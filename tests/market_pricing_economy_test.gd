extends SceneTree


const OFFER: StringName = &"homestead_stability_binder"


func _init() -> void:
	var failures: Array[String] = []
	_test_rate_postures_change_volume_price_and_margin(failures)
	_test_claimant_sentiment_and_reach_unlock_future_terms(failures)
	_test_executive_select_spends_and_requires_claimant_trust(failures)
	_test_settlement_updates_sentiment_reach_and_share(failures)
	_test_pricing_signature_and_checkpoint_integrity(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("MARKET_PRICING_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MARKET_PRICING_ECONOMY_TEST_PASSED postures=3 volume=4-6 satisfaction=renewable-gate reach=unlock margin=exact")
	quit(0)


func _test_rate_postures_change_volume_price_and_margin(failures: Array[String]) -> void:
	var simulation := _review_simulation(21101)
	var mutual := simulation.market_contract_offer_preflight(
		OFFER, &"standard_terms", &"mutual_rate"
	)
	var access := simulation.market_contract_offer_preflight(
		OFFER, &"standard_terms", &"community_access_rate"
	)
	var select := simulation.market_contract_offer_preflight(
		OFFER, &"standard_terms", &"executive_select_rate"
	)
	_check(int(mutual.get("total_claims", -1)) == 5, "Mutual Rate should retain five folders", failures)
	_check(int(access.get("total_claims", -1)) == 6, "Community Access should add one referred folder", failures)
	_check(int(select.get("total_claims", -1)) == 4, "Executive Select should remove one standard folder", failures)
	_check(int(mutual.get("required_completed", -1)) == 4, "Mutual Rate should retain the 4-file threshold", failures)
	_check(int(access.get("required_completed", -1)) == 5, "Community Access should require the referred folder", failures)
	_check(int(select.get("required_completed", -1)) == 3, "Executive Select should reduce the delivery threshold", failures)
	_check(int(mutual.get("premium_cents", -1)) == 1000, "Mutual Rate should preserve the $10 premium", failures)
	_check(int(access.get("premium_cents", -1)) == 800, "Community Access should quote 20% below the base premium", failures)
	_check(int(select.get("premium_cents", -1)) == 1300, "Executive Select should quote 30% above the base premium", failures)
	_check(int(mutual.get("estimated_margin_cents", -1)) == 375, "Mutual Rate should disclose $3.75 estimated binder margin", failures)
	_check(int(access.get("estimated_margin_cents", -1)) == 50, "Community Access should disclose its thin $0.50 margin", failures)
	_check(int(select.get("estimated_margin_cents", -1)) == 800, "Executive Select should disclose its $8 margin", failures)
	_check(bool(access.get("can_sign", false)), "Community Access should remain a viable early-game choice", failures)
	_check(not bool(select.get("can_sign", true)), "Executive Select should be held before reach is earned", failures)
	_check("reach" in String(select.get("reason", "")).to_lower(), "the premium-tier hold should explain its reach requirement", failures)


func _test_claimant_sentiment_and_reach_unlock_future_terms(failures: Array[String]) -> void:
	var simulation := _review_simulation(21102)
	simulation.market_contracts_signed_total = 1
	simulation.market_contracts_succeeded_total = 1
	simulation.market_pricing_outcomes["community_access_rate_success"] = 1
	var status := simulation.market_pricing_status()
	_check(int(status.get("reach_points", -1)) == 3, "a fulfilled access binder should earn three reach points", failures)
	_check(int(status.get("claimant_satisfaction", -1)) == 54, "a fulfilled access binder should raise claimant satisfaction by four", failures)
	_check(int(status.get("market_share_basis_points", -1)) == 4250, "three reach points should move Mutual share to 42.50%", failures)
	var select := simulation.market_contract_offer_preflight(
		OFFER, &"standard_terms", &"executive_select_rate"
	)
	_check(bool(select.get("pricing_available", false)), "earned reach should unlock Executive Select", failures)
	_check(bool(select.get("can_sign", false)), "the reached premium tier should pass an otherwise-clear preflight", failures)


func _test_executive_select_spends_and_requires_claimant_trust(
	failures: Array[String],
) -> void:
	var simulation := _review_simulation(21109)
	simulation.market_contracts_signed_total = 4
	simulation.market_contracts_succeeded_total = 4
	simulation.market_pricing_outcomes["community_access_rate_success"] = 1
	simulation.market_pricing_outcomes["executive_select_rate_success"] = 3
	var status := simulation.market_pricing_status()
	_check(
		int(status.get("reach_points", -1)) == 3
		and int(status.get("claimant_satisfaction", -1)) == 48
		and int(status.get("executive_select_satisfaction_minimum", -1)) == 50,
		"three premium successes should retain reach but spend claimant sentiment below the renewable gate",
		failures,
	)
	var held := simulation.market_contract_offer_preflight(
		OFFER, &"standard_terms", &"executive_select_rate"
	)
	_check(
		not bool(held.get("pricing_available", true))
		and not bool(held.get("can_sign", true))
		and int(held.get("pricing_required_satisfaction", -1)) == 50
		and int(held.get("pricing_current_satisfaction", -1)) == 48
		and "claimant sentiment of 50" in String(held.get("reason", "")).to_lower()
		and "community access" in String(held.get("reason", "")).to_lower(),
		"Executive Select should close after consuming trust and explain the exact recovery route",
		failures,
	)
	_check(
		bool(simulation.market_contract_offer_preflight(
			OFFER, &"standard_terms", &"mutual_rate"
		).get("can_sign", false))
		and bool(simulation.market_contract_offer_preflight(
			OFFER, &"standard_terms", &"community_access_rate"
		).get("can_sign", false)),
		"Mutual and Community Access should remain available to rebuild claimant trust",
		failures,
	)
	simulation.market_pricing_outcomes["community_access_rate_success"] = 2
	var reopened := simulation.market_contract_offer_preflight(
		OFFER, &"standard_terms", &"executive_select_rate"
	)
	_check(
		simulation.claimant_satisfaction_score() == 52
		and bool(reopened.get("pricing_available", false))
		and bool(reopened.get("can_sign", false)),
		"a fulfilled Community Access binder should renew trust and reopen the premium tier",
		failures,
	)


func _test_pricing_signature_and_checkpoint_integrity(failures: Array[String]) -> void:
	var simulation := _review_simulation(21103)
	var signed := simulation.sign_market_contract(
		OFFER, &"standard_terms", &"community_access_rate"
	)
	_check(bool(signed.get("accepted", false)), "the access-rate binder should sign", failures)
	_check(
		StringName(simulation.active_market_contract.get("pricing_profile_id", &""))
		== &"community_access_rate",
		"the signed binder should freeze its exact pricing posture",
		failures,
	)
	_check(
		(simulation.active_market_contract.get("claim_ids", []) as Array).size() == 6,
		"the signed access binder should reserve six unique folders",
		failures,
	)
	var checkpoint := simulation.export_save_state()
	var restored := DepartmentSimulation.new(21104, 4)
	_check(restored.restore_save_state(checkpoint), "an authentic priced binder checkpoint should restore", failures)
	_check(
		StringName(restored.active_market_contract.get("pricing_profile_id", &""))
		== &"community_access_rate",
		"restore should preserve the frozen pricing posture",
		failures,
	)
	var tampered := checkpoint.duplicate(true)
	var outcomes := (tampered.get("market_pricing_outcomes", {}) as Dictionary).duplicate(true)
	outcomes["executive_select_rate_success"] = 1
	tampered["market_pricing_outcomes"] = outcomes
	var rejected := DepartmentSimulation.new(21105, 4)
	_check(not rejected.restore_save_state(tampered), "unearned pricing outcomes must fail checkpoint validation", failures)


func _test_settlement_updates_sentiment_reach_and_share(failures: Array[String]) -> void:
	var simulation := _review_simulation(21106)
	_check(
		bool(simulation.sign_market_contract(
			OFFER,
			&"standard_terms",
			&"community_access_rate",
		).get("accepted", false)),
		"the settlement fixture should sign Community Access",
		failures,
	)
	var required := int(simulation.active_market_contract.get("required_completed", 0))
	simulation.active_market_contract["timely_sound_completed"] = required
	simulation.active_market_contract["sound_completed"] = required
	simulation.active_market_contract["completed_count"] = required
	var released_schedules: Array[Dictionary] = []
	for schedule_value in simulation.active_market_contract.get("scheduled_claims", []):
		var schedule := (schedule_value as Dictionary).duplicate(true)
		schedule["released"] = true
		schedule["rejected"] = false
		released_schedules.append(schedule)
	simulation.active_market_contract["scheduled_claims"] = released_schedules
	simulation.active_market_contract["accepted_claim_ids"] = (
		simulation.active_market_contract.get("claim_ids", []) as Array
	).duplicate()
	var result := simulation.call("_settle_market_contract", simulation.day) as Dictionary
	_check(bool(result.get("success", false)), "the completed Community Access binder should fulfill", failures)
	_check(
		int(result.get("claimant_satisfaction_before", -1)) == 50
		and int(result.get("claimant_satisfaction_after", -1)) == 54,
		"settlement should receipt the exact 50-to-54 claimant sentiment change",
		failures,
	)
	_check(
		int(result.get("market_reach_before", -1)) == 0
		and int(result.get("market_reach_after", -1)) == 3
		and int(result.get("market_share_basis_points", -1)) == 4250,
		"settlement should receipt three reach points and 42.50% projected share",
		failures,
	)
	var checkpoint := simulation.export_save_state()
	var restored := DepartmentSimulation.new(21107, 4)
	_check(restored.restore_save_state(checkpoint), "the settled pricing ledger should restore", failures)
	_check(
		restored.market_reach_points() == 3
		and restored.claimant_satisfaction_score() == 54,
		"restored outcome counters should reproduce reach and claimant sentiment exactly",
		failures,
	)
	simulation.day = 4
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	# Model the accounting boundary that _complete_workday() applies before the
	# next review. Lifetime pricing history remains; day-three receipts do not.
	simulation.credited_today_cents = 0
	simulation.market_contract_premium_today_cents = 0
	simulation.market_contract_breach_today_cents = 0
	var executive := simulation.sign_market_contract(
		OFFER,
		&"standard_terms",
		&"executive_select_rate",
	)
	_check(bool(executive.get("accepted", false)), "earned reach should permit a later Executive Select signature", failures)
	var executive_checkpoint := simulation.export_save_state()
	var executive_restored := DepartmentSimulation.new(21108, 4)
	_check(
		executive_restored.restore_save_state(executive_checkpoint),
		"a reached Executive Select binder should survive checkpoint validation",
		failures,
	)
	var tampered_executive := executive_checkpoint.duplicate(true)
	var tampered_contract := (
		(tampered_executive.get("active_market_contract", {}) as Dictionary).duplicate(true)
	)
	tampered_contract["pricing_required_satisfaction"] = 49
	tampered_executive["active_market_contract"] = tampered_contract
	_check(
		not DepartmentSimulation.new(21110, 4).restore_save_state(tampered_executive),
		"a saved premium binder may not weaken its authored claimant-sentiment requirement",
		failures,
	)


func _review_simulation(seed: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 4)
	simulation.day = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 100_000
	return simulation


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
