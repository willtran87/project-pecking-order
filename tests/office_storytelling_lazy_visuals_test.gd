extends SceneTree

const OfficeStorytellingScript := preload("res://features/office/office_storytelling.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var staging := OfficeStorytellingScript.new() as OfficeStorytelling
	staging.set_defer_optional_visuals(true)
	staging.set_lazy_hidden_optional_visuals(true)
	root.add_child(staging)

	var day_one := {
		"day": 1,
		"workers": [],
		"owned_facilities": {},
		"facility_catalog": [],
		"claim_queue_counts": {},
		"eggs_today": 0,
		"quota_target": 12,
		"eggs_total": 0,
		"claims_processed": 0,
	}
	staging.apply_snapshot(day_one, false)
	staging.apply_campus_presentation(day_one)
	await process_frame
	await process_frame
	var initial := staging.optional_visual_build_snapshot()
	_check(bool(initial.get("ready", false)), "lazy boot should finish its initial residency gate", failures)
	_check(bool(initial.get("lazy_hidden", false)), "lazy boot should disclose its residency policy", failures)
	_check(int(initial.get("built_count", -1)) == 0, "undiscovered campus art should not enter the scene tree", failures)
	_check(staging.find_child("PackingAnnexVisual", true, false) == null, "hidden packing art should remain uninstantiated", failures)

	var teased := day_one.duplicate(true)
	teased["day"] = 2
	teased["facility_catalog"] = [
		{"id": &"farmer_brand_packing_annex", "level": 0, "owned": false, "unlock_day": 3},
	]
	staging.apply_snapshot(teased, false)
	var teased_presentation := staging.apply_campus_presentation(teased, {
		"show_next_teaser": true,
		"teaser_window_days": 1,
	})
	_check(String(teased_presentation.get("teaser_id", "")) == "farmer_brand_packing_annex", "tomorrow's capital hint should remain in the read model", failures)
	_check((teased_presentation.get("visible_ids", []) as Array).is_empty(), "a Web teaser should not expand live world bounds", failures)
	_check(staging.find_child("PackingAnnexVisual", true, false) == null, "a teaser should not instantiate an entire facility", failures)
	teased["day"] = 3
	(teased["facility_catalog"] as Array)[0]["unlocked"] = true
	staging.apply_snapshot(teased, false)
	var offered_presentation := staging.apply_campus_presentation(teased)
	var offered_entry := (offered_presentation.get("entries_by_id", {}) as Dictionary).get(
		&"farmer_brand_packing_annex",
		{},
	) as Dictionary
	_check(String(offered_entry.get("state", "")) == "offered", "an available project should remain disclosed to planning UI", failures)
	_check((offered_presentation.get("visible_ids", []) as Array).is_empty(), "an unchosen project should not expand the Web world", failures)
	_check(staging.find_child("PackingAnnexVisual", true, false) == null, "an offered project should not allocate full world art", failures)

	var owned := day_one.duplicate(true)
	owned["day"] = 3
	owned["owned_facilities"] = {&"farmer_brand_packing_annex": 1}
	owned["facility_catalog"] = [
		{"id": &"farmer_brand_packing_annex", "level": 1, "owned": true, "unlocked": true},
	]
	staging.apply_snapshot(owned, false)
	staging.apply_campus_presentation(owned)
	var packing := staging.find_child("PackingAnnexVisual", true, false) as Node3D
	_check(packing != null and packing.visible, "an owned facility should instantiate and reveal in the same transaction", failures)
	_check(int(staging.optional_visual_build_snapshot().get("built_count", -1)) == 1, "only the required optional root should be resident", failures)
	staging.apply_campus_presentation(owned)
	_check(staging.find_children("PackingAnnexVisual", "Node3D", true, false).size() == 1, "repeated snapshots must not duplicate lazy art", failures)
	_check(staging.find_child("RecordsAnnexVisual", true, false) == null, "unrelated hidden facilities should stay absent", failures)

	staging.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("OFFICE_STORYTELLING_LAZY_VISUALS_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OFFICE_STORYTELLING_LAZY_VISUALS_TEST_PASSED hidden=absent owned=resident duplicates=none")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
