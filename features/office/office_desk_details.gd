class_name OfficeDeskDetails
extends RefCounted

## Cached, single-surface miniatures: personal desk art without per-frame work.
static var _portraits: Dictionary = {}
static var _portrait_material: StandardMaterial3D
static var _pencil: ArrayMesh
static var _ceramic_material: StandardMaterial3D
static var _files: Dictionary = {}
static var _desk_inlay: ArrayMesh
static var _glazing: ArrayMesh
static var _contact_ring: ArrayMesh


static func contact_ring() -> ArrayMesh:
	if _contact_ring != null:
		return _contact_ring
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment in 16:
		var a := float(segment) * TAU / 16.0
		var b := float(segment + 1) * TAU / 16.0
		var outer_a := Vector3(cos(a), sin(a), 0) * 0.5
		var outer_b := Vector3(cos(b), sin(b), 0) * 0.5
		var inner_a := outer_a * 0.72
		var inner_b := outer_b * 0.72
		# Both faces are authored, keeping the existing opaque material variant.
		for face in [1.0, -1.0]:
			surface.set_normal(Vector3(0, 0, face))
			var points := [outer_a, outer_b, inner_b, outer_a, inner_b, inner_a]
			if face < 0.0:
				points.reverse()
			for point in points:
				surface.add_vertex(point)
	surface.index()
	_contact_ring = surface.commit()
	return _contact_ring


## Printed details are geometry in the existing paper surface: shared by every
## desk, opaque, and only built once. No labels, decals or per-file child nodes.
static func work_file(index: int) -> ArrayMesh:
	var variant := posmod(index, 3)
	if _files.has(variant):
		return _files[variant]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_part(surface, ProceduralPrimitiveCache.box(Vector3(0.48, 0.018, 0.34)), Vector3.ZERO, Vector3.ONE, Color("ddd8bf") if variant != 1 else Color("c3d1c7"))
	var ink := Color("708b85")
	_part(surface, ProceduralPrimitiveCache.box(Vector3(0.31, 0.002, 0.027)), Vector3(-0.025, 0.0105, -0.115), Vector3.ONE, ink)
	for line in 4:
		_part(surface, ProceduralPrimitiveCache.box(Vector3(0.23 - (line % 2) * 0.045, 0.002, 0.008)), Vector3(-0.048, 0.0105, -0.055 + line * 0.037), Vector3.ONE, ink.lightened(0.15))
	# A colored index tab and a small ink seal distinguish files without text.
	_part(surface, ProceduralPrimitiveCache.box(Vector3(0.07, 0.008, 0.07)), Vector3(0.19, 0.007, -0.145), Vector3.ONE, [Color("b47b59"), Color("759583"), Color("aa8d52")][variant])
	_part(surface, ProceduralPrimitiveCache.cylinder(0.032, 0.032, 0.003, 12), Vector3(0.145, 0.011, 0.095), Vector3.ONE, Color("ad7463"))
	surface.index()
	_files[variant] = surface.commit()
	return _files[variant]


static func desk_inlay() -> ArrayMesh:
	if _desk_inlay != null:
		return _desk_inlay
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# A leather writing pad frames the keyboard; a cork coaster grounds the mug.
	_part(surface, ProceduralPrimitiveCache.box(Vector3(1.70, 0.008, 0.64)), Vector3(0, 0.884, -0.29), Vector3.ONE, Color("3e5d59"))
	for side in [-1.0, 1.0]:
		_part(surface, ProceduralPrimitiveCache.box(Vector3(1.59, 0.002, 0.008)), Vector3(0, 0.889, -0.29 + side * 0.27), Vector3.ONE, Color("9eab94"))
		_part(surface, ProceduralPrimitiveCache.box(Vector3(0.008, 0.002, 0.54)), Vector3(side * 0.795, 0.889, -0.29), Vector3.ONE, Color("9eab94"))
	_part(surface, ProceduralPrimitiveCache.cylinder(0.15, 0.15, 0.007, 24), Vector3(0.4, 0.885, 0.4), Vector3.ONE, Color("927548"))
	surface.index()
	_desk_inlay = surface.commit()
	return _desk_inlay


static func window_glazing() -> ArrayMesh:
	if _glazing != null:
		return _glazing
	var arrays := ProceduralPrimitiveCache.box(Vector3(2.75, 1.38, 0.045)).surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors := PackedColorArray()
	for vertex in vertices:
		colors.append(Color("c3cdb7").lerp(Color("577f98"), clampf((vertex.y + 0.69) / 1.38, 0.0, 1.0)))
	arrays[Mesh.ARRAY_COLOR] = colors
	_glazing = ArrayMesh.new()
	_glazing.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _glazing


static func ceramic_material() -> StandardMaterial3D:
	if _ceramic_material == null:
		_ceramic_material = StandardMaterial3D.new()
		_ceramic_material.vertex_color_use_as_albedo = true
		_ceramic_material.roughness = 0.32
	return _ceramic_material


static func portrait_material() -> StandardMaterial3D:
	if _portrait_material == null:
		_portrait_material = StandardMaterial3D.new()
		_portrait_material.vertex_color_use_as_albedo = true
		_portrait_material.roughness = 0.86
	return _portrait_material


static func pencil() -> ArrayMesh:
	if _pencil != null:
		return _pencil
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_part(surface, ProceduralPrimitiveCache.cylinder(0.015, 0.015, 0.38, 6), Vector3.ZERO, Vector3.ONE, Color("d6ad52"))
	_part(surface, ProceduralPrimitiveCache.cylinder(0.016, 0.016, 0.035, 12), Vector3(0, 0.17, 0), Vector3.ONE, Color("aaa99b"))
	_part(surface, ProceduralPrimitiveCache.cylinder(0.015, 0.015, 0.025, 12), Vector3(0, 0.195, 0), Vector3.ONE, Color("bf8076"))
	surface.index()
	_pencil = surface.commit()
	return _pencil


static func portrait(index: int) -> ArrayMesh:
	var variant := posmod(index, 3)
	if _portraits.has(variant):
		return _portraits[variant]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	var count := 3 if variant == 2 else 2
	for chick in count:
		var x := (float(chick) - float(count - 1) * 0.5) * (0.105 if count == 3 else 0.15)
		var small := 0.79 if chick == 1 else 1.0
		var down := -0.035 if chick == 1 else 0.0
		var plumage := Color("f0cc75") if chick != variant else Color("e6ddbd")
		_part(surface, sphere, Vector3(x, -0.055 + down, 0), Vector3(0.060, 0.074, 0.012) * small, plumage)
		_part(surface, sphere, Vector3(x, 0.033 + down, 0.006), Vector3(0.051, 0.054, 0.014) * small, plumage)
		_part(surface, sphere, Vector3(x, 0.085 + down, 0.008), Vector3(0.014, 0.023, 0.010) * small, Color("b65b49"))
		for side in [-1.0, 1.0]:
			_part(surface, sphere, Vector3(x + side * 0.018 * small, 0.044 + down, 0.021), Vector3(0.006, 0.008, 0.003), Color("2b3535"))
		_part(surface, sphere, Vector3(x, 0.024 + down, 0.024), Vector3(0.013, 0.009, 0.006), Color("ce8b31"))
		_part(surface, sphere, Vector3(x, -0.021 + down, 0.014), Vector3(0.024, 0.009, 0.006), Color("577e78") if variant == 0 else Color("a96861"))
	surface.index()
	var mesh := surface.commit()
	_portraits[variant] = mesh
	return mesh


static func _part(surface: SurfaceTool, mesh: Mesh, at: Vector3, size: Vector3, color: Color) -> void:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors := PackedColorArray()
	colors.resize(vertices.size())
	colors.fill(color)
	arrays[Mesh.ARRAY_COLOR] = colors
	var painted := ArrayMesh.new()
	painted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	surface.append_from(painted, 0, Transform3D(Basis.from_scale(size), at))
