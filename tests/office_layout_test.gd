extends SceneTree

const AGENT_RADIUS := 0.30
const DESK_HALF_WIDTH := 1.35
const DESK_HALF_DEPTH := 0.68
const ShellQualityLabVisualScript := preload("res://features/office/shell_quality_lab_visual.gd")
const PackingAnnexVisualScript := preload("res://features/office/packing_annex_visual.gd")
const RecordsAnnexVisualScript := preload("res://features/office/records_annex_visual.gd")
const FarmMutualServiceCoopVisualScript := preload("res://features/office/farm_mutual_service_coop_visual.gd")
const FarmMutualNegotiationRoomVisualScript := preload("res://features/office/farm_mutual_negotiation_room_visual.gd")
const FarmMutualContractBoardVisualScript := preload("res://features/office/farm_mutual_contract_board_visual.gd")
const WellnessNestVisualScript := preload("res://features/office/wellness_nest_visual.gd")
const TrainingRoostVisualScript := preload("res://features/office/training_roost_visual.gd")
const FarmerRelationsGalleryVisualScript := preload("res://features/office/farmer_relations_gallery_visual.gd")
const RoosterOperationsOfficeVisualScript := preload("res://features/office/rooster_operations_office_visual.gd")
const ITCoopVisualScript := preload("res://features/office/it_coop_visual.gd")
const FlockRelationsOfficeVisualScript := preload("res://features/office/flock_relations_office_visual.gd")
const FeedProcurementCoopVisualScript := preload("res://features/office/feed_procurement_coop_visual.gd")
const FarmgateDispatchDepotVisualScript := preload("res://features/office/farmgate_dispatch_depot_visual.gd")
const CampusExpansionVisualScript := preload("res://features/office/campus_expansion_visual.gd")
const OfficeStorytellingScript := preload("res://features/office/office_storytelling.gd")


func _init() -> void:
	var failures: Array[String] = []
	var starts: Array[Vector3] = []
	for worker_index in 6:
		var start := Office.entry_position(worker_index)
		starts.append(start)
		var route: Array[Vector3] = [start]
		route.append_array(Office.arrival_route(worker_index))
		_check_route_clear(route, worker_index, failures)
		var wellness: Array[Vector3] = [Office.chair_position(worker_index)]
		wellness.append_array(Office.wellness_route(worker_index))
		_check_route_clear(wellness, worker_index, failures)
		var feed_party: Array[Vector3] = [Office.chair_position(worker_index)]
		feed_party.append_array(Office.feed_party_route(worker_index))
		_check_route_clear(feed_party, worker_index, failures)

	for first in starts.size():
		for second in range(first + 1, starts.size()):
			_check(starts[first].distance_to(starts[second]) >= 0.90, "entry queue should keep chickens separated", failures)

	var opening_columns: Array[float] = []
	var opening_rows: Array[float] = []
	for opening_index in 4:
		var opening_desk := Office.desk_position(opening_index)
		if opening_desk.x not in opening_columns:
			opening_columns.append(opening_desk.x)
		if opening_desk.z not in opening_rows:
			opening_rows.append(opening_desk.z)
	_check(
		opening_columns.size() == 2 and opening_rows.size() == 2,
		"the opening four desks should occupy one complete two-by-two pod",
		failures,
	)
	_check(
		Office.desk_position(4).x < opening_columns.min()
		and Office.desk_position(5).x < opening_columns.min(),
		"capacity five and six should reveal the dormant west wing",
		failures,
	)

	for first in 6:
		for second in range(first + 1, 6):
			var delta := Office.desk_position(first) - Office.desk_position(second)
			_check(
				absf(delta.x) >= 5.8 or absf(delta.z) >= 5.5,
				"mature desk sockets must retain circulation separation",
				failures,
			)
			if is_zero_approx(delta.x):
				_check(absf(delta.z) >= 5.5, "desk rows need a full circulation gap", failures)
			elif is_zero_approx(delta.z):
				_check(absf(delta.x) >= 5.8, "desk columns need a full circulation gap", failures)

	for first in 6:
		var first_socket := Office.feed_party_attendance_position(first)
		_check(first_socket.distance_to(Vector3(-9.80, 0.0, 0.0)) >= 1.00, "feed socket %d should keep the full puffy chicken silhouette outside the trough" % first, failures)
		for second in range(first + 1, 6):
			var second_socket := Office.feed_party_attendance_position(second)
			_check(first_socket.distance_to(second_socket) >= 1.15, "feed-party attendance sockets must separate puffy animated silhouettes", failures)
	var annex_footprint := PackingAnnexVisualScript.declared_footprint()
	_check(is_equal_approx(annex_footprint.position.x, 12.0), "Packing Annex should connect exactly at the office's open east edge", failures)
	_check(annex_footprint.size == Vector2(6.4, 5.8), "Packing Annex should retain its authored 6.4m by 5.8m expansion parcel", failures)
	_check(not annex_footprint.intersects(ShellQualityLabVisualScript.declared_footprint()), "external annex must not crowd the Shell QA alcove", failures)
	var records_footprint := RecordsAnnexVisualScript.declared_footprint()
	_check(is_equal_approx(records_footprint.position.x, 12.0), "Records Annex should connect exactly at the office's open east edge", failures)
	_check(records_footprint.size == Vector2(6.4, 5.8), "Records Annex should retain its authored 6.4m by 5.8m expansion parcel", failures)
	_check(not records_footprint.intersects(annex_footprint), "Records Annex must retain its service seam from the Packing Annex", failures)
	_check(not records_footprint.intersects(ShellQualityLabVisualScript.declared_footprint()), "Records Annex must not crowd the Shell QA alcove", failures)
	var service_coop_footprint := FarmMutualServiceCoopVisualScript.declared_footprint()
	_check(is_equal_approx(service_coop_footprint.position.x, 12.0), "Service Coop should connect exactly at the office's open east edge", failures)
	_check(service_coop_footprint == Rect2(Vector2(12.0, 3.1), Vector2(6.4, 5.8)), "Service Coop should retain its authored northeast expansion parcel", failures)
	_check(not service_coop_footprint.intersects(records_footprint), "Service Coop must retain its 20 cm service seam from the Records Annex", failures)
	_check(not service_coop_footprint.intersects(annex_footprint), "Service Coop must not overlap the Packing Annex", failures)
	_check(not service_coop_footprint.intersects(ShellQualityLabVisualScript.declared_footprint()), "Service Coop must not crowd the Shell QA alcove", failures)
	var negotiation_room_footprint := FarmMutualNegotiationRoomVisualScript.declared_footprint()
	_check(negotiation_room_footprint == Rect2(Vector2(12.0, 9.1), Vector2(6.4, 5.8)), "Farm Mutual negotiation room should retain its authored north expansion parcel", failures)
	_check(is_equal_approx(negotiation_room_footprint.position.y - service_coop_footprint.end.y, 0.2), "negotiation room must retain its 20 cm service seam from the Service Coop", failures)
	_check(not negotiation_room_footprint.intersects(service_coop_footprint), "negotiation room must not overlap the Service Coop", failures)
	_check(not negotiation_room_footprint.intersects(records_footprint), "negotiation room must not overlap the Records Annex", failures)
	_check(not negotiation_room_footprint.intersects(annex_footprint), "negotiation room must not overlap the Packing Annex", failures)
	_check(not negotiation_room_footprint.intersects(ShellQualityLabVisualScript.declared_footprint()), "negotiation room must not crowd the Shell QA alcove", failures)
	var contract_board_footprint := FarmMutualContractBoardVisualScript.declared_footprint()
	_check(contract_board_footprint == Rect2(Vector2(-11.82, -1.66), Vector2(0.46, 3.32)), "Farm Mutual board should retain its audited shallow left-wall parcel", failures)
	_check(contract_board_footprint.end.x <= -11.35, "Farm Mutual board must remain recessed from the nearest feed-party attendance socket", failures)
	_check(not contract_board_footprint.intersects(ShellQualityLabVisualScript.declared_footprint()), "wall contract board must not overlap the Shell QA alcove", failures)
	_check(not contract_board_footprint.intersects(annex_footprint), "wall contract board must not overlap the Packing Annex", failures)
	_check(not contract_board_footprint.intersects(records_footprint), "wall contract board must not overlap the Records Annex", failures)
	_check(not contract_board_footprint.intersects(service_coop_footprint), "wall contract board must not overlap the Service Coop", failures)
	_check(not contract_board_footprint.intersects(negotiation_room_footprint), "wall contract board must not overlap the negotiation room", failures)
	var wellness_footprint := WellnessNestVisualScript.declared_footprint()
	_check(wellness_footprint == Rect2(Vector2(12.0, 15.1), Vector2(6.4, 5.8)), "Wellness Nest should retain its authored east-campus parcel", failures)
	_check(is_equal_approx(wellness_footprint.position.y - negotiation_room_footprint.end.y, 0.2), "Wellness Nest must retain its 20 cm service seam from the negotiation room", failures)
	_check(not wellness_footprint.intersects(negotiation_room_footprint), "Wellness Nest must not overlap the negotiation room", failures)
	var training_footprint := TrainingRoostVisualScript.declared_footprint()
	_check(training_footprint == Rect2(Vector2(12.0, 21.1), Vector2(6.4, 5.8)), "Training Roost should retain its authored east-campus parcel", failures)
	_check(is_equal_approx(training_footprint.position.y - wellness_footprint.end.y, 0.2), "Training Roost must retain its 20 cm service seam from the Wellness Nest", failures)
	_check(not training_footprint.intersects(wellness_footprint), "Training Roost must not overlap the Wellness Nest", failures)
	_check(not training_footprint.intersects(negotiation_room_footprint), "Training Roost must not overlap the negotiation room", failures)
	var farmer_relations_gallery_footprint := FarmerRelationsGalleryVisualScript.declared_footprint()
	var farmer_relations_gallery_bridge := FarmerRelationsGalleryVisualScript.entrance_bridge_footprint()
	var farmer_relations_gallery_aisle := FarmerRelationsGalleryVisualScript.clear_aisle_footprint()
	_check(farmer_relations_gallery_footprint == Rect2(Vector2(4.10, 21.10), Vector2(6.40, 5.80)), "Farmer Relations Gallery should retain its exact west care-campus parcel", failures)
	_check(is_equal_approx(farmer_relations_gallery_footprint.position.y, training_footprint.position.y) and farmer_relations_gallery_footprint.size == training_footprint.size, "Farmer Relations Gallery should align across the care spine from Training Roost", failures)
	_check(not farmer_relations_gallery_footprint.intersects(training_footprint), "Farmer Relations Gallery must remain across the spine without overlapping Training Roost", failures)
	_check(farmer_relations_gallery_bridge == Rect2(Vector2(10.50, 23.40), Vector2(0.25, 1.20)), "Farmer Relations Gallery should publish its exact care-spine bridge", failures)
	_check(farmer_relations_gallery_aisle == Rect2(Vector2(8.20, 23.45), Vector2(2.55, 1.10)), "Farmer Relations Gallery should preserve its exact 1.10m clear aisle", failures)
	_check(not farmer_relations_gallery_footprint.intersects(FeedProcurementCoopVisualScript.declared_footprint()), "Farmer Relations Gallery must retain its 20 cm seam from Feed Procurement", failures)
	var care_spine := OfficeStorytellingScript.CARE_CAMPUS_SPINE_FOOTPRINT
	_check(care_spine == Rect2(Vector2(10.75, 8.70), Vector2(1.0, 18.50)), "care campus should retain its connected one-metre circulation spine", failures)
	_check(care_spine.position.y <= 9.0 and care_spine.end.y >= training_footprint.end.y, "care campus spine should connect the office apron through both care parcels", failures)
	_check(care_spine.end.x < wellness_footprint.position.x and care_spine.end.x < training_footprint.position.x, "walkable care spine should remain outside both facility envelopes", failures)
	_check(is_equal_approx(care_spine.position.x - farmer_relations_gallery_footprint.end.x, 0.25), "Farmer Relations Gallery should retain the canonical 25 cm west-spine seam", failures)
	_check(is_equal_approx(farmer_relations_gallery_bridge.position.x, farmer_relations_gallery_footprint.end.x) and is_equal_approx(farmer_relations_gallery_bridge.end.x, care_spine.position.x), "Farmer Relations Gallery bridge should join its parcel directly to the care spine", failures)
	_check(is_equal_approx(farmer_relations_gallery_aisle.end.x, care_spine.position.x) and care_spine.position.y <= farmer_relations_gallery_aisle.position.y and care_spine.end.y >= farmer_relations_gallery_aisle.end.y, "Farmer Relations Gallery aisle should meet and remain covered along Z by the care spine", failures)
	var rooster_operations_footprint := RoosterOperationsOfficeVisualScript.declared_footprint()
	_check(rooster_operations_footprint == Rect2(Vector2(12.0, 27.1), Vector2(6.4, 5.8)), "Rooster Operations should retain its exact east-campus parcel", failures)
	_check(is_equal_approx(rooster_operations_footprint.position.y - training_footprint.end.y, 0.2), "Rooster Operations must retain its 20 cm seam from the Training Roost", failures)
	_check(not rooster_operations_footprint.intersects(training_footprint), "Rooster Operations must not overlap the Training Roost", failures)
	var it_coop_footprint := ITCoopVisualScript.declared_footprint()
	_check(it_coop_footprint == Rect2(Vector2(12.0, 33.1), Vector2(6.4, 5.8)), "IT Coop should retain its exact east-campus parcel", failures)
	_check(is_equal_approx(it_coop_footprint.position.y - rooster_operations_footprint.end.y, 0.2), "IT Coop must retain its 20 cm seam from Rooster Operations", failures)
	_check(not it_coop_footprint.intersects(rooster_operations_footprint), "IT Coop must not overlap Rooster Operations", failures)
	var operations_spine := OfficeStorytellingScript.OPERATIONS_CAMPUS_SPINE_FOOTPRINT
	_check(operations_spine == Rect2(Vector2(10.75, 27.20), Vector2(1.0, 12.0)), "operations campus should retain its exact one-metre circulation spine", failures)
	_check(is_equal_approx(operations_spine.position.y, care_spine.end.y), "operations spine must join the care spine without a gap", failures)
	_check(operations_spine.end.y >= it_coop_footprint.end.y, "operations spine should reach beyond the IT Coop parcel", failures)
	_check(operations_spine.end.x < rooster_operations_footprint.position.x and operations_spine.end.x < it_coop_footprint.position.x, "operations spine must remain west of both facility envelopes", failures)
	var flock_relations_footprint := FlockRelationsOfficeVisualScript.declared_footprint()
	var flock_relations_bridge := FlockRelationsOfficeVisualScript.entrance_bridge_footprint()
	var flock_relations_aisle := FlockRelationsOfficeVisualScript.clear_aisle_footprint()
	_check(flock_relations_footprint == Rect2(Vector2(4.10, 33.10), Vector2(6.40, 5.80)), "Flock Relations should retain its exact west-campus parcel", failures)
	_check(is_equal_approx(flock_relations_footprint.position.y, it_coop_footprint.position.y) and flock_relations_footprint.size == it_coop_footprint.size, "Flock Relations should align across the operations spine from IT Coop", failures)
	_check(not flock_relations_footprint.intersects(it_coop_footprint), "Flock Relations must remain across the spine from IT Coop without overlapping it", failures)
	_check(is_equal_approx(operations_spine.position.x - flock_relations_footprint.end.x, 0.25), "Flock Relations should retain its exact 25 cm seam to the operations spine", failures)
	_check(flock_relations_bridge == Rect2(Vector2(10.50, 35.40), Vector2(0.25, 1.20)), "Flock Relations should publish its exact 1.20m-wide entrance bridge", failures)
	_check(is_equal_approx(flock_relations_bridge.position.x, flock_relations_footprint.end.x) and is_equal_approx(flock_relations_bridge.end.x, operations_spine.position.x), "Flock Relations bridge should join the facility directly to the operations spine", failures)
	_check(flock_relations_aisle == Rect2(Vector2(8.20, 35.45), Vector2(2.55, 1.10)), "Flock Relations should retain its exact 1.10m clear east-entry aisle", failures)
	_check(flock_relations_footprint.merge(flock_relations_bridge).encloses(flock_relations_aisle), "Flock Relations clear aisle should remain inside its parcel and entrance bridge", failures)
	_check(is_equal_approx(flock_relations_aisle.end.x, operations_spine.position.x), "Flock Relations clear aisle should reach the operations spine without a route gap", failures)
	_check(operations_spine.position.y <= flock_relations_aisle.position.y and operations_spine.end.y >= flock_relations_aisle.end.y, "operations spine should cover the full Flock Relations entrance aisle", failures)
	var feed_procurement_footprint := FeedProcurementCoopVisualScript.declared_footprint()
	var feed_procurement_bridge := FeedProcurementCoopVisualScript.entrance_bridge_footprint()
	var feed_procurement_aisle := FeedProcurementCoopVisualScript.clear_aisle_footprint()
	_check(feed_procurement_footprint == Rect2(Vector2(4.10, 27.10), Vector2(6.40, 5.80)), "Feed Procurement should retain its exact southwest operations parcel", failures)
	_check(is_equal_approx(feed_procurement_footprint.position.y, rooster_operations_footprint.position.y) and feed_procurement_footprint.size == rooster_operations_footprint.size, "Feed Procurement should align across the operations spine from Rooster Operations", failures)
	_check(is_equal_approx(flock_relations_footprint.position.y - feed_procurement_footprint.end.y, 0.20), "Feed Procurement should retain its exact 20 cm service seam from Flock Relations", failures)
	_check(not feed_procurement_footprint.intersects(flock_relations_footprint) and not feed_procurement_footprint.intersects(rooster_operations_footprint), "Feed Procurement must complete the southwest campus quadrant without overlapping either neighbor", failures)
	_check(is_equal_approx(operations_spine.position.x - feed_procurement_footprint.end.x, 0.25), "Feed Procurement should retain its exact 25 cm seam to the operations spine", failures)
	_check(feed_procurement_bridge == Rect2(Vector2(10.50, 29.40), Vector2(0.25, 1.20)), "Feed Procurement should publish its exact 1.20m-wide entrance bridge", failures)
	_check(is_equal_approx(feed_procurement_bridge.position.x, feed_procurement_footprint.end.x) and is_equal_approx(feed_procurement_bridge.end.x, operations_spine.position.x), "Feed Procurement bridge should join the facility directly to the operations spine", failures)
	_check(feed_procurement_aisle == Rect2(Vector2(8.20, 29.45), Vector2(2.55, 1.10)), "Feed Procurement should retain its exact 1.10m clear east-entry aisle", failures)
	_check(feed_procurement_footprint.merge(feed_procurement_bridge).encloses(feed_procurement_aisle), "Feed Procurement clear aisle should remain inside its parcel and entrance bridge", failures)
	_check(is_equal_approx(feed_procurement_aisle.end.x, operations_spine.position.x), "Feed Procurement clear aisle should reach the operations spine without a route gap", failures)
	_check(operations_spine.position.y <= feed_procurement_aisle.position.y and operations_spine.end.y >= feed_procurement_aisle.end.y, "operations spine should cover the full Feed Procurement entrance aisle", failures)
	var farmgate_footprint := FarmgateDispatchDepotVisualScript.declared_footprint()
	var meadow_footprint := CampusExpansionVisualScript.declared_footprint()
	var meadow_navigation := CampusExpansionVisualScript.navigation_footprint()
	_check(meadow_footprint == Rect2(Vector2(18.65, 3.10), Vector2(12.80, 11.80)), "North Meadow should retain its exact player-owned parcel", failures)
	_check(is_equal_approx(meadow_footprint.position.y - farmgate_footprint.end.y, 0.20), "North Meadow should keep a 20 cm service seam north of Farmgate Dispatch", failures)
	_check(not meadow_footprint.intersects(farmgate_footprint), "North Meadow must not overlap the Farmgate vehicle and storage parcel", failures)
	_check(not meadow_footprint.intersects(service_coop_footprint) and not meadow_footprint.intersects(negotiation_room_footprint), "North Meadow must remain east of the fixed Service Coop and negotiation parcels", failures)
	_check(meadow_footprint.encloses(meadow_navigation), "the purchased parcel should enclose its full 2.10m circulation spine", failures)
	var meadow_socket_catalog := CampusExpansionVisualScript.socket_catalog()
	_check(meadow_socket_catalog.size() == 3, "North Meadow should publish two viable pads and one route-blocked service pad", failures)
	for socket_value in meadow_socket_catalog:
		var socket := socket_value as Dictionary
		var socket_footprint := socket.get("footprint", Rect2()) as Rect2
		_check(meadow_footprint.encloses(socket_footprint), "%s must remain inside the purchased parcel" % String(socket.get("id", "socket")), failures)
	_check(not bool((meadow_socket_catalog[0] as Dictionary).get("route_blocked", true)) and not bool((meadow_socket_catalog[1] as Dictionary).get("route_blocked", true)), "Meadow West and Meadow East should both remain viable placement choices", failures)
	_check(bool((meadow_socket_catalog[2] as Dictionary).get("route_blocked", false)), "Service Spine placement must remain authoritatively route-blocked", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("OFFICE_LAYOUT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OFFICE_LAYOUT_TEST_PASSED routes=18 floor=24x18 feed_sockets=6 fixed_facilities=13 north_meadow=expandable sockets=2+1-blocked circulation=clear")
	quit(0)


func _check_route_clear(route: Array[Vector3], worker_index: int, failures: Array[String]) -> void:
	for point in route:
		_check(absf(point.x) <= 11.5 and absf(point.z) <= 8.5, "worker %d route must stay inside office margins" % worker_index, failures)
	for segment_index in route.size() - 1:
		var start := route[segment_index]
		var finish := route[segment_index + 1]
		var distance := start.distance_to(finish)
		var samples := maxi(1, int(ceil(distance / 0.08)))
		for sample in samples + 1:
			var point := start.lerp(finish, float(sample) / samples)
			for facility in _facility_footprints():
				var facility_footprint: Rect2 = facility.get("footprint", Rect2())
				var route_safe_min := facility_footprint.position - Vector2.ONE * AGENT_RADIUS
				var route_safe_max := facility_footprint.end + Vector2.ONE * AGENT_RADIUS
				var inside_facility_x := point.x > route_safe_min.x and point.x < route_safe_max.x
				var inside_facility_z := point.z > route_safe_min.y and point.z < route_safe_max.y
				_check(
					not (inside_facility_x and inside_facility_z),
					"worker %d route intersects the declared %s facility clearance" % [worker_index, String(facility.get("name", "facility"))],
					failures
				)
			for desk_index in 6:
				var desk := Office.desk_position(desk_index)
				var inside_x := absf(point.x - desk.x) < DESK_HALF_WIDTH + AGENT_RADIUS
				var inside_z := absf(point.z - desk.z) < DESK_HALF_DEPTH + AGENT_RADIUS
				_check(not (inside_x and inside_z), "worker %d route intersects desk %d" % [worker_index, desk_index], failures)


func _facility_footprints() -> Array[Dictionary]:
	return [
		{"name": "shell-QA", "footprint": ShellQualityLabVisualScript.declared_footprint()},
		{"name": "packing-annex", "footprint": PackingAnnexVisualScript.declared_footprint()},
		{"name": "records-annex", "footprint": RecordsAnnexVisualScript.declared_footprint()},
		{"name": "farm-mutual-service-coop", "footprint": FarmMutualServiceCoopVisualScript.declared_footprint()},
		{"name": "farm-mutual-negotiation-room", "footprint": FarmMutualNegotiationRoomVisualScript.declared_footprint()},
		{"name": "wellness-nest", "footprint": WellnessNestVisualScript.declared_footprint()},
		{"name": "training-roost", "footprint": TrainingRoostVisualScript.declared_footprint()},
		{"name": "farmer-relations-gallery", "footprint": FarmerRelationsGalleryVisualScript.declared_footprint()},
		{"name": "rooster-operations-office", "footprint": RoosterOperationsOfficeVisualScript.declared_footprint()},
		{"name": "it-coop", "footprint": ITCoopVisualScript.declared_footprint()},
		{"name": "flock-relations-office", "footprint": FlockRelationsOfficeVisualScript.declared_footprint()},
		{"name": "feed-procurement-coop", "footprint": FeedProcurementCoopVisualScript.declared_footprint()},
		{"name": "farm-mutual-contract-board", "footprint": FarmMutualContractBoardVisualScript.declared_footprint()},
	]


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
