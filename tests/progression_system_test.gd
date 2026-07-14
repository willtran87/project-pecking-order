extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	_test_upgrade_transactions(failures)
	_test_upgrade_effects(failures)
	_test_daily_guards_and_review(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("PROGRESSION_SYSTEM_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PROGRESSION_SYSTEM_TEST_PASSED upgrades=3 feed=once-per-shift review=rewarded effects=causal")
	quit(0)


func _test_upgrade_transactions(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(11)
	var catalog := simulation.upgrade_catalog()
	_check(catalog.size() == 3, "catalog should expose three distinct management paths", failures)
	var first_cost := simulation.upgrade_cost_cents(&"peckwork_tools")
	var first_reserve := _protected_fund_cents(simulation, 0)
	simulation.revenue_cents = first_reserve + first_cost
	_check(simulation.purchase_upgrade(&"peckwork_tools"), "exact-cost purchase should succeed", failures)
	_check(simulation.revenue_cents == first_reserve, "exact-cost purchase should leave operating obligations fully reserved", failures)
	_check(simulation.spendable_fund_cents() == 0, "exact-cost purchase should consume only the complete discretionary balance", failures)
	_check(simulation.upgrade_level(&"peckwork_tools") == 1, "successful purchase should increase level", failures)
	_check(simulation.upgrade_cost_cents(&"peckwork_tools") > first_cost, "next level should cost more", failures)

	var insufficient := DepartmentSimulation.new(12)
	var qa_cost := insufficient.upgrade_cost_cents(&"shell_lamp")
	var insufficient_reserve := _protected_fund_cents(insufficient, 0)
	insufficient.revenue_cents = insufficient_reserve + qa_cost - 1
	_check(not insufficient.purchase_upgrade(&"shell_lamp"), "one-cent-short purchase should fail", failures)
	_check(insufficient.revenue_cents == insufficient_reserve + qa_cost - 1 and insufficient.upgrade_level(&"shell_lamp") == 0, "failed purchase must preserve reserves and remain atomic", failures)

	var capped := DepartmentSimulation.new(13)
	capped.revenue_cents = 10_000_000
	for _level in DepartmentSimulation.MAX_UPGRADE_LEVEL:
		_check(capped.purchase_upgrade(&"nest_cushion"), "upgrade should purchase through its level cap", failures)
	var fund_at_cap := capped.revenue_cents
	_check(not capped.purchase_upgrade(&"nest_cushion"), "level cap should reject another purchase", failures)
	_check(capped.revenue_cents == fund_at_cap, "capped purchase must not charge the fund", failures)


func _test_upgrade_effects(failures: Array[String]) -> void:
	var baseline := DepartmentSimulation.new(21)
	var upgraded := DepartmentSimulation.new(21)
	_check(baseline.select_directive(&"shell_assurance"), "baseline fixture should authorize its opening directive", failures)
	_check(upgraded.select_directive(&"shell_assurance"), "upgraded fixture should authorize the same opening directive", failures)
	upgraded.revenue_cents = _protected_fund_cents(upgraded, upgraded.upgrade_cost_cents(&"peckwork_tools"))
	upgraded.purchase_upgrade(&"peckwork_tools")
	for worker in baseline.workers:
		baseline.set_worker_at_workstation(worker.id, true)
	for worker in upgraded.workers:
		upgraded.set_worker_at_workstation(worker.id, true)
	baseline.advance_tick()
	upgraded.advance_tick()
	baseline.advance_tick()
	upgraded.advance_tick()
	_check(upgraded.workers[0].work_progress > baseline.workers[0].work_progress, "keycaps should visibly accelerate peckwork", failures)

	var comfort_base := DepartmentSimulation.new(22)
	var comfort_upgrade := DepartmentSimulation.new(22)
	_check(comfort_base.select_directive(&"shell_assurance"), "comfort baseline should authorize its opening directive", failures)
	_check(comfort_upgrade.select_directive(&"shell_assurance"), "comfort upgrade should authorize the same opening directive", failures)
	comfort_upgrade.revenue_cents = _protected_fund_cents(comfort_upgrade, comfort_upgrade.upgrade_cost_cents(&"nest_cushion"))
	comfort_upgrade.purchase_upgrade(&"nest_cushion")
	for simulation in [comfort_base, comfort_upgrade]:
		simulation.set_worker_at_workstation(0, true)
		simulation.workers[0].work_state = ChickenState.WorkState.WORKING
	comfort_base.advance_tick()
	comfort_upgrade.advance_tick()
	_check(comfort_upgrade.workers[0].stress < comfort_base.workers[0].stress, "nest pad should reduce stress gain", failures)
	_check(comfort_upgrade.workers[0].fatigue < comfort_base.workers[0].fatigue, "nest pad should reduce fatigue gain", failures)

	var qa_base := DepartmentSimulation.new(23)
	var qa_upgrade := DepartmentSimulation.new(23)
	qa_upgrade.revenue_cents = _protected_fund_cents(qa_upgrade, qa_upgrade.upgrade_cost_cents(&"shell_lamp"))
	qa_upgrade.purchase_upgrade(&"shell_lamp")
	_check(qa_upgrade.estimated_crack_risk(0) < qa_base.estimated_crack_risk(0), "QA lamp should reduce authoritative crack risk", failures)


func _test_daily_guards_and_review(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(31)
	var reports: Array[Dictionary] = []
	simulation.workday_completed.connect(func(report: Dictionary) -> void: reports.append(report))
	_check(simulation.select_directive(&"shell_assurance"), "daily fixture should authorize its opening directive", failures)
	var feed_party_reserve := _protected_fund_cents(simulation, 0)
	simulation.revenue_cents = feed_party_reserve + 2000
	var fund_before_feed_party := simulation.revenue_cents
	_check(simulation.fund_feed_party(), "first feed party should succeed", failures)
	_check(simulation.revenue_cents == fund_before_feed_party - 2000, "feed party should deduct exactly $20", failures)
	_check(simulation.revenue_cents == feed_party_reserve, "feed party should preserve protected operating obligations", failures)
	var fund_after_first := simulation.revenue_cents
	_check(not simulation.fund_feed_party(), "second feed party in one shift should be denied", failures)
	_check(simulation.revenue_cents == fund_after_first, "denied feed party must not charge the fund", failures)
	simulation.eggs_today = simulation.quota_target
	simulation.cracked_today = 0
	simulation.overtime_enabled = true
	simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	for _step in 3:
		simulation.advance_tick()
		_resolve_pending_incident(simulation)
	_check(reports.size() == 1, "shift end should emit one review report", failures)
	_check(not simulation.feed_party_used_today, "feed-party availability should reset next shift", failures)
	_check(not simulation.overtime_enabled, "overtime should reset next shift", failures)
	_check(simulation.quota_target >= 25 and simulation.quota_target <= 27, "successful quota should raise expectations within the stated band", failures)
	if not reports.is_empty():
		var report := reports[0]
		_check(int(report.get("quota_bonus_cents", 0)) > 0, "quota success should grant a visible fund bonus", failures)
		_check(int(report.get("quality_bonus_cents", 0)) == 500, "clean shift should grant the $5 quality bonus", failures)
		_check(int(report.get("next_quota", 0)) == simulation.quota_target, "review should disclose tomorrow's real target", failures)


func _resolve_pending_incident(simulation: DepartmentSimulation) -> void:
	var pending := simulation.pending_decision_snapshot()
	if StringName(pending.get("kind", &"")) != &"incident":
		return
	var serial := int(pending.get("serial", -1))
	for option_value in pending.get("options", []):
		var option := option_value as Dictionary
		if int(option.get("cost_cents", 0)) == 0:
			simulation.resolve_decision(serial, StringName(option.get("id", &"")))
			return


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _protected_fund_cents(simulation: DepartmentSimulation, discretionary_cents: int) -> int:
	return (
		simulation.current_daily_operating_cost_cents()
		+ simulation.wage_arrears_cents
		+ discretionary_cents
	)
