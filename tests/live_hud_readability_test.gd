extends SceneTree

const Store := preload("res://core/persistence/campaign_save_store.gd")

class CountedOffice:
	extends Office
	var layout_passes := 0
	func _apply_physical_hud_layout() -> void:
		layout_passes += 1
		super._apply_physical_hud_layout()

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var store := Store.new("live_hud_readability_test.json")
	var office := CountedOffice.new()
	office.set("_campaign_store", store)
	root.add_child(office)
	await process_frame
	await process_frame
	office.call("_prepare_capture_running")
	office.set_process(false)
	(office.get("_clock") as SimulationClock).set_speed(0)
	(office.get("_top_hud_panel") as Control).show()
	var failures: Array[String] = []
	office.call("_measure_live_hud_canvas")
	var stable_passes := office.layout_passes
	for sample in 10:
		office.call("_measure_live_hud_canvas")
	_check(office.layout_passes == stable_passes, "unchanged canvas measurements must not repeat recursive layout", failures)
	for interface_scale in [1.0, 1.5]:
		(office.get("_player_preferences") as Dictionary)["ui_scale"] = interface_scale
		office.call("_apply_management_ui_preferences")
		_check(office.layout_passes > stable_passes, "preference changes must invalidate cached layout", failures)
		stable_passes = office.layout_passes
		for ratio in [1.0, 900.0 / 1280.0]:
			office.set("_hud_canvas_ratio", ratio)
			office.set("_compact_physical_hud", ratio < 1.0)
			office.call("_apply_physical_hud_layout")
			office.call("_refresh_gameplay_pulse", (office.get("_simulation") as DepartmentSimulation).snapshot())
			for frame in 4:
				await process_frame
			var state := office.call("_live_hud_diagnostic_state") as Dictionary
			for control_name in ["SpeedButton_0", "CompactSpeedMenu", "NextMomentButton", "OpenSettingsButton", "ActivePlaybookButton"]:
				var item: Dictionary = state.controls[control_name]
				if not item.visible:
					continue
				var rect: Dictionary = item.rect
				_check(float(rect.x) >= 0 and float(rect.x) + float(rect.width) <= 1281, "%s fits at ratio %.2f / text %.1f: %s" % [control_name, ratio, interface_scale, rect], failures)
				if ratio < 1.0:
					_check(float(rect.height) * ratio >= 44.0, "%s retains a 44px physical target" % control_name, failures)
			var title := office.get("_live_title_label") as Label
			_check(ratio >= 1.0 or not title.visible, "compact refresh must not restore the title", failures)
			var clock_rect := (office.get("_shift_clock_status_host") as Control).get_global_rect()
			var fund_rect := (office.get("_fund_status_host") as Control).get_global_rect()
			_check(clock_rect.end.x <= fund_rect.position.x, "clock and spendable money never overlap at ratio %.2f / text %.1f: clock=%s fund=%s" % [ratio, interface_scale, clock_rect, fund_rect], failures)
			_check(not (office.get("_consequence_icon_host") as Control).visible, "secondary consequence icons stay in inspect mode", failures)
			var goal_rect := (office.get("_quota_progress") as Control).get_global_rect()
			office.call("_set_guidance", "NEXT", &"goal", "Short instruction", &"today")
			await process_frame
			office.call("_set_guidance", "A MUCH LONGER INSTRUCTION THAT MUST NOT MOVE THE QUOTA OR CONTROLS", &"goal", "Long instruction", &"today")
			await process_frame
			_check((office.get("_quota_progress") as Control).get_global_rect().is_equal_approx(goal_rect), "changing guidance must not shift the quota", failures)
	# Reward receipts get a bounded reading beat, not a queue of stale popups.
	office.call("_publish_status_copy", "MABEL DELIVERED · +$2.00 FEED FUND")
	office.call("_publish_status_copy", "PIP DELIVERED · +$3.00 FEED FUND")
	_check(String(office.get("_ticker_visible_copy")).begins_with("MABEL"), "simultaneous rewards must not replace a receipt before it can be read", failures)
	_check((office.get("_status_history") as Array).has("PIP DELIVERED · +$3.00 FEED FUND"), "overlapping rewards must remain in Shift Record", failures)
	office.set("_ticker_shown_at_msec", Time.get_ticks_msec() - 1900)
	office.call("_publish_status_copy", "DOT DELIVERED · +$4.00 FEED FUND")
	_check(String(office.get("_ticker_visible_copy")).begins_with("DOT"), "reward reading beat must expire", failures)
	office.call("_publish_status_copy", "WARNING · A FILE NEEDS HELP")
	_check(String(office.get("_ticker_visible_copy")).begins_with("WARNING"), "urgent warnings must interrupt reward receipts immediately", failures)
	office.free()
	store.delete()
	if failures.is_empty():
		print("LIVE_HUD_READABILITY_TEST_PASSED desktop+compact text=100+150 targets=44px hierarchy=stable")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
