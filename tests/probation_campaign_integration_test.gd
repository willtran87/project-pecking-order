extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const TEST_SAVE_FILENAME := "probation_campaign_integration_test.json"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	store.delete()

	# Inject the isolated store before _ready(), so Office exercises its real
	# checkpoint wiring without reading or replacing the player's campaign file.
	var office := Office.new()
	office.set("_campaign_store", store)
	office.set("_allow_automated_campaign_saves", true)
	root.add_child(office)
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	var campaign: CampaignState = office.get("_campaign_state") as CampaignState
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var audio_feedback := office.get("_audio_feedback") as OfficeAudioFeedback
	var day_badge := office.find_child("ProbationDayLabel", true, false) as Label
	var objectives_label := office.find_child("CampaignObjectivesLabel", true, false) as Label
	var safeguards_label := office.find_child("CampaignSafeguardForecast", true, false) as Label
	var safeguard_glance := office.find_child("CampaignSafeguardGlance", true, false) as Label
	var doctrine_label := office.find_child("CampaignActiveDoctrine", true, false) as Label
	var review_scrim := office.find_child("DayReviewScrim", true, false) as ColorRect
	var next_shift_button := office.find_child("BeginNextShiftButton", true, false) as Button
	var report_panel := office.find_child("ProbationReportPanel", true, false) as PanelContainer
	var report_heading := office.find_child("ProbationReportTitle", true, false) as Label
	var report_shift_delta := office.find_child("ReportShiftDelta", true, false) as Label
	var report_shift_delta_caption := office.find_child("ReportShiftDeltaCaption", true, false) as Label
	var report_shift_delta_icon := office.find_child("ReportShiftDeltaIcon", true, false) as TextureRect
	var report_rank_icon := office.find_child("ReportRankIcon", true, false) as TextureRect
	var report_rank_caption := office.find_child("ReportRankCaption", true, false) as Label
	var report_rank_progress := office.find_child("ReportRankProgress", true, false) as ProgressBar
	var objective_reward_badge := office.find_child("NextShiftObjectiveRewardBadge", true, false) as PanelContainer
	var objective_promotion_icon := office.find_child("NextShiftObjectivePromotionIcon", true, false) as TextureRect
	var report_receipt_summary := office.find_child("ReportScoreReceiptSummary", true, false) as Label
	var report_receipt_grid := office.find_child("ReportScoreReceiptGrid", true, false) as GridContainer
	var report_strategy_card := office.find_child("ReportStrategyReceipt", true, false) as PanelContainer
	var report_strategy_icon := office.find_child("ReportStrategyPolicyIcon", true, false) as FlockwatchIconBadge
	var report_strategy_outcome := office.find_child("ReportStrategyOutcome", true, false) as Label
	var report_strategy_policy := office.find_child("ReportStrategyPolicy", true, false) as Label
	var report_strategy_forecast := office.find_child("ReportStrategyForecast", true, false) as Label
	var report_strategy_actual := office.find_child("ReportStrategyActual", true, false) as Label
	var report_market_card := office.find_child("ReportMarketPulse", true, false) as PanelContainer
	var report_market_icon := office.find_child("ReportMarketPulseIcon", true, false) as FlockwatchIconBadge
	var report_market_kicker := office.find_child("ReportMarketPulseKicker", true, false) as Label
	var report_market_season := office.find_child("ReportMarketPulseSeason", true, false) as Label
	var report_market_signal := office.find_child("ReportMarketPulseSignal", true, false) as Label
	var report_score_row := office.find_child("ProbationReportScoreRow", true, false) as HFlowContainer
	var report_score := office.find_child("ReportScore", true, false) as Label
	var report_details_toggle := office.find_child("ReportDetailsToggle", true, false) as Button
	var report_details_section := office.find_child("ReportDetailsSection", true, false) as VBoxContainer
	var hen_highlight_card := office.find_child("ShiftHenHighlightCard", true, false) as PanelContainer
	var hen_highlight_eyebrow := office.find_child("ShiftHenHighlightEyebrow", true, false) as Label
	var hen_highlight_headline := office.find_child("ShiftHenHighlightHeadline", true, false) as Label
	var hen_highlight_body := office.find_child("ShiftHenHighlightBody", true, false) as Label
	var hen_highlight_metric := office.find_child("ShiftHenHighlightMetric", true, false) as Label
	var report_objective := office.find_child("NextShiftObjectiveDescription", true, false) as Label
	var decision_host := office.find_child("ManagementDecisionHost", true, false) as Control
	var decision_confirm := office.find_child("ConfirmDecisionButton", true, false) as Button
	var ticker := office.get("_ticker_label") as Label
	var character_dialogue_ui = office.get("_character_dialogue_ui")
	var flockwatch_navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	var capital_blueprint_ui = office.get("_capital_blueprint_ui")
	var staffing_ui := office.get("_staffing_ui") as RoostStaffingUI
	var economic_briefing_ui = office.get("_economic_briefing_ui")
	var shift_help_toggle = office.get("_shift_help_disclosure_toggle")
	var upgrade_toggle = office.get("_upgrade_disclosure_toggle")
	var commendations_toggle = office.get("_commendations_disclosure_toggle")

	_check(simulation != null and campaign != null and campaign_ui != null, "headless Office should boot all authoritative campaign collaborators", failures)
	_check(
		_signal_routes_to(
			campaign_ui,
			&"challenge_contract_changed",
			office,
			&"_on_campaign_challenge_contract_changed",
		),
		"challenge selection changes should route immediately to Office's Web diagnostic publisher",
		failures,
	)
	_check(
		_signal_routes_to(
			campaign_ui,
			&"report_filing_settled",
			office,
			&"_on_campaign_report_filing_settled",
		),
		"a settled report filing should route one semantic receipt to Office audio",
		failures,
	)
	_check(DisplayServer.get_name() == "headless", "focused integration test must run through the headless Office branch", failures)
	_check(campaign_ui != null and campaign_ui.modal_state() == ProbationCampaignUI.VIEW_ACTIVE, "headless Office should boot directly into an active campaign", failures)
	_check(campaign != null and campaign.outcome == CampaignState.OUTCOME_IN_PROGRESS and campaign.completed_shifts == 0, "headless Office should open a fresh five-shift probation state", failures)
	_check(
		day_badge != null and day_badge.text == "1 / 5"
		and day_badge.tooltip_text == "DAY 1 / 5",
		"calendar-led campaign presentation should expose shift 1 / 5 with exact semantic copy",
		failures,
	)
	_check(
		"FIRST CLUTCH" in String(day_badge.get_meta("accessible_text", "")),
		"the compact day badge should retain the current dramatic chapter in assistive detail",
		failures,
	)
	_check(_nonempty_lines(objectives_label.text if objectives_label != null else "").size() == 3, "active campaign presentation should show all three current objectives", failures)
	_check(
		safeguards_label != null and not safeguards_label.visible
		and safeguard_glance != null and safeguard_glance.visible
		and _contains_all(safeguard_glance.text, ["1 / 5 SAFE", "WELFARE", "NEEDS 45"])
		and "SAFEGUARD" in String(safeguard_glance.get_meta("accessible_text", "")),
		"office Flockwatch should expose a glance tile while retaining the exact pass count and normalized blocker (tile: %s)" % (
			safeguard_glance.text if safeguard_glance != null else "<missing>"
		),
		failures,
	)
	_check(
		safeguard_glance != null
		and _contains_all(safeguard_glance.tooltip_text, [
			"PROBATION FINAL TERMS", "PROBATION SCORE  //  50 >= 60",
			"WELFARE  //  0 >= 45", "COMPLIANCE  //  0 >= 55",
			"FARMER FAVOR  //  0 >= 50", "CRACK RATE  //  0.00% <= 25.00%",
		]),
		"Flockwatch tooltip should publish all five exact final thresholds",
		failures,
	)

	# Exercise the same title path and New Campaign action used in production. The
	# challenge selection is presentation-owned until Office files it atomically
	# into the new authoritative campaign and verified checkpoint.
	office.call("_show_campaign_title", false)
	await process_frame
	var customize_button := office.find_child("CustomizeCampaignButton", true, false) as Button
	_press(customize_button)
	await process_frame
	var challenge_selector := office.find_child("ChallengeContractSelector", true, false) as OptionButton
	var challenge_summary := office.find_child("ChallengeContractSummary", true, false) as Label
	var challenge_fund := office.find_child("ChallengeOpeningFund", true, false) as Label
	var challenge_quota := office.find_child("ChallengeOpeningQuota", true, false) as Label
	var challenge_files := office.find_child("ChallengeOpeningFiles", true, false) as Label
	var supported_index := -1
	if challenge_selector != null:
		for index: int in range(challenge_selector.item_count):
			if StringName(String(challenge_selector.get_item_metadata(index))) == CampaignState.CHALLENGE_SUPPORTED_FLOCK:
				supported_index = index
				break
	_check(
		challenge_selector != null and challenge_selector.item_count == 3 and supported_index >= 0,
		"production intake should expose all three authoritative filing standards",
		failures,
	)
	if challenge_selector != null and supported_index >= 0:
		challenge_selector.select(supported_index)
		challenge_selector.item_selected.emit(supported_index)
	_check(
		campaign_ui.selected_challenge_contract_id() == CampaignState.CHALLENGE_SUPPORTED_FLOCK,
		"the title should retain the chosen new-file standard until Office accepts it",
		failures,
	)
	_check(
		challenge_summary != null
		and challenge_fund != null and challenge_fund.text == "$65"
		and challenge_quota != null and challenge_quota.text == "14"
		and challenge_files != null and challenge_files.text == "6",
		"production intake should disclose Supported Flock's key opening numbers before filing",
		failures,
	)
	var new_campaign_button := office.find_child("NewCampaignButton", true, false) as Button
	_press(new_campaign_button)
	await process_frame
	campaign = office.get("_campaign_state") as CampaignState
	simulation = office.get("_simulation") as DepartmentSimulation
	_check(campaign_ui.modal_state() == ProbationCampaignUI.VIEW_ACTIVE, "fresh start should return to the unobstructed office", failures)
	_check(
		campaign != null
		and campaign.challenge_contract_id == CampaignState.CHALLENGE_SUPPORTED_FLOCK
		and not campaign.select_challenge_contract(CampaignState.CHALLENGE_EXECUTIVE_AUDIT),
		"Office should file the selected standard once and keep it immutable for the career",
		failures,
	)
	_check(
		simulation != null
		and simulation.revenue_cents == 6500
		and int(simulation.farm_treasury_snapshot().get("cash_cents", -1)) == 6500
		and simulation.quota_target == 14
		and simulation.claims_waiting == 6,
		"Supported Flock should begin with its disclosed $65 fund, 14 quota, and six live files",
		failures,
	)
	_check(store.has_save(), "fresh start/reset should save a resumable checkpoint", failures)
	var fresh_return_summary := office.call("_campaign_resume_summary") as Dictionary
	var fresh_return_recap := fresh_return_summary.get("return_recap", {}) as Dictionary
	var fresh_offline_recap := fresh_return_summary.get("offline_recap", {}) as Dictionary
	_check(
		String(fresh_return_recap.get("last_filed_label", "")) == "NEW COOP FILE OPENED"
		and String(fresh_return_recap.get("status_label", "")) == "FEED COVERAGE"
		and "ration scoops are uncovered" in String(fresh_return_recap.get("status_reason", ""))
		and "Provisions" in String(fresh_return_recap.get("next_action", "")),
		"the production checkpoint should project a factual completed action, unresolved pressure, and recovery action",
		failures,
	)
	_check(
		String(fresh_offline_recap.get("status_label", "")) == "ECONOMY PAUSED"
		and "SINCE LAST FILE" in String(fresh_offline_recap.get("elapsed_label", ""))
		and "No files advanced" in String(fresh_offline_recap.get("detail", "")),
		"the real checkpoint should disclose that closed time has no economic accrual",
		failures,
	)
	var independent_store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	_check(independent_store.has_save(), "a new store instance should discover the fresh checkpoint", failures)
	var fresh_envelope := independent_store.load()
	var fresh_payload := fresh_envelope.get("campaign", {}) as Dictionary
	var fresh_campaign_data := fresh_payload.get("campaign", {}) as Dictionary
	var fresh_simulation_data := fresh_payload.get("simulation", {}) as Dictionary
	var fresh_campaign := CampaignState.from_dictionary(fresh_campaign_data)
	_check(not fresh_envelope.is_empty(), "fresh checkpoint should load through the production save envelope", failures)
	_check(String((fresh_envelope.get("metadata", {}) as Dictionary).get("reason", "")) == "new_campaign", "fresh checkpoint should disclose its reset reason", failures)
	_check(
		fresh_campaign != null
		and fresh_campaign.completed_shifts == 0
		and fresh_campaign.challenge_contract_id == CampaignState.CHALLENGE_SUPPORTED_FLOCK,
		"fresh checkpoint should preserve the filed standard before shift one",
		failures,
	)
	var restored_supported_simulation := DepartmentSimulation.new(9918, 4)
	_check(
		int(fresh_simulation_data.get("revenue_cents", -1)) == 6500
		and int(fresh_simulation_data.get("quota_target", -1)) == 14
		and restored_supported_simulation.restore_save_state(fresh_simulation_data)
		and restored_supported_simulation.revenue_cents == 6500
		and int(restored_supported_simulation.farm_treasury_snapshot().get("cash_cents", -1)) == 6500
		and restored_supported_simulation.quota_target == 14
		and restored_supported_simulation.claims_waiting == 6,
		"the verified new-campaign checkpoint should preserve the complete Supported opening economy",
		failures,
	)
	var fresh_session := fresh_payload.get("session", {}) as Dictionary
	var fresh_first_clutch := fresh_session.get("first_clutch", {}) as Dictionary
	var fresh_interface_context := (
		fresh_session.get("interface_context", {}) as Dictionary
	)
	_check(
		int(fresh_first_clutch.get("target_worker_id", -1)) == 0
		and not bool(fresh_first_clutch.get("inspected", true))
		and simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE
		and decision_host != null
		and not decision_host.visible,
		"fresh checkpoint should hold Mabel's pre-policy file without mutating the morning directive",
		failures,
	)
	_check(
		int(fresh_interface_context.get("version", -1)) == 2
		and String(fresh_interface_context.get("flockwatch_page_id", "")) == "today"
		and not bool(fresh_interface_context.get("show_all_filings", true))
		and String(fresh_interface_context.get("capital_filter_id", "")) == "ready"
		and not bool(fresh_interface_context.get("economic_details_expanded", true))
		and String(fresh_interface_context.get("farmgate_mandate_id", "")) == "farmer_pickup"
		and String(fresh_interface_context.get("capital_facility_id", "")) in [
			"",
			"candling_rework_bay",
		],
		"a new career checkpoint should start from a clean, reachable interface context (context=%s)" % str(
			fresh_interface_context
		),
		failures,
	)
	if flockwatch_navigation != null:
		flockwatch_navigation.set_show_all_filings(true)
		flockwatch_navigation.open_page(FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS)
	if capital_blueprint_ui != null:
		capital_blueprint_ui.call("apply_snapshot", simulation.snapshot())
		capital_blueprint_ui.call("set_filter", &"all")
		capital_blueprint_ui.call("select_facility", &"farm_mutual_service_coop", false)
	office.call("_on_status_history_toggled", true)
	if shift_help_toggle != null:
		shift_help_toggle.call("set_expanded", true)
	if upgrade_toggle != null:
		upgrade_toggle.call("set_expanded", true)
	if commendations_toggle != null:
		commendations_toggle.call("set_expanded", true)
	if economic_briefing_ui != null:
		economic_briefing_ui.call("set_details_expanded", true)
	if staffing_ui != null:
		staffing_ui.restore_presentation_context({
			"feed_offers_expanded": true,
			"farmgate_mandate_expanded": true,
			"farmgate_mandate_id": "regional_showcase",
			"flock_relations_cases_expanded": true,
			"farmer_campaigns_expanded": true,
			"inline_facilities_expanded": true,
		})
	var checkpoint_coordinator = office.get("_checkpoint_coordinator")
	if checkpoint_coordinator != null:
		checkpoint_coordinator.call("discard_pending")
	var feed_offers_toggle := office.find_child(
		"FeedProcurementOffersToggle",
		true,
		false,
	) as Button
	if feed_offers_toggle != null:
		# Exercise the same toggle signal emitted by pointer, touch, keyboard, and
		# controller activation. Restore setters intentionally remain silent.
		feed_offers_toggle.toggled.emit(false)
	var interface_checkpoint := office.call("_checkpoint_diagnostic_state") as Dictionary
	_check(
		bool(interface_checkpoint.get("dirty", false))
		and String(interface_checkpoint.get("reason", "")) == "interface_context_changed",
		"a player disclosure change should queue the bounded interface checkpoint",
		failures,
	)
	if feed_offers_toggle != null:
		feed_offers_toggle.toggled.emit(true)
	if character_dialogue_ui != null:
		character_dialogue_ui.clear_session()
	office.call("_on_campaign_abandon_requested")
	await process_frame
	_check(
		campaign_ui.modal_state() == ProbationCampaignUI.VIEW_TITLE,
		"shelving the fresh file should return to verified intake before resume",
		failures,
	)
	office.call("_on_campaign_continue_requested")
	await process_frame
	await process_frame
	_check(
		flockwatch_navigation != null
		and flockwatch_navigation.is_showing_all_filings()
		and flockwatch_navigation.current_page_id() == FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS
		and capital_blueprint_ui != null
		and StringName(capital_blueprint_ui.call("active_filter_id")) == &"all"
		and StringName(capital_blueprint_ui.call("selected_facility_id")) == &"farm_mutual_service_coop",
		"verified Continue should restore the career's page, filing scope, Blueprint filter, and selected parcel",
		failures,
	)
	var restored_staffing_context := (
		staffing_ui.presentation_context()
		if staffing_ui != null else
		{}
	)
	_check(
		bool(office.get("_status_history_expanded"))
		and shift_help_toggle != null and bool(shift_help_toggle.call("is_expanded"))
		and upgrade_toggle != null and bool(upgrade_toggle.call("is_expanded"))
		and commendations_toggle != null and bool(commendations_toggle.call("is_expanded"))
		and economic_briefing_ui != null
		and bool(economic_briefing_ui.call("details_expanded"))
		and bool(restored_staffing_context.get("feed_offers_expanded", false))
		and bool(restored_staffing_context.get("farmgate_mandate_expanded", false))
		and String(restored_staffing_context.get("farmgate_mandate_id", "")) == "regional_showcase"
		and bool(restored_staffing_context.get("flock_relations_cases_expanded", false))
		and bool(restored_staffing_context.get("farmer_campaigns_expanded", false))
		and bool(restored_staffing_context.get("inline_facilities_expanded", false)),
		"verified Continue should restore disclosure choices and the inspected Farmgate mandate",
		failures,
	)
	var return_dialogue: Dictionary = (
		character_dialogue_ui.active_entry()
		if character_dialogue_ui != null else
		{}
	)
	_check(
		StringName(return_dialogue.get("speaker_id", &"")) == &"henrietta"
		and "ration gap" in String(return_dialogue.get("text", ""))
		and String(return_dialogue.get("id", "")).begins_with("return_")
		and "Henrietta" in String(character_dialogue_ui.accessibility_text())
		and "ration gap" in String(character_dialogue_ui.accessibility_text()),
		"verified Continue should translate the saved Feed Coverage problem into Henrietta's return beat",
		failures,
	)
	var first_return_id := String(return_dialogue.get("id", ""))
	office.call("_on_campaign_abandon_requested")
	await process_frame
	office.call("_on_campaign_continue_requested")
	await process_frame
	await process_frame
	_check(
		String(character_dialogue_ui.active_entry().get("id", "")) == first_return_id
		and int(character_dialogue_ui.queued_count()) == 0,
		"reopening the same filed condition should not queue duplicate return dialogue",
		failures,
	)
	var prelude_button := office.find_child("FirstClutchReturnToHen", true, false) as Button
	_press(prelude_button)
	await process_frame
	await process_frame
	_check(decision_host != null and decision_host.visible, "opening Mabel's file should reveal the production policy modal", failures)
	var shell_assurance := office.find_child("DecisionOption_shell_assurance", true, false) as Button
	_press(shell_assurance)
	_press(decision_confirm)
	await process_frame
	await process_frame
	_check(
		simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
		and clock.speed_index == 0,
		"authorizing Mabel's opening policy should enter the shift while preserving the First Clutch pause",
		failures,
	)

	# Complete a real simulation boundary rather than invoking Office's handler.
	# Signal observation proves one shift completion produces one campaign record.
	var observed := {"workday_reports": 0, "last_workday_report": {}}
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		observed["workday_reports"] += 1
		observed["last_workday_report"] = report.duplicate(true)
	)
	_complete_representative_shift(simulation, clock, 6200)
	await process_frame
	campaign = office.get("_campaign_state") as CampaignState
	_check(int(observed["workday_reports"]) == 1, "representative shift should emit exactly one workday report", failures)
	_check(campaign.completed_shifts == 1 and campaign.shift_records.size() == 1, "Office should record the representative shift exactly once", failures)
	_check(review_scrim != null and review_scrim.visible, "recorded shift should open the blocking farmer review", failures)
	_check(StringName(office.get("_campaign_review_stage")) == &"farmer", "Office should checkpoint the farmer-review stage", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW and clock.speed_index == 0, "farmer review should retain the authoritative simulation review gate", failures)
	# An extra simulation tick while reviewing must not duplicate the record.
	simulation.advance_tick()
	_check(int(observed["workday_reports"]) == 1 and campaign.shift_records.size() == 1, "review-phase ticks must not double-record the shift", failures)

	var first_review_envelope := store.load()
	var first_review_payload := first_review_envelope.get("campaign", {}) as Dictionary
	var first_review_campaign := CampaignState.from_dictionary(first_review_payload.get("campaign", {}) as Dictionary)
	_check(first_review_campaign != null and first_review_campaign.completed_shifts == 1, "workday checkpoint should already contain the recorded shift", failures)
	_check(String((first_review_envelope.get("metadata", {}) as Dictionary).get("review_stage", "")) == "farmer", "workday checkpoint should resume at farmer review", failures)
	var review_return_summary := office.call("_campaign_resume_summary") as Dictionary
	var review_return_recap := review_return_summary.get("return_recap", {}) as Dictionary
	_check(
		String(review_return_recap.get("last_filed_label", "")) == "SHIFT 1 CLOSED"
		and not String(review_return_recap.get("status_label", "")).is_empty()
		and not String(review_return_recap.get("status_reason", "")).is_empty()
		and not String(review_return_recap.get("next_action", "")).is_empty(),
		"a closed shift should replace the resume action while retaining an authoritative economic recovery cue",
		failures,
	)

	# The physical farmer accounting intentionally precedes the probation report.
	_press(next_shift_button)
	await process_frame
	_check(not review_scrim.visible, "advancing should dismiss the farmer accounting", failures)
	_check(decision_host != null and decision_host.visible, "advancing should require a closing credit memo before probation review", failures)
	_check(StringName(office.get("_campaign_review_stage")) == &"credit", "Office should checkpoint the credit-memo stage", failures)
	_file_credit_memo(office, decision_confirm, failures)
	await process_frame
	_check(campaign_ui.modal_state() == ProbationCampaignUI.VIEW_REPORT, "advancing should open the probation report", failures)
	_check(report_panel != null and report_panel.is_visible_in_tree(), "probation report should be visibly presented", failures)
	_check(
		report_heading != null and "SHIFT 1 RESULTS  //  FIRST CLUTCH" in report_heading.text,
		"the first report should close the named First Clutch chapter instead of reading as a generic ledger",
		failures,
	)
	_check(
		day_badge.text == "1 / 5" and day_badge.tooltip_text == "DAY 1 / 5",
		"between-shift presentation should retain the exact reviewed day behind its compact calendar value",
		failures,
	)
	_check(_objective_bullets(report_objective.text if report_objective != null else "") == 3, "probation report should present all three next-shift objectives", failures)
	await create_timer(1.05).timeout
	var report_audio := audio_feedback.feedback_snapshot() if audio_feedback != null else {}
	_check(
		String(report_audio.get("last_cue", "")) == "report_filed"
		and String(report_audio.get("last_bus", "")) == "UI",
		"the complete report evidence sweep should end with one quiet UI filing receipt",
		failures,
	)

	# The report must disclose the exact causal score receipt from CampaignState and
	# the same character moment emitted by DepartmentSimulation, rather than
	# reconstructing either story independently in the presentation layer.
	var first_receipt := campaign.latest_score_receipt()
	var first_workday_report := observed.get("last_workday_report", {}) as Dictionary
	var first_highlight := first_workday_report.get("hen_highlight", {}) as Dictionary
	var report_snapshot := campaign_ui.campaign_snapshot()
	var strategy_receipt := report_snapshot.get("strategy_receipt", {}) as Dictionary
	var market_forecast := report_snapshot.get("market_forecast", {}) as Dictionary
	var economic_market := (
		simulation.economic_briefing_snapshot().get("market", {}) as Dictionary
	)
	var current_market := economic_market.get("current", {}) as Dictionary
	_check(not first_receipt.is_empty(), "completed shift should expose an authoritative score receipt", failures)
	_check(int(first_receipt.get("shift_number", 0)) == 1, "latest score receipt should identify the reviewed shift", failures)
	_check(not first_highlight.is_empty() and int(first_highlight.get("day", 0)) == 1, "workday completion should emit one factual day-one hen highlight", failures)
	_check((report_snapshot.get("score_receipt", {}) as Dictionary) == first_receipt, "between-shift snapshot should carry CampaignState's latest score receipt unchanged", failures)
	_check((report_snapshot.get("hen_highlight", {}) as Dictionary) == first_highlight, "between-shift snapshot should carry DepartmentSimulation's emitted hen highlight unchanged", failures)
	_check(
		String(strategy_receipt.get("directive_id", "")) == "shell_assurance"
		and int(strategy_receipt.get("day", 0)) == 1
		and String(strategy_receipt.get("status", "")) == "mixed"
		and String(strategy_receipt.get("headline", "")) == "MIXED RESULT"
		and String(strategy_receipt.get("forecast", "")) == "HELPS 1 / RISKS 1"
		and String(strategy_receipt.get("actual", "")) == "1/1 HELP / 0/1 RISKS COVERED"
		and int(strategy_receipt.get("neutral_total", 0)) == 1
		and int(strategy_receipt.get("neutral_met", 0)) == 1,
		"the report snapshot should compare the filed morning policy with authoritative day-one orders",
		failures,
	)
	_check(
		bool(market_forecast.get("visible", false))
		and int(market_forecast.get("day", 0)) == simulation.day
		and String(market_forecast.get("season_short_label", ""))
		== String(current_market.get("short_label", ""))
		and int(market_forecast.get("days_remaining", -1))
		== int(economic_market.get("current_days_remaining", -2))
		and int(market_forecast.get("opportunity_demand_basis_points", -1))
		== int(economic_market.get("opportunity_demand_basis_points", -2))
		and int(market_forecast.get("feed_spot_unit_price_cents", -1))
		== int(economic_market.get("feed_spot_unit_price_cents", -2)),
		"between-shift presentation should carry the simulation's next-shift market calendar without recomputing it",
		failures,
	)
	_check(
		report_market_card != null and report_market_card.is_visible_in_tree()
		and report_market_icon != null and report_market_icon.icon_kind() == &"calendar"
		and report_market_kicker != null and report_market_kicker.text == "NEXT MARKET"
		and report_market_season != null
		and String(current_market.get("short_label", "")).to_upper() in report_market_season.text
		and report_market_signal != null and "FEED $" in report_market_signal.text
		and int(report_market_card.get_meta("day", 0)) == simulation.day
		and int(report_market_card.get_meta("demand_basis_points", -1))
		== int(economic_market.get("opportunity_demand_basis_points", -2))
		and "CAUSE  //" in report_market_card.tooltip_text
		and "UNCERTAINTY  //" in report_market_card.tooltip_text,
		"the real report should render the authoritative forecast as an icon-led planning pulse with full assistive context",
		failures,
	)
	_check(
		report_strategy_card != null and report_strategy_card.is_visible_in_tree()
		and String(report_strategy_card.get_meta("status", "")) == "mixed"
		and report_strategy_icon != null and report_strategy_icon.icon_kind() == &"shield"
		and String(report_strategy_icon.get_meta("semantic_icon", "")) == "shield"
		and report_strategy_outcome != null and report_strategy_outcome.text == "MIXED RESULT"
		and report_strategy_policy != null and report_strategy_policy.text == "ASSURANCE"
		and report_strategy_forecast != null
		and report_strategy_forecast.text == "HELPS 1 / RISKS 1"
		and report_strategy_actual != null
		and report_strategy_actual.text == "1/1 HELP / 0/1 RISKS COVERED"
		and "MISSED / RISK / OPENING CLUTCH" in report_strategy_card.tooltip_text
		and String(report_strategy_card.get_meta("accessible_text", "")) == report_strategy_card.tooltip_text,
		"the visible closing receipt should preserve the plan-to-result causal chain without another modal",
		failures,
	)
	_check(
		(report_snapshot.get("probation_safeguard_forecast", {}) as Dictionary)
		== campaign.probation_safeguard_forecast(),
		"between-shift snapshot should carry CampaignState's authoritative safeguard forecast unchanged",
		failures,
	)
	_check(
		report_shift_delta != null
		and report_shift_delta.is_visible_in_tree()
		and report_shift_delta.text == _signed_delta(int(first_receipt.get("score_delta", 0))),
		"visible shift-score metric should render the receipt's exact score delta",
		failures,
	)
	_check(
		report_shift_delta_caption != null and report_shift_delta_caption.text == "THIS SHIFT"
		and report_shift_delta_caption.tooltip_text == "SHIFT SCORE"
		and report_shift_delta_icon != null and report_shift_delta_icon.is_visible_in_tree()
		and String(report_shift_delta_icon.get_meta("semantic_icon", "")) == "score_sum"
		and String(report_shift_delta_icon.get_meta("delta_direction", "")) == "gain",
		"the authoritative shift receipt should read as the filed component sum rather than a second cumulative score",
		failures,
	)
	_check(
		report_rank_icon != null and report_rank_icon.is_visible_in_tree()
		and report_rank_icon.texture != null
		and String(report_rank_icon.get_meta("semantic_icon", "")) == "rank_crest"
		and String(first_receipt.get("rank_change", "")) == "promotion"
		and report_rank_caption != null and report_rank_caption.text == "PROMOTED"
		and bool(report_rank_icon.get_meta("promotion_stamp", false))
		and String(report_rank_icon.get_meta("promotion_stamp_motion", "")) == "completed"
		and report_rank_icon.tooltip_text == "PROMOTED  //  TRUSTED LAYER  //  FROM PROBATIONARY MANAGER",
		"the live threshold crossing should settle as one visible promoted crest stamp",
		failures,
	)
	var live_rank_progress := CampaignState.rank_progress_for_score(
		int(first_receipt.get("score_after", 0)),
	)
	_check(
		report_rank_progress != null and report_rank_progress.is_visible_in_tree()
		and is_equal_approx(
			report_rank_progress.value,
			float(live_rank_progress.get("progress_basis_points", -1)),
		)
		and int(report_rank_progress.get_meta("current_score", -1))
		== int(first_receipt.get("score_after", 0))
		and int(report_rank_progress.get_meta("points_to_next", -1))
		== int(live_rank_progress.get("points_to_next", -2)),
		"the live rank rail should consume CampaignState's exact promotion threshold",
		failures,
	)
	_check(
		objective_reward_badge != null and objective_reward_badge.is_visible_in_tree()
		and not bool(objective_reward_badge.get_meta("promotion_opportunity", true))
		and objective_promotion_icon != null and not objective_promotion_icon.visible
		and not bool(report_rank_progress.get_meta("promotion_opportunity", true)),
		"a live +3 bundle should stay visually routine when it cannot reach the next rank",
		failures,
	)
	_check(
		report_receipt_summary != null and not report_receipt_summary.is_visible_in_tree()
		and report_receipt_grid != null and report_receipt_grid.is_visible_in_tree()
		and ("Score %d to %d" % [
			int(first_receipt.get("score_before", 0)),
			int(first_receipt.get("score_after", 0)),
		]) in report_receipt_grid.tooltip_text,
		"visible receipt chips should retain the authoritative before-and-after score",
		failures,
	)
	var live_shift_panel := (
		report_shift_delta.get_parent().get_parent().get_parent() as PanelContainer
		if report_shift_delta != null else
		null
	)
	var live_score_panel := (
		report_score.get_parent().get_parent().get_parent() as PanelContainer
		if report_score != null else
		null
	)
	_check(
		report_score_row != null and bool(report_score_row.get_meta("receipt_equation", false))
		and report_score_row.get_child(1) == live_shift_panel
		and report_score_row.get_child(2) == live_score_panel
		and live_shift_panel != null
		and int(live_shift_panel.get_meta("receipt_component_count", 0)) == 5,
		"the live report should place the five authoritative receipts directly before their shift total and cumulative score",
		failures,
	)
	_check(
		report_details_toggle != null
		and report_details_section != null
		and not report_details_section.is_visible_in_tree()
		and String(first_highlight.get("worker_name", "")) in campaign_ui.accessible_text(),
		"live reports should fold exact accounting by default without removing it from assistive output",
		failures,
	)
	_press(report_details_toggle)
	await process_frame
	_check(hen_highlight_card != null and hen_highlight_card.is_visible_in_tree(), "emitted hen highlight should appear as a visible report card", failures)
	_check(
		hen_highlight_eyebrow != null
		and hen_highlight_eyebrow.is_visible_in_tree()
		and String(first_highlight.get("worker_name", "")).to_upper() in hen_highlight_eyebrow.text,
		"visible hen file should name the worker selected by the emitted highlight",
		failures,
	)
	_check(
		hen_highlight_headline != null
		and hen_highlight_headline.text == String(first_highlight.get("headline", "")).to_upper(),
		"visible hen file should retain the emitted highlight headline",
		failures,
	)
	_check(
		hen_highlight_body != null
		and hen_highlight_body.text == String(first_highlight.get("body", "")),
		"visible hen file should retain the emitted character consequence",
		failures,
	)
	_check(
		hen_highlight_metric != null
		and hen_highlight_metric.text == String(first_highlight.get("metric", "")),
		"visible hen file should retain the emitted worker metrics",
		failures,
	)

	# Shift one has no milestone gate, so filing its probation report starts day two.
	var continue_button := office.find_child("ContinueProbationButton", true, false) as Button
	_check(continue_button != null and not continue_button.disabled, "shift-one probation report should allow continuation", failures)
	_press(continue_button)
	await process_frame
	_check(campaign_ui.modal_state() == ProbationCampaignUI.VIEW_ACTIVE, "filing shift-one report should return to the office", failures)
	_check(simulation.day == 2 and simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE, "filing shift-one report should open the day-two briefing", failures)
	_check(
		day_badge.text == "2 / 5" and day_badge.tooltip_text == "DAY 2 / 5",
		"active calendar value should advance to shift 2 / 5",
		failures,
	)
	_check(
		"COMPETING ORDERS" in String(day_badge.get_meta("accessible_text", "")),
		"day two should visibly retain the campaign's next dramatic chapter in semantic context",
		failures,
	)
	_check(_nonempty_lines(objectives_label.text).size() == 3, "day-two office HUD should retain three objectives", failures)

	_complete_representative_shift(simulation, clock, 7100)
	await process_frame
	campaign = office.get("_campaign_state") as CampaignState
	_check(int(observed["workday_reports"]) == 2, "second shift should emit one additional workday report", failures)
	_check(campaign.completed_shifts == 2 and campaign.shift_records.size() == 2, "Office should retain exactly two records after two shifts", failures)
	_check(review_scrim.visible and StringName(office.get("_campaign_review_stage")) == &"farmer", "shift two should still show farmer accounting first", failures)

	_press(next_shift_button)
	await process_frame
	_check(decision_host.visible, "shift two should require another closing credit memo", failures)
	_file_credit_memo(office, decision_confirm, failures)
	await process_frame
	continue_button = office.find_child("ContinueProbationButton", true, false) as Button
	var milestone_cards := office.find_children("MilestoneChoice_*", "Button", true, false)
	_check(campaign_ui.modal_state() == ProbationCampaignUI.VIEW_REPORT, "shift-two advancement should open the probation milestone report", failures)
	_check(
		day_badge.text == "2 / 5" and day_badge.tooltip_text == "DAY 2 / 5",
		"milestone report should retain exact Day 2 / 5 meaning behind its calendar value",
		failures,
	)
	_check(milestone_cards.size() == 3, "shift-two milestone gate should present exactly three choices", failures)
	_check(campaign.is_milestone_choice_available(), "campaign domain should require a milestone after shift two", failures)
	_check(continue_button != null and continue_button.disabled, "milestone report should disable continuation before selection", failures)

	# Drive the Office guard directly through the UI's public signal as well as the
	# disabled button, proving a scripted/keyboard activation cannot bypass it.
	campaign_ui.continue_campaign.emit()
	await process_frame
	_check(campaign_ui.modal_state() == ProbationCampaignUI.VIEW_REPORT, "milestone gate should keep the probation report open", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW and simulation.day == 3, "milestone gate should prevent the day-three briefing", failures)
	_check(campaign.chosen_milestone_id == &"", "blocked continuation should not fabricate a selection", failures)
	_check(
		ticker != null and ticker.text == "NEXT SHIFT HELD  ·  CHOOSE EDGE",
		"blocked continuation should name the held filing and exact required action",
		failures,
	)

	var quality_choice := office.find_child("MilestoneChoice_shell_quality_lab", true, false) as Button
	_check(quality_choice != null and not quality_choice.disabled, "shell-quality milestone should be selectable", failures)
	var milestone_fund_before := simulation.revenue_cents
	_press(quality_choice)
	await process_frame
	campaign = office.get("_campaign_state") as CampaignState
	continue_button = office.find_child("ContinueProbationButton", true, false) as Button
	_check(campaign.chosen_milestone_id == &"shell_quality_lab", "selected milestone should reach authoritative campaign state", failures)
	_check(campaign.has_unlock(&"shell_quality_checks"), "selected milestone should grant its stable campaign unlock", failures)
	_check(simulation.has_campaign_unlock(&"shell_quality_checks"), "selected unlock should reach DepartmentSimulation", failures)
	_check(int(simulation.campaign_unlock_effects().get("crack_risk_basis_points", 0)) == -250, "DepartmentSimulation should expose the selected unlock's causal modifier", failures)
	_check(simulation.revenue_cents == milestone_fund_before, "filing a probation doctrine must not debit or mint Feed Fund cash", failures)
	_check(continue_button != null and not continue_button.disabled, "milestone selection should enable continuation", failures)
	var doctrine_commendations := office.commendations_snapshot()
	_check(
		"doctrine_filed" in (doctrine_commendations.get("earned_ids", []) as Array),
		"filing a doctrine should immediately stamp its permanent Records commendation",
		failures,
	)

	var milestone_envelope := store.load()
	var milestone_payload := milestone_envelope.get("campaign", {}) as Dictionary
	var milestone_campaign := milestone_payload.get("campaign", {}) as Dictionary
	var milestone_simulation := milestone_payload.get("simulation", {}) as Dictionary
	var milestone_revision := int((milestone_envelope.get("metadata", {}) as Dictionary).get("save_revision", -1))
	_check(String((milestone_envelope.get("metadata", {}) as Dictionary).get("reason", "")) == "milestone_selected", "milestone selection should immediately checkpoint", failures)
	_check(String((milestone_campaign.get("milestone", {}) as Dictionary).get("selected_id", "")) == "shell_quality_lab", "milestone checkpoint should persist the sole authoritative doctrine identity", failures)
	_check(bool((milestone_simulation.get("campaign_unlocks", {}) as Dictionary).get("shell_quality_checks", false)), "milestone checkpoint should include the simulation unlock", failures)

	# Once CampaignState has filed a permanent choice, every alternative card is
	# locked. Then inject a stale optimistic presentation and bypass the button via
	# the public signal: Office must reject it, restore the authoritative card,
	# conserve the fund and score, and avoid writing a new checkpoint revision.
	var padded_choice := office.find_child("MilestoneChoice_padded_perches", true, false) as Button
	_check(
		padded_choice != null
		and padded_choice.disabled
		and padded_choice.theme_type_variation != &"SelectedChoiceButton",
		"non-selected doctrine cards should lock without masquerading as the filed choice",
		failures,
	)
	var filed_score := campaign.probation_score
	var stale_report := campaign_ui.campaign_snapshot()
	stale_report["selected_milestone"] = "padded_perches"
	campaign_ui.show_between_shift_report(stale_report)
	await process_frame
	_check(campaign_ui.selected_milestone_id() == &"padded_perches", "authority regression fixture should stage a stale optimistic card", failures)
	campaign_ui.milestone_choice.emit(&"padded_perches")
	await process_frame
	campaign = office.get("_campaign_state") as CampaignState
	continue_button = office.find_child("ContinueProbationButton", true, false) as Button
	var restored_quality_choice := office.find_child("MilestoneChoice_shell_quality_lab", true, false) as Button
	var restored_padded_choice := office.find_child("MilestoneChoice_padded_perches", true, false) as Button
	_check(campaign.chosen_milestone_id == &"shell_quality_lab", "rejected repeat selection must preserve CampaignState's filed doctrine", failures)
	_check(campaign.probation_score == filed_score, "rejected repeat selection must not award a second milestone score bonus", failures)
	_check(
		simulation.has_campaign_unlock(&"shell_quality_checks")
		and not simulation.has_campaign_unlock(&"welfare_breaks"),
		"rejected repeat selection must preserve only the filed simulation unlock",
		failures,
	)
	_check(simulation.revenue_cents == milestone_fund_before, "rejected repeat selection must conserve the Feed Fund", failures)
	_check(campaign_ui.selected_milestone_id() == &"shell_quality_lab", "Office rejection should rehydrate the UI from authoritative CampaignState", failures)
	_check(
		restored_quality_choice != null
		and restored_quality_choice.theme_type_variation == &"SelectedChoiceButton"
		and restored_padded_choice != null
		and restored_padded_choice.disabled
		and restored_padded_choice.theme_type_variation != &"SelectedChoiceButton",
		"authoritative rehydration should show only Shell Quality as selected and keep alternatives locked",
		failures,
	)
	_check(ticker != null and "MILESTONE HELD" in ticker.text, "rejected repeat selection should explain the authoritative hold", failures)
	var held_envelope := store.load()
	_check(
		int((held_envelope.get("metadata", {}) as Dictionary).get("save_revision", -2)) == milestone_revision
		and String((held_envelope.get("metadata", {}) as Dictionary).get("reason", "")) == "milestone_selected",
		"rejected repeat selection must not write or relabel a checkpoint",
		failures,
	)

	_press(continue_button)
	await process_frame
	_check(campaign_ui.modal_state() == ProbationCampaignUI.VIEW_CONTRACT_BOARD, "day three should open the sequential Farm Mutual planning file", failures)
	_check(simulation.day == 3 and simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW, "contract planning should not start or advance the shift clock", failures)
	var decline_contract := office.find_child("DeclineContractButton", true, false) as Button
	_check(decline_contract != null and decline_contract.is_visible_in_tree() and not decline_contract.disabled, "Farm Mutual planning should expose an explicit standard-book fallback", failures)
	_press(decline_contract)
	await process_frame
	var open_contract_shift := office.find_child("OpenContractShiftButton", true, false) as Button
	_check(open_contract_shift != null and not open_contract_shift.disabled, "authoritative decline receipt should unlock the morning briefing", failures)
	_press(open_contract_shift)
	await process_frame
	_check(campaign_ui.modal_state() == ProbationCampaignUI.VIEW_ACTIVE, "chosen milestone should permit return to the office", failures)
	_check(simulation.day == 3 and simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE, "chosen milestone should permit the day-three briefing", failures)
	_check(
		day_badge.text == "3 / 5" and day_badge.tooltip_text == "DAY 3 / 5",
		"post-milestone calendar value should advance to shift 3 / 5",
		failures,
	)
	_check(_nonempty_lines(objectives_label.text).size() == 3, "post-milestone presentation should show all three day-three objectives", failures)
	var probation_doctrine := office.call("_probation_doctrine_snapshot") as Dictionary
	_check(
		doctrine_label != null
		and doctrine_label.visible
		and doctrine_label.text == "SHELL ASSURANCE  ·  +QUALITY  ·  WATCH WELFARE"
		and doctrine_label.autowrap_mode == TextServer.AUTOWRAP_OFF
		and doctrine_label.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS
		and _contains_all(
			String(doctrine_label.get_meta("accessible_text", "")),
			["SHELL ASSURANCE", "SHELL QUALITY", "COMPLIANCE", "FLOCK WELFARE"],
		)
		and _contains_all(
			doctrine_label.tooltip_text,
			["Win through clean output", "PLAYBOOK", "FULL EDGE", "WATCH"],
		)
		and String(doctrine_label.get_meta("milestone_id", "")) == "shell_quality_lab",
		"day-three Office HUD should show a one-line doctrine glance while preserving the full playbook",
		failures,
	)
	_check(
		String(probation_doctrine.get("milestone_id", "")) == "shell_quality_lab"
		and String(probation_doctrine.get("label", "")) == "SHELL ASSURANCE",
		"web diagnostic source should expose the same authoritative probation_doctrine identity",
		failures,
	)

	# Verify the actual stored checkpoint is primitive JSON, then restore both
	# campaign and simulation from a raw JSON parse rather than shared references.
	var final_envelope := store.load()
	var checkpoint := final_envelope.get("campaign", {}) as Dictionary
	var json_error := _json_safety_error(checkpoint, "checkpoint")
	_check(json_error.is_empty(), "checkpoint should contain only JSON-safe primitives: %s" % json_error, failures)
	var parser := JSON.new()
	var parse_error := parser.parse(JSON.stringify(checkpoint))
	_check(parse_error == OK and typeof(parser.data) == TYPE_DICTIONARY, "checkpoint should survive a raw JSON encode/decode", failures)
	if parse_error == OK and typeof(parser.data) == TYPE_DICTIONARY:
		var parsed_checkpoint := parser.data as Dictionary
		var restored_campaign := CampaignState.from_dictionary(parsed_checkpoint.get("campaign", {}) as Dictionary)
		var restored_simulation := DepartmentSimulation.new(9917)
		var simulation_restored := restored_simulation.restore_save_state(parsed_checkpoint.get("simulation", {}) as Dictionary)
		_check(restored_campaign != null and restored_campaign.to_dictionary() == campaign.to_dictionary(), "JSON campaign checkpoint should round-trip without state drift", failures)
		_check(
			restored_campaign != null
			and restored_campaign.active_doctrine() == campaign.active_doctrine()
			and String(restored_campaign.active_doctrine().get("milestone_id", "")) == "shell_quality_lab"
			and String(restored_campaign.active_doctrine().get("label", "")) == "SHELL ASSURANCE",
			"raw JSON round-trip should restore the same derived Shell Assurance doctrine identity",
			failures,
		)
		_check(simulation_restored, "JSON simulation checkpoint should restore", failures)
		_check(simulation_restored and restored_simulation.day == 3, "restored simulation should retain the day-three briefing", failures)
		_check(simulation_restored and restored_simulation.has_campaign_unlock(&"shell_quality_checks"), "restored simulation should retain the selected milestone unlock", failures)

	clock.set_speed(0)
	office.free()
	await process_frame
	var cleanup_succeeded := store.delete()
	_check(cleanup_succeeded and not independent_store.has_save(), "isolated campaign save and recovery artifacts should be cleaned up", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("PROBATION_CAMPAIGN_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PROBATION_CAMPAIGN_INTEGRATION_TEST_PASSED boot=active checkpoint=resumable shifts=2x1 review=farmer-credit-probation milestone=blocked+unlocked presentation=3-objectives+day/5 json=round-trip cleanup=isolated")
	quit(0)


func _complete_representative_shift(
	simulation: DepartmentSimulation,
	clock: SimulationClock,
	credited_cents: int
) -> void:
	if simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE:
		simulation.select_directive(&"shell_assurance")
	clock.set_speed(0)
	var eggs := simulation.quota_target + 2
	simulation.eggs_today = eggs
	simulation.eggs_total += eggs
	simulation.cracked_today = 1
	simulation.cracked_eggs += 1
	simulation.golden_today = 1
	simulation.golden_eggs += 1
	simulation.credited_today_cents = credited_cents
	simulation.revenue_cents += credited_cents
	simulation.compliance = 82.0
	simulation.executive_confidence = 72.0
	for worker in simulation.workers:
		worker.morale = 74.0
		worker.stress = 10.0
		worker.fatigue = 10.0
	simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	# Closing-time jumps cross the real incident schedule. Resolve each mandatory
	# management gate, then keep advancing until the simulation owns REVIEW.
	for _step in DepartmentSimulation.INCIDENT_MINUTES.size() + 4:
		if simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT:
			_resolve_pending_incident(simulation)
		clock.set_speed(0)
		if simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW:
			break
		if simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING:
			simulation.advance_tick()


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


func _press(button: Button) -> void:
	if button != null and not button.disabled:
		button.pressed.emit()


func _file_credit_memo(office: Office, confirm_button: Button, failures: Array[String]) -> void:
	var reward := office.find_child("DecisionOption_reward_top_layer", true, false) as Button
	_check(reward != null and not reward.disabled, "credit memo should expose a free individual-merit branch", failures)
	_press(reward)
	_check(confirm_button != null and not confirm_button.disabled, "credit selection should enable filing", failures)
	_press(confirm_button)


func _nonempty_lines(value: String) -> PackedStringArray:
	var lines := PackedStringArray()
	for line in value.split("\n"):
		if not line.strip_edges().is_empty():
			lines.append(line.strip_edges())
	return lines


func _objective_bullets(value: String) -> int:
	var count := 0
	for line in value.split("\n"):
		if line.strip_edges().begins_with("-"):
			count += 1
	return count


func _signed_delta(value: int) -> String:
	return "+%d" % value if value > 0 else str(value)


func _json_safety_error(value: Variant, path: String) -> String:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return ""
		TYPE_ARRAY:
			var array_value := value as Array
			for index in array_value.size():
				var error := _json_safety_error(array_value[index], "%s[%d]" % [path, index])
				if not error.is_empty():
					return error
			return ""
		TYPE_DICTIONARY:
			var dictionary_value := value as Dictionary
			for key in dictionary_value:
				if typeof(key) != TYPE_STRING:
					return "%s contains a non-String key" % path
				var error := _json_safety_error(dictionary_value[key], "%s.%s" % [path, key])
				if not error.is_empty():
					return error
			return ""
		_:
			return "%s contains unsupported type %s" % [path, type_string(typeof(value))]


func _contains_all(value: String, needles: Array[String]) -> bool:
	for needle: String in needles:
		if needle not in value:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _signal_routes_to(
	emitter: Object,
	signal_name: StringName,
	target: Object,
	method_name: StringName,
) -> bool:
	if emitter == null or target == null or not emitter.has_signal(signal_name):
		return false
	for connection_value: Variant in emitter.get_signal_connection_list(signal_name):
		if not connection_value is Dictionary:
			continue
		var callback_value: Variant = (connection_value as Dictionary).get("callable")
		if not callback_value is Callable:
			continue
		var callback := callback_value as Callable
		if callback.get_object() == target and callback.get_method() == method_name:
			return true
	return false
