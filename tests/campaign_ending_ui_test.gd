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
	_check(verdict != null and message != null, "final review should expose readable verdict and message labels", failures)
	_check(final_panel != null and modal_host != null, "final review should retain its blocking modal structure", failures)
	_check(continue_button != null and new_button != null and leave_button != null, "final review should retain all campaign actions", failures)

	var successful_endings: Array[Dictionary] = [
		{
			"id": &"farmer_favorite",
			"title": "FARMER'S FAVORITE",
			"coda": "The deck is clean, the quota is higher, and one chair is easier to explain.",
		},
		{
			"id": &"benevolent_rooster",
			"title": "BENEVOLENT ROOSTER",
			"coda": "Basic support survived because it was entered as an exception expense.",
		},
		{
			"id": &"collective_bargaining",
			"title": "THE FLOCK HAS A VOICE",
			"coda": "The workforce became a subject instead of a spreadsheet.",
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
		_check(final_panel != null and final_panel.is_visible_in_tree(), "%s should remain visible as the final review" % expected_title, failures)
		_check(modal_host != null and modal_host.is_visible_in_tree() and modal_host.mouse_filter == Control.MOUSE_FILTER_STOP, "%s should remain an intentional blocking modal" % expected_title, failures)
		_check(continue_button != null and continue_button.is_visible_in_tree() and not continue_button.disabled, "%s should offer senior-roost continuation" % expected_title, failures)
		_check(continue_button != null and continue_button.focus_mode == Control.FOCUS_ALL, "%s continuation should remain keyboard focusable" % expected_title, failures)
		_check(continue_button != null and _shortcut_has_key(continue_button, KEY_C), "%s continuation should retain its C shortcut" % expected_title, failures)
		_check(ui.get_viewport().gui_get_focus_owner() == continue_button, "%s should move keyboard focus to its primary continuation" % expected_title, failures)
		if continue_button != null:
			continue_button.pressed.emit()
	_check(int(observed["continue"]) == successful_endings.size(), "each successful ending should preserve the public continuation action", failures)

	# The longest authored title must remain readable in the portrait web layout.
	harness.size = Vector2(390.0, 844.0)
	ui.apply_snapshot(_final_snapshot(true, successful_endings[2]))
	await process_frame
	await process_frame
	_check(verdict != null and verdict.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "the long collective ending title should wrap for accessibility", failures)
	_check(verdict != null and verdict.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING, "authored ending titles should never be ellipsized", failures)
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
	_check(continue_button != null and not continue_button.is_visible_in_tree(), "terminated probation should hide senior-roost continuation", failures)
	_check(new_button != null and new_button.is_visible_in_tree() and not new_button.disabled and "RETRY PROBATION" in new_button.text, "terminated probation should expose an immediate retry", failures)
	_check(new_button != null and new_button.focus_mode == Control.FOCUS_ALL and _shortcut_has_key(new_button, KEY_N), "retry should remain keyboard focusable with its N shortcut", failures)
	_check(leave_button != null and leave_button.focus_mode == Control.FOCUS_ALL and _shortcut_has_key(leave_button, KEY_A), "leave bureau should remain keyboard focusable with its A shortcut", failures)
	_check(ui.get_viewport().gui_get_focus_owner() == new_button, "failed ending should move keyboard focus to retry", failures)
	if new_button != null:
		new_button.pressed.emit()
	_check(int(observed["new_campaign"]) == 1, "failed ending retry should preserve the public new-campaign action", failures)

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
	print("CAMPAIGN_ENDING_UI_TEST_PASSED endings=4 authored-titles controls=keyboard+focus portrait=wrapped memos=restructuring+golden+standard")
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
	_check(memo_label != null and memo_label.text.begins_with(expected_prefix + "  //"), "%s should use a distinct report prefix" % expected_prefix, failures)
	_check(memo_label != null and String(memo.get("outcome", "")) in memo_label.text, "%s should retain its filed outcome" % expected_prefix, failures)
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
