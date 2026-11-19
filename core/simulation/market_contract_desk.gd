class_name MarketContractDesk
extends RefCounted

## Farm Mutual market contracts: quotes, signing, fulfilment and settlement.
## Holds no state of its own: every read and write goes through the owning
## DepartmentSimulation so behaviour is identical to the original in-class methods.

## Weak back-reference: the simulation owns this component, so a strong
## reference here would form a RefCounted cycle and leak both objects.
var _sim_ref: WeakRef


func _init(owner_node: DepartmentSimulation) -> void:
	_sim_ref = weakref(owner_node)

func has_facility(facility_id: StringName) -> bool:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return sim.facility_level(facility_id) > 0


func _service_coop_premium_bonus_cents(base_premium_cents: int, level: int) -> int:
	## The bonus is additive against the authored base, never compounded from a
	## prior tier. Adding half a basis-point denominator before integer division
	## gives deterministic half-up rounding without passing money through floats.
	var numerator := (
		maxi(0, base_premium_cents)
		* maxi(0, level)
		* DepartmentSimulation.SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
		+ 5_000
	)
	@warning_ignore("integer_division")
	return numerator / 10_000


func _basis_point_delta_cents(authored_cents: int, basis_points: int) -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return sim._signed_half_up_ratio(maxi(0, authored_cents) * basis_points, 10_000)


func _neutral_market_season_for_day(target_day: int) -> Dictionary:
	return {
		"id": &"baseline_neutral",
		"label": "BASELINE NEUTRAL BOOK",
		"short_label": "BASELINE BOOK",
		"summary": "Farm Mutual holds authored probation pricing steady before its seasonal book opens.",
		"target_day": target_day,
		"season_index": -1,
		"quarter": 0,
		"year": 0,
		"start_day": DepartmentSimulation.CONTRACT_BOARD_UNLOCK_DAY,
		"end_day": DepartmentSimulation.MARKET_SEASON_FIRST_DAY - 1,
		"days_remaining": maxi(0, DepartmentSimulation.MARKET_SEASON_FIRST_DAY - target_day),
		"lane_demand_basis_points": {
			"nest_damage": 0,
			"predator_loss": 0,
			"appeals": 0,
		},
	}


func market_season_for_day(target_day: int) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if target_day < DepartmentSimulation.MARKET_SEASON_FIRST_DAY:
		return _neutral_market_season_for_day(target_day)
	var day_offset := target_day - DepartmentSimulation.MARKET_SEASON_FIRST_DAY
	@warning_ignore("integer_division")
	var season_serial: int = day_offset / DepartmentSimulation.MARKET_SEASON_LENGTH_DAYS
	var season_index := season_serial % DepartmentSimulation.MARKET_SEASONS_PER_YEAR
	@warning_ignore("integer_division")
	var market_year: int = season_serial / DepartmentSimulation.MARKET_SEASONS_PER_YEAR + 1
	var definition := DepartmentSimulation.MARKET_SEASON_DEFINITIONS[season_index] as Dictionary
	var season_start := (
		DepartmentSimulation.MARKET_SEASON_FIRST_DAY + season_serial * DepartmentSimulation.MARKET_SEASON_LENGTH_DAYS
	)
	return {
		"id": StringName(definition.get("id", &"baseline_neutral")),
		"label": String(definition.get("label", "BASELINE NEUTRAL BOOK")),
		"short_label": String(definition.get("short_label", "BASELINE BOOK")),
		"summary": String(definition.get("summary", "")),
		"target_day": target_day,
		"season_index": season_index,
		"quarter": season_index + 1,
		"year": market_year,
		"start_day": season_start,
		"end_day": season_start + DepartmentSimulation.MARKET_SEASON_LENGTH_DAYS - 1,
		"days_remaining": season_start + DepartmentSimulation.MARKET_SEASON_LENGTH_DAYS - target_day,
		"lane_demand_basis_points": (
			definition.get("lane_demand_basis_points", {}) as Dictionary
		).duplicate(true),
	}


func market_contract_clause_catalog() -> Array[Dictionary]:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var catalog: Array[Dictionary] = []
	var room_owned := has_facility(DepartmentSimulation.FARM_MUTUAL_NEGOTIATION_ROOM_ID)
	for clause_id in DepartmentSimulation.MARKET_CONTRACT_CLAUSE_ORDER:
		var definition := DepartmentSimulation.MARKET_CONTRACT_CLAUSE_DEFINITIONS[clause_id] as Dictionary
		var requires_room := bool(definition.get("requires_negotiation_room", false))
		catalog.append({
			"clause_id": clause_id,
			"label": String(definition.get("label", "STANDARD TERMS")),
			"summary": String(definition.get("summary", "")),
			"category": StringName(definition.get("category", &"standard")),
			"requires_negotiation_room": requires_room,
			"clause_available": not requires_room or room_owned,
			"premium_basis_points": int(definition.get("premium_basis_points", 0)),
			"breach_basis_points": int(definition.get("breach_basis_points", 0)),
		})
	return catalog


func market_pricing_profile_catalog() -> Array[Dictionary]:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var catalog: Array[Dictionary] = []
	var reach := market_reach_points()
	var satisfaction := sim.claimant_satisfaction_score()
	for pricing_id in DepartmentSimulation.MARKET_PRICING_PROFILE_ORDER:
		var definition := DepartmentSimulation.MARKET_PRICING_PROFILE_DEFINITIONS[pricing_id] as Dictionary
		var required_reach := int(definition.get("required_reach", 0))
		var required_satisfaction := int(definition.get("required_satisfaction", 0))
		var availability_reason := _market_pricing_availability_reason(
			required_reach,
			required_satisfaction,
			reach,
			satisfaction,
		)
		catalog.append({
			"pricing_profile_id": pricing_id,
			"label": String(definition.get("label", "MUTUAL RATE")),
			"summary": String(definition.get("summary", "")),
			"premium_basis_points": int(definition.get("premium_basis_points", 0)),
			"volume_delta": int(definition.get("volume_delta", 0)),
			"required_delta": int(definition.get("required_delta", 0)),
			"required_reach": required_reach,
			"required_satisfaction": required_satisfaction,
			"current_reach": reach,
			"current_satisfaction": satisfaction,
			"pricing_available": availability_reason.is_empty(),
			"reason": availability_reason,
		})
	return catalog


func _market_pricing_availability_reason(
	required_reach: int,
	required_satisfaction: int,
	current_reach: int,
	current_satisfaction: int,
) -> String:
	var reasons: Array[String] = []
	if current_reach < required_reach:
		reasons.append(
			"Earn %d market-reach points through fulfilled binders; current reach is %d."
			% [required_reach, current_reach]
		)
	if current_satisfaction < required_satisfaction:
		reasons.append((
			"Executive Select requires claimant sentiment of %d; current sentiment is %d. "
			+ "Fulfill Mutual Rate or Community Access to rebuild claimant trust."
		) % [required_satisfaction, current_satisfaction])
	return " ".join(reasons)


func _market_pricing_outcome_count(pricing_id: StringName, success: bool) -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return maxi(0, int(sim.market_pricing_outcomes.get(
		"%s_%s" % [String(pricing_id), "success" if success else "breach"],
		0,
	)))


func market_reach_points() -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return _market_reach_for_outcomes(sim.market_pricing_outcomes)


func _market_reach_for_outcomes(outcomes: Dictionary) -> int:
	var points := 0
	for pricing_id in DepartmentSimulation.MARKET_PRICING_PROFILE_ORDER:
		var definition := DepartmentSimulation.MARKET_PRICING_PROFILE_DEFINITIONS[pricing_id] as Dictionary
		points += (
			maxi(0, int(outcomes.get("%s_success" % String(pricing_id), 0)))
			* int(definition.get("reach_success_delta", 0))
		)
		points += (
			maxi(0, int(outcomes.get("%s_breach" % String(pricing_id), 0)))
			* int(definition.get("reach_breach_delta", 0))
		)
	return maxi(0, points)


func mutual_market_share_basis_points() -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return clampi(3500 + market_reach_points() * 250, 2500, 8500)


func market_pricing_status() -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return {
		"reach_points": market_reach_points(),
		"claimant_satisfaction": sim.claimant_satisfaction_score(),
		"market_share_basis_points": mutual_market_share_basis_points(),
		"executive_select_reach_requirement": DepartmentSimulation.MARKET_PRICING_EXECUTIVE_REACH_REQUIREMENT,
		"executive_select_satisfaction_minimum": (
			DepartmentSimulation.MARKET_PRICING_EXECUTIVE_SATISFACTION_MINIMUM
		),
		"profiles": market_pricing_profile_catalog(),
	}


func market_contract_planning_open() -> bool:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return sim.day >= DepartmentSimulation.CONTRACT_BOARD_UNLOCK_DAY and sim.staffing_planning_open()


func _market_contract_offer_on_cooldown(offer_id: StringName) -> bool:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return (
		StringName(sim.last_market_contract_result.get("status", &"")) == &"breached"
		and StringName(sim.last_market_contract_result.get("offer_id", &"")) == offer_id
		and int(sim.last_market_contract_result.get("day", 0)) == sim.day - 1
	)


func market_contract_offer_catalog() -> Array[Dictionary]:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var offers: Array[Dictionary] = []
	if sim.day < DepartmentSimulation.CONTRACT_BOARD_UNLOCK_DAY:
		return offers
	var basis := _market_contract_preflight_basis()
	for offer_id in DepartmentSimulation.MARKET_CONTRACT_OFFER_ORDER:
		offers.append(_market_contract_offer_preflight(offer_id, &"standard_terms", &"mutual_rate", true, true, basis))
	return offers


func _market_contract_preflight_basis() -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	# One synchronous publication has one exact set of eligibility inputs. Share
	# it only within that call, never across ticks or public signing requests.
	var capacity := sim.current_claim_capacity()
	return {
		"capacity": capacity,
		"available_slots": maxi(0, capacity - sim._outstanding_claim_count() - _pending_market_contract_claim_count()),
		"spendable": sim.spendable_fund_cents(),
		"active_staff": sim.active_worker_count(),
		"planning_open": market_contract_planning_open(),
	}


func market_contract_offer_preflight(
	offer_id: StringName,
	clause_id: StringName = &"standard_terms",
	pricing_id: StringName = &"mutual_rate",
) -> Dictionary:
	return _market_contract_offer_preflight(offer_id, clause_id, pricing_id, true, true)


func _market_contract_offer_preflight(
	offer_id: StringName,
	clause_id: StringName,
	pricing_id: StringName,
	attach_clause_options: bool,
	attach_pricing_options: bool,
	basis: Dictionary = {},
) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var live_basis := basis if not basis.is_empty() else _market_contract_preflight_basis()
	var clause_known := DepartmentSimulation.MARKET_CONTRACT_CLAUSE_DEFINITIONS.has(clause_id)
	var pricing_known := DepartmentSimulation.MARKET_PRICING_PROFILE_DEFINITIONS.has(pricing_id)
	var offer := {}
	if clause_known and pricing_known:
		offer = _market_contract_quote_for_day(
			offer_id,
			sim.day,
			maxi(0, sim.facility_level(DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID)),
			maxi(0, sim.facility_level(DepartmentSimulation.FARM_MUTUAL_NEGOTIATION_ROOM_ID)),
			clause_id,
			false,
			pricing_id,
		)
	if offer.is_empty():
		var unknown := {
			"id": offer_id,
			"offer_id": offer_id,
			"known": DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS.has(offer_id),
			"clause_known": clause_known,
			"clause_id": clause_id,
			"pricing_known": pricing_known,
			"pricing_profile_id": pricing_id,
			"clause_available": false,
			"pricing_available": false,
			"can_sign": false,
			"reason": (
				"Farm Mutual does not recognize that binder."
				if not DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS.has(offer_id) else
				"Farm Mutual does not recognize that negotiated clause."
				if not clause_known else
				"Farm Mutual does not recognize that pricing posture."
			),
		}
		if attach_clause_options and DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS.has(offer_id):
			unknown["clause_options"] = _market_contract_clause_options(offer_id, live_basis)
		if attach_pricing_options and DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS.has(offer_id):
			unknown["pricing_options"] = _market_contract_pricing_options(offer_id, clause_id, live_basis)
		return unknown
	var capacity := int(live_basis["capacity"])
	var available_slots := int(live_basis["available_slots"])
	var breach_cents := int(offer.get("breach_cents", 0))
	var spendable := int(live_basis["spendable"])
	var required_active_staff := int(offer.get("required_active_staff", 0))
	var active_staff := int(live_basis["active_staff"])
	var on_cooldown := _market_contract_offer_on_cooldown(offer_id)
	var reason := ""
	if not bool(offer.get("pricing_available", false)):
		reason = String(offer.get(
			"pricing_unavailable_reason",
			"This pricing posture is not available for the current market reach.",
		))
	elif not bool(offer.get("clause_available", false)):
		reason = "Commission the Farm Mutual Negotiation Room before signing this clause."
	elif sim.day < DepartmentSimulation.CONTRACT_BOARD_UNLOCK_DAY:
		reason = "Complete two shifts before Farm Mutual opens its contract folders."
	elif sim.shift_phase != DepartmentSimulation.ShiftPhase.REVIEW:
		reason = "Market binders may be signed only during closed-shift planning."
	elif not sim.pending_decision.is_empty():
		reason = "File the closing credit memo before accepting outside peckwork."
	elif (
		not sim.market_contract_decline_receipt.is_empty()
		and int(sim.market_contract_decline_receipt.get("target_day", 0)) == sim.day
	):
		reason = "The standard book was already filed for Day %d." % sim.day
	elif not sim.active_market_contract.is_empty():
		reason = "One Farm Mutual binder is already signed for Day %d." % int(
			sim.active_market_contract.get("target_day", sim.day)
		)
	elif on_cooldown:
		reason = "%s is cooling in Farm Mutual review for one planning day after yesterday's breach." % String(
			offer.get("short_name", "This binder")
		)
	elif capacity < int(offer.get("required_claim_capacity", 0)):
		reason = "%s requires %d live-file roosts; the bureau currently has %d." % [
			String(offer.get("short_name", "This binder")),
			int(offer.get("required_claim_capacity", 0)),
			capacity,
		]
	elif active_staff < required_active_staff:
		reason = "%s requires %d active hens; the bureau currently staffs %d." % [
			String(offer.get("short_name", "This binder")),
			required_active_staff,
			active_staff,
		]
	elif available_slots < int(offer.get("total_claims", 0)):
		reason = "%d more empty file roost%s required before these folders can be reserved." % [
			int(offer.get("total_claims", 0)) - available_slots,
			"" if int(offer.get("total_claims", 0)) - available_slots == 1 else "s",
		]
	elif spendable < breach_cents:
		reason = "$%.2f more spendable Feed Fund is required to reserve the breach clause." % (
			float(breach_cents - spendable) / 100.0
		)
	offer["known"] = true
	offer["clause_known"] = true
	offer["pricing_known"] = true
	offer["planning_open"] = bool(live_basis["planning_open"])
	offer["available_claim_slots"] = available_slots
	offer["spendable_fund_cents"] = spendable
	offer["breach_reserve_cents"] = breach_cents
	offer["spendable_after_reserve_cents"] = spendable - breach_cents
	offer["active_staff_count"] = active_staff
	offer["active_staff_shortfall"] = maxi(0, required_active_staff - active_staff)
	offer["staffing_ready"] = active_staff >= required_active_staff
	offer["on_cooldown"] = on_cooldown
	offer["cooldown_until_day"] = sim.day if on_cooldown else 0
	offer["can_sign"] = reason.is_empty()
	offer["reason"] = reason
	if attach_clause_options:
		offer["clause_options"] = _market_contract_clause_options(offer_id, live_basis)
	if attach_pricing_options:
		offer["pricing_options"] = _market_contract_pricing_options(offer_id, clause_id, live_basis)
	return offer


func _market_contract_clause_options(offer_id: StringName, basis: Dictionary = {}) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for clause_id in DepartmentSimulation.MARKET_CONTRACT_CLAUSE_ORDER:
		var option := _market_contract_offer_preflight(
			offer_id,
			clause_id,
			&"mutual_rate",
			false,
			true,
			basis,
		)
		options.append(option)
	return options


func _market_contract_pricing_options(
	offer_id: StringName,
	clause_id: StringName,
	basis: Dictionary = {},
) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for pricing_id in DepartmentSimulation.MARKET_PRICING_PROFILE_ORDER:
		options.append(_market_contract_offer_preflight(
			offer_id,
			clause_id,
			pricing_id,
			false,
			false,
			basis,
		))
	return options


func market_contract_board_status() -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var unlocked := sim.day >= DepartmentSimulation.CONTRACT_BOARD_UNLOCK_DAY
	var standing := sim.farm_mutual_standing_status()
	var accreditation := sim.farm_mutual_service_coop_status()
	var negotiation_room := sim.farm_mutual_negotiation_room_status()
	var season := market_season_for_day(sim.day)
	var active := sim.active_market_contract.duplicate(true)
	if not active.is_empty():
		active["remaining_required"] = maxi(
			0,
			int(active.get("required_completed", 0))
			- int(active.get("timely_sound_completed", 0)),
		)
		active["pending_arrivals"] = _pending_market_contract_claim_count()
		active["breach_reserve_cents"] = current_market_contract_reserve_cents()
	return {
		"unlocked": unlocked,
		"unlock_day": DepartmentSimulation.CONTRACT_BOARD_UNLOCK_DAY,
		"unlock_requirement": "Complete two shifts to open Farm Mutual's contract folders.",
		"planning_open": market_contract_planning_open(),
		"target_day": sim.day,
		"season": season,
		"season_id": season.get("id", &"baseline_neutral"),
		"season_label": String(season.get("label", "BASELINE NEUTRAL BOOK")),
		"standing": standing,
		"accreditation": accreditation,
		"negotiation_room": negotiation_room,
		"pricing": market_pricing_status(),
		"offers": market_contract_offer_catalog(),
		"active": active,
		"active_contract": active.duplicate(true),
		"decline_available": (
			unlocked
			and market_contract_planning_open()
			and active.is_empty()
			and sim.market_contract_decline_receipt.is_empty()
		),
		"decline_receipt": sim.market_contract_decline_receipt.duplicate(true),
		"last_result": sim.last_market_contract_result.duplicate(true),
		"claim_capacity": sim.current_claim_capacity(),
		"claims_outstanding": sim._outstanding_claim_count(),
		"reserved_claim_slots": _pending_market_contract_claim_count(),
		"breach_reserve_cents": current_market_contract_reserve_cents(),
		"contracts_signed_total": sim.market_contracts_signed_total,
		"contracts_succeeded_total": sim.market_contracts_succeeded_total,
		"contracts_breached_total": sim.market_contracts_breached_total,
		"market_standing": int(standing.get("points", 0)),
		"market_standing_rank": standing.get("rank", &"unlisted"),
		"market_clean_contract_streak": sim.market_clean_contract_streak,
		"best_market_clean_contract_streak": sim.best_market_clean_contract_streak,
		"service_coop_level": int(accreditation.get("level", 0)),
		"service_coop_premium_bonus_basis_points": int(
			accreditation.get("premium_bonus_basis_points", 0)
		),
		"negotiation_room_level": int(negotiation_room.get("level", 0)),
		"premium_today_cents": sim.market_contract_premium_today_cents,
		"premium_total_cents": sim.market_contract_premium_total_cents,
		"breach_today_cents": sim.market_contract_breach_today_cents,
		"breach_total_cents": sim.market_contract_breach_total_cents,
	}


func sign_market_contract(
	offer_id: StringName,
	clause_id: StringName = &"standard_terms",
	pricing_id: StringName = &"mutual_rate",
) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	## Signing is a reserve transaction, not income or expense. The exact folders
	## and claim IDs are authored now, then released at their disclosed times
	## without opening a modal or stopping the production clock.
	var preflight := market_contract_offer_preflight(offer_id, clause_id, pricing_id)
	if not bool(preflight.get("can_sign", false)):
		var rejection := preflight.duplicate(true)
		rejection["accepted"] = false
		return rejection
	var fund_before := sim.revenue_cents
	var claim_ids: Array[int] = []
	var scheduled_claims: Array[Dictionary] = []
	for schedule_value in preflight.get("scheduled_claims", []):
		var schedule := (schedule_value as Dictionary).duplicate(true)
		var claim_id := sim._next_claim_id
		sim._next_claim_id += 1
		claim_ids.append(claim_id)
		schedule["claim_id"] = claim_id
		schedule["released"] = false
		schedule["rejected"] = false
		scheduled_claims.append(schedule)
	var contract_id := "FM-%04d-%s" % [sim.day, String(offer_id).to_upper()]
	sim.active_market_contract = preflight.duplicate(true)
	for transient_field in [
		"known", "clause_known", "planning_open", "available_claim_slots",
		"spendable_fund_cents", "breach_reserve_cents", "spendable_after_reserve_cents",
		"active_staff_count", "active_staff_shortfall", "staffing_ready", "on_cooldown",
		"cooldown_until_day", "can_sign", "reason", "clause_options", "pricing_options",
	]:
		sim.active_market_contract.erase(transient_field)
	sim.active_market_contract.merge({
		"version": 2,
		"contract_id": contract_id,
		"offer_id": String(offer_id),
		"id": String(offer_id),
		"signed_day": sim.day,
		"target_day": sim.day,
		"deadline_day": sim.day,
		"status": "signed",
		"legacy_staffing_grandfathered": false,
		"legacy_terms_grandfathered": false,
		"scheduled_claims": scheduled_claims,
		"claim_ids": claim_ids,
		"accepted_claim_ids": [],
		"completed_claim_ids": [],
		"sound_completed_claim_ids": [],
		"timely_sound_claim_ids": [],
		"cracked_claim_ids": [],
		"late_claim_ids": [],
		"rejected_claim_ids": [],
		"released_batch_count": 0,
		"completed_count": 0,
		"sound_completed": 0,
		"timely_sound_completed": 0,
		"rush_completed_on_time": 0,
		"cracked_count": 0,
		"late_count": 0,
	}, true)
	sim.market_contracts_signed_total += 1
	var result := market_contract_board_status()
	result.merge({
		"accepted": true,
		"action_id": &"sign_market_contract",
		"offer_id": offer_id,
		"clause_id": clause_id,
		"pricing_profile_id": pricing_id,
		"contract_id": contract_id,
		"required_active_staff": int(preflight.get("required_active_staff", 0)),
		"base_premium_cents": int(preflight.get("base_premium_cents", 0)),
		"season_premium_delta_cents": int(preflight.get("season_premium_delta_cents", 0)),
		"clause_premium_delta_cents": int(preflight.get("clause_premium_delta_cents", 0)),
		"market_premium_cents": int(preflight.get("market_premium_cents", 0)),
		"service_coop_level_at_signing": int(preflight.get("service_coop_level_at_signing", 0)),
		"service_coop_bonus_cents": int(preflight.get("service_coop_bonus_cents", 0)),
		"premium_bonus_basis_points": int(preflight.get("premium_bonus_basis_points", 0)),
		"premium_cents": int(preflight.get("premium_cents", 0)),
		"fund_before_cents": fund_before,
		"fund_after_cents": sim.revenue_cents,
		"fund_delta_cents": sim.revenue_cents - fund_before,
		"outcome": "%s signed for Day %d. $%.2f remains reserved against breach." % [
			String(preflight.get("short_name", "Farm Mutual binder")),
			sim.day,
			float(preflight.get("breach_cents", 0)) / 100.0,
		],
	}, true)
	sim.announcement_posted.emit(String(result["outcome"]))
	sim.market_contract_signed.emit(result.duplicate(true))
	sim.snapshot_changed.emit(sim.snapshot())
	return result


func decline_market_contract() -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	## Outside work is optional, but skipping it must be a visible authored choice
	## rather than an accidental close button or a silent failure to sign.
	var reason := ""
	if sim.day < DepartmentSimulation.CONTRACT_BOARD_UNLOCK_DAY:
		reason = "Farm Mutual has not opened its client folders yet."
	elif not sim.staffing_planning_open():
		reason = "The standard book may be filed only during closed-shift planning."
	elif not sim.active_market_contract.is_empty():
		reason = "A Farm Mutual binder is already signed for Day %d." % sim.day
	elif (
		not sim.market_contract_decline_receipt.is_empty()
		and int(sim.market_contract_decline_receipt.get("target_day", 0)) == sim.day
	):
		reason = "The standard book is already filed for Day %d." % sim.day
	if not reason.is_empty():
		return {
			"accepted": false,
			"action_id": &"decline_market_contract",
			"target_day": sim.day,
			"reason": reason,
			"outcome": reason,
		}
	sim.market_contract_decline_receipt = {
		"version": 1,
		"accepted": true,
		"action_id": "decline_market_contract",
		"status": "declined",
		"day": sim.day,
		"target_day": sim.day,
		"outcome": "STANDARD BOOK FILED: no outside Farm Mutual binder will arrive on Day %d." % sim.day,
	}
	var result := market_contract_board_status()
	result.merge(sim.market_contract_decline_receipt.duplicate(true), true)
	sim.announcement_posted.emit(String(sim.market_contract_decline_receipt["outcome"]))
	sim.market_contract_declined.emit(result.duplicate(true))
	sim.snapshot_changed.emit(sim.snapshot())
	return result


func _legacy_market_contract_offer_for_day(offer_id: StringName, target_day: int) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if not DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS.has(offer_id):
		return {}
	var definition := DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS[offer_id] as Dictionary
	var lane_mix: Dictionary = {}
	var rush_lane_mix: Dictionary = {}
	var arrival_batches: Array[Dictionary] = []
	var scheduled_claims: Array[Dictionary] = []
	var rush_claims := 0
	var service_window := int(definition.get("service_window_minutes", 1))
	var batch_index := 0
	for batch_value in definition.get("arrival_batches", []):
		var batch := batch_value as Dictionary
		var arrival_minute := clampi(
			int(batch.get("minute_of_day", DepartmentSimulation.SHIFT_START_MINUTE)),
			DepartmentSimulation.SHIFT_START_MINUTE,
			DepartmentSimulation.SHIFT_END_MINUTE,
		)
		var rush := bool(batch.get("rush", false))
		var batch_lanes: Array[String] = []
		for lane_value in batch.get("lanes", []):
			var lane := StringName(String(lane_value))
			if lane not in DepartmentSimulation.CLAIM_LANES:
				continue
			var lane_key := String(lane)
			lane_mix[lane_key] = int(lane_mix.get(lane_key, 0)) + 1
			if rush:
				rush_lane_mix[lane_key] = int(rush_lane_mix.get(lane_key, 0)) + 1
				rush_claims += 1
			var deadline_minute := mini(DepartmentSimulation.SHIFT_END_MINUTE, arrival_minute + service_window)
			batch_lanes.append(lane_key)
			scheduled_claims.append({
				"batch_index": batch_index,
				"lane": lane_key,
				"rush": rush,
				"arrival_minute_of_day": arrival_minute,
				"arrival_time": sim._format_time(arrival_minute),
				"deadline_minute_of_day": deadline_minute,
				"deadline_time": sim._format_time(deadline_minute),
				"service_window_minutes": deadline_minute - arrival_minute,
			})
		arrival_batches.append({
			"batch_index": batch_index,
			"minute_of_day": arrival_minute,
			"time": sim._format_time(arrival_minute),
			"deadline_minute_of_day": mini(DepartmentSimulation.SHIFT_END_MINUTE, arrival_minute + service_window),
			"deadline_time": sim._format_time(mini(DepartmentSimulation.SHIFT_END_MINUTE, arrival_minute + service_window)),
			"lanes": batch_lanes,
			"lane_mix": _contract_lane_mix(batch_lanes),
			"count": batch_lanes.size(),
			"rush": rush,
		})
		batch_index += 1
	var total_claims := scheduled_claims.size()
	var required_completed := int(definition.get("required_deliveries", total_claims))
	var base_premium_cents := int(definition.get("premium_cents", 0))
	var service_coop_level := maxi(0, sim.facility_level(DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID))
	var service_coop_bonus_cents := _service_coop_premium_bonus_cents(
		base_premium_cents,
		service_coop_level,
	)
	var arrival_lines: Array[String] = []
	for batch in arrival_batches:
		arrival_lines.append("%s  %s%s" % [
			String(batch.get("time", "9:00 AM")),
			_contract_lane_mix_label(batch.get("lane_mix", {}) as Dictionary),
			"  ·  RUSH" if bool(batch.get("rush", false)) else "",
		])
	return {
		"id": offer_id,
		"offer_id": offer_id,
		"name": String(definition.get("name", "FARM MUTUAL BINDER")),
		"short_name": String(definition.get("short_name", "MUTUAL BINDER")),
		"client": String(definition.get("client", "FARM MUTUAL")),
		"tagline": String(definition.get("tagline", "Outside peckwork filed.")),
		"tone": StringName(definition.get("tone", &"quality")),
		"target_day": target_day,
		"deadline_day": target_day,
		"required_claim_capacity": int(definition.get("required_claim_capacity", 0)),
		"required_active_staff": int(definition.get("required_active_staff", 0)),
		"required_completed": required_completed,
		"required_deliveries": required_completed,
		"total_claims": total_claims,
		"rush_claims": rush_claims,
		"service_window_minutes": service_window,
		"base_premium_cents": base_premium_cents,
		"service_coop_level_at_signing": service_coop_level,
		"service_coop_bonus_cents": service_coop_bonus_cents,
		"premium_bonus_basis_points": (
			service_coop_level * DepartmentSimulation.SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
		),
		"premium_cents": base_premium_cents + service_coop_bonus_cents,
		"breach_cents": int(definition.get("breach_cents", 0)),
		"lane_mix": lane_mix,
		"lane_mix_label": _contract_lane_mix_label(lane_mix),
		"rush_lane_mix": rush_lane_mix,
		"rush_lane_mix_label": _contract_lane_mix_label(rush_lane_mix),
		"arrival_batches": arrival_batches,
		"scheduled_claims": scheduled_claims,
		"arrival_schedule": "\n".join(arrival_lines),
		"success_required": "%d sound or golden folders delivered inside their disclosed service windows." % required_completed,
		"benefit": "+$%.2f closing premium on fulfillment ($%.2f base + $%.2f Service Coop)" % [
			float(base_premium_cents + service_coop_bonus_cents) / 100.0,
			float(base_premium_cents) / 100.0,
			float(service_coop_bonus_cents) / 100.0,
		],
		"tradeoff": "-$%.2f breach charge if fewer than %d folders arrive clean and on time" % [
			float(definition.get("breach_cents", 0)) / 100.0,
			required_completed,
		],
	}


func _market_contract_offer_for_day(offer_id: StringName, target_day: int) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return _market_contract_quote_for_day(
		offer_id,
		target_day,
		maxi(0, sim.facility_level(DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID)),
		maxi(0, sim.facility_level(DepartmentSimulation.FARM_MUTUAL_NEGOTIATION_ROOM_ID)),
		&"standard_terms",
	)


func _market_contract_quote_for_day(
	offer_id: StringName,
	target_day: int,
	service_coop_level: int,
	negotiation_room_level: int,
	clause_id: StringName,
	force_neutral_terms: bool = false,
	pricing_id: StringName = &"mutual_rate",
) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if not DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS.has(offer_id) or not DepartmentSimulation.MARKET_CONTRACT_CLAUSE_DEFINITIONS.has(clause_id) or not DepartmentSimulation.MARKET_PRICING_PROFILE_DEFINITIONS.has(pricing_id):
		return {}
	var context := [target_day, clampi(service_coop_level, 0, 3), clampi(negotiation_room_level, 0, 1), force_neutral_terms, market_reach_points(), sim.claimant_satisfaction_score()]
	if context != sim._market_quote_context:
		sim._market_quote_context = context
		sim._market_quote_cache.clear()
	var key := "%s|%s|%s" % [offer_id, clause_id, pricing_id]
	if not sim._market_quote_cache.has(key):
		var started := sim.cost_probe.begin()
		sim._market_quote_cache[key] = _build_market_contract_quote_for_day(
			offer_id, target_day, service_coop_level, negotiation_room_level,
			clause_id, force_neutral_terms, pricing_id,
		)
		sim.cost_probe.finish(&"market_quote_build", started)
	# Callers annotate preflights and retain signed schedules. Never expose the
	# bank, or share nested arrays between two returned offers or saved contracts.
	return (sim._market_quote_cache[key] as Dictionary).duplicate(true)


func _build_market_contract_quote_for_day(
	offer_id: StringName,
	target_day: int,
	service_coop_level: int,
	negotiation_room_level: int,
	clause_id: StringName,
	force_neutral_terms: bool = false,
	pricing_id: StringName = &"mutual_rate",
) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if not DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS.has(offer_id):
		return {}
	if not DepartmentSimulation.MARKET_CONTRACT_CLAUSE_DEFINITIONS.has(clause_id):
		return {}
	if not DepartmentSimulation.MARKET_PRICING_PROFILE_DEFINITIONS.has(pricing_id):
		return {}
	var definition := DepartmentSimulation.MARKET_CONTRACT_DEFINITIONS[offer_id] as Dictionary
	var clause := DepartmentSimulation.MARKET_CONTRACT_CLAUSE_DEFINITIONS[clause_id] as Dictionary
	var pricing := DepartmentSimulation.MARKET_PRICING_PROFILE_DEFINITIONS[pricing_id] as Dictionary
	var authored_lane_mix: Dictionary = {}
	var scheduled_claims: Array[Dictionary] = []
	var authored_service_window := int(definition.get("service_window_minutes", 1))
	var service_window := authored_service_window
	if clause_id == &"expedited_hatch_rider":
		service_window = maxi(60, authored_service_window - 60)
	var authored_dominant_lane := _market_contract_dominant_lane(definition)
	var batch_index := 0
	for batch_value in definition.get("arrival_batches", []):
		var batch := batch_value as Dictionary
		var arrival_minute := clampi(
			int(batch.get("minute_of_day", DepartmentSimulation.SHIFT_START_MINUTE)),
			DepartmentSimulation.SHIFT_START_MINUTE,
			DepartmentSimulation.SHIFT_END_MINUTE,
		)
		var authored_rush := bool(batch.get("rush", false))
		for lane_value in batch.get("lanes", []):
			var authored_lane := StringName(String(lane_value))
			if authored_lane not in DepartmentSimulation.CLAIM_LANES:
				continue
			var authored_lane_key := String(authored_lane)
			authored_lane_mix[authored_lane_key] = int(
				authored_lane_mix.get(authored_lane_key, 0)
			) + 1
			var effective_lane := (
				authored_dominant_lane
				if clause_id == &"specialist_roost_endorsement" else
				authored_lane
			)
			var deadline_minute := mini(DepartmentSimulation.SHIFT_END_MINUTE, arrival_minute + service_window)
			scheduled_claims.append({
				"batch_index": batch_index,
				"lane": String(effective_lane),
				"authored_lane": authored_lane_key,
				"rush": authored_rush,
				"authored_rush": authored_rush,
				"arrival_minute_of_day": arrival_minute,
				"arrival_time": sim._format_time(arrival_minute),
				"deadline_minute_of_day": deadline_minute,
				"deadline_time": sim._format_time(deadline_minute),
				"service_window_minutes": deadline_minute - arrival_minute,
			})
		batch_index += 1
	if clause_id == &"expedited_hatch_rider":
		var latest_standard_index := -1
		var latest_standard_arrival := -1
		for schedule_index in scheduled_claims.size():
			var candidate := scheduled_claims[schedule_index]
			if bool(candidate.get("rush", false)):
				continue
			var candidate_arrival := int(candidate.get("arrival_minute_of_day", -1))
			if candidate_arrival >= latest_standard_arrival:
				latest_standard_arrival = candidate_arrival
				latest_standard_index = schedule_index
		if latest_standard_index >= 0:
			var expedited_schedule := scheduled_claims[latest_standard_index]
			expedited_schedule["rush"] = true
			scheduled_claims[latest_standard_index] = expedited_schedule
	var pricing_volume_delta := int(pricing.get("volume_delta", 0))
	if pricing_volume_delta > 0 and not scheduled_claims.is_empty():
		var referral_schedule := (scheduled_claims[0] as Dictionary).duplicate(true)
		referral_schedule["batch_index"] = int(referral_schedule.get("batch_index", 0))
		referral_schedule["pricing_referral"] = true
		scheduled_claims.append(referral_schedule)
	elif pricing_volume_delta < 0 and scheduled_claims.size() > 1:
		var removable_index := -1
		for schedule_index in range(scheduled_claims.size() - 1, -1, -1):
			if not bool((scheduled_claims[schedule_index] as Dictionary).get("rush", false)):
				removable_index = schedule_index
				break
		if removable_index < 0:
			removable_index = scheduled_claims.size() - 1
		scheduled_claims.remove_at(removable_index)

	var lane_mix: Dictionary = {}
	var rush_lane_mix: Dictionary = {}
	var rush_claims := 0
	for schedule in scheduled_claims:
		var lane_key := String(schedule.get("lane", ""))
		lane_mix[lane_key] = int(lane_mix.get(lane_key, 0)) + 1
		if bool(schedule.get("rush", false)):
			rush_lane_mix[lane_key] = int(rush_lane_mix.get(lane_key, 0)) + 1
			rush_claims += 1
	var arrival_batches: Array[Dictionary] = []
	for authored_batch_index in (definition.get("arrival_batches", []) as Array).size():
		var batch_lanes: Array[String] = []
		var batch_rush_count := 0
		var arrival_minute := DepartmentSimulation.SHIFT_START_MINUTE
		var deadline_minute := DepartmentSimulation.SHIFT_START_MINUTE
		for schedule in scheduled_claims:
			if int(schedule.get("batch_index", -1)) != authored_batch_index:
				continue
			batch_lanes.append(String(schedule.get("lane", "")))
			arrival_minute = int(schedule.get("arrival_minute_of_day", DepartmentSimulation.SHIFT_START_MINUTE))
			deadline_minute = int(schedule.get("deadline_minute_of_day", DepartmentSimulation.SHIFT_END_MINUTE))
			if bool(schedule.get("rush", false)):
				batch_rush_count += 1
		arrival_batches.append({
			"batch_index": authored_batch_index,
			"minute_of_day": arrival_minute,
			"time": sim._format_time(arrival_minute),
			"deadline_minute_of_day": deadline_minute,
			"deadline_time": sim._format_time(deadline_minute),
			"lanes": batch_lanes,
			"lane_mix": _contract_lane_mix(batch_lanes),
			"count": batch_lanes.size(),
			"rush": batch_rush_count == batch_lanes.size() and not batch_lanes.is_empty(),
			"contains_rush": batch_rush_count > 0,
			"rush_count": batch_rush_count,
		})

	var total_claims := scheduled_claims.size()
	var required_completed := clampi(
		int(definition.get("required_deliveries", total_claims))
		+ int(pricing.get("required_delta", 0)),
		1,
		total_claims,
	)
	var authored_base_premium_cents := int(definition.get("premium_cents", 0))
	var authored_breach_cents := int(definition.get("breach_cents", 0))
	var season := (
		_neutral_market_season_for_day(target_day)
		if force_neutral_terms else
		market_season_for_day(target_day)
	)
	var season_lane_demand := season.get("lane_demand_basis_points", {}) as Dictionary
	var demand_numerator := 0
	for lane in DepartmentSimulation.CLAIM_LANES:
		var authored_lane_key := String(lane)
		demand_numerator += (
			int(authored_lane_mix.get(authored_lane_key, 0))
			* int(season_lane_demand.get(authored_lane_key, 0))
		)
	var season_demand_basis_points := sim._signed_half_up_ratio(
		demand_numerator,
		maxi(1, total_claims),
	)
	var season_premium_delta_cents := _basis_point_delta_cents(
		authored_base_premium_cents,
		season_demand_basis_points,
	)
	var season_breach_basis_points := maxi(
		0,
		sim._signed_half_up_ratio(season_demand_basis_points, 2),
	)
	var season_breach_delta_cents := _basis_point_delta_cents(
		authored_breach_cents,
		season_breach_basis_points,
	)
	var clause_premium_basis_points := int(clause.get("premium_basis_points", 0))
	var clause_breach_basis_points := int(clause.get("breach_basis_points", 0))
	var clause_premium_delta_cents := _basis_point_delta_cents(
		authored_base_premium_cents,
		clause_premium_basis_points,
	)
	var clause_breach_delta_cents := _basis_point_delta_cents(
		authored_breach_cents,
		clause_breach_basis_points,
	)
	var pricing_premium_basis_points := int(pricing.get("premium_basis_points", 0))
	var pricing_premium_delta_cents := _basis_point_delta_cents(
		authored_base_premium_cents,
		pricing_premium_basis_points,
	)
	var market_premium_cents := (
		authored_base_premium_cents
		+ season_premium_delta_cents
		+ clause_premium_delta_cents
		+ pricing_premium_delta_cents
	)
	service_coop_level = clampi(service_coop_level, 0, 3)
	negotiation_room_level = clampi(negotiation_room_level, 0, 1)
	var service_coop_bonus_cents := _service_coop_premium_bonus_cents(
		authored_base_premium_cents,
		service_coop_level,
	)
	var premium_cents := market_premium_cents + service_coop_bonus_cents
	var breach_cents := (
		authored_breach_cents
		+ season_breach_delta_cents
		+ clause_breach_delta_cents
	)
	var welfare_gate_minimum := (
		DepartmentSimulation.RESTED_FLOCK_WELFARE_MINIMUM
		if clause_id == &"rested_flock_warranty" else
		0
	)
	var arrival_lines: Array[String] = []
	for batch in arrival_batches:
		arrival_lines.append("%s  %s%s" % [
			String(batch.get("time", "9:00 AM")),
			_contract_lane_mix_label(batch.get("lane_mix", {}) as Dictionary),
			"  ·  RUSH" if bool(batch.get("contains_rush", false)) else "",
		])
	var requires_room := bool(clause.get("requires_negotiation_room", false))
	var required_reach := int(pricing.get("required_reach", 0))
	var required_satisfaction := int(pricing.get("required_satisfaction", 0))
	var current_reach := market_reach_points()
	var current_satisfaction := sim.claimant_satisfaction_score()
	var pricing_unavailable_reason := _market_pricing_availability_reason(
		required_reach,
		required_satisfaction,
		current_reach,
		current_satisfaction,
	)
	var pricing_available := pricing_unavailable_reason.is_empty()
	var estimated_handling_cost_cents := (
		total_claims * DepartmentSimulation.MARKET_PRICING_ESTIMATED_HANDLING_COST_CENTS
	)
	var estimated_margin_cents := premium_cents - estimated_handling_cost_cents
	var success_required := "%d sound or golden folders delivered inside their disclosed service windows." % required_completed
	if welfare_gate_minimum > 0:
		success_required += " Closing flock welfare must also remain at %d or above." % welfare_gate_minimum
	return {
		"id": offer_id,
		"offer_id": offer_id,
		"name": String(definition.get("name", "FARM MUTUAL BINDER")),
		"short_name": String(definition.get("short_name", "MUTUAL BINDER")),
		"client": String(definition.get("client", "FARM MUTUAL")),
		"tagline": String(definition.get("tagline", "Outside peckwork filed.")),
		"tone": StringName(definition.get("tone", &"quality")),
		"target_day": target_day,
		"deadline_day": target_day,
		"quote_id": "FM-%04d-%s-%s" % [
			target_day,
			String(offer_id).to_upper(),
			String(clause_id).to_upper(),
		],
		"season": season.duplicate(true),
		"season_id": season.get("id", &"baseline_neutral"),
		"season_label": String(season.get("label", "BASELINE NEUTRAL BOOK")),
		"season_demand_basis_points": season_demand_basis_points,
		"required_claim_capacity": int(definition.get("required_claim_capacity", 0)),
		"required_active_staff": int(definition.get("required_active_staff", 0)),
		"required_completed": required_completed,
		"required_deliveries": required_completed,
		"total_claims": total_claims,
		"rush_claims": rush_claims,
		"authored_service_window_minutes": authored_service_window,
		"service_window_minutes": service_window,
		"clause_id": clause_id,
		"clause_label": String(clause.get("label", "STANDARD TERMS")),
		"clause_summary": String(clause.get("summary", "")),
		"clause_category": StringName(clause.get("category", &"standard")),
		"category": StringName(clause.get("category", &"standard")),
		"label": String(clause.get("label", "STANDARD TERMS")),
		"summary": String(clause.get("summary", "")),
		"requires_negotiation_room": requires_room,
		"clause_available": not requires_room or negotiation_room_level > 0,
		"pricing_profile_id": pricing_id,
		"pricing_label": String(pricing.get("label", "MUTUAL RATE")),
		"pricing_summary": String(pricing.get("summary", "")),
		"pricing_premium_basis_points": pricing_premium_basis_points,
		"pricing_premium_delta_cents": pricing_premium_delta_cents,
		"pricing_volume_delta": pricing_volume_delta,
		"pricing_required_delta": int(pricing.get("required_delta", 0)),
		"pricing_required_reach": required_reach,
		"pricing_required_satisfaction": required_satisfaction,
		"pricing_current_reach": current_reach,
		"pricing_current_satisfaction": current_satisfaction,
		"pricing_available": pricing_available,
		"pricing_unavailable_reason": pricing_unavailable_reason,
		"claimant_satisfaction_success_delta": int(
			pricing.get("satisfaction_success_delta", 0)
		),
		"claimant_satisfaction_breach_delta": int(
			pricing.get("satisfaction_breach_delta", 0)
		),
		"market_reach_success_delta": int(pricing.get("reach_success_delta", 0)),
		"market_reach_breach_delta": int(pricing.get("reach_breach_delta", 0)),
		"estimated_handling_cost_cents": estimated_handling_cost_cents,
		"estimated_margin_cents": estimated_margin_cents,
		"estimated_margin_per_file_cents": sim._signed_half_up_ratio(
			estimated_margin_cents,
			maxi(1, total_claims),
		),
		"negotiation_room_level_at_signing": negotiation_room_level,
		"authored_base_premium_cents": authored_base_premium_cents,
		"base_premium_cents": authored_base_premium_cents,
		"season_premium_delta_cents": season_premium_delta_cents,
		"clause_premium_basis_points": clause_premium_basis_points,
		"clause_premium_delta_cents": clause_premium_delta_cents,
		"market_premium_cents": market_premium_cents,
		"service_coop_level_at_signing": service_coop_level,
		"service_coop_bonus_cents": service_coop_bonus_cents,
		"premium_bonus_basis_points": (
			service_coop_level * DepartmentSimulation.SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
		),
		"contracted_service_coop_bonus_cents": service_coop_bonus_cents,
		"contracted_premium_cents": premium_cents,
		"premium_cents": premium_cents,
		"authored_breach_cents": authored_breach_cents,
		"season_breach_basis_points": season_breach_basis_points,
		"season_breach_delta_cents": season_breach_delta_cents,
		"clause_breach_basis_points": clause_breach_basis_points,
		"clause_breach_delta_cents": clause_breach_delta_cents,
		"contracted_breach_cents": breach_cents,
		"breach_cents": breach_cents,
		"welfare_gate_minimum": welfare_gate_minimum,
		"welfare_gate_required": welfare_gate_minimum > 0,
		"authored_dominant_lane": String(authored_dominant_lane),
		"authored_lane_mix": authored_lane_mix,
		"lane_mix": lane_mix,
		"lane_mix_label": _contract_lane_mix_label(lane_mix),
		"rush_lane_mix": rush_lane_mix,
		"rush_lane_mix_label": _contract_lane_mix_label(rush_lane_mix),
		"arrival_batches": arrival_batches,
		"scheduled_claims": scheduled_claims,
		"arrival_schedule": "\n".join(arrival_lines),
		"success_required": success_required,
		"benefit": "+$%.2f closing premium on fulfillment ($%.2f market + $%.2f Service Coop)" % [
			float(premium_cents) / 100.0,
			float(market_premium_cents) / 100.0,
			float(service_coop_bonus_cents) / 100.0,
		],
		"tradeoff": "-$%.2f breach charge if the signed requirements are missed" % (
			float(breach_cents) / 100.0
		),
	}


func _market_contract_dominant_lane(definition: Dictionary) -> StringName:
	var authored_counts: Dictionary = {}
	for batch_value in definition.get("arrival_batches", []):
		var batch := batch_value as Dictionary
		for lane_value in batch.get("lanes", []):
			var lane := StringName(String(lane_value))
			if lane in DepartmentSimulation.CLAIM_LANES:
				authored_counts[lane] = int(authored_counts.get(lane, 0)) + 1
	var dominant_lane: StringName = DepartmentSimulation.CLAIM_LANES[0]
	var dominant_count := -1
	for lane in DepartmentSimulation.CLAIM_LANES:
		var count := int(authored_counts.get(lane, 0))
		if count > dominant_count:
			dominant_count = count
			dominant_lane = lane
	return dominant_lane


func _contract_lane_mix(lanes: Array[String]) -> Dictionary:
	var mix: Dictionary = {}
	for lane in lanes:
		mix[lane] = int(mix.get(lane, 0)) + 1
	return mix


func _contract_lane_mix_label(mix: Dictionary) -> String:
	var parts: Array[String] = []
	for lane in DepartmentSimulation.CLAIM_LANES:
		var count := int(mix.get(String(lane), mix.get(lane, 0)))
		if count <= 0:
			continue
		parts.append("%s %d" % [String((DepartmentSimulation.CLAIM_LANE_DEFINITIONS[lane] as Dictionary)["short_name"]), count])
	return "  ·  ".join(parts) if not parts.is_empty() else "NO FOLDERS"


func _pending_market_contract_claim_count() -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if sim.active_market_contract.is_empty() or int(sim.active_market_contract.get("target_day", 0)) != sim.day:
		return 0
	var count := 0
	for scheduled_value in sim.active_market_contract.get("scheduled_claims", []):
		var scheduled := scheduled_value as Dictionary
		if not bool(scheduled.get("released", false)) and not bool(scheduled.get("rejected", false)):
			count += 1
	return count


func _release_due_market_contract_claims() -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if sim.active_market_contract.is_empty() or int(sim.active_market_contract.get("target_day", 0)) != sim.day:
		return 0
	var scheduled_claims := sim.active_market_contract.get("scheduled_claims", []) as Array
	var accepted_ids := sim.active_market_contract.get("accepted_claim_ids", []) as Array
	var rejected_ids := sim.active_market_contract.get("rejected_claim_ids", []) as Array
	var released_count := 0
	var released_batches: Dictionary = {}
	for schedule_value in scheduled_claims:
		var schedule := schedule_value as Dictionary
		if (
			bool(schedule.get("released", false))
			or bool(schedule.get("rejected", false))
			or int(schedule.get("arrival_minute_of_day", DepartmentSimulation.SHIFT_END_MINUTE + 1)) > sim.minute_of_day
		):
			continue
		var claim_id := int(schedule.get("claim_id", -1))
		var lane := StringName(String(schedule.get("lane", "")))
		if claim_id < 1 or lane not in DepartmentSimulation.CLAIM_LANES:
			schedule["rejected"] = true
			rejected_ids.append(claim_id)
			continue
		if sim._outstanding_claim_count() >= sim.current_claim_capacity():
			# This should be unreachable because pending contract folders reserve
			# capacity from ambient intake. Retain an explicit breach ledger instead
			# of laundering the failure into ordinary missed-intake value.
			schedule["rejected"] = true
			rejected_ids.append(claim_id)
			continue
		var definition := DepartmentSimulation.CLAIM_LANE_DEFINITIONS[lane] as Dictionary
		var arrival_minute_of_day := int(schedule.get("arrival_minute_of_day", sim.minute_of_day))
		var deadline_minute_of_day := int(schedule.get("deadline_minute_of_day", DepartmentSimulation.SHIFT_END_MINUTE))
		var operational_start := sim._operational_minute_for_shift_start(sim.day)
		var arrival_operational := operational_start + arrival_minute_of_day - DepartmentSimulation.SHIFT_START_MINUTE
		var deadline_operational := operational_start + deadline_minute_of_day - DepartmentSimulation.SHIFT_START_MINUTE
		var claim := ClaimState.new(
			claim_id,
			lane,
			"FARM MUTUAL · %s" % String(definition.get("display_name", "PECKWORK")),
			float(definition.get("base_difficulty", 1.0)),
			int(definition.get("base_value_cents", 0)),
			float(definition.get("crack_modifier", 0.0)),
			arrival_operational,
			deadline_operational,
			maxi(1, deadline_operational - arrival_operational),
			false,
			-1,
			sim.day,
			0,
		)
		sim._append_claim_to_queue(claim)
		schedule["released"] = true
		accepted_ids.append(claim_id)
		released_batches[int(schedule.get("batch_index", 0))] = true
		released_count += 1
	sim.active_market_contract["scheduled_claims"] = scheduled_claims
	sim.active_market_contract["accepted_claim_ids"] = accepted_ids
	sim.active_market_contract["rejected_claim_ids"] = rejected_ids
	var fully_released_batches := 0
	for batch_value in sim.active_market_contract.get("arrival_batches", []):
		var batch := batch_value as Dictionary
		var batch_index := int(batch.get("batch_index", -1))
		var batch_complete := true
		for schedule_value in scheduled_claims:
			var schedule := schedule_value as Dictionary
			if int(schedule.get("batch_index", -2)) != batch_index:
				continue
			if not bool(schedule.get("released", false)) and not bool(schedule.get("rejected", false)):
				batch_complete = false
				break
		if batch_complete:
			fully_released_batches += 1
	sim.active_market_contract["released_batch_count"] = fully_released_batches
	if released_count > 0:
		sim.active_market_contract["status"] = "active"
		sim.announcement_posted.emit(
			"FARM MUTUAL INTAKE: %d contracted folder%s arrived at %s without pausing production." % [
				released_count,
				"" if released_count == 1 else "s",
				sim._format_time(sim.minute_of_day),
			]
		)
	return released_count


func _record_market_contract_completion(claim: ClaimState, quality: StringName) -> void:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if claim == null or sim.active_market_contract.is_empty():
		return
	if int(sim.active_market_contract.get("target_day", 0)) != sim.day:
		return
	var accepted_ids := sim.active_market_contract.get("accepted_claim_ids", []) as Array
	var completed_ids := sim.active_market_contract.get("completed_claim_ids", []) as Array
	if claim.id not in accepted_ids or claim.id in completed_ids:
		return
	var schedule: Dictionary = {}
	for schedule_value in sim.active_market_contract.get("scheduled_claims", []):
		var candidate := schedule_value as Dictionary
		if int(candidate.get("claim_id", -1)) == claim.id:
			schedule = candidate
			break
	if schedule.is_empty():
		return
	var clean := quality in [&"sound", &"golden"]
	var on_time := sim.minute_of_day <= int(schedule.get("deadline_minute_of_day", DepartmentSimulation.SHIFT_END_MINUTE))
	completed_ids.append(claim.id)
	sim.active_market_contract["completed_claim_ids"] = completed_ids
	sim.active_market_contract["completed_count"] = completed_ids.size()
	if clean:
		var sound_ids := sim.active_market_contract.get("sound_completed_claim_ids", []) as Array
		sound_ids.append(claim.id)
		sim.active_market_contract["sound_completed_claim_ids"] = sound_ids
		sim.active_market_contract["sound_completed"] = sound_ids.size()
	else:
		var cracked_ids := sim.active_market_contract.get("cracked_claim_ids", []) as Array
		cracked_ids.append(claim.id)
		sim.active_market_contract["cracked_claim_ids"] = cracked_ids
		sim.active_market_contract["cracked_count"] = cracked_ids.size()
	if clean and on_time:
		var timely_ids := sim.active_market_contract.get("timely_sound_claim_ids", []) as Array
		timely_ids.append(claim.id)
		sim.active_market_contract["timely_sound_claim_ids"] = timely_ids
		sim.active_market_contract["timely_sound_completed"] = timely_ids.size()
		if bool(schedule.get("rush", false)):
			sim.active_market_contract["rush_completed_on_time"] = int(
				sim.active_market_contract.get("rush_completed_on_time", 0)
			) + 1
	else:
		var late_ids := sim.active_market_contract.get("late_claim_ids", []) as Array
		late_ids.append(claim.id)
		sim.active_market_contract["late_claim_ids"] = late_ids
		sim.active_market_contract["late_count"] = late_ids.size()
	var delivered := int(sim.active_market_contract.get("timely_sound_completed", 0))
	var required := int(sim.active_market_contract.get("required_completed", 0))
	sim.active_market_contract["remaining_required"] = maxi(0, required - delivered)
	if delivered == required:
		sim.announcement_posted.emit(
			"FARM MUTUAL THRESHOLD MET: %d clean folders arrived on time; the premium is pending close." % required
		)
	elif bool(schedule.get("rush", false)) and not (clean and on_time):
		sim.announcement_posted.emit(
			"CONTRACT RUSH MISSED: folder #%04d was %s; Farm Mutual retained the breach clause." % [
				claim.id,
				("cracked" if not clean else "late"),
			]
		)


func _settle_market_contract(completed_day: int) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if (
		sim.active_market_contract.is_empty()
		or int(sim.active_market_contract.get("target_day", 0)) != completed_day
	):
		return {}
	_finalize_market_contract_schedule_evidence()
	var completed_contract := sim.active_market_contract.duplicate(true)
	var delivered := int(completed_contract.get("timely_sound_completed", 0))
	var required := int(completed_contract.get("required_completed", 0))
	var closing_welfare := sim._flock_welfare_score()
	var welfare_gate_minimum := int(completed_contract.get("welfare_gate_minimum", 0))
	var delivery_threshold_met := delivered >= required
	var welfare_gate_met := welfare_gate_minimum <= 0 or closing_welfare >= welfare_gate_minimum
	var success := delivery_threshold_met and welfare_gate_met
	var base_premium_cents := int(completed_contract.get("base_premium_cents", 0))
	var contracted_service_bonus_cents := int(completed_contract.get("service_coop_bonus_cents", 0))
	var contracted_premium_cents := int(completed_contract.get("premium_cents", 0))
	var contracted_breach_cents := int(completed_contract.get("breach_cents", 0))
	var premium_cents := contracted_premium_cents if success else 0
	var service_coop_bonus_cents := contracted_service_bonus_cents if success else 0
	var breach_cents := contracted_breach_cents if not success else 0
	var fund_before := sim.revenue_cents
	var standing_before := sim.farm_mutual_standing()
	var reach_before := market_reach_points()
	var satisfaction_before := sim.claimant_satisfaction_score()
	var clean_streak_before := sim.market_clean_contract_streak
	if success:
		sim.revenue_cents += premium_cents
		sim.credited_today_cents += premium_cents
		sim.market_contract_premium_today_cents += premium_cents
		sim.market_contract_premium_total_cents += premium_cents
		sim.market_contracts_succeeded_total += 1
		sim.market_clean_contract_streak += 1
		sim.best_market_clean_contract_streak = maxi(
			sim.best_market_clean_contract_streak,
			sim.market_clean_contract_streak,
		)
	else:
		# The full authored clause was reserved at signing and protected from every
		# discretionary debit thereafter. Settlement therefore remains an exact
		# integer-cent sink instead of quietly converting insolvency into a discount.
		if sim.revenue_cents < breach_cents:
			push_error("Farm Mutual breach reserve invariant failed before settlement.")
		sim.revenue_cents = maxi(0, sim.revenue_cents - breach_cents)
		sim.market_contract_breach_today_cents += breach_cents
		sim.market_contract_breach_total_cents += breach_cents
		sim.market_contracts_breached_total += 1
		sim.market_clean_contract_streak = 0
	var pricing_id := StringName(completed_contract.get("pricing_profile_id", &"mutual_rate"))
	var pricing_outcome_key := "%s_%s" % [
		String(pricing_id),
		"success" if success else "breach",
	]
	sim.market_pricing_outcomes[pricing_outcome_key] = (
		int(sim.market_pricing_outcomes.get(pricing_outcome_key, 0)) + 1
	)
	var standing_after := sim.farm_mutual_standing()
	var reach_after := market_reach_points()
	var satisfaction_after := sim.claimant_satisfaction_score()
	var settlement_outcome := ""
	if success:
		settlement_outcome = "%s fulfilled: Farm Mutual credited a $%.2f premium after the flock delivered %d/%d clean folders on time." % [
			String(completed_contract.get("short_name", "Contract")),
			float(premium_cents) / 100.0,
			delivered,
			required,
		]
	elif delivery_threshold_met and not welfare_gate_met:
		settlement_outcome = "%s breached: its rested-flock welfare safeguard failed at %d/%d despite %d/%d clean folders arriving on time; Farm Mutual charged $%.2f." % [
			String(completed_contract.get("short_name", "Contract")),
			closing_welfare,
			welfare_gate_minimum,
			delivered,
			required,
			float(breach_cents) / 100.0,
		]
	else:
		settlement_outcome = "%s breached: Farm Mutual charged $%.2f after only %d/%d clean folders arrived on time." % [
			String(completed_contract.get("short_name", "Contract")),
			float(breach_cents) / 100.0,
			delivered,
			required,
		]
	var result := {
		"version": 2,
		"contract_id": String(completed_contract.get("contract_id", "")),
		"offer_id": String(completed_contract.get("offer_id", "")),
		"name": String(completed_contract.get("name", "FARM MUTUAL BINDER")),
		"short_name": String(completed_contract.get("short_name", "MUTUAL BINDER")),
		"client": String(completed_contract.get("client", "FARM MUTUAL")),
		"day": completed_day,
		"target_day": completed_day,
		"status": "fulfilled" if success else "breached",
		"success": success,
		"delivery_threshold_met": delivery_threshold_met,
		"welfare_gate_met": welfare_gate_met,
		"closing_welfare": closing_welfare,
		"welfare_gate_minimum": welfare_gate_minimum,
		"welfare_gate_required": welfare_gate_minimum > 0,
		"required_completed": required,
		"timely_sound_completed": delivered,
		"sound_completed": int(completed_contract.get("sound_completed", 0)),
		"completed_count": int(completed_contract.get("completed_count", 0)),
		"total_claims": int(completed_contract.get("total_claims", 0)),
		"rush_claims": int(completed_contract.get("rush_claims", 0)),
		"rush_completed_on_time": int(completed_contract.get("rush_completed_on_time", 0)),
		"cracked_count": int(completed_contract.get("cracked_count", 0)),
		"late_count": int(completed_contract.get("late_count", 0)),
		"rejected_count": (completed_contract.get("rejected_claim_ids", []) as Array).size(),
		"required_active_staff": int(completed_contract.get("required_active_staff", 0)),
		"legacy_terms_grandfathered": bool(
			completed_contract.get("legacy_terms_grandfathered", false)
		),
		"season": (completed_contract.get("season", {}) as Dictionary).duplicate(true),
		"season_id": completed_contract.get("season_id", &"baseline_neutral"),
		"season_label": String(completed_contract.get("season_label", "BASELINE NEUTRAL BOOK")),
		"season_demand_basis_points": int(
			completed_contract.get("season_demand_basis_points", 0)
		),
		"clause_id": completed_contract.get("clause_id", &"standard_terms"),
		"clause_label": String(completed_contract.get("clause_label", "STANDARD TERMS")),
		"clause_summary": String(completed_contract.get("clause_summary", "")),
		"clause_category": completed_contract.get("clause_category", &"standard"),
		"pricing_profile_id": pricing_id,
		"pricing_label": String(completed_contract.get("pricing_label", "MUTUAL RATE")),
		"pricing_summary": String(completed_contract.get("pricing_summary", "")),
		"negotiation_room_level_at_signing": int(
			completed_contract.get("negotiation_room_level_at_signing", 0)
		),
		"authored_service_window_minutes": int(
			completed_contract.get("authored_service_window_minutes", 0)
		),
		"service_window_minutes": int(completed_contract.get("service_window_minutes", 0)),
		"authored_dominant_lane": String(
			completed_contract.get("authored_dominant_lane", "")
		),
		"authored_lane_mix": (
			completed_contract.get("authored_lane_mix", {}) as Dictionary
		).duplicate(true),
		"lane_mix": (completed_contract.get("lane_mix", {}) as Dictionary).duplicate(true),
		"arrival_batches": (
			completed_contract.get("arrival_batches", []) as Array
		).duplicate(true),
		"scheduled_claims": (
			completed_contract.get("scheduled_claims", []) as Array
		).duplicate(true),
		"claim_ids": (
			completed_contract.get("claim_ids", []) as Array
		).duplicate(),
		"accepted_claim_ids": (
			completed_contract.get("accepted_claim_ids", []) as Array
		).duplicate(),
		"rejected_claim_ids": (
			completed_contract.get("rejected_claim_ids", []) as Array
		).duplicate(),
		"authored_base_premium_cents": int(
			completed_contract.get("authored_base_premium_cents", base_premium_cents)
		),
		"base_premium_cents": base_premium_cents,
		"season_premium_delta_cents": int(
			completed_contract.get("season_premium_delta_cents", 0)
		),
		"clause_premium_basis_points": int(
			completed_contract.get("clause_premium_basis_points", 0)
		),
		"clause_premium_delta_cents": int(
			completed_contract.get("clause_premium_delta_cents", 0)
		),
		"pricing_premium_basis_points": int(
			completed_contract.get("pricing_premium_basis_points", 0)
		),
		"pricing_premium_delta_cents": int(
			completed_contract.get("pricing_premium_delta_cents", 0)
		),
		"pricing_volume_delta": int(completed_contract.get("pricing_volume_delta", 0)),
		"pricing_required_delta": int(completed_contract.get("pricing_required_delta", 0)),
		"pricing_required_reach": int(completed_contract.get("pricing_required_reach", 0)),
		"claimant_satisfaction_success_delta": int(
			completed_contract.get("claimant_satisfaction_success_delta", 0)
		),
		"claimant_satisfaction_breach_delta": int(
			completed_contract.get("claimant_satisfaction_breach_delta", 0)
		),
		"market_reach_success_delta": int(
			completed_contract.get("market_reach_success_delta", 0)
		),
		"market_reach_breach_delta": int(
			completed_contract.get("market_reach_breach_delta", 0)
		),
		"estimated_handling_cost_cents": int(
			completed_contract.get("estimated_handling_cost_cents", 0)
		),
		"estimated_margin_cents": int(completed_contract.get("estimated_margin_cents", 0)),
		"estimated_margin_per_file_cents": int(
			completed_contract.get("estimated_margin_per_file_cents", 0)
		),
		"market_premium_cents": int(
			completed_contract.get("market_premium_cents", base_premium_cents)
		),
		"service_coop_level_at_signing": int(completed_contract.get("service_coop_level_at_signing", 0)),
		"service_coop_bonus_cents": service_coop_bonus_cents,
		"contracted_service_coop_bonus_cents": contracted_service_bonus_cents,
		"premium_bonus_basis_points": int(completed_contract.get("premium_bonus_basis_points", 0)),
		"contracted_premium_cents": contracted_premium_cents,
		"premium_cents": premium_cents,
		"authored_breach_cents": int(
			completed_contract.get("authored_breach_cents", contracted_breach_cents)
		),
		"season_breach_basis_points": int(
			completed_contract.get("season_breach_basis_points", 0)
		),
		"season_breach_delta_cents": int(
			completed_contract.get("season_breach_delta_cents", 0)
		),
		"clause_breach_basis_points": int(
			completed_contract.get("clause_breach_basis_points", 0)
		),
		"clause_breach_delta_cents": int(
			completed_contract.get("clause_breach_delta_cents", 0)
		),
		"contracted_breach_cents": contracted_breach_cents,
		"breach_cents": breach_cents,
		"net_contract_cents": premium_cents - breach_cents,
		"fund_before_cents": fund_before,
		"fund_after_cents": sim.revenue_cents,
		"market_standing_before": standing_before,
		"market_standing_after": standing_after,
		"market_standing_delta": standing_after - standing_before,
		"market_standing_rank": sim.farm_mutual_standing_rank(),
		"market_reach_before": reach_before,
		"market_reach_after": reach_after,
		"market_reach_delta": reach_after - reach_before,
		"market_share_basis_points": mutual_market_share_basis_points(),
		"claimant_satisfaction_before": satisfaction_before,
		"claimant_satisfaction_after": satisfaction_after,
		"claimant_satisfaction_delta": satisfaction_after - satisfaction_before,
		"clean_contract_streak_before": clean_streak_before,
		"clean_contract_streak_after": sim.market_clean_contract_streak,
		"best_clean_contract_streak": sim.best_market_clean_contract_streak,
		"outcome": settlement_outcome,
	}
	sim.last_market_contract_result = result.duplicate(true)
	sim.active_market_contract.clear()
	sim.announcement_posted.emit(String(result["outcome"]))
	sim.market_contract_settled.emit(result.duplicate(true))
	return result


func _finalize_market_contract_schedule_evidence() -> void:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	## Settlement is terminal. Any authored folder that never entered intake becomes
	## an explicit rejection instead of leaving an ambiguous third schedule state.
	var schedules := sim.active_market_contract.get("scheduled_claims", []) as Array
	var rejected_ids := sim.active_market_contract.get("rejected_claim_ids", []) as Array
	for index in schedules.size():
		var schedule := (schedules[index] as Dictionary).duplicate(true)
		if not bool(schedule.get("released", false)) and not bool(schedule.get("rejected", false)):
			var claim_id := int(schedule.get("claim_id", -1))
			schedule["rejected"] = true
			if claim_id > 0 and claim_id not in rejected_ids:
				rejected_ids.append(claim_id)
		schedules[index] = schedule
	sim.active_market_contract["scheduled_claims"] = schedules
	sim.active_market_contract["rejected_claim_ids"] = rejected_ids


func current_market_contract_reserve_cents() -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	## A signed binder never charges its breach clause up front. The possible
	## charge is nevertheless protected from discretionary spending until the
	## target shift settles, so failure cannot create money or erase payroll.
	if sim.active_market_contract.is_empty():
		return 0
	if int(sim.active_market_contract.get("target_day", 0)) != sim.day:
		return 0
	return maxi(0, int(sim.active_market_contract.get("breach_cents", 0)))


func _apply_market_contract_claim_snapshot(claim_snapshot: Dictionary) -> void:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if claim_snapshot.is_empty() or sim.active_market_contract.is_empty():
		return
	var claim_id := int(claim_snapshot.get("id", -1))
	if claim_id not in (sim.active_market_contract.get("accepted_claim_ids", []) as Array):
		return
	var schedule: Dictionary = {}
	for schedule_value in sim.active_market_contract.get("scheduled_claims", []):
		var candidate := schedule_value as Dictionary
		if int(candidate.get("claim_id", -1)) == claim_id:
			schedule = candidate
			break
	claim_snapshot["market_contract"] = true
	claim_snapshot["market_contract_id"] = String(sim.active_market_contract.get("contract_id", ""))
	claim_snapshot["market_contract_offer_id"] = String(sim.active_market_contract.get("offer_id", ""))
	claim_snapshot["market_contract_name"] = String(sim.active_market_contract.get("short_name", "MUTUAL BINDER"))
	claim_snapshot["market_contract_rush"] = bool(schedule.get("rush", false))
	claim_snapshot["market_contract_deadline_time"] = String(schedule.get("deadline_time", "5:00 PM"))
