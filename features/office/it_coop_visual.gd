class_name ITCoopVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## Visual-only systems facility. Purchased hardware is cumulative; live lamps,
## worker jacks, risk terms, and invoices exist only when supplied by the
## authoritative operations snapshot.
const FACILITY_ID: StringName = &"it_coop"
const FACILITY_CENTER := Vector3(15.20, 0.0, 36.00)
const FOCUS_POINT := Vector3(15.20, 1.05, 36.00)
const FOOTPRINT := Rect2(Vector2(12.00, 33.10), Vector2(6.40, 5.80))
const MAX_LEVEL := 3
const MAX_OPAQUE_HEIGHT := 3.55
const MAX_AUTO_JACKS := 6
const QUEUE_PIPS_PER_LANE := 6

const LANE_ORDER: Array[StringName] = [&"nest_damage", &"predator_loss", &"appeals"]
const LANE_COLORS := {
	&"nest_damage": Color("73937b"),
	&"predator_loss": Color("aa6b5c"),
	&"appeals": Color("767f9e"),
}

const DEEP_TEAL := Color("243d40")
const ENAMEL_TEAL := Color("35575a")
const BLUE_GREEN := Color("52787b")
const PALE_BLUE := Color("8da9a5")
const GALVANIZED := Color("778486")
const STEEL := Color("566164")
const GRAPHITE := Color("293235")
const BIRCH := Color("c8ba9c")
const CREAM := Color("eee3c9")
const WALNUT := Color("644a38")
const BRASS := Color("bfa057")
const AMBER := Color("d4a650")
const STATUS_GREEN := Color("6f9d76")
const ALERT_RED := Color("a85d52")
const GLASS := Color("84a5a762")

var locked_marker_root: Node3D
var survey_site_root: Node3D
var owned_room_root: Node3D
var level_1_root: Node3D
var level_2_root: Node3D
var level_3_root: Node3D

var _systems_units: Array[Node3D] = []
var _queue_pips: Dictionary = {}
var _auto_jack_root: Node3D
var _auto_jacks: Array[Node3D] = []
var _patch_invoice_root: Node3D
var _patch_invoices: Array[Node3D] = []
var _automation_label: Label3D
var _load_label: Label3D
var _enabled_lamp: MeshInstance3D
var _secondary_lamp: MeshInstance3D
var _exposure_pips: Array[MeshInstance3D] = []
var _material_cache: Dictionary[String, StandardMaterial3D] = {}

var _built := false
var _has_applied_snapshot := false
var _unlocked := false
var _facility_level := 0
var _has_automation_metrics := false
var _automation_enabled := false
var _work_basis_points := 0
var _specialty_grace_minutes := 0
var _recognizes_secondary_specialties := false
var _compliance_exposure_millipoints := 0
var _ledger_patch_cost_cents := 0
var _spreadsheet_compliance_loss_millipoints := 0
var _spreadsheet_crack_basis_points := 0
var _auto_enrolled_workers := 0
var _active_auto_claims := 0
var _shift_exposure_applied := false
var _queue_counts: Dictionary = {}
var _auto_worker_records: Array[Dictionary] = []


func _ready() -> void:
	name = "ITCoopVisual"
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
	_systems_units.clear()
	_queue_pips.clear()
	_auto_jack_root = null
	_auto_jacks.clear()
	_patch_invoice_root = null
	_patch_invoices.clear()
	_automation_label = null
	_load_label = null
	_enabled_lamp = null
	_secondary_lamp = null
	_exposure_pips.clear()
	_material_cache.clear()
	_has_applied_snapshot = false
	_built = false


func apply_snapshot(snapshot: Dictionary) -> void:
	if not _built:
		build()
	var previous_level := _facility_level
	var catalog_entry := _catalog_entry(snapshot)
	var operations := _dictionary(snapshot.get("operations", {}))
	var automation := _dictionary(operations.get("automation", {}))
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

	_has_automation_metrics = (
		automation.has("work_basis_points")
		or automation.has("specialty_grace_minutes")
		or automation.has("compliance_exposure_millipoints")
	)
	_automation_enabled = bool(automation.get("enabled", false))
	_work_basis_points = clampi(int(automation.get("work_basis_points", 0)), 0, 20_000)
	_specialty_grace_minutes = maxi(0, int(automation.get("specialty_grace_minutes", 0)))
	_recognizes_secondary_specialties = bool(automation.get("recognizes_secondary_specialties", false))
	_compliance_exposure_millipoints = maxi(0, int(automation.get("compliance_exposure_millipoints", 0)))
	_ledger_patch_cost_cents = maxi(0, int(automation.get("ledger_patch_cost_cents", 0)))
	_spreadsheet_compliance_loss_millipoints = maxi(0, int(automation.get("spreadsheet_compliance_loss_millipoints", 0)))
	_spreadsheet_crack_basis_points = maxi(0, int(automation.get("spreadsheet_crack_basis_points", 0)))
	_auto_enrolled_workers = maxi(0, int(automation.get("auto_enrolled_workers", 0)))
	_active_auto_claims = maxi(0, int(automation.get("active_auto_claims", 0)))
	_shift_exposure_applied = bool(automation.get("shift_exposure_applied", false))
	_queue_counts = _dictionary(snapshot.get("claim_queue_counts", {})).duplicate()
	_read_auto_worker_records(snapshot)

	_apply_visibility()
	_rebuild_auto_worker_jacks()
	_rebuild_patch_invoice()
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


func systems_unit_count() -> int:
	return _systems_units.size()


func visible_systems_unit_count() -> int:
	var count := 0
	for unit in _systems_units:
		if int(unit.get_meta(&"required_level", 99)) <= _facility_level:
			count += 1
	return count


func visible_auto_worker_jack_count() -> int:
	return _auto_jacks.size() if _facility_level >= 2 else 0


func auto_worker_ids() -> Array[int]:
	var result: Array[int] = []
	if _facility_level < 2:
		return result
	for jack in _auto_jacks:
		result.append(int(jack.get_meta(&"worker_id", -1)))
	return result


func patch_invoice_visible() -> bool:
	return _facility_level >= 3 and not _patch_invoices.is_empty()


func automation_status_text() -> String:
	return _automation_label.text if _automation_label != null else ""


func load_status_text() -> String:
	return _load_label.text if _load_label != null else ""


func has_authoritative_metrics() -> bool:
	return _has_automation_metrics


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
		"visible_systems_units": visible_systems_unit_count(),
		"auto_worker_ids": auto_worker_ids(),
		"automation_enabled": _automation_enabled,
		"work_basis_points": _work_basis_points,
		"specialty_grace_minutes": _specialty_grace_minutes,
		"recognizes_secondary_specialties": _recognizes_secondary_specialties,
		"compliance_exposure_millipoints": _compliance_exposure_millipoints,
		"ledger_patch_cost_cents": _ledger_patch_cost_cents,
		"spreadsheet_compliance_loss_millipoints": _spreadsheet_compliance_loss_millipoints,
		"spreadsheet_crack_basis_points": _spreadsheet_crack_basis_points,
		"auto_enrolled_workers": _auto_enrolled_workers,
		"active_auto_claims": _active_auto_claims,
		"shift_exposure_applied": _shift_exposure_applied,
		"footprint": FOOTPRINT,
		"focus_point": FOCUS_POINT,
	}


func _build_locked_marker() -> void:
	locked_marker_root = Node3D.new()
	locked_marker_root.name = "ITCoopLockedParcel"
	locked_marker_root.set_meta(&"facility_state", &"locked")
	add_child(locked_marker_root)
	_add_box(locked_marker_root, "ITLockedGround", Vector3(6.34, 0.035, 5.74), Vector3(0.0, -0.016, 0.0), GRAPHITE.darkened(0.08), 0.96)
	for corner in [Vector3(-2.88, 0.34, -2.46), Vector3(2.88, 0.34, -2.46), Vector3(-2.88, 0.34, 2.46), Vector3(2.88, 0.34, 2.46)]:
		_add_box(locked_marker_root, "SystemsParcelStake", Vector3(0.09, 0.68, 0.09), corner, WALNUT, 0.76)
	var notice_host := _add_box(locked_marker_root, "SystemsParcelReviewHost", Vector3(3.24, 0.72, 0.11), Vector3(0.0, 0.86, 2.45), DEEP_TEAL, 0.78)
	EnvironmentalSignageScript.add_panel(notice_host, "ITCoopLockedNotice", "SYSTEMS PARCEL\nCAPITAL REVIEW", Vector3(0.0, 0.0, 0.064), Vector2(2.96, 0.50), DEEP_TEAL, CREAM, Vector3.ZERO, 14, 0.0028, &"secondary", &"machine")


func _build_survey_site() -> void:
	survey_site_root = Node3D.new()
	survey_site_root.name = "ITCoopSurveySite"
	survey_site_root.set_meta(&"facility_state", &"survey")
	add_child(survey_site_root)
	_add_box(survey_site_root, "ITSurveyFoundation", Vector3(6.34, 0.10, 5.74), Vector3(0.0, -0.04, 0.0), BLUE_GREEN.darkened(0.38), 0.94)
	for grid_x in [-2.0, 0.0, 2.0]:
		_add_box(survey_site_root, "ITSurveyRuleX", Vector3(0.025, 0.008, 5.22), Vector3(grid_x, 0.015, 0.0), CREAM.darkened(0.20), 0.96)
	for grid_z in [-1.72, 0.0, 1.72]:
		_add_box(survey_site_root, "ITSurveyRuleZ", Vector3(5.72, 0.008, 0.025), Vector3(0.0, 0.016, grid_z), CREAM.darkened(0.20), 0.96)
	var mockup := Node3D.new()
	mockup.name = "SystemsContinuityMockup"
	mockup.position = Vector3(-1.48, 0.0, 0.62)
	survey_site_root.add_child(mockup)
	_add_box(mockup, "MockChassis", Vector3(1.44, 0.82, 0.72), Vector3(0.0, 0.41, 0.0), STEEL, 0.62, 0.18)
	for jack_index in 6:
		_add_cylinder(mockup, "MockPatchJack_%02d" % (jack_index + 1), Vector3(-0.50 + jack_index * 0.20, 0.53, 0.39), 0.035, 0.045, [AMBER, PALE_BLUE, STATUS_GREEN][jack_index % 3], 0.58, 0.20).rotation_degrees.x = 90.0
	var cable_spool := _add_cylinder(mockup, "SurveyCableSpool", Vector3(0.72, 0.26, 0.14), 0.24, 0.34, GRAPHITE, 0.58, 0.22)
	cable_spool.rotation_degrees.z = 90.0
	var survey_host := _add_box(survey_site_root, "ITSurveyNoticeHost", Vector3(3.32, 0.78, 0.11), Vector3(0.55, 0.78, 2.45), DEEP_TEAL, 0.78)
	EnvironmentalSignageScript.add_panel(survey_host, "ITCoopSurveyNotice", "SYSTEMS PARCEL\nCONTINUITY FILE PENDING", Vector3(0.0, 0.0, 0.064), Vector2(3.04, 0.55), DEEP_TEAL, CREAM, Vector3.ZERO, 14, 0.0028, &"secondary", &"machine")


func _build_owned_room() -> void:
	owned_room_root = Node3D.new()
	owned_room_root.name = "ITCoopRoom"
	owned_room_root.set_meta(&"facility_state", &"owned")
	owned_room_root.set_meta(&"management_camera_cutaway", true)
	add_child(owned_room_root)
	_build_shell(owned_room_root)
	_build_automation_console(owned_room_root)

	level_1_root = _new_level_root("CableRepairBenchTier", 1)
	_build_systems_unit(level_1_root, 0, 0.0, 1, PALE_BLUE)
	_build_cable_repair_bench(level_1_root)

	level_2_root = _new_level_root("PredictiveDispatchRackTier", 2)
	_build_systems_unit(level_2_root, 1, -1.66, 2, STATUS_GREEN)
	_build_predictive_dispatch_hardware(level_2_root)

	level_3_root = _new_level_root("AutomatedClaimsSorterTier", 3)
	_build_systems_unit(level_3_root, 2, 1.66, 3, AMBER)
	_build_automated_sorter(level_3_root)


func _build_shell(parent: Node3D) -> void:
	_add_box(parent, "ITCoopConnectedPad", Vector3(6.36, 0.18, 5.76), Vector3(0.0, -0.10, 0.0), Color("50585a"), 0.94)
	_add_box(parent, "ITCoopFloorInset", Vector3(6.06, 0.025, 5.46), Vector3(0.0, 0.004, 0.0), Color("59686a"), 0.94)
	for lane_index in 3:
		_add_box(parent, "ITFloorCableLane_%02d" % (lane_index + 1), Vector3(1.54, 0.014, 3.70), Vector3(-1.62 + lane_index * 1.62, 0.022, -0.20), [LANE_COLORS[&"predator_loss"], LANE_COLORS[&"nest_damage"], LANE_COLORS[&"appeals"]][lane_index].darkened(0.25), 0.98)
	_add_box(parent, "ITCoopBackWall", Vector3(6.10, 2.68, 0.12), Vector3(0.0, 1.34, -2.70), DEEP_TEAL, 0.78)
	_add_box(parent, "ITCoopBackWallDado", Vector3(6.12, 0.72, 0.15), Vector3(0.0, 0.38, -2.62), STEEL, 0.72)
	for post_x in [-3.05, 3.05]:
		for post_z in [-2.64, 2.64]:
			_add_box(parent, "ITCoopFramePost", Vector3(0.13, 3.30, 0.13), Vector3(post_x, 1.65, post_z), DEEP_TEAL, 0.66, 0.12)
	for beam_z in [-2.63, 2.63]:
		_add_box(parent, "ITCoopFrameBeam", Vector3(6.06, 0.13, 0.13), Vector3(0.0, 3.34, beam_z), DEEP_TEAL, 0.64, 0.14)
	for tray_x in [-2.22, -1.11, 0.0, 1.11, 2.22]:
		_add_box(parent, "ITCoopCableTraySlat", Vector3(0.12, 0.055, 3.24), Vector3(tray_x, 3.49, -0.65), GALVANIZED, 0.56, 0.22)

	var dado := _add_box(parent, "ITCoopNorthCutawayDado", Vector3(6.10, 0.46, 0.12), Vector3(0.0, 0.23, 2.70), BLUE_GREEN, 0.84)
	dado.set_meta(&"camera_facing_cutaway", true)
	_add_box(parent, "ITCoopNorthCutawayCap", Vector3(6.10, 0.07, 0.17), Vector3(0.0, 0.495, 2.69), BRASS.darkened(0.12), 0.54, 0.34)
	for wing_x in [-2.42, 2.42]:
		var glass := _add_glass_box(parent, "ITCoopNorthWireGlass", Vector3(1.08, 1.68, 0.04), Vector3(wing_x, 1.40, 2.68))
		glass.set_meta(&"cutaway_wing", true)
		for wire_x in [-0.34, 0.0, 0.34]:
			_add_box(parent, "ITCoopNorthGlassWire", Vector3(0.025, 1.56, 0.055), Vector3(wing_x + wire_x, 1.40, 2.675), CREAM.darkened(0.30), 0.62)
	var east_glass := _add_glass_box(parent, "ITCoopEastWireGlass", Vector3(0.04, 2.10, 2.70), Vector3(2.99, 1.48, 0.72))
	east_glass.set_meta(&"camera_facing_cutaway", true)
	for wire_z in [-0.92, -0.46, 0.0, 0.46, 0.92]:
		_add_box(parent, "ITCoopEastGlassWire", Vector3(0.055, 2.00, 0.025), Vector3(2.985, 1.48, 0.72 + wire_z), CREAM.darkened(0.30), 0.62)

	# The service identity occupies a real rack bay. Both stiles land on the
	# cutaway cap, while top and bottom rails clamp the fascia into the rack.
	for stile_index in 2:
		var stile_x: float = -1.76 if stile_index == 0 else 1.76
		_add_box(parent, "ITCoopIdentityRackStile_%02d" % (stile_index + 1), Vector3(0.12, 2.22, 0.16), Vector3(stile_x, 1.62, 2.65), GALVANIZED, 0.56, 0.22)
	var rack_top_rail := _add_box(parent, "ITCoopIdentityRackTopRail", Vector3(3.64, 0.14, 0.16), Vector3(0.0, 2.73, 2.65), GALVANIZED, 0.56, 0.22)
	_add_box(parent, "ITCoopIdentityRackBottomRail", Vector3(3.64, 0.10, 0.16), Vector3(0.0, 2.19, 2.65), GALVANIZED.darkened(0.08), 0.56, 0.22)
	var identity_host := _add_box(rack_top_rail, "ITCoopIdentityHost", Vector3(3.30, 0.44, 0.11), Vector3(0.0, -0.27, -0.035), DEEP_TEAL, 0.74)
	identity_host.set_meta(&"architectural_mount", &"equipment_rack")
	EnvironmentalSignageScript.add_panel(identity_host, "ITCoopIdentity", "IT COOP\nPATCHING & AUTOMATION", Vector3(0.0, 0.0, 0.058), Vector2(3.00, 0.38), DEEP_TEAL, CREAM, Vector3.ZERO, 14, 0.0028, &"primary", &"destination")

	var service_light := OmniLight3D.new()
	service_light.name = "ITCoopServiceLight"
	service_light.position = Vector3(0.0, 2.82, 0.18)
	service_light.light_color = Color("b9d7cf")
	service_light.light_energy = 0.34
	service_light.omni_range = 4.8
	service_light.shadow_enabled = false
	parent.add_child(service_light)


func _build_automation_console(parent: Node3D) -> void:
	var console := Node3D.new()
	console.name = "AutomationTermsConsole"
	console.position = Vector3(0.0, 0.0, -2.48)
	parent.add_child(console)
	_add_box(console, "AutomationConsoleCabinet", Vector3(2.72, 1.28, 0.24), Vector3(0.0, 1.82, 0.0), GRAPHITE, 0.62, 0.12)
	var screen_host := _add_box(console, "AutomationTermsScreen", Vector3(2.42, 0.72, 0.08), Vector3(0.0, 1.98, 0.155), GRAPHITE.darkened(0.08), 0.48, 0.22)
	_automation_label = EnvironmentalSignageScript.add_panel(screen_host, "ITCoopLiveAutomationTerms", "AUTOMATION / AWAITING SHIFT", Vector3(0.0, 0.0, 0.047), Vector2(2.16, 0.54), GRAPHITE.darkened(0.08), PALE_BLUE.lightened(0.18), Vector3.ZERO, 12, 0.00225, &"utility", &"screen", true)
	_enabled_lamp = _add_box(console, "AutomationEnabledLamp", Vector3(0.28, 0.10, 0.05), Vector3(-0.36, 1.34, 0.17), GRAPHITE.darkened(0.12), 0.60)
	_secondary_lamp = _add_box(console, "SecondarySpecialtyRecognitionLamp", Vector3(0.28, 0.10, 0.05), Vector3(0.0, 1.34, 0.17), GRAPHITE.darkened(0.12), 0.60)
	for pip_index in 4:
		_exposure_pips.append(_add_box(console, "ComplianceExposurePip_%02d" % (pip_index + 1), Vector3(0.20, 0.09, 0.05), Vector3(0.40 + pip_index * 0.23, 1.34, 0.17), GRAPHITE.darkened(0.12), 0.60))


func _new_level_root(root_name: String, level: int) -> Node3D:
	var level_root := Node3D.new()
	level_root.name = root_name
	level_root.set_meta(&"facility_level", level)
	owned_room_root.add_child(level_root)
	return level_root


func _build_systems_unit(parent: Node3D, unit_index: int, x: float, required_level: int, accent: Color) -> void:
	var unit := Node3D.new()
	unit.name = "ConnectedSystemsUnit_%02d" % (unit_index + 1)
	unit.position = Vector3(x, 0.0, -0.72)
	unit.set_meta(&"required_level", required_level)
	parent.add_child(unit)
	_add_box(unit, "SystemsCabinetPlinth", Vector3(1.28, 0.12, 0.92), Vector3(0.0, 0.06, 0.0), GRAPHITE, 0.48, 0.28)
	_add_box(unit, "SystemsCabinet", Vector3(1.18, 1.92, 0.76), Vector3(0.0, 1.02, -0.04), STEEL.darkened(0.08), 0.58, 0.24)
	_add_box(unit, "SystemsCabinetDoor", Vector3(1.02, 1.72, 0.055), Vector3(0.0, 1.05, 0.37), GRAPHITE, 0.52, 0.18)
	for chassis_index in 5:
		_add_box(unit, "RackChassis_%02d" % (chassis_index + 1), Vector3(0.82, 0.20, 0.06), Vector3(0.0, 0.40 + chassis_index * 0.30, 0.415), GALVANIZED.darkened(chassis_index * 0.025), 0.54, 0.22)
		var lamp := _add_box(unit, "RackStatusLamp_%02d" % (chassis_index + 1), Vector3(0.08, 0.055, 0.025), Vector3(0.30, 0.40 + chassis_index * 0.30, 0.455), accent.darkened(0.15), 0.54)
		lamp.material_override = _emissive_material(accent, 0.38)
	var plate_host := _add_box(unit, "SystemsUnitPlateHost", Vector3(0.90, 0.20, 0.05), Vector3(0.0, 1.78, 0.43), accent.darkened(0.22), 0.78)
	EnvironmentalSignageScript.add_panel(plate_host, "SystemsUnitPlate_%02d" % (unit_index + 1), "SYSTEM %02d" % (unit_index + 1), Vector3(0.0, 0.0, 0.032), Vector2(0.78, 0.13), accent.darkened(0.22), CREAM, Vector3.ZERO, 10, 0.0021, &"utility", &"machine")
	_systems_units.append(unit)


func _build_cable_repair_bench(parent: Node3D) -> void:
	var bench := Node3D.new()
	bench.name = "CableAndRepairBench"
	bench.position = Vector3(-2.28, 0.0, 1.28)
	parent.add_child(bench)
	_add_box(bench, "RepairBenchTop", Vector3(1.34, 0.12, 0.74), Vector3(0.0, 0.80, 0.0), BIRCH, 0.74)
	for leg_x in [-0.54, 0.54]:
		_add_box(bench, "RepairBenchLeg", Vector3(0.10, 0.76, 0.10), Vector3(leg_x, 0.39, 0.0), GRAPHITE, 0.50, 0.26)
	_add_box(bench, "ContinuityMeter", Vector3(0.52, 0.34, 0.40), Vector3(-0.26, 1.03, -0.04), ENAMEL_TEAL, 0.66)
	_add_box(bench, "ContinuityMeterScreen", Vector3(0.36, 0.18, 0.025), Vector3(-0.26, 1.06, 0.175), STATUS_GREEN.darkened(0.18), 0.54).material_override = _emissive_material(STATUS_GREEN, 0.34)
	for spool_index in 2:
		var spool := _add_cylinder(bench, "RepairCableSpool_%02d" % (spool_index + 1), Vector3(0.28 + spool_index * 0.32, 1.00, 0.0), 0.18, 0.22, [PALE_BLUE, AMBER][spool_index], 0.68)
		spool.rotation_degrees.z = 90.0
	var plate := _add_box(parent, "CableRepairBenchPlateHost", Vector3(2.12, 0.29, 0.08), Vector3(1.90, 2.54, -2.58), DEEP_TEAL, 0.74)
	EnvironmentalSignageScript.add_panel(plate, "CableRepairBenchPlate", "CABLE & REPAIR BENCH", Vector3(0.0, 0.0, 0.047), Vector2(1.90, 0.20), DEEP_TEAL, CREAM, Vector3.ZERO, 11, 0.00235, &"utility", &"machine")


func _build_predictive_dispatch_hardware(parent: Node3D) -> void:
	var rack := Node3D.new()
	rack.name = "PredictiveDispatchRack"
	rack.position = Vector3(-2.92, 0.0, 0.62)
	rack.rotation_degrees.y = 90.0
	parent.add_child(rack)
	_add_box(rack, "DispatchPatchPanel", Vector3(3.18, 1.62, 0.10), Vector3(0.0, 1.32, 0.0), GRAPHITE, 0.54, 0.18)
	var load_screen := _add_box(rack, "DispatchLoadScreen", Vector3(2.86, 0.38, 0.06), Vector3(0.0, 1.86, 0.083), DEEP_TEAL, 0.58)
	_load_label = EnvironmentalSignageScript.add_panel(load_screen, "ITCoopLiveLaneLoad", "LANE LOAD / AWAITING SHIFT", Vector3(0.0, 0.0, 0.037), Vector2(2.58, 0.25), DEEP_TEAL, PALE_BLUE.lightened(0.16), Vector3.ZERO, 11, 0.0022, &"utility", &"screen", true)
	for lane_index in LANE_ORDER.size():
		var lane := LANE_ORDER[lane_index]
		var pips: Array[MeshInstance3D] = []
		for pip_index in QUEUE_PIPS_PER_LANE:
			var pip := _add_box(rack, "Dispatch%sPip_%02d" % [String(lane).to_pascal_case(), pip_index + 1], Vector3(0.24, 0.075, 0.05), Vector3(-0.72 + pip_index * 0.29, 1.44 - lane_index * 0.19, 0.083), GRAPHITE.darkened(0.12), 0.60)
			pip.set_meta(&"claim_lane", lane)
			pips.append(pip)
		_queue_pips[lane] = pips
	_auto_jack_root = Node3D.new()
	_auto_jack_root.name = "AuthoritativeAutoWorkerJacks"
	_auto_jack_root.position = Vector3(0.0, 0.0, 0.09)
	_auto_jack_root.set_meta(&"authoritative_records_only", true)
	rack.add_child(_auto_jack_root)
	var plate := _add_box(parent, "PredictiveDispatchRackPlateHost", Vector3(2.28, 0.29, 0.08), Vector3(-1.82, 2.76, -2.58), DEEP_TEAL, 0.74)
	EnvironmentalSignageScript.add_panel(plate, "PredictiveDispatchRackPlate", "PREDICTIVE DISPATCH RACK", Vector3(0.0, 0.0, 0.047), Vector2(2.06, 0.20), DEEP_TEAL, CREAM, Vector3.ZERO, 11, 0.0023, &"utility", &"machine")


func _build_automated_sorter(parent: Node3D) -> void:
	var sorter := Node3D.new()
	sorter.name = "AutomatedClaimsSorter"
	sorter.position = Vector3(0.0, 0.0, 1.36)
	sorter.set_meta(&"intentionally_empty", true)
	parent.add_child(sorter)
	_add_box(sorter, "SorterPlinth", Vector3(4.72, 0.14, 1.18), Vector3(0.0, 0.07, 0.0), GRAPHITE, 0.48, 0.28)
	for lane_index in 3:
		var lane_x := -1.54 + lane_index * 1.54
		var color := [LANE_COLORS[&"predator_loss"], LANE_COLORS[&"nest_damage"], LANE_COLORS[&"appeals"]][lane_index] as Color
		_add_box(sorter, "EmptySorterLane_%02d" % (lane_index + 1), Vector3(1.28, 0.16, 0.84), Vector3(lane_x, 0.26, 0.0), color.darkened(0.28), 0.72)
		for roller_index in 4:
			var roller := _add_cylinder(sorter, "SorterRoller_%02d_%02d" % [lane_index + 1, roller_index + 1], Vector3(lane_x - 0.42 + roller_index * 0.28, 0.38, 0.0), 0.055, 0.70, GALVANIZED, 0.50, 0.26)
			roller.rotation_degrees.x = 90.0
	_add_box(sorter, "SorterControlTower", Vector3(0.82, 1.26, 0.64), Vector3(2.26, 0.70, -0.08), STEEL, 0.56, 0.20)
	_add_box(sorter, "SorterControlScreen", Vector3(0.58, 0.38, 0.035), Vector3(2.26, 0.88, 0.259), STATUS_GREEN.darkened(0.16), 0.52).material_override = _emissive_material(STATUS_GREEN, 0.38)
	_patch_invoice_root = Node3D.new()
	_patch_invoice_root.name = "AuthoritativeLedgerPatchInvoice"
	_patch_invoice_root.position = Vector3(-2.18, 0.0, -0.48)
	_patch_invoice_root.set_meta(&"authoritative_records_only", true)
	sorter.add_child(_patch_invoice_root)
	var plate := _add_box(parent, "AutomatedClaimsSorterPlateHost", Vector3(2.30, 0.29, 0.08), Vector3(1.78, 2.76, -2.58), DEEP_TEAL, 0.74)
	EnvironmentalSignageScript.add_panel(plate, "AutomatedClaimsSorterPlate", "AUTOMATED CLAIMS SORTER", Vector3(0.0, 0.0, 0.047), Vector2(2.08, 0.20), DEEP_TEAL, CREAM, Vector3.ZERO, 11, 0.0023, &"utility", &"machine")


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
	if _automation_label != null:
		if _has_automation_metrics:
			_automation_label.text = "AUTO %d%% / GRACE %dM / SECONDARY %s\nCOMPLIANCE +%.2f / PATCH $%.2f / SHEET %.2f" % [
				roundi(float(_work_basis_points) / 100.0),
				_specialty_grace_minutes,
				"YES" if _recognizes_secondary_specialties else "NO",
				float(_compliance_exposure_millipoints) / 1000.0,
				float(_ledger_patch_cost_cents) / 100.0,
				float(_spreadsheet_compliance_loss_millipoints) / 1000.0,
			]
		else:
			_automation_label.text = "AUTOMATION / AWAITING SHIFT"
		EnvironmentalSignageScript.refit_label(_automation_label)
	if _load_label != null:
		_load_label.text = "AUTO HENS %d / ACTIVE %d / N %02d P %02d A %02d" % [
			_auto_enrolled_workers,
			_active_auto_claims,
			maxi(0, int(_queue_counts.get(&"nest_damage", _queue_counts.get("nest_damage", 0)))),
			maxi(0, int(_queue_counts.get(&"predator_loss", _queue_counts.get("predator_loss", 0)))),
			maxi(0, int(_queue_counts.get(&"appeals", _queue_counts.get("appeals", 0)))),
		]
		EnvironmentalSignageScript.refit_label(_load_label)
	if _enabled_lamp != null:
		_enabled_lamp.material_override = _emissive_material(STATUS_GREEN, 0.74) if _automation_enabled else _material(GRAPHITE.darkened(0.12), 0.60)
	if _secondary_lamp != null:
		_secondary_lamp.material_override = _emissive_material(PALE_BLUE, 0.70) if _recognizes_secondary_specialties else _material(GRAPHITE.darkened(0.12), 0.60)
	var exposure_steps := clampi(ceili(float(_compliance_exposure_millipoints) / 750.0), 0, _exposure_pips.size())
	for pip_index in _exposure_pips.size():
		_exposure_pips[pip_index].material_override = _emissive_material(ALERT_RED, 0.68) if pip_index < exposure_steps else _material(GRAPHITE.darkened(0.12), 0.60)
	for lane in LANE_ORDER:
		var pips: Array = _queue_pips.get(lane, []) as Array
		var count := maxi(0, int(_queue_counts.get(lane, _queue_counts.get(String(lane), 0))))
		for pip_index in pips.size():
			var pip := pips[pip_index] as MeshInstance3D
			pip.material_override = _emissive_material(LANE_COLORS[lane], 0.58) if pip_index < mini(count, QUEUE_PIPS_PER_LANE) else _material(GRAPHITE.darkened(0.12), 0.60)


func _read_auto_worker_records(snapshot: Dictionary) -> void:
	_auto_worker_records.clear()
	var workers_variant: Variant = snapshot.get("workers", [])
	if not (workers_variant is Array):
		return
	for worker_variant in workers_variant as Array:
		if not (worker_variant is Dictionary):
			continue
		var worker := worker_variant as Dictionary
		if not bool(worker.get("employed", true)):
			continue
		if StringName(String(worker.get("assigned_lane", &"auto"))) != &"auto":
			continue
		_auto_worker_records.append({
			"worker_id": int(worker.get("id", worker.get("worker_id", -1))),
			"worker_name": String(worker.get("display_name", worker.get("name", "FLOCK MEMBER"))).strip_edges(),
		})
		if _auto_worker_records.size() >= MAX_AUTO_JACKS:
			break


func _rebuild_auto_worker_jacks() -> void:
	_auto_jacks.clear()
	if _auto_jack_root == null:
		return
	for child in _auto_jack_root.get_children():
		child.free()
	if _facility_level < 2:
		return
	for record_index in _auto_worker_records.size():
		var record := _auto_worker_records[record_index]
		var jack := Node3D.new()
		jack.name = "ITAutoWorkerJack_%02d" % (record_index + 1)
		jack.position = Vector3(-1.02 + (record_index % 3) * 1.02, 0.76 - int(record_index / 3) * 0.34, 0.0)
		jack.set_meta(&"authoritative_record", true)
		jack.set_meta(&"worker_id", int(record.get("worker_id", -1)))
		_auto_jack_root.add_child(jack)
		var host := _add_box(jack, "AutoWorkerJackHost", Vector3(0.88, 0.26, 0.055), Vector3.ZERO, ENAMEL_TEAL, 0.78)
		EnvironmentalSignageScript.add_panel(host, "AutoWorkerJackCopy_%02d" % (record_index + 1), String(record.get("worker_name", "FLOCK MEMBER")).to_upper(), Vector3(0.0, 0.0, 0.035), Vector2(0.76, 0.17), ENAMEL_TEAL, CREAM, Vector3.ZERO, 9, 0.0019, &"utility", &"machine")
		var jack_lamp := _add_box(jack, "AutoWorkerJackLamp", Vector3(0.08, 0.08, 0.025), Vector3(0.33, 0.0, 0.045), STATUS_GREEN, 0.52)
		jack_lamp.material_override = _emissive_material(STATUS_GREEN, 0.52)
		_auto_jacks.append(jack)


func _rebuild_patch_invoice() -> void:
	_patch_invoices.clear()
	if _patch_invoice_root == null:
		return
	for child in _patch_invoice_root.get_children():
		child.free()
	if _facility_level < 3 or not _has_automation_metrics:
		return
	var invoice := Node3D.new()
	invoice.name = "LedgerMoltPatchInvoice"
	invoice.position = Vector3(0.0, 1.04, 0.0)
	invoice.set_meta(&"authoritative_record", true)
	invoice.set_meta(&"ledger_patch_cost_cents", _ledger_patch_cost_cents)
	invoice.set_meta(&"spreadsheet_compliance_loss_millipoints", _spreadsheet_compliance_loss_millipoints)
	_patch_invoice_root.add_child(invoice)
	var host := _add_box(invoice, "LedgerPatchInvoiceHost", Vector3(1.44, 0.72, 0.055), Vector3.ZERO, BIRCH, 0.92)
	EnvironmentalSignageScript.add_panel(host, "LedgerMoltPatchInvoiceCopy", "LEDGER MOLT PATCH $%.2f\nFREE SHEET RISK %.2f" % [float(_ledger_patch_cost_cents) / 100.0, float(_spreadsheet_compliance_loss_millipoints) / 1000.0], Vector3(0.0, 0.0, 0.035), Vector2(1.28, 0.58), BIRCH, DEEP_TEAL, Vector3.ZERO, 10, 0.00195, &"utility", &"machine")
	_patch_invoices.append(invoice)


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
	if operations.has("it_coop_level"):
		return _level_from_variant(operations.get("it_coop_level", 0))
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
