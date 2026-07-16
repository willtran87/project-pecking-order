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
	var day_badge := office.find_child("ProbationDayLabel", true, false) as Label
	var objectives_label := office.find_child("CampaignObjectivesLabel", true, false) as Label
	var safeguards_label := office.find_child("CampaignSafeguardForecast", true, false) as Label
	var review_scrim := office.find_child("DayReviewScrim", true, false) as ColorRect
	var next_shift_button := office.find_child("BeginNextShiftButton", true, false) as Button
	var report_panel := office.find_child("ProbationReportPanel", true, false) as PanelContainer
	var report_shift_delta := office.find_child("ReportShiftDelta", true, false) as Label
	var report_receipt_summary := office.find_child("ReportScoreReceiptSummary", true, false) as Label
	var hen_highlight_card := office.find_child("ShiftHenHighlightCard", true, false) as PanelContainer
	var hen_highlight_eyebrow := office.find_child("ShiftHenHighlightEyebrow", true, false) as Label
	var hen_highlight_headline := office.find_child("ShiftHenHighlightHeadline", true, false) as Label
	var hen_highlight_body := office.find_child("ShiftHenHighlightBody", true, false) as Label
	var hen_highlight_metric := office.find_child("ShiftHenHighlightMetric", true, false) as Label
	var report_objective := office.find_child("NextShiftObjectiveDescription", true, false) as Label
	var decision_host := office.find_child("ManagementDecisionHost", true, false) as Control
	var decision_confirm := office.find_child("ConfirmDecisionButton", true, false) as Button
	var ticker := office.get("_ticker_label") as Label

	_check(simulation != null and campaign != null and campaign_ui != null, "headless Office should boot all authoritative campaign collaborators", failures)
	_check(DisplayServer.get_name() == "headless", "focused integration test must run through the headless Office branch", failures)
	_check(campaign_ui != null and campaign_ui.modal_state() == ProbationCampaignUI.VIEW_ACTIVE, "headless Office should boot directly into an active campaign", failures)
	_check(campaign != null and campaign.outcome == CampaignState.OUTCOME_IN_PROGRESS and campaign.completed_shifts == 0, "headless Office should open a fresh five-shift probation state", failures)
	_check(day_badge != null and day_badge.text == "DAY 1 / 5", "campaign presentation should expose Day 1 / 5", failures)
	_check(_nonempty_lines(objectives_label.text if objectives_label != null else "").size() == 3, "active campaign presentation should show all three current objectives", failures)
	_check(
		safeguards_label != null and safeguards_label.visible
		and "FINAL SAFEGUARDS  //  1 / 5 PASS  //  0 / 5 SHIFTS" in safeguards_label.text
		and "AT RISK  //  FLOCK WELFARE  //  -45 POINTS" in safeguards_label.text,
		"office Flockwatch should expose the live pass count and largest normalized probation blocker (text: %s)" % (
			safeguards_label.text if safeguards_label != null else "<missing>"
		),
		failures,
	)
	_check(
		safeguards_label != null
		and _contains_all(safeguards_label.tooltip_text, [
			"PROBATION FINAL TERMS", "PROBATION SCORE  //  50 >= 60",
			"WELFARE  //  0 >= 45", "COMPLIANCE  //  0 >= 55",
			"FARMER FAVOR  //  0 >= 50", "CRACK RATE  //  0.00% <= 25.00%",
		]),
		"Flockwatch tooltip should publish all five exact final thresholds",
		failures,
	)

	# Exercise the same New Campaign action used by the title card. This resets the
	# simulation and must immediately create a resumable checkpoint.
	campaign_ui.show_title(false)
	await process_frame
	var new_campaign_button := office.find_child("NewCampaignButton", true, false) as Button
	_press(new_campaign_button)
	await process_frame
	campaign = office.get("_campaign_state") as CampaignState
	_check(campaign_ui.modal_state() == ProbationCampaignUI.VIEW_ACTIVE, "fresh start should return to the unobstructed office", failures)
	_check(store.has_save(), "fresh start/reset should save a resumable checkpoint", failures)
	var independent_store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	_check(independent_store.has_save(), "a new store instance should discover the fresh checkpoint", failures)
	var fresh_envelope := independent_store.load()
	var fresh_payload := fresh_envelope.get("campaign", {}) as Dictionary
	var fresh_campaign_data := fresh_payload.get("campaign", {}) as Dictionary
	var fresh_campaign := CampaignState.from_dictionary(fresh_campaign_data)
	_check(not fresh_envelope.is_empty(), "fresh checkpoint should load through the production save envelope", failures)
	_check(String((fresh_envelope.get("metadata", {}) as Dictionary).get("reason", "")) == "new_campaign", "fresh checkpoint should disclose its reset reason", failures)
	_check(fresh_campaign != null and fresh_campaign.completed_shifts == 0, "fresh checkpoint should be resumable before shift one", failures)
	var fresh_session := fresh_payload.get("session", {}) as Dictionary
	var fresh_first_clutch := fresh_session.get("first_clutch", {}) as Dictionary
	_check(
		int(fresh_first_clutch.get("target_worker_id", -1)) == 0
		and not bool(fresh_first_clutch.get("inspected", true))
		and simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE
		and decision_host != null
		and not decision_host.visible,
		"fresh checkpoint should hold Mabel's pre-policy file without mutating the morning directive",
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
	_check(day_badge.text == "DAY 1 / 5", "between-shift presentation should identify the reviewed day out of five", failures)
	_check(_objective_bullets(report_objective.text if report_objective != null else "") == 3, "probation report should present all three next-shift objectives", failures)

	# The report must disclose the exact causal score receipt from CampaignState and
	# the same character moment emitted by DepartmentSimulation, rather than
	# reconstructing either story independently in the presentation layer.
	var first_receipt := campaign.latest_score_receipt()
	var first_workday_report := observed.get("last_workday_report", {}) as Dictionary
	var first_highlight := first_workday_report.get("hen_highlight", {}) as Dictionary
	var report_snapshot := campaign_ui.campaign_snapshot()
	_check(not first_receipt.is_empty(), "completed shift should expose an authoritative score receipt", failures)
	_check(int(first_receipt.get("shift_number", 0)) == 1, "latest score receipt should identify the reviewed shift", failures)
	_check(not first_highlight.is_empty() and int(first_highlight.get("day", 0)) == 1, "workday completion should emit one factual day-one hen highlight", failures)
	_check((report_snapshot.get("score_receipt", {}) as Dictionary) == first_receipt, "between-shift snapshot should carry CampaignState's latest score receipt unchanged", failures)
	_check((report_snapshot.get("hen_highlight", {}) as Dictionary) == first_highlight, "between-shift snapshot should carry DepartmentSimulation's emitted hen highlight unchanged", failures)
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
		report_receipt_summary != null
		and report_receipt_summary.is_visible_in_tree()
		and ("%d -> %d" % [int(first_receipt.get("score_before", 0)), int(first_receipt.get("score_after", 0))]) in report_receipt_summary.text,
		"visible receipt summary should render the authoritative before-and-after score",
		failures,
	)
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
	_check(day_badge.text == "DAY 2 / 5", "active presentation should advance to Day 2 / 5", failures)
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
	_check(day_badge.text == "DAY 2 / 5", "milestone report should identify Day 2 / 5", failures)
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
	_check(ticker != null and "MILESTONE REQUIRED" in ticker.text, "blocked continuation should explain the required choice", failures)

	var quality_choice := office.find_child("MilestoneChoice_shell_quality_lab", true, false) as Button
	_check(quality_choice != null and not quality_choice.disabled, "shell-quality milestone should be selectable", failures)
	_press(quality_choice)
	await process_frame
	campaign = office.get("_campaign_state") as CampaignState
	continue_button = office.find_child("ContinueProbationButton", true, false) as Button
	_check(campaign.chosen_milestone_id == &"shell_quality_lab", "selected milestone should reach authoritative campaign state", failures)
	_check(campaign.has_unlock(&"shell_quality_checks"), "selected milestone should grant its stable campaign unlock", failures)
	_check(simulation.has_campaign_unlock(&"shell_quality_checks"), "selected unlock should reach DepartmentSimulation", failures)
	_check(int(simulation.campaign_unlock_effects().get("crack_risk_basis_points", 0)) == -250, "DepartmentSimulation should expose the selected unlock's causal modifier", failures)
	_check(continue_button != null and not continue_button.disabled, "milestone selection should enable continuation", failures)

	var milestone_envelope := store.load()
	var milestone_payload := milestone_envelope.get("campaign", {}) as Dictionary
	var milestone_simulation := milestone_payload.get("simulation", {}) as Dictionary
	_check(String((milestone_envelope.get("metadata", {}) as Dictionary).get("reason", "")) == "milestone_selected", "milestone selection should immediately checkpoint", failures)
	_check(bool((milestone_simulation.get("campaign_unlocks", {}) as Dictionary).get("shell_quality_checks", false)), "milestone checkpoint should include the simulation unlock", failures)

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
	_check(day_badge.text == "DAY 3 / 5", "post-milestone presentation should advance to Day 3 / 5", failures)
	_check(_nonempty_lines(objectives_label.text).size() == 3, "post-milestone presentation should show all three day-three objectives", failures)

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
