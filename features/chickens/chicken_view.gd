class_name ChickenView
extends Node3D

signal feed_party_attendance_ready(worker_id: int)
signal feed_party_attendance_completed(worker_id: int)
signal workstation_presence_changed(worker_id: int, is_present: bool)
signal office_departure_completed(worker_id: int)
## Deterministic contact markers for the three-hit Priority Peck flourish. Office
## feedback should key desk pulses and contact audio from this signal instead of
## starting independent timers when the player presses the action.
signal priority_peck_contact(
	worker_id: int,
	contact_index: int,
	rating: StringName
)
## Emitted once when the imported lay action reaches its authored release pose.
## The marker is normalized against the actual imported clip length so model
## re-export frame-rate changes do not make gameplay feedback drift.
signal lay_release_reached(worker_id: int)

const ChickenModel := preload("res://assets/models/chicken_employee.glb")
const WALK_SPEED := 2.15
const CAMPUS_COMMUTE_SPEED_MULTIPLIER := 1.75
const PANIC_RUN_SPEED := 4.35
const PANIC_DURATION := 5.6
const ARRIVAL_DISTANCE := 0.055
const ENTRY_STAGGER_SECONDS := 0.90
const MODEL_SCALE := 0.84
const ANIMATION_IDLE := &"Chicken_Idle"
const ANIMATION_WALK := &"Chicken_Walk"
const ANIMATION_PECK := &"Chicken_Peck"
const ANIMATION_SIT := &"Chicken_Sit"
const ANIMATION_LAY := &"Chicken_Lay"
const ANIMATION_PANIC := &"Chicken_Panic"
const PRIORITY_PECK_CONTACT_TIMES: Array[float] = [0.12, 0.28, 0.44]
const PRIORITY_PECK_FEEDBACK_DURATION := 0.58
const PRIORITY_PECK_ANTICIPATION_SECONDS := 0.060
const PRIORITY_PECK_RECOVERY_SECONDS := 0.090
# Blender source frames are 1-based: the release is keyed on frame 22 of a
# frame 1..36 action. Using its normalized position survives import resampling.
const LAY_RELEASE_NORMALIZED_TIME := (22.0 - 1.0) / (36.0 - 1.0)
const LAY_RELEASE_FALLBACK_SECONDS := 0.73
const CHICKEN_PALETTES: Array[Dictionary] = [
	{"feather": "ad7747", "cloth": "173e59"}, # oat + navy
	{"feather": "ddd3b8", "cloth": "6e2935"}, # cream + oxblood
	{"feather": "81523b", "cloth": "667154"}, # chestnut + sage
	{"feather": "c49b5d", "cloth": "493c68"}, # buff + plum
	{"feather": "77736f", "cloth": "173e59"}, # silver + navy
	{"feather": "a96549", "cloth": "667154"}, # russet + sage
]
const ACCESSORY_NAMES: Array[StringName] = [
	&"AccessoryHead_RoundGlasses",
	&"AccessoryHead_SquareGlasses",
	&"AccessoryHead_AccountantVisor",
	&"AccessoryHead_Headset",
	&"AccessoryHead_NewsboyCap",
	&"AccessoryHead_ReadingGlassesChain",
	&"AccessoryHead_Earmuffs",
	&"AccessoryHead_SleepMask",
	&"AccessoryComb_Pencil",
	&"BowTie",
	&"AccessoryNeck_LongTie",
	&"AccessoryNeck_Lanyard",
	&"AccessoryNeck_KnitScarf",
	&"AccessoryNeck_CardiganCollar",
	&"AccessoryNeck_Neckerchief",
	&"AccessoryBody_SweaterVest",
	&"AccessoryBody_PocketProtector",
	&"AccessoryBody_Satchel",
	&"AccessoryBody_TeaMugCharm",
	&"AccessoryBody_QuiltedCapelet",
	&"AccessoryBadge_Nameplate",
	&"AccessoryBadge_GoldenEgg",
	&"AccessoryLeg_Watch",
]
# Curated compatibility slots provide stable, random-feeling silhouettes while
# preventing headwear, neckwear, and outerwear from occupying the same space.
const ACCESSORY_PROFILES: Array[Dictionary] = [
	{"head": &"AccessoryHead_RoundGlasses", "neck": &"AccessoryNeck_LongTie", "body": &"AccessoryBody_PocketProtector"},
	{"head": &"AccessoryHead_SquareGlasses", "neck": &"BowTie", "body": &"AccessoryBody_SweaterVest"},
	{"head": &"AccessoryHead_AccountantVisor", "neck": &"AccessoryNeck_Lanyard", "leg": &"AccessoryLeg_Watch"},
	{"head": &"AccessoryHead_Headset", "badge": &"AccessoryBadge_Nameplate"},
	{"head": &"AccessoryHead_NewsboyCap", "neck": &"AccessoryNeck_KnitScarf", "body": &"AccessoryBody_PocketProtector", "leg": &"AccessoryLeg_Watch"},
	{"head": &"AccessoryHead_ReadingGlassesChain", "neck": &"AccessoryNeck_CardiganCollar", "badge": &"AccessoryBadge_GoldenEgg"},
	{"head": &"AccessoryHead_Earmuffs", "neck": &"AccessoryNeck_KnitScarf", "body": &"AccessoryBody_SweaterVest"},
	{"neck": &"AccessoryNeck_Neckerchief", "body": &"AccessoryBody_Satchel", "badge": &"AccessoryBadge_Nameplate"},
	{"head": &"AccessoryHead_SleepMask", "body": &"AccessoryBody_QuiltedCapelet", "leg": &"AccessoryLeg_Watch"},
	{"head": &"AccessoryHead_AccountantVisor", "neck": &"AccessoryNeck_Lanyard", "charm": &"AccessoryBody_TeaMugCharm"},
	{"head": &"AccessoryHead_NewsboyCap", "neck": &"AccessoryNeck_CardiganCollar", "body": &"AccessoryBody_Satchel"},
	{"head": &"AccessoryHead_RoundGlasses", "neck": &"AccessoryNeck_Neckerchief", "body": &"AccessoryBody_SweaterVest", "badge": &"AccessoryBadge_GoldenEgg"},
	{"head": &"AccessoryHead_SquareGlasses", "neck": &"AccessoryNeck_Lanyard", "body": &"AccessoryBody_PocketProtector", "comb": &"AccessoryComb_Pencil"},
	{"head": &"AccessoryHead_Headset", "neck": &"AccessoryNeck_KnitScarf", "charm": &"AccessoryBody_TeaMugCharm"},
	{"neck": &"AccessoryNeck_CardiganCollar", "body": &"AccessoryBody_QuiltedCapelet", "comb": &"AccessoryComb_Pencil", "leg": &"AccessoryLeg_Watch"},
	{"head": &"AccessoryHead_ReadingGlassesChain", "neck": &"AccessoryNeck_Lanyard", "charm": &"AccessoryBody_TeaMugCharm"},
	{"head": &"AccessoryHead_AccountantVisor", "neck": &"AccessoryNeck_Neckerchief", "body": &"AccessoryBody_PocketProtector", "leg": &"AccessoryLeg_Watch"},
	{"head": &"AccessoryHead_SleepMask", "neck": &"AccessoryNeck_KnitScarf", "body": &"AccessoryBody_Satchel"},
]
const ACCESSORY_PROFILE_DECK: Array[int] = [4, 0, 9, 6, 2, 12, 5, 15, 1, 10, 7, 14, 3, 17, 11, 8, 16, 13]

var worker_id: int = -1
var desk_index: int = -1

var _work_state: int = ChickenState.WorkState.IDLE
var _phase: float = 0.0
var _stress: float = 0.0
var _body_pivot: Node3D
var _head_pivot: Node3D
var _wing_left: Node3D
var _wing_right: Node3D
var _skeleton: Skeleton3D
var _wing_left_bone := -1
var _wing_right_bone := -1
var _wing_left_tip_bone := -1
var _wing_right_tip_bone := -1
var _leg_left: Node3D
var _leg_right: Node3D
var _egg_socket: Node3D
var _neck_grip_socket: Node3D
var _head_rest_position := Vector3.ZERO
var _visual_root: Node3D
var _animation_player: AnimationPlayer
var _animation_names: Dictionary[StringName, StringName] = {}
var _active_model_animation: StringName = &""
var _route: Array[Vector3] = []
var _route_index: int = 0
var _home_position := Vector3.ZERO
var _break_position := Vector3.ZERO
var _arrival_route: Array[Vector3] = []
var _break_route: Array[Vector3] = []
var _destination_kind: StringName = &"entrance"
var _is_walking: bool = false
var _entry_delay: float = 0.0
var _feed_party_active: bool = false
var _feed_party_queued: bool = false
var _feed_party_return_requested: bool = false
var _feed_party_outbound_route: Array[Vector3] = []
var _feed_party_return_route: Array[Vector3] = []
var _feed_party_attendance_position := Vector3.ZERO
var _feed_party_trough_position := Vector3.ZERO
var _campus_duty_active: bool = false
var _campus_duty_return_requested: bool = false
var _campus_duty_position := Vector3.ZERO
var _campus_duty_face_point := Vector3.ZERO
var _campus_duty_return_route: Array[Vector3] = []
var _campus_reassignment_queued: bool = false
var _campus_reassignment_outbound_route: Array[Vector3] = []
var _campus_reassignment_position := Vector3.ZERO
var _campus_reassignment_face_point := Vector3.ZERO
var _is_at_workstation: bool = false
var _visible_accessories: Array[StringName] = []
var _accessory_signature: String = ""
var _career_credential_badge: Node3D
var _career_credential_profile_visible: bool = false
var _career_credential_rest_position := Vector3.ZERO
var _eyes: Array[Node3D] = []
var _eye_rest_scales: Array[Vector3] = []
var _comb: Node3D
var _comb_rest_rotation := Vector3.ZERO
var _tail_feather_pivot: Node3D
var _tail_feather_rest_rotation := Vector3.ZERO
var _accessory_rest_rotations: Dictionary[StringName, Vector3] = {}
var _seat_blend: float = 0.0
var _walk_blend: float = 0.0
var _work_blend: float = 0.0
var _lay_blend: float = 0.0
var _state_elapsed: float = 0.0
var _peck_assist_rating: StringName = &"steady"
var _priority_peck_timeline_active: bool = false
var _priority_peck_elapsed: float = 0.0
var _priority_peck_next_contact: int = 0
var _lay_feedback_active: bool = false
var _lay_feedback_elapsed: float = 0.0
var _lay_release_emitted: bool = false
var _lay_release_delay: float = LAY_RELEASE_FALLBACK_SECONDS
var _predator_captured := false
var _panic_active := false
var _panic_remaining := 0.0
var _panic_threat_origin := Vector3.ZERO


func configure(worker_snapshot: Dictionary) -> void:
	worker_id = int(worker_snapshot["id"])
	desk_index = int(worker_snapshot["desk_index"])
	name = "Chicken_%s" % worker_snapshot["name"]
	_build_character(String(worker_snapshot["name"]), worker_id)
	apply_snapshot(worker_snapshot)


func assign_office_route(
	entry_position: Vector3,
	chair_position: Vector3,
	break_position: Vector3,
	arrival_route: Array[Vector3],
	break_route: Array[Vector3],
	arrival_order: int = -1
) -> void:
	global_position = entry_position
	_home_position = chair_position
	_break_position = break_position
	_arrival_route = arrival_route
	_break_route = break_route
	_campus_duty_active = false
	_campus_duty_return_requested = false
	_campus_duty_return_route.clear()
	_clear_campus_reassignment()
	var stagger_order := worker_id if arrival_order < 0 else arrival_order
	_entry_delay = maxi(0, stagger_order) * ENTRY_STAGGER_SECONDS
	_destination_kind = &"home"
	_set_route(_arrival_route)


## Walks a released employee out through the authored office route. The current
## safe route is allowed to resolve first when the hen is already in motion, so a
## staffing action never produces a pop, diagonal desk cut, or seated glide.
func depart_office(exit_route: Array[Vector3]) -> void:
	if _destination_kind in [&"departure", &"departed"]:
		return
	_entry_delay = 0.0
	_feed_party_queued = false
	_feed_party_return_requested = false
	_feed_party_active = false
	_campus_duty_active = false
	_campus_duty_return_requested = false
	_campus_duty_return_route.clear()
	_clear_campus_reassignment()
	_set_workstation_presence(false)

	var safe_route: Array[Vector3] = []
	if _is_walking:
		for route_index in range(_route_index, _route.size()):
			safe_route.append(_route[route_index])
	if _destination_kind == &"break":
		var return_from_break := _break_route.duplicate()
		return_from_break.reverse()
		safe_route.append_array(return_from_break)
		safe_route.append(_home_position)
	elif _destination_kind == &"home" and (_is_walking or global_position.distance_to(_home_position) > ARRIVAL_DISTANCE * 2.0):
		if safe_route.is_empty() or safe_route[safe_route.size() - 1].distance_to(_home_position) > ARRIVAL_DISTANCE:
			safe_route.append(_home_position)
	safe_route.append_array(exit_route)
	_destination_kind = &"departure"
	_set_route(safe_route)


func apply_snapshot(worker_snapshot: Dictionary) -> void:
	_apply_career_credential(worker_snapshot)
	var previous_state := _work_state
	_work_state = int(worker_snapshot["state"])
	if previous_state != _work_state:
		_state_elapsed = 0.0
		if _work_state == ChickenState.WorkState.LAYING:
			_start_lay_feedback_timeline()
		elif previous_state == ChickenState.WorkState.LAYING and _lay_release_emitted:
			_lay_feedback_active = false
	_stress = float(worker_snapshot["stress"])
	if (
		previous_state == _work_state
		or _home_position == Vector3.ZERO
		or _feed_party_active
		or _feed_party_queued
		or _campus_duty_active
	):
		return
	if _work_state == ChickenState.WorkState.BREAK:
		_destination_kind = &"break"
		_set_route(_break_route)
	elif _destination_kind == &"break":
		_destination_kind = &"home"
		var return_route := _break_route.duplicate()
		return_route.reverse()
		_set_route(return_route)
func attend_feed_party(
	outbound_route: Array[Vector3],
	return_route: Array[Vector3],
	attendance_position: Vector3,
	trough_position: Vector3
) -> void:
	if _campus_duty_active:
		return
	_feed_party_outbound_route = outbound_route.duplicate()
	_feed_party_return_route = return_route.duplicate()
	_feed_party_attendance_position = attendance_position
	_feed_party_trough_position = trough_position
	_feed_party_return_requested = false
	if _feed_party_active:
		return
	if _is_walking or _entry_delay > 0.0:
		_feed_party_queued = true
		return
	_begin_feed_party_route()


func return_from_feed_party() -> void:
	if _campus_duty_active:
		return
	if not _feed_party_active:
		_feed_party_queued = false
		return
	if _destination_kind != &"feed_party":
		_feed_party_return_requested = true
		return
	_feed_party_return_requested = false
	_destination_kind = &"feed_return"
	_set_route(_feed_party_return_route)


func is_attending_feed_party() -> bool:
	return _feed_party_active and _destination_kind == &"feed_party"


## Sends this employee from her current safe office route to an authored campus
## duty station. Campus duty is deliberately presentation-only: staffing and
## persistence remain owned by the simulation, while this view owns the commute.
func assign_campus_duty(
	outbound_route: Array[Vector3],
	duty_position: Vector3,
	face_point: Vector3
) -> void:
	if _campus_duty_active:
		if _destination_kind == &"campus_return" or _campus_duty_return_requested:
			_campus_reassignment_queued = true
			_campus_reassignment_outbound_route = outbound_route.duplicate()
			_campus_reassignment_position = duty_position
			_campus_reassignment_face_point = face_point
		return
	if (
		_predator_captured
		or _panic_active
		or _destination_kind in [&"departure", &"departed"]
	):
		return

	var safe_route := _safe_route_home_for_campus_duty()
	safe_route.append_array(outbound_route)
	if safe_route.is_empty() or safe_route[safe_route.size() - 1].distance_to(duty_position) > ARRIVAL_DISTANCE:
		safe_route.append(duty_position)

	_entry_delay = 0.0
	_feed_party_active = false
	_feed_party_queued = false
	_feed_party_return_requested = false
	_campus_duty_active = true
	_campus_duty_return_requested = false
	_campus_duty_position = duty_position
	_campus_duty_face_point = face_point
	_campus_duty_return_route.clear()
	_clear_campus_reassignment()
	_destination_kind = &"campus_outbound"
	_set_workstation_presence(false)
	_set_route(safe_route)


## Requests the authored trip back to the workstation. If the employee is still
## outbound, she reaches the duty socket first instead of cutting diagonally
## through the campus, then follows this return route on the next route beat.
func return_from_campus_duty(return_route: Array[Vector3]) -> void:
	if not _campus_duty_active:
		return
	_campus_duty_return_route = return_route.duplicate()
	if (
		_campus_duty_return_route.is_empty()
		or _campus_duty_return_route[_campus_duty_return_route.size() - 1].distance_to(_home_position) > ARRIVAL_DISTANCE
	):
		_campus_duty_return_route.append(_home_position)
	_set_workstation_presence(false)
	if _destination_kind == &"campus_outbound":
		_campus_duty_return_requested = true
		return
	if _destination_kind == &"campus_duty":
		_begin_campus_return_route()


func has_campus_duty_assignment() -> bool:
	return _campus_duty_active


func is_at_campus_duty_station() -> bool:
	return _campus_duty_active and _destination_kind == &"campus_duty"


func campus_duty_phase() -> StringName:
	if not _campus_duty_active:
		return &""
	return _destination_kind


func is_seated_at_workstation() -> bool:
	return (
		_is_at_workstation
		and _seat_blend >= 0.92
		and _destination_kind == &"home"
		and not _is_walking
		and not _feed_party_active
		and not _feed_party_queued
		and not _campus_duty_active
		and global_position.distance_to(_home_position) <= ARRIVAL_DISTANCE * 2.0
	)


## Places the featured employee at her authored chair while a blocking campaign
## card is transitioning away. The cold open uses this presentation seam so an
## immediate New/Continue action cannot frame the flock bunched at the entrance.
## Office only calls it while the simulation is still paused for its directive.
func stage_at_workstation_for_introduction() -> void:
	if (
		_home_position == Vector3.ZERO
		or _predator_captured
		or _campus_duty_active
		or _destination_kind in [&"departure", &"departed"]
	):
		return
	_entry_delay = 0.0
	_route.clear()
	_route_index = 0
	_is_walking = false
	_feed_party_active = false
	_feed_party_queued = false
	_feed_party_return_requested = false
	_destination_kind = &"home"
	global_position = _home_position
	rotation.y = 0.0
	_seat_blend = 1.0
	_walk_blend = 0.0
	_set_workstation_presence(true)


func egg_lay_origin_global() -> Vector3:
	if _egg_socket != null and is_instance_valid(_egg_socket):
		return _egg_socket.global_position
	return global_position + Vector3(0.0, 0.72, -0.24)


func accessory_signature() -> String:
	return _accessory_signature


func visible_accessory_names() -> Array[StringName]:
	return _visible_accessories.duplicate()


func play_peck_assist_feedback(rating: StringName) -> void:
	_peck_assist_rating = rating
	_priority_peck_timeline_active = true
	_priority_peck_elapsed = 0.0
	_priority_peck_next_contact = 0
	# Restart the authored clip so the procedural three-peck emphasis and the
	# connected Blender rig share a stable, locally-reset flourish.
	_active_model_animation = &""
	_play_model_animation(ANIMATION_PECK)


## Delay from the beginning of Chicken_Lay to its authored release key. This is
## public so Office integration and focused tests can share the same source of
## truth without duplicating Blender frame assumptions.
func lay_release_delay_seconds() -> float:
	if _lay_feedback_active:
		return _lay_release_delay
	return _calculate_lay_release_delay_seconds()


func _calculate_lay_release_delay_seconds() -> float:
	var clip_length := 0.0
	if (
		_animation_player != null
		and _animation_names.has(ANIMATION_LAY)
		and _animation_player.has_animation(_animation_names[ANIMATION_LAY])
	):
		var lay_animation := _animation_player.get_animation(_animation_names[ANIMATION_LAY])
		if lay_animation != null:
			clip_length = lay_animation.length
	var authored_delay := (
		clip_length * LAY_RELEASE_NORMALIZED_TIME
		if clip_length > 0.0
		else LAY_RELEASE_FALLBACK_SECONDS
	)
	return authored_delay / _model_animation_speed(ANIMATION_LAY)


func _physics_process(delta: float) -> void:
	if _predator_captured:
		return
	_phase += delta
	_state_elapsed += delta
	if _panic_active:
		_panic_remaining = maxf(0.0, _panic_remaining - delta)
		if _panic_remaining <= 0.0:
			_panic_active = false
			_destination_kind = &"home"
			_set_route([_home_position])
	_advance_feedback_timelines(delta)
	_advance_route(delta)
	_update_pose_blends(delta)
	_animate_pose()
	_animate_secondary_motion()
	_apply_wing_actuation()


## Freezes normal office behavior so a predator encounter can reparent this
## exact live employee model to a jaw socket without route/seat code fighting it.
func begin_predator_capture() -> void:
	_predator_captured = true
	_entry_delay = 0.0
	_route.clear()
	_route_index = 0
	_is_walking = false
	_feed_party_active = false
	_feed_party_queued = false
	_feed_party_return_requested = false
	_campus_duty_active = false
	_campus_duty_return_requested = false
	_campus_duty_return_route.clear()
	_clear_campus_reassignment()
	_set_workstation_presence(false)
	if _animation_player != null:
		_animation_player.stop()


## Sends a surviving employee through a short scatter route after a predator
## takes a flockmate. The torso is not weighted to the wing bones.
func begin_predator_panic(threat_origin: Vector3) -> void:
	if _predator_captured or _destination_kind in [&"departure", &"departed"]:
		return
	_panic_active = true
	_panic_remaining = PANIC_DURATION + float(posmod(worker_id, 3)) * 0.28
	_panic_threat_origin = threat_origin
	_entry_delay = 0.0
	_feed_party_active = false
	_feed_party_queued = false
	_feed_party_return_requested = false
	_campus_duty_active = false
	_campus_duty_return_requested = false
	_campus_duty_return_route.clear()
	_clear_campus_reassignment()
	_set_workstation_presence(false)
	_destination_kind = &"panic"
	_set_route(_build_panic_route())


func _build_panic_route() -> Array[Vector3]:
	var away := global_position - _panic_threat_origin
	away.y = 0.0
	if away.length_squared() < 0.001:
		away = Vector3(0.0, 0.0, 1.0)
	away = away.normalized()
	var lateral := Vector3(-away.z, 0.0, away.x)
	var side_sign := -1.0 if posmod(worker_id, 2) == 0 else 1.0
	var first := global_position + away * 1.25 + lateral * side_sign * 0.72
	var second := first + away * 1.42 - lateral * side_sign * 0.48
	var third := second + away * 0.92 + lateral * side_sign * 0.36
	return [first, second, third]


## Applies the ragdoll response to the existing chicken rig. The outer model is
## attached at its NeckGripSocket; the body then swings beneath that fixed
## clamp point.  Do not move HeadPivot here: it carries the grip socket and
## must stay seated in the fox's jaws throughout the shake.
func apply_predator_limp_pose(body_swing: Vector2, neck_actuation: float) -> void:
	if not _predator_captured:
		return
	_body_pivot.rotation = Vector3(0.34 + neck_actuation * 0.72, 0.0, body_swing.y * 0.82)
	_head_pivot.position = _head_rest_position
	_head_pivot.rotation = Vector3.ZERO
	_wing_left.rotation = Vector3(0.12, 0.0, -0.68 - body_swing.y * 1.05)
	_wing_right.rotation = Vector3(0.12, 0.0, 0.68 - body_swing.y * 1.05)
	_apply_wing_actuation()
	_leg_left.rotation = Vector3(-1.04 + body_swing.x * 0.72, 0.20, 0.0)
	_leg_right.rotation = Vector3(-1.04 - body_swing.x * 0.72, -0.20, 0.0)


## Local-space neck clamp point used by the predator jaw socket. It is taken
## from the real imported rig, not a guessed model-height constant.
func predator_neck_local_offset() -> Vector3:
	if _neck_grip_socket != null and is_instance_valid(_neck_grip_socket):
		return to_local(_neck_grip_socket.global_position)
	# Compatibility fallback for an old imported employee asset.
	var neck_base := _head_pivot.position + Vector3(0.0, -0.18, 0.0)
	return _visual_root.transform * neck_base


func _advance_feedback_timelines(delta: float) -> void:
	if _priority_peck_timeline_active:
		_priority_peck_elapsed += delta
		# A while-loop preserves contact order even when a slow frame crosses more
		# than one marker. Restarting the action always resets the local index.
		while (
			_priority_peck_next_contact < PRIORITY_PECK_CONTACT_TIMES.size()
			and _priority_peck_elapsed
				>= PRIORITY_PECK_CONTACT_TIMES[_priority_peck_next_contact]
		):
			priority_peck_contact.emit(
				worker_id,
				_priority_peck_next_contact,
				_peck_assist_rating,
			)
			_priority_peck_next_contact += 1
		if _priority_peck_elapsed >= PRIORITY_PECK_FEEDBACK_DURATION:
			_priority_peck_timeline_active = false

	if not _lay_feedback_active:
		return
	_lay_feedback_elapsed += delta
	var just_released := false
	if (
		not _lay_release_emitted
		and _lay_feedback_elapsed >= _lay_release_delay
	):
		_lay_release_emitted = true
		just_released = true
		lay_release_reached.emit(worker_id)
	# If a high simulation speed ends LAYING early, hold the authored action only
	# until its release frame. The release remains visible and signals exactly
	# once without slowing or mutating the simulation itself.
	if (
		_lay_release_emitted
		and _work_state != ChickenState.WorkState.LAYING
		and not just_released
	):
		_lay_feedback_active = false


func _start_lay_feedback_timeline() -> void:
	_lay_feedback_active = true
	_lay_feedback_elapsed = 0.0
	_lay_release_emitted = false
	_lay_release_delay = _calculate_lay_release_delay_seconds()
	_active_model_animation = &""


func _advance_route(delta: float) -> void:
	if _entry_delay > 0.0:
		_entry_delay = maxf(0.0, _entry_delay - delta)
		return
	if _route_index >= _route.size():
		_is_walking = false
		if _destination_kind == &"home":
			global_position = _home_position
			rotation.y = lerp_angle(rotation.y, 0.0, minf(1.0, delta * 8.0))
			if _feed_party_queued:
				_begin_feed_party_route()
		elif _destination_kind == &"break" and _feed_party_queued:
			_begin_feed_party_route()
		elif _destination_kind == &"feed_outbound":
			global_position = _feed_party_attendance_position
			_face_point(_feed_party_trough_position, delta)
			_destination_kind = &"feed_party"
			feed_party_attendance_ready.emit(worker_id)
			if _feed_party_return_requested:
				return_from_feed_party()
		elif _destination_kind == &"feed_party":
			_face_point(_feed_party_trough_position, delta)
		elif _destination_kind == &"feed_return":
			global_position = _home_position
			rotation.y = lerp_angle(rotation.y, 0.0, minf(1.0, delta * 8.0))
			_destination_kind = &"home"
			_feed_party_active = false
			feed_party_attendance_completed.emit(worker_id)
		elif _destination_kind == &"campus_outbound":
			global_position = _campus_duty_position
			_face_point(_campus_duty_face_point, delta)
			_destination_kind = &"campus_duty"
			if _campus_duty_return_requested:
				_begin_campus_return_route()
		elif _destination_kind == &"campus_duty":
			_face_point(_campus_duty_face_point, delta)
		elif _destination_kind == &"campus_return":
			global_position = _home_position
			rotation.y = lerp_angle(rotation.y, 0.0, minf(1.0, delta * 8.0))
			_destination_kind = &"home"
			_campus_duty_active = false
			_campus_duty_return_requested = false
			_campus_duty_return_route.clear()
			if _campus_reassignment_queued:
				var next_outbound_route := _campus_reassignment_outbound_route.duplicate()
				var next_duty_position := _campus_reassignment_position
				var next_face_point := _campus_reassignment_face_point
				_clear_campus_reassignment()
				assign_campus_duty(next_outbound_route, next_duty_position, next_face_point)
		elif _destination_kind == &"departure":
			_destination_kind = &"departed"
			office_departure_completed.emit(worker_id)
		elif _destination_kind == &"panic" and _panic_active:
			_set_route(_build_panic_route())
		return

	var target := _route[_route_index]
	var offset := target - global_position
	offset.y = 0.0
	if offset.length() <= ARRIVAL_DISTANCE:
		global_position.x = target.x
		global_position.z = target.z
		_route_index += 1
		return

	_is_walking = true
	var direction := offset.normalized()
	# Finish standing up before translating away from a chair.  This small gate
	# removes the characteristic seated glide while keeping route timing stable.
	if _seat_blend > 0.08:
		var stand_yaw := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, stand_yaw, minf(1.0, delta * 7.0))
		return
	var movement_speed := PANIC_RUN_SPEED if _panic_active else WALK_SPEED
	if not _panic_active and _destination_kind in [&"campus_outbound", &"campus_return"]:
		# Campus posts are deliberately far from the desk floor. A brisk authored
		# commute keeps staffing responsive while retaining every collision-safe
		# waypoint and the ordinary walk silhouette.
		movement_speed *= CAMPUS_COMMUTE_SPEED_MULTIPLIER
	global_position += direction * minf(movement_speed * delta, offset.length())
	# Blender's -Y character forward imports as Godot +Z.
	var target_yaw := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, delta * 9.0))


func _animate_pose() -> void:
	_reset_pose()
	if _panic_active:
		_play_model_animation(ANIMATION_PANIC)
		_apply_walk_pose()
		_apply_panic_pose()
	elif _is_walking:
		_play_model_animation(ANIMATION_WALK)
		_apply_walk_pose()
	elif _destination_kind == &"feed_party":
		_play_model_animation(ANIMATION_PECK)
		_apply_feeding_pose()
	elif _destination_kind == &"home":
		if _work_state == ChickenState.WorkState.LAYING or _lay_feedback_active:
			_play_model_animation(ANIMATION_LAY)
		elif _work_state == ChickenState.WorkState.WORKING:
			_play_model_animation(ANIMATION_PECK)
		else:
			_play_model_animation(ANIMATION_SIT)
		_apply_seated_pose()
	else:
		_play_model_animation(ANIMATION_IDLE)
		_apply_break_pose()


func _update_pose_blends(delta: float) -> void:
	var seat_target := 1.0 if (
		_destination_kind == &"home"
		and not _is_walking
		and _route_index >= _route.size()
	) else 0.0
	_seat_blend = move_toward(_seat_blend, seat_target, delta * (2.8 if seat_target > _seat_blend else 3.8))
	_walk_blend = move_toward(_walk_blend, 1.0 if _is_walking else 0.0, delta * 5.5)
	_work_blend = move_toward(
		_work_blend,
		1.0 if _work_state == ChickenState.WorkState.WORKING and seat_target > 0.0 else 0.0,
		delta * 4.0
	)
	_lay_blend = move_toward(
		_lay_blend,
		1.0 if _work_state == ChickenState.WorkState.LAYING and seat_target > 0.0 else 0.0,
		delta * 3.2
	)
	# Gameplay presence follows the visible seated pose, not merely arrival at
	# the chair coordinate. Production therefore cannot resume mid-transition.
	if seat_target > 0.0 and _seat_blend >= 0.92:
		_set_workstation_presence(true)


func _reset_pose() -> void:
	_body_pivot.position = Vector3.ZERO
	_body_pivot.rotation = Vector3.ZERO
	_body_pivot.scale = Vector3(1.0, lerpf(1.0, 0.92, clampf(_stress / 100.0, 0.0, 1.0)), 1.0)
	_head_pivot.rotation = Vector3.ZERO
	_head_pivot.position = _head_rest_position
	_wing_left.rotation = Vector3.ZERO
	_wing_right.rotation = Vector3.ZERO
	_leg_left.rotation = Vector3.ZERO
	_leg_right.rotation = Vector3.ZERO


func _apply_walk_pose() -> void:
	var stride := sin(_phase * 9.5)
	var footfall := absf(sin(_phase * 9.5))
	var stand_ease := _seat_blend * _seat_blend * (3.0 - 2.0 * _seat_blend)
	_body_pivot.position.y = lerpf(0.045 + footfall * 0.065, 0.55, stand_ease)
	_body_pivot.position.z = lerpf(0.0, 0.025, stand_ease)
	_body_pivot.rotation.x = lerpf(0.025, -0.07, stand_ease)
	_body_pivot.rotation.z = stride * 0.052 * (1.0 - stand_ease)
	_head_pivot.rotation.x = -0.08 + absf(stride) * 0.08
	_leg_left.rotation.x = lerpf(stride * 0.68, -1.16, stand_ease)
	_leg_right.rotation.x = lerpf(-stride * 0.68, -1.16, stand_ease)
	_wing_left.rotation.z = lerpf(-0.10 + stride * 0.075, -0.18, stand_ease)
	_wing_right.rotation.z = lerpf(0.10 + stride * 0.075, 0.18, stand_ease)


func _apply_panic_pose() -> void:
	# ChickenView owns the live skeleton's wing pose, so mirror the authored
	# panic action here as well. This keeps the separate feather meshes flapping
	# in-game instead of allowing a procedural walk pose to override the clip.
	var flap := (sin(_phase * 18.0 + worker_id * 0.67) + 1.0) * 0.5
	_wing_left.rotation = Vector3(0.10, 0.0, lerpf(-0.12, 1.05, flap))
	_wing_right.rotation = Vector3(0.10, 0.0, lerpf(0.12, -1.05, flap))
	_head_pivot.rotation.y += sin(_phase * 11.0 + worker_id) * 0.18


func _apply_seated_pose() -> void:
	# Ease onto the 0.54 m chair seat with a small anticipatory crouch. Folded
	# feet stay visibly below the belly instead of vanishing into the cushion.
	var seat := _seat_blend * _seat_blend * (3.0 - 2.0 * _seat_blend)
	var sit_crouch := sin(_seat_blend * PI) * 0.045
	_body_pivot.position.y = 0.55 * seat - sit_crouch
	_body_pivot.position.z = 0.035 * seat
	_body_pivot.rotation.x = lerpf(0.0, -0.075, seat)
	_leg_left.rotation.x = lerpf(0.0, -1.16, seat)
	_leg_right.rotation.x = lerpf(0.0, -1.16, seat)
	_wing_left.rotation.z = lerpf(-0.08, -0.18, seat)
	_wing_right.rotation.z = lerpf(0.08, 0.18, seat)

	if _lay_feedback_active:
		_apply_laying_pose()
		return

	match _work_state:
		ChickenState.WorkState.WORKING:
			# A sharp contact beat framed by slower anticipation and recoil makes
			# pecking readable without separating the face from the feather shell.
			var priority_contact := _priority_peck_contact_strength()
			var peck_cycle := (
				priority_contact
				if _priority_peck_timeline_active
				else maxf(0.0, sin(_phase * 10.6 + worker_id * 0.31))
			)
			var peck := peck_cycle * peck_cycle * _work_blend
			var assist_emphasis := (
				(0.075 if _peck_assist_rating == &"perfect" else 0.045)
				* priority_contact
			)
			_body_pivot.rotation.x += -0.045 - peck * (0.19 + assist_emphasis)
			_body_pivot.position.z += peck * (0.075 + assist_emphasis * 0.30)
			_body_pivot.position.y -= peck * (0.018 + assist_emphasis * 0.10)
			_wing_left.rotation.z -= peck * 0.035
			_wing_right.rotation.z += peck * 0.035
		ChickenState.WorkState.LAYING:
			_apply_laying_pose()
		_:
			_head_pivot.rotation.x = sin(_phase * 1.4 + worker_id) * 0.045


func _priority_peck_contact_strength() -> float:
	if not _priority_peck_timeline_active:
		return 0.0
	var strongest := 0.0
	for contact_time in PRIORITY_PECK_CONTACT_TIMES:
		var offset := _priority_peck_elapsed - contact_time
		var contact_strength := 0.0
		if offset >= -PRIORITY_PECK_ANTICIPATION_SECONDS and offset <= 0.0:
			contact_strength = smoothstep(
				-PRIORITY_PECK_ANTICIPATION_SECONDS,
				0.0,
				offset,
			)
		elif offset > 0.0 and offset <= PRIORITY_PECK_RECOVERY_SECONDS:
			contact_strength = 1.0 - smoothstep(
				0.0,
				PRIORITY_PECK_RECOVERY_SECONDS,
				offset,
			)
		strongest = maxf(strongest, contact_strength)
	return strongest


func _apply_laying_pose() -> void:
	var lay_duration := maxf(0.001, _lay_release_delay / LAY_RELEASE_NORMALIZED_TIME)
	var effort_phase := fmod(_lay_feedback_elapsed, lay_duration) / lay_duration
	var brace := sin(effort_phase * PI)
	var release := pow(maxf(0.0, sin((effort_phase - 0.48) * PI * 2.0)), 3.0)
	_body_pivot.position.y += brace * 0.050 * _lay_blend + release * 0.045
	_body_pivot.position.z -= brace * 0.035 * _lay_blend
	_body_pivot.scale.x *= 1.0 + brace * 0.035 * _lay_blend
	_body_pivot.scale.z *= 1.0 - brace * 0.040 * _lay_blend
	_body_pivot.rotation.z += sin(effort_phase * TAU) * 0.040 * _lay_blend
	_head_pivot.rotation.x = -0.22 * _lay_blend
	_wing_left.rotation.z -= brace * 0.12 * _lay_blend
	_wing_right.rotation.z += brace * 0.12 * _lay_blend


func _apply_break_pose() -> void:
	_body_pivot.position.y = absf(sin(_phase * 1.7 + worker_id)) * 0.018
	_body_pivot.rotation.z = sin(_phase * 0.72 + worker_id) * 0.018
	_head_pivot.rotation.y = sin(_phase * 0.85 + worker_id) * 0.24
	_wing_left.rotation.z = -0.12
	_wing_right.rotation.z = 0.12
	match posmod(worker_id, 3):
		0: # Curious head tilts and a poised wing.
			_head_pivot.rotation.z = sin(_phase * 0.62) * 0.10
			_wing_left.rotation.z -= maxf(0.0, sin(_phase * 0.55)) * 0.07
		1: # A reserved, compact accountant stance.
			_body_pivot.scale.x *= 0.992
			_head_pivot.rotation.x = -0.035 + sin(_phase * 0.48) * 0.025
		2: # Occasional preen gesture, unsynchronised across the flock.
			var preen := pow(maxf(0.0, sin(_phase * 0.42 + worker_id)), 5.0)
			_body_pivot.rotation.x -= preen * 0.07
			_wing_right.rotation.z += preen * 0.16


func _apply_feeding_pose() -> void:
	# The attendance sockets keep the breast outside the trough; the soft forward
	# tilt brings only the beak over the feed instead of clipping the whole bird.
	var peck := maxf(0.0, sin(_phase * 9.5 + worker_id * 0.7))
	_body_pivot.position.y = 0.045 - peck * 0.025
	_body_pivot.position.z = peck * 0.045
	_body_pivot.rotation.x = -0.16 - peck * 0.24
	_wing_left.rotation.z = -0.08
	_wing_right.rotation.z = 0.08


func _begin_feed_party_route() -> void:
	if _campus_duty_active:
		return
	var route := _feed_party_outbound_route.duplicate()
	if _destination_kind == &"break":
		var route_home := _break_route.duplicate()
		route_home.reverse()
		route_home.append(_home_position)
		route_home.append_array(route)
		route = route_home
	_feed_party_queued = false
	_feed_party_active = true
	_destination_kind = &"feed_outbound"
	_set_route(route)


func _safe_route_home_for_campus_duty() -> Array[Vector3]:
	var route: Array[Vector3] = []
	if _is_walking:
		for route_index in range(_route_index, _route.size()):
			route.append(_route[route_index])

	match _destination_kind:
		&"break":
			var return_from_break := _break_route.duplicate()
			return_from_break.reverse()
			route.append_array(return_from_break)
		&"feed_outbound", &"feed_party":
			route.append_array(_feed_party_return_route)
		&"home", &"entrance", &"feed_return":
			pass
		_:
			if global_position.distance_to(_home_position) > ARRIVAL_DISTANCE:
				route.append(_home_position)

	if route.is_empty() or route[route.size() - 1].distance_to(_home_position) > ARRIVAL_DISTANCE:
		route.append(_home_position)
	return route


func _begin_campus_return_route() -> void:
	_campus_duty_return_requested = false
	_destination_kind = &"campus_return"
	_set_workstation_presence(false)
	_set_route(_campus_duty_return_route)


func _clear_campus_reassignment() -> void:
	_campus_reassignment_queued = false
	_campus_reassignment_outbound_route.clear()
	_campus_reassignment_position = Vector3.ZERO
	_campus_reassignment_face_point = Vector3.ZERO


func _face_point(point: Vector3, delta: float) -> void:
	var direction := point - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.0001:
		return
	var target_yaw := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, delta * 12.0))


func _set_route(points: Array[Vector3]) -> void:
	_route = points
	_route_index = 0
	_is_walking = not _route.is_empty()
	if _is_walking:
		_set_workstation_presence(false)


func _set_workstation_presence(is_present: bool) -> void:
	if _is_at_workstation == is_present:
		return
	_is_at_workstation = is_present
	workstation_presence_changed.emit(worker_id, is_present)


func _build_character(worker_name: String, color_index: int) -> void:
	_visual_root = ChickenModel.instantiate() as Node3D
	_visual_root.name = "EmployeeModel"
	_visual_root.scale = Vector3.ONE * MODEL_SCALE
	add_child(_visual_root)
	_cache_model_animations()
	_body_pivot = _find_joint(&"BodyPivot")
	_head_pivot = _find_joint(&"HeadPivot")
	_wing_left = _find_joint(&"WingLeftPivot")
	_wing_right = _find_joint(&"WingRightPivot")
	_skeleton = _visual_root.find_child("Skeleton3D", true, false) as Skeleton3D
	if _skeleton != null:
		_wing_left_bone = _skeleton.find_bone("wing_L")
		_wing_right_bone = _skeleton.find_bone("wing_R")
		_wing_left_tip_bone = _skeleton.find_bone("wing_L_tip")
		_wing_right_tip_bone = _skeleton.find_bone("wing_R_tip")
	_leg_left = _find_joint(&"LegLeftPivot")
	_leg_right = _find_joint(&"LegRightPivot")
	_egg_socket = _find_joint(&"EggSocket")
	_neck_grip_socket = _find_joint(&"NeckGripSocket")
	_head_rest_position = _head_pivot.position
	_apply_feather_variant(color_index)
	_apply_accessory_variant(worker_name, color_index)
	_career_credential_badge = _visual_root.find_child("AccessoryBadge_GoldenEgg", true, false) as Node3D
	if _career_credential_badge != null:
		_career_credential_profile_visible = _career_credential_badge.visible
		_career_credential_rest_position = _career_credential_badge.position
	_cache_secondary_motion_parts()


func _apply_career_credential(worker_snapshot: Dictionary) -> void:
	if _career_credential_badge == null:
		return
	var secondary_lane := String(worker_snapshot.get(
		"secondary_specialty",
		worker_snapshot.get("secondary_lane", ""),
	))
	var training_lane := String(worker_snapshot.get(
		"training_specialty",
		worker_snapshot.get(
			"cross_training_target",
			worker_snapshot.get("pending_training_lane", worker_snapshot.get("training_lane", "")),
		),
	))
	var sponsored := not secondary_lane.is_empty() or not training_lane.is_empty()
	# Reuse the model's authored torso-mounted golden credential so sponsorship
	# remains connected through peck, walk, sit, and lay animations. When it is an
	# earned credential rather than the profile badge, mirror it to the opposite
	# breast so it cannot overlap a nameplate or pocket protector.
	_career_credential_badge.position = _career_credential_rest_position
	if sponsored and not _career_credential_profile_visible:
		_career_credential_badge.position.x = -_career_credential_rest_position.x
	_career_credential_badge.visible = _career_credential_profile_visible or sponsored
	_career_credential_badge.set_meta("career_sponsorship_badge", sponsored)


func _apply_wing_actuation() -> void:
	# The visual pivots remain the authoring interface used throughout the
	# behavior poses, while the matching skeleton bones provide the real mesh
	# deformation. This keeps wings responsive during walk, work, limp, and idle
	# states instead of merely rotating an empty helper node.
	if _skeleton == null:
		return
	if _wing_left_bone >= 0:
		_skeleton.set_bone_pose_rotation(
			_wing_left_bone,
			Quaternion.from_euler(_wing_left.rotation),
		)
	if _wing_right_bone >= 0:
		_skeleton.set_bone_pose_rotation(
			_wing_right_bone,
			Quaternion.from_euler(_wing_right.rotation),
		)
	# The outer feathers trail the shoulder movement at a smaller angle. This
	# creates a readable fold/unfold without exposing a hard hinge in the body.
	var left_tip_rotation := Vector3(
		_wing_left.rotation.x * 0.42,
		_wing_left.rotation.y * 0.30,
		_wing_left.rotation.z * 0.58,
	)
	var right_tip_rotation := Vector3(
		_wing_right.rotation.x * 0.42,
		_wing_right.rotation.y * 0.30,
		_wing_right.rotation.z * 0.58,
	)
	if _wing_left_tip_bone >= 0:
		_skeleton.set_bone_pose_rotation(
			_wing_left_tip_bone,
			Quaternion.from_euler(left_tip_rotation),
		)
	if _wing_right_tip_bone >= 0:
		_skeleton.set_bone_pose_rotation(
			_wing_right_tip_bone,
			Quaternion.from_euler(right_tip_rotation),
		)


func _cache_model_animations() -> void:
	_animation_player = _visual_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _animation_player == null:
		return
	_animation_player.playback_default_blend_time = 0.14
	for available_name in _animation_player.get_animation_list():
		for requested_name in [ANIMATION_IDLE, ANIMATION_WALK, ANIMATION_PECK, ANIMATION_SIT, ANIMATION_LAY, ANIMATION_PANIC]:
			if String(available_name).ends_with(String(requested_name)):
				_animation_names[requested_name] = available_name
	_play_model_animation(ANIMATION_IDLE)
	if _animation_player.current_animation_length > 0.0:
		_animation_player.seek(fmod(worker_id * 0.41, _animation_player.current_animation_length), true)


func _play_model_animation(requested_name: StringName) -> void:
	if _animation_player == null or not _animation_names.has(requested_name):
		return
	if _active_model_animation == requested_name:
		# The sit action is a one-shot transition whose final frame should hold.
		# The other short actions restart when their imported clip finishes.
		if requested_name == ANIMATION_SIT or _animation_player.is_playing():
			return
	_active_model_animation = requested_name
	_animation_player.play(
		_animation_names[requested_name],
		-1.0,
		_model_animation_speed(requested_name),
	)


func _model_animation_speed(requested_name: StringName) -> float:
	var personality_speed := 0.94 + posmod(worker_id, 4) * 0.025
	if requested_name == ANIMATION_IDLE:
		personality_speed *= 0.88
	elif requested_name == ANIMATION_LAY:
		personality_speed *= 0.92
	elif requested_name == ANIMATION_PANIC:
		personality_speed *= 1.32
	return personality_speed


func _find_joint(joint_name: StringName) -> Node3D:
	var joint := _visual_root.find_child(String(joint_name), true, false) as Node3D
	assert(joint != null, "Chicken model is missing joint %s" % joint_name)
	return joint


func _apply_feather_variant(color_index: int) -> void:
	var palette: Dictionary = CHICKEN_PALETTES[posmod(color_index, CHICKEN_PALETTES.size())]
	var base_color := Color(String(palette["feather"]))
	var base_material := _feather_material(base_color)
	var light_material := _feather_material(base_color.lightened(0.16))
	var covert_material := _feather_material(base_color.darkened(0.08))
	var dark_material := _feather_material(base_color.darkened(0.20))
	for child in _all_children(_visual_root):
		if child is not MeshInstance3D:
			continue
		var mesh_instance := child as MeshInstance3D
		# Feather material names are the palette contract. This includes the torso,
		# separately skinned wings, shoulder hinges, and pivoted tail feathers while
		# excluding accessories, eyes, beak, comb, and feet. Surface overrides stay
		# per-instance so one employee's palette never changes another employee.
		for surface_index in mesh_instance.mesh.get_surface_count():
			var source_material := mesh_instance.mesh.surface_get_material(surface_index)
			var zone_name := source_material.resource_name if source_material != null else ""
			if not zone_name.begins_with("Feathers_"):
				continue
			var variant_material := base_material
			if "Cream" in zone_name or "Belly" in zone_name or "Face" in zone_name:
				variant_material = light_material
			elif "Wing_Covert" in zone_name:
				variant_material = covert_material
			elif "Wing" in zone_name or "Tail" in zone_name:
				variant_material = dark_material
			mesh_instance.set_surface_override_material(surface_index, variant_material)


func _apply_accessory_variant(_worker_name: String, color_index: int) -> void:
	_visible_accessories.clear()
	for accessory_name in ACCESSORY_NAMES:
		var accessory := _visual_root.find_child(String(accessory_name), true, false) as Node3D
		assert(accessory != null, "Chicken model is missing accessory %s" % accessory_name)
		accessory.visible = false

	# Worker IDs traverse a shuffled art-directed deck, guaranteeing distinct
	# opening-roster silhouettes while remaining stable across save/reload.
	var deck_index := posmod(color_index, ACCESSORY_PROFILE_DECK.size())
	var profile_index: int = ACCESSORY_PROFILE_DECK[deck_index]
	var profile: Dictionary = ACCESSORY_PROFILES[profile_index]
	for slot_name in ["head", "neck", "body", "badge", "comb", "charm", "leg"]:
		var accessory_name := StringName(profile.get(slot_name, &""))
		if accessory_name.is_empty():
			continue
		var accessory := _visual_root.find_child(String(accessory_name), true, false) as Node3D
		accessory.visible = true
		_visible_accessories.append(accessory_name)

	# Clothing and feathers share one coordinated employee palette. Surface
	# overrides remain per instance, so save/reload never changes another hen.
	var palette: Dictionary = CHICKEN_PALETTES[posmod(color_index, CHICKEN_PALETTES.size())]
	_apply_accessory_accent(Color(String(palette["cloth"])))
	var signature_parts := PackedStringArray()
	for accessory_name in _visible_accessories:
		signature_parts.append(String(accessory_name))
	_accessory_signature = "+".join(signature_parts)


func _apply_accessory_accent(color: Color) -> void:
	var accent_material := StandardMaterial3D.new()
	accent_material.albedo_color = color
	accent_material.roughness = 0.50
	for accessory_name in _visible_accessories:
		var accessory := _visual_root.find_child(String(accessory_name), true, false)
		var candidates: Array[Node] = [accessory]
		candidates.append_array(_all_children(accessory))
		for child in candidates:
			if child is not MeshInstance3D:
				continue
			var mesh_instance := child as MeshInstance3D
			for surface_index in mesh_instance.mesh.get_surface_count():
				var source_material := mesh_instance.mesh.surface_get_material(surface_index)
				var material_name := source_material.resource_name if source_material != null else ""
				if "Corporate_Navy" in material_name or "Accessory_Cloth" in material_name:
					mesh_instance.set_surface_override_material(surface_index, accent_material)


func _cache_secondary_motion_parts() -> void:
	_eyes.clear()
	_eye_rest_scales.clear()
	for eye_name in ["Eye_-1", "Eye_1"]:
		var eye := _visual_root.find_child(eye_name, true, false) as Node3D
		if eye != null:
			_eyes.append(eye)
			_eye_rest_scales.append(eye.scale)
	_comb = _visual_root.find_child("Comb", true, false) as Node3D
	if _comb != null:
		_comb_rest_rotation = _comb.rotation
	_tail_feather_pivot = _visual_root.find_child("TailFeatherPivot", true, false) as Node3D
	if _tail_feather_pivot != null:
		_tail_feather_rest_rotation = _tail_feather_pivot.rotation
	_accessory_rest_rotations.clear()
	for accessory_name in _visible_accessories:
		var accessory := _visual_root.find_child(String(accessory_name), true, false) as Node3D
		if accessory != null:
			_accessory_rest_rotations[accessory_name] = accessory.rotation


func _animate_secondary_motion() -> void:
	# A fast close-and-open blink gives the glossy eyes life without creating a
	# separate eyelid mesh. Each worker's offset keeps the flock unsynchronized.
	var blink_period := 4.2 + worker_id * 0.17
	var blink_time := fmod(_phase + worker_id * 0.83, blink_period)
	var eye_openness := 1.0
	if blink_time < 0.16:
		eye_openness = lerpf(0.12, 1.0, absf(blink_time - 0.08) / 0.08)
	for eye_index in _eyes.size():
		var rest_scale := _eye_rest_scales[eye_index]
		_eyes[eye_index].scale = Vector3(rest_scale.x, rest_scale.y * eye_openness, rest_scale.z)

	var breath := 1.0 + sin(_phase * 2.15 + worker_id * 0.7) * 0.006
	_body_pivot.scale.x *= breath
	_body_pivot.scale.z *= breath
	if _comb != null:
		_comb.rotation = _comb_rest_rotation
		var comb_motion := 2.8 if _panic_active else (1.65 if _is_walking else 1.0)
		var comb_energy := 0.022 + clampf(_stress / 100.0, 0.0, 1.0) * 0.030
		_comb.rotation.z += sin(_phase * 3.1 * comb_motion + worker_id) * comb_energy
		_comb.rotation.x += sin(_phase * 2.3 * comb_motion + worker_id * 0.4) * comb_energy * 0.42
	if _tail_feather_pivot != null:
		_tail_feather_pivot.rotation = _tail_feather_rest_rotation
		var tail_motion := 2.9 if _panic_active else (1.55 if _is_walking else 1.0)
		var tail_energy := 0.045 + clampf(_stress / 100.0, 0.0, 1.0) * 0.040
		_tail_feather_pivot.rotation.x += sin(_phase * 2.8 * tail_motion + worker_id * 0.52) * tail_energy
		_tail_feather_pivot.rotation.z += sin(_phase * 3.5 * tail_motion + worker_id) * tail_energy * 0.55

	for accessory_name in _visible_accessories:
		if not _accessory_rest_rotations.has(accessory_name):
			continue
		var accessory := _visual_root.find_child(String(accessory_name), true, false) as Node3D
		if accessory == null:
			continue
		accessory.rotation = _accessory_rest_rotations[accessory_name]
		if String(accessory_name).contains("Neck") or accessory_name == &"BowTie":
			var sway_speed := 7.5 if _is_walking else 2.0
			accessory.rotation.z += sin(_phase * sway_speed + worker_id) * (0.035 if _is_walking else 0.012)


func _all_children(parent: Node) -> Array[Node]:
	var results: Array[Node] = []
	for child in parent.get_children():
		results.append(child)
		results.append_array(_all_children(child))
	return results


func _feather_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.0
	material.roughness = 0.78
	material.metallic_specular = 0.30
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return material
