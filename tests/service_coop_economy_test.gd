extends SceneTree


const COOP: StringName = &"farm_mutual_service_coop"
const RECORDS: StringName = &"records_annex"
const LOW: StringName = &"homestead_stability_binder"
const MID: StringName = &"predator_watch_pool"
const HIGH: StringName = &"exceptions_retention_covenant"


func _init() -> void:
	var failures: Array[String] = []
	_test_derived_standing_and_rank_ladder(failures)
	_test_exact_tier_gates_costs_upkeep_and_non_demotion(failures)
	_test_offer_staffing_and_signed_commitment(failures)
	_test_success_only_bonus_freezes_and_settles_once(failures)
	_test_breach_cooldown_and_neutral_decline(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("SERVICE_COOP_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SERVICE_COOP_ECONOMY_TEST_PASSED standing=derived tiers=2-6-12 infrastructure=24-30-36 staff=4-5-6 premium=50pct-per-level freeze=exact cooldown=one-planning")
	quit(0)


func _test_derived_standing_and_rank_ladder(failures: Array[String]) -> void:
	var simulation := _review_simulation(9801, 4, 0)
	_check(simulation.farm_mutual_standing() == 0, "fresh standing should begin at zero", failures)
	_check(simulation.farm_mutual_standing_rank() == &"unlisted", "zero standing should be Unlisted", failures)
	_check(int(simulation.farm_mutual_standing_status().get("next_threshold", -1)) == 2, "Unlisted should point to Bronze at two", failures)
	_check(
		int(simulation.call("_service_coop_premium_bonus_cents", 1001, 1)) == 501,
		"a half-cent Service Coop bonus should round up deterministically without floats",
		failures,
	)

	simulation.market_contracts_succeeded_total = 1
	_check(simulation.farm_mutual_standing() == 2 and simulation.farm_mutual_standing_rank() == &"bronze", "one fulfillment should derive Bronze standing two", failures)
	simulation.market_contracts_succeeded_total = 3
	_check(simulation.farm_mutual_standing() == 6 and simulation.farm_mutual_standing_rank() == &"silver", "three fulfillments should derive Silver standing six", failures)
	simulation.market_contracts_succeeded_total = 6
	_check(simulation.farm_mutual_standing() == 12 and simulation.farm_mutual_standing_rank() == &"gold", "six fulfillments should derive Gold standing twelve", failures)
	simulation.market_contracts_breached_total = 2
	_check(simulation.farm_mutual_standing() == 10 and simulation.farm_mutual_standing_rank() == &"silver", "each breach should subtract exactly one derived standing", failures)
	simulation.market_contracts_succeeded_total = 0
	_check(simulation.farm_mutual_standing() == 0, "standing should floor at zero rather than become a debt currency", failures)


func _test_exact_tier_gates_costs_upkeep_and_non_demotion(failures: Array[String]) -> void:
	var level_one := _review_simulation(9811, 4, 0, 1)
	level_one.revenue_cents = 100_000
	var capacity_hold := level_one.facility_status(COOP)
	_check(not bool(capacity_hold.get("can_purchase", true)), "Bronze standing without Records level one should hold Coop level one", failures)
	_check(int(capacity_hold.get("required_market_standing", -1)) == 2, "Coop level one should require standing two", failures)
	_check(int(capacity_hold.get("required_claim_capacity", -1)) == 24, "Coop level one should require 24 file roosts", failures)
	_check("24 live-file" in String(capacity_hold.get("reason", "")), "level-one capacity hold should disclose 24 roosts", failures)

	level_one.owned_facilities[RECORDS] = 1
	var one := level_one.facility_status(COOP)
	_check(bool(one.get("can_purchase", false)), "standing two, capacity 24, and four hens should admit Coop level one", failures)
	_check(int(one.get("cost_cents", -1)) == 7500, "Coop level one should cost exactly $75", failures)
	_check(int(one.get("maintenance_delta_cents", -1)) == 300, "Coop level one should add exactly $3 upkeep", failures)
	var one_receipt := level_one.purchase_facility(COOP)
	_check(bool(one_receipt.get("accepted", false)), "Coop level one purchase should accept", failures)
	_check(level_one.facility_level(COOP) == 1, "accepted Bronze purchase should persist level one", failures)
	_check(int((level_one.facility_effects()).get("farm_mutual_premium_bonus_basis_points", -1)) == 5000, "level one should expose exactly 5000 bonus basis points", failures)

	var level_two := _review_simulation(9812, 5, 2, 3)
	level_two.owned_facilities[COOP] = 1
	level_two.revenue_cents = 100_000
	var two := level_two.facility_status(COOP)
	_check(bool(two.get("can_purchase", false)), "standing six, capacity 30, and five hens should admit Coop level two", failures)
	_check(int(two.get("cost_cents", -1)) == 12_000, "Coop level two should cost exactly $120", failures)
	_check(int(two.get("current_maintenance_cents", -1)) == 300 and int(two.get("next_maintenance_cents", -1)) == 600, "Coop level two should move total upkeep from $3 to $6", failures)
	_check(bool(level_two.purchase_facility(COOP).get("accepted", false)), "Coop level two purchase should accept", failures)

	var level_three := _review_simulation(9813, 6, 3, 6)
	level_three.owned_facilities[COOP] = 2
	level_three.revenue_cents = 100_000
	var three := level_three.facility_status(COOP)
	_check(bool(three.get("can_purchase", false)), "standing twelve, capacity 36, and six hens should admit Coop level three", failures)
	_check(int(three.get("cost_cents", -1)) == 18_000, "Coop level three should cost exactly $180", failures)
	_check(int(three.get("maintenance_delta_cents", -1)) == 300 and int(three.get("next_maintenance_cents", -1)) == 900, "Coop level three should raise total upkeep to $9", failures)
	_check(bool(level_three.purchase_facility(COOP).get("accepted", false)), "Coop level three purchase should accept", failures)
	level_three.market_contracts_succeeded_total = 0
	level_three.market_contracts_breached_total = 10
	var retained := level_three.facility_status(COOP)
	_check(level_three.facility_level(COOP) == 3 and bool(retained.get("installed", false)), "falling standing must never demote an owned Coop", failures)
	_check(level_three.current_daily_facility_maintenance_cents() >= 900, "a retained Gold Coop must keep charging its full upkeep", failures)

	var exact := _review_simulation(9814, 4, 1, 1)
	var required := exact.current_daily_operating_cost_cents() + 7500 + 300
	exact.revenue_cents = required - 1
	var short := exact.facility_status(COOP)
	_check(not bool(short.get("can_purchase", true)) and int(short.get("projected_spendable_fund_cents", 0)) == -1, "one cent below capital plus revised reserve should reject exactly", failures)
	var before := exact.export_save_state().duplicate(true)
	_check(not bool(exact.purchase_facility(COOP).get("accepted", true)), "one-cent-short Coop purchase should reject", failures)
	_check(exact.export_save_state() == before, "rejected Coop purchase must preserve every authoritative field", failures)
	exact.revenue_cents = required
	_check(bool(exact.purchase_facility(COOP).get("accepted", false)), "exact capital plus upkeep reserve should accept", failures)
	_check(exact.spendable_fund_cents() == 0, "exact Coop funding should leave zero, never negative, discretionary cents", failures)


func _test_offer_staffing_and_signed_commitment(failures: Array[String]) -> void:
	var low_short := _review_simulation(9821, 3, 0)
	low_short.revenue_cents = 100_000
	var low := low_short.market_contract_offer_preflight(LOW)
	_check(not bool(low.get("can_sign", true)) and int(low.get("required_active_staff", -1)) == 4, "Homestead should require four active hens", failures)
	_check("requires 4 active hens" in String(low.get("reason", "")), "Homestead staffing hold should be explicit", failures)

	var mid_short := _review_simulation(9822, 4, 1)
	mid_short.revenue_cents = 100_000
	var mid := mid_short.market_contract_offer_preflight(MID)
	_check(not bool(mid.get("can_sign", true)) and int(mid.get("required_active_staff", -1)) == 5, "Predator Watch should require five active hens", failures)

	var high_short := _review_simulation(9823, 5, 2)
	high_short.revenue_cents = 100_000
	var high := high_short.market_contract_offer_preflight(HIGH)
	_check(not bool(high.get("can_sign", true)) and int(high.get("required_active_staff", -1)) == 6, "Exceptions should require six active hens", failures)

	var committed := _review_simulation(9824, 6, 2)
	committed.revenue_cents = 100_000
	_check(bool(committed.sign_market_contract(HIGH).get("accepted", false)), "six staffed hens should sign Exceptions", failures)
	var before_release := committed.export_save_state().duplicate(true)
	var release := committed.release_worker(0)
	_check(not bool(release.get("accepted", true)), "a signed six-hen commitment should reject release to five", failures)
	_check("commits at least 6" in String(release.get("reason", release.get("outcome", ""))), "commitment rejection should explain its six-hen floor", failures)
	_check(committed.export_save_state() == before_release, "staffing commitment rejection should be atomic", failures)


func _test_success_only_bonus_freezes_and_settles_once(failures: Array[String]) -> void:
	var fulfilled := _review_simulation(9831, 4, 1)
	fulfilled.owned_facilities[COOP] = 1
	fulfilled.revenue_cents = 100_000
	var offer := fulfilled.market_contract_offer_preflight(LOW)
	_check(int(offer.get("base_premium_cents", -1)) == 1000, "Homestead base premium should remain $10", failures)
	_check(int(offer.get("service_coop_bonus_cents", -1)) == 500, "Bronze Coop should quote an exact $5 success bonus", failures)
	_check(int(offer.get("premium_cents", -1)) == 1500, "Bronze Homestead total premium should be $15", failures)
	_check(int(offer.get("premium_bonus_basis_points", -1)) == 5000, "Bronze offer should disclose 5000 basis points", failures)
	_check(bool(fulfilled.sign_market_contract(LOW).get("accepted", false)), "Bronze Homestead should sign", failures)
	fulfilled.owned_facilities[COOP] = 3
	_check(int(fulfilled.active_market_contract.get("service_coop_level_at_signing", -1)) == 1, "later Coop construction must not rewrite the signed level", failures)
	_check(int(fulfilled.active_market_contract.get("premium_cents", -1)) == 1500, "later Coop construction must not rewrite the signed total premium", failures)
	fulfilled.active_market_contract["timely_sound_completed"] = 4
	var fund_before := fulfilled.revenue_cents
	var receipt := fulfilled.call("_settle_market_contract", fulfilled.day) as Dictionary
	_check(bool(receipt.get("success", false)), "four timely Homestead folders should fulfill", failures)
	_check(int(receipt.get("base_premium_cents", -1)) == 1000 and int(receipt.get("service_coop_bonus_cents", -1)) == 500, "fulfillment should itemize $10 base plus $5 Coop", failures)
	_check(int(receipt.get("premium_cents", -1)) == 1500 and fulfilled.revenue_cents == fund_before + 1500, "fulfillment should credit the $15 total exactly once", failures)
	_check(fulfilled.farm_mutual_standing() == 2 and fulfilled.market_clean_contract_streak == 1 and fulfilled.best_market_clean_contract_streak == 1, "fulfillment should derive standing two and a one-contract clean streak", failures)
	var after := fulfilled.export_save_state().duplicate(true)
	_check((fulfilled.call("_settle_market_contract", fulfilled.day) as Dictionary).is_empty(), "fulfilled premium cannot settle twice", failures)
	_check(fulfilled.export_save_state() == after, "replayed fulfillment must preserve all ledgers", failures)

	var breached := _review_simulation(9832, 4, 1)
	breached.owned_facilities[COOP] = 3
	breached.market_clean_contract_streak = 2
	breached.best_market_clean_contract_streak = 2
	breached.market_contracts_succeeded_total = 2
	breached.market_contracts_signed_total = 2
	breached.revenue_cents = 100_000
	_check(bool(breached.sign_market_contract(LOW).get("accepted", false)), "Gold breach fixture should sign", failures)
	var breach_fund_before := breached.revenue_cents
	var breach := breached.call("_settle_market_contract", breached.day) as Dictionary
	_check(not bool(breach.get("success", true)), "zero deliveries should breach", failures)
	_check(int(breach.get("service_coop_bonus_cents", -1)) == 0 and int(breach.get("premium_cents", -1)) == 0, "breach must award no Service Coop bonus or premium", failures)
	_check(int(breach.get("contracted_service_coop_bonus_cents", -1)) == 1500, "breach receipt should retain the frozen but unearned Gold bonus", failures)
	_check(breached.revenue_cents == breach_fund_before - 500, "breach should charge only the authored $5 clause", failures)
	_check(breached.market_clean_contract_streak == 0 and breached.best_market_clean_contract_streak == 2, "breach should reset current streak without erasing best", failures)
	_check(breached.farm_mutual_standing() == 3, "two prior successes and one breach should derive standing three", failures)


func _test_breach_cooldown_and_neutral_decline(failures: Array[String]) -> void:
	var simulation := _review_simulation(9841, 5, 1)
	simulation.revenue_cents = 100_000
	simulation.market_clean_contract_streak = 2
	simulation.best_market_clean_contract_streak = 2
	simulation.market_contracts_succeeded_total = 2
	simulation.market_contracts_signed_total = 2
	_check(bool(simulation.sign_market_contract(LOW).get("accepted", false)), "cooldown fixture should sign Homestead", failures)
	var breach := simulation.call("_settle_market_contract", 3) as Dictionary
	_check(StringName(breach.get("status", &"")) == &"breached", "cooldown fixture should breach Homestead", failures)
	simulation.day = 4
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	var cooled := simulation.market_contract_offer_preflight(LOW)
	_check(bool(cooled.get("on_cooldown", false)) and not bool(cooled.get("can_sign", true)), "the same breached offer should cool for exactly the next planning day", failures)
	_check(int(cooled.get("cooldown_until_day", 0)) == 4, "cooldown should disclose its exact terminal planning day", failures)
	var other := simulation.market_contract_offer_preflight(MID)
	_check(not bool(other.get("on_cooldown", true)), "a Homestead breach must not cool a different client book", failures)
	var best_before := simulation.best_market_clean_contract_streak
	_check(bool(simulation.decline_market_contract().get("accepted", false)), "explicit standard book should remain available during cooldown", failures)
	_check(simulation.market_clean_contract_streak == 0 and simulation.best_market_clean_contract_streak == best_before, "decline must be neutral to both streak ledgers", failures)
	simulation.day = 5
	simulation.market_contract_decline_receipt.clear()
	_check(not bool(simulation.market_contract_offer_preflight(LOW).get("on_cooldown", true)), "same-offer cooldown should expire after one planning day", failures)


func _review_simulation(
	seed: int,
	staff_count: int,
	records_level: int,
	successes: int = 0,
	breaches: int = 0
) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, staff_count)
	simulation.day = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.owned_facilities[RECORDS] = records_level
	simulation.market_contracts_succeeded_total = successes
	simulation.market_contracts_breached_total = breaches
	simulation.market_contracts_signed_total = successes + breaches
	return simulation


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
