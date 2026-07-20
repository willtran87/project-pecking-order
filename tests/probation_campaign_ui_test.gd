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
		"challenge_contract": &"",
		"title_phase": &"",
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
	ui.challenge_contract_changed.connect(
		func(contract_id: StringName) -> void: observed["challenge_contract"] = contract_id
	)
	ui.title_intake_phase_changed.connect(
		func(phase: StringName) -> void: observed["title_phase"] = phase
	)
	await process_frame

	var badge := ui.find_child("ProbationDayBadge", true, false) as PanelContainer
	var status_label := ui.find_child("ProbationStatusLabel", true, false) as Label
	var day_label := ui.find_child("ProbationDayLabel", true, false) as Label
	var modal_host := ui.find_child("ProbationModalHost", true, false) as Control
	_check(badge != null and badge.is_visible_in_tree(), "probation badge should always be visible", failures)
	_check(status_label != null and status_label.text == "PROBATION", "badge should default to probation status", failures)
	_check(day_label != null and day_label.text == "DAY 1 / 5", "badge should open on day one of five", failures)
	_check(modal_host != null and not modal_host.is_visible_in_tree(), "active campaign should leave the office unobstructed", failures)

	ui.show_active_campaign({
		"status": "Probation",
		"score": 50,
		"challenge_contract": _challenge_contract("executive_audit"),
	})
	await process_frame
	_check(status_label != null and status_label.text == "SCORE 50 / 100", "active probation badge should name the score scale explicitly", failures)
	_check(
		status_label != null
		and _contains_all(status_label.tooltip_text, [
			"EXECUTIVE AUDIT", "SCORE >= 65 / 100", "WELFARE >= 48",
			"COMPLIANCE >= 65", "FARMER FAVOR >= 53", "CRACK RATE <= 23.00%",
		]),
		"score badge tooltip should explain the active contract and every exact threshold",
		failures,
	)
	var order_progress_row := ui.find_child("ProbationOrderProgressRow", true, false) as HBoxContainer
	var order_progress_label := ui.find_child("ProbationOrderProgressLabel", true, false) as Label
	var first_order_stamp := ui.find_child("ProbationOrderStamp1", true, false) as PanelContainer
	var third_order_stamp := ui.find_child("ProbationOrderStamp3", true, false) as PanelContainer
	var seeded_delta := ui.set_live_order_progress(2, 3, &"probation:1")
	await process_frame
	_check(
		seeded_delta == 0
		and order_progress_row != null
		and order_progress_row.is_visible_in_tree()
		and order_progress_label != null
		and order_progress_label.text == "ORDERS  2 / 3",
		"active badge should quietly seed the exact live order count without adding another panel",
		failures,
	)
	_check(
		first_order_stamp != null
		and third_order_stamp != null
		and first_order_stamp.is_visible_in_tree()
		and third_order_stamp.is_visible_in_tree(),
		"active badge should expose one stable visual stamp for each authored order",
		failures,
	)
	var improved_delta := ui.set_live_order_progress(3, 3, &"probation:1")
	_check(
		improved_delta == 1
		and order_progress_label.text == "ORDERS  3 / 3"
		and int(ui.live_order_progress().get("on_track", 0)) == 3,
		"same-day improvement should return one semantic transition and update the compact badge",
		failures,
	)
	ui.set_reduced_motion(true)
	var risk_delta := ui.set_live_order_progress(2, 3, &"probation:1")
	_check(
		risk_delta == -1
		and badge.modulate.is_equal_approx(Color.WHITE)
		and "Closing metrics can still move" in order_progress_label.tooltip_text,
		"risk transitions should remain legible without a pulse when reduced motion is active",
		failures,
	)
	var next_day_delta := ui.set_live_order_progress(1, 3, &"probation:2")
	_check(
		next_day_delta == 0 and order_progress_label.text == "ORDERS  1 / 3",
		"a new shift should seed quietly instead of replaying a stale reward cue",
		failures,
	)

	ui.apply_snapshot({
		"view": &"title",
		"day": 1,
		"total_days": 5,
		"continue_available": false,
		"challenge_contract_catalog": _challenge_contract_catalog(),
		"selected_new_challenge_contract_id": "standard_filing",
	})
	await process_frame
	var title_panel := ui.find_child("CampaignTitlePanel", true, false) as PanelContainer
	var title_heading := ui.find_child("CampaignTitle", true, false) as Label
	var title_description := ui.find_child("CampaignTitleDescription", true, false) as Label
	var mabel_card := ui.find_child("MabelProfileCard", true, false) as PanelContainer
	var mabel_identity := ui.find_child("CampaignMabelIdentity", true, false) as Label
	var mabel_traits := ui.find_child("CampaignMabelTraits", true, false) as Label
	var mabel_quote := ui.find_child("CampaignMabelQuote", true, false) as Label
	var challenge_selector := ui.find_child("ChallengeContractSelector", true, false) as OptionButton
	var challenge_card := ui.find_child("ChallengeContractCard", true, false) as PanelContainer
	var challenge_summary := ui.find_child("ChallengeContractSummary", true, false) as Label
	var challenge_terms_toggle := ui.find_child("ChallengeContractTermsToggle", true, false) as Button
	var challenge_detail := ui.find_child("ChallengeContractDetail", true, false) as Label
	var probation_summary := ui.find_child("ProbationFiveShiftSummary", true, false) as PanelContainer
	var probation_summary_detail := ui.find_child("ProbationFiveShiftDetail", true, false) as Label
	var new_button := ui.find_child("NewCampaignButton", true, false) as Button
	var continue_button := ui.find_child("ContinueCampaignButton", true, false) as Button
	var back_button := ui.find_child("BackToSavedCampaignButton", true, false) as Button
	_check(title_panel != null and title_panel.is_visible_in_tree(), "first load should show the campaign title panel", failures)
	_check(modal_host.is_visible_in_tree(), "title panel should be an intentional blocking modal", failures)
	_check(
		title_heading != null and title_heading.text == "FIVE SHIFTS. START BY MEETING MABEL.",
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
	_check(
		continue_button != null and continue_button.disabled and not continue_button.is_visible_in_tree(),
		"fresh intake should omit an unusable Continue action instead of adding a disabled peer",
		failures,
	)
	_check(
		new_button != null
		and new_button.text == "MEET MABEL & OPEN FILE  [N]"
		and new_button.theme_type_variation == &"PrimaryButton"
		and new_button.focus_mode == Control.FOCUS_ALL,
		"fresh intake should expose one primary Mabel action with keyboard focus",
		failures,
	)
	_check(
		_count_visible_primary_buttons(title_panel) == 1
		and back_button != null and not back_button.is_visible_in_tree(),
		"fresh intake should have exactly one visually primary CTA and no irrelevant Back action",
		failures,
	)
	_check(
		probation_summary != null and probation_summary.is_visible_in_tree()
		and probation_summary_detail != null
		and _contains_all(probation_summary_detail.text, [
			"One permanent coop file", "closing report after each shift", "final review after Shift 5",
		])
		and ui.find_child("ProbationDayStamp_1", true, false) == null
		and ui.find_child("ProbationDayStamp_5", true, false) == null,
		"one concise five-shift summary should replace five equal-weight day stamps",
		failures,
	)
	_check(
		challenge_selector != null
		and challenge_selector.item_count == 3
		and challenge_selector.focus_mode == Control.FOCUS_ALL
		and challenge_selector.get_item_text(0) == "[LEARNING] SUPPORTED FLOCK"
		and challenge_selector.get_item_text(1) == "[STANDARD] STANDARD FILING"
		and challenge_selector.get_item_text(2) == "[EXPERT] EXECUTIVE AUDIT"
		and challenge_selector.get_item_text(challenge_selector.selected) == "[STANDARD] STANDARD FILING"
		and ui.selected_challenge_contract_id() == &"standard_filing",
		"title should default its keyboard/controller selector to the Standard filing",
		failures,
	)
	_check(
		challenge_card != null and challenge_card.is_visible_in_tree()
		and challenge_summary != null and challenge_summary.is_visible_in_tree()
		and challenge_terms_toggle != null and challenge_terms_toggle.is_visible_in_tree()
		and challenge_terms_toggle.focus_mode == Control.FOCUS_ALL
		and challenge_terms_toggle.shortcut != null
		and challenge_detail != null and not challenge_detail.is_visible_in_tree()
		and "STANDARD DIFFICULTY" in challenge_summary.text
		and "BALANCED ROUTES" in challenge_summary.text
		and "LOCKS ON OPEN" in challenge_summary.text
		and _contains_all(challenge_terms_toggle.tooltip_text, [
			"recommended authored balance",
			"SCORE >= 60 / 100", "WELFARE >= 45", "COMPLIANCE >= 55",
			"FARMER FAVOR >= 50", "CRACK RATE <= 25.00%", "Every permanent doctrine",
		]),
		"Standard should keep every exact threshold keyboard-accessible behind a compact disclosure",
		failures,
	)
	if challenge_terms_toggle != null:
		challenge_terms_toggle.set_pressed_no_signal(true)
		challenge_terms_toggle.pressed.emit()
	_check(
		challenge_detail != null and challenge_detail.is_visible_in_tree()
		and challenge_detail.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
		and _contains_all(challenge_detail.text, [
			"SCORE >= 60 / 100", "WELFARE >= 45", "COMPLIANCE >= 55",
			"FARMER FAVOR >= 50", "CRACK RATE <= 25.00%", "DIFFICULTY NOTE",
		]),
		"View Exact Terms should reveal every Standard filing threshold without changing authority",
		failures,
	)
	if challenge_selector != null:
		challenge_selector.select(0)
		challenge_selector.item_selected.emit(0)
	_check(
		ui.selected_challenge_contract_id() == &"supported_flock"
		and challenge_detail != null
		and _contains_all(challenge_detail.text, [
			"SCORE >= 45 / 100", "WELFARE >= 45", "COMPLIANCE >= 55",
			"FARMER FAVOR >= 45", "CRACK RATE <= 30.00%", "Best for learning",
		]),
		"Supported Flock should retain its complete immutable threshold disclosure",
		failures,
	)
	if challenge_selector != null:
		challenge_selector.select(2)
		challenge_selector.item_selected.emit(2)
	_check(
		ui.selected_challenge_contract_id() == &"executive_audit"
		and StringName(observed["challenge_contract"]) == &"executive_audit"
		and challenge_detail != null
		and _contains_all(challenge_detail.text, [
			"SCORE >= 65 / 100", "WELFARE >= 48", "COMPLIANCE >= 65",
			"FARMER FAVOR >= 53", "CRACK RATE <= 23.00%",
			"demanding replay contract",
			"Harvest Partnership has a proven specialist route",
		]),
		"changing the selector should retain the exact Executive contract and disclose its specialist route",
		failures,
	)
	if challenge_terms_toggle != null:
		challenge_terms_toggle.set_pressed_no_signal(false)
		challenge_terms_toggle.pressed.emit()
	_check(
		challenge_detail != null and not challenge_detail.is_visible_in_tree(),
		"exact terms should collapse back to the compact new-file summary",
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

	# An existing file must be legible before it can be replaced, and replacement
	# requires a second, explicit danger action with the safe choice focused first.
	ui.apply_snapshot({
		"view": &"title",
		"day": 1,
		"total_days": 5,
		"continue_available": true,
		"challenge_contract_catalog": _challenge_contract_catalog(),
		"selected_new_challenge_contract_id": "executive_audit",
		"resume_summary": {
			"day": 3,
			"completed_shifts": 2,
			"probation_score": 66,
			"rank_label": "Trusted Layer",
			"stage_label": "Farmer Review",
			"challenge_contract": _challenge_contract("supported_flock"),
		},
	})
	await process_frame
	await process_frame
	var resume_card := ui.find_child("CampaignResumeCard", true, false) as PanelContainer
	var resume_details := ui.find_child("CampaignResumeDetails", true, false) as Label
	_check(
		resume_card != null and resume_card.is_visible_in_tree()
		and resume_details != null
		and _contains_all(resume_details.text, [
			"DAY 3 / 5", "2 SHIFTS FILED", "SCORE 66", "TRUSTED LAYER",
			"FARMER REVIEW", "SAVED CHALLENGE CONTRACT  //  SUPPORTED FLOCK",
		]),
		"title should identify the exact resumable checkpoint before offering replacement",
		failures,
	)
	_check(
		continue_button != null and continue_button.is_visible_in_tree()
		and not continue_button.disabled
		and continue_button.text == "CONTINUE SAVED FILE  [C]"
		and continue_button.theme_type_variation == &"PrimaryButton"
		and new_button != null and new_button.is_visible_in_tree()
		and new_button.text == "REVIEW A NEW FILE  [N]"
		and new_button.theme_type_variation == &"DecisionChoiceButton"
		and _count_visible_primary_buttons(title_panel) == 1,
		"a resumable intake should be Continue-first with one primary CTA and a secondary new-file path",
		failures,
	)
	_check(
		mabel_card != null and not mabel_card.is_visible_in_tree()
		and challenge_card != null and not challenge_card.is_visible_in_tree()
		and probation_summary != null and not probation_summary.is_visible_in_tree()
		and mabel_identity != null and mabel_identity.text == "MABEL  //  JUNIOR CLAIMS HEN",
		"resume landing should suppress setup density while retaining Mabel's authored identity for the new-file stage",
		failures,
	)
	_check(
		ui.get_viewport().gui_get_focus_owner() == continue_button,
		"resume-first intake should default keyboard/gamepad focus to Continue",
		failures,
	)
	new_button.pressed.emit()
	await process_frame
	await process_frame
	var replacement_host := ui.find_child("CampaignReplacementConfirmation", true, false) as Control
	_check(
		int(observed["new"]) == 1
		and replacement_host != null and not replacement_host.is_visible_in_tree()
		and resume_card != null and not resume_card.is_visible_in_tree()
		and continue_button != null and not continue_button.is_visible_in_tree()
		and mabel_card != null and mabel_card.is_visible_in_tree()
		and challenge_card != null and challenge_card.is_visible_in_tree()
		and probation_summary != null and probation_summary.is_visible_in_tree()
		and new_button.text == "MEET MABEL & OPEN FILE  [N]"
		and new_button.theme_type_variation == &"PrimaryButton"
		and back_button != null and back_button.is_visible_in_tree()
		and _count_visible_primary_buttons(title_panel) == 1,
		"Review a New File should stage compact setup without emitting or replacing the saved campaign",
		failures,
	)
	_check(
		ui.title_intake_phase() == &"new_file"
		and StringName(observed["title_phase"]) == &"new_file",
		"staging a new file should publish its visible intake phase",
		failures,
	)
	_check(
		challenge_selector != null and ui.get_viewport().gui_get_focus_owner() == challenge_selector,
		"staged new-file setup should put keyboard/gamepad focus on its immutable contract selector",
		failures,
	)
	if back_button != null:
		back_button.pressed.emit()
	await process_frame
	await process_frame
	_check(
		resume_card != null and resume_card.is_visible_in_tree()
		and continue_button != null and continue_button.is_visible_in_tree()
		and challenge_card != null and not challenge_card.is_visible_in_tree()
		and ui.get_viewport().gui_get_focus_owner() == continue_button
		and ui.selected_challenge_contract_id() == &"executive_audit"
		and int(observed["new"]) == 1,
		"Back should restore the saved-file landing without losing selection or emitting a campaign intent",
		failures,
	)
	_check(
		ui.title_intake_phase() == &"resume"
		and StringName(observed["title_phase"]) == &"resume",
		"Back should publish the restored resume-first phase",
		failures,
	)
	new_button.pressed.emit()
	await process_frame
	await process_frame
	new_button.pressed.emit()
	await process_frame
	await process_frame
	var replacement_panel := ui.find_child("CampaignReplacementConfirmationPanel", true, false) as PanelContainer
	var replacement_body := ui.find_child("CampaignReplacementConfirmationBody", true, false) as Label
	var keep_button := ui.find_child("CancelCampaignReplacementButton", true, false) as Button
	var replace_button := ui.find_child("ConfirmCampaignReplacementButton", true, false) as Button
	_check(int(observed["new"]) == 1, "staging and replacement review must not emit a destructive new-campaign intent", failures)
	_check(
		replacement_host != null and replacement_host.is_visible_in_tree()
		and replacement_body != null
		and _contains_all(replacement_body.text, [
			"DAY 3 / 5", "SCORE 66", "SUPPORTED FLOCK",
			"NEW CHALLENGE CONTRACT  //  EXECUTIVE AUDIT", "untouched", "written and verified",
		])
		and ui.selected_challenge_contract_id() == &"executive_audit",
		"replacement confirmation should name the affected file and transactional guarantee",
		failures,
	)
	_check(
		keep_button != null and ui.get_viewport().gui_get_focus_owner() == keep_button,
		"replacement confirmation should default keyboard/gamepad focus to keeping the current file",
		failures,
	)
	if replacement_panel != null:
		var replacement_rect := replacement_panel.get_global_rect()
		_check(
			replacement_rect.position.x >= -0.5
			and replacement_rect.end.x <= harness.size.x + 0.5
			and replacement_rect.position.y >= -0.5
			and replacement_rect.end.y <= harness.size.y + 0.5,
			"replacement confirmation should remain fully contained in the 390x844 portrait viewport",
			failures,
		)
	if keep_button != null:
		keep_button.pressed.emit()
	await process_frame
	_check(
		replacement_host != null and not replacement_host.is_visible_in_tree()
		and ui.get_viewport().gui_get_focus_owner() == new_button
		and int(observed["new"]) == 1
		and ui.selected_challenge_contract_id() == &"executive_audit",
		"cancel should preserve the campaign, challenge selection, and originating focus",
		failures,
	)
	new_button.pressed.emit()
	await process_frame
	if replace_button != null:
		replace_button.pressed.emit()
	_check(
		int(observed["new"]) == 2
		and replacement_host != null and not replacement_host.is_visible_in_tree()
		and ui.selected_challenge_contract_id() == &"executive_audit",
		"only explicit confirmation should emit once while retaining the selected challenge contract",
		failures,
	)
	harness.size = Vector2(1280.0, 720.0)
	await process_frame

	ui.apply_snapshot({
		"view": &"title",
		"continue_available": true,
		"challenge_contract_catalog": _challenge_contract_catalog(),
		"selected_new_challenge_contract_id": "standard_filing",
		"resume_summary": {
			"day": 2,
			"completed_shifts": 1,
			"probation_score": 50,
			"challenge_contract": {},
			"challenge_contract_verified": false,
		},
	})
	await process_frame
	_check(
		resume_details != null
		and "UNVERIFIED SAVED TERMS" in resume_details.text
		and "STANDARD FILING" not in resume_details.text,
		"an unverified current-schema saved contract must never be previewed as Standard",
		failures,
	)

	ui.apply_snapshot({
		"view": &"title",
		"continue_available": true,
		"challenge_contract_catalog": _challenge_contract_catalog(),
		"selected_new_challenge_contract_id": "standard_filing",
		"resume_summary": {
			"senior_roost": true,
			"senior_year": 3,
			"roost_marks": 7,
			"mandate_seals": 2,
			"challenge_contract": _challenge_contract("supported_flock"),
			"challenge_contract_verified": true,
		},
	})
	await process_frame
	_check(
		resume_details != null
		and "SENIOR YEAR 3" in resume_details.text
		and "CHALLENGE CONTRACT" not in resume_details.text
		and "SUPPORTED FLOCK" not in resume_details.text,
		"Senior resume copy should suppress the completed probation contract",
		failures,
	)

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
		"challenge_contract": _challenge_contract("standard_filing"),
		"probation_safeguard_forecast": _safeguard_forecast(false, false),
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
				"doctrine": {
					"label": "SHELL ASSURANCE",
					"summary": "Control brittle files before they become tomorrow's rework.",
					"strengths": ["SHELL QUALITY", "COMPLIANCE"],
					"watchouts": ["FLOCK WELFARE"],
					"playbook": "Alternate quality pressure with recovery.",
				},
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
	var safeguard_panel := ui.find_child("ReportProbationSafeguardReceipt", true, false) as PanelContainer
	var safeguard_summary := ui.find_child("ReportProbationSafeguardSummary", true, false) as Label
	var safeguard_score := ui.find_child("ReportProbationSafeguardRow_1", true, false) as Label
	var safeguard_favor := ui.find_child("ReportProbationSafeguardRow_4", true, false) as Label
	var safeguard_shells := ui.find_child("ReportProbationSafeguardRow_5", true, false) as Label
	var objective := ui.find_child("NextShiftObjective", true, false) as Label
	var milestone_section := ui.find_child("MilestoneChoiceSection", true, false) as VBoxContainer
	var choice := ui.find_child("MilestoneChoice_fast_keys", true, false) as Button
	var milestone_hint := ui.find_child("MilestoneChoiceHint", true, false) as Label
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
	_check(
		safeguard_panel != null and safeguard_panel.is_visible_in_tree()
		and safeguard_summary != null
		and _contains_all(safeguard_summary.text, [
			"CURRENT FORECAST", "STANDARD FILING", "4 / 5 SAFEGUARDS", "2 / 5 SHIFTS FILED",
			"ACTION REQUIRED", "LARGEST RECOVERABLE GAP", "FARMER FAVOR", "-1 POINT",
		]),
		"between-shift report should expose the exact pass count and largest recoverable gap",
		failures,
	)
	_check(
		safeguard_score != null and safeguard_score.text == "PASS  //  PROBATION SCORE  //  65 >= 60  //  +5 POINTS"
		and safeguard_favor != null and safeguard_favor.text == "AT RISK  //  FARMER FAVOR  //  49 >= 50  //  -1 POINT"
		and safeguard_shells != null and safeguard_shells.text == "PASS  //  CRACK RATE  //  25.00% <= 25.00%  //  0.00 PTS",
		"forecast rows should state current values, comparisons, thresholds, and signed gaps without hidden rules",
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
	_check(
		choice != null and choice.focus_mode == Control.FOCUS_ALL
		and choice.custom_minimum_size.y >= 108.0
		and _contains_all(choice.text, [
			"SHELL ASSURANCE", "BRASS KEYCAPS", "EDGE SHELL QUALITY",
			"WATCH FLOCK WELFARE", "+10% processing speed",
		])
		and _contains_all(choice.tooltip_text, [
			"Peckwork starts faster.", "SHELL QUALITY // COMPLIANCE",
			"Alternate quality pressure with recovery.",
		])
		and String(choice.get_meta("doctrine_id", "")) == "fast_keys",
		"doctrine milestone cards should stay focusable while disclosing identity, edge, obligation, effect, and playbook",
		failures,
	)
	_check(report_continue != null and report_continue.disabled, "report should wait for a required milestone choice", failures)
	if choice != null:
		choice.pressed.emit()
	_check(StringName(observed["milestone"]) == &"fast_keys", "milestone action should emit its stable identifier", failures)
	_check(ui.selected_milestone_id() == &"fast_keys", "component should expose its selected milestone", failures)
	_check(choice != null and choice.theme_type_variation == &"SelectedChoiceButton", "selected milestone should remain visually persistent", failures)
	_check(milestone_hint != null and "SHELL ASSURANCE  //  BRASS KEYCAPS" in milestone_hint.text, "selected doctrine identity should remain visible before filing", failures)
	_check(report_continue != null and not report_continue.disabled, "choosing a milestone should unlock continuation", failures)
	if report_continue != null:
		report_continue.pressed.emit()
	_check(int(observed["continue"]) == 2, "report continuation should reuse the campaign continuation signal", failures)
	var abandon := ui.find_child("AbandonCampaignButton", true, false) as Button
	_check(
		abandon != null and "SHELVE & RETURN TO INTAKE" in abandon.text
		and abandon.theme_type_variation != &"DangerButton",
		"leaving a report should be presented as a safe shelve action rather than destructive abandonment",
		failures,
	)
	if abandon != null:
		abandon.pressed.emit()
	_check(int(observed["abandon"]) == 1, "abandon action should emit its public signal", failures)

	var report_rect := report_panel.get_global_rect()
	_check(
		report_rect.position.x >= 0.0 and report_rect.end.x <= 1280.0
		and report_rect.position.y >= 60.0 and report_rect.size.y <= 900.0,
		"the complete report should remain a bounded scroll document anchored below the badge (rect %s)" % report_rect,
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
		"challenge_contract": _challenge_contract("standard_filing"),
		"probation_safeguard_forecast": _safeguard_forecast(true, true),
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
	var final_safeguard_panel := ui.find_child("FinalProbationSafeguardReceipt", true, false) as PanelContainer
	var final_safeguard_summary := ui.find_child("FinalProbationSafeguardSummary", true, false) as Label
	var final_safeguard_favor := ui.find_child("FinalProbationSafeguardRow_4", true, false) as Label
	_check(final_panel != null and final_panel.is_visible_in_tree(), "day five should show the final campaign review", failures)
	_check(verdict != null and verdict.text == "PROBATION PASSED", "final review should clearly distinguish a pass", failures)
	_check(final_continue != null and final_continue.is_visible_in_tree(), "passing should offer the senior-roost continuation", failures)
	_check(
		final_safeguard_panel != null and final_safeguard_panel.is_visible_in_tree()
		and final_safeguard_summary != null
		and final_safeguard_summary.text == "FINAL RESULT  //  STANDARD FILING  //  5 / 5 SAFEGUARDS  //  ALL SAFEGUARDS PASS"
		and final_safeguard_favor != null
		and final_safeguard_favor.text == "PASS  //  FARMER FAVOR  //  52 >= 50  //  +2 POINTS",
		"passing final review should file an exact five-row safeguard receipt",
		failures,
	)
	_check(
		final_rank != null
		and final_rank.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
		and final_rank.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING,
		"final rank should preserve the complete management title",
		failures,
	)
	_check(
		final_panel.size.y < 600.0,
		"final review should fit the 720-stage while retaining all five receipt rows (height %.1f)" % final_panel.size.y,
		failures,
	)

	ui.show_final_review({
		"day": 5,
		"score": 50,
		"rank": "Probationary Manager",
		"passed": true,
		"challenge_contract": _challenge_contract("supported_flock"),
		"probation_safeguard_forecast": {},
	})
	await process_frame
	_check(
		final_rank != null and final_rank.text == "QUALIFIED ROOSTER",
		"a passed Supported Flock file should use an outcome-aware final title",
		failures,
	)

	ui.show_final_review({
		"day": 5,
		"score": 900,
		"rank": "Loose Feather",
		"passed": false,
		"challenge_contract": _challenge_contract("standard_filing"),
		"probation_safeguard_forecast": _safeguard_forecast(true, false),
	})
	await process_frame
	_check(verdict.text == "PROBATION FAILED", "final review should clearly distinguish a failure", failures)
	_check(not final_continue.is_visible_in_tree(), "failure should not offer post-probation continuation", failures)
	_check(
		final_safeguard_summary != null
		and final_safeguard_summary.text == "FINAL RESULT  //  STANDARD FILING  //  4 / 5 SAFEGUARDS  //  FILE HELD"
		and final_safeguard_favor != null
		and final_safeguard_favor.text == "HELD  //  FARMER FAVOR  //  49 >= 50  //  -1 POINT",
		"failed final review should name the exact held condition rather than hiding it behind the verdict",
		failures,
	)
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
		status_label.text == "ROOST  73"
		and status_label.tooltip_text == "SENIOR ROOST  73",
		"active badge should expose a fitted long-term status and preserve its full accessible label",
		failures,
	)

	ui.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("PROBATION_CAMPAIGN_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PROBATION_CAMPAIGN_UI_TEST_PASSED badge=day/5+score/100+safeguards title=resume-first+staged-new-file+one-primary+compact-five-shift+contract-disclosure report=closing-file-3/3+receipt+hen-file+ledgers+milestone final=pass/fail responsive=story-wrap+4 signals=5")
	quit(0)


func _count_visible_primary_buttons(panel: Control) -> int:
	if panel == null:
		return 0
	var count := 0
	for node: Node in panel.find_children("*", "Button", true, false):
		var button := node as Button
		if (
			button != null
			and button.is_visible_in_tree()
			and button.theme_type_variation == &"PrimaryButton"
		):
			count += 1
	return count


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _contains_all(text: String, needles: Array[String]) -> bool:
	for needle: String in needles:
		if needle not in text:
			return false
	return true


func _challenge_contract_catalog() -> Array[Dictionary]:
	return [
		_challenge_contract("supported_flock"),
		_challenge_contract("standard_filing"),
		_challenge_contract("executive_audit"),
	]


func _challenge_contract(contract_id: String) -> Dictionary:
	match contract_id:
		"supported_flock":
			return {
				"id": "supported_flock",
				"label": "SUPPORTED FLOCK",
				"short_label": "SUPPORTED",
				"difficulty": "learning",
				"difficulty_label": "LEARNING",
				"difficulty_guidance": "Best for learning the complete management loop with more recovery room.",
				"description": "More room for score, farmer favor, and shell loss while preserving care floors.",
				"route_brief": "OPEN ROUTES  //  CARE, QUALITY & HARVEST",
				"route_guidance": "Use this contract to learn any doctrine while still managing welfare and compliance.",
				"criteria": {
					"minimum_score": 45,
					"minimum_welfare": 45,
					"minimum_compliance": 55,
					"minimum_farmer_favor": 45,
					"maximum_crack_rate_basis_points": 3000,
				},
			}
		"executive_audit":
			return {
				"id": "executive_audit",
				"label": "EXECUTIVE AUDIT",
				"short_label": "EXECUTIVE",
				"difficulty": "expert",
				"difficulty_label": "EXPERT",
				"difficulty_guidance": "A demanding replay contract for managers who already understand every safeguard.",
				"description": "A tighter replay contract demanding stronger results in every filing.",
				"route_brief": "EXPERT REPLAY  //  HARVEST ROUTE PROVEN",
				"route_guidance": "Harvest Partnership has a proven specialist route. Care-led files need extra score; quality-led files must deliberately recover welfare and farmer favor.",
				"criteria": {
					"minimum_score": 65,
					"minimum_welfare": 48,
					"minimum_compliance": 65,
					"minimum_farmer_favor": 53,
					"maximum_crack_rate_basis_points": 2300,
				},
			}
	return {
		"id": "standard_filing",
		"label": "STANDARD FILING",
		"short_label": "STANDARD",
		"difficulty": "standard",
		"difficulty_label": "STANDARD",
		"difficulty_guidance": "The recommended authored balance for a first complete probation file.",
		"description": "The authored probation contract with the shipped balance.",
		"route_brief": "BALANCED ROUTES  //  CARE, QUALITY & HARVEST",
		"route_guidance": "Every permanent doctrine has a tested route through these terms.",
		"criteria": {
			"minimum_score": 60,
			"minimum_welfare": 45,
			"minimum_compliance": 55,
			"minimum_farmer_favor": 50,
			"maximum_crack_rate_basis_points": 2500,
		},
	}


func _safeguard_forecast(is_final: bool, all_passing: bool) -> Dictionary:
	var completed_shifts := 5 if is_final else 2
	var farmer_favor := 52 if all_passing else 49
	var criteria: Array[Dictionary] = [
		_safeguard_row("score", "Probation Score", "probation_score", "minimum", 65, 60, not is_final),
		_safeguard_row("welfare", "Welfare", "average_welfare", "minimum", 50, 45, not is_final),
		_safeguard_row("compliance", "Compliance", "average_compliance", "minimum", 58, 55, not is_final),
		_safeguard_row("farmer_favor", "Farmer Favor", "average_farmer_favor", "minimum", farmer_favor, 50, not is_final),
		_safeguard_row("crack_rate", "Crack Rate", "crack_rate_basis_points", "maximum", 2500, 2500, not is_final),
	]
	var pass_count := 0
	for criterion: Dictionary in criteria:
		if bool(criterion["pass"]):
			pass_count += 1
	return {
		"visible": true,
		"is_final": is_final,
		"completed_shifts": completed_shifts,
		"required_shifts": 5,
		"criteria": criteria,
		"pass_count": pass_count,
		"at_risk_count": criteria.size() - pass_count,
		"criteria_count": criteria.size(),
		"all_pass": pass_count == criteria.size(),
		"largest_recoverable_blocker": (
			criteria[3].duplicate(true)
			if not is_final and not bool(criteria[3]["pass"]) else
			{}
		),
	}


func _safeguard_row(
	id: String,
	label: String,
	metric: String,
	comparison: String,
	value: int,
	target: int,
	recoverable: bool,
) -> Dictionary:
	var signed_gap := value - target if comparison == "minimum" else target - value
	return {
		"id": id,
		"label": label,
		"metric": metric,
		"comparison": comparison,
		"target": target,
		"current_value": value,
		"projected_value": value,
		"pass": signed_gap >= 0,
		"at_risk": signed_gap < 0,
		"signed_gap": signed_gap,
		"distance_to_pass": maxi(0, -signed_gap),
		"recoverable": signed_gap < 0 and recoverable,
	}


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
