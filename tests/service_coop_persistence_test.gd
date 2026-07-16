extends SceneTree


const COOP: StringName = &"farm_mutual_service_coop"
const RECORDS: StringName = &"records_annex"
const ROOM: StringName = &"farm_mutual_negotiation_room"
const LOW: StringName = &"homestead_stability_binder"
const HIGH: StringName = &"exceptions_retention_covenant"


func _init() -> void:
	var failures: Array[String] = []
	_test_current_tier_and_frozen_contract_round_trips(failures)
	_test_settled_bonus_standing_and_streak_round_trip(failures)
	_test_v12_migrates_neutral_coop_and_legacy_contract_terms(failures)
	_test_corrupt_coop_and_streak_state_fails_closed(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("SERVICE_COOP_PERSISTENCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SERVICE_COOP_PERSISTENCE_TEST_PASSED schema=v23 facilities=thirteen-key coop=0-3 frozen-premium=exact streak=strict migration=v12-neutral+farmgate-neutral+campus-neutral+treasury-neutral corruption=atomic")
	quit(0)


func _test_current_tier_and_frozen_contract_round_trips(failures: Array[String]) -> void:
	_check(DepartmentSimulation.SAVE_STATE_VERSION == 23, "Farm Treasury should own schema v23", failures)
	var tier_source := DepartmentSimulation.new(9851, 5)
	tier_source.day = 3
	tier_source.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	tier_source.pending_decision.clear()
	tier_source.owned_facilities[RECORDS] = 2
	tier_source.owned_facilities[COOP] = 2
	var tier_state := _json_dictionary(tier_source.export_save_state(), "tier two", failures)
	_check(tier_state.has("campus_expansion"), "current Service Coop state should include the North Meadow ledger", failures)
	if not tier_state.is_empty():
		var restored_tier := DepartmentSimulation.new(9852, 4)
		_check(restored_tier.restore_save_state(tier_state), "tier-two Coop JSON should restore even after standing later falls", failures)
		_check(restored_tier.facility_level(COOP) == 2, "tier round trip should preserve Service Coop level two", failures)
		_check(restored_tier.farm_mutual_standing() == 0, "ownership should not invent standing on restore", failures)
		_check(int(restored_tier.facility_effects().get("farm_mutual_premium_bonus_basis_points", -1)) == 10_000, "restored tier two should retain its 100% success bonus", failures)

	var active_source := DepartmentSimulation.new(9853, 6)
	active_source.day = 3
	active_source.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	active_source.pending_decision.clear()
	active_source.owned_facilities[RECORDS] = 3
	active_source.owned_facilities[COOP] = 2
	active_source.revenue_cents = 100_000
	_check(bool(active_source.sign_market_contract(HIGH).get("accepted", false)), "active persistence fixture should sign Exceptions", failures)
	var active_state := _json_dictionary(active_source.export_save_state(), "frozen active", failures)
	if not active_state.is_empty():
		var restored_active := DepartmentSimulation.new(9854, 4)
		_check(restored_active.restore_save_state(active_state), "frozen level-two contract JSON should restore", failures)
		var active := restored_active.active_market_contract
		_check(int(active.get("base_premium_cents", -1)) == 2400, "active restore should retain the $24 base premium", failures)
		_check(int(active.get("service_coop_level_at_signing", -1)) == 2, "active restore should retain signing level two", failures)
		_check(int(active.get("service_coop_bonus_cents", -1)) == 2400, "active restore should retain the exact $24 Coop bonus", failures)
		_check(int(active.get("premium_bonus_basis_points", -1)) == 10_000 and int(active.get("premium_cents", -1)) == 4800, "active restore should retain 100% and the $48 total", failures)
		_check(int(active.get("required_active_staff", -1)) == 6, "active restore should retain its six-hen commitment", failures)


func _test_settled_bonus_standing_and_streak_round_trip(failures: Array[String]) -> void:
	var source := DepartmentSimulation.new(9861, 6)
	source.day = 3
	source.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	source.pending_decision.clear()
	source.owned_facilities[RECORDS] = 3
	source.owned_facilities[COOP] = 2
	source.revenue_cents = 100_000
	_check(bool(source.sign_market_contract(HIGH).get("accepted", false)), "settled persistence fixture should sign", failures)
	_set_completed_threshold(source)
	var result := source.call("_settle_market_contract", 3) as Dictionary
	_check(bool(result.get("success", false)), "settled persistence fixture should fulfill", failures)
	_check(int(result.get("base_premium_cents", -1)) == 2400 and int(result.get("service_coop_bonus_cents", -1)) == 2400, "settled fixture should itemize base and Coop equally", failures)
	var state := _json_dictionary(source.export_save_state(), "settled Coop", failures)
	if state.is_empty():
		return
	var restored := DepartmentSimulation.new(9862, 4)
	_check(restored.restore_save_state(state), "settled Service Coop JSON should restore", failures)
	_check(restored.market_contract_premium_total_cents == 4800, "settled restore should preserve the exact $48 total premium", failures)
	_check(restored.market_contracts_succeeded_total == 1 and restored.farm_mutual_standing() == 2, "settled restore should derive Bronze standing from one success", failures)
	_check(restored.market_clean_contract_streak == 1 and restored.best_market_clean_contract_streak == 1, "settled restore should preserve both streak ledgers", failures)
	_check(int(restored.last_market_contract_result.get("service_coop_bonus_cents", -1)) == 2400, "settled restore should retain the earned Coop line item", failures)


func _test_v12_migrates_neutral_coop_and_legacy_contract_terms(failures: Array[String]) -> void:
	var active_source := DepartmentSimulation.new(9871, 4)
	active_source.day = 3
	active_source.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	active_source.pending_decision.clear()
	active_source.revenue_cents = 100_000
	_check(bool(active_source.sign_market_contract(LOW).get("accepted", false)), "legacy active fixture should sign level-zero Homestead", failures)
	var legacy_active := _to_v12(active_source.export_save_state())
	var active_restore := DepartmentSimulation.new(9872, 4)
	_check(active_restore.restore_save_state(legacy_active), "v12 active binder should migrate", failures)
	_check(active_restore.facility_level(COOP) == 0, "v12 migration must not invent Service Coop ownership", failures)
	_check(int(active_restore.active_market_contract.get("service_coop_level_at_signing", -1)) == 0, "v12 active binder should freeze at level zero", failures)
	_check(int(active_restore.active_market_contract.get("service_coop_bonus_cents", -1)) == 0 and int(active_restore.active_market_contract.get("premium_cents", -1)) == 1000, "v12 active binder must retain its original $10 premium", failures)
	_check(bool(active_restore.active_market_contract.get("legacy_staffing_grandfathered", false)) and int(active_restore.active_market_contract.get("required_active_staff", -1)) == 0, "v12 active staffing should remain explicitly grandfathered", failures)
	_assert_neutral_campus(active_restore, "v12 active migration", failures)

	var result_source := DepartmentSimulation.new(9873, 4)
	result_source.day = 3
	result_source.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	result_source.pending_decision.clear()
	result_source.revenue_cents = 100_000
	_check(bool(result_source.sign_market_contract(LOW).get("accepted", false)), "legacy result fixture should sign", failures)
	_set_completed_threshold(result_source)
	_check(bool((result_source.call("_settle_market_contract", 3) as Dictionary).get("success", false)), "legacy result fixture should fulfill", failures)
	var legacy_result := _to_v12(result_source.export_save_state())
	var result_restore := DepartmentSimulation.new(9874, 4)
	_check(result_restore.restore_save_state(legacy_result), "v12 fulfilled receipt should migrate", failures)
	_check(result_restore.market_clean_contract_streak == 1 and result_restore.best_market_clean_contract_streak == 1, "known v12 fulfillment should seed only one proven clean streak", failures)
	_check(result_restore.farm_mutual_standing() == 2, "v12 fulfillment should contribute its actual derived standing", failures)
	_check(int(result_restore.last_market_contract_result.get("service_coop_bonus_cents", -1)) == 0, "v12 fulfilled receipt must not invent a Coop bonus", failures)
	_check(int(result_restore.export_save_state().get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "migrated v12 state should re-export schema v23", failures)
	_check(result_restore.facility_level(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID) == 0, "v12 migration must append a neutral Farmgate Depot", failures)
	_check(int(result_restore.farmgate_dispatch_snapshot().get("stock_count", -1)) == 0, "v12 migration must not invent finished-egg stock", failures)
	_assert_neutral_campus(result_restore, "v12 settled migration", failures)


func _test_corrupt_coop_and_streak_state_fails_closed(failures: Array[String]) -> void:
	var active := DepartmentSimulation.new(9881, 6)
	active.day = 3
	active.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	active.pending_decision.clear()
	active.owned_facilities[RECORDS] = 3
	active.owned_facilities[COOP] = 2
	active.revenue_cents = 100_000
	_check(bool(active.sign_market_contract(HIGH).get("accepted", false)), "corruption fixture should sign", failures)
	var active_state := _json_dictionary(active.export_save_state(), "corrupt active", failures)
	if not active_state.is_empty():
		var corrupt_bonus := active_state.duplicate(true)
		var contract := (corrupt_bonus.get("active_market_contract", {}) as Dictionary).duplicate(true)
		contract["service_coop_bonus_cents"] = int(contract.get("service_coop_bonus_cents", 0)) + 1
		corrupt_bonus["active_market_contract"] = contract
		_expect_restore_rejected_atomic(corrupt_bonus, "one invented Coop bonus cent", failures)

	var tier_state := DepartmentSimulation.new(9882, 5).export_save_state().duplicate(true)
	tier_state["day"] = 3
	var facilities := (tier_state.get("owned_facilities", {}) as Dictionary).duplicate(true)
	facilities[String(COOP)] = 2
	facilities[String(RECORDS)] = 0
	tier_state["owned_facilities"] = facilities
	_expect_restore_rejected_atomic(tier_state, "Coop level two without permanent Records capacity", failures)

	var corrupt_streak := DepartmentSimulation.new(9883, 4).export_save_state().duplicate(true)
	corrupt_streak["market_contracts_signed_total"] = 2
	corrupt_streak["market_contracts_succeeded_total"] = 2
	corrupt_streak["market_clean_contract_streak"] = 2
	corrupt_streak["best_market_clean_contract_streak"] = 1
	_expect_restore_rejected_atomic(corrupt_streak, "current clean streak above best", failures)


func _to_v12(source: Dictionary) -> Dictionary:
	var legacy := _json_dictionary(source, "v12 conversion", [] as Array[String])
	legacy["state_version"] = 12
	legacy.erase("market_clean_contract_streak")
	legacy.erase("best_market_clean_contract_streak")
	var facilities := (legacy.get("owned_facilities", {}) as Dictionary).duplicate(true)
	facilities.erase(String(COOP))
	facilities.erase(COOP)
	facilities.erase(String(ROOM))
	facilities.erase(ROOM)
	facilities.erase(String(DepartmentSimulation.WELLNESS_NEST_ID))
	facilities.erase(String(DepartmentSimulation.TRAINING_ROOST_ID))
	facilities.erase(String(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID))
	facilities.erase(String(DepartmentSimulation.IT_COOP_ID))
	facilities.erase(String(DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID))
	facilities.erase(String(DepartmentSimulation.FEED_PROCUREMENT_COOP_ID))
	facilities.erase(String(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID))
	facilities.erase(String(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID))
	legacy["owned_facilities"] = facilities
	legacy.erase("feed_procurement_state")
	legacy.erase("harvest_credit_state")
	legacy.erase("farmgate_dispatch_state")
	legacy.erase("pinned_capital_plan_id")
	legacy.erase("last_facility_purchase_receipt")
	legacy.erase("facility_commissioning_history")
	legacy.erase("campus_expansion")
	var active := (legacy.get("active_market_contract", {}) as Dictionary).duplicate(true)
	for field in [
		"required_active_staff",
		"legacy_staffing_grandfathered",
		"base_premium_cents",
		"service_coop_level_at_signing",
		"service_coop_bonus_cents",
		"premium_bonus_basis_points",
	]:
		active.erase(field)
	legacy["active_market_contract"] = active
	var result := (legacy.get("last_market_contract_result", {}) as Dictionary).duplicate(true)
	for field in [
		"required_active_staff",
		"base_premium_cents",
		"service_coop_level_at_signing",
		"service_coop_bonus_cents",
		"contracted_service_coop_bonus_cents",
		"premium_bonus_basis_points",
		"market_standing_before",
		"market_standing_after",
		"market_standing_delta",
		"market_standing_rank",
		"clean_contract_streak_before",
		"clean_contract_streak_after",
		"best_clean_contract_streak",
		"claim_ids",
		"accepted_claim_ids",
		"rejected_claim_ids",
	]:
		result.erase(field)
	legacy["last_market_contract_result"] = result
	return legacy


func _set_completed_threshold(simulation: DepartmentSimulation) -> void:
	var required := int(simulation.active_market_contract.get("required_completed", 0))
	simulation.active_market_contract["timely_sound_completed"] = required
	simulation.active_market_contract["sound_completed"] = required
	simulation.active_market_contract["completed_count"] = required
	var schedules := simulation.active_market_contract.get("scheduled_claims", []) as Array
	var accepted_ids: Array[int] = []
	for index in mini(required, schedules.size()):
		var schedule := (schedules[index] as Dictionary).duplicate(true)
		schedule["released"] = true
		schedule["rejected"] = false
		accepted_ids.append(int(schedule.get("claim_id", -1)))
		schedules[index] = schedule
	simulation.active_market_contract["scheduled_claims"] = schedules
	simulation.active_market_contract["accepted_claim_ids"] = accepted_ids


func _json_dictionary(source: Dictionary, context: String, failures: Array[String]) -> Dictionary:
	_check(int(source.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "%s should export schema v23" % context, failures)
	var parsed: Variant = JSON.parse_string(JSON.stringify(source))
	_check(parsed is Dictionary, "%s should remain primitive JSON" % context, failures)
	return parsed as Dictionary if parsed is Dictionary else {}


func _expect_restore_rejected_atomic(corrupt: Dictionary, message: String, failures: Array[String]) -> void:
	var fallback := DepartmentSimulation.new(9889, 4)
	var before := fallback.export_save_state().duplicate(true)
	_check(not fallback.restore_save_state(corrupt), "%s should fail closed" % message, failures)
	_check(fallback.export_save_state() == before, "%s should preserve fallback state" % message, failures)


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
