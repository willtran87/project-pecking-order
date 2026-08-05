extends SceneTree


func _init() -> void:
	create_timer(45.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var view := ChickenView.new()
	view.configure(_worker_snapshot(7, 0))
	root.add_child(view)
	view.assign_office_route(
		Vector3(-2.0, 0.0, 4.0),
		Vector3(0.0, 0.0, 1.0),
		Vector3(-1.0, 0.0, 3.0),
		[Vector3(-1.0, 0.0, 4.0), Vector3(-1.0, 0.0, 1.0), Vector3.ZERO],
		[Vector3(-1.0, 0.0, 1.0), Vector3(-1.0, 0.0, 3.0)],
		0,
	)

	var contacts := {"count": 0}
	view.priority_peck_contact.connect(func(
		_worker_id: int,
		_contact_index: int,
		_rating: StringName
	) -> void:
		contacts["count"] = int(contacts["count"]) + 1
	)
	view.set_route_progress_held(true)
	var held_position := view.global_position
	view.play_peck_assist_feedback(&"steady")
	for _frame in 8:
		view.call("_physics_process", 0.10)
	_check(view.global_position.is_equal_approx(held_position), "paused route must retain its exact world position", failures)
	_check(bool(view.call("is_route_progress_held")), "route hold should expose its active state", failures)
	_check(int(contacts["count"]) == 3, "causal Priority Peck contacts should complete while spatial routing is held", failures)

	view.set_route_progress_held(false)
	view.call("_physics_process", 0.75)
	view.call("_physics_process", 0.75)
	_check(not view.global_position.is_equal_approx(held_position), "route should continue from the held position after resume", failures)
	view.free()
	await process_frame

	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	var clock := office.get("_clock") as SimulationClock
	var active_views := office.get("_worker_views") as Dictionary
	_check(not active_views.is_empty(), "Office fixture should create its authoritative flock", failures)
	clock.set_speed(0)
	office.call("_sync_worker_route_progress_hold")
	for worker_view_value: Variant in active_views.values():
		var worker_view := worker_view_value as ChickenView
		_check(worker_view != null and worker_view.is_route_progress_held(), "every active worker route should hold at 0x", failures)
	clock.set_speed(1)
	office.call("_sync_worker_route_progress_hold")
	for worker_view_value: Variant in active_views.values():
		var worker_view := worker_view_value as ChickenView
		_check(worker_view != null and not worker_view.is_route_progress_held(), "every active worker route should resume above 0x", failures)
	office.set("_feed_party_active", true)
	clock.set_speed(0)
	office.call("_sync_worker_route_progress_hold")
	for worker_view_value: Variant in active_views.values():
		var worker_view := worker_view_value as ChickenView
		_check(worker_view != null and not worker_view.is_route_progress_held(), "Feed Party should retain its authored real-time attendance routes", failures)
	office.set("_feed_party_active", false)
	clock.set_speed(1)

	if active_views.has(0):
		var old_view := active_views.get(0) as ChickenView
		active_views.erase(0)
		var departing_views := office.get("_departing_worker_views") as Dictionary
		departing_views[0] = old_view
		var replacement := office.call("_spawn_worker_view", _worker_snapshot(0, 0)) as ChickenView
		_check(replacement != null and replacement != old_view, "authoritative roster return should receive one current view", failures)
		_check(not old_view.visible and not old_view.is_physics_processing(), "stale departing view should retire before its ID is respawned", failures)
		_check(not departing_views.has(0), "one worker ID must not remain in both active and departing registries", failures)
		_check((office.get("_worker_views") as Dictionary).get(0) == replacement, "active registry should own the sole replacement view", failures)

	office.free()
	await process_frame
	_finish(failures)


func _worker_snapshot(worker_id: int, desk_index: int) -> Dictionary:
	return {
		"id": worker_id,
		"name": "Lifecycle Hen %d" % worker_id,
		"desk_index": desk_index,
		"state": ChickenState.WorkState.IDLE,
		"state_label": "AVAILABLE",
		"progress": 0.0,
		"stress": 12.0,
	}


func _finish(failures: Array[String]) -> void:
	if not failures.is_empty():
		for failure in failures:
			push_error("CHICKEN_LIFECYCLE_PAUSE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CHICKEN_LIFECYCLE_PAUSE_TEST_PASSED route=held feedback=live roster=unique")
	quit(0)


func _on_watchdog_timeout() -> void:
	push_error("CHICKEN_LIFECYCLE_PAUSE_TEST_TIMEOUT")
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
