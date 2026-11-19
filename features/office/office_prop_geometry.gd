class_name OfficePropGeometry
extends RefCounted

## Shared opaque meshes. Built once; no extra nodes, animation or physics work.
static var _rounded: Dictionary = {}
static var _leaf: ArrayMesh
static var _rim: TorusMesh
static var _egg_cup: ArrayMesh


static func egg_cup() -> ArrayMesh:
	if _egg_cup != null:
		return _egg_cup
	# Closed lathed cross-section: flat underside, rolled lip and recessed bowl.
	# The hollow is real geometry, so it reads in the Compatibility renderer.
	var profile := [Vector2(0, -0.0125), Vector2(0.10, -0.0125),
		Vector2(0.145, 0.015), Vector2(0.17, 0.05), Vector2(0.17, 0.065),
		Vector2(0.15, 0.071), Vector2(0.135, 0.050), Vector2(0.095, 0.015),
		Vector2(0, 0.006)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shades := [0.65, 0.72, 0.84, 0.94, 1.0, 1.0, 0.78, 0.59, 0.48]
	for row in profile.size() - 1:
		for segment in 24:
			var a := TAU * float(segment) / 24.0
			var b := TAU * float(segment + 1) / 24.0
			var p: Vector2 = profile[row]
			var q: Vector2 = profile[row + 1]
			var vertices := [Vector3(cos(a) * p.x, p.y, sin(a) * p.x),
				Vector3(cos(b) * p.x, p.y, sin(b) * p.x),
				Vector3(cos(b) * q.x, q.y, sin(b) * q.x),
				Vector3(cos(a) * q.x, q.y, sin(a) * q.x)]
			var indices := [0, 1, 2, 0, 2, 3]
			if row == 0:
				indices = [0, 2, 3]
			elif row == profile.size() - 2:
				indices = [0, 1, 2]
			for index in indices:
				var shade: float = shades[row if index < 2 else row + 1]
				surface.set_color(Color(shade, shade, shade))
				surface.add_vertex(vertices[index])
	surface.generate_normals()
	surface.index()
	_egg_cup = surface.commit()
	return _egg_cup

static func rounded_box(size: Vector3, radius: float = 0.035) -> ArrayMesh:
	var r := minf(radius, minf(size.x, minf(size.y, size.z)) * 0.24)
	var key := "%s:%.4f" % [size, r]
	if _rounded.has(key):
		return _rounded[key]
	var box := BoxMesh.new()
	box.size = size
	box.subdivide_width = 4
	box.subdivide_height = 4
	box.subdivide_depth = 4
	var arrays := box.get_mesh_arrays()
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var normals := arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
	var half := size * 0.5
	var inner := half - Vector3.ONE * r
	for index in vertices.size():
		var p := vertices[index]
		for axis in 3:
			var step := clampi(roundi((p[axis] / size[axis] + 0.5) * 5), 0, 5)
			p[axis] = [-half[axis], -half[axis] + r * 0.292893, -inner[axis], inner[axis], half[axis] - r * 0.292893, half[axis]][step]
		var center := p.clamp(-inner, inner)
		var normal := (p - center).normalized()
		vertices[index] = center + normal * r
		normals[index] = normal
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = null
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_rounded[key] = mesh
	return mesh

static func leaf() -> ArrayMesh:
	if _leaf != null:
		return _leaf
	var source := SphereMesh.new()
	source.radius = 0.5
	source.height = 1.0
	source.radial_segments = 16
	source.rings = 8
	var arrays := source.get_mesh_arrays()
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	for index in vertices.size():
		var p := vertices[index]
		var t := p.y + 0.5
		# A tapered, cupped blade: stem at zero, curved tip at one.
		vertices[index] = Vector3(p.x * 0.64 * (1.0 - 0.45 * t), t, p.z * 0.045 + 0.28 * t * t)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TANGENT] = null
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var surface := SurfaceTool.new()
	surface.create_from(mesh, 0)
	surface.generate_normals()
	_leaf = surface.commit()
	return _leaf

static func pot_rim() -> TorusMesh:
	if _rim == null:
		_rim = TorusMesh.new()
		_rim.inner_radius = 0.87
		_rim.outer_radius = 1.0
		_rim.rings = 24
		_rim.ring_segments = 8
	return _rim
