extends SceneTree


const FACILITY_ID: StringName = &"farmer_brand_packing_annex"
const LEVEL_COSTS := [6000, 9500, 14000]
const LEVEL_MAINTENANCE := [0, 300, 500, 800]


func _init() -> void:
	var failures: Array[String] = []
	_test_unlock_and_tiered_purchase(failures)
	_test_carton_contract(failures)
	_test_persistence_and_migration(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("PACKING_ANNEX_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PACKING_ANNEX_ECONOMY_TEST_PASSED unlock=two-shifts tiers=3 reserve=delta carton=6 persistence=v10-v8")
	quit(0)


func _test_unlock_and_tiered_purchase(failures: Array[String]) -> void:
	var locked := DepartmentSimulation.new(9101, 4)
	locked.day = 2
	locked.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	locked.pending_decision.clear()
	locked.revenue_cents = 100_000
	var locked_status := locked.facility_status(FACILITY_ID)
	_check(bool(locked_status.get("known", false)), "annex should be a known capital module", failures)
	_check(not bool(locked_status.get("unlocked", true)), "annex lease should remain locked until day three", failures)
	_check("two shifts" in String(locked_status.get("reason", "")).to_lower(), "locked annex should disclose its two-shift gate", failures)
	_expect_purchase_rejected_atomic(locked, "locked day-two annex", failures)

	var pending := DepartmentSimulation.new(9102, 4)
	pending.day = 3
	pending.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	pending.revenue_cents = 100_000
	var pending_status := pending.facility_status(FACILITY_ID)
	_check(not bool(pending_status.get("planning_open", true)), "an unresolved closing decision should lock capital planning", failures)
	_check("credit memo" in String(pending_status.get("reason", "")).to_lower(), "pending decision should produce a specific capital reason", failures)
	_expect_purchase_rejected_atomic(pending, "pending-decision annex", failures)

	var short := _ready_simulation(9103)
	short.revenue_cents = (
		short.current_daily_operating_cost_cents()
		+ LEVEL_COSTS[0]
		+ LEVEL_MAINTENANCE[1]
		- 1
	)
	var short_status := short.facility_status(FACILITY_ID)
	_check(int(short_status.get("projected_spendable_fund_cents", 0)) == -1, "annex preflight should expose the exact one-cent reserve deficit", failures)
	_expect_purchase_rejected_atomic(short, "one-cent-short level one annex", failures)

	var simulation := _ready_simulation(9104)
	var observed_levels: Array[int] = []
	simulation.facility_purchased.connect(func(id: StringName, level: int, _cost: int) -> void:
		if id == FACILITY_ID:
			observed_levels.append(level)
	)
	for level in range(1, 4):
		var current_maintenance: int = int(LEVEL_MAINTENANCE[level - 1])
		var next_maintenance: int = int(LEVEL_MAINTENANCE[level])
		var maintenance_delta: int = next_maintenance - current_maintenance
		simulation.revenue_cents = (
			simulation.current_daily_operating_cost_cents()
			+ LEVEL_COSTS[level - 1]
			+ maintenance_delta
		)
		var preflight := simulation.facility_status(FACILITY_ID)
		_check(int(preflight.get("level", -1)) == level - 1, "tier %d preflight should expose current level" % level, failures)
		_check(int(preflight.get("next_level", -1)) == level, "tier %d preflight should expose next level" % level, failures)
		_check(int(preflight.get("next_level_cost_cents", -1)) == LEVEL_COSTS[level - 1], "tier %d should quote its exact capital cost" % level, failures)
		_check(int(preflight.get("maintenance_delta_cents", -1)) == maintenance_delta, "tier %d should reserve only its exact upkeep increase" % level, failures)
		_check(int(preflight.get("projected_spendable_fund_cents", -1)) == 0, "tier %d exact fixture should project zero free cash" % level, failures)
		var fund_before := simulation.revenue_cents
		var receipt := simulation.purchase_facility(FACILITY_ID)
		_check(bool(receipt.get("accepted", false)), "tier %d should commission from an exact funded review" % level, failures)
		_check(simulation.revenue_cents == fund_before - LEVEL_COSTS[level - 1], "tier %d should debit capital exactly once" % level, failures)
		_check(simulation.facility_level(FACILITY_ID) == level, "tier %d should become authoritative ownership" % level, failures)
		_check(simulation.current_daily_facility_maintenance_cents() == next_maintenance, "tier %d should set total annex upkeep from its schedule" % level, failures)
		_check(simulation.spendable_fund_cents() == 0, "tier %d should preserve the full revised operating reserve" % level, failures)
		var post_status := simulation.facility_status(FACILITY_ID)
		_check(bool(post_status.get("installed", false)), "tier %d should remain visibly installed" % level, failures)
		_check(bool(post_status.get("maxed", false)) == (level == 3), "only tier three should be terminal", failures)
	_check(observed_levels == [1, 2, 3], "each annex tier should emit one ordered visual receipt", failures)
	_expect_purchase_rejected_atomic(simulation, "duplicate max-level annex", failures)


func _test_carton_contract(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(9201, 4)
	simulation.day = 3
	simulation.owned_facilities[FACILITY_ID] = 1
	for egg_index in 5:
		var receipt := simulation.call("_apply_packing_contract_value", &"sound", 500) as Dictionary
		_check(int(receipt.get("value_bonus_cents", -1)) == 20, "level one egg %d should receive exactly four percent" % (egg_index + 1), failures)
		_check(int(receipt.get("value_cents", -1)) == 520, "pre-carton egg should include only its percentage premium", failures)
		_check(not bool(receipt.get("carton_completed", true)), "the first five good eggs must not mint a carton", failures)
	var progress_before_crack := simulation.packing_carton_progress
	var cracked := simulation.call("_apply_packing_contract_value", &"cracked", 500) as Dictionary
	_check(int(cracked.get("value_cents", -1)) == 500, "cracked output should receive no packing value", failures)
	_check(simulation.packing_carton_progress == progress_before_crack, "cracked output must not advance the physical carton", failures)
	var sixth := simulation.call("_apply_packing_contract_value", &"sound", 500) as Dictionary
	_check(bool(sixth.get("carton_completed", false)), "the sixth good egg should close exactly one carton", failures)
	_check(int(sixth.get("carton_bonus_cents", -1)) == 300, "level one carton should pay exactly $3", failures)
	_check(int(sixth.get("value_cents", -1)) == 820, "sixth egg receipt should include premium plus carton settlement", failures)
	_check(simulation.packing_carton_progress == 0 and simulation.packing_cartons_today == 1, "completed carton should reset six slots and increment today once", failures)

	simulation.owned_facilities[FACILITY_ID] = 2
	var golden := simulation.call("_apply_packing_contract_value", &"golden", 2000) as Dictionary
	_check(int(golden.get("value_bonus_cents", -1)) == 160, "level two should add exactly eight percent to golden graded value", failures)
	_check(int(golden.get("value_cents", -1)) == 2160, "golden packing receipt should preserve the premium order", failures)
	var status := simulation.packing_contract_status()
	_check(int(status.get("carton_progress", -1)) == 1, "post-carton good output should light one authoritative slot", failures)
	_check(int(status.get("cartons_total", -1)) == 1, "contract status should retain lifetime carton count", failures)
	_check(int(status.get("value_bonus_total_cents", -1)) == 280, "contract status should total every percentage premium exactly", failures)
	_check(int(status.get("carton_bonus_total_cents", -1)) == 300, "contract status should total carton settlements separately", failures)


func _test_persistence_and_migration(failures: Array[String]) -> void:
	var source := DepartmentSimulation.new(9301, 4)
	source.day = 3
	source.owned_facilities[FACILITY_ID] = 2
	for _egg in 7:
		source.call("_apply_packing_contract_value", &"sound", 500)
	var state := source.export_save_state()
	_check(int(state.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "annex state should export the current schema", failures)
	_check(int((state.get("owned_facilities", {}) as Dictionary).get(String(FACILITY_ID), -1)) == 2, "current schema should serialize annex level with a primitive key", failures)
	var parsed: Variant = JSON.parse_string(JSON.stringify(state))
	_check(parsed is Dictionary, "annex checkpoint should remain primitive JSON", failures)
	if parsed is Dictionary:
		var restored := DepartmentSimulation.new(9302, 4)
		_check(restored.restore_save_state(parsed as Dictionary), "current-schema annex JSON should restore", failures)
		_check(restored.facility_level(FACILITY_ID) == 2, "round trip should preserve annex tier", failures)
		_check(restored.current_daily_facility_maintenance_cents() == 500, "round trip should preserve tier-two upkeep", failures)
		_check(restored.packing_contract_status() == source.packing_contract_status(), "round trip should preserve every carton ledger", failures)

	var legacy_v8 := DepartmentSimulation.new(9303, 4).export_save_state()
	legacy_v8["state_version"] = 8
	legacy_v8["owned_facilities"] = {"candling_rework_bay": 0}
	for field in [
		"packing_carton_progress",
		"packing_cartons_today",
		"packing_cartons_total",
		"packing_value_bonus_today_cents",
		"packing_value_bonus_total_cents",
		"packing_carton_bonus_today_cents",
		"packing_carton_bonus_total_cents",
	]:
		legacy_v8.erase(field)
	var migrated := DepartmentSimulation.new(9304, 4)
	_check(migrated.restore_save_state(legacy_v8), "schema v8 should migrate with a neutral annex ledger", failures)
	_check(migrated.facility_level(FACILITY_ID) == 0, "v8 migration must not invent annex ownership", failures)
	_check(not bool(migrated.packing_contract_status().get("enabled", true)), "v8 migration must not invent contract progress", failures)
	_check(int(migrated.export_save_state().get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "migrated checkpoint should re-export the current schema", failures)

	var corrupt_progress := state.duplicate(true)
	corrupt_progress["packing_carton_progress"] = 6
	_expect_restore_rejected_atomic(corrupt_progress, "out-of-range carton progress", failures)
	var corrupt_totals := state.duplicate(true)
	corrupt_totals["packing_cartons_today"] = int(corrupt_totals.get("packing_cartons_total", 0)) + 1
	_expect_restore_rejected_atomic(corrupt_totals, "daily cartons above lifetime cartons", failures)
	var corrupt_unowned := state.duplicate(true)
	var unowned_ledger := (corrupt_unowned.get("owned_facilities", {}) as Dictionary).duplicate(true)
	unowned_ledger[String(FACILITY_ID)] = 0
	corrupt_unowned["owned_facilities"] = unowned_ledger
	_expect_restore_rejected_atomic(corrupt_unowned, "packing output without an owned annex", failures)
	var corrupt_level := state.duplicate(true)
	var level_ledger := (corrupt_level.get("owned_facilities", {}) as Dictionary).duplicate(true)
	level_ledger[String(FACILITY_ID)] = 4
	corrupt_level["owned_facilities"] = level_ledger
	_expect_restore_rejected_atomic(corrupt_level, "annex level beyond authored tier three", failures)


func _ready_simulation(seed: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 4)
	simulation.day = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	return simulation


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
	var fallback := DepartmentSimulation.new(9399, 4)
	var before := fallback.export_save_state().duplicate(true)
	_check(not fallback.restore_save_state(corrupt), "%s should fail closed" % message, failures)
	_check(fallback.export_save_state() == before, "%s should preserve the fallback simulation" % message, failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
