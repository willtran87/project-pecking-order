class_name PredatorEncounter
extends Node3D

## Debug-playable office encounter using a real ChickenView, not a duplicate or
## placeholder. The jaw socket carries the employee after the grab while a
## damped spring drives the limp-neck/body response during the shake.

signal victim_carried_away(worker_id: int)

const FOX_MODEL := preload("res://assets/models/predator_fox.glb")
const APPROACH_SPEED := 3.8
const EXIT_SPEED := 4.6
const CONTACT_DISTANCE := 0.30

enum Phase { INACTIVE, APPROACH, CLAMP, GRAB_SEQUENCE, EXIT }

var _phase := Phase.INACTIVE
var _fox_root: Node3D
var _fox_model: Node3D
var _fox_animation: AnimationPlayer
var _jaw_grip: BoneAttachment3D
var _limp_pivot: Node3D
var _victim: ChickenView
var _sequence_elapsed := 0.0
var _sequence_duration := 2.1
var _exit_target := Vector3.ZERO
var _approach_waypoints: Array[Vector3] = []
var _exit_waypoints: Array[Vector3] = []
var _approach_waypoint_index := 0
var _exit_waypoint_index := 0
var _swing := Vector2.ZERO
var _swing_velocity := Vector2.ZERO
var _previous_fox_roll := 0.0
var _clamp_elapsed := 0.0
var _clamp_duration := 0.48
var _clamp_start_position := Vector3.ZERO
var _clamp_start_rotation := Vector3.ZERO
var _jaw_held_chicken_position := Vector3.ZERO


func play(victim: ChickenView, entry_point: Vector3, approach_route: Array[Vector3], exit_route: Array[Vector3]) -> bool:
	if _phase != Phase.INACTIVE or victim == null or not is_instance_valid(victim):
		return false
	_victim = victim
	_build_fox()
	_approach_waypoints = approach_route.duplicate()
	_exit_waypoints = exit_route.duplicate()
	_approach_waypoint_index = 0
	_exit_waypoint_index = 0
	_fox_root.global_position = entry_point
	_face_point(_approach_waypoints[0] if not _approach_waypoints.is_empty() else _victim.global_position)
	_phase = Phase.APPROACH
	return true


func focus_point() -> Vector3:
	if _fox_root != null and is_instance_valid(_fox_root):
		return _fox_root.global_position + Vector3(0.0, 0.95, 0.0)
	return Vector3.ZERO


func _process(delta: float) -> void:
	if _phase == Phase.INACTIVE:
		return
	if _victim == null or not is_instance_valid(_victim):
		_finish()
		return
	match _phase:
		Phase.APPROACH:
			_advance_approach(delta)
		Phase.CLAMP:
			_advance_clamp(delta)
		Phase.GRAB_SEQUENCE:
			_advance_grab_sequence(delta)
		Phase.EXIT:
			_advance_exit(delta)


func _build_fox() -> void:
	_fox_root = Node3D.new()
	_fox_root.name = "PredatorFoxEncounter"
	add_child(_fox_root)
	_fox_model = FOX_MODEL.instantiate() as Node3D
	_fox_model.name = "PredatorFoxModel"
	_fox_model.scale = Vector3.ONE * 1.10
	_fox_root.add_child(_fox_model)
	for child_name in [
		"LimpChickenBeak", "LimpChickenBody", "LimpChickenHead", "LimpChickenNeck",
		"LimpChickenWingL", "LimpChickenWingR",
	]:
		var placeholder_part := _fox_model.find_child(child_name, true, false) as Node3D
		if placeholder_part != null:
			placeholder_part.visible = false
	_fox_animation = _fox_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skeleton := _fox_model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null:
		push_error("Predator fox is missing the FoxArmature skeleton")
		return
	# The jaw bone animates the bite.  Its explicitly-authored child socket is
	# the actual clamp center used for the live chicken's neck root.
	_jaw_grip = skeleton.find_child("jaw", true, false) as BoneAttachment3D
	if _jaw_grip == null:
		push_error("Predator fox is missing the jaw bone attachment")
		return
	var jaw_grip_socket := _fox_model.find_child("JawGripSocket", true, false) as Node3D
	if jaw_grip_socket == null:
		push_error("Predator fox is missing the JawGripSocket")
		return
	_limp_pivot = Node3D.new()
	_limp_pivot.name = "NeckRagdollPivot"
	jaw_grip_socket.add_child(_limp_pivot)


func _advance_approach(delta: float) -> void:
	var target := _victim.global_position + Vector3(0.0, 0.0, 0.34)
	if _approach_waypoint_index < _approach_waypoints.size():
		target = _approach_waypoints[_approach_waypoint_index]
	var offset := target - _fox_root.global_position
	offset.y = 0.0
	if offset.length() <= CONTACT_DISTANCE:
		if _approach_waypoint_index < _approach_waypoints.size():
			_approach_waypoint_index += 1
			return
		_begin_grab_sequence()
		return
	_fox_root.global_position += offset.normalized() * minf(APPROACH_SPEED * delta, offset.length())
	_face_point(target)
	_play_fox_animation(&"Fox_CarryWalk")


func _begin_grab_sequence() -> void:
	_victim.begin_predator_capture()
	# Preserve the live employee's current world transform first. We then ease
	# from that local transform into the jaw-held offset instead of teleporting.
	_victim.reparent(_limp_pivot, true)
	_clamp_start_position = _victim.position
	_clamp_start_rotation = _victim.rotation
	_jaw_held_chicken_position = -_victim.predator_neck_local_offset()
	_clamp_elapsed = 0.0
	_limp_pivot.rotation = Vector3.ZERO
	_sequence_elapsed = 0.0
	_swing = Vector2.ZERO
	_swing_velocity = Vector2.ZERO
	_previous_fox_roll = 0.0
	_play_fox_animation(&"Fox_PickupRotateShake")
	if _fox_animation != null:
		_sequence_duration = _fox_animation.current_animation_length
	_phase = Phase.CLAMP


func _advance_clamp(delta: float) -> void:
	_clamp_elapsed += delta
	var linear := clampf(_clamp_elapsed / _clamp_duration, 0.0, 1.0)
	var blend := linear * linear * (3.0 - 2.0 * linear)
	_victim.position = _clamp_start_position.lerp(_jaw_held_chicken_position, blend)
	_victim.rotation = _clamp_start_rotation.lerp(Vector3.ZERO, blend)
	# Small anticipation begins the slack-neck read before the body is lifted.
	_victim.apply_predator_limp_pose(Vector2.ZERO, blend * 0.16)
	if linear >= 1.0:
		# Keep the fox clip continuous: its early bite frames play while the
		# chicken blends into place, then the lift/rotation continues naturally.
		_sequence_elapsed = _clamp_elapsed
		_phase = Phase.GRAB_SEQUENCE


func _advance_grab_sequence(delta: float) -> void:
	_sequence_elapsed += delta
	var normalized := clampf(_sequence_elapsed / maxf(_sequence_duration, 0.01), 0.0, 1.0)
	# Lift and rotate first, then make the spring react strongly to the shake.
	var pickup := clampf(normalized / 0.42, 0.0, 1.0)
	var fox_roll := _jaw_grip.global_rotation.z
	var angular_impulse := wrapf(fox_roll - _previous_fox_roll, -PI, PI)
	_previous_fox_roll = fox_roll
	var shake_gain := clampf((normalized - 0.48) / 0.36, 0.0, 1.0)
	_swing_velocity.y += -angular_impulse * (11.0 + shake_gain * 22.0)
	_swing_velocity.x += sin(_sequence_elapsed * 18.0) * shake_gain * 0.68
	_swing_velocity += -_swing * (9.0 + shake_gain * 6.0) * delta
	_swing_velocity *= pow(0.11, delta)
	_swing += _swing_velocity * delta
	_swing.x = clampf(_swing.x, -0.38, 0.38)
	_swing.y = clampf(_swing.y, -0.62, 0.62)
	# Pivot around the neck grip. The roll peaks during pickup, settles into a
	# vertical hang, then is driven by the whip-like fox head movement.
	var pickup_roll := sin(pickup * PI) * 0.58
	_limp_pivot.rotation = Vector3(_swing.x, 0.0, pickup_roll + _swing.y)
	var neck_actuation := (sin(_sequence_elapsed * 16.0) * 0.26 + _swing.x * 0.85) * pickup
	_victim.apply_predator_limp_pose(_swing, neck_actuation)
	if normalized >= 1.0:
		_begin_exit()


func _begin_exit() -> void:
	_play_fox_animation(&"Fox_CarryWalk")
	# Use the employee's ordinary departure lane in reverse encounter order:
	# desk aisle -> shared main aisle -> the exact door-side entry point.
	_exit_waypoint_index = 0
	_exit_target = _exit_waypoints[0] if not _exit_waypoints.is_empty() else _fox_root.global_position
	_phase = Phase.EXIT


func _advance_exit(delta: float) -> void:
	if _exit_waypoint_index < _exit_waypoints.size():
		_exit_target = _exit_waypoints[_exit_waypoint_index]
	var offset := _exit_target - _fox_root.global_position
	offset.y = 0.0
	if offset.length() <= 0.12:
		if _exit_waypoint_index < _exit_waypoints.size():
			_exit_waypoint_index += 1
			return
		victim_carried_away.emit(_victim.worker_id)
		_victim.queue_free()
		_finish()
		return
	_fox_root.global_position += offset.normalized() * minf(EXIT_SPEED * delta, offset.length())
	_face_point(_exit_target)
	# A smaller ongoing pendulum keeps the body limp throughout the exit.
	_swing.x = lerpf(_swing.x, sin(Time.get_ticks_msec() * 0.008) * 0.08, delta * 2.0)
	_swing.y = lerpf(_swing.y, 0.0, delta * 1.7)
	_limp_pivot.rotation = Vector3(_swing.x, 0.0, _swing.y)
	_victim.apply_predator_limp_pose(_swing, _swing.x * 0.45)


func _play_fox_animation(requested_name: StringName) -> void:
	if _fox_animation == null:
		return
	for available_name in _fox_animation.get_animation_list():
		if String(available_name).ends_with(String(requested_name)):
			_fox_animation.play(available_name, 0.08)
			return


func _face_point(point: Vector3) -> void:
	var direction := point - _fox_root.global_position
	direction.y = 0.0
	if direction.length_squared() > 0.0001:
		_fox_root.rotation.y = atan2(direction.x, direction.z)


func _finish() -> void:
	_phase = Phase.INACTIVE
	if _fox_root != null and is_instance_valid(_fox_root):
		_fox_root.queue_free()
	_fox_root = null
	_fox_model = null
	_fox_animation = null
	_jaw_grip = null
	_limp_pivot = null
	_victim = null
