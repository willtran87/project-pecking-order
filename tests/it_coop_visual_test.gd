extends SceneTree

const ITCoopVisualScript := preload("res://features/office/it_coop_visual.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var visual := ITCoopVisualScript.new() as ITCoopVisual
	root.add_child(visual)
	await process_frame

	_check(ITCoopVisualScript.declared_footprint() == Rect2(Vector2(12.0, 33.1), Vector2(6.4, 5.8)), "IT Coop should retain its exact parcel", failures)
	_check(ITCoopVisualScript.facility_focus_point().is_equal_approx(Vector3(15.2, 1.05, 36.0)), "IT Coop should publish its stable focus", failures)
	_check(is_equal_approx(ITCoopVisualScript.maximum_visual_height(), 3.55), "IT Coop should honor the 3.55m envelope", failures)
	_check(visual.visual_state() == &"locked" and visual.locked_marker_visible(), "fresh IT Coop should show only the locked parcel", failures)
	_check(visual.systems_unit_count() == 3 and visual.visible_systems_unit_count() == 0, "three cumulative systems units should be authored but hidden before purchase", failures)
	_check(visual.geometry_bounds_inside_footprint(), "locked IT Coop geometry should stay parcel-bound", failures)
	_check(visual.find_children("*", "CollisionObject3D", true, false).is_empty(), "IT Coop should remain collision-free", failures)
	_check(visual.find_children("*", "NavigationRegion3D", true, false).is_empty(), "IT Coop should not create navigation regions", failures)
	_check(visual.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "IT Coop should not create navigation obstacles", failures)
	_check(visual.find_child("ITCoopNorthWall", true, false) == null, "camera-facing IT frontage should remain a cutaway", failures)
	var cutaway := visual.find_child("ITCoopNorthCutawayDado", true, false) as MeshInstance3D
	_check(cutaway != null and cutaway.mesh is BoxMesh and (cutaway.mesh as BoxMesh).size.y <= 0.47, "IT Coop should use a low north dado", failures)
	var identity := visual.find_child("ITCoopIdentityFixture", true, false) as Node3D
	_check(identity != null and StringName(identity.get_meta(&"sign_tier", &"")) == &"primary", "IT Coop identity should be a primary mounted fixture", failures)
	_check(identity != null and StringName(identity.get_meta(&"copy_band", &"")) == &"destination", "IT Coop identity should use destination hierarchy", failures)
	_check(identity != null and bool(identity.get_meta(&"uses_modeled_type", false)), "IT Coop identity should use modeled host lettering", failures)
	var rack_top_rail := visual.find_child("ITCoopIdentityRackTopRail", true, false) as MeshInstance3D
	var identity_host := visual.find_child("ITCoopIdentityHost", true, false) as MeshInstance3D
	var identity_heading := visual.find_child("ITCoopIdentity", true, false) as Label3D
	var identity_body := visual.find_child("ITCoopIdentityBody", true, false) as Label3D
	_check(rack_top_rail != null and identity_host != null and identity_host.get_parent() == rack_top_rail, "IT Coop identity fascia should occupy the top equipment-rack bay", failures)
	_check(identity != null and identity_host != null and identity.get_parent() == identity_host, "IT Coop identity should remain attached to its physical host", failures)
	_check(identity_host != null and StringName(identity_host.get_meta(&"architectural_mount", &"")) == &"equipment_rack", "IT Coop identity should publish its equipment-rack mount", failures)
	_check(visual.find_children("ITCoopIdentityRackStile*", "MeshInstance3D", true, false).size() == 2 and visual.find_child("ITCoopIdentityRackBottomRail", true, false) != null, "IT Coop identity rack should land on two stiles and a bottom rail", failures)
	_check(visual.find_children("ITCoopIdentityHanger*", "MeshInstance3D", true, false).is_empty(), "IT Coop identity should no longer use floating hanger rods", failures)
	_check(identity_heading != null and identity_heading.text == "IT COOP" and identity_body != null and identity_body.text == "PATCHING & AUTOMATION", "IT Coop identity should retain its exact heading and subtitle", failures)

	visual.apply_snapshot({
		"operations": {"it_coop_level": 0},
		"facility_catalog": [{"id": &"it_coop", "unlocked": true, "level": 0}],
	})
	_check(visual.visual_state() == &"survey" and visual.survey_site_visible(), "earned unlock should reveal only the IT survey", failures)

	for level in 3:
		var purchased_level := level + 1
		visual.apply_snapshot({
			"operations": {
				"it_coop_level": purchased_level,
				"automation": {
					"enabled": true,
					"work_basis_points": [10300, 10600, 11000][level],
					"work_multiplier": [1.03, 1.06, 1.10][level],
					"specialty_grace_minutes": [150, 120, 60][level],
					"recognizes_secondary_specialties": level >= 1,
					"compliance_exposure_millipoints": [1000, 1800, 2800][level],
					"ledger_patch_cost_cents": [2200, 2600, 3000][level],
					"spreadsheet_compliance_loss_millipoints": [8000, 10000, 12000][level],
					"spreadsheet_crack_basis_points": [200, 300, 400][level],
					"auto_enrolled_workers": 0,
					"active_auto_claims": 0,
					"shift_exposure_applied": level > 0,
				},
			},
			"workers": [],
		})
		_check(visual.visual_state() == StringName("level_%d" % purchased_level), "IT Coop tier %d should publish its visual state" % purchased_level, failures)
		_check(visual.visible_systems_unit_count() == purchased_level, "IT Coop tier %d should reveal exactly %d systems units" % [purchased_level, purchased_level], failures)
		for retained_level in range(1, purchased_level + 1):
			_check(visual.level_visible(retained_level), "IT Coop tier %d should retain tier %d" % [purchased_level, retained_level], failures)
		_check(visual.geometry_bounds_inside_footprint(), "IT Coop tier %d should stay parcel-bound" % purchased_level, failures)

	visual.apply_snapshot({
		"operations": {
			"it_coop_level": 3,
			"automation": {
				"enabled": true,
				"work_basis_points": 11000,
				"work_multiplier": 1.10,
				"specialty_grace_minutes": 60,
				"recognizes_secondary_specialties": true,
				"compliance_exposure_millipoints": 2800,
				"ledger_patch_cost_cents": 3000,
				"spreadsheet_compliance_loss_millipoints": 12000,
				"spreadsheet_crack_basis_points": 400,
				"auto_enrolled_workers": 2,
				"active_auto_claims": 4,
				"shift_exposure_applied": true,
			},
		},
		"claim_queue_counts": {&"nest_damage": 3, &"predator_loss": 2, &"appeals": 1},
		"workers": [
			{"id": 20, "display_name": "Mabel", "employed": true, "assigned_lane": &"auto"},
			{"id": 21, "display_name": "Cluckson", "employed": true, "assigned_lane": &"auto"},
			{"id": 22, "display_name": "Manual Hen", "employed": true, "assigned_lane": &"appeals"},
			{"id": 23, "display_name": "Off Payroll", "employed": false, "assigned_lane": &"auto"},
		],
	})
	_check(visual.has_authoritative_metrics(), "IT Coop should recognize canonical automation metrics", failures)
	_check(visual.debug_state().get("work_basis_points") == 11000 and visual.debug_state().get("specialty_grace_minutes") == 60, "IT Coop should consume canonical automation keys", failures)
	_check(visual.auto_worker_ids() == [20, 21], "IT patch bay should expose only authoritative auto-enrolled workers", failures)
	_check(visual.patch_invoice_visible(), "tier-three IT Coop should show its authoritative ledger patch invoice", failures)
	var invoice := visual.find_child("LedgerMoltPatchInvoice", true, false) as Node3D
	_check(invoice != null and int(invoice.get_meta(&"ledger_patch_cost_cents", -1)) == 3000 and int(invoice.get_meta(&"spreadsheet_compliance_loss_millipoints", -1)) == 12000, "patch invoice should retain canonical cost and compliance exposure", failures)
	_check("AUTO 110%" in visual.automation_status_text() and "GRACE 60M" in visual.automation_status_text() and "PATCH $30.00" in visual.automation_status_text(), "automation screen should show canonical economic terms", failures)
	_check("AUTO HENS 2" in visual.load_status_text() and "ACTIVE 4" in visual.load_status_text(), "load screen should mirror authoritative worker and claim counts", failures)
	_check(visual.find_children("*DecorativeEgg*", "", true, false).is_empty(), "IT Coop must not invent eggs", failures)
	_check(visual.find_children("*FakeClaim*", "", true, false).is_empty(), "IT Coop must not invent claims", failures)
	_check(visual.find_children("*FakeWorker*", "", true, false).is_empty(), "IT Coop must not invent workers", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("IT_COOP_VISUAL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("IT_COOP_VISUAL_TEST_PASSED states=locked-survey-l1-l2-l3 systems=1-2-3 automation=canonical props=authoritative bounds=inside collisions=0")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
