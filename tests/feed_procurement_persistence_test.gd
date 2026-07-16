extends SceneTree


const PROVISIONS := DepartmentSimulation.FEED_PROCUREMENT_COOP_ID


func _init() -> void:
	var failures: Array[String] = []
	_test_active_inventory_json_round_trip(failures)
	_test_strict_neutral_v17_migration(failures)
	_test_feed_tamper_rejection_is_atomic(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("FEED_PROCUREMENT_PERSISTENCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FEED_PROCUREMENT_PERSISTENCE_TEST_PASSED schema=22 migration=v17-neutral inventory=exact campus=neutral tamper=atomic")
	quit(0)


func _test_active_inventory_json_round_trip(failures: Array[String]) -> void:
	var source := _active_reserve_fixture(18_101)
	var exported := _json_round_trip(source.export_save_state())
	_check(int(exported.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "current feed state should export schema v23", failures)
	var facilities := exported.get("owned_facilities", {}) as Dictionary
	_check(facilities.size() == 13, "schema v23 should serialize exactly thirteen facility keys", failures)
	_check(int(facilities.get(String(PROVISIONS), -1)) == 3, "schema v23 should preserve Provisions tier three", failures)
	_check(exported.has("feed_procurement_state"), "schema v23 should carry the authoritative feed ledger", failures)
	_check(exported.has("campus_expansion"), "schema v23 should carry the strict North Meadow ledger", failures)

	var restored := DepartmentSimulation.new(18_102, 6)
	_check(restored.restore_save_state(exported), "valid active-inventory JSON should restore", failures)
	_check(restored.feed_procurement_snapshot() == source.feed_procurement_snapshot(), "round trip should reproduce the canonical procurement projection", failures)
	_check(restored.export_save_state().get("feed_procurement_state", {}) == source.export_save_state().get("feed_procurement_state", {}), "round trip should reproduce the internal FIFO ledger", failures)
	_check(restored.current_daily_feed_cost_cents() == source.current_daily_feed_cost_cents(), "round trip should preserve the accrued spot obligation", failures)


func _test_strict_neutral_v17_migration(failures: Array[String]) -> void:
	var current := DepartmentSimulation.new(18_111, 4).export_save_state()
	var legacy := current.duplicate(true)
	legacy["state_version"] = 17
	var facilities := (legacy.get("owned_facilities", {}) as Dictionary).duplicate(true)
	facilities.erase(String(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID))
	facilities.erase(String(PROVISIONS))
	facilities.erase(String(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID))
	legacy["owned_facilities"] = facilities
	legacy.erase("feed_procurement_state")
	legacy.erase("harvest_credit_state")
	legacy.erase("farmgate_dispatch_state")
	legacy.erase("pinned_capital_plan_id")
	legacy.erase("last_facility_purchase_receipt")
	legacy.erase("facility_commissioning_history")
	legacy.erase("campus_expansion")
	legacy.erase("campus_expansion_state")
	_check(facilities.size() == 10, "v17 fixture should retain the exact legacy ten-key facility map", failures)

	var restored := DepartmentSimulation.new(18_112, 4)
	_check(restored.restore_save_state(_json_round_trip(legacy)), "strict valid v17 checkpoint should migrate", failures)
	var migrated := restored.export_save_state()
	_check(int(migrated.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "v17 should re-export as v23", failures)
	_check((migrated.get("owned_facilities", {}) as Dictionary).size() == 13, "migration should append exactly three facility keys", failures)
	_check(restored.facility_level(PROVISIONS) == 0, "v17 migration should append neutral Provisions level zero", failures)
	var feed := restored.feed_procurement_snapshot()
	_check(int(feed.get("stock_scoops", -1)) == 0, "migration must not invent inventory", failures)
	_check(int(feed.get("procurement_spend_total_cents", -1)) == 0, "migration must not invent procurement spend", failures)
	_check(int(feed.get("spoiled_total_scoops", -1)) == 0, "migration must not invent spoilage", failures)
	_assert_neutral_campus(restored, "v17", failures)

	var unknown_facility := legacy.duplicate(true)
	var bad_facilities := (unknown_facility.get("owned_facilities", {}) as Dictionary).duplicate(true)
	bad_facilities["mystery_grain_silo"] = 0
	unknown_facility["owned_facilities"] = bad_facilities
	_check(not DepartmentSimulation.new(18_113, 4).restore_save_state(_json_round_trip(unknown_facility)), "v17 migration should reject an unknown legacy facility", failures)


func _test_feed_tamper_rejection_is_atomic(failures: Array[String]) -> void:
	var valid := _json_round_trip(_active_reserve_fixture(18_121).export_save_state())
	var target := DepartmentSimulation.new(18_122, 6)
	var before := JSON.stringify(target.export_save_state())
	var corrupt := valid.duplicate(true)
	var feed_state := (corrupt.get("feed_procurement_state", {}) as Dictionary).duplicate(true)
	feed_state["invented_margin_cents"] = 1
	corrupt["feed_procurement_state"] = feed_state
	_check(not target.restore_save_state(corrupt), "unknown feed-ledger fields should reject", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "rejected unknown field should leave target state untouched", failures)

	corrupt = valid.duplicate(true)
	feed_state = (corrupt.get("feed_procurement_state", {}) as Dictionary).duplicate(true)
	var lots := (feed_state.get("lots", []) as Array).duplicate(true)
	if not lots.is_empty():
		var lot := (lots[0] as Dictionary).duplicate(true)
		lot["scoops_remaining"] = 55
		lots[0] = lot
	feed_state["lots"] = lots
	corrupt["feed_procurement_state"] = feed_state
	_check(not target.restore_save_state(corrupt), "inventory beyond tier capacity should reject", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "rejected capacity tamper should remain atomic", failures)

	corrupt = valid.duplicate(true)
	var corrupt_facilities := (corrupt.get("owned_facilities", {}) as Dictionary).duplicate(true)
	corrupt_facilities[String(PROVISIONS)] = 0
	corrupt["owned_facilities"] = corrupt_facilities
	_check(not target.restore_save_state(corrupt), "unowned facility may not retain prepaid lots", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "rejected ownership tamper should remain atomic", failures)


func _active_reserve_fixture(seed: int) -> DepartmentSimulation:
	var sim := DepartmentSimulation.new(seed, 6)
	sim.day = 12
	sim.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	sim.pending_decision.clear()
	sim.revenue_cents = 1_000_000
	sim.owned_facilities[PROVISIONS] = 3
	sim.authorize_feed_order(&"fixed_future_reserve")
	sim._prepare_morning_directive()
	sim.select_directive(&"shell_assurance")
	return sim


func _json_round_trip(source: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(source))
	return (parsed as Dictionary) if parsed is Dictionary else {}


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


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
