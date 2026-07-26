extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(290719)
	simulation.select_directive(&"shell_assurance")
	for worker in simulation.workers:
		if worker.employed:
			simulation.set_worker_at_workstation(worker.id, true)

	var first := simulation.snapshot(true)
	var first_diagnostics := simulation.runtime_projection_cache_diagnostics()
	_check(bool(first_diagnostics.get("cached", false)), "the first runtime snapshot should build its projection cache", failures)
	_check(int(first_diagnostics.get("builds", 0)) >= 1, "the cache should publish a measurable build count", failures)

	var first_facilities := first.get("facility_catalog", []) as Array
	if not first_facilities.is_empty():
		(first_facilities[0] as Dictionary)["name"] = "MUTATED PRESENTATION"
	var second := simulation.snapshot(true)
	var second_facilities := second.get("facility_catalog", []) as Array
	_check(
		second_facilities.is_empty()
		or String((second_facilities[0] as Dictionary).get("name", "")) != "MUTATED PRESENTATION",
		"runtime projection callers must not alias or poison the cached read model",
		failures,
	)
	var second_diagnostics := simulation.runtime_projection_cache_diagnostics()
	_check(
		int(second_diagnostics.get("hits", 0)) > int(first_diagnostics.get("hits", 0)),
		"a second clock-style read inside the refresh window should reuse the slow projections",
		failures,
	)

	var fund_before := simulation.revenue_cents
	simulation.revenue_cents += 123
	var cached := simulation.snapshot(true)
	_check(
		int(cached.get("revenue_cents", -1)) == fund_before + 123,
		"fast snapshots must keep authoritative root counters exact",
		failures,
	)
	var exact := simulation.snapshot()
	var exact_cash := (
		(exact.get("economic_briefing", {}) as Dictionary).get("cash", {}) as Dictionary
	)
	_check(
		int(exact_cash.get("feed_fund_cents", -1)) == fund_before + 123,
		"an explicit snapshot must refresh the complete economic planning projection",
		failures,
	)

	var builds_before_phase := int(
		simulation.runtime_projection_cache_diagnostics().get("builds", 0),
	)
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.snapshot(true)
	var after_phase := simulation.runtime_projection_cache_diagnostics()
	_check(
		int(after_phase.get("builds", 0)) == builds_before_phase + 1,
		"a day or phase transition must rebuild slow projections immediately",
		failures,
	)
	_check(
		int(after_phase.get("refresh_msec", 0))
			== DepartmentSimulation.RUNTIME_PROJECTION_REFRESH_MSEC,
		"the cache diagnostic should disclose the bounded visible-age contract",
		failures,
	)

	if not failures.is_empty():
		for failure in failures:
			push_error("RUNTIME_PROJECTION_CACHE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print(
		"RUNTIME_PROJECTION_CACHE_TEST_PASSED refresh_msec=%d builds=%d hits=%d exact=direct defensive_copy=true"
		% [
			int(after_phase.get("refresh_msec", 0)),
			int(after_phase.get("builds", 0)),
			int(after_phase.get("hits", 0)),
		]
	)
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
