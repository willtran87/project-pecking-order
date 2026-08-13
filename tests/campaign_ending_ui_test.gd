extends SceneTree

const ProbationCampaignUIScript := preload("res://features/office/probation_campaign_ui.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observed := {
		"continue": 0,
		"new_campaign": 0,
	}
	var harness := Control.new()
	harness.name = "CampaignEndingUITestHarness"
	harness.size = Vector2(1280.0, 720.0)
	root.add_child(harness)
	var ui = ProbationCampaignUIScript.new()
	harness.add_child(ui)
	ui.continue_campaign.connect(func() -> void: observed["continue"] += 1)
	ui.new_campaign.connect(func() -> void: observed["new_campaign"] += 1)
	await process_frame

	var verdict := ui.find_child("FinalProbationVerdict", true, false) as Label
	var message := ui.find_child("FinalProbationMessage", true, false) as Label
	var final_panel := ui.find_child("FinalProbationReviewPanel", true, false) as PanelContainer
	var modal_host := ui.find_child("ProbationModalHost", true, false) as Control
	var continue_button := ui.find_child("FinalContinueCampaignButton", true, false) as Button
	var new_button := ui.find_child("FinalNewCampaignButton", true, false) as Button
	var leave_button := ui.find_child("FinalAbandonCampaignButton", true, false) as Button
	var sticky_bar := ui.find_child("FinalStickyActionBar", true, false) as PanelContainer
	var sticky_primary := ui.find_child("FinalStickyPrimaryButton", true, false) as Button
	var sticky_leave := ui.find_child("FinalStickyLeaveButton", true, false) as Button
	var ending_beat_1 := ui.find_child("FinalEndingBeat1", true, false) as PanelContainer
	var ending_caption_1 := ui.find_child("FinalEndingBeatCaption1", true, false) as Label
	var ending_caption_2 := ui.find_child("FinalEndingBeatCaption2", true, false) as Label
	var ending_caption_3 := ui.find_child("FinalEndingBeatCaption3", true, false) as Label
	var ending_caption_4 := ui.find_child("FinalEndingBeatCaption4", true, false) as Label
	var ending_value_1 := ui.find_child("FinalEndingBeatValue1", true, false) as Label
	var ending_value_2 := ui.find_child("FinalEndingBeatValue2", true, false) as Label
	var ending_value_3 := ui.find_child("FinalEndingBeatValue3", true, false) as Label
	var ending_value_4 := ui.find_child("FinalEndingBeatValue4", true, false) as Label
	_check(verdict != null and message != null, "final review should expose readable verdict and message labels", failures)
	_check(
		ending_beat_1 != null and ending_caption_1 != null and ending_caption_4 != null
		and ending_value_1 != null and ending_value_2 != null and ending_value_3 != null and ending_value_4 != null,
		"final review should expose four glance-first ending beats",
		failures,
	)
	_check(final_panel != null and modal_host != null, "final review should retain its blocking modal structure", failures)
	_check(continue_button != null and new_button != null and leave_button != null, "final review should retain all campaign actions", failures)
	_check(sticky_bar != null and sticky_primary != null and sticky_leave != null, "desktop final review should expose its always-visible action strip", failures)

	var successful_endings: Array[Dictionary] = [
		{
			"id": &"farmer_favorite",
			"title": "FARMER'S FAVORITE",
			"coda": "The deck is clean, the quota is higher, and one chair is easier to explain.",
			"beats": ["WON", "RELEASED", "RAISED"],
		},
		{
			"id": &"benevolent_rooster",
			"title": "BENEVOLENT ROOSTER",
			"coda": "Basic support survived because it was entered as an exception expense.",
			"beats": ["SUPPORTED", "FILED", "NOTED"],
		},
		{
			"id": &"collective_bargaining",
			"title": "THE FLOCK HAS A VOICE",
			"coda": "The workforce became a subject instead of a spreadsheet.",
			"beats": ["UNITED", "FILED", "CONTESTED"],
		},
	]
	for ending: Dictionary in successful_endings:
		ui.apply_snapshot(_final_snapshot(true, ending))
		await process_frame
		await process_frame
		var expected_title := String(ending["title"])
		_check(verdict != null and verdict.text == expected_title, "%s should replace the generic pass verdict" % expected_title, failures)
		_check(verdict != null and verdict.text != "PROBATION PASSED", "%s should not collapse to generic pass copy" % expected_title, failures)
		_check(message != null and String(ending["coda"]) in message.text, "%s should preserve its authored ending copy" % expected_title, failures)
		_check(message != null and not message.visible, "%s should keep its authored paragraph out of the glance-first layout" % expected_title, failures)
		var expected_beats := ending.get("beats", []) as Array
		_check(
			ending_value_1 != null and ending_value_1.text == String(expected_beats[0])
			and ending_value_2 != null and ending_value_2.text == String(expected_beats[1])
			and ending_value_3 != null and ending_value_3.text == String(expected_beats[2]),
			"%s should communicate its outcome through three compact beats" % expected_title,
			failures,
		)
		_check(
			ending_beat_1 != null and String(ending["coda"]) in ending_beat_1.tooltip_text
			and String(ending["coda"]) in String(ending_beat_1.get_meta("accessible_text", "")),
			"%s compact beats should retain the authored coda for pointer and assistive access" % expected_title,
			failures,
		)
		_check(
			String(ending["coda"]) in ui.accessible_text(),
			"%s browser accessibility mirror should retain the exact authored ending" % expected_title,
			failures,
		)
		_check(final_panel != null and final_panel.is_visible_in_tree(), "%s should remain visible as the final review" % expected_title, failures)
		_check(modal_host != null and modal_host.is_visible_in_tree() and modal_host.mouse_filter == Control.MOUSE_FILTER_STOP, "%s should remain an intentional blocking modal" % expected_title, failures)
		_check(continue_button != null and not continue_button.is_visible_in_tree() and not continue_button.disabled, "%s should avoid duplicating the sticky desktop continuation in the scroll flow" % expected_title, failures)
		_check(continue_button != null and continue_button.focus_mode == Control.FOCUS_ALL, "%s continuation should remain keyboard focusable" % expected_title, failures)
		_check(continue_button != null and _shortcut_has_key(continue_button, KEY_C), "%s continuation should retain its C shortcut" % expected_title, failures)
		_check(sticky_bar != null and sticky_bar.is_visible_in_tree(), "%s should keep the next action above the desktop fold" % expected_title, failures)
		_check(sticky_primary != null and "ENTER THE SENIOR ROOST" in sticky_primary.text and _shortcut_has_key(sticky_primary, KEY_C), "%s sticky action should preserve Senior continuation and its shortcut" % expected_title, failures)
		_check(ui.get_viewport().gui_get_focus_owner() == sticky_primary, "%s should focus the visible sticky continuation" % expected_title, failures)
		if continue_button != null:
			continue_button.pressed.emit()
	if sticky_primary != null:
		sticky_primary.pressed.emit()
	_check(int(observed["continue"]) == successful_endings.size() + 1, "in-flow and sticky successful actions should preserve the public continuation signal", failures)

	var experiential_final := _final_snapshot(true, successful_endings[2])
	experiential_final["campaign_legacy"] = {
		"title": "FLOCK STEWARDSHIP",
		"detail": "You built durable output through recovery and shared credit.",
	}
	experiential_final["flock_epilogue"] = [
		{
			"worker_name": "Mabel",
			"caption": "RESTRUCTURING",
			"value": "STOOD TOGETHER",
			"outcome": "Mabel kept her chair after the flock contested the ranking together.",
		},
	]
	experiential_final["replay_recommendation"] = {
		"contract_short_label": "EXECUTIVE",
		"action": "FACE THE EXECUTIVE AUDIT",
		"rationale": "Start with tighter cash, a higher quota, and extra live files.",
	}
	experiential_final["campaign_future"] = {
		"title": "OFFICE FUTURE",
		"value": "FLOCK HAS LEVERAGE",
		"detail": "The hens keep a voice in future rankings and working conditions.",
	}
	experiential_final["final_hearing"] = {
		"resolved": true,
		"option_label": "SIGN THE FLOCK CHARTER",
		"outcome": "The flock charter remains on the office wall.",
	}
	experiential_final["run_history"] = {
		"run_count": 2,
		"headline": "RUN 2  /  BEST 78",
		"detail": "+9 score versus the previous file. Two scenarios are archived.",
	}
	ui.apply_snapshot(experiential_final)
	await process_frame
	await process_frame
	_check(
		ending_caption_1 != null and ending_caption_1.text == "YOUR LEGACY"
		and ending_value_1 != null and ending_value_1.text == "FLOCK STEWARDSHIP"
		and ending_caption_2 != null and ending_caption_2.text == "MABEL"
		and ending_value_2 != null and ending_value_2.text == "STOOD TOGETHER"
		and ending_caption_3 != null and ending_caption_3.text == "OFFICE FUTURE"
		and ending_value_3 != null and ending_value_3.text == "FLOCK HAS LEVERAGE"
		and ending_caption_4 != null and ending_caption_4.text == "NEXT FILE"
		and ending_value_4 != null and ending_value_4.text == "EXECUTIVE",
		"an experiential final snapshot should replace generic beats with legacy, named-flock, office-future, and replay payoffs",
		failures,
	)
	_check(
		message != null
		and "YOUR LEGACY  //  FLOCK STEWARDSHIP" in message.text
		and "MABEL  //  Mabel kept her chair" in message.text
		and "OFFICE FUTURE  //  FLOCK HAS LEVERAGE" in message.text
		and "NEXT RUN  //  FACE THE EXECUTIVE AUDIT" in message.text
		and "FINAL HEARING  //  SIGN THE FLOCK CHARTER" in message.text
		and "RUN ARCHIVE  //  RUN 2  /  BEST 78" in message.text
		and not message.visible,
		"the low-text finale should retain legacy, epilogue, playable climax, and run comparison as progressive detail",
		failures,
	)

	# The longest authored title must remain readable in the portrait web layout.
	harness.size = Vector2(390.0, 844.0)
	ui.apply_snapshot(_final_snapshot(true, successful_endings[2]))
	await process_frame
	await process_frame
	_check(verdict != null and verdict.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "the long collective ending title should wrap for accessibility", failures)
	_check(verdict != null and verdict.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING, "authored ending titles should never be ellipsized", failures)
	_check(sticky_bar != null and not sticky_bar.is_visible_in_tree(), "portrait final review should keep its actions in the scroll flow instead of covering content", failures)
	_check(ui.get_viewport().gui_get_focus_owner() == continue_button, "portrait final review should focus its in-flow continuation", failures)
	if final_panel != null:
		var panel_rect := final_panel.get_global_rect()
		_check(panel_rect.position.x >= -0.5 and panel_rect.end.x <= harness.size.x + 0.5, "the collective ending should stay inside the portrait viewport", failures)
	harness.size = Vector2(1280.0, 720.0)
	await process_frame

	var failed_ending := {
		"id": &"probation_terminated",
		"title": "PROBATION TERMINATED",
		"coda": "The farmer archived the context and opened a search for dependable leadership.",
	}
	ui.apply_snapshot(_final_snapshot(false, failed_ending))
	await process_frame
	await process_frame
	_check(verdict != null and verdict.text == "PROBATION TERMINATED", "failed restructuring should use its authored termination title", failures)
	_check(verdict != null and verdict.text != "PROBATION FAILED", "failed restructuring should not collapse to generic failure copy", failures)
	_check(
		ending_caption_1 != null and ending_caption_1.text == "FILE"
		and ending_value_1 != null and ending_value_1.text == "CLOSED"
		and ending_value_2 != null and ending_value_2.text == "RECORDED"
		and ending_value_3 != null and ending_value_3.text == "RECLAIMED",
		"terminated probation should summarize the file, flock, and badge outcomes at a glance",
		failures,
	)
	_check(continue_button != null and not continue_button.is_visible_in_tree(), "terminated probation should hide senior-roost continuation", failures)
	_check(new_button != null and not new_button.is_visible_in_tree() and not new_button.disabled and "RETRY PROBATION" in new_button.text, "terminated desktop probation should avoid duplicating the sticky retry in the scroll flow", failures)
	_check(new_button != null and new_button.focus_mode == Control.FOCUS_ALL and _shortcut_has_key(new_button, KEY_N), "retry should remain keyboard focusable with its N shortcut", failures)
	_check(leave_button != null and leave_button.focus_mode == Control.FOCUS_ALL and _shortcut_has_key(leave_button, KEY_A), "leave bureau should remain keyboard focusable with its A shortcut", failures)
	_check(sticky_bar != null and sticky_bar.is_visible_in_tree(), "failed desktop review should keep retry above the fold", failures)
	_check(sticky_primary != null and "RETRY PROBATION" in sticky_primary.text and _shortcut_has_key(sticky_primary, KEY_N), "failed sticky action should preserve retry and its shortcut", failures)
	_check(sticky_leave != null and _shortcut_has_key(sticky_leave, KEY_A), "sticky action strip should preserve the shelve-file shortcut", failures)
	_check(ui.get_viewport().gui_get_focus_owner() == sticky_primary, "failed ending should focus its visible sticky retry", failures)
	if sticky_primary != null:
		sticky_primary.pressed.emit()
	await process_frame
	await process_frame
	var replacement_host := ui.find_child("CampaignReplacementConfirmation", true, false) as Control
	var keep_button := ui.find_child("CancelCampaignReplacementButton", true, false) as Button
	var replace_button := ui.find_child("ConfirmCampaignReplacementButton", true, false) as Button
	_check(
		int(observed["new_campaign"]) == 0
		and replacement_host != null and replacement_host.is_visible_in_tree(),
		"failed ending sticky retry should require an explicit replacement confirmation",
		failures,
	)
	_check(
		keep_button != null and ui.get_viewport().gui_get_focus_owner() == keep_button,
		"failed ending retry confirmation should focus the safe keep-file action",
		failures,
	)
	if replace_button != null:
		replace_button.pressed.emit()
	_check(
		int(observed["new_campaign"]) == 1
		and replacement_host != null and not replacement_host.is_visible_in_tree(),
		"confirmed failed-ending retry should preserve the public new-campaign action exactly once",
		failures,
	)

	var memo_label := ui.find_child("FiledCreditMemoLabel", true, false) as Label
	var memo_card := ui.find_child("FiledCreditMemoCard", true, false) as PanelContainer
	await _check_credit_prefix(ui, memo_label, memo_card, {
		"day": 4,
		"decision_id": &"flock_restructuring",
		"option_id": &"contest_ranking",
		"worker_name": "Mabel",
		"outcome": "The ranking was contested collectively.",
	}, "FLOCK RESTRUCTURING FILED", failures)
	await _check_credit_prefix(ui, memo_label, memo_card, {
		"day": 3,
		"decision_id": &"golden_egg_dossier",
		"option_id": &"name_the_layer",
		"worker_name": "Henrietta",
		"outcome": "The golden layer entered the permanent coop record.",
	}, "GOLDEN DOSSIER FILED", failures)
	await _check_credit_prefix(ui, memo_label, memo_card, {
		"day": 2,
		"decision_id": &"closing_credit_memo",
		"option_id": &"reward_top_layer",
		"worker_name": "Babs",
		"outcome": "Routine shift credit was filed.",
	}, "CREDIT FILED", failures)

	ui.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPAIGN_ENDING_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPAIGN_ENDING_UI_TEST_PASSED endings=4 authored-titles beats=legacy+hen+office-future+replay controls=keyboard+focus+sticky-next-step portrait=wrapped memos=restructuring+golden+standard")
	quit(0)


func _final_snapshot(passed: bool, ending: Dictionary) -> Dictionary:
	return {
		"view": &"final",
		"day": 5,
		"total_days": 5,
		"score": 5100 if passed else 900,
		"rank": "Golden Rooster" if passed else "Loose Feather",
		"passed": passed,
		"ending": ending.duplicate(true),
		"final_message": "%s\n\nThe permanent coop record is now closed." % String(ending.get("coda", "")),
	}


func _check_credit_prefix(
	ui: Control,
	memo_label: Label,
	memo_card: PanelContainer,
	memo: Dictionary,
	expected_prefix: String,
	failures: Array[String],
) -> void:
	ui.apply_snapshot({
		"view": &"between_shift",
		"day": int(memo.get("day", 1)),
		"total_days": 5,
		"score": 2200,
		"rank": "Silver Comb",
		"credit_memo": memo.duplicate(true),
	})
	await process_frame
	_check(memo_card != null and memo_card.is_visible_in_tree(), "%s memo should be visible on its report day" % expected_prefix, failures)
	var visible_story_type := expected_prefix.trim_suffix(" FILED")
	_check(
		memo_label != null
		and memo_label.text == "CREDIT GOES TO"
		and bool(memo_label.get_meta("outcome_first_credit_heading", false)),
		"%s should use one outcome-first attribution heading without filing jargon" % expected_prefix,
		failures,
	)
	_check(
		memo_label != null
		and memo_label.tooltip_text.begins_with(expected_prefix + "  //")
		and visible_story_type in memo_label.tooltip_text
		and String(memo.get("outcome", "")) in memo_label.tooltip_text
		and String(memo_label.get_meta("accessible_text", "")).contains(
			String(memo.get("outcome", "")),
		),
		"%s should retain its filed outcome as progressive detail" % expected_prefix,
		failures,
	)
	_check(memo_label != null and memo_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "%s memo should remain readable when it wraps" % expected_prefix, failures)


func _shortcut_has_key(button: Button, keycode: Key) -> bool:
	if button == null or button.shortcut == null:
		return false
	for event: InputEvent in button.shortcut.events:
		if event is InputEventKey and (event as InputEventKey).keycode == keycode:
			return true
	return false


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
