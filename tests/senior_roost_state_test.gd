extends SceneTree

const SeniorRoostStateScript := preload("res://core/campaign/senior_roost_state.gd")


func _init() -> void:
	var failures: Array[String] = []
	var senior := SeniorRoostStateScript.new()
	_check(senior.begin(5, {"rework_total_created": 10}), "passing probation should open the first Senior quarter", failures)
	_check(senior.status == SeniorRoostStateScript.STATUS_QUARTER_CHOICE, "Senior entry should require an immediate capital policy", failures)
	var constrained_catalog := senior.policy_catalog(1000)
	_check(not bool(constrained_catalog[0].get("available", true)), "Merit Grants should respect spendable operating reserves", failures)
	_check(bool(constrained_catalog[2].get("available", false)), "Harvest Forecast should remain a no-cost fallback", failures)

	_check(senior.record_quarter_policy(_policy_receipt(&"merit_grants")), "an authoritative policy receipt should start the quarter", failures)
	_check(senior.status == SeniorRoostStateScript.STATUS_ACTIVE, "filed policy should activate Senior shifts", failures)
	var objectives := senior.current_objective_progress(_live_metrics())
	_check(objectives.size() == 3, "active Senior quarters should expose three concise live objectives", failures)

	var first := senior.record_shift(_good_report(6, 11, 11_000))
	_check(bool(first.get("accepted", false)) and not bool(first.get("quarter_complete", true)), "first Senior shift should file without closing the quarter", failures)
	var before_duplicate := senior.to_dictionary()
	var duplicate := senior.record_shift(_good_report(6, 12, 12_000))
	_check(not bool(duplicate.get("accepted", true)), "duplicate Senior days must be rejected", failures)
	_check(senior.to_dictionary() == before_duplicate, "rejected Senior shifts must be atomic", failures)
	_check(bool(senior.record_shift(_good_report(7, 12, 12_000)).get("accepted", false)), "second Senior shift should file", failures)
	var quarter_close := senior.record_shift(_good_report(8, 13, 13_000))
	_check(bool(quarter_close.get("quarter_complete", false)), "third Senior shift should close its quarter", failures)
	var quarter := quarter_close.get("quarter_review", {}) as Dictionary
	_check(int(quarter.get("score", -1)) == 100, "perfect quarter should score exactly 100", failures)
	_check(int(quarter.get("marks_awarded", -1)) == 3 and senior.roost_marks == 3, "perfect quarter should award three persistent Roost Marks", failures)
	_check(senior.status == SeniorRoostStateScript.STATUS_QUARTER_CHOICE, "quarter close should gate the next capital policy", failures)

	# Finish the first four-quarter year with strong ledgers and rotating policies.
	var next_day := 9
	var rework_total := 13
	for policy_id in [&"flock_dividend", &"harvest_forecast", &"merit_grants"]:
		_check(senior.record_quarter_policy(_policy_receipt(policy_id)), "next quarter policy should file", failures)
		for _shift in SeniorRoostStateScript.SHIFTS_PER_QUARTER:
			rework_total += 1
			var result := senior.record_shift(_good_report(next_day, rework_total, 10_000 + next_day * 100))
			next_day += 1
			_check(bool(result.get("accepted", false)), "strong Senior shift should file", failures)
	_check(senior.status == SeniorRoostStateScript.STATUS_ANNUAL_REVIEW, "four quarters should open a real annual review", failures)
	_check(senior.completed_years == 1 and senior.successful_years == 1, "strong first Senior year should pass", failures)
	_check(bool(senior.last_annual_review.get("passed", false)), "annual review should expose its pass result", failures)
	_check(int(senior.last_annual_review.get("score", -1)) == 100, "strong annual review should preserve the exact mean quarter score", failures)
	_check(senior.roost_marks == 15 and senior.promotion_title() == "REGIONAL COOP DIRECTOR", "four perfect quarters plus annual passage should unlock a visible promotion", failures)

	var json_round_trip: Variant = JSON.parse_string(JSON.stringify(senior.to_dictionary()))
	var restored = SeniorRoostStateScript.from_dictionary(json_round_trip as Dictionary)
	_check(restored != null and restored.to_dictionary() == senior.to_dictionary(), "Senior state should survive primitive JSON round-trip", failures)

	_check(senior.continue_after_annual(), "annual review should continue into an uncapped next year", failures)
	# A second, deliberately poor year proves the annual safeguards can fail while
	# keeping the career available for a performance-improvement year.
	for _quarter in SeniorRoostStateScript.QUARTERS_PER_YEAR:
		_check(senior.record_quarter_policy(_policy_receipt(&"harvest_forecast")), "forecast should start each poor-year quarter", failures)
		for _shift in SeniorRoostStateScript.SHIFTS_PER_QUARTER:
			rework_total += 3
			var poor := senior.record_shift(_poor_report(next_day, rework_total))
			next_day += 1
			_check(bool(poor.get("accepted", false)), "poor but valid Senior facts should still file", failures)
	_check(senior.completed_years == 2 and senior.successful_years == 1, "failed Senior year must not erase the earlier success", failures)
	_check(not bool(senior.last_annual_review.get("passed", true)), "unsafe annual ledgers should fail", failures)
	_check(senior.continue_after_annual(), "failed annual review should still permit another year", failures)

	# Retain only the latest eight annual records during long-form continuation.
	for _year in 8:
		for _quarter in SeniorRoostStateScript.QUARTERS_PER_YEAR:
			_check(senior.record_quarter_policy(_policy_receipt(&"harvest_forecast")), "long-form quarter policy should file", failures)
			for _shift in SeniorRoostStateScript.SHIFTS_PER_QUARTER:
				rework_total += 1
				_check(bool(senior.record_shift(_good_report(next_day, rework_total, 14_000)).get("accepted", false)), "long-form Senior shift should file", failures)
				next_day += 1
		_check(senior.continue_after_annual(), "long-form annual review should continue", failures)
	_check(senior.completed_years == 10 and senior.annual_history.size() == SeniorRoostStateScript.MAX_ANNUAL_HISTORY, "annual history should stay bounded without capping career progression", failures)

	var corrupt_total := senior.to_dictionary()
	corrupt_total["total_senior_shifts"] = int(corrupt_total["total_senior_shifts"]) + 1
	_check(not SeniorRoostStateScript.validate_dictionary(corrupt_total).is_empty(), "validator should reject inconsistent Senior totals", failures)
	var corrupt_choices := senior.to_dictionary()
	(corrupt_choices["choice_counts"] as Dictionary)["merit_grants"] = 999
	_check(not SeniorRoostStateScript.validate_dictionary(corrupt_choices).is_empty(), "validator should reject impossible policy counts", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("SENIOR_ROOST_STATE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SENIOR_ROOST_STATE_TEST_PASSED years=10 quarters=40 history=8 policies=3 progression=uncapped")
	quit(0)


func _policy_receipt(policy_id: StringName) -> Dictionary:
	var style_id: StringName = StringName({
		&"merit_grants": &"individual_merit",
		&"flock_dividend": &"shared_scoop",
		&"harvest_forecast": &"management_innovation",
	}.get(policy_id, &"management_innovation"))
	return {
		"accepted": true,
		"policy_id": policy_id,
		"style_id": style_id,
		"outcome": "Quarter policy filed.",
	}


func _good_report(day: int, rework_total: int, closing_fund: int) -> Dictionary:
	return {
		"day": day,
		"eggs": 30,
		"quota": 24,
		"cracked": 2,
		"overdue_claims": 0,
		"rework_total_created": rework_total,
		"credited_cents": 12_000,
		"welfare": 72,
		"compliance": 76,
		"farmer_favor": 66,
		"wage_arrears_cents": 0,
		"closing_fund_cents": closing_fund,
	}


func _poor_report(day: int, rework_total: int) -> Dictionary:
	return {
		"day": day,
		"eggs": 10,
		"quota": 24,
		"cracked": 5,
		"overdue_claims": 8,
		"rework_total_created": rework_total,
		"credited_cents": 1200,
		"welfare": 30,
		"compliance": 40,
		"farmer_favor": 40,
		"wage_arrears_cents": 1000,
		"closing_fund_cents": 0,
	}


func _live_metrics() -> Dictionary:
	return {
		"eggs": 24,
		"quota": 24,
		"cracked": 1,
		"overdue_files": 0,
		"rework": 0,
		"credited_cents": 8000,
		"welfare": 70,
		"compliance": 75,
		"farmer_favor": 65,
		"wage_arrears_cents": 0,
		"closing_fund_cents": 10_000,
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
