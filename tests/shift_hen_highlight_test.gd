extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_test_deterministic_priority_ladder(failures)
	_test_zero_output_fallback(failures)
	_test_workday_report_freezes_json_safe_shift_story(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("SHIFT_HEN_HIGHLIGHT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SHIFT_HEN_HIGHLIGHT_TEST_PASSED priority=deterministic fallback=leader report=frozen-json-safe")
	quit(0)


func _test_deterministic_priority_ladder(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(9301)
	var ranking: Array[Dictionary] = [
		_rank_row(1, 0, 4, 2, 0, 2, 2000),
		_rank_row(2, 1, 2, 0, 2, 0, 1800),
		_rank_row(3, 2, 2, 0, 2, 0, 1700),
		_rank_row(4, 4, 1, 1, 0, 0, 900),
		_rank_row(5, 3, 3, 3, 0, 0, 400),
		_rank_row(6, 5, 0, 0, 0, 0, 0),
	]

	# Every candidate class is present. Pressure must outrank golden output,
	# worker strain, and invisible labor; its own tie-break favors stress.
	simulation.workers[1].last_personnel_action = &"quota_pressure"
	simulation.workers[1].last_personnel_action_day = 1
	simulation.workers[1].stress = 40.0
	simulation.workers[2].last_personnel_action = &"quota_pressure"
	simulation.workers[2].last_personnel_action_day = 1
	simulation.workers[2].stress = 55.0
	simulation.workers[4].stress = 90.0
	var pressure := simulation._build_shift_hen_highlight(1, ranking, 12)
	var pressure_repeat := simulation._build_shift_hen_highlight(1, ranking, 12)
	_check(String(pressure.get("type", "")) == "pressure_exception", "pressure consequence should take top story priority", failures)
	_check(int(pressure.get("worker_id", -1)) == 2, "equal pressure cracks should deterministically select the more-stressed hen", failures)
	_check(pressure == pressure_repeat, "identical closing ledgers should produce an identical highlight", failures)

	# Removing only the pressure trigger should reveal the golden story next.
	simulation.workers[1].last_personnel_action_day = 0
	simulation.workers[2].last_personnel_action_day = 0
	var golden := simulation._build_shift_hen_highlight(1, ranking, 12)
	_check(String(golden.get("type", "")) == "golden_deliverable", "golden output should outrank strain and invisible labor", failures)
	_check(int(golden.get("worker_id", -1)) == 0, "golden story should retain its real worker", failures)

	# Removing the golden result reveals strain; clearing strain reveals the
	# bottom-half hen whose output still met the flock average.
	ranking[0]["golden"] = 0
	var strain := simulation._build_shift_hen_highlight(1, ranking, 12)
	_check(String(strain.get("type", "")) == "strain_notice", "visible strain should outrank invisible labor", failures)
	_check(int(strain.get("worker_id", -1)) == 4, "the highest-risk strained hen should be selected", failures)
	simulation.workers[4].stress = 12.0
	var invisible := simulation._build_shift_hen_highlight(1, ranking, 12)
	_check(String(invisible.get("type", "")) == "invisible_labor", "qualifying bottom-half output should become the story when no exception remains", failures)
	_check(int(invisible.get("worker_id", -1)) == 3, "invisible-labor story should name the qualifying lower-ranked hen", failures)


func _test_zero_output_fallback(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(9302)
	var ranking := simulation.current_pecking_order()
	var highlight := simulation._build_shift_hen_highlight(1, ranking, 0)
	_check(not highlight.is_empty(), "an employed flock should always produce a closing story", failures)
	_check(String(highlight.get("type", "")) == "ledger_leader", "an uneventful shift should fall back to the ledger leader", failures)
	_check(int(highlight.get("worker_id", -1)) == 0, "the disclosed employee-number tie-break should choose worker zero on an empty ledger", failures)
	_check(int(highlight.get("eggs", -1)) == 0, "zero-output fallback should not invent eggs", failures)
	_check(String(highlight.get("body", "")).contains("every tray empty"), "zero-output fallback copy should acknowledge the empty shift", failures)
	_check(simulation._build_shift_hen_highlight(1, [], 0).is_empty(), "a report with no ranked hens should not invent a character", failures)


func _test_workday_report_freezes_json_safe_shift_story(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(9303)
	var reports: Array[Dictionary] = []
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		reports.append(report.duplicate(true))
	)
	simulation.revenue_cents = 100_000
	simulation.eggs_today = 2
	simulation.golden_today = 1
	simulation.credited_today_cents = 1600
	simulation._record_worker_shift_result(2, &"golden", 1200)
	simulation._record_worker_shift_result(2, &"sound", 400)
	simulation.workers[2].stress = 81.0
	simulation.workers[2].fatigue = 86.0

	simulation._complete_workday()
	_check(reports.size() == 1, "closing a workday should emit exactly one report", failures)
	if reports.is_empty():
		return
	var report := reports[0]
	var highlight := report.get("hen_highlight", {}) as Dictionary
	_check(String(highlight.get("type", "")) == "golden_deliverable", "emitted report should carry the highest-priority real shift story", failures)
	_check(int(highlight.get("worker_id", -1)) == 2, "emitted story should retain the laying hen", failures)
	_check(int(highlight.get("eggs", -1)) == 2, "emitted story should freeze the hen's pre-reset egg count", failures)
	_check(int(highlight.get("sound", -1)) == 1 and int(highlight.get("golden", -1)) == 1, "emitted story should freeze the exact quality mix", failures)
	_check(int(highlight.get("credit_cents", -1)) == 1600, "emitted story should freeze the exact credited value", failures)
	_check(int(highlight.get("stress", -1)) == 81 and int(highlight.get("fatigue", -1)) == 86, "emitted story should capture closing strain before overnight recovery", failures)
	_check(simulation.workers[2].stress < 81.0 and simulation.workers[2].fatigue < 86.0, "overnight recovery should occur only after the report story is frozen", failures)

	var reset_row := _row_for_worker(simulation.current_pecking_order(), 2)
	_check(int(reset_row.get("eggs", -1)) == 0, "next shift's live ledger should reset independently of the frozen report", failures)
	_check(int(highlight.get("eggs", -1)) == 2, "the frozen report must survive the live-ledger reset", failures)
	_check(_is_json_safe(highlight), "hen highlight payload should contain only JSON-safe values and string keys", failures)
	var parsed: Variant = JSON.parse_string(JSON.stringify(highlight))
	_check(parsed is Dictionary, "hen highlight should survive a JSON encode/decode round trip", failures)
	if parsed is Dictionary:
		var parsed_highlight := parsed as Dictionary
		_check(String(parsed_highlight.get("headline", "")) == String(highlight.get("headline", "")), "JSON round trip should preserve presentation copy", failures)
		_check(int(parsed_highlight.get("credit_cents", -1)) == 1600, "JSON round trip should preserve numerical evidence", failures)


func _rank_row(
	rank: int,
	worker_id: int,
	eggs: int,
	sound: int,
	cracked: int,
	golden: int,
	credit_cents: int,
) -> Dictionary:
	return {
		"rank": rank,
		"worker_id": worker_id,
		"worker_name": DepartmentSimulation.WORKER_NAMES[worker_id],
		"employed": true,
		"eggs": eggs,
		"sound": sound,
		"cracked": cracked,
		"golden": golden,
		"credit_cents": credit_cents,
		"score": credit_cents,
	}


func _row_for_worker(ranking: Array[Dictionary], worker_id: int) -> Dictionary:
	for row in ranking:
		if int(row.get("worker_id", -1)) == worker_id:
			return row
	return {}


func _is_json_safe(value: Variant) -> bool:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return true
		TYPE_ARRAY:
			for item in value as Array:
				if not _is_json_safe(item):
					return false
			return true
		TYPE_DICTIONARY:
			for key in value as Dictionary:
				if typeof(key) != TYPE_STRING or not _is_json_safe((value as Dictionary)[key]):
					return false
			return true
		_:
			return false


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
