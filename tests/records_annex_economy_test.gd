extends SceneTree


const FACILITY_ID: StringName = &"records_annex"
const LEVEL_COSTS: Array[int] = [7000, 10500, 15500]
const LEVEL_MAINTENANCE: Array[int] = [0, 400, 700, 1100]
const CLAIM_CAPACITIES: Array[int] = [18, 24, 30, 36]


func _init() -> void:
	var failures: Array[String] = []
	_test_unlock_reserve_and_tiered_capacity(failures)
	_test_rejected_intake_is_recorded_without_minting_cash(failures)
	_test_persistence_and_v10_migration(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("RECORDS_ANNEX_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("RECORDS_ANNEX_ECONOMY_TEST_PASSED unlock=day3 tiers=3 reserve=delta capacity=18-36 intake=ledger-only persistence=v23-v10 campus+treasury=neutral")
	quit(0)


func _test_unlock_reserve_and_tiered_capacity(failures: Array[String]) -> void:
	var locked := DepartmentSimulation.new(9401, 4)
	locked.day = 2
	locked.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	locked.pending_decision.clear()
	locked.revenue_cents = 100_000
	var locked_status := locked.facility_status(FACILITY_ID)
	_check(bool(locked_status.get("known", false)), "Records Annex should be an authored capital facility", failures)
	_check(not bool(locked_status.get("unlocked", true)), "Records Annex should remain locked until day three", failures)
	_check(int(locked_status.get("unlock_day", -1)) == 3, "Records Annex should disclose its day-three gate", failures)
	_check("two shifts" in String(locked_status.get("reason", "")).to_lower(), "locked Records Annex should explain the two-shift requirement", failures)
	_check(locked.current_claim_capacity() == CLAIM_CAPACITIES[0], "an unbuilt annex should retain the base 18-file capacity", failures)
	_expect_purchase_rejected_atomic(locked, "locked day-two Records Annex", failures)

	var one_cent_short := _ready_simulation(9402)
	one_cent_short.revenue_cents = (
		one_cent_short.current_daily_operating_cost_cents()
		+ LEVEL_COSTS[0]
		+ LEVEL_MAINTENANCE[1]
		- 1
	)
	var short_status := one_cent_short.facility_status(FACILITY_ID)
	_check(int(short_status.get("projected_spendable_fund_cents", 0)) == -1, "level one preflight should expose the exact one-cent reserve deficit", failures)
	_expect_purchase_rejected_atomic(one_cent_short, "one-cent-short Records Annex", failures)

	var simulation := _ready_simulation(9403)
	var observed_levels: Array[int] = []
	simulation.facility_purchased.connect(func(id: StringName, level: int, _cost: int) -> void:
		if id == FACILITY_ID:
			observed_levels.append(level)
	)
	for level in range(1, 4):
		var maintenance_delta := LEVEL_MAINTENANCE[level] - LEVEL_MAINTENANCE[level - 1]
		simulation.revenue_cents = (
			simulation.current_daily_operating_cost_cents()
			+ LEVEL_COSTS[level - 1]
			+ maintenance_delta
		)
		var preflight := simulation.facility_status(FACILITY_ID)
		_check(int(preflight.get("level", -1)) == level - 1, "tier %d preflight should expose the current tier" % level, failures)
		_check(int(preflight.get("next_level", -1)) == level, "tier %d preflight should expose the next tier" % level, failures)
		_check(int(preflight.get("max_level", -1)) == 3, "Records Annex should expose exactly three authored tiers", failures)
		_check(int(preflight.get("next_level_cost_cents", -1)) == LEVEL_COSTS[level - 1], "tier %d should quote its exact capital cost" % level, failures)
		_check(int(preflight.get("maintenance_delta_cents", -1)) == maintenance_delta, "tier %d should reserve only its exact upkeep increase" % level, failures)
		_check(int(preflight.get("current_claim_capacity", -1)) == CLAIM_CAPACITIES[level - 1], "tier %d preflight should disclose current file capacity" % level, failures)
		_check(int(preflight.get("next_claim_capacity", -1)) == CLAIM_CAPACITIES[level], "tier %d preflight should disclose the next six file slots" % level, failures)
		_check(int(preflight.get("claim_capacity_delta", -1)) == 6, "every Records Annex tier should add exactly six file slots", failures)
		_check(int(preflight.get("projected_spendable_fund_cents", -1)) == 0, "tier %d exact fixture should project zero free cash" % level, failures)
		var fund_before := simulation.revenue_cents
		var receipt := simulation.purchase_facility(FACILITY_ID)
		_check(bool(receipt.get("accepted", false)), "tier %d should commission from an exactly funded review" % level, failures)
		_check(simulation.revenue_cents == fund_before - LEVEL_COSTS[level - 1], "tier %d should debit capital exactly once" % level, failures)
		_check(simulation.facility_level(FACILITY_ID) == level, "tier %d should become authoritative ownership" % level, failures)
		_check(simulation.current_daily_facility_maintenance_cents() == LEVEL_MAINTENANCE[level], "tier %d should use the authored total upkeep schedule" % level, failures)
		_check(simulation.spendable_fund_cents() == 0, "tier %d should preserve the revised operating reserve exactly" % level, failures)
		_check(simulation.current_claim_capacity() == CLAIM_CAPACITIES[level], "tier %d should add exactly six live file slots" % level, failures)
		var effects := simulation.facility_effects()
		_check(int(effects.get("records_annex_level", -1)) == level, "tier %d should publish its level in facility effects" % level, failures)
		_check(int(effects.get("claim_capacity_bonus", -1)) == level * 6, "tier %d should publish its exact capacity bonus" % level, failures)
		var snapshot := simulation.snapshot()
		_check(int(snapshot.get("claim_capacity", -1)) == CLAIM_CAPACITIES[level], "tier %d snapshot should publish derived capacity" % level, failures)
		var post_status := simulation.facility_status(FACILITY_ID)
		_check(bool(post_status.get("installed", false)), "tier %d should remain installed" % level, failures)
		_check(bool(post_status.get("maxed", false)) == (level == 3), "only tier three should be terminal", failures)
	_check(observed_levels == [1, 2, 3], "each Records Annex tier should emit one ordered purchase receipt", failures)
	_expect_purchase_rejected_atomic(simulation, "duplicate max-level Records Annex", failures)


func _test_rejected_intake_is_recorded_without_minting_cash(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(9411, 4)
	_check(simulation.select_directive(&"shell_assurance"), "intake rejection fixture should start a shift", failures)
	var guard := 0
	while int(simulation.snapshot().get("claims_outstanding", -1)) < simulation.current_claim_capacity() and guard < 240:
		_advance_or_resolve_free_incident(simulation, failures)
		guard += 1
	var full := simulation.snapshot()
	_check(guard < 240, "intake fixture should reach capacity through deterministic arrivals", failures)
	_check(int(full.get("claims_outstanding", -1)) == CLAIM_CAPACITIES[0], "unbuilt intake should fill exactly 18 outstanding slots", failures)
	_check(int(full.get("claim_capacity", -1)) == CLAIM_CAPACITIES[0], "full snapshot should distinguish demand capacity from queue occupancy", failures)

	var revenue_before_rejection := simulation.revenue_cents
	var rejections_before := int(full.get("intake_rejections_total", 0))
	guard = 0
	var rejected := full
	while int(rejected.get("intake_rejections_total", 0)) == rejections_before and guard < 24:
		_advance_or_resolve_free_incident(simulation, failures)
		rejected = simulation.snapshot()
		guard += 1
	_check(guard < 24, "the next offered file should be explicitly rejected once intake is full", failures)
	_check(int(rejected.get("claims_outstanding", -1)) == CLAIM_CAPACITIES[0], "a rejected offer must not overflow the live claim collection", failures)
	_check(int(rejected.get("intake_rejections_today", 0)) > 0, "rejected intake should increment today's count", failures)
	_check(int(rejected.get("intake_rejections_total", 0)) > rejections_before, "rejected intake should increment lifetime count", failures)
	_check(int(rejected.get("intake_rejections_today", -1)) == int(rejected.get("intake_rejections_total", -2)), "fresh fixture daily and lifetime rejection counts should reconcile", failures)
	_check(int(rejected.get("intake_missed_value_today_cents", 0)) > 0, "a rejected file should estimate positive missed claim value", failures)
	_check(int(rejected.get("intake_missed_value_today_cents", -1)) == int(rejected.get("intake_missed_value_total_cents", -2)), "fresh fixture daily and lifetime missed-value ledgers should reconcile", failures)
	_check(simulation.revenue_cents == revenue_before_rejection, "missed value is diagnostic and must never mint Feed Fund cash", failures)


func _test_persistence_and_v10_migration(failures: Array[String]) -> void:
	_check(DepartmentSimulation.SAVE_STATE_VERSION == 25, "schema v25 should retain the Records Annex persistence contract", failures)
	var source := DepartmentSimulation.new(9421, 4)
	source.day = 3
	source.owned_facilities[FACILITY_ID] = 2
	source.intake_rejections_today = 3
	source.intake_rejections_total = 7
	source.intake_missed_value_today_cents = 1565
	source.intake_missed_value_total_cents = 4890
	var state := source.export_save_state()
	_check(int(state.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "Records Annex checkpoint should export current schema v24", failures)
	_check(int((state.get("owned_facilities", {}) as Dictionary).get(String(FACILITY_ID), -1)) == 2, "schema v24 should serialize Records Annex tier with a primitive key", failures)
	_check(state.has("campus_expansion"), "schema v24 should serialize the strict North Meadow ledger", failures)
	for field in [
		"intake_rejections_today",
		"intake_rejections_total",
		"intake_missed_value_today_cents",
		"intake_missed_value_total_cents",
	]:
		_check(state.has(field), "schema v24 should serialize %s" % field, failures)

	var parsed: Variant = JSON.parse_string(JSON.stringify(state))
	_check(parsed is Dictionary, "Records Annex checkpoint should remain primitive JSON", failures)
	if parsed is Dictionary:
		var restored := DepartmentSimulation.new(9422, 4)
		_check(restored.restore_save_state(parsed as Dictionary), "current-schema Records Annex JSON should restore", failures)
		_check(restored.facility_level(FACILITY_ID) == 2, "round trip should preserve Records Annex tier", failures)
		_check(restored.current_claim_capacity() == CLAIM_CAPACITIES[2], "round trip should derive tier-two capacity", failures)
		_check(restored.current_daily_facility_maintenance_cents() == LEVEL_MAINTENANCE[2], "round trip should preserve tier-two upkeep", failures)
		_check(restored.intake_rejections_today == 3 and restored.intake_rejections_total == 7, "round trip should preserve both rejection counters", failures)
		_check(restored.intake_missed_value_today_cents == 1565 and restored.intake_missed_value_total_cents == 4890, "round trip should preserve both missed-value ledgers", failures)

	var legacy_v10 := DepartmentSimulation.new(9423, 4).export_save_state().duplicate(true)
	legacy_v10["state_version"] = 10
	# A strict schema-v10 checkpoint has exactly the original two-facility ledger.
	# Build it explicitly so later facilities cannot leak in when this fixture is
	# refreshed from a current export.
	legacy_v10["owned_facilities"] = {
		"candling_rework_bay": 0,
		String(DepartmentSimulation.PACKING_ANNEX_ID): 0,
	}
	for field in [
		"intake_rejections_today",
		"intake_rejections_total",
		"intake_missed_value_today_cents",
		"intake_missed_value_total_cents",
		"active_market_contract",
		"market_contract_decline_receipt",
		"last_market_contract_result",
		"market_contracts_signed_total",
		"market_contracts_succeeded_total",
		"market_contracts_breached_total",
		"market_clean_contract_streak",
		"best_market_clean_contract_streak",
		"market_contract_premium_today_cents",
		"market_contract_premium_total_cents",
		"market_contract_breach_today_cents",
		"market_contract_breach_total_cents",
		"flock_relations_open_cases",
		"flock_relations_resolutions_used_today",
		"flock_relations_resolved_total",
		"flock_relations_denied_total",
		"flock_relations_settlement_spend_total_cents",
		"last_flock_relations_resolution",
		"flock_relations_resolution_history",
		"next_flock_relations_case_id",
		"feed_procurement_state",
		"harvest_credit_state",
		"farmgate_dispatch_state",
		"pinned_capital_plan_id",
		"last_facility_purchase_receipt",
		"facility_commissioning_history",
		"campus_expansion",
		"campus_expansion_state",
	]:
		legacy_v10.erase(field)
	var legacy_workers := (legacy_v10.get("workers", []) as Array).duplicate(true)
	for worker_value in legacy_workers:
		if worker_value is Dictionary:
			(worker_value as Dictionary).erase("last_personnel_action_serial")
	legacy_v10["workers"] = legacy_workers
	var migrated := DepartmentSimulation.new(9424, 4)
	_check(migrated.restore_save_state(legacy_v10), "schema v10 should migrate with a neutral Records Annex ledger", failures)
	_check(migrated.facility_level(FACILITY_ID) == 0, "v10 migration must not invent Records Annex ownership", failures)
	_check(migrated.current_claim_capacity() == CLAIM_CAPACITIES[0], "v10 migration should derive the base file capacity", failures)
	_check(migrated.intake_rejections_today == 0 and migrated.intake_rejections_total == 0, "v10 migration must not invent rejected files", failures)
	_check(migrated.intake_missed_value_today_cents == 0 and migrated.intake_missed_value_total_cents == 0, "v10 migration must not invent missed value", failures)
	var migrated_state := migrated.export_save_state()
	_check(int(migrated_state.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "migrated checkpoint should re-export schema v24", failures)
	var migrated_facilities := migrated_state.get("owned_facilities", {}) as Dictionary
	var all_facilities_neutral := migrated_facilities.size() == 13
	for level_value in migrated_facilities.values():
		all_facilities_neutral = all_facilities_neutral and int(level_value) == 0
	_check(all_facilities_neutral, "v10 migration should append all eleven later facilities at neutral level zero", failures)
	var migrated_farmgate := migrated_state.get("farmgate_dispatch_state", {}) as Dictionary
	_check((migrated_farmgate.get("lots", []) as Array).is_empty(), "v10 migration must not invent Farmgate inventory", failures)
	_check(
		String(migrated_state.get("pinned_capital_plan_id", "")).is_empty()
		and (migrated_state.get("last_facility_purchase_receipt", {}) as Dictionary).is_empty()
		and (migrated_state.get("facility_commissioning_history", []) as Array).is_empty(),
		"v10 migration must create neutral capital-planning and commissioning ledgers",
		failures,
	)
	_assert_neutral_campus(migrated, "v10", failures)

	var corrupt_rejection_totals := state.duplicate(true)
	corrupt_rejection_totals["intake_rejections_today"] = int(corrupt_rejection_totals.get("intake_rejections_total", 0)) + 1
	_expect_restore_rejected_atomic(corrupt_rejection_totals, "daily rejections above lifetime rejections", failures)
	var corrupt_missed_totals := state.duplicate(true)
	corrupt_missed_totals["intake_missed_value_today_cents"] = int(corrupt_missed_totals.get("intake_missed_value_total_cents", 0)) + 1
	_expect_restore_rejected_atomic(corrupt_missed_totals, "daily missed value above lifetime missed value", failures)
	var corrupt_negative := state.duplicate(true)
	corrupt_negative["intake_rejections_total"] = -1
	_expect_restore_rejected_atomic(corrupt_negative, "negative lifetime rejection count", failures)


func _ready_simulation(seed: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 4)
	simulation.day = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	return simulation


func _advance_or_resolve_free_incident(
	simulation: DepartmentSimulation,
	failures: Array[String]
) -> void:
	if simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT:
		var pending := simulation.pending_decision_snapshot()
		var serial := int(pending.get("serial", -1))
		for option_value in pending.get("options", []):
			var option := option_value as Dictionary
			if int(option.get("cost_cents", 0)) == 0:
				_check(simulation.resolve_decision(serial, StringName(option.get("id", &""))), "intake fixture should resolve its no-cost incident branch", failures)
				return
		_check(false, "intake fixture should find a no-cost incident branch", failures)
		return
	simulation.advance_tick()


func _expect_purchase_rejected_atomic(
	simulation: DepartmentSimulation,
	message: String,
	failures: Array[String]
) -> void:
	var before := simulation.export_save_state().duplicate(true)
	var receipt := simulation.purchase_facility(FACILITY_ID)
	_check(not bool(receipt.get("accepted", false)), "%s should reject" % message, failures)
	_check(not String(receipt.get("reason", "")).is_empty(), "%s should explain its rejection" % message, failures)
	_check(simulation.export_save_state() == before, "%s must preserve all authoritative state" % message, failures)


func _expect_restore_rejected_atomic(
	corrupt: Dictionary,
	message: String,
	failures: Array[String]
) -> void:
	var fallback := DepartmentSimulation.new(9499, 4)
	var before := fallback.export_save_state().duplicate(true)
	_check(not fallback.restore_save_state(corrupt), "%s should fail closed" % message, failures)
	_check(fallback.export_save_state() == before, "%s should preserve the fallback simulation" % message, failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _assert_neutral_campus(simulation: DepartmentSimulation, source_label: String, failures: Array[String]) -> void:
	var campus := simulation.export_save_state().get("campus_expansion", {}) as Dictionary
	_check(
		campus == {
			"version": 1,
			"parcel_owned": false,
			"services": {"circulation": false, "power": false, "cold_chain": false},
			"pod_owned": false,
			"pod_socket_id": "",
			"capital_spend_total_cents": 0,
			"next_receipt_id": 1,
			"last_receipt": {},
			"history": [],
		},
		"%s migration should create the exact neutral North Meadow ledger" % source_label,
		failures,
	)
