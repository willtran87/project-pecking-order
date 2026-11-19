extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var sign := Label3D.new()
	sign.font = SystemFont.new()
	sign.font_size = 64
	sign.text = "LIVE CLUTCH"
	sign.set_meta("text_area_size", Vector2(1.5, 0.4))
	sign.set_meta("requested_pixel_size", 0.004)
	root.add_child(sign)
	EnvironmentalSignage.refit_label(sign)
	var fitted := sign.pixel_size
	var fit_count := int(sign.get_meta("signage_fit_count"))
	for _repeat in 12:
		EnvironmentalSignage.set_copy(sign, "LIVE CLUTCH")
	_check(int(sign.get_meta("signage_fit_count")) == fit_count, "unchanged signs must reuse their measured fit", failures)
	EnvironmentalSignage.set_copy(sign, "A MUCH LONGER LIVE CLUTCH RECOGNITION RECEIPT")
	_check(sign.pixel_size < fitted, "longer copy must fit immediately inside its physical sign", failures)
	for field in ["area", "size", "requested", "screen", "font", "resource"]:
		fit_count = int(sign.get_meta("signage_fit_count"))
		match field:
			"area": sign.set_meta("text_area_size", Vector2(1.1, 0.3))
			"size": sign.font_size = 80
			"requested": sign.set_meta("requested_pixel_size", 0.002)
			"screen": sign.set_meta("screen_copy", true)
			"font": sign.font = SystemFont.new()
			"resource": sign.font.emit_changed()
		EnvironmentalSignage.refit_label(sign)
		_check(int(sign.get_meta("signage_fit_count")) == fit_count + 1, "changed %s must invalidate the measured fit" % field, failures)
	var current_font := sign.font
	var fitted_width := sign.width
	sign.width = 1
	EnvironmentalSignage.refit_label(sign)
	_check(sign.width == fitted_width, "external width changes must be repaired", failures)
	sign.free()
	current_font.emit_changed() # The invalidation connection must die with the label.

	root.size = Vector2i(1280, 720)
	var office := Office.new()
	# Exercises later-shift layers (PLAN / Flock Ties) on a fresh shift-1 file.
	office.progressive_feature_introduction = false
	root.add_child(office)
	for _frame in 24:
		await process_frame
	var clock := office.get("_clock") as SimulationClock
	clock.set_process(false)
	clock.set_speed(0)
	office.set_process(false)
	var simulation := office.get("_simulation") as DepartmentSimulation
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	var playbook := {
		"strategy_preset_id": "safe",
		"contract": {"id": "clean", "label": "CLEAN CLUTCH", "progress": 1, "target": 4},
		"options": [{"kind": "signature", "id": "help", "label": "HELP HEN", "available": true, "detail": "Original detail", "icon": "flock"}],
	}
	office.call("_refresh_active_playbook_menu", playbook, 1)
	var builds: int = office.get("_active_playbook_menu_build_count")
	var button := office.get("_active_playbook_button") as MenuButton
	var old_meta: Dictionary = button.get_meta("playbook")
	var changed := playbook.duplicate(true)
	changed["contract"]["progress"] = 3
	changed["personal_best"] = {"routing": {"current": 4}}
	office.call("_refresh_active_playbook_menu", changed, 1)
	_check(int(office.get("_active_playbook_menu_build_count")) == builds, "progress changes must not rebuild unchanged choices", failures)
	_check("3 / 4" in button.tooltip_text and int(old_meta["contract"]["progress"]) == 1, "live tooltip progress must update while retained metadata stays stable [tooltip=%s old=%s]" % [button.tooltip_text, old_meta], failures)
	changed["options"][0]["detail"] = "New cost and outcome"
	office.call("_refresh_active_playbook_menu", changed, 1)
	_check(int(office.get("_active_playbook_menu_build_count")) == builds + 1, "changed choice details must rebuild immediately", failures)
	_check(button.get_popup().get_item_tooltip(0) == "New cost and outcome", "the popup must disclose current choice details", failures)
	changed["options"][0]["available"] = false
	office.call("_refresh_active_playbook_menu", changed, 1)
	_check(int(button.get_meta("option_count")) == 0, "unavailable choices must disappear immediately", failures)
	office.call("_refresh_active_playbook_menu", playbook, 2)
	_check(int(office.get("_active_playbook_focused_worker_id")) == 2, "actions must target the newly selected hen", failures)
	var snapshot := simulation.snapshot()
	var original := snapshot.duplicate(true)
	var visual: Dictionary = office.call("_workstation_visual_snapshot", snapshot)
	var feedback := office.get("_workstation_feedback") as WorkstationFeedback
	feedback.apply_snapshot(visual)
	_check(snapshot == original, "desk feedback must not mutate borrowed worker state", failures)
	var storytelling := office.get("_office_storytelling") as OfficeStorytelling
	storytelling.apply_campus_presentation(snapshot, {})
	var old_campus: Dictionary = storytelling.get("_campus_presentation")
	var campus_copy := old_campus.duplicate(true)
	var progress_only := snapshot.duplicate(true)
	progress_only["time_label"] = "10:45 AM"
	progress_only["workers"][0]["progress"] = 97.0
	progress_only["campus_expansion"]["operating_minutes"] = 99
	progress_only["contract_board"]["completed_units"] = 23
	progress_only["facility_catalog"][0]["live_progress"] = 42
	var public_campus := storytelling.apply_campus_presentation(progress_only, {})
	_check(is_same(old_campus, storytelling.get("_campus_presentation")), "clock and work progress must not rebuild unchanged campus reveals", failures)
	public_campus["visible_ids"].append("caller mutation")
	_check(old_campus == campus_copy, "returned campus projections must stay isolated from the retained cache", failures)
	storytelling.apply_campus_presentation(progress_only, {"teaser_id": "records_annex"})
	_check(not is_same(old_campus, storytelling.get("_campus_presentation")), "changed reveal options must update immediately", failures)
	progress_only["pinned_capital_plan_id"] = "records_annex"
	var pinned := storytelling.apply_campus_presentation(progress_only, {})
	_check(String(pinned["entries_by_id"]["records_annex"]["state"]) == "pinned", "pinning a project must immediately reveal its finished scene", failures)
	progress_only["owned_facilities"]["records_annex"] = 1
	var owned := storytelling.apply_campus_presentation(progress_only, {})
	_check(String(owned["entries_by_id"]["records_annex"]["state"]) == "owned", "mutating caller-owned purchase state must invalidate the isolated input cache", failures)
	office.free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("PRESENTATION_UPDATE_EFFICIENCY_TEST_%s" % ("PASSED" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
