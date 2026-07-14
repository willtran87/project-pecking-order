extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_test_welfare_unlock(failures)
	_test_quality_unlock(failures)
	_test_credit_unlock(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPAIGN_UNLOCK_EFFECTS_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPAIGN_UNLOCK_EFFECTS_TEST_PASSED welfare=causal quality=-250bp credit=+25c")
	quit(0)


func _test_welfare_unlock(failures: Array[String]) -> void:
	var baseline := DepartmentSimulation.new(4401)
	var improved := DepartmentSimulation.new(4401)
	_start_pair(baseline, improved)
	_check(improved.apply_campaign_unlock(&"welfare_breaks"), "welfare unlock should be accepted", failures)
	baseline.advance_tick()
	improved.advance_tick()
	baseline.advance_tick()
	improved.advance_tick()
	_check(improved.workers[0].fatigue < baseline.workers[0].fatigue, "padded perches should reduce fatigue gain", failures)
	_check(improved.workers[0].stress < baseline.workers[0].stress, "padded perches should reduce stress gain", failures)


func _test_quality_unlock(failures: Array[String]) -> void:
	var baseline := DepartmentSimulation.new(5502)
	var improved := DepartmentSimulation.new(5502)
	_start_pair(baseline, improved)
	_check(improved.apply_campaign_unlock(&"shell_quality_checks"), "quality unlock should be accepted", failures)
	baseline.advance_tick()
	improved.advance_tick()
	var risk_delta := baseline.estimated_crack_risk(0) - improved.estimated_crack_risk(0)
	_check(is_equal_approx(risk_delta, 0.025), "quality lab should reduce crack risk by exactly 250 basis points", failures)


func _test_credit_unlock(failures: Array[String]) -> void:
	var baseline := DepartmentSimulation.new(6603)
	var improved := DepartmentSimulation.new(6603)
	_start_pair(baseline, improved)
	_check(improved.apply_campaign_unlock(&"farmer_credit_bonus"), "credit unlock should be accepted", failures)
	var observation := {"base": {}, "improved": {}}
	baseline.egg_laid.connect(func(_worker_id: int, quality: StringName, value_cents: int) -> void:
		if (observation["base"] as Dictionary).is_empty():
			observation["base"] = {"quality": quality, "value_cents": value_cents}
	)
	improved.egg_laid.connect(func(_worker_id: int, quality: StringName, value_cents: int) -> void:
		if (observation["improved"] as Dictionary).is_empty():
			observation["improved"] = {"quality": quality, "value_cents": value_cents}
	)
	for _tick in 120:
		baseline.advance_tick()
		improved.advance_tick()
		if not (observation["base"] as Dictionary).is_empty() and not (observation["improved"] as Dictionary).is_empty():
			break
	var base_egg := observation["base"] as Dictionary
	var improved_egg := observation["improved"] as Dictionary
	_check(not base_egg.is_empty() and not improved_egg.is_empty(), "credit fixture should produce a paired egg", failures)
	if not base_egg.is_empty() and not improved_egg.is_empty():
		_check(improved_egg.get("quality") == base_egg.get("quality"), "credit perk should not alter quality RNG", failures)
		_check(int(improved_egg.get("value_cents", 0)) == int(base_egg.get("value_cents", 0)) + 25, "credit line should add exactly 25 cents per egg", failures)


func _start_pair(first: DepartmentSimulation, second: DepartmentSimulation) -> void:
	for worker_id in first.workers.size():
		first.set_worker_at_workstation(worker_id, true)
		second.set_worker_at_workstation(worker_id, true)
	first.select_directive(&"record_harvest")
	second.select_directive(&"record_harvest")


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
