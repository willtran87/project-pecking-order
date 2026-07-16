class_name TrainingRoostVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## Visual-only career and cross-lane training facility. Its credential gallery
## is record honest: slots, rails, and press hardware are permanent, but named
## credentials only appear when workers actually have a secondary specialty.
const FACILITY_ID: StringName = &"training_roost"
const FACILITY_CENTER := Vector3(15.20, 0.0, 24.00)
const FOCUS_POINT := Vector3(15.20, 1.05, 24.00)
const FOOTPRINT := Rect2(Vector2(12.00, 21.10), Vector2(6.40, 5.80))
const MAX_LEVEL := 3
const MAX_OPAQUE_HEIGHT := 3.55

const DEEP_TEAL := Color("263f42")
const ENAMEL_TEAL := Color("36585a")
const BLUE_GREEN := Color("54797a")
const PALE_BLUE := Color("88a4a0")
const BIRCH := Color("cbbd9e")
const CREAM := Color("eee3c8")
const WALNUT := Color("684b36")
const DARK_WALNUT := Color("49372d")
const BRASS := Color("c2a055")
const GRAPHITE := Color("30383a")
const SCREEN_BLUE := Color("70a7a3")
const LANE_NEST := Color("7b9b80")
const LANE_PREDATOR := Color("b17161")
const LANE_APPEALS := Color("7d829e")
const GLASS := Color("84a9aa60")

var locked_marker_root: Node3D
var survey_site_root: Node3D
var owned_room_root: Node3D
var level_1_root: Node3D
var level_2_root: Node3D
var level_3_root: Node3D

var _practice_terminals: Array[Node3D] = []
var _practice_pips: Array[MeshInstance3D] = []
var _credential_tag_root: Node3D
var _credential_tags: Array[Node3D] = []
var _status_label: Label3D
var _credential_header_label: Label3D
var _material_cache: Dictionary[String, StandardMaterial3D] = {}

var _built := false
var _has_applied_snapshot := false
var _unlocked := false
var _facility_level := 0
var _has_training_metrics := false
var _sponsorship_cost_cents := 0
var _training_work_basis_points := 0
var _coaching_xp_bonus := 0
var _active_trainee_count := 0
var _credential_records: Array[Dictionary] = []


func _ready() -> void:
	name = "TrainingRoostVisual"
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
	_practice_terminals.clear()
	_practice_pips.clear()
	_credential_tag_root = null
	_credential_tags.clear()
	_status_label = null
	_credential_header_label = null
	_material_cache.clear()
	_has_applied_snapshot = false
	_built = false


func apply_snapshot(snapshot: Dictionary) -> void:
	if not _built:
		build()
	var previous_level := _facility_level
	var catalog_entry := _catalog_entry(snapshot)
	_facility_level = clampi(_snapshot_facility_level(snapshot, catalog_entry), 0, MAX_LEVEL)
	_unlocked = (
		_facility_level > 0
		or bool(catalog_entry.get(
			"unlocked",
			catalog_entry.get("available", catalog_entry.get("can_purchase", false)),
		))
	)

	var sponsorship_value: Variant = _metric_variant(snapshot, [
		&"career_sponsorship_cost_cents", &"sponsorship_cost_cents",
	])
	var work_value: Variant = _metric_variant(snapshot, [
		&"cross_training_work_basis_points", &"training_work_basis_points",
	])
	var xp_value: Variant = _metric_variant(snapshot, [
		&"career_coaching_xp_bonus", &"coaching_xp_bonus",
	])
	_has_training_metrics = sponsorship_value != null or work_value != null or xp_value != null
	_sponsorship_cost_cents = maxi(0, int(sponsorship_value if sponsorship_value != null else 0))
	_training_work_basis_points = clampi(int(work_value if work_value != null else 0), 0, 20_000)
	_coaching_xp_bonus = maxi(0, int(xp_value if xp_value != null else 0))
	_read_worker_records(snapshot)

	_apply_visibility()
	_apply_dynamic_state()
	_rebuild_credential_tags()
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


func practice_terminal_count() -> int:
	return _practice_terminals.size()


func visible_terminal_count() -> int:
	var count := 0
	for terminal in _practice_terminals:
		if int(terminal.get_meta(&"required_level", 99)) <= _facility_level:
			count += 1
	return count


func visible_credential_count() -> int:
	return _credential_tags.size() if _facility_level >= 3 else 0


func credential_worker_ids() -> Array[int]:
	var result: Array[int] = []
	for record in _credential_records:
		result.append(int(record.get("worker_id", -1)))
	return result


func training_status_text() -> String:
	return _status_label.text if _status_label != null else ""


func has_authoritative_metrics() -> bool:
	return _has_training_metrics


func active_trainee_count() -> int:
	return _active_trainee_count


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
		"visible_terminals": visible_terminal_count(),
		"visible_credentials": visible_credential_count(),
		"active_trainees": _active_trainee_count,
		"sponsorship_cost_cents": _sponsorship_cost_cents,
		"training_work_basis_points": _training_work_basis_points,
		"coaching_xp_bonus": _coaching_xp_bonus,
		"footprint": FOOTPRINT,
		"focus_point": FOCUS_POINT,
	}


func _build_locked_marker() -> void:
	locked_marker_root = Node3D.new()
	locked_marker_root.name = "TrainingRoostLockedParcel"
	locked_marker_root.set_meta(&"facility_state", &"locked")
	add_child(locked_marker_root)
	_add_box(locked_marker_root, "TrainingLockedGround", Vector3(6.34, 0.035, 5.74), Vector3(0.0, -0.016, 0.0), GRAPHITE.darkened(0.08), 0.96)
	for corner in [Vector3(-2.88, 0.34, -2.46), Vector3(2.88, 0.34, -2.46), Vector3(-2.88, 0.34, 2.46), Vector3(2.88, 0.34, 2.46)]:
		_add_box(locked_marker_root, "TrainingParcelStake", Vector3(0.09, 0.68, 0.09), corner, WALNUT, 0.76)
	var notice_host := _add_box(locked_marker_root, "TrainingParcelReviewHost", Vector3(3.18, 0.72, 0.11), Vector3(0.0, 0.86, 2.45), DEEP_TEAL, 0.78)
	EnvironmentalSignageScript.add_panel(notice_host, "TrainingRoostLockedNotice", "TRAINING PARCEL\nCAREER REVIEW", Vector3(0.0, 0.0, 0.064), Vector2(2.90, 0.50), DEEP_TEAL, CREAM, Vector3.ZERO, 14, 0.0028, &"secondary", &"machine")


func _build_survey_site() -> void:
	survey_site_root = Node3D.new()
	survey_site_root.name = "TrainingRoostSurveySite"
	survey_site_root.set_meta(&"facility_state", &"survey")
	add_child(survey_site_root)
	_add_box(survey_site_root, "TrainingSurveyFoundation", Vector3(6.34, 0.10, 5.74), Vector3(0.0, -0.04, 0.0), BLUE_GREEN.darkened(0.34), 0.94)
	for grid_x in [-2.0, 0.0, 2.0]:
		_add_box(survey_site_root, "TrainingSurveyRuleX", Vector3(0.025, 0.008, 5.22), Vector3(grid_x, 0.015, 0.0), CREAM.darkened(0.20), 0.96)
	for grid_z in [-1.72, 0.0, 1.72]:
		_add_box(survey_site_root, "TrainingSurveyRuleZ", Vector3(5.72, 0.008, 0.025), Vector3(0.0, 0.016, grid_z), CREAM.darkened(0.20), 0.96)
	var mock_terminal := Node3D.new()
	mock_terminal.name = "TrainingTerminalMockup"
	mock_terminal.position = Vector3(-1.55, 0.0, 0.62)
	survey_site_root.add_child(mock_terminal)
	_add_box(mock_terminal, "MockTerminalDesk", Vector3(1.62, 0.12, 0.74), Vector3(0.0, 0.78, 0.0), BIRCH, 0.76)
	_add_box(mock_terminal, "MockMonitorFrame", Vector3(0.72, 0.54, 0.10), Vector3(0.0, 1.22, -0.18), GRAPHITE, 0.54)
	_add_box(mock_terminal, "MockMonitorScreen", Vector3(0.62, 0.44, 0.025), Vector3(0.0, 1.22, -0.121), BLUE_GREEN.darkened(0.18), 0.72)
	var survey_host := _add_box(survey_site_root, "TrainingSurveyNoticeHost", Vector3(3.36, 0.78, 0.11), Vector3(0.55, 0.78, 2.45), DEEP_TEAL, 0.78)
	EnvironmentalSignageScript.add_panel(survey_host, "TrainingRoostSurveyNotice", "TRAINING PARCEL\nCREDENTIAL FILE PENDING", Vector3(0.0, 0.0, 0.064), Vector2(3.08, 0.55), DEEP_TEAL, CREAM, Vector3.ZERO, 14, 0.0028, &"secondary", &"machine")


func _build_owned_room() -> void:
	owned_room_root = Node3D.new()
	owned_room_root.name = "TrainingRoostRoom"
	owned_room_root.set_meta(&"facility_state", &"owned")
	owned_room_root.set_meta(&"management_camera_cutaway", true)
	add_child(owned_room_root)
	_build_shell(owned_room_root)
	_build_metrics_console(owned_room_root)

	level_1_root = _new_level_root("PracticeTerminalTier", 1)
	_build_practice_terminal(level_1_root, 0, 0.0, 1, LANE_NEST)
	_build_practice_track(level_1_root)

	level_2_root = _new_level_root("CrossLaneClassroomTier", 2)
	_build_practice_terminal(level_2_root, 1, -1.62, 2, LANE_PREDATOR)
	_build_cross_lane_hardware(level_2_root)

	level_3_root = _new_level_root("CredentialGalleryTier", 3)
	_build_practice_terminal(level_3_root, 2, 1.62, 3, LANE_APPEALS)
	_build_credential_gallery(level_3_root)


func _build_shell(parent: Node3D) -> void:
	_add_box(parent, "TrainingRoostConnectedPad", Vector3(6.36, 0.18, 5.76), Vector3(0.0, -0.10, 0.0), Color("50595a"), 0.94)
	_add_box(parent, "TrainingRoostFloorInset", Vector3(6.06, 0.025, 5.46), Vector3(0.0, 0.004, 0.0), Color("5f6d6c"), 0.94)
	for lane_index in 3:
		_add_box(parent, "TrainingFloorLane_%02d" % (lane_index + 1), Vector3(1.54, 0.014, 3.62), Vector3(-1.62 + lane_index * 1.62, 0.022, -0.24), [LANE_PREDATOR, LANE_NEST, LANE_APPEALS][lane_index].darkened(0.20), 0.98)
	_add_box(parent, "TrainingRoostBackWall", Vector3(6.10, 2.68, 0.12), Vector3(0.0, 1.34, -2.70), DEEP_TEAL, 0.78)
	_add_box(parent, "TrainingRoostBackWallDado", Vector3(6.12, 0.72, 0.15), Vector3(0.0, 0.38, -2.62), WALNUT, 0.72)

	for post_x in [-3.05, 3.05]:
		for post_z in [-2.64, 2.64]:
			_add_box(parent, "TrainingRoostFramePost", Vector3(0.13, 3.30, 0.13), Vector3(post_x, 1.65, post_z), DEEP_TEAL, 0.66, 0.12)
	for beam_z in [-2.63, 2.63]:
		_add_box(parent, "TrainingRoostFrameBeam", Vector3(6.06, 0.13, 0.13), Vector3(0.0, 3.34, beam_z), DEEP_TEAL, 0.64, 0.14)
	# Training keeps a lighter five-baffle acoustic canopy over the teaching
	# wall. The front third stays open so terminals and credentials remain the
	# visual hierarchy, not a striped ceiling.
	for slat_x in [-2.20, -1.10, 0.0, 1.10, 2.20]:
		_add_box(parent, "TrainingRoostCeilingBaffle", Vector3(0.15, 0.06, 3.30), Vector3(slat_x, 3.50, -0.62), BIRCH.darkened(0.18), 0.76)

	var dado := _add_box(parent, "TrainingRoostNorthCutawayDado", Vector3(6.10, 0.46, 0.12), Vector3(0.0, 0.23, 2.70), BLUE_GREEN, 0.84)
	dado.set_meta(&"camera_facing_cutaway", true)
	_add_box(parent, "TrainingRoostNorthCutawayCap", Vector3(6.10, 0.07, 0.17), Vector3(0.0, 0.495, 2.69), BRASS.darkened(0.12), 0.54, 0.34)
	for wing_x in [-2.42, 2.42]:
		var glass := _add_glass_box(parent, "TrainingRoostNorthReededGlass", Vector3(1.08, 1.68, 0.04), Vector3(wing_x, 1.40, 2.68))
		glass.set_meta(&"cutaway_wing", true)
		for reed_x in [-0.34, 0.0, 0.34]:
			_add_box(parent, "TrainingRoostNorthGlassReed", Vector3(0.025, 1.56, 0.055), Vector3(wing_x + reed_x, 1.40, 2.675), CREAM.darkened(0.24), 0.62)
	var east_glass := _add_glass_box(parent, "TrainingRoostEastReededGlass", Vector3(0.04, 2.10, 2.70), Vector3(2.99, 1.48, 0.72))
	east_glass.set_meta(&"camera_facing_cutaway", true)
	for reed_z in [-0.92, -0.46, 0.0, 0.46, 0.92]:
		_add_box(parent, "TrainingRoostEastGlassReed", Vector3(0.055, 2.00, 0.025), Vector3(2.985, 1.48, 0.72 + reed_z), CREAM.darkened(0.24), 0.62)

	# A room-wide lesson rail meets both front frame posts and caps the reeded
	# glass. The identity fascia is clipped directly into that teaching rail.
	var lesson_rail := _add_box(parent, "TrainingRoostLessonRail", Vector3(5.90, 0.14, 0.16), Vector3(0.0, 2.24, 2.65), BIRCH.darkened(0.18), 0.68)
	lesson_rail.set_meta(&"architectural_mount", &"lesson_rail")
	var identity_host := _add_box(lesson_rail, "TrainingRoostIdentityHost", Vector3(3.64, 0.44, 0.11), Vector3(0.0, 0.29, -0.035), DEEP_TEAL, 0.74)
	identity_host.set_meta(&"architectural_mount", &"lesson_rail")
	for clamp_index in 3:
		var clamp_x: float = -1.35 + float(clamp_index) * 1.35
		_add_box(lesson_rail, "TrainingRoostLessonRailClamp_%02d" % (clamp_index + 1), Vector3(0.09, 0.28, 0.06), Vector3(clamp_x, 0.17, -0.055), BRASS.darkened(0.10), 0.52, 0.42)
	EnvironmentalSignageScript.add_panel(identity_host, "TrainingRoostIdentity", "TRAINING ROOST\nPRACTICE & ACCREDITATION", Vector3(0.0, 0.0, 0.058), Vector2(3.34, 0.38), DEEP_TEAL, CREAM, Vector3.ZERO, 14, 0.0028, &"primary", &"destination")


func _build_metrics_console(parent: Node3D) -> void:
	var console := Node3D.new()
	console.name = "TrainingTermsConsole"
	console.position = Vector3(0.0, 0.0, -2.48)
	parent.add_child(console)
	_add_box(console, "TrainingConsoleCabinet", Vector3(2.22, 1.08, 0.24), Vector3(0.0, 1.78, 0.0), WALNUT, 0.74)
	var screen_host := _add_box(console, "TrainingTermsTerminalScreen", Vector3(1.94, 0.60, 0.08), Vector3(0.0, 1.86, 0.155), GRAPHITE, 0.48, 0.22)
	_status_label = EnvironmentalSignageScript.add_panel(screen_host, "TrainingRoostLiveTerms", "TRAINING TERMS · AWAITING SHIFT", Vector3(0.0, 0.0, 0.047), Vector2(1.72, 0.42), GRAPHITE, SCREEN_BLUE.lightened(0.24), Vector3.ZERO, 13, 0.0027, &"utility", &"screen", true)
	for pip_index in 6:
		_practice_pips.append(_add_box(console, "ActivePracticePip_%02d" % (pip_index + 1), Vector3(0.18, 0.08, 0.05), Vector3(-0.50 + pip_index * 0.20, 1.31, 0.17), GRAPHITE.darkened(0.12), 0.60))


func _new_level_root(root_name: String, level: int) -> Node3D:
	var level_root := Node3D.new()
	level_root.name = root_name
	level_root.set_meta(&"facility_level", level)
	owned_room_root.add_child(level_root)
	return level_root


func _build_practice_terminal(parent: Node3D, terminal_index: int, x: float, required_level: int, lane_color: Color) -> void:
	var terminal := Node3D.new()
	terminal.name = "ConnectedPracticeTerminal_%02d" % (terminal_index + 1)
	terminal.position = Vector3(x, 0.0, -0.95)
	terminal.set_meta(&"required_level", required_level)
	terminal.set_meta(&"intentionally_empty", true)
	parent.add_child(terminal)
	# A continuous steel frame ties desk, monitor, keyboard, and perch together.
	_add_box(terminal, "PracticeTerminalFoot", Vector3(1.20, 0.10, 1.32), Vector3(0.0, 0.05, 0.0), GRAPHITE, 0.50, 0.32)
	for leg_x in [-0.48, 0.48]:
		_add_box(terminal, "PracticeTerminalLeg", Vector3(0.10, 0.78, 0.10), Vector3(leg_x, 0.41, -0.20), GRAPHITE, 0.48, 0.34)
	_add_box(terminal, "PracticeTerminalDesk", Vector3(1.28, 0.13, 0.74), Vector3(0.0, 0.82, -0.20), BIRCH, 0.76)
	_add_box(terminal, "PracticeMonitorArm", Vector3(0.10, 0.56, 0.10), Vector3(0.0, 1.10, -0.44), GRAPHITE, 0.46, 0.34)
	_add_box(terminal, "PracticeMonitorFrame", Vector3(0.86, 0.62, 0.11), Vector3(0.0, 1.48, -0.43), GRAPHITE, 0.46, 0.24)
	var screen := _add_box(terminal, "PracticeMonitorScreen", Vector3(0.75, 0.50, 0.024), Vector3(0.0, 1.48, -0.368), lane_color.darkened(0.18), 0.54)
	screen.material_override = _emissive_material(lane_color, 0.54)
	_add_box(terminal, "PracticeKeyboard", Vector3(0.72, 0.055, 0.27), Vector3(0.0, 0.91, -0.02), GRAPHITE.lightened(0.06), 0.62)
	_add_box(terminal, "PracticePerchBase", Vector3(0.82, 0.12, 0.62), Vector3(0.0, 0.12, 0.48), WALNUT, 0.72)
	_add_cylinder(terminal, "PracticePerchRail", Vector3(0.0, 0.48, 0.48), 0.055, 0.72, BRASS.darkened(0.08), 0.52, 0.40).rotation_degrees.z = 90.0
	_add_box(terminal, "PracticePerchBack", Vector3(0.78, 0.62, 0.12), Vector3(0.0, 0.62, 0.76), WALNUT, 0.74)
	var terminal_plate := _add_box(terminal, "PracticeTerminalLanePlateHost", Vector3(0.84, 0.20, 0.05), Vector3(0.0, 0.58, -0.57), lane_color.darkened(0.20), 0.78)
	EnvironmentalSignageScript.add_panel(terminal_plate, "PracticeTerminalLanePlate_%02d" % (terminal_index + 1), "PRACTICE %02d" % (terminal_index + 1), Vector3(0.0, 0.0, 0.032), Vector2(0.72, 0.13), lane_color.darkened(0.20), CREAM, Vector3.ZERO, 10, 0.0022, &"utility", &"machine")
	_practice_terminals.append(terminal)


func _build_practice_track(parent: Node3D) -> void:
	var manual_shelf := Node3D.new()
	manual_shelf.name = "PracticeManualShelf"
	manual_shelf.position = Vector3(-2.40, 0.0, 0.82)
	parent.add_child(manual_shelf)
	_add_box(manual_shelf, "PracticeManualShelfBody", Vector3(1.05, 1.50, 0.64), Vector3(0.0, 0.75, 0.0), WALNUT, 0.76)
	for manual_index in 4:
		_add_box(manual_shelf, "PracticeManual_%02d" % (manual_index + 1), Vector3(0.16, 0.54, 0.42), Vector3(-0.30 + manual_index * 0.20, 0.80, 0.34), [LANE_NEST, BIRCH, PALE_BLUE, DEEP_TEAL][manual_index], 0.90)
	var track_host := _add_box(parent, "PracticeTrackHost", Vector3(1.98, 0.48, 0.09), Vector3(1.92, 1.42, -2.57), ENAMEL_TEAL, 0.76)
	EnvironmentalSignageScript.add_panel(track_host, "PracticeTrackPlate", "OBSERVE · TRY · REVIEW", Vector3(0.0, 0.0, 0.052), Vector2(1.76, 0.31), ENAMEL_TEAL, CREAM, Vector3.ZERO, 11, 0.0024, &"utility", &"machine")


func _build_cross_lane_hardware(parent: Node3D) -> void:
	var rack := Node3D.new()
	rack.name = "CrossLaneTeachingRack"
	rack.position = Vector3(2.40, 0.0, 0.72)
	parent.add_child(rack)
	_add_box(rack, "CrossLaneRackFrame", Vector3(1.06, 1.72, 0.72), Vector3(0.0, 0.86, 0.0), DARK_WALNUT, 0.76)
	for lane_index in 3:
		var color := [LANE_NEST, LANE_PREDATOR, LANE_APPEALS][lane_index] as Color
		_add_box(rack, "CrossLaneManualTray_%02d" % (lane_index + 1), Vector3(0.88, 0.34, 0.58), Vector3(0.0, 0.38 + lane_index * 0.48, 0.10), color, 0.88)
		_add_box(rack, "CrossLaneSampleToken_%02d" % (lane_index + 1), Vector3(0.54, 0.07, 0.24), Vector3(0.0, 0.59 + lane_index * 0.48, 0.41), color.lightened(0.14), 0.80)
	var classroom_host := _add_box(parent, "CrossLaneClassroomPlateHost", Vector3(2.06, 0.30, 0.08), Vector3(-1.92, 2.55, -2.58), DEEP_TEAL, 0.74)
	EnvironmentalSignageScript.add_panel(classroom_host, "CrossLaneClassroomPlate", "CROSS-LANE CLASSROOM", Vector3(0.0, 0.0, 0.047), Vector2(1.84, 0.21), DEEP_TEAL, CREAM, Vector3.ZERO, 11, 0.0024, &"utility", &"machine")


func _build_credential_gallery(parent: Node3D) -> void:
	var press := Node3D.new()
	press.name = "CredentialEmbossingPress"
	press.position = Vector3(-2.42, 0.0, 0.66)
	parent.add_child(press)
	_add_box(press, "CredentialPressCabinet", Vector3(1.02, 1.18, 0.72), Vector3(0.0, 0.59, 0.0), DARK_WALNUT, 0.72)
	_add_box(press, "CredentialPressPlaten", Vector3(0.70, 0.12, 0.52), Vector3(0.0, 1.24, 0.0), GRAPHITE, 0.46, 0.36)
	_add_box(press, "CredentialPressColumn", Vector3(0.12, 0.72, 0.12), Vector3(0.28, 1.48, 0.08), BRASS.darkened(0.10), 0.48, 0.44)
	var handle := _add_cylinder(press, "CredentialPressHandle", Vector3(0.03, 1.72, 0.08), 0.035, 0.58, WALNUT, 0.60)
	handle.rotation_degrees.z = 90.0

	var gallery := Node3D.new()
	gallery.name = "AuthoritativeCredentialGallery"
	gallery.position = Vector3(0.78, 0.0, -2.55)
	gallery.set_meta(&"authoritative_records_only", true)
	parent.add_child(gallery)
	_add_box(gallery, "CredentialGalleryRail", Vector3(4.10, 0.12, 0.12), Vector3(0.0, 2.52, 0.0), BRASS.darkened(0.10), 0.50, 0.42)
	_add_box(gallery, "CredentialGalleryBack", Vector3(4.26, 0.98, 0.07), Vector3(0.0, 2.02, -0.02), ENAMEL_TEAL, 0.84)
	_credential_header_label = EnvironmentalSignageScript.add_panel(gallery, "CredentialGalleryHeader", "AUTHORIZED · WORKED · ACCREDITED", Vector3(0.0, 2.36, 0.045), Vector2(3.70, 0.28), ENAMEL_TEAL, CREAM, Vector3.ZERO, 11, 0.0024, &"secondary", &"machine")
	_credential_tag_root = Node3D.new()
	_credential_tag_root.name = "EarnedCredentialTags"
	_credential_tag_root.position = Vector3(0.0, 0.0, 0.04)
	gallery.add_child(_credential_tag_root)


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
	if _status_label != null:
		if _has_training_metrics:
			_status_label.text = "$%.2f · WORK %d%% · XP +%d" % [_sponsorship_cost_cents / 100.0, roundi(_training_work_basis_points / 100.0), _coaching_xp_bonus]
		else:
			_status_label.text = "TRAINING TERMS · AWAITING SHIFT"
		EnvironmentalSignageScript.refit_label(_status_label)
	for pip_index in _practice_pips.size():
		_practice_pips[pip_index].material_override = _emissive_material(SCREEN_BLUE, 0.78) if pip_index < mini(_active_trainee_count, _practice_pips.size()) else _material(GRAPHITE.darkened(0.12), 0.60)


func _read_worker_records(snapshot: Dictionary) -> void:
	_active_trainee_count = 0
	_credential_records.clear()
	var workers_variant: Variant = snapshot.get("workers", [])
	if not (workers_variant is Array):
		return
	for worker_variant in workers_variant as Array:
		if not (worker_variant is Dictionary):
			continue
		var worker := worker_variant as Dictionary
		if not bool(worker.get("employed", true)):
			continue
		var training_target := String(worker.get(
			"cross_training_target_name",
			worker.get("cross_training_target", ""),
		)).strip_edges()
		var training_active := bool(worker.get(
			"cross_training_active",
			worker.get("cross_training_pending", not training_target.is_empty()),
		))
		if training_active or not training_target.is_empty():
			_active_trainee_count += 1
		var specialty := String(worker.get(
			"secondary_specialty_name",
			worker.get("secondary_specialty", ""),
		)).strip_edges()
		if specialty.is_empty() or specialty.to_lower() in ["none", "unassigned", "unfiled"]:
			continue
		_credential_records.append({
			"worker_id": int(worker.get("id", worker.get("worker_id", -1))),
			"worker_name": String(worker.get("display_name", worker.get("name", "FLOCK MEMBER"))).strip_edges(),
			"specialty": specialty,
		})
		if _credential_records.size() >= 6:
			break


func _rebuild_credential_tags() -> void:
	_credential_tags.clear()
	if _credential_tag_root == null:
		return
	for child in _credential_tag_root.get_children():
		child.free()
	if _facility_level < 3:
		return
	for record_index in _credential_records.size():
		var record := _credential_records[record_index]
		var tag := Node3D.new()
		tag.name = "EarnedCredentialTag_%02d" % (record_index + 1)
		tag.position = Vector3(-1.50 + (record_index % 3) * 1.50, 2.05 - int(record_index / 3) * 0.42, 0.0)
		tag.set_meta(&"authoritative_record", true)
		tag.set_meta(&"worker_id", int(record.get("worker_id", -1)))
		tag.set_meta(&"secondary_specialty", String(record.get("specialty", "")))
		_credential_tag_root.add_child(tag)
		var tag_color := [LANE_NEST, LANE_PREDATOR, LANE_APPEALS][record_index % 3] as Color
		var tag_host := _add_box(tag, "CredentialTagHost", Vector3(1.28, 0.31, 0.06), Vector3.ZERO, tag_color.darkened(0.18), 0.82)
		var worker_name := String(record.get("worker_name", "FLOCK MEMBER")).to_upper()
		var specialty := String(record.get("specialty", "ACCREDITED")).to_upper()
		EnvironmentalSignageScript.add_panel(tag_host, "EarnedCredentialCopy_%02d" % (record_index + 1), "%s\n%s" % [worker_name, specialty], Vector3(0.0, 0.0, 0.038), Vector2(1.14, 0.23), tag_color.darkened(0.18), CREAM, Vector3.ZERO, 10, 0.0021, &"utility", &"machine")
		_credential_tags.append(tag)


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


func _snapshot_facility_level(snapshot: Dictionary, catalog_entry: Dictionary) -> int:
	var owned_variant: Variant = snapshot.get("owned_facilities", {})
	if owned_variant is Dictionary:
		var owned := owned_variant as Dictionary
		if owned.has(FACILITY_ID) or owned.has(String(FACILITY_ID)):
			return _level_from_variant(owned.get(FACILITY_ID, owned.get(String(FACILITY_ID), 0)))
	if not catalog_entry.is_empty():
		var catalog_level := int(catalog_entry.get("level", catalog_entry.get("owned_level", 0)))
		if catalog_level > 0:
			return catalog_level
		if bool(catalog_entry.get("installed", catalog_entry.get("owned", false))):
			return 1
	var care := _dictionary(snapshot.get("flock_care", {}))
	for source in [_dictionary(care.get("training", {})), _dictionary(care.get("training_roost", {})), care, _dictionary(snapshot.get("facility_effects", {}))]:
		for key in [&"level", &"training_roost_level", &"training_level"]:
			if source.has(key) or source.has(String(key)):
				return int(source.get(key, source.get(String(key), 0)))
	return 0


func _catalog_entry(snapshot: Dictionary) -> Dictionary:
	var catalog_variant: Variant = snapshot.get("facility_catalog", [])
	if catalog_variant is Array:
		for entry_variant in catalog_variant as Array:
			if entry_variant is Dictionary:
				var entry := entry_variant as Dictionary
				if StringName(String(entry.get("id", ""))) == FACILITY_ID:
					return entry
	elif catalog_variant is Dictionary:
		var catalog := catalog_variant as Dictionary
		var entry_variant: Variant = catalog.get(FACILITY_ID, catalog.get(String(FACILITY_ID), {}))
		if entry_variant is Dictionary:
			return entry_variant as Dictionary
	return {}


func _metric_variant(snapshot: Dictionary, keys: Array[StringName]) -> Variant:
	var care := _dictionary(snapshot.get("flock_care", {}))
	var sources: Array[Dictionary] = [
		_dictionary(care.get("training", {})),
		_dictionary(care.get("training_roost", {})),
		_dictionary(care.get("training_terms", {})),
		care,
		_dictionary(snapshot.get("facility_effects", {})),
		snapshot,
	]
	for source in sources:
		for key in keys:
			if source.has(key):
				return source[key]
			if source.has(String(key)):
				return source[String(key)]
	return null


func _level_from_variant(value: Variant) -> int:
	if value is Dictionary:
		var record := value as Dictionary
		return int(record.get("level", record.get("owned_level", 1 if bool(record.get("owned", false)) else 0)))
	if value is bool:
		return 1 if bool(value) else 0
	return int(value)


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
	mesh.top_radius = radius * 0.96
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color, roughness, metallic)
	parent.add_child(instance)
	return instance


func _add_glass_box(parent: Node3D, part_name: String, size: Vector3, part_position: Vector3) -> MeshInstance3D:
	var glass := _add_box(parent, part_name, size, part_position, GLASS, 0.24, 0.04)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return glass


func _material(color: Color, roughness: float = 0.82, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "%s_%.2f_%.2f" % [color.to_html(true), roughness, metallic]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material_cache[key] = material
	return material


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var key := "emissive_%s_%.2f" % [color.to_html(true), energy]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.40)
	material.roughness = 0.42
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.resource_local_to_scene = true
	_material_cache[key] = material
	return material
