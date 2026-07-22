extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_check_layer_credit_to_calendar(failures)
	_check_rooster_credit_to_calendar(failures)
	_check_calendar_to_credit(failures)
	_check_resolution_and_persistence(failures)
	_check_migration_and_rejection(failures)

	if failures.is_empty():
		print("INCIDENT_FOLLOW_THROUGH_TEST_PASSED branches=4 exact_effects=true persistence=v26 bounded=24 review=true")
		quit(0)
		return
	for failure in failures:
		push_error("INCIDENT_FOLLOW_THROUGH_TEST_FAILED: %s" % failure)
	quit(1)


func _check_layer_credit_to_calendar(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(1701, 4, 4703)
	simulation._decision_serial = 1
	simulation._record_standard_incident_response(&"credit_town_hall", &"credit_layers", 1, 1)
	var memory := simulation.incident_follow_through_snapshot(&"calendar_overflow")
	var active_precedent := simulation.active_incident_precedent_snapshot()
	_check(
		StringName(memory.get("id", &"")) == &"layers_named_to_calendar"
		and StringName(memory.get("affected_option_id", &"")) == &"cancel_status_sync",
		"crediting layers should create a visible cancel-sync follow-through",
		failures,
	)
	_check(
		String(active_precedent.get("target_label", "")) == "NEXT MEETING OVERFLOW"
		and "from +2 to +4 flock trust" in String(active_precedent.get("summary", "")),
		"the open docket should forecast the exact next-case consequence of layer credit",
		failures,
	)
	var cancel_choice := _choice(simulation, &"calendar_overflow", &"cancel_status_sync")
	_check("flock trust +4" in String(cancel_choice.get("preview", "")), "layer credit should disclose the exact +4 trust total", failures)
	var cancel_precedent := cancel_choice.get("precedent", {}) as Dictionary
	_check(
		String(cancel_precedent.get("target_label", "")) == "NEXT CREDIT TOWN HALL"
		and "from $10 to $6" in String(cancel_precedent.get("summary", "")),
		"canceling a sync should forecast its exact future layer-credit discount before authorization",
		failures,
	)
	var base_trust := simulation.workers[0].manager_trust
	simulation._apply_incident_effects(&"calendar_overflow", &"cancel_status_sync", memory)
	_check(
		is_equal_approx(simulation.workers[0].manager_trust, minf(100.0, base_trust + 4.0)),
		"layer credit should add exactly two follow-through trust points beyond the base response",
		failures,
	)


func _check_rooster_credit_to_calendar(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(1701, 4, 4703)
	simulation._record_standard_incident_response(&"credit_town_hall", &"credit_roosters", 1, 1)
	var memory := simulation.incident_follow_through_snapshot(&"calendar_overflow")
	var attend_choice := _choice(simulation, &"calendar_overflow", &"attend_status_sync")
	_check("+10 farmer favor" in String(attend_choice.get("preview", "")), "rooster credit should disclose the exact +10 attend-sync favor total", failures)
	var base_favor := simulation.executive_confidence
	simulation._apply_incident_effects(&"calendar_overflow", &"attend_status_sync", memory)
	_check(is_equal_approx(simulation.executive_confidence, minf(100.0, base_favor + 10.0)), "rooster credit should add exactly two follow-through favor points", failures)


func _check_calendar_to_credit(failures: Array[String]) -> void:
	var canceled := DepartmentSimulation.new(1701, 4, 4703)
	canceled._record_standard_incident_response(&"calendar_overflow", &"cancel_status_sync", 1, 1)
	var layer_choice := _choice(canceled, &"credit_town_hall", &"credit_layers")
	_check(
		int(layer_choice.get("cost_cents", -1)) == 600
		and "Cost $6" in String(layer_choice.get("preview", "")),
		"a canceled sync should lower the authoritative layer-credit cost from $10 to $6",
		failures,
	)

	var attended := DepartmentSimulation.new(1701, 4, 4703)
	attended._record_standard_incident_response(&"calendar_overflow", &"attend_status_sync", 1, 1)
	var memory := attended.incident_follow_through_snapshot(&"credit_town_hall")
	var rooster_choice := _choice(attended, &"credit_town_hall", &"credit_roosters")
	_check("+12 farmer favor" in String(rooster_choice.get("preview", "")), "attending every sync should disclose the exact +12 rooster-credit favor total", failures)
	var base_favor := attended.executive_confidence
	attended._apply_incident_effects(&"credit_town_hall", &"credit_roosters", memory)
	_check(is_equal_approx(attended.executive_confidence, minf(100.0, base_favor + 12.0)), "sync attendance should add exactly two follow-through favor points", failures)


func _check_resolution_and_persistence(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(1701, 4, 4703)
	simulation._decision_serial = 1
	simulation._record_standard_incident_response(&"calendar_overflow", &"cancel_status_sync", 1, 1)
	var memory := simulation.incident_follow_through_snapshot(&"credit_town_hall")
	simulation._decision_serial = 2
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT
	simulation.pending_decision = {
		"serial": 2,
		"kind": &"incident",
		"id": &"credit_town_hall",
		"day": 1,
		"case_memory": memory,
		"options": simulation._incident_choices(&"credit_town_hall"),
	}
	var opening_fund := simulation.revenue_cents
	var announcements: Array[String] = []
	var resolutions: Array[Dictionary] = []
	simulation.announcement_posted.connect(func(message: String) -> void:
		announcements.append(message)
	)
	simulation.decision_resolved.connect(func(result: Dictionary) -> void:
		resolutions.append(result.duplicate(true))
	)
	_check(simulation._resolve_incident(&"credit_layers"), "the discounted follow-through choice should resolve", failures)
	_check(simulation.revenue_cents == opening_fund - 600, "resolution should debit the exact discounted $6 cost", failures)
	var resolution: Dictionary = resolutions[0] if not resolutions.is_empty() else {}
	var filed_precedent := resolution.get("filed_precedent", {}) as Dictionary
	_check(
		String(filed_precedent.get("target_label", "")) == "NEXT MEETING OVERFLOW"
		and "from +2 to +4 flock trust" in String(filed_precedent.get("summary", "")),
		"resolution should return the exact future precedent that was just filed",
		failures,
	)
	_check(
		announcements.size() == 1
		and announcements[0] == String(resolution.get("resolution_summary", ""))
		and "PRECEDENT FILED / NEXT MEETING OVERFLOW" in announcements[0],
		"the durable resolution announcement should preserve the immediate outcome and exact precedent",
		failures,
	)
	var day_responses := simulation.incident_responses_for_day(1)
	_check(
		day_responses.size() == 2
		and String((day_responses[0] as Dictionary).get("summary", "")) == "MEETING OVERFLOW / CANCEL THE STATUS SYNC"
		and String((day_responses[1] as Dictionary).get("summary", "")) == "CREDIT TOWN HALL / CREDIT THE LAYERS",
		"the review ledger should name both actual authored responses in order",
		failures,
	)

	var persisted := DepartmentSimulation.new(1701, 4, 4703)
	persisted._decision_serial = 2
	persisted._record_standard_incident_response(&"calendar_overflow", &"cancel_status_sync", 1, 1)
	persisted._record_standard_incident_response(&"credit_town_hall", &"credit_layers", 1, 2)
	var encoded: Variant = JSON.parse_string(JSON.stringify(persisted.export_save_state()))
	var restored := DepartmentSimulation.new(1701, 4)
	_check(encoded is Dictionary and restored.restore_save_state(encoded as Dictionary), "response history should survive a Web-safe round trip", failures)
	_check(restored.incident_responses_for_day(1) == day_responses, "restore should preserve exact response review snapshots", failures)
	_check(restored.active_incident_precedent_snapshot() == persisted.active_incident_precedent_snapshot(), "restore should preserve the visible open precedent", failures)
	_check(
		restored.incident_follow_through_snapshot(&"calendar_overflow") == persisted.incident_follow_through_snapshot(&"calendar_overflow"),
		"restore should preserve deterministic future case memory",
		failures,
	)

	for serial in range(3, 31):
		simulation._record_standard_incident_response(&"ledger_molt", &"spreadsheet", 1, serial)
	_check(simulation.incident_response_history.size() == 24, "the response ledger should remain bounded to 24 records", failures)
	_check(int(simulation.incident_response_history.front().get("serial", 0)) == 7, "bounded history should discard only the oldest records", failures)


func _check_migration_and_rejection(failures: Array[String]) -> void:
	var current := DepartmentSimulation.new(1701, 4, 4703).export_save_state()
	_check(DepartmentSimulation.new(1701, 4, 4703).active_incident_precedent_snapshot().is_empty(), "a fresh docket should not invent an open precedent", failures)
	var legacy_v25 := current.duplicate(true)
	legacy_v25["state_version"] = 25
	legacy_v25.erase("incident_response_history")
	var migrated := DepartmentSimulation.new(1701, 4)
	_check(migrated.restore_save_state(legacy_v25), "an authentic v25 checkpoint should migrate with neutral case memory", failures)
	_check(
		int(migrated.export_save_state().get("state_version", -1)) == 26
		and migrated.incident_response_history.is_empty(),
		"v25 migration should re-export as v26 without inventing prior choices",
		failures,
	)

	var smuggled_v25 := current.duplicate(true)
	smuggled_v25["state_version"] = 25
	_check(not DepartmentSimulation.new(1701, 4).restore_save_state(smuggled_v25), "a claimed v25 checkpoint must not smuggle response authority", failures)

	var valid_sim := DepartmentSimulation.new(1701, 4, 4703)
	valid_sim._decision_serial = 2
	valid_sim._record_standard_incident_response(&"ledger_molt", &"spreadsheet", 1, 1)
	valid_sim._record_standard_incident_response(&"wellness_request", &"deny_breaks", 1, 2)
	var valid := valid_sim.export_save_state()
	_check_rejected(valid, func(state: Dictionary) -> void:
		(state["incident_response_history"] as Array)[0]["option_id"] = "unknown_response"
	, "unknown response option", failures)
	_check_rejected(valid, func(state: Dictionary) -> void:
		(state["incident_response_history"] as Array)[1]["serial"] = 1
	, "non-increasing response serial", failures)
	_check_rejected(valid, func(state: Dictionary) -> void:
		(state["incident_response_history"] as Array)[0]["day"] = 2
	, "future response day", failures)


func _choice(
	simulation: DepartmentSimulation,
	incident_id: StringName,
	option_id: StringName,
) -> Dictionary:
	for choice in simulation._incident_choices(incident_id):
		if StringName(choice.get("id", &"")) == option_id:
			return choice
	return {}


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
