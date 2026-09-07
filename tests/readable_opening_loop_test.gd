extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	(office.get("_campaign_ui") as ProbationCampaignUI).show_title(false)
	await process_frame
	_press(office, "NewCampaignButton", failures)
	await process_frame
	await process_frame
	_press(office, "FirstClutchReturnToHen", failures)
	await process_frame
	await process_frame
	office.call("_select_decision_option_by_index", 2)
	office.call("_on_decision_confirm_pressed")
	await process_frame
	await process_frame
	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	var action := office.find_child("FirstClutchDoAction", true, false) as Button
	_check(action != null and action.is_visible_in_tree() and action.text == "ROUTE TO APPEALS", "the specialty lesson must expose a visible, named mouse action", failures)
	var dialogue := office.get("_character_dialogue_ui") as CharacterDialogueUI
	if dialogue.is_blocking():
		_check(action.disabled, "a conversation must retain exclusive input until dismissed", failures)
	while dialogue.is_blocking():
		dialogue.dismiss_current()
		await process_frame
	_press(office, "FirstClutchDoAction", failures)
	await process_frame
	_check(bool(office.first_clutch_snapshot().get("specialty_routed", false)), "clicking the coach must route the real hen", failures)
	_check(action.text == "FILE CHECK-IN", "the same coach action must advance to the next real task", failures)
	_press(office, "FirstClutchDoAction", failures)
	await process_frame
	_check(bool(office.first_clutch_snapshot().get("checkin_filed", false)), "coach check-in must reach personnel state", failures)
	_check(action.text == "START WORK", "a paused production lesson must offer an explicit start action", failures)
	_press(office, "FirstClutchDoAction", failures)
	await process_frame
	_check(clock.speed_index == 1, "start work must resume the real simulation at normal speed", failures)
	clock.set_speed(0)
	var slots := office.get("_opening_egg_slots") as Control
	var goal := office.get("_quota_progress_label") as Label
	for eggs in [0, 1, 2, 3, 4]:
		simulation.eggs_today = eggs
		office.call("_refresh_gameplay_pulse", simulation.snapshot())
		_check(slots.visible == (eggs <= 3), "three-slot goal must retire after the opening clutch", failures)
		_check((office.get("_opening_header_slots") as Control).is_visible_in_tree() == (eggs <= 3), "compact tutorial must retain the opening goal in the header instead of hiding it with the detailed HUD", failures)
		if eggs <= 3:
			_check(int(slots.get("filled")) == eggs, "egg slots must match laid eggs, not a decorative counter", failures)
			_check(("%d/3" % eggs) in goal.text if eggs < 3 else "FIRST CLUTCH" in goal.text, "visible goal must agree with the filled slots", failures)
	var director = preload("res://core/experience/gameplay_pulse_director.gd").new()
	var report: Dictionary = director.compose_report({"eggs": 16, "quota": 16, "credited_cents": 12000, "operating_cost_cents": 3000, "market_contract_breach_cents": 2500})
	_check(report.cards[2].value == "+$65.00", "concise review operating result must include the contract breach debit", failures)
	var nested: Dictionary = director.compose_report({"credited_cents": 1000, "operating_cost_cents": 800, "market_contract": {"breach_cents": 500}})
	_check(nested.cards[2].value == "-$3.00", "nested contract reports must preserve negative results", failures)
	var mabel := (office.get("_worker_views") as Dictionary).get(0) as ChickenView
	mabel.stage_at_workstation_for_introduction()
	office.call("_on_egg_laid", 0, &"sound", 125, 9001, -1)
	simulation.revenue_cents = 20000
	_check(simulation.purchase_upgrade(&"peckwork_tools"), "the equipment demonstration must originate in a real purchase", failures)
	office.call("_on_egg_laid", 0, &"sound", 125, 9002, -1)
	office.call("_on_egg_laid", 0, &"cracked", 0, 9003, -1)
	_check(int((office.get("_upgrade_demonstration") as Dictionary).get("claim_id", -1)) == 9002, "equipment feedback must bind only the first newly laid egg after purchase", failures)
	office.call("_on_egg_reached_presentation", 0, &"sound", 125, 0)
	_check(not (office.get("_upgrade_demonstration") as Dictionary).is_empty(), "an older in-flight egg must not claim the equipment demonstration", failures)
	office.call("_on_egg_reached_presentation", 0, &"sound", 125, 0)
	_check((office.get("_upgrade_demonstration") as Dictionary).is_empty(), "collecting the bound egg must consume the one-shot demonstration", failures)
	var receipt := office.get("_latest_action_outcome_receipt") as Dictionary
	_check("KEYCAPS IN ACTION" in String(receipt.get("title", "")), "the exact equipment benefit must be visible when its egg arrives", failures)
	_check("does not guarantee a clean egg" in String(receipt.entries[0].detail), "equipment feedback must not confuse improved rates with guaranteed outcomes", failures)
	office.queue_free()
	await process_frame
	if failures.is_empty():
		print("READABLE_OPENING_LOOP_TEST_PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _press(office: Office, name: String, failures: Array[String]) -> void:
	var button := office.find_child(name, true, false) as Button
	if button == null or not button.is_visible_in_tree() or button.disabled:
		failures.append("%s must be visible and actionable" % name)
		return
	button.pressed.emit()


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
