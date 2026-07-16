extends SceneTree


const LOW_OFFER: StringName = &"homestead_stability_binder"


func _init() -> void:
	var failures: Array[String] = []
	_test_timed_release_does_not_pause_or_duplicate(failures)
	_test_exact_claim_ids_and_quality_gate_completion(failures)
	_test_exact_once_success_and_breach_settlement(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("MARKET_CONTRACT_SHIFT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MARKET_CONTRACT_SHIFT_TEST_PASSED release=timed-no-modal ids=exact quality=clean+timely settlement=success+breach-once")
	quit(0)


func _test_timed_release_does_not_pause_or_duplicate(failures: Array[String]) -> void:
	var simulation := _running_low_contract(9631, failures)
	var contract_decisions := {"count": 0}
	simulation.decision_requested.connect(func(_decision: Dictionary) -> void:
		contract_decisions["count"] = int(contract_decisions["count"]) + 1
	)
	_advance_running_to(simulation, 8 * 60 + 58, failures)
	_check((simulation.active_market_contract.get("accepted_claim_ids", []) as Array).is_empty(), "no contract folder should arrive before 9:00 AM", failures)
	_check(int(simulation.market_contract_board_status().get("reserved_claim_slots", -1)) == 5, "all five folders should remain reserved before the first batch", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING, "reserved folders should not pause production", failures)

	simulation.advance_tick()
	var accepted := simulation.active_market_contract.get("accepted_claim_ids", []) as Array
	_check(simulation.minute_of_day == 9 * 60, "the release fixture should land exactly at 9:00 AM", failures)
	_check(accepted.size() == 4, "the 9:00 AM core batch should release exactly four folders", failures)
	_check(int(simulation.active_market_contract.get("released_batch_count", -1)) == 1, "the core batch should settle one release marker", failures)
	_check(int(simulation.market_contract_board_status().get("reserved_claim_slots", -1)) == 1, "only the disclosed rush folder should remain reserved", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING, "contract intake should not open a management modal", failures)
	_check(int(contract_decisions["count"]) == 0, "contract intake should emit no decision request", failures)
	_check(_contract_queue_item_count(simulation.snapshot()) == 4, "all four released folders should appear physically in authoritative queues", failures)
	_check(int(simulation.snapshot().get("claims_outstanding", 0)) <= simulation.current_claim_capacity(), "contract release must respect the live-file cap", failures)

	simulation.advance_tick()
	_check((simulation.active_market_contract.get("accepted_claim_ids", []) as Array).size() == 4, "a later tick must not duplicate the core batch", failures)
	_advance_running_to(simulation, 10 * 60 + 58, failures)
	simulation.advance_tick()
	_check(simulation.minute_of_day == 11 * 60, "the rush fixture should land exactly at 11:00 AM", failures)
	_check((simulation.active_market_contract.get("accepted_claim_ids", []) as Array).size() == 5, "the 11:00 AM rush should release the fifth exact folder", failures)
	_check(int(simulation.active_market_contract.get("released_batch_count", -1)) == 2, "both authored batches should now be released", failures)
	_check(int(simulation.market_contract_board_status().get("reserved_claim_slots", -1)) == 0, "no folder reservation should remain after the rush", failures)
	# The structural 11:00 incident may now pause the clock, but the rush was filed
	# first and did not create an additional contract decision.
	_check(int(contract_decisions["count"]) == 1, "only the authored 11:00 incident should request a decision", failures)


func _test_exact_claim_ids_and_quality_gate_completion(failures: Array[String]) -> void:
	var simulation := _running_low_contract(9641, failures)
	_advance_running_to(simulation, 9 * 60, failures)
	var accepted := simulation.active_market_contract.get("accepted_claim_ids", []) as Array
	_check(accepted.size() == 4, "exact-ID fixture should release four core claims", failures)
	if accepted.size() < 2:
		return
	var ambient := _claim_with_id(99_999)
	simulation.call("_record_market_contract_completion", ambient, &"sound")
	_check(int(simulation.active_market_contract.get("completed_count", -1)) == 0, "an ambient claim in the same lane must not satisfy the binder", failures)

	var first := _claim_with_id(int(accepted[0]))
	simulation.call("_record_market_contract_completion", first, &"cracked")
	_check(int(simulation.active_market_contract.get("completed_count", -1)) == 1, "the accepted cracked folder should close exactly once", failures)
	_check(int(simulation.active_market_contract.get("cracked_count", -1)) == 1, "the cracked folder should enter the breach evidence ledger", failures)
	_check(int(simulation.active_market_contract.get("timely_sound_completed", -1)) == 0, "cracked work must not count as clean delivery", failures)
	simulation.call("_record_market_contract_completion", first, &"sound")
	_check(int(simulation.active_market_contract.get("completed_count", -1)) == 1, "replaying the same accepted ID must be idempotent", failures)
	_check(int(simulation.active_market_contract.get("timely_sound_completed", -1)) == 0, "a replay must not launder cracked work into success", failures)

	var second := _claim_with_id(int(accepted[1]))
	simulation.call("_record_market_contract_completion", second, &"golden")
	_check(int(simulation.active_market_contract.get("timely_sound_completed", -1)) == 1, "a timely golden accepted ID should count as one clean delivery", failures)
	_check(int(simulation.active_market_contract.get("remaining_required", -1)) == 3, "the live threshold should decrement only for the exact clean ID", failures)


func _test_exact_once_success_and_breach_settlement(failures: Array[String]) -> void:
	var success := _running_low_contract(9651, failures)
	_advance_running_to(success, 9 * 60, failures)
	var accepted := success.active_market_contract.get("accepted_claim_ids", []) as Array
	for index in mini(4, accepted.size()):
		success.call("_record_market_contract_completion", _claim_with_id(int(accepted[index])), &"sound")
	var success_signal := {"count": 0}
	success.market_contract_settled.connect(func(_result: Dictionary) -> void:
		success_signal["count"] = int(success_signal["count"]) + 1
	)
	var success_fund_before := success.revenue_cents
	var fulfilled := success.call("_settle_market_contract", success.day) as Dictionary
	_check(bool(fulfilled.get("success", false)), "four timely clean core folders should fulfill the low binder", failures)
	_check(StringName(fulfilled.get("status", &"")) == &"fulfilled", "successful settlement should file a fulfilled receipt", failures)
	_check(int(fulfilled.get("premium_cents", -1)) == 1000 and int(fulfilled.get("breach_cents", -1)) == 0, "fulfillment should award exactly $10 and no breach", failures)
	_check(success.revenue_cents == success_fund_before + 1000, "the premium should credit Feed Fund exactly once", failures)
	_check(success.market_contract_premium_total_cents == 1000 and success.market_contracts_succeeded_total == 1, "fulfillment should update both exact lifetime ledgers", failures)
	_check(success.active_market_contract.is_empty(), "settlement should clear the active binder", failures)
	var after_success := success.export_save_state().duplicate(true)
	_check((success.call("_settle_market_contract", success.day) as Dictionary).is_empty(), "a fulfilled binder cannot settle twice", failures)
	_check(success.export_save_state() == after_success, "replayed fulfillment must preserve every authoritative field", failures)
	_check(int(success_signal["count"]) == 1, "fulfillment should emit one settlement signal", failures)

	var breached := _running_low_contract(9652, failures)
	_advance_running_to(breached, 9 * 60, failures)
	var breach_ids := breached.active_market_contract.get("accepted_claim_ids", []) as Array
	for index in mini(3, breach_ids.size()):
		breached.call("_record_market_contract_completion", _claim_with_id(int(breach_ids[index])), &"sound")
	var breach_fund_before := breached.revenue_cents
	var breach := breached.call("_settle_market_contract", breached.day) as Dictionary
	_check(not bool(breach.get("success", true)), "three of four required deliveries should breach", failures)
	_check(StringName(breach.get("status", &"")) == &"breached", "failed settlement should file a breached receipt", failures)
	_check(int(breach.get("premium_cents", -1)) == 0 and int(breach.get("breach_cents", -1)) == 500, "breach should charge exactly $5 and no premium", failures)
	_check(breached.revenue_cents == breach_fund_before - 500, "the protected breach clause should debit Feed Fund exactly once", failures)
	_check(breached.market_contract_breach_total_cents == 500 and breached.market_contracts_breached_total == 1, "breach should update both exact lifetime ledgers", failures)


func _running_low_contract(seed: int, failures: Array[String]) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 4)
	simulation.day = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 100_000
	_check(bool(simulation.sign_market_contract(LOW_OFFER).get("accepted", false)), "fixture should sign the low binder", failures)
	_check(simulation.begin_next_shift_briefing(), "signed review should open its morning briefing", failures)
	_check(simulation.select_directive(&"shell_assurance"), "fixture should start production under Shell Assurance", failures)
	return simulation


func _advance_running_to(simulation: DepartmentSimulation, target_minute: int, failures: Array[String]) -> void:
	var guard := 0
	while simulation.minute_of_day < target_minute and guard < 400:
		if simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING:
			_check(false, "fixture unexpectedly paused before %d" % target_minute, failures)
			return
		simulation.advance_tick()
		guard += 1
	_check(guard < 400 and simulation.minute_of_day == target_minute, "fixture should reach exact minute %d" % target_minute, failures)


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


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
