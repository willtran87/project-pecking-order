extends SceneTree

const TrainingRoostVisualScript := preload("res://features/office/training_roost_visual.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var visual := TrainingRoostVisualScript.new() as TrainingRoostVisual
	root.add_child(visual)
	await process_frame

	_check(TrainingRoostVisualScript.declared_footprint() == Rect2(Vector2(12.0, 21.1), Vector2(6.4, 5.8)), "Training Roost should retain its exact east-campus parcel", failures)
	_check(TrainingRoostVisualScript.facility_focus_point().is_equal_approx(Vector3(15.2, 1.05, 24.0)), "Training Roost should publish a stable purchase focus", failures)
	_check(is_equal_approx(TrainingRoostVisualScript.maximum_visual_height(), 3.55), "Training Roost should honor the 3.55m opaque envelope", failures)
	_check(visual.visual_state() == &"locked" and visual.locked_marker_visible(), "fresh Training Roost should show only its locked parcel", failures)
	_check(visual.practice_terminal_count() == 3 and visual.visible_terminal_count() == 0, "all three connected terminals should be authored without appearing before purchase", failures)
	_check(visual.visible_credential_count() == 0, "empty snapshots must not invent credentials", failures)
	_check(visual.geometry_bounds_inside_footprint(), "every Training Roost state should stay inside its declared parcel", failures)
	_check(visual.find_children("*", "CollisionObject3D", true, false).is_empty(), "Training Roost should remain visual-only", failures)
	_check(visual.find_children("*", "NavigationRegion3D", true, false).is_empty(), "Training Roost should not create navigation regions", failures)
	_check(visual.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "Training Roost should not create navigation obstacles", failures)
	_check(visual.find_child("TrainingRoostNorthWall", true, false) == null, "camera-facing Training frontage should remain a cutaway", failures)
	var cutaway := visual.find_child("TrainingRoostNorthCutawayDado", true, false) as MeshInstance3D
	_check(cutaway != null and cutaway.mesh is BoxMesh and (cutaway.mesh as BoxMesh).size.y <= 0.47, "Training frontage should use a low camera-facing dado", failures)
	var identity := visual.find_child("TrainingRoostIdentityFixture", true, false) as Node3D
	_check(identity != null and StringName(identity.get_meta(&"sign_tier", &"")) == &"primary", "Training identity should be a primary environmental landmark", failures)
	_check(identity != null and StringName(identity.get_meta(&"copy_band", &"")) == &"destination", "Training identity should use destination hierarchy", failures)
	_check(identity != null and bool(identity.get_meta(&"uses_modeled_type", false)), "Training identity should use modeled host lettering", failures)
	var lesson_rail := visual.find_child("TrainingRoostLessonRail", true, false) as MeshInstance3D
	var identity_host := visual.find_child("TrainingRoostIdentityHost", true, false) as MeshInstance3D
	var identity_heading := visual.find_child("TrainingRoostIdentity", true, false) as Label3D
	var identity_body := visual.find_child("TrainingRoostIdentityBody", true, false) as Label3D
	_check(lesson_rail != null and identity_host != null and identity_host.get_parent() == lesson_rail, "Training identity fascia should be physically nested in the lesson rail", failures)
	_check(identity != null and identity_host != null and identity.get_parent() == identity_host, "Training identity should remain attached to its physical host", failures)
	_check(identity_host != null and StringName(identity_host.get_meta(&"architectural_mount", &"")) == &"lesson_rail", "Training identity should publish its lesson-rail mount", failures)
	_check(visual.find_children("TrainingRoostLessonRailClamp*", "MeshInstance3D", true, false).size() == 3, "Training lesson rail should visibly clamp the identity fascia", failures)
	_check(visual.find_children("TrainingRoostIdentityHanger*", "MeshInstance3D", true, false).is_empty(), "Training identity should no longer use floating hanger rods", failures)
	_check(identity_heading != null and identity_heading.text == "TRAINING ROOST" and identity_body != null and identity_body.text == "PRACTICE & ACCREDITATION", "Training identity should retain its exact heading and subtitle", failures)

	visual.apply_snapshot({
		"owned_facilities": {&"training_roost": 0},
		"facility_catalog": [{"id": &"training_roost", "unlocked": true, "level": 0}],
	})
	_check(visual.visual_state() == &"survey" and visual.survey_site_visible(), "earned unlock should reveal the credential survey, not installed benefits", failures)

	for level in 3:
		var purchased_level := level + 1
		visual.apply_snapshot({
			"owned_facilities": {&"training_roost": purchased_level},
			"facility_catalog": [{"id": &"training_roost", "unlocked": true, "level": purchased_level}],
			"facility_effects": {
				"training_roost_level": purchased_level,
				"career_sponsorship_cost_cents": [1000, 800, 600][level],
				"cross_training_work_basis_points": [9000, 9500, 10000][level],
				"career_coaching_xp_bonus": [2, 4, 6][level],
			},
			"workers": [],
		})
		_check(visual.visual_state() == StringName("level_%d" % purchased_level), "Training tier %d should expose its own visual state" % purchased_level, failures)
		_check(visual.visible_terminal_count() == purchased_level, "Training tier %d should reveal exactly %d cumulative terminals" % [purchased_level, purchased_level], failures)
		for retained_level in range(1, purchased_level + 1):
			_check(visual.level_visible(retained_level), "Training tier %d should retain tier %d" % [purchased_level, retained_level], failures)
		_check(visual.visible_credential_count() == 0, "Training tier %d must keep the gallery empty without earned specialties" % purchased_level, failures)
		_check(visual.geometry_bounds_inside_footprint(), "Training tier %d should remain parcel-bound" % purchased_level, failures)

	visual.apply_snapshot({
		"owned_facilities": {&"training_roost": 3},
		"facility_effects": {
			"training_roost_level": 3,
			"career_sponsorship_cost_cents": 600,
			"cross_training_work_basis_points": 10000,
			"career_coaching_xp_bonus": 6,
		},
		"workers": [
			{"id": 0, "display_name": "Mabel", "employed": true, "secondary_specialty": &"appeals", "secondary_specialty_name": "APPEALS & EXCEPTIONS"},
			{"id": 1, "display_name": "Cluckson", "employed": true, "secondary_specialty": &"predator_loss", "secondary_specialty_name": "PREDATOR LOSS"},
			{"id": 2, "display_name": "Henrietta", "employed": true, "cross_training_target": &"appeals", "cross_training_target_name": "APPEALS & EXCEPTIONS", "cross_training_active": true},
		],
	})
	_check(visual.visible_credential_count() == 2, "credential gallery should materialize exactly two authoritative secondary specialties", failures)
	_check(visual.credential_worker_ids() == [0, 1], "credential gallery should retain the authoritative worker IDs", failures)
	_check(visual.active_trainee_count() == 1, "practice meter should count the single authoritative trainee", failures)
	_check(visual.has_authoritative_metrics(), "Training live console should recognize authoritative facility effects", failures)
	_check("$6.00" in visual.training_status_text() and "WORK 100%" in visual.training_status_text() and "XP +6" in visual.training_status_text(), "Training live console should show authoritative sponsorship, work, and XP terms", failures)
	_check(visual.geometry_bounds_inside_footprint(), "dynamic credentials should remain inside the Training parcel", failures)
	_check(visual.find_children("*DecorativeEgg*", "", true, false).is_empty(), "Training Roost must not invent decorative eggs", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("TRAINING_ROOST_VISUAL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("TRAINING_ROOST_VISUAL_TEST_PASSED states=locked-survey-l1-l2-l3 terminals=1-2-3 credentials=authoritative bounds=inside collisions=0")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
