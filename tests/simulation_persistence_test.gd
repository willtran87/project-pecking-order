extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var original := DepartmentSimulation.new(9917)
	for worker_id in original.workers.size():
		original.set_worker_at_workstation(worker_id, true)
	_check(original.select_directive(&"shell_assurance"), "fixture should start the shift", failures)
	_check(original.set_worker_assignment(0, &"appeals"), "fixture should retain manual routing", failures)
	_check(original.apply_campaign_unlock(&"shell_quality_checks"), "fixture should apply a campaign unlock", failures)
	original.revenue_cents = 18000
	var personnel_result := original.perform_personnel_action(1, &"career_coaching")
	_check(bool(personnel_result.get("accepted", false)), "fixture should file a personnel action", failures)
	_check(bool(personnel_result.get("preferred", false)), "fixture action should match the worker's career profile", failures)
	_check(original.purchase_upgrade(&"peckwork_tools"), "fixture should buy a persistent requisition", failures)
	for _tick in 28:
		original.advance_tick()

	var encoded := JSON.stringify({"simulation": original.export_save_state()})
	var parsed: Variant = JSON.parse_string(encoded)
	_check(parsed is Dictionary, "checkpoint should survive JSON encoding", failures)
	var restored := DepartmentSimulation.new(44)
	var restore_ok := false
	if parsed is Dictionary:
		restore_ok = restored.restore_save_state((parsed as Dictionary).get("simulation", {}) as Dictionary)
	_check(restore_ok, "valid checkpoint should restore", failures)

	var before := original.snapshot()
	var after := restored.snapshot()
	for field in [
		"day", "minute_of_day", "claims_waiting", "claims_processed", "eggs_today",
		"eggs_total", "cracked_eggs", "revenue_cents", "quota_target",
		"shift_phase", "active_directive", "upgrade_levels", "claim_queue_counts",
		"claim_queue_items", "rework_pending_items", "lane_processed_totals",
		"campaign_unlocks", "personnel_action_available", "personnel_action_used",
		"personnel_action_status", "active_staff_count", "office_capacity",
		"wage_arrears_cents", "spendable_fund_cents", "daily_payroll_cents",
		"daily_facility_cost_cents", "daily_operating_cost_cents",
		"last_staffing_action", "staffing_catalog", "capacity_upgrade",
		"pecking_order", "last_pecking_order", "last_pecking_order_day",
		"last_credit_allocation", "credit_choice_counts", "leadership_record",
		"credit_memo_pending", "golden_dossier_resolved", "golden_dossier_day",
	]:
		var equivalent: bool = after.get(field) == before.get(field)
		if field in ["last_staffing_action", "staffing_catalog", "capacity_upgrade"]:
			equivalent = JSON.stringify(after.get(field)) == JSON.stringify(before.get(field))
		_check(equivalent, "round trip should preserve %s" % field, failures)
	var before_workers := before.get("workers", []) as Array
	var after_workers := after.get("workers", []) as Array
	_check(after_workers.size() == before_workers.size(), "round trip should preserve the flock", failures)
	for worker_index in mini(before_workers.size(), after_workers.size()):
		var expected := before_workers[worker_index] as Dictionary
		var actual := after_workers[worker_index] as Dictionary
		for field in [
			"id", "specialty", "assigned_lane", "state", "eggs_laid", "current_claim",
			"career_profile", "career_xp", "career_level", "career_title",
			"career_next_threshold", "relationship_label", "last_personnel_action",
			"last_personnel_action_day", "employed", "employment_status", "desk_index",
			"available_for_hire_day", "hire_count", "employment_start_day",
			"daily_wage_cents", "hire_cost_cents", "release_cost_cents",
			"shift_eggs", "shift_sound", "shift_cracked", "shift_golden",
			"shift_credit_cents",
		]:
			_check(actual.get(field) == expected.get(field), "worker %d should preserve %s" % [worker_index, field], failures)
		for field in [
			"skill", "accuracy", "morale", "fatigue", "stress", "progress",
			"manager_trust", "grievance", "career_progress", "career_work_multiplier",
			"career_crack_modifier",
		]:
			_check(
				is_equal_approx(float(actual.get(field, 0.0)), float(expected.get(field, 0.0))),
				"worker %d should preserve %s" % [worker_index, field],
				failures
			)

	var restored_personnel_status := after.get("personnel_action_status", {}) as Dictionary
	var restored_last_action := restored_personnel_status.get("last_action", {}) as Dictionary
	_check(bool(after.get("personnel_action_used", false)), "restored checkpoint should remember today's personnel action", failures)
	_check(not bool(after.get("personnel_action_available", true)), "restored checkpoint should keep today's action unavailable", failures)
	_check(int(restored_last_action.get("worker_id", -1)) == 1, "restored personnel status should identify the coached hen", failures)
	_check(StringName(restored_last_action.get("action_id", &"")) == &"career_coaching", "restored personnel status should identify the filed action", failures)

	# The daily guard is authoritative state, not a UI-only disabled button. A denied
	# replay after restore must leave money and both workers' personnel records intact.
	var replay_revenue_before := restored.revenue_cents
	var replay_worker_before := restored.workers[2].to_save_data()
	var filed_worker_before := restored.workers[1].to_save_data()
	var replay_result := restored.perform_personnel_action(2, &"quota_pressure")
	_check(not bool(replay_result.get("accepted", false)), "restored checkpoint should deny a second same-day personnel action", failures)
	_check(String(replay_result.get("reason", "")).contains("already filed"), "same-day replay denial should explain the global guard", failures)
	_check(restored.revenue_cents == replay_revenue_before, "denied personnel replay should not spend Feed Fund", failures)
	_check(restored.workers[2].to_save_data() == replay_worker_before, "denied replay should not mutate the targeted hen", failures)
	_check(restored.workers[1].to_save_data() == filed_worker_before, "denied replay should preserve the original personnel record", failures)

	# The RNG states are serialized as decimal strings so a Web JSON round trip
	# cannot lose 64-bit precision. Advancing both copies must stay deterministic.
	for worker_id in original.workers.size():
		original.set_worker_at_workstation(worker_id, true)
		restored.set_worker_at_workstation(worker_id, true)
	for _tick in 36:
		original.advance_tick()
		restored.advance_tick()
	var deterministic_a := original.snapshot()
	var deterministic_b := restored.snapshot()
	for field in [
		"minute_of_day", "claims_processed", "eggs_today", "cracked_today", "golden_today",
		"revenue_cents", "claim_queue_items", "lane_processed_today",
		"personnel_action_available", "personnel_action_used", "personnel_action_status",
		"pecking_order", "last_pecking_order", "last_credit_allocation",
		"credit_choice_counts", "leadership_record", "credit_memo_pending",
	]:
		_check(deterministic_b.get(field) == deterministic_a.get(field), "restored simulation should remain deterministic for %s" % field, failures)
	var deterministic_workers_a := deterministic_a.get("workers", []) as Array
	var deterministic_workers_b := deterministic_b.get("workers", []) as Array
	for worker_index in mini(deterministic_workers_a.size(), deterministic_workers_b.size()):
		var expected := deterministic_workers_a[worker_index] as Dictionary
		var actual := deterministic_workers_b[worker_index] as Dictionary
		for field in [
			"career_xp", "career_level", "last_personnel_action", "last_personnel_action_day",
			"employed", "employment_status", "desk_index", "available_for_hire_day",
			"hire_count", "employment_start_day", "daily_wage_cents",
		]:
			_check(actual.get(field) == expected.get(field), "deterministic worker %d should preserve %s" % [worker_index, field], failures)
		for field in ["manager_trust", "grievance", "career_work_multiplier", "career_crack_modifier"]:
			_check(
				is_equal_approx(float(actual.get(field, 0.0)), float(expected.get(field, 0.0))),
				"deterministic worker %d should preserve %s" % [worker_index, field],
				failures
			)

	# A reduced office keeps all six stable identities, persists applicants and a
	# same-review capacity/hire transaction, and reserves wage arrears exactly.
	var staffing_original := DepartmentSimulation.new(6221, 4)
	var staffing_report := _complete_shift(staffing_original, failures)
	_check(not staffing_report.is_empty(), "staffing persistence fixture should enter review", failures)
	staffing_original.revenue_cents = 10000
	var capacity_result := staffing_original.purchase_staff_capacity()
	var hire_result := staffing_original.hire_worker(4)
	_check(bool(capacity_result.get("accepted", false)), "staffing persistence fixture should expand to five desks", failures)
	_check(bool(hire_result.get("accepted", false)), "staffing persistence fixture should hire worker four", failures)
	staffing_original.wage_arrears_cents = 725
	var staffing_state := staffing_original.export_save_state()
	var staffing_encoded := JSON.stringify({"simulation": staffing_state})
	var staffing_parsed: Variant = JSON.parse_string(staffing_encoded)
	var staffing_restored := DepartmentSimulation.new(6222, 4)
	var staffing_restore_ok := false
	if staffing_parsed is Dictionary:
		staffing_restore_ok = staffing_restored.restore_save_state(
			(staffing_parsed as Dictionary).get("simulation", {}) as Dictionary
		)
	_check(staffing_restore_ok, "staffing checkpoint should survive a primitive JSON round trip", failures)
	_check(staffing_restored.office_capacity == 5, "round trip should preserve capacity five", failures)
	_check(staffing_restored.active_worker_count() == 5, "round trip should preserve five active hens", failures)
	_check(staffing_restored.wage_arrears_cents == 725, "round trip should preserve exact wage arrears", failures)
	for field in [
		"day", "cost_cents", "worker_id", "worker_name", "desk_index",
		"active_staff_count", "office_capacity", "daily_wage_cents",
		"spendable_fund_cents",
	]:
		_check(
			staffing_restored.last_staffing_action.get(field) == staffing_original.last_staffing_action.get(field),
			"round trip should preserve staffing cooldown %s" % field,
			failures
		)
	_check(
		StringName(staffing_restored.last_staffing_action.get("action_id", &""))
		== StringName(staffing_original.last_staffing_action.get("action_id", &"")),
		"round trip should preserve staffing cooldown action_id",
		failures
	)
	_check(staffing_restored.spendable_fund_cents() == staffing_original.spendable_fund_cents(), "round trip should preserve spendable reserves", failures)
	var staffing_expected_workers := staffing_original.export_save_state().get("workers", []) as Array
	var staffing_actual_workers := staffing_restored.export_save_state().get("workers", []) as Array
	for worker_index in mini(staffing_expected_workers.size(), staffing_actual_workers.size()):
		var expected_worker := staffing_expected_workers[worker_index] as Dictionary
		var actual_worker := staffing_actual_workers[worker_index] as Dictionary
		for field in [
			"employed", "employment_status", "desk_index", "available_for_hire_day",
			"hire_count", "employment_start_day",
		]:
			_check(actual_worker.get(field) == expected_worker.get(field), "staffing worker %d should preserve %s" % [worker_index, field], failures)
	_check(staffing_restored.workers[4].employed and staffing_restored.workers[4].desk_index == 4, "hired worker should restore at desk four", failures)
	_check(not staffing_restored.workers[5].employed and staffing_restored.workers[5].desk_index == -1, "unhired applicant should restore without a desk", failures)

	# Build an authentic v2 payload by removing every staffing field. Migration
	# must grandfather the historical six-hen roster without inventing arrears.
	var legacy_v2 := DepartmentSimulation.new(8112).export_save_state().duplicate(true)
	legacy_v2["state_version"] = 2
	for field in ["office_capacity", "wage_arrears_cents", "last_staffing_action"]:
		legacy_v2.erase(field)
	for worker_value in legacy_v2.get("workers", []) as Array:
		var legacy_v2_worker := worker_value as Dictionary
		for field in [
			"employed", "employment_status", "available_for_hire_day", "hire_count",
			"employment_start_day",
		]:
			legacy_v2_worker.erase(field)
	var legacy_v2_restored := DepartmentSimulation.new(8113, 4)
	_check(legacy_v2_restored.restore_save_state(legacy_v2), "legacy v2 checkpoint should migrate to v3 staffing", failures)
	_check(legacy_v2_restored.active_worker_count() == 6, "v2 migration should grandfather all six historical hens", failures)
	_check(legacy_v2_restored.office_capacity == 6, "v2 migration should grandfather capacity six", failures)
	_check(legacy_v2_restored.wage_arrears_cents == 0, "v2 migration should not invent arrears", failures)
	_check(legacy_v2_restored.last_staffing_action.is_empty(), "v2 migration should not invent a staffing cooldown", failures)
	for worker_id in legacy_v2_restored.workers.size():
		var migrated_legacy_worker := legacy_v2_restored.workers[worker_id]
		_check(migrated_legacy_worker.employed, "v2 worker %d should remain employed" % worker_id, failures)
		_check(migrated_legacy_worker.employment_status() == &"employed", "v2 worker %d should receive employed status" % worker_id, failures)
		_check(migrated_legacy_worker.desk_index == worker_id, "v2 worker %d should retain her desk" % worker_id, failures)
		_check(migrated_legacy_worker.available_for_hire_day == 0, "v2 worker %d should not receive applicant availability" % worker_id, failures)
		_check(migrated_legacy_worker.hire_count == 0, "v2 worker %d should receive zero historical hires" % worker_id, failures)
	_check(int(legacy_v2_restored.export_save_state().get("state_version", -1)) == 7, "v2 migration should chain through the neutral cross-training schema v7", failures)

	# An authentic v3 staffing checkpoint has no worker shift attribution or
	# closing-credit history. Migration must initialize the new ledgers honestly
	# instead of inventing historical per-hen quality.
	var legacy_v3 := staffing_original.export_save_state().duplicate(true)
	legacy_v3["state_version"] = 3
	legacy_v3["pending_decision"] = {}
	for field in [
		"worker_shift_stats", "last_pecking_order", "last_pecking_order_day",
		"last_credit_allocation", "credit_choice_counts",
		"golden_dossier_resolved", "golden_dossier_day",
	]:
		legacy_v3.erase(field)
	var legacy_v3_restored := DepartmentSimulation.new(8114, 4)
	_check(legacy_v3_restored.restore_save_state(legacy_v3), "legacy v3 checkpoint should migrate through credit, assist, and flock ledgers into v6", failures)
	var legacy_v3_snapshot := legacy_v3_restored.snapshot()
	_check((legacy_v3_snapshot.get("last_pecking_order", []) as Array).is_empty(), "v3 migration should not invent a historical ranking", failures)
	_check((legacy_v3_snapshot.get("last_credit_allocation", {}) as Dictionary).is_empty(), "v3 migration should not invent a credit choice", failures)
	_check(not bool(legacy_v3_snapshot.get("credit_memo_pending", true)), "v3 migration should not invent a pending memo", failures)
	_check(int(legacy_v3_restored.export_save_state().get("state_version", -1)) == 7, "v3 migration should export schema v7", failures)
	for worker_value in legacy_v3_snapshot.get("workers", []) as Array:
		var migrated_v3_worker := worker_value as Dictionary
		_check(int(migrated_v3_worker.get("shift_eggs", -1)) == 0, "v3 migration should start worker shift attribution at zero", failures)

	# An authentic v4 checkpoint predates Peck Assist. Migration must initialize
	# every assist ledger to a neutral value without disturbing the v4 state.
	var legacy_v4 := staffing_original.export_save_state().duplicate(true)
	legacy_v4["state_version"] = 4
	for field in [
		"peck_assists_used_today", "peck_assist_streak", "best_peck_assist_streak",
		"last_peck_assist", "priority_credit_today_cents", "priority_credit_total_cents",
		"assisted_claim_ids", "missed_assist_claim_ids", "assist_quality_modifiers",
		"assist_chain_by_claim_id",
	]:
		legacy_v4.erase(field)
	var legacy_v4_restored := DepartmentSimulation.new(8115, 4)
	_check(legacy_v4_restored.restore_save_state(legacy_v4), "legacy v4 checkpoint should migrate to v5 Peck Assist ledgers", failures)
	var migrated_v4_state := legacy_v4_restored.export_save_state()
	_check(int(migrated_v4_state.get("state_version", -1)) == 7, "v4 migration should export schema v7", failures)
	_check(legacy_v4_restored.peck_assists_used_today == 0, "v4 migration should not invent used assists", failures)
	_check(legacy_v4_restored.peck_assist_streak == 0, "v4 migration should start the assist streak at zero", failures)
	_check(legacy_v4_restored.best_peck_assist_streak == 0, "v4 migration should start the best assist streak at zero", failures)
	_check(legacy_v4_restored.last_peck_assist.is_empty(), "v4 migration should not invent a last assist", failures)
	_check(legacy_v4_restored.priority_credit_today_cents == 0, "v4 migration should not invent today's priority credit", failures)
	_check(legacy_v4_restored.priority_credit_total_cents == 0, "v4 migration should not invent historical priority credit", failures)
	for field in ["assisted_claim_ids", "missed_assist_claim_ids"]:
		_check((migrated_v4_state.get(field, []) as Array).is_empty(), "v4 migration should initialize %s empty" % field, failures)
	for field in ["assist_quality_modifiers", "assist_chain_by_claim_id"]:
		_check((migrated_v4_state.get(field, {}) as Dictionary).is_empty(), "v4 migration should initialize %s empty" % field, failures)

	# Schema v5 predates named petitions. Migration must be wholly neutral: no
	# sponsor, promise, breach receipt, or collective action may be invented.
	var legacy_v5 := staffing_original.export_save_state().duplicate(true)
	legacy_v5["state_version"] = 5
	for field in [
		"last_flock_petition", "flock_petition_history", "active_flock_compact",
		"last_flock_compact_receipt", "work_to_rule_day", "last_work_to_rule_record",
		"queued_work_to_rule_day", "queued_work_to_rule_record",
	]:
		legacy_v5.erase(field)
	var legacy_v5_restored := DepartmentSimulation.new(8116, 4)
	_check(legacy_v5_restored.restore_save_state(legacy_v5), "legacy v5 checkpoint should migrate neutrally to v6", failures)
	var migrated_v5_state := legacy_v5_restored.export_save_state()
	_check(int(migrated_v5_state.get("state_version", -1)) == 7, "v5 migration should export schema v7", failures)
	for field in [
		"last_flock_petition", "active_flock_compact", "last_flock_compact_receipt",
		"last_work_to_rule_record", "queued_work_to_rule_record",
	]:
		_check((migrated_v5_state.get(field, {}) as Dictionary).is_empty(), "v5 migration should keep %s empty" % field, failures)
	_check((migrated_v5_state.get("flock_petition_history", []) as Array).is_empty(), "v5 migration should not invent petition history", failures)
	_check(int(migrated_v5_state.get("work_to_rule_day", -1)) == 0, "v5 migration should not schedule work-to-rule", failures)
	_check(int(migrated_v5_state.get("queued_work_to_rule_day", -1)) == 0, "v5 migration should not queue work-to-rule", failures)

	# Build an authentic legacy checkpoint by deleting every field that did not
	# exist in v1. Migration must chain through every schema and reopen today's action.
	var legacy_state := original.export_save_state().duplicate(true)
	legacy_state["state_version"] = 1
	for field in ["office_capacity", "wage_arrears_cents", "last_staffing_action"]:
		legacy_state.erase(field)
	var legacy_worker_values := legacy_state.get("workers", []) as Array
	var legacy_expected_eggs: Array[int] = []
	for worker_index in legacy_worker_values.size():
		var legacy_worker := legacy_worker_values[worker_index] as Dictionary
		legacy_expected_eggs.append(maxi(0, int(legacy_worker.get("eggs_laid", 0))))
		for field in [
			"career_profile", "manager_trust", "grievance", "career_xp",
			"last_personnel_action", "last_personnel_action_day", "employed",
			"employment_status", "available_for_hire_day", "hire_count",
			"employment_start_day",
		]:
			legacy_worker.erase(field)
	var legacy_restored := DepartmentSimulation.new(1201)
	_check(legacy_restored.restore_save_state(legacy_state), "legacy v1 checkpoint should chain through v2 into v3", failures)
	var legacy_snapshot := legacy_restored.snapshot()
	var migrated_workers := legacy_snapshot.get("workers", []) as Array
	_check(migrated_workers.size() == legacy_expected_eggs.size(), "legacy migration should preserve every worker", failures)
	for worker_index in mini(migrated_workers.size(), legacy_expected_eggs.size()):
		var migrated_worker := migrated_workers[worker_index] as Dictionary
		_check(
			StringName(migrated_worker.get("career_profile", &"")) == ChickenState.default_career_profile(worker_index),
			"legacy worker %d should receive the fixed career profile" % worker_index,
			failures
		)
		_check(is_equal_approx(float(migrated_worker.get("manager_trust", 0.0)), 58.0), "legacy worker %d should start with trust 58" % worker_index, failures)
		_check(is_equal_approx(float(migrated_worker.get("grievance", 0.0)), 6.0), "legacy worker %d should start with grievance 6" % worker_index, failures)
		_check(int(migrated_worker.get("career_xp", -1)) == legacy_expected_eggs[worker_index] * 3, "legacy worker %d should derive XP from eggs laid" % worker_index, failures)
		_check(StringName(migrated_worker.get("last_personnel_action", &"")) == &"", "legacy worker %d should have no filed action" % worker_index, failures)
		_check(int(migrated_worker.get("last_personnel_action_day", -1)) == 0, "legacy worker %d should have no personnel action day" % worker_index, failures)
	_check(bool(legacy_snapshot.get("personnel_action_available", false)), "legacy migration should make today's personnel action available", failures)
	_check(not bool(legacy_snapshot.get("personnel_action_used", true)), "legacy migration should not invent a personnel action", failures)
	_check(legacy_restored.active_worker_count() == 6 and legacy_restored.office_capacity == 6, "v1 migration should inherit the v2 six-hen grandfather rule", failures)
	_check(legacy_restored.wage_arrears_cents == 0, "v1 migration should not invent wage arrears", failures)
	_check(int(legacy_restored.export_save_state().get("state_version", -1)) == 7, "migrated checkpoints should export as schema v7", failures)

	# Employment/capacity invariants fail closed before mutating the fallback.
	var invalid_fallback := DepartmentSimulation.new(7331, 4)
	var invalid_fallback_before := invalid_fallback.export_save_state().duplicate(true)
	var invalid_capacity := staffing_state.duplicate(true)
	invalid_capacity["office_capacity"] = 4
	_check(not invalid_fallback.restore_save_state(invalid_capacity), "save with more employed hens than capacity should fail closed", failures)
	_check(invalid_fallback.export_save_state() == invalid_fallback_before, "capacity rejection should preserve the fallback exactly", failures)
	var invalid_status := staffing_state.duplicate(true)
	var invalid_status_workers := invalid_status.get("workers", []) as Array
	(invalid_status_workers[4] as Dictionary)["employment_status"] = "applicant"
	_check(not invalid_fallback.restore_save_state(invalid_status), "save with mismatched employment status should fail closed", failures)
	_check(invalid_fallback.export_save_state() == invalid_fallback_before, "status rejection should preserve the fallback exactly", failures)
	var duplicate_desk := staffing_state.duplicate(true)
	var duplicate_desk_workers := duplicate_desk.get("workers", []) as Array
	(duplicate_desk_workers[4] as Dictionary)["desk_index"] = 0
	_check(not invalid_fallback.restore_save_state(duplicate_desk), "save with duplicate occupied desk should fail closed", failures)
	_check(invalid_fallback.export_save_state() == invalid_fallback_before, "desk rejection should preserve the fallback exactly", failures)

	var rejected := DepartmentSimulation.new()
	var invalid := original.export_save_state()
	invalid["state_version"] = DepartmentSimulation.SAVE_STATE_VERSION + 1
	_check(not rejected.restore_save_state(invalid), "future simulation schema should fail closed", failures)
	_check(int(rejected.snapshot().get("day", -1)) == 1, "failed restore should leave the fallback session intact", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("SIMULATION_PERSISTENCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SIMULATION_PERSISTENCE_TEST_PASSED json=round-trip rng=deterministic personnel=guarded staffing=exact migration=v1-v2-v3-v4-v5-v6-to-v7 validation=employment-capacity-credit-assist-flock-training")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _complete_shift(simulation: DepartmentSimulation, failures: Array[String]) -> Dictionary:
	var report_box := {"report": {}}
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		report_box["report"] = report.duplicate(true)
	, CONNECT_ONE_SHOT)
	if simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE:
		_check(simulation.select_directive(&"shell_assurance"), "persistence fixture should authorize its directive", failures)
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
		_check(
			simulation.resolve_decision(serial, StringName(option.get("id", &""))),
			"persistence fixture should resolve its free incident branch",
			failures
		)
		return
	_check(false, "persistence fixture should find a free incident branch", failures)
