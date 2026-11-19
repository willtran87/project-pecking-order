extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func fixture(day: int, tool: String = "") -> DepartmentSimulation:
	var sim := DepartmentSimulation.new(8129, 4)
	sim.day = day
	sim.call("_reset_daily_decision_state")
	sim.call("_prepare_morning_directive")
	sim.select_directive(&"shell_assurance")
	sim.revenue_cents = 10000
	if not tool.is_empty():
		sim.career_workshop.award(1)
		check(sim.perform_playbook_action(&"workshop", StringName(tool), 0).accepted, "tool equips: " + tool)
	return sim

func seat(sim: DepartmentSimulation) -> void:
	for worker in sim.workers: sim.set_worker_at_workstation(worker.id, true)
	sim.advance_tick()

func peck(sim: DepartmentSimulation, id: int, progress: float = 62.0) -> Dictionary:
	sim.workers[id].work_progress = progress
	var result := sim.perform_peck_assist(id)
	check(bool(result.accepted), "real Peck accepted: %s" % result.get("reason", ""))
	return result

func finish(sim: DepartmentSimulation, id: int, cracked: bool = false) -> void:
	var claim_id := sim.workers[id].current_claim.id
	var qualities: Array[StringName] = []
	var landed := func(_id: int, quality: StringName, _value: int): qualities.append(quality)
	sim.egg_laid.connect(landed)
	var rng := sim.get("_rng") as RandomNumberGenerator
	for seed_value in range(1, 10000):
		rng.seed = seed_value
		var roll := rng.randf()
		if roll < 0.001 if cracked else roll > 0.9:
			rng.seed = seed_value
			break
	sim.call("_complete_egg", sim.workers[id])
	sim.egg_laid.disconnect(landed)
	if not qualities.is_empty(): sim.settle_peck_assist_delivery(claim_id, qualities[0])

func _run() -> void:
	var configurable := fixture(3, "relay_bell")
	var tuning_cash := configurable.revenue_cents
	check(configurable.perform_playbook_action(&"workshop", &"relay_bell/sprint", 0).accepted, "owned tools can change mode before work")
	check(configurable.perform_playbook_action(&"workshop", &"relay_bell", 0).accepted, "standard mode remains a real alternative")
	check(configurable.career_workshop.owned.size() == 1 and configurable.career_workshop.stamps == 0 and configurable.revenue_cents == tuning_cash, "retuning does not repurchase or duplicate the tool")
	check(not configurable.perform_playbook_action(&"workshop", &"relay_bell/precision", 0).accepted, "a tuning cannot be applied to another tool")
	var sprint := fixture(3, "relay_bell/sprint")
	var standard := fixture(3, "relay_bell")
	seat(sprint)
	seat(standard)
	var normal_peck := peck(standard, 0)
	var sprint_peck := peck(sprint, 0)
	check(is_equal_approx(sprint_peck.progress_gain, normal_peck.progress_gain + 10), "Sprint trades extra strain for actual work")
	check(is_equal_approx(sprint.workers[0].stress, standard.workers[0].stress + 3), "Sprint charges its disclosed stress cost")
	check(not sprint.perform_playbook_action(&"workshop", &"relay_bell", 0).accepted, "cannot evade locked mode after using it")
	finish(sprint, 0)
	for id in [1, 2, 3]: peck(sprint, id)
	check(sprint.career_workshop.uses == 3, "Sprint is capped at three interventions")
	var early := fixture(2, "relay_bell")
	check(not early.perform_playbook_action(&"workshop", &"relay_bell/sprint", 0).accepted, "tuning unlock day enforced")
	var precision := fixture(4, "shell_guard/precision")
	seat(precision)
	var strong := peck(precision, 0, 54)
	check(strong.rating == &"strong" and precision.career_workshop.uses == 0 and precision.career_workshop.protected_claims.is_empty(), "Precision does not protect a merely strong Peck or consume a lens charge")
	finish(precision, 0)
	for id in [1, 2, 3]: peck(precision, id)
	check(precision.career_workshop.protected_claims.size() == 3, "Precision protects three real perfect-Peck files")
	var restored := DepartmentSimulation.new(1, 4)
	check(restored.restore_save_state(JSON.parse_string(JSON.stringify(precision.export_save_state()))), "three pending protections and tuning survive JSON save restore")
	check(restored.career_workshop.tuning == "precision" and restored.career_workshop.protected_claims.size() == 3, "restored mode and charges are exact")
	var cracks := precision.cracked_today
	for id in [1, 2, 3]: finish(precision, id, true)
	check(precision.cracked_today == cracks and precision.career_workshop.protected_claims.is_empty(), "protected files survive actual low-roll completion and spend protections")
	var mentor := fixture(5, "team_kettle/mentor")
	seat(mentor)
	peck(mentor, 0)
	var previous_xp := mentor.workers[0].career_xp
	var previous_stress := mentor.workers[0].stress
	var previous_progress := mentor.workers[0].work_progress
	peck(mentor, 1)
	check(mentor.workers[0].career_xp == previous_xp + 6, "Mentor trains the previous hen")
	check(mentor.workers[0].stress == previous_stress and mentor.workers[0].work_progress == previous_progress, "Mentor replaces rather than stacks recovery and work")
	var mixed := fixture(5)
	mixed.perform_playbook_action(&"preset", &"fast", 0)
	check(mixed.playbook_snapshot().contract.id == "mixed_basket", "fifth-shift plan offers a production-diversity challenge")
	seat(mixed)
	for id in 3: finish(mixed, id)
	check(mixed.career_workshop.clean_lanes.size() == 3 and mixed.playbook_snapshot().contract.complete, "three actual file types complete Mixed Basket")
	var rescue := fixture(5)
	rescue.perform_playbook_action(&"preset", &"safe", 0)
	seat(rescue)
	for id in 3:
		rescue.workers[id].current_claim.deadline_operational_minute = rescue.call("_current_operational_minute") + 30
		peck(rescue, id)
	check(rescue.playbook_snapshot().contract.progress == 0, "rescue Pecks alone award no finished eggs")
	rescue.workers[2].current_claim.deadline_operational_minute = rescue.call("_current_operational_minute") - 1
	finish(rescue, 2)
	check(rescue.playbook_snapshot().contract.progress == 0, "late eggs do not count as rescues")
	var saved_rescue := rescue.export_save_state()
	check(restored.restore_save_state(saved_rescue) and restored.career_workshop.rescue_claims.size() == 2, "pending rescue opportunities survive reload")
	finish(rescue, 0)
	finish(rescue, 1)
	check(rescue.playbook_snapshot().contract.complete, "two clean on-time assisted files complete Deadline Rescue")
	var fund := rescue.revenue_cents
	check(rescue.perform_playbook_action(&"reward", &"fund", 0).accepted, "new challenge earns a real reward")
	check(rescue.revenue_cents == fund + 300 and rescue.career_workshop.stamps == 1, "challenge grants disclosed cash and stamp")
	check(not rescue.perform_playbook_action(&"reward", &"fund", 0).accepted, "reward cannot be claimed twice")
	var coaching := fixture(5)
	coaching.perform_playbook_action(&"preset", &"flock", 0)
	seat(coaching)
	for id in 3: peck(coaching, id)
	check(coaching.playbook_snapshot().contract.complete, "three different coached hens complete the team challenge")
	var old := standard.export_save_state()
	for field in ["tuning", "clean_lanes", "coached_workers", "rescue_claims", "rescued_clean"]: old.career_workshop.erase(field)
	check(restored.restore_save_state(old) and restored.career_workshop.tuning == "standard", "old careers retain standard tool behavior")
	var before := JSON.stringify(restored.export_save_state())
	var bad := precision.export_save_state()
	bad.career_workshop.tuning = "mentor"
	check(not restored.restore_save_state(bad) and JSON.stringify(restored.export_save_state()) == before, "invalid tool/mode pair rejects atomically")
	var next := coaching.career_workshop
	next.begin_day(6)
	check(next.coached_workers.is_empty() and next.rescue_claims.is_empty() and next.uses == 0, "daily opportunities reset without replaying earned rewards")
	if failures.is_empty(): print("WORKSHOP_TACTICS_TEST_PASSED modes=3 tradeoffs=real challenges=3 saves=legacy+atomic limits=bounded")
	for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
