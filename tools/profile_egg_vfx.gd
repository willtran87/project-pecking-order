extends SceneTree

## Read-only first-use/allocation profiler for the high-frequency egg effect.
## Godot --headless --path . --script tools/profile_egg_vfx.gd

const SAMPLE_COUNT := 40


func _init() -> void:
	_profile.call_deferred()


func _profile() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	for _frame in 4:
		await process_frame
	var egg_layer := office.get("_egg_layer") as Node3D
	var objects_before := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var started := Time.get_ticks_usec()
	for sample_index in SAMPLE_COUNT:
		office.call(
			"_spawn_egg_vfx",
			Vector3(float(sample_index % 6) * 0.25, 0.5, 0.0),
			&"golden" if sample_index % 10 == 0 else &"sound",
			sample_index % 6,
		)
	var spawn_usec := Time.get_ticks_usec() - started
	var objects_after_spawn := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes_after_spawn := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var pool_size := egg_layer.find_children("EggFleckPool*", "MeshInstance3D", true, false).size()
	var visible_after_spawn := _count_visible_flecks(egg_layer)
	var active_after_spawn := _active_fleck_count(office)
	for _frame in 45:
		office.call("_process_egg_fleck_pool", 1.0 / 60.0)
	var visible_after_settle := _count_visible_flecks(egg_layer)
	var active_after_settle := _active_fleck_count(office)
	print("EGG_VFX_PROFILE %s" % JSON.stringify({
		"sample_count": SAMPLE_COUNT,
		"spawn_total_usec": spawn_usec,
		"spawn_average_usec": float(spawn_usec) / float(SAMPLE_COUNT),
		"objects_created": objects_after_spawn - objects_before,
		"nodes_created": nodes_after_spawn - nodes_before,
		"pool_size": pool_size,
		"visible_after_spawn": visible_after_spawn,
		"active_after_spawn": active_after_spawn,
		"visible_after_settle": visible_after_settle,
		"active_after_settle": active_after_settle,
	}))
	office.free()
	await process_frame
	quit(0)


func _count_visible_flecks(egg_layer: Node) -> int:
	var visible := 0
	for fleck in egg_layer.find_children("EggFleckPool*", "MeshInstance3D", true, false):
		if fleck.visible:
			visible += 1
	return visible


func _active_fleck_count(office: Node) -> int:
	var active_flecks: Variant = office.get("_active_egg_flecks")
	return active_flecks.size() if active_flecks is Array else -1
