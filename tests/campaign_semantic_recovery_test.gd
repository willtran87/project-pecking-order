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

	# Presentation context is campaign-scoped but never economically authoritative.
	# A malformed field rejects the candidate atomically, while unknown stable IDs
	# inside an otherwise well-typed ledger fall back to safe, actionable defaults.
	store.delete()
	_check(store.save(valid_payload, {"reason": "interface_backup"}), "interface fallback baseline should save", failures)
	var malformed_interface_payload := _advanced_payload()
	var malformed_session := malformed_interface_payload.get("session", {}) as Dictionary
	malformed_session["interface_context"] = "not a context dictionary"
	malformed_interface_payload["session"] = malformed_session
	_check(store.save(malformed_interface_payload, {"reason": "semantic_bad_interface_primary"}), "interface corruption fixture should save structurally", failures)
	office.call("_load_campaign_checkpoint")
	await process_frame
	_check(
		(office.get("_campaign_state") as CampaignState).to_dictionary() == valid_payload["campaign"]
		and "RESTORED FROM RECOVERY COPY" in (office.get("_ticker_label") as Label).text,
		"a malformed interface ledger should fall back without leaking the primary economy",
		failures,
	)

	store.delete()
	var unknown_interface_payload := _advanced_payload()
	var unknown_session := unknown_interface_payload.get("session", {}) as Dictionary
	unknown_session["interface_context"] = {
		"version": 1,
		"flockwatch_page_id": "future_page",
		"show_all_filings": false,
		"capital_filter_id": "future_filter",
		"capital_facility_id": "future_facility",
	}
	unknown_interface_payload["session"] = unknown_session
	_check(store.save(unknown_interface_payload, {"reason": "unknown_interface_ids"}), "unknown interface-ID fixture should save", failures)
	office.call("_load_campaign_checkpoint")
	await process_frame
	var navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	var blueprint = office.get("_capital_blueprint_ui")
	var restored_facility_id := (
		StringName(blueprint.call("selected_facility_id"))
		if blueprint != null else
		&""
	)
	var restored_visible_facility_ids: Array = (
		blueprint.call("visible_facility_ids")
		if blueprint != null else
		[]
	)
	var migrated_interface_context := office.call(
		"_campaign_interface_context"
	) as Dictionary
	_check(
		navigation != null
		and navigation.current_page_id() == FlockwatchNavigation.PAGE_TODAY
		and not navigation.is_showing_all_filings()
		and blueprint != null
		and StringName(blueprint.call("active_filter_id")) == &"ready"
		and int(migrated_interface_context.get("version", -1)) == 2
		and not bool(migrated_interface_context.get("economic_details_expanded", true))
		and String(migrated_interface_context.get(
			"farmgate_mandate_id",
			"",
		)) == "farmer_pickup"
		and (
			restored_facility_id == &""
			or restored_facility_id in restored_visible_facility_ids
		),
		"unknown presentation IDs should normalize to a reachable page and never retain a ghost Blueprint selection (page=%s all=%s filter=%s facility=%s)" % [
			String(navigation.current_page_id()) if navigation != null else "<missing>",
			str(navigation.is_showing_all_filings()) if navigation != null else "<missing>",
			String(blueprint.call("active_filter_id")) if blueprint != null else "<missing>",
			String(blueprint.call("selected_facility_id")) if blueprint != null else "<missing>",
		],
		failures,
	)

	# Current desk-state fields are type checked just like the original page and
	# filter fields. A malformed disclosure flag must reject the complete
	# candidate instead of partially restoring its economy.
	store.delete()
	_check(store.save(valid_payload, {"reason": "desk_state_backup"}), "desk-state fallback baseline should save", failures)
	var malformed_desk_state_payload := _advanced_payload()
	var malformed_desk_session := malformed_desk_state_payload.get("session", {}) as Dictionary
	var malformed_desk_context := (
		malformed_desk_session.get("interface_context", {}) as Dictionary
	)
	malformed_desk_context["version"] = 2
	malformed_desk_context["feed_offers_expanded"] = "yes"
	malformed_desk_session["interface_context"] = malformed_desk_context
	malformed_desk_state_payload["session"] = malformed_desk_session
	_check(
		store.save(
			malformed_desk_state_payload,
			{"reason": "semantic_bad_desk_state_primary"},
		),
		"malformed desk-state fixture should save structurally",
		failures,
	)
	office.call("_load_campaign_checkpoint")
	await process_frame
	_check(
		(office.get("_campaign_state") as CampaignState).to_dictionary() == valid_payload["campaign"]
		and "RESTORED FROM RECOVERY COPY" in (office.get("_ticker_label") as Label).text,
		"a malformed disclosure preference should fall back without leaking the primary economy",
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
			"interface_context": {
				"version": 1,
				"flockwatch_page_id": "today",
				"show_all_filings": false,
				"capital_filter_id": "ready",
				"capital_facility_id": "candling_rework_bay",
			},
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
