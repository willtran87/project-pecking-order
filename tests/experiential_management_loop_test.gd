extends SceneTree

const DirectorScript := preload("res://core/experience/gameplay_pulse_director.gd")


func _init() -> void:
	var failures: Array[String] = []
	var emergency := _running_simulation(260829)
	var compliance_before := emergency.compliance
	var intervention := emergency.perform_playbook_action(&"intervention", &"emergency_review", 0)
	var modifiers := emergency.snapshot().get("decision_modifiers", {}) as Dictionary
	var playbook := emergency.playbook_snapshot(0)
	_check(
		bool(intervention.get("accepted", false))
		and String((playbook.get("manager_intervention", {}) as Dictionary).get("id", "")) == "emergency_review"
		and bool((playbook.get("manager_intervention", {}) as Dictionary).get("used", false))
		and bool((playbook.get("manager_intervention", {}) as Dictionary).get("one_per_shift", false))
		and is_equal_approx(emergency.compliance, minf(100.0, compliance_before + 3.0))
		and is_equal_approx(float(modifiers.get("playbook_work_multiplier", 1.0)), 0.931588)
		and is_equal_approx(float(modifiers.get("playbook_crack_modifier", 0.0)), -0.058),
		"emergency review should trade exact pace for exact quality and compliance",
		failures,
	)
	_check(
		not bool(emergency.perform_playbook_action(&"intervention", &"ring_bell", 0).get("accepted", false)),
		"the manager should receive exactly one intervention per shift",
		failures,
	)

	var bell := _running_simulation(260830)
	var bell_result := bell.perform_playbook_action(&"intervention", &"ring_bell", 0)
	_check(
		bool(bell_result.get("accepted", false))
		and bell.routing_momentum_peck_recharge_bank == 1,
		"ringing the bell should restore one bounded attention charge",
		failures,
	)
	var coffee := _running_simulation(260831)
	coffee.revenue_cents = 10000
	for worker in coffee.workers:
		if worker.employed:
			worker.morale = 50.0
			worker.stress = 50.0
			worker.fatigue = 50.0
	var coffee_result := coffee.perform_playbook_action(&"intervention", &"coffee_run", 0)
	_check(
		bool(coffee_result.get("accepted", false))
		and coffee.revenue_cents == 9800
		and is_equal_approx(coffee.workers[0].morale, 52.0)
		and is_equal_approx(coffee.workers[0].stress, 46.0)
		and is_equal_approx(coffee.workers[0].fatigue, 48.0),
		"coffee run should spend exactly $2 and recover the active flock",
		failures,
	)
	var restored := DepartmentSimulation.new(1, 4)
	_check(
		restored.restore_save_state(coffee.export_save_state())
		and String(restored.active_playbook.get("manager_intervention_id", "")) == "coffee_run",
		"the bounded intervention should survive a checkpoint without duplication",
		failures,
	)

	var cause_replay := {
		"available": true,
		"active": false,
		"worker_id": 0,
		"worker_name": emergency.workers[0].display_name,
		"lane": "appeals",
		"file_label": "APPEALS",
		"result_label": "BEST FIT",
		"path": ["FILE", "HEN", "RESULT"],
		"input": "H",
		"files_nothing": true,
		"presentation_only": true,
	}
	var pulse := DirectorScript.new().compose({
		"simulation": emergency.snapshot(),
		"next_action": {"action_id": "route", "visible_label": "ROUTE NEXT FILE", "actionable": true},
		"focused_worker_id": 0,
		"active_playbook": playbook,
		"cause_replay": cause_replay,
	})
	var layer := pulse.get("experiential_management_loop", {}) as Dictionary
	var explain := (pulse.get("complete_game_loop", {}) as Dictionary).get("explain_mode", {}) as Dictionary
	_check(
		int(pulse.get("version", 0)) == 16
		and int(layer.get("item_count", 0)) == 20
		and int(layer.get("resolved_count", 0)) == 20
		and bool(layer.get("all_resolved", false))
		and not bool(layer.get("authoritative", true))
		and not bool(layer.get("adds_default_panel", true)),
		"the experiential layer should resolve all twenty items without adding authority or a panel",
		failures,
	)
	_check(
		int((layer.get("glance", {}) as Dictionary).get("card_count", 0)) == 3
		and int((layer.get("docket_draft", {}) as Dictionary).get("choice_count", 0)) == 3
		and int((layer.get("case_personas", []) as Array).size()) == 3
		and int((layer.get("specializations", {}) as Dictionary).get("count", 0)) == 3
		and bool((layer.get("automation", {}) as Dictionary).get("exception_only", false)),
		"goal, danger, reward, draft, case, specialization, and automation cues should stay compact",
		failures,
	)
	_check(
		bool(explain.get("replays_last_cause", false))
		and bool(explain.get("files_nothing", false))
		and int(explain.get("chip_count", 0)) == 4
		and bool((layer.get("comprehension", {}) as Dictionary).get("real_participants_required", false))
		and bool((layer.get("comprehension", {}) as Dictionary).get("results_never_fabricated", false)),
		"H replay should explain causality without mutation and usability evidence should remain honest",
		failures,
	)

	if not failures.is_empty():
		for failure in failures:
			push_error("EXPERIENTIAL_MANAGEMENT_LOOP_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("EXPERIENTIAL_MANAGEMENT_LOOP_TEST_PASSED items=20 intervention=one-shot replay=presentation-only draft=3 personas=3")
	quit(0)


func _running_simulation(seed: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 4)
	for worker_id in simulation.workers.size():
		simulation.set_worker_at_workstation(worker_id, true)
	simulation.select_directive(&"shell_assurance")
	simulation.revenue_cents = 10000
	simulation.perform_playbook_action(&"preset", &"safe", 0)
	return simulation


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
