extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")

const TEST_SAVE_FILENAME := "office_physical_staging_test.json"
const CAPTURE_ARGUMENT := "--capture-office-capacities"
const CAPTURE_SIZE := Vector2i(2560, 1440)
const PARTITION_ROUTE_CLEARANCE := 0.70
const PRESENTATION_ROOT_NAME := "OfficePhysicalPresentation"
const PRESENTATION_CHILD_NAMES: Array[String] = [
	"CoreOfficePresentation",
	"DormantWestPresentation",
	"WestPerch04Presentation",
	"WestPerch05Presentation",
	"ArchivePresentation",
	"IntakePresentation",
]
const SNAPSHOT_KEYS: Array[String] = [
	"capacity",
	"stage",
	"core_visible",
	"dormant_west_visible",
	"west_perch_04_visible",
	"west_perch_05_visible",
	"archive_visible",
	"intake_visible",
	"next_perch_index",
]
const EXPECTED_DESK_POSITIONS: Array[Vector3] = [
	Vector3(0.0, 0.0, -2.8),
	Vector3(6.0, 0.0, -2.8),
	Vector3(0.0, 0.0, 3.0),
	Vector3(6.0, 0.0, 3.0),
	Vector3(-6.0, 0.0, -2.8),
	Vector3(-6.0, 0.0, 3.0),
]

var _stage := "boot"


func _init() -> void:
	create_timer(60.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var capture_capacities := CAPTURE_ARGUMENT in OS.get_cmdline_user_args()
	root.size = CAPTURE_SIZE if capture_capacities else Vector2i(1280, 720)
	var store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	store.delete()
	var office := Office.new()
	office.set("_campaign_store", store)
	root.add_child(office)
	await process_frame
	await process_frame
	await process_frame

	_stage = "discovering presentation contract"
	_check(
		office.has_method("office_physical_presentation_snapshot"),
		"Office should publish its physical presentation through office_physical_presentation_snapshot()",
		failures,
	)
	var presentation := office.find_child(PRESENTATION_ROOT_NAME, true, false) as Node3D
	_check(
		presentation != null and presentation.get_parent() == office,
		"OfficePhysicalPresentation should be one stable top-level Office child",
		failures,
	)
	var presentation_roots := _presentation_roots(office, presentation, failures)
	if not office.has_method("office_physical_presentation_snapshot") or presentation == null:
		await _finish(office, store, failures)
		return
	_check(
		presentation.visible and presentation.is_visible_in_tree(),
		"the top-level physical presentation root should remain active while its authored stages change",
		failures,
	)
	_check(
		presentation.find_children("*", "CollisionObject3D", true, false).is_empty()
		and presentation.find_children("*", "NavigationObstacle3D", true, false).is_empty(),
		"capacity presentation art must remain visual-only so it cannot block authored chicken routes",
		failures,
	)

	var workstations := _capture_workstations(office, failures)
	var workstation_instance_ids := _workstation_instance_ids(workstations)
	var original_routes := _route_snapshot()
	_assert_stable_desks_and_routes(
		office, workstations, workstation_instance_ids, original_routes, 4, failures,
	)

	_stage = "checking fresh core"
	var fresh := office.call("office_physical_presentation_snapshot") as Dictionary
	_assert_snapshot_schema(fresh, failures)
	_assert_presentation_state(
		fresh,
		presentation_roots,
		4,
		&"core",
		{
			"CoreOfficePresentation": true,
			"DormantWestPresentation": false,
			"WestPerch04Presentation": false,
			"WestPerch05Presentation": false,
			"ArchivePresentation": false,
			"IntakePresentation": true,
		},
		-1,
		failures,
	)
	var marker_04 := office.find_child("CapacityAuthorization_04", true, false) as Node3D
	var marker_05 := office.find_child("CapacityAuthorization_05", true, false) as Node3D
	var west_partition := office.find_child("WestLeasePartition", true, false) as Node3D
	var west_fill := office.find_child("FluorescentFill_0", true, false) as OmniLight3D
	var west_zone_04 := office.find_child("Zone_WestPerch04", true, false) as Node3D
	var west_zone_05 := office.find_child("Zone_WestPerch05", true, false) as Node3D
	var pipeline_board := office.find_child("ClaimsPipelineBoard", true, false) as Node3D
	var safety_notice := office.find_child("CoopSafetyLabel", true, false) as Node3D
	_check(
		marker_04 != null and not marker_04.is_visible_in_tree()
		and marker_05 != null and not marker_05.is_visible_in_tree(),
		"fresh orientation should show neither west-perch authorization marker",
		failures,
	)
	_check(
		west_fill != null and not west_fill.visible,
		"the unopened west wing should not cast a mature fluorescent pool into the opening pod",
		failures,
	)
	_check(
		west_partition != null
		and west_partition.is_visible_in_tree()
		and bool(west_partition.get_meta(&"visual_only", false))
		and west_partition.find_children("*", "CollisionObject3D", true, false).is_empty(),
		"capacity four should close the vacant west carpet with one visual-only lease partition",
		failures,
	)
	if west_partition != null:
		_assert_partition_route_clearance(west_partition, failures)
	_check(
		west_zone_04 != null and not west_zone_04.is_visible_in_tree()
		and west_zone_05 != null and not west_zone_05.is_visible_in_tree(),
		"fresh orientation should keep both west laying-zone outlines uncommissioned",
		failures,
	)
	_check(
		pipeline_board != null and not pipeline_board.is_visible_in_tree()
		and safety_notice != null
		and presentation_roots.get("CoreOfficePresentation") is Node3D
		and (presentation_roots.get("CoreOfficePresentation") as Node3D).is_ancestor_of(safety_notice)
		and safety_notice.get_parent() is Node3D
		and (safety_notice.get_parent() as Node3D).is_visible_in_tree(),
		"opening staging should defer the mature pipeline board but keep aisle safety attached to its route",
		failures,
	)

	_stage = "checking contextual next perch"
	office.call("_reveal_capacity_marker_context")
	await process_frame
	var contextual_four := office.call("office_physical_presentation_snapshot") as Dictionary
	_assert_presentation_state(
		contextual_four,
		presentation_roots,
		4,
		&"core",
		{
			"CoreOfficePresentation": true,
			"DormantWestPresentation": true,
			"WestPerch04Presentation": false,
			"WestPerch05Presentation": false,
			"ArchivePresentation": false,
			"IntakePresentation": true,
		},
		4,
		failures,
	)
	_check(
		marker_04 != null and marker_04.is_visible_in_tree()
		and marker_05 != null and not marker_05.is_visible_in_tree(),
		"staffing context should preview exactly perch 04 without disclosing perch 05",
		failures,
	)
	_assert_stable_desks_and_routes(
		office, workstations, workstation_instance_ids, original_routes, 4, failures,
	)

	_stage = "checking capacity five"
	office.call("_apply_office_capacity_visibility", 5, false)
	await process_frame
	west_zone_04 = office.find_child("Zone_WestPerch04", true, false) as Node3D
	west_zone_05 = office.find_child("Zone_WestPerch05", true, false) as Node3D
	var capacity_five := office.call("office_physical_presentation_snapshot") as Dictionary
	_assert_presentation_state(
		capacity_five,
		presentation_roots,
		5,
		&"west_front",
		{
			"CoreOfficePresentation": true,
			"DormantWestPresentation": true,
			"WestPerch04Presentation": true,
			"WestPerch05Presentation": false,
			"ArchivePresentation": false,
			"IntakePresentation": true,
		},
		5,
		failures,
	)
	_check(
		marker_04 != null and not marker_04.is_visible_in_tree()
		and marker_05 != null and marker_05.is_visible_in_tree(),
		"capacity five should retire perch 04 staging and preview exactly perch 05",
		failures,
	)
	_check(
		west_fill != null and west_fill.visible and west_fill.light_energy > 0.0,
		"commissioning perch 04 should power the west fluorescent pool immediately",
		failures,
	)
	_check(
		west_partition != null and not west_partition.is_visible_in_tree(),
		"commissioning perch 04 should remove the temporary west lease partition",
		failures,
	)
	_check(
		west_zone_04 != null and west_zone_04.is_visible_in_tree()
		and west_zone_05 != null and not west_zone_05.is_visible_in_tree()
		and pipeline_board != null and not pipeline_board.is_visible_in_tree(),
		"capacity five should commission only the first west laying zone",
		failures,
	)
	_assert_stable_desks_and_routes(
		office, workstations, workstation_instance_ids, original_routes, 5, failures,
	)

	_stage = "checking full bureau"
	office.call("_apply_office_capacity_visibility", 6, false)
	await process_frame
	west_zone_04 = office.find_child("Zone_WestPerch04", true, false) as Node3D
	west_zone_05 = office.find_child("Zone_WestPerch05", true, false) as Node3D
	var capacity_six := office.call("office_physical_presentation_snapshot") as Dictionary
	_assert_presentation_state(
		capacity_six,
		presentation_roots,
		6,
		&"full_bureau",
		{
			"CoreOfficePresentation": true,
			"DormantWestPresentation": false,
			"WestPerch04Presentation": true,
			"WestPerch05Presentation": true,
			"ArchivePresentation": true,
			"IntakePresentation": true,
		},
		-1,
		failures,
	)
	_check(
		marker_04 != null and not marker_04.is_visible_in_tree()
		and marker_05 != null and not marker_05.is_visible_in_tree(),
		"the six-perch bureau should retire every next-perch preview",
		failures,
	)
	_check(
		west_partition != null and not west_partition.is_visible_in_tree(),
		"the full bureau should keep the temporary west partition retired",
		failures,
	)
	_check(
		west_zone_04 != null and west_zone_04.is_visible_in_tree()
		and west_zone_05 != null and west_zone_05.is_visible_in_tree()
		and pipeline_board != null and pipeline_board.is_visible_in_tree(),
		"the full bureau should complete both west zones and its clutch-flow board",
		failures,
	)
	_assert_stable_desks_and_routes(
		office, workstations, workstation_instance_ids, original_routes, 6, failures,
	)

	_stage = "checking monotonic permanent reveal"
	var core_permanent := _permanent_visible_roots(fresh)
	var five_permanent := _permanent_visible_roots(capacity_five)
	var six_permanent := _permanent_visible_roots(capacity_six)
	_check(
		_is_subset(core_permanent, five_permanent)
		and _is_subset(five_permanent, six_permanent)
		and core_permanent.size() == 2
		and five_permanent.size() == 3
		and six_permanent.size() == 5,
		"permanent physical space should reveal monotonically as core 2, west-front 3, and full-bureau 5 roots",
		failures,
	)

	# The public dictionary is an observation seam. Mutating a caller-owned copy
	# must never modify the physical presentation authority inside Office.
	capacity_six["capacity"] = 99
	capacity_six["west_perch_05_visible"] = false
	var detached_check := office.call("office_physical_presentation_snapshot") as Dictionary
	_check(
		int(detached_check.get("capacity", -1)) == 6
		and bool(detached_check.get("west_perch_05_visible", false)),
		"physical presentation snapshots should be detached from caller mutation",
		failures,
	)
	if capture_capacities and failures.is_empty():
		_stage = "capturing capacity baselines"
		await _capture_capacity_sequence(office, failures)

	await _finish(office, store, failures)


func _capture_capacity_sequence(office: Office, failures: Array[String]) -> void:
	office.call("_hide_world_capture_overlays")
	office.call("_set_capacity_marker_context_revealed", false)
	var camera := office.get("_camera_controller") as ManagementCameraController
	_check(camera != null, "capacity capture requires the real management camera controller", failures)
	if camera == null:
		return
	camera.set_reduced_motion(true)
	var capture_directory := ProjectSettings.globalize_path(
		"res://output/office-capacity-visual"
	)
	DirAccess.make_dir_recursive_absolute(capture_directory)
	for capacity: int in [4, 5, 6]:
		office.call("_apply_office_capacity_visibility", capacity, false)
		camera.set_overview_bounds(
			Office.office_camera_bounds(capacity),
			4.0,
			Office.CAMPUS_PRESENTATION_MARGIN_RATIO,
			Office.office_overview_minimum_size(capacity),
		)
		camera.show_overview()
		await process_frame
		await process_frame
		var image := root.get_texture().get_image()
		var file_name := "office-capacity-%d-%dx%d.png" % [
			capacity,
			CAPTURE_SIZE.x,
			CAPTURE_SIZE.y,
		]
		_check(image != null, "%s should provide a rendered viewport image" % file_name, failures)
		if image == null:
			continue
		_check(
			image.get_size() == CAPTURE_SIZE,
			"%s should retain the exact native comparison size (saw %s)" % [
				file_name,
				str(image.get_size()),
			],
			failures,
		)
		var save_error := image.save_png(capture_directory.path_join(file_name))
		_check(
			save_error == OK,
			"%s should save successfully (error %d)" % [file_name, save_error],
			failures,
		)


func _presentation_roots(
	office: Office,
	presentation: Node3D,
	failures: Array[String]
) -> Dictionary:
	var result: Dictionary = {}
	for root_name: String in PRESENTATION_CHILD_NAMES:
		var matches := office.find_children(root_name, "Node3D", true, false)
		_check(
			matches.size() == 1,
			"%s should exist exactly once" % root_name,
			failures,
		)
		var stage_root := matches[0] as Node3D if matches.size() == 1 else null
		_check(
			stage_root != null and presentation != null and stage_root.get_parent() == presentation,
			"%s should be a direct OfficePhysicalPresentation child" % root_name,
			failures,
		)
		result[root_name] = stage_root
	return result


func _capture_workstations(office: Office, failures: Array[String]) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for desk_index in EXPECTED_DESK_POSITIONS.size():
		var workstation_name := "Workstation_%02d" % desk_index
		var matches := office.find_children(workstation_name, "Node3D", true, false)
		_check(
			matches.size() == 1,
			"stable desk %d should retain exactly one %s node" % [desk_index, workstation_name],
			failures,
		)
		result.append(matches[0] as Node3D if matches.size() == 1 else null)
	return result


func _workstation_instance_ids(workstations: Array[Node3D]) -> Array[int]:
	var result: Array[int] = []
	for workstation: Node3D in workstations:
		result.append(workstation.get_instance_id() if workstation != null else -1)
	return result


func _assert_stable_desks_and_routes(
	office: Office,
	workstations: Array[Node3D],
	instance_ids: Array[int],
	original_routes: Dictionary,
	expected_capacity: int,
	failures: Array[String]
) -> void:
	for desk_index in EXPECTED_DESK_POSITIONS.size():
		var workstation := workstations[desk_index]
		var expected_position := EXPECTED_DESK_POSITIONS[desk_index]
		_check(
			Office.desk_position(desk_index).is_equal_approx(expected_position),
			"desk %d should retain its stable simulation socket %s" % [desk_index, str(expected_position)],
			failures,
		)
		_check(
			workstation != null
			and workstation.get_instance_id() == instance_ids[desk_index]
			and workstation.global_position.is_equal_approx(expected_position),
			"capacity staging should preserve workstation %02d identity and world transform" % desk_index,
			failures,
		)
		_check(
			workstation != null and workstation.is_visible_in_tree() == (desk_index < expected_capacity),
			"capacity %d should expose exactly the stable desk prefix through index %d" % [
				expected_capacity,
				expected_capacity - 1,
			],
			failures,
		)
	_check(
		_route_snapshot() == original_routes,
		"core, west-front, and full-bureau presentation changes must not rewrite any chicken route",
		failures,
	)
	_assert_route_endpoints_and_bounds(failures)


func _route_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for worker_index in EXPECTED_DESK_POSITIONS.size():
		result[worker_index] = {
			"arrival": Office.arrival_route(worker_index),
			"departure": Office.departure_route(worker_index),
			"wellness": Office.wellness_route(worker_index),
			"feed_party": Office.feed_party_route(worker_index),
		}
	return result


func _assert_route_endpoints_and_bounds(failures: Array[String]) -> void:
	for worker_index in EXPECTED_DESK_POSITIONS.size():
		var chair := Office.chair_position(worker_index)
		var arrival := Office.arrival_route(worker_index)
		var departure := Office.departure_route(worker_index)
		var chair_access := Vector3(Office.access_lane_x(worker_index), 0.0, chair.z)
		_check(
			not arrival.is_empty() and arrival[arrival.size() - 1].is_equal_approx(chair)
			and arrival.size() >= 2 and arrival[arrival.size() - 2].is_equal_approx(chair_access)
			and not departure.is_empty() and departure[0].is_equal_approx(chair_access),
			"worker %d arrival and departure should remain joined through its stable chair-access point" % worker_index,
			failures,
		)
		for route: Array[Vector3] in [
			arrival,
			departure,
			Office.wellness_route(worker_index),
			Office.feed_party_route(worker_index),
		]:
			for point: Vector3 in route:
				_check(
					absf(point.x) <= 11.5 and absf(point.z) <= 8.5,
					"worker %d route point %s should remain inside the authored office margins" % [
						worker_index,
						str(point),
					],
					failures,
				)


func _assert_partition_route_clearance(
	partition: Node3D,
	failures: Array[String]
) -> void:
	var expanded_barriers: Array[Rect2] = []
	for piece_value in partition.find_children("*", "MeshInstance3D", true, false):
		var piece := piece_value as MeshInstance3D
		var box := piece.mesh as BoxMesh if piece != null else null
		_check(box != null, "lease-partition pieces should use bounded box geometry", failures)
		if box == null:
			continue
		expanded_barriers.append(
			Rect2(
				Vector2(
					piece.global_position.x - box.size.x * 0.5,
					piece.global_position.z - box.size.z * 0.5,
				),
				Vector2(box.size.x, box.size.z),
			).grow(PARTITION_ROUTE_CLEARANCE)
		)
	for worker_index in 4:
		var arrival := Office.arrival_route(worker_index)
		arrival.push_front(Office.entry_position(worker_index))
		var departure := Office.departure_route(worker_index)
		departure.push_front(Office.chair_position(worker_index))
		var wellness := Office.wellness_route(worker_index)
		wellness.push_front(Office.chair_position(worker_index))
		var feed_party := Office.feed_party_route(worker_index)
		feed_party.push_front(Office.chair_position(worker_index))
		var route_entries: Array[Dictionary] = [
			{"label": "arrival", "points": arrival},
			{"label": "departure", "points": departure},
			{"label": "wellness", "points": wellness},
			{"label": "feed party", "points": feed_party},
			{
				"label": "feed party return",
				"points": Office.feed_party_return_route(worker_index),
			},
		]
		for route_entry: Dictionary in route_entries:
			var points := route_entry.get("points", []) as Array[Vector3]
			for point_index in range(1, points.size()):
				var from := Vector2(points[point_index - 1].x, points[point_index - 1].z)
				var to := Vector2(points[point_index].x, points[point_index].z)
				for barrier: Rect2 in expanded_barriers:
					_check(
						not _segment_intersects_rect(from, to, barrier),
						"worker %d %s route should clear the temporary partition by %.2f m" % [
							worker_index,
							String(route_entry.get("label", "office")),
							PARTITION_ROUTE_CLEARANCE,
						],
						failures,
					)


func _segment_intersects_rect(from: Vector2, to: Vector2, rect: Rect2) -> bool:
	if rect.has_point(from) or rect.has_point(to):
		return true
	var corners: Array[Vector2] = [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	]
	for corner_index in corners.size():
		var next_index := (corner_index + 1) % corners.size()
		if Geometry2D.segment_intersects_segment(
			from,
			to,
			corners[corner_index],
			corners[next_index],
		) != null:
			return true
	return false


func _assert_snapshot_schema(snapshot: Dictionary, failures: Array[String]) -> void:
	for key: String in SNAPSHOT_KEYS:
		_check(snapshot.has(key), "physical presentation snapshot should include %s" % key, failures)


func _assert_presentation_state(
	snapshot: Dictionary,
	roots: Dictionary,
	expected_capacity: int,
	expected_stage: StringName,
	expected_visibility: Dictionary,
	expected_next_perch_index: int,
	failures: Array[String]
) -> void:
	_assert_snapshot_schema(snapshot, failures)
	_check(
		int(snapshot.get("capacity", -1)) == expected_capacity
		and StringName(snapshot.get("stage", &"")) == expected_stage
		and int(snapshot.get("next_perch_index", -2)) == expected_next_perch_index,
		"capacity %d should publish stage %s and next perch %d" % [
			expected_capacity,
			String(expected_stage),
			expected_next_perch_index,
		],
		failures,
	)
	var snapshot_keys_by_root := {
		"CoreOfficePresentation": "core_visible",
		"DormantWestPresentation": "dormant_west_visible",
		"WestPerch04Presentation": "west_perch_04_visible",
		"WestPerch05Presentation": "west_perch_05_visible",
		"ArchivePresentation": "archive_visible",
		"IntakePresentation": "intake_visible",
	}
	for root_name: String in PRESENTATION_CHILD_NAMES:
		var expected := bool(expected_visibility.get(root_name, false))
		var snapshot_key := String(snapshot_keys_by_root[root_name])
		var stage_root := roots.get(root_name) as Node3D
		_check(
			bool(snapshot.get(snapshot_key, not expected)) == expected,
			"%s should report %s at capacity %d" % [snapshot_key, str(expected), expected_capacity],
			failures,
		)
		_check(
			stage_root != null
			and stage_root.visible == expected
			and stage_root.is_visible_in_tree() == expected,
			"%s scene visibility should match its capacity-%d public snapshot" % [
				root_name,
				expected_capacity,
			],
			failures,
		)


func _permanent_visible_roots(snapshot: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for entry: Array in [
		["CoreOfficePresentation", "core_visible"],
		["WestPerch04Presentation", "west_perch_04_visible"],
		["WestPerch05Presentation", "west_perch_05_visible"],
		["ArchivePresentation", "archive_visible"],
		["IntakePresentation", "intake_visible"],
	]:
		if bool(snapshot.get(String(entry[1]), false)):
			result.append(String(entry[0]))
	return result


func _is_subset(subset: Array[String], superset: Array[String]) -> bool:
	for value: String in subset:
		if value not in superset:
			return false
	return true


func _finish(office: Office, store: Variant, failures: Array[String]) -> void:
	if office != null and is_instance_valid(office):
		office.free()
	await process_frame
	store.delete()
	if not failures.is_empty():
		for failure: String in failures:
			push_error("OFFICE_PHYSICAL_STAGING_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OFFICE_PHYSICAL_STAGING_TEST_PASSED roots=6 stages=core+west_front+full_bureau preview=contextual desks=stable routes=stable")
	quit(0)


func _on_watchdog_timeout() -> void:
	push_error("OFFICE_PHYSICAL_STAGING_TEST_TIMEOUT: %s" % _stage)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
