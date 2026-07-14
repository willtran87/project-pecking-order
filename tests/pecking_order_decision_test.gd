extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_test_live_ranking_contract(failures)
	_test_closing_board_is_frozen_before_reset(failures)
	_test_campaign_memo_schedule_and_review_gate(failures)
	_test_invalid_choice_attempts_are_atomic(failures)
	_test_representative_effects_and_style_counts(failures)
	_test_v6_pending_and_resolved_json_round_trip(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("PECKING_ORDER_DECISION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PECKING_ORDER_DECISION_TEST_PASSED ranking=deterministic board=frozen schedule=1-2-3-4 atomic=true styles=exact json=v7-pending-resolved")
	quit(0)


func _test_live_ranking_contract(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(4101)
	# One fixture exercises every comparator in order. Worker 5 wins on credit;
	# workers 3/4 separate on goldens; 4/2 separate on cracks; 0/1 on ID.
	simulation._record_worker_shift_result(5, &"cracked", 1200)
	simulation._record_worker_shift_result(3, &"golden", 500)
	simulation._record_worker_shift_result(3, &"golden", 500)
	simulation._record_worker_shift_result(4, &"golden", 1000)
	simulation._record_worker_shift_result(2, &"golden", 500)
	simulation._record_worker_shift_result(2, &"cracked", 500)
	simulation._record_worker_shift_result(0, &"sound", 1000)
	simulation._record_worker_shift_result(1, &"sound", 1000)

	var ranking := simulation.current_pecking_order()
	_check(ranking.size() == 6, "live ranking should include all six employed workers", failures)
	_check(
		_worker_ids(ranking) == [5, 3, 4, 2, 0, 1],
		"ranking must sort by credited cents, then goldens, fewer cracks, then worker ID",
		failures,
	)
	for index in ranking.size():
		var row := ranking[index]
		_check(int(row.get("rank", 0)) == index + 1, "ranking row %d should receive its deterministic ordinal" % index, failures)
		_check(int(row.get("score", -1)) == int(row.get("credit_cents", -2)), "ranking score must be the credited-cent value", failures)
	_check(simulation.current_pecking_order() == ranking, "re-reading an unchanged ranking should be deterministic", failures)
	_check(
		simulation.snapshot().get("pecking_order", []) == ranking,
		"the public snapshot should expose the authoritative live ranking",
		failures,
	)


func _test_closing_board_is_frozen_before_reset(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(4201, 4)
	_check(simulation.select_directive(&"shell_assurance"), "closing-board fixture should start its workday", failures)
	simulation._record_worker_shift_result(2, &"sound", 900)
	simulation._record_worker_shift_result(0, &"golden", 800)
	simulation._record_worker_shift_result(3, &"sound", 800)
	simulation._record_worker_shift_result(1, &"cracked", 800)
	simulation.eggs_today = 4
	simulation.eggs_total = 4
	simulation.golden_today = 1
	simulation.golden_eggs = 1
	simulation.cracked_today = 1
	simulation.cracked_eggs = 1
	simulation.credited_today_cents = 3300
	var reports: Array[Dictionary] = []
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		reports.append(report.duplicate(true))
	, CONNECT_ONE_SHOT)

	simulation._complete_workday()
	_check(reports.size() == 1, "closing a workday should emit one report", failures)
	if reports.is_empty():
		return
	var report := reports[0]
	var frozen := report.get("pecking_order", []) as Array
	_check(_worker_ids(frozen) == [2, 0, 3, 1], "report should retain the pre-reset closing board", failures)
	_check(int((frozen[0] as Dictionary).get("credit_cents", 0)) == 900, "closing board should retain exact credited cents", failures)
	_check(int((frozen[1] as Dictionary).get("golden", 0)) == 1, "closing board should retain golden attribution", failures)
	_check(int((frozen[3] as Dictionary).get("cracked", 0)) == 1, "closing board should retain crack attribution", failures)
	_check(simulation.last_pecking_order == frozen, "simulation should retain the same board as the workday report", failures)
	_check(simulation.last_pecking_order_day == 1, "retained closing board should be labeled with completed day one", failures)
	var memo := simulation.pending_decision_snapshot()
	_check(StringName(memo.get("kind", &"")) == &"credit_allocation", "day-one close should prepare a standard credit memo", failures)
	_check(memo.get("ranking", []) == frozen, "credit memo should use the exact frozen report ranking", failures)
	_check(bool(report.get("credit_memo_required", false)), "workday report should disclose its required memo", failures)
	_check(StringName(report.get("credit_memo_kind", &"")) == &"credit_allocation", "workday report should disclose the standard memo kind", failures)
	var reset_ranking := simulation.current_pecking_order()
	_check(_worker_ids(reset_ranking) == [0, 1, 2, 3], "new-shift zero stats should fall back to worker ID order", failures)
	for row_value in reset_ranking:
		var row := row_value as Dictionary
		_check(
			int(row.get("eggs", -1)) == 0
			and int(row.get("golden", -1)) == 0
			and int(row.get("cracked", -1)) == 0
			and int(row.get("credit_cents", -1)) == 0,
			"live worker stats should reset only after the closing board is captured",
			failures,
		)


func _test_campaign_memo_schedule_and_review_gate(failures: Array[String]) -> void:
	for completed_day in [1, 2]:
		var simulation := _memo_fixture(completed_day, 0, 4300 + completed_day)
		var memo := simulation.pending_decision_snapshot()
		_check(StringName(memo.get("kind", &"")) == &"credit_allocation", "day %d should require a standard credit memo" % completed_day, failures)
		_check(StringName(memo.get("id", &"")) == &"closing_credit_memo", "day %d should use the closing-credit decision" % completed_day, failures)
		_check(not bool(memo.get("projected", true)), "standard day %d memo must not be projected" % completed_day, failures)
		_check(
			_option_ids(memo) == [&"reward_top_layer", &"share_feed_credit", &"claim_management_innovation"],
			"standard day %d memo should expose the three attribution styles" % completed_day,
			failures,
		)

	var dossier_simulation := _memo_fixture(3, 0, 4303)
	var dossier := dossier_simulation.pending_decision_snapshot()
	_check(StringName(dossier.get("kind", &"")) == &"major_event", "day three should guarantee the Golden Dossier major event", failures)
	_check(StringName(dossier.get("id", &"")) == &"golden_egg_dossier", "day-three major event should use the Golden Dossier ID", failures)
	_check(bool(dossier.get("projected", false)), "day-three dossier should mark a projected golden when no natural golden exists", failures)
	_check(
		_option_ids(dossier) == [&"name_the_layer", &"flock_owned_patent", &"patent_rooster_method"],
		"Golden Dossier should expose its three ownership filings",
		failures,
	)

	var restructuring_simulation := DepartmentSimulation.new(4304)
	restructuring_simulation.day = 5
	restructuring_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	restructuring_simulation.pending_decision.clear()
	for worker_id in restructuring_simulation.workers.size():
		restructuring_simulation._record_worker_shift_result(
			worker_id,
			&"sound",
			(restructuring_simulation.workers.size() - worker_id) * 100,
		)
	var restructuring_ranking := restructuring_simulation.current_pecking_order()
	restructuring_simulation._prepare_credit_allocation_decision(4, restructuring_ranking, 0)
	var restructuring := restructuring_simulation.pending_decision_snapshot()
	var bottom_ranked := restructuring_ranking[restructuring_ranking.size() - 1] as Dictionary
	_check(StringName(restructuring.get("kind", &"")) == &"major_event", "day four should guarantee the Flock Restructuring major event", failures)
	_check(StringName(restructuring.get("id", &"")) == &"flock_restructuring", "day-four major event should use the Flock Restructuring ID", failures)
	_check(
		int(restructuring.get("subject_worker_id", -1)) == int(bottom_ranked.get("worker_id", -2)),
		"Flock Restructuring should name the bottom worker from the frozen ranking",
		failures,
	)
	_check(
		String(restructuring.get("subject_worker_name", "")) == String(bottom_ranked.get("worker_name", "MISSING")),
		"Flock Restructuring should preserve the bottom-ranked worker's name",
		failures,
	)
	_check(
		_option_ids(restructuring) == [&"nominate_variance", &"fund_redeployment", &"contest_ranking"],
		"Flock Restructuring should expose dismissal, redeployment, and collective-contest filings",
		failures,
	)
	var post_campaign := _memo_fixture(5, 0, 4305)
	_check(post_campaign.pending_decision_snapshot().is_empty(), "day five should not create another closing credit memo", failures)

	var guarded := _memo_fixture(2, 0, 4312)
	var guarded_before := guarded.export_save_state().duplicate(true)
	_check(not guarded.begin_next_shift_briefing(), "next briefing must not bypass a pending credit memo", failures)
	_check(guarded.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW, "blocked briefing should remain in review", failures)
	_check(guarded.export_save_state() == guarded_before, "blocked briefing should preserve the complete simulation state", failures)


func _test_invalid_choice_attempts_are_atomic(failures: Array[String]) -> void:
	var simulation := _memo_fixture(1, 0, 4401)
	simulation.revenue_cents = (
		simulation.current_daily_operating_cost_cents()
		+ simulation.wage_arrears_cents
		+ 799
	)
	_check(simulation.spendable_fund_cents() == 799, "underfunded fixture should be exactly one cent short of Shared Scoop", failures)
	var resolved_events: Array[Dictionary] = []
	simulation.decision_resolved.connect(func(result: Dictionary) -> void:
		resolved_events.append(result)
	)
	var serial := int(simulation.pending_decision.get("serial", -1))

	var before_stale := simulation.export_save_state().duplicate(true)
	_check(not simulation.resolve_decision(serial - 1, &"reward_top_layer"), "stale credit memo serial should be rejected", failures)
	_check(simulation.export_save_state() == before_stale, "stale choice rejection must be atomic", failures)

	var before_unknown := simulation.export_save_state().duplicate(true)
	_check(not simulation.resolve_decision(serial, &"unknown_credit_filing"), "unknown credit option should be rejected", failures)
	_check(simulation.export_save_state() == before_unknown, "unknown choice rejection must be atomic", failures)

	var before_underfunded := simulation.export_save_state().duplicate(true)
	_check(not simulation.resolve_decision(serial, &"share_feed_credit"), "underfunded Shared Scoop should be rejected", failures)
	_check(simulation.export_save_state() == before_underfunded, "underfunded choice rejection must be atomic", failures)
	_check(resolved_events.is_empty(), "invalid attempts must not emit a resolution event", failures)


func _test_representative_effects_and_style_counts(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(4501)
	simulation.day = 5
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	for worker in simulation.workers:
		worker.morale = 40.0
		worker.manager_trust = 50.0
		worker.grievance = 20.0
		worker.career_xp = 0
	simulation.executive_confidence = 50.0
	simulation.solidarity = 30.0
	simulation.quota_target = 24
	simulation.revenue_cents = simulation.current_daily_operating_cost_cents() + 5000
	var opening_fund := simulation.revenue_cents
	var ranking := simulation.current_pecking_order()

	simulation._prepare_credit_allocation_decision(1, ranking, 0)
	var merit_serial := int(simulation.pending_decision.get("serial", -1))
	_check(simulation.resolve_decision(merit_serial, &"reward_top_layer"), "individual-merit fixture should resolve", failures)
	_check(_approximately(simulation.workers[0].morale, 44.0), "Individual Merit should add exactly 4 subject morale", failures)
	_check(_approximately(simulation.workers[0].manager_trust, 54.0), "Individual Merit should add exactly 4 subject trust", failures)
	_check(simulation.workers[0].career_xp == 3, "Individual Merit should add exactly 3 subject XP", failures)
	for worker_id in range(1, simulation.workers.size()):
		_check(_approximately(simulation.workers[worker_id].grievance, 21.0), "Individual Merit should add exactly 1 rival grievance", failures)
	_check(simulation.revenue_cents == opening_fund, "Individual Merit should not change the fund", failures)
	_check(_style_counts(simulation) == [1, 0, 0], "Individual Merit should increment only its style count", failures)

	var before_shared := _worker_effect_snapshot(simulation)
	var shared_fund_before := simulation.revenue_cents
	var shared_solidarity_before := simulation.solidarity
	var shared_confidence_before := simulation.executive_confidence
	simulation._prepare_credit_allocation_decision(2, ranking, 0)
	var shared_serial := int(simulation.pending_decision.get("serial", -1))
	_check(simulation.resolve_decision(shared_serial, &"share_feed_credit"), "Shared Scoop fixture should resolve", failures)
	_check(simulation.revenue_cents == shared_fund_before - 800, "Shared Scoop should deduct exactly 800 cents", failures)
	_check(_approximately(simulation.solidarity, shared_solidarity_before + 4.0), "Shared Scoop should add exactly 4 solidarity", failures)
	_check(_approximately(simulation.executive_confidence, shared_confidence_before - 2.0), "Shared Scoop should remove exactly 2 farmer favor", failures)
	_assert_uniform_worker_delta(simulation, before_shared, 4.0, 3.0, -2.0, 0, "Shared Scoop", failures)
	_check(_style_counts(simulation) == [1, 1, 0], "Shared Scoop should increment only its style count", failures)

	var before_management := _worker_effect_snapshot(simulation)
	var management_fund_before := simulation.revenue_cents
	var management_solidarity_before := simulation.solidarity
	var management_confidence_before := simulation.executive_confidence
	var management_quota_before := simulation.quota_target
	simulation._prepare_credit_allocation_decision(2, ranking, 0)
	var management_serial := int(simulation.pending_decision.get("serial", -1))
	_check(simulation.resolve_decision(management_serial, &"claim_management_innovation"), "Management Innovation fixture should resolve", failures)
	_check(simulation.revenue_cents == management_fund_before + 800, "Management Innovation should add exactly 800 cents", failures)
	_check(_approximately(simulation.executive_confidence, management_confidence_before + 5.0), "Management Innovation should add exactly 5 farmer favor", failures)
	_check(simulation.quota_target == management_quota_before + 1, "Management Innovation should add exactly 1 to next quota", failures)
	_check(_approximately(simulation.solidarity, management_solidarity_before - 3.0), "Management Innovation should remove exactly 3 solidarity", failures)
	_assert_uniform_worker_delta(simulation, before_management, 0.0, -3.0, 4.0, 0, "Management Innovation", failures)
	_check(simulation.revenue_cents == opening_fund, "representative paid and claimed-credit effects should net to the opening fund", failures)
	_check(_style_counts(simulation) == [1, 1, 1], "one representative choice per style should produce exact 1/1/1 counts", failures)
	_check(StringName(simulation.leadership_record_snapshot().get("id", &"")) == &"split_ledger", "equal style counts should report a split leadership ledger", failures)


func _test_v6_pending_and_resolved_json_round_trip(failures: Array[String]) -> void:
	var original := _memo_fixture(3, 0, 4601)
	var subject_id := int(original.pending_decision.get("subject_worker_id", -1))
	var subject := original.workers[subject_id]
	subject.morale = 40.0
	subject.manager_trust = 50.0
	subject.grievance = 20.0
	subject.career_xp = 0
	original.executive_confidence = 50.0
	var pending_state := original.export_save_state()
	_check(int(pending_state.get("state_version", -1)) == 7, "pending credit memo should export as simulation schema v7", failures)
	var pending_json := _json_round_trip(pending_state, "pending v6 checkpoint", failures)
	var pending_restored := DepartmentSimulation.new(4602)
	_check(pending_restored.restore_save_state(pending_json), "pending v6 JSON checkpoint should restore", failures)
	var restored_pending := pending_restored.pending_decision_snapshot()
	_check(_decision_contract(restored_pending) == _decision_contract(original.pending_decision_snapshot()), "pending v6 round trip should preserve memo identity and subject", failures)
	_check(_option_contract(restored_pending) == _option_contract(original.pending_decision_snapshot()), "pending v6 round trip should preserve option costs and styles", failures)
	_check(_worker_ids(restored_pending.get("ranking", []) as Array) == _worker_ids(original.pending_decision.get("ranking", []) as Array), "pending v6 round trip should preserve frozen ranking order", failures)
	_check(bool(restored_pending.get("projected", false)), "pending v6 round trip should preserve projected Golden Dossier status", failures)
	_check(pending_restored.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW, "pending v6 round trip should remain review-gated", failures)
	_check(int(pending_restored.export_save_state().get("state_version", -1)) == 7, "restored pending checkpoint should remain schema v7", failures)

	var restored_subject_id := int(restored_pending.get("subject_worker_id", -1))
	var restored_subject := pending_restored.workers[restored_subject_id]
	var fund_before := pending_restored.revenue_cents
	var serial := int(restored_pending.get("serial", -1))
	_check(pending_restored.resolve_decision(serial, &"name_the_layer"), "restored Golden Dossier should remain resolvable", failures)
	_check(_approximately(restored_subject.morale, 50.0), "Name the Layer should add exactly 10 author morale", failures)
	_check(_approximately(restored_subject.manager_trust, 62.0), "Name the Layer should add exactly 12 author trust", failures)
	_check(_approximately(restored_subject.grievance, 12.0), "Name the Layer should remove exactly 8 author grievance", failures)
	_check(restored_subject.career_xp == 12, "Name the Layer should add exactly 12 author XP", failures)
	_check(_approximately(pending_restored.executive_confidence, 47.0), "Name the Layer should remove exactly 3 farmer favor", failures)
	_check(pending_restored.revenue_cents == fund_before, "Name the Layer should have no fund cost", failures)
	_check(_style_counts(pending_restored) == [1, 0, 0], "resolved dossier should increment Individual Merit exactly once", failures)
	_check(pending_restored.golden_dossier_resolved and pending_restored.golden_dossier_day == 3, "resolved dossier should persist its one-time day-three marker", failures)
	_check(pending_restored.pending_decision_snapshot().is_empty(), "resolved dossier should clear its pending payload", failures)
	var allocation := pending_restored.last_credit_allocation
	_check(StringName(allocation.get("decision_id", &"")) == &"golden_egg_dossier", "resolved record should retain Golden Dossier identity", failures)
	_check(StringName(allocation.get("option_id", &"")) == &"name_the_layer", "resolved record should retain the filed option", failures)
	_check(StringName(allocation.get("style_id", &"")) == &"individual_merit", "resolved record should retain the management style", failures)
	_check(bool(allocation.get("special_event", false)) and bool(allocation.get("projected", false)), "resolved record should retain special/projected flags", failures)

	var resolved_state := pending_restored.export_save_state()
	_check(int(resolved_state.get("state_version", -1)) == 7, "resolved credit memo should export as simulation schema v7", failures)
	var resolved_json := _json_round_trip(resolved_state, "resolved v6 checkpoint", failures)
	var resolved_restored := DepartmentSimulation.new(4603)
	_check(resolved_restored.restore_save_state(resolved_json), "resolved v6 JSON checkpoint should restore", failures)
	_check(resolved_restored.pending_decision_snapshot().is_empty(), "resolved v6 round trip should not recreate a pending memo", failures)
	_check(resolved_restored.last_credit_allocation == allocation, "resolved v6 round trip should preserve the allocation ledger exactly", failures)
	_check(_style_counts(resolved_restored) == [1, 0, 0], "resolved v6 round trip should preserve style counts", failures)
	_check(resolved_restored.golden_dossier_resolved and resolved_restored.golden_dossier_day == 3, "resolved v6 round trip should preserve dossier completion", failures)
	var round_trip_subject := resolved_restored.workers[restored_subject_id]
	_check(_approximately(round_trip_subject.morale, 50.0), "resolved v6 round trip should preserve author morale", failures)
	_check(_approximately(round_trip_subject.manager_trust, 62.0), "resolved v6 round trip should preserve author trust", failures)
	_check(_approximately(round_trip_subject.grievance, 12.0), "resolved v6 round trip should preserve author grievance", failures)
	_check(round_trip_subject.career_xp == 12, "resolved v6 round trip should preserve author XP", failures)
	_check(int(resolved_restored.export_save_state().get("state_version", -1)) == 7, "restored resolved checkpoint should remain schema v7", failures)


func _memo_fixture(
	completed_day: int,
	completed_golden: int,
	seed: int,
) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed)
	simulation.day = completed_day + 1
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation._prepare_credit_allocation_decision(
		completed_day,
		simulation.current_pecking_order(),
		completed_golden,
	)
	return simulation


func _worker_ids(ranking: Array) -> Array[int]:
	var result: Array[int] = []
	for row_value in ranking:
		var row := row_value as Dictionary
		result.append(int(row.get("worker_id", -1)))
	return result


func _option_ids(decision: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	for option_value in decision.get("options", []):
		var option := option_value as Dictionary
		result.append(StringName(option.get("id", &"")))
	return result


func _style_counts(simulation: DepartmentSimulation) -> Array[int]:
	return [
		int(simulation.credit_choice_counts.get(&"individual_merit", 0)),
		int(simulation.credit_choice_counts.get(&"shared_scoop", 0)),
		int(simulation.credit_choice_counts.get(&"management_innovation", 0)),
	]


func _worker_effect_snapshot(simulation: DepartmentSimulation) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for worker in simulation.workers:
		result.append({
			"morale": worker.morale,
			"trust": worker.manager_trust,
			"grievance": worker.grievance,
			"xp": worker.career_xp,
		})
	return result


func _assert_uniform_worker_delta(
	simulation: DepartmentSimulation,
	before: Array[Dictionary],
	morale_delta: float,
	trust_delta: float,
	grievance_delta: float,
	xp_delta: int,
	label: String,
	failures: Array[String],
) -> void:
	for worker_id in simulation.workers.size():
		var worker := simulation.workers[worker_id]
		var prior := before[worker_id]
		_check(_approximately(worker.morale, float(prior.get("morale", 0.0)) + morale_delta), "%s should apply exact worker %d morale delta" % [label, worker_id], failures)
		_check(_approximately(worker.manager_trust, float(prior.get("trust", 0.0)) + trust_delta), "%s should apply exact worker %d trust delta" % [label, worker_id], failures)
		_check(_approximately(worker.grievance, float(prior.get("grievance", 0.0)) + grievance_delta), "%s should apply exact worker %d grievance delta" % [label, worker_id], failures)
		_check(worker.career_xp == int(prior.get("xp", 0)) + xp_delta, "%s should apply exact worker %d XP delta" % [label, worker_id], failures)


func _decision_contract(decision: Dictionary) -> Dictionary:
	return {
		"serial": int(decision.get("serial", -1)),
		"kind": String(decision.get("kind", "")),
		"id": String(decision.get("id", "")),
		"day": int(decision.get("day", -1)),
		"completed_day": int(decision.get("completed_day", -1)),
		"subject_worker_id": int(decision.get("subject_worker_id", -1)),
		"subject_worker_name": String(decision.get("subject_worker_name", "")),
		"projected": bool(decision.get("projected", false)),
	}


func _option_contract(decision: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for option_value in decision.get("options", []):
		var option := option_value as Dictionary
		result.append({
			"id": String(option.get("id", "")),
			"cost_cents": int(option.get("cost_cents", -1)),
			"style_id": String(option.get("style_id", "")),
		})
	return result


func _json_round_trip(
	state: Dictionary,
	label: String,
	failures: Array[String],
) -> Dictionary:
	var encoded := JSON.stringify(state)
	var parsed: Variant = JSON.parse_string(encoded)
	_check(parsed is Dictionary, "%s should survive JSON encoding", failures)
	if not parsed is Dictionary:
		return {}
	return parsed as Dictionary


func _approximately(actual: float, expected: float, tolerance: float = 0.0001) -> bool:
	return absf(actual - expected) <= tolerance


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
