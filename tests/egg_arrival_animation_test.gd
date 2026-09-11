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

	var stamp_egg := _make_egg(collection_root, egg_mesh, "StampAnimationFixture")
	storytelling.call("_apply_egg_quality_visual", stamp_egg, &"golden", true)
	var stamp_ring := stamp_egg.find_child(
		"EggSorterStampRing", true, false
	) as MeshInstance3D
	assert(stamp_ring != null and not stamp_ring.visible)
	storytelling.call("_play_sorter_stamp_feedback", stamp_egg, &"golden")
	var stamp_animations := storytelling.get("_sorter_stamp_animations") as Array
	assert(stamp_ring.visible and stamp_animations.size() == 1)
	var stamp_animation_id := int(stamp_animations[0].get_instance_id())
	storytelling.call("_process_sorter_stamp_animations", 0.14)
	var stamp_material := stamp_ring.material_override as StandardMaterial3D
	assert(stamp_ring.visible)
	assert(stamp_ring.scale.x > 0.50 and stamp_ring.scale.x < 1.40)
	assert(stamp_material.albedo_color.a > 0.0 and stamp_material.albedo_color.a < 0.70)
	# Re-triggering the same ring resets the existing state instead of allocating
	# a second animation graph.
	storytelling.call("_play_sorter_stamp_feedback", stamp_egg, &"golden")
	stamp_animations = storytelling.get("_sorter_stamp_animations") as Array
	assert(stamp_animations.size() == 1)
	assert(stamp_animations[0].get_instance_id() == stamp_animation_id)
	storytelling.call("_process_sorter_stamp_animations", 0.28)
	assert(not stamp_ring.visible)
	assert((storytelling.get("_sorter_stamp_animations") as Array).is_empty())

	var landing_egg := _make_egg(collection_root, egg_mesh, "LandingAnimationFixture")
	storytelling.call("_apply_egg_quality_visual", landing_egg, &"sound", true)
	assert(storytelling.call("_settle_real_egg", landing_egg, &"sound"))
	var slot_index := int(landing_egg.get_meta("clutch_slot", -1))
	var slots := storytelling.get("_clutch_slots") as Array
	var target_position: Vector3 = (slots[slot_index] as Node3D).position
	var target_root := landing_egg.get_parent() as Node3D
	assert((storytelling.get("_settled_egg_animations") as Array).size() == 1)
	assert((storytelling.get("_clutch_recoil_animations") as Array).size() == 1)
	storytelling.call("_process_settled_egg_animations", 0.055)
	assert(landing_egg.scale.y < 0.36)
	assert(not landing_egg.position.is_equal_approx(target_position))
	storytelling.call("_process_clutch_recoil_animations", 0.03)
	assert(absf(target_root.rotation.z) > 0.0)
	assert(not target_root.scale.is_equal_approx(Vector3.ONE))

	# A delayed frame consumes impact, bounce, and rest without leaving the egg or
	# its basket root in a partially animated state.
	storytelling.call("_process_settled_egg_animations", 0.30)
	storytelling.call("_process_clutch_recoil_animations", 0.30)
	assert((storytelling.get("_settled_egg_animations") as Array).is_empty())
	assert(landing_egg.position.is_equal_approx(target_position))
	assert(landing_egg.scale.is_equal_approx(Vector3(0.26, 0.36, 0.26)))
	assert(target_root.rotation.is_equal_approx(Vector3.ZERO))
	assert(target_root.scale.is_equal_approx(Vector3.ONE))

	var second_egg := _make_egg(collection_root, egg_mesh, "LandingReuseFixture")
	storytelling.call("_apply_egg_quality_visual", second_egg, &"cracked", true)
	assert(storytelling.call("_settle_real_egg", second_egg, &"cracked"))
	assert(int(second_egg.get_meta("clutch_slot", -1)) == slot_index + 1)
	# Both early slots share the presentation clutch, so recoil retains one
	# bounded reusable state while the two eggs own independent landings.
	assert((storytelling.get("_clutch_recoil_animations") as Array).size() == 1)
	assert((storytelling.get("_settled_egg_animations") as Array).size() == 1)

	print("EGG_ARRIVAL_ANIMATION_TEST_PASSED")
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
