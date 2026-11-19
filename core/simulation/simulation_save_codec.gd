class_name SimulationSaveCodec
extends RefCounted

## Save export, schema migration, validation and restore for DepartmentSimulation.
## Holds no state of its own: every read and write goes through the owning
## DepartmentSimulation so behaviour is identical to the original in-class methods.

var sim: DepartmentSimulation


func _init(owner_node: DepartmentSimulation) -> void:
	sim = owner_node

func _neutral_campus_expansion_state() -> Dictionary:
	return {
		"version": DepartmentSimulation.CAMPUS_EXPANSION_SAVE_VERSION,
		"parcel_owned": false,
		"services": {
			"circulation": false,
			"power": false,
			"cold_chain": false,
		},
		"pod_owned": false,
		"pod_socket_id": "",
		"capital_spend_total_cents": 0,
		"next_receipt_id": 1,
		"last_receipt": {},
		"history": [],
	}


func _settled_peck_assist_delivery_snapshot() -> Array[int]:
	var claim_ids: Array[int] = []
	for claim_id in sim._settled_peck_assist_delivery_ids:
		claim_ids.append(int(claim_id))
	claim_ids.sort()
	return claim_ids


func _manager_action_save_data() -> Dictionary:
	var result := sim.last_manager_action.duplicate(true)
	for id_field in ["action_id", "manager_id", "choice_id", "replaced_manager_id"]:
		if result.has(id_field):
			result[id_field] = String(result[id_field])
	return result


func export_save_state() -> Dictionary:
	## This is the authoritative simulation checkpoint. It intentionally contains
	## only primitives so the campaign save remains portable to Web builds.
	# Tests and administrative tools may advance `day` directly. Normalize the
	# ledger to that authoritative day before serializing so stale daily counters
	# can never be emitted under a newer checkpoint date.
	sim._feed_procurement.begin_day(sim.day)
	sim._farmgate_dispatch.begin_day(sim.day)
	sim._campus_portfolio.begin_day(sim.day, sim._campus_portfolio_context())
	# Administrative/test fixtures may set permanent facility ownership directly.
	# Materialize every already-funded post before serializing that authority.
	sim._ensure_manager_posts_for_office_level()
	var saved_queues: Dictionary = {}
	for lane in DepartmentSimulation.CLAIM_LANES:
		var saved_lane: Array[Dictionary] = []
		for claim_value in (sim._claim_queues.get(lane, []) as Array):
			var claim := claim_value as ClaimState
			if claim != null:
				saved_lane.append(claim.to_save_data())
		saved_queues[String(lane)] = saved_lane
	var saved_rework: Array[Dictionary] = []
	for claim in sim._pending_rework:
		if claim != null:
			saved_rework.append(claim.to_save_data())
	var saved_workers: Array[Dictionary] = []
	for worker in sim.workers:
		saved_workers.append(worker.to_save_data())
	var saved_upgrades: Dictionary = {}
	for upgrade_id in DepartmentSimulation.UPGRADE_ORDER:
		saved_upgrades[String(upgrade_id)] = sim.upgrade_level(upgrade_id)
	var saved_lane_totals: Dictionary = {}
	var saved_lane_today: Dictionary = {}
	for lane in DepartmentSimulation.CLAIM_LANES:
		saved_lane_totals[String(lane)] = int(sim.lane_processed_totals.get(lane, 0))
		saved_lane_today[String(lane)] = int(sim.lane_processed_today.get(lane, 0))
	var saved_unlocks: Dictionary = {}
	for unlock_id in DepartmentSimulation.CAMPAIGN_UNLOCKS:
		saved_unlocks[String(unlock_id)] = sim.has_campaign_unlock(unlock_id)
	var saved_facilities: Dictionary = {}
	for facility_id in DepartmentSimulation.FACILITY_ORDER:
		saved_facilities[String(facility_id)] = sim.facility_level(facility_id)
	var saved_credit_counts: Dictionary = {}
	for style_id in DepartmentSimulation.CREDIT_STYLE_IDS:
		saved_credit_counts[String(style_id)] = maxi(
			0,
			int(sim.credit_choice_counts.get(style_id, 0)),
		)
	var saved_assisted_claim_ids: Array[int] = []
	for claim_id in sim._assisted_claim_ids:
		saved_assisted_claim_ids.append(int(claim_id))
	saved_assisted_claim_ids.sort()
	var saved_missed_claim_ids: Array[int] = []
	for claim_id in sim._missed_assist_claim_ids:
		saved_missed_claim_ids.append(int(claim_id))
	saved_missed_claim_ids.sort()
	var saved_assist_quality: Dictionary = {}
	for claim_id in sim._assist_quality_modifiers:
		saved_assist_quality[str(claim_id)] = float(sim._assist_quality_modifiers[claim_id])
	var saved_assist_chains: Dictionary = {}
	for claim_id in sim._assist_chain_by_claim_id:
		saved_assist_chains[str(claim_id)] = int(sim._assist_chain_by_claim_id[claim_id])
	var saved_routing_free_assist_ids: Array[int] = []
	for claim_id in sim._routing_momentum_free_assist_claim_ids:
		saved_routing_free_assist_ids.append(int(claim_id))
	saved_routing_free_assist_ids.sort()
	var saved_incident_bag: Array[String] = []
	for incident_id in sim._incident_bag:
		saved_incident_bag.append(String(incident_id))
	return {
		"state_version": DepartmentSimulation.SAVE_STATE_VERSION,
		"day": sim.day,
		"minute_of_day": sim.minute_of_day,
		"claims_processed": sim.claims_processed,
		"eggs_today": sim.eggs_today,
		"eggs_total": sim.eggs_total,
		"cracked_eggs": sim.cracked_eggs,
		"cracked_today": sim.cracked_today,
		"golden_eggs": sim.golden_eggs,
		"golden_today": sim.golden_today,
		"revenue_cents": sim.revenue_cents,
		"credited_today_cents": sim.credited_today_cents,
		"feed_cents_per_day": sim.feed_cents_per_day,
		"quota_target": sim.quota_target,
		"executive_confidence": sim.executive_confidence,
		"compliance": sim.compliance,
		"solidarity": sim.solidarity,
		"overtime_enabled": sim.overtime_enabled,
		"feed_party_used_today": sim.feed_party_used_today,
		"quality_streak": sim.quality_streak,
		"best_quality_streak": sim.best_quality_streak,
		"last_streak_bonus_cents": sim.last_streak_bonus_cents,
		"shift_phase": sim.shift_phase,
		"active_directive_id": String(sim.active_directive_id),
		"pending_decision": sim.pending_decision.duplicate(true),
		"incidents_resolved_today": sim.incidents_resolved_today,
		"incident_response_history": sim.incident_response_history.duplicate(true),
		"incident_pivot_mastery_receipts": sim.incident_pivot_mastery_receipts.duplicate(true),
		"upgrade_levels": saved_upgrades,
		"first_clutch_reinvestment": sim.first_clutch_reinvestment.duplicate(true),
		"active_playbook": sim.active_playbook.duplicate(true),
		"career_workshop": sim.career_workshop.to_save_data(),
		"flock_relationships": sim.flock_relationships.to_save_data(),
		"hero_case_history": sim.hero_case_history.duplicate(true),
		"rival_response_history": sim.rival_response_history.duplicate(true),
		"requisition_spend_today_cents": sim.requisition_spend_today_cents,
		"requisition_spend_total_cents": sim.requisition_spend_total_cents,
		"orientation_procurement_match_today_cents": sim.orientation_procurement_match_today_cents,
		"orientation_procurement_match_total_cents": sim.orientation_procurement_match_total_cents,
		"lane_processed_totals": saved_lane_totals,
		"lane_processed_today": saved_lane_today,
		"campaign_unlocks": saved_unlocks,
		"owned_facilities": saved_facilities,
		"manager_roster_version": DepartmentSimulation.MANAGER_ROSTER_VERSION,
		"manager_roster": sim.manager_roster.duplicate(true),
		"last_manager_action": _manager_action_save_data(),
		"management_reports_today": sim.management_reports_today,
		"management_reports_total": sim.management_reports_total,
		"management_visibility_today": sim.management_visibility_today,
		"internship_program_state": sim._internship_program.to_save_data(),
		"feed_procurement_state": sim._feed_procurement.to_save_data(),
		"harvest_credit_state": sim._harvest_credit.to_save_data(),
		"farmgate_dispatch_state": sim._farmgate_dispatch.to_save_data(),
		"farm_treasury_state": sim._farm_treasury.to_save_data(),
		"pinned_capital_plan_id": String(sim.pinned_capital_plan_id),
		"pinned_economic_watch_id": String(sim.pinned_economic_watch_id),
		"last_facility_purchase_receipt": sim.last_facility_purchase_receipt.duplicate(true),
		"facility_commissioning_history": sim.facility_commissioning_history.duplicate(true),
		"campus_expansion": sim.campus_expansion_state.duplicate(true),
		"campus_portfolio": sim._campus_portfolio.to_save_data(),
		"packing_carton_progress": sim.packing_carton_progress,
		"packing_cartons_today": sim.packing_cartons_today,
		"packing_cartons_total": sim.packing_cartons_total,
		"packing_value_bonus_today_cents": sim.packing_value_bonus_today_cents,
		"packing_value_bonus_total_cents": sim.packing_value_bonus_total_cents,
		"packing_carton_bonus_today_cents": sim.packing_carton_bonus_today_cents,
		"packing_carton_bonus_total_cents": sim.packing_carton_bonus_total_cents,
		"intake_rejections_today": sim.intake_rejections_today,
		"intake_rejections_total": sim.intake_rejections_total,
		"intake_missed_value_today_cents": sim.intake_missed_value_today_cents,
		"intake_missed_value_total_cents": sim.intake_missed_value_total_cents,
		"active_market_contract": sim.active_market_contract.duplicate(true),
		"market_contract_decline_receipt": sim.market_contract_decline_receipt.duplicate(true),
		"last_market_contract_result": sim.last_market_contract_result.duplicate(true),
		"market_contracts_signed_total": sim.market_contracts_signed_total,
		"market_contracts_succeeded_total": sim.market_contracts_succeeded_total,
		"market_contracts_breached_total": sim.market_contracts_breached_total,
		"market_clean_contract_streak": sim.market_clean_contract_streak,
		"best_market_clean_contract_streak": sim.best_market_clean_contract_streak,
		"market_contract_premium_today_cents": sim.market_contract_premium_today_cents,
		"market_contract_premium_total_cents": sim.market_contract_premium_total_cents,
		"market_contract_breach_today_cents": sim.market_contract_breach_today_cents,
		"market_contract_breach_total_cents": sim.market_contract_breach_total_cents,
		"market_pricing_outcomes": sim.market_pricing_outcomes.duplicate(true),
		"office_capacity": sim.office_capacity,
		"wage_arrears_cents": sim.wage_arrears_cents,
		"last_staffing_action": sim.last_staffing_action.duplicate(true),
		"worker_shift_stats": sim._worker_shift_stats.duplicate(true),
		"last_pecking_order": sim.last_pecking_order.duplicate(true),
		"last_pecking_order_day": sim.last_pecking_order_day,
		"last_credit_allocation": sim.last_credit_allocation.duplicate(true),
		"credit_choice_counts": saved_credit_counts,
		"golden_dossier_resolved": sim.golden_dossier_resolved,
		"golden_dossier_day": sim.golden_dossier_day,
		"flock_restructuring_resolved": sim.flock_restructuring_resolved,
		"flock_restructuring_day": sim.flock_restructuring_day,
		"flock_restructuring_record": sim.flock_restructuring_record.duplicate(true),
		"last_flock_petition": sim.last_flock_petition.duplicate(true),
		"flock_petition_history": sim.flock_petition_history.duplicate(true),
		"flock_relations_open_cases": sim.flock_relations_open_cases.duplicate(true),
		"flock_relations_resolutions_used_today": sim.flock_relations_resolutions_used_today,
		"flock_relations_resolved_total": sim.flock_relations_resolved_total,
		"flock_relations_denied_total": sim.flock_relations_denied_total,
		"flock_relations_settlement_spend_total_cents": sim.flock_relations_settlement_spend_total_cents,
		"last_flock_relations_resolution": sim.last_flock_relations_resolution.duplicate(true),
		"flock_relations_resolution_history": sim.flock_relations_resolution_history.duplicate(true),
		"next_flock_relations_case_id": sim.next_flock_relations_case_id,
		"active_flock_compact": sim.active_flock_compact.duplicate(true),
		"last_flock_compact_receipt": sim.last_flock_compact_receipt.duplicate(true),
		"work_to_rule_day": sim.work_to_rule_day,
		"last_work_to_rule_record": sim.last_work_to_rule_record.duplicate(true),
		"queued_work_to_rule_day": sim.queued_work_to_rule_day,
		"queued_work_to_rule_record": sim.queued_work_to_rule_record.duplicate(true),
		"peck_assists_used_today": sim.peck_assists_used_today,
		"peck_assist_interventions_today": sim.peck_assist_interventions_today,
		"peck_assist_refunds_today": sim.peck_assist_refunds_today,
		"peck_assist_streak": sim.peck_assist_streak,
		"best_peck_assist_streak": sim.best_peck_assist_streak,
		"last_peck_assist": sim.last_peck_assist.duplicate(true),
		"last_peck_assist_delivery": sim.last_peck_assist_delivery.duplicate(true),
		"priority_credit_today_cents": sim.priority_credit_today_cents,
		"priority_credit_total_cents": sim.priority_credit_total_cents,
		"routing_momentum_chain": sim.routing_momentum_chain,
		"best_routing_momentum_chain": sim.best_routing_momentum_chain,
		"routing_momentum_peck_recharge_bank": sim.routing_momentum_peck_recharge_bank,
		"routing_momentum_peck_recharges_used_today": sim.routing_momentum_peck_recharges_used_today,
		"routing_momentum_golden_charges": sim.routing_momentum_golden_charges,
		"routing_momentum_golden_target_claim_id": sim.routing_momentum_golden_target_claim_id,
		"routing_momentum_golden_target_worker_id": sim.routing_momentum_golden_target_worker_id,
		"last_routing_dispatch": sim.last_routing_dispatch.duplicate(true),
		"routing_momentum_free_assist_claim_ids": saved_routing_free_assist_ids,
		"assisted_claim_ids": saved_assisted_claim_ids,
		"missed_assist_claim_ids": saved_missed_claim_ids,
		"assist_quality_modifiers": saved_assist_quality,
		"assist_chain_by_claim_id": saved_assist_chains,
		"pending_peck_assist_deliveries": sim._pending_peck_assist_delivery_snapshot(),
		"settled_peck_assist_delivery_ids": _settled_peck_assist_delivery_snapshot(),
		"tick_count": sim._tick_count,
		"next_claim_id": sim._next_claim_id,
		"rework_total_created": sim._rework_total_created,
		"decision_serial": sim._decision_serial,
		"incident_slot": sim._incident_slot,
		"career_seed": sim._career_seed,
		"incident_rng_state": str(sim._incident_rng.state),
		"incident_bag": saved_incident_bag,
		"last_standard_incident_id": String(sim._last_standard_incident_id),
		"rng_state": str(sim._rng.state),
		"claim_rng_state": str(sim._claim_rng.state),
		"decision_modifiers": {
			"directive_work_multiplier": sim._directive_work_multiplier,
			"directive_fatigue_multiplier": sim._directive_fatigue_multiplier,
			"directive_stress_multiplier": sim._directive_stress_multiplier,
			"directive_morale_drain_multiplier": sim._directive_morale_drain_multiplier,
			"directive_crack_modifier": sim._directive_crack_modifier,
			"daily_feed_adjustment_cents": sim._daily_feed_adjustment_cents,
			"incident_work_multiplier": sim._incident_work_multiplier,
			"incident_strain_multiplier": sim._incident_strain_multiplier,
			"incident_crack_modifier": sim._incident_crack_modifier,
			"incident_golden_modifier": sim._incident_golden_modifier,
			"incident_feed_adjustment_cents": sim._incident_feed_adjustment_cents,
			"pending_quota_adjustment": sim._pending_quota_adjustment,
		},
		"claim_queues": saved_queues,
		"pending_rework": saved_rework,
		"workers": saved_workers,
	}


func restore_save_state(data: Dictionary) -> bool:
	## Rebuild reference data before mutating this simulation. A damaged checkpoint
	## therefore fails closed and leaves the current session playable.
	var migrated_data := _migrate_save_state(data)
	if migrated_data.is_empty():
		return false
	data = migrated_data
	var worker_values: Variant = data.get("workers", [])
	var queue_values: Variant = data.get("claim_queues", {})
	var rework_values: Variant = data.get("pending_rework", [])
	if not worker_values is Array or not queue_values is Dictionary or not rework_values is Array:
		return false
	var worker_data: Array = worker_values as Array
	if worker_data.size() != sim.workers.size():
		return false
	if not sim._is_integral_number(data.get("day", null)):
		return false
	var saved_day := int(data.get("day", 1))
	if saved_day < 1 or saved_day > 9999:
		return false
	var restored_internship_program = DepartmentSimulation.InternshipProgramStateScript.new()
	if not restored_internship_program.restore_save_data(
		data.get("internship_program_state", null),
		saved_day,
	):
		return false
	if not sim._is_integral_number(data.get("career_seed", null)):
		return false
	var restored_career_seed := int(data.get("career_seed", 0))
	if restored_career_seed < 1 or restored_career_seed > 2_000_000_000:
		return false
	var incident_rng_value: Variant = data.get("incident_rng_state", null)
	if typeof(incident_rng_value) != TYPE_STRING or not String(incident_rng_value).is_valid_int():
		return false
	var incident_bag_value: Variant = data.get("incident_bag", null)
	if not incident_bag_value is Array or (incident_bag_value as Array).size() > DepartmentSimulation.INCIDENT_ORDER.size() - 1:
		return false
	var restored_incident_bag: Array[StringName] = []
	var seen_incident_ids: Dictionary[StringName, bool] = {}
	for incident_value in incident_bag_value as Array:
		if typeof(incident_value) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return false
		var incident_id := StringName(String(incident_value))
		if incident_id not in DepartmentSimulation.INCIDENT_ORDER or seen_incident_ids.has(incident_id):
			return false
		seen_incident_ids[incident_id] = true
		restored_incident_bag.append(incident_id)
	var last_incident_value: Variant = data.get("last_standard_incident_id", null)
	if typeof(last_incident_value) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	var restored_last_standard_incident_id := StringName(String(last_incident_value))
	if (
		restored_last_standard_incident_id != &""
		and restored_last_standard_incident_id not in DepartmentSimulation.INCIDENT_ORDER
	):
		return false
	if (
		(restored_last_standard_incident_id == &"" and not restored_incident_bag.is_empty())
		or seen_incident_ids.has(restored_last_standard_incident_id)
	):
		return false
	var response_history_validation := sim._validated_incident_response_history(
		data.get("incident_response_history", null),
		saved_day,
	)
	if not bool(response_history_validation.get("valid", false)):
		return false
	var restored_incident_response_history: Array[Dictionary] = []
	for response_value in response_history_validation.get("history", []):
		restored_incident_response_history.append((response_value as Dictionary).duplicate(true))
	var pivot_mastery_validation := _validated_incident_pivot_mastery_receipts(
		data.get("incident_pivot_mastery_receipts", null),
		saved_day,
	)
	if not bool(pivot_mastery_validation.get("valid", false)):
		return false
	var restored_pivot_mastery_receipts: Array[Dictionary] = []
	var restored_pivot_pairs: Dictionary[StringName, bool] = {}
	for receipt_value in pivot_mastery_validation.get("receipts", []):
		var receipt := (receipt_value as Dictionary).duplicate(true)
		restored_pivot_mastery_receipts.append(receipt)
		restored_pivot_pairs[StringName(receipt.get("pair_id", &""))] = true
	for derived_receipt: Dictionary in _incident_pivot_receipts_from_history(
		restored_incident_response_history
	):
		if not restored_pivot_pairs.has(StringName(derived_receipt.get("pair_id", &""))):
			return false
	if not sim._is_integral_number(data.get("shift_phase", null)):
		return false
	var saved_shift_phase := int(data.get("shift_phase", -1))
	if saved_shift_phase not in [
		DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE,
		DepartmentSimulation.ShiftPhase.RUNNING,
		DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT,
		DepartmentSimulation.ShiftPhase.REVIEW,
	]:
		return false
	var restored_upgrade_levels := _validated_upgrade_levels(data.get("upgrade_levels", null))
	if restored_upgrade_levels.size() != DepartmentSimulation.UPGRADE_ORDER.size():
		return false
	for ledger_field in [
		"requisition_spend_today_cents",
		"requisition_spend_total_cents",
		"orientation_procurement_match_today_cents",
		"orientation_procurement_match_total_cents",
	]:
		if not sim._is_integral_number(data.get(ledger_field, null)):
			return false
	var restored_requisition_spend_today := int(data.get("requisition_spend_today_cents", -1))
	var restored_requisition_spend_total := int(data.get("requisition_spend_total_cents", -1))
	var restored_orientation_match_today := int(data.get(
		"orientation_procurement_match_today_cents",
		-1,
	))
	var restored_orientation_match_total := int(data.get(
		"orientation_procurement_match_total_cents",
		-1,
	))
	if (
		restored_requisition_spend_today < 0
		or restored_requisition_spend_today > restored_requisition_spend_total
		or restored_requisition_spend_total > 2_000_000_000
		or restored_orientation_match_today < 0
		or restored_orientation_match_today > restored_orientation_match_total
		or restored_orientation_match_total > DepartmentSimulation.ORIENTATION_PROCUREMENT_MATCH_CAP_CENTS
	):
		return false
	var validated_reinvestment := _validated_first_clutch_reinvestment(
		data.get("first_clutch_reinvestment", null),
		saved_day,
		restored_upgrade_levels,
	)
	if not bool(validated_reinvestment.get("valid", false)):
		return false
	var restored_first_clutch_reinvestment := (
		validated_reinvestment.get("record", {}) as Dictionary
	)
	var active_playbook_validation := _validated_active_playbook(
		data.get("active_playbook", null),
		saved_day,
		worker_data.size(),
	)
	if not bool(active_playbook_validation.get("valid", false)):
		return false
	var restored_active_playbook := (
		active_playbook_validation.get("record", {}) as Dictionary
	)
	var hero_history_validation := _validated_hero_case_history(
		data.get("hero_case_history", []),
		saved_day,
		worker_data.size(),
	)
	if not bool(hero_history_validation.get("valid", false)):
		return false
	var restored_hero_case_history := hero_history_validation.get("history", []) as Array[Dictionary]
	var rival_history_validation := _validated_rival_response_history(
		data.get("rival_response_history", []),
		saved_day,
	)
	if not bool(rival_history_validation.get("valid", false)):
		return false
	var restored_rival_response_history := rival_history_validation.get("history", []) as Array[Dictionary]
	var reinvestment_match_used := int(
		restored_first_clutch_reinvestment.get("procurement_match_used_cents", 0)
	)
	if (
		restored_orientation_match_total != reinvestment_match_used
		or (
			restored_orientation_match_today > 0
			and int(restored_first_clutch_reinvestment.get("resolved_day", 0)) != saved_day
		)
		or restored_requisition_spend_total
		!= _cumulative_upgrade_spend_cents(restored_upgrade_levels) - reinvestment_match_used
	):
		return false
	if not sim._is_integral_number(data.get("office_capacity", null)):
		return false
	var saved_office_capacity := int(data.get("office_capacity", -1))
	if (
		saved_office_capacity < DepartmentSimulation.MINIMUM_STAFF_COUNT
		or saved_office_capacity > DepartmentSimulation.MAXIMUM_STAFF_CAPACITY
	):
		return false
	if not sim._is_integral_number(data.get("wage_arrears_cents", null)):
		return false
	var saved_wage_arrears := int(data.get("wage_arrears_cents", -1))
	if saved_wage_arrears < 0 or saved_wage_arrears > 2_000_000_000:
		return false
	var restored_owned_facilities := _validated_owned_facilities(
		data.get("owned_facilities", null),
	)
	if restored_owned_facilities.size() != DepartmentSimulation.FACILITY_ORDER.size():
		return false
	var restored_manager_roster := _validated_manager_roster(
		data.get("manager_roster", null),
		int(restored_owned_facilities.get(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID, 0)),
	)
	if restored_manager_roster.is_empty():
		return false
	for management_field in [
		"management_reports_today", "management_reports_total", "management_visibility_today",
	]:
		if not sim._is_integral_number(data.get(management_field, null)):
			return false
	var restored_reports_today := int(data.get("management_reports_today", -1))
	var restored_reports_total := int(data.get("management_reports_total", -1))
	var restored_visibility_today := int(data.get("management_visibility_today", -1))
	if (
		restored_reports_today < 0 or restored_reports_today > restored_manager_roster.size()
		or restored_reports_total < restored_reports_today or restored_reports_total > 2_000_000_000
		or restored_visibility_today < 0 or restored_visibility_today > restored_manager_roster.size()
	):
		return false
	var restored_last_manager_action_value: Variant = data.get("last_manager_action", {})
	if not restored_last_manager_action_value is Dictionary:
		return false
	var restored_last_manager_action := (restored_last_manager_action_value as Dictionary).duplicate(true)
	if not restored_last_manager_action.is_empty():
		for id_field in ["action_id", "manager_id", "choice_id", "replaced_manager_id"]:
			if restored_last_manager_action.has(id_field):
				restored_last_manager_action[id_field] = StringName(String(restored_last_manager_action[id_field]))
		restored_last_manager_action["day"] = int(restored_last_manager_action.get("day", 0))
		for money_field in ["cost_cents", "fund_before_cents", "fund_after_cents"]:
			if restored_last_manager_action.has(money_field):
				restored_last_manager_action[money_field] = int(restored_last_manager_action[money_field])
	var saved_unlock_values: Variant = data.get("campaign_unlocks", {})
	if not saved_unlock_values is Dictionary:
		return false
	for facility_id in DepartmentSimulation.FACILITY_ORDER:
		var restored_facility_level := int(restored_owned_facilities.get(facility_id, 0))
		if restored_facility_level <= 0:
			continue
		var definition := DepartmentSimulation.FACILITY_DEFINITIONS[facility_id] as Dictionary
		if saved_day < sim._facility_unlock_day_for_level(definition, restored_facility_level):
			return false
		var unlock_id := StringName(definition.get("unlock_id", &""))
		if unlock_id != &"":
			var saved_unlocks := saved_unlock_values as Dictionary
			var unlock_value: Variant = saved_unlocks.get(
				String(unlock_id),
				saved_unlocks.get(unlock_id, null),
			)
			if typeof(unlock_value) != TYPE_BOOL or not bool(unlock_value):
				return false
	var restored_service_coop_level := int(
		restored_owned_facilities.get(DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID, 0)
	)
	if restored_service_coop_level > 0:
		var required_coop_capacity := sim._service_coop_requirement(
			DepartmentSimulation.SERVICE_COOP_LEVEL_CLAIM_CAPACITY_REQUIREMENTS,
			restored_service_coop_level,
		)
		var required_coop_office_capacity := sim._service_coop_requirement(
			DepartmentSimulation.SERVICE_COOP_LEVEL_ACTIVE_STAFF_REQUIREMENTS,
			restored_service_coop_level,
		)
		# Standing and active headcount may fall after a legitimate purchase, so
		# neither may demote or invalidate ownership. Records and authorized desk
		# capacity never shrink and therefore remain strict purchase evidence.
		if (
			sim._claim_capacity_for_facilities(restored_owned_facilities) < required_coop_capacity
			or saved_office_capacity < required_coop_office_capacity
		):
			return false
	var restored_negotiation_room_level := int(
		restored_owned_facilities.get(DepartmentSimulation.FARM_MUTUAL_NEGOTIATION_ROOM_ID, 0)
	)
	# Standing may fall after a legitimate room purchase, but its physical Service
	# Coop dependency cannot disappear from a structurally valid checkpoint.
	if (
		restored_negotiation_room_level > 0
		and restored_service_coop_level < DepartmentSimulation.NEGOTIATION_ROOM_REQUIRED_SERVICE_COOP_LEVEL
	):
		return false
	var restored_wellness_level := int(
		restored_owned_facilities.get(DepartmentSimulation.WELLNESS_NEST_ID, 0)
	)
	if (
		restored_wellness_level > 0
		and saved_office_capacity < sim._facility_tier_requirement(
			DepartmentSimulation.WELLNESS_NEST_OFFICE_CAPACITY_REQUIREMENTS,
			restored_wellness_level,
		)
	):
		return false
	var restored_training_level := int(
		restored_owned_facilities.get(DepartmentSimulation.TRAINING_ROOST_ID, 0)
	)
	# Active headcount and career qualification may fall after a legitimate
	# purchase. Authorized desk capacity and the matching Wellness tier cannot.
	if (
		restored_training_level > restored_wellness_level
		or (
			restored_training_level > 0
			and saved_office_capacity < sim._facility_tier_requirement(
				DepartmentSimulation.TRAINING_ROOST_OFFICE_CAPACITY_REQUIREMENTS,
				restored_training_level,
			)
		)
	):
		return false
	var restored_rooster_operations_level := int(
		restored_owned_facilities.get(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID, 0)
	)
	if (
		restored_rooster_operations_level > 0
		and saved_office_capacity < sim._facility_tier_requirement(
			DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_CAPACITY_REQUIREMENTS,
			restored_rooster_operations_level,
		)
	):
		return false
	var restored_it_coop_level := int(
		restored_owned_facilities.get(DepartmentSimulation.IT_COOP_ID, 0)
	)
	var restored_records_annex_level := int(
		restored_owned_facilities.get(DepartmentSimulation.RECORDS_ANNEX_ID, 0)
	)
	# Headcount may fall after a legitimate purchase. Authorized capacity and
	# permanent Records/Rooster dependencies cannot disappear from a valid save.
	if (
		restored_it_coop_level > restored_records_annex_level
		or restored_it_coop_level > restored_rooster_operations_level
		or (
			restored_it_coop_level > 0
			and saved_office_capacity < sim._facility_tier_requirement(
				DepartmentSimulation.IT_COOP_OFFICE_CAPACITY_REQUIREMENTS,
				restored_it_coop_level,
			)
		)
	):
		return false
	var restored_flock_relations_level := int(
		restored_owned_facilities.get(DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID, 0)
	)
	# Headcount may fall after commissioning. Authorized capacity and the matching
	# permanent Rooster Operations / Wellness tiers remain strict purchase evidence.
	if (
		restored_flock_relations_level > restored_rooster_operations_level
		or restored_flock_relations_level > restored_wellness_level
		or (
			restored_flock_relations_level > 0
			and saved_office_capacity < sim._facility_tier_requirement(
				DepartmentSimulation.FLOCK_RELATIONS_OFFICE_CAPACITY_REQUIREMENTS,
				restored_flock_relations_level,
			)
		)
	):
		return false
	var restored_feed_procurement_level := int(
		restored_owned_facilities.get(DepartmentSimulation.FEED_PROCUREMENT_COOP_ID, 0)
	)
	# Active headcount may fall after commissioning; authorized desks and the
	# tier's physical bin capacity remain permanent purchase evidence.
	if (
		restored_feed_procurement_level > 0
		and saved_office_capacity < sim._facility_tier_requirement(
			DepartmentSimulation.FEED_PROCUREMENT_OFFICE_CAPACITY_REQUIREMENTS,
			restored_feed_procurement_level,
		)
	):
		return false
	var restored_feed_base_capacity := sim._facility_level_schedule_value(
		DepartmentSimulation.FEED_PROCUREMENT_CAPACITY_SCOOPS,
		restored_feed_procurement_level,
		0,
	)
	var restored_farmer_relations_gallery_level := int(
		restored_owned_facilities.get(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID, 0)
	)
	var restored_packing_annex_level := int(
		restored_owned_facilities.get(DepartmentSimulation.PACKING_ANNEX_ID, 0)
	)
	# Active staffing may fall after commissioning, but the permanent matching
	# Packing Annex and authorized desk capacity are structural purchase evidence.
	if (
		restored_farmer_relations_gallery_level > restored_packing_annex_level
		or (
			restored_farmer_relations_gallery_level > 0
			and saved_office_capacity < sim._facility_tier_requirement(
				DepartmentSimulation.FARMER_RELATIONS_GALLERY_OFFICE_CAPACITY_REQUIREMENTS,
				restored_farmer_relations_gallery_level,
			)
		)
	):
		return false
	var restored_harvest_credit = DepartmentSimulation.HarvestCreditStateScript.new()
	if not restored_harvest_credit.restore_save_data(
		data.get("harvest_credit_state", null),
		saved_day,
		restored_farmer_relations_gallery_level,
	):
		return false
	var restored_farm_treasury = DepartmentSimulation.FarmTreasuryStateScript.new()
	if not restored_farm_treasury.restore_save_data(
		data.get("farm_treasury_state", null)
	):
		return false
	# A checkpoint may be taken during the current shift, but its treasury may
	# never claim to have closed that shift—or a future one—already.
	if restored_farm_treasury.last_closed_day > maxi(0, saved_day - 1):
		return false
	var validated_campus_expansion := _validated_campus_expansion_state(
		data.get("campus_expansion", null),
		saved_day,
	)
	if not bool(validated_campus_expansion.get("valid", false)):
		return false
	var restored_campus_expansion := (
		validated_campus_expansion.get("state", {}) as Dictionary
	).duplicate(true)
	var portfolio_restore_worker_ids: Array[int] = []
	var portfolio_restore_worker_names: Dictionary = {}
	for worker_index in sim.workers.size():
		portfolio_restore_worker_ids.append(worker_index)
		portfolio_restore_worker_names[worker_index] = sim.workers[worker_index].display_name
	var restored_portfolio_context := sim._campus_portfolio_context(
		saved_shift_phase == DepartmentSimulation.ShiftPhase.REVIEW,
		portfolio_restore_worker_ids,
		portfolio_restore_worker_names,
		restored_campus_expansion,
		saved_day,
	)
	var restored_campus_portfolio = DepartmentSimulation.CampusPortfolioStateScript.new(saved_day)
	if not restored_campus_portfolio.restore_save_data(
		data.get("campus_portfolio", null),
		saved_day,
		portfolio_restore_worker_ids,
		restored_portfolio_context,
	):
		return false
	var restored_feed_capacity := (
		restored_feed_base_capacity
		+ restored_campus_portfolio.feed_capacity_bonus_scoops(restored_portfolio_context)
	)
	var restored_feed_procurement = DepartmentSimulation.FeedProcurementStateScript.new()
	if not restored_feed_procurement.restore_save_data(
		data.get("feed_procurement_state", null),
		saved_day,
		restored_feed_capacity,
		restored_feed_procurement_level,
	) or not _is_valid_feed_procurement_quote_state(restored_feed_procurement):
		return false
	var restored_farmgate_dispatch_level := int(
		restored_owned_facilities.get(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID, 0)
	)
	var restored_campus_history := (
		restored_campus_expansion.get("history", []) as Array
	)
	if not restored_campus_history.is_empty():
		var campus_access_receipt := restored_campus_history[0] as Dictionary
		if (
			StringName(campus_access_receipt.get("access_gate_id", &"")) == &"farmgate_dispatch"
			and restored_farmgate_dispatch_level
			< int(campus_access_receipt.get("access_farmgate_level", 0))
		):
			return false
	# Staffing and standing can change after a permanent tier is commissioned.
	# Authorized desk capacity and the matching physical Packing/Gallery tiers are
	# permanent structural evidence and therefore remain strict.
	if (
		restored_farmgate_dispatch_level > restored_packing_annex_level
		or restored_farmgate_dispatch_level > restored_farmer_relations_gallery_level
		or (
			restored_farmgate_dispatch_level > 0
			and saved_office_capacity < sim._facility_tier_requirement(
				DepartmentSimulation.FARMGATE_DISPATCH_OFFICE_CAPACITY_REQUIREMENTS,
				restored_farmgate_dispatch_level,
			)
		)
	):
		return false
	var restored_farmgate_dispatch = DepartmentSimulation.FarmgateDispatchStateScript.new()
	if not restored_farmgate_dispatch.restore_save_data(
		data.get("farmgate_dispatch_state", null),
		saved_day,
			sim._farmgate_storage_capacity_for_level_and_campus(
				restored_farmgate_dispatch_level,
				restored_campus_expansion,
				restored_campus_portfolio.farmgate_capacity_bonus_eggs(
					restored_portfolio_context
				),
			),
		restored_farmgate_dispatch_level,
	):
		return false
	var restored_active_farmgate := restored_farmgate_dispatch.active_mandate as Dictionary
	if not restored_active_farmgate.is_empty():
		var active_farmgate_level := int(restored_active_farmgate.get("facility_level", 0))
		var expected_farmgate_season := sim.market_season_for_day(saved_day)
		var expected_farmgate_season_id := StringName(expected_farmgate_season.get("id", &"spring_hatch_surge"))
		var active_farmgate_mandate_id := StringName(restored_active_farmgate.get("mandate_id", &""))
		if (
			StringName(restored_active_farmgate.get("season_id", &"")) != expected_farmgate_season_id
			or int(restored_active_farmgate.get("dispatch_limit", 0))
			!= sim._facility_level_schedule_value(
				DepartmentSimulation.FARMGATE_DISPATCH_DAILY_DISPATCH_EGGS,
				active_farmgate_level,
				0,
			)
			or (
				active_farmgate_mandate_id == DepartmentSimulation.FarmgateDispatchStateScript.COUNTY_AUCTION
				and int(restored_active_farmgate.get("price_basis_points", 0))
				!= sim._farmgate_auction_basis_points(expected_farmgate_season_id)
			)
		):
			return false
	var restored_last_farmgate_authorization := restored_farmgate_dispatch.last_authorization as Dictionary
	if not restored_last_farmgate_authorization.is_empty():
		var authorization_day := int(restored_last_farmgate_authorization.get("target_day", 0))
		var authorization_season := sim.market_season_for_day(authorization_day)
		var authorization_season_id := StringName(authorization_season.get("id", &"spring_hatch_surge"))
		if (
			StringName(restored_last_farmgate_authorization.get("season_id", &"")) != authorization_season_id
			or (
				StringName(restored_last_farmgate_authorization.get("mandate_id", &""))
				== DepartmentSimulation.FarmgateDispatchStateScript.COUNTY_AUCTION
				and int(restored_last_farmgate_authorization.get("price_basis_points", 0))
				!= sim._farmgate_auction_basis_points(authorization_season_id)
			)
		):
			return false
	for settlement_value in restored_farmgate_dispatch.history:
		var settlement := settlement_value as Dictionary
		var settlement_day := int(settlement.get("day", 0))
		var settlement_mandate_id := StringName(settlement.get("mandate_id", &""))
		var expected_settlement_season := sim.market_season_for_day(settlement_day)
		var expected_settlement_season_id := StringName(expected_settlement_season.get("id", &"spring_hatch_surge"))
		var saved_settlement_season_id := StringName(settlement.get("season_id", &""))
		if (
			int(settlement.get("facility_level", 0)) > restored_farmgate_dispatch_level
			or (
				settlement_mandate_id == DepartmentSimulation.FarmgateDispatchStateScript.FARMER_PICKUP
				and saved_settlement_season_id not in [&"baseline_neutral", expected_settlement_season_id]
			)
			or (
				settlement_mandate_id != DepartmentSimulation.FarmgateDispatchStateScript.FARMER_PICKUP
				and saved_settlement_season_id != expected_settlement_season_id
			)
			or (
				settlement_mandate_id == DepartmentSimulation.FarmgateDispatchStateScript.COUNTY_AUCTION
				and int(settlement.get("price_basis_points", 0))
				!= sim._farmgate_auction_basis_points(expected_settlement_season_id)
			)
		):
			return false
	var restored_capital_records := _validated_capital_records(
		data.get("pinned_capital_plan_id", null),
		data.get("last_facility_purchase_receipt", null),
		data.get("facility_commissioning_history", null),
		saved_day,
		restored_owned_facilities,
	)
	if not bool(restored_capital_records.get("valid", false)):
		return false
	var restored_economic_watch_value: Variant = data.get(
		"pinned_economic_watch_id",
		"auto",
	)
	if typeof(restored_economic_watch_value) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	var restored_economic_watch_id := StringName(String(restored_economic_watch_value))
	if restored_economic_watch_id not in DepartmentSimulation.ECONOMIC_WATCH_ORDER:
		return false
	var intake_fields := [
		"intake_rejections_today",
		"intake_rejections_total",
		"intake_missed_value_today_cents",
		"intake_missed_value_total_cents",
	]
	for intake_field in intake_fields:
		if not sim._is_integral_number(data.get(intake_field, null)):
			return false
	var restored_intake_rejections_today := int(data.get("intake_rejections_today", -1))
	var restored_intake_rejections_total := int(data.get("intake_rejections_total", -1))
	var restored_intake_missed_today := int(data.get("intake_missed_value_today_cents", -1))
	var restored_intake_missed_total := int(data.get("intake_missed_value_total_cents", -1))
	var minimum_claim_value_cents := int((DepartmentSimulation.CLAIM_LANE_DEFINITIONS[&"nest_damage"] as Dictionary)["base_value_cents"])
	var maximum_claim_value_cents := int((DepartmentSimulation.CLAIM_LANE_DEFINITIONS[&"appeals"] as Dictionary)["base_value_cents"])
	if (
		restored_intake_rejections_today < 0
		or restored_intake_rejections_today > restored_intake_rejections_total
		or restored_intake_rejections_total > 2_000_000_000
		or restored_intake_missed_today < restored_intake_rejections_today * minimum_claim_value_cents
		or restored_intake_missed_today > restored_intake_rejections_today * maximum_claim_value_cents
		or restored_intake_missed_today > restored_intake_missed_total
		or restored_intake_missed_total < restored_intake_rejections_total * minimum_claim_value_cents
		or restored_intake_missed_total > restored_intake_rejections_total * maximum_claim_value_cents
		or restored_intake_missed_total > 2_000_000_000
	):
		return false
	var market_ledger_fields := [
		"market_contracts_signed_total",
		"market_contracts_succeeded_total",
		"market_contracts_breached_total",
		"market_clean_contract_streak",
		"best_market_clean_contract_streak",
		"market_contract_premium_today_cents",
		"market_contract_premium_total_cents",
		"market_contract_breach_today_cents",
		"market_contract_breach_total_cents",
	]
	for market_field in market_ledger_fields:
		if not sim._is_integral_number(data.get(market_field, null)):
			return false
	var restored_contracts_signed := int(data.get("market_contracts_signed_total", -1))
	var restored_contracts_succeeded := int(data.get("market_contracts_succeeded_total", -1))
	var restored_contracts_breached := int(data.get("market_contracts_breached_total", -1))
	var restored_clean_contract_streak := int(data.get("market_clean_contract_streak", -1))
	var restored_best_clean_contract_streak := int(data.get("best_market_clean_contract_streak", -1))
	var restored_contract_premium_today := int(data.get("market_contract_premium_today_cents", -1))
	var restored_contract_premium_total := int(data.get("market_contract_premium_total_cents", -1))
	var restored_contract_breach_today := int(data.get("market_contract_breach_today_cents", -1))
	var restored_contract_breach_total := int(data.get("market_contract_breach_total_cents", -1))
	var restored_pricing_outcomes: Dictionary = {}
	var pricing_outcomes_value: Variant = data.get("market_pricing_outcomes", {})
	if not pricing_outcomes_value is Dictionary:
		return false
	var pricing_success_total := 0
	var pricing_breach_total := 0
	for outcome_key in DepartmentSimulation.MARKET_PRICING_OUTCOME_KEYS:
		var outcome_value: Variant = (pricing_outcomes_value as Dictionary).get(outcome_key, 0)
		if not sim._is_integral_number(outcome_value):
			return false
		var outcome_count := int(outcome_value)
		if outcome_count < 0 or outcome_count > 2_000_000_000:
			return false
		restored_pricing_outcomes[outcome_key] = outcome_count
		if outcome_key.ends_with("_success"):
			pricing_success_total += outcome_count
		else:
			pricing_breach_total += outcome_count
	if (
		restored_contracts_signed < 0 or restored_contracts_signed > 2_000_000_000
		or restored_contracts_succeeded < 0
		or restored_contracts_breached < 0
		or restored_contracts_succeeded + restored_contracts_breached > restored_contracts_signed
		or restored_clean_contract_streak < 0
		or restored_clean_contract_streak > restored_best_clean_contract_streak
		or restored_best_clean_contract_streak < 0
		or restored_best_clean_contract_streak > restored_contracts_succeeded
		or restored_contract_premium_today < 0
		or restored_contract_premium_today > restored_contract_premium_total
		or restored_contract_premium_total > 2_000_000_000
		or restored_contract_breach_today < 0
		or restored_contract_breach_today > restored_contract_breach_total
		or restored_contract_breach_total > 2_000_000_000
		or pricing_success_total > restored_contracts_succeeded
		or pricing_breach_total > restored_contracts_breached
	):
		return false
	if not restored_campus_history.is_empty():
		var campus_access_receipt := restored_campus_history[0] as Dictionary
		if StringName(campus_access_receipt.get("access_gate_id", &"")) == &"farm_mutual_standing":
			var access_standing := int(campus_access_receipt.get("access_standing_points", 0))
			# With authored +2/-1 standing, the smallest possible evidence history
			# for P points is ceil(P/2) successes plus one breach when P is odd.
			# Later settlements may lower standing, so compare against lifetime totals
			# rather than the current derived rank.
			var required_successes: int = ceili(
				float(access_standing) / float(DepartmentSimulation.MARKET_STANDING_SUCCESS_POINTS)
			)
			var required_breaches: int = (
				DepartmentSimulation.MARKET_STANDING_SUCCESS_POINTS * required_successes - access_standing
			)
			if (
				restored_contracts_succeeded < required_successes
				or restored_contracts_breached < required_breaches
			):
				return false
	var validated_active_contract := _validated_active_market_contract(
		data.get("active_market_contract", null),
		saved_day,
		int(data.get("shift_phase", -1)),
		int(data.get("minute_of_day", -1)),
		restored_service_coop_level,
		restored_negotiation_room_level,
	)
	var validated_last_contract := _validated_market_contract_result(
		data.get("last_market_contract_result", null),
		saved_day,
		restored_service_coop_level,
		restored_negotiation_room_level,
	)
	var validated_contract_decline := _validated_market_contract_decline_receipt(
		data.get("market_contract_decline_receipt", null),
		saved_day,
		int(data.get("shift_phase", -1)),
	)
	if (
		not bool(validated_active_contract.get("valid", false))
		or not bool(validated_last_contract.get("valid", false))
		or not bool(validated_contract_decline.get("valid", false))
	):
		return false
	var restored_active_contract := validated_active_contract.get("record", {}) as Dictionary
	var restored_last_contract := validated_last_contract.get("record", {}) as Dictionary
	var restored_contract_decline := validated_contract_decline.get("record", {}) as Dictionary
	if not restored_active_contract.is_empty() and not restored_contract_decline.is_empty():
		return false
	var settled_contract_total := restored_contracts_succeeded + restored_contracts_breached
	var restored_market_standing := maxi(
		0,
		DepartmentSimulation.MARKET_STANDING_SUCCESS_POINTS * restored_contracts_succeeded
		- DepartmentSimulation.MARKET_STANDING_BREACH_POINTS * restored_contracts_breached,
	)
	if (
		(settled_contract_total == 0 and not restored_last_contract.is_empty())
		or (settled_contract_total > 0 and restored_last_contract.is_empty())
		or (
			not restored_last_contract.is_empty()
			and bool(restored_last_contract.get("success", false))
			and restored_contracts_succeeded <= 0
		)
		or (
			not restored_last_contract.is_empty()
			and not bool(restored_last_contract.get("success", false))
			and restored_contracts_breached <= 0
		)
		or (
			not restored_last_contract.is_empty()
			and bool(restored_last_contract.get("success", false))
			and restored_clean_contract_streak <= 0
		)
		or (
			not restored_last_contract.is_empty()
			and not bool(restored_last_contract.get("success", false))
			and restored_clean_contract_streak != 0
		)
	):
		return false
	if not restored_last_contract.is_empty():
		var last_success := bool(restored_last_contract.get("success", false))
		var standing_before_last := (
			maxi(
				0,
				DepartmentSimulation.MARKET_STANDING_SUCCESS_POINTS * maxi(0, restored_contracts_succeeded - 1)
				- DepartmentSimulation.MARKET_STANDING_BREACH_POINTS * restored_contracts_breached,
			)
			if last_success else
			maxi(
				0,
				DepartmentSimulation.MARKET_STANDING_SUCCESS_POINTS * restored_contracts_succeeded
				- DepartmentSimulation.MARKET_STANDING_BREACH_POINTS * maxi(0, restored_contracts_breached - 1),
			)
		)
		var expected_rank: StringName = &"unlisted"
		if restored_market_standing >= 12:
			expected_rank = &"gold"
		elif restored_market_standing >= 6:
			expected_rank = &"silver"
		elif restored_market_standing >= 2:
			expected_rank = &"bronze"
		if (
			int(restored_last_contract.get("market_standing_before", -1)) != standing_before_last
			or int(restored_last_contract.get("market_standing_after", -1)) != restored_market_standing
			or int(restored_last_contract.get("market_standing_delta", 0))
			!= restored_market_standing - standing_before_last
			or StringName(restored_last_contract.get("market_standing_rank", &"")) != expected_rank
			or int(restored_last_contract.get("clean_contract_streak_after", -1))
			!= restored_clean_contract_streak
			or int(restored_last_contract.get("best_clean_contract_streak", -1))
			!= restored_best_clean_contract_streak
			or (
				last_success
				and int(restored_last_contract.get("clean_contract_streak_before", -1))
				!= restored_clean_contract_streak - 1
			)
		):
			return false
		if pricing_success_total + pricing_breach_total == settled_contract_total:
			var last_pricing_id := StringName(restored_last_contract.get(
				"pricing_profile_id",
				&"mutual_rate",
			))
			var last_pricing_key := "%s_%s" % [
				String(last_pricing_id),
				"success" if last_success else "breach",
			]
			if int(restored_pricing_outcomes.get(last_pricing_key, 0)) <= 0:
				return false
			var pricing_before_outcomes := restored_pricing_outcomes.duplicate(true)
			pricing_before_outcomes[last_pricing_key] = (
				int(pricing_before_outcomes[last_pricing_key]) - 1
			)
			var expected_reach_before := sim._market_reach_for_outcomes(pricing_before_outcomes)
			var expected_reach_after := sim._market_reach_for_outcomes(restored_pricing_outcomes)
			var expected_satisfaction_before := sim._claimant_satisfaction_for_outcomes(
				pricing_before_outcomes
			)
			var expected_satisfaction_after := sim._claimant_satisfaction_for_outcomes(
				restored_pricing_outcomes
			)
			if (
				int(restored_last_contract.get("market_reach_before", -1))
				!= expected_reach_before
				or int(restored_last_contract.get("market_reach_after", -1))
				!= expected_reach_after
				or int(restored_last_contract.get("claimant_satisfaction_before", -1))
				!= expected_satisfaction_before
				or int(restored_last_contract.get("claimant_satisfaction_after", -1))
				!= expected_satisfaction_after
			):
				return false
	if restored_contract_premium_today > 0 and (
		restored_last_contract.is_empty()
		or int(restored_last_contract.get("day", 0)) != saved_day
		or restored_contract_premium_today != int(restored_last_contract.get("premium_cents", 0))
	):
		return false
	if restored_contract_breach_today > 0 and (
		restored_last_contract.is_empty()
		or int(restored_last_contract.get("day", 0)) != saved_day
		or restored_contract_breach_today != int(restored_last_contract.get("breach_cents", 0))
	):
		return false
	var expected_signed_total := (
		restored_contracts_succeeded
		+ restored_contracts_breached
		+ (0 if restored_active_contract.is_empty() else 1)
	)
	if restored_contracts_signed != expected_signed_total:
		return false
	if (
		not restored_active_contract.is_empty()
		and sim._claim_capacity_for_facilities_and_campus(
			restored_owned_facilities,
			restored_campus_expansion,
			restored_campus_portfolio.claim_capacity_bonus(restored_portfolio_context),
		)
		< int(restored_active_contract.get("required_claim_capacity", 0))
	):
		return false
	var packing_fields := [
		"packing_carton_progress",
		"packing_cartons_today",
		"packing_cartons_total",
		"packing_value_bonus_today_cents",
		"packing_value_bonus_total_cents",
		"packing_carton_bonus_today_cents",
		"packing_carton_bonus_total_cents",
	]
	for packing_field in packing_fields:
		if not sim._is_integral_number(data.get(packing_field, null)):
			return false
	var restored_packing_progress := int(data.get("packing_carton_progress", -1))
	var restored_packing_cartons_today := int(data.get("packing_cartons_today", -1))
	var restored_packing_cartons_total := int(data.get("packing_cartons_total", -1))
	var restored_packing_value_today := int(data.get("packing_value_bonus_today_cents", -1))
	var restored_packing_value_total := int(data.get("packing_value_bonus_total_cents", -1))
	var restored_packing_carton_bonus_today := int(data.get("packing_carton_bonus_today_cents", -1))
	var restored_packing_carton_bonus_total := int(data.get("packing_carton_bonus_total_cents", -1))
	if (
		restored_packing_progress < 0
		or restored_packing_progress >= DepartmentSimulation.PACKING_CARTON_SIZE
		or restored_packing_cartons_today < 0
		or restored_packing_cartons_today > restored_packing_cartons_total
		or restored_packing_cartons_total > 2_000_000_000
		or restored_packing_value_today < 0
		or restored_packing_value_today > restored_packing_value_total
		or restored_packing_value_total > 2_000_000_000
		or restored_packing_carton_bonus_today < 0
		or restored_packing_carton_bonus_today > restored_packing_carton_bonus_total
		or restored_packing_carton_bonus_total > 2_000_000_000
		or restored_packing_carton_bonus_today % DepartmentSimulation.PACKING_CARTON_BONUS_PER_LEVEL_CENTS != 0
		or restored_packing_carton_bonus_total % DepartmentSimulation.PACKING_CARTON_BONUS_PER_LEVEL_CENTS != 0
	):
		return false
	if (
		int(restored_owned_facilities.get(DepartmentSimulation.PACKING_ANNEX_ID, 0)) <= 0
		and (
			restored_packing_progress != 0
			or restored_packing_cartons_today != 0
			or restored_packing_cartons_total != 0
			or restored_packing_value_today != 0
			or restored_packing_value_total != 0
			or restored_packing_carton_bonus_today != 0
			or restored_packing_carton_bonus_total != 0
		)
	):
		return false
	var saved_staffing_action_value: Variant = data.get("last_staffing_action", {})
	if not saved_staffing_action_value is Dictionary:
		return false
	var restored_staffing_action := (
		(saved_staffing_action_value as Dictionary).duplicate(true)
	)
	if not _is_valid_staffing_action_data(restored_staffing_action, saved_day):
		return false
	restored_staffing_action = _normalized_staffing_action_data(restored_staffing_action)
	var restored_shift_stats := _restore_worker_shift_stats(data.get("worker_shift_stats", []))
	if restored_shift_stats.size() != sim.workers.size():
		return false
	if not sim._is_integral_number(data.get("last_pecking_order_day", null)):
		return false
	var restored_order_day := int(data.get("last_pecking_order_day", -1))
	var validated_order := _validated_pecking_order_data(
		data.get("last_pecking_order", []),
	)
	if not bool(validated_order.get("valid", false)):
		return false
	var restored_order := validated_order.get("rows", []) as Array[Dictionary]
	if (
		(restored_order.is_empty() and restored_order_day != 0)
		or (not restored_order.is_empty() and (
			restored_order_day < 1 or restored_order_day > saved_day
		))
	):
		return false
	var restored_credit_counts := _validated_credit_counts(
		data.get("credit_choice_counts", {}),
	)
	if restored_credit_counts.size() != DepartmentSimulation.CREDIT_STYLE_IDS.size():
		return false
	var validated_allocation := _validated_credit_allocation(
		data.get("last_credit_allocation", {}),
		saved_day,
	)
	if not bool(validated_allocation.get("valid", false)):
		return false
	var restored_credit_allocation := (
		validated_allocation.get("record", {}) as Dictionary
	)
	if (
		not restored_credit_allocation.is_empty()
		and restored_order_day > 0
		and int(restored_credit_allocation.get("day", 0)) > restored_order_day
	):
		return false
	if typeof(data.get("golden_dossier_resolved", null)) != TYPE_BOOL:
		return false
	if not sim._is_integral_number(data.get("golden_dossier_day", null)):
		return false
	var restored_golden_resolved := bool(data.get("golden_dossier_resolved", false))
	var restored_golden_day := int(data.get("golden_dossier_day", -1))
	if (
		(restored_golden_resolved and (
			restored_golden_day < 1 or restored_golden_day > saved_day
		))
		or (not restored_golden_resolved and restored_golden_day != 0)
	):
		return false
	var restored_restructuring_resolved_value: Variant = data.get(
		"flock_restructuring_resolved",
		false,
	)
	var restored_restructuring_day_value: Variant = data.get("flock_restructuring_day", 0)
	var restored_restructuring_record_value: Variant = data.get("flock_restructuring_record", {})
	if (
		typeof(restored_restructuring_resolved_value) != TYPE_BOOL
		or not sim._is_integral_number(restored_restructuring_day_value)
		or not restored_restructuring_record_value is Dictionary
	):
		return false
	var restored_restructuring_resolved := bool(restored_restructuring_resolved_value)
	var restored_restructuring_day := int(restored_restructuring_day_value)
	var validated_restructuring := _validated_restructuring_record(
		restored_restructuring_record_value,
		saved_day,
	)
	if not bool(validated_restructuring.get("valid", false)):
		return false
	var restored_restructuring_record := (
		validated_restructuring.get("record", {}) as Dictionary
	)
	if (
		(restored_restructuring_resolved and (
			restored_restructuring_day != DepartmentSimulation.FLOCK_RESTRUCTURING_SHIFT
			or restored_restructuring_record.is_empty()
			or int(restored_restructuring_record.get("day", 0)) != restored_restructuring_day
		))
		or (not restored_restructuring_resolved and (
			restored_restructuring_day != 0
			or not restored_restructuring_record.is_empty()
		))
	):
		return false
	var validated_petition := _validated_flock_petition_record(
		data.get("last_flock_petition", {}),
		saved_day,
	)
	var validated_petition_history := _validated_flock_petition_history(
		data.get("flock_petition_history", []),
		saved_day,
	)
	var validated_compact := _validated_flock_compact(
		data.get("active_flock_compact", {}),
		saved_day,
	)
	var validated_compact_receipt := _validated_flock_compact_receipt(
		data.get("last_flock_compact_receipt", {}),
		saved_day,
	)
	var validated_work_record := _validated_work_to_rule_record(
		data.get("last_work_to_rule_record", {}),
		saved_day,
	)
	var validated_queued_work_record := _validated_work_to_rule_record(
		data.get("queued_work_to_rule_record", {}),
		saved_day,
	)
	if (
		not bool(validated_petition.get("valid", false))
		or not bool(validated_petition_history.get("valid", false))
		or not bool(validated_compact.get("valid", false))
		or not bool(validated_compact_receipt.get("valid", false))
		or not bool(validated_work_record.get("valid", false))
		or not bool(validated_queued_work_record.get("valid", false))
		or not sim._is_integral_number(data.get("work_to_rule_day", null))
		or not sim._is_integral_number(data.get("queued_work_to_rule_day", null))
	):
		return false
	var restored_petition := validated_petition.get("record", {}) as Dictionary
	var restored_petition_history := (
		validated_petition_history.get("records", []) as Array[Dictionary]
	)
	var restored_compact := validated_compact.get("record", {}) as Dictionary
	var restored_compact_receipt := validated_compact_receipt.get("record", {}) as Dictionary
	var restored_work_record := validated_work_record.get("record", {}) as Dictionary
	var restored_queued_work_record := validated_queued_work_record.get("record", {}) as Dictionary
	var restored_work_day := int(data.get("work_to_rule_day", -1))
	var restored_queued_work_day := int(data.get("queued_work_to_rule_day", -1))
	if (
		restored_work_day < 0 or restored_work_day > 9999
		or restored_queued_work_day < 0 or restored_queued_work_day > 9999
		or (restored_petition.is_empty() != restored_petition_history.is_empty())
		or (
			not restored_petition_history.is_empty()
			and restored_petition != restored_petition_history[restored_petition_history.size() - 1]
		)
	):
		return false
	if restored_work_day == 0:
		if not restored_work_record.is_empty() and StringName(restored_work_record.get("status", &"")) != &"completed":
			return false
	else:
		if (
			restored_work_record.is_empty()
			or int(restored_work_record.get("effective_day", 0)) != restored_work_day
			or restored_work_day < saved_day
		):
			return false
	if restored_queued_work_day == 0:
		if not restored_queued_work_record.is_empty():
			return false
	else:
		if (
			restored_queued_work_record.is_empty()
			or int(restored_queued_work_record.get("effective_day", 0)) != restored_queued_work_day
			or restored_queued_work_day <= saved_day
			or restored_work_day != saved_day
		):
			return false
	for assist_integer_field in [
		"peck_assists_used_today", "peck_assist_streak", "best_peck_assist_streak",
		"priority_credit_today_cents", "priority_credit_total_cents",
		"routing_momentum_chain", "best_routing_momentum_chain",
		"routing_momentum_peck_recharge_bank",
		"routing_momentum_peck_recharges_used_today",
		"routing_momentum_golden_charges",
		"routing_momentum_golden_target_claim_id",
		"routing_momentum_golden_target_worker_id",
	]:
		if not sim._is_integral_number(data.get(assist_integer_field, null)):
			return false
	var restored_assist_uses := int(data.get("peck_assists_used_today", -1))
	var restored_assist_streak := int(data.get("peck_assist_streak", -1))
	var restored_best_assist_streak := int(data.get("best_peck_assist_streak", -1))
	var restored_priority_today := int(data.get("priority_credit_today_cents", -1))
	var restored_priority_total := int(data.get("priority_credit_total_cents", -1))
	var restored_routing_chain := int(data.get("routing_momentum_chain", -1))
	var restored_best_routing_chain := int(data.get("best_routing_momentum_chain", -1))
	var restored_routing_peck_bank := int(data.get("routing_momentum_peck_recharge_bank", -1))
	var restored_routing_peck_uses := int(data.get("routing_momentum_peck_recharges_used_today", -1))
	var restored_routing_golden_charges := int(data.get("routing_momentum_golden_charges", -1))
	var restored_routing_golden_target_claim_id := int(data.get("routing_momentum_golden_target_claim_id", -2))
	var restored_routing_golden_target_worker_id := int(data.get("routing_momentum_golden_target_worker_id", -2))
	var restored_interventions_value: Variant = data.get(
		"peck_assist_interventions_today",
		restored_assist_uses,
	)
	var restored_refunds_value: Variant = data.get("peck_assist_refunds_today", 0)
	if (
		not sim._is_integral_number(restored_interventions_value)
		or not sim._is_integral_number(restored_refunds_value)
	):
		return false
	var restored_interventions := int(restored_interventions_value)
	var restored_refunds := int(restored_refunds_value)
	if (
		restored_assist_uses < 0 or restored_assist_uses > DepartmentSimulation.PECK_ASSIST_LIMIT
		or restored_interventions < 0 or restored_interventions > 9999
		or restored_refunds < 0 or restored_refunds > restored_interventions
		or restored_interventions - restored_refunds - restored_routing_peck_uses != restored_assist_uses
		or restored_assist_streak < 0 or restored_assist_streak > 9999
		or restored_best_assist_streak < restored_assist_streak
		or restored_best_assist_streak > 9999
		or restored_priority_today < 0
		or restored_priority_total < restored_priority_today
		or restored_priority_total > 2_000_000_000
		or restored_routing_chain < 0 or restored_routing_chain > 9999
		or restored_best_routing_chain < restored_routing_chain
		or restored_best_routing_chain > 9999
		or restored_routing_peck_bank not in [0, 1]
		or restored_routing_peck_uses < 0 or restored_routing_peck_uses > restored_interventions
		or restored_routing_golden_charges not in [0, 1]
		or restored_routing_golden_target_claim_id < -1
		or restored_routing_golden_target_worker_id < -1
	):
		return false
	var restored_last_assist_value: Variant = data.get("last_peck_assist", {})
	var restored_assisted_ids_value: Variant = data.get("assisted_claim_ids", [])
	var restored_missed_ids_value: Variant = data.get("missed_assist_claim_ids", [])
	var restored_assist_quality_value: Variant = data.get("assist_quality_modifiers", {})
	var restored_assist_chains_value: Variant = data.get("assist_chain_by_claim_id", {})
	var restored_pending_deliveries_value: Variant = data.get(
		"pending_peck_assist_deliveries",
		[],
	)
	var restored_settled_delivery_ids_value: Variant = data.get(
		"settled_peck_assist_delivery_ids",
		[],
	)
	var restored_last_delivery_value: Variant = data.get("last_peck_assist_delivery", {})
	var restored_last_routing_dispatch_value: Variant = data.get("last_routing_dispatch", {})
	var restored_routing_free_assist_ids_value: Variant = data.get(
		"routing_momentum_free_assist_claim_ids",
		[],
	)
	if (
		not restored_last_assist_value is Dictionary
		or not restored_assisted_ids_value is Array
		or not restored_missed_ids_value is Array
		or not restored_assist_quality_value is Dictionary
		or not restored_assist_chains_value is Dictionary
		or not restored_pending_deliveries_value is Array
		or not restored_settled_delivery_ids_value is Array
		or not restored_last_delivery_value is Dictionary
		or not restored_last_routing_dispatch_value is Dictionary
		or not restored_routing_free_assist_ids_value is Array
	):
		return false
	var restored_last_assist := (restored_last_assist_value as Dictionary).duplicate(true)
	if not _is_valid_peck_assist_record(restored_last_assist, saved_day):
		return false
	restored_last_assist = sim._normalized_peck_assist_record(restored_last_assist)
	var restored_last_delivery := (restored_last_delivery_value as Dictionary).duplicate(true)
	if not _is_valid_peck_assist_delivery_receipt(restored_last_delivery, saved_day):
		return false
	restored_last_delivery = sim._normalized_peck_assist_delivery_receipt(restored_last_delivery)
	var restored_last_routing_dispatch := (
		(restored_last_routing_dispatch_value as Dictionary).duplicate(true)
	)

	var seen_claim_ids: Dictionary[int, bool] = {}
	var personnel_actions_by_day: Dictionary[int, int] = {}
	var seen_personnel_action_serials: Dictionary[int, bool] = {}
	var restored_personnel_action_limit := sim._facility_level_schedule_value(
		DepartmentSimulation.ROOSTER_PERSONNEL_ACTION_LIMITS,
		restored_rooster_operations_level,
		1,
	)
	var occupied_desks: Dictionary[int, bool] = {}
	var restored_active_count := 0
	var restored_workers: Array[ChickenState] = []
	for index in sim.workers.size():
		if not worker_data[index] is Dictionary:
			return false
		var saved_worker := worker_data[index] as Dictionary
		if not sim._is_integral_number(saved_worker.get("id", null)) or int(saved_worker.get("id", -1)) != index:
			return false
		if typeof(saved_worker.get("employed", null)) != TYPE_BOOL:
			return false
		var saved_employed := bool(saved_worker.get("employed", false))
		var expected_status := (
			ChickenState.EMPLOYMENT_STATUS_EMPLOYED
			if saved_employed else ChickenState.EMPLOYMENT_STATUS_APPLICANT
		)
		if StringName(String(saved_worker.get("employment_status", ""))) != expected_status:
			return false
		for integer_field in [
			"desk_index", "available_for_hire_day", "hire_count",
			"employment_start_day", "last_personnel_action_day",
			"last_personnel_action_serial",
		]:
			if not sim._is_integral_number(saved_worker.get(integer_field, null)):
				return false
		var raw_desk_index := int(saved_worker.get("desk_index", -2))
		var raw_available_day := int(saved_worker.get("available_for_hire_day", -1))
		var raw_hire_count := int(saved_worker.get("hire_count", -1))
		var raw_employment_start := int(saved_worker.get("employment_start_day", -1))
		if raw_desk_index < -1 or raw_desk_index >= DepartmentSimulation.MAXIMUM_STAFF_CAPACITY:
			return false
		if raw_available_day < 0 or raw_available_day > 10000:
			return false
		if raw_hire_count < 0 or raw_hire_count > 9999:
			return false
		if raw_employment_start < 0 or raw_employment_start > 9999:
			return false
		var original := sim.workers[index]
		var saved_profile := StringName(String(saved_worker.get(
			"career_profile",
			ChickenState.default_career_profile(original.id)
		)))
		if not ChickenState.is_valid_career_profile(saved_profile):
			return false
		var saved_action := StringName(String(saved_worker.get("last_personnel_action", "")))
		var saved_action_day := int(saved_worker.get("last_personnel_action_day", 0))
		var saved_action_serial := int(saved_worker.get("last_personnel_action_serial", -1))
		for specialty_field in ["secondary_specialty", "cross_training_target"]:
			if typeof(saved_worker.get(specialty_field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
				return false
		if typeof(saved_worker.get("cross_training_worked_this_shift", null)) != TYPE_BOOL:
			return false
		if not ChickenState.is_valid_personnel_action(saved_action):
			return false
		if (
			(saved_action == &"") != (saved_action_day == 0)
			or (saved_action == &"") != (saved_action_serial == 0)
			or saved_action_serial < 0
		):
			return false
		var restored := ChickenState.new(
			original.id,
			original.display_name,
			original.desk_index,
			original.skill,
			original.accuracy,
			original.specialty
		)
		if not restored.apply_save_data(saved_worker):
			return false
		if not ChickenState.is_valid_career_profile(restored.career_profile):
			return false
		if not ChickenState.is_valid_personnel_action(restored.last_personnel_action):
			return false
		if restored.last_personnel_action_day > saved_day:
			return false
		if restored.last_personnel_action_day > 0:
			if seen_personnel_action_serials.has(restored.last_personnel_action_serial):
				return false
			seen_personnel_action_serials[restored.last_personnel_action_serial] = true
			if (
				restored.last_personnel_action_day == saved_day
				and (
					not restored.employed
					or saved_shift_phase not in [
						DepartmentSimulation.ShiftPhase.RUNNING,
						DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT,
					]
				)
			):
				return false
			var actions_on_day := int(personnel_actions_by_day.get(
				restored.last_personnel_action_day,
				0,
			)) + 1
			if actions_on_day > restored_personnel_action_limit:
				return false
			personnel_actions_by_day[restored.last_personnel_action_day] = actions_on_day
		if restored.specialty not in DepartmentSimulation.CLAIM_LANES:
			return false
		if (
			restored.secondary_specialty != &""
			and restored.secondary_specialty not in DepartmentSimulation.CLAIM_LANES
		):
			return false
		if (
			restored.cross_training_target != &""
			and restored.cross_training_target not in DepartmentSimulation.CLAIM_LANES
		):
			return false
		if restored.assigned_lane != DepartmentSimulation.AUTO_ASSIGNMENT and restored.assigned_lane not in DepartmentSimulation.CLAIM_LANES:
			return false
		if restored.cross_training_worked_this_shift and (
			not restored.employed
			or int(data.get("shift_phase", -1)) not in [
				DepartmentSimulation.ShiftPhase.RUNNING,
				DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT,
			]
		):
			return false
		if restored.employed:
			if (
				restored.desk_index < 0
				or restored.desk_index >= saved_office_capacity
				or occupied_desks.has(restored.desk_index)
				or restored.available_for_hire_day != 0
				or restored.employment_start_day < 1
				or restored.employment_start_day > saved_day
			):
				return false
			occupied_desks[restored.desk_index] = true
			restored_active_count += 1
		else:
			if (
				restored.desk_index != -1
				or restored.available_for_hire_day < 1
				or restored.available_for_hire_day > 10000
				or restored.employment_start_day != 0
				or restored.work_state != ChickenState.WorkState.IDLE
				or not is_zero_approx(restored.work_progress)
				or restored.state_ticks_remaining != 0
				or restored.current_claim != null
			):
				return false
		if restored.current_claim != null:
			if restored.current_claim.lane not in DepartmentSimulation.CLAIM_LANES or seen_claim_ids.has(restored.current_claim.id):
				return false
			seen_claim_ids[restored.current_claim.id] = true
		restored_workers.append(restored)
	if (
		restored_active_count < DepartmentSimulation.MINIMUM_STAFF_COUNT
		or restored_active_count > saved_office_capacity
	):
		return false
	var restored_golden_target_valid := (
		restored_routing_golden_charges == 1
		and restored_routing_golden_target_worker_id >= 0
		and restored_routing_golden_target_worker_id < restored_workers.size()
		and restored_workers[restored_routing_golden_target_worker_id].current_claim != null
		and restored_workers[restored_routing_golden_target_worker_id].current_claim.id
		== restored_routing_golden_target_claim_id
	)
	if (
		(restored_routing_golden_target_claim_id == -1)
		!= (restored_routing_golden_target_worker_id == -1)
		or (
			restored_routing_golden_target_claim_id >= 0
			and not restored_golden_target_valid
		)
		or (
			restored_routing_golden_charges == 0
			and restored_routing_golden_target_claim_id != -1
		)
	):
		return false
	for module_id: StringName in DepartmentSimulation.CampusPortfolioStateScript.MODULE_ORDER:
		var restored_module_value: Variant = restored_campus_portfolio.modules.get(
			String(module_id),
			{},
		)
		if not restored_module_value is Dictionary:
			return false
		var assigned_worker_id := int((restored_module_value as Dictionary).get("worker_id", -1))
		if assigned_worker_id >= 0 and (
			assigned_worker_id >= restored_workers.size()
			or not restored_workers[assigned_worker_id].employed
		):
			return false
	var farmgate_worker_lots: Array[Dictionary] = restored_farmgate_dispatch.lots.duplicate(true)
	for settlement_value in restored_farmgate_dispatch.history:
		var settlement := settlement_value as Dictionary
		for lot_value in settlement.get("sold_lots", []) as Array:
			farmgate_worker_lots.append(lot_value as Dictionary)
		for lot_value in settlement.get("expired_lots", []) as Array:
			farmgate_worker_lots.append(lot_value as Dictionary)
	for lot in farmgate_worker_lots:
		var farmgate_worker_id := int(lot.get("worker_id", -1))
		if (
			farmgate_worker_id < 0 or farmgate_worker_id >= restored_workers.size()
			or String(lot.get("worker_name", "")) != restored_workers[farmgate_worker_id].display_name
		):
			return false
	var validated_flock_relations := _validated_flock_relations_state(
		data,
		saved_day,
		restored_flock_relations_level,
		restored_workers,
	)
	if not bool(validated_flock_relations.get("valid", false)):
		return false
	var restored_flock_relations_cases := (
		validated_flock_relations.get("open_cases", []) as Array[Dictionary]
	)
	var restored_flock_relations_resolutions_used := int(
		validated_flock_relations.get("resolutions_used_today", 0)
	)
	var restored_flock_relations_resolved_total := int(
		validated_flock_relations.get("resolved_total", 0)
	)
	var restored_flock_relations_denied_total := int(
		validated_flock_relations.get("denied_total", 0)
	)
	var restored_flock_relations_spend_total := int(
		validated_flock_relations.get("settlement_spend_total_cents", 0)
	)
	var restored_last_flock_relations_resolution := (
		validated_flock_relations.get("last_resolution", {}) as Dictionary
	)
	var restored_flock_relations_history := (
		validated_flock_relations.get("history", []) as Array[Dictionary]
	)
	var restored_next_flock_relations_case_id := int(
		validated_flock_relations.get("next_case_id", 1)
	)
	if (
		not restored_active_contract.is_empty()
		and int(restored_active_contract.get("required_active_staff", 0)) > restored_active_count
	):
		return false
	var pending_value: Variant = data.get("pending_decision", {})
	if not pending_value is Dictionary or not _is_valid_pending_flock_petition(pending_value, saved_day):
		return false
	var pending_source := pending_value as Dictionary
	var pending_incident_id := StringName(String(pending_source.get("id", "")))
	if (
		pending_incident_id in DepartmentSimulation.INCIDENT_ORDER
		and restored_last_standard_incident_id != pending_incident_id
	):
		return false
	var active_directive_value: Variant = data.get("active_directive_id", "")
	if typeof(active_directive_value) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	var restored_active_directive := StringName(String(active_directive_value))
	if not _is_valid_shift_decision_tuple(
		saved_shift_phase,
		restored_active_directive,
		pending_source,
	):
		return false
	var harvest_status: StringName = StringName(restored_harvest_credit.review_status)
	var pending_kind := StringName(pending_source.get("kind", &""))
	if (
		(harvest_status == DepartmentSimulation.HarvestCreditStateScript.STATUS_PRE_CREDIT and (
			saved_shift_phase != DepartmentSimulation.ShiftPhase.REVIEW
			or pending_kind not in [&"credit_allocation", &"major_event"]
		))
		or (harvest_status == DepartmentSimulation.HarvestCreditStateScript.STATUS_OFFER_OPEN and (
			saved_shift_phase != DepartmentSimulation.ShiftPhase.REVIEW or not pending_source.is_empty()
		))
	):
		return false
	var harvest_evidence: Dictionary = (
		restored_harvest_credit.frozen_evidence as Dictionary
	)
	if not harvest_evidence.is_empty() and int(harvest_evidence.get("day", 0)) == restored_order_day:
		if restored_order.is_empty():
			return false
		var restored_top := restored_order[0]
		if (
			int(harvest_evidence.get("top_worker_id", -1)) != int(restored_top.get("worker_id", -1))
			or String(harvest_evidence.get("top_worker_name", "")) != String(restored_top.get("worker_name", ""))
		):
			return false
	if (
		saved_shift_phase == DepartmentSimulation.ShiftPhase.REVIEW
		and (not restored_active_contract.is_empty() or not restored_contract_decline.is_empty())
		and not pending_source.is_empty()
	):
		return false
	if StringName(pending_source.get("id", &"")) == DepartmentSimulation.FLOCK_PETITION_INCIDENT_ID:
		var pending_sponsor_id := int(pending_source.get("sponsor_worker_id", -1))
		if (
			saved_shift_phase != DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT
			or int(data.get("incident_slot", -1)) != DepartmentSimulation.FLOCK_PETITION_INCIDENT_SLOT + 1
			or pending_sponsor_id < 0 or pending_sponsor_id >= restored_workers.size()
			or not restored_workers[pending_sponsor_id].employed
			or restored_workers[pending_sponsor_id].display_name != String(pending_source.get("sponsor_worker_name", ""))
			or not restored_compact.is_empty()
		):
			return false
	var historical_records: Array[Dictionary] = restored_petition_history.duplicate(true)
	var named_records: Array[Dictionary] = []
	if not restored_compact.is_empty():
		named_records.append(restored_compact)
	if not restored_compact_receipt.is_empty():
		named_records.append(restored_compact_receipt)
	if not restored_work_record.is_empty():
		named_records.append(restored_work_record)
	if not restored_queued_work_record.is_empty():
		named_records.append(restored_queued_work_record)
	for named_record in named_records:
		var sponsor_id := int(named_record.get("sponsor_worker_id", -1))
		if (
			sponsor_id < 0 or sponsor_id >= restored_workers.size()
			or restored_workers[sponsor_id].display_name != String(named_record.get("sponsor_worker_name", ""))
		):
			return false
	if not restored_compact.is_empty():
		var compact_sponsor_id := int(restored_compact.get("sponsor_worker_id", -1))
		if not restored_workers[compact_sponsor_id].employed:
			return false
		var compact_type := StringName(restored_compact.get("petition_type", &""))
		if (
			StringName(restored_compact.get("status", &"")) == &"active"
			and compact_type == &"specialty_respect"
			and restored_workers[compact_sponsor_id].assigned_lane != restored_workers[compact_sponsor_id].specialty
		):
			return false
		if (
			StringName(restored_compact.get("status", &"")) == &"active"
			and compact_type == &"safe_pace"
			and bool(data.get("overtime_enabled", false))
		):
			return false
		var compact_has_petition := false
		for petition_record in historical_records:
			if (
				int(petition_record.get("day", 0)) == int(restored_compact.get("petition_day", 0))
				and int(petition_record.get("sponsor_worker_id", -1)) == compact_sponsor_id
				and StringName(petition_record.get("petition_type", &"")) == compact_type
				and StringName(petition_record.get("response_id", &"")) == &"sign_compact"
			):
				compact_has_petition = true
				break
		if not compact_has_petition:
			return false

	var restored_queues: Dictionary = {}
	var saved_queues := queue_values as Dictionary
	var outstanding_count := 0
	for lane in DepartmentSimulation.CLAIM_LANES:
		var lane_values: Variant = saved_queues.get(String(lane), [])
		if not lane_values is Array:
			return false
		var restored_lane: Array[ClaimState] = []
		for claim_value in (lane_values as Array):
			if not claim_value is Dictionary:
				return false
			var claim := ClaimState.from_save_data(claim_value as Dictionary)
			if claim == null or claim.lane != lane or seen_claim_ids.has(claim.id):
				return false
			seen_claim_ids[claim.id] = true
			restored_lane.append(claim)
			outstanding_count += 1
		restored_queues[lane] = restored_lane

	var restored_rework: Array[ClaimState] = []
	for claim_value in (rework_values as Array):
		if not claim_value is Dictionary:
			return false
		var claim := ClaimState.from_save_data(claim_value as Dictionary)
		if claim == null or claim.lane not in DepartmentSimulation.CLAIM_LANES or seen_claim_ids.has(claim.id):
			return false
		seen_claim_ids[claim.id] = true
		restored_rework.append(claim)
		outstanding_count += 1
	for restored in restored_workers:
		if restored.current_claim != null:
			outstanding_count += 1
	var restored_pending_contract_claims := 0
	if not restored_active_contract.is_empty():
		var contract_claim_ids := restored_active_contract.get("claim_ids", []) as Array
		var accepted_contract_ids := restored_active_contract.get("accepted_claim_ids", []) as Array
		var completed_contract_ids := restored_active_contract.get("completed_claim_ids", []) as Array
		var rejected_contract_ids := restored_active_contract.get("rejected_claim_ids", []) as Array
		for contract_claim_id_value in contract_claim_ids:
			var contract_claim_id := int(contract_claim_id_value)
			if contract_claim_id in accepted_contract_ids:
				if (
					(contract_claim_id in completed_contract_ids and seen_claim_ids.has(contract_claim_id))
					or (contract_claim_id not in completed_contract_ids and not seen_claim_ids.has(contract_claim_id))
				):
					return false
			elif contract_claim_id in rejected_contract_ids:
				if seen_claim_ids.has(contract_claim_id):
					return false
			else:
				if seen_claim_ids.has(contract_claim_id):
					return false
				restored_pending_contract_claims += 1
	if (
		outstanding_count + restored_pending_contract_claims
		> sim._claim_capacity_for_facilities_and_campus(
			restored_owned_facilities,
			restored_campus_expansion,
			restored_campus_portfolio.claim_capacity_bonus(restored_portfolio_context),
		)
	):
		return false

	var active_claim_ids: Dictionary[int, bool] = {}
	for restored in restored_workers:
		if restored.current_claim != null:
			active_claim_ids[restored.current_claim.id] = true
	var restored_assisted_ids: Dictionary[int, bool] = {}
	for claim_id_value in (restored_assisted_ids_value as Array):
		if not sim._is_integral_number(claim_id_value):
			return false
		var assisted_claim_id := int(claim_id_value)
		if assisted_claim_id < 1 or not active_claim_ids.has(assisted_claim_id) or restored_assisted_ids.has(assisted_claim_id):
			return false
		restored_assisted_ids[assisted_claim_id] = true
	var restored_missed_ids: Dictionary[int, bool] = {}
	for claim_id_value in (restored_missed_ids_value as Array):
		if not sim._is_integral_number(claim_id_value):
			return false
		var missed_claim_id := int(claim_id_value)
		if (
			missed_claim_id < 1
			or not active_claim_ids.has(missed_claim_id)
			or restored_missed_ids.has(missed_claim_id)
			or restored_assisted_ids.has(missed_claim_id)
		):
			return false
		restored_missed_ids[missed_claim_id] = true
	var restored_routing_free_assist_ids: Dictionary[int, bool] = {}
	for claim_id_value in (restored_routing_free_assist_ids_value as Array):
		if not sim._is_integral_number(claim_id_value):
			return false
		var free_claim_id := int(claim_id_value)
		if (
			free_claim_id < 1
			or not restored_assisted_ids.has(free_claim_id)
			or restored_routing_free_assist_ids.has(free_claim_id)
		):
			return false
		restored_routing_free_assist_ids[free_claim_id] = true
	var restored_assist_quality: Dictionary[int, float] = {}
	for key_value in (restored_assist_quality_value as Dictionary):
		var quality_key_text := String(key_value)
		if not quality_key_text.is_valid_int():
			return false
		var quality_claim_id := quality_key_text.to_int()
		var modifier_value: Variant = (restored_assist_quality_value as Dictionary)[key_value]
		if (
			typeof(modifier_value) not in [TYPE_FLOAT, TYPE_INT]
			or not restored_assisted_ids.has(quality_claim_id)
			or restored_assist_quality.has(quality_claim_id)
		):
			return false
		var modifier := float(modifier_value)
		if modifier < -0.10 or modifier > 0.10:
			return false
		restored_assist_quality[quality_claim_id] = modifier
	var restored_assist_chains: Dictionary[int, int] = {}
	for key_value in (restored_assist_chains_value as Dictionary):
		var chain_key_text := String(key_value)
		if not chain_key_text.is_valid_int():
			return false
		var chain_claim_id := chain_key_text.to_int()
		var chain_value: Variant = (restored_assist_chains_value as Dictionary)[key_value]
		if (
			not sim._is_integral_number(chain_value)
			or not restored_assisted_ids.has(chain_claim_id)
			or restored_assist_chains.has(chain_claim_id)
		):
			return false
		var chain := int(chain_value)
		if chain < 0 or chain > restored_best_assist_streak:
			return false
		restored_assist_chains[chain_claim_id] = chain
	var restored_pending_deliveries: Dictionary[int, Dictionary] = {}
	for delivery_value in (restored_pending_deliveries_value as Array):
		if not delivery_value is Dictionary:
			return false
		var delivery := (delivery_value as Dictionary).duplicate(true)
		if not _is_valid_peck_assist_delivery_token(delivery, saved_day):
			return false
		delivery = _normalized_peck_assist_delivery_token(delivery)
		var delivery_claim_id := int(delivery.get("claim_id", -1))
		if (
			restored_pending_deliveries.has(delivery_claim_id)
			or seen_claim_ids.has(delivery_claim_id)
		):
			return false
		restored_pending_deliveries[delivery_claim_id] = delivery
	var restored_settled_delivery_ids: Dictionary[int, bool] = {}
	for claim_id_value in (restored_settled_delivery_ids_value as Array):
		if not sim._is_integral_number(claim_id_value):
			return false
		var settled_claim_id := int(claim_id_value)
		if (
			settled_claim_id < 1
			or restored_settled_delivery_ids.has(settled_claim_id)
			or restored_pending_deliveries.has(settled_claim_id)
			or seen_claim_ids.has(settled_claim_id)
		):
			return false
		restored_settled_delivery_ids[settled_claim_id] = true
	if (
		restored_assist_quality.size() != restored_assisted_ids.size()
		or restored_assist_chains.size() != restored_assisted_ids.size()
		or restored_assisted_ids.size() > restored_assist_uses + restored_routing_peck_uses
		or restored_routing_free_assist_ids.size() > restored_routing_peck_uses
		or restored_pending_deliveries.size() > restored_assist_uses
		or restored_settled_delivery_ids.size() != restored_refunds
		or (restored_refunds == 0 and not restored_last_delivery.is_empty())
		or (
			restored_refunds > 0
			and (
				restored_last_delivery.is_empty()
				or not restored_settled_delivery_ids.has(int(restored_last_delivery.get("claim_id", -1)))
			)
		)
	):
		return false

	var restored_workshop := CareerWorkshop.from_save_data(data.get("career_workshop"), saved_day, restored_workers.size())
	if restored_workshop == null:
		return false
	var restored_relationships := FlockRelationships.from_save_data(data.get("flock_relationships"), saved_day, restored_workers.size())
	if restored_relationships == null:
		return false
	sim.flock_relationships = restored_relationships
	sim.career_workshop = restored_workshop
	sim.workers = restored_workers
	sim._claim_queues = restored_queues
	sim._pending_rework = restored_rework
	sim.upgrade_levels = restored_upgrade_levels
	sim.first_clutch_reinvestment = restored_first_clutch_reinvestment
	sim.active_playbook = restored_active_playbook.duplicate(true)
	sim.hero_case_history = restored_hero_case_history.duplicate(true)
	sim.rival_response_history = restored_rival_response_history.duplicate(true)
	sim.requisition_spend_today_cents = restored_requisition_spend_today
	sim.requisition_spend_total_cents = restored_requisition_spend_total
	sim.orientation_procurement_match_today_cents = restored_orientation_match_today
	sim.orientation_procurement_match_total_cents = restored_orientation_match_total
	sim.owned_facilities = restored_owned_facilities
	sim.manager_roster = restored_manager_roster
	sim.last_manager_action = restored_last_manager_action
	sim.management_reports_today = restored_reports_today
	sim.management_reports_total = restored_reports_total
	sim.management_visibility_today = restored_visibility_today
	sim._internship_program = restored_internship_program
	sim._feed_procurement = restored_feed_procurement
	sim._harvest_credit = restored_harvest_credit
	sim._farmgate_dispatch = restored_farmgate_dispatch
	sim._farm_treasury = restored_farm_treasury
	sim.campus_expansion_state = restored_campus_expansion
	sim._campus_portfolio = restored_campus_portfolio
	sim.pinned_capital_plan_id = StringName(restored_capital_records.get("pinned_id", &""))
	sim.pinned_economic_watch_id = restored_economic_watch_id
	sim.last_facility_purchase_receipt = (
		restored_capital_records.get("last", {}) as Dictionary
	).duplicate(true)
	sim.facility_commissioning_history = (
		restored_capital_records.get("history", []) as Array[Dictionary]
	).duplicate(true)
	sim.packing_carton_progress = restored_packing_progress
	sim.packing_cartons_today = restored_packing_cartons_today
	sim.packing_cartons_total = restored_packing_cartons_total
	sim.packing_value_bonus_today_cents = restored_packing_value_today
	sim.packing_value_bonus_total_cents = restored_packing_value_total
	sim.packing_carton_bonus_today_cents = restored_packing_carton_bonus_today
	sim.packing_carton_bonus_total_cents = restored_packing_carton_bonus_total
	sim.intake_rejections_today = restored_intake_rejections_today
	sim.intake_rejections_total = restored_intake_rejections_total
	sim.intake_missed_value_today_cents = restored_intake_missed_today
	sim.intake_missed_value_total_cents = restored_intake_missed_total
	sim.active_market_contract = restored_active_contract
	sim.market_contract_decline_receipt = restored_contract_decline
	sim.last_market_contract_result = restored_last_contract
	sim.market_contracts_signed_total = restored_contracts_signed
	sim.market_contracts_succeeded_total = restored_contracts_succeeded
	sim.market_contracts_breached_total = restored_contracts_breached
	sim.market_clean_contract_streak = restored_clean_contract_streak
	sim.best_market_clean_contract_streak = restored_best_clean_contract_streak
	sim.market_contract_premium_today_cents = restored_contract_premium_today
	sim.market_contract_premium_total_cents = restored_contract_premium_total
	sim.market_contract_breach_today_cents = restored_contract_breach_today
	sim.market_contract_breach_total_cents = restored_contract_breach_total
	sim.market_pricing_outcomes = restored_pricing_outcomes
	sim.office_capacity = saved_office_capacity
	sim.wage_arrears_cents = saved_wage_arrears
	sim.last_staffing_action = restored_staffing_action
	sim._worker_shift_stats = restored_shift_stats
	sim.last_pecking_order = restored_order
	sim.last_pecking_order_day = restored_order_day
	sim.last_credit_allocation = restored_credit_allocation
	sim.credit_choice_counts = restored_credit_counts
	sim.golden_dossier_resolved = restored_golden_resolved
	sim.golden_dossier_day = restored_golden_day
	sim.flock_restructuring_resolved = restored_restructuring_resolved
	sim.flock_restructuring_day = restored_restructuring_day
	sim.flock_restructuring_record = restored_restructuring_record
	sim.last_flock_petition = restored_petition
	sim.flock_petition_history = restored_petition_history
	sim.flock_relations_open_cases = restored_flock_relations_cases
	sim.flock_relations_resolutions_used_today = restored_flock_relations_resolutions_used
	sim.flock_relations_resolved_total = restored_flock_relations_resolved_total
	sim.flock_relations_denied_total = restored_flock_relations_denied_total
	sim.flock_relations_settlement_spend_total_cents = restored_flock_relations_spend_total
	sim.last_flock_relations_resolution = restored_last_flock_relations_resolution
	sim.flock_relations_resolution_history = restored_flock_relations_history
	sim.next_flock_relations_case_id = restored_next_flock_relations_case_id
	sim.active_flock_compact = restored_compact
	sim.last_flock_compact_receipt = restored_compact_receipt
	sim.work_to_rule_day = restored_work_day
	sim.last_work_to_rule_record = restored_work_record
	sim.queued_work_to_rule_day = restored_queued_work_day
	sim.queued_work_to_rule_record = restored_queued_work_record
	sim.peck_assists_used_today = restored_assist_uses
	sim.peck_assist_interventions_today = restored_interventions
	sim.peck_assist_refunds_today = restored_refunds
	sim.peck_assist_streak = restored_assist_streak
	sim.best_peck_assist_streak = restored_best_assist_streak
	sim.last_peck_assist = restored_last_assist
	sim.last_peck_assist_delivery = restored_last_delivery
	sim.priority_credit_today_cents = restored_priority_today
	sim.priority_credit_total_cents = restored_priority_total
	sim.routing_momentum_chain = restored_routing_chain
	sim.best_routing_momentum_chain = restored_best_routing_chain
	sim.routing_momentum_peck_recharge_bank = restored_routing_peck_bank
	sim.routing_momentum_peck_recharges_used_today = restored_routing_peck_uses
	sim.routing_momentum_golden_charges = restored_routing_golden_charges
	sim.routing_momentum_golden_target_claim_id = restored_routing_golden_target_claim_id
	sim.routing_momentum_golden_target_worker_id = restored_routing_golden_target_worker_id
	sim.last_routing_dispatch = restored_last_routing_dispatch
	sim._assisted_claim_ids = restored_assisted_ids
	sim._missed_assist_claim_ids = restored_missed_ids
	sim._assist_quality_modifiers = restored_assist_quality
	sim._assist_chain_by_claim_id = restored_assist_chains
	sim._pending_peck_assist_deliveries = restored_pending_deliveries
	sim._settled_peck_assist_delivery_ids = restored_settled_delivery_ids
	sim._routing_momentum_free_assist_claim_ids = restored_routing_free_assist_ids
	sim.day = clampi(int(data.get("day", 1)), 1, 9999)
	sim.minute_of_day = clampi(int(data.get("minute_of_day", DepartmentSimulation.SHIFT_START_MINUTE)), DepartmentSimulation.SHIFT_START_MINUTE, DepartmentSimulation.SHIFT_END_MINUTE)
	sim.claims_processed = maxi(0, int(data.get("claims_processed", 0)))
	sim.eggs_today = maxi(0, int(data.get("eggs_today", 0)))
	sim.eggs_total = maxi(0, int(data.get("eggs_total", sim.eggs_today)))
	sim.cracked_eggs = clampi(int(data.get("cracked_eggs", 0)), 0, sim.eggs_total)
	sim.cracked_today = clampi(int(data.get("cracked_today", 0)), 0, sim.eggs_today)
	sim.golden_eggs = clampi(int(data.get("golden_eggs", 0)), 0, sim.eggs_total)
	sim.golden_today = clampi(int(data.get("golden_today", 0)), 0, sim.eggs_today)
	sim.revenue_cents = clampi(int(data.get("revenue_cents", 5000)), 0, 2000000000)
	sim.credited_today_cents = clampi(int(data.get("credited_today_cents", 0)), 0, 2000000000)
	sim.feed_cents_per_day = clampi(int(data.get("feed_cents_per_day", 1800)), 0, 1000000)
	sim.quota_target = clampi(int(data.get("quota_target", 24)), 1, 10000)
	sim.executive_confidence = clampf(float(data.get("executive_confidence", 52.0)), 0.0, 100.0)
	sim.compliance = clampf(float(data.get("compliance", 78.0)), 0.0, 100.0)
	sim.solidarity = clampf(float(data.get("solidarity", 18.0)), 0.0, 100.0)
	sim.overtime_enabled = bool(data.get("overtime_enabled", false))
	sim.feed_party_used_today = bool(data.get("feed_party_used_today", false))
	sim.quality_streak = maxi(0, int(data.get("quality_streak", 0)))
	sim.best_quality_streak = maxi(sim.quality_streak, int(data.get("best_quality_streak", sim.quality_streak)))
	sim.last_streak_bonus_cents = maxi(0, int(data.get("last_streak_bonus_cents", 0)))
	sim.shift_phase = saved_shift_phase
	sim.active_directive_id = restored_active_directive
	sim.pending_decision = _decision_from_save_data(data.get("pending_decision", {}) as Dictionary)
	sim.incidents_resolved_today = clampi(int(data.get("incidents_resolved_today", 0)), 0, DepartmentSimulation.INCIDENT_MINUTES.size())
	sim.incident_response_history = restored_incident_response_history
	sim.incident_pivot_mastery_receipts = restored_pivot_mastery_receipts

	var saved_lane_totals := data.get("lane_processed_totals", {}) as Dictionary
	var saved_lane_today := data.get("lane_processed_today", {}) as Dictionary
	for lane in DepartmentSimulation.CLAIM_LANES:
		sim.lane_processed_totals[lane] = maxi(0, int(saved_lane_totals.get(String(lane), 0)))
		sim.lane_processed_today[lane] = maxi(0, int(saved_lane_today.get(String(lane), 0)))
	var saved_unlocks := data.get("campaign_unlocks", {}) as Dictionary
	for unlock_id in DepartmentSimulation.CAMPAIGN_UNLOCKS:
		sim.campaign_unlocks[unlock_id] = bool(saved_unlocks.get(String(unlock_id), false))

	sim._tick_count = maxi(0, int(data.get("tick_count", 0)))
	sim._next_claim_id = maxi(_highest_claim_id() + 1, int(data.get("next_claim_id", 1)))
	sim._rework_total_created = maxi(0, int(data.get("rework_total_created", 0)))
	sim._decision_serial = maxi(0, int(data.get("decision_serial", 0)))
	sim._incident_slot = clampi(int(data.get("incident_slot", 0)), 0, DepartmentSimulation.INCIDENT_MINUTES.size())
	sim._career_seed = restored_career_seed
	sim._incident_rng.state = String(incident_rng_value).to_int()
	sim._incident_bag.assign(restored_incident_bag)
	sim._last_standard_incident_id = restored_last_standard_incident_id
	sim._rng.state = String(data.get("rng_state", str(sim._rng.state))).to_int()
	sim._claim_rng.state = String(data.get("claim_rng_state", str(sim._claim_rng.state))).to_int()
	var modifiers := data.get("decision_modifiers", {}) as Dictionary
	sim._directive_work_multiplier = clampf(float(modifiers.get("directive_work_multiplier", 1.0)), 0.25, 3.0)
	sim._directive_fatigue_multiplier = clampf(float(modifiers.get("directive_fatigue_multiplier", 1.0)), 0.25, 3.0)
	sim._directive_stress_multiplier = clampf(float(modifiers.get("directive_stress_multiplier", 1.0)), 0.25, 3.0)
	sim._directive_morale_drain_multiplier = clampf(float(modifiers.get("directive_morale_drain_multiplier", 1.0)), 0.25, 3.0)
	sim._directive_crack_modifier = clampf(float(modifiers.get("directive_crack_modifier", 0.0)), -0.50, 0.50)
	sim._daily_feed_adjustment_cents = clampi(int(modifiers.get("daily_feed_adjustment_cents", 0)), -100000, 100000)
	sim._incident_work_multiplier = clampf(float(modifiers.get("incident_work_multiplier", 1.0)), 0.25, 3.0)
	sim._incident_strain_multiplier = clampf(float(modifiers.get("incident_strain_multiplier", 1.0)), 0.25, 3.0)
	sim._incident_crack_modifier = clampf(float(modifiers.get("incident_crack_modifier", 0.0)), -0.50, 0.50)
	sim._incident_golden_modifier = clampf(float(modifiers.get("incident_golden_modifier", 0.0)), -0.25, 0.25)
	sim._incident_feed_adjustment_cents = clampi(int(modifiers.get("incident_feed_adjustment_cents", 0)), -100000, 100000)
	sim._pending_quota_adjustment = clampi(int(modifiers.get("pending_quota_adjustment", 0)), -100, 100)
	sim._ensure_active_playbook()
	sim._worker_at_workstation.clear()
	for worker in sim.workers:
		sim._worker_at_workstation[worker.id] = false
	sim._sync_claims_waiting()
	sim.snapshot_changed.emit(sim.snapshot())
	return true


func _migrate_save_state(source: Dictionary) -> Dictionary:
	## Simulation checkpoints are nested inside the campaign save. Keep migration
	## local and pure so a rejected checkpoint cannot partially mutate the office.
	if not sim._is_integral_number(source.get("state_version", null)):
		return {}
	var source_version := int(source.get("state_version", -1))
	var original_source_version := source_version
	if source_version < 1 or source_version > DepartmentSimulation.SAVE_STATE_VERSION:
		return {}
	var migrated := source.duplicate(true)
	while source_version < DepartmentSimulation.SAVE_STATE_VERSION:
		var worker_values: Variant = migrated.get("workers", [])
		if not worker_values is Array:
			return {}
		var migrated_workers: Array[Dictionary] = []
		match source_version:
			1:
				for index in (worker_values as Array).size():
					var worker_value: Variant = (worker_values as Array)[index]
					if not worker_value is Dictionary:
						return {}
					var worker := (worker_value as Dictionary).duplicate(true)
					var worker_id := int(worker.get("id", index))
					worker["career_profile"] = String(ChickenState.default_career_profile(worker_id))
					worker["manager_trust"] = 58.0
					worker["grievance"] = 6.0
					worker["career_xp"] = maxi(0, int(worker.get("eggs_laid", 0))) * 3
					worker["last_personnel_action"] = ""
					worker["last_personnel_action_day"] = 0
					migrated_workers.append(worker)
				migrated["workers"] = migrated_workers
				source_version = 2
				migrated["state_version"] = source_version
			2:
				for index in (worker_values as Array).size():
					var worker_value: Variant = (worker_values as Array)[index]
					if not worker_value is Dictionary:
						return {}
					var worker := (worker_value as Dictionary).duplicate(true)
					worker["employed"] = true
					worker["employment_status"] = String(ChickenState.EMPLOYMENT_STATUS_EMPLOYED)
					worker["available_for_hire_day"] = 0
					worker["hire_count"] = 0
					worker["employment_start_day"] = 1
					migrated_workers.append(worker)
				migrated["workers"] = migrated_workers
				migrated["office_capacity"] = DepartmentSimulation.MAXIMUM_STAFF_CAPACITY
				migrated["wage_arrears_cents"] = 0
				migrated["last_staffing_action"] = {}
				source_version = 3
				migrated["state_version"] = source_version
			3:
				var migrated_stats: Array[Dictionary] = []
				for index in (worker_values as Array).size():
					var worker_value: Variant = (worker_values as Array)[index]
					if not worker_value is Dictionary:
						return {}
					migrated_stats.append({
						"worker_id": int((worker_value as Dictionary).get("id", index)),
						"eggs": 0,
						"sound": 0,
						"cracked": 0,
						"golden": 0,
						"credit_cents": 0,
					})
				migrated["worker_shift_stats"] = migrated_stats
				migrated["last_pecking_order"] = []
				migrated["last_pecking_order_day"] = 0
				migrated["last_credit_allocation"] = {}
				migrated["credit_choice_counts"] = {
					"individual_merit": 0,
					"shared_scoop": 0,
					"management_innovation": 0,
				}
				migrated["golden_dossier_resolved"] = false
				migrated["golden_dossier_day"] = 0
				source_version = 4
				migrated["state_version"] = source_version
			4:
				migrated["peck_assists_used_today"] = 0
				migrated["peck_assist_streak"] = 0
				migrated["best_peck_assist_streak"] = 0
				migrated["last_peck_assist"] = {}
				migrated["priority_credit_today_cents"] = 0
				migrated["priority_credit_total_cents"] = 0
				migrated["assisted_claim_ids"] = []
				migrated["missed_assist_claim_ids"] = []
				migrated["assist_quality_modifiers"] = {}
				migrated["assist_chain_by_claim_id"] = {}
				migrated["flock_restructuring_resolved"] = false
				migrated["flock_restructuring_day"] = 0
				migrated["flock_restructuring_record"] = {}
				source_version = 5
				migrated["state_version"] = source_version
			5:
				migrated["last_flock_petition"] = {}
				migrated["flock_petition_history"] = []
				migrated["active_flock_compact"] = {}
				migrated["last_flock_compact_receipt"] = {}
				migrated["work_to_rule_day"] = 0
				migrated["last_work_to_rule_record"] = {}
				migrated["queued_work_to_rule_day"] = 0
				migrated["queued_work_to_rule_record"] = {}
				source_version = 6
				migrated["state_version"] = source_version
			6:
				for index in (worker_values as Array).size():
					var worker_value: Variant = (worker_values as Array)[index]
					if not worker_value is Dictionary:
						return {}
					var worker := (worker_value as Dictionary).duplicate(true)
					worker["secondary_specialty"] = ""
					worker["cross_training_target"] = ""
					worker["cross_training_worked_this_shift"] = false
					migrated_workers.append(worker)
				migrated["workers"] = migrated_workers
				# Renewable delivery refunds extend the v7 assist ledger without
				# invalidating earlier v7 checkpoints. Legacy schemas preserve their
				# known unavailable charges as gross interventions and invent no refunds.
				migrated["peck_assist_interventions_today"] = maxi(
					0,
					int(migrated.get("peck_assists_used_today", 0)),
				)
				migrated["peck_assist_refunds_today"] = 0
				migrated["last_peck_assist_delivery"] = {}
				migrated["pending_peck_assist_deliveries"] = []
				migrated["settled_peck_assist_delivery_ids"] = []
				source_version = 7
				migrated["state_version"] = source_version
			7:
				# Capital facilities begin unowned. The v7 economy therefore migrates
				# without inventing a purchase, maintenance liability, or quality edge.
				migrated["owned_facilities"] = {
					"candling_rework_bay": 0,
				}
				source_version = 8
				migrated["state_version"] = source_version
			8:
				# The first true building expansion arrives neutral for every v8 file.
				# Validate the formerly strict single-entry ledger before extending it;
				# migration must never launder an unknown facility or invent output.
				var legacy_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not legacy_facilities_value is Dictionary:
					return {}
				var legacy_facilities := legacy_facilities_value as Dictionary
				if legacy_facilities.size() != 1:
					return {}
				var legacy_candling_value: Variant = legacy_facilities.get(
					"candling_rework_bay",
					legacy_facilities.get(&"candling_rework_bay", null),
				)
				if (
					not sim._is_integral_number(legacy_candling_value)
					or int(legacy_candling_value) < 0
					or int(legacy_candling_value) > 1
				):
					return {}
				var migrated_facilities := {
					"candling_rework_bay": int(legacy_candling_value),
				}
				migrated_facilities[String(DepartmentSimulation.PACKING_ANNEX_ID)] = 0
				migrated["owned_facilities"] = migrated_facilities
				migrated["packing_carton_progress"] = 0
				migrated["packing_cartons_today"] = 0
				migrated["packing_cartons_total"] = 0
				migrated["packing_value_bonus_today_cents"] = 0
				migrated["packing_value_bonus_total_cents"] = 0
				migrated["packing_carton_bonus_today_cents"] = 0
				migrated["packing_carton_bonus_total_cents"] = 0
				source_version = 9
				migrated["state_version"] = source_version
			9:
				# First Clutch reinvestment is never inferred for an older campaign.
				# Historical upgrade spend is reconstructable from the immutable level
				# schedule, while today's attribution remains neutral because v9 did not
				# record which shift bought each level.
				var migrated_upgrade_levels := _validated_upgrade_levels(
					migrated.get("upgrade_levels", null),
				)
				if migrated_upgrade_levels.size() != DepartmentSimulation.UPGRADE_ORDER.size():
					return {}
				migrated["first_clutch_reinvestment"] = {}
				migrated["requisition_spend_today_cents"] = 0
				migrated["requisition_spend_total_cents"] = _cumulative_upgrade_spend_cents(
					migrated_upgrade_levels,
				)
				migrated["orientation_procurement_match_today_cents"] = 0
				migrated["orientation_procurement_match_total_cents"] = 0
				source_version = 10
				migrated["state_version"] = source_version
			10:
				# The Records Annex begins unowned and intake history begins neutral.
				# Validate the exact v10 two-facility ledger before extending it so
				# migration cannot launder an unknown building or invented capacity.
				var v10_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v10_facilities_value is Dictionary:
					return {}
				var v10_facilities := v10_facilities_value as Dictionary
				if v10_facilities.size() != 2:
					return {}
				var v10_candling_value: Variant = v10_facilities.get(
					"candling_rework_bay",
					v10_facilities.get(&"candling_rework_bay", null),
				)
				var v10_packing_value: Variant = v10_facilities.get(
					String(DepartmentSimulation.PACKING_ANNEX_ID),
					v10_facilities.get(DepartmentSimulation.PACKING_ANNEX_ID, null),
				)
				if (
					not sim._is_integral_number(v10_candling_value)
					or int(v10_candling_value) < 0
					or int(v10_candling_value) > 1
					or not sim._is_integral_number(v10_packing_value)
					or int(v10_packing_value) < 0
					or int(v10_packing_value) > 3
				):
					return {}
				var v11_facilities := {
					"candling_rework_bay": int(v10_candling_value),
				}
				v11_facilities[String(DepartmentSimulation.PACKING_ANNEX_ID)] = int(v10_packing_value)
				v11_facilities[String(DepartmentSimulation.RECORDS_ANNEX_ID)] = 0
				migrated["owned_facilities"] = v11_facilities
				migrated["intake_rejections_today"] = 0
				migrated["intake_rejections_total"] = 0
				migrated["intake_missed_value_today_cents"] = 0
				migrated["intake_missed_value_total_cents"] = 0
				source_version = 11
				migrated["state_version"] = source_version
			11:
				# Farm Mutual did not exist in v11. Preserve every historical file and
				# cent while adding a neutral market ledger; migration must never infer
				# a signature, a premium, or a breach from ordinary lane throughput.
				migrated["active_market_contract"] = {}
				migrated["market_contract_decline_receipt"] = {}
				migrated["last_market_contract_result"] = {}
				migrated["market_contracts_signed_total"] = 0
				migrated["market_contracts_succeeded_total"] = 0
				migrated["market_contracts_breached_total"] = 0
				migrated["market_contract_premium_today_cents"] = 0
				migrated["market_contract_premium_total_cents"] = 0
				migrated["market_contract_breach_today_cents"] = 0
				migrated["market_contract_breach_total_cents"] = 0
				source_version = 12
				migrated["state_version"] = source_version
			12:
				# Service Coop begins unowned. Standing is derived from the exact v12
				# success/breach totals, so genuine history is grandfathered without
				# minting a second balance. In-flight v12 binders retain level-zero
				# premiums and their formerly legal staffing commitment.
				var v12_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v12_facilities_value is Dictionary:
					return {}
				var v12_facilities := v12_facilities_value as Dictionary
				if v12_facilities.size() != 3:
					return {}
				var v13_facilities: Dictionary = {}
				for legacy_facility_id in [
					&"candling_rework_bay",
					DepartmentSimulation.PACKING_ANNEX_ID,
					DepartmentSimulation.RECORDS_ANNEX_ID,
				]:
					var legacy_level_value: Variant = v12_facilities.get(
						String(legacy_facility_id),
						v12_facilities.get(legacy_facility_id, null),
					)
					if not sim._is_integral_number(legacy_level_value):
						return {}
					var legacy_max := int((DepartmentSimulation.FACILITY_DEFINITIONS[legacy_facility_id] as Dictionary).get("max_level", 1))
					var legacy_level := int(legacy_level_value)
					if legacy_level < 0 or legacy_level > legacy_max:
						return {}
					v13_facilities[String(legacy_facility_id)] = legacy_level
				v13_facilities[String(DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID)] = 0
				migrated["owned_facilities"] = v13_facilities

				var migrated_active_value: Variant = migrated.get("active_market_contract", {})
				if not migrated_active_value is Dictionary:
					return {}
				var migrated_active := (migrated_active_value as Dictionary).duplicate(true)
				if not migrated_active.is_empty():
					var active_offer_id := StringName(migrated_active.get("offer_id", &""))
					if not DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS.has(active_offer_id):
						return {}
					var active_definition := DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS[active_offer_id] as Dictionary
					migrated_active["required_active_staff"] = 0
					migrated_active["legacy_staffing_grandfathered"] = true
					migrated_active["base_premium_cents"] = int(active_definition.get("premium_cents", 0))
					migrated_active["service_coop_level_at_signing"] = 0
					migrated_active["service_coop_bonus_cents"] = 0
					migrated_active["premium_bonus_basis_points"] = 0
				migrated["active_market_contract"] = migrated_active

				var migrated_last_value: Variant = migrated.get("last_market_contract_result", {})
				if not migrated_last_value is Dictionary:
					return {}
				var migrated_last := (migrated_last_value as Dictionary).duplicate(true)
				var seeded_streak := 0
				if not migrated_last.is_empty():
					var last_offer_id := StringName(migrated_last.get("offer_id", &""))
					if not DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS.has(last_offer_id):
						return {}
					var last_definition := DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS[last_offer_id] as Dictionary
					var last_success := bool(migrated_last.get("success", false))
					seeded_streak = 1 if last_success else 0
					var succeeded_total := maxi(0, int(migrated.get("market_contracts_succeeded_total", 0)))
					var breached_total := maxi(0, int(migrated.get("market_contracts_breached_total", 0)))
					var standing_after := maxi(0, 2 * succeeded_total - breached_total)
					var standing_before := (
						maxi(0, 2 * maxi(0, succeeded_total - 1) - breached_total)
						if last_success else
						maxi(0, 2 * succeeded_total - maxi(0, breached_total - 1))
					)
					migrated_last["required_active_staff"] = 0
					migrated_last["base_premium_cents"] = int(last_definition.get("premium_cents", 0))
					migrated_last["service_coop_level_at_signing"] = 0
					migrated_last["service_coop_bonus_cents"] = 0
					migrated_last["contracted_service_coop_bonus_cents"] = 0
					migrated_last["premium_bonus_basis_points"] = 0
					migrated_last["market_standing_before"] = standing_before
					migrated_last["market_standing_after"] = standing_after
					migrated_last["market_standing_delta"] = standing_after - standing_before
					migrated_last["market_standing_rank"] = String(
						&"gold" if standing_after >= 12 else
						(&"silver" if standing_after >= 6 else (&"bronze" if standing_after >= 2 else &"unlisted"))
					)
					migrated_last["clean_contract_streak_before"] = 0
					migrated_last["clean_contract_streak_after"] = seeded_streak
					migrated_last["best_clean_contract_streak"] = seeded_streak
				migrated["last_market_contract_result"] = migrated_last
				migrated["market_clean_contract_streak"] = seeded_streak
				migrated["best_market_clean_contract_streak"] = seeded_streak
				source_version = 13
				migrated["state_version"] = source_version
			13:
				# Seasonal pricing and negotiation begin neutral for every v13 file.
				# Existing signed and settled terms are grandfathered byte-for-byte in
				# money and operations; no historical day is repriced into a season.
				var v13_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v13_facilities_value is Dictionary:
					return {}
				var v13_facilities := v13_facilities_value as Dictionary
				if v13_facilities.size() != 4:
					return {}
				var v14_facilities: Dictionary = {}
				for legacy_facility_id in [
					&"candling_rework_bay",
					DepartmentSimulation.PACKING_ANNEX_ID,
					DepartmentSimulation.RECORDS_ANNEX_ID,
					DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID,
				]:
					var legacy_level_value: Variant = v13_facilities.get(
						String(legacy_facility_id),
						v13_facilities.get(legacy_facility_id, null),
					)
					if not sim._is_integral_number(legacy_level_value):
						return {}
					var legacy_level := int(legacy_level_value)
					var legacy_max := int(
						(DepartmentSimulation.FACILITY_DEFINITIONS[legacy_facility_id] as Dictionary).get("max_level", 1)
					)
					if legacy_level < 0 or legacy_level > legacy_max:
						return {}
					v14_facilities[String(legacy_facility_id)] = legacy_level
				v14_facilities[String(DepartmentSimulation.FARM_MUTUAL_NEGOTIATION_ROOM_ID)] = 0
				migrated["owned_facilities"] = v14_facilities

				var v13_active_value: Variant = migrated.get("active_market_contract", {})
				if not v13_active_value is Dictionary:
					return {}
				migrated["active_market_contract"] = _migrated_v14_active_market_contract(
					v13_active_value as Dictionary
				)
				if (
					not (v13_active_value as Dictionary).is_empty()
					and (migrated["active_market_contract"] as Dictionary).is_empty()
				):
					return {}

				var v13_result_value: Variant = migrated.get("last_market_contract_result", {})
				if not v13_result_value is Dictionary:
					return {}
				migrated["last_market_contract_result"] = _migrated_v14_market_contract_result(
					v13_result_value as Dictionary
				)
				if (
					not (v13_result_value as Dictionary).is_empty()
					and (migrated["last_market_contract_result"] as Dictionary).is_empty()
				):
					return {}
				source_version = 14
				migrated["state_version"] = source_version
			14:
				# v15 adds two neutral cumulative facilities. Validate the exact v14
				# five-key primitive ledger before appending zero levels; every other
				# simulation, worker, contract, quota, and RNG field remains untouched.
				var v14_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v14_facilities_value is Dictionary:
					return {}
				var v14_facilities := v14_facilities_value as Dictionary
				if v14_facilities.size() != DepartmentSimulation.V14_FACILITY_ORDER.size():
					return {}
				var seen_v14_facilities: Dictionary = {}
				var v15_facilities: Dictionary = {}
				for raw_facility_id in v14_facilities:
					var facility_id := StringName(String(raw_facility_id))
					if facility_id not in DepartmentSimulation.V14_FACILITY_ORDER or seen_v14_facilities.has(facility_id):
						return {}
					var level_value: Variant = v14_facilities[raw_facility_id]
					if not sim._is_integral_number(level_value):
						return {}
					var definition := DepartmentSimulation.FACILITY_DEFINITIONS[facility_id] as Dictionary
					var level := int(level_value)
					if level < 0 or level > int(definition.get("max_level", 1)):
						return {}
					seen_v14_facilities[facility_id] = true
					v15_facilities[String(facility_id)] = level
				if seen_v14_facilities.size() != DepartmentSimulation.V14_FACILITY_ORDER.size():
					return {}
				v15_facilities[String(DepartmentSimulation.WELLNESS_NEST_ID)] = 0
				v15_facilities[String(DepartmentSimulation.TRAINING_ROOST_ID)] = 0
				migrated["owned_facilities"] = v15_facilities
				source_version = 15
				migrated["state_version"] = source_version
			15:
				# v16 adds two neutral cumulative operations facilities. Validate the
				# exact seven-key v15 primitive ledger before appending zero levels;
				# no historical supervision, automation, pressure, or payroll is inferred.
				var v15_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v15_facilities_value is Dictionary:
					return {}
				var v15_facilities := v15_facilities_value as Dictionary
				if v15_facilities.size() != DepartmentSimulation.V15_FACILITY_ORDER.size():
					return {}
				var seen_v15_facilities: Dictionary = {}
				var v16_facilities: Dictionary = {}
				for raw_facility_id in v15_facilities:
					var facility_id := StringName(String(raw_facility_id))
					if facility_id not in DepartmentSimulation.V15_FACILITY_ORDER or seen_v15_facilities.has(facility_id):
						return {}
					var level_value: Variant = v15_facilities[raw_facility_id]
					if not sim._is_integral_number(level_value):
						return {}
					var definition := DepartmentSimulation.FACILITY_DEFINITIONS[facility_id] as Dictionary
					var level := int(level_value)
					if level < 0 or level > int(definition.get("max_level", 1)):
						return {}
					seen_v15_facilities[facility_id] = true
					v16_facilities[String(facility_id)] = level
				if seen_v15_facilities.size() != DepartmentSimulation.V15_FACILITY_ORDER.size():
					return {}
				v16_facilities[String(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID)] = 0
				v16_facilities[String(DepartmentSimulation.IT_COOP_ID)] = 0
				migrated["owned_facilities"] = v16_facilities
				var v15_workers_value: Variant = migrated.get("workers", null)
				if not v15_workers_value is Array:
					return {}
				var v15_workers := v15_workers_value as Array
				var migrated_action_serial := 1
				for worker_value in v15_workers:
					if not worker_value is Dictionary:
						return {}
					var worker_record := worker_value as Dictionary
					var action_id := StringName(String(worker_record.get("last_personnel_action", "")))
					worker_record["last_personnel_action_serial"] = (
						migrated_action_serial if action_id != &"" else 0
					)
					if action_id != &"":
						migrated_action_serial += 1
				migrated["workers"] = v15_workers
				source_version = 16
				migrated["state_version"] = source_version
			16:
				# v17 adds one neutral Flock Relations facility and its case ledger. Validate
				# the exact nine-key v16 primitive facility map before extending it so an
				# older checkpoint cannot launder an unknown building or invented casework.
				var v16_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v16_facilities_value is Dictionary:
					return {}
				var v16_facilities := v16_facilities_value as Dictionary
				if v16_facilities.size() != DepartmentSimulation.V16_FACILITY_ORDER.size():
					return {}
				var seen_v16_facilities: Dictionary = {}
				var v17_facilities: Dictionary = {}
				for raw_facility_id in v16_facilities:
					var facility_id := StringName(String(raw_facility_id))
					if facility_id not in DepartmentSimulation.V16_FACILITY_ORDER or seen_v16_facilities.has(facility_id):
						return {}
					var level_value: Variant = v16_facilities[raw_facility_id]
					if not sim._is_integral_number(level_value):
						return {}
					var definition := DepartmentSimulation.FACILITY_DEFINITIONS[facility_id] as Dictionary
					var level := int(level_value)
					if level < 0 or level > int(definition.get("max_level", 1)):
						return {}
					seen_v16_facilities[facility_id] = true
					v17_facilities[String(facility_id)] = level
				if seen_v16_facilities.size() != DepartmentSimulation.V16_FACILITY_ORDER.size():
					return {}
				v17_facilities[String(DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID)] = 0
				migrated["owned_facilities"] = v17_facilities
				migrated["flock_relations_open_cases"] = []
				migrated["flock_relations_resolutions_used_today"] = 0
				migrated["flock_relations_resolved_total"] = 0
				migrated["flock_relations_denied_total"] = 0
				migrated["flock_relations_settlement_spend_total_cents"] = 0
				migrated["last_flock_relations_resolution"] = {}
				migrated["flock_relations_resolution_history"] = []
				migrated["next_flock_relations_case_id"] = 1
				source_version = 17
				migrated["state_version"] = source_version
			17:
				# v18 adds the Flock Provisions Co-op and a neutral FIFO ledger. Validate
				# the exact ten-key v17 facility map before appending the unowned tier;
				# historical saves invent no grain, procurement spend, or spoilage.
				var v17_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v17_facilities_value is Dictionary:
					return {}
				var v17_facilities := v17_facilities_value as Dictionary
				if v17_facilities.size() != DepartmentSimulation.V17_FACILITY_ORDER.size():
					return {}
				var seen_v17_facilities: Dictionary = {}
				var v18_facilities: Dictionary = {}
				for raw_facility_id in v17_facilities:
					var facility_id := StringName(String(raw_facility_id))
					if facility_id not in DepartmentSimulation.V17_FACILITY_ORDER or seen_v17_facilities.has(facility_id):
						return {}
					var level_value: Variant = v17_facilities[raw_facility_id]
					if not sim._is_integral_number(level_value):
						return {}
					var definition := DepartmentSimulation.FACILITY_DEFINITIONS[facility_id] as Dictionary
					var level := int(level_value)
					if level < 0 or level > int(definition.get("max_level", 1)):
						return {}
					seen_v17_facilities[facility_id] = true
					v18_facilities[String(facility_id)] = level
				if seen_v17_facilities.size() != DepartmentSimulation.V17_FACILITY_ORDER.size():
					return {}
				v18_facilities[String(DepartmentSimulation.FEED_PROCUREMENT_COOP_ID)] = 0
				migrated["owned_facilities"] = v18_facilities
				migrated["feed_procurement_state"] = DepartmentSimulation.FeedProcurementStateScript.neutral_save_data(
					clampi(int(migrated.get("day", 1)), 1, 9999)
				)
				source_version = 18
				migrated["state_version"] = source_version
			18:
				# v19 appends the Harvest Credit Gallery and a neutral publicity ledger.
				# Validate the exact eleven-key v18 facility map before extending it;
				# migration invents no campaign, standing, payout, or attribution history.
				var v18_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v18_facilities_value is Dictionary:
					return {}
				var v18_facilities := v18_facilities_value as Dictionary
				if v18_facilities.size() != DepartmentSimulation.V18_FACILITY_ORDER.size():
					return {}
				var seen_v18_facilities: Dictionary = {}
				var v19_facilities: Dictionary = {}
				for raw_facility_id in v18_facilities:
					var facility_id := StringName(String(raw_facility_id))
					if facility_id not in DepartmentSimulation.V18_FACILITY_ORDER or seen_v18_facilities.has(facility_id):
						return {}
					var level_value: Variant = v18_facilities[raw_facility_id]
					if not sim._is_integral_number(level_value):
						return {}
					var definition := DepartmentSimulation.FACILITY_DEFINITIONS[facility_id] as Dictionary
					var level := int(level_value)
					if level < 0 or level > int(definition.get("max_level", 1)):
						return {}
					seen_v18_facilities[facility_id] = true
					v19_facilities[String(facility_id)] = level
				if seen_v18_facilities.size() != DepartmentSimulation.V18_FACILITY_ORDER.size():
					return {}
				v19_facilities[String(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID)] = 0
				migrated["owned_facilities"] = v19_facilities
				migrated["harvest_credit_state"] = DepartmentSimulation.HarvestCreditStateScript.neutral_save_data()
				source_version = 19
				migrated["state_version"] = source_version
			19:
				# v20 appends the Farmgate Dispatch Depot and neutral inventory, mandate,
				# settlement, capital-plan, and commissioning ledgers. No prior egg cash
				# is reclassified, so a v19 checkpoint preserves its exact fund balance.
				var v19_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v19_facilities_value is Dictionary or not sim._is_integral_number(migrated.get("day", null)):
					return {}
				var v19_facilities := v19_facilities_value as Dictionary
				if v19_facilities.size() != DepartmentSimulation.V19_FACILITY_ORDER.size():
					return {}
				var seen_v19_facilities: Dictionary = {}
				var v20_facilities: Dictionary = {}
				for raw_facility_id in v19_facilities:
					var facility_id := StringName(String(raw_facility_id))
					if facility_id not in DepartmentSimulation.V19_FACILITY_ORDER or seen_v19_facilities.has(facility_id):
						return {}
					var level_value: Variant = v19_facilities[raw_facility_id]
					if not sim._is_integral_number(level_value):
						return {}
					var definition := DepartmentSimulation.FACILITY_DEFINITIONS[facility_id] as Dictionary
					var level := int(level_value)
					if level < 0 or level > int(definition.get("max_level", 1)):
						return {}
					seen_v19_facilities[facility_id] = true
					v20_facilities[String(facility_id)] = level
				if seen_v19_facilities.size() != DepartmentSimulation.V19_FACILITY_ORDER.size():
					return {}
				v20_facilities[String(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID)] = 0
				migrated["owned_facilities"] = v20_facilities
				migrated["farmgate_dispatch_state"] = DepartmentSimulation.FarmgateDispatchStateScript.neutral_save_data(
					int(migrated["day"])
				)
				migrated["pinned_capital_plan_id"] = ""
				migrated["last_facility_purchase_receipt"] = {}
				migrated["facility_commissioning_history"] = []
				source_version = 20
				migrated["state_version"] = source_version
			20:
				# v21 adds the North Meadow parcel, service, placement, and receipt
				# ledger. The facility catalog is unchanged. A v20 checkpoint may not
				# smuggle invented campus ownership through the neutral migration.
				if migrated.has("campus_expansion"):
					# A checkpoint that identifies itself as v20 must not smuggle
					# v21 ownership. Older migration fixtures historically retain
					# later-schema fields while walking multiple pure migrations, so
					# discard that unknown field and still create the exact neutral v21
					# ledger when the original source genuinely predates v20.
					if original_source_version == 20:
						return {}
					migrated.erase("campus_expansion")
				var v20_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v20_facilities_value is Dictionary:
					return {}
				var v20_facilities := v20_facilities_value as Dictionary
				if v20_facilities.size() != DepartmentSimulation.V20_FACILITY_ORDER.size():
					return {}
				var seen_v20_facilities: Dictionary = {}
				for raw_facility_id in v20_facilities:
					var facility_id := StringName(String(raw_facility_id))
					if facility_id not in DepartmentSimulation.V20_FACILITY_ORDER or seen_v20_facilities.has(facility_id):
						return {}
					var level_value: Variant = v20_facilities[raw_facility_id]
					if not sim._is_integral_number(level_value):
						return {}
					var definition := DepartmentSimulation.FACILITY_DEFINITIONS[facility_id] as Dictionary
					var level := int(level_value)
					if level < 0 or level > int(definition.get("max_level", 1)):
						return {}
					seen_v20_facilities[facility_id] = true
				if seen_v20_facilities.size() != DepartmentSimulation.V20_FACILITY_ORDER.size():
					return {}
				migrated["campus_expansion"] = _neutral_campus_expansion_state()
				source_version = 21
				migrated["state_version"] = source_version
			21:
				# v22 introduces the two-parcel campus portfolio as a neutral, exact
				# construction ledger. A claimed v21 file may not smuggle later deeds,
				# modules, staffing, or receipts through migration.
				if migrated.has("campus_portfolio"):
					if original_source_version == 21:
						return {}
					migrated.erase("campus_portfolio")
				if not sim._is_integral_number(migrated.get("day", null)):
					return {}
				migrated["campus_portfolio"] = DepartmentSimulation.CampusPortfolioStateScript.neutral_save_data(
					int(migrated["day"])
				)
				source_version = 22
				migrated["state_version"] = source_version
			22:
				# v23 adds the conserving Farm Treasury. A legacy checkpoint knew
				# only its current Feed Fund, so migration preserves that exact cash
				# and invents no credit, invoices, interest, rating, or journal history.
				if migrated.has("farm_treasury_state"):
					if original_source_version == 22:
						return {}
					migrated.erase("farm_treasury_state")
				if (
					not sim._is_integral_number(migrated.get("day", null))
					or not sim._is_integral_number(migrated.get("revenue_cents", null))
				):
					return {}
				var migrated_day := int(migrated["day"])
				var migrated_cash := int(migrated["revenue_cents"])
				if (
					migrated_day < 1 or migrated_day > 9999
					or migrated_cash < 0 or migrated_cash > 2_000_000_000
				):
					return {}
				migrated["farm_treasury_state"] = DepartmentSimulation.FarmTreasuryStateScript.neutral_save_data(
					migrated_cash,
					maxi(0, migrated_day - 1),
				)
				source_version = 23
				migrated["state_version"] = source_version
			23:
				# v24 gives each career a persisted incident docket. A v23 career had
				# the original fixed seed, so migration preserves that identity and
				# derives a fresh independent incident stream without touching claims,
				# workers, money, or the currently pending decision.
				for docket_field in [
					"career_seed",
					"incident_rng_state",
					"incident_bag",
					"last_standard_incident_id",
				]:
					if migrated.has(docket_field):
						if original_source_version == 23:
							return {}
						migrated.erase(docket_field)
				var migrated_incident_rng := RandomNumberGenerator.new()
				migrated_incident_rng.seed = 1701 + DepartmentSimulation.INCIDENT_DOCKET_SEED_OFFSET
				var migrated_last_incident := &""
				var migrated_pending_value: Variant = migrated.get("pending_decision", {})
				if migrated_pending_value is Dictionary:
					var migrated_pending_id := StringName(String(
						(migrated_pending_value as Dictionary).get("id", "")
					))
					if migrated_pending_id in DepartmentSimulation.INCIDENT_ORDER:
						migrated_last_incident = migrated_pending_id
				migrated["career_seed"] = 1701
				migrated["incident_rng_state"] = str(migrated_incident_rng.state)
				migrated["incident_bag"] = []
				migrated["last_standard_incident_id"] = String(migrated_last_incident)
				source_version = 24
				migrated["state_version"] = source_version
			24:
				# v25 makes the already-funded supervisor posts named and controllable.
				# Legacy office levels receive the default post for each funded seat, so
				# payroll, action capacity, cash, worker state, and chronology are unchanged.
				var facilities_value: Variant = migrated.get("owned_facilities", null)
				if not facilities_value is Dictionary:
					return {}
				var facilities := facilities_value as Dictionary
				var rooster_level_value: Variant = facilities.get(
					String(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID), facilities.get(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID, null)
				)
				if not sim._is_integral_number(rooster_level_value):
					return {}
				var roster_count := clampi(int(rooster_level_value) + 1, 1, 4)
				var migrated_roster: Array[Dictionary] = []
				for slot_index in roster_count:
					migrated_roster.append(sim._new_manager_record(
						DepartmentSimulation.MANAGER_DEFAULT_HIRE_ORDER[slot_index], slot_index, 1
					))
				migrated["manager_roster_version"] = DepartmentSimulation.MANAGER_ROSTER_VERSION
				migrated["manager_roster"] = migrated_roster
				migrated["last_manager_action"] = {}
				migrated["management_reports_today"] = 0
				migrated["management_reports_total"] = 0
				migrated["management_visibility_today"] = 0
				source_version = 25
				migrated["state_version"] = source_version
			25:
				# v26 records only authored incident and response identifiers. A v25
				# checkpoint has no trustworthy evidence of earlier choices, so migration
				# starts with neutral case memory instead of inventing a history.
				if migrated.has("incident_response_history"):
					if original_source_version == 25:
						return {}
					migrated.erase("incident_response_history")
				migrated["incident_response_history"] = []
				source_version = 26
				migrated["state_version"] = source_version
			26:
				# v27 files the first verified counterweight pivot in each connected
				# incident pair. Authentic v26 response history can reconstruct those
				# receipts exactly; a claimed v26 file may not smuggle future authority.
				if migrated.has("incident_pivot_mastery_receipts"):
					if original_source_version == 26:
						return {}
					migrated.erase("incident_pivot_mastery_receipts")
				var migrated_history_value: Variant = migrated.get("incident_response_history", null)
				if not migrated_history_value is Array:
					return {}
				migrated["incident_pivot_mastery_receipts"] = _incident_pivot_receipts_from_history(
					migrated_history_value as Array
				)
				source_version = 27
				migrated["state_version"] = source_version
			27:
				# v28 opens the Bright-Eyed Rotation with a neutral, empty cohort.
				# Older careers gain no capacity, speed, fellow, or fabricated term
				# history until the player explicitly files an internship.
				if migrated.has("internship_program_state"):
					if original_source_version == 27:
						return {}
					migrated.erase("internship_program_state")
				migrated["internship_program_state"] = (
					DepartmentSimulation.InternshipProgramStateScript.neutral_save_data()
				)
				source_version = 28
				migrated["state_version"] = source_version
			28:
				# v29 makes the tray-dispatch skill chain authoritative. Earlier
				# careers begin neutral; no routing judgment can be inferred safely.
				for field in [
					"routing_momentum_chain",
					"best_routing_momentum_chain",
					"routing_momentum_peck_recharge_bank",
					"routing_momentum_peck_recharges_used_today",
					"routing_momentum_golden_charges",
				]:
					if migrated.has(field):
						if original_source_version == 28:
							return {}
						migrated.erase(field)
					migrated[field] = 0
				migrated["last_routing_dispatch"] = {}
				migrated["routing_momentum_free_assist_claim_ids"] = []
				source_version = 29
				migrated["state_version"] = source_version
			29:
				# v30 binds the banked x5 reward to one active authoritative file.
				# Existing careers keep the charge but wait for the next live claim.
				for field in [
					"routing_momentum_golden_target_claim_id",
					"routing_momentum_golden_target_worker_id",
				]:
					if migrated.has(field):
						if original_source_version == 29:
							return {}
						migrated.erase(field)
					migrated[field] = -1
				source_version = 30
				migrated["state_version"] = source_version
			_:
				return {}
	return migrated


func _migrated_v14_active_market_contract(source: Dictionary) -> Dictionary:
	if source.is_empty():
		return {}
	var offer_id := StringName(String(source.get("offer_id", "")))
	if not DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS.has(offer_id):
		return {}
	var target_day := int(source.get("target_day", source.get("signed_day", 0)))
	var service_coop_level := int(source.get("service_coop_level_at_signing", 0))
	var quote := sim._market_contract_quote_for_day(
		offer_id,
		target_day,
		service_coop_level,
		0,
		&"standard_terms",
		true,
	)
	if quote.is_empty():
		return {}
	var migrated := quote.duplicate(true)
	migrated.merge(source.duplicate(true), true)
	var migrated_schedules := _migrated_v14_market_contract_schedules(
		source.get("scheduled_claims", null),
		quote.get("scheduled_claims", null),
	)
	if migrated_schedules.size() != (quote.get("scheduled_claims", []) as Array).size():
		return {}
	migrated["scheduled_claims"] = migrated_schedules
	var base_premium_cents := int(source.get("base_premium_cents", -1))
	var contracted_service_bonus_cents := int(source.get("service_coop_bonus_cents", -1))
	var contracted_premium_cents := int(source.get("premium_cents", -1))
	var contracted_breach_cents := int(source.get("breach_cents", -1))
	var neutral_season := sim._neutral_market_season_for_day(target_day)
	migrated.merge({
		"version": 2,
		"legacy_terms_grandfathered": true,
		"season": neutral_season,
		"season_id": &"baseline_neutral",
		"season_label": "BASELINE NEUTRAL BOOK",
		"season_demand_basis_points": 0,
		"clause_id": &"standard_terms",
		"clause_label": "STANDARD TERMS",
		"clause_summary": String(
			(DepartmentSimulation.MARKET_CONTRACT_CLAUSE_DEFINITIONS[&"standard_terms"] as Dictionary).get("summary", "")
		),
		"clause_category": &"standard",
		"category": &"standard",
		"label": "STANDARD TERMS",
		"summary": String(
			(DepartmentSimulation.MARKET_CONTRACT_CLAUSE_DEFINITIONS[&"standard_terms"] as Dictionary).get("summary", "")
		),
		"requires_negotiation_room": false,
		"clause_available": true,
		"negotiation_room_level_at_signing": 0,
		"authored_base_premium_cents": base_premium_cents,
		"base_premium_cents": base_premium_cents,
		"season_premium_delta_cents": 0,
		"clause_premium_basis_points": 0,
		"clause_premium_delta_cents": 0,
		"market_premium_cents": base_premium_cents,
		"contracted_service_coop_bonus_cents": contracted_service_bonus_cents,
		"contracted_premium_cents": contracted_premium_cents,
		"authored_breach_cents": contracted_breach_cents,
		"season_breach_basis_points": 0,
		"season_breach_delta_cents": 0,
		"clause_breach_basis_points": 0,
		"clause_breach_delta_cents": 0,
		"contracted_breach_cents": contracted_breach_cents,
		"welfare_gate_minimum": 0,
		"welfare_gate_required": false,
	}, true)
	return migrated


func _migrated_v14_market_contract_result(source: Dictionary) -> Dictionary:
	if source.is_empty():
		return {}
	var offer_id := StringName(String(source.get("offer_id", "")))
	if not DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS.has(offer_id):
		return {}
	var target_day := int(source.get("target_day", source.get("day", 0)))
	var service_coop_level := int(source.get("service_coop_level_at_signing", 0))
	var quote := sim._market_contract_quote_for_day(
		offer_id,
		target_day,
		service_coop_level,
		0,
		&"standard_terms",
		true,
	)
	if quote.is_empty():
		return {}
	var migrated := source.duplicate(true)
	var migrated_schedules := _migrated_v14_market_contract_schedules(
		source.get("scheduled_claims", null),
		quote.get("scheduled_claims", null),
	)
	if migrated_schedules.size() != (quote.get("scheduled_claims", []) as Array).size():
		return {}
	var migrated_claim_ids: Array[int] = []
	var migrated_accepted_ids: Array[int] = []
	var migrated_rejected_ids: Array[int] = []
	for schedule in migrated_schedules:
		if (
			not sim._is_integral_number(schedule.get("claim_id", null))
			or typeof(schedule.get("released", null)) != TYPE_BOOL
			or typeof(schedule.get("rejected", null)) != TYPE_BOOL
		):
			return {}
		var claim_id := int(schedule.get("claim_id", -1))
		migrated_claim_ids.append(claim_id)
		if bool(schedule.get("released", false)):
			migrated_accepted_ids.append(claim_id)
		elif bool(schedule.get("rejected", false)):
			migrated_rejected_ids.append(claim_id)
	var base_premium_cents := int(source.get("base_premium_cents", -1))
	var contracted_service_bonus_cents := int(
		source.get("contracted_service_coop_bonus_cents", -1)
	)
	var authored_breach_cents := int(
		(DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS[offer_id] as Dictionary).get("breach_cents", -1)
	)
	var neutral_season := sim._neutral_market_season_for_day(target_day)
	migrated.merge({
		"version": 2,
		"legacy_terms_grandfathered": true,
		"season": neutral_season,
		"season_id": &"baseline_neutral",
		"season_label": "BASELINE NEUTRAL BOOK",
		"season_demand_basis_points": 0,
		"clause_id": &"standard_terms",
		"clause_label": "STANDARD TERMS",
		"clause_summary": String(
			(DepartmentSimulation.MARKET_CONTRACT_CLAUSE_DEFINITIONS[&"standard_terms"] as Dictionary).get("summary", "")
		),
		"clause_category": &"standard",
		"negotiation_room_level_at_signing": 0,
		"authored_service_window_minutes": int(quote.get("authored_service_window_minutes", 0)),
		"service_window_minutes": int(quote.get("service_window_minutes", 0)),
		"authored_dominant_lane": String(quote.get("authored_dominant_lane", "")),
		"authored_lane_mix": (quote.get("authored_lane_mix", {}) as Dictionary).duplicate(true),
		"lane_mix": (quote.get("lane_mix", {}) as Dictionary).duplicate(true),
		"arrival_batches": (quote.get("arrival_batches", []) as Array).duplicate(true),
		"scheduled_claims": migrated_schedules,
		"claim_ids": migrated_claim_ids,
		"accepted_claim_ids": migrated_accepted_ids,
		"rejected_claim_ids": migrated_rejected_ids,
		"authored_base_premium_cents": base_premium_cents,
		"base_premium_cents": base_premium_cents,
		"season_premium_delta_cents": 0,
		"clause_premium_basis_points": 0,
		"clause_premium_delta_cents": 0,
		"market_premium_cents": base_premium_cents,
		"contracted_premium_cents": base_premium_cents + contracted_service_bonus_cents,
		"authored_breach_cents": authored_breach_cents,
		"season_breach_basis_points": 0,
		"season_breach_delta_cents": 0,
		"clause_breach_basis_points": 0,
		"clause_breach_delta_cents": 0,
		"contracted_breach_cents": authored_breach_cents,
		"delivery_threshold_met": (
			int(source.get("timely_sound_completed", -1))
			>= int(source.get("required_completed", 0))
		),
		"welfare_gate_met": true,
		"closing_welfare": 0,
		"welfare_gate_minimum": 0,
		"welfare_gate_required": false,
	}, true)
	return migrated


func _migrated_v14_market_contract_schedules(
	source_value: Variant,
	authored_value: Variant
) -> Array[Dictionary]:
	var migrated: Array[Dictionary] = []
	if not source_value is Array or not authored_value is Array:
		return migrated
	var source := source_value as Array
	var authored := authored_value as Array
	if source.size() != authored.size():
		return migrated
	for index in authored.size():
		if not source[index] is Dictionary or not authored[index] is Dictionary:
			migrated.clear()
			return migrated
		var schedule := (source[index] as Dictionary).duplicate(true)
		var authored_schedule := authored[index] as Dictionary
		schedule["authored_lane"] = String(authored_schedule.get("authored_lane", ""))
		schedule["authored_rush"] = bool(authored_schedule.get("authored_rush", false))
		migrated.append(schedule)
	return migrated


func _validated_market_contract_id_array(value: Variant) -> Dictionary:
	if not value is Array:
		return {"valid": false, "ids": []}
	var source := value as Array
	if source.size() > DepartmentSimulation.MARKET_CONTRACT_MAX_CLAIMS:
		return {"valid": false, "ids": []}
	var ids: Array[int] = []
	var seen: Dictionary[int, bool] = {}
	for id_value in source:
		if not sim._is_integral_number(id_value):
			return {"valid": false, "ids": []}
		var claim_id := int(id_value)
		if claim_id < 1 or claim_id > 2_000_000_000 or seen.has(claim_id):
			return {"valid": false, "ids": []}
		seen[claim_id] = true
		ids.append(claim_id)
	return {"valid": true, "ids": ids}


func _market_contract_same_id_order(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	for index in left.size():
		if int(left[index]) != int(right[index]):
			return false
	return true


func _market_contract_lane_mix_matches(value: Variant, authored: Dictionary) -> bool:
	if not value is Dictionary:
		return false
	var source := value as Dictionary
	if source.size() != authored.size():
		return false
	for lane in DepartmentSimulation.CLAIM_LANES:
		var lane_key := String(lane)
		var authored_count := int(authored.get(lane_key, authored.get(lane, 0)))
		var count_value: Variant = source.get(lane_key, source.get(lane, null))
		if authored_count == 0:
			if count_value != null:
				return false
			continue
		if not sim._is_integral_number(count_value) or int(count_value) != authored_count:
			return false
	return true


func _market_contract_arrival_batches_match(value: Variant, authored_value: Variant) -> bool:
	if not value is Array or not authored_value is Array:
		return false
	var source := value as Array
	var authored := authored_value as Array
	if source.size() != authored.size():
		return false
	for index in authored.size():
		var batch_value: Variant = source[index]
		var authored_batch_value: Variant = authored[index]
		if not batch_value is Dictionary or not authored_batch_value is Dictionary:
			return false
		var batch := batch_value as Dictionary
		var authored_batch := authored_batch_value as Dictionary
		for field in ["batch_index", "minute_of_day", "deadline_minute_of_day", "count"]:
			if (
				not sim._is_integral_number(batch.get(field, null))
				or int(batch.get(field, -1)) != int(authored_batch.get(field, -2))
			):
				return false
		for field in ["time", "deadline_time"]:
			if String(batch.get(field, "")) != String(authored_batch.get(field, "")):
				return false
		if typeof(batch.get("rush", null)) != TYPE_BOOL:
			return false
		if bool(batch.get("rush", false)) != bool(authored_batch.get("rush", false)):
			return false
		var lanes_value: Variant = batch.get("lanes", null)
		var authored_lanes_value: Variant = authored_batch.get("lanes", null)
		if not lanes_value is Array or not authored_lanes_value is Array:
			return false
		var lanes := lanes_value as Array
		var authored_lanes := authored_lanes_value as Array
		if lanes.size() != authored_lanes.size():
			return false
		for lane_index in authored_lanes.size():
			if String(lanes[lane_index]) != String(authored_lanes[lane_index]):
				return false
		if not _market_contract_lane_mix_matches(
			batch.get("lane_mix", null),
			authored_batch.get("lane_mix", {}) as Dictionary,
		):
			return false
	return true


func _market_contract_season_matches(value: Variant, expected: Dictionary) -> bool:
	if not value is Dictionary:
		return false
	var source := value as Dictionary
	for field in ["id", "label", "short_label", "summary"]:
		if String(source.get(field, "")) != String(expected.get(field, "")):
			return false
	for field in [
		"target_day", "season_index", "quarter", "year", "start_day", "end_day",
		"days_remaining",
	]:
		if (
			not sim._is_integral_number(source.get(field, null))
			or int(source.get(field, -99999)) != int(expected.get(field, -99998))
		):
			return false
	var demand_value: Variant = source.get("lane_demand_basis_points", null)
	if not demand_value is Dictionary:
		return false
	var demand := demand_value as Dictionary
	var expected_demand := expected.get("lane_demand_basis_points", {}) as Dictionary
	if demand.size() != DepartmentSimulation.CLAIM_LANES.size():
		return false
	for lane in DepartmentSimulation.CLAIM_LANES:
		var lane_key := String(lane)
		var demand_basis_points: Variant = demand.get(lane_key, demand.get(lane, null))
		if (
			not sim._is_integral_number(demand_basis_points)
			or int(demand_basis_points) != int(expected_demand.get(lane_key, 0))
		):
			return false
	return true


func _active_market_contract_quote_matches(
	source: Dictionary,
	expected: Dictionary,
	legacy_terms_grandfathered: bool
) -> bool:
	var has_pricing_terms := source.has("pricing_profile_id")
	for field in [
		"authored_service_window_minutes",
		"service_window_minutes",
		"season_demand_basis_points",
		"negotiation_room_level_at_signing",
		"authored_base_premium_cents",
		"base_premium_cents",
		"season_premium_delta_cents",
		"clause_premium_basis_points",
		"clause_premium_delta_cents",
		"market_premium_cents",
		"service_coop_level_at_signing",
		"service_coop_bonus_cents",
		"contracted_service_coop_bonus_cents",
		"premium_bonus_basis_points",
		"contracted_premium_cents",
		"premium_cents",
		"authored_breach_cents",
		"season_breach_basis_points",
		"season_breach_delta_cents",
		"clause_breach_basis_points",
		"clause_breach_delta_cents",
		"contracted_breach_cents",
		"breach_cents",
		"welfare_gate_minimum",
	]:
		if (
			not sim._is_integral_number(source.get(field, null))
			or int(source.get(field, -999999)) != int(expected.get(field, -999998))
		):
			return false
	if has_pricing_terms:
		for field in [
			"pricing_premium_basis_points",
			"pricing_premium_delta_cents",
			"pricing_volume_delta",
			"pricing_required_delta",
			"pricing_required_reach",
			"claimant_satisfaction_success_delta",
			"claimant_satisfaction_breach_delta",
			"market_reach_success_delta",
			"market_reach_breach_delta",
			"estimated_handling_cost_cents",
			"estimated_margin_cents",
			"estimated_margin_per_file_cents",
		]:
			if (
				not sim._is_integral_number(source.get(field, null))
				or int(source.get(field, -999999)) != int(expected.get(field, -999998))
			):
				return false
		if (
			source.has("pricing_required_satisfaction")
			and (
				not sim._is_integral_number(source.get("pricing_required_satisfaction", null))
				or int(source.get("pricing_required_satisfaction", -1))
				!= int(expected.get("pricing_required_satisfaction", -2))
			)
		):
			return false
		for field in ["pricing_profile_id", "pricing_label", "pricing_summary"]:
			if String(source.get(field, "")) != String(expected.get(field, "")):
				return false
	for field in [
		"quote_id", "season_id", "season_label", "clause_id", "clause_label",
		"clause_summary", "clause_category", "category", "label", "summary",
		"authored_dominant_lane",
	]:
		if String(source.get(field, "")) != String(expected.get(field, "")):
			return false
	for field in [
		"requires_negotiation_room", "clause_available", "welfare_gate_required",
	]:
		if (
			typeof(source.get(field, null)) != TYPE_BOOL
			or bool(source.get(field, false)) != bool(expected.get(field, false))
		):
			return false
	if not _market_contract_season_matches(
		source.get("season", null),
		expected.get("season", {}) as Dictionary,
	):
		return false
	if not _market_contract_lane_mix_matches(
		source.get("authored_lane_mix", null),
		expected.get("authored_lane_mix", {}) as Dictionary,
	):
		return false
	if legacy_terms_grandfathered:
		if (
			String(source.get("season_id", "")) != "baseline_neutral"
			or String(source.get("clause_id", "")) != "standard_terms"
			or int(source.get("negotiation_room_level_at_signing", -1)) != 0
			or int(source.get("season_demand_basis_points", 1)) != 0
			or int(source.get("season_premium_delta_cents", 1)) != 0
			or int(source.get("clause_premium_delta_cents", 1)) != 0
			or int(source.get("season_breach_delta_cents", 1)) != 0
			or int(source.get("clause_breach_delta_cents", 1)) != 0
		):
			return false
	return true


func _market_contract_result_quote_matches(
	source: Dictionary,
	expected: Dictionary,
	legacy_terms_grandfathered: bool
) -> bool:
	var has_pricing_terms := source.has("pricing_profile_id")
	for field in [
		"authored_service_window_minutes",
		"service_window_minutes",
		"season_demand_basis_points",
		"negotiation_room_level_at_signing",
		"authored_base_premium_cents",
		"base_premium_cents",
		"season_premium_delta_cents",
		"clause_premium_basis_points",
		"clause_premium_delta_cents",
		"market_premium_cents",
		"service_coop_level_at_signing",
		"contracted_service_coop_bonus_cents",
		"premium_bonus_basis_points",
		"contracted_premium_cents",
		"authored_breach_cents",
		"season_breach_basis_points",
		"season_breach_delta_cents",
		"clause_breach_basis_points",
		"clause_breach_delta_cents",
		"contracted_breach_cents",
		"welfare_gate_minimum",
	]:
		if (
			not sim._is_integral_number(source.get(field, null))
			or int(source.get(field, -999999)) != int(expected.get(field, -999998))
		):
			return false
	if has_pricing_terms:
		for field in [
			"pricing_premium_basis_points",
			"pricing_premium_delta_cents",
			"pricing_volume_delta",
			"pricing_required_delta",
			"pricing_required_reach",
			"claimant_satisfaction_success_delta",
			"claimant_satisfaction_breach_delta",
			"market_reach_success_delta",
			"market_reach_breach_delta",
			"estimated_handling_cost_cents",
			"estimated_margin_cents",
			"estimated_margin_per_file_cents",
		]:
			if (
				not sim._is_integral_number(source.get(field, null))
				or int(source.get(field, -999999)) != int(expected.get(field, -999998))
			):
				return false
		if (
			source.has("pricing_required_satisfaction")
			and (
				not sim._is_integral_number(source.get("pricing_required_satisfaction", null))
				or int(source.get("pricing_required_satisfaction", -1))
				!= int(expected.get("pricing_required_satisfaction", -2))
			)
		):
			return false
		for field in ["pricing_profile_id", "pricing_label", "pricing_summary"]:
			if String(source.get(field, "")) != String(expected.get(field, "")):
				return false
	for field in [
		"season_id", "season_label", "clause_id", "clause_label", "clause_summary",
		"clause_category", "authored_dominant_lane",
	]:
		if String(source.get(field, "")) != String(expected.get(field, "")):
			return false
	if not _market_contract_season_matches(
		source.get("season", null),
		expected.get("season", {}) as Dictionary,
	):
		return false
	if not _market_contract_lane_mix_matches(
		source.get("authored_lane_mix", null),
		expected.get("authored_lane_mix", {}) as Dictionary,
	) or not _market_contract_lane_mix_matches(
		source.get("lane_mix", null),
		expected.get("lane_mix", {}) as Dictionary,
	):
		return false
	if not _market_contract_arrival_batches_match(
		source.get("arrival_batches", null),
		expected.get("arrival_batches", null),
	):
		return false
	if not _market_contract_result_schedules_match(
		source.get("scheduled_claims", null),
		expected.get("scheduled_claims", null),
	):
		return false
	if legacy_terms_grandfathered and (
		String(source.get("season_id", "")) != "baseline_neutral"
		or String(source.get("clause_id", "")) != "standard_terms"
		or int(source.get("negotiation_room_level_at_signing", -1)) != 0
		or int(source.get("season_demand_basis_points", 1)) != 0
		or int(source.get("season_premium_delta_cents", 1)) != 0
		or int(source.get("clause_premium_delta_cents", 1)) != 0
		or int(source.get("season_breach_delta_cents", 1)) != 0
		or int(source.get("clause_breach_delta_cents", 1)) != 0
	):
		return false
	return true


func _market_contract_result_schedules_match(value: Variant, expected_value: Variant) -> bool:
	if not value is Array or not expected_value is Array:
		return false
	var source := value as Array
	var expected := expected_value as Array
	if source.size() != expected.size():
		return false
	var previous_claim_id := -1
	for index in expected.size():
		if not source[index] is Dictionary or not expected[index] is Dictionary:
			return false
		var schedule := source[index] as Dictionary
		var expected_schedule := expected[index] as Dictionary
		for field in [
			"batch_index", "arrival_minute_of_day", "deadline_minute_of_day",
			"service_window_minutes",
		]:
			if (
				not sim._is_integral_number(schedule.get(field, null))
				or int(schedule.get(field, -1)) != int(expected_schedule.get(field, -2))
			):
				return false
		for field in ["lane", "authored_lane", "arrival_time", "deadline_time"]:
			if String(schedule.get(field, "")) != String(expected_schedule.get(field, "")):
				return false
		for field in ["rush", "authored_rush"]:
			if (
				typeof(schedule.get(field, null)) != TYPE_BOOL
				or bool(schedule.get(field, false)) != bool(expected_schedule.get(field, false))
			):
				return false
		if (
			not sim._is_integral_number(schedule.get("claim_id", null))
			or typeof(schedule.get("released", null)) != TYPE_BOOL
			or typeof(schedule.get("rejected", null)) != TYPE_BOOL
		):
			return false
		var claim_id := int(schedule.get("claim_id", -1))
		var released := bool(schedule.get("released", false))
		var rejected := bool(schedule.get("rejected", false))
		if (
			claim_id < 1
			or claim_id > 2_000_000_000
			or (index > 0 and claim_id != previous_claim_id + 1)
			or released == rejected
		):
			return false
		previous_claim_id = claim_id
	return true


func _validated_active_market_contract(
	value: Variant,
	saved_day: int,
	saved_phase: int,
	saved_minute: int,
	restored_service_coop_level: int,
	restored_negotiation_room_level: int
) -> Dictionary:
	var invalid := {"valid": false, "record": {}}
	if not value is Dictionary:
		return invalid
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	if (
		saved_day < DepartmentSimulation.CONTRACT_BOARD_UNLOCK_DAY
		or saved_phase not in [
			DepartmentSimulation.ShiftPhase.REVIEW,
			DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE,
			DepartmentSimulation.ShiftPhase.RUNNING,
			DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT,
		]
		or saved_minute < DepartmentSimulation.SHIFT_START_MINUTE
		or saved_minute > DepartmentSimulation.SHIFT_END_MINUTE
	):
		return invalid
	var offer_id := StringName(String(source.get("offer_id", "")))
	if offer_id not in DepartmentSimulation.MARKET_CONTRACT_OFFER_ORDER:
		return invalid
	if not sim._is_integral_number(source.get("version", null)) or int(source.get("version", 0)) != 2:
		return invalid
	if typeof(source.get("legacy_terms_grandfathered", null)) != TYPE_BOOL:
		return invalid
	var legacy_terms_grandfathered := bool(source.get("legacy_terms_grandfathered", false))
	var clause_id := StringName(String(source.get("clause_id", "")))
	if clause_id not in DepartmentSimulation.MARKET_CONTRACT_CLAUSE_ORDER:
		return invalid
	var pricing_id := StringName(String(source.get("pricing_profile_id", "mutual_rate")))
	if pricing_id not in DepartmentSimulation.MARKET_PRICING_PROFILE_ORDER:
		return invalid
	for frozen_level_field in [
		"service_coop_level_at_signing",
		"negotiation_room_level_at_signing",
	]:
		if not sim._is_integral_number(source.get(frozen_level_field, null)):
			return invalid
	var service_coop_level_at_signing := int(source.get("service_coop_level_at_signing", -1))
	var negotiation_room_level_at_signing := int(
		source.get("negotiation_room_level_at_signing", -1)
	)
	if (
		service_coop_level_at_signing < 0
		or service_coop_level_at_signing > restored_service_coop_level
		or service_coop_level_at_signing > 3
		or negotiation_room_level_at_signing < 0
		or negotiation_room_level_at_signing > restored_negotiation_room_level
		or negotiation_room_level_at_signing > 1
		or (clause_id != &"standard_terms" and negotiation_room_level_at_signing != 1)
		or (
			legacy_terms_grandfathered
			and (
				clause_id != &"standard_terms"
				or negotiation_room_level_at_signing != 0
			)
		)
	):
		return invalid
	var authored := sim._market_contract_quote_for_day(
		offer_id,
		saved_day,
		service_coop_level_at_signing,
		negotiation_room_level_at_signing,
		clause_id,
		legacy_terms_grandfathered,
		pricing_id,
	)
	if authored.is_empty() or not _active_market_contract_quote_matches(
		source,
		authored,
		legacy_terms_grandfathered,
	):
		return invalid
	var expected_contract_id := "FM-%04d-%s" % [saved_day, String(offer_id).to_upper()]
	if (
		String(source.get("contract_id", "")) != expected_contract_id
		or String(source.get("id", "")) != String(offer_id)
	):
		return invalid
	for field in ["signed_day", "target_day", "deadline_day"]:
		if not sim._is_integral_number(source.get(field, null)) or int(source.get(field, 0)) != saved_day:
			return invalid
	for field in [
		"required_claim_capacity",
		"required_completed",
		"total_claims",
		"rush_claims",
		"service_window_minutes",
		"breach_cents",
	]:
		if (
			not sim._is_integral_number(source.get(field, null))
			or int(source.get(field, -1)) != int(authored.get(field, -2))
		):
			return invalid
	for field in [
		"required_active_staff",
		"base_premium_cents",
		"service_coop_level_at_signing",
		"service_coop_bonus_cents",
		"premium_bonus_basis_points",
		"premium_cents",
	]:
		if not sim._is_integral_number(source.get(field, null)):
			return invalid
	if typeof(source.get("legacy_staffing_grandfathered", null)) != TYPE_BOOL:
		return invalid
	var legacy_staffing_grandfathered := bool(source.get("legacy_staffing_grandfathered", false))
	var required_active_staff := int(source.get("required_active_staff", -1))
	var authored_required_active_staff := int(authored.get("required_active_staff", -1))
	if (
		(legacy_staffing_grandfathered and required_active_staff != 0)
		or (
			not legacy_staffing_grandfathered
			and required_active_staff != authored_required_active_staff
		)
	):
		return invalid
	var base_premium_cents := int((DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS[offer_id] as Dictionary).get("premium_cents", -1))
	var expected_service_bonus := sim._service_coop_premium_bonus_cents(
		base_premium_cents,
		service_coop_level_at_signing,
	)
	var expected_bonus_basis_points := (
		service_coop_level_at_signing * DepartmentSimulation.SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
	)
	if (
		int(source.get("base_premium_cents", -1)) != base_premium_cents
		or int(source.get("service_coop_bonus_cents", -1)) != expected_service_bonus
		or int(source.get("premium_bonus_basis_points", -1)) != expected_bonus_basis_points
		or int(source.get("premium_cents", -1)) != int(authored.get("premium_cents", -2))
	):
		return invalid
	for field in [
		"name",
		"short_name",
		"client",
		"tagline",
		"success_required",
		"lane_mix_label",
		"arrival_schedule",
	]:
		if String(source.get(field, "")) != String(authored.get(field, "")):
			return invalid
	if String(source.get("tone", "")) != String(authored.get("tone", "")):
		return invalid
	if not _market_contract_lane_mix_matches(
		source.get("lane_mix", null),
		authored.get("lane_mix", {}) as Dictionary,
	):
		return invalid
	if not _market_contract_arrival_batches_match(
		source.get("arrival_batches", null),
		authored.get("arrival_batches", null),
	):
		return invalid

	var claim_ids_result := _validated_market_contract_id_array(source.get("claim_ids", null))
	if not bool(claim_ids_result.get("valid", false)):
		return invalid
	var claim_ids := claim_ids_result.get("ids", []) as Array
	var authored_schedules := authored.get("scheduled_claims", []) as Array
	var schedule_values: Variant = source.get("scheduled_claims", null)
	if (
		claim_ids.size() != int(authored.get("total_claims", -1))
		or not schedule_values is Array
		or (schedule_values as Array).size() != authored_schedules.size()
	):
		return invalid
	var normalized_schedules: Array[Dictionary] = []
	var derived_accepted: Array[int] = []
	var derived_rejected: Array[int] = []
	var rush_by_claim_id: Dictionary[int, bool] = {}
	for index in authored_schedules.size():
		var schedule_value: Variant = (schedule_values as Array)[index]
		var authored_schedule_value: Variant = authored_schedules[index]
		if not schedule_value is Dictionary or not authored_schedule_value is Dictionary:
			return invalid
		var schedule := schedule_value as Dictionary
		var authored_schedule := authored_schedule_value as Dictionary
		for field in [
			"batch_index",
			"arrival_minute_of_day",
			"deadline_minute_of_day",
			"service_window_minutes",
		]:
			if (
				not sim._is_integral_number(schedule.get(field, null))
				or int(schedule.get(field, -1)) != int(authored_schedule.get(field, -2))
			):
				return invalid
		for field in ["lane", "authored_lane", "arrival_time", "deadline_time"]:
			if String(schedule.get(field, "")) != String(authored_schedule.get(field, "")):
				return invalid
		for field in ["rush", "authored_rush"]:
			if (
				typeof(schedule.get(field, null)) != TYPE_BOOL
				or bool(schedule.get(field, false)) != bool(authored_schedule.get(field, false))
			):
				return invalid
		if (
			not sim._is_integral_number(schedule.get("claim_id", null))
			or int(schedule.get("claim_id", -1)) != int(claim_ids[index])
			or typeof(schedule.get("released", null)) != TYPE_BOOL
			or typeof(schedule.get("rejected", null)) != TYPE_BOOL
		):
			return invalid
		var released := bool(schedule.get("released", false))
		var rejected := bool(schedule.get("rejected", false))
		if released and rejected:
			return invalid
		var arrival_minute := int(authored_schedule.get("arrival_minute_of_day", DepartmentSimulation.SHIFT_END_MINUTE + 1))
		var terminal := released or rejected
		if saved_phase in [DepartmentSimulation.ShiftPhase.REVIEW, DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE]:
			if terminal or saved_minute != DepartmentSimulation.SHIFT_START_MINUTE:
				return invalid
		else:
			if (arrival_minute <= saved_minute) != terminal:
				return invalid
		var claim_id := int(claim_ids[index])
		if released:
			derived_accepted.append(claim_id)
		elif rejected:
			derived_rejected.append(claim_id)
		rush_by_claim_id[claim_id] = bool(authored_schedule.get("rush", false))
		var normalized_schedule := authored_schedule.duplicate(true)
		normalized_schedule["claim_id"] = claim_id
		normalized_schedule["released"] = released
		normalized_schedule["rejected"] = rejected
		normalized_schedules.append(normalized_schedule)

	var array_fields := [
		"accepted_claim_ids",
		"completed_claim_ids",
		"sound_completed_claim_ids",
		"timely_sound_claim_ids",
		"cracked_claim_ids",
		"late_claim_ids",
		"rejected_claim_ids",
	]
	var validated_arrays: Dictionary = {}
	for field in array_fields:
		var ids_result := _validated_market_contract_id_array(source.get(field, null))
		if not bool(ids_result.get("valid", false)):
			return invalid
		validated_arrays[field] = ids_result.get("ids", [])
	var accepted_ids := validated_arrays["accepted_claim_ids"] as Array
	var rejected_ids := validated_arrays["rejected_claim_ids"] as Array
	if (
		not _market_contract_same_id_order(accepted_ids, derived_accepted)
		or not _market_contract_same_id_order(rejected_ids, derived_rejected)
	):
		return invalid
	var completed_ids := validated_arrays["completed_claim_ids"] as Array
	var sound_ids := validated_arrays["sound_completed_claim_ids"] as Array
	var timely_ids := validated_arrays["timely_sound_claim_ids"] as Array
	var cracked_ids := validated_arrays["cracked_claim_ids"] as Array
	var late_ids := validated_arrays["late_claim_ids"] as Array
	for completed_id in completed_ids:
		if completed_id not in accepted_ids:
			return invalid
		var is_sound: bool = completed_id in sound_ids
		var is_cracked: bool = completed_id in cracked_ids
		var is_timely: bool = completed_id in timely_ids
		var is_late_or_failed: bool = completed_id in late_ids
		if is_sound == is_cracked or (is_timely and not is_sound):
			return invalid
		if is_late_or_failed != (not is_timely):
			return invalid
	for sound_id in sound_ids:
		if sound_id not in completed_ids:
			return invalid
	for timely_id in timely_ids:
		if timely_id not in sound_ids:
			return invalid
	for cracked_id in cracked_ids:
		if cracked_id not in completed_ids:
			return invalid
	for late_id in late_ids:
		if late_id not in completed_ids:
			return invalid
	var rush_completed_on_time := 0
	for timely_id in timely_ids:
		if bool(rush_by_claim_id.get(int(timely_id), false)):
			rush_completed_on_time += 1
	var released_batch_count := 0
	for batch_index in (authored.get("arrival_batches", []) as Array).size():
		var complete := true
		for schedule in normalized_schedules:
			if int(schedule.get("batch_index", -1)) != batch_index:
				continue
			if not bool(schedule.get("released", false)) and not bool(schedule.get("rejected", false)):
				complete = false
				break
		if complete:
			released_batch_count += 1
	var expected_counts := {
		"released_batch_count": released_batch_count,
		"completed_count": completed_ids.size(),
		"sound_completed": sound_ids.size(),
		"timely_sound_completed": timely_ids.size(),
		"rush_completed_on_time": rush_completed_on_time,
		"cracked_count": cracked_ids.size(),
		"late_count": late_ids.size(),
	}
	for field in expected_counts:
		if (
			not sim._is_integral_number(source.get(field, null))
			or int(source.get(field, -1)) != int(expected_counts[field])
		):
			return invalid
	var expected_status := "active" if not accepted_ids.is_empty() else "signed"
	if String(source.get("status", "")) != expected_status:
		return invalid
	var normalized := {
		"version": 2,
		"contract_id": expected_contract_id,
		"offer_id": String(offer_id),
		"id": String(offer_id),
		"name": String(authored.get("name", "FARM MUTUAL BINDER")),
		"short_name": String(authored.get("short_name", "MUTUAL BINDER")),
		"client": String(authored.get("client", "FARM MUTUAL")),
		"tagline": String(authored.get("tagline", "")),
		"tone": String(authored.get("tone", &"quality")),
		"signed_day": saved_day,
		"target_day": saved_day,
		"deadline_day": saved_day,
		"status": expected_status,
		"required_claim_capacity": int(authored.get("required_claim_capacity", 0)),
		"required_active_staff": required_active_staff,
		"legacy_staffing_grandfathered": legacy_staffing_grandfathered,
		"legacy_terms_grandfathered": legacy_terms_grandfathered,
		"required_completed": int(authored.get("required_completed", 0)),
		"success_required": String(authored.get("success_required", "")),
		"total_claims": int(authored.get("total_claims", 0)),
		"rush_claims": int(authored.get("rush_claims", 0)),
		"service_window_minutes": int(authored.get("service_window_minutes", 0)),
		"base_premium_cents": base_premium_cents,
		"service_coop_level_at_signing": service_coop_level_at_signing,
		"service_coop_bonus_cents": expected_service_bonus,
		"premium_bonus_basis_points": expected_bonus_basis_points,
		"premium_cents": int(authored.get("premium_cents", 0)),
		"breach_cents": int(authored.get("breach_cents", 0)),
		"lane_mix": (authored.get("lane_mix", {}) as Dictionary).duplicate(true),
		"lane_mix_label": String(authored.get("lane_mix_label", "")),
		"arrival_batches": (authored.get("arrival_batches", []) as Array).duplicate(true),
		"arrival_schedule": String(authored.get("arrival_schedule", "")),
		"scheduled_claims": normalized_schedules,
		"claim_ids": claim_ids.duplicate(),
		"accepted_claim_ids": accepted_ids.duplicate(),
		"completed_claim_ids": completed_ids.duplicate(),
		"sound_completed_claim_ids": sound_ids.duplicate(),
		"timely_sound_claim_ids": timely_ids.duplicate(),
		"cracked_claim_ids": cracked_ids.duplicate(),
		"late_claim_ids": late_ids.duplicate(),
		"rejected_claim_ids": rejected_ids.duplicate(),
		"released_batch_count": released_batch_count,
		"completed_count": completed_ids.size(),
		"sound_completed": sound_ids.size(),
		"timely_sound_completed": timely_ids.size(),
		"rush_completed_on_time": rush_completed_on_time,
		"cracked_count": cracked_ids.size(),
		"late_count": late_ids.size(),
	}
	var authoritative_normalized := authored.duplicate(true)
	authoritative_normalized.merge(normalized, true)
	return {"valid": true, "record": authoritative_normalized}


func _validated_market_contract_result(
	value: Variant,
	saved_day: int,
	restored_service_coop_level: int,
	restored_negotiation_room_level: int
) -> Dictionary:
	var invalid := {"valid": false, "record": {}}
	if not value is Dictionary:
		return invalid
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	if not sim._is_integral_number(source.get("version", null)) or int(source.get("version", 0)) != 2:
		return invalid
	if typeof(source.get("legacy_terms_grandfathered", null)) != TYPE_BOOL:
		return invalid
	var legacy_terms_grandfathered := bool(source.get("legacy_terms_grandfathered", false))
	if not sim._is_integral_number(source.get("day", null)):
		return invalid
	var result_day := int(source.get("day", 0))
	if result_day < DepartmentSimulation.CONTRACT_BOARD_UNLOCK_DAY or result_day > saved_day:
		return invalid
	if (
		not sim._is_integral_number(source.get("target_day", null))
		or int(source.get("target_day", 0)) != result_day
	):
		return invalid
	var offer_id := StringName(String(source.get("offer_id", "")))
	if offer_id not in DepartmentSimulation.MARKET_CONTRACT_OFFER_ORDER:
		return invalid
	var clause_id := StringName(String(source.get("clause_id", "")))
	if clause_id not in DepartmentSimulation.MARKET_CONTRACT_CLAUSE_ORDER:
		return invalid
	var pricing_id := StringName(String(source.get("pricing_profile_id", "mutual_rate")))
	if pricing_id not in DepartmentSimulation.MARKET_PRICING_PROFILE_ORDER:
		return invalid
	for frozen_level_field in [
		"service_coop_level_at_signing",
		"negotiation_room_level_at_signing",
	]:
		if not sim._is_integral_number(source.get(frozen_level_field, null)):
			return invalid
	var service_coop_level_at_signing := int(source.get("service_coop_level_at_signing", -1))
	var negotiation_room_level_at_signing := int(
		source.get("negotiation_room_level_at_signing", -1)
	)
	if (
		service_coop_level_at_signing < 0
		or service_coop_level_at_signing > restored_service_coop_level
		or service_coop_level_at_signing > 3
		or negotiation_room_level_at_signing < 0
		or negotiation_room_level_at_signing > restored_negotiation_room_level
		or negotiation_room_level_at_signing > 1
		or (clause_id != &"standard_terms" and negotiation_room_level_at_signing != 1)
		or (
			legacy_terms_grandfathered
			and (
				clause_id != &"standard_terms"
				or negotiation_room_level_at_signing != 0
			)
		)
	):
		return invalid
	var authored := sim._market_contract_quote_for_day(
		offer_id,
		result_day,
		service_coop_level_at_signing,
		negotiation_room_level_at_signing,
		clause_id,
		legacy_terms_grandfathered,
		pricing_id,
	)
	if authored.is_empty() or not _market_contract_result_quote_matches(
		source,
		authored,
		legacy_terms_grandfathered,
	):
		return invalid
	var expected_contract_id := "FM-%04d-%s" % [result_day, String(offer_id).to_upper()]
	if String(source.get("contract_id", "")) != expected_contract_id:
		return invalid
	for field in ["name", "short_name", "client"]:
		if String(source.get(field, "")) != String(authored.get(field, "")):
			return invalid
	for field in ["required_completed", "total_claims", "rush_claims"]:
		if (
			not sim._is_integral_number(source.get(field, null))
			or int(source.get(field, -1)) != int(authored.get(field, -2))
		):
			return invalid
	if typeof(source.get("success", null)) != TYPE_BOOL:
		return invalid
	var success := bool(source.get("success", false))
	var expected_status := "fulfilled" if success else "breached"
	if String(source.get("status", "")) != expected_status:
		return invalid
	for boolean_field in [
		"delivery_threshold_met", "welfare_gate_met", "welfare_gate_required",
	]:
		if typeof(source.get(boolean_field, null)) != TYPE_BOOL:
			return invalid
	var integer_fields := [
		"timely_sound_completed",
		"sound_completed",
		"completed_count",
		"rush_completed_on_time",
		"cracked_count",
		"late_count",
		"rejected_count",
		"required_active_staff",
		"closing_welfare",
		"base_premium_cents",
		"service_coop_level_at_signing",
		"service_coop_bonus_cents",
		"contracted_service_coop_bonus_cents",
		"premium_bonus_basis_points",
		"premium_cents",
		"breach_cents",
		"net_contract_cents",
		"fund_before_cents",
		"fund_after_cents",
		"market_standing_before",
		"market_standing_after",
		"market_standing_delta",
		"clean_contract_streak_before",
		"clean_contract_streak_after",
		"best_clean_contract_streak",
	]
	var has_pricing_outcome := source.has("pricing_profile_id")
	if has_pricing_outcome:
		integer_fields.append_array([
			"market_reach_before",
			"market_reach_after",
			"market_reach_delta",
			"market_share_basis_points",
			"claimant_satisfaction_before",
			"claimant_satisfaction_after",
			"claimant_satisfaction_delta",
		])
	for field in integer_fields:
		if not sim._is_integral_number(source.get(field, null)):
			return invalid
	var total_claims := int(authored.get("total_claims", 0))
	var required := int(authored.get("required_completed", 0))
	var timely := int(source.get("timely_sound_completed", -1))
	var sound := int(source.get("sound_completed", -1))
	var completed := int(source.get("completed_count", -1))
	var rush_on_time := int(source.get("rush_completed_on_time", -1))
	var cracked := int(source.get("cracked_count", -1))
	var late := int(source.get("late_count", -1))
	var rejected := int(source.get("rejected_count", -1))
	var claim_ids_result := _validated_market_contract_id_array(source.get("claim_ids", null))
	var accepted_ids_result := _validated_market_contract_id_array(
		source.get("accepted_claim_ids", null)
	)
	var rejected_ids_result := _validated_market_contract_id_array(
		source.get("rejected_claim_ids", null)
	)
	if (
		not bool(claim_ids_result.get("valid", false))
		or not bool(accepted_ids_result.get("valid", false))
		or not bool(rejected_ids_result.get("valid", false))
	):
		return invalid
	var claim_ids := claim_ids_result.get("ids", []) as Array
	var accepted_ids := accepted_ids_result.get("ids", []) as Array
	var rejected_ids := rejected_ids_result.get("ids", []) as Array
	var derived_claim_ids: Array[int] = []
	var derived_accepted_ids: Array[int] = []
	var derived_rejected_ids: Array[int] = []
	var normalized_result_schedules: Array[Dictionary] = []
	var source_schedules := source.get("scheduled_claims", []) as Array
	var authored_schedules := authored.get("scheduled_claims", []) as Array
	for index in source_schedules.size():
		var schedule := source_schedules[index] as Dictionary
		var claim_id := int(schedule.get("claim_id", -1))
		derived_claim_ids.append(claim_id)
		if bool(schedule.get("released", false)):
			derived_accepted_ids.append(claim_id)
		elif bool(schedule.get("rejected", false)):
			derived_rejected_ids.append(claim_id)
		var normalized_schedule := (authored_schedules[index] as Dictionary).duplicate(true)
		normalized_schedule["claim_id"] = claim_id
		normalized_schedule["released"] = bool(schedule.get("released", false))
		normalized_schedule["rejected"] = bool(schedule.get("rejected", false))
		normalized_result_schedules.append(normalized_schedule)
	if (
		not _market_contract_same_id_order(claim_ids, derived_claim_ids)
		or not _market_contract_same_id_order(accepted_ids, derived_accepted_ids)
		or not _market_contract_same_id_order(rejected_ids, derived_rejected_ids)
	):
		return invalid
	var closing_welfare := int(source.get("closing_welfare", -1))
	var welfare_gate_minimum := int(authored.get("welfare_gate_minimum", 0))
	var delivery_threshold_met := timely >= required
	var welfare_gate_met := welfare_gate_minimum <= 0 or closing_welfare >= welfare_gate_minimum
	if (
		timely < 0 or timely > sound
		or sound < 0 or sound > completed
		or completed < 0 or completed > total_claims
		or sound + cracked != completed
		or cracked < 0
		or late != completed - timely
		or rush_on_time < 0 or rush_on_time > int(authored.get("rush_claims", 0))
		or rush_on_time > timely
		or rejected < 0 or rejected > total_claims
		or rejected != rejected_ids.size()
		or completed + rejected > total_claims
		or closing_welfare < 0 or closing_welfare > 100
		or bool(source.get("delivery_threshold_met", false)) != delivery_threshold_met
		or bool(source.get("welfare_gate_met", false)) != welfare_gate_met
		or bool(source.get("welfare_gate_required", false)) != (welfare_gate_minimum > 0)
		or success != (delivery_threshold_met and welfare_gate_met)
	):
		return invalid
	var authored_required_staff := int(authored.get("required_active_staff", 0))
	var required_active_staff := int(source.get("required_active_staff", -1))
	if (
		(legacy_terms_grandfathered and required_active_staff not in [0, authored_required_staff])
		or (not legacy_terms_grandfathered and required_active_staff != authored_required_staff)
	):
		return invalid
	var base_premium_cents := int((DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS[offer_id] as Dictionary).get("premium_cents", -1))
	var contracted_service_bonus := sim._service_coop_premium_bonus_cents(
		base_premium_cents,
		service_coop_level_at_signing,
	)
	var expected_service_bonus := contracted_service_bonus if success else 0
	var expected_premium := int(authored.get("contracted_premium_cents", 0)) if success else 0
	var expected_breach := int(authored.get("contracted_breach_cents", 0)) if not success else 0
	var premium := int(source.get("premium_cents", -1))
	var breach := int(source.get("breach_cents", -1))
	var net := int(source.get("net_contract_cents", 0))
	var fund_before := int(source.get("fund_before_cents", -1))
	var fund_after := int(source.get("fund_after_cents", -1))
	var pricing_definition := DepartmentSimulation.MARKET_PRICING_PROFILE_DEFINITIONS[pricing_id] as Dictionary
	var authored_reach_delta := int(pricing_definition.get(
		"reach_success_delta" if success else "reach_breach_delta",
		0,
	))
	var authored_satisfaction_delta := int(pricing_definition.get(
		"satisfaction_success_delta" if success else "satisfaction_breach_delta",
		0,
	))
	var pricing_reach_before := int(source.get("market_reach_before", 0))
	var expected_reach_after := maxi(0, pricing_reach_before + authored_reach_delta)
	var pricing_satisfaction_before := int(source.get("claimant_satisfaction_before", 50))
	var expected_satisfaction_after := clampi(
		pricing_satisfaction_before + authored_satisfaction_delta,
		0,
		100,
	)
	if (
		int(source.get("base_premium_cents", -1)) != base_premium_cents
		or int(source.get("service_coop_bonus_cents", -1)) != expected_service_bonus
		or int(source.get("contracted_service_coop_bonus_cents", -1)) != contracted_service_bonus
		or int(source.get("premium_bonus_basis_points", -1))
		!= service_coop_level_at_signing * DepartmentSimulation.SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
		or premium != expected_premium
		or breach != expected_breach
		or net != premium - breach
		or fund_before < 0 or fund_before > 2_000_000_000
		or fund_after < 0 or fund_after > 2_000_000_000
		or fund_after != fund_before + net
		or int(source.get("market_standing_delta", 0))
		!= int(source.get("market_standing_after", 0)) - int(source.get("market_standing_before", 0))
		or int(source.get("clean_contract_streak_before", -1)) < 0
		or int(source.get("clean_contract_streak_after", -1)) < 0
		or int(source.get("best_clean_contract_streak", -1))
		< int(source.get("clean_contract_streak_after", 0))
		or StringName(source.get("market_standing_rank", &"")) not in [
			&"unlisted", &"bronze", &"silver", &"gold",
		]
		or String(source.get("outcome", "")).is_empty()
		or (
			has_pricing_outcome
			and (
				int(source.get("market_reach_delta", 0))
				!= expected_reach_after - pricing_reach_before
				or int(source.get("market_reach_after", 0))
				!= expected_reach_after
				or int(source.get("claimant_satisfaction_delta", 0))
				!= (
					int(source.get("claimant_satisfaction_after", 0))
					- int(source.get("claimant_satisfaction_before", 0))
				)
				or int(source.get("claimant_satisfaction_after", 0))
				!= expected_satisfaction_after
				or int(source.get("market_share_basis_points", 0))
				!= clampi(3500 + int(source.get("market_reach_after", 0)) * 250, 2500, 8500)
			)
		)
	):
		return invalid
	var normalized := {
		"version": 2,
		"contract_id": expected_contract_id,
		"offer_id": String(offer_id),
		"name": String(authored.get("name", "FARM MUTUAL BINDER")),
		"short_name": String(authored.get("short_name", "MUTUAL BINDER")),
		"client": String(authored.get("client", "FARM MUTUAL")),
		"day": result_day,
		"target_day": result_day,
		"status": expected_status,
		"success": success,
		"delivery_threshold_met": delivery_threshold_met,
		"welfare_gate_met": welfare_gate_met,
		"closing_welfare": closing_welfare,
		"welfare_gate_minimum": welfare_gate_minimum,
		"welfare_gate_required": welfare_gate_minimum > 0,
		"legacy_terms_grandfathered": legacy_terms_grandfathered,
		"required_completed": required,
		"timely_sound_completed": timely,
		"sound_completed": sound,
		"completed_count": completed,
		"total_claims": total_claims,
		"rush_claims": int(authored.get("rush_claims", 0)),
		"rush_completed_on_time": rush_on_time,
		"cracked_count": cracked,
		"late_count": late,
		"rejected_count": rejected,
		"scheduled_claims": normalized_result_schedules,
		"claim_ids": claim_ids.duplicate(),
		"accepted_claim_ids": accepted_ids.duplicate(),
		"rejected_claim_ids": rejected_ids.duplicate(),
		"required_active_staff": required_active_staff,
		"base_premium_cents": base_premium_cents,
		"service_coop_level_at_signing": service_coop_level_at_signing,
		"service_coop_bonus_cents": expected_service_bonus,
		"contracted_service_coop_bonus_cents": contracted_service_bonus,
		"premium_bonus_basis_points": (
			service_coop_level_at_signing * DepartmentSimulation.SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
		),
		"premium_cents": premium,
		"breach_cents": breach,
		"net_contract_cents": net,
		"fund_before_cents": fund_before,
		"fund_after_cents": fund_after,
		"market_standing_before": int(source.get("market_standing_before", 0)),
		"market_standing_after": int(source.get("market_standing_after", 0)),
		"market_standing_delta": int(source.get("market_standing_delta", 0)),
		"market_standing_rank": String(source.get("market_standing_rank", "unlisted")),
		"clean_contract_streak_before": int(source.get("clean_contract_streak_before", 0)),
		"clean_contract_streak_after": int(source.get("clean_contract_streak_after", 0)),
		"best_clean_contract_streak": int(source.get("best_clean_contract_streak", 0)),
		"market_reach_before": int(source.get("market_reach_before", 0)),
		"market_reach_after": int(source.get("market_reach_after", 0)),
		"market_reach_delta": int(source.get("market_reach_delta", 0)),
		"market_share_basis_points": int(source.get("market_share_basis_points", 3500)),
		"claimant_satisfaction_before": int(source.get("claimant_satisfaction_before", 50)),
		"claimant_satisfaction_after": int(source.get("claimant_satisfaction_after", 50)),
		"claimant_satisfaction_delta": int(source.get("claimant_satisfaction_delta", 0)),
		"outcome": String(source.get("outcome", "")),
	}
	var authoritative_normalized := authored.duplicate(true)
	authoritative_normalized.merge(normalized, true)
	return {"valid": true, "record": authoritative_normalized}


func _validated_market_contract_decline_receipt(
	value: Variant,
	saved_day: int,
	saved_phase: int
) -> Dictionary:
	var invalid := {"valid": false, "record": {}}
	if not value is Dictionary:
		return invalid
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	if (
		saved_day < DepartmentSimulation.CONTRACT_BOARD_UNLOCK_DAY
		or saved_phase not in [
			DepartmentSimulation.ShiftPhase.REVIEW,
			DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE,
			DepartmentSimulation.ShiftPhase.RUNNING,
			DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT,
		]
		or not sim._is_integral_number(source.get("version", null))
		or int(source.get("version", 0)) != 1
		or typeof(source.get("accepted", null)) != TYPE_BOOL
		or not bool(source.get("accepted", false))
		or String(source.get("action_id", "")) != "decline_market_contract"
		or String(source.get("status", "")) != "declined"
	):
		return invalid
	for field in ["day", "target_day"]:
		if not sim._is_integral_number(source.get(field, null)) or int(source.get(field, 0)) != saved_day:
			return invalid
	var expected_outcome := "STANDARD BOOK FILED: no outside Farm Mutual binder will arrive on Day %d." % saved_day
	if String(source.get("outcome", "")) != expected_outcome:
		return invalid
	return {
		"valid": true,
		"record": {
			"version": 1,
			"accepted": true,
			"action_id": "decline_market_contract",
			"status": "declined",
			"day": saved_day,
			"target_day": saved_day,
			"outcome": expected_outcome,
		},
	}


func _validated_upgrade_levels(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var source := value as Dictionary
	if source.size() != DepartmentSimulation.UPGRADE_ORDER.size():
		return {}
	var restored: Dictionary = {}
	for key_value in source:
		var upgrade_id := StringName(String(key_value))
		if upgrade_id not in DepartmentSimulation.UPGRADE_ORDER or restored.has(upgrade_id):
			return {}
		var level_value: Variant = source[key_value]
		if not sim._is_integral_number(level_value):
			return {}
		var level := int(level_value)
		if level < 0 or level > DepartmentSimulation.MAX_UPGRADE_LEVEL:
			return {}
		restored[upgrade_id] = level
	return restored


func _cumulative_upgrade_spend_cents(levels: Dictionary) -> int:
	var total := 0
	for upgrade_id in DepartmentSimulation.UPGRADE_ORDER:
		var level := clampi(int(levels.get(upgrade_id, 0)), 0, DepartmentSimulation.MAX_UPGRADE_LEVEL)
		for level_before in level:
			total += sim._upgrade_list_cost_for_level(upgrade_id, level_before)
	return total


func _validated_hero_case_history(value: Variant, saved_day: int, worker_count: int) -> Dictionary:
	if not value is Array or (value as Array).size() > 32:
		return {"valid": false, "history": []}
	var history: Array[Dictionary] = []
	for row_value in value as Array:
		if not row_value is Dictionary:
			return {"valid": false, "history": []}
		var row := row_value as Dictionary
		if not sim._is_integral_number(row.get("day", null)):
			return {"valid": false, "history": []}
		var row_day := int(row.get("day", 0))
		var case_id := StringName(String(row.get("case_id", "")))
		var choice_id := StringName(String(row.get("choice_id", "")))
		var case_definition := DepartmentSimulation.PLAYBOOK_HERO_CASE_DEFINITIONS.get(case_id, {}) as Dictionary
		var worker_id := int(row.get("worker_id", -1))
		if (
			row_day < 1 or row_day > saved_day
			or case_definition.is_empty()
			or not (case_definition.get("choices", {}) as Dictionary).has(choice_id)
			or worker_id < -1 or worker_id >= worker_count
		):
			return {"valid": false, "history": []}
		for text_field in ["case_label", "choice_label", "worker_name", "echo"]:
			if typeof(row.get(text_field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
				return {"valid": false, "history": []}
		history.append({
			"day": row_day,
			"case_id": String(case_id),
			"case_label": String(row.get("case_label", "")),
			"choice_id": String(choice_id),
			"choice_label": String(row.get("choice_label", "")),
			"worker_id": worker_id,
			"worker_name": String(row.get("worker_name", "")),
			"echo": String(row.get("echo", "")),
		})
	return {"valid": true, "history": history}


func _validated_rival_response_history(value: Variant, saved_day: int) -> Dictionary:
	if not value is Array or (value as Array).size() > 32:
		return {"valid": false, "history": []}
	var history: Array[Dictionary] = []
	for row_value in value as Array:
		if not row_value is Dictionary:
			return {"valid": false, "history": []}
		var row := row_value as Dictionary
		if not sim._is_integral_number(row.get("day", null)):
			return {"valid": false, "history": []}
		var row_day := int(row.get("day", 0))
		var response_id := StringName(String(row.get("response_id", "")))
		if row_day < 1 or row_day > saved_day or not DepartmentSimulation.PLAYBOOK_RIVAL_DEFINITIONS.has(response_id):
			return {"valid": false, "history": []}
		for integer_field in ["eggs_at_choice", "margin_at_choice"]:
			if not sim._is_integral_number(row.get(integer_field, null)):
				return {"valid": false, "history": []}
		for text_field in ["response_label", "rival_name"]:
			if typeof(row.get(text_field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
				return {"valid": false, "history": []}
		history.append({
			"day": row_day,
			"response_id": String(response_id),
			"response_label": String(row.get("response_label", "")),
			"rival_name": String(row.get("rival_name", "")),
			"eggs_at_choice": clampi(int(row.get("eggs_at_choice", 0)), 0, 2_000_000_000),
			"margin_at_choice": clampi(int(row.get("margin_at_choice", 0)), -100, 100),
		})
	return {"valid": true, "history": history}


func _validated_active_playbook(
	value: Variant,
	saved_day: int,
	worker_count: int,
) -> Dictionary:
	# Version 30 checkpoints predate this optional layer, so absence restores a
	# fresh same-day playbook. Once present, every authoritative choice is checked.
	if value == null:
		return {"valid": true, "record": {}}
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	if not sim._is_integral_number(source.get("day", null)) or int(source.get("day", 0)) != saved_day:
		return {"valid": false, "record": {}}
	var definition_fields := {
		"strategy_preset_id": DepartmentSimulation.PLAYBOOK_STRATEGY_PRESET_DEFINITIONS,
		"contract_id": DepartmentSimulation.PLAYBOOK_CONTRACT_DEFINITIONS,
		"preparation_id": DepartmentSimulation.PLAYBOOK_PREPARATION_DEFINITIONS,
		"manager_intervention_id": DepartmentSimulation.PLAYBOOK_MANAGER_INTERVENTION_DEFINITIONS,
		"rival_response_id": DepartmentSimulation.PLAYBOOK_RIVAL_DEFINITIONS,
		"loadout_id": DepartmentSimulation.PLAYBOOK_LOADOUT_DEFINITIONS,
		"recovery_id": DepartmentSimulation.PLAYBOOK_RECOVERY_DEFINITIONS,
		"side_goal_id": DepartmentSimulation.PLAYBOOK_SIDE_GOAL_DEFINITIONS,
		"contract_reward_id": DepartmentSimulation.PLAYBOOK_REWARD_DEFINITIONS,
		"push_luck_id": DepartmentSimulation.PLAYBOOK_PUSH_LUCK_DEFINITIONS,
		"challenge_modifier_id": DepartmentSimulation.PLAYBOOK_CHALLENGE_MODIFIER_DEFINITIONS,
	}
	var normalized := {"day": saved_day}
	for field_name: String in definition_fields:
		var field_value: Variant = source.get(field_name, "")
		if typeof(field_value) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
		var choice_id := StringName(String(field_value))
		var custom_strategy := field_name == "strategy_preset_id" and choice_id == &"custom"
		if choice_id != &"" and not custom_strategy and not (definition_fields[field_name] as Dictionary).has(choice_id):
			return {"valid": false, "record": {}}
		normalized[field_name] = String(choice_id)
	for integer_field in ["side_goal_fund_baseline_cents", "receipt_serial"]:
		if not sim._is_integral_number(source.get(integer_field, null)):
			return {"valid": false, "record": {}}
		var integer_value := int(source.get(integer_field, -1))
		if integer_value < 0 or integer_value > 2_000_000_000:
			return {"valid": false, "record": {}}
		normalized[integer_field] = integer_value
	var push_luck_start_eggs := int(source.get("push_luck_start_eggs", 0))
	if push_luck_start_eggs < 0 or push_luck_start_eggs > 2_000_000_000:
		return {"valid": false, "record": {}}
	normalized["push_luck_start_eggs"] = push_luck_start_eggs
	var signature_values: Variant = source.get("signature_worker_ids", null)
	if not signature_values is Array:
		return {"valid": false, "record": {}}
	var normalized_signature_ids: Array[int] = []
	for worker_id_value in signature_values as Array:
		if not sim._is_integral_number(worker_id_value):
			return {"valid": false, "record": {}}
		var worker_id := int(worker_id_value)
		if worker_id < 0 or worker_id >= worker_count or worker_id in normalized_signature_ids:
			return {"valid": false, "record": {}}
		normalized_signature_ids.append(worker_id)
	normalized["signature_worker_ids"] = normalized_signature_ids
	if typeof(source.get("teamwork_used", null)) != TYPE_BOOL:
		return {"valid": false, "record": {}}
	normalized["teamwork_used"] = bool(source.get("teamwork_used", false))
	normalized["mastery_auto_used"] = bool(source.get("mastery_auto_used", false))
	for optional_bool in ["rescue_used", "rare_episode_resolved", "contract_completed"]:
		var optional_value: Variant = source.get(optional_bool, false)
		if typeof(optional_value) != TYPE_BOOL:
			return {"valid": false, "record": {}}
		normalized[optional_bool] = bool(optional_value)
	if bool(normalized["contract_completed"]) and String(normalized["contract_id"]).is_empty():
		return {"valid": false, "record": {}}
	var hero_case_id := StringName(String(source.get("hero_case_id", "")))
	if hero_case_id != &"" and not DepartmentSimulation.PLAYBOOK_HERO_CASE_DEFINITIONS.has(hero_case_id):
		return {"valid": false, "record": {}}
	normalized["hero_case_id"] = String(hero_case_id)
	var hero_case_choice_id := StringName(String(source.get("hero_case_choice_id", "")))
	if hero_case_choice_id != &"":
		var hero_definition := DepartmentSimulation.PLAYBOOK_HERO_CASE_DEFINITIONS.get(hero_case_id, {}) as Dictionary
		if not (hero_definition.get("choices", {}) as Dictionary).has(hero_case_choice_id):
			return {"valid": false, "record": {}}
	normalized["hero_case_choice_id"] = String(hero_case_choice_id)
	var hero_callback_value: Variant = source.get("hero_case_callback", {})
	if not hero_callback_value is Dictionary:
		return {"valid": false, "record": {}}
	normalized["hero_case_callback"] = (hero_callback_value as Dictionary).duplicate(true)
	var proposal_worker_id := int(source.get("proposal_worker_id", -1))
	if proposal_worker_id < -1 or proposal_worker_id >= worker_count:
		return {"valid": false, "record": {}}
	normalized["proposal_worker_id"] = proposal_worker_id
	var proposal_id := StringName(String(source.get("proposal_id", "")))
	if proposal_id != &"" and not DepartmentSimulation.PLAYBOOK_HEN_PROPOSAL_DEFINITIONS.has(proposal_id):
		return {"valid": false, "record": {}}
	normalized["proposal_id"] = String(proposal_id)
	var toy_id := StringName(String(source.get("toy_id", "")))
	if toy_id != &"" and not DepartmentSimulation.PLAYBOOK_OFFICE_TOY_DEFINITIONS.has(toy_id):
		return {"valid": false, "record": {}}
	normalized["toy_id"] = String(toy_id)
	var display_style_index := int(source.get("display_style_index", 0))
	if display_style_index < 0 or display_style_index >= DepartmentSimulation.PLAYBOOK_DISPLAY_STYLE_ORDER.size():
		return {"valid": false, "record": {}}
	normalized["display_style_index"] = display_style_index
	var receipt_value: Variant = source.get("last_receipt", null)
	if not receipt_value is Dictionary:
		return {"valid": false, "record": {}}
	normalized["last_receipt"] = (receipt_value as Dictionary).duplicate(true)
	return {"valid": true, "record": normalized}


func _validated_first_clutch_reinvestment(
	value: Variant,
	saved_day: int,
	restored_upgrade_levels: Dictionary
) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	for integer_field in [
		"version", "trigger_day", "trigger_worker_id", "trigger_claim_id",
		"created_value_cents", "fund_at_collection_cents", "protected_reserve_cents",
		"spendable_at_collection_cents", "procurement_match_available_cents",
		"resolved_day", "selected_level", "selected_list_cost_cents",
		"procurement_match_used_cents", "net_cost_cents",
		"fund_before_resolution_cents", "spendable_before_resolution_cents",
		"fund_after_cents", "spendable_after_cents",
	]:
		if not sim._is_integral_number(source.get(integer_field, null)):
			return {"valid": false, "record": {}}
	for text_field in [
		"status", "trigger_worker_name", "trigger_quality", "choice_id",
	]:
		if typeof(source.get(text_field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	var options_value: Variant = source.get("offered_options", null)
	if not options_value is Array:
		return {"valid": false, "record": {}}
	var version := int(source.get("version", -1))
	var status := StringName(String(source.get("status", "")))
	var trigger_day := int(source.get("trigger_day", -1))
	var worker_id := int(source.get("trigger_worker_id", -1))
	var claim_id := int(source.get("trigger_claim_id", -1))
	var quality := StringName(String(source.get("trigger_quality", "")))
	var created_value := int(source.get("created_value_cents", -1))
	var fund_at_collection := int(source.get("fund_at_collection_cents", -1))
	var protected_reserve := int(source.get("protected_reserve_cents", -1))
	var spendable_at_collection := int(source.get("spendable_at_collection_cents", -1))
	var match_available := int(source.get("procurement_match_available_cents", -1))
	if (
		version != DepartmentSimulation.FIRST_CLUTCH_REINVESTMENT_VERSION
		or status not in [&"offered", &"purchased", &"banked"]
		or trigger_day < 1 or trigger_day > saved_day
		or worker_id != DepartmentSimulation.FIRST_CLUTCH_WORKER_ID
		or String(source.get("trigger_worker_name", "")) != DepartmentSimulation.WORKER_NAMES[DepartmentSimulation.FIRST_CLUTCH_WORKER_ID]
		or claim_id < 1
		or quality not in [&"sound", &"golden", &"cracked"]
		or created_value < 1 or created_value > 2_000_000_000
		or fund_at_collection < 0 or fund_at_collection > 2_000_000_000
		or protected_reserve < 0 or protected_reserve > 4_000_000_000
		or spendable_at_collection != maxi(0, fund_at_collection - protected_reserve)
		or match_available < 0
		or match_available > DepartmentSimulation.ORIENTATION_PROCUREMENT_MATCH_CAP_CENTS
	):
		return {"valid": false, "record": {}}

	var normalized_options: Array[Dictionary] = []
	var seen_options: Dictionary[StringName, bool] = {}
	var last_order_index := -1
	var highest_list_cost := 0
	for option_value in (options_value as Array):
		if not option_value is Dictionary:
			return {"valid": false, "record": {}}
		var option := option_value as Dictionary
		for integer_field in ["level_before", "next_level", "list_cost_cents"]:
			if not sim._is_integral_number(option.get(integer_field, null)):
				return {"valid": false, "record": {}}
		if typeof(option.get("id", null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
		var upgrade_id := StringName(String(option.get("id", "")))
		var order_index := DepartmentSimulation.UPGRADE_ORDER.find(upgrade_id)
		var level_before := int(option.get("level_before", -1))
		var next_level := int(option.get("next_level", -1))
		var list_cost := int(option.get("list_cost_cents", -1))
		if (
			order_index < 0 or order_index <= last_order_index
			or seen_options.has(upgrade_id)
			or level_before < 0 or level_before >= DepartmentSimulation.MAX_UPGRADE_LEVEL
			or next_level != level_before + 1
			or list_cost != sim._upgrade_list_cost_for_level(upgrade_id, level_before)
			or int(restored_upgrade_levels.get(upgrade_id, -1)) < level_before
		):
			return {"valid": false, "record": {}}
		last_order_index = order_index
		seen_options[upgrade_id] = true
		highest_list_cost = maxi(highest_list_cost, list_cost)
		normalized_options.append({
			"id": String(upgrade_id),
			"level_before": level_before,
			"next_level": next_level,
			"list_cost_cents": list_cost,
		})
	if normalized_options.size() > DepartmentSimulation.FIRST_CLUTCH_REINVESTMENT_OFFER_LIMIT:
		return {"valid": false, "record": {}}
	var expected_match := mini(
		DepartmentSimulation.ORIENTATION_PROCUREMENT_MATCH_CAP_CENTS,
		maxi(0, highest_list_cost - spendable_at_collection),
	)
	if match_available != expected_match:
		return {"valid": false, "record": {}}

	var choice_id := StringName(String(source.get("choice_id", "")))
	var resolved_day := int(source.get("resolved_day", -1))
	var selected_level := int(source.get("selected_level", -1))
	var selected_list_cost := int(source.get("selected_list_cost_cents", -1))
	var match_used := int(source.get("procurement_match_used_cents", -1))
	var net_cost := int(source.get("net_cost_cents", -1))
	var fund_before := int(source.get("fund_before_resolution_cents", -1))
	var spendable_before := int(source.get("spendable_before_resolution_cents", -1))
	var fund_after := int(source.get("fund_after_cents", -1))
	var spendable_after := int(source.get("spendable_after_cents", -1))
	if status == &"offered":
		if (
			choice_id != &"" or resolved_day != 0 or selected_level != 0
			or selected_list_cost != 0 or match_used != 0 or net_cost != 0
			or fund_before != 0 or spendable_before != 0
			or fund_after != fund_at_collection
			or spendable_after != spendable_at_collection
		):
			return {"valid": false, "record": {}}
		for option in normalized_options:
			var offered_id := StringName(option.get("id", ""))
			if int(restored_upgrade_levels.get(offered_id, -1)) != int(option["level_before"]):
				return {"valid": false, "record": {}}
	elif status == &"banked":
		if (
			choice_id != DepartmentSimulation.FIRST_CLUTCH_BANK_CHOICE_ID
			or resolved_day < trigger_day or resolved_day > saved_day
			or selected_level != 0 or selected_list_cost != 0 or match_used != 0 or net_cost != 0
			or fund_before < 0 or fund_before > 2_000_000_000
			or spendable_before < 0 or spendable_before > fund_before
			or fund_after != fund_before or spendable_after != spendable_before
		):
			return {"valid": false, "record": {}}
	else:
		var selected_option: Dictionary = {}
		for option in normalized_options:
			if StringName(option.get("id", "")) == choice_id:
				selected_option = option
				break
		if selected_option.is_empty():
			return {"valid": false, "record": {}}
		var expected_level := int(selected_option["next_level"])
		var expected_list_cost := int(selected_option["list_cost_cents"])
		var expected_match_used := mini(match_available, expected_list_cost)
		var expected_net_cost := expected_list_cost - expected_match_used
		if (
			resolved_day < trigger_day or resolved_day > saved_day
			or selected_level != expected_level
			or selected_list_cost != expected_list_cost
			or match_used != expected_match_used
			or net_cost != expected_net_cost
			or fund_before < net_cost or fund_before > 2_000_000_000
			or spendable_before < net_cost or spendable_before > fund_before
			or fund_after != fund_before - net_cost
			or spendable_after != spendable_before - net_cost
			or int(restored_upgrade_levels.get(choice_id, -1)) < selected_level
		):
			return {"valid": false, "record": {}}

	var normalized := source.duplicate(true)
	normalized["status"] = String(status)
	normalized["trigger_quality"] = String(quality)
	normalized["choice_id"] = String(choice_id)
	normalized["offered_options"] = normalized_options
	return {"valid": true, "record": normalized}


func _decision_from_save_data(value: Dictionary) -> Dictionary:
	if value.is_empty():
		return {}
	var restored := value.duplicate(true)
	for key in ["kind", "id", "category", "petition_type"]:
		if restored.has(key):
			restored[key] = StringName(String(restored[key]))
	var restored_options: Array[Dictionary] = []
	var option_values: Variant = restored.get("options", [])
	if option_values is Array:
		for option_value in (option_values as Array):
			if not option_value is Dictionary:
				continue
			var option := (option_value as Dictionary).duplicate(true)
			for key in ["id", "tone", "response_tier"]:
				if option.has(key):
					option[key] = StringName(String(option[key]))
			restored_options.append(option)
	restored["options"] = restored_options
	var petition_value: Variant = restored.get("petition", {})
	if petition_value is Dictionary:
		var petition := (petition_value as Dictionary).duplicate(true)
		if petition.has("petition_type"):
			petition["petition_type"] = StringName(String(petition["petition_type"]))
		restored["petition"] = petition
	return restored


func _is_valid_shift_decision_tuple(
	saved_shift_phase: int,
	saved_active_directive: StringName,
	saved_pending_decision: Dictionary,
) -> bool:
	var pending_kind := StringName(saved_pending_decision.get("kind", &""))
	var pending_id := StringName(saved_pending_decision.get("id", &""))
	match saved_shift_phase:
		DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE:
			return (
				saved_active_directive == &""
				and pending_kind == &"directive"
				and pending_id == &"morning_directive"
			)
		DepartmentSimulation.ShiftPhase.RUNNING:
			return (
				DepartmentSimulation.DIRECTIVE_DEFINITIONS.has(saved_active_directive)
				and saved_pending_decision.is_empty()
			)
		DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT:
			return (
				DepartmentSimulation.DIRECTIVE_DEFINITIONS.has(saved_active_directive)
				and pending_kind == &"incident"
				and (
					DepartmentSimulation.INCIDENT_DEFINITIONS.has(pending_id)
					or pending_id == DepartmentSimulation.FLOCK_PETITION_INCIDENT_ID
				)
			)
		DepartmentSimulation.ShiftPhase.REVIEW:
			return (
				saved_active_directive == &""
				and (
					saved_pending_decision.is_empty()
					or pending_kind in [&"credit_allocation", &"major_event"]
				)
			)
	return false


func _is_valid_peck_assist_record(value: Dictionary, saved_day: int) -> bool:
	if value.is_empty():
		return true
	if typeof(value.get("accepted", null)) != TYPE_BOOL or not bool(value.get("accepted", false)):
		return false
	for field in ["day", "worker_id", "claim_id", "streak", "best_streak", "remaining"]:
		if not sim._is_integral_number(value.get(field, null)):
			return false
	if int(value.get("day", 0)) < 1 or int(value.get("day", 0)) > saved_day:
		return false
	if int(value.get("worker_id", -1)) < 0 or int(value.get("worker_id", -1)) >= DepartmentSimulation.WORKER_NAMES.size():
		return false
	if int(value.get("claim_id", 0)) < 1:
		return false
	if int(value.get("streak", -1)) < 0 or int(value.get("best_streak", -1)) < int(value.get("streak", 0)):
		return false
	if int(value.get("remaining", -1)) < 0 or int(value.get("remaining", -1)) > DepartmentSimulation.PECK_ASSIST_LIMIT:
		return false
	if (
		not sim._is_integral_number(value.get("potential_priority_credit_cents", null))
		or int(value.get("potential_priority_credit_cents", -1)) < 0
		or int(value.get("potential_priority_credit_cents", -1)) > 100
	):
		return false
	for optional_integer_field in ["charges", "gross_interventions", "refunds"]:
		if value.has(optional_integer_field) and not sim._is_integral_number(value.get(optional_integer_field)):
			return false
	var rating := StringName(String(value.get("rating", "")))
	if rating not in [&"perfect", &"strong", &"steady", &"scramble"]:
		return false
	for field in [
		"timing_score", "progress_before", "progress_after", "progress_gain",
		"quality_modifier", "stress_delta", "fatigue_delta", "morale_delta",
	]:
		if typeof(value.get(field, null)) not in [TYPE_FLOAT, TYPE_INT]:
			return false
	return true


func _is_valid_peck_assist_delivery_token(value: Dictionary, saved_day: int) -> bool:
	for field in ["day", "claim_id", "worker_id"]:
		if not sim._is_integral_number(value.get(field, null)):
			return false
	if int(value.get("day", 0)) != saved_day:
		return false
	if int(value.get("claim_id", 0)) < 1:
		return false
	if int(value.get("worker_id", -1)) < 0 or int(value.get("worker_id", -1)) >= DepartmentSimulation.WORKER_NAMES.size():
		return false
	if typeof(value.get("quality", null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	return StringName(String(value.get("quality", ""))) in [&"sound", &"golden"]


func _normalized_peck_assist_delivery_token(value: Dictionary) -> Dictionary:
	var normalized := value.duplicate(true)
	for field in ["day", "claim_id", "worker_id"]:
		normalized[field] = int(normalized.get(field, 0))
	normalized["quality"] = String(normalized.get("quality", ""))
	return normalized


func _is_valid_peck_assist_delivery_receipt(value: Dictionary, saved_day: int) -> bool:
	if value.is_empty():
		return true
	if (
		typeof(value.get("accepted", null)) != TYPE_BOOL
		or not bool(value.get("accepted", false))
		or typeof(value.get("refunded", null)) != TYPE_BOOL
		or not bool(value.get("refunded", false))
	):
		return false
	for field in [
		"day", "claim_id", "refund_amount", "charges_before", "charges_after", "remaining",
		"gross_interventions", "refunds", "pending_delivery_count",
	]:
		if not sim._is_integral_number(value.get(field, null)):
			return false
	var charges_before := int(value.get("charges_before", -1))
	var charges_after := int(value.get("charges_after", -1))
	var gross_interventions := int(value.get("gross_interventions", -1))
	var refunds := int(value.get("refunds", -1))
	if (
		int(value.get("day", 0)) != saved_day
		or int(value.get("claim_id", 0)) < 1
		or int(value.get("refund_amount", -1)) != 1
		or charges_before < 0 or charges_before >= DepartmentSimulation.PECK_ASSIST_LIMIT
		or charges_after != charges_before + 1 or charges_after > DepartmentSimulation.PECK_ASSIST_LIMIT
		or int(value.get("remaining", -1)) != charges_after
		or gross_interventions < 1 or gross_interventions > 9999
		or refunds < 1 or refunds > gross_interventions
		or gross_interventions - refunds != DepartmentSimulation.PECK_ASSIST_LIMIT - charges_after
		or int(value.get("pending_delivery_count", -1)) < 0
		or int(value.get("pending_delivery_count", -1)) > DepartmentSimulation.PECK_ASSIST_LIMIT
		or int(value.get("pending_delivery_count", -1)) > DepartmentSimulation.PECK_ASSIST_LIMIT - charges_after
	):
		return false
	if typeof(value.get("quality", null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	if StringName(String(value.get("quality", ""))) not in [&"sound", &"golden"]:
		return false
	return typeof(value.get("reason", null)) == TYPE_STRING


func _is_valid_staffing_action_data(value: Dictionary, saved_day: int) -> bool:
	if value.is_empty():
		return true
	if typeof(value.get("accepted", null)) != TYPE_BOOL or not bool(value.get("accepted", false)):
		return false
	if typeof(value.get("action_id", null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	if typeof(value.get("worker_name", null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	if value.has("outcome") and typeof(value.get("outcome")) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	if StringName(String(value.get("action_id", ""))) not in [&"hire_worker", &"release_worker"]:
		return false
	for field in [
		"day", "cost_cents", "worker_id", "desk_index",
		"active_staff_count", "office_capacity",
	]:
		if not sim._is_integral_number(value.get(field, null)):
			return false
	var action_day := int(value.get("day", 0))
	if action_day < 1 or action_day > saved_day:
		return false
	if int(value.get("cost_cents", -1)) < 0:
		return false
	if int(value.get("worker_id", -1)) < 0 or int(value.get("worker_id", -1)) >= DepartmentSimulation.MAXIMUM_STAFF_CAPACITY:
		return false
	if String(value.get("worker_name", "")).is_empty():
		return false
	if int(value.get("desk_index", -2)) < -1 or int(value.get("desk_index", -2)) >= DepartmentSimulation.MAXIMUM_STAFF_CAPACITY:
		return false
	if (
		int(value.get("active_staff_count", 0)) < DepartmentSimulation.MINIMUM_STAFF_COUNT
		or int(value.get("active_staff_count", 0)) > DepartmentSimulation.MAXIMUM_STAFF_CAPACITY
	):
		return false
	if (
		int(value.get("office_capacity", 0)) < DepartmentSimulation.MINIMUM_STAFF_COUNT
		or int(value.get("office_capacity", 0)) > DepartmentSimulation.MAXIMUM_STAFF_CAPACITY
	):
		return false
	return true


func _string_array_matches(value: Variant, expected: Variant) -> bool:
	if not value is Array or not expected is Array:
		return false
	var source := value as Array
	var target := expected as Array
	if source.size() != target.size():
		return false
	for index in source.size():
		if String(source[index]) != String(target[index]):
			return false
	return true


func _validated_campus_expansion_receipt(
	value: Variant,
	saved_day: int,
	expected_receipt_id: int,
	replay_state: Dictionary,
) -> Dictionary:
	if not value is Dictionary:
		return {}
	var receipt := value as Dictionary
	if not _dictionary_has_exact_keys(receipt, DepartmentSimulation.CAMPUS_EXPANSION_RECEIPT_KEYS):
		return {}
	if typeof(receipt.get("accepted", null)) != TYPE_BOOL or not bool(receipt["accepted"]):
		return {}
	for key in [
		"receipt_id", "day", "cost_cents", "added_daily_cost_cents", "fund_before_cents",
		"fund_after_cents", "daily_cost_before_cents", "daily_cost_after_cents",
		"claim_capacity_bonus_before", "claim_capacity_bonus_after",
		"farmgate_capacity_bonus_before", "farmgate_capacity_bonus_after",
		"access_standing_points", "access_farmgate_level",
	]:
		if not sim._is_integral_number(receipt.get(key, null)):
			return {}
	for key in ["action_id", "item_id", "socket_id", "from_socket_id", "access_gate_id"]:
		if typeof(receipt.get(key, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {}
	if typeof(receipt.get("reason", null)) != TYPE_STRING or typeof(receipt.get("outcome", null)) != TYPE_STRING:
		return {}
	var action_id := StringName(String(receipt["action_id"]))
	var item_id := StringName(String(receipt["item_id"]))
	var socket_id := StringName(String(receipt["socket_id"]))
	var from_socket_id := StringName(String(receipt["from_socket_id"]))
	var access_gate_id := StringName(String(receipt["access_gate_id"]))
	var terms := sim._campus_action_terms(action_id, item_id)
	if terms.is_empty() or not sim._campus_state_action_reason(
		replay_state,
		action_id,
		item_id,
		socket_id,
	).is_empty():
		return {}
	if action_id in [&"purchase_parcel", &"commission_service"] and socket_id != &"":
		return {}
	var receipt_day := int(receipt["day"])
	var expected_from_socket := StringName(String(replay_state.get("pod_socket_id", "")))
	var cost_cents := int(terms["cost_cents"])
	var added_daily_cost_cents := int(terms["added_daily_cost_cents"])
	var daily_before := sim._campus_daily_cost_for_state(replay_state)
	var claim_bonus_before := sim._campus_claim_capacity_bonus_for_state(replay_state)
	# Receipt capacity effects are facility-independent campus bonuses. A Depot
	# may be commissioned later without rewriting this immutable campus history.
	var farmgate_bonus_before := (
		DepartmentSimulation.CAMPUS_FARMGATE_STORAGE_BONUS_EGGS
		if sim._campus_cold_chain_active_for_state(replay_state) else
		0
	)
	var preview_state := replay_state.duplicate(true)
	sim._apply_campus_action_to_state(preview_state, action_id, item_id, socket_id)
	var claim_bonus_after := sim._campus_claim_capacity_bonus_for_state(preview_state)
	var farmgate_bonus_after := (
		DepartmentSimulation.CAMPUS_FARMGATE_STORAGE_BONUS_EGGS
		if sim._campus_cold_chain_active_for_state(preview_state) else
		0
	)
	var fund_before := int(receipt["fund_before_cents"])
	var access_standing := int(receipt["access_standing_points"])
	var access_farmgate := int(receipt["access_farmgate_level"])
	if (
		int(receipt["receipt_id"]) != expected_receipt_id
		or receipt_day < DepartmentSimulation.CAMPUS_EXPANSION_UNLOCK_DAY or receipt_day > saved_day
		or int(receipt["cost_cents"]) != cost_cents
		or int(receipt["added_daily_cost_cents"]) != added_daily_cost_cents
		or fund_before < cost_cents or fund_before > 2_000_000_000
		or int(receipt["fund_after_cents"]) != fund_before - cost_cents
		or int(receipt["fund_after_cents"]) < 0
		or int(receipt["daily_cost_before_cents"]) != daily_before
		or int(receipt["daily_cost_after_cents"]) != sim._campus_daily_cost_for_state(preview_state)
		or int(receipt["claim_capacity_bonus_before"]) != claim_bonus_before
		or int(receipt["claim_capacity_bonus_after"]) != claim_bonus_after
		or int(receipt["farmgate_capacity_bonus_before"]) != farmgate_bonus_before
		or int(receipt["farmgate_capacity_bonus_after"]) != farmgate_bonus_after
		or from_socket_id != expected_from_socket
		or not String(receipt["reason"]).is_empty()
		or String(receipt["outcome"]) != sim._campus_action_outcome(
			action_id,
			item_id,
			from_socket_id,
			socket_id,
		)
	):
		return {}
	if action_id == &"purchase_parcel":
		if (
			access_standing < 0
			or access_farmgate < 0 or access_farmgate > 3
			or (
				access_gate_id == &"farmgate_dispatch"
				and access_farmgate < 1
			)
			or (
				access_gate_id == &"farm_mutual_standing"
				and (
					access_standing < DepartmentSimulation.CAMPUS_EXPANSION_STANDING_REQUIREMENT
					or access_farmgate != 0
				)
			)
			or access_gate_id not in [&"farmgate_dispatch", &"farm_mutual_standing"]
		):
			return {}
	elif access_gate_id != &"" or access_standing != 0 or access_farmgate != 0:
		return {}
	var normalized := receipt.duplicate(true)
	normalized["action_id"] = action_id
	normalized["item_id"] = item_id
	normalized["socket_id"] = socket_id
	normalized["from_socket_id"] = from_socket_id
	normalized["access_gate_id"] = access_gate_id
	for key in [
		"receipt_id", "day", "cost_cents", "added_daily_cost_cents", "fund_before_cents",
		"fund_after_cents", "daily_cost_before_cents", "daily_cost_after_cents",
		"claim_capacity_bonus_before", "claim_capacity_bonus_after",
		"farmgate_capacity_bonus_before", "farmgate_capacity_bonus_after",
		"access_standing_points", "access_farmgate_level",
	]:
		normalized[key] = int(normalized[key])
	return normalized


func _validated_campus_expansion_state(value: Variant, saved_day: int) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false}
	var source := value as Dictionary
	if not _dictionary_has_exact_keys(source, DepartmentSimulation.CAMPUS_EXPANSION_SAVE_KEYS):
		return {"valid": false}
	if (
		not sim._is_integral_number(source.get("version", null))
		or int(source["version"]) != DepartmentSimulation.CAMPUS_EXPANSION_SAVE_VERSION
		or typeof(source.get("parcel_owned", null)) != TYPE_BOOL
		or typeof(source.get("pod_owned", null)) != TYPE_BOOL
		or typeof(source.get("pod_socket_id", null)) not in [TYPE_STRING, TYPE_STRING_NAME]
		or not sim._is_integral_number(source.get("capital_spend_total_cents", null))
		or not sim._is_integral_number(source.get("next_receipt_id", null))
		or not source.get("last_receipt", null) is Dictionary
		or not source.get("history", null) is Array
	):
		return {"valid": false}
	var services_value: Variant = source.get("services", null)
	if not services_value is Dictionary:
		return {"valid": false}
	var services_source := services_value as Dictionary
	if services_source.size() != DepartmentSimulation.CAMPUS_SERVICE_ORDER.size():
		return {"valid": false}
	var normalized_services: Dictionary = {}
	for raw_service_id in services_source:
		var service_id := StringName(String(raw_service_id))
		if (
			service_id not in DepartmentSimulation.CAMPUS_SERVICE_ORDER
			or normalized_services.has(String(service_id))
			or typeof(services_source[raw_service_id]) != TYPE_BOOL
		):
			return {"valid": false}
		normalized_services[String(service_id)] = bool(services_source[raw_service_id])
	var history_source := source["history"] as Array
	if history_source.size() > DepartmentSimulation.CAMPUS_EXPANSION_HISTORY_LIMIT:
		return {"valid": false}
	var replay_state := _neutral_campus_expansion_state()
	var normalized_history: Array[Dictionary] = []
	var previous_day := 0
	var accumulated_spend := 0
	for index in history_source.size():
		var receipt := _validated_campus_expansion_receipt(
			history_source[index],
			saved_day,
			index + 1,
			replay_state,
		)
		if receipt.is_empty() or int(receipt["day"]) < previous_day:
			return {"valid": false}
		previous_day = int(receipt["day"])
		accumulated_spend += int(receipt["cost_cents"])
		sim._apply_campus_action_to_state(
			replay_state,
			StringName(receipt["action_id"]),
			StringName(receipt["item_id"]),
			StringName(receipt["socket_id"]),
		)
		normalized_history.append(receipt)
	var pod_socket_id := StringName(String(source["pod_socket_id"]))
	if (
		bool(source["parcel_owned"]) != bool(replay_state["parcel_owned"])
		or normalized_services != sim._campus_services_for_state(replay_state)
		or bool(source["pod_owned"]) != bool(replay_state["pod_owned"])
		or pod_socket_id != StringName(String(replay_state["pod_socket_id"]))
		or int(source["capital_spend_total_cents"]) != accumulated_spend
		or int(source["next_receipt_id"]) != normalized_history.size() + 1
	):
		return {"valid": false}
	var last_source := source["last_receipt"] as Dictionary
	var normalized_last: Dictionary = {}
	if normalized_history.is_empty():
		if not last_source.is_empty():
			return {"valid": false}
	else:
		normalized_last = _validated_campus_expansion_receipt(
			last_source,
			saved_day,
			normalized_history.size(),
			_campus_replay_state_before_last(normalized_history),
		)
		if normalized_last.is_empty() or normalized_last != normalized_history[normalized_history.size() - 1]:
			return {"valid": false}
	var normalized_state := {
		"version": DepartmentSimulation.CAMPUS_EXPANSION_SAVE_VERSION,
		"parcel_owned": bool(source["parcel_owned"]),
		"services": normalized_services,
		"pod_owned": bool(source["pod_owned"]),
		"pod_socket_id": String(pod_socket_id),
		"capital_spend_total_cents": accumulated_spend,
		"next_receipt_id": normalized_history.size() + 1,
		"last_receipt": normalized_last,
		"history": normalized_history,
	}
	return {"valid": true, "state": normalized_state}


func _campus_replay_state_before_last(history: Array[Dictionary]) -> Dictionary:
	var state := _neutral_campus_expansion_state()
	for index in maxi(0, history.size() - 1):
		var receipt := history[index] as Dictionary
		sim._apply_campus_action_to_state(
			state,
			StringName(receipt["action_id"]),
			StringName(receipt["item_id"]),
			StringName(receipt["socket_id"]),
		)
	return state


func _validated_facility_purchase_receipt(
	value: Variant,
	saved_day: int,
	restored_owned_facilities: Dictionary,
) -> Dictionary:
	if not value is Dictionary:
		return {}
	var receipt := value as Dictionary
	if not _dictionary_has_exact_keys(receipt, DepartmentSimulation.FACILITY_PURCHASE_RECEIPT_KEYS):
		return {}
	if typeof(receipt.get("accepted")) != TYPE_BOOL or not bool(receipt["accepted"]):
		return {}
	if StringName(receipt.get("action_id", &"")) != &"purchase_facility":
		return {}
	var facility_id := StringName(receipt.get("facility_id", &""))
	if not DepartmentSimulation.FACILITY_DEFINITIONS.has(facility_id):
		return {}
	for key in [
		"day", "purchased_level", "max_level", "cost_cents", "fund_before_cents",
		"fund_after_cents", "spendable_before_cents", "spendable_after_cents",
		"protected_reserve_before_cents", "protected_reserve_after_cents",
		"upkeep_before_cents", "upkeep_after_cents", "upkeep_delta_cents",
	]:
		if not sim._is_integral_number(receipt.get(key, null)):
			return {}
	var definition := DepartmentSimulation.FACILITY_DEFINITIONS[facility_id] as Dictionary
	var purchased_level := int(receipt["purchased_level"])
	var max_level := int(definition.get("max_level", 1))
	var day_value := int(receipt["day"])
	var expected_cost := sim._facility_cost_for_level(definition, purchased_level)
	var expected_upkeep_before := sim._facility_maintenance_for_level(definition, purchased_level - 1)
	var expected_upkeep_after := sim._facility_maintenance_for_level(definition, purchased_level)
	var expected_supervisor_delta := 0
	if facility_id == DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID:
		expected_supervisor_delta = (
			sim._facility_level_schedule_value(DepartmentSimulation.ROOSTER_SUPERVISOR_PAYROLL_CENTS, purchased_level, 0)
			- sim._facility_level_schedule_value(DepartmentSimulation.ROOSTER_SUPERVISOR_PAYROLL_CENTS, purchased_level - 1, 0)
		)
	var fund_before := int(receipt["fund_before_cents"])
	var fund_after := int(receipt["fund_after_cents"])
	var reserve_before := int(receipt["protected_reserve_before_cents"])
	var reserve_after := int(receipt["protected_reserve_after_cents"])
	var effect_value: Variant = receipt.get("effect", null)
	if not effect_value is Dictionary:
		return {}
	var effect := effect_value as Dictionary
	if not _dictionary_has_exact_keys(effect, DepartmentSimulation.FACILITY_PURCHASE_EFFECT_KEYS):
		return {}
	for effect_key in ["storage_capacity_eggs", "dispatch_capacity_eggs", "shelf_life_shifts"]:
		if not sim._is_integral_number(effect.get(effect_key, null)):
			return {}
	if (
		purchased_level < 1 or purchased_level > max_level
		or purchased_level > int(restored_owned_facilities.get(facility_id, 0))
		or day_value < 1 or day_value > saved_day
		or String(receipt.get("facility_name", "")) != String(definition.get("name", ""))
		or String(receipt.get("level_name", "")) != sim._facility_level_name(definition, purchased_level)
		or int(receipt["max_level"]) != max_level
		or int(receipt["cost_cents"]) != expected_cost
		or fund_before < expected_cost or fund_before > 2_000_000_000
		or fund_after != fund_before - expected_cost
		or reserve_before < 0 or reserve_before > 2_000_000_000
		or reserve_after != reserve_before + (expected_upkeep_after - expected_upkeep_before) + expected_supervisor_delta
		or int(receipt["spendable_before_cents"]) != maxi(0, fund_before - reserve_before)
		or int(receipt["spendable_after_cents"]) != maxi(0, fund_after - reserve_after)
		or int(receipt["upkeep_before_cents"]) < expected_upkeep_before
		or int(receipt["upkeep_after_cents"]) != int(receipt["upkeep_before_cents"]) + expected_upkeep_after - expected_upkeep_before
		or int(receipt["upkeep_delta_cents"]) != expected_upkeep_after - expected_upkeep_before
		or not _string_array_matches(effect.get("benefits", null), definition.get("benefits", null))
		or not _string_array_matches(effect.get("tradeoffs", null), definition.get("tradeoffs", null))
		or int(effect.get("storage_capacity_eggs", -1)) != int(sim._facility_purchase_effect_copy(facility_id, purchased_level)["storage_capacity_eggs"])
		or int(effect.get("dispatch_capacity_eggs", -1)) != int(sim._facility_purchase_effect_copy(facility_id, purchased_level)["dispatch_capacity_eggs"])
		or int(effect.get("shelf_life_shifts", -1)) != int(sim._facility_purchase_effect_copy(facility_id, purchased_level)["shelf_life_shifts"])
	):
		return {}
	var normalized := receipt.duplicate(true)
	normalized["action_id"] = &"purchase_facility"
	normalized["facility_id"] = facility_id
	for key in [
		"day", "purchased_level", "max_level", "cost_cents", "fund_before_cents",
		"fund_after_cents", "spendable_before_cents", "spendable_after_cents",
		"protected_reserve_before_cents", "protected_reserve_after_cents",
		"upkeep_before_cents", "upkeep_after_cents", "upkeep_delta_cents",
	]:
		normalized[key] = int(normalized.get(key, 0))
	var normalized_effect := (normalized.get("effect", {}) as Dictionary).duplicate(true)
	for key in ["storage_capacity_eggs", "dispatch_capacity_eggs", "shelf_life_shifts"]:
		normalized_effect[key] = int(normalized_effect.get(key, 0))
	normalized["effect"] = normalized_effect
	return normalized


func _validated_capital_records(
	pinned_value: Variant,
	last_value: Variant,
	history_value: Variant,
	saved_day: int,
	restored_owned_facilities: Dictionary,
) -> Dictionary:
	if typeof(pinned_value) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return {"valid": false}
	var pinned_id := StringName(String(pinned_value))
	if pinned_id != &"":
		if not DepartmentSimulation.FACILITY_DEFINITIONS.has(pinned_id):
			return {"valid": false}
		var pinned_definition := DepartmentSimulation.FACILITY_DEFINITIONS[pinned_id] as Dictionary
		if int(restored_owned_facilities.get(pinned_id, 0)) >= int(pinned_definition.get("max_level", 1)):
			return {"valid": false}
	if not last_value is Dictionary or not history_value is Array:
		return {"valid": false}
	var history_source := history_value as Array
	if history_source.size() > DepartmentSimulation.FARMGATE_COMMISSIONING_HISTORY_LIMIT:
		return {"valid": false}
	var restored_history: Array[Dictionary] = []
	var previous_day := 0
	var previous_level_by_facility: Dictionary = {}
	for raw_receipt in history_source:
		var receipt := _validated_facility_purchase_receipt(
			raw_receipt,
			saved_day,
			restored_owned_facilities,
		)
		if receipt.is_empty():
			return {"valid": false}
		var receipt_day := int(receipt["day"])
		var facility_id := StringName(receipt["facility_id"])
		var purchased_level := int(receipt["purchased_level"])
		if receipt_day < previous_day or purchased_level <= int(previous_level_by_facility.get(facility_id, 0)):
			return {"valid": false}
		previous_day = receipt_day
		previous_level_by_facility[facility_id] = purchased_level
		restored_history.append(receipt)
	var last_source := last_value as Dictionary
	var restored_last: Dictionary = {}
	if restored_history.is_empty():
		if not last_source.is_empty():
			return {"valid": false}
	else:
		restored_last = _validated_facility_purchase_receipt(
			last_source,
			saved_day,
			restored_owned_facilities,
		)
		if restored_last.is_empty() or restored_last != restored_history[restored_history.size() - 1]:
			return {"valid": false}
	return {
		"valid": true,
		"pinned_id": pinned_id,
		"last": restored_last,
		"history": restored_history,
	}


func _validated_manager_roster(value: Variant, rooster_office_level: int) -> Array[Dictionary]:
	var invalid: Array[Dictionary] = []
	if not value is Array:
		return invalid
	var source := value as Array
	var expected_count := clampi(rooster_office_level + 1, 1, 4)
	if source.size() != expected_count:
		return invalid
	var result: Array[Dictionary] = []
	var seen_ids: Dictionary[StringName, bool] = {}
	for slot_index in source.size():
		var row_value: Variant = source[slot_index]
		if not row_value is Dictionary:
			return invalid
		var row := (row_value as Dictionary).duplicate(true)
		var candidate_id := StringName(String(row.get("candidate_id", row.get("id", ""))))
		var assignment_id := StringName(String(row.get("assignment_id", "")))
		var posture_id := StringName(String(row.get("posture_id", "")))
		if (
			not DepartmentSimulation.MANAGER_CANDIDATE_DEFINITIONS.has(candidate_id)
			or seen_ids.has(candidate_id)
			or assignment_id not in DepartmentSimulation.MANAGER_ASSIGNMENT_ORDER
			or posture_id not in DepartmentSimulation.MANAGER_POSTURE_ORDER
			or not sim._is_integral_number(row.get("slot_index", null))
			or int(row.get("slot_index", -1)) != slot_index
			or typeof(row.get("posture_filed", null)) != TYPE_BOOL
		):
			return invalid
		for integer_field in ["hired_day", "influence", "rank", "credit_claims", "interventions", "last_pip_worker_id"]:
			if not sim._is_integral_number(row.get(integer_field, null)):
				return invalid
		var influence := int(row.get("influence", -1))
		var rank := int(row.get("rank", -1))
		if (
			int(row.get("hired_day", 0)) < 1
			or influence < 0 or influence > 2_000_000_000
			or rank != sim._manager_rank_for_influence(influence)
			or int(row.get("credit_claims", -1)) < 0
			or int(row.get("interventions", -1)) < 0
			or int(row.get("last_pip_worker_id", -2)) < -1
			or int(row.get("last_pip_worker_id", -2)) >= sim.workers.size()
		):
			return invalid
		seen_ids[candidate_id] = true
		row["id"] = String(candidate_id)
		row["candidate_id"] = String(candidate_id)
		row["assignment_id"] = String(assignment_id)
		row["posture_id"] = String(posture_id)
		result.append(row)
	return result


func _validated_owned_facilities(value: Variant) -> Dictionary:
	## The current schema requires exactly one integral level for every known facility.
	## Rejecting unknown, missing, duplicate-normalized, and out-of-range entries
	## keeps authored effects deterministic after a JSON round trip.
	if not value is Dictionary:
		return {}
	var source := value as Dictionary
	if source.size() != DepartmentSimulation.FACILITY_ORDER.size():
		return {}
	var normalized: Dictionary = {}
	for raw_id in source:
		var facility_id := StringName(String(raw_id))
		if not DepartmentSimulation.FACILITY_DEFINITIONS.has(facility_id) or normalized.has(facility_id):
			return {}
		var level_value: Variant = source[raw_id]
		if not sim._is_integral_number(level_value):
			return {}
		var definition := DepartmentSimulation.FACILITY_DEFINITIONS[facility_id] as Dictionary
		var level := int(level_value)
		if level < 0 or level > int(definition.get("max_level", 1)):
			return {}
		normalized[facility_id] = level
	if normalized.size() != DepartmentSimulation.FACILITY_ORDER.size():
		return {}
	return normalized


func _dictionary_has_exact_keys(source: Dictionary, keys: Array[String]) -> bool:
	if source.size() != keys.size():
		return false
	for key in keys:
		if not source.has(key):
			return false
	return true


func _validated_flock_relations_resolution(
	value: Variant,
	saved_day: int,
	facility_level_value: int,
	restored_workers: Array[ChickenState],
) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	var required_keys: Array[String] = [
		"case_id", "worker_id", "worker_name", "type", "title", "severity",
		"filed_day", "resolved_day", "action_id", "action_label", "cost_cents", "outcome",
	]
	if not _dictionary_has_exact_keys(source, required_keys):
		return {"valid": false, "record": {}}
	for field in ["case_id", "worker_id", "severity", "filed_day", "resolved_day", "cost_cents"]:
		if not sim._is_integral_number(source.get(field, null)):
			return {"valid": false, "record": {}}
	for field in ["worker_name", "type", "title", "action_id", "action_label", "outcome"]:
		if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	var case_id := int(source.get("case_id", 0))
	var worker_id := int(source.get("worker_id", -1))
	var severity := int(source.get("severity", 0))
	var filed_day := int(source.get("filed_day", 0))
	var resolved_day := int(source.get("resolved_day", 0))
	var case_type := StringName(String(source.get("type", "")))
	var action_id := StringName(String(source.get("action_id", "")))
	if (
		case_id < 1
		or worker_id < 0 or worker_id >= restored_workers.size()
		or severity < 1 or severity > 3
		or filed_day < 1 or filed_day > resolved_day
		or resolved_day < 1 or resolved_day > saved_day
		or case_type not in DepartmentSimulation.FLOCK_RELATIONS_CASE_TYPES
		or not DepartmentSimulation.FLOCK_RELATIONS_ACTION_DEFINITIONS.has(action_id)
	):
		return {"valid": false, "record": {}}
	var worker := restored_workers[worker_id]
	var definition := DepartmentSimulation.FLOCK_RELATIONS_ACTION_DEFINITIONS[action_id] as Dictionary
	var expected_label := String(definition.get("label", ""))
	var expected_cost := sim._flock_relations_action_cost_cents(action_id, severity)
	var title := sim._flock_relations_case_title(case_type)
	var expected_outcome := "%s closed %s's %s file for $%.2f." % [
		expected_label.capitalize(),
		worker.display_name,
		title.to_lower(),
		float(expected_cost) / 100.0,
	]
	if (
		String(source.get("worker_name", "")) != worker.display_name
		or String(source.get("title", "")) != title
		or int(source.get("cost_cents", -1)) != expected_cost
		or String(source.get("action_label", "")) != expected_label
		or String(source.get("outcome", "")) != expected_outcome
		or facility_level_value < int(definition.get("required_level", 0))
	):
		return {"valid": false, "record": {}}
	return {
		"valid": true,
		"record": {
			"case_id": case_id,
			"worker_id": worker_id,
			"worker_name": worker.display_name,
			"type": case_type,
			"title": title,
			"severity": severity,
			"filed_day": filed_day,
			"resolved_day": resolved_day,
			"action_id": action_id,
			"action_label": expected_label,
			"cost_cents": expected_cost,
			"outcome": expected_outcome,
		},
	}


func _validated_flock_relations_state(
	data: Dictionary,
	saved_day: int,
	facility_level_value: int,
	restored_workers: Array[ChickenState],
) -> Dictionary:
	for field in [
		"flock_relations_resolutions_used_today",
		"flock_relations_resolved_total",
		"flock_relations_denied_total",
		"flock_relations_settlement_spend_total_cents",
		"next_flock_relations_case_id",
	]:
		if not sim._is_integral_number(data.get(field, null)):
			return {"valid": false}
	var open_value: Variant = data.get("flock_relations_open_cases", null)
	var last_value: Variant = data.get("last_flock_relations_resolution", null)
	var history_value: Variant = data.get("flock_relations_resolution_history", null)
	if not open_value is Array or not last_value is Dictionary or not history_value is Array:
		return {"valid": false}
	var resolution_limit := sim._facility_level_schedule_value(
		DepartmentSimulation.FLOCK_RELATIONS_RESOLUTION_LIMITS,
		facility_level_value,
		0,
	)
	var case_capacity := sim._facility_level_schedule_value(
		DepartmentSimulation.FLOCK_RELATIONS_CASE_CAPACITY,
		facility_level_value,
		0,
	)
	var resolutions_used := int(data.get("flock_relations_resolutions_used_today", -1))
	var resolved_total := int(data.get("flock_relations_resolved_total", -1))
	var denied_total := int(data.get("flock_relations_denied_total", -1))
	var spend_total := int(data.get("flock_relations_settlement_spend_total_cents", -1))
	var next_case_id := int(data.get("next_flock_relations_case_id", 0))
	if (
		resolutions_used < 0 or resolutions_used > resolution_limit
		or resolved_total < 0 or resolved_total > 2_000_000_000
		or denied_total < 0 or denied_total > resolved_total
		or spend_total < 0 or spend_total > 2_000_000_000
		or next_case_id < 1 or next_case_id > 2_000_000_000
		or (open_value as Array).size() > case_capacity
		or (history_value as Array).size() > DepartmentSimulation.FLOCK_RELATIONS_HISTORY_LIMIT
	):
		return {"valid": false}
	var open_cases: Array[Dictionary] = []
	var seen_case_ids: Dictionary[int, bool] = {}
	var seen_worker_ids: Dictionary[int, bool] = {}
	for case_value in (open_value as Array):
		if not case_value is Dictionary:
			return {"valid": false}
		var source := case_value as Dictionary
		var case_keys: Array[String] = [
			"case_id", "worker_id", "worker_name", "type", "title", "severity",
			"filed_day", "status", "evidence", "risk_score", "last_carry_day",
		]
		if not _dictionary_has_exact_keys(source, case_keys):
			return {"valid": false}
		for field in ["case_id", "worker_id", "severity", "filed_day", "risk_score", "last_carry_day"]:
			if not sim._is_integral_number(source.get(field, null)):
				return {"valid": false}
		for field in ["worker_name", "type", "title", "status"]:
			if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
				return {"valid": false}
		var evidence_value: Variant = source.get("evidence", null)
		if not evidence_value is Dictionary:
			return {"valid": false}
		var evidence_source := evidence_value as Dictionary
		var evidence_keys: Array[String] = [
			"risk_score", "grievance", "stress", "fatigue", "manager_trust",
			"wage_arrears_cents", "compliance", "it_coop_installed",
			"recent_management_innovation",
		]
		if not _dictionary_has_exact_keys(evidence_source, evidence_keys):
			return {"valid": false}
		if (
			not sim._is_integral_number(evidence_source.get("risk_score", null))
			or not sim._is_integral_number(evidence_source.get("wage_arrears_cents", null))
			or typeof(evidence_source.get("it_coop_installed", null)) != TYPE_BOOL
			or typeof(evidence_source.get("recent_management_innovation", null)) != TYPE_BOOL
		):
			return {"valid": false}
		for metric in ["grievance", "stress", "fatigue", "manager_trust", "compliance"]:
			var metric_value: Variant = evidence_source.get(metric, null)
			if typeof(metric_value) not in [TYPE_FLOAT, TYPE_INT]:
				return {"valid": false}
			var metric_number := float(metric_value)
			if not is_finite(metric_number) or metric_number < 0.0 or metric_number > 100.0:
				return {"valid": false}
		var case_id := int(source.get("case_id", 0))
		var worker_id := int(source.get("worker_id", -1))
		var severity := int(source.get("severity", 0))
		var filed_day := int(source.get("filed_day", 0))
		var risk_score := int(source.get("risk_score", 0))
		var last_carry_day := int(source.get("last_carry_day", 0))
		var case_type := StringName(String(source.get("type", "")))
		if (
			case_id < 1 or seen_case_ids.has(case_id)
			or worker_id < 0 or worker_id >= restored_workers.size()
			or seen_worker_ids.has(worker_id)
			or severity < 1 or severity > 3
			or filed_day < 1 or filed_day > saved_day
			or last_carry_day < filed_day or last_carry_day > saved_day
			or risk_score < DepartmentSimulation.FLOCK_RELATIONS_CASE_RISK_THRESHOLD or risk_score > 1000
			or case_type not in DepartmentSimulation.FLOCK_RELATIONS_CASE_TYPES
			or StringName(String(source.get("status", ""))) != &"open"
		):
			return {"valid": false}
		var worker := restored_workers[worker_id]
		if (
			String(source.get("worker_name", "")) != worker.display_name
			or String(source.get("title", "")) != sim._flock_relations_case_title(case_type)
			or severity != sim._flock_relations_case_severity(risk_score)
			or int(evidence_source.get("risk_score", -1)) != risk_score
		):
			return {"valid": false}
		var grievance := float(evidence_source.get("grievance", 0.0))
		var stress := float(evidence_source.get("stress", 0.0))
		var fatigue := float(evidence_source.get("fatigue", 0.0))
		var trust := float(evidence_source.get("manager_trust", 0.0))
		var evidence_compliance := float(evidence_source.get("compliance", 0.0))
		var evidence_arrears := int(evidence_source.get("wage_arrears_cents", -1))
		if evidence_arrears < 0 or evidence_arrears > 2_000_000_000:
			return {"valid": false}
		var expected_risk := roundi(grievance * 2.0 + stress + fatigue + (100.0 - trust))
		if evidence_arrears > 0:
			expected_risk += 120
		if bool(evidence_source.get("it_coop_installed", false)):
			expected_risk += roundi(maxf(0.0, 70.0 - evidence_compliance) * 2.0)
		var expected_type: StringName = &"workplace_grievance"
		if evidence_arrears > 0:
			expected_type = &"pay_dispute"
		elif bool(evidence_source.get("it_coop_installed", false)) and evidence_compliance < 60.0:
			expected_type = &"automation_appeal"
		elif grievance >= 50.0:
			expected_type = &"surveillance_grievance"
		elif stress + fatigue >= 120.0:
			expected_type = &"burnout_case"
		elif bool(evidence_source.get("recent_management_innovation", false)):
			expected_type = &"credit_claim"
		if risk_score != expected_risk or case_type != expected_type:
			return {"valid": false}
		seen_case_ids[case_id] = true
		seen_worker_ids[worker_id] = true
		open_cases.append({
			"case_id": case_id,
			"worker_id": worker_id,
			"worker_name": worker.display_name,
			"type": case_type,
			"title": sim._flock_relations_case_title(case_type),
			"severity": severity,
			"filed_day": filed_day,
			"status": &"open",
			"evidence": {
				"risk_score": risk_score,
				"grievance": snappedf(grievance, 0.0001),
				"stress": snappedf(stress, 0.0001),
				"fatigue": snappedf(fatigue, 0.0001),
				"manager_trust": snappedf(trust, 0.0001),
				"wage_arrears_cents": evidence_arrears,
				"compliance": snappedf(evidence_compliance, 0.0001),
				"it_coop_installed": bool(evidence_source.get("it_coop_installed", false)),
				"recent_management_innovation": bool(evidence_source.get("recent_management_innovation", false)),
			},
			"risk_score": risk_score,
			"last_carry_day": last_carry_day,
		})
	var history: Array[Dictionary] = []
	var history_spend := 0
	var history_denials := 0
	var resolutions_on_saved_day := 0
	var previous_resolution_day := 0
	for resolution_value in (history_value as Array):
		var validated := _validated_flock_relations_resolution(
			resolution_value,
			saved_day,
			facility_level_value,
			restored_workers,
		)
		if not bool(validated.get("valid", false)):
			return {"valid": false}
		var resolution := validated.get("record", {}) as Dictionary
		var resolved_case_id := int(resolution.get("case_id", 0))
		var resolution_day := int(resolution.get("resolved_day", 0))
		if seen_case_ids.has(resolved_case_id) or resolution_day < previous_resolution_day:
			return {"valid": false}
		seen_case_ids[resolved_case_id] = true
		previous_resolution_day = resolution_day
		history_spend += int(resolution.get("cost_cents", 0))
		if StringName(resolution.get("action_id", &"")) == &"file_pip":
			history_denials += 1
		if resolution_day == saved_day:
			resolutions_on_saved_day += 1
		history.append(resolution)
	var last_resolution: Dictionary = {}
	if not (last_value as Dictionary).is_empty():
		var validated_last := _validated_flock_relations_resolution(
			last_value,
			saved_day,
			facility_level_value,
			restored_workers,
		)
		if not bool(validated_last.get("valid", false)):
			return {"valid": false}
		last_resolution = validated_last.get("record", {}) as Dictionary
	if (
		resolutions_used != resolutions_on_saved_day
		or (resolved_total == 0 and (not history.is_empty() or not last_resolution.is_empty()))
		or (resolved_total > 0 and (history.is_empty() or last_resolution != history[history.size() - 1]))
		or (resolved_total <= DepartmentSimulation.FLOCK_RELATIONS_HISTORY_LIMIT and history.size() != resolved_total)
		or (resolved_total > DepartmentSimulation.FLOCK_RELATIONS_HISTORY_LIMIT and history.size() != DepartmentSimulation.FLOCK_RELATIONS_HISTORY_LIMIT)
		or (resolved_total <= DepartmentSimulation.FLOCK_RELATIONS_HISTORY_LIMIT and spend_total != history_spend)
		or (resolved_total > DepartmentSimulation.FLOCK_RELATIONS_HISTORY_LIMIT and spend_total < history_spend)
		or (resolved_total <= DepartmentSimulation.FLOCK_RELATIONS_HISTORY_LIMIT and denied_total != history_denials)
		or (resolved_total > DepartmentSimulation.FLOCK_RELATIONS_HISTORY_LIMIT and denied_total < history_denials)
		or next_case_id != resolved_total + open_cases.size() + 1
	):
		return {"valid": false}
	for recorded_case_id in seen_case_ids:
		if int(recorded_case_id) >= next_case_id:
			return {"valid": false}
	if facility_level_value == 0 and (
		not open_cases.is_empty()
		or resolutions_used != 0
		or resolved_total != 0
		or denied_total != 0
		or spend_total != 0
		or not last_resolution.is_empty()
		or not history.is_empty()
		or next_case_id != 1
	):
		return {"valid": false}
	return {
		"valid": true,
		"open_cases": open_cases,
		"resolutions_used_today": resolutions_used,
		"resolved_total": resolved_total,
		"denied_total": denied_total,
		"settlement_spend_total_cents": spend_total,
		"last_resolution": last_resolution,
		"history": history,
		"next_case_id": next_case_id,
	}


func _normalized_staffing_action_data(value: Dictionary) -> Dictionary:
	if value.is_empty():
		return {}
	var normalized := value.duplicate(true)
	normalized["accepted"] = bool(normalized.get("accepted", true))
	normalized["action_id"] = String(normalized.get("action_id", ""))
	normalized["worker_name"] = String(normalized.get("worker_name", ""))
	if normalized.has("outcome"):
		normalized["outcome"] = String(normalized["outcome"])
	for field in [
		"day", "cost_cents", "worker_id", "desk_index", "active_staff_count",
		"office_capacity", "daily_wage_cents", "spendable_fund_cents",
		"available_for_hire_day",
	]:
		if normalized.has(field):
			normalized[field] = int(normalized[field])
	return normalized


func _restore_worker_shift_stats(value: Variant) -> Array[Dictionary]:
	var restored: Array[Dictionary] = []
	if not value is Array or (value as Array).size() != sim.workers.size():
		return restored
	for index in (value as Array).size():
		var entry_value: Variant = (value as Array)[index]
		if not entry_value is Dictionary:
			return []
		var entry := entry_value as Dictionary
		for field in ["worker_id", "eggs", "sound", "cracked", "golden", "credit_cents"]:
			if not sim._is_integral_number(entry.get(field, null)):
				return []
		var worker_id := int(entry.get("worker_id", -1))
		var eggs := int(entry.get("eggs", -1))
		var sound := int(entry.get("sound", -1))
		var cracked := int(entry.get("cracked", -1))
		var golden := int(entry.get("golden", -1))
		var credit_cents := int(entry.get("credit_cents", -1))
		if (
			worker_id != index
			or eggs < 0 or eggs > 100_000
			or sound < 0 or cracked < 0 or golden < 0
			or sound + cracked + golden != eggs
			or credit_cents < 0 or credit_cents > 2_000_000_000
		):
			return []
		restored.append({
			"worker_id": worker_id,
			"eggs": eggs,
			"sound": sound,
			"cracked": cracked,
			"golden": golden,
			"credit_cents": credit_cents,
		})
	return restored


func _validated_pecking_order_data(value: Variant) -> Dictionary:
	if not value is Array:
		return {"valid": false, "rows": []}
	var source := value as Array
	if source.size() > sim.workers.size():
		return {"valid": false, "rows": []}
	var restored: Array[Dictionary] = []
	var seen_ids: Dictionary[int, bool] = {}
	for index in source.size():
		var row_value: Variant = source[index]
		if not row_value is Dictionary:
			return {"valid": false, "rows": []}
		var row := row_value as Dictionary
		for field in [
			"rank", "worker_id", "eggs", "sound", "cracked", "golden",
			"credit_cents", "score",
		]:
			if not sim._is_integral_number(row.get(field, null)):
				return {"valid": false, "rows": []}
		if typeof(row.get("worker_name", null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "rows": []}
		if typeof(row.get("employed", null)) != TYPE_BOOL:
			return {"valid": false, "rows": []}
		var worker_id := int(row.get("worker_id", -1))
		var eggs := int(row.get("eggs", -1))
		var sound := int(row.get("sound", -1))
		var cracked := int(row.get("cracked", -1))
		var golden := int(row.get("golden", -1))
		var credit_cents := int(row.get("credit_cents", -1))
		if (
			int(row.get("rank", 0)) != index + 1
			or worker_id < 0 or worker_id >= sim.workers.size()
			or seen_ids.has(worker_id)
			or eggs < 0 or eggs > 100_000
			or sound < 0 or cracked < 0 or golden < 0
			or sound + cracked + golden != eggs
			or credit_cents < 0 or credit_cents > 2_000_000_000
			or int(row.get("score", -1)) != credit_cents
			or String(row.get("worker_name", "")).is_empty()
		):
			return {"valid": false, "rows": []}
		seen_ids[worker_id] = true
		restored.append({
			"rank": index + 1,
			"worker_id": worker_id,
			"worker_name": String(row.get("worker_name", "")),
			"employed": bool(row.get("employed", true)),
			"eggs": eggs,
			"sound": sound,
			"cracked": cracked,
			"golden": golden,
			"credit_cents": credit_cents,
			"score": credit_cents,
		})
	return {"valid": true, "rows": restored}


func _validated_credit_counts(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var restored: Dictionary = {}
	for style_id in DepartmentSimulation.CREDIT_STYLE_IDS:
		var raw: Variant = (value as Dictionary).get(String(style_id), null)
		if not sim._is_integral_number(raw):
			return {}
		var count := int(raw)
		if count < 0 or count > 9999:
			return {}
		restored[style_id] = count
	return restored


func _validated_credit_allocation(value: Variant, saved_day: int) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	for field in ["day", "worker_id", "cost_cents"]:
		if not sim._is_integral_number(source.get(field, null)):
			return {"valid": false, "record": {}}
	for field in ["decision_id", "option_id", "style_id", "worker_name", "outcome"]:
		if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	for field in ["special_event", "projected"]:
		if typeof(source.get(field, null)) != TYPE_BOOL:
			return {"valid": false, "record": {}}
	var record_day := int(source.get("day", 0))
	var worker_id := int(source.get("worker_id", -1))
	var cost_cents := int(source.get("cost_cents", -1))
	var option_id := StringName(String(source.get("option_id", "")))
	var style_id := StringName(String(source.get("style_id", "")))
	if (
		record_day < 1 or record_day > saved_day
		or worker_id < -1 or worker_id >= sim.workers.size()
		or cost_cents < 0 or cost_cents > 2_000_000_000
		or option_id not in DepartmentSimulation.CREDIT_OPTION_IDS
		or style_id not in DepartmentSimulation.CREDIT_STYLE_IDS
		or String(source.get("outcome", "")).is_empty()
	):
		return {"valid": false, "record": {}}
	return {
		"valid": true,
		"record": {
			"day": record_day,
			"decision_id": String(source.get("decision_id", "")),
			"option_id": String(option_id),
			"style_id": String(style_id),
			"worker_id": worker_id,
			"worker_name": String(source.get("worker_name", "")),
			"cost_cents": cost_cents,
			"outcome": String(source.get("outcome", "")),
			"special_event": bool(source.get("special_event", false)),
			"projected": bool(source.get("projected", false)),
		},
	}


func _validated_restructuring_record(value: Variant, saved_day: int) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	var validated_base := _validated_credit_allocation(source, saved_day)
	if not bool(validated_base.get("valid", false)):
		return {"valid": false, "record": {}}
	var record := (validated_base.get("record", {}) as Dictionary).duplicate(true)
	var option_id := StringName(String(record.get("option_id", "")))
	if (
		StringName(String(record.get("decision_id", ""))) != &"flock_restructuring"
		or option_id not in [&"nominate_variance", &"fund_redeployment", &"contest_ranking"]
		or int(record.get("day", 0)) != DepartmentSimulation.FLOCK_RESTRUCTURING_SHIFT
		or not bool(record.get("special_event", false))
		or bool(record.get("projected", true))
	):
		return {"valid": false, "record": {}}
	for field in [
		"candidate_rank", "candidate_eggs", "candidate_cracked",
		"candidate_credit_cents", "replacement_worker_id",
	]:
		if not sim._is_integral_number(source.get(field, null)):
			return {"valid": false, "record": {}}
	for field in ["choice_label", "replacement_worker_name"]:
		if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	if typeof(source.get("candidate_employed_after", null)) != TYPE_BOOL:
		return {"valid": false, "record": {}}
	var candidate_before_value: Variant = source.get("candidate_before", {})
	if not candidate_before_value is Dictionary:
		return {"valid": false, "record": {}}
	var candidate_before := candidate_before_value as Dictionary
	for field in ["career_title", "specialty", "assignment"]:
		if typeof(candidate_before.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	if not sim._is_integral_number(candidate_before.get("career_xp", null)):
		return {"valid": false, "record": {}}
	for field in ["manager_trust", "grievance", "morale", "stress", "fatigue"]:
		if typeof(candidate_before.get(field, null)) not in [TYPE_FLOAT, TYPE_INT]:
			return {"valid": false, "record": {}}
		if float(candidate_before.get(field, -1.0)) < 0.0 or float(candidate_before.get(field, 101.0)) > 100.0:
			return {"valid": false, "record": {}}
	var candidate_rank := int(source.get("candidate_rank", 0))
	var candidate_eggs := int(source.get("candidate_eggs", -1))
	var candidate_cracked := int(source.get("candidate_cracked", -1))
	var candidate_credit_cents := int(source.get("candidate_credit_cents", -1))
	var replacement_worker_id := int(source.get("replacement_worker_id", -2))
	var candidate_employed_after := bool(source.get("candidate_employed_after", true))
	if (
		candidate_rank < 1 or candidate_rank > sim.workers.size()
		or candidate_eggs < 0 or candidate_cracked < 0 or candidate_cracked > candidate_eggs
		or candidate_credit_cents < 0
		or replacement_worker_id < -1 or replacement_worker_id >= sim.workers.size()
		or int(candidate_before.get("career_xp", -1)) < 0
		or String(source.get("choice_label", "")).is_empty()
		or (option_id == &"nominate_variance" and candidate_employed_after)
		or (option_id != &"nominate_variance" and not candidate_employed_after)
		or (option_id != &"nominate_variance" and replacement_worker_id != -1)
	):
		return {"valid": false, "record": {}}
	var normalized_before := {
		"career_title": String(candidate_before.get("career_title", "")),
		"career_xp": int(candidate_before.get("career_xp", 0)),
		"specialty": String(candidate_before.get("specialty", "")),
		"assignment": String(candidate_before.get("assignment", "")),
		"manager_trust": snappedf(float(candidate_before.get("manager_trust", 0.0)), 0.0001),
		"grievance": snappedf(float(candidate_before.get("grievance", 0.0)), 0.0001),
		"morale": snappedf(float(candidate_before.get("morale", 0.0)), 0.0001),
		"stress": snappedf(float(candidate_before.get("stress", 0.0)), 0.0001),
		"fatigue": snappedf(float(candidate_before.get("fatigue", 0.0)), 0.0001),
	}
	record.merge({
		"choice_label": String(source.get("choice_label", "")),
		"candidate_rank": candidate_rank,
		"candidate_eggs": candidate_eggs,
		"candidate_cracked": candidate_cracked,
		"candidate_credit_cents": candidate_credit_cents,
		"candidate_before": normalized_before,
		"candidate_employed_after": candidate_employed_after,
		"replacement_worker_id": replacement_worker_id,
		"replacement_worker_name": String(source.get("replacement_worker_name", "")),
	}, true)
	return {"valid": true, "record": record}


func _validated_flock_petition_record(value: Variant, saved_day: int) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	for field in ["version", "day", "sponsor_worker_id", "cost_cents", "effective_day"]:
		if not sim._is_integral_number(source.get(field, null)):
			return {"valid": false, "record": {}}
	for field in [
		"petition_type", "petition_title", "sponsor_worker_name", "response_id",
		"response_tier", "outcome",
	]:
		if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	for field in ["compact_scheduled", "work_to_rule_scheduled"]:
		if typeof(source.get(field, null)) != TYPE_BOOL:
			return {"valid": false, "record": {}}
	for field in ["solidarity_before", "solidarity_after"]:
		if typeof(source.get(field, null)) not in [TYPE_FLOAT, TYPE_INT]:
			return {"valid": false, "record": {}}
		var solidarity_value := float(source.get(field, -1.0))
		if not is_finite(solidarity_value) or solidarity_value < 0.0 or solidarity_value > 100.0:
			return {"valid": false, "record": {}}
	var evidence_value: Variant = source.get("evidence", [])
	if not evidence_value is Array or (evidence_value as Array).is_empty() or (evidence_value as Array).size() > 8:
		return {"valid": false, "record": {}}
	var evidence: Array[String] = []
	for entry in (evidence_value as Array):
		if typeof(entry) not in [TYPE_STRING, TYPE_STRING_NAME] or String(entry).is_empty():
			return {"valid": false, "record": {}}
		evidence.append(String(entry))
	var record_day := int(source.get("day", 0))
	var petition_type := StringName(String(source.get("petition_type", "")))
	var response_id := StringName(String(source.get("response_id", "")))
	var response_tier := StringName(String(source.get("response_tier", "")))
	var sponsor_id := int(source.get("sponsor_worker_id", -1))
	if (
		int(source.get("version", 0)) != 1
		or record_day not in DepartmentSimulation.FLOCK_PETITION_DAYS
		or record_day > saved_day
		or int(source.get("effective_day", 0)) != record_day + 1
		or petition_type not in DepartmentSimulation.FLOCK_PETITION_TYPES
		or response_id not in DepartmentSimulation.FLOCK_PETITION_RESPONSE_IDS
		or sponsor_id < 0 or sponsor_id >= sim.workers.size()
		or String(source.get("sponsor_worker_name", "")).is_empty()
		or String(source.get("petition_title", "")).is_empty()
		or String(source.get("outcome", "")).is_empty()
	):
		return {"valid": false, "record": {}}
	var expected_tier: StringName = &""
	var expected_cost := 0
	var expected_compact := false
	match response_id:
		&"sign_compact":
			expected_tier = &"binding"
			expected_cost = int((DepartmentSimulation.FLOCK_PETITION_DEFINITIONS[petition_type] as Dictionary).get("sign_cost_cents", -1))
			expected_compact = true
		&"offer_concession":
			expected_tier = &"concession"
			expected_cost = 400
		&"deny_and_monitor":
			expected_tier = &"denial"
			expected_cost = 0
	if (
		response_tier != expected_tier
		or int(source.get("cost_cents", -1)) != expected_cost
		or bool(source.get("compact_scheduled", false)) != expected_compact
		or (bool(source.get("work_to_rule_scheduled", false)) and response_id != &"deny_and_monitor")
	):
		return {"valid": false, "record": {}}
	return {
		"valid": true,
		"record": {
			"version": 1,
			"day": record_day,
			"petition_type": String(petition_type),
			"petition_title": String(source.get("petition_title", "")),
			"sponsor_worker_id": sponsor_id,
			"sponsor_worker_name": String(source.get("sponsor_worker_name", "")),
			"evidence": evidence,
			"response_id": String(response_id),
			"response_tier": String(response_tier),
			"cost_cents": expected_cost,
			"outcome": String(source.get("outcome", "")),
			"effective_day": record_day + 1,
			"compact_scheduled": expected_compact,
			"work_to_rule_scheduled": bool(source.get("work_to_rule_scheduled", false)),
			"solidarity_before": snappedf(float(source.get("solidarity_before", 0.0)), 0.0001),
			"solidarity_after": snappedf(float(source.get("solidarity_after", 0.0)), 0.0001),
		},
	}


func _validated_flock_petition_history(value: Variant, saved_day: int) -> Dictionary:
	if not value is Array or (value as Array).size() > DepartmentSimulation.FLOCK_PETITION_HISTORY_LIMIT:
		return {"valid": false, "records": []}
	var records: Array[Dictionary] = []
	var previous_day := 0
	for record_value in (value as Array):
		var validated := _validated_flock_petition_record(record_value, saved_day)
		if not bool(validated.get("valid", false)):
			return {"valid": false, "records": []}
		var record := validated.get("record", {}) as Dictionary
		if record.is_empty() or int(record.get("day", 0)) <= previous_day:
			return {"valid": false, "records": []}
		previous_day = int(record.get("day", 0))
		records.append(record)
	return {"valid": true, "records": records}


func _validated_flock_compact(value: Variant, saved_day: int) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	for field in ["version", "petition_day", "effective_day", "sponsor_worker_id"]:
		if not sim._is_integral_number(source.get(field, null)):
			return {"valid": false, "record": {}}
	for field in [
		"compact_id", "status", "petition_type", "compact_name",
		"sponsor_worker_name", "promise", "condition",
	]:
		if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	var petition_day := int(source.get("petition_day", 0))
	var effective_day := int(source.get("effective_day", 0))
	var petition_type := StringName(String(source.get("petition_type", "")))
	var status := StringName(String(source.get("status", "")))
	var sponsor_id := int(source.get("sponsor_worker_id", -1))
	if (
		int(source.get("version", 0)) != 1
		or petition_day not in DepartmentSimulation.FLOCK_PETITION_DAYS
		or effective_day != petition_day + 1
		or petition_type not in DepartmentSimulation.FLOCK_PETITION_TYPES
		or status not in [&"scheduled", &"active"]
		or sponsor_id < 0 or sponsor_id >= sim.workers.size()
		or String(source.get("compact_id", "")) != "D%d-%s-%d" % [petition_day, String(petition_type), sponsor_id]
		or String(source.get("sponsor_worker_name", "")).is_empty()
	):
		return {"valid": false, "record": {}}
	if (
		(status == &"scheduled" and saved_day != petition_day)
		or (status == &"active" and saved_day != effective_day)
	):
		return {"valid": false, "record": {}}
	var definition := DepartmentSimulation.FLOCK_PETITION_DEFINITIONS[petition_type] as Dictionary
	if (
		String(source.get("compact_name", "")) != String(definition.get("compact_name", ""))
		or String(source.get("promise", "")) != String(definition.get("promise", ""))
		or String(source.get("condition", "")) != String(definition.get("condition", ""))
	):
		return {"valid": false, "record": {}}
	var record := source.duplicate(true)
	record["version"] = 1
	record["petition_day"] = petition_day
	record["effective_day"] = effective_day
	record["sponsor_worker_id"] = sponsor_id
	for field in [
		"compact_id", "status", "petition_type", "compact_name",
		"sponsor_worker_name", "promise", "condition",
	]:
		record[field] = String(record.get(field, ""))
	return {"valid": true, "record": record}


func _validated_flock_compact_receipt(value: Variant, saved_day: int) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	for field in [
		"version", "petition_day", "effective_day", "resolved_day", "sponsor_worker_id",
	]:
		if not sim._is_integral_number(source.get(field, null)):
			return {"valid": false, "record": {}}
	for field in [
		"compact_id", "status", "petition_type", "compact_name", "sponsor_worker_name",
		"promise", "condition", "reason", "outcome",
	]:
		if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	if typeof(source.get("work_to_rule_scheduled", null)) != TYPE_BOOL:
		return {"valid": false, "record": {}}
	var petition_day := int(source.get("petition_day", 0))
	var effective_day := int(source.get("effective_day", 0))
	var resolved_day := int(source.get("resolved_day", 0))
	var petition_type := StringName(String(source.get("petition_type", "")))
	var status := StringName(String(source.get("status", "")))
	var sponsor_id := int(source.get("sponsor_worker_id", -1))
	if (
		int(source.get("version", 0)) != 1
		or petition_day not in DepartmentSimulation.FLOCK_PETITION_DAYS
		or effective_day != petition_day + 1
		or resolved_day < effective_day or resolved_day > saved_day
		or petition_type not in DepartmentSimulation.FLOCK_PETITION_TYPES
		or status not in [&"fulfilled", &"breached"]
		or sponsor_id < 0 or sponsor_id >= sim.workers.size()
		or String(source.get("compact_id", "")) != "D%d-%s-%d" % [petition_day, String(petition_type), sponsor_id]
		or String(source.get("sponsor_worker_name", "")).is_empty()
		or String(source.get("reason", "")).is_empty()
		or String(source.get("outcome", "")).is_empty()
		or (status == &"fulfilled" and bool(source.get("work_to_rule_scheduled", true)))
	):
		return {"valid": false, "record": {}}
	var definition := DepartmentSimulation.FLOCK_PETITION_DEFINITIONS[petition_type] as Dictionary
	if (
		String(source.get("compact_name", "")) != String(definition.get("compact_name", ""))
		or String(source.get("promise", "")) != String(definition.get("promise", ""))
		or String(source.get("condition", "")) != String(definition.get("condition", ""))
	):
		return {"valid": false, "record": {}}
	var record := source.duplicate(true)
	for field in [
		"version", "petition_day", "effective_day", "resolved_day", "sponsor_worker_id",
	]:
		record[field] = int(record.get(field, 0))
	for field in [
		"compact_id", "status", "petition_type", "compact_name", "sponsor_worker_name",
		"promise", "condition", "reason", "outcome",
	]:
		record[field] = String(record.get(field, ""))
	record["work_to_rule_scheduled"] = bool(record.get("work_to_rule_scheduled", false))
	return {"valid": true, "record": record}


func _validated_work_to_rule_record(value: Variant, saved_day: int) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	for field in ["version", "petition_day", "effective_day", "sponsor_worker_id"]:
		if not sim._is_integral_number(source.get(field, null)):
			return {"valid": false, "record": {}}
	for field in ["trigger", "status", "sponsor_worker_name", "outcome"]:
		if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	for field in ["work_multiplier", "crack_modifier"]:
		if typeof(source.get(field, null)) not in [TYPE_FLOAT, TYPE_INT]:
			return {"valid": false, "record": {}}
	var status := StringName(String(source.get("status", "")))
	var trigger := StringName(String(source.get("trigger", "")))
	var petition_day := int(source.get("petition_day", 0))
	var effective_day := int(source.get("effective_day", 0))
	var sponsor_id := int(source.get("sponsor_worker_id", -1))
	if (
		int(source.get("version", 0)) != 1
		or trigger not in [&"petition_denied", &"compact_breached"]
		or status not in [&"scheduled", &"active", &"completed"]
		or petition_day not in DepartmentSimulation.FLOCK_PETITION_DAYS
		or effective_day <= petition_day or effective_day > mini(9999, petition_day + 2)
		or sponsor_id < 0 or sponsor_id >= sim.workers.size()
		or String(source.get("sponsor_worker_name", "")).is_empty()
		or String(source.get("outcome", "")).is_empty()
		or not is_equal_approx(float(source.get("work_multiplier", 0.0)), DepartmentSimulation.WORK_TO_RULE_WORK_MULTIPLIER)
		or not is_equal_approx(float(source.get("crack_modifier", 0.0)), DepartmentSimulation.WORK_TO_RULE_CRACK_MODIFIER)
	):
		return {"valid": false, "record": {}}
	if (
		(status == &"scheduled" and effective_day <= saved_day)
		or (status == &"active" and effective_day != saved_day)
	):
		return {"valid": false, "record": {}}
	if status == &"completed":
		if not sim._is_integral_number(source.get("completed_day", null)):
			return {"valid": false, "record": {}}
		if int(source.get("completed_day", 0)) != effective_day or effective_day > saved_day:
			return {"valid": false, "record": {}}
	var record := source.duplicate(true)
	for field in ["version", "petition_day", "effective_day", "sponsor_worker_id"]:
		record[field] = int(record.get(field, 0))
	if record.has("completed_day"):
		record["completed_day"] = int(record.get("completed_day", 0))
	for field in ["trigger", "status", "sponsor_worker_name", "outcome"]:
		record[field] = String(record.get(field, ""))
	record["work_multiplier"] = DepartmentSimulation.WORK_TO_RULE_WORK_MULTIPLIER
	record["crack_modifier"] = DepartmentSimulation.WORK_TO_RULE_CRACK_MODIFIER
	return {"valid": true, "record": record}


func _is_valid_pending_flock_petition(value: Variant, saved_day: int) -> bool:
	if not value is Dictionary:
		return false
	var source := value as Dictionary
	if StringName(source.get("id", &"")) != DepartmentSimulation.FLOCK_PETITION_INCIDENT_ID:
		return true
	if (
		StringName(source.get("kind", &"")) != &"incident"
		or StringName(source.get("category", &"")) != DepartmentSimulation.FLOCK_PETITION_CATEGORY
		or int(source.get("day", 0)) != saved_day
		or saved_day not in DepartmentSimulation.FLOCK_PETITION_DAYS
	):
		return false
	var petition_type := StringName(source.get("petition_type", &""))
	var sponsor_id := int(source.get("sponsor_worker_id", -1))
	if petition_type not in DepartmentSimulation.FLOCK_PETITION_TYPES or sponsor_id < 0 or sponsor_id >= sim.workers.size():
		return false
	var petition_value: Variant = source.get("petition", {})
	var evidence_value: Variant = source.get("evidence", [])
	if not petition_value is Dictionary or not evidence_value is Array or (evidence_value as Array).is_empty():
		return false
	var petition := petition_value as Dictionary
	if (
		int(petition.get("version", 0)) != 1
		or StringName(petition.get("petition_type", &"")) != petition_type
		or int(petition.get("sponsor_worker_id", -1)) != sponsor_id
		or String(petition.get("sponsor_worker_name", "")) != String(source.get("sponsor_worker_name", ""))
		or int(petition.get("effective_day", 0)) != saved_day + 1
		or not is_equal_approx(float(petition.get("work_to_rule_threshold", -1.0)), DepartmentSimulation.WORK_TO_RULE_SOLIDARITY_THRESHOLD)
		or petition.get("evidence", []) != evidence_value
	):
		return false
	var options_value: Variant = source.get("options", [])
	if not options_value is Array or (options_value as Array).size() != DepartmentSimulation.FLOCK_PETITION_RESPONSE_IDS.size():
		return false
	var seen: Dictionary[StringName, bool] = {}
	for option_value in (options_value as Array):
		if not option_value is Dictionary:
			return false
		var option := option_value as Dictionary
		var option_id := StringName(option.get("id", &""))
		if option_id not in DepartmentSimulation.FLOCK_PETITION_RESPONSE_IDS or seen.has(option_id):
			return false
		seen[option_id] = true
		var expected_cost := 0
		var expected_tier: StringName = &""
		match option_id:
			&"sign_compact":
				expected_cost = int((DepartmentSimulation.FLOCK_PETITION_DEFINITIONS[petition_type] as Dictionary).get("sign_cost_cents", -1))
				expected_tier = &"binding"
			&"offer_concession":
				expected_cost = 400
				expected_tier = &"concession"
			&"deny_and_monitor":
				expected_tier = &"denial"
		if (
			int(option.get("cost_cents", -1)) != expected_cost
			or StringName(option.get("response_tier", &"")) != expected_tier
		):
			return false
	return true


func _highest_claim_id() -> int:
	var highest := 0
	for lane in DepartmentSimulation.CLAIM_LANES:
		for claim_value in (sim._claim_queues.get(lane, []) as Array):
			var claim := claim_value as ClaimState
			if claim != null:
				highest = maxi(highest, claim.id)
	for claim in sim._pending_rework:
		if claim != null:
			highest = maxi(highest, claim.id)
	for worker in sim.workers:
		if worker.current_claim != null:
			highest = maxi(highest, worker.current_claim.id)
	# Signed folders receive immutable IDs before their timed arrival. Include
	# unreleased and already completed contract IDs so a restored allocator can
	# never recycle one into ordinary intake.
	for claim_id_value in sim.active_market_contract.get("claim_ids", []):
		if sim._is_integral_number(claim_id_value):
			highest = maxi(highest, int(claim_id_value))
	return highest


func _is_valid_feed_procurement_quote_state(state: FeedProcurementState) -> bool:
	for lot in state.lots:
		var offer_id := StringName(String(lot.get("offer_id", "")))
		if int(lot.get("unit_cost_cents", -1)) != sim._feed_offer_unit_price_cents(
			offer_id,
			int(lot.get("ordered_day", 0)),
		):
			return false
	if not state.last_order.is_empty():
		var order_offer_id := StringName(String(state.last_order.get("offer_id", "")))
		if int(state.last_order.get("unit_cost_cents", -1)) != sim._feed_offer_unit_price_cents(
			order_offer_id,
			int(state.last_order.get("day", 0)),
		):
			return false
	if not state.last_consumption.is_empty():
		if int(state.last_consumption.get("spot_unit_price_cents", -1)) != sim._feed_spot_unit_price_cents(
			int(state.last_consumption.get("day", 0))
		):
			return false
	if not state.last_spoilage.is_empty():
		for row_value in state.last_spoilage.get("lots", []):
			var row := row_value as Dictionary
			var spoil_offer_id := StringName(String(row.get("offer_id", "")))
			if not DepartmentSimulation.FEED_PROCUREMENT_OFFER_DEFINITIONS.has(spoil_offer_id):
				return false
			var definition := DepartmentSimulation.FEED_PROCUREMENT_OFFER_DEFINITIONS[spoil_offer_id] as Dictionary
			var ordered_day := (
				int(row.get("expired_day", 0))
				- int(definition.get("shelf_shifts", 1))
				+ 1
			)
			if int(row.get("unit_cost_cents", -1)) != sim._feed_offer_unit_price_cents(
				spoil_offer_id,
				ordered_day,
			):
				return false
	return true


func _validated_incident_response_history(value: Variant, saved_day: int) -> Dictionary:
	if not value is Array or (value as Array).size() > DepartmentSimulation.INCIDENT_RESPONSE_HISTORY_LIMIT:
		return {"valid": false, "history": []}
	var restored: Array[Dictionary] = []
	var previous_day := 0
	var previous_serial := 0
	for record_value in value as Array:
		if not record_value is Dictionary:
			return {"valid": false, "history": []}
		var record := record_value as Dictionary
		for integral_field in ["version", "day", "serial"]:
			if not sim._is_integral_number(record.get(integral_field, null)):
				return {"valid": false, "history": []}
		var record_version := int(record.get("version", 0))
		var record_day := int(record.get("day", 0))
		var record_serial := int(record.get("serial", 0))
		var incident_value: Variant = record.get("incident_id", null)
		var option_value: Variant = record.get("option_id", null)
		if (
			record_version != DepartmentSimulation.INCIDENT_RESPONSE_VERSION
			or record_day < 1
			or record_day > saved_day
			or record_day < previous_day
			or record_serial < 1
			or record_serial <= previous_serial
			or typeof(incident_value) not in [TYPE_STRING, TYPE_STRING_NAME]
			or typeof(option_value) not in [TYPE_STRING, TYPE_STRING_NAME]
		):
			return {"valid": false, "history": []}
		var incident_id := StringName(String(incident_value))
		var option_id := StringName(String(option_value))
		if sim._incident_choice_definition(incident_id, option_id).is_empty():
			return {"valid": false, "history": []}
		restored.append({
			"version": DepartmentSimulation.INCIDENT_RESPONSE_VERSION,
			"day": record_day,
			"serial": record_serial,
			"incident_id": incident_id,
			"option_id": option_id,
		})
		previous_day = record_day
		previous_serial = record_serial
	return {"valid": true, "history": restored}


func _incident_pivot_receipts_from_history(history: Array) -> Array[Dictionary]:
	var receipts: Array[Dictionary] = []
	var prior_history: Array[Dictionary] = []
	var mastered_pairs: Dictionary[StringName, bool] = {}
	for record_value: Variant in history:
		if not record_value is Dictionary:
			continue
		var record := record_value as Dictionary
		var incident_id := StringName(record.get("incident_id", &""))
		var pair_id := StringName(DepartmentSimulation.INCIDENT_PAIR_IDS.get(incident_id, &""))
		var memory := sim.incident_follow_through_snapshot(incident_id, prior_history)
		if pair_id != &"" and not mastered_pairs.has(pair_id):
			var receipt := sim._incident_pivot_receipt(
				incident_id,
				StringName(record.get("option_id", &"")),
				int(record.get("day", 0)),
				int(record.get("serial", 0)),
				memory,
			)
			if not receipt.is_empty():
				receipts.append(receipt)
				mastered_pairs[pair_id] = true
		prior_history.append(record.duplicate(true))
	return receipts


func _validated_incident_pivot_mastery_receipts(value: Variant, saved_day: int) -> Dictionary:
	if not value is Array or (value as Array).size() > DepartmentSimulation.INCIDENT_PAIR_ORDER.size():
		return {"valid": false, "receipts": []}
	var receipts: Array[Dictionary] = []
	var seen_pairs: Dictionary[StringName, bool] = {}
	var previous_pivot_serial := 0
	for receipt_value: Variant in value as Array:
		if not receipt_value is Dictionary:
			return {"valid": false, "receipts": []}
		var receipt := receipt_value as Dictionary
		for integer_field in ["version", "source_day", "source_serial", "pivot_day", "pivot_serial"]:
			if not sim._is_integral_number(receipt.get(integer_field, null)):
				return {"valid": false, "receipts": []}
		for id_field in ["pair_id", "source_incident_id", "source_option_id", "pivot_incident_id", "pivot_option_id"]:
			if typeof(receipt.get(id_field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
				return {"valid": false, "receipts": []}
		var pair_id := StringName(String(receipt.get("pair_id", "")))
		var source_incident_id := StringName(String(receipt.get("source_incident_id", "")))
		var source_option_id := StringName(String(receipt.get("source_option_id", "")))
		var pivot_incident_id := StringName(String(receipt.get("pivot_incident_id", "")))
		var pivot_option_id := StringName(String(receipt.get("pivot_option_id", "")))
		var source_day := int(receipt.get("source_day", 0))
		var source_serial := int(receipt.get("source_serial", 0))
		var pivot_day := int(receipt.get("pivot_day", 0))
		var pivot_serial := int(receipt.get("pivot_serial", 0))
		var target_definitions := DepartmentSimulation.INCIDENT_FOLLOW_THROUGH_DEFINITIONS.get(
			pivot_incident_id, {}
		) as Dictionary
		var follow_through := target_definitions.get(source_option_id, {}) as Dictionary
		if (
			int(receipt.get("version", 0)) != DepartmentSimulation.INCIDENT_PIVOT_MASTERY_VERSION
			or pair_id not in DepartmentSimulation.INCIDENT_PAIR_ORDER
			or seen_pairs.has(pair_id)
			or StringName(DepartmentSimulation.INCIDENT_PAIR_IDS.get(source_incident_id, &"")) != pair_id
			or StringName(DepartmentSimulation.INCIDENT_PAIR_IDS.get(pivot_incident_id, &"")) != pair_id
			or StringName(DepartmentSimulation.INCIDENT_PAIR_SOURCE.get(pivot_incident_id, &"")) != source_incident_id
			or sim._incident_choice_definition(source_incident_id, source_option_id).is_empty()
			or sim._incident_choice_definition(pivot_incident_id, pivot_option_id).is_empty()
			or StringName(follow_through.get("affected_option_id", &"")) != pivot_option_id
			or source_day < 1
			or source_day > pivot_day
			or pivot_day > saved_day
			or source_serial < 1
			or source_serial >= pivot_serial
			or pivot_serial <= previous_pivot_serial
		):
			return {"valid": false, "receipts": []}
		seen_pairs[pair_id] = true
		previous_pivot_serial = pivot_serial
		receipts.append({
			"version": DepartmentSimulation.INCIDENT_PIVOT_MASTERY_VERSION,
			"pair_id": pair_id,
			"source_day": source_day,
			"source_serial": source_serial,
			"source_incident_id": source_incident_id,
			"source_option_id": source_option_id,
			"pivot_day": pivot_day,
			"pivot_serial": pivot_serial,
			"pivot_incident_id": pivot_incident_id,
			"pivot_option_id": pivot_option_id,
		})
	return {"valid": true, "receipts": receipts}
