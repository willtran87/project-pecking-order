extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func fixture() -> DepartmentSimulation:
	var sim := DepartmentSimulation.new(8129, 4)
	sim.select_directive(&"shell_assurance")
	sim.revenue_cents = 10000
	for worker in sim.workers:
		sim.set_worker_at_workstation(worker.id, true)
	sim.advance_tick()
	return sim

func finish(sim: DepartmentSimulation, id: int, cracked: bool = false) -> void:
	var rng := sim.get("_rng") as RandomNumberGenerator
	for seed_value in range(1, 10000):
		rng.seed = seed_value
		var roll := rng.randf()
		if roll < 0.001 if cracked else roll > 0.9:
			rng.seed = seed_value
			break
	sim.call("_complete_egg", sim.workers[id])

func befriend(sim: DepartmentSimulation, a: int, b: int) -> void:
	for kind in ["shared_break", "shared_credit", "shared_shift"]:
		sim.flock_relationships.record(a, b, kind, sim.day)

func rival(sim: DepartmentSimulation) -> void:
	sim.flock_relationships.record(0, 1, "quota_comparison", sim.day)

func _run() -> void:
	var friends := fixture()
	# Non-neighbours are intentional: player-selected friendships also pay off.
	befriend(friends, 0, 2)
	var receipts: Array[Dictionary] = []
	friends.pair_reward_earned.connect(func(r: Dictionary): receipts.append(r))
	finish(friends, 0)
	check(receipts.is_empty() and friends.flock_relationships.pair_reward(0, 2).progress == 1, "one hen cannot earn the pair reward alone")
	var restore := DepartmentSimulation.new(42, 4)
	check(restore.restore_save_state(JSON.parse_string(JSON.stringify(friends.export_save_state()))), "partial clean pair survives JSON save")
	var xp := friends.workers[0].career_xp
	var stress := friends.workers[0].stress
	finish(friends, 2)
	check(receipts.size() == 1 and receipts[0].xp == 2, "real second clean egg earns friend reward")
	check(friends.workers[0].career_xp == xp + 2 and is_equal_approx(friends.workers[0].stress, maxf(0, stress - 3)), "friend gets real XP and relief")
	var saved := friends.export_save_state()
	check(restore.restore_save_state(JSON.parse_string(JSON.stringify(saved))), "earned reward reloads")
	var exact := JSON.stringify(restore.export_save_state())
	restore.call("_award_clean_pair", restore.workers[0], restore.workers[2])
	check(JSON.stringify(restore.export_save_state()) == exact, "reload cannot award pair twice")
	check(not restore.perform_relationship_action(0, 2, "friendly_contest").accepted, "friends cannot farm contests")
	var old := saved.duplicate(true)
	old.erase("flock_relationships")
	check(restore.restore_save_state(old) and restore.flock_relationships.pairs.is_empty(), "old saves load without invented rewards")
	var invalid := saved.duplicate(true)
	invalid.flock_relationships.daily_counts["0:2:friend_reward"] = 2
	var stable := JSON.stringify(restore.export_save_state())
	check(not restore.restore_save_state(invalid) and stable == JSON.stringify(restore.export_save_state()), "invalid reward ledger is rejected atomically")
	var close := fixture()
	befriend(close, 0, 2)
	for kind in ["team_lift", "clear_air"]: close.flock_relationships.record(0, 2, kind, close.day)
	var close_receipts: Array[Dictionary] = []
	close.pair_reward_earned.connect(func(r: Dictionary): close_receipts.append(r))
	finish(close, 2)
	finish(close, 0)
	check(close_receipts.size() == 1 and close_receipts[0].xp == 4 and close_receipts[0].relief == 5, "inseparable bond improves payoff in either completion order")
	var contest := fixture()
	rival(contest)
	var contest_stress := contest.workers[0].stress
	var contest_xp := contest.workers[0].career_xp
	check(contest.perform_relationship_action(0, 1, "friendly_contest").accepted, "strained pairs can choose fair competition")
	check(is_equal_approx(contest.workers[0].stress, contest_stress + 3) and contest.workers[0].career_xp == contest_xp, "contest charges stress up front without unearned XP")
	var locked := JSON.stringify(contest.export_save_state())
	check(not contest.perform_relationship_action(0, 1, "clear_air").accepted and not contest.perform_relationship_action(0, 1, "friendly_contest").accepted, "contest competes with repair and Team Lift")
	check(JSON.stringify(contest.export_save_state()) == locked, "rejected choices do not mutate")
	var contest_receipts: Array[Dictionary] = []
	contest.pair_reward_earned.connect(func(r: Dictionary): contest_receipts.append(r))
	finish(contest, 0)
	check(contest_receipts.is_empty(), "contest requires both hens")
	var pending := DepartmentSimulation.new(42, 4)
	check(pending.restore_save_state(JSON.parse_string(JSON.stringify(contest.export_save_state()))), "pending contest survives reload")
	check(pending.flock_relationships.pair_reward(0, 1).contest and pending.flock_relationships.pair_reward(0, 1).progress == 1, "contest and progress persist")
	var winner_xp := contest.workers[0].career_xp
	finish(contest, 1)
	check(contest_receipts.size() == 1 and contest_receipts[0].xp == 6 and contest.workers[0].career_xp == winner_xp + 6, "clean contest pays actual XP to both")
	check(contest.flock_relationships.affinity(0, 1) == 0, "shared clean shift and contest reward repair trust")
	check(contest.flock_relationships.pair_reward(0, 1).earned, "earned contest remains recorded after relationship changes")
	var crack := fixture()
	rival(crack)
	crack.perform_relationship_action(0, 1, "friendly_contest")
	finish(crack, 0, true)
	finish(crack, 1)
	check(not crack.flock_relationships.pair_reward(0, 1).earned and crack.flock_relationships.pair_reward(0, 1).progress == 1, "cracked egg cannot count toward contest")
	crack.day += 1
	crack.call("_reset_daily_decision_state")
	check(crack.flock_relationships.clean_workers.is_empty() and not crack.flock_relationships.pair_reward(0, 1).contest, "unfinished contest expires at shift boundary")
	check(crack.flock_relationships.affinity(0, 1) == -10, "unfinished contest causes no hidden trust penalty")
	var late := fixture()
	rival(late)
	finish(late, 0)
	check(not late.perform_relationship_action(0, 1, "friendly_contest").accepted, "cannot start a contest after already completing half")
	var unlock := fixture()
	unlock.flock_relationships.record(0, 2, "shared_credit", unlock.day)
	unlock.flock_relationships.record(0, 2, "team_lift", unlock.day)
	finish(unlock, 0)
	finish(unlock, 2)
	check(not unlock.flock_relationships.pair_reward(0, 2).earned, "familiar pair has no unearned benefit")
	unlock.perform_relationship_action(0, 2, "shared_break")
	check(unlock.flock_relationships.pair_reward(0, 2).earned, "forming friendship after clean work pays immediately")
	var director := HenSocialDirector.new()
	director.reflect_pair(0, 1, contest_receipts[0])
	director.reflect_pair(0, 1)
	director.reflect_pair(0, 2, receipts[0])
	director.advance(2, [{"id": 0, "name": "Mabel", "position": Vector3.ZERO}, {"id": 1, "name": "Pip", "position": Vector3.ONE}])
	check(director.current.relationship_label == "CONTEST COMPLETE" and "6 XP" in director.current.opening and "+6 warmth" in director.current.reply, "earned conversation explains actual payoff")
	if failures.is_empty():
		print("PAIR_REWARDS_TEST_PASSED choices=tradeoffs rewards=actual+once saves=pending+earned+legacy reactions=causal")
		quit(0)
	else:
		for failure in failures: push_error("PAIR_REWARDS_TEST_FAILED: " + failure)
		quit(1)
