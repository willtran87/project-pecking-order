extends SceneTree


const WorkstationScene := preload("res://assets/models/office_workstation.glb")
const WorkstationFeedbackScript := preload("res://features/office/workstation_feedback.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var fixture := Node3D.new()
	fixture.name = "CoreLoopReadabilityFixture"
	root.add_child(fixture)

	var workstations := Node3D.new()
	workstations.name = "Workstations"
	fixture.add_child(workstations)
	var workstation := WorkstationScene.instantiate() as Node3D
	workstation.name = "Workstation_00"
	workstations.add_child(workstation)

	var feedback := WorkstationFeedbackScript.new() as WorkstationFeedback
	feedback.name = "WorkstationFeedback"
	fixture.add_child(feedback)
	feedback.configure(workstations)

	var working_snapshot := _worker_snapshot(ChickenState.WorkState.WORKING, true)
	feedback.apply_snapshot({"workers": [working_snapshot], "upgrade_levels": {}})
	_check(
		StringName(workstation.get_meta("core_loop_stage", &"")) == &"pecking_screen",
		"an occupied active desk should identify the visible screen-peck stage",
		failures,
	)
	_check(
		int(workstation.get_meta("last_routed_claim_id", -1)) == 81,
		"a newly pulled file should leave a desk-local routing receipt",
		failures,
	)

	var view := ChickenView.new()
	view.configure(working_snapshot)
	fixture.add_child(view)
	var chair := Vector3(0.1, 0.0, 0.1)
	view.assign_office_route(chair, chair, Vector3(0.1, 0.0, 1.0), [], [])
	view.stage_at_workstation_for_introduction()
	var contacts: Array[int] = []
	var accepted_contacts: Array[int] = []
	view.work_peck_contact.connect(func(worker_id: int, serial: int) -> void:
		contacts.append(serial)
		if feedback.pulse_work_contact(worker_id, serial):
			accepted_contacts.append(serial)
	)

	for _frame in 150:
		if not accepted_contacts.is_empty():
			break
		await physics_frame
	_check(not contacts.is_empty(), "a seated working hen should produce a normal peck contact", failures)
	_check(not accepted_contacts.is_empty(), "the occupied workstation should accept that exact contact", failures)
	_check(
		int(workstation.get_meta("work_peck_contact_count", 0)) == accepted_contacts.size(),
		"screen contact feedback should count accepted contacts without duplicate timers",
		failures,
	)
	_check(
		feedback.screen_contact_point_global(7) != Vector3.ZERO,
		"screen feedback should expose a point derived from the authored monitor",
		failures,
	)
	_check(
		workstation.find_child("ScreenPeckContactDisc", true, false) != null,
		"each workstation should cache one connected display impact marker",
		failures,
	)

	var unattended_snapshot := _worker_snapshot(ChickenState.WorkState.WORKING, false)
	feedback.apply_snapshot({"workers": [unattended_snapshot], "upgrade_levels": {}})
	var accepted_before := int(workstation.get_meta("work_peck_contact_count", 0))
	_check(
		not feedback.pulse_work_contact(7, 999),
		"an unattended desk must reject synthetic screen contacts",
		failures,
	)
	_check(
		int(workstation.get_meta("work_peck_contact_count", 0)) == accepted_before,
		"rejected contacts must not advance presentation state",
		failures,
	)

	feedback.apply_snapshot({"workers": [working_snapshot], "upgrade_levels": {}})
	feedback.pulse_completion(7, &"sound")
	_check(
		StringName(workstation.get_meta("core_loop_stage", &"")) == &"egg_released",
		"a completed file should visibly advance from peckwork to egg release",
		failures,
	)
	_check(
		String(workstation.get_meta("last_completed_worker", "")) == "Timing Hen",
		"completion evidence should retain the hen who performed the work",
		failures,
	)

	view.apply_snapshot(_worker_snapshot(ChickenState.WorkState.IDLE, true))
	contacts.clear()
	for _frame in 80:
		await physics_frame
	_check(contacts.is_empty(), "an idle hen must not emit cosmetic work contacts", failures)

	fixture.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("CORE_LOOP_READABILITY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CORE_LOOP_READABILITY_TEST_PASSED route=file peck=screen egg=worker_attributed")
	quit(0)


func _worker_snapshot(state: ChickenState.WorkState, at_workstation: bool) -> Dictionary:
	return {
		"id": 7,
		"name": "Timing Hen",
		"desk_index": 0,
		"state": state,
		"state_label": "PECKING" if state == ChickenState.WorkState.WORKING else "IDLE",
		"progress": 42.0,
		"stress": 22.0,
		"at_workstation": at_workstation,
		"assigned_lane": &"nest_damage",
		"current_claim": {
			"id": 81,
			"lane": &"nest_damage",
			"value_cents": 455,
		},
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
