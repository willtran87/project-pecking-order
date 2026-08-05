extends SceneTree

const ProbationCampaignUIScript := preload("res://features/office/probation_campaign_ui.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observed := {"chosen": &"", "continued": 0, "presentation_changes": 0}
	var harness := Control.new()
	harness.name = "SeniorRoostUITestHarness"
	harness.size = Vector2(1280.0, 720.0)
	root.add_child(harness)
	var ui = ProbationCampaignUIScript.new()
	harness.add_child(ui)
	ui.milestone_choice.connect(func(choice_id: StringName) -> void: observed["chosen"] = choice_id)
	ui.continue_campaign.connect(func() -> void: observed["continued"] = int(observed["continued"]) + 1)
	ui.presentation_state_changed.connect(
		func() -> void:
			observed["presentation_changes"] = int(observed["presentation_changes"]) + 1
	)
	await process_frame

	ui.show_between_shift_report(_quarter_policy_snapshot())
	await process_frame
	await process_frame
	var report := ui.find_child("ProbationReportPanel", true, false) as PanelContainer
	var kicker := ui.find_child("ProbationReportDay", true, false) as Label
	var heading := ui.find_child("ProbationReportTitle", true, false) as Label
	var heading_stack := heading.get_parent() as VBoxContainer if heading != null else null
	var rank_label := ui.find_child("ReportRank", true, false) as Label
	var rank_icon := ui.find_child("ReportRankIcon", true, false) as TextureRect
	var rank_progress := ui.find_child("ReportRankProgress", true, false) as ProgressBar
	var live_order_promotion_icon := ui.find_child("ProbationOrderPromotionIcon", true, false) as TextureRect
	var secondary_caption := ui.find_child("ReportShiftDeltaCaption", true, false) as Label
	var secondary_icon := ui.find_child("ReportShiftDeltaIcon", true, false) as TextureRect
	var secondary_value := ui.find_child("ReportShiftDelta", true, false) as Label
	var score_value := ui.find_child("ReportScore", true, false) as Label
	var score_row := ui.find_child("ProbationReportScoreRow", true, false) as HFlowContainer
	var secondary_panel := (
		secondary_value.get_parent().get_parent().get_parent() as PanelContainer
		if secondary_value != null else
		null
	)
	var score_panel := (
		score_value.get_parent().get_parent().get_parent() as PanelContainer
		if score_value != null else
		null
	)
	var day_badge := ui.find_child("ProbationDayBadge", true, false) as PanelContainer
	var ledger_title := ui.find_child("ReportLedgerSectionTitle", true, false) as Label
	var first_ledger_line := ui.find_child("ReportLedgerMetricLine1", true, false) as HBoxContainer
	var first_ledger_value := ui.find_child("ReportLedgerValue1", true, false) as Label
	var choice_title := ui.find_child("MilestoneChoiceSectionTitle", true, false) as Label
	var edge_legend := ui.find_child("MilestoneEdgeLegend", true, false) as Label
	var watch_legend := ui.find_child("MilestoneWatchLegend", true, false) as Label
	var board_legend := ui.find_child("MilestoneBoardLegend", true, false) as Label
	var continue_button := ui.find_child("ContinueProbationButton", true, false) as Button
	var requisitions_button := ui.find_child("ReviewRoostRequisitionsButton", true, false) as Button
	var shelve_button := ui.find_child("AbandonCampaignButton", true, false) as Button
	var merit := ui.find_child("MilestoneChoice_merit_grants", true, false) as Button
	var dividend := ui.find_child("MilestoneChoice_flock_dividend", true, false) as Button
	var forecast := ui.find_child("MilestoneChoice_harvest_forecast", true, false) as Button
	var board_strip := ui.find_child("BoardTargetStrip", true, false) as HFlowContainer
	var clutch_tile := ui.find_child("BoardTarget_quota_met_shifts", true, false) as PanelContainer
	var payroll_tile := ui.find_child("BoardTarget_wage_arrears_shifts", true, false) as PanelContainer
	var clutch_rail := clutch_tile.find_child("BoardTargetProgress", true, false) as ProgressBar if clutch_tile != null else null
	var payroll_rail := payroll_tile.find_child("BoardTargetProgress", true, false) as ProgressBar if payroll_tile != null else null
	var objective_progress := ui.find_child("NextShiftObjectiveProgress", true, false) as Label
	var objective_reward_badge := ui.find_child("NextShiftObjectiveRewardBadge", true, false) as PanelContainer
	var objective_promotion_icon := ui.find_child("NextShiftObjectivePromotionIcon", true, false) as TextureRect
	var objective_card := ui.find_child("NextShiftObjectiveCard", true, false) as PanelContainer
	_check(report != null and report.is_visible_in_tree(), "Senior policy filing should reuse the full report surface", failures)
	_check(report != null and report.custom_minimum_size.x == 960.0, "desktop Senior reports should use the tighter 960px decision width", failures)
	_check(heading_stack != null and heading_stack.custom_minimum_size.x == 340.0, "the desktop report heading should release legacy width while preserving a stable metric row", failures)
	_check(
		rank_label != null and rank_label.get_line_count() == 1,
		"the tighter desktop header should keep the Senior career title on one line",
		failures,
	)
	_check(
		rank_icon != null and rank_icon.is_visible_in_tree()
		and rank_icon.texture != null
		and String(rank_icon.get_meta("semantic_icon", "")) == "rank_crest"
		and rank_label.tooltip_text == "CAREER TITLE  //  SENIOR CLAIMS ROOSTER",
		"the Senior title should pair its exact accessible copy with one rank crest",
		failures,
	)
	_check(
		not bool(rank_icon.get_meta("promotion_stamp", true))
		and String(rank_icon.get_meta("promotion_stamp_motion", "")) == "skipped",
		"Senior career titles should not inherit probation promotion stamps",
		failures,
	)
	_check(
		rank_progress != null and not rank_progress.is_visible_in_tree()
		and not bool(rank_progress.get_meta("threshold_backed", true)),
		"Senior career titles should not inherit the probation score ladder",
		failures,
	)
	_check(
		live_order_promotion_icon != null and not live_order_promotion_icon.visible,
		"Senior reports should not inherit the live probation promotion crest",
		failures,
	)
	_check(
		objective_promotion_icon != null and not objective_promotion_icon.visible
		and not bool(objective_reward_badge.get_meta("promotion_opportunity", true)),
		"Senior policy rewards should not inherit probation promotion opportunities",
		failures,
	)
	_check(
		kicker != null and kicker.visible
		and "YEAR 1" in kicker.text and "QUARTER 1" in kicker.text
		and not bool(kicker.get_meta("merged_into_result_heading", true)),
		"Senior report should retain its separate career-calendar orientation",
		failures,
	)
	_check(
		heading != null and heading.text == "QUARTER 1 CAPITAL FILING"
		and not bool(heading.get_meta("compact_result_heading", true))
		and String(heading.get_meta("authored_report_heading", "")) == "QUARTER 1 CAPITAL FILING",
		"Senior report heading should remain authored by its snapshot",
		failures,
	)
	_check(
		secondary_caption != null and secondary_caption.text == "QUARTER SHIFTS"
		and secondary_icon != null and not secondary_icon.visible
		and secondary_panel != null
		and not bool(secondary_panel.get_meta("compact_delta_caption", true))
		and String(secondary_panel.get_meta("authored_metric_caption", "")) == "QUARTER SHIFTS",
		"Senior reports should retain their authored calendar metric without a probation delta badge",
		failures,
	)
	_check(
		score_row != null and not bool(score_row.get_meta("receipt_equation", true))
		and String(score_row.get_meta("visual_flow", "")) == "primary_to_secondary"
		and score_row.get_child(1) == score_panel
		and score_row.get_child(2) == secondary_panel,
		"Senior reports should preserve their authored primary-to-calendar metric hierarchy",
		failures,
	)
	_check(day_badge != null and not day_badge.is_visible_in_tree() and bool(day_badge.get_meta("suppressed_by_report", false)), "a foreground Senior report should suppress the duplicate background calendar badge", failures)
	_check(ledger_title != null and ledger_title.text == "SENIOR CAREER RECORD", "Senior report should name the career record without probation copy or accounting jargon", failures)
	_check(first_ledger_line != null and first_ledger_value != null and first_ledger_line.get_child(0) == first_ledger_value, "Senior career cards should share the value-first report hierarchy", failures)
	_check(choice_title != null and "CAPITAL POLICY" in choice_title.text, "quarter gate should explain the decision class", failures)
	_check(
		edge_legend != null and edge_legend.text == "+ HELP"
		and watch_legend != null and watch_legend.text == "! RISK"
		and board_legend != null and board_legend.is_visible_in_tree()
		and board_legend.text == "B BOARD",
		"Senior policy filing should decode benefit, risk, and Board-fit symbols in the section header",
		failures,
	)
	_check(board_strip != null and board_strip.is_visible_in_tree() and board_strip.get_child_count() == 3, "Senior reports should render the annual Board as three stable target tiles", failures)
	_check(clutch_tile != null and String(clutch_tile.get_meta("status", "")) == "needs_action" and payroll_tile != null and String(payroll_tile.get_meta("status", "")) == "met", "Board target state should remain semantic when color is unavailable", failures)
	_check(clutch_rail != null and clutch_rail.value == 0.0 and not clutch_rail.show_percentage, "an untouched minimum Board target should render an empty glance rail without duplicate text", failures)
	_check(payroll_rail != null and payroll_rail.value == 10_000.0 and String(payroll_rail.get_meta("comparison", "")) == "maximum", "a satisfied maximum Board target should invert correctly into a full glance rail", failures)
	_check(objective_progress != null and objective_progress.is_visible_in_tree() and objective_progress.text == "BOARD 1 / 3 MET  //  2 NEED ACTION  //  YEAR 0 / 12", "Senior reports should reduce annual Board progress to one scan-first summary", failures)
	_check(objective_reward_badge != null and not objective_reward_badge.is_visible_in_tree(), "probation score badges should not displace Senior Board progress", failures)
	_check(objective_card != null and objective_card.tooltip_text.contains("LARGEST RECOVERABLE BLOCKER"), "the compact Board strip should retain the exact annual ledger in progressive detail", failures)
	_check(_visible_text(ui).find("probation") == -1, "visible Senior UI must not leak probation wording", failures)
	_check(merit != null and merit.disabled and "$2.00 more" in merit.tooltip_text, "unaffordable policies should be visibly disabled with an exact reserve explanation", failures)
	_check(dividend != null and dividend.disabled, "every underfunded policy should remain non-interactive", failures)
	_check(forecast != null and not forecast.disabled and forecast.focus_mode == Control.FOCUS_ALL, "the no-cost fallback should remain keyboard accessible", failures)
	_check(
		dividend != null
		and "+ FLOCK  /  ! FUND  /  B +2" in String(dividend.get_meta("visible_card_text", ""))
		and "HELPS" not in String(dividend.get_meta("visible_card_text", ""))
		and String(dividend.get_meta("glance_symbol_language", ""))
		== "plus_benefit_bang_tradeoff_b_board"
		and String(dividend.get_meta("glance_help", "")) == "FLOCK"
		and String(dividend.get_meta("glance_risk", "")) == "FUND"
		and String(dividend.get_meta("glance_board", "")) == "+2"
		and String(dividend.get_meta("glance_fund", "")) == "$ -24"
		and String(dividend.get_meta("glance_outcome", "")) == "FLOCK STRAIN DOWN"
		and "-$24" not in String(dividend.get_meta("visible_card_text", ""))
		and String(dividend.get_meta("accessible_text", "")).contains("Helps FLOCK")
		and String(dividend.get_meta("accessible_text", "")).contains("Risks FUND")
		and String(dividend.get_meta("accessible_text", "")).contains("Board fit +2"),
		"Senior policy cards should replace repeated prose with one stable benefit, tradeoff, and Board strip",
		failures,
	)
	var dividend_fund_chip := dividend.get_node_or_null("PolicyMetricChips/PolicyFundChip/PolicyFundChipLabel") as Label if dividend != null else null
	var dividend_outcome_chip := dividend.get_node_or_null("PolicyMetricChips/PolicyOutcomeChip/PolicyOutcomeChipLabel") as Label if dividend != null else null
	var dividend_signal := dividend.get_node_or_null("PolicyCardSignalLabel") as Label if dividend != null else null
	_check(dividend_fund_chip != null and dividend_fund_chip.text == "$ -24", "Senior policy cards should isolate Feed Fund movement in a stable metric chip", failures)
	_check(dividend_outcome_chip != null and dividend_outcome_chip.text == "FLOCK STRAIN DOWN", "Senior policy cards should isolate the primary operational result in a second metric chip", failures)
	_check(dividend_signal != null and dividend_signal.text == "+ FLOCK  /  ! FUND  /  B +2", "Senior policy cards should render the comparison strip in a dedicated non-overlapping row", failures)
	_check(dividend != null and "QUARTER EFFECT  //  FUND $ -24  //  RESULT FLOCK STRAIN DOWN" in dividend.tooltip_text and "AT A GLANCE  //  + HELPS FLOCK  //  ! RISKS FUND  //  B BOARD +2" in dividend.tooltip_text and "SCORE EDGE  //  FLOCK WELFARE + QUOTA RELIABILITY" in dividend.tooltip_text and "EDGE RELIABLE CLUTCH + FLOCK CONTINUITY" in dividend.tooltip_text, "Senior policy tooltips should retain exact quarter effect and annual fit", failures)
	_check(forecast != null and "+ FUND  /  ! FLOCK  /  B +1" in String(forecast.get_meta("visible_card_text", "")), "Senior policy cards should summarize their scored risk and annual edge", failures)
	var forecast_fund_chip := forecast.get_node_or_null("PolicyMetricChips/PolicyFundChip/PolicyFundChipLabel") as Label if forecast != null else null
	_check(forecast_fund_chip != null and forecast_fund_chip.text == "$ +60", "positive Feed Fund movement should use the same signed metric position", failures)
	_check(forecast != null and "SCORE WATCH  //  QUOTA RELIABILITY + FLOCK WELFARE + OBEDIENCE" in forecast.tooltip_text, "Senior policy tooltips should retain the complete scored risk", failures)
	_check(continue_button != null and continue_button.disabled, "a quarter must remain gated until an available policy is filed", failures)
	_check(requisitions_button != null and not requisitions_button.is_visible_in_tree() and requisitions_button.disabled, "unavailable Senior requisitions should leave the visible action row until staffing planning opens", failures)
	_check(
		continue_button != null
		and continue_button.text == "FILE POLICY  [C]"
		and continue_button.icon != null
		and String(continue_button.get_meta("semantic_icon", "")) == "advance_arrow"
		and String(continue_button.get_meta("accessible_text", "")).contains(
			"FILE POLICY & OPEN QUARTER"
		)
		and requisitions_button != null
		and requisitions_button.text == "REQUISITIONS  [R]"
		and requisitions_button.icon != null
		and shelve_button != null
		and shelve_button.text == "SAVE & EXIT  [A]"
		and shelve_button.icon != null
		and String(shelve_button.get_meta("outcome_first_action", "")) == "save_exit",
		"Senior report actions should use compact symbols and verbs without dropping exact semantics",
		failures,
	)
	if merit != null:
		merit.pressed.emit()
	_check(StringName(observed["chosen"]) == &"", "disabled policy activation must be ignored even when signaled directly", failures)
	if forecast != null:
		forecast.pressed.emit()
	await process_frame
	_check(StringName(observed["chosen"]) == &"harvest_forecast", "available policy should emit its stable domain ID", failures)
	_check(continue_button != null and not continue_button.disabled, "filing a policy should unlock the quarter", failures)
	_check(ui.selected_milestone_id() == &"harvest_forecast", "selected policy should remain visibly persistent", failures)

	# Advanced annual Books own permanent career risk. Selecting one should only
	# stage the exact stake; the existing Continue action must confirm it.
	observed["chosen"] = &""
	var advanced_snapshot := _advanced_mandate_snapshot()
	var advanced_ledgers := advanced_snapshot.get("ledgers", []) as Array
	(advanced_ledgers[0] as Dictionary)["glance"] = "+ 2 READY TO SPEND"
	(advanced_ledgers[1] as Dictionary)["glance"] = "> 1 SEAL TO TIER 2"
	(advanced_ledgers[2] as Dictionary)["glance"] = "> FIRST QUARTER OPEN"
	ui.show_between_shift_report(advanced_snapshot)
	await process_frame
	await process_frame
	var marks_card := ui.find_child("ReportCumulativeLedger1", true, false) as PanelContainer
	var marks_glance := ui.find_child("ReportLedgerDetail1", true, false) as Label
	var seals_glance := ui.find_child("ReportLedgerDetail2", true, false) as Label
	var quarter_glance := ui.find_child("ReportLedgerDetail3", true, false) as Label
	_check(marks_glance != null and marks_glance.text == "+ 2 READY TO SPEND" and seals_glance != null and seals_glance.text == "> 1 SEAL TO TIER 2" and quarter_glance != null and quarter_glance.text == "> FIRST QUARTER OPEN", "Senior career ledgers should replace dense accounting lines with stable icon-led glance states", failures)
	_check(marks_card != null and "2 AVAILABLE" in marks_card.tooltip_text and "0 FORFEITED" in marks_card.tooltip_text and String(marks_card.get_meta("accessible_text", "")).contains("ROOST MARKS 5"), "compact ledger subtitles should retain exact lifetime accounting in progressive and assistive detail", failures)
	_check("INVESTED" not in _visible_text(ui) and "FORFEITED" not in _visible_text(ui), "exact career accounting should no longer compete with the report's visible scan path", failures)
	var advanced := ui.find_child("MilestoneChoice_mutual_assurance", true, false) as Button
	var standard := ui.find_child("MilestoneChoice_standard_board_book", true, false) as Button
	var mandate_hint := ui.find_child("MilestoneChoiceHint", true, false) as Label
	_check(advanced != null and not advanced.disabled, "an affordable advanced Board Book should be keyboard accessible", failures)
	_check(advanced != null and "NEW PORTFOLIO CLEAR" in advanced.text, "unmastered annual cards should disclose their permanent variety reward", failures)
	_check(standard != null and "MASTERED x2" in standard.text, "repeat annual cards should disclose existing mastery without promising duplicate recognition", failures)
	if advanced != null:
		advanced.pressed.emit()
	await process_frame
	_check(StringName(observed["chosen"]) == &"", "the first advanced-card activation must not reserve career marks", failures)
	_check(int(observed["presentation_changes"]) == 1, "staging a paused advanced confirmation should request one diagnostic presentation refresh", failures)
	_check(ui.selected_milestone_id() == &"mutual_assurance", "the inspected advanced Book should remain visibly selected", failures)
	_check(continue_button != null and not continue_button.disabled and "CONFIRM 2-MARK STAKE" in continue_button.text, "the existing action should become an explicit exact-stake confirmation", failures)
	_check(
		continue_button != null
		and String(continue_button.get_meta("semantic_icon", "")) == "irreversible_warning",
		"a staged permanent Board stake should replace the advance arrow with the warning symbol",
		failures,
	)
	_check(continue_button != null and "failure permanently spends them" in continue_button.tooltip_text, "the confirmation tooltip should disclose permanent failure cost", failures)
	_check(mandate_hint != null and "PRESS C TO CONFIRM 2-MARK STAKE" in mandate_hint.text, "the selection hint should publish the keyboard confirmation step", failures)
	var pending := (ui.campaign_snapshot().get("pending_milestone_confirmation", {}) as Dictionary)
	_check(String(pending.get("id", "")) == "mutual_assurance" and int(pending.get("stake_marks", 0)) == 2, "assistive diagnostics should expose the exact pending stake without mutating authority", failures)
	if continue_button != null:
		continue_button.pressed.emit()
	_check(StringName(observed["chosen"]) == &"mutual_assurance", "confirming should emit the stable advanced mandate ID exactly once", failures)
	_check(int(observed["continued"]) == 0, "stake confirmation must not also continue through the report", failures)
	_check((ui.campaign_snapshot().get("pending_milestone_confirmation", {}) as Dictionary).is_empty(), "confirmed presentation intent should clear its pending confirmation", failures)

	# The quick no-stake fallback remains a one-action filing.
	observed["chosen"] = &""
	ui.show_between_shift_report(_advanced_mandate_snapshot())
	await process_frame
	standard = ui.find_child("MilestoneChoice_standard_board_book", true, false) as Button
	if standard != null:
		standard.pressed.emit()
	_check(StringName(observed["chosen"]) == &"standard_board_book", "the no-stake fallback should retain its immediate filing flow", failures)

	harness.size = Vector2(800.0, 720.0)
	await process_frame
	await process_frame
	var choice_host := ui.find_child("MilestoneChoiceCards", true, false) as HFlowContainer
	var compact_choices := ui.find_children("MilestoneChoice_*", "Button", true, false)
	_check(choice_host != null and choice_host.alignment == FlowContainer.ALIGNMENT_CENTER and compact_choices.size() == 3, "small-laptop policy choices should use an intentional centered flow", failures)
	if compact_choices.size() == 3:
		var first_rect := (compact_choices[0] as Button).get_global_rect()
		var second_rect := (compact_choices[1] as Button).get_global_rect()
		var third_rect := (compact_choices[2] as Button).get_global_rect()
		_check(absf(first_rect.position.y - second_rect.position.y) <= 1.0 and absf(first_rect.position.y - third_rect.position.y) <= 1.0, "an 800px policy filing should preserve one balanced three-card comparison row (rects=%s / %s / %s)" % [first_rect, second_rect, third_rect], failures)
		_check(first_rect.size.x >= 220.0 and first_rect.size.x <= 230.0 and absf(first_rect.size.x - third_rect.size.x) <= 1.0, "small-laptop policy columns should share the available report width evenly (rects=%s / %s / %s)" % [first_rect, second_rect, third_rect], failures)

	harness.size = Vector2(760.0, 720.0)
	await process_frame
	await process_frame
	compact_choices = ui.find_children("MilestoneChoice_*", "Button", true, false)
	if compact_choices.size() == 3:
		var first_stacked_rect := (compact_choices[0] as Button).get_global_rect()
		var second_stacked_rect := (compact_choices[1] as Button).get_global_rect()
		var third_stacked_rect := (compact_choices[2] as Button).get_global_rect()
		_check(second_stacked_rect.position.y >= first_stacked_rect.end.y - 0.5 and third_stacked_rect.position.y >= second_stacked_rect.end.y - 0.5, "sub-800px policy choices should become a deliberate one-card-per-row decision stack", failures)
		_check(absf(first_stacked_rect.size.x - third_stacked_rect.size.x) <= 1.0 and first_stacked_rect.size.x >= 650.0, "stacked policy choices should use the full readable report width instead of leaving an orphan column", failures)

	harness.size = Vector2(390.0, 844.0)
	await process_frame
	await process_frame
	var report_rect := report.get_global_rect()
	_check(report_rect.position.x >= -0.5 and report_rect.end.x <= 390.5, "Senior policy report should stay inside a 390px portrait viewport (rect=%s)" % report_rect, failures)
	_check(report.custom_minimum_size.x == 338.0 and heading_stack != null and heading_stack.custom_minimum_size.x == 0.0, "portrait Senior reports should derive their width from the viewport and release the desktop heading minimum", failures)
	var scroll := ui.find_child("ProbationModalScroll", true, false) as ScrollContainer
	_check(scroll != null and scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Senior reports should never require horizontal scrolling", failures)

	harness.size = Vector2(1280.0, 720.0)
	ui.show_between_shift_report(_annual_review_snapshot())
	await process_frame
	await process_frame
	_check(heading.text == "YEAR 1 ANNUAL ROOST REVIEW", "annual review should use distinct authored copy", failures)
	_check(not (ui.find_child("MilestoneChoiceSection", true, false) as VBoxContainer).is_visible_in_tree(), "annual review should not present a quarterly policy gate", failures)
	_check(continue_button.text == "BEGIN YEAR 2  [C]" and not continue_button.disabled, "annual review should offer an explicit next-year action", failures)
	_check(
		continue_button.icon != null
		and String(continue_button.get_meta("semantic_icon", "")) == "advance_arrow",
		"annual continuation should restore the reversible advance symbol",
		failures,
	)
	_check(_visible_text(ui).find("probation") == -1, "annual Senior UI must remain free of probation copy", failures)
	continue_button.pressed.emit()
	_check(int(observed["continued"]) == 1, "annual continuation should reuse the public campaign intent", failures)
	ui.show_active_campaign(_quarter_policy_snapshot())
	await process_frame
	_check(day_badge != null and day_badge.is_visible_in_tree() and not bool(day_badge.get_meta("suppressed_by_report", true)), "returning to the office should restore the Senior calendar badge", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("SENIOR_ROOST_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SENIOR_ROOST_UI_TEST_PASSED policy_cards=3 reserves=disabled keyboard=available annual=distinct responsive=390x844")
	quit(0)


func _quarter_policy_snapshot() -> Dictionary:
	return {
		"view": "between_shift",
		"career_mode": "senior_roost",
		"status": "SENIOR ROOST",
		"day": 1,
		"total_days": 3,
		"senior_year": 1,
		"senior_quarter": 1,
		"day_badge_text": "Y1 · Q1 · SHIFT 1 / 3",
		"report_heading": "QUARTER 1 CAPITAL FILING",
		"report_note": "Choose how this quarter spends money, pressure, and trust.",
		"choice_section_title": "QUARTERLY CAPITAL POLICY  //  FILE ONE",
		"choice_hint": "One policy governs the next three shifts.",
		"continue_label": "FILE POLICY & OPEN QUARTER  [C]",
		"continue_tooltip": "Open Quarter 1 under the selected capital policy.",
		"choice_required": true,
		"score": 0,
		"secondary_metric_display": "0 / 3",
		"secondary_metric_caption": "QUARTER SHIFTS",
		"secondary_metric_tooltip": "Three filed shifts close a Senior Roost quarter.",
		"rank": "Senior Claims Rooster",
		"rank_caption": "CAREER TITLE",
		"ledgers": [
			{"label": "ROOST MARKS", "value": 0, "detail": "CAREER TOTAL"},
			{"label": "FEED FUND", "value": 1000, "format": "currency_cents", "detail": "SPENDABLE"},
			{"label": "YEARS PASSED", "value": 0, "detail": "ANNUAL REVIEWS"},
		],
		"next_objective": {
			"title": "FILE A CAPITAL POLICY",
			"description": "The quarter cannot open until management accepts a tradeoff.",
			"board_summary": "BOARD 1 / 3 MET  //  2 NEED ACTION  //  YEAR 0 / 12",
			"board_detail": "ANNUAL BOARD  //  STANDARD BOARD BOOK\n0 / 12 shifts  //  1 / 3 targets met\nNEEDS ACTION  //  RELIABLE CLUTCH  //  0 / 6\nNEEDS ACTION  //  FLOCK CONTINUITY  //  0 / 45\nMET  //  CURRENT PAYROLL  //  0 / 0\nLARGEST RECOVERABLE BLOCKER  //  RELIABLE CLUTCH  //  GAP 6",
		},
		"annual_mandate_progress": _board_progress_snapshot(),
		"milestone_choices": [
			{
				"id": "merit_grants",
				"title": "Merit Grants",
				"description": "Concentrate development money on the top hen.",
				"effect": "-$12.00 / top hen development",
				"glance_fund": "$ -12",
				"glance_outcome": "HEN DEVELOPMENT",
				"available": false,
				"unavailable_reason": "$2.00 more spendable Feed Fund is required.",
				"strategy": {
					"score_edge": "COOP OBEDIENCE + TOP-HEN CAREER",
					"score_watch": "FARMER FAVOR + FUND BUFFER",
					"board_fit": "NO DIRECT TARGET EDGE  //  WATCH CURRENT PAYROLL",
					"board_name": "STANDARD BOARD BOOK",
				},
			},
			{
				"id": "flock_dividend",
				"title": "Flock Dividend",
				"description": "Return part of the harvest to every employed hen.",
				"effect": "-$24.00 / flock strain down",
				"glance_fund": "$ -24",
				"glance_outcome": "FLOCK STRAIN DOWN",
				"available": false,
				"unavailable_reason": "$14.00 more spendable Feed Fund is required.",
				"strategy": {
					"score_edge": "FLOCK WELFARE + QUOTA RELIABILITY",
					"score_watch": "FARMER FAVOR + FUND BUFFER",
					"board_fit": "EDGE RELIABLE CLUTCH + FLOCK CONTINUITY  //  WATCH CURRENT PAYROLL",
					"board_name": "STANDARD BOARD BOOK",
				},
			},
			{
				"id": "harvest_forecast",
				"title": "Executive Harvest Forecast",
				"description": "Book future confidence as present Feed Fund.",
				"effect": "+$60.00 / favor +24 / next quota +2 / flock trust -1, grievance +1",
				"glance_fund": "$ +60",
				"glance_outcome": "FAVOR +24",
				"available": true,
				"strategy": {
					"score_edge": "FARMER FAVOR + FUND BUFFER",
					"score_watch": "QUOTA RELIABILITY + FLOCK WELFARE + OBEDIENCE",
					"board_fit": "EDGE CURRENT PAYROLL  //  WATCH RELIABLE CLUTCH + FLOCK CONTINUITY",
					"board_name": "STANDARD BOARD BOOK",
				},
			},
		],
	}


func _board_progress_snapshot() -> Dictionary:
	return {
		"objectives_met": 1,
		"objectives_total": 3,
		"shifts_recorded": 0,
		"shifts_target": 12,
		"objectives": [
			{
				"metric": "quota_met_shifts",
				"label": "RELIABLE CLUTCH",
				"comparison": "minimum",
				"actual": 0,
				"target": 6,
				"met": false,
			},
			{
				"metric": "welfare_average",
				"label": "FLOCK CONTINUITY",
				"comparison": "minimum",
				"actual": 0,
				"target": 45,
				"met": false,
			},
			{
				"metric": "wage_arrears_shifts",
				"label": "CURRENT PAYROLL",
				"comparison": "maximum",
				"actual": 0,
				"target": 0,
				"met": true,
			},
		],
	}


func _annual_review_snapshot() -> Dictionary:
	return {
		"view": "between_shift",
		"career_mode": "senior_roost",
		"status": "SENIOR ROOST",
		"day": 3,
		"total_days": 3,
		"day_badge_text": "YEAR 1 · ANNUAL REVIEW",
		"report_kicker": "SENIOR ROOST  //  YEAR 1 CLOSED",
		"report_heading": "YEAR 1 ANNUAL ROOST REVIEW",
		"report_note": "Annual safeguards passed. The permanent career record remains open.",
		"continue_label": "BEGIN YEAR 2  [C]",
		"continue_tooltip": "Accept the annual review and open Year 2 planning.",
		"score": 74,
		"rank": "Department Rooster",
		"ledgers": [
			{"label": "ANNUAL SCORE", "value": 74, "detail": "PASSED"},
			{"label": "ROOST MARKS", "value": 11, "detail": "CAREER TOTAL"},
			{"label": "YEARS PASSED", "value": 1, "detail": "OF 1 REVIEWED"},
		],
		"next_objective": {
			"title": "YEAR 2",
			"description": "The next year adds one clutch to the baseline quota.",
		},
		"milestone_choices": [],
	}


func _advanced_mandate_snapshot() -> Dictionary:
	return {
		"view": "between_shift",
		"career_mode": "senior_roost",
		"status": "SENIOR ROOST",
		"day": 1,
		"total_days": 3,
		"senior_year": 2,
		"senior_quarter": 1,
		"day_badge_text": "Y2 Â· ANNUAL MANDATE",
		"report_heading": "YEAR 2 Â· ANNUAL BOARD MANDATE",
		"report_note": "Recovery year. Compare the permanent stake before filing.",
		"choice_section_title": "ANNUAL BOARD MANDATE  //  FILE ONE",
		"choice_hint": "One twelve-shift mandate governs the year.",
		"continue_label": "SELECT A MANDATE BEFORE Q1 POLICY  [C]",
		"continue_tooltip": "Choose one Board Book before Quarter 1 policy.",
		"choice_required": true,
		"selected_milestone": "",
		"score": 5,
		"rank": "Senior Claims Rooster",
		"ledgers": [
			{"label": "ROOST MARKS", "value": 5, "detail": "2 AVAILABLE  Â·  0 INVESTED  Â·  0 STAKED  Â·  0 FORFEITED"},
			{"label": "BOARD SEALS", "value": 1, "format": "number", "detail": "MANDATE TIER 1"},
			{"label": "QUARTER SCORE", "value": 0, "format": "number", "detail": "FIRST QUARTER OPEN"},
		],
		"milestone_choices": [
			{
				"id": "standard_board_book",
				"title": "Standard Board Book",
				"description": "Keep the year solvent without staking marks.",
				"effect": "TIER 0 Â· MASTERED x2 Â· NO MARK STAKE Â· +1 SEAL",
				"stake_marks": 0,
				"available": true,
			},
			{
				"id": "mutual_assurance",
				"title": "Mutual Assurance Guarantee",
				"description": "Stake two marks on quality, quota, and obedience.",
				"effect": "TIER 1 Â· NEW PORTFOLIO CLEAR Â· 2 ROOST MARKS STAKED Â· +2 SEALS",
				"stake_marks": 2,
				"confirmation_required": true,
				"confirmation_label": "CONFIRM 2-MARK STAKE  [C]",
				"confirmation_tooltip": "Confirm the 2-mark career stake. The marks remain reserved for this twelve-shift Book; success returns them, while failure permanently spends them.",
				"available": true,
			},
			{
				"id": "shell_stewardship",
				"title": "Shell Stewardship Book",
				"description": "Protect quality without staking marks.",
				"effect": "TIER 0 Â· NEW PORTFOLIO CLEAR Â· NO MARK STAKE Â· +1 SEAL",
				"stake_marks": 0,
				"available": true,
			},
		],
	}


func _visible_text(root_node: Node) -> String:
	var parts: Array[String] = []
	for node: Node in root_node.find_children("*", "", true, false):
		if node is Label and (node as Label).is_visible_in_tree():
			parts.append((node as Label).text.to_lower())
		elif node is Button and (node as Button).is_visible_in_tree():
			parts.append((node as Button).text.to_lower())
	return "\n".join(parts)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
