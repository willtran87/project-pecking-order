extends SceneTree


const FACILITY_ID: StringName = &"candling_rework_bay"
const CAPITAL_COST_CENTS := 4000
const MAINTENANCE_CENTS := 300


func _init() -> void:
	var failures: Array[String] = []
	_test_catalog_and_atomic_purchase_guards(failures)
	_test_authoritative_costs_and_effects(failures)
	_test_persistence_migration_and_corruption(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("FACILITY_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FACILITY_ECONOMY_TEST_PASSED catalog=thirteen-module purchase=atomic reserve=maintenance effects=derived persistence=v20-v7")
	quit(0)


func _test_catalog_and_atomic_purchase_guards(failures: Array[String]) -> void:
	var locked := DepartmentSimulation.new(8101, 4)
	locked.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	locked.pending_decision.clear()
	locked.revenue_cents = 100_000
	var catalog := locked.facility_catalog()
	_check(catalog.size() == 13, "capital catalog should expose all thirteen authored facilities", failures)
	if not catalog.is_empty():
		var row := catalog[0]
		for field in [
			"id", "name", "short_name", "description", "cost_cents",
			"daily_maintenance_cents", "benefits", "owned", "unlocked",
			"planning_open", "affordable", "can_purchase", "reason",
			"projected_spendable_fund_cents",
		]:
			_check(row.has(field), "catalog row should expose %s" % field, failures)
		_check(StringName(row.get("id", &"")) == FACILITY_ID, "catalog should use the stable facility id", failures)
		_check(int(row.get("cost_cents", -1)) == CAPITAL_COST_CENTS, "catalog should quote the exact $40 capital price", failures)
		_check(int(row.get("daily_maintenance_cents", -1)) == MAINTENANCE_CENTS, "catalog should quote the exact $3 maintenance", failures)
		_check((row.get("benefits", []) as Array).size() == 2, "catalog should disclose both causal benefits", failures)
		_check(not bool(row.get("unlocked", true)) and not bool(row.get("can_purchase", true)), "Shell Quality Checks should gate the facility", failures)

	_expect_rejected_atomic(
		locked,
		func() -> Dictionary: return locked.purchase_facility(FACILITY_ID),
		"locked facility purchase",
		failures,
	)
	_expect_rejected_atomic(
		locked,
		func() -> Dictionary: return locked.purchase_facility(&"unlisted_barn"),
		"unknown facility purchase",
		failures,
	)

	var wrong_phase := DepartmentSimulation.new(8102, 4)
	wrong_phase.apply_campaign_unlock(&"shell_quality_checks")
	wrong_phase.pending_decision.clear()
	wrong_phase.revenue_cents = 100_000
	_expect_rejected_atomic(
		wrong_phase,
		func() -> Dictionary: return wrong_phase.purchase_facility(FACILITY_ID),
		"non-review facility purchase",
		failures,
	)

	var short := DepartmentSimulation.new(8103, 4)
	short.apply_campaign_unlock(&"shell_quality_checks")
	short.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	short.pending_decision.clear()
	# The purchase must protect the maintenance obligation it creates. One cent
	# below capital plus the revised reserve is therefore an atomic rejection.
	short.revenue_cents = (
		short.current_daily_operating_cost_cents()
		+ CAPITAL_COST_CENTS
		+ MAINTENANCE_CENTS
		- 1
	)
	_expect_rejected_atomic(
		short,
		func() -> Dictionary: return short.purchase_facility(FACILITY_ID),
		"one-cent-short facility purchase",
		failures,
	)

	var simulation := _purchase_ready_simulation(8104, failures)
	var observed := {"count": 0, "id": &"", "level": 0, "cost": 0}
	simulation.facility_purchased.connect(func(facility_id: StringName, level: int, cost_cents: int) -> void:
		observed["count"] = int(observed["count"]) + 1
		observed["id"] = facility_id
		observed["level"] = level
		observed["cost"] = cost_cents
	)
	var fund_before := simulation.revenue_cents
	var purchase := simulation.purchase_facility(FACILITY_ID)
	_check(bool(purchase.get("accepted", false)), "unlocked review should commission the facility", failures)
	_check(StringName(purchase.get("action_id", &"")) == &"purchase_facility", "receipt should identify the authoritative action", failures)
	_check(int(purchase.get("cost_cents", -1)) == CAPITAL_COST_CENTS, "receipt should debit exactly $40 capital", failures)
	_check(simulation.revenue_cents == fund_before - CAPITAL_COST_CENTS, "accepted purchase should deduct capital exactly once", failures)
	_check(simulation.facility_level(FACILITY_ID) == 1 and simulation.has_facility(FACILITY_ID), "accepted purchase should own level one", failures)
	_check(observed == {"count": 1, "id": FACILITY_ID, "level": 1, "cost": CAPITAL_COST_CENTS}, "accepted purchase should emit one exact signal receipt", failures)
	_check(simulation.spendable_fund_cents() == 0, "exact capital-plus-maintenance fixture should preserve the complete revised reserve", failures)
	_expect_rejected_atomic(
		simulation,
		func() -> Dictionary: return simulation.purchase_facility(FACILITY_ID),
		"duplicate facility purchase",
		failures,
	)


func _test_authoritative_costs_and_effects(failures: Array[String]) -> void:
	var baseline := DepartmentSimulation.new(8201, 4)
	var improved := _purchase_ready_simulation(8201, failures)
	baseline.apply_campaign_unlock(&"shell_quality_checks")
	_check(bool(improved.purchase_facility(FACILITY_ID).get("accepted", false)), "effect fixture should own the bay", failures)
	_check(improved.daily_facility_expansion_cost_cents() == 0, "four-desk office should have no seat expansion charge", failures)
	_check(improved.current_daily_facility_maintenance_cents() == MAINTENANCE_CENTS, "bay should add exactly $3 daily maintenance", failures)
	_check(improved.current_daily_facility_cost_cents() == MAINTENANCE_CENTS, "facility total should include bay maintenance", failures)
	_check(improved.current_daily_operating_cost_cents() == baseline.current_daily_operating_cost_cents() + MAINTENANCE_CENTS, "bay maintenance should enter protected operating obligations", failures)

	_stage_claim(baseline, false, 9001)
	_stage_claim(improved, false, 9001)
	baseline.advance_tick()
	improved.advance_tick()
	_check(is_equal_approx(improved.workers[0].work_progress, baseline.workers[0].work_progress), "bay must not accelerate original claims", failures)

	_stage_claim(baseline, true, 9002)
	_stage_claim(improved, true, 9002)
	var baseline_risk := baseline.estimated_crack_risk(0)
	var improved_risk := improved.estimated_crack_risk(0)
	_check(is_equal_approx(baseline_risk - improved_risk, 0.015), "bay should apply exactly -1.5% additional crack risk", failures)
	_check(int(baseline.campaign_unlock_effects().get("crack_risk_basis_points", 0)) == -250, "existing Shell Quality Checks milestone should remain exactly -2.5%", failures)
	baseline.advance_tick()
	improved.advance_tick()
	_check(is_equal_approx(improved.workers[0].work_progress, baseline.workers[0].work_progress * 1.20), "bay should accelerate rework by exactly 20%", failures)

	var snapshot := improved.snapshot()
	var effects := snapshot.get("facility_effects", {}) as Dictionary
	_check(int(effects.get("crack_risk_basis_points", 0)) == -150, "snapshot should expose the exact facility crack modifier", failures)
	_check(is_equal_approx(float(effects.get("rework_speed_multiplier", 0.0)), 1.20), "snapshot should expose the exact rework multiplier", failures)
	_check(int(snapshot.get("daily_facility_expansion_cost_cents", -1)) == 0, "snapshot should separate seat expansion cost", failures)
	_check(int(snapshot.get("daily_facility_maintenance_cents", -1)) == MAINTENANCE_CENTS, "snapshot should separate facility maintenance", failures)
	_check(int((snapshot.get("owned_facilities", {}) as Dictionary).get(FACILITY_ID, 0)) == 1, "snapshot should expose persistent owned level", failures)
	var workers := snapshot.get("workers", []) as Array
	if not workers.is_empty():
		var current_claim := (workers[0] as Dictionary).get("current_claim", {}) as Dictionary
		_check(is_equal_approx(float(current_claim.get("facility_speed_multiplier", 0.0)), 1.20), "active rework should disclose its facility multiplier", failures)

	# Complete a fresh owned shift so the closing ledger proves maintenance is
	# charged, not merely displayed in a planning snapshot.
	var closing := _purchase_ready_simulation(8202, failures)
	_check(bool(closing.purchase_facility(FACILITY_ID).get("accepted", false)), "closing fixture should own the bay", failures)
	var report := _complete_owned_shift(closing, failures)
	_check(int(report.get("facility_expansion_cost_cents", -1)) == 0, "closing report should separate zero seat cost", failures)
	_check(int(report.get("facility_maintenance_cents", -1)) == MAINTENANCE_CENTS, "closing report should charge exact bay maintenance", failures)
	_check(int(report.get("facility_cost_cents", -1)) == MAINTENANCE_CENTS, "closing facility total should include maintenance", failures)
	_check(int(report.get("operating_cost_cents", -1)) >= MAINTENANCE_CENTS, "closing operating total should include the facility sink", failures)


func _test_persistence_migration_and_corruption(failures: Array[String]) -> void:
	var purchased := _purchase_ready_simulation(8301, failures)
	_check(bool(purchased.purchase_facility(FACILITY_ID).get("accepted", false)), "persistence fixture should own the bay", failures)
	var state := purchased.export_save_state()
	_check(int(state.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "facility checkpoints should export the current schema", failures)
	_check(int((state.get("owned_facilities", {}) as Dictionary).get(String(FACILITY_ID), 0)) == 1, "current schema should serialize the owned level with a primitive key", failures)
	var parsed: Variant = JSON.parse_string(JSON.stringify(state))
	_check(parsed is Dictionary, "facility checkpoint should remain primitive JSON", failures)
	if parsed is Dictionary:
		var restored := DepartmentSimulation.new(8302, 4)
		_check(restored.restore_save_state(parsed as Dictionary), "current-schema JSON round trip should restore", failures)
		_check(restored.has_facility(FACILITY_ID), "round trip should preserve ownership", failures)
		_check(restored.current_daily_facility_maintenance_cents() == MAINTENANCE_CENTS, "round trip should restore maintenance liability", failures)
		_check(restored.facility_effects() == purchased.facility_effects(), "round trip should restore deterministic effects", failures)

	var legacy_v7 := DepartmentSimulation.new(8303, 4).export_save_state()
	legacy_v7["state_version"] = 7
	legacy_v7.erase("owned_facilities")
	var migrated := DepartmentSimulation.new(8304, 4)
	_check(migrated.restore_save_state(legacy_v7), "schema v7 should migrate with an empty facility ledger", failures)
	_check(not migrated.has_facility(FACILITY_ID), "v7 migration must not invent facility ownership", failures)
	_check(migrated.current_daily_facility_maintenance_cents() == 0, "v7 migration must not invent maintenance", failures)
	_check(int(migrated.export_save_state().get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "migrated checkpoint should re-export the current schema", failures)

	var valid_unowned := DepartmentSimulation.new(8305, 4).export_save_state()
	var corrupt_ledgers: Array[Dictionary] = [
		{},
		{"unlisted_barn": 0},
		{String(FACILITY_ID): -1},
		{String(FACILITY_ID): 2},
		{String(FACILITY_ID): 0.5},
		{String(FACILITY_ID): "1"},
	]
	for corrupt_ledger in corrupt_ledgers:
		var corrupt := valid_unowned.duplicate(true)
		corrupt["owned_facilities"] = corrupt_ledger
		_expect_restore_rejected_atomic(corrupt, failures)

	var corrupt_gate := state.duplicate(true)
	var unlocks := (corrupt_gate.get("campaign_unlocks", {}) as Dictionary).duplicate(true)
	unlocks["shell_quality_checks"] = false
	corrupt_gate["campaign_unlocks"] = unlocks
	_expect_restore_rejected_atomic(corrupt_gate, failures)


func _purchase_ready_simulation(seed: int, failures: Array[String]) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 4)
	_check(simulation.apply_campaign_unlock(&"shell_quality_checks"), "fixture should unlock Shell Quality Checks", failures)
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = (
		simulation.current_daily_operating_cost_cents()
		+ simulation.wage_arrears_cents
		+ CAPITAL_COST_CENTS
		+ MAINTENANCE_CENTS
	)
	var preflight := simulation.facility_purchase_preflight(FACILITY_ID)
	_check(bool(preflight.get("can_purchase", false)), "funded review fixture should pass facility preflight", failures)
	_check(int(preflight.get("projected_spendable_fund_cents", -1)) == 0, "preflight should project the revised protected reserve exactly", failures)
	return simulation


func _stage_claim(simulation: DepartmentSimulation, rework: bool, claim_id: int) -> void:
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	var worker := simulation.workers[0]
	worker.current_claim = ClaimState.new(
		claim_id,
		&"nest_damage",
		"NEST DAMAGE REWORK" if rework else "NEST DAMAGE",
		1.0,
		360,
		0.0,
		0,
		180,
		180,
		rework,
		claim_id - 1 if rework else -1,
		simulation.day,
		1 if rework else 0,
	)
	worker.work_state = ChickenState.WorkState.WORKING
	worker.work_progress = 0.0
	worker.fatigue = 0.0
	worker.stress = 0.0
	worker.morale = 70.0
	simulation.set_worker_at_workstation(worker.id, true)


func _complete_owned_shift(simulation: DepartmentSimulation, failures: Array[String]) -> Dictionary:
	# This focused fixture opens REVIEW directly; discard the constructor's
	# untouched day-one directive before asking the review API for a fresh one.
	simulation.pending_decision.clear()
	_check(simulation.begin_next_shift_briefing(), "owned review should open the next briefing", failures)
	_check(simulation.select_directive(&"shell_assurance"), "owned fixture should authorize Shell Assurance", failures)
	var report_box := {"report": {}}
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		report_box["report"] = report.duplicate(true)
	, CONNECT_ONE_SHOT)
	for worker in simulation.workers:
		simulation.set_worker_at_workstation(worker.id, worker.employed)
	for _tick in 360:
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
		_check(simulation.resolve_decision(serial, StringName(option.get("id", &""))), "fixture should resolve a free incident branch", failures)
		return
	_check(false, "facility fixture incident should expose a free branch", failures)


func _expect_rejected_atomic(
	simulation: DepartmentSimulation,
	action: Callable,
	message: String,
	failures: Array[String]
) -> void:
	var before := simulation.export_save_state().duplicate(true)
	var result: Dictionary = action.call()
	_check(not bool(result.get("accepted", false)), "%s should reject" % message, failures)
	_check(not String(result.get("reason", "")).is_empty(), "%s should explain its rejection" % message, failures)
	_check(simulation.export_save_state() == before, "%s must preserve complete authoritative state" % message, failures)


func _expect_restore_rejected_atomic(corrupt: Dictionary, failures: Array[String]) -> void:
	var fallback := DepartmentSimulation.new(8399, 4)
	var before := fallback.export_save_state().duplicate(true)
	_check(not fallback.restore_save_state(corrupt), "corrupt facility ledger should fail closed", failures)
	_check(fallback.export_save_state() == before, "corrupt facility restore must preserve the fallback session", failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
