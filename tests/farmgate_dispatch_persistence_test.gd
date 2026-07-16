extends SceneTree


const DEPOT := DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID
const PACKING := DepartmentSimulation.PACKING_ANNEX_ID
const GALLERY := DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID


func _init() -> void:
	var failures: Array[String] = []
	_test_active_route_round_trip(failures)
	_test_neutral_v19_migration(failures)
	_test_corruption_rejects_atomically(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("FARMGATE_DISPATCH_PERSISTENCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARMGATE_DISPATCH_PERSISTENCE_TEST_PASSED schema=22 facilities=thirteen migration=v19-neutral lots=exact mandate=frozen capital=strict campus=neutral tamper=atomic")
	quit(0)


func _test_active_route_round_trip(failures: Array[String]) -> void:
	var source := _active_route_fixture(20_201)
	var exported := _json_round_trip(source.export_save_state())
	_check(int(exported.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "current dispatch state should export schema v23", failures)
	var facilities := exported.get("owned_facilities", {}) as Dictionary
	_check(facilities.size() == 13, "schema v23 should serialize exactly thirteen facility keys", failures)
	_check(int(facilities.get(String(DEPOT), -1)) == 1, "schema v23 should preserve depot tier one", failures)
	_check(exported.has("farmgate_dispatch_state"), "schema v23 should include the strict dispatch ledger", failures)
	_check(exported.has("pinned_capital_plan_id") and exported.has("facility_commissioning_history"), "schema v23 should persist capital planning and receipts", failures)
	_check(exported.has("campus_expansion"), "schema v23 should include the strict North Meadow ledger", failures)

	var restored := DepartmentSimulation.new(20_202, 6)
	_check(restored.restore_save_state(exported), "canonical active-route JSON should restore", failures)
	_check(restored.farmgate_dispatch_snapshot() == source.farmgate_dispatch_snapshot(), "lots, frozen mandate, season, and lifetime projection should round-trip", failures)
	_check(restored.capital_plan_snapshot() == source.capital_plan_snapshot(), "pinned plan and commissioning receipt should round-trip", failures)
	var settlement := restored._farmgate_dispatch.settle(6, 1, 8, 5)
	_check(bool(settlement.get("accepted", false)) and int(settlement.get("gross_cents", -1)) == 1_050, "restored county route should settle its frozen 105% quote", failures)


func _test_neutral_v19_migration(failures: Array[String]) -> void:
	var current := DepartmentSimulation.new(20_211, 4).export_save_state()
	var legacy := current.duplicate(true)
	legacy["state_version"] = 19
	var facilities := (legacy.get("owned_facilities", {}) as Dictionary).duplicate(true)
	facilities.erase(String(DEPOT))
	legacy["owned_facilities"] = facilities
	legacy.erase("farmgate_dispatch_state")
	legacy.erase("pinned_capital_plan_id")
	legacy.erase("last_facility_purchase_receipt")
	legacy.erase("facility_commissioning_history")
	legacy.erase("campus_expansion")
	legacy.erase("campus_expansion_state")
	_check(facilities.size() == 12, "v19 fixture should retain the exact twelve-key facility map", failures)
	var opening_fund := int(legacy.get("revenue_cents", -1))
	var restored := DepartmentSimulation.new(20_212, 4)
	_check(restored.restore_save_state(_json_round_trip(legacy)), "strict valid v19 checkpoint should migrate", failures)
	var migrated := restored.export_save_state()
	_check(int(migrated.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "v19 should re-export as schema v23", failures)
	_check((migrated.get("owned_facilities", {}) as Dictionary).size() == 13, "migration should append exactly one depot facility", failures)
	_check(restored.facility_level(DEPOT) == 0, "migration should append the depot unowned", failures)
	_check(restored.revenue_cents == opening_fund, "migration must not reclassify prior immediate egg cash", failures)
	var depot := restored.farmgate_dispatch_snapshot()
	_check(int(depot.get("stock_count", -1)) == 0 and int(depot.get("lifetime_gross_cents", -1)) == 0, "migration must invent neither stock nor dispatch value", failures)
	_check(StringName(migrated.get("pinned_capital_plan_id", &"")) == &"", "migration should create no pinned capital plan", failures)
	_check((migrated.get("facility_commissioning_history", []) as Array).is_empty(), "migration should create no commissioning history", failures)
	_assert_neutral_campus(restored, "v19", failures)

	var unknown := legacy.duplicate(true)
	var bad_facilities := (unknown.get("owned_facilities", {}) as Dictionary).duplicate(true)
	bad_facilities["unlicensed_egg_freighter"] = 0
	unknown["owned_facilities"] = bad_facilities
	_check(not DepartmentSimulation.new(20_213, 4).restore_save_state(_json_round_trip(unknown)), "v19 migration should reject an unknown facility", failures)


func _test_corruption_rejects_atomically(failures: Array[String]) -> void:
	var valid := _json_round_trip(_active_route_fixture(20_221).export_save_state())
	var target := DepartmentSimulation.new(20_222, 6)
	var before := JSON.stringify(target.export_save_state())

	var corrupt := valid.duplicate(true)
	var dispatch_state := (corrupt.get("farmgate_dispatch_state", {}) as Dictionary).duplicate(true)
	dispatch_state["invented_freight_margin_cents"] = 1
	corrupt["farmgate_dispatch_state"] = dispatch_state
	_check(not target.restore_save_state(corrupt), "unknown dispatch fields should reject", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "unknown-field rejection should leave target untouched", failures)

	corrupt = valid.duplicate(true)
	dispatch_state = (corrupt.get("farmgate_dispatch_state", {}) as Dictionary).duplicate(true)
	var active := (dispatch_state.get("active_mandate", {}) as Dictionary).duplicate(true)
	active["price_basis_points"] = 10_499
	dispatch_state["active_mandate"] = active
	corrupt["farmgate_dispatch_state"] = dispatch_state
	_check(not target.restore_save_state(corrupt), "repriced frozen county terms should reject", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "route repricing rejection should remain atomic", failures)

	corrupt = valid.duplicate(true)
	dispatch_state = (corrupt.get("farmgate_dispatch_state", {}) as Dictionary).duplicate(true)
	var lots := (dispatch_state.get("lots", []) as Array).duplicate(true)
	var lot := (lots[0] as Dictionary).duplicate(true)
	lot["expires_day"] = int(lot.get("expires_day", 0)) + 1
	lots[0] = lot
	dispatch_state["lots"] = lots
	corrupt["farmgate_dispatch_state"] = dispatch_state
	_check(not target.restore_save_state(corrupt), "tampered immutable lot expiry should reject", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "lot rejection should remain atomic", failures)

	corrupt = valid.duplicate(true)
	var history := (corrupt.get("facility_commissioning_history", []) as Array).duplicate(true)
	var receipt := (history[-1] as Dictionary).duplicate(true)
	receipt["cost_cents"] = int(receipt.get("cost_cents", 0)) + 1
	history[-1] = receipt
	corrupt["facility_commissioning_history"] = history
	corrupt["last_facility_purchase_receipt"] = receipt.duplicate(true)
	_check(not target.restore_save_state(corrupt), "repriced commissioning receipt should reject", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "commissioning rejection should remain atomic", failures)


func _active_route_fixture(seed: int) -> DepartmentSimulation:
	var sim := DepartmentSimulation.new(seed, 6)
	sim.day = 6
	sim.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	sim.pending_decision.clear()
	sim.revenue_cents = 1_000_000
	sim.owned_facilities[PACKING] = 1
	sim.owned_facilities[GALLERY] = 1
	_file_canonical_harvest_credit(sim, 5)
	sim.pin_capital_plan(DEPOT)
	var purchase := sim.purchase_facility(DEPOT)
	if not bool(purchase.get("accepted", false)):
		push_error("Fixture could not commission Farmgate tier one: %s" % String(purchase.get("reason", "unknown")))
	sim._farmgate_dispatch.begin_day(6)
	sim._farmgate_dispatch.store_lot(601, 6, 0, "Mabel", &"sound", 1_000, 1, 2, 12)
	sim.authorize_farmgate_dispatch(&"county_auction")
	return sim


func _file_canonical_harvest_credit(sim: DepartmentSimulation, completed_day: int) -> void:
	var evidence := {
		"day": completed_day,
		"eggs": 8,
		"quota": 8,
		"sound": 7,
		"cracked": 1,
		"golden": 1,
		"met_quota": true,
		"top_worker_id": 0,
		"top_worker_name": "Mabel",
		"hen_highlight": {
			"version": 1,
			"day": completed_day,
			"worker_id": 0,
			"worker_name": "Mabel",
			"tone": &"gold",
		},
	}
	sim._harvest_credit.stage_review(evidence, 1, false)
	sim._harvest_credit.commit_campaign(&"farmer_method", "Canonical depot gate credit.")


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
