extends SceneTree


const DispatchState := preload("res://core/simulation/farmgate_dispatch_state.gd")


func _init() -> void:
	var failures: Array[String] = []
	_test_default_pickup_and_overflow(failures)
	_test_county_fifo_hold_expiry_and_exact_once(failures)
	_test_regional_showcase_selection(failures)
	_test_strict_json_restore(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("FARMGATE_DISPATCH_STATE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARMGATE_DISPATCH_STATE_TEST_PASSED lots=immutable overflow=90pct default=parity county=fifo showcase=golden-first hold=carry expiry=disposal exact-once=yes json=strict")
	quit(0)


func _test_default_pickup_and_overflow(failures: Array[String]) -> void:
	var state := DispatchState.new()
	_check(state.begin_day(6), "Day 6 should initialize", failures)
	var stored := state.store_lot(101, 6, 0, "Mabel", &"sound", 1_000, 1, 2, 12)
	_check(bool(stored.get("stored", false)), "the first egg should enter tier-one storage", failures)
	var receipt := state.settle(6, 1, 8, 5)
	_check(bool(receipt.get("accepted", false)), "unconfigured settlement should default to farmer pickup", failures)
	_check(StringName(receipt.get("mandate_id", &"")) == DispatchState.FARMER_PICKUP, "default route should be farmer pickup", failures)
	_check(int(receipt.get("gross_cents", -1)) == 1_000, "default pickup should preserve exact finished value", failures)
	_check(int(receipt.get("commission_cents", -1)) == 0 and int(receipt.get("listing_fee_cents", -1)) == 0, "default pickup should charge no fee", failures)
	_check(int(receipt.get("settlement_cash_delta_cents", -1)) == 1_000, "default pickup should preserve baseline closing cash", failures)
	_check(int(receipt.get("cash_delta_cents", -1)) == 1_000, "daily cash should equal the default settlement without overflow", failures)

	var overflow_state := DispatchState.new()
	overflow_state.begin_day(6)
	for index in 12:
		overflow_state.store_lot(110 + index, 6, index % 6, "Fill Hen %d" % index, &"sound", 100, 1, 2, 12)
	var overflow := overflow_state.store_lot(122, 6, 1, "Pip", &"golden", 2_000, 1, 2, 12)
	_check(bool(overflow.get("overflow", false)), "the thirteenth tier-one egg should overflow", failures)
	_check(int(overflow.get("gross_cents", -1)) == 1_800, "overflow should auto-sell at exactly 90%", failures)
	_check(overflow_state.stock_count() == 12 and overflow_state.stock_value_cents() == 1_200, "overflow must not mutate the twelve stored lots", failures)
	_check(overflow_state.payout_total_cents == 1_800, "lifetime payout should include overflow cash immediately", failures)


func _test_county_fifo_hold_expiry_and_exact_once(failures: Array[String]) -> void:
	var state := DispatchState.new()
	state.begin_day(7)
	for index in 10:
		state.store_lot(200 + index, 7, index % 6, "Hen %d" % index, &"sound", 100 + index, 1, 2, 12)
	var auth := state.authorize_mandate(
		DispatchState.COUNTY_AUCTION, 7, 1, 8, &"spring_hatch_surge", 10_500,
		5, 100_000, 5_000, "County route frozen.",
	)
	_check(bool(auth.get("accepted", false)), "county authorization should accept valid frozen terms", failures)
	var receipt := state.settle(7, 1, 8, 5)
	_check(int(receipt.get("sold_eggs", -1)) == 8, "tier one county route should dispatch eight eggs", failures)
	var sold := receipt.get("sold_lots", []) as Array
	_check(int((sold[0] as Dictionary).get("claim_id", -1)) == 200 and int((sold[-1] as Dictionary).get("claim_id", -1)) == 207, "county route should be oldest-first with stable lot order", failures)
	_check(int(receipt.get("base_value_cents", -1)) == 828, "county base should equal the eight oldest exact values", failures)
	_check(int(receipt.get("gross_cents", -1)) == 869, "spring county price should round 105% half-up", failures)
	_check(int(receipt.get("commission_cents", -1)) == 43, "county commission should round 5% half-up", failures)
	_check(int(receipt.get("carrying_cost_cents", -1)) == 40, "two retained eggs should cost twenty cents each", failures)
	var duplicate := state.settle(7, 1, 8, 5)
	_check(not bool(duplicate.get("accepted", true)), "a day may settle only once", failures)
	_check(state.history.size() == 1, "duplicate settlement must not append history", failures)

	state.begin_day(8)
	var hold := state.authorize_mandate(
		DispatchState.HOLD_BASKET, 8, 1, 8, &"spring_hatch_surge", 10_500,
		5, 10_000, 5_000, "Basket held.",
	)
	_check(bool(hold.get("accepted", false)), "funded hold should authorize", failures)
	var held := state.settle(8, 1, 8, 5)
	_check(int(held.get("sold_eggs", -1)) == 0 and int(held.get("carrying_cost_cents", -1)) == 40, "hold should sell none and carry every retained egg", failures)
	state.begin_day(9)
	var expired := state.settle(9, 1, 8, 5)
	_check(int(expired.get("expired_eggs", -1)) == 2, "eggs held beyond their two-shift shelf life should expire", failures)
	_check(int(expired.get("disposal_cost_cents", -1)) == 50, "expired eggs should cost twenty-five cents each", failures)
	_check(int(expired.get("gross_cents", -1)) == 0 and state.stock_count() == 0, "expired eggs should sell for zero and leave storage", failures)
	var parsed: Variant = JSON.parse_string(JSON.stringify(state.to_save_data()))
	var restored := DispatchState.new()
	_check(parsed is Dictionary and restored.restore_save_data(parsed, 9, 12, 1), "settled history with an older last authorization should restore", failures)
	_check(restored.snapshot() == state.snapshot(), "settled daily and lifetime ledgers should round-trip exactly", failures)


func _test_regional_showcase_selection(failures: Array[String]) -> void:
	var state := DispatchState.new()
	state.begin_day(14)
	var qualities: Array[StringName] = [&"sound", &"golden", &"sound", &"golden", &"sound", &"golden", &"sound", &"sound"]
	var values := [900, 500, 1_400, 700, 1_300, 600, 1_200, 1_100]
	for index in values.size():
		state.store_lot(300 + index, 14, index % 6, "Show Hen %d" % index, qualities[index], values[index], 3, 4, 42)
	var auth := state.authorize_mandate(
		DispatchState.REGIONAL_SHOWCASE, 14, 3, 24, &"autumn_retention_audit", 12_000,
		50, 100_000, 5_000, "Regional route frozen.",
	)
	_check(int(auth.get("price_basis_points", -1)) == 18_500, "standing bonus should cap at +25% over the 160% showcase base", failures)
	var receipt := state.settle(14, 3, 24, 50)
	var sold := receipt.get("sold_lots", []) as Array
	_check(sold.size() == 6, "regional showcase should dispatch exactly six when stock permits", failures)
	_check(StringName((sold[0] as Dictionary).get("quality", &"")) == &"golden" and StringName((sold[2] as Dictionary).get("quality", &"")) == &"golden", "all golden eggs should be selected before sound eggs", failures)
	_check(int((sold[0] as Dictionary).get("value_cents", -1)) == 700 and int((sold[1] as Dictionary).get("value_cents", -1)) == 600, "golden subset should be highest-value first", failures)
	_check(int(receipt.get("listing_fee_cents", -1)) == 300, "nonempty showcase should charge one $3 listing fee", failures)
	_check(int(receipt.get("commission_cents", -1)) == 0, "showcase should not also charge county commission", failures)


func _test_strict_json_restore(failures: Array[String]) -> void:
	var source := DispatchState.new()
	source.begin_day(10)
	source.store_lot(401, 10, 0, "Mabel", &"golden", 1_250, 2, 3, 24)
	source.authorize_mandate(DispatchState.COUNTY_AUCTION, 10, 2, 16, &"summer_predator_migration", 9_000, 12, 50_000, 5_000)
	var parsed: Variant = JSON.parse_string(JSON.stringify(source.to_save_data()))
	var restored := DispatchState.new()
	_check(parsed is Dictionary and restored.restore_save_data(parsed, 10, 24, 2), "canonical JSON should restore", failures)
	_check(restored.snapshot() == source.snapshot(), "restored lot and frozen mandate projections should match exactly", failures)

	var corrupt := (parsed as Dictionary).duplicate(true)
	corrupt["invented_route_margin"] = 1
	var target := DispatchState.new()
	target.begin_day(10)
	var before := target.to_save_data()
	_check(not target.restore_save_data(corrupt, 10, 24, 2), "unknown state fields should reject", failures)
	_check(target.to_save_data() == before, "rejected restore should remain atomic", failures)

	corrupt = (parsed as Dictionary).duplicate(true)
	var lots := (corrupt.get("lots", []) as Array).duplicate(true)
	var lot := (lots[0] as Dictionary).duplicate(true)
	lot["value_cents"] = 1_251
	lots[0] = lot
	corrupt["lots"] = lots
	# An unsold lot value may legitimately be any positive exact value; corrupt the
	# deterministic expiry relation instead to prove strict immutable-lot checks.
	lot["expires_day"] = int(lot["expires_day"]) + 1
	lots[0] = lot
	corrupt["lots"] = lots
	_check(not DispatchState.new().restore_save_data(corrupt, 10, 24, 2), "repriced expiry metadata should reject", failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
