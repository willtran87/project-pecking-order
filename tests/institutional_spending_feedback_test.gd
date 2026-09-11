extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	for _frame in 4:
		await process_frame
	office.call("_prepare_capture_running")
	var simulation := office.get("_simulation") as DepartmentSimulation
	var navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	var staffing_ui := office.get("_staffing_ui") as RoostStaffingUI

	# A paid internship filing stays attached to the same named candidate card
	# after the authoritative mutation changes its status and rebuilds the roster.
	simulation.day = 2
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 100_000
	office.call("_on_snapshot_changed", simulation.snapshot())
	office.call("_set_campaign_modal_open", false)
	office.call("_open_flockwatch_page", FlockwatchNavigation.PAGE_FLOCK)
	var internship_ui := office.find_child(
		"InternshipProgramUI",
		true,
		false,
	) as InternshipProgramUI
	assert(internship_ui != null)
	internship_ui.set_expanded(true)
	await process_frame
	var candidate_id: StringName = &"lottie_ledger"
	var onboard_button := office.find_child(
		"InternOnboard_lottie_ledger",
		true,
		false,
	) as Button
	var intern_card := office.find_child(
		"InternCard_lottie_ledger",
		true,
		false,
	) as Control
	assert(onboard_button != null and intern_card != null)
	var flock_scroll := navigation.page_scroll(FlockwatchNavigation.PAGE_FLOCK)
	_scroll_control_into_view(flock_scroll, intern_card)
	await process_frame
	assert(bool(office.call("_fund_debit_control_is_actually_visible", intern_card)))
	var fund_before_intern := simulation.revenue_cents
	var started_before_intern := int((
		office.call("fund_debit_feedback_snapshot") as Dictionary
	).get("started_total", 0))
	office.call("_on_intern_onboard_requested", candidate_id)
	var debit_state := office.call("fund_debit_feedback_snapshot") as Dictionary
	var receipt := debit_state.get("last_receipt", {}) as Dictionary
	assert(
		fund_before_intern - simulation.revenue_cents
		== InternshipProgramState.ONBOARDING_COST_CENTS
	)
	assert(int(debit_state.get("started_total", -1)) == started_before_intern + 1)
	assert(String(receipt.get("transaction_kind", "")) == "internship")
	assert(String(receipt.get("target_id", "")) == "intern_onboard_lottie_ledger")
	assert(String(receipt.get("target_name", "")) == "InternCard_lottie_ledger")
	assert(
		int(receipt.get("cost_cents", 0))
		== InternshipProgramState.ONBOARDING_COST_CENTS
	)
	var fund_before_repeat := simulation.revenue_cents
	office.call("_on_intern_onboard_requested", candidate_id)
	debit_state = office.call("fund_debit_feedback_snapshot") as Dictionary
	assert(simulation.revenue_cents == fund_before_repeat)
	assert(int(debit_state.get("started_total", -1)) == started_before_intern + 1)

	# A paid management succession uses the stable roster disclosure after the
	# accepted replacement removes the selected candidate from the slate.
	simulation.day = 12
	simulation.owned_facilities[
		DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID
	] = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 100_000
	simulation.export_save_state()
	office.call("_on_snapshot_changed", simulation.snapshot())
	office.call("_open_flockwatch_page", FlockwatchNavigation.PAGE_OPERATIONS)
	staffing_ui.set_managers_expanded(false)
	staffing_ui.set_successors_expanded(true)
	await process_frame
	var manager_target := office.find_child(
		"ManagerRosterToggle",
		true,
		false,
	) as Control
	var recruit_button := office.find_child(
		"RecruitManager_byte_automation",
		true,
		false,
	) as Button
	assert(manager_target != null and recruit_button != null)
	var operations_scroll := navigation.page_scroll(FlockwatchNavigation.PAGE_OPERATIONS)
	_scroll_control_into_view(operations_scroll, manager_target)
	await process_frame
	assert(bool(office.call("_fund_debit_control_is_actually_visible", manager_target)))
	var manager_cost := 0
	for candidate_value in simulation.operations_snapshot().get(
		"manager_candidates",
		[],
	) as Array:
		var candidate := candidate_value as Dictionary
		if StringName(String(candidate.get("id", ""))) == &"byte_automation":
			manager_cost = int(candidate.get("signing_cost_cents", 0))
			break
	assert(manager_cost > 0)
	var fund_before_manager := simulation.revenue_cents
	var started_before_manager := int(debit_state.get("started_total", 0))
	office.call("_on_manager_recruit_requested", &"byte_automation")
	debit_state = office.call("fund_debit_feedback_snapshot") as Dictionary
	receipt = debit_state.get("last_receipt", {}) as Dictionary
	assert(fund_before_manager - simulation.revenue_cents == manager_cost)
	assert(int(debit_state.get("started_total", -1)) == started_before_manager + 1)
	assert(String(receipt.get("transaction_kind", "")) == "management")
	assert(String(receipt.get("target_id", "")) == "manager_recruited_byte_automation")
	assert(String(receipt.get("target_name", "")) == "ManagerRosterToggle")
	assert(int(receipt.get("cost_cents", 0)) == manager_cost)
	var fund_before_manager_repeat := simulation.revenue_cents
	office.call("_on_manager_recruit_requested", &"byte_automation")
	debit_state = office.call("fund_debit_feedback_snapshot") as Dictionary
	assert(simulation.revenue_cents == fund_before_manager_repeat)
	assert(int(debit_state.get("started_total", -1)) == started_before_manager + 1)

	# Accepted assignment instructions carry no immediate cost and therefore do
	# not impersonate a financial transaction.
	var roster := simulation.operations_snapshot().get("manager_roster", []) as Array
	assert(not roster.is_empty())
	var manager_id := StringName(String((roster[0] as Dictionary).get("id", "")))
	var save_before_instruction := simulation.export_save_state()
	office.call("_on_manager_assignment_requested", manager_id, &"whole_flock")
	debit_state = office.call("fund_debit_feedback_snapshot") as Dictionary
	assert(int(debit_state.get("started_total", -1)) == started_before_manager + 1)
	assert(simulation.revenue_cents == int(save_before_instruction.get("revenue_cents", -1)))

	print("INSTITUTIONAL_SPENDING_FEEDBACK_TEST_PASSED")
	office.free()
	await process_frame
	quit(0)


func _scroll_control_into_view(scroll: ScrollContainer, control: Control) -> void:
	assert(scroll != null and control != null)
	var component_offset := (
		control.global_position.y
		- scroll.global_position.y
		+ float(scroll.scroll_vertical)
		- 250.0
	)
	scroll.scroll_vertical = maxi(0, int(component_offset))
