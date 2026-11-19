extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _check(condition: bool, copy: String) -> void:
	if not condition:
		failures.append(copy)

func _fixture(day: int) -> DepartmentSimulation:
	var sim := DepartmentSimulation.new(8129, 4)
	sim.day = day
	sim.call("_reset_daily_decision_state")
	sim.call("_prepare_morning_directive")
	_check(sim.select_directive(&"shell_assurance"), "fixture enters a real running shift")
	sim.revenue_cents = 10000
	return sim

func _route(sim: DepartmentSimulation, lane: StringName) -> void:
	var candidates := sim.dispatch_candidates(lane)
	var id := int(candidates[0].worker_id)
	if sim.workers[id].assigned_lane == lane:
		sim.set_worker_assignment(id, DepartmentSimulation.AUTO_ASSIGNMENT)
	_check(bool(sim.dispatch_worker_to_lane(id, lane).get("recommended", false)), "recommended route accepted")

func _seat(sim: DepartmentSimulation) -> void:
	for id in 3:
		sim.set_worker_at_workstation(id, true)
	sim.advance_tick()

func _peck(sim: DepartmentSimulation, id: int) -> void:
	sim.workers[id].work_progress = 62.0
	_check(bool(sim.perform_peck_assist(id).get("accepted", false)), "timed Peck accepted")

func _finish(sim: DepartmentSimulation, id: int, low_roll: bool = false) -> void:
	var rng := sim.get("_rng") as RandomNumberGenerator
	for seed_value in range(1, 10000):
		rng.seed = seed_value
		var roll := rng.randf()
		if (roll < 0.001 if low_roll else roll > 0.9):
			rng.seed = seed_value
			break
	sim.call("_complete_egg", sim.workers[id])

func _run() -> void:
	_check(CareerWorkshop.contract_for(1, "fast") == "fit_three", "first shift stays simple")
	_check(CareerWorkshop.contract_for(2, "fast") == "route_circuit", "second shift unlocks a new routing goal")
	_check(CareerWorkshop.contract_for(3, "safe") == "precision_pair", "third shift unlocks assisted production")
	_check(CareerWorkshop.contract_for(4, "flock") == "flock_relay", "fourth shift unlocks team production")
	_check(CareerWorkshop.contract_for(5, "fast") != CareerWorkshop.contract_for(6, "fast"), "later challenge pairings rotate")
	var sim := _fixture(2)
	sim.perform_playbook_action(&"preset", &"fast", 0)
	for unused in 3:
		_route(sim, &"nest_damage")
	_check(int(sim.playbook_snapshot(0).contract.progress) == 1, "same tray cannot farm the circuit")
	_route(sim, &"predator_loss")
	_route(sim, &"appeals")
	_check(bool(sim.playbook_snapshot(0).contract.complete), "three distinct trays complete the circuit")
	var cash := sim.revenue_cents
	_check(bool(sim.perform_playbook_action(&"reward", &"fund", 0).accepted), "new challenge pays a normal reward")
	_check(sim.career_workshop.stamps == 1 and sim.revenue_cents == cash + 300, "reward also earns a permanent workshop stamp")
	sim.perform_playbook_action(&"reward", &"fund", 0)
	_check(sim.career_workshop.stamps == 1, "duplicate claim cannot farm stamps")
	_check(not bool(sim.perform_playbook_action(&"workshop", &"shell_guard", 0).accepted), "future tools cannot unlock early")
	_check(bool(sim.perform_playbook_action(&"workshop", &"relay_bell", 0).accepted), "stamp buys an unlocked tool")
	_check(sim.career_workshop.equipped.is_empty(), "midshift purchase cannot change a locked loadout")
	sim.day = 3
	sim.call("_reset_daily_decision_state")
	sim.call("_prepare_morning_directive")
	sim.select_directive(&"shell_assurance")
	_check(bool(sim.perform_playbook_action(&"workshop", &"relay_bell", 0).accepted), "owned bell can be equipped next shift without spending cash")
	# Clear the reserve earned by the earlier, independent routing milestone.
	sim.routing_momentum_peck_recharge_bank = 0
	_route(sim, &"nest_damage")
	_check(sim.routing_momentum_peck_recharge_bank == 1, "bell banks a real reserve Peck")
	_seat(sim)
	_peck(sim, 0)
	_check(sim.routing_momentum_peck_recharge_bank == 0, "reserve is consumed by a real intervention")
	# Avoid the existing x3 routing milestone while checking the bell's own limit.
	sim.call("_break_routing_momentum", "fixture", &"test", 0, -1)
	_route(sim, &"nest_damage")
	_check(sim.routing_momentum_peck_recharge_bank == 0, "same lane cannot refill the bell twice")
	_route(sim, &"predator_loss")
	_check(sim.routing_momentum_peck_recharge_bank == 1, "a different tray replenishes attention")
	var restored := DepartmentSimulation.new(91, 4)
	_check(restored.restore_save_state(sim.export_save_state()), "used bell and charge accounting survive reload")
	_check(restored.career_workshop.to_save_data() == sim.career_workshop.to_save_data(), "ownership, loadout, and used lanes persist exactly")
	_check(restored.restore_save_state(JSON.parse_string(JSON.stringify(sim.export_save_state()))), "browser JSON round-trip restores typed workshop state")
	var lens := _fixture(3)
	lens.career_workshop.award(1)
	lens.perform_playbook_action(&"workshop", &"shell_guard", 0)
	lens.perform_playbook_action(&"preset", &"safe", 0)
	_seat(lens)
	var egg_qualities: Array[StringName] = []
	lens.egg_laid.connect(func(_id: int, quality: StringName, _value: int): egg_qualities.append(quality))
	for id in 2:
		_peck(lens, id)
	_check(lens.career_workshop.protected_claims.size() == 2, "lens protects exactly two stamped files")
	_check(lens.estimated_crack_risk(0) == 0.0 and String(lens.last_peck_assist.get("workshop_effect", "")).contains("PROTECTED"), "risk forecast and action receipt explain the active protection")
	var lens_save := lens.export_save_state()
	var lens_restore := DepartmentSimulation.new(92, 4)
	_check(lens_restore.restore_save_state(lens_save) and lens_restore.career_workshop.protected_claims.size() == 2, "pending protections survive reload")
	for id in 2:
		_finish(lens, id, true)
	_check(egg_qualities.size() == 2 and &"cracked" not in egg_qualities, "protected files cannot crack even on a losing random roll")
	_check(bool(lens.playbook_snapshot(0).contract.complete), "two actual assisted clean eggs earn Precision Pair")
	_peck(lens, 2)
	_check(lens.career_workshop.protected_claims.is_empty() and lens.career_workshop.uses == 2, "third Peck gets no extra lens protection")
	var kettle := _fixture(4)
	kettle.career_workshop.award(1)
	kettle.perform_playbook_action(&"workshop", &"team_kettle", 0)
	kettle.perform_playbook_action(&"preset", &"flock", 0)
	_seat(kettle)
	for worker in kettle.workers:
		worker.stress = 20.0
		worker.fatigue = 20.0
	_peck(kettle, 0)
	var progress_before := kettle.workers[0].work_progress
	var stress_before := kettle.workers[0].stress
	_peck(kettle, 1)
	_check(is_equal_approx(kettle.workers[0].work_progress, minf(99.0, progress_before + 10.0)) and is_equal_approx(kettle.workers[0].stress, stress_before - 4.0), "alternating Pecks advances and recovers the previous hen")
	_check(kettle.career_workshop.uses == 1 and kettle.workers[1].fatigue == 16.0, "both hens benefit from one relay")
	kettle.career_workshop.uses = 3
	var previous_progress := kettle.workers[1].work_progress
	_peck(kettle, 2)
	_check(kettle.workers[1].work_progress == previous_progress and kettle.career_workshop.uses == 3, "kettle cannot grant a fourth relay")
	for id in 3:
		_finish(kettle, id)
	_check(bool(kettle.playbook_snapshot(0).contract.complete), "three actual clean hens earn Flock Relay")
	var bad := sim.export_save_state()
	bad.career_workshop.stamps = -1
	var before_bad := JSON.stringify(restored.export_save_state())
	_check(not restored.restore_save_state(bad), "invalid workshop cannot load")
	_check(JSON.stringify(restored.export_save_state()) == before_bad, "failed restore is atomic")
	var legacy := sim.export_save_state()
	legacy.erase("career_workshop")
	_check(DepartmentSimulation.new(93, 4).restore_save_state(legacy), "existing careers without a workshop remain loadable")
	sim.day = 4
	sim.call("_reset_daily_decision_state")
	_check(sim.career_workshop.owned.has("relay_bell") and sim.career_workshop.equipped == "relay_bell" and sim.career_workshop.bell_lanes.is_empty() and not sim.career_workshop.loadout_locked, "daily reset preserves tools and refreshes their limits")
	var mature := _fixture(5)
	for award_day in [1, 2, 3]:
		mature.career_workshop.award(award_day)
	# Reward accounting is independent of the rotating guided-plan challenge.
	mature.perform_playbook_action(&"contract", &"route_circuit", 0)
	for lane: StringName in [&"nest_damage", &"predator_loss", &"appeals"]:
		_route(mature, lane)
	var mature_cash := mature.revenue_cents
	_check(bool(mature.perform_playbook_action(&"reward", &"fund", 0).accepted) and mature.revenue_cents == mature_cash + 400 and mature.career_workshop.stamps == 3, "fully funded workshop converts future progress to a cash bonus")
	if failures.is_empty():
		print("CAREER_WORKSHOP_TEST_PASSED challenges=3 tools=3 unlocks=staged rotation=daily limits=bounded save=atomic+legacy")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)
