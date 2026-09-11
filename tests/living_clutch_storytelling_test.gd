extends SceneTree

const OfficeStorytellingScript := preload("res://features/office/office_storytelling.gd")
const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var staging := OfficeStorytellingScript.new() as OfficeStorytelling
	root.add_child(staging)
	await process_frame

	staging.apply_snapshot(_live_snapshot(1, 0, 0, 0))
	_check(staging.visible_clutch_count() == 0, "the physical clutch should begin empty", failures)
	_check(_clutch_cup_capacity(staging) == 36, "the two bounded cup batches should preserve all 36 physical destinations", failures)
	_check(_visible_clutch_cups(staging) == 36, "an empty living clutch should expose all 36 destination cups", failures)

	var egg := MeshInstance3D.new()
	egg.name = "AuthorizedTestEgg"
	var egg_mesh := SphereMesh.new()
	egg_mesh.radius = 0.5
	egg_mesh.height = 1.0
	egg.mesh = egg_mesh
	egg.scale = Vector3(0.32, 0.43, 0.32)
	staging.add_child(egg)
	egg.global_position = Vector3(-6.0, 0.8, -3.0)

	var arrival := {"seen": false, "value": 0, "quality": &""}
	staging.egg_reached_presentation_detailed.connect(func(
		_worker_id: int,
		quality: StringName,
		value_cents: int,
		_streak_bonus_cents: int
	) -> void:
		arrival["seen"] = true
		arrival["value"] = value_cents
		arrival["quality"] = quality
	)
	_check(
		staging.animate_egg_collection(egg, 0, &"golden", true, 1680, 70),
		"an authorized egg should enter the physical collection route",
		failures
	)
	# The authoritative snapshot includes the laid egg, but the in-flight guard
	# must reserve its slot instead of materializing a duplicate.
	staging.apply_snapshot(_live_snapshot(1, 1, 0, 1))
	_check(staging.visible_clutch_count() == 0, "an in-flight egg should not also appear in the basket", failures)

	await _wait_for_flag(arrival, "seen", 300)
	_check(bool(arrival["seen"]), "the routed egg should reach the presentation gate", failures)
	_check(int(arrival["value"]) == 1680 and StringName(arrival["quality"]) == &"golden", "arrival should preserve the authoritative quality and value", failures)
	_check(staging.visible_clutch_count() == 1, "the arrived real egg should remain in the living clutch", failures)
	var cups_after_arrival := _visible_clutch_cups(staging)
	_check(cups_after_arrival == 35, "the real egg should replace exactly one visible empty cup (found %d)" % cups_after_arrival, failures)
	_check(staging.visible_clutch_quality_count(&"golden") == 1, "the retained egg should preserve its golden quality", failures)
	_check(is_instance_valid(egg) and egg.name.begins_with("SettledClutchEgg_"), "the exact routed node should be retained rather than replaced", failures)

	# REVIEW uses the last authoritative pecking order because the simulation has
	# already advanced its calendar and reset today's counters.
	staging.apply_snapshot({
		"day": 3,
		"shift_phase": 3,
		"eggs_today": 0,
		"cracked_today": 0,
		"golden_today": 0,
		"last_pecking_order_day": 2,
		"last_pecking_order": [
			{"eggs": 3, "sound": 2, "cracked": 1, "golden": 0},
			{"eggs": 1, "sound": 0, "cracked": 0, "golden": 1},
		],
		"workers": [],
	})
	_check(staging.visible_clutch_count() == 4, "review reload should reconstruct the completed clutch", failures)
	var cups_at_review := _visible_clutch_cups(staging)
	_check(cups_at_review == 32, "review reconstruction should hide exactly the four occupied cup instances (found %d)" % cups_at_review, failures)
	_check(staging.visible_clutch_quality_count(&"cracked") == 1, "review reconstruction should preserve cracked count", failures)
	_check(staging.visible_clutch_quality_count(&"golden") == 1, "review reconstruction should preserve golden count", failures)

	# An egg launched during REVIEW belongs to that displayed clutch day. If the
	# next briefing begins before it arrives, its gameplay callback still fires,
	# but the stale visual must not repopulate the newly cleared clutch.
	var stale_egg := MeshInstance3D.new()
	stale_egg.name = "StaleCrossShiftEgg"
	var stale_egg_mesh := SphereMesh.new()
	stale_egg_mesh.radius = 0.5
	stale_egg_mesh.height = 1.0
	stale_egg.mesh = stale_egg_mesh
	stale_egg.scale = Vector3(0.32, 0.43, 0.32)
	staging.add_child(stale_egg)
	stale_egg.global_position = Vector3(-6.0, 0.8, -3.0)

	var stale_arrival := {"seen": false, "value": 0}
	staging.egg_reached_presentation_detailed.connect(func(
		_worker_id: int,
		_quality: StringName,
		value_cents: int,
		_streak_bonus_cents: int
	) -> void:
		if value_cents == 512:
			stale_arrival["seen"] = true
			stale_arrival["value"] = value_cents
	)
	_check(
		staging.animate_egg_collection(stale_egg, 0, &"sound", true, 512, 0),
		"a review-day egg should begin its authorized collection route",
		failures
	)
	staging.apply_snapshot(_live_snapshot(3, 0, 0, 0))
	_check(staging.visible_clutch_count() == 0, "a new shift should clear the previous physical clutch", failures)
	_check(_visible_clutch_cups(staging) == 36, "clearing a shift should restore every empty destination cup", failures)
	await _wait_for_flag(stale_arrival, "seen", 300)
	_check(bool(stale_arrival["seen"]) and int(stale_arrival["value"]) == 512, "a stale cross-shift arrival should preserve its gameplay callback", failures)
	await process_frame
	_check(staging.visible_clutch_count() == 0, "a stale cross-shift arrival should not repopulate the cleared clutch", failures)
	_check(not is_instance_valid(stale_egg), "a stale cross-shift egg visual should be released after its callback", failures)

	staging.apply_snapshot(_live_snapshot(3, 40, 2, 3))
	_check(staging.visible_clutch_count() == 36, "the retained mesh budget should cap at 36 eggs", failures)
	var cups_at_capacity := _visible_clutch_cups(staging)
	_check(cups_at_capacity == 0, "a full retained clutch should hide every occupied destination cup (found %d)" % cups_at_capacity, failures)
	_check(staging.clutch_surplus_count() == 4, "eggs beyond the mesh budget should become surplus", failures)
	var surplus := staging.find_child("ClutchSurplusMarker", true, false) as Node3D
	var surplus_label := staging.find_child("ClutchSurplusLabel", true, false) as Label3D
	_check(surplus != null and surplus.visible, "surplus should reveal its mounted physical marker", failures)
	_check(surplus_label != null and "+04" in surplus_label.text, "surplus marker should show the exact overflow count", failures)
	EnvironmentalSignageScript.set_camera_detail(staging, false)
	_check(surplus_label != null and surplus_label.visible and "+04" in surplus_label.text, "surplus count should remain legible in the normal office overview", failures)

	staging.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("LIVING_CLUTCH_STORYTELLING_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("LIVING_CLUTCH_STORYTELLING_TEST_PASSED transit=reserved arrival=retained stale_day=discarded callbacks=preserved surplus=overview-visible cap=36")
	quit(0)


func _live_snapshot(day: int, eggs: int, cracked: int, golden: int) -> Dictionary:
	return {
		"day": day,
		"shift_phase": 0,
		"time_label": "8:00 AM",
		"eggs_today": eggs,
		"cracked_today": cracked,
		"golden_today": golden,
		"eggs_total": eggs,
		"quota_target": 24,
		"claims_processed": eggs,
		"workers": [],
	}


func _wait_for_flag(state: Dictionary, key: String, frame_limit: int) -> void:
	for _frame in frame_limit:
		if bool(state.get(key, false)):
			return
		await process_frame


func _clutch_cup_capacity(staging: Node) -> int:
	var total := 0
	for candidate in staging.find_children("EmptyClutchCupBatch*", "MultiMeshInstance3D", true, false):
		var batch := candidate as MultiMeshInstance3D
		if batch != null and batch.multimesh != null:
			total += batch.multimesh.instance_count
	return total


func _visible_clutch_cups(staging: Node) -> int:
	var visible := 0
	for candidate in staging.find_children("EmptyClutchCupBatch*", "MultiMeshInstance3D", true, false):
		var batch := candidate as MultiMeshInstance3D
		if batch == null or batch.multimesh == null:
			continue
		visible += (
			batch.multimesh.instance_count
			if batch.multimesh.visible_instance_count < 0
			else batch.multimesh.visible_instance_count
		)
	return visible


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
