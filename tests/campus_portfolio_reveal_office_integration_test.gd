extends SceneTree

const RAIL_HUB: StringName = &"collection_rail_hub"
const GRAIN_MILL: StringName = &"grain_recovery_mill"
const ORCHARD: StringName = &"orchard_row"
const ORCHARD_WEST: StringName = &"orchard_west"
const ORCHARD_EAST: StringName = &"orchard_east"

var _stage := "boot"


func _init() -> void:
	create_timer(65.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := _funded_review_fixture(failures)
	if not failures.is_empty():
		_finish(null, failures)
		return
	_stage = "building office"
	var office := Office.new()
	office.set("_simulation", simulation)
	root.add_child(office)
	await process_frame
	await process_frame
	office.call("_set_campaign_modal_open", false)
	var review_scrim := office.get("_day_review_scrim") as Control
	if review_scrim != null:
		review_scrim.visible = false
	office.call("_on_snapshot_changed", simulation.snapshot())
	office.call("_open_capital_blueprint", false, false)
	office.call("_on_campus_expansion_requested")
	await process_frame
	await process_frame

	var portfolio := office.get("_campus_portfolio_ui") as CampusPortfolioUI
	var reveal := office.get("_campus_portfolio_reveal_ui") as CampusPortfolioRevealUI
	var visual := office.find_child("CampusPortfolioVisual", true, false) as CampusPortfolioVisual
	var camera := office.get("_camera_controller") as ManagementCameraController
	_check(portfolio != null and reveal != null and visual != null and camera != null, "Office should compose the planner, held live-world reveal, physical portfolio, and exact camera", failures)
	_check(portfolio != null and portfolio.is_open(), "portfolio should begin as the active planning surface", failures)
	if portfolio == null or reveal == null or visual == null or camera == null:
		_finish(office, failures)
		return

	_stage = "filing Orchard Row deed"
	office.call("_on_campus_portfolio_deed_requested", ORCHARD)
	await process_frame
	await process_frame
	var deed_receipt := reveal.receipt_snapshot()
	var marker := visual.reveal_target_snapshot()
	var unowned := visual.find_child("OrchardRowUnownedDeedStakes", true, false) as Node3D
	var owned := visual.find_child("OrchardRowOwnedFarmParcel", true, false) as Node3D
	_check(reveal.is_reveal_visible() and not portfolio.is_open(), "accepted deed should replace the opaque planner with a held world reveal", failures)
	_check(StringName(String(deed_receipt.get("action_id", ""))) == &"purchase_deed" and int(deed_receipt.get("cost_cents", 0)) == 12_500, "deed reveal should retain the authoritative action and exact $125 capital filing", failures)
	_check(StringName(String(marker.get("parcel_id", ""))) == ORCHARD and StringName(String(marker.get("pad_id", ""))) == &"", "deed reveal should bracket the exact Orchard Row parcel", failures)
	_check(camera.current_focus_label == "ORCHARD ROW", "deed reveal should focus the named parcel instead of the generic campus", failures)
	_check(unowned != null and not unowned.visible and owned != null and owned.visible, "the world behind the deed receipt should already show unowned-to-owned reconciliation", failures)
	_check(_contains_all(reveal.accessible_text(), ["campus deed filed", "orchard row", "$125.00"]), "deed reveal should narrate the exact visible transition", failures)
	office.call("_on_campus_portfolio_reveal_return_requested")
	await process_frame
	_check(portfolio.is_open() and not reveal.is_reveal_visible() and visual.reveal_target_snapshot().is_empty(), "Return should restore the portfolio and clear only the temporary world marker", failures)

	_stage = "authorizing active and queued projects"
	office.call("_on_campus_portfolio_project_requested", RAIL_HUB, ORCHARD_WEST)
	await process_frame
	await process_frame
	var active_receipt := reveal.receipt_snapshot()
	var foundation := visual.find_child("ProjectFoundationStage_orchard_west", true, false) as Node3D
	_check(reveal.is_reveal_visible() and not portfolio.is_open(), "accepted module should again expose the live pad instead of leaving the planner over it", failures)
	_check(StringName(String(active_receipt.get("action_id", ""))) == &"authorize_project" and StringName(String(active_receipt.get("status", ""))) == &"active", "first contractor filing should expose its exact active authorization receipt", failures)
	_check(StringName(String(visual.reveal_target_snapshot().get("pad_id", ""))) == ORCHARD_WEST, "active project reveal should bracket Orchard West exactly", failures)
	_check(camera.current_focus_label == "COLLECTION RAIL HUB / ORCHARD WEST PAD", "project reveal camera should name both exact module and pad", failures)
	_check(foundation != null and foundation.visible, "empty Orchard West should visibly become foundation construction before acknowledgement", failures)
	_save_visual_capture("active-project")
	office.call("_on_campus_portfolio_reveal_return_requested")
	await process_frame

	office.call("_on_campus_portfolio_project_requested", GRAIN_MILL, ORCHARD_EAST)
	await process_frame
	await process_frame
	var queued_receipt := reveal.receipt_snapshot()
	var queued_stage := visual.find_child("ProjectQueuedStage_orchard_east", true, false) as Node3D
	_check(StringName(String(queued_receipt.get("status", ""))) == &"queued", "second authorization should surface its contractor-queue state", failures)
	_check(queued_stage != null and queued_stage.visible, "empty Orchard East should visibly become survey-staged while the queue receipt is held", failures)
	office.call("_on_campus_portfolio_reveal_continue_requested")
	await process_frame
	_check(not reveal.is_reveal_visible() and visual.reveal_target_snapshot().is_empty(), "Continue should clear the held overlay and temporary marker", failures)

	_stage = "closing shifts through construction"
	var day_15_progress := _advance_portfolio_day(simulation, 15)
	var day_16_progress := _advance_portfolio_day(simulation, 16)
	office.call("_on_snapshot_changed", simulation.snapshot())
	_check((day_15_progress.get("completed", []) as Array).is_empty(), "the two-shift Rail Hub should not complete after only one boundary", failures)
	_check((day_16_progress.get("completed", []) as Array).size() == 1 and (day_16_progress.get("started", []) as Array).size() == 1, "the second boundary should complete Rail Hub and mobilize the queued Grain Mill", failures)
	var campaign_state: Object = office.get("_campaign_state")
	if campaign_state != null:
		campaign_state.set("outcome", &"passed")
	var workday_report := {
		"day": 16,
		"eggs": 0,
		"quota": 1,
		"met_quota": false,
		"closing_fund_cents": simulation.revenue_cents,
		"campus_portfolio_progress": day_16_progress.duplicate(true),
	}
	office.call("_on_workday_completed", workday_report)
	await process_frame
	await process_frame
	_check(review_scrim != null and review_scrim.visible, "shift boundary should preserve Farmer Review as the immediate closing surface", failures)
	_check(not reveal.is_reveal_visible() and (office.get("_pending_campus_portfolio_reveals") as Array).size() == 2, "construction completion and mobilization should queue without interrupting Farmer Review", failures)

	_stage = "revealing completed building on return to planning"
	office.call("_open_capital_blueprint", true, false)
	office.call("_on_campus_expansion_requested")
	await process_frame
	await process_frame
	var completion_receipt := reveal.receipt_snapshot()
	var rail_module := visual.find_child("Module_collection_rail_hub_orchard_west", true, false) as Node3D
	_check(reveal.is_reveal_visible() and not portfolio.is_open(), "returning to campus planning should present the held completion before the portfolio", failures)
	_check(StringName(String(completion_receipt.get("action_id", ""))) == &"complete_project", "first queued boundary reveal should be the exact completed project receipt", failures)
	_check(rail_module != null and rail_module.visible, "completed Rail Hub should be permanently visible behind its receipt", failures)
	_check(StringName(String(visual.reveal_target_snapshot().get("pad_id", ""))) == ORCHARD_WEST, "completion receipt should bracket the commissioned Rail Hub pad", failures)
	_save_visual_capture("completed-project")
	office.call("_on_campus_portfolio_reveal_continue_requested")
	await process_frame

	_stage = "revealing queued contractor mobilization"
	await process_frame
	var start_receipt := reveal.receipt_snapshot()
	var grain_foundation := visual.find_child("ProjectFoundationStage_orchard_east", true, false) as Node3D
	_check(StringName(String(start_receipt.get("action_id", ""))) == &"start_project", "Continue should advance to the second exact contractor mobilization receipt before restoring planning", failures)
	_check(StringName(String(visual.reveal_target_snapshot().get("pad_id", ""))) == ORCHARD_EAST and grain_foundation != null and grain_foundation.visible, "mobilization should focus Orchard East while its physical stage is active construction", failures)
	office.call("_on_campus_portfolio_reveal_return_requested")
	await process_frame
	_check((office.get("_pending_campus_portfolio_reveals") as Array).is_empty(), "all exact day-boundary receipts should be consumed once", failures)

	_stage = "assigning named hen and showing commute"
	office.call("_on_campus_portfolio_staff_assignment_requested", RAIL_HUB, 0)
	await process_frame
	await process_frame
	var staff_receipt := reveal.receipt_snapshot()
	var worker_views := office.get("_worker_views") as Dictionary
	var mabel := worker_views.get(0) as ChickenView
	_check(reveal.is_reveal_visible() and not portfolio.is_open(), "accepted staffing should reveal the named module instead of remaining under the planner", failures)
	_check(StringName(String(staff_receipt.get("action_id", ""))) == &"assign_worker" and int(staff_receipt.get("worker_id", -1)) == 0, "staff receipt should retain the exact named-worker identity", failures)
	_check(_contains_all(reveal.accessible_text(), ["named campus perch staffed", "mabel", "collection rail hub", "orchard west"]), "staff reveal should narrate the named hen and exact campus post", failures)
	_check(mabel != null and mabel.has_campus_duty_assignment() and not simulation.is_worker_at_workstation(0), "accepted staffing should visibly begin the hen's authored commute and immediately remove desk production", failures)
	_save_visual_capture("named-hen")
	office.call("_on_campus_portfolio_reveal_continue_requested")
	await process_frame
	_check(review_scrim != null and review_scrim.visible, "final Continue should restore the Farmer Review origin held throughout campus inspection", failures)
	_check(not reveal.is_reveal_visible() and visual.reveal_target_snapshot().is_empty(), "final acknowledgement should leave no overlay or marker behind", failures)

	_finish(office, failures)


func _funded_review_fixture(failures: Array[String]) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(27_701, 4)
	simulation.day = 14
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 1_000_000
	simulation.market_contracts_succeeded_total = 1
	simulation.market_contracts_breached_total = 0
	_check(bool(simulation.purchase_campus_parcel(&"north_meadow").get("accepted", false)), "fixture should file North Meadow", failures)
	for service_id: StringName in [&"circulation", &"power", &"cold_chain"]:
		_check(bool(simulation.commission_campus_service(service_id).get("accepted", false)), "fixture should connect %s" % String(service_id), failures)
	_check(bool(simulation.place_campus_module(&"egg_routing_pod", &"meadow_west").get("accepted", false)), "fixture should place the utility pod", failures)
	var progress := simulation._campus_portfolio.begin_day(14, simulation._campus_portfolio_context())
	_check(bool(progress.get("accepted", false)), "fixture should reconcile the portfolio clock to review day 14", failures)
	return simulation


func _advance_portfolio_day(simulation: DepartmentSimulation, target_day: int) -> Dictionary:
	simulation.day = target_day
	return simulation._campus_portfolio.begin_day(target_day, simulation._campus_portfolio_context())


func _save_visual_capture(label: String) -> void:
	if "--capture-reveal" not in OS.get_cmdline_user_args():
		return
	var viewport_size := root.get_visible_rect().size.round()
	var capture_directory := ProjectSettings.globalize_path(
		"res://output/campus-portfolio-reveal-visual"
	)
	DirAccess.make_dir_recursive_absolute(capture_directory)
	var image := root.get_texture().get_image()
	var file_name := "%s-%dx%d.png" % [label, int(viewport_size.x), int(viewport_size.y)]
	if image == null:
		push_error("Campus reveal visual capture requires an active rendering display for %s." % file_name)
		return
	var error := image.save_png(capture_directory.path_join(file_name))
	if error != OK:
		push_error("Campus reveal visual capture could not save %s (error %d)." % [file_name, error])


func _finish(office: Office, failures: Array[String]) -> void:
	if office != null and is_instance_valid(office):
		office.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPUS_PORTFOLIO_REVEAL_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_PORTFOLIO_REVEAL_OFFICE_INTEGRATION_TEST_PASSED deed=world project=active+queued boundary=complete+start farmer-review=preserved staffing=named-commute receipt=held")
	quit(0)


func _contains_all(text_value: String, needles: Array[String]) -> bool:
	var lowered := text_value.to_lower()
	for needle: String in needles:
		if needle.to_lower() not in lowered:
			return false
	return true


func _on_watchdog_timeout() -> void:
	push_error("CAMPUS_PORTFOLIO_REVEAL_OFFICE_INTEGRATION_TEST_TIMEOUT: %s" % _stage)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
