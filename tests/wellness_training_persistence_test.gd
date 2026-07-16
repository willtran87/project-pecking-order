extends SceneTree


const WELLNESS := DepartmentSimulation.WELLNESS_NEST_ID
const TRAINING := DepartmentSimulation.TRAINING_ROOST_ID


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_test_current_schema_round_trip(failures)
	_test_strict_neutral_v14_migration(failures)
	_test_v14_corruption_rejected_atomically(failures)
	_test_v15_structural_validation(failures)
	_test_ownership_survives_staff_and_qualification_loss(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("WELLNESS_TRAINING_PERSISTENCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("WELLNESS_TRAINING_PERSISTENCE_TEST_PASSED schema=22 migration=14-neutral ledger=thirteen-key dependencies=strict ownership=permanent farmgate=neutral campus=neutral")
	quit(0)


func _test_current_schema_round_trip(failures: Array[String]) -> void:
	var source := DepartmentSimulation.new(15601, 6)
	source.day = 10
	source.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	source.pending_decision.clear()
	source.owned_facilities[WELLNESS] = 3
	source.owned_facilities[TRAINING] = 3
	source.workers[0].career_xp = 80
	source.workers[0].fatigue = 63.25
	source.workers[0].stress = 44.75
	source.workers[0].morale = 71.5
	var exported := source.export_save_state()
	_check(int(exported.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "current flock-care state should export schema v23", failures)
	var facilities := exported.get("owned_facilities", {}) as Dictionary
	_check(facilities.size() == 13, "schema v23 should serialize exactly thirteen facility keys", failures)
	_check(int(facilities.get(String(WELLNESS), -1)) == 3, "schema v23 should serialize Wellness tier 3", failures)
	_check(int(facilities.get(String(TRAINING), -1)) == 3, "schema v23 should serialize Training tier 3", failures)
	_check(exported.has("campus_expansion"), "schema v23 should serialize the strict North Meadow ledger", failures)

	var parsed: Variant = JSON.parse_string(JSON.stringify(exported))
	_check(parsed is Dictionary, "current state should remain primitive JSON", failures)
	if parsed is Dictionary:
		var restored := DepartmentSimulation.new(15602, 6)
		_check(restored.restore_save_state(parsed as Dictionary), "valid schema-v23 care state should restore", failures)
		var restored_round_trip := _json_round_trip(restored.export_save_state())
		_check(
			(parsed as Dictionary) == restored_round_trip,
			"schema-v23 care state should round-trip exactly",
			failures,
		)
		_check(restored.facility_effects() == source.facility_effects(), "schema-v23 restore should reproduce every derived care effect", failures)
		_check(restored.current_daily_facility_maintenance_cents() == 3000, "tier-3 care facilities should restore exact $30 total upkeep", failures)


func _test_strict_neutral_v14_migration(failures: Array[String]) -> void:
	var source := DepartmentSimulation.new(15611, 4)
	source.day = 8
	source.revenue_cents = 54_321
	source.quota_target = 37
	source.workers[0].morale = 67.25
	source.workers[0].fatigue = 38.5
	source.workers[0].stress = 42.75
	source.workers[0].career_xp = 45
	var current := source.export_save_state()
	var legacy := current.duplicate(true)
	legacy["state_version"] = 14
	var legacy_facilities := (legacy.get("owned_facilities", {}) as Dictionary).duplicate(true)
	legacy_facilities.erase(String(WELLNESS))
	legacy_facilities.erase(String(TRAINING))
	legacy_facilities.erase(String(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID))
	legacy_facilities.erase(String(DepartmentSimulation.IT_COOP_ID))
	legacy_facilities.erase(String(DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID))
	legacy_facilities.erase(String(DepartmentSimulation.FEED_PROCUREMENT_COOP_ID))
	legacy_facilities.erase(String(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID))
	legacy_facilities.erase(String(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID))
	legacy["owned_facilities"] = legacy_facilities
	legacy.erase("feed_procurement_state")
	legacy.erase("harvest_credit_state")
	legacy.erase("farmgate_dispatch_state")
	legacy.erase("pinned_capital_plan_id")
	legacy.erase("last_facility_purchase_receipt")
	legacy.erase("facility_commissioning_history")
	legacy.erase("campus_expansion")
	legacy.erase("campus_expansion_state")
	_check(legacy_facilities.size() == 5, "v14 migration fixture should contain the exact legacy five-key ledger", failures)

	var restored := DepartmentSimulation.new(15612, 4)
	_check(restored.restore_save_state(_json_round_trip(legacy)), "strict valid v14 state should migrate", failures)
	var migrated := restored.export_save_state()
	var migrated_facilities := migrated.get("owned_facilities", {}) as Dictionary
	_check(int(migrated.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "v14 should re-export as v23", failures)
	_check(int(migrated_facilities.get(String(WELLNESS), -1)) == 0, "v14 migration should append neutral Wellness level zero", failures)
	_check(int(migrated_facilities.get(String(TRAINING), -1)) == 0, "v14 migration should append neutral Training level zero", failures)
	_check(int(migrated_facilities.get(String(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID), -1)) == 0, "v14 migration should append neutral Farmgate level zero", failures)
	_check(int(restored.farmgate_dispatch_snapshot().get("stock_count", -1)) == 0, "v14 migration must not invent finished-egg stock", failures)
	_check(restored.current_daily_facility_maintenance_cents() == source.current_daily_facility_maintenance_cents(), "v14 migration must add no care upkeep", failures)
	_assert_neutral_campus(restored, "v14", failures)
	for invariant in [
		"revenue_cents", "quota_target", "rng_state", "claim_rng_state",
		"active_market_contract", "last_market_contract_result",
	]:
		_check(migrated.get(invariant) == current.get(invariant), "v14 migration should preserve %s exactly" % invariant, failures)
	_check(
		_json_round_trip({"workers": migrated.get("workers")})
		== _json_round_trip({"workers": current.get("workers")}),
		"v14 migration should preserve every worker state and career field",
		failures,
	)


func _test_v14_corruption_rejected_atomically(failures: Array[String]) -> void:
	var base := DepartmentSimulation.new(15621, 4).export_save_state()
	base["state_version"] = 14
	var base_facilities := (base.get("owned_facilities", {}) as Dictionary).duplicate(true)
	base_facilities.erase(String(WELLNESS))
	base_facilities.erase(String(TRAINING))
	base_facilities.erase(String(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID))
	base_facilities.erase(String(DepartmentSimulation.IT_COOP_ID))
	base_facilities.erase(String(DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID))
	base_facilities.erase(String(DepartmentSimulation.FEED_PROCUREMENT_COOP_ID))
	base_facilities.erase(String(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID))
	base_facilities.erase(String(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID))
	base["owned_facilities"] = base_facilities
	base.erase("feed_procurement_state")
	base.erase("harvest_credit_state")
	base.erase("farmgate_dispatch_state")
	base.erase("pinned_capital_plan_id")
	base.erase("last_facility_purchase_receipt")
	base.erase("facility_commissioning_history")
	base.erase("campus_expansion")
	base.erase("campus_expansion_state")

	var corrupt_states: Array[Dictionary] = []
	var missing := base.duplicate(true)
	var missing_facilities := (missing.get("owned_facilities", {}) as Dictionary).duplicate(true)
	missing_facilities.erase("candling_rework_bay")
	missing["owned_facilities"] = missing_facilities
	corrupt_states.append(missing)

	var extra := base.duplicate(true)
	var extra_facilities := (extra.get("owned_facilities", {}) as Dictionary).duplicate(true)
	extra_facilities["unlisted_barn"] = 0
	extra["owned_facilities"] = extra_facilities
	corrupt_states.append(extra)

	for bad_value in [0.5, "1", -1, 4]:
		var corrupt := base.duplicate(true)
		var facilities := (corrupt.get("owned_facilities", {}) as Dictionary).duplicate(true)
		facilities["farmer_brand_packing_annex"] = bad_value
		corrupt["owned_facilities"] = facilities
		corrupt_states.append(corrupt)

	for corrupt in corrupt_states:
		_expect_restore_rejected_atomically(corrupt, failures)


func _test_v15_structural_validation(failures: Array[String]) -> void:
	var valid := DepartmentSimulation.new(15631, 6)
	valid.day = 10
	valid.owned_facilities[WELLNESS] = 3
	valid.owned_facilities[TRAINING] = 3
	var valid_state := valid.export_save_state()

	var missing := valid_state.duplicate(true)
	var missing_facilities := (missing.get("owned_facilities", {}) as Dictionary).duplicate(true)
	missing_facilities.erase(String(TRAINING))
	missing["owned_facilities"] = missing_facilities
	_expect_restore_rejected_atomically(missing, failures)

	var unknown := valid_state.duplicate(true)
	var unknown_facilities := (unknown.get("owned_facilities", {}) as Dictionary).duplicate(true)
	unknown_facilities["unlisted_barn"] = 0
	unknown["owned_facilities"] = unknown_facilities
	_expect_restore_rejected_atomically(unknown, failures)

	var out_of_range := valid_state.duplicate(true)
	var range_facilities := (out_of_range.get("owned_facilities", {}) as Dictionary).duplicate(true)
	range_facilities[String(WELLNESS)] = 4
	out_of_range["owned_facilities"] = range_facilities
	_expect_restore_rejected_atomically(out_of_range, failures)

	var before_unlock := valid_state.duplicate(true)
	before_unlock["day"] = 8
	_expect_restore_rejected_atomically(before_unlock, failures)

	var broken_dependency := valid_state.duplicate(true)
	var dependency_facilities := (broken_dependency.get("owned_facilities", {}) as Dictionary).duplicate(true)
	dependency_facilities[String(WELLNESS)] = 2
	dependency_facilities[String(TRAINING)] = 3
	broken_dependency["owned_facilities"] = dependency_facilities
	_expect_restore_rejected_atomically(broken_dependency, failures)

	var small_office := DepartmentSimulation.new(15632, 4)
	small_office.day = 7
	small_office.owned_facilities[WELLNESS] = 2
	_expect_restore_rejected_atomically(small_office.export_save_state(), failures)


func _test_ownership_survives_staff_and_qualification_loss(failures: Array[String]) -> void:
	var source := DepartmentSimulation.new(15641, 4)
	source.day = 4
	source.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	source.pending_decision.clear()
	source.revenue_cents = 100_000
	source.workers[0].career_xp = 18
	source.owned_facilities[WELLNESS] = 1
	source.owned_facilities[TRAINING] = 1
	var release := source.release_worker(0)
	_check(bool(release.get("accepted", false)), "fixture should legitimately release the only qualified hen after purchase", failures)
	_check(source.active_worker_count() == 3, "fixture should fall below the original four-hen purchase gate", failures)
	_check(source._qualified_active_worker_count(1) == 0, "fixture should lose its current Training qualification", failures)
	var restored := DepartmentSimulation.new(15642, 4)
	_check(restored.restore_save_state(_json_round_trip(source.export_save_state())), "staff and qualification loss must not demote permanent facility ownership", failures)
	_check(restored.facility_level(WELLNESS) == 1 and restored.facility_level(TRAINING) == 1, "permanent care tiers should survive later roster loss", failures)


func _expect_restore_rejected_atomically(data: Dictionary, failures: Array[String]) -> void:
	var target := DepartmentSimulation.new(15699, 4)
	var before := JSON.stringify(target.export_save_state())
	_check(not target.restore_save_state(data), "corrupt care checkpoint should fail closed", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "rejected care checkpoint should not partially mutate the target", failures)


func _json_round_trip(value: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(value))
	return parsed as Dictionary if parsed is Dictionary else {}


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
