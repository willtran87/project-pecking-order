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
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var routing_ui := office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	var journey_label := office.find_child("RoutingAutomationHint", true, false) as Label
	var claim_label := office.find_child("RoutingCurrentClaim", true, false) as Label
	var worker_view := (office.get("_worker_views") as Dictionary).get(0) as ChickenView
	var camera_controller := office.get("_camera_controller") as ManagementCameraController
	var workstation_feedback := office.get("_workstation_feedback") as WorkstationFeedback
	_check(
		simulation != null
		and campaign_ui != null
		and routing_ui != null
		and journey_label != null
		and claim_label != null
		and worker_view != null,
		"receipt fixture should expose the production Office surfaces",
		failures,
	)
	if campaign_ui != null:
		campaign_ui.show_title(false)
	if simulation != null and simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING:
		_check(simulation.select_directive(&"shell_assurance"), "fixture should enter a running shift", failures)
	if worker_view != null:
		worker_view.stage_at_workstation_for_introduction()
	if simulation != null:
		simulation.set_worker_at_workstation(0, true)
		office.call("_on_snapshot_changed", simulation.snapshot())
	if routing_ui != null:
		routing_ui.set_focus(0)
	await process_frame

	var save_before: Dictionary = simulation.export_save_state() if simulation != null else {}
	office.call("_on_egg_laid", 0, &"sound", 455, 9001, 0)
	await process_frame
	var laid := routing_ui.egg_journey_receipt_state() if routing_ui != null else {}
	_check(
		bool(laid.get("visible", false))
		and int(laid.get("claim_id", -1)) == 9001
		and StringName(laid.get("stage", &"")) == &"grading"
		and journey_label != null
		and "LAST EGG #9001" in journey_label.text
		and "GRADING > FARMER" in journey_label.text,
		"a laid egg should open one compact grading receipt for the exact claim",
		failures,
	)
	office.call("_on_egg_graded", 0, &"sound", 455, 0, Vector3.ZERO)
	await process_frame
	var graded := routing_ui.egg_journey_receipt_state() if routing_ui != null else {}
	_check(
		StringName(graded.get("stage", &"")) == &"graded"
		and journey_label != null
		and "SOUND GRADED > FARMER" in journey_label.text,
		"the same receipt should advance at grading without changing the hen intent",
		failures,
	)
	office.call("_on_egg_reached_presentation", 0, &"sound", 455, 0)
	await process_frame
	var delivered := routing_ui.egg_journey_receipt_state() if routing_ui != null else {}
	_check(
		StringName(delivered.get("stage", &"")) == &"delivered"
		and journey_label != null
		and "FARMER +$4.55" in journey_label.text
		and "separate from" in String(delivered.get("accessible_text", "")),
		"farmer arrival should close the exact receipt with value and accessible timeline separation",
		failures,
	)
	var world_ack := (
		workstation_feedback.egg_delivery_ack_snapshot()
		if workstation_feedback != null else
		{}
	)
	var world_acknowledgments := world_ack.get("acknowledgments", []) as Array
	var delivered_ack := (
		world_acknowledgments[0] as Dictionary
		if world_acknowledgments.size() == 1 else
		{}
	)
	_check(
		int(world_ack.get("pooled_marker_count", 0)) == 6
		and int(world_ack.get("active_count", 0)) == 1
		and int(delivered_ack.get("worker_id", -1)) == 0
		and int(delivered_ack.get("claim_id", -1)) == 9001
		and int(delivered_ack.get("cash_cents", -1)) == 455
		and String(delivered_ack.get("shape", "")) == "coin_up_arrow",
		"the same farmer arrival should light one pooled, exact desk-level payout icon",
		failures,
	)
	_check(
		simulation != null and simulation.export_save_state() == save_before,
		"the complete presentation receipt lifecycle must remain neutral to authoritative save data",
		failures,
	)

	# The hen is free to pull another file while the previous outcome remains
	# glanceable. Current work stays in the main header; LAST EGG stays in the hint.
	if simulation != null:
		simulation.advance_tick()
		office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	var next_worker := (simulation.snapshot().get("workers", []) as Array)[0] as Dictionary
	var next_claim := next_worker.get("current_claim", {}) as Dictionary
	_check(not next_claim.is_empty(), "the now-free hen should be able to pull her next authoritative file", failures)
	_check(
		claim_label != null
		and "#%04d" % int(next_claim.get("id", 0)) in claim_label.text
		and journey_label != null
		and "LAST EGG #9001" in journey_label.text,
		"new work and the previous egg receipt should remain visibly separate",
		failures,
	)
	if camera_controller != null:
		camera_controller.focus_worker(0)
	await create_timer(0.9).timeout
	var focused_receipt := routing_ui.egg_journey_receipt_state() if routing_ui != null else {}
	_check(
		bool(focused_receipt.get("visible", false))
		and journey_label != null
		and "LAST EGG #9001" in journey_label.text,
		"camera focus refreshes must preserve the settled receipt beside the next file",
		failures,
	)
	office.call("_set_flockwatch_open", true)
	await process_frame
	office.call("_set_flockwatch_open", false)
	await process_frame
	var restored_receipt := routing_ui.egg_journey_receipt_state() if routing_ui != null else {}
	_check(
		bool(restored_receipt.get("visible", false))
		and journey_label != null
		and "LAST EGG #9001" in journey_label.text,
		"closing Flockwatch must restore the routing projection without dropping the receipt",
		failures,
	)
	office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("EGG_JOURNEY_RECEIPT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("EGG_JOURNEY_RECEIPT_TEST_PASSED stages=grading+graded+delivered next_file=separate save=neutral")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
