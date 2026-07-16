class_name CampusPortfolioVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## Visual-only second/third-deed campus portfolio. The authoritative simulation
## owns deeds, projects, crews, utilities, and completion. This projection owns
## only deterministic low-poly geometry and published spatial contracts.
const SNAPSHOT_ROOT: StringName = &"campus_portfolio"

const ORCHARD_ROW_ID: StringName = &"orchard_row"
const CREEKSIDE_YARD_ID: StringName = &"creekside_yard"

const ORCHARD_ROW_FOOTPRINT := Rect2(Vector2(18.65, 15.10), Vector2(12.80, 11.80))
const CREEKSIDE_YARD_FOOTPRINT := Rect2(Vector2(18.65, 27.10), Vector2(12.80, 11.80))
const ORCHARD_ROW_CROSS_ROUTE := Rect2(Vector2(19.10, 15.35), Vector2(11.90, 2.10))
const CREEKSIDE_YARD_CROSS_ROUTE := Rect2(Vector2(19.10, 27.35), Vector2(11.90, 2.10))
const SHARED_SERVICE_TRUNK := Rect2(Vector2(28.15, 5.45), Vector2(2.10, 33.50))
const MAX_VISUAL_HEIGHT := 4.45

const ORCHARD_WEST_PAD: StringName = &"orchard_west"
const ORCHARD_EAST_PAD: StringName = &"orchard_east"
const ORCHARD_SERVICE_PAD: StringName = &"orchard_service_spine"
const CREEKSIDE_WEST_PAD: StringName = &"creekside_west"
const CREEKSIDE_EAST_PAD: StringName = &"creekside_east"
const CREEKSIDE_SERVICE_PAD: StringName = &"creekside_service_spine"

const COLLECTION_RAIL_HUB_ID: StringName = &"collection_rail_hub"
const GRAIN_RECOVERY_MILL_ID: StringName = &"grain_recovery_mill"
const CREEKSIDE_CHILLING_EXCHANGE_ID: StringName = &"creekside_chilling_exchange"
const CONTRACTOR_ROOST_ID: StringName = &"contractor_roost"

const ORCHARD_GREEN := Color("647b5e")
const ORCHARD_LIGHT := Color("8d9a72")
const CREEKSIDE_GREEN := Color("56736b")
const CREEK_BLUE := Color("63919a")
const DARK_GREEN := Color("30483d")
const TIMBER := Color("79583b")
const DARK_TIMBER := Color("4a3729")
const CREAM := Color("e8dec2")
const PAPER := Color("eee6d0")
const OATMEAL := Color("cfbf99")
const BARN_RED := Color("92503f")
const DEEP_RED := Color("62372f")
const BRASS := Color("c4a35b")
const GRAPHITE := Color("293436")
const CONCRETE := Color("737a72")
const DARK_CONCRETE := Color("474e4b")
const GALVANIZED := Color("8a9996")
const POWER_TEAL := Color("4c8586")
const COLD_BLUE := Color("72a4ad")
const RAIL_AMBER := Color("d0a54f")
const STATUS_GREEN := Color("79ad79")
const STATUS_OFF := Color("37443f")
const SURVEY_RED := Color("b75b4d")

const PARCEL_ORDER: Array[StringName] = [ORCHARD_ROW_ID, CREEKSIDE_YARD_ID]
const PAD_ORDER: Array[StringName] = [
	ORCHARD_WEST_PAD,
	ORCHARD_EAST_PAD,
	ORCHARD_SERVICE_PAD,
	CREEKSIDE_WEST_PAD,
	CREEKSIDE_EAST_PAD,
	CREEKSIDE_SERVICE_PAD,
]
const MODULE_ORDER: Array[StringName] = [
	COLLECTION_RAIL_HUB_ID,
	GRAIN_RECOVERY_MILL_ID,
	CREEKSIDE_CHILLING_EXCHANGE_ID,
	CONTRACTOR_ROOST_ID,
]

var _built := false
var _parcel_roots: Dictionary = {}
var _pad_roots: Dictionary = {}
var _pad_stage_roots: Dictionary = {}
var _module_roots: Dictionary = {}
var _pad_status_labels: Dictionary = {}
var _service_lamps: Dictionary = {}
var _material_cache: Dictionary = {}
var _reveal_marker_root: Node3D
var _reveal_marker_edges: Array[MeshInstance3D] = []
var _reveal_marker_posts: Array[MeshInstance3D] = []
var _reveal_target: Dictionary = {}


static func parcel_catalog() -> Array[Dictionary]:
	return [
		{
			"id": ORCHARD_ROW_ID,
			"label": "ORCHARD ROW",
			"subtitle": "COLLECTION & GRAIN WORKS",
			"footprint": ORCHARD_ROW_FOOTPRINT,
			"cross_route": ORCHARD_ROW_CROSS_ROUTE,
			"pad_ids": [ORCHARD_WEST_PAD, ORCHARD_EAST_PAD, ORCHARD_SERVICE_PAD],
		},
		{
			"id": CREEKSIDE_YARD_ID,
			"label": "CREEKSIDE YARD",
			"subtitle": "COLD STORE & CONTRACTOR WORKS",
			"footprint": CREEKSIDE_YARD_FOOTPRINT,
			"cross_route": CREEKSIDE_YARD_CROSS_ROUTE,
			"pad_ids": [CREEKSIDE_WEST_PAD, CREEKSIDE_EAST_PAD, CREEKSIDE_SERVICE_PAD],
		},
	]


static func declared_footprint(parcel_id: StringName) -> Rect2:
	match parcel_id:
		ORCHARD_ROW_ID:
			return ORCHARD_ROW_FOOTPRINT
		CREEKSIDE_YARD_ID:
			return CREEKSIDE_YARD_FOOTPRINT
	return Rect2()


static func declared_footprints() -> Array[Rect2]:
	return [ORCHARD_ROW_FOOTPRINT, CREEKSIDE_YARD_FOOTPRINT]


static func pad_catalog(parcel_id: StringName = &"") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var definitions: Array[Dictionary] = [
		_pad_record(ORCHARD_WEST_PAD, ORCHARD_ROW_ID, "ORCHARD WEST", Rect2(Vector2(19.20, 18.20), Vector2(3.40, 7.55)), [COLLECTION_RAIL_HUB_ID, GRAIN_RECOVERY_MILL_ID], false),
		_pad_record(ORCHARD_EAST_PAD, ORCHARD_ROW_ID, "ORCHARD EAST", Rect2(Vector2(23.35, 18.20), Vector2(3.40, 7.55)), [COLLECTION_RAIL_HUB_ID, GRAIN_RECOVERY_MILL_ID], false),
		_pad_record(ORCHARD_SERVICE_PAD, ORCHARD_ROW_ID, "SHARED SERVICE SPINE", Rect2(Vector2(27.50, 18.20), Vector2(3.40, 7.55)), [], true),
		_pad_record(CREEKSIDE_WEST_PAD, CREEKSIDE_YARD_ID, "CREEKSIDE WEST", Rect2(Vector2(19.20, 30.20), Vector2(3.40, 7.55)), [CREEKSIDE_CHILLING_EXCHANGE_ID, CONTRACTOR_ROOST_ID], false),
		_pad_record(CREEKSIDE_EAST_PAD, CREEKSIDE_YARD_ID, "CREEKSIDE EAST", Rect2(Vector2(23.35, 30.20), Vector2(3.40, 7.55)), [CREEKSIDE_CHILLING_EXCHANGE_ID, CONTRACTOR_ROOST_ID], false),
		_pad_record(CREEKSIDE_SERVICE_PAD, CREEKSIDE_YARD_ID, "SHARED SERVICE SPINE", Rect2(Vector2(27.50, 30.20), Vector2(3.40, 7.55)), [], true),
	]
	for definition: Dictionary in definitions:
		if parcel_id == &"" or StringName(String(definition.get("parcel_id", ""))) == parcel_id:
			result.append(definition.duplicate(true))
	return result


static func declared_pad_footprint(pad_id: StringName) -> Rect2:
	for pad: Dictionary in pad_catalog():
		if StringName(String(pad.get("id", ""))) == pad_id:
			return pad.get("footprint", Rect2()) as Rect2
	return Rect2()


static func module_catalog() -> Array[Dictionary]:
	return [
		{"id": COLLECTION_RAIL_HUB_ID, "label": "COLLECTION RAIL HUB", "parcel_id": ORCHARD_ROW_ID, "footprint": Vector2(3.04, 5.10), "max_height": 3.55},
		{"id": GRAIN_RECOVERY_MILL_ID, "label": "GRAIN RECOVERY MILL", "parcel_id": ORCHARD_ROW_ID, "footprint": Vector2(3.04, 5.10), "max_height": 4.25},
		{"id": CREEKSIDE_CHILLING_EXCHANGE_ID, "label": "CREEKSIDE CHILLING EXCHANGE", "parcel_id": CREEKSIDE_YARD_ID, "footprint": Vector2(3.04, 5.10), "max_height": 3.60},
		{"id": CONTRACTOR_ROOST_ID, "label": "CONTRACTOR ROOST", "parcel_id": CREEKSIDE_YARD_ID, "footprint": Vector2(3.04, 5.10), "max_height": 3.45},
	]


static func protected_trunk_footprint() -> Rect2:
	return SHARED_SERVICE_TRUNK


static func navigation_footprints(_snapshot: Dictionary = {}) -> Array[Rect2]:
	# These are protected circulation contracts, not NavigationRegion3D nodes.
	return [ORCHARD_ROW_CROSS_ROUTE, CREEKSIDE_YARD_CROSS_ROUTE, SHARED_SERVICE_TRUNK]


static func camera_bounds(_snapshot: Dictionary = {}) -> AABB:
	var xz := ORCHARD_ROW_FOOTPRINT.merge(CREEKSIDE_YARD_FOOTPRINT)
	xz = xz.merge(SHARED_SERVICE_TRUNK)
	return AABB(
		Vector3(xz.position.x, -0.18, xz.position.y),
		Vector3(xz.size.x, MAX_VISUAL_HEIGHT + 0.18, xz.size.y),
	)


static func project_stage(record: Dictionary) -> StringName:
	if record.is_empty():
		return &"empty"
	var raw := StringName(String(record.get("stage", record.get("status", "queued"))).strip_edges().to_lower())
	var duration := maxi(0, int(record.get("duration_shifts", 0)))
	var remaining := clampi(int(record.get("remaining_shifts", duration)), 0, duration)
	var inferred_progress := (
		float(duration - remaining) / float(duration)
		if duration > 0 else
		0.0
	)
	var progress := float(record.get(
		"progress",
		record.get("progress_ratio", inferred_progress),
	))
	if progress > 1.0:
		progress /= 100.0
	progress = clampf(progress, 0.0, 1.0)
	if raw in [&"complete", &"completed", &"operational", &"commissioned", &"ready"] or progress >= 0.999:
		return &"complete"
	if raw in [&"frame", &"framing", &"shell", &"scaffold"]:
		return &"frame"
	if raw in [&"foundation", &"foundations", &"groundwork", &"groundworks", &"site_work"]:
		return &"foundation"
	if raw in [&"building", &"construction", &"under_construction"]:
		return &"foundation" if progress < 0.45 else &"frame"
	if raw == &"active":
		return &"foundation" if progress < 0.50 else &"frame"
	return &"queued"


static func _pad_record(
	pad_id: StringName,
	parcel_id: StringName,
	label: String,
	footprint: Rect2,
	allowed_module_ids: Array,
	route_blocked: bool,
) -> Dictionary:
	return {
		"id": pad_id,
		"parcel_id": parcel_id,
		"label": label,
		"center": Vector3(footprint.get_center().x, 0.0, footprint.get_center().y),
		"footprint": footprint,
		"route_blocked": route_blocked,
		"blocked_reason": "Reserved for the shared flock, rail, power, and cold-chain trunk." if route_blocked else "",
		"allowed_module_ids": allowed_module_ids.duplicate(),
	}


func _ready() -> void:
	name = "CampusPortfolioVisual"
	set_meta(&"visual_only", true)
	set_meta(&"collision_free", true)
	set_meta(&"navigation_free", true)
	set_meta(&"declared_footprints", declared_footprints())
	set_meta(&"navigation_footprints", navigation_footprints())
	if not _built:
		build()


func build() -> void:
	clear()
	_built = true
	_build_shared_infrastructure()
	for parcel: Dictionary in parcel_catalog():
		_build_parcel(parcel)
	_build_reveal_marker()
	apply_snapshot({})


func clear() -> void:
	for child: Node in get_children():
		child.free()
	_parcel_roots.clear()
	_pad_roots.clear()
	_pad_stage_roots.clear()
	_module_roots.clear()
	_pad_status_labels.clear()
	_service_lamps.clear()
	_material_cache.clear()
	_reveal_marker_root = null
	_reveal_marker_edges.clear()
	_reveal_marker_posts.clear()
	_reveal_target.clear()
	_built = false


func show_reveal_target(
		parcel_id: StringName,
		pad_id: StringName = &"",
		action_id: StringName = &"",
) -> bool:
	if not _built:
		build()
	var footprint := declared_pad_footprint(pad_id) if pad_id != &"" else declared_footprint(parcel_id)
	if footprint.size.x <= 0.0 or footprint.size.y <= 0.0 or _reveal_marker_root == null:
		hide_reveal_target()
		return false
	var center := footprint.get_center()
	_reveal_marker_root.position = Vector3(center.x, 0.0, center.y)
	var half_x := footprint.size.x * 0.5
	var half_z := footprint.size.y * 0.5
	_set_marker_box(_reveal_marker_edges[0], Vector3(footprint.size.x + 0.20, 0.055, 0.095), Vector3(0.0, 0.12, -half_z - 0.07))
	_set_marker_box(_reveal_marker_edges[1], Vector3(footprint.size.x + 0.20, 0.055, 0.095), Vector3(0.0, 0.12, half_z + 0.07))
	_set_marker_box(_reveal_marker_edges[2], Vector3(0.095, 0.055, footprint.size.y + 0.20), Vector3(-half_x - 0.07, 0.12, 0.0))
	_set_marker_box(_reveal_marker_edges[3], Vector3(0.095, 0.055, footprint.size.y + 0.20), Vector3(half_x + 0.07, 0.12, 0.0))
	var corners: Array[Vector3] = [
		Vector3(-half_x - 0.07, 0.60, -half_z - 0.07),
		Vector3(half_x + 0.07, 0.60, -half_z - 0.07),
		Vector3(-half_x - 0.07, 0.60, half_z + 0.07),
		Vector3(half_x + 0.07, 0.60, half_z + 0.07),
	]
	for index in _reveal_marker_posts.size():
		_set_marker_box(_reveal_marker_posts[index], Vector3(0.105, 1.20, 0.105), corners[index])
	_reveal_marker_root.visible = true
	_reveal_target = {
		"parcel_id": parcel_id,
		"pad_id": pad_id,
		"action_id": action_id,
		"footprint": footprint,
		"center": Vector3(center.x, 0.0, center.y),
	}
	return true


func hide_reveal_target() -> void:
	if _reveal_marker_root != null:
		_reveal_marker_root.visible = false
	_reveal_target.clear()


func reveal_target_snapshot() -> Dictionary:
	return _reveal_target.duplicate(true)


func apply_snapshot(snapshot: Dictionary) -> void:
	if not _built:
		build()
	var portfolio := _portfolio_from_snapshot(snapshot)
	var parcels := _records_by_id(portfolio.get("parcels", []), "id")
	var projects := _records_by_id(portfolio.get("projects", []), "pad_id")
	# Completed jobs leave the authoritative queue. Rebuild their pad projection
	# from installed modules so commissioned buildings remain visible permanently.
	var installed_modules := _records_by_id(
		portfolio.get("modules", portfolio.get("module_catalog", [])),
		"id",
	)
	for module_id: StringName in installed_modules:
		var installed_module := installed_modules[module_id] as Dictionary
		if not bool(installed_module.get("installed", installed_module.get("built", false))):
			continue
		var installed_pad := StringName(String(installed_module.get("pad_id", "")))
		if installed_pad == &"":
			continue
		projects[installed_pad] = {
			"module_id": module_id,
			"pad_id": installed_pad,
			"status": &"complete",
			"progress": 1.0,
		}
	# Accept projects nested under parcel records as a convenience for strict
	# projections that group their portfolio by deed.
	for parcel_id: StringName in PARCEL_ORDER:
		var parcel_record := parcels.get(parcel_id, {}) as Dictionary
		for nested_value: Variant in parcel_record.get("projects", []) as Array:
			if nested_value is Dictionary:
				var nested := nested_value as Dictionary
				var nested_pad := StringName(String(nested.get("pad_id", "")))
				if nested_pad != &"":
					projects[nested_pad] = nested.duplicate(true)

	for parcel_id: StringName in PARCEL_ORDER:
		var roots := _parcel_roots.get(parcel_id, {}) as Dictionary
		var record := parcels.get(parcel_id, {}) as Dictionary
		var owned := _parcel_owned(record)
		var unowned_root := roots.get("unowned") as Node3D
		var owned_root := roots.get("owned") as Node3D
		if unowned_root != null:
			unowned_root.visible = not owned
		if owned_root != null:
			owned_root.visible = owned
		for pad: Dictionary in pad_catalog(parcel_id):
			var pad_id := StringName(String(pad.get("id", "")))
			var pad_root := _pad_roots.get(pad_id) as Node3D
			if pad_root != null:
				pad_root.visible = owned
			if bool(pad.get("route_blocked", false)):
				continue
			_apply_project_to_pad(pad_id, projects.get(pad_id, {}) as Dictionary)

	for service_id: StringName in [&"collection_rail", &"power", &"cold_chain"]:
		var lamp := _service_lamps.get(service_id) as MeshInstance3D
		if lamp != null:
			lamp.material_override = _material(STATUS_GREEN if _service_active(portfolio, service_id) else STATUS_OFF, 0.46)


func _apply_project_to_pad(pad_id: StringName, project: Dictionary) -> void:
	var stage := project_stage(project)
	var stages := _pad_stage_roots.get(pad_id, {}) as Dictionary
	for stage_id: StringName in [&"queued", &"foundation", &"frame"]:
		var stage_root := stages.get(stage_id) as Node3D
		if stage_root != null:
			stage_root.visible = stage == stage_id
	var module_id := StringName(String(project.get("module_id", "")))
	var modules := _module_roots.get(pad_id, {}) as Dictionary
	for candidate_id: Variant in modules.keys():
		var module_root := modules.get(candidate_id) as Node3D
		if module_root != null:
			module_root.visible = stage == &"complete" and StringName(String(candidate_id)) == module_id
	var label := _pad_status_labels.get(pad_id) as Label3D
	if label != null:
		var copy := "OPEN MODULE PAD"
		if stage != &"empty":
			copy = "%s / %s" % [String(module_id).replace("_", " ").to_upper(), String(stage).replace("_", " ").to_upper()]
		EnvironmentalSignageScript.set_copy(label, copy)


func _build_shared_infrastructure() -> void:
	var infrastructure := _new_root("PortfolioSharedInfrastructure")
	infrastructure.set_meta(&"navigation_footprint", SHARED_SERVICE_TRUNK)
	var center := SHARED_SERVICE_TRUNK.get_center()
	_add_box(infrastructure, "PortfolioSharedServiceTrunk", Vector3(SHARED_SERVICE_TRUNK.size.x, 0.11, SHARED_SERVICE_TRUNK.size.y), Vector3(center.x, -0.035, center.y), DARK_CONCRETE)
	for edge_x: float in [SHARED_SERVICE_TRUNK.position.x + 0.08, SHARED_SERVICE_TRUNK.end.x - 0.08]:
		_add_box(infrastructure, "PortfolioTrunkBrassEdge", Vector3(0.035, 0.02, SHARED_SERVICE_TRUNK.size.y - 0.18), Vector3(edge_x, 0.028, center.y), BRASS.darkened(0.16), 0.50, 0.28)

	# The collection carrier is overhead, while power and cold chain occupy a
	# narrow east chase. The 2.10 m ground route therefore remains visually clear.
	_add_box(infrastructure, "PortfolioCollectionRail", Vector3(0.12, 0.12, SHARED_SERVICE_TRUNK.size.y), Vector3(29.20, 3.18, center.y), GALVANIZED, 0.40, 0.32)
	_add_box(infrastructure, "PortfolioPowerConduit", Vector3(0.10, 0.10, SHARED_SERVICE_TRUNK.size.y), Vector3(30.43, 0.18, center.y), POWER_TEAL, 0.42, 0.24)
	_add_box(infrastructure, "PortfolioColdChainLine", Vector3(0.12, 0.12, SHARED_SERVICE_TRUNK.size.y), Vector3(30.67, 0.28, center.y), COLD_BLUE, 0.40, 0.28)
	for post_index in 6:
		var post_z := 7.20 + float(post_index) * 6.10
		_add_box(infrastructure, "PortfolioRailPost_%02d" % (post_index + 1), Vector3(0.12, 3.18, 0.12), Vector3(29.20, 1.59, post_z), GRAPHITE, 0.50, 0.22)
		_add_box(infrastructure, "PortfolioRailBracket_%02d" % (post_index + 1), Vector3(0.62, 0.10, 0.10), Vector3(29.48, 3.12, post_z), GALVANIZED, 0.42, 0.28)
	for junction_index in 2:
		var junction_z: float = float([16.40, 28.40][junction_index])
		_add_box(infrastructure, "PortfolioCrossRail_%02d" % (junction_index + 1), Vector3(8.30, 0.12, 0.12), Vector3(25.05, 3.18, junction_z), GALVANIZED, 0.40, 0.32)
		for branch_x: float in [20.90, 25.05]:
			_add_box(infrastructure, "PortfolioModuleRailDrop", Vector3(0.10, 0.10, 1.42), Vector3(branch_x, 3.18, junction_z + 0.71), GALVANIZED, 0.40, 0.30)

	var meter := _add_box(infrastructure, "PortfolioServiceMeterCabinet", Vector3(1.34, 1.08, 0.32), Vector3(30.63, 0.68, 38.20), GRAPHITE, 0.52, 0.20)
	var status_host := _add_box(meter, "PortfolioServiceStatusHost", Vector3(1.12, 0.28, 0.04), Vector3(0.0, 0.25, 0.18), DARK_GREEN)
	EnvironmentalSignageScript.add_panel(status_host, "PortfolioServiceStatus", "SHARED CAMPUS SERVICE", Vector3(0.0, 0.0, 0.026), Vector2(0.98, 0.18), DARK_GREEN, CREAM, Vector3.ZERO, 9, 0.0018, &"utility", &"machine")
	for service_index in 3:
		var service_id: StringName = [&"collection_rail", &"power", &"cold_chain"][service_index]
		var color: Color = [RAIL_AMBER, POWER_TEAL, COLD_BLUE][service_index]
		var lamp := _add_sphere(meter, "Portfolio%sLamp" % String(service_id).to_pascal_case(), Vector3(-0.38 + float(service_index) * 0.38, -0.21, 0.22), Vector3(0.16, 0.16, 0.09), STATUS_OFF)
		lamp.set_meta(&"service_id", service_id)
		lamp.set_meta(&"active_color", color)
		_service_lamps[service_id] = lamp


func _build_reveal_marker() -> void:
	_reveal_marker_root = _new_root("CampusPortfolioRevealMarker")
	_reveal_marker_root.set_meta(&"visual_only", true)
	_reveal_marker_root.set_meta(&"collision_free", true)
	var marker_material := StandardMaterial3D.new()
	marker_material.albedo_color = Color("f0c85f")
	marker_material.roughness = 0.34
	marker_material.metallic = 0.18
	marker_material.emission_enabled = true
	marker_material.emission = Color("c99a3d")
	marker_material.emission_energy_multiplier = 1.7
	for edge_index in 4:
		var edge := MeshInstance3D.new()
		edge.name = "CampusPortfolioRevealEdge_%d" % edge_index
		edge.mesh = BoxMesh.new()
		edge.material_override = marker_material
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_reveal_marker_root.add_child(edge)
		_reveal_marker_edges.append(edge)
	for post_index in 4:
		var post := MeshInstance3D.new()
		post.name = "CampusPortfolioRevealPost_%d" % post_index
		post.mesh = BoxMesh.new()
		post.material_override = marker_material
		post.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_reveal_marker_root.add_child(post)
		_reveal_marker_posts.append(post)
	_reveal_marker_root.visible = false


func _set_marker_box(instance: MeshInstance3D, size: Vector3, position: Vector3) -> void:
	if instance == null:
		return
	var box := instance.mesh as BoxMesh
	if box == null:
		box = BoxMesh.new()
		instance.mesh = box
	box.size = size
	instance.position = position


func _build_parcel(parcel: Dictionary) -> void:
	var parcel_id := StringName(String(parcel.get("id", "")))
	var footprint := parcel.get("footprint", Rect2()) as Rect2
	var center := footprint.get_center()
	var prefix := String(parcel_id).to_pascal_case()
	var root := _new_root("%sParcel" % prefix)
	root.set_meta(&"parcel_id", parcel_id)
	root.set_meta(&"declared_footprint", footprint)

	var field_color := ORCHARD_GREEN if parcel_id == ORCHARD_ROW_ID else CREEKSIDE_GREEN
	_add_box(root, "%sUnfiledGround" % prefix, Vector3(footprint.size.x, 0.14, footprint.size.y), Vector3(center.x, -0.09, center.y), field_color.darkened(0.10))
	_build_parcel_identity(root, parcel)

	var unowned := _new_root("%sUnownedDeedStakes" % prefix, root)
	unowned.set_meta(&"portfolio_stage", &"unowned")
	_build_unowned_deed(unowned, parcel)
	var owned := _new_root("%sOwnedFarmParcel" % prefix, root)
	owned.set_meta(&"portfolio_stage", &"owned")
	_build_owned_parcel(owned, parcel)
	_parcel_roots[parcel_id] = {"root": root, "unowned": unowned, "owned": owned}

	for pad: Dictionary in pad_catalog(parcel_id):
		_build_pad(root, pad)


func _build_parcel_identity(parent: Node3D, parcel: Dictionary) -> void:
	var parcel_id := StringName(String(parcel.get("id", "")))
	var footprint := parcel.get("footprint", Rect2()) as Rect2
	var prefix := String(parcel_id).to_pascal_case()
	var gate_x := footprint.position.x + 2.15
	var gate_z := footprint.position.y + 0.18
	var gate := _new_root("%sIdentityGate" % prefix, parent)
	gate.set_meta(&"ground_supported", true)
	for side: float in [-1.0, 1.0]:
		_add_box(gate, "%sIdentityPost" % prefix, Vector3(0.18, 1.90, 0.18), Vector3(gate_x + side * 1.36, 0.95, gate_z), DARK_TIMBER)
		_add_box(gate, "%sIdentityPostFoot" % prefix, Vector3(0.32, 0.12, 0.32), Vector3(gate_x + side * 1.36, 0.06, gate_z), CONCRETE.darkened(0.10))
	var host := _add_box(gate, "%sIdentityHost" % prefix, Vector3(3.30, 0.62, 0.14), Vector3(gate_x, 1.58, gate_z), TIMBER)
	_add_box(gate, "%sIdentityWeatherCap" % prefix, Vector3(3.50, 0.08, 0.19), Vector3(gate_x, 1.93, gate_z), DARK_TIMBER)
	EnvironmentalSignageScript.add_panel(
		host,
		"%sIdentity" % prefix,
		"%s\n%s" % [String(parcel.get("label", parcel_id)), String(parcel.get("subtitle", "CAMPUS DEED"))],
		Vector3(0.0, 0.0, 0.080),
		Vector2(2.98, 0.46),
		TIMBER,
		CREAM,
		Vector3.ZERO,
		15,
		0.0026,
		&"primary",
		&"destination",
	)


func _build_unowned_deed(parent: Node3D, parcel: Dictionary) -> void:
	var parcel_id := StringName(String(parcel.get("id", "")))
	var footprint := parcel.get("footprint", Rect2()) as Rect2
	var prefix := String(parcel_id).to_pascal_case()
	for x: float in [footprint.position.x + 0.50, footprint.end.x - 0.50]:
		for z: float in [footprint.position.y + 0.50, footprint.end.y - 0.50]:
			_add_box(parent, "%sDeedStake" % prefix, Vector3(0.10, 0.86, 0.10), Vector3(x, 0.43, z), TIMBER)
			_add_box(parent, "%sSurveyFlag" % prefix, Vector3(0.30, 0.18, 0.025), Vector3(x + 0.13, 0.73, z), SURVEY_RED)
	var notice_host := _add_box(parent, "%sDeedNoticeHost" % prefix, Vector3(1.56, 0.72, 0.08), Vector3(footprint.end.x - 1.40, 0.94, footprint.position.y + 0.48), DARK_TIMBER)
	for post_x: float in [-0.58, 0.58]:
		_add_box(notice_host, "%sDeedNoticePost" % prefix, Vector3(0.09, 0.74, 0.09), Vector3(post_x, -0.68, 0.0), DARK_TIMBER)
	EnvironmentalSignageScript.add_panel(notice_host, "%sDeedNotice" % prefix, "DEED OPTION HELD\nSURVEY FILE REQUIRED", Vector3(0.0, 0.0, 0.050), Vector2(1.34, 0.54), PAPER, DEEP_RED, Vector3.ZERO, 11, 0.0020, &"utility", &"paper")


func _build_owned_parcel(parent: Node3D, parcel: Dictionary) -> void:
	var parcel_id := StringName(String(parcel.get("id", "")))
	var footprint := parcel.get("footprint", Rect2()) as Rect2
	var cross_route := parcel.get("cross_route", Rect2()) as Rect2
	var prefix := String(parcel_id).to_pascal_case()
	var center := footprint.get_center()
	var ground_color := ORCHARD_LIGHT if parcel_id == ORCHARD_ROW_ID else CREEKSIDE_GREEN.lightened(0.08)
	_add_box(parent, "%sMownGround" % prefix, Vector3(footprint.size.x - 0.24, 0.035, footprint.size.y - 0.24), Vector3(center.x, 0.002, center.y), ground_color)
	var route_center := cross_route.get_center()
	_add_box(parent, "%sCrossRoute" % prefix, Vector3(cross_route.size.x, 0.055, cross_route.size.y), Vector3(route_center.x, 0.035, route_center.y), CONCRETE)
	for dash_index in 9:
		_add_box(parent, "%sRouteDash_%02d" % [prefix, dash_index + 1], Vector3(0.68, 0.018, 0.055), Vector3(19.72 + float(dash_index) * 1.16, 0.075, route_center.y), CREAM)

	# Low perimeter planting gives each deed a farm identity without entering the
	# cross-route or any legal module pad.
	if parcel_id == ORCHARD_ROW_ID:
		for tree_index in 4:
			var tree_x := footprint.position.x + 0.55 + float(tree_index) * 3.65
			_add_box(parent, "OrchardTreeTrunk", Vector3(0.18, 0.92, 0.18), Vector3(tree_x, 0.46, footprint.end.y - 0.45), TIMBER)
			_add_sphere(parent, "OrchardTreeCrown", Vector3(tree_x, 1.18, footprint.end.y - 0.45), Vector3(0.82, 0.68, 0.82), DARK_GREEN.lightened(0.12))
			_add_sphere(parent, "OrchardFruit", Vector3(tree_x + 0.22, 1.24, footprint.end.y - 0.68), Vector3.ONE * 0.12, BARN_RED)
	else:
		_add_box(parent, "CreeksideWaterRill", Vector3(12.10, 0.035, 0.56), Vector3(center.x, 0.025, footprint.end.y - 0.42), CREEK_BLUE)
		for reed_index in 12:
			var reed_x := footprint.position.x + 0.55 + float(reed_index) * 1.02
			_add_box(parent, "CreeksideReed", Vector3(0.035, 0.42 + float(reed_index % 3) * 0.10, 0.035), Vector3(reed_x, 0.24, footprint.end.y - 0.62), ORCHARD_GREEN.darkened(0.08))


func _build_pad(parent: Node3D, pad: Dictionary) -> void:
	var pad_id := StringName(String(pad.get("id", "")))
	var footprint := pad.get("footprint", Rect2()) as Rect2
	var center := footprint.get_center()
	var pad_root := _new_root("Pad_%s" % String(pad_id), parent)
	pad_root.position = Vector3(center.x, 0.0, center.y)
	pad_root.set_meta(&"pad_id", pad_id)
	pad_root.set_meta(&"pad_footprint", footprint)
	pad_root.set_meta(&"route_blocked", bool(pad.get("route_blocked", false)))
	_pad_roots[pad_id] = pad_root

	if bool(pad.get("route_blocked", false)):
		_build_protected_pad(pad_root, pad)
		return

	_add_box(pad_root, "ModulePad_%s" % String(pad_id), Vector3(3.40, 0.055, 7.55), Vector3.ZERO, DARK_CONCRETE)
	for edge_x: float in [-1.64, 1.64]:
		_add_box(pad_root, "ModulePadEdge", Vector3(0.07, 0.04, 7.30), Vector3(edge_x, 0.050, 0.0), BRASS.darkened(0.12), 0.52, 0.24)
	for edge_z: float in [-3.68, 3.68]:
		_add_box(pad_root, "ModulePadEdge", Vector3(3.28, 0.04, 0.07), Vector3(0.0, 0.050, edge_z), BRASS.darkened(0.12), 0.52, 0.24)
	var status_host := _add_box(pad_root, "ModulePadStatusHost_%s" % String(pad_id), Vector3(2.34, 0.32, 0.055), Vector3(0.0, 0.26, -3.44), GRAPHITE)
	var label := EnvironmentalSignageScript.add_panel(status_host, "ModulePadStatus_%s" % String(pad_id), "OPEN MODULE PAD", Vector3(0.0, 0.0, 0.034), Vector2(2.08, 0.22), GRAPHITE, CREAM, Vector3.ZERO, 10, 0.0019, &"utility", &"machine")
	_pad_status_labels[pad_id] = label

	var queued := _new_root("ProjectQueuedStage_%s" % String(pad_id), pad_root)
	queued.set_meta(&"project_stage", &"queued")
	_build_queued_stage(queued)
	var foundation := _new_root("ProjectFoundationStage_%s" % String(pad_id), pad_root)
	foundation.set_meta(&"project_stage", &"foundation")
	_build_foundation_stage(foundation)
	var frame := _new_root("ProjectFrameStage_%s" % String(pad_id), pad_root)
	frame.set_meta(&"project_stage", &"frame")
	_build_frame_stage(frame)
	_pad_stage_roots[pad_id] = {&"queued": queued, &"foundation": foundation, &"frame": frame}

	var modules: Dictionary = {}
	for module_value: Variant in pad.get("allowed_module_ids", []) as Array:
		var module_id := StringName(String(module_value))
		var module_root := _new_root("Module_%s_%s" % [String(module_id), String(pad_id)], pad_root)
		module_root.set_meta(&"module_id", module_id)
		module_root.set_meta(&"pad_id", pad_id)
		_build_complete_module(module_root, module_id)
		module_root.visible = false
		modules[module_id] = module_root
	_module_roots[pad_id] = modules


func _build_protected_pad(parent: Node3D, pad: Dictionary) -> void:
	var pad_id := StringName(String(pad.get("id", "")))
	_add_box(parent, "ProtectedServicePad_%s" % String(pad_id), Vector3(3.40, 0.045, 7.55), Vector3.ZERO, DEEP_RED.darkened(0.12))
	for cross_index in 2:
		var cross := _add_box(parent, "ProtectedServiceCrossbar", Vector3(2.72, 0.15, 0.11), Vector3(0.0, 0.60, -2.76), SURVEY_RED)
		cross.rotation_degrees.z = -31.0 if cross_index == 0 else 31.0
	var host := _add_box(parent, "ProtectedServiceNoticeHost_%s" % String(pad_id), Vector3(2.12, 0.48, 0.07), Vector3(0.0, 0.84, -2.60), RAIL_AMBER.darkened(0.08))
	EnvironmentalSignageScript.add_panel(host, "ProtectedServiceNotice_%s" % String(pad_id), "KEEP CLEAR\nSHARED SERVICE TRUNK", Vector3(0.0, 0.0, 0.044), Vector2(1.88, 0.36), RAIL_AMBER.darkened(0.08), DEEP_RED, Vector3.ZERO, 11, 0.0020, &"secondary", &"stencil")


func _build_queued_stage(parent: Node3D) -> void:
	for x: float in [-1.42, 1.42]:
		for z: float in [-3.34, 3.34]:
			_add_box(parent, "QueuedSurveyStake", Vector3(0.08, 0.72, 0.08), Vector3(x, 0.36, z), TIMBER)
			_add_box(parent, "QueuedSurveyFlag", Vector3(0.26, 0.15, 0.025), Vector3(x + 0.11, 0.62, z), SURVEY_RED)
	for side_x: float in [-1.48, 1.48]:
		_add_box(parent, "QueuedSafetyFence", Vector3(0.06, 0.44, 6.46), Vector3(side_x, 0.30, 0.10), OATMEAL)
	_add_box(parent, "QueuedMaterialPallet", Vector3(1.18, 0.24, 0.82), Vector3(0.72, 0.12, 1.70), TIMBER)


func _build_foundation_stage(parent: Node3D) -> void:
	_add_box(parent, "ProjectFoundationSlab", Vector3(2.96, 0.18, 5.18), Vector3(0.0, 0.09, 0.34), CONCRETE)
	for x: float in [-1.18, 1.18]:
		for z: float in [-1.78, 1.78]:
			_add_box(parent, "ProjectFoundationFooting", Vector3(0.38, 0.28, 0.38), Vector3(x, 0.20, z + 0.34), DARK_CONCRETE)
	_add_box(parent, "FoundationPowerStub", Vector3(0.10, 0.54, 0.10), Vector3(1.02, 0.36, -1.62), POWER_TEAL)
	_add_box(parent, "FoundationColdStub", Vector3(0.12, 0.48, 0.12), Vector3(1.25, 0.32, -1.62), COLD_BLUE)


func _build_frame_stage(parent: Node3D) -> void:
	_add_box(parent, "FrameStageSlab", Vector3(2.96, 0.18, 5.18), Vector3(0.0, 0.09, 0.34), CONCRETE)
	for x: float in [-1.22, 1.22]:
		for z: float in [-1.84, 1.84]:
			_add_box(parent, "TimberFramePost", Vector3(0.15, 2.72, 0.15), Vector3(x, 1.45, z + 0.34), TIMBER)
	for z: float in [-1.50, 0.34, 2.18]:
		_add_box(parent, "TimberFrameCrossbeam", Vector3(2.60, 0.15, 0.15), Vector3(0.0, 2.76, z), DARK_TIMBER)
	for x: float in [-1.48, 1.48]:
		_add_box(parent, "FrameScaffoldStandard", Vector3(0.08, 3.12, 0.08), Vector3(x, 1.56, 0.34), GALVANIZED, 0.42, 0.30)
		for y: float in [0.72, 1.62, 2.52]:
			_add_box(parent, "FrameScaffoldLedger", Vector3(0.08, 0.08, 5.36), Vector3(x, y, 0.34), GALVANIZED, 0.42, 0.30)


func _build_complete_module(parent: Node3D, module_id: StringName) -> void:
	match module_id:
		COLLECTION_RAIL_HUB_ID:
			_build_collection_rail_hub(parent)
		GRAIN_RECOVERY_MILL_ID:
			_build_grain_recovery_mill(parent)
		CREEKSIDE_CHILLING_EXCHANGE_ID:
			_build_chilling_exchange(parent)
		CONTRACTOR_ROOST_ID:
			_build_contractor_roost(parent)


func _build_collection_rail_hub(parent: Node3D) -> void:
	_add_box(parent, "CollectionRailHubFoundation", Vector3(3.04, 0.18, 5.10), Vector3(0.0, 0.09, 0.34), DARK_CONCRETE)
	var body := _add_box(parent, "CollectionRailHubBody", Vector3(2.70, 2.12, 3.54), Vector3(0.0, 1.28, 0.48), CREAM)
	_add_gabled_roof(parent, "CollectionRailHubRoof", Vector3(0.0, 2.52, 0.48), Vector3(1.58, 0.14, 3.86), BARN_RED)
	_add_box(parent, "CollectionRailHubGantry", Vector3(2.86, 0.13, 0.13), Vector3(0.0, 3.12, -1.92), GALVANIZED, 0.40, 0.32)
	for x: float in [-1.20, 1.20]:
		_add_box(parent, "CollectionRailHubGantryPost", Vector3(0.12, 2.82, 0.12), Vector3(x, 1.50, -1.92), GRAPHITE)
	for lane_x: float in [-0.72, 0.0, 0.72]:
		_add_box(parent, "CollectionRailLaneChute", Vector3(0.38, 0.38, 0.76), Vector3(lane_x, 1.18, -1.62), OATMEAL)
		var collar := _add_cylinder(parent, "CollectionRailEmptyCarrier", Vector3(lane_x, 2.84, -1.90), 0.14, 0.26, GALVANIZED, 0.38, 0.30)
		collar.rotation_degrees.x = 90.0
	_add_module_identity(body, "CollectionRailHubIdentity", "COLLECTION RAIL HUB", DARK_GREEN, CREAM)


func _build_grain_recovery_mill(parent: Node3D) -> void:
	_add_box(parent, "GrainMillFoundation", Vector3(3.04, 0.18, 5.10), Vector3(0.0, 0.09, 0.34), DARK_CONCRETE)
	var body := _add_box(parent, "GrainRecoveryMillBody", Vector3(1.78, 2.38, 3.30), Vector3(-0.48, 1.38, 0.42), OATMEAL)
	_add_gabled_roof(parent, "GrainRecoveryMillRoof", Vector3(-0.48, 2.73, 0.42), Vector3(1.14, 0.14, 3.58), DEEP_RED)
	_add_cylinder(parent, "GrainRecoverySilo", Vector3(0.92, 1.46, 0.74), 0.62, 2.72, GALVANIZED, 0.48, 0.22)
	_add_sphere(parent, "GrainRecoverySiloCap", Vector3(0.92, 2.90, 0.74), Vector3(1.24, 0.48, 1.24), GALVANIZED, 0.48)
	var auger := _add_cylinder(parent, "GrainRecoveryAuger", Vector3(0.18, 2.02, -0.32), 0.12, 2.24, POWER_TEAL, 0.44, 0.20)
	auger.rotation_degrees.z = 53.0
	for sack_index in 3:
		_add_box(parent, "RecoveredGrainSack", Vector3(0.46, 0.58, 0.34), Vector3(-0.82 + float(sack_index) * 0.52, 0.38, -1.58), CREAM.darkened(0.10))
	_add_module_identity(body, "GrainRecoveryMillIdentity", "GRAIN RECOVERY MILL", TIMBER, CREAM)


func _build_chilling_exchange(parent: Node3D) -> void:
	_add_box(parent, "ChillingExchangeFoundation", Vector3(3.04, 0.18, 5.10), Vector3(0.0, 0.09, 0.34), DARK_CONCRETE)
	var body := _add_box(parent, "ChillingExchangeBody", Vector3(2.76, 2.34, 4.28), Vector3(0.0, 1.39, 0.42), Color("d8e2d8"))
	for roof_index in 3:
		var roof := _add_box(parent, "ChillingExchangeSawtoothRoof", Vector3(0.92, 0.14, 4.48), Vector3(-0.92 + float(roof_index) * 0.92, 2.64, 0.42), COLD_BLUE)
		roof.rotation_degrees.z = -14.0
	for fan_x: float in [-0.72, 0.72]:
		var fan := _add_cylinder(parent, "ChillingExchangeCondenserFan", Vector3(fan_x, 1.62, -1.77), 0.34, 0.12, GRAPHITE, 0.54, 0.20)
		fan.rotation_degrees.x = 90.0
		_add_cylinder(parent, "ChillingExchangeFanHub", Vector3(fan_x, 1.62, -1.85), 0.09, 0.14, COLD_BLUE, 0.42, 0.24).rotation_degrees.x = 90.0
	_add_box(parent, "ChillingExchangeColdPipe", Vector3(0.12, 1.80, 0.12), Vector3(1.18, 1.08, -1.72), COLD_BLUE, 0.40, 0.26)
	for basket_x: float in [-0.72, 0.0, 0.72]:
		_add_box(parent, "ChilledBasket", Vector3(0.58, 0.34, 0.58), Vector3(basket_x, 0.32, -1.64), CREEK_BLUE)
	_add_module_identity(body, "ChillingExchangeIdentity", "CREEKSIDE CHILLING EXCHANGE", CREEK_BLUE.darkened(0.20), CREAM)


func _build_contractor_roost(parent: Node3D) -> void:
	_add_box(parent, "ContractorRoostFoundation", Vector3(3.04, 0.18, 5.10), Vector3(0.0, 0.09, 0.34), DARK_CONCRETE)
	var body := _add_box(parent, "ContractorRoostBody", Vector3(2.74, 2.18, 3.74), Vector3(0.0, 1.30, 0.38), Color("d9c6a0"))
	_add_gabled_roof(parent, "ContractorRoostRoof", Vector3(0.0, 2.56, 0.38), Vector3(1.58, 0.14, 4.06), TIMBER)
	_add_box(parent, "ContractorRoostPorch", Vector3(2.42, 0.16, 0.82), Vector3(0.0, 0.20, -1.90), TIMBER)
	for x: float in [-1.04, 1.04]:
		_add_box(parent, "ContractorRoostPorchPost", Vector3(0.11, 1.56, 0.11), Vector3(x, 0.91, -1.90), DARK_TIMBER)
	var table := _add_box(parent, "ContractorBlueprintTable", Vector3(1.62, 0.12, 0.82), Vector3(0.0, 0.86, -0.78), TIMBER)
	_add_box(table, "ContractorBlueprint", Vector3(1.32, 0.02, 0.62), Vector3(0.0, 0.07, 0.0), POWER_TEAL)
	for perch_x: float in [-0.72, 0.72]:
		_add_cylinder(parent, "ContractorPerch", Vector3(perch_x, 0.54, 1.42), 0.07, 0.82, BRASS, 0.48, 0.30).rotation_degrees.z = 90.0
	_add_box(parent, "ContractorToolRack", Vector3(1.88, 1.08, 0.18), Vector3(0.0, 1.16, 2.14), DARK_TIMBER)
	for tool_x: float in [-0.60, -0.20, 0.20, 0.60]:
		_add_box(parent, "ContractorTool", Vector3(0.08, 0.72, 0.08), Vector3(tool_x, 1.18, 2.04), RAIL_AMBER)
	_add_module_identity(body, "ContractorRoostIdentity", "CONTRACTOR ROOST", DARK_TIMBER, CREAM)


func _add_module_identity(body: MeshInstance3D, label_name: String, copy: String, panel_color: Color, ink_color: Color) -> void:
	var body_mesh := body.mesh as BoxMesh
	var face_z := body_mesh.size.z * 0.5 + 0.025 if body_mesh != null else 1.80
	var host := _add_box(body, "%sHost" % label_name, Vector3(2.30, 0.42, 0.05), Vector3(0.0, 0.40, face_z), panel_color)
	EnvironmentalSignageScript.add_panel(host, label_name, copy, Vector3(0.0, 0.0, 0.032), Vector2(2.08, 0.28), panel_color, ink_color, Vector3.ZERO, 11, 0.0021, &"secondary", &"machine")


func _add_gabled_roof(parent: Node3D, part_name: String, center: Vector3, half_size: Vector3, color: Color) -> void:
	for side: float in [-1.0, 1.0]:
		var roof := _add_box(parent, part_name, Vector3(half_size.x, half_size.y, half_size.z), center + Vector3(side * half_size.x * 0.42, 0.0, 0.0), color)
		roof.rotation_degrees.z = side * 23.0
	_add_box(parent, "%sRidge" % part_name, Vector3(0.16, 0.16, half_size.z + 0.10), center + Vector3(0.0, 0.34, 0.0), color.darkened(0.18))


func _portfolio_from_snapshot(snapshot: Dictionary) -> Dictionary:
	var value: Variant = snapshot.get(String(SNAPSHOT_ROOT), snapshot.get(SNAPSHOT_ROOT, snapshot))
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _records_by_id(value: Variant, id_key: String) -> Dictionary:
	var result: Dictionary = {}
	if value is Array:
		for record_value: Variant in value as Array:
			if record_value is Dictionary:
				var record := record_value as Dictionary
				var id := StringName(String(record.get(id_key, "")))
				if id != &"":
					result[id] = record.duplicate(true)
	elif value is Dictionary:
		for key: Variant in (value as Dictionary).keys():
			var record_value: Variant = (value as Dictionary).get(key)
			if record_value is Dictionary:
				var record := (record_value as Dictionary).duplicate(true)
				if not record.has(id_key):
					record[id_key] = String(key)
				var id := StringName(String(record.get(id_key, "")))
				if id != &"":
					result[id] = record
	return result


func _parcel_owned(record: Dictionary) -> bool:
	if bool(record.get("owned", record.get("parcel_owned", false))):
		return true
	return StringName(String(record.get("status", record.get("stage", ""))).to_lower()) in [&"owned", &"surveyed", &"building", &"operational", &"complete"]


func _service_active(portfolio: Dictionary, service_id: StringName) -> bool:
	var services_value: Variant = portfolio.get("services", portfolio.get("network", {}))
	if services_value is Dictionary:
		var value: Variant = (services_value as Dictionary).get(String(service_id), (services_value as Dictionary).get(service_id, false))
		if value is Dictionary:
			return bool((value as Dictionary).get("active", (value as Dictionary).get("connected", false)))
		return bool(value)
	if services_value is Array:
		for record_value: Variant in services_value as Array:
			if record_value is Dictionary:
				var record := record_value as Dictionary
				if StringName(String(record.get("id", ""))) == service_id:
					return bool(record.get("active", record.get("connected", false)))
	return false


func _new_root(root_name: String, parent: Node3D = self) -> Node3D:
	var root := Node3D.new()
	root.name = root_name
	root.set_meta(&"visual_only", true)
	root.set_meta(&"collision_free", true)
	root.set_meta(&"navigation_free", true)
	parent.add_child(root)
	return root


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
	roughness: float = 0.72,
	metallic: float = 0.0,
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
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


func _add_sphere(
	parent: Node3D,
	part_name: String,
	part_position: Vector3,
	part_scale: Vector3,
	color: Color,
	roughness: float = 0.72,
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.scale = part_scale
	instance.material_override = _material(color, roughness)
	parent.add_child(instance)
	return instance


func _material(color: Color, roughness: float = 0.82, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "%s|%.3f|%.3f" % [color.to_html(true), roughness, metallic]
	if _material_cache.has(key):
		return _material_cache[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	_material_cache[key] = material
	return material
