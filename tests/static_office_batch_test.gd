extends SceneTree

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var parent := Node3D.new()
	root.add_child(parent)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("52765c")
	var sources: Array[MeshInstance3D] = []
	var expected_vertices := PackedVector3Array()
	var expected_bounds := AABB()
	for i in 3:
		var source := MeshInstance3D.new()
		source.mesh = BoxMesh.new()
		source.material_override = material
		source.position = Vector3(i * 3.0, i * 0.5, 0.0)
		source.rotation.y = i * 0.3
		source.scale = Vector3(1.0, 1.0 + i, 0.8)
		parent.add_child(source)
		sources.append(source)
		var bounds := source.transform * source.mesh.get_aabb()
		expected_bounds = bounds if i == 0 else expected_bounds.merge(bounds)
		for vertex: Vector3 in source.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			expected_vertices.append(source.transform * vertex)
	var animated := MeshInstance3D.new()
	animated.mesh = BoxMesh.new()
	animated.material_override = material
	parent.add_child(animated)
	var excluded: Array[Node3D] = [animated]
	var result := StaticOfficeBatch.build(parent, excluded)
	assert(result.sources == 3 and result.batches == 1 and result.triangles == 36)
	assert(animated.layers == 1, "Animated props must keep their own renderer")
	var batch := parent.get_node("StaticBatch_0") as MeshInstance3D
	assert(batch.get_aabb().is_equal_approx(expected_bounds), "Batch must preserve transformed bounds")
	assert(batch.material_override == material and batch.cast_shadow == sources[0].cast_shadow)
	var actual: PackedVector3Array = batch.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for expected in expected_vertices:
		var found := false
		for vertex in actual:
			if vertex.is_equal_approx(expected):
				found = true
				break
		assert(found, "Batch must preserve every transformed source vertex")
	for source in sources:
		assert(source.layers == 0 and source.mesh != null, "Reference sockets retain geometry without duplicate draws")
	parent.hide()
	assert(not batch.is_visible_in_tree(), "Parent visibility must still own the batch")
	parent.queue_free()
	await process_frame
	_test_solid_palette()
	await process_frame
	print("STATIC_OFFICE_BATCH_TEST_PASSED geometry=preserved palette=preserved normals=preserved animation=excluded visibility=inherited idempotent=true")
	quit()


func _solid(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	material.set_meta(&"static_office_solid", true)
	return material


func _prop(parent: Node3D, mesh: Mesh, material: Material) -> MeshInstance3D:
	var prop := MeshInstance3D.new()
	prop.mesh = mesh
	prop.material_override = material
	parent.add_child(prop)
	return prop


func _test_solid_palette() -> void:
	var parent := Node3D.new()
	root.add_child(parent)
	var sources: Array[MeshInstance3D] = [
		_prop(parent, BoxMesh.new(), _solid(Color("b2874e"))),
		_prop(parent, CylinderMesh.new(), _solid(Color("385262"))),
		_prop(parent, SphereMesh.new(), _solid(Color("66814e"))),
	]
	var expected_vertices := PackedVector3Array()
	var expected_normals := PackedVector3Array()
	var expected_uvs := PackedVector2Array()
	var expected_colors := PackedColorArray()
	var triangles := 0
	for i in sources.size():
		var source := sources[i]
		source.position = Vector3(i * 3, 0.2 * i, 0)
		source.rotation = Vector3(0.2 * i, 0.3 * i, 0.1)
		source.scale = Vector3(0.8, 1.0 + i, 1.2)
		var arrays := source.mesh.surface_get_arrays(0)
		triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
		for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
			expected_vertices.append(source.transform * vertex)
			expected_colors.append(source.material_override.albedo_color)
		for normal: Vector3 in arrays[Mesh.ARRAY_NORMAL]:
			expected_normals.append((source.transform.basis.inverse().transposed() * normal).normalized())
		expected_uvs.append_array(arrays[Mesh.ARRAY_TEX_UV])
	var untouched: Array[MeshInstance3D] = []
	var moving := _prop(parent, BoxMesh.new(), _solid(Color.RED))
	untouched.append(moving)
	for property_name in ["roughness", "metallic", "emission_enabled", "albedo_texture", "transparency", "next_pass", "vertex_color_use_as_albedo"]:
		var material := _solid(Color.WHITE)
		match property_name:
			"roughness": material.roughness = 0.1
			"metallic": material.metallic = 0.7
			"emission_enabled": material.emission_enabled = true
			"albedo_texture": material.albedo_texture = GradientTexture2D.new()
			"transparency": material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			"next_pass": material.next_pass = StandardMaterial3D.new()
			"vertex_color_use_as_albedo": material.vertex_color_use_as_albedo = true
		untouched.append(_prop(parent, BoxMesh.new(), material))
	var shadowless := _prop(parent, BoxMesh.new(), _solid(Color.WHITE))
	shadowless.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	untouched.append(shadowless)
	var child := Node3D.new()
	parent.add_child(child)
	untouched.append(_prop(child, BoxMesh.new(), _solid(Color.WHITE)))
	var result := StaticOfficeBatch.build(parent, [moving])
	assert(result.sources == 3 and result.batches == 1 and result.triangles == triangles, "Only compatible static palette siblings share a draw")
	var batch := parent.get_node("StaticBatch_0") as MeshInstance3D
	var material := batch.material_override as StandardMaterial3D
	assert(material.albedo_color == Color.WHITE and material.vertex_color_use_as_albedo and material.vertex_color_is_srgb)
	assert(is_equal_approx(material.roughness, 0.82) and material.metallic == 0.0)
	var arrays := batch.mesh.surface_get_arrays(0)
	assert(arrays[Mesh.ARRAY_VERTEX].size() == expected_vertices.size())
	for i in expected_vertices.size():
		assert(arrays[Mesh.ARRAY_VERTEX][i].is_equal_approx(expected_vertices[i]))
		assert(arrays[Mesh.ARRAY_NORMAL][i].dot(expected_normals[i]) > 0.9999, "Scaled primitive lighting must retain inverse-transpose normals")
		assert(arrays[Mesh.ARRAY_TEX_UV][i].is_equal_approx(expected_uvs[i]))
		var color: Color = arrays[Mesh.ARRAY_COLOR][i]
		var expected := expected_colors[i]
		assert(absf(color.r - expected.r) <= 1.0 / 255.0 and absf(color.g - expected.g) <= 1.0 / 255.0 and absf(color.b - expected.b) <= 1.0 / 255.0, "Standard vertex-color precision must preserve each palette color")
	for source in sources:
		assert(source.layers == 0 and source.mesh != null)
		assert(not source.material_override.vertex_color_use_as_albedo, "Shared source materials must remain unmodified")
	for source in untouched:
		assert(source.layers == 1, "Animated, separate-parent, shadow and material variants retain independent draws")
	assert(StaticOfficeBatch.build(parent, [moving]).sources == 0, "Repeated preparation must not batch existing batches")
	parent.hide()
	assert(not batch.is_visible_in_tree())
	parent.queue_free()
