extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new()
	var opening := simulation.campaign_flock_epilogue()
	_check(opening.size() == 3, "the closing flock record should select three bounded named outcomes", failures)
	_check(_unique_worker_count(opening) == 3, "the default epilogue should not repeat one hen across its three slots", failures)
	for entry: Dictionary in opening:
		_check(
			int(entry.get("worker_id", -1)) >= 0
			and not String(entry.get("worker_name", "")).is_empty()
			and not String(entry.get("caption", "")).is_empty()
			and not String(entry.get("value", "")).is_empty()
			and not String(entry.get("outcome", "")).is_empty(),
			"every flock epilogue entry should name the hen, the outcome, and its human consequence",
			failures,
		)

	var mabel: ChickenState = simulation.workers[0]
	simulation.flock_restructuring_resolved = true
	simulation.flock_restructuring_record = {
		"worker_name": mabel.display_name,
		"worker_id": mabel.id,
		"option_id": &"contest_ranking",
	}
	var contested := simulation.campaign_flock_epilogue()
	var first := contested[0] as Dictionary
	_check(
		String(first.get("worker_name", "")) == mabel.display_name
		and String(first.get("caption", "")) == "RESTRUCTURING"
		and String(first.get("value", "")) == "STOOD TOGETHER"
		and "contested the ranking" in String(first.get("outcome", "")),
		"the defining people decision should lead the epilogue with the exact affected hen",
		failures,
	)
	_check(_unique_worker_count(contested) == 3, "restructuring should still leave three distinct flock outcomes", failures)

	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPAIGN_FLOCK_EPILOGUE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPAIGN_FLOCK_EPILOGUE_TEST_PASSED outcomes=3 named+unique restructuring=causal")
	quit(0)


func _unique_worker_count(entries: Array[Dictionary]) -> int:
	var ids: Dictionary = {}
	for entry: Dictionary in entries:
		ids[int(entry.get("worker_id", -1))] = true
	return ids.size()


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
