class_name CampusExpansionVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## Visual-only North Meadow expansion parcel. Authoritative progression can
## drive one compact projection without this component owning construction,
## placement, navigation, or economy state.
const SNAPSHOT_ROOT: StringName = &"campus_expansion"
const POD_ID: StringName = &"egg_routing_pod"
const WEST_SOCKET_ID: StringName = &"meadow_west"
const EAST_SOCKET_ID: StringName = &"meadow_east"
const BLOCKED_SOCKET_ID: StringName = &"service_spine"

const FACILITY_CENTER := Vector3(25.05, 0.0, 9.00)
const FOOTPRINT := Rect2(Vector2(18.65, 3.10), Vector2(12.80, 11.80))
const CLEAR_NAVIGATION_SPINE := Rect2(Vector2(19.10, 3.35), Vector2(11.90, 2.10))
const MAX_VISUAL_HEIGHT := 4.25

const STAGE_LOCKED := 0
const STAGE_SURVEY := 1
const STAGE_UTILITIES := 2
const STAGE_READY := 3
const STAGE_NAMES: Array[StringName] = [&"locked", &"survey", &"utilities", &"ready"]

const MEADOW_GREEN := Color("58705a")
const MOWN_GREEN := Color("71826a")
const DEEP_GREEN := Color("334b3e")
const SAGE := Color("7f947e")
const CREAM := Color("e6dcc2")
const PAPER := Color("eee5cf")
const OATMEAL := Color("cdbd99")
const TIMBER := Color("77583d")
const DARK_TIMBER := Color("4b392d")
const BARN_RED := Color("914d3f")
const DEEP_RED := Color("63382f")
const BRASS := Color("c1a05a")
const GRAPHITE := Color("293335")
const CONCRETE := Color("777b72")
const DARK_CONCRETE := Color("4a504d")
const POWER_TEAL := Color("4d8586")
const COLD_BLUE := Color("78a5ae")
const ROUTE_AMBER := Color("d1a54f")
const STATUS_GREEN := Color("7dac78")
const STATUS_OFF := Color("38453f")
const BLOCKED_RED := Color("b55346")

var _built := false
var _stage := STAGE_LOCKED
var _pod_socket: StringName = &""
var _blocked_reason := "SERVICE ACCESS RESERVED"
var _utility_state := {
	&"circulation": false,
	&"power": false,
	&"cold_chain": false,
}

var _locked_root: Node3D
var _survey_root: Node3D
var _utility_root: Node3D
var _open_trench_root: Node3D
var _ready_root: Node3D
var _pod_root: Node3D
var _stage_label: Label3D
var _blocked_label: Label3D
var _pod_label: Label3D
var _utility_labels: Dictionary[StringName, Label3D] = {}
var _utility_lamps: Dictionary[StringName, MeshInstance3D] = {}
var _socket_roots: Dictionary[StringName, Node3D] = {}
var _material_cache: Dictionary[String, StandardMaterial3D] = {}


static func declared_footprint() -> Rect2:
	return FOOTPRINT


static func navigation_footprint(snapshot: Dictionary = {}) -> Rect2:
	# The reserved south circulation band never moves with a socket placement;
	# future navigation can therefore be extended without cutting around art.
	_projection_from_snapshot(snapshot)
	return CLEAR_NAVIGATION_SPINE


static func camera_bounds(snapshot: Dictionary = {}) -> AABB:
	var projection := _projection_from_snapshot(snapshot)
	var stage := _stage_from_projection(projection)
	var height: float = float([2.35, 2.55, 2.85, 3.10][stage])
	var socket_id := _pod_socket_from_projection(projection)
	if stage >= STAGE_READY and socket_id in [WEST_SOCKET_ID, EAST_SOCKET_ID]:
		height = MAX_VISUAL_HEIGHT
	return AABB(
		Vector3(FOOTPRINT.position.x, -0.18, FOOTPRINT.position.y),
		Vector3(FOOTPRINT.size.x, height + 0.18, FOOTPRINT.size.y),
	)


static func socket_catalog() -> Array[Dictionary]:
	return [
		{
			"id": WEST_SOCKET_ID,
			"label": "MEADOW WEST",
			"center": Vector3(20.90, 0.0, 10.10),
			"footprint": Rect2(Vector2(19.20, 6.20), Vector2(3.40, 7.55)),
			"route_blocked": false,
			"allowed_pod_ids": [POD_ID],
			"utility_connections": [&"circulation", &"power", &"cold_chain"],
		},
		{
			"id": EAST_SOCKET_ID,
			"label": "MEADOW EAST",
			"center": Vector3(25.05, 0.0, 10.10),
			"footprint": Rect2(Vector2(23.35, 6.20), Vector2(3.40, 7.55)),
			"route_blocked": false,
			"allowed_pod_ids": [POD_ID],
			"utility_connections": [&"circulation", &"power", &"cold_chain"],
		},
		{
			"id": BLOCKED_SOCKET_ID,
			"label": "SERVICE SPINE",
			"center": Vector3(29.20, 0.0, 10.10),
			"footprint": Rect2(Vector2(27.50, 6.20), Vector2(3.40, 7.55)),
			"route_blocked": true,
			"allowed_pod_ids": [],
			"utility_connections": [&"power", &"cold_chain"],
		},
	]


func _ready() -> void:
	name = "CampusExpansionVisual"
	position = FACILITY_CENTER
	set_meta(&"visual_only", true)
	set_meta(&"collision_free", true)
	set_meta(&"navigation_free", true)
	set_meta(&"declared_footprint", FOOTPRINT)
	if not _built:
		build()


func apply_snapshot(snapshot: Dictionary) -> void:
	if not _built:
		build()
	var projection := _projection_from_snapshot(snapshot)
	_stage = _stage_from_projection(projection)
	var requested_socket := _pod_socket_from_projection(projection)
	_pod_socket = (
		requested_socket
		if _stage >= STAGE_READY and requested_socket in [WEST_SOCKET_ID, EAST_SOCKET_ID]
		else &""
	)
	_blocked_reason = String(projection.get(
		"blocked_reason",
		projection.get("service_spine_reason", "SERVICE ACCESS RESERVED"),
	)).strip_edges().to_upper()
	if not projection.has("blocked_reason") and projection.get("sockets", null) is Array:
		for socket_value in projection.get("sockets", []):
			if socket_value is not Dictionary:
				continue
			var socket := socket_value as Dictionary
			if StringName(String(socket.get("id", ""))) == BLOCKED_SOCKET_ID:
				_blocked_reason = String(socket.get(
					"blocked_reason", socket.get("reason", _blocked_reason)
				)).strip_edges().to_upper()
				break
	if _blocked_reason.is_empty():
		_blocked_reason = "SERVICE ACCESS RESERVED"
	var utilities_value: Variant = projection.get("utilities", projection.get("services", {}))
	var utilities: Dictionary = {}
	if utilities_value is Dictionary:
		utilities = utilities_value as Dictionary
	elif utilities_value is Array:
		for utility_record_value in utilities_value:
			if utility_record_value is not Dictionary:
				continue
			var utility_record := utility_record_value as Dictionary
			var utility_id := StringName(String(utility_record.get("id", "")))
			if utility_id in [&"circulation", &"power", &"cold_chain"]:
				utilities[utility_id] = utility_record
	for utility_id in [&"circulation", &"power", &"cold_chain"]:
		var default_active := _stage >= STAGE_UTILITIES
		var utility_value: Variant = utilities.get(
			String(utility_id),
			utilities.get(utility_id, default_active),
		)
		_utility_state[utility_id] = _service_record_active(utility_value, default_active)
	_refresh_state()


static func _projection_from_snapshot(snapshot: Dictionary) -> Dictionary:
	var value: Variant = snapshot.get(String(SNAPSHOT_ROOT), snapshot.get(SNAPSHOT_ROOT, {}))
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


static func _stage_from_projection(projection: Dictionary) -> int:
	var raw_stage: Variant = projection.get("construction_stage", projection.get("stage", STAGE_LOCKED))
	var stage := STAGE_LOCKED
	if raw_stage is String or raw_stage is StringName:
		var stage_id := StringName(String(raw_stage).strip_edges().to_lower())
		match stage_id:
			&"survey", &"surveyed":
				stage = STAGE_SURVEY
			&"access":
				stage = STAGE_SURVEY if bool(projection.get("visible", false)) else STAGE_LOCKED
			&"site_work":
				stage = STAGE_SURVEY
			&"utilities", &"serviced", &"utility_trench", &"services_ready":
				stage = STAGE_UTILITIES
			&"ready", &"pod_placed", &"operational", &"commissioned", &"cold_chain_operational":
				stage = STAGE_READY
			_:
				stage = STAGE_LOCKED
	elif raw_stage is int or raw_stage is float:
		stage = clampi(int(raw_stage), STAGE_LOCKED, STAGE_READY)
	if bool(projection.get("unlocked", false)) and stage == STAGE_LOCKED:
		stage = STAGE_SURVEY
	return stage


static func _pod_socket_from_projection(projection: Dictionary) -> StringName:
	var placements_value: Variant = projection.get("placements", {})
	var placements := placements_value as Dictionary if placements_value is Dictionary else {}
	var raw_socket: Variant = placements.get(
		String(POD_ID),
		placements.get(POD_ID, projection.get("egg_routing_pod_socket", &"")),
	)
	var pod_value: Variant = projection.get("egg_routing_pod", null)
	if pod_value is Dictionary:
		raw_socket = (pod_value as Dictionary).get("socket_id", raw_socket)
	elif pod_value is String or pod_value is StringName:
		raw_socket = pod_value
	var routing_value: Variant = projection.get("routing_pod", null)
	if routing_value is Dictionary:
		raw_socket = (routing_value as Dictionary).get(
			"socket_id",
			(routing_value as Dictionary).get(
				"current_socket_id",
				(routing_value as Dictionary).get("pod_socket_id", raw_socket),
			),
		)
	elif routing_value is String or routing_value is StringName:
		raw_socket = routing_value
	raw_socket = projection.get("pod_socket_id", raw_socket)
	return StringName(String(raw_socket).strip_edges().to_lower())


func build() -> void:
	clear()
	_built = true
	_build_meadow_shell()
	_build_sockets()
	_build_routes()
	_build_locked_stage()
	_build_survey_stage()
	_build_utility_stage()
	_build_ready_stage()
	_build_routing_pod()
	_refresh_state()


func clear() -> void:
	for child in get_children():
		child.free()
	_locked_root = null
	_survey_root = null
	_utility_root = null
	_open_trench_root = null
	_ready_root = null
	_pod_root = null
	_stage_label = null
	_blocked_label = null
	_pod_label = null
	_utility_labels.clear()
	_utility_lamps.clear()
	_socket_roots.clear()
	_material_cache.clear()
	_built = false


func _build_meadow_shell() -> void:
	var shell := _new_visual_root("NorthMeadowParcel")
	shell.set_meta(&"parcel_name", &"north_meadow")
	shell.set_meta(&"declared_footprint", FOOTPRINT)
	_add_box(shell, "NorthMeadowGround", Vector3(12.80, 0.14, 11.80), Vector3(0.0, -0.09, 0.0), MEADOW_GREEN)
	_add_box(shell, "NorthMeadowMownApron", Vector3(12.10, 0.025, 2.30), Vector3(0.0, 0.005, -4.48), MOWN_GREEN)
	_add_box(shell, "NorthMeadowNorthHedgerow", Vector3(12.28, 0.42, 0.34), Vector3(0.0, 0.20, 5.64), DEEP_GREEN)
	for edge_x in [-6.14, 6.14]:
		_add_box(shell, "NorthMeadowFenceRail", Vector3(0.12, 0.12, 10.96), Vector3(edge_x, 0.76, 0.24), TIMBER)
		for post_z in [-5.10, -2.60, -0.10, 2.40, 4.90]:
			_add_box(shell, "NorthMeadowFencePost", Vector3(0.18, 1.42, 0.18), Vector3(edge_x, 0.71, post_z), DARK_TIMBER)
	var permit_fence_rail: MeshInstance3D = null
	for fence_x in [-4.70, -2.85, 2.85, 4.70]:
		var south_rail := _add_box(shell, "NorthMeadowSouthFenceRail", Vector3(1.65, 0.12, 0.12), Vector3(fence_x, 0.76, -5.66), TIMBER)
		south_rail.set_meta(&"north_meadow_south_fence_rail", true)
		if is_equal_approx(fence_x, 2.85):
			permit_fence_rail = south_rail
			permit_fence_rail.set_meta(&"permit_support_rail", true)
		_add_box(shell, "NorthMeadowSouthFencePost", Vector3(0.18, 1.42, 0.18), Vector3(fence_x - 0.82, 0.71, -5.66), DARK_TIMBER)

	var grass_mesh := BoxMesh.new()
	grass_mesh.size = Vector3(0.045, 0.28, 0.045)
	grass_mesh.material = _material(SAGE.darkened(0.08), 0.92)
	var grass_multimesh := MultiMesh.new()
	grass_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	grass_multimesh.mesh = grass_mesh
	grass_multimesh.instance_count = 24
	for grass_index in 24:
		var side := -1.0 if grass_index % 2 == 0 else 1.0
		var x := side * (5.25 + float(grass_index % 3) * 0.22)
		var z := -4.70 + float(grass_index / 2) * 0.84
		var transform := Transform3D(Basis(Vector3.UP, deg_to_rad(float((grass_index * 37) % 180))), Vector3(x, 0.12, z))
		grass_multimesh.set_instance_transform(grass_index, transform)
	var grass := MultiMeshInstance3D.new()
	grass.name = "NorthMeadowGrassTufts"
	grass.multimesh = grass_multimesh
	shell.add_child(grass)

	# A permanent meadow name belongs to the gate, not to a freestanding UI-like
	# slab. The routed timber face is carried by two visible ground posts and a
	# weather cap, while the filing descriptor moves to a small deed plate.
	var identity_gate := _new_visual_root("NorthMeadowIdentityGate", shell)
	identity_gate.position = Vector3(-3.80, 0.0, -5.55)
	identity_gate.set_meta(&"ground_supported", true)
	identity_gate.set_meta(&"support_kind", &"timber_gate_posts")
	for post_index in 2:
		var post_x: float = float([-1.24, 1.24][post_index])
		_add_box(identity_gate, "NorthMeadowIdentityPost_%02d" % post_index, Vector3(0.18, 1.94, 0.18), Vector3(post_x, 0.97, 0.06), DARK_TIMBER)
		_add_box(identity_gate, "NorthMeadowIdentityPostFoot_%02d" % post_index, Vector3(0.30, 0.12, 0.30), Vector3(post_x, 0.06, 0.06), CONCRETE.darkened(0.12))
	var identity_host := _add_box(identity_gate, "NorthMeadowIdentityHost", Vector3(3.08, 0.58, 0.14), Vector3(0.0, 1.60, 0.0), TIMBER)
	identity_host.set_meta(&"routed_timber_gate_sign", true)
	identity_host.set_meta(&"visible_support_count", 2)
	_add_box(identity_gate, "NorthMeadowIdentityWeatherCap", Vector3(3.28, 0.08, 0.18), Vector3(0.0, 1.93, 0.0), DARK_TIMBER)
	EnvironmentalSignageScript.add_panel(
		identity_host,
		"NorthMeadowIdentity",
		"NORTH MEADOW",
		Vector3(0.0, 0.0, 0.080),
		Vector2(2.72, 0.36),
		TIMBER,
		CREAM,
		Vector3.ZERO,
		16,
		0.0028,
		&"primary",
		&"destination",
	)
	var deed_plate_host := _add_box(identity_host, "NorthMeadowDeedPlateHost", Vector3(1.14, 0.18, 0.03), Vector3(0.70, -0.19, 0.085), BRASS.darkened(0.08), 0.50, 0.28)
	deed_plate_host.set_meta(&"deed_plate", true)
	EnvironmentalSignageScript.add_panel(
		deed_plate_host,
		"NorthMeadowDeedPlate",
		"CAMPUS EXPANSION FILE",
		Vector3(0.0, 0.0, 0.020),
		Vector2(1.00, 0.12),
		BRASS.darkened(0.08),
		DARK_TIMBER,
		Vector3.ZERO,
		9,
		0.0017,
		&"secondary",
		&"stencil",
	)

	# The changing construction stage is a handled permit clipped to the actual
	# south fence rail. Its utility-tier paper copy naturally recedes at overview
	# and reappears through the shared environmental-signage focus pass.
	if permit_fence_rail != null:
		var stage_host := _add_box(permit_fence_rail, "NorthMeadowStageLedgerHost", Vector3(0.72, 0.48, 0.035), Vector3(0.0, 0.31, 0.085), DARK_TIMBER)
		stage_host.set_meta(&"clipboard_permit", true)
		stage_host.set_meta(&"physically_clipped_to_fence", true)
		_add_box(stage_host, "NorthMeadowPermitClip", Vector3(0.18, 0.07, 0.022), Vector3(0.0, 0.205, 0.035), BRASS.darkened(0.10), 0.48, 0.34)
		var permit_paper := _add_box(stage_host, "NorthMeadowStagePermitPaper", Vector3(0.58, 0.36, 0.004), Vector3(0.0, 0.0, 0.021), PAPER, 0.96)
		permit_paper.set_meta(&"permit_document", true)
		_stage_label = EnvironmentalSignageScript.add_panel(
			permit_paper,
			"NorthMeadowStageLedger",
			"LEASE REVIEW",
			Vector3(0.0, 0.0, 0.005),
			Vector2(0.50, 0.28),
			PAPER,
			GRAPHITE,
			Vector3.ZERO,
			10,
			0.0018,
			&"utility",
			&"stencil",
		)
		_stage_label.get_parent().set_meta(&"permit_document", true)


func _build_sockets() -> void:
	for socket in socket_catalog():
		var socket_id := StringName(socket.get("id", &""))
		var center := socket.get("center", FACILITY_CENTER) as Vector3
		var local_center := center - FACILITY_CENTER
		var socket_root := _new_visual_root("NorthMeadowSocket_%s" % String(socket_id))
		socket_root.position = local_center
		socket_root.set_meta(&"socket_id", socket_id)
		socket_root.set_meta(&"route_blocked", bool(socket.get("route_blocked", false)))
		socket_root.set_meta(&"allowed_pod_ids", (socket.get("allowed_pod_ids", []) as Array).duplicate())
		socket_root.set_meta(&"socket_footprint", socket.get("footprint", Rect2()))
		_socket_roots[socket_id] = socket_root
		var blocked := bool(socket.get("route_blocked", false))
		var pad_color := DEEP_RED if blocked else DARK_CONCRETE
		var trim_color := BLOCKED_RED if blocked else BRASS.darkened(0.16)
		var socket_pad := _add_box(socket_root, "SocketPad_%s" % String(socket_id), Vector3(3.40, 0.075, 7.55), Vector3(0.0, 0.005, 0.0), pad_color)
		for edge_x in [-1.64, 1.64]:
			_add_box(socket_root, "SocketEdge_%s" % String(socket_id), Vector3(0.075, 0.055, 7.36), Vector3(edge_x, 0.066, 0.0), trim_color)
		for edge_z in [-3.68, 3.68]:
			_add_box(socket_root, "SocketEdge_%s" % String(socket_id), Vector3(3.32, 0.055, 0.075), Vector3(0.0, 0.066, edge_z), trim_color)
		var medallion := _add_cylinder(socket_root, "SocketMedallion_%s" % String(socket_id), Vector3(0.0, 0.085, 0.35), 0.48, 0.045, trim_color, 0.62, 0.18)
		medallion.set_meta(&"socket_id", socket_id)
		# Socket identities are painted into the pad at foot level. Parenting the
		# shallow inlay to the pad makes the support relationship literal and keeps
		# these markers from reading as three floating status cards.
		var marker_color := DEEP_RED.lightened(0.08) if blocked else DARK_CONCRETE.lightened(0.10)
		var marker_host := _add_box(socket_pad, "SocketMarkerHost_%s" % String(socket_id), Vector3(2.08, 0.014, 0.42), Vector3(0.0, 0.047, -3.20), marker_color)
		marker_host.set_meta(&"ground_inlay", true)
		marker_host.set_meta(&"physically_attached_to_socket_pad", true)
		var ground_marker_name := (
			"SocketGroundStencil_%s" % String(socket_id)
			if blocked
			else "SocketMarker_%s" % String(socket_id)
		)
		var ground_copy := (
			"SERVICE SPINE · ACCESS"
			if blocked
			else "%s · POD SOCKET" % String(socket.get("label", socket_id)).to_upper()
		)
		EnvironmentalSignageScript.add_panel(
			marker_host,
			ground_marker_name,
			ground_copy,
			Vector3(0.0, 0.008, 0.0),
			Vector2(1.86, 0.22),
			marker_color,
			CREAM if not blocked else PAPER,
			Vector3(-90.0, 0.0, 0.0),
			11,
			0.0019,
			&"secondary",
			&"stencil",
		)
		if blocked:
			var keep_clear_crossbar: MeshInstance3D = null
			for cross_index in 2:
				var cross_rotation: float = float([-31.0, 31.0][cross_index])
				var crossbar := _add_box(socket_root, "ServiceSpineBlockCrossbar_%02d" % cross_index, Vector3(2.84, 0.16, 0.12), Vector3(0.0, 0.62, -2.65), BLOCKED_RED)
				crossbar.rotation_degrees.z = cross_rotation
				if cross_index == 0:
					keep_clear_crossbar = crossbar
			for cone_x in [-1.22, 1.22]:
				_add_cylinder(socket_root, "ServiceSpineBarrierCone", Vector3(cone_x, 0.32, -2.64), 0.20, 0.64, ROUTE_AMBER)
			if keep_clear_crossbar != null:
				var keep_clear_plate := _add_box(keep_clear_crossbar, "ServiceSpineKeepClearPlateHost", Vector3(1.72, 0.36, 0.055), Vector3(0.0, 0.0, 0.10), ROUTE_AMBER.darkened(0.08), 0.62, 0.12)
				# Counter-rotate the readable plate while retaining the crossed barrier as
				# its direct physical parent.
				keep_clear_plate.rotation_degrees.z = 31.0
				keep_clear_plate.set_meta(&"physically_attached_to_service_spine", true)
				for fastener_x in [-0.70, 0.70]:
					_add_sphere(keep_clear_plate, "ServiceSpineKeepClearFastener", Vector3(fastener_x, 0.0, 0.040), Vector3(0.055, 0.055, 0.030), BRASS.lightened(0.12), 0.48)
				var blocked_heading := EnvironmentalSignageScript.add_panel(
					keep_clear_plate,
					"SocketMarker_service_spine",
					"KEEP CLEAR\nROUTE BLOCKED · SERVICE ACCESS RESERVED",
					Vector3(0.0, 0.0, 0.034),
					Vector2(1.52, 0.27),
					ROUTE_AMBER.darkened(0.08),
					DEEP_RED,
					Vector3.ZERO,
					10,
					0.0018,
					&"secondary",
					&"stencil",
				)
				# Permanent safety copy remains legible in the parcel overview. The
				# second-line easement reason stays a close-focus detail.
				blocked_heading.get_parent().set_meta(&"overview_anchor", true)
				var reason_label := blocked_heading.get_parent().find_child("SocketMarker_service_spineBody", false, false) as Label3D
				_blocked_label = reason_label if reason_label != null else blocked_heading


func _build_routes() -> void:
	var routes := _new_visual_root("NorthMeadowRouteCorridors")
	routes.set_meta(&"navigation_footprint", CLEAR_NAVIGATION_SPINE)
	_add_box(routes, "NorthMeadowCirculationCorridor", Vector3(11.90, 0.055, 2.10), Vector3(0.0, 0.035, -4.60), CONCRETE)
	for dash_index in 9:
		_add_box(routes, "CirculationRouteDash_%02d" % dash_index, Vector3(0.68, 0.018, 0.055), Vector3(-4.65 + dash_index * 1.16, 0.075, -4.60), CREAM)
	for branch_index in 3:
		var branch_x: float = float([-4.15, 0.0, 4.15][branch_index])
		var blocked := branch_index == 2
		_add_box(routes, "SocketRouteBranch_%02d" % branch_index, Vector3(1.08, 0.045, 2.35), Vector3(branch_x, 0.045, -3.02), CONCRETE.darkened(0.22) if blocked else CONCRETE.lightened(0.05))
		_add_box(routes, "SocketRouteArrowStem_%02d" % branch_index, Vector3(0.12, 0.020, 0.66), Vector3(branch_x, 0.082, -2.78), BLOCKED_RED if blocked else ROUTE_AMBER)
		for arrow_side in [-1.0, 1.0]:
			var arrow := _add_box(routes, "SocketRouteArrowHead_%02d" % branch_index, Vector3(0.10, 0.020, 0.42), Vector3(branch_x + arrow_side * 0.12, 0.083, -2.49), BLOCKED_RED if blocked else ROUTE_AMBER)
			arrow.rotation_degrees.y = arrow_side * 35.0


func _build_locked_stage() -> void:
	var identity_host := find_child("NorthMeadowIdentityHost", true, false) as MeshInstance3D
	_locked_root = _new_visual_root(
		"NorthMeadowLockedStage",
		identity_host if identity_host != null else self,
	)
	_locked_root.set_meta(&"construction_stage", &"locked")
	_locked_root.set_meta(&"gate_attached", identity_host != null)
	for chain_x in [-0.38, 0.38]:
		_add_box(_locked_root, "MeadowLeaseChain", Vector3(0.035, 0.24, 0.035), Vector3(chain_x, 0.28, 0.085), BRASS.darkened(0.20), 0.52, 0.22)
	var notice_host := _add_box(_locked_root, "NorthMeadowLeaseNoticeHost", Vector3(1.02, 0.44, 0.035), Vector3(0.0, 0.04, 0.105), DARK_TIMBER)
	notice_host.set_meta(&"compact_gate_notice", true)
	EnvironmentalSignageScript.add_panel(
		notice_host,
		"NorthMeadowLeaseNotice",
		"MEADOW LEASE HELD\nCAPITAL FILE REQUIRED",
		Vector3(0.0, 0.0, 0.020),
		Vector2(0.86, 0.32),
		PAPER,
		DEEP_RED,
		Vector3.ZERO,
		10,
		0.0018,
		&"secondary",
		&"paper",
	)


func _build_survey_stage() -> void:
	_survey_root = _new_visual_root("NorthMeadowSurveyStage")
	_survey_root.set_meta(&"construction_stage", &"survey")
	var socket_xs: Array[float] = [-4.15, 0.0, 4.15]
	var corner_offsets: Array[Vector3] = [Vector3(-1.45, 0.36, -3.35), Vector3(1.45, 0.36, -3.35), Vector3(-1.45, 0.36, 3.35), Vector3(1.45, 0.36, 3.35)]
	for socket_index in socket_xs.size():
		var socket_x := socket_xs[socket_index]
		for corner_index in corner_offsets.size():
			var offset := corner_offsets[corner_index]
			_add_box(_survey_root, "MeadowSurveyStake_%02d_%02d" % [socket_index, corner_index], Vector3(0.08, 0.72, 0.08), Vector3(socket_x, 0.0, 1.10) + offset, TIMBER)
			_add_box(_survey_root, "MeadowSurveyFlag_%02d_%02d" % [socket_index, corner_index], Vector3(0.28, 0.16, 0.025), Vector3(socket_x, 0.16, 1.10) + offset + Vector3(0.12, 0.10, 0.0), BARN_RED)
	var survey_table := _add_box(_survey_root, "NorthMeadowSurveyTable", Vector3(2.20, 0.12, 1.08), Vector3(-0.90, 0.82, -3.65), TIMBER)
	for leg_x in [-0.86, 0.86]:
		for leg_z in [-0.38, 0.38]:
			_add_box(survey_table, "SurveyTableLeg", Vector3(0.09, 0.76, 0.09), Vector3(leg_x, -0.44, leg_z), DARK_TIMBER)
	_add_box(survey_table, "NorthMeadowBlueprint", Vector3(1.82, 0.018, 0.76), Vector3(0.0, 0.07, 0.0), POWER_TEAL)


func _build_utility_stage() -> void:
	_utility_root = _new_visual_root("NorthMeadowUtilitiesStage")
	_utility_root.set_meta(&"construction_stage", &"utilities")
	_open_trench_root = _new_visual_root("NorthMeadowOpenUtilityTrenches", _utility_root)
	_add_box(_open_trench_root, "UtilitySpineOpenTrench", Vector3(11.20, 0.09, 0.46), Vector3(0.0, 0.09, -4.25), DARK_TIMBER.darkened(0.25))
	for branch_x in [-4.15, 0.0, 4.15]:
		_add_box(_open_trench_root, "SocketUtilityOpenTrench", Vector3(0.46, 0.09, 2.12), Vector3(branch_x, 0.09, -3.20), DARK_TIMBER.darkened(0.25))

	_build_utility_assembly(
		&"circulation",
		"CirculationUtilityAssembly",
		"CirculationRouteLine",
		"CirculationCounterMeter",
		Vector3(0.0, 0.14, -4.60),
		Vector3(10.80, 0.055, 0.10),
		ROUTE_AMBER,
		Vector3(-5.28, 0.66, -4.60),
	)
	_build_utility_assembly(
		&"power",
		"PowerUtilityAssembly",
		"PowerConduitLine",
		"PowerServiceMeter",
		Vector3(0.0, 0.18, -4.18),
		Vector3(11.00, 0.10, 0.11),
		POWER_TEAL,
		Vector3(-5.36, 0.78, -4.18),
	)
	_build_utility_assembly(
		&"cold_chain",
		"ColdChainUtilityAssembly",
		"ColdChainSupplyLine",
		"ColdChainPressureMeter",
		Vector3(0.0, 0.30, -3.92),
		Vector3(11.00, 0.12, 0.12),
		COLD_BLUE,
		Vector3(5.36, 0.86, -3.92),
	)
	for branch_x in [-4.15, 0.0, 4.15]:
		_add_box(_utility_root, "PowerSocketBranch", Vector3(0.10, 0.09, 2.12), Vector3(branch_x - 0.16, 0.18, -3.16), POWER_TEAL, 0.44, 0.24)
		_add_box(_utility_root, "ColdChainSocketBranch", Vector3(0.12, 0.10, 2.12), Vector3(branch_x + 0.16, 0.28, -3.16), COLD_BLUE, 0.40, 0.28)


func _build_utility_assembly(
	utility_id: StringName,
	assembly_name: String,
	line_name: String,
	meter_name: String,
	line_position: Vector3,
	line_size: Vector3,
	color: Color,
	meter_position: Vector3,
) -> void:
	var assembly := _new_visual_root(assembly_name, _utility_root)
	assembly.set_meta(&"utility_id", utility_id)
	assembly.set_meta(&"host_attached", true)
	assembly.set_meta(&"line_and_meter_attached", true)
	_add_box(assembly, line_name, line_size, line_position, color, 0.44, 0.24)
	var meter := _add_box(assembly, meter_name, Vector3(0.54, 0.88, 0.28), meter_position, GRAPHITE)
	var dial := _add_cylinder(meter, "%sDial" % meter_name, Vector3(0.0, 0.12, 0.17), 0.18, 0.055, PAPER, 0.55, 0.06)
	# The dial cylinder is vertical by default; rotate it onto the cabinet face.
	dial.rotation_degrees.x = 90.0
	var lamp := _add_sphere(meter, "%sStatusLamp" % meter_name, Vector3(0.0, -0.22, 0.19), Vector3(0.18, 0.18, 0.10), STATUS_OFF)
	_utility_lamps[utility_id] = lamp
	var label := EnvironmentalSignageScript.add_panel(
		meter,
		"%sStatus" % meter_name,
		"%s / HELD" % String(utility_id).replace("_", " ").to_upper(),
		Vector3(0.0, -0.35, 0.150),
		Vector2(0.46, 0.18),
		GRAPHITE,
		color.lightened(0.18),
		Vector3.ZERO,
		8,
		0.00165,
		&"utility",
		&"machine",
		true,
	)
	_utility_labels[utility_id] = label


func _build_ready_stage() -> void:
	_ready_root = _new_visual_root("NorthMeadowReadyStage")
	_ready_root.set_meta(&"construction_stage", &"ready")
	for socket_x in [-4.15, 0.0]:
		for bollard_x in [-0.66, 0.66]:
			_add_cylinder(_ready_root, "MeadowSocketSafetyBollard", Vector3(socket_x + bollard_x, 0.36, -2.70), 0.10, 0.72, ROUTE_AMBER)
	for planter_x in [-5.48, 5.48]:
		_add_box(_ready_root, "NorthMeadowPlanter", Vector3(0.58, 0.34, 1.30), Vector3(planter_x, 0.17, 3.80), DARK_TIMBER)
		for bloom_z in [-0.38, 0.0, 0.38]:
			_add_sphere(_ready_root, "NorthMeadowPlanterBloom", Vector3(planter_x, 0.48, 3.80 + bloom_z), Vector3(0.24, 0.24, 0.24), CREAM.darkened(0.08))
	for lantern_x in [-5.65, 5.65]:
		_add_box(_ready_root, "NorthMeadowRouteLanternPost", Vector3(0.10, 1.84, 0.10), Vector3(lantern_x, 0.92, -4.56), DARK_TIMBER)
		_add_sphere(_ready_root, "NorthMeadowRouteLantern", Vector3(lantern_x, 1.88, -4.56), Vector3(0.32, 0.26, 0.32), ROUTE_AMBER.lightened(0.18))


func _build_routing_pod() -> void:
	_pod_root = _new_visual_root("EggRoutingPod")
	_pod_root.set_meta(&"pod_id", POD_ID)
	_pod_root.set_meta(&"visual_only", true)
	_add_box(_pod_root, "EggRoutingPodFoundation", Vector3(3.04, 0.16, 4.86), Vector3(0.0, 0.08, 0.28), DARK_CONCRETE)
	for foot_x in [-1.28, 1.28]:
		for foot_z in [-1.72, 1.72]:
			_add_box(_pod_root, "EggRoutingPodTimberFoot", Vector3(0.18, 0.46, 0.18), Vector3(foot_x, 0.31, foot_z + 0.28), TIMBER)
	_add_box(_pod_root, "EggRoutingPodBody", Vector3(2.78, 2.18, 3.78), Vector3(0.0, 1.33, 0.30), CREAM)
	_add_box(_pod_root, "EggRoutingPodLowerBand", Vector3(2.86, 0.42, 3.86), Vector3(0.0, 0.52, 0.30), DEEP_GREEN)
	for roof_side in [-1.0, 1.0]:
		var roof := _add_box(_pod_root, "EggRoutingPodRoof", Vector3(1.72, 0.14, 4.08), Vector3(roof_side * 0.72, 2.66, 0.30), BARN_RED)
		roof.rotation_degrees.z = roof_side * 23.0
	_add_box(_pod_root, "EggRoutingPodRidgeCap", Vector3(0.18, 0.16, 4.14), Vector3(0.0, 3.00, 0.30), DEEP_RED)
	var front := _add_box(_pod_root, "EggRoutingPodFrontConsole", Vector3(2.18, 1.16, 0.18), Vector3(0.0, 1.22, -1.66), GRAPHITE)
	for lane_x in [-0.70, 0.0, 0.70]:
		_add_box(front, "EggRoutingPodLaneLight", Vector3(0.32, 0.14, 0.08), Vector3(lane_x, 0.16, -0.13), STATUS_GREEN)
		_add_box(front, "EggRoutingPodClaimSlot", Vector3(0.42, 0.08, 0.09), Vector3(lane_x, -0.22, -0.13), PAPER.darkened(0.12))
	var hopper := _add_cylinder(_pod_root, "EggRoutingPodHopper", Vector3(-0.86, 1.90, -1.72), 0.42, 0.54, POWER_TEAL, 0.46, 0.18)
	hopper.rotation_degrees.z = 90.0
	_add_box(_pod_root, "EggRoutingPodOutputChute", Vector3(0.54, 0.42, 1.08), Vector3(0.88, 1.05, -1.92), OATMEAL)
	var identity_host := _add_box(_pod_root, "EggRoutingPodIdentityHost", Vector3(2.48, 0.66, 0.12), Vector3(0.0, 2.15, -1.86), DEEP_GREEN)
	_pod_label = EnvironmentalSignageScript.add_panel(
		identity_host,
		"EggRoutingPodIdentity",
		"EGG ROUTING POD\nCLAIMS-TO-CLUTCH TRANSFER",
		Vector3(0.0, 0.0, -0.072),
		Vector2(2.18, 0.46),
		DEEP_GREEN,
		CREAM,
		Vector3(0.0, 180.0, 0.0),
		13,
		0.00245,
		&"secondary",
		&"machine",
	)
	_add_box(_pod_root, "EggRoutingPodPowerUmbilical", Vector3(0.09, 0.09, 0.92), Vector3(-0.20, 0.18, -2.08), POWER_TEAL, 0.42, 0.26)
	_add_box(_pod_root, "EggRoutingPodColdUmbilical", Vector3(0.11, 0.11, 0.92), Vector3(0.20, 0.22, -2.08), COLD_BLUE, 0.40, 0.30)
	_add_sphere(_pod_root, "EggRoutingPodBeacon", Vector3(0.0, 3.22, -0.82), Vector3(0.26, 0.30, 0.26), ROUTE_AMBER.lightened(0.18))


func _refresh_state() -> void:
	if not _built:
		return
	_locked_root.visible = _stage == STAGE_LOCKED
	_survey_root.visible = _stage == STAGE_SURVEY
	_utility_root.visible = _stage >= STAGE_UTILITIES
	_open_trench_root.visible = _stage == STAGE_UTILITIES
	_ready_root.visible = _stage >= STAGE_READY
	_pod_root.visible = _stage >= STAGE_READY and _pod_socket in [WEST_SOCKET_ID, EAST_SOCKET_ID]
	if _pod_root.visible:
		var socket_root := _socket_roots.get(_pod_socket) as Node3D
		_pod_root.position = socket_root.position if socket_root != null else Vector3.ZERO
		_pod_root.set_meta(&"socket_id", _pod_socket)
	else:
		_pod_root.set_meta(&"socket_id", &"")
	if _stage_label != null:
		_stage_label.text = [
			"LEASE REVIEW",
			"SURVEY STAKES SET",
			"UTILITY TRENCH OPEN",
			"MEADOW SOCKETS READY",
		][_stage]
		EnvironmentalSignageScript.refit_label(_stage_label)
	if _blocked_label != null:
		_blocked_label.text = "ROUTE BLOCKED · %s" % _blocked_reason
		EnvironmentalSignageScript.refit_label(_blocked_label)
	if _pod_label != null:
		_pod_label.text = "EGG ROUTING POD\n%s" % (
			"MEADOW WEST" if _pod_socket == WEST_SOCKET_ID else "MEADOW EAST"
		)
		EnvironmentalSignageScript.refit_label(_pod_label)
	for utility_id in [&"circulation", &"power", &"cold_chain"]:
		var active := bool(_utility_state.get(utility_id, false)) and _stage >= STAGE_UTILITIES
		var lamp := _utility_lamps.get(utility_id) as MeshInstance3D
		if lamp != null:
			lamp.material_override = _material(STATUS_GREEN if active else STATUS_OFF, 0.48)
		var label := _utility_labels.get(utility_id) as Label3D
		if label != null:
			label.text = "%s / %s" % [
				String(utility_id).replace("_", " ").to_upper(),
				"LIVE" if active else "HELD",
			]
			EnvironmentalSignageScript.refit_label(label)


func _service_record_active(value: Variant, default_active: bool) -> bool:
	if value is Dictionary:
		var record := value as Dictionary
		return bool(record.get(
			"active",
			record.get("connected", record.get("ready", record.get("commissioned", default_active))),
		))
	if value is String or value is StringName:
		return String(value).strip_edges().to_lower() in ["active", "connected", "ready", "live", "commissioned"]
	if value == null:
		return default_active
	return bool(value)


func _new_visual_root(root_name: String, parent: Node3D = self) -> Node3D:
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
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	_material_cache[key] = material
	return material
