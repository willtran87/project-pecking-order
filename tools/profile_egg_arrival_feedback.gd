extends SceneTree

## Read-only allocation profiler for the two remaining high-frequency egg
## feedback stages. Run with:
## Godot --headless --path . --script tools/profile_egg_arrival_feedback.gd

const STAMP_SAMPLE_COUNT := 40
const LANDING_SAMPLE_COUNT := 36


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
	var stamp_eggs: Array[MeshInstance3D] = []
	for sample_index in STAMP_SAMPLE_COUNT:
		var egg := _make_egg(collection_root, egg_mesh, "StampProfile_%02d" % sample_index)
		storytelling.call("_apply_egg_quality_visual", egg, &"sound", true)
		stamp_eggs.append(egg)

	var stamp_objects_before := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var stamp_nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var stamp_started := Time.get_ticks_usec()
	for egg in stamp_eggs:
		storytelling.call("_play_sorter_stamp_feedback", egg, &"sound")
	var stamp_total_usec := Time.get_ticks_usec() - stamp_started
	var stamp_objects_after := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var stamp_nodes_after := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))

	var landing_eggs: Array[MeshInstance3D] = []
	for sample_index in LANDING_SAMPLE_COUNT:
		var egg := _make_egg(collection_root, egg_mesh, "LandingProfile_%02d" % sample_index)
		storytelling.call("_apply_egg_quality_visual", egg, &"sound", true)
		landing_eggs.append(egg)
	var landing_objects_before := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var landing_nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var landing_started := Time.get_ticks_usec()
	for egg in landing_eggs:
		assert(storytelling.call("_settle_real_egg", egg, &"sound"))
	var landing_total_usec := Time.get_ticks_usec() - landing_started
	var landing_objects_after := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var landing_nodes_after := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))

	print("EGG_ARRIVAL_FEEDBACK_PROFILE %s" % JSON.stringify({
		"stamp": {
			"sample_count": STAMP_SAMPLE_COUNT,
			"total_usec": stamp_total_usec,
			"average_usec": float(stamp_total_usec) / float(STAMP_SAMPLE_COUNT),
			"objects_created": stamp_objects_after - stamp_objects_before,
			"nodes_created": stamp_nodes_after - stamp_nodes_before,
		},
		"landing": {
			"sample_count": LANDING_SAMPLE_COUNT,
			"total_usec": landing_total_usec,
			"average_usec": float(landing_total_usec) / float(LANDING_SAMPLE_COUNT),
			"objects_created": landing_objects_after - landing_objects_before,
			"nodes_created": landing_nodes_after - landing_nodes_before,
		},
	}))
	storytelling.free()
	await process_frame
	quit(0)


func _make_egg(
	parent: Node3D,
	mesh: Mesh,
	egg_name: String
) -> MeshInstance3D:
	var egg := MeshInstance3D.new()
	egg.name = egg_name
	egg.mesh = mesh
	egg.scale = Vector3(0.32, 0.43, 0.32)
	parent.add_child(egg)
	return egg
