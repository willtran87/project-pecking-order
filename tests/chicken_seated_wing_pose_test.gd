extends SceneTree


const ChickenModel: PackedScene = preload("res://assets/models/chicken_employee.glb")
const WING_BONES: Array[StringName] = [&"wing_L", &"wing_R", &"wing_L_tip", &"wing_R_tip"]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var chicken := ChickenView.new()
	chicken.configure({
		"id": 0,
		"name": "Mabel",
		"desk_index": 0,
		"state": ChickenState.WorkState.IDLE,
		"stress": 12.0,
	})
	root.add_child(chicken)
	var chair := Vector3(0.0, 0.0, 1.0)
	chicken.assign_office_route(
		Vector3(-1.0, 0.0, 1.0),
		chair,
		Vector3(-1.0, 0.0, 2.0),
		[chair],
		[Vector3(-1.0, 0.0, 2.0)],
	)

	# This raw model is the same presentation path used by ManagementPresence.
	# Sampling it at the worker clip's exact time catches any procedural write
	# that replaces the imported GLB bone basis with an incorrect identity pose.
	var manager_reference := ChickenModel.instantiate() as Node3D
	root.add_child(manager_reference)
	var reference_player := manager_reference.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var reference_skeleton := manager_reference.find_child("Skeleton3D", true, false) as Skeleton3D
	_check(reference_player != null, "the manager reference should expose its imported AnimationPlayer", failures)
	_check(reference_skeleton != null, "the manager reference should expose its imported Skeleton3D", failures)

	chicken.stage_at_workstation_for_introduction()
	for _frame in 12:
		await physics_frame

	var animation_player := chicken.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_check(
		animation_player != null
		and animation_player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL,
		"the worker should manually sample the imported clip before behavioral presentation",
		failures,
	)
	var skeleton := chicken.find_child("Skeleton3D", true, false) as Skeleton3D
	_check(skeleton != null, "the worker fixture should expose the production skeleton", failures)
	var idle_error := _sample_manager_reference_error(
		skeleton,
		animation_player,
		reference_skeleton,
		reference_player,
		&"Chicken_Sit",
	)
	_check(idle_error < 0.002, "seated idle wings should match the manager model basis", failures)

	chicken.apply_snapshot({
		"state": ChickenState.WorkState.WORKING,
		"stress": 12.0,
	})
	for _frame in 12:
		await physics_frame
	var maximum_working_error := 0.0
	for _frame in 60:
		await physics_frame
		maximum_working_error = maxf(
			maximum_working_error,
			_sample_manager_reference_error(
				skeleton,
				animation_player,
				reference_skeleton,
				reference_player,
				&"Chicken_Peck",
			),
		)
	_check(
		maximum_working_error < 0.002,
		"desk pecking should preserve the manager-reference wing basis",
		failures,
	)

	chicken.apply_snapshot({
		"state": ChickenState.WorkState.LAYING,
		"stress": 12.0,
	})
	for _frame in 12:
		await physics_frame
	var maximum_laying_error := 0.0
	for _frame in 60:
		await physics_frame
		maximum_laying_error = maxf(
			maximum_laying_error,
			_sample_manager_reference_error(
				skeleton,
				animation_player,
				reference_skeleton,
				reference_player,
				&"Chicken_Lay",
			),
		)
	_check(
		maximum_laying_error < 0.002,
		"laying should retain the imported wing curve without a procedural fold",
		failures,
	)

	chicken.depart_office([Vector3(0.0, 0.0, 4.0)])
	for _frame in 12:
		await physics_frame
	var maximum_walking_error := 0.0
	var walking_distance := 0.0
	var departure_position := chicken.global_position
	for _frame in 60:
		await physics_frame
		maximum_walking_error = maxf(
			maximum_walking_error,
			_sample_manager_reference_error(
				skeleton,
				animation_player,
				reference_skeleton,
				reference_player,
				&"Chicken_Walk",
			),
		)
		walking_distance = maxf(walking_distance, chicken.global_position.distance_to(departure_position))
	_check(walking_distance > 0.50, "the fixture should exercise sustained route movement", failures)
	_check(
		maximum_walking_error < 0.002,
		"walking worker wings should match the known-good manager walk clip",
		failures,
	)

	chicken.queue_free()
	manager_reference.queue_free()
	await process_frame
	print(
		"CHICKEN_MANAGER_WING_REFERENCE idle=%.6f work=%.6f lay=%.6f walk=%.6f distance=%.3f"
			% [idle_error, maximum_working_error, maximum_laying_error, maximum_walking_error, walking_distance]
	)
	if not failures.is_empty():
		for failure in failures:
			push_error("CHICKEN_SEATED_WING_POSE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CHICKEN_SEATED_WING_POSE_TEST_PASSED manager_reference=exact")
	quit(0)


func _sample_manager_reference_error(
	worker_skeleton: Skeleton3D,
	worker_player: AnimationPlayer,
	reference_skeleton: Skeleton3D,
	reference_player: AnimationPlayer,
	requested_clip: StringName,
) -> float:
	if worker_skeleton == null or worker_player == null or reference_skeleton == null or reference_player == null:
		return INF
	var reference_clip := _find_imported_clip(reference_player, requested_clip)
	if reference_clip.is_empty():
		return INF
	if reference_player.current_animation != String(reference_clip):
		reference_player.play(reference_clip)
	reference_player.seek(worker_player.current_animation_position, true)
	var maximum_error := 0.0
	for bone_name in WING_BONES:
		var worker_bone := worker_skeleton.find_bone(bone_name)
		var reference_bone := reference_skeleton.find_bone(bone_name)
		if worker_bone < 0 or reference_bone < 0:
			return INF
		maximum_error = maxf(
			maximum_error,
			worker_skeleton.get_bone_pose_rotation(worker_bone).angle_to(
				reference_skeleton.get_bone_pose_rotation(reference_bone)
			),
		)
	return maximum_error


func _find_imported_clip(player: AnimationPlayer, requested_clip: StringName) -> StringName:
	for available_name in player.get_animation_list():
		if String(available_name).ends_with(String(requested_clip)):
			return available_name
	return &""


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
