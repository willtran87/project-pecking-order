extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var paced := _running_simulation(7107)
	var direct := _running_simulation(7107)
	var clock := SimulationClock.new()
	clock.initialize(paced)
	clock.set_speed(3)

	var observed_revisions: Array[int] = []
	var observed_batch_sizes: Array[int] = []
	paced.snapshot_changed.connect(func(state: Dictionary) -> void:
		observed_revisions.append(int(state.get("authoritative_tick_revision", -1)))
	)
	clock.tick_batch_completed.connect(func(tick_count: int) -> void:
		observed_batch_sizes.append(tick_count)
	)

	# One real second at 10x makes thirteen whole logical ticks due. Only the
	# bounded frame budget may execute immediately; the remainder must be kept.
	clock._process(1.0)
	_check(
		clock.ticks_advanced_last_frame() == SimulationClock.MAX_TICKS_PER_FRAME,
		"a long frame must service no more than the configured tick budget",
		failures,
	)
	_check(
		paced.checkpoint_revision() == SimulationClock.MAX_TICKS_PER_FRAME,
		"the first frame must advance exactly the bounded authoritative tick count",
		failures,
	)
	_check(
		clock.pending_tick_count() == 9,
		"unserviced catch-up ticks must remain queued instead of being discarded",
		failures,
	)
	_check(
		observed_revisions == [4],
		"one clock frame should publish only its newest authoritative read model",
		failures,
	)
	_check(
		observed_batch_sizes == [4] and not clock.is_advancing_tick_batch(),
		"the clock should disclose one completed four-tick batch after publication settles",
		failures,
	)

	var drain_frames := 0
	while clock.pending_tick_count() > 0 and drain_frames < 8:
		clock._process(0.0)
		_check(
			clock.ticks_advanced_last_frame() <= SimulationClock.MAX_TICKS_PER_FRAME,
			"every catch-up frame must honor the same bounded tick budget",
			failures,
		)
		drain_frames += 1

	var expected_ticks := floori(
		SimulationClock.SPEED_MULTIPLIERS[3] / SimulationClock.BASE_TICK_SECONDS
	)
	var direct_revisions: Array[int] = []
	direct.snapshot_changed.connect(func(state: Dictionary) -> void:
		direct_revisions.append(int(state.get("authoritative_tick_revision", -1)))
	)
	for _tick in expected_ticks:
		direct.advance_tick()

	_check(clock.pending_tick_count() == 0, "the retained backlog must eventually drain", failures)
	_check(
		paced.checkpoint_revision() == expected_ticks,
		"bounded catch-up must eventually execute every due authoritative tick",
		failures,
	)
	_check(
		observed_revisions == [4, 8, 12, 13]
		and observed_batch_sizes == [4, 4, 4, 1],
		"accelerated catch-up should publish one settled snapshot and one batch receipt per rendered frame",
		failures,
	)
	_check(
		direct_revisions == range(1, expected_ticks + 1),
		"direct advance_tick calls should retain their immediate snapshot contract",
		failures,
	)
	_check(
		JSON.stringify(paced.export_save_state()) == JSON.stringify(direct.export_save_state()),
		"bounded cadence and direct cadence must produce identical deterministic save state",
		failures,
	)

	# Ordinary 10x play produces one logical tick every 75ms on a healthy frame
	# cadence. The first tick presents immediately, then adjacent single ticks
	# may share one bounded read model for at most 200ms while authority continues
	# exactly. This keeps accelerated Web play smooth without hiding decisions.
	var accelerated := _running_simulation(8118)
	var accelerated_direct := _running_simulation(8118)
	var accelerated_clock := SimulationClock.new()
	accelerated_clock.initialize(accelerated)
	accelerated_clock.set_speed(3)
	var accelerated_revisions: Array[int] = []
	accelerated.snapshot_changed.connect(func(state: Dictionary) -> void:
		accelerated_revisions.append(int(state.get("authoritative_tick_revision", -1)))
	)
	for _frame in 4:
		accelerated_clock._process(0.075)
		accelerated_direct.advance_tick(false)
	_check(
		accelerated.checkpoint_revision() == 4,
		"accelerated presentation coalescing must never drop authoritative ticks",
		failures,
	)
	_check(
		accelerated_revisions == [1, 4],
		"healthy 10x cadence should present immediately, then coalesce adjacent ticks inside 200ms",
		failures,
	)
	_check(
		JSON.stringify(accelerated.export_save_state())
			== JSON.stringify(accelerated_direct.export_save_state()),
		"accelerated visual coalescing must leave deterministic economy state unchanged",
		failures,
	)

	# Pausing has always discarded fractional elapsed time. It must also clear a
	# retained catch-up backlog so resuming cannot replay time accrued pre-pause.
	var paused := _running_simulation(99)
	var paused_clock := SimulationClock.new()
	paused_clock.initialize(paused)
	paused_clock.set_speed(3)
	paused_clock._process(6.0)
	_check(paused_clock.pending_tick_count() > 0, "large deltas should create measurable backlog", failures)
	paused_clock.set_speed(0)
	_check(paused_clock.pending_tick_count() == 0, "pause must clear retained catch-up debt", failures)
	_check(paused_clock.ticks_advanced_last_frame() == 0, "pause must reset frame instrumentation", failures)
	clock.free()
	accelerated_clock.free()
	paused_clock.free()

	if not failures.is_empty():
		for failure in failures:
			push_error("SIMULATION_CLOCK_CATCH_UP_TEST_FAILED: %s" % failure)
		quit(1)
		return

	print(
		"SIMULATION_CLOCK_CATCH_UP_TEST_PASSED ticks=%d drain_frames=%d snapshots=one_per_frame direct=immediate max_per_frame=%d"
		% [expected_ticks, drain_frames, SimulationClock.MAX_TICKS_PER_FRAME]
	)
	quit(0)


func _running_simulation(seed_value: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed_value)
	simulation.select_directive(&"shell_assurance")
	for worker in simulation.workers:
		simulation.set_worker_at_workstation(worker.id, true)
	return simulation


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
