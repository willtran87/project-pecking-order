extends SceneTree

const ProbationCampaignUIScript := preload("res://features/office/probation_campaign_ui.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observed := {"chosen": &"", "continued": 0}
	var harness := Control.new()
	harness.name = "SeniorRoostUITestHarness"
	harness.size = Vector2(1280.0, 720.0)
	root.add_child(harness)
	var ui = ProbationCampaignUIScript.new()
	harness.add_child(ui)
	ui.milestone_choice.connect(func(choice_id: StringName) -> void: observed["chosen"] = choice_id)
	ui.continue_campaign.connect(func() -> void: observed["continued"] = int(observed["continued"]) + 1)
	await process_frame

	ui.show_between_shift_report(_quarter_policy_snapshot())
	await process_frame
	await process_frame
	var report := ui.find_child("ProbationReportPanel", true, false) as PanelContainer
	var kicker := ui.find_child("ProbationReportDay", true, false) as Label
	var heading := ui.find_child("ProbationReportTitle", true, false) as Label
	var ledger_title := ui.find_child("ReportLedgerSectionTitle", true, false) as Label
	var choice_title := ui.find_child("MilestoneChoiceSectionTitle", true, false) as Label
	var continue_button := ui.find_child("ContinueProbationButton", true, false) as Button
	var merit := ui.find_child("MilestoneChoice_merit_grants", true, false) as Button
	var dividend := ui.find_child("MilestoneChoice_flock_dividend", true, false) as Button
	var forecast := ui.find_child("MilestoneChoice_harvest_forecast", true, false) as Button
	_check(report != null and report.is_visible_in_tree(), "Senior policy filing should reuse the full report surface", failures)
	_check(kicker != null and "YEAR 1" in kicker.text and "QUARTER 1" in kicker.text, "Senior report should orient the player within the career calendar", failures)
	_check(heading != null and heading.text == "QUARTER 1 CAPITAL FILING", "Senior report heading should be authored by its snapshot", failures)
	_check(ledger_title != null and ledger_title.text == "SENIOR CAREER LEDGERS", "Senior report should name career ledgers without probation copy", failures)
	_check(choice_title != null and "CAPITAL POLICY" in choice_title.text, "quarter gate should explain the decision class", failures)
	_check(_visible_text(ui).find("probation") == -1, "visible Senior UI must not leak probation wording", failures)
	_check(merit != null and merit.disabled and "$2.00 more" in merit.tooltip_text, "unaffordable policies should be visibly disabled with an exact reserve explanation", failures)
	_check(dividend != null and dividend.disabled, "every underfunded policy should remain non-interactive", failures)
	_check(forecast != null and not forecast.disabled and forecast.focus_mode == Control.FOCUS_ALL, "the no-cost fallback should remain keyboard accessible", failures)
	_check(continue_button != null and continue_button.disabled, "a quarter must remain gated until an available policy is filed", failures)
	if merit != null:
		merit.pressed.emit()
	_check(StringName(observed["chosen"]) == &"", "disabled policy activation must be ignored even when signaled directly", failures)
	if forecast != null:
		forecast.pressed.emit()
	await process_frame
	_check(StringName(observed["chosen"]) == &"harvest_forecast", "available policy should emit its stable domain ID", failures)
	_check(continue_button != null and not continue_button.disabled, "filing a policy should unlock the quarter", failures)
	_check(ui.selected_milestone_id() == &"harvest_forecast", "selected policy should remain visibly persistent", failures)

	harness.size = Vector2(390.0, 844.0)
	await process_frame
	await process_frame
	var report_rect := report.get_global_rect()
	_check(report_rect.position.x >= -0.5 and report_rect.end.x <= 390.5, "Senior policy report should stay inside a 390px portrait viewport (rect=%s)" % report_rect, failures)
	var scroll := ui.find_child("ProbationModalScroll", true, false) as ScrollContainer
	_check(scroll != null and scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Senior reports should never require horizontal scrolling", failures)

	harness.size = Vector2(1280.0, 720.0)
	ui.show_between_shift_report(_annual_review_snapshot())
	await process_frame
	await process_frame
	_check(heading.text == "YEAR 1 ANNUAL ROOST REVIEW", "annual review should use distinct authored copy", failures)
	_check(not (ui.find_child("MilestoneChoiceSection", true, false) as VBoxContainer).is_visible_in_tree(), "annual review should not present a quarterly policy gate", failures)
	_check(continue_button.text == "BEGIN YEAR 2  [C]" and not continue_button.disabled, "annual review should offer an explicit next-year action", failures)
	_check(_visible_text(ui).find("probation") == -1, "annual Senior UI must remain free of probation copy", failures)
	continue_button.pressed.emit()
	_check(int(observed["continued"]) == 1, "annual continuation should reuse the public campaign intent", failures)

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
		"rank": "Senior Claims Rooster",
		"ledgers": [
			{"label": "ROOST MARKS", "value": 0, "detail": "CAREER TOTAL"},
			{"label": "FEED FUND", "value": 1000, "format": "currency_cents", "detail": "SPENDABLE"},
			{"label": "YEARS PASSED", "value": 0, "detail": "ANNUAL REVIEWS"},
		],
		"next_objective": {
			"title": "FILE A CAPITAL POLICY",
			"description": "The quarter cannot open until management accepts a tradeoff.",
		},
		"milestone_choices": [
			{
				"id": "merit_grants",
				"title": "Merit Grants",
				"description": "Concentrate development money on the top hen.",
				"effect": "-$12.00 / top hen development",
				"available": false,
				"unavailable_reason": "$2.00 more spendable Feed Fund is required.",
			},
			{
				"id": "flock_dividend",
				"title": "Flock Dividend",
				"description": "Return part of the harvest to every employed hen.",
				"effect": "-$24.00 / flock strain down",
				"available": false,
				"unavailable_reason": "$14.00 more spendable Feed Fund is required.",
			},
			{
				"id": "harvest_forecast",
				"title": "Executive Harvest Forecast",
				"description": "Book future confidence as present Feed Fund.",
				"effect": "+$24.00 / quota pressure up",
				"available": true,
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
