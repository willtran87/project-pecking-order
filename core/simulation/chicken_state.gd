class_name ChickenState
extends RefCounted

enum WorkState {
	IDLE,
	WORKING,
	LAYING,
	BREAK,
}

const CAREER_PROFILES: Array[StringName] = [
	&"credit_conscious",
	&"advancement_minded",
	&"quota_conditioned",
]
const PERSONNEL_ACTION_IDS: Array[StringName] = [
	&"share_credit",
	&"career_coaching",
	&"quota_pressure",
]
const CAREER_THRESHOLDS: Array[int] = [0, 18, 45, 80]
const CAREER_TITLES: Array[String] = [
	"JUNIOR CLAIMS HEN",
	"ACCREDITED LAYER",
	"SENIOR CLAIMS HEN",
	"PRINCIPAL SHELL ADJUSTER",
]
const MAX_CAREER_XP := 999_999
const EMPLOYMENT_STATUS_EMPLOYED: StringName = &"employed"
const EMPLOYMENT_STATUS_APPLICANT: StringName = &"applicant"
const BASE_DAILY_WAGE_CENTS := 400
const CAREER_LEVEL_WAGE_CENTS := 100
const CROSS_TRAINING_WAGE_BONUS_CENTS := 100
const CROSS_TRAINING_WORK_MULTIPLIER := 0.85
const BASE_HIRE_COST_CENTS := 1200
const WORKER_ID_HIRE_COST_CENTS := 100
const CAREER_LEVEL_HIRE_COST_CENTS := 400
const BASE_RELEASE_COST_CENTS := 1000
const CAREER_LEVEL_RELEASE_COST_CENTS := 400
const HIRE_COUNT_RELEASE_COST_CENTS := 100

var id: int
var display_name: String
var desk_index: int
var skill: float
var accuracy: float
var specialty: StringName
var secondary_specialty: StringName = &""
var cross_training_target: StringName = &""
var cross_training_worked_this_shift: bool = false
var assigned_lane: StringName = &"auto"
var current_claim: ClaimState
var morale: float = 74.0
var fatigue: float = 8.0
var stress: float = 12.0
var work_state: WorkState = WorkState.IDLE
var work_progress: float = 0.0
var state_ticks_remaining: int = 0
var eggs_laid: int = 0
var career_profile: StringName
var manager_trust: float = 58.0
var grievance: float = 6.0
var career_xp: int = 0
var last_personnel_action: StringName = &""
var last_personnel_action_day: int = 0
var last_personnel_action_serial: int = 0
var employed: bool = true
var available_for_hire_day: int = 0
var hire_count: int = 0
var employment_start_day: int = 1


func _init(
	worker_id: int,
	worker_name: String,
	assigned_desk: int,
	worker_skill: float,
	worker_accuracy: float,
	worker_specialty: StringName = &"nest_damage"
) -> void:
	id = worker_id
	display_name = worker_name
	desk_index = assigned_desk
	skill = worker_skill
	accuracy = worker_accuracy
	specialty = worker_specialty
	career_profile = default_career_profile(worker_id)


static func default_career_profile(worker_id: int) -> StringName:
	return CAREER_PROFILES[posmod(worker_id, CAREER_PROFILES.size())]


static func is_valid_career_profile(profile_id: StringName) -> bool:
	return profile_id in CAREER_PROFILES


static func is_valid_personnel_action(action_id: StringName) -> bool:
	return action_id == &"" or action_id in PERSONNEL_ACTION_IDS


func career_level() -> int:
	var level := 0
	for index in CAREER_THRESHOLDS.size():
		if career_xp < CAREER_THRESHOLDS[index]:
			break
		level = index
	return level


func career_title() -> String:
	return CAREER_TITLES[career_level()]


func career_next_threshold() -> int:
	var next_level := career_level() + 1
	if next_level >= CAREER_THRESHOLDS.size():
		return -1
	return CAREER_THRESHOLDS[next_level]


func career_progress() -> float:
	var level := career_level()
	if level >= CAREER_THRESHOLDS.size() - 1:
		return 1.0
	var current_threshold := CAREER_THRESHOLDS[level]
	var next_threshold := CAREER_THRESHOLDS[level + 1]
	return clampf(
		float(career_xp - current_threshold) / float(next_threshold - current_threshold),
		0.0,
		1.0
	)


func add_career_xp(amount: int) -> bool:
	var previous_level := career_level()
	career_xp = clampi(career_xp + maxi(0, amount), 0, MAX_CAREER_XP)
	return career_level() > previous_level


func relationship_label() -> String:
	if grievance >= 70.0 or manager_trust <= 25.0:
		return "OPEN GRIEVANCE"
	if grievance >= 45.0 or manager_trust <= 40.0:
		return "STRAINED"
	if manager_trust >= 75.0 and grievance <= 20.0:
		return "TRUSTED"
	if manager_trust >= 60.0 and grievance <= 35.0:
		return "COOPERATIVE"
	return "WARY"


func employment_status() -> StringName:
	return EMPLOYMENT_STATUS_EMPLOYED if employed else EMPLOYMENT_STATUS_APPLICANT


func has_specialty(lane: StringName) -> bool:
	return lane == specialty or (secondary_specialty != &"" and lane == secondary_specialty)


func has_secondary_specialty() -> bool:
	return secondary_specialty != &""


func cross_training_pending() -> bool:
	return cross_training_target != &""


func cross_training_work_multiplier() -> float:
	return CROSS_TRAINING_WORK_MULTIPLIER if cross_training_pending() else 1.0


func cross_training_wage_bonus_cents() -> int:
	return CROSS_TRAINING_WAGE_BONUS_CENTS if has_secondary_specialty() else 0


func begin_cross_training(target_lane: StringName) -> bool:
	if (
		target_lane == &""
		or target_lane == specialty
		or career_level() < 1
		or has_secondary_specialty()
		or cross_training_pending()
	):
		return false
	cross_training_target = target_lane
	cross_training_worked_this_shift = false
	return true


func complete_cross_training() -> StringName:
	if not cross_training_pending() or has_secondary_specialty():
		return &""
	secondary_specialty = cross_training_target
	cross_training_target = &""
	cross_training_worked_this_shift = false
	return secondary_specialty


func daily_wage_cents() -> int:
	return (
		BASE_DAILY_WAGE_CENTS
		+ career_level() * CAREER_LEVEL_WAGE_CENTS
		+ cross_training_wage_bonus_cents()
	)


func hire_cost_cents() -> int:
	return (
		BASE_HIRE_COST_CENTS
		+ id * WORKER_ID_HIRE_COST_CENTS
		+ career_level() * CAREER_LEVEL_HIRE_COST_CENTS
	)


func release_cost_cents() -> int:
	return (
		BASE_RELEASE_COST_CENTS
		+ career_level() * CAREER_LEVEL_RELEASE_COST_CENTS
		+ hire_count * HIRE_COUNT_RELEASE_COST_CENTS
	)


func state_label() -> String:
	match work_state:
		WorkState.WORKING:
			return "PECKING"
		WorkState.LAYING:
			return "LAYING"
		WorkState.BREAK:
			return "WELLNESS"
		_:
			return "AVAILABLE"


func snapshot(current_operational_minute: int = 0) -> Dictionary:
	return {
		"id": id,
		"name": display_name,
		"desk_index": desk_index,
		"skill": skill,
		"accuracy": accuracy,
		"specialty": specialty,
		"secondary_specialty": secondary_specialty,
		"has_secondary_specialty": has_secondary_specialty(),
		"cross_training_target": cross_training_target,
		"cross_training_pending": cross_training_pending(),
		"cross_training_worked_this_shift": cross_training_worked_this_shift,
		"cross_training_work_multiplier": cross_training_work_multiplier(),
		"cross_training_wage_bonus_cents": cross_training_wage_bonus_cents(),
		"assigned_lane": assigned_lane,
		"current_claim": (
			current_claim.snapshot(current_operational_minute)
			if current_claim != null else {}
		),
		"morale": morale,
		"fatigue": fatigue,
		"stress": stress,
		"state": work_state,
		"state_label": state_label(),
		"progress": work_progress,
		"eggs_laid": eggs_laid,
		"career_profile": career_profile,
		"manager_trust": manager_trust,
		"grievance": grievance,
		"career_xp": career_xp,
		"career_level": career_level(),
		"career_title": career_title(),
		"career_next_threshold": career_next_threshold(),
		"career_xp_next": career_next_threshold(),
		"career_progress": career_progress(),
		"relationship_label": relationship_label(),
		"last_personnel_action": last_personnel_action,
		"last_personnel_action_day": last_personnel_action_day,
		"last_personnel_action_serial": last_personnel_action_serial,
		"employed": employed,
		"employment_status": employment_status(),
		"available_for_hire_day": available_for_hire_day,
		"hire_count": hire_count,
		"employment_start_day": employment_start_day,
		"daily_wage_cents": daily_wage_cents(),
		"hire_cost_cents": hire_cost_cents(),
		"release_cost_cents": release_cost_cents(),
	}


func to_save_data() -> Dictionary:
	return {
		"id": id,
		"name": display_name,
		"desk_index": desk_index,
		"skill": skill,
		"accuracy": accuracy,
		"specialty": String(specialty),
		"secondary_specialty": String(secondary_specialty),
		"cross_training_target": String(cross_training_target),
		"cross_training_worked_this_shift": cross_training_worked_this_shift,
		"assigned_lane": String(assigned_lane),
		"current_claim": current_claim.to_save_data() if current_claim != null else {},
		"morale": morale,
		"fatigue": fatigue,
		"stress": stress,
		"state": work_state,
		"progress": work_progress,
		"state_ticks_remaining": state_ticks_remaining,
		"eggs_laid": eggs_laid,
		"career_profile": String(career_profile),
		"manager_trust": manager_trust,
		"grievance": grievance,
		"career_xp": career_xp,
		"last_personnel_action": String(last_personnel_action),
		"last_personnel_action_day": last_personnel_action_day,
		"last_personnel_action_serial": last_personnel_action_serial,
		"employed": employed,
		"employment_status": String(employment_status()),
		"available_for_hire_day": available_for_hire_day,
		"hire_count": hire_count,
		"employment_start_day": employment_start_day,
	}


func apply_save_data(data: Dictionary) -> bool:
	if int(data.get("id", -1)) != id:
		return false
	display_name = String(data.get("name", display_name)).substr(0, 48)
	desk_index = clampi(int(data.get("desk_index", desk_index)), -1, 64)
	skill = clampf(float(data.get("skill", skill)), 0.25, 3.0)
	accuracy = clampf(float(data.get("accuracy", accuracy)), 0.25, 0.999)
	specialty = StringName(String(data.get("specialty", specialty)))
	assigned_lane = StringName(String(data.get("assigned_lane", assigned_lane)))
	morale = clampf(float(data.get("morale", morale)), 0.0, 100.0)
	fatigue = clampf(float(data.get("fatigue", fatigue)), 0.0, 100.0)
	stress = clampf(float(data.get("stress", stress)), 0.0, 100.0)
	work_state = clampi(
		int(data.get("state", WorkState.IDLE)),
		WorkState.IDLE,
		WorkState.BREAK
	)
	work_progress = clampf(float(data.get("progress", 0.0)), 0.0, 100.0)
	state_ticks_remaining = clampi(int(data.get("state_ticks_remaining", 0)), 0, 10000)
	eggs_laid = maxi(0, int(data.get("eggs_laid", 0)))
	var saved_profile := StringName(String(data.get(
		"career_profile",
		default_career_profile(id)
	)))
	career_profile = (
		saved_profile
		if is_valid_career_profile(saved_profile)
		else default_career_profile(id)
	)
	manager_trust = clampf(float(data.get("manager_trust", 58.0)), 0.0, 100.0)
	grievance = clampf(float(data.get("grievance", 6.0)), 0.0, 100.0)
	career_xp = clampi(int(data.get("career_xp", 0)), 0, MAX_CAREER_XP)
	secondary_specialty = StringName(String(data.get("secondary_specialty", "")))
	cross_training_target = StringName(String(data.get("cross_training_target", "")))
	var saved_training_worked: Variant = data.get("cross_training_worked_this_shift", false)
	if typeof(saved_training_worked) != TYPE_BOOL:
		return false
	cross_training_worked_this_shift = bool(saved_training_worked)
	if (
		(secondary_specialty != &"" and secondary_specialty == specialty)
		or (cross_training_target != &"" and cross_training_target == specialty)
		or (secondary_specialty != &"" and cross_training_target != &"")
		or ((secondary_specialty != &"" or cross_training_target != &"") and career_level() < 1)
		or (cross_training_target == &"" and cross_training_worked_this_shift)
	):
		return false
	var saved_action := StringName(String(data.get("last_personnel_action", "")))
	last_personnel_action = saved_action if is_valid_personnel_action(saved_action) else &""
	last_personnel_action_day = clampi(
		int(data.get("last_personnel_action_day", 0)),
		0,
		9999
	)
	last_personnel_action_serial = clampi(
		int(data.get("last_personnel_action_serial", 0)),
		0,
		2_000_000_000
	)
	if last_personnel_action == &"":
		last_personnel_action_day = 0
		last_personnel_action_serial = 0
	var saved_employed: Variant = data.get("employed", true)
	if typeof(saved_employed) != TYPE_BOOL:
		return false
	employed = bool(saved_employed)
	var saved_employment_status := StringName(String(data.get(
		"employment_status",
		String(EMPLOYMENT_STATUS_EMPLOYED if employed else EMPLOYMENT_STATUS_APPLICANT)
	)))
	if saved_employment_status != employment_status():
		return false
	available_for_hire_day = clampi(
		int(data.get("available_for_hire_day", 0)),
		0,
		10000
	)
	hire_count = clampi(int(data.get("hire_count", 0)), 0, 9999)
	employment_start_day = clampi(
		int(data.get("employment_start_day", 1 if employed else 0)),
		0,
		9999
	)
	var claim_data := data.get("current_claim", {}) as Dictionary
	current_claim = ClaimState.from_save_data(claim_data) if not claim_data.is_empty() else null
	return true
