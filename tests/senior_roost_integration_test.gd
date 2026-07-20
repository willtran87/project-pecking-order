extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const TEST_SAVE_FILENAME := "senior_roost_integration_test.json"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	store.delete()
	var office := Office.new()
	office.set("_campaign_store", store)
	office.set("_allow_automated_campaign_saves", true)
	root.add_child(office)
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var campaign := _passing_campaign(failures)
	office.set("_campaign_state", campaign)
	office.set("_last_workday_report", _probation_report(5, 5))
	office.set("_campaign_senior_roost", false)
	simulation.pending_decision.clear()
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.day = 6
	office.call("_show_campaign_final_review")
	await process_frame
	var audio_feedback := office.get("_audio_feedback") as OfficeAudioFeedback
	var verdict_audio := audio_feedback.feedback_snapshot() if audio_feedback != null else {}
	var final_continue := office.find_child("FinalContinueCampaignButton", true, false) as Button
	_check(campaign.outcome == CampaignState.OUTCOME_PASSED, "fixture should reach an authentic passed probation record", failures)
	_check(String(verdict_audio.get("last_cue", "")) == "campaign_pass", "production final review should synchronize the passed verdict cadence", failures)
	_check(final_continue != null and final_continue.is_visible_in_tree(), "passed probation should expose Senior Roost continuation", failures)
	_press(final_continue)
	await process_frame
	await process_frame

	var senior: SeniorRoostState = office.get("_senior_roost_state") as SeniorRoostState
	var report := office.find_child("ProbationReportPanel", true, false) as PanelContainer
	var report_heading := office.find_child("ProbationReportTitle", true, false) as Label
	var report_objective_title := office.find_child("NextShiftObjective", true, false) as Label
	var report_objective_body := office.find_child("NextShiftObjectiveDescription", true, false) as Label
	var report_objective_progress := office.find_child("NextShiftObjectiveProgress", true, false) as Label
	var hen_highlight_card := office.find_child("ShiftHenHighlightCard", true, false) as PanelContainer
	var board_seals_value := office.find_child("ReportLedgerValue2", true, false) as Label
	var quarter_score_value := office.find_child("ReportLedgerValue3", true, false) as Label
	var continue_button := office.find_child("ContinueProbationButton", true, false) as Button
	var policy_cards := office.find_children("MilestoneChoice_*", "Button", true, false)
	_check(bool(office.get("_campaign_senior_roost")), "successful continuation should enter the real Senior mode", failures)
	_check(senior != null and senior.status == SeniorRoostState.STATUS_QUARTER_CHOICE, "Senior entry should open the first annual planning gate", failures)
	_check(senior != null and senior.requires_annual_mandate(), "Senior entry should require one frozen annual Board Mandate before Q1 policy", failures)
	_check(senior.last_recorded_day == 5, "Senior ledger should begin immediately after the fifth probation shift", failures)
	_check(campaign.completed_shifts == 5, "Senior entry must not mutate the immutable probation record", failures)
	_check(report != null and report.is_visible_in_tree() and policy_cards.size() == 3, "Senior entry should open exactly three visible annual mandate cards", failures)
	_check(continue_button != null and continue_button.disabled, "first Senior shift must remain gated until annual terms and a policy are filed", failures)
	_check(report_heading != null and "ANNUAL BOARD MANDATE" in report_heading.text, "entry report should explain the year-long Board decision", failures)
	_check(
		board_seals_value != null and board_seals_value.text == "0",
		"Board Seals should render as a permanent count rather than Feed Fund currency",
		failures,
	)
	var senior_commendations := office.commendations_snapshot()
	_check(
		"senior_transfer" in (senior_commendations.get("earned_ids", []) as Array),
		"entering Senior Roost should immediately stamp the permanent transfer commendation",
		failures,
	)
	var senior_visible_text := _visible_text(office)
	_check(senior_visible_text.find("probation") == -1, "visible Senior filing should not leak probation language: %s" % _matching_lines(senior_visible_text, "probation"), failures)
	_check("no mark stake" in senior_visible_text and "targets" in senior_visible_text and "seal" in senior_visible_text, "annual mandate cards should disclose fallback stake, targets, and permanent seal rewards", failures)

	var standard_book := office.find_child("MilestoneChoice_standard_board_book", true, false) as Button
	_check(standard_book != null and not standard_book.disabled, "Standard Board Book should guarantee an available no-stake annual fallback", failures)
	_press(standard_book)
	await process_frame
	await process_frame
	senior = office.get("_senior_roost_state") as SeniorRoostState
	policy_cards = office.find_children("MilestoneChoice_*", "Button", true, false)
	continue_button = office.find_child("ContinueProbationButton", true, false) as Button
	_check(not senior.requires_annual_mandate() and senior.requires_quarter_policy(), "filing annual terms should advance to the separate Q1 policy gate", failures)
	_check(StringName(senior.active_annual_mandate().get("id", "")) == SeniorRoostState.MANDATE_FALLBACK_ID, "annual mandate intent should reach the authoritative career ledger", failures)
	_check(policy_cards.size() == 3 and continue_button.disabled, "annual acceptance should immediately show three quarterly capital choices while preserving the gate", failures)
	_check(report_heading != null and "QUARTER 1 CAPITAL FILING" in report_heading.text, "accepted annual terms should visibly orient the Q1 policy decision", failures)
	var dividend := office.find_child("MilestoneChoice_flock_dividend", true, false) as Button
	_check(dividend != null and "SCORE  //  EDGE FLOCK WELFARE + QUOTA RELIABILITY" in dividend.text, "generated Senior policy cards should disclose quarter score fit", failures)
	_check(dividend != null and "BOARD  //  EDGE RELIABLE CLUTCH + FLOCK CONTINUITY" in dividend.text and "WATCH CURRENT PAYROLL" in dividend.text, "generated Senior policy cards should disclose active Board Mandate fit and risk", failures)
	var mandate_envelope := store.load()
	var mandate_payload := mandate_envelope.get("campaign", {}) as Dictionary
	var mandate_state := SeniorRoostState.from_dictionary(mandate_payload.get("senior_roost", {}) as Dictionary)
	_check(mandate_state != null and StringName(mandate_state.active_annual_mandate().get("id", "")) == SeniorRoostState.MANDATE_FALLBACK_ID, "annual mandate selection should checkpoint immediately", failures)

	var fund_before := simulation.revenue_cents
	var quota_before := simulation.quota_target
	var forecast := office.find_child("MilestoneChoice_harvest_forecast", true, false) as Button
	_check(forecast != null and not forecast.disabled, "forecast should guarantee a no-cost policy fallback", failures)
	_press(forecast)
	await process_frame
	senior = office.get("_senior_roost_state") as SeniorRoostState
	continue_button = office.find_child("ContinueProbationButton", true, false) as Button
	_check(senior.status == SeniorRoostState.STATUS_ACTIVE and senior.active_policy_id == &"harvest_forecast", "policy intent should reach the authoritative career state", failures)
	_check(simulation.revenue_cents == fund_before + 6000 and simulation.quota_target == quota_before + 2, "policy should apply its exact authoritative liquidity and quota effects once", failures)
	_check(continue_button != null and not continue_button.disabled and "BEGIN QUARTER" in continue_button.text, "accepted policy should expose the first Senior shift action", failures)
	var selected_envelope := store.load()
	var selected_payload := selected_envelope.get("campaign", {}) as Dictionary
	var selected_state := SeniorRoostState.from_dictionary(selected_payload.get("senior_roost", {}) as Dictionary)
	_check(selected_state != null and selected_state.active_policy_id == &"harvest_forecast" and StringName(selected_state.active_annual_mandate().get("id", "")) == SeniorRoostState.MANDATE_FALLBACK_ID, "policy selection should checkpoint both the quarter policy and annual terms immediately", failures)

	_press(continue_button)
	await process_frame
	_check(campaign_ui.modal_state() == ProbationCampaignUI.VIEW_CONTRACT_BOARD, "Senior continuation should route through the recurring Farm Mutual planning file", failures)
	var decline_contract := office.find_child("DeclineContractButton", true, false) as Button
	_check(decline_contract != null and decline_contract.is_visible_in_tree() and not decline_contract.disabled, "Senior planning should retain the explicit no-contract fallback", failures)
	_press(decline_contract)
	await process_frame
	var open_contract_shift := office.find_child("OpenContractShiftButton", true, false) as Button
	_check(open_contract_shift != null and not open_contract_shift.disabled, "standard-book receipt should authorize the Senior morning briefing", failures)
	_press(open_contract_shift)
	await process_frame
	_check(campaign_ui.modal_state() == ProbationCampaignUI.VIEW_ACTIVE, "filed policy should return to the playable office", failures)
	_check(simulation.day == 6 and simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE, "Senior continuation should open the next real simulation briefing", failures)
	_check((office.find_child("ProbationDayLabel", true, false) as Label).text == "Y1 · Q1 · SHIFT 1 / 3", "active badge should expose the three-shift quarter cadence", failures)

	# Feed three chronological workday signals through Office. Each signal enters
	# the Senior ledger once, while the final signal closes the quarter.
	for senior_day in [6, 7, 8]:
		simulation.pending_decision.clear()
		# This focused fixture emits Office's workday signal directly instead of
		# running DepartmentSimulation._complete_workday(), so mirror the real
		# boundary cleanup for the explicit no-contract planning receipt.
		simulation.market_contract_decline_receipt.clear()
		simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
		simulation.day = senior_day + 1
		simulation.workday_completed.emit(_senior_report(senior_day, senior_day - 5))
		await process_frame
		senior = office.get("_senior_roost_state") as SeniorRoostState
		_check(senior.total_senior_shifts == senior_day - 5, "day %d should create exactly one Senior record" % senior_day, failures)
		if senior_day < 8:
			office.call("_advance_after_closing_credit")
			await process_frame
			_check(not (office.find_child("ContinueProbationButton", true, false) as Button).disabled, "in-quarter shift report should permit next-shift planning", failures)
			_check(hen_highlight_card != null and hen_highlight_card.is_visible_in_tree(), "in-quarter shift %d should retain its named-hen story receipt" % (senior_day - 5), failures)

	office.call("_advance_after_closing_credit")
	await process_frame
	await process_frame
	senior = office.get("_senior_roost_state") as SeniorRoostState
	policy_cards = office.find_children("MilestoneChoice_*", "Button", true, false)
	continue_button = office.find_child("ContinueProbationButton", true, false) as Button
	_check(senior.completed_quarters == 1 and senior.status == SeniorRoostState.STATUS_QUARTER_CHOICE, "third Senior shift should close one scored quarter and gate the next policy", failures)
	_check(int(senior.last_quarter_review.get("score", -1)) == 100 and senior.roost_marks == 3, "three strong shifts should yield the exact perfect-quarter promotion reward", failures)
	var closed_breakdown := senior.snapshot().get("last_quarter_score_breakdown", {}) as Dictionary
	_check(int(closed_breakdown.get("score", -1)) == 100 and (closed_breakdown.get("components", []) as Array).size() == 7, "quarter report should derive the exact seven-part closing score receipt", failures)
	_check(report_objective_title != null and "REWARD RECEIPT" in report_objective_title.text, "quarter gate should foreground the earned reward before the next policy", failures)
	_check(report_objective_body != null and "FILED SCORE" in report_objective_body.text and "CREDIT LEADERS" in report_objective_body.text and "TOP MARK TIER" in report_objective_body.text, "perfect quarter receipt should connect score, strongest components, and remaining opportunity", failures)
	_check(report_objective_progress != null and "BOARD 2 / 3 TARGETS MET" in report_objective_progress.text and "NEXT RELIABLE CLUTCH 3 / 6" in report_objective_progress.text, "later-quarter planning should expose the live annual target count and largest remaining blocker", failures)
	_check(hen_highlight_card != null and not hen_highlight_card.is_visible_in_tree(), "quarter planning should retire the previous shift highlight so policy controls retain the visual hierarchy", failures)
	_check(quarter_score_value != null and quarter_score_value.text == "100", "closed quarter score should render as points rather than inheriting a percent format", failures)
	var mandate_progress := senior.current_annual_mandate_progress()
	var mandate_checkpoint := senior.last_quarter_review.get("annual_mandate_checkpoint", {}) as Dictionary
	_check(int(mandate_progress.get("shifts_recorded", -1)) == 3 and int(mandate_checkpoint.get("shifts_recorded", -1)) == 3, "quarter close should preserve a three-of-twelve annual mandate checkpoint", failures)
	_check(not senior.requires_annual_mandate() and StringName(senior.active_annual_mandate().get("id", "")) == SeniorRoostState.MANDATE_FALLBACK_ID, "quarter two should retain the same year-long mandate instead of asking again", failures)
	_check(policy_cards.size() == 3 and continue_button.disabled, "quarter close should restore the three-choice capital gate", failures)
	_check("QUARTER 2 CAPITAL FILING" in report_heading.text, "quarter close should visibly orient the next recurring cycle", failures)
	_check(StringName(office.get("_campaign_review_stage")) == &"senior_quarter", "quarter gate should have its own restorable review stage", failures)

	var quarter_envelope := store.load()
	var quarter_payload := quarter_envelope.get("campaign", {}) as Dictionary
	var quarter_state := SeniorRoostState.from_dictionary(quarter_payload.get("senior_roost", {}) as Dictionary)
	_check(quarter_state != null and quarter_state.completed_quarters == 1 and quarter_state.status == SeniorRoostState.STATUS_QUARTER_CHOICE, "quarter checkpoint should round-trip the recurring gate", failures)
	_check(String((quarter_envelope.get("metadata", {}) as Dictionary).get("review_stage", "")) == "senior_quarter", "checkpoint metadata should resume at the visible Senior report", failures)

	office.free()
	await process_frame
	var restored_office := Office.new()
	restored_office.set("_campaign_store", store)
	restored_office.set("_allow_automated_campaign_saves", true)
	root.add_child(restored_office)
	await process_frame
	await process_frame
	restored_office.call("_load_campaign_checkpoint")
	await process_frame
	await process_frame
	var restored_senior := restored_office.get("_senior_roost_state") as SeniorRoostState
	var restored_ui := restored_office.get("_campaign_ui") as ProbationCampaignUI
	_check(restored_senior != null and restored_senior.to_dictionary() == quarter_state.to_dictionary(), "Continue should restore the complete Senior career without drift", failures)
	_check(restored_ui.modal_state() == ProbationCampaignUI.VIEW_REPORT and restored_office.find_children("MilestoneChoice_*", "Button", true, false).size() == 3, "Continue should reopen the exact quarterly policy gate", failures)
	_check(bool(restored_office.get("_campaign_senior_roost")), "restored Senior mode should derive from the validated career state", failures)

	(restored_office.get("_clock") as SimulationClock).set_speed(0)
	restored_office.free()
	await process_frame
	var cleaned := store.delete()
	_check(cleaned and not store.has_save(), "isolated Senior integration checkpoints should be cleaned up", failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("SENIOR_ROOST_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SENIOR_ROOST_INTEGRATION_TEST_PASSED handoff=final-to-mandate-to-policy mandate=3-of-12 effects=exact shifts=3x1 quarter=scored save=round-trip restore=visible-gate")
	quit(0)


func _passing_campaign(failures: Array[String]) -> CampaignState:
	var campaign := CampaignState.new()
	var closing_fund := CampaignState.DEFAULT_OPENING_FUND_CENTS
	var rework_total := 0
	for day in range(1, CampaignState.CAMPAIGN_LENGTH + 1):
		if day == 3:
			_check(campaign.choose_milestone(&"shell_quality_lab"), "passing fixture should file its required milestone", failures)
		var credited := 8500 + day * 100
		closing_fund += credited - 1800
		var result := campaign.record_shift(
			_probation_report(day, rework_total, closing_fund, credited),
			{"welfare": 75, "compliance": 82, "executive_confidence": 70},
		)
		_check(bool(result.get("accepted", false)), "passing fixture shift %d should file" % day, failures)
	return campaign


func _probation_report(day: int, rework_total: int, closing_fund: int = 40_000, credited: int = 9000) -> Dictionary:
	return {
		"day": day,
		"eggs": 28,
		"quota": 24,
		"met_quota": true,
		"cracked": 1,
		"golden": 0,
		"quota_bonus_cents": 1000,
		"quality_bonus_cents": 500,
		"feed_cost_cents": 1800,
		"overdue_claims": 0,
		"rework_waiting": 0,
		"rework_due_next_shift": 0,
		"rework_total_created": rework_total,
		"closing_fund_cents": closing_fund,
		"credited_cents": credited,
	}


func _senior_report(day: int, rework_total: int) -> Dictionary:
	return {
		"day": day,
		"eggs": 30,
		"quota": 24,
		"met_quota": true,
		"cracked": 2,
		"golden": 0,
		"quota_bonus_cents": 0,
		"quality_bonus_cents": 0,
		"feed_cost_cents": 1800,
		"credited_cents": 12_000,
		"welfare": 72,
		"compliance": 76,
		"farmer_favor": 66,
		"wage_arrears_cents": 0,
		"overdue_claims": 0,
		"rework_waiting": 0,
		"rework_due_next_shift": 0,
		"rework_total_created": rework_total,
		"closing_fund_cents": 20_000 + day * 100,
		"credit_memo_required": false,
		"pecking_order": [],
		"hen_highlight": {
			"day": day,
			"worker_name": "Dot",
			"career_title": "Appeals Hen",
			"relationship_label": "Trusted",
			"headline": "Resilience Opportunity",
			"body": "Dot converted a difficult file into a learning opportunity.",
			"metric": "7 EGGS  //  4 SOUND",
			"tone": "quality",
		},
	}


func _visible_text(root_node: Node) -> String:
	var parts: Array[String] = []
	for node: Node in root_node.find_children("*", "", true, false):
		if node is Label and (node as Label).is_visible_in_tree():
			parts.append((node as Label).text.to_lower())
		elif node is Button and (node as Button).is_visible_in_tree():
			parts.append((node as Button).text.to_lower())
	return "\n".join(parts)


func _matching_lines(text: String, needle: String) -> String:
	var matches: Array[String] = []
	for line in text.split("\n"):
		if needle in line:
			matches.append(line)
	return " | ".join(matches)


func _press(button: Button) -> void:
	if button != null and not button.disabled:
		button.pressed.emit()


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
