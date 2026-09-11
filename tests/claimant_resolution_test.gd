extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	_test_claimant_context_and_disclosed_paths(failures)
	_test_path_cost_lock_and_persistence(failures)
	_test_denial_returns_as_named_appeal(failures)
	_test_resolution_modifiers_reach_real_work_and_risk(failures)
	_test_lane_operational_tradeoffs(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("CLAIMANT_RESOLUTION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print(
		"CLAIMANT_RESOLUTION_TEST_PASSED context=3 paths=3 "
		+ "denial=next-shift-appeal persistence=locked causal=pace+risk",
	)
	quit(0)


func _test_claimant_context_and_disclosed_paths(
	failures: Array[String],
) -> void:
	var simulation := DepartmentSimulation.new(23101)
	var snapshot := simulation.snapshot()
	var queue_items := snapshot.get("claim_queue_items", {}) as Dictionary
	for lane in DepartmentSimulation.CLAIM_LANES:
		var items := queue_items.get(lane, []) as Array
		_check(not items.is_empty(), "%s should expose a claimant file" % lane, failures)
		if items.is_empty():
			continue
		var claim := items[0] as Dictionary
		for field in [
			"claimant_profile_id",
			"claimant_name",
			"claimant_incident",
			"claimant_need",
			"claimant_delay_cost",
		]:
			_check(
				not String(claim.get(field, "")).is_empty(),
				"%s should disclose claimant %s" % [lane, field],
				failures,
			)
	var catalog := simulation.claim_resolution_catalog()
	_check(catalog.size() == 4, "the default and three explicit paths must be disclosed", failures)
	var expected := {
		&"settle": [120, 10_000, -300, "CLAIMANT"],
		&"deny": [0, 11_200, 400, "BUREAU"],
		&"exception": [60, 9_400, -500, "CLAIMANT"],
	}
	for path_id in expected:
		var row := _catalog_row(catalog, path_id)
		var terms := expected[path_id] as Array
		_check(
			int(row.get("cost_cents", -1)) == int(terms[0])
			and int(row.get("work_basis_points", -1)) == int(terms[1])
			and int(row.get("crack_basis_points", -9999)) == int(terms[2])
			and String(row.get("beneficiary", "")) == String(terms[3])
			and not String(row.get("benefit", "")).is_empty()
			and not String(row.get("burden", "")).is_empty(),
			"%s should disclose exact money, beneficiary, benefit, and burden" % path_id,
			failures,
		)
	for lane_row in simulation.routing_catalog():
		_check(
			not String(lane_row.get("operational_tradeoff", "")).is_empty(),
			"%s should disclose an operational identity beyond value, deadline, and risk" % lane_row.get("id", ""),
			failures,
		)


func _test_path_cost_lock_and_persistence(failures: Array[String]) -> void:
	var simulation := _working_simulation(23102, 1, &"nest_damage", failures)
	var worker := simulation.workers[1]
	if worker.current_claim == null:
		return
	var opening_fund := simulation.revenue_cents
	var receipt := simulation.set_claim_resolution(1, &"settle")
	_check(bool(receipt.get("accepted", false)), "a timely settlement should file", failures)
	_check(
		simulation.revenue_cents == opening_fund - 120,
		"settlement should charge its disclosed $1.20 exactly once",
		failures,
	)
	_check(
		not bool(simulation.set_claim_resolution(1, &"deny").get("accepted", true))
		and simulation.revenue_cents == opening_fund - 120,
		"a filed claimant path should be immutable and never double-charge",
		failures,
	)
	var saved := simulation.export_save_state()
	var restored := DepartmentSimulation.new(99991)
	_check(restored.restore_save_state(saved), "a claimant-path checkpoint should restore", failures)
	var restored_claim := restored.workers[1].current_claim
	_check(
		restored_claim != null
		and restored_claim.resolution_path == &"settle"
		and restored_claim.resolution_locked
		and restored_claim.resolution_cost_cents == 120
		and restored_claim.claimant_profile_id == worker.current_claim.claimant_profile_id,
		"save/load should preserve claimant identity, locked path, and sunk cost",
		failures,
	)
	var tampered := saved.duplicate(true)
	var tampered_workers := tampered.get("workers", []) as Array
	var tampered_worker := tampered_workers[1] as Dictionary
	var tampered_claim := tampered_worker.get("current_claim", {}) as Dictionary
	tampered_claim["resolution_cost_cents"] = 99_999
	var normalized := DepartmentSimulation.new(99992)
	_check(
		normalized.restore_save_state(tampered)
		and normalized.workers[1].current_claim != null
		and normalized.workers[1].current_claim.resolution_cost_cents == 120,
		"restore should derive the sunk cost from the stable path instead of trusting tampered money",
		failures,
	)


func _test_denial_returns_as_named_appeal(failures: Array[String]) -> void:
	var simulation := _working_simulation(23103, 1, &"nest_damage", failures)
	var worker := simulation.workers[1]
	if worker.current_claim == null:
		return
	var source_claim_id := worker.current_claim.id
	var claimant_profile_id := worker.current_claim.claimant_profile_id
	var compliance_before := simulation.compliance
	var confidence_before := simulation.executive_confidence
	_check(
		bool(simulation.set_claim_resolution(1, &"deny").get("accepted", false)),
		"a timely fast denial should file",
		failures,
	)
	worker.accuracy = 0.999
	worker.stress = 0.0
	worker.fatigue = 0.0
	(simulation.get("_rng") as RandomNumberGenerator).seed = _sound_seed()
	worker.work_state = ChickenState.WorkState.LAYING
	worker.state_ticks_remaining = 1
	simulation.advance_tick()
	var pending := simulation.get("_pending_rework") as Array
	var appeal: ClaimState
	for claim_value in pending:
		var claim := claim_value as ClaimState
		if claim != null and claim.source_claim_id == source_claim_id:
			appeal = claim
			break
	_check(appeal != null, "a clean denial should create one delayed claimant appeal", failures)
	if appeal != null:
		_check(
			appeal.lane == &"appeals"
			and appeal.is_claimant_follow_up
			and appeal.available_day == simulation.day + 1
			and appeal.claimant_profile_id == claimant_profile_id
			and "CLAIMANT APPEAL" in appeal.display_name,
			"the next-shift appeal should retain the named claimant and source file",
			failures,
		)
	_check(
		is_equal_approx(simulation.compliance, compliance_before - 1.0),
		"the fast denial should apply its audit-order cost",
		failures,
	)
	_check(
		simulation.executive_confidence >= confidence_before + 0.5,
		"the bureau should receive the denial's immediate presentation benefit",
		failures,
	)
	simulation.day += 1
	simulation.call("_release_due_rework")
	var released := false
	for item_value in (
		(simulation.snapshot().get("claim_queue_items", {}) as Dictionary)
		.get(&"appeals", []) as Array
	):
		var item := item_value as Dictionary
		if int(item.get("source_claim_id", -1)) == source_claim_id:
			released = bool(item.get("is_claimant_follow_up", false))
			break
	_check(released, "the named appeal should visibly enter tomorrow's Appeals tray", failures)


func _test_resolution_modifiers_reach_real_work_and_risk(
	failures: Array[String],
) -> void:
	var deny := _working_simulation(23104, 1, &"nest_damage", failures)
	var exception := _working_simulation(23104, 1, &"nest_damage", failures)
	if deny.workers[1].current_claim == null or exception.workers[1].current_claim == null:
		return
	for simulation_value in [deny, exception]:
		var simulation := simulation_value as DepartmentSimulation
		var worker := simulation.workers[1] as ChickenState
		worker.skill = 1.0
		worker.accuracy = 0.90
		worker.morale = 80.0
		worker.fatigue = 10.0
		worker.stress = 10.0
		worker.work_progress = 0.0
	_check(bool(deny.set_claim_resolution(1, &"deny").get("accepted", false)), "deny pace fixture should file", failures)
	_check(bool(exception.set_claim_resolution(1, &"exception").get("accepted", false)), "exception pace fixture should file", failures)
	var deny_risk := deny.estimated_crack_risk(1)
	var exception_risk := exception.estimated_crack_risk(1)
	deny.call("_update_worker", deny.workers[1])
	exception.call("_update_worker", exception.workers[1])
	_check(
		is_equal_approx(
			deny.workers[1].work_progress / exception.workers[1].work_progress,
			1.12 / 0.94,
		),
		"the disclosed denial-versus-exception pace tradeoff should reach real peckwork once",
		failures,
	)
	_check(
		is_equal_approx(
			float(deny.call(
				"_claim_resolution_crack_modifier",
				deny.workers[1].current_claim,
			))
			- float(exception.call(
				"_claim_resolution_crack_modifier",
				exception.workers[1].current_claim,
			)),
			0.09,
		)
		and deny_risk > exception_risk,
		"the exact +4% versus -5% modifier should reach grading before its safe 2% floor",
		failures,
	)


func _test_lane_operational_tradeoffs(failures: Array[String]) -> void:
	var nest := DepartmentSimulation.new(23105)
	var predator := DepartmentSimulation.new(23105)
	for fixture_value in [
		{"simulation": nest, "lane": &"nest_damage"},
		{"simulation": predator, "lane": &"predator_loss"},
	]:
		var fixture := fixture_value as Dictionary
		var simulation := fixture.get("simulation") as DepartmentSimulation
		var worker := simulation.workers[1]
		worker.skill = 1.0
		worker.accuracy = 0.9
		worker.morale = 80.0
		worker.fatigue = 10.0
		worker.stress = 10.0
		worker.work_state = ChickenState.WorkState.WORKING
		worker.work_progress = 0.0
		worker.current_claim = ClaimState.new(
			9500,
			StringName(fixture.get("lane", &"nest_damage")),
			"LANE EFFECT FIXTURE",
			1.0,
			400,
			0.0,
			0,
			360,
			360,
			false,
			-1,
			1,
			0,
			&"",
			&"settle",
			true,
			120,
		)
		simulation.set_worker_at_workstation(1, true)
	nest.call("_update_worker", nest.workers[1])
	predator.call("_update_worker", predator.workers[1])
	_check(
		is_equal_approx(
			(predator.workers[1].stress - 10.0)
			/ (nest.workers[1].stress - 10.0),
			1.25,
		),
		"Predator Loss claimant paths should apply the disclosed 25% trauma load to real stress gain",
		failures,
	)

	var outcome := DepartmentSimulation.new(23106)
	var worker := outcome.workers[1]
	var nest_claim := ClaimState.new(
		9600,
		&"nest_damage",
		"NEST OUTCOME",
		1.0,
		400,
		0.0,
		0,
		360,
		360,
		false,
		-1,
		1,
		0,
		&"",
		&"settle",
		true,
		120,
	)
	worker.morale = 50.0
	outcome.call("_apply_claim_lane_outcome", nest_claim, worker, &"sound")
	_check(
		is_equal_approx(worker.morale, 50.6),
		"clean Nest Damage paths should restore the disclosed +0.6 handler morale",
		failures,
	)
	var appeal_claim := ClaimState.new(
		9601,
		&"appeals",
		"APPEAL OUTCOME",
		1.0,
		800,
		0.0,
		0,
		360,
		360,
		false,
		-1,
		1,
		0,
		&"",
		&"exception",
		true,
		60,
	)
	outcome.compliance = 50.0
	outcome.call("_apply_claim_lane_outcome", appeal_claim, worker, &"sound")
	_check(
		is_equal_approx(outcome.compliance, 50.7),
		"clean Appeals paths should add the disclosed +0.7 audit order",
		failures,
	)
	outcome.compliance = 50.0
	outcome.call("_apply_claim_lane_outcome", appeal_claim, worker, &"cracked")
	_check(
		is_equal_approx(outcome.compliance, 49.0),
		"cracked Appeals paths should lose the disclosed extra 1.0 audit order",
		failures,
	)


func _working_simulation(
	seed: int,
	worker_id: int,
	lane: StringName,
	failures: Array[String],
) -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(seed)
	_check(simulation.set_worker_assignment(worker_id, lane), "fixture route should file", failures)
	simulation.set_worker_at_workstation(worker_id, true)
	_check(simulation.select_directive(&"shell_assurance"), "fixture shift should start", failures)
	simulation.advance_tick()
	_check(
		simulation.workers[worker_id].current_claim != null,
		"fixture hen should hold an active claimant file",
		failures,
	)
	return simulation


func _catalog_row(catalog: Array[Dictionary], path_id: StringName) -> Dictionary:
	for row in catalog:
		if StringName(row.get("id", &"")) == path_id:
			return row
	return {}


func _sound_seed() -> int:
	for seed in 10_000:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		if rng.randf() > 0.95 and rng.randf() > 0.08:
			return seed
	return 9999


func _check(
	condition: bool,
	message: String,
	failures: Array[String],
) -> void:
	if not condition:
		failures.append(message)
