extends SceneTree

## Read-only allocation profiler for the physical sorter receipt.
## Godot --headless --path . --script tools/profile_grading_receipts.gd

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
	var objects_before := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var children_before := collection_root.get_child_count()
	var started := Time.get_ticks_usec()
	for sample_index in SAMPLE_COUNT:
		storytelling.call("_spawn_grading_receipt", 0, {
			"quality": &"golden" if sample_index % 10 == 0 else &"sound",
			"value_cents": 400 + sample_index,
			"streak_bonus_cents": 50 if sample_index % 5 == 0 else 0,
			"worker_id": sample_index % 4,
		})
		var slots := storytelling.get("_grading_receipt_slots") as Array
		var receipt := slots[0] as Node3D
		storytelling.call("_finish_grading_receipt", receipt, 0)
	var total_usec := Time.get_ticks_usec() - started
	var objects_after := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes_after := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	print("GRADING_RECEIPT_PROFILE %s" % JSON.stringify({
		"sample_count": SAMPLE_COUNT,
		"total_usec": total_usec,
		"average_usec": float(total_usec) / float(SAMPLE_COUNT),
		"objects_created": objects_after - objects_before,
		"nodes_created": nodes_after - nodes_before,
		"children_delta": collection_root.get_child_count() - children_before,
	}))
	storytelling.free()
	await process_frame
	quit(0)
