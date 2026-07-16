extends SceneTree


const LOW_OFFER: StringName = &"homestead_stability_binder"
const MID_OFFER: StringName = &"predator_watch_pool"
const HIGH_OFFER: StringName = &"exceptions_retention_covenant"
const RECORDS_ANNEX: StringName = &"records_annex"


func _init() -> void:
	var failures: Array[String] = []
	_test_day_three_gate_and_exact_offer_catalog(failures)
	_test_capacity_gates_and_exact_reserve(failures)
	_test_signing_rejections_are_atomic(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("MARKET_CONTRACT_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MARKET_CONTRACT_ECONOMY_TEST_PASSED gate=day3 offers=3 capacity=18-24-30 reserve=exact signing=atomic")
	quit(0)


func _test_day_three_gate_and_exact_offer_catalog(failures: Array[String]) -> void:
	var locked := _review_simulation(9601, 2)
	locked.revenue_cents = 100_000
	var locked_board := locked.market_contract_board_status()
	_check(not bool(locked_board.get("unlocked", true)), "Farm Mutual should remain locked on day two", failures)
	_check(int(locked_board.get("unlock_day", -1)) == 3, "the Board should disclose its day-three gate", failures)
	_check(locked.market_contract_offer_catalog().is_empty(), "the locked Board should not publish signable folders", failures)
	var locked_offer := locked.market_contract_offer_preflight(LOW_OFFER)
	_check(bool(locked_offer.get("known", false)), "a known binder should remain explainable while locked", failures)
	_check(not bool(locked_offer.get("can_sign", true)), "day two must reject a known binder", failures)
	_check("two shifts" in String(locked_offer.get("reason", "")).to_lower(), "the day gate should explain the two-shift requirement", failures)

	var simulation := _review_simulation(9602, 3)
	simulation.revenue_cents = 100_000
	var offers := simulation.market_contract_offer_catalog()
	_check(offers.size() == 3, "day three should expose exactly three authored binders", failures)
	var expected: Array[Dictionary] = [
		{
			"id": LOW_OFFER,
			"capacity": 18,
			"staff": 4,
			"total": 5,
			"required": 4,
			"window": 120,
			"premium": 1000,
			"breach": 500,
			"mix": {"nest_damage": 4, "predator_loss": 1},
			"times": [9 * 60, 11 * 60],
		},
		{
			"id": MID_OFFER,
			"capacity": 24,
			"staff": 5,
			"total": 6,
			"required": 5,
			"window": 180,
			"premium": 1600,
			"breach": 800,
			"mix": {"nest_damage": 1, "predator_loss": 5},
			"times": [9 * 60, 12 * 60],
		},
		{
			"id": HIGH_OFFER,
			"capacity": 30,
			"staff": 6,
			"total": 6,
			"required": 5,
			"window": 240,
			"premium": 2400,
			"breach": 1200,
			"mix": {"nest_damage": 1, "predator_loss": 1, "appeals": 4},
			"times": [9 * 60, 13 * 60],
		},
	]
	for index in mini(offers.size(), expected.size()):
		var offer := offers[index] as Dictionary
		var contract := expected[index]
		_check(StringName(offer.get("id", &"")) == contract["id"], "offer %d should retain its stable authored order" % index, failures)
		_check(int(offer.get("required_claim_capacity", -1)) == int(contract["capacity"]), "%s should disclose its exact Records capacity" % contract["id"], failures)
		_check(int(offer.get("required_active_staff", -1)) == int(contract["staff"]), "%s should disclose its exact active-hen commitment" % contract["id"], failures)
		_check(int(offer.get("total_claims", -1)) == int(contract["total"]), "%s should disclose its exact folder count" % contract["id"], failures)
		_check(int(offer.get("required_completed", -1)) == int(contract["required"]), "%s should disclose its exact delivery threshold" % contract["id"], failures)
		_check(int(offer.get("service_window_minutes", -1)) == int(contract["window"]), "%s should disclose its exact service window" % contract["id"], failures)
		_check(int(offer.get("premium_cents", -1)) == int(contract["premium"]), "%s should quote an exact integer-cent premium" % contract["id"], failures)
		_check(int(offer.get("breach_cents", -1)) == int(contract["breach"]), "%s should quote an exact integer-cent breach charge" % contract["id"], failures)
		_check(offer.get("lane_mix", {}) == contract["mix"], "%s should expose its complete deterministic lane mix" % contract["id"], failures)
		var batches := offer.get("arrival_batches", []) as Array
		_check(batches.size() == 2, "%s should contain one core and one rush batch" % contract["id"], failures)
		if batches.size() == 2:
			_check(int((batches[0] as Dictionary).get("minute_of_day", -1)) == int((contract["times"] as Array)[0]), "%s core arrival time should be exact" % contract["id"], failures)
			_check(int((batches[1] as Dictionary).get("minute_of_day", -1)) == int((contract["times"] as Array)[1]), "%s rush arrival time should be exact" % contract["id"], failures)
			_check(not bool((batches[0] as Dictionary).get("rush", true)) and bool((batches[1] as Dictionary).get("rush", false)), "%s should identify only its second batch as rush work" % contract["id"], failures)


func _test_capacity_gates_and_exact_reserve(failures: Array[String]) -> void:
	var base := _review_simulation(9611, 3)
	base.revenue_cents = 100_000
	_check(bool(base.market_contract_offer_preflight(LOW_OFFER).get("can_sign", false)), "base capacity should admit the low binder", failures)
	_check(not bool(base.market_contract_offer_preflight(MID_OFFER).get("can_sign", true)), "base capacity should reject the 24-slot binder", failures)
	_check("24 live-file" in String(base.market_contract_offer_preflight(MID_OFFER).get("reason", "")), "the medium capacity rejection should quote 24 roosts", failures)

	var level_one := _review_simulation(9612, 3, 1, 5)
	level_one.revenue_cents = 100_000
	_check(level_one.current_claim_capacity() == 24, "Records level one should expose 24 live-file roosts", failures)
	_check(bool(level_one.market_contract_offer_preflight(MID_OFFER).get("can_sign", false)), "Records level one should admit the medium binder", failures)
	_check(not bool(level_one.market_contract_offer_preflight(HIGH_OFFER).get("can_sign", true)), "Records level one should reject the 30-slot binder", failures)

	var level_two := _review_simulation(9613, 3, 2, 6)
	level_two.revenue_cents = 100_000
	_check(level_two.current_claim_capacity() == 30, "Records level two should expose 30 live-file roosts", failures)
	_check(bool(level_two.market_contract_offer_preflight(HIGH_OFFER).get("can_sign", false)), "Records level two should admit the high binder", failures)

	var exact := _review_simulation(9614, 3)
	exact.revenue_cents = exact.current_daily_operating_cost_cents() + exact.wage_arrears_cents + 500
	var preflight := exact.market_contract_offer_preflight(LOW_OFFER)
	_check(bool(preflight.get("can_sign", false)), "the exact breach-reserve fixture should pass preflight", failures)
	_check(int(preflight.get("spendable_fund_cents", -1)) == 500, "preflight should expose exactly $5 spendable before signing", failures)
	_check(int(preflight.get("spendable_after_reserve_cents", -1)) == 0, "preflight should project zero discretionary cents after reserve", failures)
	var observed := {"count": 0, "offer_id": &""}
	exact.market_contract_signed.connect(func(result: Dictionary) -> void:
		observed["count"] = int(observed["count"]) + 1
		observed["offer_id"] = StringName(result.get("offer_id", &""))
	)
	var fund_before := exact.revenue_cents
	var signed := exact.sign_market_contract(LOW_OFFER)
	_check(bool(signed.get("accepted", false)), "the exact reserve should sign the low binder", failures)
	_check(exact.revenue_cents == fund_before, "signing should reserve breach cash without debiting it", failures)
	_check(exact.current_market_contract_reserve_cents() == 500, "the active binder should protect its exact $5 breach clause", failures)
	_check(exact.spendable_fund_cents() == 0, "the reserved breach clause should leave no discretionary cash", failures)
	_check(observed == {"count": 1, "offer_id": LOW_OFFER}, "signing should emit one exact authoritative receipt", failures)
	_check(exact.market_contracts_signed_total == 1, "signing should increment its lifetime ledger exactly once", failures)


func _test_signing_rejections_are_atomic(failures: Array[String]) -> void:
	var short := _review_simulation(9621, 3)
	short.revenue_cents = short.current_daily_operating_cost_cents() + short.wage_arrears_cents + 499
	var short_preflight := short.market_contract_offer_preflight(LOW_OFFER)
	_check(not bool(short_preflight.get("can_sign", true)), "one cent below the breach reserve should reject", failures)
	_check(int(short_preflight.get("spendable_after_reserve_cents", 0)) == -1, "one-cent-short preflight should expose the exact deficit", failures)
	_expect_sign_rejected_atomic(short, LOW_OFFER, "one-cent-short binder", failures)

	var unknown := _review_simulation(9622, 3)
	unknown.revenue_cents = 100_000
	_expect_sign_rejected_atomic(unknown, &"unfiled_emu_indemnity", "unknown binder", failures)

	var duplicate := _review_simulation(9623, 3)
	duplicate.revenue_cents = 100_000
	_check(bool(duplicate.sign_market_contract(LOW_OFFER).get("accepted", false)), "duplicate fixture should sign once", failures)
	_expect_sign_rejected_atomic(duplicate, MID_OFFER, "second binder for the same shift", failures)


func _review_simulation(
	seed: int,
	target_day: int,
	records_level: int = 0,
	staff_count: int = 4
) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, staff_count)
	simulation.day = target_day
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.owned_facilities[RECORDS_ANNEX] = records_level
	return simulation


func _expect_sign_rejected_atomic(
	simulation: DepartmentSimulation,
	offer_id: StringName,
	message: String,
	failures: Array[String]
) -> void:
	var before := simulation.export_save_state().duplicate(true)
	var result := simulation.sign_market_contract(offer_id)
	_check(not bool(result.get("accepted", false)), "%s should reject" % message, failures)
	_check(not String(result.get("reason", "")).is_empty(), "%s should explain its rejection" % message, failures)
	_check(simulation.export_save_state() == before, "%s must preserve every authoritative field" % message, failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
