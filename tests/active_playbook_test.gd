extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(260821, 4)
	for worker_id in simulation.workers.size():
		simulation.set_worker_at_workstation(worker_id, true)
	_check(simulation.select_directive(&"shell_assurance"), "fixture should enter a running shift", failures)
	simulation.revenue_cents = 10000

	var opening := simulation.playbook_snapshot(0)
	_check(
		bool(opening.get("authoritative", false))
		and (opening.get("shift_plan", []) as Array).size() == 3
		and (opening.get("shift_journey", []) as Array).size() == 4
		and (opening.get("options", []) as Array).size() >= 5
		and String(opening.get("recommended_preset_id", "")) == "safe",
		"the running shift should expose three guided plans, one four-stage journey, and a policy-fit recommendation",
		failures,
	)
	_check(_has_option(opening, &"preset", &"fast", true), "the fast one-click plan should be available", failures)
	_check(_has_option(opening, &"preset", &"safe", true), "the policy-fit safe plan should be available", failures)
	_check(_has_option(opening, &"preset", &"flock", true), "the flock one-click plan should be available", failures)
	_check(_has_option(opening, &"practice", &"peck", true), "practice should be consequence-free and available", failures)

	var preset_simulation := DepartmentSimulation.new(260822, 4)
	for worker_id in preset_simulation.workers.size():
		preset_simulation.set_worker_at_workstation(worker_id, true)
	_check(preset_simulation.select_directive(&"shell_assurance"), "preset fixture should enter a running shift", failures)
	preset_simulation.revenue_cents = 10000
	var guided_plan := preset_simulation.perform_playbook_action(&"preset", &"safe", 0)
	var guided_state := preset_simulation.playbook_snapshot(0)
	var guided_modifiers := preset_simulation.snapshot().get("decision_modifiers", {}) as Dictionary
	_check(
		bool(guided_plan.get("accepted", false))
		and String(guided_state.get("strategy_preset_id", "")) == "safe"
		and String((guided_state.get("contract", {}) as Dictionary).get("id", "")) == "clean_pair"
		and String(guided_state.get("loadout_id", "")) == "quality_floor"
		and String(guided_state.get("preparation_id", "")) == "brace_shells"
		and String((guided_state.get("side_goal", {}) as Dictionary).get("id", "")) == "clean_carton"
		and is_equal_approx(float(guided_modifiers.get("playbook_work_multiplier", 1.0)), 0.9506)
		and is_equal_approx(float(guided_modifiers.get("playbook_crack_modifier", 0.0)), -0.043),
		"one safe-plan action should atomically file its challenge, floor focus, preparation, goal, and exact modifiers",
		failures,
	)
	_check(
		not bool(preset_simulation.perform_playbook_action(&"preset", &"fast", 0).get("accepted", false)),
		"a guided plan should file exactly once",
		failures,
	)
	var preset_restored := DepartmentSimulation.new(6, 4)
	_check(
		preset_restored.restore_save_state(preset_simulation.export_save_state())
		and String(preset_restored.active_playbook.get("strategy_preset_id", "")) == "safe"
		and String((preset_restored.playbook_snapshot(0).get("smart_default", {}) as Dictionary).get("id", "")) == "safe",
		"the atomic guided plan and its non-mutating recommendation should survive a checkpoint",
		failures,
	)

	var contract := simulation.perform_playbook_action(&"contract", &"fit_three", 0)
	var loadout := simulation.perform_playbook_action(&"loadout", &"quality_floor", 0)
	var preparation := simulation.perform_playbook_action(&"preparation", &"rest_flock", 0)
	_check(bool(contract.get("accepted", false)), "the optional contract should file", failures)
	_check(bool(loadout.get("accepted", false)), "the shift loadout should file", failures)
	_check(bool(preparation.get("accepted", false)) and simulation.revenue_cents == 9800, "rest preparation should charge exactly $2", failures)
	var prepared_modifiers := simulation.snapshot().get("decision_modifiers", {}) as Dictionary
	_check(
		is_equal_approx(float(prepared_modifiers.get("playbook_work_multiplier", 1.0)), 0.98)
		and is_equal_approx(float(prepared_modifiers.get("playbook_crack_modifier", 0.0)), -0.018)
		and is_equal_approx(float(prepared_modifiers.get("playbook_strain_multiplier", 1.0)), 0.88),
		"loadout and preparation should change authoritative pace, shell risk, and strain",
		failures,
	)

	var before_practice := simulation.export_save_state()
	var practice := simulation.perform_playbook_action(&"practice", &"peck", 0)
	var after_practice := simulation.export_save_state()
	_check(
		bool(practice.get("accepted", false))
		and bool(practice.get("practice", false))
		and JSON.stringify(before_practice) == JSON.stringify(after_practice),
		"practice should provide feedback without mutating simulation authority",
		failures,
	)

	var xp_before := simulation.workers[0].career_xp
	simulation.routing_momentum_chain = 3
	simulation.best_routing_momentum_chain = 3
	var completed_contract := simulation.playbook_snapshot(0)
	_check(bool((completed_contract.get("contract", {}) as Dictionary).get("complete", false)), "fit three should complete from the authoritative route chain", failures)
	var reward := simulation.perform_playbook_action(&"reward", &"mastery", 0)
	_check(bool(reward.get("accepted", false)) and simulation.workers[0].career_xp == xp_before + 6, "the player should choose one exact contract reward", failures)
	_check(not bool(simulation.perform_playbook_action(&"reward", &"fund", 0).get("accepted", false)), "a completed contract should pay only once", failures)

	var signature := simulation.perform_playbook_action(&"signature", &"activate", 0)
	_check(
		bool(signature.get("accepted", false))
		and bool(signature.get("preferred", false))
		and bool(signature.get("signature", false)),
		"a focused hen's signature should execute her existing preferred personnel action",
		failures,
	)

	simulation.solidarity = 100.0
	for worker in simulation.workers:
		if worker.employed:
			worker.morale = 100.0
			worker.stress = 0.0
			worker.fatigue = 0.0
	var teamwork := simulation.perform_playbook_action(&"teamwork", &"team_lift", 0)
	_check(bool(teamwork.get("accepted", false)) and simulation.routing_momentum_peck_recharge_bank == 1, "a strong named bond should unlock one manual Team Lift", failures)

	var side_goal := simulation.perform_playbook_action(&"side_goal", &"team_lift", 0)
	_check(bool(side_goal.get("accepted", false)), "a personal side goal should be player-authored and penalty-free", failures)
	var authored := simulation.playbook_snapshot(0)
	_check(bool((authored.get("side_goal", {}) as Dictionary).get("complete", false)), "the pinned Team Lift side goal should resolve from the filed action", failures)

	simulation.eggs_today = 1
	simulation.eggs_total = maxi(1, simulation.eggs_total)
	var rival := simulation.perform_playbook_action(&"rival", &"counter", 0)
	_check(bool(rival.get("accepted", false)), "the rival response should open after the first delivery", failures)
	simulation.revenue_cents = 2000
	var recovery := simulation.perform_playbook_action(&"recovery", &"steady_fund", 0)
	_check(bool(recovery.get("accepted", false)), "a transparent recovery plan should open under cash pressure", failures)

	var encoded := JSON.stringify({"simulation": simulation.export_save_state()})
	var parsed: Variant = JSON.parse_string(encoded)
	var restored := DepartmentSimulation.new(4, 4)
	var restored_ok := (
		parsed is Dictionary
		and restored.restore_save_state((parsed as Dictionary).get("simulation", {}) as Dictionary)
	)
	_check(restored_ok, "a mid-shift active playbook should survive the JSON checkpoint", failures)
	if restored_ok:
		var restored_playbook := restored.active_playbook
		_check(
			String(restored_playbook.get("contract_id", "")) == "fit_three"
			and String(restored_playbook.get("contract_reward_id", "")) == "mastery"
			and String(restored_playbook.get("loadout_id", "")) == "quality_floor"
			and String(restored_playbook.get("preparation_id", "")) == "rest_flock"
			and String(restored_playbook.get("rival_response_id", "")) == "counter"
			and String(restored_playbook.get("recovery_id", "")) == "steady_fund"
			and String(restored_playbook.get("side_goal_id", "")) == "team_lift"
			and bool(restored_playbook.get("teamwork_used", false))
			and (restored_playbook.get("signature_worker_ids", []) as Array) == [0]
			and int(restored_playbook.get("receipt_serial", 0)) == 9
			and String((restored.playbook_snapshot(0).get("contract", {}) as Dictionary).get("id", "")) == "fit_three",
			"restore should preserve all filed playbook choices and receipts",
			failures,
		)
		restored.day += 1
		restored.call("_reset_daily_decision_state")
		var next_shift := restored.playbook_snapshot(0)
		_check(
			String((next_shift.get("contract", {}) as Dictionary).get("id", "")).is_empty()
			and not bool(next_shift.get("teamwork_used", true)),
			"day rollover should reset bounded shift choices without stale duplicates",
			failures,
		)

	if not failures.is_empty():
		for failure in failures:
			push_error("ACTIVE_PLAYBOOK_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("ACTIVE_PLAYBOOK_TEST_PASSED choices=9 presets=3 journey=4 reward=choose-one practice=atomic persistence=round-trip rollover=clean")
	quit(0)


func _has_option(snapshot: Dictionary, kind: StringName, choice_id: StringName, available: bool) -> bool:
	for option_value in snapshot.get("options", []):
		if not option_value is Dictionary:
			continue
		var option := option_value as Dictionary
		if (
			StringName(option.get("kind", &"")) == kind
			and StringName(option.get("id", &"")) == choice_id
			and bool(option.get("available", false)) == available
		):
			return true
	return false


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
