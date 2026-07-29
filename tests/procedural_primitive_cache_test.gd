extends SceneTree

const PrimitiveCacheScript := preload("res://features/office/procedural_primitive_cache.gd")


func _init() -> void:
	var failures: Array[String] = []
	var box_size := Vector3(1.25, 0.18, 0.72)
	var box_a := PrimitiveCacheScript.box(box_size)
	var box_b := PrimitiveCacheScript.box(box_size)
	var box_other := PrimitiveCacheScript.box(Vector3(1.26, 0.18, 0.72))
	_check(box_a == box_b, "identical box geometry should share one immutable resource", failures)
	_check(box_a != box_other, "different box geometry must not alias", failures)
	_check(box_a.size == box_size, "shared box dimensions must remain exact", failures)

	var cylinder_a := PrimitiveCacheScript.cylinder(0.18, 0.20, 0.64, 16)
	var cylinder_b := PrimitiveCacheScript.cylinder(0.18, 0.20, 0.64, 16)
	var cylinder_other := PrimitiveCacheScript.cylinder(0.18, 0.20, 0.64, 12)
	_check(
		cylinder_a == cylinder_b,
		"identical cylinder geometry should share one immutable resource",
		failures,
	)
	_check(cylinder_a != cylinder_other, "cylinder segment counts must remain distinct", failures)

	var sphere_a := PrimitiveCacheScript.sphere(0.5, 1.0, 16, 8)
	var sphere_b := PrimitiveCacheScript.sphere(0.5, 1.0, 16, 8)
	var sphere_other := PrimitiveCacheScript.sphere(0.5, 1.0, 16, 10)
	_check(sphere_a == sphere_b, "identical sphere geometry should share one immutable resource", failures)
	_check(sphere_a != sphere_other, "sphere ring counts must remain distinct", failures)

	var first_instance := MeshInstance3D.new()
	first_instance.mesh = box_a
	first_instance.position = Vector3(1.0, 2.0, 3.0)
	var second_instance := MeshInstance3D.new()
	second_instance.mesh = box_b
	second_instance.position = Vector3(-1.0, 0.5, 4.0)
	_check(
		first_instance.position != second_instance.position,
		"shared geometry must leave per-instance transforms independent",
		failures,
	)
	first_instance.free()
	second_instance.free()

	if not failures.is_empty():
		for failure: String in failures:
			push_error("PROCEDURAL_PRIMITIVE_CACHE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print(
		"PROCEDURAL_PRIMITIVE_CACHE_TEST_PASSED resources=%s"
		% JSON.stringify(PrimitiveCacheScript.diagnostics())
	)
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
