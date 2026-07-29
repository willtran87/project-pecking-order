extends SceneTree

## Read-only profiler for procedural primitive residency in the Office scene. Run with:
## Godot --headless --path . --script tools/profile_procedural_meshes.gd


func _init() -> void:
	_profile.call_deferred()


func _profile() -> void:
	root.size = Vector2i(1280, 720)
	var construction_started := Time.get_ticks_usec()
	var office := Office.new()
	var construction_usec := Time.get_ticks_usec() - construction_started
	var attachment_started := Time.get_ticks_usec()
	root.add_child(office)
	var attachment_usec := Time.get_ticks_usec() - attachment_started
	for _frame in 12:
		await process_frame

	var mesh_instances := office.find_children("*", "MeshInstance3D", true, false)
	var primitive_instances := 0
	var primitive_resources: Dictionary = {}
	var signature_counts: Dictionary = {}
	var signature_resources: Dictionary = {}
	for child in mesh_instances:
		var instance := child as MeshInstance3D
		var mesh := instance.mesh
		var signature := _primitive_signature(mesh)
		if signature.is_empty():
			continue
		primitive_instances += 1
		primitive_resources[mesh.get_instance_id()] = true
		signature_counts[signature] = int(signature_counts.get(signature, 0)) + 1
		var resource_ids: Dictionary = signature_resources.get(signature, {})
		resource_ids[mesh.get_instance_id()] = true
		signature_resources[signature] = resource_ids

	var duplicate_signature_instances := 0
	var shareable_resource_excess := 0
	var repeated_signatures := 0
	for signature in signature_counts:
		var count := int(signature_counts[signature])
		if count <= 1:
			continue
		repeated_signatures += 1
		duplicate_signature_instances += count
		var resource_count: int = (signature_resources[signature] as Dictionary).size()
		shareable_resource_excess += maxi(0, resource_count - 1)

	print("PROCEDURAL_MESH_PROFILE %s" % JSON.stringify({
		"construction_usec": construction_usec,
		"attachment_usec": attachment_usec,
		"mesh_instances": mesh_instances.size(),
		"primitive_instances": primitive_instances,
		"primitive_resources": primitive_resources.size(),
		"primitive_signatures": signature_counts.size(),
		"repeated_signatures": repeated_signatures,
		"duplicate_signature_instances": duplicate_signature_instances,
		"shareable_resource_excess": shareable_resource_excess,
	}))
	office.free()
	await process_frame
	quit(0)


func _primitive_signature(mesh: Mesh) -> String:
	if mesh is BoxMesh:
		var box := mesh as BoxMesh
		return "box:%s" % _vector3_key(box.size)
	if mesh is CylinderMesh:
		var cylinder := mesh as CylinderMesh
		return "cylinder:%.5f:%.5f:%.5f:%d:%d" % [
			cylinder.top_radius,
			cylinder.bottom_radius,
			cylinder.height,
			cylinder.radial_segments,
			cylinder.rings,
		]
	if mesh is SphereMesh:
		var sphere := mesh as SphereMesh
		return "sphere:%.5f:%.5f:%d:%d" % [
			sphere.radius,
			sphere.height,
			sphere.radial_segments,
			sphere.rings,
		]
	return ""


func _vector3_key(value: Vector3) -> String:
	return "%.5f:%.5f:%.5f" % [value.x, value.y, value.z]
