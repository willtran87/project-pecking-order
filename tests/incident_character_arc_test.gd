extends SceneTree

const DialogueCatalog := preload("res://features/office/character_dialogue_catalog.gd")


func _init() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(1701, 4, 4703)
	var first_arc := simulation.incident_character_arc_snapshot(&"nest_heatwave")
	var paired_arc := simulation.incident_character_arc_snapshot(&"cold_storage_audit")
	_check(
		not first_arc.is_empty()
		and int(first_arc.get("worker_id", -1)) == int(paired_arc.get("worker_id", -2))
		and String(first_arc.get("worker_name", "")).to_lower() == String(first_arc.get("speaker_id", "")),
		"both halves of a connected case should belong to one stable named hen",
		failures,
	)
	_check(
		StringName(first_arc.get("standing", &"")) == &"forming"
		and not String(first_arc.get("request", "")).is_empty(),
		"a first witnessed file should disclose the hen's persistent relationship stage",
		failures,
	)

	var result_events: Array[Dictionary] = []
	simulation.decision_resolved.connect(func(result: Dictionary) -> void:
		result_events.append(result.duplicate(true))
	)
	var witness_id := int(first_arc.get("worker_id", -1))
	var witness_before: ChickenState
	for worker in simulation.workers:
		if worker.id == witness_id:
			witness_before = worker
			break
	var trust_before := witness_before.manager_trust if witness_before != null else -1.0
	simulation._decision_serial = 1
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT
	simulation.pending_decision = {
		"serial": 1,
		"kind": &"incident",
		"id": &"nest_heatwave",
		"day": 1,
		"character_arc": first_arc,
		"options": simulation._incident_choices(&"nest_heatwave"),
	}
	_check(simulation._resolve_incident(&"seasonal_variance"), "the witnessed incident should resolve normally", failures)
	var result: Dictionary = result_events[0] if not result_events.is_empty() else {}
	var resolved_arc := result.get("character_arc", {}) as Dictionary
	_check(
		int(resolved_arc.get("worker_id", -1)) == witness_id
		and StringName(resolved_arc.get("tone", &"")) == &"danger"
		and float(resolved_arc.get("trust_after", 999.0)) < trust_before,
		"the result should preserve the witness and expose the relationship consequence",
		failures,
	)
	_check(
		not String(resolved_arc.get("standing_label_after", "")).is_empty(),
		"the resolution should expose the witness's updated standing for later callbacks",
		failures,
	)
	var reaction := DialogueCatalog.beat_for_decision_result(result, 1)
	_check(
		StringName(reaction.get("speaker_id", &"")) == StringName(first_arc.get("speaker_id", &""))
		and "That was my file" in String(reaction.get("text", ""))
		and "I won't" in String(reaction.get("text", "")),
		"the named witness should react in her own portrait cutout after a harmful response",
		failures,
	)
	var callback_arc := simulation.incident_character_arc_snapshot(&"cold_storage_audit")
	_check(
		int(callback_arc.get("worker_id", -1)) == witness_id
		and int(callback_arc.get("beat", 0)) == 2
		and "CALLBACK" in String(callback_arc.get("beat_label", "")),
		"the paired incident should return to the same hen as an explicit second beat",
		failures,
	)

	if failures.is_empty():
		print("INCIDENT_CHARACTER_ARC_TEST_PASSED witnesses=stable callbacks=paired consequences=relationship dialogue=named")
		quit(0)
		return
	for failure in failures:
		push_error("INCIDENT_CHARACTER_ARC_TEST_FAILED: %s" % failure)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
