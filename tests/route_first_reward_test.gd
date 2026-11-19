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
	_check(not dialogue.has_blocking_dialogue(), "first policy must lead straight to routing without a second blocking story", failures)
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
	var first_work_cue := office.call("_first_clutch_coach_snapshot", simulation.snapshot()) as Dictionary
	var first_work_dossier := (office.get("_routing_ui") as PeckworkRoutingUI).routing_lifecycle_state()
	_check(
		String(first_work_cue.get("visual_body", "")) == "NO EXTRA CLICKS  ·  NEXT: EGG"
		and String(first_work_dossier.get("header_copy", "")).begins_with("EGG IN PROGRESS  ·  ")
		and String(first_work_dossier.get("header_copy", "")).ends_with("%")
		and String(first_work_dossier.get("route_hint_copy", "")) == "NO EXTRA CLICKS  ·  NEXT: EGG",
		"first work should visibly explain automatic production instead of implying another required click",
		failures,
	)
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
		var named_delivery := false
		for receipt in office.get("_status_history"):
			if String(receipt).contains("MABEL") and String(receipt).contains("DELIVERED"):
				named_delivery = true
		_check(named_delivery, "the earned delivery receipt must credit Mabel", failures)
		_check(bool(office.first_clutch_snapshot().completed), "physical collection must complete the shortened lesson", failures)
		_check(simulation.first_clutch_reinvestment_status().status == &"offered", "real egg value must create the authoritative reinvestment offer", failures)
		_check(int((office.get("_camera_controller") as ManagementCameraController).get("_focused_worker_id")) == 0, "the first egg must retain the player's hen selection instead of jumping to grading", failures)
		_check(not (office.get("_decision_host") as Control).visible, "the delivery must have breathing room before another modal", failures)
		await create_timer(2.5).timeout
		_check(not (office.get("_decision_host") as Control).visible and clock.speed_index == 0, "reward must remain paused without opening itself on a timer", failures)
		_check(action.is_visible_in_tree() and action.text == "CHOOSE UPGRADE" and not action.disabled, "the same coach must offer a usable next step after payment: visible=%s disabled=%s text=%s coach=%s" % [action.is_visible_in_tree(), action.disabled, action.text, office.call("_first_clutch_coach_snapshot", simulation.snapshot())], failures)
		action.pressed.emit()
		await process_frame
		_check((office.get("_decision_host") as Control).visible, "the player's reward action must open the actual upgrade choice", failures)
	_check(Clarity.attention({"id": "deadline"}).label == "! HELP NEEDED", "deadline needs must outrank normal work", failures)
	_check(Clarity.attention({"id": "sync"}).label == "OPPORTUNITY", "timing windows must read as opportunities, not emergencies", failures)
	_check(Clarity.attention({"id": "steady"}).label == "ALL GOOD", "routine work must look safe to leave alone", failures)
	_check(Clarity.next_shift({"cracked": 2}).strategy == "safe", "next-shift challenge must respond to actual cracks", failures)
	_check(Clarity.next_shift({"overdue_claims": 2}).strategy == "fast", "late files must produce a relevant next-shift challenge", failures)
	if (office.get("_decision_host") as Control).visible:
		office.call("_select_decision_option_by_index", 2)
		office.call("_on_decision_confirm_pressed")
		await process_frame
		office.set("_first_clutch_completion_hold_until_msec", 0)
		office.call("_refresh_first_clutch_ui", simulation.snapshot())
		_check(action.is_visible_in_tree() and action.text == "CONTINUE SHIFT", "the inline goal summary must offer a direct return to play", failures)
		var goal_summary := office.call("_first_clutch_coach_snapshot", simulation.snapshot()) as Dictionary
		_check(String(goal_summary.visual_title).contains(str(simulation.quota_target)) and String(goal_summary.visual_body).contains("5:00 PM"), "the handoff must show the actual quota and deadline", failures)
		_check(int((office.get("_camera_controller") as ManagementCameraController).get("_focused_worker_id")) == 0, "installing the chosen upgrade must keep the player's camera selection", failures)
		action.pressed.emit()
		await process_frame
		_check(bool(office.first_clutch_snapshot().orders_handoff_acknowledged) and clock.speed_index == 1 and not bool(office.get("_flockwatch_open")), "Continue must acknowledge the visible summary and resume without opening a dashboard", failures)
		# The full goals remain available on demand; closing them and pressing
		# Space must resume rather than activate a stale focused ledger control.
		office.call("_on_flockwatch_pressed")
		_check(bool(office.get("_flockwatch_open")), "full goals remain accessible after Continue", failures)
		office.call("_set_flockwatch_open", false)
		clock.set_speed(0)
		(office.get("_flockwatch_toggle") as Button).grab_focus()
		var pause_key := InputEventKey.new()
		pause_key.keycode = KEY_SPACE
		pause_key.physical_keycode = KEY_SPACE
		pause_key.pressed = true
		Input.parse_input_event(pause_key)
		await process_frame
		pause_key = pause_key.duplicate()
		pause_key.pressed = false
		Input.parse_input_event(pause_key)
		await process_frame
		_check(not bool(office.get("_flockwatch_open")) and clock.speed_index == 1, "Space after closing goals must resume play without activating the focused ledger button", failures)
		dialogue.clear_session()
		(office.get("_first_clutch") as Dictionary)["dismissed"] = true
		(simulation.active_playbook as Dictionary)["strategy_preset_id"] = ""
		for worker in simulation.workers:
			worker.current_claim = null
		clock.set_speed(1)
		office.set("_campaign_order_return_cue", {})
		office.set("_routing_return_cue", {})
		var routine_snapshot := simulation.snapshot()
		routine_snapshot["personnel_action_available"] = true
		office.call("_update_guidance", routine_snapshot)
		var guidance := office.get("_guidance_label") as Label
		_check(
			guidance.text.contains("EGGS TO GO")
			and guidance.text.contains("HENS AUTO-WORK")
			and String(office.get("_guidance_action_id")) == "",
			"early-shift guidance should prioritize autonomous quota work over optional care: %s action=%s" % [guidance.text, String(office.get("_guidance_action_id"))],
			failures,
		)
		office.call("_update_guidance", routine_snapshot.merged({"day": 2}, true))
		_check(guidance.text.contains("HENS AUTO-WORK"), "second-shift guidance should keep optional check-in subordinate to the goal: %s" % guidance.text, failures)
		office.call("_update_guidance", routine_snapshot.merged({"day": 3}, true))
		_check(guidance.text.contains("HENS AUTO-WORK"), "Later shifts must keep the quota above optional plans and check-ins", failures)
		clock.set_speed(0)
		var contract_snapshot := routine_snapshot.merged({"contract_board": {"active": {"status": "signed", "required_completed": 3, "short_name": "Test contract"}}}, true)
		office.call("_update_guidance", contract_snapshot)
		_check(String(office.get("_guidance_action_id")) == "resume_shift", "optional contracts must not hide Resume while paused", failures)
		office.call("_update_guidance", routine_snapshot)
		_check(guidance.text.begins_with("RESUME SHIFT") and String(office.get("_guidance_action_id")) == "resume_shift", "Pausing should offer a direct return to production", failures)
		office.call("_on_guidance_action_pressed")
		_check(clock.speed_index == 1 and not bool(office.get("_flockwatch_open")), "Resume guidance must immediately start production", failures)
		office.call("_update_guidance", routine_snapshot.merged({"eggs_today": simulation.quota_target}, true))
		_check(guidance.text.begins_with("TARGET MET"), "a met quota should outrank an unused optional check-in", failures)
		clock.set_speed(0)
		office.call("_update_guidance", routine_snapshot)
		office.call("_apply_readable_loop_hud", routine_snapshot, {"push_luck": {"open": true, "id": ""}})
		_check(String(office.get("_guidance_action_id")) == "resume_shift", "HUD presentation must not replace Resume with Bank or Chase", failures)
		clock.set_speed(1)
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
