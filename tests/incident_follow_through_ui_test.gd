extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	var simulation := office.get("_simulation") as DepartmentSimulation
	simulation._decision_serial = 1
	simulation._record_standard_incident_response(&"credit_town_hall", &"credit_layers", 1, 1)
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	var memory := simulation.incident_follow_through_snapshot(&"calendar_overflow")
	var decision := {
		"serial": 2,
		"kind": &"incident",
		"id": &"calendar_overflow",
		"day": 1,
		"eyebrow": "INCIDENT / AUTO-PAUSED / 11:30 AM",
		"title": "THE ROOSTERS HAVE SCHEDULED A MEETING ABOUT MEETINGS",
		"body": "Every manager has added a status sync to explain why the flock has too many status syncs.",
		"case_memory": memory,
		"options": simulation._incident_choices(&"calendar_overflow"),
	}
	# Keep the fixture authoritative so the selected response can exercise the
	# real synchronous simulation -> Office resolution feedback chain.
	simulation._decision_serial = 2
	simulation.pending_decision = decision.duplicate(true)
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT
	office.call("_on_decision_requested", decision)
	await process_frame
	var body := office.find_child("DecisionBody", true, false) as Label
	var cancel_button := office.find_child("DecisionOption_cancel_status_sync", true, false) as Button
	var decision_preview := office.find_child("DecisionPreview", true, false) as Label
	var confirm_button := office.find_child("ConfirmDecisionButton", true, false) as Button
	var precedent_label := office.find_child("FlockwatchTodayPrecedent", true, false) as Label
	var flockwatch_navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	var diagnostic := office.call("_pending_decision_diagnostic_state") as Dictionary
	var diagnostic_memory := diagnostic.get("case_memory", {}) as Dictionary
	_check(
		body != null
		and "PRIOR CREDIT FILE / LAYERS NAMED" in body.text
		and "canceling this sync worth +2 more flock trust" in body.text,
		"the incident card should present the prior case and its exact causal bonus",
		failures,
	)
	_check(
		cancel_button != null and "flock trust +4" in cancel_button.tooltip_text,
		"the affected response card should present its exact modified total",
		failures,
	)
	if cancel_button != null:
		cancel_button.emit_signal("pressed")
		await process_frame
	_check(
		decision_preview != null
		and "PRECEDENT // NEXT CREDIT TOWN HALL" in decision_preview.text
		and "discounts CREDIT THE LAYERS from $10 to $6" in decision_preview.text,
		"selecting a response should disclose the exact precedent it sets before authorization",
		failures,
	)
	_check(
		precedent_label != null
		and precedent_label.visible
		and "OPEN PRECEDENT · NEXT MEETING OVERFLOW" in precedent_label.text
		and "from +2 to +4 flock trust" in precedent_label.text,
		"Flockwatch Today should retain the currently open precedent without another menu",
		failures,
	)
	_check(
		flockwatch_navigation != null
		and "Open precedent for NEXT MEETING OVERFLOW" in flockwatch_navigation.accessible_text(),
		"Flockwatch narration should announce the open precedent on its Today page",
		failures,
	)
	_check(
		StringName(diagnostic_memory.get("id", &"")) == &"layers_named_to_calendar"
		and StringName(diagnostic_memory.get("affected_option_id", &"")) == &"cancel_status_sync",
		"diagnostics should expose sanitized structured case memory for Web narration",
		failures,
	)
	var diagnostic_options := diagnostic.get("options", []) as Array
	_check(
		not diagnostic_options.is_empty()
		and String(((diagnostic_options[0] as Dictionary).get("precedent", {}) as Dictionary).get("target_label", "")) == "NEXT CREDIT TOWN HALL",
		"decision diagnostics should expose the selected response's authored precedent for Web narration",
		failures,
	)

	if "--capture-incident-follow-through" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://output/web-game/incident-follow-through-v1")
		await process_frame
		var image := root.get_texture().get_image()
		image.save_png("res://output/web-game/incident-follow-through-v1/case-memory.png")

	if confirm_button != null:
		confirm_button.emit_signal("pressed")
		await process_frame
		await process_frame
	var ticker_label := office.get("_ticker_label") as Label
	var status_history := office.get("_status_history") as Array[String]
	var audio_feedback := office.get("_audio_feedback") as OfficeAudioFeedback
	var feedback_snapshot := audio_feedback.feedback_snapshot() if audio_feedback != null else {}
	var accessible_resolution := (
		flockwatch_navigation.accessible_text()
		if flockwatch_navigation != null else
		""
	)
	_check(
		ticker_label != null
		and "PRECEDENT FILED / NEXT CREDIT TOWN HALL" in ticker_label.text
		and "from $10 to $6" in ticker_label.text,
		"authorization should confirm the exact filed precedent in the existing status surface",
		failures,
	)
	_check(
		not status_history.is_empty()
		and "PRECEDENT FILED / NEXT CREDIT TOWN HALL" in status_history[0],
		"the existing shift record should durably retain the precedent filing without another overlay",
		failures,
	)
	_check(
		String(feedback_snapshot.get("last_cue", "")) == "precedent_filed",
		"a precedent resolution should use one distinct pooled confirmation cue",
		failures,
	)
	_check(
		precedent_label != null
		and "OPEN PRECEDENT" in precedent_label.text
		and "NEXT CREDIT TOWN HALL" in precedent_label.text
		and "from $10 to $6" in precedent_label.text,
		"Flockwatch Today should immediately replace the consumed precedent with the newly filed one",
		failures,
	)
	_check(
		"Latest notice:" in accessible_resolution
		and "PRECEDENT FILED / NEXT CREDIT TOWN HALL" in accessible_resolution
		and "Open precedent for NEXT CREDIT TOWN HALL" in accessible_resolution,
		"assistive narration should confirm both the filed receipt and the newly open precedent",
		failures,
	)

	office.queue_free()
	await process_frame
	if failures.is_empty():
		print("INCIDENT_FOLLOW_THROUGH_UI_TEST_PASSED card=true preview=true resolution=true audio=precedent_filed")
		quit(0)
		return
	for failure in failures:
		push_error("INCIDENT_FOLLOW_THROUGH_UI_TEST_FAILED: %s" % failure)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
