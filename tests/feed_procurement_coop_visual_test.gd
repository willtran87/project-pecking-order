extends SceneTree

const FeedProcurementCoopVisualScript := preload("res://features/office/feed_procurement_coop_visual.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var visual := FeedProcurementCoopVisualScript.new() as FeedProcurementCoopVisual
	root.add_child(visual)
	await process_frame

	_check(FeedProcurementCoopVisualScript.declared_footprint() == Rect2(Vector2(4.10, 27.10), Vector2(6.40, 5.80)), "Feed Procurement should retain its exact southwest operations parcel", failures)
	_check(FeedProcurementCoopVisualScript.entrance_bridge_footprint() == Rect2(Vector2(10.50, 29.40), Vector2(0.25, 1.20)), "Feed Procurement should publish its exact spine bridge", failures)
	_check(FeedProcurementCoopVisualScript.clear_aisle_footprint() == Rect2(Vector2(8.20, 29.45), Vector2(2.55, 1.10)), "Feed Procurement should publish its exact clear east-entry aisle", failures)
	_check(FeedProcurementCoopVisualScript.facility_focus_point().is_equal_approx(Vector3(7.30, 1.50, 30.00)), "Feed Procurement should publish its stable facility focus", failures)
	_check(is_equal_approx(FeedProcurementCoopVisualScript.EAST_DOOR_WIDTH, 1.20), "Feed Procurement should retain its exact 1.20m east door", failures)
	_check(visual.focus_point_global().is_equal_approx(Vector3(7.30, 1.50, 30.00)), "global focus should account for the positioned visual exactly once", failures)
	_check(visual.visual_state() == &"locked", "fresh Feed Procurement should show only its locked parcel", failures)
	_check(visual.visible_stock_sack_count() == 0 and visual.visible_offer_binder_count() == 0, "locked facility must not invent stock or offers", failures)
	_check(visual.geometry_bounds_inside_footprint(), "locked and authored facility geometry should remain parcel-bound", failures)
	_check(visual.connector_geometry_inside_bridge(), "connector geometry should remain in the exact bridge parcel", failures)
	_check(visual.circulation_clear(), "the exact east-entry aisle should remain free of blocking geometry", failures)
	_check(visual.find_children("*", "CollisionObject3D", true, false).is_empty(), "Feed Procurement should remain collision-free", failures)
	_check(visual.find_children("*", "NavigationRegion3D", true, false).is_empty(), "Feed Procurement should not create navigation regions", failures)
	_check(visual.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "Feed Procurement should not create navigation obstacles", failures)

	visual.apply_snapshot({
		"facility_catalog": [{"id": &"feed_procurement_coop", "unlocked": true, "level": 0}],
		"feed_procurement": _procurement_snapshot(0),
	})
	_check(visual.visual_state() == &"survey", "unlocked but unpurchased Feed Procurement should reveal the surveyed parcel", failures)
	_check(visual.visible_stock_sack_count() == 0 and visual.visible_offer_binder_count() == 0, "survey state must remain free of economic props", failures)

	for level in 3:
		var purchased_level := level + 1
		var procurement := _procurement_snapshot(purchased_level)
		visual.apply_snapshot({"owned_facilities": {&"feed_procurement_coop": purchased_level}, "feed_procurement": procurement})
		_check(visual.visual_state() == StringName("level_%d" % purchased_level), "Feed Procurement tier %d should publish its own state" % purchased_level, failures)
		for retained_level in range(1, purchased_level + 1):
			_check(visual.level_visible(retained_level), "Feed Procurement tier %d should retain tier %d" % [purchased_level, retained_level], failures)
		_check(visual.visible_stock_sack_count() == 2, "tier %d should materialize exactly the two active canonical lots" % purchased_level, failures)
		_check(visual.visible_offer_binder_count() == (2 if purchased_level >= 2 else 0), "tier %d should reveal offer binders only in the reserve tier" % purchased_level, failures)
		_check(visual.geometry_bounds_inside_footprint(), "Feed Procurement tier %d should remain parcel-bound" % purchased_level, failures)
		_check(visual.connector_geometry_inside_bridge(), "Feed Procurement tier %d should retain its exact connector" % purchased_level, failures)
		_check(visual.circulation_clear(), "Feed Procurement tier %d should retain the clear aisle" % purchased_level, failures)

	_check(visual.find_child("ReceivingHopper", true, false) != null, "tier one should include the Receiving Hopper", failures)
	_check(visual.find_child("ReceivingDesk", true, false) != null and visual.find_child("ReceivingScaleDeck", true, false) != null, "tier one should include its desk and receiving scale", failures)
	_check(visual.find_child("DryReserveHopper", true, false) != null and visual.find_child("DryReserveAugerTube", true, false) != null, "tier two should include twin hoppers joined by the overhead auger", failures)
	_check(visual.find_child("SupplierBinderCabinet", true, false) != null, "tier two should include its supplier binder cabinet", failures)
	_check(visual.find_child("StrategicReserveSilo", true, false) != null and visual.find_child("GrainClimateCabinet", true, false) != null, "tier three should include the signature reserve silo and climate cabinet", failures)
	_check(visual.find_child("FeedFuturesDesk", true, false) != null, "tier three should include the Feed Futures Desk", failures)
	_check(visual.has_authoritative_procurement(), "canonical feed_procurement data should be recognized as authoritative", failures)
	_check(visual.lot_ids() == [101, 102], "physical sacks should preserve canonical lot IDs and omit depleted lots", failures)
	_check(is_equal_approx(visual.stock_fill_ratio(), 0.75), "hopper and silo fill should mirror the canonical stock ratio", failures)
	_check(visual.lit_reserve_segment_count() == 8, "reserve gauge should round 75 percent to eight lit segments", failures)
	_check("AUTUMN" in visual.quote_text() and "$2.20" in visual.quote_text(), "futures screen should mirror canonical season and spot quote", failures)
	_check("EXP D09" in visual.expiry_text() and "SPOILED 02" in visual.expiry_text(), "expiry rail should mirror nearest lot expiry and spoilage", failures)
	_check(visual.spoilage_indicator_active(), "canonical spoilage should illuminate the spoilage indicator", failures)
	_check(visual.find_child("AuthoritativeLastFeedOrder", true, false).visible, "tier three should materialize the canonical last order receipt", failures)

	visual.apply_snapshot({"feed_procurement": _procurement_snapshot(3, true)})
	_check(visual.visible_stock_sack_count() == 0 and visual.visible_offer_binder_count() == 0, "empty canonical procurement should remove every prior sack and offer binder", failures)
	_check(is_zero_approx(visual.stock_fill_ratio()) and visual.lit_reserve_segment_count() == 0, "empty canonical stock should clear hopper fill and reserve gauge", failures)
	_check(not visual.spoilage_indicator_active(), "empty canonical spoilage should clear the warning", failures)
	_check(not visual.find_child("AuthoritativeLastFeedOrder", true, false).visible, "empty canonical last order should remove the receipt", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("FEED_PROCUREMENT_COOP_VISUAL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FEED_PROCUREMENT_COOP_VISUAL_TEST_PASSED states=locked-survey-l1-l2-l3 stock=lots-only offers=canonical fill=authoritative bridge=exact aisle=clear bounds=inside collisions=0")
	quit(0)


func _procurement_snapshot(level: int, empty: bool = false) -> Dictionary:
	return {
		"facility_id": &"feed_procurement_coop",
		"level": level,
		"capacity_scoops": 40,
		"stock_scoops": 0 if empty else 30,
		"demand_scoops": 0 if empty else 4,
		"stock_after_demand_scoops": 0 if empty else 26,
		"spot_shortage_scoops": 0,
		"coverage_shifts": 0.0 if empty else 7.5,
		"season": {"id": &"autumn", "label": "Autumn", "start_day": 7, "end_day": 12, "days_remaining": 3, "price_basis_points": 11000},
		"charter": {"length_shifts": 3, "renewal_day": 10, "renewal_due": false},
		"base_spot_unit_price_cents": 200,
		"spot_unit_price_cents": 220,
		"spot_obligation_cents": 0,
		"order_limit": 1,
		"orders_used_today": 0 if empty else 1,
		"planning_open": true,
		"offers": [] if empty else [
			{"offer_id": &"barn_bulk", "label": "Barn Bulk"},
			{"offer_id": &"field_forward", "label": "Field Forward"},
		],
		"lots": [] if empty else [
			{"lot_id": 101, "offer_id": &"barn_bulk", "ordered_day": 7, "expires_day": 9, "scoops_initial": 12, "scoops_remaining": 7, "unit_cost_cents": 190, "total_cost_cents": 2280},
			{"lot_id": 102, "offer_id": &"field_forward", "ordered_day": 8, "expires_day": 11, "scoops_initial": 24, "scoops_remaining": 23, "unit_cost_cents": 205, "total_cost_cents": 4920},
			{"lot_id": 103, "offer_id": &"barn_bulk", "ordered_day": 5, "expires_day": 8, "scoops_initial": 4, "scoops_remaining": 0, "unit_cost_cents": 180, "total_cost_cents": 720},
		],
		"procurement_spend_today_cents": 0 if empty else 4920,
		"procurement_spend_total_cents": 0 if empty else 7200,
		"spot_spend_today_cents": 0,
		"spot_spend_total_cents": 0,
		"spoiled_today_scoops": 0 if empty else 2,
		"spoiled_total_scoops": 0 if empty else 3,
		"consumed_today_scoops": 0,
		"consumed_inventory_today_scoops": 0,
		"consumed_spot_today_scoops": 0,
		"consumed_value_today_cents": 0,
		"active_ration": {},
		"last_order": {} if empty else {"offer_id": &"field_forward", "label": "Field Forward", "scoops": 24, "total_cost_cents": 4920},
		"last_consumption": {},
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
