extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const TEST_SAVE_FILENAME := "campaign_semantic_recovery_test.json"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	store.delete()

	var valid_payload := _fresh_payload()
	_check(store.save(valid_payload, {"reason": "known_good_backup"}), "test should file a valid recovery baseline", failures)
	var corrupt_senior_payload := _advanced_payload()
	var corrupt_senior := corrupt_senior_payload.get("senior_roost", {}) as Dictionary
	corrupt_senior["status"] = "unsupported_semantic_state"
	corrupt_senior_payload["senior_roost"] = corrupt_senior
	_check(
		store.save(corrupt_senior_payload, {"reason": "semantic_bad_senior_primary"}),
		"envelope store should accept the structurally valid semantic-corruption fixture",
		failures,
	)

	var office := Office.new()
	office.set("_campaign_store", store)
	office.set("_allow_automated_campaign_saves", true)
	root.add_child(office)
	await process_frame
	await process_frame
	office.call("_load_campaign_checkpoint")
	await process_frame
	await process_frame

	var restored_campaign := office.get("_campaign_state") as CampaignState
	var restored_simulation := office.get("_simulation") as DepartmentSimulation
	var restored_senior := office.get("_senior_roost_state") as SeniorRoostState
	var ticker := office.get("_ticker_label") as Label
	_check(
		restored_campaign != null and restored_campaign.to_dictionary() == valid_payload["campaign"],
		"semantic-invalid primary should fall back to the known-good campaign ledger",
		failures,
	)
	_check(
		restored_simulation != null
		and _fields_match(
			restored_simulation.export_save_state(),
			valid_payload["simulation"] as Dictionary,
			["day", "shift_phase", "minute_of_day", "tick_count", "revenue_cents", "decision_serial"],
		)
		and restored_simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE,
		"Senior validation failure must not leak the primary's advanced simulation into live state",
		failures,
	)
	_check(
		restored_senior != null and restored_senior.to_dictionary() == valid_payload["senior_roost"],
		"Senior validation failure should restore the complete backup Senior ledger",
		failures,
	)
	_check(
		ticker != null and "RESTORED FROM RECOVERY COPY" in ticker.text,
		"semantic recovery should disclose that a recovery artifact became authoritative",
		failures,
	)

	# A valid envelope with an invalid CampaignState must also advance to backup.
	store.delete()
	_check(store.save(valid_payload, {"reason": "campaign_backup"}), "campaign fallback baseline should save", failures)
	var corrupt_campaign_payload := _advanced_payload()
	var corrupt_campaign := corrupt_campaign_payload.get("campaign", {}) as Dictionary
	corrupt_campaign["probation_score"] = 101
	corrupt_campaign_payload["campaign"] = corrupt_campaign
	_check(store.save(corrupt_campaign_payload, {"reason": "semantic_bad_campaign_primary"}), "campaign corruption fixture should save structurally", failures)
	office.call("_load_campaign_checkpoint")
	await process_frame
	_check(
		(office.get("_campaign_state") as CampaignState).to_dictionary() == valid_payload["campaign"]
		and "RESTORED FROM RECOVERY COPY" in (office.get("_ticker_label") as Label).text,
		"semantic-invalid campaign primary should activate the fully valid backup",
		failures,
	)

	# The same transaction must skip a simulation that passes JSON/envelope checks
	# but fails DepartmentSimulation's invariants.
	store.delete()
	_check(store.save(valid_payload, {"reason": "simulation_backup"}), "simulation fallback baseline should save", failures)
	var corrupt_simulation_payload := _advanced_payload()
	var corrupt_simulation := corrupt_simulation_payload.get("simulation", {}) as Dictionary
	corrupt_simulation["day"] = 0
	corrupt_simulation_payload["simulation"] = corrupt_simulation
	_check(store.save(corrupt_simulation_payload, {"reason": "semantic_bad_simulation_primary"}), "simulation corruption fixture should save structurally", failures)
	office.call("_load_campaign_checkpoint")
	await process_frame
	_check(
		_fields_match(
			(office.get("_simulation") as DepartmentSimulation).export_save_state(),
			valid_payload["simulation"] as Dictionary,
			["day", "shift_phase", "minute_of_day", "tick_count", "revenue_cents", "decision_serial"],
		)
		and "RESTORED FROM RECOVERY COPY" in (office.get("_ticker_label") as Label).text,
		"semantic-invalid simulation primary should activate the fully valid backup",
		failures,
	)

	# With no semantically valid candidate, loading must leave every authoritative
	# live component byte-for-byte unchanged and disable Continue.
	var campaign_before := (office.get("_campaign_state") as CampaignState).to_dictionary()
	var simulation_before := (office.get("_simulation") as DepartmentSimulation).export_save_state()
	var senior_before := (office.get("_senior_roost_state") as SeniorRoostState).to_dictionary()
	store.delete()
	_check(
		store.save(corrupt_senior_payload, {"reason": "only_semantic_bad_candidate"}),
		"single invalid candidate fixture should retain a valid outer envelope",
		failures,
	)
	office.call("_load_campaign_checkpoint")
	await process_frame
	await process_frame
	var continue_button := office.find_child("ContinueCampaignButton", true, false) as Button
	_check(
		(office.get("_campaign_state") as CampaignState).to_dictionary() == campaign_before
		and (office.get("_simulation") as DepartmentSimulation).export_save_state() == simulation_before
		and (office.get("_senior_roost_state") as SeniorRoostState).to_dictionary() == senior_before,
		"all-invalid recovery must fail closed without partially mutating live authoritative state",
		failures,
	)
	_check(
		continue_button != null and continue_button.disabled
		and "No complete campaign, office, and Senior ledger passed validation" in (
			office.get("_ticker_label") as Label
		).text,
		"all-invalid recovery should disable Continue and explain the composite hold",
		failures,
	)
	var invalid_diagnostic := office.call("_checkpoint_diagnostic_state") as Dictionary
	_check(
		not bool(invalid_diagnostic.get("has_checkpoint", true))
		and not bool(invalid_diagnostic.get("has_candidate", true))
		and String(invalid_diagnostic.get("status", "")) == "error"
		and "No complete campaign, office, and Senior ledger passed validation" in String(
			invalid_diagnostic.get("last_error", "")
		)
		and String(invalid_diagnostic.get("last_error", "")).length() <= 240,
		"all-invalid recovery must revoke verified-save diagnostics and publish one bounded error",
		failures,
	)

	root.remove_child(office)
	office.free()
	var cleanup_succeeded := store.delete()
	_check(cleanup_succeeded, "isolated semantic recovery artifacts should clean up", failures)
	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPAIGN_SEMANTIC_RECOVERY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPAIGN_SEMANTIC_RECOVERY_TEST_PASSED candidates=campaign+simulation+senior fallback=atomic all_invalid=no_mutation+truthful")
	quit(0)


func _fresh_payload() -> Dictionary:
	var campaign := CampaignState.new()
	var simulation := DepartmentSimulation.new(1701, 4)
	var senior := SeniorRoostState.new()
	return _json_safe_variant({
		"campaign": campaign.to_dictionary(),
		"simulation": simulation.export_save_state(),
		"senior_roost": senior.to_dictionary(),
		"session": {
			"review_stage": "active",
			"last_workday_report": {},
			"senior_roost": false,
		},
	}) as Dictionary


func _advanced_payload() -> Dictionary:
	var payload := _fresh_payload()
	var simulation := DepartmentSimulation.new(1701, 4)
	simulation.select_directive(&"shell_assurance")
	simulation.advance_tick()
	payload["simulation"] = simulation.export_save_state()
	return payload


func _json_safe_variant(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var result: Dictionary = {}
			for key: Variant in value as Dictionary:
				result[String(key)] = _json_safe_variant((value as Dictionary)[key])
			return result
		TYPE_ARRAY:
			var result: Array = []
			for item: Variant in value as Array:
				result.append(_json_safe_variant(item))
			return result
		TYPE_STRING_NAME:
			return String(value)
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
	return str(value)


func _fields_match(actual: Dictionary, expected: Dictionary, fields: Array[String]) -> bool:
	for field: String in fields:
		if actual.get(field) != expected.get(field):
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
