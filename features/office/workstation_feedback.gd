class_name WorkstationFeedback
extends Node

const SemanticColorPaletteScript := preload("res://core/settings/semantic_color_palette.gd")

signal routing_reward_presented(worker_id: int, reward: Dictionary, chain: int)
signal dispatch_landing_presented(worker_id: int, receipt: Dictionary)
signal dispatch_work_started_presented(worker_id: int, receipt: Dictionary)
signal egg_delivery_ack_presented(worker_id: int, receipt: Dictionary)
signal work_progress_interactions_changed

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
const COLOR_ROUTING_PACE := Color("74d4c2")
const COLOR_LINE_OFF := Color("17313a")
const COLOR_NEST_DAMAGE := Color("78b985")
const COLOR_PREDATOR_LOSS := Color("d47c5f")
const COLOR_APPEALS := Color("a18acb")
const COLOR_HARDWARE_BRASS := Color("b88b43")
const COLOR_HARDWARE_DARK := Color("3c4b4b")
const COLOR_HARDWARE_CREAM := Color("d9d2b8")
const RUNTIME_PROP_META := &"workstation_feedback_runtime"
const ROUTING_REWARD_DURATION := 1.55
const EGG_DELIVERY_ACK_DURATION := 1.55
const DISPATCH_LANDING_DURATION := 0.96
const DISPATCH_WORK_HANDOFF_DURATION := 0.34
const WORK_PROGRESS_PIP_COUNT := 5
const WORK_DEADLINE_RISK_MINUTES := 60

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
	var golden_file_seal: Node3D
	var golden_file_seal_material: StandardMaterial3D
	var golden_file_target: bool = false
	var peck_contact_root: Node3D
	var peck_contact_disc: MeshInstance3D
	var peck_contact_material: StandardMaterial3D
	var pace_flow_root: Node3D
	var pace_flow_material: StandardMaterial3D
	var pace_active: bool = false
	var work_progress_root: Node3D
	var work_progress_pips: Array[MeshInstance3D] = []
	var work_progress_active_material: StandardMaterial3D
	var work_progress_inactive_material: StandardMaterial3D
	var work_progress_warning_material: StandardMaterial3D
	var work_progress_pause_root: Node3D
	var work_progress_risk_root: Node3D
	var work_progress_affordance_root: Node3D
	var work_progress_affordance_material: StandardMaterial3D
	var work_progress_hovered := false
	var work_progress_selected := false
	var work_progress_status: StringName = &"hidden"
	var minutes_until_deadline: int = 9999
	var claim_overdue: bool = false
	var claim_is_rework: bool = false
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
	var specialty_match: bool = false
	var peck_assist_ready: bool = false
	var completion_color: Color = COLOR_SOUND
	var completion_boost: float = 0.0
	var completion_tween: Tween
	var contact_boost: float = 0.0
	var route_boost: float = 0.0
	var dispatch_landing_root: Node3D
	var dispatch_landing_sprite: Sprite3D
	var dispatch_landing_tween: Tween
	var dispatch_landing_rest_position := Vector3.ZERO
	var dispatch_landing_serial := 0
	var dispatch_landing_active := false
	var dispatch_landing_animated := false
	var dispatch_landing_capture_staged := false
	var dispatch_landing_settled := false
	var dispatch_work_handoff_queued := false
	var dispatch_work_handoff_active := false
	var dispatch_work_handoff_animated := false
	var dispatch_work_handoff_capture_staged := false
	var dispatch_work_contact_serial := 0
	var egg_delivery_ack_root: Node3D
	var egg_delivery_ack_sprite: Sprite3D
	var egg_delivery_ack_tween: Tween
	var egg_delivery_ack_rest_position := Vector3.ZERO
	var egg_delivery_ack_serial := 0
	var egg_delivery_ack_active := false
	var egg_delivery_ack_animated := false
	var egg_delivery_ack_capture_staged := false
	var egg_delivery_ack_kind: StringName = &"cash"
	var egg_delivery_ack_worker_id := -1
	var egg_delivery_ack_worker_name := ""
	var egg_delivery_ack_claim_id := -1
	var egg_delivery_ack_quality: StringName = &"sound"
	var egg_delivery_ack_cash_cents := 0
	var egg_delivery_ack_priority_refunded := false
	var contact_count: int = 0
	var worker_id: int = -1
	var current_claim_id: int = -1
	var worker_name: String = ""
	var loop_stage: StringName = &"waiting_file"


var _stations_by_index: Dictionary[int, StationVisual] = {}
var _stations_by_worker: Dictionary[int, StationVisual] = {}
var _station_list: Array[StationVisual] = []
var _phase: float = 0.0
var _update_accumulator: float = 0.0
var _color_vision_mode: StringName = &"standard"
var _animation_speed_multiplier := 1.0
var _reduced_motion := false
var _routing_pace_active := false
var _routing_pace_multiplier := 1.0
var _active_dispatch_deliveries: Array[Node3D] = []
var _active_routing_reward_bursts: Array[Node3D] = []
static var _routing_reward_texture_cache: Dictionary[StringName, Texture2D] = {}
static var _dispatch_landing_texture_cache: Dictionary[StringName, Texture2D] = {}
static var _egg_delivery_ack_texture_cache: Dictionary[StringName, Texture2D] = {}
var _dispatch_landing_serial := 0
var _last_dispatch_landing: Dictionary = {}
var _egg_delivery_ack_serial := 0
var _last_egg_delivery_ack: Dictionary = {}


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_phase = fmod(_phase + delta, TAU * 64.0)
	_update_accumulator += delta
	if _update_accumulator < UPDATE_INTERVAL:
		return
	_update_accumulator = fmod(_update_accumulator, UPDATE_INTERVAL)

	for station in _station_list:
		station.contact_boost = (
			1.0
			if station.dispatch_work_handoff_capture_staged else
			move_toward(station.contact_boost, 0.0, UPDATE_INTERVAL * 7.5)
		)
		station.route_boost = move_toward(station.route_boost, 0.0, UPDATE_INTERVAL * 2.4)
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
	var routing_momentum := snapshot.get("routing_momentum", {}) as Dictionary
	_routing_pace_active = bool(routing_momentum.get("pace_active", false))
	_routing_pace_multiplier = (
		maxf(1.0, float(routing_momentum.get("pace_multiplier", 1.0)))
		if _routing_pace_active else
		1.0
	)
	var upgrade_levels: Dictionary = snapshot.get("upgrade_levels", {}) as Dictionary
	for station in _station_list:
		_apply_upgrade_snapshot(station, upgrade_levels)
	_stations_by_worker.clear()
	var assigned_desk_indices: Dictionary[int, bool] = {}
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
		assigned_desk_indices[desk_index] = true
		station.worker_id = worker_id
		var claim: Dictionary = worker_snapshot.get("current_claim", {}) as Dictionary
		var claim_id := int(claim.get("id", -1))
		if claim_id >= 0 and claim_id != station.current_claim_id:
			station.route_boost = 1.0
			station.root.set_meta("last_routed_claim_id", claim_id)
		station.current_claim_id = claim_id
		station.minutes_until_deadline = int(claim.get("minutes_until_deadline", 9999))
		station.claim_overdue = bool(claim.get("overdue", false))
		station.claim_is_rework = bool(claim.get("is_rework", false))
		station.worker_name = String(worker_snapshot.get("name", "HEN %d" % (worker_id + 1)))
		_apply_station_snapshot(
			station,
			int(worker_snapshot.get("state", STATE_IDLE)),
			clampf(float(worker_snapshot.get("progress", 0.0)), 0.0, 100.0),
			clampf(float(worker_snapshot.get("stress", 0.0)), 0.0, 100.0),
			bool(worker_snapshot.get("at_workstation", false)),
			_worker_lane(worker_snapshot),
			bool((worker_snapshot.get("peck_assist", {}) as Dictionary).get("available", false)),
			bool(claim.get("specialty_match", false)),
			bool(claim.get("routing_golden_target", false)),
		)
	for station in _station_list:
		if assigned_desk_indices.has(station.index) or station.worker_id < 0:
			continue
		station.worker_id = -1
		station.worker_name = ""
		station.current_claim_id = -1
		station.minutes_until_deadline = 9999
		station.claim_overdue = false
		station.claim_is_rework = false
		_apply_station_snapshot(station, STATE_IDLE, 0.0, 0.0, false)
	work_progress_interactions_changed.emit()


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
	install_tween.set_speed_scale(_animation_speed_multiplier)
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


func set_color_vision_mode(mode: StringName) -> void:
	var normalized := SemanticColorPaletteScript.normalize_mode(mode)
	if normalized == _color_vision_mode:
		return
	_color_vision_mode = normalized
	for station in _station_list:
		_apply_station_snapshot(
			station,
			station.state,
			station.progress,
			station.stress,
			station.chair_occupied,
			station.current_lane,
			station.peck_assist_ready,
			station.specialty_match,
			station.golden_file_target,
		)
		if station.egg_delivery_ack_active and station.egg_delivery_ack_sprite != null:
			station.egg_delivery_ack_sprite.texture = _egg_delivery_ack_texture(
				station.egg_delivery_ack_kind,
				station.egg_delivery_ack_quality,
			)


func color_vision_mode() -> StringName:
	return _color_vision_mode


func set_animation_speed_multiplier(multiplier: float) -> void:
	_animation_speed_multiplier = clampf(multiplier, 0.5, 2.0)
	for station in _station_list:
		if station.completion_tween != null and station.completion_tween.is_valid():
			station.completion_tween.set_speed_scale(_animation_speed_multiplier)
		if station.dispatch_landing_tween != null and station.dispatch_landing_tween.is_valid():
			station.dispatch_landing_tween.set_speed_scale(_animation_speed_multiplier)
		if station.egg_delivery_ack_tween != null and station.egg_delivery_ack_tween.is_valid():
			station.egg_delivery_ack_tween.set_speed_scale(_animation_speed_multiplier)
		for tween_value in station.install_tweens.values():
			var install_tween := tween_value as Tween
			if install_tween != null and install_tween.is_valid():
				install_tween.set_speed_scale(_animation_speed_multiplier)


func animation_speed_multiplier() -> float:
	return _animation_speed_multiplier


func set_reduced_motion(enabled: bool) -> void:
	if enabled and not _reduced_motion:
		for station in _station_list:
			if station.egg_delivery_ack_active:
				_hold_egg_delivery_ack_static(station, station.egg_delivery_ack_serial)
			if station.dispatch_work_handoff_active:
				_hold_dispatch_work_handoff_static(
					station,
					station.dispatch_landing_serial,
				)
			elif station.dispatch_landing_active:
				_hold_dispatch_landing_static(station, station.dispatch_landing_serial)
	_reduced_motion = enabled
	for station in _station_list:
		_animate_station(station)


func reduced_motion() -> bool:
	return _reduced_motion


func routing_pace_snapshot() -> Dictionary:
	var active_desks: Array[int] = []
	var golden_target_desks: Array[int] = []
	for station in _station_list:
		if station.pace_active:
			active_desks.append(station.index)
		if station.golden_file_target:
			golden_target_desks.append(station.index)
	return {
		"authoritative_active": _routing_pace_active,
		"pace_multiplier": _routing_pace_multiplier,
		"active_desk_count": active_desks.size(),
		"active_desk_indices": active_desks,
		"shape": "double_chevron",
		"view_sides": 2,
		"animated": _routing_pace_active and not _reduced_motion,
		"reduced_motion": _reduced_motion,
		"golden_target_desk_count": golden_target_desks.size(),
		"golden_target_desk_indices": golden_target_desks,
		"golden_target_shape": "diamond_egg_seal",
	}


## Compact assistive mirror for the physical cubicle progress rails. Each desk
## owns one fixed five-pip rail; status shapes make pauses and deadline risk
## readable without color, text, or opening the worker dossier.
func work_progress_snapshot() -> Dictionary:
	var desks: Array[Dictionary] = []
	var visible_count := 0
	var risk_count := 0
	var paused_count := 0
	var hovered_count := 0
	var selected_count := 0
	for station in _station_list:
		var visible := station.work_progress_root != null and station.work_progress_root.visible
		if visible:
			visible_count += 1
		if station.work_progress_status == &"deadline_risk":
			risk_count += 1
		elif station.work_progress_status == &"paused":
			paused_count += 1
		if station.work_progress_hovered:
			hovered_count += 1
		if station.work_progress_selected:
			selected_count += 1
		var filled_pips := clampi(
			ceili(station.progress * float(WORK_PROGRESS_PIP_COUNT) / 100.0),
			0,
			WORK_PROGRESS_PIP_COUNT,
		)
		desks.append({
			"worker_id": station.worker_id,
			"desk_index": station.index,
			"worker_name": station.worker_name,
			"claim_id": station.current_claim_id,
			"lane": String(station.current_lane),
			"progress": snappedf(station.progress, 0.1),
			"filled_pips": filled_pips,
			"pip_count": WORK_PROGRESS_PIP_COUNT,
			"status": String(station.work_progress_status),
			"shape": _work_progress_shape(station.work_progress_status),
			"minutes_until_deadline": station.minutes_until_deadline,
			"overdue": station.claim_overdue,
			"rework": station.claim_is_rework,
			"visible": visible,
			"animated": visible and not _reduced_motion,
			"interactive": visible and station.worker_id >= 0,
			"hovered": station.work_progress_hovered,
			"selected": station.work_progress_selected,
			"affordance_visible": (
				station.work_progress_affordance_root != null
				and station.work_progress_affordance_root.visible
			),
			"affordance_shape": "corner_brackets",
			"affordance_animated": (
				station.work_progress_hovered and not _reduced_motion
			),
		})
	return {
		"pooled_rail_count": _station_list.size(),
		"pip_count_per_rail": WORK_PROGRESS_PIP_COUNT,
		"visible_count": visible_count,
		"deadline_risk_count": risk_count,
		"paused_count": paused_count,
		"hovered_count": hovered_count,
		"selected_count": selected_count,
		"pooled_affordance_count": _station_list.size(),
		"reduced_motion": _reduced_motion,
		"desks": desks,
	}


## Concise assistive mirror for the pooled world-space payout markers. The
## selected dossier owns detailed history; this state describes only markers
## that are currently visible in the office.
func egg_delivery_ack_snapshot() -> Dictionary:
	var acknowledgments: Array[Dictionary] = []
	var capture_staged_count := 0
	for station in _station_list:
		if not station.egg_delivery_ack_active:
			continue
		var kind := station.egg_delivery_ack_kind
		var accessible_text := _egg_delivery_ack_accessible_text(station)
		acknowledgments.append({
			"serial": station.egg_delivery_ack_serial,
			"worker_id": station.egg_delivery_ack_worker_id,
			"worker_name": station.egg_delivery_ack_worker_name,
			"desk_index": station.index,
			"claim_id": station.egg_delivery_ack_claim_id,
			"kind": String(kind),
			"quality": String(station.egg_delivery_ack_quality),
			"cash_cents": station.egg_delivery_ack_cash_cents,
			"priority_refunded": station.egg_delivery_ack_priority_refunded,
			"shape": "crate_egg" if kind == &"stock" else "coin_up_arrow",
			"active": true,
			"animated": station.egg_delivery_ack_animated,
			"capture_staged": station.egg_delivery_ack_capture_staged,
			"accessible_text": accessible_text,
		})
		if station.egg_delivery_ack_capture_staged:
			capture_staged_count += 1
	return {
		"pooled_marker_count": _station_list.size(),
		"active_count": acknowledgments.size(),
		"capture_staged_count": capture_staged_count,
		"reduced_motion": _reduced_motion,
		"animation_speed_multiplier": _animation_speed_multiplier,
		"acknowledgments": acknowledgments,
		"last_acknowledgment": _last_egg_delivery_ack.duplicate(true),
	}


## Reuses the exact worker's desk marker. Rapid or high-speed deliveries replace
## that desk's prior transient state instead of growing the scene tree.
func play_egg_delivery_ack(
	worker_id: int,
	claim_id: int,
	quality: StringName,
	cash_cents: int,
	stocked_for_dispatch: bool,
	priority_refunded: bool,
	duration_seconds: float = EGG_DELIVERY_ACK_DURATION,
) -> bool:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null or station.egg_delivery_ack_root == null:
		return false
	if not stocked_for_dispatch and cash_cents <= 0:
		return false
	_reset_egg_delivery_ack(station)
	_egg_delivery_ack_serial += 1
	station.egg_delivery_ack_serial = _egg_delivery_ack_serial
	station.egg_delivery_ack_active = true
	station.egg_delivery_ack_animated = not _reduced_motion
	station.egg_delivery_ack_capture_staged = false
	station.egg_delivery_ack_kind = &"stock" if stocked_for_dispatch else &"cash"
	station.egg_delivery_ack_worker_id = worker_id
	station.egg_delivery_ack_worker_name = station.worker_name
	station.egg_delivery_ack_claim_id = claim_id
	station.egg_delivery_ack_quality = quality
	station.egg_delivery_ack_cash_cents = maxi(0, cash_cents)
	station.egg_delivery_ack_priority_refunded = priority_refunded
	var root := station.egg_delivery_ack_root
	var sprite := station.egg_delivery_ack_sprite
	root.visible = true
	root.position = station.egg_delivery_ack_rest_position - Vector3(0.0, 0.18, 0.0)
	root.scale = Vector3.ONE * 0.58
	root.set_meta("serial", station.egg_delivery_ack_serial)
	root.set_meta("worker_id", worker_id)
	root.set_meta("claim_id", claim_id)
	root.set_meta("kind", station.egg_delivery_ack_kind)
	root.set_meta(
		"feedback_shape",
		&"crate_egg" if stocked_for_dispatch else &"coin_up_arrow",
	)
	root.set_meta("cash_cents", station.egg_delivery_ack_cash_cents)
	root.set_meta("quality", quality)
	root.set_meta("priority_refunded", priority_refunded)
	root.set_meta("active", true)
	root.set_meta("animated", station.egg_delivery_ack_animated)
	root.set_meta("capture_staged", false)
	if sprite != null:
		sprite.texture = _egg_delivery_ack_texture(station.egg_delivery_ack_kind, quality)
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var receipt := {
		"serial": station.egg_delivery_ack_serial,
		"worker_id": worker_id,
		"worker_name": station.egg_delivery_ack_worker_name,
		"desk_index": station.index,
		"claim_id": claim_id,
		"kind": String(station.egg_delivery_ack_kind),
		"quality": String(quality),
		"cash_cents": station.egg_delivery_ack_cash_cents,
		"priority_refunded": priority_refunded,
		"shape": "crate_egg" if stocked_for_dispatch else "coin_up_arrow",
		"active": true,
		"animated": station.egg_delivery_ack_animated,
		"capture_staged": false,
		"accessible_text": _egg_delivery_ack_accessible_text(station),
	}
	_last_egg_delivery_ack = receipt.duplicate(true)
	egg_delivery_ack_presented.emit(worker_id, receipt.duplicate(true))
	if _reduced_motion:
		_hold_egg_delivery_ack_static(station, station.egg_delivery_ack_serial, duration_seconds)
		return true
	var duration := maxf(0.82, duration_seconds)
	var impact_position := station.egg_delivery_ack_rest_position + Vector3(0.0, 0.26, 0.0)
	var tween := create_tween().bind_node(root)
	station.egg_delivery_ack_tween = tween
	tween.set_speed_scale(_animation_speed_multiplier)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "scale", Vector3.ONE * 1.08, 0.18)
	if sprite != null:
		tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.10)
	tween.parallel().tween_property(root, "position", impact_position, 0.24)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(root, "scale", Vector3.ONE, 0.12)
	tween.tween_interval(maxf(0.18, duration - 0.70))
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(root, "position", impact_position + Vector3(0.0, 0.22, 0.0), 0.28)
	if sprite != null:
		tween.parallel().tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.28)
	tween.tween_callback(_finish_egg_delivery_ack.bind(station, station.egg_delivery_ack_serial))
	return true


func stage_egg_delivery_ack_capture(worker_id: int) -> bool:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null or not station.egg_delivery_ack_active:
		return false
	if station.egg_delivery_ack_tween != null and station.egg_delivery_ack_tween.is_valid():
		station.egg_delivery_ack_tween.pause()
	station.egg_delivery_ack_capture_staged = true
	station.egg_delivery_ack_root.visible = true
	station.egg_delivery_ack_root.position = (
		station.egg_delivery_ack_rest_position + Vector3(0.0, 0.26, 0.0)
	)
	station.egg_delivery_ack_root.scale = Vector3.ONE
	station.egg_delivery_ack_sprite.modulate = Color.WHITE
	station.egg_delivery_ack_root.set_meta("capture_staged", true)
	if int(_last_egg_delivery_ack.get("serial", -1)) == station.egg_delivery_ack_serial:
		_last_egg_delivery_ack["capture_staged"] = true
	return true


func egg_delivery_ack_focus_point_global(worker_id: int) -> Vector3:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null or station.egg_delivery_ack_root == null:
		return Vector3.ZERO
	return station.egg_delivery_ack_root.global_position


func _hold_egg_delivery_ack_static(
	station: StationVisual,
	serial: int,
	duration_seconds: float = EGG_DELIVERY_ACK_DURATION,
) -> void:
	if station == null or not station.egg_delivery_ack_active or station.egg_delivery_ack_serial != serial:
		return
	if station.egg_delivery_ack_tween != null and station.egg_delivery_ack_tween.is_valid():
		station.egg_delivery_ack_tween.kill()
	station.egg_delivery_ack_animated = false
	station.egg_delivery_ack_capture_staged = false
	station.egg_delivery_ack_root.visible = true
	station.egg_delivery_ack_root.position = (
		station.egg_delivery_ack_rest_position + Vector3(0.0, 0.26, 0.0)
	)
	station.egg_delivery_ack_root.scale = Vector3.ONE
	station.egg_delivery_ack_root.set_meta("animated", false)
	station.egg_delivery_ack_root.set_meta("capture_staged", false)
	if station.egg_delivery_ack_sprite != null:
		station.egg_delivery_ack_sprite.modulate = Color.WHITE
	if int(_last_egg_delivery_ack.get("serial", -1)) == serial:
		_last_egg_delivery_ack["animated"] = false
		_last_egg_delivery_ack["capture_staged"] = false
	var hold_tween := create_tween().bind_node(station.egg_delivery_ack_root)
	station.egg_delivery_ack_tween = hold_tween
	hold_tween.set_speed_scale(_animation_speed_multiplier)
	hold_tween.tween_interval(maxf(0.72, duration_seconds))
	hold_tween.tween_callback(_finish_egg_delivery_ack.bind(station, serial))


func _finish_egg_delivery_ack(station: StationVisual, serial: int) -> void:
	if station == null or station.egg_delivery_ack_serial != serial:
		return
	station.egg_delivery_ack_active = false
	station.egg_delivery_ack_animated = false
	station.egg_delivery_ack_capture_staged = false
	station.egg_delivery_ack_tween = null
	if station.egg_delivery_ack_root != null:
		station.egg_delivery_ack_root.visible = false
		station.egg_delivery_ack_root.position = station.egg_delivery_ack_rest_position
		station.egg_delivery_ack_root.scale = Vector3.ONE
		station.egg_delivery_ack_root.set_meta("active", false)
		station.egg_delivery_ack_root.set_meta("animated", false)
		station.egg_delivery_ack_root.set_meta("capture_staged", false)
	if station.egg_delivery_ack_sprite != null:
		station.egg_delivery_ack_sprite.modulate = Color.WHITE
	if int(_last_egg_delivery_ack.get("serial", -1)) == serial:
		_last_egg_delivery_ack["active"] = false
		_last_egg_delivery_ack["animated"] = false
		_last_egg_delivery_ack["capture_staged"] = false


func _reset_egg_delivery_ack(station: StationVisual) -> void:
	if station == null:
		return
	var serial := station.egg_delivery_ack_serial
	if station.egg_delivery_ack_tween != null and station.egg_delivery_ack_tween.is_valid():
		station.egg_delivery_ack_tween.kill()
	station.egg_delivery_ack_tween = null
	station.egg_delivery_ack_active = false
	station.egg_delivery_ack_animated = false
	station.egg_delivery_ack_capture_staged = false
	if station.egg_delivery_ack_root != null:
		station.egg_delivery_ack_root.visible = false
		station.egg_delivery_ack_root.position = station.egg_delivery_ack_rest_position
		station.egg_delivery_ack_root.scale = Vector3.ONE
		station.egg_delivery_ack_root.set_meta("active", false)
		station.egg_delivery_ack_root.set_meta("animated", false)
		station.egg_delivery_ack_root.set_meta("capture_staged", false)
	if station.egg_delivery_ack_sprite != null:
		station.egg_delivery_ack_sprite.modulate = Color.WHITE
	if int(_last_egg_delivery_ack.get("serial", -1)) == serial:
		_last_egg_delivery_ack["active"] = false
		_last_egg_delivery_ack["animated"] = false
		_last_egg_delivery_ack["capture_staged"] = false


func _egg_delivery_ack_accessible_text(station: StationVisual) -> String:
	if station == null:
		return ""
	if station.egg_delivery_ack_kind == &"stock":
		return "%s's previous egg entered Farmgate stock. Select this hen for detailed history." % station.egg_delivery_ack_worker_name
	return "%s's previous egg delivered $%.2f to the Feed Fund%s. Select this hen for detailed history." % [
		station.egg_delivery_ack_worker_name,
		float(station.egg_delivery_ack_cash_cents) / 100.0,
		" and restored one Priority Peck charge" if station.egg_delivery_ack_priority_refunded else "",
	]


## Live Node3D targets for pointer/touch selection. They are never serialized;
## the camera projects the physical rail itself and ignores hidden/vacant desks.
func work_progress_interaction_roots() -> Dictionary[int, Node3D]:
	var result: Dictionary[int, Node3D] = {}
	for worker_id: int in _stations_by_worker:
		var station: StationVisual = _stations_by_worker.get(worker_id)
		if station != null and station.work_progress_root != null:
			result[worker_id] = station.work_progress_root
	return result


func set_work_progress_hover(worker_id: int) -> void:
	for station in _station_list:
		station.work_progress_hovered = (
			station.worker_id == worker_id
			and station.work_progress_root != null
			and station.work_progress_root.visible
		)
		_apply_work_progress_affordance(station)


func set_work_progress_selected(worker_id: int) -> void:
	for station in _station_list:
		station.work_progress_selected = (
			station.worker_id == worker_id
			and station.work_progress_root != null
			and station.work_progress_root.visible
		)
		_apply_work_progress_affordance(station)


## Play a short, interrupt-safe quality pulse on a worker's workstation.
func pulse_completion(worker_id: int, quality: StringName) -> void:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null:
		station = _stations_by_index.get(worker_id)
	if station == null:
		return
	station.loop_stage = &"egg_released"
	station.root.set_meta("core_loop_stage", station.loop_stage)
	station.root.set_meta("last_completed_worker", station.worker_name)

	match quality:
		&"golden":
			station.completion_color = SemanticColorPaletteScript.quality_color(&"golden", _color_vision_mode)
		&"cracked":
			station.completion_color = SemanticColorPaletteScript.quality_color(&"cracked", _color_vision_mode)
		_:
			station.completion_color = SemanticColorPaletteScript.quality_color(&"sound", _color_vision_mode)

	if station.completion_tween != null and station.completion_tween.is_valid():
		station.completion_tween.kill()
	station.completion_boost = 0.0
	station.completion_tween = create_tween().bind_node(self)
	station.completion_tween.set_speed_scale(_animation_speed_multiplier)
	station.completion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	station.completion_tween.tween_property(station, "completion_boost", 1.0, 0.10)
	station.completion_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	station.completion_tween.tween_property(station, "completion_boost", 0.0, 0.72)


## A normal work contact is intentionally allocation-free. Six busy desks can
## generate several contacts per second, so the process loop decays this scalar
## and animates one cached display marker instead of constructing a Tween each
## time. Returns false when causality rejects an unattended or inactive desk.
func pulse_work_contact(worker_id: int, contact_serial: int) -> bool:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null:
		return false
	if station.state != STATE_WORKING or not station.chair_occupied:
		return false
	station.contact_boost = 1.0
	station.contact_count += 1
	station.loop_stage = &"pecking_screen"
	station.root.set_meta("core_loop_stage", station.loop_stage)
	station.root.set_meta("work_peck_contact_count", station.contact_count)
	station.root.set_meta("last_work_peck_serial", contact_serial)
	_queue_dispatch_work_handoff(station, worker_id, contact_serial)
	return true


## Stable world-space evidence point used by camera framing and regression
## tests. The point comes from the imported Screen transform, never a guessed
## office coordinate.
func screen_contact_point_global(worker_id: int) -> Vector3:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null or station.peck_contact_root == null:
		return Vector3.ZERO
	return station.peck_contact_root.global_position


## Authoritative settled folder point for cross-layer causal feedback. This is
## the marker's rest transform projected through its real parent, so callers do
## not sample the temporary pop offset from the landing tween.
func dispatch_landing_point_global(worker_id: int) -> Vector3:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null or station.dispatch_landing_root == null:
		return Vector3.ZERO
	var landing_parent := station.dispatch_landing_root.get_parent_node_3d()
	if landing_parent == null:
		return station.dispatch_landing_root.global_position
	return landing_parent.to_global(station.dispatch_landing_rest_position)


func pulse_peck_assist(worker_id: int, rating: StringName) -> void:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null:
		station = _stations_by_index.get(worker_id)
	if station == null:
		return
	station.completion_color = (
		SemanticColorPaletteScript.quality_color(&"golden", _color_vision_mode)
		if rating == &"perfect" else
		SemanticColorPaletteScript.quality_color(&"sound", _color_vision_mode)
	)
	if station.completion_tween != null and station.completion_tween.is_valid():
		station.completion_tween.kill()
	station.completion_boost = 0.0
	station.completion_tween = create_tween().bind_node(self)
	station.completion_tween.set_speed_scale(_animation_speed_multiplier)
	station.completion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for _peck in 3:
		station.completion_tween.tween_property(station, "completion_boost", 1.0, 0.07)
		station.completion_tween.tween_property(station, "completion_boost", 0.22, 0.10)
	station.completion_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	station.completion_tween.tween_property(station, "completion_boost", 0.0, 0.36)


## Sends a real 3D claim folder from the intake counter to the selected desk.
## The route is presentation-only; Office has already filed the authoritative
## assignment before this animation begins.
func play_dispatch_delivery(
	worker_id: int,
	lane: StringName,
	source_global: Vector3,
	recommended: bool = false,
	chain: int = 0,
	duration_seconds: float = 0.78,
	reward_id: StringName = &"",
	reward_receipt: Dictionary = {},
) -> bool:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null or station.root == null:
		return false
	var world_parent := get_parent() as Node3D
	if world_parent == null:
		return false
	var folder := Node3D.new()
	folder.name = "DispatchFolder_%s_%d" % [String(lane), Time.get_ticks_msec()]
	folder.set_meta("dispatch_worker_id", worker_id)
	folder.set_meta("dispatch_lane", lane)
	folder.set_meta("recommended", recommended)
	folder.set_meta("fit_chain", chain)
	folder.set_meta("routing_reward_id", reward_id)
	world_parent.add_child(folder)
	_active_dispatch_deliveries.append(folder)
	var lane_color := _lane_color(lane)
	var cover_material := _make_standard_material(lane_color.lightened(0.08), 0.78, 0.04)
	var paper_material := _make_standard_material(Color("f2ead2"), 0.94)
	var edge_material := _make_standard_material(lane_color.darkened(0.36), 0.72, 0.02)
	_add_box_mesh(folder, "FolderPaper", Vector3(0.62, 0.035, 0.42), Vector3(0.0, 0.015, 0.0), paper_material)
	_add_box_mesh(folder, "FolderCover", Vector3(0.66, 0.025, 0.44), Vector3(0.0, 0.045, 0.025), cover_material)
	_add_box_mesh(folder, "FolderTab", Vector3(0.22, 0.035, 0.11), Vector3(-0.19, 0.055, -0.245), cover_material)
	_add_box_mesh(folder, "FolderSpine", Vector3(0.035, 0.075, 0.44), Vector3(-0.33, 0.02, 0.025), edge_material)
	if recommended:
		var seal_material := _make_emissive_material(COLOR_GOLDEN, 0.52, 0.46 + mini(chain, 5) * 0.10)
		_add_cylinder_mesh(folder, "BestFitSeal", 0.095, 0.095, 0.025, Vector3(0.17, 0.075, 0.05), Vector3.ZERO, seal_material)
	folder.global_position = source_global
	folder.rotation_degrees = Vector3(-4.0, -18.0, 4.0)
	var preview_scale := 1.65 if duration_seconds > 2.0 else 1.0
	folder.scale = Vector3.ONE * 0.74 * preview_scale
	var target_global := station.root.to_global(Vector3(-0.72, 1.28, 0.20))
	var midpoint_global := source_global.lerp(target_global, 0.52) + Vector3(0.0, 2.35, 0.0)
	var duration := maxf(0.20, duration_seconds)
	var delivery_tween := create_tween().bind_node(folder)
	delivery_tween.set_speed_scale(_animation_speed_multiplier)
	delivery_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	delivery_tween.tween_property(folder, "global_position", midpoint_global, duration * 0.48)
	delivery_tween.parallel().tween_property(folder, "rotation_degrees", Vector3(6.0, 22.0, -5.0), duration * 0.48)
	delivery_tween.parallel().tween_property(folder, "scale", Vector3.ONE * (1.12 if recommended else 1.0) * preview_scale, duration * 0.30)
	delivery_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	delivery_tween.tween_property(folder, "global_position", target_global, duration * 0.52)
	delivery_tween.parallel().tween_property(folder, "rotation_degrees", Vector3(0.0, -2.0, 0.0), duration * 0.52)
	delivery_tween.parallel().tween_property(folder, "scale", Vector3.ONE * 0.90 * preview_scale, duration * 0.52)
	delivery_tween.tween_callback(
		_finish_dispatch_delivery.bind(
			folder,
			station,
			worker_id,
			lane,
			recommended,
			chain,
			reward_id,
			reward_receipt.duplicate(true),
		)
	)
	return true


func active_dispatch_delivery_count() -> int:
	var active := 0
	for folder in _active_dispatch_deliveries:
		if is_instance_valid(folder):
			active += 1
	return active


func active_dispatch_landing_count() -> int:
	var active := 0
	for station in _station_list:
		if station.dispatch_landing_active:
			active += 1
	return active


func dispatch_landing_snapshot() -> Dictionary:
	var result := _last_dispatch_landing.duplicate(true)
	var active_desks: Array[int] = []
	var work_handoff_desks: Array[int] = []
	var work_handoff_queued_count := 0
	var capture_staged_count := 0
	for station in _station_list:
		if not station.dispatch_landing_active:
			continue
		active_desks.append(station.index)
		if station.dispatch_work_handoff_active:
			work_handoff_desks.append(station.index)
		if station.dispatch_work_handoff_queued:
			work_handoff_queued_count += 1
		if (
			station.dispatch_landing_capture_staged
			or station.dispatch_work_handoff_capture_staged
		):
			capture_staged_count += 1
	result["active"] = not active_desks.is_empty()
	result["active_count"] = active_desks.size()
	result["active_desk_indices"] = active_desks
	result["capture_staged_count"] = capture_staged_count
	result["work_handoff_active_count"] = work_handoff_desks.size()
	result["work_handoff_desk_indices"] = work_handoff_desks
	result["work_handoff_queued_count"] = work_handoff_queued_count
	result["pooled_marker_count"] = _station_list.size()
	result["reduced_motion"] = _reduced_motion
	return result


## Holds the real destination receipt at its settled impact frame for browser
## capture. Runtime timing is otherwise untouched and the same pooled marker is
## resumed afterward.
func stage_dispatch_landing_capture(worker_id: int) -> bool:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null or not station.dispatch_landing_active:
		return false
	if station.dispatch_landing_tween != null and station.dispatch_landing_tween.is_valid():
		station.dispatch_landing_tween.pause()
	station.dispatch_landing_capture_staged = true
	station.dispatch_landing_root.position = station.dispatch_landing_rest_position
	station.dispatch_landing_root.scale = Vector3.ONE
	station.dispatch_landing_sprite.modulate = Color.WHITE
	station.dispatch_landing_root.set_meta("capture_staged", true)
	if int(_last_dispatch_landing.get("serial", -1)) == station.dispatch_landing_serial:
		_last_dispatch_landing["capture_staged"] = true
	return true


func release_dispatch_landing_capture(worker_id: int) -> bool:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null or not station.dispatch_landing_capture_staged:
		return false
	station.dispatch_landing_capture_staged = false
	station.dispatch_landing_root.set_meta("capture_staged", false)
	if int(_last_dispatch_landing.get("serial", -1)) == station.dispatch_landing_serial:
		_last_dispatch_landing["capture_staged"] = false
	if station.dispatch_landing_tween != null and station.dispatch_landing_tween.is_valid():
		station.dispatch_landing_tween.play()
	return true


## Holds the real first-peck transfer at the authored screen contact point. The
## same desk stamp and cached contact disc are used; capture never clones either.
func stage_dispatch_work_handoff_capture(worker_id: int) -> bool:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null:
		return false
	if (
		not station.dispatch_work_handoff_active
		and station.dispatch_landing_active
		and station.dispatch_work_handoff_queued
	):
		_settle_dispatch_landing_waiting(station, station.dispatch_landing_serial)
	if not station.dispatch_work_handoff_active:
		return false
	if station.dispatch_landing_tween != null and station.dispatch_landing_tween.is_valid():
		station.dispatch_landing_tween.pause()
	station.dispatch_work_handoff_capture_staged = true
	station.dispatch_landing_root.visible = true
	station.dispatch_landing_root.position = _dispatch_work_target_position(station)
	station.dispatch_landing_root.scale = Vector3.ONE * 0.76
	station.dispatch_landing_sprite.modulate = Color.WHITE
	station.contact_boost = 1.0
	station.dispatch_landing_root.set_meta("work_handoff_capture_staged", true)
	if int(_last_dispatch_landing.get("serial", -1)) == station.dispatch_landing_serial:
		_last_dispatch_landing["work_handoff_capture_staged"] = true
	_animate_station(station)
	return true


func release_dispatch_work_handoff_capture(worker_id: int) -> bool:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null or not station.dispatch_work_handoff_capture_staged:
		return false
	station.dispatch_work_handoff_capture_staged = false
	station.dispatch_landing_root.set_meta("work_handoff_capture_staged", false)
	if int(_last_dispatch_landing.get("serial", -1)) == station.dispatch_landing_serial:
		_last_dispatch_landing["work_handoff_capture_staged"] = false
	if station.dispatch_landing_tween != null and station.dispatch_landing_tween.is_valid():
		station.dispatch_landing_tween.play()
	return true


func finish_dispatch_landing(worker_id: int) -> bool:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null or not station.dispatch_landing_active:
		return false
	_reset_dispatch_landing(station)
	return true


func active_routing_reward_burst_count() -> int:
	var active := 0
	for burst in _active_routing_reward_bursts:
		if is_instance_valid(burst):
			active += 1
	return active


func stage_routing_reward_capture(reward_id: StringName) -> bool:
	for index in range(_active_routing_reward_bursts.size() - 1, -1, -1):
		var burst := _active_routing_reward_bursts[index]
		if (
			not is_instance_valid(burst)
			or StringName(burst.get_meta("routing_reward_id", &"")) != reward_id
		):
			continue
		var reward_tween := burst.get_meta("reward_tween", null) as Tween
		if reward_tween != null and reward_tween.is_valid():
			reward_tween.pause()
		burst.set_meta("capture_staged", true)
		return true
	return false


func routing_reward_snapshot() -> Dictionary:
	var reward_ids: Array[String] = []
	var capture_staged_count := 0
	for burst in _active_routing_reward_bursts:
		if not is_instance_valid(burst):
			continue
		reward_ids.append(String(burst.get_meta("routing_reward_id", &"")))
		if bool(burst.get_meta("capture_staged", false)):
			capture_staged_count += 1
	return {
		"active_count": reward_ids.size(),
		"reward_ids": reward_ids,
		"capture_staged_count": capture_staged_count,
	}


func play_routing_reward_burst(
	worker_id: int,
	reward_id: StringName,
	chain: int,
	duration_seconds: float = ROUTING_REWARD_DURATION,
	reward_receipt: Dictionary = {},
) -> bool:
	var station: StationVisual = _stations_by_worker.get(worker_id)
	if station == null or station.root == null or reward_id == &"":
		return false
	_play_routing_reward_burst(station, reward_id, chain, duration_seconds)
	var presented_reward := reward_receipt.duplicate(true)
	if presented_reward.is_empty():
		presented_reward["id"] = reward_id
	routing_reward_presented.emit(worker_id, presented_reward, chain)
	return true


func _finish_dispatch_delivery(
	folder: Node3D,
	station: StationVisual,
	worker_id: int,
	lane: StringName,
	recommended: bool,
	chain: int,
	reward_id: StringName,
	reward_receipt: Dictionary,
) -> void:
	_active_dispatch_deliveries.erase(folder)
	if station != null and station.root != null:
		if bool(reward_receipt.get("presentation_only", false)):
			station.root.set_meta("last_cause_replay_serial", int(reward_receipt.get("cause_replay_serial", 0)))
			station.root.set_meta("last_cause_replay_lane", lane)
			if is_instance_valid(folder):
				folder.queue_free()
			return
		station.route_boost = 1.0
		station.root.set_meta("last_manual_dispatch_lane", lane)
		station.root.set_meta("last_manual_dispatch_best_fit", recommended)
		station.root.set_meta("last_manual_dispatch_chain", chain)
		station.root.set_meta("last_routing_reward_id", reward_id)
		_play_dispatch_landing(station, worker_id, lane, recommended, chain)
		dispatch_landing_presented.emit(
			worker_id,
			_last_dispatch_landing.duplicate(true),
		)
		if reward_id != &"":
			_play_routing_reward_burst(station, reward_id, chain)
			var presented_reward := reward_receipt.duplicate(true)
			if presented_reward.is_empty():
				presented_reward["id"] = reward_id
			routing_reward_presented.emit(worker_id, presented_reward, chain)
	if is_instance_valid(folder):
		folder.queue_free()


func _play_routing_reward_burst(
	station: StationVisual,
	reward_id: StringName,
	chain: int,
	duration_seconds: float = ROUTING_REWARD_DURATION,
) -> void:
	if station == null or station.root == null:
		return
	var world_parent := get_parent() as Node3D
	if world_parent == null:
		return
	var texture := _routing_reward_texture(reward_id)
	if texture == null:
		return
	var burst := Node3D.new()
	burst.name = "RoutingReward_%s_%d" % [String(reward_id), Time.get_ticks_msec()]
	burst.set_meta("routing_reward_id", reward_id)
	burst.set_meta("fit_chain", chain)
	world_parent.add_child(burst)
	_active_routing_reward_bursts.append(burst)
	burst.global_position = station.root.to_global(Vector3(-0.72, 2.02, 0.18))
	burst.scale = Vector3.ONE * 0.42

	var icon := Sprite3D.new()
	icon.name = "RewardIcon"
	icon.texture = texture
	icon.pixel_size = 0.0115
	icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	icon.no_depth_test = true
	icon.render_priority = 24
	icon.modulate = Color(1.0, 1.0, 1.0, 0.0)
	burst.add_child(icon)

	var duration := maxf(0.72, duration_seconds)
	var rise_target := burst.global_position + Vector3(0.0, 0.72, 0.0)
	var burst_tween := create_tween().bind_node(burst)
	burst.set_meta("reward_tween", burst_tween)
	burst.set_meta("capture_staged", false)
	burst_tween.set_speed_scale(_animation_speed_multiplier)
	burst_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(burst, "scale", Vector3.ONE * 1.16, 0.18)
	burst_tween.parallel().tween_property(icon, "modulate", Color.WHITE, 0.10)
	burst_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(burst, "scale", Vector3.ONE, 0.16)
	burst_tween.parallel().tween_property(
		burst,
		"global_position",
		rise_target,
		duration - 0.34,
	)
	burst_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	burst_tween.parallel().tween_property(icon, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.34).set_delay(
		duration - 0.68
	)
	burst_tween.tween_callback(_finish_routing_reward_burst.bind(burst))


func _finish_routing_reward_burst(burst: Node3D) -> void:
	_active_routing_reward_bursts.erase(burst)
	if is_instance_valid(burst):
		burst.queue_free()


func _play_dispatch_landing(
	station: StationVisual,
	worker_id: int,
	lane: StringName,
	recommended: bool,
	chain: int,
) -> void:
	if station == null or station.dispatch_landing_root == null:
		return
	_reset_dispatch_landing(station)
	_dispatch_landing_serial += 1
	station.dispatch_landing_serial = _dispatch_landing_serial
	station.dispatch_landing_active = true
	station.dispatch_landing_animated = not _reduced_motion
	station.dispatch_landing_capture_staged = false
	station.dispatch_landing_settled = false
	station.dispatch_work_handoff_queued = false
	station.dispatch_work_handoff_active = false
	station.dispatch_work_handoff_animated = false
	station.dispatch_work_handoff_capture_staged = false
	station.dispatch_work_contact_serial = 0
	var shape: StringName = &"gold_star_stamp" if recommended else &"file_check_stamp"
	_last_dispatch_landing = {
		"serial": _dispatch_landing_serial,
		"worker_id": worker_id,
		"worker_name": station.worker_name,
		"desk_index": station.index,
		"lane": String(lane),
		"recommended": recommended,
		"fit_chain": chain,
		"shape": String(shape),
		"active": true,
		"animated": station.dispatch_landing_animated,
		"capture_staged": false,
		"phase": "filed_waiting",
		"work_started": false,
		"work_contact_serial": 0,
		"work_handoff_queued": false,
		"work_handoff_active": false,
		"work_handoff_animated": false,
		"work_handoff_capture_staged": false,
		"work_handoff_shape": "stamp_to_screen",
	}
	station.dispatch_landing_sprite.texture = _dispatch_landing_texture(
		&"best_fit" if recommended else lane,
	)
	station.dispatch_landing_root.visible = true
	station.dispatch_landing_root.set_meta("serial", _dispatch_landing_serial)
	station.dispatch_landing_root.set_meta("worker_id", worker_id)
	station.dispatch_landing_root.set_meta("lane", lane)
	station.dispatch_landing_root.set_meta("recommended", recommended)
	station.dispatch_landing_root.set_meta("fit_chain", chain)
	station.dispatch_landing_root.set_meta("feedback_shape", shape)
	station.dispatch_landing_root.set_meta("active", true)
	station.dispatch_landing_root.set_meta("animated", station.dispatch_landing_animated)
	station.dispatch_landing_root.set_meta("capture_staged", false)
	station.dispatch_landing_root.set_meta("phase", &"filed_waiting")
	station.dispatch_landing_root.set_meta("work_started", false)
	station.dispatch_landing_root.set_meta("work_handoff_shape", &"stamp_to_screen")
	if _reduced_motion:
		_hold_dispatch_landing_static(station, _dispatch_landing_serial)
		return
	station.dispatch_landing_root.position = (
		station.dispatch_landing_rest_position + Vector3(0.0, 0.26, 0.0)
	)
	station.dispatch_landing_root.scale = Vector3.ONE * 0.56
	station.dispatch_landing_sprite.modulate = Color(1.0, 1.0, 1.0, 0.30)
	var landing_tween := create_tween().bind_node(station.dispatch_landing_root)
	station.dispatch_landing_tween = landing_tween
	landing_tween.set_speed_scale(_animation_speed_multiplier)
	landing_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	landing_tween.tween_property(
		station.dispatch_landing_root,
		"position",
		station.dispatch_landing_rest_position,
		0.16,
	)
	landing_tween.parallel().tween_property(
		station.dispatch_landing_root,
		"scale",
		Vector3.ONE * 1.18,
		0.16,
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	landing_tween.parallel().tween_property(
		station.dispatch_landing_sprite,
		"modulate",
		Color.WHITE,
		0.10,
	)
	landing_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	landing_tween.tween_property(
		station.dispatch_landing_root,
		"scale",
		Vector3.ONE,
		0.14,
	)
	landing_tween.tween_interval(maxf(0.08, DISPATCH_LANDING_DURATION - 0.62))
	landing_tween.tween_callback(
		_settle_dispatch_landing_waiting.bind(station, _dispatch_landing_serial)
	)


func _hold_dispatch_landing_static(station: StationVisual, serial: int) -> void:
	if station == null or not station.dispatch_landing_active:
		return
	if station.dispatch_landing_tween != null and station.dispatch_landing_tween.is_valid():
		station.dispatch_landing_tween.kill()
	station.dispatch_landing_animated = false
	station.dispatch_landing_capture_staged = false
	station.dispatch_landing_root.visible = true
	station.dispatch_landing_root.position = station.dispatch_landing_rest_position
	station.dispatch_landing_root.scale = Vector3.ONE
	station.dispatch_landing_sprite.modulate = Color.WHITE
	station.dispatch_landing_root.set_meta("animated", false)
	station.dispatch_landing_root.set_meta("capture_staged", false)
	if int(_last_dispatch_landing.get("serial", -1)) == serial:
		_last_dispatch_landing["animated"] = false
		_last_dispatch_landing["capture_staged"] = false
	_settle_dispatch_landing_waiting(station, serial)


func _settle_dispatch_landing_waiting(station: StationVisual, serial: int) -> void:
	if (
		station == null
		or station.dispatch_landing_serial != serial
		or not station.dispatch_landing_active
	):
		return
	station.dispatch_landing_tween = null
	station.dispatch_landing_settled = true
	station.dispatch_landing_root.visible = true
	station.dispatch_landing_root.position = station.dispatch_landing_rest_position
	station.dispatch_landing_root.scale = Vector3.ONE
	station.dispatch_landing_sprite.modulate = Color.WHITE
	station.dispatch_landing_root.set_meta("phase", &"filed_waiting")
	if station.dispatch_work_handoff_queued:
		_start_dispatch_work_handoff(station, serial)


func _queue_dispatch_work_handoff(
	station: StationVisual,
	worker_id: int,
	contact_serial: int,
) -> bool:
	if (
		station == null
		or not station.dispatch_landing_active
		or station.dispatch_work_handoff_queued
		or station.dispatch_work_handoff_active
	):
		return false
	station.dispatch_work_handoff_queued = true
	station.dispatch_work_contact_serial = contact_serial
	station.dispatch_landing_root.set_meta("work_contact_serial", contact_serial)
	station.dispatch_landing_root.set_meta("work_handoff_queued", true)
	if int(_last_dispatch_landing.get("serial", -1)) == station.dispatch_landing_serial:
		_last_dispatch_landing["worker_id"] = worker_id
		_last_dispatch_landing["work_contact_serial"] = contact_serial
		_last_dispatch_landing["work_handoff_queued"] = true
		_last_dispatch_landing["phase"] = "work_contact_queued"
	if station.dispatch_landing_settled:
		_start_dispatch_work_handoff(station, station.dispatch_landing_serial)
	return true


func _start_dispatch_work_handoff(station: StationVisual, serial: int) -> void:
	if (
		station == null
		or station.dispatch_landing_serial != serial
		or not station.dispatch_landing_active
		or not station.dispatch_work_handoff_queued
		or station.dispatch_work_handoff_active
	):
		return
	if station.dispatch_landing_tween != null and station.dispatch_landing_tween.is_valid():
		station.dispatch_landing_tween.kill()
	station.dispatch_landing_tween = null
	station.dispatch_work_handoff_active = true
	station.dispatch_work_handoff_animated = not _reduced_motion
	station.dispatch_work_handoff_capture_staged = false
	station.dispatch_landing_capture_staged = false
	station.dispatch_landing_root.set_meta("phase", &"work_started")
	station.dispatch_landing_root.set_meta("work_started", true)
	station.dispatch_landing_root.set_meta("work_handoff_active", true)
	station.dispatch_landing_root.set_meta(
		"work_handoff_animated",
		station.dispatch_work_handoff_animated,
	)
	station.dispatch_landing_root.set_meta("work_handoff_capture_staged", false)
	if int(_last_dispatch_landing.get("serial", -1)) == serial:
		_last_dispatch_landing["phase"] = "work_started"
		_last_dispatch_landing["work_started"] = true
		_last_dispatch_landing["work_handoff_active"] = true
		_last_dispatch_landing["work_handoff_animated"] = (
			station.dispatch_work_handoff_animated
		)
		_last_dispatch_landing["work_handoff_capture_staged"] = false
	dispatch_work_started_presented.emit(
		int(_last_dispatch_landing.get("worker_id", -1)),
		_last_dispatch_landing.duplicate(true),
	)
	if _reduced_motion:
		_hold_dispatch_work_handoff_static(station, serial)
		return
	var target_position := _dispatch_work_target_position(station)
	var handoff_tween := create_tween().bind_node(station.dispatch_landing_root)
	station.dispatch_landing_tween = handoff_tween
	handoff_tween.set_speed_scale(_animation_speed_multiplier)
	handoff_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	handoff_tween.tween_property(
		station.dispatch_landing_root,
		"position",
		target_position,
		DISPATCH_WORK_HANDOFF_DURATION * 0.70,
	)
	handoff_tween.parallel().tween_property(
		station.dispatch_landing_root,
		"scale",
		Vector3.ONE * 0.70,
		DISPATCH_WORK_HANDOFF_DURATION * 0.70,
	)
	handoff_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	handoff_tween.tween_property(
		station.dispatch_landing_sprite,
		"modulate",
		Color(1.0, 1.0, 1.0, 0.0),
		DISPATCH_WORK_HANDOFF_DURATION * 0.30,
	)
	handoff_tween.parallel().tween_property(
		station.dispatch_landing_root,
		"scale",
		Vector3.ONE * 0.42,
		DISPATCH_WORK_HANDOFF_DURATION * 0.30,
	)
	handoff_tween.tween_callback(_finish_dispatch_work_handoff.bind(station, serial))


func _hold_dispatch_work_handoff_static(station: StationVisual, serial: int) -> void:
	if (
		station == null
		or station.dispatch_landing_serial != serial
		or not station.dispatch_work_handoff_active
	):
		return
	if station.dispatch_landing_tween != null and station.dispatch_landing_tween.is_valid():
		station.dispatch_landing_tween.kill()
	station.dispatch_work_handoff_animated = false
	station.dispatch_work_handoff_capture_staged = false
	station.dispatch_landing_root.visible = true
	station.dispatch_landing_root.position = _dispatch_work_target_position(station)
	station.dispatch_landing_root.scale = Vector3.ONE * 0.76
	station.dispatch_landing_sprite.modulate = Color.WHITE
	station.dispatch_landing_root.set_meta("work_handoff_animated", false)
	station.dispatch_landing_root.set_meta("work_handoff_capture_staged", false)
	if int(_last_dispatch_landing.get("serial", -1)) == serial:
		_last_dispatch_landing["work_handoff_animated"] = false
		_last_dispatch_landing["work_handoff_capture_staged"] = false
	var hold_tween := create_tween().bind_node(station.dispatch_landing_root)
	station.dispatch_landing_tween = hold_tween
	hold_tween.set_speed_scale(_animation_speed_multiplier)
	hold_tween.tween_interval(DISPATCH_WORK_HANDOFF_DURATION)
	hold_tween.tween_callback(_finish_dispatch_work_handoff.bind(station, serial))


func _dispatch_work_target_position(station: StationVisual) -> Vector3:
	if station == null or station.root == null or station.peck_contact_root == null:
		return station.dispatch_landing_rest_position if station != null else Vector3.ZERO
	return station.root.to_local(station.peck_contact_root.global_position)


func _finish_dispatch_work_handoff(station: StationVisual, serial: int) -> void:
	if station == null or station.dispatch_landing_serial != serial:
		return
	if int(_last_dispatch_landing.get("serial", -1)) == serial:
		_last_dispatch_landing["phase"] = "work_started_settled"
		_last_dispatch_landing["work_handoff_active"] = false
		_last_dispatch_landing["work_handoff_capture_staged"] = false
	_finish_dispatch_landing(station, serial)


func _finish_dispatch_landing(station: StationVisual, serial: int) -> void:
	if station == null or station.dispatch_landing_serial != serial:
		return
	station.dispatch_landing_tween = null
	station.dispatch_landing_active = false
	station.dispatch_landing_capture_staged = false
	station.dispatch_landing_settled = false
	station.dispatch_work_handoff_queued = false
	station.dispatch_work_handoff_active = false
	station.dispatch_work_handoff_animated = false
	station.dispatch_work_handoff_capture_staged = false
	if station.dispatch_landing_root != null:
		station.dispatch_landing_root.visible = false
		station.dispatch_landing_root.position = station.dispatch_landing_rest_position
		station.dispatch_landing_root.scale = Vector3.ONE
		station.dispatch_landing_root.set_meta("active", false)
		station.dispatch_landing_root.set_meta("capture_staged", false)
		station.dispatch_landing_root.set_meta("work_handoff_queued", false)
		station.dispatch_landing_root.set_meta("work_handoff_active", false)
		station.dispatch_landing_root.set_meta("work_handoff_capture_staged", false)
	if station.dispatch_landing_sprite != null:
		station.dispatch_landing_sprite.modulate = Color.WHITE
	if int(_last_dispatch_landing.get("serial", -1)) == serial:
		_last_dispatch_landing["active"] = false
		_last_dispatch_landing["capture_staged"] = false


func _reset_dispatch_landing(station: StationVisual) -> void:
	if station == null:
		return
	var serial := station.dispatch_landing_serial
	if station.dispatch_landing_tween != null and station.dispatch_landing_tween.is_valid():
		station.dispatch_landing_tween.kill()
	station.dispatch_landing_tween = null
	station.dispatch_landing_active = false
	station.dispatch_landing_animated = false
	station.dispatch_landing_capture_staged = false
	station.dispatch_landing_settled = false
	station.dispatch_work_handoff_queued = false
	station.dispatch_work_handoff_active = false
	station.dispatch_work_handoff_animated = false
	station.dispatch_work_handoff_capture_staged = false
	station.dispatch_work_contact_serial = 0
	if station.dispatch_landing_root != null:
		station.dispatch_landing_root.visible = false
		station.dispatch_landing_root.position = station.dispatch_landing_rest_position
		station.dispatch_landing_root.scale = Vector3.ONE
		station.dispatch_landing_root.set_meta("active", false)
		station.dispatch_landing_root.set_meta("animated", false)
		station.dispatch_landing_root.set_meta("capture_staged", false)
		station.dispatch_landing_root.set_meta("work_started", false)
		station.dispatch_landing_root.set_meta("work_handoff_queued", false)
		station.dispatch_landing_root.set_meta("work_handoff_active", false)
		station.dispatch_landing_root.set_meta("work_handoff_animated", false)
		station.dispatch_landing_root.set_meta("work_handoff_capture_staged", false)
	if station.dispatch_landing_sprite != null:
		station.dispatch_landing_sprite.modulate = Color.WHITE
	if int(_last_dispatch_landing.get("serial", -1)) == serial:
		_last_dispatch_landing["active"] = false
		_last_dispatch_landing["animated"] = false
		_last_dispatch_landing["capture_staged"] = false


func _dispatch_landing_texture(kind: StringName) -> Texture2D:
	var cache_key := (
		&"best_fit"
		if kind == &"best_fit" else
		StringName("%s:%s" % [String(kind), String(_color_vision_mode)])
	)
	if _dispatch_landing_texture_cache.has(cache_key):
		return _dispatch_landing_texture_cache[cache_key]
	var fill := "d6ad4d"
	var symbol := "M32 8 L39 23 L56 25 L44 37 L47 54 L32 46 L17 54 L20 37 L8 25 L25 23 Z"
	if kind != &"best_fit":
		fill = _lane_color(kind).to_html(false)
		# A filed-page outline plus heavy check stays distinct from the star even
		# when color vision or a monochrome capture removes the lane hue.
		symbol = "M15 9 H42 L52 19 V55 H15 Z M42 9 V20 H52 M22 37 L29 44 L45 27 L50 32 L29 53 L17 42 Z"
	var svg := (
		"<svg xmlns='http://www.w3.org/2000/svg' width='72' height='72' viewBox='0 0 64 64'>"
		+ "<circle cx='32' cy='32' r='29' fill='#101a21' fill-opacity='.96' stroke='#fff0b8' stroke-width='3'/>"
		+ "<circle cx='32' cy='32' r='23' fill='#%s'/>" % fill
		+ "<path d='%s' fill='#fff9df' fill-rule='evenodd'/>" % symbol
		+ "</svg>"
	)
	var image := Image.new()
	if image.load_svg_from_string(svg, 1.0) != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_dispatch_landing_texture_cache[cache_key] = texture
	return texture


func _routing_reward_texture(reward_id: StringName) -> Texture2D:
	if _routing_reward_texture_cache.has(reward_id):
		return _routing_reward_texture_cache[reward_id]
	var fill := "e4b94f"
	var symbol := "M36 7 L18 35 H30 L25 57 L48 27 H35 Z"
	match reward_id:
		&"peck_recharge":
			fill = "5cb9aa"
			symbol = "M17 12 H47 V24 H41 L39 34 H25 L23 24 H17 Z M14 39 H50 V53 H14 Z"
		&"golden_file":
			fill = "e6bd4b"
			symbol = "M32 8 C22 8 15 25 15 39 C15 51 22 57 32 57 C42 57 49 51 49 39 C49 25 42 8 32 8 Z"
		&"team_lift":
			fill = "cf7184"
			symbol = "M32 55 L12 35 C2 22 11 8 23 12 C28 14 31 19 32 22 C33 19 36 14 41 12 C53 8 62 22 52 35 Z"
		&"mastery_record":
			fill = "58a99b"
			# A medal with split tails remains distinct from the Golden File egg,
			# Team Lift heart, and Priority Peck folder at overview scale.
			symbol = "M32 8 L39 19 L52 20 L45 31 L48 44 L32 38 L16 44 L19 31 L12 20 L25 19 Z M22 40 L29 43 L25 58 L17 51 Z M42 40 L35 43 L39 58 L47 51 Z"
		&"pace":
			fill = "d7aa43"
		_:
			return null
	var svg := (
		"<svg xmlns='http://www.w3.org/2000/svg' width='72' height='72' viewBox='0 0 64 64'>"
		+ "<circle cx='32' cy='32' r='29' fill='#101a21' fill-opacity='.96' stroke='#fff0b8' stroke-width='3'/>"
		+ "<circle cx='32' cy='32' r='23' fill='#%s'/>" % fill
		+ "<path d='%s' fill='#fff9df' fill-rule='evenodd'/>" % symbol
		+ "</svg>"
	)
	var image := Image.new()
	if image.load_svg_from_string(svg, 1.0) != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_routing_reward_texture_cache[reward_id] = texture
	return texture


func _egg_delivery_ack_texture(kind: StringName, quality: StringName) -> Texture2D:
	var cache_key := StringName("%s:%s:%s" % [
		String(kind), String(quality), String(_color_vision_mode),
	])
	if _egg_delivery_ack_texture_cache.has(cache_key):
		return _egg_delivery_ack_texture_cache[cache_key]
	var fill := SemanticColorPaletteScript.quality_color(quality, _color_vision_mode).to_html(false)
	# A benefit coin with an inset plus and a heavy upward arrow communicates
	# credited cash without a currency glyph, number, or language abbreviation.
	var symbol := "M27 29 V16 L21 22 L16 17 L32 3 L48 17 L43 22 L37 16 V29 Z"
	var detail_svg := (
		"<circle cx='32' cy='46' r='12' fill='#fff9df' stroke='#101a21' stroke-width='1.2'/>"
		+ "<path d='M32 34 V58 M39 39 C36 35 26 36 25 41 C24 46 39 44 39 50 C38 56 27 56 24 52' fill='none' stroke='#101a21' stroke-width='3.4' stroke-linecap='round' stroke-linejoin='round'/>"
	)
	if kind == &"stock":
		fill = SemanticColorPaletteScript.quality_color(quality, _color_vision_mode).to_html(false)
		# A pitched crate around an egg remains distinct from the cash arrow even
		# in monochrome and means the value is inventory, not current Feed Fund.
		symbol = (
			"M10 31 L32 20 L54 31 V55 H10 Z M10 31 H54 M22 27 V55 M42 27 V55 "
			+ "M32 7 C26 7 22 15 22 21 C22 27 26 30 32 30 C38 30 42 27 42 21 C42 15 38 7 32 7 Z"
		)
		detail_svg = ""
	var svg := (
		"<svg xmlns='http://www.w3.org/2000/svg' width='72' height='72' viewBox='0 0 64 64'>"
		+ "<circle cx='32' cy='32' r='29' fill='#101a21' fill-opacity='.96' stroke='#fff0b8' stroke-width='3'/>"
		+ "<circle cx='32' cy='32' r='23' fill='#%s'/>" % fill
		+ "<path d='%s' fill='#fff9df' fill-rule='evenodd' stroke='#101a21' stroke-width='1.2' stroke-linejoin='round'/>" % symbol
		+ detail_svg
		+ "</svg>"
	)
	var image := Image.new()
	if image.load_svg_from_string(svg, 1.0) != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_egg_delivery_ack_texture_cache[cache_key] = texture
	return texture


func _clear_cached_stations() -> void:
	for folder in _active_dispatch_deliveries:
		if is_instance_valid(folder):
			folder.queue_free()
	_active_dispatch_deliveries.clear()
	for burst in _active_routing_reward_bursts:
		if is_instance_valid(burst):
			burst.queue_free()
	_active_routing_reward_bursts.clear()
	for station in _station_list:
		_reset_egg_delivery_ack(station)
		_reset_dispatch_landing(station)
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
	_last_dispatch_landing.clear()
	_last_egg_delivery_ack.clear()
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
	_build_core_loop_props(station)
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
	station.root.set_meta("core_loop_stage", station.loop_stage)
	return station


func _build_core_loop_props(station: StationVisual) -> void:
	if station.root == null or station.screens.is_empty():
		return
	var screen := station.screens[0]
	station.peck_contact_root = _new_runtime_root("ScreenPeckContact", screen)
	# The flattened emissive sphere reads as a soft point of impact from both
	# sides of the monitor and inherits the exact authored Screen transform.
	station.peck_contact_root.position = Vector3(0.0, 0.0, 0.022)
	station.peck_contact_disc = MeshInstance3D.new()
	station.peck_contact_disc.name = "ScreenPeckContactDisc"
	var disc_mesh := SphereMesh.new()
	disc_mesh.radius = 0.50
	disc_mesh.height = 1.0
	disc_mesh.radial_segments = 12
	disc_mesh.rings = 6
	station.peck_contact_disc.mesh = disc_mesh
	station.peck_contact_disc.scale = Vector3(0.16, 0.16, 0.025)
	station.peck_contact_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	station.peck_contact_material = _make_emissive_material(Color("f7d878"), 0.0, 0.26)
	station.peck_contact_disc.material_override = station.peck_contact_material
	station.peck_contact_root.add_child(station.peck_contact_disc)
	station.peck_contact_root.visible = false

	station.pace_flow_root = _new_runtime_root("RoutingPaceFlow", station.root)
	station.pace_flow_root.set_meta("feedback_shape", &"double_chevron")
	station.pace_flow_root.set_meta("view_sides", 2)
	station.pace_flow_material = _make_emissive_material(COLOR_ROUTING_PACE, 0.82, 0.24)
	# Two joined chevrons communicate throughput without a word or another
	# floating badge. One lives on the employee-facing monitor; its matching
	# management lamp sits on the authored cubicle back beside the paper memos.
	# Both remain physical parts of the workstation and share one cached state.
	for face_index in 2:
		var face_root := Node3D.new()
		face_root.name = "PaceWorkerFace" if face_index == 0 else "PaceManagerFace"
		face_root.position = (
			Vector3(0.22, 1.38, -0.065)
			if face_index == 0
			else Vector3(0.56, 1.44, 0.785)
		)
		if face_index == 1:
			# The outer cubicle face is viewed from +Z, opposite the worker's
			# monitor face. Flip it so both viewpoints read forward motion.
			face_root.rotation.y = PI
		station.pace_flow_root.add_child(face_root)
		for chevron_index in 2:
			var chevron_x := -0.10 + chevron_index * 0.18
			var upper := _add_box_mesh(
				face_root,
				"PaceChevron_%d_Upper" % chevron_index,
				Vector3(0.038, 0.18, 0.018),
				Vector3(chevron_x, 0.058, 0.0),
				station.pace_flow_material,
			)
			upper.rotation.z = -PI * 0.25
			var lower := _add_box_mesh(
				face_root,
				"PaceChevron_%d_Lower" % chevron_index,
				Vector3(0.038, 0.18, 0.018),
				Vector3(chevron_x, -0.058, 0.0),
				station.pace_flow_material,
			)
			lower.rotation.z = PI * 0.25
	station.pace_flow_root.visible = false
	_build_work_progress_rail(station)


func _build_work_progress_rail(station: StationVisual) -> void:
	if station.root == null:
		return
	station.work_progress_root = _new_runtime_root("WorkProgressRail", station.root)
	station.work_progress_root.position = Vector3(-0.22, 1.29, 0.795)
	station.work_progress_root.rotation.y = PI
	station.work_progress_root.set_meta("feedback_shape", &"segmented_rail")
	station.work_progress_root.set_meta("pip_count", WORK_PROGRESS_PIP_COUNT)
	station.work_progress_root.set_meta("view_side", &"management")
	var backplate_material := _make_standard_material(COLOR_HARDWARE_DARK.darkened(0.18), 0.72, 0.08)
	_add_box_mesh(
		station.work_progress_root,
		"ProgressRailBackplate",
		Vector3(0.72, 0.20, 0.035),
		Vector3.ZERO,
		backplate_material,
	)
	station.work_progress_active_material = _make_emissive_material(COLOR_WORKING, 0.92, 0.28)
	station.work_progress_inactive_material = _make_emissive_material(COLOR_LINE_OFF, 0.16, 0.54)
	station.work_progress_warning_material = _make_emissive_material(COLOR_ALERT, 1.18, 0.30)
	for pip_index in WORK_PROGRESS_PIP_COUNT:
		var pip := _add_box_mesh(
			station.work_progress_root,
			"ProgressPip_%d" % pip_index,
			Vector3(0.095, 0.075, 0.026),
			Vector3(-0.245 + pip_index * 0.122, 0.0, -0.026),
			station.work_progress_inactive_material,
		)
		pip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		station.work_progress_pips.append(pip)

	# A double bar is a familiar, non-text pause shape. The deadline-risk
	# diamond carries an inset exclamation silhouette, so neither depends on red.
	station.work_progress_pause_root = _new_runtime_root("ProgressPausedShape", station.work_progress_root)
	for side in [-1, 1]:
		_add_box_mesh(
			station.work_progress_pause_root,
			"PauseBar_%d" % side,
			Vector3(0.038, 0.12, 0.030),
			Vector3(0.315 + side * 0.032, 0.0, -0.032),
			station.work_progress_active_material,
		)
	station.work_progress_pause_root.visible = false
	station.work_progress_risk_root = _new_runtime_root("ProgressDeadlineRiskShape", station.work_progress_root)
	var risk_diamond := _add_box_mesh(
		station.work_progress_risk_root,
		"DeadlineRiskDiamond",
		Vector3(0.125, 0.125, 0.028),
		Vector3(0.315, 0.0, -0.032),
		station.work_progress_warning_material,
	)
	risk_diamond.rotation.z = PI * 0.25
	_add_box_mesh(
		station.work_progress_risk_root,
		"DeadlineRiskStem",
		Vector3(0.022, 0.054, 0.032),
		Vector3(0.315, 0.014, -0.050),
		backplate_material,
	)
	_add_box_mesh(
		station.work_progress_risk_root,
		"DeadlineRiskDot",
		Vector3(0.024, 0.020, 0.032),
		Vector3(0.315, -0.030, -0.050),
		backplate_material,
	)
	station.work_progress_risk_root.visible = false
	station.work_progress_affordance_root = _new_runtime_root(
		"ProgressInteractionAffordance",
		station.work_progress_root,
	)
	station.work_progress_affordance_material = _make_emissive_material(
		COLOR_ROUTING_PACE,
		1.10,
		0.22,
	)
	for side in [-1, 1]:
		var side_x := float(side) * 0.385
		var vertical := _add_box_mesh(
			station.work_progress_affordance_root,
			"AffordanceSide_%d" % side,
			Vector3(0.020, 0.245, 0.022),
			Vector3(side_x, 0.0, -0.045),
			station.work_progress_affordance_material,
		)
		vertical.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for edge in [-1, 1]:
			var corner := _add_box_mesh(
				station.work_progress_affordance_root,
				"AffordanceCorner_%d_%d" % [side, edge],
				Vector3(0.080, 0.020, 0.022),
				Vector3(side_x - float(side) * 0.030, float(edge) * 0.112, -0.045),
				station.work_progress_affordance_material,
			)
			corner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	station.work_progress_affordance_root.visible = false
	station.work_progress_root.visible = false


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
	peck_assist_ready: bool = false,
	specialty_match: bool = false,
	golden_file_target: bool = false,
) -> void:
	station.state = state
	station.progress = progress
	station.stress = stress
	station.chair_occupied = at_workstation
	station.current_lane = lane
	station.peck_assist_ready = peck_assist_ready
	station.specialty_match = specialty_match
	station.golden_file_target = golden_file_target
	station.pace_active = (
		_routing_pace_active
		and state == STATE_WORKING
		and at_workstation
	)
	station.root.set_meta("specialty_match", specialty_match)
	station.root.set_meta("routing_golden_target", golden_file_target)
	station.root.set_meta("routing_golden_claim_id", station.current_claim_id if golden_file_target else -1)
	station.root.set_meta("routing_pace_active", station.pace_active)
	station.root.set_meta(
		"routing_pace_multiplier",
		_routing_pace_multiplier if station.pace_active else 1.0,
	)
	station.root.set_meta("routing_pace_shape", &"double_chevron" if station.pace_active else &"")
	if station.completion_boost <= 0.05:
		if state == STATE_LAYING and at_workstation:
			station.loop_stage = &"laying_egg"
		elif state == STATE_WORKING and at_workstation:
			station.loop_stage = &"pecking_screen"
		elif station.current_claim_id >= 0:
			station.loop_stage = &"file_paused"
		else:
			station.loop_stage = &"waiting_file"
		station.root.set_meta("core_loop_stage", station.loop_stage)
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
	if station.golden_file_seal != null:
		station.golden_file_seal.visible = golden_file_target

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
	_apply_work_progress_visual(station)


func _apply_work_progress_visual(station: StationVisual) -> void:
	if station.work_progress_root == null:
		return
	if station.current_claim_id < 0:
		station.work_progress_status = &"hidden"
	elif station.claim_overdue or station.minutes_until_deadline <= WORK_DEADLINE_RISK_MINUTES:
		station.work_progress_status = &"deadline_risk"
	elif station.state != STATE_WORKING or not station.chair_occupied:
		station.work_progress_status = &"paused"
	else:
		station.work_progress_status = &"working"
	var visible := station.work_progress_status != &"hidden"
	if not visible:
		station.work_progress_hovered = false
		station.work_progress_selected = false
	station.work_progress_root.visible = visible
	station.work_progress_root.set_meta("status", station.work_progress_status)
	station.work_progress_root.set_meta("status_shape", _work_progress_shape(station.work_progress_status))
	station.work_progress_root.set_meta("claim_id", station.current_claim_id)
	station.work_progress_root.set_meta("progress", station.progress)
	station.work_progress_root.set_meta("minutes_until_deadline", station.minutes_until_deadline)
	station.work_progress_root.set_meta("overdue", station.claim_overdue)
	station.work_progress_root.set_meta("rework", station.claim_is_rework)
	station.work_progress_active_material.albedo_color = station.base_color.lightened(0.08)
	station.work_progress_active_material.emission = station.base_color.lightened(0.30)
	var warning_color := SemanticColorPaletteScript.quality_color(&"cracked", _color_vision_mode)
	station.work_progress_warning_material.albedo_color = warning_color.darkened(0.34)
	station.work_progress_warning_material.emission = warning_color.lightened(0.08)
	var filled_pips := clampi(
		ceili(station.progress * float(WORK_PROGRESS_PIP_COUNT) / 100.0),
		0,
		WORK_PROGRESS_PIP_COUNT,
	)
	station.work_progress_root.set_meta("filled_pips", filled_pips)
	for pip_index in station.work_progress_pips.size():
		if pip_index >= filled_pips:
			station.work_progress_pips[pip_index].material_override = station.work_progress_inactive_material
		elif station.work_progress_status == &"deadline_risk":
			station.work_progress_pips[pip_index].material_override = station.work_progress_warning_material
		else:
			station.work_progress_pips[pip_index].material_override = station.work_progress_active_material
	if station.work_progress_pause_root != null:
		station.work_progress_pause_root.visible = station.work_progress_status == &"paused"
	if station.work_progress_risk_root != null:
		station.work_progress_risk_root.visible = station.work_progress_status == &"deadline_risk"
	_apply_work_progress_affordance(station)


func _apply_work_progress_affordance(station: StationVisual) -> void:
	if station.work_progress_affordance_root == null:
		return
	var visible := (
		station.work_progress_root != null
		and station.work_progress_root.visible
		and (station.work_progress_hovered or station.work_progress_selected)
	)
	station.work_progress_affordance_root.visible = visible
	station.work_progress_affordance_root.set_meta("hovered", station.work_progress_hovered)
	station.work_progress_affordance_root.set_meta("selected", station.work_progress_selected)
	station.work_progress_affordance_root.set_meta("shape", &"corner_brackets")
	station.work_progress_affordance_root.scale = (
		Vector3.ONE * 1.055 if station.work_progress_hovered else Vector3.ONE
	)
	if station.work_progress_affordance_material != null:
		station.work_progress_affordance_material.emission_energy_multiplier = (
			1.85 if station.work_progress_hovered else 1.20
		)


func _work_progress_shape(status: StringName) -> String:
	match status:
		&"paused":
			return "segmented_rail+pause_bars"
		&"deadline_risk":
			return "segmented_rail+warning_diamond"
		&"working":
			return "segmented_rail"
		_:
			return "hidden"


func _animate_station(station: StationVisual) -> void:
	if station.screen_material == null:
		return

	var slow_pulse := sin(_phase * 2.2 + station.phase_offset) * 0.07
	var fine_flicker := sin(_phase * 13.0 + station.phase_offset * 1.7) * 0.018
	var stress_flicker := fine_flicker * remap(station.stress, 0.0, 100.0, 0.35, 1.35)
	var completion_mix := clampf(station.completion_boost, 0.0, 1.0)
	var display_color := station.base_color.lerp(station.completion_color, completion_mix)
	if station.specialty_match and station.state == STATE_WORKING:
		display_color = display_color.lerp(
			SemanticColorPaletteScript.quality_color(&"golden", _color_vision_mode),
			0.24,
		)
	if station.peck_assist_ready:
		var ready_mix := 0.34 + maxf(0.0, sin(_phase * 5.6 + station.phase_offset)) * 0.24
		display_color = display_color.lerp(
			SemanticColorPaletteScript.quality_color(&"golden", _color_vision_mode),
			ready_mix,
		)
	var work_energy := 1.00 if station.state == STATE_WORKING else 0.72
	if station.state == STATE_LAYING:
		work_energy = 1.22
	elif station.state == STATE_BREAK:
		work_energy = 0.52

	station.screen_material.emission = display_color
	station.header_material.emission = display_color.lightened(0.17)
	station.line_active_material.emission = display_color.lightened(0.25)
	station.screen_material.emission_energy_multiplier = maxf(0.18, work_energy + slow_pulse + stress_flicker + completion_mix * 1.25)
	station.header_material.emission_energy_multiplier = maxf(
		0.18,
		work_energy + slow_pulse * 0.55 + completion_mix * 1.55
		+ (0.34 if station.specialty_match and station.state == STATE_WORKING else 0.0),
	)
	station.line_active_material.emission_energy_multiplier = 1.10 + slow_pulse * 0.45 + completion_mix * 1.20
	if station.work_progress_active_material != null:
		station.work_progress_active_material.emission_energy_multiplier = (
			1.18 if _reduced_motion else 1.18 + maxf(0.0, slow_pulse) * 2.2
		)
	if station.work_progress_warning_material != null:
		station.work_progress_warning_material.emission_energy_multiplier = (
			1.18 if _reduced_motion else 1.18 + maxf(0.0, sin(_phase * 4.6 + station.phase_offset)) * 0.72
		)
	if (
		station.work_progress_affordance_root != null
		and station.work_progress_affordance_root.visible
		and station.work_progress_affordance_material != null
	):
		var hover_pulse := maxf(0.0, sin(_phase * 5.2 + station.phase_offset))
		station.work_progress_affordance_root.scale = (
			Vector3.ONE * (1.055 + hover_pulse * 0.035)
			if station.work_progress_hovered and not _reduced_motion else
			Vector3.ONE
		)
		station.work_progress_affordance_material.emission_energy_multiplier = (
			1.85 + hover_pulse * 0.55
			if station.work_progress_hovered and not _reduced_motion else
			1.45 if station.work_progress_hovered else 1.20
		)
	if station.peck_contact_root != null and station.peck_contact_material != null:
		var contact_mix := clampf(station.contact_boost, 0.0, 1.0)
		station.peck_contact_root.visible = (
			contact_mix > 0.015
			and station.state == STATE_WORKING
			and station.chair_occupied
		)
		station.peck_contact_root.scale = Vector3.ONE * lerpf(0.52, 1.18, contact_mix)
		station.peck_contact_material.emission = display_color.lightened(0.34)
		station.peck_contact_material.emission_energy_multiplier = 0.25 + contact_mix * 3.35
	if station.pace_flow_root != null and station.pace_flow_material != null:
		station.pace_flow_root.visible = station.pace_active
		station.pace_flow_root.set_meta("active", station.pace_active)
		station.pace_flow_root.set_meta("reduced_motion", _reduced_motion)
		if station.pace_active:
			var flow_phase := sin(_phase * 3.8 + station.phase_offset)
			station.pace_flow_root.position.x = 0.0 if _reduced_motion else flow_phase * 0.018
			station.pace_flow_root.scale = Vector3.ONE if _reduced_motion else Vector3.ONE * (1.0 + maxf(0.0, flow_phase) * 0.06)
			station.pace_flow_material.emission = COLOR_ROUTING_PACE
			station.pace_flow_material.emission_energy_multiplier = (
				1.08 if _reduced_motion else 1.05 + maxf(0.0, flow_phase) * 0.72
			)
		else:
			station.pace_flow_root.position.x = 0.0
			station.pace_flow_root.scale = Vector3.ONE

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
		var route_lift := station.route_boost * (0.14 if paper_index == 0 else 0.025)
		paper.position.y = rest_y + route_lift + sin(_phase * 1.35 + station.phase_offset + paper_index * 0.7) * 0.006
		paper.scale = Vector3.ONE * (1.0 + station.route_boost * (0.10 if paper_index == 0 else 0.02))
	if station.stress_notice != null and station.stress_notice.visible:
		station.stress_notice.rotation.z = sin(_phase * 3.8 + station.phase_offset) * 0.025
	if station.golden_file_seal != null and station.golden_file_seal.visible:
		var seal_pulse := 1.0 if _reduced_motion else 1.0 + maxf(0.0, sin(_phase * 3.2 + station.phase_offset)) * 0.10
		station.golden_file_seal.scale = Vector3.ONE * seal_pulse
		station.golden_file_seal_material.emission_energy_multiplier = (
			1.05 if _reduced_motion else 1.05 + maxf(0.0, sin(_phase * 3.2 + station.phase_offset)) * 0.55
		)
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
		paper.mesh = ProceduralPrimitiveCache.box(Vector3(0.48, 0.018, 0.34))
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

	# One cached destination stamp completes the intake -> hen -> desk gesture.
	# It is attached to the authored claim tray, collision-free, and reused for
	# every route so rapid filing never grows the scene tree.
	station.dispatch_landing_root = _new_runtime_root(
		"DispatchLandingReceipt",
		station.root,
	)
	station.dispatch_landing_rest_position = tray_position + Vector3(0.0, 0.42, 0.0)
	station.dispatch_landing_root.position = station.dispatch_landing_rest_position
	station.dispatch_landing_root.visible = false
	station.dispatch_landing_sprite = Sprite3D.new()
	station.dispatch_landing_sprite.name = "DispatchLandingStamp"
	station.dispatch_landing_sprite.pixel_size = 0.0074
	station.dispatch_landing_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	station.dispatch_landing_sprite.no_depth_test = true
	station.dispatch_landing_sprite.render_priority = 23
	station.dispatch_landing_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	station.dispatch_landing_root.add_child(station.dispatch_landing_sprite)

	# One pooled icon per workstation closes the physical work loop at the source.
	# It carries no copy and never becomes an input target; the selected dossier
	# remains the only detailed history for that hen.
	station.egg_delivery_ack_root = _new_runtime_root(
		"EggDeliveryAcknowledgment",
		station.root,
	)
	station.egg_delivery_ack_rest_position = Vector3(0.64, 1.88, 0.83)
	station.egg_delivery_ack_root.position = station.egg_delivery_ack_rest_position
	station.egg_delivery_ack_root.visible = false
	station.egg_delivery_ack_root.set_meta("feedback_shape", &"coin_up_arrow")
	station.egg_delivery_ack_root.set_meta("active", false)
	station.egg_delivery_ack_root.set_meta("animated", false)
	station.egg_delivery_ack_root.set_meta("capture_staged", false)
	station.egg_delivery_ack_sprite = Sprite3D.new()
	station.egg_delivery_ack_sprite.name = "EggDeliveryIcon"
	station.egg_delivery_ack_sprite.pixel_size = 0.0104
	station.egg_delivery_ack_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	station.egg_delivery_ack_sprite.no_depth_test = true
	station.egg_delivery_ack_sprite.render_priority = 24
	station.egg_delivery_ack_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	station.egg_delivery_ack_root.add_child(station.egg_delivery_ack_sprite)

	# A physical gold seal rides with the exact file at the workstation. The raised
	# diamond and egg silhouette remain identifiable without relying on hue or text.
	station.golden_file_seal = _new_runtime_root("RoutingGoldenFileSeal", station.root)
	station.golden_file_seal.position = tray_position + Vector3(-0.12, 0.18, -0.02)
	station.golden_file_seal.set_meta("feedback_shape", &"diamond_egg_seal")
	station.golden_file_seal_material = _make_emissive_material(Color("f4c95d"), 1.05, 0.30)
	var seal_back := _add_box_mesh(
		station.golden_file_seal,
		"GoldenSealDiamond",
		Vector3(0.22, 0.035, 0.22),
		Vector3.ZERO,
		station.golden_file_seal_material,
	)
	seal_back.rotation.y = PI * 0.25
	_add_sphere_mesh(
		station.golden_file_seal,
		"GoldenSealEgg",
		Vector3(0.0, 0.075, 0.0),
		Vector3(0.11, 0.16, 0.11),
		station.golden_file_seal_material,
	)
	station.golden_file_seal.visible = false

	station.stress_notice = MeshInstance3D.new()
	station.stress_notice.name = "StressNotice"
	station.stress_notice.mesh = ProceduralPrimitiveCache.box(Vector3(0.42, 0.28, 0.025))
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
	mesh_instance.mesh = ProceduralPrimitiveCache.box(size)
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
	mesh_instance.mesh = ProceduralPrimitiveCache.cylinder(
		top_radius,
		bottom_radius,
		height,
		12,
	)
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
	mesh_instance.mesh = ProceduralPrimitiveCache.sphere(0.5, 1.0, 16, 8)
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
	return SemanticColorPaletteScript.lane_color(lane, _color_vision_mode)


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
