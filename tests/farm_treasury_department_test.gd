extends SceneTree


const Treasury := preload("res://core/simulation/farm_treasury_state.gd")


func _init() -> void:
	var failures: Array[String] = []
	_test_v22_neutral_migration_and_smuggling_guard(failures)
	_test_zero_cash_close_round_trip_and_tamper_rejection(failures)
	_test_exhausted_line_freezes_capital(failures)
	if not failures.is_empty():
		for failure: String in failures:
			push_error("FARM_TREASURY_DEPARTMENT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARM_TREASURY_DEPARTMENT_TEST_PASSED schema=v23 migration=v22-neutral close=conserving labor=external debt=durable capital=freeze tamper=atomic")
	quit(0)


func _test_v22_neutral_migration_and_smuggling_guard(failures: Array[String]) -> void:
	var current := DepartmentSimulation.new(23_101, 4).export_save_state()
	var legacy := current.duplicate(true)
	legacy["state_version"] = 22
	legacy.erase("farm_treasury_state")
	var target := DepartmentSimulation.new(23_102, 4)
	_check(target.restore_save_state(_json_round_trip(legacy)), "canonical v22 checkpoint should migrate", failures)
	var migrated: Dictionary = _json_round_trip(target.export_save_state()) as Dictionary
	_check(int(migrated.get("state_version", -1)) == 23, "v22 checkpoint should re-export as v23", failures)
	_check(
		migrated.get("farm_treasury_state", {})
		== _json_round_trip(Treasury.neutral_save_data(5000, 0)),
		"v22 migration should preserve cash while inventing no debt, rating, or receipts",
		failures,
	)

	var smuggled := legacy.duplicate(true)
	smuggled["farm_treasury_state"] = Treasury.neutral_save_data(5000, 0)
	var guarded := DepartmentSimulation.new(23_103, 4)
	var before: Dictionary = _json_round_trip(guarded.export_save_state()) as Dictionary
	_check(not guarded.restore_save_state(_json_round_trip(smuggled)), "claimed v22 checkpoint must reject a smuggled v23 treasury root", failures)
	_check(_json_round_trip(guarded.export_save_state()) == before, "rejected treasury migration must leave the target atomic", failures)


func _test_zero_cash_close_round_trip_and_tamper_rejection(failures: Array[String]) -> void:
	var source := DepartmentSimulation.new(23_201, 4)
	source.revenue_cents = 0
	source.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	var report_box := {"report": {}}
	source.workday_completed.connect(func(report: Dictionary) -> void:
		report_box["report"] = report.duplicate(true)
	, CONNECT_ONE_SHOT)
	source._complete_workday()
	var report := report_box.get("report", {}) as Dictionary
	var receipt := report.get("farm_treasury_receipt", {}) as Dictionary
	_check(not receipt.is_empty(), "zero-cash close should emit a treasury receipt", failures)
	var vendor_breakdown := receipt.get("vendor_breakdown", {}) as Dictionary
	_check(int(vendor_breakdown.get("daily_feed_service", -1)) == 1400, "four hens should file the exact $14 feed invoice", failures)
	_check(int(receipt.get("current_vendor_due_cents", -1)) == 6400, "journal should reconcile the explicit $50 cash reset plus the $14 feed invoice", failures)
	_check(int(receipt.get("credit_draw_cents", -1)) == 1400, "the operating line should cover that exact vendor invoice", failures)
	_check(int(receipt.get("labor_due_cents", -1)) == 1600, "the labor boundary should receive exact four-hen payroll", failures)
	_check(int(receipt.get("labor_unpaid_cents", -1)) == 1600, "credit must never finance labor", failures)
	_check(int(receipt.get("conservation_left_cents", -1)) == int(receipt.get("conservation_right_cents", -2)), "department close must conserve every cent", failures)

	var valid: Dictionary = _json_round_trip(source.export_save_state()) as Dictionary
	var restored := DepartmentSimulation.new(23_202, 4)
	_check(restored.restore_save_state(valid), "debt-bearing v23 checkpoint should restore", failures)
	_check(
		_json_round_trip(restored.farm_treasury_snapshot())
		== _json_round_trip(source.farm_treasury_snapshot()),
		"credit, invoices, interest, rating, and receipt archive should round-trip exactly",
		failures,
	)

	var corrupted: Dictionary = valid.duplicate(true)
	var treasury := (corrupted.get("farm_treasury_state", {}) as Dictionary).duplicate(true)
	var history := (treasury.get("history", []) as Array).duplicate(true)
	var corrupt_receipt := (history[-1] as Dictionary).duplicate(true)
	corrupt_receipt["closing_credit_principal_cents"] = int(corrupt_receipt["closing_credit_principal_cents"]) + 1
	history[-1] = corrupt_receipt
	treasury["history"] = history
	corrupted["farm_treasury_state"] = treasury
	var guarded := DepartmentSimulation.new(23_203, 4)
	var before: Dictionary = _json_round_trip(guarded.export_save_state()) as Dictionary
	_check(not guarded.restore_save_state(_json_round_trip(corrupted)), "one-cent treasury receipt tamper must reject", failures)
	_check(_json_round_trip(guarded.export_save_state()) == before, "failed treasury restore must remain atomic", failures)


func _test_exhausted_line_freezes_capital(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(23_301, 4)
	var standing := maxi(0, simulation.farm_mutual_standing())
	var treasury := Treasury.new(0, 0)
	var limit := treasury.credit_limit_cents(standing)
	var receipt := treasury.close_shift(1, standing, {}, {"vendor_invoice": limit}, 0)
	_check(bool(receipt.get("accepted", false)), "capital-freeze fixture should fill its exact revolving line", failures)
	simulation._farm_treasury = treasury
	simulation.day = 2
	simulation.revenue_cents = 100_000
	_check(simulation.farm_treasury_capital_frozen(), "a fully drawn operating line with liabilities should freeze capital", failures)
	_check(simulation.spendable_fund_cents() == 0, "capital freeze should override apparent cash surplus", failures)
	_check(int(simulation.snapshot().get("spendable_fund_cents", -1)) == 0, "canonical snapshot should expose the same freeze", failures)


func _json_round_trip(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
