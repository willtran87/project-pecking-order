extends SceneTree

const BURST_COUNT := 80
const POOL_SIZE := 30


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	for _frame in 4:
		await process_frame

	var egg_layer := office.get("_egg_layer") as Node3D
	var pool_nodes := egg_layer.find_children(
		"EggFleckPool*",
		"MeshInstance3D",
		true,
		false,
	)
	assert(pool_nodes.size() == POOL_SIZE)
	var first_mesh: Mesh = pool_nodes[0].mesh
	var initial_ids: Array[int] = []
	for node in pool_nodes:
		assert(node.mesh == first_mesh)
		assert(node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		assert(not node.visible)
		initial_ids.append(node.get_instance_id())

	var child_count_before := egg_layer.get_child_count()
	for sample_index in BURST_COUNT:
		office.call(
			"_spawn_egg_vfx",
			Vector3(float(sample_index % 8) * 0.2, 0.5, 0.0),
			&"golden" if sample_index % 10 == 0 else &"sound",
			sample_index % 8,
		)
	assert(egg_layer.get_child_count() == child_count_before)
	assert((office.get("_active_egg_flecks") as Array).size() <= POOL_SIZE)
	assert(_visible_count(pool_nodes) <= POOL_SIZE)

	office.call("_process_egg_fleck_pool", 1.0)
	assert((office.get("_active_egg_flecks") as Array).is_empty())
	assert(_visible_count(pool_nodes) == 0)
	for node in pool_nodes:
		assert(node.scale.is_zero_approx())

	for sample_index in 3:
		office.call("_spawn_egg_vfx", Vector3.ZERO, &"sound", sample_index)
	assert(egg_layer.get_child_count() == child_count_before)
	var reused_nodes := egg_layer.find_children(
		"EggFleckPool*",
		"MeshInstance3D",
		true,
		false,
	)
	for node_index in reused_nodes.size():
		assert(reused_nodes[node_index].get_instance_id() == initial_ids[node_index])

	print("EGG_VFX_POOL_TEST_PASSED")
	office.free()
	await process_frame
	quit(0)


func _visible_count(nodes: Array[Node]) -> int:
	var visible := 0
	for node in nodes:
		if node.visible:
			visible += 1
	return visible
