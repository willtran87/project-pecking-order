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
	var routing_ui := office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	var dossier := office.find_child("PeckworkAssignmentDossier", true, false) as PanelContainer
	var assist_button := office.find_child("PeckAssistButton", true, false) as Button

	_check(simulation != null, "Office should expose its authoritative simulation", failures)
	_check(clock != null, "Office should expose its simulation clock", failures)
	_check(routing_ui != null, "Office should install the Peckwork routing interface", failures)
	_check(dossier != null, "routing interface should build the selected-hen dossier", failures)
	_check(assist_button != null, "selected-hen dossier should contain a Priority Peck button", failures)
	_check(dossier != null and not dossier.is_visible_in_tree(), "dossier should remain hidden before a hen is selected", failures)
	_check(assist_button != null and not assist_button.is_visible_in_tree(), "Priority Peck should not float outside a closed dossier", failures)

	if routing_ui != null:
		routing_ui.set_focus(0)
	await process_frame
	_check(dossier != null and dossier.is_visible_in_tree(), "selecting a hen should reveal the dossier", failures)
	_check(assist_button != null and assist_button.is_visible_in_tree(), "selecting a hen should reveal Priority Peck inside the dossier", failures)
	_check(assist_button != null and assist_button.disabled, "Priority Peck should remain locked before a policy is authorized", failures)
	_check(assist_button != null and "NO ACTIVE FILE" in assist_button.text, "idle hens should explain that no claim can be assisted", failures)
	if dossier != null and assist_button != null:
		var dossier_rect := dossier.get_global_rect().grow(0.5)
		var button_rect := assist_button.get_global_rect()
		_check(
			dossier_rect.has_point(button_rect.position) and dossier_rect.has_point(button_rect.end),
			"Priority Peck should be fully contained by the selected-hen dossier",
			failures,
		)

	# Authorize the morning policy through the visible management controls so the
	# Office owns the same transition and interaction locks used by a player.
	var policy_button := office.find_child("DecisionOption_shell_assurance", true, false) as Button
	var confirm_button := office.find_child("ConfirmDecisionButton", true, false) as Button
	_check(policy_button != null and confirm_button != null, "opening policy controls should exist", failures)
	_press(policy_button)
	_press(confirm_button)
	await process_frame
	_check(
		simulation != null and simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING,
		"authorizing a policy should start the authoritative shift",
		failures,
	)

	# Build a real claim rhythm using authoritative ticks. Keeping the game clock
	# paused makes this deterministic and lets the test prove that a visible open
	# timing window still cannot be stamped while time is stopped.
	if clock != null:
		clock.set_speed(0)
	if simulation != null:
		simulation.set_worker_at_workstation(0, true)
	var first_window_open := _advance_until_assist_available(simulation, 0)
	await process_frame
	_check(first_window_open, "a seated working hen should enter the Priority Peck timing window", failures)
	_check(
		simulation != null and bool(simulation.peck_assist_status(0).get("available", false)),
		"authoritative status should report the live timing window",
		failures,
	)
	_check(assist_button != null and assist_button.disabled, "paused time should lock the Priority Peck button", failures)
	_check(
		assist_button != null and "Resume" in assist_button.tooltip_text,
		"paused Priority Peck should tell the player how to unlock it",
		failures,
	)
	var uses_before_pause_attempt := simulation.peck_assists_used_today if simulation != null else -1
	if assist_button != null:
		assist_button.pressed.emit()
	await process_frame
	_check(
		simulation != null and simulation.peck_assists_used_today == uses_before_pause_attempt,
		"a paused button invocation must not mutate authoritative assist usage",
		failures,
	)

	if clock != null:
		clock.set_speed(1)
	await process_frame
	_check(assist_button != null and not assist_button.disabled, "resuming the live clock should unlock an open timing window", failures)
	_check(assist_button != null and "PECK" in assist_button.text, "open timing window should present a concise action label", failures)
	var first_progress_before := _worker_progress(simulation, 0)
	var first_claim_id := int(simulation.peck_assist_status(0).get("claim_id", -1)) if simulation != null else -1
	var uses_before_mouse := simulation.peck_assists_used_today if simulation != null else -1
	if assist_button != null:
		await _mouse_click(assist_button)
	await process_frame
	var first_result := simulation.last_peck_assist if simulation != null else {}
	_check(
		simulation != null and simulation.peck_assists_used_today == uses_before_mouse + 1,
		"clicking the dossier button should invoke one authoritative Priority Peck",
		failures,
	)
	_check(
		int(first_result.get("worker_id", -1)) == 0 and int(first_result.get("claim_id", -1)) == first_claim_id,
		"mouse invocation should stamp the focused hen's exact active claim",
		failures,
	)
	_check(_worker_progress(simulation, 0) > first_progress_before, "accepted mouse invocation should advance authoritative claim progress", failures)
	_check(assist_button != null and assist_button.disabled, "a stamped claim should immediately lock against duplicate input", failures)
	_check(assist_button != null and "PRIORITY FILED" in assist_button.text, "button should confirm the completed stamp", failures)

	# The semantic action must share the same authoritative route. Prepare a new
	# worker's window, then inject the mapped action rather than calling Office
	# internals; this covers keyboard/gamepad remapping without coupling to KEY_E.
	if clock != null:
		clock.set_speed(0)
	if simulation != null:
		simulation.set_worker_at_workstation(0, false)
		simulation.set_worker_at_workstation(1, true)
	if routing_ui != null:
		routing_ui.set_focus(1)
	var second_window_open := _advance_until_assist_available(simulation, 1)
	await process_frame
	_check(second_window_open, "a second seated hen should receive an independent timing window", failures)
	_check(InputMap.has_action(&"peck_assist"), "Office should register a semantic peck_assist action", failures)
	_check(_action_has_keyboard_or_gamepad_binding(&"peck_assist"), "peck_assist should expose keyboard or gamepad input", failures)
	if clock != null:
		clock.set_speed(1)
	await process_frame
	var second_claim_id := int(simulation.peck_assist_status(1).get("claim_id", -1)) if simulation != null else -1
	var uses_before_semantic := simulation.peck_assists_used_today if simulation != null else -1
	var semantic_event := InputEventAction.new()
	semantic_event.action = &"peck_assist"
	semantic_event.pressed = true
	semantic_event.strength = 1.0
	Input.parse_input_event(semantic_event)
	await process_frame
	var second_result := simulation.last_peck_assist if simulation != null else {}
	_check(
		simulation != null and simulation.peck_assists_used_today == uses_before_semantic + 1,
		"semantic peck_assist input should invoke one authoritative action",
		failures,
	)
	_check(
		int(second_result.get("worker_id", -1)) == 1 and int(second_result.get("claim_id", -1)) == second_claim_id,
		"semantic input should stamp the focused hen's exact active claim",
		failures,
	)

	# Let short feedback cues retire before tearing down the whole office; the
	# dummy headless audio driver otherwise reports live playback resources.
	await create_timer(0.4).timeout
	office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("PECK_ASSIST_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PECK_ASSIST_UI_TEST_PASSED dossier=contained mouse=authoritative paused=locked semantic_input=authoritative")
	quit(0)


func _advance_until_assist_available(simulation: DepartmentSimulation, worker_id: int) -> bool:
	if simulation == null:
		return false
	for _step in 32:
		if bool(simulation.peck_assist_status(worker_id).get("available", false)):
			return true
		simulation.advance_tick()
	return bool(simulation.peck_assist_status(worker_id).get("available", false))


func _worker_progress(simulation: DepartmentSimulation, worker_id: int) -> float:
	if simulation == null:
		return -1.0
	for worker_value in simulation.snapshot().get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return float(worker.get("progress", -1.0))
	return -1.0


func _mouse_click(button: Button) -> void:
	var position := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	root.push_input(motion, true)
	await process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	root.push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	root.push_input(release, true)
	await process_frame


func _action_has_keyboard_or_gamepad_binding(action: StringName) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey or event is InputEventJoypadButton:
			return true
	return false


func _press(button: Button) -> void:
	if button != null and not button.disabled:
		button.pressed.emit()


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
