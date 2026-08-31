extends SceneTree


const GALLERY := DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID
const PACKING := DepartmentSimulation.PACKING_ANNEX_ID


func _init() -> void:
	var failures: Array[String] = []
	_test_open_and_filed_round_trip(failures)
	_test_neutral_v18_migration(failures)
	_test_corrupt_gallery_state_rejects_atomically(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("HARVEST_CREDIT_PERSISTENCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("HARVEST_CREDIT_PERSISTENCE_TEST_PASSED schema=22 facilities=thirteen migration=v18-neutral+campus-neutral review=exact receipt=strict tamper=atomic")
	quit(0)


func _test_open_and_filed_round_trip(failures: Array[String]) -> void:
	var source := _completed_shift_fixture(19_301)
	var exported := _json_round_trip(source.export_save_state())
	_check(int(exported.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "current Gallery state should export schema v24", failures)
	var facilities := exported.get("owned_facilities", {}) as Dictionary
	_check(facilities.size() == 13, "schema v24 should serialize exactly thirteen facility keys", failures)
	_check(int(facilities.get(String(GALLERY), -1)) == 1, "schema v24 should preserve Gallery tier one", failures)
	_check(exported.has("harvest_credit_state"), "schema v24 should include the strict Harvest Credit ledger", failures)
	_check(exported.has("campus_expansion"), "schema v24 should include the North Meadow ledger", failures)

	var restored := DepartmentSimulation.new(19_302, 6)
	_check(restored.restore_save_state(exported), "valid open Gallery JSON should restore", failures)
	_check(restored.farmer_relations_gallery_snapshot() == source.farmer_relations_gallery_snapshot(), "open review projection should round-trip exactly", failures)
	var result := restored.file_farmer_relations_campaign(&"layer_profile")
	_check(bool(result.get("accepted", false)), "restored open review should remain actionable", failures)
	var filed_state := _json_round_trip(restored.export_save_state())
	var filed_restore := DepartmentSimulation.new(19_303, 6)
	_check(filed_restore.restore_save_state(filed_state), "filed campaign JSON should restore", failures)
	_check(filed_restore.farmer_relations_gallery_snapshot() == restored.farmer_relations_gallery_snapshot(), "filed receipt, standing, attribution, and history should round-trip", failures)


func _test_neutral_v18_migration(failures: Array[String]) -> void:
	var current := DepartmentSimulation.new(19_311, 4).export_save_state()
	var legacy := current.duplicate(true)
	legacy["state_version"] = 18
	var facilities := (legacy.get("owned_facilities", {}) as Dictionary).duplicate(true)
	facilities.erase(String(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID))
	facilities.erase(String(GALLERY))
	legacy["owned_facilities"] = facilities
	legacy.erase("harvest_credit_state")
	legacy.erase("farmgate_dispatch_state")
	legacy.erase("pinned_capital_plan_id")
	legacy.erase("last_facility_purchase_receipt")
	legacy.erase("facility_commissioning_history")
	legacy.erase("campus_expansion")
	_check(facilities.size() == 11, "v18 fixture should retain the exact eleven-key facility map", failures)
	var restored := DepartmentSimulation.new(19_312, 4)
	_check(restored.restore_save_state(_json_round_trip(legacy)), "strict valid v18 checkpoint should migrate", failures)
	var migrated := restored.export_save_state()
	_check(int(migrated.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "v18 should re-export as schema v24", failures)
	_check((migrated.get("owned_facilities", {}) as Dictionary).size() == 13, "migration should append the Gallery and Depot facilities", failures)
	_check(restored.facility_level(GALLERY) == 0, "migration should append the Gallery unowned", failures)
	var gallery := restored.farmer_relations_gallery_snapshot()
	_check(int(gallery.get("standing_points", -1)) == 0, "migration must not invent public standing", failures)
	_check(int(gallery.get("total_campaigns", -1)) == 0, "migration must not invent campaigns", failures)
	_check(int(gallery.get("payout_total_cents", -1)) == 0, "migration must not invent publicity payout", failures)
	_check((gallery.get("shift_evidence", {}) as Dictionary).is_empty(), "migration must not invent completed-shift evidence", failures)
	_assert_neutral_campus(restored, "v18 migration", failures)

	var unknown := legacy.duplicate(true)
	var bad_facilities := (unknown.get("owned_facilities", {}) as Dictionary).duplicate(true)
	bad_facilities["unlicensed_billboard"] = 0
	unknown["owned_facilities"] = bad_facilities
	_check(not DepartmentSimulation.new(19_313, 4).restore_save_state(_json_round_trip(unknown)), "v18 migration should reject an unknown facility", failures)


func _test_corrupt_gallery_state_rejects_atomically(failures: Array[String]) -> void:
	var filed := _completed_shift_fixture(19_321)
	filed.file_farmer_relations_campaign(&"farmer_method")
	var valid := _json_round_trip(filed.export_save_state())
	var target := DepartmentSimulation.new(19_322, 6)
	var before := JSON.stringify(target.export_save_state())

	var corrupt := valid.duplicate(true)
	var credit_state := (corrupt.get("harvest_credit_state", {}) as Dictionary).duplicate(true)
	credit_state["invented_press_margin_cents"] = 1
	corrupt["harvest_credit_state"] = credit_state
	_check(not target.restore_save_state(corrupt), "unknown Harvest Credit fields should reject", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "unknown-field rejection should leave the target untouched", failures)

	corrupt = valid.duplicate(true)
	credit_state = (corrupt.get("harvest_credit_state", {}) as Dictionary).duplicate(true)
	var history := (credit_state.get("history", []) as Array).duplicate(true)
	if not history.is_empty():
		var receipt := (history[-1] as Dictionary).duplicate(true)
		receipt["payout_cents"] = int(receipt.get("payout_cents", 0)) + 1
		history[-1] = receipt
		credit_state["last_receipt"] = receipt.duplicate(true)
	credit_state["history"] = history
	corrupt["harvest_credit_state"] = credit_state
	_check(not target.restore_save_state(corrupt), "a repriced publicity receipt should reject", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "repricing rejection should remain atomic", failures)

	corrupt = valid.duplicate(true)
	var corrupt_facilities := (corrupt.get("owned_facilities", {}) as Dictionary).duplicate(true)
	corrupt_facilities[String(GALLERY)] = 0
	corrupt["owned_facilities"] = corrupt_facilities
	_check(not target.restore_save_state(corrupt), "an unowned Gallery may not retain a filed campaign ledger", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "ownership rejection should remain atomic", failures)


func _completed_shift_fixture(seed: int) -> DepartmentSimulation:
	var sim := DepartmentSimulation.new(seed, 6)
	sim.day = 5
	sim.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	sim.pending_decision.clear()
	sim.revenue_cents = 1_000_000
	sim.owned_facilities[PACKING] = 1
	sim.owned_facilities[GALLERY] = 1
	sim.eggs_today = 10
	sim.cracked_today = 2
	sim.golden_today = 1
	sim.eggs_total = 10
	sim.cracked_eggs = 2
	sim.golden_eggs = 1
	sim.quota_target = 8
	var row: Dictionary = sim._worker_shift_stats[0]
	row.merge({"eggs": 10, "sound": 7, "cracked": 2, "golden": 1, "credit_cents": 2_600}, true)
	sim._worker_shift_stats[0] = row
	sim._complete_workday()
	return sim


func _json_round_trip(source: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(source))
	return (parsed as Dictionary) if parsed is Dictionary else {}


func _assert_neutral_campus(simulation: DepartmentSimulation, context: String, failures: Array[String]) -> void:
	var campus := simulation.export_save_state().get("campus_expansion", {}) as Dictionary
	var services := campus.get("services", {}) as Dictionary
	_check(not bool(campus.get("parcel_owned", true)), "%s must not invent North Meadow ownership" % context, failures)
	_check(
		services.size() == 3
		and not bool(services.get("circulation", true))
		and not bool(services.get("power", true))
		and not bool(services.get("cold_chain", true)),
		"%s must leave all North Meadow services disconnected" % context,
		failures,
	)
	_check(
		not bool(campus.get("pod_owned", true)) and String(campus.get("pod_socket_id", "")).is_empty(),
		"%s must not invent Egg Routing Pod ownership or placement" % context,
		failures,
	)
	_check(
		int(campus.get("capital_spend_total_cents", -1)) == 0
		and int(campus.get("next_receipt_id", -1)) == 1
		and (campus.get("last_receipt", {}) as Dictionary).is_empty()
		and (campus.get("history", []) as Array).is_empty(),
		"%s must retain an exact neutral North Meadow receipt ledger" % context,
		failures,
	)
	var projection := simulation.campus_expansion_snapshot()
	_check(
		not bool(projection.get("pod_operational", true))
		and int(projection.get("claim_capacity_bonus", -1)) == 0
		and int(projection.get("farmgate_capacity_bonus_eggs", -1)) == 0
		and int(projection.get("current_daily_cost_cents", -1)) == 0,
		"%s must retain zero North Meadow operations, capacity, and daily cost" % context,
		failures,
	)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
