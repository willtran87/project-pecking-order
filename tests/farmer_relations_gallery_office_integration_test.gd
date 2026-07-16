extends SceneTree

const OfficeScript := preload("res://features/office/office.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := OfficeScript.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var simulation = office.get("_simulation")
	var harvest_credit = simulation.get("_harvest_credit")
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	_check(simulation != null and harvest_credit != null and campaign_ui != null, "Office should own the authoritative simulation, campaign surface, and Harvest Credit ledger", failures)
	if simulation == null or harvest_credit == null or campaign_ui == null:
		_finish(failures)
		return

	# This is a post-induction closing review. Retire the campaign title and the
	# optional coach so Flockwatch owns the same presentation a real later shift
	# would expose.
	office.set("_campaign_review_stage", &"active")
	campaign_ui.show_active_campaign()
	office.call("_reset_first_clutch", false)
	office.call("_set_campaign_modal_open", false)

	simulation.owned_facilities[&"farmer_relations_gallery"] = 1
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	var evidence := {
		"day": 2,
		"eggs": 26,
		"quota": 24,
		"sound": 25,
		"cracked": 1,
		"golden": 1,
		"met_quota": true,
		"top_worker_id": 0,
		"top_worker_name": "Mabel",
		"hen_highlight": {"worker_id": 0, "worker_name": "Mabel"},
	}
	_check(harvest_credit.stage_review(evidence, 1, false), "fixture should stage one post-credit campaign offer", failures)
	office.set("_campaign_review_stage", &"credit")
	office.call("_on_snapshot_changed", simulation.snapshot())
	office.call("_advance_after_closing_credit")
	await process_frame
	await process_frame

	var flockwatch := office.find_child("FlockwatchLedger", true, false) as PanelContainer
	var gallery := office.find_child("FarmerRelationsGalleryUI", true, false) as Control
	var continue_button := office.find_child("ContinueDirectiveButton", true, false) as Button
	var navigation := office.find_child("FlockwatchNavigation", true, false) as FlockwatchNavigation
	var records_scroll := (
		navigation.page_scroll(FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS)
		if navigation != null else
		null
	) as ScrollContainer
	var context_actions := navigation.context_actions() if navigation != null else null
	_check(flockwatch != null and flockwatch.visible, "post-credit review should open the existing Flockwatch ledger", failures)
	_check(gallery != null and gallery.is_visible_in_tree(), "the real Gallery offer should be visible inline without a modal", failures)
	_check(continue_button != null and continue_button.text == "CONTINUE: SKIP PUBLIC CAMPAIGN", "the existing continue action should make the optional skip explicit", failures)
	_check(StringName(office.get("_campaign_review_stage")) == &"credit", "Gallery review should reuse the restorable credit stage", failures)
	_check(navigation != null and navigation.current_page_id() == FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS, "Gallery review should deep-link the existing Records page", failures)
	_check(records_scroll != null and records_scroll.is_visible_in_tree(), "Gallery review should expose the Records page's own scroll", failures)
	_check(records_scroll != null and gallery != null and records_scroll.is_ancestor_of(gallery), "the Gallery offer should live inside the Records scroll", failures)
	_check(context_actions != null and continue_button != null and continue_button.get_parent() == context_actions, "Continue should be hosted by Flockwatch's global context actions", failures)
	_check(context_actions != null and context_actions.is_visible_in_tree() and continue_button != null and continue_button.is_visible_in_tree(), "the global Continue action should remain visible while Records is current", failures)
	_check(continue_button != null and continue_button.focus_mode != Control.FOCUS_NONE, "the global Continue action should remain keyboard-focusable from Records", failures)
	_check(records_scroll != null and continue_button != null and not records_scroll.is_ancestor_of(continue_button), "the global Continue action should not scroll away with Records content", failures)

	if records_scroll != null:
		records_scroll.scroll_vertical = 180
		await process_frame
	var scroll_before := records_scroll.scroll_vertical if records_scroll != null else 0
	var layer := office.find_child("FarmerRelationsCampaignButton_layer_profile", true, false) as Button
	_check(layer != null and not layer.disabled, "the real post-credit Layer Profile should be actionable", failures)
	if layer != null:
		layer.pressed.emit()
	await process_frame
	await process_frame

	var filed: Dictionary = simulation.farmer_relations_gallery_snapshot()
	var receipt := filed.get("last_receipt", {}) as Dictionary
	var receipt_label := office.find_child("FarmerRelationsGalleryLastReceipt", true, false) as Label
	_check(StringName(filed.get("campaign_status", &"")) == &"filed", "button intent should file the authoritative campaign", failures)
	_check(StringName(receipt.get("campaign_id", &"")) == &"layer_profile" and int(receipt.get("payout_cents", 0)) > 0, "receipt should retain the selected campaign and real payout", failures)
	_check(receipt_label != null and _contains_all(receipt_label.text, ["day 2", "layer profile", "mabel", "payout"]), "Flockwatch should replace the offer with its permanent receipt", failures)
	_check(flockwatch != null and flockwatch.visible, "filing should leave Flockwatch open", failures)
	_check(navigation != null and navigation.current_page_id() == FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS, "filing should preserve Records as the current page", failures)
	_check(records_scroll != null and records_scroll.scroll_vertical == scroll_before, "campaign receipt refresh should preserve the Records scroll", failures)
	_check(continue_button != null and continue_button.text == "CONTINUE: FILE SHIFT REPORT", "filed campaign should expose the existing progression action", failures)
	_check(continue_button != null and continue_button.get_parent() == context_actions and continue_button.is_visible_in_tree(), "the filed progression action should remain in the visible global context host", failures)
	_check(continue_button != null and continue_button.has_focus(), "keyboard focus should move to the safe Continue action after filing", failures)

	var second: Dictionary = simulation.file_farmer_relations_campaign(&"farmer_method")
	_check(not bool(second.get("accepted", true)) and _contains_all(String(second.get("reason", "")), ["already", "filed"]), "a second campaign for the completed shift should reject authoritatively", failures)

	if continue_button != null:
		continue_button.pressed.emit()
	await process_frame
	_check(StringName(office.get("_campaign_review_stage")) == &"probation", "Continue should advance from the filed Gallery to the normal shift report", failures)

	var skipped_evidence := evidence.duplicate(true)
	skipped_evidence["day"] = 3
	skipped_evidence["eggs"] = 22
	skipped_evidence["quota"] = 24
	skipped_evidence["sound"] = 21
	skipped_evidence["met_quota"] = false
	_check(harvest_credit.stage_review(skipped_evidence, 1, false), "fixture should stage a second optional campaign", failures)
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office.set("_campaign_review_stage", &"credit")
	office.call("_on_snapshot_changed", simulation.snapshot())
	office.call("_advance_after_closing_credit")
	await process_frame
	_check(continue_button != null and continue_button.text == "CONTINUE: SKIP PUBLIC CAMPAIGN", "a later open offer should restore the explicit skip action", failures)
	_check(navigation != null and navigation.current_page_id() == FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS, "a later Gallery offer should deep-link Records again", failures)
	_check(continue_button != null and continue_button.get_parent() == context_actions and continue_button.is_visible_in_tree() and continue_button.focus_mode != Control.FOCUS_NONE, "the restored skip action should remain globally placed, visible, and focusable", failures)
	if continue_button != null:
		continue_button.pressed.emit()
	await process_frame
	var skipped: Dictionary = simulation.farmer_relations_gallery_snapshot()
	_check(StringName(skipped.get("campaign_status", &"")) == &"skipped", "Continue should file an authoritative no-release receipt before advancing", failures)
	_check(StringName(office.get("_campaign_review_stage")) == &"probation", "skipping should advance to the same normal shift report", failures)

	office.queue_free()
	await process_frame
	_finish(failures)


func _contains_all(copy: String, needles: Array[String]) -> bool:
	var normalized := copy.to_lower()
	for needle in needles:
		if needle.to_lower() not in normalized:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _finish(failures: Array[String]) -> void:
	if not failures.is_empty():
		for failure in failures:
			push_error("FARMER_RELATIONS_GALLERY_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARMER_RELATIONS_GALLERY_OFFICE_INTEGRATION_TEST_PASSED flow=credit-gallery-report mutation=authoritative receipt=permanent scroll-focus=preserved duplicate=rejected")
	quit(0)
