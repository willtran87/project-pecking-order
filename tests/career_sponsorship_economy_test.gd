extends SceneTree

const DepartmentSimulationScript := preload("res://core/simulation/department_simulation.gd")
const ChickenStateScript := preload("res://core/simulation/chicken_state.gd")
const ClaimStateScript := preload("res://core/simulation/claim_state.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_test_preflight_and_atomic_guards(failures)
	_test_exact_cost_training_and_accreditation(failures)
	_test_absent_hen_keeps_training_pending(failures)
	_test_secondary_affinity_and_primary_auto_dispatch(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("CAREER_SPONSORSHIP_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAREER_SPONSORSHIP_ECONOMY_TEST_PASSED review=atomic cost=1200 training=0.85 secondary=specialist wage=+100 auto=primary")
	quit(0)


func _test_preflight_and_atomic_guards(failures: Array[String]) -> void:
	var simulation := DepartmentSimulationScript.new(7101, 4)
	simulation.workers[0].career_xp = 18
	_check_rejected_atomically(simulation, 0, &"predator_loss", "outside review", failures)

	simulation.shift_phase = DepartmentSimulationScript.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = _protected_fund_cents(simulation, 1199)
	_check_rejected_atomically(simulation, 0, &"predator_loss", "underfunded", failures)
	_check_rejected_atomically(simulation, -1, &"predator_loss", "unknown hen", failures)
	_check_rejected_atomically(simulation, 0, &"unsupported_lane", "unsupported lane", failures)
	_check_rejected_atomically(simulation, 0, simulation.workers[0].specialty, "primary lane", failures)
	_check_rejected_atomically(simulation, 1, &"predator_loss", "junior hen", failures)

	simulation.workers[4].career_xp = 18
	_check_rejected_atomically(simulation, 4, &"nest_damage", "applicant hen", failures)
	simulation.workers[0].secondary_specialty = &"nest_damage"
	_check_rejected_atomically(simulation, 0, &"predator_loss", "already cross-accredited", failures)
	simulation.workers[0].secondary_specialty = &""
	simulation.workers[0].cross_training_target = &"nest_damage"
	_check_rejected_atomically(simulation, 0, &"predator_loss", "training already pending", failures)


func _test_exact_cost_training_and_accreditation(failures: Array[String]) -> void:
	var simulation := DepartmentSimulationScript.new(7201, 4)
	var worker := simulation.workers[0]
	worker.career_xp = 18
	simulation.shift_phase = DepartmentSimulationScript.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = _protected_fund_cents(simulation, 1200)
	var fund_before := simulation.revenue_cents
	var wage_before := worker.daily_wage_cents()
	var preflight := simulation.career_sponsorship_preflight(0, &"predator_loss")
	_check(bool(preflight.get("available", false)), "valid review sponsorship should pass preflight", failures)
	_check(int(preflight.get("cost_cents", -1)) == 1200, "preflight should expose the exact $12.00 cost", failures)
	_check(int(preflight.get("accredited_daily_wage_cents", -1)) == wage_before + 100, "preflight should expose the permanent $1 wage premium", failures)

	var accepted := simulation.authorize_career_sponsorship(0, &"predator_loss")
	_check(bool(accepted.get("accepted", false)), "valid sponsorship should authorize", failures)
	_check(int(accepted.get("fund_delta_cents", 0)) == -1200, "authorization receipt should record exactly -$12.00", failures)
	_check(simulation.revenue_cents == fund_before - 1200, "authorization should deduct exactly $12.00", failures)
	_check(simulation.spendable_fund_cents() == 0, "authorization should preserve every protected operating cent", failures)
	_check(worker.cross_training_target == &"predator_loss" and worker.secondary_specialty == &"", "authorization should schedule training without accrediting early", failures)
	_check(worker.daily_wage_cents() == wage_before, "pending training should not raise wages before accreditation", failures)
	var review_worker := _worker_snapshot(simulation.snapshot(), 0)
	_check(bool(review_worker.get("cross_training_pending", false)), "review snapshot should expose pending cross-training", failures)
	_check(not bool(review_worker.get("cross_training_active", true)), "review snapshot should not call training active", failures)
	_check(StringName(review_worker.get("cross_training_target", &"")) == &"predator_loss", "review snapshot should expose the exact target lane", failures)
	_check(int(simulation.snapshot().get("career_sponsorship_cost_cents", -1)) == 1200, "simulation snapshot should publish the sponsorship cost", failures)
	_check(bool(simulation.snapshot().get("career_sponsorship_planning_open", false)), "simulation snapshot should identify review planning", failures)
	_check_rejected_atomically(simulation, 0, &"nest_damage", "second sponsorship", failures)

	_check(simulation.begin_next_shift_briefing(), "accepted fixture should open its next shift briefing", failures)
	_check(simulation.select_directive(&"shell_assurance"), "accepted fixture should start its training shift", failures)
	var active_worker := _worker_snapshot(simulation.snapshot(), 0)
	_check(bool(active_worker.get("cross_training_active", false)), "running snapshot should expose active training", failures)
	_check(_approximately(float(active_worker.get("cross_training_work_multiplier", 0.0)), 0.85), "running snapshot should expose the 0.85 personal multiplier", failures)
	simulation.set_worker_at_workstation(0, true)
	simulation.advance_tick()
	simulation.advance_tick()
	_check(worker.cross_training_worked_this_shift, "a real workstation claim-progress tick should record training participation", failures)

	var baseline := DepartmentSimulationScript.new(7202, 4)
	var training := DepartmentSimulationScript.new(7202, 4)
	for fixture in [baseline, training]:
		fixture.workers[0].career_xp = 18
		_check(fixture.select_directive(&"shell_assurance"), "speed fixture should begin its shift", failures)
		fixture.set_worker_at_workstation(0, true)
	_check(training.workers[0].begin_cross_training(&"predator_loss"), "speed fixture should schedule a valid target", failures)
	baseline.advance_tick()
	training.advance_tick()
	baseline.advance_tick()
	training.advance_tick()
	var baseline_progress := baseline.workers[0].work_progress
	var training_progress := training.workers[0].work_progress
	_check(baseline_progress > 0.0, "baseline speed fixture should perform live peckwork", failures)
	_check(_approximately(training_progress / baseline_progress, 0.85), "training should reduce only that hen's live work speed by exactly 15%", failures)

	var reports: Array[Dictionary] = []
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		reports.append(report.duplicate(true))
	)
	_complete_shift_to_review(simulation, failures)
	_check(worker.secondary_specialty == &"predator_loss" and worker.cross_training_target == &"", "one completed worked shift should permanently accredit the target", failures)
	_check(worker.daily_wage_cents() == wage_before + 100, "accreditation should add exactly $1.00 to daily wage", failures)
	_check(reports.size() == 1, "training shift should emit one closing report", failures)
	if reports.size() == 1:
		var completions := reports[0].get("career_sponsorships_completed", []) as Array
		_check(completions.size() == 1, "closing report should expose one accreditation receipt", failures)
		if completions.size() == 1:
			var receipt := completions[0] as Dictionary
			_check(StringName(receipt.get("secondary_specialty", &"")) == &"predator_loss", "accreditation receipt should retain the target lane", failures)
			_check(int(receipt.get("daily_wage_delta_cents", 0)) == 100, "accreditation receipt should retain the exact wage delta", failures)


func _test_absent_hen_keeps_training_pending(failures: Array[String]) -> void:
	var simulation := DepartmentSimulationScript.new(7251, 4)
	var worker := simulation.workers[0]
	worker.career_xp = 18
	simulation.shift_phase = DepartmentSimulationScript.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = _protected_fund_cents(simulation, 5000)
	_check(bool(simulation.authorize_career_sponsorship(0, &"predator_loss").get("accepted", false)), "absence fixture should authorize", failures)
	_check(simulation.begin_next_shift_briefing(), "absence fixture should open briefing", failures)
	_check(simulation.select_directive(&"shell_assurance"), "absence fixture should begin its planned training shift", failures)
	var reports: Array[Dictionary] = []
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		reports.append(report.duplicate(true))
	)
	_complete_shift_to_review(simulation, failures)
	_check(worker.secondary_specialty == &"" and worker.cross_training_target == &"predator_loss", "a hen with no claim-progress tick should remain pending", failures)
	_check(not worker.cross_training_worked_this_shift, "absence should not fabricate training participation", failures)
	_check(worker.daily_wage_cents() == 500, "absence should not award the accreditation wage premium", failures)
	if reports.size() >= 1:
		_check((reports[0].get("career_sponsorships_completed", []) as Array).is_empty(), "absent shift report should not contain an accreditation receipt", failures)

	_resolve_free_incident(simulation, failures)
	_check(simulation.begin_next_shift_briefing(), "pending training should carry into the next briefing", failures)
	_check(simulation.select_directive(&"shell_assurance"), "pending training should carry into the next running shift", failures)
	simulation.set_worker_at_workstation(0, true)
	simulation.advance_tick()
	simulation.advance_tick()
	_check(worker.cross_training_worked_this_shift, "later claim progress should satisfy the worked-shift invariant", failures)
	_complete_shift_to_review(simulation, failures)
	_check(worker.secondary_specialty == &"predator_loss" and worker.cross_training_target == &"", "the first actually worked shift should complete delayed accreditation", failures)
	_check(worker.daily_wage_cents() == 600, "delayed accreditation should add the wage premium exactly once", failures)


func _test_secondary_affinity_and_primary_auto_dispatch(failures: Array[String]) -> void:
	var simulation := DepartmentSimulationScript.new(7301, 4)
	var worker := simulation.workers[0]
	worker.career_xp = 18
	worker.secondary_specialty = &"predator_loss"
	worker.current_claim = ClaimStateScript.new(
		9001, &"predator_loss", "SECONDARY TEST", 1.0, 500, 0.0, 0, 180, 180
	)
	_check(_approximately(simulation._claim_speed_factor(worker), DepartmentSimulationScript.SPECIALTY_SPEED_MULTIPLIER), "manual secondary routing should receive the existing specialist speed modifier", failures)
	_check(_approximately(simulation._claim_affinity_crack_modifier(worker), DepartmentSimulationScript.SPECIALTY_CRACK_MODIFIER), "manual secondary routing should receive the existing specialist crack modifier", failures)
	worker.current_claim = ClaimStateScript.new(
		9002, &"nest_damage", "MISMATCH TEST", 1.0, 500, 0.0, 0, 180, 180
	)
	_check(_approximately(simulation._claim_speed_factor(worker), DepartmentSimulationScript.MISMATCH_SPEED_MULTIPLIER), "a third lane should retain the mismatch speed modifier", failures)
	_check(_approximately(simulation._claim_affinity_crack_modifier(worker), DepartmentSimulationScript.MISMATCH_CRACK_MODIFIER), "a third lane should retain the mismatch crack modifier", failures)
	worker.current_claim = null
	worker.assigned_lane = DepartmentSimulationScript.AUTO_ASSIGNMENT
	var auto_claim := simulation._take_claim_for_worker(worker)
	_check(auto_claim != null and auto_claim.lane == worker.specialty, "AUTO dispatch should continue preferring the primary specialty over the secondary", failures)


func _complete_shift_to_review(simulation: DepartmentSimulation, failures: Array[String]) -> void:
	var safety := 0
	while simulation.shift_phase != DepartmentSimulationScript.ShiftPhase.REVIEW and safety < 8:
		match simulation.shift_phase:
			DepartmentSimulationScript.ShiftPhase.RUNNING:
				simulation.minute_of_day = DepartmentSimulationScript.SHIFT_END_MINUTE - DepartmentSimulationScript.MINUTES_PER_TICK
				simulation.advance_tick()
			DepartmentSimulationScript.ShiftPhase.AWAITING_INCIDENT:
				_resolve_free_incident(simulation, failures)
			_:
				failures.append("training fixture entered an unexpected phase")
				return
		safety += 1
	_check(simulation.shift_phase == DepartmentSimulationScript.ShiftPhase.REVIEW, "training fixture should reach review", failures)


func _resolve_free_incident(simulation: DepartmentSimulation, failures: Array[String]) -> void:
	var decision: Dictionary = simulation.pending_decision_snapshot()
	for option_value in decision.get("options", []):
		var option := option_value as Dictionary
		if int(option.get("cost_cents", 0)) == 0:
			_check(simulation.resolve_decision(int(decision.get("serial", -1)), StringName(option.get("id", &""))), "training fixture should resolve its free incident", failures)
			return
	failures.append("training fixture should expose a free incident response")


func _check_rejected_atomically(simulation: DepartmentSimulation, worker_id: int, lane: StringName, label: String, failures: Array[String]) -> void:
	var before := JSON.stringify(simulation.export_save_state())
	var result: Dictionary = simulation.authorize_career_sponsorship(worker_id, lane)
	var after := JSON.stringify(simulation.export_save_state())
	_check(not bool(result.get("accepted", false)), "%s should be rejected" % label, failures)
	_check(not String(result.get("reason", "")).is_empty(), "%s should explain its rejection" % label, failures)
	_check(after == before, "%s rejection should be fully atomic" % label, failures)


func _protected_fund_cents(simulation: DepartmentSimulation, discretionary_cents: int) -> int:
	return simulation.current_daily_operating_cost_cents() + simulation.wage_arrears_cents + discretionary_cents


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
