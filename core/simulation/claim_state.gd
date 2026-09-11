class_name ClaimState
extends RefCounted

## Authoritative, serializable-in-principle unit of peckwork.
##
## Claims deliberately remain lightweight data rather than Nodes. The
## DepartmentSimulation owns their queue position and ChickenState only holds a
## reference while a claim is actively being processed.

const CLAIMANT_PROFILES := {
	&"mossy_hollow": {
		"name": "MOSSY HOLLOW COOP",
		"incident": "Rain collapsed the east nesting wall before hatch night.",
		"need": "Dry nesting space and repair feed before tomorrow's clutch.",
		"delay_cost": "A slow file leaves twelve eggs and two broody hens exposed.",
	},
	&"thistle_patch": {
		"name": "THISTLE PATCH SMALLHOLDING",
		"incident": "A feed-bin hinge failed and vermin spoiled the winter grain.",
		"need": "Replacement grain and a covered bin before the next cold front.",
		"delay_cost": "Delay means rationing feed across a mixed-age flock.",
	},
	&"juniper_flock": {
		"name": "JUNIPER RIDGE FLOCK",
		"incident": "A fox breach scattered the pullets and damaged the night run.",
		"need": "Emergency fencing and recovery care for the surviving birds.",
		"delay_cost": "Every night without settlement keeps the flock in a cramped shed.",
	},
	&"reed_bank": {
		"name": "REED BANK DUCK & HEN",
		"incident": "A hawk strike closed the shared pasture and injured a layer.",
		"need": "Veterinary feed and overhead netting before the pasture reopens.",
		"delay_cost": "A slow decision extends confinement and lost laying days.",
	},
	&"clover_appeal": {
		"name": "CLOVER FIELD COOPERATIVE",
		"incident": "Farm Mutual denied storm damage as ordinary nest wear.",
		"need": "An exception review using the photographs omitted from intake.",
		"delay_cost": "Without review, member hens absorb the repair bill from feed money.",
	},
	&"old_red_barn": {
		"name": "OLD RED BARN MUTUAL AID",
		"incident": "A predator-loss payment excluded three fostered hens.",
		"need": "A humane coverage exception before the temporary coop closes.",
		"delay_cost": "Delay separates the fostered birds from their established flock.",
	},
}
const CLAIMANT_PROFILE_IDS_BY_LANE := {
	&"nest_damage": [&"mossy_hollow", &"thistle_patch"],
	&"predator_loss": [&"juniper_flock", &"reed_bank"],
	&"appeals": [&"clover_appeal", &"old_red_barn"],
}
const RESOLUTION_PATH_IDS: Array[StringName] = [
	&"standard",
	&"settle",
	&"deny",
	&"exception",
]
const RESOLUTION_COST_CENTS := {
	&"standard": 0,
	&"settle": 120,
	&"deny": 0,
	&"exception": 60,
}

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
var claimant_profile_id: StringName = &""
var resolution_path: StringName = &"standard"
var resolution_locked: bool = false
var resolution_cost_cents: int = 0
var is_claimant_follow_up: bool = false


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
	claim_rework_depth: int = 0,
	claimant_id: StringName = &"",
	claim_resolution_path: StringName = &"standard",
	claim_resolution_locked: bool = false,
	_claim_resolution_cost_cents: int = 0,
	claimant_follow_up: bool = false
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
	claimant_profile_id = (
		claimant_id
		if CLAIMANT_PROFILES.has(claimant_id) else
		default_claimant_profile(claim_lane, claim_id)
	)
	resolution_path = (
		claim_resolution_path
		if claim_resolution_path in RESOLUTION_PATH_IDS else
		&"standard"
	)
	resolution_locked = claim_resolution_locked and resolution_path != &"standard"
	resolution_cost_cents = (
		int(RESOLUTION_COST_CENTS.get(resolution_path, 0))
		if resolution_locked else
		0
	)
	is_claimant_follow_up = claimant_follow_up


static func default_claimant_profile(
	claim_lane: StringName,
	claim_id: int,
) -> StringName:
	var profiles := CLAIMANT_PROFILE_IDS_BY_LANE.get(
		claim_lane,
		CLAIMANT_PROFILE_IDS_BY_LANE[&"appeals"],
	) as Array
	return StringName(profiles[posmod(claim_id - 1, profiles.size())])


func claimant_profile() -> Dictionary:
	return (
		CLAIMANT_PROFILES.get(claimant_profile_id, {}) as Dictionary
	).duplicate(true)


func minutes_until_deadline(current_operational_minute: int) -> int:
	return deadline_operational_minute - current_operational_minute


func is_overdue(current_operational_minute: int) -> bool:
	return minutes_until_deadline(current_operational_minute) < 0


func snapshot(current_operational_minute: int) -> Dictionary:
	var remaining := minutes_until_deadline(current_operational_minute)
	var claimant := claimant_profile()
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
		"claimant_profile_id": claimant_profile_id,
		"claimant_name": String(claimant.get("name", "UNFILED CLAIMANT")),
		"claimant_incident": String(claimant.get("incident", "")),
		"claimant_need": String(claimant.get("need", "")),
		"claimant_delay_cost": String(claimant.get("delay_cost", "")),
		"resolution_path": resolution_path,
		"resolution_locked": resolution_locked,
		"resolution_cost_cents": resolution_cost_cents,
		"is_claimant_follow_up": is_claimant_follow_up,
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
		"claimant_profile_id": String(claimant_profile_id),
		"resolution_path": String(resolution_path),
		"resolution_locked": resolution_locked,
		"resolution_cost_cents": resolution_cost_cents,
		"is_claimant_follow_up": is_claimant_follow_up,
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
		clampi(int(data.get("rework_depth", 0)), 0, 100),
		StringName(String(data.get("claimant_profile_id", ""))),
		StringName(String(data.get("resolution_path", "standard"))),
		bool(data.get("resolution_locked", false)),
		clampi(int(data.get("resolution_cost_cents", 0)), 0, 100_000),
		bool(data.get("is_claimant_follow_up", false))
	)
