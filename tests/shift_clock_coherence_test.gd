extends SceneTree


func _init() -> void:
	create_timer(60.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(260923, 4)
	_check(simulation.select_directive(&"shell_assurance"), "fixture should start an active shift", failures)
	var clock := SimulationClock.new()
	clock.initialize(simulation)
	clock.set_speed(1)
	clock._process(SimulationClock.BASE_TICK_SECONDS)
	_check(simulation.minute_of_day == 8 * 60 + 2, "one 1x work beat should move the office clock two game minutes", failures)
	clock.set_speed(2)
	clock._process(SimulationClock.BASE_TICK_SECONDS / 3.0)
	_check(simulation.minute_of_day == 8 * 60 + 4, "3x should advance one work beat in one third the real time", failures)
	clock.set_speed(3)
	clock._process(SimulationClock.BASE_TICK_SECONDS / 10.0)
	_check(simulation.minute_of_day == 8 * 60 + 6, "10x should advance one work beat in one tenth the real time", failures)
	clock.set_speed(0)
	clock._process(5.0)
	_check(simulation.minute_of_day == 8 * 60 + 6, "pausing must stop authoritative clock minutes", failures)
	clock.free()

	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	var office_clock := office.get("_clock") as SimulationClock
	var office_simulation := office.get("_simulation") as DepartmentSimulation
	var time_label := office.get("_time_label") as Label
	var day_label := office.get("_day_label") as Label
	_check(time_label != null and time_label.text == "8:00 AM", "paused opening should retain the actual 8:00 AM clock", failures)
	_check(day_label != null and day_label.text == "DAY 1", "opening clock should identify the active day", failures)
	if time_label != null:
		_check("Closing bell: 5:00 PM" in time_label.accessibility_name, "clock explanation should disclose the shift boundary", failures)
		office_simulation.minute_of_day = 8 * 60 + 2
		office_clock.set_speed(1)
		office.call("_update_shift_clock_copy", 1, "8:02 AM")
		_check(time_label.text == "8:02 AM", "running HUD should show the authoritative time", failures)
		_check("two game minutes" in time_label.accessibility_name, "running clock should explain one work beat", failures)
		office_clock.set_speed(0)
		office.call("_refresh_speed_button_copy")
		_check(time_label.text == "8:02 AM", "manual pause should not replace the time with a status word", failures)
		_check("Pause owner" in time_label.accessibility_name, "paused clock should still explain why time stopped", failures)
		office_simulation.minute_of_day = 8 * 60 + 22
		office.call("_on_clock_tick_batch_completed", 1)
		_check(time_label.text == "8:22 AM", "a completed authoritative tick should refresh the HUD even without a heavy presentation snapshot", failures)
		office_simulation.minute_of_day = 8 * 60 + 24
		office_clock.set_speed(1)
		_check(time_label.text == "8:24 AM", "changing pace should synchronize the visible clock before resuming", failures)
		office_simulation.eggs_today = 2
		office_simulation.quota_target = 16
		var first_clutch := (office.get("_first_clutch") as Dictionary).duplicate(true)
		first_clutch["dismissed"] = true
		office.set("_first_clutch", first_clutch)
		office.call("_on_clock_tick_batch_completed", 1)
		var quota_label := office.get("_quota_progress_label") as Label
		_check(
			quota_label != null and "2 / 16" in quota_label.text,
			"the live shift objective should count authoritative eggs even when world presentation is deferred",
			failures,
		)
		office_simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
		office_simulation.eggs_today = 1
		first_clutch["dismissed"] = false
		first_clutch["route_first_lesson"] = true
		first_clutch["delivery_laid"] = true
		office.set("_first_clutch", first_clutch)
		office.call("_sync_authoritative_shift_objective_display")
		_check(quota_label != null and "FIRST EGG · 1/1" == quota_label.text, "the first-egg reward should stay visible until the choice is filed", failures)
		first_clutch["reinvestment_grandfathered"] = true
		office.set("_first_clutch", first_clutch)
		office.call("_sync_authoritative_shift_objective_display")
		_check(quota_label != null and "FILE 3 EGGS · 1/3" == quota_label.text, "filing the first reward should carry its credited egg into the next short goal", failures)
		office_simulation.eggs_today = 3
		office.call("_sync_authoritative_shift_objective_display")
		_check(
			quota_label != null and "QUOTA  ·  3 / 16" == quota_label.text
			and "13 remaining before 5:00 PM" in quota_label.accessibility_name,
			"the third egg should reveal the remaining shift quota without waiting for a fourth egg",
			failures,
		)
		first_clutch["inspected"] = true
		first_clutch["specialty_routed"] = true
		first_clutch["target_worker_id"] = 0
		first_clutch["delivery_laid"] = false
		office.set("_first_clutch", first_clutch)
		office_simulation.eggs_today = 0
		office_simulation.minute_of_day = DepartmentSimulation.SHIFT_START_MINUTE
		office_clock.set_speed(0)
		var fresh_coach := office.call("_first_clutch_coach_snapshot", office_simulation.snapshot()) as Dictionary
		_check(String(fresh_coach.get("primary_label", "")) == "START WORK", "the first paused work action should still say start", failures)
		office_simulation.minute_of_day += DepartmentSimulation.MINUTES_PER_TICK
		var resumed_coach := office.call("_first_clutch_coach_snapshot", office_simulation.snapshot()) as Dictionary
		_check(String(resumed_coach.get("primary_label", "")) == "RESUME SHIFT", "a paused shift with elapsed work time should offer resume, not start again", failures)

	office.set("_last_workday_report", {"day": 1})
	var closing_stamp := office.call("_clock_stamp_for_snapshot", {
		"day": 2,
		"time_label": "8:00 AM",
		"shift_phase": DepartmentSimulation.ShiftPhase.REVIEW,
	}) as Dictionary
	_check(int(closing_stamp.get("day", -1)) == 1 and String(closing_stamp.get("time_label", "")) == "5:00 PM", "review should show the shift just closed, not tomorrow's staged 8:00 AM", failures)
	var next_shift_stamp := office.call("_clock_stamp_for_snapshot", {
		"day": 2,
		"time_label": "8:00 AM",
		"shift_phase": DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE,
	}) as Dictionary
	_check(int(next_shift_stamp.get("day", -1)) == 2 and String(next_shift_stamp.get("time_label", "")) == "8:00 AM", "tomorrow's clock should appear when its morning decision starts", failures)

	office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("SHIFT_CLOCK_COHERENCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SHIFT_CLOCK_COHERENCE_TEST_PASSED beats=2min paces=1x+3x+10x pause=frozen review=closing-day")
	quit(0)


func _on_watchdog_timeout() -> void:
	push_error("SHIFT_CLOCK_COHERENCE_TEST_TIMEOUT")
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
