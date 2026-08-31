extends SceneTree

const SAMPLE_COUNT := 40


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var storytelling := OfficeStorytelling.new()
	root.add_child(storytelling)
	for _frame in 3:
		await process_frame

	var collection_root := storytelling.get("egg_collection_root") as Node3D
	var receipt := storytelling.get("_grading_receipt_pool") as Node3D
	var label := storytelling.get("_grading_receipt_label") as Label3D
	var stripe := storytelling.get("_grading_receipt_quality_stripe") as MeshInstance3D
	assert(collection_root != null and receipt != null and label != null and stripe != null)
	assert(not receipt.visible)
	var child_count_before := collection_root.get_child_count()
	var receipt_id := receipt.get_instance_id()
	var part_ids: Array[int] = []
	for part in receipt.get_children():
		part_ids.append(part.get_instance_id())

	for sample_index in SAMPLE_COUNT:
		storytelling.call("_spawn_grading_receipt", 0, {
			"quality": &"golden" if sample_index % 10 == 0 else &"sound",
			"value_cents": 400 + sample_index,
			"streak_bonus_cents": 50 if sample_index % 5 == 0 else 0,
			"worker_id": sample_index % 4,
		})
		storytelling.call("_finish_grading_receipt", receipt, 0)
	assert(collection_root.get_child_count() == child_count_before)
	assert(receipt.get_instance_id() == receipt_id)
	for part_index in receipt.get_child_count():
		assert(receipt.get_child(part_index).get_instance_id() == part_ids[part_index])

	storytelling.call("_spawn_grading_receipt", 0, {
		"quality": &"cracked",
		"value_cents": 875,
		"streak_bonus_cents": 75,
		"worker_id": 0,
	})
	assert(receipt.visible and receipt.name == "GradingReceipt_0")
	assert("CRACKED" in label.text)
	assert("$8.00" in label.text)
	assert("+$0.75 clean-clutch" in label.text)
	assert(bool(storytelling.get("_grading_receipt_active")))
	var stripe_material := stripe.material_override as StandardMaterial3D
	assert(stripe_material != null)
	assert(stripe_material.albedo_color.is_equal_approx(
		SemanticColorPalette.quality_color(&"cracked", &"standard"),
	))
	storytelling.call("_process_grading_receipt", 0.09)
	assert(receipt.scale.y > 0.10 and receipt.scale.y < 1.0)

	storytelling.call("_enqueue_grading_receipt", &"sound", 525, 0, 1)
	assert((storytelling.get("_grading_receipt_queue") as Array).size() == 1)
	storytelling.call("_process_grading_receipt", 2.0)
	assert(receipt.visible)
	assert("SOUND" in label.text and "$5.25" in label.text)
	assert((storytelling.get("_grading_receipt_queue") as Array).is_empty())
	storytelling.call("_process_grading_receipt", 2.0)
	assert(not receipt.visible)
	assert(receipt.name == "GradingReceiptPool")
	assert(not bool(storytelling.get("_grading_receipt_active")))
	assert((storytelling.get("_grading_receipt_slots") as Array)[0] == null)

	print("GRADING_RECEIPT_POOL_TEST_PASSED")
	storytelling.free()
	await process_frame
	quit(0)
