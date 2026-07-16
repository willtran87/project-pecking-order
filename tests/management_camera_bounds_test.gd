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
	controller.set_overview_bounds(Rect2(Vector2(-12.0, -9.0), Vector2(48.0, 52.0)), 4.0)
	_check(is_equal_approx(float(controller.get("_desired_size")), focused_size), "campus growth must not interrupt an active inspection shot", failures)
	controller.show_overview()
	_check(is_equal_approx(float(controller.get("_desired_size")), float(controller.overview_bounds_frame().get("size", 0.0))), "returning to overview should use the latest commissioned campus frame", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("MANAGEMENT_CAMERA_BOUNDS_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MANAGEMENT_CAMERA_BOUNDS_TEST_PASSED frame=commissioned-campus focus=preserved")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
