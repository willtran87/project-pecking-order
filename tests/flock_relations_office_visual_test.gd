extends SceneTree

const FlockRelationsOfficeVisualScript := preload("res://features/office/flock_relations_office_visual.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var visual := FlockRelationsOfficeVisualScript.new() as FlockRelationsOfficeVisual
	root.add_child(visual)
	await process_frame

	_check(FlockRelationsOfficeVisualScript.declared_footprint() == Rect2(Vector2(4.10, 33.10), Vector2(6.40, 5.80)), "Flock Relations should retain its exact west-campus parcel", failures)
	_check(FlockRelationsOfficeVisualScript.entrance_bridge_footprint() == Rect2(Vector2(10.50, 35.40), Vector2(0.25, 1.20)), "Flock Relations should publish its exact spine bridge", failures)
	_check(FlockRelationsOfficeVisualScript.clear_aisle_footprint() == Rect2(Vector2(8.20, 35.45), Vector2(2.55, 1.10)), "Flock Relations should publish its exact clear east-entry aisle", failures)
	_check(FlockRelationsOfficeVisualScript.facility_focus_point().is_equal_approx(Vector3(7.30, 1.05, 36.00)), "Flock Relations should publish its stable purchase focus", failures)
	_check(is_equal_approx(FlockRelationsOfficeVisualScript.maximum_visual_height(), 3.55), "Flock Relations should honor the 3.55m envelope", failures)
	_check(is_equal_approx(FlockRelationsOfficeVisualScript.EAST_DOOR_WIDTH, 1.20), "Flock Relations should retain its exact 1.20m east door", failures)
	_check(visual.focus_point_global().is_equal_approx(Vector3(7.30, 1.05, 36.00)), "global focus should account for the positioned visual root exactly once", failures)
	_check(visual.visual_state() == &"locked" and visual.locked_marker_visible(), "fresh Flock Relations should show only its locked parcel", failures)
	_check(visual.pigeonhole_count() == 6 and visual.waiting_perch_count() == 2, "case intake should author six empty pigeonholes and two waiting perches", failures)
	_check(visual.visible_case_folder_count() == 0 and visual.open_case_ids().is_empty(), "empty construction state must not invent case folders", failures)
	_check(not visual.resolution_docket_visible() and visual.illuminated_outcome() == &"", "empty construction state must not invent a settlement", failures)
	_check(visual.geometry_bounds_inside_footprint(), "all room geometry should stay in the declared parcel", failures)
	_check(visual.connector_geometry_inside_bridge(), "all connector geometry should stay in the exact bridge parcel", failures)
	_check(visual.circulation_clear(), "the exact east-entry aisle should remain free of blocking geometry", failures)
	_check(visual.find_children("*", "CollisionObject3D", true, false).is_empty(), "Flock Relations should remain collision-free", failures)
	_check(visual.find_children("*", "NavigationRegion3D", true, false).is_empty(), "Flock Relations should not create navigation regions", failures)
	_check(visual.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "Flock Relations should not create navigation obstacles", failures)
	_check(visual.find_child("FlockRelationsNorthWall", true, false) == null, "camera-facing frontage should remain a cutaway", failures)
	var cutaway := visual.find_child("FlockRelationsNorthCutawayDado", true, false) as MeshInstance3D
	_check(cutaway != null and cutaway.mesh is BoxMesh and (cutaway.mesh as BoxMesh).size.y <= 0.47, "Flock Relations should use a low north cutaway dado", failures)
	_check(visual.find_children("FlockRelationsEastWallSegment_*", "MeshInstance3D", true, false).size() == 2, "east wall should be split into two authored doorway segments", failures)
	var identity := visual.find_child("FlockRelationsIdentityFixture", true, false) as Node3D
	_check(identity != null and StringName(identity.get_meta(&"sign_tier", &"")) == &"primary", "Flock Relations identity should be a primary mounted fixture", failures)
	_check(identity != null and StringName(identity.get_meta(&"copy_band", &"")) == &"destination", "Flock Relations identity should use destination hierarchy", failures)
	_check(identity != null and bool(identity.get_meta(&"uses_modeled_type", false)), "Flock Relations identity should use modeled host lettering", failures)
	var identity_host := visual.find_child("FlockRelationsIdentityHost", true, false) as MeshInstance3D
	var identity_heading := visual.find_child("FlockRelationsIdentity", true, false) as Label3D
	var identity_body := visual.find_child("FlockRelationsIdentityBody", true, false) as Label3D
	_check(identity_host != null and identity != null and identity.get_parent() == identity_host, "Flock Relations identity should remain attached to its physical host", failures)
	_check(identity_host != null and StringName(identity_host.get_meta(&"architectural_mount", &"")) == &"glazed_transom_band" and bool(identity_host.get_meta(&"glass_identity_band", false)), "Flock Relations identity should be integrated into the glazed transom band", failures)
	_check(visual.find_child("FlockRelationsIdentityGlassBandTopRail", true, false) != null and visual.find_child("FlockRelationsIdentityGlassBandBottomRail", true, false) != null, "Flock Relations glass identity band should terminate in full-width rails", failures)
	_check(visual.find_children("FlockRelationsIdentityGlassBandMullion*", "MeshInstance3D", true, false).size() == 2, "Flock Relations glass identity band should retain two visible mullions", failures)
	_check(visual.find_children("FlockRelationsIdentityHanger*", "MeshInstance3D", true, false).is_empty(), "Flock Relations identity should no longer use floating hanger rods", failures)
	_check(identity_heading != null and identity_heading.text == "FLOCK RELATIONS" and identity_body != null and identity_body.text == "GRIEVANCE & COMPLIANCE", "Flock Relations identity should retain its exact heading and subtitle", failures)

	visual.apply_snapshot({
		"flock_relations": _neutral_relations(0),
		"facility_catalog": [{"id": &"flock_relations_office", "unlocked": true, "level": 0}],
	})
	_check(visual.visual_state() == &"survey" and visual.survey_site_visible(), "earned unlock should reveal only the case-intake survey", failures)
	_check(visual.visible_case_folder_count() == 0 and not visual.resolution_docket_visible(), "neutral survey must remain free of activity props", failures)

	for level_index in 3:
		var level := level_index + 1
		var relations := _neutral_relations(level)
		relations["capacity"] = [2, 4, 6][level_index]
		relations["resolution_limit"] = [1, 1, 2][level_index]
		visual.apply_snapshot({"flock_relations": relations})
		_check(visual.visual_state() == StringName("level_%d" % level), "Flock Relations tier %d should publish its own state" % level, failures)
		for retained_level in range(1, level + 1):
			_check(visual.level_visible(retained_level), "Flock Relations tier %d should retain tier %d" % [level, retained_level], failures)
		_check(visual.visible_case_folder_count() == 0 and visual.open_case_worker_ids().is_empty(), "neutral tier %d must not fabricate cases or workers" % level, failures)
		_check(not visual.resolution_docket_visible() and visual.illuminated_outcome() == &"", "neutral tier %d must not fabricate a resolution" % level, failures)
		_check(visual.geometry_bounds_inside_footprint(), "Flock Relations tier %d should remain parcel-bound" % level, failures)
		_check(visual.connector_geometry_inside_bridge(), "Flock Relations tier %d should retain its exact connector" % level, failures)
		_check(visual.circulation_clear(), "Flock Relations tier %d should retain the clear aisle" % level, failures)

	_check(visual.find_child("OpenNestIntakeCounterTop", true, false) != null, "tier one should include the Open-Nest intake counter", failures)
	_check(visual.find_child("CaseTicketWheel", true, false) != null, "tier one should include the hosted ticket wheel", failures)
	_check(visual.find_child("MediationFeltTableTop", true, false) != null, "tier two should include the rounded felt mediation table", failures)
	_check(visual.find_children("MediationPrivacyPane_*", "MeshInstance3D", true, false).size() == 5, "tier two should include the five-pane privacy arc", failures)
	_check(visual.find_child("RemedyStamp", true, false) != null and visual.find_child("PIPStamp", true, false) != null, "tier two should include distinct Remedy and PIP stamps", failures)
	_check(visual.find_child("MandatoryArbitrationBenchTop", true, false) != null, "tier three should include the arbitration bench", failures)
	_check(visual.find_child("PrecedentVaultCabinet", true, false) != null, "tier three should include an empty precedent vault", failures)
	_check(visual.find_child("ComplianceSealDie", true, false) != null, "tier three should include the compliance seal", failures)
	_check(visual.find_child("EmptySettlementTray", true, false) != null, "tier three should include an explicitly empty settlement tray", failures)

	visual.apply_snapshot({
		"flock_relations": {
			"level": 3,
			"capacity": 6,
			"resolution_limit": 2,
			"resolutions_used_today": 1,
			"open_case_count": 3,
			"open_cases": [
				{"case_id": 12, "docket_id": "FR-D8-H0-12", "worker_id": 0, "worker_name": "Mabel", "case_type": &"automation_appeal", "title": "Automated Assignment Appeal", "severity": 1, "filed_day": 8, "status": &"open", "evidence_summary": "Compliance 54"},
				{"case_id": 13, "docket_id": "FR-D8-H2-13", "worker_id": 2, "worker_name": "Henrietta", "case_type": &"surveillance_grievance", "title": "Supervision & Surveillance Grievance", "severity": 2, "filed_day": 8, "status": &"open", "evidence_summary": "Grievance 62"},
				{"case_id": 14, "docket_id": "FR-D8-H4-14", "worker_id": 4, "worker_name": "Pecky", "case_type": &"pay_dispute", "title": "Deferred Feed Pay Dispute", "severity": 3, "filed_day": 8, "status": &"open", "evidence_summary": "Arrears $12.00"},
			],
			"resolved_total": 7,
			"denied_total": 2,
			"settlement_spend_total_cents": 4200,
			"last_resolution": {"case_id": 11, "worker_id": 3, "worker_name": "Cluckson", "action_id": &"file_pip", "action_label": "File Performance Plan", "cost_cents": 0, "outcome": "Performance plan filed."},
		},
	})
	_check(visual.has_authoritative_relations(), "Flock Relations should recognize the canonical nested snapshot", failures)
	_check(visual.open_case_ids() == [12, 13, 14], "case folders should preserve authoritative integer case IDs", failures)
	_check(visual.open_case_worker_ids() == [0, 2, 4], "case folders should preserve authoritative worker IDs", failures)
	_check(visual.visible_case_folder_count() == 3, "case intake should materialize exactly three canonical open cases", failures)
	var first_folder := visual.find_child("AuthoritativeOpenCaseFolder_01", true, false) as Node3D
	_check(first_folder != null and String(first_folder.get_meta(&"docket_id", "")) == "FR-D8-H0-12", "physical folder should use the canonical human-readable docket ID", failures)
	_check(first_folder != null and int(first_folder.get_meta(&"case_id", -1)) == 12, "physical folder should retain the canonical integer case ID", failures)
	_check(first_folder != null and StringName(first_folder.get_meta(&"case_type", &"")) == &"automation_appeal" and String(first_folder.get_meta(&"evidence_summary", "")) == "Compliance 54", "physical folder should retain canonical type and evidence metadata", failures)
	_check(visual.resolution_docket_visible() and visual.last_resolution_id() == &"file_pip", "settlement tray should reflect only the canonical last resolution", failures)
	_check(visual.illuminated_outcome() == &"pip", "a file_pip resolution should illuminate only the PIP outcome", failures)
	_check("OPEN 03/06" in visual.relations_status_text() and "REVIEW 1/2" in visual.relations_status_text(), "case console should show canonical capacity and daily resolution use", failures)
	_check("RESOLVED 007" in visual.relations_status_text() and "DENIED 002" in visual.relations_status_text() and "$42.00" in visual.relations_status_text(), "case console should show canonical lifetime case ledgers", failures)
	_check(visual.geometry_bounds_inside_footprint() and visual.connector_geometry_inside_bridge(), "dynamic records should retain the authored geometry contracts", failures)
	_check(visual.circulation_clear(), "dynamic records should never enter the clear aisle", failures)

	visual.apply_snapshot({"flock_relations": _neutral_relations(3)})
	_check(visual.visible_case_folder_count() == 0 and visual.open_case_ids().is_empty(), "neutral reconciliation should remove every prior case folder", failures)
	_check(not visual.resolution_docket_visible() and visual.illuminated_outcome() == &"", "neutral reconciliation should clear the resolution docket and lamps", failures)
	_check(visual.find_children("*DecorativeEgg*", "", true, false).is_empty(), "Flock Relations must not invent eggs", failures)
	_check(visual.find_children("*FakeWorker*", "", true, false).is_empty(), "Flock Relations must not invent workers", failures)
	_check(visual.find_children("*FakeFolder*", "", true, false).is_empty(), "Flock Relations must not invent folders", failures)
	_check(visual.find_children("*FakeSettlement*", "", true, false).is_empty(), "Flock Relations must not invent settlements", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("FLOCK_RELATIONS_OFFICE_VISUAL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FLOCK_RELATIONS_OFFICE_VISUAL_TEST_PASSED states=locked-survey-l1-l2-l3 cases=open_cases-only resolution=last-only bridge=exact aisle=clear bounds=inside collisions=0")
	quit(0)


func _neutral_relations(level: int) -> Dictionary:
	return {
		"level": level,
		"capacity": 0,
		"resolution_limit": 0,
		"resolutions_used_today": 0,
		"open_case_count": 0,
		"open_cases": [],
		"resolved_total": 0,
		"denied_total": 0,
		"settlement_spend_total_cents": 0,
		"last_resolution": {},
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
