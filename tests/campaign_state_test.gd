extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	_test_catalog_and_shift_gate(failures)
	_test_live_objective_projection(failures)
	_test_current_workday_report_fallbacks(failures)
	_test_five_shift_pass_and_cumulative_ledgers(failures)
	_test_early_failure(failures)
	_test_determinism_and_json_round_trip(failures)
	_test_validation_and_atomicity(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPAIGN_STATE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPAIGN_STATE_TEST_PASSED shifts=5 objectives=15 milestone=1-of-3 outcome=pass/fail schema=validated-json")
	quit(0)


func _test_catalog_and_shift_gate(failures: Array[String]) -> void:
	var campaign := CampaignState.new()
	_check(campaign.completed_shifts == 0, "new campaign should start before shift one", failures)
	_check(campaign.probation_score == CampaignState.STARTING_SCORE, "new campaign should expose its probation score", failures)
	_check(campaign.probation_rank == CampaignState.RANK_PROBATIONARY, "starting score should derive the probationary rank", failures)
	_check(campaign.outcome == CampaignState.OUTCOME_IN_PROGRESS, "new campaign should be in progress", failures)
	for shift_number in range(1, CampaignState.CAMPAIGN_LENGTH + 1):
		var objectives := campaign.objectives_for_shift(shift_number)
		_check(objectives.size() == 3, "shift %d should expose three explicit objectives" % shift_number, failures)
		for objective in objectives:
			_check(not String(objective.get("id", "")).is_empty(), "objective needs a stable ID", failures)
			_check(int(objective.get("score_award", 0)) == 3, "every objective should disclose its deterministic score award", failures)

	var choices := campaign.milestone_catalog()
	_check(choices.size() == 3, "probation should offer exactly three milestone choices", failures)
	var expected_choices := {
		"padded_perches": {"unlock": "welfare_breaks", "effect": "stress_gain_percent", "value": -12},
		"shell_quality_lab": {"unlock": "shell_quality_checks", "effect": "crack_risk_basis_points", "value": -250},
		"farmer_credit_line": {"unlock": "farmer_credit_bonus", "effect": "egg_value_bonus_cents", "value": 25},
	}
	for choice in choices:
		var id := String(choice.get("id", ""))
		_check(expected_choices.has(id), "milestone choice ID should be stable", failures)
		if expected_choices.has(id):
			var expected := expected_choices[id] as Dictionary
			_check(String(choice.get("unlock_id", "")) == String(expected["unlock"]), "%s should grant its documented unlock" % id, failures)
			var effects := choice.get("effects", {}) as Dictionary
			_check(int(effects.get(expected["effect"], 999_999)) == int(expected["value"]), "%s should expose an integer gameplay modifier" % id, failures)
	_check(not campaign.is_milestone_choice_available(), "milestone should remain locked before shift two", failures)
	_check(not campaign.choose_milestone(&"shell_quality_lab"), "choice should not apply before its gate", failures)


func _test_live_objective_projection(failures: Array[String]) -> void:
	var campaign := CampaignState.new()
	var before := campaign.to_dictionary()
	var on_track := campaign.current_objective_progress({
		"eggs": 18,
		"crack_rate_basis_points": 1500,
		"welfare": 52,
	})
	_check(on_track.size() == 3, "live projection should mirror the three immutable shift orders", failures)
	for row in on_track:
		_check(bool(row.get("projected_met", false)), "qualifying live metrics should read on track", failures)
		_check(String(row.get("status", "")) == "on_track", "projection should expose a stable on-track status", failures)
		_check(float(row.get("progress_ratio", 0.0)) == 1.0, "qualifying metrics should expose full projected progress", failures)
	var needs_action := campaign.current_objective_progress({
		"eggs": 9,
		"crack_rate_basis_points": 2500,
		"welfare": 40,
	})
	var every_order_needs_action := needs_action.size() == 3
	for row in needs_action:
		every_order_needs_action = every_order_needs_action and not bool(row.get("projected_met", true))
	_check(
		every_order_needs_action,
		"lagging live metrics should keep every opening order actionable",
		failures,
	)
	_check(campaign.to_dictionary() == before, "live projection must never award score or mutate campaign state", failures)


func _test_current_workday_report_fallbacks(failures: Array[String]) -> void:
	var campaign := CampaignState.new()
	var report := _good_report(1, 9800, 6600, 2)
	report.erase("credited_cents")
	var result := campaign.record_shift(report, _worker_derived_welfare_snapshot())
	_check(bool(result.get("accepted", false)), "existing workday report keys plus its closing snapshot should normalize", failures)
	if not bool(result.get("accepted", false)):
		return
	var record := result.get("record", {}) as Dictionary
	_check(int(record.get("credited_cents", -1)) == 6600, "closing fund plus feed cost should recover credited cents when event total is absent", failures)
	_check(int(record.get("rework", -1)) == 2, "cumulative rework source counter should normalize to a daily delta", failures)
	_check(int(record.get("welfare", -1)) == 80, "worker morale, stress, and fatigue should derive a deterministic closing welfare index", failures)
	_check(int(record.get("compliance", -1)) == 76, "simulation compliance float should normalize to an integer", failures)
	_check(int(record.get("farmer_favor", -1)) == 64, "executive_confidence should map to farmer favor", failures)


func _test_five_shift_pass_and_cumulative_ledgers(failures: Array[String]) -> void:
	var campaign := CampaignState.new()
	var closing_fund := CampaignState.DEFAULT_OPENING_FUND_CENTS
	var total_credited := 0
	var rework_total := 0
	for shift_number in range(1, CampaignState.CAMPAIGN_LENGTH + 1):
		if shift_number == 3:
			var before_gate := campaign.to_dictionary()
			var blocked := campaign.record_shift(
				_good_report(shift_number, closing_fund, 9000, rework_total),
				_good_snapshot()
			)
			_check(not bool(blocked.get("accepted", true)), "shift three should wait for a milestone choice", failures)
			_check(campaign.to_dictionary() == before_gate, "blocked shift must not mutate campaign state", failures)
			_check(not campaign.choose_milestone(&"executive_fox"), "unknown milestone should fail atomically", failures)
			var score_before_choice := campaign.probation_score
			_check(campaign.choose_milestone(&"shell_quality_lab"), "valid milestone should unlock shift three", failures)
			_check(campaign.probation_score == mini(100, score_before_choice + 2), "milestone should apply its disclosed score bonus once", failures)
			_check(campaign.has_unlock(&"shell_quality_checks"), "chosen milestone should persist its unlock", failures)
			_check(int(campaign.active_unlock_effects().get("crack_risk_basis_points", 0)) == -250, "selected quality lab should expose its exact modifier", failures)
			_check(not campaign.choose_milestone(&"padded_perches"), "milestone selection should be mutually exclusive", failures)

		var credited := 8000 + shift_number * 500
		rework_total += 1 if shift_number in [2, 4] else 0
		closing_fund += credited - 1800
		var result := campaign.record_shift(
			_good_report(shift_number, closing_fund, credited, rework_total),
			_good_snapshot()
		)
		_check(bool(result.get("accepted", false)), "good shift %d should be accepted" % shift_number, failures)
		if not bool(result.get("accepted", false)):
			continue
		total_credited += credited
		var record := result.get("record", {}) as Dictionary
		_check(int(record.get("shift_number", 0)) == shift_number, "record should retain chronological shift number", failures)
		_check(typeof(record.get("credited_cents")) == TYPE_INT, "credited value should remain integer cents", failures)
		_check((record.get("objective_results", []) as Array).size() == 3, "record should persist all objective results", failures)
		if shift_number == 2:
			_check(bool(result.get("milestone_available", false)), "shift two should open the milestone gate", failures)

	_check(campaign.completed_shifts == CampaignState.CAMPAIGN_LENGTH, "campaign should end after exactly five accepted shifts", failures)
	_check(campaign.outcome == CampaignState.OUTCOME_PASSED, "balanced high performance should pass probation", failures)
	_check(campaign.final_evaluation().get("passed", false), "final evaluation should expose the win state", failures)
	_check(campaign.probation_rank == CampaignState.RANK_GOLDEN_MANAGEMENT, "excellent probation score should earn the top explicit rank", failures)
	_check(campaign.total_credited_cents == total_credited, "credited ledger should accumulate daily integer cents", failures)
	_check(campaign.total_eggs == 130, "egg ledger should accumulate all five shifts", failures)
	_check(campaign.total_cracked_eggs == 5, "cracked egg ledger should accumulate all five shifts", failures)
	_check(campaign.total_overdue_files == 0, "overdue ledger should accumulate shift-end files", failures)
	_check(campaign.total_rework == 2, "rework ledger should count deltas from the simulation cumulative counter", failures)
	_check(campaign.cumulative_welfare == 375, "welfare should be cumulative rather than only the last value", failures)
	_check(campaign.cumulative_compliance == 410, "compliance should be cumulative rather than only the last value", failures)
	_check(campaign.cumulative_farmer_favor == 350, "farmer favor should be cumulative rather than only the last value", failures)
	_check(campaign.average_welfare() == 75, "final evaluation should expose deterministic average welfare", failures)
	_check(campaign.current_objectives().is_empty(), "final campaign should have no phantom sixth-shift objectives", failures)
	var after_final := campaign.to_dictionary()
	_check(not bool(campaign.record_shift(_good_report(6, closing_fund, 1000, rework_total), _good_snapshot()).get("accepted", true)), "final campaign should reject a sixth shift", failures)
	_check(campaign.to_dictionary() == after_final, "sixth-shift rejection should be atomic", failures)


func _test_early_failure(failures: Array[String]) -> void:
	var campaign := CampaignState.new()
	var report_one := _poor_report(1, 0)
	var report_two := _poor_report(2, 10)
	_check(bool(campaign.record_shift(report_one, _poor_snapshot()).get("accepted", false)), "first poor shift should still produce a review", failures)
	_check(bool(campaign.record_shift(report_two, _poor_snapshot()).get("accepted", false)), "second poor shift should still produce a review", failures)
	_check(campaign.outcome == CampaignState.OUTCOME_FAILED, "critical score collapse should produce an early loss", failures)
	_check(campaign.probation_rank == CampaignState.RANK_TERMINATED, "early loss should expose the terminated rank", failures)
	var evaluation := campaign.final_evaluation()
	_check(bool(evaluation.get("is_final", false)) and not bool(evaluation.get("passed", true)), "loss evaluation should be final and unambiguously failed", failures)
	_check(not campaign.is_milestone_choice_available(), "terminated campaign should not offer a milestone", failures)


func _test_determinism_and_json_round_trip(failures: Array[String]) -> void:
	var first := CampaignState.new()
	var second := CampaignState.new()
	var closing_fund := CampaignState.DEFAULT_OPENING_FUND_CENTS
	var rework_total := 0
	for shift_number in range(1, 4):
		if shift_number == 3:
			first.choose_milestone(&"padded_perches")
			second.choose_milestone(&"padded_perches")
		var credited := 7000 + shift_number * 333
		closing_fund += credited - 1800
		rework_total += 1 if shift_number == 2 else 0
		var report := _good_report(shift_number, closing_fund, credited, rework_total)
		first.record_shift(report, _worker_derived_welfare_snapshot())
		second.record_shift(report, _worker_derived_welfare_snapshot())
	_check(first.to_dictionary() == second.to_dictionary(), "same reports and choices should produce byte-for-byte deterministic state", failures)

	var json_text := JSON.stringify(first.to_dictionary())
	var parsed_value: Variant = JSON.parse_string(json_text)
	_check(typeof(parsed_value) == TYPE_DICTIONARY, "campaign dictionary should be valid JSON", failures)
	if typeof(parsed_value) != TYPE_DICTIONARY:
		return
	var parsed := parsed_value as Dictionary
	_check(CampaignState.validate_dictionary(parsed).is_empty(), "JSON-parsed campaign should satisfy schema validation", failures)
	var restored := CampaignState.from_dictionary(parsed)
	_check(restored != null, "valid JSON campaign should restore", failures)
	if restored != null:
		_check(restored.to_dictionary() == first.to_dictionary(), "restored campaign should reproduce the exact primitive state", failures)
		_check(restored.has_unlock(&"welfare_breaks"), "restored milestone unlock should retain its typed identity", failures)
		_check(typeof(restored.total_credited_cents) == TYPE_INT, "restored currency should be an integer", failures)


func _test_validation_and_atomicity(failures: Array[String]) -> void:
	var campaign := CampaignState.new()
	var invalid_report := _good_report(1, 10_000, 6800, 0)
	invalid_report["cracked"] = 99
	var before := campaign.to_dictionary()
	var rejected := campaign.record_shift(invalid_report, _good_snapshot())
	_check(not bool(rejected.get("accepted", true)), "malformed workday report should be rejected", failures)
	_check(campaign.to_dictionary() == before, "malformed report rejection should not partially mutate totals", failures)

	var valid_report := _good_report(1, 11_200, 8000, 0)
	campaign.record_shift(valid_report, _good_snapshot())
	var corrupt_total := campaign.to_dictionary()
	(corrupt_total["totals"] as Dictionary)["total_eggs"] = 999
	_check(not CampaignState.validate_dictionary(corrupt_total).is_empty(), "validator should reject totals inconsistent with records", failures)
	_check(CampaignState.from_dictionary(corrupt_total) == null, "loader should refuse a tampered cumulative ledger", failures)

	var corrupt_rank := campaign.to_dictionary()
	corrupt_rank["probation_rank"] = "golden_management"
	_check(not CampaignState.validate_dictionary(corrupt_rank).is_empty(), "validator should reject a rank inconsistent with score", failures)

	var corrupt_type := campaign.to_dictionary()
	corrupt_type["probation_score"] = "73"
	_check(not CampaignState.validate_dictionary(corrupt_type).is_empty(), "validator should reject stringly typed score data", failures)


func _good_report(shift_number: int, closing_fund: int, credited: int, rework_total: int) -> Dictionary:
	return {
		"day": shift_number,
		"eggs": 26,
		"quota": 24,
		"met_quota": true,
		"cracked": 1,
		"golden": 1,
		"quota_bonus_cents": 1000,
		"quality_bonus_cents": 500,
		"feed_cost_cents": 1800,
		"overdue_claims": 0,
		"rework_waiting": 0,
		"rework_due_next_shift": 0,
		"rework_total_created": rework_total,
		"closing_fund_cents": closing_fund,
		# Explicit value is preferred when the integration has tracked egg events;
		# current workday reports can instead use the closing-fund fallback.
		"credited_cents": credited,
	}


func _good_snapshot() -> Dictionary:
	return {
		"welfare": 75,
		"compliance": 82,
		"executive_confidence": 70,
	}


func _worker_derived_welfare_snapshot() -> Dictionary:
	return {
		"compliance": 76.0,
		"executive_confidence": 64.0,
		"workers": [
			{"morale": 70.0, "stress": 15.0, "fatigue": 10.0},
			{"morale": 66.0, "stress": 18.0, "fatigue": 15.0},
		],
	}


func _poor_report(shift_number: int, rework_total: int) -> Dictionary:
	return {
		"day": shift_number,
		"eggs": 0,
		"quota": 24,
		"cracked": 0,
		"feed_cost_cents": 1800,
		"overdue_claims": 8,
		"rework_total_created": rework_total,
		"closing_fund_cents": 0,
		"credited_cents": 0,
	}


func _poor_snapshot() -> Dictionary:
	return {"welfare": 0, "compliance": 0, "executive_confidence": 0}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
