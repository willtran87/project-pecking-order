extends SceneTree

const FarmerRelationsGalleryVisualScript := preload("res://features/office/farmer_relations_gallery_visual.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var visual := FarmerRelationsGalleryVisualScript.new() as FarmerRelationsGalleryVisual
	root.add_child(visual)
	await process_frame

	_check(FarmerRelationsGalleryVisualScript.declared_footprint() == Rect2(Vector2(4.10, 21.10), Vector2(6.40, 5.80)), "Gallery should retain the exact west care-campus parcel", failures)
	_check(FarmerRelationsGalleryVisualScript.entrance_bridge_footprint() == Rect2(Vector2(10.50, 23.40), Vector2(0.25, 1.20)), "Gallery should publish its exact care-spine bridge", failures)
	_check(FarmerRelationsGalleryVisualScript.clear_aisle_footprint() == Rect2(Vector2(8.20, 23.45), Vector2(2.55, 1.10)), "Gallery should publish its exact 1.10m clear aisle", failures)
	_check(FarmerRelationsGalleryVisualScript.facility_focus_point().is_equal_approx(Vector3(7.30, 1.50, 24.00)), "Gallery should publish its stable camera focus", failures)
	_check(visual.focus_point_global().is_equal_approx(Vector3(7.30, 1.50, 24.00)), "Gallery global focus should apply its center exactly once", failures)
	_check(visual.visual_state() == &"locked" and visual.locked_marker_visible(), "fresh Gallery should begin as a locked publicity parcel", failures)
	_check(not visual.evidence_profile_visible() and not visual.last_receipt_visible(), "locked Gallery must not invent a hen profile or receipt", failures)
	_assert_geometry_contract(visual, "locked", failures)

	visual.apply_snapshot({
		"facility_catalog": [{"id": &"farmer_relations_gallery", "unlocked": true, "level": 0}],
		"farmer_relations_gallery": _gallery_snapshot(0, true),
	})
	_check(visual.visual_state() == &"survey" and visual.survey_site_visible(), "unlocked level zero should reveal only the surveyed pavilion", failures)
	_check(not visual.evidence_profile_visible() and not visual.last_receipt_visible(), "survey state must remain free of authored economic records", failures)
	_assert_geometry_contract(visual, "survey", failures)

	for purchased_level in range(1, 4):
		var snapshot := _gallery_snapshot(purchased_level, false)
		visual.apply_snapshot({
			"owned_facilities": {&"farmer_relations_gallery": purchased_level},
			"farmer_relations_gallery": snapshot,
		})
		_check(visual.visual_state() == StringName("level_%d" % purchased_level), "Gallery tier %d should publish its own state" % purchased_level, failures)
		for retained_level in range(1, purchased_level + 1):
			_check(visual.level_visible(retained_level), "Gallery tier %d should retain tier %d" % [purchased_level, retained_level], failures)
		_check(visual.evidence_profile_visible(), "Gallery tier %d should show only the canonical named layer profile" % purchased_level, failures)
		_check(visual.last_receipt_visible() == (purchased_level >= 3), "last hung receipt should appear only on the level-three attribution wall", failures)
		_assert_geometry_contract(visual, "level %d" % purchased_level, failures)

	_check(visual.find_child("UpgradedBasketPlinth", true, false) != null and visual.find_child("AuthoritativeEmptyPressBasket", true, false) != null, "level one should add its upgraded but empty basket plinth", failures)
	_check(visual.find_child("AuthoritativeLayerProfile", true, false) != null, "level one should host the authoritative layer portrait and nameplate", failures)
	_check(visual.find_child("HarvestPressBackdrop", true, false) != null and visual.find_child("ClutchResultsBoard", true, false) != null, "level two should add the press backdrop and physical results board", failures)
	_check(visual.find_children("PressCameraSoftbox_*", "MeshInstance3D", true, false).size() == 2, "level two should add two overhead camera lights", failures)
	_check(visual.find_child("HarvestAttributionWall", true, false) != null and visual.find_child("PublicStandingAwardShelf", true, false) != null, "level three should add the attribution wall and award shelf", failures)
	_check(visual.find_child("FarmerPortraitFrame", true, false) != null, "level three should add the authored farmer portrait", failures)
	_check("COUNTY FAIR / 14 PT" in visual.standing_text(), "standing readout should mirror exact canonical rank and points", failures)
	_check("DAY 09" in visual.results_text() and "CLUTCH 31/28" in visual.results_text() and "S 27  C 02  G 02" in visual.results_text(), "results board should mirror only fields owned by the frozen shift evidence", failures)
	_check("CONTESTED CREDIT / MABEL" in visual.attribution_text(), "attribution wall should mirror the filed style and named credited subject", failures)
	_check("LAST HUNG / DAY 09" in visual.last_receipt_text() and "LAYER PROFILE" in visual.last_receipt_text(), "receipt should mirror the canonical hung campaign", failures)
	_check(visual.has_authoritative_gallery(), "canonical gallery projection should be recognized as authoritative", failures)
	_check(visual.find_children("DecorativeEgg*", "MeshInstance3D", true, false).is_empty() and visual.find_children("CartonEgg*", "MeshInstance3D", true, false).is_empty(), "Gallery fixtures must never invent decorative or unattended eggs", failures)

	visual.apply_snapshot({"farmer_relations_gallery": _gallery_snapshot(3, true)})
	_check(not visual.evidence_profile_visible(), "clearing canonical evidence should remove the named layer profile", failures)
	_check(not visual.last_receipt_visible(), "clearing the canonical last receipt should remove the hung paper", failures)
	_check("NO CLOSED SHIFT EVIDENCE" in visual.results_text(), "cleared evidence should leave an explicit empty board", failures)
	_check("NO CREDIT MEMO HUNG" in visual.attribution_text(), "cleared attribution should leave an explicit empty wall", failures)
	_assert_geometry_contract(visual, "cleared level three", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("FARMER_RELATIONS_GALLERY_VISUAL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARMER_RELATIONS_GALLERY_VISUAL_TEST_PASSED states=locked-survey-l1-l2-l3 evidence=canonical attribution=canonical receipt=canonical bridge=exact aisle=1.10m collisions=0")
	quit(0)


func _gallery_snapshot(level: int, empty: bool) -> Dictionary:
	return {
		"level": level,
		"public_standing": 0 if empty else 14,
		"public_standing_label": "UNLISTED" if empty else "COUNTY FAIR",
		"source_digest": {} if empty else {
			"day": 9,
			"eggs": 31,
			"quota": 28,
			"sound": 27,
			"cracked": 2,
			"golden": 2,
			"top_worker_id": 41,
			"top_worker_name": "Mabel",
			"met_quota": true,
			"hen_highlight": {},
		},
		"attribution": {} if empty else {
			"style_id": &"contested_credit",
			"style_label": "CONTESTED CREDIT",
			"worker_id": 41,
			"worker_name": "Mabel",
		},
		"last_receipt": {} if empty else {
			"day": 9,
			"campaign_label": "Layer Profile",
			"attribution": {"style_id": &"contested_credit", "style_label": "CONTESTED CREDIT", "worker_id": 41, "worker_name": "Mabel"},
		},
	}


func _assert_geometry_contract(visual: FarmerRelationsGalleryVisual, state: String, failures: Array[String]) -> void:
	_check(visual.geometry_bounds_inside_footprint(), "%s geometry should remain inside the exact parcel" % state, failures)
	_check(visual.connector_geometry_inside_bridge(), "%s connector should remain inside the exact bridge" % state, failures)
	_check(visual.circulation_clear(), "%s should preserve the protected east-entry aisle" % state, failures)
	_check(visual.find_children("*", "CollisionObject3D", true, false).is_empty(), "%s should add no collisions" % state, failures)
	_check(visual.find_children("*", "NavigationRegion3D", true, false).is_empty(), "%s should add no navigation regions" % state, failures)
	_check(visual.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "%s should add no navigation obstacles" % state, failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
