extends SceneTree

const Clarity := preload("res://core/experience/loop_readability.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	(office.get("_campaign_ui") as ProbationCampaignUI).show_title(false)
	(office.find_child("NewCampaignButton", true, false) as Button).pressed.emit()
	await process_frame
	await process_frame
	(office.find_child("FirstClutchReturnToHen", true, false) as Button).pressed.emit()
	await process_frame
	office.call("_select_decision_option_by_index", 2)
	office.call("_on_decision_confirm_pressed")
	await process_frame
	var dialogue := office.get("_character_dialogue_ui") as CharacterDialogueUI
	while dialogue.is_blocking():
		dialogue.dismiss_current()
		await process_frame
	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	var action := office.find_child("FirstClutchDoAction", true, false) as Button
	_check(action.text == "ROUTE & START" and not action.disabled, "fresh careers need one actionable route-and-start control", failures)
	_check(int((office.get("_opening_header_slots") as Control).get("goal_count")) == 1, "the first reward must have one goal, not three competing counters", failures)
	action.pressed.emit()
	await process_frame
	_check(office.first_clutch_snapshot().stage == "delivery" and clock.speed_index == 1, "the route must immediately start automatic work", failures)
	_check(not bool(office.first_clutch_snapshot().checkin_filed), "shortening the lesson must not fabricate a paid check-in", failures)
	var restored: Dictionary = office.call("_normalize_first_clutch_state", office.first_clutch_snapshot())
	_check(bool(restored.get("route_first_lesson", false)) and not bool(restored.checkin_filed), "save normalization must preserve the short lesson without inventing actions", failures)
	var landed: Array[Dictionary] = []
	simulation.egg_laid.connect(func(worker_id: int, quality: StringName, value: int):
		if worker_id == 0:
			landed.append({"quality": quality, "value": value})
	)
	clock.set_speed(0)
	var production_ticks := 0
	for step in 100:
		production_ticks += 1
		for worker_id in office.get("_worker_views"):
			var hen := (office.get("_worker_views") as Dictionary)[worker_id] as ChickenView
			hen.stage_at_workstation_for_introduction()
			simulation.set_worker_at_workstation(worker_id, true)
		simulation.advance_tick()
		if not landed.is_empty():
			break
	_check(not landed.is_empty(), "Mabel must produce a real egg without a check-in or timed Peck", failures)
	_check(production_ticks <= 45, "first production must fit within 33.75 simulation seconds after reaching the desk", failures)
	if not landed.is_empty():
		office.call("_on_egg_reached_presentation", 0, landed[0].quality, landed[0].value, 0)
		_check(bool(office.first_clutch_snapshot().completed), "physical collection must complete the shortened lesson", failures)
		_check(simulation.first_clutch_reinvestment_status().status == &"offered", "real egg value must create the authoritative reinvestment offer", failures)
		_check(not (office.get("_decision_host") as Control).visible, "the delivery must have breathing room before another modal", failures)
		var reward_deadline := Time.get_ticks_msec() + 4000
		while not (office.get("_decision_host") as Control).visible and Time.get_ticks_msec() < reward_deadline:
			await process_frame
		_check((office.get("_decision_host") as Control).visible, "the reward choice must open after the bounded pause (pending=%s, now=%s, stage=%s, modal=%s)" % [office.get("_first_reward_ready_msec"), Time.get_ticks_msec(), office.get("_campaign_review_stage"), (office.get("_campaign_ui") as ProbationCampaignUI).is_modal_open()], failures)
	_check(Clarity.attention({"id": "deadline"}).label == "! HELP NEEDED", "deadline needs must outrank normal work", failures)
	_check(Clarity.attention({"id": "sync"}).label == "OPPORTUNITY", "timing windows must read as opportunities, not emergencies", failures)
	_check(Clarity.attention({"id": "steady"}).label == "ALL GOOD", "routine work must look safe to leave alone", failures)
	_check(Clarity.next_shift({"cracked": 2}).strategy == "safe", "next-shift challenge must respond to actual cracks", failures)
	_check(Clarity.next_shift({"overdue_claims": 2}).strategy == "fast", "late files must produce a relevant next-shift challenge", failures)
	if (office.get("_decision_host") as Control).visible:
		office.call("_select_decision_option_by_index", 2)
		office.call("_on_decision_confirm_pressed")
		await process_frame
		dialogue.clear_session()
		office.call("_refresh_gameplay_pulse", simulation.snapshot())
		var lesson_id := -1
		var menu_map: Dictionary = office.get("_active_playbook_menu_map")
		for item_id in menu_map:
			if menu_map[item_id].get("kind", "") == "learn_care":
				lesson_id = int(item_id)
		_check(lesson_id >= 0 and (office.get("_active_playbook_button") as MenuButton).visible, "the post-reward lesson must be reachable in the real plan menu", failures)
		var cash_before := simulation.revenue_cents
		if lesson_id >= 0:
			office.call("_on_active_playbook_item_pressed", lesson_id)
		_check(simulation.revenue_cents == cash_before, "opening the optional lesson must never purchase care", failures)
	office.queue_free()
	await process_frame
	if failures.is_empty():
		print("ROUTE_FIRST_REWARD_TEST_PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
