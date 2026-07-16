extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_test_named_petition_and_atomic_tiers(failures)
	_test_structural_fallback_and_probation_days(failures)
	_test_compact_fulfillment_and_release_breach(failures)
	_test_work_to_rule_has_one_shift_of_causal_effect(failures)
	_test_v6_round_trip_and_strict_invariants(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("FLOCK_PETITION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FLOCK_PETITION_TEST_PASSED sponsor=deterministic tiers=atomic compact=once release=breach work_to_rule=causal persistence=v10")
	quit(0)


func _test_named_petition_and_atomic_tiers(failures: Array[String]) -> void:
	var simulation := _day_fixture(4201, 2, &"credit", 4)
	# Applicants carry deliberately louder raw readings; they must never become a
	# sponsor because only the employed flock has standing in this incident.
	for worker_id in range(4, simulation.workers.size()):
		simulation.workers[worker_id].stress = 100.0
		simulation.workers[worker_id].fatigue = 100.0
		simulation.workers[worker_id].assigned_lane = &"appeals"
	var petition := _open_second_incident(simulation, failures)
	_check(StringName(petition.get("id", &"")) == &"flock_petition", "Day 2's eligible second interruption should be the petition", failures)
	_check(StringName(petition.get("category", &"")) == &"flock_petition", "petition should expose its presentation category", failures)
	_check(StringName(petition.get("petition_type", &"")) == &"credit_in_writing", "credit-conscious state should select the written-credit petition", failures)
	var sponsor_id := int(petition.get("sponsor_worker_id", -1))
	_check(sponsor_id >= 0 and sponsor_id < 4, "a named sponsor must be employed, never an applicant", failures)
	if sponsor_id >= 0 and sponsor_id < simulation.workers.size():
		_check(String(petition.get("sponsor_worker_name", "")) == simulation.workers[sponsor_id].display_name, "sponsor identity should reconcile to the worker ledger", failures)
	var evidence := petition.get("evidence", []) as Array
	_check(not evidence.is_empty(), "petition should carry state-derived evidence for presentation", failures)
	var options := petition.get("options", []) as Array
	_check(options.size() == 3, "petition should expose exactly three response tiers", failures)
	var expected_tiers := {
		&"sign_compact": {"tier": &"binding", "cost": 700},
		&"offer_concession": {"tier": &"concession", "cost": 400},
		&"deny_and_monitor": {"tier": &"denial", "cost": 0},
	}
	for option_value in options:
		var option := option_value as Dictionary
		var option_id := StringName(option.get("id", &""))
		_check(expected_tiers.has(option_id), "every petition option should belong to the three-tier contract", failures)
		if expected_tiers.has(option_id):
			var expected := expected_tiers[option_id] as Dictionary
			_check(StringName(option.get("response_tier", &"")) == StringName(expected.get("tier", &"")), "%s should expose its response tier" % String(option_id), failures)
			_check(int(option.get("cost_cents", -1)) == int(expected.get("cost", -2)), "%s should expose its exact cent cost" % String(option_id), failures)

	var serial := int(petition.get("serial", -1))
	var protected_cents := simulation.current_daily_operating_cost_cents() + simulation.wage_arrears_cents
	simulation.revenue_cents = protected_cents + 699
	var before_rejection := simulation.export_save_state().duplicate(true)
	_check(not simulation.resolve_decision(serial, &"sign_compact"), "one-cent-short compact should be rejected", failures)
	_check(simulation.export_save_state() == before_rejection, "failed affordability should leave all authoritative state unchanged", failures)
	simulation.revenue_cents += 1
	var funded_before := simulation.revenue_cents
	_check(simulation.resolve_decision(serial, &"sign_compact"), "exactly funded compact should resolve", failures)
	_check(simulation.revenue_cents == funded_before - 700, "signed compact should deduct exactly seven dollars", failures)
	_check(simulation.incidents_resolved_today == 2, "petition should occupy the normal second incident slot exactly once", failures)
	_check(StringName(simulation.active_flock_compact.get("status", &"")) == &"scheduled", "signing should schedule a binding next-shift compact", failures)
	_check(int(simulation.active_flock_compact.get("effective_day", 0)) == 3, "Day 2 compact should bind Day 3", failures)
	_check(int(simulation.last_flock_petition.get("sponsor_worker_id", -1)) == sponsor_id, "resolution record should retain the named sponsor", failures)
	_check((simulation.flock_petition_history as Array).size() == 1, "petition should enter history once", failures)

	var concession := _day_fixture(4204, 2, &"safe_pace")
	var concession_petition := _open_second_incident(concession, failures)
	var concession_sponsor := int(concession_petition.get("sponsor_worker_id", -1))
	concession.revenue_cents = concession.current_daily_operating_cost_cents() + 400
	var stress_before := concession.workers[concession_sponsor].stress
	_check(concession.resolve_decision(int(concession_petition.get("serial", -1)), &"offer_concession"), "middle-tier feed concession should resolve", failures)
	_check(concession.spendable_fund_cents() == 0, "concession should spend its exact four-dollar discretionary balance", failures)
	_check(concession.workers[concession_sponsor].stress < stress_before, "concession should provide immediate sponsor relief", failures)
	_check(concession.active_flock_compact.is_empty(), "concession should not invent a binding compact", failures)
	_check(StringName(concession.last_flock_petition.get("response_tier", &"")) == &"concession", "concession should freeze its response tier in history", failures)


func _test_structural_fallback_and_probation_days(failures: Array[String]) -> void:
	var fallback := _day_fixture(4202, 2, &"none", 4)
	for worker_id in range(4, fallback.workers.size()):
		fallback.workers[worker_id].stress = 100.0
		fallback.workers[worker_id].fatigue = 100.0
		fallback.workers[worker_id].assigned_lane = &"appeals"
	var interruption_count := {"value": 0}
	fallback.decision_requested.connect(func(decision: Dictionary) -> void:
		if StringName(decision.get("kind", &"")) == &"incident":
			interruption_count["value"] = int(interruption_count["value"]) + 1
	)
	var structural := _open_second_incident(fallback, failures)
	_check(StringName(structural.get("id", &"")) == &"feed_shortfall", "no eligible employed sponsor should preserve the structural fallback", failures)
	_check(_resolve_free_incident(fallback), "fallback should retain its free response branch", failures)
	for _tick in 8:
		fallback.advance_tick()
	_check(int(interruption_count["value"]) == 2, "fallback day should still contain exactly two interruptions", failures)
	_check(fallback.incidents_resolved_today == 2, "fallback day should resolve exactly two incidents", failures)
	_check(fallback.last_flock_petition.is_empty(), "structural fallback must not invent petition history", failures)

	var day_four := _day_fixture(4203, 4, &"specialty")
	var day_four_petition := _open_second_incident(day_four, failures)
	_check(StringName(day_four_petition.get("id", &"")) == &"flock_petition", "Day 4's eligible second incident should also become a petition", failures)
	_check(StringName(day_four_petition.get("petition_type", &"")) == &"specialty_respect", "mismatched routing should deterministically select specialty respect", failures)


func _test_compact_fulfillment_and_release_breach(failures: Array[String]) -> void:
	var fulfilled := _day_fixture(4211, 2, &"credit")
	var petition := _open_second_incident(fulfilled, failures)
	var sponsor_id := int(petition.get("sponsor_worker_id", -1))
	fulfilled.revenue_cents = fulfilled.current_daily_operating_cost_cents() + 10000
	_check(fulfilled.resolve_decision(int(petition.get("serial", -1)), &"sign_compact"), "fulfillment fixture should sign its compact", failures)
	_finish_shift(fulfilled, failures)
	_check(fulfilled.day == 3 and StringName(fulfilled.active_flock_compact.get("status", &"")) == &"active", "signed compact should activate in Day 3 review", failures)
	_check(_start_reviewed_shift(fulfilled), "fulfillment fixture should start Day 3", failures)
	fulfilled.revenue_cents = fulfilled.current_daily_operating_cost_cents() + 5000
	var shared_credit := fulfilled.perform_personnel_action(sponsor_id, &"share_credit")
	_check(bool(shared_credit.get("accepted", false)), "written-credit compact should accept Share Credit for its sponsor", failures)
	var fulfillment_report := _finish_shift(fulfilled, failures)
	var receipt := fulfilled.last_flock_compact_receipt.duplicate(true)
	_check(StringName(receipt.get("status", &"")) == &"fulfilled", "kept promise should produce a fulfilled receipt", failures)
	_check(int(receipt.get("resolved_day", 0)) == 3, "compact should resolve on its one binding shift", failures)
	_check(fulfilled.active_flock_compact.is_empty(), "fulfilled compact should clear from active authority", failures)
	_check((fulfillment_report.get("flock_compact_receipt", {}) as Dictionary) == receipt, "closing report should expose the exact fulfillment receipt", failures)
	var receipt_after_snapshots := fulfilled.last_flock_compact_receipt.duplicate(true)
	fulfilled.snapshot()
	fulfilled.snapshot()
	_check(fulfilled.last_flock_compact_receipt == receipt_after_snapshots, "presentation reads must not duplicate fulfillment effects", failures)

	var breached := _day_fixture(4212, 2, &"specialty")
	var breach_petition := _open_second_incident(breached, failures)
	var breach_sponsor_id := int(breach_petition.get("sponsor_worker_id", -1))
	breached.revenue_cents = breached.current_daily_operating_cost_cents() + 20000
	_check(breached.resolve_decision(int(breach_petition.get("serial", -1)), &"sign_compact"), "release fixture should sign its specialty compact", failures)
	_finish_shift(breached, failures)
	_check(StringName(breached.active_flock_compact.get("status", &"")) == &"active", "release fixture should enter review with an active compact", failures)
	_check(_resolve_free_incident(breached), "release fixture should file its closing credit before staffing changes", failures)
	breached.revenue_cents = 100000
	breached.solidarity = DepartmentSimulation.WORK_TO_RULE_SOLIDARITY_THRESHOLD
	var release_result := breached.release_worker(breach_sponsor_id)
	_check(bool(release_result.get("accepted", false)), "active compact sponsor should still be legally releasable", failures)
	_check(bool(release_result.get("compact_breached", false)), "sponsor release should explicitly report compact breach", failures)
	var breach_receipt := breached.last_flock_compact_receipt.duplicate(true)
	_check(StringName(breach_receipt.get("status", &"")) == &"breached", "sponsor release should create a breach receipt", failures)
	_check(StringName(breach_receipt.get("reason", &"")) == &"sponsor_released", "breach receipt should name sponsor release as its cause", failures)
	_check(breached.active_flock_compact.is_empty(), "breached compact should clear exactly once", failures)
	_check(bool(breached.work_to_rule_snapshot().get("active", false)), "solidarity after sponsor release should activate work-to-rule for the upcoming shift", failures)
	var solidarity_after_breach := breached.solidarity
	_check(not bool(breached.release_worker(breach_sponsor_id).get("accepted", false)), "same sponsor cannot be released twice", failures)
	_check(breached.last_flock_compact_receipt == breach_receipt, "replayed release must not replace the breach receipt", failures)
	_check(is_equal_approx(breached.solidarity, solidarity_after_breach), "replayed release must not duplicate solidarity effects", failures)


func _test_work_to_rule_has_one_shift_of_causal_effect(failures: Array[String]) -> void:
	var baseline := _day_fixture(4221, 2, &"credit")
	var collective := _day_fixture(4221, 2, &"credit")
	var baseline_petition := _open_second_incident(baseline, failures)
	var collective_petition := _open_second_incident(collective, failures)
	baseline.solidarity = 0.0
	collective.solidarity = DepartmentSimulation.WORK_TO_RULE_SOLIDARITY_THRESHOLD - 14.0
	_check(baseline.resolve_decision(int(baseline_petition.get("serial", -1)), &"deny_and_monitor"), "baseline denial should resolve", failures)
	_check(collective.resolve_decision(int(collective_petition.get("serial", -1)), &"deny_and_monitor"), "threshold denial should resolve", failures)
	_check(not bool(baseline.work_to_rule_snapshot().get("scheduled", false)), "sub-threshold denial should not schedule collective action", failures)
	_check(bool(collective.work_to_rule_snapshot().get("scheduled", false)), "threshold denial should schedule one next-shift work-to-rule", failures)
	_finish_shift(baseline, failures)
	_finish_shift(collective, failures)
	_check(_start_reviewed_shift(baseline), "baseline comparison should start Day 3", failures)
	_check(_start_reviewed_shift(collective), "collective comparison should start Day 3", failures)
	baseline.set_worker_at_workstation(0, true)
	collective.set_worker_at_workstation(0, true)
	baseline.advance_tick()
	collective.advance_tick()
	baseline.advance_tick()
	collective.advance_tick()
	_check(collective.workers[0].work_progress < baseline.workers[0].work_progress, "work-to-rule should causally lower authoritative claim progress", failures)
	_check(collective.estimated_crack_risk(0) < baseline.estimated_crack_risk(0), "careful procedure should causally lower authoritative crack risk", failures)
	var modifiers := collective.snapshot().get("decision_modifiers", {}) as Dictionary
	_check(is_equal_approx(float(modifiers.get("work_to_rule_work_multiplier", 0.0)), 0.82), "snapshot should disclose the exact work-to-rule throughput multiplier", failures)
	_check(is_equal_approx(float(modifiers.get("work_to_rule_crack_modifier", 0.0)), -0.06), "snapshot should disclose the exact work-to-rule crack modifier", failures)
	var collective_report := _finish_shift(collective, failures)
	_check(bool((collective_report.get("work_to_rule", {}) as Dictionary).get("completed", false)), "closing report should identify the completed work-to-rule shift", failures)
	_check(not bool(collective.work_to_rule_snapshot().get("active", true)), "work-to-rule should end after exactly one shift", failures)
	_check(is_equal_approx(float((collective.snapshot().get("decision_modifiers", {}) as Dictionary).get("work_to_rule_work_multiplier", 0.0)), 1.0), "next shift should restore normal throughput", failures)


func _test_v6_round_trip_and_strict_invariants(failures: Array[String]) -> void:
	var original := _day_fixture(4231, 2, &"credit", 4)
	var petition := _open_second_incident(original, failures)
	var pending_encoded := JSON.stringify({"simulation": original.export_save_state()})
	var pending_parsed: Variant = JSON.parse_string(pending_encoded)
	var pending_restored := DepartmentSimulation.new(9230, 4)
	var pending_restore_ok := false
	if pending_parsed is Dictionary:
		pending_restore_ok = pending_restored.restore_save_state((pending_parsed as Dictionary).get("simulation", {}) as Dictionary)
	_check(pending_restore_ok, "pending named petition should survive a strict v6 round trip", failures)
	_check(StringName(pending_restored.pending_decision_snapshot().get("id", &"")) == &"flock_petition", "restored pending petition should remain in the existing incident API", failures)
	original.revenue_cents = original.current_daily_operating_cost_cents() + 5000
	_check(original.resolve_decision(int(petition.get("serial", -1)), &"sign_compact"), "persistence fixture should sign a scheduled compact", failures)
	var encoded := JSON.stringify({"simulation": original.export_save_state()})
	var parsed: Variant = JSON.parse_string(encoded)
	var restored := DepartmentSimulation.new(9231, 4)
	var restored_ok := false
	if parsed is Dictionary:
		restored_ok = restored.restore_save_state((parsed as Dictionary).get("simulation", {}) as Dictionary)
	_check(restored_ok, "v6 petition state should survive a primitive JSON round trip", failures)
	_check(restored.last_flock_petition == original.last_flock_petition, "round trip should preserve the named petition record", failures)
	_check(restored.flock_petition_history == original.flock_petition_history, "round trip should preserve bounded petition history", failures)
	_check(restored.active_flock_compact == original.active_flock_compact, "round trip should preserve the binding scheduled compact", failures)
	_check(int(restored.export_save_state().get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "restored petition state should export the current schema", failures)

	var invalid_target := DepartmentSimulation.new(9232, 4)
	var invalid_before := invalid_target.export_save_state().duplicate(true)
	var invalid_applicant := original.export_save_state().duplicate(true)
	var applicant_id := 4
	var applicant_name := original.workers[applicant_id].display_name
	var invalid_compact := invalid_applicant.get("active_flock_compact", {}) as Dictionary
	invalid_compact["sponsor_worker_id"] = applicant_id
	invalid_compact["sponsor_worker_name"] = applicant_name
	invalid_compact["compact_id"] = "D2-credit_in_writing-%d" % applicant_id
	var invalid_last := invalid_applicant.get("last_flock_petition", {}) as Dictionary
	invalid_last["sponsor_worker_id"] = applicant_id
	invalid_last["sponsor_worker_name"] = applicant_name
	var invalid_history := invalid_applicant.get("flock_petition_history", []) as Array
	(invalid_history[0] as Dictionary)["sponsor_worker_id"] = applicant_id
	(invalid_history[0] as Dictionary)["sponsor_worker_name"] = applicant_name
	_check(not invalid_target.restore_save_state(invalid_applicant), "active compact may not restore with an applicant sponsor", failures)
	_check(invalid_target.export_save_state() == invalid_before, "rejected applicant compact should fail closed before mutation", failures)

	var denied := _day_fixture(4233, 2, &"credit", 4)
	var denied_petition := _open_second_incident(denied, failures)
	denied.solidarity = DepartmentSimulation.WORK_TO_RULE_SOLIDARITY_THRESHOLD
	_check(denied.resolve_decision(int(denied_petition.get("serial", -1)), &"deny_and_monitor"), "work record fixture should deny at threshold", failures)
	var invalid_modifier := denied.export_save_state().duplicate(true)
	(invalid_modifier.get("last_work_to_rule_record", {}) as Dictionary)["work_multiplier"] = 1.0
	_check(not invalid_target.restore_save_state(invalid_modifier), "work-to-rule record with forged mechanics should fail strict validation", failures)
	_check(invalid_target.export_save_state() == invalid_before, "forged work modifier should also fail closed", failures)


func _day_fixture(seed: int, target_day: int, petition_mode: StringName, staff_count: int = 6) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, staff_count)
	simulation.day = target_day
	simulation.pending_decision["day"] = target_day
	for worker in simulation.workers:
		worker.assigned_lane = DepartmentSimulation.AUTO_ASSIGNMENT
		worker.stress = 0.0
		worker.fatigue = 0.0
		worker.grievance = 0.0
	simulation.last_credit_allocation.clear()
	match petition_mode:
		&"credit":
			var sponsor_id := _first_employed_profile(simulation, &"credit_conscious")
			if sponsor_id >= 0:
				var sponsor := simulation.workers[sponsor_id]
				simulation.last_credit_allocation = {
					"day": target_day - 1,
					"decision_id": "credit_allocation",
					"option_id": "reward_top_layer",
					"style_id": "individual_merit",
					"worker_id": sponsor.id,
					"worker_name": sponsor.display_name,
					"cost_cents": 0,
					"outcome": "Prior credit memo filed.",
					"special_event": false,
					"projected": false,
				}
		&"specialty":
			var worker := simulation.workers[0]
			worker.assigned_lane = &"appeals" if worker.specialty != &"appeals" else &"nest_damage"
			worker.grievance = 90.0
		&"safe_pace":
			simulation.workers[0].stress = 90.0
	simulation.select_directive(&"shell_assurance")
	return simulation


func _first_employed_profile(simulation: DepartmentSimulation, profile: StringName) -> int:
	for worker in simulation.workers:
		if worker.employed and worker.career_profile == profile:
			return worker.id
	return -1


func _open_second_incident(simulation: DepartmentSimulation, failures: Array[String]) -> Dictionary:
	simulation.minute_of_day = DepartmentSimulation.INCIDENT_MINUTES[0] - DepartmentSimulation.MINUTES_PER_TICK
	simulation.advance_tick()
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT, "fixture should open its first incident", failures)
	_check(_resolve_free_incident(simulation), "fixture should resolve the first structural incident", failures)
	simulation.minute_of_day = DepartmentSimulation.INCIDENT_MINUTES[1] - DepartmentSimulation.MINUTES_PER_TICK
	simulation.advance_tick()
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT, "fixture should open its second incident", failures)
	return simulation.pending_decision_snapshot()


func _resolve_free_incident(simulation: DepartmentSimulation) -> bool:
	var pending := simulation.pending_decision_snapshot()
	var serial := int(pending.get("serial", -1))
	for option_value in pending.get("options", []):
		var option := option_value as Dictionary
		if int(option.get("cost_cents", 0)) == 0:
			return simulation.resolve_decision(serial, StringName(option.get("id", &"")))
	return false


func _finish_shift(simulation: DepartmentSimulation, failures: Array[String]) -> Dictionary:
	var report_box := {"report": {}}
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		report_box["report"] = report.duplicate(true)
	, CONNECT_ONE_SHOT)
	while simulation.incidents_resolved_today < DepartmentSimulation.INCIDENT_MINUTES.size():
		if simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT:
			_check(_resolve_free_incident(simulation), "shift helper should resolve a free incident option", failures)
			continue
		var slot := simulation.incidents_resolved_today
		simulation.minute_of_day = DepartmentSimulation.INCIDENT_MINUTES[slot] - DepartmentSimulation.MINUTES_PER_TICK
		simulation.advance_tick()
	simulation.eggs_today = simulation.quota_target
	simulation.cracked_today = 0
	simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	simulation.advance_tick()
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW, "shift helper should reach review", failures)
	return report_box.get("report", {}) as Dictionary


func _start_reviewed_shift(simulation: DepartmentSimulation) -> bool:
	var pending := simulation.pending_decision_snapshot()
	if not pending.is_empty():
		var resolved := false
		var serial := int(pending.get("serial", -1))
		for option_value in pending.get("options", []):
			var option := option_value as Dictionary
			if int(option.get("cost_cents", 0)) == 0:
				resolved = simulation.resolve_decision(serial, StringName(option.get("id", &"")))
				break
		if not resolved:
			return false
	if not simulation.begin_next_shift_briefing():
		return false
	return simulation.select_directive(&"shell_assurance")


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
