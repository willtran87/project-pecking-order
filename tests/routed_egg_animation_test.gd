extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var storytelling := OfficeStorytelling.new()
	root.add_child(storytelling)
	for _frame in 3:
		await process_frame

	var collection_root := storytelling.get("egg_collection_root") as Node3D
	var egg_mesh := storytelling.get("_clutch_egg_mesh") as Mesh
	assert(collection_root != null and egg_mesh != null)
	var egg := MeshInstance3D.new()
	egg.name = "RoutedEggTimingFixture"
	egg.mesh = egg_mesh
	egg.scale = Vector3(0.32, 0.43, 0.32)
	collection_root.add_child(egg)
	egg.global_position = storytelling.to_global(Vector3(-6.0, 1.2, -2.8))

	var events := {"graded": 0, "presented": 0, "value": 0}
	storytelling.egg_graded.connect(func(
		_worker_id: int,
		_quality: StringName,
		value_cents: int,
		_streak_bonus_cents: int,
		_position: Vector3
	) -> void:
		events["graded"] = int(events["graded"]) + 1
		events["value"] = value_cents
	)
	storytelling.egg_reached_presentation_detailed.connect(func(
		_worker_id: int,
		_quality: StringName,
		value_cents: int,
		_streak_bonus_cents: int
	) -> void:
		events["presented"] = int(events["presented"]) + 1
		events["value"] = value_cents
	)

	assert(storytelling.animate_egg_collection(egg, 1, &"sound", true, 455, 25))
	assert((storytelling.get("_routed_egg_animations") as Array).size() == 1)
	assert((storytelling.get("_animated_eggs") as Array).size() == 1)
	var treatment_before := egg.get_node("EggQualityTreatment") as Node3D
	var treatment_id := treatment_before.get_instance_id()

	storytelling.call("_process_routed_egg_animations", 1.11)
	assert(int(events["graded"]) == 0)
	assert(int(events["presented"]) == 0)
	storytelling.call("_process_routed_egg_animations", 0.02)
	assert(int(events["graded"]) == 1)
	assert(int(events["presented"]) == 0)
	assert(int(events["value"]) == 455)

	# One long frame must consume all remaining visual phases rather than delaying
	# the presentation/economy callback by a matching amount.
	storytelling.call("_process_routed_egg_animations", 2.0)
	assert(int(events["graded"]) == 1)
	assert(int(events["presented"]) == 1)
	assert((storytelling.get("_routed_egg_animations") as Array).is_empty())
	assert((storytelling.get("_animated_eggs") as Array).is_empty())
	assert(is_instance_valid(egg))
	var treatment_after := egg.get_node("EggQualityTreatment") as Node3D
	assert(treatment_after.get_instance_id() == treatment_id)
	var stamp_ring := treatment_after.get_node("EggSorterStampRing") as MeshInstance3D
	assert(stamp_ring != null and not stamp_ring.visible)

	# Unknown worker IDs retain the direct route and present without inventing a
	# grading pass, matching the compatibility fallback.
	var fallback_egg := MeshInstance3D.new()
	fallback_egg.mesh = egg_mesh
	fallback_egg.scale = Vector3(0.32, 0.43, 0.32)
	collection_root.add_child(fallback_egg)
	assert(storytelling.animate_egg_collection(fallback_egg, 999, &"golden", false, 700, 0))
	storytelling.call("_process_routed_egg_animations", 0.23)
	assert(int(events["graded"]) == 1)
	assert(int(events["presented"]) == 2)
	assert(is_instance_valid(fallback_egg))

	print("ROUTED_EGG_ANIMATION_TEST_PASSED")
	storytelling.free()
	await process_frame
	quit(0)
