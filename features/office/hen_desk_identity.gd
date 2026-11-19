class_name HenDeskIdentity
extends RefCounted

## Fixed, shared, opaque meshes. No new lights, textures, timers or save state.
const ACCENTS := [Color("d4ae59"), Color("83a8bc"), Color("b87a60"), Color("a28bba"), Color("89a793"), Color("a3ad6b")]
const MOTIFS := ["SUNBURST", "QUILL", "TEACUP", "CONVERSATION", "CHECKLIST", "LEAF"]
const HARDWARE := [Color("74b9a7"), Color("f0c968"), Color("a38aaa")]
static var _records: Dictionary = {}
static var _hardware: Dictionary = {}
static var _finish: StandardMaterial3D


static func finish() -> StandardMaterial3D:
	if _finish == null:
		_finish = StandardMaterial3D.new()
		_finish.vertex_color_use_as_albedo = true
		_finish.roughness = 0.46
		_finish.metallic_specular = 0.35
	return _finish


static func record(worker_id: int, level: int) -> ArrayMesh:
	var identity := posmod(worker_id, 6)
	var tier := clampi(level, 0, 3)
	var key := identity * 4 + tier
	if _records.has(key):
		return _records[key]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var accent: Color = ACCENTS[identity]
	box(surface, Vector3.ZERO, Vector3(0.64, 0.26, 0.035), Color("434c48"))
	box(surface, Vector3(0, 0, 0.021), Vector3(0.60, 0.22, 0.012), Color("e3d6b6"))
	# Six recognizable stamped keepsakes, tied to the hen rather than the desk.
	var at := Vector3(-0.19, 0.0, 0.037)
	match identity:
		0:
			oval(surface, at, Vector3(0.085, 0.085, 0.015), accent)
			for ray in 8:
				var angle := ray * TAU / 8.0
				piece(surface, ProceduralPrimitiveCache.box(Vector3(0.014, 0.034, 0.012)), at + Vector3(sin(angle), cos(angle), 0) * 0.074, Vector3.ONE, accent, Vector3(0, 0, -angle))
		1:
			piece(surface, ProceduralPrimitiveCache.sphere(0.5, 1.0, 12, 6), at, Vector3(0.060, 0.16, 0.016), accent, Vector3(0, 0, -0.5))
			box(surface, at + Vector3(0.02, -0.045, 0.005), Vector3(0.012, 0.10, 0.014), Color("555e55"))
		2:
			oval(surface, at + Vector3(0.065, 0, 0), Vector3(0.060, 0.070, 0.014), accent)
			oval(surface, at + Vector3(0.066, 0, 0.009), Vector3(0.030, 0.039, 0.010), Color("e3d6b6"))
			box(surface, at, Vector3(0.11, 0.09, 0.025), accent)
			box(surface, at + Vector3(0, -0.064, 0), Vector3(0.17, 0.018, 0.018), accent)
		3:
			oval(surface, at, Vector3(0.17, 0.12, 0.018), accent)
			box(surface, at + Vector3(-0.045, -0.052, 0), Vector3(0.035, 0.047, 0.018), accent)
			for dot in 3:
				oval(surface, at + Vector3(-0.045 + dot * 0.045, 0, 0.014), Vector3.ONE * 0.018, Color("f2ead0"))
		4:
			for line in 3:
				box(surface, at + Vector3(-0.058, 0.058 - line * 0.058, 0), Vector3(0.029, 0.029, 0.015), accent)
				box(surface, at + Vector3(0.022, 0.058 - line * 0.058, 0), Vector3(0.085, 0.012, 0.015), accent)
		5:
			for side in [-1.0, 1.0]:
				piece(surface, ProceduralPrimitiveCache.sphere(0.5, 1.0, 12, 6), at + Vector3(side * 0.035, 0.016, 0), Vector3(0.065, 0.14, 0.016), accent, Vector3(0, 0, side * -0.45))
			box(surface, at + Vector3(0, -0.045, 0.005), Vector3(0.014, 0.10, 0.014), accent)
	# Three empty sockets become earned career seals at the real XP thresholds.
	var seal_colors := [Color("b47d4e"), Color("becacb"), Color("e4bb5d")]
	for step in 3:
		var center := Vector3(-0.025 + step * 0.105, 0.015, 0.041)
		oval(surface, center, Vector3(0.078, 0.078, 0.018), seal_colors[step] if step < tier else Color("b4b39e"))
		if step < tier:
			box(surface, center + Vector3(0, -0.060, -0.005), Vector3(0.039, 0.061, 0.014), accent)
		else:
			oval(surface, center + Vector3(0, 0, 0.010), Vector3(0.043, 0.043, 0.009), Color("d6cbb0"))
	surface.index()
	_records[key] = surface.commit()
	return _records[key]


static func hardware(kind: int, level: int) -> ArrayMesh:
	var type := clampi(kind, 0, 2)
	var tier := clampi(level, 0, 5)
	var key := type * 6 + tier
	if _hardware.has(key):
		return _hardware[key]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var accent: Color = HARDWARE[type]
	oval(surface, Vector3.ZERO, Vector3(0.25, 0.25, 0.035), Color("526160"))
	match type:
		0:
			for cap in 3:
				box(surface, Vector3(-0.058 + cap * 0.058, 0.025, 0.033), Vector3(0.042, 0.042, 0.018), accent)
		1:
			box(surface, Vector3(-0.03, 0.025, 0.032), Vector3(0.022, 0.10, 0.018), accent)
			box(surface, Vector3(0.005, 0.070, 0.032), Vector3(0.09, 0.018, 0.018), accent)
			oval(surface, Vector3(0.049, 0.035, 0.034), Vector3(0.068, 0.050, 0.025), accent)
		2:
			oval(surface, Vector3(0, 0.035, 0.032), Vector3(0.16, 0.10, 0.026), accent)
	for pip in 5:
		box(surface, Vector3(-0.076 + pip * 0.038, -0.060, 0.032), Vector3(0.023, 0.025, 0.014), accent.lightened(0.20) if pip < tier else Color("303c3c"))
	surface.index()
	_hardware[key] = surface.commit()
	return _hardware[key]


static func box(surface: SurfaceTool, at: Vector3, size: Vector3, color: Color) -> void:
	piece(surface, ProceduralPrimitiveCache.box(size), at, Vector3.ONE, color)


static func oval(surface: SurfaceTool, at: Vector3, size: Vector3, color: Color) -> void:
	piece(surface, ProceduralPrimitiveCache.sphere(0.5, 1.0, 12, 6), at, size, color)


static func piece(surface: SurfaceTool, mesh: Mesh, at: Vector3, size: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO) -> void:
	var arrays := mesh.surface_get_arrays(0)
	var colors := PackedColorArray()
	colors.resize((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	colors.fill(color)
	arrays[Mesh.ARRAY_COLOR] = colors
	var painted := ArrayMesh.new()
	painted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	surface.append_from(painted, 0, Transform3D(Basis.from_euler(rotation).scaled(size), at))
