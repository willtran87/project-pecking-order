extends SceneTree


const LOW: StringName = &"homestead_stability_binder"
const HIGH: StringName = &"exceptions_retention_covenant"
const RECORDS: StringName = &"records_annex"
const COOP: StringName = &"farm_mutual_service_coop"
const ROOM: StringName = &"farm_mutual_negotiation_room"
const V14_QUOTE_FIELDS: Array[String] = [
	"quote_id",
	"season",
	"season_id",
	"season_label",
	"season_demand_basis_points",
	"clause_id",
	"clause_label",
	"clause_summary",
	"clause_category",
	"category",
	"label",
	"summary",
	"requires_negotiation_room",
	"clause_available",
	"negotiation_room_level_at_signing",
	"authored_service_window_minutes",
	"authored_dominant_lane",
	"authored_lane_mix",
	"authored_base_premium_cents",
	"season_premium_delta_cents",
	"clause_premium_basis_points",
	"clause_premium_delta_cents",
	"market_premium_cents",
	"contracted_premium_cents",
	"authored_breach_cents",
	"season_breach_basis_points",
	"season_breach_delta_cents",
	"clause_breach_basis_points",
	"clause_breach_delta_cents",
	"contracted_breach_cents",
	"welfare_gate_minimum",
	"welfare_gate_required",
	"legacy_terms_grandfathered",
	"delivery_threshold_met",
	"welfare_gate_met",
	"closing_welfare",
]


func _init() -> void:
	var failures: Array[String] = []
	_test_v14_active_and_result_round_trips(failures)
	_test_v14_corruption_fails_closed(failures)
	_test_v13_neutral_migration(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("MARKET_CONTRACT_SEASON_CLAUSE_PERSISTENCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MARKET_CONTRACT_SEASON_CLAUSE_PERSISTENCE_TEST_PASSED schema=v23 facilities=thirteen-key schedules=exact+tamper-closed v13=evidence-preserved+farmgate-neutral+campus-neutral+treasury-neutral corruption=atomic")
	quit(0)


func _test_v14_active_and_result_round_trips(failures: Array[String]) -> void:
	_check(DepartmentSimulation.SAVE_STATE_VERSION == 26, "connected incident case memory should own simulation schema v26", failures)
	var active_sim := _room_simulation(9940, 12)
	_check(bool(active_sim.sign_market_contract(HIGH, &"specialist_roost_endorsement").get("accepted", false)), "active round-trip fixture should sign Specialist Roost", failures)
	var active_export := active_sim.export_save_state()
	_check(int(active_export.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION and active_export.has("campus_expansion"), "active binder should export schema v24 with the North Meadow ledger", failures)
	var saved_active := active_export.get("active_market_contract", {}) as Dictionary
	var active_state := _json(active_export, failures)
	var active_restore := DepartmentSimulation.new(9941, 6)
	_check(active_restore.restore_save_state(active_state), "v14 negotiated active JSON should restore", failures)
	var active := active_restore.active_market_contract
	_check(
		active.get("scheduled_claims", []) == saved_active.get("scheduled_claims", []),
		"active restore should preserve every exact per-claim schedule field: %s != %s" % [JSON.stringify(active.get("scheduled_claims", [])), JSON.stringify(saved_active.get("scheduled_claims", []))],
		failures,
	)
	_check(String(active.get("season_id", "")) == "autumn_retention_audit", "active restore should preserve its signed season", failures)
	_check(String(active.get("clause_id", "")) == "specialist_roost_endorsement", "active restore should preserve its signed clause", failures)
	_check(active.get("lane_mix", {}) == {"appeals": 6}, "active restore should preserve its transformed lane mix", failures)
	_check(int(active.get("premium_cents", -1)) == 7300 and int(active.get("breach_cents", -1)) == 1615, "active restore should preserve every contracted cent", failures)

	var result_sim := _room_simulation(9942, 6)
	_check(bool(result_sim.sign_market_contract(LOW, &"rested_flock_warranty").get("accepted", false)), "result fixture should sign Rested Flock", failures)
	_set_threshold(result_sim)
	_set_welfare(result_sim, 82.0, 0.0, 0.0)
	var receipt := result_sim.call("_settle_market_contract", result_sim.day) as Dictionary
	_check(bool(receipt.get("success", false)), "result fixture should fulfill before persistence", failures)
	var result_export := result_sim.export_save_state()
	_check(int(result_export.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION and result_export.has("campus_expansion"), "settled binder should export schema v24 with the North Meadow ledger", failures)
	var saved_result := result_export.get("last_market_contract_result", {}) as Dictionary
	var result_state := _json(result_export, failures)
	var result_restore := DepartmentSimulation.new(9943, 6)
	_check(result_restore.restore_save_state(result_state), "v14 negotiated result JSON should restore", failures)
	var restored_result := result_restore.last_market_contract_result
	_check(
		restored_result.get("scheduled_claims", []) == saved_result.get("scheduled_claims", []),
		"settled restore should preserve exact claim IDs and release/rejection evidence: %s != %s" % [JSON.stringify(restored_result.get("scheduled_claims", [])), JSON.stringify(saved_result.get("scheduled_claims", []))],
		failures,
	)
	for field in ["claim_ids", "accepted_claim_ids", "rejected_claim_ids"]:
		_check(
			restored_result.get(field, []) == saved_result.get(field, []),
			"settled restore should preserve the exact %s ledger: %s != %s" % [field, JSON.stringify(restored_result.get(field, [])), JSON.stringify(saved_result.get(field, []))],
			failures,
		)
	_check(String(restored_result.get("clause_id", "")) == "rested_flock_warranty", "result restore should preserve Rested Flock", failures)
	_check(int(restored_result.get("closing_welfare", -1)) >= 72 and bool(restored_result.get("welfare_gate_met", false)), "result restore should preserve welfare settlement evidence", failures)
	_check(int(restored_result.get("contracted_premium_cents", -1)) == 3060 and int(restored_result.get("premium_cents", -1)) == 3060, "result restore should distinguish and preserve contracted versus paid cents", failures)


func _test_v14_corruption_fails_closed(failures: Array[String]) -> void:
	var simulation := _room_simulation(9950, 12)
	_check(bool(simulation.sign_market_contract(HIGH, &"specialist_roost_endorsement").get("accepted", false)), "corruption fixture should sign", failures)
	var state := _json(simulation.export_save_state(), failures)

	var corrupt_season := state.duplicate(true)
	var season_contract := (corrupt_season.get("active_market_contract", {}) as Dictionary).duplicate(true)
	var season := (season_contract.get("season", {}) as Dictionary).duplicate(true)
	season["id"] = "winter_feed_fund_squeeze"
	season_contract["season"] = season
	corrupt_season["active_market_contract"] = season_contract
	_expect_rejected(corrupt_season, "altered season identity", failures)

	var corrupt_money := state.duplicate(true)
	var money_contract := (corrupt_money.get("active_market_contract", {}) as Dictionary).duplicate(true)
	money_contract["season_premium_delta_cents"] = int(money_contract.get("season_premium_delta_cents", 0)) + 1
	corrupt_money["active_market_contract"] = money_contract
	_expect_rejected(corrupt_money, "one invented seasonal premium cent", failures)

	var corrupt_clause := state.duplicate(true)
	var clause_contract := (corrupt_clause.get("active_market_contract", {}) as Dictionary).duplicate(true)
	clause_contract["clause_id"] = "standard_terms"
	corrupt_clause["active_market_contract"] = clause_contract
	_expect_rejected(corrupt_clause, "clause ID with mismatched frozen terms", failures)

	var missing_room := state.duplicate(true)
	var missing_room_facilities := (missing_room.get("owned_facilities", {}) as Dictionary).duplicate(true)
	missing_room_facilities[String(ROOM)] = 0
	missing_room["owned_facilities"] = missing_room_facilities
	_expect_rejected(missing_room, "negotiated binder without its frozen owned room", failures)

	var broken_dependency := state.duplicate(true)
	var broken_facilities := (broken_dependency.get("owned_facilities", {}) as Dictionary).duplicate(true)
	broken_facilities[String(COOP)] = 2
	broken_dependency["owned_facilities"] = broken_facilities
	_expect_rejected(broken_dependency, "owned room without structural Service Coop level three", failures)

	var corrupt_authored_lane := state.duplicate(true)
	var lane_contract := (corrupt_authored_lane.get("active_market_contract", {}) as Dictionary).duplicate(true)
	var lane_schedules := (lane_contract.get("scheduled_claims", []) as Array).duplicate(true)
	if not lane_schedules.is_empty():
		var lane_schedule := (lane_schedules[0] as Dictionary).duplicate(true)
		lane_schedule["authored_lane"] = "tampered_lane"
		lane_schedules[0] = lane_schedule
		lane_contract["scheduled_claims"] = lane_schedules
		corrupt_authored_lane["active_market_contract"] = lane_contract
		_expect_rejected(corrupt_authored_lane, "altered active authored lane evidence", failures)

	var corrupt_authored_rush := state.duplicate(true)
	var rush_contract := (corrupt_authored_rush.get("active_market_contract", {}) as Dictionary).duplicate(true)
	var rush_schedules := (rush_contract.get("scheduled_claims", []) as Array).duplicate(true)
	if not rush_schedules.is_empty():
		var rush_schedule := (rush_schedules[0] as Dictionary).duplicate(true)
		rush_schedule["authored_rush"] = not bool(rush_schedule.get("authored_rush", false))
		rush_schedules[0] = rush_schedule
		rush_contract["scheduled_claims"] = rush_schedules
		corrupt_authored_rush["active_market_contract"] = rush_contract
		_expect_rejected(corrupt_authored_rush, "altered active authored rush evidence", failures)

	var welfare_sim := _room_simulation(9951, 6)
	_check(bool(welfare_sim.sign_market_contract(LOW, &"rested_flock_warranty").get("accepted", false)), "welfare corruption fixture should sign", failures)
	_set_threshold(welfare_sim)
	_set_welfare(welfare_sim, 82.0, 0.0, 0.0)
	welfare_sim.call("_settle_market_contract", welfare_sim.day)
	var valid_welfare_state := _json(welfare_sim.export_save_state(), failures)
	var welfare_state := valid_welfare_state.duplicate(true)
	var welfare_result := (valid_welfare_state.get("last_market_contract_result", {}) as Dictionary).duplicate(true)
	welfare_result["closing_welfare"] = 71
	welfare_state["last_market_contract_result"] = welfare_result
	_expect_rejected(welfare_state, "fulfilled Rested Flock result below its welfare gate", failures)

	var corrupt_result_claim_id := valid_welfare_state.duplicate(true)
	var claim_result := (corrupt_result_claim_id.get("last_market_contract_result", {}) as Dictionary).duplicate(true)
	var claim_schedules := (claim_result.get("scheduled_claims", []) as Array).duplicate(true)
	if not claim_schedules.is_empty():
		var claim_schedule := (claim_schedules[0] as Dictionary).duplicate(true)
		claim_schedule["claim_id"] = int(claim_schedule.get("claim_id", 0)) + 100
		claim_schedules[0] = claim_schedule
		claim_result["scheduled_claims"] = claim_schedules
		corrupt_result_claim_id["last_market_contract_result"] = claim_result
		_expect_rejected(corrupt_result_claim_id, "altered settled schedule claim ID", failures)

	var corrupt_result_released := valid_welfare_state.duplicate(true)
	var released_result := (corrupt_result_released.get("last_market_contract_result", {}) as Dictionary).duplicate(true)
	var released_schedules := (released_result.get("scheduled_claims", []) as Array).duplicate(true)
	if not released_schedules.is_empty():
		var released_schedule := (released_schedules[0] as Dictionary).duplicate(true)
		released_schedule["released"] = not bool(released_schedule.get("released", false))
		released_schedules[0] = released_schedule
		released_result["scheduled_claims"] = released_schedules
		corrupt_result_released["last_market_contract_result"] = released_result
		_expect_rejected(corrupt_result_released, "altered settled schedule release evidence", failures)

	var corrupt_result_rejected := valid_welfare_state.duplicate(true)
	var rejected_result := (corrupt_result_rejected.get("last_market_contract_result", {}) as Dictionary).duplicate(true)
	var rejected_schedules := (rejected_result.get("scheduled_claims", []) as Array).duplicate(true)
	if not rejected_schedules.is_empty():
		var rejected_schedule := (rejected_schedules[0] as Dictionary).duplicate(true)
		rejected_schedule["rejected"] = not bool(rejected_schedule.get("rejected", false))
		rejected_schedules[0] = rejected_schedule
		rejected_result["scheduled_claims"] = rejected_schedules
		corrupt_result_rejected["last_market_contract_result"] = rejected_result
		_expect_rejected(corrupt_result_rejected, "altered settled schedule rejection evidence", failures)

	var corrupt_result_flag_type := valid_welfare_state.duplicate(true)
	var typed_result := (corrupt_result_flag_type.get("last_market_contract_result", {}) as Dictionary).duplicate(true)
	var typed_schedules := (typed_result.get("scheduled_claims", []) as Array).duplicate(true)
	if not typed_schedules.is_empty():
		var typed_schedule := (typed_schedules[0] as Dictionary).duplicate(true)
		typed_schedule["released"] = 1
		typed_schedules[0] = typed_schedule
		typed_result["scheduled_claims"] = typed_schedules
		corrupt_result_flag_type["last_market_contract_result"] = typed_result
		_expect_rejected(corrupt_result_flag_type, "non-boolean settled schedule release evidence", failures)


func _test_v13_neutral_migration(failures: Array[String]) -> void:
	var active_sim := _baseline_simulation(9960)
	_check(bool(active_sim.sign_market_contract(LOW).get("accepted", false)), "v13 active fixture should sign neutral Standard terms", failures)
	var legacy_active := _to_v13(active_sim.export_save_state(), true)
	var active_restore := DepartmentSimulation.new(9961, 6)
	_check(active_restore.restore_save_state(legacy_active), "v13 neutral active binder should migrate", failures)
	var active := active_restore.active_market_contract
	_check(int(active.get("version", -1)) == 2 and bool(active.get("legacy_terms_grandfathered", false)), "migrated v13 active binder should become grandfathered record v2", failures)
	_check(String(active.get("season_id", "")) == "baseline_neutral" and String(active.get("clause_id", "")) == "standard_terms", "v13 active migration must invent neither a season nor a rider", failures)
	_check(int(active.get("season_premium_delta_cents", -1)) == 0 and int(active.get("clause_premium_delta_cents", -1)) == 0, "v13 active migration should remain economically neutral", failures)
	_check(int(active.get("premium_cents", -1)) == 1000 and int(active.get("breach_cents", -1)) == 500, "v13 active migration should preserve old signed terms exactly", failures)
	_check(int((active_restore.export_save_state()).get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "migrated active state should re-export v23", failures)
	_check(active_restore.facility_level(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID) == 0, "v13 migration must append a neutral Farmgate Depot", failures)
	_check(int(active_restore.farmgate_dispatch_snapshot().get("stock_count", -1)) == 0, "v13 migration must not invent finished-egg stock", failures)
	_assert_neutral_campus(active_restore, "v13 active migration", failures)

	var result_sim := _baseline_simulation(9962)
	_check(bool(result_sim.sign_market_contract(LOW).get("accepted", false)), "v13 result fixture should sign neutral Standard terms", failures)
	_set_threshold(result_sim)
	result_sim.call("_settle_market_contract", result_sim.day)
	var legacy_result := _to_v13(result_sim.export_save_state(), false)
	var legacy_result_evidence := _schedule_evidence(
		(legacy_result.get("last_market_contract_result", {}) as Dictionary).get("scheduled_claims", []) as Array
	)
	var result_restore := DepartmentSimulation.new(9963, 6)
	_check(result_restore.restore_save_state(legacy_result), "v13 neutral settled receipt should migrate", failures)
	var result := result_restore.last_market_contract_result
	_check(int(result.get("version", -1)) == 2 and bool(result.get("legacy_terms_grandfathered", false)), "migrated v13 result should become grandfathered record v2", failures)
	_check(String(result.get("season_id", "")) == "baseline_neutral" and int(result.get("contracted_premium_cents", -1)) == 1000, "v13 result migration should preserve a neutral $10 contract", failures)
	_check(
		_schedule_evidence(result.get("scheduled_claims", []) as Array) == legacy_result_evidence,
		"v13 result migration should preserve exact claim/release/rejection evidence",
		failures,
	)
	_assert_neutral_campus(result_restore, "v13 settled migration", failures)


func _room_simulation(seed: int, target_day: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 6)
	simulation.day = target_day
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.owned_facilities[RECORDS] = 3
	simulation.owned_facilities[COOP] = 3
	simulation.owned_facilities[ROOM] = 1
	simulation.revenue_cents = 1_000_000
	return simulation


func _baseline_simulation(seed: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 6)
	simulation.day = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.owned_facilities[RECORDS] = 3
	simulation.revenue_cents = 1_000_000
	return simulation


func _to_v13(source: Dictionary, has_active: bool) -> Dictionary:
	var legacy := _json(source, [] as Array[String])
	legacy["state_version"] = 13
	var facilities := (legacy.get("owned_facilities", {}) as Dictionary).duplicate(true)
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
	var field_name := "active_market_contract" if has_active else "last_market_contract_result"
	var record := (legacy.get(field_name, {}) as Dictionary).duplicate(true)
	for field in V14_QUOTE_FIELDS:
		record.erase(field)
	record["version"] = 1
	if has_active:
		record.erase("contracted_service_coop_bonus_cents")
		var schedules := record.get("scheduled_claims", []) as Array
		for index in schedules.size():
			var schedule := (schedules[index] as Dictionary).duplicate(true)
			schedule.erase("authored_lane")
			schedule.erase("authored_rush")
			schedules[index] = schedule
		var batches := record.get("arrival_batches", []) as Array
		for index in batches.size():
			var batch := (batches[index] as Dictionary).duplicate(true)
			batch.erase("contains_rush")
			batch.erase("rush_count")
			batches[index] = batch
		record["scheduled_claims"] = schedules
		record["arrival_batches"] = batches
	else:
		for field in ["claim_ids", "accepted_claim_ids", "rejected_claim_ids"]:
			record.erase(field)
	legacy[field_name] = record
	return legacy


func _set_threshold(simulation: DepartmentSimulation) -> void:
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


func _set_welfare(simulation: DepartmentSimulation, morale: float, stress: float, fatigue: float) -> void:
	for worker in simulation.workers:
		if not worker.employed:
			continue
		worker.morale = morale
		worker.stress = stress
		worker.fatigue = fatigue


func _json(source: Dictionary, failures: Array[String]) -> Dictionary:
	_check(int(source.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "checkpoint should export schema v24", failures)
	var parsed: Variant = JSON.parse_string(JSON.stringify(source))
	_check(parsed is Dictionary, "checkpoint should remain primitive JSON", failures)
	return parsed as Dictionary if parsed is Dictionary else {}


func _schedule_evidence(schedules: Array) -> Array[Dictionary]:
	var evidence: Array[Dictionary] = []
	for schedule_value in schedules:
		var schedule := schedule_value as Dictionary
		evidence.append({
			"claim_id": int(schedule.get("claim_id", -1)),
			"released": bool(schedule.get("released", false)),
			"rejected": bool(schedule.get("rejected", false)),
		})
	return evidence


func _expect_rejected(corrupt: Dictionary, message: String, failures: Array[String]) -> void:
	var fallback := DepartmentSimulation.new(9999, 6)
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
