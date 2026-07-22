extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_check_layer_credit_to_calendar(failures)
	_check_rooster_credit_to_calendar(failures)
	_check_calendar_to_credit(failures)
	_check_ledger_story_pair(failures)
	_check_wellness_feed_pair(failures)
	_check_multiple_open_precedents(failures)
	_check_resolution_and_persistence(failures)
	_check_adaptive_pivot_mastery(failures)
	_check_migration_and_rejection(failures)

	if failures.is_empty():
		print("INCIDENT_FOLLOW_THROUGH_TEST_PASSED pairs=3 branches=12 exact_effects=true open_precedents=3 persistence=v27 bounded=24 review=true")
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
		StringName(memory.get("id", &"")) == &"layer_results_to_syncs"
		and StringName(memory.get("affected_option_id", &"")) == &"attend_status_sync"
		and String(memory.get("strategy_label", "")) == "PIVOT OPPORTUNITY",
		"crediting layers should create a visible attend-sync pivot",
		failures,
	)
	_check(
		String(active_precedent.get("target_label", "")) == "NEXT MEETING OVERFLOW"
		and "from +8 to +10 farmer favor" in String(active_precedent.get("summary", "")),
		"the open docket should forecast the exact next-case consequence of layer credit",
		failures,
	)
	var attend_choice := _choice(simulation, &"calendar_overflow", &"attend_status_sync")
	_check(
		"+10 farmer favor" in String(attend_choice.get("preview", ""))
		and bool(attend_choice.get("case_memory_active", false)),
		"layer credit should disclose the exact +10 pivot total on the affected response",
		failures,
	)
	var attend_precedent := attend_choice.get("precedent", {}) as Dictionary
	_check(
		String(attend_precedent.get("target_label", "")) == "NEXT CREDIT TOWN HALL"
		and "from $10 to $6" in String(attend_precedent.get("summary", "")),
		"attending the sync should forecast its exact future layer-credit pivot before authorization",
		failures,
	)
	var base_favor := simulation.executive_confidence
	simulation._apply_incident_effects(&"calendar_overflow", &"attend_status_sync", memory)
	_check(
		is_equal_approx(simulation.executive_confidence, minf(100.0, base_favor + 10.0)),
		"layer credit should add exactly two follow-through favor points beyond the base response",
		failures,
	)


func _check_rooster_credit_to_calendar(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(1701, 4, 4703)
	simulation._record_standard_incident_response(&"credit_town_hall", &"credit_roosters", 1, 1)
	var memory := simulation.incident_follow_through_snapshot(&"calendar_overflow")
	var cancel_choice := _choice(simulation, &"calendar_overflow", &"cancel_status_sync")
	_check("flock trust +4" in String(cancel_choice.get("preview", "")), "rooster credit should disclose the exact +4 cancel-sync trust total", failures)
	var base_trust := simulation.workers[0].manager_trust
	simulation._apply_incident_effects(&"calendar_overflow", &"cancel_status_sync", memory)
	_check(is_equal_approx(simulation.workers[0].manager_trust, minf(100.0, base_trust + 4.0)), "rooster credit should add exactly two follow-through trust points", failures)


func _check_calendar_to_credit(failures: Array[String]) -> void:
	var canceled := DepartmentSimulation.new(1701, 4, 4703)
	canceled._record_standard_incident_response(&"calendar_overflow", &"cancel_status_sync", 1, 1)
	var canceled_memory := canceled.incident_follow_through_snapshot(&"credit_town_hall")
	var rooster_choice := _choice(canceled, &"credit_town_hall", &"credit_roosters")
	_check("+12 farmer favor" in String(rooster_choice.get("preview", "")), "a canceled sync should disclose the exact +12 rooster-credit pivot", failures)
	var canceled_favor := canceled.executive_confidence
	canceled._apply_incident_effects(&"credit_town_hall", &"credit_roosters", canceled_memory)
	_check(is_equal_approx(canceled.executive_confidence, minf(100.0, canceled_favor + 12.0)), "a canceled sync should apply exactly +12 rooster-credit favor", failures)

	var attended := DepartmentSimulation.new(1701, 4, 4703)
	attended._record_standard_incident_response(&"calendar_overflow", &"attend_status_sync", 1, 1)
	var layer_choice := _choice(attended, &"credit_town_hall", &"credit_layers")
	_check(
		int(layer_choice.get("cost_cents", -1)) == 600
		and "Cost $6" in String(layer_choice.get("preview", "")),
		"attending every sync should lower the authoritative layer-credit cost from $10 to $6",
		failures,
	)


func _check_ledger_story_pair(failures: Array[String]) -> void:
	var polished := DepartmentSimulation.new(1701, 4, 4703)
	polished._record_standard_incident_response(&"farmer_story", &"polish_story", 1, 1)
	var patch := _choice(polished, &"ledger_molt", &"patch")
	_check(
		int(patch.get("cost_cents", -1)) == polished.ledger_molt_patch_cost_cents() - 400
		and "Cost $14.00" in String(patch.get("preview", "")),
		"a polished story should take exactly $4 off the current emergency-patch quote",
		failures,
	)

	var truthful := DepartmentSimulation.new(1701, 4, 4703)
	truthful._record_standard_incident_response(&"farmer_story", &"show_ledger", 1, 1)
	var spreadsheet := _choice(truthful, &"ledger_molt", &"spreadsheet")
	var truthful_memory := truthful.incident_follow_through_snapshot(&"ledger_molt")
	_check("+7% speed" in String(spreadsheet.get("preview", "")), "showing the ledger should disclose the exact +7% shadow-sheet pivot", failures)
	truthful._apply_incident_effects(&"ledger_molt", &"spreadsheet", truthful_memory)
	_check(is_equal_approx(truthful._incident_work_multiplier, 1.07), "showing the ledger should apply exactly 7% shadow-sheet speed", failures)

	var patched := DepartmentSimulation.new(1701, 4, 4703)
	patched._record_standard_incident_response(&"ledger_molt", &"patch", 1, 1)
	var polish_choice := _choice(patched, &"farmer_story", &"polish_story")
	var patched_memory := patched.incident_follow_through_snapshot(&"farmer_story")
	_check("+$20 fund" in String(polish_choice.get("preview", "")), "a clean audit should disclose the exact $20 story pivot", failures)
	var patched_fund := patched.revenue_cents
	patched._apply_incident_effects(&"farmer_story", &"polish_story", patched_memory)
	_check(patched.revenue_cents == patched_fund + 2000, "a clean audit should add exactly $20 for the polished story", failures)

	var shadow := DepartmentSimulation.new(1701, 4, 4703)
	shadow._record_standard_incident_response(&"ledger_molt", &"spreadsheet", 1, 1)
	var truth_choice := _choice(shadow, &"farmer_story", &"show_ledger")
	var shadow_memory := shadow.incident_follow_through_snapshot(&"farmer_story")
	_check("-4 farmer favor" in String(truth_choice.get("preview", "")), "a shadow sheet should disclose the reduced -4 truth pivot", failures)
	var shadow_favor := shadow.executive_confidence
	shadow._apply_incident_effects(&"farmer_story", &"show_ledger", shadow_memory)
	_check(is_equal_approx(shadow.executive_confidence, shadow_favor - 4.0), "a shadow sheet should reduce the truth response by exactly four favor", failures)


func _check_wellness_feed_pair(failures: Array[String]) -> void:
	var grain := DepartmentSimulation.new(1701, 4, 4703)
	grain._record_standard_incident_response(&"feed_shortfall", &"buy_grain", 1, 1)
	var deny_choice := _choice(grain, &"wellness_request", &"deny_breaks")
	var grain_memory := grain.incident_follow_through_snapshot(&"wellness_request")
	_check("+5 farmer favor" in String(deny_choice.get("preview", "")), "local grain should disclose the exact +5 denial pivot", failures)
	var grain_favor := grain.executive_confidence
	grain._apply_incident_effects(&"wellness_request", &"deny_breaks", grain_memory)
	_check(is_equal_approx(grain.executive_confidence, grain_favor + 5.0), "local grain should apply exactly +5 denial favor", failures)

	var portions := DepartmentSimulation.new(1701, 4, 4703)
	portions._record_standard_incident_response(&"feed_shortfall", &"optimize_portions", 1, 1)
	var break_choice := _choice(portions, &"wellness_request", &"grant_breaks")
	_check(int(break_choice.get("cost_cents", -1)) == 400 and "Cost $4" in String(break_choice.get("preview", "")), "optimized portions should lower the rotating-break pivot to exactly $4", failures)

	var breaks := DepartmentSimulation.new(1701, 4, 4703)
	breaks._record_standard_incident_response(&"wellness_request", &"grant_breaks", 1, 1)
	var optimize_choice := _choice(breaks, &"feed_shortfall", &"optimize_portions")
	var breaks_memory := breaks.incident_follow_through_snapshot(&"feed_shortfall")
	_check("Daily feed -$10" in String(optimize_choice.get("preview", "")), "covered breaks should disclose the exact $10 portion pivot", failures)
	breaks._apply_incident_effects(&"feed_shortfall", &"optimize_portions", breaks_memory)
	_check(breaks._incident_feed_adjustment_cents == -1000, "covered breaks should apply exactly $10 lower daily feed cost", failures)

	var denied := DepartmentSimulation.new(1701, 4, 4703)
	denied._record_standard_incident_response(&"wellness_request", &"deny_breaks", 1, 1)
	var grain_choice := _choice(denied, &"feed_shortfall", &"buy_grain")
	_check(int(grain_choice.get("cost_cents", -1)) == 1200 and "Cost $12" in String(grain_choice.get("preview", "")), "a denied break should lower the local-grain pivot to exactly $12", failures)


func _check_multiple_open_precedents(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(1701, 4, 4703)
	simulation._decision_serial = 3
	simulation._record_standard_incident_response(&"ledger_molt", &"patch", 1, 1)
	simulation._record_standard_incident_response(&"wellness_request", &"grant_breaks", 1, 2)
	simulation._record_standard_incident_response(&"calendar_overflow", &"cancel_status_sync", 1, 3)
	var precedents := simulation.active_incident_precedent_snapshots()
	_check(
		precedents.size() == 3
		and StringName(precedents[0].get("pair_id", &"")) == &"calendar_credit"
		and StringName(precedents[1].get("pair_id", &"")) == &"wellness_feed"
		and StringName(precedents[2].get("pair_id", &"")) == &"ledger_story",
		"the docket should retain one newest-first open precedent for each connected pair",
		failures,
	)
	_check(
		(simulation.case_docket_snapshot().get("active_precedents", []) as Array).size() == 3,
		"the public docket should expose all three bounded open precedents",
		failures,
	)
	simulation._decision_serial = 4
	simulation._record_standard_incident_response(&"farmer_story", &"show_ledger", 1, 4)
	precedents = simulation.active_incident_precedent_snapshots()
	_check(
		precedents.size() == 3
		and StringName(precedents[0].get("pair_id", &"")) == &"ledger_story"
		and String(precedents[0].get("target_label", "")) == "NEXT LEDGER MOLT",
		"a related response should replace its pair's open precedent instead of adding a duplicate",
		failures,
	)


func _check_resolution_and_persistence(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(1701, 4, 4703)
	simulation._decision_serial = 1
	simulation._record_standard_incident_response(&"calendar_overflow", &"attend_status_sync", 1, 1)
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
		and "from +8 to +10 farmer favor" in String(filed_precedent.get("summary", "")),
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
		and String((day_responses[0] as Dictionary).get("summary", "")) == "MEETING OVERFLOW / ATTEND EVERY STATUS SYNC"
		and String((day_responses[1] as Dictionary).get("summary", "")) == "CREDIT TOWN HALL / CREDIT THE LAYERS",
		"the review ledger should name both actual authored responses in order",
		failures,
	)

	var persisted := DepartmentSimulation.new(1701, 4, 4703)
	persisted._decision_serial = 2
	persisted._record_standard_incident_response(&"calendar_overflow", &"attend_status_sync", 1, 1)
	persisted._record_standard_incident_response(&"credit_town_hall", &"credit_layers", 1, 2)
	var encoded: Variant = JSON.parse_string(JSON.stringify(persisted.export_save_state()))
	var restored := DepartmentSimulation.new(1701, 4)
	_check(encoded is Dictionary and restored.restore_save_state(encoded as Dictionary), "response history should survive a Web-safe round trip", failures)
	_check(restored.incident_responses_for_day(1) == day_responses, "restore should preserve exact response review snapshots", failures)
	_check(restored.active_incident_precedent_snapshot() == persisted.active_incident_precedent_snapshot(), "restore should preserve the visible open precedent", failures)
	_check(restored.active_incident_precedent_snapshots() == persisted.active_incident_precedent_snapshots(), "restore should preserve every connected-pair precedent in newest-first order", failures)
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
	legacy_v25.erase("incident_pivot_mastery_receipts")
	var migrated := DepartmentSimulation.new(1701, 4)
	_check(migrated.restore_save_state(legacy_v25), "an authentic v25 checkpoint should migrate with neutral case memory", failures)
	_check(
		int(migrated.export_save_state().get("state_version", -1)) == 27
		and migrated.incident_response_history.is_empty(),
		"v25 migration should re-export as v27 without inventing prior choices",
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


func _check_adaptive_pivot_mastery(failures: Array[String]) -> void:
	var simulation := DepartmentSimulation.new(1701, 4, 4703)
	var sequence := [
		[&"ledger_molt", &"patch"],
		[&"farmer_story", &"polish_story"],
		[&"wellness_request", &"grant_breaks"],
		[&"feed_shortfall", &"optimize_portions"],
		[&"credit_town_hall", &"credit_layers"],
		[&"calendar_overflow", &"attend_status_sync"],
	]
	for index in sequence.size():
		var response: Array = sequence[index]
		simulation._record_standard_incident_response(
			StringName(response[0]),
			StringName(response[1]),
			1,
			index + 1,
		)
		if index in [1, 3]:
			_check(
				int(simulation.incident_pivot_mastery_snapshot().get("mastered_count", -1)) == (index + 1) / 2,
				"each first counterweight pivot should file one permanent case-pair receipt",
				failures,
			)
	simulation._decision_serial = sequence.size()
	var mastery := simulation.incident_pivot_mastery_snapshot()
	_check(
		int(mastery.get("mastered_count", -1)) == 3
		and bool(mastery.get("complete", false))
		and simulation.incident_pivot_mastery_receipts.size() == 3,
		"using the highlighted pivot in all three pairs should complete adaptive casework exactly once per pair",
		failures,
	)

	var encoded: Variant = JSON.parse_string(JSON.stringify(simulation.export_save_state()))
	var restored := DepartmentSimulation.new(1701, 4)
	_check(
		encoded is Dictionary
		and restored.restore_save_state(encoded as Dictionary)
		and restored.incident_pivot_mastery_snapshot() == mastery,
		"adaptive casework receipts should survive a Web-safe v27 round trip",
		failures,
	)

	var legacy_v26 := simulation.export_save_state()
	legacy_v26["state_version"] = 26
	legacy_v26.erase("incident_pivot_mastery_receipts")
	var migrated := DepartmentSimulation.new(1701, 4)
	_check(
		migrated.restore_save_state(legacy_v26)
		and int(migrated.export_save_state().get("state_version", -1)) == 27
		and int(migrated.incident_pivot_mastery_snapshot().get("mastered_count", -1)) == 3,
		"authentic v26 response history should reconstruct adaptive mastery without inventing evidence",
		failures,
	)

	var valid := simulation.export_save_state()
	_check_rejected(valid, func(state: Dictionary) -> void:
		(state["incident_pivot_mastery_receipts"] as Array)[0]["pair_id"] = "unknown_pair"
	, "unknown pivot mastery pair", failures)
	_check_rejected(valid, func(state: Dictionary) -> void:
		(state["incident_pivot_mastery_receipts"] as Array)[0]["pivot_option_id"] = "show_ledger"
	, "non-counterweight pivot receipt", failures)
	var smuggled_v26 := valid.duplicate(true)
	smuggled_v26["state_version"] = 26
	_check(
		not DepartmentSimulation.new(1701, 4).restore_save_state(smuggled_v26),
		"a claimed v26 checkpoint must not smuggle future adaptive mastery authority",
		failures,
	)


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
