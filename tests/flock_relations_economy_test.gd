extends SceneTree


const FLOCK_RELATIONS := DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID
const ROOSTER := DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID
const WELLNESS := DepartmentSimulation.WELLNESS_NEST_ID


func _init() -> void:
	var failures: Array[String] = []
	_test_facility_catalog_and_dependencies(failures)
	_test_deterministic_filing_and_carry(failures)
	_test_completed_shift_hook_and_report(failures)
	_test_resolution_actions_and_atomic_guards(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("FLOCK_RELATIONS_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FLOCK_RELATIONS_ECONOMY_TEST_PASSED facility=three-tier filing=deterministic carry=once actions=atomic+bounded")
	quit(0)


func _test_facility_catalog_and_dependencies(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(17_701, 4)
	simulation.day = 7
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 1_000_000
	var gated := simulation.facility_status(FLOCK_RELATIONS)
	_check(int(gated.get("required_office_capacity", 0)) == 4, "tier one should require four authorized desks", failures)
	_check(int(gated.get("required_active_staff", 0)) == 4, "tier one should require four active hens", failures)
	_check(int(gated.get("required_rooster_operations_office_level", 0)) == 1, "tier one should require Rooster Operations tier one", failures)
	_check(int(gated.get("required_wellness_nest_level", 0)) == 1, "tier one should require Wellness tier one", failures)
	_check(int(gated.get("current_flock_relations_case_capacity", -1)) == 0, "unbuilt office should expose zero current case capacity", failures)
	_check(int(gated.get("next_flock_relations_case_capacity", -1)) == 1, "tier one should preview one case slot", failures)
	_check(int(gated.get("current_flock_relations_resolution_limit", -1)) == 0, "unbuilt office should expose zero current resolution limit", failures)
	_check(int(gated.get("next_flock_relations_resolution_limit", -1)) == 1, "tier one should preview one review disposition", failures)
	_check(not bool(gated.get("can_purchase", true)), "missing permanent dependencies must gate the purchase", failures)

	simulation.owned_facilities[ROOSTER] = 1
	simulation.owned_facilities[WELLNESS] = 1
	var ready := simulation.facility_status(FLOCK_RELATIONS)
	_check(bool(ready.get("can_purchase", false)), "matching permanent dependencies should open tier one", failures)
	_check(int(ready.get("cost_cents", -1)) == 11_000, "tier one should cost exactly $110", failures)
	_check(int(ready.get("next_maintenance_cents", -1)) == 500, "tier one should carry exactly $5 upkeep", failures)
	var receipt := simulation.purchase_facility(FLOCK_RELATIONS)
	_check(bool(receipt.get("accepted", false)), "ready review should commission Flock Relations", failures)
	_check(int(receipt.get("current_flock_relations_case_capacity", -1)) == 0, "receipt should preserve pre-purchase case capacity", failures)
	_check(int(receipt.get("next_flock_relations_case_capacity", -1)) == 1, "receipt should disclose purchased case capacity", failures)
	_check(int(receipt.get("flock_relations_case_capacity_delta", -1)) == 1, "receipt should disclose one added case slot", failures)
	_check(int(receipt.get("current_flock_relations_resolution_limit", -1)) == 0, "receipt should preserve pre-purchase review limit", failures)
	_check(int(receipt.get("next_flock_relations_resolution_limit", -1)) == 1, "receipt should disclose purchased review limit", failures)
	_check(simulation.flock_relations_case_capacity() == 1, "tier one should authoritatively provide one case slot", failures)
	_check(simulation.flock_relations_resolution_limit() == 1, "tier one should authoritatively provide one disposition", failures)

	var costs := [11_000, 17_500, 26_000]
	var maintenance := [500, 900, 1500]
	var days := [7, 10, 13]
	var names := ["OPEN-NEST CASE INTAKE", "MEDIATION & PIP ROOM", "MANDATORY ARBITRATION ROOST"]
	for index in 3:
		var tier := _fixture(17_710 + index, index + 1)
		tier.day = days[index]
		tier.owned_facilities[FLOCK_RELATIONS] = index
		var status := tier.facility_status(FLOCK_RELATIONS)
		_check(String(status.get("next_level_name", "")) == names[index], "tier should expose its authored room name", failures)
		_check(int(status.get("cost_cents", -1)) == costs[index], "tier should expose its exact capital cost", failures)
		_check(int(status.get("next_maintenance_cents", -1)) == maintenance[index], "tier should expose its exact upkeep", failures)
		tier.owned_facilities[FLOCK_RELATIONS] = index + 1
		_check(tier.flock_relations_case_capacity() == index + 1, "case capacity should scale one per tier", failures)
		_check(tier.flock_relations_resolution_limit() == index + 1, "review limit should scale one per tier", failures)


func _test_deterministic_filing_and_carry(failures: Array[String]) -> void:
	var simulation := _fixture(17_720, 3)
	simulation.day = 9
	for worker in simulation.workers:
		worker.manager_trust = 90.0
		worker.grievance = 5.0
		worker.stress = 5.0
		worker.fatigue = 5.0
	for worker_id in [0, 1]:
		var worker := simulation.workers[worker_id]
		worker.manager_trust = 20.0
		worker.grievance = 40.0
		worker.stress = 50.0
		worker.fatigue = 40.0
	simulation.wage_arrears_cents = 100
	var first := simulation._file_flock_relations_case_after_shift(8)
	_check(first.size() == 1, "one completed shift should file at most one case", failures)
	if not first.is_empty():
		_check(int(first[0].get("worker_id", -1)) == 0, "equal risk should select the lowest worker id", failures)
		_check(StringName(first[0].get("type", &"")) == &"pay_dispute", "wage arrears should take case-type priority", failures)
		_check(String(first[0].get("docket_id", "")) == "FR-D8-H0-1", "public case should expose a stable human-readable docket", failures)
		_check(StringName(first[0].get("case_type", &"")) == &"pay_dispute", "public case should expose the case_type alias", failures)
		_check(not String(first[0].get("evidence_summary", "")).is_empty(), "public case should summarize canonical evidence", failures)
	var second := simulation._file_flock_relations_case_after_shift(8)
	_check(second.size() == 1 and int(second[0].get("worker_id", -1)) == 1, "an existing open case should exclude its subject from the next deterministic filing", failures)
	_check(simulation.flock_relations_open_cases.size() == 2, "two calls should never file more than one case each", failures)

	var compliance_before := simulation.compliance
	var solidarity_before := simulation.solidarity
	var grievance_before := simulation.workers[0].grievance
	var carry := simulation._apply_flock_relations_carry_penalties(9)
	_check(carry.size() == 2, "each older open case should receive one carry consequence", failures)
	_check(is_equal_approx(simulation.compliance, compliance_before - 3.0), "two carried cases should lower compliance by 1.5 each", failures)
	_check(is_equal_approx(simulation.solidarity, solidarity_before + 3.0), "two carried cases should raise solidarity by 1.5 each", failures)
	_check(is_equal_approx(simulation.workers[0].grievance, grievance_before + 2.0), "carry should raise the subject grievance by two", failures)
	var state_after_carry := JSON.stringify(simulation.export_save_state())
	_check(simulation._apply_flock_relations_carry_penalties(9).is_empty(), "the same completed day must not carry a case twice", failures)
	_check(JSON.stringify(simulation.export_save_state()) == state_after_carry, "duplicate carry attempt should preserve authoritative state", failures)

	var public_snapshot := simulation.flock_relations_snapshot()
	var exact_keys := [
		"level", "capacity", "resolution_limit", "resolutions_used_today",
		"open_case_count", "open_cases", "resolved_total", "denied_total",
		"settlement_spend_total_cents", "last_resolution",
	]
	_check(public_snapshot.size() == exact_keys.size(), "canonical Flock Relations snapshot should contain exactly ten keys", failures)
	for key in exact_keys:
		_check(public_snapshot.has(key), "canonical Flock Relations snapshot should expose %s" % key, failures)
	var cases := public_snapshot.get("open_cases", []) as Array
	if not cases.is_empty():
		var options := (cases[0] as Dictionary).get("action_options", []) as Array
		_check(options.size() == 4, "every public case should expose all four authoritative actions", failures)
		for option_value in options:
			var option := option_value as Dictionary
			for field in ["action_id", "label", "required_level", "cost_cents", "enabled", "reason", "effect_preview"]:
				_check(option.has(field), "action option should expose %s" % field, failures)


func _test_resolution_actions_and_atomic_guards(failures: Array[String]) -> void:
	var expected := {
		&"fund_remedy": {"cost": 2000, "trust": 12.0, "grievance": -16.0, "stress": -8.0, "compliance": 4.0, "solidarity": 0.0, "favor": -2.0},
		&"mediate": {"cost": 1000, "trust": 7.0, "grievance": -9.0, "stress": -4.0, "compliance": 2.0, "solidarity": 0.0, "favor": -1.0},
		&"file_pip": {"cost": 0, "trust": -10.0, "grievance": 14.0, "stress": 8.0, "compliance": -3.0, "solidarity": 4.0, "favor": 3.0},
		&"binding_arbitration": {"cost": 1500, "trust": -3.0, "grievance": -5.0, "stress": -3.0, "compliance": 6.0, "solidarity": 2.0, "favor": 1.0},
	}
	var serial := 0
	for action_id_value in expected:
		var action_id := StringName(action_id_value)
		var simulation := _severity_three_case(17_730 + serial, 3)
		serial += 1
		var worker := simulation.workers[0]
		worker.manager_trust = 50.0
		worker.grievance = 50.0
		worker.stress = 50.0
		simulation.compliance = 50.0
		simulation.solidarity = 50.0
		simulation.executive_confidence = 50.0
		var fund_before := simulation.revenue_cents
		var receipt := simulation.resolve_flock_relations_case(1, action_id)
		var row := expected[action_id] as Dictionary
		_check(bool(receipt.get("accepted", false)), "%s should resolve an eligible severity-three case" % action_id, failures)
		_check(int(receipt.get("cost_cents", -1)) == int(row["cost"]), "%s should charge the authored severity-three cost" % action_id, failures)
		_check(simulation.revenue_cents == fund_before - int(row["cost"]), "%s should debit its cost exactly once" % action_id, failures)
		_check(is_equal_approx(worker.manager_trust, 50.0 + float(row["trust"])), "%s should apply exact trust effect" % action_id, failures)
		_check(is_equal_approx(worker.grievance, 50.0 + float(row["grievance"])), "%s should apply exact grievance effect" % action_id, failures)
		_check(is_equal_approx(worker.stress, 50.0 + float(row["stress"])), "%s should apply exact stress effect" % action_id, failures)
		_check(is_equal_approx(simulation.compliance, 50.0 + float(row["compliance"])), "%s should apply exact compliance effect" % action_id, failures)
		_check(is_equal_approx(simulation.solidarity, 50.0 + float(row["solidarity"])), "%s should apply exact solidarity effect" % action_id, failures)
		_check(is_equal_approx(simulation.executive_confidence, 50.0 + float(row["favor"])), "%s should apply exact farmer-favor effect" % action_id, failures)
		_check(simulation.flock_relations_open_cases.is_empty(), "%s should remove the resolved case from the open queue" % action_id, failures)
		_check(simulation.flock_relations_resolved_total == 1, "%s should increment resolved total" % action_id, failures)
		_check(simulation.flock_relations_denied_total == (1 if action_id == &"file_pip" else 0), "only PIP should increment denied total", failures)

	var wrong_phase := _severity_three_case(17_740, 3)
	wrong_phase.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	_expect_atomic_rejection(wrong_phase, 1, &"fund_remedy", "non-review resolution", failures)
	var unknown_action := _severity_three_case(17_741, 3)
	_expect_atomic_rejection(unknown_action, 1, &"unlisted_disposition", "unknown disposition", failures)
	var unknown_case := _severity_three_case(17_742, 3)
	_expect_atomic_rejection(unknown_case, 999, &"fund_remedy", "unknown case", failures)
	var tier_locked := _severity_three_case(17_743, 1)
	_expect_atomic_rejection(tier_locked, 1, &"binding_arbitration", "tier-locked arbitration", failures)
	var short := _severity_three_case(17_744, 3)
	var operating_reserve := short.current_daily_operating_cost_cents() + short.wage_arrears_cents
	short.revenue_cents = operating_reserve + 1999
	_expect_atomic_rejection(short, 1, &"fund_remedy", "one-cent-short remedy", failures)

	var limited := _severity_three_case(17_745, 1)
	_check(bool(limited.resolve_flock_relations_case(1, &"file_pip").get("accepted", false)), "tier one should allow its first disposition", failures)
	limited.workers[0].manager_trust = 0.0
	limited.workers[0].grievance = 100.0
	limited.workers[0].stress = 100.0
	limited.workers[0].fatigue = 100.0
	var next_filing := limited._file_flock_relations_case_after_shift(limited.day)
	_check(next_filing.size() == 1, "freed capacity should admit a later case", failures)
	if not next_filing.is_empty():
		_expect_atomic_rejection(limited, int(next_filing[0].get("case_id", 0)), &"file_pip", "daily resolution limit", failures)


func _test_completed_shift_hook_and_report(failures: Array[String]) -> void:
	var simulation := _fixture(17_725, 1)
	simulation.day = 8
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	for worker in simulation.workers:
		worker.manager_trust = 100.0
		worker.grievance = 0.0
		worker.stress = 0.0
		worker.fatigue = 0.0
	var subject := simulation.workers[2]
	subject.manager_trust = 0.0
	subject.grievance = 100.0
	subject.stress = 100.0
	subject.fatigue = 100.0
	var observed: Dictionary = {}
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		observed.assign(report)
	)
	simulation._complete_workday()
	_check(simulation.day == 9, "completed-shift hook should advance the authoritative day", failures)
	_check(simulation.flock_relations_open_cases.size() == 1, "a completed eligible shift should file exactly one case", failures)
	_check(int(simulation.flock_relations_open_cases[0].get("worker_id", -1)) == 2, "completed shift should file for the highest-risk eligible worker", failures)
	_check((observed.get("flock_relations_filings", []) as Array).size() == 1, "day report should publish the completed filing", failures)
	_check((observed.get("flock_relations_carry_effects", []) as Array).is_empty(), "a newly filed case should not carry on its filing shift", failures)
	var report_snapshot := observed.get("flock_relations", {}) as Dictionary
	_check(int(report_snapshot.get("open_case_count", 0)) == 1, "day report should freeze the completed Flock Relations snapshot", failures)
	_check(int(observed.get("flock_relations_office_level", 0)) == 1, "day report should expose the installed Flock Relations tier", failures)


func _severity_three_case(seed: int, level: int) -> DepartmentSimulation:
	var simulation := _fixture(seed, level)
	simulation.day = 9
	for worker in simulation.workers:
		worker.manager_trust = 100.0
		worker.grievance = 0.0
		worker.stress = 0.0
		worker.fatigue = 0.0
	var subject := simulation.workers[0]
	subject.manager_trust = 0.0
	subject.grievance = 100.0
	subject.stress = 100.0
	subject.fatigue = 100.0
	simulation._file_flock_relations_case_after_shift(8)
	return simulation


func _fixture(seed: int, level: int) -> DepartmentSimulation:
	var staff := level + 3
	var simulation := DepartmentSimulation.new(seed, staff)
	simulation.office_capacity = staff
	simulation.day = 13
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 1_000_000
	simulation.owned_facilities[ROOSTER] = level
	simulation.owned_facilities[WELLNESS] = level
	simulation.owned_facilities[FLOCK_RELATIONS] = level
	return simulation


func _expect_atomic_rejection(
	simulation: DepartmentSimulation,
	case_id: int,
	action_id: StringName,
	label: String,
	failures: Array[String],
) -> void:
	var before := JSON.stringify(simulation.export_save_state())
	var result := simulation.resolve_flock_relations_case(case_id, action_id)
	_check(not bool(result.get("accepted", true)), "%s should reject" % label, failures)
	_check(JSON.stringify(simulation.export_save_state()) == before, "%s should preserve every authoritative field" % label, failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
