extends SceneTree

## Read-only scene residency profiler. Run with:
## Godot --headless --path . --script tools/profile_office_scene.gd


func _init() -> void:
	create_timer(120.0).timeout.connect(func() -> void:
		push_error("OFFICE_SCENE_PROFILE_TIMEOUT")
		quit(1)
	)
	_profile.call_deferred()


func _profile() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	for _frame in 6:
		await process_frame
	var rows: Array[Dictionary] = []
	for child in office.get_children():
		rows.append(_measure_subtree(child))
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("visible_surfaces", 0)) > int(right.get("visible_surfaces", 0))
	)
	print("OFFICE_SCENE_PROFILE_BEGIN")
	for row in rows:
		print(JSON.stringify(row))
	for root_name in [
		"OfficePhysicalPresentation", "OfficeStorytelling", "ClaimsDesks", "Workers",
		"CoreOfficePresentation", "VisibleEggCollectionChain", "RoosterManagementPerch",
		"Workstation_00",
	]:
		var profile_root := office.find_child(root_name, true, false)
		if profile_root == null:
			continue
		var child_rows: Array[Dictionary] = []
		for child in profile_root.get_children():
			child_rows.append(_measure_subtree(child))
		child_rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
			return int(left.get("visible_surfaces", 0)) > int(right.get("visible_surfaces", 0))
		)
		print("OFFICE_SCENE_PROFILE_BREAKDOWN %s" % root_name)
		for child_row in child_rows:
			if int(child_row.get("nodes", 0)) > 8 or int(child_row.get("visible_surfaces", 0)) > 0:
				print(JSON.stringify(child_row))
	print("OFFICE_SCENE_PROFILE_TOTAL %s" % JSON.stringify(_measure_subtree(office)))
	print("OFFICE_SCENE_PROFILE_END")
	office.free()
	await process_frame
	quit(0)


func _measure_subtree(node: Node) -> Dictionary:
	var nodes := 0
	var meshes := 0
	var visible_meshes := 0
	var surfaces := 0
	var visible_surfaces := 0
	var multimeshes := 0
	var multimesh_instances := 0
	var visible_multimeshes := 0
	var visible_multimesh_instances := 0
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		nodes += 1
		if current is MeshInstance3D:
			var mesh_instance := current as MeshInstance3D
			var surface_count: int = mesh_instance.mesh.get_surface_count() if mesh_instance.mesh != null else 0
			meshes += 1
			surfaces += surface_count
			if mesh_instance.is_visible_in_tree():
				visible_meshes += 1
				visible_surfaces += surface_count
		elif current is MultiMeshInstance3D:
			var multimesh_instance := current as MultiMeshInstance3D
			var instance_count := (
				multimesh_instance.multimesh.instance_count
				if multimesh_instance.multimesh != null
				else 0
			)
			multimeshes += 1
			multimesh_instances += instance_count
			if multimesh_instance.is_visible_in_tree():
				visible_multimeshes += 1
				visible_multimesh_instances += instance_count
		for child in current.get_children():
			stack.append(child)
	return {
		"name": String(node.name),
		"class": node.get_class(),
		"nodes": nodes,
		"meshes": meshes,
		"visible_meshes": visible_meshes,
		"surfaces": surfaces,
		"visible_surfaces": visible_surfaces,
		"multimeshes": multimeshes,
		"multimesh_instances": multimesh_instances,
		"visible_multimeshes": visible_multimeshes,
		"visible_multimesh_instances": visible_multimesh_instances,
		"visible_draw_submissions": visible_meshes + visible_multimeshes,
	}
