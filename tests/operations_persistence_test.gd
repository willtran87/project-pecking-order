extends SceneTree


const ROOSTER := DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID
const IT := DepartmentSimulation.IT_COOP_ID
const RECORDS := DepartmentSimulation.RECORDS_ANNEX_ID
const FLOCK_RELATIONS := DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID


func _init() -> void:
	var failures: Array[String] = []
	_test_current_schema_round_trip(failures)
	_test_strict_neutral_v15_migration(failures)
	_test_v15_corruption_rejected_atomically(failures)
	_test_v16_structural_validation(failures)
	_test_ownership_survives_staff_loss(failures)
	_test_personnel_action_limit_validation(failures)
	_test_personnel_action_serial_and_causality_validation(failures)
	_test_shift_phase_decision_tuple_validation(failures)
	_test_shift_pressure_restore_boundary(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("OPERATIONS_PERSISTENCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OPERATIONS_PERSISTENCE_TEST_PASSED schema=22 migration=15-neutral ledger=thirteen-key dependencies=strict ownership=permanent actions=bounded pressure=exact-once campus=neutral")
	quit(0)


func _test_current_schema_round_trip(failures: Array[String]) -> void:
	var source := _tier_three_source(16601)
	source.revenue_cents = 1_000_000
	source._prepare_morning_directive()
	_check(source.select_directive(&"shell_assurance"), "round-trip fixture should resolve its Day 12 directive", failures)
	for worker_id in [0, 1, 2, 3]:
		_check(bool(source.perform_personnel_action(worker_id, &"share_credit").get("accepted", false)), "round-trip fixture should file all four tier-three check-ins", failures)
	var exported := source.export_save_state()
	_check(int(exported.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "operations state should export schema v23", failures)
	var facilities := exported.get("owned_facilities", {}) as Dictionary
	_check(facilities.size() == 13, "schema v23 should serialize exactly thirteen facility keys", failures)
	_check(int(facilities.get(String(ROOSTER), -1)) == 3, "schema v23 should serialize Rooster Office tier three", failures)
	_check(int(facilities.get(String(IT), -1)) == 3, "schema v23 should serialize IT Coop tier three", failures)
	_check(exported.has("campus_expansion"), "schema v23 should carry the strict North Meadow ledger", failures)

	var restored := DepartmentSimulation.new(16602, 6)
	_check(restored.restore_save_state(_json_round_trip(exported)), "valid schema v23 JSON should restore", failures)
	_check(restored.facility_level(ROOSTER) == 3 and restored.facility_level(IT) == 3, "round trip should preserve both cumulative operations tiers", failures)
	_check(restored.current_daily_supervisor_payroll_cents() == 1200, "round trip should restore tier-three supervisor payroll", failures)
	_check(restored.current_daily_facility_maintenance_cents() == source.current_daily_facility_maintenance_cents(), "round trip should restore every maintenance liability", failures)
	_check(restored.personnel_action_count_today() == 4, "round trip should preserve all four same-day personnel actions", failures)
	_check(restored.operations_snapshot() == source.operations_snapshot(), "round trip should reproduce the frozen operations projection", failures)


func _test_strict_neutral_v15_migration(failures: Array[String]) -> void:
	var current := DepartmentSimulation.new(16611, 4).export_save_state()
	var legacy := current.duplicate(true)
	legacy["state_version"] = 15
	var legacy_facilities := (legacy.get("owned_facilities", {}) as Dictionary).duplicate(true)
	legacy_facilities.erase(String(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID))
	legacy_facilities.erase(String(ROOSTER))
	legacy_facilities.erase(String(IT))
	legacy_facilities.erase(String(FLOCK_RELATIONS))
	legacy_facilities.erase(String(DepartmentSimulation.FEED_PROCUREMENT_COOP_ID))
	legacy_facilities.erase(String(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID))
	legacy["owned_facilities"] = legacy_facilities
	legacy.erase("feed_procurement_state")
	legacy.erase("harvest_credit_state")
	legacy.erase("farmgate_dispatch_state")
	legacy.erase("pinned_capital_plan_id")
	legacy.erase("last_facility_purchase_receipt")
	legacy.erase("facility_commissioning_history")
	legacy.erase("campus_expansion")
	legacy.erase("campus_expansion_state")
	_check(legacy_facilities.size() == 7, "v15 migration fixture should contain the exact legacy seven-key ledger", failures)

	var restored := DepartmentSimulation.new(16612, 4)
	_check(restored.restore_save_state(_json_round_trip(legacy)), "strict valid v15 state should migrate", failures)
	var migrated := restored.export_save_state()
	var migrated_facilities := migrated.get("owned_facilities", {}) as Dictionary
	_check(int(migrated.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "v15 should re-export as v23", failures)
	_check(int(migrated_facilities.get(String(ROOSTER), -1)) == 0, "v15 migration should append neutral Rooster Office level zero", failures)
	_check(int(migrated_facilities.get(String(IT), -1)) == 0, "v15 migration should append neutral IT Coop level zero", failures)
	_check(restored.current_daily_supervisor_payroll_cents() == 0, "v15 migration must not invent supervisor payroll", failures)
	_check(restored.automation_work_basis_points() == 10_000, "v15 migration must keep AUTO at its neutral baseline", failures)
	_check(restored.automation_compliance_exposure_millipoints() == 0, "v15 migration must not invent automation exposure", failures)
	_check(restored.personnel_action_limit() == 1, "v15 migration must preserve the baseline one-action limit", failures)
	_assert_neutral_campus(restored, "v15", failures)
	for invariant in ["revenue_cents", "quota_target", "rng_state", "claim_rng_state", "workers"]:
		_check(_json_round_trip({"value": migrated.get(invariant)}) == _json_round_trip({"value": current.get(invariant)}), "v15 migration should preserve %s exactly" % invariant, failures)


func _test_v15_corruption_rejected_atomically(failures: Array[String]) -> void:
	var base := DepartmentSimulation.new(16621, 4).export_save_state()
	base["state_version"] = 15
	var base_facilities := (base.get("owned_facilities", {}) as Dictionary).duplicate(true)
	base_facilities.erase(String(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID))
	base_facilities.erase(String(ROOSTER))
	base_facilities.erase(String(IT))
	base_facilities.erase(String(FLOCK_RELATIONS))
	base_facilities.erase(String(DepartmentSimulation.FEED_PROCUREMENT_COOP_ID))
	base_facilities.erase(String(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID))
	base["owned_facilities"] = base_facilities
	base.erase("feed_procurement_state")
	base.erase("harvest_credit_state")
	base.erase("farmgate_dispatch_state")
	base.erase("pinned_capital_plan_id")
	base.erase("last_facility_purchase_receipt")
	base.erase("facility_commissioning_history")
	base.erase("campus_expansion")
	base.erase("campus_expansion_state")
	var corrupt_states: Array[Dictionary] = []

	var missing := base.duplicate(true)
	var missing_facilities := (missing.get("owned_facilities", {}) as Dictionary).duplicate(true)
	missing_facilities.erase("candling_rework_bay")
	missing["owned_facilities"] = missing_facilities
	corrupt_states.append(missing)

	var extra := base.duplicate(true)
	var extra_facilities := (extra.get("owned_facilities", {}) as Dictionary).duplicate(true)
	extra_facilities["unlisted_barn"] = 0
	extra["owned_facilities"] = extra_facilities
	corrupt_states.append(extra)

	for bad_value in [0.5, "1", -1, 4]:
		var corrupt := base.duplicate(true)
		var facilities := (corrupt.get("owned_facilities", {}) as Dictionary).duplicate(true)
		facilities[String(DepartmentSimulation.WELLNESS_NEST_ID)] = bad_value
		corrupt["owned_facilities"] = facilities
		corrupt_states.append(corrupt)

	for corrupt in corrupt_states:
		_expect_restore_rejected_atomically(corrupt, "corrupt v15 facility ledger", failures)


func _test_v16_structural_validation(failures: Array[String]) -> void:
	var source := _tier_three_source(16631)
	source.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	source.pending_decision.clear()
	var valid := source.export_save_state()
	var valid_restore := DepartmentSimulation.new(16632, 6)
	_check(valid_restore.restore_save_state(_json_round_trip(valid)), "valid tier-three dependency graph should restore", failures)

	var records_broken := valid.duplicate(true)
	var records_facilities := (records_broken.get("owned_facilities", {}) as Dictionary).duplicate(true)
	records_facilities[String(RECORDS)] = 2
	records_broken["owned_facilities"] = records_facilities
	_expect_restore_rejected_atomically(records_broken, "IT tier above Records tier", failures)

	var rooster_broken := valid.duplicate(true)
	var rooster_facilities := (rooster_broken.get("owned_facilities", {}) as Dictionary).duplicate(true)
	rooster_facilities[String(ROOSTER)] = 2
	rooster_broken["owned_facilities"] = rooster_facilities
	_expect_restore_rejected_atomically(rooster_broken, "IT tier above Rooster tier", failures)

	var before_unlock := valid.duplicate(true)
	before_unlock["day"] = 10
	_expect_restore_rejected_atomically(before_unlock, "tier-three ownership before authored unlock day", failures)

	var missing := valid.duplicate(true)
	var missing_facilities := (missing.get("owned_facilities", {}) as Dictionary).duplicate(true)
	missing_facilities.erase(String(IT))
	missing["owned_facilities"] = missing_facilities
	_expect_restore_rejected_atomically(missing, "current schema missing IT key", failures)

	var out_of_range := valid.duplicate(true)
	var range_facilities := (out_of_range.get("owned_facilities", {}) as Dictionary).duplicate(true)
	range_facilities[String(ROOSTER)] = 4
	out_of_range["owned_facilities"] = range_facilities
	_expect_restore_rejected_atomically(out_of_range, "out-of-range Rooster tier", failures)


func _test_ownership_survives_staff_loss(failures: Array[String]) -> void:
	var source := _tier_three_source(16641)
	source.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	source.pending_decision.clear()
	source.revenue_cents = 1_000_000
	var release := source.release_worker(5)
	_check(bool(release.get("accepted", false)), "fixture should release one hen after legitimate tier-three commissioning", failures)
	_check(source.active_worker_count() == 5, "fixture should fall below the tier-three six-hen purchase gate", failures)
	var restored := DepartmentSimulation.new(16642, 6)
	_check(restored.restore_save_state(_json_round_trip(source.export_save_state())), "later headcount loss must not demote permanent operations ownership", failures)
	_check(restored.facility_level(ROOSTER) == 3 and restored.facility_level(IT) == 3, "permanent operations tiers should survive later roster loss", failures)


func _test_personnel_action_limit_validation(failures: Array[String]) -> void:
	var source := DepartmentSimulation.new(16651, 4)
	source.day = 5
	source.owned_facilities[ROOSTER] = 1
	source.revenue_cents = 1_000_000
	source._prepare_morning_directive()
	_check(source.select_directive(&"shell_assurance"), "action validation fixture should enter the running shift", failures)
	for worker_id in [0, 1]:
		_check(bool(source.perform_personnel_action(worker_id, &"share_credit").get("accepted", false)), "Rooster level one should allow two unique check-ins", failures)
	var legal := source.export_save_state()
	var legal_restore := DepartmentSimulation.new(16652, 4)
	_check(legal_restore.restore_save_state(_json_round_trip(legal)), "two same-day actions should restore under Rooster level one", failures)

	var over_limit := legal.duplicate(true)
	var worker_values := over_limit.get("workers", []) as Array
	var third_worker := worker_values[2] as Dictionary
	third_worker["last_personnel_action"] = "share_credit"
	third_worker["last_personnel_action_day"] = 5
	third_worker["last_personnel_action_serial"] = 3
	_expect_restore_rejected_atomically(over_limit, "three actions above Rooster level-one limit", failures)


func _test_personnel_action_serial_and_causality_validation(failures: Array[String]) -> void:
	var source := DepartmentSimulation.new(16656, 4)
	source.day = 5
	source.owned_facilities[ROOSTER] = 1
	source.revenue_cents = 1_000_000
	source._prepare_morning_directive()
	_check(source.select_directive(&"shell_assurance"), "serial fixture should enter the running shift", failures)
	for worker_id in [0, 1]:
		_check(bool(source.perform_personnel_action(worker_id, &"share_credit").get("accepted", false)), "serial fixture should file two ordered check-ins", failures)
	var legal := source.export_save_state()

	var duplicate_serial := legal.duplicate(true)
	var duplicate_workers := duplicate_serial.get("workers", []) as Array
	var first_worker := duplicate_workers[0] as Dictionary
	var second_worker := duplicate_workers[1] as Dictionary
	second_worker["last_personnel_action_serial"] = int(first_worker.get("last_personnel_action_serial", 0))
	_expect_restore_rejected_atomically(duplicate_serial, "duplicate personnel-action serial", failures)

	# Keep the phase/directive tuple valid so this reaches the rule that today's
	# actions only exist while the shift can still accept management activity.
	var review_action := legal.duplicate(true)
	review_action["shift_phase"] = DepartmentSimulation.ShiftPhase.REVIEW
	review_action["active_directive_id"] = ""
	review_action["pending_decision"] = {}
	_expect_restore_rejected_atomically(review_action, "current-day personnel action in review", failures)

	var awaiting := DepartmentSimulation.new(16657, 4)
	awaiting.day = 5
	awaiting.owned_facilities[ROOSTER] = 1
	awaiting._prepare_morning_directive()
	var awaiting_action := awaiting.export_save_state()
	var awaiting_workers := awaiting_action.get("workers", []) as Array
	var awaiting_worker := awaiting_workers[0] as Dictionary
	awaiting_worker["last_personnel_action"] = "share_credit"
	awaiting_worker["last_personnel_action_day"] = 5
	awaiting_worker["last_personnel_action_serial"] = 1
	_expect_restore_rejected_atomically(awaiting_action, "current-day personnel action before directive", failures)

	# Start from a genuinely released applicant so employment, desk, claim, and
	# staffing fields are internally valid before adding the impossible action.
	var applicant_source := DepartmentSimulation.new(16658, 4)
	applicant_source.day = 5
	applicant_source.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	applicant_source.pending_decision.clear()
	applicant_source.owned_facilities[ROOSTER] = 1
	applicant_source.revenue_cents = 1_000_000
	_check(bool(applicant_source.release_worker(3).get("accepted", false)), "applicant fixture should release one employed hen", failures)
	applicant_source._prepare_morning_directive()
	_check(applicant_source.select_directive(&"shell_assurance"), "applicant fixture should enter the running shift", failures)
	var applicant_action := applicant_source.export_save_state()
	var applicant_workers := applicant_action.get("workers", []) as Array
	var applicant_worker := applicant_workers[3] as Dictionary
	applicant_worker["last_personnel_action"] = "share_credit"
	applicant_worker["last_personnel_action_day"] = 5
	applicant_worker["last_personnel_action_serial"] = 1
	_expect_restore_rejected_atomically(applicant_action, "current-day personnel action assigned to applicant", failures)


func _test_shift_phase_decision_tuple_validation(failures: Array[String]) -> void:
	var awaiting := DepartmentSimulation.new(16671, 4)
	awaiting.day = 5
	awaiting._prepare_morning_directive()
	var awaiting_state := awaiting.export_save_state()
	var awaiting_restore := DepartmentSimulation.new(16672, 4)
	_check(awaiting_restore.restore_save_state(_json_round_trip(awaiting_state)), "valid awaiting-directive tuple should restore", failures)

	for bad_phase in [1.5, 99]:
		var invalid_phase := awaiting_state.duplicate(true)
		invalid_phase["shift_phase"] = bad_phase
		_expect_restore_rejected_atomically(invalid_phase, "invalid shift phase %s" % str(bad_phase), failures)

	var awaiting_with_active := awaiting_state.duplicate(true)
	awaiting_with_active["active_directive_id"] = "shell_assurance"
	_expect_restore_rejected_atomically(awaiting_with_active, "awaiting directive with an already-active directive", failures)

	var awaiting_without_decision := awaiting_state.duplicate(true)
	awaiting_without_decision["pending_decision"] = {}
	_expect_restore_rejected_atomically(awaiting_without_decision, "awaiting directive without morning decision", failures)

	_check(awaiting.select_directive(&"shell_assurance"), "running tuple fixture should resolve its directive", failures)
	var running_state := awaiting.export_save_state()
	var running_restore := DepartmentSimulation.new(16673, 4)
	_check(running_restore.restore_save_state(_json_round_trip(running_state)), "valid running tuple should restore", failures)

	var running_without_directive := running_state.duplicate(true)
	running_without_directive["active_directive_id"] = ""
	_expect_restore_rejected_atomically(running_without_directive, "running shift without active directive", failures)

	var running_with_pending := running_state.duplicate(true)
	running_with_pending["pending_decision"] = (awaiting_state.get("pending_decision", {}) as Dictionary).duplicate(true)
	_expect_restore_rejected_atomically(running_with_pending, "running shift with unresolved decision", failures)

	var review_state := running_state.duplicate(true)
	review_state["shift_phase"] = DepartmentSimulation.ShiftPhase.REVIEW
	review_state["active_directive_id"] = ""
	review_state["pending_decision"] = {}
	var review_restore := DepartmentSimulation.new(16674, 4)
	_check(review_restore.restore_save_state(_json_round_trip(review_state)), "valid review tuple should restore", failures)

	var review_with_directive := review_state.duplicate(true)
	review_with_directive["active_directive_id"] = "shell_assurance"
	_expect_restore_rejected_atomically(review_with_directive, "review phase with active directive", failures)

	var review_with_incident := review_state.duplicate(true)
	review_with_incident["pending_decision"] = {
		"serial": 900,
		"kind": "incident",
		"id": "ledger_molt",
		"options": [],
	}
	_expect_restore_rejected_atomically(review_with_incident, "review phase with incident decision", failures)


func _test_shift_pressure_restore_boundary(failures: Array[String]) -> void:
	var awaiting := _tier_three_source(16661)
	awaiting._prepare_morning_directive()
	var awaiting_restore := DepartmentSimulation.new(16662, 6)
	_check(awaiting_restore.restore_save_state(_json_round_trip(awaiting.export_save_state())), "awaiting-directive operations checkpoint should restore", failures)
	var grievance_before := awaiting_restore.workers[0].grievance
	var stress_before := awaiting_restore.workers[0].stress
	var solidarity_before := awaiting_restore.solidarity
	var compliance_before := awaiting_restore.compliance
	_check(awaiting_restore.select_directive(&"shell_assurance"), "restored awaiting directive should resolve once", failures)
	_check(is_equal_approx(awaiting_restore.workers[0].grievance - grievance_before, 1.0), "restored morning boundary should apply exact net grievance once", failures)
	_check(is_equal_approx(awaiting_restore.workers[0].stress - stress_before, 1.5), "restored morning boundary should apply exact stress once", failures)
	_check(is_equal_approx(awaiting_restore.solidarity - solidarity_before, 1.5), "restored morning boundary should apply exact solidarity once", failures)
	_check(is_equal_approx(awaiting_restore.compliance - compliance_before, 0.2), "restored morning boundary should apply exact net compliance once", failures)

	var running_restore := DepartmentSimulation.new(16663, 6)
	_check(running_restore.restore_save_state(_json_round_trip(awaiting_restore.export_save_state())), "running operations checkpoint should restore after pressure application", failures)
	var pressure_values := [running_restore.workers[0].grievance, running_restore.workers[0].stress, running_restore.solidarity, running_restore.compliance]
	_check(not running_restore.select_directive(&"shell_assurance"), "running restore must reject a second morning directive", failures)
	_check(pressure_values == [running_restore.workers[0].grievance, running_restore.workers[0].stress, running_restore.solidarity, running_restore.compliance], "running restore must not reapply operations pressure", failures)
	var operations := running_restore.operations_snapshot()
	_check(bool((operations.get("supervision", {}) as Dictionary).get("shift_pressure_applied", false)), "running restore should disclose that supervision pressure is already applied", failures)
	_check(bool((operations.get("automation", {}) as Dictionary).get("shift_exposure_applied", false)), "running restore should disclose that automation exposure is already applied", failures)


func _tier_three_source(seed: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 6)
	simulation.day = 12
	simulation.owned_facilities[RECORDS] = 3
	simulation.owned_facilities[ROOSTER] = 3
	simulation.owned_facilities[IT] = 3
	return simulation


func _expect_restore_rejected_atomically(data: Dictionary, label: String, failures: Array[String]) -> void:
	var worker_values := data.get("workers", []) as Array
	var target := DepartmentSimulation.new(16699, worker_values.size())
	var before := JSON.stringify(target.export_save_state())
	_check(not target.restore_save_state(_json_round_trip(data)), "%s should fail closed" % label, failures)
	_check(JSON.stringify(target.export_save_state()) == before, "%s should not partially mutate the target" % label, failures)


func _json_round_trip(value: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(value))
	return parsed as Dictionary if parsed is Dictionary else {}


func _assert_neutral_campus(simulation: DepartmentSimulation, source_label: String, failures: Array[String]) -> void:
	var campus := simulation.export_save_state().get("campus_expansion", {}) as Dictionary
	_check(
		campus == {
			"version": 1,
			"parcel_owned": false,
			"services": {"circulation": false, "power": false, "cold_chain": false},
			"pod_owned": false,
			"pod_socket_id": "",
			"capital_spend_total_cents": 0,
			"next_receipt_id": 1,
			"last_receipt": {},
			"history": [],
		},
		"%s migration should create the exact neutral North Meadow ledger" % source_label,
		failures,
	)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
