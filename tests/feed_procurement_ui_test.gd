extends SceneTree

const FeedProcurementUIScript := preload("res://features/office/feed_procurement_ui.gd")
const RoostStaffingUIScript := preload("res://features/office/roost_staffing_ui.gd")
const ManagementUIThemeScript := preload("res://features/office/management_ui_theme.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var test_viewport := SubViewport.new()
	test_viewport.name = "FeedProcurementTestViewport"
	test_viewport.size = Vector2i(282, 760)
	test_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(test_viewport)
	var harness := Control.new()
	harness.name = "FeedProcurementUITestHarness"
	harness.size = Vector2(282.0, 760.0)
	test_viewport.add_child(harness)

	var scroll := ScrollContainer.new()
	scroll.name = "FeedProcurementTestScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	harness.add_child(scroll)

	var ui := FeedProcurementUIScript.new() as FeedProcurementUI
	ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(ui)
	await process_frame

	var requests: Array[StringName] = []
	ui.feed_order_requested.connect(func(order_id: StringName) -> void: requests.append(order_id))
	ui.apply_snapshot(_root_snapshot(true))
	await process_frame
	await process_frame

	var quote := ui.find_child("FeedProcurementSeasonQuote", true, false) as Label
	var inventory := ui.find_child("FeedProcurementInventory", true, false) as Label
	var stock_glance := ui.find_child("FeedProcurementStockGlance", true, false) as Label
	var demand_glance := ui.find_child("FeedProcurementDemandGlance", true, false) as Label
	var after_glance := ui.find_child("FeedProcurementAfterGlance", true, false) as Label
	var spot_glance := ui.find_child("FeedProcurementSpotGlance", true, false) as Label
	var fallback := ui.find_child("FeedProcurementSpotFallback", true, false) as Label
	var active_ration := ui.find_child("FeedProcurementActiveRation", true, false) as Label
	var offers := ui.find_children("FeedProcurementOffer_*", "PanelContainer", true, false)
	_check(ui.visible, "a canonical feed_procurement snapshot should reveal the inline section", failures)
	_check(quote != null and _contains_all(quote.text, ["harvest shoulder", "$1.80", "2d"]), "the visible market quote should be glance-first", failures)
	_check(quote != null and _contains_all(quote.tooltip_text, ["spot $1.80 per scoop", "days 7-9", "2 days left", "base $2.00"]), "the market quote tooltip should retain its exact window and base comparison", failures)
	_check(inventory != null and not inventory.visible and _contains_all(inventory.text, ["stock", "8 / 20 scoops", "next-shift demand 5", "after rations 3", "coverage 1.6 shifts", "spot shortage 0"]), "the hidden inventory filing should retain every exact planning metric", failures)
	_check(stock_glance != null and _contains_all(stock_glance.text, ["stock", "8 / 20"]), "the feed board should lead with stock and capacity", failures)
	_check(demand_glance != null and _contains_all(demand_glance.text, ["need", "5"]), "the feed board should expose next-shift need without prose", failures)
	_check(after_glance != null and _contains_all(after_glance.text, ["after", "3"]), "the feed board should expose the post-ration remainder", failures)
	_check(spot_glance != null and _contains_all(spot_glance.text, ["spot", "$1.80"]), "the feed board should expose the automatic spot price", failures)
	_check(stock_glance != null and _contains_all(stock_glance.tooltip_text, ["coverage 1.6 shifts", "spot shortage 0"]), "glance tiles should retain the complete inventory filing on demand", failures)
	_check(fallback != null and _contains_all(fallback.text, ["auto-buy", "covered"]), "the visible fallback should communicate safety without a paragraph", failures)
	_check(fallback != null and _contains_all(fallback.tooltip_text, ["automatic spot fallback", "$1.80", "no order is required to continue"]), "the fallback tooltip should retain the exact automatic-purchase rule", failures)
	_check(active_ration != null and active_ration.visible and _contains_all(active_ration.text, ["active", "strain -10%", "morale +2", "griev -1"]), "a consequential active ration should remain visible in compact form", failures)
	_check(offers.size() == 3, "the fixed supplier file should show exactly one card for each canonical offer", failures)

	var local_terms := ui.find_child("FeedProcurementOfferTerms_local_whole_grain", true, false) as Label
	var local_title := ui.find_child("FeedProcurementOfferTitle_local_whole_grain", true, false) as Label
	var local_description := ui.find_child("FeedProcurementOfferDescription_local_whole_grain", true, false) as Label
	var local_ration := ui.find_child("FeedProcurementOfferRation_local_whole_grain", true, false) as Label
	var local_reason := ui.find_child("FeedProcurementOfferReason_local_whole_grain", true, false) as Label
	var local_button := ui.find_child("FeedProcurementOrder_local_whole_grain", true, false) as Button
	var offers_toggle := ui.find_child("FeedProcurementOffersToggle", true, false) as Button
	var offer_list := ui.find_child("FeedProcurementOfferList", true, false) as VBoxContainer
	_check(local_title != null and local_title.text == "LOCAL", "the routine supplier should use a stable one-word identity", failures)
	_check(local_description != null and not local_description.visible and local_description.text.contains("nearby mill"), "supplier flavor should remain authored without competing with the purchase", failures)
	_check(local_terms != null and _contains_all(local_terms.text, ["6 scoops", "$9.00", "lasts 3", "d10"]), "each visible card should compare quantity, prepaid cost, shelf life, and expiry compactly", failures)
	_check(local_terms != null and _contains_all(local_terms.tooltip_text, ["$1.50 each", "prepaid $9.00", "shelf life 3 shifts", "expires day 10"]), "each card tooltip should retain the exact filed terms", failures)
	_check(local_ration != null and _contains_all(local_ration.text, ["strain -10%", "morale +2", "griev -1"]), "each card should retain the exact ration tradeoff in token form", failures)
	_check(local_reason != null and local_reason.text == "READY", "an available order should have one unmistakable state", failures)
	_check(local_reason != null and _contains_all(local_reason.tooltip_text, ["farmer review open", "0 of 1 daily orders used"]), "the ready state should retain its exact authorization context on demand", failures)
	_check(local_button != null and _contains_all(local_button.text, ["buy 6", "$9.00"]), "the action should say what is bought and spent without restating the full filing", failures)
	_check(local_button != null and not local_button.disabled and local_button.focus_mode == Control.FOCUS_ALL, "an authorized review order should be keyboard actionable", failures)
	_check(
		offers_toggle != null
		and offer_list != null
		and ui.offers_expanded()
		and offer_list.visible,
		"an actionable deep-linked supplier file should automatically reveal its existing actions",
		failures,
	)
	_check(
		offers_toggle != null
		and offers_toggle.text == "HIDE FEED  /  1 READY"
		and _contains_all(offers_toggle.tooltip_text, ["1 of 3 supplier files", "price", "quantity", "shelf life", "ration effects", "held reasons"]),
		"the feed disclosure should fit while its assistive detail retains the full file count and scope",
		failures,
	)
	var original_local_button := local_button
	ui.set_offers_expanded(false)
	await process_frame
	ui.apply_snapshot(_root_snapshot(true))
	await process_frame
	_check(
		not ui.offers_expanded()
		and offer_list != null
		and not offer_list.visible
		and ui.find_child("FeedProcurementOrder_local_whole_grain", true, false) == original_local_button,
		"a deliberate collapse should survive a same-state refresh without rebuilding its action",
		failures,
	)
	ui.set_offers_expanded(true)
	await process_frame
	if local_button != null:
		local_button.pressed.emit()
	_check(requests == [&"local_whole_grain"], "an order action should emit its stable offer ID exactly once", failures)

	var bulk_description := ui.find_child("FeedProcurementOfferDescription_inspirational_bulk_mash", true, false) as Label
	var bulk_reason := ui.find_child("FeedProcurementOfferReason_inspirational_bulk_mash", true, false) as Label
	var bulk_button := ui.find_child("FeedProcurementOrder_inspirational_bulk_mash", true, false) as Button
	var future_reason := ui.find_child("FeedProcurementOfferReason_fixed_future_reserve", true, false) as Label
	var future_button := ui.find_child("FeedProcurementOrder_fixed_future_reserve", true, false) as Button
	_check(bulk_description != null and not bulk_description.visible and bulk_description.text.contains("motivational slogans"), "authored supplier flavor should remain available without adding a visible sentence", failures)
	_check(bulk_reason != null and bulk_reason.text == "HELD  /  LEVEL 2", "level-gated offers should expose a concise actionable reason", failures)
	_check(bulk_reason != null and bulk_reason.tooltip_text.contains("level 2 is required"), "the complete level gate should remain available on demand", failures)
	_check(bulk_button != null and bulk_button.disabled, "an unavailable supplier must not emit an order", failures)
	_check(future_reason != null and _contains_all(future_reason.text, ["held", "short $4.00"]), "fund-held offers should state the exact shortfall compactly", failures)
	_check(future_reason != null and future_reason.tooltip_text.contains("short by $4.00"), "the full affordability reason should remain available on demand", failures)
	_check(future_button != null and future_button.disabled, "an unaffordable prepaid order must remain disabled", failures)
	if bulk_button != null:
		bulk_button.pressed.emit()
	if future_button != null:
		future_button.pressed.emit()
	_check(requests == [&"local_whole_grain"], "direct disabled-button signals must not bypass the component guard", failures)

	var activity := ui.find_child("FeedProcurementLastActivity", true, false) as Label
	_check(activity != null and _contains_all(activity.text, ["last", "+6 feed", "-$9.00", "spot -$3.60", "spoil -1"]), "the visible history should be one compact consequence line", failures)
	_check(activity != null and _contains_all(activity.tooltip_text, ["last delivery", "day 7", "local whole grain", "6 scoops", "$9.00 prepaid", "stock 2 -> 8"]), "the history tooltip should retain the exact supplier receipt", failures)
	_check(activity != null and _contains_all(activity.tooltip_text, ["last consumption", "day 6", "demand 5", "stored 3 + spot 2 scoops", "spot $3.60"]), "the history tooltip should retain exact automatic spot use", failures)
	_check(activity != null and _contains_all(activity.tooltip_text, ["last spoilage", "day 6", "1 scoops", "$1.20 lost", "lifetime 2 scoops ($2.70)"]), "the history tooltip should retain exact spoilage and lifetime waste", failures)

	var baseline_snapshot := _root_snapshot(true)
	var baseline_procurement := baseline_snapshot.get("feed_procurement", {}) as Dictionary
	baseline_procurement["active_ration"] = {
		"strain_basis_points": 10_000,
		"morale_delta": 0,
		"grievance_delta": 0,
	}
	ui.apply_snapshot(baseline_snapshot)
	await process_frame
	_check(active_ration != null and not active_ration.visible, "a baseline ration should add no zero-value reading chore", failures)
	ui.apply_snapshot(_root_snapshot(true))
	await process_frame

	if "--capture-feed-procurement" in OS.get_cmdline_user_args():
		var capture_directory := ProjectSettings.globalize_path("res://output/feed-procurement-glance-v1")
		DirAccess.make_dir_recursive_absolute(capture_directory)
		var capture_image := test_viewport.get_texture().get_image()
		_check(capture_image != null, "the feed-board capture should expose the rendered filing", failures)
		if capture_image != null:
			_check(capture_image.save_png(capture_directory.path_join("feed-procurement-282x760.png")) == OK, "the feed-board capture should save", failures)

	var ui_rect := ui.get_global_rect()
	_check(ui.get_combined_minimum_size().x <= scroll.size.x + 0.5, "the compact file should not demand horizontal scrolling at the real 282px Flockwatch width", failures)
	_check(_visible_children_fit_horizontally(ui, ui_rect), "visible procurement controls should remain inside the compact ledger width", failures)
	_check(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "the host should require no horizontal feed-order scrolling", failures)

	var prior_theme := ui.theme
	var control_records := _capture_control_records(ui)
	ui.theme = ManagementUIThemeScript.create_theme(false, 1.5)
	_apply_explicit_font_scale(ui, 1.5)
	_expand_interface_copy(ui)
	await process_frame
	await process_frame
	ui_rect = ui.get_global_rect()
	_check(
		ui.get_combined_minimum_size().x <= scroll.size.x + 0.5,
		"150-percent expanded feed procurement should remain inside the 282px filing (minimum=%s viewport=%s)"
		% [ui.get_combined_minimum_size(), scroll.size],
		failures,
	)
	_check(
		_visible_children_fit_horizontally(ui, ui_rect),
		"every max-scale feed offer should remain inside the vertical-only filing",
		failures,
	)
	local_button = ui.find_child(
		"FeedProcurementOrder_local_whole_grain",
		true,
		false,
	) as Button
	if local_button != null:
		scroll.ensure_control_visible(local_button)
	await process_frame
	await process_frame
	_check(
		local_button != null
		and local_button.is_visible_in_tree()
		and scroll.get_global_rect().intersects(local_button.get_global_rect()),
		"the max-scale routine order should remain vertically reachable",
		failures,
	)
	_restore_control_records(control_records)
	ui.theme = prior_theme
	await process_frame
	await process_frame

	var closed := _root_snapshot(false)
	ui.apply_snapshot(closed)
	await process_frame
	local_button = ui.find_child("FeedProcurementOrder_local_whole_grain", true, false) as Button
	local_reason = ui.find_child("FeedProcurementOfferReason_local_whole_grain", true, false) as Label
	_check(local_button != null and local_button.disabled and _contains_all(local_button.text, ["review", "$9.00"]), "active-shift orders should point to Farmer Review without opening another surface", failures)
	_check(local_reason != null and _contains_all(local_reason.text, ["held", "review"]), "review-only gating should remain immediately visible", failures)
	_check(local_reason != null and local_reason.tooltip_text.contains("only during Farmer Review"), "the complete active-shift gate should remain available on demand", failures)
	if local_button != null:
		local_button.pressed.emit()
	_check(requests == [&"local_whole_grain"], "closed-review orders must remain guarded even under direct signal emission", failures)

	ui.apply_snapshot({})
	await process_frame
	_check(not ui.visible, "legacy snapshots without feed_procurement should leave no empty ledger furniture", failures)

	await _test_staffing_integration(failures)

	test_viewport.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FEED_PROCUREMENT_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FEED_PROCUREMENT_UI_TEST_PASSED inline=flockwatch offers=3 economics=exact fallback=automatic review=guarded activity=auditable responsive=282px signal=stable")
	quit(0)


func _test_staffing_integration(failures: Array[String]) -> void:
	var harness := Control.new()
	harness.name = "FeedProcurementStaffingHarness"
	harness.size = Vector2(282.0, 760.0)
	root.add_child(harness)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	harness.add_child(scroll)
	var staffing := RoostStaffingUIScript.new() as RoostStaffingUI
	staffing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(staffing)
	await process_frame

	var forwarded: Array[StringName] = []
	staffing.feed_order_requested.connect(func(order_id: StringName) -> void: forwarded.append(order_id))
	var snapshot := _root_snapshot(true)
	snapshot.merge({
		"workers": [],
		"staffing_catalog": [],
		"active_staff_count": 0,
		"office_capacity": 4,
		"maximum_staff_capacity": 6,
		"staffing_planning_open": true,
		"daily_payroll_cents": 0,
		"daily_facility_cost_cents": 400,
		"daily_operating_cost_cents": 1400,
		"spendable_fund_cents": 20_000,
		"wage_arrears_cents": 300,
		"farm_treasury": {
			"credit_principal_cents": 1400,
			"vendor_arrears_cents": 200,
			"interest_arrears_cents": 100,
			"total_liabilities_cents": 1700,
			"credit_limit_cents": 5000,
			"credit_headroom_cents": 3600,
			"interest_basis_points": 500,
			"interest_percent": 5.0,
			"credit_rating": 0,
			"rating_label": "FIELD FILE",
			"capital_frozen": false,
		},
		"capacity_upgrade": {"maxed": true, "reason": "Capacity fixture is closed."},
		"facility_catalog": [],
		"operations": {"supervision": {}, "automation": {}},
	}, true)
	staffing.apply_snapshot(snapshot)
	await process_frame
	await process_frame

	var domains := staffing.navigation_sections()
	var flock_domain := domains.get(&"flock") as VBoxContainer
	var operations_domain := domains.get(&"operations") as VBoxContainer
	var capital_domain := domains.get(&"capital") as VBoxContainer
	var embedded := staffing.find_child("FeedProcurementUI", true, false) as FeedProcurementUI
	var farmgate := staffing.find_child("FarmgateDispatchUI", true, false) as FarmgateDispatchUI
	var operations := staffing.find_child("RoosterOperationsSection", true, false) as PanelContainer
	var treasury_label := staffing.find_child("FarmTreasurySummary", true, false) as Label
	var reserve_label := _direct_label_containing(flock_domain, "SPENDABLE FEED FUND")
	var arrears_label := _direct_label_containing(capital_domain, "WAGE ARREARS")
	var local_button := staffing.find_child("FeedProcurementOrder_local_whole_grain", true, false) as Button
	_check(embedded != null and embedded.visible, "Flock Provisions should be embedded in the existing staffing ledger", failures)
	_check(
		embedded != null
		and operations_domain != null
		and operations_domain.get_parent() == staffing
		and embedded.get_parent() == operations_domain,
		"the inventory file should be a direct Operations filing rather than a modal or sibling overlay",
		failures,
	)
	_check(
		farmgate != null
		and embedded != null
		and operations != null
		and farmgate.get_parent() == operations_domain
		and operations.get_parent() == operations_domain
		and farmgate.get_index() < embedded.get_index()
		and embedded.get_index() < operations.get_index(),
		"Operations should retain Farmgate, Flock Provisions, then Rooster Operations ordering",
		failures,
	)
	_check(
		reserve_label != null
		and reserve_label.get_parent() == flock_domain
		and _contains_all(reserve_label.text, ["reserved", "$14.00/day", "spendable feed fund", "$200.00"]),
		"the Flock filing should retain exact operating reserve and spendable-fund context",
		failures,
	)
	_check(
		arrears_label != null
		and arrears_label.get_parent() == capital_domain
		and _contains_all(arrears_label.text, ["wage arrears", "$3.00", "credit $14.00", "vendors $2.00", "interest $1.00"]),
		"the Capital filing should retain exact arrears and liability consequences",
		failures,
	)
	_check(
		treasury_label != null
		and treasury_label.get_parent() == capital_domain
		and "LINE $14.00 / $50.00" in treasury_label.text
		and "HEADROOM $36.00" in treasury_label.text,
		"the Capital filing should expose exact Treasury line usage and headroom",
		failures,
	)
	if local_button != null:
		local_button.pressed.emit()
	_check(forwarded == [&"local_whole_grain"], "Roost Staffing should forward the stable feed order without translation", failures)

	harness.queue_free()
	await process_frame


func _root_snapshot(planning_open: bool) -> Dictionary:
	var procurement := {
		"facility_id": &"flock_provisions_room",
		"level": 1,
		"capacity_scoops": 20,
		"stock_scoops": 8,
		"demand_scoops": 5,
		"stock_after_demand_scoops": 3,
		"spot_shortage_scoops": 0,
		"coverage_shifts": 1.6,
		"season": {
			"id": &"harvest_shoulder",
			"label": "Harvest Shoulder",
			"start_day": 7,
			"end_day": 9,
			"days_remaining": 2,
			"price_basis_points": 9000,
		},
		"base_spot_unit_price_cents": 200,
		"spot_unit_price_cents": 180,
		"spot_obligation_cents": 0,
		"order_limit": 1,
		"orders_used_today": 0,
		"planning_open": planning_open,
		"active_ration": {
			"strain_basis_points": 9000,
			"morale_delta": 2,
			"grievance_delta": -1,
		},
		"offers": [
			_offer(
				&"local_whole_grain",
				"Local Whole Grain",
				"A nearby mill delivers a steady whole-grain ration.",
				6,
				150,
				900,
				3,
				10,
				9000,
				2,
				-1,
				true,
				planning_open,
				"" if planning_open else "Feed orders open only during Farmer Review.",
			),
			_offer(
				&"inspirational_bulk_mash",
				"Inspirational Bulk Mash",
				"Discount mash arrives with motivational slogans on every sack.",
				10,
				125,
				1250,
				1,
				8,
				11000,
				-1,
				2,
				false,
				false,
				"Flock Provisions room level 2 is required.",
			),
			_offer(
				&"fixed_future_reserve",
				"Fixed Future Reserve",
				"A prepaid silo allotment fixes the current seasonal quote.",
				12,
				190,
				2280,
				5,
				12,
				9500,
				1,
				0,
				true,
				false,
				"Spendable Feed Fund is short by $4.00.",
			),
		],
		"last_order": {
			"accepted": true,
			"offer_id": &"local_whole_grain",
			"offer_label": "Local Whole Grain",
			"day": 7,
			"lot_id": 3,
			"quantity_scoops": 6,
			"total_cost_cents": 900,
			"stock_before_scoops": 2,
			"stock_after_scoops": 8,
		},
		"last_consumption": {
			"day": 6,
			"demand_scoops": 5,
			"inventory_scoops": 3,
			"spot_scoops": 2,
			"spot_cost_cents": 360,
		},
		"spoiled_total_scoops": 2,
		"spoiled_total_value_cents": 270,
		"last_spoilage": {"day": 6, "scoops": 1, "value_cents": 120},
	}
	return {"feed_procurement": procurement}


func _offer(
	offer_id: StringName,
	label: String,
	description: String,
	quantity: int,
	unit_price: int,
	total_cost: int,
	shelf_shifts: int,
	expires_day: int,
	strain_basis_points: int,
	morale_delta: int,
	grievance_delta: int,
	available: bool,
	can_authorize: bool,
	reason: String,
) -> Dictionary:
	return {
		"offer_id": offer_id,
		"label": label,
		"description": description,
		"required_level": 1,
		"quantity_scoops": quantity,
		"unit_price_cents": unit_price,
		"total_cost_cents": total_cost,
		"shelf_shifts": shelf_shifts,
		"expires_day": expires_day,
		"strain_basis_points": strain_basis_points,
		"morale_delta": morale_delta,
		"grievance_delta": grievance_delta,
		"available": available,
		"can_authorize": can_authorize,
		"reason": reason,
		"projected_stock_scoops": 14,
		"capacity_scoops": 20,
	}


func _direct_label_containing(parent: Node, fragment: String) -> Label:
	if parent == null:
		return null
	for child: Node in parent.get_children():
		if child is Label and String((child as Label).text).contains(fragment):
			return child as Label
	return null


func _visible_children_fit_horizontally(root_control: Control, root_rect: Rect2) -> bool:
	for node: Node in root_control.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		if rect.position.x < root_rect.position.x - 0.5 or rect.end.x > root_rect.end.x + 0.5:
			return false
	return true


func _contains_all(copy: String, fragments: Array[String]) -> bool:
	var normalized := copy.to_lower()
	for fragment in fragments:
		if not normalized.contains(fragment.to_lower()):
			return false
	return true


func _capture_control_records(root_node: Node) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
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
