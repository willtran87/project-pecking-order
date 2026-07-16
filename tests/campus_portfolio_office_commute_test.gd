extends SceneTree

const RAIL_HUB: StringName = &"collection_rail_hub"
const ORCHARD_WEST: StringName = &"orchard_west"

var _stage := "boot"


func _init() -> void:
	create_timer(45.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := _staffed_portfolio_fixture(failures)
	if not failures.is_empty():
		_finish(failures)
		return

	_stage = "building office"
	var office := Office.new()
	office.set("_simulation", simulation)
	root.add_child(office)
	await process_frame
	await process_frame
	office.call("_set_campaign_modal_open", false)
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame

	var worker_views := office.get("_worker_views") as Dictionary
	var view := worker_views.get(0) as ChickenView
	_check(view != null, "Office should retain the named staffed hen as a live ChickenView", failures)
	if view == null:
		office.free()
		_finish(failures)
		return

	var assignments := office.get("_campus_worker_assignments") as Dictionary
	var pads := office.get("_campus_worker_pads") as Dictionary
	_check(StringName(String(assignments.get(0, ""))) == RAIL_HUB, "canonical Rail Hub staffing should drive the Office commute registry", failures)
	_check(StringName(String(pads.get(0, ""))) == ORCHARD_WEST, "the commute registry should retain the installed module pad", failures)
	_check(view.has_campus_duty_assignment(), "a staffed hen should immediately reserve an authored campus commute", failures)
	_check(not simulation.is_worker_at_workstation(0), "campus assignment must remove the hen from desk production before she departs", failures)
	var camera_bounds := office.get_meta(&"commissioned_campus_bounds", Rect2()) as Rect2
	_check(camera_bounds.encloses(Office.campus_duty_commute_bounds()), "overview bounds should include the full visible commute perimeter while a campus post is staffed", failures)

	_stage = "commuting to Orchard Row"
	_advance_view(view, 150)
	var expected_duty := Office.campus_duty_position(ORCHARD_WEST)
	_check(view.is_at_campus_duty_station(), "staffed hen should reach and hold at the Orchard Row duty socket (phase=%s position=%s)" % [String(view.campus_duty_phase()), str(view.global_position)], failures)
	_check(view.global_position.distance_to(expected_duty) <= 0.08, "campus hen should stop on the protected cross-route instead of inside module geometry (position=%s expected=%s)" % [str(view.global_position), str(expected_duty)], failures)
	_check(not view.is_seated_at_workstation() and not simulation.is_worker_at_workstation(0), "campus duty must remain mutually exclusive with seated claim and egg work", failures)

	_stage = "returning from Orchard Row"
	var unassignment := simulation.unassign_campus_portfolio_worker(RAIL_HUB)
	_check(bool(unassignment.get("accepted", false)), "review fixture should allow the named hen to be released from campus duty", failures)
	office.call("_on_snapshot_changed", simulation.snapshot())
	_check(view.campus_duty_phase() == &"campus_return", "unassignment should start the authored return commute (phase=%s)" % String(view.campus_duty_phase()), failures)
	_advance_view(view, 170)
	_check(not view.has_campus_duty_assignment(), "returning to the chair should clear transient campus duty", failures)
	_check(view.is_seated_at_workstation(), "released campus hen should visibly sit before regaining production presence", failures)
	_check(simulation.is_worker_at_workstation(0), "workstation production should resume only after the seated callback", failures)
	_check((office.get("_campus_worker_assignments") as Dictionary).is_empty(), "Office commute registry should clear the released assignment", failures)

	office.free()
	await process_frame
	_finish(failures)


func _staffed_portfolio_fixture(failures: Array[String]) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(22_701, 4)
	simulation.day = 14
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 1_000_000
	simulation.market_contracts_succeeded_total = 1
	simulation.market_contracts_breached_total = 0

	_check(bool(simulation.purchase_campus_parcel(&"north_meadow").get("accepted", false)), "fixture should file North Meadow", failures)
	for service_id: StringName in [&"circulation", &"power", &"cold_chain"]:
		_check(bool(simulation.commission_campus_service(service_id).get("accepted", false)), "fixture should connect %s" % String(service_id), failures)
	_check(bool(simulation.place_campus_module(&"egg_routing_pod", &"meadow_west").get("accepted", false)), "fixture should place the routing pod", failures)
	simulation._campus_portfolio.begin_day(simulation.day, simulation._campus_portfolio_context())
	_check(bool(simulation.purchase_campus_portfolio_deed(&"orchard_row").get("accepted", false)), "fixture should file Orchard Row", failures)
	_check(bool(simulation.authorize_campus_portfolio_project(RAIL_HUB, ORCHARD_WEST).get("accepted", false)), "fixture should authorize the Rail Hub", failures)
	for target_day in [15, 16]:
		simulation.day = target_day
		simulation._campus_portfolio.begin_day(target_day, simulation._campus_portfolio_context())
	_check(bool(simulation.assign_campus_portfolio_worker(RAIL_HUB, 0).get("accepted", false)), "fixture should assign the named hen to the completed Rail Hub", failures)
	return simulation


func _advance_view(view: ChickenView, frame_count: int) -> void:
	# Large deterministic deltas make this an integration check, not a 40-second
	# real-time wait; ChickenView still consumes every authored waypoint in order.
	for _frame in frame_count:
		view.call("_physics_process", 0.75)


func _finish(failures: Array[String]) -> void:
	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPUS_PORTFOLIO_OFFICE_COMMUTE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_PORTFOLIO_OFFICE_COMMUTE_TEST_PASSED named_hen=commutes duty=cross_route workstation=exclusive return=seated")
	quit(0)


func _on_watchdog_timeout() -> void:
	push_error("CAMPUS_PORTFOLIO_OFFICE_COMMUTE_TEST_TIMEOUT: %s" % _stage)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
