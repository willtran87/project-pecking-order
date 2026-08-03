class_name ChickenView
extends Node3D

signal feed_party_attendance_ready(worker_id: int)
signal feed_party_attendance_completed(worker_id: int)
signal workstation_presence_changed(worker_id: int, is_present: bool)
signal office_departure_completed(worker_id: int)
## Ambient work pecks emit one visual contact per authored peck cycle, but only
## while the hen is physically seated at an active file. This keeps screen
## feedback causal without making the workstation controller poll every bird.
signal work_peck_contact(worker_id: int, contact_serial: int)
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
const CHARACTER_SHADOW_HOSTS: Array[StringName] = [
	&"Feather_Torso",
	&"ArticulatedWing_L",
	&"ArticulatedWing_R",
	&"TailFeatherFan",
	&"LegLeftMesh",
	&"LegRightMesh",
]
const HEN_INTENT_COLORS := {
	&"sync": "d5aa4f",
	&"urgent": "df6f55",
	&"care": "58a99b",
	&"choice": "668fbd",
	&"match": "d6ad4d",
	&"ready": "c8a24d",
	&"steady": "729b70",
}
const HEN_INTENT_BASE_HEIGHT := 1.80
const HEN_INTENT_HEIGHT_OFFSETS := [0.0, 0.11, 0.22, 0.11]
const HEN_INTENT_COMPACT_PIXEL_SIZE := 0.0075
const HEN_INTENT_STANDARD_PIXEL_SIZE := 0.009
const HEN_INTENT_URGENT_PIXEL_SIZE := 0.0096
const HEN_INTENT_HANDOFF_SCALE := Vector3(0.90, 0.90, 0.90)
const HEN_INTENT_HANDOFF_SCALE_SECONDS := 0.20
const HEN_INTENT_HANDOFF_COLOR_SECONDS := 0.30
const DISPATCH_HANDOFF_START_SCALE := Vector3(0.78, 0.78, 0.78)
const DISPATCH_HANDOFF_PEAK_SCALE := Vector3(1.18, 1.18, 1.18)
const DISPATCH_HANDOFF_RISE_SECONDS := 0.14
const DISPATCH_HANDOFF_SETTLE_SECONDS := 0.20
const DISPATCH_HANDOFF_STATIC_SECONDS := 0.34
const PRIORITY_PECK_READY_HALO_SCALE := Vector3(1.44, 1.44, 1.44)
const PRIORITY_PECK_READY_HALO_SECONDS := 0.42
const PRIORITY_PECK_MISSED_HALO_SCALE := Vector3(0.72, 0.72, 0.72)
const PRIORITY_PECK_MISSED_HALO_SECONDS := 0.46
const HEN_INTENT_SYMBOLS := {
	&"sync": "M31 11 L20 31 H29 L25 53 L45 26 H35 L40 11 Z",
	&"urgent": "M32 10 L56 52 H8 Z M29 24 H35 V38 H29 Z M29 42 H35 V48 H29 Z",
	&"care": "M32 52 C8 38 10 18 22 17 C28 17 31 21 32 24 C33 21 36 17 42 17 C54 18 56 38 32 52 Z",
	&"choice": "M29 15 H35 V27 H43 V20 L54 31 L43 42 V35 H35 V49 H29 V35 H21 V42 L10 31 L21 20 V27 H29 Z",
	&"match": "M32 8 L39 23 L56 25 L44 37 L47 54 L32 46 L17 54 L20 37 L8 25 L25 23 Z",
	# A signpost communicates routing without reusing the egg silhouette.
	&"ready": "M29 8 H35 V56 H29 Z M29 14 H12 V25 H29 Z M12 19 L20 11 V27 Z M35 34 H52 V45 H35 Z M52 39 L44 31 V47 Z",
	&"steady": "M15 31 L27 43 L50 19 L55 25 L27 53 L9 36 Z",
}
const FLOCK_BOND_COLORS := {
	&"clutchmates": "e0a75a",
	&"good_perch": "71b99c",
	&"withdrawn": "d96e62",
}
const FLOCK_BOND_SYMBOLS := {
	&"clutchmates": "M32 51 C9 38 12 17 23 17 C29 17 32 22 32 25 C32 22 35 17 41 17 C52 17 55 38 32 51 Z",
	&"good_perch": "M25 20 C16 20 11 27 11 35 C11 43 17 49 25 49 H32 V42 H25 C21 42 18 39 18 35 C18 31 21 27 25 27 H34 V20 Z M39 15 H32 V22 H39 C43 22 46 25 46 29 C46 33 43 36 39 36 H30 V43 H39 C48 43 53 37 53 29 C53 21 47 15 39 15 Z",
	&"withdrawn": "M30 12 H37 L33 25 H44 L25 53 L30 35 H19 Z",
}

static var _hen_intent_texture_cache: Dictionary[String, Texture2D] = {}
static var _priority_peck_ready_halo_texture: Texture2D
static var _priority_peck_missed_halo_texture: Texture2D
static var _team_lift_marker_texture: Texture2D
static var _flock_bond_texture_cache: Dictionary[StringName, Texture2D] = {}
static var _dispatch_candidate_texture_cache: Dictionary[StringName, Texture2D] = {}

var worker_id: int = -1
var desk_index: int = -1

var _work_state: int = ChickenState.WorkState.IDLE
var _phase: float = 0.0
var _stress: float = 0.0
var _temperament_id: StringName = &"bright_eyed"
var _temperament_idle_style: int = 0
var _temperament_motion_scale: float = 1.0
var _temperament_focus_scale: float = 1.0
var _body_pivot: Node3D
var _head_pivot: Node3D
var _wing_left: Node3D
var _wing_right: Node3D
var _skeleton: Skeleton3D
var _wing_left_bone := -1
var _wing_right_bone := -1
var _wing_left_tip_bone := -1
var _wing_right_tip_bone := -1
var _use_authored_wing_pose := true
var _leg_left: Node3D
var _leg_right: Node3D
var _egg_socket: Node3D
var _neck_grip_socket: Node3D
var _head_rest_position := Vector3.ZERO
var _visual_root: Node3D
var _animation_player: AnimationPlayer
var _animation_names: Dictionary[StringName, StringName] = {}
var _active_model_animation: StringName = &""
var _presentation_update_interval := 0.0
var _presentation_update_accumulator := 0.0
var _presentation_update_count := 0
var _route: Array[Vector3] = []
var _route_index: int = 0
var _home_position := Vector3.ZERO
var _break_position := Vector3.ZERO
var _arrival_route: Array[Vector3] = []
var _break_route: Array[Vector3] = []
var _break_interaction_kind: StringName = &"rest"
var _break_interaction_face_point := Vector3.ZERO
var _break_cup: Node3D
var _break_cup_body: MeshInstance3D
var _break_cup_handle: MeshInstance3D
var _break_cup_liquid: MeshInstance3D
var _break_cup_steam: Array[MeshInstance3D] = []
var _break_magazine: Node3D
var _break_magazine_left_page: MeshInstance3D
var _break_magazine_right_page: MeshInstance3D
var _break_interaction_elapsed := 0.0
var _break_interaction_was_active := false
var _break_activity_phase: StringName = &"approach"
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
var _accessory_nodes: Dictionary[StringName, Node3D] = {}
var _visible_accessory_nodes: Array[Node3D] = []
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
var _secondary_motion_accessories: Array[Node3D] = []
var _secondary_motion_accessory_rest_rotations: Array[Vector3] = []
var _secondary_motion_accessory_sways: Array[bool] = []
var _seat_blend: float = 0.0
var _walk_blend: float = 0.0
var _work_blend: float = 0.0
var _lay_blend: float = 0.0
var _state_elapsed: float = 0.0
var _peck_assist_rating: StringName = &"steady"
var _priority_peck_timeline_active: bool = false
var _priority_peck_elapsed: float = 0.0
var _priority_peck_next_contact: int = 0
var _work_peck_contact_armed: bool = true
var _work_peck_contact_serial: int = 0
var _lay_feedback_active: bool = false
var _lay_feedback_elapsed: float = 0.0
var _lay_release_emitted: bool = false
var _lay_release_delay: float = LAY_RELEASE_FALLBACK_SECONDS
var _predator_captured := false
var _panic_active := false
var _panic_remaining := 0.0
var _panic_threat_origin := Vector3.ZERO
var _hen_intent_marker: Sprite3D
var _priority_peck_ready_halo: Sprite3D
var _team_lift_marker: Sprite3D
var _hen_intent: Dictionary = {}
var _hen_intent_transition_tween: Tween
var _priority_peck_ready_tween: Tween
var _team_lift_tween: Tween
var _last_hen_intent_key := ""
var _hen_intent_transition_serial := 0
var _priority_peck_ready_serial := 0
var _priority_peck_missed_serial := 0
var _team_lift_serial := 0
var _team_lift_receipt: Dictionary = {}
var _team_lift_marker_origin := Vector3.ZERO
var _priority_peck_halo_origin := Vector3.ZERO
var _reduced_motion := false
var _flock_bond_marker: Sprite3D
var _flock_bond: Dictionary = {}
var _dispatch_candidate_marker: Sprite3D
var _dispatch_candidate: Dictionary = {}
var _dispatch_recommendation_tween: Tween
var _dispatch_recommendation_serial := 0
var _dispatch_recommendation_active := false
var _dispatch_recommendation_animated := false
var _dispatch_recommendation_lane: StringName = &""


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


func configure_break_interaction(
	interaction_kind: StringName,
	face_point: Vector3,
) -> void:
	_break_interaction_kind = interaction_kind
	_break_interaction_face_point = face_point
	_break_interaction_elapsed = 0.0
	_break_interaction_was_active = false
	_break_activity_phase = &"approach"
	if _break_cup_body == null or _break_cup_handle == null:
		return
	var cup_color := (
		Color("d7eef0")
		if interaction_kind == &"water" else
		Color("c9895e")
	)
	var cup_material := StandardMaterial3D.new()
	cup_material.albedo_color = cup_color
	cup_material.roughness = 0.58
	_break_cup_body.material_override = cup_material
	_break_cup_handle.material_override = cup_material
	if _break_cup_liquid != null:
		var liquid_material := StandardMaterial3D.new()
		liquid_material.albedo_color = (
			Color("6fa9b1")
			if interaction_kind == &"water" else
			Color("633b28")
		)
		liquid_material.roughness = 0.30
		liquid_material.metallic = 0.08
		_break_cup_liquid.material_override = liquid_material


func break_interaction_state() -> Dictionary:
	return {
		"kind": String(_break_interaction_kind),
		"active": _is_break_interaction_active(),
		"phase": String(_break_activity_phase),
		"destination": str(_break_position),
		"face_point": str(_break_interaction_face_point),
		"held_cup_visible": _break_cup != null and _break_cup.visible,
		"held_reading_visible": _break_magazine != null and _break_magazine.visible,
	}


func break_interaction_active() -> bool:
	return _is_break_interaction_active()


func break_interaction_kind_name() -> StringName:
	return _break_interaction_kind


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
	var current_claim := worker_snapshot.get("current_claim", {}) as Dictionary
	_apply_hen_intent(
		worker_snapshot.get("hen_intent", {}) as Dictionary,
		float(worker_snapshot.get("progress", 0.0)) if not current_claim.is_empty() else -1.0,
	)
	_apply_flock_bond(worker_snapshot.get("flock_bond", {}) as Dictionary)
	_temperament_id = StringName(String(worker_snapshot.get(
		"temperament_id",
		ChickenState.default_temperament(worker_id),
	)))
	_temperament_idle_style = clampi(int(worker_snapshot.get(
		"temperament_idle_style",
		posmod(worker_id, ChickenState.TEMPERAMENT_ORDER.size()),
	)), 0, ChickenState.TEMPERAMENT_ORDER.size() - 1)
	_temperament_motion_scale = clampf(float(worker_snapshot.get(
		"temperament_motion_scale",
		1.0,
	)), 0.75, 1.25)
	_temperament_focus_scale = clampf(float(worker_snapshot.get(
		"temperament_focus_scale",
		1.0,
	)), 0.75, 1.25)
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


## Sets the cadence for visual-only imported animation and secondary-motion
## evaluation. Route movement and every gameplay-facing contact/release timeline
## continue at the physics rate. A non-positive rate restores per-frame visual
## sampling for the High preset.
func set_presentation_update_rate_hz(rate_hz: float) -> void:
	_presentation_update_interval = 1.0 / rate_hz if rate_hz > 0.0 else 0.0
	if _presentation_update_interval <= 0.0:
		_presentation_update_accumulator = 0.0
		return
	# Split workers across the available physics-frame slots. Without this
	# stable per-worker phase, all six skeletons wake on the same alternate
	# frame at 30 Hz, replacing redundant work with a visible CPU pulse.
	var presentation_slots := maxi(
		1,
		ceili(float(Engine.physics_ticks_per_second) / rate_hz),
	)
	var presentation_slot := posmod(worker_id, presentation_slots)
	_presentation_update_accumulator = (
		_presentation_update_interval
		* float(presentation_slot)
		/ float(presentation_slots)
	)


## Keeps semantic world-pin handoffs accessible without removing the state
## change itself. The preference may arrive before the marker is constructed.
func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if enabled:
		_reset_hen_intent_transition()
		_reset_priority_peck_ready_feedback()
		_reset_team_lift_feedback()
		_reset_dispatch_recommendation_handoff()


func presentation_update_rate_hz() -> float:
	if _presentation_update_interval <= 0.0:
		return 0.0
	return 1.0 / _presentation_update_interval


## On-demand instrumentation for scene-binding regressions. This allocates only
## when explicitly queried by a test or diagnostic; normal presentation frames
## read the cached Node3D and bone references directly.
func model_binding_diagnostics() -> Dictionary:
	var cached_wing_bones := 0
	for bone_index in [
		_wing_left_bone,
		_wing_right_bone,
		_wing_left_tip_bone,
		_wing_right_tip_bone,
	]:
		if bone_index >= 0:
			cached_wing_bones += 1
	return {
		"accessory_nodes_cached": _accessory_nodes.size(),
		"accessory_nodes_expected": ACCESSORY_NAMES.size(),
		"visible_accessory_nodes_cached": _visible_accessory_nodes.size(),
		"secondary_motion_accessories_cached": _secondary_motion_accessories.size(),
		"skeleton_cached": _skeleton != null,
		"wing_bones_cached": cached_wing_bones,
		"authored_wing_pose": _use_authored_wing_pose,
		"temperament_id": _temperament_id,
		"temperament_idle_style": _temperament_idle_style,
		"temperament_motion_scale": _temperament_motion_scale,
		"temperament_focus_scale": _temperament_focus_scale,
		"visible_shadow_casters": _visible_shadow_caster_count(),
		"presentation_update_rate_hz": presentation_update_rate_hz(),
		"presentation_update_count": _presentation_update_count,
	}


func play_peck_assist_feedback(rating: StringName) -> void:
	_reset_priority_peck_ready_feedback()
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
	_update_break_interaction_timeline(delta)
	_update_pose_blends(delta)
	# Hidden workers must continue routes and gameplay-facing contact timelines,
	# but their model transforms do not need to be rewritten until visible again.
	# The next visible physics frame derives the complete pose from current state.
	if not is_visible_in_tree():
		_presentation_update_accumulator = _presentation_update_interval
		return
	_presentation_update_accumulator += delta
	if (
		_presentation_update_interval > 0.0
		and _presentation_update_accumulator + 0.000001 < _presentation_update_interval
	):
		return
	var presentation_delta := (
		_presentation_update_accumulator
		if _presentation_update_interval > 0.0
		else delta
	)
	_presentation_update_accumulator = 0.0
	_presentation_update_count += 1
	_animate_pose()
	# Sample the imported body/head/leg clip before applying behavioral wing
	# deformation. In automatic mode AnimationPlayer evaluated later in the
	# frame and silently replaced the final behavioral wing pose.
	if _animation_player != null:
		_animation_player.advance(presentation_delta)
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
	_use_authored_wing_pose = false
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

	_advance_ambient_work_contact()

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


func _advance_ambient_work_contact() -> void:
	var can_contact := (
		_work_state == ChickenState.WorkState.WORKING
		and _is_at_workstation
		and not _is_walking
		and not _priority_peck_timeline_active
		and not _predator_captured
		and _seat_blend >= 0.92
		and _work_blend >= 0.72
	)
	if not can_contact:
		_work_peck_contact_armed = true
		return
	var peck_wave := _ambient_peck_wave()
	if peck_wave <= 0.24:
		_work_peck_contact_armed = true
	elif _work_peck_contact_armed and peck_wave >= 0.93:
		_work_peck_contact_armed = false
		_work_peck_contact_serial += 1
		work_peck_contact.emit(worker_id, _work_peck_contact_serial)


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
		elif _destination_kind == &"break":
			global_position = _break_position
			_face_point(_break_interaction_face_point, delta)
			if _feed_party_queued:
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
	_update_break_interaction_prop()
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
		_play_model_animation(
			ANIMATION_SIT
			if _break_interaction_kind == &"lounge" and _is_break_interaction_active() else
			ANIMATION_IDLE
		)
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
	_use_authored_wing_pose = true
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


func _apply_panic_pose() -> void:
	# ChickenView owns the live skeleton's wing pose, so mirror the authored
	# panic action here as well. This keeps the separate feather meshes flapping
	# in-game instead of allowing a procedural walk pose to override the clip.
	var flap := (sin(_phase * 18.0 + worker_id * 0.67) + 1.0) * 0.5
	_wing_left.rotation = Vector3(0.10, 0.0, lerpf(-0.12, 1.05, flap))
	_wing_right.rotation = Vector3(0.10, 0.0, lerpf(0.12, -1.05, flap))
	_use_authored_wing_pose = false
	_head_pivot.rotation.y += sin(_phase * 11.0 + worker_id) * 0.18


func _apply_seated_pose() -> void:
	# Ease onto the 0.54 m chair seat with a small anticipatory crouch. Folded
	# feet stay visibly below the belly instead of vanishing into the cushion.
	# The imported Blender clip owns the wing bones here, exactly as it does for
	# the manager chicken. Procedural work feedback stays on the connected torso
	# and head so it cannot disturb that known-good body-side silhouette.
	var seat := _seat_blend * _seat_blend * (3.0 - 2.0 * _seat_blend)
	var sit_crouch := sin(_seat_blend * PI) * 0.045
	_body_pivot.position.y = 0.55 * seat - sit_crouch
	_body_pivot.position.z = 0.035 * seat
	_body_pivot.rotation.x = lerpf(0.0, -0.075, seat)
	_leg_left.rotation.x = lerpf(0.0, -1.16, seat)
	_leg_right.rotation.x = lerpf(0.0, -1.16, seat)

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
				else _ambient_peck_wave()
			)
			var peck := peck_cycle * peck_cycle * _work_blend
			var assist_emphasis := (
				(0.075 if _peck_assist_rating == &"perfect" else 0.045)
				* priority_contact
			)
			_body_pivot.rotation.x += -0.045 - peck * (0.19 + assist_emphasis)
			_body_pivot.position.z += peck * (0.075 + assist_emphasis * 0.30)
			_body_pivot.position.y -= peck * (0.018 + assist_emphasis * 0.10)
			# HeadPivot owns the complete connected face rig. A small extra reach
			# therefore brings the beak toward the display without allowing eyes,
			# wattles, or accessories to lag behind the body during contact.
			_head_pivot.rotation.x -= peck * (0.10 + assist_emphasis * 0.30)
			_head_pivot.position.z += peck * (0.030 + assist_emphasis * 0.12)
		ChickenState.WorkState.LAYING:
			_apply_laying_pose()
		_:
			_head_pivot.rotation.x = sin(_phase * 1.4 * _temperament_motion_scale + worker_id) * 0.045


func _ambient_peck_wave() -> float:
	return maxf(
		0.0,
		sin(_phase * 10.6 * _temperament_focus_scale + worker_id * 0.31),
	)

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


func _apply_break_pose() -> void:
	var motion_phase := _phase * _temperament_motion_scale
	_body_pivot.position.y = absf(sin(motion_phase * 1.7 + worker_id)) * 0.018
	_body_pivot.rotation.z = sin(motion_phase * 0.72 + worker_id) * 0.018
	_head_pivot.rotation.y = sin(motion_phase * 0.85 + worker_id) * 0.24
	if _is_break_interaction_active():
		match _break_interaction_kind:
			&"water", &"coffee":
				var drink_time := maxf(0.0, _break_interaction_elapsed - 0.72)
				var drink_cycle := fmod(drink_time, 6.20)
				var raise_cup := smoothstep(0.35, 1.18, drink_cycle)
				raise_cup *= 1.0 - smoothstep(3.25, 4.08, drink_cycle)
				var sip := smoothstep(1.28, 1.72, drink_cycle)
				sip *= 1.0 - smoothstep(2.62, 3.08, drink_cycle)
				var collect_reach := 1.0 - smoothstep(0.36, 0.82, _break_interaction_elapsed)
				_body_pivot.rotation.x = -0.025 - sip * 0.055 - collect_reach * 0.035
				_head_pivot.rotation.x = -0.035 - sip * 0.20
				_head_pivot.position.z += sip * 0.042
				_wing_left.rotation = Vector3(
					0.16 + raise_cup * 0.12,
					0.0,
					-0.36 - raise_cup * 0.31 - collect_reach * 0.16,
				)
				_wing_right.rotation = Vector3(0.10, 0.0, 0.20)
				_use_authored_wing_pose = false
				if _break_cup != null:
					_break_cup.position = Vector3(
						-0.29,
						lerpf(0.58, 0.91, raise_cup),
						lerpf(0.39, 0.25, raise_cup),
					)
					_break_cup.rotation_degrees = Vector3(0.0, 0.0, -7.0 + sip * 13.0)
				for steam_index in _break_cup_steam.size():
					var steam := _break_cup_steam[steam_index]
					var steam_lift := fmod(
						_break_interaction_elapsed * 0.42 + steam_index * 0.37,
						0.72,
					)
					steam.position = Vector3(
						-0.025 + steam_index * 0.045,
						0.12 + steam_lift * 0.21,
						sin(motion_phase * 0.52 + steam_index) * 0.018,
					)
					var steam_scale := 0.55 + steam_lift * 0.42
					steam.scale = Vector3(steam_scale, 0.65 + steam_lift, steam_scale)
				return
			&"lounge":
				var settle_in := smoothstep(0.0, 0.85, _break_interaction_elapsed)
				var lounge_cycle := fmod(maxf(0.0, _break_interaction_elapsed - 0.85), 8.4)
				var stretch := smoothstep(5.75, 6.25, lounge_cycle)
				stretch *= 1.0 - smoothstep(7.10, 7.72, lounge_cycle)
				var breathe := (sin(motion_phase * 0.55 + worker_id) + 1.0) * 0.5
				_body_pivot.position.y = lerpf(0.08, 0.28, settle_in) + breathe * 0.012 + stretch * 0.035
				_body_pivot.position.z = 0.035
				_body_pivot.rotation.x = -0.08 + stretch * 0.06
				_leg_left.rotation.x = -1.16
				_leg_right.rotation.x = -1.16
				_head_pivot.rotation.x = -stretch * 0.09
				_head_pivot.rotation.y = sin(motion_phase * 0.42) * 0.16 + stretch * 0.11
				_head_pivot.rotation.z = sin(motion_phase * 0.31) * 0.045
				_wing_left.rotation.z = -stretch * 0.22
				_wing_right.rotation.z = stretch * 0.22
				_use_authored_wing_pose = stretch < 0.02
				return
			&"browse":
				var browse_cycle := fmod(maxf(0.0, _break_interaction_elapsed - 0.65), 7.2)
				var page_turn := smoothstep(4.45, 4.88, browse_cycle)
				page_turn *= 1.0 - smoothstep(5.38, 5.92, browse_cycle)
				var page_scan := (sin(motion_phase * 0.44 + worker_id) + 1.0) * 0.5
				_body_pivot.rotation.x = -0.10
				_head_pivot.rotation.x = -0.24 - page_scan * 0.08
				_head_pivot.rotation.y = lerpf(-0.18, 0.18, page_scan)
				_wing_left.rotation = Vector3(0.12, 0.0, -0.38)
				_wing_right.rotation = Vector3(0.12, 0.0, 0.36 + page_turn * 0.26)
				_use_authored_wing_pose = false
				if _break_magazine != null:
					_break_magazine.position = Vector3(-0.02, 0.76 + page_turn * 0.035, 0.50)
					_break_magazine.rotation_degrees = Vector3(-24.0, 0.0, 0.0)
					_break_magazine.scale = Vector3.ONE * 1.08
				if _break_magazine_right_page != null:
					_break_magazine_right_page.rotation_degrees.z = -page_turn * 28.0
					_break_magazine_right_page.position.y = page_turn * 0.045
				return
			&"bulletin":
				var note_scan := sin(motion_phase * 0.46 + worker_id)
				var bulletin_cycle := fmod(_break_interaction_elapsed, 6.8)
				var point_note := smoothstep(2.65, 3.10, bulletin_cycle)
				point_note *= 1.0 - smoothstep(4.02, 4.58, bulletin_cycle)
				_head_pivot.rotation.x = -0.08 + absf(note_scan) * 0.06
				_head_pivot.rotation.y = note_scan * 0.30
				_head_pivot.rotation.z = sin(motion_phase * 0.24) * 0.045
				_wing_left.rotation = Vector3(0.10, 0.0, -0.16 - point_note * 0.66)
				_use_authored_wing_pose = false
				return
			&"chat":
				var chat_cycle := fmod(_break_interaction_elapsed + worker_id * 0.31, 7.4)
				var gesture := smoothstep(2.45, 2.92, chat_cycle)
				gesture *= 1.0 - smoothstep(3.82, 4.42, chat_cycle)
				var listen := 1.0 - smoothstep(1.82, 2.45, chat_cycle)
				_head_pivot.rotation.y = sin(motion_phase * 0.58) * 0.12 + listen * 0.08
				_head_pivot.rotation.z = sin(motion_phase * 0.41) * 0.055
				_wing_left.rotation = Vector3(0.10, 0.0, -0.18 - gesture * 0.56)
				_wing_right.rotation = Vector3(0.08, 0.0, 0.16 + gesture * 0.18)
				_use_authored_wing_pose = false
				return
	match _temperament_idle_style:
		0: # Curious head tilts and a poised wing.
			_head_pivot.rotation.z = sin(motion_phase * 0.62) * 0.10
		1: # A reserved, compact accountant stance.
			_body_pivot.scale.x *= 0.992
			_head_pivot.rotation.x = -0.035 + sin(motion_phase * 0.48) * 0.025
		2: # Occasional preen gesture, unsynchronised across the flock.
			var preen := pow(maxf(0.0, sin(motion_phase * 0.42 + worker_id)), 5.0)
			_body_pivot.rotation.x -= preen * 0.07
		3: # Social scan: quick glances toward the neighboring perch.
			_head_pivot.rotation.y += sin(motion_phase * 1.35 + worker_id) * 0.16
			_head_pivot.rotation.z = sin(motion_phase * 0.92) * 0.055
		4: # Methodical file review: slow, repeated downward checks.
			var review := pow(maxf(0.0, sin(motion_phase * 0.68 + worker_id)), 3.0)
			_head_pivot.rotation.x = -0.04 - review * 0.10
		5: # Gentle rebel: still body, alert eyes, occasional skeptical tilt.
			_body_pivot.rotation.z *= 0.45
			var skepticism := pow(maxf(0.0, sin(motion_phase * 0.44 + worker_id)), 5.0)
			_head_pivot.rotation.z = skepticism * (-0.11 if posmod(worker_id, 2) == 0 else 0.11)


func _apply_feeding_pose() -> void:
	# The attendance sockets keep the breast outside the trough; the soft forward
	# tilt brings only the beak over the feed instead of clipping the whole bird.
	var peck := maxf(0.0, sin(_phase * 9.5 + worker_id * 0.7))
	_body_pivot.position.y = 0.045 - peck * 0.025
	_body_pivot.position.z = peck * 0.045
	_body_pivot.rotation.x = -0.16 - peck * 0.24


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
	_cache_accessory_nodes()
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
	_apply_character_shadow_budget()
	_career_credential_badge = _accessory_nodes.get(&"AccessoryBadge_GoldenEgg") as Node3D
	if _career_credential_badge != null:
		_career_credential_profile_visible = _career_credential_badge.visible
		_career_credential_rest_position = _career_credential_badge.position
	_cache_secondary_motion_parts()
	_build_hen_intent_marker()
	_build_break_interaction_prop()


func _build_break_interaction_prop() -> void:
	_break_cup = Node3D.new()
	_break_cup.name = "BreakInteractionCup"
	_break_cup.visible = false
	add_child(_break_cup)

	_break_cup_body = MeshInstance3D.new()
	_break_cup_body.name = "BreakInteractionCupBody"
	var cup_mesh := CylinderMesh.new()
	cup_mesh.top_radius = 0.09
	cup_mesh.bottom_radius = 0.075
	cup_mesh.height = 0.17
	cup_mesh.radial_segments = 12
	_break_cup_body.mesh = cup_mesh
	_break_cup_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_break_cup.add_child(_break_cup_body)

	_break_cup_handle = MeshInstance3D.new()
	_break_cup_handle.name = "BreakInteractionCupHandle"
	var handle_mesh := TorusMesh.new()
	handle_mesh.inner_radius = 0.025
	handle_mesh.outer_radius = 0.060
	handle_mesh.rings = 8
	handle_mesh.ring_segments = 5
	_break_cup_handle.mesh = handle_mesh
	_break_cup_handle.position = Vector3(-0.078, 0.0, 0.0)
	_break_cup_handle.rotation_degrees.z = 90.0
	_break_cup_handle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_break_cup.add_child(_break_cup_handle)

	_break_cup_liquid = MeshInstance3D.new()
	_break_cup_liquid.name = "BreakInteractionCupLiquid"
	var liquid_mesh := CylinderMesh.new()
	liquid_mesh.top_radius = 0.068
	liquid_mesh.bottom_radius = 0.068
	liquid_mesh.height = 0.008
	liquid_mesh.radial_segments = 12
	_break_cup_liquid.mesh = liquid_mesh
	_break_cup_liquid.position.y = 0.086
	_break_cup_liquid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_break_cup.add_child(_break_cup_liquid)
	for steam_index in 2:
		var steam := MeshInstance3D.new()
		steam.name = "BreakInteractionCupSteam_%02d" % steam_index
		var steam_mesh := SphereMesh.new()
		steam_mesh.radius = 0.022
		steam_mesh.height = 0.065
		steam_mesh.radial_segments = 8
		steam_mesh.rings = 4
		steam.mesh = steam_mesh
		var steam_material := StandardMaterial3D.new()
		steam_material.albedo_color = Color("eee8d7")
		steam_material.emission_enabled = true
		steam_material.emission = Color("b8aa94")
		steam_material.emission_energy_multiplier = 0.28
		steam.material_override = steam_material
		steam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_break_cup.add_child(steam)
		_break_cup_steam.append(steam)

	# Browsing now uses a physical open periodical between the wings instead of
	# relying on a downward head tilt to imply what the hen is doing.
	_break_magazine = Node3D.new()
	_break_magazine.name = "BreakInteractionMagazine"
	_break_magazine.visible = false
	add_child(_break_magazine)
	var page_material := StandardMaterial3D.new()
	page_material.albedo_color = Color("eee6cf")
	page_material.roughness = 0.88
	var cover_material := StandardMaterial3D.new()
	cover_material.albedo_color = Color("c7634d")
	cover_material.roughness = 0.72
	for page_index in 2:
		var cover_half := MeshInstance3D.new()
		cover_half.name = "BreakInteractionMagazineCover_%02d" % page_index
		var cover_half_mesh := BoxMesh.new()
		cover_half_mesh.size = Vector3(0.27, 0.012, 0.33)
		cover_half.mesh = cover_half_mesh
		cover_half.position = Vector3(-0.145 if page_index == 0 else 0.145, -0.017, 0.0)
		cover_half.material_override = cover_material
		cover_half.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_break_magazine.add_child(cover_half)
		var page := MeshInstance3D.new()
		page.name = "BreakInteractionMagazinePage_%02d" % page_index
		var page_mesh := BoxMesh.new()
		page_mesh.size = Vector3(0.25, 0.018, 0.31)
		page.mesh = page_mesh
		page.position.x = -0.135 if page_index == 0 else 0.135
		page.material_override = page_material
		page.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_break_magazine.add_child(page)
		if page_index == 0:
			_break_magazine_left_page = page
		else:
			_break_magazine_right_page = page
		for line_index in 3:
			var print_line := MeshInstance3D.new()
			print_line.name = "BreakInteractionMagazinePrint_%02d_%02d" % [page_index, line_index]
			var print_mesh := BoxMesh.new()
			print_mesh.size = Vector3(0.13, 0.007, 0.014)
			print_line.mesh = print_mesh
			print_line.position = Vector3(
				-0.135 if page_index == 0 else 0.135,
				0.014,
				-0.085 + line_index * 0.072,
			)
			print_line.material_override = cover_material
			print_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_break_magazine.add_child(print_line)
	var magazine_spine := MeshInstance3D.new()
	magazine_spine.name = "BreakInteractionMagazineSpine"
	var spine_mesh := BoxMesh.new()
	spine_mesh.size = Vector3(0.025, 0.026, 0.33)
	magazine_spine.mesh = spine_mesh
	magazine_spine.material_override = cover_material
	magazine_spine.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_break_magazine.add_child(magazine_spine)
	var magazine_masthead := MeshInstance3D.new()
	magazine_masthead.name = "BreakInteractionMagazineMasthead"
	var masthead_mesh := BoxMesh.new()
	masthead_mesh.size = Vector3(0.17, 0.008, 0.062)
	magazine_masthead.mesh = masthead_mesh
	magazine_masthead.position = Vector3(-0.135, 0.018, -0.092)
	var masthead_material := StandardMaterial3D.new()
	masthead_material.albedo_color = Color("3f746f")
	masthead_material.roughness = 0.68
	magazine_masthead.material_override = masthead_material
	magazine_masthead.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_break_magazine.add_child(magazine_masthead)
	configure_break_interaction(_break_interaction_kind, _break_interaction_face_point)


func _is_break_interaction_active() -> bool:
	return (
		_destination_kind == &"break"
		and not _is_walking
		and _route_index >= _route.size()
		and global_position.distance_to(_break_position) <= ARRIVAL_DISTANCE * 2.0
	)


func _update_break_interaction_timeline(delta: float) -> void:
	var active := _is_break_interaction_active()
	if active:
		_break_interaction_elapsed = (
			_break_interaction_elapsed + delta
			if _break_interaction_was_active else
			0.0
		)
	else:
		_break_interaction_elapsed = 0.0
	_break_interaction_was_active = active
	_break_activity_phase = _resolve_break_activity_phase() if active else &"approach"


func _resolve_break_activity_phase() -> StringName:
	match _break_interaction_kind:
		&"water", &"coffee":
			if _break_interaction_elapsed < 0.72:
				return &"collect"
			var drink_cycle := fmod(_break_interaction_elapsed - 0.72, 6.20)
			if drink_cycle < 1.28:
				return &"raise"
			if drink_cycle < 3.08:
				return &"sip"
			if drink_cycle < 4.25:
				return &"lower"
			return &"savor"
		&"lounge":
			if _break_interaction_elapsed < 0.85:
				return &"settle"
			var lounge_cycle := fmod(_break_interaction_elapsed - 0.85, 8.4)
			return &"stretch" if lounge_cycle >= 5.75 and lounge_cycle < 7.72 else &"rest"
		&"browse":
			if _break_interaction_elapsed < 0.65:
				return &"pick_up"
			var browse_cycle := fmod(_break_interaction_elapsed - 0.65, 7.2)
			return &"turn_page" if browse_cycle >= 4.45 and browse_cycle < 5.92 else &"read"
		&"bulletin":
			var bulletin_cycle := fmod(_break_interaction_elapsed, 6.8)
			if bulletin_cycle >= 2.65 and bulletin_cycle < 4.58:
				return &"point"
			return &"consider" if bulletin_cycle >= 4.58 else &"scan"
		&"chat":
			var chat_cycle := fmod(_break_interaction_elapsed + worker_id * 0.31, 7.4)
			if chat_cycle >= 2.45 and chat_cycle < 4.42:
				return &"respond"
			return &"listen" if chat_cycle < 2.45 else &"pause"
	return &"rest"


func _update_break_interaction_prop() -> void:
	if _break_cup == null:
		return
	var drink_visible := (
		_is_break_interaction_active()
		and (
			_break_interaction_kind == &"water"
			or _break_interaction_kind == &"coffee"
		)
	)
	_break_cup.visible = drink_visible
	if _break_cup_liquid != null:
		_break_cup_liquid.visible = drink_visible
	for steam in _break_cup_steam:
		steam.visible = drink_visible and _break_interaction_kind == &"coffee"
	if _break_magazine != null:
		_break_magazine.visible = (
			_is_break_interaction_active()
			and _break_interaction_kind == &"browse"
		)


func _build_hen_intent_marker() -> void:
	_priority_peck_ready_halo = Sprite3D.new()
	_priority_peck_ready_halo.name = "PriorityPeckReadyHalo"
	var height_offset := float(
		HEN_INTENT_HEIGHT_OFFSETS[posmod(worker_id, HEN_INTENT_HEIGHT_OFFSETS.size())]
	)
	_priority_peck_ready_halo.position = Vector3(
		0.0,
		HEN_INTENT_BASE_HEIGHT + height_offset,
		0.0,
	)
	_priority_peck_halo_origin = _priority_peck_ready_halo.position
	_priority_peck_ready_halo.pixel_size = HEN_INTENT_URGENT_PIXEL_SIZE
	_priority_peck_ready_halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_priority_peck_ready_halo.no_depth_test = true
	_priority_peck_ready_halo.render_priority = 19
	_priority_peck_ready_halo.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_priority_peck_ready_halo.texture = _priority_peck_halo_texture()
	_priority_peck_ready_halo.visible = false
	add_child(_priority_peck_ready_halo)
	_team_lift_marker = Sprite3D.new()
	_team_lift_marker.name = "TeamLiftMarker"
	_team_lift_marker.position = Vector3(
		0.0,
		HEN_INTENT_BASE_HEIGHT + height_offset + 0.38,
		0.0,
	)
	_team_lift_marker_origin = _team_lift_marker.position
	_team_lift_marker.pixel_size = 0.0094
	_team_lift_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_team_lift_marker.no_depth_test = true
	_team_lift_marker.render_priority = 23
	_team_lift_marker.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_team_lift_marker.texture = _team_lift_texture()
	_team_lift_marker.visible = false
	add_child(_team_lift_marker)
	_hen_intent_marker = Sprite3D.new()
	_hen_intent_marker.name = "HenIntentMarker"
	_hen_intent_marker.position = Vector3(
		0.0,
		HEN_INTENT_BASE_HEIGHT + height_offset,
		0.0,
	)
	_hen_intent_marker.pixel_size = HEN_INTENT_STANDARD_PIXEL_SIZE
	_hen_intent_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hen_intent_marker.no_depth_test = true
	_hen_intent_marker.render_priority = 20
	_hen_intent_marker.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_hen_intent_marker.visible = false
	_hen_intent_marker.set_meta("height_offset", height_offset)
	add_child(_hen_intent_marker)
	_flock_bond_marker = Sprite3D.new()
	_flock_bond_marker.name = "FlockBondMarker"
	_flock_bond_marker.position = Vector3(-0.42, 1.56, 0.0)
	_flock_bond_marker.pixel_size = 0.0072
	_flock_bond_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_flock_bond_marker.no_depth_test = true
	_flock_bond_marker.render_priority = 19
	_flock_bond_marker.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_flock_bond_marker.visible = false
	add_child(_flock_bond_marker)
	_dispatch_candidate_marker = Sprite3D.new()
	_dispatch_candidate_marker.name = "DispatchCandidateMarker"
	_dispatch_candidate_marker.position = Vector3(0.0, 2.22, 0.0)
	_dispatch_candidate_marker.pixel_size = 0.0105
	_dispatch_candidate_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_dispatch_candidate_marker.no_depth_test = true
	_dispatch_candidate_marker.render_priority = 22
	_dispatch_candidate_marker.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_dispatch_candidate_marker.visible = false
	add_child(_dispatch_candidate_marker)


## Highlights this hen while a physical intake tray is waiting for dispatch.
## A gold star is the ranked recommendation; eligible alternatives use a teal
## downward chevron so the action reads without another explanatory panel.
func set_dispatch_candidate(
	active: bool,
	recommended: bool = false,
	lane: StringName = &"",
) -> void:
	_reset_dispatch_recommendation_handoff()
	_dispatch_candidate = {
		"active": active,
		"recommended": recommended,
		"lane": lane,
	}
	if _dispatch_candidate_marker == null:
		return
	_dispatch_candidate_marker.visible = active
	_dispatch_candidate_marker.set_meta("recommended", recommended)
	_dispatch_candidate_marker.set_meta("lane", lane)
	_dispatch_candidate_marker.set_meta("handoff_active", false)
	_dispatch_candidate_marker.set_meta("handoff_animated", false)
	if not active:
		_dispatch_candidate_marker.texture = null
		return
	var kind: StringName = &"recommended" if recommended else &"eligible"
	_dispatch_candidate_marker.texture = _dispatch_candidate_texture(kind)
	_dispatch_candidate_marker.modulate = Color.WHITE


func dispatch_candidate_snapshot() -> Dictionary:
	var result := _dispatch_candidate.duplicate(true)
	result["worker_id"] = worker_id
	result["marker_visible"] = (
		_dispatch_candidate_marker != null and _dispatch_candidate_marker.visible
	)
	result["handoff_serial"] = _dispatch_recommendation_serial
	result["handoff_active"] = _dispatch_recommendation_active
	result["handoff_animated"] = _dispatch_recommendation_animated
	result["handoff_lane"] = String(_dispatch_recommendation_lane)
	return result


## Gives a newly selected intake tray one restrained cause-and-effect handoff
## to its ranked hen. The gold marker remains after the pulse; this does not
## select the hen, move the camera, or invalidate any teal alternative.
func play_dispatch_recommendation_handoff(lane: StringName) -> bool:
	_reset_dispatch_recommendation_handoff()
	if (
		_dispatch_candidate_marker == null
		or not bool(_dispatch_candidate.get("active", false))
		or not bool(_dispatch_candidate.get("recommended", false))
		or StringName(_dispatch_candidate.get("lane", &"")) != lane
	):
		return false
	_dispatch_recommendation_serial += 1
	_dispatch_recommendation_active = true
	_dispatch_recommendation_animated = not _reduced_motion and is_inside_tree()
	_dispatch_recommendation_lane = lane
	_dispatch_candidate_marker.visible = true
	_dispatch_candidate_marker.set_meta("handoff_serial", _dispatch_recommendation_serial)
	_dispatch_candidate_marker.set_meta("handoff_active", true)
	_dispatch_candidate_marker.set_meta("handoff_animated", _dispatch_recommendation_animated)
	_dispatch_candidate_marker.set_meta("handoff_lane", lane)
	if not _dispatch_recommendation_animated:
		# Preserve the same semantic receipt without scale motion.
		_dispatch_candidate_marker.scale = Vector3.ONE
		_dispatch_candidate_marker.modulate = Color(1.0, 0.92, 0.68, 1.0)
		if is_inside_tree():
			_dispatch_recommendation_tween = create_tween().bind_node(_dispatch_candidate_marker)
			_dispatch_recommendation_tween.tween_interval(DISPATCH_HANDOFF_STATIC_SECONDS)
			_dispatch_recommendation_tween.tween_callback(_finish_dispatch_recommendation_handoff)
		else:
			_finish_dispatch_recommendation_handoff()
		return false
	_dispatch_candidate_marker.scale = DISPATCH_HANDOFF_START_SCALE
	_dispatch_candidate_marker.modulate = Color(1.0, 0.86, 0.46, 1.0)
	_dispatch_recommendation_tween = create_tween().bind_node(_dispatch_candidate_marker)
	_dispatch_recommendation_tween.tween_property(
		_dispatch_candidate_marker,
		"scale",
		DISPATCH_HANDOFF_PEAK_SCALE,
		DISPATCH_HANDOFF_RISE_SECONDS,
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_dispatch_recommendation_tween.parallel().tween_property(
		_dispatch_candidate_marker,
		"modulate",
		Color.WHITE,
		DISPATCH_HANDOFF_RISE_SECONDS,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_dispatch_recommendation_tween.tween_property(
		_dispatch_candidate_marker,
		"scale",
		Vector3.ONE,
		DISPATCH_HANDOFF_SETTLE_SECONDS,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_dispatch_recommendation_tween.tween_callback(_finish_dispatch_recommendation_handoff)
	return true


func _finish_dispatch_recommendation_handoff() -> void:
	_dispatch_recommendation_tween = null
	_dispatch_recommendation_active = false
	if _dispatch_candidate_marker != null:
		_dispatch_candidate_marker.scale = Vector3.ONE
		_dispatch_candidate_marker.modulate = Color.WHITE
		_dispatch_candidate_marker.set_meta("handoff_active", false)


func _reset_dispatch_recommendation_handoff() -> void:
	if _dispatch_recommendation_tween != null and _dispatch_recommendation_tween.is_valid():
		_dispatch_recommendation_tween.kill()
	_dispatch_recommendation_tween = null
	_dispatch_recommendation_active = false
	_dispatch_recommendation_animated = false
	if _dispatch_candidate_marker != null:
		_dispatch_candidate_marker.scale = Vector3.ONE
		_dispatch_candidate_marker.modulate = Color.WHITE
		_dispatch_candidate_marker.set_meta("handoff_active", false)
		_dispatch_candidate_marker.set_meta("handoff_animated", false)


func _dispatch_candidate_texture(kind: StringName) -> Texture2D:
	if _dispatch_candidate_texture_cache.has(kind):
		return _dispatch_candidate_texture_cache[kind]
	var fill := "d6ad4d" if kind == &"recommended" else "58a99b"
	var symbol := (
		HEN_INTENT_SYMBOLS[&"match"]
		if kind == &"recommended" else
		"M14 18 H50 V30 H42 L32 46 L22 30 H14 Z"
	)
	var svg := (
		"<svg xmlns='http://www.w3.org/2000/svg' width='64' height='64' viewBox='0 0 64 64'>"
		+ "<circle cx='32' cy='32' r='29' fill='#101a21' fill-opacity='.94' stroke='#fff0b8' stroke-width='3'/>"
		+ "<circle cx='32' cy='32' r='23' fill='#%s'/>" % fill
		+ "<path d='%s' fill='#fff8dc' fill-rule='evenodd'/>" % symbol
		+ "</svg>"
	)
	var image := Image.new()
	if image.load_svg_from_string(svg, 1.0) != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_dispatch_candidate_texture_cache[kind] = texture
	return texture


func _apply_hen_intent(intent: Dictionary, progress: float = -1.0) -> void:
	_hen_intent = intent.duplicate(true)
	if _hen_intent_marker == null:
		return
	var icon := StringName(String(intent.get("icon", "")))
	_hen_intent_marker.visible = icon in HEN_INTENT_SYMBOLS
	if not _hen_intent_marker.visible:
		_reset_hen_intent_transition()
		_reset_priority_peck_ready_feedback()
		_last_hen_intent_key = ""
		_hen_intent_marker.texture = null
		return
	var action_id := StringName(String(intent.get("action_id", "route")))
	var action_label := String(intent.get("action_label", "OPEN")).to_upper()
	var intent_key := "%s|%s|%s" % [String(icon), String(action_id), action_label]
	var previous_intent_key := _last_hen_intent_key
	var progress_bucket := (
		clampi(ceili(clampf(progress, 0.0, 100.0) / 20.0), 0, 5)
		if progress >= 0.0 else
		-1
	)
	var urgency := clampi(int(intent.get("urgency", 1)), 1, 3)
	_hen_intent_marker.pixel_size = (
		HEN_INTENT_URGENT_PIXEL_SIZE
		if urgency >= 3 else
		HEN_INTENT_STANDARD_PIXEL_SIZE
		if urgency == 2 else
		HEN_INTENT_COMPACT_PIXEL_SIZE
	)
	_hen_intent_marker.texture = hen_intent_icon_texture(icon, progress_bucket, urgency)
	_hen_intent_marker.set_meta("progress_bucket", progress_bucket)
	_hen_intent_marker.set_meta("urgency", urgency)
	_hen_intent_marker.set_meta("compact", urgency == 1)
	_hen_intent_marker.set_meta("intent_id", StringName(String(intent.get("id", ""))))
	_hen_intent_marker.set_meta("action_label", action_label)
	_last_hen_intent_key = intent_key
	if previous_intent_key.is_empty():
		_reset_hen_intent_transition()
	elif previous_intent_key != intent_key:
		_play_hen_intent_transition(previous_intent_key, intent_key, urgency)


func _play_hen_intent_transition(from_key: String, to_key: String, urgency: int) -> void:
	_reset_hen_intent_transition()
	_hen_intent_transition_serial += 1
	var should_animate := not _reduced_motion and is_inside_tree()
	_hen_intent_marker.set_meta("intent_transition_serial", _hen_intent_transition_serial)
	_hen_intent_marker.set_meta("intent_transition_from", from_key)
	_hen_intent_marker.set_meta("intent_transition_to", to_key)
	_hen_intent_marker.set_meta("intent_transition_animated", should_animate)
	if not should_animate:
		return
	var transition_color := Color("8dcfbd")
	if urgency >= 3:
		transition_color = Color("f1d681")
	elif urgency == 2:
		transition_color = Color("e6a07e")
	_hen_intent_marker.scale = HEN_INTENT_HANDOFF_SCALE
	_hen_intent_marker.modulate = transition_color.lightened(0.24)
	_hen_intent_transition_tween = create_tween().bind_node(_hen_intent_marker).set_parallel(true)
	_hen_intent_transition_tween.tween_property(
		_hen_intent_marker,
		"scale",
		Vector3.ONE,
		HEN_INTENT_HANDOFF_SCALE_SECONDS,
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hen_intent_transition_tween.tween_property(
		_hen_intent_marker,
		"modulate",
		Color.WHITE,
		HEN_INTENT_HANDOFF_COLOR_SECONDS,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _reset_hen_intent_transition() -> void:
	if _hen_intent_transition_tween != null and _hen_intent_transition_tween.is_valid():
		_hen_intent_transition_tween.kill()
	_hen_intent_transition_tween = null
	if _hen_intent_marker != null:
		_hen_intent_marker.scale = Vector3.ONE
		_hen_intent_marker.modulate = Color.WHITE
		_hen_intent_marker.set_meta("intent_transition_animated", false)


## Mirrors the restrained opportunity motif with one no-text ring behind the
## selected hen's existing intent pin. Office owns the single-fire transition;
## this view owns only the bounded world-space presentation.
func play_priority_peck_ready_feedback() -> bool:
	_reset_priority_peck_ready_feedback()
	_priority_peck_ready_serial += 1
	var should_animate := (
		not _reduced_motion
		and is_inside_tree()
		and _hen_intent_marker != null
		and _hen_intent_marker.visible
		and _priority_peck_ready_halo != null
	)
	if _hen_intent_marker != null:
		_hen_intent_marker.set_meta("priority_peck_ready_serial", _priority_peck_ready_serial)
		_hen_intent_marker.set_meta("priority_peck_ready_animated", should_animate)
		_hen_intent_marker.set_meta("priority_peck_ready_active", should_animate)
	if not should_animate:
		return false
	_priority_peck_ready_halo.visible = true
	_priority_peck_ready_halo.scale = Vector3(0.88, 0.88, 0.88)
	_priority_peck_ready_halo.modulate = Color(1.0, 0.84, 0.38, 0.86)
	_priority_peck_ready_halo.set_meta("pulse_serial", _priority_peck_ready_serial)
	_priority_peck_ready_tween = create_tween().bind_node(_priority_peck_ready_halo)
	_priority_peck_ready_tween.set_parallel(true)
	_priority_peck_ready_tween.tween_property(
		_priority_peck_ready_halo,
		"scale",
		PRIORITY_PECK_READY_HALO_SCALE,
		PRIORITY_PECK_READY_HALO_SECONDS,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_priority_peck_ready_tween.tween_property(
		_priority_peck_ready_halo,
		"modulate:a",
		0.0,
		PRIORITY_PECK_READY_HALO_SECONDS,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_priority_peck_ready_tween.chain().tween_callback(_finish_priority_peck_ready_feedback)
	return true


## Closes an inspected opportunity with a broken ring that contracts and drops
## away from the same world pin. The opposing shape and direction communicate a
## miss without relying on color or adding another label over the floor.
func play_priority_peck_missed_feedback() -> bool:
	_reset_priority_peck_ready_feedback()
	_priority_peck_missed_serial += 1
	var should_animate := (
		not _reduced_motion
		and is_inside_tree()
		and _hen_intent_marker != null
		and _hen_intent_marker.visible
		and _priority_peck_ready_halo != null
	)
	if _hen_intent_marker != null:
		_hen_intent_marker.set_meta("priority_peck_missed_serial", _priority_peck_missed_serial)
		_hen_intent_marker.set_meta("priority_peck_missed_animated", should_animate)
		_hen_intent_marker.set_meta("priority_peck_missed_active", should_animate)
	if not should_animate:
		return false
	_priority_peck_ready_halo.texture = _priority_peck_missed_texture()
	_priority_peck_ready_halo.visible = true
	_priority_peck_ready_halo.position = _priority_peck_halo_origin
	_priority_peck_ready_halo.scale = Vector3(1.34, 1.34, 1.34)
	_priority_peck_ready_halo.modulate = Color(1.0, 1.0, 1.0, 0.9)
	_priority_peck_ready_halo.set_meta("missed_serial", _priority_peck_missed_serial)
	_priority_peck_ready_tween = create_tween().bind_node(_priority_peck_ready_halo)
	_priority_peck_ready_tween.set_parallel(true)
	_priority_peck_ready_tween.tween_property(
		_priority_peck_ready_halo,
		"scale",
		PRIORITY_PECK_MISSED_HALO_SCALE,
		PRIORITY_PECK_MISSED_HALO_SECONDS,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_priority_peck_ready_tween.tween_property(
		_priority_peck_ready_halo,
		"position",
		_priority_peck_halo_origin + Vector3(0.0, -0.16, 0.0),
		PRIORITY_PECK_MISSED_HALO_SECONDS,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_priority_peck_ready_tween.tween_property(
		_priority_peck_ready_halo,
		"modulate:a",
		0.0,
		PRIORITY_PECK_MISSED_HALO_SECONDS,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_priority_peck_ready_tween.chain().tween_callback(_finish_priority_peck_ready_feedback)
	return true


## Holds the authored midpoint only for deterministic screenshot fixtures. Live
## play always uses the bounded tween above and never leaves this halo resident.
func stage_priority_peck_ready_capture() -> bool:
	_reset_priority_peck_ready_feedback()
	if (
		_hen_intent_marker == null
		or not _hen_intent_marker.visible
		or _priority_peck_ready_halo == null
	):
		return false
	_priority_peck_ready_halo.visible = true
	_priority_peck_ready_halo.scale = Vector3(1.26, 1.26, 1.26)
	_priority_peck_ready_halo.modulate = Color(1.0, 0.84, 0.38, 0.72)
	_hen_intent_marker.set_meta("priority_peck_ready_active", true)
	_hen_intent_marker.set_meta("priority_peck_ready_capture_staged", true)
	return true


## Capture-only midpoint for the real broken-ring retreat. Runtime misses always
## use `play_priority_peck_missed_feedback` and settle within the bounded beat.
func stage_priority_peck_missed_capture() -> bool:
	_reset_priority_peck_ready_feedback()
	if (
		_hen_intent_marker == null
		or not _hen_intent_marker.visible
		or _priority_peck_ready_halo == null
	):
		return false
	_priority_peck_ready_halo.texture = _priority_peck_missed_texture()
	_priority_peck_ready_halo.visible = true
	_priority_peck_ready_halo.position = _priority_peck_halo_origin + Vector3(0.0, -0.08, 0.0)
	_priority_peck_ready_halo.scale = Vector3(1.16, 1.16, 1.16)
	_priority_peck_ready_halo.modulate = Color(1.0, 1.0, 1.0, 0.84)
	_hen_intent_marker.set_meta("priority_peck_missed_active", true)
	_hen_intent_marker.set_meta("priority_peck_missed_capture_staged", true)
	return true


func _finish_priority_peck_ready_feedback() -> void:
	_priority_peck_ready_tween = null
	if _priority_peck_ready_halo != null:
		_priority_peck_ready_halo.visible = false
	if _hen_intent_marker != null:
		_hen_intent_marker.set_meta("priority_peck_ready_active", false)
		_hen_intent_marker.set_meta("priority_peck_ready_capture_staged", false)
		_hen_intent_marker.set_meta("priority_peck_missed_active", false)
		_hen_intent_marker.set_meta("priority_peck_missed_capture_staged", false)


func _reset_priority_peck_ready_feedback() -> void:
	if _priority_peck_ready_tween != null and _priority_peck_ready_tween.is_valid():
		_priority_peck_ready_tween.kill()
	_priority_peck_ready_tween = null
	if _priority_peck_ready_halo != null:
		_priority_peck_ready_halo.visible = false
		_priority_peck_ready_halo.position = _priority_peck_halo_origin
		_priority_peck_ready_halo.scale = Vector3.ONE
		_priority_peck_ready_halo.modulate = Color.WHITE
		_priority_peck_ready_halo.texture = _priority_peck_halo_texture()
	if _hen_intent_marker != null:
		_hen_intent_marker.set_meta("priority_peck_ready_active", false)
		_hen_intent_marker.set_meta("priority_peck_ready_capture_staged", false)
		_hen_intent_marker.set_meta("priority_peck_missed_active", false)
		_hen_intent_marker.set_meta("priority_peck_missed_capture_staged", false)


## Marks the exact hens changed by the authoritative x10 Team Lift receipt.
## The shared icon is deliberately compact: the routing strip carries the
## numbers while matching world markers answer "who received it?" at a glance.
func play_team_lift_feedback(receipt: Dictionary) -> bool:
	_reset_team_lift_feedback()
	if _team_lift_marker == null:
		return false
	_team_lift_serial += 1
	_team_lift_receipt = receipt.duplicate(true)
	var authority_key := String(receipt.get("authority_key", ""))
	_team_lift_marker.visible = true
	_team_lift_marker.position = _team_lift_marker_origin
	_team_lift_marker.scale = Vector3.ONE * (1.0 if _reduced_motion else 0.72)
	_team_lift_marker.modulate = Color(1.0, 1.0, 1.0, 0.94)
	_team_lift_marker.set_meta("active", true)
	_team_lift_marker.set_meta("serial", _team_lift_serial)
	_team_lift_marker.set_meta("authority_key", authority_key)
	_team_lift_marker.set_meta("worker_id", worker_id)
	_team_lift_marker.set_meta("morale_delta", float(receipt.get("morale_delta", 0.0)))
	_team_lift_marker.set_meta("stress_delta", float(receipt.get("stress_delta", 0.0)))
	_team_lift_marker.set_meta("fatigue_delta", float(receipt.get("fatigue_delta", 0.0)))
	_team_lift_marker.set_meta("animated", not _reduced_motion)
	_team_lift_marker.set_meta("capture_staged", false)
	_team_lift_tween = create_tween().bind_node(_team_lift_marker)
	if _reduced_motion:
		# Hold a static receipt with no travel, scale, flash, or other motion.
		_team_lift_tween.tween_interval(1.10)
	else:
		_team_lift_tween.set_parallel(true)
		_team_lift_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_team_lift_tween.tween_property(
			_team_lift_marker,
			"scale",
			Vector3.ONE * 1.10,
			0.22,
		)
		_team_lift_tween.tween_property(
			_team_lift_marker,
			"position",
			_team_lift_marker_origin + Vector3(0.0, 0.28, 0.0),
			0.86,
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_team_lift_tween.tween_property(
			_team_lift_marker,
			"modulate:a",
			0.0,
			0.34,
		).set_delay(0.60).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_team_lift_tween.chain().tween_callback(_finish_team_lift_feedback)
	return true


func stage_team_lift_capture() -> bool:
	if _team_lift_marker == null or not _team_lift_marker.visible:
		return false
	if _team_lift_tween != null and _team_lift_tween.is_valid():
		_team_lift_tween.pause()
	_team_lift_marker.position = _team_lift_marker_origin + Vector3(0.0, 0.16, 0.0)
	_team_lift_marker.scale = Vector3.ONE
	_team_lift_marker.modulate = Color.WHITE
	_team_lift_marker.set_meta("capture_staged", true)
	return true


func team_lift_feedback_state() -> Dictionary:
	return {
		"active": _team_lift_marker != null and _team_lift_marker.visible,
		"serial": _team_lift_serial,
		"animated": bool(_team_lift_marker.get_meta("animated", false)) if _team_lift_marker != null else false,
		"capture_staged": bool(_team_lift_marker.get_meta("capture_staged", false)) if _team_lift_marker != null else false,
		"receipt": _team_lift_receipt.duplicate(true),
	}


func _finish_team_lift_feedback() -> void:
	_team_lift_tween = null
	if _team_lift_marker != null:
		_team_lift_marker.visible = false
		_team_lift_marker.set_meta("active", false)
		_team_lift_marker.set_meta("capture_staged", false)


func _reset_team_lift_feedback() -> void:
	if _team_lift_tween != null and _team_lift_tween.is_valid():
		_team_lift_tween.kill()
	_team_lift_tween = null
	if _team_lift_marker != null:
		_team_lift_marker.visible = false
		_team_lift_marker.position = _team_lift_marker_origin
		_team_lift_marker.scale = Vector3.ONE
		_team_lift_marker.modulate = Color.WHITE
		_team_lift_marker.set_meta("active", false)
		_team_lift_marker.set_meta("capture_staged", false)


static func _team_lift_texture() -> Texture2D:
	if _team_lift_marker_texture != null:
		return _team_lift_marker_texture
	# Heart + three upward chevrons reads as one flock-wide recovery token.
	var svg := (
		"<svg xmlns='http://www.w3.org/2000/svg' width='72' height='72' viewBox='0 0 72 72'>"
		+ "<circle cx='36' cy='36' r='32' fill='#101a21' fill-opacity='.95' stroke='#fff0b8' stroke-width='3'/>"
		+ "<path d='M36 57 L16 38 C6 25 15 12 27 16 C32 18 35 23 36 27 C37 23 40 18 45 16 C57 12 66 25 56 38 Z' fill='#d9778b'/>"
		+ "<path d='M22 38 L27 32 L32 38 M30 45 L36 38 L42 45 M40 38 L45 32 L50 38' fill='none' stroke='#fff9df' stroke-width='4' stroke-linecap='round' stroke-linejoin='round'/>"
		+ "</svg>"
	)
	var image := Image.new()
	if image.load_svg_from_string(svg, 1.0) != OK:
		return null
	_team_lift_marker_texture = ImageTexture.create_from_image(image)
	return _team_lift_marker_texture


static func _priority_peck_halo_texture() -> Texture2D:
	if _priority_peck_ready_halo_texture != null:
		return _priority_peck_ready_halo_texture
	var svg := (
		"<svg xmlns='http://www.w3.org/2000/svg' width='64' height='64' viewBox='0 0 64 64'>"
		+ "<circle cx='32' cy='32' r='27' fill='none' stroke='#f1d681' stroke-opacity='.92' stroke-width='4'/>"
		+ "<circle cx='32' cy='32' r='22' fill='none' stroke='#fff0b8' stroke-opacity='.52' stroke-width='2'/>"
		+ "</svg>"
	)
	var image := Image.new()
	if image.load_svg_from_string(svg, 1.0) != OK:
		return null
	_priority_peck_ready_halo_texture = ImageTexture.create_from_image(image)
	return _priority_peck_ready_halo_texture


static func _priority_peck_missed_texture() -> Texture2D:
	if _priority_peck_missed_halo_texture != null:
		return _priority_peck_missed_halo_texture
	var svg := (
		"<svg xmlns='http://www.w3.org/2000/svg' width='64' height='64' viewBox='0 0 64 64'>"
		+ "<path d='M6 27 A27 27 0 0 1 24 7' fill='none' stroke='#d96e62' stroke-width='4.5' stroke-linecap='round'/>"
		+ "<path d='M40 7 A27 27 0 0 1 58 27' fill='none' stroke='#d96e62' stroke-width='4.5' stroke-linecap='round'/>"
		+ "<path d='M58 38 A27 27 0 0 1 42 56' fill='none' stroke='#f29a82' stroke-width='4.5' stroke-linecap='round'/>"
		+ "<path d='M22 56 A27 27 0 0 1 6 38' fill='none' stroke='#f29a82' stroke-width='4.5' stroke-linecap='round'/>"
		+ "<path d='M24 49 L32 58 L40 49' fill='none' stroke='#fff0d0' stroke-width='3.5' stroke-linecap='round' stroke-linejoin='round'/>"
		+ "</svg>"
	)
	var image := Image.new()
	if image.load_svg_from_string(svg, 1.0) != OK:
		return null
	_priority_peck_missed_halo_texture = ImageTexture.create_from_image(image)
	return _priority_peck_missed_halo_texture


func hen_intent_snapshot() -> Dictionary:
	return _hen_intent.duplicate(true)


func hen_intent_world_position() -> Vector3:
	if _hen_intent_marker != null and _hen_intent_marker.visible:
		return _hen_intent_marker.global_position
	return global_position


static func hen_intent_icon_texture(
	icon: StringName,
	progress_bucket: int = -1,
	urgency: int = 1,
) -> Texture2D:
	var cache_key := "%s:%d:%d" % [String(icon), progress_bucket, urgency]
	if _hen_intent_texture_cache.has(cache_key):
		return _hen_intent_texture_cache[cache_key]
	var fill := String(HEN_INTENT_COLORS.get(icon, "729b70"))
	var symbol := String(HEN_INTENT_SYMBOLS.get(icon, HEN_INTENT_SYMBOLS[&"steady"]))
	var ring := ""
	if progress_bucket >= 0:
		var ring_length := snappedf(175.93 * float(progress_bucket) / 5.0, 0.01)
		ring = (
			"<circle cx='32' cy='32' r='28' fill='none' stroke='#35444b' stroke-width='4'/>"
			+ "<circle cx='32' cy='32' r='28' fill='none' stroke='#fff0b8' stroke-width='%d' stroke-linecap='round' stroke-dasharray='%.2f 175.93' transform='rotate(-90 32 32)'/>" % [5 if urgency >= 3 else 4, ring_length]
		)
	var svg := (
		"<svg xmlns='http://www.w3.org/2000/svg' width='64' height='64' viewBox='0 0 64 64'>"
		+ "<path d='M25 53 L39 53 L32 63 Z' fill='#101a21' fill-opacity='.92' stroke='#f6e5b5' stroke-width='2' stroke-linejoin='round'/>"
		+ "<circle cx='32' cy='32' r='29' fill='#101a21' fill-opacity='.92' stroke='#f6e5b5' stroke-width='2'/>"
		+ ring
		+ "<circle cx='32' cy='32' r='22' fill='#%s'/>" % fill
		+ "<path d='%s' fill='#fff8dc' fill-rule='evenodd'/>" % symbol
		+ "</svg>"
	)
	var image := Image.new()
	var load_error := image.load_svg_from_string(svg, 1.0)
	if load_error != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_hen_intent_texture_cache[cache_key] = texture
	return texture


func _apply_flock_bond(bond: Dictionary) -> void:
	_flock_bond = bond.duplicate(true)
	if _flock_bond_marker == null:
		return
	var score := int(bond.get("score", 50))
	var signal_kind: StringName = &""
	if score >= 75:
		signal_kind = &"clutchmates"
	elif score >= 60:
		signal_kind = &"good_perch"
	elif score < 30:
		signal_kind = &"withdrawn"
	_flock_bond_marker.visible = signal_kind != &""
	if not _flock_bond_marker.visible:
		_flock_bond_marker.texture = null
		_flock_bond_marker.set_meta("signal_kind", &"")
		return
	_flock_bond_marker.texture = _flock_bond_texture(signal_kind)
	_flock_bond_marker.modulate = Color.WHITE
	_flock_bond_marker.set_meta("signal_kind", signal_kind)
	_flock_bond_marker.set_meta("score", score)
	_flock_bond_marker.set_meta("partner_id", int(bond.get("partner_id", -1)))


func flock_bond_snapshot() -> Dictionary:
	return _flock_bond.duplicate(true)


func flock_bond_world_position() -> Vector3:
	if _flock_bond_marker != null and _flock_bond_marker.visible:
		return _flock_bond_marker.global_position
	return global_position


func _flock_bond_texture(signal_kind: StringName) -> Texture2D:
	if _flock_bond_texture_cache.has(signal_kind):
		return _flock_bond_texture_cache[signal_kind]
	var fill := String(FLOCK_BOND_COLORS.get(signal_kind, "71b99c"))
	var symbol := String(FLOCK_BOND_SYMBOLS.get(
		signal_kind,
		FLOCK_BOND_SYMBOLS[&"good_perch"],
	))
	var svg := (
		"<svg xmlns='http://www.w3.org/2000/svg' width='64' height='64' viewBox='0 0 64 64'>"
		+ "<circle cx='32' cy='32' r='28' fill='#101a21' fill-opacity='.90' stroke='#f6e5b5' stroke-width='3'/>"
		+ "<circle cx='32' cy='32' r='23' fill='#%s'/>" % fill
		+ "<path d='%s' fill='#fff8dc' fill-rule='evenodd'/>" % symbol
		+ "</svg>"
	)
	var image := Image.new()
	var load_error := image.load_svg_from_string(svg, 1.0)
	if load_error != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_flock_bond_texture_cache[signal_kind] = texture
	return texture


func _apply_character_shadow_budget() -> void:
	# The connected torso, articulated wings, tail, and feet establish the full
	# readable silhouette. Facial accents and professional accessories receive
	# that shadow instead of each submitting another animated depth pass.
	for candidate in _visual_root.find_children("*", "GeometryInstance3D", true, false):
		var geometry := candidate as GeometryInstance3D
		if geometry == null:
			continue
		geometry.cast_shadow = (
			GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			if StringName(geometry.name) in CHARACTER_SHADOW_HOSTS
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		)


func _visible_shadow_caster_count() -> int:
	var count := 0
	if _visual_root == null:
		return count
	for candidate in _visual_root.find_children("*", "GeometryInstance3D", true, false):
		var geometry := candidate as GeometryInstance3D
		if (
			geometry != null
			and geometry.is_visible_in_tree()
			and geometry.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		):
			count += 1
	return count


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
	# Normal workers keep the exact imported wing pose used by the manager model.
	# Only explicit panic and predator-limp reactions opt into procedural bones.
	if _skeleton == null or _use_authored_wing_pose:
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
	# Panic and limp reactions add outer-feather follow-through.
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
	_animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
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


func _cache_accessory_nodes() -> void:
	_accessory_nodes.clear()
	for accessory_name in ACCESSORY_NAMES:
		var accessory := _visual_root.find_child(String(accessory_name), true, false) as Node3D
		assert(accessory != null, "Chicken model is missing accessory %s" % accessory_name)
		if accessory != null:
			_accessory_nodes[accessory_name] = accessory


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
	_visible_accessory_nodes.clear()
	for accessory_name in ACCESSORY_NAMES:
		var accessory := _accessory_nodes.get(accessory_name) as Node3D
		if accessory != null:
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
		var accessory := _accessory_nodes.get(accessory_name) as Node3D
		assert(accessory != null, "Chicken model is missing profile accessory %s" % accessory_name)
		if accessory == null:
			continue
		accessory.visible = true
		_visible_accessories.append(accessory_name)
		_visible_accessory_nodes.append(accessory)

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
	for accessory in _visible_accessory_nodes:
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
	_secondary_motion_accessories.clear()
	_secondary_motion_accessory_rest_rotations.clear()
	_secondary_motion_accessory_sways.clear()
	for accessory_index in _visible_accessories.size():
		var accessory_name := _visible_accessories[accessory_index]
		var accessory := _visible_accessory_nodes[accessory_index]
		_secondary_motion_accessories.append(accessory)
		_secondary_motion_accessory_rest_rotations.append(accessory.rotation)
		_secondary_motion_accessory_sways.append(
			String(accessory_name).contains("Neck") or accessory_name == &"BowTie"
		)


func _animate_secondary_motion() -> void:
	# A fast close-and-open blink gives the glossy eyes life without creating a
	# separate eyelid mesh. Each worker's offset keeps the flock unsynchronized.
	var blink_period := (4.2 + worker_id * 0.17) / _temperament_motion_scale
	var blink_time := fmod(_phase + worker_id * 0.83, blink_period)
	var eye_openness := 1.0
	if blink_time < 0.16:
		eye_openness = lerpf(0.12, 1.0, absf(blink_time - 0.08) / 0.08)
	for eye_index in _eyes.size():
		var rest_scale := _eye_rest_scales[eye_index]
		_eyes[eye_index].scale = Vector3(rest_scale.x, rest_scale.y * eye_openness, rest_scale.z)

	var breath := 1.0 + sin(_phase * 2.15 * _temperament_motion_scale + worker_id * 0.7) * 0.006
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

	for accessory_index in _secondary_motion_accessories.size():
		var accessory := _secondary_motion_accessories[accessory_index]
		accessory.rotation = _secondary_motion_accessory_rest_rotations[accessory_index]
		if _secondary_motion_accessory_sways[accessory_index]:
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
