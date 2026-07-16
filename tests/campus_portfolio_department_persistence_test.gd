extends SceneTree


const Portfolio := preload("res://core/simulation/campus_portfolio_state.gd")

const NORTH_MEADOW: StringName = &"north_meadow"
const PACKING := DepartmentSimulation.PACKING_ANNEX_ID
const GALLERY := DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID
const DEPOT := DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID


func _init() -> void:
	var failures: Array[String] = []
	_test_schema_v21_neutral_migration(failures)
	_test_portfolio_round_trip_and_strict_tamper_rejection(failures)
	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPUS_PORTFOLIO_DEPARTMENT_PERSISTENCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_PORTFOLIO_DEPARTMENT_PERSISTENCE_TEST_PASSED schema=v23 migration=v21-portfolio-neutral+v22-treasury-neutral roundtrip=staffed-benefits-exact receipts=strict roster=strict tamper=atomic")
	quit(0)


func _test_schema_v21_neutral_migration(failures: Array[String]) -> void:
	var opening := DepartmentSimulation.new(22_301, 4).export_save_state()
	var legacy := opening.duplicate(true)
	legacy["state_version"] = 21
	legacy.erase("campus_portfolio")
	var opening_fund := int(legacy.get("revenue_cents", -1))
	var restored := DepartmentSimulation.new(22_302, 4)
	_check(restored.restore_save_state(_json_round_trip(legacy)), "canonical schema-v21 checkpoint should migrate", failures)
	var migrated := _json_round_trip(restored.export_save_state())
	_check(int(migrated.get("state_version", -1)) == 23, "v21 checkpoint should re-export as schema v23", failures)
	_check(restored.revenue_cents == opening_fund, "neutral portfolio migration must not change the Feed Fund", failures)
	_check(
		(migrated.get("campus_portfolio", {}) as Dictionary)
		== (_json_round_trip(Portfolio.neutral_save_data(1)) as Dictionary),
		"v21 migration should add the exact neutral portfolio ledger",
		failures,
	)
	_check(restored.current_daily_portfolio_cost_cents() == 0, "neutral migration must invent no portfolio obligation", failures)
	_check((restored.campus_portfolio_snapshot().get("history", []) as Array).is_empty(), "neutral migration must invent no deed, project, or staffing receipt", failures)

	var smuggled := legacy.duplicate(true)
	smuggled["campus_portfolio"] = Portfolio.neutral_save_data(1)
	var target := DepartmentSimulation.new(22_303, 4)
	var before := _json_round_trip(target.export_save_state())
	_check(not target.restore_save_state(_json_round_trip(smuggled)), "claimed v21 file should reject even a smuggled neutral v22 portfolio root", failures)
	_check(_json_round_trip(target.export_save_state()) == before, "failed v21 migration should preserve the target simulation atomically", failures)


func _test_portfolio_round_trip_and_strict_tamper_rejection(failures: Array[String]) -> void:
	var source := _staffed_portfolio_fixture(22_401, failures)
	var valid := _json_round_trip(source.export_save_state())
	_check(int(valid.get("state_version", -1)) == 23 and valid.has("campus_portfolio"), "staffed portfolio checkpoint should export the v23 root", failures)
	var restored := DepartmentSimulation.new(22_402, 4)
	_check(restored.restore_save_state(valid), "canonical staffed portfolio checkpoint should restore", failures)
	var restored_save := _json_round_trip(restored.export_save_state())
	if restored_save.get("campus_portfolio", {}) != valid.get("campus_portfolio", {}):
		failures.append("deeds, installed modules, FIFO receipts, and named assignments should round-trip exactly")
	_check(restored.current_daily_portfolio_cost_cents() == source.current_daily_portfolio_cost_cents(), "restored land, module, and duty obligations should remain exact", failures)
	_check(restored.current_claim_capacity() == source.current_claim_capacity(), "restored Rail staffing and utility evidence should reproduce claim capacity", failures)
	_check(restored.feed_procurement_snapshot().get("capacity_scoops") == source.feed_procurement_snapshot().get("capacity_scoops"), "restored Mill staffing should reproduce feed capacity", failures)
	_check(restored.feed_procurement_snapshot().get("demand_scoops") == source.feed_procurement_snapshot().get("demand_scoops"), "restored Mill staffing should reproduce feed demand", failures)

	var corrupt_receipt := valid.duplicate(true)
	var portfolio := (corrupt_receipt.get("campus_portfolio", {}) as Dictionary).duplicate(true)
	var history := (portfolio.get("history", []) as Array).duplicate(true)
	var deed_receipt := (history[0] as Dictionary).duplicate(true)
	deed_receipt["cost_cents"] = int(deed_receipt.get("cost_cents", 0)) + 1
	history[0] = deed_receipt
	portfolio["history"] = history
	corrupt_receipt["campus_portfolio"] = portfolio
	_expect_restore_rejected_atomic(corrupt_receipt, "one-cent portfolio receipt repricing", failures)

	# Make the strict state/history replay agree on worker #4 so CampusPortfolioState
	# accepts it; DepartmentSimulation must still reject because that hen is not on
	# this four-hen active roster.
	var corrupt_roster := valid.duplicate(true)
	portfolio = (corrupt_roster.get("campus_portfolio", {}) as Dictionary).duplicate(true)
	var modules := (portfolio.get("modules", {}) as Dictionary).duplicate(true)
	var rail_state := (modules.get("collection_rail_hub", {}) as Dictionary).duplicate(true)
	rail_state["worker_id"] = 4
	modules["collection_rail_hub"] = rail_state
	portfolio["modules"] = modules
	history = (portfolio.get("history", []) as Array).duplicate(true)
	for index in history.size():
		var receipt := (history[index] as Dictionary).duplicate(true)
		if (
			StringName(String(receipt.get("action_id", ""))) == &"assign_worker"
			and StringName(String(receipt.get("module_id", ""))) == Portfolio.COLLECTION_RAIL_HUB
		):
			receipt["worker_id"] = 4
			receipt["outcome"] = "Worker #4 assigned to COLLECTION RAIL HUB campus duty."
			history[index] = receipt
			break
	portfolio["history"] = history
	if StringName(String((portfolio.get("last_receipt", {}) as Dictionary).get("module_id", ""))) == Portfolio.COLLECTION_RAIL_HUB:
		portfolio["last_receipt"] = (history[-1] as Dictionary).duplicate(true)
	corrupt_roster["campus_portfolio"] = portfolio
	_expect_restore_rejected_atomic(corrupt_roster, "assignment to a known but unemployed hen", failures)


func _staffed_portfolio_fixture(seed: int, failures: Array[String]) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 4)
	simulation.day = 14
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 1_000_000
	simulation.office_capacity = 6
	simulation.owned_facilities[PACKING] = 3
	simulation.owned_facilities[GALLERY] = 3
	simulation.owned_facilities[DEPOT] = 3
	simulation.export_save_state()
	_check(bool(simulation.purchase_campus_parcel(NORTH_MEADOW).get("accepted", false)), "persistence fixture should file North Meadow through canonical Farmgate evidence", failures)
	for service_id: StringName in [&"circulation", &"power", &"cold_chain"]:
		_check(bool(simulation.commission_campus_service(service_id).get("accepted", false)), "persistence fixture should commission %s" % String(service_id), failures)
	_check(bool(simulation.purchase_campus_portfolio_deed(Portfolio.ORCHARD_ROW).get("accepted", false)), "persistence fixture should file Orchard Row", failures)
	_check(bool(simulation.authorize_campus_portfolio_project(Portfolio.COLLECTION_RAIL_HUB, Portfolio.ORCHARD_WEST).get("accepted", false)), "persistence fixture should authorize the Rail Hub", failures)
	_check(bool(simulation.authorize_campus_portfolio_project(Portfolio.GRAIN_RECOVERY_MILL, Portfolio.ORCHARD_EAST).get("accepted", false)), "persistence fixture should queue the Grain Mill", failures)
	simulation.day = 19
	simulation.export_save_state()
	_check(bool(simulation.assign_campus_portfolio_worker(Portfolio.COLLECTION_RAIL_HUB, 0).get("accepted", false)), "persistence fixture should staff the Rail Hub", failures)
	_check(bool(simulation.assign_campus_portfolio_worker(Portfolio.GRAIN_RECOVERY_MILL, 1).get("accepted", false)), "persistence fixture should staff the Grain Mill", failures)
	return simulation


func _expect_restore_rejected_atomic(
	corrupt: Dictionary,
	label: String,
	failures: Array[String],
) -> void:
	var target := DepartmentSimulation.new(22_499, 4)
	var before := _json_round_trip(target.export_save_state())
	_check(not target.restore_save_state(_json_round_trip(corrupt)), "%s should fail closed" % label, failures)
	_check(_json_round_trip(target.export_save_state()) == before, "%s rejection should preserve the target atomically" % label, failures)


func _json_round_trip(source: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(source))
	return parsed as Dictionary if parsed is Dictionary else {}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
