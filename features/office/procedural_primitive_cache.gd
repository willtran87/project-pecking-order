class_name ProceduralPrimitiveCache
extends RefCounted

## Process-wide immutable primitive meshes for authored office fixtures.
##
## MeshInstance3D nodes still own their transforms and materials. Callers must
## treat returned meshes as immutable; animated or resized geometry should keep
## a dedicated mesh resource instead.

static var _boxes: Dictionary = {}
static var _cylinders: Dictionary = {}
static var _spheres: Dictionary = {}


static func box(size: Vector3) -> BoxMesh:
	if not _boxes.has(size):
		var mesh := BoxMesh.new()
		mesh.size = size
		_boxes[size] = mesh
	return _boxes[size] as BoxMesh


static func cylinder(
	top_radius: float,
	bottom_radius: float,
	height: float,
	radial_segments: int,
	rings: int = 4,
) -> CylinderMesh:
	var key := "%s|%s|%s|%d|%d" % [
		String.num(top_radius, 9),
		String.num(bottom_radius, 9),
		String.num(height, 9),
		radial_segments,
		rings,
	]
	if not _cylinders.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = top_radius
		mesh.bottom_radius = bottom_radius
		mesh.height = height
		mesh.radial_segments = radial_segments
		mesh.rings = rings
		_cylinders[key] = mesh
	return _cylinders[key] as CylinderMesh


static func sphere(
	radius: float,
	height: float,
	radial_segments: int,
	rings: int,
) -> SphereMesh:
	var key := "%s|%s|%d|%d" % [
		String.num(radius, 9),
		String.num(height, 9),
		radial_segments,
		rings,
	]
	if not _spheres.has(key):
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = height
		mesh.radial_segments = radial_segments
		mesh.rings = rings
		_spheres[key] = mesh
	return _spheres[key] as SphereMesh


static func diagnostics() -> Dictionary:
	return {
		"boxes": _boxes.size(),
		"cylinders": _cylinders.size(),
		"spheres": _spheres.size(),
		"total": _boxes.size() + _cylinders.size() + _spheres.size(),
	}
