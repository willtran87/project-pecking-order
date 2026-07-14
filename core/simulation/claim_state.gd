class_name ClaimState
extends RefCounted

## Authoritative, serializable-in-principle unit of peckwork.
##
## Claims deliberately remain lightweight data rather than Nodes. The
## DepartmentSimulation owns their queue position and ChickenState only holds a
## reference while a claim is actively being processed.

var id: int
var lane: StringName
var display_name: String
var difficulty: float
var value_cents: int
var base_crack_risk: float
var arrived_operational_minute: int
var deadline_operational_minute: int
var service_window_minutes: int
var is_rework: bool = false
var source_claim_id: int = -1
var available_day: int = 1
var rework_depth: int = 0


func _init(
	claim_id: int,
	claim_lane: StringName,
	claim_display_name: String,
	claim_difficulty: float,
	claim_value_cents: int,
	claim_base_crack_risk: float,
	arrival_minute: int,
	deadline_minute: int,
	window_minutes: int,
	rework: bool = false,
	source_id: int = -1,
	claim_available_day: int = 1,
	claim_rework_depth: int = 0
) -> void:
	id = claim_id
	lane = claim_lane
	display_name = claim_display_name
	difficulty = maxf(0.1, claim_difficulty)
	value_cents = maxi(0, claim_value_cents)
	base_crack_risk = claim_base_crack_risk
	arrived_operational_minute = arrival_minute
	deadline_operational_minute = deadline_minute
	service_window_minutes = maxi(1, window_minutes)
	is_rework = rework
	source_claim_id = source_id
	available_day = maxi(1, claim_available_day)
	rework_depth = maxi(0, claim_rework_depth)


func minutes_until_deadline(current_operational_minute: int) -> int:
	return deadline_operational_minute - current_operational_minute


func is_overdue(current_operational_minute: int) -> bool:
	return minutes_until_deadline(current_operational_minute) < 0


func snapshot(current_operational_minute: int) -> Dictionary:
	var remaining := minutes_until_deadline(current_operational_minute)
	return {
		"id": id,
		"lane": lane,
		"display_name": display_name,
		"difficulty": difficulty,
		"value_cents": value_cents,
		"base_crack_risk": base_crack_risk,
		"arrived_operational_minute": arrived_operational_minute,
		"deadline_operational_minute": deadline_operational_minute,
		"service_window_minutes": service_window_minutes,
		"minutes_until_deadline": remaining,
		"overdue": remaining < 0,
		"is_rework": is_rework,
		"source_claim_id": source_claim_id,
		"available_day": available_day,
		"rework_depth": rework_depth,
	}


func to_save_data() -> Dictionary:
	## Save only primitives and stable identifiers. Derived deadline labels are
	## rebuilt by `snapshot()` after load.
	return {
		"id": id,
		"lane": String(lane),
		"display_name": display_name,
		"difficulty": difficulty,
		"value_cents": value_cents,
		"base_crack_risk": base_crack_risk,
		"arrived_operational_minute": arrived_operational_minute,
		"deadline_operational_minute": deadline_operational_minute,
		"service_window_minutes": service_window_minutes,
		"is_rework": is_rework,
		"source_claim_id": source_claim_id,
		"available_day": available_day,
		"rework_depth": rework_depth,
	}


static func from_save_data(data: Dictionary) -> ClaimState:
	var claim_id := int(data.get("id", -1))
	var claim_lane := StringName(String(data.get("lane", "")))
	if claim_id < 0 or claim_lane == &"":
		return null
	return ClaimState.new(
		claim_id,
		claim_lane,
		String(data.get("display_name", "PECKWORK")),
		clampf(float(data.get("difficulty", 1.0)), 0.1, 8.0),
		clampi(int(data.get("value_cents", 0)), 0, 1000000),
		clampf(float(data.get("base_crack_risk", 0.0)), -0.25, 0.75),
		maxi(0, int(data.get("arrived_operational_minute", 0))),
		maxi(0, int(data.get("deadline_operational_minute", 1))),
		clampi(int(data.get("service_window_minutes", 1)), 1, 10000),
		bool(data.get("is_rework", false)),
		int(data.get("source_claim_id", -1)),
		maxi(1, int(data.get("available_day", 1))),
		clampi(int(data.get("rework_depth", 0)), 0, 100)
	)
