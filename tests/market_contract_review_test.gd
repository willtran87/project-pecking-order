extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	var review_results := office.get("_review_results") as Label
	_check(review_results != null, "production Office should compose its farmer-review ledger", failures)
	if review_results == null:
		await _finish(office, failures)
		return

	var fulfilled := _base_report()
	fulfilled.merge({
		"credited_cents": 7000,
		"quota_bonus_cents": 1000,
		"quality_bonus_cents": 500,
		"operating_cost_cents": 3000,
		"closing_fund_cents": 12_345,
		"market_contract_base_premium_cents": 1000,
		"market_contract_service_coop_bonus_cents": 500,
		"market_contract_premium_cents": 1500,
		"market_contract_breach_cents": 0,
		"farm_mutual_standing": {
			"points": 2,
			"rank": &"bronze",
			"rank_label": "BRONZE",
			"clean_streak": 1,
		},
		"market_contract": {
			"short_name": "HOMESTEAD BINDER",
			"status": "fulfilled",
			"timely_sound_completed": 4,
			"required_completed": 4,
			"base_premium_cents": 1000,
			"service_coop_level_at_signing": 1,
			"service_coop_bonus_cents": 500,
			"premium_cents": 1500,
			"breach_cents": 0,
		},
	}, true)
	office.call("_show_farmer_review", fulfilled, false)
	var fulfilled_text := review_results.text
	_check("Production credit +$40.00" in fulfilled_text, "fulfilled review should exclude the $10 premium from base production", failures)
	_check("Production credit +$55.00" not in fulfilled_text, "fulfilled review must not double-count the base premium or Coop bonus as production", failures)
	_check("Farm Mutual: HOMESTEAD BINDER FULFILLED" in fulfilled_text, "fulfilled review should name the settled binder", failures)
	_check(
		"Base +$10.00" in fulfilled_text
		and "Coop L1 +$5.00" in fulfilled_text
		and "=  +$15.00" in fulfilled_text
		and "Breach -$" not in fulfilled_text,
		"fulfilled review should itemize base, frozen Service Coop bonus, and exact total",
		failures,
	)
	_check("4/4 clean on time" in fulfilled_text, "fulfilled review should show authoritative delivery evidence", failures)
	_check("BRONZE standing 2" in fulfilled_text and "1 clean binder streak" in fulfilled_text, "fulfilled review should show the standing earned by the clean binder", failures)
	_check("Net operating +$40.00" in fulfilled_text, "fulfilled net should include base and Coop premium exactly once", failures)
	_check("Closing Feed Fund $123.45" in fulfilled_text, "fulfilled review should preserve authoritative closing cash", failures)
	_check(
		"Base premium and the Service Coop accreditation bonus are itemized" in review_results.tooltip_text
		and "enter gross credit exactly once" in review_results.tooltip_text,
		"fulfilled tooltip should explain the itemized accounting boundary",
		failures,
	)

	var negotiated := _base_report()
	negotiated.merge({
		"credited_cents": 7450,
		"quota_bonus_cents": 1000,
		"quality_bonus_cents": 500,
		"operating_cost_cents": 3000,
		"closing_fund_cents": 14_295,
		"market_contract_base_premium_cents": 1000,
		"market_contract_season_premium_delta_cents": 200,
		"market_contract_clause_premium_delta_cents": 250,
		"market_contract_service_coop_bonus_cents": 500,
		"market_contract_premium_cents": 1950,
		"market_contract_breach_cents": 0,
		"market_contract": {
			"short_name": "HOMESTEAD BINDER",
			"status": "fulfilled",
			"timely_sound_completed": 4,
			"required_completed": 4,
			"base_premium_cents": 1000,
			"season_id": &"spring_hatch_surge",
			"season_premium_delta_cents": 200,
			"clause_id": &"expedited_hatch_rider",
			"clause_premium_delta_cents": 250,
			"service_coop_level_at_signing": 1,
			"service_coop_bonus_cents": 500,
			"premium_cents": 1950,
			"breach_cents": 0,
		},
	}, true)
	office.call("_show_farmer_review", negotiated, false)
	var negotiated_text := review_results.text
	_check(
		"Authored +$10.00  +  Season +$2.00  +  Rider +$2.50  +  Coop L1 +$5.00  =  +$19.50"
		in negotiated_text,
		"schema-v14 review should itemize authored, signed season, rider, frozen Coop, and exact total",
		failures,
	)
	_check(
		"Production credit +$40.00" in negotiated_text
		and "Net operating +$44.50" in negotiated_text,
		"schema-v14 review should settle its full premium exactly once",
		failures,
	)

	var breached := _base_report()
	breached.merge({
		"credited_cents": 4000,
		"quota_bonus_cents": 0,
		"quality_bonus_cents": 0,
		"operating_cost_cents": 3000,
		"closing_fund_cents": 7777,
		"market_contract_premium_cents": 0,
		"market_contract_breach_cents": 500,
		"market_contract": {
			"short_name": "HOMESTEAD BINDER",
			"status": "breached",
			"timely_sound_completed": 3,
			"required_completed": 4,
			"premium_cents": 0,
			"breach_cents": 500,
		},
	}, true)
	office.call("_show_farmer_review", breached, false)
	var breached_text := review_results.text
	_check("Production credit +$40.00" in breached_text, "breach review should preserve base production credit", failures)
	_check("Farm Mutual: HOMESTEAD BINDER BREACHED" in breached_text, "breach review should name the failed binder", failures)
	_check("Breach -$5.00" in breached_text and "Premium +$" not in breached_text, "breach review should itemize only its exact charge", failures)
	_check("3/4 clean on time" in breached_text, "breach review should show authoritative delivery evidence", failures)
	_check("Net operating +$5.00" in breached_text, "breach net should deduct the $5 charge exactly once", failures)
	_check("Closing Feed Fund $77.77" in breached_text, "breach review should preserve authoritative closing cash", failures)

	await _finish(office, failures)


func _base_report() -> Dictionary:
	return {
		"day": 3,
		"met_quota": true,
		"eggs": 8,
		"quota": 8,
		"cracked": 0,
		"golden": 0,
		"feed_cost_cents": 1000,
		"payroll_cents": 1500,
		"facility_cost_cents": 500,
		"facility_expansion_cost_cents": 0,
		"facility_maintenance_cents": 500,
		"wage_arrears_cents": 0,
		"packing_contract": {},
		"directive": {"short_name": "SHELL ASSURANCE"},
		"incidents_resolved": 0,
		"lane_processed": {
			&"nest_damage": 4,
			&"predator_loss": 2,
			&"appeals": 2,
		},
		"overdue_claims": 0,
		"rework_waiting": 0,
		"rework_due_next_shift": 0,
		"claims_outstanding": 6,
		"claim_capacity": 18,
		"intake_rejections_today": 0,
		"intake_missed_value_today_cents": 0,
		"personnel_action": {},
		"pecking_order": [],
		"average_manager_trust": 60,
		"average_grievance": 8,
		"new_facility_unlocks": [],
		"next_quota": 9,
	}


func _finish(office: Node, failures: Array[String]) -> void:
	await create_timer(0.1).timeout
	if office != null and is_instance_valid(office):
		office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("MARKET_CONTRACT_REVIEW_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MARKET_CONTRACT_REVIEW_TEST_PASSED premium=separate breach=separate production=base net=single-settlement closing=authoritative")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
