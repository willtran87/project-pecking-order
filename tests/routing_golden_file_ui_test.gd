extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	office.call("_prepare_capture_running")
	var simulation := office.get("_simulation") as DepartmentSimulation
	var routing_ui := office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	var feedback := office.get("_workstation_feedback") as WorkstationFeedback
	var badge := office.find_child("RoutingGoldenFileBadge", true, false) as Label
	_check(simulation != null and routing_ui != null and feedback != null, "Office should expose Golden File authority and presentation", failures)
	if simulation == null or routing_ui == null or feedback == null:
		await _finish(office, failures)
		return

	for worker_index in mini(4, simulation.workers.size()):
		simulation.set_worker_at_workstation(worker_index, true)
	simulation.advance_tick()
	for lane: StringName in [&"nest_damage", &"predator_loss", &"appeals", &"nest_damage", &"predator_loss"]:
		var receipt := _best_fit_dispatch(simulation, lane, failures)
		_check(bool(receipt.get("accepted", false)), "%s should build the real x5 route chain" % lane, failures)
	var momentum := simulation.routing_momentum_snapshot()
	var target_worker_id := int(momentum.get("golden_target_worker_id", -1))
	var target_claim_id := int(momentum.get("golden_target_claim_id", -1))
	_check(
		int(momentum.get("chain", 0)) == 5
		and int(momentum.get("golden_charges", 0)) == 1
		and bool(momentum.get("golden_target_bound", false)),
		"x5 should bind one live Golden File",
		failures,
	)
	routing_ui.set_focus(target_worker_id)
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	await process_frame
	_check(
		badge != null
		and badge.visible
		and badge.text == "* GOLD"
		and "file #%04d" % target_claim_id in badge.tooltip_text,
		"the dossier should show one compact, accessible seal for the exact claim",
		failures,
	)
	var world_state := feedback.routing_pace_snapshot()
	_check(
		int(world_state.get("golden_target_desk_count", 0)) == 1
		and String(world_state.get("golden_target_shape", "")) == "diamond_egg_seal",
		"the same claim should carry one shape-distinct physical desk seal",
		failures,
	)

	routing_ui.set_reduced_motion(true)
	feedback.set_reduced_motion(true)
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	world_state = feedback.routing_pace_snapshot()
	_check(
		badge.visible
		and bool(world_state.get("reduced_motion", false))
		and int(world_state.get("golden_target_desk_count", 0)) == 1,
		"reduced motion should preserve the static dossier and world seals",
		failures,
	)
	await _finish(office, failures)


func _best_fit_dispatch(
	simulation: DepartmentSimulation,
	lane: StringName,
	failures: Array[String],
) -> Dictionary:
	var candidates := simulation.dispatch_candidates(lane)
	_check(not candidates.is_empty(), "%s should expose a best fit" % lane, failures)
	if candidates.is_empty():
		return {}
	var worker_id := int(candidates[0].get("worker_id", -1))
	if simulation.workers[worker_id].assigned_lane == lane:
		simulation.set_worker_assignment(worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
	return simulation.dispatch_worker_to_lane(worker_id, lane)


func _finish(office: Office, failures: Array[String]) -> void:
	office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("ROUTING_GOLDEN_FILE_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("ROUTING_GOLDEN_FILE_UI_TEST_PASSED authority=x5 dossier=diamond world=egg-seal reduced=static")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
