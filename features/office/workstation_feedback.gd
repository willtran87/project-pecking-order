class_name WorkstationFeedback
extends Node

## Lightweight visual feedback for the six imported office workstations.
## The controller owns every runtime material it modifies, so imported GLB
## materials remain shared and untouched.

const STATE_IDLE := 0
const STATE_WORKING := 1
const STATE_LAYING := 2
const STATE_BREAK := 3
const UPDATE_INTERVAL := 0.05

const COLOR_IDLE := Color("4d7890")
const COLOR_WORKING := Color("45c2b0")
const COLOR_LAYING := Color("edaa52")
const COLOR_BREAK := Color("8b7fb6")
const COLOR_ALERT := Color("e65343")
const COLOR_SOUND := Color("78d98a")
const COLOR_CRACKED := Color("f06455")
const COLOR_GOLDEN := Color("ffd75e")
const COLOR_LINE_OFF := Color("17313a")
const COLOR_NEST_DAMAGE := Color("78b985")
const COLOR_PREDATOR_LOSS := Color("d47c5f")
const COLOR_APPEALS := Color("a18acb")
const COLOR_HARDWARE_BRASS := Color("b88b43")
const COLOR_HARDWARE_DARK := Color("3c4b4b")
const COLOR_HARDWARE_CREAM := Color("d9d2b8")
const RUNTIME_PROP_META := &"workstation_feedback_runtime"

const UPGRADE_PECKWORK_TOOLS := &"peckwork_tools"
const UPGRADE_SHELL_LAMP := &"shell_lamp"
const UPGRADE_NEST_CUSHION := &"nest_cushion"
const SUPPORTED_UPGRADES: Array[StringName] = [
	UPGRADE_PECKWORK_TOOLS,
	UPGRADE_SHELL_LAMP,
	UPGRADE_NEST_CUSHION,
]


class StationVisual extends RefCounted:
	var index: int = -1
	var root: Node3D
	var screens: Array[MeshInstance3D] = []
	var headers: Array[MeshInstance3D] = []
	var lines: Array[MeshInstance3D] = []
	var alerts: Array[MeshInstance3D] = []
	var phones: Array[MeshInstance3D] = []
	var claim_trays: Array[MeshInstance3D] = []
	var activity_papers: Array[MeshInstance3D] = []
	var stress_notice: MeshInstance3D
	var upgrade_keycaps: Array[MeshInstance3D] = []
	var upgrade_keycap_root: Node3D
	var quality_lamp_root: Node3D
	var quality_lamp_material: StandardMaterial3D
	var nest_upgrade_root: Node3D
	var nest_cushion: MeshInstance3D
	var nest_cushion_material: StandardMaterial3D
	var upgrade_prop_roots: Dictionary = {}
	var upgrade_tokens: Dictionary = {}
	var applied_upgrade_levels: Dictionary = {}
	var active_install_levels: Dictionary = {}
	var install_tweens: Dictionary = {}
	var install_generations: Dictionary = {}
	var chair_root: Node3D
	var chair_rest_rotation := Vector3.ZERO
	var chair_occupied: bool = false
	var screen_material: StandardMaterial3D
	var header_material: StandardMaterial3D
	var line_active_material: StandardMaterial3D
	var line_inactive_material: StandardMaterial3D
	var alert_material: StandardMaterial3D
	var phone_material: StandardMaterial3D
	var tray_material: StandardMaterial3D
	var state: int = STATE_IDLE
	var progress: float = 0.0
	var stress: float = 0.0
	var phase_offset: float = 0.0
	var base_color: Color = COLOR_IDLE
	var current_lane: StringName = &"auto"
	var peck_assist_ready: bool = false
	var completion_color: Color = COLOR_SOUND
	var completion_boost: float = 0.0
	var completion_tween: Tween


var _stations_by_index: Dictionary[int, StationVisual] = {}
var _stations_by_worker: Dictionary[int, StationVisual] = {}
var _station_list: Array[StationVisual] = []
var _phase: float = 0.0
var _update_accumulator: float = 0.0


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_phase = fmod(_phase + delta, TAU * 64.0)
	_update_accumulator += delta
	if _update_accumulator < UPDATE_INTERVAL:
		return
	_update_accumulator = fmod(_update_accumulator, UPDATE_INTERVAL)

	for station in _station_list:
		_animate_station(station)


## Cache imported workstation nodes and install local emissive materials.
## Workstations are expected to be named Workstation_00, Workstation_01, etc.
func configure(workstations_root: Node3D) -> void:
	_clear_cached_stations()
	if workstations_root == null:
		push_warning("WorkstationFeedback.configure received no workstation root.")
		return

	var roots: Array[Node3D] = []
	_collect_workstation_roots(workstations_root, roots)
	roots.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.name.naturalnocasecmp_to(b.name) < 0)

	for workstation in roots:
		var station := _build_station(workstation)
		_station_list.append(station)
		_stations_by_index[station.index] = station
		_apply_station_snapshot(station, STATE_IDLE, 0.0, 0.0, false)

	set_process(not _station_list.is_empty())


## Apply the DepartmentSimulation snapshot to each worker's assigned desk.
func apply_snapshot(snapshot: Dictionary) -> void:
	var upgrade_levels: Dictionary = snapshot.get("upgrade_levels", {}) as Dictionary
	for station in _station_list:
		_apply_upgrade_snapshot(station, upgrade_levels)
	_stations_by_worker.clear()
	var worker_data: Array = snapshot.get("workers", [])
	for worker_value in worker_data:
		if worker_value is not Dictionary:
			continue
		var worker_snapshot: Dictionary = worker_value
		var worker_id := int(worker_snapshot.get("id", -1))
		var desk_index := int(worker_snapshot.get("desk_index", worker_id))
		var station: StationVisual = _stations_by_index.get(desk_index)
		if station == null:
			continue
		_stations_by_worker[worker_id] = station
		_apply_station_snapshot(
			station,
			int(worker_snapshot.get("state", STATE_IDLE)),
			clampf(float(worker_snapshot.get("progress", 0.0)), 0.0, 100.0),
			clampf(float(worker_snapshot.get("stress", 0.0)), 0.0, 100.0),
			bool(worker_snapshot.get("at_workstation", false)),
			_worker_lane(worker_snapshot),
			bool((worker_snapshot.get("peck_assist", {}) as Dictionary).get("available", false))
		)


## Reveal and animate one installed workstation upgrade without replaying it on restore.
## An invalid desk index falls back to the worker's current authoritative mapping.
func play_reinvestment_install(
	worker_id: int,
	desk_index: int,
	upgrade_id: StringName,
	resulting_level: int
) -> bool:
	if upgrade_id not in SUPPORTED_UPGRADES or resulting_level <= 0:
		return false
	var station: StationVisual = _stations_by_index.get(desk_index)
	if station == null:
		station = _stations_by_worker.get(worker_id)
	if station == null:
		return false

	var prop_root := station.upgrade_prop_roots.get(upgrade_id) as Node3D
	var token_root := station.upgrade_tokens.get(upgrade_id) as Node3D
	if prop_root == null:
		return false

	_kill_install_tween(station, upgrade_id)
	station.active_install_levels[upgrade_id] = resulting_level
	_apply_single_upgrade_level(station, upgrade_id, resulting_level)
	prop_root.visible = true
	prop_root.scale = Vector3(0.72, 0.10, 0.72)
	if token_root != null:
		token_root.visible = true
		token_root.scale = Vector3(0.58, 0.08, 0.58)

	var generation := int(station.install_generations.get(upgrade_id, 0)) + 1
	station.install_generations[upgrade_id] = generation
	var install_tween := create_tween().bind_node(station.root)
	station.install_tweens[upgrade_id] = install_tween
	install_tween.tween_property(prop_root, "scale", Vector3(1.08, 1.08, 1.08), 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if token_root != null:
		install_tween.parallel().tween_property(token_root, "scale", Vector3(1.16, 1.16, 1.16), 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	install_tween.chain().tween_property(prop_root, "scale", Vector3.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if token_root != null:
		install_tween.parallel().tween_property(token_root, "scale", Vector3.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	install_tween.chain().tween_callback(
		_finish_reinvestment_install.bind(station, upgrade_id, generation, prop_root, token_root)
	)
	return true


## Camera-safe global focus point for a workstation install presentation.
func install_focus_point_global(desk_index: int) -> Vector3:
	var station: StationVisual = _stations_by_index.get(desk_index)
	if station == null or station.root == null:
		return Vector3.ZERO
	return station.root.to_global(Vector3(0.0, 1.42, 0.16))


## Stable real-prop root for presentation tests and camera integration.
func upgrade_prop_root(desk_index: int, upgrade_id: StringName) -> Node3D:
	var station: StationVisual = _stations_by_index.get(desk_index)
	if station == null:
		return null
	return station.upgrade_prop_roots.get(upgrade_id) as Node3D


## Play a short, interrupt-safe quality pulse on a worker's workstation.
func pulse_completion(worker_id: int, quality: StringName) -> void:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null:
		station = _stations_by_index.get(worker_id)
	if station == null:
		return

	match quality:
		&"golden":
			station.completion_color = COLOR_GOLDEN
		&"cracked":
			station.completion_color = COLOR_CRACKED
		_:
			station.completion_color = COLOR_SOUND

	if station.completion_tween != null and station.completion_tween.is_valid():
		station.completion_tween.kill()
	station.completion_boost = 0.0
	station.completion_tween = create_tween().bind_node(self)
	station.completion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	station.completion_tween.tween_property(station, "completion_boost", 1.0, 0.10)
	station.completion_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	station.completion_tween.tween_property(station, "completion_boost", 0.0, 0.72)


func pulse_peck_assist(worker_id: int, rating: StringName) -> void:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null:
		station = _stations_by_index.get(worker_id)
	if station == null:
		return
	station.completion_color = COLOR_GOLDEN if rating == &"perfect" else Color("8fd7bc")
	if station.completion_tween != null and station.completion_tween.is_valid():
		station.completion_tween.kill()
	station.completion_boost = 0.0
	station.completion_tween = create_tween().bind_node(self)
	station.completion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for _peck in 3:
		station.completion_tween.tween_property(station, "completion_boost", 1.0, 0.07)
		station.completion_tween.tween_property(station, "completion_boost", 0.22, 0.10)
	station.completion_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	station.completion_tween.tween_property(station, "completion_boost", 0.0, 0.36)


func _clear_cached_stations() -> void:
	for station in _station_list:
		if station.completion_tween != null and station.completion_tween.is_valid():
			station.completion_tween.kill()
		for tween_value in station.install_tweens.values():
			var install_tween := tween_value as Tween
			if install_tween != null and install_tween.is_valid():
				install_tween.kill()
	_station_list.clear()
	_stations_by_index.clear()
	_stations_by_worker.clear()
	_phase = 0.0
	_update_accumulator = 0.0
	set_process(false)


func _collect_workstation_roots(parent: Node, results: Array[Node3D]) -> void:
	var parent_3d := parent as Node3D
	if parent_3d != null and parent.name.begins_with("Workstation_"):
		results.append(parent_3d)
		return
	for child in parent.get_children():
		_collect_workstation_roots(child, results)


func _build_station(workstation: Node3D) -> StationVisual:
	_remove_runtime_station_props(workstation)
	var station := StationVisual.new()
	station.root = workstation
	station.index = String(workstation.name).trim_prefix("Workstation_").to_int()
	station.phase_offset = float(station.index) * 0.91
	station.screens = _meshes_named(workstation, &"Screen")
	station.headers = _meshes_named(workstation, &"ScreenHeader")
	station.lines = _meshes_with_prefix(workstation, "ScreenLine_")
	station.alerts = _meshes_named(workstation, &"ScreenAlert")
	station.phones = _meshes_named(workstation, &"PhoneReceiver")
	station.claim_trays = _meshes_named(workstation, &"ClaimTray")
	station.chair_root = workstation.find_child("TaskChair", true, false) as Node3D
	if station.chair_root != null:
		station.chair_rest_rotation = station.chair_root.rotation
	_build_activity_props(station)
	_build_upgrade_props(station)

	station.screen_material = _make_emissive_material(COLOR_IDLE, 0.72, 0.38)
	station.header_material = _make_emissive_material(COLOR_IDLE.lightened(0.22), 1.05, 0.32)
	station.line_active_material = _make_emissive_material(COLOR_WORKING.lightened(0.20), 1.25, 0.30)
	station.line_inactive_material = _make_emissive_material(COLOR_LINE_OFF, 0.18, 0.56)
	station.alert_material = _make_emissive_material(COLOR_IDLE.darkened(0.28), 0.28, 0.38)
	station.phone_material = _make_emissive_material(COLOR_IDLE.darkened(0.32), 0.20, 0.48)
	station.tray_material = _make_emissive_material(COLOR_IDLE.darkened(0.22), 0.16, 0.68)

	_assign_material(station.screens, station.screen_material)
	_assign_material(station.headers, station.header_material)
	_assign_material(station.alerts, station.alert_material)
	_assign_material(station.phones, station.phone_material)
	_assign_material(station.claim_trays, station.tray_material)
	return station


func _build_upgrade_props(station: StationVisual) -> void:
	if station.root == null:
		return
	var keyboard := station.root.find_child("Keyboard", true, false) as Node3D
	if keyboard == null:
		keyboard = station.root
	station.upgrade_keycap_root = _new_runtime_root("PeckworkKeycapUpgrade", keyboard)
	# Imported key tops sit at workstation y ~= 0.977 and z ~= -0.31. This
	# keyboard-local offset lets the requisition caps overlap those tops by a
	# few millimetres, so they read as installed hardware rather than floaters.
	station.upgrade_keycap_root.position = Vector3(0.0, 0.080, 0.090) if keyboard != station.root else Vector3(0.0, 0.990, -0.310)
	var keycap_materials: Array[StandardMaterial3D] = [
		_make_standard_material(Color("77b6a5"), 0.54, 0.08),
		_make_standard_material(COLOR_HARDWARE_CREAM, 0.62, 0.04),
	]
	for key_index in 5:
		var keycap := MeshInstance3D.new()
		keycap.name = "RequisitionKeycap_%d" % key_index
		var key_mesh := BoxMesh.new()
		key_mesh.size = Vector3(0.086, 0.032, 0.074)
		keycap.mesh = key_mesh
		keycap.position = Vector3(-0.196 + key_index * 0.098, 0.0, 0.0)
		keycap.material_override = keycap_materials[key_index % keycap_materials.size()]
		keycap.visible = false
		station.upgrade_keycap_root.add_child(keycap)
		station.upgrade_keycaps.append(keycap)

	var cubicle_back := station.root.find_child("CubicleBack", true, false) as Node3D
	if cubicle_back == null:
		cubicle_back = station.root
	station.quality_lamp_root = _new_runtime_root("ShellIntegrityDeskLamp", cubicle_back)
	station.quality_lamp_root.position = Vector3(-1.04, 0.29, 0.075) if cubicle_back != station.root else Vector3(-1.04, 1.57, 0.755)
	var dark_hardware := _make_standard_material(COLOR_HARDWARE_DARK, 0.48, 0.28)
	var brass_hardware := _make_standard_material(COLOR_HARDWARE_BRASS, 0.38, 0.58)
	_add_box_mesh(station.quality_lamp_root, "CandlerBackplate", Vector3(0.24, 0.30, 0.055), Vector3(0.0, 0.0, 0.0), dark_hardware)
	_add_box_mesh(station.quality_lamp_root, "CandlerVerticalArm", Vector3(0.045, 0.34, 0.045), Vector3(0.0, 0.22, 0.055), brass_hardware)
	_add_box_mesh(station.quality_lamp_root, "CandlerReachArm", Vector3(0.25, 0.045, 0.045), Vector3(0.105, 0.39, 0.055), brass_hardware)
	_add_cylinder_mesh(station.quality_lamp_root, "CandlerShade", 0.135, 0.18, 0.12, Vector3(0.22, 0.39, 0.13), Vector3(PI * 0.5, 0.0, 0.0), dark_hardware)
	station.quality_lamp_material = _make_emissive_material(Color("f3ca68"), 0.66, 0.24)
	var lamp_glow := _add_sphere_mesh(station.quality_lamp_root, "LampGlow", Vector3(0.22, 0.39, 0.208), Vector3(0.20, 0.20, 0.075), station.quality_lamp_material)
	lamp_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	station.quality_lamp_root.visible = false

	var chair_host := station.chair_root if station.chair_root != null else station.root
	station.nest_upgrade_root = _new_runtime_root("ErgonomicNestUpgrade", chair_host)
	station.nest_cushion_material = _make_standard_material(Color("8b7898"), 0.92)
	station.nest_cushion = _add_sphere_mesh(station.nest_upgrade_root, "ErgonomicNestCushion", Vector3(0.0, 0.68, -1.03), Vector3(0.76, 0.14, 0.60), station.nest_cushion_material)
	_add_sphere_mesh(station.nest_upgrade_root, "ErgonomicNestBackrest", Vector3(0.0, 1.10, -1.315), Vector3(0.72, 0.72, 0.16), station.nest_cushion_material)
	_add_sphere_mesh(station.nest_upgrade_root, "ErgonomicNestLeftWing", Vector3(-0.34, 1.08, -1.29), Vector3(0.22, 0.54, 0.18), station.nest_cushion_material)
	_add_sphere_mesh(station.nest_upgrade_root, "ErgonomicNestRightWing", Vector3(0.34, 1.08, -1.29), Vector3(0.22, 0.54, 0.18), station.nest_cushion_material)
	_add_sphere_mesh(station.nest_upgrade_root, "ErgonomicNestBridge", Vector3(0.0, 0.79, -1.20), Vector3(0.52, 0.20, 0.22), station.nest_cushion_material)
	var seam_material := _make_standard_material(Color("66586e"), 0.96)
	_add_box_mesh(station.nest_upgrade_root, "NestBackrestSeam", Vector3(0.032, 0.46, 0.026), Vector3(0.0, 1.10, -1.22), seam_material)
	station.nest_upgrade_root.visible = false

	station.upgrade_prop_roots[UPGRADE_PECKWORK_TOOLS] = station.upgrade_keycap_root
	station.upgrade_prop_roots[UPGRADE_SHELL_LAMP] = station.quality_lamp_root
	station.upgrade_prop_roots[UPGRADE_NEST_CUSHION] = station.nest_upgrade_root
	_build_issued_hardware_tokens(station, cubicle_back)


func _apply_upgrade_snapshot(station: StationVisual, levels: Dictionary) -> void:
	for upgrade_id in SUPPORTED_UPGRADES:
		var authoritative_level := clampi(int(levels.get(upgrade_id, levels.get(String(upgrade_id), 0))), 0, 5)
		station.applied_upgrade_levels[upgrade_id] = authoritative_level
		var active_level := int(station.active_install_levels.get(upgrade_id, 0))
		_apply_single_upgrade_level(station, upgrade_id, maxi(authoritative_level, active_level))


func _apply_single_upgrade_level(station: StationVisual, upgrade_id: StringName, raw_level: int) -> void:
	var level := clampi(raw_level, 0, 5)
	match upgrade_id:
		UPGRADE_PECKWORK_TOOLS:
			var visible_keys := mini(level, station.upgrade_keycaps.size())
			if station.upgrade_keycap_root != null:
				station.upgrade_keycap_root.visible = visible_keys > 0
			for key_index in station.upgrade_keycaps.size():
				station.upgrade_keycaps[key_index].visible = key_index < visible_keys
		UPGRADE_SHELL_LAMP:
			if station.quality_lamp_root != null:
				station.quality_lamp_root.visible = level > 0
			if station.quality_lamp_material != null:
				station.quality_lamp_material.emission_energy_multiplier = 0.48 + level * 0.18
		UPGRADE_NEST_CUSHION:
			if station.nest_upgrade_root != null:
				station.nest_upgrade_root.visible = level > 0
			if station.nest_cushion_material != null:
				station.nest_cushion_material.albedo_color = Color("8b7898").lerp(Color("d0a65c"), level / 5.0)
	var token := station.upgrade_tokens.get(upgrade_id) as Node3D
	if token != null:
		token.visible = level > 0


func _build_issued_hardware_tokens(station: StationVisual, cubicle_back: Node3D) -> void:
	if cubicle_back == null:
		return
	var plaque_material := _make_standard_material(Color("526160"), 0.52, 0.26)
	var token_colors: Dictionary = {
		UPGRADE_PECKWORK_TOOLS: Color("74b9a7"),
		UPGRADE_SHELL_LAMP: Color("f0c968"),
		UPGRADE_NEST_CUSHION: Color("a38aaa"),
	}
	for token_index in SUPPORTED_UPGRADES.size():
		var upgrade_id := SUPPORTED_UPGRADES[token_index]
		var token := _new_runtime_root("IssuedHardwareToken_%s" % String(upgrade_id), cubicle_back)
		token.position = (
			Vector3(0.50 + token_index * 0.28, 0.28, 0.075)
			if cubicle_back != station.root
			else Vector3(0.50 + token_index * 0.28, 1.56, 0.755)
		)
		_add_cylinder_mesh(token, "IssuedTokenMount", 0.096, 0.096, 0.035, Vector3.ZERO, Vector3(PI * 0.5, 0.0, 0.0), plaque_material)
		var icon_material := _make_emissive_material(token_colors[upgrade_id], 0.38, 0.42)
		match upgrade_id:
			UPGRADE_PECKWORK_TOOLS:
				for key_index in 3:
					_add_box_mesh(token, "TokenKey_%d" % key_index, Vector3(0.042, 0.035, 0.025), Vector3(-0.048 + key_index * 0.048, 0.0, 0.040), icon_material)
			UPGRADE_SHELL_LAMP:
				_add_box_mesh(token, "TokenLampArm", Vector3(0.024, 0.086, 0.022), Vector3(-0.025, 0.0, 0.038), icon_material)
				_add_sphere_mesh(token, "TokenLampLens", Vector3(0.028, 0.028, 0.044), Vector3(0.095, 0.095, 0.040), icon_material)
			UPGRADE_NEST_CUSHION:
				_add_sphere_mesh(token, "TokenNestPad", Vector3(0.0, 0.0, 0.042), Vector3(0.145, 0.115, 0.045), icon_material)
		token.visible = false
		station.upgrade_tokens[upgrade_id] = token


func _kill_install_tween(station: StationVisual, upgrade_id: StringName) -> void:
	var active_tween := station.install_tweens.get(upgrade_id) as Tween
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	station.install_tweens.erase(upgrade_id)


func _finish_reinvestment_install(
	station: StationVisual,
	upgrade_id: StringName,
	generation: int,
	prop_root: Node3D,
	token_root: Node3D
) -> void:
	if int(station.install_generations.get(upgrade_id, -1)) != generation:
		return
	if is_instance_valid(prop_root):
		prop_root.scale = Vector3.ONE
	if is_instance_valid(token_root):
		token_root.scale = Vector3.ONE
	station.install_tweens.erase(upgrade_id)
	station.active_install_levels.erase(upgrade_id)
	var authoritative_level := int(station.applied_upgrade_levels.get(upgrade_id, 0))
	_apply_single_upgrade_level(station, upgrade_id, authoritative_level)


func _apply_station_snapshot(
	station: StationVisual,
	state: int,
	progress: float,
	stress: float,
	at_workstation: bool,
	lane: StringName = &"auto",
	peck_assist_ready: bool = false
) -> void:
	station.state = state
	station.progress = progress
	station.stress = stress
	station.chair_occupied = at_workstation
	station.current_lane = lane
	station.peck_assist_ready = peck_assist_ready
	var state_color := _state_color(state)
	var lane_color := _lane_color(lane)
	var lane_mix := 0.62 if state in [STATE_WORKING, STATE_LAYING] else 0.24
	station.base_color = state_color.lerp(lane_color, lane_mix) if lane != &"auto" else state_color

	station.screen_material.albedo_color = station.base_color.darkened(0.68)
	station.header_material.albedo_color = station.base_color.darkened(0.48)
	station.phone_material.albedo_color = station.base_color.darkened(0.72)
	station.tray_material.albedo_color = station.base_color.darkened(0.66)
	station.phone_material.emission = station.base_color.darkened(0.16)
	station.tray_material.emission = station.base_color.darkened(0.26)
	var visible_papers := 0
	if state == STATE_WORKING:
		visible_papers = clampi(1 + floori(progress / 24.0), 1, station.activity_papers.size())
	elif state == STATE_LAYING:
		visible_papers = station.activity_papers.size()
	for paper_index in station.activity_papers.size():
		station.activity_papers[paper_index].visible = paper_index < visible_papers
	if station.stress_notice != null:
		station.stress_notice.visible = stress >= 72.0

	var active_line_count := 0
	if state == STATE_WORKING:
		active_line_count = ceili(progress * float(station.lines.size()) / 100.0)
	elif state == STATE_LAYING:
		active_line_count = station.lines.size()
	for line_index in station.lines.size():
		var line := station.lines[line_index]
		line.material_override = (
			station.line_active_material if line_index < active_line_count
			else station.line_inactive_material
		)


func _animate_station(station: StationVisual) -> void:
	if station.screen_material == null:
		return

	var slow_pulse := sin(_phase * 2.2 + station.phase_offset) * 0.07
	var fine_flicker := sin(_phase * 13.0 + station.phase_offset * 1.7) * 0.018
	var stress_flicker := fine_flicker * remap(station.stress, 0.0, 100.0, 0.35, 1.35)
	var completion_mix := clampf(station.completion_boost, 0.0, 1.0)
	var display_color := station.base_color.lerp(station.completion_color, completion_mix)
	if station.peck_assist_ready:
		var ready_mix := 0.34 + maxf(0.0, sin(_phase * 5.6 + station.phase_offset)) * 0.24
		display_color = display_color.lerp(COLOR_GOLDEN, ready_mix)
	var work_energy := 1.00 if station.state == STATE_WORKING else 0.72
	if station.state == STATE_LAYING:
		work_energy = 1.22
	elif station.state == STATE_BREAK:
		work_energy = 0.52

	station.screen_material.emission = display_color
	station.header_material.emission = display_color.lightened(0.17)
	station.line_active_material.emission = display_color.lightened(0.25)
	station.screen_material.emission_energy_multiplier = maxf(0.18, work_energy + slow_pulse + stress_flicker + completion_mix * 1.25)
	station.header_material.emission_energy_multiplier = maxf(0.18, work_energy + slow_pulse * 0.55 + completion_mix * 1.55)
	station.line_active_material.emission_energy_multiplier = 1.10 + slow_pulse * 0.45 + completion_mix * 1.20

	var alert_strength := 0.18
	var alert_color := station.base_color.darkened(0.30)
	if station.state == STATE_LAYING:
		alert_strength = 0.70 + maxf(0.0, sin(_phase * 7.0 + station.phase_offset)) * 0.95
		alert_color = COLOR_LAYING
	elif station.stress >= 72.0:
		alert_strength = 0.48 + maxf(0.0, sin(_phase * 5.4 + station.phase_offset)) * 0.72
		alert_color = COLOR_ALERT
	if completion_mix > 0.0:
		alert_strength += completion_mix * 1.8
		alert_color = alert_color.lerp(station.completion_color, completion_mix)
	station.alert_material.emission = alert_color
	station.alert_material.emission_energy_multiplier = alert_strength
	for paper_index in station.activity_papers.size():
		var paper := station.activity_papers[paper_index]
		if not paper.visible:
			continue
		var rest_y := float(paper.get_meta("rest_y", paper.position.y))
		paper.position.y = rest_y + sin(_phase * 1.35 + station.phase_offset + paper_index * 0.7) * 0.006
	if station.stress_notice != null and station.stress_notice.visible:
		station.stress_notice.rotation.z = sin(_phase * 3.8 + station.phase_offset) * 0.025
	if station.chair_root != null:
		var unattended_swivel := sin(_phase * 0.42 + station.phase_offset) * 0.075
		var target_y := station.chair_rest_rotation.y if station.chair_occupied else station.chair_rest_rotation.y + unattended_swivel
		station.chair_root.rotation.y = lerp_angle(station.chair_root.rotation.y, target_y, 0.16)


func _build_activity_props(station: StationVisual) -> void:
	if station.root == null:
		return
	var tray_position := Vector3(-0.72, 1.04, 0.18)
	if not station.claim_trays.is_empty():
		tray_position = station.root.to_local(station.claim_trays[0].global_position) + Vector3(0.0, 0.08, 0.0)
	for paper_index in 5:
		var paper := MeshInstance3D.new()
		paper.name = "LivePeckworkPaper_%d" % paper_index
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.48, 0.018, 0.34)
		paper.mesh = mesh
		paper.position = tray_position + Vector3((paper_index % 2) * 0.018, paper_index * 0.023, (paper_index % 3) * 0.010)
		paper.rotation_degrees.y = -2.5 + paper_index * 1.1
		paper.set_meta("rest_y", paper.position.y)
		var paper_material := StandardMaterial3D.new()
		paper_material.albedo_color = Color("dedbc8") if paper_index % 2 == 0 else Color("c5d2ce")
		paper_material.roughness = 0.92
		paper.material_override = paper_material
		paper.visible = false
		station.root.add_child(paper)
		station.activity_papers.append(paper)

	station.stress_notice = MeshInstance3D.new()
	station.stress_notice.name = "StressNotice"
	var notice_mesh := BoxMesh.new()
	notice_mesh.size = Vector3(0.42, 0.28, 0.025)
	station.stress_notice.mesh = notice_mesh
	station.stress_notice.position = Vector3(0.62, 1.31, 0.79)
	var notice_material := StandardMaterial3D.new()
	notice_material.albedo_color = COLOR_ALERT
	notice_material.roughness = 0.78
	station.stress_notice.material_override = notice_material
	station.stress_notice.visible = false
	station.root.add_child(station.stress_notice)


func _remove_runtime_station_props(workstation: Node3D) -> void:
	for child in workstation.get_children():
		_remove_runtime_prop_branch(child)


func _remove_runtime_prop_branch(node: Node) -> void:
	var node_name := String(node.name)
	var is_runtime_root := bool(node.get_meta(RUNTIME_PROP_META, false))
	is_runtime_root = is_runtime_root or node_name.begins_with("LivePeckworkPaper_")
	is_runtime_root = is_runtime_root or node_name.begins_with("RequisitionKeycap_")
	is_runtime_root = is_runtime_root or node_name == "StressNotice"
	is_runtime_root = is_runtime_root or node_name == "ShellIntegrityDeskLamp"
	is_runtime_root = is_runtime_root or node_name == "ErgonomicNestCushion"
	if is_runtime_root:
		node.free()
		return
	for child in node.get_children():
		_remove_runtime_prop_branch(child)


func _new_runtime_root(node_name: String, parent: Node3D) -> Node3D:
	var runtime_root := Node3D.new()
	runtime_root.name = node_name
	runtime_root.set_meta(RUNTIME_PROP_META, true)
	parent.add_child(runtime_root)
	return runtime_root


func _add_box_mesh(
	parent: Node3D,
	node_name: String,
	size: Vector3,
	position: Vector3,
	material: StandardMaterial3D
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = position
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance


func _add_cylinder_mesh(
	parent: Node3D,
	node_name: String,
	top_radius: float,
	bottom_radius: float,
	height: float,
	position: Vector3,
	rotation: Vector3,
	material: StandardMaterial3D
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = top_radius
	cylinder.bottom_radius = bottom_radius
	cylinder.height = height
	cylinder.radial_segments = 12
	mesh_instance.mesh = cylinder
	mesh_instance.position = position
	mesh_instance.rotation = rotation
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance


func _add_sphere_mesh(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	scale: Vector3,
	material: StandardMaterial3D
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 16
	sphere.rings = 8
	mesh_instance.mesh = sphere
	mesh_instance.position = position
	mesh_instance.scale = scale
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance


func _state_color(state: int) -> Color:
	match state:
		STATE_WORKING:
			return COLOR_WORKING
		STATE_LAYING:
			return COLOR_LAYING
		STATE_BREAK:
			return COLOR_BREAK
		_:
			return COLOR_IDLE


func _worker_lane(worker_snapshot: Dictionary) -> StringName:
	var current_claim := worker_snapshot.get("current_claim", {}) as Dictionary
	if not current_claim.is_empty():
		return StringName(current_claim.get("lane", &"auto"))
	return StringName(worker_snapshot.get("assignment", &"auto"))


func _lane_color(lane: StringName) -> Color:
	match lane:
		&"nest_damage":
			return COLOR_NEST_DAMAGE
		&"predator_loss":
			return COLOR_PREDATOR_LOSS
		&"appeals":
			return COLOR_APPEALS
		_:
			return COLOR_IDLE


func _make_emissive_material(color: Color, energy: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_local_to_scene = true
	material.albedo_color = color.darkened(0.66)
	material.metallic = 0.0
	material.roughness = roughness
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


func _make_standard_material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_local_to_scene = true
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _assign_material(meshes: Array[MeshInstance3D], material: StandardMaterial3D) -> void:
	for mesh in meshes:
		mesh.material_override = material


func _meshes_named(parent: Node, target_name: StringName) -> Array[MeshInstance3D]:
	var results: Array[MeshInstance3D] = []
	var target := parent.find_child(String(target_name), true, false)
	if target != null:
		_collect_meshes(target, results)
	return results


func _meshes_with_prefix(parent: Node, prefix: String) -> Array[MeshInstance3D]:
	var results: Array[MeshInstance3D] = []
	_collect_prefixed_meshes(parent, prefix, results)
	results.sort_custom(func(a: MeshInstance3D, b: MeshInstance3D) -> bool: return a.name.naturalnocasecmp_to(b.name) < 0)
	return results


func _collect_prefixed_meshes(parent: Node, prefix: String, results: Array[MeshInstance3D]) -> void:
	if parent.name.begins_with(prefix):
		_collect_meshes(parent, results)
		return
	for child in parent.get_children():
		_collect_prefixed_meshes(child, prefix, results)


func _collect_meshes(parent: Node, results: Array[MeshInstance3D]) -> void:
	var mesh := parent as MeshInstance3D
	if mesh != null:
		results.append(mesh)
	for child in parent.get_children():
		_collect_meshes(child, results)
