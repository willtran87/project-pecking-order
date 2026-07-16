extends SceneTree

const RoosterOperationsOfficeVisualScript := preload("res://features/office/rooster_operations_office_visual.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var visual := RoosterOperationsOfficeVisualScript.new() as RoosterOperationsOfficeVisual
	root.add_child(visual)
	await process_frame

	_check(RoosterOperationsOfficeVisualScript.declared_footprint() == Rect2(Vector2(12.0, 27.1), Vector2(6.4, 5.8)), "Rooster Operations should retain its exact parcel", failures)
	_check(RoosterOperationsOfficeVisualScript.facility_focus_point().is_equal_approx(Vector3(15.2, 1.05, 30.0)), "Rooster Operations should publish its stable focus", failures)
	_check(is_equal_approx(RoosterOperationsOfficeVisualScript.maximum_visual_height(), 3.55), "Rooster Operations should honor the 3.55m envelope", failures)
	_check(visual.visual_state() == &"locked" and visual.locked_marker_visible(), "fresh Rooster Operations should show only the locked parcel", failures)
	_check(visual.supervisor_station_count() == 3 and visual.visible_supervisor_station_count() == 0, "three cumulative stations should be authored but hidden before purchase", failures)
	_check(visual.geometry_bounds_inside_footprint(), "locked Rooster Operations geometry should stay parcel-bound", failures)
	_check(visual.find_children("*", "CollisionObject3D", true, false).is_empty(), "Rooster Operations should remain collision-free", failures)
	_check(visual.find_children("*", "NavigationRegion3D", true, false).is_empty(), "Rooster Operations should not create navigation regions", failures)
	_check(visual.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "Rooster Operations should not create navigation obstacles", failures)
	_check(visual.find_child("RoosterOperationsNorthWall", true, false) == null, "camera-facing frontage should remain a cutaway", failures)
	var cutaway := visual.find_child("RoosterOperationsNorthCutawayDado", true, false) as MeshInstance3D
	_check(cutaway != null and cutaway.mesh is BoxMesh and (cutaway.mesh as BoxMesh).size.y <= 0.47, "Rooster Operations should use a low north dado", failures)
	var identity := visual.find_child("RoosterOperationsIdentityFixture", true, false) as Node3D
	_check(identity != null and StringName(identity.get_meta(&"sign_tier", &"")) == &"primary", "Rooster Operations identity should be a primary mounted fixture", failures)
	_check(identity != null and StringName(identity.get_meta(&"copy_band", &"")) == &"destination", "Rooster Operations identity should use destination hierarchy", failures)
	_check(identity != null and bool(identity.get_meta(&"uses_modeled_type", false)), "Rooster Operations identity should use modeled host lettering", failures)
	var front_lintel := visual.find_child("RoosterOperationsFrontLintel", true, false) as MeshInstance3D
	var identity_host := visual.find_child("RoosterOperationsIdentityHost", true, false) as MeshInstance3D
	var identity_heading := visual.find_child("RoosterOperationsIdentity", true, false) as Label3D
	var identity_body := visual.find_child("RoosterOperationsIdentityBody", true, false) as Label3D
	_check(front_lintel != null and identity_host != null and identity_host.get_parent() == front_lintel, "Rooster Operations identity fascia should be borne by the front lintel", failures)
	_check(identity != null and identity_host != null and identity.get_parent() == identity_host, "Rooster Operations identity should remain attached to its physical host", failures)
	_check(identity_host != null and StringName(identity_host.get_meta(&"architectural_mount", &"")) == &"command_lintel", "Rooster Operations identity should publish its command-lintel mount", failures)
	_check(visual.find_children("RoosterOperationsLintelBracket*", "MeshInstance3D", true, false).size() == 2, "Rooster Operations lintel should retain two visible fascia brackets", failures)
	_check(visual.find_children("RoosterOperationsIdentityHanger*", "MeshInstance3D", true, false).is_empty(), "Rooster Operations identity should no longer use floating hanger rods", failures)
	_check(identity_heading != null and identity_heading.text == "ROOSTER OPERATIONS" and identity_body != null and identity_body.text == "SCHEDULE & SUPERVISION", "Rooster Operations identity should retain its exact heading and subtitle", failures)

	visual.apply_snapshot({
		"operations": {"rooster_office_level": 0},
		"facility_catalog": [{"id": &"rooster_operations_office", "unlocked": true, "level": 0}],
	})
	_check(visual.visual_state() == &"survey" and visual.survey_site_visible(), "earned unlock should reveal only the operations survey", failures)

	for level in 3:
		var purchased_level := level + 1
		visual.apply_snapshot({
			"operations": {
				"rooster_office_level": purchased_level,
				"supervision": {
					"action_limit": [2, 3, 4][level],
					"actions_used": [1, 1, 2][level],
					"actions_remaining": [1, 2, 2][level],
					"supervisor_payroll_cents": [500, 800, 1200][level],
					"surveillance_grievance_millipoints": [750, 1250, 2000][level],
					"surveillance_stress_millipoints": [500, 1000, 1500][level],
					"surveillance_solidarity_millipoints": [500, 1000, 1500][level],
					"quota_pressure_actions_today": level,
					"shift_pressure_applied": level > 0,
				},
			},
			"workers": [],
		})
		_check(visual.visual_state() == StringName("level_%d" % purchased_level), "Rooster Operations tier %d should publish its visual state" % purchased_level, failures)
		_check(visual.visible_supervisor_station_count() == purchased_level, "Rooster Operations tier %d should reveal exactly %d stations" % [purchased_level, purchased_level], failures)
		for retained_level in range(1, purchased_level + 1):
			_check(visual.level_visible(retained_level), "Rooster Operations tier %d should retain tier %d" % [purchased_level, retained_level], failures)
		_check(visual.geometry_bounds_inside_footprint(), "Rooster Operations tier %d should stay parcel-bound" % purchased_level, failures)

	visual.apply_snapshot({
		"operations": {
			"rooster_office_level": 3,
			"supervision": {
				"action_limit": 4,
				"actions_used": 2,
				"actions_remaining": 2,
				"supervisor_payroll_cents": 1200,
				"surveillance_grievance_millipoints": 2000,
				"surveillance_stress_millipoints": 1500,
				"surveillance_solidarity_millipoints": 1500,
				"quota_pressure_actions_today": 2,
				"shift_pressure_applied": true,
			},
		},
		"claim_queue_counts": {&"nest_damage": 3, &"predator_loss": 2, &"appeals": 1},
		"active_directive": {"id": &"accelerate_intake", "name": "Accelerate Intake"},
		"workers": [
			{"id": 10, "display_name": "Mabel", "employed": true, "assigned_lane": &"nest_damage", "assignment_name": "Nest Damage"},
			{"id": 11, "display_name": "Cluckson", "employed": true, "assigned_lane": &"appeals", "assignment_name": "Appeals"},
			{"id": 12, "display_name": "Off Payroll", "employed": false, "assigned_lane": &"auto"},
		],
	})
	_check(visual.has_authoritative_metrics(), "Rooster Operations should recognize canonical supervision metrics", failures)
	_check(visual.debug_state().get("action_limit") == 4 and visual.debug_state().get("actions_used") == 2 and visual.debug_state().get("actions_remaining") == 2, "Rooster Operations should consume canonical action keys", failures)
	_check(visual.assignment_worker_ids() == [10, 11], "assignment rail should expose only authoritative employed workers", failures)
	_check(visual.active_directive_visible() and visual.active_directive_id() == &"accelerate_intake", "command gallery should expose only the authoritative active directive", failures)
	_check("ACTIONS 2/4" in visual.operations_status_text() and "$12.00" in visual.operations_status_text() and "+2.00G" in visual.operations_status_text(), "live supervision screen should show canonical economic effects", failures)
	_check("N 03" in visual.queue_status_text() and "P 02" in visual.queue_status_text() and "A 01" in visual.queue_status_text(), "queue screen should mirror authoritative lane counts", failures)
	_check(visual.find_children("*DecorativeEgg*", "", true, false).is_empty(), "Rooster Operations must not invent eggs", failures)
	_check(visual.find_children("*FakeWorker*", "", true, false).is_empty(), "Rooster Operations must not invent workers", failures)
	_check(visual.find_children("*FakeFolder*", "", true, false).is_empty(), "Rooster Operations must not invent folders", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("ROOSTER_OPERATIONS_OFFICE_VISUAL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("ROOSTER_OPERATIONS_OFFICE_VISUAL_TEST_PASSED states=locked-survey-l1-l2-l3 stations=1-2-3 canonical_actions=yes props=authoritative bounds=inside collisions=0")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
