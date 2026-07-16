extends SceneTree


const Portfolio := preload("res://core/simulation/campus_portfolio_state.gd")

const NORTH_MEADOW: StringName = &"north_meadow"
const PACKING := DepartmentSimulation.PACKING_ANNEX_ID
const GALLERY := DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID
const DEPOT := DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID


func _init() -> void:
	var failures: Array[String] = []
	_test_deed_and_project_reserve_are_atomic(failures)
	_test_completed_modules_require_named_staff_and_live_utilities(failures)
	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPUS_PORTFOLIO_DEPARTMENT_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_PORTFOLIO_DEPARTMENT_ECONOMY_TEST_PASSED deeds=reserve-safe projects=reserve-safe queue=fifo staffing=named utilities=live claims=+4 feed=+18/-1 upkeep=exact")
	quit(0)


func _test_deed_and_project_reserve_are_atomic(failures: Array[String]) -> void:
	var deed_simulation := _funded_grid_review(22_101)
	var funded_deed_quote := deed_simulation.campus_portfolio_deed_quote(Portfolio.ORCHARD_ROW)
	_check(bool(funded_deed_quote.get("can_authorize", false)), "Day 14 review should expose an authorized Orchard Row deed", failures)
	var deed_required := int(funded_deed_quote.get("required_spendable_cents", -1))
	_check(deed_required == 12_950, "Orchard deed should protect its exact $125 capital plus first $4.50 land obligation", failures)
	deed_simulation.revenue_cents = deed_simulation.protected_reserve_cents() + deed_required - 1
	_expect_rejected_atomic(
		deed_simulation,
		func() -> Dictionary: return deed_simulation.purchase_campus_portfolio_deed(Portfolio.ORCHARD_ROW),
		"one-cent-short Orchard Row deed",
		failures,
	)
	var exact_deed_fund := deed_simulation.protected_reserve_cents() + deed_required
	deed_simulation.revenue_cents = exact_deed_fund
	var deed := deed_simulation.purchase_campus_portfolio_deed(Portfolio.ORCHARD_ROW)
	_check(bool(deed.get("accepted", false)), "exact-reserve Orchard Row deed should authorize", failures)
	_check(int(deed.get("cost_cents", -1)) == 12_500, "accepted Orchard deed should debit exactly $125 once", failures)
	_check(deed_simulation.revenue_cents == exact_deed_fund - 12_500, "accepted Orchard deed should preserve every non-capital cent", failures)
	_check(deed_simulation.current_daily_portfolio_cost_cents() == 450, "owned Orchard Row should add exactly $4.50 daily land upkeep", failures)

	var project_simulation := _funded_grid_review(22_102)
	_check(bool(project_simulation.purchase_campus_portfolio_deed(Portfolio.ORCHARD_ROW).get("accepted", false)), "project fixture should own Orchard Row", failures)
	var project_quote := project_simulation.campus_portfolio_project_quote(
		Portfolio.COLLECTION_RAIL_HUB,
		Portfolio.ORCHARD_WEST,
	)
	_check(bool(project_quote.get("can_authorize", false)), "powered Orchard West should accept the Collection Rail Hub", failures)
	var project_required := int(project_quote.get("required_spendable_cents", -1))
	_check(project_required == 14_600, "Rail Hub filing should protect exact $140 capital plus $6 completed upkeep", failures)
	project_simulation.revenue_cents = project_simulation.protected_reserve_cents() + project_required - 1
	_expect_rejected_atomic(
		project_simulation,
		func() -> Dictionary:
			return project_simulation.authorize_campus_portfolio_project(
				Portfolio.COLLECTION_RAIL_HUB,
				Portfolio.ORCHARD_WEST,
			),
		"one-cent-short Collection Rail Hub contract",
		failures,
	)
	var exact_project_fund := project_simulation.protected_reserve_cents() + project_required
	project_simulation.revenue_cents = exact_project_fund
	var project := project_simulation.authorize_campus_portfolio_project(
		Portfolio.COLLECTION_RAIL_HUB,
		Portfolio.ORCHARD_WEST,
	)
	_check(bool(project.get("accepted", false)), "exact-reserve Rail Hub contract should authorize", failures)
	_check(int(project.get("cost_cents", -1)) == 14_000, "accepted Rail Hub should debit exactly $140 once", failures)
	_check(project_simulation.revenue_cents == exact_project_fund - 14_000, "accepted Rail Hub should preserve every non-capital cent", failures)
	var projects := project_simulation.campus_portfolio_snapshot().get("projects", []) as Array
	_check(projects.size() == 1 and StringName((projects[0] as Dictionary).get("status", &"")) == &"active", "first contractor project should enter the active board exactly once", failures)


func _test_completed_modules_require_named_staff_and_live_utilities(failures: Array[String]) -> void:
	var simulation := _funded_grid_review(22_201)
	var base_claim_capacity := simulation.current_claim_capacity()
	var base_feed := simulation.feed_procurement_snapshot()
	var base_feed_capacity := int(base_feed.get("capacity_scoops", -1))
	var base_feed_demand := int(base_feed.get("demand_scoops", -1))

	_check(bool(simulation.purchase_campus_portfolio_deed(Portfolio.ORCHARD_ROW).get("accepted", false)), "staffing fixture should purchase Orchard Row", failures)
	var rail := simulation.authorize_campus_portfolio_project(
		Portfolio.COLLECTION_RAIL_HUB,
		Portfolio.ORCHARD_WEST,
	)
	var mill := simulation.authorize_campus_portfolio_project(
		Portfolio.GRAIN_RECOVERY_MILL,
		Portfolio.ORCHARD_EAST,
	)
	_check(bool(rail.get("accepted", false)) and StringName(rail.get("project_status", &"")) == &"active", "Rail Hub should occupy the one base contractor slot", failures)
	_check(bool(mill.get("accepted", false)) and StringName(mill.get("project_status", &"")) == &"queued", "Grain Mill should enter the strict FIFO queue", failures)

	# Advancing the authoritative campaign day makes construction progress through
	# DepartmentSimulation's export normalization without reaching into project rows.
	simulation.day = 16
	simulation.export_save_state()
	var mid_projects := simulation.campus_portfolio_snapshot().get("projects", []) as Array
	_check(mid_projects.size() == 1, "Rail completion should remove it from the active board and promote the queued Mill", failures)
	if mid_projects.size() == 1:
		_check(StringName((mid_projects[0] as Dictionary).get("module_id", &"")) == Portfolio.GRAIN_RECOVERY_MILL, "FIFO promotion should start the Grain Mill next", failures)
	simulation.day = 19
	simulation.export_save_state()

	var completed := simulation.campus_portfolio_snapshot()
	_check((completed.get("projects", []) as Array).is_empty(), "both construction contracts should be complete by Day 19", failures)
	_check(simulation.current_daily_portfolio_cost_cents() == 1_750, "two completed unstaffed modules plus Orchard land should cost exactly $17.50 daily", failures)
	_check(simulation.current_claim_capacity() == base_claim_capacity, "an unstaffed Rail Hub must not create claim capacity", failures)
	var unstaffed_feed := simulation.feed_procurement_snapshot()
	_check(int(unstaffed_feed.get("capacity_scoops", -1)) == base_feed_capacity, "an unstaffed Grain Mill must not create prepaid storage", failures)
	_check(int(unstaffed_feed.get("demand_scoops", -1)) == base_feed_demand, "an unstaffed Grain Mill must not reduce feed demand", failures)

	var rail_staff := simulation.assign_campus_portfolio_worker(Portfolio.COLLECTION_RAIL_HUB, 0)
	_check(bool(rail_staff.get("accepted", false)), "an employed named hen should staff the completed Rail Hub", failures)
	_check(simulation.current_claim_capacity() == base_claim_capacity + 4, "staffed and powered Rail Hub should add exactly four claim slots", failures)
	_check(simulation.current_daily_portfolio_cost_cents() == 1_850, "first campus duty should reserve exactly one $1 daily premium", failures)
	var release := simulation.release_worker(0)
	_check(not bool(release.get("accepted", false)) and "unassign" in String(release.get("reason", "")).to_lower(), "staffing ledger should block release of a hen on campus duty", failures)

	var mill_staff := simulation.assign_campus_portfolio_worker(Portfolio.GRAIN_RECOVERY_MILL, 1)
	_check(bool(mill_staff.get("accepted", false)), "a second named hen should staff the completed Grain Mill", failures)
	var staffed_feed := simulation.feed_procurement_snapshot()
	_check(int(staffed_feed.get("capacity_scoops", -1)) == base_feed_capacity + 18, "staffed and powered Grain Mill should add exactly eighteen storage scoops", failures)
	_check(int(staffed_feed.get("demand_scoops", -1)) == maxi(3, base_feed_demand - 1), "staffed and powered Grain Mill should reduce demand by exactly one scoop", failures)
	_check(simulation.current_daily_portfolio_cost_cents() == 1_950, "land, two modules, and two named duty premiums should total exactly $19.50 daily", failures)

	# Benefits are also utility-gated. Removing the legacy trunk is a diagnostic
	# network outage; permanent obligations remain while production bonuses stop.
	var services := (simulation.campus_expansion_state.get("services", {}) as Dictionary).duplicate(true)
	services["power"] = false
	simulation.campus_expansion_state["services"] = services
	_check(simulation.current_claim_capacity() == base_claim_capacity, "a power outage should suspend the staffed Rail Hub bonus", failures)
	var outage_feed := simulation.feed_procurement_snapshot()
	_check(int(outage_feed.get("capacity_scoops", -1)) == base_feed_capacity and int(outage_feed.get("demand_scoops", -1)) == base_feed_demand, "a power outage should suspend both Grain Mill benefits", failures)
	_check(simulation.current_daily_portfolio_cost_cents() == 1_950, "utility loss must not erase filed land, module, or duty obligations", failures)


func _funded_grid_review(seed: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 4)
	simulation.day = 14
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 1_000_000
	# This mirrors the existing strict North Meadow persistence fixture: the three
	# structural tiers are canonical access evidence while only four hens are active.
	simulation.office_capacity = 6
	simulation.owned_facilities[PACKING] = 3
	simulation.owned_facilities[GALLERY] = 3
	simulation.owned_facilities[DEPOT] = 3
	simulation.export_save_state()
	if not bool(simulation.campus_expansion_state.get("parcel_owned", false)):
		simulation.purchase_campus_parcel(NORTH_MEADOW)
	for service_id: StringName in [&"circulation", &"power", &"cold_chain"]:
		if not bool((simulation.campus_expansion_state.get("services", {}) as Dictionary).get(String(service_id), false)):
			simulation.commission_campus_service(service_id)
	return simulation


func _expect_rejected_atomic(
	simulation: DepartmentSimulation,
	action: Callable,
	label: String,
	failures: Array[String],
) -> void:
	var before := _json_round_trip(simulation.export_save_state())
	var result := action.call() as Dictionary
	_check(not bool(result.get("accepted", false)), "%s should reject" % label, failures)
	_check(not String(result.get("reason", "")).is_empty(), "%s should explain the protected reserve" % label, failures)
	_check(_json_round_trip(simulation.export_save_state()) == before, "%s should preserve every authoritative field atomically" % label, failures)


func _json_round_trip(source: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(source))
	return parsed as Dictionary if parsed is Dictionary else {}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
