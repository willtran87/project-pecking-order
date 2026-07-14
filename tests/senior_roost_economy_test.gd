extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_test_guards_are_atomic(failures)
	_test_merit_grants(failures)
	_test_flock_dividend(failures)
	_test_harvest_forecast(failures)
	_test_annual_transition(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("SENIOR_ROOST_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SENIOR_ROOST_ECONOMY_TEST_PASSED policies=atomic effects=exact ranking=deterministic transitions=exact")
	quit(0)


func _test_guards_are_atomic(failures: Array[String]) -> void:
	var wrong_phase := _review_fixture(7101, 5000)
	wrong_phase.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	_expect_rejected_atomic(
		wrong_phase,
		func() -> Dictionary: return wrong_phase.apply_senior_quarter_policy(&"merit_grants"),
		"quarter policy outside REVIEW",
		failures,
	)
	_expect_rejected_atomic(
		wrong_phase,
		func() -> Dictionary: return wrong_phase.apply_senior_year_transition(true),
		"annual transition outside REVIEW",
		failures,
	)

	var unresolved := _review_fixture(7102, 5000)
	unresolved.pending_decision = {"id": &"closing_credit_memo", "kind": &"credit_allocation"}
	_expect_rejected_atomic(
		unresolved,
		func() -> Dictionary: return unresolved.apply_senior_quarter_policy(&"flock_dividend"),
		"quarter policy with unresolved closing credit",
		failures,
	)
	_expect_rejected_atomic(
		unresolved,
		func() -> Dictionary: return unresolved.apply_senior_year_transition(false),
		"annual transition with unresolved closing credit",
		failures,
	)

	var unknown := _review_fixture(7103, 5000)
	_expect_rejected_atomic(
		unknown,
		func() -> Dictionary: return unknown.apply_senior_quarter_policy(&"executive_omelette"),
		"unknown quarter policy",
		failures,
	)

	var short_merit := _review_fixture(7104, 1199)
	_expect_rejected_atomic(
		short_merit,
		func() -> Dictionary: return short_merit.apply_senior_quarter_policy(&"merit_grants"),
		"merit grant one cent below its discretionary cost",
		failures,
	)
	var short_dividend := _review_fixture(7105, 2399)
	_expect_rejected_atomic(
		short_dividend,
		func() -> Dictionary: return short_dividend.apply_senior_quarter_policy(&"flock_dividend"),
		"flock dividend one cent below its discretionary cost",
		failures,
	)

	var empty_roster := _review_fixture(7106, 5000)
	for worker in empty_roster.workers:
		worker.employed = false
	_expect_rejected_atomic(
		empty_roster,
		func() -> Dictionary: return empty_roster.apply_senior_quarter_policy(&"merit_grants"),
		"merit grant without an employed hen",
		failures,
	)


func _test_merit_grants(failures: Array[String]) -> void:
	var simulation := _review_fixture(7201, 1200)
	# The first row is a stale applicant. Worker two is therefore the first valid
	# ranked hen and must receive the award instead of relying on array order.
	simulation.last_pecking_order = [
		{"worker_id": 4},
		{"worker_id": 2},
		{"worker_id": 0},
	]
	var revenue_before := simulation.revenue_cents
	var worker_states := _worker_states(simulation)
	var result := simulation.apply_senior_quarter_policy(&"merit_grants")
	_check(bool(result.get("accepted", false)), "ranked merit grant should be accepted", failures)
	_check(StringName(result.get("policy_id", &"")) == &"merit_grants", "merit receipt should identify its policy", failures)
	_check(StringName(result.get("style_id", &"")) == &"individual_merit", "merit receipt should record individual leadership", failures)
	_check(int(result.get("day", -1)) == 8, "review receipt should name the completed shift", failures)
	_check(int(result.get("cost_cents", -1)) == 1200, "merit grant should cost exactly $12", failures)
	_check(int(result.get("fund_delta_cents", 0)) == -1200, "merit receipt should expose its exact fund delta", failures)
	_check(simulation.revenue_cents == revenue_before - 1200, "merit grant should deduct exactly $12", failures)
	_check(int(result.get("worker_id", -1)) == 2, "merit grant should skip stale ranked applicants", failures)
	_check(String(result.get("worker_name", "")) == simulation.workers[2].display_name, "merit receipt should name the selected hen", failures)
	_check(bool(result.get("promoted", false)), "eighteen merit XP should report the first promotion", failures)
	_check(simulation.workers[2].career_xp == 18, "merit winner should gain eighteen XP", failures)
	_check(_approximately(simulation.workers[2].morale, 58.0), "merit winner should gain eight morale", failures)
	_check(_approximately(simulation.workers[2].manager_trust, 60.0), "merit winner should gain ten trust", failures)
	_check(_approximately(simulation.workers[2].grievance, 22.0), "merit winner should lose eight grievance", failures)
	_check(_approximately(simulation.compliance, 74.0), "merit policy should add four compliance", failures)
	_check(_approximately(simulation.executive_confidence, 48.0), "merit policy should cost two farmer favor", failures)
	_check(simulation.quota_target == 20, "merit policy should leave quota unchanged", failures)
	_check(int(simulation.credit_choice_counts.get(&"individual_merit", -1)) == 1, "merit policy should advance individual leadership history", failures)
	_check(int(result.get("workers_affected", -1)) == 1, "merit receipt should expose one affected hen", failures)
	_check_worker_effect(_effect_for_worker(result, 2), {
		"career_xp": 18,
		"morale": 8.0,
		"stress": 0.0,
		"fatigue": 0.0,
		"manager_trust": 10.0,
		"grievance": -8.0,
	}, "merit winner", failures)
	for worker_id in simulation.workers.size():
		if worker_id == 2:
			continue
		_check(simulation.workers[worker_id].to_save_data() == worker_states[worker_id], "merit grant should not mutate worker %d" % worker_id, failures)

	var fallback := _review_fixture(7202, 1200)
	fallback.last_pecking_order.clear()
	var fallback_result := fallback.apply_senior_quarter_policy(&"merit_grants")
	_check(int(fallback_result.get("worker_id", -1)) == 0, "empty ranking should fall back to the lowest employed worker ID", failures)


func _test_flock_dividend(failures: Array[String]) -> void:
	var simulation := _review_fixture(7301, 2400)
	var revenue_before := simulation.revenue_cents
	var applicant_states := {
		4: simulation.workers[4].to_save_data(),
		5: simulation.workers[5].to_save_data(),
	}
	var result := simulation.apply_senior_quarter_policy(&"flock_dividend")
	_check(bool(result.get("accepted", false)), "funded flock dividend should be accepted", failures)
	_check(int(result.get("cost_cents", -1)) == 2400, "flock dividend should cost exactly $24", failures)
	_check(simulation.revenue_cents == revenue_before - 2400, "flock dividend should deduct exactly $24", failures)
	_check(int(result.get("workers_affected", -1)) == 4, "flock dividend should affect employed hens only", failures)
	for worker_id in 4:
		var worker := simulation.workers[worker_id]
		_check(_approximately(worker.morale, 56.0), "dividend should add six morale to worker %d" % worker_id, failures)
		_check(_approximately(worker.stress, 24.0), "dividend should remove six stress from worker %d" % worker_id, failures)
		_check(_approximately(worker.fatigue, 24.0), "dividend should remove six fatigue from worker %d" % worker_id, failures)
		_check(_approximately(worker.manager_trust, 56.0), "dividend should add six trust to worker %d" % worker_id, failures)
		_check(_approximately(worker.grievance, 24.0), "dividend should remove six grievance from worker %d" % worker_id, failures)
		_check_worker_effect(_effect_for_worker(result, worker_id), {
			"career_xp": 0,
			"morale": 6.0,
			"stress": -6.0,
			"fatigue": -6.0,
			"manager_trust": 6.0,
			"grievance": -6.0,
		}, "dividend worker %d" % worker_id, failures)
	_check(simulation.workers[4].to_save_data() == applicant_states[4], "dividend should not mutate applicant four", failures)
	_check(simulation.workers[5].to_save_data() == applicant_states[5], "dividend should not mutate applicant five", failures)
	_check(_approximately(simulation.solidarity, 30.0), "dividend should add ten solidarity", failures)
	_check(_approximately(simulation.executive_confidence, 44.0), "dividend should cost six farmer favor", failures)
	_check(_approximately(simulation.compliance, 70.0), "dividend should leave compliance unchanged", failures)
	_check(simulation.quota_target == 19, "dividend should lower quota by one", failures)
	_check(int(simulation.credit_choice_counts.get(&"shared_scoop", -1)) == 1, "dividend should advance shared leadership history", failures)


func _test_harvest_forecast(failures: Array[String]) -> void:
	var simulation := _review_fixture(7401, 0)
	var revenue_before := simulation.revenue_cents
	var applicant_states := {
		4: simulation.workers[4].to_save_data(),
		5: simulation.workers[5].to_save_data(),
	}
	var result := simulation.apply_senior_quarter_policy(&"harvest_forecast")
	_check(bool(result.get("accepted", false)), "harvest forecast should be accepted without discretionary fund", failures)
	_check(int(result.get("cost_cents", -1)) == 0, "harvest forecast should have no cost", failures)
	_check(int(result.get("fund_delta_cents", 0)) == 2400, "forecast receipt should disclose $24 booked revenue", failures)
	_check(simulation.revenue_cents == revenue_before + 2400, "forecast should book exactly $24 revenue", failures)
	_check(int(result.get("workers_affected", -1)) == 4, "forecast should affect employed hens only", failures)
	for worker_id in 4:
		var worker := simulation.workers[worker_id]
		_check(_approximately(worker.stress, 34.0), "forecast should add four stress to worker %d" % worker_id, failures)
		_check(_approximately(worker.manager_trust, 45.0), "forecast should remove five trust from worker %d" % worker_id, failures)
		_check(_approximately(worker.grievance, 36.0), "forecast should add six grievance to worker %d" % worker_id, failures)
		_check_worker_effect(_effect_for_worker(result, worker_id), {
			"career_xp": 0,
			"morale": 0.0,
			"stress": 4.0,
			"fatigue": 0.0,
			"manager_trust": -5.0,
			"grievance": 6.0,
		}, "forecast worker %d" % worker_id, failures)
	_check(simulation.workers[4].to_save_data() == applicant_states[4], "forecast should not mutate applicant four", failures)
	_check(simulation.workers[5].to_save_data() == applicant_states[5], "forecast should not mutate applicant five", failures)
	_check(_approximately(simulation.executive_confidence, 58.0), "forecast should add eight farmer favor", failures)
	_check(_approximately(simulation.compliance, 65.0), "forecast should remove five compliance", failures)
	_check(_approximately(simulation.solidarity, 20.0), "forecast should leave solidarity unchanged", failures)
	_check(simulation.quota_target == 23, "forecast should raise quota by three", failures)
	_check(int(simulation.credit_choice_counts.get(&"management_innovation", -1)) == 1, "forecast should advance management leadership history", failures)


func _test_annual_transition(failures: Array[String]) -> void:
	var passed := _review_fixture(7501, 0)
	var passed_revenue := passed.revenue_cents
	var passed_workers := _worker_states(passed)
	var passed_result := passed.apply_senior_year_transition(true)
	_check(bool(passed_result.get("accepted", false)), "passed annual transition should be accepted", failures)
	_check(bool(passed_result.get("previous_year_passed", false)), "passed receipt should preserve its result", failures)
	_check(int(passed_result.get("quota_delta", 0)) == 1 and passed.quota_target == 21, "passed year should add one baseline quota", failures)
	_check(_approximately(float(passed_result.get("farmer_favor_delta", -1.0)), 0.0), "passed year should not change farmer favor", failures)
	_check(_approximately(passed.executive_confidence, 50.0), "passed year should preserve farmer favor", failures)
	_check(passed.revenue_cents == passed_revenue, "passed transition should not change fund", failures)
	_check(_worker_states(passed) == passed_workers, "passed transition should not mutate workers", failures)

	var failed := _review_fixture(7502, 0)
	var failed_revenue := failed.revenue_cents
	var failed_workers := _worker_states(failed)
	var failed_result := failed.apply_senior_year_transition(false)
	_check(bool(failed_result.get("accepted", false)), "failed annual transition consequence should be accepted", failures)
	_check(not bool(failed_result.get("previous_year_passed", true)), "failed receipt should preserve its result", failures)
	_check(int(failed_result.get("quota_delta", 0)) == 2 and failed.quota_target == 22, "failed year should add two baseline quota", failures)
	_check(_approximately(float(failed_result.get("farmer_favor_delta", 0.0)), -5.0), "failed year should remove five farmer favor", failures)
	_check(_approximately(failed.executive_confidence, 45.0), "failed year should leave exact farmer favor", failures)
	_check(failed.revenue_cents == failed_revenue, "failed transition should not change fund", failures)
	_check(_worker_states(failed) == failed_workers, "failed transition should not mutate workers", failures)


func _review_fixture(seed: int, discretionary_cents: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 4)
	simulation.day = 9
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.quota_target = 20
	simulation.executive_confidence = 50.0
	simulation.compliance = 70.0
	simulation.solidarity = 20.0
	for worker in simulation.workers:
		worker.career_xp = 0
		worker.morale = 50.0
		worker.stress = 30.0
		worker.fatigue = 30.0
		worker.manager_trust = 50.0
		worker.grievance = 30.0
	simulation.revenue_cents = (
		simulation.current_daily_operating_cost_cents()
		+ simulation.wage_arrears_cents
		+ discretionary_cents
	)
	return simulation


func _worker_states(simulation: DepartmentSimulation) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for worker in simulation.workers:
		result.append(worker.to_save_data())
	return result


func _effect_for_worker(result: Dictionary, worker_id: int) -> Dictionary:
	for effect_value in result.get("worker_effects", []):
		var effect := effect_value as Dictionary
		if int(effect.get("worker_id", -1)) == worker_id:
			return effect
	return {}


func _check_worker_effect(
	actual: Dictionary,
	expected: Dictionary,
	label: String,
	failures: Array[String],
) -> void:
	_check(not actual.is_empty(), "%s receipt should exist" % label, failures)
	for key in expected:
		_check(
			_approximately(float(actual.get(key, 9999.0)), float(expected[key])),
			"%s receipt should report %s=%s" % [label, key, expected[key]],
			failures,
		)


func _expect_rejected_atomic(
	simulation: DepartmentSimulation,
	action: Callable,
	label: String,
	failures: Array[String],
) -> void:
	var before := simulation.export_save_state().duplicate(true)
	var result: Dictionary = action.call()
	_check(not bool(result.get("accepted", false)), "%s should be rejected" % label, failures)
	_check(not String(result.get("reason", "")).is_empty(), "%s should explain its rejection" % label, failures)
	_check(simulation.export_save_state() == before, "%s should preserve complete authoritative state" % label, failures)


func _approximately(left: float, right: float) -> bool:
	return absf(left - right) < 0.001


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
