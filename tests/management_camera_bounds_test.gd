extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var stage := Node3D.new()
	root.add_child(stage)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 43.5
	camera.position = Vector3(25.02, 17.50, 36.60)
	stage.add_child(camera)
	var original_target := Vector3(7.72, 0.65, 15.10)
	camera.look_at(original_target)
	var controller := ManagementCameraController.new()
	stage.add_child(controller)
	var workers: Dictionary[int, ChickenView] = {}
	controller.configure(camera, workers, original_target)

	var installed_campus := Rect2(Vector2(-12.0, -9.0), Vector2(43.45, 48.0))
	controller.set_overview_bounds(installed_campus, 4.0)
	var frame := controller.overview_bounds_frame()
	var expected_center := installed_campus.get_center()
	var target: Vector3 = frame.get("target", Vector3.ZERO)
	_check(is_equal_approx(target.x, expected_center.x), "overview target should recenter on commissioned X bounds", failures)
	_check(is_equal_approx(target.z, expected_center.y), "overview target should recenter on commissioned Z bounds", failures)
	_check(float(frame.get("size", 0.0)) >= 43.5, "parcel-derived framing must never crop the authored base office", failures)
	_check(is_equal_approx(float(controller.get("_desired_size")), float(frame.get("size", 0.0))), "an unfocused overview should adopt the parcel-derived size immediately", failures)

	controller.focus_point(Vector3(24.0, 1.0, 8.0), "NORTH MEADOW", 0.0, 12.0)
	var focused_size := float(controller.get("_desired_size"))
	var focused_subject := controller.focus_world_position()
	controller.set_safe_viewport_insets(0.0, 438.0, 0.0, 0.0)
	var safe_state := controller.safe_framing_state()
	_check(bool(safe_state.get("focused", false)), "drawer-safe framing must preserve focus mode", failures)
	_check(
		is_equal_approx(float(safe_state.get("desired_size", 0.0)), focused_size),
		"drawer-safe framing must preserve the active orthographic scale",
		failures,
	)
	_check(
		(safe_state.get("subject", Vector3.ZERO) as Vector3).is_equal_approx(focused_subject),
		"drawer-safe framing must preserve the inspected subject",
		failures,
	)
	_check(
		(safe_state.get("world_offset", Vector3.ZERO) as Vector3).length() > 0.1,
		"a right drawer should reserve a nonzero world-space safe area",
		failures,
	)
	controller.show_event_focus(Vector3(5.0, 1.0, 5.0), "AMBIENT NOTICE", 1.0)
	_check(
		controller.focus_world_position().is_equal_approx(focused_subject),
		"an ambient event must not steal an active player inspection",
		failures,
	)
	var transaction_focus := Vector3(7.3, 1.5, 30.0)
	controller.show_event_focus(transaction_focus, "DELIVERY FILED", 1.0, true)
	_check(
		controller.focus_world_position().is_equal_approx(transaction_focus),
		"an accepted transaction should be able to replace an active inspection",
		failures,
	)
	_check(
		controller.current_focus_label == "DELIVERY FILED",
		"an accepted transaction should publish its authored focus label",
		failures,
	)
	var transaction_size := float(controller.get("_desired_size"))
	controller.set_overview_bounds(Rect2(Vector2(-12.0, -9.0), Vector2(48.0, 52.0)), 4.0)
	_check(is_equal_approx(float(controller.get("_desired_size")), transaction_size), "campus growth must not interrupt an active inspection shot", failures)
	var offsite_event_focus := Vector3(-18.0, 1.0, -13.0)
	controller.show_event_focus(offsite_event_focus, "SERVICE-BAY ARRIVAL", 1.0, true)
	controller.set_overview_bounds(installed_campus, 4.0)
	_check(
		controller.focus_world_position().is_equal_approx(offsite_event_focus),
		"a reversible event shot should retain its authored subject outside ordinary pan bounds",
		failures,
	)
	controller.show_overview()
	_check(is_equal_approx(float(controller.get("_desired_size")), float(controller.overview_bounds_frame().get("size", 0.0))), "returning to overview should use the latest commissioned campus frame", failures)
	controller.set_safe_viewport_insets(0.0, 0.0, 0.0, 0.0)
	_check(
		(controller.safe_framing_state().get("world_offset", Vector3(INF, INF, INF)) as Vector3).is_zero_approx(),
		"closing the drawer should clear only its safe-area shift",
		failures,
	)

	if not failures.is_empty():
		for failure in failures:
			push_error("MANAGEMENT_CAMERA_BOUNDS_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MANAGEMENT_CAMERA_BOUNDS_TEST_PASSED frame=commissioned-campus focus=preserved drawer=safe-inset")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
