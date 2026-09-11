extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(31_070, 4)
	simulation.day = 2
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 20_000
	var base_capacity := simulation.current_claim_capacity()
	var base_fund := simulation.revenue_cents

	var onboard := simulation.onboard_intern(&"lottie_ledger")
	_check(bool(onboard.get("accepted", false)), "simulation should accept a valid intern filing", failures)
	_check(
		simulation.revenue_cents == base_fund - InternshipProgramState.ONBOARDING_COST_CENTS,
		"onboarding should debit the authoritative Feed Fund once",
		failures,
	)
	_check(
		simulation.current_claim_capacity() == base_capacity + 1,
		"guided shadow should affect authoritative live-file capacity",
		failures,
	)

	var assignment := simulation.assign_intern(&"lottie_ledger", &"stretch_project")
	_check(bool(assignment.get("accepted", false)), "simulation should file an intern stretch assignment", failures)
	_check(
		simulation.current_claim_capacity() == base_capacity + 2,
		"stretch work should replace, not stack with, the guided capacity effect",
		failures,
	)
	var snapshot := simulation.snapshot()
	var internship := snapshot.get("internship_program", {}) as Dictionary
	_check(int(internship.get("active_count", 0)) == 1, "main snapshot should publish active intern count", failures)
	_check(
		int((internship.get("effects", {}) as Dictionary).get("crack_basis_points", 0)) == 100,
		"main snapshot should disclose stretch-project quality risk",
		failures,
	)

	var save_data := _json_round_trip(simulation.export_save_state())
	var restored := DepartmentSimulation.new(31_071, 4)
	_check(restored.restore_save_state(save_data), "schema v28 should restore internship state", failures)
	_check(
		restored.current_claim_capacity() == base_capacity + 2,
		"restored simulation should retain intern effects",
		failures,
	)
	_check(
		int(restored.internship_program_snapshot().get("active_count", 0)) == 1,
		"restored program should retain its active cohort",
		failures,
	)
	var internship_state := simulation.get("_internship_program") as InternshipProgramState
	internship_state.complete_shift(2)
	internship_state.complete_shift(3)
	internship_state.complete_shift(4)
	simulation.day = 5
	var operating_before_fellow := simulation.current_daily_operating_cost_cents()
	var reserve_before_fellow := simulation.protected_reserve_cents()
	var fund_before_fellow := simulation.revenue_cents
	var fellowship := simulation.resolve_intern_review(
		&"lottie_ledger",
		&"paid_fellowship",
	)
	_check(bool(fellowship.get("accepted", false)), "review should authorize an affordable paid fellowship", failures)
	_check(
		simulation.revenue_cents == fund_before_fellow - 800
		and simulation.current_daily_fellow_payroll_cents() == 200,
		"fellowship should debit its filing once and create $2 daily junior payroll",
		failures,
	)
	_check(
		simulation.current_daily_operating_cost_cents() == operating_before_fellow + 200
		and simulation.protected_reserve_cents() == reserve_before_fellow + 200,
		"junior payroll should immediately enter operating cost and protected reserves",
		failures,
	)
	var fellow_costs := (
		simulation.economic_briefing_snapshot().get("costs", {}) as Dictionary
	)
	_check(
		int(fellow_costs.get("fellow_payroll_cents", 0)) == 200,
		"Economic Briefing should itemize junior payroll",
		failures,
	)
	simulation.call("_prepare_morning_directive")
	_check(
		simulation.select_directive(&"shell_assurance"),
		"fellowship settlement fixture should enter a running shift",
		failures,
	)
	simulation.revenue_cents = simulation.current_daily_operating_cost_cents()
	var fellow_report := _close_on_next_tick(simulation)
	_check(
		int(fellow_report.get("fellow_payroll_cents", -1)) == 200
		and int(fellow_report.get("payroll_due_cents", -1))
			== int(fellow_report.get("payroll_cents", -2)),
		"closing should itemize and settle fellow payroll inside the combined wage liability",
		failures,
	)
	_check(
		int(fellow_report.get("wage_arrears_cents", -1)) == 0,
		"a fully reserved fellow wage should close without arrears",
		failures,
	)
	var reserve_guard := DepartmentSimulation.new(31_074, 4)
	reserve_guard.day = 2
	reserve_guard.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	reserve_guard.pending_decision.clear()
	reserve_guard.revenue_cents = (
		reserve_guard.current_daily_operating_cost_cents()
		+ InternshipProgramState.ONBOARDING_COST_CENTS
		- 1
	)
	_check(
		not bool(reserve_guard.onboard_intern(&"chip_chirper").get("accepted", true)),
		"intern onboarding should not spend Feed Fund reserved for current operations",
		failures,
	)
	var legacy_v27 := _json_round_trip(DepartmentSimulation.new(31_072, 4).export_save_state())
	legacy_v27["state_version"] = 27
	legacy_v27.erase("internship_program_state")
	var migrated := DepartmentSimulation.new(31_073, 4)
	_check(migrated.restore_save_state(legacy_v27), "schema v27 should migrate to a neutral intern cohort", failures)
	_check(
		int(migrated.internship_program_snapshot().get("active_count", -1)) == 0,
		"legacy careers should not receive fabricated intern labor",
		failures,
	)

	if not failures.is_empty():
		for failure in failures:
			push_error("INTERNSHIP_PROGRAM_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("INTERNSHIP_PROGRAM_INTEGRATION_TEST_PASSED economy=authoritative fellowship=recurring-payroll reserve=protected snapshot=disclosed save=v28")
	quit(0)


func _json_round_trip(value: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(value)) as Dictionary


func _close_on_next_tick(simulation: DepartmentSimulation) -> Dictionary:
	var report_box := {"report": {}}
	simulation.workday_completed.connect(
		func(report: Dictionary) -> void:
			report_box["report"] = report.duplicate(true),
		CONNECT_ONE_SHOT,
	)
	for worker in simulation.workers:
		simulation.set_worker_at_workstation(worker.id, false)
	simulation.incidents_resolved_today = DepartmentSimulation.INCIDENT_MINUTES.size()
	simulation.set("_incident_slot", DepartmentSimulation.INCIDENT_MINUTES.size())
	simulation.minute_of_day = (
		DepartmentSimulation.SHIFT_END_MINUTE
		- DepartmentSimulation.MINUTES_PER_TICK
	)
	simulation.advance_tick()
	return report_box.get("report", {}) as Dictionary


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
