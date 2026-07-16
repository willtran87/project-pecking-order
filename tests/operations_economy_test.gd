extends SceneTree


const ROOSTER := DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID
const IT := DepartmentSimulation.IT_COOP_ID
const RECORDS := DepartmentSimulation.RECORDS_ANNEX_ID


func _init() -> void:
	var failures: Array[String] = []
	_test_catalog_gates_and_purchase_reserve(failures)
	_test_exact_tier_schedules(failures)
	_test_shift_pressure_and_personnel_capacity(failures)
	_test_promotion_wage_reserve_atomicity(failures)
	_test_multi_action_chronology_round_trip(failures)
	_test_supervisor_payroll_settlement(failures)
	_test_auto_routing_speed_and_presence(failures)
	_test_ledger_molt_authority(failures)
	_test_operations_snapshot_contract(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("OPERATIONS_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OPERATIONS_ECONOMY_TEST_PASSED tiers=exact reserve=payroll pressure=once actions=scaled auto=causal+seated snapshot=frozen")
	quit(0)


func _test_catalog_gates_and_purchase_reserve(failures: Array[String]) -> void:
	var locked := DepartmentSimulation.new(16001, 4)
	locked.day = 4
	locked.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	locked.pending_decision.clear()
	locked.revenue_cents = 1_000_000
	_check(locked.facility_catalog().size() == 13, "capital catalog should expose all thirteen authored facilities", failures)
	var locked_status := locked.facility_status(ROOSTER)
	_check(not bool(locked_status.get("unlocked", true)), "Rooster Office level one should remain locked before Day 5", failures)
	_check(int(locked_status.get("next_unlock_day", -1)) == 5, "Rooster Office level one should disclose its Day 5 gate", failures)

	var understaffed := DepartmentSimulation.new(16002, 3)
	understaffed.day = 5
	understaffed.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	understaffed.pending_decision.clear()
	understaffed.revenue_cents = 1_000_000
	var understaffed_status := understaffed.facility_status(ROOSTER)
	_check(int(understaffed_status.get("office_capacity_shortfall", 0)) == 1, "Rooster Office level one should require four authorized desks", failures)
	_check(int(understaffed_status.get("active_staff_shortfall", 0)) == 1, "Rooster Office level one should require four active hens", failures)
	_check(not bool(understaffed_status.get("can_purchase", true)), "an undersized office must not commission supervision", failures)

	var short := _review_fixture(16003, 4, 5)
	var quote := short.facility_status(ROOSTER)
	var required_fund := (
		short.current_daily_operating_cost_cents()
		+ int(quote.get("cost_cents", 0))
		+ int(quote.get("added_daily_operating_cents", 0))
	)
	short.revenue_cents = required_fund - 1
	var before := JSON.stringify(short.export_save_state())
	var rejected := short.purchase_facility(ROOSTER)
	_check(not bool(rejected.get("accepted", true)), "one cent below capital plus revised reserve should reject atomically", failures)
	_check(JSON.stringify(short.export_save_state()) == before, "rejected Rooster Office purchase should preserve all authoritative state", failures)

	var funded := _review_fixture(16004, 4, 5)
	quote = funded.facility_status(ROOSTER)
	funded.revenue_cents = (
		funded.current_daily_operating_cost_cents()
		+ int(quote.get("cost_cents", 0))
		+ int(quote.get("added_daily_operating_cents", 0))
	)
	var operating_before := funded.current_daily_operating_cost_cents()
	var receipt := funded.purchase_facility(ROOSTER)
	_check(bool(receipt.get("accepted", false)), "exactly funded Rooster Office purchase should commission", failures)
	_check(int(receipt.get("cost_cents", -1)) == 10_000, "Rooster Office level one should debit exactly $100", failures)
	_check(int(receipt.get("maintenance_delta_cents", -1)) == 400, "Rooster Office level one should add exactly $4 maintenance", failures)
	_check(int(receipt.get("supervisor_payroll_delta_cents", -1)) == 500, "Rooster Office level one should add exactly $5 supervisor payroll", failures)
	_check(int(receipt.get("added_daily_operating_cents", -1)) == 900, "purchase receipt should combine maintenance and supervisor payroll", failures)
	_check(funded.current_daily_operating_cost_cents() == operating_before + 900, "supervision should add its complete $9 daily obligation", failures)
	_check(funded.spendable_fund_cents() == 0, "exact funding should preserve the complete revised operating reserve", failures)

	var missing_dependencies := _review_fixture(16005, 4, 6)
	missing_dependencies.revenue_cents = 1_000_000
	var it_status := missing_dependencies.facility_status(IT)
	_check(int(it_status.get("required_records_annex_level", 0)) == 1, "IT Coop level one should require Records Annex level one", failures)
	_check(int(it_status.get("records_annex_level_shortfall", 0)) == 1, "IT Coop should expose its missing Records tier", failures)
	_check(int(it_status.get("required_rooster_operations_office_level", 0)) == 1, "IT Coop level one should require Rooster Office level one", failures)
	_check(int(it_status.get("rooster_operations_office_level_shortfall", 0)) == 1, "IT Coop should expose its missing supervision tier", failures)
	_check(not bool(it_status.get("unlocked", true)), "IT Coop must remain gated until both permanent dependencies match", failures)


func _test_exact_tier_schedules(failures: Array[String]) -> void:
	var rooster_costs := [10_000, 16_000, 24_000]
	var rooster_maintenance := [400, 700, 1100]
	var rooster_payroll := [500, 800, 1200]
	var rooster_days := [5, 8, 11]
	var rooster_names := ["SHIFT BOARD PERCH", "GLASS SUPERVISION POD", "COMMAND ROOST GALLERY"]
	var action_limits := [2, 3, 4]
	var grievance_mp := [750, 1250, 2000]
	var stress_mp := [500, 1000, 1500]
	var solidarity_mp := [500, 1000, 1500]
	for index in 3:
		var staff := index + 4
		var simulation := _review_fixture(16100 + index, staff, rooster_days[index])
		simulation.owned_facilities[ROOSTER] = index
		simulation.revenue_cents = 1_000_000
		var status := simulation.facility_status(ROOSTER)
		_check(int(status.get("next_level", 0)) == index + 1, "Rooster Office should preview the next cumulative tier", failures)
		_check(String(status.get("next_level_name", "")) == rooster_names[index], "Rooster Office tier should expose its authored room name", failures)
		_check(int(status.get("cost_cents", -1)) == rooster_costs[index], "Rooster Office tier should expose exact capital cost", failures)
		_check(int(status.get("next_maintenance_cents", -1)) == rooster_maintenance[index], "Rooster Office tier should expose exact total maintenance", failures)
		_check(int(status.get("next_supervisor_payroll_cents", -1)) == rooster_payroll[index], "Rooster Office tier should expose exact supervisor payroll", failures)
		simulation.owned_facilities[ROOSTER] = index + 1
		_check(simulation.personnel_action_limit() == action_limits[index], "Rooster Office tier should scale the daily action limit exactly", failures)
		_check(simulation.rooster_surveillance_grievance_millipoints() == grievance_mp[index], "Rooster Office tier should expose exact grievance pressure", failures)
		_check(simulation.rooster_surveillance_stress_millipoints() == stress_mp[index], "Rooster Office tier should expose exact stress pressure", failures)
		_check(simulation.rooster_surveillance_solidarity_millipoints() == solidarity_mp[index], "Rooster Office tier should expose exact solidarity pressure", failures)

	var it_costs := [13_000, 20_000, 30_000]
	var it_maintenance := [1000, 1700, 2600]
	var it_days := [6, 9, 12]
	var it_names := ["CABLE & REPAIR BENCH", "PREDICTIVE DISPATCH RACK", "AUTOMATED CLAIMS SORTER"]
	var work_bp := [10_300, 10_600, 11_000]
	var grace_minutes := [150, 120, 60]
	var exposure_mp := [1000, 1800, 2800]
	var patch_costs := [2200, 2600, 3000]
	var sheet_loss_mp := [8000, 10_000, 12_000]
	var sheet_crack_bp := [750, 900, 1050]
	for index in 3:
		var staff := index + 4
		var simulation := _review_fixture(16200 + index, staff, it_days[index])
		simulation.owned_facilities[RECORDS] = index + 1
		simulation.owned_facilities[ROOSTER] = index + 1
		simulation.owned_facilities[IT] = index
		simulation.revenue_cents = 1_000_000
		var status := simulation.facility_status(IT)
		_check(bool(status.get("unlocked", false)), "IT Coop tier should unlock when day, desks, staff, Records, and Rooster tiers match", failures)
		_check(String(status.get("next_level_name", "")) == it_names[index], "IT Coop tier should expose its authored room name", failures)
		_check(int(status.get("cost_cents", -1)) == it_costs[index], "IT Coop tier should expose exact capital cost", failures)
		_check(int(status.get("next_maintenance_cents", -1)) == it_maintenance[index], "IT Coop tier should expose exact total maintenance", failures)
		simulation.owned_facilities[IT] = index + 1
		_check(simulation.automation_work_basis_points() == work_bp[index], "IT Coop tier should expose exact AUTO speed basis points", failures)
		_check(simulation.automation_specialty_grace_minutes() == grace_minutes[index], "IT Coop tier should expose exact specialty grace", failures)
		_check(simulation.automation_compliance_exposure_millipoints() == exposure_mp[index], "IT Coop tier should expose exact compliance exposure", failures)
		_check(simulation.ledger_molt_patch_cost_cents() == patch_costs[index], "IT Coop tier should expose exact Ledger Molt patch cost", failures)
		_check(simulation.ledger_molt_spreadsheet_compliance_loss_millipoints() == sheet_loss_mp[index], "IT Coop tier should expose exact spreadsheet compliance loss", failures)
		_check(simulation.ledger_molt_spreadsheet_crack_basis_points() == sheet_crack_bp[index], "IT Coop tier should expose exact spreadsheet crack exposure", failures)


func _test_shift_pressure_and_personnel_capacity(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(16301, 6)
	simulation.day = 12
	simulation.owned_facilities[ROOSTER] = 3
	simulation.owned_facilities[RECORDS] = 3
	simulation.owned_facilities[IT] = 3
	simulation.revenue_cents = 1_000_000
	simulation._prepare_morning_directive()
	var grievance_before := simulation.workers[0].grievance
	var stress_before := simulation.workers[0].stress
	var solidarity_before := simulation.solidarity
	var compliance_before := simulation.compliance
	_check(simulation.select_directive(&"shell_assurance"), "operations pressure fixture should authorize one directive", failures)
	_check(is_equal_approx(simulation.workers[0].grievance - grievance_before, 1.0), "Shell Assurance plus tier-three surveillance should net +1 grievance per hen", failures)
	_check(is_equal_approx(simulation.workers[0].stress - stress_before, 1.5), "tier-three surveillance should add exactly 1.5 stress per hen", failures)
	_check(is_equal_approx(simulation.solidarity - solidarity_before, 1.5), "tier-three surveillance should add exactly 1.5 flock solidarity", failures)
	_check(is_equal_approx(simulation.compliance - compliance_before, 0.2), "Shell Assurance plus tier-three IT exposure should net +0.2 compliance", failures)
	var pressure_state := [simulation.workers[0].grievance, simulation.workers[0].stress, simulation.solidarity, simulation.compliance]
	_check(not simulation.select_directive(&"shell_assurance"), "a resolved directive must not apply operations pressure twice", failures)
	_check(pressure_state == [simulation.workers[0].grievance, simulation.workers[0].stress, simulation.solidarity, simulation.compliance], "rejected duplicate directive should preserve every pressure value", failures)

	var first := simulation.perform_personnel_action(0, &"share_credit")
	_check(bool(first.get("accepted", false)), "tier-three supervision should accept the first check-in", failures)
	var duplicate := simulation.perform_personnel_action(0, &"career_coaching")
	_check(not bool(duplicate.get("accepted", true)), "one hen must not receive two check-ins in one shift", failures)
	for worker_id in [1, 2, 3]:
		_check(bool(simulation.perform_personnel_action(worker_id, &"share_credit").get("accepted", false)), "tier-three supervision should accept four unique daily check-ins", failures)
	_check(not bool(simulation.perform_personnel_action(4, &"share_credit").get("accepted", true)), "a fifth check-in should reject at the tier-three action limit", failures)
	var action_status := simulation.personnel_action_status()
	_check(int(action_status.get("limit", 0)) == 4 and int(action_status.get("used", 0)) == 4, "personnel status should expose the exact four-of-four usage", failures)
	_check((action_status.get("actions", []) as Array).size() == 4, "personnel status should retain every accepted action receipt", failures)


func _test_promotion_wage_reserve_atomicity(failures: Array[String]) -> void:
	var simulation := _running_operations_fixture(16321)
	_check(simulation.select_directive(&"shell_assurance"), "promotion reserve fixture should enter the running shift", failures)
	var worker := simulation.workers[1]
	worker.career_xp = 17
	var wage_before := worker.daily_wage_cents()
	var coaching_preview: Dictionary = {}
	for action in simulation.personnel_action_catalog(worker.id):
		if StringName(action.get("id", &"")) == &"career_coaching":
			coaching_preview = action
			break
	_check(not coaching_preview.is_empty(), "promotion reserve fixture should expose career coaching", failures)
	_check(int(coaching_preview.get("career_xp_award", 0)) == 22, "advancement-minded coaching should preview its exact preferred XP award", failures)
	_check(int(coaching_preview.get("projected_wage_delta_cents", 0)) == 100, "coaching across the first threshold should preview a $1 daily wage increase", failures)

	var action_cost := int(coaching_preview.get("cost_cents", 0))
	var wage_delta := int(coaching_preview.get("projected_wage_delta_cents", 0))
	var exact_funding := simulation.protected_reserve_cents() + action_cost + wage_delta
	simulation.revenue_cents = exact_funding - 1
	var before_rejection := JSON.stringify(simulation.export_save_state())
	var rejected := simulation.perform_personnel_action(worker.id, &"career_coaching")
	_check(not bool(rejected.get("accepted", true)), "one cent below action cost plus promoted payroll reserve should reject", failures)
	_check(String(rejected.get("reason", "")).contains("daily promotion wage"), "promotion reserve rejection should explain the added wage obligation", failures)
	_check(JSON.stringify(simulation.export_save_state()) == before_rejection, "rejected promotion should preserve Feed Fund, career state, and action capacity atomically", failures)

	simulation.revenue_cents = exact_funding
	var accepted := simulation.perform_personnel_action(worker.id, &"career_coaching")
	_check(bool(accepted.get("accepted", false)), "exact action-plus-promotion funding should accept", failures)
	_check(bool(accepted.get("promoted", false)), "the exact-funded coaching should actually promote the hen", failures)
	_check(int(accepted.get("career_xp_award", 0)) == 22, "accepted receipt should retain the preflight XP award", failures)
	_check(int(accepted.get("daily_wage_delta_cents", 0)) == 100, "accepted receipt should disclose the exact new daily wage obligation", failures)
	_check(worker.daily_wage_cents() == wage_before + 100, "promotion should raise authoritative daily payroll by exactly $1", failures)
	_check(simulation.spendable_fund_cents() == 0, "exact funding should leave the promoted payroll reserve intact", failures)


func _test_multi_action_chronology_round_trip(failures: Array[String]) -> void:
	var source := _running_operations_fixture(16331)
	source.revenue_cents = 1_000_000
	_check(source.select_directive(&"shell_assurance"), "chronology fixture should enter the running shift", failures)
	var first := source.perform_personnel_action(3, &"share_credit")
	var second := source.perform_personnel_action(0, &"share_credit")
	_check(bool(first.get("accepted", false)) and bool(second.get("accepted", false)), "Rooster level one should accept two check-ins in filing order", failures)
	_check(int(first.get("action_serial", 0)) == 1 and int(second.get("action_serial", 0)) == 2, "accepted check-ins should receive monotonic action serials", failures)

	var status := source.personnel_action_status()
	var actions := status.get("actions", []) as Array
	_check(actions.size() == 2, "chronology status should expose both filed check-ins", failures)
	if actions.size() == 2:
		_check(int((actions[0] as Dictionary).get("worker_id", -1)) == 3, "chronology should preserve the first-filed higher worker ID", failures)
		_check(int((actions[1] as Dictionary).get("worker_id", -1)) == 0, "chronology should preserve the second-filed lower worker ID", failures)
	var last_action := status.get("last_action", {}) as Dictionary
	_check(int(last_action.get("worker_id", -1)) == 0, "last action should mean latest filing rather than highest worker ID", failures)
	var supervision := (source.operations_snapshot().get("supervision", {}) as Dictionary)
	var operations_actions := supervision.get("actions", []) as Array
	_check(operations_actions == actions, "operations projection should use the same authoritative filing chronology", failures)

	var restored := DepartmentSimulation.new(16332, 4)
	_check(restored.restore_save_state(_json_round_trip(source.export_save_state())), "ordered multi-action checkpoint should round trip", failures)
	var restored_status := restored.personnel_action_status()
	_check((restored_status.get("actions", []) as Array) == actions, "round trip should preserve action serials and filing chronology exactly", failures)
	_check((restored_status.get("last_action", {}) as Dictionary) == last_action, "round trip should preserve the latest-action projection", failures)


func _test_supervisor_payroll_settlement(failures: Array[String]) -> void:
	var funded := _running_operations_fixture(16341)
	_check(funded.select_directive(&"shell_assurance"), "funded payroll fixture should enter the running shift", failures)
	var funded_feed := funded.current_daily_feed_cost_cents()
	var funded_facility := funded.current_daily_facility_cost_cents()
	var funded_hen_payroll := funded.current_daily_hen_payroll_cents()
	var funded_supervisor_payroll := funded.current_daily_supervisor_payroll_cents()
	funded.revenue_cents = funded_feed + funded_facility + funded_hen_payroll + funded_supervisor_payroll
	var funded_report := _close_on_next_tick(funded)
	_check(not funded_report.is_empty(), "funded operations fixture should emit a closing report", failures)
	_check(int(funded_report.get("hen_payroll_cents", -1)) == 1600, "closing report should separate exact four-hen payroll", failures)
	_check(int(funded_report.get("supervisor_payroll_cents", -1)) == 500, "closing report should separate Rooster level-one payroll", failures)
	_check(int(funded_report.get("payroll_cents", -1)) == 2100, "closing payroll should combine hens and supervisor exactly", failures)
	_check(int(funded_report.get("payroll_due_cents", -1)) == 2100, "funded closing should settle the complete combined payroll liability", failures)
	_check(int(funded_report.get("payroll_paid_cents", -1)) == 2100, "funded closing should pay the complete combined payroll", failures)
	_check(int(funded_report.get("wage_arrears_cents", -1)) == 0 and funded.wage_arrears_cents == 0, "fully funded supervisor payroll should create no arrears", failures)

	var partial := _running_operations_fixture(16342)
	_check(partial.select_directive(&"shell_assurance"), "partial payroll fixture should enter the running shift", failures)
	var partial_feed := partial.current_daily_feed_cost_cents()
	var partial_facility := partial.current_daily_facility_cost_cents()
	var partial_hen_payroll := partial.current_daily_hen_payroll_cents()
	partial.revenue_cents = partial_feed + partial_facility + partial_hen_payroll
	var partial_report := _close_on_next_tick(partial)
	_check(not partial_report.is_empty(), "partial operations fixture should emit a closing report", failures)
	_check(int(partial_report.get("supervisor_payroll_cents", -1)) == 500, "partial closing should still disclose the supervisor liability", failures)
	_check(int(partial_report.get("payroll_due_cents", -1)) == 2100, "partial closing should not omit supervisor payroll from wages due", failures)
	_check(int(partial_report.get("payroll_paid_cents", -1)) == 1600, "partial closing should pay only the available post-overhead fund", failures)
	_check(int(partial_report.get("wage_arrears_cents", -1)) == 500 and partial.wage_arrears_cents == 500, "unfunded supervisor wages should persist as exact arrears", failures)


func _test_auto_routing_speed_and_presence(failures: Array[String]) -> void:
	var manual := DepartmentSimulation.new(16401, 4)
	var baseline_auto := DepartmentSimulation.new(16401, 4)
	var improved_auto := DepartmentSimulation.new(16401, 4)
	_stage_active_claim(manual, &"appeals", true)
	_stage_active_claim(baseline_auto, DepartmentSimulation.AUTO_ASSIGNMENT, true)
	improved_auto.owned_facilities[IT] = 3
	_stage_active_claim(improved_auto, DepartmentSimulation.AUTO_ASSIGNMENT, true)
	manual.advance_tick()
	baseline_auto.advance_tick()
	improved_auto.advance_tick()
	_check(is_equal_approx(manual.workers[0].work_progress, baseline_auto.workers[0].work_progress), "manual and baseline AUTO should process identical claims at the same speed", failures)
	_check(is_equal_approx(improved_auto.workers[0].work_progress, baseline_auto.workers[0].work_progress * 1.10), "tier-three IT should accelerate only AUTO work by exactly 10%", failures)

	var absent := DepartmentSimulation.new(16402, 4)
	absent.owned_facilities[IT] = 3
	_stage_active_claim(absent, DepartmentSimulation.AUTO_ASSIGNMENT, false)
	var absent_progress := absent.workers[0].work_progress
	absent.advance_tick()
	_check(is_equal_approx(absent.workers[0].work_progress, absent_progress), "automation must not process a claim while its hen is absent from the workstation", failures)
	_check(absent.eggs_today == 0, "automation must not lay or deliver an egg from an unattended desk", failures)

	var legacy_routing := _secondary_routing_fixture(16403, 0)
	var legacy_claim := legacy_routing._take_claim_for_worker(legacy_routing.workers[0])
	_check(legacy_claim != null and legacy_claim.lane == &"predator_loss", "baseline AUTO should ignore a secondary specialty and take the globally urgent claim", failures)
	var upgraded_routing := _secondary_routing_fixture(16404, 1)
	var upgraded_claim := upgraded_routing._take_claim_for_worker(upgraded_routing.workers[0])
	_check(upgraded_claim != null and upgraded_claim.lane == &"nest_damage", "IT level one should recognize an accredited secondary specialty within its grace window", failures)


func _test_ledger_molt_authority(failures: Array[String]) -> void:
	var patched := DepartmentSimulation.new(16451, 6)
	patched.day = 12
	patched.owned_facilities[IT] = 3
	patched.revenue_cents = patched.current_daily_operating_cost_cents() + 3000
	var choices := patched._incident_choices(&"ledger_molt")
	for choice_value in choices:
		var choice := choice_value as Dictionary
		if StringName(choice.get("id", &"")) == &"patch":
			choice["cost_cents"] = 0
	patched.pending_decision = {
		"serial": 77,
		"kind": &"incident",
		"id": &"ledger_molt",
		"options": choices,
	}
	patched.shift_phase = DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT
	var fund_before := patched.revenue_cents
	_check(patched._resolve_incident(&"patch"), "funded Ledger Molt patch should resolve", failures)
	_check(patched.revenue_cents == fund_before - 3000, "Ledger Molt resolution should recompute tier-three patch cost instead of trusting tampered option copy", failures)

	var spreadsheet := DepartmentSimulation.new(16452, 6)
	spreadsheet.owned_facilities[IT] = 3
	var compliance_before := spreadsheet.compliance
	var crack_before := float(spreadsheet.get("_incident_crack_modifier"))
	spreadsheet._apply_incident_effects(&"ledger_molt", &"spreadsheet")
	_check(is_equal_approx(spreadsheet.compliance, compliance_before - 12.0), "tier-three spreadsheet branch should lose exactly 12 compliance", failures)
	_check(is_equal_approx(float(spreadsheet.get("_incident_crack_modifier")), crack_before + 0.105), "tier-three spreadsheet branch should add exactly 10.5% crack exposure", failures)


func _test_operations_snapshot_contract(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(16501, 6)
	simulation.day = 12
	simulation.owned_facilities[ROOSTER] = 3
	simulation.owned_facilities[RECORDS] = 3
	simulation.owned_facilities[IT] = 3
	var operations := simulation.operations_snapshot()
	for field in [
		"version", "rooster_office_level", "it_coop_level", "flock_relations_office_level", "supervision",
		"automation", "daily_costs", "rooster_operations_office", "it_coop",
		"next_operations_action",
	]:
		_check(operations.has(field), "operations snapshot should expose frozen field %s" % field, failures)
	var supervision := operations.get("supervision", {}) as Dictionary
	var automation := operations.get("automation", {}) as Dictionary
	_check(int(supervision.get("action_limit", 0)) == 4, "operations snapshot should expose tier-three action capacity", failures)
	_check(int(supervision.get("supervisor_payroll_cents", 0)) == 1200, "operations snapshot should expose supervisor payroll separately", failures)
	_check(int(automation.get("work_basis_points", 0)) == 11_000, "operations snapshot should expose integer AUTO basis points", failures)
	_check(bool(automation.get("recognizes_secondary_specialties", false)), "operations snapshot should disclose secondary-specialty recognition", failures)
	var snapshot := simulation.snapshot()
	_check(int(snapshot.get("daily_hen_payroll_cents", -1)) == simulation.current_daily_hen_payroll_cents(), "main snapshot should separate hen payroll", failures)
	_check(int(snapshot.get("daily_supervisor_payroll_cents", -1)) == 1200, "main snapshot should separate supervisor payroll", failures)
	_check((snapshot.get("operations", {}) as Dictionary) == operations, "main snapshot should embed the frozen operations projection", failures)


func _review_fixture(seed: int, staff_count: int, target_day: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, staff_count)
	simulation.day = target_day
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	return simulation


func _running_operations_fixture(seed: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 4)
	simulation.day = 5
	simulation.owned_facilities[ROOSTER] = 1
	simulation.revenue_cents = 1_000_000
	simulation._prepare_morning_directive()
	return simulation


func _close_on_next_tick(simulation: DepartmentSimulation) -> Dictionary:
	var report_box := {"report": {}}
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		report_box["report"] = report.duplicate(true)
	, CONNECT_ONE_SHOT)
	for worker in simulation.workers:
		simulation.set_worker_at_workstation(worker.id, false)
	simulation.incidents_resolved_today = DepartmentSimulation.INCIDENT_MINUTES.size()
	simulation.set("_incident_slot", DepartmentSimulation.INCIDENT_MINUTES.size())
	simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	simulation.advance_tick()
	return report_box.get("report", {}) as Dictionary


func _stage_active_claim(simulation: DepartmentSimulation, assignment: StringName, seated: bool) -> void:
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	simulation.pending_decision.clear()
	var worker := simulation.workers[0]
	worker.assigned_lane = assignment
	worker.current_claim = ClaimState.new(
		90_000 + simulation.day,
		&"appeals",
		"APPEALS REVIEW",
		1.0,
		500,
		0.0,
		0,
		300,
		300,
	)
	worker.work_state = ChickenState.WorkState.WORKING
	worker.work_progress = 0.0
	worker.fatigue = 0.0
	worker.stress = 0.0
	worker.morale = 70.0
	simulation.set_worker_at_workstation(worker.id, seated)


func _secondary_routing_fixture(seed: int, it_level: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 4)
	simulation.owned_facilities[IT] = it_level
	var worker := simulation.workers[0]
	worker.specialty = &"appeals"
	worker.secondary_specialty = &"nest_damage"
	worker.assigned_lane = DepartmentSimulation.AUTO_ASSIGNMENT
	var queues := simulation.get("_claim_queues") as Dictionary
	for lane in DepartmentSimulation.CLAIM_LANES:
		queues[lane] = []
	queues[&"predator_loss"] = [ClaimState.new(91_001, &"predator_loss", "URGENT LOSS", 1.0, 500, 0.0, 0, 100, 100)]
	queues[&"nest_damage"] = [ClaimState.new(91_002, &"nest_damage", "TRAINED NEST", 1.0, 500, 0.0, 0, 220, 220)]
	simulation._sync_claims_waiting()
	return simulation


func _json_round_trip(value: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(value))
	return parsed as Dictionary if parsed is Dictionary else {}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
