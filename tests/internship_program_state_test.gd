extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var program := InternshipProgramState.new()

	var locked := program.snapshot(1, 2000, true, 1)
	_check(not bool(locked.get("unlocked", true)), "program should unlock on Day 2", failures)
	_check(
		not bool((locked.get("candidates", []) as Array)[0].get("can_onboard", true)),
		"locked candidates should not be onboardable",
		failures,
	)

	var onboard := program.onboard(&"lottie_ledger", 2, 2000, true, 1)
	_check(bool(onboard.get("accepted", false)), "Lottie should onboard in an open seat", failures)
	_check(program.claim_capacity_bonus() == 1, "guided shadow should add one live file", failures)
	_check(is_equal_approx(program.work_multiplier(), 1.01), "guided shadow should add one percent work", failures)

	var full_seat := program.onboard(&"chip_chirper", 2, 1700, true, 1)
	_check(not bool(full_seat.get("accepted", true)), "one supervised seat should enforce its limit", failures)

	var stretch := program.assign(&"lottie_ledger", &"stretch_project", 2, true)
	_check(bool(stretch.get("accepted", false)), "active interns should accept planning assignments", failures)
	_check(program.claim_capacity_bonus() == 2, "stretch work should disclose two live files", failures)
	_check(is_equal_approx(program.work_multiplier(), 1.04), "stretch work should add four percent work", failures)
	_check(is_equal_approx(program.crack_modifier(), 0.01), "stretch work should add one percent shell risk", failures)

	program.complete_shift(2)
	program.complete_shift(3)
	var transitions := program.complete_shift(4)
	_check(transitions.size() == 1, "the third completed shift should file one term review", failures)
	var review_snapshot := program.snapshot(5, 2000, true, 1)
	_check(
		_status_for(review_snapshot, &"lottie_ledger") == &"review",
		"the completed rotation should await an explicit review",
		failures,
	)
	_check(program.claim_capacity_bonus() == 0, "reviewing interns should stop affecting production", failures)

	var extension := program.resolve_review(&"lottie_ledger", &"growth_extension", 5, 2000, true)
	_check(bool(extension.get("accepted", false)), "growth extension should restart the active rotation", failures)
	program.complete_shift(5)
	program.complete_shift(6)
	var underfunded_fellowship := program.resolve_review(
		&"lottie_ledger",
		&"paid_fellowship",
		7,
		999,
		true,
	)
	_check(
		not bool(underfunded_fellowship.get("accepted", true)),
		"fellowship should protect both its filing cost and first daily payroll reserve",
		failures,
	)
	var fellowship := program.resolve_review(&"lottie_ledger", &"paid_fellowship", 7, 2000, true)
	_check(bool(fellowship.get("accepted", false)), "a reviewed intern should be convertible to a paid fellow", failures)
	_check(program.fellow_count() == 1, "paid fellowship should remain as a permanent junior post", failures)
	_check(program.claim_capacity_bonus() == 1, "paid fellowship should provide its disclosed capacity", failures)
	_check(
		program.daily_fellow_payroll_cents() == 200
		and int(fellowship.get("required_spendable_cents", 0)) == 1000,
		"paid fellowship should create a disclosed $2 daily payroll obligation",
		failures,
	)

	var save_data := program.to_save_data()
	var restored := InternshipProgramState.new()
	_check(restored.restore_save_data(save_data, 7), "valid internship data should restore", failures)
	_check(restored.fellow_count() == 1, "restored data should preserve the paid fellow", failures)
	var tampered := save_data.duplicate(true)
	(tampered.get("records", []) as Array)[0]["status"] = "executive"
	_check(
		not InternshipProgramState.new().restore_save_data(tampered, 7),
		"unknown internship statuses should fail closed",
		failures,
	)

	var recommendation_program := InternshipProgramState.new()
	recommendation_program.onboard(&"marigold_memo", 2, 2000, true, 1)
	recommendation_program.complete_shift(2)
	recommendation_program.complete_shift(3)
	recommendation_program.complete_shift(4)
	var recommendation := recommendation_program.resolve_review(
		&"marigold_memo",
		&"recommendation_letter",
		5,
		2000,
		true,
	)
	_check(bool(recommendation.get("accepted", false)), "a recommendation should resolve a review", failures)
	_check(
		_status_for(recommendation_program.snapshot(5, 2000, true, 1), &"marigold_memo")
			== &"completed",
		"recommendation alumni should leave without an active production effect",
		failures,
	)

	if not failures.is_empty():
		for failure in failures:
			push_error("INTERNSHIP_PROGRAM_STATE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("INTERNSHIP_PROGRAM_STATE_TEST_PASSED cast=4 term=3 review=explicit fellowship=payroll-backed save=roundtrip")
	quit(0)


func _status_for(snapshot: Dictionary, candidate_id: StringName) -> StringName:
	for candidate_value in snapshot.get("candidates", []):
		if not candidate_value is Dictionary:
			continue
		var candidate := candidate_value as Dictionary
		if StringName(String(candidate.get("candidate_id", ""))) == candidate_id:
			return StringName(String(candidate.get("status", "")))
	return &""


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
