extends SceneTree

const GalleryUIScript := preload("res://features/office/farmer_relations_gallery_ui.gd")
const RoostStaffingUIScript := preload("res://features/office/roost_staffing_ui.gd")
const ManagementUIThemeScript := preload("res://features/office/management_ui_theme.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var test_viewport := SubViewport.new()
	test_viewport.name = "FarmerRelationsScaleViewport"
	test_viewport.size = Vector2i(282, 760)
	test_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(test_viewport)
	var harness := Control.new()
	harness.name = "FarmerRelationsGalleryUITestHarness"
	harness.size = Vector2(282.0, 760.0)
	test_viewport.add_child(harness)

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
	var confirmation := ui.find_child(
		"FarmerRelationsCampaignConfirmation",
		true,
		false,
	) as ConfirmationDialog
	_check(layer != null and not layer.disabled and layer.focus_mode == Control.FOCUS_ALL and layer.text == "PUBLISH LAYER PROFILE", "Layer Profile should be a clear keyboard action", failures)
	_check(clutch != null and not clutch.disabled and clutch.text == "POST CLUTCH RESULTS", "Clutch Results should be a clear action", failures)
	_check(farmer != null and not farmer.disabled and farmer.text == "FRAME FARMER'S METHOD", "Farmer's Method should be a clear satirical action", failures)
	var layer_terms := ui.find_child("FarmerRelationsCampaignTerms_layer_profile", true, false) as Label
	var layer_evidence := ui.find_child("FarmerRelationsCampaignEvidence_layer_profile", true, false) as Label
	_check(layer_terms != null and _contains_all(layer_terms.text, ["cost $6.00", "payout $0.00", "fund -$6.00", "standing +4"]), "card terms should use authoritative integer economics", failures)
	_check(layer_evidence != null and _contains_all(layer_evidence.text, ["mabel", "7 eggs", "$12.40"]), "Layer Profile should cite the real named-hen shift", failures)
	if layer != null:
		layer.pressed.emit()
	await process_frame
	_check(
		confirmation != null
		and confirmation.visible
		and requests.is_empty()
		and _contains_all(
			confirmation.dialog_text,
			[
				"layer profile",
				"individual merit",
				"mabel",
				"cost $6.00",
				"payout $0.00",
				"net -$6.00",
				"standing",
				"+4",
				"permanent day 8",
				"cannot be undone",
			],
		),
		"publication should disclose its named subject, exact economics, standing, and permanent record before emitting",
		failures,
	)
	if confirmation != null:
		confirmation.canceled.emit()
	await process_frame
	_check(requests.is_empty(), "canceling publication should preserve the open campaign allowance", failures)
	if layer != null:
		layer.pressed.emit()
	await process_frame
	if confirmation != null:
		confirmation.confirmed.emit()
	await process_frame
	_check(requests == [&"layer_profile"], "one confirmed card should emit its stable campaign ID exactly once", failures)
	if confirmation != null:
		confirmation.confirmed.emit()
	_check(requests == [&"layer_profile"], "duplicate publication confirmation must not emit twice", failures)

	var prior_theme := ui.theme
	var control_records := _capture_control_records(ui)
	ui.theme = ManagementUIThemeScript.create_theme(false, 1.5)
	_apply_explicit_font_scale(ui, 1.5)
	await process_frame
	await process_frame
	if "--capture-max-scale-farmer-relations" in OS.get_cmdline_user_args():
		var capture_directory := ProjectSettings.globalize_path(
			"res://output/web-game/farmer-relations-scale-v1"
		)
		DirAccess.make_dir_recursive_absolute(capture_directory)
		var image := test_viewport.get_texture().get_image()
		if image != null:
			_check(
				image.save_png(capture_directory.path_join(
					"farmer-relations-282x760-150.png"
				)) == OK,
				"authored Farmer Relations capture should save",
				failures,
			)
	_expand_interface_copy(ui)
	await process_frame
	await process_frame
	var ui_rect := ui.get_global_rect()
	_check(
		ui.get_combined_minimum_size().x <= scroll.size.x + 0.5
		and _visible_children_fit_horizontally(ui, ui_rect),
		"150-percent expanded Farmer Relations should remain vertical-only (minimum=%s viewport=%s)"
		% [ui.get_combined_minimum_size(), scroll.size],
		failures,
	)
	farmer = ui.find_child(
		"FarmerRelationsCampaignButton_farmer_method",
		true,
		false,
	) as Button
	if farmer != null:
		scroll.ensure_control_visible(farmer)
	await process_frame
	await process_frame
	_check(
		farmer != null
		and farmer.is_visible_in_tree()
		and scroll.get_global_rect().intersects(farmer.get_global_rect()),
		"the farmer-credit publication should remain physically reachable at max scale",
		failures,
	)
	if farmer != null:
		farmer.pressed.emit()
	await process_frame
	confirmation = ui.find_child(
		"FarmerRelationsCampaignConfirmation",
		true,
		false,
	) as ConfirmationDialog
	_check(
		confirmation != null
		and confirmation.visible
		and _contains_all(
			confirmation.dialog_text,
			[
				"farmer",
				"mabel",
				"cost $0.00",
				"payout $10.00",
				"net +$10.00",
				"permanent",
			],
		),
		"farmer-credit review should retain named labor and exact economic effects",
		failures,
	)
	var confirmation_records := _capture_control_records(confirmation)
	_apply_explicit_font_scale(confirmation, 1.5)
	_expand_interface_copy(confirmation)
	await process_frame
	await process_frame
	_check(
		confirmation != null
		and confirmation.size.x <= 390
		and confirmation.size.y <= 844
		and _popup_control_fits(confirmation, confirmation.get_ok_button())
		and _popup_control_fits(confirmation, confirmation.get_cancel_button()),
		"expanded public-campaign review should fit 390x844 with both choices reachable (size=%s)"
		% [confirmation.size if confirmation != null else Vector2i.ZERO],
		failures,
	)
	if (
		"--capture-max-scale-farmer-relations" in OS.get_cmdline_user_args()
		and confirmation != null
	):
		var capture_directory := ProjectSettings.globalize_path(
			"res://output/web-game/farmer-relations-scale-v1"
		)
		var confirmation_image := confirmation.get_texture().get_image()
		if confirmation_image != null:
			_check(
				confirmation_image.save_png(capture_directory.path_join(
					"farmer-relations-confirmation-150.png"
				)) == OK,
				"authored Farmer Relations confirmation capture should save",
				failures,
			)
	_restore_control_records(confirmation_records)
	if confirmation != null:
		confirmation.canceled.emit()
	_restore_control_records(control_records)
	ui.theme = prior_theme
	await process_frame
	await process_frame

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
	if layer != null:
		layer.pressed.emit()
	await process_frame
	_check(
		requests == [&"layer_profile"]
		and confirmation != null
		and not confirmation.visible,
		"a stale disabled publication action must fail closed before Office",
		failures,
	)
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

	test_viewport.queue_free()
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
	await process_frame
	var confirmation := staffing.find_child(
		"FarmerRelationsCampaignConfirmation",
		true,
		false,
	) as ConfirmationDialog
	if confirmation != null:
		confirmation.confirmed.emit()
	await process_frame
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


func _visible_children_fit_horizontally(
	root_control: Control,
	root_rect: Rect2,
) -> bool:
	for node_value: Node in root_control.find_children(
		"*",
		"Control",
		true,
		false,
	):
		var control := node_value as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		if (
			rect.position.x < root_rect.position.x - 0.5
			or rect.end.x > root_rect.end.x + 0.5
		):
			return false
	return true


func _popup_control_fits(popup: Window, control: Control) -> bool:
	if popup == null or control == null or not control.is_visible_in_tree():
		return false
	return Rect2(Vector2.ZERO, Vector2(popup.size)).encloses(
		control.get_global_rect()
	)


func _capture_control_records(root_node: Node) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if root_node == null:
		return records
	for node_value: Node in root_node.find_children(
		"*",
		"Control",
		true,
		false,
	):
		var control := node_value as Control
		var record := {
			"control": control,
			"had_font_override": control.has_theme_font_size_override(
				"font_size"
			),
			"font_size": control.get_theme_font_size("font_size"),
			"kind": &"",
			"text": "",
		}
		if control is Button:
			record["kind"] = &"button"
			record["text"] = (control as Button).text
		elif control is Label:
			record["kind"] = &"label"
			record["text"] = (control as Label).text
		records.append(record)
	return records


func _restore_control_records(records: Array[Dictionary]) -> void:
	for record: Dictionary in records:
		var value: Variant = record.get("control")
		if not is_instance_valid(value):
			continue
		var control := value as Control
		if control == null:
			continue
		match StringName(record.get("kind", &"")):
			&"button":
				(control as Button).text = String(record.get("text", ""))
			&"label":
				(control as Label).text = String(record.get("text", ""))
		if bool(record.get("had_font_override", false)):
			control.add_theme_font_size_override(
				"font_size",
				int(record.get("font_size", 16)),
			)
		else:
			control.remove_theme_font_size_override("font_size")


func _apply_explicit_font_scale(root_node: Node, scale: float) -> void:
	if root_node == null:
		return
	for node_value: Node in root_node.find_children(
		"*",
		"Control",
		true,
		false,
	):
		var control := node_value as Control
		if (
			control != null
			and control.has_theme_font_size_override("font_size")
		):
			var base_size := control.get_theme_font_size("font_size")
			control.add_theme_font_size_override(
				"font_size",
				maxi(10, roundi(float(base_size) * scale)),
			)


func _expand_interface_copy(root_node: Node) -> void:
	if root_node == null:
		return
	for node_value: Node in root_node.find_children(
		"*",
		"Control",
		true,
		false,
	):
		if node_value is Button:
			var button := node_value as Button
			button.text = _expanded(button.text)
		elif node_value is Label:
			var label := node_value as Label
			label.text = _expanded(label.text)


func _expanded(source: String) -> String:
	var expanded := source
	for vowel: String in [
		"a",
		"e",
		"i",
		"o",
		"u",
		"A",
		"E",
		"I",
		"O",
		"U",
	]:
		expanded = expanded.replace(vowel, vowel + vowel)
	return expanded


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
