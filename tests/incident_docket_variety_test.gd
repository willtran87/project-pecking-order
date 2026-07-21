extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var authored_seeds := [4703, 7919, 12011]
	var rotation_signatures: Dictionary[String, bool] = {}
	for seed in authored_seeds:
		var first := DepartmentSimulation.new(1701, 4, seed)
		var replay := DepartmentSimulation.new(1701, 4, seed)
		var rotation_size := DepartmentSimulation.INCIDENT_ORDER.size()
		var first_sequence := _draw_incidents(first, rotation_size * 3)
		var replay_sequence := _draw_incidents(replay, rotation_size * 3)
		_check(first_sequence == replay_sequence, "docket %d should replay deterministically" % seed, failures)
		_check(
			first_sequence.slice(0, 4) == DepartmentSimulation.LEGACY_INCIDENT_ORDER,
			"docket %d should preserve the four familiar cases at the start of its expanded rotation" % seed,
			failures,
		)
		_check(
			&"calendar_overflow" in first_sequence.slice(0, rotation_size)
			and &"credit_town_hall" in first_sequence.slice(0, rotation_size),
			"docket %d should include both new management-credit cases in every complete rotation" % seed,
			failures,
		)
		for rotation_index in 3:
			var rotation_start := rotation_index * rotation_size
			var rotation: Array = first_sequence.slice(rotation_start, rotation_start + rotation_size)
			_check(_contains_every_incident_once(rotation), "docket %d rotation %d should contain every standard incident exactly once" % [seed, rotation_index + 1], failures)
		for index in range(1, first_sequence.size()):
			_check(first_sequence[index] != first_sequence[index - 1], "docket %d should never repeat a standard incident back-to-back" % seed, failures)
		rotation_signatures[JSON.stringify(first_sequence.slice(rotation_size, rotation_size * 3))] = true
	_check(rotation_signatures.size() >= 2, "the three replay dockets should produce at least two distinct post-onboarding rotations", failures)

	var legacy := DepartmentSimulation.new(1701, 4)
	_check(_open_incident(legacy, 1, 0) == &"ledger_molt", "legacy docket should preserve day-one ledger onboarding", failures)
	_check(_open_incident(legacy, 1, 1) == &"wellness_request", "legacy docket should preserve day-one welfare onboarding", failures)
	_check(_open_incident(legacy, 3, 0) == &"ledger_molt", "legacy docket should preserve the shipped day-three balance schedule", failures)
	_check(_open_incident(legacy, 3, 1) == &"wellness_request", "legacy docket should preserve the shipped day-three second incident", failures)
	_check(DepartmentSimulation.INCIDENT_ORDER.size() == 6, "new dockets should rotate through six standard incidents", failures)
	_check(DepartmentSimulation.LEGACY_INCIDENT_ORDER.size() == 4, "the legacy docket should retain its exact four-case cadence", failures)
	_check_incident_tradeoffs(failures)

	var source := DepartmentSimulation.new(1701, 4, 4703)
	_draw_incidents(source, 5)
	var encoded: Variant = JSON.parse_string(JSON.stringify(source.export_save_state()))
	var restored := DepartmentSimulation.new(1701, 4)
	_check(encoded is Dictionary and restored.restore_save_state(encoded as Dictionary), "a mid-rotation docket should survive a Web-safe JSON round trip", failures)
	_check(source.case_docket_snapshot() == restored.case_docket_snapshot(), "restore should preserve the visible docket identity and rotation position", failures)
	_check(_draw_incidents(source, 11) == _draw_incidents(restored, 11), "restore should preserve all future incident draws exactly", failures)

	var valid := DepartmentSimulation.new(1701, 4, 7919)
	_draw_incidents(valid, 1)
	var valid_state := valid.export_save_state()
	_check_rejected(valid_state, func(state: Dictionary) -> void: state["career_seed"] = 0, "out-of-range career seed", failures)
	_check_rejected(valid_state, func(state: Dictionary) -> void: state["incident_rng_state"] = "not-an-integer", "invalid incident RNG state", failures)
	_check_rejected(valid_state, func(state: Dictionary) -> void: state["incident_bag"] = ["ledger_molt", "ledger_molt"], "duplicate incident bag", failures)
	_check_rejected(valid_state, func(state: Dictionary) -> void: state["incident_bag"] = ["unknown_case"], "unknown incident bag entry", failures)
	_check_rejected(valid_state, func(state: Dictionary) -> void: state["last_standard_incident_id"] = String((state["incident_bag"] as Array)[0]), "last incident left inside bag", failures)

	var legacy_v23 := DepartmentSimulation.new(1701, 4, 12011).export_save_state()
	legacy_v23["state_version"] = 23
	for field in ["career_seed", "incident_rng_state", "incident_bag", "last_standard_incident_id"]:
		legacy_v23.erase(field)
	var migrated := DepartmentSimulation.new(4703, 4)
	_check(migrated.restore_save_state(legacy_v23), "an authentic v23 checkpoint should migrate into the neutral legacy docket", failures)
	_check(int(migrated.export_save_state().get("state_version", -1)) == 25, "v23 migration should re-export as schema v25", failures)
	_check(String(migrated.case_docket_snapshot().get("id", "")) == "PO-1701", "v23 migration should preserve the historical career identity", failures)
	var smuggled_v23 := DepartmentSimulation.new(1701, 4).export_save_state()
	smuggled_v23["state_version"] = 23
	_check(not DepartmentSimulation.new(4703, 4).restore_save_state(smuggled_v23), "a claimed v23 checkpoint must not smuggle v24 docket authority", failures)

	if failures.is_empty():
		print("INCIDENT_DOCKET_VARIETY_TEST_PASSED dockets=4 rotation_cases=6 rotations=18 tradeoffs=management+credit persisted=true migration=v23_to_v24")
		quit(0)
		return
	for failure in failures:
		push_error("INCIDENT_DOCKET_VARIETY_TEST_FAILED: %s" % failure)
	quit(1)


func _draw_incidents(simulation: DepartmentSimulation, count: int) -> Array[StringName]:
	var result: Array[StringName] = []
	for _index in count:
		result.append(simulation._next_standard_incident_id())
	return result


func _open_incident(simulation: DepartmentSimulation, target_day: int, slot: int) -> StringName:
	simulation.day = target_day
	simulation._incident_slot = slot
	simulation.minute_of_day = DepartmentSimulation.INCIDENT_MINUTES[slot]
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	simulation.pending_decision.clear()
	if not simulation._maybe_open_incident():
		return &""
	return StringName(simulation.pending_decision_snapshot().get("id", &""))


func _contains_every_incident_once(rotation: Array) -> bool:
	if rotation.size() != DepartmentSimulation.INCIDENT_ORDER.size():
		return false
	var seen: Dictionary[StringName, bool] = {}
	for incident_value in rotation:
		var incident_id := StringName(incident_value)
		if incident_id not in DepartmentSimulation.INCIDENT_ORDER or seen.has(incident_id):
			return false
		seen[incident_id] = true
	return seen.size() == DepartmentSimulation.INCIDENT_ORDER.size()


func _check_incident_tradeoffs(failures: Array[String]) -> void:
	var calendar_fast := DepartmentSimulation.new(1701, 4, 4703)
	var calendar_favor := DepartmentSimulation.new(1701, 4, 4703)
	var base_favor := calendar_fast.executive_confidence
	var base_trust := calendar_fast.workers[0].manager_trust
	var base_compliance := calendar_favor.compliance
	var calendar_fast_base_compliance := calendar_fast.compliance
	calendar_fast._apply_incident_effects(&"calendar_overflow", &"cancel_status_sync")
	calendar_favor._apply_incident_effects(&"calendar_overflow", &"attend_status_sync")
	_check(
		is_equal_approx(calendar_fast._incident_work_multiplier, 1.06)
		and is_equal_approx(calendar_fast._incident_crack_modifier, -0.02)
		and is_equal_approx(calendar_fast.compliance, minf(100.0, calendar_fast_base_compliance + 2.0))
		and is_equal_approx(calendar_fast.executive_confidence, base_favor - 2.0)
		and is_equal_approx(calendar_fast.workers[0].manager_trust, base_trust + 2.0),
		"canceling status sync should exchange two favor for exact production and trust gains",
		failures,
	)
	_check(
		is_equal_approx(calendar_favor._incident_work_multiplier, 0.93)
		and is_equal_approx(calendar_favor.executive_confidence, base_favor + 8.0)
		and is_equal_approx(calendar_favor.compliance, minf(100.0, base_compliance + 2.0)),
		"attending status sync should exchange production time for exact favor and obedience gains",
		failures,
	)

	var layer_credit := DepartmentSimulation.new(1701, 4, 4703)
	var rooster_credit := DepartmentSimulation.new(1701, 4, 4703)
	var base_morale := layer_credit.workers[0].morale
	var base_stress := layer_credit.workers[0].stress
	var base_fatigue := layer_credit.workers[0].fatigue
	var base_grievance := layer_credit.workers[0].grievance
	var layer_credit_base_compliance := layer_credit.compliance
	layer_credit._apply_incident_effects(&"credit_town_hall", &"credit_layers")
	rooster_credit._apply_incident_effects(&"credit_town_hall", &"credit_roosters")
	_check(
		is_equal_approx(layer_credit.workers[0].morale, minf(100.0, base_morale + 8.0))
		and is_equal_approx(layer_credit.workers[0].stress, maxf(0.0, base_stress - 6.0))
		and is_equal_approx(layer_credit.workers[0].fatigue, maxf(0.0, base_fatigue - 4.0))
		and is_equal_approx(layer_credit.workers[0].grievance, maxf(0.0, base_grievance - 5.0))
		and is_equal_approx(layer_credit.executive_confidence, base_favor - 2.0)
		and is_equal_approx(layer_credit.compliance, minf(100.0, layer_credit_base_compliance + 4.0))
		and layer_credit._pending_quota_adjustment == -1
		and is_equal_approx(layer_credit._incident_crack_modifier, -0.01)
		and is_equal_approx(layer_credit._incident_golden_modifier, 0.02),
		"crediting layers should exchange two favor for morale, grievance, and golden output exactly",
		failures,
	)
	_check(
		is_equal_approx(rooster_credit._incident_work_multiplier, 1.05)
		and is_equal_approx(rooster_credit.executive_confidence, base_favor + 10.0)
		and is_equal_approx(rooster_credit.workers[0].grievance, minf(100.0, base_grievance + 6.0)),
		"crediting roosters should trade exact favor and speed for relationship debt",
		failures,
	)
	var catalog_simulation := DepartmentSimulation.new(1701, 4, 4703)
	for incident_id in DepartmentSimulation.INCIDENT_ORDER:
		for choice in catalog_simulation._incident_choices(incident_id):
			_check(
				not String(choice.get("tagline", "")).is_empty(),
				"%s choice %s should disclose its strategic tradeoff before selection" % [
					String(incident_id), String(choice.get("id", "")),
				],
				failures,
			)


func _check_rejected(
	valid_state: Dictionary,
	mutator: Callable,
	label: String,
	failures: Array[String],
) -> void:
	var target := DepartmentSimulation.new(1701, 4)
	var before := JSON.stringify(target.export_save_state())
	var corrupt := valid_state.duplicate(true)
	mutator.call(corrupt)
	_check(not target.restore_save_state(corrupt), "%s should be rejected" % label, failures)
	_check(JSON.stringify(target.export_save_state()) == before, "%s rejection should remain atomic" % label, failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
