extends SceneTree


const WELLNESS := DepartmentSimulation.WELLNESS_NEST_ID
const TRAINING := DepartmentSimulation.TRAINING_ROOST_ID
const WELLNESS_COSTS: Array[int] = [7000, 11500, 17500]
const WELLNESS_UPKEEP: Array[int] = [500, 900, 1400]
const WELLNESS_DAYS: Array[int] = [3, 6, 9]
const TRAINING_COSTS: Array[int] = [8500, 13500, 21000]
const TRAINING_UPKEEP: Array[int] = [600, 1000, 1600]
const TRAINING_DAYS: Array[int] = [4, 7, 10]
const STRAIN_BP: Array[int] = [10000, 9200, 8400, 7600]
const BREAK_BP: Array[int] = [10000, 11500, 13000, 15000]
const SPONSORSHIP_COSTS: Array[int] = [1200, 1000, 800, 600]
const TRAINING_BP: Array[int] = [8500, 9000, 9500, 10000]
const COACHING_BONUS: Array[int] = [0, 2, 4, 6]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_test_wellness_tiers_and_gates(failures)
	_test_training_tiers_and_gates(failures)
	_test_real_wellness_state_changes(failures)
	_test_training_terms_and_career_actions(failures)
	_test_authoritative_flock_care_snapshot(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("WELLNESS_TRAINING_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("WELLNESS_TRAINING_ECONOMY_TEST_PASSED tiers=3+3 gates=deterministic care=real training=derived quota=+1")
	quit(0)


func _test_wellness_tiers_and_gates(failures: Array[String]) -> void:
	var early := _review_fixture(15101, 4, 2)
	_check(not bool(early.facility_status(WELLNESS).get("can_purchase", true)), "Wellness tier 1 must wait until Day 3", failures)

	var desk_short := _review_fixture(15102, 3, 3)
	var desk_status := desk_short.facility_status(WELLNESS)
	_check(int(desk_status.get("required_office_capacity", 0)) == 4, "Wellness tier 1 should require four authorized desks", failures)
	_check(int(desk_status.get("office_capacity_shortfall", 0)) == 1, "Wellness should disclose the exact desk shortfall", failures)

	var active_short := _review_fixture(15103, 4, 3)
	active_short.workers[3].employed = false
	var active_status := active_short.facility_status(WELLNESS)
	_check(int(active_status.get("active_staff_shortfall", 0)) == 1, "Wellness should require four active hens at tier 1", failures)

	var one_cent_short := _review_fixture(15104, 4, 3)
	one_cent_short.revenue_cents = (
		one_cent_short.current_daily_operating_cost_cents()
		+ WELLNESS_COSTS[0]
		+ WELLNESS_UPKEEP[0]
		- 1
	)
	_expect_purchase_rejected_atomically(one_cent_short, WELLNESS, "one-cent-short Wellness purchase", failures)

	var simulation := _review_fixture(15105, 6, WELLNESS_DAYS[0])
	var opening_fund := simulation.revenue_cents
	var opening_quota := simulation.quota_target
	var capital_spent := 0
	for index in 3:
		simulation.day = WELLNESS_DAYS[index]
		var status := simulation.facility_status(WELLNESS)
		_check(int(status.get("next_level", 0)) == index + 1, "Wellness should quote the next cumulative tier", failures)
		_check(int(status.get("cost_cents", -1)) == WELLNESS_COSTS[index], "Wellness tier %d should quote exact capital" % (index + 1), failures)
		_check(int(status.get("next_maintenance_cents", -1)) == WELLNESS_UPKEEP[index], "Wellness tier %d should quote total upkeep" % (index + 1), failures)
		_check(bool(status.get("can_purchase", false)), "funded Wellness tier %d should pass all gates" % (index + 1), failures)
		var before_quota := simulation.quota_target
		var receipt := simulation.purchase_facility(WELLNESS)
		capital_spent += WELLNESS_COSTS[index]
		_check(bool(receipt.get("accepted", false)), "Wellness tier %d should purchase" % (index + 1), failures)
		_check(int(receipt.get("next_shift_quota_before", -1)) == before_quota, "Wellness receipt should retain quota before", failures)
		_check(int(receipt.get("next_shift_quota_delta", 0)) == 1, "each Wellness tier should add exactly one next-shift file", failures)
		_check(simulation.quota_target == before_quota + 1, "Wellness quota tradeoff should mutate exactly once", failures)
		_check(simulation.current_daily_facility_maintenance_cents() == WELLNESS_UPKEEP[index], "Wellness upkeep should use the cumulative tier total", failures)
	_check(simulation.facility_level(WELLNESS) == 3, "Wellness should finish at tier 3", failures)
	_check(simulation.revenue_cents == opening_fund - capital_spent, "Wellness should debit each capital price exactly once", failures)
	_check(simulation.quota_target == opening_quota + 3, "three Wellness tiers should add exactly three quota files", failures)
	_expect_purchase_rejected_atomically(simulation, WELLNESS, "maxed Wellness purchase", failures)


func _test_training_tiers_and_gates(failures: Array[String]) -> void:
	var dependency := _review_fixture(15201, 4, TRAINING_DAYS[0])
	dependency.workers[0].career_xp = 18
	var dependency_status := dependency.facility_status(TRAINING)
	_check(int(dependency_status.get("required_wellness_nest_level", 0)) == 1, "Training tier 1 should require Wellness tier 1", failures)
	_check(int(dependency_status.get("wellness_nest_level_shortfall", 0)) == 1, "Training should disclose the matching Wellness shortfall", failures)
	_check(not bool(dependency_status.get("can_purchase", true)), "Training must not bypass its Wellness dependency", failures)

	var qualification := _review_fixture(15202, 4, TRAINING_DAYS[0])
	qualification.owned_facilities[WELLNESS] = 1
	var qualification_status := qualification.facility_status(TRAINING)
	_check(int(qualification_status.get("required_career_level", 0)) == 1, "Training tier 1 should require an Accredited Layer", failures)
	_check(int(qualification_status.get("qualification_shortfall", 0)) == 1, "Training should disclose missing career qualification", failures)

	var simulation := _review_fixture(15203, 6, TRAINING_DAYS[0])
	simulation.workers[0].career_xp = 80
	var opening_fund := simulation.revenue_cents
	var capital_spent := 0
	for index in 3:
		simulation.day = TRAINING_DAYS[index]
		simulation.owned_facilities[WELLNESS] = index + 1
		var status := simulation.facility_status(TRAINING)
		_check(int(status.get("required_wellness_nest_level", 0)) == index + 1, "Training tier %d should require matching Wellness" % (index + 1), failures)
		_check(int(status.get("required_career_level", 0)) == index + 1, "Training tier %d should require career level %d" % [index + 1, index + 1], failures)
		_check(int(status.get("cost_cents", -1)) == TRAINING_COSTS[index], "Training tier %d should quote exact capital" % (index + 1), failures)
		_check(int(status.get("next_maintenance_cents", -1)) == TRAINING_UPKEEP[index], "Training tier %d should quote total upkeep" % (index + 1), failures)
		_check(bool(status.get("can_purchase", false)), "funded Training tier %d should pass all gates" % (index + 1), failures)
		var wage_before := simulation.workers[0].daily_wage_cents()
		var receipt := simulation.purchase_facility(TRAINING)
		capital_spent += TRAINING_COSTS[index]
		_check(bool(receipt.get("accepted", false)), "Training tier %d should purchase" % (index + 1), failures)
		_check(simulation.workers[0].daily_wage_cents() == wage_before, "facility purchase itself must not invent a wage stipend", failures)
		_check(simulation.current_daily_facility_maintenance_cents() == WELLNESS_UPKEEP[index] + TRAINING_UPKEEP[index], "combined upkeep should include exact cumulative care totals", failures)
	_check(simulation.revenue_cents == opening_fund - capital_spent, "Training should debit each capital price exactly once", failures)


func _test_real_wellness_state_changes(failures: Array[String]) -> void:
	for level in 4:
		var simulation := DepartmentSimulation.new(15300 + level, 4)
		simulation.owned_facilities[WELLNESS] = level
		var effects := simulation.facility_effects()
		_check(int(effects.get("wellness_strain_gain_basis_points", -1)) == STRAIN_BP[level], "Wellness strain schedule should be exact at level %d" % level, failures)
		_check(int(effects.get("wellness_break_recovery_basis_points", -1)) == BREAK_BP[level], "Wellness break schedule should be exact at level %d" % level, failures)
		_check(is_equal_approx(float(effects.get("crack_modifier", 99.0)), 0.0), "Wellness must not add a flat crack modifier", failures)

	var baseline := _working_fixture(15310, 0)
	var improved := _working_fixture(15310, 3)
	baseline._update_worker(baseline.workers[0])
	improved._update_worker(improved.workers[0])
	_check(_approximately(baseline.workers[0].fatigue, 10.36), "baseline work should retain exact fatigue gain", failures)
	_check(_approximately(improved.workers[0].fatigue, 10.0 + 0.36 * 0.76), "Wellness should multiply real fatigue gain once", failures)
	_check(_approximately(improved.workers[0].stress, 10.0 + 0.20 * 0.76), "Wellness should multiply real stress gain once", failures)

	var breaking := DepartmentSimulation.new(15311, 4)
	breaking.owned_facilities[WELLNESS] = 3
	var break_worker := breaking.workers[0]
	break_worker.work_state = ChickenState.WorkState.BREAK
	break_worker.state_ticks_remaining = 5
	break_worker.fatigue = 50.0
	break_worker.stress = 50.0
	break_worker.morale = 50.0
	breaking._update_worker(break_worker)
	_check(_approximately(break_worker.fatigue, 47.0), "Wellness tier 3 should recover exactly 3 fatigue per break tick", failures)
	_check(_approximately(break_worker.stress, 47.9), "Wellness tier 3 should recover exactly 2.1 stress per break tick", failures)
	_check(_approximately(break_worker.morale, 50.25), "Wellness tier 3 should add exactly 0.25 morale per break tick", failures)

	break_worker.fatigue = 50.0
	break_worker.stress = 50.0
	breaking._apply_overnight_recovery(break_worker)
	_check(_approximately(break_worker.fatigue, 16.0), "Wellness tier 3 overnight recovery should remove exactly 34 fatigue", failures)
	_check(_approximately(break_worker.stress, 33.0), "Wellness tier 3 overnight recovery should remove exactly 17 stress", failures)

	var same_state_a := DepartmentSimulation.new(15312, 4)
	var same_state_b := DepartmentSimulation.new(15312, 4)
	same_state_b.owned_facilities[WELLNESS] = 3
	_check(same_state_a.flock_welfare_score() == same_state_b.flock_welfare_score(), "owning Wellness must not fabricate a flat Rested Flock welfare bonus", failures)


func _test_training_terms_and_career_actions(failures: Array[String]) -> void:
	for level in 4:
		var simulation := _review_fixture(15400 + level, 4, 10)
		simulation.owned_facilities[WELLNESS] = level
		simulation.owned_facilities[TRAINING] = level
		simulation.workers[0].career_xp = 18
		var effects := simulation.facility_effects()
		_check(int(effects.get("career_sponsorship_cost_cents", -1)) == SPONSORSHIP_COSTS[level], "sponsorship cost schedule should be exact at level %d" % level, failures)
		_check(int(effects.get("cross_training_work_basis_points", -1)) == TRAINING_BP[level], "pending-training work schedule should be exact at level %d" % level, failures)
		_check(int(effects.get("career_coaching_xp_bonus", -1)) == COACHING_BONUS[level], "coaching XP schedule should be exact at level %d" % level, failures)
		var preflight := simulation.career_sponsorship_preflight(0, &"predator_loss")
		_check(int(preflight.get("cost_cents", -1)) == SPONSORSHIP_COSTS[level], "preflight and facility effect must share one sponsorship cost", failures)
		_check(int(preflight.get("training_work_basis_points", -1)) == TRAINING_BP[level], "preflight should publish the effective training pace", failures)

	var baseline := _training_work_fixture(15410, 0)
	var trained := _training_work_fixture(15410, 3)
	baseline._update_worker(baseline.workers[0])
	trained._update_worker(trained.workers[0])
	_check(baseline.workers[0].work_progress > 0.0, "pending-training baseline should perform real work", failures)
	_check(_approximately(trained.workers[0].work_progress / baseline.workers[0].work_progress, 1.0 / 0.85), "Training tier 3 should remove only the pending-training penalty", failures)

	var preferred := DepartmentSimulation.new(15411, 4)
	preferred.owned_facilities[WELLNESS] = 3
	preferred.owned_facilities[TRAINING] = 3
	preferred.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	preferred.revenue_cents = 100_000
	var preferred_before := preferred.workers[1].career_xp
	var preferred_receipt := preferred.perform_personnel_action(1, &"career_coaching")
	_check(bool(preferred_receipt.get("accepted", false)), "preferred coaching should remain available", failures)
	_check(preferred.workers[1].career_xp - preferred_before == 28, "tier-3 preferred coaching should award exactly 28 XP", failures)

	var nonpreferred := DepartmentSimulation.new(15412, 4)
	nonpreferred.owned_facilities[WELLNESS] = 3
	nonpreferred.owned_facilities[TRAINING] = 3
	nonpreferred.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	nonpreferred.revenue_cents = 100_000
	var nonpreferred_before := nonpreferred.workers[0].career_xp
	var nonpreferred_receipt := nonpreferred.perform_personnel_action(0, &"career_coaching")
	_check(bool(nonpreferred_receipt.get("accepted", false)), "nonpreferred coaching should remain available", failures)
	_check(nonpreferred.workers[0].career_xp - nonpreferred_before == 24, "tier-3 nonpreferred coaching should award exactly 24 XP", failures)


func _test_authoritative_flock_care_snapshot(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(15501, 4)
	simulation.owned_facilities[WELLNESS] = 3
	simulation.owned_facilities[TRAINING] = 3
	simulation.workers[0].work_state = ChickenState.WorkState.BREAK
	simulation.workers[1].career_xp = 18
	_check(simulation.workers[1].begin_cross_training(&"appeals"), "flock_care fixture should open one real pending training file", failures)
	var care := simulation.snapshot().get("flock_care", {}) as Dictionary
	for field in [
		"welfare", "rested_flock_gate", "welfare_delta_to_gate",
		"wellness_level", "training_roost_level", "breaks_active",
		"recovery_perch_count", "recovery_effects", "training_terms", "training_active",
		"wellness_nest", "training_roost", "next_care_action",
	]:
		_check(care.has(field), "flock_care should expose authoritative %s" % field, failures)
	_check(int(care.get("rested_flock_gate", 0)) == 72, "Rested Flock gate should remain exactly 72", failures)
	_check(int(care.get("breaks_active", 0)) == 1, "flock_care should count real employed breaks", failures)
	_check(int(care.get("training_active_count", 0)) == 1, "flock_care should count real pending training files", failures)
	_check((care.get("training_active", []) as Array).size() == 1, "flock_care should expose one concise pending training record", failures)
	_check(int(care.get("recovery_perch_count", 0)) == 6, "tier-3 Wellness should expose six recovery perches", failures)
	var recovery := care.get("recovery_effects", {}) as Dictionary
	_check(_approximately(float(recovery.get("overnight_fatigue_recovery_bonus", 0.0)), 10.0), "flock_care should expose the exact overnight fatigue bonus", failures)
	var training_terms := care.get("training_terms", {}) as Dictionary
	_check(int(training_terms.get("effective_sponsorship_cost_cents", -1)) == 600, "flock_care should expose the effective $6 sponsorship", failures)
	_check(int(training_terms.get("wage_bonus_cents", -1)) == 100, "flock_care should disclose the existing accreditation wage liability", failures)


func _review_fixture(seed: int, staff_count: int, target_day: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, staff_count)
	simulation.day = target_day
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 1_000_000
	return simulation


func _working_fixture(seed: int, wellness_level: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 4)
	simulation.owned_facilities[WELLNESS] = wellness_level
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	var worker := simulation.workers[0]
	worker.work_state = ChickenState.WorkState.WORKING
	worker.work_progress = 0.0
	worker.fatigue = 10.0
	worker.stress = 10.0
	worker.morale = 80.0
	simulation.set_worker_at_workstation(0, true)
	return simulation


func _training_work_fixture(seed: int, training_level: int) -> DepartmentSimulation:
	var simulation := _working_fixture(seed, training_level)
	simulation.owned_facilities[TRAINING] = training_level
	simulation.workers[0].career_xp = 18
	_check_without_record(simulation.workers[0].begin_cross_training(&"predator_loss"))
	return simulation


func _expect_purchase_rejected_atomically(
	simulation: DepartmentSimulation,
	facility_id: StringName,
	label: String,
	failures: Array[String],
) -> void:
	var before := JSON.stringify(simulation.export_save_state())
	var result := simulation.purchase_facility(facility_id)
	var after := JSON.stringify(simulation.export_save_state())
	_check(not bool(result.get("accepted", false)), "%s should reject" % label, failures)
	_check(after == before, "%s should not mutate authoritative state" % label, failures)


func _check_without_record(condition: bool) -> void:
	if not condition:
		push_error("WELLNESS_TRAINING_ECONOMY_TEST fixture setup failed")


func _approximately(actual: float, expected: float, tolerance: float = 0.0001) -> bool:
	return absf(actual - expected) <= tolerance


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
