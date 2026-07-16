extends SceneTree


const ASSIST_SAVE_FIELDS: Array[String] = [
	"peck_assists_used_today",
	"peck_assist_streak",
	"best_peck_assist_streak",
	"last_peck_assist",
	"priority_credit_today_cents",
	"priority_credit_total_cents",
	"peck_assist_interventions_today",
	"peck_assist_refunds_today",
	"last_peck_assist_delivery",
	"pending_peck_assist_deliveries",
	"settled_peck_assist_delivery_ids",
	"assisted_claim_ids",
	"missed_assist_claim_ids",
	"assist_quality_modifiers",
	"assist_chain_by_claim_id",
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_test_invalid_guards_are_atomic(failures)
	_test_authoritative_timing_ratings_and_effects(failures)
	_test_one_stamp_per_claim_and_three_per_shift(failures)
	_test_missed_window_resets_the_chain(failures)
	_test_assist_never_lays_and_clean_completion_adds_priority_credit(failures)
	_test_clean_delivery_refunds_exactly_once_and_cracks_do_not(failures)
	_test_v6_round_trip_v4_migration_and_validation(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("PECK_ASSIST_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PECK_ASSIST_TEST_PASSED guards=atomic timing=authoritative attention=renewable-exact-once crack=no-refund risk=exact persistence=v10-v4")
	quit(0)


func _test_invalid_guards_are_atomic(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(5101)
	var resolved := {"count": 0}
	simulation.peck_assist_resolved.connect(func(_result: Dictionary) -> void:
		resolved["count"] += 1
	)

	_assert_rejected_atomic(
		simulation,
		0,
		"management file",
		"pre-directive attempt",
		failures,
	)
	_assert_rejected_atomic(
		simulation,
		99,
		"select a working hen",
		"unknown worker attempt",
		failures,
	)

	var worker := _start_working_claim(simulation, 0, failures)
	worker.work_progress = DepartmentSimulation.PECK_ASSIST_WINDOW_START - 0.01
	_assert_rejected_atomic(
		simulation,
		0,
		"build the claim rhythm",
		"early timing attempt",
		failures,
	)

	worker.work_progress = DepartmentSimulation.PECK_ASSIST_WINDOW_END + 0.01
	_assert_rejected_atomic(
		simulation,
		0,
		"window has passed",
		"late timing attempt",
		failures,
	)

	worker.work_progress = DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS
	simulation.set_worker_at_workstation(0, false)
	_assert_rejected_atomic(
		simulation,
		0,
		"visibly seated",
		"absent worker attempt",
		failures,
	)
	_check(int(resolved["count"]) == 0, "rejected assist attempts must not emit peck_assist_resolved", failures)

	var applicant_simulation := DepartmentSimulation.new(5102, 4)
	_check(
		applicant_simulation.select_directive(&"shell_assurance"),
		"applicant guard fixture should start its shift",
		failures,
	)
	_assert_rejected_atomic(
		applicant_simulation,
		5,
		"applicants",
		"applicant attempt",
		failures,
	)


func _test_authoritative_timing_ratings_and_effects(failures: Array[String]) -> void:
	var fixtures: Array[Dictionary] = [
		{
			"label": "perfect",
			"progress": 62.0,
			"rating": &"perfect",
			"quality_modifier": -0.06,
			"progress_gain": 26.0,
			"stress_delta": 1.0,
			"fatigue_delta": 0.0,
			"morale_delta": 2.0,
			"streak": 1,
		},
		{
			"label": "strong",
			"progress": 54.0,
			"rating": &"strong",
			"quality_modifier": -0.04,
			"progress_gain": 22.0,
			"stress_delta": 1.5,
			"fatigue_delta": 0.0,
			"morale_delta": 1.0,
			"streak": 1,
		},
		{
			"label": "steady",
			"progress": 46.0,
			"rating": &"steady",
			"quality_modifier": -0.025,
			"progress_gain": 15.0,
			"stress_delta": 2.0,
			"fatigue_delta": 0.0,
			"morale_delta": 0.0,
			"streak": 0,
		},
		{
			"label": "scramble",
			"progress": 28.0,
			"rating": &"scramble",
			"quality_modifier": 0.01,
			"progress_gain": 10.0,
			"stress_delta": 4.0,
			"fatigue_delta": 2.0,
			"morale_delta": -1.0,
			"streak": 0,
		},
	]

	for fixture_index in fixtures.size():
		var fixture := fixtures[fixture_index]
		var label := String(fixture.get("label", "timing"))
		var simulation := DepartmentSimulation.new(5200 + fixture_index)
		var worker := _start_working_claim(simulation, 0, failures)
		var progress := float(fixture.get("progress", 0.0))
		worker.work_progress = progress
		var status := simulation.peck_assist_status(0)
		var expected_score := clampf(
			1.0 - absf(progress - DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS) / 34.0,
			0.0,
			1.0,
		)
		_check(bool(status.get("available", false)), "%s timing should be inside the authoritative window" % label, failures)
		_check(
			_approximately(float(status.get("timing_score", -1.0)), expected_score),
			"%s status should derive its exact score from claim progress" % label,
			failures,
		)

		var before_eggs := simulation.eggs_today
		var before_credit := simulation.credited_today_cents
		var result := simulation.perform_peck_assist(0)
		_check(bool(result.get("accepted", false)), "%s assist should be accepted" % label, failures)
		_check(StringName(result.get("rating", &"")) == StringName(fixture.get("rating", &"")), "%s progress should map to its exact rating" % label, failures)
		_check(_approximately(float(result.get("timing_score", -1.0)), expected_score), "%s result should retain the authoritative timing score" % label, failures)
		for field in ["quality_modifier", "progress_gain", "stress_delta", "fatigue_delta", "morale_delta"]:
			_check(
				_approximately(float(result.get(field, 999.0)), float(fixture.get(field, -999.0))),
				"%s assist should apply exact %s" % [label, field],
				failures,
			)
		_check(int(result.get("streak", -1)) == int(fixture.get("streak", -2)), "%s assist should apply the correct chain rule" % label, failures)
		_check(_approximately(worker.work_progress, progress + float(fixture.get("progress_gain", 0.0))), "%s worker progress should match the reported gain" % label, failures)
		_check(simulation.eggs_today == before_eggs, "%s timing resolution must not lay an egg" % label, failures)
		_check(simulation.credited_today_cents == before_credit, "%s timing resolution must not credit revenue" % label, failures)


func _test_one_stamp_per_claim_and_three_per_shift(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(5301)
	var worker := _start_working_claim(simulation, 0, failures)
	var first_claim_id := worker.current_claim.id if worker.current_claim != null else -1
	for assist_index in DepartmentSimulation.PECK_ASSIST_LIMIT:
		worker.work_progress = DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS
		var result := simulation.perform_peck_assist(0)
		_check(bool(result.get("accepted", false)), "distinct claim %d should accept its Priority Peck" % (assist_index + 1), failures)
		_check(int(result.get("remaining", -1)) == DepartmentSimulation.PECK_ASSIST_LIMIT - assist_index - 1, "assist %d should decrement the shared shift allowance exactly once" % (assist_index + 1), failures)
		_check(int(result.get("streak", -1)) == assist_index + 1, "consecutive perfect claims should build one chain step each", failures)

		if assist_index == 0:
			var state_after_first := _serialized_state(simulation)
			var duplicate := simulation.perform_peck_assist(0)
			_check(not bool(duplicate.get("accepted", false)), "a claim must reject a second Priority Peck stamp", failures)
			_check(String(duplicate.get("reason", "")).to_lower().contains("already carries"), "duplicate denial should identify the claim-level guard", failures)
			_check(_serialized_state(simulation) == state_after_first, "duplicate claim denial must be atomic", failures)

		_force_sound_completion(simulation, 0, "limit claim %d" % (assist_index + 1), failures)
		if assist_index < DepartmentSimulation.PECK_ASSIST_LIMIT - 1:
			worker = _pick_up_next_claim(simulation, 0, failures)

	_check(first_claim_id > 0, "claim-limit fixture should begin with a real claim ID", failures)
	_check(simulation.peck_assists_used_today == DepartmentSimulation.PECK_ASSIST_LIMIT, "three distinct claims should consume the complete shift allowance", failures)
	worker = _pick_up_next_claim(simulation, 0, failures)
	worker.work_progress = DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS
	var spent_status := simulation.peck_assist_status(0)
	_check(StringName(spent_status.get("window_state", &"")) == &"spent", "a fourth claim should expose the spent shift state", failures)
	_assert_rejected_atomic(
		simulation,
		0,
		"fully allocated",
		"fourth same-shift attempt",
		failures,
	)


func _test_missed_window_resets_the_chain(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(5401)
	var worker := _start_working_claim(simulation, 0, failures)
	worker.work_progress = DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS
	var first := simulation.perform_peck_assist(0)
	_check(bool(first.get("accepted", false)) and int(first.get("streak", 0)) == 1, "miss fixture should first establish a clean x1 chain", failures)
	_force_sound_completion(simulation, 0, "pre-miss claim", failures)
	worker = _pick_up_next_claim(simulation, 0, failures)
	var missed_claim_id := worker.current_claim.id if worker.current_claim != null else -1
	var missed_events: Array[Dictionary] = []
	simulation.peck_assist_missed.connect(func(worker_id: int, claim_id: int) -> void:
		missed_events.append({"worker_id": worker_id, "claim_id": claim_id})
	, CONNECT_ONE_SHOT)
	worker.work_progress = DepartmentSimulation.PECK_ASSIST_WINDOW_END
	simulation.advance_tick()

	_check(missed_events.size() == 1, "crossing the closing boundary should emit one missed-window event", failures)
	if not missed_events.is_empty():
		_check(int(missed_events[0].get("worker_id", -1)) == 0, "missed-window event should identify the working hen", failures)
		_check(int(missed_events[0].get("claim_id", -1)) == missed_claim_id, "missed-window event should identify the exact claim", failures)
	_check(simulation.peck_assist_streak == 0, "a genuinely missed claim must reset the live chain", failures)
	_check(simulation.best_peck_assist_streak == 1, "a miss must not erase the best historical chain", failures)
	_check(StringName(simulation.peck_assist_status(0).get("window_state", &"")) == &"missed", "the missed claim should remain ineligible after crossing the boundary", failures)
	_assert_rejected_atomic(simulation, 0, "window closed", "missed-claim attempt", failures)

	_force_sound_completion(simulation, 0, "missed claim completion", failures)
	worker = _pick_up_next_claim(simulation, 0, failures)
	worker.work_progress = DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS
	var restarted := simulation.perform_peck_assist(0)
	_check(bool(restarted.get("accepted", false)), "the claim after a miss should accept a new stamp", failures)
	_check(int(restarted.get("streak", -1)) == 1, "the claim after a miss should restart at x1 rather than continue the old chain", failures)


func _test_assist_never_lays_and_clean_completion_adds_priority_credit(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(5501)
	var laid_events: Array[Dictionary] = []
	simulation.egg_laid.connect(func(worker_id: int, quality: StringName, value_cents: int) -> void:
		laid_events.append({"worker_id": worker_id, "quality": quality, "value_cents": value_cents})
	)
	var worker := _start_working_claim(simulation, 0, failures)
	worker.accuracy = 0.80
	worker.work_progress = DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS
	var claim_id := worker.current_claim.id if worker.current_claim != null else -1
	var claim_value := worker.current_claim.value_cents if worker.current_claim != null else 0
	var eggs_before := simulation.eggs_today
	var processed_before := simulation.claims_processed
	var revenue_before := simulation.revenue_cents
	var credited_before := simulation.credited_today_cents
	var risk_before := simulation.estimated_crack_risk(0)
	var stress_before := worker.stress
	var fatigue_before := worker.fatigue

	var result := simulation.perform_peck_assist(0)
	_check(bool(result.get("accepted", false)), "completion fixture should accept its ideal stamp", failures)
	_check(worker.current_claim != null and worker.current_claim.id == claim_id, "Priority Peck must retain the same active claim", failures)
	_check(worker.work_state == ChickenState.WorkState.WORKING, "Priority Peck must leave the hen in normal peckwork", failures)
	_check(worker.work_progress <= 99.0, "Priority Peck must cap progress below the laying transition", failures)
	_check(simulation.eggs_today == eggs_before and simulation.claims_processed == processed_before, "Priority Peck must not directly complete work", failures)
	_check(simulation.revenue_cents == revenue_before and simulation.credited_today_cents == credited_before, "Priority Peck must not directly create or credit revenue", failures)
	_check(simulation.priority_credit_today_cents == 0, "priority credit must remain potential until a clean completion", failures)
	_check(laid_events.is_empty(), "Priority Peck must not emit egg_laid", failures)

	var quality_modifier := float(result.get("quality_modifier", 0.0))
	var expected_risk_after := (
		risk_before
		+ quality_modifier
		+ float(result.get("stress_delta", 0.0)) / 500.0
		+ float(result.get("fatigue_delta", 0.0)) / 600.0
	)
	_check(_approximately(quality_modifier, -0.06), "ideal timing should attach the exact -6% claim risk modifier", failures)
	_check(_approximately(simulation.estimated_crack_risk(0), expected_risk_after), "public crack-risk estimate should include the exact claim modifier plus reported strain", failures)
	worker.stress = stress_before
	worker.fatigue = fatigue_before
	_check(_approximately(simulation.estimated_crack_risk(0), risk_before - 0.06), "with strain held equal, the active claim risk should fall by exactly six percentage points", failures)

	_force_sound_completion(simulation, 0, "priority-credit claim", failures)
	_check(laid_events.size() == 1, "normal laying should emit the assisted claim exactly once", failures)
	if not laid_events.is_empty():
		var egg := laid_events[0]
		_check(StringName(egg.get("quality", &"")) == &"sound", "controlled assisted completion should produce a sound egg", failures)
		_check(int(egg.get("value_cents", 0)) == claim_value + 20 + 35, "clean x1 completion should add $0.20 priority credit and the first $0.35 clutch bonus", failures)
	_check(simulation.priority_credit_today_cents == 20, "clean x1 completion should book exactly 20 cents of daily priority credit", failures)
	_check(simulation.priority_credit_total_cents == 20, "clean x1 completion should book exactly 20 cents of lifetime priority credit", failures)
	_check(simulation.revenue_cents - revenue_before == claim_value + 20 + 35, "priority credit should reach revenue only through normal completion", failures)
	_check(simulation.credited_today_cents - credited_before == claim_value + 20 + 35, "farmer-facing credited value should receive the same completed-egg amount", failures)


func _test_clean_delivery_refunds_exactly_once_and_cracks_do_not(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(5551)
	var worker := _start_working_claim(simulation, 0, failures)
	worker.work_progress = DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS
	var first := simulation.perform_peck_assist(0)
	var first_claim_id := int(first.get("claim_id", -1))
	_check(bool(first.get("accepted", false)), "renewal fixture should accept its first clean assist", failures)
	_check(int(first.get("remaining", -1)) == 2, "one intervention should consume one of three attention charges", failures)
	_force_sound_completion(simulation, 0, "renewal claim", failures)
	var pending := simulation.peck_assist_delivery_status()
	_check(int(pending.get("charges", -1)) == 2, "egg completion alone must not restore attention before physical delivery", failures)
	_check(int(pending.get("pending_delivery_count", -1)) == 1, "clean assisted completion should mint one exact claim-keyed delivery token", failures)
	_check(int((pending.get("pending_delivery", {}) as Dictionary).get("claim_id", -1)) == first_claim_id, "pending refund token should identify the completed assisted claim", failures)

	# The token must survive a checkpoint before its visual basket animation and
	# settle once after restore without duplicating the reward.
	var restored := DepartmentSimulation.new(5552)
	_check(restored.restore_save_state(_json_round_trip(simulation.export_save_state(), "pending attention checkpoint", failures)), "pending clean delivery should survive JSON restore", failures)
	var before_settlement := restored.export_save_state()
	var receipt := restored.settle_peck_assist_delivery(first_claim_id, &"sound")
	_check(bool(receipt.get("accepted", false)) and bool(receipt.get("refunded", false)), "clean farmer delivery should restore attention", failures)
	_check(int(receipt.get("charges_before", -1)) == 2 and int(receipt.get("charges_after", -1)) == 3, "clean delivery should restore exactly one charge up to the cap", failures)
	_check(int(receipt.get("gross_interventions", -1)) == 1 and int(receipt.get("refunds", -1)) == 1, "gross interventions and refunds should remain separate ledgers", failures)
	var after_settlement := restored.export_save_state()
	_check(JSON.stringify(after_settlement) != JSON.stringify(before_settlement), "accepted delivery settlement should mutate the persisted attention ledger", failures)
	var duplicate := restored.settle_peck_assist_delivery(first_claim_id, &"sound")
	_check(not bool(duplicate.get("accepted", false)) and "already restored" in String(duplicate.get("reason", "")), "duplicate basket callbacks should explain the exact-once guard", failures)
	_check(JSON.stringify(restored.export_save_state()) == JSON.stringify(after_settlement), "duplicate delivery settlement must be atomic", failures)

	# A refunded charge can immediately sustain another claim intervention, making
	# the active loop renewable instead of ending after three early stamps.
	restored.set_worker_at_workstation(0, true)
	worker = restored.workers[0]
	worker = _pick_up_next_claim(restored, 0, failures)
	worker.work_progress = DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS
	var second := restored.perform_peck_assist(0)
	_check(bool(second.get("accepted", false)) and int(second.get("gross_interventions", -1)) == 2, "restored attention should fund a later exact claim", failures)
	_check(int(second.get("remaining", -1)) == 2, "renewed intervention should consume the restored charge normally", failures)

	var cracked := DepartmentSimulation.new(5553)
	var cracked_worker := _start_working_claim(cracked, 0, failures)
	cracked_worker.accuracy = 0.55
	cracked_worker.work_progress = DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS
	var cracked_assist := cracked.perform_peck_assist(0)
	var cracked_claim_id := int(cracked_assist.get("claim_id", -1))
	_check(bool(cracked_assist.get("accepted", false)), "crack fixture should begin with a real assisted claim", failures)
	_force_cracked_completion(cracked, 0, "cracked renewal claim", failures)
	var cracked_status := cracked.peck_assist_delivery_status()
	_check(int(cracked_status.get("pending_delivery_count", -1)) == 0, "cracked assisted work must not mint a refund token", failures)
	_check(int(cracked_status.get("charges", -1)) == 2 and cracked.peck_assist_streak == 0, "a crack should consume attention and break the live chain", failures)
	var cracked_before := JSON.stringify(cracked.export_save_state())
	var cracked_delivery := cracked.settle_peck_assist_delivery(cracked_claim_id, &"cracked")
	_check(not bool(cracked_delivery.get("accepted", false)) and "cannot restore" in String(cracked_delivery.get("reason", "")), "cracked presentation should explicitly deny a refund", failures)
	_check(JSON.stringify(cracked.export_save_state()) == cracked_before, "cracked delivery denial must remain atomic", failures)


func _test_v6_round_trip_v4_migration_and_validation(failures: Array[String]) -> void:
	var original := DepartmentSimulation.new(5601)
	var worker := _start_working_claim(original, 0, failures)
	worker.work_progress = 54.0
	var assist := original.perform_peck_assist(0)
	_check(bool(assist.get("accepted", false)), "persistence fixture should retain one active assisted claim", failures)
	var state := original.export_save_state()
	_check(int(state.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "peck-assist checkpoints should export the current schema", failures)
	var parsed_state := _json_round_trip(state, "v6 checkpoint", failures)
	var restored := DepartmentSimulation.new(5602)
	_check(restored.restore_save_state(parsed_state), "valid v6 JSON checkpoint should restore", failures)
	var restored_state := restored.export_save_state()
	for field in ASSIST_SAVE_FIELDS:
		_check(
			JSON.stringify(restored_state.get(field)) == JSON.stringify(state.get(field)),
			"v6 round trip should preserve %s" % field,
			failures,
		)
	_check(_approximately(restored.workers[0].work_progress, original.workers[0].work_progress), "v6 round trip should preserve assisted claim progress", failures)
	restored.set_worker_at_workstation(0, true)
	_check(StringName(restored.peck_assist_status(0).get("window_state", &"")) == &"used", "restored active claim should retain its one-stamp guard", failures)

	var malformed := parsed_state.duplicate(true)
	malformed["peck_assists_used_today"] = DepartmentSimulation.PECK_ASSIST_LIMIT + 1
	var fallback := DepartmentSimulation.new(5603)
	var fallback_before := _serialized_state(fallback)
	_check(not fallback.restore_save_state(malformed), "out-of-range v6 assist usage should fail closed", failures)
	_check(_serialized_state(fallback) == fallback_before, "rejected v6 restore should leave the fallback simulation unchanged", failures)

	var legacy_v4 := state.duplicate(true)
	legacy_v4["state_version"] = 4
	for field in ASSIST_SAVE_FIELDS:
		legacy_v4.erase(field)
	legacy_v4 = _json_round_trip(legacy_v4, "legacy v4 checkpoint", failures)
	var migrated := DepartmentSimulation.new(5604)
	_check(migrated.restore_save_state(legacy_v4), "valid v4 checkpoint should migrate to the peck-assist schema", failures)
	var migrated_state := migrated.export_save_state()
	_check(int(migrated_state.get("state_version", -1)) == DepartmentSimulation.SAVE_STATE_VERSION, "v4 migration should export the current schema", failures)
	_check(int(migrated_state.get("peck_assists_used_today", -1)) == 0, "v4 migration should default shift assist usage to zero", failures)
	_check(int(migrated_state.get("peck_assist_streak", -1)) == 0, "v4 migration should default the live chain to zero", failures)
	_check(int(migrated_state.get("best_peck_assist_streak", -1)) == 0, "v4 migration should default the best chain to zero", failures)
	_check((migrated_state.get("last_peck_assist", {}) as Dictionary).is_empty(), "v4 migration should not invent a last assist result", failures)
	_check((migrated_state.get("assisted_claim_ids", []) as Array).is_empty(), "v4 migration should not stamp an active legacy claim", failures)
	_check((migrated_state.get("assist_quality_modifiers", {}) as Dictionary).is_empty(), "v4 migration should not invent claim quality modifiers", failures)
	_check(int(migrated_state.get("priority_credit_total_cents", -1)) == 0, "v4 migration should not invent priority credit", failures)


func _start_working_claim(
	simulation: DepartmentSimulation,
	worker_id: int,
	failures: Array[String],
) -> ChickenState:
	_check(
		simulation.select_directive(&"shell_assurance"),
		"working fixture should authorize Shell Assurance",
		failures,
	)
	simulation.set_worker_at_workstation(worker_id, true)
	simulation.advance_tick()
	var worker := simulation.workers[worker_id]
	_check(worker.work_state == ChickenState.WorkState.WORKING, "working fixture should enter peckwork", failures)
	_check(worker.current_claim != null, "working fixture should hold a real claim", failures)
	return worker


func _pick_up_next_claim(
	simulation: DepartmentSimulation,
	worker_id: int,
	failures: Array[String],
) -> ChickenState:
	var worker := simulation.workers[worker_id]
	_check(worker.current_claim == null, "next-claim fixture should begin after the prior claim clears", failures)
	simulation.set_worker_at_workstation(worker_id, true)
	simulation.advance_tick()
	_check(worker.work_state == ChickenState.WorkState.WORKING, "seated hen should pick up the next claim", failures)
	_check(worker.current_claim != null, "next-claim fixture should receive a distinct real claim", failures)
	return worker


func _force_sound_completion(
	simulation: DepartmentSimulation,
	worker_id: int,
	label: String,
	failures: Array[String],
) -> void:
	var worker := simulation.workers[worker_id]
	_check(worker.current_claim != null, "%s should have a claim to finish" % label, failures)
	if worker.current_claim == null:
		return
	var eggs_before := simulation.eggs_today
	var risk := simulation.estimated_crack_risk(worker_id)
	var golden_chance := clampf(
		0.025 + maxf(0.0, worker.morale - 70.0) * 0.0005,
		0.025,
		0.08,
	)
	var clean_seed := _seed_for_sound_egg(risk, golden_chance)
	_check(clean_seed > 0, "%s should find a deterministic sound-egg seed" % label, failures)
	(simulation.get("_rng") as RandomNumberGenerator).seed = clean_seed
	worker.work_state = ChickenState.WorkState.LAYING
	worker.state_ticks_remaining = 1
	simulation.advance_tick()
	_check(simulation.eggs_today == eggs_before + 1, "%s should finish through the normal laying tick" % label, failures)
	_check(worker.current_claim == null, "%s should clear its completed claim" % label, failures)


func _force_cracked_completion(
	simulation: DepartmentSimulation,
	worker_id: int,
	label: String,
	failures: Array[String],
) -> void:
	var worker := simulation.workers[worker_id]
	_check(worker.current_claim != null, "%s should have a claim to crack" % label, failures)
	if worker.current_claim == null:
		return
	var eggs_before := simulation.eggs_today
	var risk := simulation.estimated_crack_risk(worker_id)
	var cracked_seed := _seed_for_cracked_egg(risk)
	_check(cracked_seed > 0, "%s should find a deterministic cracked-egg seed" % label, failures)
	(simulation.get("_rng") as RandomNumberGenerator).seed = cracked_seed
	worker.work_state = ChickenState.WorkState.LAYING
	worker.state_ticks_remaining = 1
	simulation.advance_tick()
	_check(simulation.eggs_today == eggs_before + 1, "%s should finish through the normal laying tick" % label, failures)
	_check(worker.current_claim == null, "%s should clear its cracked claim" % label, failures)
	_check(simulation.cracked_today > 0, "%s should record a cracked result" % label, failures)


func _assert_rejected_atomic(
	simulation: DepartmentSimulation,
	worker_id: int,
	reason_fragment: String,
	label: String,
	failures: Array[String],
) -> void:
	var before := _serialized_state(simulation)
	var result := simulation.perform_peck_assist(worker_id)
	_check(not bool(result.get("accepted", false)), "%s should be rejected" % label, failures)
	_check(
		String(result.get("reason", "")).to_lower().contains(reason_fragment.to_lower()),
		"%s should explain its authoritative guard" % label,
		failures,
	)
	_check(_serialized_state(simulation) == before, "%s must leave the full save state unchanged" % label, failures)


func _serialized_state(simulation: DepartmentSimulation) -> String:
	return JSON.stringify(simulation.export_save_state())


func _json_round_trip(
	state: Dictionary,
	label: String,
	failures: Array[String],
) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(state))
	_check(parsed is Dictionary, "%s should survive JSON encoding" % label, failures)
	if not parsed is Dictionary:
		return {}
	return parsed as Dictionary


func _seed_for_sound_egg(crack_risk: float, golden_chance: float) -> int:
	for candidate in range(1, 10_000):
		var probe := RandomNumberGenerator.new()
		probe.seed = candidate
		if probe.randf() >= crack_risk and probe.randf() >= golden_chance:
			return candidate
	return -1


func _seed_for_cracked_egg(crack_risk: float) -> int:
	for candidate in range(1, 10_000):
		var probe := RandomNumberGenerator.new()
		probe.seed = candidate
		if probe.randf() < crack_risk:
			return candidate
	return -1


func _approximately(actual: float, expected: float, tolerance: float = 0.0001) -> bool:
	return absf(actual - expected) <= tolerance


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
