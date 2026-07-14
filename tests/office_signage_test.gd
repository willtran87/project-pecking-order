extends SceneTree


const MIN_PRINT_GAP_METERS := 0.0005
const MAX_PRINT_GAP_METERS := 0.0100


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var fixtures: Array[Node] = []
	var style_families: Dictionary[String, int] = {}
	var primary_fixtures: Array[Node3D] = []
	var valid_tiers: Array[StringName] = [&"primary", &"secondary", &"utility"]
	var valid_styles: Array[StringName] = [
		&"architectural_letters",
		&"bureau_plaque",
		&"room_plaque",
		&"paper_notice",
		&"enamel_plate",
		&"desk_plaque",
		&"partition_insert",
		&"adhesive_label",
		&"surface_stencil",
		&"suspended_notice",
		&"hosted_header",
		&"chart_header",
		&"portrait_masthead",
		&"beam_letters",
		&"screen",
	]
	for candidate in get_nodes_in_group(&"environmental_signage"):
		if candidate is Node and office.is_ancestor_of(candidate as Node):
			fixtures.append(candidate as Node)
	_check(fixtures.size() >= 23, "office should expose a complete mounted signage set (found %d)" % fixtures.size(), failures)

	for fixture in fixtures:
		var fixture_3d := fixture as Node3D
		_check(fixture_3d != null, "%s should be a spatial signage fixture" % fixture.name, failures)
		if fixture_3d == null:
			continue
		var backplate := fixture.find_child("Backplate", false, false) as MeshInstance3D
		var label: Label3D = null
		for child in fixture.get_children():
			if child is Label3D and (child as Label3D).has_meta(&"type_role"):
				label = child as Label3D
				break
		var tier := StringName(fixture.get_meta(&"sign_tier", &""))
		var style_family_name := StringName(fixture.get_meta(&"style_family", &""))
		_check(valid_tiers.has(tier), "%s should use a valid signage tier (found %s)" % [fixture.name, tier], failures)
		_check(valid_styles.has(style_family_name), "%s should use a valid physical style (found %s)" % [fixture.name, style_family_name], failures)
		_check(bool(fixture.get_meta(&"surface_integrated", false)), "%s should declare that its fixture is integrated with a physical surface" % fixture.name, failures)
		if tier == &"primary":
			primary_fixtures.append(fixture_3d)
		var printed_labels := _surface_printed_labels(fixture_3d)
		_check(not printed_labels.is_empty(), "%s should expose its printed surface copy" % fixture.name, failures)
		var printable_face := _printable_face(fixture_3d, style_family_name)
		_check(printable_face != null and printable_face.mesh is BoxMesh, "%s should expose one measurable printable face" % fixture.name, failures)
		if printable_face != null and printable_face.mesh is BoxMesh:
			var printable_box := printable_face.mesh as BoxMesh
			var face_front_z := (
				printable_face.position.z
				+ printable_box.size.z * absf(printable_face.scale.z) * 0.5
			)
			for printed_label in printed_labels:
				_check(bool(printed_label.get_meta(&"surface_printed", false)), "%s should declare that its copy is printed on its fixture" % printed_label.name, failures)
				var print_gap := printed_label.position.z - face_front_z
				_check(
					print_gap >= MIN_PRINT_GAP_METERS and print_gap <= MAX_PRINT_GAP_METERS,
					"%s should sit 0.5-10 mm above %s's printable face (found %.2f mm)" % [printed_label.name, fixture.name, print_gap * 1000.0],
					failures
				)
		var host_integrated := bool(fixture.get_meta(&"physical_host", false))
		var architectural := style_family_name == &"architectural_letters"
		_check(
			(backplate != null and backplate.mesh is BoxMesh) or host_integrated or architectural,
			"%s should have a thin mount, architectural fascia, or declared physical host" % fixture.name,
			failures
		)
		_check(label != null and not label.text.is_empty(), "%s should have printed or screened copy" % fixture.name, failures)
		if label != null:
			_check(label.billboard == BaseMaterial3D.BILLBOARD_DISABLED, "%s must share the mount's perspective" % label.name, failures)
			_check(not label.no_depth_test, "%s must respect walls and furniture depth" % label.name, failures)
			_check(not label.fixed_size, "%s must retain physical world scale" % label.name, failures)
			_check(label.outline_size <= 1, "%s should not use a HUD-style heavy outline" % label.name, failures)
			_check(label.font != null and label.has_meta(&"type_role"), "%s should use the bureau house type system" % label.name, failures)
		_check(fixture.has_meta(&"sign_tier") and fixture.has_meta(&"mount_kind"), "%s should declare its signage hierarchy and mounting" % fixture.name, failures)
		var style_family := String(style_family_name)
		style_families[style_family] = int(style_families.get(style_family, 0)) + 1
		match style_family:
			"architectural_letters":
				_check(fixture.find_child("IdentityFascia", false, false) != null, "%s should be integrated into a laminate architectural fascia" % fixture.name, failures)
				_check(fixture.find_child("BureauEggSeal", false, false) != null, "%s should carry the bureau's dimensional egg seal" % fixture.name, failures)
			"paper_notice":
				_check(fixture.find_child("DocumentIndexTab", false, false) != null, "%s should read as a printed office notice" % fixture.name, failures)
				_check(fixture.find_child("Frame", false, false) == null, "%s should be pinned paper, not a framed card inside another prop" % fixture.name, failures)
				if backplate != null and backplate.mesh is BoxMesh:
					_check((backplate.mesh as BoxMesh).size.z <= 0.012, "%s paper should remain millimetre-thin" % fixture.name, failures)
			"enamel_plate":
				_check(fixture.find_child("EquipmentPlateLip", false, false) != null, "%s should use a slim equipment lip" % fixture.name, failures)
				_check(fixture.find_child("Frame", false, false) == null, "%s should not resemble a framed UI card" % fixture.name, failures)
			"desk_plaque":
				_check(fixture.find_child("PartitionClipLeft", false, false) != null, "%s should clip to its cubicle partition" % fixture.name, failures)
			"partition_insert":
				_check(fixture.find_child("PartitionRailTop", false, false) != null, "%s should slide into a cubicle rail" % fixture.name, failures)
				_check(fixture.find_child("Frame", false, false) == null, "%s should be office furniture, not a ceremonial plaque" % fixture.name, failures)
				_check(bool(fixture.get_meta(&"fixture_detail_only", false)), "%s should disappear as a whole when too small to read" % fixture.name, failures)
			"adhesive_label":
				_check(fixture.find_child("AdhesiveShadow", false, false) != null, "%s should read as a glued shipping label" % fixture.name, failures)
				_check(bool(fixture.get_meta(&"fixture_detail_only", false)), "%s should not leave an empty card at overview" % fixture.name, failures)
				if backplate != null and backplate.mesh is BoxMesh:
					_check((backplate.mesh as BoxMesh).size.z <= 0.004, "%s should be paper-thin" % fixture.name, failures)
			"surface_stencil":
				_check(host_integrated, "%s should inherit the object it is painted on" % fixture.name, failures)
				_check(fixture.find_child("StencilRegistrationTick", false, false) != null, "%s should expose a restrained painted registration mark" % fixture.name, failures)
				_check(fixture.find_child("Frame", false, false) == null, "%s should have no card silhouette" % fixture.name, failures)
			"screen":
				_check(fixture.find_child("ScreenStatusLamp", false, false) != null, "%s should have a physical monitor status lamp" % fixture.name, failures)
			"hosted_header":
				_check(host_integrated, "%s should explicitly inherit its physical host" % fixture.name, failures)
				_check(backplate == null, "%s should not add a second card over its host" % fixture.name, failures)
				_check(fixture.find_child("HostHeaderRule", false, false) != null, "%s should use a silk-screened host rule" % fixture.name, failures)

	for required_style in [
		"architectural_letters", "chart_header", "portrait_masthead", "beam_letters",
		"paper_notice", "enamel_plate", "partition_insert", "adhesive_label",
		"surface_stencil", "screen",
	]:
		_check(style_families.has(required_style), "signage system should include the %s mounting family" % required_style, failures)
	_check(primary_fixtures.size() == 1, "office should have exactly one primary identity landmark (found %d)" % primary_fixtures.size(), failures)
	if primary_fixtures.size() == 1:
		var primary_identity := primary_fixtures[0]
		_check(primary_identity.name == &"BureauIdentityFixture", "the sole primary landmark should be BureauIdentityFixture", failures)
		_check(StringName(primary_identity.get_meta(&"style_family", &"")) == &"architectural_letters", "the primary bureau identity should be architectural lettering", failures)
		_check(bool(primary_identity.get_meta(&"overview_anchor", false)), "the primary bureau identity should remain an overview landmark", failures)

	var hosted_relationships: Dictionary[String, Dictionary] = {
		"ClaimsPipelineLabelFixture": {"host": "ClaimsPipelineBoard", "style": &"chart_header", "face": "HostPrintField"},
		"HenOfMonthLabelFixture": {"host": "HenOfMonthFrame", "style": &"portrait_masthead", "face": "PortraitTitleMat"},
		"PerchTitleFixture": {"host": "PerchDepartmentHeaderBeam", "style": &"beam_letters", "face": "BeamLetterBed"},
	}
	for fixture_name in hosted_relationships:
		var hosted_fixture := office.find_child(fixture_name, true, false) as Node3D
		var relationship := hosted_relationships[fixture_name]
		var expected_host_name := String(relationship.get("host", ""))
		var expected_host := office.find_child(expected_host_name, true, false) as MeshInstance3D
		_check(hosted_fixture != null, "%s should exist as a hosted sign fixture" % fixture_name, failures)
		_check(expected_host != null, "%s should exist as %s's explicit physical host" % [expected_host_name, fixture_name], failures)
		if hosted_fixture != null and expected_host != null:
			_check(StringName(hosted_fixture.get_meta(&"style_family", &"")) == StringName(relationship.get("style", &"")), "%s should use its host-specific treatment" % fixture_name, failures)
			_check(bool(hosted_fixture.get_meta(&"physical_host", false)), "%s should declare its physical-host relationship" % fixture_name, failures)
			_check(hosted_fixture.get_parent() == expected_host.get_parent(), "%s and %s should belong to the same authored prop cluster" % [fixture_name, expected_host_name], failures)
			_check(hosted_fixture.global_position.distance_to(expected_host.global_position) <= 1.25, "%s should remain attached to the surface of %s" % [fixture_name, expected_host_name], failures)
			_check(hosted_fixture.find_child(String(relationship.get("face", "")), false, false) != null, "%s should expose its own printable host face" % fixture_name, failures)

	# Labels that describe a specific prop must inherit that prop's transform.
	# This catches the perceptual failure the old style metadata could not: copy
	# could claim to be integrated while hovering centimetres in front of a prop,
	# or remain level while its shipping carton rotated beneath it.
	var directly_attached_hosts: Dictionary[String, String] = {
		"PresentationPlaqueTextFixture": "BasketFrontSlatCreditHost",
		"ShellIntegrityLabelFixture": "ShellIntegrityGate",
		"SuggestionBoxLabelFixture": "OpenBeakSuggestionBox",
		"ArchiveRetentionLabelFixture": "ArchiveHeaderBeam",
		"ClutchSurplusMarker": "EggCollectionCartBasket",
	}
	for fixture_name in directly_attached_hosts:
		var attached_fixture := office.find_child(fixture_name, true, false) as Node3D
		var expected_host_name := directly_attached_hosts[fixture_name]
		var actual_host := attached_fixture.get_parent() as MeshInstance3D if attached_fixture != null else null
		_check(attached_fixture != null, "%s should exist as host-attached copy" % fixture_name, failures)
		_check(actual_host != null and String(actual_host.name).begins_with(expected_host_name), "%s should be parented directly to %s (found %s)" % [fixture_name, expected_host_name, String(actual_host.name) if actual_host != null else "none"], failures)
		_check(attached_fixture != null and bool(attached_fixture.get_meta(&"host_attached", false)), "%s should declare a real host attachment" % fixture_name, failures)
	for capacity_index in 6:
		var capacity_fixture := office.find_child("CapacityNotice_%02dFixture" % capacity_index, true, false) as Node3D
		var carton_host := capacity_fixture.get_parent() as MeshInstance3D if capacity_fixture != null else null
		_check(carton_host != null and carton_host.name == "BoxedPerch_%02d" % capacity_index, "capacity label %d should inherit its rotated carton" % capacity_index, failures)
		_check(capacity_fixture != null and bool(capacity_fixture.get_meta(&"host_attached", false)), "capacity label %d should declare a real host attachment" % capacity_index, failures)

	var all_world_labels := office.find_children("*", "Label3D", true, false)
	for label_node in all_world_labels:
		var label := label_node as Label3D
		_check(_has_sign_ancestor(label, office), "%s is raw floating text instead of mounted signage" % label.name, failures)

	_check(office.find_children("EmployeeNameplateTextFixture", "Node3D", true, false).size() == 6, "all six desk names should be mounted", failures)
	_check(office.find_children("StatusLabel", "Label3D", true, false).is_empty(), "worker metrics should live in the inspection ticker, not float over hens", failures)
	_check(office.find_child("CollectionChainLabel", true, false) == null, "collection flow should be communicated by machinery instead of floating copy", failures)
	var zone_root := office.find_child("FarmBureauZoneMarkers", true, false)
	_check(zone_root != null and zone_root.find_children("*", "Label3D", true, false).is_empty(), "floor zones should use physical markings rather than floating captions", failures)

	var motto := office.find_child("BureauIdentity", true, false) as Label3D
	var identity_fixture := office.find_child("BureauIdentityFixture", true, false) as Node3D
	var side_board := office.find_child("ClaimsPipelineLabelFixture", true, false) as Node3D
	var metrics := office.find_child("ManagementYieldBoard", true, false) as Label3D
	var wellness_fixture := office.find_child("WellnessZoneLabelFixture", true, false) as Node3D
	var identity_subtitle := office.find_child("BureauIdentitySubtitle", true, false) as Label3D
	var desk_copy := office.find_child("EmployeeNameplateText", true, false) as Label3D
	var desk_fixture := office.find_child("EmployeeNameplateTextFixture", true, false) as Node3D
	var desk_role := office.find_child("EmployeeNameplateTextBody", true, false) as Label3D
	var document_heading := office.find_child("FreeRangePermitLabel", true, false) as Label3D
	var document_body := office.find_child("FreeRangePermitLabelBody", true, false) as Label3D
	_check(motto != null and motto.billboard == BaseMaterial3D.BILLBOARD_DISABLED, "bureau identity should be fixed to the back wall", failures)
	_check(identity_fixture != null and identity_fixture.position.z <= -8.60, "bureau identity should sit against the architectural wall rail", failures)
	_check(identity_fixture != null and identity_fixture.find_child("IdentityInset", false, false) != null, "bureau identity should reserve a high-contrast architectural inset", failures)
	_check(identity_fixture != null and (identity_fixture.get_meta(&"panel_size", Vector2.ZERO) as Vector2).x >= 6.0, "bureau identity should remain the room's readable landmark", failures)
	_check(motto != null and identity_subtitle != null and motto.pixel_size > identity_subtitle.pixel_size * 1.7, "bureau title should dominate its subordinate department line", failures)
	_check(side_board != null and is_equal_approx(absf(side_board.rotation_degrees.y), 90.0), "left-wall pipeline heading should face into the room", failures)
	_check(side_board != null and bool(side_board.get_meta(&"physical_host", false)), "pipeline heading should inherit the existing visibility board", failures)
	_check(side_board != null and side_board.find_child("HostPrintField", false, false) != null, "pipeline title should print into the chart field instead of using a generic UI tab", failures)
	_check(metrics != null and String(metrics.get_parent().get_meta(&"mount_kind", &"")) == "screen", "live yield metrics should live on a monitor", failures)
	_check(metrics != null and metrics.position.x < -1.0, "left-aligned screen copy should begin at the glass inset instead of its center", failures)
	_check(_font_source_path(motto).ends_with("BarlowCondensed-SemiBold.fontbytes"), "architectural identity should use the authored institutional face", failures)
	_check(_font_source_path(metrics).ends_with("IBMPlexMono-Regular.fontbytes"), "live screens should use the authored ledger mono face", failures)
	_check(_font_source_path(document_heading).ends_with("CourierPrime-Bold.fontbytes"), "paper headings should use the authored typewriter bold face", failures)
	_check(_font_source_path(document_body).ends_with("CourierPrime-Regular.fontbytes"), "paper body copy should use the authored typewriter face", failures)
	_check(_font_source_path(desk_copy).ends_with("BarlowCondensed-SemiBold.fontbytes"), "desk names should use engraved institutional caps", failures)
	_check(_font_source_path(desk_role).ends_with("BarlowCondensed-Regular.fontbytes"), "desk roles should use a quieter authored face", failures)
	_check(wellness_fixture != null and wellness_fixture.position.x <= -11.75 and is_equal_approx(absf(wellness_fixture.rotation_degrees.y), 90.0), "wellness notice should sit flush on the left wall instead of floating inside the room", failures)
	_check(wellness_fixture != null and not wellness_fixture.visible, "overview should not leave a blank room plaque after its copy recedes", failures)
	_check(office.find_child("BureauBulletinBoard", true, false) != null, "small policy jokes should cluster on a physical bulletin board", failures)
	_check(office.find_child("IntakeLedgerSupport", true, false) != null, "the intake ledger should be physically supported by the counter", failures)
	_check(office.find_children("SuspensionRod*", "MeshInstance3D", true, false).is_empty(), "department and event signs should not hang from rods connected to nothing", failures)
	_check(office.find_child("CreditPlaque", true, false) == null and office.find_child("CoopSafetyFrame", true, false) == null, "sign fixtures should not duplicate prebuilt backing geometry", failures)
	_check(desk_copy != null and not desk_copy.visible, "overview should suppress sub-pixel desk lettering", failures)
	_check(desk_fixture != null and not desk_fixture.visible, "overview should suppress the whole removable desk insert instead of leaving a blank card", failures)
	_check(document_body != null and not document_body.visible, "overview should suppress document microcopy while retaining notice headings", failures)
	_check(motto != null and motto.visible, "overview should retain the bureau landmark", failures)
	# Preserve the original all-detail contract for callers that do not provide a
	# spatial focus point. This remains useful for authored close-view captures.
	EnvironmentalSignage.set_camera_detail(office, true, Vector3(INF, INF, INF), EnvironmentalSignage.FOCUSED_DETAIL_RADIUS, false)
	_check(desk_copy != null and desk_copy.visible, "legacy all-detail focus should reveal desk lettering", failures)
	_check(desk_fixture != null and desk_fixture.visible, "legacy all-detail focus should reveal the physical desk insert", failures)
	_check(document_body != null and document_body.visible, "legacy all-detail focus should reveal document body copy", failures)
	EnvironmentalSignage.set_camera_detail(office, false, Vector3(INF, INF, INF), EnvironmentalSignage.FOCUSED_DETAIL_RADIUS, false)
	# Normal gameplay focus is spatial: nearby fine print should appear without
	# switching on every nameplate and memo elsewhere in the office.
	if document_body != null:
		var desk_labels := _printed_labels_for_style(fixtures, &"partition_insert")
		var paper_body_labels := _printed_labels_for_style(fixtures, &"paper_notice", &"body")
		var remote_desk := _farthest_label_from(document_body.global_position, desk_labels)
		var remote_paper := _farthest_label_from(document_body.global_position, paper_body_labels, document_body)
		var spatial_detail_radius := 1.25
		_check(remote_desk != null and remote_desk.global_position.distance_to(document_body.global_position) > spatial_detail_radius, "spatial-focus fixture should include a genuinely remote desk detail", failures)
		_check(remote_paper != null and remote_paper.global_position.distance_to(document_body.global_position) > spatial_detail_radius, "spatial-focus fixture should include a genuinely remote paper detail", failures)
		EnvironmentalSignage.set_camera_detail(
			office, true, document_body.global_position, spatial_detail_radius, false
		)
		_check(document_body.visible, "spatial focus should reveal nearby document detail", failures)
		_check(remote_desk != null and not remote_desk.visible, "spatial focus should keep remote desk lettering hidden", failures)
		_check(remote_paper != null and not remote_paper.visible, "spatial focus should keep remote paper detail hidden", failures)
		EnvironmentalSignage.set_camera_detail(office, false, Vector3(INF, INF, INF), EnvironmentalSignage.FOCUSED_DETAIL_RADIUS, false)
	var bulletin := office.find_child("BureauBulletinBoard", true, false) as Node3D
	var bulletin_frame := bulletin.find_child("BulletinBoardFrame", false, false) as MeshInstance3D if bulletin != null else null
	_check(bulletin != null and bulletin.position.x <= -11.69, "bulletin board should mount against the wall instead of hovering in front of it", failures)
	_check(bulletin_frame != null and bulletin_frame.mesh is BoxMesh and (bulletin_frame.mesh as BoxMesh).size.x <= 3.60, "bulletin cluster should leave breathing room between adjacent wall zones", failures)
	var identity_light_arms := office.find_children("IdentityLightArm*", "MeshInstance3D", true, false)
	_check(identity_light_arms.size() == 2, "center picture light should visibly clamp to the bureau fascia (found %d)" % identity_light_arms.size(), failures)
	for capacity_index in [4, 5]:
		var capacity_fixture := office.find_child("CapacityNotice_%02dFixture" % capacity_index, true, false) as Node3D
		_check(capacity_fixture != null and StringName(capacity_fixture.get_meta(&"style_family", &"")) == &"adhesive_label", "pending perch copy should be a glued shipping label on its crate", failures)
	var paper_fixture := office.find_child("FreeRangePermitLabelFixture", true, false) as Node3D
	var paper_shadow := paper_fixture.find_child("PaperContactShadow", false, false) as MeshInstance3D if paper_fixture != null else null
	var paper_face := paper_fixture.find_child("Backplate", false, false) as MeshInstance3D if paper_fixture != null else null
	if paper_shadow != null and paper_face != null and paper_shadow.mesh is BoxMesh and paper_face.mesh is BoxMesh:
		var shadow_size := (paper_shadow.mesh as BoxMesh).size
		var face_size := (paper_face.mesh as BoxMesh).size
		_check(shadow_size.x - face_size.x <= 0.012 and shadow_size.y - face_size.y <= 0.012, "paper contact shadow should be a narrow attachment cue, not a card frame", failures)
		_check(absf(paper_shadow.position.x) <= 0.004 and absf(paper_shadow.position.y) <= 0.004, "paper contact shadow should remain tight to the sheet", failures)
		_check(paper_shadow.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "decorative paper contact ink should not cast a second physical shadow", failures)
	else:
		_check(false, "paper notice should expose measurable face and contact shadow geometry", failures)
	if metrics != null:
		var screen_fixture := metrics.get_parent() as Node3D
		for decoration_name in ["ScreenHeaderRail", "ScreenScanline"]:
			for decoration_candidate in screen_fixture.find_children(decoration_name, "MeshInstance3D", false, false):
				var decoration := decoration_candidate as MeshInstance3D
				if decoration.mesh is BoxMesh:
					var decoration_front := decoration.position.z + (decoration.mesh as BoxMesh).size.z * 0.5
					_check(decoration_front <= metrics.position.z - 0.0005, "%s should remain behind the live glyph plane" % decoration.name, failures)
	var identity_rail := office.find_child("FasciaTopRail", true, false) as MeshInstance3D
	var rail_material := identity_rail.material_override as StandardMaterial3D if identity_rail != null else null
	_check(rail_material != null and rail_material.metallic > 0.0 and rail_material.metallic < 1.0, "brass trim should retain nuanced fractional metal response", failures)
	if metrics != null:
		var original_pixel_size := metrics.pixel_size
		metrics.text = "FLOCKWATCH / EXTRAORDINARILY LONG LIVE YIELD ACCOUNTING FIELD\nDAY 999 / REPORTING PERIOD 999\nCLUTCH 9999 / 9999\nPECKWORK QUEUE 9999"
		EnvironmentalSignage.refit_label(metrics)
		_check(metrics.pixel_size < original_pixel_size, "dynamic screen copy should shrink to remain inside its glass", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("OFFICE_SIGNAGE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OFFICE_SIGNAGE_TEST_PASSED fixtures=%d floating=0 hierarchy=mounted" % fixtures.size())
	quit(0)


func _has_sign_ancestor(label: Label3D, office: Node) -> bool:
	var cursor := label.get_parent()
	while cursor != null and cursor != office:
		if cursor.is_in_group(&"environmental_signage"):
			return true
		cursor = cursor.get_parent()
	return false


func _font_source_path(label: Label3D) -> String:
	if label == null or not (label.font is FontVariation):
		return ""
	var variation := label.font as FontVariation
	return String(variation.base_font.get_meta(&"authored_source_path", "")) if variation.base_font != null else ""


func _surface_printed_labels(fixture: Node3D) -> Array[Label3D]:
	var labels: Array[Label3D] = []
	for child in fixture.get_children():
		if child is Label3D and bool((child as Label3D).get_meta(&"environmental_copy", false)):
			labels.append(child as Label3D)
	return labels


func _printable_face(fixture: Node3D, style_family: StringName) -> MeshInstance3D:
	var face_name := &"Backplate"
	if style_family == &"architectural_letters":
		face_name = &"IdentityInset"
	elif style_family == &"hosted_header":
		face_name = &"HostHeaderBand"
	elif style_family == &"chart_header":
		face_name = &"HostPrintField"
	elif style_family == &"portrait_masthead":
		face_name = &"PortraitTitleMat"
	elif style_family == &"beam_letters":
		face_name = &"BeamLetterBed"
	return fixture.find_child(face_name, false, false) as MeshInstance3D


func _printed_labels_for_style(
	fixtures: Array[Node],
	style_family: StringName,
	detail_role: StringName = &""
) -> Array[Label3D]:
	var labels: Array[Label3D] = []
	for fixture_node in fixtures:
		var fixture := fixture_node as Node3D
		if fixture == null or StringName(fixture.get_meta(&"style_family", &"")) != style_family:
			continue
		for printed_label in _surface_printed_labels(fixture):
			if detail_role == &"" or StringName(printed_label.get_meta(&"detail_role", &"")) == detail_role:
				labels.append(printed_label)
	return labels


func _farthest_label_from(
	origin: Vector3,
	labels: Array[Label3D],
	excluded_label: Label3D = null
) -> Label3D:
	var farthest_label: Label3D = null
	var farthest_distance_squared := -1.0
	for label in labels:
		if label == excluded_label:
			continue
		var distance_squared := label.global_position.distance_squared_to(origin)
		if distance_squared > farthest_distance_squared:
			farthest_label = label
			farthest_distance_squared = distance_squared
	return farthest_label


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
