extends SceneTree

var failures: Array[String] = []
const OFFER := &"homestead_stability_binder"

func check(ok: bool, reason: String) -> void:
	if not ok: failures.append(reason)

func _init() -> void:
	var sim := DepartmentSimulation.new(20261114, 4)
	sim.day = 5
	sim.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	sim.pending_decision.clear()
	sim.revenue_cents = 100000
	sim.cost_probe.enabled = true
	var saved := JSON.stringify(sim.export_save_state())
	# Compare every authored combination to the original builder, including
	# seasonal transitions and different facility levels. No gameplay authority
	# uses the uncached builder directly except this equivalence test.
	for target_day in [3, 5, 10, 31]:
		for level in [0, 3]:
			for offer in DepartmentSimulation.MARKET_CONTRACT_OFFER_ORDER:
				for clause in DepartmentSimulation.MARKET_CONTRACT_CLAUSE_ORDER:
					for pricing in DepartmentSimulation.MARKET_PRICING_PROFILE_ORDER:
						var cached := sim._market_contract_quote_for_day(offer, target_day, level, mini(level, 1), clause, false, pricing)
						var direct := sim._build_market_contract_quote_for_day(offer, target_day, level, mini(level, 1), clause, false, pricing)
						check(cached == direct, "Cached quote must exactly match authored schedules, pricing and gates")
	check(JSON.stringify(sim.export_save_state()) == saved, "Quote reads must not mutate career/save state")
	var first := sim.market_contract_offer_preflight(OFFER)
	var builds := int(sim.cost_probe.snapshot().stages.market_quote_build.count)
	for repeat in 10:
		check(sim.market_contract_offer_preflight(OFFER) == first, "Repeated preflights remain equivalent")
	check(int(sim.cost_probe.snapshot().stages.market_quote_build.count) == builds, "Unchanged terms must not rebuild schedules")
	first.scheduled_claims[0].lane = "tampered"
	first.arrival_batches[0].lanes.clear()
	first.clause_options[0].pricing_options[0].premium_cents = -1
	var intact := sim.market_contract_offer_preflight(OFFER)
	check(intact.scheduled_claims[0].lane != "tampered" and not intact.arrival_batches[0].lanes.is_empty(), "Returned nested schedules must be isolated")
	check(intact.clause_options[0].pricing_options[0].premium_cents >= 0, "Sibling option trees must be isolated")
	check(intact.can_sign, "Eligible review binder can be signed")
	check_catalog(sim)
	sim.revenue_cents = 0
	var poor := sim.market_contract_offer_preflight(OFFER)
	check(not poor.can_sign and poor.spendable_fund_cents != intact.spendable_fund_cents, "Current funds must bypass quote cache")
	check_catalog(sim)
	sim.revenue_cents = 100000
	sim.workers[0].employed = false
	var short_staff := sim.market_contract_offer_preflight(OFFER)
	check(not short_staff.can_sign and short_staff.active_staff_count == 3, "Current staffing must bypass quote cache")
	check_catalog(sim)
	sim.workers[0].employed = true
	sim.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	check(not sim.market_contract_offer_preflight(OFFER).can_sign, "Live shift must never inherit a planning permission")
	check_catalog(sim)
	sim.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	var locked := sim.market_contract_offer_preflight(OFFER, &"standard_terms", &"executive_select_rate")
	sim.market_pricing_outcomes["community_access_rate_success"] = 1
	var unlocked := sim.market_contract_offer_preflight(OFFER, &"standard_terms", &"executive_select_rate")
	check(not locked.pricing_available and unlocked.pricing_available, "Reach and satisfaction changes invalidate quoted availability")
	var neutral := sim._market_contract_quote_for_day(OFFER, 31, 0, 0, &"standard_terms", true)
	check(neutral == sim._build_market_contract_quote_for_day(OFFER, 31, 0, 0, &"standard_terms", true), "Legacy neutral quotes retain exact terms")
	for target_day in range(32, 80):
		sim._market_contract_quote_for_day(OFFER, target_day, 0, 0, &"standard_terms")
		check(sim._market_quote_cache.size() == 1, "Previous quote contexts must be evicted")
	for unknown in 40:
		sim._market_contract_quote_for_day(StringName("unknown_%d" % unknown), 79, 0, 0, &"standard_terms")
	check(sim._market_quote_cache.size() == 1, "Unknown inputs cannot grow the cache")
	var career := DepartmentSimulation.new(17, 4)
	career.select_directive(&"shell_assurance")
	var restored := DepartmentSimulation.new(11, 4)
	restored._market_contract_quote_for_day(OFFER, 79, 3, 1, &"standard_terms")
	check(restored.restore_save_state(JSON.parse_string(JSON.stringify(career.export_save_state()))), "Existing save restores without quote state")
	check(restored.market_contract_offer_preflight(OFFER) == career.market_contract_offer_preflight(OFFER), "Restored save computes its own exact eligibility")
	for failure in failures: push_error(failure)
	print("MARKET_QUOTE_CACHE_TEST_%s" % ("PASSED" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)

func check_catalog(sim: DepartmentSimulation) -> void:
	var individual: Array[Dictionary] = []
	for offer in DepartmentSimulation.MARKET_CONTRACT_OFFER_ORDER:
		individual.append(sim.market_contract_offer_preflight(offer))
	check(sim.market_contract_offer_catalog() == individual, "Shared live basis must match fresh independent preflights, including nested options")
