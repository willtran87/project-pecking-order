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
	var work_start_receipts: Array[Dictionary] = []
	feedback.dispatch_work_started_presented.connect(
		func(_worker_id: int, receipt: Dictionary) -> void:
			work_start_receipts.append(receipt.duplicate(true))
	)

	var working_snapshot := _worker_snapshot(ChickenState.WorkState.WORKING, true)
	feedback.apply_snapshot({
		"workers": [working_snapshot],
		"upgrade_levels": {},
		"routing_momentum": {
			"pace_active": true,
			"pace_multiplier": 1.15,
		},
	})
	await create_timer(0.08).timeout
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
	_check(
		bool(workstation.get_meta("specialty_match", false)),
		"a correctly matched file should light the physical desk's gold fit state",
		failures,
	)
	var pace_flow := workstation.find_child("RoutingPaceFlow", true, false) as Node3D
	var manager_pace_face := workstation.find_child("PaceManagerFace", true, false) as Node3D
	var progress_rail := workstation.find_child("WorkProgressRail", true, false) as Node3D
	var progress_affordance := workstation.find_child(
		"ProgressInteractionAffordance",
		true,
		false,
	) as Node3D
	_check(
		bool(workstation.get_meta("routing_pace_active", false))
		and is_equal_approx(float(workstation.get_meta("routing_pace_multiplier", 0.0)), 1.15),
		"an occupied working desk should inherit the authoritative x2 pace multiplier",
		failures,
	)
	_check(
		progress_affordance != null and not progress_affordance.visible
		and workstation.find_children("Affordance*", "MeshInstance3D", true, false).size() == 6
		and int(feedback.work_progress_snapshot().get("pooled_affordance_count", 0)) == 1,
		"each desk should pool one quiet six-piece interaction bracket without showing it at rest",
		failures,
	)
	_check(
		pace_flow != null and pace_flow.visible
		and StringName(pace_flow.get_meta("feedback_shape", &"")) == &"double_chevron"
		and int(pace_flow.get_meta("view_sides", 0)) == 2,
		"active pace should add one cached shape-distinct monitor flow accent",
		failures,
	)
	_check(
		manager_pace_face != null and is_equal_approx(absf(manager_pace_face.rotation.y), PI),
		"the management-facing desk lamp should preserve forward chevron orientation",
		failures,
	)
	var pace_snapshot := feedback.routing_pace_snapshot()
	_check(
		bool(pace_snapshot.get("authoritative_active", false))
		and int(pace_snapshot.get("active_desk_count", 0)) == 1
		and String(pace_snapshot.get("shape", "")) == "double_chevron"
		and int(pace_snapshot.get("view_sides", 0)) == 2,
		"desk diagnostics should expose exactly which working stations receive pace",
		failures,
	)
	var progress_snapshot := feedback.work_progress_snapshot()
	var progress_desks := progress_snapshot.get("desks", []) as Array
	var active_progress := progress_desks[0] as Dictionary if not progress_desks.is_empty() else {}
	_check(
		progress_rail != null and progress_rail.visible
		and StringName(progress_rail.get_meta("status", &"")) == &"working"
		and StringName(progress_rail.get_meta("feedback_shape", &"")) == &"segmented_rail"
		and int(progress_rail.get_meta("filled_pips", 0)) == 3,
		"real claim progress should illuminate one management-facing five-pip desk rail",
		failures,
	)
	_check(
		int(progress_snapshot.get("pooled_rail_count", 0)) == 1
		and int(progress_snapshot.get("visible_count", 0)) == 1
		and String(active_progress.get("status", "")) == "working"
		and String(active_progress.get("shape", "")) == "segmented_rail"
		and is_equal_approx(float(active_progress.get("progress", 0.0)), 42.0),
		"assistive diagnostics should mirror the physical rail's authoritative claim progress",
		failures,
	)
	_check(
		workstation.find_children("ProgressPip_*", "MeshInstance3D", true, false).size() == 5,
		"each desk should pool exactly five non-text progress pips",
		failures,
	)
	var interaction_roots := feedback.work_progress_interaction_roots()
	_check(
		interaction_roots.size() == 1
		and interaction_roots.get(7) == progress_rail
		and int(active_progress.get("worker_id", -1)) == 7,
		"the visible rail should expose its exact worker-bound physical interaction point",
		failures,
	)
	feedback.set_work_progress_hover(7)
	var hovered_progress := feedback.work_progress_snapshot()
	var hovered_desk := (hovered_progress.get("desks", []) as Array)[0] as Dictionary
	_check(
		progress_affordance != null and progress_affordance.visible
		and bool(hovered_desk.get("hovered", false))
		and bool(hovered_desk.get("interactive", false))
		and bool(hovered_desk.get("affordance_visible", false))
		and String(hovered_desk.get("affordance_shape", "")) == "corner_brackets"
		and int(hovered_progress.get("hovered_count", 0)) == 1,
		"hovering a live rail should reveal one pooled non-text corner bracket",
		failures,
	)
	feedback.set_reduced_motion(true)
	_check(
		pace_flow != null and pace_flow.visible
		and bool(pace_flow.get_meta("reduced_motion", false))
		and not bool(feedback.routing_pace_snapshot().get("animated", true)),
		"reduced motion should keep the semantic chevrons while stopping their travel",
		failures,
	)
	_check(
		not bool(((feedback.work_progress_snapshot().get("desks", []) as Array)[0] as Dictionary).get("animated", true)),
		"reduced motion should keep the work rail readable without pulsing it",
		failures,
	)
	_check(
		progress_affordance != null and progress_affordance.visible
		and not bool(((feedback.work_progress_snapshot().get("desks", []) as Array)[0] as Dictionary).get("affordance_animated", true)),
		"reduced motion should preserve the hover brackets as a stable shape",
		failures,
	)
	feedback.set_reduced_motion(false)
	feedback.set_work_progress_hover(-1)
	feedback.set_work_progress_selected(7)
	var selected_desk := (feedback.work_progress_snapshot().get("desks", []) as Array)[0] as Dictionary
	_check(
		progress_affordance != null and progress_affordance.visible
		and bool(selected_desk.get("selected", false))
		and not bool(selected_desk.get("hovered", true))
		and int(feedback.work_progress_snapshot().get("selected_count", 0)) == 1,
		"selection should retain the same bracket after pointer hover hands off to the dossier",
		failures,
	)
	_check(
		feedback.play_dispatch_delivery(
			7,
			&"nest_damage",
			workstation.global_position + Vector3(3.0, 2.0, 0.0),
			true,
			2,
			0.20,
		),
		"a real route should launch its presentation toward the mapped desk",
		failures,
	)
	await create_timer(0.90).timeout
	var waiting_landing := feedback.dispatch_landing_snapshot()
	_check(
		bool(waiting_landing.get("active", false))
		and String(waiting_landing.get("phase", "")) == "filed_waiting"
		and not bool(waiting_landing.get("work_started", true))
		and int(waiting_landing.get("pooled_marker_count", 0)) == 1,
		"the delivered file should wait at the desk in one pooled stamp until real work begins",
		failures,
	)
	_check(
		feedback.pulse_work_contact(7, 701),
		"the first attended work contact should accept the waiting routed file",
		failures,
	)
	var started_landing := feedback.dispatch_landing_snapshot()
	_check(
		bool(started_landing.get("active", false))
		and bool(started_landing.get("work_started", false))
		and bool(started_landing.get("work_handoff_active", false))
		and String(started_landing.get("phase", "")) == "work_started"
		and int(started_landing.get("work_contact_serial", 0)) == 701
		and String(started_landing.get("work_handoff_shape", "")) == "stamp_to_screen"
		and work_start_receipts.size() == 1,
		"the exact first peck should transfer the desk stamp into the authored monitor contact once",
		failures,
	)
	feedback.set_reduced_motion(true)
	var static_handoff := feedback.dispatch_landing_snapshot()
	_check(
		bool(static_handoff.get("work_handoff_active", false))
		and not bool(static_handoff.get("work_handoff_animated", true)),
		"reduced motion should preserve the same file-to-screen receipt without travel",
		failures,
	)
	_check(
		feedback.stage_dispatch_work_handoff_capture(7)
		and int(feedback.dispatch_landing_snapshot().get("capture_staged_count", 0)) == 1,
		"capture should hold the real pooled stamp and monitor contact without cloning either",
		failures,
	)
	_check(
		feedback.release_dispatch_work_handoff_capture(7)
		and feedback.finish_dispatch_landing(7)
		and feedback.active_dispatch_landing_count() == 0,
		"the first-peck receipt should release and clean its pooled marker exactly once",
		failures,
	)
	feedback.set_reduced_motion(false)
	var routed_contact_count := int(workstation.get_meta("work_peck_contact_count", 0))

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
		int(workstation.get_meta("work_peck_contact_count", 0))
		== routed_contact_count + accepted_contacts.size(),
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
	await create_timer(0.08).timeout
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
	_check(
		not bool(workstation.get_meta("routing_pace_active", true))
		and pace_flow != null and not pace_flow.visible,
		"inactive or unattended desks should remove the pace accent immediately",
		failures,
	)
	_check(
		progress_rail != null and progress_rail.visible
		and StringName(progress_rail.get_meta("status", &"")) == &"paused"
		and (workstation.find_child("ProgressPausedShape", true, false) as Node3D).visible,
		"a real file left unattended should retain its pips and add shape-distinct pause bars",
		failures,
	)

	var deadline_snapshot := _worker_snapshot(ChickenState.WorkState.WORKING, true)
	(deadline_snapshot["current_claim"] as Dictionary)["minutes_until_deadline"] = 35
	feedback.apply_snapshot({"workers": [deadline_snapshot], "upgrade_levels": {}})
	var risk_shape := workstation.find_child("ProgressDeadlineRiskShape", true, false) as Node3D
	var risk_progress := feedback.work_progress_snapshot()
	_check(
		progress_rail != null and progress_rail.visible
		and StringName(progress_rail.get_meta("status", &"")) == &"deadline_risk"
		and risk_shape != null and risk_shape.visible
		and int(risk_progress.get("deadline_risk_count", 0)) == 1,
		"an authoritative near-deadline file should replace pause bars with a warning diamond",
		failures,
	)
	feedback.set_color_vision_mode(&"deuteranopia")
	_check(
		progress_rail != null
		and StringName(progress_rail.get_meta("status", &"")) == &"deadline_risk"
		and risk_shape != null and risk_shape.visible,
		"color-vision remapping should preserve deadline risk through its physical diamond shape",
		failures,
	)
	feedback.set_color_vision_mode(&"standard")

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
	feedback.apply_snapshot({"workers": [], "upgrade_levels": {}})
	_check(
		feedback.work_progress_interaction_roots().is_empty()
		and progress_rail != null and not progress_rail.visible
		and progress_affordance != null and not progress_affordance.visible
		and int(feedback.work_progress_snapshot().get("hovered_count", -1)) == 0
		and int(feedback.work_progress_snapshot().get("selected_count", -1)) == 0,
		"removing a worker should retire the rail hit target and visible state without a ghost desk",
		failures,
	)

	fixture.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("CORE_LOOP_READABILITY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CORE_LOOP_READABILITY_TEST_PASSED route=file landing=waiting first-peck=screen-handoff egg=worker_attributed")
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
			"specialty_match": true,
			"minutes_until_deadline": 180,
			"overdue": false,
			"is_rework": false,
		},
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
