class_name StaticOfficeBatch
extends RefCounted

## Combines opaque, stationary siblings without changing their geometry or
## parent visibility. Source nodes remain available as placement/reference
## sockets; only their rendering layer is retired. Animated parts are excluded.
static func build(root: Node3D, animated: Array[Node3D]) -> Dictionary:
	var result := {"sources": 0, "batches": 0, "triangles": 0}
	var defaults := StandardMaterial3D.new()
	var material_defaults: Dictionary = {}
	for property in defaults.get_property_list():
		var property_name := String(property.name)
		if int(property.usage) & PROPERTY_USAGE_STORAGE and not property_name.begins_with("resource_"):
			if property_name not in ["albedo_color", "roughness", "metallic"]:
				material_defaults[property_name] = defaults.get(property_name)
	_batch_parent(root, animated, result, material_defaults, {})
	return result


static func _batch_parent(parent: Node3D, animated: Array[Node3D], result: Dictionary, material_defaults: Dictionary, styles: Dictionary) -> void:
	var groups: Dictionary = {}
	for child in parent.get_children():
		if child in animated:
			continue
		if child is Node3D:
			_batch_parent(child, animated, result, material_defaults, styles)
		if not child is MeshInstance3D:
			continue
		var source := child as MeshInstance3D
		if not source.visible or source.layers == 0 or source.skin != null or source.material_overlay != null or source.has_meta("static_batch_sources"):
			continue
		if source.mesh == null or source.mesh.get_surface_count() != 1:
			continue
		var material := source.get_active_material(0) as BaseMaterial3D
		if material == null or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
			continue
		if source.mesh is ArrayMesh and (source.mesh as ArrayMesh).surface_get_primitive_type(0) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var format_key := str((source.mesh as ArrayMesh).surface_get_format(0)) if source.mesh is ArrayMesh else source.mesh.get_class()
		var style := _solid_style(material, material_defaults, styles)
		# Only these authored primitives have the same vertex/normal/tangent/UV
		# layout and no pre-existing vertex colors, skinning or custom channels.
		var colored := not style.is_empty() and (source.mesh is BoxMesh or source.mesh is CylinderMesh or source.mesh is SphereMesh)
		if source.transform.basis.determinant() <= 0.0:
			continue
		var material_key := "solid:" + style if colored else str(material.get_instance_id())
		var key := "%s:%d:%d:%s" % [material_key, source.cast_shadow, source.layers, "solid_primitives" if colored else format_key]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(source)
	for key in groups:
		var sources := groups[key] as Array
		if sources.size() < 3:
			continue
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var colored := String(key).begins_with("solid:")
		var colors := PackedColorArray()
		var normals := PackedVector3Array()
		var tangents := PackedFloat32Array()
		var triangles := 0
		for source: MeshInstance3D in sources:
			surface.append_from(source.mesh, 0, source.transform)
			var arrays := source.mesh.surface_get_arrays(0)
			var indices := arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
			var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
			triangles += (indices.size() if not indices.is_empty() else vertices.size()) / 3
			if colored:
				var color := (source.get_active_material(0) as StandardMaterial3D).albedo_color
				var source_colors := PackedColorArray()
				source_colors.resize(vertices.size())
				source_colors.fill(color)
				colors.append_array(source_colors)
				# Match the renderer's inverse-transpose normal transform, including
				# non-uniformly scaled spheres. append_from uses the vertex basis.
				var normal_basis := source.transform.basis.inverse().transposed()
				for normal: Vector3 in arrays[Mesh.ARRAY_NORMAL]:
					normals.append((normal_basis * normal).normalized())
				var source_tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
				for i in range(0, source_tangents.size(), 4):
					var tangent := (normal_basis * Vector3(source_tangents[i], source_tangents[i + 1], source_tangents[i + 2])).normalized()
					tangents.append_array(PackedFloat32Array([tangent.x, tangent.y, tangent.z, source_tangents[i + 3]]))
		var first := sources[0] as MeshInstance3D
		var mesh: ArrayMesh
		var batch_material := first.get_active_material(0)
		if colored:
			var arrays := surface.commit_to_arrays()
			arrays[Mesh.ARRAY_COLOR] = colors
			arrays[Mesh.ARRAY_NORMAL] = normals
			arrays[Mesh.ARRAY_TANGENT] = tangents
			mesh = ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var palette_key := "batch:" + _solid_style(batch_material, material_defaults, styles)
			if not styles.has(palette_key):
				var solid := batch_material.duplicate() as StandardMaterial3D
				solid.albedo_color = Color.WHITE
				solid.vertex_color_use_as_albedo = true
				solid.vertex_color_is_srgb = true
				styles[palette_key] = solid
			batch_material = styles[palette_key]
		else:
			mesh = surface.commit()
		if mesh == null:
			continue
		var batch := MeshInstance3D.new()
		batch.name = "StaticBatch_%d" % int(result.batches)
		batch.mesh = mesh
		batch.material_override = batch_material
		batch.cast_shadow = first.cast_shadow
		batch.layers = first.layers
		batch.set_meta("static_batch_sources", sources.size())
		batch.set_meta("static_batch_triangles", triangles)
		parent.add_child(batch)
		for source: MeshInstance3D in sources:
			source.set_meta("static_batch_original_layers", source.layers)
			source.layers = 0
		result.sources += sources.size()
		result.batches += 1
		result.triangles += triangles


static func _solid_style(material: BaseMaterial3D, defaults: Dictionary, styles: Dictionary) -> String:
	var id := material.get_instance_id()
	if styles.has(id):
		return styles[id]
	styles[id] = ""
	# An explicit authoring promise: the palette is immutable after construction.
	# Ordinary/dynamic materials retain the original shared-resource batching.
	if not material is StandardMaterial3D or not material.get_meta(&"static_office_solid", false):
		return ""
	# Fail closed if a palette entry acquires a texture, emission, next pass,
	# shader feature, or any other non-default rendering property.
	for property_name in defaults:
		if material.get(property_name) != defaults[property_name]:
			return ""
	styles[id] = "%s:%s" % [var_to_str(material.roughness), var_to_str(material.metallic)]
	return styles[id]
