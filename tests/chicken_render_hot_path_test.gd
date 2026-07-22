extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var chicken := ChickenView.new()
	chicken.configure({
		"id": 0,
		"name": "Mabel",
		"desk_index": 0,
		"state": ChickenState.WorkState.WORKING,
		"state_label": "PECKING",
		"progress": 18.0,
		"stress": 20.0,
	})
	root.add_child(chicken)
	await physics_frame

	var chicken_bindings := chicken.model_binding_diagnostics()
	_check(
		int(chicken_bindings["accessory_nodes_cached"])
			== int(chicken_bindings["accessory_nodes_expected"]),
		"ChickenView should bind every authored accessory exactly once",
		failures,
	)
	_check(
		int(chicken_bindings["visible_accessory_nodes_cached"])
			== chicken.visible_accessory_names().size(),
		"visible accessory names and cached nodes should remain aligned",
		failures,
	)
	_check(
		int(chicken_bindings["secondary_motion_accessories_cached"])
			== chicken.visible_accessory_names().size(),
		"secondary motion should use the stable visible-accessory bindings",
		failures,
	)
	_check(bool(chicken_bindings["skeleton_cached"]), "chicken skeleton should be cached", failures)
	_check(int(chicken_bindings["wing_bones_cached"]) == 4, "all four articulated wing bones should be cached", failures)
	var rig := chicken.find_child("ChickenRig", true, false)
	var render_profile := _render_profile(rig)
	_check(
		int(render_profile.meshes) <= 40,
		"the chicken GLB should consolidate rigid detail into at most 40 mesh nodes",
		failures,
	)
	_check(
		int(render_profile.surfaces) <= 70,
		"the chicken GLB should keep its detailed material silhouette within 70 surfaces",
		failures,
	)
	for accessory_name in ChickenView.ACCESSORY_NAMES:
		var accessory_root := chicken.find_child(String(accessory_name), true, false)
		if accessory_root == null or accessory_root is MeshInstance3D:
			continue
		_check(
			_count_meshes(accessory_root) <= 1,
			"accessory %s should submit one consolidated mesh" % accessory_name,
			failures,
		)

	# Culling model writes must not pause logical travel or workstation presence.
	chicken.assign_office_route(
		Vector3(-1.0, 0.0, 0.0),
		Vector3.ZERO,
		Vector3(0.0, 0.0, 1.0),
		[Vector3.ZERO],
		[Vector3(0.0, 0.0, 1.0)],
	)
	chicken.visible = false
	for _frame in 120:
		await physics_frame
	_check(
		chicken.global_position.distance_to(Vector3.ZERO) < 0.06,
		"hidden chickens should still complete their collision-safe route",
		failures,
	)
	_check(
		chicken.is_seated_at_workstation(),
		"hidden chickens should still complete their gameplay-facing seat blend",
		failures,
	)
	chicken.visible = true
	await physics_frame
	var body := chicken.find_child("BodyPivot", true, false) as Node3D
	_check(
		body != null and body.position.y > 0.45,
		"a culled chicken should derive its complete current pose when shown again",
		failures,
	)

	var presence := ManagementPresence.new()
	root.add_child(presence)
	await process_frame
	var manager_bindings := presence.model_binding_diagnostics()
	_check(
		int(manager_bindings["accessory_nodes_cached"])
			== int(manager_bindings["accessory_nodes_expected"]),
		"manager should cache the complete current accessory catalog",
		failures,
	)
	_check(
		int(manager_bindings["visible_accessory_count"])
			== int(manager_bindings["visible_accessory_expected"]),
		"manager should show only the executive bow tie and nameplate",
		failures,
	)
	_check(bool(manager_bindings["comb_cached"]), "manager comb should be cached", failures)
	_check(
		is_equal_approx(float(manager_bindings["comb_scale"]), ManagementPresence.MANAGER_COMB_SCALE),
		"manager comb should retain its larger rooster silhouette",
		failures,
	)
	_check(
		float(manager_bindings["comb_attachment_error"]) <= 0.0001,
		"manager comb scaling should preserve its exact crown contact anchor",
		failures,
	)
	_check(bool(manager_bindings["animation_player_cached"]), "manager animation player should be cached", failures)
	await create_timer(0.65).timeout
	manager_bindings = presence.model_binding_diagnostics()
	_check(
		float(manager_bindings["comb_attachment_error"]) <= 0.0001,
		"manager comb should remain seated on the crown during its walk animation",
		failures,
	)
	for accessory_name in ManagementPresence.MANAGER_ACCESSORIES:
		var accessory := presence.find_child(String(accessory_name), true, false) as Node3D
		var expected_visible := accessory_name in ManagementPresence.MANAGER_VISIBLE_ACCESSORIES
		_check(accessory != null, "manager should include %s" % accessory_name, failures)
		_check(
			accessory != null and accessory.visible == expected_visible,
			"manager accessory %s should have its authored executive visibility" % accessory_name,
			failures,
		)

	chicken.queue_free()
	presence.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("CHICKEN_RENDER_HOT_PATH_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print(
		"CHICKEN_RENDER_HOT_PATH_TEST_PASSED accessories=%d meshes=%d surfaces=%d wing_bones=4 manager_accessories=%d hidden_routes=active"
			% [
				int(chicken_bindings["accessory_nodes_cached"]),
				int(render_profile.meshes),
				int(render_profile.surfaces),
				int(manager_bindings["accessory_nodes_cached"]),
			]
	)
	quit(0)


func _render_profile(node: Node) -> Dictionary:
	var profile := {"meshes": 0, "surfaces": 0}
	if node == null:
		return profile
	for candidate in node.find_children("*", "MeshInstance3D", true, false):
		profile.meshes += 1
		var mesh := (candidate as MeshInstance3D).mesh
		if mesh != null:
			profile.surfaces += mesh.get_surface_count()
	return profile


func _count_meshes(node: Node) -> int:
	return node.find_children("*", "MeshInstance3D", true, false).size()


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
