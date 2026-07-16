class_name FlockRelationsOfficeVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## Snapshot-driven, visual-only personnel and compliance facility. Furniture and
## empty machinery are authored environment props; case folders and worker
## identifiers exist only for canonical flock_relations.open_cases records, and
## outcome hardware activates only from flock_relations.last_resolution.
const FACILITY_ID: StringName = &"flock_relations_office"
const FACILITY_CENTER := Vector3(7.30, 0.0, 36.00)
const FOCUS_POINT := Vector3(7.30, 1.05, 36.00)
const FOOTPRINT := Rect2(Vector2(4.10, 33.10), Vector2(6.40, 5.80))
const ENTRANCE_BRIDGE_FOOTPRINT := Rect2(Vector2(10.50, 35.40), Vector2(0.25, 1.20))
const CLEAR_AISLE_FOOTPRINT := Rect2(Vector2(8.20, 35.45), Vector2(2.55, 1.10))
const MAX_LEVEL := 3
const MAX_OPAQUE_HEIGHT := 3.55
const MAX_VISIBLE_CASES := 6
const EAST_DOOR_WIDTH := 1.20

const MULBERRY := Color("55404f")
const DEEP_MULBERRY := Color("3d303a")
const INK_CHARCOAL := Color("30363a")
const WARM_GRAY := Color("b8b0a0")
const OATMEAL := Color("ddd2b8")
const PAPER_CREAM := Color("eee5cf")
const OXIDIZED_BRASS := Color("b49a5a")
const FELT_PLUM := Color("735a6c")
const DUSTY_LILAC := Color("988497")
const STATUS_GREEN := Color("709979")
const STATUS_AMBER := Color("d0a557")
const STATUS_RED := Color("a95f5a")
const SCREEN_BLUE := Color("7da0a0")
const SMOKED_GLASS := Color(0.53, 0.58, 0.60, 0.38)
const CLERESTORY_GLASS := Color(0.72, 0.78, 0.76, 0.13)

var governance_foundation_root: Node3D
var entrance_bridge_root: Node3D
var locked_marker_root: Node3D
var survey_site_root: Node3D
var owned_room_root: Node3D
var level_1_root: Node3D
var level_2_root: Node3D
var level_3_root: Node3D

var _case_console_label: Label3D
var _case_folder_root: Node3D
var _case_folders: Array[Node3D] = []
var _resolution_docket_root: Node3D
var _resolution_dockets: Array[Node3D] = []
var _outcome_lamps: Dictionary[StringName, MeshInstance3D] = {}
var _material_cache: Dictionary[String, StandardMaterial3D] = {}

var _built := false
var _has_applied_snapshot := false
var _has_authoritative_relations := false
var _unlocked := false
var _facility_level := 0
var _capacity := 0
var _resolution_limit := 0
var _resolutions_used_today := 0
var _open_case_count := 0
var _open_cases: Array[Dictionary] = []
var _resolved_total := 0
var _denied_total := 0
var _settlement_spend_total_cents := 0
var _last_resolution: Dictionary = {}


func _ready() -> void:
	name = "FlockRelationsOfficeVisual"
	position = FACILITY_CENTER
	set_meta(&"facility_id", FACILITY_ID)
	set_meta(&"visual_only", true)
	set_meta(&"collision_free", true)
	set_meta(&"navigation_free", true)
	set_meta(&"declared_footprint", FOOTPRINT)
	set_meta(&"entrance_bridge_footprint", ENTRANCE_BRIDGE_FOOTPRINT)
	set_meta(&"clear_aisle_footprint", CLEAR_AISLE_FOOTPRINT)
	set_meta(&"maximum_visual_height", MAX_OPAQUE_HEIGHT)
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
	return MAX_OPAQUE_HEIGHT


func focus_point_global() -> Vector3:
	return to_global(Vector3(0.0, FOCUS_POINT.y, 0.0))


func build() -> void:
	clear()
	_built = true
	position = FACILITY_CENTER
	_build_governance_foundation()
	_build_entrance_bridge()
	_build_locked_marker()
	_build_survey_site()
	_build_owned_room()
	_apply_visibility()
	_apply_dynamic_state()
	EnvironmentalSignageScript.set_camera_detail(self, false, FOCUS_POINT, 2.75, false)


func clear() -> void:
	for visual_root in [
		governance_foundation_root,
		entrance_bridge_root,
		locked_marker_root,
		survey_site_root,
		owned_room_root,
	]:
		if visual_root != null and is_instance_valid(visual_root):
			visual_root.free()
	governance_foundation_root = null
	entrance_bridge_root = null
	locked_marker_root = null
	survey_site_root = null
	owned_room_root = null
	level_1_root = null
	level_2_root = null
	level_3_root = null
	_case_console_label = null
	_case_folder_root = null
	_case_folders.clear()
	_resolution_docket_root = null
	_resolution_dockets.clear()
	_outcome_lamps.clear()
	_material_cache.clear()
	_has_applied_snapshot = false
	_has_authoritative_relations = false
	_unlocked = false
	_facility_level = 0
	_capacity = 0
	_resolution_limit = 0
	_resolutions_used_today = 0
	_open_case_count = 0
	_open_cases.clear()
	_resolved_total = 0
	_denied_total = 0
	_settlement_spend_total_cents = 0
	_last_resolution.clear()
	_built = false


func apply_snapshot(snapshot: Dictionary) -> void:
	if not _built:
		build()
	var previous_level := _facility_level
	var catalog_entry := _catalog_entry(snapshot)
	var relations_variant: Variant = snapshot.get("flock_relations", {})
	var relations := _dictionary(relations_variant)
	var operations := _dictionary(snapshot.get("operations", {}))
	_has_authoritative_relations = relations_variant is Dictionary and snapshot.has("flock_relations")
	_facility_level = clampi(
		_snapshot_facility_level(snapshot, relations, operations, catalog_entry),
		0,
		MAX_LEVEL,
	)
	_unlocked = (
		_facility_level > 0
		or bool(catalog_entry.get(
			"unlocked",
			catalog_entry.get("available", catalog_entry.get("can_purchase", false)),
		))
	)
	_capacity = maxi(0, int(relations.get("capacity", 0)))
	_resolution_limit = maxi(0, int(relations.get("resolution_limit", 0)))
	_resolutions_used_today = clampi(
		int(relations.get("resolutions_used_today", 0)),
		0,
		_resolution_limit,
	)
	_open_case_count = maxi(0, int(relations.get("open_case_count", 0)))
	_resolved_total = maxi(0, int(relations.get("resolved_total", 0)))
	_denied_total = maxi(0, int(relations.get("denied_total", 0)))
	_settlement_spend_total_cents = maxi(
		0,
		int(relations.get("settlement_spend_total_cents", 0)),
	)
	_read_open_cases(relations)
	_last_resolution = _dictionary(relations.get("last_resolution", {})).duplicate(true)

	_apply_visibility()
	_rebuild_case_folders()
	_rebuild_resolution_docket()
	_apply_dynamic_state()
	if _has_applied_snapshot and _facility_level > previous_level and is_inside_tree():
		_animate_reveal()
	_has_applied_snapshot = true


func set_camera_detail(
	focused: bool,
	focus_position: Vector3 = Vector3(INF, INF, INF),
) -> void:
	EnvironmentalSignageScript.set_camera_detail(self, focused, focus_position, 2.75)


func visual_state() -> StringName:
	if _facility_level > 0:
		return StringName("level_%d" % _facility_level)
	return &"survey" if _unlocked else &"locked"


func current_level() -> int:
	return _facility_level


func facility_level() -> int:
	return _facility_level


func level_visible(level: int) -> bool:
	var level_root := _level_root(level)
	return level_root != null and level_root.visible


func locked_marker_visible() -> bool:
	return locked_marker_root != null and locked_marker_root.visible


func survey_site_visible() -> bool:
	return survey_site_root != null and survey_site_root.visible


func owned_room_visible() -> bool:
	return owned_room_root != null and owned_room_root.visible


func pigeonhole_count() -> int:
	return MAX_VISIBLE_CASES


func waiting_perch_count() -> int:
	return 2


func visible_case_folder_count() -> int:
	return _case_folders.size() if _facility_level >= 1 else 0


func open_case_ids() -> Array[int]:
	var result: Array[int] = []
	if _facility_level < 1:
		return result
	for folder in _case_folders:
		result.append(int(folder.get_meta(&"case_id", -1)))
	return result


func open_case_worker_ids() -> Array[int]:
	var result: Array[int] = []
	if _facility_level < 1:
		return result
	for folder in _case_folders:
		result.append(int(folder.get_meta(&"worker_id", -1)))
	return result


func resolution_docket_visible() -> bool:
	return _facility_level >= 3 and not _resolution_dockets.is_empty()


func last_resolution_id() -> StringName:
	return _resolution_id(_last_resolution)


func illuminated_outcome() -> StringName:
	if not _has_valid_last_resolution():
		return &""
	return _outcome_tone(last_resolution_id())


func relations_status_text() -> String:
	return _case_console_label.text if _case_console_label != null else ""


func has_authoritative_relations() -> bool:
	return _has_authoritative_relations


func geometry_bounds_inside_footprint() -> bool:
	var local_half := FOOTPRINT.size * 0.5
	var tolerance := 0.012
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null or _is_connector_geometry(instance):
			continue
		for local_corner in _mesh_corners_in_visual_space(instance):
			if (
				absf(local_corner.x) > local_half.x + tolerance
				or absf(local_corner.z) > local_half.y + tolerance
				or local_corner.y > MAX_OPAQUE_HEIGHT + tolerance
			):
				return false
	return true


func connector_geometry_inside_bridge() -> bool:
	var found_connector := false
	var tolerance := 0.012
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null or not _is_connector_geometry(instance):
			continue
		found_connector = true
		for local_corner in _mesh_corners_in_visual_space(instance):
			var world_xz := Vector2(
				local_corner.x + FACILITY_CENTER.x,
				local_corner.z + FACILITY_CENTER.z,
			)
			if (
				world_xz.x < ENTRANCE_BRIDGE_FOOTPRINT.position.x - tolerance
				or world_xz.x > ENTRANCE_BRIDGE_FOOTPRINT.end.x + tolerance
				or world_xz.y < ENTRANCE_BRIDGE_FOOTPRINT.position.y - tolerance
				or world_xz.y > ENTRANCE_BRIDGE_FOOTPRINT.end.y + tolerance
			):
				return false
	return found_connector


func circulation_clear() -> bool:
	var aisle_local := Rect2(
		CLEAR_AISLE_FOOTPRINT.position - Vector2(FACILITY_CENTER.x, FACILITY_CENTER.z),
		CLEAR_AISLE_FOOTPRINT.size,
	)
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null:
			continue
		var local_bounds := _mesh_bounds_in_visual_space(instance)
		if local_bounds.end.y <= 0.08 or local_bounds.position.y >= 2.45:
			continue
		var xz_bounds := Rect2(
			Vector2(local_bounds.position.x, local_bounds.position.z),
			Vector2(local_bounds.size.x, local_bounds.size.z),
		)
		if xz_bounds.intersects(aisle_local):
			return false
	return true


func geometry_bounds_global() -> AABB:
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	var found_geometry := false
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null:
			continue
		var bounds := instance.mesh.get_aabb()
		var bounds_end := bounds.end
		for corner_x in [bounds.position.x, bounds_end.x]:
			for corner_y in [bounds.position.y, bounds_end.y]:
				for corner_z in [bounds.position.z, bounds_end.z]:
					var world_corner := instance.to_global(Vector3(corner_x, corner_y, corner_z))
					minimum = minimum.min(world_corner)
					maximum = maximum.max(world_corner)
					found_geometry = true
	return AABB(minimum, maximum - minimum) if found_geometry else AABB()


func debug_state() -> Dictionary:
	return {
		"facility_id": FACILITY_ID,
		"state": visual_state(),
		"level": _facility_level,
		"unlocked": _unlocked,
		"capacity": _capacity,
		"resolution_limit": _resolution_limit,
		"resolutions_used_today": _resolutions_used_today,
		"open_case_count": _open_case_count,
		"open_case_ids": open_case_ids(),
		"open_case_worker_ids": open_case_worker_ids(),
		"resolved_total": _resolved_total,
		"denied_total": _denied_total,
		"settlement_spend_total_cents": _settlement_spend_total_cents,
		"last_resolution_id": last_resolution_id(),
		"illuminated_outcome": illuminated_outcome(),
		"footprint": FOOTPRINT,
		"entrance_bridge_footprint": ENTRANCE_BRIDGE_FOOTPRINT,
		"clear_aisle_footprint": CLEAR_AISLE_FOOTPRINT,
		"focus_point": FOCUS_POINT,
	}


func _build_governance_foundation() -> void:
	governance_foundation_root = Node3D.new()
	governance_foundation_root.name = "FlockRelationsGovernanceFoundation"
	governance_foundation_root.set_meta(&"visual_only", true)
	governance_foundation_root.set_meta(&"collision_free", true)
	governance_foundation_root.set_meta(&"navigation_free", true)
	add_child(governance_foundation_root)
	_add_box(
		governance_foundation_root,
		"GovernanceCampusFoundationSlab",
		Vector3(6.40, 0.12, 5.80),
		Vector3(0.0, -0.10, 0.0),
		INK_CHARCOAL.darkened(0.05),
		0.94,
	)
	_add_box(
		governance_foundation_root,
		"GovernanceCampusFoundationBrassEdge",
		Vector3(6.18, 0.025, 0.055),
		Vector3(0.0, -0.025, 2.83),
		OXIDIZED_BRASS,
		0.48,
		0.32,
	)


func _build_entrance_bridge() -> void:
	entrance_bridge_root = Node3D.new()
	entrance_bridge_root.name = "FlockRelationsEntranceBridge"
	entrance_bridge_root.set_meta(&"visual_only", true)
	entrance_bridge_root.set_meta(&"collision_free", true)
	entrance_bridge_root.set_meta(&"navigation_free", true)
	entrance_bridge_root.set_meta(&"campus_connector", true)
	entrance_bridge_root.set_meta(&"declared_footprint", ENTRANCE_BRIDGE_FOOTPRINT)
	add_child(entrance_bridge_root)
	_add_box(
		entrance_bridge_root,
		"GovernanceCampusDoorBridge",
		Vector3(0.25, 0.10, 1.20),
		Vector3(3.325, -0.055, 0.0),
		WARM_GRAY.darkened(0.08),
		0.92,
	)
	for threshold_z in [-0.54, 0.54]:
		_add_box(
			entrance_bridge_root,
			"GovernanceCampusBridgeBrassInlay",
			Vector3(0.22, 0.018, 0.035),
			Vector3(3.325, 0.005, threshold_z),
			OXIDIZED_BRASS,
			0.48,
			0.32,
		)


func _build_locked_marker() -> void:
	locked_marker_root = Node3D.new()
	locked_marker_root.name = "FlockRelationsLockedParcel"
	locked_marker_root.set_meta(&"facility_state", &"locked")
	add_child(locked_marker_root)
	_add_box(
		locked_marker_root,
		"FlockRelationsLockedGround",
		Vector3(6.34, 0.035, 5.74),
		Vector3(0.0, -0.018, 0.0),
		DEEP_MULBERRY.darkened(0.14),
		0.96,
	)
	for corner in [
		Vector3(-2.88, 0.34, -2.46),
		Vector3(2.88, 0.34, -2.46),
		Vector3(-2.88, 0.34, 2.46),
		Vector3(2.88, 0.34, 2.46),
	]:
		_add_box(
			locked_marker_root,
			"FlockRelationsParcelStake",
			Vector3(0.09, 0.68, 0.09),
			corner,
			MULBERRY,
			0.78,
		)
	var notice_host := _add_box(
		locked_marker_root,
		"FlockRelationsParcelReviewHost",
		Vector3(3.38, 0.72, 0.11),
		Vector3(-0.50, 0.86, 2.45),
		DEEP_MULBERRY,
		0.80,
	)
	EnvironmentalSignageScript.add_panel(
		notice_host,
		"FlockRelationsLockedNotice",
		"FLOCK RELATIONS PARCEL\nCASE REVIEW",
		Vector3(0.0, 0.0, 0.064),
		Vector2(3.08, 0.50),
		DEEP_MULBERRY,
		PAPER_CREAM,
		Vector3.ZERO,
		14,
		0.0028,
		&"secondary",
		&"machine",
	)


func _build_survey_site() -> void:
	survey_site_root = Node3D.new()
	survey_site_root.name = "FlockRelationsSurveySite"
	survey_site_root.set_meta(&"facility_state", &"survey")
	add_child(survey_site_root)
	_add_box(
		survey_site_root,
		"FlockRelationsSurveyFoundation",
		Vector3(6.34, 0.055, 5.74),
		Vector3(0.0, -0.008, 0.0),
		WARM_GRAY.darkened(0.12),
		0.94,
	)
	for line_z in [-2.38, 0.0, 2.38]:
		_add_box(
			survey_site_root,
			"FlockRelationsSurveyLine",
			Vector3(5.72, 0.016, 0.035),
			Vector3(-0.18, 0.028, line_z),
			OXIDIZED_BRASS,
			0.52,
			0.24,
		)
	for cap_index in 3:
		_add_cylinder(
			survey_site_root,
			"RelationsUtilityCap_%02d" % (cap_index + 1),
			Vector3(2.48, 0.065, -1.70 + cap_index * 0.35),
			0.13,
			0.09,
			MULBERRY if cap_index != 1 else OXIDIZED_BRASS,
			0.58,
			0.18,
		)
	var survey_host := _add_box(
		survey_site_root,
		"FlockRelationsSurveyNoticeHost",
		Vector3(3.52, 0.78, 0.11),
		Vector3(-0.45, 0.92, 2.45),
		MULBERRY,
		0.82,
	)
	EnvironmentalSignageScript.add_panel(
		survey_host,
		"FlockRelationsSurveyNotice",
		"CASE INTAKE PARCEL\nFLOCK FILE PENDING",
		Vector3(0.0, 0.0, 0.064),
		Vector2(3.20, 0.54),
		MULBERRY,
		PAPER_CREAM,
		Vector3.ZERO,
		14,
		0.0028,
		&"secondary",
		&"machine",
	)


func _build_owned_room() -> void:
	owned_room_root = Node3D.new()
	owned_room_root.name = "FlockRelationsOwnedRoom"
	owned_room_root.set_meta(&"facility_state", &"owned")
	add_child(owned_room_root)
	_build_room_shell(owned_room_root)
	level_1_root = Node3D.new()
	level_1_root.name = "FlockRelationsLevel1"
	level_1_root.set_meta(&"required_level", 1)
	owned_room_root.add_child(level_1_root)
	_build_level_1(level_1_root)
	level_2_root = Node3D.new()
	level_2_root.name = "FlockRelationsLevel2"
	level_2_root.set_meta(&"required_level", 2)
	owned_room_root.add_child(level_2_root)
	_build_level_2(level_2_root)
	level_3_root = Node3D.new()
	level_3_root.name = "FlockRelationsLevel3"
	level_3_root.set_meta(&"required_level", 3)
	owned_room_root.add_child(level_3_root)
	_build_level_3(level_3_root)


func _build_room_shell(parent: Node3D) -> void:
	_add_box(
		parent,
		"FlockRelationsFloor",
		Vector3(6.30, 0.06, 5.70),
		Vector3(0.0, -0.005, 0.0),
		OATMEAL.darkened(0.06),
		0.94,
	)
	_add_box(
		parent,
		"FlockRelationsSouthWall",
		Vector3(6.10, 2.90, 0.12),
		Vector3(0.0, 1.45, -2.70),
		MULBERRY.darkened(0.04),
		0.84,
	)
	_add_box(
		parent,
		"FlockRelationsWestWall",
		Vector3(0.12, 2.90, 5.28),
		Vector3(-3.05, 1.45, -0.06),
		MULBERRY,
		0.84,
	)
	# The east wall is split around the exact 1.20m doorway to the governance spine.
	for doorway_index in 2:
		var doorway_side := -1.0 if doorway_index == 0 else 1.0
		_add_box(
			parent,
			"FlockRelationsEastWallSegment_%02d" % (doorway_index + 1),
			Vector3(0.12, 2.90, 2.08),
			Vector3(3.05, 1.45, doorway_side * 1.65),
			MULBERRY.darkened(0.02),
			0.84,
		)
		_add_box(
			parent,
			"FlockRelationsEastDoorJamb_%02d" % (doorway_index + 1),
			Vector3(0.16, 2.42, 0.10),
			Vector3(3.00, 1.21, doorway_side * 0.66),
			OXIDIZED_BRASS.darkened(0.10),
			0.50,
			0.28,
		)
	_add_box(
		parent,
		"FlockRelationsEastDoorHeader",
		Vector3(0.16, 0.16, EAST_DOOR_WIDTH + 0.20),
		Vector3(3.00, 2.58, 0.0),
		OXIDIZED_BRASS.darkened(0.10),
		0.50,
		0.28,
	)
	_add_box(
		parent,
		"FlockRelationsNorthCutawayDado",
		Vector3(6.10, 0.46, 0.12),
		Vector3(0.0, 0.23, 2.70),
		FELT_PLUM,
		0.86,
	)
	for post_x in [-3.05, 3.05]:
		_add_box(
			parent,
			"FlockRelationsNorthCutawayPost",
			Vector3(0.12, 2.90, 0.12),
			Vector3(post_x, 1.45, 2.70),
			DEEP_MULBERRY,
			0.74,
		)
	for panel_x in [-2.35, 2.35]:
		_add_glass_box(
			parent,
			"FlockRelationsCutawayGlassWing",
			Vector3(1.18, 1.48, 0.035),
			Vector3(panel_x, 1.22, 2.63),
		)
	# A shallow glazed clerestory breaks the repeated flat pergola silhouette.
	_add_box(
		parent,
		"FlockRelationsClerestoryRidge",
		Vector3(0.10, 0.10, 4.30),
		Vector3(0.0, 3.42, -0.10),
		OXIDIZED_BRASS.darkened(0.22),
		0.48,
		0.28,
	)
	# The low-opacity panes make the rafters read as one glazed roof instead of
	# disconnected overhead bars while preserving the open management view.
	var west_clerestory_glass := _add_box(
		parent,
		"FlockRelationsClerestoryGlassWest",
		Vector3(2.28, 0.035, 4.26),
		Vector3(-1.14, 3.14, -0.10),
		CLERESTORY_GLASS,
		0.18,
		0.02,
	)
	west_clerestory_glass.rotation_degrees.z = 14.0
	west_clerestory_glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var east_clerestory_glass := _add_box(
		parent,
		"FlockRelationsClerestoryGlassEast",
		Vector3(2.28, 0.035, 4.26),
		Vector3(1.14, 3.14, -0.10),
		CLERESTORY_GLASS,
		0.18,
		0.02,
	)
	east_clerestory_glass.rotation_degrees.z = -14.0
	east_clerestory_glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for rafter_z in [-1.82, 0.0, 1.82]:
		var west_rafter := _add_box(
			parent,
			"FlockRelationsClerestoryRafterWest",
			Vector3(2.36, 0.10, 0.10),
			Vector3(-1.16, 3.14, rafter_z),
			OXIDIZED_BRASS.darkened(0.22),
			0.48,
			0.28,
		)
		west_rafter.rotation_degrees.z = 14.0
		var east_rafter := _add_box(
			parent,
			"FlockRelationsClerestoryRafterEast",
			Vector3(2.36, 0.10, 0.10),
			Vector3(1.16, 3.14, rafter_z),
			OXIDIZED_BRASS.darkened(0.22),
			0.48,
			0.28,
		)
		east_rafter.rotation_degrees.z = -14.0
	# A smoked-glass transom now spans the frontage above the two glazed wings.
	# Full-width rails terminate at the cutaway posts, making the identity a
	# permanent privacy-glass band instead of a board suspended from the roof.
	_add_box(
		parent,
		"FlockRelationsIdentityGlassBandBottomRail",
		Vector3(5.90, 0.10, 0.14),
		Vector3(0.0, 2.00, 2.64),
		OXIDIZED_BRASS.darkened(0.10),
		0.50,
		0.28,
	)
	_add_box(
		parent,
		"FlockRelationsIdentityGlassBandTopRail",
		Vector3(5.90, 0.10, 0.14),
		Vector3(0.0, 2.54, 2.64),
		OXIDIZED_BRASS.darkened(0.10),
		0.50,
		0.28,
	)
	for mullion_index in 2:
		var mullion_x: float = -2.41 if mullion_index == 0 else 2.41
		_add_box(
			parent,
			"FlockRelationsIdentityGlassBandMullion_%02d" % (mullion_index + 1),
			Vector3(0.10, 0.54, 0.14),
			Vector3(mullion_x, 2.27, 2.64),
			OXIDIZED_BRASS.darkened(0.10),
			0.50,
			0.28,
		)
	var identity_host := _add_glass_box(
		parent,
		"FlockRelationsIdentityHost",
		Vector3(4.78, 0.46, 0.045),
		Vector3(0.0, 2.27, 2.635),
	)
	identity_host.set_meta(&"architectural_mount", &"glazed_transom_band")
	identity_host.set_meta(&"glass_identity_band", true)
	EnvironmentalSignageScript.add_panel(
		identity_host,
		"FlockRelationsIdentity",
		"FLOCK RELATIONS\nGRIEVANCE & COMPLIANCE",
		Vector3(0.0, 0.0, 0.030),
		Vector2(4.46, 0.38),
		DEEP_MULBERRY,
		PAPER_CREAM,
		Vector3.ZERO,
		14,
		0.0028,
		&"primary",
		&"destination",
	)


func _build_level_1(parent: Node3D) -> void:
	_add_box(
		parent,
		"OpenNestIntakeCounterBase",
		Vector3(1.72, 0.82, 0.68),
		Vector3(-1.66, 0.41, 1.28),
		MULBERRY.darkened(0.06),
		0.80,
	)
	_add_box(
		parent,
		"OpenNestIntakeCounterTop",
		Vector3(1.94, 0.11, 0.82),
		Vector3(-1.66, 0.87, 1.28),
		OATMEAL,
		0.92,
	)
	var intake_plate_host := _add_box(
		parent,
		"OpenNestIntakePlateHost",
		Vector3(1.48, 0.25, 0.055),
		Vector3(-1.66, 0.62, 1.635),
		DEEP_MULBERRY,
		0.78,
	)
	EnvironmentalSignageScript.add_panel(
		intake_plate_host,
		"OpenNestCaseIntakePlate",
		"OPEN-NEST CASE INTAKE",
		Vector3(0.0, 0.0, 0.035),
		Vector2(1.34, 0.17),
		DEEP_MULBERRY,
		PAPER_CREAM,
		Vector3.ZERO,
		10,
		0.0020,
		&"utility",
		&"machine",
	)
	for perch_index in 2:
		var perch_x := -2.34 + perch_index * 1.08
		_add_oval_cylinder(
			parent,
			"OpenNestWaitingPerch_%02d" % (perch_index + 1),
			Vector3(perch_x, 0.48, -0.55 - perch_index * 0.32),
			0.42,
			0.13,
			Vector3(1.15, 1.0, 0.78),
			FELT_PLUM,
			0.92,
		)
		_add_cylinder(
			parent,
			"OpenNestWaitingPerchStem_%02d" % (perch_index + 1),
			Vector3(perch_x, 0.24, -0.55 - perch_index * 0.32),
			0.075,
			0.42,
			OXIDIZED_BRASS.darkened(0.18),
			0.52,
			0.28,
		)
	# Six empty pigeonholes are furniture; folders are rebuilt only from open_cases.
	for slot_index in MAX_VISIBLE_CASES:
		var slot_x := -2.22 + (slot_index % 3) * 0.54
		var slot_y := 1.42 + int(slot_index / 3) * 0.46
		_add_box(
			parent,
			"OpenCasePigeonhole_%02d" % (slot_index + 1),
			Vector3(0.48, 0.36, 0.12),
			Vector3(slot_x, slot_y, -2.55),
			INK_CHARCOAL.lightened(0.10),
			0.76,
		)
		_add_box(
			parent,
			"OpenCasePigeonholeLip_%02d" % (slot_index + 1),
			Vector3(0.46, 0.045, 0.16),
			Vector3(slot_x, slot_y - 0.18, -2.47),
			OXIDIZED_BRASS.darkened(0.12),
			0.50,
			0.22,
		)
	_case_folder_root = Node3D.new()
	_case_folder_root.name = "AuthoritativeOpenCaseFolders"
	parent.add_child(_case_folder_root)
	var console_host := _add_box(
		parent,
		"FlockRelationsCaseConsoleHost",
		Vector3(2.24, 0.76, 0.10),
		Vector3(1.52, 1.58, -2.58),
		INK_CHARCOAL,
		0.56,
	)
	_case_console_label = EnvironmentalSignageScript.add_panel(
		console_host,
		"FlockRelationsLiveCaseConsole",
		"CASE INTAKE / AWAITING FILE",
		Vector3(0.0, 0.0, 0.057),
		Vector2(2.06, 0.60),
		INK_CHARCOAL,
		SCREEN_BLUE.lightened(0.18),
		Vector3.ZERO,
		11,
		0.0022,
		&"utility",
		&"screen",
		true,
	)
	var ticket_post := _add_box(
		parent,
		"CaseTicketWheelPost",
		Vector3(0.14, 1.34, 0.14),
		Vector3(0.12, 0.67, 1.90),
		MULBERRY,
		0.78,
	)
	var ticket_wheel := _add_cylinder(
		parent,
		"CaseTicketWheel",
		Vector3(0.12, 1.26, 1.90),
		0.33,
		0.13,
		OXIDIZED_BRASS,
		0.48,
		0.30,
	)
	ticket_wheel.rotation_degrees.x = 90.0
	_add_cylinder(
		ticket_wheel,
		"CaseTicketWheelHub",
		Vector3.ZERO,
		0.10,
		0.16,
		DEEP_MULBERRY,
		0.64,
	)
	# Keep a named reference to the support so audits can prove the wheel is hosted.
	ticket_post.set_meta(&"supports", &"CaseTicketWheel")


func _build_level_2(parent: Node3D) -> void:
	_add_oval_cylinder(
		parent,
		"MediationFeltTableTop",
		Vector3(-1.10, 0.78, 0.02),
		0.92,
		0.14,
		Vector3(1.22, 1.0, 0.72),
		FELT_PLUM,
		0.94,
	)
	_add_oval_cylinder(
		parent,
		"MediationFeltTableApron",
		Vector3(-1.10, 0.70, 0.02),
		0.82,
		0.20,
		Vector3(1.22, 1.0, 0.72),
		DEEP_MULBERRY,
		0.82,
	)
	_add_cylinder(
		parent,
		"MediationTablePedestal",
		Vector3(-1.10, 0.38, 0.02),
		0.17,
		0.62,
		OXIDIZED_BRASS.darkened(0.20),
		0.52,
		0.28,
	)
	var perch_specs := [
		{"name": "MediationHenPerch_01", "position": Vector3(-2.02, 0.48, 0.62), "color": DUSTY_LILAC},
		{"name": "MediationHenPerch_02", "position": Vector3(-2.02, 0.48, -0.58), "color": DUSTY_LILAC},
		{"name": "MediationManagementPerch", "position": Vector3(0.02, 0.52, 0.02), "color": MULBERRY},
	]
	for spec_variant in perch_specs:
		var spec := spec_variant as Dictionary
		var perch_position := spec.get("position", Vector3.ZERO) as Vector3
		_add_oval_cylinder(
			parent,
			String(spec.get("name", "MediationPerch")),
			perch_position,
			0.38,
			0.13,
			Vector3(1.08, 1.0, 0.80),
			spec.get("color", DUSTY_LILAC) as Color,
			0.92,
		)
		_add_cylinder(
			parent,
			"%sStem" % String(spec.get("name", "MediationPerch")),
			perch_position - Vector3(0.0, 0.25, 0.0),
			0.07,
			0.42,
			OXIDIZED_BRASS.darkened(0.18),
			0.52,
			0.28,
		)
	# Five faceted panes create a soft privacy arc without runtime CSG.
	for panel_index in 5:
		var angle := deg_to_rad(122.0 + panel_index * 29.0)
		var panel_position := Vector3(
			-1.10 + cos(angle) * 1.56,
			1.42,
			sin(angle) * 1.18,
		)
		var panel := _add_glass_box(
			parent,
			"MediationPrivacyPane_%02d" % (panel_index + 1),
			Vector3(0.52, 1.38, 0.035),
			panel_position,
		)
		panel.rotation_degrees.y = 212.0 + panel_index * 29.0
	var stamp_base := _add_box(
		parent,
		"MediationPIPStampStation",
		Vector3(1.28, 0.68, 0.54),
		Vector3(-2.20, 0.34, 1.72),
		WARM_GRAY.darkened(0.08),
		0.84,
	)
	for stamp_index in 2:
		var stamp_x := -2.48 + stamp_index * 0.56
		_add_cylinder(
			parent,
			"RemedyStamp" if stamp_index == 0 else "PIPStamp",
			Vector3(stamp_x, 0.83, 1.72),
			0.10,
			0.34,
			STATUS_GREEN if stamp_index == 0 else STATUS_AMBER,
			0.66,
		)
		_add_box(
			parent,
			"RemedyStampPad" if stamp_index == 0 else "PIPStampPad",
			Vector3(0.34, 0.05, 0.30),
			Vector3(stamp_x, 0.70, 1.72),
			DEEP_MULBERRY,
			0.80,
		)
	var stamp_plate_host := _add_box(
		stamp_base,
		"MediationPIPPlateHost",
		Vector3(1.10, 0.18, 0.035),
		Vector3(0.0, 0.16, 0.288),
		MULBERRY,
		0.78,
	)
	EnvironmentalSignageScript.add_panel(
		stamp_plate_host,
		"MediationPIPRoomPlate",
		"MEDIATION & PIP ROOM",
		Vector3(0.0, 0.0, 0.025),
		Vector2(1.00, 0.12),
		MULBERRY,
		PAPER_CREAM,
		Vector3.ZERO,
		9,
		0.0018,
		&"utility",
		&"machine",
	)


func _build_level_3(parent: Node3D) -> void:
	_add_box(
		parent,
		"MandatoryArbitrationBenchBase",
		Vector3(2.48, 0.82, 0.62),
		Vector3(-0.95, 0.59, -1.86),
		DEEP_MULBERRY,
		0.80,
	)
	_add_box(
		parent,
		"MandatoryArbitrationBenchTop",
		Vector3(2.72, 0.14, 0.78),
		Vector3(-0.95, 1.05, -1.86),
		OATMEAL.darkened(0.04),
		0.90,
	)
	var tribunal_plate_host := _add_box(
		parent,
		"MandatoryArbitrationPlateHost",
		Vector3(2.12, 0.27, 0.055),
		Vector3(-0.95, 0.76, -1.525),
		DEEP_MULBERRY,
		0.76,
	)
	EnvironmentalSignageScript.add_panel(
		tribunal_plate_host,
		"MandatoryArbitrationRoostPlate",
		"MANDATORY ARBITRATION ROOST",
		Vector3(0.0, 0.0, 0.035),
		Vector2(1.96, 0.17),
		DEEP_MULBERRY,
		PAPER_CREAM,
		Vector3.ZERO,
		10,
		0.0020,
		&"utility",
		&"machine",
	)
	_add_box(
		parent,
		"PrecedentVaultCabinet",
		Vector3(0.96, 2.08, 0.62),
		Vector3(2.38, 1.04, -1.72),
		INK_CHARCOAL.lightened(0.08),
		0.72,
	)
	for drawer_index in 5:
		_add_box(
			parent,
			"PrecedentVaultDrawer_%02d" % (drawer_index + 1),
			Vector3(0.78, 0.27, 0.055),
			Vector3(2.38, 0.32 + drawer_index * 0.35, -1.38),
			WARM_GRAY.darkened(0.12),
			0.78,
		)
		_add_box(
			parent,
			"PrecedentVaultHandle_%02d" % (drawer_index + 1),
			Vector3(0.22, 0.045, 0.035),
			Vector3(2.38, 0.32 + drawer_index * 0.35, -1.34),
			OXIDIZED_BRASS,
			0.46,
			0.30,
		)
	_add_box(
		parent,
		"ComplianceSealPressBase",
		Vector3(0.96, 0.72, 0.72),
		Vector3(1.83, 0.36, 1.72),
		MULBERRY.darkened(0.02),
		0.78,
	)
	_add_box(
		parent,
		"ComplianceSealPressArm",
		Vector3(0.14, 0.92, 0.14),
		Vector3(1.83, 1.08, 1.72),
		OXIDIZED_BRASS.darkened(0.14),
		0.48,
		0.30,
	)
	_add_cylinder(
		parent,
		"ComplianceSealDie",
		Vector3(1.83, 0.83, 1.72),
		0.24,
		0.12,
		OXIDIZED_BRASS,
		0.44,
		0.32,
	)
	_add_box(
		parent,
		"EmptySettlementTray",
		Vector3(1.32, 0.08, 0.76),
		Vector3(1.73, 0.79, 0.98),
		INK_CHARCOAL,
		0.76,
	)
	_resolution_docket_root = Node3D.new()
	_resolution_docket_root.name = "AuthoritativeSettlementDocketRoot"
	_resolution_docket_root.position = Vector3(1.73, 0.86, 0.98)
	parent.add_child(_resolution_docket_root)
	var outcome_host := _add_box(
		parent,
		"ArbitrationOutcomeLampRail",
		Vector3(1.56, 0.38, 0.08),
		Vector3(0.80, 2.25, -2.57),
		INK_CHARCOAL,
		0.60,
	)
	var tones: Array[StringName] = [&"remedy", &"pip", &"denied"]
	var colors := [STATUS_GREEN, STATUS_AMBER, STATUS_RED]
	for tone_index in tones.size():
		var lamp := _add_box(
			outcome_host,
			"ArbitrationOutcomeLamp_%s" % String(tones[tone_index]).to_pascal_case(),
			Vector3(0.30, 0.16, 0.035),
			Vector3(-0.48 + tone_index * 0.48, 0.0, 0.058),
			INK_CHARCOAL.darkened(0.10),
			0.62,
		)
		lamp.set_meta(&"outcome_tone", tones[tone_index])
		lamp.set_meta(&"active_color", colors[tone_index])
		_outcome_lamps[tones[tone_index]] = lamp


func _apply_visibility() -> void:
	if locked_marker_root != null:
		locked_marker_root.visible = not _unlocked and _facility_level <= 0
	if survey_site_root != null:
		survey_site_root.visible = _unlocked and _facility_level <= 0
	if owned_room_root != null:
		owned_room_root.visible = _facility_level >= 1
	if level_1_root != null:
		level_1_root.visible = _facility_level >= 1
	if level_2_root != null:
		level_2_root.visible = _facility_level >= 2
	if level_3_root != null:
		level_3_root.visible = _facility_level >= 3


func _apply_dynamic_state() -> void:
	if _case_console_label != null:
		if _has_authoritative_relations:
			_case_console_label.text = (
				"OPEN %02d/%02d / REVIEW %d/%d\n"
				+ "RESOLVED %03d / DENIED %03d / SETTLED $%.2f"
			) % [
				_open_case_count,
				_capacity,
				_resolutions_used_today,
				_resolution_limit,
				_resolved_total,
				_denied_total,
				float(_settlement_spend_total_cents) / 100.0,
			]
		else:
			_case_console_label.text = "CASE INTAKE / AWAITING FILE"
		EnvironmentalSignageScript.refit_label(_case_console_label)
	var active_tone := illuminated_outcome()
	for tone in _outcome_lamps:
		var lamp := _outcome_lamps[tone]
		var active_color := lamp.get_meta(&"active_color", STATUS_AMBER) as Color
		lamp.material_override = (
			_emissive_material(active_color, 0.72)
			if tone == active_tone
			else _material(INK_CHARCOAL.darkened(0.10), 0.62)
		)


func _read_open_cases(relations: Dictionary) -> void:
	_open_cases.clear()
	var cases_variant: Variant = relations.get("open_cases", [])
	if not (cases_variant is Array):
		return
	for case_variant in cases_variant as Array:
		if not (case_variant is Dictionary):
			continue
		var case_record := case_variant as Dictionary
		var case_id := int(case_record.get("case_id", -1))
		if case_id < 0:
			continue
		_open_cases.append(case_record.duplicate(true))
		if _open_cases.size() >= MAX_VISIBLE_CASES:
			break


func _rebuild_case_folders() -> void:
	_case_folders.clear()
	if _case_folder_root == null:
		return
	for child in _case_folder_root.get_children():
		child.free()
	if _facility_level < 1 or _capacity <= 0:
		return
	var visible_count := mini(_open_cases.size(), mini(_capacity, MAX_VISIBLE_CASES))
	for case_index in visible_count:
		var case_record := _open_cases[case_index]
		var folder := Node3D.new()
		folder.name = "AuthoritativeOpenCaseFolder_%02d" % (case_index + 1)
		folder.position = Vector3(
			-2.22 + (case_index % 3) * 0.54,
			1.42 + int(case_index / 3) * 0.46,
			-2.45,
		)
		folder.set_meta(&"authoritative_record", true)
		folder.set_meta(&"case_id", int(case_record.get("case_id", -1)))
		folder.set_meta(&"docket_id", String(case_record.get("docket_id", "")))
		folder.set_meta(&"worker_id", int(case_record.get("worker_id", -1)))
		folder.set_meta(&"case_type", StringName(String(case_record.get("case_type", ""))))
		folder.set_meta(&"title", String(case_record.get("title", "")))
		folder.set_meta(&"severity", maxi(0, int(case_record.get("severity", 0))))
		folder.set_meta(&"filed_day", maxi(0, int(case_record.get("filed_day", 0))))
		folder.set_meta(&"status", StringName(String(case_record.get("status", ""))))
		folder.set_meta(&"evidence_summary", String(case_record.get("evidence_summary", "")))
		_case_folder_root.add_child(folder)
		var severity := clampi(int(case_record.get("severity", 0)), 0, 3)
		var folder_color := [OATMEAL, DUSTY_LILAC, STATUS_AMBER, STATUS_RED][severity] as Color
		var host := _add_box(
			folder,
			"OpenCaseFolderHost",
			Vector3(0.42, 0.29, 0.045),
			Vector3.ZERO,
			folder_color.darkened(0.10),
			0.90,
		)
		var docket_id := String(case_record.get("docket_id", "CASE %03d" % int(case_record.get("case_id", 0)))).to_upper()
		var worker_name := String(case_record.get("worker_name", "FLOCK MEMBER")).to_upper()
		EnvironmentalSignageScript.add_panel(
			host,
			"OpenCaseFolderCopy_%02d" % (case_index + 1),
			"%s\n%s" % [docket_id, worker_name],
			Vector3(0.0, 0.0, 0.032),
			Vector2(0.36, 0.22),
			folder_color.darkened(0.10),
			DEEP_MULBERRY,
			Vector3.ZERO,
			8,
			0.0016,
			&"utility",
			&"machine",
		)
		_case_folders.append(folder)


func _rebuild_resolution_docket() -> void:
	_resolution_dockets.clear()
	if _resolution_docket_root == null:
		return
	for child in _resolution_docket_root.get_children():
		child.free()
	if _facility_level < 3 or not _has_valid_last_resolution():
		return
	var docket := Node3D.new()
	docket.name = "AuthoritativeSettlementDocket"
	docket.set_meta(&"authoritative_record", true)
	docket.set_meta(&"case_id", int(_last_resolution.get("case_id", -1)))
	docket.set_meta(&"resolution_id", _resolution_id(_last_resolution))
	docket.set_meta(&"source_record", _last_resolution.duplicate(true))
	_resolution_docket_root.add_child(docket)
	var host := _add_box(
		docket,
		"SettlementDocketHost",
		Vector3(1.14, 0.54, 0.05),
		Vector3.ZERO,
		PAPER_CREAM,
		0.94,
	)
	var resolution_name := String(_last_resolution.get(
		"resolution_name",
		_last_resolution.get(
			"action_label",
			_last_resolution.get("title", String(last_resolution_id()).replace("_", " ")),
		),
	)).to_upper()
	var settlement_cents := int(_last_resolution.get(
		"settlement_spend_cents",
		_last_resolution.get("spend_cents", _last_resolution.get("cost_cents", 0)),
	))
	EnvironmentalSignageScript.add_panel(
		host,
		"AuthoritativeSettlementDocketCopy",
		"CASE %03d / %s\nSETTLEMENT $%.2f" % [
			maxi(0, int(_last_resolution.get("case_id", 0))),
			resolution_name,
			float(maxi(0, settlement_cents)) / 100.0,
		],
		Vector3(0.0, 0.0, 0.032),
		Vector2(1.02, 0.42),
		PAPER_CREAM,
		DEEP_MULBERRY,
		Vector3.ZERO,
		9,
		0.0018,
		&"utility",
		&"machine",
	)
	_resolution_dockets.append(docket)


func _has_valid_last_resolution() -> bool:
	if _last_resolution.is_empty():
		return false
	return (
		int(_last_resolution.get("case_id", -1)) >= 0
		or _resolution_id(_last_resolution) != &""
	)


func _resolution_id(record: Dictionary) -> StringName:
	return StringName(String(record.get(
		"resolution_id",
		record.get("action_id", record.get("outcome_id", record.get("id", ""))),
	)))


func _outcome_tone(resolution_id: StringName) -> StringName:
	var normalized := String(resolution_id).to_lower()
	if "deny" in normalized or "denied" in normalized:
		return &"denied"
	if "pip" in normalized or "performance" in normalized:
		return &"pip"
	return &"remedy"


func _animate_reveal() -> void:
	var revealed := _level_root(_facility_level)
	if revealed == null:
		return
	revealed.scale = Vector3(0.92, 0.15, 0.92)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(revealed, "scale", Vector3.ONE, 0.42)


func _level_root(level: int) -> Node3D:
	match level:
		1:
			return level_1_root
		2:
			return level_2_root
		3:
			return level_3_root
	return null


func _snapshot_facility_level(
	snapshot: Dictionary,
	relations: Dictionary,
	operations: Dictionary,
	catalog_entry: Dictionary,
) -> int:
	if relations.has("level"):
		return _level_from_variant(relations.get("level", 0))
	if operations.has("flock_relations_office_level"):
		return _level_from_variant(operations.get("flock_relations_office_level", 0))
	var owned := _dictionary(snapshot.get("owned_facilities", {}))
	if owned.has(FACILITY_ID) or owned.has(String(FACILITY_ID)):
		return _level_from_variant(owned.get(FACILITY_ID, owned.get(String(FACILITY_ID), 0)))
	return _level_from_variant(catalog_entry.get("level", catalog_entry.get("owned", 0)))


func _catalog_entry(snapshot: Dictionary) -> Dictionary:
	var catalog_variant: Variant = snapshot.get("facility_catalog", [])
	if catalog_variant is Array:
		for entry_variant in catalog_variant as Array:
			if not (entry_variant is Dictionary):
				continue
			var entry := entry_variant as Dictionary
			if StringName(String(entry.get("id", ""))) == FACILITY_ID:
				return entry
	elif catalog_variant is Dictionary:
		var catalog := catalog_variant as Dictionary
		var entry_variant: Variant = catalog.get(FACILITY_ID, catalog.get(String(FACILITY_ID), {}))
		if entry_variant is Dictionary:
			return entry_variant as Dictionary
	return {}


func _level_from_variant(value: Variant) -> int:
	if value is bool:
		return 1 if bool(value) else 0
	if value is int or value is float:
		return int(value)
	if value is Dictionary:
		var source := value as Dictionary
		return int(source.get("level", source.get("owned", source.get("installed", 0))))
	return 0


func _dictionary(value: Variant) -> Dictionary:
	return value as Dictionary if value is Dictionary else {}


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
	var bounds_end := bounds.end
	for corner_x in [bounds.position.x, bounds_end.x]:
		for corner_y in [bounds.position.y, bounds_end.y]:
			for corner_z in [bounds.position.z, bounds_end.z]:
				result.append(to_local(instance.to_global(Vector3(corner_x, corner_y, corner_z))))
	return result


func _mesh_bounds_in_visual_space(instance: MeshInstance3D) -> AABB:
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	for corner in _mesh_corners_in_visual_space(instance):
		minimum = minimum.min(corner)
		maximum = maximum.max(corner)
	return AABB(minimum, maximum - minimum)


func _add_box(
	parent: Node3D,
	part_name: String,
	size: Vector3,
	part_position: Vector3,
	color: Color,
	roughness: float = 0.82,
	metallic: float = 0.0,
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color, roughness, metallic)
	parent.add_child(instance)
	return instance


func _add_cylinder(
	parent: Node3D,
	part_name: String,
	part_position: Vector3,
	radius: float,
	height: float,
	color: Color,
	roughness: float = 0.82,
	metallic: float = 0.0,
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color, roughness, metallic)
	parent.add_child(instance)
	return instance


func _add_oval_cylinder(
	parent: Node3D,
	part_name: String,
	part_position: Vector3,
	radius: float,
	height: float,
	part_scale: Vector3,
	color: Color,
	roughness: float = 0.82,
	metallic: float = 0.0,
) -> MeshInstance3D:
	var instance := _add_cylinder(
		parent,
		part_name,
		part_position,
		radius,
		height,
		color,
		roughness,
		metallic,
	)
	instance.scale = part_scale
	return instance


func _add_glass_box(
	parent: Node3D,
	part_name: String,
	size: Vector3,
	part_position: Vector3,
) -> MeshInstance3D:
	var glass := _add_box(parent, part_name, size, part_position, SMOKED_GLASS, 0.22, 0.02)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return glass


func _material(
	color: Color,
	roughness: float = 0.82,
	metallic: float = 0.0,
) -> StandardMaterial3D:
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
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	_material_cache[key] = material
	return material


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var key := "emissive|%s|%.3f" % [color.to_html(true), energy]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.36)
	material.roughness = 0.46
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.resource_local_to_scene = true
	_material_cache[key] = material
	return material
