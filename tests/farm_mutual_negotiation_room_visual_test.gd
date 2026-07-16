extends SceneTree

const NegotiationRoomVisualScript := preload("res://features/office/farm_mutual_negotiation_room_visual.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var visual: Variant = NegotiationRoomVisualScript.new()
	root.add_child(visual)
	await process_frame

	_check(NegotiationRoomVisualScript.declared_footprint() == Rect2(Vector2(12.0, 9.1), Vector2(6.4, 5.8)), "room should publish the canonical 6.4 m by 5.8 m north parcel", failures)
	_check(is_equal_approx(NegotiationRoomVisualScript.maximum_visual_height(), 4.05), "room should publish its 4.05 m opaque-height budget", failures)
	_check(visual.focus_point_global().is_equal_approx(Vector3(15.2, 1.18, 12.0)), "room should expose a stable pavilion camera target", failures)
	_check(visual.visual_state() == &"locked", "fresh room should begin as a locked survey", failures)
	_check(visual.locked_marker_visible() and not visual.construction_prospect_visible() and not visual.owned_room_visible(), "locked state should expose only the restrained parcel marker", failures)
	_check(visual.geometry_bounds_inside_footprint(), "every hidden and visible state should remain in the declared parcel and height budget", failures)
	_check(visual.chicken_perch_chair_count() == 6, "owned room should author exactly six chicken perch chairs", failures)
	_check(visual.farmer_credit_chair_present(), "owned room should author the oversized farmer-credit chair", failures)
	_check(visual.visible_clause_folio_count() == 0 and not visual.active_rider_visible(), "empty snapshots must not invent contract folders", failures)
	_check(not visual.premium_marker_visible() and not visual.breach_marker_visible(), "empty snapshots must not invent settlement money", failures)
	_check(visual.find_children("*", "CollisionObject3D", true, false).is_empty(), "negotiation room must remain non-colliding", failures)
	_check(visual.find_children("*", "NavigationRegion3D", true, false).is_empty(), "negotiation room must not add navigation regions", failures)
	_check(visual.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "negotiation room must not add navigation obstacles", failures)

	for required_part in [
		"NegotiationRoomConnectedPad",
		"WalnutOvalNegotiationTable",
		"NegotiationTableFeltCenter",
		"FarmerCreditChair",
		"NegotiationSigningPressStation",
		"NegotiationSettlementTrays",
		"AuthoritativeSeasonMedallion",
		"NegotiationDeliveryAndSeatPips",
		"NegotiationWarmPendant",
		"NegotiationRoomReededGlass",
		"NegotiationRoomNorthCutawayDado",
		"NegotiationRoomNorthCutawayHeader",
		"NegotiationRoomNorthReededGlassWest",
		"NegotiationRoomNorthReededGlassEast",
	]:
		_check(visual.find_child(required_part, true, false) != null, "owned pavilion should include %s" % required_part, failures)
	_check(visual.find_child("NegotiationRoomNorthWall", true, false) == null, "management-facing north elevation must not restore the full-height opaque wall", failures)
	_check(bool(visual.owned_room_root.get_meta(&"management_camera_cutaway", false)), "owned pavilion should publish its management-camera cutaway contract", failures)
	var north_dado := visual.find_child("NegotiationRoomNorthCutawayDado", true, false) as MeshInstance3D
	var north_dado_mesh := north_dado.mesh as BoxMesh if north_dado != null else null
	_check(north_dado_mesh != null and north_dado_mesh.size.y <= 0.47, "camera-facing dado should remain low enough to reveal chairs and tabletop", failures)
	var cutaway_header := visual.find_child("NegotiationRoomNorthCutawayHeader", true, false) as MeshInstance3D
	_check(cutaway_header != null and bool(cutaway_header.get_meta(&"camera_facing_cutaway", false)), "north header should explicitly mark the wide central architectural opening", failures)
	_check(visual.find_children("ChickenPerchChair_*", "Node3D", true, false).size() == 6, "chair roots should remain individually addressable", failures)
	var farmer_chair := visual.find_child("FarmerCreditChair", true, false) as Node3D
	_check(farmer_chair != null and bool(farmer_chair.get_meta(&"intentionally_empty", false)), "farmer-credit chair should explicitly remain empty", failures)
	var identity := visual.find_child("FarmMutualNegotiationIdentity", true, false) as Label3D
	_check(identity != null and bool(identity.get_meta(&"host_embossed_copy", false)), "room identity should use modeled architectural lettering", failures)
	var identity_fixture := visual.find_child("FarmMutualNegotiationIdentityFixture", true, false) as Node3D
	_check(identity_fixture != null and identity_fixture.position.z > 0.0 and absf(identity_fixture.rotation_degrees.y) < 0.01, "lifted room identity should face the positive-Z management-camera approach", failures)
	var rider_copy := visual.find_child("NegotiationActiveRiderCopy", true, false) as Label3D
	_check(rider_copy != null and rider_copy.get_parent() != null and bool(rider_copy.get_parent().get_meta(&"host_attached", false)), "active rider detail should stay physically attached to its paper host", failures)

	visual.apply_snapshot({
		"facility_catalog": [{"id": "farm_mutual_negotiation_room", "unlocked": true, "level": 0}],
		"contract_board": {},
	})
	_check(visual.visual_state() == &"construction_prospect", "unlocked unpurchased room should reveal its construction prospect", failures)
	_check(not visual.locked_marker_visible() and visual.construction_prospect_visible() and not visual.owned_room_visible(), "construction prospect should replace locked and owned states", failures)

	visual.apply_snapshot({
		"owned_facilities": {&"farm_mutual_negotiation_room": 1},
		"facility_catalog": [{"id": &"farm_mutual_negotiation_room", "unlocked": true, "level": 1}],
		"contract_board": {},
	})
	_check(visual.visual_state() == &"owned" and visual.owned_room_visible(), "one-tier purchase should reveal the complete pavilion", failures)
	_check(visual.visible_clause_folio_count() == 0 and not visual.active_rider_visible(), "owned but empty room should keep the felt clear of invented files", failures)
	_check(visual.lit_delivery_pip_count() == 0 and visual.lit_seat_pip_count() == 0, "owned but empty room should leave progress pips dark", failures)
	_check(not visual.premium_marker_visible() and not visual.breach_marker_visible(), "owned but empty room should leave settlement trays empty", failures)

	var active_clause := {
		"clause_id": &"staffed_roost_rider",
		"clause_label": "Staffed Roost Rider",
		"clause_category": &"staffing",
		"timely_sound_completed": 4,
		"required_completed": 6,
		"active_staff": 3,
		"required_active_staff": 5,
	}
	visual.apply_snapshot({
		"owned_facilities": {&"farm_mutual_negotiation_room": 1},
		"contract_board": {
			"season": {"label": "Harvest 07"},
			"active": active_clause,
			"last_result": {},
		},
	})
	_check(visual.season_key() == "HARVEST 07", "season medallion should retain authoritative season copy", failures)
	_check(visual.active_clause_id() == &"staffed_roost_rider", "active rider should retain the authoritative clause id", failures)
	_check(visual.active_clause_category() == &"staffing", "active rider should retain the authoritative category", failures)
	_check(visual.visible_clause_folio_count() == 4, "authoritative season should reveal four clause folios", failures)
	_check(visual.active_rider_visible(), "authoritative clause should reveal its signing clip", failures)
	_check(visual.lit_delivery_pip_count() == 4 and visual.lit_seat_pip_count() == 3, "table pips should mirror authoritative delivery and seat counts", failures)
	_check(not visual.premium_marker_visible() and not visual.breach_marker_visible(), "active clause without result should keep both trays empty", failures)
	var rider_label := visual.find_child("NegotiationActiveRiderCopy", true, false) as Label3D
	_check(rider_label != null and "STAFFED ROOST RIDER" in rider_label.text and "STAFFING" in rider_label.text, "hosted rider copy should reflect label and category", failures)

	visual.apply_snapshot({
		"owned_facilities": {&"farm_mutual_negotiation_room": 1},
		"contract_board": {
			"season": 7,
			"active": active_clause,
			"last_result": {"status": "fulfilled", "premium_cents": 12400},
		},
	})
	_check(visual.premium_marker_visible() and not visual.breach_marker_visible(), "fulfilled contract should place only its authoritative premium receipt", failures)
	var premium_copy := visual.find_child("PremiumSettlementCopy", true, false) as Label3D
	_check(premium_copy != null and "$124.00" in premium_copy.text, "premium receipt should carry the exact snapshot value", failures)

	visual.apply_snapshot({
		"owned_facilities": {&"farm_mutual_negotiation_room": 1},
		"contract_board": {
			"season": 8,
			"active": {},
			"last_result": {"status": "breached", "breach_cents": 6700},
		},
	})
	_check(not visual.active_rider_visible(), "cleared active clause should remove its rider clip", failures)
	_check(not visual.premium_marker_visible() and visual.breach_marker_visible(), "breached contract should place only its authoritative debit receipt", failures)
	var breach_copy := visual.find_child("BreachSettlementCopy", true, false) as Label3D
	_check(breach_copy != null and "$67.00" in breach_copy.text, "breach receipt should carry the exact snapshot value", failures)
	_check(visual.geometry_bounds_inside_footprint(), "dynamic result states should remain inside the parcel", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("FARM_MUTUAL_NEGOTIATION_ROOM_VISUAL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARM_MUTUAL_NEGOTIATION_ROOM_VISUAL_TEST_PASSED states=locked-prospect-owned chairs=6 folios=4 rider=snapshot-driven settlements=authoritative bounds=audited collisions=0 navigation=0")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
