extends SceneTree

const SeniorRoostStateScript := preload("res://core/campaign/senior_roost_state.gd")


func _init() -> void:
	var failures: Array[String] = []
	_test_mark_boundaries(failures)
	_test_pure_breakdown_and_tie(failures)
	_test_live_projection_parity_and_nonmutation(failures)
	_test_quarter_award_parity(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("SENIOR_CAREER_FORECAST_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SENIOR_CAREER_FORECAST_TEST_PASSED boundaries=40-60-80 breakdown=pure tie=deterministic projection=quarter-parity save=unchanged")
	quit(0)


func _test_mark_boundaries(failures: Array[String]) -> void:
	var expected := {
		39: 0,
		40: 1,
		59: 1,
		60: 2,
		79: 2,
		80: 3,
	}
	for score_value in expected:
		var score := int(score_value)
		_check(
			SeniorRoostStateScript.marks_for_score(score) == int(expected[score_value]),
			"score %d should project exactly %d Roost Marks" % [score, int(expected[score_value])],
			failures,
		)
	_check(SeniorRoostStateScript.next_mark_threshold_for_score(39) == 40, "39 should point to the 40-point tier", failures)
	_check(SeniorRoostStateScript.next_mark_threshold_for_score(40) == 60, "40 should point to the 60-point tier", failures)
	_check(SeniorRoostStateScript.next_mark_threshold_for_score(60) == 80, "60 should point to the 80-point tier", failures)
	_check(SeniorRoostStateScript.next_mark_threshold_for_score(80) == -1, "80 should report the top mark tier", failures)


func _test_pure_breakdown_and_tie(failures: Array[String]) -> void:
	var senior := SeniorRoostStateScript.new()
	var records: Array[Dictionary] = [
		_normalized_record(10, 10, 2, 3, 60, 70, 60, 0),
		_normalized_record(10, 10, 2, 2, 60, 70, 60, 0),
		_normalized_record(10, 10, 2, 2, 60, 70, 60, 0),
	]
	var records_before := records.duplicate(true)
	var first := senior.score_breakdown(records, false)
	var second := senior.score_breakdown(records, false)
	var largest := first.get("largest_recoverable_component", {}) as Dictionary
	_check(records == records_before, "score breakdown must not mutate caller records", failures)
	_check(first == second, "identical score facts should produce an identical forecast", failures)
	_check(int(first.get("score", -1)) == 80, "tie fixture should score exactly 80", failures)
	_check(
		String(largest.get("id", "")) == "shell_integrity"
		and int(largest.get("recoverable_points", 0)) == 10,
		"equal ten-point Shell and Queue losses should deterministically choose the earlier Shell component",
		failures,
	)
	_check(
		String(largest.get("cause", "")).contains("crack rate"),
		"largest recoverable component should carry its factual cause",
		failures,
	)


func _test_live_projection_parity_and_nonmutation(failures: Array[String]) -> void:
	var senior := _active_senior(failures)
	var first_report := _report(6, &"eighty")
	var second_report := _report(7, &"eighty")
	var closing_report := _report(8, &"eighty")
	_check(bool(senior.record_shift(first_report).get("accepted", false)), "first parity shift should file", failures)
	_check(bool(senior.record_shift(second_report).get("accepted", false)), "second parity shift should file", failures)
	var before_forecast := senior.to_dictionary()
	var forecast := senior.current_career_forecast(_live_metrics(closing_report))
	_check(senior.to_dictionary() == before_forecast, "live forecast must not change persistent Senior state", failures)
	_check(bool(forecast.get("visible", false)), "active Senior facts should expose a forecast", failures)
	_check((forecast.get("components", []) as Array).size() == 7, "forecast should publish all seven authoritative score components", failures)
	var close := senior.record_shift(closing_report)
	var review := close.get("quarter_review", {}) as Dictionary
	_check(bool(close.get("quarter_complete", false)), "third parity shift should close the quarter", failures)
	_check(
		int(forecast.get("projected_score", -1)) == int(review.get("score", -2)),
		"if-filed-now score must equal the filed quarter score for identical facts",
		failures,
	)
	_check(
		int(forecast.get("projected_marks", -1)) == int(review.get("marks_awarded", -2)),
		"projected marks must equal the permanent award for identical facts",
		failures,
	)


func _test_quarter_award_parity(failures: Array[String]) -> void:
	var profiles := {
		&"forty_five": {"score": 45, "marks": 1},
		&"sixty": {"score": 60, "marks": 2},
		&"eighty": {"score": 80, "marks": 3},
	}
	for profile_value in profiles:
		var profile := StringName(profile_value)
		var senior := _active_senior(failures)
		var quarter: Dictionary = {}
		for day in [6, 7, 8]:
			var result := senior.record_shift(_report(day, profile))
			_check(bool(result.get("accepted", false)), "%s fixture day %d should file" % [String(profile), day], failures)
			if bool(result.get("quarter_complete", false)):
				quarter = result.get("quarter_review", {}) as Dictionary
		var expected := profiles[profile_value] as Dictionary
		_check(int(quarter.get("score", -1)) == int(expected["score"]), "%s fixture should close at its authored score" % String(profile), failures)
		_check(int(quarter.get("marks_awarded", -1)) == int(expected["marks"]), "%s fixture should use the canonical mark boundary" % String(profile), failures)


func _active_senior(failures: Array[String]) -> SeniorRoostState:
	var senior := SeniorRoostStateScript.new()
	_check(senior.current_career_forecast({}).is_empty(), "inactive career should not expose a forecast", failures)
	_check(senior.begin(5), "forecast fixture should begin Senior Roost", failures)
	_check(
		bool(senior.select_annual_mandate(
			SeniorRoostStateScript.MANDATE_FALLBACK_ID,
			senior.current_year_number(),
		).get("accepted", false)),
		"forecast fixture should file the universal annual Board Mandate before Q1 policy",
		failures,
	)
	_check(senior.current_career_forecast(_live_metrics(_report(6, &"eighty"))).is_empty(), "quarter-choice gate should not expose an active forecast", failures)
	_check(senior.record_quarter_policy({
		"accepted": true,
		"policy_id": &"harvest_forecast",
		"style_id": &"management_innovation",
		"outcome": "Forecast test policy filed.",
	}), "forecast fixture should file its policy", failures)
	return senior


func _report(day: int, profile: StringName) -> Dictionary:
	var facts := {
		&"forty_five": {
			"eggs": 10, "quota": 20, "cracked": 0, "overdue": 0,
			"welfare": 30, "compliance": 40, "favor": 65, "arrears": 0,
		},
		&"sixty": {
			"eggs": 10, "quota": 20, "cracked": 0, "overdue": 0,
			"welfare": 65, "compliance": 75, "favor": 40, "arrears": 0,
		},
		&"eighty": {
			"eggs": 24, "quota": 24, "cracked": 1, "overdue": 0,
			"welfare": 30, "compliance": 75, "favor": 55, "arrears": 0,
		},
	}[profile] as Dictionary
	return {
		"day": day,
		"eggs": int(facts["eggs"]),
		"quota": int(facts["quota"]),
		"cracked": int(facts["cracked"]),
		"overdue_claims": int(facts["overdue"]),
		"rework_total_created": 0,
		"credited_cents": 5000,
		"welfare": int(facts["welfare"]),
		"compliance": int(facts["compliance"]),
		"farmer_favor": int(facts["favor"]),
		"wage_arrears_cents": int(facts["arrears"]),
		"closing_fund_cents": 20_000,
	}


func _live_metrics(report: Dictionary) -> Dictionary:
	return {
		"eggs": int(report["eggs"]),
		"quota": int(report["quota"]),
		"cracked": int(report["cracked"]),
		"overdue_files": int(report["overdue_claims"]),
		"rework": 0,
		"credited_cents": int(report["credited_cents"]),
		"welfare": int(report["welfare"]),
		"compliance": int(report["compliance"]),
		"farmer_favor": int(report["farmer_favor"]),
		"wage_arrears_cents": int(report["wage_arrears_cents"]),
		"closing_fund_cents": int(report["closing_fund_cents"]),
	}


func _normalized_record(
	eggs: int,
	quota: int,
	cracked: int,
	overdue: int,
	welfare: int,
	compliance: int,
	favor: int,
	arrears: int,
) -> Dictionary:
	return {
		"day": 1,
		"eggs": eggs,
		"quota": quota,
		"met_quota": eggs >= quota,
		"cracked": cracked,
		"overdue": overdue,
		"rework_created": 0,
		"credited_cents": 0,
		"welfare": welfare,
		"compliance": compliance,
		"farmer_favor": favor,
		"wage_arrears_cents": arrears,
		"closing_fund_cents": 0,
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
