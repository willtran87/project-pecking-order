extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const TEST_SAVE_FILENAME := "campaign_intake_safety_test.json"


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
	office.call("_show_campaign_title", false)
	await process_frame
	await process_frame
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var fresh_next_action := office.call("_next_action_diagnostic_state") as Dictionary
	var fresh_summary := String(office.call(
		"_web_accessibility_summary",
		(office.get("_simulation") as DepartmentSimulation).snapshot(),
	))
	var fresh_announcement := office.call(
		"_web_accessibility_announcement",
		(office.get("_simulation") as DepartmentSimulation).snapshot(),
		fresh_summary,
	) as Dictionary
	_check(
		campaign_ui != null
		and campaign_ui.title_intake_phase() == &"new_file"
		and String(fresh_next_action.get("copy", "")) == "NEXT: CHOOSE DIFFICULTY"
		and String(fresh_next_action.get("action_id", "")) == "campaign_new"
		and bool(fresh_next_action.get("actionable", false))
		and "Choose a difficulty" in fresh_summary
		and "START SHIFT 1 [N]" in fresh_summary
		and String(fresh_announcement.get("kind", "")) == "career_intake"
		and "Choose a difficulty" in String(fresh_announcement.get("text", ""))
		and "pressure file" not in String(fresh_announcement.get("text", "")),
		"fresh intake diagnostics and narration should mirror the visible difficulty-to-start action [phase=%s next=%s summary=%s announcement=%s]" % [
			String(campaign_ui.title_intake_phase()) if campaign_ui != null else "missing",
			str(fresh_next_action),
			fresh_summary,
			str(fresh_announcement),
		],
		failures,
	)

	var blueprint := office.get("_capital_blueprint_ui") as CapitalBlueprintUI
	_check(
		blueprint != null and blueprint.set_filter(&"all"),
		"campaign fixture should be able to stage a retained ALL PLANS presentation filter",
		failures,
	)
	office.call("_on_campaign_new_requested")
	await process_frame
	var baseline := store.load()
	_check(not baseline.is_empty(), "new campaign should establish a verified baseline", failures)
	_check(
		String((baseline.get("metadata", {}) as Dictionary).get("reason", "")) == "new_campaign",
		"baseline checkpoint should identify the new campaign transaction",
		failures,
	)
	_check(
		blueprint != null
		and blueprint.active_filter_id() == &"ready"
		and blueprint.set_filter(&"all")
		and blueprint.visible_facility_ids().size() == 13,
		"New Campaign should reset Blueprint presentation to READY without removing the complete ALL PLANS catalog",
		failures,
	)
	var baseline_payload := (baseline.get("campaign", {}) as Dictionary).duplicate(true)

	# Returning to intake is a navigation action, not deletion. The exact payload is
	# checkpointed first and Continue remains available from the title surface.
	office.call("_on_campaign_abandon_requested")
	await process_frame
	await process_frame
	var shelved := store.load()
	var shelved_payload := shelved.get("campaign", {}) as Dictionary
	var shelved_session := shelved_payload.get("session", {}) as Dictionary
	var shelved_interface_context := (
		shelved_session.get("interface_context", {}) as Dictionary
	)
	var continue_button := office.find_child("ContinueCampaignButton", true, false) as Button
	_check(not shelved.is_empty() and store.has_save(), "return to intake must preserve a loadable campaign", failures)
	_check(
		_without_interface_context(shelved_payload)
		== _without_interface_context(baseline_payload),
		"shelving should preserve the exact authoritative campaign, simulation, Senior, and tutorial payload",
		failures,
	)
	_check(
		String(shelved_interface_context.get("capital_filter_id", "")) == "all",
		"shelving should intentionally checkpoint the player's current Blueprint filter instead of reverting it to the baseline presentation",
		failures,
	)
	_check(
		String((shelved.get("metadata", {}) as Dictionary).get("reason", "")) == "returned_to_intake",
		"safe return should file an explicit checkpoint reason",
		failures,
	)
	_check(
		campaign_ui != null and campaign_ui.modal_state() == ProbationCampaignUI.VIEW_TITLE
		and continue_button != null and not continue_button.disabled,
		"safe return should open intake with Continue available",
		failures,
	)
	var resume_next_action := office.call("_next_action_diagnostic_state") as Dictionary
	var resume_announcement := office.call(
		"_web_accessibility_announcement",
		(office.get("_simulation") as DepartmentSimulation).snapshot(),
	) as Dictionary
	_check(
		campaign_ui.title_intake_phase() == &"resume"
		and String(resume_next_action.get("copy", "")) == "NEXT: CONTINUE SAVED FILE"
		and String(resume_next_action.get("action_id", "")) == "campaign_continue"
		and bool(resume_next_action.get("actionable", false))
		and "CONTINUE SAVED FILE [C]" in String(resume_announcement.get("text", ""))
		and "review a new file without changing" in String(
			resume_announcement.get("text", "")
		).to_lower(),
		"resume intake diagnostics and narration should mirror the visible Continue-first hierarchy",
		failures,
	)

	office.call("_on_campaign_continue_requested")
	await process_frame
	await process_frame
	_check(
		campaign_ui.modal_state() == ProbationCampaignUI.VIEW_ACTIVE,
		"Continue should restore the safely shelved active checkpoint",
		failures,
	)

	# Replacement must leave the preceding valid primary as the recovery copy.
	# Removing the new primary simulates a failed/lost final commit and proves the
	# old file remains recoverable instead of being deleted up front.
	office.call("_on_campaign_new_requested")
	await process_frame
	var replacement := store.load()
	_check(
		String((replacement.get("metadata", {}) as Dictionary).get("reason", "")) == "new_campaign",
		"confirmed replacement should commit a fresh verified primary",
		failures,
	)
	var primary_path := String(store.get("_primary_path"))
	_check(FileAccess.file_exists(primary_path), "replacement primary should exist before recovery probe", failures)
	var remove_error := DirAccess.remove_absolute(primary_path)
	_check(remove_error == OK, "test should be able to simulate loss of the replacement primary", failures)
	var recovered := store.load()
	_check(
		not recovered.is_empty()
		and bool(recovered.get("recovered_from_backup", false))
		and String((recovered.get("metadata", {}) as Dictionary).get("reason", "")) == "returned_to_intake",
		"replacement should retain the prior shelved file as a verified recovery copy",
		failures,
	)

	# A paused campaign report owns one real action. Its disabled Next Shift
	# button must not leak through diagnostics before the required milestone is
	# selected, and activating the global action must reach the visible card.
	campaign_ui.show_between_shift_report({
		"day": 2,
		"total_days": 5,
		"score": 64,
		"rank": "Trusted Layer",
		"choice_required": true,
		"milestone_choices": [{
			"id": "report_action_fixture",
			"title": "Clear Peckwork Keys",
			"description": "Make the next shift's work easier to read.",
			"effect": "+8% processing speed",
		}],
		"next_objective": {
			"title": "Day 3 orders",
			"description": "File the next three farm orders.",
		},
	})
	await process_frame
	await process_frame
	var report_next_action := office.call("_next_action_diagnostic_state") as Dictionary
	var report_summary := String(office.call(
		"_web_accessibility_summary",
		(office.get("_simulation") as DepartmentSimulation).snapshot(),
	))
	var report_announcement := office.call(
		"_web_accessibility_announcement",
		(office.get("_simulation") as DepartmentSimulation).snapshot(),
		report_summary,
	) as Dictionary
	var report_choice := office.find_child(
		"MilestoneChoice_report_action_fixture",
		true,
		false,
	) as Button
	office.call("_on_guidance_action_pressed")
	await process_frame
	_check(
		String(report_next_action.get("copy", "")) == "NEXT: CHOOSE ONE PERMANENT EDGE"
		and String(report_next_action.get("action_id", "")) == "campaign_milestone"
		and bool(report_next_action.get("actionable", false))
		and "available permanent milestone cards" in String(report_next_action.get("accessible_text", ""))
		and "FINISH THE HIGHLIGHTED ACTION" not in String(report_next_action.get("copy", ""))
		and report_choice != null
		and root.gui_get_focus_owner() == report_choice,
		"campaign report diagnostics and activation should target the visible required milestone",
		failures,
	)
	_check(
		"Objective: Choose one of 1 available permanent milestone cards" in report_summary
		and String(report_announcement.get("kind", "")) == "campaign_record"
		and "Choose one of 1 available permanent milestone cards" in String(report_announcement.get("text", ""))
		and "available continuation" not in String(report_announcement.get("text", "")),
		"campaign report summary and live narration should name the same reachable milestone action",
		failures,
	)

	# The closing campaign card also owns an exact visible primary action. Global
	# guidance must reach Senior Roost (or Retry on a failed file) instead of
	# falling back to a disabled generic campaign instruction.
	campaign_ui.show_final_review({
		"day": 5,
		"score": 77,
		"rank": "Trusted Layer",
		"passed": true,
		"challenge_contract": {
			"id": "standard_filing",
			"label": "STANDARD FILING",
		},
	})
	await process_frame
	await process_frame
	var final_next_action := office.call("_next_action_diagnostic_state") as Dictionary
	var final_announcement := office.call(
		"_web_accessibility_announcement",
		(office.get("_simulation") as DepartmentSimulation).snapshot(),
	) as Dictionary
	var final_primary := office.find_child("FinalStickyPrimaryButton", true, false) as Button
	office.call("_on_guidance_action_pressed")
	await process_frame
	_check(
		final_primary != null
		and String(final_next_action.get("copy", "")) == final_primary.text
		and String(final_next_action.get("action_id", "")) == "campaign_final_continue"
		and bool(final_next_action.get("actionable", false))
		and "FINISH THE HIGHLIGHTED ACTION" not in String(final_next_action.get("copy", ""))
		and root.gui_get_focus_owner() == final_primary,
		"campaign final diagnostics and activation should target the visible Senior Roost action",
		failures,
	)
	_check(
		String(final_announcement.get("kind", "")) == "campaign_record"
		and "Campaign final review opened" in String(final_announcement.get("text", ""))
		and "optional Senior Roost" in String(final_announcement.get("text", ""))
		and "available continuation" not in String(final_announcement.get("text", "")),
		"campaign final narration should name the reachable visible continuation",
		failures,
	)

	root.remove_child(office)
	office.free()
	var cleanup_succeeded := store.delete()
	_check(cleanup_succeeded, "isolated campaign safety files should clean up", failures)

	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPAIGN_INTAKE_SAFETY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPAIGN_INTAKE_SAFETY_TEST_PASSED return=shelved+resumable replacement=confirmed+transactional recovery=prior-primary")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _without_interface_context(payload: Dictionary) -> Dictionary:
	var result := payload.duplicate(true)
	var session := result.get("session", {}) as Dictionary
	session.erase("interface_context")
	result["session"] = session
	return result
