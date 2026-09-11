extends SceneTree

const SeniorRoostStateScript := preload("res://core/campaign/senior_roost_state.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.day = 18

	var successful_review := _annual_review_state(true, 1, 3)
	office.set("_campaign_senior_roost", true)
	office.set("_senior_roost_state", successful_review)
	var success_snapshot := office.call("_senior_presentation_snapshot", &"between_shift") as Dictionary
	_check(
		"Advanced mandate tier 1 unlocked for Year 2." in String(success_snapshot.get("report_note", "")),
		"a first Board Seal should announce the exact next-year tier unlock on the annual receipt",
		failures,
	)
	_check(
		"MANDATE TIER 1 UNLOCKED" in String((success_snapshot.get("next_objective", {}) as Dictionary).get("reward", "")),
		"the persistent reward line should connect the seal to its unlocked mandate tier",
		failures,
	)
	_check(
		"Career Sponsorship may be filed" in String(success_snapshot.get("report_note", "")),
		"an affordable annual Sponsorship should remain truthfully advertised",
		failures,
	)
	_check(
		"NEW BOOK MASTERED" in String(success_snapshot.get("report_note", "")) and "BOARD PORTFOLIO 1 / 7" in String(success_snapshot.get("report_note", "")),
		"a first successful Book should close with permanent portfolio recognition",
		failures,
	)

	var failed_review := _annual_review_state(false, 0, 0)
	office.set("_senior_roost_state", failed_review)
	var failed_snapshot := office.call("_senior_presentation_snapshot", &"between_shift") as Dictionary
	_check(
		"Sponsorship needs 3 available marks; 0 currently banked." in String(failed_snapshot.get("report_note", "")),
		"an unaffordable annual Sponsorship must disclose its exact mark goal instead of claiming availability",
		failures,
	)

	var recovery := SeniorRoostStateScript.new()
	recovery.completed_years = 1
	recovery.mandate_seals = 1
	recovery.roost_marks = 1
	recovery.mandate_success_counts[&"shell_stewardship"] = 1
	recovery.last_annual_review = {
		"year": 1,
		"passed": false,
		"score": 38,
		"welfare": 17,
		"compliance": 79,
		"farmer_favor": 26,
		"crack_rate_basis_points": 3170,
	}
	_check(recovery.begin(17, {"day": 18, "revenue_cents": 91_935, "quota_target": 26}), "Year 2 recovery fixture should open", failures)
	office.set("_senior_roost_state", recovery)
	var recovery_snapshot := office.call("_senior_presentation_snapshot", &"between_shift") as Dictionary
	var recovery_note := String(recovery_snapshot.get("report_note", ""))
	_check(
		"RECOVERY YEAR" in recovery_note and "BASELINE +2" in recovery_note and "FARMER FAVOR -5" in recovery_note,
		"Year 2 planning should restate the inherited recovery pressure before the player chooses a book",
		failures,
	)
	_check("PORTFOLIO 1 / 7 MASTERED" in recovery_note, "Year 2 planning should preserve the distinct-Book replay goal in the existing report", failures)
	var cards := recovery_snapshot.get("milestone_choices", []) as Array
	_check(cards.size() == 3, "recovery planning should retain exactly three Board Book cards", failures)
	var advanced: Dictionary = {}
	for card_value in cards:
		if card_value is Dictionary and int((card_value as Dictionary).get("effect", "").find("TIER 1")) >= 0:
			advanced = (card_value as Dictionary).duplicate(true)
			break
	_check(not advanced.is_empty(), "the unlocked tier-one Book should remain visible when its stake is short", failures)
	_check(not bool(advanced.get("available", true)), "the visible advanced Book must remain disabled without its two-mark stake", failures)
	_check(
		"1 more available Roost Mark is required" in String(advanced.get("unavailable_reason", "")),
		"the advanced card should disclose the exact one-mark recovery target",
		failures,
	)
	_check(
		"HELD" in String(advanced.get("effect", "")) and "1 MORE AVAILABLE ROOST MARK IS REQUIRED" in String(advanced.get("effect", "")),
		"the exact advanced-book shortfall should be visible on the card without requiring hover",
		failures,
	)
	var standard: Dictionary = {}
	var mutual: Dictionary = {}
	var shell: Dictionary = {}
	for card_value in cards:
		if card_value is Dictionary and String((card_value as Dictionary).get("id", "")) == "standard_board_book":
			standard = card_value as Dictionary
		elif card_value is Dictionary and String((card_value as Dictionary).get("id", "")) == "mutual_assurance":
			mutual = card_value as Dictionary
		elif card_value is Dictionary and String((card_value as Dictionary).get("id", "")) == "shell_stewardship":
			shell = card_value as Dictionary
	_check(bool(standard.get("available", false)), "the no-stake Standard Board Book must remain actionable during recovery", failures)
	_check("NEW PORTFOLIO CLEAR" in String(standard.get("effect", "")), "the unmastered fallback card should disclose its first-clear recognition", failures)
	_check("NEW PORTFOLIO CLEAR" in String(advanced.get("effect", "")), "the unmastered advanced card should disclose its first-clear recognition", failures)
	_check(not mutual.is_empty(), "mastery-aware recovery planning should use its variety slot for unmastered Mutual Assurance", failures)
	_check(shell.is_empty(), "mastery-aware recovery planning should retire cleared Shell Stewardship while first clears remain eligible", failures)

	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	campaign_ui.show_between_shift_report(recovery_snapshot)
	# Office startup can leave the normal morning-policy modal above this focused
	# fixture. The annual mandate report owns this capture and its input hierarchy.
	(office.get("_decision_host") as Control).visible = false
	await process_frame
	await process_frame
	var visible_advanced: Button = null
	for button_value in office.find_children("MilestoneChoice_*", "Button", true, false):
		var button := button_value as Button
		if "TIER 1" in button.text:
			visible_advanced = button
			break
	_check(visible_advanced != null and visible_advanced.is_visible_in_tree(), "the aspirational advanced card should render on the real report surface", failures)
	_check(visible_advanced != null and visible_advanced.disabled, "the rendered advanced card should reject activation while underfunded", failures)
	_check(visible_advanced != null and "HELD" in visible_advanced.text and "1 MORE AVAILABLE ROOST MARK IS REQUIRED" in visible_advanced.text, "the rendered locked card should show its recovery goal inline", failures)
	_check(visible_advanced != null and "1 more available Roost Mark is required" in visible_advanced.tooltip_text, "the rendered locked card should preserve its exact tooltip", failures)
	var standard_button := office.find_child("MilestoneChoice_standard_board_book", true, false) as Button
	_check(standard_button != null and not standard_button.disabled, "the rendered recovery surface should retain a safe available fallback", failures)
	_save_visual_capture(failures, "year-2-first-clear-offers.png")

	var rested_preparation := _rested_preparation_state(failures)
	office.set("_senior_roost_state", rested_preparation)
	var rested_snapshot := office.call("_senior_presentation_snapshot", &"between_shift") as Dictionary
	var rested_card: Dictionary = {}
	for card_value in rested_snapshot.get("milestone_choices", []) as Array:
		if card_value is Dictionary and String((card_value as Dictionary).get("id", "")) == "rested_flock_covenant":
			rested_card = (card_value as Dictionary).duplicate(true)
			break
	_check(not rested_card.is_empty(), "a three-seal career should render the Rested Flock bridge to Gold", failures)
	_check(
		"Grow to six hens and finish the care-and-candling buildout" in String(rested_card.get("description", "")),
		"the Rested Flock card should disclose the proven staffing and facility preparation path",
		failures,
	)
	campaign_ui.show_between_shift_report(rested_snapshot)
	await process_frame
	await process_frame
	var rested_button := office.find_child("MilestoneChoice_rested_flock_covenant", true, false) as Button
	_check(rested_button != null and rested_button.is_visible_in_tree(), "the Rested Flock bridge should render on the real annual report", failures)
	_check(rested_button != null and "Grow to six hens" in rested_button.text, "the rendered Rested Flock card should carry its preparation guidance inline", failures)
	_save_visual_capture(failures, "rested-flock-capital-guidance.png")

	var gold_capstone := _gold_capstone_state(failures)
	office.set("_senior_roost_state", gold_capstone)
	var gold_snapshot := office.call("_senior_presentation_snapshot", &"between_shift") as Dictionary
	var gold_card: Dictionary = {}
	for card_value in gold_snapshot.get("milestone_choices", []) as Array:
		if card_value is Dictionary and String((card_value as Dictionary).get("id", "")) == "gold_standard_book":
			gold_card = (card_value as Dictionary).duplicate(true)
			break
	_check(not gold_card.is_empty(), "a six-seal career should render the Gold Standard capstone", failures)
	_check(
		"Six hens plus mature speed, shell, care, and Candling investments" in String(gold_card.get("description", "")),
		"the Gold card should disclose its proven capital preparation instead of presenting an opaque perfect-year trap",
		failures,
	)
	campaign_ui.show_between_shift_report(gold_snapshot)
	await process_frame
	await process_frame
	var gold_button := office.find_child("MilestoneChoice_gold_standard_book", true, false) as Button
	_check(gold_button != null and gold_button.is_visible_in_tree(), "the Gold Standard capstone should render on the real annual report", failures)
	_check(gold_button != null and "Six hens plus mature speed" in gold_button.text, "the rendered Gold card should carry its preparation guidance inline", failures)
	_save_visual_capture(failures, "gold-standard-capital-guidance.png")

	var affordable := _recovery_state_with_marks(2, failures)
	office.set("_senior_roost_state", affordable)
	campaign_ui.show_between_shift_report(office.call("_senior_presentation_snapshot", &"between_shift") as Dictionary)
	await process_frame
	await process_frame
	var affordable_advanced: Button = null
	for button_value in office.find_children("MilestoneChoice_*", "Button", true, false):
		var button := button_value as Button
		if "TIER 1" in button.text:
			affordable_advanced = button
			break
	_check(affordable_advanced != null and not affordable_advanced.disabled, "an affordable advanced Book should render as actionable", failures)
	var affordable_advanced_id := String(
		affordable_advanced.get_meta("choice_id", "") if affordable_advanced != null else ""
	)
	if affordable_advanced != null:
		affordable_advanced.pressed.emit()
	await process_frame
	_check(affordable.requires_annual_mandate() and affordable.active_annual_mandate().is_empty(), "inspecting an advanced Book must not reserve marks or mutate the authoritative annual gate", failures)
	_check(affordable.available_roost_marks() == 2 and affordable.mandate_stake_reserved() == 0, "the first advanced activation should preserve both available marks", failures)
	var pending_confirmation := (campaign_ui.campaign_snapshot().get("pending_milestone_confirmation", {}) as Dictionary)
	_check(String(pending_confirmation.get("id", "")) == affordable_advanced_id and int(pending_confirmation.get("stake_marks", 0)) == 2, "the real Office surface should publish the exact pending stake", failures)
	var confirm_button := office.find_child("ContinueProbationButton", true, false) as Button
	_check(confirm_button != null and "CONFIRM 2-MARK STAKE" in confirm_button.text, "the real report action should require explicit stake confirmation", failures)
	if confirm_button != null:
		confirm_button.pressed.emit()
	await process_frame
	_check(not affordable.requires_annual_mandate() and String(affordable.active_annual_mandate().get("id", "")) == affordable_advanced_id, "confirming should file the inspected advanced Book authoritatively", failures)
	_check(affordable.available_roost_marks() == 0 and affordable.mandate_stake_reserved() == 2, "confirmation should reserve exactly two marks once", failures)

	(office.get("_clock") as SimulationClock).set_speed(0)
	# Allow renderer-backed optional visual staging to finish before this short-lived
	# capture harness releases the production Office tree.
	if "--capture-recovery" in OS.get_cmdline_user_args():
		await create_timer(0.5).timeout
	office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("SENIOR_YEAR_RECOVERY_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SENIOR_YEAR_RECOVERY_INTEGRATION_TEST_PASSED annual=tier-unlock sponsorship=truthful recovery=pressure advanced=visible-locked+confirm-first fallback=available")
	quit(0)


func _annual_review_state(passed: bool, seals: int, marks: int) -> SeniorRoostState:
	var senior := SeniorRoostStateScript.new()
	senior.status = SeniorRoostStateScript.STATUS_ANNUAL_REVIEW
	senior.completed_years = 1
	senior.completed_quarters = 4
	senior.successful_years = 1 if passed else 0
	senior.roost_marks = marks
	senior.mandate_seals = seals
	if passed:
		senior.mandate_success_counts[&"shell_stewardship"] = 1
	var reward := 1 if passed else 0
	var settlement := {
		"mandate_id": "shell_stewardship",
		"mandate_name": "SHELL STEWARDSHIP BOOK",
		"success": passed,
		"stake_marks": 0,
		"stake_returned": 0,
		"stake_forfeited": 0,
		"seal_reward": reward,
		"mandate_seals_after": seals,
		"available_roost_marks_after": marks,
		"outcome": (
			"Annual Board Mandate fulfilled; the seal was filed."
			if passed else
			"Annual Board Mandate failed; no seal was filed and no Roost Marks were at risk."
		),
	}
	senior.last_mandate_settlement = settlement.duplicate(true)
	senior.last_annual_review = {
		"year": 1,
		"passed": passed,
		"score": 72 if passed else 38,
		"welfare": 61 if passed else 17,
		"compliance": 76 if passed else 79,
		"farmer_favor": 58 if passed else 26,
		"crack_rate_basis_points": 1800 if passed else 3170,
		"mandate_settlement": settlement.duplicate(true),
	}
	return senior


func _recovery_state_with_marks(marks: int, failures: Array[String]) -> SeniorRoostState:
	var recovery := SeniorRoostStateScript.new()
	recovery.completed_years = 1
	recovery.mandate_seals = 1
	recovery.roost_marks = marks
	recovery.mandate_success_counts[&"shell_stewardship"] = 1
	recovery.last_annual_review = {
		"year": 1,
		"passed": false,
		"score": 38,
		"welfare": 17,
		"compliance": 79,
		"farmer_favor": 26,
		"crack_rate_basis_points": 3170,
	}
	_check(recovery.begin(17, {"day": 18, "revenue_cents": 91_935, "quota_target": 26}), "affordable recovery fixture should open", failures)
	return recovery


func _gold_capstone_state(failures: Array[String]) -> SeniorRoostState:
	var senior := SeniorRoostStateScript.new()
	senior.completed_years = 3
	senior.completed_quarters = 12
	senior.successful_years = 3
	senior.mandate_seals = 6
	senior.roost_marks = 6
	_check(
		senior.begin(41, {"day": 42, "revenue_cents": 803_385, "quota_target": 67}),
		"six-seal Gold capstone fixture should open",
		failures,
	)
	return senior


func _rested_preparation_state(failures: Array[String]) -> SeniorRoostState:
	var senior := SeniorRoostStateScript.new()
	senior.completed_years = 2
	senior.completed_quarters = 8
	senior.successful_years = 2
	senior.mandate_seals = 3
	senior.roost_marks = 4
	senior.mandate_success_counts[&"shell_stewardship"] = 1
	senior.mandate_success_counts[&"mutual_assurance"] = 1
	_check(
		senior.begin(29, {"day": 30, "revenue_cents": 406_500, "quota_target": 48}),
		"three-seal Rested Flock preparation fixture should open",
		failures,
	)
	return senior


func _save_visual_capture(failures: Array[String], filename: String) -> void:
	if "--capture-recovery" not in OS.get_cmdline_user_args():
		return
	var capture_directory := ProjectSettings.globalize_path(
		"res://output/web-game/cross-docket-senior-robustness-v1"
	)
	DirAccess.make_dir_recursive_absolute(capture_directory)
	var image := root.get_texture().get_image()
	_check(image != null, "recovery visual capture should expose a rendered viewport", failures)
	if image == null:
		return
	var save_error := image.save_png(capture_directory.path_join(filename))
	_check(save_error == OK, "recovery visual capture should save successfully", failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
