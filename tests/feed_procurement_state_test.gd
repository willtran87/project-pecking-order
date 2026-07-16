extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	_test_fifo_and_same_day_reconciliation(failures)
	_test_expiry_and_spoilage_value(failures)
	_test_strict_json_round_trip(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("FEED_PROCUREMENT_STATE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FEED_PROCUREMENT_STATE_TEST_PASSED fifo=stable reconciliation=idempotent spoilage=valued persistence=strict")
	quit(0)


func _test_fifo_and_same_day_reconciliation(failures: Array[String]) -> void:
	var state := FeedProcurementState.new()
	_check(state.begin_day(1), "ledger should open Day 1", failures)
	var local := state.authorize_lot(
		&"local_whole_grain", "LOCAL WHOLE GRAIN", 4, 250, 20, 1, "local filed"
	)
	_check(bool(local.get("accepted", false)), "local lot should be authorized", failures)
	var first := state.consume(2, 200, 1)
	_check(int(first.get("inventory_scoops", -1)) == 2, "first ration should use two inventory scoops", failures)
	_check(int(first.get("spot_scoops", -1)) == 0, "covered ration should buy no spot feed", failures)
	_check(int(first.get("strain_basis_points", -1)) == 9200, "pure local grain should apply 92% strain", failures)
	_check(int(first.get("morale_millipoints", -1)) == 2000, "pure local grain should apply +2 morale", failures)

	_check(state.begin_day(2), "ledger should open Day 2", failures)
	var fixed := state.authorize_lot(
		&"fixed_future_reserve", "FIXED FUTURE RESERVE", 4, 200, 20, 2, "future filed"
	)
	_check(bool(fixed.get("accepted", false)), "fixed reserve should be authorized next day", failures)
	var mixed := state.consume(3, 220, 2)
	var allocations := mixed.get("allocations", []) as Array
	_check(allocations.size() == 2, "mixed ration should disclose two FIFO allocations", failures)
	if allocations.size() == 2:
		_check(int((allocations[0] as Dictionary).get("lot_id", -1)) == int(local.get("lot_id", -2)), "older local lot should be consumed first", failures)
		_check(int((allocations[0] as Dictionary).get("scoops", -1)) == 2, "FIFO should exhaust the two older scoops", failures)
		_check(int((allocations[1] as Dictionary).get("lot_id", -1)) == int(fixed.get("lot_id", -2)), "newer fixed lot should follow", failures)
	_check(int(mixed.get("strain_basis_points", -1)) == 9467, "mixed ration should use deterministic weighted strain", failures)

	var reconciled := state.consume(2, 220, 2)
	_check(int(reconciled.get("inventory_scoops", -1)) == 2, "reconciled demand should remain fully inventoried", failures)
	_check(int(reconciled.get("strain_basis_points", -1)) == 9200, "reconciliation should restore then re-run FIFO", failures)
	_check(state.stock_scoops() == 4, "same-day reconciliation must not double-consume stock", failures)
	_check(state.spot_spend_total_cents == 0, "same-day reconciliation must not double-book spot spend", failures)


func _test_expiry_and_spoilage_value(failures: Array[String]) -> void:
	var state := FeedProcurementState.new()
	state.begin_day(1)
	state.authorize_lot(
		&"local_whole_grain", "LOCAL WHOLE GRAIN", 5, 250, 18, 1, "local filed"
	)
	state.begin_day(2)
	_check(state.stock_scoops() == 5, "two-shift local lot should remain usable on Day 2", failures)
	state.begin_day(3)
	_check(state.stock_scoops() == 0, "local lot should expire before Day 3 demand", failures)
	_check(state.spoiled_today_scoops == 5, "expiry should account for five spoiled scoops", failures)
	_check(state.spoiled_total_value_cents == 1250, "spoilage should retain prepaid acquisition value", failures)
	var spoilage := state.last_spoilage
	_check(int(spoilage.get("day", -1)) == 3, "spoilage receipt should carry the recognition day", failures)
	_check(int(spoilage.get("value_cents", -1)) == 1250, "spoilage receipt should carry exact wasted cents", failures)


func _test_strict_json_round_trip(failures: Array[String]) -> void:
	var state := FeedProcurementState.new()
	state.begin_day(6)
	state.authorize_lot(
		&"inspirational_bulk_mash", "INSPIRATIONAL BULK MASH", 12, 153, 36, 6, "bulk filed"
	)
	state.consume(5, 180, 6)
	var encoded := JSON.stringify(state.to_save_data())
	var parsed: Variant = JSON.parse_string(encoded)
	var restored := FeedProcurementState.new()
	_check(restored.restore_save_data(parsed, 6, 36, 2), "valid JSON ledger should restore", failures)
	_check(restored.to_save_data() == state.to_save_data(), "JSON round trip should reproduce the exact ledger", failures)

	var corrupt := (parsed as Dictionary).duplicate(true)
	corrupt["unknown_ledger_field"] = 1
	var rejected := FeedProcurementState.new()
	_check(not rejected.restore_save_data(corrupt, 6, 36, 2), "unknown ledger keys should fail closed", failures)

	corrupt = (parsed as Dictionary).duplicate(true)
	var lots := (corrupt.get("lots", []) as Array).duplicate(true)
	if not lots.is_empty():
		var lot := (lots[0] as Dictionary).duplicate(true)
		lot["strain_basis_points"] = 10000
		lots[0] = lot
	corrupt["lots"] = lots
	_check(not rejected.restore_save_data(corrupt, 6, 36, 2), "tampered lot effects should fail closed", failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
