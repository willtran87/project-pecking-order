class_name CareerRunArchive
extends RefCounted

## Small, bounded history of completed probation files. This is player-owned
## career context, not simulation authority: it compares runs without changing
## money, workers, scores, or unlocks.

const VERSION := 1
const MAX_ENTRIES := 8
const FLOCK_SAFE_WELFARE := 60
const GOLD_FILE_SCORE := 80

var _entries: Array[Dictionary] = []


func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _entries:
		result.append(entry.duplicate(true))
	return result


func record(entry: Dictionary) -> bool:
	var normalized := _normalized_entry(entry)
	if normalized.is_empty():
		return false
	var run_id := String(normalized["run_id"])
	for existing in _entries:
		if String(existing.get("run_id", "")) == run_id:
			return false
	_entries.append(normalized)
	while _entries.size() > MAX_ENTRIES:
		_entries.pop_front()
	return true


func restore(value: Variant) -> bool:
	if not value is Array or (value as Array).size() > MAX_ENTRIES:
		return false
	var restored: Array[Dictionary] = []
	var seen: Dictionary[String, bool] = {}
	for entry_value in value as Array:
		if not entry_value is Dictionary:
			return false
		var normalized := _normalized_entry(entry_value as Dictionary)
		if normalized.is_empty():
			return false
		var run_id := String(normalized["run_id"])
		if seen.has(run_id):
			return false
		seen[run_id] = true
		restored.append(normalized)
	_entries = restored
	return true


func comparison() -> Dictionary:
	if _entries.is_empty():
		return {
			"run_count": 0,
			"headline": "FIRST PERMANENT FILE",
			"detail": "Complete probation to establish a run record.",
			"scenario_mastery": [],
			"mastery_stamp_count": 0,
			"mastery_stamp_total": 0,
			"mastery_headline": "MASTERY 0 / 0",
			"mastery_detail": "Complete a scenario to begin its three-stamp mastery card.",
		}
	var current: Dictionary = _entries.back()
	var previous: Dictionary = _entries[_entries.size() - 2] if _entries.size() > 1 else {}
	var best_score := -1
	var passed_count := 0
	var scenario_ids: Dictionary[String, bool] = {}
	var doctrine_ids: Dictionary[String, bool] = {}
	for entry in _entries:
		best_score = maxi(best_score, int(entry.get("score", 0)))
		if bool(entry.get("passed", false)):
			passed_count += 1
		var scenario_id := String(entry.get("scenario_id", ""))
		if not scenario_id.is_empty():
			scenario_ids[scenario_id] = true
		var doctrine_id := String(entry.get("doctrine_id", ""))
		if not doctrine_id.is_empty():
			doctrine_ids[doctrine_id] = true
	var score_delta := 0
	var comparison_copy := "Career baseline established."
	if not previous.is_empty():
		score_delta = int(current.get("score", 0)) - int(previous.get("score", 0))
		comparison_copy = "%+d score versus the previous file." % score_delta
	var mastery := scenario_mastery()
	var mastery_stamp_count := 0
	for row in mastery:
		mastery_stamp_count += int(row.get("earned_count", 0))
	var mastery_stamp_total := mastery.size() * 3
	var current_scenario_id := String(current.get("scenario_id", ""))
	var current_mastery: Dictionary = {}
	for row in mastery:
		if String(row.get("scenario_id", "")) == current_scenario_id:
			current_mastery = row.duplicate(true)
			break
	var mastery_detail := "Clear a file, protect flock welfare, and earn an 80+ score to stamp every scenario card."
	if not current_mastery.is_empty():
		mastery_detail = String(current_mastery.get("next_stamp_detail", mastery_detail))
	return {
		"run_count": _entries.size(),
		"passed_count": passed_count,
		"best_score": best_score,
		"scenario_count": scenario_ids.size(),
		"doctrine_count": doctrine_ids.size(),
		"current": current.duplicate(true),
		"previous": previous.duplicate(true),
		"score_delta": score_delta,
		"headline": "RUN %d  /  BEST %d" % [_entries.size(), best_score],
		"detail": "%s %d scenario%s and %d doctrine%s are now in the archive." % [
			comparison_copy,
			scenario_ids.size(),
			"" if scenario_ids.size() == 1 else "s",
			doctrine_ids.size(),
			"" if doctrine_ids.size() == 1 else "s",
		],
		"scenario_mastery": mastery,
		"current_scenario_mastery": current_mastery,
		"mastery_stamp_count": mastery_stamp_count,
		"mastery_stamp_total": mastery_stamp_total,
		"mastery_headline": "MASTERY %d / %d" % [mastery_stamp_count, mastery_stamp_total],
		"mastery_detail": mastery_detail,
	}


## Three legible, derived goals per scenario. These stamps never alter economy
## authority and require no schema migration: the bounded run receipts remain
## the sole source of truth.
func scenario_mastery() -> Array[Dictionary]:
	var grouped: Dictionary[String, Array] = {}
	var labels: Dictionary[String, String] = {}
	for entry in _entries:
		var scenario_id := String(entry.get("scenario_id", "")).strip_edges()
		if scenario_id.is_empty():
			continue
		if not grouped.has(scenario_id):
			grouped[scenario_id] = []
		grouped[scenario_id].append(entry)
		labels[scenario_id] = String(entry.get("scenario_label", scenario_id.replace("_", " ")))
	var scenario_ids := grouped.keys()
	scenario_ids.sort()
	var result: Array[Dictionary] = []
	for scenario_id in scenario_ids:
		var cleared := false
		var flock_safe := false
		var gold_file := false
		var best_score := 0
		var best_welfare := 0
		for entry_value in grouped[scenario_id]:
			var entry := entry_value as Dictionary
			if not bool(entry.get("passed", false)):
				continue
			cleared = true
			best_score = maxi(best_score, int(entry.get("score", 0)))
			best_welfare = maxi(best_welfare, int(entry.get("welfare", 0)))
			flock_safe = flock_safe or int(entry.get("welfare", 0)) >= FLOCK_SAFE_WELFARE
			gold_file = gold_file or int(entry.get("score", 0)) >= GOLD_FILE_SCORE
		var earned_count := int(cleared) + int(flock_safe) + int(gold_file)
		var next_stamp_detail := "All three stamps earned. Try a different doctrine or challenge contract."
		if not cleared:
			next_stamp_detail = "Next stamp: clear this five-shift file."
		elif not flock_safe:
			next_stamp_detail = "Next stamp: pass with flock welfare at %d or higher." % FLOCK_SAFE_WELFARE
		elif not gold_file:
			next_stamp_detail = "Next stamp: pass with a score of %d or higher." % GOLD_FILE_SCORE
		result.append({
			"scenario_id": scenario_id,
			"scenario_label": labels.get(scenario_id, scenario_id.replace("_", " ")).to_upper(),
			"earned_count": earned_count,
			"total_count": 3,
			"complete": earned_count == 3,
			"best_score": best_score,
			"best_welfare": best_welfare,
			"compact": "%s  %s%s%s" % [
				labels.get(scenario_id, scenario_id.replace("_", " ")).to_upper(),
				"●" if cleared else "○",
				"●" if flock_safe else "○",
				"●" if gold_file else "○",
			],
			"next_stamp_detail": next_stamp_detail,
			"stamps": [
				{"id": "clear", "label": "CLEAR", "earned": cleared},
				{"id": "flock_safe", "label": "FLOCK SAFE", "earned": flock_safe},
				{"id": "gold_file", "label": "GOLD FILE", "earned": gold_file},
			],
		})
	return result


func _normalized_entry(entry: Dictionary) -> Dictionary:
	for field in ["run_id", "scenario_id", "scenario_label", "contract_id", "contract_label", "doctrine_id", "doctrine_label", "hearing_choice_id", "hearing_choice_label"]:
		if typeof(entry.get(field, "")) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {}
	for field in ["score", "welfare", "compliance", "farmer_favor", "crack_rate_basis_points", "mastered_pairs"]:
		if typeof(entry.get(field, 0)) != TYPE_INT:
			return {}
	if typeof(entry.get("passed", false)) != TYPE_BOOL:
		return {}
	var run_id := String(entry.get("run_id", "")).strip_edges()
	if run_id.is_empty() or run_id.length() > 120:
		return {}
	return {
		"version": VERSION,
		"run_id": run_id,
		"scenario_id": String(entry.get("scenario_id", "")).substr(0, 64),
		"scenario_label": String(entry.get("scenario_label", "BASELINE")).substr(0, 80),
		"contract_id": String(entry.get("contract_id", "")).substr(0, 64),
		"contract_label": String(entry.get("contract_label", "STANDARD")).substr(0, 80),
		"doctrine_id": String(entry.get("doctrine_id", "")).substr(0, 64),
		"doctrine_label": String(entry.get("doctrine_label", "UNFILED")).substr(0, 80),
		"hearing_choice_id": String(entry.get("hearing_choice_id", "")).substr(0, 64),
		"hearing_choice_label": String(entry.get("hearing_choice_label", "UNFILED")).substr(0, 96),
		"score": clampi(int(entry.get("score", 0)), 0, 100),
		"welfare": clampi(int(entry.get("welfare", 0)), 0, 100),
		"compliance": clampi(int(entry.get("compliance", 0)), 0, 100),
		"farmer_favor": clampi(int(entry.get("farmer_favor", 0)), 0, 100),
		"crack_rate_basis_points": clampi(int(entry.get("crack_rate_basis_points", 0)), 0, 10_000),
		"mastered_pairs": clampi(int(entry.get("mastered_pairs", 0)), 0, 64),
		"passed": bool(entry.get("passed", false)),
	}
