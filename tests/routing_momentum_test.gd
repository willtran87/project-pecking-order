extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(8129)
	var first := _best_fit_dispatch(simulation, &"nest_damage", failures)
	_check(int(first.get("momentum_chain", -1)) == 1, "first best-fit dispatch should start the chain", failures)

	var second := _best_fit_dispatch(simulation, &"predator_loss", failures)
	_check(int(second.get("momentum_chain", -1)) == 2, "second best-fit dispatch should reach pace flow", failures)
	_check(StringName((second.get("reward", {}) as Dictionary).get("id", &"")) == &"pace", "x2 should award the pace milestone", failures)
	_check(bool(simulation.routing_momentum_snapshot().get("pace_active", false)), "pace multiplier should be authoritative while the chain holds", failures)

	simulation.peck_assists_used_today = 1
	simulation.peck_assist_interventions_today = 1
	var third := _best_fit_dispatch(simulation, &"appeals", failures)
	_check(int(third.get("momentum_chain", -1)) == 3, "third best-fit dispatch should continue without a timer", failures)
	_check(StringName((third.get("reward", {}) as Dictionary).get("id", &"")) == &"peck_recharge", "x3 should award a Priority Peck recharge", failures)
	_check(simulation.peck_assists_used_today == 0, "x3 should restore a spent Priority Peck immediately", failures)
	var recharge_reward := third.get("reward", {}) as Dictionary
	_check(
		bool(recharge_reward.get("refilled", false))
		and int(recharge_reward.get("charges_before", -1)) == 2
		and int(recharge_reward.get("charges_after", -1)) == 3,
		"x3 should expose the exact authoritative charge refill",
		failures,
	)
	_check(
		not String(recharge_reward.get("authority_key", "")).is_empty()
		and int(recharge_reward.get("worker_id", -1)) == int(third.get("worker_id", -2)),
		"x3 should carry a stable single-fire presentation key and earning hen",
		failures,
	)
	var already_full := DepartmentSimulation.new(8130)
	already_full.routing_momentum_peck_recharge_bank = 1
	var full_reward := already_full.call("_apply_routing_momentum_milestone", 3) as Dictionary
	_check(
		not bool(full_reward.get("refilled", true))
		and int(full_reward.get("charges_before", -1)) == 4
		and int(full_reward.get("charges_after", -1)) == 4
		and String(full_reward.get("label", "")) == "PECK READY",
		"an already-full bank must not claim it created another charge",
		failures,
	)

	_best_fit_dispatch(simulation, &"nest_damage", failures)
	var fifth := _best_fit_dispatch(simulation, &"predator_loss", failures)
	_check(int(fifth.get("momentum_chain", -1)) == 5, "five best-fit dispatches should reach the golden milestone", failures)
	_check(simulation.routing_momentum_golden_charges == 1, "x5 should bank one golden-file opportunity", failures)
	_test_team_lift_receipt(failures)

	var state := simulation.export_save_state()
	var restored := DepartmentSimulation.new(9991)
	_check(restored.restore_save_state(state), "authoritative routing momentum should restore", failures)
	_check(restored.routing_momentum_snapshot() == simulation.routing_momentum_snapshot(), "chain and earned rewards should round-trip exactly", failures)
	var break_receipts: Array[Dictionary] = []
	var recovery_receipts: Array[Dictionary] = []
	restored.routing_momentum_broken.connect(func(receipt: Dictionary) -> void:
		break_receipts.append(receipt.duplicate(true))
	)
	restored.routing_momentum_recovered.connect(func(receipt: Dictionary) -> void:
		recovery_receipts.append(receipt.duplicate(true))
	)

	var poor_lane := &"appeals"
	var candidates := restored.dispatch_candidates(poor_lane)
	_check(candidates.size() >= 2, "poor-fit fixture should expose a second candidate", failures)
	if candidates.size() >= 2:
		var poor_worker_id := int(candidates[1].get("worker_id", -1))
		restored.set_worker_assignment(poor_worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
		var poor := restored.dispatch_worker_to_lane(poor_worker_id, poor_lane)
		_check(bool(poor.get("accepted", false)), "poor-fit dispatch should still route the file", failures)
		_check(int(poor.get("momentum_chain", -1)) == 0, "poor-fit routing should break the live chain", failures)
		_check(restored.routing_momentum_golden_charges == 1, "earned golden opportunity should survive a later chain break", failures)
		var break_receipt := poor.get("break", {}) as Dictionary
		_check(break_receipts.size() == 1, "one real chain loss should emit one authoritative break receipt", failures)
		_check(int(break_receipt.get("broken_chain", 0)) == 5, "break receipt should retain the exact chain that was lost", failures)
		_check(StringName(break_receipt.get("source", &"")) == &"poor_fit", "poor route should expose its exact break source", failures)
		_check(int(break_receipt.get("worker_id", -1)) == poor_worker_id, "break receipt should retain the responsible worker", failures)
		_check(int(restored.routing_momentum_snapshot().get("break_serial", 0)) == 1, "momentum snapshot should expose the single-fire break serial", failures)
		_check(bool(restored.routing_momentum_snapshot().get("recovery_pending", false)), "a real break should expose one pending best-fit recovery", failures)
		_check(
			(restored.routing_momentum_snapshot().get("last_break", {}) as Dictionary) == break_receipt,
			"momentum snapshot should retain the exact progressive-disclosure receipt",
			failures,
		)
		restored.call("_break_routing_momentum", "Already clear.", &"test")
		_check(break_receipts.size() == 1, "breaking an empty chain must not replay feedback", failures)

		var recovered := _best_fit_dispatch(restored, &"nest_damage", failures)
		var recovery_receipt := recovered.get("recovery", {}) as Dictionary
		_check(recovery_receipts.size() == 1, "the first correcting best fit should emit one authoritative recovery", failures)
		_check(int(recovery_receipt.get("break_serial", 0)) == 1, "recovery should close the exact break receipt", failures)
		_check(int(recovery_receipt.get("broken_chain", 0)) == 5, "recovery should retain the chain the player rebuilt from", failures)
		_check(int(recovery_receipt.get("recovered_chain", 0)) == 1, "recovery should restart flow at x1", failures)
		_check(int(recovery_receipt.get("worker_id", -1)) == int(recovered.get("worker_id", -2)), "recovery should retain the correcting worker", failures)
		_check(StringName(recovery_receipt.get("lane", &"")) == &"nest_damage", "recovery should retain the corrected tray", failures)
		_check(not recovery_receipts.is_empty() and recovery_receipts[0] == recovery_receipt, "signal and dispatch should expose the same recovery receipt", failures)
		var recovered_snapshot := restored.routing_momentum_snapshot()
		_check(not bool(recovered_snapshot.get("recovery_pending", true)), "the exact correction should clear pending recovery", failures)
		_check(int(recovered_snapshot.get("recovery_serial", 0)) == 1, "recovery diagnostics should remain single-fire", failures)
		_best_fit_dispatch(restored, &"predator_loss", failures)
		_check(recovery_receipts.size() == 1, "ordinary chain continuation must not replay recovery", failures)

	_test_golden_file_consumption(restored, failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("ROUTING_MOMENTUM_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("ROUTING_MOMENTUM_TEST_PASSED chain=untimed pace=x2 peck=x3 golden=x5 bound=claim persistence=v30")
	quit(0)


func _best_fit_dispatch(
	simulation: DepartmentSimulation,
	lane: StringName,
	failures: Array[String],
) -> Dictionary:
	var candidates := simulation.dispatch_candidates(lane)
	_check(not candidates.is_empty(), "%s should have a best-fit candidate" % lane, failures)
	if candidates.is_empty():
		return {}
	var worker_id := int(candidates[0].get("worker_id", -1))
	# A milestone must represent a real route change, never repeated clicks.
	if simulation.workers[worker_id].assigned_lane == lane:
		simulation.set_worker_assignment(worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
	var receipt := simulation.dispatch_worker_to_lane(worker_id, lane)
	_check(bool(receipt.get("accepted", false)), "%s best-fit dispatch should be accepted" % lane, failures)
	_check(bool(receipt.get("recommended", false)), "%s dispatch should preserve the ranked recommendation" % lane, failures)
	return receipt


func _test_golden_file_consumption(
	simulation: DepartmentSimulation,
	failures: Array[String],
) -> void:
	_check(simulation.select_directive(&"shell_assurance"), "golden fixture should start the shift", failures)
	simulation.set_worker_at_workstation(0, true)
	simulation.set_worker_at_workstation(1, true)
	simulation.advance_tick()
	var worker := simulation.workers[0]
	_check(worker.current_claim != null, "golden fixture should pull a real claim", failures)
	if worker.current_claim == null:
		return
	var target_claim_id := worker.current_claim.id
	_check(simulation.routing_momentum_golden_target_claim_id == target_claim_id, "x5 should seal one exact live claim", failures)
	_check(simulation.routing_momentum_golden_target_worker_id == 0, "the seal should retain its authoritative worker", failures)
	var target_snapshot := (simulation.snapshot().get("workers", []) as Array)[0] as Dictionary
	_check(bool((target_snapshot.get("current_claim", {}) as Dictionary).get("routing_golden_target", false)), "the sealed claim should project into its dossier", failures)

	var bound_state := simulation.export_save_state()
	var bound := DepartmentSimulation.new(9992)
	_check(bound.restore_save_state(bound_state), "a sealed active Golden File should restore", failures)
	_check(
		bound.routing_momentum_golden_target_claim_id == target_claim_id
		and bound.routing_momentum_golden_target_worker_id == 0,
		"the exact seal should survive restore",
		failures,
	)
	bound.set_worker_at_workstation(0, true)
	bound.set_worker_at_workstation(1, true)
	var observed: Array[StringName] = []
	bound.egg_laid.connect(func(_worker_id: int, quality: StringName, _value_cents: int) -> void:
		observed.append(quality)
	)
	var bound_worker := bound.workers[0]
	var crack_seed := _seed_for_cracked_egg(bound.estimated_crack_risk(0))
	(bound.get("_rng") as RandomNumberGenerator).seed = crack_seed
	bound_worker.work_state = ChickenState.WorkState.LAYING
	bound_worker.state_ticks_remaining = 1
	bound.advance_tick()
	_check(not observed.is_empty() and observed[0] == &"cracked", "a sealed file can still crack at grading", failures)
	_check(bound.routing_momentum_golden_charges == 1, "a crack should preserve the earned clean-file upgrade", failures)
	_check(bound.routing_momentum_golden_target_worker_id == 1, "a cracked seal should move once to the next active file", failures)
	var rebound_worker := bound.workers[1]
	_check(rebound_worker.current_claim != null, "the rebound seal requires a second live claim", failures)
	if rebound_worker.current_claim == null:
		return
	var rebound_claim_id := rebound_worker.current_claim.id
	_check(bound.routing_momentum_golden_target_claim_id == rebound_claim_id, "the rebound seal should name the second claim exactly", failures)
	var risk := bound.estimated_crack_risk(1)
	var golden_chance := clampf(0.025 + maxf(0.0, rebound_worker.morale - 70.0) * 0.0005, 0.025, 0.08)
	var sound_seed := _seed_for_sound_egg(risk, golden_chance)
	_check(sound_seed > 0, "golden fixture should find a deterministic sound result", failures)
	(bound.get("_rng") as RandomNumberGenerator).seed = sound_seed
	rebound_worker.work_state = ChickenState.WorkState.LAYING
	rebound_worker.state_ticks_remaining = 1
	bound.advance_tick()
	_check(observed.size() >= 2 and observed[1] == &"golden", "the rebound file should visibly fulfill the x5 reward", failures)
	_check(bound.routing_momentum_golden_charges == 0, "golden opportunity should be consumed exactly once", failures)
	_check(bound.routing_momentum_golden_target_claim_id == -1, "the fulfilled Golden File should clear its seal", failures)


func _test_team_lift_receipt(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(8131)
	var lanes: Array[StringName] = [&"nest_damage", &"predator_loss", &"appeals"]
	for dispatch_index in 9:
		_best_fit_dispatch(simulation, lanes[dispatch_index % lanes.size()], failures)
	for worker in simulation.workers:
		if not worker.employed:
			continue
		worker.morale = 50.0
		worker.stress = 50.0
		worker.fatigue = 50.0
	simulation.solidarity = 50.0
	var tenth := _best_fit_dispatch(simulation, lanes[0], failures)
	var reward := tenth.get("reward", {}) as Dictionary
	_check(int(tenth.get("momentum_chain", -1)) == 10, "ten best-fit routes should reach Team Lift", failures)
	_check(StringName(reward.get("id", &"")) == &"team_lift", "x10 should award Team Lift", failures)
	var employed_count := 0
	for worker in simulation.workers:
		if worker.employed:
			employed_count += 1
	_check(int(reward.get("affected_count", -1)) == employed_count, "Team Lift should name every employed hen", failures)
	_check((reward.get("affected_workers", []) as Array).size() == employed_count, "Team Lift should expose one receipt per affected hen", failures)
	for affected_value in reward.get("affected_workers", []):
		var affected := affected_value as Dictionary
		_check(
			is_equal_approx(float(affected.get("morale_delta", 0.0)), 3.0)
			and is_equal_approx(float(affected.get("stress_delta", 0.0)), -2.0)
			and is_equal_approx(float(affected.get("fatigue_delta", 0.0)), -1.0),
			"each Team Lift receipt should expose exact +3/-2/-1 deltas",
			failures,
		)
	_check(is_equal_approx(float(reward.get("solidarity_delta", 0.0)), 1.0), "Team Lift should expose its exact solidarity change", failures)
	_check(not String(reward.get("authority_key", "")).is_empty(), "Team Lift should carry a stable single-fire presentation key", failures)
	var mastery_horizon := simulation.routing_momentum_snapshot()
	_check(
		int(mastery_horizon.get("next_milestone", 0)) == 15
		and String(mastery_horizon.get("next_reward", "")) == "MASTER RECORD"
		and StringName(mastery_horizon.get("mastery_target_kind", &"")) == &"record",
		"Team Lift should reveal the next balanced mastery record at x15",
		failures,
	)
	for dispatch_index in range(10, 14):
		var continuation := _best_fit_dispatch(simulation, lanes[dispatch_index % lanes.size()], failures)
		_check((continuation.get("reward", {}) as Dictionary).is_empty(), "ordinary post-x10 routes should not spam rewards", failures)
	var fifteenth := _best_fit_dispatch(simulation, lanes[14 % lanes.size()], failures)
	var record_reward := fifteenth.get("reward", {}) as Dictionary
	_check(
		StringName(record_reward.get("id", &"")) == &"mastery_record"
		and int(record_reward.get("record_before", -1)) == 14
		and int(record_reward.get("record_after", -1)) == 15
		and String(record_reward.get("label", "")) == "RECORD x15",
		"x15 should file one exact non-economic mastery record",
		failures,
	)
	var mastery_state := simulation.export_save_state()
	var mastery_restored := DepartmentSimulation.new(8134)
	_check(mastery_restored.restore_save_state(mastery_state), "post-x10 mastery should restore", failures)
	_check(
		int(mastery_restored.routing_momentum_snapshot().get("best_chain", 0)) == 15
		and int(mastery_restored.routing_momentum_snapshot().get("next_milestone", 0)) == 20,
		"the restored record should retain its next x20 horizon",
		failures,
	)
	simulation.call("_break_routing_momentum", "Mastery rebuild fixture.", &"test")
	for dispatch_index in 10:
		_best_fit_dispatch(simulation, lanes[dispatch_index % lanes.size()], failures)
	var rebuild_horizon := simulation.routing_momentum_snapshot()
	_check(
		int(rebuild_horizon.get("next_milestone", 0)) == 15
		and String(rebuild_horizon.get("next_reward", "")) == "REBUILD BEST"
		and StringName(rebuild_horizon.get("mastery_target_kind", &"")) == &"rebuild",
		"a broken mastery chain should name the exact prior record to rebuild",
		failures,
	)
	for dispatch_index in range(10, 15):
		var rebuilt := _best_fit_dispatch(simulation, lanes[dispatch_index % lanes.size()], failures)
		_check((rebuilt.get("reward", {}) as Dictionary).is_empty(), "rebuilding an old record must not replay its medal", failures)
	_check(
		int(simulation.routing_momentum_snapshot().get("next_milestone", 0)) == 20,
		"matching the old record should advance the horizon to x20",
		failures,
	)
	for dispatch_index in range(15, 20):
		var next_record := _best_fit_dispatch(simulation, lanes[dispatch_index % lanes.size()], failures)
		if dispatch_index < 19:
			_check((next_record.get("reward", {}) as Dictionary).is_empty(), "record progress should stay restrained between five-route crests", failures)
		else:
			_check(
				StringName((next_record.get("reward", {}) as Dictionary).get("id", &"")) == &"mastery_record"
				and int((next_record.get("reward", {}) as Dictionary).get("record_after", 0)) == 20,
				"surpassing the rebuilt best at x20 should file the next record once",
				failures,
			)
	var capped := DepartmentSimulation.new(8133)
	for worker in capped.workers:
		if worker.employed:
			worker.morale = 99.0
			worker.stress = 1.0
			worker.fatigue = 0.0
	capped.solidarity = 100.0
	var capped_reward := capped.call("_apply_routing_momentum_milestone", 10) as Dictionary
	var capped_first := (capped_reward.get("affected_workers", []) as Array)[0] as Dictionary
	_check(
		String(capped_reward.get("label", "")) == "ALL LIFTED"
		and is_equal_approx(float(capped_first.get("morale_delta", 0.0)), 1.0)
		and is_equal_approx(float(capped_first.get("stress_delta", 0.0)), -1.0)
		and is_equal_approx(float(capped_first.get("fatigue_delta", 1.0)), 0.0)
		and is_equal_approx(float(capped_reward.get("solidarity_delta", 1.0)), 0.0),
		"capped Team Lift receipts must expose actual deltas instead of claiming the nominal award",
		failures,
	)


func _seed_for_sound_egg(crack_risk: float, golden_chance: float) -> int:
	for candidate in range(1, 10_000):
		var probe := RandomNumberGenerator.new()
		probe.seed = candidate
		if probe.randf() >= crack_risk and probe.randf() >= golden_chance:
			return candidate
	return -1


func _seed_for_cracked_egg(crack_risk: float) -> int:
	for candidate in range(1, 10_000):
		var probe := RandomNumberGenerator.new()
		probe.seed = candidate
		if probe.randf() < crack_risk:
			return candidate
	return -1


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
