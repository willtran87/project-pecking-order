extends SceneTree


const PARCEL: StringName = &"north_meadow"
const POD: StringName = &"egg_routing_pod"
const DEPOT := DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID
const PACKING := DepartmentSimulation.PACKING_ANNEX_ID
const GALLERY := DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID
const RECORDS := DepartmentSimulation.RECORDS_ANNEX_ID
const LOW_BINDER: StringName = &"homestead_stability_binder"


func _init() -> void:
	var failures: Array[String] = []
	_test_full_campus_and_forty_eight_lots_round_trip(failures)
	_test_standing_access_round_trip(failures)
	_test_schema_v20_neutral_migration(failures)
	_test_strict_campus_corruption_rejects_atomically(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPUS_EXPANSION_PERSISTENCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_EXPANSION_PERSISTENCE_TEST_PASSED schema=v23 migration=v20-neutral campus=exact receipts=strict farmgate=48-lot-roundtrip overflow=90-percent tamper=atomic")
	quit(0)


func _test_full_campus_and_forty_eight_lots_round_trip(failures: Array[String]) -> void:
	var source := _full_campus_fixture(21_401, failures)
	for index in 48:
		var store := source.call(
			"_store_farmgate_lot_with_campus_capacity",
			10_000 + index,
			source.day,
			0,
			source.workers[0].display_name,
			&"sound",
			1_000 + index,
			3,
			4,
		) as Dictionary
		_check(bool(store.get("accepted", false)) and bool(store.get("stored", false)), "lot %d should enter the 48-slot cold-chain ledger" % (index + 1), failures)
	_check(source._farmgate_dispatch.stock_count() == 48, "fixture should hold exactly 48 finished-egg lots", failures)
	_check(int(source.farmgate_dispatch_snapshot().get("storage_capacity_eggs", -1)) == 48, "source projection should expose 48-slot effective storage", failures)

	var exported := _json_round_trip(source.export_save_state())
	_check(int(exported.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "campus checkpoint should export the current schema v24", failures)
	_check(exported.has("campus_expansion"), "schema v24 should persist campus expansion root", failures)
	var restored := DepartmentSimulation.new(21_402, 6)
	_check(restored.restore_save_state(exported), "canonical full-campus JSON checkpoint should restore", failures)
	_check(restored.campus_expansion_state == source.campus_expansion_state, "campus flags, socket, spend, and receipts should round-trip exactly", failures)
	_check(restored.campus_expansion_snapshot().get("history", []) == source.campus_expansion_snapshot().get("history", []), "campus immutable history should round-trip exactly", failures)
	_check(restored._farmgate_dispatch.stock_count() == 48, "all 48 actual lots should survive restore", failures)
	_check(int(restored.farmgate_dispatch_snapshot().get("storage_capacity_eggs", -1)) == 48, "restored cold-chain should retain exact effective capacity", failures)

	var overflow := restored.call(
		"_store_farmgate_lot_with_campus_capacity",
		20_001,
		restored.day,
		0,
		restored.workers[0].display_name,
		&"sound",
		1_000,
		3,
		4,
	) as Dictionary
	_check(bool(overflow.get("accepted", false)) and bool(overflow.get("overflow", false)), "49th lot should use the existing overflow route", failures)
	_check(not bool(overflow.get("stored", true)), "49th lot must not exceed the 48-lot hard cap", failures)
	_check(int(overflow.get("cash_delta_cents", -1)) == 900, "overflow pickup should preserve the authored 90-percent payout", failures)
	_check(restored._farmgate_dispatch.stock_count() == 48, "overflow should leave stored lot count capped at 48", failures)


func _test_standing_access_round_trip(failures: Array[String]) -> void:
	var source := DepartmentSimulation.new(21_451, 4)
	source.day = 3
	source.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	source.pending_decision.clear()
	source.revenue_cents = 200_000
	source.owned_facilities[RECORDS] = 1
	_check(bool(source.sign_market_contract(LOW_BINDER).get("accepted", false)), "standing fixture should sign the real Homestead binder", failures)
	_check(source.begin_next_shift_briefing(), "standing fixture should open its signed shift briefing", failures)
	_check(source.select_directive(&"shell_assurance"), "standing fixture should start production", failures)
	var guard := 0
	while source.minute_of_day < 9 * 60 and guard < 120:
		source.advance_tick()
		guard += 1
	_check(source.minute_of_day == 9 * 60, "standing fixture should release the Homestead folders at 09:00", failures)
	var accepted := source.active_market_contract.get("accepted_claim_ids", []) as Array
	_check(accepted.size() >= 4, "standing fixture should receive four authored Homestead folders", failures)
	for index in mini(4, accepted.size()):
		source.call("_record_market_contract_completion", _claim_with_id(int(accepted[index])), &"sound")
	source.call("_complete_workday")
	_check(source.farm_mutual_standing() == 2 and source.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW, "standing fixture should close into review with a fulfilled real binder", failures)
	source.pending_decision.clear()
	var pre_deed := _json_round_trip(source.export_save_state())
	_check(DepartmentSimulation.new(21_450, 4).restore_save_state(pre_deed), "fulfilled standing fixture should be canonical before the deed filing", failures)
	var deed := source.purchase_campus_parcel(PARCEL)
	_check(bool(deed.get("accepted", false)) and StringName(deed.get("access_gate_id", &"")) == &"farm_mutual_standing", "Bronze standing should be the filed parcel access route", failures)
	var valid := _json_round_trip(source.export_save_state())
	var restored := DepartmentSimulation.new(21_452, 4)
	_check(restored.restore_save_state(valid), "legitimate standing-gated parcel should restore", failures)
	_check(bool(restored.campus_expansion_state.get("parcel_owned", false)) and restored.farm_mutual_standing() == 2, "standing-gated restore should retain deed and Bronze evidence", failures)

	var corrupt := valid.duplicate(true)
	var campus := (corrupt.get("campus_expansion", {}) as Dictionary).duplicate(true)
	var history := (campus.get("history", []) as Array).duplicate(true)
	var receipt := (history[0] as Dictionary).duplicate(true)
	receipt["access_standing_points"] = 4
	history[0] = receipt
	campus["history"] = history
	campus["last_receipt"] = receipt.duplicate(true)
	corrupt["campus_expansion"] = campus
	_expect_restore_rejected_atomic(corrupt, "standing evidence beyond lifetime successes", failures)

	corrupt = valid.duplicate(true)
	campus = (corrupt.get("campus_expansion", {}) as Dictionary).duplicate(true)
	history = (campus.get("history", []) as Array).duplicate(true)
	receipt = (history[0] as Dictionary).duplicate(true)
	receipt["access_gate_id"] = "farmgate_dispatch"
	receipt["access_farmgate_level"] = 1
	history[0] = receipt
	campus["history"] = history
	campus["last_receipt"] = receipt.duplicate(true)
	corrupt["campus_expansion"] = campus
	_expect_restore_rejected_atomic(corrupt, "invented Farmgate deed access", failures)


func _test_schema_v20_neutral_migration(failures: Array[String]) -> void:
	var opening := DepartmentSimulation.new(21_501, 4).export_save_state()
	var legacy := opening.duplicate(true)
	legacy["state_version"] = 20
	legacy.erase("campus_expansion")
	var opening_fund := int(legacy.get("revenue_cents", -1))
	var restored := DepartmentSimulation.new(21_502, 4)
	_check(restored.restore_save_state(_json_round_trip(legacy)), "strict schema-v20 checkpoint should migrate", failures)
	var migrated := restored.export_save_state()
	_check(int(migrated.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "v20 checkpoint should re-export as the current schema v24", failures)
	_check(restored.revenue_cents == opening_fund, "neutral migration must not alter the Feed Fund", failures)
	_check((migrated.get("owned_facilities", {}) as Dictionary).size() == 13, "v20 migration should retain the exact thirteen-facility ledger", failures)
	var campus := migrated.get("campus_expansion", {}) as Dictionary
	_check(not bool(campus.get("parcel_owned", true)) and not bool(campus.get("pod_owned", true)), "migration must invent neither parcel nor pod ownership", failures)
	_check((campus.get("history", []) as Array).is_empty(), "migration must invent no campus receipts", failures)
	_check(int(campus.get("capital_spend_total_cents", -1)) == 0 and int(campus.get("next_receipt_id", -1)) == 1, "migration should create an exact neutral campus ledger", failures)
	var services := campus.get("services", {}) as Dictionary
	_check(services.size() == 3 and not bool(services.get("circulation", true)) and not bool(services.get("power", true)) and not bool(services.get("cold_chain", true)), "migration should leave all three services disconnected", failures)

	var smuggled := legacy.duplicate(true)
	smuggled["campus_expansion"] = campus.duplicate(true)
	_check(not DepartmentSimulation.new(21_503, 4).restore_save_state(_json_round_trip(smuggled)), "v20 migration should reject an invented campus root", failures)
	var malformed := legacy.duplicate(true)
	var facilities := (malformed.get("owned_facilities", {}) as Dictionary).duplicate(true)
	facilities.erase(String(DEPOT))
	malformed["owned_facilities"] = facilities
	_check(not DepartmentSimulation.new(21_504, 4).restore_save_state(_json_round_trip(malformed)), "v20 migration should reject a noncanonical facility map", failures)


func _test_strict_campus_corruption_rejects_atomically(failures: Array[String]) -> void:
	var valid := _json_round_trip(_full_campus_fixture(21_601, failures).export_save_state())

	var corrupt := valid.duplicate(true)
	var campus := (corrupt.get("campus_expansion", {}) as Dictionary).duplicate(true)
	var services := (campus.get("services", {}) as Dictionary).duplicate(true)
	services.erase("power")
	campus["services"] = services
	corrupt["campus_expansion"] = campus
	_expect_restore_rejected_atomic(corrupt, "missing required service key", failures)

	corrupt = valid.duplicate(true)
	campus = (corrupt.get("campus_expansion", {}) as Dictionary).duplicate(true)
	campus["pod_socket_id"] = "service_spine"
	corrupt["campus_expansion"] = campus
	_expect_restore_rejected_atomic(corrupt, "route-blocked persisted socket", failures)

	corrupt = valid.duplicate(true)
	campus = (corrupt.get("campus_expansion", {}) as Dictionary).duplicate(true)
	var history := (campus.get("history", []) as Array).duplicate(true)
	var receipt := (history[0] as Dictionary).duplicate(true)
	receipt["cost_cents"] = int(receipt.get("cost_cents", 0)) + 1
	history[0] = receipt
	campus["history"] = history
	corrupt["campus_expansion"] = campus
	_expect_restore_rejected_atomic(corrupt, "repriced campus receipt", failures)

	corrupt = valid.duplicate(true)
	campus = (corrupt.get("campus_expansion", {}) as Dictionary).duplicate(true)
	campus["capital_spend_total_cents"] = int(campus.get("capital_spend_total_cents", 0)) + 1
	corrupt["campus_expansion"] = campus
	_expect_restore_rejected_atomic(corrupt, "tampered capital total", failures)

	corrupt = valid.duplicate(true)
	campus = (corrupt.get("campus_expansion", {}) as Dictionary).duplicate(true)
	history = (campus.get("history", []) as Array).duplicate(true)
	receipt = (history[0] as Dictionary).duplicate(true)
	receipt["fund_after_cents"] = -1
	history[0] = receipt
	campus["history"] = history
	corrupt["campus_expansion"] = campus
	_expect_restore_rejected_atomic(corrupt, "negative campus receipt fund", failures)

	corrupt = valid.duplicate(true)
	campus = (corrupt.get("campus_expansion", {}) as Dictionary).duplicate(true)
	history = (campus.get("history", []) as Array).duplicate(true)
	history.pop_back()
	campus["history"] = history
	corrupt["campus_expansion"] = campus
	_expect_restore_rejected_atomic(corrupt, "missing campus receipt", failures)

	corrupt = valid.duplicate(true)
	campus = (corrupt.get("campus_expansion", {}) as Dictionary).duplicate(true)
	history = (campus.get("history", []) as Array).duplicate(true)
	receipt = (history[1] as Dictionary).duplicate(true)
	receipt["socket_id"] = "unfiled_meadow_socket"
	history[1] = receipt
	campus["history"] = history
	corrupt["campus_expansion"] = campus
	_expect_restore_rejected_atomic(corrupt, "unknown receipt socket", failures)

	corrupt = valid.duplicate(true)
	campus = (corrupt.get("campus_expansion", {}) as Dictionary).duplicate(true)
	history = (campus.get("history", []) as Array).duplicate(true)
	receipt = (history[0] as Dictionary).duplicate(true)
	receipt["socket_id"] = "meadow_west"
	history[0] = receipt
	campus["history"] = history
	corrupt["campus_expansion"] = campus
	_expect_restore_rejected_atomic(corrupt, "parcel receipt with invented socket", failures)

	corrupt = valid.duplicate(true)
	var facilities := (corrupt.get("owned_facilities", {}) as Dictionary).duplicate(true)
	facilities[String(DEPOT)] = 0
	corrupt["owned_facilities"] = facilities
	_expect_restore_rejected_atomic(corrupt, "campus deed with erased Farmgate access evidence", failures)


func _full_campus_fixture(seed: int, failures: Array[String]) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 6)
	simulation.day = 14
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 1_000_000
	simulation.office_capacity = 6
	simulation.owned_facilities[PACKING] = 3
	simulation.owned_facilities[GALLERY] = 3
	simulation.owned_facilities[DEPOT] = 3
	simulation._farmgate_dispatch.begin_day(simulation.day)
	_check(bool(simulation.purchase_campus_parcel(PARCEL).get("accepted", false)), "fixture should purchase North Meadow through Farmgate access", failures)
	_check(bool(simulation.place_campus_module(POD, &"meadow_west").get("accepted", false)), "fixture should place the routing pod", failures)
	_check(bool(simulation.commission_campus_service(&"circulation").get("accepted", false)), "fixture should commission circulation", failures)
	_check(bool(simulation.commission_campus_service(&"power").get("accepted", false)), "fixture should commission power", failures)
	_check(bool(simulation.commission_campus_service(&"cold_chain").get("accepted", false)), "fixture should commission cold-chain", failures)
	_check(simulation.current_claim_capacity() >= 6 and simulation.current_daily_campus_cost_cents() == 1_575, "fixture campus should be operational with exact upkeep", failures)
	return simulation


func _claim_with_id(claim_id: int) -> ClaimState:
	return ClaimState.new(
		claim_id,
		&"nest_damage",
		"NORTH MEADOW ACCESS FOLDER",
		1.0,
		360,
		0.0,
		0,
		10_000,
		10_000,
	)


func _expect_restore_rejected_atomic(
	corrupt: Dictionary,
	label: String,
	failures: Array[String],
) -> void:
	var target := DepartmentSimulation.new(21_699, 6)
	var before := JSON.stringify(target.export_save_state())
	_check(not target.restore_save_state(corrupt), "%s should fail closed" % label, failures)
	_check(JSON.stringify(target.export_save_state()) == before, "%s rejection should preserve fallback state" % label, failures)


func _json_round_trip(source: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(source))
	return parsed as Dictionary if parsed is Dictionary else {}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
