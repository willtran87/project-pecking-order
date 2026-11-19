extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _fixture() -> DepartmentSimulation:
	var sim := DepartmentSimulation.new(8129, 4)
	_check(sim.select_directive(&"shell_assurance"), "running fixture")
	sim.revenue_cents = 10000
	return sim

func _next_day(sim: DepartmentSimulation) -> void:
	sim.day += 1
	sim.call("_reset_daily_decision_state")
	sim.call("_prepare_morning_directive")
	_check(sim.select_directive(&"shell_assurance"), "new shift starts")

func _finish(sim: DepartmentSimulation, id: int, cracked: bool = false) -> void:
	var rng := sim.get("_rng") as RandomNumberGenerator
	for seed_value in range(1, 10000):
		rng.seed = seed_value
		var roll := rng.randf()
		if (roll < 0.001 if cracked else roll > 0.9):
			rng.seed = seed_value
			break
	sim.call("_complete_egg", sim.workers[id])

func _run() -> void:
	var sim := _fixture()
	_check(sim.perform_personnel_action(0, &"quota_pressure").accepted, "real quota pressure accepted")
	_check(sim.flock_relationships.affinity(0, 1) == -10, "pressure strains nearest pair")
	_check(not sim.perform_personnel_action(0, &"quota_pressure").accepted and sim.flock_relationships.affinity(0, 1) == -10, "denied pressure cannot add rivalry")
	_next_day(sim)
	_check(sim.perform_personnel_action(0, &"quota_pressure").accepted, "pressure accepted next shift")
	_check(sim.flock_relationships.snapshot(0, 1).tier == "rivals", "repeated pressure creates rivalry across shifts")
	_next_day(sim)
	_check(sim.perform_personnel_action(0, &"share_credit").accepted, "real shared credit accepted")
	_check(sim.flock_relationships.affinity(0, 1) == -14, "shared credit repairs some trust")
	var revenue := sim.revenue_cents
	var before_stress := sim.workers[1].stress
	var repair := sim.perform_relationship_action(0, 1, "clear_air")
	_check(repair.accepted and sim.revenue_cents == revenue, "clear air is free")
	_check(sim.flock_relationships.snapshot(0, 1).tier == "mending" and sim.workers[1].stress == maxf(0, before_stress - 2), "reconciliation remembers rivalry and comforts both")
	var after := JSON.stringify(sim.export_save_state())
	_check(not sim.perform_relationship_action(0, 1, "shared_break").accepted, "shared moment consumes shift's Team Lift")
	_check(JSON.stringify(sim.export_save_state()) == after, "denied second shared moment is atomic")
	var restored := DepartmentSimulation.new(44, 4)
	_check(restored.restore_save_state(JSON.parse_string(after)), "JSON save restores relationship and receipt")
	_check(restored.flock_relationships.snapshot(0, 1).reconciled and not restored.relationship_panel_snapshot(0, 1).break_available, "reload preserves reconciliation and spent opportunity")
	for mutation in ["score", "memory", "pair", "daily"]:
		var bad := sim.export_save_state()
		match mutation:
			"score": bad.flock_relationships.pairs["0:1"].affinity = 999
			"memory": bad.flock_relationships.pairs["0:1"].memories[0].actor = 5
			"pair": bad.flock_relationships.pairs["0:99"] = bad.flock_relationships.pairs["0:1"]
			"daily": bad.flock_relationships.daily_counts["0:1:clear_air"] = 2
		var stable := JSON.stringify(restored.export_save_state())
		_check(not restored.restore_save_state(bad), "malformed " + mutation + " rejected")
		_check(JSON.stringify(restored.export_save_state()) == stable, "malformed " + mutation + " rejected atomically")
	var legacy := sim.export_save_state()
	legacy.erase("flock_relationships")
	_check(restored.restore_save_state(legacy) and restored.flock_relationships.pairs.is_empty(), "old saves migrate without invented memories")
	_next_day(sim)
	_check(sim.perform_relationship_action(0, 1, "shared_break").accepted, "shared moments reopen next shift")
	_check(sim.revenue_cents == revenue - 100, "break charges exactly $1")
	var broke := _fixture()
	broke.revenue_cents = 0
	var broke_before := JSON.stringify(broke.export_save_state())
	_check(not broke.perform_relationship_action(0, 1, "shared_break").accepted and JSON.stringify(broke.export_save_state()) == broke_before, "break cannot spend reserved or missing funds")
	_check(not broke.perform_relationship_action(0, 4, "clear_air").accepted and not broke.perform_relationship_action(0, 0, "shared_break").accepted, "off-floor and self-pair guards")
	# Clean shifts accrue for adjacent pairs regardless of who completes first.
	var work := _fixture()
	for id in 3:
		work.set_worker_at_workstation(id, true)
	work.advance_tick()
	_finish(work, 2)
	_finish(work, 0)
	_finish(work, 1)
	_check(work.flock_relationships.affinity(0, 1) == 4 and work.flock_relationships.affinity(1, 2) == 4, "real clean eggs build both neighbouring bonds")
	_check(work.flock_relationships.affinity(0, 2) == 0, "distant production does not invent a shared perch")
	work.flock_relationships.record_clean(1, 2, work.day)
	_check(work.flock_relationships.affinity(1, 2) == 4, "same-day clean egg farming is capped")
	var cracked := _fixture()
	for id in 2:
		cracked.set_worker_at_workstation(id, true)
	cracked.advance_tick()
	_finish(cracked, 0, true)
	_finish(cracked, 1)
	_check(cracked.flock_relationships.pairs.is_empty(), "cracked work does not earn shared clean shift")
	# Durable friendship changes the actual Team Lift outcome.
	var friends := _fixture()
	friends.flock_relationships.record(0, 1, "shared_break", 1)
	friends.flock_relationships.record(0, 1, "shared_credit", 1)
	friends.flock_relationships.record(0, 1, "shared_shift", 1)
	friends.solidarity = 100
	for worker in friends.workers:
		worker.stress = 15
		worker.fatigue = 0
		worker.morale = 70
	var base: Dictionary = friends.call("_base_team_lift_ability", friends.workers[0], friends.workers[1])
	_check(friends.perform_playbook_action(&"teamwork", &"team_lift", 0).accepted, "friends can perform real Team Lift")
	_check(friends.workers[0].morale == 72 + float(base.morale) and friends.workers[1].stress == 13 + float(base.stress), "friend care adds exact morale and relief for both")
	_check(friends.flock_relationships.affinity(0, 1) == 26, "Team Lift grows lasting trust")
	var one := {"id": 0, "name": "Mabel", "relationships": [friends.flock_relationships.snapshot(0, 1)]}
	var two := {"id": 1, "name": "Pip"}
	var friend_chat := HenPersonality.exchange(&"chat", one, two, 0)
	one.relationships = [{"partner_id": 1, "tier": "rivals", "label": "RIVALS"}]
	var rival_chat := HenPersonality.exchange(&"chat", one, two, 0)
	one.relationships = [{"partner_id": 1, "tier": "mending", "label": "MENDING"}]
	var mending_chat := HenPersonality.exchange(&"chat", one, two, 0)
	_check(friend_chat.opening != rival_chat.opening and rival_chat.opening != mending_chat.opening, "friendship rivalry and reconciliation have different conversations")
	one.position = Vector3.ZERO
	two.position = Vector3(2, 0, 0)
	var director := HenSocialDirector.new()
	director.current = rival_chat
	director.reflect_pair(0, 1)
	director.advance(5.0, [one, two], false)
	_check(director.current.is_empty(), "repair discards stale argument and waits for floor control")
	director.advance(2.0, [one, two])
	_check(director.current.relationship_label == "MENDING", "a real shared moment earns a nearby reconciled exchange")
	_check(friends.flock_relationships.snapshot(0, 1).memories.size() == 3, "shared history is bounded")
	if failures.is_empty():
		print("FLOCK_RELATIONSHIPS_TEST_PASSED events=causal history=persistent rewards=earned repair=remembered guards=atomic saves=compatible")
		quit(0)
	else:
		for failure in failures:
			push_error("FLOCK_RELATIONSHIPS_TEST_FAILED: " + failure)
		quit(1)
