class_name RoosterOperationsOfficeVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## Snapshot-driven, visual-only management facility on the east campus. The
## room never invents supervisors, assignments, directives, or economic effects:
## every live prop is rebuilt from the authoritative office snapshot.
const FACILITY_ID: StringName = &"rooster_operations_office"
const FACILITY_CENTER := Vector3(15.20, 0.0, 30.00)
const FOCUS_POINT := Vector3(15.20, 1.05, 30.00)
const FOOTPRINT := Rect2(Vector2(12.00, 27.10), Vector2(6.40, 5.80))
const MAX_LEVEL := 3
const MAX_OPAQUE_HEIGHT := 3.55
const MAX_ASSIGNMENT_TOKENS := 6
const QUEUE_PIPS_PER_LANE := 6

const LANE_ORDER: Array[StringName] = [&"nest_damage", &"predator_loss", &"appeals"]
const LANE_SHORT_NAMES := {
	&"nest_damage": "NEST",
	&"predator_loss": "PREDATOR",
	&"appeals": "APPEALS",
}
const LANE_COLORS := {
	&"nest_damage": Color("789477"),
	&"predator_loss": Color("aa6657"),
	&"appeals": Color("777e9b"),
	&"auto": Color("c4a35b"),
}

const DEEP_BURGUNDY := Color("4b2f32")
const BARN_RED := Color("76434a")
const DUSTY_ROSE := Color("9b6668")
const WALNUT := Color("6c4e39")
const DARK_WALNUT := Color("46362e")
const CREAM := Color("eee2c8")
const OATMEAL := Color("d1c3a4")
const BRASS := Color("c3a158")
const GRAPHITE := Color("30383a")
const SLATE := Color("58676a")
const SCREEN_AMBER := Color("d5ae5d")
const SCREEN_GREEN := Color("78a27a")
const GLASS := Color("9aa9a35c")

var locked_marker_root: Node3D
var survey_site_root: Node3D
var owned_room_root: Node3D
var level_1_root: Node3D
var level_2_root: Node3D
var level_3_root: Node3D

var _supervisor_stations: Array[Node3D] = []
var _queue_pips: Dictionary = {}
var _action_pips: Array[MeshInstance3D] = []
var _assignment_token_root: Node3D
var _assignment_tokens: Array[Node3D] = []
var _directive_card_root: Node3D
var _directive_cards: Array[Node3D] = []
var _supervision_label: Label3D
var _queue_label: Label3D
var _material_cache: Dictionary[String, StandardMaterial3D] = {}

var _built := false
var _has_applied_snapshot := false
var _unlocked := false
var _facility_level := 0
var _has_supervision_metrics := false
var _action_limit := 0
var _actions_used := 0
var _actions_remaining := 0
var _supervisor_payroll_cents := 0
var _grievance_millipoints := 0
var _stress_millipoints := 0
var _solidarity_millipoints := 0
var _quota_pressure_actions_today := 0
var _shift_pressure_applied := false
var _queue_counts: Dictionary = {}
var _assignment_records: Array[Dictionary] = []
var _active_directive: Dictionary = {}


func _ready() -> void:
	name = "RoosterOperationsOfficeVisual"
	position = FACILITY_CENTER
	set_meta(&"facility_id", FACILITY_ID)
	set_meta(&"visual_only", true)
	set_meta(&"collision_free", true)
	set_meta(&"navigation_free", true)
	set_meta(&"declared_footprint", FOOTPRINT)
	set_meta(&"maximum_visual_height", MAX_OPAQUE_HEIGHT)
	if not _built:
		build()


static func declared_footprint() -> Rect2:
	return FOOTPRINT


static func facility_footprint() -> Rect2:
	return FOOTPRINT


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
	_build_locked_marker()
	_build_survey_site()
	_build_owned_room()
	_apply_visibility()
	_apply_dynamic_state()
	EnvironmentalSignageScript.set_camera_detail(self, false, FOCUS_POINT, 2.75, false)


func clear() -> void:
	for visual_root in [locked_marker_root, survey_site_root, owned_room_root]:
		if visual_root != null and is_instance_valid(visual_root):
			visual_root.free()
	locked_marker_root = null
	survey_site_root = null
	owned_room_root = null
	level_1_root = null
	level_2_root = null
	level_3_root = null
	_supervisor_stations.clear()
	_queue_pips.clear()
	_action_pips.clear()
	_assignment_token_root = null
	_assignment_tokens.clear()
	_directive_card_root = null
	_directive_cards.clear()
	_supervision_label = null
	_queue_label = null
	_material_cache.clear()
	_has_applied_snapshot = false
	_built = false


func apply_snapshot(snapshot: Dictionary) -> void:
	if not _built:
		build()
	var previous_level := _facility_level
	var catalog_entry := _catalog_entry(snapshot)
	var operations := _dictionary(snapshot.get("operations", {}))
	var supervision := _dictionary(operations.get("supervision", {}))
	_facility_level = clampi(
		_snapshot_facility_level(snapshot, operations, catalog_entry), 0, MAX_LEVEL
	)
	_unlocked = (
		_facility_level > 0
		or bool(catalog_entry.get(
			"unlocked",
			catalog_entry.get("available", catalog_entry.get("can_purchase", false)),
		))
	)

	_has_supervision_metrics = (
		supervision.has("action_limit")
		or supervision.has("personnel_action_limit")
		or supervision.has("supervisor_payroll_cents")
		or supervision.has("surveillance_grievance_millipoints")
	)
	_action_limit = clampi(int(supervision.get(
		"action_limit",
		supervision.get("personnel_action_limit", 0),
	)), 0, 4)
	_actions_used = clampi(int(supervision.get(
		"actions_used",
		supervision.get("personnel_actions_used", supervision.get("action_used", 0)),
	)), 0, _action_limit)
	_actions_remaining = clampi(int(supervision.get(
		"actions_remaining",
		supervision.get(
			"personnel_actions_remaining",
			supervision.get("action_remaining", maxi(0, _action_limit - _actions_used)),
		),
	)), 0, _action_limit)
	_supervisor_payroll_cents = maxi(0, int(supervision.get("supervisor_payroll_cents", 0)))
	_grievance_millipoints = maxi(0, int(supervision.get("surveillance_grievance_millipoints", 0)))
	_stress_millipoints = maxi(0, int(supervision.get("surveillance_stress_millipoints", 0)))
	_solidarity_millipoints = maxi(0, int(supervision.get("surveillance_solidarity_millipoints", 0)))
	_quota_pressure_actions_today = maxi(0, int(supervision.get("quota_pressure_actions_today", 0)))
	_shift_pressure_applied = bool(supervision.get("shift_pressure_applied", false))
	_queue_counts = _dictionary(snapshot.get("claim_queue_counts", {})).duplicate()
	_read_assignment_records(snapshot)
	_active_directive = _dictionary(snapshot.get("active_directive", {})).duplicate(true)

	_apply_visibility()
	_rebuild_assignment_tokens()
	_rebuild_directive_card()
	_apply_dynamic_state()
	if _has_applied_snapshot and _facility_level > previous_level and is_inside_tree():
		_animate_reveal()
	_has_applied_snapshot = true


func set_camera_detail(focused: bool, focus_position: Vector3 = Vector3(INF, INF, INF)) -> void:
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


func supervisor_station_count() -> int:
	return _supervisor_stations.size()


func visible_supervisor_station_count() -> int:
	var count := 0
	for station in _supervisor_stations:
		if int(station.get_meta(&"required_level", 99)) <= _facility_level:
			count += 1
	return count


func visible_assignment_token_count() -> int:
	return _assignment_tokens.size() if _facility_level >= 2 else 0


func assignment_worker_ids() -> Array[int]:
	var result: Array[int] = []
	if _facility_level < 2:
		return result
	for token in _assignment_tokens:
		result.append(int(token.get_meta(&"worker_id", -1)))
	return result


func active_directive_visible() -> bool:
	return _facility_level >= 3 and not _directive_cards.is_empty()


func active_directive_id() -> StringName:
	return StringName(String(_active_directive.get("id", "")))


func operations_status_text() -> String:
	return _supervision_label.text if _supervision_label != null else ""


func queue_status_text() -> String:
	return _queue_label.text if _queue_label != null else ""


func has_authoritative_metrics() -> bool:
	return _has_supervision_metrics


func geometry_bounds_inside_footprint() -> bool:
	var local_half := FOOTPRINT.size * 0.5
	var tolerance := 0.012
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null:
			continue
		var bounds := instance.mesh.get_aabb()
		var bounds_end := bounds.position + bounds.size
		for corner_x in [bounds.position.x, bounds_end.x]:
			for corner_y in [bounds.position.y, bounds_end.y]:
				for corner_z in [bounds.position.z, bounds_end.z]:
					var local_corner := to_local(instance.to_global(Vector3(corner_x, corner_y, corner_z)))
					if (
						absf(local_corner.x) > local_half.x + tolerance
						or absf(local_corner.z) > local_half.y + tolerance
						or local_corner.y > MAX_OPAQUE_HEIGHT + tolerance
					):
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
		var bounds_end := bounds.position + bounds.size
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
		"visible_supervisor_stations": visible_supervisor_station_count(),
		"assignment_worker_ids": assignment_worker_ids(),
		"active_directive_id": active_directive_id(),
		"action_limit": _action_limit,
		"actions_used": _actions_used,
		"actions_remaining": _actions_remaining,
		"supervisor_payroll_cents": _supervisor_payroll_cents,
		"surveillance_grievance_millipoints": _grievance_millipoints,
		"surveillance_stress_millipoints": _stress_millipoints,
		"surveillance_solidarity_millipoints": _solidarity_millipoints,
		"quota_pressure_actions_today": _quota_pressure_actions_today,
		"shift_pressure_applied": _shift_pressure_applied,
		"footprint": FOOTPRINT,
		"focus_point": FOCUS_POINT,
	}


func _build_locked_marker() -> void:
	locked_marker_root = Node3D.new()
	locked_marker_root.name = "RoosterOperationsLockedParcel"
	locked_marker_root.set_meta(&"facility_state", &"locked")
	add_child(locked_marker_root)
	_add_box(locked_marker_root, "OperationsLockedGround", Vector3(6.34, 0.035, 5.74), Vector3(0.0, -0.016, 0.0), GRAPHITE.darkened(0.08), 0.96)
	for corner in [Vector3(-2.88, 0.34, -2.46), Vector3(2.88, 0.34, -2.46), Vector3(-2.88, 0.34, 2.46), Vector3(2.88, 0.34, 2.46)]:
		_add_box(locked_marker_root, "OperationsParcelStake", Vector3(0.09, 0.68, 0.09), corner, WALNUT, 0.76)
	var notice_host := _add_box(locked_marker_root, "OperationsParcelReviewHost", Vector3(3.32, 0.72, 0.11), Vector3(0.0, 0.86, 2.45), DEEP_BURGUNDY, 0.78)
	EnvironmentalSignageScript.add_panel(notice_host, "RoosterOperationsLockedNotice", "OPERATIONS PARCEL\nSPAN REVIEW", Vector3(0.0, 0.0, 0.064), Vector2(3.04, 0.50), DEEP_BURGUNDY, CREAM, Vector3.ZERO, 14, 0.0028, &"secondary", &"machine")


func _build_survey_site() -> void:
	survey_site_root = Node3D.new()
	survey_site_root.name = "RoosterOperationsSurveySite"
	survey_site_root.set_meta(&"facility_state", &"survey")
	add_child(survey_site_root)
	_add_box(survey_site_root, "OperationsSurveyFoundation", Vector3(6.34, 0.10, 5.74), Vector3(0.0, -0.04, 0.0), BARN_RED.darkened(0.40), 0.94)
	for grid_x in [-2.0, 0.0, 2.0]:
		_add_box(survey_site_root, "OperationsSurveyRuleX", Vector3(0.025, 0.008, 5.22), Vector3(grid_x, 0.015, 0.0), OATMEAL.darkened(0.20), 0.96)
	for grid_z in [-1.72, 0.0, 1.72]:
		_add_box(survey_site_root, "OperationsSurveyRuleZ", Vector3(5.72, 0.008, 0.025), Vector3(0.0, 0.016, grid_z), OATMEAL.darkened(0.20), 0.96)
	var mock_board := Node3D.new()
	mock_board.name = "ShiftBoardScaleMockup"
	mock_board.position = Vector3(-1.55, 0.0, 0.64)
	survey_site_root.add_child(mock_board)
	_add_box(mock_board, "MockBoardStand", Vector3(1.76, 0.12, 0.66), Vector3(0.0, 0.08, 0.0), GRAPHITE, 0.58, 0.18)
	_add_box(mock_board, "MockBoardFace", Vector3(1.58, 1.02, 0.09), Vector3(0.0, 0.72, -0.18), SLATE, 0.80)
	for rule_index in 3:
		_add_box(mock_board, "MockLaneRule_%02d" % (rule_index + 1), Vector3(1.24, 0.055, 0.025), Vector3(0.0, 0.48 + rule_index * 0.25, -0.125), [LANE_COLORS[&"nest_damage"], LANE_COLORS[&"predator_loss"], LANE_COLORS[&"appeals"]][rule_index], 0.88)
	var survey_host := _add_box(survey_site_root, "OperationsSurveyNoticeHost", Vector3(3.42, 0.78, 0.11), Vector3(0.55, 0.78, 2.45), DEEP_BURGUNDY, 0.78)
	EnvironmentalSignageScript.add_panel(survey_host, "RoosterOperationsSurveyNotice", "SUPERVISION PARCEL\nSPAN FILE PENDING", Vector3(0.0, 0.0, 0.064), Vector2(3.14, 0.55), DEEP_BURGUNDY, CREAM, Vector3.ZERO, 14, 0.0028, &"secondary", &"machine")


func _build_owned_room() -> void:
	owned_room_root = Node3D.new()
	owned_room_root.name = "RoosterOperationsOfficeRoom"
	owned_room_root.set_meta(&"facility_state", &"owned")
	owned_room_root.set_meta(&"management_camera_cutaway", true)
	add_child(owned_room_root)
	_build_shell(owned_room_root)
	_build_live_boards(owned_room_root)

	level_1_root = _new_level_root("ShiftBoardPerchTier", 1)
	_build_supervisor_station(level_1_root, 0, 0.0, 1, BARN_RED)
	_build_shift_board_details(level_1_root)

	level_2_root = _new_level_root("GlassSupervisionPodTier", 2)
	_build_supervisor_station(level_2_root, 1, -1.66, 2, DUSTY_ROSE)
	_build_glass_supervision_pod(level_2_root)

	level_3_root = _new_level_root("CommandRoostGalleryTier", 3)
	_build_supervisor_station(level_3_root, 2, 1.66, 3, BRASS.darkened(0.08))
	_build_command_gallery(level_3_root)


func _build_shell(parent: Node3D) -> void:
	_add_box(parent, "RoosterOperationsConnectedPad", Vector3(6.36, 0.18, 5.76), Vector3(0.0, -0.10, 0.0), Color("545757"), 0.94)
	_add_box(parent, "RoosterOperationsFloorInset", Vector3(6.06, 0.025, 5.46), Vector3(0.0, 0.004, 0.0), Color("6a6260"), 0.94)
	_add_box(parent, "RoosterOperationsRunner", Vector3(4.82, 0.018, 2.54), Vector3(0.0, 0.020, -0.52), BARN_RED.darkened(0.20), 0.98)
	_add_box(parent, "RoosterOperationsBackWall", Vector3(6.10, 2.68, 0.12), Vector3(0.0, 1.34, -2.70), DEEP_BURGUNDY, 0.78)
	_add_box(parent, "RoosterOperationsBackWallDado", Vector3(6.12, 0.72, 0.15), Vector3(0.0, 0.38, -2.62), WALNUT, 0.72)
	for post_x in [-3.05, 3.05]:
		for post_z in [-2.64, 2.64]:
			_add_box(parent, "RoosterOperationsFramePost", Vector3(0.13, 3.30, 0.13), Vector3(post_x, 1.65, post_z), DEEP_BURGUNDY, 0.66, 0.12)
	_add_box(parent, "RoosterOperationsFrameBeam", Vector3(6.06, 0.13, 0.13), Vector3(0.0, 3.34, -2.63), DEEP_BURGUNDY, 0.64, 0.14)
	# The public-facing beam is a deeper structural lintel that bears on both
	# corner posts. The operations identity becomes its fascia, not a pendant.
	var front_lintel := _add_box(parent, "RoosterOperationsFrontLintel", Vector3(6.06, 0.22, 0.16), Vector3(0.0, 3.30, 2.63), DEEP_BURGUNDY, 0.64, 0.14)
	front_lintel.set_meta(&"architectural_mount", &"command_lintel")
	for slat_x in [-2.20, -1.10, 0.0, 1.10, 2.20]:
		_add_box(parent, "RoosterOperationsCanopySlat", Vector3(0.15, 0.055, 3.30), Vector3(slat_x, 3.49, -0.62), WALNUT.darkened(0.05), 0.76)

	var dado := _add_box(parent, "RoosterOperationsNorthCutawayDado", Vector3(6.10, 0.46, 0.12), Vector3(0.0, 0.23, 2.70), BARN_RED, 0.84)
	dado.set_meta(&"camera_facing_cutaway", true)
	_add_box(parent, "RoosterOperationsNorthCutawayCap", Vector3(6.10, 0.07, 0.17), Vector3(0.0, 0.495, 2.69), BRASS.darkened(0.12), 0.54, 0.34)
	for wing_x in [-2.42, 2.42]:
		var glass := _add_glass_box(parent, "RoosterOperationsNorthReededGlass", Vector3(1.08, 1.68, 0.04), Vector3(wing_x, 1.40, 2.68))
		glass.set_meta(&"cutaway_wing", true)
		for reed_x in [-0.34, 0.0, 0.34]:
			_add_box(parent, "RoosterOperationsNorthGlassReed", Vector3(0.025, 1.56, 0.055), Vector3(wing_x + reed_x, 1.40, 2.675), CREAM.darkened(0.24), 0.62)
	var east_glass := _add_glass_box(parent, "RoosterOperationsEastReededGlass", Vector3(0.04, 2.10, 2.70), Vector3(2.99, 1.48, 0.72))
	east_glass.set_meta(&"camera_facing_cutaway", true)
	for reed_z in [-0.92, -0.46, 0.0, 0.46, 0.92]:
		_add_box(parent, "RoosterOperationsEastGlassReed", Vector3(0.055, 2.00, 0.025), Vector3(2.985, 1.48, 0.72 + reed_z), CREAM.darkened(0.24), 0.62)

	var identity_host := _add_box(front_lintel, "RoosterOperationsIdentityHost", Vector3(3.92, 0.44, 0.12), Vector3(0.0, -0.33, -0.015), DEEP_BURGUNDY, 0.74)
	identity_host.set_meta(&"architectural_mount", &"command_lintel")
	for bracket_index in 2:
		var bracket_x: float = -1.82 if bracket_index == 0 else 1.82
		_add_box(front_lintel, "RoosterOperationsLintelBracket_%02d" % (bracket_index + 1), Vector3(0.12, 0.36, 0.15), Vector3(bracket_x, -0.19, -0.005), BRASS.darkened(0.10), 0.52, 0.42)
	EnvironmentalSignageScript.add_panel(identity_host, "RoosterOperationsIdentity", "ROOSTER OPERATIONS\nSCHEDULE & SUPERVISION", Vector3(0.0, 0.0, 0.066), Vector2(3.62, 0.38), DEEP_BURGUNDY, CREAM, Vector3.ZERO, 14, 0.0028, &"primary", &"destination")

	var pendant := Node3D.new()
	pendant.name = "RoosterOperationsPendant"
	parent.add_child(pendant)
	_add_cylinder(pendant, "OperationsPendantRose", Vector3(0.0, 3.39, 0.20), 0.18, 0.08, BRASS.darkened(0.12), 0.48, 0.40)
	_add_cylinder(pendant, "OperationsPendantStem", Vector3(0.0, 3.07, 0.20), 0.025, 0.58, GRAPHITE, 0.52, 0.28)
	_add_cylinder(pendant, "OperationsPendantShade", Vector3(0.0, 2.72, 0.20), 0.32, 0.22, OATMEAL, 0.74)
	var light := OmniLight3D.new()
	light.name = "RoosterOperationsWarmLight"
	light.position = Vector3(0.0, 2.52, 0.20)
	light.light_color = Color("ffd7a2")
	light.light_energy = 0.48
	light.omni_range = 4.8
	light.shadow_enabled = false
	pendant.add_child(light)


func _build_live_boards(parent: Node3D) -> void:
	var queue_board := Node3D.new()
	queue_board.name = "AuthoritativeQueueBoard"
	queue_board.position = Vector3(-1.62, 0.0, -2.49)
	queue_board.set_meta(&"authoritative_records_only", true)
	parent.add_child(queue_board)
	_add_box(queue_board, "QueueBoardCabinet", Vector3(2.48, 1.26, 0.24), Vector3(0.0, 1.82, 0.0), DARK_WALNUT, 0.72)
	var queue_screen := _add_box(queue_board, "QueueBoardScreen", Vector3(2.20, 0.38, 0.08), Vector3(0.0, 2.12, 0.155), GRAPHITE, 0.48, 0.22)
	_queue_label = EnvironmentalSignageScript.add_panel(queue_screen, "RoosterOperationsQueueLive", "QUEUE / AWAITING SHIFT", Vector3(0.0, 0.0, 0.047), Vector2(1.94, 0.25), GRAPHITE, SCREEN_AMBER.lightened(0.22), Vector3.ZERO, 12, 0.0025, &"utility", &"screen", true)
	for lane_index in LANE_ORDER.size():
		var lane := LANE_ORDER[lane_index]
		var lane_color := LANE_COLORS[lane] as Color
		var lane_pips: Array[MeshInstance3D] = []
		for pip_index in QUEUE_PIPS_PER_LANE:
			var pip := _add_box(queue_board, "Queue%sPip_%02d" % [String(LANE_SHORT_NAMES[lane]).capitalize(), pip_index + 1], Vector3(0.22, 0.075, 0.05), Vector3(-0.68 + pip_index * 0.27, 1.78 - lane_index * 0.18, 0.17), GRAPHITE.darkened(0.12), 0.60)
			pip.set_meta(&"claim_lane", lane)
			lane_pips.append(pip)
		_queue_pips[lane] = lane_pips

	var console := Node3D.new()
	console.name = "SupervisionEffectsConsole"
	console.position = Vector3(1.58, 0.0, -2.49)
	parent.add_child(console)
	_add_box(console, "SupervisionConsoleCabinet", Vector3(2.56, 1.26, 0.24), Vector3(0.0, 1.82, 0.0), WALNUT, 0.72)
	var supervision_screen := _add_box(console, "SupervisionEffectsScreen", Vector3(2.28, 0.68, 0.08), Vector3(0.0, 1.95, 0.155), GRAPHITE, 0.48, 0.22)
	_supervision_label = EnvironmentalSignageScript.add_panel(supervision_screen, "RoosterOperationsLiveEffects", "SUPERVISION / AWAITING SHIFT", Vector3(0.0, 0.0, 0.047), Vector2(2.02, 0.50), GRAPHITE, SCREEN_GREEN.lightened(0.22), Vector3.ZERO, 12, 0.00235, &"utility", &"screen", true)
	for pip_index in 4:
		var pip := _add_box(console, "PersonnelActionSocket_%02d" % (pip_index + 1), Vector3(0.28, 0.09, 0.05), Vector3(-0.48 + pip_index * 0.32, 1.38, 0.17), GRAPHITE.darkened(0.12), 0.60)
		pip.set_meta(&"action_slot", pip_index + 1)
		_action_pips.append(pip)


func _new_level_root(root_name: String, level: int) -> Node3D:
	var level_root := Node3D.new()
	level_root.name = root_name
	level_root.set_meta(&"facility_level", level)
	owned_room_root.add_child(level_root)
	return level_root


func _build_supervisor_station(parent: Node3D, station_index: int, x: float, required_level: int, accent: Color) -> void:
	var station := Node3D.new()
	station.name = "ConnectedSupervisorStation_%02d" % (station_index + 1)
	station.position = Vector3(x, 0.0, -0.54)
	station.set_meta(&"required_level", required_level)
	station.set_meta(&"intentionally_empty", true)
	parent.add_child(station)
	_add_box(station, "SupervisorStationFoot", Vector3(1.32, 0.10, 1.48), Vector3(0.0, 0.05, 0.0), GRAPHITE, 0.50, 0.32)
	for leg_x in [-0.50, 0.50]:
		_add_box(station, "SupervisorDeskLeg", Vector3(0.10, 0.78, 0.10), Vector3(leg_x, 0.41, -0.24), GRAPHITE, 0.48, 0.34)
	_add_box(station, "SupervisorDesk", Vector3(1.40, 0.14, 0.78), Vector3(0.0, 0.84, -0.24), WALNUT, 0.70)
	_add_box(station, "SupervisorMonitorArm", Vector3(0.10, 0.56, 0.10), Vector3(0.0, 1.12, -0.48), GRAPHITE, 0.46, 0.34)
	_add_box(station, "SupervisorMonitorFrame", Vector3(0.90, 0.62, 0.11), Vector3(0.0, 1.50, -0.47), GRAPHITE, 0.46, 0.24)
	var screen := _add_box(station, "SupervisorMonitorScreen", Vector3(0.79, 0.50, 0.024), Vector3(0.0, 1.50, -0.408), accent.darkened(0.20), 0.54)
	screen.material_override = _emissive_material(accent, 0.42)
	_add_box(station, "SupervisorKeyboard", Vector3(0.76, 0.055, 0.27), Vector3(0.0, 0.93, -0.04), GRAPHITE.lightened(0.06), 0.62)
	_add_box(station, "SupervisorPerchBase", Vector3(0.88, 0.12, 0.66), Vector3(0.0, 0.12, 0.52), DARK_WALNUT, 0.72)
	var perch := _add_cylinder(station, "SupervisorPerchRail", Vector3(0.0, 0.50, 0.52), 0.055, 0.76, BRASS.darkened(0.08), 0.52, 0.40)
	perch.rotation_degrees.z = 90.0
	_add_box(station, "SupervisorPerchBack", Vector3(0.84, 0.64, 0.12), Vector3(0.0, 0.65, 0.82), WALNUT, 0.74)
	var plate_host := _add_box(station, "SupervisorStationPlateHost", Vector3(0.88, 0.20, 0.05), Vector3(0.0, 0.58, -0.61), accent.darkened(0.22), 0.78)
	EnvironmentalSignageScript.add_panel(plate_host, "SupervisorStationPlate_%02d" % (station_index + 1), "SHIFT %02d" % (station_index + 1), Vector3(0.0, 0.0, 0.032), Vector2(0.76, 0.13), accent.darkened(0.22), CREAM, Vector3.ZERO, 10, 0.0022, &"utility", &"machine")
	_supervisor_stations.append(station)


func _build_shift_board_details(parent: Node3D) -> void:
	var punch_clock := Node3D.new()
	punch_clock.name = "ShiftBoardPunchClock"
	punch_clock.position = Vector3(-2.46, 0.0, 0.90)
	parent.add_child(punch_clock)
	_add_box(punch_clock, "PunchClockCabinet", Vector3(0.90, 1.24, 0.62), Vector3(0.0, 0.62, 0.0), DARK_WALNUT, 0.74)
	_add_box(punch_clock, "PunchClockFace", Vector3(0.66, 0.38, 0.05), Vector3(0.0, 0.92, 0.336), GRAPHITE, 0.52)
	for slot_index in 4:
		_add_box(punch_clock, "ShiftPunchCard_%02d" % (slot_index + 1), Vector3(0.13, 0.38, 0.30), Vector3(-0.24 + slot_index * 0.16, 0.38, 0.25), OATMEAL.darkened(slot_index * 0.025), 0.92)
	var plate := _add_box(parent, "ShiftBoardPerchPlateHost", Vector3(2.08, 0.30, 0.08), Vector3(1.90, 2.52, -2.58), DEEP_BURGUNDY, 0.74)
	EnvironmentalSignageScript.add_panel(plate, "ShiftBoardPerchPlate", "SHIFT BOARD PERCH", Vector3(0.0, 0.0, 0.047), Vector2(1.86, 0.21), DEEP_BURGUNDY, CREAM, Vector3.ZERO, 11, 0.0024, &"utility", &"machine")


func _build_glass_supervision_pod(parent: Node3D) -> void:
	var pod := Node3D.new()
	pod.name = "GlassSupervisionPod"
	pod.position = Vector3(-2.92, 0.0, 0.58)
	pod.rotation_degrees.y = 90.0
	parent.add_child(pod)
	_add_box(pod, "SupervisionPodFrame", Vector3(3.22, 1.78, 0.10), Vector3(0.0, 1.36, 0.0), DEEP_BURGUNDY, 0.62, 0.16)
	_add_glass_box(pod, "SupervisionPodGlass", Vector3(3.02, 1.56, 0.035), Vector3(0.0, 1.36, 0.061))
	for mullion_x in [-1.0, 0.0, 1.0]:
		_add_box(pod, "SupervisionPodMullion", Vector3(0.045, 1.52, 0.055), Vector3(mullion_x, 1.36, 0.066), BRASS.darkened(0.18), 0.54, 0.30)
	var title_host := _add_box(pod, "AssignmentRailTitleHost", Vector3(2.72, 0.27, 0.06), Vector3(0.0, 2.07, 0.092), BARN_RED, 0.76)
	EnvironmentalSignageScript.add_panel(title_host, "OperationsAssignmentRailHeader", "FILE ASSIGNMENTS", Vector3(0.0, 0.0, 0.038), Vector2(2.48, 0.18), BARN_RED, CREAM, Vector3.ZERO, 11, 0.0023, &"secondary", &"machine")
	_assignment_token_root = Node3D.new()
	_assignment_token_root.name = "AuthoritativeAssignmentTokens"
	_assignment_token_root.position = Vector3(0.0, 0.0, 0.10)
	_assignment_token_root.set_meta(&"authoritative_records_only", true)
	pod.add_child(_assignment_token_root)


func _build_command_gallery(parent: Node3D) -> void:
	var gallery := Node3D.new()
	gallery.name = "CommandRoostGallery"
	parent.add_child(gallery)
	_add_box(gallery, "CommandGalleryRail", Vector3(3.46, 0.11, 0.11), Vector3(0.52, 2.62, -2.51), BRASS.darkened(0.10), 0.48, 0.42)
	for monitor_index in 3:
		var x := -0.46 + monitor_index * 0.98
		_add_box(gallery, "CommandGalleryMonitorFrame_%02d" % (monitor_index + 1), Vector3(0.78, 0.52, 0.10), Vector3(x, 2.18, -2.50), GRAPHITE, 0.48, 0.22)
		var screen := _add_box(gallery, "CommandGalleryMonitorScreen_%02d" % (monitor_index + 1), Vector3(0.66, 0.40, 0.024), Vector3(x, 2.18, -2.439), [LANE_COLORS[&"nest_damage"], LANE_COLORS[&"predator_loss"], LANE_COLORS[&"appeals"]][monitor_index].darkened(0.20), 0.58)
		screen.material_override = _emissive_material([LANE_COLORS[&"nest_damage"], LANE_COLORS[&"predator_loss"], LANE_COLORS[&"appeals"]][monitor_index], 0.36)
	_directive_card_root = Node3D.new()
	_directive_card_root.name = "AuthoritativeDirectiveDocket"
	_directive_card_root.position = Vector3(2.12, 0.0, -2.42)
	_directive_card_root.set_meta(&"authoritative_records_only", true)
	gallery.add_child(_directive_card_root)
	var plate := _add_box(gallery, "CommandRoostGalleryPlateHost", Vector3(2.18, 0.29, 0.08), Vector3(-1.84, 2.76, -2.57), DEEP_BURGUNDY, 0.74)
	EnvironmentalSignageScript.add_panel(plate, "CommandRoostGalleryPlate", "COMMAND ROOST GALLERY", Vector3(0.0, 0.0, 0.047), Vector2(1.96, 0.20), DEEP_BURGUNDY, CREAM, Vector3.ZERO, 11, 0.00235, &"utility", &"machine")


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
	if _supervision_label != null:
		if _has_supervision_metrics:
			_supervision_label.text = "ACTIONS %d/%d / PAY $%.2f\nWATCH +%.2fG +%.2fS / UNITY +%.2f" % [
				_actions_remaining,
				_action_limit,
				float(_supervisor_payroll_cents) / 100.0,
				float(_grievance_millipoints) / 1000.0,
				float(_stress_millipoints) / 1000.0,
				float(_solidarity_millipoints) / 1000.0,
			]
		else:
			_supervision_label.text = "SUPERVISION / AWAITING SHIFT"
		EnvironmentalSignageScript.refit_label(_supervision_label)
	if _queue_label != null:
		_queue_label.text = "N %02d / P %02d / A %02d" % [
			maxi(0, int(_queue_counts.get(&"nest_damage", _queue_counts.get("nest_damage", 0)))),
			maxi(0, int(_queue_counts.get(&"predator_loss", _queue_counts.get("predator_loss", 0)))),
			maxi(0, int(_queue_counts.get(&"appeals", _queue_counts.get("appeals", 0)))),
		]
		EnvironmentalSignageScript.refit_label(_queue_label)
	for pip_index in _action_pips.size():
		var pip := _action_pips[pip_index]
		if pip_index < _actions_remaining:
			pip.material_override = _emissive_material(SCREEN_GREEN, 0.72)
		elif pip_index < _action_limit:
			pip.material_override = _material(BARN_RED.darkened(0.10), 0.64)
		else:
			pip.material_override = _material(GRAPHITE.darkened(0.12), 0.60)
	for lane in LANE_ORDER:
		var lane_pips: Array = _queue_pips.get(lane, []) as Array
		var count := maxi(0, int(_queue_counts.get(lane, _queue_counts.get(String(lane), 0))))
		for pip_index in lane_pips.size():
			var pip := lane_pips[pip_index] as MeshInstance3D
			pip.material_override = _emissive_material(LANE_COLORS[lane], 0.60) if pip_index < mini(count, QUEUE_PIPS_PER_LANE) else _material(GRAPHITE.darkened(0.12), 0.60)


func _read_assignment_records(snapshot: Dictionary) -> void:
	_assignment_records.clear()
	var workers_variant: Variant = snapshot.get("workers", [])
	if not (workers_variant is Array):
		return
	for worker_variant in workers_variant as Array:
		if not (worker_variant is Dictionary):
			continue
		var worker := worker_variant as Dictionary
		if not bool(worker.get("employed", true)):
			continue
		_assignment_records.append({
			"worker_id": int(worker.get("id", worker.get("worker_id", -1))),
			"worker_name": String(worker.get("display_name", worker.get("name", "FLOCK MEMBER"))).strip_edges(),
			"assigned_lane": StringName(String(worker.get("assigned_lane", &"auto"))),
			"assignment_name": String(worker.get("assignment_name", "AUTO DISPATCH")).strip_edges(),
		})
		if _assignment_records.size() >= MAX_ASSIGNMENT_TOKENS:
			break


func _rebuild_assignment_tokens() -> void:
	_assignment_tokens.clear()
	if _assignment_token_root == null:
		return
	for child in _assignment_token_root.get_children():
		child.free()
	if _facility_level < 2:
		return
	for record_index in _assignment_records.size():
		var record := _assignment_records[record_index]
		var token := Node3D.new()
		token.name = "OperationsAssignmentToken_%02d" % (record_index + 1)
		token.position = Vector3(-0.92 + (record_index % 3) * 0.92, 1.73 - int(record_index / 3) * 0.48, 0.0)
		token.set_meta(&"authoritative_record", true)
		token.set_meta(&"worker_id", int(record.get("worker_id", -1)))
		var lane := StringName(record.get("assigned_lane", &"auto"))
		token.set_meta(&"assigned_lane", lane)
		_assignment_token_root.add_child(token)
		var token_color := LANE_COLORS.get(lane, LANE_COLORS[&"auto"]) as Color
		var host := _add_box(token, "AssignmentTokenHost", Vector3(0.82, 0.34, 0.055), Vector3.ZERO, token_color.darkened(0.18), 0.82)
		var worker_name := String(record.get("worker_name", "FLOCK MEMBER")).to_upper()
		var assignment_name := String(record.get("assignment_name", String(LANE_SHORT_NAMES.get(lane, "AUTO")))).to_upper()
		EnvironmentalSignageScript.add_panel(host, "OperationsAssignmentCopy_%02d" % (record_index + 1), "%s\n%s" % [worker_name, assignment_name], Vector3(0.0, 0.0, 0.035), Vector2(0.72, 0.25), token_color.darkened(0.18), CREAM, Vector3.ZERO, 9, 0.0019, &"utility", &"machine")
		_assignment_tokens.append(token)


func _rebuild_directive_card() -> void:
	_directive_cards.clear()
	if _directive_card_root == null:
		return
	for child in _directive_card_root.get_children():
		child.free()
	if _facility_level < 3 or _active_directive.is_empty():
		return
	var directive_id := StringName(String(_active_directive.get("id", "")))
	if directive_id == &"":
		return
	var card := Node3D.new()
	card.name = "AuthoritativeDirectiveCard"
	card.position = Vector3(0.0, 2.18, 0.0)
	card.set_meta(&"authoritative_record", true)
	card.set_meta(&"directive_id", directive_id)
	_directive_card_root.add_child(card)
	var host := _add_box(card, "DirectiveCardHost", Vector3(1.40, 0.66, 0.055), Vector3.ZERO, OATMEAL, 0.92)
	var directive_name := String(_active_directive.get("name", _active_directive.get("title", String(directive_id).replace("_", " ")))).to_upper()
	EnvironmentalSignageScript.add_panel(host, "AuthoritativeDirectiveCopy", "ACTIVE DIRECTIVE\n%s" % directive_name, Vector3(0.0, 0.0, 0.035), Vector2(1.26, 0.52), OATMEAL, DEEP_BURGUNDY, Vector3.ZERO, 10, 0.0020, &"utility", &"machine")
	_directive_cards.append(card)


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


func _snapshot_facility_level(snapshot: Dictionary, operations: Dictionary, catalog_entry: Dictionary) -> int:
	if operations.has("rooster_office_level"):
		return _level_from_variant(operations.get("rooster_office_level", 0))
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
	mesh.radial_segments = 16
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color, roughness, metallic)
	parent.add_child(instance)
	return instance


func _add_glass_box(parent: Node3D, part_name: String, size: Vector3, part_position: Vector3) -> MeshInstance3D:
	var glass := _add_box(parent, part_name, size, part_position, GLASS, 0.20)
	glass.material_override = _material(GLASS, 0.18)
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
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	_material_cache[key] = material
	return material


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _material(color.darkened(0.16), 0.50).duplicate() as StandardMaterial3D
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
