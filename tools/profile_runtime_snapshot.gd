extends SceneTree

## Read-only snapshot profiler. Run with:
## Godot --headless --path . --script tools/profile_runtime_snapshot.gd

const SAMPLE_PASSES := 100


func _init() -> void:
	var simulation := DepartmentSimulation.new(290719)
	simulation.select_directive(&"shell_assurance")
	for worker in simulation.workers:
		if worker.employed:
			simulation.set_worker_at_workstation(worker.id, true)

	var exact_samples := _sample(func() -> void: simulation.snapshot())
	simulation.snapshot(true)
	var defensive_cached_samples := _sample(func() -> void: simulation.snapshot(true))
	var clock_read_only_samples := _sample(func() -> void: simulation.publish_current_snapshot())
	await create_timer(
		float(DepartmentSimulation.RUNTIME_PROJECTION_REFRESH_MSEC + 50) / 1000.0,
	).timeout
	var refresh_started := Time.get_ticks_usec()
	simulation.publish_current_snapshot()
	var clock_live_refresh_usec := Time.get_ticks_usec() - refresh_started
	print("RUNTIME_SNAPSHOT_PROFILE %s" % JSON.stringify({
		"exact": _summary(exact_samples),
		"defensive_cached": _summary(defensive_cached_samples),
		"clock_read_only": _summary(clock_read_only_samples),
		"clock_live_refresh_usec": clock_live_refresh_usec,
		"diagnostics": simulation.runtime_projection_cache_diagnostics(),
	}))
	quit(0)


func _sample(callable: Callable) -> Array[int]:
	var samples: Array[int] = []
	for _pass in SAMPLE_PASSES:
		var started := Time.get_ticks_usec()
		callable.call()
		samples.append(Time.get_ticks_usec() - started)
	return samples


func _summary(samples: Array[int]) -> Dictionary:
	var sorted := samples.duplicate()
	sorted.sort()
	var total := 0
	for sample in sorted:
		total += sample
	return {
		"count": sorted.size(),
		"average_usec": float(total) / maxf(1.0, float(sorted.size())),
		"median_usec": sorted[sorted.size() / 2],
		"p95_usec": sorted[mini(sorted.size() - 1, floori(sorted.size() * 0.95))],
		"maximum_usec": sorted[-1],
	}
