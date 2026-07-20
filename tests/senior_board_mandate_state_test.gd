extends SceneTree

const SeniorRoostStateScript := preload("res://core/campaign/senior_roost_state.gd")


func _init() -> void:
	var failures: Array[String] = []
	_test_offer_gate_and_progress(failures)
	_test_mandate_mastery_portfolio(failures)
	_test_mastery_aware_offer_rotation(failures)
	_test_unaffordable_unlocked_offer_visibility(failures)
	_test_settlement_tiers_and_stakes(failures)
	_test_v2_neutral_migration(failures)
	_test_versioned_mandate_terms(failures)
	_test_malformed_state_is_atomic(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("SENIOR_BOARD_MANDATE_STATE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SENIOR_BOARD_MANDATE_STATE_TEST_PASSED offers=3 gate=annual evidence=12 settlement=exact-once portfolio=7-books rotation=first-clear tiers=seals stakes=reserved+returned+forfeited migration=v2+v3+v4 validation=atomic")
	quit(0)


func _test_offer_gate_and_progress(failures: Array[String]) -> void:
	var senior := SeniorRoostStateScript.new()
	var twin := SeniorRoostStateScript.new()
	var opening := _opening_snapshot(6)
	_check(senior.begin(5, opening), "Senior year should begin at its mandate gate", failures)
	_check(twin.begin(5, opening), "determinism twin should begin", failures)
	var offers := senior.annual_mandate_catalog()
	_check(offers.size() == 3, "every Senior year must freeze exactly three mandate offers", failures)
	_check(offers == twin.annual_mandate_catalog(), "identical frozen context must produce identical offers", failures)
	var shell := _offer_by_id(offers, &"shell_stewardship")
	_check(
		"reinvest in faster keycaps and brighter QA lamps" in String(shell.get("summary", "")),
		"the opening Shell Book should disclose the early speed-and-quality reinvestment path",
		failures,
	)
	_check(StringName(String(offers[0].get("id", ""))) == SeniorRoostStateScript.MANDATE_FALLBACK_ID, "the universal no-stake fallback must be the first offer", failures)
	_check(int(offers[0].get("stake_marks", -1)) == 0 and bool(offers[0].get("available", false)), "the fallback must remain free and available", failures)
	_check(senior.requires_annual_mandate() and not senior.requires_quarter_policy(), "Q1 policy must wait for an annual mandate", failures)
	_check(not senior.record_quarter_policy(_policy_receipt()), "policy filing must reject an unselected annual mandate", failures)

	var before_stale := senior.to_dictionary()
	var stale := senior.select_annual_mandate(SeniorRoostStateScript.MANDATE_FALLBACK_ID, 2)
	_check(not bool(stale.get("accepted", true)) and String(stale.get("reason_id", "")) == "stale_year", "stale-year mandate selection must reject explicitly", failures)
	_check(senior.to_dictionary() == before_stale, "rejected mandate selection must be atomic", failures)
	var selected := senior.select_annual_mandate(SeniorRoostStateScript.MANDATE_FALLBACK_ID, 1)
	_check(bool(selected.get("accepted", false)), "the no-stake fallback must always select", failures)
	_check(not senior.requires_annual_mandate() and senior.requires_quarter_policy(), "mandate selection should open the Q1 policy gate", failures)
	_check(senior.record_quarter_policy(_policy_receipt()), "Q1 policy should file after mandate selection", failures)

	var first := senior.record_shift(_good_report(6))
	_check(bool(first.get("accepted", false)), "first mandate evidence shift should file", failures)
	var evidence := senior.to_dictionary().get("current_mandate_evidence", []) as Array
	_check(evidence.size() == 1, "one accepted workday must append exactly one compact evidence row", failures)
	if evidence.size() == 1:
		var row := evidence[0] as Dictionary
		_check(row.size() == 10 and row.has("met_quota") and not row.has("quota") and not row.has("overdue"), "mandate evidence should retain only the compact authoritative facts", failures)
	var before_duplicate := senior.to_dictionary()
	var duplicate := senior.record_shift(_good_report(6))
	_check(not bool(duplicate.get("accepted", true)), "duplicate workday evidence must reject", failures)
	_check(senior.to_dictionary() == before_duplicate, "rejected duplicate evidence must leave the state unchanged", failures)
	_check(bool(senior.record_shift(_good_report(7)).get("accepted", false)), "second mandate evidence shift should file", failures)
	var quarter_close := senior.record_shift(_good_report(8))
	_check(bool(quarter_close.get("accepted", false)) and bool(quarter_close.get("quarter_complete", false)), "third evidence shift should close Q1", failures)
	var progress := senior.current_annual_mandate_progress()
	_check(int(progress.get("shifts_recorded", -1)) == 3 and int(progress.get("quarter_checkpoints_filed", -1)) == 1, "mandate progress must expose the current quarterly checkpoint", failures)
	_check(not (progress.get("next_threshold", {}) as Dictionary).is_empty(), "incomplete mandate progress should expose the next threshold", failures)
	_check(not (progress.get("largest_recoverable_blocker", {}) as Dictionary).is_empty(), "incomplete mandate progress should expose its largest blocker", failures)
	var checkpoint := (quarter_close.get("quarter_review", {}) as Dictionary).get("annual_mandate_checkpoint", {}) as Dictionary
	_check(int(checkpoint.get("shifts_recorded", -1)) == 3, "the closed-quarter receipt must persist mandate progress", failures)

	var json_value: Variant = JSON.parse_string(JSON.stringify(senior.to_dictionary()))
	var restored = SeniorRoostStateScript.from_dictionary(json_value as Dictionary)
	_check(restored != null and restored.to_dictionary() == senior.to_dictionary(), "midyear mandate state must survive primitive JSON round-trip exactly", failures)


func _test_mandate_mastery_portfolio(failures: Array[String]) -> void:
	var senior := SeniorRoostStateScript.new()
	var fresh := senior.mandate_mastery_portfolio()
	_check(int(fresh.get("mastered_count", -1)) == 0 and int(fresh.get("total_count", -1)) == 7, "fresh Senior authority should expose seven distinct unmastered Board Books", failures)
	_check(String(fresh.get("portfolio_title", "")) == "OPEN BOARD PORTFOLIO", "fresh portfolio should use its authored opening title", failures)
	_check(not bool(fresh.get("complete", true)), "fresh portfolio must not claim mastery", failures)

	senior.mandate_success_counts[SeniorRoostStateScript.MANDATE_FALLBACK_ID] = 2
	senior.mandate_success_counts[&"shell_stewardship"] = 1
	senior.mandate_success_counts[&"flock_continuity"] = 1
	var developing := senior.mandate_mastery_portfolio()
	_check(int(developing.get("mastered_count", -1)) == 3, "three positive success ledgers should master three distinct Books", failures)
	_check(int(developing.get("total_successes", -1)) == 4 and int(developing.get("repeat_clears", -1)) == 1, "portfolio should distinguish one repeat filing from four total clears", failures)
	_check(String(developing.get("portfolio_title", "")) == "STRATEGY PORTFOLIO", "three distinct Books should reach the strategy portfolio tier", failures)
	_check(StringName((developing.get("next", {}) as Dictionary).get("id", &"")) == &"mutual_assurance", "next portfolio Book should follow the stable authored order", failures)

	_check(senior.begin(5, _opening_snapshot(6)), "mastery card fixture should open annual planning", failures)
	var catalog := senior.annual_mandate_catalog()
	var mastered_fallback := _offer_by_id(catalog, SeniorRoostStateScript.MANDATE_FALLBACK_ID)
	_check(bool(mastered_fallback.get("mastered", false)) and int(mastered_fallback.get("mastery_count", 0)) == 2, "annual cards should expose authoritative repeat mastery", failures)
	_check(String(mastered_fallback.get("mastery_text", "")) == "MASTERED x2", "annual cards should label repeat clears without implying a new portfolio entry", failures)

	for mandate_id: StringName in SeniorRoostStateScript.MANDATE_IDS:
		senior.mandate_success_counts[mandate_id] = 1
	var complete := senior.mandate_mastery_portfolio()
	_check(int(complete.get("mastered_count", -1)) == 7 and bool(complete.get("complete", false)), "one clear of every supported Book should complete the portfolio", failures)
	_check(String(complete.get("portfolio_title", "")) == "COMPLETE BOARD LEDGER" and (complete.get("next", {}) as Dictionary).is_empty(), "complete portfolio should publish its master title and no phantom next Book", failures)


func _test_mastery_aware_offer_rotation(failures: Array[String]) -> void:
	var fresh := SeniorRoostStateScript.new()
	_check(fresh.begin(5, _opening_snapshot(6)), "fresh rotation fixture should open", failures)
	var fresh_offers := fresh.annual_mandate_catalog()
	_check(fresh_offers.size() == 3, "fresh rotation should retain exactly three Books", failures)
	_check(not bool(fresh_offers[1].get("mastered", true)) and not bool(fresh_offers[2].get("mastered", true)), "the opening catalog should expose both unmastered tier-zero strategies", failures)

	# Under the legacy rotation this exact Year 2 context offered mastered Shell
	# Stewardship beside Executive Harvest while two eligible first clears waited.
	var developing := SeniorRoostStateScript.new()
	developing.completed_years = 1
	developing.mandate_seals = 1
	developing.roost_marks = 4
	developing.mandate_success_counts[&"shell_stewardship"] = 1
	_check(developing.begin(17, _opening_snapshot(18)), "developing portfolio fixture should open Year 2", failures)
	var developing_offers := developing.annual_mandate_catalog()
	_check(_offer_by_id(developing_offers, &"shell_stewardship").is_empty(), "mastery-aware rotation should not spend the variety slot on a cleared Book while eligible first clears remain", failures)
	_check(not _offer_by_id(developing_offers, &"mutual_assurance").is_empty(), "the same Year 2 rotation should surface Mutual Assurance as a first-clear opportunity", failures)
	_check(_unmastered_nonstandard_count(developing_offers) == 2, "both nonstandard Year 2 cards should be first-clear opportunities when the unlocked pool permits it", failures)

	# The hardest unlocked tier remains represented even when it is already
	# mastered; the second slot must still rescue the final missing portfolio Book.
	var nearly_complete := SeniorRoostStateScript.new()
	nearly_complete.completed_years = 6
	nearly_complete.roost_marks = 20
	for mandate_id: StringName in SeniorRoostStateScript.MANDATE_IDS:
		if mandate_id != &"mutual_assurance":
			nearly_complete.mandate_success_counts[mandate_id] = 1
	nearly_complete.mandate_seals = 12
	_check(nearly_complete.begin(77, _opening_snapshot(78)), "near-complete portfolio fixture should open", failures)
	var final_gap_offers := nearly_complete.annual_mandate_catalog()
	_check(not _offer_by_id(final_gap_offers, &"gold_standard_book").is_empty(), "the hardest unlocked Book should remain represented", failures)
	_check(not _offer_by_id(final_gap_offers, &"mutual_assurance").is_empty(), "the final eligible unmastered Book should receive the portfolio variety slot", failures)


func _test_unaffordable_unlocked_offer_visibility(failures: Array[String]) -> void:
	var senior := SeniorRoostStateScript.new()
	# Model the valid player-facing boundary after a seal has unlocked tier one
	# but Sponsorship or a prior forfeit leaves only one mark spendable.
	senior.completed_years = 1
	senior.mandate_seals = 1
	senior.roost_marks = 1
	_check(senior.begin(17, _opening_snapshot(18)), "low-mark Year 2 fixture should open", failures)
	var offers := senior.annual_mandate_catalog()
	_check(offers.size() == 3, "an unlocked but unaffordable tier must not shrink the three-book catalog", failures)
	var advanced := _highest_tier_offer(offers)
	_check(int(advanced.get("tier", 0)) == 1 and int(advanced.get("stake_marks", 0)) == 2, "the first unlocked advanced book should remain visible", failures)
	_check(not bool(advanced.get("available", true)), "an unaffordable advanced book must remain safely disabled", failures)
	_check("1 more available Roost Mark is required" in String(advanced.get("unavailable_reason", "")), "the locked advanced book should disclose its exact recovery goal", failures)
	var before := senior.to_dictionary()
	var rejected := senior.select_annual_mandate(StringName(String(advanced.get("id", ""))), 2)
	_check(not bool(rejected.get("accepted", true)) and String(rejected.get("reason_id", "")) == "insufficient_roost_marks", "locked advanced selection must reject with the authoritative mark reason", failures)
	_check(senior.to_dictionary() == before, "rejected advanced selection must leave the career ledger atomic", failures)
	_check(bool(offers[0].get("available", false)), "the no-stake Standard Board Book must remain available beside the aspirational card", failures)


func _test_settlement_tiers_and_stakes(failures: Array[String]) -> void:
	var senior := SeniorRoostStateScript.new()
	_check(senior.begin(5, _opening_snapshot(6)), "settlement fixture should begin", failures)
	_check(bool(senior.select_annual_mandate(SeniorRoostStateScript.MANDATE_FALLBACK_ID, 1).get("accepted", false)), "year-one fallback should select", failures)
	_complete_open_year(senior, 6, true, failures)
	_check(senior.status == SeniorRoostStateScript.STATUS_ANNUAL_REVIEW, "twelve accepted shifts should close the annual mandate", failures)
	_check(senior.mandate_history.size() == 1 and senior.mandate_seals == 1, "successful fallback should settle once and award one permanent seal", failures)
	_check(int(senior.mandate_mastery_portfolio().get("mastered_count", 0)) == 1, "first successful annual Book should add one distinct portfolio entry", failures)
	var first_settlement := senior.last_mandate_settlement
	_check(bool(first_settlement.get("success", false)) and int(first_settlement.get("year", 0)) == 1, "year-one settlement should record exact success", failures)
	_check(int((first_settlement.get("progress", {}) as Dictionary).get("shifts_recorded", 0)) == 12, "annual settlement must bind exactly twelve evidence rows", failures)
	_check(senior.current_annual_mandate_progress().is_empty(), "settlement must clear active annual evidence", failures)
	var annual_json: Variant = JSON.parse_string(JSON.stringify(senior.to_dictionary()))
	var annual_restored = SeniorRoostStateScript.from_dictionary(annual_json as Dictionary)
	_check(annual_restored != null and annual_restored.to_dictionary() == senior.to_dictionary(), "annual review should reconstruct its pre-settlement mastery-aware catalog exactly", failures)
	var settled_history_size := senior.mandate_history.size()
	_check(senior.continue_after_annual({}), "annual continuation should open the next mandate gate", failures)
	_check(not senior.continue_after_annual({}), "annual continuation cannot settle or continue twice", failures)
	_check(senior.mandate_history.size() == settled_history_size, "annual continuation must not duplicate settlement", failures)

	var tier_one := senior.mandate_tier_eligibility()
	_check(int(tier_one.get("eligible_tier", -1)) == 1, "one seal should unlock harder tier-one mandates", failures)
	var advanced := _highest_tier_offer(senior.annual_mandate_catalog())
	_check(int(advanced.get("tier", 0)) == 1 and int(advanced.get("stake_marks", 0)) == 2, "eligible year-two offers should include an affordable tier-one stake", failures)
	var marks_before_stake := senior.available_roost_marks()
	var advanced_selection := senior.select_annual_mandate(StringName(String(advanced.get("id", ""))), 2)
	_check(bool(advanced_selection.get("accepted", false)), "tier-one mandate should select", failures)
	_check(senior.available_roost_marks() == marks_before_stake - 2 and senior.mandate_stake_reserved() == 2, "active stake must be excluded from available Roost Marks", failures)
	_complete_open_year(senior, 18, true, failures)
	_check(bool(senior.last_mandate_settlement.get("success", false)), "good year should fulfill the advanced mandate", failures)
	_check(int(senior.last_mandate_settlement.get("stake_returned", -1)) == 2 and int(senior.last_mandate_settlement.get("stake_forfeited", -1)) == 0, "successful advanced settlement must return its exact stake", failures)
	_check(senior.mandate_marks_forfeited == 0 and senior.mandate_seals == 3, "advanced success should preserve marks and unlock the next seal tier", failures)
	_check(int(senior.mandate_mastery_portfolio().get("mastered_count", 0)) == 2, "a different advanced success should add a second portfolio entry", failures)

	_check(senior.continue_after_annual(_opening_snapshot(30)), "year three should open after advanced success", failures)
	var tier_two_offer := _highest_tier_offer(senior.annual_mandate_catalog())
	_check(int(tier_two_offer.get("tier", 0)) == 2 and int(tier_two_offer.get("stake_marks", 0)) == 4, "three seals should expose an affordable tier-two mandate", failures)
	var failure_selection := senior.select_annual_mandate(StringName(String(tier_two_offer.get("id", ""))), 3)
	_check(bool(failure_selection.get("accepted", false)), "tier-two failure fixture should select", failures)
	var available_while_reserved := senior.available_roost_marks()
	_complete_open_year(senior, 30, false, failures)
	var failed := senior.last_mandate_settlement
	_check(not bool(failed.get("success", true)) and int(failed.get("stake_forfeited", 0)) == 4, "failed advanced mandate must forfeit its exact stake", failures)
	_check(senior.mandate_marks_forfeited == 4 and senior.available_roost_marks() == available_while_reserved + _marks_earned_in_last_year(senior), "a failed stake must remain permanently unavailable after annual earnings", failures)
	_check(senior.mandate_history.size() == 3 and senior.mandate_seals == 3, "failure should settle once without inventing seals", failures)
	_check(int(senior.mandate_mastery_portfolio().get("mastered_count", 0)) == 2, "failed Books must not advance the mastery portfolio", failures)
	var bad_settlement := senior.to_dictionary()
	((bad_settlement["mandate_history"] as Array).back() as Dictionary)["stake_forfeited"] = 3
	var settlement_errors := SeniorRoostStateScript.validate_dictionary(bad_settlement)
	_check(_contains_error(settlement_errors, "stake_forfeited is inconsistent"), "validator should reject a fabricated annual stake settlement", failures)


func _test_v2_neutral_migration(failures: Array[String]) -> void:
	var senior := SeniorRoostStateScript.new()
	_check(senior.begin(5, _opening_snapshot(6)), "migration fixture should begin", failures)
	_check(bool(senior.select_annual_mandate(SeniorRoostStateScript.MANDATE_FALLBACK_ID, 1).get("accepted", false)), "migration fixture mandate should select", failures)
	_check(senior.record_quarter_policy(_policy_receipt()), "migration fixture policy should file", failures)
	_check(bool(senior.record_shift(_good_report(6)).get("accepted", false)), "migration fixture should contain one accepted shift", failures)
	var legacy := _as_v2(senior.to_dictionary())
	var legacy_before := legacy.duplicate(true)
	var restored = SeniorRoostStateScript.from_dictionary(legacy)
	_check(restored != null, "valid v2 in-progress Senior state should migrate", failures)
	_check(legacy == legacy_before, "v2 migration must not mutate the caller Dictionary", failures)
	if restored != null:
		var active := restored.active_annual_mandate()
		_check(bool(active.get("grandfathered", false)), "in-progress v2 years should receive a neutral grandfathered mandate", failures)
		_check(StringName(String(active.get("id", ""))) == SeniorRoostStateScript.MANDATE_FALLBACK_ID, "v2 neutral migration should use the universal fallback", failures)
		_check(restored.mandate_seals == 0 and restored.mandate_marks_forfeited == 0 and restored.mandate_history.is_empty(), "v2 migration must not invent seals, forfeitures, or prior settlements", failures)
		_check((restored.to_dictionary().get("current_mandate_evidence", []) as Array).size() == 1, "v2 migration should derive compact evidence from the one saved shift", failures)
		_complete_open_year(restored, 7, true, failures)
		var neutral: Dictionary = restored.last_mandate_settlement
		_check(bool(neutral.get("grandfathered", false)) and not bool(neutral.get("success", true)), "grandfathered year should settle neutrally rather than count as success", failures)
		_check(int(neutral.get("stake_forfeited", -1)) == 0 and int(neutral.get("seal_reward", -1)) == 0, "neutral v2 settlement must award and forfeit nothing", failures)

	var untouched := SeniorRoostStateScript.new()
	_check(untouched.begin(5, _opening_snapshot(6)), "untouched migration fixture should begin", failures)
	var restored_gate = SeniorRoostStateScript.from_dictionary(_as_v2(untouched.to_dictionary()))
	_check(restored_gate != null and restored_gate.requires_annual_mandate(), "untouched v2 Q1 should migrate to three fresh offers and require selection", failures)


func _test_versioned_mandate_terms(failures: Array[String]) -> void:
	var senior := SeniorRoostStateScript.new()
	_check(senior.begin(5, _opening_snapshot(6)), "versioned-terms fixture should open Year 1", failures)
	_check(bool(senior.select_annual_mandate(SeniorRoostStateScript.MANDATE_FALLBACK_ID, 1).get("accepted", false)), "versioned-terms fixture should select the Year 1 fallback", failures)
	_complete_open_year(senior, 6, true, failures)
	_check(senior.continue_after_annual(_opening_snapshot(18)), "versioned-terms fixture should open a valid Year 2", failures)
	var current_offer := _offer_by_id(senior.annual_mandate_catalog(), &"executive_harvest")
	_check(not current_offer.is_empty(), "new Year 2 catalog should expose Executive Harvest", failures)
	var current_objectives := current_offer.get("objectives", []) as Array
	_check(int((current_objectives[0] as Dictionary).get("target", 0)) == 80_640, "new credited target should use the measured 280 factor", failures)
	_check(int((current_objectives[2] as Dictionary).get("target", 0)) == 40, "new Executive favor target should use the measured 40 floor", failures)

	var legacy_v3 := senior.to_dictionary()
	legacy_v3["schema_version"] = 3
	(legacy_v3["annual_mandate_offer_context"] as Dictionary).erase("mandate_terms_version")
	(legacy_v3["annual_mandate_offer_context"] as Dictionary).erase("offer_rotation_version")
	for offer_value in legacy_v3["annual_mandate_offers"] as Array:
		var offer := offer_value as Dictionary
		if StringName(String(offer.get("id", ""))) != &"executive_harvest":
			continue
		var objectives := offer.get("objectives", []) as Array
		(objectives[0] as Dictionary)["target"] = 100_800
		(objectives[2] as Dictionary)["target"] = 55
	var restored = SeniorRoostStateScript.from_dictionary(legacy_v3)
	_check(restored != null, "a valid v3 frozen Book should migrate without changing its terms", failures)
	if restored != null:
		var migrated_context := restored.to_dictionary().get("annual_mandate_offer_context", {}) as Dictionary
		_check(int(migrated_context.get("mandate_terms_version", 0)) == 1, "v3 migration should explicitly freeze legacy terms version one", failures)
		_check(int(migrated_context.get("offer_rotation_version", 0)) == 1, "v3 migration should preserve the legacy mastery-blind offer rotation", failures)
		var legacy_offer := _offer_by_id(restored.annual_mandate_catalog(), &"executive_harvest")
		var legacy_objectives := legacy_offer.get("objectives", []) as Array
		_check(int((legacy_objectives[0] as Dictionary).get("target", 0)) == 100_800, "migrated v3 credited target must remain unchanged", failures)
		_check(int((legacy_objectives[2] as Dictionary).get("target", 0)) == 55, "migrated v3 favor target must remain unchanged", failures)

	var current_gate := SeniorRoostStateScript.new()
	_check(current_gate.begin(5, _opening_snapshot(6)), "v4 offer migration fixture should begin", failures)
	var legacy_v4 := current_gate.to_dictionary()
	var frozen_v4_offers := (legacy_v4.get("annual_mandate_offers", []) as Array).duplicate(true)
	legacy_v4["schema_version"] = 4
	(legacy_v4["annual_mandate_offer_context"] as Dictionary).erase("offer_rotation_version")
	var restored_v4 = SeniorRoostStateScript.from_dictionary(legacy_v4)
	_check(restored_v4 != null, "a valid v4 frozen catalog should migrate", failures)
	if restored_v4 != null:
		var migrated_v4 := restored_v4.to_dictionary()
		_check(int(migrated_v4.get("schema_version", 0)) == 5, "v4 migration should emit schema v5", failures)
		_check(int((migrated_v4.get("annual_mandate_offer_context", {}) as Dictionary).get("offer_rotation_version", 0)) == 1, "v4 migration should label its frozen catalog as legacy rotation", failures)
		_check((migrated_v4.get("annual_mandate_offers", []) as Array) == frozen_v4_offers, "v4 migration must preserve all three frozen Books byte-for-byte", failures)


func _test_malformed_state_is_atomic(failures: Array[String]) -> void:
	var senior := SeniorRoostStateScript.new()
	_check(senior.begin(5, _opening_snapshot(6)), "validation fixture should begin", failures)
	_check(bool(senior.select_annual_mandate(SeniorRoostStateScript.MANDATE_FALLBACK_ID, 1).get("accepted", false)), "validation fixture mandate should select", failures)
	_check(senior.record_quarter_policy(_policy_receipt()), "validation fixture policy should file", failures)
	_check(bool(senior.record_shift(_good_report(6)).get("accepted", false)), "validation fixture should contain evidence", failures)

	var malformed := senior.to_dictionary()
	var malformed_before := malformed.duplicate(true)
	var objective := ((((malformed["annual_mandate_offers"] as Array)[0] as Dictionary)["objectives"] as Array)[0] as Dictionary)
	objective["target"] = int(objective["target"]) + 1
	malformed_before = malformed.duplicate(true)
	var offer_errors := SeniorRoostStateScript.validate_dictionary(malformed)
	_check(_contains_error(offer_errors, "frozen context"), "validator should reject tampered frozen offers", failures)
	_check(SeniorRoostStateScript.from_dictionary(malformed) == null, "from_dictionary should reject malformed mandate state atomically", failures)
	_check(malformed == malformed_before, "rejected malformed state must not be mutated", failures)

	var stale := senior.to_dictionary()
	(stale["annual_mandate_offer_context"] as Dictionary)["year"] = 9
	var stale_errors := SeniorRoostStateScript.validate_dictionary(stale)
	_check(_contains_error(stale_errors, "stale") or _contains_error(stale_errors, "frozen context"), "validator should reject stale annual context", failures)

	var bad_evidence := senior.to_dictionary()
	(bad_evidence["current_mandate_evidence"] as Array)[0]["day"] = 99
	var evidence_errors := SeniorRoostStateScript.validate_dictionary(bad_evidence)
	_check(_contains_error(evidence_errors, "inconsistent with its Senior shift"), "validator should reject fabricated compact evidence", failures)

	var bad_selection := senior.to_dictionary()
	(bad_selection["last_mandate_selection"] as Dictionary)["year"] = 99
	var selection_errors := SeniorRoostStateScript.validate_dictionary(bad_selection)
	_check(_contains_error(selection_errors, "last_mandate_selection.year is inconsistent"), "validator should reject a stale selection receipt", failures)


func _complete_open_year(
	senior: SeniorRoostState,
	start_day: int,
	good: bool,
	failures: Array[String],
) -> void:
	var next_day := start_day
	while senior.status != SeniorRoostStateScript.STATUS_ANNUAL_REVIEW:
		if senior.requires_annual_mandate():
			_check(false, "year completion helper requires a selected annual mandate", failures)
			return
		if senior.requires_quarter_policy():
			_check(senior.record_quarter_policy(_policy_receipt()), "quarter policy should file during annual completion", failures)
		var report := _good_report(next_day) if good else _poor_report(next_day)
		var result := senior.record_shift(report)
		_check(bool(result.get("accepted", false)), "Senior day %d should file during annual completion" % next_day, failures)
		if not bool(result.get("accepted", false)):
			return
		next_day += 1


func _highest_tier_offer(offers: Array[Dictionary]) -> Dictionary:
	var highest: Dictionary = {}
	for offer in offers:
		if int(offer.get("tier", -1)) > int(highest.get("tier", -1)):
			highest = offer.duplicate(true)
	return highest


func _offer_by_id(offers: Array[Dictionary], id: StringName) -> Dictionary:
	for offer in offers:
		if StringName(String(offer.get("id", ""))) == id:
			return offer.duplicate(true)
	return {}


func _unmastered_nonstandard_count(offers: Array[Dictionary]) -> int:
	var count := 0
	for offer in offers:
		if (
			StringName(String(offer.get("id", ""))) != SeniorRoostStateScript.MANDATE_FALLBACK_ID
			and not bool(offer.get("mastered", false))
		):
			count += 1
	return count


func _as_v2(value: Dictionary) -> Dictionary:
	var legacy := value.duplicate(true)
	legacy["schema_version"] = 2
	for key in [
		"mandate_marks_forfeited", "mandate_seals", "next_mandate_settlement_id",
		"annual_mandate_offer_context", "annual_mandate_offers",
		"active_annual_mandate", "current_mandate_evidence", "mandate_history",
		"last_mandate_selection", "last_mandate_settlement", "mandate_success_counts",
	]:
		legacy.erase(key)
	return legacy


func _marks_earned_in_last_year(senior: SeniorRoostState) -> int:
	if senior.annual_history.is_empty():
		return 0
	var annual := senior.annual_history.back() as Dictionary
	var total := int(annual.get("annual_bonus_marks", 0))
	for quarter_value in annual.get("quarters", []) as Array:
		if quarter_value is Dictionary:
			total += int((quarter_value as Dictionary).get("marks_awarded", 0))
	return total


func _opening_snapshot(day: int) -> Dictionary:
	return {
		"day": day,
		"revenue_cents": 20_000,
		"quota_target": 24,
	}


func _policy_receipt() -> Dictionary:
	return {
		"accepted": true,
		"policy_id": &"harvest_forecast",
		"style_id": &"management_innovation",
		"outcome": "Quarter policy filed.",
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
		"closing_fund_cents": 30_000 + day * 100,
	}


func _poor_report(day: int) -> Dictionary:
	return {
		"day": day,
		"eggs": 8,
		"quota": 24,
		"cracked": 8,
		"overdue_claims": 12,
		"rework_total_created": day,
		"credited_cents": 0,
		"welfare": 10,
		"compliance": 10,
		"farmer_favor": 10,
		"wage_arrears_cents": 500,
		"closing_fund_cents": 0,
	}


func _contains_error(errors: PackedStringArray, needle: String) -> bool:
	for error in errors:
		if needle in error:
			return true
	return false


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
