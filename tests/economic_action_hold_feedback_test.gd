extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	office.call("_prepare_capture_running")
	office.call("_retire_action_outcome_receipts", &"economic_hold_test", false)
	var simulation := office.get("_simulation") as DepartmentSimulation
	var navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	var ticker := office.get("_ticker_label") as Label
	_check(
		simulation != null and navigation != null and ticker != null,
		"Office should expose the authoritative economy, Flockwatch, and status receipt",
		failures,
	)
	if simulation == null or navigation == null or ticker == null:
		await _finish(office, failures)
		return

	var before_state := simulation.export_save_state()
	var expected_receipts: Array[Dictionary] = [
		{
			"invoke": func() -> void: office.call("_on_claim_resolution_requested", -1, &"unknown"),
			"copy": "CLAIMANT FILE HELD  ·  REVIEW PATH",
			"semantic": "Claimant file held.",
		},
		{
			"invoke": func() -> void: office.call("_on_personnel_action_requested", -1, &"unknown"),
			"copy": "CHECK-IN HELD  ·  REVIEW HEN",
			"semantic": "Personnel check-in held.",
		},
		{
			"invoke": func() -> void: office.call("_on_facility_purchase_requested", &"unknown"),
			"copy": "BUILD HELD  ·  REVIEW GATE",
			"semantic": "Facility requisition held.",
		},
		{
			"invoke": func() -> void: office.call("_on_feed_order_requested", &"unknown"),
			"copy": "PROVISIONS HELD  ·  REVIEW LOT",
			"semantic": "Provisions order held.",
		},
		{
			"invoke": func() -> void: office.call("_on_farmgate_dispatch_mandate_requested", &"unknown"),
			"copy": "FARMGATE HELD  ·  REVIEW MANDATE",
			"semantic": "Farmgate mandate held.",
		},
		{
			"invoke": func() -> void: office.call("_on_farmer_relations_campaign_requested", &"unknown"),
			"copy": "GALLERY HELD  ·  REVIEW CAMPAIGN",
			"semantic": "Gallery campaign held.",
		},
		{
			"invoke": func() -> void: office.call("_on_flock_relations_action_requested", -1, &"unknown"),
			"copy": "FLOCK CASE HELD  ·  REVIEW TERMS",
			"semantic": "Flock Relations case held.",
		},
		{
			"invoke": func() -> void: office.call("_handle_internship_action_result", {
				"accepted": false,
				"reason": "No rotation seat remains; review the current fellows.",
			}),
			"copy": "ROTATION HELD  ·  REVIEW CANDIDATE",
			"semantic": "Internship rotation held.",
		},
		{
			"invoke": func() -> void: office.call("_handle_manager_action_result", {
				"accepted": false,
				"reason": "That directive is no longer available; review the current manager.",
			}),
			"copy": "MANAGEMENT HELD  ·  REVIEW DIRECTIVE",
			"semantic": "Management filing held.",
		},
		{
			"invoke": func() -> void: office.call("_handle_staffing_action_result", {
				"accepted": false,
				"reason": "Roster capacity is full; review an existing hen or commission a perch.",
			}, &"worker_hired"),
			"copy": "STAFFING HELD  ·  REVIEW ROSTER",
			"semantic": "Staffing filing held.",
		},
	]
	for receipt in expected_receipts:
		(receipt.get("invoke") as Callable).call()
		var notifications := office.call("_notification_diagnostic_state") as Dictionary
		_check(
			bool(notifications.get("toast_visible", false))
			and String(notifications.get("toast_copy", "")) == String(receipt.get("copy", ""))
			and String(notifications.get("toast_priority", "")) == "action"
			and String(receipt.get("semantic", "")) in String(
				ticker.get_meta("accessible_text", ""),
			),
			"%s should publish one concise action receipt with exact semantic detail" % String(
				receipt.get("copy", "economic hold"),
			),
			failures,
		)

	_check(
		simulation.export_save_state() == before_state,
		"rejected economic filings should never mutate the authoritative save state",
		failures,
	)
	var announcement := office.call(
		"_web_accessibility_announcement",
		simulation.snapshot(),
		"",
	) as Dictionary
	_check(
		String(announcement.get("kind", "")) == "notification"
		and "Roster capacity is full" in String(announcement.get("text", "")),
		"the Web live region should receive the full current recovery reason, not only the compact receipt",
		failures,
	)

	var priority_preferences := (office.get("_player_preferences") as Dictionary).duplicate(true)
	priority_preferences["notice_level"] = "priority"
	office.set("_player_preferences", priority_preferences)
	office.call("_publish_economic_action_hold", "BUILD", "REVIEW GATE", "Complete the shell-quality milestone first.", "Facility requisition")
	var priority_notifications := office.call("_notification_diagnostic_state") as Dictionary
	_check(
		bool(priority_notifications.get("toast_visible", false))
		and String(priority_notifications.get("toast_copy", "")) == "BUILD HELD  ·  REVIEW GATE",
		"Priority notice mode should retain consequential economic failures",
		failures,
	)

	priority_preferences["notice_level"] = "archive_only"
	office.set("_player_preferences", priority_preferences)
	office.call("_publish_economic_action_hold", "PROVISIONS", "REVIEW LOT", "The selected lot no longer fits storage.", "Provisions order")
	var archive_notifications := office.call("_notification_diagnostic_state") as Dictionary
	_check(
		not bool(archive_notifications.get("toast_visible", true))
		and String(archive_notifications.get("latest_copy", ""))
		== "PROVISIONS HELD  ·  REVIEW LOT",
		"Archive Only should suppress the floor toast while preserving the bounded Shift Record",
		failures,
	)

	priority_preferences["notice_level"] = "all"
	office.set("_player_preferences", priority_preferences)
	office.call("_set_flockwatch_open", true)
	office.call("_publish_economic_action_hold", "FLOCK CASE", "REVIEW TERMS", "That case has already been resolved.", "Flock Relations case")
	var flockwatch_notifications := office.call("_notification_diagnostic_state") as Dictionary
	_check(
		not bool(flockwatch_notifications.get("toast_visible", true))
		and navigation.last_feedback() == "FLOCK CASE HELD  ·  REVIEW TERMS",
		"an open Flockwatch ledger should own presentation while retaining the compact failure in its feedback record",
		failures,
	)

	await _finish(office, failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _finish(office: Office, failures: Array[String]) -> void:
	if is_instance_valid(office):
		office.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("ECONOMIC_ACTION_HOLD_FEEDBACK_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("ECONOMIC_ACTION_HOLD_FEEDBACK_TEST_PASSED systems=10 priority=visible archive=retained flockwatch=owned authority=unchanged")
	quit(0)
