extends SceneTree

## Read-only allocation profiler for launching eggs through the collection rail.
## Godot --headless --path . --script tools/profile_routed_egg_animation.gd

const SAMPLE_COUNT := 40


func _init() -> void:
	_profile.call_deferred()


func _profile() -> void:
	root.size = Vector2i(1280, 720)
	var storytelling := OfficeStorytelling.new()
	root.add_child(storytelling)
	for _frame in 3:
		await process_frame
	var collection_root := storytelling.get("egg_collection_root") as Node3D
	var egg_mesh := storytelling.get("_clutch_egg_mesh") as Mesh
	var eggs: Array[MeshInstance3D] = []
	for sample_index in SAMPLE_COUNT:
		var egg := MeshInstance3D.new()
		egg.name = "ProfileRoutedEgg_%02d" % sample_index
		egg.mesh = egg_mesh
		egg.scale = Vector3(0.32, 0.43, 0.32)
		egg.position = Vector3(-3.0 + float(sample_index % 6), 1.2, -2.0)
		collection_root.add_child(egg)
		eggs.append(egg)
	var objects_before := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var started := Time.get_ticks_usec()
	for sample_index in SAMPLE_COUNT:
		storytelling.animate_egg_collection(
			eggs[sample_index],
			1 + sample_index % 6,
			&"golden" if sample_index % 10 == 0 else &"sound",
			false,
			400 + sample_index,
			0,
		)
	var total_usec := Time.get_ticks_usec() - started
	var objects_after := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes_after := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	print("ROUTED_EGG_ANIMATION_PROFILE %s" % JSON.stringify({
		"sample_count": SAMPLE_COUNT,
		"total_usec": total_usec,
		"average_usec": float(total_usec) / float(SAMPLE_COUNT),
		"objects_created": objects_after - objects_before,
		"nodes_created": nodes_after - nodes_before,
		"animated_count": (storytelling.get("_animated_eggs") as Array).size(),
		"active_trails": (storytelling.get("_egg_handoff_trails") as Dictionary).size(),
	}))
	storytelling.free()
	await process_frame
	quit(0)
