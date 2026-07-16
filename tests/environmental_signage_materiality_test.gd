extends SceneTree

## Art-direction contract for world-space office copy. The broader signage tests
## cover attachment and fitting; this suite protects the visible material split
## between paperwork, cubicle furniture, equipment enamel, and live glass.


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var paper := office.find_child("FreeRangePermitLabelFixture", true, false) as Node3D
	var cubicle := office.find_child("EmployeeNameplateTextFixture", true, false) as Node3D
	var enamel := office.find_child("ShellIntegrityLabelFixture", true, false) as Node3D
	var live_label := office.find_child("ManagementYieldBoard", true, false) as Label3D
	var live_screen := live_label.get_parent() as Node3D if live_label != null else null
	var bureau := office.find_child("BureauIdentityFixture", true, false) as Node3D

	_check(paper != null, "paper notice exemplar should exist", failures)
	_check(cubicle != null, "cubicle insert exemplar should exist", failures)
	_check(enamel != null, "equipment enamel exemplar should exist", failures)
	_check(live_screen != null, "live screen exemplar should exist", failures)
	_check(bureau != null, "architectural Bureau identity should exist", failures)

	if paper != null:
		_check(StringName(paper.get_meta(&"style_family", &"")) == &"paper_notice", "policy notice should retain the paper family", failures)
		_check(paper.find_child("PaperContactShadow", false, false) != null, "paper should retain a tight contact shadow", failures)
		_check(paper.find_child("PaperTape", false, false) != null, "paper should retain an imperfect physical tape mount", failures)
		_check(paper.find_child("MountFastener", false, false) != null, "paper should retain a physical tack", failures)
		var paper_face := paper.find_child("Backplate", false, false) as MeshInstance3D
		_check(_box_depth(paper_face) <= 0.004, "paper face should remain millimetre-thin", failures)
		_check(_surface_near_fixture(paper, paper_face, 0.08), "paper face should stay near its warm physical substrate while retaining sheet-to-sheet variation", failures)
		var authored_paper := paper.get_meta(&"authored_panel_color", Color.BLACK) as Color
		var physical_paper := paper.get_meta(&"physical_substrate_color", Color.BLACK) as Color
		_check(physical_paper.get_luminance() >= authored_paper.get_luminance() - 0.08, "paper normalization should preserve a warm legible form stock", failures)

	if cubicle != null:
		_check(StringName(cubicle.get_meta(&"style_family", &"")) == &"partition_insert", "employee identity should remain cubicle stationery", failures)
		_check(cubicle.find_child("PartitionRailTop", false, false) != null, "cubicle insert should slide into a top memo rail", failures)
		_check(cubicle.find_child("PartitionRailBottom", false, false) != null, "cubicle insert should slide into a bottom memo rail", failures)
		_check(cubicle.find_child("PartitionInsertShadow", false, false) != null, "cubicle insert should retain a contact shadow", failures)
		var cubicle_face := cubicle.find_child("Backplate", false, false) as MeshInstance3D
		_check(_surface_matches_fixture(cubicle, cubicle_face), "cubicle face material should match its physical stationery substrate", failures)
		var authored_cubicle := cubicle.get_meta(&"authored_panel_color", Color.BLACK) as Color
		var physical_cubicle := cubicle.get_meta(&"physical_substrate_color", Color.BLACK) as Color
		_check(physical_cubicle.get_luminance() >= authored_cubicle.get_luminance() + 0.12, "cubicle stationery should be materially lighter than the former dark-card accent", failures)
		var cubicle_heading := cubicle.find_child("EmployeeNameplateText", false, false) as Label3D
		_check(cubicle_heading != null and float(cubicle_heading.get_meta(&"ink_luminance_separation", 0.0)) >= 0.16, "employee name should retain pigment separation from its paper insert", failures)

	if enamel != null:
		_check(StringName(enamel.get_meta(&"style_family", &"")) == &"enamel_plate", "grading hardware should retain the enamel family", failures)
		_check(enamel.find_child("EquipmentPlateLip", false, false) != null, "equipment plate should retain a rolled outer lip", failures)
		_check(enamel.find_child("EquipmentPlateRollTop", false, false) != null, "equipment plate should catch light on its top rolled edge", failures)
		_check(enamel.find_child("EquipmentPlateRollBottom", false, false) != null, "equipment plate should retain a shaded bottom rolled edge", failures)
		_check(_direct_mesh_count(enamel, "CylinderMesh") >= 2, "equipment plate should use two physical screws", failures)
		var enamel_face := enamel.find_child("Backplate", false, false) as MeshInstance3D
		_check(_surface_matches_fixture(enamel, enamel_face), "enamel face should match its desaturated machine substrate", failures)
		var authored_enamel := enamel.get_meta(&"authored_panel_color", Color.BLACK) as Color
		var physical_enamel := enamel.get_meta(&"physical_substrate_color", Color.BLACK) as Color
		_check(not physical_enamel.is_equal_approx(authored_enamel), "machine enamel should age the departmental accent instead of becoming another screen card", failures)

	if live_screen != null:
		_check(StringName(live_screen.get_meta(&"style_family", &"")) == &"screen", "yield data should remain live glass", failures)
		_check(live_screen.find_child("Frame", false, false) != null, "live glass should remain inside monitor hardware", failures)
		_check(live_screen.find_child("ScreenStatusLamp", false, false) != null, "live glass should retain its status lamp", failures)
		var screen_face := live_screen.find_child("Backplate", false, false) as MeshInstance3D
		var screen_material := screen_face.material_override as StandardMaterial3D if screen_face != null else null
		_check(screen_material != null and screen_material.emission_enabled, "live glass should remain softly emissive", failures)
		var authored_screen := live_screen.get_meta(&"authored_panel_color", Color.BLACK) as Color
		var physical_screen := live_screen.get_meta(&"physical_substrate_color", Color.WHITE) as Color
		_check(physical_screen.is_equal_approx(authored_screen), "live glass should preserve its authored display color", failures)

	if bureau != null:
		var subtitle := bureau.find_child("BureauIdentitySubtitleModeledType", false, false) as MeshInstance3D
		var subtitle_mesh := subtitle.mesh as TextMesh if subtitle != null else null
		_check(subtitle_mesh != null, "Bureau department line should use modeled physical type", failures)
		_check(subtitle_mesh != null and subtitle_mesh.depth >= 0.007, "Bureau department line should retain readable letter depth", failures)
		_check(subtitle != null and (subtitle.get_meta(&"maximum_text_size", Vector2.ZERO) as Vector2).y >= 0.11, "Bureau department line should occupy a legible riveted strip", failures)

	var protected_fields := 0
	for fixture_node in get_nodes_in_group(&"environmental_signage"):
		var fixture := fixture_node as Node3D
		if fixture == null or not office.is_ancestor_of(fixture):
			continue
		if StringName(fixture.get_meta(&"style_family", &"")) == &"architectural_letters":
			continue
		var panel_size := fixture.get_meta(&"panel_size", Vector2.ZERO) as Vector2
		for child in fixture.get_children():
			var label := child as Label3D
			if label == null or not label.has_meta(&"text_area_size"):
				continue
			var field := label.get_meta(&"text_area_size", Vector2.ZERO) as Vector2
			protected_fields += 1
			_check(field.x <= panel_size.x * 0.87 + 0.002, "%s should preserve side margins for rails, clips, and screws" % label.name, failures)
			_check(field.y <= panel_size.y * 0.80 + 0.002, "%s should preserve top/bottom material around the print" % label.name, failures)
	_check(protected_fields >= 100, "materiality contract should inspect the complete environmental print set", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("ENVIRONMENTAL_SIGNAGE_MATERIALITY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("ENVIRONMENTAL_SIGNAGE_MATERIALITY_TEST_PASSED fields=%d paper=warm cubicle=stationery enamel=rolled screen=live" % protected_fields)
	quit(0)


func _box_depth(instance: MeshInstance3D) -> float:
	if instance == null or not (instance.mesh is BoxMesh):
		return INF
	return (instance.mesh as BoxMesh).size.z * absf(instance.scale.z)


func _surface_matches_fixture(fixture: Node3D, face: MeshInstance3D) -> bool:
	if face == null or not (face.material_override is StandardMaterial3D):
		return false
	var material := face.material_override as StandardMaterial3D
	var expected := fixture.get_meta(&"physical_substrate_color", Color.TRANSPARENT) as Color
	return material.albedo_color.is_equal_approx(expected)


func _surface_near_fixture(
	fixture: Node3D,
	face: MeshInstance3D,
	maximum_channel_delta: float,
) -> bool:
	if face == null or not (face.material_override is StandardMaterial3D):
		return false
	var material := face.material_override as StandardMaterial3D
	var expected := fixture.get_meta(&"physical_substrate_color", Color.TRANSPARENT) as Color
	var actual := material.albedo_color
	return (
		absf(actual.r - expected.r) <= maximum_channel_delta
		and absf(actual.g - expected.g) <= maximum_channel_delta
		and absf(actual.b - expected.b) <= maximum_channel_delta
	)


func _direct_mesh_count(parent: Node, mesh_class: String) -> int:
	var count := 0
	for child in parent.get_children():
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		if mesh_class == "CylinderMesh" and mesh_instance.mesh is CylinderMesh:
			count += 1
	return count


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
