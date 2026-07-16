extends SceneTree


const HarvestState := preload("res://core/simulation/harvest_credit_state.gd")


func _init() -> void:
	var failures: Array[String] = []
	_test_gate_quotes_and_single_use(failures)
	_test_skip_and_standing_labels(failures)
	_test_strict_json_restore(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("HARVEST_CREDIT_STATE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("HARVEST_CREDIT_STATE_TEST_PASSED gate=credit-first catalog=three formula=tier3 single-use=yes skip=neutral json=canonical corruption=strict")
	quit(0)


func _test_gate_quotes_and_single_use(failures: Array[String]) -> void:
	var state := HarvestState.new()
	_check(state.stage_review(_evidence(5), 3, true), "valid evidence should stage behind the closing-credit gate", failures)
	_check(state.review_status == HarvestState.STATUS_PRE_CREDIT, "pending closing credit should hold publicity in pre-credit", failures)
	_check(not state.release_credit_gate(4), "a mismatched completed day may not release publicity", failures)
	_check(state.release_credit_gate(5), "the matching completed day should release publicity once", failures)
	var catalog := state.campaign_catalog()
	_check(catalog.size() == 3, "all three authored campaigns should exist at Gallery level one and above", failures)
	var ids: Array[StringName] = []
	for offer in catalog:
		ids.append(StringName(offer.get("campaign_id", &"")))
	_check(ids == [&"layer_profile", &"clutch_results_board", &"farmer_method"], "campaign IDs should remain stable and ordered", failures)
	var layer := state.campaign_quote(&"layer_profile")
	var clutch := state.campaign_quote(&"clutch_results_board")
	var farmer := state.campaign_quote(&"farmer_method")
	_check(int(layer.get("base_payout_cents", -1)) == 640 and int(layer.get("public_standing_delta", -1)) == 6, "tier-three Layer Profile should use 8x30 + 2x200 and six reach", failures)
	_check(int(clutch.get("base_payout_cents", -1)) == 450 and int(clutch.get("public_standing_delta", -1)) == 7, "tier-three Clutch Board should use 8x25 + 2x125 and seven reach", failures)
	_check(int(farmer.get("base_payout_cents", -1)) == 1240 and int(farmer.get("public_standing_delta", -1)) == 8, "tier-three Farmer Method should use 8x55 + 2x400 and eight reach", failures)
	var receipt := state.commit_campaign(&"farmer_method", "Filed from frozen evidence.")
	_check(int(receipt.get("payout_cents", -1)) == 1240 and state.payout_total_cents == 1240, "the selected payout should post exactly once", failures)
	_check(state.public_standing == 8 and state.attribution_balance == 18, "Farmer Method should post its exact standing and attribution deltas", failures)
	_check(state.commit_campaign(&"layer_profile").is_empty(), "a filed shift may not publish a second campaign", failures)


func _test_skip_and_standing_labels(failures: Array[String]) -> void:
	var state := HarvestState.new()
	_check(state.stage_review(_evidence(6), 1, false), "an ungated completed shift should open directly", failures)
	var before := state.to_save_data()
	var skipped := state.skip_campaign()
	_check(StringName(skipped.get("status", &"")) == HarvestState.STATUS_SKIPPED, "explicit skip should produce a skipped receipt", failures)
	_check(state.public_standing == int(before.get("public_standing", -1)) and state.attribution_balance == int(before.get("attribution_balance", -1)), "skip should change neither standing nor attribution", failures)
	_check(state.total_campaigns == 0 and state.payout_total_cents == 0 and state.last_skipped_day == 6, "skip should record its day without inventing a campaign or payout", failures)
	var thresholds := {0: "UNLISTED", 5: "ROADSIDE NOTICE", 12: "COUNTY FAIR", 25: "REGIONAL SHOWCASE", 45: "HOUSEHOLD FARM BRAND"}
	for points in thresholds:
		_check(HarvestState.standing_label_for(points) == thresholds[points], "standing threshold %d should map exactly" % points, failures)


func _test_strict_json_restore(failures: Array[String]) -> void:
	var source := HarvestState.new()
	_check(source.stage_review(_evidence(7), 2, false), "restore fixture should stage", failures)
	source.commit_campaign(&"layer_profile", "Canonical JSON receipt.")
	var encoded: Variant = JSON.parse_string(JSON.stringify(source.to_save_data()))
	var restored := HarvestState.new()
	_check(encoded is Dictionary and restored.restore_save_data(encoded, 8, 2), "valid primitive JSON should restore", failures)
	_check(restored.snapshot() == source.snapshot(), "live and JSON-restored projections should be identical", failures)

	var corrupt := (encoded as Dictionary).duplicate(true)
	corrupt["invented_publicity_margin"] = 1
	var target := HarvestState.new()
	var before := target.to_save_data()
	_check(not target.restore_save_data(corrupt, 8, 2), "unknown ledger fields should fail closed", failures)
	_check(target.to_save_data() == before, "rejected restore should not partially mutate the target", failures)

	corrupt = (encoded as Dictionary).duplicate(true)
	var history := (corrupt.get("history", []) as Array).duplicate(true)
	var receipt := (history[0] as Dictionary).duplicate(true)
	receipt["payout_cents"] = int(receipt.get("payout_cents", 0)) + 1
	history[0] = receipt
	corrupt["history"] = history
	corrupt["last_receipt"] = receipt.duplicate(true)
	_check(not HarvestState.new().restore_save_data(corrupt, 8, 2), "repriced receipts should fail deterministic validation", failures)


func _evidence(completed_day: int) -> Dictionary:
	return {
		"day": completed_day,
		"eggs": 10,
		"quota": 8,
		"sound": 8,
		"cracked": 2,
		"golden": 2,
		"met_quota": true,
		"top_worker_id": 0,
		"top_worker_name": "Mabel",
		"hen_highlight": {
			"version": 1,
			"day": completed_day,
			"worker_id": 0,
			"worker_name": "Mabel",
			"tone": &"gold",
		},
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
