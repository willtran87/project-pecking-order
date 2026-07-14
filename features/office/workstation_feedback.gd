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
	var quality_lamp_root: Node3D
	var quality_lamp_material: StandardMaterial3D
	var nest_cushion: MeshInstance3D
	var nest_cushion_material: StandardMaterial3D
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
	for key_index in 5:
		var keycap := MeshInstance3D.new()
		keycap.name = "RequisitionKeycap_%d" % key_index
		var key_mesh := BoxMesh.new()
		key_mesh.size = Vector3(0.095, 0.035, 0.085)
		keycap.mesh = key_mesh
		keycap.position = Vector3(-0.25 + key_index * 0.12, 1.105, 0.37)
		keycap.material_override = _make_emissive_material(Color("7fc9b4"), 0.62 + key_index * 0.06, 0.34)
		keycap.visible = false
		station.root.add_child(keycap)
		station.upgrade_keycaps.append(keycap)

	station.quality_lamp_root = Node3D.new()
	station.quality_lamp_root.name = "ShellIntegrityDeskLamp"
	station.quality_lamp_root.position = Vector3(0.70, 1.04, -0.18)
	station.root.add_child(station.quality_lamp_root)
	var lamp_pole := MeshInstance3D.new()
	lamp_pole.name = "LampPole"
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.022
	pole_mesh.bottom_radius = 0.028
	pole_mesh.height = 0.44
	pole_mesh.radial_segments = 10
	lamp_pole.mesh = pole_mesh
	lamp_pole.position.y = 0.22
	lamp_pole.material_override = _make_standard_material(Color("4e5d60"), 0.42, 0.34)
	station.quality_lamp_root.add_child(lamp_pole)
	var lamp_head := MeshInstance3D.new()
	lamp_head.name = "LampGlow"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.5
	head_mesh.height = 1.0
	head_mesh.radial_segments = 12
	head_mesh.rings = 6
	lamp_head.mesh = head_mesh
	lamp_head.scale = Vector3(0.13, 0.085, 0.13)
	lamp_head.position.y = 0.46
	station.quality_lamp_material = _make_emissive_material(Color("f0c968"), 0.54, 0.28)
	lamp_head.material_override = station.quality_lamp_material
	station.quality_lamp_root.add_child(lamp_head)
	station.quality_lamp_root.visible = false

	station.nest_cushion = MeshInstance3D.new()
	station.nest_cushion.name = "ErgonomicNestCushion"
	var cushion_mesh := BoxMesh.new()
	cushion_mesh.size = Vector3(0.68, 0.10, 0.54)
	station.nest_cushion.mesh = cushion_mesh
	station.nest_cushion.position = Vector3(0.0, 0.65, -0.96)
	station.nest_cushion_material = _make_standard_material(Color("8b7898"), 0.92)
	station.nest_cushion.material_override = station.nest_cushion_material
	station.nest_cushion.visible = false
	station.root.add_child(station.nest_cushion)


func _apply_upgrade_snapshot(station: StationVisual, levels: Dictionary) -> void:
	var tool_level := clampi(int(levels.get(&"peckwork_tools", 0)), 0, station.upgrade_keycaps.size())
	for key_index in station.upgrade_keycaps.size():
		station.upgrade_keycaps[key_index].visible = key_index < tool_level
	var lamp_level := clampi(int(levels.get(&"shell_lamp", 0)), 0, 5)
	if station.quality_lamp_root != null:
		station.quality_lamp_root.visible = lamp_level > 0
	if station.quality_lamp_material != null:
		station.quality_lamp_material.emission_energy_multiplier = 0.48 + lamp_level * 0.18
	var cushion_level := clampi(int(levels.get(&"nest_cushion", 0)), 0, 5)
	if station.nest_cushion != null:
		station.nest_cushion.visible = cushion_level > 0
	if station.nest_cushion_material != null:
		station.nest_cushion_material.albedo_color = Color("8b7898").lerp(Color("d0a65c"), cushion_level / 5.0)


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
