extends SceneTree

const SimulationScript := preload("res://core/simulation/department_simulation.gd")
const CampaignScript := preload("res://core/campaign/campaign_state.gd")
const ArchiveScript := preload("res://core/campaign/career_run_archive.gd")


func _init() -> void:
	var failures: Array[String] = []
	_test_scenario_openings(failures)
	_test_final_hearing(failures)
	_test_run_archive(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("FINAL_HEARING_AND_REPLAY_STRUCTURE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FINAL_HEARING_AND_REPLAY_STRUCTURE_TEST_PASSED scenarios=6 openings=distinct climax=playable witness=named charter=persisted archive=bounded+comparative")
	quit(0)


func _test_scenario_openings(failures: Array[String]) -> void:
	var observed_counts: Dictionary[String, int] = {}
	var observed_rules: Dictionary[String, String] = {}
	for seed in SimulationScript.AUTHORED_SCENARIO_SEEDS:
		var simulation := SimulationScript.new(1701, 4, seed) as DepartmentSimulation
		var campaign := CampaignScript.new() as CampaignState
		var result := simulation.configure_opening_challenge(campaign.challenge_contract_snapshot())
		_check(bool(result.get("accepted", false)), "authored scenario %d should accept the standard opening" % seed, failures)
		var scenario := simulation.scenario_identity_snapshot()
		var scenario_id := String(scenario.get("id", ""))
		observed_counts[scenario_id] = int(result.get("live_files", 0))
		observed_rules[scenario_id] = String(scenario.get("opening_rule", ""))
		_check(not observed_rules[scenario_id].is_empty(), "%s should disclose its structural opening" % scenario_id, failures)
		_check(not String(scenario.get("climax_title", "")).is_empty(), "%s should disclose its authored climax" % scenario_id, failures)
	_check(int(observed_counts.get("harvest_surge", 0)) == 8, "Harvest Surge should open with two visible rush files", failures)
	_check(int(observed_counts.get("shell_audit", 0)) == 8, "Shell Audit should open with two visible appeal files", failures)
	_check(int(observed_counts.get("flock_walkout", 0)) == 6, "Flock Walkout should change worker state instead of adding files", failures)
	_check(int(observed_counts.get("thin_margin", 0)) == 6, "Thin Margin should change cash and quota instead of adding files", failures)
	_check(int(observed_counts.get("fox_season", 0)) == 8, "Fox Season should open with two visible predator files", failures)
	_check(int(observed_counts.get("credit_scramble", 0)) == 8, "Credit Scramble should open with two visible repair files", failures)
	_check(observed_counts.size() == 6, "the replay catalog should expose six distinct authored pressures", failures)


func _test_final_hearing(failures: Array[String]) -> void:
	var simulation := SimulationScript.new(1701, 4, 12011) as DepartmentSimulation
	var campaign := CampaignScript.new() as CampaignState
	_check(bool(simulation.configure_opening_challenge(campaign.challenge_contract_snapshot()).get("accepted", false)), "finale fixture should configure", failures)
	simulation.day = DepartmentSimulation.PROBATION_CAMPAIGN_SHIFTS
	simulation.minute_of_day = DepartmentSimulation.INCIDENT_MINUTES.back()
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	simulation.set("_incident_slot", DepartmentSimulation.INCIDENT_MINUTES.size() - 1)
	_check(bool(simulation.call("_maybe_open_incident")), "the last Shift 5 incident slot should open the Final Hearing", failures)
	var pending := simulation.pending_decision_snapshot()
	_check(StringName(pending.get("id", &"")) == DepartmentSimulation.FINAL_HEARING_INCIDENT_ID, "the climax should replace the routine second incident", failures)
	_check((pending.get("options", []) as Array).size() == 3, "the Final Hearing should expose three permanent charters", failures)
	var arc := pending.get("character_arc", {}) as Dictionary
	_check(not String(arc.get("worker_name", "")).is_empty(), "a named hen should witness the Final Hearing", failures)
	_check("PERMANENT CHOICE" in String(pending.get("eyebrow", "")), "the climax should communicate permanence before confirmation", failures)
	var serial := int(pending.get("serial", -1))
	_check(simulation.resolve_decision(serial, &"sign_flock_charter"), "the scenario-fit flock charter should resolve", failures)
	var hearing := simulation.final_hearing_snapshot()
	_check(bool(hearing.get("resolved", false)) and StringName(hearing.get("option_id", &"")) == &"sign_flock_charter", "the filed charter should become the derived final-hearing authority", failures)
	var saved := simulation.export_save_state()
	var history_validation: Dictionary = simulation.call(
		"_validated_incident_response_history",
		saved.get("incident_response_history", []),
		5,
	)
	_check(bool(history_validation.get("valid", false)), "the Final Hearing receipt should pass persisted incident-history validation", failures)
	_check(StringName(((history_validation.get("history", []) as Array).back() as Dictionary).get("option_id", &"")) == &"sign_flock_charter", "the persisted receipt should retain the permanent charter", failures)


func _test_run_archive(failures: Array[String]) -> void:
	var archive: RefCounted = ArchiveScript.new()
	var first := _archive_entry("run-1", 61, "harvest_surge", "eggceleration", true)
	var second := _archive_entry("run-2", 74, "shell_audit", "shell_assurance", true)
	_check(bool(archive.call("record", first)) and bool(archive.call("record", second)), "distinct completed runs should enter the archive", failures)
	_check(not bool(archive.call("record", second)), "reopening a final review must not duplicate a run", failures)
	var comparison: Dictionary = archive.call("comparison")
	_check(int(comparison.get("score_delta", 0)) == 13, "run history should compare the latest score to the previous file", failures)
	_check(int(comparison.get("scenario_count", 0)) == 2 and int(comparison.get("doctrine_count", 0)) == 2, "run history should expose mastery breadth", failures)
	var restored: RefCounted = ArchiveScript.new()
	_check(bool(restored.call("restore", archive.call("entries"))), "the bounded archive should validate and restore", failures)
	_check(int((restored.call("comparison") as Dictionary).get("run_count", 0)) == 2, "restored run history should retain its count", failures)


func _archive_entry(run_id: String, score: int, scenario_id: String, doctrine_id: String, passed: bool) -> Dictionary:
	return {
		"run_id": run_id,
		"scenario_id": scenario_id,
		"scenario_label": scenario_id.replace("_", " ").to_upper(),
		"contract_id": "standard_filing",
		"contract_label": "STANDARD",
		"doctrine_id": doctrine_id,
		"doctrine_label": doctrine_id.replace("_", " ").to_upper(),
		"hearing_choice_id": "publish_ledger",
		"hearing_choice_label": "OPEN LEDGER",
		"score": score,
		"welfare": 66,
		"compliance": 72,
		"farmer_favor": 63,
		"crack_rate_basis_points": 1200,
		"mastered_pairs": 2,
		"passed": passed,
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
