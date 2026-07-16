class_name ShellQualityLabVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## A visual-only facility module for the east service alcove. The rectangle is
## expressed in OfficeStorytelling local X/Z space so routing tests and future
## facilities can reserve it without reverse-engineering the meshes.
const FACILITY_ID := &"candling_rework_bay"
const REQUIRED_UNLOCK := &"shell_quality_checks"
const FACILITY_CENTER := Vector3(10.10, 0.0, 2.30)
const FOOTPRINT_MIN := Vector2(9.05, 1.40)
const FOOTPRINT_MAX := Vector2(11.15, 3.20)
const MAX_OPAQUE_HEIGHT := 1.65

const ENAMEL_TEAL := Color("315b60")
const ENAMEL_DARK := Color("203d41")
const WARM_CREAM := Color("ded6bf")
const SERVICE_GREY := Color("667275")
const GRAPHITE := Color("283235")
const BRASS := Color("b59655")
const SAFETY_AMBER := Color("d4a347")
const PAPER := Color("ded8c4")

var construction_pad_root: Node3D
var owned_bay_root: Node3D

var _material_cache: Dictionary[String, StandardMaterial3D] = {}
var _built := false
var _unlocked := false
var _owned := false


func _ready() -> void:
	name = "ShellQualityLabVisual"
	position = FACILITY_CENTER
	if not _built:
		build()


## Rect2.position is minimum X/Z and Rect2.size is footprint width/depth.
static func declared_footprint() -> Rect2:
	return Rect2(FOOTPRINT_MIN, FOOTPRINT_MAX - FOOTPRINT_MIN)


func build() -> void:
	clear()
	_built = true
	_build_construction_pad()
	_build_owned_bay()
	_apply_visibility()


func clear() -> void:
	for visual_root in [construction_pad_root, owned_bay_root]:
		if visual_root != null and is_instance_valid(visual_root):
			visual_root.free()
	construction_pad_root = null
	owned_bay_root = null
	_material_cache.clear()
	_built = false


func apply_snapshot(snapshot: Dictionary) -> void:
	if not _built:
		build()
	_owned = _snapshot_owns_facility(snapshot)
	_unlocked = _owned or _snapshot_has_unlock(snapshot)
	_apply_visibility()


func construction_pad_visible() -> bool:
	return construction_pad_root != null and construction_pad_root.visible


func owned_bay_visible() -> bool:
	return owned_bay_root != null and owned_bay_root.visible


func visual_state() -> StringName:
	if _owned:
		return &"owned"
	if _unlocked:
		return &"construction_pad"
	return &"locked"


func _apply_visibility() -> void:
	if construction_pad_root != null:
		construction_pad_root.visible = _unlocked and not _owned
	if owned_bay_root != null:
		owned_bay_root.visible = _owned


func _snapshot_has_unlock(snapshot: Dictionary) -> bool:
	var unlocks := snapshot.get("campaign_unlocks", {}) as Dictionary
	return bool(unlocks.get(REQUIRED_UNLOCK, unlocks.get(String(REQUIRED_UNLOCK), false)))


func _snapshot_owns_facility(snapshot: Dictionary) -> bool:
	var owned_facilities := snapshot.get("owned_facilities", {}) as Dictionary
	var has_authoritative_entry := (
		owned_facilities.has(FACILITY_ID)
		or owned_facilities.has(String(FACILITY_ID))
	)
	var owned_value: Variant = owned_facilities.get(
		FACILITY_ID,
		owned_facilities.get(String(FACILITY_ID), null)
	)
	if has_authoritative_entry:
		return _owned_value_is_active(owned_value)

	# Compatibility for UI fixtures and transitional snapshots that expose only
	# the purchasable catalog. The authoritative owned_facilities map wins above.
	var catalog_variant: Variant = snapshot.get("facility_catalog", [])
	if catalog_variant is Array:
		for entry_variant in catalog_variant as Array:
			if entry_variant is Dictionary:
				var entry := entry_variant as Dictionary
				if StringName(entry.get("id", &"")) == FACILITY_ID:
					return bool(entry.get("owned", false)) or int(entry.get("level", 0)) > 0
	elif catalog_variant is Dictionary:
		var catalog := catalog_variant as Dictionary
		var entry_variant: Variant = catalog.get(FACILITY_ID, catalog.get(String(FACILITY_ID), null))
		return _owned_value_is_active(entry_variant)
	return false


func _owned_value_is_active(value: Variant) -> bool:
	if value is bool:
		return value
	if value is int or value is float:
		return int(value) > 0
	if value is Dictionary:
		var record := value as Dictionary
		return bool(record.get("owned", false)) or int(record.get("level", 0)) > 0
	return false


func _build_construction_pad() -> void:
	construction_pad_root = Node3D.new()
	construction_pad_root.name = "ShellQAConstructionPad"
	add_child(construction_pad_root)

	_add_box(
		construction_pad_root, "ReservedUtilityPad",
		Vector3(2.02, 0.025, 1.70), Vector3(0.0, 0.014, 0.0),
		Color("596467"), 0.92
	)
	_add_box(
		construction_pad_root, "UtilityPadInset",
		Vector3(1.86, 0.009, 1.54), Vector3(0.0, 0.031, 0.0),
		Color("414d50"), 0.94
	)

	# Low taped perimeter: clearly reserved space, never an obstacle or a floating
	# UI card. Alternating warm and dark blocks evoke old facilities tape.
	for edge_z in [-0.79, 0.79]:
		for stripe_index in 9:
			_add_box(
				construction_pad_root,
				"ConstructionTapeZ_%d_%d" % [int(edge_z > 0.0), stripe_index],
				Vector3(0.19, 0.010, 0.055),
				Vector3(-0.82 + stripe_index * 0.205, 0.041, edge_z),
				SAFETY_AMBER if stripe_index % 2 == 0 else GRAPHITE,
				0.78
			)
	for edge_x in [-0.96, 0.96]:
		for stripe_index in 7:
			_add_box(
				construction_pad_root,
				"ConstructionTapeX_%d_%d" % [int(edge_x > 0.0), stripe_index],
				Vector3(0.055, 0.010, 0.19),
				Vector3(edge_x, 0.042, -0.61 + stripe_index * 0.205),
				SAFETY_AMBER if stripe_index % 2 == 0 else GRAPHITE,
				0.78
			)

	# Capped power and air services make the pad feel planned rather than empty.
	var service_plate := _add_box(
		construction_pad_root, "CappedServicePlate",
		Vector3(0.54, 0.035, 0.26), Vector3(0.53, 0.055, -0.46),
		SERVICE_GREY, 0.62, 0.22
	)
	for port_x in [-0.13, 0.13]:
		_add_cylinder(
			construction_pad_root, "CappedUtilityPort",
			Vector3(0.53 + port_x, 0.090, -0.46), 0.065, 0.065,
			GRAPHITE, 0.52, 0.28
		)
	EnvironmentalSignageScript.add_panel(
		service_plate,
		"ShellQAUtilityReservation",
		"QA SERVICE",
		Vector3(0.0, 0.020, 0.0),
		Vector2(0.42, 0.11),
		SERVICE_GREY,
		ENAMEL_DARK,
		Vector3(-90.0, 0.0, 0.0),
		10,
		0.0020,
		&"utility",
		&"stencil"
	)


func _build_owned_bay() -> void:
	owned_bay_root = Node3D.new()
	owned_bay_root.name = "CandlingAndReworkBay"
	add_child(owned_bay_root)

	# The completed facility grows from the exact reserved pad footprint.
	_add_box(
		owned_bay_root, "ShellQAFloorMat",
		Vector3(2.02, 0.025, 1.70), Vector3(0.0, 0.014, 0.0),
		Color("455356"), 0.94
	)
	for rail_z in [-0.79, 0.79]:
		_add_box(
			owned_bay_root, "ShellQAMatEdge",
			Vector3(1.96, 0.014, 0.035), Vector3(0.0, 0.034, rail_z),
			BRASS.darkened(0.24), 0.68, 0.26
		)

	_add_box(
		owned_bay_root, "ConnectedQABenchTop",
		Vector3(1.90, 0.105, 0.76), Vector3(0.0, 0.80, 0.02),
		WARM_CREAM, 0.64
	)
	var bench_apron := _add_box(
		owned_bay_root, "QABenchFrontApron",
		Vector3(1.90, 0.24, 0.085), Vector3(0.0, 0.695, 0.385),
		ENAMEL_TEAL, 0.68, 0.08
	)
	for leg_x in [-0.83, 0.83]:
		for leg_z in [-0.27, 0.27]:
			_add_box(
				owned_bay_root, "QABenchConnectedLeg",
				Vector3(0.095, 0.72, 0.095), Vector3(leg_x, 0.40, 0.02 + leg_z),
				SERVICE_GREY, 0.52, 0.34
			)
	_add_box(
		owned_bay_root, "QABenchLowerShelf",
		Vector3(1.70, 0.060, 0.55), Vector3(0.0, 0.25, 0.02),
		Color("596568"), 0.68, 0.18
	)
	for brace_x in [-0.83, 0.83]:
		_add_box(
			owned_bay_root, "QABenchCrossBrace",
			Vector3(0.070, 0.070, 0.58), Vector3(brace_x, 0.46, 0.02),
			GRAPHITE, 0.58, 0.30
		)

	_build_candling_hood()
	_build_thickness_gauge()
	_build_calibration_weights()
	_build_rework_tray()
	_build_qa_terminal()
	_build_status_lamps()

	# The enamel plate is bolted to the bench apron: it inherits the equipment,
	# remains legible at overview distance, and never reads as screen-space UI.
	var plate := EnvironmentalSignageScript.add_panel(
		bench_apron,
		"ShellQAEnamelPlate",
		"SHELL QA\nCANDLING / REWORK",
		Vector3(0.0, 0.0, 0.048),
		Vector2(1.48, 0.22),
		ENAMEL_DARK,
		Color("e7ddbf"),
		Vector3.ZERO,
		15,
		0.0034,
		&"secondary",
		&"machine"
	)
	plate.get_parent().set_meta(&"enamel_equipment_plate", true)


func _build_candling_hood() -> void:
	var hood := Node3D.new()
	hood.name = "EnclosedCandlingHood"
	hood.position = Vector3(-0.58, 0.86, -0.035)
	owned_bay_root.add_child(hood)

	_add_box(hood, "CandlingHoodBack", Vector3(0.66, 0.66, 0.065), Vector3(0.0, 0.33, -0.24), ENAMEL_DARK, 0.56, 0.12)
	_add_box(hood, "CandlingHoodTop", Vector3(0.66, 0.065, 0.54), Vector3(0.0, 0.63, 0.0), ENAMEL_TEAL, 0.58, 0.10)
	for side_x in [-0.30, 0.30]:
		_add_box(hood, "CandlingHoodSide", Vector3(0.065, 0.66, 0.54), Vector3(side_x, 0.33, 0.0), ENAMEL_TEAL, 0.58, 0.10)
	_add_box(hood, "CandlingHoodBed", Vector3(0.64, 0.055, 0.52), Vector3(0.0, 0.045, 0.0), GRAPHITE, 0.76)
	_add_box(hood, "CandlingHoodDarkChamber", Vector3(0.51, 0.47, 0.035), Vector3(0.0, 0.31, -0.198), Color("101719"), 0.94)
	_add_glass_box(hood, "CandlingSafetyScreen", Vector3(0.54, 0.50, 0.025), Vector3(0.0, 0.33, 0.255))
	_add_box(hood, "CandlingLightAperture", Vector3(0.25, 0.025, 0.18), Vector3(0.0, 0.083, 0.0), Color("c98b3d"), 0.34, 0.10)


func _build_thickness_gauge() -> void:
	var gauge := Node3D.new()
	gauge.name = "ShellThicknessGauge"
	gauge.position = Vector3(0.04, 0.86, 0.04)
	owned_bay_root.add_child(gauge)
	_add_box(gauge, "GaugeConnectedBase", Vector3(0.29, 0.050, 0.25), Vector3(0.0, 0.025, 0.0), GRAPHITE, 0.54, 0.30)
	_add_box(gauge, "GaugeUpright", Vector3(0.055, 0.39, 0.060), Vector3(-0.10, 0.22, -0.07), SERVICE_GREY, 0.44, 0.38)
	_add_box(gauge, "GaugeUpperArm", Vector3(0.25, 0.055, 0.060), Vector3(0.00, 0.39, -0.07), SERVICE_GREY, 0.44, 0.38)
	var spindle := _add_cylinder(gauge, "GaugeSpindle", Vector3(0.10, 0.30, -0.07), 0.027, 0.17, BRASS, 0.36, 0.46)
	spindle.rotation_degrees.z = 90.0
	_add_cylinder(gauge, "GaugeDial", Vector3(-0.105, 0.40, 0.00), 0.075, 0.035, WARM_CREAM, 0.48, 0.12).rotation_degrees.x = 90.0
	_add_box(gauge, "GaugeDialNeedle", Vector3(0.008, 0.052, 0.010), Vector3(-0.105, 0.405, 0.024), Color("a45246"), 0.54)


func _build_calibration_weights() -> void:
	var rack := Node3D.new()
	rack.name = "CalibrationWeightRack"
	rack.position = Vector3(0.40, 0.86, 0.18)
	owned_bay_root.add_child(rack)
	_add_box(rack, "CalibrationRackBase", Vector3(0.36, 0.035, 0.20), Vector3.ZERO, GRAPHITE, 0.62, 0.28)
	var heights := [0.10, 0.14, 0.18]
	for weight_index in 3:
		var height: float = heights[weight_index]
		_add_cylinder(
			rack, "CalibrationWeight_%d" % weight_index,
			Vector3(-0.12 + weight_index * 0.12, 0.025 + height * 0.5, 0.0),
			0.048 + weight_index * 0.006, height,
			BRASS.darkened(weight_index * 0.055), 0.34, 0.62
		)


func _build_rework_tray() -> void:
	var tray := Node3D.new()
	tray.name = "RejectReworkPaperworkTray"
	tray.position = Vector3(-0.42, 0.31, 0.03)
	owned_bay_root.add_child(tray)
	_add_box(tray, "ReworkTrayBase", Vector3(0.58, 0.045, 0.40), Vector3.ZERO, ENAMEL_TEAL, 0.68)
	for wall_x in [-0.275, 0.275]:
		_add_box(tray, "ReworkTraySide", Vector3(0.035, 0.15, 0.40), Vector3(wall_x, 0.065, 0.0), ENAMEL_TEAL, 0.68)
	var tray_front := _add_box(
		tray,
		"ReworkTrayFront",
		Vector3(0.58, 0.15, 0.035),
		Vector3(0.0, 0.065, 0.185),
		ENAMEL_TEAL,
		0.68,
	)
	for sheet_index in 4:
		_add_box(
			tray, "ReworkPaper_%d" % sheet_index,
			Vector3(0.48, 0.012, 0.32), Vector3(0.0, 0.035 + sheet_index * 0.012, 0.0),
			PAPER.darkened(sheet_index * 0.018), 0.96
		)
	EnvironmentalSignageScript.add_panel(
		tray_front, "ReworkTrayStencil", "REWORK",
		Vector3(0.0, 0.0, 0.020), Vector2(0.42, 0.10),
		ENAMEL_TEAL, Color("ead9a7"), Vector3.ZERO,
		10, 0.0022, &"utility", &"stencil"
	)


func _build_qa_terminal() -> void:
	var terminal := Node3D.new()
	terminal.name = "QACalibrationTerminal"
	terminal.position = Vector3(0.59, 0.86, -0.10)
	owned_bay_root.add_child(terminal)
	_add_box(terminal, "QATerminalPedestal", Vector3(0.075, 0.32, 0.075), Vector3(0.0, 0.18, 0.0), SERVICE_GREY, 0.42, 0.38)
	_add_box(terminal, "QATerminalNeck", Vector3(0.30, 0.055, 0.075), Vector3(0.0, 0.31, 0.0), SERVICE_GREY, 0.42, 0.38)
	_add_box(terminal, "QATerminalFrame", Vector3(0.46, 0.34, 0.075), Vector3(0.0, 0.49, 0.0), GRAPHITE, 0.42, 0.18)
	var screen := _add_box(terminal, "QATerminalScreen", Vector3(0.38, 0.26, 0.020), Vector3(0.0, 0.49, 0.048), Color("5f8d80"), 0.34)
	screen.material_override = _emissive_material(Color("72a696"), 0.32)
	for bar_index in 3:
		_add_box(
			terminal, "QACalibrationReadout_%d" % bar_index,
			Vector3(0.21 - bar_index * 0.035, 0.018, 0.009),
			Vector3(-0.04, 0.55 - bar_index * 0.068, 0.061),
			Color("d5d8ae"), 0.46
		)


func _build_status_lamps() -> void:
	var tower := Node3D.new()
	tower.name = "RestrainedQAStatusTower"
	tower.position = Vector3(0.86, 0.87, -0.23)
	owned_bay_root.add_child(tower)
	_add_cylinder(tower, "StatusTowerStem", Vector3(0.0, 0.17, 0.0), 0.025, 0.30, SERVICE_GREY, 0.40, 0.38)
	_add_box(tower, "StatusTowerCap", Vector3(0.13, 0.045, 0.11), Vector3(0.0, 0.34, 0.0), GRAPHITE, 0.48, 0.24)
	for lamp_index in 2:
		var lamp_color := Color("789d84") if lamp_index == 0 else Color("c69545")
		var lamp := _add_cylinder(
			tower, "QAStatusLamp_%d" % lamp_index,
			Vector3(-0.035 + lamp_index * 0.07, 0.38, 0.0),
			0.028, 0.055, lamp_color, 0.40, 0.05
		)
		lamp.material_override = _emissive_material(lamp_color, 0.20)


func _add_box(
	parent: Node3D,
	part_name: String,
	size: Vector3,
	part_position: Vector3,
	color: Color,
	roughness: float = 0.82,
	metallic: float = 0.0
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
	metallic: float = 0.0
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.94
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color, roughness, metallic)
	parent.add_child(instance)
	return instance


func _add_glass_box(parent: Node3D, part_name: String, size: Vector3, part_position: Vector3) -> MeshInstance3D:
	var glass := _add_box(parent, part_name, size, part_position, Color(0.52, 0.72, 0.72, 0.22), 0.18, 0.08)
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
		material.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_DISABLED
	_material_cache[key] = material
	return material


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var key := "emissive_%s_%.2f" % [color.to_html(true), energy]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.42)
	material.roughness = 0.42
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.resource_local_to_scene = true
	_material_cache[key] = material
	return material
