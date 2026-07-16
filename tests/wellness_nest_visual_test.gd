extends SceneTree

const WellnessNestVisualScript := preload("res://features/office/wellness_nest_visual.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var visual := WellnessNestVisualScript.new() as WellnessNestVisual
	root.add_child(visual)
	await process_frame

	_check(WellnessNestVisualScript.declared_footprint() == Rect2(Vector2(12.0, 15.1), Vector2(6.4, 5.8)), "Wellness Nest should retain its exact east-campus parcel", failures)
	_check(WellnessNestVisualScript.facility_focus_point().is_equal_approx(Vector3(15.2, 1.05, 18.0)), "Wellness Nest should publish a stable purchase focus", failures)
	_check(is_equal_approx(WellnessNestVisualScript.maximum_visual_height(), 3.55), "Wellness Nest should honor the 3.55m opaque envelope", failures)
	_check(visual.visual_state() == &"locked" and visual.locked_marker_visible(), "fresh Wellness Nest should show only its locked parcel", failures)
	_check(visual.nest_count() == 6 and visual.visible_nest_count() == 0, "all six connected nests should be authored without appearing before purchase", failures)
	_check(visual.geometry_bounds_inside_footprint(), "every Wellness Nest state should stay inside its declared parcel", failures)
	_check(visual.find_children("*", "CollisionObject3D", true, false).is_empty(), "Wellness Nest should remain visual-only", failures)
	_check(visual.find_children("*", "NavigationRegion3D", true, false).is_empty(), "Wellness Nest should not create navigation regions", failures)
	_check(visual.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "Wellness Nest should not create navigation obstacles", failures)
	_check(visual.find_child("WellnessNestNorthWall", true, false) == null, "camera-facing Wellness frontage should remain a cutaway", failures)
	var cutaway := visual.find_child("WellnessNestNorthCutawayDado", true, false) as MeshInstance3D
	_check(cutaway != null and cutaway.mesh is BoxMesh and (cutaway.mesh as BoxMesh).size.y <= 0.47, "Wellness frontage should use a low camera-facing dado", failures)
	var identity := visual.find_child("WellnessNestIdentityFixture", true, false) as Node3D
	_check(identity != null and StringName(identity.get_meta(&"sign_tier", &"")) == &"primary", "Wellness identity should be a primary environmental landmark", failures)
	_check(identity != null and StringName(identity.get_meta(&"copy_band", &"")) == &"destination", "Wellness identity should use destination hierarchy", failures)
	_check(identity != null and bool(identity.get_meta(&"uses_modeled_type", false)), "Wellness identity should use modeled host lettering", failures)
	var identity_host := visual.find_child("WellnessNestIdentityHost", true, false) as MeshInstance3D
	var identity_heading := visual.find_child("WellnessNestIdentity", true, false) as Label3D
	var identity_body := visual.find_child("WellnessNestIdentityBody", true, false) as Label3D
	_check(identity_host != null and identity != null and identity.get_parent() == identity_host, "Wellness identity should remain attached to its physical host", failures)
	_check(identity_host != null and StringName(identity_host.get_meta(&"architectural_mount", &"")) == &"recovery_lintel", "Wellness identity host should be authored as recovery-room lintel joinery", failures)
	_check(visual.find_children("WellnessNestIdentityLintelJamb*", "MeshInstance3D", true, false).size() == 2, "Wellness lintel should land on two visible frontage jambs", failures)
	_check(visual.find_child("WellnessNestIdentityLintelTopCap", true, false) != null and visual.find_child("WellnessNestIdentityLintelBottomCap", true, false) != null, "Wellness lintel should retain visible top and bottom joinery", failures)
	_check(visual.find_children("WellnessNestIdentityHanger*", "MeshInstance3D", true, false).is_empty(), "Wellness identity should no longer use floating hanger rods", failures)
	_check(identity_heading != null and identity_heading.text == "WELLNESS NEST" and identity_body != null and identity_body.text == "RECOVERY & REST", "Wellness identity should retain its exact heading and subtitle", failures)

	visual.apply_snapshot({
		"owned_facilities": {&"wellness_nest_room": 0},
		"facility_catalog": [{"id": &"wellness_nest_room", "unlocked": true, "level": 0}],
	})
	_check(visual.visual_state() == &"survey" and visual.survey_site_visible(), "earned unlock should reveal the recovery survey, not installed benefits", failures)

	for level in 3:
		var purchased_level := level + 1
		visual.apply_snapshot({
			"owned_facilities": {&"wellness_nest_room": purchased_level},
			"facility_catalog": [{"id": &"wellness_nest_room", "unlocked": true, "level": purchased_level}],
			"facility_effects": {
				"wellness_nest_level": purchased_level,
				"wellness_strain_gain_basis_points": [9200, 8400, 7600][level],
				"wellness_break_recovery_basis_points": [11500, 13000, 15000][level],
			},
			"flock_care": {"welfare": 76, "rested_flock_gate": 72},
		})
		_check(visual.visual_state() == StringName("level_%d" % purchased_level), "Wellness tier %d should expose its own visual state" % purchased_level, failures)
		_check(visual.visible_nest_count() == purchased_level * 2, "Wellness tier %d should reveal exactly %d cumulative nests" % [purchased_level, purchased_level * 2], failures)
		for retained_level in range(1, purchased_level + 1):
			_check(visual.level_visible(retained_level), "Wellness tier %d should retain tier %d" % [purchased_level, retained_level], failures)
		_check(visual.geometry_bounds_inside_footprint(), "Wellness tier %d should remain parcel-bound" % purchased_level, failures)

	_check(visual.has_authoritative_metrics(), "Wellness live console should recognize authoritative facility effects", failures)
	_check("STRAIN 76%" in visual.care_status_text() and "REST 150%" in visual.care_status_text(), "Wellness live console should show authoritative strain and rest values", failures)
	_check(visual.find_children("*DecorativeEgg*", "", true, false).is_empty(), "Wellness Nest must not invent decorative eggs", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("WELLNESS_NEST_VISUAL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("WELLNESS_NEST_VISUAL_TEST_PASSED states=locked-survey-l1-l2-l3 nests=2-4-6 bounds=inside collisions=0 signage=modeled")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
