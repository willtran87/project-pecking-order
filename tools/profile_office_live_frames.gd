extends SceneTree

## Live Office frame profiler: runs a staffed shift through the real clock and
## reports per-frame script time plus simulation probe stages (snapshot builds,
## ticks). Run with:
## Godot --headless --path . --script tools/profile_office_live_frames.gd [-- frames=600 speed=2]

var _frames := 600
var _speed := 2


func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		var parts := argument.split("=")
		if parts.size() == 2 and parts[0] == "frames":
			_frames = int(parts[1])
		elif parts.size() == 2 and parts[0] == "speed":
			_speed = int(parts[1])
	_profile.call_deferred()


func _profile() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	office.progressive_feature_introduction = false
	root.add_child(office)
	for _frame in 24:
		await process_frame
	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	if simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING:
		simulation.select_directive(&"shell_assurance")
	for worker in simulation.workers:
		if worker.employed:
			simulation.set_worker_at_workstation(worker.id, true)
	clock.set_speed(_speed)
	for _frame in 30:
		await process_frame
	simulation.cost_probe.enabled = true
	var frame_usec: Array[int] = []
	var last := Time.get_ticks_usec()
	var resolved := 0
	for _frame in _frames:
		await process_frame
		var now := Time.get_ticks_usec()
		frame_usec.append(now - last)
		last = now
		if not simulation.pending_decision.is_empty():
			var options := simulation.pending_decision.get("options", []) as Array
			if not options.is_empty():
				simulation.resolve_decision(
					int(simulation.pending_decision.get("serial", -1)),
					StringName((options[0] as Dictionary).get("id", &"")),
				)
				resolved += 1
	var sorted := frame_usec.duplicate()
	sorted.sort()
	var total := 0
	for value in sorted:
		total += value
	var stages := simulation.cost_probe.snapshot().get("stages", {}) as Dictionary
	var stage_rows := {}
	for key in stages:
		var row := stages[key] as Dictionary
		stage_rows[String(key)] = "%d calls, %.2f/frame, %.0f us avg" % [
			int(row["count"]),
			float(row["count"]) / float(_frames),
			float(row["total_usec"]) / maxf(1.0, float(row["count"])),
		]
	print("OFFICE_LIVE_PROFILE %s" % JSON.stringify({
		"frames": _frames,
		"speed": _speed,
		"phase": int(simulation.shift_phase),
		"decisions_resolved": resolved,
		"frame_avg_usec": total / maxi(1, sorted.size()),
		"frame_median_usec": sorted[sorted.size() / 2],
		"frame_p95_usec": sorted[mini(sorted.size() - 1, floori(sorted.size() * 0.95))],
		"stages": stage_rows,
		"cache": simulation.runtime_projection_cache_diagnostics(),
	}, "  "))
	quit(0)
