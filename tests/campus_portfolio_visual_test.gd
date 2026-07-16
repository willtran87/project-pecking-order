extends SceneTree

const CampusPortfolioVisualScript := preload("res://features/office/campus_portfolio_visual.gd")
const CampusExpansionVisualScript := preload("res://features/office/campus_expansion_visual.gd")
const WellnessNestVisualScript := preload("res://features/office/wellness_nest_visual.gd")
const TrainingRoostVisualScript := preload("res://features/office/training_roost_visual.gd")
const RoosterOperationsOfficeVisualScript := preload("res://features/office/rooster_operations_office_visual.gd")
const ITCoopVisualScript := preload("res://features/office/it_coop_visual.gd")

const ORCHARD := Rect2(Vector2(18.65, 15.10), Vector2(12.80, 11.80))
const CREEKSIDE := Rect2(Vector2(18.65, 27.10), Vector2(12.80, 11.80))
const TRUNK := Rect2(Vector2(28.15, 5.45), Vector2(2.10, 33.50))
const ORCHARD_ROUTE := Rect2(Vector2(19.10, 15.35), Vector2(11.90, 2.10))
const CREEKSIDE_ROUTE := Rect2(Vector2(19.10, 27.35), Vector2(11.90, 2.10))


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_assert_spatial_contract(failures)
	_assert_stage_classifier(failures)

	var visual := CampusPortfolioVisualScript.new() as CampusPortfolioVisual
	root.add_child(visual)
	await process_frame
	_assert_fresh_portfolio(visual, failures)
	_assert_mounted_signage(visual, failures)

	visual.apply_snapshot({
		"campus_portfolio": {
			"parcels": [
				{"id": &"orchard_row", "owned": true},
				{"id": &"creekside_yard", "status": &"owned"},
			],
			"projects": [
				{"pad_id": &"orchard_west", "module_id": &"collection_rail_hub", "status": &"queued"},
				{"pad_id": &"orchard_east", "module_id": &"grain_recovery_mill", "stage": &"foundation"},
				{"pad_id": &"creekside_west", "module_id": &"creekside_chilling_exchange", "status": &"building", "progress": 60},
				{"pad_id": &"creekside_east", "module_id": &"contractor_roost", "status": &"operational"},
			],
			"services": {
				"collection_rail": {"active": true},
				"power": true,
				"cold_chain": {"connected": false},
			},
		},
	})
	_assert_mixed_portfolio(visual, failures)

	visual.apply_snapshot(_complete_snapshot())
	_assert_complete_modules(visual, failures)
	_assert_visual_only(visual, failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPUS_PORTFOLIO_VISUAL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_PORTFOLIO_VISUAL_TEST_PASSED parcels=2 pads=6 modules=4 stages=4 service-trunk=protected signage=mounted collisions=0")
	quit(0)


func _assert_spatial_contract(failures: Array[String]) -> void:
	_check(CampusPortfolioVisualScript.declared_footprints() == [ORCHARD, CREEKSIDE], "portfolio parcels should retain their exact deterministic footprints", failures)
	_check(CampusPortfolioVisualScript.declared_footprint(&"orchard_row") == ORCHARD, "Orchard Row should publish its exact footprint", failures)
	_check(CampusPortfolioVisualScript.declared_footprint(&"creekside_yard") == CREEKSIDE, "Creekside Yard should publish its exact footprint", failures)
	_check(CampusPortfolioVisualScript.declared_footprint(&"unknown") == Rect2(), "unknown parcels should not claim office space", failures)

	var north_meadow := CampusExpansionVisualScript.declared_footprint()
	_check(is_equal_approx(ORCHARD.position.y - north_meadow.end.y, 0.20), "Orchard Row should keep a 0.20 m seam south of North Meadow", failures)
	_check(is_equal_approx(CREEKSIDE.position.y - ORCHARD.end.y, 0.20), "Creekside Yard should keep a 0.20 m seam south of Orchard Row", failures)
	_check(not ORCHARD.intersects(north_meadow) and not ORCHARD.intersects(CREEKSIDE), "new parcel deeds should not overlap each other or North Meadow", failures)

	var adjacent_rooms: Array[Rect2] = [
		WellnessNestVisualScript.declared_footprint(),
		TrainingRoostVisualScript.declared_footprint(),
		RoosterOperationsOfficeVisualScript.declared_footprint(),
		ITCoopVisualScript.declared_footprint(),
	]
	for room: Rect2 in adjacent_rooms:
		_check(is_equal_approx(ORCHARD.position.x - room.end.x, 0.25), "portfolio parcels should keep the authored 0.25 m east-room seam", failures)
		_check(not ORCHARD.intersects(room) and not CREEKSIDE.intersects(room), "portfolio parcels should not overlap an existing east room", failures)

	var pads := CampusPortfolioVisualScript.pad_catalog()
	_check(pads.size() == 6, "portfolio should publish four buildable pads and two protected service pads", failures)
	_check(_ids(pads) == [&"orchard_west", &"orchard_east", &"orchard_service_spine", &"creekside_west", &"creekside_east", &"creekside_service_spine"], "pad IDs and order should remain stable", failures)
	var expected: Dictionary = {
		&"orchard_west": Rect2(Vector2(19.20, 18.20), Vector2(3.40, 7.55)),
		&"orchard_east": Rect2(Vector2(23.35, 18.20), Vector2(3.40, 7.55)),
		&"orchard_service_spine": Rect2(Vector2(27.50, 18.20), Vector2(3.40, 7.55)),
		&"creekside_west": Rect2(Vector2(19.20, 30.20), Vector2(3.40, 7.55)),
		&"creekside_east": Rect2(Vector2(23.35, 30.20), Vector2(3.40, 7.55)),
		&"creekside_service_spine": Rect2(Vector2(27.50, 30.20), Vector2(3.40, 7.55)),
	}
	for pad: Dictionary in pads:
		var pad_id := StringName(String(pad.get("id", "")))
		var footprint := pad.get("footprint", Rect2()) as Rect2
		var parcel := ORCHARD if StringName(String(pad.get("parcel_id", ""))) == &"orchard_row" else CREEKSIDE
		var cross_route := ORCHARD_ROUTE if parcel == ORCHARD else CREEKSIDE_ROUTE
		_check(footprint == expected.get(pad_id, Rect2()), "%s should retain its exact authored pad footprint" % pad_id, failures)
		_check(parcel.encloses(footprint), "%s should remain inside its deed" % pad_id, failures)
		_check(not footprint.intersects(cross_route), "%s should keep the parcel cross-route unobstructed" % pad_id, failures)
		if bool(pad.get("route_blocked", false)):
			_check(footprint.intersects(TRUNK), "%s should visibly reserve the protected service trunk" % pad_id, failures)
			_check((pad.get("allowed_module_ids", []) as Array).is_empty(), "%s should reject every buildable module" % pad_id, failures)
		else:
			_check(not footprint.intersects(TRUNK), "%s should not enter the protected service trunk" % pad_id, failures)
	_check((pads[0].get("allowed_module_ids", []) as Array) == [&"collection_rail_hub", &"grain_recovery_mill"], "Orchard pads should expose only collection and grain modules", failures)
	_check((pads[3].get("allowed_module_ids", []) as Array) == [&"creekside_chilling_exchange", &"contractor_roost"], "Creekside pads should expose only chilling and contractor modules", failures)

	_check(CampusPortfolioVisualScript.protected_trunk_footprint() == TRUNK, "shared service trunk footprint should remain immutable", failures)
	_check(CampusPortfolioVisualScript.navigation_footprints() == [ORCHARD_ROUTE, CREEKSIDE_ROUTE, TRUNK], "navigation helper should publish both cross-routes and the protected trunk", failures)
	var camera_bounds := CampusPortfolioVisualScript.camera_bounds()
	_check(camera_bounds.position.is_equal_approx(Vector3(18.65, -0.18, 5.45)), "camera bounds should begin at the west edge and northern service-trunk end", failures)
	_check(camera_bounds.end.is_equal_approx(Vector3(31.45, 4.45, 38.95)), "camera bounds should enclose all authored portfolio geometry", failures)


func _assert_stage_classifier(failures: Array[String]) -> void:
	_check(CampusPortfolioVisualScript.project_stage({}) == &"empty", "an absent project should leave a pad open", failures)
	_check(CampusPortfolioVisualScript.project_stage({"status": "queued"}) == &"queued", "queued projects should render survey staging", failures)
	_check(CampusPortfolioVisualScript.project_stage({"stage": "foundation"}) == &"foundation", "foundation projects should render the slab", failures)
	_check(CampusPortfolioVisualScript.project_stage({"status": "building", "progress": 0.60}) == &"frame", "ratio construction progress should promote to timber framing", failures)
	_check(CampusPortfolioVisualScript.project_stage({"status": "building", "progress": 60}) == &"frame", "percentage construction progress should promote to timber framing", failures)
	_check(CampusPortfolioVisualScript.project_stage({"status": "operational"}) == &"complete", "operational projects should render their completed module", failures)


func _assert_fresh_portfolio(visual: CampusPortfolioVisual, failures: Array[String]) -> void:
	for parcel_prefix in ["OrchardRow", "CreeksideYard"]:
		var deed := visual.find_child("%sUnownedDeedStakes" % parcel_prefix, true, false) as Node3D
		var owned := visual.find_child("%sOwnedFarmParcel" % parcel_prefix, true, false) as Node3D
		_check(deed != null and deed.visible and owned != null and not owned.visible, "%s should begin as a staked deed option" % parcel_prefix, failures)
	_check(visual.find_child("PortfolioSharedServiceTrunk", true, false) != null, "portfolio should model its shared ground service trunk", failures)
	_check(visual.find_child("PortfolioCollectionRail", true, false) != null, "portfolio should model its overhead collection rail", failures)
	_check(visual.find_child("PortfolioPowerConduit", true, false) != null, "portfolio should model its power conduit", failures)
	_check(visual.find_child("PortfolioColdChainLine", true, false) != null, "portfolio should model its cold-chain line", failures)
	for service_id in ["CollectionRail", "Power", "ColdChain"]:
		var lamp := visual.find_child("Portfolio%sLamp" % service_id, true, false) as MeshInstance3D
		_check(lamp != null and lamp.has_meta(&"service_id"), "%s should have a physical status lamp" % service_id, failures)


func _assert_mixed_portfolio(visual: CampusPortfolioVisual, failures: Array[String]) -> void:
	for parcel_prefix in ["OrchardRow", "CreeksideYard"]:
		var deed := visual.find_child("%sUnownedDeedStakes" % parcel_prefix, true, false) as Node3D
		var owned := visual.find_child("%sOwnedFarmParcel" % parcel_prefix, true, false) as Node3D
		_check(deed != null and not deed.visible and owned != null and owned.visible, "%s should switch cleanly to its owned farm treatment" % parcel_prefix, failures)
	_assert_only_stage(visual, &"orchard_west", &"queued", failures)
	_assert_only_stage(visual, &"orchard_east", &"foundation", failures)
	_assert_only_stage(visual, &"creekside_west", &"frame", failures)
	_assert_only_stage(visual, &"creekside_east", &"complete", failures)
	var contractor := visual.find_child("Module_contractor_roost_creekside_east", true, false) as Node3D
	var chilling := visual.find_child("Module_creekside_chilling_exchange_creekside_east", true, false) as Node3D
	_check(contractor != null and contractor.visible and chilling != null and not chilling.visible, "completed Creekside East should reveal only its selected Contractor Roost", failures)
	_check(visual.find_children("QueuedSurveyStake", "MeshInstance3D", true, false).size() >= 4, "queued projects should retain visible survey stakes", failures)
	_check(visual.find_child("ProjectFoundationSlab", true, false) != null, "foundation projects should retain a physical slab", failures)
	_check(visual.find_child("TimberFramePost", true, false) != null and visual.find_child("FrameScaffoldStandard", true, false) != null, "frame projects should retain timber framing and scaffold", failures)


func _assert_complete_modules(visual: CampusPortfolioVisual, failures: Array[String]) -> void:
	var expected: Dictionary = {
		&"orchard_west": &"collection_rail_hub",
		&"orchard_east": &"grain_recovery_mill",
		&"creekside_west": &"creekside_chilling_exchange",
		&"creekside_east": &"contractor_roost",
	}
	for pad_id: StringName in expected:
		_assert_only_stage(visual, pad_id, &"complete", failures)
		var module_id := expected.get(pad_id) as StringName
		var module_root := visual.find_child("Module_%s_%s" % [module_id, pad_id], true, false) as Node3D
		_check(module_root != null and module_root.visible, "%s should reveal its completed %s" % [pad_id, module_id], failures)
	_check(visual.find_child("CollectionRailHubGantry", true, false) != null and visual.find_child("CollectionRailLaneChute", true, false) != null, "Collection Rail Hub should have its own gantry-and-chute silhouette", failures)
	_check(visual.find_child("GrainRecoverySilo", true, false) != null and visual.find_child("GrainRecoveryAuger", true, false) != null, "Grain Recovery Mill should have its own silo-and-auger silhouette", failures)
	_check(visual.find_child("ChillingExchangeCondenserFan", true, false) != null and visual.find_child("ChillingExchangeColdPipe", true, false) != null, "Chilling Exchange should have its own condenser-and-pipe silhouette", failures)
	_check(visual.find_child("ContractorBlueprintTable", true, false) != null and visual.find_child("ContractorToolRack", true, false) != null, "Contractor Roost should have its own blueprint-and-tool silhouette", failures)


func _assert_only_stage(visual: CampusPortfolioVisual, pad_id: StringName, expected_stage: StringName, failures: Array[String]) -> void:
	for stage_id: StringName in [&"queued", &"foundation", &"frame"]:
		var node_name := "Project%sStage_%s" % [String(stage_id).to_pascal_case(), pad_id]
		var stage_root := visual.find_child(node_name, true, false) as Node3D
		_check(stage_root != null and stage_root.visible == (stage_id == expected_stage), "%s should expose only its %s stage" % [pad_id, expected_stage], failures)
	if expected_stage == &"complete":
		for stage_id: StringName in [&"queued", &"foundation", &"frame"]:
			var stage_root := visual.find_child("Project%sStage_%s" % [String(stage_id).to_pascal_case(), pad_id], true, false) as Node3D
			_check(stage_root != null and not stage_root.visible, "%s complete module should hide temporary construction staging" % pad_id, failures)


func _assert_mounted_signage(visual: CampusPortfolioVisual, failures: Array[String]) -> void:
	var overview_names: Array[String] = []
	for candidate: Node in get_nodes_in_group(&"environmental_signage"):
		if not visual.is_ancestor_of(candidate):
			continue
		_check(candidate.get_parent() is MeshInstance3D, "%s copy should remain mounted to a modeled substrate" % candidate.name, failures)
		_check(bool(candidate.get_meta(&"host_attached", false)) and bool(candidate.get_meta(&"physical_host", false)), "%s should publish its physical host relationship" % candidate.name, failures)
		if bool(candidate.get_meta(&"overview_anchor", false)):
			overview_names.append(String(candidate.name))
	overview_names.sort()
	_check(overview_names == ["CreeksideYardIdentityFixture", "OrchardRowIdentityFixture"], "only parcel destinations should remain overview-critical", failures)


func _assert_visual_only(visual: CampusPortfolioVisual, failures: Array[String]) -> void:
	_check(bool(visual.get_meta(&"visual_only", false)) and bool(visual.get_meta(&"collision_free", false)) and bool(visual.get_meta(&"navigation_free", false)), "portfolio root should declare its projection-only ownership", failures)
	for node_class in ["CollisionObject3D", "CollisionShape3D", "NavigationRegion3D", "NavigationObstacle3D", "NavigationLink3D", "NavigationAgent3D", "CSGShape3D"]:
		_check(visual.find_children("*", node_class, true, false).is_empty(), "portfolio visual should add no %s nodes" % node_class, failures)
	for pad: Dictionary in CampusPortfolioVisualScript.pad_catalog():
		var pad_id := StringName(String(pad.get("id", "")))
		var pad_root := visual.find_child("Pad_%s" % pad_id, true, false) as Node3D
		_check(pad_root != null and StringName(String(pad_root.get_meta(&"pad_id", ""))) == pad_id, "%s should retain its stable scene identity", failures)


func _complete_snapshot() -> Dictionary:
	return {
		"campus_portfolio": {
			"parcels": {
				"orchard_row": {"owned": true},
				"creekside_yard": {"owned": true},
			},
			"projects": [
				{"pad_id": &"orchard_west", "module_id": &"collection_rail_hub", "status": &"complete"},
				{"pad_id": &"orchard_east", "module_id": &"grain_recovery_mill", "status": &"complete"},
				{"pad_id": &"creekside_west", "module_id": &"creekside_chilling_exchange", "status": &"complete"},
				{"pad_id": &"creekside_east", "module_id": &"contractor_roost", "status": &"complete"},
			],
		},
	}


func _ids(records: Array[Dictionary]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for record: Dictionary in records:
		ids.append(StringName(String(record.get("id", ""))))
	return ids


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
