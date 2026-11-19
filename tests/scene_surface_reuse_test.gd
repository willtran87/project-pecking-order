extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	var host := Node3D.new()
	root.add_child(host)
	var desks := Node3D.new()
	host.add_child(desks)
	var desk := preload("res://assets/models/office_workstation.glb").instantiate()
	desk.name = "Workstation_00"
	desks.add_child(desk)
	var feedback := WorkstationFeedback.new()
	host.add_child(feedback)
	feedback.configure(desks)
	feedback.set_process(false)
	var worker := {"id": 0, "desk_index": 0, "name": "MABEL", "state": 1, "progress": 25.0, "stress": 10.0, "at_workstation": true, "assigned_lane": "nest_damage", "current_claim": {"id": 100, "minutes_until_deadline": 100}, "peck_assist": {"available": false}}
	var snapshot := {"workers": [worker], "upgrade_levels": {}}
	feedback.apply_snapshot(snapshot)
	var writes := feedback.presentation_write_counts()
	for _repeat in 12:
		feedback.apply_snapshot(snapshot)
	check(feedback.presentation_write_counts() == writes, "Identical live desks must not resend surface parameters or rebind materials")
	var station = feedback.get("_stations_by_worker")[0]
	worker.progress = 26.0
	feedback.apply_snapshot(snapshot)
	check(is_equal_approx(station.work_progress_fill.scale.x, 0.26), "Continuous work progress must still move on every update")
	check(feedback.presentation_write_counts() == writes, "Sub-pip progress must reuse the same colors and bindings")
	worker.progress = 65.0
	feedback.apply_snapshot(snapshot)
	check(station.work_progress_root.get_meta("filled_pips") == 4, "Crossing progress thresholds must fill the new pips immediately")
	worker.current_claim.minutes_until_deadline = 20
	worker.peck_assist.available = true
	feedback.apply_snapshot(snapshot)
	check(station.work_progress_fill.material_override == station.work_progress_warning_material, "Deadline risk must retain priority over a ready assist")
	worker.current_claim.minutes_until_deadline = 100
	feedback.apply_snapshot(snapshot)
	check(station.work_progress_fill.material_override == station.work_progress_ready_material, "Clearing a deadline must restore the ready-assist material")
	# An externally edited resource must be repaired, rather than hidden by a stale key.
	station.screen_material.albedo_color = Color.MAGENTA
	feedback.apply_snapshot(snapshot)
	check(station.screen_material.albedo_color == station.base_color.darkened(0.68), "Surface guards must compare actual resource values")
	feedback.set_color_vision_mode(&"color_blind_safe")
	check(station.work_progress_warning_material.albedo_color == SemanticColorPalette.quality_color(&"cracked", &"color_blind_safe"), "Palette changes must recolor warnings immediately")
	feedback.set_color_vision_mode(&"standard")
	check(station.work_progress_ready_material.albedo_color == SemanticColorPalette.quality_color(&"golden", &"standard"), "Returning to the standard palette must restore the reward color")
	worker.state = 3
	worker.at_workstation = false
	feedback.apply_snapshot(snapshot)
	check(station.work_progress_pause_root.visible, "Taking a break must still show the pause marker")
	var rooms: Array[Node3D] = [
		preload("res://features/office/farm_mutual_contract_board_visual.gd").new(),
		preload("res://features/office/farm_mutual_service_coop_visual.gd").new(),
		preload("res://features/office/farm_mutual_negotiation_room_visual.gd").new(),
		preload("res://features/office/records_annex_visual.gd").new(),
	]
	var room_snapshot := {
		"owned_facilities": {"farm_mutual_service_coop": 1, "farm_mutual_negotiation_room": 1, "records_annex": 1},
		"contract_board": {"unlocked": true, "active": {"id": "delivery", "required_completed": 3, "timely_sound_completed": 1}},
		"claim_capacity": 12, "claims_outstanding": 2, "overdue_claims": 0,
	}
	for room in rooms:
		host.add_child(room)
		room.call("apply_snapshot", room_snapshot)
		var count: int = room.get("_render_refresh_count")
		for tick in 5:
			room_snapshot["minute_of_day"] = 500 + tick
			room.call("apply_snapshot", room_snapshot)
		check(room.get("_render_refresh_count") == count, "Clock-only updates must not repaint " + room.name)
	# Mutate the same caller-owned graph: retained render states must be isolated.
	room_snapshot.contract_board.active.timely_sound_completed = 2
	for room in rooms.slice(0, 3):
		var count: int = room.get("_render_refresh_count")
		room.call("apply_snapshot", room_snapshot)
		check(room.get("_render_refresh_count") == count + 1, "A real delivery must update " + room.name)
	var records := rooms[3]
	var records_count: int = records.get("_render_refresh_count")
	room_snapshot.overdue_claims = 2
	records.call("apply_snapshot", room_snapshot)
	check(records.get("_overdue_count") == 2 and records.get("_render_refresh_count") == records_count + 1, "Records must display new overdue files immediately")
	room_snapshot.owned_facilities.records_annex = 2
	records.call("apply_snapshot", room_snapshot)
	check(records.call("current_level") == 2 and records.call("tier_visible", 2), "Purchased room progression must reveal its new tier")
	host.free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("SCENE_SURFACE_REUSE_TEST_%s" % ("PASSED" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)
