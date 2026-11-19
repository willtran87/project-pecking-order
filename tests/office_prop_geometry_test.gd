extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	for size in [Vector3(1.45, 1.18, 0.95), Vector3(0.5, 0.09, 0.3)]:
		var mesh := OfficePropGeometry.rounded_box(size)
		if not mesh.get_aabb().size.is_equal_approx(size):
			failures.append("rounded furniture must preserve authored bounds")
		if mesh != OfficePropGeometry.rounded_box(size):
			failures.append("repeated props must reuse the mesh")
		var arrays := mesh.surface_get_arrays(0)
		for normal in arrays[Mesh.ARRAY_NORMAL]:
			if not normal.is_finite() or not is_equal_approx(normal.length(), 1.0):
				failures.append("rounded edges must have finite unit normals")
	var leaf := OfficePropGeometry.leaf()
	var cup := OfficePropGeometry.egg_cup()
	var cup_arrays := cup.surface_get_arrays(0)
	var cup_vertices: PackedVector3Array = cup_arrays[Mesh.ARRAY_VERTEX]
	var cup_normals: PackedVector3Array = cup_arrays[Mesh.ARRAY_NORMAL]
	for index in cup_vertices.size():
		var p := cup_vertices[index]
		if not cup_normals[index].is_finite() or cup_normals[index].length() < 0.95:
			failures.append("molded cup must have finite surface normals")
		if absf(p.x) + absf(p.z) < 0.0001 and p.y > 0.0 and cup_normals[index].y < 0.95:
			failures.append("recessed cup interior must face up")
	if cup != OfficePropGeometry.egg_cup():
		failures.append("all egg cups must reuse the same mesh")
	if leaf != OfficePropGeometry.leaf() or absf(leaf.get_aabb().position.y) > 0.001 or absf(leaf.get_aabb().end.y - 1.0) > 0.001:
		failures.append("shared leaf must grow from its attachment point")
	if failures.is_empty():
		print("OFFICE_PROP_GEOMETRY_TEST_PASSED bounds=preserved normals=finite leaf=rooted resources=shared")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
