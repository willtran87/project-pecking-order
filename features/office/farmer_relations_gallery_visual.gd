class_name FarmerRelationsGalleryVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## Snapshot-driven, visual-only publicity pavilion. The room shell and empty
## fixtures are authored scenery; every hen name, shift result, attribution,
## standing value, and hung receipt comes only from `farmer_relations_gallery`.
const FACILITY_ID: StringName = &"farmer_relations_gallery"
const FACILITY_CENTER := Vector3(7.30, 0.0, 24.00)
const FOCUS_POINT := Vector3(7.30, 1.50, 24.00)
const FOOTPRINT := Rect2(Vector2(4.10, 21.10), Vector2(6.40, 5.80))
const ENTRANCE_BRIDGE_FOOTPRINT := Rect2(Vector2(10.50, 23.40), Vector2(0.25, 1.20))
const CLEAR_AISLE_FOOTPRINT := Rect2(Vector2(8.20, 23.45), Vector2(2.55, 1.10))
const EAST_DOOR_WIDTH := 1.20
const MAX_LEVEL := 3
const MAX_VISUAL_HEIGHT := 3.55

const BARN_RED := Color("8f5548")
const DEEP_BARN_RED := Color("633d37")
const OAT_LINEN := Color("ded1b6")
const PAPER_CREAM := Color("eee4cc")
const WALNUT := Color("664b39")
const DARK_WALNUT := Color("46362d")
const AGED_BRASS := Color("92723f")
const GRAPHITE := Color("303638")
const WARM_SLATE := Color("697274")
const PORTRAIT_SEPIA := Color("a87855")
const STATUS_GREEN := Color("749276")
const STATUS_AMBER := Color("d0a553")
const GLASS := Color(0.66, 0.72, 0.70, 0.18)

var locked_marker_root: Node3D
var survey_site_root: Node3D
var entrance_bridge_root: Node3D
var owned_room_root: Node3D
var level_1_root: Node3D
var level_2_root: Node3D
var level_3_root: Node3D

var _profile_evidence_root: Node3D
var _profile_label: Label3D
var _results_label: Label3D
var _standing_label: Label3D
var _attribution_label: Label3D
var _last_receipt_root: Node3D
var _last_receipt_label: Label3D
var _press_lamp: MeshInstance3D
var _rank_lamps: Array[MeshInstance3D] = []
var _material_cache: Dictionary[String, StandardMaterial3D] = {}

var _built := false
var _has_applied_snapshot := false
var _has_authoritative_gallery := false
var _unlocked := false
var _facility_level := 0
var _standing_points := 0
var _standing_rank := "UNLISTED"
var _source_digest: Dictionary = {}
var _attribution: Dictionary = {}
var _last_receipt: Dictionary = {}


func _ready() -> void:
	name = "FarmerRelationsGalleryVisual"
	position = FACILITY_CENTER
	set_meta(&"facility_id", FACILITY_ID)
	set_meta(&"visual_only", true)
	set_meta(&"collision_free", true)
	set_meta(&"navigation_free", true)
	set_meta(&"declared_footprint", FOOTPRINT)
	set_meta(&"entrance_bridge_footprint", ENTRANCE_BRIDGE_FOOTPRINT)
	set_meta(&"clear_aisle_footprint", CLEAR_AISLE_FOOTPRINT)
	set_meta(&"facility_focus_point", FOCUS_POINT)
	set_meta(&"maximum_visual_height", MAX_VISUAL_HEIGHT)
	if not _built:
		build()


static func declared_footprint() -> Rect2:
	return FOOTPRINT


static func facility_footprint() -> Rect2:
	return FOOTPRINT


static func entrance_bridge_footprint() -> Rect2:
	return ENTRANCE_BRIDGE_FOOTPRINT


static func clear_aisle_footprint() -> Rect2:
	return CLEAR_AISLE_FOOTPRINT


static func facility_focus_point() -> Vector3:
	return FOCUS_POINT


static func maximum_visual_height() -> float:
	return MAX_VISUAL_HEIGHT


func focus_point_global() -> Vector3:
	return to_global(Vector3(0.0, FOCUS_POINT.y, 0.0))


func build() -> void:
	clear()
	_built = true
	position = FACILITY_CENTER
	_build_entrance_bridge()
	_build_locked_marker()
	_build_survey_site()
	_build_owned_room()
	_build_level_1()
	_build_level_2()
	_build_level_3()
	_apply_visibility()
	_apply_dynamic_state()
	EnvironmentalSignageScript.set_camera_detail(self, false, FOCUS_POINT, 4.60, false)


func clear() -> void:
	for visual_root in [locked_marker_root, survey_site_root, entrance_bridge_root, owned_room_root]:
		if visual_root != null and is_instance_valid(visual_root):
			visual_root.free()
	locked_marker_root = null
	survey_site_root = null
	entrance_bridge_root = null
	owned_room_root = null
	level_1_root = null
	level_2_root = null
	level_3_root = null
	_profile_evidence_root = null
	_profile_label = null
	_results_label = null
	_standing_label = null
	_attribution_label = null
	_last_receipt_root = null
	_last_receipt_label = null
	_press_lamp = null
	_rank_lamps.clear()
	_material_cache.clear()
	_has_applied_snapshot = false
	_has_authoritative_gallery = false
	_unlocked = false
	_facility_level = 0
	_standing_points = 0
	_standing_rank = "UNLISTED"
	_source_digest.clear()
	_attribution.clear()
	_last_receipt.clear()
	_built = false


func apply_snapshot(snapshot: Dictionary) -> void:
	if not _built:
		build()
	var previous_level := _facility_level
	var gallery_variant: Variant = snapshot.get("farmer_relations_gallery", {})
	var gallery := _dictionary(gallery_variant)
	var catalog_entry := _catalog_entry(snapshot)
	_has_authoritative_gallery = snapshot.has("farmer_relations_gallery") and gallery_variant is Dictionary
	_facility_level = clampi(_snapshot_level(snapshot, gallery, catalog_entry), 0, MAX_LEVEL)
	_unlocked = (
		_facility_level > 0
		or bool(catalog_entry.get("unlocked", catalog_entry.get("available", catalog_entry.get("can_purchase", false))))
	)
	_read_standing(gallery)
	_source_digest = _dictionary(gallery.get("source_digest", gallery.get("frozen_evidence", gallery.get("evidence", {})))).duplicate(true)
	_last_receipt = _dictionary(gallery.get("last_receipt", {})).duplicate(true)
	_attribution = _dictionary(gallery.get("attribution", gallery.get("closing_attribution", {}))).duplicate(true)
	if _attribution.is_empty() and not _last_receipt.is_empty():
		_attribution = _dictionary(_last_receipt.get("attribution", {})).duplicate(true)
		if _attribution.is_empty():
			_attribution = _last_receipt.duplicate(true)
	_apply_visibility()
	_apply_dynamic_state()
	if _has_applied_snapshot and _facility_level > previous_level and is_inside_tree():
		for revealed_level in range(previous_level + 1, _facility_level + 1):
			_animate_reveal(revealed_level)
	_has_applied_snapshot = true


func set_camera_detail(focused: bool, focus_position: Vector3 = Vector3(INF, INF, INF)) -> void:
	var gallery_focused := focused
	if is_finite(focus_position.x) and is_finite(focus_position.y) and is_finite(focus_position.z):
		gallery_focused = focused and focus_position.distance_to(focus_point_global()) <= 5.20
	EnvironmentalSignageScript.set_camera_detail(self, gallery_focused, focus_position, 4.60)


func visual_state() -> StringName:
	if _facility_level > 0:
		return StringName("level_%d" % _facility_level)
	return &"survey" if _unlocked else &"locked"


func current_level() -> int:
	return _facility_level


func level_visible(level: int) -> bool:
	var root_for_level := _level_root(level)
	return root_for_level != null and root_for_level.visible


func locked_marker_visible() -> bool:
	return locked_marker_root != null and locked_marker_root.visible


func survey_site_visible() -> bool:
	return survey_site_root != null and survey_site_root.visible


func owned_room_visible() -> bool:
	return owned_room_root != null and owned_room_root.visible


func has_authoritative_gallery() -> bool:
	return _has_authoritative_gallery


func evidence_profile_visible() -> bool:
	return _profile_evidence_root != null and _profile_evidence_root.visible


func last_receipt_visible() -> bool:
	return _last_receipt_root != null and _last_receipt_root.visible


func standing_text() -> String:
	return _standing_label.text if _standing_label != null else ""


func results_text() -> String:
	return _results_label.text if _results_label != null else ""


func attribution_text() -> String:
	return _attribution_label.text if _attribution_label != null else ""


func last_receipt_text() -> String:
	return _last_receipt_label.text if _last_receipt_label != null else ""


func geometry_bounds_inside_footprint() -> bool:
	var local_half := FOOTPRINT.size * 0.5
	var tolerance := 0.012
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null or _is_connector_geometry(instance):
			continue
		for corner in _mesh_corners_in_visual_space(instance):
			if absf(corner.x) > local_half.x + tolerance or absf(corner.z) > local_half.y + tolerance or corner.y > MAX_VISUAL_HEIGHT + tolerance:
				return false
	return true


func connector_geometry_inside_bridge() -> bool:
	var found := false
	var tolerance := 0.012
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null or not _is_connector_geometry(instance):
			continue
		found = true
		for corner in _mesh_corners_in_visual_space(instance):
			var world_xz := Vector2(corner.x + FACILITY_CENTER.x, corner.z + FACILITY_CENTER.z)
			if world_xz.x < ENTRANCE_BRIDGE_FOOTPRINT.position.x - tolerance or world_xz.x > ENTRANCE_BRIDGE_FOOTPRINT.end.x + tolerance or world_xz.y < ENTRANCE_BRIDGE_FOOTPRINT.position.y - tolerance or world_xz.y > ENTRANCE_BRIDGE_FOOTPRINT.end.y + tolerance:
				return false
	return found


func circulation_clear() -> bool:
	var aisle_local := Rect2(CLEAR_AISLE_FOOTPRINT.position - Vector2(FACILITY_CENTER.x, FACILITY_CENTER.z), CLEAR_AISLE_FOOTPRINT.size)
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null:
			continue
		var bounds := _mesh_bounds_in_visual_space(instance)
		if bounds.end.y <= 0.08 or bounds.position.y >= 2.45:
			continue
		var xz := Rect2(Vector2(bounds.position.x, bounds.position.z), Vector2(bounds.size.x, bounds.size.z))
		if xz.intersects(aisle_local):
			return false
	return true


func _build_entrance_bridge() -> void:
	entrance_bridge_root = Node3D.new()
	entrance_bridge_root.name = "FarmerRelationsEntranceBridge"
	entrance_bridge_root.set_meta(&"visual_only", true)
	entrance_bridge_root.set_meta(&"collision_free", true)
	entrance_bridge_root.set_meta(&"navigation_free", true)
	entrance_bridge_root.set_meta(&"campus_connector", true)
	entrance_bridge_root.set_meta(&"declared_footprint", ENTRANCE_BRIDGE_FOOTPRINT)
	add_child(entrance_bridge_root)
	_add_box(entrance_bridge_root, "FarmerRelationsBridgeDeck", Vector3(0.25, 0.10, 1.20), Vector3(3.325, -0.055, 0.0), OAT_LINEN.darkened(0.10))
	for edge_z in [-0.54, 0.54]:
		_add_box(entrance_bridge_root, "FarmerRelationsBridgeBrassEdge", Vector3(0.22, 0.018, 0.035), Vector3(3.325, 0.005, edge_z), AGED_BRASS, 0.48, 0.34)


func _build_locked_marker() -> void:
	locked_marker_root = Node3D.new()
	locked_marker_root.name = "FarmerRelationsLockedParcel"
	locked_marker_root.set_meta(&"facility_state", &"locked")
	add_child(locked_marker_root)
	for z in [-2.72, 2.72]:
		_add_box(locked_marker_root, "GalleryLeaseLineZ", Vector3(6.08, 0.035, 0.055), Vector3(0.0, 0.025, z), AGED_BRASS.darkened(0.24))
	for x in [-3.02, 3.02]:
		for z in [-1.70, 1.70]:
			_add_box(locked_marker_root, "GalleryLeaseLineX", Vector3(0.055, 0.035, 1.94), Vector3(x, 0.025, z), AGED_BRASS.darkened(0.24))
	var host := _add_box(locked_marker_root, "GalleryLeaseNoticeHost", Vector3(3.44, 0.86, 0.10), Vector3(-0.34, 1.08, 2.56), DEEP_BARN_RED)
	EnvironmentalSignageScript.add_panel(host, "GalleryLeaseNotice", "FARMER RELATIONS PARCEL\nPUBLICITY CHARTER REQUIRED", Vector3(0.0, 0.0, 0.058), Vector2(3.14, 0.64), DEEP_BARN_RED, PAPER_CREAM, Vector3.ZERO, 13, 0.00245, &"secondary", &"paper")


func _build_survey_site() -> void:
	survey_site_root = Node3D.new()
	survey_site_root.name = "FarmerRelationsSurveySite"
	survey_site_root.set_meta(&"facility_state", &"survey")
	add_child(survey_site_root)
	_add_box(survey_site_root, "GallerySurveyMat", Vector3(6.08, 0.035, 5.48), Vector3.ZERO, BARN_RED.darkened(0.30))
	for center in [Vector3(-1.86, 0.025, 1.32), Vector3(-1.86, 0.025, -1.32)]:
		_add_box(survey_site_root, "GallerySurveyPlinthOutline", Vector3(1.46, 0.018, 0.055), center, AGED_BRASS.darkened(0.16))
	var board := _add_box(survey_site_root, "GallerySurveyBoardHost", Vector3(3.08, 0.82, 0.10), Vector3(-0.74, 1.04, 2.55), BARN_RED)
	EnvironmentalSignageScript.add_panel(board, "GallerySurveyBoard", "FARMER RELATIONS GALLERY\nPAVILION PLAN FILED", Vector3(0.0, 0.0, 0.058), Vector2(2.80, 0.60), BARN_RED, PAPER_CREAM, Vector3.ZERO, 13, 0.00245, &"secondary", &"paper")
	var crate := _add_box(survey_site_root, "UnopenedGalleryFixtureCrate", Vector3(1.28, 0.78, 0.96), Vector3(-2.18, 0.39, -1.38), WALNUT)
	for band_x in [-0.42, 0.42]:
		_add_box(crate, "GalleryCrateBrassBand", Vector3(0.09, 0.82, 1.00), Vector3(band_x, 0.0, 0.0), AGED_BRASS.darkened(0.10), 0.58, 0.22)


func _build_owned_room() -> void:
	owned_room_root = Node3D.new()
	owned_room_root.name = "FarmerRelationsOwnedRoom"
	owned_room_root.set_meta(&"visual_only", true)
	owned_room_root.set_meta(&"collision_free", true)
	owned_room_root.set_meta(&"navigation_free", true)
	add_child(owned_room_root)
	_add_box(owned_room_root, "GalleryFoundation", Vector3(6.40, 0.16, 5.80), Vector3(0.0, -0.08, 0.0), GRAPHITE.darkened(0.04))
	_add_box(owned_room_root, "GalleryOatFloor", Vector3(6.14, 0.035, 5.54), Vector3(0.0, 0.018, 0.0), OAT_LINEN.darkened(0.16))
	_add_box(owned_room_root, "GalleryBackWall", Vector3(6.10, 3.15, 0.12), Vector3(0.0, 1.575, -2.70), DEEP_BARN_RED)
	_add_box(owned_room_root, "GalleryWestWall", Vector3(0.12, 3.15, 5.28), Vector3(-3.05, 1.575, -0.06), BARN_RED.darkened(0.12))
	for post in [Vector3(-3.02, 1.65, -2.70), Vector3(3.02, 1.65, -2.70), Vector3(-3.02, 1.65, 2.70), Vector3(3.02, 1.65, 2.70)]:
		_add_box(owned_room_root, "GalleryStructuralPost", Vector3(0.12, 3.30, 0.12), post, DARK_WALNUT)
	for wing_z in [-1.67, 1.67]:
		_add_glass_box(owned_room_root, "GalleryEastGlassWing", Vector3(0.035, 2.32, 1.82), Vector3(3.00, 1.24, wing_z))
		for edge_z in [-0.91, 0.91]:
			_add_box(owned_room_root, "GalleryEastGlassMullion", Vector3(0.075, 2.44, 0.075), Vector3(3.00, 1.25, wing_z + edge_z), DARK_WALNUT, 0.70)
		_add_box(owned_room_root, "GalleryEastGlassThreshold", Vector3(0.080, 0.080, 1.90), Vector3(3.00, 0.06, wing_z), AGED_BRASS.darkened(0.20), 0.50, 0.30)
		_add_box(owned_room_root, "GalleryEastGlassTopRail", Vector3(0.080, 0.10, 1.90), Vector3(3.00, 2.44, wing_z), DARK_WALNUT, 0.68)
	_add_box(owned_room_root, "GalleryEastDoorHeader", Vector3(0.14, 0.16, EAST_DOOR_WIDTH + 0.20), Vector3(3.00, 2.58, 0.0), AGED_BRASS.darkened(0.08), 0.46, 0.34)
	# A substantial walnut fascia carries shallow, modeled destination letters.
	# The former two-line wall print became tiny at the management-camera angle and
	# read like floating HUD copy; this single-line wordmark now belongs to the beam.
	var identity_host := _add_box(owned_room_root, "FarmerRelationsIdentityHost", Vector3(5.34, 0.66, 0.14), Vector3(0.0, 2.78, -2.60), DARK_WALNUT, 0.70)
	_add_box(identity_host, "GalleryIdentityBrassCapTop", Vector3(5.38, 0.045, 0.17), Vector3(0.0, 0.285, 0.0), AGED_BRASS.darkened(0.16), 0.48, 0.36)
	_add_box(identity_host, "GalleryIdentityBrassCapBottom", Vector3(5.38, 0.030, 0.17), Vector3(0.0, -0.292, 0.0), AGED_BRASS.darkened(0.24), 0.52, 0.32)
	EnvironmentalSignageScript.add_panel(identity_host, "FarmerRelationsGalleryIdentity", "HARVEST CREDIT GALLERY", Vector3(0.0, 0.0, 0.078), Vector2(4.86, 0.42), DARK_WALNUT, AGED_BRASS.lightened(0.16), Vector3.ZERO, 18, 0.0032, &"primary", &"destination")
	# Perimeter headers visibly carry two restrained joists; every end now lands on
	# structure, and the exhibit sightlines stay substantially more open.
	for header_z in [-2.62, 2.62]:
		_add_box(owned_room_root, "GalleryCeilingHeader", Vector3(6.08, 0.12, 0.12), Vector3(0.0, 3.28, header_z), DARK_WALNUT, 0.70)
	for beam_x in [-2.98, 2.98]:
		_add_box(owned_room_root, "GalleryCeilingBeam", Vector3(0.075, 0.075, 5.18), Vector3(beam_x, 3.31, 0.0), WALNUT, 0.72)


func _build_level_1() -> void:
	level_1_root = Node3D.new()
	level_1_root.name = "BasketPressDeskLevelOne"
	level_1_root.set_meta(&"facility_level", 1)
	owned_room_root.add_child(level_1_root)
	var plinth := _add_box(level_1_root, "UpgradedBasketPlinth", Vector3(1.72, 0.86, 1.18), Vector3(-1.70, 0.43, 1.36), WALNUT)
	_add_box(level_1_root, "BasketPlinthStoneTop", Vector3(1.92, 0.14, 1.36), Vector3(-1.70, 0.93, 1.36), OAT_LINEN.lightened(0.02))
	_add_box(plinth, "BasketPlinthBrassInset", Vector3(1.48, 0.46, 0.045), Vector3(0.0, 0.02, 0.612), AGED_BRASS.darkened(0.10), 0.42, 0.48)
	var standing_host := _add_box(plinth, "PublicStandingReadoutHost", Vector3(1.30, 0.32, 0.040), Vector3(0.0, 0.02, 0.642), GRAPHITE)
	_standing_label = EnvironmentalSignageScript.add_panel(standing_host, "PublicStandingReadout", "PUBLIC STANDING\nUNLISTED / 0 PT", Vector3(0.0, 0.0, 0.026), Vector2(1.14, 0.24), GRAPHITE, STATUS_AMBER, Vector3.ZERO, 9, 0.00175, &"utility", &"screen", true)
	# An intentionally empty presentation basket avoids inventing an egg or result.
	var basket := Node3D.new()
	basket.name = "AuthoritativeEmptyPressBasket"
	basket.position = Vector3(-1.70, 1.07, 1.36)
	level_1_root.add_child(basket)
	for side_x in [-0.58, 0.58]:
		_add_box(basket, "PressBasketSide", Vector3(0.10, 0.52, 0.82), Vector3(side_x, 0.22, 0.0), AGED_BRASS, 0.56, 0.34)
	for slat in 5:
		_add_box(basket, "PressBasketSlat", Vector3(1.14, 0.055, 0.72), Vector3(0.0, 0.04 + slat * 0.10, 0.0), PORTRAIT_SEPIA.darkened(0.08))
	for handle_x in [-0.58, 0.58]:
		_add_box(basket, "PressBasketHandleUpright", Vector3(0.08, 0.30, 0.08), Vector3(handle_x, 0.58, 0.0), AGED_BRASS, 0.44, 0.46)
	_add_box(basket, "PressBasketHandle", Vector3(1.18, 0.08, 0.08), Vector3(0.0, 0.72, 0.0), AGED_BRASS, 0.44, 0.46)

	var frame := _add_box(level_1_root, "LayerPortraitFrame", Vector3(1.40, 1.72, 0.10), Vector3(-2.05, 1.70, -2.57), AGED_BRASS.darkened(0.08), 0.44, 0.46)
	_add_box(frame, "LayerPortraitMat", Vector3(1.18, 1.48, 0.045), Vector3(0.0, 0.0, 0.072), OAT_LINEN)
	_profile_evidence_root = Node3D.new()
	_profile_evidence_root.name = "AuthoritativeLayerProfile"
	_profile_evidence_root.position = Vector3(-2.05, 1.70, -2.47)
	_profile_evidence_root.set_meta(&"authoritative_record", true)
	level_1_root.add_child(_profile_evidence_root)
	# A connected, sepia chicken bust reads as the credited layer rather than a
	# generic egg: body, head, wing, beak, comb, and eye overlap as one silhouette.
	_add_sphere(_profile_evidence_root, "LayerPortraitBody", Vector3(-0.04, 0.08, 0.0), Vector3(0.66, 0.62, 0.11), PORTRAIT_SEPIA)
	_add_sphere(_profile_evidence_root, "LayerPortraitHead", Vector3(0.08, 0.39, 0.008), Vector3(0.43, 0.43, 0.12), PORTRAIT_SEPIA.lightened(0.04))
	_add_sphere(_profile_evidence_root, "LayerPortraitWing", Vector3(-0.24, 0.06, 0.020), Vector3(0.34, 0.39, 0.13), PORTRAIT_SEPIA.darkened(0.10))
	_add_box(_profile_evidence_root, "LayerPortraitBeak", Vector3(0.18, 0.10, 0.055), Vector3(0.34, 0.38, 0.025), AGED_BRASS.lightened(0.08), 0.66)
	for comb_x in [-0.07, 0.04, 0.15]:
		_add_sphere(_profile_evidence_root, "LayerPortraitComb", Vector3(comb_x, 0.62, 0.012), Vector3(0.11, 0.13, 0.055), BARN_RED.lightened(0.08))
	_add_sphere(_profile_evidence_root, "LayerPortraitEye", Vector3(0.19, 0.47, 0.065), Vector3(0.055, 0.055, 0.030), GRAPHITE)
	var profile_host := _add_box(_profile_evidence_root, "LayerProfileNameplateHost", Vector3(1.12, 0.40, 0.04), Vector3(0.0, -0.50, 0.02), DEEP_BARN_RED)
	_profile_label = EnvironmentalSignageScript.add_panel(profile_host, "LayerProfileNameplate", "VERIFIED LAYER\nAWAITING CLOSED SHIFT", Vector3(0.0, 0.0, 0.028), Vector2(1.00, 0.30), DEEP_BARN_RED, PAPER_CREAM, Vector3.ZERO, 9, 0.0017, &"utility", &"stencil")


func _build_level_2() -> void:
	level_2_root = Node3D.new()
	level_2_root.name = "PressBackdropLevelTwo"
	level_2_root.set_meta(&"facility_level", 2)
	owned_room_root.add_child(level_2_root)
	_add_box(level_2_root, "HarvestPressBackdrop", Vector3(2.54, 2.20, 0.08), Vector3(0.15, 1.34, -2.54), BARN_RED)
	for fold_x in [-0.96, -0.48, 0.0, 0.48, 0.96]:
		_add_box(level_2_root, "PressBackdropLinenFold", Vector3(0.055, 1.86, 0.035), Vector3(0.15 + fold_x, 1.34, -2.485), OAT_LINEN.darkened(0.06))
	var result_host := _add_box(level_2_root, "ClutchResultsBoardHost", Vector3(2.16, 0.92, 0.10), Vector3(0.15, 1.66, -2.44), GRAPHITE)
	_results_label = EnvironmentalSignageScript.add_panel(result_host, "ClutchResultsBoard", "NO CLOSED SHIFT EVIDENCE", Vector3(0.0, 0.0, 0.058), Vector2(1.96, 0.74), GRAPHITE, PAPER_CREAM, Vector3.ZERO, 10, 0.00195, &"utility", &"screen", true)
	var press := _add_box(level_2_root, "BasketBylinePress", Vector3(1.20, 0.78, 0.72), Vector3(-0.15, 0.39, -1.48), DARK_WALNUT)
	_add_box(level_2_root, "BasketBylinePressBed", Vector3(1.44, 0.12, 0.94), Vector3(-0.15, 0.84, -1.48), AGED_BRASS.darkened(0.12), 0.44, 0.42)
	_add_cylinder(press, "BasketBylinePressWheel", Vector3(0.62, 0.18, 0.0), 0.22, 0.08, AGED_BRASS, 0.42, 0.48).rotation_degrees.z = 90.0
	_press_lamp = _add_box(level_2_root, "BasketPressFiledLamp", Vector3(0.18, 0.18, 0.10), Vector3(0.58, 1.00, -1.48), GRAPHITE)
	# Compact wall-mounted key lights preserve the press-upgrade silhouette without
	# drawing long rails across the credited hen portrait or the results board.
	for light_index in 2:
		var light_x: float = [-2.72, 2.72][light_index]
		_add_box(level_2_root, "PressCameraLightRail_%02d" % (light_index + 1), Vector3(0.08, 0.08, 0.30), Vector3(light_x, 2.62, -2.40), WALNUT)
		_add_box(level_2_root, "PressCameraLightDropArm_%02d" % (light_index + 1), Vector3(0.065, 0.24, 0.065), Vector3(light_x, 2.51, -2.27), DARK_WALNUT, 0.62, 0.12)
		var light := _add_box(level_2_root, "PressCameraSoftbox_%02d" % (light_index + 1), Vector3(0.32, 0.20, 0.12), Vector3(light_x, 2.35, -2.22), GRAPHITE, 0.48, 0.08)
		var light_face := _add_box(light, "PressCameraSoftboxFace", Vector3(0.24, 0.13, 0.025), Vector3(0.0, 0.0, 0.073), OAT_LINEN.lightened(0.10))
		light_face.material_override = _emissive_material(OAT_LINEN, 0.38)


func _build_level_3() -> void:
	level_3_root = Node3D.new()
	level_3_root.name = "AttributionWallLevelThree"
	level_3_root.set_meta(&"facility_level", 3)
	owned_room_root.add_child(level_3_root)
	var wall := _add_box(level_3_root, "HarvestAttributionWall", Vector3(1.78, 2.28, 0.10), Vector3(2.00, 1.42, -2.52), WALNUT)
	var attribution_host := _add_box(wall, "ClosingAttributionHost", Vector3(1.52, 0.82, 0.045), Vector3(0.0, 0.30, 0.078), DEEP_BARN_RED)
	_attribution_label = EnvironmentalSignageScript.add_panel(attribution_host, "ClosingAttributionReadout", "CLOSING ATTRIBUTION\nNO CREDIT MEMO HUNG", Vector3(0.0, 0.0, 0.030), Vector2(1.36, 0.65), DEEP_BARN_RED, PAPER_CREAM, Vector3.ZERO, 12, 0.0022, &"utility", &"stencil")
	# The farmer portrait is authored corporate decor; no hen portrait is shown
	# unless a canonical source digest supplies the named layer above.
	var farmer_frame := _add_box(wall, "FarmerPortraitFrame", Vector3(1.08, 0.92, 0.045), Vector3(0.0, -0.62, 0.078), AGED_BRASS.darkened(0.06), 0.42, 0.50)
	_add_box(farmer_frame, "FarmerPortraitMat", Vector3(0.90, 0.74, 0.030), Vector3(0.0, 0.0, 0.030), OAT_LINEN)
	_add_sphere(farmer_frame, "FarmerPortraitShoulders", Vector3(0.0, -0.16, 0.060), Vector3(0.64, 0.38, 0.08), PORTRAIT_SEPIA.darkened(0.18))
	_add_sphere(farmer_frame, "FarmerPortraitHead", Vector3(0.0, 0.10, 0.064), Vector3(0.34, 0.39, 0.09), PORTRAIT_SEPIA.darkened(0.08))
	_add_box(farmer_frame, "FarmerPortraitHatBrim", Vector3(0.72, 0.09, 0.055), Vector3(0.0, 0.31, 0.070), DARK_WALNUT, 0.76)
	_add_box(farmer_frame, "FarmerPortraitHatCrown", Vector3(0.42, 0.22, 0.060), Vector3(0.0, 0.39, 0.068), WALNUT, 0.78)

	var shelf := _add_box(level_3_root, "PublicStandingAwardShelf", Vector3(1.84, 0.14, 0.58), Vector3(-2.04, 1.02, -0.98), WALNUT)
	_add_box(level_3_root, "AwardShelfBack", Vector3(1.84, 1.14, 0.10), Vector3(-2.04, 1.52, -1.24), DEEP_BARN_RED)
	for rank_index in 4:
		var lamp := _add_cylinder(shelf, "StandingRankMedallion_%02d" % rank_index, Vector3(-0.66 + rank_index * 0.44, 0.18, 0.02), 0.14, 0.055, GRAPHITE, 0.52, 0.18)
		lamp.rotation_degrees.x = 90.0
		_rank_lamps.append(lamp)

	_last_receipt_root = Node3D.new()
	_last_receipt_root.name = "AuthoritativeLastHungReceipt"
	_last_receipt_root.position = Vector3(-2.04, 1.58, -1.17)
	_last_receipt_root.set_meta(&"authoritative_record", true)
	level_3_root.add_child(_last_receipt_root)
	var receipt_host := _add_box(_last_receipt_root, "LastHungReceiptHost", Vector3(1.62, 0.78, 0.045), Vector3.ZERO, PAPER_CREAM)
	_last_receipt_label = EnvironmentalSignageScript.add_panel(receipt_host, "LastHungReceipt", "LAST HUNG\nNO FILED RECEIPT", Vector3(0.0, 0.0, 0.030), Vector2(1.46, 0.64), PAPER_CREAM, DEEP_BARN_RED, Vector3.ZERO, 10, 0.0019, &"utility", &"paper")


func _apply_visibility() -> void:
	if locked_marker_root != null:
		locked_marker_root.visible = not _unlocked and _facility_level == 0
	if survey_site_root != null:
		survey_site_root.visible = _unlocked and _facility_level == 0
	if entrance_bridge_root != null:
		entrance_bridge_root.visible = _facility_level > 0
	if owned_room_root != null:
		owned_room_root.visible = _facility_level > 0
	for level in range(1, MAX_LEVEL + 1):
		var root_for_level := _level_root(level)
		if root_for_level != null:
			root_for_level.visible = _facility_level >= level


func _apply_dynamic_state() -> void:
	if _profile_evidence_root != null:
		_profile_evidence_root.visible = _facility_level >= 1 and _has_source_worker()
	if _profile_label != null and _has_source_worker():
		var worker_name := _source_worker_name().to_upper()
		var evidence_day := maxi(0, int(_source_digest.get("day", 0)))
		_profile_label.text = "%s\nDAY %02d / VERIFIED SOURCE" % [worker_name, evidence_day]
		EnvironmentalSignageScript.refit_label(_profile_label)
	if _standing_label != null:
		_standing_label.text = (
			"PUBLIC STANDING\n%s / %d PT" % [_standing_rank, _standing_points]
			if _has_authoritative_gallery else "PUBLIC STANDING\nUNFILED"
		)
		EnvironmentalSignageScript.refit_label(_standing_label)
	if _results_label != null:
		_results_label.text = _evidence_results_text()
		EnvironmentalSignageScript.refit_label(_results_label)
	if _attribution_label != null:
		_attribution_label.text = _closing_attribution_text()
		EnvironmentalSignageScript.refit_label(_attribution_label)
	if _last_receipt_root != null:
		_last_receipt_root.visible = _facility_level >= 3 and _has_valid_receipt()
	if _last_receipt_label != null and _has_valid_receipt():
		_last_receipt_label.text = _last_hung_text()
		EnvironmentalSignageScript.refit_label(_last_receipt_label)
	if _press_lamp != null:
		_press_lamp.material_override = _emissive_material(STATUS_GREEN, 0.76) if _facility_level >= 2 and _has_valid_receipt() else _material(GRAPHITE, 0.70)
	var rank_index := _standing_rank_index()
	for index in _rank_lamps.size():
		_rank_lamps[index].material_override = _emissive_material(AGED_BRASS, 0.54) if _has_authoritative_gallery and index <= rank_index else _material(GRAPHITE, 0.70)


func _evidence_results_text() -> String:
	if not _has_authoritative_gallery or _source_digest.is_empty():
		return "NO CLOSED SHIFT EVIDENCE"
	var day := maxi(0, int(_source_digest.get("day", 0)))
	var eggs := maxi(0, int(_source_digest.get("eggs", 0)))
	var quota := maxi(0, int(_source_digest.get("quota", 0)))
	var sound := maxi(0, int(_source_digest.get("sound", maxi(0, eggs - int(_source_digest.get("cracked", 0)) - int(_source_digest.get("golden", 0))))))
	var cracked := maxi(0, int(_source_digest.get("cracked", 0)))
	var golden := maxi(0, int(_source_digest.get("golden", 0)))
	return "DAY %02d  CLUTCH %02d/%02d\nS %02d  C %02d  G %02d" % [day, eggs, quota, sound, cracked, golden]


func _closing_attribution_text() -> String:
	if not _has_authoritative_gallery or _attribution.is_empty():
		return "CLOSING ATTRIBUTION\nNO CREDIT MEMO HUNG"
	var style := String(_attribution.get("style_label", _attribution.get("attribution_label", _attribution.get("style_id", _attribution.get("attribution_style", ""))))).strip_edges().replace("_", " ").to_upper()
	var subject := String(_attribution.get("subject_label", _attribution.get("credited_to", _attribution.get("source_name", "")))).strip_edges().to_upper()
	if subject.is_empty():
		var style_id := String(_attribution.get("style_id", _attribution.get("attribution_style", ""))).strip_edges().to_lower()
		match style_id:
			"flock_authored":
				subject = "FLOCK"
			"farmer_authored":
				subject = "FARMER METHOD"
			_:
				subject = String(_attribution.get("worker_name", "")).strip_edges().to_upper()
	if style.is_empty() or subject.is_empty():
		return "CLOSING ATTRIBUTION\nNO CREDIT MEMO HUNG"
	return "CLOSING ATTRIBUTION\n%s / %s" % [style, subject]


func _last_hung_text() -> String:
	var day := maxi(0, int(_last_receipt.get("day", _last_receipt.get("review_day", 0))))
	var label := String(_last_receipt.get("campaign_label", _last_receipt.get("offer_label", _last_receipt.get("label", _last_receipt.get("offer_id", ""))))).strip_edges().replace("_", " ").to_upper()
	return "LAST HUNG / DAY %02d\n%s" % [day, label]


func _has_valid_receipt() -> bool:
	if not _has_authoritative_gallery or _last_receipt.is_empty():
		return false
	var day := int(_last_receipt.get("day", _last_receipt.get("review_day", 0)))
	var label := String(_last_receipt.get("campaign_label", _last_receipt.get("offer_label", _last_receipt.get("label", _last_receipt.get("offer_id", ""))))).strip_edges()
	return day > 0 and not label.is_empty()


func _has_source_worker() -> bool:
	return _has_authoritative_gallery and not _source_worker_name().is_empty()


func _source_worker_name() -> String:
	var direct := String(_source_digest.get("top_worker_name", _source_digest.get("worker_name", ""))).strip_edges()
	if not direct.is_empty():
		return direct
	var worker := _dictionary(_source_digest.get("top_worker", _source_digest.get("source_worker", {})))
	return String(worker.get("name", worker.get("display_name", ""))).strip_edges()


func _read_standing(gallery: Dictionary) -> void:
	_standing_points = 0
	_standing_rank = "UNLISTED"
	var standing: Variant = gallery.get("public_standing", gallery.get("standing_points", 0))
	if standing is Dictionary:
		var record := standing as Dictionary
		_standing_points = maxi(0, int(record.get("points", record.get("value", 0))))
		_standing_rank = String(record.get("label", record.get("rank", gallery.get("public_standing_label", gallery.get("standing_label", gallery.get("standing_rank", "UNLISTED")))))).strip_edges().replace("_", " ").to_upper()
	else:
		_standing_points = maxi(0, int(standing))
		var rank_value: Variant = gallery.get("public_standing_label", gallery.get("standing_label", gallery.get("standing_rank", "UNLISTED")))
		if rank_value is Dictionary:
			_standing_rank = String((rank_value as Dictionary).get("label", (rank_value as Dictionary).get("rank", "UNLISTED"))).strip_edges().replace("_", " ").to_upper()
		else:
			_standing_rank = String(rank_value).strip_edges().replace("_", " ").to_upper()
	if _standing_rank.is_empty():
		_standing_rank = "UNLISTED"


func _standing_rank_index() -> int:
	var normalized := _standing_rank.to_lower()
	if "household" in normalized or "national" in normalized:
		return 3
	if "regional" in normalized:
		return 2
	if "county" in normalized:
		return 1
	if "roadside" in normalized:
		return 0
	return -1


func _snapshot_level(snapshot: Dictionary, gallery: Dictionary, catalog_entry: Dictionary) -> int:
	if gallery.has("level"):
		return int(gallery.get("level", 0))
	var owned := _dictionary(snapshot.get("owned_facilities", {}))
	if owned.has(FACILITY_ID) or owned.has(String(FACILITY_ID)):
		return int(owned.get(FACILITY_ID, owned.get(String(FACILITY_ID), 0)))
	return int(catalog_entry.get("level", catalog_entry.get("owned_level", 0)))


func _catalog_entry(snapshot: Dictionary) -> Dictionary:
	var catalog: Variant = snapshot.get("facility_catalog", [])
	if catalog is Array:
		for value in catalog as Array:
			if value is Dictionary and StringName(String((value as Dictionary).get("id", ""))) == FACILITY_ID:
				return value as Dictionary
	elif catalog is Dictionary:
		var entry: Variant = (catalog as Dictionary).get(FACILITY_ID, (catalog as Dictionary).get(String(FACILITY_ID), {}))
		if entry is Dictionary:
			return entry as Dictionary
	return {}


func _dictionary(value: Variant) -> Dictionary:
	return value as Dictionary if value is Dictionary else {}


func _level_root(level: int) -> Node3D:
	match level:
		1: return level_1_root
		2: return level_2_root
		3: return level_3_root
	return null


func _animate_reveal(level: int) -> void:
	var root_for_level := _level_root(level)
	if root_for_level == null:
		return
	# Keep overhead light rigs above the protected chicken volume throughout the
	# reveal. A plan-view bloom reads without ever changing vertical clearance.
	root_for_level.scale = Vector3(0.90, 1.0, 0.90)
	var tween := create_tween().bind_node(root_for_level)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(root_for_level, "scale", Vector3.ONE, 0.46)


func _is_connector_geometry(instance: MeshInstance3D) -> bool:
	var cursor: Node = instance
	while cursor != null and cursor != self:
		if bool(cursor.get_meta(&"campus_connector", false)):
			return true
		cursor = cursor.get_parent()
	return false


func _mesh_corners_in_visual_space(instance: MeshInstance3D) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var bounds := instance.mesh.get_aabb()
	for x in [bounds.position.x, bounds.end.x]:
		for y in [bounds.position.y, bounds.end.y]:
			for z in [bounds.position.z, bounds.end.z]:
				result.append(to_local(instance.to_global(Vector3(x, y, z))))
	return result


func _mesh_bounds_in_visual_space(instance: MeshInstance3D) -> AABB:
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	for corner in _mesh_corners_in_visual_space(instance):
		minimum = minimum.min(corner)
		maximum = maximum.max(corner)
	return AABB(minimum, maximum - minimum)


func _add_box(parent: Node3D, part_name: String, size: Vector3, part_position: Vector3, color: Color, roughness: float = 0.82, metallic: float = 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color, roughness, metallic)
	parent.add_child(instance)
	return instance


func _add_cylinder(parent: Node3D, part_name: String, part_position: Vector3, radius: float, height: float, color: Color, roughness: float = 0.82, metallic: float = 0.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color, roughness, metallic)
	parent.add_child(instance)
	return instance


func _add_sphere(parent: Node3D, part_name: String, part_position: Vector3, part_scale: Vector3, color: Color, roughness: float = 0.82) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 20
	mesh.rings = 12
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.scale = part_scale
	instance.material_override = _material(color, roughness)
	parent.add_child(instance)
	return instance


func _add_glass_box(parent: Node3D, part_name: String, size: Vector3, part_position: Vector3) -> MeshInstance3D:
	var glass := _add_box(parent, part_name, size, part_position, GLASS, 0.22, 0.02)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return glass


func _material(color: Color, roughness: float = 0.82, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "%s|%.3f|%.3f" % [color.to_html(true), roughness, metallic]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	_material_cache[key] = material
	return material


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var key := "emissive|%s|%.3f" % [color.to_html(true), energy]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.34)
	material.roughness = 0.46
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.resource_local_to_scene = true
	_material_cache[key] = material
	return material
