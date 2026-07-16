extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var view := ChickenView.new()
	view.configure({
		"id": 0,
		"name": "Mabel",
		"desk_index": 0,
		"state": ChickenState.WorkState.IDLE,
		"state_label": "AVAILABLE",
		"progress": 0.0,
		"stress": 8.0,
	})
	root.add_child(view)

	var home := Vector3(0.0, 0.0, 1.0)
	var break_socket := Vector3(-0.65, 0.0, 1.0)
	var presence_events: Array[bool] = []
	view.workstation_presence_changed.connect(func(_worker_id: int, is_present: bool) -> void:
		presence_events.append(is_present)
	)
	view.assign_office_route(
		Vector3(0.0, 0.0, 1.55),
		home,
		break_socket,
		[home],
		[break_socket]
	)
	await _wait_until_seated(view, 240)
	_check(view.is_seated_at_workstation(), "fixture employee should visibly settle at her chair", failures)

	var duty_position := Vector3(2.2, 0.0, 2.6)
	var face_point := duty_position + Vector3(0.0, 0.0, 1.0)
	var outbound: Array[Vector3] = [
		Vector3(0.0, 0.0, 1.5),
		Vector3(1.3, 0.0, 1.5),
		Vector3(1.3, 0.0, 2.6),
		duty_position,
	]
	var return_route: Array[Vector3] = [
		Vector3(1.3, 0.0, 2.6),
		Vector3(1.3, 0.0, 1.5),
		Vector3(0.0, 0.0, 1.5),
		home,
	]
	view.assign_campus_duty(outbound, duty_position, face_point)
	_check(view.has_campus_duty_assignment(), "campus assignment should become active immediately", failures)
	_check(view.campus_duty_phase() == &"campus_outbound", "assignment should begin on the authored outbound route", failures)
	_check(not view.is_seated_at_workstation(), "leaving for campus duty should clear visible seating immediately", failures)
	_check(not presence_events.is_empty() and not presence_events[presence_events.size() - 1], "campus departure should emit workstation absence", failures)

	# Neither a simulation break transition nor an office celebration may steal
	# the employee away from an active campus commute.
	view.apply_snapshot({
		"state": ChickenState.WorkState.BREAK,
		"stress": 12.0,
		"secondary_specialty": "",
	})
	view.attend_feed_party(
		[Vector3(-1.0, 0.0, 1.0)],
		[home],
		Vector3(-1.0, 0.0, 1.0),
		Vector3(-1.0, 0.0, 1.6)
	)
	view.stage_at_workstation_for_introduction()
	_check(view.campus_duty_phase() == &"campus_outbound", "break, feed, and staging requests must not override campus transit", failures)
	_check(not view.is_attending_feed_party(), "campus employees should not be rerouted into a feed party", failures)

	await _wait_until_at_duty(view, 360)
	_check(view.is_at_campus_duty_station(), "employee should reach and hold at the authored duty socket", failures)
	_check(view.global_position.distance_to(duty_position) <= 0.06, "campus duty should snap only to the authored socket", failures)
	for _frame in 24:
		await physics_frame
	_check(view.global_position.distance_to(duty_position) <= 0.06, "employee should remain at the duty socket while assigned", failures)
	_check(absf(wrapf(view.rotation.y, -PI, PI)) <= 0.05, "employee should face the authored campus work point", failures)
	_check(not view.is_seated_at_workstation(), "on-duty employee must remain absent from the workstation", failures)

	view.return_from_campus_duty(return_route)
	_check(view.campus_duty_phase() == &"campus_return", "unassignment should begin the authored return route", failures)
	await _wait_until_seated(view, 360)
	_check(not view.has_campus_duty_assignment(), "campus assignment should clear after reaching the chair", failures)
	_check(view.campus_duty_phase() == &"", "completed campus return should expose no active duty phase", failures)
	_check(view.is_seated_at_workstation(), "workstation presence should resume only after the seated blend completes", failures)
	_check(not presence_events.is_empty() and presence_events[presence_events.size() - 1], "returning employee should emit workstation presence once seated", failures)

	# A reassignment made while the old return is active is queued. The employee
	# must visit the old duty socket, return to her chair, then take the new route.
	var second_duty := Vector3(2.2, 0.0, 3.5)
	var second_outbound: Array[Vector3] = [
		Vector3(0.0, 0.0, 1.5),
		Vector3(1.3, 0.0, 1.5),
		Vector3(1.3, 0.0, 3.5),
		second_duty,
	]
	view.assign_campus_duty(outbound, duty_position, face_point)
	view.return_from_campus_duty(return_route)
	view.assign_campus_duty(second_outbound, second_duty, second_duty + Vector3(0.0, 0.0, 1.0))
	_check(view.campus_duty_phase() == &"campus_outbound", "early return should finish outbound before reversing", failures)
	var reached_old_socket := false
	var touched_home_between_routes := false
	for _frame in 720:
		await physics_frame
		reached_old_socket = reached_old_socket or view.global_position.distance_to(duty_position) <= 0.07
		if reached_old_socket and view.global_position.distance_to(home) <= 0.07:
			touched_home_between_routes = true
		if view.is_at_campus_duty_station() and view.global_position.distance_to(second_duty) <= 0.07:
			break
	_check(reached_old_socket, "early return should still reach the old duty socket before reversing", failures)
	_check(touched_home_between_routes, "queued reassignment should return through the workstation before departing again", failures)
	_check(view.is_at_campus_duty_station() and view.global_position.distance_to(second_duty) <= 0.07, "queued reassignment should finish at the replacement duty socket", failures)
	_check(not view.is_seated_at_workstation(), "queued campus reassignment must never restore desk presence between routes", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("CHICKEN_CAMPUS_DUTY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CHICKEN_CAMPUS_DUTY_TEST_PASSED outbound=held return=seated reassignment=route_safe")
	quit(0)


func _wait_until_seated(view: ChickenView, frame_limit: int) -> void:
	for _frame in frame_limit:
		if view.is_seated_at_workstation():
			return
		await physics_frame


func _wait_until_at_duty(view: ChickenView, frame_limit: int) -> void:
	for _frame in frame_limit:
		if view.is_at_campus_duty_station():
			return
		await physics_frame


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
