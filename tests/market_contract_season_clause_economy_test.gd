extends SceneTree


const LOW: StringName = &"homestead_stability_binder"
const MID: StringName = &"predator_watch_pool"
const HIGH: StringName = &"exceptions_retention_covenant"
const RECORDS: StringName = &"records_annex"
const COOP: StringName = &"farm_mutual_service_coop"
const ROOM: StringName = &"farm_mutual_negotiation_room"


func _init() -> void:
	var failures: Array[String] = []
	_test_season_quotes(failures)
	_test_room_purchase_and_non_demotion(failures)
	_test_clause_quotes_and_operations(failures)
	_test_rested_welfare_and_exact_once_settlement(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("MARKET_CONTRACT_SEASON_CLAUSE_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MARKET_CONTRACT_SEASON_CLAUSE_ECONOMY_TEST_PASSED seasons=day6-18 room=gold+coop3 clauses=3 reserve=cent welfare=72 settlement=once")
	quit(0)


func _test_season_quotes(failures: Array[String]) -> void:
	_assert_quote(3, LOW, "baseline_neutral", 0, 1000, 500, failures)
	_assert_quote(6, LOW, "spring_hatch_surge", 1600, 1160, 540, failures)
	_assert_quote(7, LOW, "spring_hatch_surge", 1600, 1160, 540, failures)
	_assert_quote(8, LOW, "spring_hatch_surge", 1600, 1160, 540, failures)
	_assert_quote(9, MID, "summer_predator_migration", 2000, 1920, 880, failures)
	_assert_quote(12, HIGH, "autumn_retention_audit", 1917, 2860, 1315, failures)
	_assert_quote(15, LOW, "winter_feed_fund_squeeze", 1000, 1100, 525, failures)
	_assert_quote(18, LOW, "spring_hatch_surge", 1600, 1160, 540, failures)
	var repeated := _quote_simulation(9901, 18)
	var season := repeated.market_contract_board_status().get("season", {}) as Dictionary
	_check(int(season.get("year", -1)) == 2, "day 18 should repeat Spring as market year two", failures)
	_check(int(season.get("days_remaining", -1)) == 3, "a season's opening day should disclose all three days remaining", failures)


func _assert_quote(
	target_day: int,
	offer_id: StringName,
	expected_season: String,
	expected_demand_bp: int,
	expected_premium: int,
	expected_breach: int,
	failures: Array[String]
) -> void:
	var simulation := _quote_simulation(9800 + target_day, target_day)
	var quote := simulation.market_contract_offer_preflight(offer_id)
	_check(String(quote.get("season_id", "")) == expected_season, "day %d should use %s" % [target_day, expected_season], failures)
	_check(int(quote.get("season_demand_basis_points", -9999)) == expected_demand_bp, "day %d demand should use the exact authored-lane weighted basis points" % target_day, failures)
	_check(int(quote.get("premium_cents", -1)) == expected_premium, "day %d premium should round to exact integer cents" % target_day, failures)
	_check(int(quote.get("breach_cents", -1)) == expected_breach, "day %d breach should round to exact integer cents" % target_day, failures)


func _test_room_purchase_and_non_demotion(failures: Array[String]) -> void:
	var early := _room_purchase_fixture(9910)
	early.day = 5
	_check(not bool(early.facility_status(ROOM).get("can_purchase", true)), "the room must remain gated before day six", failures)

	var silver := _room_purchase_fixture(9911)
	silver.market_contracts_breached_total = 1
	_check(silver.farm_mutual_standing() == 11, "the standing gate fixture should hold eleven points", failures)
	_check(not bool(silver.facility_status(ROOM).get("can_purchase", true)), "eleven standing must not satisfy the Gold gate", failures)

	var coop_short := _room_purchase_fixture(9912)
	coop_short.owned_facilities[COOP] = 2
	_check(not bool(coop_short.facility_status(ROOM).get("can_purchase", true)), "Service Coop level two must not satisfy the room dependency", failures)

	var one_cent_short := _room_purchase_fixture(9913)
	one_cent_short.revenue_cents -= 1
	var before := one_cent_short.export_save_state().duplicate(true)
	_check(not bool(one_cent_short.purchase_facility(ROOM).get("accepted", true)), "one cent below capital plus revised upkeep must reject", failures)
	_check(one_cent_short.export_save_state() == before, "a short room purchase must be fully atomic", failures)

	var ready := _room_purchase_fixture(9914)
	var operating_before := ready.current_daily_operating_cost_cents()
	var fund_before := ready.revenue_cents
	var receipt := ready.purchase_facility(ROOM)
	_check(bool(receipt.get("accepted", false)), "Gold plus Service Coop level three should commission the room", failures)
	_check(int(receipt.get("cost_cents", -1)) == 24000, "room capital should cost exactly $240", failures)
	_check(ready.revenue_cents == fund_before - 24000, "room capital should debit exactly once", failures)
	_check(ready.current_daily_operating_cost_cents() == operating_before + 1200, "room upkeep should add exactly $12 per day", failures)
	_check(ready.spendable_fund_cents() == 0, "exact purchase funding should retain every revised obligation", failures)
	ready.market_contracts_succeeded_total = 0
	var owned_status := ready.farm_mutual_negotiation_room_status()
	_check(bool(owned_status.get("owned", false)) and bool(owned_status.get("unlocked", false)), "falling standing must not demote an owned room", failures)
	_check(int(owned_status.get("max_clause_slots", 0)) == 1, "the owned room should expose exactly one clause slot", failures)


func _test_clause_quotes_and_operations(failures: Array[String]) -> void:
	var locked := _quote_simulation(9920, 6)
	var locked_clause := locked.market_contract_offer_preflight(LOW, &"expedited_hatch_rider")
	_check(not bool(locked_clause.get("clause_available", true)), "negotiated riders should disclose their locked room dependency", failures)
	_check(not bool(locked_clause.get("can_sign", true)), "a room clause must not sign without the room", failures)

	var simulation := _room_quote_simulation(9921, 6)
	var standard := simulation.market_contract_offer_preflight(LOW)
	var options := standard.get("clause_options", []) as Array
	_check(options.size() == 4, "every binder should expose Standard plus three authoritative room clauses", failures)
	for option_value in options:
		var option := option_value as Dictionary
		for field in ["clause_id", "label", "summary", "category", "clause_available", "can_sign", "reason", "premium_cents", "breach_cents"]:
			_check(option.has(field), "each clause option should expose %s" % field, failures)

	var expedited := simulation.market_contract_offer_preflight(LOW, &"expedited_hatch_rider")
	_check(int(expedited.get("service_window_minutes", -1)) == 60, "Expedited Hatch should reduce the 120-minute window to 60", failures)
	_check(int(expedited.get("rush_claims", -1)) == 2, "Expedited Hatch should mark exactly one additional folder rush", failures)
	_check(int(expedited.get("premium_cents", -1)) == 2910, "season + Expedited + Coop L3 should add against the $10 authored base without compounding", failures)
	_check(int(expedited.get("breach_cents", -1)) == 790, "Expedited breach should add season and clause cents against the authored $5 clause", failures)
	_check(int(expedited.get("market_premium_cents", -1)) == 1410 and int(expedited.get("service_coop_bonus_cents", -1)) == 1500, "the quote should itemize market terms separately from the authored-base Coop bonus", failures)
	var schedules := expedited.get("scheduled_claims", []) as Array
	var promoted_rush := 0
	for schedule_value in schedules:
		var schedule := schedule_value as Dictionary
		if bool(schedule.get("rush", false)) and not bool(schedule.get("authored_rush", false)):
			promoted_rush += 1
		_check(int(schedule.get("deadline_minute_of_day", 0)) - int(schedule.get("arrival_minute_of_day", 0)) == 60, "Expedited Hatch should freeze every effective deadline at 60 minutes", failures)
	_check(promoted_rush == 1, "Expedited Hatch should promote exactly one latest nonrush folder", failures)

	var specialist_sim := _room_quote_simulation(9922, 12)
	var specialist := specialist_sim.market_contract_offer_preflight(HIGH, &"specialist_roost_endorsement")
	_check(specialist.get("authored_lane_mix", {}) == {"nest_damage": 1, "predator_loss": 1, "appeals": 4}, "Specialist Roost should preserve the authored mix used for seasonal demand", failures)
	_check(specialist.get("lane_mix", {}) == {"appeals": 6}, "Specialist Roost should transform every effective folder to the authored dominant lane", failures)
	_check(int(specialist.get("premium_cents", -1)) == 7300, "Specialist quote should add $8.40 clause, $4.60 season, and $36 Coop to the $24 base", failures)
	_check(int(specialist.get("breach_cents", -1)) == 1615, "Specialist breach should add its exact authored-base clause cents", failures)

	var exact := _room_quote_simulation(9923, 6)
	var exact_quote := exact.market_contract_offer_preflight(LOW, &"expedited_hatch_rider")
	exact.revenue_cents = exact.current_daily_operating_cost_cents() + int(exact_quote.get("breach_cents", 0))
	_check(bool(exact.market_contract_offer_preflight(LOW, &"expedited_hatch_rider").get("can_sign", false)), "an exact negotiated breach reserve should sign", failures)
	exact.revenue_cents -= 1
	var exact_before := exact.export_save_state().duplicate(true)
	_check(not bool(exact.sign_market_contract(LOW, &"expedited_hatch_rider").get("accepted", true)), "one cent below a negotiated reserve should reject", failures)
	_check(exact.export_save_state() == exact_before, "a rejected negotiated signature must preserve all state", failures)

	var frozen := _room_quote_simulation(9924, 6)
	_check(bool(frozen.sign_market_contract(LOW, &"specialist_roost_endorsement").get("accepted", false)), "a funded room clause should sign", failures)
	var frozen_terms := frozen.active_market_contract.duplicate(true)
	frozen.owned_facilities[COOP] = 0
	frozen.owned_facilities[ROOM] = 0
	_check(frozen.active_market_contract == frozen_terms, "signed season, clause, room, schedule, lanes, and cents must remain frozen", failures)


func _test_rested_welfare_and_exact_once_settlement(failures: Array[String]) -> void:
	var success_sim := _room_quote_simulation(9930, 6)
	_check(bool(success_sim.sign_market_contract(LOW, &"rested_flock_warranty").get("accepted", false)), "Rested Flock should sign in an owned room", failures)
	_set_delivery_threshold(success_sim)
	_set_welfare(success_sim, 80.0, 0.0, 0.0)
	var success := success_sim.call("_settle_market_contract", success_sim.day) as Dictionary
	_check(bool(success.get("success", false)), "Rested Flock should fulfill when delivery and welfare both pass", failures)
	_check(int(success.get("closing_welfare", -1)) >= 72 and bool(success.get("welfare_gate_met", false)), "Rested Flock should record authoritative closing welfare evidence", failures)
	_check(int(success.get("premium_cents", -1)) == 3060, "Rested Flock success should pay the exact additive quote with Coop L3", failures)
	_check((success_sim.call("_settle_market_contract", success_sim.day) as Dictionary).is_empty(), "a fulfilled binder must settle exactly once", failures)

	var failure_sim := _room_quote_simulation(9931, 6)
	_check(bool(failure_sim.sign_market_contract(LOW, &"rested_flock_warranty").get("accepted", false)), "low-welfare fixture should sign Rested Flock", failures)
	_set_delivery_threshold(failure_sim)
	_set_welfare(failure_sim, 30.0, 90.0, 90.0)
	var failure := failure_sim.call("_settle_market_contract", failure_sim.day) as Dictionary
	_check(not bool(failure.get("success", true)), "delivery alone must not fulfill Rested Flock below welfare 72", failures)
	_check(bool(failure.get("delivery_threshold_met", false)) and not bool(failure.get("welfare_gate_met", true)), "the breach receipt should distinguish delivery success from welfare failure", failures)
	_check(int(failure.get("breach_cents", -1)) == 740, "Rested Flock welfare breach should charge the exact signed clause", failures)
	_check("welfare safeguard failed" in String(failure.get("outcome", "")), "the welfare breach copy should name the failed safeguard instead of blaming delivered folders", failures)
	_check((failure_sim.call("_settle_market_contract", failure_sim.day) as Dictionary).is_empty(), "a welfare breach must settle exactly once", failures)


func _quote_simulation(seed: int, target_day: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 6)
	simulation.day = target_day
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.owned_facilities[RECORDS] = 3
	simulation.revenue_cents = 1_000_000
	return simulation


func _room_quote_simulation(seed: int, target_day: int) -> DepartmentSimulation:
	var simulation := _quote_simulation(seed, target_day)
	simulation.owned_facilities[COOP] = 3
	simulation.owned_facilities[ROOM] = 1
	return simulation


func _room_purchase_fixture(seed: int) -> DepartmentSimulation:
	var simulation := _quote_simulation(seed, 6)
	simulation.market_contracts_succeeded_total = 6
	simulation.owned_facilities[COOP] = 3
	simulation.revenue_cents = (
		simulation.current_daily_operating_cost_cents()
		+ 24000
		+ 1200
	)
	return simulation


func _set_delivery_threshold(simulation: DepartmentSimulation) -> void:
	var required := int(simulation.active_market_contract.get("required_completed", 0))
	simulation.active_market_contract["timely_sound_completed"] = required
	simulation.active_market_contract["sound_completed"] = required
	simulation.active_market_contract["completed_count"] = required


func _set_welfare(simulation: DepartmentSimulation, morale: float, stress: float, fatigue: float) -> void:
	for worker in simulation.workers:
		if not worker.employed:
			continue
		worker.morale = morale
		worker.stress = stress
		worker.fatigue = fatigue


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
