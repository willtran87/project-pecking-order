extends SceneTree


const DEPOT := DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID
const PACKING := DepartmentSimulation.PACKING_ANNEX_ID
const GALLERY := DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID


func _init() -> void:
	var failures: Array[String] = []
	_test_pin_receipt_history_and_max_clear(failures)
	_test_pinned_plan_and_receipt_round_trip(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("CAPITAL_PLAN_COMMISSIONING_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAPITAL_PLAN_COMMISSIONING_TEST_PASSED pin=persistent clear=max-only receipt=exact effects=copied history=bounded restore=strict")
	quit(0)


func _test_pin_receipt_history_and_max_clear(failures: Array[String]) -> void:
	var sim := _tier_one_fixture(20_301, false)
	var pin := sim.pin_capital_plan(DEPOT)
	_check(bool(pin.get("accepted", false)) and sim.pinned_capital_plan_id == DEPOT, "available facility should pin as the capital plan", failures)
	var days := [6, 10, 14]
	var costs := [12_000, 20_000, 32_000]
	var upkeep_deltas := [700, 600, 900]
	var storage := [12, 24, 42]
	for index in 3:
		sim.day = days[index]
		sim._farmgate_dispatch.begin_day(days[index])
		sim.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
		sim.pending_decision.clear()
		sim.owned_facilities[PACKING] = index + 1
		sim.owned_facilities[GALLERY] = index + 1
		sim._harvest_credit.public_standing = [5, 12, 25][index]
		var fund_before := sim.revenue_cents
		var spendable_before := sim.spendable_fund_cents()
		var reserve_before := sim.protected_reserve_cents()
		var upkeep_before := sim.current_daily_facility_maintenance_cents()
		var result := sim.purchase_facility(DEPOT)
		_check(bool(result.get("accepted", false)), "depot tier %d purchase should accept" % (index + 1), failures)
		var receipt := result.get("commissioning_receipt", {}) as Dictionary
		_check(receipt.size() == DepartmentSimulation.FACILITY_PURCHASE_RECEIPT_KEYS.size(), "receipt should contain only the strict commissioning fields", failures)
		_check(int(receipt.get("cost_cents", -1)) == costs[index], "receipt tier %d cost should match" % (index + 1), failures)
		_check(int(receipt.get("fund_before_cents", -1)) == fund_before and int(receipt.get("fund_after_cents", -1)) == fund_before - costs[index], "receipt should preserve exact before/after Feed Fund", failures)
		_check(int(receipt.get("spendable_before_cents", -1)) == spendable_before and int(receipt.get("spendable_after_cents", -1)) == sim.spendable_fund_cents(), "receipt should preserve exact before/after spendable fund", failures)
		_check(int(receipt.get("protected_reserve_before_cents", -1)) == reserve_before and int(receipt.get("protected_reserve_after_cents", -1)) == sim.protected_reserve_cents(), "receipt should preserve exact protected reserve", failures)
		_check(int(receipt.get("upkeep_before_cents", -1)) == upkeep_before and int(receipt.get("upkeep_after_cents", -1)) == sim.current_daily_facility_maintenance_cents(), "receipt should preserve total upkeep before and after", failures)
		_check(int(receipt.get("upkeep_delta_cents", -1)) == upkeep_deltas[index], "tier %d upkeep delta should match" % (index + 1), failures)
		var effect := receipt.get("effect", {}) as Dictionary
		_check(int(effect.get("storage_capacity_eggs", -1)) == storage[index], "receipt should copy the installed storage effect", failures)
		_check((effect.get("benefits", []) as Array) == (DepartmentSimulation.FACILITY_DEFINITIONS[DEPOT].get("benefits", []) as Array), "receipt should copy authored benefits exactly", failures)
		_check((effect.get("tradeoffs", []) as Array) == (DepartmentSimulation.FACILITY_DEFINITIONS[DEPOT].get("tradeoffs", []) as Array), "receipt should copy authored tradeoffs exactly", failures)
		if index < 2:
			_check(sim.pinned_capital_plan_id == DEPOT, "pin should remain until the facility becomes maxed", failures)
		else:
			_check(sim.pinned_capital_plan_id == &"", "pin should clear exactly when tier three becomes maxed", failures)
	_check(sim.facility_commissioning_history.size() == 3, "three purchases should append three commissioning receipts", failures)
	_check(sim.last_facility_purchase_receipt == sim.facility_commissioning_history[-1], "last receipt should equal the bounded history tail", failures)
	var history_before := sim.facility_commissioning_history.duplicate(true)
	var duplicate := sim.purchase_facility(DEPOT)
	_check(not bool(duplicate.get("accepted", true)), "fully commissioned duplicate purchase should reject", failures)
	_check(sim.facility_commissioning_history == history_before, "rejected purchase should not append or mutate receipts", failures)


func _test_pinned_plan_and_receipt_round_trip(failures: Array[String]) -> void:
	var source := _tier_one_fixture(20_311, true)
	var encoded: Variant = JSON.parse_string(JSON.stringify(source.export_save_state()))
	var restored := DepartmentSimulation.new(20_312, 6)
	_check(encoded is Dictionary and restored.restore_save_state(encoded), "canonical pinned-plan JSON should restore", failures)
	_check(restored.pinned_capital_plan_id == DEPOT, "non-maxed pinned depot should persist", failures)
	_check(restored.last_facility_purchase_receipt == source.last_facility_purchase_receipt, "commissioning receipt should round-trip exactly", failures)
	_check(restored.facility_commissioning_history == source.facility_commissioning_history, "commissioning history should round-trip exactly", failures)

	var corrupt := (encoded as Dictionary).duplicate(true)
	corrupt["pinned_capital_plan_id"] = "unlicensed_barn_extension"
	var target := DepartmentSimulation.new(20_313, 6)
	var before := JSON.stringify(target.export_save_state())
	_check(not target.restore_save_state(corrupt), "unknown pinned facility should reject", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "pin rejection should remain atomic", failures)

	corrupt = (encoded as Dictionary).duplicate(true)
	var last := (corrupt.get("last_facility_purchase_receipt", {}) as Dictionary).duplicate(true)
	var effect := (last.get("effect", {}) as Dictionary).duplicate(true)
	effect["storage_capacity_eggs"] = 13
	last["effect"] = effect
	var history := (corrupt.get("facility_commissioning_history", []) as Array).duplicate(true)
	history[-1] = last.duplicate(true)
	corrupt["last_facility_purchase_receipt"] = last
	corrupt["facility_commissioning_history"] = history
	_check(not target.restore_save_state(corrupt), "tampered installed effect should reject", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "effect rejection should remain atomic", failures)


func _tier_one_fixture(seed: int, purchase_tier_one: bool) -> DepartmentSimulation:
	var sim := DepartmentSimulation.new(seed, 6)
	sim.day = 6
	sim.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	sim.pending_decision.clear()
	sim.revenue_cents = 1_000_000
	sim.owned_facilities[PACKING] = 1
	sim.owned_facilities[GALLERY] = 1
	_file_canonical_harvest_credit(sim)
	if purchase_tier_one:
		sim.pin_capital_plan(DEPOT)
		var receipt := sim.purchase_facility(DEPOT)
		if not bool(receipt.get("accepted", false)):
			push_error("Tier-one fixture failed: %s" % String(receipt.get("reason", "unknown")))
	return sim


func _file_canonical_harvest_credit(sim: DepartmentSimulation) -> void:
	var evidence := {
		"day": 5,
		"eggs": 8,
		"quota": 8,
		"sound": 7,
		"cracked": 1,
		"golden": 1,
		"met_quota": true,
		"top_worker_id": 0,
		"top_worker_name": "Mabel",
		"hen_highlight": {
			"version": 1,
			"day": 5,
			"worker_id": 0,
			"worker_name": "Mabel",
			"tone": &"gold",
		},
	}
	sim._harvest_credit.stage_review(evidence, 1, false)
	sim._harvest_credit.commit_campaign(&"farmer_method", "Canonical commissioning standing.")


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
