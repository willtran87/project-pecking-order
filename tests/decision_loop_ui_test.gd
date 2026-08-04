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
	var decision_host := office.find_child("ManagementDecisionHost", true, false) as Control
	var confirm_button := office.find_child("ConfirmDecisionButton", true, false) as Button
	var stay_paused_button := office.find_child("ResolveStayPausedButton", true, false) as Button
	var decision_title := office.find_child("DecisionTitle", true, false) as Label
	var decision_body := office.find_child("DecisionBody", true, false) as Label
	var decision_order_heading := office.find_child("DecisionOrderHeading", true, false) as Label
	var decision_order_glance := office.find_child("DecisionOrderGlance", true, false) as GridContainer
	var decision_preview := office.find_child("DecisionPreview", true, false) as Label
	var directive_badge := office.get("_directive_badge") as Label
	var review_scrim := office.find_child("DayReviewScrim", true, false) as ColorRect
	var next_shift_button := office.find_child("BeginNextShiftButton", true, false) as Button
	var probation_report := office.find_child("ProbationReportPanel", true, false) as PanelContainer
	var probation_continue := office.find_child("ContinueProbationButton", true, false) as Button
	var filed_credit_label := office.find_child("FiledCreditMemoLabel", true, false) as Label
	var review_results := office.find_child("FarmerReviewAccountingDetails", true, false) as Label
	var character_dialogue = office.get("_character_dialogue_ui")
	var character_dialogue_panel := office.find_child(
		"CharacterDialoguePanel", true, false
	) as PanelContainer
	var character_dialogue_dismiss := office.find_child(
		"CharacterDialogueDismiss", true, false
	) as Button

	_check(simulation != null, "office should expose its authoritative simulation", failures)
	_check(clock != null and clock.speed_index == 0, "morning briefing should pause the simulation clock", failures)
	_check(decision_host != null and decision_host.visible, "morning directive card should open on first presentation", failures)
	_check(
		character_dialogue != null
		and character_dialogue_panel != null
		and not character_dialogue_panel.visible,
		"character cutouts should remain respectfully suspended behind management decisions",
		failures,
	)
	_check(simulation != null and simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE, "opening shift should await a directive", failures)
	_check(office.find_children("DecisionOption_*", "Button", true, false).size() == 3, "directive card should present three policy choices", failures)
	_check(
		decision_title != null
		and decision_title.text == "PICK TODAY'S FLOCK RULE"
		and decision_order_heading != null
		and decision_order_heading.text == "TODAY'S GOALS"
		and decision_order_heading.is_visible_in_tree()
		and decision_order_glance != null
		and decision_order_glance.is_visible_in_tree()
		and decision_order_glance.columns == 3,
		"the opening policy should lead with one short action and one row of three scored orders",
		failures,
	)
	var opening_accessibility := String(office.call(
		"_web_accessibility_summary",
		simulation.snapshot(),
	))
	_check(
		"PICK TODAY'S FLOCK RULE" in opening_accessibility
		and "Opening clutch, Gather at least 18 eggs., worth 3 score" in opening_accessibility
		and "HARVEST helps 1 and risks 2 orders" in opening_accessibility,
		"assistive narration should retain the full order terms and policy tradeoffs hidden from the glance view",
		failures,
	)
	var decision_diagnostic := office.call("_pending_decision_diagnostic_state") as Dictionary
	var diagnostic_options := decision_diagnostic.get("options", []) as Array
	_check(
		bool(decision_diagnostic.get("visible", false))
		and String(decision_diagnostic.get("id", "")) == "morning_directive"
		and String(decision_diagnostic.get("title", "")) == "CHOOSE TODAY'S MANAGEMENT POLICY"
		and diagnostic_options.size() == 3,
		"player diagnostics should expose the visible decision identity and three bounded choices",
		failures,
	)
	if diagnostic_options.size() >= 3:
		var harvest_effects := (diagnostic_options[0] as Dictionary).get("effect_chips", []) as Array
		var assurance_effects := (diagnostic_options[1] as Dictionary).get("effect_chips", []) as Array
		var care_effects := (diagnostic_options[2] as Dictionary).get("effect_chips", []) as Array
		var harvest_fit := (diagnostic_options[0] as Dictionary).get("order_fit", {}) as Dictionary
		var assurance_fit := (diagnostic_options[1] as Dictionary).get("order_fit", {}) as Dictionary
		var care_fit := (diagnostic_options[2] as Dictionary).get("order_fit", {}) as Dictionary
		_check(
			String((diagnostic_options[0] as Dictionary).get("id", "")) == "record_harvest"
			and int((diagnostic_options[0] as Dictionary).get("index", 0)) == 1
			and bool((diagnostic_options[0] as Dictionary).get("available", false))
			and String((diagnostic_options[2] as Dictionary).get("id", "")) == "sustainable_flock",
			"decision diagnostics should preserve visible ordering, stable IDs, and availability",
			failures,
		)
		_check(
			harvest_effects.size() == 3
			and String((harvest_effects[0] as Dictionary).get("copy", "")) == "PACE +10%"
			and String((harvest_effects[1] as Dictionary).get("copy", "")) == "STRAIN +20%"
			and String((harvest_effects[2] as Dictionary).get("copy", "")) == "RISK +4%"
			and assurance_effects.size() == 3
			and String((assurance_effects[0] as Dictionary).get("copy", "")) == "PACE -7%"
			and String((assurance_effects[1] as Dictionary).get("copy", "")) == "RISK -5%"
			and String((assurance_effects[2] as Dictionary).get("copy", "")) == "RULES +3"
			and care_effects.size() == 3
			and String((care_effects[2] as Dictionary).get("copy", "")) == "FEED +$6",
			"directive authority should expose three compact, exact effect chips for every policy",
			failures,
		)
		_check(
			int(harvest_fit.get("support_count", -1)) == 1
			and int(harvest_fit.get("risk_count", -1)) == 2
			and (harvest_fit.get("supports", []) as Array) == ["OPENING CLUTCH"]
			and (harvest_fit.get("risks", []) as Array) == ["SOUND START", "SETTLED FLOCK"]
			and int(assurance_fit.get("support_count", -1)) == 1
			and int(assurance_fit.get("risk_count", -1)) == 1
			and int(care_fit.get("support_count", -1)) == 1
			and int(care_fit.get("risk_count", -1)) == 1,
			"Day 1 policy diagnostics should map real directive modifiers onto the exact three opening orders",
			failures,
		)

	var harvest_button := office.find_child("DecisionOption_record_harvest", true, false) as Button
	var harvest_chip_row := office.find_child("DecisionEffectChips_record_harvest", true, false) as HBoxContainer
	_check(
		harvest_button != null
		and not harvest_button.disabled
		and "1  HARVEST" in harvest_button.text
		and "INITIATIVE" not in harvest_button.text
		and "1 HELP  ·  2 WATCH" in harvest_button.text
		and harvest_chip_row != null
		and harvest_chip_row.get_child_count() == 3,
		"record harvest should expose a readable short label and intuitive Day 1 tradeoff before selection",
		failures,
	)
	_press(harvest_button)
	_check(confirm_button != null and not confirm_button.disabled, "selecting a directive should enable authorization", failures)
	_check(
		decision_title != null
		and not decision_title.is_visible_in_tree()
		and decision_title.text == "PICK TODAY'S FLOCK RULE"
		and decision_body != null
		and decision_body.text == "Check the goal colors, then start.",
		"selecting a rule should collapse the completed prompt and replace stale guidance",
		failures,
	)
	_check(
		confirm_button != null and confirm_button.text == "START SHIFT  ·  HARVEST",
		"the opening confirmation should state the immediate action without another briefing phrase",
		failures,
	)
	_check(
		decision_preview != null
		and "HARVEST  ·  1 HELP  ·  2 WATCH" in decision_preview.text
		and "EDGE  ·  OUTPUT + QUEUE CONTROL" in decision_preview.text
		and "TODAY'S ORDER FIT" in String(decision_preview.get_meta("accessible_text", ""))
		and "SUPPORTS: OPENING CLUTCH" in String(decision_preview.get_meta("accessible_text", ""))
		and "WATCH: SOUND START, SETTLED FLOCK" in String(decision_preview.get_meta("accessible_text", "")),
		"selected policy should show a compact result while retaining exact fit for assistive output",
		failures,
	)
	_check(
		decision_order_heading != null
		and decision_order_heading.text == "TODAY'S GOALS  ·  TEAL HELPS  ·  AMBER WATCH",
		"selected policy should turn the goal row into the visual help/watch explanation",
		failures,
	)
	decision_diagnostic = office.call("_pending_decision_diagnostic_state") as Dictionary
	_check(
		String(decision_diagnostic.get("selected_option_id", "")) == "record_harvest"
		and bool(decision_diagnostic.get("confirm_enabled", false)),
		"decision diagnostics should publish the selected response and enabled authorization",
		failures,
	)
	_press(confirm_button)
	await process_frame

	_check(not decision_host.visible, "authorized directive should close the management card", failures)
	var character_dialogue_state := (
		character_dialogue.diagnostic_state() as Dictionary
		if character_dialogue != null else
		{}
	)
	_check(
		bool(character_dialogue_state.get("visible", false))
		and String(character_dialogue_state.get("speaker_name", "")) == "Mabel"
		and "speed is a value" in String(character_dialogue_state.get("text", "")),
		"a real directive result should surface one short Mabel aside after the modal closes",
		failures,
	)
	decision_diagnostic = office.call("_pending_decision_diagnostic_state") as Dictionary
	_check(not bool(decision_diagnostic.get("visible", true)), "closed decisions should not leak stale choice text", failures)
	_check(clock.speed_index == 0, "the directive result aside should pause the running shift while it is visible", failures)
	_press(character_dialogue_dismiss)
	await process_frame
	_check(clock.speed_index == 1, "authorized morning directive should begin the shift at 1x", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING, "directive authorization should enter the running phase", failures)
	_check(directive_badge != null and "HARVEST" in directive_badge.text, "top HUD should identify the active policy", failures)
	_check(
		directive_badge != null
		and "SUPPORTS: OPENING CLUTCH" in directive_badge.tooltip_text
		and "WATCH: SOUND START, SETTLED FLOCK" in directive_badge.tooltip_text,
		"active policy tooltip should retain its Day 1 order fit after authorization",
		failures,
	)

	# The first scheduled incident should stop the clock and replace normal controls
	# with a response card. Resolve it without resuming to verify deliberate pause.
	simulation.minute_of_day = DepartmentSimulation.INCIDENT_MINUTES[0] - DepartmentSimulation.MINUTES_PER_TICK
	simulation.advance_tick()
	await process_frame
	_check(decision_host.visible, "first scheduled incident should open a management card", failures)
	_check(clock.speed_index == 0, "incident card should auto-pause the clock", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT, "incident should block the running phase until resolved", failures)
	_check(stay_paused_button != null and stay_paused_button.visible, "incident card should offer a stay-paused resolution", failures)

	var spreadsheet_button := office.find_child("DecisionOption_spreadsheet", true, false) as Button
	var patch_button := office.find_child("DecisionOption_patch", true, false) as Button
	_check(
		patch_button != null
		and "EMERGENCY PATCH" in patch_button.text
		and "$18 COST  /  SAFETY +  /  ORDER +" in patch_button.text
		and "AUTHORIZE" not in patch_button.text,
		"paid incident response should lead with a short action, live cost, and directional stakes",
		failures,
	)
	_check(
		spreadsheet_button != null
		and not spreadsheet_button.disabled
		and "SHADOW SHEET" in spreadsheet_button.text
		and "FREE  /  SPEED +  /  SAFETY -" in spreadsheet_button.text
		and "unofficial" not in spreadsheet_button.text.to_lower(),
		"free incident response should communicate its speed-for-safety tradeoff without clipped prose",
		failures,
	)
	var incident_accessibility := String(office.call(
		"_web_accessibility_summary",
		simulation.snapshot(),
	))
	_check(
		"AUTHORIZE EMERGENCY PATCH" in incident_accessibility
		and "Cost $18" in incident_accessibility
		and "USE THE UNOFFICIAL SPREADSHEET" in incident_accessibility
		and "+6.0% crack risk" in incident_accessibility,
		"assistive narration should retain both full incident actions and exact consequences",
		failures,
	)
	_press(spreadsheet_button)
	_check(
		decision_preview != null
		and "Keep the Fund; trade safety and obedience for speed." in decision_preview.text
		and "No cost" in decision_preview.text
		and "+5% speed" in decision_preview.text
		and "+6.0% crack risk" in decision_preview.text
		and "-6.0 obedience" in decision_preview.text
		and "NEXT FARMER STORY" in decision_preview.text,
		"selecting a concise incident card should disclose its exact immediate and precedent effects",
		failures,
	)
	_check(not stay_paused_button.disabled, "selecting an incident response should enable stay-paused resolution", failures)
	_press(stay_paused_button)
	await process_frame
	_check(not decision_host.visible, "resolved incident should close its card", failures)
	_check(clock.speed_index == 0, "resolve-and-stay-paused should preserve a stopped clock", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING, "resolved incident should return simulation authority to the running phase", failures)
	if character_dialogue_panel != null and character_dialogue_panel.visible:
		_press(character_dialogue_dismiss)
		await process_frame

	# Resume at 3x, then prove the second incident remembers and restores that speed.
	clock.set_speed(2)
	simulation.minute_of_day = DepartmentSimulation.INCIDENT_MINUTES[1] - DepartmentSimulation.MINUTES_PER_TICK
	simulation.advance_tick()
	await process_frame
	_check(decision_host.visible and clock.speed_index == 0, "second incident should auto-pause a running 3x shift", failures)
	var deny_breaks_button := office.find_child("DecisionOption_deny_breaks", true, false) as Button
	_check(deny_breaks_button != null and not deny_breaks_button.disabled, "free wellness response should be selectable", failures)
	_press(deny_breaks_button)
	_press(confirm_button)
	await process_frame
	_check(not decision_host.visible, "resolve-and-resume should close the incident card", failures)
	_check(clock.speed_index == 0, "the incident result aside should pause before restoring the running speed", failures)
	if character_dialogue_panel != null and character_dialogue_panel.visible:
		_press(character_dialogue_dismiss)
		await process_frame
	_check(clock.speed_index == 2, "resolve-and-resume should restore the pre-incident 3x speed", failures)
	_check(simulation.incidents_resolved_today == 2, "both incident choices should be recorded for the farmer review", failures)
	var incident_responses := simulation.incident_responses_for_day(1)
	_check(
		incident_responses.size() == 2
		and String((incident_responses[0] as Dictionary).get("summary", "")) == "LEDGER MOLT / USE THE UNOFFICIAL SPREADSHEET"
		and String((incident_responses[1] as Dictionary).get("summary", "")) == "WELLNESS REQUEST / DENY THE ATTITUDE VARIANCE",
		"the live shift should retain the two actual incident responses, not only a count",
		failures,
	)

	# Completing the day first reveals the detailed farmer accounting, then the
	# cumulative probation report, before routing into a fresh daily directive.
	simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	simulation.advance_tick()
	await process_frame
	_check(review_scrim != null and review_scrim.visible, "shift completion should show the full-screen farmer review", failures)
	_check(clock.speed_index == 0, "farmer review should pause the next shift", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW, "completed day should remain in review until planning continues", failures)
	_check(
		review_results != null
		and "Incident files: LEDGER MOLT / USE THE UNOFFICIAL SPREADSHEET; WELLNESS REQUEST / DENY THE ATTITUDE VARIANCE" in review_results.text,
		"farmer accounting should name every actual standard incident response",
		failures,
	)
	_check(
		next_shift_button != null
		and next_shift_button.text == "CONTINUE  >"
		and "allocate closing credit" in next_shift_button.tooltip_text.to_lower(),
		"review should keep one stable closing-file action while clearly naming credit allocation as the next step",
		failures,
	)

	_press(next_shift_button)
	await process_frame
	_check(not review_scrim.visible, "opening the credit memo should close the farmer review", failures)
	_check(decision_host.visible, "closing review should open the required Pecking Order credit memo", failures)
	_check(not probation_report.visible, "probation report must wait until credit is attributed", failures)
	_check(stay_paused_button != null and not stay_paused_button.visible, "credit memo should hide the in-shift stay-paused action", failures)
	_check(confirm_button != null and confirm_button.text == "FILE CREDIT MEMO", "credit memo should use a dedicated filing action", failures)
	_check(clock.speed_index == 0 and simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW, "credit allocation must keep the review clock locked", failures)
	var reward_button := office.find_child("DecisionOption_reward_top_layer", true, false) as Button
	_check(reward_button != null and not reward_button.disabled, "individual merit should be a valid closing attribution", failures)
	_press(reward_button)
	_press(confirm_button)
	await process_frame
	_check(not decision_host.visible, "filed credit memo should close its dossier", failures)
	_check(probation_report != null and probation_report.visible, "filed credit should advance to the cumulative probation report", failures)
	_check(
		filed_credit_label != null and filed_credit_label.text == "CREDIT GOES TO"
		and "REWARD TOP LAYER" in filed_credit_label.tooltip_text
		and bool(filed_credit_label.get_meta("outcome_first_credit_heading", false)),
		"probation report should show a plain credit heading and retain the exact filed attribution on demand",
		failures,
	)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW and clock.speed_index == 0, "probation report should keep the completed shift locked", failures)
	_press(probation_continue)
	await process_frame
	_check(not probation_report.visible, "filing the probation report should return to the office", failures)
	_check(decision_host.visible, "planning the next shift should open a fresh directive card", failures)
	_check(clock.speed_index == 0, "next morning directive should remain paused for a choice", failures)
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE, "next shift should await a new daily policy", failures)
	decision_diagnostic = office.call("_pending_decision_diagnostic_state") as Dictionary
	diagnostic_options = decision_diagnostic.get("options", []) as Array
	if diagnostic_options.size() >= 3:
		var day_two_harvest_fit := (diagnostic_options[0] as Dictionary).get("order_fit", {}) as Dictionary
		var day_two_care_fit := (diagnostic_options[2] as Dictionary).get("order_fit", {}) as Dictionary
		_check(
			int(day_two_harvest_fit.get("support_count", -1)) == 2
			and int(day_two_harvest_fit.get("risk_count", -1)) == 0
			and (day_two_harvest_fit.get("supports", []) as Array) == ["MEET THE CLUTCH", "TRIM THE TRAYS"]
			and int(day_two_care_fit.get("support_count", -1)) == 0
			and int(day_two_care_fit.get("risk_count", -1)) == 2,
			"policy fit should recompute from Day 2 orders instead of carrying stale opening guidance",
			failures,
		)

	office.free()
	await process_frame

	if not failures.is_empty():
		for failure in failures:
			push_error("DECISION_LOOP_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("DECISION_LOOP_UI_TEST_PASSED directive=harvest incidents=2 review=credit+probation+briefing")
	quit(0)


func _press(button: Button) -> void:
	if button != null and not button.disabled:
		button.pressed.emit()


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
