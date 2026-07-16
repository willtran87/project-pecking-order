extends SceneTree


const PROVISIONS := DepartmentSimulation.FEED_PROCUREMENT_COOP_ID


func _init() -> void:
	var failures: Array[String] = []
	_test_baseline_demand_and_season_quotes(failures)
	_test_facility_tiers_and_gates(failures)
	_test_offer_reserve_and_atomic_order(failures)
	_test_ration_effects_once_per_day(failures)
	_test_automatic_spot_and_midshift_reconciliation(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("FEED_PROCUREMENT_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FEED_PROCUREMENT_ECONOMY_TEST_PASSED demand=translated seasons=exact tiers=exact orders=atomic rations=once-per-day")
	quit(0)


func _test_baseline_demand_and_season_quotes(failures: Array[String]) -> void:
	var sim := DepartmentSimulation.new(18_001, 6)
	_check(sim._feed_demand_scoops() == 9, "baseline demand should equal three plus six active hens", failures)
	_check(sim.current_daily_feed_cost_cents() == 1800, "neutral Day 1 spot feed should preserve the legacy $18 baseline", failures)
	_check(sim._feed_spot_unit_price_cents(6) == 180, "spring quote should be 90% of $2", failures)
	_check(sim._feed_spot_unit_price_cents(9) == 220, "summer quote should be 110% of $2", failures)
	_check(sim._feed_spot_unit_price_cents(12) == 200, "autumn quote should be 100% of $2", failures)
	_check(sim._feed_spot_unit_price_cents(15) == 270, "winter quote should be 135% of $2", failures)
	_check(sim.select_directive(&"sustainable_flock"), "fixture should select Sustainable Flock", failures)
	_check(sim._feed_demand_scoops() == 12, "the existing +$6 directive adjustment should become three scoops", failures)
	_check(sim.current_daily_feed_cost_cents() == 2400, "translated directive demand should retain neutral-price parity", failures)


func _test_facility_tiers_and_gates(failures: Array[String]) -> void:
	var undersized := _review_fixture(18_011, 3, 4)
	var blocked := undersized.facility_status(PROVISIONS)
	_check(int(blocked.get("required_office_capacity", 0)) == 4, "tier one should require four authorized desks", failures)
	_check(int(blocked.get("active_staff_shortfall", 0)) == 1, "tier one should require four active hens", failures)
	_check(not bool(blocked.get("can_purchase", true)), "undersized flock should not commission tier one", failures)

	var sim := _review_fixture(18_012, 6, 4)
	var costs := [8000, 14000, 22000]
	var maintenance := [400, 800, 1300]
	var capacities := [18, 36, 54]
	var days := [4, 8, 12]
	var names := ["RECEIVING HOPPER", "DRY GRAIN RESERVE", "FEED FUTURES DESK"]
	for index in 3:
		sim.day = days[index]
		sim.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
		sim.pending_decision.clear()
		var status := sim.facility_status(PROVISIONS)
		_check(bool(status.get("can_purchase", false)), "funded provisions tier %d should pass gates" % (index + 1), failures)
		_check(int(status.get("cost_cents", -1)) == costs[index], "tier %d capital cost should match the authored schedule" % (index + 1), failures)
		_check(String(status.get("next_level_name", "")) == names[index], "tier %d should expose its authored level name" % (index + 1), failures)
		var receipt := sim.purchase_facility(PROVISIONS)
		_check(bool(receipt.get("accepted", false)), "tier %d purchase should be accepted" % (index + 1), failures)
		_check(sim.current_daily_facility_maintenance_cents() >= maintenance[index], "tier %d should carry its cumulative maintenance" % (index + 1), failures)
		_check(sim._feed_procurement_capacity_scoops() == capacities[index], "tier %d should expose exact scoop capacity" % (index + 1), failures)


func _test_offer_reserve_and_atomic_order(failures: Array[String]) -> void:
	var sim := _review_fixture(18_021, 6, 4)
	sim.owned_facilities[PROVISIONS] = 1
	var offers := sim.procurement_offer_catalog()
	_check(offers.size() == 3, "catalog should expose the three authored feed choices", failures)
	var local := _offer(offers, &"local_whole_grain")
	var bulk := _offer(offers, &"inspirational_bulk_mash")
	_check(int(local.get("quantity_scoops", -1)) == 9, "local grain should quote one demand unit", failures)
	_check(int(local.get("unit_price_cents", -1)) == 250, "local grain should quote 125% of neutral spot", failures)
	_check(int(local.get("total_cost_cents", -1)) == 2250, "local grain should quote exact integer cents", failures)
	_check(bool(local.get("available", false)), "tier one should unlock local grain", failures)
	_check(not bool(bulk.get("available", true)), "tier one should not unlock bulk mash", failures)

	var reserve_without_feed := sim.protected_reserve_cents() - sim.current_daily_feed_cost_cents()
	sim.revenue_cents = reserve_without_feed + int(local["total_cost_cents"])
	local = _offer(sim.procurement_offer_catalog(), &"local_whole_grain")
	_check(int(local.get("projected_spendable_fund_cents", -1)) == 0, "preflight should replace the covered spot obligation rather than double-reserve it", failures)
	var fund_before := sim.revenue_cents
	var receipt := sim.authorize_feed_order(&"local_whole_grain")
	_check(bool(receipt.get("accepted", false)), "exactly funded local order should authorize", failures)
	_check(sim.revenue_cents == fund_before - 2250, "prepaid lot should debit its cost exactly once", failures)
	_check(sim.current_daily_feed_cost_cents() == 0, "fully covered inventory should remove today's spot obligation", failures)
	_check(sim.spendable_fund_cents() == 0, "exact funding should preserve all non-feed obligations", failures)
	var state_after := JSON.stringify(sim.export_save_state())
	var duplicate := sim.authorize_feed_order(&"local_whole_grain")
	_check(not bool(duplicate.get("accepted", true)), "second order in one review should reject", failures)
	_check(JSON.stringify(sim.export_save_state()) == state_after, "rejected duplicate order should be atomic", failures)

	var short := _review_fixture(18_022, 6, 4)
	short.owned_facilities[PROVISIONS] = 1
	reserve_without_feed = short.protected_reserve_cents() - short.current_daily_feed_cost_cents()
	short.revenue_cents = reserve_without_feed + 2249
	var before := JSON.stringify(short.export_save_state())
	var rejected := short.authorize_feed_order(&"local_whole_grain")
	_check(not bool(rejected.get("accepted", true)), "one cent below protected order funding should reject", failures)
	_check(JSON.stringify(short.export_save_state()) == before, "underfunded rejection should preserve the full checkpoint", failures)


func _test_ration_effects_once_per_day(failures: Array[String]) -> void:
	var sim := _review_fixture(18_031, 6, 4)
	sim.owned_facilities[PROVISIONS] = 1
	sim.revenue_cents = 1_000_000
	_check(bool(sim.authorize_feed_order(&"local_whole_grain").get("accepted", false)), "Day 4 local order should authorize", failures)
	var morale_before := sim.workers[0].morale
	sim._prepare_morning_directive()
	_check(sim.select_directive(&"shell_assurance"), "Day 4 shift should start", failures)
	_check(is_equal_approx(sim.workers[0].morale, morale_before + 2.0), "local ration should apply its full +2 morale once", failures)
	sim._consume_feed_for_shift()
	_check(is_equal_approx(sim.workers[0].morale, morale_before + 2.0), "idempotent same-day consumption should not apply morale twice", failures)

	sim.day = 5
	sim._feed_procurement.begin_day(5)
	sim.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	sim.pending_decision.clear()
	_check(bool(sim.authorize_feed_order(&"local_whole_grain").get("accepted", false)), "Day 5 local order should authorize", failures)
	morale_before = sim.workers[0].morale
	sim._prepare_morning_directive()
	_check(sim.select_directive(&"shell_assurance"), "Day 5 shift should start", failures)
	_check(is_equal_approx(sim.workers[0].morale, morale_before + 2.0), "consecutive-day local ration should apply the full effect again", failures)
	var ration := sim.feed_procurement_snapshot().get("active_ration", {}) as Dictionary
	_check(int(ration.get("strain_basis_points", -1)) == 9200, "local ration should expose 92% active strain", failures)


func _test_automatic_spot_and_midshift_reconciliation(failures: Array[String]) -> void:
	var sim := DepartmentSimulation.new(18_041, 6)
	_check(sim.select_directive(&"shell_assurance"), "spot fixture should start its shift", failures)
	_check(sim.current_daily_feed_cost_cents() == 1800, "uncovered ration should accrue automatic neutral spot feed", failures)
	_check(sim._feed_procurement.spot_spend_total_cents == 1800, "automatic spot purchase should enter the lifetime ledger once", failures)
	sim._consume_feed_for_shift()
	_check(sim._feed_procurement.spot_spend_total_cents == 1800, "idempotent close planning should not duplicate spot spend", failures)
	sim._apply_incident_effects(&"feed_shortfall", &"optimize_portions")
	_check(sim._feed_demand_scoops() == 5, "existing -$8 portion adjustment should become four fewer scoops", failures)
	_check(sim.current_daily_feed_cost_cents() == 1000, "mid-shift portion plan should retain exact neutral-price parity", failures)
	_check(sim._feed_procurement.spot_spend_total_cents == 1000, "reconciliation should replace, not stack, the earlier spot plan", failures)

	var reports: Array[Dictionary] = []
	sim.workday_completed.connect(func(report: Dictionary) -> void: reports.append(report))
	sim._complete_workday()
	_check(reports.size() == 1, "closing the shift should emit one report", failures)
	if reports.size() == 1:
		var report := reports[0]
		_check(int(report.get("feed_spot_spend_cents", -1)) == 1000, "report should settle the reconciled spot obligation", failures)
		_check(int(report.get("feed_procurement_spend_cents", -1)) == 0, "unowned co-op should report no prepaid procurement", failures)
		_check(int(report.get("feed_total_cash_spend_cents", -1)) == 1000, "report should separate and total feed cash flows", failures)
	_check(sim._feed_procurement.spot_spend_today_cents == 0, "new day should reset daily spot spend", failures)
	_check(sim._feed_procurement.spot_spend_total_cents == 1000, "new day should retain lifetime spot spend", failures)


func _review_fixture(seed: int, staff_count: int, target_day: int) -> DepartmentSimulation:
	var sim := DepartmentSimulation.new(seed, staff_count)
	sim.day = target_day
	sim.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	sim.pending_decision.clear()
	sim.revenue_cents = 1_000_000
	return sim


func _offer(offers: Array[Dictionary], offer_id: StringName) -> Dictionary:
	for offer in offers:
		if StringName(offer.get("offer_id", &"")) == offer_id:
			return offer
	return {}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
