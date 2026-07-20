extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var worker := {
		"id": 0,
		"name": "Henrietta",
		"desk_index": 0,
		"state": ChickenState.WorkState.WORKING,
		"state_label": "PECKING",
		"progress": 42.0,
		"stress": 22.0,
	}
	var view := ChickenView.new()
	view.configure(worker)
	root.add_child(view)
	var start := Vector3(-2.0, 0.0, 4.05)
	var chair := Vector3(0.0, 0.0, 1.03)
	var wellness := Vector3(-1.0, 0.0, 3.0)
	view.assign_office_route(
		start,
		chair,
		wellness,
		[Vector3(-1.0, 0.0, 4.05), Vector3(-1.0, 0.0, 1.03), chair],
		[Vector3(-1.0, 0.0, 1.03), wellness]
	)

	for joint_name in ["BodyPivot", "HeadPivot", "WingLeftPivot", "WingRightPivot", "LegLeftPivot", "LegRightPivot"]:
		_check(view.find_child(joint_name, true, false) != null, "model should expose %s" % joint_name, failures)
	for unified_part in ["Feather_Torso", "LegLeftMesh", "LegRightMesh", "Beak", "Comb", "BowTie"]:
		_check(view.find_child(unified_part, true, false) != null, "model should include unified part %s" % unified_part, failures)
	for facial_part_name in ["Eye_-1", "Eye_1", "Beak", "Comb"]:
		var facial_part := view.find_child(facial_part_name, true, false)
		_check(_has_bone_attachment_ancestor(facial_part), "%s should follow the animated head bone" % facial_part_name, failures)
	_check(_has_bone_attachment_ancestor(view.find_child("BowTie", true, false)), "BowTie should follow the animated chest bone", failures)
	for head_accessory_name in [
		"AccessoryHead_RoundGlasses", "AccessoryHead_SquareGlasses",
		"AccessoryHead_AccountantVisor", "AccessoryHead_Headset",
		"AccessoryHead_NewsboyCap", "AccessoryHead_ReadingGlassesChain",
		"AccessoryHead_Earmuffs", "AccessoryHead_SleepMask",
	]:
		var head_accessory := view.find_child(head_accessory_name, true, false)
		_check(head_accessory != null, "model should include %s" % head_accessory_name, failures)
		_check(_has_bone_attachment_ancestor(head_accessory), "%s should follow the animated head bone" % head_accessory_name, failures)
	for lower_accessory_name in [
		"AccessoryNeck_LongTie", "AccessoryNeck_Lanyard",
		"AccessoryNeck_KnitScarf", "AccessoryNeck_CardiganCollar", "AccessoryNeck_Neckerchief",
		"AccessoryBody_SweaterVest", "AccessoryBody_PocketProtector", "AccessoryBody_Satchel",
		"AccessoryBody_TeaMugCharm", "AccessoryBody_QuiltedCapelet",
		"AccessoryBadge_Nameplate", "AccessoryBadge_GoldenEgg",
	]:
		var lower_accessory := view.find_child(lower_accessory_name, true, false)
		_check(lower_accessory != null, "model should include %s" % lower_accessory_name, failures)
		_check(_has_bone_attachment_ancestor(lower_accessory), "%s should follow the animated chest bone" % lower_accessory_name, failures)
	for articulated_accessory_name in ["AccessoryComb_Pencil", "AccessoryLeg_Watch"]:
		var articulated_accessory := view.find_child(articulated_accessory_name, true, false)
		_check(articulated_accessory != null, "model should include %s" % articulated_accessory_name, failures)
		_check(_has_bone_attachment_ancestor(articulated_accessory), "%s should follow its animated attachment" % articulated_accessory_name, failures)
	var career_badge := view.find_child("AccessoryBadge_GoldenEgg", true, false) as Node3D
	var profile_badge_visible := career_badge.visible if career_badge != null else false
	view.apply_snapshot({
		"state": ChickenState.WorkState.WORKING,
		"stress": 22.0,
		"secondary_specialty": "appeals",
	})
	_check(career_badge != null and career_badge.visible, "cross-trained hens should wear the authored torso-mounted credential", failures)
	_check(career_badge != null and bool(career_badge.get_meta("career_sponsorship_badge", false)), "career credential should expose sponsorship semantics for visual regression", failures)
	view.apply_snapshot({
		"state": ChickenState.WorkState.WORKING,
		"stress": 22.0,
		"secondary_specialty": "",
	})
	_check(career_badge != null and career_badge.visible == profile_badge_visible, "unsponsored hens should retain their original deterministic accessory profile", failures)

	var roster_names := ["Mabel", "Pip", "Henrietta", "Dot", "Agnes", "Beatrice"]
	var accessory_signatures := {}
	for worker_index in roster_names.size():
		var accessory_view := ChickenView.new()
		accessory_view.configure({
			"id": worker_index,
			"name": roster_names[worker_index],
			"desk_index": worker_index,
			"state": ChickenState.WorkState.IDLE,
			"state_label": "AVAILABLE",
			"progress": 0.0,
			"stress": 12.0,
		})
		var visible_accessories := accessory_view.visible_accessory_names()
		var signature := accessory_view.accessory_signature()
		_check(visible_accessories.size() >= 1 and visible_accessories.size() <= 4, "worker %d should wear one to four compatible accessories" % worker_index, failures)
		_check(not accessory_signatures.has(signature), "worker accessory profiles should be visually unique", failures)
		accessory_signatures[signature] = true
		var repeated_view := ChickenView.new()
		repeated_view.configure({
			"id": worker_index,
			"name": roster_names[worker_index],
			"desk_index": worker_index,
			"state": ChickenState.WorkState.IDLE,
			"state_label": "AVAILABLE",
			"progress": 0.0,
			"stress": 12.0,
		})
		_check(repeated_view.accessory_signature() == signature, "worker %d accessories should remain stable across reloads" % worker_index, failures)
		accessory_view.free()
		repeated_view.free()
	var animation_player := view.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_check(animation_player != null, "rebuilt chicken should import a playable armature animation set", failures)
	if animation_player != null:
		for required_clip in ["Chicken_Idle", "Chicken_Walk", "Chicken_Peck", "Chicken_Sit", "Chicken_Lay"]:
			var clip_found := false
			for available_clip in animation_player.get_animation_list():
				if String(available_clip).ends_with(required_clip):
					clip_found = true
					break
			_check(clip_found, "model should import %s" % required_clip, failures)
	var torso := view.find_child("Feather_Torso", true, false) as MeshInstance3D
	var articulated_wing := view.find_child("ArticulatedWing_L", true, false) as MeshInstance3D
	var tail_feather := view.find_child("TailFeatherFan", true, false) as MeshInstance3D
	var left_leg := view.find_child("LegLeftMesh", true, false) as Node3D
	var right_leg := view.find_child("LegRightMesh", true, false) as Node3D
	_check(torso != null and torso.get_aabb().size.x < 0.82, "authored wings should stay integrated with the torso silhouette", failures)
	_check(left_leg != null and absf(left_leg.position.x) < 0.01, "left leg mesh should be centered under its animation pivot", failures)
	_check(right_leg != null and absf(right_leg.position.x) < 0.01, "right leg mesh should be centered under its animation pivot", failures)
	var torso_color := _surface_override_color(torso, "Feathers_Oat")
	var covert_color := _surface_override_color(articulated_wing, "Feathers_Wing_Covert")
	var flight_color := _surface_override_color(articulated_wing, "Feathers_Wing")
	var tail_color := _surface_override_color(tail_feather, "Feathers_Wing")
	_check(torso_color.is_equal_approx(Color("ad7747")), "worker zero should receive the oat base feather palette", failures)
	_check(covert_color.is_equal_approx(torso_color.darkened(0.08)), "wing coverts should derive from the worker body palette", failures)
	_check(flight_color.is_equal_approx(torso_color.darkened(0.20)), "flight feathers should derive from the worker body palette", failures)
	_check(tail_color.is_equal_approx(flight_color), "tail and flight feathers should share the worker dark feather tone", failures)

	var blinking_eye := view.find_child("Eye_-1", true, false) as Node3D
	var eye_rest_height := blinking_eye.scale.y if blinking_eye != null else 0.0
	var minimum_eye_height := eye_rest_height
	for _frame in 360:
		await physics_frame
		if blinking_eye != null:
			minimum_eye_height = minf(minimum_eye_height, blinking_eye.scale.y)
	_check(view.global_position.distance_to(chair) < 0.08, "worker should walk to assigned chair", failures)
	_check(blinking_eye != null and minimum_eye_height < eye_rest_height * 0.55, "worker eyes should blink with attached secondary motion", failures)
	var body := view.find_child("BodyPivot", true, false) as Node3D
	_check(body != null and body.position.y > 0.45, "worker torso should rest above the chair seat", failures)
	_check(body != null and body.rotation.x < -0.10, "working worker should peck with its connected body", failures)
	var seated_binding_diagnostics := view.model_binding_diagnostics()
	_check(
		bool(seated_binding_diagnostics.get("authored_wing_pose", false)),
		"working at a desk should preserve the same authored body-side wing pose as the manager model",
		failures,
	)

	var attendance := Vector3(-1.0, 0.0, 0.0)
	var trough := Vector3(0.0, 0.0, 0.0)
	var attendance_observation := {"ready": 0, "completed": 0}
	view.feed_party_attendance_ready.connect(func(_worker_id: int) -> void:
		attendance_observation["ready"] += 1
	)
	view.feed_party_attendance_completed.connect(func(_worker_id: int) -> void:
		attendance_observation["completed"] += 1
	)
	view.attend_feed_party(
		[Vector3(-1.0, 0.0, 1.03), attendance],
		[Vector3(-1.0, 0.0, 1.03), chair],
		attendance,
		trough
	)
	for _frame in 160:
		await physics_frame
	_check(view.is_attending_feed_party(), "worker should remain at the trough until the office releases attendance", failures)
	_check(view.global_position.distance_to(attendance) < 0.08, "worker should reach the assigned feed-party socket", failures)
	_check(attendance_observation["ready"] == 1, "worker should report feed-party attendance once", failures)
	_check(body.rotation.x < -0.15, "feeding worker should peck down toward the trough", failures)
	view.return_from_feed_party()
	for _frame in 160:
		await physics_frame
	_check(view.global_position.distance_to(chair) < 0.08, "worker should return safely to the assigned desk", failures)
	_check(not view.is_attending_feed_party(), "worker should leave attendance mode after returning", failures)
	_check(attendance_observation["completed"] == 1, "worker should report one completed feed-party visit", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("PRESENTATION_SMOKE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PRESENTATION_SMOKE_TEST_PASSED position=%s body_pitch=%.2f" % [view.global_position, body.rotation.x])
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _has_bone_attachment_ancestor(node: Node) -> bool:
	var ancestor := node
	while ancestor != null:
		if ancestor is BoneAttachment3D:
			return true
		ancestor = ancestor.get_parent()
	return false


func _surface_override_color(mesh_instance: MeshInstance3D, material_name: String) -> Color:
	if mesh_instance == null or mesh_instance.mesh == null:
		return Color(0.0, 0.0, 0.0, 0.0)
	for surface_index in mesh_instance.mesh.get_surface_count():
		var source_material := mesh_instance.mesh.surface_get_material(surface_index)
		if source_material == null or source_material.resource_name != material_name:
			continue
		var override_material := mesh_instance.get_surface_override_material(surface_index) as StandardMaterial3D
		return override_material.albedo_color if override_material != null else Color(0.0, 0.0, 0.0, 0.0)
	return Color(0.0, 0.0, 0.0, 0.0)
