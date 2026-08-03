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
	var clock := office.get("_clock") as SimulationClock
	var quota_progress := office.find_child("ShiftQuotaProgress", true, false) as ProgressBar
	var review_panel := office.find_child("DayReviewPanel", true, false) as PanelContainer
	var review_glance := office.find_child("FarmerReviewGlanceGrid", true, false) as GridContainer
	var review_summary := office.find_child("FarmerReviewSummary", true, false) as Label
	var review_eggs := office.find_child("FarmerReviewEggsValue", true, false) as Label
	var review_net := office.find_child("FarmerReviewNetValue", true, false) as Label
	var review_fund := office.find_child("FarmerReviewFundValue", true, false) as Label
	var review_next := office.find_child("FarmerReviewNextValue", true, false) as Label
	var review_details_toggle := office.find_child("FarmerReviewDetailsToggle", true, false) as Button
	var review_details_scroll := office.find_child("FarmerReviewAccountingScroll", true, false) as ScrollContainer
	var review_results := office.find_child("FarmerReviewAccountingDetails", true, false) as Label
	var review_continue := office.find_child("BeginNextShiftButton", true, false) as Button
	var decision_host := office.find_child("ManagementDecisionHost", true, false) as Control
	var flockwatch_toggle := office.find_child("FlockwatchToggle", true, false) as Button
	var guidance := office.get("_guidance_label") as Label
	var guidance_icon := office.find_child("GuidanceIcon", true, false) as Control
	var guidance_action := office.find_child("GuidanceActionButton", true, false) as Button
	_check(clock != null and clock.speed_index == 0, "first shift should begin paused for its morning directive", failures)
	_check(decision_host != null and decision_host.is_visible_in_tree(), "opening directive should be presented as a blocking decision", failures)
	_check(
		guidance != null
		and guidance_icon != null
		and guidance_action != null
		and not guidance_action.disabled
		and StringName(guidance_action.get_meta("guidance_action_id", &"")) == &"decision"
		and guidance.text == "DECIDE: CHOOSE + AUTHORIZE ONE POLICY"
		and guidance.text.length() <= 40
		and "select a policy card" in String(guidance.get_meta("accessible_text", "")).to_lower()
		and guidance.tooltip_text == String(guidance.get_meta("accessible_text", ""))
		and guidance_icon.tooltip_text == guidance.tooltip_text,
		"the HUD should expose one compact next action with the exact explanation available semantically",
		failures,
	)
	if guidance_action != null:
		guidance_action.pressed.emit()
	await process_frame
	var guided_focus := root.get_viewport().gui_get_focus_owner()
	_check(
		guided_focus != null and guided_focus.name.begins_with("DecisionOption_"),
		"activating the next-move cue should focus the first safe policy action without authorizing it",
		failures,
	)
	var assurance_option := office.find_child("DecisionOption_shell_assurance", true, false) as Button
	var assurance_chip_row := office.find_child("DecisionEffectChips_shell_assurance", true, false) as HBoxContainer
	var confirm_decision := office.find_child("ConfirmDecisionButton", true, false) as Button
	var decision_body := office.find_child("DecisionBody", true, false) as Label
	var decision_order_glance := office.find_child("DecisionOrderGlance", true, false) as GridContainer
	var opening_order := office.find_child("DecisionOrderValue_0", true, false) as Label
	var quality_order := office.find_child("DecisionOrderValue_1", true, false) as Label
	var welfare_order := office.find_child("DecisionOrderValue_2", true, false) as Label
	_check(assurance_option != null and confirm_decision != null, "directive modal should expose selectable policy cards and authorization", failures)
	_check(
		assurance_chip_row != null
		and assurance_chip_row.get_child_count() == 3
		and office.find_child("DecisionEffectChip_shell_assurance_pace", true, false) != null
		and office.find_child("DecisionEffectChip_shell_assurance_risk", true, false) != null
		and office.find_child("DecisionEffectChip_shell_assurance_compliance", true, false) != null,
		"the Assurance card should preview pace, shell risk, and rules with three icon-led chips",
		failures,
	)
	_check(
		decision_body != null
		and decision_body.text == "Choose one rule for the whole flock."
		and decision_order_glance != null
		and decision_order_glance.is_visible_in_tree()
		and opening_order != null
		and opening_order.text == "18+ EGGS"
		and quality_order != null
		and quality_order.text == "CRACKS <=20%"
		and welfare_order != null
		and welfare_order.text == "WELFARE 48+",
		"morning policy should show three glance-first scored order tiles before authorization",
		failures,
	)
	if assurance_option != null and confirm_decision != null:
		assurance_option.pressed.emit()
		_check(not confirm_decision.disabled, "selecting a directive should enable authorization", failures)
		confirm_decision.pressed.emit()
	await process_frame
	_check(not decision_host.is_visible_in_tree(), "authorizing a directive should close the decision modal", failures)
	_check(StringName(simulation.active_directive_snapshot().get("id", &"")) == &"shell_assurance", "authorized directive should become authoritative", failures)
	_check(clock.speed_index == 1, "authorizing the morning directive should start the shift", failures)
	var outcome_receipt := office.get("_latest_action_outcome_receipt") as Dictionary
	var outcome_ids: Array[StringName] = []
	var outcome_copy: Array[String] = []
	for entry_value in outcome_receipt.get("entries", []):
		outcome_ids.append(StringName((entry_value as Dictionary).get("id", &"")))
		outcome_copy.append(String((entry_value as Dictionary).get("copy", "")))
	_check(
		bool(outcome_receipt.get("visible", false))
		and &"pace" in outcome_ids
		and &"risk" in outcome_ids
		and &"compliance" in outcome_ids
		and outcome_copy == ["PACE -7%", "RISK -5%", "RULES +3"]
		and not office.find_children("ActionOutcomeReceipt_*", "PanelContainer", true, false).is_empty(),
		"authorizing a policy should immediately show authoritative production, shell-risk, and compliance consequence receipts [receipt=%s nodes=%d]" % [
			str(outcome_receipt),
			office.find_children("ActionOutcomeReceipt_*", "PanelContainer", true, false).size(),
		],
		failures,
	)
	var save_before_receipt_handoff := simulation.export_save_state()
	var audio_feedback = office.get("_audio_feedback")
	var audio_serial_before_handoff := int(audio_feedback.feedback_snapshot().get(
		"cue_serial",
		-1,
	))
	office.call("_set_flockwatch_open", true)
	await process_frame
	await process_frame
	var archived_outcome_receipt := office.get("_latest_action_outcome_receipt") as Dictionary
	_check(
		not bool(archived_outcome_receipt.get("visible", true))
		and String(archived_outcome_receipt.get("dismissed_by", "")) == "flockwatch"
		and int(archived_outcome_receipt.get("retired_panel_count", -1)) == 3
		and (archived_outcome_receipt.get("entries", []) as Array).size() == 3
		and office.find_children("ActionOutcomeReceipt_*", "PanelContainer", true, false).is_empty(),
		"opening the ledger should archive the semantic result and retire every overlapping transient card",
		failures,
	)
	_check(
		simulation.export_save_state() == save_before_receipt_handoff
		and int(audio_feedback.feedback_snapshot().get("cue_serial", -2)) == audio_serial_before_handoff,
		"the receipt-to-ledger handoff should remain save-neutral and silent",
		failures,
	)
	office.call("_set_flockwatch_open", false)
	await process_frame
	var money_before := simulation.snapshot()
	var money_after := money_before.duplicate(true)
	money_after["revenue_cents"] = int(money_before.get("revenue_cents", 0)) - 700
	var money_entries := office.call(
		"_decision_consequence_entries",
		money_before,
		money_after,
	) as Array
	_check(
		not money_entries.is_empty()
		and StringName((money_entries[0] as Dictionary).get("id", &"")) == &"fund"
		and String((money_entries[0] as Dictionary).get("copy", "")) == "FUND -$7.00",
		"a funded choice should map its exact Feed Fund delta to the money receipt family",
		failures,
	)
	clock.set_speed(0)
	await process_frame
	var ticker_panel := office.get("_ticker_panel") as PanelContainer
	var status_history := office.get("_status_history") as Array[String]
	_check(
		guidance != null
		and guidance_action != null
		and guidance.text == "NEXT: OPEN TODAY'S GOALS"
		and guidance.text.length() <= 40
		and StringName(guidance_action.get_meta("guidance_action_id", &"")) == &"today"
		and "open today's goals" in String(guidance.get_meta("accessible_text", "")).to_lower(),
		"pausing should replace prose with a short state-aware next move",
		failures,
	)
	_check(
		ticker_panel != null
		and not ticker_panel.visible
		and not status_history.is_empty()
		and "SHIFT PAUSED" in status_history[0],
		"the always-visible pause controls should suppress the duplicate floor toast while preserving its Shift Record entry",
		failures,
	)
	var paused_accessibility := String(
		office.call("_web_accessibility_summary", simulation.snapshot())
	)
	_check(
		"While paused, open today's goals to choose the most useful intervention." in paused_accessibility,
		"assistive narration should retain the exact next-move explanation hidden from the compact HUD",
		failures,
	)
	if guidance_action != null:
		guidance_action.pressed.emit()
	await process_frame
	var flockwatch_panel := office.find_child("FlockwatchLedger", true, false) as PanelContainer
	var flockwatch_navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	var latest_feedback := office.find_child("FlockwatchLatestFeedbackCopy", true, false) as Label
	_check(
		flockwatch_panel != null
		and flockwatch_panel.is_visible_in_tree()
		and flockwatch_navigation != null
		and flockwatch_navigation.current_page_id() == FlockwatchNavigation.PAGE_TODAY,
		"activating the paused next-move cue should open Today's Goals directly",
		failures,
	)
	_check(
		latest_feedback != null
		and latest_feedback.text == "LATEST NOTICE  /  PAUSED  ·  TIME SAFE"
		and "SHIFT PAUSED" in latest_feedback.tooltip_text,
		"Today's visible archive glance should compact the routine pause echo while preserving the exact notice semantically",
		failures,
	)
	office.call("_set_flockwatch_open", false)
	await process_frame
	var campaign_objectives := office.find_child("CampaignObjectivesLabel", true, false) as Label
	var badge_order_progress := office.find_child("ProbationOrderProgressLabel", true, false) as Label
	_check(
		campaign_objectives != null
		and badge_order_progress != null
		and badge_order_progress.is_visible_in_tree()
		and badge_order_progress.text == "ON TRACK  %d / %d" % [
			int(campaign_objectives.get_meta("orders_on_track", -1)),
			int(campaign_objectives.get_meta("orders_total", -1)),
		],
		"the always-visible badge should mirror the same authoritative live orders as Flockwatch",
		failures,
	)
	_check(quota_progress != null and int(quota_progress.max_value) == 16 and int(quota_progress.value) == 0, "top HUD should scale the opening objective to four active hens", failures)
	_check(office.find_children("Upgrade_*", "Button", true, false).size() == 3, "Flockwatch should expose three upgrade paths", failures)
	var requisitions_toggle := office.find_child("DeskRequisitionsToggle", true, false) as Button
	var shift_help_toggle := office.find_child("OperationsShiftHelpToggle", true, false) as Button
	var shift_help := office.find_child("OperationsShiftHelp", true, false) as Label
	var records_summary := office.find_child("FlockwatchRecordsArchiveSummary", true, false) as Label
	_check(
		requisitions_toggle != null
		and requisitions_toggle.focus_mode == Control.FOCUS_ALL
		and "FILES" in requisitions_toggle.text
		and "DESK REQUISITIONS" not in requisitions_toggle.text
		and "COMPLETE" not in requisitions_toggle.text
		and _contains_all(
			requisitions_toggle.tooltip_text,
			["desk requisitions", "3 total", "ready", "complete"],
		)
		and _contains_all(
			String(requisitions_toggle.get_meta("accessible_text", "")),
			["files", "collapsed", "3 total", "ready", "complete"],
		),
		"Capital should show a concise keyboard-focusable filing action while preserving exact counts in tooltip and accessibility copy",
		failures,
	)
	_check(
		shift_help_toggle != null
		and shift_help_toggle.focus_mode == Control.FOCUS_ALL
		and shift_help != null
		and not shift_help.visible,
		"Operations help should begin as a concise optional row instead of permanent menu copy",
		failures,
	)
	_check(
		records_summary != null
		and "FARM MUTUAL" in records_summary.text
		and "FLOCK LABOR" in records_summary.text
		and "RECEIPTS" in records_summary.text,
		"Records should provide a useful compact archive instead of an empty page",
		failures,
	)
	_check(
		flockwatch_toggle != null
		and "FLOCKWATCH" in flockwatch_toggle.text
		and "4 of 4" in flockwatch_toggle.tooltip_text,
		"collapsed ledger should keep its stable identity and narrate active roost capacity",
		failures,
	)
	_check(review_panel != null and not review_panel.is_visible_in_tree(), "daily review should remain hidden during a shift", failures)

	var protected_fund := simulation.current_daily_operating_cost_cents() + simulation.wage_arrears_cents
	var opening_fund := simulation.revenue_cents
	_check(not simulation.purchase_upgrade(&"peckwork_tools"), "operating reserves should block an underfunded keycap requisition", failures)
	_check(simulation.revenue_cents == opening_fund, "a reserve-protected requisition rejection should be atomic", failures)
	simulation.revenue_cents += 500
	_check(simulation.purchase_upgrade(&"peckwork_tools"), "five additional Feed Fund dollars should make one keycap level affordable", failures)
	_check(simulation.revenue_cents == protected_fund, "the exact-price keycap requisition should retain the full operating reserve", failures)
	await process_frame
	var first_keycaps := office.find_children("RequisitionKeycap_0", "MeshInstance3D", true, false)
	_check(first_keycaps.size() == 6, "each workstation should contain a keycap upgrade indicator", failures)
	for keycap in first_keycaps:
		_check((keycap as MeshInstance3D).visible, "purchased keycap level should be visible at every desk", failures)

	simulation.eggs_today = simulation.quota_target
	simulation.cracked_today = 0
	simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	for _step in 3:
		simulation.advance_tick()
		_resolve_pending_incident(simulation)
		clock.set_speed(0)
	await process_frame
	_check(review_panel.is_visible_in_tree(), "shift completion should open the farmer review", failures)
	_check(clock.speed_index == 0, "farmer review should pause the next shift", failures)
	_check(
		review_summary != null
		and review_summary.is_visible_in_tree()
		and "CLEAN SHELLS" in review_summary.text
		and review_eggs != null
		and "16 / 16" in review_eggs.text
		and review_net != null
		and "$" in review_net.text
		and (
			review_net.text.begins_with("+")
			or review_net.text.begins_with("-")
		)
		and review_fund != null
		and review_fund.text.begins_with("$")
		and review_next != null
		and review_next.text.is_valid_int()
		and int(review_next.text) > 0,
		(
			"Farmer Review should lead with four glance-first result tiles and one quality line "
			+ "[quality=%s eggs=%s net=%s fund=%s next=%s]"
		) % [
			review_summary.text if review_summary != null else "<missing>",
			review_eggs.text if review_eggs != null else "<missing>",
			review_net.text if review_net != null else "<missing>",
			review_fund.text if review_fund != null else "<missing>",
			review_next.text if review_next != null else "<missing>",
		],
		failures,
	)
	_check(
		review_details_toggle != null
		and review_details_toggle.is_visible_in_tree()
		and review_details_toggle.text == "DETAILS"
		and review_details_scroll != null
		and not review_details_scroll.visible,
		"the full accounting ledger should begin behind an explicit disclosure",
		failures,
	)
	var review_accessibility := String(
		office.call("_web_accessibility_summary", simulation.snapshot())
	)
	_check(
		"Eggs versus target:" in review_accessibility
		and "Net:" in review_accessibility
		and "Feed Fund:" in review_accessibility
		and "Next target:" in review_accessibility
		and "Accounting details:" in review_accessibility
		and "Payroll" in review_accessibility
		and "Closing Feed Fund" in review_accessibility,
		"assistive review narration should combine every glance tile with the complete accounting ledger",
		failures,
	)
	if review_panel != null:
		_check(
			review_panel.size.y <= 432.0,
			"the default result card should release the unused accounting-ledger height",
			failures,
		)
	if review_details_toggle != null:
		review_details_toggle.pressed.emit()
	await process_frame
	_check(
		review_details_scroll != null
		and review_details_scroll.is_visible_in_tree()
		and review_details_toggle.text == "HIDE DETAILS",
		"the accounting disclosure should reveal a bounded scrolling detail region",
		failures,
	)
	_check(
		review_results != null
		and review_results.is_visible_in_tree()
		and "TARGET HARVESTED" in review_results.text
		and "Quality bonus" in review_results.text
		and "Payroll" in review_results.text
		and "Facilities" in review_results.text
		and "Net operating" in review_results.text
		and "Closing Feed Fund" in review_results.text,
		"review should reconcile rewards, obligations, net operations, and closing cash",
		failures,
	)
	if review_panel != null:
		var review_rect := review_panel.get_global_rect()
		_check(
			review_rect.position.y >= 0.0 and review_rect.end.y <= 720.0,
			"the expanded Farmer Review should remain inside the authored 720p stage",
			failures,
		)
	if review_details_toggle != null:
		review_details_toggle.pressed.emit()
	var scaled_preferences := (
		office.get("_player_preferences") as Dictionary
	).duplicate(true)
	scaled_preferences["ui_scale"] = 1.5
	office.set("_player_preferences", scaled_preferences)
	office.call("_apply_management_ui_preferences")
	await process_frame
	await process_frame
	if review_panel != null and review_continue != null:
		var scaled_review_rect := review_panel.get_global_rect()
		var continue_rect := review_continue.get_global_rect()
		_check(
			review_panel.size.y <= 482.0
			and scaled_review_rect.position.y >= 0.0
			and scaled_review_rect.end.y <= 720.0
			and continue_rect.position.y >= scaled_review_rect.position.y
			and continue_rect.end.y <= scaled_review_rect.end.y,
			"the compact result card and Continue action should remain contained at 150 percent scale",
			failures,
		)
	_check(
		review_glance != null
		and review_glance.columns == 4
		and review_glance.get_child_count() == 4,
		"the 150 percent result card should preserve its four-tile visual scan",
		failures,
	)
	# Let the short upgrade/review cues naturally retire before tearing down the
	# entire office; the dummy headless audio driver otherwise reports them as
	# live playback resources during process shutdown.
	await create_timer(0.4).timeout
	office.free()
	await process_frame

	if not failures.is_empty():
		for failure in failures:
			push_error("MANAGEMENT_LOOP_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MANAGEMENT_LOOP_UI_TEST_PASSED objective=visible upgrades=physical review=paused")
	quit(0)


func _resolve_pending_incident(simulation: DepartmentSimulation) -> void:
	var pending := simulation.pending_decision_snapshot()
	if StringName(pending.get("kind", &"")) != &"incident":
		return
	var serial := int(pending.get("serial", -1))
	for option_value in pending.get("options", []):
		var option := option_value as Dictionary
		if int(option.get("cost_cents", 0)) == 0:
			simulation.resolve_decision(serial, StringName(option.get("id", &"")))
			return


func _contains_all(copy: String, needles: Array[String]) -> bool:
	var normalized := copy.to_lower()
	for needle: String in needles:
		if needle.to_lower() not in normalized:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
