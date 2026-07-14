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
	var audio := office.get("_audio_feedback") as OfficeAudioFeedback
	var storytelling := office.get("_office_storytelling") as OfficeStorytelling
	var worker_views: Dictionary = office.get("_worker_views") as Dictionary
	var worker_view := worker_views.get(0) as ChickenView
	_check(simulation != null, "Office should expose its authoritative simulation", failures)
	_check(clock != null, "Office should expose its simulation clock", failures)
	_check(audio != null, "Office should install pooled audio feedback", failures)
	_check(storytelling != null, "Office should install physical egg storytelling", failures)
	_check(worker_view != null, "Office should spawn the first worker view", failures)
	if (
		simulation == null
		or clock == null
		or audio == null
		or storytelling == null
		or worker_view == null
	):
		office.free()
		await process_frame
		_report_and_quit(failures)
		return

	var cue_events: Array[Dictionary] = []
	audio.cue_played.connect(func(cue: StringName) -> void:
		cue_events.append({
			"cue": cue,
			"frame": Engine.get_process_frames(),
		})
	)
	var contact_frames: Array[int] = []
	worker_view.priority_peck_contact.connect(func(
		_worker_id: int,
		_contact_index: int,
		_rating: StringName
	) -> void:
		contact_frames.append(Engine.get_process_frames())
	)
	var lay_release_frames: Array[int] = []
	worker_view.lay_release_reached.connect(func(_worker_id: int) -> void:
		lay_release_frames.append(Engine.get_process_frames())
	)
	var grading_frames: Array[int] = []
	storytelling.egg_graded.connect(func(
		_worker_id: int,
		_quality: StringName,
		_value_cents: int,
		_streak_bonus_cents: int,
		_grading_position: Vector3
	) -> void:
		grading_frames.append(Engine.get_process_frames())
	)
	var presentation_observation := {"frames": [], "chip_seen": false}
	storytelling.egg_reached_presentation_detailed.connect(func(
		_worker_id: int,
		_quality: StringName,
		_value_cents: int,
		_streak_bonus_cents: int
	) -> void:
		(presentation_observation["frames"] as Array).append(Engine.get_process_frames())
		presentation_observation["chip_seen"] = not office.find_children(
			"FundCreditChip", "PanelContainer", true, false
		).is_empty()
	)

	# Start a real shift, then advance authoritative claim work while the clock is
	# paused so the Priority Peck window is deterministic.
	var policy_button := office.find_child("DecisionOption_shell_assurance", true, false) as Button
	var confirm_button := office.find_child("ConfirmDecisionButton", true, false) as Button
	_check(policy_button != null and confirm_button != null, "opening policy controls should exist", failures)
	if policy_button != null and confirm_button != null:
		policy_button.pressed.emit()
		confirm_button.pressed.emit()
	await process_frame
	clock.set_speed(0)
	simulation.set_worker_at_workstation(0, true)
	var assist_available := _advance_until_assist_available(simulation, 0)
	_check(assist_available, "test worker should enter an authoritative Priority Peck window", failures)

	# The accepted request itself must stay silent. ChickenView's delayed contact
	# markers should synchronously drive each accepted peck cue through Office.
	cue_events.clear()
	contact_frames.clear()
	clock.set_speed(1)
	var assists_before := simulation.peck_assists_used_today
	var request_frame := Engine.get_process_frames()
	office.call("_on_peck_assist_requested", 0)
	_check(
		simulation.peck_assists_used_today == assists_before + 1,
		"Office should accept the prepared Priority Peck",
		failures,
	)
	_check(
		_cue_frames(cue_events, &"peck_contact").is_empty(),
		"accepted button/request handling must not play contact audio immediately",
		failures,
	)
	await _wait_physics_frames(2)
	_check(
		_cue_frames(cue_events, &"peck_contact").is_empty(),
		"peck cue should wait for the first visible contact marker",
		failures,
	)
	await _wait_for_cue_count(cue_events, &"peck_contact", 3, 90)
	var peck_cue_frames := _cue_frames(cue_events, &"peck_contact")
	_check(peck_cue_frames.size() == 3, "Priority Peck should produce three contact cues", failures)
	_check(contact_frames.size() == 3, "ChickenView should emit three contact markers", failures)
	_check(
		peck_cue_frames == contact_frames,
		"each peck cue should be emitted synchronously from its contact marker",
		failures,
	)
	_check(
		peck_cue_frames.is_empty() or peck_cue_frames[0] > request_frame,
		"first peck cue should occur after the accepted request frame",
		failures,
	)
	clock.set_speed(0)

	# Drive the worker view through LAYING and then end the state early, matching a
	# fast simulation clock. Office should still play the lay cue at the authored
	# release marker, never at state entry.
	var working_snapshot := _worker_snapshot(simulation, 0)
	working_snapshot["state"] = ChickenState.WorkState.WORKING
	working_snapshot["state_label"] = "PECKING"
	var laying_snapshot := working_snapshot.duplicate(true)
	laying_snapshot["state"] = ChickenState.WorkState.LAYING
	laying_snapshot["state_label"] = "LAYING"
	worker_view.apply_snapshot(working_snapshot)
	cue_events.clear()
	lay_release_frames.clear()
	worker_view.apply_snapshot(laying_snapshot)
	_check(
		_cue_frames(cue_events, &"lay_release").is_empty(),
		"entering LAYING must not play the release cue early",
		failures,
	)
	await _wait_physics_frames(5)
	worker_view.apply_snapshot(working_snapshot)
	await _wait_for_cue_count(cue_events, &"lay_release", 1, 120)
	var lay_cue_frames := _cue_frames(cue_events, &"lay_release")
	_check(lay_release_frames.size() == 1, "worker should emit one authored lay release", failures)
	_check(lay_cue_frames.size() == 1, "Office should play one lay/nest cue", failures)
	_check(
		lay_cue_frames == lay_release_frames,
		"lay cue should be emitted synchronously from the authored release marker",
		failures,
	)
	await _wait_physics_frames(2)

	# Run one egg through the physical production line. Its public storytelling
	# signals and Office audio cues should share frames at grading/presentation,
	# while payout must wait for the credit chip to reach Feed Fund.
	_seat_worker(worker_view)
	_check(worker_view.is_seated_at_workstation(), "egg fixture should honor the seating guard", failures)
	cue_events.clear()
	grading_frames.clear()
	(presentation_observation["frames"] as Array).clear()
	presentation_observation["chip_seen"] = false
	var egg_value_cents := 455
	simulation.revenue_cents += egg_value_cents
	simulation.eggs_today += 1
	office.call("_on_egg_laid", 0, &"sound", egg_value_cents)
	await _wait_for_cue_count(cue_events, &"payout_confirmation", 1, 360)
	var sorter_frames := _cue_frames(cue_events, &"sorter_clack")
	var basket_frames := _cue_frames(cue_events, &"basket_thunk")
	var payout_frames := _cue_frames(cue_events, &"payout_confirmation")
	var presentation_frames := presentation_observation["frames"] as Array
	_check(grading_frames.size() == 1, "physical route should emit one grading gate", failures)
	_check(sorter_frames.size() == 1, "grading should play one sorter/receipt clack", failures)
	_check(sorter_frames == grading_frames, "sorter cue should originate at the grading gate", failures)
	_check(presentation_frames.size() == 1, "physical route should reach presentation once", failures)
	_check(basket_frames.size() == 1, "presentation should play one basket thunk", failures)
	_check(
		basket_frames == _variant_frames_to_int(presentation_frames),
		"basket cue should originate at presentation arrival",
		failures,
	)
	_check(bool(presentation_observation["chip_seen"]), "presentation should spawn a Feed Fund credit chip", failures)
	_check(payout_frames.size() == 1, "credit-chip arrival should play one payout confirmation", failures)
	_check(
		basket_frames.size() == 1
		and payout_frames.size() == 1
		and payout_frames[0] > basket_frames[0],
		"payout confirmation should wait until after basket arrival",
		failures,
	)

	# Headless/reduced-UI fallback must route through the same payout-arrival hook.
	await _wait_physics_frames(8)
	cue_events.clear()
	var saved_ui_root: Variant = office.get("_ui_root")
	office.set("_ui_root", null)
	var fallback_frame := Engine.get_process_frames()
	office.call("_spawn_fund_credit_chip", 123, &"sound")
	office.set("_ui_root", saved_ui_root)
	var fallback_payout_frames := _cue_frames(cue_events, &"payout_confirmation")
	_check(
		fallback_payout_frames == [fallback_frame],
		"missing-UI fallback should confirm payout through the arrival hook immediately",
		failures,
	)

	await _wait_physics_frames(20)
	office.free()
	await process_frame
	_report_and_quit(failures)


func _advance_until_assist_available(simulation: DepartmentSimulation, worker_id: int) -> bool:
	for _step in 40:
		if bool(simulation.peck_assist_status(worker_id).get("available", false)):
			return true
		simulation.advance_tick()
	return bool(simulation.peck_assist_status(worker_id).get("available", false))


func _worker_snapshot(simulation: DepartmentSimulation, worker_id: int) -> Dictionary:
	for worker_value in simulation.snapshot().get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return worker.duplicate(true)
	return {
		"id": worker_id,
		"name": "Feedback Hen",
		"desk_index": 0,
		"state": ChickenState.WorkState.WORKING,
		"progress": 0.0,
		"stress": 12.0,
	}


func _seat_worker(worker_view: ChickenView) -> void:
	worker_view.set("_is_at_workstation", true)
	worker_view.set("_seat_blend", 1.0)
	worker_view.set("_destination_kind", &"home")
	worker_view.set("_is_walking", false)
	worker_view.set("_feed_party_active", false)
	worker_view.set("_feed_party_queued", false)
	worker_view.global_position = worker_view.get("_home_position") as Vector3


func _cue_frames(events: Array[Dictionary], cue: StringName) -> Array[int]:
	var frames: Array[int] = []
	for event in events:
		if StringName(event.get("cue", &"")) == cue:
			frames.append(int(event.get("frame", -1)))
	return frames


func _variant_frames_to_int(values: Array) -> Array[int]:
	var frames: Array[int] = []
	for value in values:
		frames.append(int(value))
	return frames


func _wait_for_cue_count(
	events: Array[Dictionary],
	cue: StringName,
	expected_count: int,
	frame_limit: int
) -> void:
	for _frame in frame_limit:
		if _cue_frames(events, cue).size() >= expected_count:
			return
		await physics_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _frame in frame_count:
		await physics_frame


func _report_and_quit(failures: Array[String]) -> void:
	if not failures.is_empty():
		for failure in failures:
			push_error("FEEDBACK_ORCHESTRA_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FEEDBACK_ORCHESTRA_INTEGRATION_TEST_PASSED peck=contact lay=release grade=sorter presentation=basket payout=arrival+fallback")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
