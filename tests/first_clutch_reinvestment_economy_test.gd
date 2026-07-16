extends SceneTree


const KEYCAPS: StringName = &"peckwork_tools"
const SHELL_LAMP: StringName = &"shell_lamp"
const BANK: StringName = &"bank_fund"


func _init() -> void:
	var failures: Array[String] = []
	_test_offer_and_exact_purchase(failures)
	_test_first_two_non_maxed_selection(failures)
	_test_bank_forfeits_match(failures)
	_test_one_cent_reserve_guard(failures)
	_test_persistence_migration_and_validation(failures)
	_test_workday_ledgers(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("FIRST_CLUTCH_REINVESTMENT_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FIRST_CLUTCH_REINVESTMENT_ECONOMY_TEST_PASSED offer=two match=purchase-only transaction=exact reserve=one-cent bank=idempotent persistence=v10-v9 report=daily")
	quit(0)


func _test_offer_and_exact_purchase(failures: Array[String]) -> void:
	var simulation := _first_egg_fixture(7101, 1480)
	var fund_before := simulation.revenue_cents
	var upgrade_events: Array[Dictionary] = []
	var resolution_events: Array[Dictionary] = []
	simulation.upgrade_purchased.connect(func(id: StringName, level: int, cost: int) -> void:
		upgrade_events.append({"id": id, "level": level, "cost": cost})
	)
	simulation.first_clutch_reinvestment_resolved.connect(func(result: Dictionary) -> void:
		resolution_events.append(result.duplicate(true))
	)
	var offer := simulation.begin_first_clutch_reinvestment(0, 3, &"cracked", 180)
	_check(bool(offer.get("accepted", false)) and bool(offer.get("created", false)), "exact collected egg should stage the offer", failures)
	_check(simulation.revenue_cents == fund_before, "staging must not mint procurement cash", failures)
	_check(StringName(offer.get("status", &"")) == &"offered" and not bool(offer.get("resolved", true)), "new offer should remain unresolved", failures)
	_check(int(offer.get("trigger_worker_id", -1)) == 0 and String(offer.get("trigger_worker_name", "")) == "Mabel", "offer should retain Mabel's exact identity", failures)
	_check(int(offer.get("trigger_claim_id", -1)) == 3 and StringName(offer.get("trigger_quality", &"")) == &"cracked" and int(offer.get("created_value_cents", -1)) == 180, "offer should retain exact claim, grade, and created value", failures)
	_check(int(offer.get("protected_reserve_cents", -1)) == simulation.current_daily_operating_cost_cents(), "offer should disclose the protected operating reserve", failures)
	_check(int(offer.get("spendable_at_collection_cents", -1)) == 1480, "offer should disclose exact collection-time spendable cash", failures)
	_check(int(offer.get("procurement_match_available_cents", -1)) == 1720, "match should be only the shortfall to the highest offered list cost", failures)
	var options := offer.get("offered_options", []) as Array
	_check(options.size() == 2, "offer should expose at most the first two non-maxed upgrades", failures)
	if options.size() == 2:
		var keycaps := options[0] as Dictionary
		var lamp := options[1] as Dictionary
		_check(StringName(keycaps.get("id", &"")) == KEYCAPS and StringName(lamp.get("id", &"")) == SHELL_LAMP, "offer order should be keycaps then shell lamp", failures)
		_check(int(keycaps.get("list_cost_cents", -1)) == 2500 and int(keycaps.get("procurement_match_cents", -1)) == 1720 and int(keycaps.get("net_cost_cents", -1)) == 780, "keycap option should expose exact list/match/net cents", failures)
		_check(int(keycaps.get("projected_spendable_fund_cents", -1)) == 700 and bool(keycaps.get("can_purchase", false)), "keycap preflight should retain $7 spendable", failures)
		_check(int(lamp.get("list_cost_cents", -1)) == 3200 and int(lamp.get("net_cost_cents", -1)) == 1480 and int(lamp.get("projected_spendable_fund_cents", -1)) == 0 and bool(lamp.get("can_purchase", false)), "lamp preflight should consume exactly the available discretionary fund", failures)
	var state_before_replay := JSON.stringify(simulation.export_save_state())
	var replay := simulation.begin_first_clutch_reinvestment(0, 3, &"cracked", 180)
	_check(bool(replay.get("accepted", false)) and bool(replay.get("idempotent", false)) and not bool(replay.get("created", true)), "exact begin replay should return the durable offer idempotently", failures)
	_check(JSON.stringify(simulation.export_save_state()) == state_before_replay, "exact begin replay must not mutate any ledger", failures)
	var mismatch := simulation.begin_first_clutch_reinvestment(0, 4, &"cracked", 180)
	_check(not bool(mismatch.get("accepted", true)) and simulation.revenue_cents == fund_before, "different collection replay should fail atomically", failures)
	_check(not simulation.purchase_upgrade(KEYCAPS), "ordinary requisition route should not bypass the open matched offer", failures)

	var receipt := simulation.resolve_first_clutch_reinvestment(KEYCAPS)
	_check(bool(receipt.get("accepted", false)) and StringName(receipt.get("status", &"")) == &"purchased" and bool(receipt.get("resolved", false)), "offered keycaps should resolve as purchased", failures)
	_check(simulation.upgrade_level(KEYCAPS) == 1, "matched purchase should reuse the global keycap level", failures)
	_check(simulation.revenue_cents == fund_before - 780 and simulation.spendable_fund_cents() == 700, "matched purchase should debit only net cost while preserving reserves", failures)
	_check(int(receipt.get("selected_list_cost_cents", -1)) == 2500 and int(receipt.get("procurement_match_used_cents", -1)) == 1720 and int(receipt.get("net_cost_cents", -1)) == 780, "purchase receipt should reconcile list, match, and net cents", failures)
	_check(simulation.requisition_spend_today_cents == 780 and simulation.requisition_spend_total_cents == 780, "purchase should enter daily and lifetime spend ledgers", failures)
	_check(simulation.orientation_procurement_match_today_cents == 1720 and simulation.orientation_procurement_match_total_cents == 1720, "used match should enter daily and lifetime subsidy ledgers", failures)
	_check(upgrade_events.size() == 1 and int(upgrade_events[0].get("cost", -1)) == 780, "existing upgrade signal should emit actual Feed Fund debit once", failures)
	_check(resolution_events.size() == 1 and StringName(resolution_events[0].get("choice_id", &"")) == KEYCAPS, "dedicated resolution signal should emit the authoritative receipt once", failures)
	var fund_after := simulation.revenue_cents
	var replay_resolve := simulation.resolve_first_clutch_reinvestment(SHELL_LAMP)
	_check(not bool(replay_resolve.get("accepted", true)) and bool(replay_resolve.get("idempotent", false)), "second resolution should be rejected as an idempotent replay", failures)
	_check(simulation.revenue_cents == fund_after and simulation.upgrade_level(SHELL_LAMP) == 0 and upgrade_events.size() == 1 and resolution_events.size() == 1, "resolution replay must not spend, level, or signal twice", failures)


func _test_first_two_non_maxed_selection(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(7113, 4)
	simulation.revenue_cents = 1_000_000
	for _level in DepartmentSimulation.MAX_UPGRADE_LEVEL:
		_check(simulation.purchase_upgrade(KEYCAPS), "selection fixture should max the first upgrade path", failures)
	simulation.workers[0].eggs_laid = 1
	simulation.eggs_total = 1
	simulation.revenue_cents = simulation.current_daily_operating_cost_cents() + 1000
	var offer := simulation.begin_first_clutch_reinvestment(0, 7, &"sound", 875)
	var options := offer.get("offered_options", []) as Array
	_check(options.size() == 2, "maxed paths should be skipped without reducing the two-option cap", failures)
	if options.size() == 2:
		_check(StringName((options[0] as Dictionary).get("id", &"")) == SHELL_LAMP and StringName((options[1] as Dictionary).get("id", &"")) == &"nest_cushion", "offer should choose the first two remaining non-maxed paths in catalog order", failures)
	_check(int(offer.get("procurement_match_available_cents", -1)) == 1800, "selection fixture should cap, not exceed, its required $22 match", failures)


func _test_bank_forfeits_match(failures: Array[String]) -> void:
	var simulation := _first_egg_fixture(7102, 2175)
	var offer := simulation.begin_first_clutch_reinvestment(0, 9, &"sound", 875)
	_check(int(offer.get("procurement_match_available_cents", -1)) == 1025, "stronger collection should require a smaller exact match", failures)
	var fund_before := simulation.revenue_cents
	var banked := simulation.resolve_first_clutch_reinvestment(BANK)
	_check(bool(banked.get("accepted", false)) and StringName(banked.get("status", &"")) == &"banked" and bool(banked.get("banked", false)), "Bank the Fund should close the offer", failures)
	_check(simulation.revenue_cents == fund_before and simulation.requisition_spend_total_cents == 0 and simulation.orientation_procurement_match_total_cents == 0, "banking should neither spend nor convert the match into cash", failures)
	_check(simulation.upgrade_level(KEYCAPS) == 0 and simulation.upgrade_level(SHELL_LAMP) == 0, "banking should not invent an upgrade", failures)
	var replay := simulation.resolve_first_clutch_reinvestment(BANK)
	_check(not bool(replay.get("accepted", true)) and bool(replay.get("idempotent", false)) and simulation.revenue_cents == fund_before, "bank replay should remain economically idempotent", failures)


func _test_one_cent_reserve_guard(failures: Array[String]) -> void:
	var simulation := _first_egg_fixture(7103, 1480)
	simulation.begin_first_clutch_reinvestment(0, 12, &"cracked", 180)
	simulation.revenue_cents -= 1
	var preflight := simulation.first_clutch_reinvestment_preflight(SHELL_LAMP)
	_check(int(preflight.get("projected_spendable_fund_cents", 0)) == -1 and not bool(preflight.get("can_purchase", true)), "one-cent-short preflight should expose the raw reserve deficit", failures)
	var fund_before := simulation.revenue_cents
	var rejected := simulation.resolve_first_clutch_reinvestment(SHELL_LAMP)
	_check(not bool(rejected.get("accepted", true)) and simulation.revenue_cents == fund_before and simulation.upgrade_level(SHELL_LAMP) == 0, "one-cent-short resolution should reject atomically", failures)
	simulation.revenue_cents += 1
	var accepted := simulation.resolve_first_clutch_reinvestment(SHELL_LAMP)
	_check(bool(accepted.get("accepted", false)) and simulation.spendable_fund_cents() == 0 and simulation.upgrade_level(SHELL_LAMP) == 1, "restoring the exact cent should permit the reserve-safe purchase", failures)


func _test_persistence_migration_and_validation(failures: Array[String]) -> void:
	var offered := _first_egg_fixture(7104, 1480)
	offered.begin_first_clutch_reinvestment(0, 18, &"golden", 3335)
	var offered_state := offered.export_save_state()
	_check(int(offered_state.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "First Clutch state should export the current schema", failures)
	var parsed: Variant = JSON.parse_string(JSON.stringify(offered_state))
	var restored := DepartmentSimulation.new(7105, 4)
	_check(parsed is Dictionary and restored.restore_save_state(parsed as Dictionary), "offered receipt should survive a primitive JSON round trip", failures)
	var restored_status := restored.first_clutch_reinvestment_status()
	_check(StringName(restored_status.get("status", &"")) == &"offered" and int(restored_status.get("trigger_claim_id", -1)) == 18 and (restored_status.get("offered_options", []) as Array).size() == 2, "round trip should preserve exact offered identity and terms", failures)

	var purchased := _first_egg_fixture(7106, 1480)
	purchased.begin_first_clutch_reinvestment(0, 22, &"sound", 875)
	purchased.resolve_first_clutch_reinvestment(KEYCAPS)
	var purchased_state := purchased.export_save_state()
	var purchased_restored := DepartmentSimulation.new(7107, 4)
	_check(purchased_restored.restore_save_state(purchased_state), "purchased reinvestment receipt should restore", failures)
	_check(purchased_restored.upgrade_level(KEYCAPS) == 1 and purchased_restored.requisition_spend_total_cents == 780 and purchased_restored.orientation_procurement_match_total_cents == 1720, "purchased restore should reconcile level, spend, and match ledgers", failures)

	var legacy_source := DepartmentSimulation.new(7108, 4)
	legacy_source.revenue_cents = legacy_source.current_daily_operating_cost_cents() + legacy_source.upgrade_cost_cents(KEYCAPS)
	_check(legacy_source.purchase_upgrade(KEYCAPS), "legacy migration fixture should contain one standard requisition", failures)
	var legacy_v9 := legacy_source.export_save_state()
	legacy_v9["state_version"] = 9
	for field in [
		"first_clutch_reinvestment",
		"requisition_spend_today_cents", "requisition_spend_total_cents",
		"orientation_procurement_match_today_cents", "orientation_procurement_match_total_cents",
		"intake_rejections_today", "intake_rejections_total",
		"intake_missed_value_today_cents", "intake_missed_value_total_cents",
	]:
		legacy_v9.erase(field)
	var legacy_facilities := (legacy_v9.get("owned_facilities", {}) as Dictionary).duplicate(true)
	legacy_facilities.erase("records_annex")
	legacy_facilities.erase("farm_mutual_service_coop")
	legacy_facilities.erase("farm_mutual_negotiation_room")
	legacy_facilities.erase(String(DepartmentSimulation.WELLNESS_NEST_ID))
	legacy_facilities.erase(String(DepartmentSimulation.TRAINING_ROOST_ID))
	legacy_facilities.erase(String(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID))
	legacy_facilities.erase(String(DepartmentSimulation.IT_COOP_ID))
	legacy_facilities.erase(String(DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID))
	legacy_facilities.erase(String(DepartmentSimulation.FEED_PROCUREMENT_COOP_ID))
	legacy_facilities.erase(String(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID))
	legacy_facilities.erase(String(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID))
	legacy_v9["owned_facilities"] = legacy_facilities
	legacy_v9.erase("feed_procurement_state")
	legacy_v9.erase("harvest_credit_state")
	legacy_v9.erase("farmgate_dispatch_state")
	legacy_v9.erase("pinned_capital_plan_id")
	legacy_v9.erase("last_facility_purchase_receipt")
	legacy_v9.erase("facility_commissioning_history")
	var migrated := DepartmentSimulation.new(7109, 4)
	_check(migrated.restore_save_state(legacy_v9), "schema v9 should migrate with no invented First Clutch offer", failures)
	_check(migrated.first_clutch_reinvestment.is_empty() and migrated.requisition_spend_today_cents == 0 and migrated.requisition_spend_total_cents == 2500 and migrated.orientation_procurement_match_total_cents == 0, "v9 migration should reconstruct known list spend but keep offer and match neutral", failures)
	_check(int(migrated.export_save_state().get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "migrated v9 checkpoint should re-export the current schema", failures)

	var bad_match := purchased_state.duplicate(true)
	var bad_match_record := (bad_match["first_clutch_reinvestment"] as Dictionary).duplicate(true)
	bad_match_record["procurement_match_used_cents"] = 1719
	bad_match["first_clutch_reinvestment"] = bad_match_record
	_check(not DepartmentSimulation.new(7110, 4).restore_save_state(bad_match), "tampered match receipt should fail closed", failures)
	var bad_ledger := purchased_state.duplicate(true)
	bad_ledger["requisition_spend_total_cents"] = 779
	_check(not DepartmentSimulation.new(7111, 4).restore_save_state(bad_ledger), "ledger inconsistent with upgrade levels and match should fail closed", failures)


func _test_workday_ledgers(failures: Array[String]) -> void:
	var simulation := _first_egg_fixture(7112, 1480)
	simulation.begin_first_clutch_reinvestment(0, 31, &"cracked", 180)
	simulation.resolve_first_clutch_reinvestment(KEYCAPS)
	var reports: Array[Dictionary] = []
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		reports.append(report.duplicate(true))
	)
	simulation.call("_complete_workday")
	_check(reports.size() == 1, "workday completion should emit one economy report", failures)
	if not reports.is_empty():
		var report := reports[0]
		var receipt := report.get("first_clutch_reinvestment", {}) as Dictionary
		_check(int(report.get("requisition_spend_cents", -1)) == 780 and int(report.get("orientation_procurement_match_cents", -1)) == 1720, "workday report should itemize actual debit and procurement match", failures)
		_check(StringName(receipt.get("status", &"")) == &"purchased" and int(receipt.get("trigger_claim_id", -1)) == 31, "workday report should retain the exact First Clutch receipt", failures)
	_check(simulation.requisition_spend_today_cents == 0 and simulation.orientation_procurement_match_today_cents == 0, "daily requisition ledgers should reset after report capture", failures)
	_check(simulation.requisition_spend_total_cents == 780 and simulation.orientation_procurement_match_total_cents == 1720, "lifetime requisition ledgers should survive rollover", failures)


func _first_egg_fixture(seed: int, spendable_cents: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 4)
	simulation.workers[0].eggs_laid = 1
	simulation.eggs_total = 1
	simulation.revenue_cents = (
		simulation.current_daily_operating_cost_cents()
		+ simulation.wage_arrears_cents
		+ spendable_cents
	)
	return simulation


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
