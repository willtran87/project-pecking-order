extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	var decision_host := office.find_child("ManagementDecisionHost", true, false) as Control
	var confirm_button := office.find_child("ConfirmDecisionButton", true, false) as Button
	var stay_paused_button := office.find_child("ResolveStayPausedButton", true, false) as Button
	var directive_badge := office.get("_directive_badge") as Label
	var review_scrim := office.find_child("DayReviewScrim", true, false) as ColorRect
	var next_shift_button := office.find_child("BeginNextShiftButton", true, false) as Button
	var probation_report := office.find_child("ProbationReportPanel", true, false) as PanelContainer
	var probation_continue := office.find_child("ContinueProbationButton", true, false) as Button
	var filed_credit_label := office.find_child("FiledCreditMemoLabel", true, false) as Label

	_check(simulation != null, "office should expose its authoritative simulation", failures)
	_check(clock != null and clock.speed_index == 0, "morning briefing should pause the simulation clock", failures)
	_check(decision_host != null and decision_host.visible, "morning directive card should open on first presentation", failures)
	_check(simulation != null and simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE, "opening shift should await a directive", failures)
	_check(office.find_children("DecisionOption_*", "Button", true, false).size() == 3, "directive card should present three policy choices", failures)

	var harvest_button := office.find_child("DecisionOption_record_harvest", true, false) as Button
	_check(harvest_button != null and not harvest_button.disabled, "record harvest directive should be selectable", failures)
	_press(harvest_button)
	_check(confirm_button != null and not confirm_button.disabled, "selecting a directive should enable authorization", failures)
	_press(confirm_button)
	await process_frame

	_check(not decision_host.visible, "authorized directive should close the management card", failures)
	_check(clock.speed_index == 1, "authorized morning directive should begin the shift at 1x", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING, "directive authorization should enter the running phase", failures)
	_check(directive_badge != null and "HARVEST" in directive_badge.text, "top HUD should identify the active policy", failures)

	# The first scheduled incident should stop the clock and replace normal controls
	# with a response card. Resolve it without resuming to verify deliberate pause.
	simulation.minute_of_day = DepartmentSimulation.INCIDENT_MINUTES[0] - DepartmentSimulation.MINUTES_PER_TICK
	simulation.advance_tick()
	await process_frame
	_check(decision_host.visible, "first scheduled incident should open a management card", failures)
	_check(clock.speed_index == 0, "incident card should auto-pause the clock", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT, "incident should block the running phase until resolved", failures)
	_check(stay_paused_button != null and stay_paused_button.visible, "incident card should offer a stay-paused resolution", failures)

	var spreadsheet_button := office.find_child("DecisionOption_spreadsheet", true, false) as Button
	_check(spreadsheet_button != null and not spreadsheet_button.disabled, "free ledger response should remain available", failures)
	_press(spreadsheet_button)
	_check(not stay_paused_button.disabled, "selecting an incident response should enable stay-paused resolution", failures)
	_press(stay_paused_button)
	await process_frame
	_check(not decision_host.visible, "resolved incident should close its card", failures)
	_check(clock.speed_index == 0, "resolve-and-stay-paused should preserve a stopped clock", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING, "resolved incident should return simulation authority to the running phase", failures)

	# Resume at 3x, then prove the second incident remembers and restores that speed.
	clock.set_speed(2)
	simulation.minute_of_day = DepartmentSimulation.INCIDENT_MINUTES[1] - DepartmentSimulation.MINUTES_PER_TICK
	simulation.advance_tick()
	await process_frame
	_check(decision_host.visible and clock.speed_index == 0, "second incident should auto-pause a running 3x shift", failures)
	var deny_breaks_button := office.find_child("DecisionOption_deny_breaks", true, false) as Button
	_check(deny_breaks_button != null and not deny_breaks_button.disabled, "free wellness response should be selectable", failures)
	_press(deny_breaks_button)
	_press(confirm_button)
	await process_frame
	_check(not decision_host.visible, "resolve-and-resume should close the incident card", failures)
	_check(clock.speed_index == 2, "resolve-and-resume should restore the pre-incident 3x speed", failures)
	_check(simulation.incidents_resolved_today == 2, "both incident choices should be recorded for the farmer review", failures)

	# Completing the day first reveals the detailed farmer accounting, then the
	# cumulative probation report, before routing into a fresh daily directive.
	simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	simulation.advance_tick()
	await process_frame
	_check(review_scrim != null and review_scrim.visible, "shift completion should show the full-screen farmer review", failures)
	_check(clock.speed_index == 0, "farmer review should pause the next shift", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW, "completed day should remain in review until planning continues", failures)
	_check(next_shift_button != null and next_shift_button.text == "ALLOCATE SHIFT CREDIT", "review should clearly require the closing credit allocation", failures)

	_press(next_shift_button)
	await process_frame
	_check(not review_scrim.visible, "opening the credit memo should close the farmer review", failures)
	_check(decision_host.visible, "closing review should open the required Pecking Order credit memo", failures)
	_check(not probation_report.visible, "probation report must wait until credit is attributed", failures)
	_check(stay_paused_button != null and not stay_paused_button.visible, "credit memo should hide the in-shift stay-paused action", failures)
	_check(confirm_button != null and confirm_button.text == "FILE CREDIT MEMO", "credit memo should use a dedicated filing action", failures)
	_check(clock.speed_index == 0 and simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW, "credit allocation must keep the review clock locked", failures)
	var reward_button := office.find_child("DecisionOption_reward_top_layer", true, false) as Button
	_check(reward_button != null and not reward_button.disabled, "individual merit should be a valid closing attribution", failures)
	_press(reward_button)
	_press(confirm_button)
	await process_frame
	_check(not decision_host.visible, "filed credit memo should close its dossier", failures)
	_check(probation_report != null and probation_report.visible, "filed credit should advance to the cumulative probation report", failures)
	_check(filed_credit_label != null and "REWARD TOP LAYER" in filed_credit_label.text, "probation report should retain the filed attribution", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW and clock.speed_index == 0, "probation report should keep the completed shift locked", failures)
	_press(probation_continue)
	await process_frame
	_check(not probation_report.visible, "filing the probation report should return to the office", failures)
	_check(decision_host.visible, "planning the next shift should open a fresh directive card", failures)
	_check(clock.speed_index == 0, "next morning directive should remain paused for a choice", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE, "next shift should await a new daily policy", failures)

	office.free()
	await process_frame

	if not failures.is_empty():
		for failure in failures:
			push_error("DECISION_LOOP_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("DECISION_LOOP_UI_TEST_PASSED directive=harvest incidents=2 review=credit+probation+briefing")
	quit(0)


func _press(button: Button) -> void:
	if button != null and not button.disabled:
		button.pressed.emit()


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
