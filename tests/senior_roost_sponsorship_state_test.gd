extends SceneTree

const SeniorRoostStateScript := preload("res://core/campaign/senior_roost_state.gd")


func _init() -> void:
	var failures: Array[String] = []
	_test_gate_and_atomic_commit(failures)
	_test_annual_and_later_gates(failures)
	_test_schema_migration_and_validation(failures)
	_test_bounded_history(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("SENIOR_ROOST_SPONSORSHIP_STATE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SENIOR_ROOST_SPONSORSHIP_STATE_TEST_PASSED marks=lifetime-vs-spent gates=quarter+annual transaction=atomic migration=v1-to-v5 history=bounded")
	quit(0)


func _test_gate_and_atomic_commit(failures: Array[String]) -> void:
	var senior := SeniorRoostStateScript.new()
	_check(senior.begin(5), "fixture should open the first Senior policy gate", failures)
	var initial_snapshot := senior.snapshot()
	_check(int(initial_snapshot.get("sponsorship_mark_cost", -1)) == 3, "snapshot should expose the exact three-mark sponsorship price", failures)
	_check(int(initial_snapshot.get("roost_marks_spent", -1)) == 0, "new careers should expose zero spent marks", failures)
	_check(int(initial_snapshot.get("available_roost_marks", -1)) == 0, "new careers should expose zero available marks", failures)
	_check(not bool(initial_snapshot.get("sponsorship_available_this_gate", true)), "initial Senior entry must not expose sponsorship before a completed quarter", failures)

	var before_initial := senior.to_dictionary()
	var initial_preflight := senior.preflight_sponsorship(0, &"appeals", &"nest_damage")
	_check(not bool(initial_preflight.get("accepted", true)), "initial Senior entry should reject sponsorship", failures)
	_check(String(initial_preflight.get("reason_id", "")) == "quarter_required", "initial rejection should identify the missing completed quarter", failures)
	_check(senior.to_dictionary() == before_initial, "preflight rejection must not mutate the Senior ledger", failures)

	_complete_perfect_quarter(senior, 6, failures)
	_check(senior.completed_quarters == 1 and senior.roost_marks == 3, "one perfect quarter should create the first three lifetime marks", failures)
	_check(senior.roost_marks_spent == 0 and senior.available_roost_marks() == 3, "earned marks should begin fully available", failures)
	_check(senior.sponsorship_available_this_gate(), "the first closed-quarter gate should expose sponsorship", failures)
	var earned_title := senior.promotion_title()

	var invalid_before := senior.to_dictionary()
	var same_lane := senior.preflight_sponsorship(0, &"appeals", &"appeals")
	_check(String(same_lane.get("reason_id", "")) == "same_lane", "sponsorship should require a genuinely secondary lane", failures)
	_check(senior.to_dictionary() == invalid_before, "invalid lane preflight must be atomic", failures)

	var preflight := senior.preflight_sponsorship(0, &"appeals", &"nest_damage")
	_check(bool(preflight.get("accepted", false)), "eligible first-quarter sponsorship should pass Senior preflight", failures)
	_check(int(preflight.get("mark_cost", -1)) == 3 and int(preflight.get("available_roost_marks_before", -1)) == 3, "preflight should expose exact mark accounting", failures)
	_check(senior.to_dictionary() == invalid_before, "accepted preflight must remain pure", failures)

	var denied_receipt := _authoritative_receipt(preflight, "Mabel")
	denied_receipt["accepted"] = false
	var denied_before := senior.to_dictionary()
	var denied_commit := senior.commit_sponsorship(preflight, denied_receipt)
	_check(not bool(denied_commit.get("accepted", true)), "denied external receipt should block Senior commit", failures)
	_check(senior.to_dictionary() == denied_before, "denied external receipt must not spend marks", failures)

	var mismatched_receipt := _authoritative_receipt(preflight, "Mabel")
	mismatched_receipt["worker_id"] = 1
	var mismatched_commit := senior.commit_sponsorship(preflight, mismatched_receipt)
	_check(not bool(mismatched_commit.get("accepted", true)), "mismatched external receipt should block Senior commit", failures)
	_check(senior.to_dictionary() == denied_before, "mismatched receipt must preserve the complete ledger", failures)

	var committed := senior.commit_sponsorship(preflight, _authoritative_receipt(preflight, "Mabel"))
	_check(bool(committed.get("accepted", false)), "matching external receipt should commit the Senior sponsorship", failures)
	_check(senior.roost_marks == 3, "sponsorship must never reduce lifetime promotion marks", failures)
	_check(senior.promotion_title() == earned_title, "spending sponsorship marks must never demote the player", failures)
	_check(senior.roost_marks_spent == 3 and senior.available_roost_marks() == 0, "commit should spend exactly three available marks", failures)
	_check(senior.sponsorship_history.size() == 1, "commit should append exactly one bounded receipt", failures)
	var record := senior.sponsorship_history[0]
	_check(int(record.get("career_quarter", -1)) == 1, "receipt should bind to the first completed-quarter gate", failures)
	_check(StringName(record.get("secondary_lane", &"")) == &"nest_damage", "receipt should preserve the secondary lane", failures)
	_check(int(record.get("fund_cost_cents", -1)) == 1200, "receipt should retain authoritative Feed Fund cost", failures)
	_check(not senior.sponsorship_available_this_gate(), "a committed gate should no longer advertise sponsorship", failures)

	var repeat_before := senior.to_dictionary()
	var repeat := senior.preflight_sponsorship(1, &"nest_damage", &"appeals")
	_check(not bool(repeat.get("accepted", true)), "a second sponsorship at the same completed-quarter gate must be rejected", failures)
	_check(String(repeat.get("reason_id", "")) == "already_filed_this_gate", "same-gate rejection should expose the stable reason ID", failures)
	_check(String(repeat.get("reason", "")) == SeniorRoostStateScript.SPONSORSHIP_ALREADY_FILED_REASON, "same-gate rejection should expose the exact authored explanation", failures)
	_check(senior.to_dictionary() == repeat_before, "same-gate rejection must be atomic", failures)

	_complete_perfect_quarter(senior, 9, failures)
	var later_preflight := senior.preflight_sponsorship(1, &"nest_damage", &"appeals")
	_check(bool(later_preflight.get("accepted", false)), "a later completed-quarter gate should permit another hen", failures)
	var stale_before := senior.to_dictionary()
	senior.roost_marks += 1
	var stale := senior.commit_sponsorship(later_preflight, _authoritative_receipt(later_preflight, "Pip"))
	_check(not bool(stale.get("accepted", true)) and String(stale.get("reason_id", "")) == "stale_preflight", "changed mark accounting should invalidate a stale preflight", failures)
	_check(senior.roost_marks_spent == int(stale_before.get("roost_marks_spent", -1)), "stale commit must not spend marks", failures)
	_check(senior.sponsorship_history.size() == 1, "stale commit must not append a receipt", failures)
	var refreshed := senior.preflight_sponsorship(1, &"nest_damage", &"appeals")
	_check(bool(senior.commit_sponsorship(refreshed, _authoritative_receipt(refreshed, "Pip")).get("accepted", false)), "refreshed preflight should commit at the later gate", failures)
	_check(senior.sponsorship_history.size() == 2 and senior.roost_marks_spent == 6, "later gate should retain both exact sponsorship receipts", failures)


func _test_annual_and_later_gates(failures: Array[String]) -> void:
	var senior := SeniorRoostStateScript.new()
	_check(senior.begin(5), "annual fixture should begin Senior Roost", failures)
	var next_day := 6
	for _quarter in SeniorRoostStateScript.QUARTERS_PER_YEAR:
		_complete_perfect_quarter(senior, next_day, failures)
		next_day += SeniorRoostStateScript.SHIFTS_PER_QUARTER
	_check(senior.status == SeniorRoostStateScript.STATUS_ANNUAL_REVIEW, "fourth completed quarter should expose the annual-review gate", failures)
	_check(senior.roost_marks == 15 and senior.available_roost_marks() == 15, "perfect first year should expose quarter and annual marks", failures)
	var annual_preflight := senior.preflight_sponsorship(2, &"predator_loss", &"appeals")
	_check(bool(annual_preflight.get("accepted", false)), "annual review should accept one sponsorship for its completed-quarter gate", failures)
	_check(bool(senior.commit_sponsorship(annual_preflight, _authoritative_receipt(annual_preflight, "Henrietta")).get("accepted", false)), "annual-review sponsorship should commit", failures)
	_check(senior.continue_after_annual(), "annual fixture should continue to the next year's policy gate", failures)
	var same_gate := senior.preflight_sponsorship(3, &"nest_damage", &"predator_loss")
	_check(String(same_gate.get("reason_id", "")) == "already_filed_this_gate", "annual continuation must not reopen the same completed-quarter sponsorship gate", failures)

	_complete_perfect_quarter(senior, next_day, failures)
	var duplicate_hen := senior.preflight_sponsorship(2, &"predator_loss", &"nest_damage")
	_check(String(duplicate_hen.get("reason_id", "")) == "worker_already_sponsored", "a later gate must still reject a second sponsorship for the same hen", failures)
	var later_hen := senior.preflight_sponsorship(3, &"nest_damage", &"predator_loss")
	_check(bool(later_hen.get("accepted", false)), "the next completed quarter should open a new gate for a different hen", failures)


func _test_schema_migration_and_validation(failures: Array[String]) -> void:
	var senior := SeniorRoostStateScript.new()
	_check(senior.begin(5), "migration fixture should begin Senior Roost", failures)
	_complete_perfect_quarter(senior, 6, failures)
	var current := senior.to_dictionary()
	var legacy := current.duplicate(true)
	legacy["schema_version"] = 1
	legacy.erase("roost_marks_spent")
	legacy.erase("sponsorship_history")
	var restored = SeniorRoostStateScript.from_dictionary(legacy)
	_check(restored != null, "valid v1 Senior career should migrate through schema v2, v3, and v4 to schema v5", failures)
	if restored != null:
		var migrated := restored.to_dictionary()
		_check(int(migrated.get("schema_version", -1)) == 5, "migration should emit schema v5", failures)
		_check(restored.roost_marks_spent == 0 and restored.available_roost_marks() == restored.roost_marks, "v1 migration should preserve every lifetime mark as available", failures)
		_check(restored.sponsorship_history.is_empty(), "v1 migration should default to an empty sponsorship ledger", failures)
	_check(int(legacy.get("schema_version", -1)) == 1 and not legacy.has("roost_marks_spent"), "migration must not mutate the caller's v1 Dictionary", failures)

	var preflight := senior.preflight_sponsorship(0, &"appeals", &"nest_damage")
	_check(bool(senior.commit_sponsorship(preflight, _authoritative_receipt(preflight, "Mabel")).get("accepted", false)), "validation fixture should contain one real sponsorship", failures)
	var json_value: Variant = JSON.parse_string(JSON.stringify(senior.to_dictionary()))
	var round_trip = SeniorRoostStateScript.from_dictionary(json_value as Dictionary)
	_check(round_trip != null and round_trip.to_dictionary() == senior.to_dictionary(), "schema-v5 sponsorship state should survive primitive JSON round-trip", failures)

	var overspent := senior.to_dictionary()
	overspent["roost_marks_spent"] = int(overspent["roost_marks"]) + 1
	var overspent_errors := SeniorRoostStateScript.validate_dictionary(overspent)
	_check(_contains_error(overspent_errors, "cannot exceed lifetime"), "validator should reject spent marks above lifetime marks", failures)

	var inconsistent_spend := senior.to_dictionary()
	inconsistent_spend["roost_marks_spent"] = 0
	var spend_errors := SeniorRoostStateScript.validate_dictionary(inconsistent_spend)
	_check(_contains_error(spend_errors, "inconsistent with sponsorship_history"), "validator should reconcile spent marks with exact receipts", failures)

	var bad_gate := senior.to_dictionary()
	(bad_gate["sponsorship_history"] as Array)[0]["career_quarter"] = 0
	var gate_errors := SeniorRoostStateScript.validate_dictionary(bad_gate)
	_check(_contains_error(gate_errors, "later completed-quarter gate"), "validator should reject a sponsorship outside a completed-quarter gate", failures)

	var bad_available := senior.to_dictionary()
	(bad_available["sponsorship_history"] as Array)[0]["available_roost_marks_after"] = 999
	var available_errors := SeniorRoostStateScript.validate_dictionary(bad_available)
	_check(_contains_error(available_errors, "available_roost_marks_after is inconsistent"), "validator should reject a fabricated receipt balance", failures)


func _test_bounded_history(failures: Array[String]) -> void:
	var senior := SeniorRoostStateScript.new()
	_check(senior.begin(5), "bounded-history fixture should begin Senior Roost", failures)
	var next_day := 6
	for gate_index in SeniorRoostStateScript.MAX_SPONSORSHIP_HISTORY:
		_complete_perfect_quarter(senior, next_day, failures)
		next_day += SeniorRoostStateScript.SHIFTS_PER_QUARTER
		var primary_lane: StringName = SeniorRoostStateScript.SPONSORSHIP_LANES[gate_index % SeniorRoostStateScript.SPONSORSHIP_LANES.size()]
		var secondary_lane: StringName = SeniorRoostStateScript.SPONSORSHIP_LANES[(gate_index + 1) % SeniorRoostStateScript.SPONSORSHIP_LANES.size()]
		var preflight := senior.preflight_sponsorship(gate_index, primary_lane, secondary_lane)
		_check(bool(preflight.get("accepted", false)), "bounded-history gate %d should accept its unique hen" % (gate_index + 1), failures)
		_check(bool(senior.commit_sponsorship(preflight, _authoritative_receipt(preflight, "Hen %d" % gate_index)).get("accepted", false)), "bounded-history gate %d should commit" % (gate_index + 1), failures)
		if senior.status == SeniorRoostStateScript.STATUS_ANNUAL_REVIEW:
			_check(senior.continue_after_annual(), "bounded-history annual gate should continue", failures)
	_check(senior.sponsorship_history.size() == SeniorRoostStateScript.MAX_SPONSORSHIP_HISTORY, "sponsorship receipts should stop at the declared bound", failures)
	_check(senior.roost_marks_spent == SeniorRoostStateScript.MAX_SPONSORSHIP_HISTORY * 3, "bounded history should reconcile every three-mark transaction", failures)
	_check(SeniorRoostStateScript.validate_dictionary(senior.to_dictionary()).is_empty(), "full bounded sponsorship history should remain strictly valid", failures)

	_complete_perfect_quarter(senior, next_day, failures)
	var overflow := senior.preflight_sponsorship(
		SeniorRoostStateScript.MAX_SPONSORSHIP_HISTORY,
		&"appeals",
		&"nest_damage",
	)
	_check(not bool(overflow.get("accepted", true)) and String(overflow.get("reason_id", "")) == "history_capacity", "the first sponsorship beyond the bound should be rejected explicitly", failures)


func _complete_perfect_quarter(
	senior: SeniorRoostState,
	start_day: int,
	failures: Array[String],
) -> void:
	if senior.requires_annual_mandate():
		var selection := senior.select_annual_mandate(
			SeniorRoostStateScript.MANDATE_FALLBACK_ID,
			senior.current_year_number(),
		)
		_check(bool(selection.get("accepted", false)), "annual fallback mandate should file before Q1 policy", failures)
	_check(senior.record_quarter_policy(_policy_receipt()), "quarter policy should file before Senior work", failures)
	for offset in SeniorRoostStateScript.SHIFTS_PER_QUARTER:
		var result := senior.record_shift(_good_report(start_day + offset))
		_check(bool(result.get("accepted", false)), "Senior day %d should file" % (start_day + offset), failures)


func _policy_receipt() -> Dictionary:
	return {
		"accepted": true,
		"policy_id": &"harvest_forecast",
		"style_id": &"management_innovation",
		"outcome": "Quarter policy filed.",
	}


func _authoritative_receipt(preflight: Dictionary, worker_name: String) -> Dictionary:
	return {
		"accepted": true,
		"action_id": &"career_sponsorship",
		"worker_id": int(preflight.get("worker_id", -1)),
		"worker_name": worker_name,
		"primary_lane": String(preflight.get("primary_lane", "")),
		"secondary_lane": String(preflight.get("secondary_lane", "")),
		"fund_cost_cents": 1200,
	}


func _good_report(day: int) -> Dictionary:
	return {
		"day": day,
		"eggs": 30,
		"quota": 24,
		"cracked": 2,
		"overdue_claims": 0,
		"rework_total_created": day,
		"credited_cents": 12_000,
		"welfare": 72,
		"compliance": 76,
		"farmer_favor": 66,
		"wage_arrears_cents": 0,
		"closing_fund_cents": 20_000 + day * 100,
	}


func _contains_error(errors: PackedStringArray, needle: String) -> bool:
	for error in errors:
		if needle in error:
			return true
	return false


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
