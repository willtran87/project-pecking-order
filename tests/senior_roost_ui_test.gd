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
	_check(dividend != null and "SCORE  //  EDGE FLOCK WELFARE + QUOTA RELIABILITY" in dividend.text, "Senior policy cards should connect their effects to exact quarter score lanes", failures)
	_check(dividend != null and "BOARD  //  EDGE RELIABLE CLUTCH + FLOCK CONTINUITY" in dividend.text, "Senior policy cards should disclose direct annual mandate fit", failures)
	_check(forecast != null and "WATCH QUOTA RELIABILITY + FLOCK WELFARE + OBEDIENCE" in forecast.text, "Senior policy cards should name their scored risks before filing", failures)
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

	# Advanced annual Books own permanent career risk. Selecting one should only
	# stage the exact stake; the existing Continue action must confirm it.
	observed["chosen"] = &""
	ui.show_between_shift_report(_advanced_mandate_snapshot())
	await process_frame
	await process_frame
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
