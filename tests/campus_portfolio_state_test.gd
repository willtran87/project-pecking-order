extends SceneTree


const Portfolio := preload("res://core/simulation/campus_portfolio_state.gd")


func _init() -> void:
	var failures: Array[String] = []
	_test_exact_economics_and_gates(failures)
	_test_fifo_progress_staffing_and_benefits(failures)
	_test_contractor_roost_and_chilling_exchange(failures)
	_test_strict_round_trip_and_atomic_rejection(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPUS_PORTFOLIO_STATE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_PORTFOLIO_STATE_TEST_PASSED schema=1 parcels=2 modules=4 cents=exact fifo=deterministic contractor=1-plus-1 utilities=reserved staffing=required persistence=strict")
	quit(0)


func _test_exact_economics_and_gates(failures: Array[String]) -> void:
	var state := Portfolio.new(1)
	var neutral := state.to_save_data()
	_check(neutral.keys().size() == Portfolio.SAVE_KEYS.size(), "neutral save should expose only strict save keys", failures)
	_check(int(neutral.get("version", -1)) == 1, "portfolio save version should be one inside simulation schema v23", failures)
	_check((neutral.get("parcels", {}) as Dictionary).size() == 2, "neutral state should contain exactly two parcel deeds", failures)
	_check((neutral.get("modules", {}) as Dictionary).size() == 4, "neutral state should contain exactly four module records", failures)
	_check(state.daily_cost_cents() == 0 and state.capital_spend_total_cents == 0, "neutral portfolio should invent no cost or spending", failures)

	var early := state.quote_deed(Portfolio.ORCHARD_ROW, _context(1))
	_check(not bool(early.get("can_authorize", true)) and "Day 6" in String(early.get("reason", "")), "Orchard Row should disclose its Day-6 gate", failures)
	_check(int(early.get("cost_cents", -1)) == 12_500 and int(early.get("added_daily_cost_cents", -1)) == 450, "Orchard deed should quote exact $125 and $4.50/day", failures)
	_check(int(state.quote_deed(Portfolio.CREEKSIDE_YARD, _context(1)).get("cost_cents", -1)) == 16_500, "Creekside deed should quote exact $165", failures)
	for module_id: StringName in Portfolio.MODULE_ORDER:
		var definition := Portfolio.MODULE_DEFINITIONS[module_id] as Dictionary
		_check(int(definition.get("capital_cost_cents", 0)) > 0, "%s should have exact positive capital" % String(module_id), failures)
		_check(int(definition.get("daily_cost_cents", 0)) > 0, "%s should have exact positive upkeep" % String(module_id), failures)
		_check(int(definition.get("duration_shifts", 0)) in [2, 3], "%s should have a real two-or-three-shift duration" % String(module_id), failures)


func _test_fifo_progress_staffing_and_benefits(failures: Array[String]) -> void:
	var state := Portfolio.new(6)
	var context := _context(6, 6, 3, [0, 1, 2, 3, 4, 5])
	var deed := state.authorize_deed(Portfolio.ORCHARD_ROW, 6, context)
	_check(bool(deed.get("accepted", false)), "Day-6 Orchard deed should authorize", failures)
	_check(state.daily_cost_cents() == 450 and state.capital_spend_total_cents == 12_500, "deed should add exact tax and gross spend", failures)

	var rail := state.authorize_project(Portfolio.COLLECTION_RAIL_HUB, Portfolio.ORCHARD_WEST, 6, context)
	var mill := state.authorize_project(Portfolio.GRAIN_RECOVERY_MILL, Portfolio.ORCHARD_EAST, 6, context)
	_check(bool(rail.get("accepted", false)) and StringName(rail.get("project_status", &"")) == &"active", "first one-slot job should start immediately", failures)
	_check(bool(mill.get("accepted", false)) and StringName(mill.get("project_status", &"")) == &"queued", "second one-slot job should queue behind base capacity one", failures)
	_check(int(state.snapshot(context).get("capital_spend_total_cents", -1)) == 42_500, "deed plus both modules should reserve exact $425 capital", failures)
	_check(int((state.snapshot(context).get("network", {}) as Dictionary).get("power_reserved_units", -1)) == 3, "active and queued jobs should reserve all three power units at authorization", failures)
	var duplicate_before := state.to_save_data().duplicate(true)
	var duplicate := state.authorize_project(Portfolio.COLLECTION_RAIL_HUB, Portfolio.ORCHARD_WEST, 6, context)
	_check(not bool(duplicate.get("accepted", true)), "duplicate module authorization should reject", failures)
	_check(state.to_save_data() == duplicate_before, "duplicate rejection should be atomic", failures)

	var day7 := state.begin_day(7, context)
	_check(bool(day7.get("accepted", false)) and (day7.get("completed", []) as Array).is_empty(), "first boundary should leave two-shift Rail in progress", failures)
	var day8 := state.begin_day(8, context)
	_check((day8.get("completed", []) as Array).size() == 1 and (day8.get("started", []) as Array).size() == 1, "Rail completion should promote exactly one FIFO Mill job", failures)
	_check(state.claim_capacity_bonus(context) == 0 and state.good_egg_bonus_cents(context) == 0, "completed but unstaffed Rail should provide no benefit", failures)
	var assignment := state.assign_worker(Portfolio.COLLECTION_RAIL_HUB, 0, [0, 1, 2, 3, 4, 5], context)
	_check(bool(assignment.get("accepted", false)), "named employed worker should staff completed Rail", failures)
	_check(state.claim_capacity_bonus(context) == 4 and state.good_egg_bonus_cents(context) == 25, "staffed powered Rail should activate exact capacity and value bonuses", failures)
	var empty_roster := context.duplicate(true)
	empty_roster["valid_worker_ids"] = []
	_check(state.claim_capacity_bonus(empty_roster) == 0, "an explicit empty worker roster should suspend staffed-module benefits", failures)
	_check(state.daily_cost_cents() == 1_150, "Orchard deed, installed Rail, and duty premium should cost exact $11.50/day", failures)

	state.begin_day(9, context)
	state.begin_day(10, context)
	var day11 := state.begin_day(11, context)
	_check((day11.get("completed", []) as Array).size() == 1, "three-shift Mill should complete on its third active boundary", failures)
	_check(bool(state.assign_worker(Portfolio.GRAIN_RECOVERY_MILL, 1, [0, 1, 2, 3, 4, 5], context).get("accepted", false)), "second named worker should staff Mill", failures)
	_check(state.feed_capacity_bonus_scoops(context) == 18 and state.feed_demand_reduction_scoops(context) == 1, "staffed powered Mill should activate exact feed benefits", failures)
	var duplicate_worker := state.assign_worker(Portfolio.GRAIN_RECOVERY_MILL, 0, [0, 1, 2, 3, 4, 5], context)
	_check(not bool(duplicate_worker.get("accepted", true)), "one named worker may not staff two modules", failures)


func _test_contractor_roost_and_chilling_exchange(failures: Array[String]) -> void:
	var state := Portfolio.new(9)
	var context := _context(9, 6, 3, [0, 1, 2, 3, 4, 5])
	_check(bool(state.authorize_deed(Portfolio.ORCHARD_ROW, 9, context).get("accepted", false)), "late fixture should file Orchard deed", failures)
	_check(bool(state.authorize_deed(Portfolio.CREEKSIDE_YARD, 9, context).get("accepted", false)), "Creekside should require and follow Orchard deed", failures)
	var blocked_chiller := state.quote_project(Portfolio.CREEKSIDE_CHILLING_EXCHANGE, Portfolio.CREEKSIDE_WEST, context)
	_check(not bool(blocked_chiller.get("can_authorize", true)) and "2 contractor slots" in String(blocked_chiller.get("reason", "")), "two-slot Chiller should disclose Contractor Roost gate", failures)

	var roost := state.authorize_project(Portfolio.CONTRACTOR_ROOST, Portfolio.CREEKSIDE_EAST, 9, context)
	_check(bool(roost.get("accepted", false)), "one-slot Contractor Roost should authorize", failures)
	state.begin_day(10, context)
	state.begin_day(11, context)
	_check(state.contractor_capacity_slots(context) == 1, "completed but unstaffed Roost should not expand contractor capacity", failures)
	_check(bool(state.assign_worker(Portfolio.CONTRACTOR_ROOST, 2, [0, 1, 2, 3, 4, 5], context).get("accepted", false)), "named coordinator should staff Roost", failures)
	_check(state.contractor_capacity_slots(context) == 2, "staffed powered Roost should add exactly one contractor slot", failures)

	context["day"] = 11
	var chiller := state.authorize_project(Portfolio.CREEKSIDE_CHILLING_EXCHANGE, Portfolio.CREEKSIDE_WEST, 11, context)
	_check(bool(chiller.get("accepted", false)) and StringName(chiller.get("project_status", &"")) == &"active", "two-slot Chiller should use both expanded contractor slots", failures)
	var in_flight_json: Variant = JSON.parse_string(JSON.stringify(state.to_save_data()))
	var context_free_restore := Portfolio.new(1)
	_check(
		context_free_restore.restore_save_data(in_flight_json, 11, [0, 1, 2, 3, 4, 5]),
		"valid two-slot construction should restore before live network context is available",
		failures,
	)
	var roost_hold := state.unassign_worker(Portfolio.CONTRACTOR_ROOST, [0, 1, 2, 3, 4, 5], context)
	_check(not bool(roost_hold.get("accepted", true)), "Roost cannot be unstaffed while a two-slot contract exists", failures)
	state.begin_day(12, context)
	state.begin_day(13, context)
	state.begin_day(14, context)
	context["day"] = 14
	_check(state.farmgate_capacity_bonus_eggs(context) == 0, "unassigned completed Chiller should provide no storage", failures)
	_check(bool(state.assign_worker(Portfolio.CREEKSIDE_CHILLING_EXCHANGE, 3, [0, 1, 2, 3, 4, 5], context).get("accepted", false)), "named cold-chain worker should staff Chiller", failures)
	_check(state.farmgate_capacity_bonus_eggs(context) == 12, "staffed powered Chiller should add exact 12-egg storage", failures)
	_check(state.farmgate_overflow_basis_points(context) == 9_500, "staffed powered Chiller should raise overflow route to exact 95%", failures)
	_check(state.farmgate_storage_bonus_eggs(context) == 12 and state.farmgate_overflow_value_basis_points(context) == 9_500, "integration aliases should expose the same Farmgate benefits", failures)
	var power_lost := context.duplicate(true)
	power_lost["power_capacity_units"] = 1
	_check(state.farmgate_capacity_bonus_eggs(power_lost) == 0 and state.contractor_capacity_slots(power_lost) == 1, "network deficit should hold every operational benefit", failures)


func _test_strict_round_trip_and_atomic_rejection(failures: Array[String]) -> void:
	var source := Portfolio.new(9)
	var context := _context(9, 6, 3, [0, 1, 2, 3, 4, 5])
	source.authorize_deed(Portfolio.ORCHARD_ROW, 9, context)
	source.authorize_deed(Portfolio.CREEKSIDE_YARD, 9, context)
	source.authorize_project(Portfolio.CONTRACTOR_ROOST, Portfolio.CREEKSIDE_EAST, 9, context)
	source.begin_day(10, context)
	source.begin_day(11, context)
	source.assign_worker(Portfolio.CONTRACTOR_ROOST, 2, [0, 1, 2, 3, 4, 5], context)
	var encoded: Variant = JSON.parse_string(JSON.stringify(source.to_save_data()))
	var restored := Portfolio.new(1)
	_check(encoded is Dictionary and restored.restore_save_data(encoded, 11, [0, 1, 2, 3, 4, 5], context), "canonical JSON portfolio should restore", failures)
	_check(restored.to_save_data() == source.to_save_data(), "strict portfolio should round-trip exactly", failures)
	_check(restored.contractor_capacity_slots(context) == 2, "restored named Roost assignment should reproduce contractor capacity", failures)

	var corrupt := (encoded as Dictionary).duplicate(true)
	var modules := (corrupt.get("modules", {}) as Dictionary).duplicate(true)
	var roost := (modules.get("contractor_roost", {}) as Dictionary).duplicate(true)
	roost["pad_id"] = "orchard_west"
	modules["contractor_roost"] = roost
	corrupt["modules"] = modules
	var target := Portfolio.new(4)
	var before := target.to_save_data().duplicate(true)
	_check(not target.restore_save_data(corrupt, 11, [0, 1, 2, 3, 4, 5], context), "wrong-parcel installed pad should reject", failures)
	_check(target.to_save_data() == before, "failed restore should preserve target atomically", failures)

	corrupt = (encoded as Dictionary).duplicate(true)
	var history := (corrupt.get("history", []) as Array).duplicate(true)
	var receipt := (history[0] as Dictionary).duplicate(true)
	receipt["cost_cents"] = int(receipt["cost_cents"]) + 1
	receipt["fund_delta_cents"] = -int(receipt["cost_cents"])
	history[0] = receipt
	corrupt["history"] = history
	corrupt["last_receipt"] = (history[-1] as Dictionary).duplicate(true)
	_check(not target.restore_save_data(corrupt, 11, [0, 1, 2, 3, 4, 5], context), "one-cent receipt tamper should reject", failures)
	_check(target.to_save_data() == before, "receipt rejection should remain atomic", failures)


func _context(
	day: int,
	power_units: int = 6,
	cold_units: int = 3,
	worker_ids: Array = [0, 1, 2, 3, 4, 5],
) -> Dictionary:
	return {
		"day": day,
		"planning_open": true,
		"can_fund": true,
		"power_capacity_units": power_units,
		"cold_capacity_units": cold_units,
		"valid_worker_ids": worker_ids.duplicate(),
		"worker_names": {
			0: "Mabel",
			1: "Dot",
			2: "Ginger",
			3: "Pepper",
			4: "Poppy",
			5: "Nugget",
		},
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
