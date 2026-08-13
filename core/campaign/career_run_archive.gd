class_name CareerRunArchive
extends RefCounted

## Small, bounded history of completed probation files. This is player-owned
## career context, not simulation authority: it compares runs without changing
## money, workers, scores, or unlocks.

const VERSION := 1
const MAX_ENTRIES := 8

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
	}


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
