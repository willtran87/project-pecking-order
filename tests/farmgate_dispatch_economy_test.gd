extends SceneTree


const DEPOT := DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID
const PACKING := DepartmentSimulation.PACKING_ANNEX_ID
const GALLERY := DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID


func _init() -> void:
	var failures: Array[String] = []
	_test_facility_tiers_and_gates(failures)
	_test_finished_egg_deferral_and_level_zero_parity(failures)
	_test_review_mandates_and_hold_reserve(failures)
	_test_close_settlement_precedes_obligations(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("FARMGATE_DISPATCH_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARMGATE_DISPATCH_ECONOMY_TEST_PASSED tiers=exact gates=packing-gallery-standing eggs=deferred baseline=unchanged mandates=review-only settlement=before-obligations")
	quit(0)


func _test_facility_tiers_and_gates(failures: Array[String]) -> void:
	var blocked := _review_fixture(20_101, 6)
	blocked.owned_facilities[PACKING] = 1
	blocked.owned_facilities[GALLERY] = 1
	blocked._harvest_credit.public_standing = 4
	var blocked_status := blocked.facility_status(DEPOT)
	_check(int(blocked_status.get("required_harvest_credit_standing", -1)) == 5, "tier one should require five Harvest Credit standing", failures)
	_check(not bool(blocked_status.get("can_purchase", true)), "standing four should block tier one", failures)

	var sim := _review_fixture(20_102, 6)
	var days := [6, 10, 14]
	var costs := [12_000, 20_000, 32_000]
	var upkeep := [700, 1_300, 2_200]
	var storage := [12, 24, 42]
	var dispatch := [8, 16, 24]
	var shelf := [2, 3, 4]
	var standing := [5, 12, 25]
	var names := ["ROADSIDE LOADING SHED", "CHILLED COUNTY DOCK", "REGIONAL ROUTE FLEET"]
	for index in 3:
		sim.day = days[index]
		sim._farmgate_dispatch.begin_day(days[index])
		sim.owned_facilities[PACKING] = index + 1
		sim.owned_facilities[GALLERY] = index + 1
		sim._harvest_credit.public_standing = standing[index]
		var status := sim.facility_status(DEPOT)
		_check(bool(status.get("can_purchase", false)), "funded depot tier %d should pass every authored gate" % (index + 1), failures)
		_check(int(status.get("cost_cents", -1)) == costs[index], "tier %d capital cost should match" % (index + 1), failures)
		_check(String(status.get("next_level_name", "")) == names[index], "tier %d ASCII name should match" % (index + 1), failures)
		var receipt := sim.purchase_facility(DEPOT)
		_check(bool(receipt.get("accepted", false)), "tier %d purchase should accept" % (index + 1), failures)
		var depot := sim.farmgate_dispatch_snapshot()
		_check(int(depot.get("storage_capacity_eggs", -1)) == storage[index], "tier %d storage should match" % (index + 1), failures)
		_check(int(depot.get("dispatch_capacity_eggs", -1)) == dispatch[index], "tier %d route capacity should match" % (index + 1), failures)
		_check(int(depot.get("shelf_life_shifts", -1)) == shelf[index], "tier %d shelf life should match" % (index + 1), failures)
		_check(int(sim.facility_status(DEPOT).get("current_maintenance_cents", -1)) == upkeep[index], "tier %d cumulative upkeep should match" % (index + 1), failures)


func _test_finished_egg_deferral_and_level_zero_parity(failures: Array[String]) -> void:
	var baseline := DepartmentSimulation.new(20_111, 6)
	baseline.owned_facilities[PACKING] = 1
	baseline._rng.seed = 77
	baseline.workers[0].accuracy = 1.0
	baseline.workers[0].stress = 0.0
	baseline.workers[0].fatigue = 0.0
	var baseline_fund := baseline.revenue_cents
	baseline._complete_egg(baseline.workers[0])
	_check(baseline.revenue_cents > baseline_fund, "level zero should retain immediate egg cash", failures)
	_check(baseline._farmgate_dispatch.stock_count() == 0, "level zero should not create dispatch lots", failures)

	var deferred := DepartmentSimulation.new(20_112, 6)
	deferred.day = 6
	deferred._farmgate_dispatch.begin_day(6)
	deferred.owned_facilities[PACKING] = 1
	deferred.owned_facilities[GALLERY] = 1
	deferred.owned_facilities[DEPOT] = 1
	deferred._rng.seed = 77
	deferred.workers[0].accuracy = 1.0
	deferred.workers[0].stress = 0.0
	deferred.workers[0].fatigue = 0.0
	var deferred_fund := deferred.revenue_cents
	deferred._complete_egg(deferred.workers[0])
	_check(deferred.revenue_cents == deferred_fund, "sound depot egg should not mint immediate cash", failures)
	_check(deferred._farmgate_dispatch.stock_count() == 1, "sound depot egg should become one immutable lot", failures)
	var lot := deferred._farmgate_dispatch.lots[0] as Dictionary
	_check(int(lot.get("worker_id", -1)) == 0 and String(lot.get("worker_name", "")) == deferred.workers[0].display_name, "lot should bind the exact layer identity", failures)
	_check(StringName(lot.get("quality", &"")) in [&"sound", &"golden"], "only a finished sound or golden egg should defer", failures)


func _test_review_mandates_and_hold_reserve(failures: Array[String]) -> void:
	var sim := _review_fixture(20_121, 6)
	sim.owned_facilities[PACKING] = 1
	sim.owned_facilities[GALLERY] = 1
	sim.owned_facilities[DEPOT] = 1
	sim._farmgate_dispatch.begin_day(6)
	var catalog := sim.farmgate_dispatch_mandate_catalog()
	_check(catalog.size() == 4, "catalog should expose four stable mandates", failures)
	var county := _mandate(catalog, &"county_auction")
	var showcase := _mandate(catalog, &"regional_showcase")
	_check(int(county.get("projected_capacity", -1)) == 8 and int(county.get("projected_basis_points", -1)) == 10_500, "Day 6 tier-one county quote should freeze eight eggs at 105%", failures)
	_check(not bool(showcase.get("can_authorize", true)), "regional showcase should require tier three", failures)
	var auth := sim.authorize_farmgate_dispatch(&"county_auction")
	_check(bool(auth.get("accepted", false)), "review should authorize the county route", failures)
	_check(int(auth.get("dispatch_limit", -1)) == 8 and int(auth.get("price_basis_points", -1)) == 10_500, "authorization should freeze capacity and quote", failures)
	_check(not bool(sim.authorize_farmgate_dispatch(&"farmer_pickup").get("accepted", true)), "one target shift may not receive a second mandate", failures)

	var hold := _review_fixture(20_122, 6)
	hold.owned_facilities[PACKING] = 1
	hold.owned_facilities[GALLERY] = 1
	hold.owned_facilities[DEPOT] = 1
	hold._farmgate_dispatch.begin_day(6)
	hold.revenue_cents = hold.protected_reserve_cents() - 1
	_check(not bool(hold.authorize_farmgate_dispatch(&"hold_basket").get("accepted", true)), "hold should reject one cent below protected close obligations", failures)
	hold.revenue_cents = hold.protected_reserve_cents()
	_check(bool(hold.authorize_farmgate_dispatch(&"hold_basket").get("accepted", false)), "hold should accept at exact protected funding", failures)

	var running := _review_fixture(20_123, 6)
	running.owned_facilities[DEPOT] = 1
	running.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	_check(not bool(running.authorize_farmgate_dispatch(&"farmer_pickup").get("accepted", true)), "running shift should reject review-time intent changes", failures)


func _test_close_settlement_precedes_obligations(failures: Array[String]) -> void:
	var sim := DepartmentSimulation.new(20_131, 6)
	sim.day = 6
	sim.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	sim.pending_decision.clear()
	sim.owned_facilities[PACKING] = 1
	sim.owned_facilities[GALLERY] = 1
	sim.owned_facilities[DEPOT] = 1
	sim._farmgate_dispatch.begin_day(6)
	sim._farmgate_dispatch.store_lot(501, 6, 0, "Mabel", &"sound", 10_000, 1, 2, 12)
	sim.revenue_cents = 0
	sim.quota_target = 99
	var reports: Array[Dictionary] = []
	sim.workday_completed.connect(func(report: Dictionary) -> void: reports.append(report))
	sim._complete_workday()
	_check(reports.size() == 1, "close should emit one report", failures)
	if reports.size() == 1:
		var settlement := (reports[0].get("farmgate_settlement", {}) as Dictionary)
		_check(int(settlement.get("gross_cents", -1)) == 10_000, "default pickup should settle the lot before close charges", failures)
		_check(int(reports[0].get("credited_cents", -1)) == 10_000, "settlement payout should enter completed credited cash", failures)
	_check(sim.revenue_cents < 10_000 and sim.revenue_cents >= 0, "feed, upkeep, and payroll should charge after settlement without underflow", failures)


func _review_fixture(seed: int, staff_count: int) -> DepartmentSimulation:
	var sim := DepartmentSimulation.new(seed, staff_count)
	sim.day = 6
	sim.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	sim.pending_decision.clear()
	sim.revenue_cents = 1_000_000
	return sim


func _mandate(catalog: Array[Dictionary], mandate_id: StringName) -> Dictionary:
	for offer in catalog:
		if StringName(offer.get("id", &"")) == mandate_id:
			return offer
	return {}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
