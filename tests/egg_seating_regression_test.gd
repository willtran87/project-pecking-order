extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(91)
	_check(simulation.select_directive(&"shell_assurance"), "fixture should authorize its opening directive", failures)
	var view := ChickenView.new()
	view.configure(simulation.snapshot()["workers"][0])
	root.add_child(view)

	var observed := {"eggs": 0, "callback_was_seated": true}
	view.workstation_presence_changed.connect(func(worker_id: int, is_present: bool) -> void:
		simulation.set_worker_at_workstation(worker_id, is_present)
	)
	simulation.egg_laid.connect(func(_worker_id: int, _quality: StringName, _value_cents: int) -> void:
		observed["eggs"] += 1
		observed["callback_was_seated"] = bool(observed["callback_was_seated"]) and view.is_seated_at_workstation()
	)

	var home := Vector3.ZERO
	view.assign_office_route(
		Vector3(0.0, 0.0, 0.55),
		home,
		Vector3(0.55, 0.0, 0.0),
		[home],
		[Vector3(0.55, 0.0, 0.0)]
	)
	simulation.set_worker_at_workstation(0, view.is_seated_at_workstation())

	# Even extreme simulation speed cannot create desk eggs during morning entry.
	for _tick in 60:
		_advance_active_tick(simulation)
	_check(int(observed["eggs"]) == 0, "unseated morning worker must not lay eggs", failures)
	_check(simulation.workers[0].work_progress == 0.0, "unseated morning worker must not advance peckwork", failures)
	_check(simulation.workers[0].work_state == ChickenState.WorkState.IDLE, "unseated morning worker must not claim work", failures)

	await _wait_until_seated(view, 240)
	_check(view.is_seated_at_workstation(), "worker should report seated only after reaching the chair", failures)
	_check(simulation.is_worker_at_workstation(0), "view seating signal should reach the simulation", failures)

	var ticks_to_laying := 0
	while simulation.workers[0].work_state != ChickenState.WorkState.LAYING and ticks_to_laying < 80:
		_advance_active_tick(simulation)
		ticks_to_laying += 1
	_check(simulation.workers[0].work_state == ChickenState.WorkState.LAYING, "seated worker should eventually enter laying state", failures)
	var laying_ticks_before_party := simulation.workers[0].state_ticks_remaining

	view.attend_feed_party(
		[Vector3(0.0, 0.0, 0.48)],
		[home],
		Vector3(0.0, 0.0, 0.48),
		Vector3(0.0, 0.0, 0.95)
	)
	_check(not view.is_seated_at_workstation(), "feed-party departure must clear seating immediately", failures)
	_check(not simulation.is_worker_at_workstation(0), "simulation must know the worker left the desk", failures)
	for _tick in 10:
		_advance_active_tick(simulation)
	_check(int(observed["eggs"]) == 0, "worker away at feed party must not lay", failures)
	_check(simulation.workers[0].state_ticks_remaining == laying_ticks_before_party, "laying countdown must pause while worker is away", failures)

	await _wait_until_feeding(view, 240)
	_check(view.is_attending_feed_party(), "worker should reach the feed-party attendance point", failures)
	view.return_from_feed_party()
	await _wait_until_seated(view, 240)
	_check(view.is_seated_at_workstation(), "worker should return to the chair before production resumes", failures)
	for _tick in laying_ticks_before_party:
		_advance_active_tick(simulation)
	_check(int(observed["eggs"]) == 1, "returning seated worker should complete exactly one egg", failures)
	_check(bool(observed["callback_was_seated"]), "every egg callback must occur while its hen is seated", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("EGG_SEATING_REGRESSION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("EGG_SEATING_REGRESSION_TEST_PASSED morning=blocked feed_party=paused seated_origin=required")
	quit(0)


func _advance_active_tick(simulation: DepartmentSimulation) -> void:
	simulation.advance_tick()
	var pending := simulation.pending_decision_snapshot()
	if StringName(pending.get("kind", &"")) != &"incident":
		return
	var serial := int(pending.get("serial", -1))
	for option_value in pending.get("options", []):
		var option := option_value as Dictionary
		if int(option.get("cost_cents", 0)) == 0:
			simulation.resolve_decision(serial, StringName(option.get("id", &"")))
			return


func _wait_until_seated(view: ChickenView, frame_limit: int) -> void:
	for _frame in frame_limit:
		if view.is_seated_at_workstation():
			return
		await physics_frame


func _wait_until_feeding(view: ChickenView, frame_limit: int) -> void:
	for _frame in frame_limit:
		if view.is_attending_feed_party():
			return
		await physics_frame


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
