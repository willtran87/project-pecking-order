extends SceneTree


const PARCEL: StringName = &"north_meadow"
const POD: StringName = &"egg_routing_pod"
const LOW_BINDER: StringName = &"homestead_stability_binder"
const RECORDS := DepartmentSimulation.RECORDS_ANNEX_ID
const DEPOT := DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID


func _init() -> void:
	var failures: Array[String] = []
	_test_day_one_projection_and_access_gate(failures)
	_test_authoritative_build_sequence_and_effects(failures)
	_test_fund_reserve_rejects_atomically(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPUS_EXPANSION_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_EXPANSION_ECONOMY_TEST_PASSED schema=v23 access=bronze-or-depot parcel=north-meadow sockets=2-cleared-1-blocked pod=gated effects=claims+6-farmgate+6 receipts=exact")
	quit(0)


func _test_day_one_projection_and_access_gate(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(21_101, 4)
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 200_000
	var campus := simulation.campus_expansion_snapshot()
	_check(bool(campus.get("visible", false)), "North Meadow portal should be visible on Day 1", failures)
	_check(not bool(campus.get("access_gate_met", true)), "fresh office should not satisfy parcel access", failures)
	var parcel := campus.get("parcel", {}) as Dictionary
	_check(StringName(parcel.get("id", &"")) == PARCEL, "parcel projection should expose stable north_meadow id", failures)
	_check(not bool(parcel.get("can_purchase", true)), "parcel should be held before a real access gate", failures)
	_check("Farmgate" in String(parcel.get("reason", "")) and "Bronze" in String(parcel.get("reason", "")), "parcel hold should disclose both authored access routes", failures)
	_check((campus.get("services", []) as Array).size() == 3, "projection should expose three stable services", failures)
	var sockets := campus.get("sockets", []) as Array
	_check(sockets.size() == 3, "projection should expose all three placement sockets", failures)
	var cleared := 0
	var blocked := 0
	for socket_value in sockets:
		var socket := socket_value as Dictionary
		if bool(socket.get("route_blocked", false)):
			blocked += 1
			_check(StringName(socket.get("id", &"")) == &"service_spine", "only Service Spine should be route-blocked", failures)
		else:
			cleared += 1
	_check(cleared == 2 and blocked == 1, "North Meadow should have exactly two cleared sockets and one protected route", failures)
	for field in ["parcel", "routing_pod", "construction_stage", "construction_stages", "operational_benefits"]:
		_check(campus.has(field), "campus projection should expose presentation field %s" % field, failures)
	_check((campus.get("construction_stages", []) as Array).size() >= 5, "projection should disclose the construction sequence", failures)
	var root_snapshot := simulation.snapshot()
	_check(root_snapshot.has("campus_expansion"), "root simulation snapshot should include campus_expansion", failures)


func _test_authoritative_build_sequence_and_effects(failures: Array[String]) -> void:
	var simulation := _funded_review(21_201)
	_earn_bronze_standing(simulation, failures)
	_check(simulation.farm_mutual_standing() == 2, "one fulfilled Homestead binder should earn exact Bronze standing", failures)
	var starting_claim_capacity := simulation.current_claim_capacity()
	var fund_before_campus := simulation.revenue_cents

	var parcel_receipt := simulation.purchase_campus_parcel(PARCEL)
	_check(bool(parcel_receipt.get("accepted", false)), "Bronze planning review should purchase North Meadow", failures)
	_check(int(parcel_receipt.get("cost_cents", -1)) == 8_500, "parcel should debit exactly 8,500 cents", failures)
	_check(StringName(parcel_receipt.get("access_gate_id", &"")) == &"farm_mutual_standing", "parcel receipt should preserve the Bronze access evidence", failures)
	_check(int(parcel_receipt.get("access_standing_points", -1)) == 2, "parcel receipt should freeze exact standing evidence", failures)

	_expect_rejected_atomic(
		simulation,
		func() -> Dictionary: return simulation.place_campus_module(POD, &"service_spine"),
		"route-blocked Service Spine placement",
		failures,
	)
	var pod_receipt := simulation.place_campus_module(POD, &"meadow_west")
	_check(bool(pod_receipt.get("accepted", false)) and int(pod_receipt.get("cost_cents", -1)) == 7_500, "cleared west socket should place the exact-price routing pod", failures)
	_check(simulation.current_claim_capacity() == starting_claim_capacity, "placed pod must remain inert without circulation and power", failures)

	var circulation := simulation.commission_campus_service(&"circulation")
	_check(bool(circulation.get("accepted", false)) and int(circulation.get("cost_cents", -1)) == 2_800, "circulation should commission at its exact price", failures)
	_check(simulation.current_claim_capacity() == starting_claim_capacity, "circulation alone must not activate pod benefits", failures)
	var power := simulation.commission_campus_service(&"power")
	_check(bool(power.get("accepted", false)) and int(power.get("cost_cents", -1)) == 3_500, "power should commission at its exact price", failures)
	_check(simulation.current_claim_capacity() == starting_claim_capacity + 6, "parcel, pod, circulation, and power should add exactly six live claim slots", failures)

	# The Depot is a permanent structural facility. Setting the complete tier-three
	# fixture isolates the cold-chain capacity effect from its pre-existing gates.
	simulation.owned_facilities[DEPOT] = 3
	_check(int(simulation.farmgate_dispatch_snapshot().get("storage_capacity_eggs", -1)) == 42, "tier-three Farmgate baseline should remain 42 eggs", failures)
	var cold_chain := simulation.commission_campus_service(&"cold_chain")
	_check(bool(cold_chain.get("accepted", false)) and int(cold_chain.get("cost_cents", -1)) == 6_000, "cold-chain should commission at its exact price", failures)
	_check(int(simulation.farmgate_dispatch_snapshot().get("storage_capacity_eggs", -1)) == 48, "active Meadow cold-chain should extend Farmgate storage by exactly six eggs", failures)

	var campus := simulation.campus_expansion_snapshot()
	_check(StringName(campus.get("construction_stage", &"")) == &"cold_chain_operational", "complete build should expose the terminal construction stage", failures)
	_check(bool(campus.get("pod_operational", false)), "complete dependency chain should mark the pod operational", failures)
	_check(int(campus.get("claim_capacity_bonus", -1)) == 6, "projection should expose exact claim bonus", failures)
	_check(int(campus.get("farmgate_capacity_bonus_eggs", -1)) == 6, "projection should expose exact Farmgate bonus", failures)
	_check(int(campus.get("current_daily_cost_cents", -1)) == 1_575, "complete campus should add exact 1,575-cent daily obligation", failures)
	_check(int(campus.get("capital_spend_total_cents", -1)) == 28_300, "five construction filings should total exactly 28,300 cents", failures)
	_check((campus.get("history", []) as Array).size() == 5, "five accepted filings should create five immutable receipts", failures)
	_check(simulation.revenue_cents == fund_before_campus - 28_300, "campus capital should debit each exact cost once", failures)
	var pod := campus.get("routing_pod", {}) as Dictionary
	for field in ["id", "name", "placed", "current_socket_id", "capital_cost_cents", "relocation_cost_cents", "daily_cost_cents", "can_place", "can_relocate", "placement_reason", "relocation_reason", "operational"]:
		_check(pod.has(field), "routing-pod projection should expose %s" % field, failures)
	for service_value in campus.get("services", []):
		var service := service_value as Dictionary
		_check(service.has("connected") and service.has("can_connect") and service.has("reason"), "each service should expose presentation connection state", failures)
	for socket_value in campus.get("sockets", []):
		var socket := socket_value as Dictionary
		for field in ["can_place", "can_relocate", "placement_cost_cents", "relocation_cost_cents", "placement_reason", "relocation_reason"]:
			_check(socket.has(field), "each socket should expose authoritative %s" % field, failures)

	var relocation := simulation.relocate_campus_module(POD, &"meadow_east")
	_check(bool(relocation.get("accepted", false)) and int(relocation.get("cost_cents", -1)) == 1_800, "cleared east relocation should debit exactly 1,800 cents", failures)
	_check(int(relocation.get("added_daily_cost_cents", -1)) == 0, "relocation should not duplicate pod upkeep", failures)
	_check(StringName(simulation.campus_expansion_snapshot().get("pod_socket_id", &"")) == &"meadow_east", "relocation should move the pod to Meadow East", failures)
	_check(simulation.current_daily_campus_cost_cents() == 1_575, "relocation should preserve daily campus obligation", failures)
	_check(simulation.current_claim_capacity() == starting_claim_capacity + 6, "relocation between cleared sockets should preserve operational benefit", failures)
	_check(int(simulation.campus_expansion_state.get("capital_spend_total_cents", -1)) == 30_100, "relocation should enter exact lifetime capital spend", failures)


func _test_fund_reserve_rejects_atomically(failures: Array[String]) -> void:
	var simulation := _funded_review(21_301)
	simulation.owned_facilities[DEPOT] = 1
	var funded_quote := simulation.campus_expansion_action_quote(&"purchase_parcel", PARCEL)
	_check(bool(funded_quote.get("can_authorize", false)), "funded Depot gate should clear parcel preflight", failures)
	var exact_requirement := int(funded_quote.get("required_spendable_cents", -1))
	simulation.revenue_cents = exact_requirement - 1
	_expect_rejected_atomic(
		simulation,
		func() -> Dictionary: return simulation.purchase_campus_parcel(PARCEL),
		"one-cent-short parcel filing",
		failures,
	)
	_check(simulation.revenue_cents >= 0, "rejected campus filing must never underflow the Feed Fund", failures)


func _funded_review(seed: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 4)
	simulation.day = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 200_000
	return simulation


func _earn_bronze_standing(simulation: DepartmentSimulation, failures: Array[String]) -> void:
	simulation.owned_facilities[RECORDS] = 1
	var signature := simulation.sign_market_contract(LOW_BINDER)
	_check(bool(signature.get("accepted", false)), "Bronze access fixture should sign the real Homestead binder", failures)
	var required := int(simulation.active_market_contract.get("required_completed", 0))
	simulation.active_market_contract["timely_sound_completed"] = required
	simulation.active_market_contract["sound_completed"] = required
	simulation.active_market_contract["completed_count"] = required
	var settlement := simulation.call("_settle_market_contract", simulation.day) as Dictionary
	_check(bool(settlement.get("success", false)), "Homestead delivery evidence should settle as fulfilled", failures)


func _expect_rejected_atomic(
	simulation: DepartmentSimulation,
	action: Callable,
	label: String,
	failures: Array[String],
) -> void:
	var before := simulation.export_save_state().duplicate(true)
	var result := action.call() as Dictionary
	_check(not bool(result.get("accepted", false)), "%s should reject" % label, failures)
	_check(not String(result.get("reason", "")).is_empty(), "%s should explain its rejection" % label, failures)
	_check(simulation.export_save_state() == before, "%s should preserve authoritative state atomically" % label, failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
