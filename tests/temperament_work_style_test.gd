extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_test_disclosed_work_style_catalog(failures)
	_test_social_work_styles_react_to_authoritative_state(failures)
	_test_work_style_changes_real_pace_risk_and_recovery(failures)
	_test_manual_route_persistence_and_auto_reset(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("TEMPERAMENT_WORK_STYLE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("TEMPERAMENT_WORK_STYLE_TEST_PASSED identities=6 social=2 pace=risk=strain=recovery")
	quit(0)


func _test_disclosed_work_style_catalog(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(21101, 4)
	var workers_snapshot := simulation.snapshot().get("workers", []) as Array
	_check(
		workers_snapshot.size() == ChickenState.TEMPERAMENT_ORDER.size(),
		"the complete roster should publish one work style for each stable temperament",
		failures,
	)
	for worker_id in workers_snapshot.size():
		var worker := workers_snapshot[worker_id] as Dictionary
		var effect := worker.get("temperament_effect", {}) as Dictionary
		for field in [
			"label", "pace_basis_points", "work_multiplier",
			"crack_basis_points", "crack_modifier",
			"strain_basis_points", "strain_multiplier",
			"break_recovery_basis_points", "break_recovery_multiplier",
			"potential_pace_basis_points", "potential_crack_basis_points",
			"potential_strain_basis_points", "potential_break_recovery_basis_points",
			"engaged", "condition", "potential_summary", "summary",
		]:
			_check(
				effect.has(field),
				"worker %d work style should disclose authoritative %s" % [worker_id, field],
				failures,
			)
		_check(
			not String(effect.get("label", "")).is_empty()
			and not String(effect.get("summary", "")).is_empty(),
			"worker %d work style should be readable without reverse engineering multipliers" % worker_id,
			failures,
		)
	var bright := (workers_snapshot[0] as Dictionary).get("temperament_effect", {}) as Dictionary
	_check(
		String(bright.get("label", "")) == "FAST SCAN"
		and not bool(bright.get("engaged", true))
		and int(bright.get("pace_basis_points", -1)) == 0
		and int(bright.get("potential_pace_basis_points", 0)) == 400
		and int(bright.get("potential_crack_basis_points", 0)) == 100
		and int(bright.get("potential_strain_basis_points", 0)) == 10_000,
		"Bright-Eyed should trade exactly +4% pace for +1% shell risk without compounding labor strain",
		failures,
	)
	var cozy := (workers_snapshot[2] as Dictionary).get("temperament_effect", {}) as Dictionary
	_check(
		String(cozy.get("label", "")) == "DEEP PERCH"
		and int(cozy.get("potential_pace_basis_points", 0)) == -200
		and int(cozy.get("potential_break_recovery_basis_points", 0)) == 11_500,
		"Cozy Nester should disclose the exact slower-pace and stronger-recovery tradeoff",
		failures,
	)
	var methodical := (workers_snapshot[4] as Dictionary).get("temperament_effect", {}) as Dictionary
	_check(
		String(methodical.get("label", "")) == "DOUBLE CHECK"
		and int(methodical.get("potential_pace_basis_points", 0)) == -500
		and int(methodical.get("potential_crack_basis_points", 0)) == -250
		and "APPLICANT PREVIEW" in String(methodical.get("summary", "")),
		"Methodical Pecker applicants should disclose their exact pace-for-safety tradeoff before hiring",
		failures,
	)


func _test_social_work_styles_react_to_authoritative_state(
	failures: Array[String],
) -> void:
	var networker := DepartmentSimulation.new(21102, 4)
	_check(
		networker.set_worker_assignment(3, &"nest_damage"),
		"the networker fixture should accept a deliberate manual route",
		failures,
	)
	networker.solidarity = 90.0
	for worker in networker.workers:
		if not worker.employed:
			continue
		worker.morale = 100.0
		worker.stress = 0.0
		worker.fatigue = 0.0
		worker.grievance = 0.0
	var supported := networker.worker_temperament_effect(3)
	_check(
		int(supported.get("pace_basis_points", 0)) == 400
		and int(supported.get("strain_basis_points", 0)) == 9_700
		and String(supported.get("condition", "")) == "bond score 60+",
		"Perch-Side Networker should gain exact pace and strain benefits from a supported named bond",
		failures,
	)
	networker.solidarity = 0.0
	for worker in networker.workers:
		if not worker.employed:
			continue
		worker.morale = 0.0
		worker.stress = 100.0
		worker.fatigue = 100.0
		worker.grievance = 0.0
	var withdrawn := networker.worker_temperament_effect(3)
	_check(
		int(withdrawn.get("pace_basis_points", 0)) == -400
		and int(withdrawn.get("strain_basis_points", 0)) == 10_000
		and String(withdrawn.get("condition", "")) == "bond score below 30",
		"Perch-Side Networker should visibly slow under a collapsed named bond",
		failures,
	)

	var rebel := DepartmentSimulation.new(21103, 4)
	rebel.workers[5].employed = true
	_check(
		rebel.set_worker_assignment(5, &"nest_damage"),
		"the rebel fixture should accept a deliberate manual route",
		failures,
	)
	rebel.solidarity = 70.0
	var united := rebel.worker_temperament_effect(5)
	rebel.solidarity = 20.0
	var divided := rebel.worker_temperament_effect(5)
	_check(
		int(united.get("pace_basis_points", 0)) == 400
		and int(united.get("strain_basis_points", 0)) == 9_500,
		"Gentle Rebel should work faster and take less strain when flock solidarity is high",
		failures,
	)
	_check(
		int(divided.get("pace_basis_points", 0)) == -400
		and int(divided.get("strain_basis_points", 0)) == 10_000,
		"Gentle Rebel should disclose the exact cost of a divided flock",
		failures,
	)


func _test_work_style_changes_real_pace_risk_and_recovery(
	failures: Array[String],
) -> void:
	var simulation := DepartmentSimulation.new(21104, 4)
	for worker_id in [0, 4]:
		var worker := simulation.workers[worker_id]
		worker.employed = true
		worker.desk_index = worker_id
		worker.skill = 1.0
		worker.accuracy = 0.90
		worker.morale = 80.0
		worker.fatigue = 10.0
		worker.stress = 10.0
		worker.manager_trust = 50.0
		worker.grievance = 0.0
		worker.career_xp = 0
		worker.work_state = ChickenState.WorkState.WORKING
		worker.work_progress = 0.0
		worker.current_claim = null
		_check(
			simulation.set_worker_assignment(worker_id, &"nest_damage"),
			"worker %d should accept a deliberate manual route" % worker_id,
			failures,
		)
		simulation.set_worker_at_workstation(worker_id, true)
	var bright := simulation.workers[0]
	var methodical := simulation.workers[4]
	var bright_risk := simulation._error_risk_for(bright)
	var methodical_risk := simulation._error_risk_for(methodical)
	simulation._update_worker(bright)
	simulation._update_worker(methodical)
	_check(
		_approximately(
			bright.work_progress / methodical.work_progress,
			1.04 / 0.95,
		),
		"Fast Scan and Double Check should multiply real claim pace exactly once",
		failures,
	)
	_check(
		_approximately(bright_risk - methodical_risk, 0.035),
		"the disclosed +1% versus -2.5% shell-risk tradeoff should reach egg grading",
		failures,
	)
	_check(
		_approximately(
			(bright.fatigue - 10.0) / (methodical.fatigue - 10.0),
			1.0 / 0.97,
		),
		"temperament strain should multiply real fatigue gain exactly once",
		failures,
	)

	var cozy_simulation := DepartmentSimulation.new(21105, 4)
	var cozy := cozy_simulation.workers[2]
	cozy.work_state = ChickenState.WorkState.BREAK
	_check(
		cozy_simulation.set_worker_assignment(2, &"nest_damage"),
		"the cozy fixture should accept a deliberate manual route",
		failures,
	)
	cozy.state_ticks_remaining = 5
	cozy.fatigue = 50.0
	cozy.stress = 50.0
	cozy.morale = 50.0
	cozy_simulation._update_worker(cozy)
	_check(
		_approximately(cozy.fatigue, 47.7)
		and _approximately(cozy.stress, 48.39),
		"Deep Perch should apply its disclosed +15% recovery to real break fatigue and stress",
		failures,
	)


func _test_manual_route_persistence_and_auto_reset(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(21106, 4)
	_check(
		simulation.set_worker_assignment(0, &"nest_damage"),
		"a manual route should be accepted before persistence",
		failures,
	)
	var saved := simulation.workers[0].to_save_data()
	var restored := ChickenState.new(0, "Restored Hen", 0, 1.0, 0.9)
	_check(
		restored.apply_save_data(saved)
		and restored.assigned_lane == &"nest_damage"
		and restored.manually_routed,
		"a deliberate route should preserve its work-style engagement through save/load",
		failures,
	)
	_check(
		simulation.set_worker_assignment(0, &"auto")
		and not simulation.workers[0].manually_routed
		and not bool(simulation.worker_temperament_effect(0).get("engaged", true)),
		"returning to AUTO should clear work-style engagement immediately",
		failures,
	)
	var legacy := saved.duplicate(true)
	legacy.erase("manually_routed")
	var legacy_restored := ChickenState.new(0, "Legacy Hen", 0, 1.0, 0.9)
	_check(
		legacy_restored.apply_save_data(legacy)
		and not legacy_restored.manually_routed,
		"older saves should retain their assignment without silently enabling a new modifier",
		failures,
	)


func _approximately(
	actual: float,
	expected: float,
	tolerance: float = 0.0001,
) -> bool:
	return absf(actual - expected) <= tolerance


func _check(
	condition: bool,
	message: String,
	failures: Array[String],
) -> void:
	if not condition:
		failures.append(message)
