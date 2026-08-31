extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame

	var required_details := [
		"BureauIdentity",
		"IdentityFascia",
		"OfficeClockFace",
		"ClaimsPipelineBoard",
		"BreakroomKitchenCounter",
		"BreakroomCoffeeUrn",
		"BreakroomMicrowave",
		"BreakroomSofaSeat",
		"BreakroomSideTable",
		"BreakroomCorkboard",
		"CopierOutputTray",
		"ArchiveBox",
		"SafetyExtinguisher",
		"IntakeClaimBundle",
		"IntakeServiceBell",
		"EggScaleBase",
		"CandlingLamp",
		"BasketFrontSlat",
		"BasketHandle",
		"PresentationPlaqueTextFixture",
		"OpeningWestOfficeFurnishings",
		"WestFlexSupplyCabinet",
		"WestFlexMailTable",
		"WestFlexFileCart",
		"WestFlexCoatStand",
		"WestFlexProjectStation",
		"WestFlexProjectTable",
		"WestFlexPlanningBoard",
		"WestVisitorOfficeNook",
		"WestVisitorBench",
		"WestVisitorFileCredenza",
		"WestVisitorWallRecords",
	]
	for detail_name in required_details:
		_check(office.find_child(detail_name, true, false) != null, "office should include %s" % detail_name, failures)
	var breakroom := office.find_child("BaselineBreakroom", true, false)
	_check(
		breakroom != null
		and bool(breakroom.get_meta(&"visual_only", false))
		and bool(breakroom.get_meta(&"collision_free", false))
		and bool(breakroom.get_meta(&"navigation_free", false))
		and bool(breakroom.get_meta(&"wellness_routes_clear", false)),
		"baseline breakroom should remain visual-only and preserve wellness routes",
		failures,
	)
	_check(
		office.find_children("BreakroomPinnedNote_*", "MeshInstance3D", true, false).size() >= 4,
		"breakroom corkboard should carry communal visual storytelling",
		failures,
	)
	_check(office.find_children("BreakroomRugWeave_*", "MeshInstance3D", true, false).size() == 5, "breakroom rug should include a woven inset pattern", failures)
	_check(office.find_children("BreakroomCorkboardFrame*", "MeshInstance3D", true, false).size() >= 4, "communal board should have a dimensional wood frame", failures)
	_check(office.find_children("BreakroomMug_*", "MeshInstance3D", true, false).size() == 3, "coffee shelf should include three distinct mugs", failures)
	_check(office.find_children("BreakroomPlantLeaf_*", "MeshInstance3D", true, false).size() >= 5, "breakroom should include soft plant detail", failures)
	_check(office.find_children("BreakroomSconceGlow_*", "MeshInstance3D", true, false).size() == 2, "breakroom should have a warm authored lighting silhouette", failures)
	_check(office.find_children("BreakroomCoolerBubble_*", "MeshInstance3D", true, false).size() == 4, "water cooler should expose ambient liquid life", failures)
	_check(office.find_children("BreakroomCoffeeSteam_*", "MeshInstance3D", true, false).size() == 3, "coffee station should expose responsive steam visuals", failures)
	_check(office.find_child("BreakroomThrowBlanket", true, false) != null, "lounge should include layered upholstery detail", failures)
	_check(office.find_child("BreakroomTableCup", true, false) != null, "cafe table should include a grounded personal prop", failures)
	var opening_west_furnishings := office.find_child("OpeningWestOfficeFurnishings", true, false)
	_check(
		opening_west_furnishings != null
		and bool(opening_west_furnishings.get_meta(&"visual_only", false))
		and bool(opening_west_furnishings.get_meta(&"collision_free", false))
		and bool(opening_west_furnishings.get_meta(&"navigation_free", false))
		and bool(opening_west_furnishings.get_meta(&"persistent_across_shifts", false))
		and int(opening_west_furnishings.get_meta(&"retired_at_capacity", 0)) == -1,
		"west records and visitor furnishings should remain persistent visual-only office staging",
		failures,
	)
	var second_perch_flex := office.find_child("WestSecondPerchFlexFurnishings", true, false)
	_check(
		second_perch_flex != null
		and bool(second_perch_flex.get_meta(&"visual_only", false))
		and int(second_perch_flex.get_meta(&"converted_at_capacity", -1)) == 6,
		"only the sixth-perch footprint should be marked as convertible furnishing space",
		failures,
	)
	_check(office.find_children("WestFlexBinder_*", "MeshInstance3D", true, false).size() == 7, "west supply cabinet should carry a readable binder run", failures)
	_check(office.find_children("WestFlexMailSorterDivider_*", "MeshInstance3D", true, false).size() == 5, "west mail table should expose six pigeonholes", failures)
	_check(office.find_children("WestFlexMailPacket_*", "MeshInstance3D", true, false).size() == 6, "west sorter contents should remain legible from the management camera", failures)
	_check(office.find_children("WestFlexFileCartCaster_*", "MeshInstance3D", true, false).size() == 4, "west file cart should have a grounded mobile silhouette", failures)
	_check(office.find_children("WestFlexProjectStoolSeat_*", "MeshInstance3D", true, false).size() == 2, "west project station should include two recognizable task stools", failures)
	_check(office.find_children("WestFlexPlanningCard_*", "MeshInstance3D", true, false).size() == 7, "west planning board should communicate active work without extra prose", failures)
	_check(office.find_children("WestFlexProjectPlanGrid_*", "MeshInstance3D", true, false).size() == 4, "west project table should expose readable plan detail", failures)
	_check(office.find_children("WestVisitorBenchCushion_*", "MeshInstance3D", true, false).size() == 2, "west wall should include recognizable visitor seating", failures)
	_check(office.find_children("WestVisitorFileDrawer_*", "MeshInstance3D", true, false).size() == 2, "west visitor nook should include lateral office files", failures)
	_check(office.find_children("WestVisitorWallRecord_*", "MeshInstance3D", true, false).size() == 6, "west wall records should add visual activity without more instructional copy", failures)
	_check(office.find_children("WestVisitorFormsPacket_*", "MeshInstance3D", true, false).size() == 3, "west wall should include a stocked forms rack", failures)

	_check(office.find_children("WindowMullion*", "MeshInstance3D", true, false).size() == 6, "every window should have a center mullion", failures)
	_check(office.find_children("Radiator_*", "MeshInstance3D", true, false).size() == 6, "every window bay should have modeled lower-wall depth", failures)
	_check(office.find_children("WallLightLens*", "MeshInstance3D", true, false).size() == 3, "office should include three wall light fixtures", failures)
	_check(office.find_children("PresentationEgg*", "MeshInstance3D", true, false).is_empty(), "farmer basket should start without decorative fake eggs", failures)
	_check(office.find_children("AuthoritativeClutchSlot_*", "Node3D", true, false).size() == 36, "farmer presentation should expose the authoritative living-clutch cups", failures)
	var window_pastures := office.find_children("WindowPasture*", "MeshInstance3D", true, false)
	_check(window_pastures.size() == 6, "every window should show the farm beyond the office (found %d)" % window_pastures.size(), failures)
	_check(office.find_children("EmployeeNameplateTextFixture", "Node3D", true, false).size() == 6, "every workstation should have a physically mounted nameplate", failures)
	var structural_shadow_names := [
		"CubicleBack", "CubicleWing_L", "DeskSurface", "DrawerPedestal",
		"Monitor", "ChairSeat",
	]
	var cosmetic_shadow_names := [
		"ClaimFile_0", "ClaimTray", "CoffeeMug", "DeskMat", "DeskPhone",
		"DrawerHandle_0", "Keyboard", "Memo_A", "Memo_B", "PhoneReceiver",
		"Screen", "ScreenAlert", "ScreenHeader", "ScreenLine_0", "UrgentTab",
		"ChickPhotoFrame", "ChickPhoto", "ChickPortrait", "PencilCup", "Pencil",
		"DeskPlantPot", "DeskPlantLeaf", "FeedSnackPacket", "DeskFrontTrim",
		"DeskLeg_L", "PanelTopTrim",
	]
	for workstation_value in office.find_children("Workstation_*", "Node3D", true, false):
		var workstation := workstation_value as Node3D
		for shadow_name in structural_shadow_names:
			var structural := workstation.find_child(shadow_name, true, false) as GeometryInstance3D
			_check(
				structural != null and structural.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON,
				"%s/%s should retain one grounding shadow" % [workstation.name, shadow_name],
				failures,
			)
		for shadow_name in cosmetic_shadow_names:
			for cosmetic_value in workstation.find_children(shadow_name, "GeometryInstance3D", true, false):
				var cosmetic := cosmetic_value as GeometryInstance3D
				_check(
					cosmetic.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
					"%s/%s should receive light without a redundant shadow submission" % [workstation.name, cosmetic.name],
					failures,
				)
	var intake_presentation := office.find_child("IntakePresentation", true, false)
	var intake_shadow_casters := _visible_shadow_caster_count(intake_presentation)
	_check(
		intake_shadow_casters <= 20,
		"intake detail should retain depth without submitting every small prop to the shadow map (found %d)" % intake_shadow_casters,
		failures,
	)
	var archive_story := office.find_child("ArchiveAndIntakeStory", true, false)
	_check(
		_visible_shadow_caster_count(archive_story) == 0,
		"wall-mounted archive/intake storytelling should receive structural shadows without duplicating them",
		failures,
	)
	var collection_chain := office.find_child("VisibleEggCollectionChain", true, false)
	_check(
		_visible_shadow_caster_count(collection_chain) <= 30,
		"collection hardware should reserve shadows for structural rails, tubes, trays, and carriers",
		failures,
	)
	var office_shell := office.find_child("OfficeShell", true, false)
	_check(
		_visible_shadow_caster_count(office_shell) <= Office.CORE_OFFICE_STRUCTURAL_SHADOW_HOSTS.size(),
		"office shell should reserve real-time shadows for a few grounding props",
		failures,
	)
	var management_perch := office.find_child("RoosterManagementPerch", true, false)
	_check(
		_visible_shadow_caster_count(management_perch) <= 9,
		"management perch should keep its silhouette without shadowing every dashboard detail",
		failures,
	)
	var floor_chevrons := office.find_children("PeckFlowChevron*", "MeshInstance3D", true, false)
	_check(floor_chevrons.size() == 6, "access lanes should include floor storytelling (found %d)" % floor_chevrons.size(), failures)
	_check(_multimesh_instance_total(office, "WindowFrameBatch") == 18, "window frame batching should preserve all 18 frame pieces", failures)
	_check(_multimesh_instance_total(office, "WindowBlindSlatBatch") == 12, "window batching should preserve all 12 blind slats", failures)
	_check(_multimesh_instance_total(office, "WindowRadiatorFinBatch") == 30, "window batching should preserve all 30 radiator fins", failures)
	_check(_multimesh_instance_total(office, "PastureFenceBatch") == 30, "farm views should preserve all 30 fence pieces", failures)
	_check(_multimesh_instance_total(office, "PeckLaneScuffBatch") == 9, "access lanes should preserve all nine wear marks", failures)
	_check(office.find_child("HenOfMonthFrame", true, false) != null, "office should include farm-bureau wall storytelling", failures)
	var ledger := office.find_child("FlockwatchLedger", true, false) as Control
	_check(ledger != null and not ledger.visible, "Flockwatch ledger should default closed so it cannot obscure the office", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("OFFICE_DETAIL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OFFICE_DETAIL_TEST_PASSED windows=6 personalized_desks=6 farm_story=expanded ledger=collapsed")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _multimesh_instance_total(office: Node, batch_name: String) -> int:
	var total := 0
	for candidate in office.find_children(batch_name, "MultiMeshInstance3D", true, false):
		var batch := candidate as MultiMeshInstance3D
		if batch != null and batch.multimesh != null:
			total += batch.multimesh.instance_count
	return total


func _visible_shadow_caster_count(root_node: Node) -> int:
	if root_node == null:
		return 0
	var count := 0
	for candidate in root_node.find_children("*", "GeometryInstance3D", true, false):
		var geometry := candidate as GeometryInstance3D
		if geometry.is_visible_in_tree() and geometry.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			count += 1
	return count
