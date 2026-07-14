extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	_test_initial_decision_guards(failures)
	_test_directive_modifiers(failures)
	_test_incident_and_review_lifecycle(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("DECISION_LOOP_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("DECISION_LOOP_TEST_PASSED directives=3 incidents=2 atomic_paid_choice=true review_gate=true")
	quit(0)


func _test_initial_decision_guards(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(701)
	var resolved_events: Array[Dictionary] = []
	simulation.decision_resolved.connect(func(result: Dictionary) -> void:
		resolved_events.append(result)
	)

	var opening := simulation.snapshot()
	var pending: Dictionary = opening.get("pending_decision", {})
	var opening_minute := simulation.minute_of_day
	var opening_claims := simulation.claims_waiting
	var opening_fund := simulation.revenue_cents
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE, "a new simulation should await a morning directive", failures)
	_check(StringName(pending.get("kind", &"")) == &"directive", "the opening decision should be a directive", failures)
	_check((pending.get("options", []) as Array).size() == 3, "the morning directive should expose all three policies", failures)

	simulation.advance_tick()
	_check(simulation.minute_of_day == opening_minute, "ticks must not advance while the directive is pending", failures)
	_check(simulation.claims_waiting == opening_claims, "blocked directive ticks must not mutate the claim queue", failures)
	_check(not simulation.fund_feed_party(), "feed party funding should be rejected while a directive is pending", failures)
	_check(simulation.revenue_cents == opening_fund, "a rejected pending-decision feed party must not charge the fund", failures)
	_check(not simulation.toggle_overtime() and not simulation.overtime_enabled, "overtime should remain off while a directive is pending", failures)

	var serial := int(pending.get("serial", -1))
	_check(not simulation.resolve_decision(serial - 1, &"shell_assurance"), "a stale decision serial should be rejected", failures)
	_check(not simulation.resolve_decision(serial, &"not_a_policy"), "an unknown directive option should be rejected", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE, "invalid directive attempts must leave the decision pending", failures)
	_check(simulation.pending_decision_snapshot() == pending, "invalid directive attempts must leave the pending payload unchanged", failures)

	var compliance_before := simulation.compliance
	_check(simulation.select_directive(&"shell_assurance"), "a valid directive should resolve the morning decision", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING, "a resolved directive should start the shift", failures)
	_check(simulation.active_directive_id == &"shell_assurance", "the selected directive should become authoritative", failures)
	_check(simulation.pending_decision_snapshot().is_empty(), "the directive payload should clear after resolution", failures)
	_check(_approximately(simulation.compliance, compliance_before + 3.0), "Shell Assurance should add exactly three compliance points", failures)
	_check(resolved_events.size() == 1, "a valid directive should emit exactly one resolution event", failures)

	var compliance_after := simulation.compliance
	_check(not simulation.resolve_decision(serial, &"shell_assurance"), "the same directive serial must not resolve twice", failures)
	_check(not simulation.select_directive(&"record_harvest"), "a second directive must not apply during the same running shift", failures)
	_check(_approximately(simulation.compliance, compliance_after), "double-apply attempts must not repeat directive effects", failures)
	_check(resolved_events.size() == 1, "double-apply attempts must not emit another resolution event", failures)


func _test_directive_modifiers(failures: Array[String]) -> void:
	var harvest := DepartmentSimulation.new(711)
	_check(harvest.select_directive(&"record_harvest"), "Record Harvest should be selectable", failures)
	var harvest_modifiers: Dictionary = harvest.snapshot().get("decision_modifiers", {})
	_check(_approximately(float(harvest_modifiers.get("work_multiplier", 0.0)), 1.10), "Record Harvest should apply a 1.10 work multiplier", failures)
	_check(_approximately(float(harvest_modifiers.get("fatigue_multiplier", 0.0)), 1.20), "Record Harvest should apply a 1.20 fatigue multiplier", failures)
	_check(_approximately(float(harvest_modifiers.get("stress_multiplier", 0.0)), 1.20), "Record Harvest should apply a 1.20 stress multiplier", failures)
	_check(_approximately(float(harvest_modifiers.get("crack_modifier", 0.0)), 0.04), "Record Harvest should add four percentage points of crack risk", failures)

	var assurance := DepartmentSimulation.new(712)
	_check(assurance.select_directive(&"shell_assurance"), "Shell Assurance should be selectable", failures)
	var assurance_modifiers: Dictionary = assurance.snapshot().get("decision_modifiers", {})
	_check(_approximately(float(assurance_modifiers.get("work_multiplier", 0.0)), 0.93), "Shell Assurance should apply a 0.93 work multiplier", failures)
	_check(_approximately(float(assurance_modifiers.get("fatigue_multiplier", 0.0)), 1.0), "Shell Assurance should leave fatigue gain unchanged", failures)
	_check(_approximately(float(assurance_modifiers.get("crack_modifier", 0.0)), -0.05), "Shell Assurance should remove five percentage points of crack risk", failures)

	var flock_care := DepartmentSimulation.new(713)
	var stress_before := flock_care.workers[0].stress
	_check(flock_care.select_directive(&"sustainable_flock"), "Sustainable Flock should be selectable", failures)
	var care_snapshot := flock_care.snapshot()
	var care_modifiers: Dictionary = care_snapshot.get("decision_modifiers", {})
	_check(_approximately(float(care_modifiers.get("work_multiplier", 0.0)), 0.97), "Sustainable Flock should apply a 0.97 work multiplier", failures)
	_check(_approximately(float(care_modifiers.get("fatigue_multiplier", 0.0)), 0.70), "Sustainable Flock should apply a 0.70 fatigue multiplier", failures)
	_check(_approximately(float(care_modifiers.get("stress_multiplier", 0.0)), 0.70), "Sustainable Flock should apply a 0.70 stress multiplier", failures)
	_check(_approximately(float(care_modifiers.get("morale_drain_multiplier", 0.0)), 0.60), "Sustainable Flock should reduce morale drain to 0.60", failures)
	_check(int(care_snapshot.get("daily_feed_cost_cents", 0)) == 2400, "Sustainable Flock should add exactly $6 to daily feed", failures)
	_check(_approximately(flock_care.workers[0].stress, stress_before - 4.0), "Sustainable Flock should immediately remove four stress points", failures)


func _test_incident_and_review_lifecycle(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(721)
	var review_reports: Array[Dictionary] = []
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		review_reports.append(report)
	)
	_check(simulation.select_directive(&"shell_assurance"), "the lifecycle fixture should start under Shell Assurance", failures)
	_check(simulation.toggle_overtime() and simulation.overtime_enabled, "overtime should be enabled while the shift is running", failures)

	simulation.minute_of_day = 10 * 60 + 58
	simulation.advance_tick()
	var first_incident := simulation.pending_decision_snapshot()
	_check(simulation.minute_of_day == 11 * 60, "the first incident should open at 11:00 AM", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT, "the first incident should pause authoritative simulation", failures)
	_check(StringName(first_incident.get("kind", &"")) == &"incident", "the 11:00 decision should be an incident", failures)
	_check(StringName(first_incident.get("id", &"")) == &"ledger_molt", "day one's first incident should use the deterministic ledger event", failures)

	var blocked_minute := simulation.minute_of_day
	simulation.advance_tick()
	_check(simulation.minute_of_day == blocked_minute, "time must remain frozen until an incident is resolved", failures)
	var fund_before_guard := simulation.revenue_cents
	_check(not simulation.fund_feed_party(), "feed party funding should be rejected while an incident is pending", failures)
	_check(simulation.revenue_cents == fund_before_guard, "a rejected incident-time feed party must not charge the fund", failures)
	_check(simulation.toggle_overtime() and simulation.overtime_enabled, "an incident-time overtime request should preserve the prior enabled state", failures)

	var first_serial := int(first_incident.get("serial", -1))
	var patch_reserve := _protected_fund_cents(simulation, 0)
	simulation.revenue_cents = patch_reserve + 1799
	var compliance_before_patch := simulation.compliance
	var modifiers_before_patch: Dictionary = simulation.snapshot().get("decision_modifiers", {})
	_check(not simulation.resolve_decision(first_serial, &"patch"), "the paid patch should fail when the fund is one cent short", failures)
	_check(simulation.revenue_cents == patch_reserve + 1799, "a failed paid response must leave reserves and discretionary fund untouched", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT, "a failed paid response must leave the incident pending", failures)
	_check(simulation.pending_decision_snapshot() == first_incident, "a failed paid response must preserve the decision payload", failures)
	_check(simulation.incidents_resolved_today == 0, "a failed paid response must not count as a resolved incident", failures)
	_check(_approximately(simulation.compliance, compliance_before_patch), "a failed paid response must not apply compliance effects", failures)
	_check(simulation.snapshot().get("decision_modifiers", {}) == modifiers_before_patch, "a failed paid response must not apply hidden modifiers", failures)

	simulation.revenue_cents = patch_reserve + 1800
	var fund_before_patch := simulation.revenue_cents
	_check(simulation.resolve_decision(first_serial, &"patch"), "the paid patch should succeed when the fund covers its exact cost", failures)
	_check(simulation.revenue_cents == fund_before_patch - 1800, "the successful patch should deduct exactly $18", failures)
	_check(simulation.revenue_cents == patch_reserve, "the successful patch should preserve protected operating obligations", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING, "a successful incident response should resume authoritative simulation", failures)
	_check(simulation.incidents_resolved_today == 1, "the successful patch should count exactly one incident", failures)
	_check(_approximately(simulation.compliance, compliance_before_patch + 4.0), "the successful patch should add four compliance points", failures)
	var patched_modifiers: Dictionary = simulation.snapshot().get("decision_modifiers", {})
	_check(_approximately(float(patched_modifiers.get("crack_modifier", 0.0)), -0.09), "Shell Assurance plus the patch should total minus nine crack-risk points", failures)
	_check(not simulation.toggle_overtime() and not simulation.overtime_enabled, "overtime should toggle normally again after the incident resolves", failures)

	var break_reserve := _protected_fund_cents(simulation, 0)
	simulation.revenue_cents = break_reserve + 600
	simulation.minute_of_day = 13 * 60 + 58
	simulation.advance_tick()
	var second_incident := simulation.pending_decision_snapshot()
	_check(simulation.minute_of_day == 14 * 60, "the second incident should open at 2:00 PM", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT, "the second incident should pause authoritative simulation", failures)
	_check(StringName(second_incident.get("id", &"")) == &"wellness_request", "day one's second incident should use the deterministic wellness event", failures)
	var morale_before_break := simulation.workers[0].morale
	var stress_before_break := simulation.workers[0].stress
	var fatigue_before_break := simulation.workers[0].fatigue
	var fund_before_break := simulation.revenue_cents
	_check(simulation.resolve_decision(int(second_incident.get("serial", -1)), &"grant_breaks"), "the funded rotating break should resolve the second incident", failures)
	_check(simulation.revenue_cents == fund_before_break - 600, "the rotating break should deduct exactly $6", failures)
	_check(simulation.revenue_cents == break_reserve, "the rotating break should preserve protected operating obligations", failures)
	_check(simulation.incidents_resolved_today == 2, "both scheduled incidents should be counted once", failures)
	_check(_approximately(simulation.workers[0].morale, morale_before_break + 4.0), "the rotating break should add four morale points", failures)
	_check(_approximately(simulation.workers[0].stress, stress_before_break - 6.0), "the rotating break should remove six stress points", failures)
	_check(_approximately(simulation.workers[0].fatigue, fatigue_before_break - 5.0), "the rotating break should remove five fatigue points", failures)

	simulation.eggs_today = simulation.quota_target
	simulation.cracked_today = 0
	simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	simulation.advance_tick()
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW, "shift completion should enter the explicit review phase", failures)
	_check(simulation.day == 2, "shift completion should advance to day two", failures)
	_check(simulation.minute_of_day == DepartmentSimulation.SHIFT_START_MINUTE, "review should hold the next shift at 8:00 AM", failures)
	var closing_memo := simulation.pending_decision_snapshot()
	_check(StringName(closing_memo.get("kind", &"")) == &"credit_allocation", "review should capture a required closing credit memo without creating tomorrow's directive", failures)
	_check((closing_memo.get("ranking", []) as Array).size() == simulation.active_worker_count(), "closing memo should carry the frozen employed-hen ranking", failures)
	_check(simulation.active_directive_snapshot().is_empty(), "the completed shift's directive should no longer be active", failures)
	_check(review_reports.size() == 1, "shift completion should emit exactly one review report", failures)
	if not review_reports.is_empty():
		var report := review_reports[0]
		var reported_directive: Dictionary = report.get("directive", {})
		_check(StringName(reported_directive.get("id", &"")) == &"shell_assurance", "the review should retain the completed shift's directive", failures)
		_check(int(report.get("incidents_resolved", 0)) == 2, "the review should report both resolved incidents", failures)

	var next_shift_fund := simulation.revenue_cents
	_check(not simulation.fund_feed_party(), "feed party funding should be rejected during review", failures)
	_check(simulation.revenue_cents == next_shift_fund, "a review-time feed party rejection must not charge the fund", failures)
	_check(not simulation.toggle_overtime() and not simulation.overtime_enabled, "overtime should remain off during review", failures)
	_check(not simulation.begin_next_shift_briefing(), "the review must not bypass its closing credit memo", failures)
	_check(simulation.pending_decision_snapshot() == closing_memo, "a blocked briefing attempt must preserve the memo exactly", failures)
	_check(
		simulation.resolve_decision(int(closing_memo.get("serial", -1)), &"reward_top_layer"),
		"filing a valid free credit allocation should clear the review gate",
		failures,
	)
	_check(simulation.pending_decision_snapshot().is_empty(), "filed credit memo should clear before briefing", failures)
	_check(simulation.begin_next_shift_briefing(), "the cleared review should explicitly open the next morning briefing", failures)
	var next_opening := simulation.snapshot()
	var next_pending: Dictionary = next_opening.get("pending_decision", {})
	var reset_modifiers: Dictionary = next_opening.get("decision_modifiers", {})
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE, "the next briefing should await a new directive", failures)
	_check(StringName(next_pending.get("kind", &"")) == &"directive", "the next briefing should create a directive decision", failures)
	_check(int(next_pending.get("day", 0)) == 2, "the next directive should be labeled for day two", failures)
	_check(_approximately(float(reset_modifiers.get("work_multiplier", 0.0)), 1.0), "daily work modifiers should reset before the next directive", failures)
	_check(_approximately(float(reset_modifiers.get("fatigue_multiplier", 0.0)), 1.0), "daily fatigue modifiers should reset before the next directive", failures)
	_check(_approximately(float(reset_modifiers.get("stress_multiplier", 0.0)), 1.0), "daily stress modifiers should reset before the next directive", failures)
	_check(_approximately(float(reset_modifiers.get("crack_modifier", 1.0)), 0.0), "daily crack modifiers should reset before the next directive", failures)
	_check(simulation.incidents_resolved_today == 0, "the incident count should reset before the next shift", failures)
	var next_serial := int(next_pending.get("serial", -1))
	_check(not simulation.begin_next_shift_briefing(), "the same review must not create a second morning briefing", failures)
	_check(int(simulation.pending_decision_snapshot().get("serial", -2)) == next_serial, "a duplicate briefing attempt must preserve the original directive serial", failures)
	var briefing_minute := simulation.minute_of_day
	simulation.advance_tick()
	_check(simulation.minute_of_day == briefing_minute, "the next shift must remain frozen until its directive is selected", failures)


func _approximately(actual: float, expected: float, tolerance: float = 0.0001) -> bool:
	return absf(actual - expected) <= tolerance


func _protected_fund_cents(simulation: DepartmentSimulation, discretionary_cents: int) -> int:
	return (
		simulation.current_daily_operating_cost_cents()
		+ simulation.wage_arrears_cents
		+ discretionary_cents
	)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
