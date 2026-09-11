extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var simulation := _running_fixture(8242, 2, &"shell_assurance")
	var opening_quota := simulation.quota_target
	_check(bool(simulation.perform_playbook_action(&"preset", &"safe", 0).get("accepted", false)), "the completion fixture should file the Safe plan", failures)
	var planned := simulation.playbook_snapshot(0)
	_check(_option_count(planned, &"modifier") == 3, "shift two should offer exactly three optional rule-changing modifiers after the plan", failures)

	var modifier := simulation.perform_playbook_action(&"modifier", &"rush_hour", 0)
	var rush_modifiers := simulation.snapshot().get("decision_modifiers", {}) as Dictionary
	_check(
		bool(modifier.get("accepted", false))
		and simulation.quota_target == opening_quota + 2
		and float(rush_modifiers.get("playbook_work_multiplier", 1.0)) > 1.0
		and is_equal_approx(float(rush_modifiers.get("playbook_crack_modifier", 0.0)), -0.033),
		"Rush Hour should visibly trade two quota eggs and shell exposure for real pace",
		failures,
	)
	_check(not bool(simulation.perform_playbook_action(&"modifier", &"glass_carton", 0).get("accepted", false)), "a shift modifier should lock exactly once", failures)

	var restored := DepartmentSimulation.new(1, 4)
	_check(restored.restore_save_state(simulation.export_save_state()) and String(restored.active_playbook.get("challenge_modifier_id", "")) == "rush_hour", "the selected modifier should survive a strict checkpoint", failures)

	var combo_fixture := _running_fixture(8243, 2, &"shell_assurance")
	_check(bool(combo_fixture.perform_playbook_action(&"preset", &"safe", 0).get("accepted", false)), "the combo fixture should file the Safe plan", failures)
	combo_fixture.quality_streak = 4
	combo_fixture.eggs_today = combo_fixture.quota_target
	var prediction := combo_fixture.playbook_snapshot(0).get("prediction_score", {}) as Dictionary
	_check(String(prediction.get("verdict", "")) == "CALLED IT" and int(prediction.get("score", 0)) == 2, "the plan prediction should score Called It immediately from authoritative progress", failures)
	_check(bool(combo_fixture.perform_playbook_action(&"push_luck", &"bank_clutch", 0).get("accepted", false)), "the Safe recipe should accept its banked-clutch step after quota", failures)
	var completed := combo_fixture.playbook_snapshot(0)
	var recipe := completed.get("combo_recipe", {}) as Dictionary
	var mastery := completed.get("strategy_mastery", {}) as Dictionary
	var objective := completed.get("dominant_objective", {}) as Dictionary
	_check(bool(recipe.get("complete", false)) and int(recipe.get("completed_steps", 0)) == 2 and String(recipe.get("effect", "")) == "SHELL RISK -1.5%", "Safe should complete a readable two-action recipe with a causal shell bonus", failures)
	_check(String(mastery.get("tier", "")) == "SIGNATURE BUILD" and int(mastery.get("marks", 0)) == 3, "contract, recipe, and personal goal should transform the plan into a named signature build", failures)
	_check(bool(objective.get("single", false)) and String(objective.get("kind", "")) == "reward" and (objective.get("ghost_path", []) as Array).size() == 3, "only one dominant reward objective and its physical ghost path should be projected", failures)
	_check(not (completed.get("relationship_echo", {}) as Dictionary).is_empty(), "the focused hen should expose a persistent relationship consequence echo", failures)
	_check(bool((completed.get("next_shift_preview", {}) as Dictionary).get("one_more_shift", false)), "the completed loop should tease one concrete next shift", failures)

	var one_bell := _running_fixture(8244, 2, &"record_harvest")
	_check(bool(one_bell.perform_playbook_action(&"preset", &"fast", 0).get("accepted", false)), "the One Bell fixture should file Fast", failures)
	_check(bool(one_bell.perform_playbook_action(&"modifier", &"one_bell", 0).get("accepted", false)), "One Bell should file before production", failures)
	one_bell.eggs_today = 1
	one_bell.cracked_today = 1
	_check(not bool((one_bell.playbook_snapshot(0).get("contextual_rescue", {}) as Dictionary).get("available", true)), "One Bell should materially disable the route rescue it discloses", failures)

	var final_fixture := _running_fixture(4703, DepartmentSimulation.PROBATION_CAMPAIGN_SHIFTS, &"sustainable_flock")
	_check(bool(final_fixture.perform_playbook_action(&"preset", &"flock", 0).get("accepted", false)), "the final fixture should carry a named build into the hearing", failures)
	var hearing := final_fixture.final_hearing_snapshot()
	var hearing_definition := final_fixture.call("_final_hearing_definition") as Dictionary
	_check(not (hearing.get("legacy_evidence", {}) as Dictionary).is_empty() and String(hearing_definition.get("body", "")).contains("PERMANENT EVIDENCE"), "the final hearing should incorporate the player's build, strongest hen, and relationship record", failures)

	var director := GameplayPulseDirector.new()
	var pulse := director.compose({
		"simulation": combo_fixture.snapshot(),
		"next_action": {"action_id": "route", "copy": "ROUTE THE NEXT FILE", "actionable": true},
		"routing_lifecycle": {},
		"action_feedback": {},
		"momentum_brief": {},
		"rival": {},
		"chapter": {},
		"first_session_funnel": {},
		"adaptive": {},
		"order_pulse": {},
		"focused_worker_id": 0,
		"active_playbook": completed,
	})
	var next_level := pulse.get("engagement_next_level", {}) as Dictionary
	_check(int(next_level.get("item_count", 0)) == 20 and bool(next_level.get("all_resolved", false)), "the presentation contract should map all twenty requested improvements to live game surfaces", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("INTUITIVE_ENGAGEMENT_COMPLETION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("INTUITIVE_ENGAGEMENT_COMPLETION_TEST_PASSED prediction=called-it recipes=2-step strategy=signature modifiers=3 objective=single climax=legacy items=20")
	quit(0)


func _running_fixture(seed: int, day: int, directive_id: StringName) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 4)
	simulation.day = day
	simulation.call("_reset_active_playbook")
	for worker_id in simulation.workers.size():
		simulation.set_worker_at_workstation(worker_id, true)
	simulation.revenue_cents = 10000
	simulation.select_directive(directive_id)
	return simulation


func _option_count(snapshot: Dictionary, kind: StringName) -> int:
	var count := 0
	for value in snapshot.get("options", []) as Array:
		if value is Dictionary and StringName((value as Dictionary).get("kind", &"")) == kind:
			count += 1
	return count


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
