class_name CampaignShiftRecord
extends RefCounted

## Normalized, immutable-in-practice result for one probation shift. Every
## persisted measurement is an integer; percentages are 0..100 and rates use
## basis points (10,000 == 100%).

var shift_number: int = 0
var eggs: int = 0
var quota: int = 1
var met_quota: bool = false
var cracked_eggs: int = 0
var crack_rate_basis_points: int = 0
var overdue_files: int = 0
var rework: int = 0
var credited_cents: int = 0
var welfare: int = 0
var compliance: int = 0
var farmer_favor: int = 0
var objective_results: Array[Dictionary] = []
var score_delta: int = 0
var score_after: int = 0
var rank_after: StringName = &"probationary"


func metrics_dictionary() -> Dictionary:
	return {
		"eggs": eggs,
		"quota": quota,
		"quota_met": 1 if met_quota else 0,
		"cracked_eggs": cracked_eggs,
		"crack_rate_basis_points": crack_rate_basis_points,
		"overdue_files": overdue_files,
		"rework": rework,
		"credited_cents": credited_cents,
		"welfare": welfare,
		"compliance": compliance,
		"farmer_favor": farmer_favor,
	}


func to_dictionary() -> Dictionary:
	return {
		"shift_number": shift_number,
		"eggs": eggs,
		"quota": quota,
		"met_quota": met_quota,
		"cracked_eggs": cracked_eggs,
		"crack_rate_basis_points": crack_rate_basis_points,
		"overdue_files": overdue_files,
		"rework": rework,
		"credited_cents": credited_cents,
		"welfare": welfare,
		"compliance": compliance,
		"farmer_favor": farmer_favor,
		"objective_results": objective_results.duplicate(true),
		"score_delta": score_delta,
		"score_after": score_after,
		"rank_after": String(rank_after),
	}


static func from_dictionary(data: Dictionary) -> CampaignShiftRecord:
	var record := CampaignShiftRecord.new()
	record.shift_number = int(data.get("shift_number", 0))
	record.eggs = int(data.get("eggs", 0))
	record.quota = int(data.get("quota", 1))
	record.met_quota = bool(data.get("met_quota", false))
	record.cracked_eggs = int(data.get("cracked_eggs", 0))
	record.crack_rate_basis_points = int(data.get("crack_rate_basis_points", 0))
	record.overdue_files = int(data.get("overdue_files", 0))
	record.rework = int(data.get("rework", 0))
	record.credited_cents = int(data.get("credited_cents", 0))
	record.welfare = int(data.get("welfare", 0))
	record.compliance = int(data.get("compliance", 0))
	record.farmer_favor = int(data.get("farmer_favor", 0))
	for result_value in data.get("objective_results", []):
		var result := result_value as Dictionary
		record.objective_results.append({
			"id": String(result.get("id", "")),
			"completed": bool(result.get("completed", false)),
			"score_awarded": int(result.get("score_awarded", 0)),
		})
	record.score_delta = int(data.get("score_delta", 0))
	record.score_after = int(data.get("score_after", 0))
	record.rank_after = StringName(data.get("rank_after", "probationary"))
	return record
