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
	office.call("_retire_action_outcome_receipts", &"strategic_hold_test", false)
	var simulation := office.get("_simulation") as DepartmentSimulation
	var ticker := office.get("_ticker_label") as Label
	_check(
		simulation != null and ticker != null,
		"Office should expose the authoritative economy and status receipt",
		failures,
	)
	if simulation == null or ticker == null:
		await _finish(office, failures)
		return

	var before_state := simulation.export_save_state()
	var expected_receipts: Array[Dictionary] = [
		{
			"invoke": func() -> void: office.call("_on_capital_blueprint_pin_requested", &"unknown"),
			"copy": "CAPITAL PLAN HELD  ·  REVIEW FACILITY",
			"semantic": "Capital plan held.",
		},
		{
			"invoke": func() -> void: office.call("_on_economic_watch_requested", &"unknown"),
			"copy": "WATCH HELD  ·  REVIEW METRIC",
			"semantic": "Management watch held.",
		},
		{
			"invoke": func() -> void: office.call("_resolve_campus_portfolio_action", {
				"accepted": false,
				"reason": "The selected parcel no longer has contractor capacity.",
			}, "strategic_hold_test", &"orchard_row"),
			"copy": "CAMPUS FILE HELD  ·  REVIEW PROJECT",
			"semantic": "Campus portfolio file held.",
		},
		{
			"invoke": func() -> void: office.call(
				"_on_campus_pod_relocate_requested",
				&"stale_socket",
				&"meadow_west",
			),
			"copy": "POD MOVE HELD  ·  REFRESH SOCKET",
			"semantic": "Egg Routing Pod move held.",
		},
		{
			"invoke": func() -> void: office.call("_resolve_campus_authorization", {
				"accepted": false,
				"reason": "Cold-chain service is not connected.",
			}, "strategic_hold_test"),
			"copy": "MEADOW FILE HELD  ·  REVIEW GATE",
			"semantic": "North Meadow filing held.",
		},
		{
			"invoke": func() -> void: office.call("_on_campaign_milestone_requested", &"unknown"),
			"copy": "MILESTONE HELD  ·  REVIEW EDGE",
			"semantic": "Probation milestone held.",
		},
		{
			"invoke": func() -> void: office.call("_on_career_sponsorship_requested", -1, &"unknown"),
			"copy": "SPONSORSHIP HELD  ·  OPEN SENIOR ROOST",
			"semantic": "Sponsorship held.",
		},
		{
			"invoke": func() -> void: office.call("_continue_senior_roost_report"),
			"copy": "SENIOR ROOST HELD  ·  RETURN REVIEW",
			"semantic": "Senior Roost held.",
		},
		{
			"invoke": func() -> void: office.call("_publish_economic_action_hold",
				"NEXT SHIFT",
				"FINISH REVIEW",
				"Finish the farmer review before filing another morning briefing.",
				"Next-shift filing"),
			"copy": "NEXT SHIFT HELD  ·  FINISH REVIEW",
			"semantic": "Next-shift filing held.",
		},
		{
			"invoke": func() -> void: office.call("_publish_economic_action_hold",
				"FARM MUTUAL",
				"CHOOSE BINDER",
				"Sign one disclosed binder or explicitly keep the standard book.",
				"Farm Mutual filing"),
			"copy": "FARM MUTUAL HELD  ·  CHOOSE BINDER",
			"semantic": "Farm Mutual filing held.",
		},
		{
			"invoke": func() -> void: office.call("_publish_economic_action_hold",
				"CONTINUE",
				"REVIEW RECOVERY",
				"No readable campaign checkpoint is available.",
				"Campaign continue"),
			"copy": "CONTINUE HELD  ·  REVIEW RECOVERY",
			"semantic": "Campaign continue held.",
		},
	]
	for receipt in expected_receipts:
		(receipt.get("invoke") as Callable).call()
		var notifications := office.call("_notification_diagnostic_state") as Dictionary
		_check(
			String(notifications.get("latest_copy", "")) == String(receipt.get("copy", ""))
			and String(notifications.get("latest_priority", "")) == "action"
			and String(receipt.get("semantic", "")) in String(
				ticker.get_meta("accessible_text", ""),
			),
			"%s should retain one concise strategic recovery receipt with exact semantic detail" % String(
				receipt.get("copy", "strategic hold"),
			),
			failures,
		)

	_check(
		simulation.export_save_state() == before_state,
		"rejected strategic filings should never mutate authoritative economic or save state",
		failures,
	)
	var announcement := office.call(
		"_web_accessibility_announcement",
		simulation.snapshot(),
		"",
	) as Dictionary
	_check(
		String(announcement.get("kind", "")) == "campaign_record"
		and "No readable campaign checkpoint" in String(announcement.get("text", "")),
		"the owning campaign record should retain the exact strategic recovery reason in the Web live region",
		failures,
	)

	# Blocking management screens own the visible compact receipt. This avoids a
	# hidden or overlapping floor toast while preserving the exact reason in the
	# screen's semantic label and browser announcement.
	office.call("_set_campaign_modal_open", false)
	office.call("_open_capital_blueprint", false, false)
	office.call(
		"_publish_economic_action_hold",
		"CAPITAL PLAN",
		"REVIEW FACILITY",
		"The facility price changed before filing. Compare the current cost and protected reserve.",
		"Capital plan",
	)
	var capital_summary := office.find_child(
		"CapitalBlueprintPlanSummary",
		true,
		false,
	) as Label
	var capital_notifications := office.call("_notification_diagnostic_state") as Dictionary
	var capital_announcement := office.call(
		"_web_accessibility_announcement",
		simulation.snapshot(),
		"",
	) as Dictionary
	_check(
		capital_summary != null
		and capital_summary.text == "CAPITAL PLAN HELD  ·  REVIEW FACILITY"
		and "price changed" in String(capital_summary.get_meta("accessible_text", ""))
		and not bool(capital_notifications.get("toast_visible", true))
		and String(capital_announcement.get("kind", "")) == "capital_plan"
		and "protected reserve" in String(capital_announcement.get("text", "")),
		"Capital Blueprint should visibly own the compact hold without losing the exact reason or overlapping floor toast",
		failures,
	)

	# Authored reasons that already begin with the semantic hold must not repeat
	# the same phrase in assistive output.
	office.call(
		"_publish_economic_action_hold",
		"CAPITAL POLICY",
		"REVIEW DOCKET",
		"Capital policy held. Review the Senior Roost docket.",
		"Capital policy",
	)
	_check(
		String(ticker.get_meta("accessible_text", ""))
		== "Capital policy held. Review the Senior Roost docket.",
		"a pre-authored hold reason should not be duplicated in semantic output",
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
			push_error("STRATEGIC_ACTION_HOLD_FEEDBACK_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("STRATEGIC_ACTION_HOLD_FEEDBACK_TEST_PASSED systems=11 authority=unchanged modal-owner=visible narration=exact duplication=prevented")
	quit(0)
