extends SceneTree


const ASSIST_V5_FIELDS: Array[String] = [
	"peck_assists_used_today",
	"peck_assist_streak",
	"best_peck_assist_streak",
	"last_peck_assist",
	"priority_credit_today_cents",
	"priority_credit_total_cents",
	"assisted_claim_ids",
	"missed_assist_claim_ids",
	"assist_quality_modifiers",
	"assist_chain_by_claim_id",
]
const RESTRUCTURING_V5_FIELDS: Array[String] = [
	"flock_restructuring_resolved",
	"flock_restructuring_day",
	"flock_restructuring_record",
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_test_deterministic_bottom_ranked_candidate(failures)
	_test_nomination_effects_and_minimum_roster_replacement(failures)
	_test_paid_redeployment_effects_and_atomic_rejection(failures)
	_test_collective_contest_effects(failures)
	_test_v6_json_round_trip_and_v4_neutral_migration(failures)
	_test_distinct_campaign_ending_ids(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("FLOCK_RESTRUCTURING_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FLOCK_RESTRUCTURING_TEST_PASSED candidate=bottom choices=exact paid=atomic replacement=minimum persistence=v10-v4 endings=distinct")
	quit(0)


func _test_deterministic_bottom_ranked_candidate(failures: Array[String]) -> void:
	var simulation := _restructuring_fixture(6101, 4)
	var ranking := simulation.last_pecking_order
	var decision := simulation.pending_decision_snapshot()
	_check(_worker_ids(ranking) == [0, 1, 2, 3], "fixture ranking should be deterministic before the event is prepared", failures)
	_check(StringName(decision.get("kind", &"")) == &"major_event", "day-four restructuring should be a major event", failures)
	_check(StringName(decision.get("id", &"")) == &"flock_restructuring", "day-four major event should use the flock_restructuring ID", failures)
	_check(int(decision.get("completed_day", 0)) == 4, "restructuring should be tied to completed shift four", failures)
	_check(int(decision.get("subject_worker_id", -1)) == 3, "frozen ranking should nominate the deterministic bottom-ranked worker", failures)
	_check(String(decision.get("subject_worker_name", "")) == simulation.workers[3].display_name, "decision should preserve the nominated hen's name", failures)
	_check(_worker_ids(decision.get("ranking", []) as Array) == [0, 1, 2, 3], "decision should freeze the complete ranking in order", failures)
	_check(_option_ids(decision) == [&"nominate_variance", &"fund_redeployment", &"contest_ranking"], "restructuring should expose the three intended filings in order", failures)
	_check(_option_costs(decision) == [0, 1200, 0], "restructuring option costs should be exact and disclosed", failures)
	_check(String(decision.get("body", "")).contains("OMITTED CONTEXT"), "restructuring dossier should disclose omitted ranking context", failures)


func _test_nomination_effects_and_minimum_roster_replacement(failures: Array[String]) -> void:
	var simulation := _restructuring_fixture(6201, 4)
	var candidate_id := int(simulation.pending_decision.get("subject_worker_id", -1))
	var candidate := simulation.workers[candidate_id]
	var before := _worker_metrics(simulation)
	var fund_before := simulation.revenue_cents
	var favor_before := simulation.executive_confidence
	var quota_before := simulation.quota_target
	var unity_before := simulation.solidarity
	var obedience_before := simulation.compliance
	var serial := int(simulation.pending_decision.get("serial", -1))
	_check(simulation.resolve_decision(serial, &"nominate_variance"), "nomination filing should resolve", failures)

	_check(not candidate.employed and candidate.desk_index == -1, "nomination should release the bottom-ranked candidate", failures)
	_check(candidate.available_for_hire_day == simulation.day + 2, "released candidate should not immediately return as an applicant", failures)
	_check(simulation.active_worker_count() == 3, "a four-hen roster should fall to the legal minimum after nomination", failures)
	_check(simulation.revenue_cents == fund_before + 1800, "nomination should add exactly $18 to the fund", failures)
	_check(_approximately(simulation.executive_confidence, favor_before + 8.0), "nomination should add exactly 8 farmer favor", failures)
	_check(simulation.quota_target == quota_before + 2, "nomination should add exactly 2 to the next quota", failures)
	_check(_approximately(simulation.solidarity, unity_before + 10.0), "nomination should add exactly 10 flock unity", failures)
	_check(_approximately(simulation.compliance, obedience_before), "nomination should not change obedience", failures)
	for worker_id in simulation.workers.size():
		var prior := before[worker_id]
		var worker := simulation.workers[worker_id]
		if worker_id < 3:
			_check(_approximately(worker.morale, float(prior.get("morale", 0.0)) - 7.0), "nomination should remove exactly 7 morale from retained worker %d" % worker_id, failures)
			_check(_approximately(worker.manager_trust, float(prior.get("trust", 0.0)) - 10.0), "nomination should remove exactly 10 trust from retained worker %d" % worker_id, failures)
			_check(_approximately(worker.grievance, float(prior.get("grievance", 0.0)) + 12.0), "nomination should add exactly 12 grievance to retained worker %d" % worker_id, failures)
		else:
			_check(_same_relationship_metrics(worker, prior), "nomination should not apply retained-flock penalties to worker %d" % worker_id, failures)
	_check(_style_counts(simulation) == [0, 0, 1], "nomination should increment only Management Innovation", failures)
	_assert_resolved_record(simulation, &"nominate_variance", candidate_id, 0, failures)
	_check(int(simulation.flock_restructuring_record.get("replacement_worker_id", -2)) == -1, "four-to-three nomination should not invent a replacement", failures)

	# At the minimum roster size, the named hen still leaves, but a real applicant
	# must occupy the released desk so the simulation cannot strand the office at two.
	var minimum := _restructuring_fixture(6202, 3)
	var minimum_candidate_id := int(minimum.pending_decision.get("subject_worker_id", -1))
	var minimum_candidate := minimum.workers[minimum_candidate_id]
	var released_desk := minimum_candidate.desk_index
	var replacement := minimum.workers[3]
	var replacement_morale_before := replacement.morale
	var replacement_hires_before := replacement.hire_count
	var minimum_serial := int(minimum.pending_decision.get("serial", -1))
	_check(minimum.resolve_decision(minimum_serial, &"nominate_variance"), "minimum-roster nomination should resolve with a replacement", failures)
	_check(not minimum_candidate.employed, "minimum-roster nominated hen should still be released", failures)
	_check(replacement.employed and replacement.desk_index == released_desk, "first eligible applicant should occupy the released desk", failures)
	_check(replacement.hire_count == replacement_hires_before + 1, "automatic replacement should increment the applicant's hire count", failures)
	_check(replacement.employment_start_day == minimum.day, "automatic replacement should record the restructuring day as her start", failures)
	_check(_approximately(replacement.morale, replacement_morale_before + 3.0), "automatic replacement should receive exactly 3 onboarding morale", failures)
	_check(minimum.active_worker_count() == DepartmentSimulation.MINIMUM_STAFF_COUNT, "minimum-roster nomination must preserve the three-hen floor", failures)
	_check(int(minimum.flock_restructuring_record.get("replacement_worker_id", -1)) == replacement.id, "restructuring record should name the automatic replacement", failures)
	_check(String(minimum.flock_restructuring_record.get("replacement_worker_name", "")) == replacement.display_name, "restructuring record should preserve the replacement name", failures)


func _test_paid_redeployment_effects_and_atomic_rejection(failures: Array[String]) -> void:
	var underfunded := _restructuring_fixture(6301, 4)
	underfunded.revenue_cents = (
		underfunded.current_daily_operating_cost_cents()
		+ underfunded.wage_arrears_cents
		+ 1199
	)
	_check(underfunded.spendable_fund_cents() == 1199, "underfunded redeployment fixture should be exactly one cent short", failures)
	var rejected_events := {"count": 0}
	underfunded.decision_resolved.connect(func(_result: Dictionary) -> void:
		rejected_events["count"] += 1
	)
	var underfunded_before := underfunded.export_save_state().duplicate(true)
	var underfunded_serial := int(underfunded.pending_decision.get("serial", -1))
	_check(not underfunded.resolve_decision(underfunded_serial, &"fund_redeployment"), "one-cent-short redeployment should be rejected", failures)
	_check(underfunded.export_save_state() == underfunded_before, "one-cent-short rejection must preserve the complete simulation atomically", failures)
	_check(int(rejected_events["count"]) == 0, "rejected redeployment must not emit decision_resolved", failures)

	var simulation := _restructuring_fixture(6302, 4)
	var candidate_id := int(simulation.pending_decision.get("subject_worker_id", -1))
	var candidate := simulation.workers[candidate_id]
	var before := _worker_metrics(simulation)
	var assigned_before := candidate.assigned_lane
	var fund_before := simulation.revenue_cents
	var favor_before := simulation.executive_confidence
	var obedience_before := simulation.compliance
	var quota_before := simulation.quota_target
	var unity_before := simulation.solidarity
	var serial := int(simulation.pending_decision.get("serial", -1))
	_check(assigned_before != candidate.specialty, "redeployment fixture should begin outside the candidate's specialty", failures)
	_check(simulation.resolve_decision(serial, &"fund_redeployment"), "funded redeployment should resolve", failures)

	var prior := before[candidate_id]
	_check(candidate.employed, "redeployment should retain the nominated hen", failures)
	_check(candidate.assigned_lane == candidate.specialty, "redeployment should assign the candidate to her specialty", failures)
	_check(_approximately(candidate.morale, float(prior.get("morale", 0.0)) + 8.0), "redeployment should add exactly 8 candidate morale", failures)
	_check(_approximately(candidate.manager_trust, float(prior.get("trust", 0.0)) + 14.0), "redeployment should add exactly 14 candidate trust", failures)
	_check(_approximately(candidate.grievance, float(prior.get("grievance", 0.0)) - 12.0), "redeployment should remove exactly 12 candidate grievance", failures)
	_check(_approximately(candidate.stress, float(prior.get("stress", 0.0)) - 10.0), "redeployment should remove exactly 10 candidate stress", failures)
	_check(_approximately(candidate.fatigue, float(prior.get("fatigue", 0.0)) - 10.0), "redeployment should remove exactly 10 candidate fatigue", failures)
	_check(candidate.career_xp == int(prior.get("xp", 0)) + 18, "redeployment should add exactly 18 candidate XP", failures)
	for worker_id in simulation.workers.size():
		if worker_id == candidate_id:
			continue
		_check(_same_worker_metrics(simulation.workers[worker_id], before[worker_id]), "redeployment should not alter unrelated worker %d" % worker_id, failures)
	_check(simulation.revenue_cents == fund_before - 1200, "redeployment should deduct exactly $12", failures)
	_check(_approximately(simulation.executive_confidence, favor_before - 5.0), "redeployment should remove exactly 5 farmer favor", failures)
	_check(_approximately(simulation.compliance, obedience_before + 4.0), "redeployment should add exactly 4 obedience", failures)
	_check(simulation.quota_target == quota_before - 1, "redeployment should reduce the next quota by exactly 1", failures)
	_check(_approximately(simulation.solidarity, unity_before), "redeployment should not change flock unity", failures)
	_check(_style_counts(simulation) == [1, 0, 0], "redeployment should increment only Individual Merit", failures)
	_assert_resolved_record(simulation, &"fund_redeployment", candidate_id, 1200, failures)


func _test_collective_contest_effects(failures: Array[String]) -> void:
	var simulation := _restructuring_fixture(6401, 4)
	var candidate_id := int(simulation.pending_decision.get("subject_worker_id", -1))
	var before := _worker_metrics(simulation)
	var fund_before := simulation.revenue_cents
	var favor_before := simulation.executive_confidence
	var obedience_before := simulation.compliance
	var quota_before := simulation.quota_target
	var unity_before := simulation.solidarity
	var serial := int(simulation.pending_decision.get("serial", -1))
	_check(simulation.resolve_decision(serial, &"contest_ranking"), "collective contest should resolve", failures)

	for worker_id in simulation.workers.size():
		var worker := simulation.workers[worker_id]
		var prior := before[worker_id]
		if worker.employed:
			_check(_approximately(worker.morale, float(prior.get("morale", 0.0)) + 4.0), "collective contest should add exactly 4 morale to employed worker %d" % worker_id, failures)
			_check(_approximately(worker.manager_trust, float(prior.get("trust", 0.0)) + 8.0), "collective contest should add exactly 8 trust to employed worker %d" % worker_id, failures)
			_check(_approximately(worker.grievance, float(prior.get("grievance", 0.0)) - 6.0), "collective contest should remove exactly 6 grievance from employed worker %d" % worker_id, failures)
			_check(_approximately(worker.stress, float(prior.get("stress", 0.0))), "collective contest should not change worker %d stress" % worker_id, failures)
			_check(_approximately(worker.fatigue, float(prior.get("fatigue", 0.0))), "collective contest should not change worker %d fatigue" % worker_id, failures)
			_check(worker.career_xp == int(prior.get("xp", 0)), "collective contest should not change worker %d XP" % worker_id, failures)
		else:
			_check(_same_worker_metrics(worker, prior), "collective contest should not alter applicant %d", failures)
	_check(simulation.workers[candidate_id].employed, "collective contest should retain the nominated hen", failures)
	_check(simulation.revenue_cents == fund_before, "collective contest should have no fund cost", failures)
	_check(_approximately(simulation.executive_confidence, favor_before - 10.0), "collective contest should remove exactly 10 farmer favor", failures)
	_check(_approximately(simulation.compliance, obedience_before - 5.0), "collective contest should remove exactly 5 obedience", failures)
	_check(simulation.quota_target == quota_before + 2, "collective contest should add exactly 2 retaliatory quota", failures)
	_check(_approximately(simulation.solidarity, unity_before + 15.0), "collective contest should add exactly 15 flock unity", failures)
	_check(_style_counts(simulation) == [0, 1, 0], "collective contest should increment only Shared Scoop", failures)
	_assert_resolved_record(simulation, &"contest_ranking", candidate_id, 0, failures)


func _test_v6_json_round_trip_and_v4_neutral_migration(failures: Array[String]) -> void:
	var pending_original := _restructuring_fixture(6501, 4)
	var pending_json := _json_round_trip(pending_original.export_save_state(), "pending restructuring v6 checkpoint", failures)
	var pending_restored := DepartmentSimulation.new(6502, 4)
	_check(pending_restored.restore_save_state(pending_json), "pending restructuring v6 JSON checkpoint should restore", failures)
	var restored_pending := pending_restored.pending_decision_snapshot()
	_check(StringName(restored_pending.get("id", &"")) == &"flock_restructuring", "pending round trip should retain restructuring identity", failures)
	_check(int(restored_pending.get("subject_worker_id", -1)) == 3, "pending round trip should retain the frozen candidate", failures)
	_check(_worker_ids(restored_pending.get("ranking", []) as Array) == [0, 1, 2, 3], "pending round trip should retain the frozen ranking", failures)
	_check(_option_ids(restored_pending) == [&"nominate_variance", &"fund_redeployment", &"contest_ranking"], "pending round trip should retain restructuring choices", failures)

	var original := _restructuring_fixture(6503, 4)
	var candidate_id := int(original.pending_decision.get("subject_worker_id", -1))
	var serial := int(original.pending_decision.get("serial", -1))
	_check(original.resolve_decision(serial, &"fund_redeployment"), "resolved persistence fixture should file redeployment", failures)
	var exported := original.export_save_state()
	_check(int(exported.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "restructuring checkpoint should use the current simulation schema", failures)
	for field in RESTRUCTURING_V5_FIELDS:
		_check(exported.has(field), "current schema should export restructuring field %s" % field, failures)
	var resolved_json := _json_round_trip(exported, "resolved restructuring v6 checkpoint", failures)
	var restored := DepartmentSimulation.new(6504, 4)
	_check(restored.restore_save_state(resolved_json), "resolved restructuring v6 JSON checkpoint should restore", failures)
	_check(restored.flock_restructuring_resolved, "resolved round trip should retain the one-time restructuring marker", failures)
	_check(restored.flock_restructuring_day == 4, "resolved round trip should retain restructuring day four", failures)
	_check(restored.flock_restructuring_record == original.flock_restructuring_record, "resolved round trip should preserve the restructuring consequence ledger exactly", failures)
	_check(restored.last_credit_allocation == original.last_credit_allocation, "resolved round trip should preserve the matching credit ledger", failures)
	_check(restored.pending_decision_snapshot().is_empty(), "resolved round trip should not recreate the decision", failures)
	_check(restored.workers[candidate_id].employed, "resolved redeployment round trip should retain candidate employment", failures)
	_check(restored.workers[candidate_id].assigned_lane == restored.workers[candidate_id].specialty, "resolved redeployment round trip should retain specialty assignment", failures)
	_check(restored.workers[candidate_id].career_xp == 18, "resolved redeployment round trip should retain candidate XP", failures)

	# Authentic schema v4 predates both Peck Assist and Flock Restructuring. Remove
	# every v6 field before migration so the test cannot accidentally smuggle in a
	# modern consequence ledger under an old version number.
	var legacy_v4 := DepartmentSimulation.new(6505, 4).export_save_state().duplicate(true)
	legacy_v4["state_version"] = 4
	for field in ASSIST_V5_FIELDS + RESTRUCTURING_V5_FIELDS:
		legacy_v4.erase(field)
	var migrated := DepartmentSimulation.new(6506, 4)
	_check(migrated.restore_save_state(legacy_v4), "authentic v4 checkpoint should migrate to neutral v6 restructuring state", failures)
	var migrated_state := migrated.export_save_state()
	_check(int(migrated_state.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "v4 migration should export the current schema", failures)
	_check(not migrated.flock_restructuring_resolved, "v4 migration should not invent a resolved restructuring", failures)
	_check(migrated.flock_restructuring_day == 0, "v4 migration should initialize restructuring day to zero", failures)
	_check(migrated.flock_restructuring_record.is_empty(), "v4 migration should not invent a restructuring consequence ledger", failures)
	_check(migrated_state.has("flock_restructuring_resolved"), "migrated v6 state should export the restructuring resolved marker", failures)
	_check(migrated_state.has("flock_restructuring_day"), "migrated v6 state should export the restructuring day", failures)
	_check(migrated_state.has("flock_restructuring_record"), "migrated v6 state should export the restructuring record", failures)


func _test_distinct_campaign_ending_ids(failures: Array[String]) -> void:
	var expected_ids := {
		&"nominate_variance": &"farmer_favorite",
		&"fund_redeployment": &"benevolent_rooster",
		&"contest_ranking": &"collective_bargaining",
	}
	var ending_ids: Array[StringName] = []
	for option_id in expected_ids:
		var simulation := _restructuring_fixture(6600 + ending_ids.size(), 4)
		var serial := int(simulation.pending_decision.get("serial", -1))
		_check(simulation.resolve_decision(serial, option_id), "%s ending fixture should resolve its restructuring choice" % String(option_id), failures)
		if not simulation.has_method("campaign_ending_snapshot"):
			_check(false, "DepartmentSimulation should expose campaign_ending_snapshot for restructuring consequences", failures)
			return
		var ending_value: Variant = simulation.call("campaign_ending_snapshot", true)
		_check(ending_value is Dictionary, "%s should produce a campaign ending dictionary" % String(option_id), failures)
		if not ending_value is Dictionary:
			continue
		var ending := ending_value as Dictionary
		var ending_id := StringName(ending.get("id", &""))
		ending_ids.append(ending_id)
		_check(ending_id == StringName(expected_ids[option_id]), "%s should map to ending ID %s" % [String(option_id), String(expected_ids[option_id])], failures)
		_check(not String(ending.get("title", "")).is_empty(), "%s ending should have a player-facing title" % String(option_id), failures)
		_check(not String(ending.get("coda", "")).is_empty(), "%s ending should have a consequence coda" % String(option_id), failures)
	var unique_ids: Dictionary[StringName, bool] = {}
	for ending_id in ending_ids:
		unique_ids[ending_id] = true
	_check(ending_ids.size() == 3 and unique_ids.size() == 3, "the three restructuring choices should produce three distinct successful ending IDs", failures)


func _restructuring_fixture(seed: int, initial_staff_count: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, initial_staff_count)
	simulation.day = 5
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.flock_restructuring_resolved = false
	simulation.flock_restructuring_day = 0
	simulation.flock_restructuring_record.clear()
	simulation.revenue_cents = simulation.current_daily_operating_cost_cents() + 5000
	simulation.executive_confidence = 50.0
	simulation.compliance = 60.0
	simulation.solidarity = 30.0
	simulation.quota_target = initial_staff_count * 4
	for worker in simulation.workers:
		worker.morale = 40.0
		worker.manager_trust = 50.0
		worker.grievance = 20.0
		worker.stress = 30.0
		worker.fatigue = 30.0
		worker.career_xp = 0
		worker.assigned_lane = DepartmentSimulation.AUTO_ASSIGNMENT
	for worker_id in initial_staff_count:
		simulation._record_worker_shift_result(
			worker_id,
			&"sound",
			(initial_staff_count - worker_id) * 1000,
		)
	var ranking := simulation.current_pecking_order()
	simulation.last_pecking_order = ranking.duplicate(true)
	simulation.last_pecking_order_day = 4
	var candidate_id := int(ranking[ranking.size() - 1].get("worker_id", -1))
	var candidate := simulation.workers[candidate_id]
	for lane in DepartmentSimulation.CLAIM_LANES:
		if lane != candidate.specialty:
			candidate.assigned_lane = lane
			break
	simulation._prepare_credit_allocation_decision(4, ranking, 0)
	return simulation


func _assert_resolved_record(
	simulation: DepartmentSimulation,
	option_id: StringName,
	candidate_id: int,
	cost_cents: int,
	failures: Array[String],
) -> void:
	_check(simulation.flock_restructuring_resolved, "%s should mark restructuring resolved" % String(option_id), failures)
	_check(simulation.flock_restructuring_day == 4, "%s should record completed shift four" % String(option_id), failures)
	_check(simulation.pending_decision_snapshot().is_empty(), "%s should clear the pending restructuring" % String(option_id), failures)
	var record := simulation.flock_restructuring_record
	_check(StringName(record.get("decision_id", &"")) == &"flock_restructuring", "%s record should retain event identity" % String(option_id), failures)
	_check(StringName(record.get("option_id", &"")) == option_id, "%s record should retain filed choice" % String(option_id), failures)
	_check(int(record.get("worker_id", -1)) == candidate_id, "%s record should retain candidate identity" % String(option_id), failures)
	_check(int(record.get("candidate_rank", 0)) == 4, "%s record should retain the candidate's frozen rank" % String(option_id), failures)
	_check(int(record.get("candidate_credit_cents", -1)) == 1000, "%s record should retain candidate credited output" % String(option_id), failures)
	_check(int(record.get("cost_cents", -1)) == cost_cents, "%s record should retain the exact filing cost" % String(option_id), failures)
	_check(record.get("candidate_before", {}) is Dictionary and not (record.get("candidate_before", {}) as Dictionary).is_empty(), "%s record should retain pre-choice human context" % String(option_id), failures)
	_check(simulation.last_credit_allocation == _credit_record_projection(record), "%s restructuring and closing-credit ledgers should agree", failures)


func _credit_record_projection(record: Dictionary) -> Dictionary:
	var result := record.duplicate(true)
	for field in [
		"choice_label",
		"candidate_rank",
		"candidate_eggs",
		"candidate_cracked",
		"candidate_credit_cents",
		"candidate_before",
		"candidate_employed_after",
		"replacement_worker_id",
		"replacement_worker_name",
	]:
		result.erase(field)
	return result


func _worker_metrics(simulation: DepartmentSimulation) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for worker in simulation.workers:
		result.append({
			"employed": worker.employed,
			"morale": worker.morale,
			"trust": worker.manager_trust,
			"grievance": worker.grievance,
			"stress": worker.stress,
			"fatigue": worker.fatigue,
			"xp": worker.career_xp,
		})
	return result


func _same_relationship_metrics(worker: ChickenState, prior: Dictionary) -> bool:
	return (
		_approximately(worker.morale, float(prior.get("morale", 0.0)))
		and _approximately(worker.manager_trust, float(prior.get("trust", 0.0)))
		and _approximately(worker.grievance, float(prior.get("grievance", 0.0)))
	)


func _same_worker_metrics(worker: ChickenState, prior: Dictionary) -> bool:
	return (
		_same_relationship_metrics(worker, prior)
		and _approximately(worker.stress, float(prior.get("stress", 0.0)))
		and _approximately(worker.fatigue, float(prior.get("fatigue", 0.0)))
		and worker.career_xp == int(prior.get("xp", 0))
	)


func _worker_ids(ranking: Array) -> Array[int]:
	var result: Array[int] = []
	for row_value in ranking:
		result.append(int((row_value as Dictionary).get("worker_id", -1)))
	return result


func _option_ids(decision: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	for option_value in decision.get("options", []):
		result.append(StringName((option_value as Dictionary).get("id", &"")))
	return result


func _option_costs(decision: Dictionary) -> Array[int]:
	var result: Array[int] = []
	for option_value in decision.get("options", []):
		result.append(int((option_value as Dictionary).get("cost_cents", -1)))
	return result


func _style_counts(simulation: DepartmentSimulation) -> Array[int]:
	return [
		int(simulation.credit_choice_counts.get(&"individual_merit", 0)),
		int(simulation.credit_choice_counts.get(&"shared_scoop", 0)),
		int(simulation.credit_choice_counts.get(&"management_innovation", 0)),
	]


func _json_round_trip(
	state: Dictionary,
	label: String,
	failures: Array[String],
) -> Dictionary:
	var encoded := JSON.stringify(state)
	var parsed: Variant = JSON.parse_string(encoded)
	_check(parsed is Dictionary, "%s should survive JSON encoding" % label, failures)
	if not parsed is Dictionary:
		return {}
	return parsed as Dictionary


func _approximately(actual: float, expected: float, tolerance: float = 0.0001) -> bool:
	return absf(actual - expected) <= tolerance


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
