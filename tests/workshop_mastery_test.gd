extends "res://tests/workshop_tactics_test.gd"


func next_day(sim: DepartmentSimulation, day: int) -> DepartmentSimulation:
	# Stage the next day's work queue independently; carry earned workshop state
	# through its real JSON boundary instead of skipping unrelated daily ledgers.
	var next := fixture(day)
	next.career_workshop = CareerWorkshop.from_save_data(JSON.parse_string(JSON.stringify(sim.career_workshop.to_save_data())), day, 4)
	check(next.career_workshop != null, "earned workshop survives the next shift")
	next.career_workshop.begin_day(day)
	return next


func _run() -> void:
	for path in [["fast", "relay_bell", "handoff"], ["safe", "shell_guard", "triage"], ["flock", "team_kettle", "encourage"]]:
		check(CareerWorkshop.contract_for(5, path[0], path[1], path[2]) != CareerWorkshop.contract_for(6, path[0], path[1], path[2]), "mastered tools retain day-to-day challenge variety")
	var bell := fixture(2, "relay_bell")
	check(not bell.perform_playbook_action(&"workshop", &"relay_bell/handoff", 0).accepted, "mastery cannot be bought or selected early")
	bell.perform_playbook_action(&"preset", &"fast", 0)
	check(not bell.perform_playbook_action(&"reward", &"fund", 0).accepted, "unfinished challenge cannot grant mastery")
	for lane: StringName in [&"nest_damage", &"predator_loss", &"appeals"]:
		var candidate := int(bell.dispatch_candidates(lane)[0].worker_id)
		if bell.workers[candidate].assigned_lane == lane:
			bell.set_worker_assignment(candidate, DepartmentSimulation.AUTO_ASSIGNMENT)
		check(bell.dispatch_worker_to_lane(candidate, lane).accepted, "real route accepted")
	check(bell.playbook_snapshot().contract.complete, "Route Circuit earned")
	check(bell.career_workshop.mastered_tools.is_empty(), "completion previews mastery without granting before reward")
	check(bell.playbook_snapshot().workshop.mastery_offer.id == "handoff", "reward discloses the earned upgrade")
	check(bell.perform_playbook_action(&"reward", &"fund", 0).accepted, "claim grants earned upgrade")
	check(bell.career_workshop.mastered_tools == ["relay_bell"], "tool used in matching challenge is mastered")
	check(not bell.perform_playbook_action(&"reward", &"mastery", 0).accepted, "mastery and reward cannot be claimed twice")
	var restored := DepartmentSimulation.new(8, 4)
	check(restored.restore_save_state(JSON.parse_string(JSON.stringify(bell.export_save_state()))), "earned upgrade survives real JSON save restore")
	check(restored.career_workshop.mastered_tools == ["relay_bell"], "mastery persists")
	restored = next_day(restored, 4)
	var balance := restored.revenue_cents
	check(restored.perform_playbook_action(&"workshop", &"relay_bell/handoff", 0).accepted, "earned mode equips on its unlock shift")
	check(restored.revenue_cents == balance, "retuning is free")
	restored.perform_playbook_action(&"preset", &"fast", 0)
	check(restored.playbook_snapshot().contract.id == "relay_finish", "earlier tool choice changes later challenge")
	seat(restored)
	peck(restored, 0)
	var progress_before := restored.workers[0].work_progress
	peck(restored, 1)
	check(is_equal_approx(restored.workers[0].work_progress, minf(99, progress_before + 18)), "Handoff advances the previous working hen")
	check(restored.playbook_snapshot().contract.progress == 0, "assists alone do not count as finished eggs")
	peck(restored, 2)
	for id in 3: finish(restored, id)
	check(restored.playbook_snapshot().contract.complete, "three distinct assisted clean deliveries finish Relay Finish")
	check(not restored.perform_playbook_action(&"workshop", &"relay_bell", 0).accepted, "mode stays locked after use")
	check(CareerWorkshop.from_save_data(restored.career_workshop.to_save_data(), 4, 4) != null, "Handoff workshop state restores")
	check(DepartmentSimulation.new(8, 4).restore_save_state(restored.export_save_state()), "new progress and Handoff uses restore")

	var lens := fixture(3, "shell_guard")
	lens.perform_playbook_action(&"preset", &"safe", 0)
	seat(lens)
	for id in 2:
		peck(lens, id)
		finish(lens, id)
	check(lens.perform_playbook_action(&"reward", &"fund", 0).accepted, "Precision Pair pays real reward")
	check(lens.career_workshop.mastered_tools == ["shell_guard"], "lens use earns Triage")
	lens = next_day(lens, 4)
	check(lens.perform_playbook_action(&"workshop", &"shell_guard/triage", 0).accepted, "Triage equips after earned mastery")
	lens.perform_playbook_action(&"preset", &"safe", 0)
	check(lens.playbook_snapshot().contract.id == "deadline_rescue", "Triage brings deadline rescue forward")
	seat(lens)
	lens.workers[0].current_claim.deadline_operational_minute = lens.call("_current_operational_minute") + 90
	peck(lens, 0, 54)
	check(lens.career_workshop.uses == 0, "early Peck keeps Triage charge")
	for id in [1, 2]:
		lens.workers[id].current_claim.deadline_operational_minute = lens.call("_current_operational_minute") + 30
		peck(lens, id, 54)
	check(lens.career_workshop.uses == 2 and lens.career_workshop.protected_claims.size() == 2, "two last-hour files receive protection")
	check(DepartmentSimulation.new(8, 4).restore_save_state(lens.export_save_state()), "Triage protections restore before delivery")
	for id in [1, 2]: finish(lens, id, true)
	check(lens.playbook_snapshot().contract.complete and lens.cracked_today == 0, "protected actual deliveries complete rescue")

	var kettle := fixture(4, "team_kettle")
	kettle.perform_playbook_action(&"preset", &"flock", 0)
	seat(kettle)
	peck(kettle, 0)
	peck(kettle, 1)
	for id in 3: finish(kettle, id)
	check(kettle.perform_playbook_action(&"reward", &"recovery", 0).accepted, "Flock Relay reward claimed")
	check(kettle.career_workshop.mastered_tools == ["team_kettle"], "successful kettle relay earns Encourage")
	kettle = next_day(kettle, 5)
	check(kettle.perform_playbook_action(&"workshop", &"team_kettle/encourage", 0).accepted, "earned Encourage equips")
	kettle.perform_playbook_action(&"preset", &"flock", 0)
	check(kettle.playbook_snapshot().contract.id == "care_circle", "Encourage offers Care Circle")
	check(not kettle.perform_playbook_action(&"workshop", &"relay_bell", 0).accepted, "cannot strand a kettle-specific challenge by swapping tools")
	seat(kettle)
	for worker in kettle.workers:
		worker.stress = 30
		worker.fatigue = 30
	peck(kettle, 0)
	var strain_before := kettle.workers[0].stress
	progress_before = kettle.workers[0].work_progress
	peck(kettle, 1)
	check(is_equal_approx(kettle.workers[0].stress, strain_before - 8), "Encourage gives its disclosed relief")
	check(kettle.workers[0].work_progress == progress_before, "Encourage gives up the normal work boost")
	check(kettle.playbook_snapshot().contract.progress == 2, "first real pair supports two hens")
	peck(kettle, 2)
	check(kettle.playbook_snapshot().contract.complete, "distinct hens finish Care Circle")
	finish(kettle, 0)
	peck(kettle, 3)
	check(kettle.career_workshop.uses == 3, "Encourage has three relay charges")
	check(DepartmentSimulation.new(8, 4).restore_save_state(kettle.export_save_state()), "Care Circle progress restores")
	check(kettle.perform_playbook_action(&"reward", &"fund", 0).accepted, "Care Circle pays its reward")
	check(kettle.perform_playbook_action(&"workshop", &"relay_bell", 0).accepted, "locked kettle can still fund a different tool for tomorrow")
	check(kettle.career_workshop.equipped == "team_kettle", "buying tomorrow's tool cannot remove today's kettle")
	var bad := kettle.export_save_state()
	bad.career_workshop.mastered_tools = []
	check(not DepartmentSimulation.new(8, 4).restore_save_state(bad), "unearned mastery mode rejected on restore")
	bad = kettle.export_save_state()
	bad.career_workshop.relief_workers.append(bad.career_workshop.relief_workers[0])
	check(not DepartmentSimulation.new(8, 4).restore_save_state(bad), "duplicate progress rejected")
	var legacy := fixture(3, "shell_guard").export_save_state()
	for field in ["mastered_tools", "assisted_workers", "relief_workers"]: legacy.career_workshop.erase(field)
	check(DepartmentSimulation.new(8, 4).restore_save_state(legacy), "old saves preserve their existing standard tools")
	var no_use := fixture(3, "shell_guard")
	no_use.career_workshop.award(3, "precision_pair")
	check(no_use.career_workshop.mastered_tools.is_empty(), "unused tools do not earn mastery")

	kettle = next_day(kettle, 6)
	var ui := ShiftChallengeUI.new()
	root.add_child(ui)
	ui.show_choices("workshop", kettle.career_workshop.catalog(6, true), "Mabel", {}, kettle.career_workshop.snapshot(6))
	ui.call("_select", 2)
	ui.call("_toggle_tuning")
	check(ui.snapshot().tuning == "standard", "earned mode cycles back to standard")
	ui.call("_toggle_tuning")
	check(ui.snapshot().tuning == "mentor", "old alternate mode remains available")
	ui.call("_toggle_tuning")
	check(ui.snapshot().tuning == "encourage", "earned third mode is previewable")
	ui.free()
	await process_frame
	for failure in failures: push_error(failure)
	print("WORKSHOP_MASTERY_TEST_%s" % ("PASSED" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)
