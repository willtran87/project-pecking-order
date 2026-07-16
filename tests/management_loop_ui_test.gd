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
	var quota_progress := office.find_child("ShiftQuotaProgress", true, false) as ProgressBar
	var review_panel := office.find_child("DayReviewPanel", true, false) as PanelContainer
	var decision_host := office.find_child("ManagementDecisionHost", true, false) as Control
	var flockwatch_toggle := office.find_child("FlockwatchToggle", true, false) as Button
	_check(clock != null and clock.speed_index == 0, "first shift should begin paused for its morning directive", failures)
	_check(decision_host != null and decision_host.is_visible_in_tree(), "opening directive should be presented as a blocking decision", failures)
	var assurance_option := office.find_child("DecisionOption_shell_assurance", true, false) as Button
	var confirm_decision := office.find_child("ConfirmDecisionButton", true, false) as Button
	var decision_body := office.find_child("DecisionBody", true, false) as Label
	_check(assurance_option != null and confirm_decision != null, "directive modal should expose selectable policy cards and authorization", failures)
	_check(
		decision_body != null
		and "TODAY'S 3 ORDERS" in decision_body.text
		and decision_body.text.count("+3 SCORE") == 3,
		"morning policy should show the concrete scored orders before authorization",
		failures,
	)
	if assurance_option != null and confirm_decision != null:
		assurance_option.pressed.emit()
		_check(not confirm_decision.disabled, "selecting a directive should enable authorization", failures)
		confirm_decision.pressed.emit()
	await process_frame
	_check(not decision_host.is_visible_in_tree(), "authorizing a directive should close the decision modal", failures)
	_check(StringName(simulation.active_directive_snapshot().get("id", &"")) == &"shell_assurance", "authorized directive should become authoritative", failures)
	_check(clock.speed_index == 1, "authorizing the morning directive should start the shift", failures)
	clock.set_speed(0)
	_check(quota_progress != null and int(quota_progress.max_value) == 16 and int(quota_progress.value) == 0, "top HUD should scale the opening objective to four active hens", failures)
	_check(office.find_children("Upgrade_*", "Button", true, false).size() == 3, "Flockwatch should expose three upgrade paths", failures)
	_check(
		flockwatch_toggle != null
		and "FLOCKWATCH" in flockwatch_toggle.text
		and "4 of 4" in flockwatch_toggle.tooltip_text,
		"collapsed ledger should keep its stable identity and narrate active roost capacity",
		failures,
	)
	_check(review_panel != null and not review_panel.is_visible_in_tree(), "daily review should remain hidden during a shift", failures)

	var protected_fund := simulation.current_daily_operating_cost_cents() + simulation.wage_arrears_cents
	var opening_fund := simulation.revenue_cents
	_check(not simulation.purchase_upgrade(&"peckwork_tools"), "operating reserves should block an underfunded keycap requisition", failures)
	_check(simulation.revenue_cents == opening_fund, "a reserve-protected requisition rejection should be atomic", failures)
	simulation.revenue_cents += 500
	_check(simulation.purchase_upgrade(&"peckwork_tools"), "five additional Feed Fund dollars should make one keycap level affordable", failures)
	_check(simulation.revenue_cents == protected_fund, "the exact-price keycap requisition should retain the full operating reserve", failures)
	await process_frame
	var first_keycaps := office.find_children("RequisitionKeycap_0", "MeshInstance3D", true, false)
	_check(first_keycaps.size() == 6, "each workstation should contain a keycap upgrade indicator", failures)
	for keycap in first_keycaps:
		_check((keycap as MeshInstance3D).visible, "purchased keycap level should be visible at every desk", failures)

	simulation.eggs_today = simulation.quota_target
	simulation.cracked_today = 0
	simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	for _step in 3:
		simulation.advance_tick()
		_resolve_pending_incident(simulation)
		clock.set_speed(0)
	await process_frame
	_check(review_panel.is_visible_in_tree(), "shift completion should open the farmer review", failures)
	_check(clock.speed_index == 0, "farmer review should pause the next shift", failures)
	var review_results := office.get("_review_results") as Label
	_check(
		review_results != null
		and "TARGET HARVESTED" in review_results.text
		and "Quality bonus" in review_results.text
		and "Payroll" in review_results.text
		and "Facilities" in review_results.text
		and "Net operating" in review_results.text
		and "Closing Feed Fund" in review_results.text,
		"review should reconcile rewards, obligations, net operations, and closing cash",
		failures,
	)
	# Let the short upgrade/review cues naturally retire before tearing down the
	# entire office; the dummy headless audio driver otherwise reports them as
	# live playback resources during process shutdown.
	await create_timer(0.4).timeout
	office.free()
	await process_frame

	if not failures.is_empty():
		for failure in failures:
			push_error("MANAGEMENT_LOOP_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MANAGEMENT_LOOP_UI_TEST_PASSED objective=visible upgrades=physical review=paused")
	quit(0)


func _resolve_pending_incident(simulation: DepartmentSimulation) -> void:
	var pending := simulation.pending_decision_snapshot()
	if StringName(pending.get("kind", &"")) != &"incident":
		return
	var serial := int(pending.get("serial", -1))
	for option_value in pending.get("options", []):
		var option := option_value as Dictionary
		if int(option.get("cost_cents", 0)) == 0:
			simulation.resolve_decision(serial, StringName(option.get("id", &"")))
			return


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
