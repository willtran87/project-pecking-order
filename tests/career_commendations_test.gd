extends SceneTree

const Commendations := preload("res://core/campaign/career_commendations.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var fresh := Commendations.evaluate(
		{
			"eggs_total": 0,
			"best_quality_streak": 0,
			"market_contracts_succeeded_total": 0,
			"office_capacity": 4,
			"owned_facilities": {},
		},
		{
			"completed_shifts": 0,
			"outcome": "in_progress",
			"milestone": {"selected_id": ""},
		},
		{"status": "inactive", "total_senior_shifts": 0, "mandate_seals": 0},
	)
	_check(int(fresh.get("earned_count", -1)) == 0, "fresh career should begin with no invented commendations", failures)
	_check(int(fresh.get("total_count", -1)) == 12, "career ledger should expose exactly twelve stable commendations", failures)
	_check((fresh.get("rows", []) as Array).size() == 12, "every stable commendation should have one presentation row", failures)
	_check(String((fresh.get("next", {}) as Dictionary).get("id", "")) == "first_egg", "first credited egg should be the opening stamp", failures)
	_check(_unique_ids(fresh).size() == 12, "commendation IDs should be unique and stable", failures)

	var growing_simulation := {
		"eggs_total": 17,
		"best_quality_streak": 11,
		"market_contracts_succeeded_total": 2,
		"office_capacity": 5,
		"owned_facilities": {"records_annex": 2},
	}
	var growing_campaign := {
		"completed_shifts": 2,
		"outcome": "in_progress",
		"milestone": {"selected_id": ""},
	}
	var growing := Commendations.evaluate(growing_simulation, growing_campaign)
	_check(int(growing.get("earned_count", -1)) == 1, "only the permanent first-egg fact should be filed in the partial fixture", failures)
	_check(bool(_row(growing, &"first_egg").get("earned", false)), "first egg should file from the cumulative egg ledger", failures)
	_check(not bool(_row(growing, &"clean_dozen").get("earned", true)), "an eleven-egg best chain must not round into a clean dozen", failures)
	_check(String(_row(growing, &"clean_dozen").get("progress_label", "")) == "11 / 12 CLEAN CHAIN", "near-complete clean chain should disclose exact progress", failures)
	_check(String((growing.get("next", {}) as Dictionary).get("id", "")) == "doctrine_filed", "next stamp should follow the authored career cadence", failures)

	var adapting := Commendations.evaluate({"incident_pivot_mastery": {"mastered_count": 2}}, {})
	_check(not bool(_row(adapting, &"adaptive_casework").get("earned", true)), "two mastered case pairs should not file adaptive casework early", failures)
	_check(String(_row(adapting, &"adaptive_casework").get("progress_label", "")) == "2 / 3 CASE PAIRS", "adaptive casework should disclose exact permanent progress", failures)

	var failed_campaign := growing_campaign.duplicate(true)
	failed_campaign["completed_shifts"] = 5
	failed_campaign["outcome"] = "failed"
	var failed := Commendations.evaluate(growing_simulation, failed_campaign)
	_check(not bool(_row(failed, &"probation_survivor").get("earned", true)), "closing five shifts without safeguards must not award probation survival", failures)
	_check("SAFEGUARDS MISSED" in String(_row(failed, &"probation_survivor").get("progress_label", "")), "failed final file should explain the remaining achievement blocker", failures)

	var complete_simulation := growing_simulation.duplicate(true)
	complete_simulation["best_quality_streak"] = 12
	complete_simulation["market_contracts_succeeded_total"] = 3
	complete_simulation["office_capacity"] = 6
	complete_simulation["owned_facilities"] = {
		"records_annex": 1,
		"wellness_nest_room": 1,
		"training_roost": 1,
	}
	complete_simulation["incident_pivot_mastery"] = {"mastered_count": 3}
	var complete_campaign := {
		"completed_shifts": 5,
		"outcome": "passed",
		"milestone": {"selected_id": "shell_quality_lab"},
	}
	var complete_senior := {
		"status": "active",
		"total_senior_shifts": 1,
		"mandate_seals": 1,
		"mandate_mastery": {"mastered_count": 7},
	}
	var complete := Commendations.evaluate(complete_simulation, complete_campaign, complete_senior)
	_check(int(complete.get("earned_count", -1)) == 12 and bool(complete.get("complete", false)), "all twelve permanent source facts should complete the archive", failures)
	_check((complete.get("next", {}) as Dictionary).is_empty(), "complete archive should expose no phantom next stamp", failures)
	var compact := Commendations.compact_snapshot(complete)
	_check(not compact.has("rows"), "browser diagnostic should omit full commendation prose and row history", failures)
	_check((compact.get("earned_ids", []) as Array).size() == 12, "compact diagnostic should retain every stable earned ID", failures)

	var portfolio := Commendations.evaluate({}, {}, {
		"mandate_success_counts": {
			"standard_board_book": 4,
			"shell_stewardship": 1,
			"flock_continuity": 1,
		},
	})
	_check(bool(_row(portfolio, &"board_portfolio").get("earned", false)), "three distinct successful Books should file the strategy portfolio stamp", failures)
	_check(String(_row(portfolio, &"board_portfolio").get("progress_label", "")) == "3 / 3 DISTINCT BOOKS", "portfolio stamp should count distinct Books rather than repeat clears", failures)
	_check(not bool(_row(portfolio, &"complete_board_ledger").get("earned", true)), "three Books must not complete the seven-Book master ledger", failures)
	_check(String(_row(portfolio, &"complete_board_ledger").get("progress_label", "")) == "3 / 7 DISTINCT BOOKS", "master-ledger row should disclose exact remaining variety", failures)

	var malformed := Commendations.evaluate({"owned_facilities": "invalid"}, {"milestone": []}, {"status": 42})
	_check(int(malformed.get("earned_count", -1)) == 0, "malformed presentation inputs should fail closed without inventing recognition", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("CAREER_COMMENDATIONS_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAREER_COMMENDATIONS_TEST_PASSED count=12 sources=permanent adaptive=3-pairs portfolio=distinct-books next=ordered final=safeguarded diagnostic=compact")
	quit(0)


func _row(snapshot: Dictionary, id: StringName) -> Dictionary:
	for value: Variant in snapshot.get("rows", []):
		if value is Dictionary and StringName((value as Dictionary).get("id", &"")) == id:
			return value as Dictionary
	return {}


func _unique_ids(snapshot: Dictionary) -> Dictionary:
	var ids: Dictionary = {}
	for value: Variant in snapshot.get("rows", []):
		if value is Dictionary:
			ids[String((value as Dictionary).get("id", ""))] = true
	return ids


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
