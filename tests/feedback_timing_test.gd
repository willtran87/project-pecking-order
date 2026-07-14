extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var view := ChickenView.new()
	view.configure(_worker_snapshot(ChickenState.WorkState.WORKING))
	root.add_child(view)
	var chair := Vector3(0.1, 0.0, 0.1)
	view.assign_office_route(chair, chair, Vector3(0.1, 0.0, 1.0), [], [])
	await process_frame
	await physics_frame

	var sequence_clock := {"start_frame": 0}
	var contact_observations: Array[Dictionary] = []
	view.priority_peck_contact.connect(func(
		emitted_worker_id: int,
		contact_index: int,
		rating: StringName
	) -> void:
		contact_observations.append({
			"worker_id": emitted_worker_id,
			"contact_index": contact_index,
			"rating": rating,
			"seconds": (
				float(Engine.get_physics_frames() - int(sequence_clock["start_frame"]))
				/ float(Engine.physics_ticks_per_second)
			),
		})
	)

	sequence_clock["start_frame"] = Engine.get_physics_frames()
	view.play_peck_assist_feedback(&"perfect")
	await _wait_for_observation_count(contact_observations, 3, 70)
	_verify_contact_sequence(contact_observations, &"perfect", failures)

	# Start the same flourish at a deliberately different ambient phase. A local
	# reset timeline should reproduce the markers instead of inheriting _phase.
	await create_timer(0.137).timeout
	contact_observations.clear()
	sequence_clock["start_frame"] = Engine.get_physics_frames()
	view.play_peck_assist_feedback(&"steady")
	await _wait_for_observation_count(contact_observations, 3, 70)
	_verify_contact_sequence(contact_observations, &"steady", failures)

	var animation_player := view.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var release_clock := {"start_frame": 0}
	var release_observations: Array[Dictionary] = []
	view.lay_release_reached.connect(func(emitted_worker_id: int) -> void:
		release_observations.append({
			"worker_id": emitted_worker_id,
			"seconds": (
				float(Engine.get_physics_frames() - int(release_clock["start_frame"]))
				/ float(Engine.physics_ticks_per_second)
			),
			"animation": (
				String(animation_player.current_animation)
				if animation_player != null
				else ""
			),
		})
	)
	var expected_release_seconds := view.lay_release_delay_seconds()
	release_clock["start_frame"] = Engine.get_physics_frames()
	view.apply_snapshot(_worker_snapshot(ChickenState.WorkState.LAYING))
	# Simulate a fast clock ending authoritative LAYING before the authored clip
	# reaches its marker. ChickenView should hold only through release and emit once.
	await create_timer(0.12).timeout
	view.apply_snapshot(_worker_snapshot(ChickenState.WorkState.WORKING))
	await _wait_for_observation_count(
		release_observations,
		1,
		ceili((expected_release_seconds + 0.50) * Engine.physics_ticks_per_second),
	)
	_check(release_observations.size() == 1, "lay action should emit exactly one release marker", failures)
	if release_observations.size() == 1:
		var release := release_observations[0]
		_check(int(release["worker_id"]) == 7, "lay release should identify its worker", failures)
		_check(
			absf(float(release["seconds"]) - expected_release_seconds) <= 0.075,
			"lay release should align with the imported frame-22 marker",
			failures,
		)
		_check(
			String(release["animation"]).ends_with("Chicken_Lay"),
			"early state exit should hold the authored lay clip through release",
			failures,
		)
	await create_timer(0.20).timeout
	_check(release_observations.size() == 1, "lay marker should not duplicate after release", failures)

	view.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FEEDBACK_TIMING_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print(
		"FEEDBACK_TIMING_TEST_PASSED pecks=3 reset=stable lay_release=%.3fs"
		% expected_release_seconds
	)
	quit(0)


func _worker_snapshot(state: ChickenState.WorkState) -> Dictionary:
	return {
		"id": 7,
		"name": "Timing Hen",
		"desk_index": 0,
		"state": state,
		"state_label": "LAYING" if state == ChickenState.WorkState.LAYING else "PECKING",
		"progress": 42.0,
		"stress": 22.0,
	}


func _wait_for_observation_count(
	observations: Array[Dictionary],
	expected_count: int,
	frame_limit: int
) -> void:
	for _frame in frame_limit:
		if observations.size() >= expected_count:
			return
		await physics_frame


func _verify_contact_sequence(
	observations: Array[Dictionary],
	expected_rating: StringName,
	failures: Array[String]
) -> void:
	_check(observations.size() == 3, "Priority Peck should emit exactly three contacts", failures)
	if observations.size() != 3:
		return
	for contact_index in 3:
		var observation := observations[contact_index]
		_check(int(observation["worker_id"]) == 7, "contact should identify its worker", failures)
		_check(
			int(observation["contact_index"]) == contact_index,
			"Priority Peck contacts should remain ordered 0, 1, 2",
			failures,
		)
		_check(
			StringName(observation["rating"]) == expected_rating,
			"contact should preserve the action rating",
			failures,
		)
		_check(
			absf(
				float(observation["seconds"])
				- ChickenView.PRIORITY_PECK_CONTACT_TIMES[contact_index]
			) <= 0.060,
			"contact %d should stay on its local timeline marker" % contact_index,
			failures,
		)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
