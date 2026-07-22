extends SceneTree


const OfficeActionCatalogScript := preload("res://core/settings/office_action_catalog.gd")

var _stage := "boot"


func _init() -> void:
	create_timer(30.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	OfficeActionCatalogScript.reset_all()

	var stage := Node3D.new()
	root.add_child(stage)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 40.0
	camera.position = Vector3(24.0, 18.0, 34.0)
	stage.add_child(camera)
	camera.current = true
	var home_target := Vector3(6.0, 0.65, 10.0)
	camera.look_at(home_target)
	var controller := ManagementCameraController.new()
	stage.add_child(controller)
	var workers: Dictionary[int, ChickenView] = {}
	controller.configure(camera, workers, home_target)
	var commissioned_bounds := Rect2(Vector2(-12.0, -8.0), Vector2(40.0, 36.0))
	controller.set_overview_bounds(commissioned_bounds, 4.0)
	await process_frame

	_check(controller.camera_mode() == "home", "configure should establish the explicit Home mode", failures)
	var home_state := controller.navigation_state()

	_stage = "overview precision wheel zoom"
	await _send_wheel(MOUSE_BUTTON_WHEEL_UP, 1.0, Vector2(920.0, 360.0))
	var one_notch_state := controller.navigation_state()
	_check(
		String(one_notch_state.get("mode", "")) == "free_overview",
		"overview wheel input should enter bounded free-overview mode",
		failures,
	)
	_check(
		float(one_notch_state.get("desired_size", INF)) < float(home_state.get("home_size", 0.0)),
		"overview wheel-up should zoom in",
		failures,
	)
	var one_notch_size := float(one_notch_state.get("desired_size", 0.0))
	controller.show_overview()
	await _send_wheel(MOUSE_BUTTON_WHEEL_UP, 2.0, Vector2(920.0, 360.0))
	var precision_size := float(controller.navigation_state().get("desired_size", 0.0))
	_check(
		precision_size < one_notch_size,
		"wheel factor should preserve precision-scroll magnitude instead of treating every event as one notch",
		failures,
	)

	_stage = "middle-mouse drag"
	controller.show_overview()
	await _send_mouse_button(MOUSE_BUTTON_MIDDLE, true, Vector2(640.0, 360.0))
	await _send_mouse_motion(Vector2(90.0, -35.0), Vector2(730.0, 325.0))
	await _send_mouse_button(MOUSE_BUTTON_MIDDLE, false, Vector2(730.0, 325.0))
	var mouse_drag_state := controller.navigation_state()
	_check(
		String(mouse_drag_state.get("mode", "")) == "free_overview",
		"middle-mouse drag should enter free overview",
		failures,
	)
	_check(
		_target_inside_bounds(mouse_drag_state.get("view_target", Vector3.ZERO) as Vector3, commissioned_bounds),
		"mouse drag must stay inside commissioned bounds",
		failures,
	)

	_stage = "bounded keyboard pan and Home reset"
	controller.show_overview()
	await _hold_key(KEY_D, 4)
	var keyboard_state := controller.navigation_state()
	var keyboard_target := keyboard_state.get("view_target", Vector3.ZERO) as Vector3
	_check(
		String(keyboard_state.get("mode", "")) == "free_overview",
		"WASD/arrow navigation should leave authored Home for free overview",
		failures,
	)
	_check(_target_inside_bounds(keyboard_target, commissioned_bounds), "keyboard pan must stay inside commissioned bounds", failures)
	await _send_key(KEY_HOME, true)
	await _send_key(KEY_HOME, false)
	var reset_state := controller.navigation_state()
	_check(String(reset_state.get("mode", "")) == "home", "Home should restore authored framing", failures)
	_check(
		(reset_state.get("view_target", Vector3.INF) as Vector3).is_equal_approx(
			home_state.get("home_target", Vector3.ZERO) as Vector3
		),
		"Home should restore the exact commissioned target",
		failures,
	)
	_check(
		is_equal_approx(
			float(reset_state.get("desired_size", 0.0)),
			float(home_state.get("home_size", -1.0))
		),
		"Home should restore the exact commissioned orthographic size",
		failures,
	)
	var key_zoom_in := InputEventKey.new()
	key_zoom_in.physical_keycode = KEY_EQUAL
	key_zoom_in.pressed = true
	var key_zoom_consumed := bool(controller.call("_handle_navigation_key", key_zoom_in))
	_check(
		key_zoom_consumed
		and float(controller.navigation_state().get("desired_size", INF))
		< float(reset_state.get("desired_size", 0.0)),
		"the semantic keyboard Zoom In action should leave Home at a smaller bounded size",
		failures,
	)
	controller.show_overview()

	_stage = "sub-frame keyboard tap"
	controller.show_overview()
	var tap_start := controller.navigation_state().get("view_target", Vector3.ZERO) as Vector3
	var tap_press := InputEventKey.new()
	tap_press.physical_keycode = KEY_RIGHT
	tap_press.pressed = true
	var tap_release := InputEventKey.new()
	tap_release.physical_keycode = KEY_RIGHT
	tap_release.pressed = false
	controller.call("_handle_navigation_key", tap_press)
	controller.call("_handle_navigation_key", tap_release)
	var tap_state := controller.navigation_state()
	_check(
		String(tap_state.get("mode", "")) == "free_overview"
		and not (tap_state.get("view_target", Vector3.ZERO) as Vector3).is_equal_approx(tap_start),
		"a complete keyboard tap between process frames should still pan immediately",
		failures,
	)

	_stage = "controller axes"
	await _send_joy_axis(JOY_AXIS_LEFT_X, 1.0)
	await process_frame
	await process_frame
	await _send_joy_axis(JOY_AXIS_LEFT_X, 0.0)
	var stick_state := controller.navigation_state()
	_check(String(stick_state.get("mode", "")) == "free_overview", "left stick should pan in free overview", failures)
	_check(
		_target_inside_bounds(stick_state.get("view_target", Vector3.ZERO) as Vector3, commissioned_bounds),
		"controller pan must stay inside commissioned bounds",
		failures,
	)
	var stick_size_before := float(stick_state.get("desired_size", 0.0))
	await _send_joy_axis(JOY_AXIS_RIGHT_Y, -1.0)
	await process_frame
	await process_frame
	await _send_joy_axis(JOY_AXIS_RIGHT_Y, 0.0)
	_check(
		float(controller.navigation_state().get("desired_size", INF)) < stick_size_before,
		"right-stick up should zoom in",
		failures,
	)

	_stage = "rebound semantic camera controls"
	controller.show_overview()
	var remapped_right := InputEventKey.new()
	remapped_right.physical_keycode = KEY_J
	var pan_rebind: Dictionary = OfficeActionCatalogScript.rebind_action(
		&"camera_pan_right",
		[remapped_right],
	)
	var before_old_right := controller.navigation_state().get("view_target", Vector3.ZERO) as Vector3
	var old_right := InputEventKey.new()
	old_right.physical_keycode = KEY_D
	old_right.pressed = true
	var old_consumed := bool(controller.call("_handle_navigation_key", old_right))
	var after_old_right := controller.navigation_state().get("view_target", Vector3.ZERO) as Vector3
	var new_right := InputEventKey.new()
	new_right.physical_keycode = KEY_J
	new_right.pressed = true
	var new_consumed := bool(controller.call("_handle_navigation_key", new_right))
	var after_new_right := controller.navigation_state().get("view_target", Vector3.ZERO) as Vector3
	_check(
		bool(pan_rebind.get("accepted", false))
		and not old_consumed and after_old_right.is_equal_approx(before_old_right)
		and new_consumed and not after_new_right.is_equal_approx(before_old_right),
		"camera pan should follow the live semantic binding instead of hard-coded WASD",
		failures,
	)
	new_right.pressed = false
	controller.call("_handle_navigation_key", new_right)
	var remapped_zoom := InputEventJoypadButton.new()
	remapped_zoom.button_index = JOY_BUTTON_LEFT_SHOULDER
	var zoom_rebind: Dictionary = OfficeActionCatalogScript.rebind_action(
		&"camera_zoom_in",
		[remapped_zoom],
	)
	var size_before_button := float(controller.navigation_state().get("desired_size", 0.0))
	remapped_zoom.pressed = true
	var zoom_consumed := bool(controller.call("_handle_navigation_button", remapped_zoom))
	_check(
		bool(zoom_rebind.get("accepted", false))
		and zoom_consumed
		and float(controller.navigation_state().get("desired_size", INF)) < size_before_button,
		"a rebound gamepad button should invoke the same bounded camera zoom authority",
		failures,
	)
	remapped_zoom.pressed = false
	controller.call("_handle_navigation_button", remapped_zoom)
	OfficeActionCatalogScript.reset_action(&"camera_pan_right")
	OfficeActionCatalogScript.reset_action(&"camera_zoom_in")

	_stage = "touch drag and pinch"
	controller.show_overview()
	await _send_touch(0, Vector2(640.0, 360.0), true)
	await _send_touch_drag(0, Vector2(700.0, 360.0), Vector2(60.0, 0.0))
	await _send_touch(0, Vector2(700.0, 360.0), false)
	_check(
		controller.camera_mode() == "free_overview",
		"a one-finger drag should pan instead of selecting",
		failures,
	)
	var touch_size_before := float(controller.navigation_state().get("desired_size", 0.0))
	await _send_touch(0, Vector2(560.0, 360.0), true)
	await _send_touch(1, Vector2(720.0, 360.0), true)
	await _send_touch_drag(1, Vector2(800.0, 360.0), Vector2(80.0, 0.0))
	await _send_touch(1, Vector2(800.0, 360.0), false)
	await _send_touch(0, Vector2(560.0, 360.0), false)
	_check(
		float(controller.navigation_state().get("desired_size", INF)) < touch_size_before,
		"an outward two-finger pinch should zoom in",
		failures,
	)
	var host_zoom_size := float(controller.navigation_state().get("desired_size", 0.0))
	controller.request_zoom_step(false)
	_check(
		float(controller.navigation_state().get("desired_size", 0.0)) > host_zoom_size,
		"the allow-listed Web host zoom step should use the same bounded camera authority",
		failures,
	)
	_check(
		controller.selection_radius_pixels(true) >= controller.selection_radius_pixels(false),
		"touch selection should never be less forgiving than mouse selection",
		failures,
	)

	_stage = "landmark clamp"
	controller.focus_point(Vector3(10.0, 1.0, 20.0), "CAMPUS PORTFOLIO", 0.0, 19.5)
	_check(controller.camera_mode() == "landmark_focus", "focus_point should establish landmark mode", failures)
	_check(
		is_equal_approx(float(controller.navigation_state().get("desired_size", 0.0)), 19.5),
		"wide landmark framing must not be silently clamped to the 14.5 worker-focus cap",
		failures,
	)
	controller.set_overview_bounds(commissioned_bounds, 4.0)
	_check(
		is_equal_approx(
			(controller.navigation_state().get("view_target", Vector3.ZERO) as Vector3).y,
			1.0,
		),
		"campus-bound refreshes should preserve a landmark's authored subject height",
		failures,
	)

	_stage = "event prior-view restoration"
	controller.show_overview()
	controller.call("_pan_by_screen_delta", Vector2(-180.0, 90.0))
	controller.call("_zoom_at_screen", 0.72, Vector2(860.0, 330.0))
	var prior_view := controller.navigation_state()
	controller.show_event_focus(Vector3(2.0, 1.2, 4.0), "DELIVERY FILED", 0.25, true)
	_check(controller.camera_mode() == "event_focus", "accepted event focus should use explicit event mode", failures)
	await create_timer(0.35).timeout
	var restored_view := controller.navigation_state()
	_check(
		String(restored_view.get("mode", "")) == String(prior_view.get("mode", "")),
		"event completion should restore the prior camera mode",
		failures,
	)
	_check(
		(restored_view.get("view_target", Vector3.INF) as Vector3).is_equal_approx(
			prior_view.get("view_target", Vector3.ZERO) as Vector3
		),
		"event completion should restore the prior panned target",
		failures,
	)
	_check(
		is_equal_approx(
			float(restored_view.get("desired_size", 0.0)),
			float(prior_view.get("desired_size", -1.0))
		),
		"event completion should restore the prior zoom",
		failures,
	)

	_stage = "input context lock"
	controller.set_process_input(false)
	controller.set_process_unhandled_input(false)
	controller.set("_joy_pan", Vector2.ONE)
	var locked_target := controller.navigation_state().get("view_target", Vector3.ZERO) as Vector3
	await process_frame
	await process_frame
	_check(
		(controller.navigation_state().get("view_target", Vector3.INF) as Vector3).is_equal_approx(locked_target),
		"disabled camera input should clear continuous axes rather than leaking behind Flockwatch",
		failures,
	)
	_check(
		not controller.is_processing_input()
		and not controller.is_processing_unhandled_input(),
		"modal context should disable both pre-GUI and fallback camera input phases",
		failures,
	)
	controller.set_process_input(true)
	controller.set_process_unhandled_input(true)

	stage.free()
	await process_frame
	OfficeActionCatalogScript.reset_all()
	if not failures.is_empty():
		for failure: String in failures:
			push_error("MANAGEMENT_CAMERA_NAVIGATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MANAGEMENT_CAMERA_NAVIGATION_TEST_PASSED modes=home+free+landmark+event input=mouse+semantic-keyboard+rebound-button+controller+touch bounds=commissioned event=restored")
	quit(0)


func _send_wheel(button: MouseButton, factor: float, position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.factor = factor
	event.position = position
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame


func _send_mouse_button(button: MouseButton, pressed: bool, position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.position = position
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame


func _send_mouse_motion(relative: Vector2, position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	event.position = position
	Input.parse_input_event(event)
	await process_frame


func _send_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame


func _hold_key(keycode: Key, frames: int) -> void:
	await _send_key(keycode, true)
	for _frame in range(frames):
		await process_frame
	await _send_key(keycode, false)


func _send_joy_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
	await process_frame


func _send_touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame


func _send_touch_drag(index: int, position: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	event.relative = relative
	Input.parse_input_event(event)
	await process_frame


func _target_inside_bounds(target: Vector3, bounds: Rect2) -> bool:
	return (
		target.x >= bounds.position.x - 0.001
		and target.x <= bounds.end.x + 0.001
		and target.z >= bounds.position.y - 0.001
		and target.z <= bounds.end.y + 0.001
	)


func _on_watchdog_timeout() -> void:
	push_error("MANAGEMENT_CAMERA_NAVIGATION_TEST_TIMEOUT stage=%s" % _stage)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
