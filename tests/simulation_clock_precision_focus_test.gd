extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(1701, 4)
	_check(simulation.select_directive(&"shell_assurance"), "fixture should start a running shift", failures)
	var clock := SimulationClock.new()
	clock.initialize(simulation)
	clock.set_speed(2)
	clock.set_precision_focus_active(true)
	_check(clock.speed_index == 2, "precision focus must retain the requested 3x index", failures)
	_check(clock.precision_focus_limiting(), "3x should report an active precision limit", failures)
	_check(is_equal_approx(clock.effective_multiplier(), 1.0), "3x precision focus should use a 1x effective multiplier", failures)
	clock.set_speed(1)
	_check(not clock.precision_focus_limiting(), "requested 1x should not report a speed limit", failures)
	_check(is_equal_approx(clock.effective_multiplier(), 1.0), "requested 1x should remain natively 1x", failures)
	clock.set_speed(3)
	_check(clock.speed_index == 3, "precision focus must retain the requested 10× index", failures)
	_check(clock.precision_focus_limiting(), "10× should report an active precision limit", failures)
	_check(is_equal_approx(clock.effective_multiplier(), 1.0), "10× precision focus should use a 1× effective multiplier", failures)

	var revision_before := int(simulation.snapshot().get("authoritative_tick_revision", -1))
	clock._process(0.74)
	_check(
		int(simulation.snapshot().get("authoritative_tick_revision", -1)) == revision_before,
		"precision time below one base interval should not advance authority",
		failures,
	)
	clock._process(0.02)
	var focused_revision := int(simulation.snapshot().get("authoritative_tick_revision", -1))
	_check(focused_revision == revision_before + 1, "0.76 seconds of precision time should advance exactly one tick", failures)

	clock.set_precision_focus_active(false)
	_check(not clock.precision_focus_limiting(), "leaving the claim window should release precision focus", failures)
	_check(is_equal_approx(clock.effective_multiplier(), 10.0), "released focus should restore requested 10× immediately", failures)
	clock._process(0.075)
	_check(
		int(simulation.snapshot().get("authoritative_tick_revision", -1)) == focused_revision + 1,
		"restored 10× should advance one tick in 75 milliseconds",
		failures,
	)

	var debt_clock := SimulationClock.new()
	debt_clock.initialize(simulation)
	debt_clock.set_speed(3)
	debt_clock._process(2.0)
	_check(debt_clock.pending_tick_count() > 0, "high-speed catch-up fixture should retain bounded tick debt", failures)
	debt_clock.set_precision_focus_active(true)
	_check(
		debt_clock.pending_tick_count() == 0,
		"entering precision focus should discard whole high-speed debt before the readable window",
		failures,
	)

	clock.free()
	debt_clock.free()
	if not failures.is_empty():
		for failure in failures:
			push_error("SIMULATION_CLOCK_PRECISION_FOCUS_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SIMULATION_CLOCK_PRECISION_FOCUS_TEST_PASSED requested=10x effective=1x restore=10x backlog=clamped")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
