extends SceneTree

## The imported puffy chicken plus every current accessory profile measures at
## most 0.571 m from its route origin in X/Z.  A 0.60 m swept radius therefore
## protects the rendered silhouette, not only an abstract navigation point.
const CHICKEN_SWEEP_RADIUS := 0.60
const DESK_NAVIGATION_RADIUS := 0.30
const DESK_HALF_SIZE := Vector2(1.35, 0.68)

const ShellQualityLabVisualScript := preload("res://features/office/shell_quality_lab_visual.gd")
const PackingAnnexVisualScript := preload("res://features/office/packing_annex_visual.gd")
const RecordsAnnexVisualScript := preload("res://features/office/records_annex_visual.gd")
const FarmMutualServiceCoopVisualScript := preload("res://features/office/farm_mutual_service_coop_visual.gd")
const FarmMutualNegotiationRoomVisualScript := preload("res://features/office/farm_mutual_negotiation_room_visual.gd")
const WellnessNestVisualScript := preload("res://features/office/wellness_nest_visual.gd")
const TrainingRoostVisualScript := preload("res://features/office/training_roost_visual.gd")
const FarmerRelationsGalleryVisualScript := preload("res://features/office/farmer_relations_gallery_visual.gd")
const RoosterOperationsOfficeVisualScript := preload("res://features/office/rooster_operations_office_visual.gd")
const ITCoopVisualScript := preload("res://features/office/it_coop_visual.gd")
const FlockRelationsOfficeVisualScript := preload("res://features/office/flock_relations_office_visual.gd")
const FeedProcurementCoopVisualScript := preload("res://features/office/feed_procurement_coop_visual.gd")
const FarmgateDispatchDepotVisualScript := preload("res://features/office/farmgate_dispatch_depot_visual.gd")
const CampusExpansionVisualScript := preload("res://features/office/campus_expansion_visual.gd")
const CampusPortfolioVisualScript := preload("res://features/office/campus_portfolio_visual.gd")
const OfficeStorytellingScript := preload("res://features/office/office_storytelling.gd")

const PAD_IDS: Array[StringName] = [
	&"orchard_west",
	&"orchard_east",
	&"creekside_west",
	&"creekside_east",
]


func _init() -> void:
	var failures: Array[String] = []
	var blockers := _declared_blockers()
	var minimum_clearance := INF

	_check(
		Office.CAMPUS_COMMUTE_SPINE_X == 11.25
		and Office.CAMPUS_COMMUTE_SPINE_ENTRY_Z == 8.70,
		"campus commute should enter the connected care spine on its 11.25 m centerline",
		failures,
	)
	_check(
		OfficeStorytellingScript.CARE_CAMPUS_SPINE_FOOTPRINT.has_point(Vector2(11.25, 8.70))
		and OfficeStorytellingScript.OPERATIONS_CAMPUS_SPINE_FOOTPRINT.has_point(Vector2(11.25, 38.90)),
		"the northbound authored commute should remain on both connected campus spines",
		failures,
	)
	_check(
		is_equal_approx(Office.CAMPUS_COMMUTE_NORTH_BYPASS_Z - 38.95, 0.70),
		"north bypass should retain exactly 0.70 m beyond the portfolio service envelope",
		failures,
	)
	_check(
		is_equal_approx(Office.CAMPUS_COMMUTE_EAST_BYPASS_X - 31.45, 0.70),
		"east bypass should retain exactly 0.70 m beyond the parcel envelope",
		failures,
	)

	for pad_id: StringName in PAD_IDS:
		var duty := Office.campus_duty_position(pad_id)
		var parcel_id := (
			CampusPortfolioVisualScript.ORCHARD_ROW_ID
			if String(pad_id).begins_with("orchard_")
			else CampusPortfolioVisualScript.CREEKSIDE_YARD_ID
		)
		var parcel_route := _parcel_cross_route(parcel_id)
		var pad_footprint := CampusPortfolioVisualScript.declared_pad_footprint(pad_id)
		_check(duty.is_finite(), "%s should publish a finite duty position" % String(pad_id), failures)
		_check(
			parcel_route.grow(-CHICKEN_SWEEP_RADIUS).has_point(Vector2(duty.x, duty.z)),
			"%s duty position should fit the puffy chicken fully inside its cross-route" % String(pad_id),
			failures,
		)
		_check(
			_point_rect_distance(Vector2(duty.x, duty.z), pad_footprint) >= CHICKEN_SWEEP_RADIUS,
			"%s duty position should remain clear of the commissioned module pad" % String(pad_id),
			failures,
		)
		_check(
			Office.campus_duty_face_point(pad_id).z > duty.z,
			"%s worker should face the staffed module instead of the perimeter" % String(pad_id),
			failures,
		)

	for worker_index in 6:
		for pad_id: StringName in PAD_IDS:
			var outbound: Array[Vector3] = [Office.chair_position(worker_index)]
			outbound.append_array(Office.campus_duty_outbound_route(worker_index, pad_id))
			var return_route: Array[Vector3] = [Office.campus_duty_position(pad_id)]
			return_route.append_array(Office.campus_duty_return_route(worker_index, pad_id))
			minimum_clearance = minf(
				minimum_clearance,
				_validate_route(outbound, blockers, worker_index, "%s outbound" % String(pad_id), failures),
			)
			minimum_clearance = minf(
				minimum_clearance,
				_validate_route(return_route, blockers, worker_index, "%s return" % String(pad_id), failures),
			)
			_check(
				outbound[outbound.size() - 1] == Office.campus_duty_position(pad_id),
				"worker %d %s outbound route should terminate at the exact duty socket" % [worker_index, String(pad_id)],
				failures,
			)
			_check(
				return_route[return_route.size() - 1] == Office.chair_position(worker_index),
				"worker %d %s return route should terminate at the assigned chair" % [worker_index, String(pad_id)],
				failures,
			)

	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPUS_PORTFOLIO_COMMUTE_LAYOUT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print(
		"CAMPUS_PORTFOLIO_COMMUTE_LAYOUT_TEST_PASSED workers=6 pads=4 routes=48 silhouette_radius=%.2f minimum_clearance=%.2f collisions=0"
		% [CHICKEN_SWEEP_RADIUS, minimum_clearance]
	)
	quit(0)


func _validate_route(
	route: Array[Vector3],
	blockers: Array[Dictionary],
	worker_index: int,
	label: String,
	failures: Array[String],
) -> float:
	var minimum_clearance := INF
	for segment_index in route.size() - 1:
		var start := route[segment_index]
		var finish := route[segment_index + 1]
		_check(
			is_equal_approx(start.x, finish.x) or is_equal_approx(start.z, finish.z),
			"worker %d %s segment %d must stay axis-aligned instead of cutting a corner"
			% [worker_index, label, segment_index],
			failures,
		)
		for blocker: Dictionary in blockers:
			var clearance := _segment_rect_distance(start, finish, blocker.get("footprint", Rect2()) as Rect2)
			minimum_clearance = minf(minimum_clearance, clearance)
			_check(
				clearance + 0.0001 >= CHICKEN_SWEEP_RADIUS,
				"worker %d %s clips the declared %s clearance on segment %d (%.3f m)"
				% [worker_index, label, String(blocker.get("name", "blocker")), segment_index, clearance],
				failures,
			)
		for desk_index in 6:
			var desk := Office.desk_position(desk_index)
			var desk_rect := Rect2(
				Vector2(desk.x, desk.z) - DESK_HALF_SIZE,
				DESK_HALF_SIZE * 2.0,
			)
			_check(
				_segment_rect_distance(start, finish, desk_rect) + 0.0001 >= DESK_NAVIGATION_RADIUS,
				"worker %d %s cuts through workstation %d" % [worker_index, label, desk_index],
				failures,
			)
	return minimum_clearance


func _declared_blockers() -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		{"name": "shell-QA", "footprint": ShellQualityLabVisualScript.declared_footprint()},
		{"name": "packing-annex", "footprint": PackingAnnexVisualScript.declared_footprint()},
		{"name": "records-annex", "footprint": RecordsAnnexVisualScript.declared_footprint()},
		{"name": "service-coop", "footprint": FarmMutualServiceCoopVisualScript.declared_footprint()},
		{"name": "negotiation-room", "footprint": FarmMutualNegotiationRoomVisualScript.declared_footprint()},
		{"name": "wellness-nest", "footprint": WellnessNestVisualScript.declared_footprint()},
		{"name": "training-roost", "footprint": TrainingRoostVisualScript.declared_footprint()},
		{"name": "farmer-relations", "footprint": FarmerRelationsGalleryVisualScript.declared_footprint()},
		{"name": "rooster-operations", "footprint": RoosterOperationsOfficeVisualScript.declared_footprint()},
		{"name": "IT-coop", "footprint": ITCoopVisualScript.declared_footprint()},
		{"name": "flock-relations", "footprint": FlockRelationsOfficeVisualScript.declared_footprint()},
		{"name": "feed-procurement", "footprint": FeedProcurementCoopVisualScript.declared_footprint()},
		{"name": "farmgate-depot", "footprint": FarmgateDispatchDepotVisualScript.declared_footprint()},
	]
	for socket: Dictionary in CampusExpansionVisualScript.socket_catalog():
		result.append({
			"name": "North Meadow %s" % String(socket.get("id", "socket")),
			"footprint": socket.get("footprint", Rect2()),
		})
	for pad: Dictionary in CampusPortfolioVisualScript.pad_catalog():
		result.append({
			"name": "portfolio %s" % String(pad.get("id", "pad")),
			"footprint": pad.get("footprint", Rect2()),
		})
	return result


func _parcel_cross_route(parcel_id: StringName) -> Rect2:
	for parcel: Dictionary in CampusPortfolioVisualScript.parcel_catalog():
		if StringName(String(parcel.get("id", ""))) == parcel_id:
			return parcel.get("cross_route", Rect2()) as Rect2
	return Rect2()


func _point_rect_distance(point: Vector2, footprint: Rect2) -> float:
	var dx := maxf(maxf(footprint.position.x - point.x, 0.0), point.x - footprint.end.x)
	var dz := maxf(maxf(footprint.position.y - point.y, 0.0), point.y - footprint.end.y)
	return Vector2(dx, dz).length()


func _segment_rect_distance(start: Vector3, finish: Vector3, footprint: Rect2) -> float:
	var start_x := minf(start.x, finish.x)
	var end_x := maxf(start.x, finish.x)
	var start_z := minf(start.z, finish.z)
	var end_z := maxf(start.z, finish.z)
	var dx := maxf(maxf(footprint.position.x - end_x, 0.0), start_x - footprint.end.x)
	var dz := maxf(maxf(footprint.position.y - end_z, 0.0), start_z - footprint.end.y)
	return Vector2(dx, dz).length()


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
