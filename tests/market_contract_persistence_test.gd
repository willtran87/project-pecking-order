extends SceneTree


const LOW_OFFER: StringName = &"homestead_stability_binder"
const HIGH_OFFER: StringName = &"exceptions_retention_covenant"
const RECORDS_ANNEX: StringName = &"records_annex"
const NEGOTIATION_ROOM: StringName = &"farm_mutual_negotiation_room"
const MARKET_FIELDS: Array[String] = [
	"active_market_contract",
	"market_contract_decline_receipt",
	"last_market_contract_result",
	"market_contracts_signed_total",
	"market_contracts_succeeded_total",
	"market_contracts_breached_total",
	"market_clean_contract_streak",
	"best_market_clean_contract_streak",
	"market_contract_premium_today_cents",
	"market_contract_premium_total_cents",
	"market_contract_breach_today_cents",
	"market_contract_breach_total_cents",
]


func _init() -> void:
	var failures: Array[String] = []
	_test_signed_and_midshift_json_round_trips(failures)
	_test_decline_receipt_json_round_trip_and_corruption(failures)
	_test_settled_receipt_json_round_trip(failures)
	_test_v11_migrates_with_a_neutral_market_ledger(failures)
	_test_corrupt_contract_state_fails_closed(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("MARKET_CONTRACT_PERSISTENCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MARKET_CONTRACT_PERSISTENCE_TEST_PASSED schema=v23 json=review+decline+running+settled migration=v11-neutral+campus-neutral+treasury-neutral corruption=atomic")
	quit(0)


func _test_signed_and_midshift_json_round_trips(failures: Array[String]) -> void:
	var signed := _signed_review(9661, LOW_OFFER, 0, failures)
	var signed_state := _json_dictionary(signed.export_save_state(), "signed review", failures)
	if not signed_state.is_empty():
		var restored_signed := DepartmentSimulation.new(9662, 4)
		_check(restored_signed.restore_save_state(signed_state), "signed review JSON should restore", failures)
		var active := restored_signed.market_contract_board_status().get("active", {}) as Dictionary
		_check(StringName(active.get("offer_id", &"")) == LOW_OFFER, "signed restore should preserve the exact offer", failures)
		_check(int(active.get("target_day", -1)) == 3, "signed restore should preserve its upcoming shift", failures)
		_check((active.get("accepted_claim_ids", []) as Array).is_empty(), "signed review should restore before any folder arrives", failures)
		_check(int(restored_signed.market_contract_board_status().get("reserved_claim_slots", -1)) == 5, "signed restore should retain all five reserved folders", failures)
		_check(restored_signed.current_market_contract_reserve_cents() == 500, "signed restore should retain the exact breach reserve", failures)

	var running := _signed_review(9663, LOW_OFFER, 0, failures)
	_check(running.begin_next_shift_briefing(), "midshift fixture should open its briefing", failures)
	_check(running.select_directive(&"shell_assurance"), "midshift fixture should start production", failures)
	_advance_to(running, 9 * 60, failures)
	var running_ids := (running.active_market_contract.get("accepted_claim_ids", []) as Array).duplicate()
	_check(running_ids.size() == 4, "midshift fixture should release four exact IDs", failures)
	var running_state := _json_dictionary(running.export_save_state(), "midshift", failures)
	if not running_state.is_empty():
		var restored_running := DepartmentSimulation.new(9664, 4)
		_check(restored_running.restore_save_state(running_state), "midshift contract JSON should restore", failures)
		_check(restored_running.active_market_contract.get("accepted_claim_ids", []) == running_ids, "midshift restore should preserve the exact accepted IDs", failures)
		_check(int(restored_running.active_market_contract.get("released_batch_count", -1)) == 1, "midshift restore should preserve exact-once batch progress", failures)
		_check(int(restored_running.market_contract_board_status().get("reserved_claim_slots", -1)) == 1, "midshift restore should retain only the rush reservation", failures)
		_check(_contract_queue_item_count(restored_running.snapshot()) == 4, "restored accepted IDs should still mark four physical queue folders", failures)


func _test_settled_receipt_json_round_trip(failures: Array[String]) -> void:
	var simulation := _signed_review(9671, LOW_OFFER, 0, failures)
	_check(simulation.begin_next_shift_briefing(), "settled fixture should open its briefing", failures)
	_check(simulation.select_directive(&"shell_assurance"), "settled fixture should start production", failures)
	_advance_to(simulation, 9 * 60, failures)
	var accepted := simulation.active_market_contract.get("accepted_claim_ids", []) as Array
	for index in mini(4, accepted.size()):
		simulation.call("_record_market_contract_completion", _claim_with_id(int(accepted[index])), &"sound")
	var receipt := simulation.call("_settle_market_contract", simulation.day) as Dictionary
	_check(bool(receipt.get("success", false)), "settled fixture should fulfill before export", failures)
	var state := _json_dictionary(simulation.export_save_state(), "settled receipt", failures)
	if state.is_empty():
		return
	var restored := DepartmentSimulation.new(9672, 4)
	_check(restored.restore_save_state(state), "settled receipt JSON should restore", failures)
	_check(restored.active_market_contract.is_empty(), "settled restore should not resurrect the binder", failures)
	_check(StringName(restored.last_market_contract_result.get("status", &"")) == &"fulfilled", "settled restore should retain the fulfilled receipt", failures)
	_check(restored.market_contracts_signed_total == 1 and restored.market_contracts_succeeded_total == 1, "settled restore should reconcile signature and success totals", failures)
	_check(restored.market_contract_premium_total_cents == 1000, "settled restore should preserve the exact lifetime premium", failures)


func _test_decline_receipt_json_round_trip_and_corruption(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(9665, 4)
	simulation.day = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	var receipt := simulation.decline_market_contract()
	_check(bool(receipt.get("accepted", false)), "decline fixture should authoritatively file the standard book", failures)
	_check(simulation.active_market_contract.is_empty(), "decline fixture must not invent an active binder", failures)
	var state := _json_dictionary(simulation.export_save_state(), "decline receipt", failures)
	if state.is_empty():
		return

	var restored := DepartmentSimulation.new(9666, 4)
	_check(restored.restore_save_state(state), "decline receipt JSON should restore", failures)
	var restored_board := restored.market_contract_board_status()
	var restored_receipt := restored_board.get("decline_receipt", {}) as Dictionary
	_check(restored.active_market_contract.is_empty(), "decline restore should remain on the standard book", failures)
	_check(bool(restored_receipt.get("accepted", false)), "decline restore should retain its accepted authority", failures)
	_check(String(restored_receipt.get("action_id", "")) == "decline_market_contract", "decline restore should retain the exact action ID", failures)
	_check(String(restored_receipt.get("status", "")) == "declined", "decline restore should retain its terminal planning status", failures)
	_check(int(restored_receipt.get("day", -1)) == 3 and int(restored_receipt.get("target_day", -1)) == 3, "decline restore should retain the exact target shift", failures)
	_check(not bool(restored_board.get("decline_available", true)), "restored receipt should prevent a duplicate standard-book filing", failures)
	for offer_value in restored_board.get("offers", []):
		_check(not bool((offer_value as Dictionary).get("can_sign", true)), "restored decline should keep every outside binder closed", failures)

	var corrupt_target := state.duplicate(true)
	var target_receipt := (corrupt_target.get("market_contract_decline_receipt", {}) as Dictionary).duplicate(true)
	target_receipt["target_day"] = 4
	corrupt_target["market_contract_decline_receipt"] = target_receipt
	_expect_restore_rejected_atomic(corrupt_target, "decline receipt with a mismatched target shift", failures)

	var corrupt_outcome := state.duplicate(true)
	var outcome_receipt := (corrupt_outcome.get("market_contract_decline_receipt", {}) as Dictionary).duplicate(true)
	outcome_receipt["outcome"] = "STANDARD BOOK FILED: altered receipt copy."
	corrupt_outcome["market_contract_decline_receipt"] = outcome_receipt
	_expect_restore_rejected_atomic(corrupt_outcome, "decline receipt with altered authored outcome", failures)


func _test_v11_migrates_with_a_neutral_market_ledger(failures: Array[String]) -> void:
	_check(DepartmentSimulation.SAVE_STATE_VERSION == 27, "adaptive casework receipts should advance the simulation schema to v27", failures)
	var current_state := DepartmentSimulation.new(9681, 4).export_save_state()
	_check(int(current_state.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "current market state should export schema v24", failures)
	_check(current_state.has("campus_expansion"), "current market state should include the North Meadow ledger", failures)
	var legacy_v11 := current_state.duplicate(true)
	legacy_v11["state_version"] = 11
	for field in MARKET_FIELDS:
		legacy_v11.erase(field)
	var legacy_facilities := (legacy_v11.get("owned_facilities", {}) as Dictionary).duplicate(true)
	legacy_facilities.erase("farm_mutual_service_coop")
	legacy_facilities.erase(String(NEGOTIATION_ROOM))
	legacy_facilities.erase(String(DepartmentSimulation.WELLNESS_NEST_ID))
	legacy_facilities.erase(String(DepartmentSimulation.TRAINING_ROOST_ID))
	legacy_facilities.erase(String(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID))
	legacy_facilities.erase(String(DepartmentSimulation.IT_COOP_ID))
	legacy_facilities.erase(String(DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID))
	legacy_facilities.erase(String(DepartmentSimulation.FEED_PROCUREMENT_COOP_ID))
	legacy_facilities.erase(String(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID))
	legacy_facilities.erase(String(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID))
	legacy_v11["owned_facilities"] = legacy_facilities
	legacy_v11.erase("feed_procurement_state")
	legacy_v11.erase("harvest_credit_state")
	legacy_v11.erase("farmgate_dispatch_state")
	legacy_v11.erase("pinned_capital_plan_id")
	legacy_v11.erase("last_facility_purchase_receipt")
	legacy_v11.erase("facility_commissioning_history")
	legacy_v11.erase("campus_expansion")
	var restored := DepartmentSimulation.new(9682, 4)
	_check(restored.restore_save_state(legacy_v11), "schema v11 should migrate with a neutral market ledger", failures)
	_check(restored.active_market_contract.is_empty() and restored.last_market_contract_result.is_empty(), "v11 migration must not invent a binder or receipt", failures)
	_check(restored.market_contracts_signed_total == 0 and restored.market_contracts_succeeded_total == 0 and restored.market_contracts_breached_total == 0, "v11 migration must not invent contract outcomes", failures)
	_check(restored.market_contract_premium_total_cents == 0 and restored.market_contract_breach_total_cents == 0, "v11 migration must not invent premium or breach cents", failures)
	_check(int(restored.export_save_state().get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "migrated state should re-export schema v24", failures)
	_assert_neutral_campus(restored, "v11 migration", failures)


func _test_corrupt_contract_state_fails_closed(failures: Array[String]) -> void:
	var signed := _signed_review(9691, LOW_OFFER, 0, failures)
	var signed_state := _json_dictionary(signed.export_save_state(), "corrupt signed fixture", failures)
	if signed_state.is_empty():
		return
	var corrupt_terms := signed_state.duplicate(true)
	var terms_contract := (corrupt_terms.get("active_market_contract", {}) as Dictionary).duplicate(true)
	terms_contract["premium_cents"] = int(terms_contract.get("premium_cents", 0)) + 1
	corrupt_terms["active_market_contract"] = terms_contract
	_expect_restore_rejected_atomic(corrupt_terms, "altered authored premium", failures)

	var corrupt_totals := signed_state.duplicate(true)
	corrupt_totals["market_contracts_signed_total"] = 0
	_expect_restore_rejected_atomic(corrupt_totals, "active binder without a signature total", failures)

	var corrupt_daily := signed_state.duplicate(true)
	corrupt_daily["market_contract_premium_today_cents"] = 1
	corrupt_daily["market_contract_premium_total_cents"] = 0
	_expect_restore_rejected_atomic(corrupt_daily, "daily premium above lifetime premium", failures)

	var running := _signed_review(9692, LOW_OFFER, 0, failures)
	_check(running.begin_next_shift_briefing(), "duplicate-ID fixture should open its briefing", failures)
	_check(running.select_directive(&"shell_assurance"), "duplicate-ID fixture should start production", failures)
	_advance_to(running, 9 * 60, failures)
	var corrupt_ids := _json_dictionary(running.export_save_state(), "corrupt ID fixture", failures)
	if not corrupt_ids.is_empty():
		var id_contract := (corrupt_ids.get("active_market_contract", {}) as Dictionary).duplicate(true)
		var accepted := (id_contract.get("accepted_claim_ids", []) as Array).duplicate()
		if not accepted.is_empty():
			accepted.append(accepted[0])
		id_contract["accepted_claim_ids"] = accepted
		corrupt_ids["active_market_contract"] = id_contract
		_expect_restore_rejected_atomic(corrupt_ids, "duplicate accepted claim ID", failures)

	var high := _signed_review(9693, HIGH_OFFER, 2, failures)
	var corrupt_capacity := _json_dictionary(high.export_save_state(), "corrupt capacity fixture", failures)
	if not corrupt_capacity.is_empty():
		var facilities := (corrupt_capacity.get("owned_facilities", {}) as Dictionary).duplicate(true)
		facilities[String(RECORDS_ANNEX)] = 0
		corrupt_capacity["owned_facilities"] = facilities
		_expect_restore_rejected_atomic(corrupt_capacity, "active high binder without its Records capacity", failures)


func _signed_review(
	seed: int,
	offer_id: StringName,
	records_level: int,
	failures: Array[String]
) -> DepartmentSimulation:
	var staff_count := 6 if offer_id == HIGH_OFFER else 4
	var simulation := DepartmentSimulation.new(seed, staff_count)
	simulation.day = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.owned_facilities[RECORDS_ANNEX] = records_level
	simulation.revenue_cents = 100_000
	_check(bool(simulation.sign_market_contract(offer_id).get("accepted", false)), "fixture should sign %s" % offer_id, failures)
	return simulation


func _advance_to(simulation: DepartmentSimulation, target_minute: int, failures: Array[String]) -> void:
	var guard := 0
	while simulation.minute_of_day < target_minute and guard < 400:
		if simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING:
			_check(false, "persistence fixture paused before %d" % target_minute, failures)
			return
		simulation.advance_tick()
		guard += 1
	_check(guard < 400 and simulation.minute_of_day == target_minute, "persistence fixture should reach minute %d" % target_minute, failures)


func _json_dictionary(source: Dictionary, context: String, failures: Array[String]) -> Dictionary:
	_check(int(source.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "%s should export schema v24" % context, failures)
	var parsed: Variant = JSON.parse_string(JSON.stringify(source))
	_check(parsed is Dictionary, "%s should remain primitive JSON" % context, failures)
	return parsed as Dictionary if parsed is Dictionary else {}


func _contract_queue_item_count(snapshot: Dictionary) -> int:
	var count := 0
	var queues := snapshot.get("claim_queue_items", {}) as Dictionary
	for lane in DepartmentSimulation.CLAIM_LANES:
		for claim_value in queues.get(lane, queues.get(String(lane), [])):
			if bool((claim_value as Dictionary).get("market_contract", false)):
				count += 1
	return count


func _claim_with_id(claim_id: int) -> ClaimState:
	return ClaimState.new(
		claim_id,
		&"nest_damage",
		"TEST FOLDER",
		1.0,
		360,
		0.0,
		0,
		10_000,
		10_000,
	)


func _expect_restore_rejected_atomic(corrupt: Dictionary, message: String, failures: Array[String]) -> void:
	var fallback := DepartmentSimulation.new(9699, 4)
	var before := fallback.export_save_state().duplicate(true)
	_check(not fallback.restore_save_state(corrupt), "%s should fail closed" % message, failures)
	_check(fallback.export_save_state() == before, "%s should preserve the fallback simulation" % message, failures)


func _assert_neutral_campus(simulation: DepartmentSimulation, context: String, failures: Array[String]) -> void:
	var campus := simulation.export_save_state().get("campus_expansion", {}) as Dictionary
	var services := campus.get("services", {}) as Dictionary
	_check(not bool(campus.get("parcel_owned", true)), "%s must not invent North Meadow ownership" % context, failures)
	_check(
		services.size() == 3
		and not bool(services.get("circulation", true))
		and not bool(services.get("power", true))
		and not bool(services.get("cold_chain", true)),
		"%s must leave all North Meadow services disconnected" % context,
		failures,
	)
	_check(
		not bool(campus.get("pod_owned", true)) and String(campus.get("pod_socket_id", "")).is_empty(),
		"%s must not invent Egg Routing Pod ownership or placement" % context,
		failures,
	)
	_check(
		int(campus.get("capital_spend_total_cents", -1)) == 0
		and int(campus.get("next_receipt_id", -1)) == 1
		and (campus.get("last_receipt", {}) as Dictionary).is_empty()
		and (campus.get("history", []) as Array).is_empty(),
		"%s must retain an exact neutral North Meadow receipt ledger" % context,
		failures,
	)
	var projection := simulation.campus_expansion_snapshot()
	_check(
		not bool(projection.get("pod_operational", true))
		and int(projection.get("claim_capacity_bonus", -1)) == 0
		and int(projection.get("farmgate_capacity_bonus_eggs", -1)) == 0
		and int(projection.get("current_daily_cost_cents", -1)) == 0,
		"%s must retain zero North Meadow operations, capacity, and daily cost" % context,
		failures,
	)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
