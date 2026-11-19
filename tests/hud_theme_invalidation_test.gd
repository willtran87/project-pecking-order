extends SceneTree

var failures: Array[String] = []
var theme_events := 0

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	for _frame in 24:
		await process_frame
	var clock := office.get("_clock") as SimulationClock
	clock.set_process(false)
	clock.set_speed(0)
	office.set_process(false)
	var simulation := office.get("_simulation") as DepartmentSimulation
	var snapshot := simulation.snapshot()
	office.call("_apply_snapshot_presentation", snapshot)
	for _frame in 3:
		await process_frame
	for field in ["_quality_streak_label", "_directive_badge", "_rival_pulse_label", "_flock_labor_label", "_records_archive_label"]:
		var control := office.get(field) as Control
		check(control != null, "Expected live HUD binding: " + field)
		if control != null:
			control.theme_changed.connect(func() -> void: theme_events += 1)
	for _repeat in 3:
		office.call("_apply_snapshot_presentation", snapshot)
		await process_frame
		await process_frame
	print("HUD_REPEATED_THEME_EVENTS=%d" % theme_events)
	check(theme_events == 0, "Identical live snapshots must not invalidate HUD themes")
	# State transitions still repaint immediately, including returning to an old state.
	var quality := office.get("_quality_streak_label") as Label
	var low := snapshot.duplicate(true)
	low["quality_streak"] = 0
	var high := low.duplicate(true)
	high["quality_streak"] = 5
	office.call("_apply_snapshot_presentation", low)
	var low_color := quality.get_theme_color("font_color")
	office.call("_apply_snapshot_presentation", high)
	check(quality.get_theme_color("font_color") != low_color, "A reward streak must change its accent immediately")
	office.call("_apply_snapshot_presentation", low)
	check(quality.get_theme_color("font_color") == low_color, "Ending a streak must restore its previous accent")
	var glances: Array = office.get("_campaign_order_glances")
	check(not glances.is_empty(), "Goal card fixture must exist")
	if not glances.is_empty():
		var glance := glances[0] as Label
		glance.set_meta("objective_id", "theme_test")
		glance.set_meta("focus_accent", Color("8ed3b1"))
		office.set("_focused_campaign_order_id", &"")
		office.call("_refresh_campaign_order_glance_focus_style", glance)
		var tile := office.call("_flockwatch_glance_tile", glance) as Control
		var style := tile.get_theme_stylebox("panel")
		office.call("_refresh_campaign_order_glance_focus_style", glance)
		check(tile.get_theme_stylebox("panel") == style, "Unchanged goals must retain their panel resource")
		office.set("_focused_campaign_order_id", &"theme_test")
		office.call("_refresh_campaign_order_glance_focus_style", glance)
		var focused := tile.get_theme_stylebox("panel") as StyleBoxFlat
		check(focused.border_width_left == 2, "Focused goals must have the full focus border")
		glance.set_meta("focus_accent", Color("efb37c"))
		office.call("_refresh_campaign_order_glance_focus_style", glance)
		check((tile.get_theme_stylebox("panel") as StyleBoxFlat).border_color.is_equal_approx(Color(Color("efb37c"), 0.96)), "Goal risk changes must recolor the focus border")
		office.set("_focused_campaign_order_id", &"")
		office.call("_refresh_campaign_order_glance_focus_style", glance)
		check((tile.get_theme_stylebox("panel") as StyleBoxFlat).border_width_left == 1, "Leaving a goal must restore its normal border")
		glance.set_meta("metric", &"eggs")
		office.call("_configure_campaign_order_driver_action", glance)
		var driver := office.get("_campaign_order_driver_button") as Button
		var driver_style := driver.get_theme_stylebox("normal")
		glance.set_meta("objective_id", "next_goal")
		glance.set_meta("objective_title", "NEXT GOAL")
		glance.set_meta("metric", &"welfare")
		office.call("_configure_campaign_order_driver_action", glance)
		check(driver.get_theme_stylebox("normal") == driver_style, "An unchanged driver accent must reuse its styles")
		check(driver.get_meta("objective_id") == "next_goal" and "NEXT GOAL" in driver.tooltip_text, "Reusing paint must not retain the previous goal action or tooltip")
		check(driver.get_meta("driver_action_id") == "flock_care", "Changing a goal's metric must change its driver even when the accent is identical")
	var routing := office.get("_routing_ui") as PeckworkRoutingUI
	var worker := {"hen_intent": {"id": "route", "icon": "steady", "action_id": "route", "action_label": "ROUTE", "urgency": 1}}
	routing.call("_refresh_hen_intent", worker)
	await process_frame
	await process_frame
	var intent := routing.get("_hen_intent_button") as Button
	var intent_events := [0]
	intent.theme_changed.connect(func() -> void: intent_events[0] += 1)
	for _repeat in 3:
		routing.call("_refresh_hen_intent", worker)
		await process_frame
		await process_frame
	check(intent_events[0] == 0, "Unchanged hen actions must not invalidate their theme")
	worker["hen_intent"]["id"] = "choice"
	worker["hen_intent"]["urgency"] = 3
	worker["hen_intent"]["cutoff_progress"] = 70
	routing.call("_refresh_hen_intent", worker)
	check(intent.get_theme_font_size("font_size") >= 12 and intent.theme_type_variation == &"PrimaryButton", "A hen's urgent choice must keep readable text and update emphasis immediately")
	check("70" in intent.text, "Hen choices must keep their live cutoff")
	office.free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("HUD_THEME_INVALIDATION_TEST_%s" % ("PASSED" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
