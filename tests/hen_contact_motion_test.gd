extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func fixture(id: int, stress: float = 12.0, fatigue: float = 5.0) -> ChickenView:
	var hen := ChickenView.new()
	hen.configure({"id": id, "name": "Contact Hen", "desk_index": id, "state": ChickenState.WorkState.WORKING, "stress": stress, "fatigue": fatigue})
	root.add_child(hen)
	hen.set_physics_process(false)
	var home := Vector3(0, 0, -1.03)
	hen.assign_office_route(home, home, Vector3(3, 0, -1.03), [], [Vector3(3, 0, -1.03)])
	hen.stage_at_workstation_for_introduction()
	for i in 90: hen._physics_process(1.0 / 60.0)
	return hen

func _run() -> void:
	var worst_contact := 0.0
	for id in 6:
		for strain in [12.0, 90.0]:
			var hen := fixture(id, strain, 80.0 if strain > 50 else 5.0)
			var nodes := hen.find_children("*", "", true, false).size()
			hen.play_peck_assist_feedback(&"perfect")
			for time in [0.12, 0.28, 0.44]:
				hen.set("_priority_peck_elapsed", time)
				hen._physics_process(0.0)
				var contact := hen.contact_snapshot()
				var beak := contact.beak as Vector3
				worst_contact = maxf(worst_contact, absf(beak.y - 0.98))
				check(absf(beak.y - 0.98) < 0.015, "beak reaches key surface for hen %d at strain %.0f" % [id, strain])
				check(beak.z > -0.58 and beak.z < -0.22 and absf(beak.x) < 0.47, "beak lands inside keyboard footprint")
				check(absf((contact.left_foot as Vector3).y - 0.60) < 0.005 and absf((contact.right_foot as Vector3).y - 0.60) < 0.005, "both feet stay on cushion during work lean")
			hen.set("_priority_peck_timeline_active", false)
			hen.play_emotion(&"proud", "earned")
			for i in 30: hen._physics_process(1.0 / 60.0)
			var skeleton := hen.find_child("Skeleton3D", true, false) as Skeleton3D
			var head := skeleton.find_bone("head")
			check(skeleton.get_bone_pose_rotation(head).angle_to(hen.get("_head_base") as Quaternion) > 0.05, "earned reaction moves actual head bone")
			check(absf((hen.contact_snapshot().left_foot as Vector3).y - 0.60) < 0.005, "reward keeps a supported perch")
			var elapsed := float(hen.expression_snapshot().elapsed)
			hen.play_emotion(&"proud", "earned-again")
			check(float(hen.expression_snapshot().elapsed) == elapsed, "successes coalesce without resetting the pose")
			check(not hen.play_emotion(&"proud", "earned-again"), "coalescing still deduplicates receipts")
			check(hen.find_children("*", "", true, false).size() == nodes, "contact and reaction reuse the existing rig")
			hen.free()
	var walker := fixture(0)
	walker.apply_snapshot({"state": ChickenState.WorkState.IDLE, "stress": 12.0, "fatigue": 5.0})
	for i in 100: walker._physics_process(1.0 / 60.0)
	var sk := walker.find_child("Skeleton3D", true, false) as Skeleton3D
	walker._physics_process(0.0)
	var before_head := sk.get_bone_pose_rotation(sk.find_bone("head"))
	for i in 200: walker._physics_process(0.0)
	check(before_head.angle_to(sk.get_bone_pose_rotation(sk.find_bone("head"))) < 0.001, "repeated held pose sampling cannot accumulate head rotation")
	var origin := walker.position
	walker.apply_snapshot({"state": ChickenState.WorkState.BREAK, "stress": 12.0, "fatigue": 5.0})
	var body := walker.get("_body_pivot") as Node3D
	var last_y := body.global_position.y
	var largest_step := 0.0
	for i in 90:
		walker._physics_process(1.0 / 60.0)
		largest_step = maxf(largest_step, absf(body.global_position.y - last_y))
		last_y = body.global_position.y
		var contact := walker.contact_snapshot()
		if float(contact.seat) > 0.08:
			check(walker.position.is_equal_approx(origin) and contact.animation != "Chicken_Walk", "stand up before translating or cycling walk")
		elif float(contact.seat) == 0.0:
			check(absf(minf((contact.left_foot as Vector3).y, (contact.right_foot as Vector3).y) - 0.008) < 0.006, "walking planted foot meets floor")
	check(largest_step < 0.08, "stand transition avoids a large vertical pop")
	check(walker.position.distance_to(origin) > 1.0, "standing gate still permits normal travel")
	walker.apply_snapshot({"state": ChickenState.WorkState.WORKING, "stress": 12.0, "fatigue": 5.0})
	# The fixture's authored return path includes the chair, as real routes do.
	walker.set("_route", [origin] as Array[Vector3])
	walker.set("_route_index", 0)
	for i in 240: walker._physics_process(1.0 / 60.0)
	check(walker.is_seated_at_workstation(), "return turns, settles and restores workstation presence")
	walker.set_reduced_motion(true)
	walker.play_emotion(&"relief", "rest")
	for i in 20: walker._physics_process(1.0 / 60.0)
	check(not bool(walker.get("_expression_wings_applied")), "reduced motion preserves static reaction")
	walker.free()
	print("HEN_CONTACT_METRICS max_key_error=%.5f max_stand_step=%.5f" % [worst_contact, largest_step])
	if failures.is_empty():
		print("HEN_CONTACT_MOTION_TEST_PASSED keys=6-hens+strain feet=perch+floor transitions=stand+return reactions=real-rig+bounded")
		quit(0)
	else:
		for message in failures: push_error("HEN_CONTACT_MOTION_TEST_FAILED: " + message)
		quit(1)
