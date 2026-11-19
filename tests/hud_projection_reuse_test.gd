extends SceneTree


class CountingRoutingUI:
	extends PeckworkRoutingUI
	var refreshes := 0

	func _refresh() -> void:
		refreshes += 1


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	for _frame in 24:
		await process_frame
	var clock := office.get("_clock") as SimulationClock
	clock.set_process(false)
	clock.set_speed(0)
	office.set_process(false)
	var simulation := office.get("_simulation") as DepartmentSimulation
	var snapshot := simulation.snapshot()
	var original := snapshot.duplicate(true)
	office.call("_apply_snapshot_presentation", snapshot)
	var pulse: Dictionary = office.get("_gameplay_pulse")
	var retained := pulse.duplicate(true)
	var hud := office.get("_top_hud_panel") as Control
	var routing := office.get("_routing_ui") as PeckworkRoutingUI
	var failures: Array[String] = []
	var counted := CountingRoutingUI.new()
	counted.set_peck_assist_clock_running(false)
	var paused_refreshes := counted.refreshes
	for _repeat in 10:
		counted.set_peck_assist_clock_running(false)
	_check(counted.refreshes == paused_refreshes, "unchanged paused state must not rebuild the dossier", failures)
	counted.set_peck_assist_clock_running(true)
	_check(counted.refreshes == paused_refreshes + 1, "resuming must refresh availability immediately", failures)
	for _repeat in 10:
		counted.set_peck_assist_clock_running(true)
	_check(counted.refreshes == paused_refreshes + 1, "running snapshots must not rebuild the dossier twice", failures)
	counted.set_peck_assist_clock_running(false)
	_check(counted.refreshes == paused_refreshes + 2, "pausing must disable timing actions immediately", failures)
	counted.free()
	_check(snapshot == original, "HUD adapters must not modify authoritative inputs", failures)
	var old_layer: Dictionary = hud.get_meta("professional_polish", {})
	var old_copy := old_layer.duplicate(true)
	_check(not old_layer.is_empty(), "fixture must exercise the nested polish projection", failures)
	_check(is_same(old_layer, routing.get_meta("professional_polish")), "panels should share one owned projection instead of copying it", failures)
	# Replacing the current projection must leave retained metadata and inputs
	# stable, while new quota information reaches the visible controls immediately.
	simulation.eggs_today += 2
	var next_snapshot := simulation.snapshot()
	office.call("_apply_snapshot_presentation", next_snapshot)
	_check(old_layer == old_copy and pulse == retained, "a later update must not mutate any retained HUD projection", failures)
	_check(not is_same(old_layer, hud.get_meta("professional_polish")), "new projections must replace previous graphs", failures)
	var goal := office.get("_shift_goal_status_host") as Control
	_check(int(goal.get_meta("laid", -1)) == simulation.eggs_today, "goal counts must update in the same presentation pass", failures)
	# Public routing adapters still accept mutable caller-owned values safely.
	var external := {"action_spotlight": {"label": "ORIGINAL"}, "experiential_polish": {}}
	routing.apply_professional_polish_state(external)
	external["action_spotlight"]["label"] = "CHANGED"
	var stored: Dictionary = routing.get_meta("professional_polish")
	_check(stored["action_spotlight"]["label"] == "ORIGINAL", "external callers must retain defensive-copy isolation", failures)
	var external_completion := {"attention_choreography": {"visible_groups": ["work"], "focus_id": "work"}}
	routing.apply_professional_completion_state(external_completion)
	external_completion["attention_choreography"]["visible_groups"].append("changed")
	var stored_completion: Dictionary = routing.get_meta("professional_gameplay_completion")
	_check(stored_completion["attention_choreography"]["visible_groups"] == ["work"], "external completion arrays must remain isolated too", failures)
	office.free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("HUD_PROJECTION_REUSE_TEST_%s" % ("PASSED" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
