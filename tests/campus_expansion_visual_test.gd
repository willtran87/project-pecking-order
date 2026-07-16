extends SceneTree

const CampusExpansionVisualScript := preload("res://features/office/campus_expansion_visual.gd")
const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var visual := CampusExpansionVisualScript.new() as CampusExpansionVisual
	root.add_child(visual)
	await process_frame

	_check(
		CampusExpansionVisualScript.declared_footprint()
		== Rect2(Vector2(18.65, 3.10), Vector2(12.80, 11.80)),
		"North Meadow should retain the exact parcel directly north of Farmgate Depot",
		failures,
	)
	_check(
		CampusExpansionVisualScript.navigation_footprint({})
		== Rect2(Vector2(19.10, 3.35), Vector2(11.90, 2.10)),
		"North Meadow should publish its unobstructed southern circulation spine",
		failures,
	)
	var sockets := CampusExpansionVisualScript.socket_catalog()
	_check(sockets.size() == 3, "North Meadow should publish exactly three authored sockets", failures)
	_check(
		_socket_ids(sockets) == [&"meadow_west", &"meadow_east", &"service_spine"],
		"socket order and stable IDs should remain deterministic",
		failures,
	)
	_check(
		not bool(sockets[0].get("route_blocked", true))
		and not bool(sockets[1].get("route_blocked", true))
		and bool(sockets[2].get("route_blocked", false)),
		"only the service spine should be route-blocked",
		failures,
	)
	_check(
		(sockets[0].get("allowed_pod_ids", []) as Array) == [&"egg_routing_pod"]
		and (sockets[1].get("allowed_pod_ids", []) as Array) == [&"egg_routing_pod"]
		and (sockets[2].get("allowed_pod_ids", []) as Array).is_empty(),
		"Egg Routing Pod should be authorized only at Meadow West or Meadow East",
		failures,
	)

	var locked := visual.find_child("NorthMeadowLockedStage", true, false) as Node3D
	var survey := visual.find_child("NorthMeadowSurveyStage", true, false) as Node3D
	var utilities := visual.find_child("NorthMeadowUtilitiesStage", true, false) as Node3D
	var trenches := visual.find_child("NorthMeadowOpenUtilityTrenches", true, false) as Node3D
	var ready := visual.find_child("NorthMeadowReadyStage", true, false) as Node3D
	var pod := visual.find_child("EggRoutingPod", true, false) as Node3D
	_check(
		locked != null and locked.visible
		and survey != null and not survey.visible
		and utilities != null and not utilities.visible
		and ready != null and not ready.visible
		and pod != null and not pod.visible,
		"fresh North Meadow should expose only its locked construction stage",
		failures,
	)

	for socket_id in [&"meadow_west", &"meadow_east", &"service_spine"]:
		var socket_root := visual.find_child("NorthMeadowSocket_%s" % String(socket_id), true, false) as Node3D
		_check(socket_root != null, "%s should have an obvious physical socket" % socket_id, failures)
		if socket_root != null:
			_check(StringName(socket_root.get_meta(&"socket_id", &"")) == socket_id, "%s should retain its stable socket metadata" % socket_id, failures)
	var blocked_root := visual.find_child("NorthMeadowSocket_service_spine", true, false) as Node3D
	_check(blocked_root != null and bool(blocked_root.get_meta(&"route_blocked", false)), "Service Spine should carry permanent blocked-route metadata", failures)
	_check(visual.find_children("ServiceSpineBlockCrossbar_*", "MeshInstance3D", true, false).size() == 2, "Service Spine should carry an unmistakable modeled X barrier", failures)
	_assert_integrated_signage(visual, failures)

	visual.apply_snapshot({
		"campus_expansion": {
			"unlocked": true,
			"construction_stage": &"survey",
		},
	})
	_check(not locked.visible and survey.visible and not utilities.visible and not ready.visible, "survey snapshot should reveal only survey staging", failures)
	_check(visual.find_children("MeadowSurveyStake_*", "MeshInstance3D", true, false).size() == 12, "survey stage should stake all three socket envelopes", failures)

	visual.apply_snapshot({
		"campus_expansion": {
			"construction_stage": &"utilities",
			"utilities": {
				"circulation": true,
				"power": false,
				"cold_chain": true,
			},
		},
	})
	_check(not survey.visible and utilities.visible and trenches.visible and not ready.visible, "utilities snapshot should expose attached services and open trenches", failures)
	_assert_utility_assembly(visual, "CirculationUtilityAssembly", "CirculationRouteLine", "CirculationCounterMeter", failures)
	_assert_utility_assembly(visual, "PowerUtilityAssembly", "PowerConduitLine", "PowerServiceMeter", failures)
	_assert_utility_assembly(visual, "ColdChainUtilityAssembly", "ColdChainSupplyLine", "ColdChainPressureMeter", failures)
	var circulation_status := visual.find_child("CirculationCounterMeterStatus", true, false) as Label3D
	var power_status := visual.find_child("PowerServiceMeterStatus", true, false) as Label3D
	var cold_status := visual.find_child("ColdChainPressureMeterStatus", true, false) as Label3D
	_check(circulation_status != null and "LIVE" in circulation_status.text, "circulation meter should mirror its live snapshot", failures)
	_check(power_status != null and "HELD" in power_status.text, "power meter should mirror its held snapshot", failures)
	_check(cold_status != null and "LIVE" in cold_status.text, "cold-chain meter should mirror its live snapshot", failures)

	var west_snapshot := _ready_snapshot(&"meadow_west")
	visual.apply_snapshot(west_snapshot)
	var west_socket := visual.find_child("NorthMeadowSocket_meadow_west", true, false) as Node3D
	_check(utilities.visible and not trenches.visible and ready.visible, "ready stage should retain finished utilities and close its trenches", failures)
	_check(pod.visible and pod.position.is_equal_approx(west_socket.position), "Egg Routing Pod should occupy Meadow West exactly", failures)
	_check(StringName(pod.get_meta(&"socket_id", &"")) == &"meadow_west", "west placement should publish stable pod socket metadata", failures)
	var pod_identity := visual.find_child("EggRoutingPodIdentityFixture", true, false) as Node3D
	_check(pod_identity != null and bool(pod_identity.get_meta(&"host_attached", false)), "Egg Routing Pod identity should remain attached to its modeled fascia", failures)

	var east_snapshot := _ready_snapshot(&"meadow_east")
	visual.apply_snapshot(east_snapshot)
	var east_socket := visual.find_child("NorthMeadowSocket_meadow_east", true, false) as Node3D
	_check(pod.visible and pod.position.is_equal_approx(east_socket.position), "Egg Routing Pod should relocate cleanly to Meadow East", failures)
	_check(not pod.position.is_equal_approx(west_socket.position), "east placement should not leave a duplicate pod at Meadow West", failures)

	visual.apply_snapshot({
		"campus_expansion": {
			"construction_stage": &"ready",
			"placements": {"egg_routing_pod": &"service_spine"},
			"blocked_reason": "cold-chain service easement",
		},
	})
	var blocked_heading := visual.find_child("SocketMarker_service_spine", true, false) as Label3D
	var blocked_copy := visual.find_child("SocketMarker_service_spineBody", true, false) as Label3D
	_check(not pod.visible and StringName(pod.get_meta(&"socket_id", &"invalid")) == &"", "blocked Service Spine must reject visual pod placement", failures)
	_check(blocked_heading != null and "KEEP CLEAR" in blocked_heading.text, "Service Spine should carry one readable KEEP CLEAR heading", failures)
	_check(blocked_copy != null and "ROUTE BLOCKED" in blocked_copy.text and "COLD-CHAIN SERVICE EASEMENT" in blocked_copy.text, "blocked socket should explain its farm-service easement on its attached marker", failures)

	_check(visual.find_children("*", "CollisionObject3D", true, false).is_empty(), "North Meadow should add no collision objects", failures)
	_check(visual.find_children("*", "NavigationRegion3D", true, false).is_empty(), "North Meadow should add no navigation regions", failures)
	_check(visual.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "North Meadow should add no navigation obstacles", failures)
	_check(visual.find_children("*", "CSGShape3D", true, false).is_empty(), "North Meadow should use final primitive meshes rather than runtime CSG", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPUS_EXPANSION_VISUAL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_EXPANSION_VISUAL_TEST_PASSED parcel=north-meadow sockets=west-east-service pod=A-or-B service=C-blocked utilities=attached stages=4 collisions=0")
	quit(0)


func _ready_snapshot(socket_id: StringName) -> Dictionary:
	return {
		"campus_expansion": {
			"construction_stage": &"ready",
			"utilities": {
				"circulation": true,
				"power": true,
				"cold_chain": true,
			},
			"placements": {"egg_routing_pod": socket_id},
		},
	}


func _socket_ids(catalog: Array[Dictionary]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for socket in catalog:
		ids.append(StringName(socket.get("id", &"")))
	return ids


func _assert_utility_assembly(
	visual: CampusExpansionVisual,
	assembly_name: String,
	line_name: String,
	meter_name: String,
	failures: Array[String],
) -> void:
	var assembly := visual.find_child(assembly_name, true, false) as Node3D
	_check(assembly != null, "%s should exist" % assembly_name, failures)
	if assembly == null:
		return
	_check(bool(assembly.get_meta(&"host_attached", false)), "%s should publish attached utility hardware" % assembly_name, failures)
	_check(assembly.find_child(line_name, true, false) != null, "%s should retain its physical line" % assembly_name, failures)
	_check(assembly.find_child(meter_name, true, false) != null, "%s should retain its physical meter" % assembly_name, failures)


func _assert_integrated_signage(visual: CampusExpansionVisual, failures: Array[String]) -> void:
	var identity_gate := visual.find_child("NorthMeadowIdentityGate", true, false) as Node3D
	var identity_host := visual.find_child("NorthMeadowIdentityHost", true, false) as MeshInstance3D
	var identity_fixture := visual.find_child("NorthMeadowIdentityFixture", true, false) as Node3D
	_check(identity_gate != null and bool(identity_gate.get_meta(&"ground_supported", false)), "North Meadow identity should be a ground-supported gate assembly", failures)
	_check(visual.find_children("NorthMeadowIdentityPost_*", "MeshInstance3D", true, false).size() == 2, "North Meadow identity should stand on two visible timber posts", failures)
	_check(identity_host != null and bool(identity_host.get_meta(&"routed_timber_gate_sign", false)), "North Meadow identity should use its routed timber face instead of a giant panel", failures)
	_check(identity_fixture != null and identity_fixture.get_parent() == identity_host, "North Meadow identity fixture should remain attached to the routed gate face", failures)
	_check(identity_fixture != null and identity_fixture.position.z > 0.0 and is_zero_approx(identity_fixture.rotation_degrees.y), "North Meadow identity copy should occupy the camera-facing gate surface", failures)
	var deed_plate := visual.find_child("NorthMeadowDeedPlateHost", true, false) as MeshInstance3D
	var deed_fixture := visual.find_child("NorthMeadowDeedPlateFixture", true, false) as Node3D
	_check(deed_plate != null and deed_plate.get_parent() == identity_host, "campus filing copy should live on a small deed plate attached to the gate", failures)
	_check(deed_fixture != null and deed_fixture.get_parent() == deed_plate, "deed copy should remain physically attached to its brass plate", failures)
	_check(deed_plate != null and deed_plate.position.z > 0.0, "deed plate should share the camera-facing gate surface", failures)

	var stage_host := visual.find_child("NorthMeadowStageLedgerHost", true, false) as MeshInstance3D
	var stage_label := visual.find_child("NorthMeadowStageLedger", true, false) as Label3D
	_check(stage_host != null and bool(stage_host.get_meta(&"clipboard_permit", false)), "North Meadow stage should use a clipboard-sized permit", failures)
	_check(stage_host != null and stage_host.get_parent() is MeshInstance3D and bool(stage_host.get_parent().get_meta(&"permit_support_rail", false)), "stage permit should be clipped directly to a physical fence rail", failures)
	_check(stage_host != null and stage_host.position.z > 0.0, "stage permit should be clipped to the camera-facing side of its fence rail", failures)
	var permit_paper := visual.find_child("NorthMeadowStagePermitPaper", true, false) as MeshInstance3D
	_check(permit_paper != null and permit_paper.get_parent() == stage_host and bool(permit_paper.get_meta(&"permit_document", false)), "stage copy should be printed on one physical sheet carried by the clipboard", failures)
	var stage_fixture := visual.find_child("NorthMeadowStageLedgerFixture", true, false) as Node3D
	_check(stage_fixture != null and StringName(stage_fixture.get_meta(&"style_family", &"")) == &"surface_stencil" and StringName(stage_fixture.get_meta(&"copy_band", &"")) == &"detail", "stage status should use direct focus/detail copy on its paper", failures)
	if stage_label != null:
		EnvironmentalSignageScript.set_camera_detail(visual, false, Vector3(INF, INF, INF), 2.75, false)
		_check(not stage_label.visible, "stage permit glyphs should recede from the office overview", failures)
		EnvironmentalSignageScript.set_camera_detail(visual, true, stage_label.global_position, 2.75, false)
		_check(stage_label.visible, "stage permit glyphs should return when North Meadow is inspected", failures)

	for socket_id in [&"meadow_west", &"meadow_east", &"service_spine"]:
		var marker_host := visual.find_child("SocketMarkerHost_%s" % String(socket_id), true, false) as MeshInstance3D
		_check(marker_host != null and bool(marker_host.get_meta(&"ground_inlay", false)), "%s marker should be a ground inlay" % socket_id, failures)
		_check(marker_host != null and marker_host.get_parent() is MeshInstance3D and String(marker_host.get_parent().name) == "SocketPad_%s" % String(socket_id), "%s ground marker should be physically parented to its socket pad" % socket_id, failures)
		if marker_host != null and marker_host.mesh is BoxMesh:
			_check((marker_host.mesh as BoxMesh).size.y <= 0.02, "%s marker should remain flush with the ground" % socket_id, failures)
	var keep_clear_plate := visual.find_child("ServiceSpineKeepClearPlateHost", true, false) as MeshInstance3D
	var keep_clear_fixture := visual.find_child("SocketMarker_service_spineFixture", true, false) as Node3D
	var keep_clear_heading := visual.find_child("SocketMarker_service_spine", true, false) as Label3D
	var keep_clear_reason := visual.find_child("SocketMarker_service_spineBody", true, false) as Label3D
	_check(keep_clear_plate != null and bool(keep_clear_plate.get_meta(&"physically_attached_to_service_spine", false)), "KEEP CLEAR plate should publish its Service Spine attachment", failures)
	_check(keep_clear_plate != null and keep_clear_plate.get_parent() is MeshInstance3D and String(keep_clear_plate.get_parent().name).begins_with("ServiceSpineBlockCrossbar_"), "KEEP CLEAR plate should be a child of the modeled barrier", failures)
	_check(keep_clear_fixture != null and keep_clear_fixture.get_parent() == keep_clear_plate, "KEEP CLEAR copy should remain attached to its one physical plate", failures)
	EnvironmentalSignageScript.set_camera_detail(visual, false, Vector3(INF, INF, INF), 2.75, false)
	_check(keep_clear_heading != null and keep_clear_heading.visible, "permanent KEEP CLEAR safety heading should remain visible in the parcel overview", failures)
	_check(keep_clear_reason != null and not keep_clear_reason.visible, "Service Spine easement reason should remain close-focus detail", failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
