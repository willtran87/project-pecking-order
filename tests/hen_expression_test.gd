extends SceneTree

const HenPose := preload("res://features/chickens/hen_expression.gd")
var failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var pose := HenPose.new()
	pose.sample(1.0, 0, 10.0, 5.0, true, false)
	var calm_eyes := pose.eyes
	pose.sample(1.0, 0, 90.0, 85.0, true, false)
	_check(pose.strain > 0.9 and pose.eyes < calm_eyes - 0.3, "stress and fatigue change face/posture")
	_check(HenPose.work_check(4.4, 0) > 0.9 and HenPose.work_check(1.0, 0) == 0.0, "work has distinct peck/check beats")
	_check(pose.play(&"golden", "egg:7"), "real event can start a celebration")
	_check(not pose.play(&"golden", "egg:7"), "same delivery cannot replay")
	_check(not pose.play(&"relief"), "minor recovery cannot interrupt a golden payoff")
	pose.advance(0.7, true)
	pose.sample(0.0, 0, 10.0, 5.0, true, true)
	_check(pose.wings == 0.0 and pose.sparkle > 0.0 and pose.breath == 1.0, "reduced motion keeps a static earned expression")
	pose.advance(4.0, true)
	_check(pose.reaction.is_empty(), "reaction retires")
	pose.play(&"proud", "egg:8")
	pose.advance(5.1, false)
	_check(pose.reaction.is_empty(), "offscreen travel cannot retain a stale reward indefinitely")

	var view := ChickenView.new()
	view.configure({"id": 0, "name": "Expression Hen", "desk_index": 0, "state": ChickenState.WorkState.IDLE, "stress": 12.0, "fatigue": 5.0, "career_level": 2})
	root.add_child(view)
	view.set_physics_process(false)
	view.assign_office_route(Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.0, 1.0), Vector3(1.0, 0.0, 1.0), [], [])
	view.stage_at_workstation_for_introduction()
	view.set_route_progress_held(true)
	for frame in 120:
		view._physics_process(1.0 / 60.0)
	_check(view.expression_snapshot().serial == 0, "loading an existing promoted hen does not invent a reward")
	var root_position := view.position
	var skeleton := view.find_child("Skeleton3D", true, false) as Skeleton3D
	var wing := skeleton.find_bone("wing_L")
	var rest_rotation := skeleton.get_bone_pose_rotation(wing)
	var node_count := view.find_children("*", "", true, false).size()
	view.play_emotion(&"golden", "egg:9")
	var max_wing_change := 0.0
	for frame in 210:
		view._physics_process(1.0 / 60.0)
		max_wing_change = maxf(max_wing_change, rest_rotation.angle_to(skeleton.get_bone_pose_rotation(wing)))
	_check(max_wing_change > 0.10 and max_wing_change < 0.35, "wing flourish is visible and bounded relative to the authored basis")
	_check(rest_rotation.angle_to(skeleton.get_bone_pose_rotation(wing)) < 0.002, "finished sit clip restores wing exactly without accumulating offsets")
	_check(view.position.is_equal_approx(root_position), "reward never moves the hen off her authoritative seat")
	_check(view.find_children("*", "", true, false).size() == node_count, "reactions reuse pooled marks without node growth")
	view.apply_snapshot({"state": ChickenState.WorkState.WORKING, "stress": 12.0, "fatigue": 5.0})
	view.play_emotion(&"proud", "egg:10")
	view._physics_process(0.5)
	_check(float(view.call("_ambient_peck_wave")) == 0.0, "earned reactions get their own visual beat without extra work-contact noise")
	for frame in 150:
		view._physics_process(1.0 / 60.0)
	view.apply_snapshot({"state": ChickenState.WorkState.WORKING, "stress": 90.0, "fatigue": 80.0})
	view._physics_process(0.1)
	_check(view.find_child("ExpressionSweat_0", true, false).visible, "real stress drives a visible sweat cue")
	view.apply_snapshot({"state": ChickenState.WorkState.WORKING, "stress": 40.0, "fatigue": 25.0})
	var recovered_serial := int(view.expression_snapshot().serial)
	_check(view.expression_snapshot().last_reaction == "relief", "recovering from high stress produces relief")
	view.apply_snapshot({"state": ChickenState.WorkState.WORKING, "stress": 39.0, "fatigue": 24.0})
	_check(view.expression_snapshot().serial == recovered_serial, "routine snapshots do not repeat the same recovery")
	view.set_reduced_motion(true)
	view._physics_process(0.1)
	_check(not bool(view.get("_expression_wings_applied")), "reduced motion removes flourish from the rig")
	view.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("HEN_EXPRESSION_TEST_FAILED: " + failure)
		quit(1)
		return
	print("HEN_EXPRESSION_TEST_PASSED moods=authoritative events=deduplicated wings=bounded+restored movement=unchanged reduced=static nodes=pooled")
	quit(0)


func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
