extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_test_fresh_roster_and_applicant_isolation(failures)
	_test_exact_costs_reserves_and_atomic_guards(failures)
	_test_release_cooldown_minimum_and_vacant_desk(failures)
	_test_capacity_hire_increases_throughput(failures)
	_test_wage_arrears_and_active_flock_consequences(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("STAFFING_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("STAFFING_ECONOMY_TEST_PASSED roster=fixed-six applicants=isolated costs=exact reserves=guarded staffing=causal arrears=consequential")
	quit(0)


func _test_fresh_roster_and_applicant_isolation(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(4101, 4)
	_check(simulation.workers.size() == 6, "a four-hen office should retain the fixed six-worker directory", failures)
	_check(simulation.active_worker_count() == 4, "a four-hen office should employ exactly four workers", failures)
	_check(simulation.office_capacity == 4, "the fresh office capacity should match its four active desks", failures)
	_check(simulation.quota_target == 16, "four active hens should start with quota 16", failures)
	_check(simulation.current_daily_payroll_cents() == 1600, "four junior hens should reserve $16 payroll", failures)
	_check(simulation.current_daily_feed_cost_cents() == 1400, "feed should be $6 base plus $2 per active hen", failures)
	_check(simulation.current_daily_facility_cost_cents() == 0, "the original four desks should have no facility surcharge", failures)
	_check(simulation.current_daily_operating_cost_cents() == 3000, "fresh four-hen operating obligations should total $30", failures)
	_check(simulation.spendable_fund_cents() == 2000, "the $50 opening fund should expose only $20 after reserves", failures)

	var catalog := simulation.staffing_catalog()
	_check(catalog.size() == 6, "staffing catalog should expose all six stable worker identities", failures)
	for worker_id in simulation.workers.size():
		var worker := simulation.workers[worker_id]
		var row := _catalog_row(catalog, worker_id)
		_check(not row.is_empty(), "staffing catalog should contain worker %d" % worker_id, failures)
		if worker_id < 4:
			_check(worker.employed, "worker %d should begin employed" % worker_id, failures)
			_check(worker.employment_status() == &"employed", "worker %d should have employed status" % worker_id, failures)
			_check(worker.desk_index == worker_id, "worker %d should retain her original desk" % worker_id, failures)
			_check(not bool(row.get("can_release", true)), "worker %d should not be releasable before REVIEW" % worker_id, failures)
		else:
			_check(not worker.employed, "worker %d should begin as an applicant" % worker_id, failures)
			_check(worker.employment_status() == &"applicant", "worker %d should have applicant status" % worker_id, failures)
			_check(worker.desk_index == -1, "applicant %d should not own a desk" % worker_id, failures)
			_check(int(row.get("hire_cost_cents", -1)) == 1200 + 100 * worker_id, "applicant %d should expose the exact ID-based hire cost" % worker_id, failures)

	# Extreme applicant relationship values make accidental inclusion in flock-wide
	# policy, celebration, and review averages immediately visible.
	for applicant_id in [4, 5]:
		simulation.workers[applicant_id].manager_trust = 0.0
		simulation.workers[applicant_id].grievance = 100.0
	var applicant_before_directive := simulation.workers[4].to_save_data()
	_check(simulation.select_directive(&"shell_assurance"), "applicant-isolation fixture should start its shift", failures)
	_check(simulation.workers[4].to_save_data() == applicant_before_directive, "morning policy must not mutate an applicant", failures)

	simulation.set_worker_at_workstation(4, true)
	_check(not simulation.is_worker_at_workstation(4), "an applicant cannot be seated at a workstation", failures)
	_check(not simulation.set_worker_assignment(4, &"appeals"), "an applicant cannot receive peckwork routing", failures)
	_expect_rejected_atomic(
		simulation,
		func() -> Dictionary: return simulation.perform_personnel_action(4, &"share_credit"),
		"an applicant cannot receive the flock check-in",
		failures
	)
	var applicant_before_party := simulation.workers[4].to_save_data()
	var active_morale_before := simulation.workers[0].morale
	_check(simulation.fund_feed_party(), "the opening spendable reserve should fund one $20 Feed Party", failures)
	_check(simulation.workers[0].morale > active_morale_before, "Feed Party should benefit an active hen", failures)
	_check(simulation.workers[4].to_save_data() == applicant_before_party, "Feed Party must not benefit an applicant", failures)

	var report := _complete_running_shift(simulation, failures)
	_check(not report.is_empty(), "applicant-isolation fixture should complete its shift", failures)
	var active_trust_total := 0.0
	var active_grievance_total := 0.0
	for worker in simulation.workers:
		if not worker.employed:
			continue
		active_trust_total += worker.manager_trust
		active_grievance_total += worker.grievance
	var expected_trust := roundi(active_trust_total / float(simulation.active_worker_count()))
	var expected_grievance := roundi(active_grievance_total / float(simulation.active_worker_count()))
	_check(int(report.get("average_manager_trust", -1)) == expected_trust, "review trust should average active hens only", failures)
	_check(int(report.get("average_grievance", -1)) == expected_grievance, "review grievance should average active hens only", failures)


func _test_exact_costs_reserves_and_atomic_guards(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(4202, 4)
	_expect_rejected_atomic(
		simulation,
		func() -> Dictionary: return simulation.purchase_staff_capacity(),
		"capacity expansion should be REVIEW-only",
		failures
	)
	_expect_rejected_atomic(
		simulation,
		func() -> Dictionary: return simulation.hire_worker(4),
		"hiring should be REVIEW-only",
		failures
	)
	_expect_rejected_atomic(
		simulation,
		func() -> Dictionary: return simulation.release_worker(0),
		"release should be REVIEW-only",
		failures
	)

	var applicant_before := simulation.workers[4].to_save_data()
	var report := _complete_shift(simulation, failures)
	_check(not report.is_empty(), "cost fixture should enter REVIEW", failures)
	_check(simulation.workers[4].to_save_data() == applicant_before, "an idle applicant should survive a full shift unchanged", failures)
	_reset_career_xp(simulation)

	# Set a deterministic planning balance so every cent in the reserve calculation
	# is independently observable.
	simulation.revenue_cents = 10000
	_check(simulation.spendable_fund_cents() == 7000, "$100 should expose $70 after four-hen obligations", failures)
	var capacity_result := simulation.purchase_staff_capacity()
	_check(bool(capacity_result.get("accepted", false)), "the first capacity tier should be purchasable during REVIEW", failures)
	_check(StringName(capacity_result.get("action_id", &"")) == &"expand_capacity", "capacity result should identify its action", failures)
	_check(int(capacity_result.get("cost_cents", -1)) == 2500, "capacity four-to-five should cost exactly $25", failures)
	_check(simulation.office_capacity == 5, "first expansion should add exactly one desk", failures)
	_check(simulation.revenue_cents == 7500, "first expansion should deduct exactly $25", failures)
	_check(simulation.current_daily_facility_cost_cents() == 200, "one seat above four should reserve $2 facility cost", failures)
	_check(simulation.current_daily_operating_cost_cents() == 3200, "expanded four-hen obligations should total $32", failures)
	_check(simulation.spendable_fund_cents() == 4300, "post-expansion spendable fund should include the new facility reserve", failures)

	var hire_result := simulation.hire_worker(4)
	_check(bool(hire_result.get("accepted", false)), "capacity expansion and one hire should be allowed in the same review", failures)
	_check(StringName(hire_result.get("action_id", &"")) == &"hire_worker", "hire result should identify its action", failures)
	_check(int(hire_result.get("cost_cents", -1)) == 1600, "junior worker four should cost exactly $16 to hire", failures)
	_check(int(hire_result.get("desk_index", -1)) == 4, "first hire should occupy the only vacant desk", failures)
	_check(simulation.revenue_cents == 5900, "hire should deduct its exact $16 filing cost", failures)
	_check(simulation.active_worker_count() == 5, "accepted hire should create five active workers", failures)
	_check(simulation.current_daily_payroll_cents() == 2000, "five junior hens should reserve $20 payroll", failures)
	_check(simulation.current_daily_feed_cost_cents() == 1600, "five hens should reserve $16 feed", failures)
	_check(simulation.current_daily_facility_cost_cents() == 200, "capacity five should retain its $2 facility cost", failures)
	_check(simulation.current_daily_operating_cost_cents() == 3800, "five-hen expanded obligations should total $38", failures)
	_check(simulation.spendable_fund_cents() == 2100, "post-hire spendable fund should reserve all $38 of obligations", failures)

	_expect_rejected_atomic(
		simulation,
		func() -> Dictionary: return simulation.hire_worker(5),
		"only one hire or release is allowed per planning day",
		failures
	)
	_expect_rejected_atomic(
		simulation,
		func() -> Dictionary: return simulation.release_worker(0),
		"a same-day release cannot bypass the staffing-action cooldown",
		failures
	)
	_expect_rejected_atomic(
		simulation,
		func() -> Dictionary: return simulation.hire_worker(4),
		"an already employed worker cannot be hired twice",
		failures
	)

	# Expansion does not consume the staffing-action slot. A separate rich fixture
	# proves the exact second-tier price without coupling it to hire cooldown state.
	var expansion := DepartmentSimulation.new(4203, 4)
	_complete_shift(expansion, failures)
	_reset_career_xp(expansion)
	expansion.revenue_cents = 20000
	var first := expansion.purchase_staff_capacity()
	var second := expansion.purchase_staff_capacity()
	_check(bool(first.get("accepted", false)) and int(first.get("cost_cents", -1)) == 2500, "first rich-fixture tier should cost $25", failures)
	_check(bool(second.get("accepted", false)) and int(second.get("cost_cents", -1)) == 5500, "capacity five-to-six should cost exactly $55", failures)
	_check(expansion.office_capacity == 6, "both tiers should cap the fixed office at six", failures)
	_check(expansion.current_daily_facility_cost_cents() == 400, "six-seat office should reserve $4 facility cost", failures)
	_expect_rejected_atomic(
		expansion,
		func() -> Dictionary: return expansion.purchase_staff_capacity(),
		"fixed-six office cannot expand past capacity six",
		failures
	)


func _test_release_cooldown_minimum_and_vacant_desk(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(4303, 4)
	_complete_shift(simulation, failures)
	_reset_career_xp(simulation)
	simulation.workers[1].career_xp = 18
	simulation.revenue_cents = 10000
	_check(simulation.current_daily_payroll_cents() == 1700, "an accredited active hen should add $1 to daily wages", failures)
	var release := simulation.release_worker(1)
	_check(bool(release.get("accepted", false)), "review should allow one release above the three-hen minimum", failures)
	_check(int(release.get("cost_cents", -1)) == 1400, "accredited original worker release should cost $10 + $4 career", failures)
	_check(simulation.active_worker_count() == 3, "accepted release should leave three active hens", failures)
	_check(not simulation.workers[1].employed and simulation.workers[1].desk_index == -1, "released worker should become a deskless applicant", failures)
	_expect_rejected_atomic(
		simulation,
		func() -> Dictionary: return simulation.release_worker(2),
		"a second same-review release should be rejected",
		failures
	)

	_resolve_closing_credit(simulation, failures)
	_check(simulation.begin_next_shift_briefing(), "release fixture should open its next briefing after credit is filed", failures)
	var second_report := _complete_shift(simulation, failures)
	_check(not second_report.is_empty(), "three-hen fixture should complete the cooldown shift", failures)
	_expect_rejected_atomic(
		simulation,
		func() -> Dictionary: return simulation.release_worker(2),
		"the roster cannot fall below three even after cooldown expires",
		failures
	)

	simulation.revenue_cents = 10000
	var hire := simulation.hire_worker(4)
	_check(bool(hire.get("accepted", false)), "a rejected minimum-roster release should not consume the planning action", failures)
	_check(int(hire.get("desk_index", -1)) == 1, "hire should claim the lowest vacant desk rather than append by worker ID", failures)
	_check(simulation.workers[4].desk_index == 1, "hired worker should persist the returned desk assignment", failures)
	_check(int((_catalog_row(simulation.staffing_catalog(), 4)).get("release_cost_cents", -1)) == 1100, "first-time hired junior should expose $11 release cost", failures)


func _test_capacity_hire_increases_throughput(failures: Array[String]) -> void:
	var baseline := DepartmentSimulation.new(4404, 4)
	var staffed := DepartmentSimulation.new(4404, 4)
	var baseline_day_one := _complete_shift(baseline, failures)
	var staffed_day_one := _complete_shift(staffed, failures)
	_check(int(baseline_day_one.get("eggs", -1)) == int(staffed_day_one.get("eggs", -2)), "same-seed day-one fixtures should start identically", failures)

	staffed.revenue_cents = maxi(staffed.revenue_cents, 10000)
	var expansion := staffed.purchase_staff_capacity()
	var hire := staffed.hire_worker(4)
	_check(bool(expansion.get("accepted", false)), "causal staffing fixture should expand capacity", failures)
	_check(bool(hire.get("accepted", false)), "causal staffing fixture should hire its fifth hen", failures)
	_resolve_closing_credit(baseline, failures)
	_resolve_closing_credit(staffed, failures)
	_check(baseline.begin_next_shift_briefing(), "baseline should open day-two briefing", failures)
	_check(staffed.begin_next_shift_briefing(), "staffed office should open day-two briefing", failures)
	var baseline_day_two := _complete_shift(baseline, failures)
	var staffed_day_two := _complete_shift(staffed, failures)
	_check(int(staffed_day_two.get("active_staff_count", -1)) == 5, "staffed report should disclose five active hens", failures)
	_check(int(baseline_day_two.get("active_staff_count", -1)) == 4, "baseline report should disclose four active hens", failures)
	_check(int(staffed_day_two.get("eggs", 0)) > int(baseline_day_two.get("eggs", 0)), "an expanded and staffed office should produce more eggs under the same seed", failures)


func _test_wage_arrears_and_active_flock_consequences(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(4505, 4)
	_check(simulation.select_directive(&"shell_assurance"), "arrears fixture should start its shift", failures)
	simulation.revenue_cents = 0
	simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	# Closing-time jumps encounter both scheduled incident gates. Resolve their
	# free branches before capturing the exact pre-payroll relationship state.
	for _step in 8:
		if simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT:
			_resolve_free_incident(simulation, failures)
		if simulation.incidents_resolved_today >= DepartmentSimulation.INCIDENT_MINUTES.size():
			break
		if simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING:
			simulation.advance_tick()
	var active_before: Dictionary = {}
	var applicant_before: Dictionary = {}
	for worker in simulation.workers:
		if worker.employed:
			active_before[worker.id] = {
				"morale": worker.morale,
				"trust": worker.manager_trust,
				"grievance": worker.grievance,
			}
		else:
			applicant_before[worker.id] = worker.to_save_data()

	var report_box := {"report": {}}
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		report_box["report"] = report.duplicate(true)
	, CONNECT_ONE_SHOT)
	for _step in 4:
		if simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING:
			simulation.advance_tick()
		if simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW:
			break
	var report := report_box.get("report", {}) as Dictionary
	_check(not report.is_empty(), "arrears fixture should reach review", failures)
	_check(int(report.get("feed_cost_cents", -1)) == 1400, "closing should charge exact four-hen feed", failures)
	_check(int(report.get("facility_cost_cents", -1)) == 0, "unexpanded office should have no facility charge", failures)
	_check(int(report.get("payroll_cents", -1)) == 1600, "closing should accrue exact four-hen payroll", failures)
	_check(int(report.get("opening_wage_arrears_cents", -1)) == 0, "fresh office should begin with no arrears", failures)
	_check(int(report.get("payroll_due_cents", -1)) == 1600, "first unpaid payroll due should equal current wages", failures)
	_check(int(report.get("payroll_paid_cents", -1)) == 0, "empty Feed Fund cannot pay payroll", failures)
	_check(int(report.get("wage_arrears_cents", -1)) == 1600, "unpaid payroll must persist as $16 arrears rather than disappear", failures)
	_check(simulation.wage_arrears_cents == 1600, "authoritative simulation should retain the reported arrears", failures)
	_check(int(report.get("operating_cost_cents", -1)) == 3000, "reported current operating obligations should total $30", failures)
	_check(simulation.revenue_cents == 0, "arrears should never underflow the displayed Feed Fund", failures)
	for worker in simulation.workers:
		if worker.employed:
			var before := active_before.get(worker.id, {}) as Dictionary
			_check(is_equal_approx(worker.morale, float(before.get("morale", 0.0)) - 8.0), "arrears should reduce active worker %d morale by 8" % worker.id, failures)
			_check(is_equal_approx(worker.manager_trust, float(before.get("trust", 0.0)) - 10.0), "arrears should reduce active worker %d trust by 10" % worker.id, failures)
			_check(is_equal_approx(worker.grievance, float(before.get("grievance", 0.0)) + 14.0), "arrears should raise active worker %d grievance by 14" % worker.id, failures)
		else:
			_check(worker.to_save_data() == applicant_before.get(worker.id, {}), "arrears and review recovery must not mutate applicant %d" % worker.id, failures)

	simulation.revenue_cents = 10000
	_check(simulation.spendable_fund_cents() == 5400, "$100 should reserve $30 next operations plus $16 arrears", failures)


func _complete_shift(simulation: DepartmentSimulation, failures: Array[String]) -> Dictionary:
	if simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE:
		_check(simulation.select_directive(&"shell_assurance"), "fixture should authorize Shell Assurance", failures)
	return _complete_running_shift(simulation, failures)


func _complete_running_shift(simulation: DepartmentSimulation, failures: Array[String]) -> Dictionary:
	var report_box := {"report": {}}
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		report_box["report"] = report.duplicate(true)
	, CONNECT_ONE_SHOT)
	for worker in simulation.workers:
		simulation.set_worker_at_workstation(worker.id, worker.employed)
	for _tick in 340:
		if simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT:
			_resolve_free_incident(simulation, failures)
		elif simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING:
			simulation.advance_tick()
		elif simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW:
			break
	return report_box.get("report", {}) as Dictionary


func _resolve_free_incident(simulation: DepartmentSimulation, failures: Array[String]) -> void:
	var pending := simulation.pending_decision_snapshot()
	var serial := int(pending.get("serial", -1))
	for option_value in pending.get("options", []):
		var option := option_value as Dictionary
		if int(option.get("cost_cents", 0)) != 0:
			continue
		_check(simulation.resolve_decision(serial, StringName(option.get("id", &""))), "fixture should resolve the free incident branch", failures)
		return
	_check(false, "every staffing fixture incident should expose a free branch", failures)


func _resolve_closing_credit(simulation: DepartmentSimulation, failures: Array[String]) -> void:
	var pending := simulation.pending_decision_snapshot()
	var kind := StringName(pending.get("kind", &""))
	_check(kind in [&"credit_allocation", &"major_event"], "staffing review should expose its closing credit decision", failures)
	var option_id: StringName
	match StringName(pending.get("id", &"")):
		&"closing_credit_memo":
			option_id = &"reward_top_layer"
		&"golden_egg_dossier":
			option_id = &"name_the_layer"
		&"flock_restructuring":
			option_id = &"contest_ranking"
		_:
			_check(false, "staffing review should expose a recognized closing decision ID", failures)
			return
	_check(simulation.resolve_decision(int(pending.get("serial", -1)), option_id), "staffing review should file a free closing attribution", failures)


func _expect_rejected_atomic(
	simulation: DepartmentSimulation,
	action: Callable,
	message: String,
	failures: Array[String]
) -> void:
	var before := simulation.export_save_state().duplicate(true)
	var result: Dictionary = action.call()
	_check(not bool(result.get("accepted", false)), message, failures)
	_check(not String(result.get("reason", "")).is_empty(), "%s should explain its rejection" % message, failures)
	_check(simulation.export_save_state() == before, "%s must preserve the complete authoritative state" % message, failures)


func _catalog_row(catalog: Array[Dictionary], worker_id: int) -> Dictionary:
	for row in catalog:
		if int(row.get("id", -1)) == worker_id:
			return row
	return {}


func _reset_career_xp(simulation: DepartmentSimulation) -> void:
	for worker in simulation.workers:
		worker.career_xp = 0


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
