extends SceneTree


const FLOCK_RELATIONS := DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID
const ROOSTER := DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID
const WELLNESS := DepartmentSimulation.WELLNESS_NEST_ID
const RELATIONS_FIELDS: Array[String] = [
	"flock_relations_open_cases",
	"flock_relations_resolutions_used_today",
	"flock_relations_resolved_total",
	"flock_relations_denied_total",
	"flock_relations_settlement_spend_total_cents",
	"last_flock_relations_resolution",
	"flock_relations_resolution_history",
	"next_flock_relations_case_id",
]


func _init() -> void:
	var failures: Array[String] = []
	_test_current_schema_open_and_resolved_round_trips(failures)
	_test_strict_neutral_v16_migration(failures)
	_test_dependency_and_case_tamper_rejection(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("FLOCK_RELATIONS_PERSISTENCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FLOCK_RELATIONS_PERSISTENCE_TEST_PASSED schema=22 migration=16-neutral facilities=thirteen-key cases=strict+atomic farmgate=neutral campus=neutral")
	quit(0)


func _test_current_schema_open_and_resolved_round_trips(failures: Array[String]) -> void:
	var source := _open_case_fixture(17_801)
	var exported := _json_round_trip(source.export_save_state())
	_check(int(exported.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "current case state should export schema v24", failures)
	var facilities := exported.get("owned_facilities", {}) as Dictionary
	_check(facilities.size() == 13, "schema v24 should serialize exactly thirteen facility keys", failures)
	_check(int(facilities.get(String(FLOCK_RELATIONS), -1)) == 3, "schema v24 should preserve Flock Relations tier three", failures)
	_check(exported.has("campus_expansion"), "schema v24 should carry the strict North Meadow ledger", failures)

	var restored := DepartmentSimulation.new(17_802, 6)
	_check(restored.restore_save_state(exported), "valid open-case JSON should restore", failures)
	_check(restored.flock_relations_snapshot() == source.flock_relations_snapshot(), "open-case round trip should reproduce the canonical projection", failures)
	_check(restored.export_save_state().get("flock_relations_open_cases", []) == source.export_save_state().get("flock_relations_open_cases", []), "round trip should preserve internal carry metadata", failures)

	restored.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	restored.pending_decision.clear()
	var resolved := restored.resolve_flock_relations_case(1, &"fund_remedy")
	_check(bool(resolved.get("accepted", false)), "restored case should remain resolvable", failures)
	var resolved_state := _json_round_trip(restored.export_save_state())
	var resolved_restore := DepartmentSimulation.new(17_803, 6)
	_check(resolved_restore.restore_save_state(resolved_state), "valid resolved-case JSON should restore", failures)
	_check(resolved_restore.flock_relations_open_cases.is_empty(), "resolved round trip should not resurrect the open case", failures)
	_check(resolved_restore.flock_relations_resolved_total == 1, "resolved round trip should preserve lifetime resolution count", failures)
	_check(resolved_restore.flock_relations_settlement_spend_total_cents == 2000, "resolved round trip should preserve actual severity-three remedy spend", failures)
	_check(resolved_restore.last_flock_relations_resolution == restored.last_flock_relations_resolution, "resolved round trip should preserve the compact last resolution", failures)
	_check(resolved_restore.flock_relations_resolution_history == restored.flock_relations_resolution_history, "resolved round trip should preserve bounded history", failures)


func _test_strict_neutral_v16_migration(failures: Array[String]) -> void:
	var current := DepartmentSimulation.new(17_811, 4).export_save_state()
	var legacy := current.duplicate(true)
	legacy["state_version"] = 16
	var facilities := (legacy.get("owned_facilities", {}) as Dictionary).duplicate(true)
	facilities.erase(String(FLOCK_RELATIONS))
	facilities.erase(String(DepartmentSimulation.FEED_PROCUREMENT_COOP_ID))
	facilities.erase(String(DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID))
	facilities.erase(String(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID))
	legacy["owned_facilities"] = facilities
	legacy.erase("feed_procurement_state")
	legacy.erase("harvest_credit_state")
	legacy.erase("farmgate_dispatch_state")
	legacy.erase("pinned_capital_plan_id")
	legacy.erase("last_facility_purchase_receipt")
	legacy.erase("facility_commissioning_history")
	legacy.erase("campus_expansion")
	legacy.erase("campus_expansion_state")
	for field in RELATIONS_FIELDS:
		legacy.erase(field)
	_check(facilities.size() == 9, "v16 fixture should contain the exact legacy nine-key facility ledger", failures)

	var restored := DepartmentSimulation.new(17_812, 4)
	_check(restored.restore_save_state(_json_round_trip(legacy)), "strict valid v16 checkpoint should migrate", failures)
	var migrated := restored.export_save_state()
	_check(int(migrated.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "v16 should re-export as v23", failures)
	_check((migrated.get("owned_facilities", {}) as Dictionary).size() == 13, "migration should append Flock Relations, Provisions, Gallery, and Farmgate facilities", failures)
	_check(restored.facility_level(FLOCK_RELATIONS) == 0, "v16 migration should append neutral Flock Relations level zero", failures)
	_check(restored.facility_level(DepartmentSimulation.FEED_PROCUREMENT_COOP_ID) == 0, "v16 migration should append neutral Provisions level zero", failures)
	_check(restored.facility_level(DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID) == 0, "v16 migration should append neutral Farmgate level zero", failures)
	_check(int(restored.farmgate_dispatch_snapshot().get("stock_count", -1)) == 0, "v16 migration must not invent finished-egg stock", failures)
	_check(not bool(restored.capital_plan_snapshot().get("has_pinned_plan", true)), "v16 migration must not invent a pinned capital plan", failures)
	var snapshot := restored.flock_relations_snapshot()
	_check(int(snapshot.get("capacity", -1)) == 0 and int(snapshot.get("open_case_count", -1)) == 0, "v16 migration must not invent case capacity or open cases", failures)
	_check(int(snapshot.get("resolved_total", -1)) == 0 and int(snapshot.get("settlement_spend_total_cents", -1)) == 0, "v16 migration must not invent historical dispositions or spend", failures)
	_assert_neutral_campus(restored, "v16", failures)

	var corrupt_ledgers: Array[Dictionary] = []
	var missing := legacy.duplicate(true)
	var missing_facilities := (missing.get("owned_facilities", {}) as Dictionary).duplicate(true)
	missing_facilities.erase("it_coop")
	missing["owned_facilities"] = missing_facilities
	corrupt_ledgers.append(missing)
	var extra := legacy.duplicate(true)
	var extra_facilities := (extra.get("owned_facilities", {}) as Dictionary).duplicate(true)
	extra_facilities["unlisted_barn"] = 0
	extra["owned_facilities"] = extra_facilities
	corrupt_ledgers.append(extra)
	var fractional := legacy.duplicate(true)
	var fractional_facilities := (fractional.get("owned_facilities", {}) as Dictionary).duplicate(true)
	fractional_facilities[String(DepartmentSimulation.IT_COOP_ID)] = 0.5
	fractional["owned_facilities"] = fractional_facilities
	corrupt_ledgers.append(fractional)
	for corrupt in corrupt_ledgers:
		_expect_restore_rejected_atomically(corrupt, "corrupt v16 exact facility ledger", failures)


func _test_dependency_and_case_tamper_rejection(failures: Array[String]) -> void:
	var valid := _json_round_trip(_open_case_fixture(17_821).export_save_state())
	var dependency := valid.duplicate(true)
	var dependency_facilities := (dependency.get("owned_facilities", {}) as Dictionary).duplicate(true)
	dependency_facilities[String(ROOSTER)] = 2
	dependency["owned_facilities"] = dependency_facilities
	_expect_restore_rejected_atomically(dependency, "missing permanent Rooster dependency", failures)

	var wellness_dependency := valid.duplicate(true)
	var wellness_facilities := (wellness_dependency.get("owned_facilities", {}) as Dictionary).duplicate(true)
	wellness_facilities[String(WELLNESS)] = 2
	wellness_dependency["owned_facilities"] = wellness_facilities
	_expect_restore_rejected_atomically(wellness_dependency, "missing permanent Wellness dependency", failures)

	var capacity := valid.duplicate(true)
	capacity["office_capacity"] = 5
	_expect_restore_rejected_atomically(capacity, "insufficient permanent office capacity", failures)

	var corrupt_states: Array[Dictionary] = []
	for field in ["risk_score", "severity", "title", "worker_name", "last_carry_day"]:
		var corrupt := valid.duplicate(true)
		var cases := (corrupt.get("flock_relations_open_cases", []) as Array).duplicate(true)
		var case_record := (cases[0] as Dictionary).duplicate(true)
		match field:
			"risk_score":
				case_record[field] = int(case_record[field]) + 1
			"severity":
				case_record[field] = 1
			"title":
				case_record[field] = "REWRITTEN FINDING"
			"worker_name":
				case_record[field] = "INVENTED HEN"
			"last_carry_day":
				case_record[field] = 999
		cases[0] = case_record
		corrupt["flock_relations_open_cases"] = cases
		corrupt_states.append(corrupt)
	var evidence_tamper := valid.duplicate(true)
	var evidence_cases := (evidence_tamper.get("flock_relations_open_cases", []) as Array).duplicate(true)
	var evidence_case := (evidence_cases[0] as Dictionary).duplicate(true)
	var evidence := (evidence_case.get("evidence", {}) as Dictionary).duplicate(true)
	evidence["grievance"] = 0.0
	evidence_case["evidence"] = evidence
	evidence_cases[0] = evidence_case
	evidence_tamper["flock_relations_open_cases"] = evidence_cases
	corrupt_states.append(evidence_tamper)
	for corrupt in corrupt_states:
		_expect_restore_rejected_atomically(corrupt, "tampered open case", failures)

	var resolved_source := _open_case_fixture(17_822)
	_check(bool(resolved_source.resolve_flock_relations_case(1, &"fund_remedy").get("accepted", false)), "resolved corruption fixture should close its case", failures)
	var resolved_valid := _json_round_trip(resolved_source.export_save_state())
	for field in ["flock_relations_resolved_total", "flock_relations_settlement_spend_total_cents", "next_flock_relations_case_id"]:
		var corrupt := resolved_valid.duplicate(true)
		corrupt[field] = int(corrupt.get(field, 0)) + 1
		_expect_restore_rejected_atomically(corrupt, "tampered %s" % field, failures)
	var history_tamper := resolved_valid.duplicate(true)
	var history := (history_tamper.get("flock_relations_resolution_history", []) as Array).duplicate(true)
	var receipt := (history[0] as Dictionary).duplicate(true)
	receipt["cost_cents"] = 0
	history[0] = receipt
	history_tamper["flock_relations_resolution_history"] = history
	_expect_restore_rejected_atomically(history_tamper, "tampered resolution receipt", failures)

	var neutral := DepartmentSimulation.new(17_823, 4).export_save_state()
	neutral["flock_relations_resolved_total"] = 1
	_expect_restore_rejected_atomically(neutral, "non-neutral level-zero case history", failures)


func _open_case_fixture(seed: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed, 6)
	simulation.office_capacity = 6
	simulation.day = 13
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 1_000_000
	simulation.owned_facilities[ROOSTER] = 3
	simulation.owned_facilities[WELLNESS] = 3
	simulation.owned_facilities[FLOCK_RELATIONS] = 3
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
	simulation._file_flock_relations_case_after_shift(12)
	return simulation


func _expect_restore_rejected_atomically(
	state: Dictionary,
	label: String,
	failures: Array[String],
) -> void:
	var target := DepartmentSimulation.new(17_899, 6)
	var before := JSON.stringify(target.export_save_state())
	_check(not target.restore_save_state(_json_round_trip(state)), "%s should reject" % label, failures)
	_check(JSON.stringify(target.export_save_state()) == before, "%s should leave the target untouched" % label, failures)


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
