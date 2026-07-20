extends SceneTree

const FeedProcurementUIScript := preload("res://features/office/feed_procurement_ui.gd")
const RoostStaffingUIScript := preload("res://features/office/roost_staffing_ui.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var harness := Control.new()
	harness.name = "FeedProcurementUITestHarness"
	harness.size = Vector2(282.0, 760.0)
	root.add_child(harness)

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
	var fallback := ui.find_child("FeedProcurementSpotFallback", true, false) as Label
	var offers := ui.find_children("FeedProcurementOffer_*", "PanelContainer", true, false)
	_check(ui.visible, "a canonical feed_procurement snapshot should reveal the inline section", failures)
	_check(quote != null and _contains_all(quote.text, ["harvest shoulder", "$1.80", "days 7-9", "2 days left", "base $2.00"]), "season quote should disclose its exact window and current/base spot price", failures)
	_check(inventory != null and _contains_all(inventory.text, ["stock", "8 / 20 scoops", "next-shift demand 5", "after rations 3", "coverage 1.6 shifts", "spot shortage 0"]), "inventory should join stock, capacity, next demand, residual stock, coverage, and shortage", failures)
	_check(fallback != null and _contains_all(fallback.text, ["automatic spot fallback", "$1.80", "no order is required to continue"]), "the ledger should make its non-blocking automatic spot fallback explicit", failures)
	_check(offers.size() == 3, "the fixed supplier file should show exactly one card for each canonical offer", failures)

	var local_terms := ui.find_child("FeedProcurementOfferTerms_local_whole_grain", true, false) as Label
	var local_ration := ui.find_child("FeedProcurementOfferRation_local_whole_grain", true, false) as Label
	var local_reason := ui.find_child("FeedProcurementOfferReason_local_whole_grain", true, false) as Label
	var local_button := ui.find_child("FeedProcurementOrder_local_whole_grain", true, false) as Button
	var offers_toggle := ui.find_child("FeedProcurementOffersToggle", true, false) as Button
	var offer_list := ui.find_child("FeedProcurementOfferList", true, false) as VBoxContainer
	_check(local_terms != null and _contains_all(local_terms.text, ["quantity 6 scoops", "$1.50 each", "prepaid $9.00", "shelf life 3 shifts", "expires day 10"]), "each order should disclose quantity, exact unit/prepaid cost, shelf life, and expiry", failures)
	_check(local_ration != null and _contains_all(local_ration.text, ["ration effect", "strain -10%", "morale +2", "grievance -1"]), "each order should disclose the exact ration tradeoff", failures)
	_check(local_reason != null and _contains_all(local_reason.text, ["ready", "farmer review open", "0 of 1"]), "an available order should explain why it is ready", failures)
	_check(local_button != null and not local_button.disabled and local_button.focus_mode == Control.FOCUS_ALL, "an authorized review order should be keyboard actionable", failures)
	_check(
		offers_toggle != null
		and offer_list != null
		and ui.offers_expanded()
		and offer_list.visible,
		"an actionable deep-linked supplier file should automatically reveal its existing actions",
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
	_check(bulk_description != null and bulk_description.text.contains("motivational slogans"), "authored supplier descriptions should remain visible without a tooltip", failures)
	_check(bulk_reason != null and _contains_all(bulk_reason.text, ["held", "level 2"]), "level-gated offers should keep the authoritative availability reason visible", failures)
	_check(bulk_button != null and bulk_button.disabled, "an unavailable supplier must not emit an order", failures)
	_check(future_reason != null and _contains_all(future_reason.text, ["held", "short by $4.00"]), "fund-held offers should state the exact shortfall", failures)
	_check(future_button != null and future_button.disabled, "an unaffordable prepaid order must remain disabled", failures)
	if bulk_button != null:
		bulk_button.pressed.emit()
	if future_button != null:
		future_button.pressed.emit()
	_check(requests == [&"local_whole_grain"], "direct disabled-button signals must not bypass the component guard", failures)

	var activity := ui.find_child("FeedProcurementLastActivity", true, false) as Label
	_check(activity != null and _contains_all(activity.text, ["last delivery", "day 7", "local whole grain", "6 scoops", "$9.00 prepaid", "stock 2 -> 8"]), "last delivery should retain its exact supplier, quantity, payment, and stock receipt", failures)
	_check(activity != null and _contains_all(activity.text, ["last consumption", "day 6", "demand 5", "stored 3 + spot 2 scoops", "spot $3.60"]), "last consumption should distinguish inventory and automatic spot use", failures)
	_check(activity != null and _contains_all(activity.text, ["last spoilage", "day 6", "1 scoops", "$1.20 lost", "lifetime 2 scoops ($2.70)"]), "spoilage should disclose both the last loss and cumulative waste value", failures)

	var ui_rect := ui.get_global_rect()
	_check(ui.get_combined_minimum_size().x <= scroll.size.x + 0.5, "the compact file should not demand horizontal scrolling at the real 282px Flockwatch width", failures)
	_check(_visible_children_fit_horizontally(ui, ui_rect), "visible procurement controls should remain inside the compact ledger width", failures)
	_check(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "the host should require no horizontal feed-order scrolling", failures)

	var closed := _root_snapshot(false)
	ui.apply_snapshot(closed)
	await process_frame
	local_button = ui.find_child("FeedProcurementOrder_local_whole_grain", true, false) as Button
	local_reason = ui.find_child("FeedProcurementOfferReason_local_whole_grain", true, false) as Label
	_check(local_button != null and local_button.disabled and _contains_all(local_button.text, ["review to order", "$9.00"]), "active-shift orders should point to Farmer Review without opening another surface", failures)
	_check(local_reason != null and _contains_all(local_reason.text, ["held", "only during farmer review"]), "review-only gating should be visible beside the disabled action", failures)
	if local_button != null:
		local_button.pressed.emit()
	_check(requests == [&"local_whole_grain"], "closed-review orders must remain guarded even under direct signal emission", failures)

	ui.apply_snapshot({})
	await process_frame
	_check(not ui.visible, "legacy snapshots without feed_procurement should leave no empty ledger furniture", failures)

	await _test_staffing_integration(failures)

	harness.queue_free()
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


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
