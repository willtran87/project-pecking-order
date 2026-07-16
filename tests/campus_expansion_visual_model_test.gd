extends SceneTree

const CampusExpansionVisualScript := preload("res://features/office/campus_expansion_visual.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var visual := CampusExpansionVisualScript.new() as CampusExpansionVisual
	root.add_child(visual)
	await process_frame

	var locked_bounds := CampusExpansionVisualScript.camera_bounds({})
	var ready_without_pod := CampusExpansionVisualScript.camera_bounds({
		"campus_expansion": {"construction_stage": &"ready"},
	})
	var ready_with_pod := CampusExpansionVisualScript.camera_bounds({
		"campus_expansion": {
			"construction_stage": &"ready",
			"placements": {"egg_routing_pod": &"meadow_west"},
		},
	})
	_check(locked_bounds.position == Vector3(18.65, -0.18, 3.10), "camera bounds should begin at the exact parcel corner", failures)
	_check(is_equal_approx(locked_bounds.size.x, 12.80) and is_equal_approx(locked_bounds.size.z, 11.80), "camera bounds should retain the exact parcel plan", failures)
	_check(ready_without_pod.size.y > locked_bounds.size.y, "ready landscaping should expand the staged camera height", failures)
	_check(is_equal_approx(ready_with_pod.end.y, 4.25), "a routed pod should publish the exact 4.25m camera envelope", failures)

	var navigation_locked := CampusExpansionVisualScript.navigation_footprint({})
	var navigation_west := CampusExpansionVisualScript.navigation_footprint({
		"campus_expansion": {
			"construction_stage": &"ready",
			"placements": {"egg_routing_pod": &"meadow_west"},
		},
	})
	_check(navigation_locked == navigation_west, "socket placement must never move the reserved circulation spine", failures)
	_check(_rect_inside(navigation_locked, CampusExpansionVisualScript.declared_footprint()), "navigation footprint should remain inside North Meadow", failures)

	visual.apply_snapshot({"campus_expansion": "invalid"})
	var locked := visual.find_child("NorthMeadowLockedStage", true, false) as Node3D
	var pod := visual.find_child("EggRoutingPod", true, false) as Node3D
	_check(locked.visible and not pod.visible, "malformed projection should fail closed to a locked empty parcel", failures)

	var ready_snapshot := {
		"campus_expansion": {
			"construction_stage": 3,
			"utilities": {"circulation": true, "power": true, "cold_chain": true},
			"egg_routing_pod": {"socket_id": &"meadow_east"},
		},
	}
	visual.apply_snapshot(ready_snapshot)
	var child_count := visual.find_children("*", "", true, false).size()
	var pod_position := pod.position
	visual.apply_snapshot(ready_snapshot)
	_check(visual.find_children("*", "", true, false).size() == child_count, "idempotent snapshots must not rebuild or duplicate meadow art", failures)
	_check(pod.position.is_equal_approx(pod_position), "idempotent snapshots should preserve the exact pod transform", failures)

	visual.apply_snapshot({
		"campus_expansion": {
			"stage": &"operational",
			"services": {
				"circulation": {"connected": true},
				"power": {"active": false},
				"cold_chain": {"ready": true},
			},
			"routing_pod": {"pod_socket_id": &"meadow_west"},
		},
	})
	var west_socket := visual.find_child("NorthMeadowSocket_meadow_west", true, false) as Node3D
	var power_status := visual.find_child("PowerServiceMeterStatus", true, false) as Label3D
	_check(pod.visible and west_socket != null and pod.position.is_equal_approx(west_socket.position), "authoritative routing_pod/pod_socket_id aliases should place at Meadow West", failures)
	_check(power_status != null and "HELD" in power_status.text, "dictionary service records should preserve an explicitly inactive power meter", failures)
	# Restore the canonical ready fixture for bounds and visible-budget checks.
	visual.apply_snapshot(ready_snapshot)

	_check(_all_meshes_inside_declared_footprint(visual), "every primitive mesh should remain inside the exact North Meadow parcel", failures)
	_check(_visible_meshes_inside_camera_bounds(visual, ready_snapshot), "ready-state visible meshes should fit the published camera bounds", failures)
	var mesh_count := visual.find_children("*", "MeshInstance3D", true, false).size()
	var visible_mesh_count := 0
	for mesh_value in visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_value as MeshInstance3D
		if mesh_instance != null and mesh_instance.is_visible_in_tree():
			visible_mesh_count += 1
	_check(mesh_count <= 240, "North Meadow should stay within its 240-mesh authored art budget (found %d)" % mesh_count, failures)
	_check(visible_mesh_count <= 180, "one staged North Meadow view should stay within 180 visible meshes (found %d)" % visible_mesh_count, failures)
	_check(visual.find_children("NorthMeadowGrassTufts", "MultiMeshInstance3D", true, false).size() == 1, "repeated grass should use one MultiMesh draw cluster", failures)
	_check(visual.find_children("NorthMeadowIdentityPost_*", "MeshInstance3D", true, false).size() == 2, "identity carrier should use exactly two modeled ground supports", failures)
	var lease_notice := visual.find_child("NorthMeadowLeaseNoticeHost", true, false) as MeshInstance3D
	_check(lease_notice != null and bool(lease_notice.get_meta(&"compact_gate_notice", false)), "locked-stage lease copy should use the compact gate notice", failures)
	if lease_notice != null and lease_notice.mesh is BoxMesh:
		_check((lease_notice.mesh as BoxMesh).size.x <= 1.10, "legacy wide lease/status boards should not remain in North Meadow", failures)
	_check(visual.find_children("ServiceSpineKeepClearPlateHost", "MeshInstance3D", true, false).size() == 1, "Service Spine should use exactly one attached KEEP CLEAR plate", failures)
	for marker_value in visual.find_children("SocketMarkerHost_*", "MeshInstance3D", true, false):
		var marker := marker_value as MeshInstance3D
		_check(marker != null and marker.mesh is BoxMesh and (marker.mesh as BoxMesh).size.y <= 0.02, "socket markers should be flush ground inlays rather than raised slabs", failures)
	_check(not visual.is_processing() and not visual.is_physics_processing(), "static expansion art should add no per-frame process loop", failures)
	visual.clear()
	_check(visual.get_child_count() == 0, "public clear should release all authored expansion art", failures)
	visual.build()
	_check(visual.find_child("NorthMeadowParcel", true, false) != null and visual.find_child("EggRoutingPod", true, false) != null, "public build should reconstruct the complete visual contract", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPUS_EXPANSION_VISUAL_MODEL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_EXPANSION_VISUAL_MODEL_TEST_PASSED api=snapshot-root geometry=parcel-bound camera=staged navigation=stable idempotent=true authored<=240 visible<=180")
	quit(0)


func _all_meshes_inside_declared_footprint(visual: CampusExpansionVisual) -> bool:
	var footprint := CampusExpansionVisualScript.declared_footprint()
	for candidate in visual.find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null:
			continue
		var bounds := instance.global_transform * instance.mesh.get_aabb()
		for corner_index in 8:
			var corner := bounds.get_endpoint(corner_index)
			if (
				corner.x < footprint.position.x - 0.015
				or corner.x > footprint.end.x + 0.015
				or corner.z < footprint.position.y - 0.015
				or corner.z > footprint.end.y + 0.015
			):
				return false
	return true


func _visible_meshes_inside_camera_bounds(visual: CampusExpansionVisual, snapshot: Dictionary) -> bool:
	var camera_bounds := CampusExpansionVisualScript.camera_bounds(snapshot)
	for candidate in visual.find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null or not instance.is_visible_in_tree():
			continue
		var bounds := instance.global_transform * instance.mesh.get_aabb()
		for corner_index in 8:
			if not camera_bounds.has_point(bounds.get_endpoint(corner_index)):
				return false
	return true


func _rect_inside(inner: Rect2, outer: Rect2) -> bool:
	return (
		inner.position.x >= outer.position.x
		and inner.position.y >= outer.position.y
		and inner.end.x <= outer.end.x
		and inner.end.y <= outer.end.y
	)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
