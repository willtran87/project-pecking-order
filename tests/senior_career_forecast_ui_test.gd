extends SceneTree

const SeniorRoostStateScript := preload("res://core/campaign/senior_roost_state.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var label := office.find_child("CampaignObjectivesLabel", true, false) as Label
	var heading := office.find_child("CampaignOrdersHeading", true, false) as Label
	var panel := office.find_child("FlockwatchLedger", true, false) as PanelContainer
	_check(label != null and heading != null and panel != null, "Office should build the existing Flockwatch forecast hosts", failures)

	office.call("_update_campaign_objectives_label", simulation.snapshot())
	var outside := office.call("_senior_career_forecast", simulation.snapshot()) as Dictionary
	_check(not bool(outside.get("visible", true)), "probation/title state must not publish a Senior forecast", failures)
	_check(label != null and not bool(label.get_meta("career_forecast_visible", false)), "existing Flockwatch summary should hide the forecast outside Senior", failures)

	var senior := SeniorRoostStateScript.new()
	_check(senior.begin(5), "UI fixture should begin Senior Roost", failures)
	_check(
		bool(senior.select_annual_mandate(
			SeniorRoostStateScript.MANDATE_FALLBACK_ID,
			senior.current_year_number(),
		).get("accepted", false)),
		"UI fixture should file the no-stake annual Board fallback before its quarter policy",
		failures,
	)
	_check(senior.record_quarter_policy({
		"accepted": true,
		"policy_id": &"harvest_forecast",
		"style_id": &"management_innovation",
		"outcome": "UI forecast policy filed.",
	}), "UI fixture should activate a Senior quarter", failures)
	office.set("_senior_roost_state", senior)
	office.set("_campaign_senior_roost", true)
	office.set("_campaign_review_stage", &"active")
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	office.call("_set_campaign_modal_open", false)
	office.call("_set_flockwatch_open", true)
	office.call("_update_campaign_objectives_label", simulation.snapshot())
	await process_frame
	await process_frame

	var forecast := office.call("_senior_career_forecast", simulation.snapshot()) as Dictionary
	var json_round_trip: Variant = JSON.parse_string(JSON.stringify(forecast))
	_check(bool(forecast.get("visible", false)), "active Senior floor should publish its derived career forecast", failures)
	var restored_forecast := json_round_trip as Dictionary if json_round_trip is Dictionary else {}
	_check(
		not restored_forecast.is_empty()
		and int(restored_forecast.get("projected_score", -1)) == int(forecast.get("projected_score", -2))
		and int(restored_forecast.get("projected_marks", -1)) == int(forecast.get("projected_marks", -2))
		and String((restored_forecast.get("largest_recoverable_component", {}) as Dictionary).get("id", ""))
		== String((forecast.get("largest_recoverable_component", {}) as Dictionary).get("id", "")),
		"career forecast diagnostic should preserve its player-facing contract through primitive JSON",
		failures,
	)
	_check(heading != null and heading.text == "SENIOR CAREER + BOARD FORECAST", "existing Flockwatch heading should name both compact career horizons", failures)
	_check(
		label != null
		and bool(label.get_meta("career_forecast_visible", false))
		and _contains_all(label.text, ["if filed now", "/ 100", "mark", "recoverable", "year book", "target"]),
		"top Flockwatch summary should show quarter score, marks, the largest recoverable component, and annual book progress without a new section",
		failures,
	)
	_check(
		label != null
		and _contains_all(label.tooltip_text, ["quota reliability", "shell integrity", "queue control", "flock welfare", "coop obedience", "farmer favor", "solvency", "annual board mandate"]),
		"forecast tooltip should retain every authoritative quarter component plus the annual mandate ledger",
		failures,
	)
	_check(label != null and label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "compact forecast should wrap in the existing narrow ledger", failures)
	_check_forecast_containment(label, panel, "1280x720", failures)

	root.size = Vector2i(390, 844)
	await process_frame
	await process_frame
	_check_forecast_containment(label, panel, "390x844", failures)

	office.set("_campaign_review_stage", &"farmer")
	office.call("_update_campaign_objectives_label", simulation.snapshot())
	var review_forecast := office.call("_senior_career_forecast", simulation.snapshot()) as Dictionary
	_check(not bool(review_forecast.get("visible", true)), "farmer review should hide live projection instead of counting the closing shift twice", failures)
	_check(label != null and not bool(label.get_meta("career_forecast_visible", true)), "Flockwatch summary should clear its forecast metadata outside active play", failures)
	_check(heading != null and heading.text != "SENIOR CAREER + BOARD FORECAST", "review gate should restore the ordinary Senior heading", failures)

	(office.get("_clock") as SimulationClock).set_speed(0)
	office.free()
	await process_frame
	root.size = Vector2i(1280, 720)
	if not failures.is_empty():
		for failure in failures:
			push_error("SENIOR_CAREER_FORECAST_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SENIOR_CAREER_FORECAST_UI_TEST_PASSED host=existing summary=quarter+annual causes=7 diagnostic=json-safe visibility=active-only responsive=1280x720-390x844")
	quit(0)


func _check_forecast_containment(label: Label, panel: PanelContainer, viewport_label: String, failures: Array[String]) -> void:
	if label == null or panel == null:
		return
	var label_rect := label.get_global_rect()
	var panel_rect := panel.get_global_rect()
	_check(
		label_rect.position.x >= panel_rect.position.x - 0.5
		and label_rect.end.x <= panel_rect.end.x + 0.5,
		"%s forecast should remain horizontally inside Flockwatch (label=%s panel=%s)" % [viewport_label, label_rect, panel_rect],
		failures,
	)


func _contains_all(source: String, fragments: Array[String]) -> bool:
	var normalized := source.to_lower()
	for fragment in fragments:
		if not normalized.contains(fragment.to_lower()):
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
