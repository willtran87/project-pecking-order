extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(8132)
	var lanes: Array[StringName] = [&"nest_damage", &"predator_loss", &"appeals"]
	for dispatch_index in 9:
		_best_fit_dispatch(simulation, lanes[dispatch_index % lanes.size()], failures)
	for worker in simulation.workers:
		if not worker.employed:
			continue
		worker.morale = 50.0
		worker.stress = 50.0
		worker.fatigue = 50.0
	var tenth := _best_fit_dispatch(simulation, &"nest_damage", failures)
	var reward := tenth.get("reward", {}) as Dictionary
	_check(StringName(reward.get("id", &"")) == &"team_lift", "fixture should reach the real x10 reward", failures)

	# Exercise the Office single-fire coordinator without constructing the entire
	# production floor. ChickenView still builds the real imported character and
	# its actual world marker, so motion, reduced motion, and cleanup stay covered.
	var office := Office.new()
	var worker_views: Dictionary = office.get("_worker_views") as Dictionary
	var view_nodes: Array[ChickenView] = []
	var worker_snapshots := simulation.snapshot().get("workers", []) as Array
	for affected_value in reward.get("affected_workers", []):
		var affected := affected_value as Dictionary
		var worker_id := int(affected.get("worker_id", -1))
		var worker_snapshot := worker_snapshots[worker_id] as Dictionary
		var view := ChickenView.new()
		view.configure(worker_snapshot)
		root.add_child(view)
		worker_views[worker_id] = view
		view_nodes.append(view)

	var earning_worker_id := int(reward.get("worker_id", -1))
	office.call("_on_routing_reward_presented", earning_worker_id, reward, 10)
	var presentation := office.get("_last_team_lift_presentation") as Dictionary
	_check(
		int(presentation.get("presented_count", -1)) == int(reward.get("affected_count", 0)),
		"one landed receipt should synchronize every affected hen",
		failures,
	)
	for view in view_nodes:
		var state := view.team_lift_feedback_state()
		var receipt := state.get("receipt", {}) as Dictionary
		_check(
			bool(state.get("active", false))
			and bool(state.get("animated", false))
			and int(state.get("serial", 0)) == 1,
			"each affected hen should show one live lift marker",
			failures,
		)
		_check(
			is_equal_approx(float(receipt.get("morale_delta", 0.0)), 3.0)
			and is_equal_approx(float(receipt.get("stress_delta", 0.0)), -2.0)
			and is_equal_approx(float(receipt.get("fatigue_delta", 0.0)), -1.0),
			"each marker should retain its exact +3/-2/-1 receipt",
			failures,
		)

	var first_serial := int(view_nodes[0].team_lift_feedback_state().get("serial", 0))
	office.call("_on_routing_reward_presented", earning_worker_id, reward, 10)
	_check(
		int(view_nodes[0].team_lift_feedback_state().get("serial", 0)) == first_serial,
		"a duplicate authority key must not replay the flock reaction",
		failures,
	)

	for view in view_nodes:
		view.set_reduced_motion(true)
	var reduced_reward := reward.duplicate(true)
	reduced_reward["authority_key"] = String(reward.get("authority_key", "")) + ":reduced"
	office.call("_on_routing_reward_presented", earning_worker_id, reduced_reward, 10)
	for view in view_nodes:
		var reduced_state := view.team_lift_feedback_state()
		_check(
			bool(reduced_state.get("active", false))
			and not bool(reduced_state.get("animated", true)),
			"reduced motion should preserve a static marker on every affected hen",
			failures,
		)
	await create_timer(1.30).timeout
	for view in view_nodes:
		_check(
			not bool(view.team_lift_feedback_state().get("active", true)),
			"every Team Lift marker should clean itself up after its bounded hold",
			failures,
		)

	worker_views.clear()
	var isolated_clock := office.get("_clock") as SimulationClock
	if isolated_clock != null and not isolated_clock.is_inside_tree():
		isolated_clock.free()
	office.free()
	for view in view_nodes:
		view.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("ROUTING_TEAM_LIFT_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("ROUTING_TEAM_LIFT_UI_TEST_PASSED authority=x10 world=all_hens exact=+3/-2/-1 duplicate=blocked reduced=static cleanup=bounded")
	quit(0)


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
	var receipt := simulation.dispatch_worker_to_lane(worker_id, lane)
	_check(bool(receipt.get("accepted", false)), "%s should file a real route" % lane, failures)
	return receipt


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
