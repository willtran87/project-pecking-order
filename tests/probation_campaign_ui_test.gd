extends SceneTree

const ProbationCampaignUIScript := preload("res://features/office/probation_campaign_ui.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observed := {
		"continue": 0,
		"new": 0,
		"abandon": 0,
		"milestone": &"",
	}
	var harness := Control.new()
	harness.name = "ProbationCampaignUITestHarness"
	harness.size = Vector2(1280.0, 720.0)
	root.add_child(harness)
	var ui = ProbationCampaignUIScript.new()
	harness.add_child(ui)
	ui.continue_campaign.connect(func() -> void: observed["continue"] += 1)
	ui.new_campaign.connect(func() -> void: observed["new"] += 1)
	ui.abandon_campaign.connect(func() -> void: observed["abandon"] += 1)
	ui.milestone_choice.connect(func(choice_id: StringName) -> void: observed["milestone"] = choice_id)
	await process_frame

	var badge := ui.find_child("ProbationDayBadge", true, false) as PanelContainer
	var status_label := ui.find_child("ProbationStatusLabel", true, false) as Label
	var day_label := ui.find_child("ProbationDayLabel", true, false) as Label
	var modal_host := ui.find_child("ProbationModalHost", true, false) as Control
	_check(badge != null and badge.is_visible_in_tree(), "probation badge should always be visible", failures)
	_check(status_label != null and status_label.text == "PROBATION", "badge should default to probation status", failures)
	_check(day_label != null and day_label.text == "DAY 1 / 5", "badge should open on day one of five", failures)
	_check(modal_host != null and not modal_host.is_visible_in_tree(), "active campaign should leave the office unobstructed", failures)

	ui.show_active_campaign({"status": "Probation", "score": 50})
	await process_frame
	_check(status_label != null and status_label.text == "SCORE 50 / 100", "active probation badge should name the score scale explicitly", failures)
	_check(
		status_label != null
		and "60 / 100" in status_label.tooltip_text
		and "welfare" in status_label.tooltip_text
		and "compliance" in status_label.tooltip_text
		and "farmer favor" in status_label.tooltip_text
		and "shell-quality safeguards" in status_label.tooltip_text,
		"score badge tooltip should explain the threshold and every final safeguard",
		failures,
	)

	ui.show_title(false)
	await process_frame
	var title_panel := ui.find_child("CampaignTitlePanel", true, false) as PanelContainer
	var title_heading := ui.find_child("CampaignTitle", true, false) as Label
	var title_description := ui.find_child("CampaignTitleDescription", true, false) as Label
	var mabel_card := ui.find_child("MabelProfileCard", true, false) as PanelContainer
	var mabel_identity := ui.find_child("CampaignMabelIdentity", true, false) as Label
	var mabel_traits := ui.find_child("CampaignMabelTraits", true, false) as Label
	var mabel_quote := ui.find_child("CampaignMabelQuote", true, false) as Label
	var new_button := ui.find_child("NewCampaignButton", true, false) as Button
	var continue_button := ui.find_child("ContinueCampaignButton", true, false) as Button
	_check(title_panel != null and title_panel.is_visible_in_tree(), "first load should show the campaign title panel", failures)
	_check(modal_host.is_visible_in_tree(), "title panel should be an intentional blocking modal", failures)
	_check(
		title_heading != null and title_heading.text == "FIVE SHIFTS. START WITH ONE HEN.",
		"title should foreground one named hen before management abstractions",
		failures,
	)
	_check(
		title_description != null
		and title_description.text == "Mabel is already at her desk. Every choice you make together shares one permanent coop file.",
		"title subtitle should connect Mabel to the shared permanent file",
		failures,
	)
	_check(
		mabel_card != null
		and mabel_card.is_visible_in_tree()
		and ui.find_child("ProbationTermsCard", true, false) == null,
		"Mabel's compact profile should replace the abstract probation-rules card",
		failures,
	)
	_check(
		mabel_identity != null and mabel_identity.text == "MABEL  //  JUNIOR CLAIMS HEN",
		"Mabel profile should establish her name and current role",
		failures,
	)
	_check(
		mabel_traits != null
		and mabel_traits.text == "APPEALS SPECIALIST  //  CREDIT CONSCIOUS",
		"Mabel profile should expose her specialty and motivation",
		failures,
	)
	_check(
		mabel_quote != null
		and mabel_quote.text == "\"The farmer remembers the basket, not the beak that filled it.\"",
		"Mabel profile should give the opening hen a concise first-person perspective",
		failures,
	)
	_check(continue_button != null and continue_button.disabled, "continue should be disabled without a saved campaign", failures)
	_check(
		new_button != null
		and new_button.text == "MEET MABEL & OPEN FILE  [N]"
		and new_button.focus_mode == Control.FOCUS_ALL,
		"primary title action should invite the player to meet Mabel and support keyboard focus",
		failures,
	)
	if new_button != null:
		new_button.pressed.emit()
	_check(int(observed["new"]) == 1, "new campaign action should emit its public signal", failures)
	for viewport_size: Vector2 in [
		Vector2(1280.0, 720.0),
		Vector2(2560.0, 1600.0),
		Vector2(1440.0, 1000.0),
		Vector2(390.0, 844.0),
	]:
		await _check_responsive_layout(ui, harness, "CampaignTitlePanel", viewport_size, failures)
		_check_title_character_layout(
			title_panel,
			mabel_card,
			[mabel_identity, mabel_traits, mabel_quote],
			new_button,
			viewport_size,
			failures,
		)
	harness.size = Vector2(1280.0, 720.0)
	await process_frame

	ui.apply_snapshot({
		"view": "title",
		"day": 3,
		"total_days": 5,
		"continue_available": true,
	})
	await process_frame
	_check(day_label.text == "DAY 3 / 5", "badge should react to plain campaign snapshot data", failures)
	_check(not continue_button.disabled, "continue should enable when a resumable campaign exists", failures)
	continue_button.pressed.emit()
	_check(int(observed["continue"]) == 1, "continue action should emit its public signal", failures)

	ui.show_between_shift_report({
		"day": 2,
		"total_days": 5,
		"score": 1840,
		"rank": "Silver Comb",
		"score_receipt": {
			"shift_number": 2,
			"score_before": 1703,
			"score_after": 1840,
			"score_delta": 137,
			"raw_shift_delta": 137,
			"applied_shift_delta": 137,
			"components": [
				{
					"id": "probation_orders",
					"label": "Probation Orders",
					"delta": 120,
					"detail": "Two orders cleared without an exception.",
				},
				{
					"id": "daily_clutch",
					"label": "Daily Clutch",
					"delta": 47,
					"detail": "Forty-seven eggs entered the campaign ledger.",
				},
				{
					"id": "shell_quality",
					"label": "Shell Quality",
					"delta": -12,
					"detail": "Cracked shells reduced the filing value.",
				},
				{
					"id": "queue_control",
					"label": "Queue Control",
					"delta": -8,
					"detail": "Open claims remained at close.",
				},
				{
					"id": "flock_safeguards",
					"label": "Flock Safeguards",
					"delta": -10,
					"detail": "One welfare warning was filed.",
				},
			],
		},
		"credit_memo": {
			"day": 2,
			"decision_id": "golden_egg_dossier",
			"option_id": "farmer_credit",
			"worker_name": "Mabel",
			"outcome": "The farmer presented Mabel's golden file as a management breakthrough.",
		},
		"hen_highlight": {
			"day": 2,
			"type": "golden_deliverable",
			"worker_name": "Mabel",
			"career_title": "Senior Claims Hen",
			"relationship_label": "Warm",
			"headline": "Golden Deliverable",
			"body": "Mabel laid one golden egg. The farmer congratulated management before collecting it.",
			"metric": "5 EGGS  //  4 SOUND  //  1 GOLDEN  //  $14.80 CREDIT",
			"tone": "gold",
		},
		"ledgers": [
			{"label": "Eggs Filed", "value": 47, "detail": "TWO-SHIFT TOTAL"},
			{"label": "Feed Fund", "value": 9235, "format": "currency_cents", "detail": "BANKED"},
			{"label": "Shell Integrity", "value": 91, "format": "percent", "detail": "CAMPAIGN QUALITY"},
		],
		"next_objective": {
			"title": "Clear Predator Backlog",
			"description": "Close six Predator Loss files before noon.",
			"progress": 0,
			"target": 6,
		},
		"milestone_choices": [
			{
				"id": "fast_keys",
				"title": "Brass Keycaps",
				"description": "Peckwork starts faster.",
				"effect": "+10% processing speed",
			},
			{
				"id": "soft_nests",
				"title": "Soft Nests",
				"description": "Cushion rushed production.",
				"effect": "-8% crack risk",
			},
		],
	})
	await process_frame
	await process_frame
	var report_panel := ui.find_child("ProbationReportPanel", true, false) as PanelContainer
	var report_day := ui.find_child("ProbationReportDay", true, false) as Label
	var score := ui.find_child("ReportScore", true, false) as Label
	var shift_delta := ui.find_child("ReportShiftDelta", true, false) as Label
	var receipt_summary := ui.find_child("ReportScoreReceiptSummary", true, false) as Label
	var rank := ui.find_child("ReportRank", true, false) as Label
	var story_row := ui.find_child("ReportShiftStories", true, false) as HFlowContainer
	var credit_memo_card := ui.find_child("FiledCreditMemoCard", true, false) as PanelContainer
	var highlight_card := ui.find_child("ShiftHenHighlightCard", true, false) as PanelContainer
	var highlight_eyebrow := ui.find_child("ShiftHenHighlightEyebrow", true, false) as Label
	var highlight_headline := ui.find_child("ShiftHenHighlightHeadline", true, false) as Label
	var highlight_body := ui.find_child("ShiftHenHighlightBody", true, false) as Label
	var highlight_metric := ui.find_child("ShiftHenHighlightMetric", true, false) as Label
	var first_ledger := ui.find_child("ReportLedgerValue1", true, false) as Label
	var second_ledger := ui.find_child("ReportLedgerValue2", true, false) as Label
	var third_ledger := ui.find_child("ReportLedgerValue3", true, false) as Label
	var objective := ui.find_child("NextShiftObjective", true, false) as Label
	var milestone_section := ui.find_child("MilestoneChoiceSection", true, false) as VBoxContainer
	var choice := ui.find_child("MilestoneChoice_fast_keys", true, false) as Button
	var report_continue := ui.find_child("ContinueProbationButton", true, false) as Button
	_check(report_panel != null and report_panel.is_visible_in_tree(), "between shifts should show the probation report", failures)
	_check(
		report_day != null
		and report_day.text == "CLOSING FILE 3 / 3 · SHIFT 2 OF 5 · PROBATION REPORT",
		"probation report should identify itself as the third and final closing file",
		failures,
	)
	_check(score != null and score.text == "1,840", "report should present a readable cumulative score", failures)
	_check(shift_delta != null and shift_delta.text == "+137", "report should present the exact signed shift score", failures)
	_check(
		shift_delta != null and _colors_close(shift_delta.get_theme_color("font_color"), Color("73b5a7")),
		"a positive shift score should use the report's positive teal",
		failures,
	)
	_check(
		receipt_summary != null
		and "1703 -> 1840" in receipt_summary.text
		and "ORDERS +120" in receipt_summary.text
		and "CLUTCH +47" in receipt_summary.text
		and "SHELLS -12" in receipt_summary.text
		and "QUEUES -8" in receipt_summary.text
		and "FLOCK -10" in receipt_summary.text,
		"score receipt summary should expose every grouped causal component",
		failures,
	)
	_check(
		receipt_summary != null
		and "SHIFT 2 SCORE RECEIPT" in receipt_summary.tooltip_text
		and "Probation Orders  +120" in receipt_summary.tooltip_text
		and "Two orders cleared without an exception." in receipt_summary.tooltip_text
		and shift_delta.tooltip_text == receipt_summary.tooltip_text,
		"receipt summary and score metric should retain the full causal detail in a shared tooltip",
		failures,
	)
	_check(rank != null and rank.text == "SILVER COMB", "report should present the campaign rank", failures)
	_check(
		rank != null
		and rank.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
		and rank.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING,
		"report rank should wrap instead of rendering a truncated ellipsis",
		failures,
	)
	_check(
		first_ledger != null and first_ledger.text == "47"
		and second_ledger != null and second_ledger.text == "$92.35"
		and third_ledger != null and third_ledger.text == "91%",
		"report should expose exactly three formatted cumulative ledgers",
		failures,
	)
	_check(objective != null and "CLEAR PREDATOR BACKLOG" in objective.text, "report should teach the next-shift objective", failures)
	_check(
		story_row != null and story_row.is_visible_in_tree()
		and credit_memo_card != null and credit_memo_card.is_visible_in_tree()
		and highlight_card != null and highlight_card.is_visible_in_tree(),
		"credit attribution and the causal hen file should share the report story row",
		failures,
	)
	_check(
		highlight_eyebrow != null and highlight_eyebrow.text == "HEN FILE  //  MABEL  //  WARM"
		and highlight_headline != null and highlight_headline.text == "GOLDEN DELIVERABLE"
		and highlight_body != null and "farmer congratulated management" in highlight_body.text
		and highlight_metric != null and highlight_metric.text == "5 EGGS  //  4 SOUND  //  1 GOLDEN  //  $14.80 CREDIT",
		"hen highlight should preserve the subject, satirical outcome, and shift evidence",
		failures,
	)
	_check(
		highlight_body != null
		and "SENIOR CLAIMS HEN" in highlight_body.tooltip_text
		and "5 EGGS" in highlight_body.tooltip_text
		and highlight_eyebrow != null
		and _colors_close(highlight_eyebrow.get_theme_color("font_color"), Color("d1a650")),
		"golden hen highlights should expose their full file and use the gold tone",
		failures,
	)
	var highlight_style := highlight_card.get_theme_stylebox("panel") as StyleBoxFlat if highlight_card != null else null
	_check(
		highlight_style != null
		and _colors_close(highlight_style.border_color, Color("d1a650").darkened(0.1)),
		"hen highlight card border should carry the selected highlight tone",
		failures,
	)
	_check(milestone_section != null and milestone_section.is_visible_in_tree(), "offered milestones should appear as choice cards", failures)
	_check(choice != null and choice.focus_mode == Control.FOCUS_ALL, "milestone cards should be keyboard focusable", failures)
	_check(report_continue != null and report_continue.disabled, "report should wait for a required milestone choice", failures)
	if choice != null:
		choice.pressed.emit()
	_check(StringName(observed["milestone"]) == &"fast_keys", "milestone action should emit its stable identifier", failures)
	_check(ui.selected_milestone_id() == &"fast_keys", "component should expose its selected milestone", failures)
	_check(choice != null and choice.theme_type_variation == &"SelectedChoiceButton", "selected milestone should remain visually persistent", failures)
	_check(report_continue != null and not report_continue.disabled, "choosing a milestone should unlock continuation", failures)
	if report_continue != null:
		report_continue.pressed.emit()
	_check(int(observed["continue"]) == 2, "report continuation should reuse the campaign continuation signal", failures)
	var abandon := ui.find_child("AbandonCampaignButton", true, false) as Button
	if abandon != null:
		abandon.pressed.emit()
	_check(int(observed["abandon"]) == 1, "abandon action should emit its public signal", failures)

	var report_rect := report_panel.get_global_rect()
	_check(
		report_rect.position.x >= 0.0 and report_rect.end.x <= 1280.0
		and report_rect.position.y >= 60.0 and report_rect.end.y <= 720.0,
		"report card should fit the 1280x720 stage below the persistent badge",
		failures,
	)
	for viewport_size: Vector2 in [
		Vector2(1280.0, 720.0),
		Vector2(2560.0, 1600.0),
		Vector2(1440.0, 1000.0),
		Vector2(390.0, 844.0),
	]:
		await _check_responsive_layout(ui, harness, "ProbationReportPanel", viewport_size, failures)
	await _check_report_story_layout(ui, harness, Vector2(1280.0, 720.0), false, failures)
	await _check_report_story_layout(ui, harness, Vector2(390.0, 844.0), true, failures)
	var modal_scroll := ui.find_child("ProbationModalScroll", true, false) as ScrollContainer
	if modal_scroll != null:
		modal_scroll.scroll_vertical = 100000
	await process_frame
	ui.show_between_shift_report()
	await process_frame
	await process_frame
	_check(modal_scroll != null and modal_scroll.scroll_vertical == 0, "opening a report should reset its scroll to the causal summary", failures)
	_check(
		ui.get_viewport().gui_get_focus_owner() == report_panel,
		"report focus should intentionally begin on the report summary before its actions",
		failures,
	)
	harness.size = Vector2(1280.0, 720.0)
	await process_frame

	ui.show_between_shift_report({
		"day": 1,
		"score": 0,
		"rank": "Unranked",
		"score_receipt": {},
		"credit_memo": {},
		"hen_highlight": {},
		"milestone_choices": [],
	})
	await process_frame
	await process_frame
	_check(shift_delta != null and shift_delta.text == "--", "missing receipt data should use an explicit unavailable shift score", failures)
	_check(
		receipt_summary != null and receipt_summary.text == "Cumulative results follow you through all five shifts.",
		"missing receipt data should restore the neutral report explanation",
		failures,
	)
	_check(
		story_row != null and not story_row.is_visible_in_tree()
		and credit_memo_card != null and not credit_memo_card.is_visible_in_tree()
		and highlight_card != null and not highlight_card.is_visible_in_tree(),
		"story row should collapse completely when neither attribution nor hen data exists",
		failures,
	)

	ui.show_final_review({
		"day": 5,
		"score": 5120,
		"rank": "Golden Rooster",
		"passed": true,
		"ledgers": [
			{"label": "Eggs Filed", "value": 133},
			{"label": "Feed Fund", "value": 21480, "format": "currency_cents"},
			{"label": "Shell Integrity", "value": 94, "format": "percent"},
		],
	})
	await process_frame
	var final_panel := ui.find_child("FinalProbationReviewPanel", true, false) as PanelContainer
	var verdict := ui.find_child("FinalProbationVerdict", true, false) as Label
	var final_continue := ui.find_child("FinalContinueCampaignButton", true, false) as Button
	var final_rank := ui.find_child("FinalRank", true, false) as Label
	_check(final_panel != null and final_panel.is_visible_in_tree(), "day five should show the final campaign review", failures)
	_check(verdict != null and verdict.text == "PROBATION PASSED", "final review should clearly distinguish a pass", failures)
	_check(final_continue != null and final_continue.is_visible_in_tree(), "passing should offer the senior-roost continuation", failures)
	_check(
		final_rank != null
		and final_rank.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
		and final_rank.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING,
		"final rank should preserve the complete management title",
		failures,
	)
	_check(final_panel.size.y < 500.0, "final review should size to its content instead of leaving a large empty footer", failures)

	ui.show_final_review({"day": 5, "score": 900, "rank": "Loose Feather", "passed": false})
	await process_frame
	_check(verdict.text == "PROBATION FAILED", "final review should clearly distinguish a failure", failures)
	_check(not final_continue.is_visible_in_tree(), "failure should not offer post-probation continuation", failures)
	var retry := ui.find_child("FinalNewCampaignButton", true, false) as Button
	_check(retry != null and "RETRY PROBATION" in retry.text, "failure should offer an immediate retry", failures)
	for viewport_size: Vector2 in [
		Vector2(1280.0, 720.0),
		Vector2(2560.0, 1600.0),
		Vector2(1440.0, 1000.0),
		Vector2(390.0, 844.0),
	]:
		await _check_responsive_layout(ui, harness, "FinalProbationReviewPanel", viewport_size, failures)
	harness.size = Vector2(1280.0, 720.0)
	await process_frame

	ui.hide_modal()
	await process_frame
	_check(not ui.is_modal_open() and not modal_host.is_visible_in_tree(), "closing campaign cards should restore the unobstructed office", failures)
	_check(badge.is_visible_in_tree() and day_label.text == "DAY 5 / 5", "day badge should persist after closing a modal", failures)

	ui.show_active_campaign({"status": "Senior Roost", "score": 73})
	await process_frame
	_check(
		status_label.text == "SENIOR ROOST  73",
		"active badge should expose compact long-term status and score",
		failures,
	)

	ui.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("PROBATION_CAMPAIGN_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PROBATION_CAMPAIGN_UI_TEST_PASSED badge=day/5+score/100+safeguards title=resume-gated report=closing-file-3/3+receipt+hen-file+ledgers+milestone final=pass/fail responsive=story-wrap+4 signals=4")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _colors_close(left: Color, right: Color, tolerance: float = 0.002) -> bool:
	return (
		absf(left.r - right.r) <= tolerance
		and absf(left.g - right.g) <= tolerance
		and absf(left.b - right.b) <= tolerance
		and absf(left.a - right.a) <= tolerance
	)


func _check_report_story_layout(
	ui: Control,
	harness: Control,
	viewport_size: Vector2,
	expect_wrapped: bool,
	failures: Array[String],
) -> void:
	harness.size = viewport_size
	await process_frame
	await process_frame
	var credit_card := ui.find_child("FiledCreditMemoCard", true, false) as PanelContainer
	var highlight_card := ui.find_child("ShiftHenHighlightCard", true, false) as PanelContainer
	_check(
		credit_card != null and credit_card.is_visible_in_tree()
		and highlight_card != null and highlight_card.is_visible_in_tree(),
		"both report story cards should remain visible at %s" % viewport_size,
		failures,
	)
	if credit_card == null or highlight_card == null:
		return
	var credit_rect := credit_card.get_global_rect()
	var highlight_rect := highlight_card.get_global_rect()
	if expect_wrapped:
		_check(
			is_equal_approx(credit_card.custom_minimum_size.x, 260.0)
			and is_equal_approx(highlight_card.custom_minimum_size.x, 260.0),
			"portrait report story cards should use compact 260px minimum widths",
			failures,
		)
		_check(
			highlight_rect.position.y >= credit_rect.end.y - 0.5,
			"portrait report should stack the hen file below the credit memo without overlap",
			failures,
		)
	else:
		_check(
			absf(credit_rect.position.y - highlight_rect.position.y) <= 1.0,
			"desktop report should keep both story cards on one compact row",
			failures,
		)


func _check_responsive_layout(
	ui: Control,
	harness: Control,
	panel_name: String,
	viewport_size: Vector2,
	failures: Array[String],
) -> void:
	harness.size = viewport_size
	await process_frame
	await process_frame
	var panel := ui.find_child(panel_name, true, false) as PanelContainer
	var modal_scroll := ui.find_child("ProbationModalScroll", true, false) as ScrollContainer
	var badge := ui.find_child("ProbationDayBadge", true, false) as PanelContainer
	_check(panel != null and panel.is_visible_in_tree(), "%s should remain visible at %s" % [panel_name, viewport_size], failures)
	if panel != null:
		var panel_rect := panel.get_global_rect()
		_check(
			panel_rect.position.x >= -0.5 and panel_rect.end.x <= viewport_size.x + 0.5,
			"%s should stay horizontally inside %s (rect=%s)" % [panel_name, viewport_size, panel_rect],
			failures,
		)
	if modal_scroll != null:
		var scroll_rect := modal_scroll.get_global_rect()
		_check(
			scroll_rect.position.x >= -0.5 and scroll_rect.end.x <= viewport_size.x + 0.5
			and scroll_rect.position.y >= -0.5 and scroll_rect.end.y <= viewport_size.y + 0.5,
			"modal scroll viewport should remain bounded at %s" % viewport_size,
			failures,
		)
		_check(
			modal_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
			"campaign cards should never require horizontal scrolling at %s" % viewport_size,
			failures,
		)
	if badge != null:
		var badge_rect := badge.get_global_rect()
		_check(
			badge_rect.position.x >= -0.5 and badge_rect.end.x <= viewport_size.x + 0.5,
			"probation badge should stay horizontally visible at %s" % viewport_size,
			failures,
		)


func _check_title_character_layout(
	title_panel: PanelContainer,
	profile_card: PanelContainer,
	profile_labels: Array,
	new_button: Button,
	viewport_size: Vector2,
	failures: Array[String],
) -> void:
	if title_panel == null or profile_card == null or new_button == null:
		return
	var panel_rect := title_panel.get_global_rect()
	var profile_rect := profile_card.get_global_rect()
	_check(
		profile_rect.position.x >= panel_rect.position.x - 0.5
		and profile_rect.end.x <= panel_rect.end.x + 0.5,
		"Mabel profile should stay inside the title panel at %s" % viewport_size,
		failures,
	)
	for label_value in profile_labels:
		var label := label_value as Label
		if label == null:
			continue
		var label_rect := label.get_global_rect()
		_check(
			label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
			and label_rect.position.x >= profile_rect.position.x - 0.5
			and label_rect.end.x <= profile_rect.end.x + 0.5,
			"%s should wrap inside Mabel's profile at %s" % [label.name, viewport_size],
			failures,
		)
	var button_rect := new_button.get_global_rect()
	_check(
		button_rect.position.x >= panel_rect.position.x - 0.5
		and button_rect.end.x <= panel_rect.end.x + 0.5,
		"Mabel title action should stay inside the panel at %s" % viewport_size,
		failures,
	)
