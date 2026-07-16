extends SceneTree

const PARCEL: StringName = &"north_meadow"
const POD: StringName = &"egg_routing_pod"
const WEST: StringName = &"meadow_west"
const EAST: StringName = &"meadow_east"
const BLOCKED: StringName = &"service_spine"

var _stage := "boot"


func _init() -> void:
	create_timer(50.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := _funded_review_fixture()
	var initial_claim_capacity := simulation.current_claim_capacity()
	var initial_fund := simulation.revenue_cents
	var office := Office.new()
	office.set("_simulation", simulation)
	root.add_child(office)
	await process_frame
	await process_frame
	_stage = "opening Capital Blueprint"

	office.call("_set_campaign_modal_open", false)
	var review_scrim := office.get("_day_review_scrim") as Control
	if review_scrim != null:
		review_scrim.visible = false
	office.call("_on_snapshot_changed", simulation.snapshot())
	office.call("_open_capital_blueprint", false, false)
	await process_frame
	await process_frame

	var blueprint := office.get("_capital_blueprint_ui") as CapitalBlueprintUI
	var portfolio := office.get("_campus_portfolio_ui") as CampusPortfolioUI
	var planner := office.get("_campus_expansion_ui") as CampusExpansionUI
	var visual := office.find_child("CampusExpansionVisual", true, false) as CampusExpansionVisual
	var camera := office.get("_camera_controller") as ManagementCameraController
	var portal := office.find_child("CapitalBlueprintCampusExpansionButton", true, false) as Button
	_check(blueprint != null and portfolio != null and planner != null and visual != null and camera != null, "Office should compose the Blueprint, portfolio, North Meadow detail planner, physical meadow, and camera", failures)
	_check(portfolio != null and not portfolio.is_open(), "Campus Portfolio should remain hidden until the player opens it", failures)
	_check(planner != null and not planner.is_open(), "Campus planner should remain hidden until the player opens it", failures)
	_check(portal != null and portal.is_visible_in_tree(), "Capital Blueprint should expose North Meadow as a persistent planning route", failures)
	if portal != null:
		portal.pressed.emit()
	await process_frame
	await process_frame
	_check(portfolio != null and portfolio.is_open() and blueprint != null and not blueprint.is_open(), "Campus route should replace the Blueprint with the three-parcel portfolio", failures)
	_check(camera != null and camera.current_focus_label == "CAMPUS PORTFOLIO", "opening the portfolio should focus the expanded campus", failures)
	var details_button := office.find_child("CampusPortfolioNorthMeadowDetailsButton", true, false) as Button
	_check(details_button != null and details_button.is_visible_in_tree(), "North Meadow card should expose its detailed utilities and placement file", failures)
	if details_button != null:
		details_button.pressed.emit()
	await process_frame
	await process_frame
	_check(planner != null and planner.is_open() and portfolio != null and not portfolio.is_open(), "North Meadow details should replace the portfolio with the authored utility planner", failures)
	_check(camera != null and camera.current_focus_label == "NORTH MEADOW", "opening North Meadow details should focus the physical expansion parcel", failures)

	_stage = "purchasing parcel"
	var parcel_button := office.find_child("CampusExpansionPurchaseParcelButton", true, false) as Button
	_check(parcel_button != null and not parcel_button.disabled and "$85.00" in parcel_button.text, "authorized Depot access should expose the exact $85 North Meadow filing", failures)
	if parcel_button != null:
		parcel_button.pressed.emit()
	await process_frame
	await process_frame
	_check(bool(simulation.campus_expansion_snapshot().get("parcel_owned", false)), "parcel intent should reach the authoritative North Meadow transaction", failures)

	_stage = "checking route rejection"
	_check(planner.select_socket(BLOCKED), "Service Spine should be selectable so its route rejection can be inspected", failures)
	await process_frame
	var place_button := office.find_child("CampusExpansionPlacePodButton", true, false) as Button
	_check(place_button != null and place_button.disabled, "Service Spine must never expose an enabled pod authorization", failures)
	_check("reserved" in planner.accessible_text().to_lower(), "blocked placement should explain that flock circulation owns the route", failures)

	_stage = "commissioning services"
	for service_id: StringName in [&"circulation", &"power", &"cold_chain"]:
		var service_button := office.find_child(
			"CampusExpansionConnectService_%s" % String(service_id), true, false
		) as Button
		_check(service_button != null and not service_button.disabled, "%s should become actionable after the parcel deed" % String(service_id), failures)
		if service_button != null:
			service_button.pressed.emit()
		await process_frame
		await process_frame

	_stage = "placing and relocating pod"
	_check(planner.select_socket(WEST), "Meadow West should be a cleared placement choice", failures)
	await process_frame
	place_button = office.find_child("CampusExpansionPlacePodButton", true, false) as Button
	_check(place_button != null and not place_button.disabled and "$75.00" in place_button.text, "Meadow West should expose the exact $75 pod filing", failures)
	if place_button != null:
		place_button.pressed.emit()
	await process_frame
	await process_frame
	_check(simulation.current_claim_capacity() == initial_claim_capacity + 6, "commissioned routing pod should add exactly six live-file slots", failures)
	_check(int(simulation.farmgate_dispatch_snapshot().get("storage_capacity_eggs", 0)) == 18, "commissioned cold-chain should extend the level-one Depot from 12 to 18 eggs", failures)
	_check(StringName(visual.get("_pod_socket")) == WEST, "physical Egg Routing Pod should appear once at Meadow West", failures)

	_check(planner.select_socket(EAST), "Meadow East should remain a legal relocation choice", failures)
	await process_frame
	var relocate_button := office.find_child("CampusExpansionRelocatePodButton", true, false) as Button
	_check(relocate_button != null and not relocate_button.disabled and "$18.00" in relocate_button.text, "Meadow East should expose the exact $18 relocation filing", failures)
	if relocate_button != null:
		relocate_button.pressed.emit()
	await process_frame
	await process_frame
	var campus := simulation.campus_expansion_snapshot()
	_check(StringName(campus.get("pod_socket_id", &"")) == EAST and StringName(visual.get("_pod_socket")) == EAST, "one accepted relocation should move both authoritative and physical pod state to Meadow East", failures)
	_check(simulation.revenue_cents == initial_fund - 30_100, "land, three services, pod, and relocation should debit exactly $301 once", failures)
	_check(simulation.current_daily_campus_cost_cents() == 1_575, "relocation should preserve the exact $15.75 recurring campus obligation", failures)
	_check(StringName(campus.get("construction_stage", &"")) == &"cold_chain_operational", "completed physical campus should expose its terminal construction stage", failures)

	var commissioned_bounds := office.get_meta(&"commissioned_campus_bounds", Rect2()) as Rect2
	var navigation := office.get_meta(&"campus_navigation_footprint", Rect2()) as Rect2
	_check(commissioned_bounds.encloses(CampusExpansionVisual.declared_footprint()), "management camera bounds should derive from and enclose the purchased parcel", failures)
	_check(navigation == CampusExpansionVisual.navigation_footprint(simulation.snapshot()), "Office should publish the exact purchased circulation footprint for future pathing", failures)

	_stage = "returning through Portfolio to Blueprint"
	var close_button := office.find_child("CampusExpansionCloseButton", true, false) as Button
	if close_button != null:
		close_button.pressed.emit()
	await process_frame
	_check(planner != null and not planner.is_open() and portfolio != null and portfolio.is_open(), "closing North Meadow details should return to the still-held Campus Portfolio", failures)
	var portfolio_return := office.find_child("CampusPortfolioReturnButton", true, false) as Button
	if portfolio_return != null:
		portfolio_return.pressed.emit()
	await process_frame
	_check(portfolio != null and not portfolio.is_open() and blueprint != null and blueprint.is_open(), "closing Campus Portfolio should return to the still-held Capital Blueprint", failures)

	if office != null and is_instance_valid(office):
		office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPUS_EXPANSION_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_EXPANSION_OFFICE_INTEGRATION_TEST_PASSED blueprint=portfolio north=details parcel=owned services=3 route=blocked pod=place+relocate camera=derived save=checkpointed")
	quit(0)


func _funded_review_fixture() -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(21_701, 4)
	simulation.day = 6
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 500_000
	simulation.owned_facilities[DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID] = 1
	simulation._farmgate_dispatch.begin_day(6)
	return simulation


func _on_watchdog_timeout() -> void:
	push_error("CAMPUS_EXPANSION_OFFICE_INTEGRATION_TEST_TIMEOUT: %s" % _stage)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
