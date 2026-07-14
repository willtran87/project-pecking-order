extends SceneTree

const DepartmentSimulationScript := preload("res://core/simulation/department_simulation.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_test_pending_and_active_round_trip(failures)
	_test_accredited_round_trip_and_v6_migration(failures)
	_test_invalid_cross_training_fails_closed(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("CAREER_SPONSORSHIP_PERSISTENCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAREER_SPONSORSHIP_PERSISTENCE_TEST_PASSED schema=7 migration=6->7 pending=exact active=exact accredited=exact invalid=closed")
	quit(0)


func _test_pending_and_active_round_trip(failures: Array[String]) -> void:
	var simulation := _prepared_review_simulation(8101)
	var result := simulation.authorize_career_sponsorship(0, &"predator_loss")
	_check(bool(result.get("accepted", false)), "pending fixture should authorize sponsorship", failures)
	var pending_state := _json_round_trip(simulation.export_save_state())
	_check(int(pending_state.get("state_version", -1)) == 7, "new sponsorship state should export schema v7", failures)
	var restored := DepartmentSimulationScript.new(8101, 4)
	_check(restored.restore_save_state(pending_state), "schema-v7 pending sponsorship should restore", failures)
	_check(_same_state(pending_state, restored.export_save_state()), "pending sponsorship should round-trip exactly", failures)
	_check(restored.workers[0].secondary_specialty == &"" and restored.workers[0].cross_training_target == &"predator_loss", "pending restore should retain target without early accreditation", failures)
	_check(restored.workers[0].daily_wage_cents() == 500, "pending restore should retain the pre-accreditation wage", failures)

	_check(restored.begin_next_shift_briefing(), "pending restore should open the training shift briefing", failures)
	_check(restored.select_directive(&"shell_assurance"), "pending restore should enter its training shift", failures)
	var active_state := _json_round_trip(restored.export_save_state())
	var active_restored := DepartmentSimulationScript.new(8101, 4)
	_check(active_restored.restore_save_state(active_state), "mid-training state should restore", failures)
	_check(_same_state(active_state, active_restored.export_save_state()), "mid-training sponsorship should round-trip exactly", failures)
	var active_worker := _worker_snapshot(active_restored.snapshot(), 0)
	_check(bool(active_worker.get("cross_training_active", false)), "mid-training restore should expose an active training shift", failures)
	_check(_approximately(float(active_worker.get("cross_training_work_multiplier", 0.0)), 0.85), "mid-training restore should retain the exact personal multiplier", failures)

	active_restored.set_worker_at_workstation(0, true)
	active_restored.advance_tick()
	active_restored.advance_tick()
	_check(active_restored.workers[0].cross_training_worked_this_shift, "restored training should record authoritative claim participation", failures)
	var worked_state := _json_round_trip(active_restored.export_save_state())
	var worked_restored := DepartmentSimulationScript.new(8101, 4)
	_check(worked_restored.restore_save_state(worked_state), "mid-shift participation marker should restore", failures)
	_check(_same_state(worked_state, worked_restored.export_save_state()), "mid-shift participation marker should round-trip exactly", failures)
	_check(worked_restored.workers[0].cross_training_worked_this_shift, "restored participation marker should remain authoritative", failures)
	active_restored = worked_restored
	_complete_shift_to_review(active_restored, failures)
	_check(active_restored.workers[0].secondary_specialty == &"predator_loss", "restored training shift should accredit at completion", failures)
	_check(active_restored.workers[0].cross_training_target == &"", "restored training completion should clear the pending target", failures)
	_check(active_restored.workers[0].daily_wage_cents() == 600, "restored accreditation should retain the permanent wage premium", failures)


func _test_accredited_round_trip_and_v6_migration(failures: Array[String]) -> void:
	var simulation := _prepared_review_simulation(8201)
	_check(bool(simulation.authorize_career_sponsorship(0, &"predator_loss").get("accepted", false)), "accredited fixture should authorize", failures)
	_check(simulation.begin_next_shift_briefing(), "accredited fixture should open briefing", failures)
	_check(simulation.select_directive(&"shell_assurance"), "accredited fixture should enter training shift", failures)
	simulation.set_worker_at_workstation(0, true)
	simulation.advance_tick()
	simulation.advance_tick()
	_complete_shift_to_review(simulation, failures)
	var accredited_state := _json_round_trip(simulation.export_save_state())
	var restored := DepartmentSimulationScript.new(8201, 4)
	_check(restored.restore_save_state(accredited_state), "accredited state should restore", failures)
	var expected_accredited_workers := accredited_state.get("workers", []) as Array
	var expected_accredited_worker := expected_accredited_workers[0] as Dictionary
	var actual_accredited_worker := _json_round_trip(restored.workers[0].to_save_data())
	_check(expected_accredited_worker == actual_accredited_worker, "accredited worker state should round-trip exactly", failures)
	for field in ["state_version", "day", "revenue_cents", "wage_arrears_cents", "shift_phase"]:
		_check(restored.export_save_state().get(field) == accredited_state.get(field), "accredited economy should round-trip %s exactly" % field, failures)
	_check(restored.workers[0].secondary_specialty == &"predator_loss", "accredited restore should retain the permanent secondary lane", failures)
	_check(restored.workers[0].daily_wage_cents() == 600, "accredited restore should reserve the permanent $1 wage premium", failures)

	var legacy_source := DepartmentSimulationScript.new(8202, 4).export_save_state()
	legacy_source["state_version"] = 6
	for worker_value in legacy_source.get("workers", []):
		var worker := worker_value as Dictionary
		worker.erase("secondary_specialty")
		worker.erase("cross_training_target")
		worker.erase("cross_training_worked_this_shift")
	var legacy_restored := DepartmentSimulationScript.new(8202, 4)
	_check(legacy_restored.restore_save_state(_json_round_trip(legacy_source)), "schema-v6 state should migrate through neutral sponsorship defaults", failures)
	var migrated := legacy_restored.export_save_state()
	_check(int(migrated.get("state_version", -1)) == 7, "v6 migration should export schema v7", failures)
	for worker in legacy_restored.workers:
		_check(worker.secondary_specialty == &"" and worker.cross_training_target == &"", "v6 migration should not invent a secondary specialty", failures)


func _test_invalid_cross_training_fails_closed(failures: Array[String]) -> void:
	var target := DepartmentSimulationScript.new(8301, 4)
	var before := JSON.stringify(target.export_save_state())
	var invalid_lane := target.export_save_state()
	var invalid_workers := invalid_lane.get("workers", []) as Array
	(invalid_workers[0] as Dictionary)["career_xp"] = 18
	(invalid_workers[0] as Dictionary)["cross_training_target"] = "not_a_claim_lane"
	_check(not target.restore_save_state(invalid_lane), "unsupported pending lane should be rejected", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "unsupported-lane rejection should leave the target simulation untouched", failures)

	var conflicting := target.export_save_state()
	var conflicting_workers := conflicting.get("workers", []) as Array
	(conflicting_workers[0] as Dictionary)["career_xp"] = 18
	(conflicting_workers[0] as Dictionary)["secondary_specialty"] = "predator_loss"
	(conflicting_workers[0] as Dictionary)["cross_training_target"] = "nest_damage"
	_check(not target.restore_save_state(conflicting), "simultaneous accredited and pending specialties should be rejected", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "conflicting-specialty rejection should leave the target simulation untouched", failures)

	var fabricated_participation := target.export_save_state()
	var fabricated_workers := fabricated_participation.get("workers", []) as Array
	(fabricated_workers[0] as Dictionary)["career_xp"] = 18
	(fabricated_workers[0] as Dictionary)["cross_training_target"] = "predator_loss"
	(fabricated_workers[0] as Dictionary)["cross_training_worked_this_shift"] = true
	fabricated_participation["shift_phase"] = DepartmentSimulationScript.ShiftPhase.REVIEW
	_check(not target.restore_save_state(fabricated_participation), "review state must reject fabricated training participation", failures)
	_check(JSON.stringify(target.export_save_state()) == before, "fabricated-participation rejection should leave the target simulation untouched", failures)


func _prepared_review_simulation(seed: int) -> DepartmentSimulation:
	var simulation := DepartmentSimulationScript.new(seed, 4)
	simulation.workers[0].career_xp = 18
	simulation.shift_phase = DepartmentSimulationScript.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = simulation.current_daily_operating_cost_cents() + simulation.wage_arrears_cents + 5000
	return simulation


func _complete_shift_to_review(simulation: DepartmentSimulation, failures: Array[String]) -> void:
	var safety := 0
	while simulation.shift_phase != DepartmentSimulationScript.ShiftPhase.REVIEW and safety < 8:
		match simulation.shift_phase:
			DepartmentSimulationScript.ShiftPhase.RUNNING:
				simulation.minute_of_day = DepartmentSimulationScript.SHIFT_END_MINUTE - DepartmentSimulationScript.MINUTES_PER_TICK
				simulation.advance_tick()
			DepartmentSimulationScript.ShiftPhase.AWAITING_INCIDENT:
				_resolve_free_incident(simulation, failures)
			_:
				failures.append("persistence fixture entered an unexpected phase")
				return
		safety += 1
	_check(simulation.shift_phase == DepartmentSimulationScript.ShiftPhase.REVIEW, "persistence fixture should reach review", failures)


func _resolve_free_incident(simulation: DepartmentSimulation, failures: Array[String]) -> void:
	var decision: Dictionary = simulation.pending_decision_snapshot()
	for option_value in decision.get("options", []):
		var option := option_value as Dictionary
		if int(option.get("cost_cents", 0)) == 0:
			_check(simulation.resolve_decision(int(decision.get("serial", -1)), StringName(option.get("id", &""))), "persistence fixture should resolve its free incident", failures)
			return
	failures.append("persistence fixture should expose a free incident response")


func _json_round_trip(value: Dictionary) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(JSON.stringify(value)) != OK or not parser.data is Dictionary:
		return {}
	return (parser.data as Dictionary).duplicate(true)


func _same_state(expected: Dictionary, actual: Dictionary) -> bool:
	return expected == _json_round_trip(actual)


func _worker_snapshot(snapshot: Dictionary, worker_id: int) -> Dictionary:
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return worker
	return {}


func _approximately(actual: float, expected: float, tolerance: float = 0.0001) -> bool:
	return absf(actual - expected) <= tolerance


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
