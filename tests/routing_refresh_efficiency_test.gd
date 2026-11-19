extends SceneTree


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
	var routing := office.get("_routing_ui") as PeckworkRoutingUI
	var simulation := office.get("_simulation") as DepartmentSimulation
	var source: Dictionary = office.call("_routing_visual_snapshot", simulation.snapshot())
	source["shift_phase"] = DepartmentSimulation.ShiftPhase.RUNNING
	routing.set("_dossier_canvas_scale", 1.0)
	routing.set_interaction_enabled(true)
	var worker: Dictionary = source["workers"][0]
	worker["state_label"] = "PECKING"
	worker["progress"] = 42.0
	worker["current_claim"] = {"id": 123, "lane": "nest_damage", "value_cents": 300, "minutes_until_deadline": 35}
	worker["peck_assist"] = {"available": true, "window_state": "open", "remaining": 3, "limit": 3}
	routing.apply_first_clutch({"visible": false})
	routing.apply_snapshot(source)
	routing.set_focus(int(worker["id"]))
	var failures: Array[String] = []
	var progress := routing.get("_claim_progress_bar") as ProgressBar
	_check(is_equal_approx(progress.value, 42.0), "fixture must show the current file progress", failures)
	var fill := progress.get_theme_stylebox("fill")
	var warm := routing.runtime_refresh_diagnostic()
	for _repeat in 12:
		routing.apply_snapshot(source)
	var stable := routing.runtime_refresh_diagnostic()
	_check(stable["panel_styles"] == warm["panel_styles"] and stable["compact_styles"] == warm["compact_styles"], "stable progress must not allocate new style variants", failures)
	_check(stable["font_writes"] == warm["font_writes"], "identical worker refreshes must not reset and rescale the hen action font", failures)
	_check(is_same(fill, progress.get_theme_stylebox("fill")), "the progress fill must retain its existing resource", failures)
	for scale: float in [1.0, 1.5, 1.0]:
		routing.set_interface_scale(scale)
		routing.call("_apply_dossier_readability")
		var writes: int = routing.runtime_refresh_diagnostic()["font_writes"]
		for _repeat in 5:
			routing.call("_apply_dossier_readability")
		_check(int(routing.runtime_refresh_diagnostic()["font_writes"]) == writes, "unchanged readability must not invalidate fonts", failures)
		for control: Control in routing.get("_dossier_readability_controls"):
			if control is Label or control is Button:
				var expected := roundi(maxi(12, int(control.get_meta("dossier_base_font"))) * scale)
				_check(control.get_theme_font_size("font_size") == expected, "font scaling must remain correct at each supported scale", failures)
	var next := source.duplicate(true)
	next["workers"][0]["progress"] = 68.0
	next["workers"][0]["current_claim"]["minutes_until_deadline"] = 3
	routing.apply_snapshot(next)
	_check(is_equal_approx(progress.value, 68.0), "new progress must render immediately without a cache delay", failures)
	var facts: Array = routing.routing_lifecycle_state().get("claim_facts", [])
	_check(facts.any(func(row: Dictionary) -> bool: return String(row.get("role", "")) == "deadline" and "3" in String(row.get("value", ""))), "the new deadline must remain current", failures)
	routing.set_peck_assist_clock_running(false)
	var peck := routing.get("_peck_assist_button") as Button
	_check(bool(peck.get_meta("resume_required")), "paused pecks must still disclose resume", failures)
	routing.set_peck_assist_clock_running(true)
	_check(not bool(peck.get_meta("resume_required")), "resuming must update the current action immediately", failures)
	var color := Color("29453f")
	var border := Color("5b9b8d")
	var panel: StyleBoxFlat = routing.call("_panel_style", color, color.a, border, 6, 1)
	var margin := panel.content_margin_left
	var compact: StyleBoxFlat = routing.call("_compact_button_style", color, border, 1)
	_check(panel.content_margin_left == margin and compact.content_margin_left == 6.0, "compact margins must not mutate shared panel styles", failures)
	_check(compact.bg_color == color and compact.border_color == border, "cached styles must preserve authored colors", failures)
	office.free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("ROUTING_REFRESH_EFFICIENCY_TEST_%s" % ("PASSED" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
