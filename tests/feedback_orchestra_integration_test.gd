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
	var routing_ui := office.get("_routing_ui") as PeckworkRoutingUI
	var storytelling := office.get("_office_storytelling") as OfficeStorytelling
	var worker_views: Dictionary = office.get("_worker_views") as Dictionary
	var worker_view := worker_views.get(0) as ChickenView
	var ticker := office.get("_ticker_label") as Label
	_check(simulation != null, "Office should expose its authoritative simulation", failures)
	_check(clock != null, "Office should expose its simulation clock", failures)
	_check(audio != null, "Office should install pooled audio feedback", failures)
	_check(routing_ui != null, "Office should install the selected-hen dossier", failures)
	_check(storytelling != null, "Office should install physical egg storytelling", failures)
	_check(worker_view != null, "Office should spawn the first worker view", failures)
	if (
		simulation == null
		or clock == null
		or audio == null
		or routing_ui == null
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
	office.call("_on_camera_focus_changed", "MABEL", 0)
	await process_frame
	_check(
		ticker != null
		and "MABEL" in ticker.text
		and "♥" in ticker.text
		and "Zz" in ticker.text
		and "!" in ticker.text
		and "CRACK" in ticker.text
		and not "MORALE" in ticker.text
		and not "FATIGUE" in ticker.text
		and not "STRESS" in ticker.text
		and "Morale" in ticker.accessibility_name
		and "Fatigue" in ticker.accessibility_name
		and "Stress" in ticker.accessibility_name
		and "Estimated shell crack risk" in ticker.accessibility_name
		and ticker.tooltip_text == ticker.accessibility_name
		and StringName(ticker.get_meta("presentation_role", &"")) == &"worker_vitals",
		"selected-hen status should use a compact visual vitals strip with a complete semantic equivalent",
		failures,
	)
	cue_events.clear()
	var intent_marker := worker_view.find_child("HenIntentMarker", true, false) as Sprite3D
	var background_worker_view := worker_views.get(1) as ChickenView
	var background_marker := (
		background_worker_view.find_child("HenIntentMarker", true, false) as Sprite3D
		if background_worker_view != null else
		null
	)
	_check(
		intent_marker != null
		and background_marker != null
		and StringName(intent_marker.get_meta("focus_role", &"")) == &"selected"
		and StringName(background_marker.get_meta("focus_role", &"")) == &"background"
		and background_marker.pixel_size < intent_marker.pixel_size
		and background_marker.modulate.a < intent_marker.modulate.a,
		"inspecting one hen should keep her world pin prominent while routine flock pins recede",
		failures,
	)
	var opportunity_visual_serial := int(
		intent_marker.get_meta("priority_peck_ready_serial", 0)
		if intent_marker != null else
		0
	)
	var assist_available := _advance_until_assist_available(simulation, 0)
	_check(assist_available, "test worker should enter an authoritative Priority Peck window", failures)
	var opportunity_frames := _cue_frames(cue_events, &"priority_peck_ready")
	_check(
		opportunity_frames.size() == 1,
		"the inspected claim should announce its first transition into the open window exactly once",
		failures,
	)
	_check(
		intent_marker != null
		and int(intent_marker.get_meta("priority_peck_ready_serial", 0)) == opportunity_visual_serial + 1
		and bool(intent_marker.get_meta("priority_peck_ready_animated", false)),
		"the same inspected transition should pulse the selected hen's no-text world pin exactly once",
		failures,
	)
	office.call("_refresh_priority_peck_precision_focus", simulation.snapshot())
	office.call("_refresh_priority_peck_precision_focus", simulation.snapshot())
	office.call("_on_camera_focus_changed", "PIP", 1)
	office.call("_on_camera_focus_changed", "MABEL", 0)
	await process_frame
	_check(
		_cue_frames(cue_events, &"priority_peck_ready").size() == 1,
		"repeated snapshots and refocusing an already-open claim should remain quiet",
		failures,
	)
	_check(
		intent_marker != null
		and int(intent_marker.get_meta("priority_peck_ready_serial", 0)) == opportunity_visual_serial + 1,
		"repeated snapshots and refocus should not replay the selected-hen opportunity halo",
		failures,
	)

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
	_check(
		_cue_frames(cue_events, &"priority_peck_perfect").is_empty()
		and _cue_frames(cue_events, &"priority_peck_steady").is_empty(),
		"accepted input must not play the semantic result before physical follow-through",
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
	var priority_peck_result_cue: StringName = (
		&"priority_peck_perfect"
		if StringName(simulation.last_peck_assist.get("rating", &"steady")) == &"perfect" else
		&"priority_peck_steady"
	)
	var priority_peck_result_frames := _cue_frames(cue_events, priority_peck_result_cue)
	var priority_peck_audio := audio.feedback_snapshot()
	_check(
		priority_peck_result_frames.size() == 1
		and contact_frames.size() == 3
		and priority_peck_result_frames[0] == contact_frames[2],
		"one semantic result cadence should land exactly on the third visible peck contact",
		failures,
	)
	_check(
		String(priority_peck_audio.get("last_cue", "")) == String(priority_peck_result_cue)
		and String(priority_peck_audio.get("last_haptic_cue", "")) == String(priority_peck_result_cue),
		"completed Priority Peck feedback should expose matching audio and optional haptic semantics",
		failures,
	)
	clock.set_speed(0)

	# A second inspected hen now crosses the authoritative closing boundary. The
	# event should retire both the world opportunity ring and dossier connector
	# exactly once, then leave a stable next-file recovery state.
	var missed_worker_view := worker_views.get(1) as ChickenView
	_check(missed_worker_view != null, "Office should expose Pip for a real missed-window transition", failures)
	if missed_worker_view != null:
		simulation.set_worker_at_workstation(1, true)
		office.call("_on_camera_focus_changed", "PIP", 1)
		await process_frame
		var missed_marker := missed_worker_view.find_child("HenIntentMarker", true, false) as Sprite3D
		var missed_available := _advance_until_assist_available(simulation, 1)
		_check(missed_available, "Pip should enter a second authoritative Priority Peck window", failures)
		var missed_claim_id := int(simulation.peck_assist_status(1).get("claim_id", -1))
		var world_missed_serial := int(
			missed_marker.get_meta("priority_peck_missed_serial", 0)
			if missed_marker != null else
			0
		)
		var dossier_missed_serial := int(routing_ui.get_meta("peck_missed_link_serial", 0))
		simulation.workers[1].work_progress = DepartmentSimulation.PECK_ASSIST_WINDOW_END
		simulation.advance_tick()
		await process_frame
		_check(
			StringName(simulation.peck_assist_status(1).get("window_state", &"")) == &"missed",
			"the fixture should cross the real one-shot missed-window boundary",
			failures,
		)
		_check(
			missed_marker != null
			and int(missed_marker.get_meta("priority_peck_missed_serial", 0)) == world_missed_serial + 1
			and bool(missed_marker.get_meta("priority_peck_missed_animated", false))
			and bool(missed_marker.get_meta("priority_peck_missed_active", false)),
			"the inspected hen's pin should contract one broken missed ring",
			failures,
		)
		_check(
			int(routing_ui.get_meta("peck_missed_link_serial", 0)) == dossier_missed_serial + 1
			and bool(routing_ui.get_meta("peck_missed_link_animated", false))
			and StringName(office.get("_priority_peck_result_hold_kind")) == &"missed"
			and int(office.get("_priority_peck_result_hold_until_msec")) > Time.get_ticks_msec(),
			"the same closing event should reverse one broken dossier connector",
			failures,
		)
		office.call("_on_peck_assist_missed", 1, missed_claim_id)
		_check(
			missed_marker != null
			and int(missed_marker.get_meta("priority_peck_missed_serial", 0)) == world_missed_serial + 1
			and int(routing_ui.get_meta("peck_missed_link_serial", 0)) == dossier_missed_serial + 1,
			"duplicate callbacks for the same claim must not replay either missed-window retreat",
			failures,
		)
		await create_timer(0.64).timeout
		var missed_halo := missed_worker_view.find_child("PriorityPeckReadyHalo", true, false) as Sprite3D
		var missed_link := routing_ui.find_child("PriorityPeckIntentLink", true, false) as Control
		_check(
			missed_halo != null
			and not missed_halo.visible
			and missed_link != null
			and not missed_link.visible,
			"both missed-window flourishes should settle without persistent floor or dossier clutter",
			failures,
		)
		# The failed action holds the inspected file for the same readable result
		# budget as a landed peck, then restores the player's selected speed.
		await create_timer(2.00).timeout
		office.call("_refresh_priority_peck_precision_focus", simulation.snapshot())
		_check(
			StringName(office.get("_priority_peck_result_hold_kind")) == &"",
			"the readable missed result beat should retire and release precision focus automatically",
			failures,
		)

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
	print("FEEDBACK_ORCHESTRA_INTEGRATION_TEST_PASSED opportunity=single-fire peck=contact+semantic-result lay=release grade=sorter presentation=basket payout=arrival+fallback")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
