extends SceneTree


func _init() -> void:
	create_timer(45.0).timeout.connect(func() -> void:
		push_error("WEB_DIAGNOSTIC_COMPACTION_TEST_TIMEOUT")
		quit(1)
	)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := _heavy_projection_fixture(failures)
	var office := Office.new()
	var snapshot := simulation.snapshot()

	var contract_source := snapshot.get("contract_board", {}) as Dictionary
	var contract_hidden := office.call(
		"_compact_contract_board_diagnostic",
		contract_source,
		false,
	) as Dictionary
	var contract_visible := office.call(
		"_compact_contract_board_diagnostic",
		contract_source,
		true,
	) as Dictionary
	var raw_contract_bytes := _json_bytes(contract_source)
	var hidden_contract_bytes := _json_bytes(contract_hidden)
	var visible_contract_bytes := _json_bytes(contract_visible)
	_check(
		raw_contract_bytes > 100_000,
		"fixture should reproduce the recursively expanded contract catalog",
		failures,
	)
	_check(
		(contract_hidden.get("offers", []) as Array).is_empty()
		and hidden_contract_bytes < 6_000,
		"hidden Contract Board diagnostics should retain authority without its offer matrix",
		failures,
	)
	var compact_offers := contract_visible.get("offers", []) as Array
	var selected_offer := (contract_source.get("offers", []) as Array)[0] as Dictionary
	var selected_terms := office.call(
		"_compact_contract_offer_diagnostic",
		selected_offer,
	) as Dictionary
	_check(
		compact_offers.size() == 3
		and visible_contract_bytes < 20_000
		and not (compact_offers[0] as Dictionary).has("clause_options")
		and not (compact_offers[0] as Dictionary).has("pricing_options")
		and ((compact_offers[0] as Dictionary).get("scheduled_claims", []) as Array).is_empty()
		and not (selected_terms.get("scheduled_claims", []) as Array).is_empty(),
		"visible planning should expose three useful binder summaries without recursive terms",
		failures,
	)

	var operations_source := snapshot.get("operations", {}) as Dictionary
	var operations_compact := office.call(
		"_compact_operations_diagnostic",
		operations_source,
	) as Dictionary
	var raw_operations_bytes := _json_bytes(operations_source)
	var compact_operations_bytes := _json_bytes(operations_compact)
	_check(
		raw_operations_bytes > 8_000
		and compact_operations_bytes < 6_000
		and (operations_compact.get("manager_roster", []) as Array).size()
			== (operations_source.get("manager_roster", []) as Array).size()
		and (operations_compact.get("manager_candidates", []) as Array).size()
			== (operations_source.get("manager_candidates", []) as Array).size()
		and not (operations_compact.get("rooster_operations_office", {}) as Dictionary).has(
			"current_automation_compliance_exposure_millipoints"
		)
		and (operations_compact.get("succession_shared_terms", {}) as Dictionary).has(
			"supervisor_payroll_after_cents"
		),
		"operations diagnostics should preserve every manager and current decision without facility matrices",
		failures,
	)
	var operations_held := office.call(
		"_compact_operations_diagnostic",
		operations_source,
		false,
	) as Dictionary
	_check(
		bool(office.call("_operations_staffing_details_visible", true, &""))
		and not bool(office.call(
			"_operations_staffing_details_visible",
			true,
			&"manager_succession",
		)),
		"Operations staffing details should retire only while a blocking confirmation is held",
		failures,
	)
	_check(
		(operations_held.get("manager_roster", []) as Array).is_empty()
		and (operations_held.get("manager_candidates", []) as Array).is_empty()
		and int(operations_held.get("manager_roster_count", 0))
			== (operations_source.get("manager_roster", []) as Array).size()
		and _json_bytes(operations_held) < 3_000,
		"a held confirmation should replace the blocked manager catalog with exact counts until return",
		failures,
	)

	var care_source := snapshot.get("flock_care", {}) as Dictionary
	var care_compact := office.call(
		"_compact_flock_care_diagnostic",
		care_source,
	) as Dictionary
	var raw_care_bytes := _json_bytes(care_source)
	var compact_care_bytes := _json_bytes(care_compact)
	_check(
		raw_care_bytes > 8_000
		and compact_care_bytes < 6_000
		and not (care_compact.get("wellness_nest", {}) as Dictionary).has(
			"current_automation_compliance_exposure_millipoints"
		)
		and (care_compact.get("effects", {}) as Dictionary).has(
			"wellness_break_recovery_multiplier"
		),
		"care diagnostics should retain actionable recovery and training terms without facility matrices",
		failures,
	)

	var capital_source := _capital_plan_fixture(snapshot)
	var capital_compact := office.call(
		"_compact_capital_plan_diagnostic",
		capital_source,
	) as Dictionary
	var raw_capital_bytes := _json_bytes(capital_source)
	var compact_capital_bytes := _json_bytes(capital_compact)
	_check(
		raw_capital_bytes > 8_000
		and compact_capital_bytes < 2_500
		and int(capital_compact.get("commissioning_count", 0)) == 12
		and not capital_compact.has("commissioning_history")
		and (capital_compact.get("latest_commissioning", {}) as Dictionary).is_empty()
		and int((capital_compact.get("last_facility_purchase_receipt", {}) as Dictionary).get("day", 0)) == 12,
		"capital diagnostics should bound commissioning history while retaining its count and latest receipt",
		failures,
	)

	var work_progress_source := _dormant_work_progress_fixture()
	var work_progress_compact := office.call(
		"_compact_work_progress_diagnostic",
		work_progress_source,
	) as Dictionary
	_check(
		_json_bytes(work_progress_source) > 2_000
		and _json_bytes(work_progress_compact) < 500
		and (work_progress_compact.get("desks", []) as Array).is_empty(),
		"dormant desk rails should collapse to their bounded pool and visibility counters",
		failures,
	)
	var live_work_progress := work_progress_source.duplicate(true)
	live_work_progress["visible_count"] = 1
	var live_work_progress_compact := office.call(
		"_compact_work_progress_diagnostic",
		live_work_progress,
	) as Dictionary
	_check(
		_json_bytes(live_work_progress_compact) == _json_bytes(live_work_progress),
		"live desk rails should retain their complete visual and interaction state",
		failures,
	)

	var safeguards_source := _probation_safeguards_fixture()
	var safeguards_compact := office.call(
		"_compact_probation_safeguards_diagnostic",
		safeguards_source,
	) as Dictionary
	_check(
		_json_bytes(safeguards_source) > 3_000
		and _json_bytes(safeguards_compact) < 2_200
		and (safeguards_compact.get("criteria", []) as Array).size() == 5
		and String((safeguards_compact.get("challenge_contract", {}) as Dictionary).get("id", ""))
			== "standard_filing",
		"safeguard diagnostics should preserve every exact gate without duplicating the full challenge brief",
		failures,
	)

	var interaction_safety_source := _dormant_interaction_safety_fixture()
	var interaction_safety_compact := office.call(
		"_compact_interaction_safety_diagnostic",
		interaction_safety_source,
	) as Dictionary
	_check(
		_json_bytes(interaction_safety_source) > 1_300
		and _json_bytes(interaction_safety_compact) < 300
		and not bool((interaction_safety_compact.get("confirmation_backdrop", {}) as Dictionary).get("visible", true)),
		"dormant confirmations should publish only their authoritative visibility flags",
		failures,
	)
	var live_interaction_safety := interaction_safety_source.duplicate(true)
	(live_interaction_safety.get("staffing", {}) as Dictionary)[
		"manager_recruit_confirmation_visible"
	] = true
	var live_interaction_safety_compact := office.call(
		"_compact_interaction_safety_diagnostic",
		live_interaction_safety,
	) as Dictionary
	_check(
		_json_bytes(live_interaction_safety_compact) == _json_bytes(live_interaction_safety),
		"a live irreversible confirmation should retain every safety label and exact term",
		failures,
	)

	var portfolio_source := snapshot.get("campus_portfolio", {}) as Dictionary
	var portfolio_compact := office.call(
		"_compact_campus_portfolio_diagnostic",
		portfolio_source,
	) as Dictionary
	_check(
		_json_bytes(portfolio_source) > 20_000
		and _json_bytes(portfolio_compact) < 6_000
		and not portfolio_compact.has("module_catalog")
		and (portfolio_compact.get("modules", []) as Array).size() == 4
		and not ((portfolio_compact.get("modules", []) as Array)[0] as Dictionary).has("pad_quotes"),
		"portfolio diagnostics should preserve deeds, projects, resources, and staffing without quote duplication",
		failures,
	)

	var expansion_source := snapshot.get("campus_expansion", {}) as Dictionary
	var expansion_compact := office.call(
		"_compact_campus_expansion_diagnostic",
		expansion_source,
	) as Dictionary
	var compact_portfolio_bytes := _json_bytes(portfolio_compact)
	var compact_expansion_bytes := _json_bytes(expansion_compact)
	_check(
		_json_bytes(expansion_source) > 8_000
		and compact_expansion_bytes < 4_000
		and not expansion_compact.has("history")
		and not expansion_compact.has("sockets"),
		"North Meadow diagnostics should preserve operational authority without hidden quote history",
		failures,
	)

	var facility_source := snapshot.get("facility_catalog", []) as Array
	var facility_compact := office.call(
		"_compact_facility_catalog_diagnostic",
		facility_source,
	) as Array
	var raw_facility_bytes := _json_bytes(facility_source)
	var compact_facility_bytes := _json_bytes(facility_compact)
	var locked_facility: Dictionary = {}
	var available_facility: Dictionary = {}
	for facility_value: Variant in facility_compact:
		var facility := facility_value as Dictionary
		if bool(facility.get("unlocked", false)) and available_facility.is_empty():
			available_facility = facility
		elif not bool(facility.get("unlocked", false)) and locked_facility.is_empty():
			locked_facility = facility
	_check(
		raw_facility_bytes > 45_000
		and compact_facility_bytes < 7_000
		and facility_compact.size() == 13
		and not available_facility.is_empty()
		and available_facility.has("cost_cents")
		and available_facility.has("daily_maintenance_cents")
		and available_facility.has("benefits")
		and available_facility.has("tradeoffs")
		and not available_facility.has("current_automation_compliance_exposure_millipoints")
		and not locked_facility.has("benefits")
		and not locked_facility.has("tradeoffs"),
		"Capital diagnostics should preserve every actionable facility row without the recursive effect matrix",
		failures,
	)

	var journey_source := _inactive_egg_journey_fixture()
	var journey_compact := office.call(
		"_compact_egg_journey_diagnostic",
		journey_source,
	) as Dictionary
	var raw_journey_bytes := _json_bytes(journey_source)
	var compact_journey_bytes := _json_bytes(journey_compact)
	var compact_arbitration := journey_compact.get("settlement_arbitration", {}) as Dictionary
	_check(
		raw_journey_bytes > 3_000
		and compact_journey_bytes < 2_000
		and (compact_arbitration.get("attention", {}) as Dictionary).get("primary_id", "") == "flockwatch",
		"inactive egg feedback should retain its blocker once without repeating dormant pool internals",
		failures,
	)
	var active_journey := journey_source.duplicate(true)
	(active_journey.get("focused_receipt", {}) as Dictionary)["visible"] = true
	active_journey["active_receipt_marker"] = "complete live receipt retained"
	var active_journey_compact := office.call(
		"_compact_egg_journey_diagnostic",
		active_journey,
	) as Dictionary
	_check(
		active_journey_compact.get("active_receipt_marker", "") == "complete live receipt retained"
		and _json_bytes(active_journey_compact) == _json_bytes(active_journey),
		"active egg feedback should retain its complete receipt and placement authority",
		failures,
	)

	var combined_bytes := _json_bytes({
		"contract_board": contract_visible,
		"operations": operations_compact,
		"flock_care": care_compact,
		"capital_plan": capital_compact,
		"work_progress": work_progress_compact,
		"probation_safeguards": safeguards_compact,
		"interaction_safety": interaction_safety_compact,
		"campus_portfolio": portfolio_compact,
		"campus_expansion": expansion_compact,
		"facility_catalog": facility_compact,
		"egg_journey": journey_compact,
	})
	_check(
		combined_bytes < 48_000,
		"all compact heavy projections should leave room inside the 64 KiB complete-state ceiling",
		failures,
	)

	contract_source.clear()
	contract_hidden.clear()
	contract_visible.clear()
	selected_terms.clear()
	operations_source.clear()
	operations_compact.clear()
	operations_held.clear()
	care_source.clear()
	care_compact.clear()
	capital_source.clear()
	capital_compact.clear()
	work_progress_source.clear()
	work_progress_compact.clear()
	live_work_progress.clear()
	live_work_progress_compact.clear()
	safeguards_source.clear()
	safeguards_compact.clear()
	interaction_safety_source.clear()
	interaction_safety_compact.clear()
	live_interaction_safety.clear()
	live_interaction_safety_compact.clear()
	portfolio_source.clear()
	portfolio_compact.clear()
	expansion_source.clear()
	expansion_compact.clear()
	facility_source.clear()
	facility_compact.clear()
	journey_source.clear()
	journey_compact.clear()
	active_journey.clear()
	active_journey_compact.clear()
	snapshot.clear()
	var detached_clock := office.get("_clock") as SimulationClock
	if detached_clock != null and not detached_clock.is_inside_tree():
		detached_clock.free()
	office.free()
	simulation = null
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("WEB_DIAGNOSTIC_COMPACTION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print(
		"WEB_DIAGNOSTIC_COMPACTION_TEST_PASSED raw_contract=%d hidden_contract=%d visible_contract=%d operations=%d/%d care=%d/%d capital=%d/%d portfolio=%d expansion=%d facility=%d/%d egg_journey=%d/%d combined=%d"
		% [
			raw_contract_bytes,
			hidden_contract_bytes,
			visible_contract_bytes,
			raw_operations_bytes,
			compact_operations_bytes,
			raw_care_bytes,
			compact_care_bytes,
			raw_capital_bytes,
			compact_capital_bytes,
			compact_portfolio_bytes,
			compact_expansion_bytes,
			raw_facility_bytes,
			compact_facility_bytes,
			raw_journey_bytes,
			compact_journey_bytes,
			combined_bytes,
		]
	)
	quit(0)


func _heavy_projection_fixture(failures: Array[String]) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(28_090_814, 4)
	simulation.day = 14
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 1_000_000
	simulation.market_contracts_succeeded_total = 1
	_check(
		bool(simulation.purchase_campus_parcel(&"north_meadow").get("accepted", false)),
		"fixture should file North Meadow",
		failures,
	)
	for service_id: StringName in [&"circulation", &"power", &"cold_chain"]:
		_check(
			bool(simulation.commission_campus_service(service_id).get("accepted", false)),
			"fixture should commission %s" % String(service_id),
			failures,
		)
	_check(
		bool(simulation.place_campus_module(&"egg_routing_pod", &"meadow_west").get("accepted", false)),
		"fixture should place the routing pod",
		failures,
	)
	var day_receipt := simulation._campus_portfolio.begin_day(
		simulation.day,
		simulation._campus_portfolio_context(),
	)
	_check(bool(day_receipt.get("accepted", false)), "fixture should reconcile the portfolio day", failures)
	_check(
		bool(simulation.purchase_campus_portfolio_deed(&"orchard_row").get("accepted", false)),
		"fixture should file Orchard Row",
		failures,
	)
	return simulation


func _json_bytes(value: Variant) -> int:
	return JSON.stringify(value).to_utf8_buffer().size()


func _capital_plan_fixture(snapshot: Dictionary) -> Dictionary:
	var facility_catalog := snapshot.get("facility_catalog", []) as Array
	var facility := (
		(facility_catalog[0] as Dictionary).duplicate(true)
		if not facility_catalog.is_empty() else
		{}
	)
	var receipt := {
		"accepted": true,
		"action_id": &"purchase_facility",
		"facility_id": facility.get("id", &"fixture_facility"),
		"facility_name": facility.get("name", "Fixture Facility"),
		"purchased_level": 1,
		"level_name": "Level one",
		"max_level": 3,
		"cost_cents": 12_500,
		"fund_before_cents": 50_000,
		"fund_after_cents": 37_500,
		"protected_reserve_before_cents": 4_000,
		"protected_reserve_after_cents": 4_500,
		"spendable_before_cents": 46_000,
		"spendable_after_cents": 33_000,
		"upkeep_before_cents": 800,
		"upkeep_after_cents": 950,
		"upkeep_delta_cents": 150,
		"effect": "A deliberately descriptive commissioning consequence retained in the latest receipt.",
	}
	var history: Array[Dictionary] = []
	for day: int in range(1, 13):
		var history_receipt := receipt.duplicate(true)
		history_receipt["day"] = day
		history_receipt["facility_snapshot"] = facility.duplicate(true)
		history.append(history_receipt)
	receipt["day"] = 12
	return {
		"has_pinned_plan": true,
		"pinned_capital_plan_id": facility.get("id", &"fixture_facility"),
		"facility": facility,
		"last_facility_purchase_receipt": receipt,
		"commissioning_history": history,
	}


func _dormant_work_progress_fixture() -> Dictionary:
	var desks: Array[Dictionary] = []
	for worker_id: int in range(6):
		desks.append({
			"affordance_animated": false,
			"affordance_shape": "corner_brackets",
			"affordance_visible": false,
			"animated": false,
			"claim_id": -1,
			"desk_index": worker_id,
			"filled_pips": 0,
			"hovered": false,
			"interactive": false,
			"lane": "auto",
			"minutes_until_deadline": 9999,
			"overdue": false,
			"pip_count": 5,
			"progress": 0.0,
			"rework": false,
			"selected": false,
			"shape": "hidden",
			"status": "hidden",
			"visible": false,
			"worker_id": worker_id,
			"worker_name": "Fixture Hen %d" % worker_id,
		})
	return {
		"deadline_risk_count": 0,
		"desks": desks,
		"hovered_count": 0,
		"paused_count": 0,
		"pip_count_per_rail": 5,
		"pooled_affordance_count": 6,
		"pooled_rail_count": 6,
		"reduced_motion": false,
		"selected_count": 0,
		"visible_count": 0,
	}


func _probation_safeguards_fixture() -> Dictionary:
	var criteria: Array[Dictionary] = []
	for index: int in range(5):
		criteria.append({
			"id": "criterion_%d" % index,
			"label": "AUTHORED SAFEGUARD %d" % index,
			"metric": "metric_%d" % index,
			"comparison": "minimum",
			"target": 50 + index,
			"unit": "points",
			"current_value": 40,
			"projected_value": 45,
			"current_pass": false,
			"pass": false,
			"status": "at_risk",
			"distance_to_pass": 10 + index,
			"current_signed_gap": -10,
			"signed_gap": -5,
			"distance_basis_points": 2000,
			"at_risk": true,
			"recoverable": true,
			"value_source": "current",
		})
	return {
		"visible": true,
		"all_pass": false,
		"at_risk_count": 5,
		"completed_shifts": 2,
		"criteria_count": 5,
		"is_final": false,
		"pass_count": 0,
		"required_shifts": 5,
		"criteria": criteria,
		"largest_recoverable_blocker": criteria[0].duplicate(true),
		"challenge_contract": {
			"id": "standard_filing",
			"label": "STANDARD FILING",
			"short_label": "STANDARD",
			"difficulty": "standard",
			"difficulty_label": "STANDARD",
			"description": "A deliberately verbose authored challenge description repeated elsewhere.",
			"route_guidance": "A deliberately verbose route guide repeated elsewhere in the state.",
			"criteria": criteria.duplicate(true),
		},
	}


func _dormant_interaction_safety_fixture() -> Dictionary:
	return {
		"confirmation_backdrop": {
			"alpha": 0.58,
			"blocks_pointer": true,
			"flockwatch_page": "operations",
			"surface": "",
			"visible": false,
		},
		"routing": {
			"claim_confirmation_accessible_text": "",
			"claim_confirmation_cancel_label": "KEEP CURRENT PATH",
			"claim_confirmation_claim_id": -1,
			"claim_confirmation_confirm_label": "FILE PATH",
			"claim_confirmation_focus": "",
			"claim_confirmation_path_id": "",
			"claim_confirmation_skin": "flockwatch_compact",
			"claim_confirmation_title": "FILE AN IRREVERSIBLE CLAIMANT PATH?",
			"claim_confirmation_visible": false,
			"claim_confirmation_worker_id": -1,
			"route_undo_current_lane": "",
			"route_undo_previous_lane": "",
			"route_undo_visible": false,
			"route_undo_worker_id": -1,
		},
		"staffing": {
			"manager_candidate_id": "",
			"manager_candidate_name": "",
			"manager_recruit_confirmation_accessible_text": "",
			"manager_recruit_confirmation_cancel_label": "KEEP",
			"manager_recruit_confirmation_confirm_label": "FILE",
			"manager_recruit_confirmation_focus": "",
			"manager_recruit_confirmation_skin": "flockwatch_compact",
			"manager_recruit_confirmation_title": "FILE A MANAGEMENT SUCCESSION?",
			"manager_recruit_confirmation_visible": false,
			"manager_recruit_cost_cents": 0,
			"manager_replaces_name": "",
			"release_confirmation_accessible_text": "",
			"release_confirmation_cancel_label": "KEEP",
			"release_confirmation_confirm_label": "FILE",
			"release_confirmation_focus": "",
			"release_confirmation_skin": "flockwatch_compact",
			"release_confirmation_title": "RELEASE A HEN?",
			"release_confirmation_visible": false,
			"release_cost_cents": 0,
			"release_worker_id": -1,
			"release_worker_name": "",
		},
	}


func _inactive_egg_journey_fixture() -> Dictionary:
	var arbitration := {
		"active_batch_count": 0,
		"deferred_batch_count": 0,
		"visible_batch_count": 0,
		"released_batch_count": 0,
		"released_total": 0,
		"suppressed_total": 0,
		"release_serial": 0,
		"release_cue_count": 0,
		"max_defer_seconds": 9.0,
		"route_handoff_timeout_seconds": 2.4,
		"receipt_surfaces": [
			"feed_fund_counter", "flockwatch_inventory_ledger", "priority_peck_meter",
			"workstation_acknowledgment", "selected_hen_last_egg", "shift_record",
		],
		"attention": {
			"active": true,
			"primary_id": "flockwatch",
			"accessible_text": "Flockwatch is open for management review.",
			"blockers": [{
				"id": "flockwatch",
				"priority": "action",
				"accessible_text": "Flockwatch is open for management review.",
			}],
		},
		"last_release": {},
		"last_route_handoff": {},
		"last_suppressed": [],
		"route_handoff": {},
	}
	var batch_pool := {
		"active_batch_count": 0,
		"visible_batch_count": 0,
		"deferred_batch_count": 0,
		"pooled_chip_count": 8,
		"batches": [],
		"arbitration": arbitration.duplicate(true),
		"reduced_motion": false,
	}
	return {
		"receipts": [],
		"focused_receipt": {
			"visible": false,
			"stage": "",
			"copy": "Choose which tray this hen pulls next.",
			"accessible_text": "",
			"worker_id": -1,
			"claim_id": -1,
		},
		"world_acknowledgments": {
			"pooled_marker_count": 6,
			"active_count": 0,
			"capture_staged_count": 0,
			"acknowledgments": [],
			"reduced_motion": false,
		},
		"fund_credit_batches": batch_pool.merged({
			"total_eggs": 0,
			"total_value_cents": 0,
		}, true),
		"auxiliary_settlements": batch_pool.merged({
			"stock_eggs": 0,
			"stock_value_cents": 0,
			"pecks_restored": 0,
		}, true),
		"settlement_placement": {
			"card_count": 0,
			"visible_card_count": 0,
			"deferred_card_count": 0,
			"clamped_count": 0,
			"all_safe": true,
			"cards": [],
			"arbitration": arbitration.duplicate(true),
		},
		"settlement_arbitration": arbitration.duplicate(true),
		"settlement_destinations": {
			"pooled_count": 3,
			"active_count": 0,
			"merged_total": 0,
			"started_total": 0,
			"pulses": [],
			"reduced_motion": false,
		},
		"fund_debits": {
			"pooled_count": 3,
			"active_count": 0,
			"merged_total": 0,
			"started_total": 0,
			"recycled_total": 0,
			"bounded": true,
			"active_debits": [],
			"reduced_motion": false,
		},
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
