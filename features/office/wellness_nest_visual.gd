class_name WellnessNestVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## A visual-only, snapshot-driven recovery facility on the east campus. Every
## tier is cumulative and every substantial prop stays inside the authored
## parcel. The room intentionally contributes no collision or navigation nodes.
const FACILITY_ID: StringName = &"wellness_nest_room"
const FACILITY_CENTER := Vector3(15.20, 0.0, 18.00)
const FOCUS_POINT := Vector3(15.20, 1.05, 18.00)
const FOOTPRINT := Rect2(Vector2(12.00, 15.10), Vector2(6.40, 5.80))
const MAX_LEVEL := 3
const MAX_OPAQUE_HEIGHT := 3.55

const DEEP_SAGE := Color("29433d")
const SAGE := Color("71887a")
const PALE_SAGE := Color("9cab93")
const OATMEAL := Color("d8c9aa")
const CREAM := Color("eee4ca")
const FELT := Color("87947f")
const TERRACOTTA := Color("a8604f")
const WALNUT := Color("6d4e37")
const DARK_WALNUT := Color("47372d")
const BRASS := Color("c3a257")
const GRAPHITE := Color("31393a")
const AMBER := Color("e0b45e")
const REST_GREEN := Color("75a276")
const GLASS := Color("8eb1a562")

var locked_marker_root: Node3D
var survey_site_root: Node3D
var owned_room_root: Node3D
var level_1_root: Node3D
var level_2_root: Node3D
var level_3_root: Node3D

var _nests: Array[Node3D] = []
var _strain_pips: Array[MeshInstance3D] = []
var _rest_pips: Array[MeshInstance3D] = []
var _welfare_pips: Array[MeshInstance3D] = []
var _status_label: Label3D
var _welfare_label: Label3D
var _warm_light: OmniLight3D
var _material_cache: Dictionary[String, StandardMaterial3D] = {}

var _built := false
var _has_applied_snapshot := false
var _unlocked := false
var _facility_level := 0
var _has_care_metrics := false
var _strain_basis_points := 0
var _rest_basis_points := 0
var _welfare := 0
var _rested_gate := 72


func _ready() -> void:
	name = "WellnessNestVisual"
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
	_nests.clear()
	_strain_pips.clear()
	_rest_pips.clear()
	_welfare_pips.clear()
	_status_label = null
	_welfare_label = null
	_warm_light = null
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

	var strain_value: Variant = _metric_variant(snapshot, [
		&"wellness_strain_gain_basis_points", &"strain_gain_basis_points",
	])
	var rest_value: Variant = _metric_variant(snapshot, [
		&"wellness_break_recovery_basis_points", &"break_recovery_basis_points",
	])
	_has_care_metrics = strain_value != null or rest_value != null
	_strain_basis_points = clampi(int(strain_value if strain_value != null else 0), 0, 20_000)
	_rest_basis_points = clampi(int(rest_value if rest_value != null else 0), 0, 20_000)
	var welfare_value: Variant = _metric_variant(snapshot, [&"welfare", &"flock_welfare"])
	var gate_value: Variant = _metric_variant(snapshot, [&"rested_flock_gate"])
	_welfare = clampi(int(welfare_value if welfare_value != null else 0), 0, 100)
	_rested_gate = clampi(int(gate_value if gate_value != null else 72), 1, 100)

	_apply_visibility()
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


func nest_count() -> int:
	return _nests.size()


func visible_nest_count() -> int:
	var count := 0
	for nest in _nests:
		if int(nest.get_meta(&"required_level", 99)) <= _facility_level:
			count += 1
	return count


func care_status_text() -> String:
	return _status_label.text if _status_label != null else ""


func has_authoritative_metrics() -> bool:
	return _has_care_metrics


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
		"visible_nests": visible_nest_count(),
		"has_care_metrics": _has_care_metrics,
		"strain_basis_points": _strain_basis_points,
		"rest_basis_points": _rest_basis_points,
		"welfare": _welfare,
		"rested_gate": _rested_gate,
		"footprint": FOOTPRINT,
		"focus_point": FOCUS_POINT,
	}


func _build_locked_marker() -> void:
	locked_marker_root = Node3D.new()
	locked_marker_root.name = "WellnessNestLockedParcel"
	locked_marker_root.set_meta(&"facility_state", &"locked")
	add_child(locked_marker_root)
	_add_box(locked_marker_root, "WellnessLockedGround", Vector3(6.34, 0.035, 5.74), Vector3(0.0, -0.016, 0.0), GRAPHITE.darkened(0.08), 0.96)
	for corner in [Vector3(-2.88, 0.34, -2.46), Vector3(2.88, 0.34, -2.46), Vector3(-2.88, 0.34, 2.46), Vector3(2.88, 0.34, 2.46)]:
		_add_box(locked_marker_root, "RecoveryParcelStake", Vector3(0.09, 0.68, 0.09), corner, WALNUT, 0.76)
	var notice_host := _add_box(locked_marker_root, "RecoveryParcelReviewHost", Vector3(3.18, 0.72, 0.11), Vector3(0.0, 0.86, 2.45), DEEP_SAGE, 0.78)
	EnvironmentalSignageScript.add_panel(notice_host, "WellnessNestLockedNotice", "RECOVERY PARCEL\nSTANDING REVIEW", Vector3(0.0, 0.0, 0.064), Vector2(2.90, 0.50), DEEP_SAGE, CREAM, Vector3.ZERO, 14, 0.0028, &"secondary", &"machine")


func _build_survey_site() -> void:
	survey_site_root = Node3D.new()
	survey_site_root.name = "WellnessNestSurveySite"
	survey_site_root.set_meta(&"facility_state", &"survey")
	add_child(survey_site_root)
	_add_box(survey_site_root, "WellnessSurveyFoundation", Vector3(6.34, 0.10, 5.74), Vector3(0.0, -0.04, 0.0), SAGE.darkened(0.32), 0.94)
	for grid_x in [-2.0, 0.0, 2.0]:
		_add_box(survey_site_root, "WellnessSurveyRuleX", Vector3(0.025, 0.008, 5.22), Vector3(grid_x, 0.015, 0.0), CREAM.darkened(0.20), 0.96)
	for grid_z in [-1.72, 0.0, 1.72]:
		_add_box(survey_site_root, "WellnessSurveyRuleZ", Vector3(5.72, 0.008, 0.025), Vector3(0.0, 0.016, grid_z), CREAM.darkened(0.20), 0.96)
	var material_bench := Node3D.new()
	material_bench.name = "RecoveryMaterialSampleBench"
	material_bench.position = Vector3(-1.55, 0.0, 0.60)
	survey_site_root.add_child(material_bench)
	_add_box(material_bench, "SampleBenchTop", Vector3(1.82, 0.10, 0.82), Vector3(0.0, 0.76, 0.0), WALNUT, 0.72)
	for leg_x in [-0.72, 0.72]:
		_add_box(material_bench, "SampleBenchLeg", Vector3(0.10, 0.72, 0.10), Vector3(leg_x, 0.36, 0.0), GRAPHITE, 0.58, 0.24)
	for sample_index in 3:
		_add_box(material_bench, "AcousticFeltSwatch_%02d" % (sample_index + 1), Vector3(0.48, 0.035, 0.46), Vector3(-0.58 + sample_index * 0.58, 0.83, 0.0), [SAGE, OATMEAL, TERRACOTTA][sample_index], 0.96)
	var survey_host := _add_box(survey_site_root, "RecoverySurveyNoticeHost", Vector3(3.30, 0.78, 0.11), Vector3(0.55, 0.78, 2.45), DEEP_SAGE, 0.78)
	EnvironmentalSignageScript.add_panel(survey_host, "WellnessNestSurveyNotice", "RECOVERY PARCEL\nWELFARE FILE PENDING", Vector3(0.0, 0.0, 0.064), Vector2(3.02, 0.55), DEEP_SAGE, CREAM, Vector3.ZERO, 14, 0.0028, &"secondary", &"machine")


func _build_owned_room() -> void:
	owned_room_root = Node3D.new()
	owned_room_root.name = "WellnessNestRoom"
	owned_room_root.set_meta(&"facility_state", &"owned")
	owned_room_root.set_meta(&"management_camera_cutaway", true)
	add_child(owned_room_root)
	_build_shell(owned_room_root)
	_build_metrics_console(owned_room_root)

	level_1_root = _new_level_root("QuietNestCubbies", 1)
	_build_nest(level_1_root, 0, -0.45, 1, OATMEAL)
	_build_nest(level_1_root, 1, 0.45, 1, PALE_SAGE)
	_build_quiet_nest_details(level_1_root)

	level_2_root = _new_level_root("RotatingRecoveryRoom", 2)
	_build_nest(level_2_root, 2, -1.35, 2, TERRACOTTA.lightened(0.12))
	_build_nest(level_2_root, 3, 1.35, 2, FELT)
	_build_rotation_details(level_2_root)

	level_3_root = _new_level_root("RestedFlockSuite", 3)
	_build_nest(level_3_root, 4, -2.25, 3, PALE_SAGE.lightened(0.08))
	_build_nest(level_3_root, 5, 2.25, 3, OATMEAL.lightened(0.05))
	_build_rested_suite_details(level_3_root)


func _build_shell(parent: Node3D) -> void:
	_add_box(parent, "WellnessNestConnectedPad", Vector3(6.36, 0.18, 5.76), Vector3(0.0, -0.10, 0.0), Color("515b56"), 0.94)
	_add_box(parent, "WellnessNestFloorInset", Vector3(6.06, 0.025, 5.46), Vector3(0.0, 0.004, 0.0), Color("6d756c"), 0.94)
	_add_box(parent, "WellnessNestOatmealRug", Vector3(4.82, 0.018, 2.66), Vector3(0.0, 0.020, -0.60), OATMEAL.darkened(0.08), 0.98)
	_add_box(parent, "WellnessNestBackWall", Vector3(6.10, 2.68, 0.12), Vector3(0.0, 1.34, -2.70), DEEP_SAGE, 0.78)
	_add_box(parent, "WellnessNestBackWallDado", Vector3(6.12, 0.72, 0.15), Vector3(0.0, 0.38, -2.62), WALNUT, 0.72)

	for post_x in [-3.05, 3.05]:
		for post_z in [-2.64, 2.64]:
			_add_box(parent, "WellnessNestFramePost", Vector3(0.13, 3.30, 0.13), Vector3(post_x, 1.65, post_z), DEEP_SAGE, 0.66, 0.12)
	for beam_z in [-2.63, 2.63]:
		_add_box(parent, "WellnessNestFrameBeam", Vector3(6.06, 0.13, 0.13), Vector3(0.0, 3.34, beam_z), DEEP_SAGE, 0.64, 0.14)
	# Five short, slim slats define an acoustic canopy over the rear cubbies.
	# Keeping the public/front third open prevents the isometric camera from
	# reading the canopy as a heavy lid over the room.
	for slat_x in [-2.20, -1.10, 0.0, 1.10, 2.20]:
		_add_box(parent, "WellnessNestCanopySlat", Vector3(0.18, 0.06, 3.40), Vector3(slat_x, 3.50, -0.58), WALNUT.darkened(0.04), 0.72)

	# Positive X and positive Z are the management-camera elevations. Keep both
	# elevations transparent above a low dado so the cozy interior remains clear.
	var dado := _add_box(parent, "WellnessNestNorthCutawayDado", Vector3(6.10, 0.46, 0.12), Vector3(0.0, 0.23, 2.70), SAGE, 0.84)
	dado.set_meta(&"camera_facing_cutaway", true)
	_add_box(parent, "WellnessNestNorthCutawayCap", Vector3(6.10, 0.07, 0.17), Vector3(0.0, 0.495, 2.69), BRASS.darkened(0.12), 0.54, 0.34)
	for wing_x in [-2.42, 2.42]:
		var glass := _add_glass_box(parent, "WellnessNestNorthReededGlass", Vector3(1.08, 1.68, 0.04), Vector3(wing_x, 1.40, 2.68))
		glass.set_meta(&"cutaway_wing", true)
		for reed_x in [-0.34, 0.0, 0.34]:
			_add_box(parent, "WellnessNestNorthGlassReed", Vector3(0.025, 1.56, 0.055), Vector3(wing_x + reed_x, 1.40, 2.675), CREAM.darkened(0.24), 0.62)
	var east_glass := _add_glass_box(parent, "WellnessNestEastReededGlass", Vector3(0.04, 2.10, 2.70), Vector3(2.99, 1.48, 0.72))
	east_glass.set_meta(&"camera_facing_cutaway", true)
	for reed_z in [-0.92, -0.46, 0.0, 0.46, 0.92]:
		_add_box(parent, "WellnessNestEastGlassReed", Vector3(0.055, 2.00, 0.025), Vector3(2.985, 1.48, 0.72 + reed_z), CREAM.darkened(0.24), 0.62)

	# The recovery identity is the lintel of the open central bay. Its jambs land
	# on the dado cap and overlap the inner edges of the reeded-glass wings, so the
	# lettering reads as part of the quiet-room joinery instead of a hanging card.
	for jamb_index in 2:
		var jamb_x: float = -1.83 if jamb_index == 0 else 1.83
		_add_box(parent, "WellnessNestIdentityLintelJamb_%02d" % (jamb_index + 1), Vector3(0.10, 1.62, 0.13), Vector3(jamb_x, 1.31, 2.66), DEEP_SAGE.darkened(0.04), 0.68)
	var identity_host := _add_box(parent, "WellnessNestIdentityHost", Vector3(3.55, 0.46, 0.13), Vector3(0.0, 2.35, 2.63), DEEP_SAGE, 0.74)
	identity_host.set_meta(&"architectural_mount", &"recovery_lintel")
	identity_host.set_meta(&"lintel_integrated", true)
	_add_box(identity_host, "WellnessNestIdentityLintelTopCap", Vector3(3.67, 0.07, 0.17), Vector3(0.0, 0.245, 0.0), BRASS.darkened(0.12), 0.54, 0.34)
	_add_box(identity_host, "WellnessNestIdentityLintelBottomCap", Vector3(3.67, 0.07, 0.17), Vector3(0.0, -0.245, 0.0), WALNUT.darkened(0.04), 0.70)
	EnvironmentalSignageScript.add_panel(identity_host, "WellnessNestIdentity", "WELLNESS NEST\nRECOVERY & REST", Vector3(0.0, 0.0, 0.070), Vector2(3.26, 0.38), DEEP_SAGE, CREAM, Vector3.ZERO, 14, 0.0028, &"primary", &"destination")

	var pendant := Node3D.new()
	pendant.name = "WellnessNestWarmPendant"
	parent.add_child(pendant)
	_add_cylinder(pendant, "WellnessPendantRose", Vector3(0.0, 3.40, 0.30), 0.18, 0.08, BRASS.darkened(0.10), 0.44, 0.44)
	_add_cylinder(pendant, "WellnessPendantStem", Vector3(0.0, 3.05, 0.30), 0.025, 0.64, GRAPHITE, 0.48, 0.34)
	_add_cylinder(pendant, "WellnessPendantShade", Vector3(0.0, 2.68, 0.30), 0.34, 0.24, OATMEAL, 0.72)
	_warm_light = OmniLight3D.new()
	_warm_light.name = "WellnessNestWarmLight"
	_warm_light.position = Vector3(0.0, 2.48, 0.30)
	_warm_light.light_color = Color("ffd89a")
	_warm_light.light_energy = 0.88
	_warm_light.omni_range = 5.4
	_warm_light.shadow_enabled = false
	pendant.add_child(_warm_light)


func _build_metrics_console(parent: Node3D) -> void:
	var console := Node3D.new()
	console.name = "WellnessCareMetricsConsole"
	console.position = Vector3(0.0, 0.0, -2.48)
	parent.add_child(console)
	_add_box(console, "CareConsoleCabinet", Vector3(2.08, 1.12, 0.24), Vector3(0.0, 1.76, 0.0), WALNUT, 0.74)
	var screen_host := _add_box(console, "CareMetricsTerminalScreen", Vector3(1.78, 0.60, 0.08), Vector3(0.0, 1.83, 0.155), GRAPHITE, 0.48, 0.22)
	_status_label = EnvironmentalSignageScript.add_panel(screen_host, "WellnessCareLiveMetrics", "CARE METRICS · AWAITING SHIFT", Vector3(0.0, 0.0, 0.047), Vector2(1.57, 0.42), GRAPHITE, REST_GREEN.lightened(0.26), Vector3.ZERO, 13, 0.0027, &"utility", &"screen", true)
	for pip_index in 10:
		var strain_pip := _add_box(console, "StrainGaugePip_%02d" % (pip_index + 1), Vector3(0.12, 0.065, 0.05), Vector3(-0.64 + pip_index * 0.142, 1.35, 0.17), GRAPHITE.darkened(0.12), 0.60)
		var rest_pip := _add_box(console, "RestGaugePip_%02d" % (pip_index + 1), Vector3(0.12, 0.065, 0.05), Vector3(-0.64 + pip_index * 0.142, 1.22, 0.17), GRAPHITE.darkened(0.12), 0.60)
		_strain_pips.append(strain_pip)
		_rest_pips.append(rest_pip)


func _new_level_root(root_name: String, level: int) -> Node3D:
	var level_root := Node3D.new()
	level_root.name = root_name
	level_root.set_meta(&"facility_level", level)
	owned_room_root.add_child(level_root)
	return level_root


func _build_nest(parent: Node3D, nest_index: int, x: float, required_level: int, cushion_color: Color) -> void:
	var nest := Node3D.new()
	nest.name = "ConnectedRecoveryNest_%02d" % (nest_index + 1)
	nest.position = Vector3(x, 0.0, -1.46)
	nest.set_meta(&"required_level", required_level)
	nest.set_meta(&"intentionally_empty", true)
	parent.add_child(nest)
	# Plinth, back, canopy, and basket overlap deliberately so the fixture reads
	# as one built-in cubby instead of a collection of floating primitives.
	_add_box(nest, "RecoveryNestPlinth", Vector3(0.82, 0.18, 0.94), Vector3(0.0, 0.09, 0.0), DARK_WALNUT, 0.74)
	_add_box(nest, "RecoveryNestUpright", Vector3(0.82, 1.12, 0.13), Vector3(0.0, 0.65, -0.40), WALNUT, 0.72)
	_add_box(nest, "RecoveryNestCanopy", Vector3(0.82, 0.12, 0.92), Vector3(0.0, 1.20, 0.0), WALNUT, 0.72)
	_add_box(nest, "RecoveryNestSideLeft", Vector3(0.10, 0.96, 0.84), Vector3(-0.36, 0.66, 0.0), WALNUT, 0.74)
	_add_box(nest, "RecoveryNestSideRight", Vector3(0.10, 0.96, 0.84), Vector3(0.36, 0.66, 0.0), WALNUT, 0.74)
	_add_sphere(nest, "PuffyNestCushion", Vector3(0.0, 0.39, 0.03), Vector3(0.62, 0.22, 0.58), cushion_color, 16, 8)
	_add_cylinder(nest, "NestFrontBolster", Vector3(0.0, 0.43, 0.32), 0.095, 0.62, cushion_color.darkened(0.08), 0.94).rotation_degrees.z = 90.0
	_add_cylinder(nest, "NestPerchRail", Vector3(0.0, 0.26, 0.47), 0.045, 0.70, BRASS.darkened(0.10), 0.52, 0.38).rotation_degrees.z = 90.0
	_nests.append(nest)


func _build_quiet_nest_details(parent: Node3D) -> void:
	for panel_index in 3:
		var panel := _add_box(parent, "QuietNestAcousticPanel_%02d" % (panel_index + 1), Vector3(0.72, 0.68, 0.045), Vector3(-0.78 + panel_index * 0.78, 2.34, -2.60), [FELT, OATMEAL, PALE_SAGE][panel_index], 0.98)
		panel.set_meta(&"acoustic_felt", true)
	var tier_host := _add_box(parent, "QuietNestCubbiesPlateHost", Vector3(1.82, 0.28, 0.07), Vector3(-1.94, 2.78, -2.58), DEEP_SAGE, 0.74)
	EnvironmentalSignageScript.add_panel(tier_host, "QuietNestCubbiesPlate", "QUIET NEST CUBBIES", Vector3(0.0, 0.0, 0.042), Vector2(1.62, 0.19), DEEP_SAGE, CREAM, Vector3.ZERO, 11, 0.0024, &"utility", &"machine")


func _build_rotation_details(parent: Node3D) -> void:
	var hutch := Node3D.new()
	hutch.name = "RecoveryHydrationHutch"
	hutch.position = Vector3(2.33, 0.0, 0.55)
	parent.add_child(hutch)
	_add_box(hutch, "HydrationHutchBody", Vector3(1.05, 1.60, 0.74), Vector3(0.0, 0.80, 0.0), WALNUT, 0.76)
	_add_box(hutch, "HydrationHutchDoor", Vector3(0.91, 0.78, 0.05), Vector3(0.0, 1.12, 0.398), PALE_SAGE, 0.90)
	_add_cylinder(hutch, "WaterCarafe", Vector3(-0.23, 0.36, 0.40), 0.13, 0.46, GLASS, 0.24)
	_add_box(hutch, "FeedTin", Vector3(0.34, 0.30, 0.24), Vector3(0.24, 0.28, 0.40), TERRACOTTA, 0.86)
	var wheel := Node3D.new()
	wheel.name = "RecoveryRotationWheel"
	wheel.position = Vector3(-2.39, 1.68, -2.58)
	parent.add_child(wheel)
	_add_cylinder(wheel, "RotationWheelFace", Vector3.ZERO, 0.52, 0.07, OATMEAL, 0.90).rotation_degrees.x = 90.0
	for spoke_index in 8:
		var spoke := _add_box(wheel, "RotationWheelSpoke", Vector3(0.036, 0.86, 0.035), Vector3.ZERO, BRASS.darkened(0.16), 0.58, 0.24)
		spoke.rotation_degrees.z = spoke_index * 22.5


func _build_rested_suite_details(parent: Node3D) -> void:
	var cabinet := Node3D.new()
	cabinet.name = "RestedFlockLinenCabinet"
	cabinet.position = Vector3(-2.40, 0.0, 0.63)
	parent.add_child(cabinet)
	_add_box(cabinet, "LinenCabinetBody", Vector3(1.10, 1.76, 0.78), Vector3(0.0, 0.88, 0.0), DARK_WALNUT, 0.76)
	for shelf_index in 3:
		_add_box(cabinet, "FoldedRecoveryLinen_%02d" % (shelf_index + 1), Vector3(0.76, 0.22, 0.49), Vector3(0.0, 0.38 + shelf_index * 0.49, 0.41), [OATMEAL, PALE_SAGE, CREAM][shelf_index], 0.96)
	var gauge_host := _add_box(parent, "RestedFlockGaugeHost", Vector3(2.28, 0.78, 0.09), Vector3(0.0, 1.08, 2.55), DEEP_SAGE, 0.76)
	_welfare_label = EnvironmentalSignageScript.add_panel(gauge_host, "RestedFlockLiveGauge", "RESTED FLOCK · FILE EMPTY", Vector3(0.0, 0.16, 0.052), Vector2(2.02, 0.32), DEEP_SAGE, CREAM, Vector3.ZERO, 12, 0.0025, &"utility", &"screen", true)
	for pip_index in 10:
		var pip := _add_box(gauge_host, "RestedFlockGaugePip_%02d" % (pip_index + 1), Vector3(0.145, 0.09, 0.045), Vector3(-0.74 + pip_index * 0.165, -0.24, 0.07), GRAPHITE.darkened(0.10), 0.58)
		_welfare_pips.append(pip)


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
		if _has_care_metrics:
			_status_label.text = "STRAIN %d%% · REST %d%%" % [roundi(_strain_basis_points / 100.0), roundi(_rest_basis_points / 100.0)]
		else:
			_status_label.text = "CARE METRICS · AWAITING SHIFT"
		EnvironmentalSignageScript.refit_label(_status_label)
	var strain_lit := clampi(roundi((20_000.0 - _strain_basis_points) / 2_000.0), 0, 10) if _has_care_metrics else 0
	var rest_lit := clampi(roundi(_rest_basis_points / 2_000.0), 0, 10) if _has_care_metrics else 0
	for pip_index in _strain_pips.size():
		_strain_pips[pip_index].material_override = _emissive_material(REST_GREEN, 0.72) if pip_index < strain_lit else _material(GRAPHITE.darkened(0.10), 0.60)
	for pip_index in _rest_pips.size():
		_rest_pips[pip_index].material_override = _emissive_material(AMBER, 0.72) if pip_index < rest_lit else _material(GRAPHITE.darkened(0.10), 0.60)
	var has_welfare := _metric_was_supplied()
	if _welfare_label != null:
		_welfare_label.text = "WELFARE %02d · GATE %02d" % [_welfare, _rested_gate] if has_welfare else "RESTED FLOCK · FILE EMPTY"
		EnvironmentalSignageScript.refit_label(_welfare_label)
	var welfare_lit := clampi(roundi(_welfare / 10.0), 0, 10) if has_welfare else 0
	for pip_index in _welfare_pips.size():
		var pip_color := REST_GREEN if _welfare >= _rested_gate else AMBER
		_welfare_pips[pip_index].material_override = _emissive_material(pip_color, 0.82) if pip_index < welfare_lit else _material(GRAPHITE.darkened(0.10), 0.60)


func _metric_was_supplied() -> bool:
	return _welfare > 0


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
	for source in [_dictionary(care.get("wellness", {})), _dictionary(care.get("wellness_nest", {})), care, _dictionary(snapshot.get("facility_effects", {}))]:
		for key in [&"level", &"wellness_nest_level", &"wellness_level"]:
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
		_dictionary(care.get("wellness", {})),
		_dictionary(care.get("wellness_nest", {})),
		_dictionary(care.get("recovery_effects", {})),
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


func _add_sphere(parent: Node3D, part_name: String, part_position: Vector3, part_scale: Vector3, color: Color, radial_segments: int = 16, rings: int = 8) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = radial_segments
	mesh.rings = rings
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.scale = part_scale
	instance.material_override = _material(color, 0.96)
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
