extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var closing_simulation := DepartmentSimulation.new(8141)
	closing_simulation.routing_momentum_chain = 15
	closing_simulation.best_routing_momentum_chain = 15
	var completed_reports: Array[Dictionary] = []
	closing_simulation.workday_completed.connect(func(completed_report: Dictionary) -> void:
		completed_reports.append(completed_report.duplicate(true))
	)
	closing_simulation.call("_complete_workday")
	_check(
		completed_reports.size() == 1
		and int((completed_reports[0].get("routing_momentum", {}) as Dictionary).get(
			"best_chain",
			0,
		)) == 15,
		"the authoritative closing report should file the exact routing snapshot once",
		failures,
	)
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	var simulation := office.get("_simulation") as DepartmentSimulation

	var previous_report := {
		"day": 1,
		"routing_momentum": {"best_chain": 10},
	}
	var report := {
		"day": 2,
		"routing_momentum": {
			"chain": 15,
			"best_chain": 15,
		},
	}
	var receipt := office.call(
		"_routing_review_receipt",
		report,
		previous_report,
	) as Dictionary
	_check(
		bool(receipt.get("record_set", false))
		and int(receipt.get("previous_best_chain", -1)) == 10
		and int(receipt.get("best_chain", -1)) == 15
		and int(receipt.get("next_record", -1)) == 20,
		"a completed shift should file the exact 10-to-15 record and x20 chase",
		failures,
	)
	_check(
		String(receipt.get("short_label", "")) == "NEW FIT RECORD  x15   /   CHASE  x20"
		and "15 consecutive recommended tray assignments" in String(
			receipt.get("accessible_text", "")
		),
		"the review should stay glance-first while retaining the exact semantic action",
		failures,
	)

	var repeated := office.call(
		"_routing_review_receipt",
		report,
		{"day": 1, "routing_momentum": {"best_chain": 15}},
	) as Dictionary
	_check(
		not bool(repeated.get("record_set", true))
		and String(repeated.get("short_label", "")).begins_with("BEST FIT RECORD"),
		"an unchanged record should remain visible without claiming another celebration",
		failures,
	)
	var legacy := office.call(
		"_routing_review_receipt",
		{"day": 3, "routing_momentum": {"best_chain": 15}},
		{},
	) as Dictionary
	_check(
		not bool(legacy.get("record_set", true)),
		"an upgraded legacy file should not invent a newly earned record",
		failures,
	)

	var review_report := {
		"day": 2,
		"eggs": 19,
		"quota": 16,
		"met_quota": true,
		"cracked": 0,
		"golden": 1,
		"closing_fund_cents": 7200,
		"next_quota": 18,
		"routing_review": receipt,
	}
	var decision_host := office.find_child("ManagementDecisionHost", true, false) as Control
	if decision_host != null:
		decision_host.visible = false
	office.call("_show_farmer_review", review_report, false)
	await process_frame
	var summary := office.find_child("FarmerReviewSummary", true, false) as Label
	_check(
		summary != null
		and "NEW FIT RECORD  x15" in summary.text
		and summary.text.count("\n") == 1,
		"the existing review summary should add one compact routing line and no panel",
		failures,
	)
	_check(
		summary != null
		and "15 consecutive recommended tray assignments" in String(
			summary.get_meta("accessible_text", "")
		),
		"the compact review line should expose its complete meaning accessibly",
		failures,
	)
	var review_accessible := office.call(
		"_web_accessibility_summary",
		simulation.snapshot(),
	) as String
	_check(
		"15 consecutive recommended tray assignments" in review_accessible,
		"the browser semantic mirror should carry the same authoritative review record: %s"
		% review_accessible,
		failures,
	)

	simulation.routing_momentum_chain = 15
	simulation.best_routing_momentum_chain = 15
	report["routing_review"] = receipt
	var return_recap := office.call(
		"_campaign_return_recap",
		{"simulation": simulation.export_save_state()},
		{"reason": "workday_completed", "completed_shifts": 2},
		{"last_workday_report": report},
	) as Dictionary
	_check(
		int(return_recap.get("version", 0)) == 2
		and (return_recap.get("routing_mastery", {}) as Dictionary) == receipt,
		"the verified return recap should preserve the exact filed shift receipt",
		failures,
	)
	var return_accessible := office.call(
		"_web_return_recap_summary",
		{"return_recap": return_recap},
	) as String
	_check(
		"Next mastery record: 20" in return_accessible,
		"saved-file accessibility should name one clear record for the next session",
		failures,
	)

	# Continue turns the filed result into one compact morning handoff. It is
	# presentation-only, survives blocked or invalid actions, and retires on the
	# first accepted route through the ordinary dispatch authority.
	office.call("_reset_first_clutch", false)
	office.call("_prepare_capture_running")
	office.set("_campaign_review_stage", &"active")
	office.call("_set_campaign_modal_open", false)
	if decision_host != null:
		decision_host.visible = false
	var day_review := office.find_child("DayReviewScrim", true, false) as Control
	if day_review != null:
		day_review.visible = false
	var routing_ui := office.get("_routing_ui") as Control
	if routing_ui != null:
		routing_ui.visible = true
		routing_ui.call("set_interaction_enabled", true)
	var simulation_before_cue := simulation.export_save_state()
	_check(
		bool(office.call("_arm_routing_return_cue", return_recap)),
		"the verified mastery recap should arm one re-entry cue",
		failures,
	)
	office.call("_update_guidance", simulation.snapshot())
	var cue := office.call("_routing_return_cue_diagnostic_state") as Dictionary
	var guidance := office.get("_guidance_label") as Label
	_check(
		bool(cue.get("active", false))
		and bool(cue.get("visible", false))
		and int(cue.get("best_chain", 0)) == 15
		and int(cue.get("next_record", 0)) == 20
		and String(cue.get("source", "")) == "verified_return_recap",
		"ordinary morning play should expose the exact verified x15-to-x20 cue",
		failures,
	)
	_check(
		guidance != null
		and guidance.text == "ROUTING RECORD  x15  /  CHASE  x20"
		and "focus the most urgent intake tray" in String(guidance.get_meta("accessible_text", ""))
		and "you still choose the best-fit hen" in String(guidance.get_meta("accessible_text", "")),
		"the re-entry reminder should stay glance-first while preserving semantic instructions",
		failures,
	)
	_check(
		simulation.export_save_state() == simulation_before_cue,
		"arming presentation guidance must not mutate authoritative save data",
		failures,
	)
	_check(
		not bool(office.call("_commit_dispatch", -1))
		and bool((office.call("_routing_return_cue_diagnostic_state") as Dictionary).get(
			"active",
			false,
		)),
		"an invalid routing attempt must not consume the one-shot cue",
		failures,
	)
	var waiting_snapshot := simulation.snapshot().duplicate(true)
	waiting_snapshot["shift_phase"] = DepartmentSimulation.ShiftPhase.RUNNING
	waiting_snapshot["claim_queue_counts"] = {
		&"nest_damage": 0,
		&"predator_loss": 0,
		&"appeals": 0,
	}
	waiting_snapshot["claim_queue_overdue_counts"] = {
		&"nest_damage": 0,
		&"predator_loss": 0,
		&"appeals": 0,
	}
	waiting_snapshot["claim_queue_items"] = {
		&"nest_damage": [],
		&"predator_loss": [],
		&"appeals": [],
	}
	var waiting_routing := (waiting_snapshot.get("routing", {}) as Dictionary).duplicate(true)
	waiting_routing["queue_counts"] = waiting_snapshot["claim_queue_counts"]
	waiting_routing["overdue_by_lane"] = waiting_snapshot["claim_queue_overdue_counts"]
	waiting_snapshot["routing"] = waiting_routing
	routing_ui.call("apply_snapshot", waiting_snapshot)
	var waiting_target := routing_ui.call("focus_priority_dispatch_tray") as Control
	var waiting_focus := routing_ui.call("return_cue_focus_state") as Dictionary
	_check(
		waiting_target != null
		and waiting_target.name == "PeckworkQueueStrip"
		and bool(waiting_focus.get("fallback", false))
		and String(waiting_focus.get("reason", "")) == "waiting_for_intake",
		"an empty restored queue should focus the truthful intake fallback without enabling a tray",
		failures,
	)
	var priority_snapshot := simulation.snapshot().duplicate(true)
	priority_snapshot["shift_phase"] = DepartmentSimulation.ShiftPhase.RUNNING
	priority_snapshot["claim_queue_counts"] = {
		&"nest_damage": 2,
		&"predator_loss": 3,
		&"appeals": 1,
	}
	priority_snapshot["claim_queue_overdue_counts"] = {
		&"nest_damage": 0,
		&"predator_loss": 0,
		&"appeals": 1,
	}
	priority_snapshot["claim_queue_items"] = {
		&"nest_damage": [
			{"minutes_until_deadline": 180, "market_contract_rush": false},
			{"minutes_until_deadline": 220, "market_contract_rush": false},
		],
		&"predator_loss": [
			{"minutes_until_deadline": 90, "market_contract_rush": true},
			{"minutes_until_deadline": 120, "market_contract_rush": false},
			{"minutes_until_deadline": 150, "market_contract_rush": false},
		],
		&"appeals": [
			{"minutes_until_deadline": -15, "overdue": true, "market_contract_rush": true},
		],
	}
	var priority_routing := (priority_snapshot.get("routing", {}) as Dictionary).duplicate(true)
	priority_routing["queue_counts"] = priority_snapshot["claim_queue_counts"]
	priority_routing["overdue_by_lane"] = priority_snapshot["claim_queue_overdue_counts"]
	priority_snapshot["routing"] = priority_routing
	routing_ui.call("apply_snapshot", priority_snapshot)
	office.call("_on_guidance_action_pressed")
	await process_frame
	var focus_owner := root.get_viewport().gui_get_focus_owner()
	var focused_cue := office.call("_routing_return_cue_diagnostic_state") as Dictionary
	var focus_receipt := focused_cue.get("focus", {}) as Dictionary
	_check(
		focus_owner != null
		and focus_owner.name == "DispatchTray_appeals"
		and String(focus_receipt.get("lane", "")) == "appeals"
		and String(focus_receipt.get("reason", "")) == "overdue"
		and int(focus_receipt.get("minutes_until_deadline", 0)) == -15
		and not bool(focus_receipt.get("fallback", true)),
		"activating the cue should focus the most urgent live intake tray without filing a route",
		failures,
	)
	_check(
		bool(focused_cue.get("active", false))
		and simulation.export_save_state() == simulation_before_cue,
		"priority focus alone should leave the cue armed and authoritative save data untouched",
		failures,
	)
	office.call("_on_dispatch_lane_requested", &"appeals")
	var route_worker_id := int(office.get("_dispatch_recommended_worker_id"))
	if (
		route_worker_id >= 0
		and simulation.workers[route_worker_id].assigned_lane == &"appeals"
	):
		simulation.set_worker_assignment(route_worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
	_check(
		route_worker_id >= 0 and bool(office.call("_commit_dispatch", route_worker_id)),
		"the focused tray should still flow through the real accepted dispatch path",
		failures,
	)
	var cleared_cue := office.call("_routing_return_cue_diagnostic_state") as Dictionary
	var dismissal := cleared_cue.get("dismissal", {}) as Dictionary
	_check(
		not bool(cleared_cue.get("active", true))
		and String(dismissal.get("reason", "")) == "first_accepted_route"
		and int(dismissal.get("worker_id", -1)) == route_worker_id
		and String(dismissal.get("lane", "")) == "appeals"
		and String(dismissal.get("focus_target_lane", "")) == "appeals"
		and String(dismissal.get("focus_reason", "")) == "overdue",
		"the first accepted route should retire the cue exactly once with an auditable receipt",
		failures,
	)
	_check(
		guidance != null and "CHASE  x20" not in guidance.text,
		"normal contextual guidance should replace the chase immediately after routing",
		failures,
	)
	_check(
		not bool(office.call("_arm_routing_return_cue", {
			"routing_mastery": {
				"best_chain": 9,
				"next_record": 10,
				"target_kind": "team_lift",
			},
		})),
		"pre-mastery files should not gain a persistent return chase",
		failures,
	)
	_check(
		bool(office.call("_arm_routing_return_cue", return_recap)),
		"the saved recap should remain eligible on a later genuine app return",
		failures,
	)
	_check(
		((office.call("_routing_return_cue_diagnostic_state") as Dictionary).get(
			"focus",
			{},
		) as Dictionary).is_empty(),
		"a later genuine return should begin with a fresh focus receipt",
		failures,
	)
	office.call("_reset_campaign_session_visuals")
	_check(
		not bool((office.call("_routing_return_cue_diagnostic_state") as Dictionary).get(
			"active",
			true,
		)),
		"starting or restoring another session should clear any stale transient cue",
		failures,
	)

	office.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("ROUTING_SESSION_RECAP_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("ROUTING_SESSION_RECAP_TEST_PASSED review=x15 return=x20 cue=single_route legacy=quiet semantic=exact")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
