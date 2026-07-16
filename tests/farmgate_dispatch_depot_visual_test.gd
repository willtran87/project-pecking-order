extends SceneTree

const FarmgateDispatchDepotVisualScript := preload("res://features/office/farmgate_dispatch_depot_visual.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var visual := FarmgateDispatchDepotVisualScript.new() as FarmgateDispatchDepotVisual
	root.add_child(visual)
	await process_frame

	_check(
		FarmgateDispatchDepotVisualScript.declared_footprint()
		== Rect2(Vector2(18.65, -8.90), Vector2(8.80, 11.80)),
		"Depot should retain its exact east distribution parcel",
		failures,
	)
	_check(
		FarmgateDispatchDepotVisualScript.entrance_bridge_footprint()
		== Rect2(Vector2(18.40, -6.60), Vector2(0.25, 1.20)),
		"Depot should publish its exact Packing Annex bridge",
		failures,
	)
	_check(
		FarmgateDispatchDepotVisualScript.clear_aisle_footprint()
		== Rect2(Vector2(18.40, -6.55), Vector2(3.10, 1.10)),
		"Depot should publish its exact 1.10m pedestrian aisle",
		failures,
	)
	_check(
		FarmgateDispatchDepotVisualScript.vehicle_lane_footprint()
		== Rect2(Vector2(23.70, -8.55), Vector2(3.35, 10.90)),
		"Depot should publish its exact reserved refrigerated-truck lane",
		failures,
	)
	_check(
		FarmgateDispatchDepotVisualScript.facility_focus_point()
		== Vector3(23.05, 1.25, -3.00),
		"Depot should publish its exact stable camera focus",
		failures,
	)
	_check(
		visual.focus_point_global().is_equal_approx(Vector3(23.05, 1.25, -3.00)),
		"Depot focus should apply its world center exactly once",
		failures,
	)

	_check(visual.visual_state() == &"locked" and visual.locked_marker_visible(), "fresh Depot should begin as a locked freight parcel", failures)
	_check(visual.stock_case_count() == 0 and visual.visible_case_count() == 0, "locked construction must not invent packed cases", failures)
	_check(not visual.manifest_visible() and not visual.truck_visible(), "locked construction must not invent a route receipt or truck", failures)
	_assert_geometry_contract(visual, "locked", failures)
	var lease_mount := visual.find_child("DispatchLeasePermitMount", true, false) as Node3D
	var lease_host := visual.find_child("DispatchLeaseNoticeHost", true, false) as MeshInstance3D
	var lease_fixture := visual.find_child("DispatchLeaseNoticeFixture", true, false) as Node3D
	_check(lease_mount != null and bool(lease_mount.get_meta(&"ground_supported", false)), "locked parcel notice should stand on surveyed boundary stakes", failures)
	_check(lease_mount != null and lease_mount.position.z < -5.0, "locked parcel notice should stay on the depot boundary instead of colliding visually with North Meadow", failures)
	_check(lease_mount != null and lease_mount.find_children("DispatchLeaseNoticeStake*", "MeshInstance3D", true, false).size() == 2, "locked parcel notice should have two visible timber supports", failures)
	_check(lease_host != null and bool(lease_host.get_meta(&"boundary_permit_board", false)), "locked parcel copy should use the compact boundary permit board", failures)
	if lease_host != null and lease_host.mesh is BoxMesh:
		_check((lease_host.mesh as BoxMesh).size.x <= 2.20, "locked parcel permit should remain compact rather than becoming an overview billboard", failures)
	_check(lease_fixture != null and lease_fixture.get_meta(&"style_family", &"") == &"paper_notice", "locked parcel copy should read as a pinned permit, not a destination sign", failures)
	_check(lease_fixture != null and not bool(lease_fixture.get_meta(&"overview_anchor", true)), "locked parcel permit text should recede outside local focus", failures)

	visual.apply_snapshot({
		"facility_catalog": [{"id": &"farmgate_dispatch_depot", "unlocked": true, "level": 0}],
		"farmgate_dispatch_depot": _dispatch_projection(0, true),
	})
	_check(visual.visual_state() == &"survey" and visual.survey_site_visible(), "unlocked level zero should reveal only the surveyed output yard", failures)
	_check(visual.visible_case_count() == 0 and not visual.manifest_visible(), "survey state must remain free of economic evidence", failures)
	_assert_geometry_contract(visual, "survey", failures)

	var expected_visible_cases := [0, 7, 16, 31]
	for purchased_level in range(1, 4):
		visual.apply_snapshot({
			"owned_facilities": {&"farmgate_dispatch_depot": purchased_level},
			"farmgate_dispatch_depot": _dispatch_projection(purchased_level, false),
		})
		_check(
			visual.visual_state() == StringName("level_%d" % purchased_level),
			"Depot tier %d should publish its own state" % purchased_level,
			failures,
		)
		for retained_level in range(1, purchased_level + 1):
			_check(
				visual.level_visible(retained_level),
				"Depot tier %d should retain tier %d construction" % [purchased_level, retained_level],
				failures,
			)
		_check(
			visual.visible_case_count() == expected_visible_cases[purchased_level],
			"Depot tier %d should materialize only its canonical packed cases" % purchased_level,
			failures,
		)
		_check(
			visual.truck_visible() == (purchased_level == 3),
			"refrigerated fleet should appear only at tier three",
			failures,
		)
		_assert_geometry_contract(visual, "level %d" % purchased_level, failures)

	_check(visual.find_child("RoadsideManualScale", true, false) != null, "level one should add its connected manual scale", failures)
	_check(visual.find_child("RoadsideColdBasket", true, false) != null, "level one should add the twelve-cell cold basket rack", failures)
	_check(visual.find_child("SplitFlapRouteBoardHost", true, false) != null, "level one should mount its mechanical route slate", failures)
	_check(visual.find_child("ColdChainCondenser", true, false) != null, "level two should add its connected cold-chain condenser", failures)
	_check(visual.find_children("SawtoothColdRoof_*", "MeshInstance3D", true, false).size() == 4, "level two should add four galvanized sawtooth roof bays", failures)
	_check(visual.find_child("CountyCaseConveyor", true, false) != null and visual.find_child("RaisedCountyDock", true, false) != null, "level two should add the dock and case conveyor", failures)
	_check(visual.find_child("BarnRedDispatchTower", true, false) != null, "level three should add the tall barn-red dispatch tower", failures)
	_check(visual.find_child("RegionalLoadingMast", true, false) != null, "level three should add the loading mast", failures)
	_check(visual.find_child("FarmerBrandRefrigeratedTruck", true, false) != null, "level three should add the refrigerated Farmer Brand truck", failures)
	_check(visual.find_children("DispatchCase_*", "MeshInstance3D", true, false).size() == 42, "cumulative racks should publish exactly 42 physical case cells", failures)

	var identity_fixture := visual.find_child("FarmgateDispatchDepotIdentityFixture", true, false) as Node3D
	_check(identity_fixture != null, "Depot should carry its main physical destination fascia", failures)
	if identity_fixture != null:
		_check(bool(identity_fixture.get_meta(&"host_attached", false)), "main Depot identity should be attached to its fascia host", failures)
		_check(bool(identity_fixture.get_meta(&"uses_modeled_type", false)), "main Depot identity should use modeled destination lettering", failures)
		_check(_fixture_copy(identity_fixture).contains("FARMGATE DISPATCH DEPOT"), "modeled Depot fascia should carry the exact destination name", failures)

	for fixture_name in [
		"ScaleCaseCounterFixture",
		"SplitFlapRouteBoardFixture",
		"ColdChainConditionLedgerFixture",
		"FarmerBrandTruckLiveryFixture",
		"TruckRouteManifestFixture",
		"DispatchCaseTag_00Fixture",
	]:
		var fixture := visual.find_child(fixture_name, true, false) as Node3D
		_check(fixture != null, "%s should exist on a physical host" % fixture_name, failures)
		if fixture != null:
			_check(bool(fixture.get_meta(&"host_attached", false)), "%s must remain attached instead of floating" % fixture_name, failures)

	_check("COUNTY CO-OP" in visual.route_text(), "route slate should mirror the canonical mandate", failures)
	_check("AUTUMN FARMGATE" in visual.route_text(), "route slate should mirror the canonical deterministic season", failures)
	_check("OVERFLOW 02" in visual.condition_text() and "SPOILED 01" in visual.condition_text(), "condition hardware should mirror exact overflow and spoilage", failures)
	_check(visual.overflow_indicator_active() and visual.spoilage_indicator_active(), "canonical output losses should illuminate their mounted lamps", failures)
	_check(visual.manifest_visible(), "canonical last route should reveal the truck manifest", failures)
	_check("DAY 14" in visual.manifest_text() and "31 CASES" in visual.manifest_text() and "$73.50" in visual.manifest_text(), "truck manifest should mirror the canonical route receipt", failures)
	var first_case_tag := visual.find_child("DispatchCaseTag_00", true, false) as Label3D
	_check(first_case_tag != null and "PACKED BY THE FLOCK" in first_case_tag.text, "visible packed cases should carry the exact flock crate stamp", failures)
	var truck_livery := visual.find_child("FarmerBrandTruckLivery", true, false) as Label3D
	_check(truck_livery != null and truck_livery.text == "FARMER BRAND EGGS", "truck should carry the exact farmer-brand livery", failures)

	# The Office passes the complete DepartmentSimulation snapshot, whose public
	# Farmgate projection uses egg-ledger field names rather than the isolated art
	# fixture aliases above. This contract prevents real stored eggs from rendering
	# as an empty rack even while the economy ledger is full.
	var simulation_lots: Array[Dictionary] = []
	for lot_index in 5:
		simulation_lots.append({
			"lot_id": 9000 + lot_index,
			"laying_day": 14,
			"expires_day": 15,
			"worker_name": "CAPTURE HEN %d" % (lot_index + 1),
			"quality": &"sound",
			"value_cents": 500,
		})
	visual.apply_snapshot({
		"day": 14,
		"owned_facilities": {&"farmgate_dispatch_depot": 1},
		"farmgate_dispatch": {
			"level": 1,
			"status": "MANDATE FILED",
			"storage_capacity_eggs": 12,
			"stock_count": 5,
			"lots": simulation_lots,
			"season": {"id": &"autumn_farmgate", "label": "Autumn Farmgate"},
			"active_mandate": {
				"mandate_id": &"county_auction",
				"dispatch_limit": 8,
			},
			"last_settlement_receipt": {},
		},
	})
	_check(visual.has_authoritative_projection(), "the public farmgate_dispatch projection should be authoritative", failures)
	_check(visual.stock_case_count() == 5 and visual.visible_case_count() == 5, "five real stored eggs should materialize five warm kraft case cells", failures)
	_check("COUNTY AUCTION" in visual.route_text() and "08 CASES" in visual.route_text(), "the real active mandate should drive the mounted route board", failures)
	var simulation_case_tag := visual.find_child("DispatchCaseTag_00", true, false) as Label3D
	_check(simulation_case_tag != null and "9000" in simulation_case_tag.text and "D14" in simulation_case_tag.text, "the first real lot should stamp its exact ledger identity and laying day", failures)

	var level_one_height := visual.cumulative_silhouette_height(1)
	var level_two_height := visual.cumulative_silhouette_height(2)
	var level_three_height := visual.cumulative_silhouette_height(3)
	_check(level_one_height >= 2.70 and level_one_height <= 3.20, "level one should remain a low canopy silhouette (%.2fm)" % level_one_height, failures)
	_check(level_two_height >= level_one_height + 0.80 and level_two_height <= 4.50, "level two should add an unmistakable middle-height cold shed (%.2fm)" % level_two_height, failures)
	_check(level_three_height >= level_two_height + 0.70 and level_three_height <= FarmgateDispatchDepotVisualScript.maximum_visual_height() + 0.02, "level three should add the tall route-fleet landmark (%.2fm)" % level_three_height, failures)

	visual.apply_snapshot({
		"owned_facilities": {&"farmgate_dispatch_depot": 3},
		"farmgate_dispatch_depot": _dispatch_projection(3, true),
	})
	_check(visual.has_authoritative_projection(), "empty projection should remain authoritative", failures)
	_check(visual.stock_case_count() == 0 and visual.visible_case_count() == 0, "empty canonical stock should remove every packed case", failures)
	_check(not visual.manifest_visible(), "empty canonical receipt should remove the truck manifest", failures)
	_check(not visual.overflow_indicator_active() and not visual.spoilage_indicator_active(), "empty canonical losses should clear both warning lamps", failures)
	_check("NO ROUTE FILED" in visual.route_text() and "00/42 CASES" in visual.route_text(), "empty route slate should state its honest capacity and idle state", failures)
	_assert_geometry_contract(visual, "empty level three", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("FARMGATE_DISPATCH_DEPOT_VISUAL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARMGATE_DISPATCH_DEPOT_VISUAL_TEST_PASSED states=locked-survey-l1-l2-l3 cells=42 cases=canonical fascia=modeled bridge=exact aisle=clear truck_lane=reserved collisions=0")
	quit(0)


func _dispatch_projection(level: int, empty: bool) -> Dictionary:
	var case_count: int = int([0, 7, 16, 31][clampi(level, 0, 3)])
	return {
		"level": level,
		"status": "survey" if level == 0 else "operating",
		"day": 14,
		"capacity_cases": [0, 12, 24, 42][clampi(level, 0, 3)],
		"stock_lots": [] if empty else [
			{
				"lot_id": "BASKET-14A",
				"packed_day": 13,
				"expires_day": 15,
				"cases_remaining": mini(case_count, 12),
			},
			{
				"lot_id": "CLUTCH-14B",
				"packed_day": 14,
				"expires_day": 17,
				"cases_remaining": maxi(0, case_count - 12),
			},
		],
		"mandate": {} if empty else {
			"id": &"county_coop",
			"label": "COUNTY CO-OP",
			"case_count": case_count,
		},
		"season": {} if empty else {"id": &"autumn_farmgate", "label": "Autumn Farmgate"},
		"last_receipt": {} if empty or level < 3 else {
			"day": 14,
			"route_label": "County Co-op",
			"case_count": 31,
			"net_cents": 7350,
		},
		"overflow_cases": 0 if empty else 2,
		"spoiled_cases": 0 if empty else 1,
	}


func _assert_geometry_contract(visual: FarmgateDispatchDepotVisual, state: String, failures: Array[String]) -> void:
	_check(visual.geometry_bounds_inside_footprint(), "%s geometry should remain inside the exact Depot parcel and height envelope" % state, failures)
	_check(visual.connector_geometry_inside_bridge(), "%s connector should remain inside the exact Packing Annex bridge" % state, failures)
	_check(visual.circulation_clear(), "%s should preserve the exact 1.10m pedestrian aisle" % state, failures)
	_check(visual.vehicle_geometry_inside_lane(), "%s should keep the complete refrigerated truck inside its reserved lane" % state, failures)
	_check(visual.vehicle_lane_clear_of_unauthorized_geometry(), "%s should keep non-vehicle geometry out of the active truck envelope" % state, failures)
	_check(visual.find_children("*", "CollisionObject3D", true, false).is_empty(), "%s should add no collisions" % state, failures)
	_check(visual.find_children("*", "NavigationRegion3D", true, false).is_empty(), "%s should add no navigation regions" % state, failures)
	_check(visual.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "%s should add no navigation obstacles" % state, failures)


func _fixture_copy(fixture: Node3D) -> String:
	var result := ""
	for candidate in fixture.find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance != null and instance.mesh is TextMesh:
			result += String((instance.mesh as TextMesh).text) + "\n"
	for candidate in fixture.find_children("*", "Label3D", true, false):
		var label := candidate as Label3D
		if label != null:
			result += label.text + "\n"
	return result


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
