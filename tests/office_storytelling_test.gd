extends SceneTree

const OfficeStorytellingScript := preload("res://features/office/office_storytelling.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var staging := OfficeStorytellingScript.new() as OfficeStorytelling
	root.add_child(staging)
	await process_frame

	# Exercise the supported post-add_child configuration path used by Office.
	var desk_positions: Array[Vector3] = [
		Vector3(-6.0, 0.0, -2.8), Vector3(0.0, 0.0, -2.8), Vector3(6.0, 0.0, -2.8),
		Vector3(-6.0, 0.0, 3.0), Vector3(0.0, 0.0, 3.0), Vector3(6.0, 0.0, 3.0),
	]
	staging.configure(desk_positions, Vector3(9.55, 0.0, 5.35), Vector3(9.4, 0.0, -6.85))

	for root_name in [
		"RoosterManagementPerch",
		"VisibleEggCollectionChain",
		"FarmBureauZoneMarkers",
		"FarmBureauSatire",
		"ArchiveAndIntakeStory",
	]:
		_check(staging.find_child(root_name, true, false) != null, "staging should expose %s" % root_name, failures)

	_check(staging.find_children("DeskEggTray_*", "MeshInstance3D", true, false).size() == 6, "every desk should have a visible collection tray", failures)
	_check(staging.find_children("EggLiftTube_*", "MeshInstance3D", true, false).size() == 6, "every desk should connect to the overhead collection rail", failures)
	_check(staging.find_children("EggInTransit_*", "MeshInstance3D", true, false).is_empty(), "collection manifold should never contain decorative fake eggs", failures)
	_check(staging.find_children("EmptyTransitCarrier_*", "MeshInstance3D", true, false).size() == 4, "collection manifold should expose four visibly empty carrier collars", failures)
	_check(staging.find_children("AuthoritativeClutchSlot_*", "Node3D", true, false).size() == 36, "basket and cart should expose a bounded 36-slot living clutch", failures)
	_check(staging.find_children("CartonEgg", "MeshInstance3D", true, false).is_empty(), "collection cart should start without decorative eggs", failures)
	_check(staging.find_child("ManagementYieldBoard", true, false) != null, "management perch should expose live yield metrics", failures)
	_check(staging.find_child("OpenBeakSuggestionBox", true, false) != null, "bureau should include satirical farm-office props", failures)
	_check(staging.find_child("ArchiveRetentionLabel", true, false) != null, "archive should communicate lifetime retention satire", failures)
	_check(staging.find_child("IntakeStatusLedger", true, false) != null, "intake should expose shell/credit storytelling", failures)
	_check(staging.find_children("*", "CollisionObject3D", true, false).is_empty(), "storytelling geometry must remain non-colliding", failures)

	# Rails crossing the open office must stay safely over chicken head-height;
	# floor zoning must remain decal-thin.
	for rail in staging.find_children("OverheadRowRail_*", "MeshInstance3D", true, false):
		_check((rail as MeshInstance3D).position.y >= 2.60, "%s should remain overhead" % rail.name, failures)
	for marker in staging.find_children("ZoneMarkerGlow", "MeshInstance3D", true, false):
		_check((marker as MeshInstance3D).position.y <= 0.03, "%s should remain a floor decal" % marker.name, failures)

	var snapshot := {
		"day": 3,
		"time_label": "6:15 PM",
		"eggs_today": 19,
		"eggs_total": 42,
		"quota_target": 24,
		"claims_waiting": 7,
		"claims_processed": 38,
		"overtime_enabled": true,
		"workers": [{"id": 41, "desk_index": 2}],
	}
	staging.apply_snapshot(snapshot)
	_check(staging.visible_clutch_count() == 19, "snapshot reconciliation should materialize the authoritative current clutch", failures)
	var metrics := staging.find_child("ManagementYieldBoard", true, false) as Label3D
	_check(
		metrics != null
		and metrics.text.begins_with("TODAY")
		and "019 / 024" in metrics.text
		and "6:15 PM" in metrics.text,
		"yield board should reflect the current snapshot in its restrained live-display format",
		failures
	)

	var real_socket_origin := Vector3(6.0, 0.72, -3.75)
	var route := staging.collection_route_global(41, real_socket_origin)
	_check(route.size() == 6, "bound worker should receive a complete collection route", failures)
	_check(route[0].is_equal_approx(real_socket_origin), "egg route must begin at the real hen socket", failures)
	_check(route[route.size() - 1].is_equal_approx(Vector3(9.4, 1.25, -6.85)), "egg route should terminate in the farmer presentation basket", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("OFFICE_STORYTELLING_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OFFICE_STORYTELLING_TEST_PASSED roots=5 desks=6 route=socket-to-farmer collisions=0")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
