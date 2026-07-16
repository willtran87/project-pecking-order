extends SceneTree

## Visual hierarchy contract for in-world office copy. The broad signage tests
## prove that copy is mounted and physically fitted; this test proves that the
## most distant words read as authored architecture while operational copy
## recedes into the material that owns it.

const MAJOR_LANDMARK_FIXTURES: PackedStringArray = [
	"BureauIdentityFixture",
	"PerchTitleFixture",
	"FarmerBrandAnnexIdentityFixture",
	"RecordsAnnexIdentityFixture",
	"FarmMutualServiceCoopIdentityFixture",
	"FarmMutualNegotiationIdentityFixture",
	"WellnessNestIdentityFixture",
	"TrainingRoostIdentityFixture",
	"RoosterOperationsIdentityFixture",
	"ITCoopIdentityFixture",
	"FlockRelationsIdentityFixture",
	"FeedProcurementIdentityFixture",
]

const PURCHASED_LANDMARK_FIXTURES: PackedStringArray = [
	"PerchTitleFixture",
	"FarmerBrandAnnexIdentityFixture",
	"RecordsAnnexIdentityFixture",
	"FarmMutualServiceCoopIdentityFixture",
	"FarmMutualNegotiationIdentityFixture",
	"WellnessNestIdentityFixture",
	"TrainingRoostIdentityFixture",
	"RoosterOperationsIdentityFixture",
	"ITCoopIdentityFixture",
	"FlockRelationsIdentityFixture",
	"FeedProcurementIdentityFixture",
]

const SECONDARY_PARCEL_FIXTURES: PackedStringArray = [
	"PackingAnnexLeaseOptionFixture",
	"RecordsAnnexLeaseOptionFixture",
	"FarmMutualServiceParcelFixture",
	"WellnessNestLockedNoticeFixture",
	"TrainingRoostLockedNoticeFixture",
	"RoosterOperationsLockedNoticeFixture",
	"ITCoopLockedNoticeFixture",
	"FlockRelationsLockedNoticeFixture",
]

const SECONDARY_PARCEL_PRESENTATION_IDS: Dictionary = {
	"PackingAnnexLeaseOptionFixture": &"farmer_brand_packing_annex",
	"RecordsAnnexLeaseOptionFixture": &"records_annex",
	"FarmMutualServiceParcelFixture": &"farm_mutual_service_coop",
	"WellnessNestLockedNoticeFixture": &"wellness_nest_room",
	"TrainingRoostLockedNoticeFixture": &"training_roost",
	"RoosterOperationsLockedNoticeFixture": &"rooster_operations_office",
	"ITCoopLockedNoticeFixture": &"it_coop",
	"FlockRelationsLockedNoticeFixture": &"flock_relations_office",
}

const UTILITY_FIXTURES: PackedStringArray = [
	"PresentationPlaqueTextFixture",
	"WeighingHeadPlateFixture",
	"RetentionVaultPlateFixture",
	"AccreditationVaultPlateFixture",
	"QuietNestCubbiesPlateFixture",
	"PracticeTerminalLanePlate_01Fixture",
	"SupervisorStationPlate_01Fixture",
	"SystemsUnitPlate_01Fixture",
	"OpenNestCaseIntakePlateFixture",
	"ReceivingHopperTierPlateFixture",
]

const REQUIRED_LANDMARK_LINES: Dictionary = {
	"BureauIdentityFixture": ["EGG YIELD BUREAU", "CLUTCH INTAKE & CREDIT"],
	"PerchTitleFixture": ["FLOCKWATCH"],
	"FarmerBrandAnnexIdentityFixture": ["FARMER BRAND"],
	"RecordsAnnexIdentityFixture": ["RECORDS ANNEX"],
	"FarmMutualServiceCoopIdentityFixture": [
		"FARM MUTUAL SERVICE COOP",
		"ACCREDITATION & DISPATCH",
	],
	"FarmMutualNegotiationIdentityFixture": [
		"FARM MUTUAL COUNCIL ROOM",
		"CLAUSE & CREDIT TABLE",
	],
	"WellnessNestIdentityFixture": [
		"WELLNESS NEST",
		"RECOVERY & REST",
	],
	"TrainingRoostIdentityFixture": [
		"TRAINING ROOST",
		"PRACTICE & ACCREDITATION",
	],
	"RoosterOperationsIdentityFixture": [
		"ROOSTER OPERATIONS",
		"SCHEDULE & SUPERVISION",
	],
	"ITCoopIdentityFixture": [
		"IT COOP",
		"PATCHING & AUTOMATION",
	],
	"FlockRelationsIdentityFixture": [
		"FLOCK RELATIONS",
		"GRIEVANCE & COMPLIANCE",
	],
	"FeedProcurementIdentityFixture": [
		"FLOCK PROVISIONS CO-OP",
		"FEED PROCUREMENT & RESERVE",
	],
}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	var simulation := office.get("_simulation") as DepartmentSimulation
	var storytelling := office.get("_office_storytelling") as OfficeStorytelling
	var fresh_snapshot := simulation.snapshot() if simulation != null else {}
	_check(
		simulation != null and storytelling != null,
		"office should expose its authoritative snapshot and campus presentation seam",
		failures,
	)

	var major_proxies: Array[Label3D] = []
	for fixture_name in MAJOR_LANDMARK_FIXTURES:
		var fixture := office.find_child(fixture_name, true, false) as Node3D
		_check(fixture != null, "%s should exist as a major office landmark" % fixture_name, failures)
		if fixture == null:
			continue
		var text_meshes := _text_meshes(fixture)
		var proxies := _semantic_proxies(fixture)
		_check(not text_meshes.is_empty(), "%s should render its static heading with modeled TextMesh glyphs" % fixture_name, failures)
		_check(not proxies.is_empty(), "%s should retain a hidden Label3D semantic proxy" % fixture_name, failures)
		for proxy in proxies:
			_check(not proxy.visible, "%s semantic proxy must stay visually hidden" % proxy.name, failures)
			_check(is_zero_approx(float(proxy.get_meta(&"resting_alpha", proxy.modulate.a))), "%s semantic proxy must publish zero resting alpha" % proxy.name, failures)
		var matched_copy := false
		for text_mesh in text_meshes:
			_check(
				text_mesh.rotation.is_equal_approx(Vector3.ZERO),
				"%s modeled lettering should present its readable face to the room" % text_mesh.name,
				failures,
			)
			_check(
				bool(text_mesh.get_meta(&"readable_face_outward", false)),
				"%s should publish its outward-facing installation contract" % text_mesh.name,
				failures,
			)
			var modeled_copy := String((text_mesh.mesh as TextMesh).text).strip_edges()
			for proxy in proxies:
				if modeled_copy == proxy.text.strip_edges():
					matched_copy = true
		_check(matched_copy, "%s modeled heading and semantic proxy should carry identical copy" % fixture_name, failures)
		var authored_lines := _authored_lines(fixture)
		for required_line in REQUIRED_LANDMARK_LINES.get(fixture_name, []):
			_check(
				authored_lines.has(String(required_line)),
				"%s should retain authored line '%s'" % [fixture_name, required_line],
				failures,
			)
		major_proxies.append_array(proxies)

	for fixture_name in PURCHASED_LANDMARK_FIXTURES:
		var fixture := office.find_child(fixture_name, true, false) as Node3D
		if fixture == null:
			continue
		_check(StringName(fixture.get_meta(&"sign_tier", &"")) == &"primary", "%s should be promoted to the primary landmark tier once its room exists" % fixture_name, failures)
		_check(bool(fixture.get_meta(&"overview_anchor", false)), "%s should remain an authored overview landmark" % fixture_name, failures)

	# Lease and parcel copy is useful while inspecting a prospective expansion,
	# but it should not compete with purchased departments in the office overview.
	EnvironmentalSignage.set_camera_detail(
		office, false, Vector3(INF, INF, INF),
		EnvironmentalSignage.FOCUSED_DETAIL_RADIUS, false
	)
	var operational_screen := office.find_child(
		"ManagementYieldBoard", true, false
	) as Label3D
	var operational_fixture := (
		operational_screen.get_parent() as Node3D
		if operational_screen != null
		else null
	)
	_check(operational_screen != null, "office should expose an operational yield screen", failures)
	_check(operational_fixture != null, "operational yield screen should retain its monitor fixture", failures)
	if operational_screen != null and operational_fixture != null:
		_check(StringName(operational_fixture.get_meta(&"style_family", &"")) == &"screen", "operational yield readout should remain mounted in modeled screen hardware", failures)
		_check(StringName(operational_fixture.get_meta(&"copy_band", &"")) == &"live", "operational yield readout should retain its live-copy classification", failures)
		_check(not bool(operational_fixture.get_meta(&"overview_critical_readout", true)), "operational screens should not opt into overview visibility by default", failures)
		_check(not bool(operational_fixture.get_meta(&"overview_anchor", true)), "operational screen glyphs should not become overview anchors by default", failures)
		_check(operational_fixture.visible, "physical monitor mount should remain visible at overview", failures)
		_check(not operational_screen.visible, "operational screen glyphs should recede at overview", failures)

		EnvironmentalSignage.set_overview_critical_readout(operational_screen, true)
		EnvironmentalSignage.set_camera_detail(
			office, false, Vector3(INF, INF, INF),
			EnvironmentalSignage.FOCUSED_DETAIL_RADIUS, false
		)
		_check(bool(operational_fixture.get_meta(&"overview_critical_readout", false)), "rare critical readouts should expose explicit overview opt-in metadata", failures)
		_check(operational_screen.visible, "explicitly critical readout should remain legible at overview", failures)
		_check(operational_fixture.visible, "critical-readout opt-in must not replace or hide its modeled monitor", failures)

		EnvironmentalSignage.set_overview_critical_readout(operational_screen, false)
		EnvironmentalSignage.set_camera_detail(
			office, false, Vector3(INF, INF, INF),
			EnvironmentalSignage.FOCUSED_DETAIL_RADIUS, false
		)
		_check(not operational_screen.visible, "disabling the explicit readout opt-in should restore overview restraint", failures)

	for fixture_name in ["BureauIdentityFixture", "PerchTitleFixture"]:
		var landmark_fixture := office.find_child(fixture_name, true, false) as Node3D
		_check(landmark_fixture != null, "%s should remain available for overview hierarchy coverage" % fixture_name, failures)
		if landmark_fixture != null:
			_check(bool(landmark_fixture.get_meta(&"overview_anchor", false)), "%s should retain its landmark overview role" % fixture_name, failures)
			_check(_authored_copy_visible(landmark_fixture), "%s authored identity or destination copy should remain visible at overview" % fixture_name, failures)
	for fixture_name in SECONDARY_PARCEL_FIXTURES:
		var fixture := office.find_child(fixture_name, true, false) as Node3D
		_check(fixture != null, "%s should exist as secondary parcel copy" % fixture_name, failures)
		if fixture == null:
			continue
		var presentation_id := StringName(SECONDARY_PARCEL_PRESENTATION_IDS.get(
			fixture_name, &""
		))
		_check(StringName(fixture.get_meta(&"sign_tier", &"")) == &"secondary", "%s should remain secondary rather than becoming another room landmark" % fixture_name, failures)
		_check(not bool(fixture.get_meta(&"overview_anchor", true)), "%s should not be an overview anchor" % fixture_name, failures)
		_check(not _authored_copy_visible(fixture), "%s copy should recede in the office overview" % fixture_name, failures)
		_check(
			storytelling != null
			and storytelling.campus_presentation_state(presentation_id) == &"hidden",
			"%s should remain undiscovered in the fresh Day-1 campus" % fixture_name,
			failures,
		)
		if storytelling != null:
			storytelling.apply_campus_presentation(
				_pinned_parcel_snapshot(fresh_snapshot, presentation_id)
			)
		_check(
			storytelling != null
			and storytelling.campus_presentation_state(presentation_id) == &"pinned",
			"%s should be legitimately revealed before its parcel copy is inspected" % fixture_name,
			failures,
		)
		EnvironmentalSignage.set_camera_detail(
			office, true, fixture.global_position, 1.25, false
		)
		_check(_authored_copy_visible(fixture), "%s copy should appear when its parcel is inspected" % fixture_name, failures)
		EnvironmentalSignage.set_camera_detail(
			office, false, Vector3(INF, INF, INF),
			EnvironmentalSignage.FOCUSED_DETAIL_RADIUS, false
		)

	# Dimensional parcel lettering must dissolve with the rest of the physical
	# print hierarchy. A hard visibility snap makes a real mesh behave like HUD.
	var animated_fixture := office.find_child(
		SECONDARY_PARCEL_FIXTURES[0], true, false
	) as Node3D
	if animated_fixture != null:
		if storytelling != null:
			storytelling.apply_campus_presentation(_pinned_parcel_snapshot(
				fresh_snapshot,
				StringName(SECONDARY_PARCEL_PRESENTATION_IDS.get(
					SECONDARY_PARCEL_FIXTURES[0], &""
				)),
			))
		var animated_meshes := _text_meshes(animated_fixture)
		_check(not animated_meshes.is_empty(), "secondary parcel should expose modeled copy for transition coverage", failures)
		if not animated_meshes.is_empty():
			var animated_copy := animated_meshes[0]
			EnvironmentalSignage.set_camera_detail(
				office, true, animated_fixture.global_position, 1.25, true
			)
			_check(animated_copy.visible, "modeled parcel copy should remain present while fading in", failures)
			var fade_in := animated_copy.get_meta(&"detail_visibility_tween", null) as Tween
			_check(fade_in != null, "modeled parcel focus should create a visibility tween", failures)
			if fade_in != null:
				await fade_in.finished
			_check(animated_copy.visible, "modeled parcel copy should be visible after its focus fade", failures)
			_check(
				animated_copy.transparency <= 0.01,
				"modeled parcel copy should finish its focus fade opaque (%.3f)" % animated_copy.transparency,
				failures,
			)
			EnvironmentalSignage.set_camera_detail(
				office, false, Vector3(INF, INF, INF),
				EnvironmentalSignage.FOCUSED_DETAIL_RADIUS, true
			)
			_check(animated_copy.visible, "modeled parcel copy should remain present during its overview fade", failures)
			var fade_out := animated_copy.get_meta(&"detail_visibility_tween", null) as Tween
			_check(fade_out != null, "modeled parcel overview should create a visibility tween", failures)
			if fade_out != null:
				await fade_out.finished
			_check(not animated_copy.visible, "modeled parcel copy should hide only after its overview fade", failures)
			_check(
				animated_copy.transparency >= 0.99,
				"modeled parcel copy should finish its overview fade transparent (%.3f)" % animated_copy.transparency,
				failures,
			)

	# Host geometry is already the sign face. Adding a second panel-sized bed is
	# the perceptual source of the pasted-on UI-card silhouette.
	for fixture_node in get_nodes_in_group(&"environmental_signage"):
		var fixture := fixture_node as Node3D
		if (
			fixture == null
			or not office.is_ancestor_of(fixture)
			or StringName(fixture.get_meta(&"style_family", &"")) != &"beam_letters"
			or not bool(fixture.get_meta(&"host_attached", false))
		):
			continue
		_check(fixture.find_child("BeamLetterBed", false, false) == null, "%s should print into its real beam instead of adding a duplicate BeamLetterBed card" % fixture.name, failures)

	var primary_minimum_fill := INF
	var primary_substrate_blend := INF
	for proxy in major_proxies:
		# Compare utility copy against the landmark heading, not its deliberately
		# subordinate modeled subtitle. Body lines use a smaller fill by design.
		if StringName(proxy.get_meta(&"detail_role", &"heading")) != &"heading":
			continue
		if not proxy.has_meta(&"minimum_height_fill"):
			continue
		primary_minimum_fill = minf(primary_minimum_fill, float(proxy.get_meta(&"minimum_height_fill")))
		_check(proxy.has_meta(&"substrate_blend"), "%s should publish its authored substrate blend" % proxy.name, failures)
		if proxy.has_meta(&"substrate_blend"):
			primary_substrate_blend = minf(primary_substrate_blend, float(proxy.get_meta(&"substrate_blend")))
	_check(is_finite(primary_minimum_fill), "major landmark proxies should publish minimum face-height metadata", failures)
	_check(is_finite(primary_substrate_blend), "major landmark proxies should publish substrate-blend metadata", failures)

	for fixture_name in UTILITY_FIXTURES:
		var fixture := office.find_child(fixture_name, true, false) as Node3D
		_check(fixture != null, "%s should exist as utility copy" % fixture_name, failures)
		if fixture == null:
			continue
		var utility_label := _source_label(fixture)
		_check(utility_label != null, "%s should expose a source utility label" % fixture_name, failures)
		if utility_label == null:
			continue
		_check(StringName(utility_label.get_meta(&"sign_tier", &"")) == &"utility", "%s should remain in the utility tier" % utility_label.name, failures)
		_check(utility_label.has_meta(&"minimum_height_fill"), "%s should publish its minimum face-height" % utility_label.name, failures)
		_check(utility_label.has_meta(&"substrate_blend"), "%s should publish its substrate blend" % utility_label.name, failures)
		if utility_label.has_meta(&"minimum_height_fill") and is_finite(primary_minimum_fill):
			_check(float(utility_label.get_meta(&"minimum_height_fill")) < primary_minimum_fill, "%s utility type should fill less of its face than a primary identity" % utility_label.name, failures)
		if utility_label.has_meta(&"substrate_blend") and is_finite(primary_substrate_blend):
			_check(float(utility_label.get_meta(&"substrate_blend")) >= primary_substrate_blend + 0.10, "%s utility ink should borrow materially more color from its host than a primary identity" % utility_label.name, failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("ENVIRONMENTAL_SIGNAGE_HIERARCHY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("ENVIRONMENTAL_SIGNAGE_HIERARCHY_TEST_PASSED landmarks=%d parcels=%d utilities=%d" % [
		MAJOR_LANDMARK_FIXTURES.size(),
		SECONDARY_PARCEL_FIXTURES.size(),
		UTILITY_FIXTURES.size(),
	])
	quit(0)


func _text_meshes(fixture: Node3D) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for candidate in fixture.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance != null and mesh_instance.mesh is TextMesh:
			meshes.append(mesh_instance)
	return meshes


func _semantic_proxies(fixture: Node3D) -> Array[Label3D]:
	var proxies: Array[Label3D] = []
	for candidate in fixture.find_children("*", "Label3D", true, false):
		var label := candidate as Label3D
		if label != null and bool(label.get_meta(&"dimensional_proxy", false)):
			proxies.append(label)
	return proxies


func _authored_lines(fixture: Node3D) -> PackedStringArray:
	var lines := PackedStringArray()
	for text_mesh in _text_meshes(fixture):
		for line in String((text_mesh.mesh as TextMesh).text).split("\n", false):
			lines.append(line.strip_edges())
	for candidate in fixture.find_children("*", "Label3D", true, false):
		var label := candidate as Label3D
		if label == null:
			continue
		for line in label.text.split("\n", false):
			var authored_line := line.strip_edges()
			if not authored_line.is_empty() and not lines.has(authored_line):
				lines.append(authored_line)
	return lines


func _authored_copy_visible(fixture: Node3D) -> bool:
	for text_mesh in _text_meshes(fixture):
		if text_mesh.is_visible_in_tree():
			return true
	for candidate in fixture.find_children("*", "Label3D", true, false):
		var label := candidate as Label3D
		if (
			label != null
			and not bool(label.get_meta(&"dimensional_proxy", false))
			and label.is_visible_in_tree()
		):
			return true
	return false


func _source_label(fixture: Node3D) -> Label3D:
	for candidate in fixture.find_children("*", "Label3D", true, false):
		var label := candidate as Label3D
		if label != null and StringName(label.get_meta(&"type_role", &"")) != &"letterpress_shadow":
			return label
	return null


func _pinned_parcel_snapshot(snapshot: Dictionary, presentation_id: StringName) -> Dictionary:
	var revealed := snapshot.duplicate(true)
	revealed["pinned_capital_plan_id"] = presentation_id
	revealed["capital_plan"] = {
		"has_pinned_plan": true,
		"pinned_capital_plan_id": presentation_id,
	}
	return revealed


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
