extends SceneTree

const OfficeScript := preload("res://features/office/office.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := OfficeScript.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var clock := office.get("_clock") as SimulationClock
	var simulation := office.get("_simulation") as DepartmentSimulation
	var ticker := office.get("_ticker_label") as Label
	_check(clock != null and simulation != null and ticker != null, "Office should expose its authoritative clock, simulation, and completion receipt", failures)
	if clock == null or simulation == null or ticker == null:
		_finish(office, failures)
		return

	# Keep this clock contract isolated from flock travel and animation timing.
	# The event still exercises the production Office entry/completion methods.
	(office.get("_worker_views") as Dictionary).clear()
	var preferences: Dictionary = office.get("_player_preferences")
	preferences["motion_mode"] = "reduced"
	office.set("_player_preferences", preferences)
	office.call("_prepare_capture_running")
	_check(
		simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING,
		"fixture should exercise a legitimately resumable running shift",
		failures,
	)

	var expected_copy := [
		"Production remains paused",
		"Production resumes at 1x",
		"Production resumes at 3x",
		"Production resumes at 10x",
	]
	for speed_index in SimulationClock.SPEED_MULTIPLIERS.size():
		clock.set_speed(speed_index)
		office.call("_on_feed_party_funded")
		_check(clock.speed_index == 0, "Feed Party should hold %dx at pause while attendance runs" % speed_index, failures)
		office.call("_complete_feed_party_visual")
		_check(
			clock.speed_index == speed_index,
			"Feed Party should restore exact speed index %d" % speed_index,
			failures,
		)
		_check(
			expected_copy[speed_index] in ticker.text,
			"completion receipt should state the restored speed for index %d" % speed_index,
			failures,
		)

	# Every blocking management surface remains authoritative over remembered
	# event speed. The shared gate protects these views as the UI grows.
	var decision_host := office.get("_decision_host") as Control
	var day_review := office.get("_day_review_scrim") as Control
	var settings := office.get("_settings_ui") as Control
	var capital_blueprint := office.get("_capital_blueprint_ui") as Control
	var campaign := office.get("_campaign_ui") as ProbationCampaignUI
	var blocking_surfaces: Array[Dictionary] = [
		{"name": "decision", "control": decision_host},
		{"name": "day review", "control": day_review},
		{"name": "settings", "control": settings},
		{"name": "capital blueprint", "control": capital_blueprint},
	]
	for fixture in blocking_surfaces:
		var surface := fixture["control"] as Control
		clock.set_speed(3)
		office.call("_on_feed_party_funded")
		surface.visible = true
		office.call("_complete_feed_party_visual")
		_check(
			clock.speed_index == 0,
			"%s should suppress remembered Feed Party speed" % String(fixture["name"]),
			failures,
		)
		_check(
			"remains paused while a management file is open" in ticker.text,
			"%s-gated completion should explain why speed was not restored" % String(fixture["name"]),
			failures,
		)
		surface.visible = false

	clock.set_speed(3)
	office.call("_on_feed_party_funded")
	campaign.show_title(false)
	office.call("_complete_feed_party_visual")
	_check(clock.speed_index == 0, "campaign review should suppress remembered Feed Party speed", failures)
	_check(
		"remains paused while a management file is open" in ticker.text,
		"campaign-gated completion should explain why speed was not restored",
		failures,
	)
	campaign.hide_modal()

	# Capital transitions can retain their speed hold for a frame after a panel
	# closes; that ownership must also beat the event's remembered 10x intent.
	clock.set_speed(3)
	office.call("_on_feed_party_funded")
	office.set("_capital_modal_holds_speed", true)
	office.call("_complete_feed_party_visual")
	_check(clock.speed_index == 0, "capital transition hold should suppress remembered Feed Party speed", failures)
	office.set("_capital_modal_holds_speed", false)

	_finish(office, failures)


func _finish(office: Node, failures: Array[String]) -> void:
	office.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FEED_PARTY_SPEED_RESTORE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FEED_PARTY_SPEED_RESTORE_TEST_PASSED speeds=0x+1x+3x+10x gates=all_blocking_surfaces receipt=truthful")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
