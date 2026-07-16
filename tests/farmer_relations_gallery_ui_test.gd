extends SceneTree

const GalleryUIScript := preload("res://features/office/farmer_relations_gallery_ui.gd")
const RoostStaffingUIScript := preload("res://features/office/roost_staffing_ui.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var harness := Control.new()
	harness.name = "FarmerRelationsGalleryUITestHarness"
	harness.size = Vector2(282.0, 620.0)
	root.add_child(harness)

	var scroll := ScrollContainer.new()
	scroll.name = "FarmerRelationsGalleryTestScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	harness.add_child(scroll)

	var ui := GalleryUIScript.new()
	ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(ui)
	await process_frame

	var requests: Array[StringName] = []
	ui.campaign_requested.connect(func(campaign_id: StringName) -> void: requests.append(campaign_id))
	ui.apply_snapshot({"farmer_relations_gallery": _gallery_snapshot()})
	await process_frame
	await process_frame

	var standing := ui.find_child("FarmerRelationsGalleryStanding", true, false) as Label
	var status := ui.find_child("FarmerRelationsGalleryStatus", true, false) as Label
	var attribution := ui.find_child("FarmerRelationsGalleryAttribution", true, false) as Label
	var evidence := ui.find_child("FarmerRelationsGalleryEvidence", true, false) as Label
	var receipt := ui.find_child("FarmerRelationsGalleryLastReceipt", true, false) as Label
	_check(ui.visible, "an installed Gallery should occupy one inline Flockwatch section", failures)
	_check(standing != null and _contains_all(standing.text, ["public standing", "barnwide", "14 pts"]), "standing should use the canonical label and points", failures)
	_check(status != null and _contains_all(status.text, ["campaign 0 / 1", "offer open"]), "status should disclose the one-campaign allowance", failures)
	_check(attribution != null and _contains_all(attribution.text, ["individual merit", "mabel"]), "attribution should name the filed closing-credit style and subject", failures)
	_check(evidence != null and _contains_all(evidence.text, ["day 8", "29 / 24 eggs", "2 cracked", "1 golden"]), "summary should retain the frozen shift evidence", failures)
	_check(receipt != null and _contains_all(receipt.text, ["day 7", "clutch results board", "+3", "$8.00", "+$4.00"]), "the last hung receipt should disclose standing and exact cash effects", failures)

	var layer := ui.find_child("FarmerRelationsCampaignButton_layer_profile", true, false) as Button
	var clutch := ui.find_child("FarmerRelationsCampaignButton_clutch_results_board", true, false) as Button
	var farmer := ui.find_child("FarmerRelationsCampaignButton_farmer_method", true, false) as Button
	_check(layer != null and not layer.disabled and layer.focus_mode == Control.FOCUS_ALL and layer.text == "PUBLISH LAYER PROFILE", "Layer Profile should be a clear keyboard action", failures)
	_check(clutch != null and not clutch.disabled and clutch.text == "POST CLUTCH RESULTS", "Clutch Results should be a clear action", failures)
	_check(farmer != null and not farmer.disabled and farmer.text == "FRAME FARMER'S METHOD", "Farmer's Method should be a clear satirical action", failures)
	var layer_terms := ui.find_child("FarmerRelationsCampaignTerms_layer_profile", true, false) as Label
	var layer_evidence := ui.find_child("FarmerRelationsCampaignEvidence_layer_profile", true, false) as Label
	_check(layer_terms != null and _contains_all(layer_terms.text, ["cost $6.00", "payout $0.00", "fund -$6.00", "standing +4"]), "card terms should use authoritative integer economics", failures)
	_check(layer_evidence != null and _contains_all(layer_evidence.text, ["mabel", "7 eggs", "$12.40"]), "Layer Profile should cite the real named-hen shift", failures)
	if layer != null:
		layer.pressed.emit()
	_check(requests == [&"layer_profile"], "an enabled card should emit its stable campaign ID exactly once", failures)

	# Applying a changed compact projection updates controls in place. It must not
	# clear the shared ledger or rebuild the card that currently owns keyboard focus.
	scroll.scroll_vertical = 240
	await process_frame
	var previous_layer := layer
	var filed := _gallery_snapshot()
	filed["campaign_status"] = "filed"
	filed["campaigns_used"] = 1
	filed["last_receipt"] = {
		"day": 8,
		"campaign_id": "layer_profile",
		"campaign_label": "Layer Profile",
		"standing_delta": 4,
		"cost_cents": 600,
		"payout_cents": 0,
		"fund_delta_cents": -600,
		"outcome": "Mabel's credited shift now hangs under her own name.",
	}
	for offer_value in filed["offers"]:
		var offer := offer_value as Dictionary
		offer["can_authorize"] = false
		offer["reason"] = "One public campaign has already been filed for this shift."
	ui.apply_snapshot(filed)
	await process_frame
	_check(ui.find_child("FarmerRelationsCampaignButton_layer_profile", true, false) == previous_layer, "snapshot refresh should preserve the authored button node", failures)
	_check(layer != null and layer.disabled and _contains_all(layer.tooltip_text, ["already been filed"]), "all campaigns should hold after the daily authorization is used", failures)
	_check(scroll.scroll_vertical > 0, "a receipt refresh should preserve the shared Flockwatch scroll", failures)
	_check(receipt != null and _contains_all(receipt.text, ["day 8", "layer profile", "mabel", "-$6.00"]), "accepted publication should replace the receipt in place", failures)

	var pre_credit := _gallery_snapshot()
	pre_credit["campaign_status"] = "pre_credit"
	pre_credit["review_open"] = true
	for offer_value in pre_credit["offers"]:
		var offer := offer_value as Dictionary
		offer["can_authorize"] = false
		offer["reason"] = "File the closing credit memo first."
	ui.apply_snapshot(pre_credit)
	await process_frame
	_check(layer != null and layer.disabled and _contains_all(layer.tooltip_text, ["closing credit memo first"]), "pre-credit cards should explain the exact sequencing gate", failures)

	ui.apply_snapshot({"farmer_relations_gallery": {"level": 0, "campaign_status": "locked", "offers": []}})
	await process_frame
	_check(not ui.visible, "an unbuilt Gallery with no receipt should not consume Flockwatch space", failures)

	await _test_staffing_forwarding(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("FARMER_RELATIONS_GALLERY_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARMER_RELATIONS_GALLERY_UI_TEST_PASSED cards=3 width=282 attribution=frozen receipt=permanent scroll=preserved signal=stable")
	quit(0)


func _test_staffing_forwarding(failures: Array[String]) -> void:
	var harness := Control.new()
	harness.size = Vector2(360.0, 900.0)
	root.add_child(harness)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	harness.add_child(scroll)
	var staffing := RoostStaffingUIScript.new() as RoostStaffingUI
	staffing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(staffing)
	await process_frame
	staffing.apply_snapshot({
		"active_staff_count": 4,
		"office_capacity": 4,
		"maximum_staff_capacity": 6,
		"staffing_planning_open": true,
		"daily_payroll_cents": 4_000,
		"daily_facility_cost_cents": 500,
		"daily_operating_cost_cents": 4_500,
		"spendable_fund_cents": 40_000,
		"revenue_cents": 50_000,
		"wage_arrears_cents": 0,
		"farmer_relations_gallery": _gallery_snapshot(),
		"facility_catalog": [],
		"workers": [],
		"staffing_applicants": [],
	})
	await process_frame
	var embedded := staffing.find_child("FarmerRelationsGalleryUI", true, false) as Control
	_check(embedded != null and embedded.visible, "Roost Staffing should compose the Gallery near the top of the existing ledger", failures)
	var forwarded: Array[StringName] = []
	staffing.farmer_relations_campaign_requested.connect(
		func(campaign_id: StringName) -> void: forwarded.append(campaign_id)
	)
	var action := staffing.find_child("FarmerRelationsCampaignButton_farmer_method", true, false) as Button
	if action != null:
		action.pressed.emit()
	_check(forwarded == [&"farmer_method"], "the Flockwatch host should forward campaign identity without translation", failures)
	harness.queue_free()
	await process_frame


func _gallery_snapshot() -> Dictionary:
	return {
		"version": 1,
		"level": 2,
		"max_level": 3,
		"campaign_status": "offer_open",
		"completed_day": 8,
		"review_open": true,
		"campaign_limit": 1,
		"campaigns_used": 0,
		"standing_points": 14,
		"standing_label": "Barnwide",
		"attribution": {
			"style_id": "individual_merit",
			"style_label": "Individual Merit",
			"worker_id": 0,
			"worker_name": "Mabel",
		},
		"shift_evidence": {
			"day": 8,
			"eggs": 29,
			"quota": 24,
			"sound": 27,
			"cracked": 2,
			"golden": 1,
		},
		"offers": [
			_offer("layer_profile", "Layer Profile", "Put Mabel and her real shift on the wall.", "Mabel / 7 eggs / $12.40 credited", 600, 0, -600, 4),
			_offer("clutch_results_board", "Clutch Results Board", "Publish the actual clutch without erasing shell quality.", "29 / 24 eggs / 27 sound / 2 cracked / 1 golden", 800, 1_200, 400, 3),
			_offer("farmer_method", "Farmer's Method", "Turn the same shift into a leadership case study.", "Individual Merit attribution / $48.00 credited", 0, 1_000, 1_000, 1),
		],
		"last_receipt": {
			"day": 7,
			"campaign_id": "clutch_results_board",
			"campaign_label": "Clutch Results Board",
			"standing_delta": 3,
			"cost_cents": 800,
			"payout_cents": 1_200,
			"fund_delta_cents": 400,
			"outcome": "The complete clutch now hangs beside the farmer's portrait.",
		},
	}


func _offer(
	id: String,
	label: String,
	tagline: String,
	evidence: String,
	cost_cents: int,
	payout_cents: int,
	fund_delta_cents: int,
	standing_delta: int,
) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"tagline": tagline,
		"evidence": evidence,
		"preview": "This exact publication changes standing and the permanent labor record.",
		"cost_cents": cost_cents,
		"payout_cents": payout_cents,
		"fund_delta_cents": fund_delta_cents,
		"standing_delta": standing_delta,
		"can_authorize": true,
		"reason": "Closing credit filed; 0 of 1 campaign used.",
	}


func _contains_all(copy: String, needles: Array[String]) -> bool:
	var normalized := copy.to_lower()
	for needle in needles:
		if needle.to_lower() not in normalized:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
