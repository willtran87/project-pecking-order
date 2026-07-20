extends SceneTree

const ROOSTER := DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID

func _init() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(25001, 6)
	simulation.day = 12
	simulation.owned_facilities[ROOSTER] = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	# Export normalization materializes every already-funded post, matching admin fixtures and migration.
	simulation.export_save_state()
	var operations := simulation.operations_snapshot()
	var roster := operations.get("manager_roster", []) as Array
	_check(roster.size() == 4, "tier three should fund four named management posts", failures)
	_check(int((operations.get("management_density", {}) as Dictionary).get("excess_managers", -1)) == 2, "four managers over six hens should expose two excess management equivalents", failures)
	_check(int((operations.get("management_reports", {}) as Dictionary).get("today", -1)) == 0, "roosters should not invent reports before the shift boundary", failures)
	_check(not bool((operations.get("management_reports", {}) as Dictionary).get("produces_eggs", true)), "management must never produce eggs", failures)
	_check(simulation.current_daily_supervisor_payroll_cents() == 1200, "funded posts should preserve the authored tier-three payroll", failures)
	_check((operations.get("manager_candidates", []) as Array).size() == 6, "the screened slate should expose all six management archetypes", failures)
	simulation.revenue_cents = 100_000
	var recruit := simulation.recruit_manager(&"byte_automation")
	_check(bool(recruit.get("accepted", false)), "the player should be able to appoint an alternate manager", failures)
	_check(int(recruit.get("cost_cents", 0)) == 7000, "appointments should charge the authored signing cost", failures)
	_check(simulation.manager_roster.size() == 4 and StringName(String(simulation.manager_roster[3].get("candidate_id", ""))) == &"byte_automation", "an appointment should replace the newest post without inflating headcount", failures)
	_check(simulation.current_daily_supervisor_payroll_cents() == 1200, "lateral appointment should preserve the post's authorized base salary", failures)

	var lead_id := StringName(String((roster[0] as Dictionary).get("id", "")))
	var quality_id := StringName(String((roster[1] as Dictionary).get("id", "")))
	_check(bool(simulation.set_manager_assignment(lead_id, &"whole_flock").get("accepted", false)), "planning should accept a manager assignment", failures)
	_check(bool(simulation.set_manager_posture(lead_id, &"chase_quota").get("accepted", false)), "planning should accept a manager posture", failures)
	var first_worker := simulation.workers[0]
	var stress_before := first_worker.stress
	var grievance_before := first_worker.grievance
	simulation.call("_apply_manager_posture_relationships")
	_check(is_equal_approx(first_worker.stress - stress_before, 2.0), "quota posture should add exact target stress", failures)
	_check(is_equal_approx(first_worker.grievance - grievance_before, 1.5), "quota posture should add exact target grievance", failures)
	_check(simulation.management_reports_today == 4 and simulation.management_reports_total == 4, "every manager should file one report at the shift boundary", failures)

	_check(bool(simulation.set_manager_assignment(quality_id, &"whole_flock").get("accepted", false)), "a second manager should accept a shared flock assignment", failures)
	_check(bool(simulation.set_manager_posture(quality_id, &"protect_quality").get("accepted", false)), "a second manager should accept a quality posture", failures)
	var combined := simulation.call("_manager_effect_for_worker", first_worker) as Dictionary
	_check(int(combined.get("conflicts", 0)) == 1, "quota and quality directives over the same hen should conflict", failures)
	_check(is_equal_approx(float(combined.get("work_multiplier", 0.0)), 0.975), "conflict and density drag should conservatively compose with both postures", failures)
	_check(is_equal_approx(float(combined.get("crack_modifier", 1.0)), -0.01), "quota and shell protection should net their authored crack modifiers", failures)

	var payroll_before_promotion := simulation.current_daily_supervisor_payroll_cents()
	for _index in 9:
		simulation.call("_settle_manager_careers", simulation.day, true)
	_check(int(simulation.manager_roster[0].get("rank", 0)) >= 1, "successful reports should promote a manager by influence", failures)
	_check(simulation.current_daily_supervisor_payroll_cents() > payroll_before_promotion, "promotion should increase next-shift supervisor payroll", failures)

	var state := JSON.parse_string(JSON.stringify(simulation.export_save_state())) as Dictionary
	var restored := DepartmentSimulation.new(25002, 6)
	_check(restored.restore_save_state(state), "manager roster checkpoint should round trip", failures)
	_check(restored.operations_snapshot() == simulation.operations_snapshot(), "manager authority and operations projection should restore exactly", failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("MANAGER_ROSTER_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MANAGER_ROSTER_ECONOMY_TEST_PASSED roster=named assignments=targeted postures=causal density=drag conflicts=visible careers=promote payroll=escalates persistence=exact")
	quit(0)

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
