class_name FacilityOperations
extends RefCounted

## Facility and campus purchases, status, construction and upkeep.
## Holds no state of its own: every read and write goes through the owning
## DepartmentSimulation so behaviour is identical to the original in-class methods.

## Weak back-reference: the simulation owns this component, so a strong
## reference here would form a RefCounted cycle and leak both objects.
var _sim_ref: WeakRef


func _init(owner_node: DepartmentSimulation) -> void:
	_sim_ref = weakref(owner_node)

func _ensure_manager_posts_for_office_level() -> void:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var authorized_count := clampi(facility_level(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID) + 1, 1, 4)
	while sim.manager_roster.size() < authorized_count:
		var slot_index := sim.manager_roster.size()
		sim.manager_roster.append(sim._new_manager_record(
			DepartmentSimulation.MANAGER_DEFAULT_HIRE_ORDER[slot_index], slot_index, sim.day
		))


func facility_level(facility_id: StringName) -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if not DepartmentSimulation.FACILITY_DEFINITIONS.has(facility_id):
		return -1
	return int(sim.owned_facilities.get(facility_id, 0))


func has_facility(facility_id: StringName) -> bool:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return sim._market_desk.has_facility(facility_id)


func _claim_capacity_for_facilities_and_campus(
	facilities: Dictionary,
	campus_state: Dictionary,
	portfolio_bonus: int = 0,
) -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return (
		sim._claim_capacity_for_facilities(facilities)
		+ _campus_claim_capacity_bonus_for_state(campus_state)
		+ maxi(0, portfolio_bonus)
	)


func _service_coop_requirement(schedule: Array[int], target_level: int) -> int:
	if target_level <= 0 or target_level > schedule.size():
		return 0
	return int(schedule[target_level - 1])


func _facility_level_schedule_value(schedule: Array, level: int, fallback: int) -> int:
	if schedule.is_empty():
		return fallback
	var index := clampi(level, 0, schedule.size() - 1)
	return int(schedule[index])


func _facility_tier_requirement(schedule: Array, target_level: int) -> int:
	if target_level <= 0 or schedule.is_empty():
		return 0
	var index := clampi(target_level - 1, 0, schedule.size() - 1)
	return int(schedule[index])


func _facility_unlock_day_for_level(definition: Dictionary, target_level: int) -> int:
	var unlock_days_value: Variant = definition.get("unlock_days", null)
	if unlock_days_value is Array and target_level > 0:
		var unlock_days := unlock_days_value as Array
		var index := target_level - 1
		if index >= 0 and index < unlock_days.size():
			return maxi(1, int(unlock_days[index]))
	return maxi(1, int(definition.get("unlock_day", 1)))


func _qualified_active_worker_count(minimum_career_level: int) -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var count := 0
	for worker in sim.workers:
		if worker.employed and worker.career_level() >= minimum_career_level:
			count += 1
	return count


func _farmgate_storage_capacity_for_level_and_campus(
	farmgate_level: int,
	campus_state: Dictionary,
	portfolio_bonus_eggs: int = 0,
) -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var base_capacity := _facility_level_schedule_value(
		DepartmentSimulation.FARMGATE_DISPATCH_STORAGE_CAPACITY_EGGS,
		farmgate_level,
		0,
	)
	if base_capacity <= 0:
		return 0
	return mini(
		DepartmentSimulation.CAMPUS_FARMGATE_MAX_STORAGE_EGGS + maxi(0, portfolio_bonus_eggs),
		base_capacity
		+ _campus_farmgate_capacity_bonus_for_state(campus_state, farmgate_level)
		+ maxi(0, portfolio_bonus_eggs),
	)


func facility_effects() -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var crack_modifier := 0.0
	var rework_speed_multiplier := 1.0
	for facility_id in DepartmentSimulation.FACILITY_ORDER:
		var level := facility_level(facility_id)
		if level <= 0:
			continue
		var definition := DepartmentSimulation.FACILITY_DEFINITIONS[facility_id] as Dictionary
		crack_modifier += float(definition.get("crack_modifier", 0.0)) * level
		rework_speed_multiplier *= pow(
			float(definition.get("rework_speed_multiplier", 1.0)),
			level,
		)
	var packing_level := maxi(0, facility_level(DepartmentSimulation.PACKING_ANNEX_ID))
	var packing_value_bonus := DepartmentSimulation.PACKING_VALUE_BONUS_PER_LEVEL * packing_level
	var records_level := maxi(0, facility_level(DepartmentSimulation.RECORDS_ANNEX_ID))
	var records_claim_capacity_bonus := DepartmentSimulation.CLAIM_CAPACITY_PER_RECORDS_LEVEL * records_level
	var campus_claim_capacity_bonus := _campus_claim_capacity_bonus_for_state(sim.campus_expansion_state)
	var claim_capacity_bonus := records_claim_capacity_bonus + campus_claim_capacity_bonus
	var service_coop_level := maxi(0, facility_level(DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID))
	var negotiation_room_level := maxi(0, facility_level(DepartmentSimulation.FARM_MUTUAL_NEGOTIATION_ROOM_ID))
	var wellness_level := maxi(0, facility_level(DepartmentSimulation.WELLNESS_NEST_ID))
	var training_level := maxi(0, facility_level(DepartmentSimulation.TRAINING_ROOST_ID))
	var rooster_operations_level := maxi(0, facility_level(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID))
	var it_coop_level := maxi(0, facility_level(DepartmentSimulation.IT_COOP_ID))
	var flock_relations_level := maxi(0, facility_level(DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID))
	var feed_procurement_level := maxi(0, facility_level(DepartmentSimulation.FEED_PROCUREMENT_COOP_ID))
	var farmer_relations_gallery_level := maxi(0, facility_level(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID))
	var farmgate_dispatch_level := maxi(0, facility_level(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID))
	var strain_basis_points := sim.wellness_strain_gain_basis_points()
	var break_recovery_basis_points := sim.wellness_break_recovery_basis_points()
	var overnight_fatigue_millipoints := sim.wellness_overnight_fatigue_recovery_millipoints()
	var overnight_stress_millipoints := sim.wellness_overnight_stress_recovery_millipoints()
	var sponsorship_cost := sim.career_sponsorship_cost_cents()
	var training_work_basis_points := sim.pending_training_work_basis_points()
	return {
		"crack_modifier": crack_modifier,
		"crack_risk_modifier": crack_modifier,
		"crack_risk_basis_points": roundi(crack_modifier * 10_000.0),
		"rework_speed_multiplier": rework_speed_multiplier,
		"rework_processing_speed_multiplier": rework_speed_multiplier,
		"packing_annex_level": packing_level,
		"packing_value_bonus": packing_value_bonus,
		"packing_value_bonus_percent": roundi(packing_value_bonus * 100.0),
		"packing_value_multiplier": 1.0 + packing_value_bonus,
		"packing_carton_size": DepartmentSimulation.PACKING_CARTON_SIZE,
		"packing_carton_bonus_cents": DepartmentSimulation.PACKING_CARTON_BONUS_PER_LEVEL_CENTS * packing_level,
		"records_annex_level": records_level,
		"claim_capacity_base": DepartmentSimulation.BASE_CLAIM_CAPACITY,
		"claim_capacity_bonus": claim_capacity_bonus,
		"records_claim_capacity_bonus": records_claim_capacity_bonus,
		"campus_claim_capacity_bonus": campus_claim_capacity_bonus,
		"claim_capacity": DepartmentSimulation.BASE_CLAIM_CAPACITY + claim_capacity_bonus,
		"farm_mutual_service_coop_level": service_coop_level,
		"farm_mutual_negotiation_room_level": negotiation_room_level,
		"farm_mutual_negotiation_room_owned": negotiation_room_level > 0,
		"farm_mutual_premium_bonus_basis_points": (
			service_coop_level * DepartmentSimulation.SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
		),
		"farm_mutual_standing": sim.farm_mutual_standing(),
		"farm_mutual_standing_rank": sim.farm_mutual_standing_rank(),
		"wellness_nest_level": wellness_level,
		"wellness_strain_gain_basis_points": strain_basis_points,
		"wellness_strain_gain_multiplier": float(strain_basis_points) / 10_000.0,
		"wellness_break_recovery_basis_points": break_recovery_basis_points,
		"wellness_break_recovery_multiplier": float(break_recovery_basis_points) / 10_000.0,
		"wellness_break_morale_millipoints": sim.wellness_break_morale_millipoints(),
		"wellness_overnight_fatigue_recovery_millipoints": overnight_fatigue_millipoints,
		"wellness_overnight_stress_recovery_millipoints": overnight_stress_millipoints,
		"training_roost_level": training_level,
		"career_sponsorship_base_cost_cents": DepartmentSimulation.CAREER_SPONSORSHIP_COST_CENTS,
		"career_sponsorship_cost_cents": sponsorship_cost,
		"career_sponsorship_discount_cents": DepartmentSimulation.CAREER_SPONSORSHIP_COST_CENTS - sponsorship_cost,
		"cross_training_work_basis_points": training_work_basis_points,
		"cross_training_work_multiplier": float(training_work_basis_points) / 10_000.0,
		"career_coaching_xp_bonus": sim.career_coaching_xp_bonus(),
		"rooster_operations_office_level": rooster_operations_level,
		"personnel_action_limit": sim.personnel_action_limit(),
		"supervisor_payroll_cents": sim.supervisor_payroll_cents(),
		"surveillance_grievance_millipoints": sim.rooster_surveillance_grievance_millipoints(),
		"surveillance_stress_millipoints": sim.rooster_surveillance_stress_millipoints(),
		"surveillance_solidarity_millipoints": sim.rooster_surveillance_solidarity_millipoints(),
		"it_coop_level": it_coop_level,
		"automation_work_basis_points": sim.automation_work_basis_points(),
		"automation_work_multiplier": sim.automation_work_multiplier(),
		"automation_specialty_grace_minutes": sim.automation_specialty_grace_minutes(),
		"automation_recognizes_secondary_specialties": sim.automation_recognizes_secondary_specialties(),
		"automation_compliance_exposure_millipoints": sim.automation_compliance_exposure_millipoints(),
		"ledger_molt_patch_cost_cents": sim.ledger_molt_patch_cost_cents(),
		"ledger_molt_spreadsheet_compliance_loss_millipoints": sim.ledger_molt_spreadsheet_compliance_loss_millipoints(),
		"ledger_molt_spreadsheet_crack_basis_points": sim.ledger_molt_spreadsheet_crack_basis_points(),
		"flock_relations_office_level": flock_relations_level,
		"flock_relations_case_capacity": sim.flock_relations_case_capacity(),
		"flock_relations_resolution_limit": sim.flock_relations_resolution_limit(),
		"feed_procurement_coop_level": feed_procurement_level,
		"feed_procurement_capacity_scoops": sim._feed_procurement_capacity_scoops(),
		"farmer_relations_gallery_level": farmer_relations_gallery_level,
		"farmgate_dispatch_depot_level": farmgate_dispatch_level,
		"farmgate_storage_capacity_eggs": sim._farmgate_storage_capacity_eggs(),
		"campus_farmgate_storage_bonus_eggs": _campus_farmgate_capacity_bonus_for_state(
			sim.campus_expansion_state,
			farmgate_dispatch_level,
		),
		"farmgate_dispatch_capacity_eggs": sim._farmgate_dispatch_capacity_eggs(),
		"farmgate_shelf_life_shifts": sim._farmgate_shelf_life_shifts(),
	}


func facility_catalog() -> Array[Dictionary]:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var catalog: Array[Dictionary] = []
	for facility_id in DepartmentSimulation.FACILITY_ORDER:
		catalog.append(facility_status(facility_id))
	return catalog


func facility_status(facility_id: StringName) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if not DepartmentSimulation.FACILITY_DEFINITIONS.has(facility_id):
		return {
			"known": false,
			"id": facility_id,
			"name": "UNKNOWN FACILITY",
			"short_name": "UNKNOWN",
			"description": "This facility code is not on the capital schedule.",
			"cost_cents": 0,
			"daily_maintenance_cents": 0,
			"current_maintenance_cents": 0,
			"next_maintenance_cents": 0,
			"maintenance_delta_cents": 0,
			"benefits": [] as Array[String],
			"tradeoffs": [] as Array[String],
			"owned": false,
			"installed": false,
			"maxed": false,
			"level": 0,
			"next_level": 0,
			"max_level": 0,
			"unlocked": false,
			"planning_open": sim.staffing_planning_open(),
			"affordable": false,
			"can_purchase": false,
			"reason": "Facility code is not on the authorized capital schedule.",
			"action_reason": "Facility code is not on the authorized capital schedule.",
			"purchase_label": "UNLISTED FACILITY",
			"projected_spendable_fund_cents": sim.spendable_fund_cents(),
		}

	var definition := DepartmentSimulation.FACILITY_DEFINITIONS[facility_id] as Dictionary
	var level := facility_level(facility_id)
	var max_level := int(definition.get("max_level", 1))
	var installed := level > 0
	var maxed := level >= max_level
	var next_level := mini(max_level, level + 1)
	var unlock_id := StringName(definition.get("unlock_id", &""))
	var unlock_day := _facility_unlock_day_for_level(definition, next_level)
	var base_unlocked := (
		(unlock_id == &"" or sim.has_campaign_unlock(unlock_id))
		and sim.day >= unlock_day
	)
	var market_standing := sim.farm_mutual_standing()
	var required_market_standing := 0
	var required_claim_capacity := 0
	var required_active_staff := 0
	var required_office_capacity := 0
	var required_service_coop_level := 0
	var required_wellness_nest_level := 0
	var required_packing_annex_level := 0
	var required_records_annex_level := 0
	var required_rooster_operations_level := 0
	var required_farmer_relations_gallery_level := 0
	var required_harvest_credit_standing := 0
	var required_career_level := 0
	var qualified_staff_count := 0
	var harvest_credit_standing := int(sim._harvest_credit.public_standing)
	if facility_id == DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID:
		required_market_standing = _service_coop_requirement(
			DepartmentSimulation.SERVICE_COOP_LEVEL_STANDING_REQUIREMENTS,
			next_level,
		)
		required_claim_capacity = _service_coop_requirement(
			DepartmentSimulation.SERVICE_COOP_LEVEL_CLAIM_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _service_coop_requirement(
			DepartmentSimulation.SERVICE_COOP_LEVEL_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
	elif facility_id == DepartmentSimulation.FARM_MUTUAL_NEGOTIATION_ROOM_ID:
		required_market_standing = DepartmentSimulation.NEGOTIATION_ROOM_REQUIRED_STANDING
		required_service_coop_level = DepartmentSimulation.NEGOTIATION_ROOM_REQUIRED_SERVICE_COOP_LEVEL
	elif facility_id == DepartmentSimulation.WELLNESS_NEST_ID:
		required_office_capacity = _facility_tier_requirement(
			DepartmentSimulation.WELLNESS_NEST_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			DepartmentSimulation.WELLNESS_NEST_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
	elif facility_id == DepartmentSimulation.TRAINING_ROOST_ID:
		required_office_capacity = _facility_tier_requirement(
			DepartmentSimulation.TRAINING_ROOST_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			DepartmentSimulation.TRAINING_ROOST_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
		required_wellness_nest_level = next_level
		required_career_level = _facility_tier_requirement(
			DepartmentSimulation.TRAINING_ROOST_CAREER_LEVEL_REQUIREMENTS,
			next_level,
		)
		qualified_staff_count = _qualified_active_worker_count(required_career_level)
	elif facility_id == DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID:
		required_office_capacity = _facility_tier_requirement(
			DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			DepartmentSimulation.ROOSTER_OPERATIONS_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
	elif facility_id == DepartmentSimulation.IT_COOP_ID:
		required_office_capacity = _facility_tier_requirement(
			DepartmentSimulation.IT_COOP_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			DepartmentSimulation.IT_COOP_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
		required_records_annex_level = next_level
		required_rooster_operations_level = next_level
	elif facility_id == DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID:
		required_office_capacity = _facility_tier_requirement(
			DepartmentSimulation.FLOCK_RELATIONS_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			DepartmentSimulation.FLOCK_RELATIONS_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
		required_rooster_operations_level = next_level
		required_wellness_nest_level = next_level
	elif facility_id == DepartmentSimulation.FEED_PROCUREMENT_COOP_ID:
		required_office_capacity = _facility_tier_requirement(
			DepartmentSimulation.FEED_PROCUREMENT_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			DepartmentSimulation.FEED_PROCUREMENT_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
	elif facility_id == DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID:
		required_office_capacity = _facility_tier_requirement(
			DepartmentSimulation.FARMER_RELATIONS_GALLERY_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			DepartmentSimulation.FARMER_RELATIONS_GALLERY_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
		required_packing_annex_level = next_level
	elif facility_id == DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID:
		required_office_capacity = _facility_tier_requirement(
			DepartmentSimulation.FARMGATE_DISPATCH_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			DepartmentSimulation.FARMGATE_DISPATCH_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
		required_packing_annex_level = _facility_tier_requirement(
			DepartmentSimulation.FARMGATE_DISPATCH_PACKING_LEVEL_REQUIREMENTS,
			next_level,
		)
		required_farmer_relations_gallery_level = _facility_tier_requirement(
			DepartmentSimulation.FARMGATE_DISPATCH_GALLERY_LEVEL_REQUIREMENTS,
			next_level,
		)
		required_harvest_credit_standing = _facility_tier_requirement(
			DepartmentSimulation.FARMGATE_DISPATCH_STANDING_REQUIREMENTS,
			next_level,
		)
	var authored_gate_met := true
	if not maxed and facility_id == DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID:
		authored_gate_met = (
			market_standing >= required_market_standing
			and sim.current_claim_capacity() >= required_claim_capacity
			and sim.active_worker_count() >= required_active_staff
		)
	elif not maxed and facility_id == DepartmentSimulation.FARM_MUTUAL_NEGOTIATION_ROOM_ID:
		authored_gate_met = (
			market_standing >= required_market_standing
			and facility_level(DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID) >= required_service_coop_level
		)
	elif not maxed and facility_id == DepartmentSimulation.WELLNESS_NEST_ID:
		authored_gate_met = (
			sim.office_capacity >= required_office_capacity
			and sim.active_worker_count() >= required_active_staff
		)
	elif not maxed and facility_id == DepartmentSimulation.TRAINING_ROOST_ID:
		authored_gate_met = (
			sim.office_capacity >= required_office_capacity
			and sim.active_worker_count() >= required_active_staff
			and facility_level(DepartmentSimulation.WELLNESS_NEST_ID) >= required_wellness_nest_level
			and qualified_staff_count > 0
		)
	elif not maxed and facility_id == DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID:
		authored_gate_met = (
			sim.office_capacity >= required_office_capacity
			and sim.active_worker_count() >= required_active_staff
		)
	elif not maxed and facility_id == DepartmentSimulation.IT_COOP_ID:
		authored_gate_met = (
			sim.office_capacity >= required_office_capacity
			and sim.active_worker_count() >= required_active_staff
			and facility_level(DepartmentSimulation.RECORDS_ANNEX_ID) >= required_records_annex_level
			and facility_level(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID)
			>= required_rooster_operations_level
		)
	elif not maxed and facility_id == DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID:
		authored_gate_met = (
			sim.office_capacity >= required_office_capacity
			and sim.active_worker_count() >= required_active_staff
			and facility_level(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID)
			>= required_rooster_operations_level
			and facility_level(DepartmentSimulation.WELLNESS_NEST_ID) >= required_wellness_nest_level
		)
	elif not maxed and facility_id == DepartmentSimulation.FEED_PROCUREMENT_COOP_ID:
		authored_gate_met = (
			sim.office_capacity >= required_office_capacity
			and sim.active_worker_count() >= required_active_staff
		)
	elif not maxed and facility_id == DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID:
		authored_gate_met = (
			sim.office_capacity >= required_office_capacity
			and sim.active_worker_count() >= required_active_staff
			and facility_level(DepartmentSimulation.PACKING_ANNEX_ID) >= required_packing_annex_level
		)
	elif not maxed and facility_id == DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID:
		authored_gate_met = (
			sim.office_capacity >= required_office_capacity
			and sim.active_worker_count() >= required_active_staff
			and facility_level(DepartmentSimulation.PACKING_ANNEX_ID) >= required_packing_annex_level
			and facility_level(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID)
			>= required_farmer_relations_gallery_level
			and harvest_credit_standing >= required_harvest_credit_standing
		)
	var unlocked := base_unlocked and authored_gate_met
	var planning_open := sim.staffing_planning_open()
	var cost_cents := 0 if maxed else _facility_cost_for_level(definition, next_level)
	var current_maintenance_cents := _facility_maintenance_for_level(definition, level)
	var next_maintenance_cents := (
		current_maintenance_cents
		if maxed else
		_facility_maintenance_for_level(definition, next_level)
	)
	var maintenance_delta_cents := maxi(
		0,
		next_maintenance_cents - current_maintenance_cents,
	)
	var current_rooster_operations_level := facility_level(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID)
	var preview_rooster_operations_level := (
		next_level
		if facility_id == DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID and not maxed else
		current_rooster_operations_level
	)
	var current_supervisor_payroll_cents := _facility_level_schedule_value(
		DepartmentSimulation.ROOSTER_SUPERVISOR_PAYROLL_CENTS,
		current_rooster_operations_level,
		0,
	)
	var next_supervisor_payroll_cents := _facility_level_schedule_value(
		DepartmentSimulation.ROOSTER_SUPERVISOR_PAYROLL_CENTS,
		preview_rooster_operations_level,
		0,
	)
	var supervisor_payroll_delta_cents := maxi(
		0,
		next_supervisor_payroll_cents - current_supervisor_payroll_cents,
	)
	var added_daily_operating_cents := (
		maintenance_delta_cents + supervisor_payroll_delta_cents
	)
	var required_spendable_cents := sim._required_spendable_for_obligation_change_cents(
		cost_cents,
		added_daily_operating_cents,
	)
	var spendable := sim.spendable_fund_cents()
	var affordable := not maxed and sim._projected_spendable_after_obligation_change_cents(
		cost_cents,
		added_daily_operating_cents,
	) >= 0
	var projected_spendable := spendable
	if not maxed:
		projected_spendable = sim._projected_spendable_after_obligation_change_cents(
			cost_cents,
			added_daily_operating_cents,
		)
	var reason := ""
	if maxed:
		reason = "%s is already fully commissioned." % String(definition["short_name"])
	elif facility_id in [
		DepartmentSimulation.WELLNESS_NEST_ID,
		DepartmentSimulation.TRAINING_ROOST_ID,
		DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID,
		DepartmentSimulation.IT_COOP_ID,
		DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID,
		DepartmentSimulation.FEED_PROCUREMENT_COOP_ID,
		DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID,
		DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID,
	] and sim.day < unlock_day:
		reason = "%s level %d files on Day %d; the bureau is on Day %d." % [
			String(definition["short_name"]),
			next_level,
			unlock_day,
			sim.day,
		]
	elif not base_unlocked:
		reason = String(definition.get(
			"unlock_requirement",
			"Complete the required milestone before commissioning this facility.",
		))
	elif facility_id == DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID and market_standing < required_market_standing:
		reason = "Service Coop level %d requires %d Farm Mutual standing; the bureau has %d." % [
			next_level,
			required_market_standing,
			market_standing,
		]
	elif facility_id == DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID and sim.current_claim_capacity() < required_claim_capacity:
		reason = "Service Coop level %d requires %d live-file roosts; the bureau has %d." % [
			next_level,
			required_claim_capacity,
			sim.current_claim_capacity(),
		]
	elif facility_id == DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID and sim.active_worker_count() < required_active_staff:
		reason = "Service Coop level %d requires %d active hens; the roster has %d." % [
			next_level,
			required_active_staff,
			sim.active_worker_count(),
		]
	elif facility_id == DepartmentSimulation.FARM_MUTUAL_NEGOTIATION_ROOM_ID and market_standing < required_market_standing:
		reason = "The Negotiation Room requires Gold standing (%d points); the bureau has %d." % [
			required_market_standing,
			market_standing,
		]
	elif (
		facility_id == DepartmentSimulation.FARM_MUTUAL_NEGOTIATION_ROOM_ID
		and facility_level(DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID) < required_service_coop_level
	):
		reason = "The Negotiation Room requires Service Coop level %d; the bureau has level %d." % [
			required_service_coop_level,
			maxi(0, facility_level(DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID)),
		]
	elif (
		facility_id in [
			DepartmentSimulation.WELLNESS_NEST_ID,
			DepartmentSimulation.TRAINING_ROOST_ID,
			DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID,
			DepartmentSimulation.IT_COOP_ID,
			DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID,
			DepartmentSimulation.FEED_PROCUREMENT_COOP_ID,
			DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID,
			DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID,
		]
		and sim.office_capacity < required_office_capacity
	):
		reason = "%s level %d requires office capacity %d; the bureau authorizes %d desks." % [
			String(definition["short_name"]),
			next_level,
			required_office_capacity,
			sim.office_capacity,
		]
	elif (
		facility_id in [
			DepartmentSimulation.WELLNESS_NEST_ID,
			DepartmentSimulation.TRAINING_ROOST_ID,
			DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID,
			DepartmentSimulation.IT_COOP_ID,
			DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID,
			DepartmentSimulation.FEED_PROCUREMENT_COOP_ID,
			DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID,
			DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID,
		]
		and sim.active_worker_count() < required_active_staff
	):
		reason = "%s level %d requires %d active hens; the roster has %d." % [
			String(definition["short_name"]),
			next_level,
			required_active_staff,
			sim.active_worker_count(),
		]
	elif (
		facility_id == DepartmentSimulation.TRAINING_ROOST_ID
		and facility_level(DepartmentSimulation.WELLNESS_NEST_ID) < required_wellness_nest_level
	):
		reason = "Training Roost level %d requires Wellness Nest level %d; the Nest is level %d." % [
			next_level,
			required_wellness_nest_level,
			facility_level(DepartmentSimulation.WELLNESS_NEST_ID),
		]
	elif facility_id == DepartmentSimulation.TRAINING_ROOST_ID and qualified_staff_count <= 0:
		reason = "Training Roost level %d requires an employed career-level %d hen." % [
			next_level,
			required_career_level,
		]
	elif (
		facility_id == DepartmentSimulation.IT_COOP_ID
		and facility_level(DepartmentSimulation.RECORDS_ANNEX_ID) < required_records_annex_level
	):
		reason = "IT Coop level %d requires Records Annex level %d; the Annex is level %d." % [
			next_level,
			required_records_annex_level,
			facility_level(DepartmentSimulation.RECORDS_ANNEX_ID),
		]
	elif (
		facility_id == DepartmentSimulation.IT_COOP_ID
		and facility_level(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID)
		< required_rooster_operations_level
	):
		reason = "IT Coop level %d requires Rooster Office level %d; the Office is level %d." % [
			next_level,
			required_rooster_operations_level,
			facility_level(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID),
		]
	elif (
		facility_id == DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID
		and facility_level(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID)
		< required_rooster_operations_level
	):
		reason = "Flock Relations level %d requires Rooster Office level %d; the Office is level %d." % [
			next_level,
			required_rooster_operations_level,
			facility_level(DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID),
		]
	elif (
		facility_id == DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID
		and facility_level(DepartmentSimulation.WELLNESS_NEST_ID) < required_wellness_nest_level
	):
		reason = "Flock Relations level %d requires Wellness Nest level %d; the Nest is level %d." % [
			next_level,
			required_wellness_nest_level,
			facility_level(DepartmentSimulation.WELLNESS_NEST_ID),
		]
	elif (
		facility_id == DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID
		and facility_level(DepartmentSimulation.PACKING_ANNEX_ID) < required_packing_annex_level
	):
		reason = "Credit Gallery level %d requires Packing Annex level %d; the Annex is level %d." % [
			next_level,
			required_packing_annex_level,
			facility_level(DepartmentSimulation.PACKING_ANNEX_ID),
		]
	elif (
		facility_id == DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID
		and facility_level(DepartmentSimulation.PACKING_ANNEX_ID) < required_packing_annex_level
	):
		reason = "Farmgate Depot level %d requires Packing Annex level %d; the Annex is level %d." % [
			next_level,
			required_packing_annex_level,
			facility_level(DepartmentSimulation.PACKING_ANNEX_ID),
		]
	elif (
		facility_id == DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID
		and facility_level(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID)
		< required_farmer_relations_gallery_level
	):
		reason = "Farmgate Depot level %d requires Harvest Credit Gallery level %d; the Gallery is level %d." % [
			next_level,
			required_farmer_relations_gallery_level,
			facility_level(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID),
		]
	elif (
		facility_id == DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID
		and harvest_credit_standing < required_harvest_credit_standing
	):
		reason = "Farmgate Depot level %d requires %d Harvest Credit standing; the bureau has %d." % [
			next_level,
			required_harvest_credit_standing,
			harvest_credit_standing,
		]
	elif sim.shift_phase != DepartmentSimulation.ShiftPhase.REVIEW:
		reason = "Capital facilities may only be commissioned during shift review."
	elif not sim.pending_decision.is_empty():
		reason = "Resolve the closing credit memo before commissioning capital facilities."
	elif not affordable:
		reason = "Facility denied: $%.2f more spendable Feed Fund required." % (
			float(-projected_spendable) / 100.0
		)
	var level_name := _facility_level_name(definition, level)
	var next_level_name := _facility_level_name(definition, next_level)
	var current_capacity := sim.current_claim_capacity()
	var next_claim_capacity := current_capacity
	if facility_id == DepartmentSimulation.RECORDS_ANNEX_ID and not maxed:
		next_claim_capacity += DepartmentSimulation.CLAIM_CAPACITY_PER_RECORDS_LEVEL
	var purchase_label := "FULLY COMMISSIONED"
	if not maxed:
		purchase_label = "%s LEVEL %d  ·  $%.2f" % [
			"BUILD" if level == 0 else "UPGRADE",
			next_level,
			float(cost_cents) / 100.0,
		]
	var current_wellness_level := facility_level(DepartmentSimulation.WELLNESS_NEST_ID)
	var current_training_level := facility_level(DepartmentSimulation.TRAINING_ROOST_ID)
	var preview_wellness_level := (
		next_level if facility_id == DepartmentSimulation.WELLNESS_NEST_ID else current_wellness_level
	)
	var preview_training_level := (
		next_level if facility_id == DepartmentSimulation.TRAINING_ROOST_ID else current_training_level
	)
	var current_it_coop_level := facility_level(DepartmentSimulation.IT_COOP_ID)
	var preview_it_coop_level := (
		next_level if facility_id == DepartmentSimulation.IT_COOP_ID else current_it_coop_level
	)
	var current_flock_relations_level := facility_level(DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID)
	var preview_flock_relations_level := (
		next_level
		if facility_id == DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID and not maxed else
		current_flock_relations_level
	)
	var current_flock_relations_case_capacity := _facility_level_schedule_value(
		DepartmentSimulation.FLOCK_RELATIONS_CASE_CAPACITY,
		current_flock_relations_level,
		0,
	)
	var next_flock_relations_case_capacity := _facility_level_schedule_value(
		DepartmentSimulation.FLOCK_RELATIONS_CASE_CAPACITY,
		preview_flock_relations_level,
		0,
	)
	var current_flock_relations_resolution_limit := _facility_level_schedule_value(
		DepartmentSimulation.FLOCK_RELATIONS_RESOLUTION_LIMITS,
		current_flock_relations_level,
		0,
	)
	var next_flock_relations_resolution_limit := _facility_level_schedule_value(
		DepartmentSimulation.FLOCK_RELATIONS_RESOLUTION_LIMITS,
		preview_flock_relations_level,
		0,
	)
	var current_feed_procurement_level := facility_level(DepartmentSimulation.FEED_PROCUREMENT_COOP_ID)
	var preview_feed_procurement_level := (
		next_level
		if facility_id == DepartmentSimulation.FEED_PROCUREMENT_COOP_ID and not maxed else
		current_feed_procurement_level
	)
	var current_feed_capacity_scoops := _facility_level_schedule_value(
		DepartmentSimulation.FEED_PROCUREMENT_CAPACITY_SCOOPS,
		current_feed_procurement_level,
		0,
	)
	var next_feed_capacity_scoops := _facility_level_schedule_value(
		DepartmentSimulation.FEED_PROCUREMENT_CAPACITY_SCOOPS,
		preview_feed_procurement_level,
		0,
	)
	var current_farmgate_level := facility_level(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID)
	var preview_farmgate_level := (
		next_level
		if facility_id == DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID and not maxed else
		current_farmgate_level
	)
	var current_farmgate_storage := _facility_level_schedule_value(
		DepartmentSimulation.FARMGATE_DISPATCH_STORAGE_CAPACITY_EGGS,
		current_farmgate_level,
		0,
	)
	var next_farmgate_storage := _facility_level_schedule_value(
		DepartmentSimulation.FARMGATE_DISPATCH_STORAGE_CAPACITY_EGGS,
		preview_farmgate_level,
		0,
	)
	var current_farmgate_dispatch := _facility_level_schedule_value(
		DepartmentSimulation.FARMGATE_DISPATCH_DAILY_DISPATCH_EGGS,
		current_farmgate_level,
		0,
	)
	var next_farmgate_dispatch := _facility_level_schedule_value(
		DepartmentSimulation.FARMGATE_DISPATCH_DAILY_DISPATCH_EGGS,
		preview_farmgate_level,
		0,
	)
	return {
		"known": true,
		"id": facility_id,
		"name": String(definition["name"]),
		"short_name": String(definition["short_name"]),
		"description": String(definition["description"]),
		"cost_cents": cost_cents,
		"capital_cost_cents": cost_cents,
		"next_level_cost_cents": cost_cents,
		"daily_maintenance_cents": next_maintenance_cents,
		"current_maintenance_cents": current_maintenance_cents,
		"next_maintenance_cents": next_maintenance_cents,
		"maintenance_delta_cents": maintenance_delta_cents,
		"current_supervisor_payroll_cents": current_supervisor_payroll_cents,
		"next_supervisor_payroll_cents": next_supervisor_payroll_cents,
		"supervisor_payroll_delta_cents": supervisor_payroll_delta_cents,
		"added_daily_operating_cents": added_daily_operating_cents,
		"required_spendable_cents": required_spendable_cents,
		"spendable_fund_cents": spendable,
		"benefits": (definition.get("benefits", []) as Array).duplicate(),
		"tradeoffs": (definition.get("tradeoffs", []) as Array).duplicate(),
		"owned": installed,
		"installed": installed,
		"maxed": maxed,
		"level": level,
		"level_name": level_name,
		"next_level": next_level,
		"next_level_name": next_level_name,
		"max_level": max_level,
		"unlock_id": unlock_id,
		"unlock_day": unlock_day,
		"next_unlock_day": unlock_day,
		"unlocked": unlocked,
		"planning_open": planning_open,
		"affordable": affordable,
		"can_purchase": not maxed and unlocked and planning_open and affordable,
		"reason": reason,
		"action_reason": reason,
		"purchase_label": purchase_label,
		"projected_spendable_fund_cents": projected_spendable,
		"protected_reserve_before_cents": sim.protected_reserve_cents(),
		"projected_protected_reserve_cents": (
			sim.protected_reserve_cents() + added_daily_operating_cents
			if not maxed else sim.protected_reserve_cents()
		),
		"protected_reserve_after_cents": (
			sim.protected_reserve_cents() + added_daily_operating_cents
			if not maxed else sim.protected_reserve_cents()
		),
		"current_claim_capacity": current_capacity,
		"next_claim_capacity": next_claim_capacity,
		"claim_capacity_delta": next_claim_capacity - current_capacity,
		"market_standing": market_standing,
		"market_standing_rank": sim.farm_mutual_standing_rank(),
		"market_standing_rank_label": sim.farm_mutual_standing_rank_label(),
		"required_market_standing": required_market_standing,
		"market_standing_shortfall": maxi(0, required_market_standing - market_standing),
		"required_claim_capacity": required_claim_capacity,
		"claim_capacity_shortfall": maxi(0, required_claim_capacity - sim.current_claim_capacity()),
		"required_active_staff": required_active_staff,
		"active_staff_count": sim.active_worker_count(),
		"active_staff_shortfall": maxi(0, required_active_staff - sim.active_worker_count()),
		"required_office_capacity": required_office_capacity,
		"office_capacity": sim.office_capacity,
		"office_capacity_shortfall": maxi(0, required_office_capacity - sim.office_capacity),
		"required_service_coop_level": required_service_coop_level,
		"service_coop_level": maxi(0, facility_level(DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID)),
		"service_coop_level_shortfall": maxi(
			0,
			required_service_coop_level - maxi(0, facility_level(DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID)),
		),
		"required_packing_annex_level": required_packing_annex_level,
		"packing_annex_level": maxi(0, facility_level(DepartmentSimulation.PACKING_ANNEX_ID)),
		"packing_annex_level_shortfall": maxi(
			0,
			required_packing_annex_level - maxi(0, facility_level(DepartmentSimulation.PACKING_ANNEX_ID)),
		),
		"required_farmer_relations_gallery_level": required_farmer_relations_gallery_level,
		"farmer_relations_gallery_level": maxi(0, facility_level(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID)),
		"farmer_relations_gallery_level_shortfall": maxi(
			0,
			required_farmer_relations_gallery_level
			- maxi(0, facility_level(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID)),
		),
		"required_harvest_credit_standing": required_harvest_credit_standing,
		"harvest_credit_standing": harvest_credit_standing,
		"harvest_credit_standing_shortfall": maxi(
			0,
			required_harvest_credit_standing - harvest_credit_standing,
		),
		"required_records_annex_level": required_records_annex_level,
		"records_annex_level": maxi(0, facility_level(DepartmentSimulation.RECORDS_ANNEX_ID)),
		"records_annex_level_shortfall": maxi(
			0,
			required_records_annex_level - maxi(0, facility_level(DepartmentSimulation.RECORDS_ANNEX_ID)),
		),
		"required_rooster_operations_office_level": required_rooster_operations_level,
		"rooster_operations_office_level": maxi(
			0,
			current_rooster_operations_level,
		),
		"rooster_operations_office_level_shortfall": maxi(
			0,
			required_rooster_operations_level - maxi(0, current_rooster_operations_level),
		),
		"premium_bonus_basis_points": (
			level * DepartmentSimulation.SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
			if facility_id == DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID else 0
		),
		"next_premium_bonus_basis_points": (
			next_level * DepartmentSimulation.SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
			if facility_id == DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID else 0
		),
		"required_wellness_nest_level": required_wellness_nest_level,
		"wellness_nest_level": current_wellness_level,
		"wellness_nest_level_shortfall": maxi(
			0,
			required_wellness_nest_level - current_wellness_level,
		),
		"required_career_level": required_career_level,
		"qualified_staff_count": qualified_staff_count,
		"qualification_shortfall": (
			1 if required_career_level > 0 and qualified_staff_count <= 0 else 0
		),
		"current_strain_gain_basis_points": _facility_level_schedule_value(
			DepartmentSimulation.WELLNESS_STRAIN_GAIN_BASIS_POINTS,
			current_wellness_level,
			10_000,
		),
		"next_strain_gain_basis_points": _facility_level_schedule_value(
			DepartmentSimulation.WELLNESS_STRAIN_GAIN_BASIS_POINTS,
			preview_wellness_level,
			10_000,
		),
		"current_break_recovery_basis_points": _facility_level_schedule_value(
			DepartmentSimulation.WELLNESS_BREAK_RECOVERY_BASIS_POINTS,
			current_wellness_level,
			10_000,
		),
		"next_break_recovery_basis_points": _facility_level_schedule_value(
			DepartmentSimulation.WELLNESS_BREAK_RECOVERY_BASIS_POINTS,
			preview_wellness_level,
			10_000,
		),
		"current_career_sponsorship_cost_cents": _facility_level_schedule_value(
			DepartmentSimulation.TRAINING_SPONSORSHIP_COSTS_CENTS,
			current_training_level,
			DepartmentSimulation.CAREER_SPONSORSHIP_COST_CENTS,
		),
		"next_career_sponsorship_cost_cents": _facility_level_schedule_value(
			DepartmentSimulation.TRAINING_SPONSORSHIP_COSTS_CENTS,
			preview_training_level,
			DepartmentSimulation.CAREER_SPONSORSHIP_COST_CENTS,
		),
		"current_training_work_basis_points": _facility_level_schedule_value(
			DepartmentSimulation.TRAINING_WORK_BASIS_POINTS,
			current_training_level,
			8500,
		),
		"next_training_work_basis_points": _facility_level_schedule_value(
			DepartmentSimulation.TRAINING_WORK_BASIS_POINTS,
			preview_training_level,
			8500,
		),
		"current_career_coaching_xp_bonus": _facility_level_schedule_value(
			DepartmentSimulation.TRAINING_COACHING_XP_BONUS,
			current_training_level,
			0,
		),
		"next_career_coaching_xp_bonus": _facility_level_schedule_value(
			DepartmentSimulation.TRAINING_COACHING_XP_BONUS,
			preview_training_level,
			0,
		),
		"current_personnel_action_limit": _facility_level_schedule_value(
			DepartmentSimulation.ROOSTER_PERSONNEL_ACTION_LIMITS,
			current_rooster_operations_level,
			1,
		),
		"next_personnel_action_limit": _facility_level_schedule_value(
			DepartmentSimulation.ROOSTER_PERSONNEL_ACTION_LIMITS,
			preview_rooster_operations_level,
			1,
		),
		"current_surveillance_grievance_millipoints": _facility_level_schedule_value(
			DepartmentSimulation.ROOSTER_SURVEILLANCE_GRIEVANCE_MILLIPOINTS,
			current_rooster_operations_level,
			0,
		),
		"next_surveillance_grievance_millipoints": _facility_level_schedule_value(
			DepartmentSimulation.ROOSTER_SURVEILLANCE_GRIEVANCE_MILLIPOINTS,
			preview_rooster_operations_level,
			0,
		),
		"current_surveillance_stress_millipoints": _facility_level_schedule_value(
			DepartmentSimulation.ROOSTER_SURVEILLANCE_STRESS_MILLIPOINTS,
			current_rooster_operations_level,
			0,
		),
		"next_surveillance_stress_millipoints": _facility_level_schedule_value(
			DepartmentSimulation.ROOSTER_SURVEILLANCE_STRESS_MILLIPOINTS,
			preview_rooster_operations_level,
			0,
		),
		"current_surveillance_solidarity_millipoints": _facility_level_schedule_value(
			DepartmentSimulation.ROOSTER_SURVEILLANCE_SOLIDARITY_MILLIPOINTS,
			current_rooster_operations_level,
			0,
		),
		"next_surveillance_solidarity_millipoints": _facility_level_schedule_value(
			DepartmentSimulation.ROOSTER_SURVEILLANCE_SOLIDARITY_MILLIPOINTS,
			preview_rooster_operations_level,
			0,
		),
		"current_automation_work_basis_points": _facility_level_schedule_value(
			DepartmentSimulation.IT_AUTO_WORK_BASIS_POINTS,
			current_it_coop_level,
			10_000,
		),
		"next_automation_work_basis_points": _facility_level_schedule_value(
			DepartmentSimulation.IT_AUTO_WORK_BASIS_POINTS,
			preview_it_coop_level,
			10_000,
		),
		"current_automation_specialty_grace_minutes": _facility_level_schedule_value(
			DepartmentSimulation.IT_AUTO_SPECIALTY_GRACE_MINUTES,
			current_it_coop_level,
			DepartmentSimulation.AUTO_SPECIALTY_GRACE_MINUTES,
		),
		"next_automation_specialty_grace_minutes": _facility_level_schedule_value(
			DepartmentSimulation.IT_AUTO_SPECIALTY_GRACE_MINUTES,
			preview_it_coop_level,
			DepartmentSimulation.AUTO_SPECIALTY_GRACE_MINUTES,
		),
		"current_automation_compliance_exposure_millipoints": _facility_level_schedule_value(
			DepartmentSimulation.IT_COMPLIANCE_EXPOSURE_MILLIPOINTS,
			current_it_coop_level,
			0,
		),
		"next_automation_compliance_exposure_millipoints": _facility_level_schedule_value(
			DepartmentSimulation.IT_COMPLIANCE_EXPOSURE_MILLIPOINTS,
			preview_it_coop_level,
			0,
		),
		"current_ledger_molt_patch_cost_cents": _facility_level_schedule_value(
			DepartmentSimulation.IT_LEDGER_PATCH_COSTS_CENTS,
			current_it_coop_level,
			1800,
		),
		"next_ledger_molt_patch_cost_cents": _facility_level_schedule_value(
			DepartmentSimulation.IT_LEDGER_PATCH_COSTS_CENTS,
			preview_it_coop_level,
			1800,
		),
		"current_flock_relations_case_capacity": current_flock_relations_case_capacity,
		"next_flock_relations_case_capacity": next_flock_relations_case_capacity,
		"flock_relations_case_capacity_delta": (
			next_flock_relations_case_capacity - current_flock_relations_case_capacity
		),
		"current_flock_relations_resolution_limit": current_flock_relations_resolution_limit,
		"next_flock_relations_resolution_limit": next_flock_relations_resolution_limit,
		"flock_relations_resolution_limit_delta": (
			next_flock_relations_resolution_limit - current_flock_relations_resolution_limit
		),
		"current_feed_capacity_scoops": current_feed_capacity_scoops,
		"next_feed_capacity_scoops": next_feed_capacity_scoops,
		"feed_capacity_delta_scoops": next_feed_capacity_scoops - current_feed_capacity_scoops,
		"current_farmgate_storage_capacity_eggs": current_farmgate_storage,
		"next_farmgate_storage_capacity_eggs": next_farmgate_storage,
		"farmgate_storage_capacity_delta_eggs": next_farmgate_storage - current_farmgate_storage,
		"current_farmgate_dispatch_capacity_eggs": current_farmgate_dispatch,
		"next_farmgate_dispatch_capacity_eggs": next_farmgate_dispatch,
		"farmgate_dispatch_capacity_delta_eggs": next_farmgate_dispatch - current_farmgate_dispatch,
	}


func _facility_cost_for_level(definition: Dictionary, target_level: int) -> int:
	if target_level <= 0:
		return 0
	var scheduled_costs: Variant = definition.get("level_costs_cents", null)
	if scheduled_costs is Array:
		var costs := scheduled_costs as Array
		var index := target_level - 1
		if index >= 0 and index < costs.size():
			return maxi(0, int(costs[index]))
	return maxi(0, int(definition.get("cost_cents", 0)))


func _facility_maintenance_for_level(definition: Dictionary, target_level: int) -> int:
	if target_level <= 0:
		return 0
	var schedule_value: Variant = definition.get("maintenance_by_level_cents", null)
	if schedule_value is Array:
		var schedule := schedule_value as Array
		if target_level >= 0 and target_level < schedule.size():
			return maxi(0, int(schedule[target_level]))
	return maxi(0, target_level) * maxi(
		0,
		int(definition.get("daily_maintenance_cents", 0)),
	)


func _facility_level_name(definition: Dictionary, target_level: int) -> String:
	if target_level <= 0:
		return "LEASE OPTION"
	var names_value: Variant = definition.get("level_names", null)
	if names_value is Array:
		var names := names_value as Array
		var index := target_level - 1
		if index >= 0 and index < names.size():
			return String(names[index])
	return "LEVEL %d" % target_level


func _campus_services_for_state(state: Dictionary) -> Dictionary:
	var value: Variant = state.get("services", {})
	return value as Dictionary if value is Dictionary else {}


func _campus_service_owned_for_state(state: Dictionary, service_id: StringName) -> bool:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var services := _campus_services_for_state(state)
	return bool(services.get(String(service_id), services.get(service_id, false)))


func _campus_socket_is_valid(socket_id: StringName) -> bool:
	return (
		DepartmentSimulation.CAMPUS_SOCKET_DEFINITIONS.has(socket_id)
		and not bool((DepartmentSimulation.CAMPUS_SOCKET_DEFINITIONS[socket_id] as Dictionary).get("route_blocked", false))
	)


func _campus_pod_operational_for_state(state: Dictionary) -> bool:
	var socket_id := StringName(String(state.get("pod_socket_id", "")))
	return (
		bool(state.get("parcel_owned", false))
		and bool(state.get("pod_owned", false))
		and _campus_socket_is_valid(socket_id)
		and _campus_service_owned_for_state(state, &"circulation")
		and _campus_service_owned_for_state(state, &"power")
	)


func _campus_cold_chain_active_for_state(state: Dictionary) -> bool:
	return (
		_campus_pod_operational_for_state(state)
		and _campus_service_owned_for_state(state, &"cold_chain")
	)


func _campus_claim_capacity_bonus_for_state(state: Dictionary) -> int:
	return DepartmentSimulation.CAMPUS_CLAIM_CAPACITY_BONUS if _campus_pod_operational_for_state(state) else 0


func _campus_farmgate_capacity_bonus_for_state(
	state: Dictionary,
	farmgate_level: int,
) -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return (
		DepartmentSimulation.CAMPUS_FARMGATE_STORAGE_BONUS_EGGS
		if farmgate_level > 0 and _campus_cold_chain_active_for_state(state) else
		0
	)


func _campus_daily_cost_for_state(state: Dictionary) -> int:
	var total := 0
	if bool(state.get("parcel_owned", false)):
		total += int((DepartmentSimulation.CAMPUS_PARCEL_DEFINITIONS[DepartmentSimulation.CAMPUS_PARCEL_ID] as Dictionary)["daily_cost_cents"])
	for service_id in DepartmentSimulation.CAMPUS_SERVICE_ORDER:
		if _campus_service_owned_for_state(state, service_id):
			total += int((DepartmentSimulation.CAMPUS_SERVICE_DEFINITIONS[service_id] as Dictionary)["daily_cost_cents"])
	if bool(state.get("pod_owned", false)):
		total += int((DepartmentSimulation.CAMPUS_MODULE_DEFINITIONS[DepartmentSimulation.CAMPUS_MODULE_ID] as Dictionary)["daily_cost_cents"])
	return total


func current_daily_campus_cost_cents() -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return _campus_daily_cost_for_state(sim.campus_expansion_state)


func _campus_access_gate_met() -> bool:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return (
		facility_level(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID) >= 1
		or sim.farm_mutual_standing() >= DepartmentSimulation.CAMPUS_EXPANSION_STANDING_REQUIREMENT
	)


func _campus_access_gate_reason() -> String:
	if _campus_access_gate_met():
		return ""
	return (
		"Commission Farmgate Dispatch Depot level 1 or earn Bronze Farm Mutual standing "
		+ "(%d points) before purchasing North Meadow." % DepartmentSimulation.CAMPUS_EXPANSION_STANDING_REQUIREMENT
	)


func _campus_action_terms(action_id: StringName, item_id: StringName) -> Dictionary:
	match action_id:
		&"purchase_parcel":
			if item_id != DepartmentSimulation.CAMPUS_PARCEL_ID:
				return {}
			var parcel := DepartmentSimulation.CAMPUS_PARCEL_DEFINITIONS[DepartmentSimulation.CAMPUS_PARCEL_ID] as Dictionary
			return {
				"name": String(parcel["name"]),
				"cost_cents": int(parcel["capital_cost_cents"]),
				"added_daily_cost_cents": int(parcel["daily_cost_cents"]),
			}
		&"commission_service":
			if not DepartmentSimulation.CAMPUS_SERVICE_DEFINITIONS.has(item_id):
				return {}
			var service := DepartmentSimulation.CAMPUS_SERVICE_DEFINITIONS[item_id] as Dictionary
			return {
				"name": String(service["name"]),
				"cost_cents": int(service["capital_cost_cents"]),
				"added_daily_cost_cents": int(service["daily_cost_cents"]),
			}
		&"place_module":
			if item_id != DepartmentSimulation.CAMPUS_MODULE_ID:
				return {}
			var module := DepartmentSimulation.CAMPUS_MODULE_DEFINITIONS[DepartmentSimulation.CAMPUS_MODULE_ID] as Dictionary
			return {
				"name": String(module["name"]),
				"cost_cents": int(module["capital_cost_cents"]),
				"added_daily_cost_cents": int(module["daily_cost_cents"]),
			}
		&"relocate_module":
			if item_id != DepartmentSimulation.CAMPUS_MODULE_ID:
				return {}
			var module := DepartmentSimulation.CAMPUS_MODULE_DEFINITIONS[DepartmentSimulation.CAMPUS_MODULE_ID] as Dictionary
			return {
				"name": String(module["name"]),
				"cost_cents": int(module["relocation_cost_cents"]),
				"added_daily_cost_cents": 0,
			}
	return {}


func _campus_state_action_reason(
	state: Dictionary,
	action_id: StringName,
	item_id: StringName,
	socket_id: StringName,
) -> String:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if _campus_action_terms(action_id, item_id).is_empty():
		return "This campus action is not on the authorized North Meadow schedule."
	match action_id:
		&"purchase_parcel":
			if bool(state.get("parcel_owned", false)):
				return "North Meadow is already owned."
		&"commission_service":
			if not bool(state.get("parcel_owned", false)):
				return "Purchase North Meadow before commissioning its services."
			if _campus_service_owned_for_state(state, item_id):
				return "%s is already commissioned." % String(
					(DepartmentSimulation.CAMPUS_SERVICE_DEFINITIONS[item_id] as Dictionary)["name"]
				)
		&"place_module":
			if not bool(state.get("parcel_owned", false)):
				return "Purchase North Meadow before placing the Egg Routing Pod."
			if bool(state.get("pod_owned", false)):
				return "The Egg Routing Pod is already placed; file a relocation instead."
			if not DepartmentSimulation.CAMPUS_SOCKET_DEFINITIONS.has(socket_id):
				return "Select a listed North Meadow placement socket."
			var socket := DepartmentSimulation.CAMPUS_SOCKET_DEFINITIONS[socket_id] as Dictionary
			if bool(socket.get("route_blocked", false)):
				return String(socket.get("blocked_reason", "This socket blocks a protected route."))
		&"relocate_module":
			if not bool(state.get("parcel_owned", false)) or not bool(state.get("pod_owned", false)):
				return "Place the Egg Routing Pod before filing a relocation."
			if not DepartmentSimulation.CAMPUS_SOCKET_DEFINITIONS.has(socket_id):
				return "Select a listed North Meadow placement socket."
			var socket := DepartmentSimulation.CAMPUS_SOCKET_DEFINITIONS[socket_id] as Dictionary
			if bool(socket.get("route_blocked", false)):
				return String(socket.get("blocked_reason", "This socket blocks a protected route."))
			if StringName(String(state.get("pod_socket_id", ""))) == socket_id:
				return "The Egg Routing Pod already occupies this socket."
	return ""


func _apply_campus_action_to_state(
	state: Dictionary,
	action_id: StringName,
	item_id: StringName,
	socket_id: StringName,
) -> void:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	match action_id:
		&"purchase_parcel":
			state["parcel_owned"] = true
		&"commission_service":
			var services := _campus_services_for_state(state).duplicate(true)
			services[String(item_id)] = true
			state["services"] = services
		&"place_module":
			state["pod_owned"] = true
			state["pod_socket_id"] = String(socket_id)
		&"relocate_module":
			state["pod_socket_id"] = String(socket_id)


func _campus_action_outcome(
	action_id: StringName,
	item_id: StringName,
	from_socket_id: StringName,
	socket_id: StringName,
) -> String:
	match action_id:
		&"purchase_parcel":
			return "North Meadow was added to the bureau's taxable definition of open space."
		&"commission_service":
			return "%s commissioned with its recurring obligation attached." % String(
				(DepartmentSimulation.CAMPUS_SERVICE_DEFINITIONS[item_id] as Dictionary)["name"]
			)
		&"place_module":
			return "Egg Routing Pod placed at %s; benefits wait for circulation and power." % String(
				(DepartmentSimulation.CAMPUS_SOCKET_DEFINITIONS[socket_id] as Dictionary)["name"]
			)
		&"relocate_module":
			return "Egg Routing Pod relocated from %s to %s without changing daily upkeep." % [
				String((DepartmentSimulation.CAMPUS_SOCKET_DEFINITIONS[from_socket_id] as Dictionary)["name"]),
				String((DepartmentSimulation.CAMPUS_SOCKET_DEFINITIONS[socket_id] as Dictionary)["name"]),
			]
	return "North Meadow filing completed."


func campus_expansion_action_quote(
	action_id: StringName,
	item_id: StringName,
	socket_id: StringName = &"",
) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var terms := _campus_action_terms(action_id, item_id)
	var state_reason := _campus_state_action_reason(
		sim.campus_expansion_state,
		action_id,
		item_id,
		socket_id,
	)
	var preview_state := sim.campus_expansion_state.duplicate(true)
	if state_reason.is_empty():
		_apply_campus_action_to_state(preview_state, action_id, item_id, socket_id)
	var cost_cents := int(terms.get("cost_cents", 0))
	var added_daily_cost_cents := int(terms.get("added_daily_cost_cents", 0))
	var projected_spendable := sim._projected_spendable_after_obligation_change_cents(
		cost_cents,
		added_daily_cost_cents,
	)
	var reason := state_reason
	if reason.is_empty() and action_id == &"purchase_parcel":
		reason = _campus_access_gate_reason()
	if reason.is_empty() and sim.day < DepartmentSimulation.CAMPUS_EXPANSION_UNLOCK_DAY:
		reason = "North Meadow filings become visible on Day %d." % DepartmentSimulation.CAMPUS_EXPANSION_UNLOCK_DAY
	if reason.is_empty() and not sim.staffing_planning_open():
		reason = "North Meadow filings may only be authorized during clear review planning."
	if reason.is_empty() and (sim.campus_expansion_state.get("history", []) as Array).size() >= DepartmentSimulation.CAMPUS_EXPANSION_HISTORY_LIMIT:
		reason = "The North Meadow receipt archive is full."
	if reason.is_empty() and (sim.revenue_cents < cost_cents or projected_spendable < 0):
		reason = "The Feed Fund cannot cover this filing and its next recurring obligation."
	var current_farmgate_level := facility_level(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID)
	return {
		"accepted": false,
		"known": not terms.is_empty(),
		"action_id": action_id,
		"item_id": item_id,
		"socket_id": socket_id,
		"name": String(terms.get("name", "UNKNOWN CAMPUS FILING")),
		"can_authorize": reason.is_empty(),
		"ready": reason.is_empty(),
		"reason": reason,
		"cost_cents": cost_cents,
		"added_daily_cost_cents": added_daily_cost_cents,
		"current_daily_cost_cents": _campus_daily_cost_for_state(sim.campus_expansion_state),
		"projected_daily_cost_cents": _campus_daily_cost_for_state(preview_state),
		"fund_before_cents": sim.revenue_cents,
		"spendable_before_cents": sim.spendable_fund_cents(),
		"required_spendable_cents": sim._required_spendable_for_obligation_change_cents(
			cost_cents,
			added_daily_cost_cents,
		),
		"projected_spendable_cents": projected_spendable,
		"claim_capacity_before": sim.current_claim_capacity(),
		"claim_capacity_after": (
			sim._claim_capacity_for_facilities(sim.owned_facilities)
			+ _campus_claim_capacity_bonus_for_state(preview_state)
		),
		"farmgate_capacity_before": sim._farmgate_storage_capacity_eggs(),
		"farmgate_capacity_after": _farmgate_storage_capacity_for_level_and_campus(
			current_farmgate_level,
			preview_state,
		),
	}


func _authorize_campus_expansion_action(
	action_id: StringName,
	item_id: StringName,
	socket_id: StringName = &"",
) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var quote := campus_expansion_action_quote(action_id, item_id, socket_id)
	if not bool(quote.get("can_authorize", false)):
		return quote
	var from_socket_id := StringName(String(sim.campus_expansion_state.get("pod_socket_id", "")))
	var cost_cents := int(quote["cost_cents"])
	var fund_before := sim.revenue_cents
	var daily_before := _campus_daily_cost_for_state(sim.campus_expansion_state)
	var claim_bonus_before := _campus_claim_capacity_bonus_for_state(sim.campus_expansion_state)
	var farmgate_bonus_before := (
		DepartmentSimulation.CAMPUS_FARMGATE_STORAGE_BONUS_EGGS
		if _campus_cold_chain_active_for_state(sim.campus_expansion_state) else
		0
	)
	sim.revenue_cents -= cost_cents
	_apply_campus_action_to_state(sim.campus_expansion_state, action_id, item_id, socket_id)
	var outcome := _campus_action_outcome(action_id, item_id, from_socket_id, socket_id)
	var access_gate_id: StringName = &""
	var access_standing_points := 0
	var access_farmgate_level := 0
	if action_id == &"purchase_parcel":
		access_farmgate_level = maxi(0, facility_level(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID))
		access_standing_points = maxi(0, sim.farm_mutual_standing())
		access_gate_id = &"farmgate_dispatch" if access_farmgate_level >= 1 else &"farm_mutual_standing"
	var receipt := {
		"accepted": true,
		"receipt_id": int(sim.campus_expansion_state.get("next_receipt_id", 1)),
		"day": sim.day,
		"action_id": action_id,
		"item_id": item_id,
		"socket_id": socket_id,
		"from_socket_id": from_socket_id,
		"cost_cents": cost_cents,
		"added_daily_cost_cents": int(quote["added_daily_cost_cents"]),
		"fund_before_cents": fund_before,
		"fund_after_cents": sim.revenue_cents,
		"daily_cost_before_cents": daily_before,
		"daily_cost_after_cents": _campus_daily_cost_for_state(sim.campus_expansion_state),
		"claim_capacity_bonus_before": claim_bonus_before,
		"claim_capacity_bonus_after": _campus_claim_capacity_bonus_for_state(sim.campus_expansion_state),
		"farmgate_capacity_bonus_before": farmgate_bonus_before,
		"farmgate_capacity_bonus_after": (
			DepartmentSimulation.CAMPUS_FARMGATE_STORAGE_BONUS_EGGS
			if _campus_cold_chain_active_for_state(sim.campus_expansion_state) else
			0
		),
		"access_gate_id": access_gate_id,
		"access_standing_points": access_standing_points,
		"access_farmgate_level": access_farmgate_level,
		"reason": "",
		"outcome": outcome,
	}
	sim.campus_expansion_state["next_receipt_id"] = int(receipt["receipt_id"]) + 1
	sim.campus_expansion_state["capital_spend_total_cents"] = (
		int(sim.campus_expansion_state.get("capital_spend_total_cents", 0)) + cost_cents
	)
	var history := (sim.campus_expansion_state.get("history", []) as Array).duplicate(true)
	history.append(receipt.duplicate(true))
	sim.campus_expansion_state["history"] = history
	sim.campus_expansion_state["last_receipt"] = receipt.duplicate(true)
	sim.announcement_posted.emit(outcome)
	sim.snapshot_changed.emit(sim.snapshot())
	var result := receipt.duplicate(true)
	result["campus_expansion"] = campus_expansion_snapshot()
	return result


func purchase_campus_parcel(parcel_id: StringName = DepartmentSimulation.CAMPUS_PARCEL_ID) -> Dictionary:
	return _authorize_campus_expansion_action(&"purchase_parcel", parcel_id)


func commission_campus_service(service_id: StringName) -> Dictionary:
	return _authorize_campus_expansion_action(&"commission_service", service_id)


func place_campus_module(module_id: StringName, socket_id: StringName) -> Dictionary:
	return _authorize_campus_expansion_action(&"place_module", module_id, socket_id)


func relocate_campus_module(module_id: StringName, socket_id: StringName) -> Dictionary:
	return _authorize_campus_expansion_action(&"relocate_module", module_id, socket_id)


func campus_expansion_snapshot() -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var sockets: Array[Dictionary] = []
	var placed_socket := StringName(String(sim.campus_expansion_state.get("pod_socket_id", "")))
	var any_socket_can_place := false
	var any_socket_can_relocate := false
	var placement_reason := "No cleared North Meadow socket is currently available."
	var relocation_reason := "Place the Egg Routing Pod before filing a relocation."
	for socket_id in DepartmentSimulation.CAMPUS_SOCKET_ORDER:
		var definition := DepartmentSimulation.CAMPUS_SOCKET_DEFINITIONS[socket_id] as Dictionary
		var placement_quote := campus_expansion_action_quote(
			&"place_module",
			DepartmentSimulation.CAMPUS_MODULE_ID,
			socket_id,
		)
		var relocation_quote := campus_expansion_action_quote(
			&"relocate_module",
			DepartmentSimulation.CAMPUS_MODULE_ID,
			socket_id,
		)
		var can_place := bool(placement_quote.get("can_authorize", false))
		var can_relocate := bool(relocation_quote.get("can_authorize", false))
		if can_place:
			any_socket_can_place = true
			placement_reason = ""
		elif not any_socket_can_place and not bool(definition["route_blocked"]):
			placement_reason = String(placement_quote.get("reason", placement_reason))
		if can_relocate:
			any_socket_can_relocate = true
			relocation_reason = ""
		elif not any_socket_can_relocate and not bool(definition["route_blocked"]):
			relocation_reason = String(relocation_quote.get("reason", relocation_reason))
		sockets.append({
			"id": socket_id,
			"name": String(definition["name"]),
			"route_blocked": bool(definition["route_blocked"]),
			"blocked_reason": String(definition["blocked_reason"]),
			"placement_valid": not bool(definition["route_blocked"]),
			"occupied": placed_socket == socket_id,
			"module_id": DepartmentSimulation.CAMPUS_MODULE_ID if placed_socket == socket_id else &"",
			"can_place": can_place,
			"can_relocate": can_relocate,
			"placement_cost_cents": int(placement_quote.get("cost_cents", 0)),
			"placement_recurring_cost_cents": int(
				placement_quote.get("added_daily_cost_cents", 0)
			),
			"relocation_cost_cents": int(relocation_quote.get("cost_cents", 0)),
			"placement_reason": String(placement_quote.get("reason", "")),
			"relocation_reason": String(relocation_quote.get("reason", "")),
			"reason": (
				String(definition["blocked_reason"])
				if bool(definition["route_blocked"]) else
				String(placement_quote.get("reason", ""))
			),
			"placement_quote": placement_quote,
			"relocation_quote": relocation_quote,
		})
	var services: Array[Dictionary] = []
	for service_id in DepartmentSimulation.CAMPUS_SERVICE_ORDER:
		var definition := DepartmentSimulation.CAMPUS_SERVICE_DEFINITIONS[service_id] as Dictionary
		var service_quote := campus_expansion_action_quote(&"commission_service", service_id)
		var connected := _campus_service_owned_for_state(sim.campus_expansion_state, service_id)
		services.append({
			"id": service_id,
			"name": String(definition["name"]),
			"commissioned": connected,
			"connected": connected,
			"can_connect": bool(service_quote.get("can_authorize", false)),
			"reason": String(service_quote.get("reason", "")),
			"required_for_pod": bool(definition["required_for_pod"]),
			"capital_cost_cents": int(definition["capital_cost_cents"]),
			"daily_cost_cents": int(definition["daily_cost_cents"]),
			"quote": service_quote,
		})
	var parcel_definition := DepartmentSimulation.CAMPUS_PARCEL_DEFINITIONS[DepartmentSimulation.CAMPUS_PARCEL_ID] as Dictionary
	var parcel_quote := campus_expansion_action_quote(&"purchase_parcel", DepartmentSimulation.CAMPUS_PARCEL_ID)
	var parcel_owned := bool(sim.campus_expansion_state.get("parcel_owned", false))
	var pod_owned := bool(sim.campus_expansion_state.get("pod_owned", false))
	var pod_definition := DepartmentSimulation.CAMPUS_MODULE_DEFINITIONS[DepartmentSimulation.CAMPUS_MODULE_ID] as Dictionary
	var circulation_connected := _campus_service_owned_for_state(
		sim.campus_expansion_state,
		&"circulation",
	)
	var power_connected := _campus_service_owned_for_state(sim.campus_expansion_state, &"power")
	var cold_chain_connected := _campus_service_owned_for_state(
		sim.campus_expansion_state,
		&"cold_chain",
	)
	var pod_operational := _campus_pod_operational_for_state(sim.campus_expansion_state)
	var cold_chain_active := _campus_cold_chain_active_for_state(sim.campus_expansion_state)
	var claim_bonus := _campus_claim_capacity_bonus_for_state(sim.campus_expansion_state)
	var farmgate_bonus := _campus_farmgate_capacity_bonus_for_state(
		sim.campus_expansion_state,
		facility_level(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID),
	)
	var construction_stage: StringName = &"access"
	if parcel_owned:
		construction_stage = &"site_work"
	if parcel_owned and circulation_connected and power_connected:
		construction_stage = &"services_ready"
	if pod_owned:
		construction_stage = &"pod_placed"
	if pod_operational:
		construction_stage = &"operational"
	if cold_chain_active:
		construction_stage = &"cold_chain_operational"
	var construction_stages: Array[Dictionary] = [
		{
			"id": &"parcel_deed",
			"label": "PARCEL DEED",
			"status": (
				&"complete" if parcel_owned else
				&"active" if bool(parcel_quote.get("can_authorize", false)) else
				&"pending"
			),
			"complete": parcel_owned,
			"detail": (
				"North Meadow deed filed."
				if parcel_owned else
				String(parcel_quote.get("reason", "North Meadow deed held."))
			),
			"cost_cents": int(parcel_definition["capital_cost_cents"]),
		},
		{
			"id": &"circulation_link",
			"label": "FLOCK CIRCULATION",
			"status": &"complete" if circulation_connected else &"active" if parcel_owned else &"pending",
			"complete": circulation_connected,
			"detail": "Circulation connected." if circulation_connected else "Commission after the parcel deed.",
			"cost_cents": int((DepartmentSimulation.CAMPUS_SERVICE_DEFINITIONS[&"circulation"] as Dictionary)["capital_cost_cents"]),
		},
		{
			"id": &"power_drop",
			"label": "COOP POWER",
			"status": &"complete" if power_connected else &"active" if parcel_owned else &"pending",
			"complete": power_connected,
			"detail": "Power connected." if power_connected else "Commission after the parcel deed.",
			"cost_cents": int((DepartmentSimulation.CAMPUS_SERVICE_DEFINITIONS[&"power"] as Dictionary)["capital_cost_cents"]),
		},
		{
			"id": &"pod_pad",
			"label": "EGG ROUTING POD",
			"status": &"complete" if pod_owned else &"active" if parcel_owned else &"pending",
			"complete": pod_owned,
			"detail": (
				"Installed at %s." % String(placed_socket).replace("_", " ").to_upper()
				if pod_owned else
				placement_reason
			),
			"cost_cents": int(pod_definition["capital_cost_cents"]),
		},
		{
			"id": &"commissioning",
			"label": "POD COMMISSIONING",
			"status": &"complete" if pod_operational else &"active" if pod_owned else &"pending",
			"complete": pod_operational,
			"detail": (
				"Routing pod operational."
				if pod_operational else
				"Requires parcel, placement, circulation, and power."
			),
		},
		{
			"id": &"cold_chain",
			"label": "COLD-CHAIN LOOP",
			"status": &"complete" if cold_chain_active else &"active" if parcel_owned else &"pending",
			"complete": cold_chain_active,
			"detail": (
				"Farmgate storage extension active."
				if cold_chain_active else
				"Optional service; its storage benefit waits for pod commissioning."
			),
			"cost_cents": int((DepartmentSimulation.CAMPUS_SERVICE_DEFINITIONS[&"cold_chain"] as Dictionary)["capital_cost_cents"]),
		},
	]
	var operational_benefits: Array[String] = [
		"LIVE FILE CAPACITY  +%d FILES%s" % [claim_bonus, " / ACTIVE" if claim_bonus > 0 else " / HELD"],
		"FARMGATE FINISHED-EGG STORAGE  +%d EGGS%s" % [farmgate_bonus, " / ACTIVE" if farmgate_bonus > 0 else " / HELD"],
	]
	var routing_pod := {
		"id": DepartmentSimulation.CAMPUS_MODULE_ID,
		"name": String(pod_definition["name"]),
		"placed": pod_owned,
		"owned": pod_owned,
		"current_socket_id": placed_socket,
		"capital_cost_cents": int(pod_definition["capital_cost_cents"]),
		"relocation_cost_cents": int(pod_definition["relocation_cost_cents"]),
		"daily_cost_cents": int(pod_definition["daily_cost_cents"]),
		"can_place": any_socket_can_place,
		"can_relocate": any_socket_can_relocate,
		"placement_reason": placement_reason,
		"relocation_reason": relocation_reason,
		"operational": pod_operational,
	}
	return {
		"id": &"campus_expansion",
		"visible": sim.day >= DepartmentSimulation.CAMPUS_EXPANSION_UNLOCK_DAY,
		"unlock_day": DepartmentSimulation.CAMPUS_EXPANSION_UNLOCK_DAY,
		"access_gate_met": _campus_access_gate_met(),
		"access_gate_reason": _campus_access_gate_reason(),
		"access_standing_requirement": DepartmentSimulation.CAMPUS_EXPANSION_STANDING_REQUIREMENT,
		"parcel_id": DepartmentSimulation.CAMPUS_PARCEL_ID,
		"parcel_owned": parcel_owned,
		"parcel_quote": parcel_quote,
		"parcel": {
			"id": DepartmentSimulation.CAMPUS_PARCEL_ID,
			"name": String(parcel_definition["name"]),
			"owned": parcel_owned,
			"can_purchase": bool(parcel_quote.get("can_authorize", false)),
			"capital_cost_cents": int(parcel_definition["capital_cost_cents"]),
			"daily_cost_cents": int(parcel_definition["daily_cost_cents"]),
			"reason": String(parcel_quote.get("reason", "")),
			"quote": parcel_quote,
		},
		"services": services,
		"sockets": sockets,
		"module_id": DepartmentSimulation.CAMPUS_MODULE_ID,
		"pod_owned": pod_owned,
		"pod_socket_id": placed_socket,
		"pod_operational": pod_operational,
		"routing_pod": routing_pod,
		"cold_chain_connected": cold_chain_connected,
		"cold_chain_active": cold_chain_active,
		"claim_capacity_bonus": claim_bonus,
		"farmgate_capacity_bonus_eggs": farmgate_bonus,
		"construction_stage": construction_stage,
		"construction_stages": construction_stages,
		"operational_benefits": operational_benefits,
		"summary": "NORTH MEADOW / %s / POD %s" % [
			String(construction_stage).replace("_", " ").to_upper(),
			"OPERATIONAL" if pod_operational else "HELD",
		],
		"current_daily_cost_cents": current_daily_campus_cost_cents(),
		"capital_spend_total_cents": int(sim.campus_expansion_state.get("capital_spend_total_cents", 0)),
		"next_receipt_id": int(sim.campus_expansion_state.get("next_receipt_id", 1)),
		"last_receipt": (sim.campus_expansion_state.get("last_receipt", {}) as Dictionary).duplicate(true),
		"history": (sim.campus_expansion_state.get("history", []) as Array).duplicate(true),
	}


func _campus_portfolio_context(
	planning_override: Variant = null,
	worker_id_override: Array = [],
	worker_name_override: Dictionary = {},
	campus_state_override: Dictionary = {},
	target_day: int = -1,
) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var source_campus := sim.campus_expansion_state if campus_state_override.is_empty() else campus_state_override
	var grid_active := (
		bool(source_campus.get("parcel_owned", false))
		and _campus_service_owned_for_state(source_campus, &"circulation")
		and _campus_service_owned_for_state(source_campus, &"power")
	)
	var cold_active := grid_active and _campus_service_owned_for_state(source_campus, &"cold_chain")
	var valid_worker_ids: Array[int] = []
	var worker_names: Dictionary = {}
	if worker_id_override.is_empty():
		for worker in sim.workers:
			if not worker.employed:
				continue
			valid_worker_ids.append(worker.id)
			worker_names[worker.id] = worker.display_name
	else:
		for raw_worker_id: Variant in worker_id_override:
			if _is_integral_number(raw_worker_id):
				valid_worker_ids.append(int(raw_worker_id))
		worker_names = worker_name_override.duplicate(true)
	return {
		"day": sim.day if target_day < 0 else target_day,
		"planning_open": (
			sim.staffing_planning_open()
			if planning_override == null else
			bool(planning_override)
		),
		# North Meadow's commissioned utility trunk is deliberately large enough
		# for the four authored portfolio modules, but every project reserves its
		# exact share at authorization so the player cannot overbook it.
		"power_capacity_units": 5 if grid_active else 0,
		"cold_capacity_units": 2 if cold_active else 0,
		"valid_worker_ids": valid_worker_ids,
		"worker_names": worker_names,
		"can_fund": true,
	}


func campus_portfolio_deed_quote(parcel_id: StringName) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var context := _campus_portfolio_context()
	var quote: Dictionary = sim._campus_portfolio.quote_deed(parcel_id, context)
	return _enriched_campus_portfolio_quote(
		quote,
		_campus_portfolio_finance_basis(),
		&"deed",
	)


func purchase_campus_portfolio_deed(parcel_id: StringName) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var quote := campus_portfolio_deed_quote(parcel_id)
	if not bool(quote.get("can_authorize", false)):
		return quote
	var fund_before := sim.revenue_cents
	var result: Dictionary = sim._campus_portfolio.authorize_deed(
		parcel_id,
		sim.day,
		_campus_portfolio_context(),
	)
	if not bool(result.get("accepted", false)):
		return result
	var cost := int(quote.get("cost_cents", 0))
	sim.revenue_cents -= cost
	result["fund_before_cents"] = fund_before
	result["fund_after_cents"] = sim.revenue_cents
	result["projected_spendable_fund_cents"] = int(quote.get("projected_spendable_fund_cents", 0))
	result["campus_portfolio"] = campus_portfolio_snapshot()
	sim.snapshot_changed.emit(sim.snapshot())
	return result


func campus_portfolio_project_quote(module_id: StringName, pad_id: StringName) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var context := _campus_portfolio_context()
	var quote: Dictionary = sim._campus_portfolio.quote_project(module_id, pad_id, context)
	return _enriched_campus_portfolio_quote(
		quote,
		_campus_portfolio_finance_basis(),
		&"module",
	)


func _campus_portfolio_finance_basis() -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var protected := sim.protected_reserve_cents()
	return {
		"revenue_cents": sim.revenue_cents,
		"protected_reserve_cents": protected,
		"spendable_fund_cents": maxi(0, sim.revenue_cents - protected),
	}


func _enriched_campus_portfolio_quote(
	raw_quote: Dictionary,
	finance_basis: Dictionary,
	kind: StringName,
) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var quote := raw_quote.duplicate(true)
	var cost := maxi(0, int(quote.get("cost_cents", 0)))
	var added_daily := maxi(0, int(quote.get("added_daily_cost_cents", 0)))
	var protected := maxi(0, int(finance_basis.get("protected_reserve_cents", 0)))
	var fund := maxi(0, int(finance_basis.get("revenue_cents", sim.revenue_cents)))
	var projected_spendable := fund - protected - cost - added_daily
	if bool(quote.get("can_authorize", false)) and projected_spendable < 0:
		quote["can_authorize"] = false
		quote["ready"] = false
		quote["reason"] = (
			"The Feed Fund is $%.2f short after protecting this deed's first land obligation."
			% (float(-projected_spendable) / 100.0)
			if kind == &"deed" else
			"The Feed Fund is $%.2f short after protecting this module's completed upkeep."
			% (float(-projected_spendable) / 100.0)
		)
	quote["required_spendable_cents"] = cost + added_daily
	quote["projected_spendable_fund_cents"] = projected_spendable
	quote["current_spendable_fund_cents"] = int(finance_basis.get(
		"spendable_fund_cents",
		maxi(0, fund - protected),
	))
	quote["current_protected_reserve_cents"] = protected
	quote["projected_protected_reserve_cents"] = protected + added_daily
	return quote


func authorize_campus_portfolio_project(
	module_id: StringName,
	pad_id: StringName,
) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var quote := campus_portfolio_project_quote(module_id, pad_id)
	if not bool(quote.get("can_authorize", false)):
		return quote
	var fund_before := sim.revenue_cents
	var result: Dictionary = sim._campus_portfolio.authorize_project(
		module_id,
		pad_id,
		sim.day,
		_campus_portfolio_context(),
	)
	if not bool(result.get("accepted", false)):
		return result
	var cost := int(quote.get("cost_cents", 0))
	sim.revenue_cents -= cost
	result["fund_before_cents"] = fund_before
	result["fund_after_cents"] = sim.revenue_cents
	result["projected_spendable_fund_cents"] = int(quote.get("projected_spendable_fund_cents", 0))
	result["campus_portfolio"] = campus_portfolio_snapshot()
	sim.snapshot_changed.emit(sim.snapshot())
	return result


func assign_campus_portfolio_worker(module_id: StringName, worker_id: int) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if not sim.staffing_planning_open():
		return {
			"accepted": false,
			"action_id": &"assign_worker",
			"module_id": module_id,
			"worker_id": worker_id,
			"reason": "Campus duty assignments may only be filed during clear review planning.",
		}
	var state_value: Variant = sim._campus_portfolio.modules.get(String(module_id), {})
	var module_state := state_value as Dictionary if state_value is Dictionary else {}
	var previous_worker := int(module_state.get("worker_id", -1))
	var added_daily := DepartmentSimulation.CampusPortfolioStateScript.CAMPUS_DUTY_PREMIUM_CENTS if previous_worker < 0 else 0
	var projected_spendable := sim._projected_spendable_after_obligation_change_cents(0, added_daily)
	if projected_spendable < 0:
		return {
			"accepted": false,
			"action_id": &"assign_worker",
			"module_id": module_id,
			"worker_id": worker_id,
			"reason": "The Feed Fund cannot protect the $1.00 daily campus-duty premium.",
			"projected_spendable_fund_cents": projected_spendable,
		}
	var context := _campus_portfolio_context()
	var result: Dictionary = sim._campus_portfolio.assign_worker(
		module_id,
		worker_id,
		context.get("valid_worker_ids", []) as Array,
		context,
	)
	if bool(result.get("accepted", false)):
		result["projected_spendable_fund_cents"] = projected_spendable
		result["campus_portfolio"] = campus_portfolio_snapshot()
		sim.snapshot_changed.emit(sim.snapshot())
	return result


func unassign_campus_portfolio_worker(module_id: StringName) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if not sim.staffing_planning_open():
		return {
			"accepted": false,
			"action_id": &"unassign_worker",
			"module_id": module_id,
			"reason": "Campus duty assignments may only be changed during clear review planning.",
		}
	var capacity_reason := _campus_portfolio_unassignment_capacity_reason(module_id)
	if not capacity_reason.is_empty():
		return {
			"accepted": false,
			"action_id": &"unassign_worker",
			"module_id": module_id,
			"reason": capacity_reason,
		}
	var context := _campus_portfolio_context()
	var result: Dictionary = sim._campus_portfolio.unassign_worker(
		module_id,
		context.get("valid_worker_ids", []) as Array,
		context,
	)
	if bool(result.get("accepted", false)):
		result["campus_portfolio"] = campus_portfolio_snapshot()
		sim.snapshot_changed.emit(sim.snapshot())
	return result


func _campus_portfolio_assignment_for_worker(worker_id: int) -> StringName:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	for module_id: StringName in DepartmentSimulation.CampusPortfolioStateScript.MODULE_ORDER:
		var state_value: Variant = sim._campus_portfolio.modules.get(String(module_id), {})
		if state_value is Dictionary and int((state_value as Dictionary).get("worker_id", -1)) == worker_id:
			return module_id
	return &""


func _campus_portfolio_unassignment_capacity_reason(module_id: StringName) -> String:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if module_id == DepartmentSimulation.CampusPortfolioStateScript.COLLECTION_RAIL_HUB:
		var capacity_without_rail := (
			_claim_capacity_for_facilities_and_campus(sim.owned_facilities, sim.campus_expansion_state)
		)
		if sim._outstanding_claim_count() + sim._pending_market_contract_claim_count() > capacity_without_rail:
			return "Route or finish files before releasing the Collection Rail hen; the live ledger exceeds capacity without her."
	elif module_id == DepartmentSimulation.CampusPortfolioStateScript.GRAIN_RECOVERY_MILL:
		var base_feed_capacity := _facility_level_schedule_value(
			DepartmentSimulation.FEED_PROCUREMENT_CAPACITY_SCOOPS,
			facility_level(DepartmentSimulation.FEED_PROCUREMENT_COOP_ID),
			0,
		)
		if sim._feed_procurement.stock_scoops() > base_feed_capacity:
			return "Use the Grain Recovery overflow stock before releasing its named hen."
	elif module_id == DepartmentSimulation.CampusPortfolioStateScript.CREEKSIDE_CHILLING_EXCHANGE:
		var base_farmgate_capacity := _farmgate_storage_capacity_for_level_and_campus(
			facility_level(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID),
			sim.campus_expansion_state,
		)
		if sim._farmgate_dispatch.stock_count() > base_farmgate_capacity:
			return "Dispatch Creekside's overflow egg lots before releasing its named hen."
	return ""


func campus_portfolio_snapshot(north_projection: Dictionary = {}) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var context := _campus_portfolio_context()
	var projection: Dictionary = sim._campus_portfolio.snapshot(context)
	var finance_basis := _campus_portfolio_finance_basis()
	var assignments := (projection.get("workers", []) as Array).duplicate(true)
	var parcel_rows := (projection.get("parcels", []) as Array).duplicate(true)
	for index in parcel_rows.size():
		var row := (parcel_rows[index] as Dictionary).duplicate(true)
		var parcel_id := StringName(String(row.get("id", "")))
		var raw_quote_value: Variant = row.get("quote", {})
		var raw_quote := (
			raw_quote_value as Dictionary
			if raw_quote_value is Dictionary else
			sim._campus_portfolio.quote_deed(parcel_id, context)
		)
		var quote := _enriched_campus_portfolio_quote(raw_quote, finance_basis, &"deed")
		row["quote"] = quote
		row["can_purchase"] = bool(quote.get("can_authorize", false))
		row["reason"] = String(quote.get("reason", ""))
		row["benefit_lines"] = [
			"Adds two route-safe construction pads to the visible farm-office campus.",
			"Every completed module adds a real operating benefit and recurring obligation.",
		]
		parcel_rows[index] = row
	var north := north_projection if not north_projection.is_empty() else campus_expansion_snapshot()
	var north_parcel := (north.get("parcel", {}) as Dictionary).duplicate(true)
	north_parcel["id"] = &"north_meadow"
	north_parcel["name"] = "NORTH MEADOW"
	north_parcel["status_label"] = (
		"UTILITY HUB ONLINE" if bool(north.get("pod_operational", false)) else
		"DEED FILED" if bool(north_parcel.get("owned", false)) else
		"READY" if bool(north_parcel.get("can_purchase", false)) else
		"HELD"
	)
	north_parcel["benefit_lines"] = [
		"Supplies the shared circulation, five-unit power trunk, and two-unit cold loop.",
		"Open North Meadow details to file its deed, services, pod, or relocation.",
	]
	parcel_rows.push_front(north_parcel)
	projection["parcels"] = parcel_rows

	var module_rows := (projection.get("modules", []) as Array).duplicate(true)
	for index in module_rows.size():
		var module := (module_rows[index] as Dictionary).duplicate(true)
		var module_id := StringName(String(module.get("id", "")))
		var pad_quotes: Dictionary = {}
		var allowed_pad_ids: Array[StringName] = []
		for quote_value: Variant in module.get("placement_quotes", []) as Array:
			if not quote_value is Dictionary:
				continue
			var pad_quote := (quote_value as Dictionary).duplicate(true)
			var pad_id := StringName(String(pad_quote.get("pad_id", "")))
			pad_quote = _enriched_campus_portfolio_quote(
				pad_quote,
				finance_basis,
				&"module",
			)
			pad_quotes[pad_id] = pad_quote
			allowed_pad_ids.append(pad_id)
		module["pad_quotes"] = pad_quotes
		module["allowed_pad_ids"] = allowed_pad_ids
		module["requires_staff"] = true
		module["staff_required"] = 1
		module["effect_lines"] = (module.get("benefits", []) as Array).duplicate(true)
		module_rows[index] = module
	projection["modules"] = module_rows
	projection["module_catalog"] = module_rows.duplicate(true)

	var project_rows := (projection.get("projects", []) as Array).duplicate(true)
	for index in project_rows.size():
		var project := (project_rows[index] as Dictionary).duplicate(true)
		var duration := maxi(1, int(project.get("duration_shifts", 1)))
		var remaining := clampi(int(project.get("remaining_shifts", duration)), 0, duration)
		var progress := duration - remaining
		project["job_id"] = int(project.get("project_id", index + 1))
		project["progress_shifts"] = progress
		project["stage_id"] = (
			&"queued" if StringName(String(project.get("status", ""))) == &"queued" else
			&"foundation" if progress * 2 < duration else
			&"frame"
		)
		project["stage_label"] = String(project["stage_id"]).replace("_", " ").to_upper()
		project_rows[index] = project
	projection["projects"] = project_rows

	var assigned_by_worker: Dictionary = {}
	for assignment_value: Variant in assignments:
		if assignment_value is Dictionary:
			assigned_by_worker[int((assignment_value as Dictionary).get("worker_id", -1))] = StringName(
				String((assignment_value as Dictionary).get("module_id", ""))
			)
	var worker_rows: Array[Dictionary] = []
	for worker in sim.workers:
		if not worker.employed:
			continue
		var assigned_module := StringName(assigned_by_worker.get(worker.id, &""))
		worker_rows.append({
			"id": worker.id,
			"name": worker.display_name,
			"role": worker.career_title(),
			"available": assigned_module == &"",
			"can_assign": assigned_module == &"",
			"assigned_module_id": assigned_module,
		})
	projection["workers"] = worker_rows
	projection["assignments"] = assignments
	projection["resources"] = {
		"feed_fund_cents": sim.revenue_cents,
		"spendable_fund_cents": sim.spendable_fund_cents(),
		"protected_reserve_cents": sim.protected_reserve_cents(),
	}
	var contractor := projection.get("contractor", {}) as Dictionary
	var network := projection.get("network", {}) as Dictionary
	(projection["resources"] as Dictionary)["contractor_used"] = int(contractor.get("active_slots", 0))
	(projection["resources"] as Dictionary)["contractor_capacity"] = int(contractor.get("capacity_slots", 1))
	(projection["resources"] as Dictionary)["power_used"] = int(network.get("power_reserved_units", 0))
	(projection["resources"] as Dictionary)["power_capacity"] = int(network.get("power_capacity_units", 0))
	(projection["resources"] as Dictionary)["cold_used"] = int(network.get("cold_reserved_units", 0))
	(projection["resources"] as Dictionary)["cold_capacity"] = int(network.get("cold_capacity_units", 0))
	projection["summary"] = "%d/3 DEEDS / %d ACTIVE / %d QUEUED" % [
		(1 if bool(north_parcel.get("owned", false)) else 0)
		+ int(bool((sim._campus_portfolio.parcels as Dictionary).get("orchard_row", false)))
		+ int(bool((sim._campus_portfolio.parcels as Dictionary).get("creekside_yard", false))),
		int(contractor.get("active_slots", 0)),
		int(contractor.get("queue_count", 0)),
	]
	return projection


func _facility_purchase_effect_copy(facility_id: StringName, level: int) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var definition := DepartmentSimulation.FACILITY_DEFINITIONS[facility_id] as Dictionary
	return {
		"benefits": (definition.get("benefits", []) as Array).duplicate(true),
		"tradeoffs": (definition.get("tradeoffs", []) as Array).duplicate(true),
		"storage_capacity_eggs": (
			_facility_level_schedule_value(DepartmentSimulation.FARMGATE_DISPATCH_STORAGE_CAPACITY_EGGS, level, 0)
			if facility_id == DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID else 0
		),
		"dispatch_capacity_eggs": (
			_facility_level_schedule_value(DepartmentSimulation.FARMGATE_DISPATCH_DAILY_DISPATCH_EGGS, level, 0)
			if facility_id == DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID else 0
		),
		"shelf_life_shifts": (
			_facility_level_schedule_value(DepartmentSimulation.FARMGATE_DISPATCH_SHELF_LIFE_SHIFTS, level, 0)
			if facility_id == DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID else 0
		),
	}


func facility_purchase_preflight(facility_id: StringName) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	## A read-only receipt shared by the UI and the authoritative mutation. This
	## keeps duplicate, gate, phase, and fund rejections completely atomic.
	return facility_status(facility_id)


func purchase_facility(facility_id: StringName) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var preflight := facility_purchase_preflight(facility_id)
	if not bool(preflight.get("can_purchase", false)):
		var rejection := preflight.duplicate(true)
		rejection["accepted"] = false
		return rejection

	var cost_cents := int(preflight["cost_cents"])
	var fund_before := sim.revenue_cents
	var spendable_before := sim.spendable_fund_cents()
	var protected_reserve_before := sim.protected_reserve_cents()
	var upkeep_before := current_daily_facility_maintenance_cents()
	var next_shift_quota_before := sim.quota_target
	var next_level := facility_level(facility_id) + 1
	sim.revenue_cents -= cost_cents
	sim.owned_facilities[facility_id] = next_level
	if facility_id == DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID:
		_ensure_manager_posts_for_office_level()
	if facility_id == DepartmentSimulation.WELLNESS_NEST_ID:
		sim.quota_target = clampi(sim.quota_target + 1, 1, 10_000)
	var definition := DepartmentSimulation.FACILITY_DEFINITIONS[facility_id] as Dictionary
	var outcome := _facility_purchase_outcome(facility_id, next_level, definition)
	var result := facility_status(facility_id)
	result.merge({
		"accepted": true,
		"action_id": &"purchase_facility",
		"facility_id": facility_id,
		"day": sim.day,
		"level": next_level,
		"purchased_level": next_level,
		"cost_cents": cost_cents,
		"capital_cost_cents": cost_cents,
		"added_daily_operating_cents": int(preflight.get("added_daily_operating_cents", 0)),
		"maintenance_delta_cents": int(preflight.get("maintenance_delta_cents", 0)),
		"supervisor_payroll_delta_cents": int(
			preflight.get("supervisor_payroll_delta_cents", 0)
		),
		"required_spendable_cents": int(preflight.get("required_spendable_cents", cost_cents)),
		"projected_spendable_fund_cents": int(preflight.get("projected_spendable_fund_cents", 0)),
		"current_flock_relations_case_capacity": int(
			preflight.get("current_flock_relations_case_capacity", 0)
		),
		"next_flock_relations_case_capacity": int(
			preflight.get("next_flock_relations_case_capacity", 0)
		),
		"flock_relations_case_capacity_delta": int(
			preflight.get("flock_relations_case_capacity_delta", 0)
		),
		"current_flock_relations_resolution_limit": int(
			preflight.get("current_flock_relations_resolution_limit", 0)
		),
		"next_flock_relations_resolution_limit": int(
			preflight.get("next_flock_relations_resolution_limit", 0)
		),
		"flock_relations_resolution_limit_delta": int(
			preflight.get("flock_relations_resolution_limit_delta", 0)
		),
		"fund_delta_cents": sim.revenue_cents - fund_before,
		"spendable_fund_cents": sim.spendable_fund_cents(),
		"next_shift_quota_before": next_shift_quota_before,
		"next_shift_quota_after": sim.quota_target,
		"next_shift_quota_delta": sim.quota_target - next_shift_quota_before,
		"outcome": outcome,
	}, true)
	var commissioning_receipt := {
		"accepted": true,
		"action_id": &"purchase_facility",
		"facility_id": facility_id,
		"facility_name": String(definition.get("name", "CAPITAL FACILITY")),
		"level_name": _facility_level_name(definition, next_level),
		"day": sim.day,
		"purchased_level": next_level,
		"max_level": int(definition.get("max_level", 1)),
		"cost_cents": cost_cents,
		"fund_before_cents": fund_before,
		"fund_after_cents": sim.revenue_cents,
		"spendable_before_cents": spendable_before,
		"spendable_after_cents": sim.spendable_fund_cents(),
		"protected_reserve_before_cents": protected_reserve_before,
		"protected_reserve_after_cents": sim.protected_reserve_cents(),
		"upkeep_before_cents": upkeep_before,
		"upkeep_after_cents": current_daily_facility_maintenance_cents(),
		"upkeep_delta_cents": (
			current_daily_facility_maintenance_cents() - upkeep_before
		),
		"effect": _facility_purchase_effect_copy(facility_id, next_level),
	}
	sim.last_facility_purchase_receipt = commissioning_receipt.duplicate(true)
	sim.facility_commissioning_history.append(commissioning_receipt.duplicate(true))
	while sim.facility_commissioning_history.size() > DepartmentSimulation.FARMGATE_COMMISSIONING_HISTORY_LIMIT:
		sim.facility_commissioning_history.pop_front()
	if (
		sim.pinned_capital_plan_id == facility_id
		and next_level >= int(definition.get("max_level", 1))
	):
		sim.pinned_capital_plan_id = &""
	result["commissioning_receipt"] = commissioning_receipt.duplicate(true)
	result["capital_plan"] = sim.capital_plan_snapshot()
	sim.facility_purchased.emit(facility_id, next_level, cost_cents)
	sim.announcement_posted.emit(outcome)
	sim.snapshot_changed.emit(sim.snapshot())
	return result


func _facility_purchase_outcome(
	facility_id: StringName,
	level: int,
	definition: Dictionary
) -> String:
	if facility_id == DepartmentSimulation.PACKING_ANNEX_ID:
		match level:
			1:
				return "Packing Annex level 1 opened: the flock fills cartons and the farmer signs the label."
			2:
				return "Packing Annex level 2 automated sealing; throughput is now described as management innovation."
			3:
				return "Packing Annex level 3 opened premium dispatch and a larger farmer-credit stamp."
	if facility_id == DepartmentSimulation.RECORDS_ANNEX_ID:
		match level:
			1:
				return "Records Annex level 1 opened six more file roosts; missed work may now become overdue work."
			2:
				return "Records Annex level 2 opened pneumatic triage and six additional live-file slots."
			3:
				return "Records Annex level 3 sealed the retention vault at 36 files and $11.00 daily upkeep."
	if facility_id == DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID:
		match level:
			1:
				return "Service Coop level 1 installed the Bronze client seal desk; fulfilled binder premiums now carry a 50% service bonus."
			2:
				return "Service Coop level 2 opened Silver timed dispatch; fulfilled binder premiums now carry a 100% service bonus."
			3:
				return "Service Coop level 3 opened the Gold account gallery; fulfilled binder premiums now carry a 150% service bonus."
	if facility_id == DepartmentSimulation.FARM_MUTUAL_NEGOTIATION_ROOM_ID:
		return "Farm Mutual Negotiation Room commissioned: one signed rider may now reshape each binder's operational risk."
	if facility_id == DepartmentSimulation.WELLNESS_NEST_ID:
		match level:
			1:
				return "Wellness Nest level 1 opened Quiet Nest Cubbies; Finance added one file to the next clutch target."
			2:
				return "Wellness Nest level 2 opened Rotating Recovery; improved rest now supports one more target file."
			3:
				return "Wellness Nest level 3 certified the Rested Flock Suite and raised the target once more."
	if facility_id == DepartmentSimulation.TRAINING_ROOST_ID:
		match level:
			1:
				return "Training Roost level 1 opened a Practice Terminal; sponsorship now costs $10.00."
			2:
				return "Training Roost level 2 opened the Cross-Lane Classroom; sponsorship now costs $8.00."
			3:
				return "Training Roost level 3 opened the Credential Gallery; sponsorship now costs $6.00."
	if facility_id == DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID:
		match level:
			1:
				return "Rooster Office level 1 opened the Shift Board Perch; two flock check-ins now fit beneath one supervisor's gaze."
			2:
				return "Rooster Office level 2 sealed the Glass Supervision Pod; three hens may now receive management attention each shift."
			3:
				return "Rooster Office level 3 opened the Command Roost Gallery; four daily check-ins now support a complete visibility narrative."
	if facility_id == DepartmentSimulation.IT_COOP_ID:
		match level:
			1:
				return "IT Coop level 1 repaired the cable bench; AUTO now recognizes accredited secondary peckwork and runs 3% faster."
			2:
				return "IT Coop level 2 opened predictive dispatch; AUTO runs 6% faster and rescues urgent folders sooner."
			3:
				return "IT Coop level 3 commissioned the automated sorter; AUTO runs 10% faster while every system exception costs more to explain."
	if facility_id == DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID:
		match level:
			1:
				return "Flock Relations level 1 opened Open-Nest Case Intake; one workplace file may now receive a review disposition."
			2:
				return "Flock Relations level 2 opened the Mediation & PIP Room; two open cases and two daily dispositions now fit the ledger."
			3:
				return "Flock Relations level 3 opened the Mandatory Arbitration Roost; three cases may now be managed into final language."
	if facility_id == DepartmentSimulation.FEED_PROCUREMENT_COOP_ID:
		match level:
			1:
				return "Provisions Co-op level 1 opened the Receiving Hopper; one local-grain shift may now be held outside the spot market."
			2:
				return "Provisions Co-op level 2 opened the Dry Grain Reserve; bulk mash can now trade thrift for flock strain."
			3:
				return "Provisions Co-op level 3 opened the Feed Futures Desk; four shifts of grain may now be fixed at today's seasonal quote."
	if facility_id == DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID:
		match level:
			1:
				return "Harvest Credit Gallery level 1 opened the Basket Press Desk; each completed shift may now become one paid public story."
			2:
				return "Harvest Credit Gallery level 2 opened the Clutch Results Wall; verified sound and golden output now earns regional placement rates."
			3:
				return "Harvest Credit Gallery level 3 opened the Executive Harvest Stage; the farmer's method now travels at the bureau's richest publicity rate."
	if facility_id == DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID:
		match level:
			1:
				return "Farmgate Depot level 1 opened the Roadside Loading Shed; finished eggs now wait for a filed dispatch mandate."
			2:
				return "Farmgate Depot level 2 opened the Chilled County Dock; sixteen eggs may reach the auction route each shift."
			3:
				return "Farmgate Depot level 3 commissioned the Regional Route Fleet; six premium eggs may now enter the farmer's showcase."
	return "%s commissioned. Finance has converted shell integrity into a recurring expense." % String(
		definition["name"]
	)


func daily_facility_expansion_cost_cents() -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return maxi(0, sim.office_capacity - 4) * DepartmentSimulation.FACILITY_COST_PER_EXPANDED_SEAT_CENTS


func current_daily_facility_maintenance_cents() -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var maintenance_cents := 0
	for facility_id in DepartmentSimulation.FACILITY_ORDER:
		var definition := DepartmentSimulation.FACILITY_DEFINITIONS[facility_id] as Dictionary
		maintenance_cents += _facility_maintenance_for_level(
			definition,
			facility_level(facility_id),
		)
	return maintenance_cents


func current_daily_facility_cost_cents() -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return (
		daily_facility_expansion_cost_cents()
		+ current_daily_facility_maintenance_cents()
		+ current_daily_campus_cost_cents()
		+ sim.current_daily_portfolio_cost_cents()
	)


func _is_integral_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) != TYPE_FLOAT:
		return false
	var number := float(value)
	return is_finite(number) and number == floor(number)


func _facility_claim_speed_multiplier(worker: ChickenState) -> float:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if worker.current_claim == null or not worker.current_claim.is_rework:
		return 1.0
	return float(facility_effects().get("rework_speed_multiplier", 1.0))


func _store_farmgate_lot_with_campus_capacity(
	claim_id: int,
	laying_day: int,
	worker_id: int,
	worker_name: String,
	quality: StringName,
	value_cents: int,
	farmgate_level: int,
	shelf_shifts: int,
) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var effective_capacity := sim._farmgate_storage_capacity_eggs()
	return sim._farmgate_dispatch.store_lot(
		claim_id,
		laying_day,
		worker_id,
		worker_name,
		quality,
		value_cents,
		farmgate_level,
		shelf_shifts,
		effective_capacity,
		sim._campus_portfolio.farmgate_overflow_basis_points(_campus_portfolio_context()),
	)
