extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_test_career_tiers(failures)
	_test_deterministic_profiles(failures)
	_test_action_guards_are_atomic(failures)
	_test_exact_preferred_action_effects(failures)
	_test_nonpreferred_pressure_effect(failures)
	_test_actions_change_authoritative_speed_and_risk(failures)
	_test_check_in_reopens_next_shift(failures)
	_test_laid_egg_awards_xp_and_promotes(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("PERSONNEL_CAREER_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PERSONNEL_CAREER_TEST_PASSED tiers=4 profiles=deterministic actions=atomic careers=causal shifts=reopen")
	quit(0)


func _test_career_tiers(failures: Array[String]) -> void:
	var worker := ChickenState.new(0, "Boundary Hen", 0, 1.0, 0.9, &"appeals")
	var cases: Array[Dictionary] = [
		{"xp": 0, "level": 0, "title": "JUNIOR CLAIMS HEN", "next": 18},
		{"xp": 17, "level": 0, "title": "JUNIOR CLAIMS HEN", "next": 18},
		{"xp": 18, "level": 1, "title": "ACCREDITED LAYER", "next": 45},
		{"xp": 44, "level": 1, "title": "ACCREDITED LAYER", "next": 45},
		{"xp": 45, "level": 2, "title": "SENIOR CLAIMS HEN", "next": 80},
		{"xp": 79, "level": 2, "title": "SENIOR CLAIMS HEN", "next": 80},
		{"xp": 80, "level": 3, "title": "PRINCIPAL SHELL ADJUSTER", "next": -1},
	]
	for case in cases:
		worker.career_xp = int(case["xp"])
		_check(worker.career_level() == int(case["level"]), "XP %d should map to career tier %d" % [case["xp"], case["level"]], failures)
		_check(worker.career_title() == String(case["title"]), "XP %d should map to %s" % [case["xp"], case["title"]], failures)
		_check(worker.career_next_threshold() == int(case["next"]), "XP %d should expose the correct next threshold" % case["xp"], failures)

	worker.career_xp = 17
	_check(worker.add_career_xp(1), "crossing 18 XP should report a promotion", failures)
	_check(worker.career_level() == 1, "crossing 18 XP should enter the accredited tier", failures)
	_check(not worker.add_career_xp(-50), "negative XP awards should be ignored", failures)
	_check(worker.career_xp == 18, "negative XP should never remove earned career progress", failures)


func _test_deterministic_profiles(failures: Array[String]) -> void:
	var expected: Array[StringName] = [
		&"credit_conscious",
		&"advancement_minded",
		&"quota_conditioned",
		&"credit_conscious",
		&"advancement_minded",
		&"quota_conditioned",
	]
	var simulation := DepartmentSimulation.new(101)
	for worker_id in expected.size():
		var worker := simulation.workers[worker_id]
		_check(worker.career_profile == expected[worker_id], "worker %d should receive the deterministic %s profile" % [worker_id, expected[worker_id]], failures)
		_check(worker.career_profile == ChickenState.default_career_profile(worker_id), "worker %d profile should agree with the public profile mapping" % worker_id, failures)
		var preferred_count := 0
		for action in simulation.personnel_action_catalog(worker_id):
			if bool(action.get("preferred", false)):
				preferred_count += 1
		_check(preferred_count == 1, "worker %d should have exactly one preferred personnel action" % worker_id, failures)
	_check(ChickenState.default_career_profile(6) == &"credit_conscious", "career profiles should repeat deterministically for later roster IDs", failures)


func _test_action_guards_are_atomic(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(202)
	_check_rejected_atomically(simulation, 0, &"share_credit", "briefing-time action", failures)
	_check(_start_running(simulation), "guard fixture should enter a running shift", failures)
	_check_rejected_atomically(simulation, -1, &"share_credit", "invalid worker", failures)
	_check_rejected_atomically(simulation, 0, &"not_in_handbook", "invalid action", failures)

	simulation.revenue_cents = _protected_fund_cents(simulation, 699)
	_check_rejected_atomically(simulation, 0, &"share_credit", "underfunded action", failures)
	simulation.revenue_cents = _protected_fund_cents(simulation, 0)
	var accepted := simulation.perform_personnel_action(2, &"quota_pressure")
	_check(bool(accepted.get("accepted", false)), "a valid running-shift check-in should be accepted", failures)
	_check(simulation.personnel_action_used_today(), "accepted action should consume the one daily flock check-in", failures)
	_check_rejected_atomically(simulation, 1, &"career_coaching", "second same-day action", failures)


func _test_exact_preferred_action_effects(failures: Array[String]) -> void:
	var share := _prepared_action_simulation(301, 0)
	var share_fund_before := share.revenue_cents
	var share_result := share.perform_personnel_action(0, &"share_credit")
	_check_action_result(share_result, true, 700, {
		"trust": 18.0,
		"grievance": -13.0,
		"morale": 10.0,
		"stress": -5.0,
		"fatigue": 0.0,
		"career_xp": 6.0,
		"farmer_favor": -2.0,
		"compliance": 0.0,
		"solidarity": 2.0,
		"shift_work_multiplier": 1.0,
		"shift_crack_modifier": 0.0,
	}, "preferred credit sharing", failures)
	_check(share.revenue_cents == share_fund_before - 700, "credit sharing should deduct exactly $7.00", failures)
	_check(share.revenue_cents >= _protected_fund_cents(share, 0), "credit sharing should preserve protected operating obligations", failures)

	var coaching := _prepared_action_simulation(302, 1)
	var coaching_fund_before := coaching.revenue_cents
	var coaching_result := coaching.perform_personnel_action(1, &"career_coaching")
	_check_action_result(coaching_result, true, 400, {
		"trust": 9.0,
		"grievance": -3.0,
		"morale": 3.0,
		"stress": 3.0,
		"fatigue": 2.0,
		"career_xp": 22.0,
		"farmer_favor": 0.0,
		"compliance": 2.0,
		"solidarity": 0.0,
		"shift_work_multiplier": 0.94,
		"shift_crack_modifier": -0.03,
	}, "preferred career coaching", failures)
	_check(coaching.revenue_cents == coaching_fund_before - 400, "career coaching should deduct exactly $4.00", failures)
	_check(coaching.revenue_cents >= _protected_fund_cents(coaching, 0), "career coaching should preserve protected operating obligations after promotion", failures)
	_check(bool(coaching_result.get("promoted", false)), "preferred coaching from zero XP should cross the first promotion threshold", failures)
	_check(String(coaching_result.get("career_title", "")) == "ACCREDITED LAYER", "coaching promotion should expose the new title", failures)

	var pressure := _prepared_action_simulation(303, 2)
	var pressure_fund_before := pressure.revenue_cents
	var pressure_result := pressure.perform_personnel_action(2, &"quota_pressure")
	_check_action_result(pressure_result, true, 0, {
		"trust": -12.0,
		"grievance": 10.0,
		"morale": -7.0,
		"stress": 8.0,
		"fatigue": 4.0,
		"career_xp": 5.0,
		"farmer_favor": 3.0,
		"compliance": 2.0,
		"solidarity": 4.0,
		"shift_work_multiplier": 1.18,
		"shift_crack_modifier": 0.025,
	}, "preferred quota pressure", failures)
	_check(pressure.revenue_cents == pressure_fund_before, "quota pressure should remain free in Feed Fund terms", failures)
	_check(pressure.revenue_cents >= _protected_fund_cents(pressure, 0), "free pressure should preserve protected operating obligations", failures)


func _test_nonpreferred_pressure_effect(failures: Array[String]) -> void:
	var simulation := _prepared_action_simulation(304, 0)
	var result := simulation.perform_personnel_action(0, &"quota_pressure")
	_check(bool(result.get("accepted", false)), "nonpreferred pressure should still be a valid management choice", failures)
	_check(not bool(result.get("preferred", true)), "credit-conscious worker should flag quota pressure as nonpreferred", failures)
	var effects := result.get("effects", {}) as Dictionary
	_check(_approximately(float(effects.get("grievance", 0.0)), 14.0), "nonpreferred pressure should add fourteen grievance points", failures)
	_check(_approximately(float(effects.get("shift_work_multiplier", 0.0)), 1.14), "nonpreferred pressure should use the lower 1.14 speed multiplier", failures)
	_check(_approximately(float(effects.get("shift_crack_modifier", 0.0)), 0.025), "all quota pressure should add 2.5 crack-risk points", failures)


func _test_actions_change_authoritative_speed_and_risk(failures: Array[String]) -> void:
	var baseline := DepartmentSimulation.new(401)
	var coaching := DepartmentSimulation.new(401)
	var pressure := DepartmentSimulation.new(401)
	for simulation in [baseline, coaching, pressure]:
		_check(_start_running(simulation), "causal fixture should enter a running shift", failures)
		simulation.revenue_cents = _protected_fund_cents(simulation, 500)
		simulation.set_worker_at_workstation(0, true)

	var coaching_result := coaching.perform_personnel_action(0, &"career_coaching")
	var pressure_result := pressure.perform_personnel_action(0, &"quota_pressure")
	_check(bool(coaching_result.get("accepted", false)), "coaching causal fixture should accept its action", failures)
	_check(bool(pressure_result.get("accepted", false)), "pressure causal fixture should accept its action", failures)
	_check(coaching.estimated_crack_risk(0) < baseline.estimated_crack_risk(0), "career coaching should lower authoritative crack risk", failures)
	_check(pressure.estimated_crack_risk(0) > baseline.estimated_crack_risk(0), "quota pressure should raise authoritative crack risk", failures)

	for _tick in 2:
		baseline.advance_tick()
		coaching.advance_tick()
		pressure.advance_tick()
	var base_progress := baseline.workers[0].work_progress
	var coaching_progress := coaching.workers[0].work_progress
	var pressure_progress := pressure.workers[0].work_progress
	_check(coaching_progress > 0.0 and base_progress > 0.0 and pressure_progress > 0.0, "causal fixtures should all enter active peckwork", failures)
	_check(coaching_progress < base_progress, "career coaching should trade current-shift speed for safer development time", failures)
	_check(pressure_progress > base_progress, "quota pressure should causally increase current-shift peckwork speed", failures)

	var base_worker := _worker_snapshot(baseline.snapshot(), 0)
	var coaching_worker := _worker_snapshot(coaching.snapshot(), 0)
	var pressure_worker := _worker_snapshot(pressure.snapshot(), 0)
	_check(float(coaching_worker.get("career_work_multiplier", 0.0)) < float(base_worker.get("career_work_multiplier", 0.0)), "coaching speed tradeoff should remain visible in the worker snapshot", failures)
	_check(float(pressure_worker.get("career_work_multiplier", 0.0)) > float(base_worker.get("career_work_multiplier", 0.0)), "pressure speed bonus should remain visible in the worker snapshot", failures)


func _test_check_in_reopens_next_shift(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(501)
	var reports: Array[Dictionary] = []
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		reports.append(report.duplicate(true))
	)
	_check(_start_running(simulation), "reopening fixture should enter day one's running shift", failures)
	simulation.revenue_cents = _protected_fund_cents(simulation, 700)
	var first := simulation.perform_personnel_action(0, &"share_credit")
	_check(bool(first.get("accepted", false)), "day one should accept its flock check-in", failures)
	_complete_shift_to_review(simulation, failures)
	_check(simulation.day == 2 and simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW, "completed day should enter day-two review", failures)
	_check(not simulation.personnel_action_used_today(), "day one's check-in should not consume day two's allowance", failures)
	var review_status := simulation.personnel_action_status()
	_check(not bool(review_status.get("used_today", true)), "review status should report the new day as unused", failures)
	_check(not bool(review_status.get("available", true)), "personnel actions should remain closed during review", failures)
	_check(reports.size() == 1, "shift completion should emit one personnel-aware report", failures)
	if reports.size() == 1:
		var reported_action := reports[0].get("personnel_action", {}) as Dictionary
		_check(StringName(reported_action.get("action_id", &"")) == &"share_credit", "review should retain day one's personnel choice", failures)
		_check(int(reported_action.get("worker_id", -1)) == 0, "review should retain the selected worker", failures)

	_resolve_closing_credit(simulation, failures)
	_check(simulation.begin_next_shift_briefing(), "review should explicitly open day two's briefing after credit is filed", failures)
	_check(simulation.select_directive(&"shell_assurance"), "day two directive should start the next running shift", failures)
	_check(bool(simulation.personnel_action_status().get("available", false)), "day two running shift should reopen the flock check-in", failures)
	var second := simulation.perform_personnel_action(1, &"quota_pressure")
	_check(bool(second.get("accepted", false)), "day two should accept a new action for another hen", failures)
	_check(simulation.workers[1].last_personnel_action_day == 2, "day-two action should retain its own shift date", failures)
	_check(simulation.personnel_action_used_today(), "day-two allowance should be consumed only after its new action", failures)


func _test_laid_egg_awards_xp_and_promotes(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(601)
	var worker := simulation.workers[0]
	worker.career_xp = 17
	var laid_qualities: Array[StringName] = []
	var announcements: Array[String] = []
	simulation.egg_laid.connect(func(worker_id: int, quality: StringName, _value_cents: int) -> void:
		if worker_id == 0:
			laid_qualities.append(quality)
	)
	simulation.announcement_posted.connect(func(message: String) -> void:
		announcements.append(message)
	)
	_check(_start_running(simulation), "work-XP fixture should enter a running shift", failures)
	simulation.set_worker_at_workstation(0, true)
	var safety := 0
	while simulation.eggs_today == 0 and safety < 120:
		if simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT:
			_resolve_free_incident_option(simulation, failures)
		else:
			simulation.advance_tick()
		safety += 1

	_check(simulation.eggs_today == 1, "a seated hen should complete one egg within the bounded work fixture", failures)
	_check(laid_qualities.size() == 1, "completed work should emit one quality-tagged egg", failures)
	if laid_qualities.size() == 1:
		var quality := laid_qualities[0]
		var expected_xp := 1 if quality == &"cracked" else (5 if quality == &"golden" else 3)
		_check(worker.career_xp == 17 + expected_xp, "%s work should award exactly %d career XP" % [quality, expected_xp], failures)
	_check(worker.career_level() == 1, "the laid egg should promote a 17-XP hen into the accredited tier", failures)
	_check(worker.career_title() == "ACCREDITED LAYER", "work-earned promotion should expose the accredited title", failures)
	var promotion_announced := false
	for announcement in announcements:
		if "PROMOTION FILED" in announcement and worker.display_name.to_upper() in announcement:
			promotion_announced = true
			break
	_check(promotion_announced, "work-earned promotion should post a named office announcement", failures)


func _prepared_action_simulation(seed: int, worker_id: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed)
	_start_running(simulation)
	var worker := simulation.workers[worker_id]
	worker.manager_trust = 50.0
	worker.grievance = 30.0
	worker.morale = 60.0
	worker.stress = 20.0
	worker.fatigue = 10.0
	worker.career_xp = 0
	simulation.executive_confidence = 50.0
	simulation.compliance = 70.0
	simulation.solidarity = 20.0
	simulation.revenue_cents = _protected_fund_cents(simulation, 10000)
	return simulation


func _protected_fund_cents(simulation: DepartmentSimulation, discretionary_cents: int) -> int:
	return (
		simulation.current_daily_operating_cost_cents()
		+ simulation.wage_arrears_cents
		+ discretionary_cents
	)


func _start_running(simulation: DepartmentSimulation) -> bool:
	return simulation.select_directive(&"shell_assurance")


func _complete_shift_to_review(simulation: DepartmentSimulation, failures: Array[String]) -> void:
	var safety := 0
	while simulation.shift_phase != DepartmentSimulation.ShiftPhase.REVIEW and safety < 8:
		match simulation.shift_phase:
			DepartmentSimulation.ShiftPhase.RUNNING:
				simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
				simulation.advance_tick()
			DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT:
				_resolve_free_incident_option(simulation, failures)
			_:
				failures.append("shift fixture entered an unexpected phase before review")
				return
		safety += 1
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW, "bounded shift completion should reach review after resolving incidents", failures)


func _resolve_free_incident_option(simulation: DepartmentSimulation, failures: Array[String]) -> void:
	var decision := simulation.pending_decision_snapshot()
	var selected: StringName = &""
	for option_value in decision.get("options", []):
		var option := option_value as Dictionary
		if int(option.get("cost_cents", 0)) == 0:
			selected = StringName(option.get("id", &""))
			break
	_check(selected != &"", "incident fixture should expose a free resolution option", failures)
	if selected != &"":
		_check(simulation.resolve_decision(int(decision.get("serial", -1)), selected), "free incident option should resolve the paused shift", failures)


func _resolve_closing_credit(simulation: DepartmentSimulation, failures: Array[String]) -> void:
	var decision := simulation.pending_decision_snapshot()
	_check(StringName(decision.get("kind", &"")) in [&"credit_allocation", &"major_event"], "review fixture should expose its closing credit decision", failures)
	var option_id: StringName
	match StringName(decision.get("id", &"")):
		&"closing_credit_memo":
			option_id = &"reward_top_layer"
		&"golden_egg_dossier":
			option_id = &"name_the_layer"
		&"flock_restructuring":
			option_id = &"contest_ranking"
		_:
			_check(false, "review fixture should expose a recognized closing decision ID", failures)
			return
	_check(simulation.resolve_decision(int(decision.get("serial", -1)), option_id), "review fixture should file a free closing attribution", failures)


func _check_rejected_atomically(
	simulation: DepartmentSimulation,
	worker_id: int,
	action_id: StringName,
	label: String,
	failures: Array[String]
) -> void:
	var before := JSON.stringify(simulation.export_save_state())
	var result := simulation.perform_personnel_action(worker_id, action_id)
	var after := JSON.stringify(simulation.export_save_state())
	_check(not bool(result.get("accepted", false)), "%s should be rejected" % label, failures)
	_check(not String(result.get("reason", "")).is_empty(), "%s should explain its rejection" % label, failures)
	_check(after == before, "%s rejection should be fully atomic" % label, failures)


func _check_action_result(
	result: Dictionary,
	expected_preferred: bool,
	expected_cost_cents: int,
	expected_effects: Dictionary,
	label: String,
	failures: Array[String]
) -> void:
	_check(bool(result.get("accepted", false)), "%s should be accepted" % label, failures)
	_check(bool(result.get("preferred", not expected_preferred)) == expected_preferred, "%s should report profile-match status" % label, failures)
	_check(int(result.get("cost_cents", -1)) == expected_cost_cents, "%s should expose its exact cost" % label, failures)
	var effects := result.get("effects", {}) as Dictionary
	for effect_name in expected_effects:
		_check(
			_approximately(float(effects.get(effect_name, INF)), float(expected_effects[effect_name])),
			"%s should apply exact %s effect %.3f" % [label, effect_name, expected_effects[effect_name]],
			failures
		)


func _worker_snapshot(snapshot: Dictionary, worker_id: int) -> Dictionary:
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return worker
	return {}


func _approximately(actual: float, expected: float, tolerance: float = 0.0001) -> bool:
	return absf(actual - expected) <= tolerance


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
