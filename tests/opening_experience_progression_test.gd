extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")

const TEST_SAVE_FILENAME := "opening_experience_progression_test.json"
const CORE_CAMPUS_BOUNDS := Rect2(Vector2(-12.0, -9.0), Vector2(24.0, 18.0))
const EXPECTED_SECTION_IDS: Array[StringName] = [
	&"today",
	&"flock",
	&"staffing_flock",
	&"operations",
	&"staffing_operations",
	&"staffing_capital",
	&"capital",
	&"staffing_records",
	&"records",
]

var _stage := "boot"


func _init() -> void:
	create_timer(60.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	var store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	store.delete()
	var office := Office.new()
	office.set("_campaign_store", store)
	root.add_child(office)
	await process_frame
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var camera_controller := office.get("_camera_controller") as ManagementCameraController
	var storytelling := office.get("_office_storytelling") as OfficeStorytelling
	var navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var campaign_badge := office.find_child("ProbationDayBadge", true, false) as PanelContainer
	var blueprint := office.get("_capital_blueprint_ui") as CapitalBlueprintUI
	var routing_ui := office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	var live_hud := office.find_child("LiveShiftHUD", true, false) as PanelContainer
	var objective_row := office.find_child("ShiftObjectiveRow", true, false) as HBoxContainer
	var queue_strip := office.find_child("PeckworkQueueStrip", true, false) as PanelContainer
	var flockwatch_toggle := office.find_child("FlockwatchToggle", true, false) as Button
	var flockwatch_panel := office.find_child("FlockwatchLedger", true, false) as PanelContainer
	var status_toast := office.find_child("StatusToast", true, false) as PanelContainer
	var status_history := office.find_child("FlockwatchStatusHistory", true, false) as Label
	_check(
		simulation != null
		and camera_controller != null
		and storytelling != null
		and navigation != null
		and campaign_ui != null
		and campaign_badge != null
		and blueprint != null
		and routing_ui != null,
		"Office should compose every opening-experience collaborator",
		failures,
	)

	_stage = "checking compact campus frame"
	var commissioned_bounds := office.get_meta(&"commissioned_campus_bounds", Rect2()) as Rect2
	var campus_presentation := office.get_meta(&"campus_presentation", {}) as Dictionary
	var camera_frame := camera_controller.overview_bounds_frame() if camera_controller != null else {}
	var camera_target: Vector3 = camera_frame.get("target", Vector3(INF, INF, INF))
	var camera_size := float(camera_frame.get("size", INF))
	_check(
		commissioned_bounds == CORE_CAMPUS_BOUNDS,
		"a fresh file should commission only the occupied 24 by 18 bureau footprint (got %s)" % str(commissioned_bounds),
		failures,
	)
	_check(
		is_zero_approx(camera_target.x)
		and is_equal_approx(camera_target.y, 0.65)
		and is_zero_approx(camera_target.z)
		and camera_size >= 25.5
		and camera_size <= 30.0,
		"fresh overview should remain centered on the core bureau with a compact camera size (target %s, size %.2f)" % [str(camera_target), camera_size],
		failures,
	)
	_check(
		storytelling != null
		and storytelling.visible_campus_footprints().is_empty()
		and (campus_presentation.get("visible_footprints", []) as Array).is_empty()
		and (campus_presentation.get("visible_ids", []) as Array).is_empty(),
		"future facilities, parcels, and approach spines should contribute no Day 1 camera footprint",
		failures,
	)
	var teaser_count := 0
	var presentation_entries := campus_presentation.get("entries_by_id", {}) as Dictionary
	for entry_value: Variant in presentation_entries.values():
		if entry_value is Dictionary and StringName((entry_value as Dictionary).get("state", &"")) == &"teased":
			teaser_count += 1
	_check(teaser_count <= 1, "campus presentation should disclose at most one future-site teaser", failures)

	_stage = "checking one-step perch disclosure"
	var visible_markers: Array[Node] = []
	for marker: Node in office.find_children("CapacityAuthorization_*", "Node3D", true, false):
		if (marker as Node3D).visible:
			visible_markers.append(marker)
	var fifth_marker := office.find_child("CapacityAuthorization_04", true, false) as Node3D
	var sixth_marker := office.find_child("CapacityAuthorization_05", true, false) as Node3D
	_check(
		visible_markers.size() == 1
		and fifth_marker != null
		and fifth_marker.visible
		and sixth_marker != null
		and not sixth_marker.visible,
		"fresh capacity should signpost only the next available perch, not every future desk",
		failures,
	)

	_stage = "checking blocking title surface"
	campaign_ui.show_title(false)
	office.call("_set_campaign_modal_open", true)
	await process_frame
	await process_frame
	_check(campaign_ui.is_modal_open(), "the title fixture should be a genuine blocking campaign surface", failures)
	_check(live_hud != null and not live_hud.visible, "campaign title should hide the live-shift HUD", failures)
	_check(flockwatch_toggle != null and not flockwatch_toggle.visible, "campaign title should hide the ledger launcher", failures)
	_check(routing_ui != null and not routing_ui.visible, "campaign title should hide the hen dossier and routing controls", failures)

	_stage = "starting First Clutch"
	var new_campaign := office.find_child("NewCampaignButton", true, false) as Button
	_check(new_campaign != null and not new_campaign.disabled, "campaign title should retain the New Campaign action", failures)
	if new_campaign != null and not new_campaign.disabled:
		new_campaign.pressed.emit()
	await process_frame
	await process_frame
	await process_frame
	var clutch := office.first_clutch_snapshot()
	_check(
		not bool(clutch.get("dismissed", true)) and not bool(clutch.get("completed", true)),
		"the real New Campaign action should enter optional First Clutch orientation",
		failures,
	)
	_check(
		navigation.available_page_ids() == [FlockwatchNavigation.PAGE_TODAY, FlockwatchNavigation.PAGE_FLOCK],
		"First Clutch should disclose only Today and Flock by default",
		failures,
	)
	_check(
		live_hud != null
		and is_equal_approx(live_hud.offset_bottom, Office.FIRST_CLUTCH_HUD_HEIGHT)
		and objective_row != null
		and not objective_row.visible
		and routing_ui != null
		and is_equal_approx(routing_ui.top_inset(), Office.FIRST_CLUTCH_ROUTING_TOP)
		and queue_strip != null
		and is_equal_approx(queue_strip.offset_top, Office.FIRST_CLUTCH_ROUTING_TOP)
		and flockwatch_toggle != null
		and is_equal_approx(flockwatch_toggle.offset_top, Office.FIRST_CLUTCH_ROUTING_TOP)
		and flockwatch_panel != null
		and is_equal_approx(flockwatch_panel.offset_top, Office.FIRST_CLUTCH_ROUTING_TOP + 52.0),
		"First Clutch should collapse duplicate live metrics and pull its focused controls into the reclaimed space",
		failures,
	)
	_check(
		campaign_ui != null
		and is_equal_approx(campaign_ui.active_badge_top(), Office.FIRST_CLUTCH_ROUTING_TOP),
		"First Clutch should align the compact campaign badge with the single-row HUD",
		failures,
	)

	_stage = "checking All Filings reachability"
	_check(
		navigation.registered_section_ids() == EXPECTED_SECTION_IDS,
		"Flockwatch should preserve every feature section under one of its five pages (got %s)" % str(navigation.registered_section_ids()),
		failures,
	)
	navigation.set_show_all_filings(true)
	await process_frame
	_check(
		navigation.available_page_ids() == FlockwatchNavigation.PAGE_ORDER,
		"All Filings should preserve explicit access to all five filing pages during orientation",
		failures,
	)
	for page_id: StringName in FlockwatchNavigation.PAGE_ORDER:
		_check(navigation.open_page(page_id), "%s should remain reachable through All Filings" % String(page_id), failures)
		await process_frame
		var page_scroll := navigation.page_scroll(page_id)
		_check(page_scroll != null and page_scroll.visible, "%s should reveal its persistent scroll surface when opened" % String(page_id), failures)
		_check(not navigation.registered_section_ids(page_id).is_empty(), "%s should retain at least one registered feature section" % String(page_id), failures)
	navigation.set_show_all_filings(false)
	await process_frame
	_check(
		navigation.current_page_id() == FlockwatchNavigation.PAGE_TODAY,
		"closing All Filings should return orientation to the safe Today page",
		failures,
	)

	_stage = "checking post-orientation relevance"
	# Emit the same semantic intent as the optional coach's Skip action. Normal
	# mode should immediately expose the two everyday management filing domains.
	routing_ui.first_clutch_skip_requested.emit()
	await process_frame
	await process_frame
	clutch = office.first_clutch_snapshot()
	_check(bool(clutch.get("dismissed", false)), "Skip should retire First Clutch without changing campaign features", failures)
	_check(
		navigation.is_page_available(FlockwatchNavigation.PAGE_OPERATIONS)
		and navigation.is_page_available(FlockwatchNavigation.PAGE_CAPITAL),
		"post-orientation Flockwatch should reveal Operations and Capital immediately",
		failures,
	)
	_check(
		live_hud != null
		and is_equal_approx(live_hud.offset_bottom, Office.LIVE_HUD_HEIGHT)
		and objective_row != null
		and objective_row.visible
		and routing_ui != null
		and is_equal_approx(routing_ui.top_inset(), Office.LIVE_ROUTING_TOP)
		and queue_strip != null
		and is_equal_approx(queue_strip.offset_top, Office.LIVE_ROUTING_TOP),
		"normal play should restore the complete live HUD and its established routing position",
		failures,
	)
	campaign_ui.show_active_campaign()
	office.call("_set_campaign_modal_open", false)
	office.call("_set_flockwatch_open", true)
	await process_frame
	await process_frame
	_check(
		campaign_ui.is_badge_suppressed() and campaign_badge != null and not campaign_badge.visible,
		"an open Flockwatch drawer should suppress the campaign badge instead of overlapping its header",
		failures,
	)
	office.call("_set_flockwatch_open", false)
	await process_frame
	_check(
		not campaign_ui.is_badge_suppressed()
		and campaign_badge != null
		and campaign_badge.visible
		and is_equal_approx(campaign_badge.offset_top, Office.LIVE_ROUTING_TOP),
		"closing Flockwatch should restore the active badge to the normal HUD row",
		failures,
	)

	_stage = "checking Blueprint and notices"
	var parcel_controls := blueprint.find_children("CapitalBlueprintParcel_*", "Button", true, false)
	_check(parcel_controls.size() == 13, "Ready filtering must retain all 13 stable Blueprint parcel controls", failures)
	_check(blueprint.set_filter(&"ready"), "Blueprint should retain the public Ready filter", failures)
	_check(
		blueprint.find_children("CapitalBlueprintParcel_*", "Button", true, false).size() == 13,
		"switching to Ready should filter presentation without destroying future feature controls",
		failures,
	)
	_check(
		status_toast != null
		and is_equal_approx(status_toast.anchor_left, 0.5)
		and is_equal_approx(status_toast.anchor_right, 0.5)
		and status_toast.size.x < float(root.size.x) * 0.75
		and status_toast.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"live notices should use a centered, nonblocking toast instead of a permanent full-width ticker",
		failures,
	)
	_check(
		status_history != null
		and navigation.page_scroll(FlockwatchNavigation.PAGE_TODAY).is_ancestor_of(status_history),
		"persistent notice history should remain reachable inside Today's Flockwatch filing",
		failures,
	)

	office.free()
	await process_frame
	store.delete()
	if not failures.is_empty():
		for failure: String in failures:
			push_error("OPENING_EXPERIENCE_PROGRESSION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OPENING_EXPERIENCE_PROGRESSION_TEST_PASSED campus=core camera=compact teaser<=1 perch=next chrome=blocked+adaptive pages=2+all+normal blueprint=13 notices=toast+history")
	quit(0)


func _on_watchdog_timeout() -> void:
	push_error("OPENING_EXPERIENCE_PROGRESSION_TEST_TIMEOUT: %s" % _stage)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
