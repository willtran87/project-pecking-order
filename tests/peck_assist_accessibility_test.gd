extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(1701, 4)
	var standard := simulation.peck_assist_status(0)
	_check(
		StringName(standard.get("timing_assist_profile", &"")) == &"standard"
		and is_equal_approx(float(standard.get("window_start", 0.0)), DepartmentSimulation.PECK_ASSIST_WINDOW_START)
		and is_equal_approx(float(standard.get("window_end", 0.0)), DepartmentSimulation.PECK_ASSIST_WINDOW_END),
		"standard timing should preserve the shipped Priority Peck window",
		failures,
	)

	_check(simulation.set_peck_assist_timing_profile(&"lenient"), "lenient timing profile should be accepted", failures)
	var lenient := simulation.peck_assist_status(0)
	_check(
		StringName(lenient.get("timing_assist_profile", &"")) == &"lenient"
		and float(lenient.get("window_start", 100.0)) < float(standard.get("window_start", 0.0))
		and float(lenient.get("window_end", 0.0)) > float(standard.get("window_end", 100.0)),
		"lenient timing should widen both edges without changing the ideal",
		failures,
	)
	_check(
		is_equal_approx(float(lenient.get("ideal_progress", 0.0)), DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS),
		"timing assistance must not move the strongest reward target",
		failures,
	)

	_check(simulation.set_peck_assist_timing_profile(&"extended"), "extended timing profile should be accepted", failures)
	var extended := simulation.peck_assist_status(0)
	_check(
		float(extended.get("window_start", 100.0)) < float(lenient.get("window_start", 0.0))
		and float(extended.get("window_end", 0.0)) > float(lenient.get("window_end", 100.0)),
		"extended timing should provide the widest motor-access window",
		failures,
	)
	_check(
		not simulation.set_peck_assist_timing_profile(&"automatic_win")
		and simulation.peck_assist_timing_profile == &"extended",
		"unknown or unfair timing profiles should reject without mutation",
		failures,
	)

	if not failures.is_empty():
		for failure: String in failures:
			push_error("PECK_ASSIST_ACCESSIBILITY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PECK_ASSIST_ACCESSIBILITY_TEST_PASSED standard=28-88 lenient=22-92 extended=15-96 rewards=unchanged")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
