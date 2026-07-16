extends SceneTree


const LOW_OFFER: StringName = &"homestead_stability_binder"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(9701, 4)
	simulation.day = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 50_000
	var fund_before := simulation.revenue_cents

	# Inject the authored day-three review before Office._ready(), allowing this
	# narrow scene test to exercise production UI wiring without playing two shifts.
	var office := Office.new()
	office.set("_simulation", simulation)
	root.add_child(office)
	await process_frame
	await process_frame

	var clock := office.get("_clock") as SimulationClock
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var observed := {"signed": 0}
	simulation.market_contract_signed.connect(func(_receipt: Dictionary) -> void:
		observed["signed"] += 1
	)

	_check(clock != null and clock.speed_index == 0, "day-three review fixture should begin paused", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW, "fixture should remain at the authoritative review gate", failures)

	office.call("_open_contract_board_or_begin_next_shift")
	await process_frame
	await process_frame

	var board_ui := campaign_ui.contract_board_ui() if campaign_ui != null else null
	var folder := office.find_child("ContractFolder_homestead_stability_binder", true, false) as Button
	var sign_button := office.find_child("SignContractButton", true, false) as Button
	var continue_button := office.find_child("OpenContractShiftButton", true, false) as Button
	_check(
		campaign_ui != null and campaign_ui.modal_state() == ProbationCampaignUI.VIEW_CONTRACT_BOARD,
		"day-three Review should open the sequential Farm Mutual Board",
		failures,
	)
	_check(StringName(office.get("_campaign_review_stage")) == &"contract_board", "Office should own the contract-board review stage", failures)
	_check(clock != null and clock.speed_index == 0, "opening planning must keep the simulation clock paused", failures)
	_check(folder != null and folder.is_visible_in_tree() and not folder.disabled, "Homestead folder should be selectable through the real Board", failures)
	_check(sign_button != null and sign_button.disabled, "a binder cannot be signed before explicit folder selection", failures)
	_check(continue_button != null and continue_button.disabled, "C must remain held before an authoritative filing receipt", failures)

	_press(folder)
	await process_frame
	await process_frame
	_check(board_ui != null and board_ui.selected_contract_id() == LOW_OFFER, "folder selection should retain the stable Homestead offer ID", failures)
	_check(sign_button != null and not sign_button.disabled, "selected affordable folder should enable the separate signature action", failures)
	_check(simulation.active_market_contract.is_empty(), "selection alone must not create a liability", failures)

	_press(sign_button)
	await process_frame
	await process_frame

	var board := simulation.market_contract_board_status()
	var active := board.get("active", {}) as Dictionary
	_check(int(observed["signed"]) == 1, "one Sign action should produce exactly one authoritative signature receipt", failures)
	_check(StringName(active.get("offer_id", &"")) == LOW_OFFER, "authoritative state should bind the selected Homestead offer", failures)
	_check(String(active.get("status", "")) == "signed", "new binder should remain signed until timed folders arrive", failures)
	_check(int(active.get("target_day", -1)) == 3, "signed binder should target the day-three shift", failures)
	_check((active.get("scheduled_claims", []) as Array).size() == 5, "Homestead binder should reserve its five authored folders", failures)
	_check(int(board.get("reserved_claim_slots", -1)) == 5, "Board should expose all five reserved archive slots", failures)
	_check(simulation.current_market_contract_reserve_cents() == 500, "signature should authoritatively reserve the exact $5 breach clause", failures)
	_check(simulation.protected_reserve_cents() >= 500, "protected reserves should include the full contract liability", failures)
	_check(simulation.revenue_cents == fund_before, "signing should reserve liability without debiting the Feed Fund", failures)
	_check((board.get("decline_receipt", {}) as Dictionary).is_empty(), "signed path must not fabricate a standard-book decline", failures)
	_check(continue_button != null and not continue_button.disabled, "authoritative signed receipt should unlock the separate C continuation", failures)
	_check(clock != null and clock.speed_index == 0, "signing must leave the planning clock paused", failures)

	_press_key(KEY_C)
	await process_frame
	await process_frame

	var pending := simulation.pending_decision_snapshot()
	_check(campaign_ui != null and campaign_ui.modal_state() == ProbationCampaignUI.VIEW_ACTIVE, "C should close the Board and return to the office", failures)
	_check(StringName(office.get("_campaign_review_stage")) == &"active", "C should advance Office to the active briefing stage", failures)
	_check(simulation.day == 3 and simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE, "C should open the day-three directive without starting production", failures)
	_check(StringName(pending.get("kind", &"")) == &"directive", "the morning policy should remain the next authoritative decision", failures)
	_check(clock != null and clock.speed_index == 0, "directive should remain paused after leaving the Board", failures)
	_check(StringName(simulation.active_market_contract.get("offer_id", &"")) == LOW_OFFER, "opening the briefing should preserve the signed binder", failures)
	_check(simulation.revenue_cents == fund_before, "opening the briefing should not debit the reserved liability", failures)

	if clock != null:
		clock.set_speed(0)
	office.free()
	await process_frame

	if not failures.is_empty():
		for failure: String in failures:
			push_error("MARKET_CONTRACT_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MARKET_CONTRACT_OFFICE_INTEGRATION_TEST_PASSED flow=review-board-select-sign-C directive=paused contract=authoritative reserve=exact fund=no-debit")
	quit(0)


func _press(button: Button) -> void:
	if button != null and not button.disabled:
		button.pressed.emit()


func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	Input.parse_input_event(event)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
