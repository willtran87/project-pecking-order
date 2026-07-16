extends SceneTree


const TreasuryState := preload("res://core/simulation/farm_treasury_state.gd")


func _init() -> void:
	var failures: Array[String] = []
	_test_credit_terms_and_rating(failures)
	_test_credit_arrears_priority_and_conservation(failures)
	_test_labor_boundary_and_principal_priority(failures)
	_test_quote_rejection_and_receipt_immutability(failures)
	_test_history_json_restore_and_corruption_rejection(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("FARM_TREASURY_STATE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARM_TREASURY_STATE_TEST_PASSED conservation=exact credit=standing-capped interest=5-3pct-min1 priority=signed labor=external-cash-only rating=two-tier history=32 json=strict neutral=migration-safe")
	quit(0)


func _test_credit_terms_and_rating(failures: Array[String]) -> void:
	var state := TreasuryState.new(10_000, 0)
	_check(state.credit_limit_cents(0) == 5_000, "zero standing should open the exact $50 line", failures)
	_check(state.credit_limit_cents(10) == 10_000, "ten standing should add exactly $50", failures)
	_check(state.credit_limit_cents(100) == 15_000, "standing-derived credit should cap at $150", failures)
	_check(state.interest_basis_points() == 500, "unrated credit should charge 5%", failures)

	for target_day in range(1, 7):
		var receipt := state.close_shift(
			target_day,
			0,
			{"production": 1_000},
			{"feed": 500},
		)
		_check(bool(receipt.get("accepted", false)), "profitable close %d should file" % target_day, failures)
		_check(bool(receipt.get("debt_free", false)), "profitable close %d should remain debt-free" % target_day, failures)
		_check(int(receipt.get("operating_margin_cents", 0)) == 500, "profitable close should disclose exact $5 margin", failures)
		if target_day == 3:
			_check(bool(receipt.get("rating_advanced", false)), "third clean profitable close should earn rating one", failures)
			_check(state.credit_rating == 1 and state.solvency_streak == 0, "first rating should reset the three-close counter", failures)
			_check(int(receipt.get("closing_credit_limit_cents", 0)) == 7_500, "rating one should add an exact $25 line bonus", failures)
			_check(state.interest_basis_points() == 400, "rating one should reduce future interest to 4%", failures)
		if target_day == 6:
			_check(bool(receipt.get("rating_advanced", false)), "sixth clean profitable close should earn rating two", failures)
			_check(state.credit_rating == 2 and state.solvency_streak == 0, "second rating should be the terminal earned tier", failures)
			_check(state.credit_limit_cents(100) == 20_000, "two ratings should lift the capped standing line from $150 to $200", failures)
			_check(state.interest_basis_points() == 300, "rating two should reduce future interest to 3%", failures)

	# At maximum rating, clean closes retain a bounded three-shift badge without
	# minting a third tier.
	for target_day in range(7, 11):
		state.close_shift(target_day, 0, {"production": 1_000}, {"feed": 500})
	_check(state.credit_rating == 2 and state.solvency_streak == 3, "terminal rating and streak should remain bounded", failures)


func _test_credit_arrears_priority_and_conservation(failures: Array[String]) -> void:
	var state := TreasuryState.new(0, 0)
	var saturated := state.close_shift(
		1,
		0,
		{},
		{"facilities": 3_000, "feed": 3_000},
	)
	_check(bool(saturated.get("accepted", false)), "empty-fund close should still file every obligation", failures)
	_check(int(saturated.get("credit_draw_cents", -1)) == 5_000, "automatic credit should draw the full zero-standing line", failures)
	_check(int(saturated.get("closing_credit_principal_cents", -1)) == 5_000, "the full draw should remain exact principal", failures)
	_check(int(saturated.get("closing_vendor_arrears_cents", -1)) == 1_000, "uncovered vendor cost must persist instead of disappearing", failures)
	_assert_conserved(saturated, "saturated close", failures)

	var interest_arrears := state.close_shift(2, 0, {}, {})
	_check(int(interest_arrears.get("interest_charged_cents", -1)) == 250, "$50 principal should charge exact 5% interest", failures)
	_check(int(interest_arrears.get("closing_interest_arrears_cents", -1)) == 250, "interest beyond a saturated line should remain a liability", failures)
	_check(int(interest_arrears.get("closing_vendor_arrears_cents", -1)) == 1_000, "existing vendor arrears should carry exactly", failures)
	_assert_conserved(interest_arrears, "interest-arrears close", failures)

	var recovery := state.close_shift(3, 0, {"farmgate": 2_000}, {})
	_check(int(recovery.get("cash_paid_interest_arrears_cents", -1)) == 250, "cash should pay carried interest first", failures)
	_check(int(recovery.get("cash_paid_vendor_arrears_cents", -1)) == 1_000, "cash should pay carried vendors second", failures)
	_check(int(recovery.get("cash_paid_current_interest_cents", -1)) == 250, "cash should pay current interest third", failures)
	_check(int(recovery.get("principal_repaid_cents", -1)) == 500, "remaining cash should sweep principal last", failures)
	_check(int(recovery.get("closing_credit_principal_cents", -1)) == 4_500, "recovery sweep should leave exact principal", failures)
	_check(int(recovery.get("closing_vendor_arrears_cents", -1)) == 0 and int(recovery.get("closing_interest_arrears_cents", -1)) == 0, "recovery should clear both carried liability classes", failures)
	_assert_conserved(recovery, "recovery close", failures)

	var tiny := TreasuryState.new(0, 0)
	# Create one cent of principal through a valid vendor draw. The authored minimum
	# makes the following shift's interest exactly $1 rather than rounding to zero.
	var one_cent := tiny.close_shift(1, 0, {}, {"feed": 1})
	_check(int(one_cent.get("closing_credit_principal_cents", -1)) == 1, "one-cent vendor cost should draw one cent", failures)
	var minimum_interest := tiny.close_shift(2, 0, {}, {})
	_check(int(minimum_interest.get("interest_charged_cents", -1)) == 100, "nonzero principal should charge the exact $1 minimum", failures)
	_assert_conserved(minimum_interest, "minimum-interest close", failures)


func _test_labor_boundary_and_principal_priority(failures: Array[String]) -> void:
	var leveraged := TreasuryState.new(0, 0)
	var borrowing := leveraged.close_shift(1, 0, {}, {"feed": 5_000})
	_check(int(borrowing.get("closing_credit_principal_cents", -1)) == 5_000, "setup should borrow the exact zero-standing line", failures)

	var payroll_close := leveraged.close_shift(2, 0, {"production": 2_000}, {}, 1_000)
	_check(int(payroll_close.get("interest_charged_cents", -1)) == 250, "labor close should first charge exact opening-principal interest", failures)
	_check(int(payroll_close.get("labor_due_cents", -1)) == 1_000, "receipt should preserve the external labor obligation", failures)
	_check(int(payroll_close.get("labor_paid_cents", -1)) == 1_000, "available post-vendor cash should pay labor in full", failures)
	_check(int(payroll_close.get("labor_unpaid_cents", -1)) == 0, "fully paid labor should return no wage arrears", failures)
	_check(int(payroll_close.get("principal_repaid_cents", -1)) == 750, "principal may consume only cash left after labor", failures)
	_check(int(payroll_close.get("closing_credit_principal_cents", -1)) == 4_250, "labor-first sweep should leave exact principal", failures)
	_assert_conserved(payroll_close, "labor-before-principal close", failures)

	var cash_only := TreasuryState.new(0, 0)
	var underfunded := cash_only.close_shift(1, 0, {"production": 1_000}, {}, 1_600)
	_check(int(underfunded.get("labor_paid_cents", -1)) == 1_000, "labor should receive all available cash", failures)
	_check(int(underfunded.get("labor_unpaid_cents", -1)) == 600, "unpaid labor should be reported exactly for external wage arrears", failures)
	_check(int(underfunded.get("credit_draw_cents", -1)) == 0, "automatic credit must never fund labor", failures)
	_check(int(underfunded.get("closing_credit_principal_cents", -1)) == 0, "unpaid labor must not become treasury principal", failures)
	_check(int(underfunded.get("closing_vendor_arrears_cents", -1)) == 0, "unpaid labor must not become vendor arrears", failures)
	_check(not bool(underfunded.get("debt_free", true)), "unpaid labor must block a clean solvency close", failures)
	_assert_conserved(underfunded, "cash-only labor close", failures)


func _test_quote_rejection_and_receipt_immutability(failures: Array[String]) -> void:
	var state := TreasuryState.new(5_000, 4)
	var before := state.to_save_data()
	var quote := state.quote_close(5, 2, {"production": 900}, {"feed": 700})
	_check(bool(quote.get("accepted", false)), "valid next-day quote should preview", failures)
	_check(state.to_save_data() == before, "pure quote must not mutate the ledger", failures)

	var invalid_day := state.close_shift(6, 2, {"production": 900}, {"feed": 700})
	_check(not bool(invalid_day.get("accepted", true)), "a skipped close day should reject", failures)
	var invalid_key := state.close_shift(5, 2, {"Bad Label": 900}, {"feed": 700})
	_check(not bool(invalid_key.get("accepted", true)), "unsafe category names should reject", failures)
	var invalid_money := state.close_shift(5, 2, {"production": -1}, {"feed": 700})
	_check(not bool(invalid_money.get("accepted", true)), "negative category cents should reject", failures)
	var invalid_labor := state.close_shift(5, 2, {"production": 900}, {"feed": 700}, -1)
	_check(not bool(invalid_labor.get("accepted", true)), "negative external labor cents should reject", failures)
	_check(state.to_save_data() == before, "every rejected close must remain atomic", failures)

	var receipt := state.close_shift(5, 2, {"production": 900}, {"feed": 700})
	var filed_cash := state.cash_cents
	receipt["closing_cash_cents"] = -99
	_check(state.cash_cents == filed_cash, "mutating a returned receipt must not mutate treasury state", failures)
	_check(int(state.last_receipt.get("closing_cash_cents", -1)) == filed_cash, "mutating a returned receipt must not mutate the last receipt", failures)
	var archived_view := state.last_receipt
	archived_view["closing_cash_cents"] = -101
	_check(int(state.last_receipt.get("closing_cash_cents", -1)) == filed_cash, "mutating an archive view must not mutate the filed receipt", failures)


func _test_history_json_restore_and_corruption_rejection(failures: Array[String]) -> void:
	var source := TreasuryState.new(10_000, 0)
	for target_day in range(1, 36):
		var receipt := source.close_shift(
			target_day,
			target_day % 24,
			{"production": 200},
			{"feed": 100},
		)
		_assert_conserved(receipt, "history close %d" % target_day, failures)
	_check(source.history.size() == TreasuryState.HISTORY_LIMIT, "history should retain exactly the latest 32 receipts", failures)
	_check(int(source.history[0].get("receipt_id", -1)) == 4 and int(source.history[-1].get("receipt_id", -1)) == 35, "bounded history should retain a contiguous receipt tail", failures)

	var parsed: Variant = JSON.parse_string(JSON.stringify(source.to_save_data()))
	var restored := TreasuryState.new()
	_check(parsed is Dictionary and restored.restore_save_data(parsed), "canonical JSON should restore", failures)
	_check(restored.to_save_data() == source.to_save_data(), "restored authoritative state should match exactly", failures)

	var neutral_data := TreasuryState.neutral_save_data(12_345, 8)
	var neutral := TreasuryState.new()
	_check(neutral.restore_save_data(neutral_data), "neutral migration data should restore", failures)
	_check(neutral.cash_cents == 12_345 and neutral.last_closed_day == 8, "neutral migration should preserve only cash and completed day", failures)
	_check(neutral.credit_principal_cents == 0 and neutral.history.is_empty(), "neutral migration must invent no debt or receipts", failures)
	_check(bool(neutral.close_shift(9, 0, {}, {}).get("accepted", false)), "neutral migration should accept the next chronological close", failures)

	var corrupt_unknown := (parsed as Dictionary).duplicate(true)
	corrupt_unknown["invented_dividend"] = 1
	var target := TreasuryState.new(777, 2)
	var target_before := target.to_save_data()
	_check(not target.restore_save_data(corrupt_unknown), "unknown save fields should reject", failures)
	_check(target.to_save_data() == target_before, "unknown-field rejection should be atomic", failures)

	var corrupt_receipt := (parsed as Dictionary).duplicate(true)
	var corrupt_history := (corrupt_receipt["history"] as Array).duplicate(true)
	var changed := (corrupt_history[-1] as Dictionary).duplicate(true)
	changed["closing_cash_cents"] = int(changed["closing_cash_cents"]) + 1
	corrupt_history[-1] = changed
	corrupt_receipt["history"] = corrupt_history
	corrupt_receipt["last_receipt"] = changed.duplicate(true)
	corrupt_receipt["cash_cents"] = int(corrupt_receipt["cash_cents"]) + 1
	_check(not TreasuryState.new().restore_save_data(corrupt_receipt), "a non-conserving replayed receipt should reject", failures)

	var corrupt_chain := (parsed as Dictionary).duplicate(true)
	var chain_history := (corrupt_chain["history"] as Array).duplicate(true)
	var chain_row := (chain_history[1] as Dictionary).duplicate(true)
	chain_row["opening_cash_cents"] = int(chain_row["opening_cash_cents"]) + 1
	chain_history[1] = chain_row
	corrupt_chain["history"] = chain_history
	_check(not TreasuryState.new().restore_save_data(corrupt_chain), "a broken retained receipt chain should reject", failures)


func _assert_conserved(receipt: Dictionary, label: String, failures: Array[String]) -> void:
	_check(
		int(receipt.get("conservation_left_cents", -1))
		== int(receipt.get("conservation_right_cents", -2)),
		"%s should conserve every cent" % label,
		failures,
	)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
