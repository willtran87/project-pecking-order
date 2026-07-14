extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	_test_opening_catalog_and_specialties(failures)
	_test_assignment_atomicity_and_seated_pickup(failures)
	_test_auto_specialty_and_urgency(failures)
	_test_specialty_causality(failures)
	_test_deterministic_arrivals_cap_and_deadlines(failures)
	_test_lane_value_reward(failures)
	_test_rework_and_daily_counters(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("CLAIM_ROUTING_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CLAIM_ROUTING_TEST_PASSED lanes=3 queue=bounded routing=causal rework=next-shift")
	quit(0)


func _test_opening_catalog_and_specialties(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(801)
	var snapshot := simulation.snapshot()
	var catalog: Array = snapshot.get("routing_catalog", [])
	var expected_lanes: Array[StringName] = [&"nest_damage", &"predator_loss", &"appeals"]
	var catalog_ids: Array[StringName] = []
	for entry_value in catalog:
		var entry := entry_value as Dictionary
		catalog_ids.append(StringName(entry.get("id", &"")))
		_check(not String(entry.get("display_name", "")).is_empty(), "each lane needs a display name", failures)
		_check(int(entry.get("base_value_cents", 0)) > 0, "each lane needs an integer-cent value", failures)
		_check(int(entry.get("deadline_minutes", 0)) > 0, "each lane needs a service deadline", failures)
	_check(catalog.size() == 3, "routing catalog should expose exactly three work lanes", failures)
	_check(catalog_ids == expected_lanes, "routing catalog should retain the stable three-lane order", failures)

	var queue_counts: Dictionary = snapshot.get("claim_queue_counts", {})
	var queue_items: Dictionary = snapshot.get("claim_queue_items", {})
	_check(int(snapshot.get("claims_waiting", -1)) == 6, "opening queue should contain six claims", failures)
	for lane in expected_lanes:
		_check(int(queue_counts.get(lane, -1)) == 2, "opening queue should contain two %s claims" % lane, failures)
		_check((queue_items.get(lane, []) as Array).size() == 2, "opening item snapshot should expose both %s claims" % lane, failures)

	var expected_specialties: Array[StringName] = [
		&"appeals", &"nest_damage", &"predator_loss",
		&"nest_damage", &"appeals", &"predator_loss",
	]
	var workers: Array = snapshot.get("workers", [])
	_check(workers.size() == 6, "routing fixture should retain six hens", failures)
	for worker_index in mini(workers.size(), expected_specialties.size()):
		var worker := workers[worker_index] as Dictionary
		_check(StringName(worker.get("specialty", &"")) == expected_specialties[worker_index], "worker %d should keep her stable specialty" % worker_index, failures)
		_check(StringName(worker.get("assigned_lane", &"")) == &"auto", "worker %d should default to AUTO dispatch" % worker_index, failures)
		_check((worker.get("current_claim", {}) as Dictionary).is_empty(), "worker %d should open without an active claim" % worker_index, failures)


func _test_assignment_atomicity_and_seated_pickup(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(802)
	var emitted := {"count": 0}
	simulation.snapshot_changed.connect(func(_snapshot: Dictionary) -> void:
		emitted["count"] += 1
	)
	var before := simulation.snapshot()
	_check(not simulation.set_worker_assignment(99, &"nest_damage"), "unknown worker assignment should fail", failures)
	_check(not simulation.set_worker_assignment(0, &"executive_scratching"), "unknown lane assignment should fail", failures)
	_check(int(emitted["count"]) == 0, "invalid assignment should not emit a mutation snapshot", failures)
	var after_invalid := simulation.snapshot()
	_check(
		(after_invalid.get("workers", []) as Array)[0].get("assigned_lane", &"")
			== (before.get("workers", []) as Array)[0].get("assigned_lane", &""),
		"invalid assignment should leave the worker unchanged",
		failures
	)
	_check(after_invalid.get("claim_queue_items", {}) == before.get("claim_queue_items", {}), "invalid assignment should leave every queued claim unchanged", failures)

	_check(simulation.set_worker_assignment(0, &"nest_damage"), "valid lane assignment should succeed", failures)
	_check(simulation.select_directive(&"shell_assurance"), "pickup fixture should authorize a directive", failures)
	var waiting_before := simulation.claims_waiting
	simulation.advance_tick()
	var unseated_worker := (simulation.snapshot().get("workers", []) as Array)[0] as Dictionary
	_check((unseated_worker.get("current_claim", {}) as Dictionary).is_empty(), "unseated worker must not pick up a claim", failures)
	_check(simulation.claims_waiting == waiting_before, "unseated pickup attempt must not mutate the queue", failures)

	simulation.set_worker_at_workstation(0, true)
	simulation.advance_tick()
	var seated_snapshot := simulation.snapshot()
	var seated_worker := (seated_snapshot.get("workers", []) as Array)[0] as Dictionary
	var current_claim := seated_worker.get("current_claim", {}) as Dictionary
	_check(StringName(current_claim.get("lane", &"")) == &"nest_damage", "assigned worker should pull only her selected lane", failures)
	_check(simulation.claim_queue_count(&"nest_damage") == 1, "lane pull should remove exactly one nest claim", failures)
	_check(int(seated_snapshot.get("claims_waiting", -1)) == _sum_queue_counts(seated_snapshot), "compatibility queue total should stay synchronized", failures)


func _test_auto_specialty_and_urgency(failures: Array[String]) -> void:
	var specialty_simulation := DepartmentSimulation.new(803)
	_check(specialty_simulation.select_directive(&"shell_assurance"), "AUTO specialty fixture should authorize a directive", failures)
	specialty_simulation.set_worker_at_workstation(0, true)
	specialty_simulation.advance_tick()
	var specialty_worker := (specialty_simulation.snapshot().get("workers", []) as Array)[0] as Dictionary
	_check(StringName(specialty_worker.get("specialty", &"")) == &"appeals", "Mabel should be the stable appeals specialist", failures)
	_check(StringName((specialty_worker.get("current_claim", {}) as Dictionary).get("lane", &"")) == &"appeals", "AUTO should prefer available specialty work within its urgency window", failures)

	var urgency_simulation := DepartmentSimulation.new(804)
	# Narrow deterministic setup: make one real queued nest claim old enough that
	# deadline urgency must override Mabel's otherwise-preferred appeals lane.
	var queues := urgency_simulation.get("_claim_queues") as Dictionary
	var nest_queue := queues.get(&"nest_damage", []) as Array
	var urgent_claim := nest_queue[0] as ClaimState
	urgent_claim.deadline_operational_minute = -1
	_check(urgency_simulation.select_directive(&"shell_assurance"), "AUTO urgency fixture should authorize a directive", failures)
	urgency_simulation.set_worker_at_workstation(0, true)
	urgency_simulation.advance_tick()
	var urgency_worker := (urgency_simulation.snapshot().get("workers", []) as Array)[0] as Dictionary
	_check(StringName((urgency_worker.get("current_claim", {}) as Dictionary).get("lane", &"")) == &"nest_damage", "genuinely overdue work should override AUTO specialty preference", failures)


func _test_specialty_causality(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(805)
	_check(simulation.set_worker_assignment(0, &"nest_damage"), "mismatched worker should accept nest assignment", failures)
	_check(simulation.set_worker_assignment(1, &"nest_damage"), "matched worker should accept nest assignment", failures)
	for worker_id in [0, 1]:
		var worker := simulation.workers[worker_id]
		worker.skill = 1.0
		worker.accuracy = 0.90
		worker.morale = 80.0
		worker.fatigue = 10.0
		worker.stress = 10.0
		simulation.set_worker_at_workstation(worker_id, true)
	_check(simulation.select_directive(&"shell_assurance"), "specialty comparison should authorize one shared directive", failures)
	simulation.advance_tick()
	_check(simulation.workers[0].current_claim != null and simulation.workers[1].current_claim != null, "both equalized workers should pull same-lane claims", failures)
	_check(simulation.workers[0].current_claim.lane == simulation.workers[1].current_claim.lane, "speed comparison should use the same lane", failures)
	var mismatch_risk := simulation.estimated_crack_risk(0)
	var match_risk := simulation.estimated_crack_risk(1)
	simulation.advance_tick()
	_check(simulation.workers[1].work_progress > simulation.workers[0].work_progress, "specialty match should causally process an equal claim faster", failures)
	_check(match_risk < mismatch_risk, "specialty match should causally reduce crack risk on an equal claim", failures)


func _test_deterministic_arrivals_cap_and_deadlines(failures: Array[String]) -> void:
	var first := DepartmentSimulation.new(806)
	var second := DepartmentSimulation.new(806)
	_check(first.select_directive(&"shell_assurance"), "first deterministic arrival fixture should start", failures)
	_check(second.select_directive(&"shell_assurance"), "second deterministic arrival fixture should start", failures)
	for _tick in 30:
		first.advance_tick()
		second.advance_tick()
	var first_snapshot := first.snapshot()
	var second_snapshot := second.snapshot()
	_check(first_snapshot.get("claim_queue_items", {}) == second_snapshot.get("claim_queue_items", {}), "equal seeds and actions should create identical typed arrivals", failures)

	for _tick in 40:
		first.advance_tick()
	var capped := first.snapshot()
	_check(int(capped.get("claims_waiting", -1)) == DepartmentSimulation.MAX_CLAIM_QUEUE, "waiting queue should stop at its hard cap", failures)
	_check(int(capped.get("claims_outstanding", -1)) == DepartmentSimulation.MAX_CLAIM_QUEUE, "total outstanding claims should respect the same cap", failures)
	_check(_sum_queue_counts(capped) == DepartmentSimulation.MAX_CLAIM_QUEUE, "typed lane counts should sum to the authoritative cap", failures)

	var overdue_simulation := DepartmentSimulation.new(807)
	_check(overdue_simulation.select_directive(&"shell_assurance"), "deadline fixture should start", failures)
	for _tick in 91:
		overdue_simulation.advance_tick()
		_resolve_pending_incident(overdue_simulation)
	var overdue_snapshot := overdue_simulation.snapshot()
	var overdue_by_lane: Dictionary = overdue_snapshot.get("claim_queue_overdue_counts", {})
	_check(int(overdue_snapshot.get("queued_overdue_claims", -1)) == 2, "the two opening nest files should be overdue just after 11:00 AM", failures)
	_check(int(overdue_by_lane.get(&"nest_damage", -1)) == 2, "overdue totals should remain attributable to their lane", failures)
	var nest_items: Array = (overdue_snapshot.get("claim_queue_items", {}) as Dictionary).get(&"nest_damage", [])
	var item_overdue_count := 0
	for item_value in nest_items:
		var item := item_value as Dictionary
		if bool(item.get("overdue", false)):
			item_overdue_count += 1
			_check(int(item.get("minutes_until_deadline", 0)) < 0, "overdue item should expose a negative deadline remainder", failures)
	_check(item_overdue_count == 2, "queued item snapshots should expose both overdue nest files", failures)


func _test_lane_value_reward(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(808)
	var observations: Array[Dictionary] = []
	simulation.egg_laid.connect(func(worker_id: int, quality: StringName, value_cents: int) -> void:
		observations.append({"worker_id": worker_id, "quality": quality, "value_cents": value_cents})
	)
	_check(simulation.set_worker_assignment(1, &"nest_damage"), "reward fixture should assign the nest specialist", failures)
	simulation.set_worker_at_workstation(1, true)
	var worker := simulation.workers[1]
	worker.accuracy = 1.0
	worker.morale = 0.0
	worker.fatigue = 0.0
	worker.stress = 0.0
	_check(simulation.select_directive(&"shell_assurance"), "reward fixture should authorize quality policy", failures)
	simulation.advance_tick()
	_check(worker.current_claim != null and worker.current_claim.lane == &"nest_damage", "reward fixture should hold a real nest claim", failures)
	var claim_value := worker.current_claim.value_cents
	var reward_before := simulation.revenue_cents
	(simulation.get("_rng") as RandomNumberGenerator).seed = _seed_for_sound_egg()
	worker.work_state = ChickenState.WorkState.LAYING
	worker.state_ticks_remaining = 1
	simulation.advance_tick()
	_check(observations.size() == 1, "one completed claim should emit one egg reward", failures)
	if not observations.is_empty():
		var observation := observations[0]
		_check(StringName(observation.get("quality", &"")) == &"sound", "controlled reward fixture should produce a sound egg", failures)
		_check(typeof(observation.get("value_cents", 0)) == TYPE_INT, "egg reward should remain integer cents", failures)
		_check(int(observation.get("value_cents", 0)) == claim_value + 35, "sound reward should equal lane value plus the first clean-clutch bonus", failures)
		_check(simulation.revenue_cents - reward_before == int(observation.get("value_cents", 0)), "authoritative revenue should receive the emitted lane-specific value", failures)
	_check(int(simulation.lane_processed_today.get(&"nest_damage", 0)) == 1, "completed nest claim should increment its daily lane counter", failures)


func _test_rework_and_daily_counters(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(809)
	var qualities: Array[StringName] = []
	simulation.egg_laid.connect(func(_worker_id: int, quality: StringName, _value_cents: int) -> void:
		qualities.append(quality)
	)
	_check(simulation.set_worker_assignment(0, &"appeals"), "rework fixture should assign the appeals specialist", failures)
	simulation.set_worker_at_workstation(0, true)
	var worker := simulation.workers[0]
	worker.accuracy = 0.0
	worker.morale = 50.0
	worker.fatigue = 0.0
	worker.stress = 0.0
	_check(simulation.select_directive(&"shell_assurance"), "rework fixture should authorize a directive", failures)
	simulation.advance_tick()
	_check(worker.current_claim != null and worker.current_claim.lane == &"appeals", "rework fixture should hold an appeals claim", failures)
	var source_claim_id := worker.current_claim.id
	var source_lane := worker.current_claim.lane
	var crack_risk := simulation.estimated_crack_risk(0)
	(simulation.get("_rng") as RandomNumberGenerator).seed = _seed_for_cracked_egg(crack_risk)
	worker.work_state = ChickenState.WorkState.LAYING
	worker.state_ticks_remaining = 1
	simulation.advance_tick()
	_check(qualities == [&"cracked"], "controlled low-accuracy completion should crack", failures)
	var scheduled := simulation.snapshot()
	_check(int(scheduled.get("rework_due_next_shift", 0)) == 1, "cracked claim should schedule one next-shift rework", failures)
	var pending_items: Array = scheduled.get("rework_pending_items", [])
	_check(pending_items.size() == 1, "scheduled rework should be explicit in the snapshot", failures)
	if not pending_items.is_empty():
		var pending := pending_items[0] as Dictionary
		_check(bool(pending.get("is_rework", false)), "pending follow-up should be marked as rework", failures)
		_check(int(pending.get("source_claim_id", -1)) == source_claim_id, "pending rework should retain its source claim ID", failures)
	_check(int(scheduled.get("lane_processed_today", {}).get(source_lane, 0)) == 1, "cracked completion should still count as processed work", failures)
	_check(int(scheduled.get("lane_processed_totals", {}).get(source_lane, 0)) == 1, "cumulative lane counter should include the cracked completion", failures)

	simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	for _step in 5:
		if simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW:
			break
		simulation.advance_tick()
		_resolve_pending_incident(simulation)
	var next_shift := simulation.snapshot()
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW and simulation.day == 2, "rework fixture should reach the next-shift review gate", failures)
	_check(int(next_shift.get("rework_due_next_shift", -1)) == 0, "due rework should leave the pending list at next shift", failures)
	_check(int(next_shift.get("rework_waiting", 0)) >= 1, "due rework should be released into the next-shift typed queue", failures)
	var released_rework := _find_rework(next_shift, source_lane, source_claim_id)
	_check(not released_rework.is_empty(), "released queue should expose rework with its source ID", failures)
	if not released_rework.is_empty():
		_check(bool(released_rework.get("is_rework", false)), "released follow-up should remain marked as rework", failures)
		_check(int(released_rework.get("available_day", 0)) == 2, "released rework should become available on day two", failures)
	_check(int(next_shift.get("lane_processed_today", {}).get(source_lane, -1)) == 0, "daily lane counters should reset at the shift boundary", failures)
	_check(int(next_shift.get("lane_processed_totals", {}).get(source_lane, 0)) == 1, "cumulative lane counters should persist across the shift boundary", failures)


func _sum_queue_counts(snapshot: Dictionary) -> int:
	var total := 0
	var counts: Dictionary = snapshot.get("claim_queue_counts", {})
	for lane in DepartmentSimulation.CLAIM_LANES:
		total += int(counts.get(lane, 0))
	return total


func _find_rework(snapshot: Dictionary, lane: StringName, source_claim_id: int) -> Dictionary:
	var queue_items: Dictionary = snapshot.get("claim_queue_items", {})
	for item_value in (queue_items.get(lane, []) as Array):
		var item := item_value as Dictionary
		if bool(item.get("is_rework", false)) and int(item.get("source_claim_id", -1)) == source_claim_id:
			return item
	return {}


func _resolve_pending_incident(simulation: DepartmentSimulation) -> void:
	var pending := simulation.pending_decision_snapshot()
	if StringName(pending.get("kind", &"")) != &"incident":
		return
	var serial := int(pending.get("serial", -1))
	for option_value in pending.get("options", []):
		var option := option_value as Dictionary
		if int(option.get("cost_cents", 0)) == 0:
			simulation.resolve_decision(serial, StringName(option.get("id", &"")))
			return


func _seed_for_sound_egg() -> int:
	for candidate in range(1, 10_000):
		var probe := RandomNumberGenerator.new()
		probe.seed = candidate
		if probe.randf() > 0.10 and probe.randf() > 0.10:
			return candidate
	return 1


func _seed_for_cracked_egg(crack_risk: float) -> int:
	for candidate in range(1, 10_000):
		var probe := RandomNumberGenerator.new()
		probe.seed = candidate
		if probe.randf() < crack_risk:
			return candidate
	return 1


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
