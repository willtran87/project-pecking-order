extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	for _frame in 24:
		await process_frame
	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	clock.set_speed(0)
	var snapshot := simulation.snapshot(true, true)
	office.call("_apply_snapshot_presentation", snapshot)
	var exact_before := int(simulation.runtime_projection_cache_diagnostics().get("exact_builds", 0))
	var retained := snapshot.duplicate(true)
	for _pass in 3:
		office.call("_apply_snapshot_presentation", snapshot)
	var failures: Array[String] = []
	if int(simulation.runtime_projection_cache_diagnostics().get("exact_builds", 0)) != exact_before:
		failures.append("Presenting a settled clock snapshot must not rebuild exact management projections")
	if snapshot != retained:
		failures.append("Presentation must not mutate the clock's retained snapshot")
	# Focus and pause copy must still follow the supplied state immediately.
	var next_moment: Dictionary = office.call("_next_moment_target_state", snapshot)
	office.call("_refresh_floor_input_context", snapshot)
	var next_button := office.get("_next_moment_button") as Button
	if next_button == null or next_button.tooltip_text != String(next_moment.get("detail", "")):
		failures.append("Next Moment must explain the supplied current target")
	office.free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("live_presentation_snapshot_test: %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
