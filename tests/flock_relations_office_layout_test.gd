extends SceneTree

const ShellQualityLabVisualScript := preload("res://features/office/shell_quality_lab_visual.gd")
const PackingAnnexVisualScript := preload("res://features/office/packing_annex_visual.gd")
const RecordsAnnexVisualScript := preload("res://features/office/records_annex_visual.gd")
const FarmMutualServiceCoopVisualScript := preload("res://features/office/farm_mutual_service_coop_visual.gd")
const FarmMutualNegotiationRoomVisualScript := preload("res://features/office/farm_mutual_negotiation_room_visual.gd")
const FarmMutualContractBoardVisualScript := preload("res://features/office/farm_mutual_contract_board_visual.gd")
const WellnessNestVisualScript := preload("res://features/office/wellness_nest_visual.gd")
const TrainingRoostVisualScript := preload("res://features/office/training_roost_visual.gd")
const RoosterOperationsOfficeVisualScript := preload("res://features/office/rooster_operations_office_visual.gd")
const ITCoopVisualScript := preload("res://features/office/it_coop_visual.gd")
const FlockRelationsOfficeVisualScript := preload("res://features/office/flock_relations_office_visual.gd")
const OfficeStorytellingScript := preload("res://features/office/office_storytelling.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var footprint := FlockRelationsOfficeVisualScript.declared_footprint()
	var bridge := FlockRelationsOfficeVisualScript.entrance_bridge_footprint()
	var clear_aisle := FlockRelationsOfficeVisualScript.clear_aisle_footprint()
	var operations_spine := OfficeStorytellingScript.OPERATIONS_CAMPUS_SPINE_FOOTPRINT
	var rooster_office := RoosterOperationsOfficeVisualScript.declared_footprint()
	var it_coop := ITCoopVisualScript.declared_footprint()

	_check(footprint == Rect2(Vector2(4.10, 33.10), Vector2(6.40, 5.80)), "Flock Relations should occupy the exact mirrored west parcel", failures)
	_check(footprint.get_center().is_equal_approx(Vector2(7.30, 36.00)), "Flock Relations parcel should center at X 7.30 / Z 36.00", failures)
	_check(footprint.end.x < operations_spine.position.x, "Flock Relations must remain west of the operations spine", failures)
	_check(is_equal_approx(operations_spine.position.x - footprint.end.x, 0.25), "west parcel should retain its exact 25 cm spine seam", failures)
	_check(not footprint.intersects(operations_spine), "Flock Relations room must not overlap the operations spine", failures)
	_check(not footprint.intersects(it_coop), "Flock Relations must not overlap the mirrored IT Coop parcel", failures)
	_check(not footprint.intersects(rooster_office), "Flock Relations must not overlap Rooster Operations", failures)
	_check(is_equal_approx(footprint.position.y, it_coop.position.y) and is_equal_approx(footprint.end.y, it_coop.end.y), "Flock Relations should align exactly across the spine from IT Coop", failures)

	_check(is_equal_approx(bridge.position.x, footprint.end.x), "entrance bridge should begin at the facility boundary", failures)
	_check(is_equal_approx(bridge.end.x, operations_spine.position.x), "entrance bridge should terminate exactly at the spine", failures)
	_check(bridge.position.y >= footprint.position.y and bridge.end.y <= footprint.end.y, "entrance bridge should remain inside the room's Z span", failures)
	_check(bridge.intersects(clear_aisle), "the declared clear aisle should continue across the entrance bridge", failures)
	_check(is_equal_approx(clear_aisle.end.x, operations_spine.position.x), "clear aisle should reach the spine without a gap", failures)
	_check(is_equal_approx(clear_aisle.size.y, 1.10), "clear aisle should retain 1.10m of chicken circulation width", failures)
	_check(clear_aisle.position.y >= footprint.position.y and clear_aisle.end.y <= footprint.end.y, "clear aisle should stay within the room's Z span", failures)

	for existing in _existing_facility_footprints():
		var existing_footprint := existing.get("footprint", Rect2()) as Rect2
		_check(not footprint.intersects(existing_footprint), "Flock Relations must not overlap %s" % String(existing.get("name", "existing facility")), failures)

	var visual := FlockRelationsOfficeVisualScript.new() as FlockRelationsOfficeVisual
	root.add_child(visual)
	await process_frame
	_check(visual.geometry_bounds_inside_footprint(), "room meshes should stay inside the exact west parcel", failures)
	_check(visual.connector_geometry_inside_bridge(), "bridge meshes should stay inside the exact 25 cm connector", failures)
	_check(visual.circulation_clear(), "every cumulative tier should preserve the exact ingress aisle", failures)
	_check(visual.find_children("*", "CollisionObject3D", true, false).is_empty(), "west parcel should add no collision objects", failures)
	_check(visual.find_children("*", "NavigationRegion3D", true, false).is_empty(), "west parcel should add no navigation regions", failures)
	_check(visual.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "west parcel should add no navigation obstacles", failures)
	var bridge_root := visual.find_child("FlockRelationsEntranceBridge", true, false) as Node3D
	_check(bridge_root != null and bool(bridge_root.get_meta(&"campus_connector", false)), "entrance bridge should declare its connector role", failures)
	_check(bridge_root != null and bridge_root.get_meta(&"declared_footprint", Rect2()) == bridge, "entrance bridge should publish the exact connector footprint", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("FLOCK_RELATIONS_OFFICE_LAYOUT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FLOCK_RELATIONS_OFFICE_LAYOUT_TEST_PASSED facility_footprints=11 west_branch=mirrored bridge=exact aisle=1.10m collisions=0 navigation=0")
	quit(0)


func _existing_facility_footprints() -> Array[Dictionary]:
	return [
		{"name": "shell QA", "footprint": ShellQualityLabVisualScript.declared_footprint()},
		{"name": "Packing Annex", "footprint": PackingAnnexVisualScript.declared_footprint()},
		{"name": "Records Annex", "footprint": RecordsAnnexVisualScript.declared_footprint()},
		{"name": "Farm Mutual Service Coop", "footprint": FarmMutualServiceCoopVisualScript.declared_footprint()},
		{"name": "Farm Mutual negotiation room", "footprint": FarmMutualNegotiationRoomVisualScript.declared_footprint()},
		{"name": "Wellness Nest", "footprint": WellnessNestVisualScript.declared_footprint()},
		{"name": "Training Roost", "footprint": TrainingRoostVisualScript.declared_footprint()},
		{"name": "Rooster Operations", "footprint": RoosterOperationsOfficeVisualScript.declared_footprint()},
		{"name": "IT Coop", "footprint": ITCoopVisualScript.declared_footprint()},
		{"name": "Farm Mutual wall board", "footprint": FarmMutualContractBoardVisualScript.declared_footprint()},
	]


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
