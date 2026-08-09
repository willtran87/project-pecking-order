class_name InternshipProgramState
extends RefCounted

## Persistent authority for the Cornfields Mutual internship program.
##
## Interns are deliberately not regular workers: they do not own claims, lay
## eggs, consume a full perch, or disappear into ChickenState. Their disclosed
## office effects come from temporary rotations, and every term ending requires
## a player-facing review. This keeps the satire legible and prevents "free
## labor" from silently becoming an undocumented seventh production hen.

const SAVE_VERSION := 1
const UNLOCK_DAY := 2
const BASE_SEAT_LIMIT := 1
const MAX_SEAT_LIMIT := 2
const TERM_SHIFTS := 3
const EXTENSION_SHIFTS := 2
const ONBOARDING_COST_CENTS := 300
const EXTENSION_COST_CENTS := 100
const FELLOWSHIP_COST_CENTS := 800
const FELLOWSHIP_DAILY_PAYROLL_CENTS := 200

const CANDIDATE_ORDER: Array[StringName] = [
	&"lottie_ledger",
	&"chip_chirper",
	&"marigold_memo",
	&"tilly_tabs",
]

const CANDIDATES := {
	&"lottie_ledger": {
		"name": "Lottie Ledger",
		"role": "APPEALS INTERN  /  EAGER VERIFIER",
		"portrait_id": &"intern_lottie",
		"personality_title": "THE GOLD-STAR CHECKER",
		"personality": "Precise, earnest, and delighted by any task described as trusted.",
		"hope": "Believes flawless work will turn an internship into a real perch.",
		"blind_spot": "Reads additional responsibility as recognition, even when compensation never changes.",
	},
	&"chip_chirper": {
		"name": "Chip Chirper",
		"role": "OPERATIONS INTERN  /  SOCIAL OPTIMIST",
		"portrait_id": &"intern_chip",
		"personality_title": "THE VISIBILITY SEEKER",
		"personality": "Friendly, energetic, and certain every meeting is a chance to be remembered.",
		"hope": "Believes proximity to leadership is the same thing as sponsorship.",
		"blind_spot": "Treats unpaid coordination and after-hours networking as access.",
	},
	&"marigold_memo": {
		"name": "Marigold Memo",
		"role": "CLAIMANT CARE INTERN  /  PURPOSE HELPER",
		"portrait_id": &"intern_marigold",
		"personality_title": "THE MISSION BELIEVER",
		"personality": "Warm, capable, and genuinely proud to help wherever the flock is short.",
		"hope": "Believes doing two vacant jobs proves she belongs in one of them.",
		"blind_spot": "Calls chronic understaffing a cross-functional learning opportunity.",
	},
	&"tilly_tabs": {
		"name": "Tilly Tabs",
		"role": "SYSTEMS INTERN  /  FAST LEARNER",
		"portrait_id": &"intern_tilly",
		"personality_title": "THE DASHBOARD NATIVE",
		"personality": "Tech-curious, cheerful, and thrilled whenever the system notices her.",
		"hope": "Believes measurement means somebody is invested in her growth.",
		"blind_spot": "Mistakes minute-by-minute surveillance for attentive mentorship.",
	},
}

const ASSIGNMENT_ORDER: Array[StringName] = [
	&"guided_shadow",
	&"stretch_project",
	&"culture_sprint",
]

const ASSIGNMENTS := {
	&"guided_shadow": {
		"label": "GUIDED FILE SHADOW",
		"promise": "Learn the full file lifecycle beside the flock.",
		"disclosure": "+1 live-file capacity; +1% flock work. No shell-risk change.",
		"capacity_bonus": 1,
		"work_basis_points": 100,
		"crack_basis_points": 0,
		"morale_drain_basis_points": 10_000,
	},
	&"stretch_project": {
		"label": "HIGH-VISIBILITY STRETCH PROJECT",
		"promise": "Own a leadership-priority deliverable beyond the job description.",
		"disclosure": "+2 live-file capacity; +4% flock work; +1% shell risk.",
		"capacity_bonus": 2,
		"work_basis_points": 400,
		"crack_basis_points": 100,
		"morale_drain_basis_points": 10_000,
	},
	&"culture_sprint": {
		"label": "CULTURE & BELONGING SPRINT",
		"promise": "Improve morale through an intern-led enthusiasm initiative.",
		"disclosure": "No capacity gain; worker morale drains 10% more slowly.",
		"capacity_bonus": 0,
		"work_basis_points": 0,
		"crack_basis_points": 0,
		"morale_drain_basis_points": 9_000,
	},
}

const REVIEW_ORDER: Array[StringName] = [
	&"growth_extension",
	&"recommendation_letter",
	&"paid_fellowship",
]

const REVIEWS := {
	&"growth_extension": {
		"label": "FILE A GROWTH EXTENSION",
		"promise": "Keep the intern close to the opportunity for two more shifts.",
		"disclosure": "Costs $1.00 in meal-card credit; paid employment is deferred again.",
		"cost_cents": EXTENSION_COST_CENTS,
	},
	&"recommendation_letter": {
		"label": "ISSUE A GLOWING RECOMMENDATION",
		"promise": "Certify the experience and return the intern to the applicant market.",
		"disclosure": "The intern leaves; coop compliance +1.",
		"cost_cents": 0,
	},
	&"paid_fellowship": {
		"label": "OFFER A PAID FELLOWSHIP",
		"promise": "Convert the temporary rotation into one continuing junior post.",
		"disclosure": "Costs $8.00 to file and adds $2.00/day in junior payroll; one permanent fellow adds +1 capacity and +1% flock work.",
		"cost_cents": FELLOWSHIP_COST_CENTS,
		"daily_payroll_delta_cents": FELLOWSHIP_DAILY_PAYROLL_CENTS,
	},
}

var _records: Dictionary[StringName, Dictionary] = {}
var _last_action: Dictionary = {}
var _history: Array[Dictionary] = []


func _init() -> void:
	_reset_records()


func _reset_records() -> void:
	_records.clear()
	for candidate_id in CANDIDATE_ORDER:
		_records[candidate_id] = {
			"candidate_id": candidate_id,
			"status": &"candidate",
			"assignment_id": &"guided_shadow",
			"start_day": 0,
			"shifts_completed": 0,
			"term_shifts": TERM_SHIFTS,
			"extensions": 0,
			"completed_day": 0,
		}


func active_count() -> int:
	var count := 0
	for record in _records.values():
		if StringName((record as Dictionary).get("status", &"")) == &"active":
			count += 1
	return count


func fellow_count() -> int:
	var count := 0
	for record in _records.values():
		if StringName((record as Dictionary).get("status", &"")) == &"fellow":
			count += 1
	return count


func daily_fellow_payroll_cents() -> int:
	return fellow_count() * FELLOWSHIP_DAILY_PAYROLL_CENTS


func claim_capacity_bonus() -> int:
	var bonus := fellow_count()
	for record in _records.values():
		var row := record as Dictionary
		if StringName(row.get("status", &"")) != &"active":
			continue
		var definition := ASSIGNMENTS.get(
			StringName(row.get("assignment_id", &"guided_shadow")),
			{},
		) as Dictionary
		bonus += int(definition.get("capacity_bonus", 0))
	return bonus


func work_multiplier() -> float:
	var basis_points := fellow_count() * 100
	for record in _records.values():
		var row := record as Dictionary
		if StringName(row.get("status", &"")) != &"active":
			continue
		var definition := ASSIGNMENTS.get(
			StringName(row.get("assignment_id", &"guided_shadow")),
			{},
		) as Dictionary
		basis_points += int(definition.get("work_basis_points", 0))
	return 1.0 + float(basis_points) / 10_000.0


func crack_modifier() -> float:
	var basis_points := 0
	for record in _records.values():
		var row := record as Dictionary
		if StringName(row.get("status", &"")) != &"active":
			continue
		var definition := ASSIGNMENTS.get(
			StringName(row.get("assignment_id", &"guided_shadow")),
			{},
		) as Dictionary
		basis_points += int(definition.get("crack_basis_points", 0))
	return float(basis_points) / 10_000.0


func morale_drain_multiplier() -> float:
	var basis_points := 10_000
	for record in _records.values():
		var row := record as Dictionary
		if StringName(row.get("status", &"")) != &"active":
			continue
		var definition := ASSIGNMENTS.get(
			StringName(row.get("assignment_id", &"guided_shadow")),
			{},
		) as Dictionary
		basis_points = mini(
			basis_points,
			int(definition.get("morale_drain_basis_points", 10_000)),
		)
	return float(basis_points) / 10_000.0


func onboard(
	candidate_id: StringName,
	day: int,
	fund_cents: int,
	planning_open: bool,
	seat_limit: int,
) -> Dictionary:
	var reason := _onboard_reason(candidate_id, day, fund_cents, planning_open, seat_limit)
	if not reason.is_empty():
		return {
			"accepted": false,
			"action_id": &"intern_onboard",
			"candidate_id": candidate_id,
			"reason": reason,
		}
	var record := _records[candidate_id]
	record["status"] = &"active"
	record["assignment_id"] = &"guided_shadow"
	record["start_day"] = day
	record["shifts_completed"] = 0
	record["term_shifts"] = TERM_SHIFTS
	record["completed_day"] = 0
	var result := _file_action({
		"accepted": true,
		"action_id": &"intern_onboard",
		"candidate_id": candidate_id,
		"intern_name": _candidate_name(candidate_id),
		"day": day,
		"cost_cents": ONBOARDING_COST_CENTS,
		"assignment_id": &"guided_shadow",
		"outcome": "%s joined the Bright-Eyed Rotation for three shifts of credentialed experience."
			% _candidate_name(candidate_id),
	})
	return result


func assign(
	candidate_id: StringName,
	assignment_id: StringName,
	day: int,
	planning_open: bool,
) -> Dictionary:
	if not _records.has(candidate_id):
		return _rejection(&"intern_assignment", candidate_id, "That intern is not in the screened cohort.")
	if not ASSIGNMENTS.has(assignment_id):
		return _rejection(&"intern_assignment", candidate_id, "That developmental assignment is not filed.")
	if not planning_open:
		return _rejection(&"intern_assignment", candidate_id, "Intern assignments can only change during planning or review.")
	var record := _records[candidate_id]
	if StringName(record.get("status", &"")) != &"active":
		return _rejection(&"intern_assignment", candidate_id, "Only an active intern can receive a stretch assignment.")
	record["assignment_id"] = assignment_id
	var definition := ASSIGNMENTS[assignment_id] as Dictionary
	return _file_action({
		"accepted": true,
		"action_id": &"intern_assignment",
		"candidate_id": candidate_id,
		"intern_name": _candidate_name(candidate_id),
		"assignment_id": assignment_id,
		"day": day,
		"cost_cents": 0,
		"outcome": "%s received the %s learning opportunity."
			% [_candidate_name(candidate_id), String(definition.get("label", "ROTATION"))],
	})


func resolve_review(
	candidate_id: StringName,
	resolution_id: StringName,
	day: int,
	fund_cents: int,
	planning_open: bool,
) -> Dictionary:
	if not _records.has(candidate_id):
		return _rejection(&"intern_review", candidate_id, "That intern is not in the screened cohort.")
	if not REVIEWS.has(resolution_id):
		return _rejection(&"intern_review", candidate_id, "That term disposition is not filed.")
	if not planning_open:
		return _rejection(&"intern_review", candidate_id, "Term reviews can only be filed during planning or review.")
	var record := _records[candidate_id]
	if StringName(record.get("status", &"")) != &"review":
		return _rejection(&"intern_review", candidate_id, "That internship term is not awaiting review.")
	var definition := REVIEWS[resolution_id] as Dictionary
	var cost_cents := int(definition.get("cost_cents", 0))
	var daily_payroll_delta_cents := int(
		definition.get("daily_payroll_delta_cents", 0)
	)
	var required_spendable_cents := cost_cents + daily_payroll_delta_cents
	if fund_cents < required_spendable_cents:
		return _rejection(
			&"intern_review",
			candidate_id,
			"The free Feed Fund cannot cover that filing plus its new daily payroll reserve.",
		)
	if resolution_id == &"paid_fellowship" and fellow_count() >= 1:
		return _rejection(&"intern_review", candidate_id, "The single paid fellowship perch is already occupied.")
	match resolution_id:
		&"growth_extension":
			record["status"] = &"active"
			record["start_day"] = day
			record["shifts_completed"] = 0
			record["term_shifts"] = EXTENSION_SHIFTS
			record["extensions"] = int(record.get("extensions", 0)) + 1
		&"recommendation_letter":
			record["status"] = &"completed"
			record["completed_day"] = day
		&"paid_fellowship":
			record["status"] = &"fellow"
			record["completed_day"] = day
	return _file_action({
		"accepted": true,
		"action_id": &"intern_review",
		"candidate_id": candidate_id,
		"intern_name": _candidate_name(candidate_id),
		"resolution_id": resolution_id,
		"day": day,
		"cost_cents": cost_cents,
		"daily_payroll_delta_cents": daily_payroll_delta_cents,
		"daily_payroll_after_cents": daily_fellow_payroll_cents(),
		"required_spendable_cents": required_spendable_cents,
		"projected_spendable_cents": fund_cents - required_spendable_cents,
		"outcome": "%s: %s." % [
			_candidate_name(candidate_id),
			String(definition.get("label", "TERM REVIEW")).capitalize(),
		],
	})


func complete_shift(completed_day: int) -> Array[Dictionary]:
	var transitions: Array[Dictionary] = []
	for candidate_id in CANDIDATE_ORDER:
		var record := _records[candidate_id]
		if StringName(record.get("status", &"")) != &"active":
			continue
		if int(record.get("start_day", completed_day)) > completed_day:
			continue
		record["shifts_completed"] = int(record.get("shifts_completed", 0)) + 1
		if int(record.get("shifts_completed", 0)) < int(record.get("term_shifts", TERM_SHIFTS)):
			continue
		record["status"] = &"review"
		record["completed_day"] = completed_day
		var transition := _file_action({
			"accepted": true,
			"action_id": &"intern_term_complete",
			"candidate_id": candidate_id,
			"intern_name": _candidate_name(candidate_id),
			"day": completed_day,
			"cost_cents": 0,
			"outcome": "%s completed the filed rotation and is awaiting a future-opportunity decision."
				% _candidate_name(candidate_id),
		})
		transitions.append(transition)
	return transitions


func snapshot(
	day: int,
	fund_cents: int,
	planning_open: bool,
	seat_limit: int,
) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var normalized_seat_limit := clampi(seat_limit, BASE_SEAT_LIMIT, MAX_SEAT_LIMIT)
	for candidate_id in CANDIDATE_ORDER:
		var profile := (CANDIDATES[candidate_id] as Dictionary).duplicate(true)
		var record := (_records[candidate_id] as Dictionary).duplicate(true)
		profile.merge(record, true)
		profile["can_onboard"] = _onboard_reason(
			candidate_id,
			day,
			fund_cents,
			planning_open,
			normalized_seat_limit,
		).is_empty()
		profile["onboard_reason"] = _onboard_reason(
			candidate_id,
			day,
			fund_cents,
			planning_open,
			normalized_seat_limit,
		)
		profile["term_remaining"] = maxi(
			0,
			int(record.get("term_shifts", TERM_SHIFTS))
				- int(record.get("shifts_completed", 0)),
		)
		candidates.append(profile)
	var assignments: Array[Dictionary] = []
	for assignment_id in ASSIGNMENT_ORDER:
		var row := (ASSIGNMENTS[assignment_id] as Dictionary).duplicate(true)
		row["id"] = assignment_id
		assignments.append(row)
	var reviews: Array[Dictionary] = []
	for review_id in REVIEW_ORDER:
		var row := (REVIEWS[review_id] as Dictionary).duplicate(true)
		row["id"] = review_id
		row["required_spendable_cents"] = (
			int(row.get("cost_cents", 0))
			+ int(row.get("daily_payroll_delta_cents", 0))
		)
		row["affordable"] = (
			fund_cents >= int(row.get("required_spendable_cents", 0))
		)
		row["available"] = not (
			review_id == &"paid_fellowship" and fellow_count() >= 1
		)
		reviews.append(row)
	return {
		"version": SAVE_VERSION,
		"unlocked": day >= UNLOCK_DAY,
		"unlock_day": UNLOCK_DAY,
		"program_name": "BRIGHT-EYED ROTATION",
		"program_tagline": "REAL FILES  /  REAL VISIBILITY  /  FUTURE OPPORTUNITIES",
		"planning_open": planning_open,
		"seat_limit": normalized_seat_limit,
		"active_count": active_count(),
		"fellow_count": fellow_count(),
		"onboarding_cost_cents": ONBOARDING_COST_CENTS,
		"candidates": candidates,
		"assignments": assignments,
		"reviews": reviews,
		"effects": {
			"claim_capacity_bonus": claim_capacity_bonus(),
			"work_basis_points": roundi((work_multiplier() - 1.0) * 10_000.0),
			"crack_basis_points": roundi(crack_modifier() * 10_000.0),
			"morale_drain_basis_points": roundi(morale_drain_multiplier() * 10_000.0),
			"fellow_payroll_cents": daily_fellow_payroll_cents(),
		},
		"last_action": _last_action.duplicate(true),
	}


func to_save_data() -> Dictionary:
	var records: Array[Dictionary] = []
	for candidate_id in CANDIDATE_ORDER:
		var row := (_records[candidate_id] as Dictionary).duplicate(true)
		for key in ["candidate_id", "status", "assignment_id"]:
			row[key] = String(row.get(key, ""))
		records.append(row)
	return {
		"version": SAVE_VERSION,
		"records": records,
		"last_action": _primitive_action(_last_action),
		"history": _primitive_history(),
	}


func restore_save_data(value: Variant, saved_day: int) -> bool:
	if not value is Dictionary:
		return false
	var source := value as Dictionary
	if int(source.get("version", -1)) != SAVE_VERSION:
		return false
	var records_value: Variant = source.get("records", null)
	var history_value: Variant = source.get("history", null)
	var last_action_value: Variant = source.get("last_action", null)
	if (
		not records_value is Array
		or not history_value is Array
		or not last_action_value is Dictionary
		or (records_value as Array).size() != CANDIDATE_ORDER.size()
		or (history_value as Array).size() > 64
	):
		return false
	var restored: Dictionary[StringName, Dictionary] = {}
	for record_value in records_value as Array:
		if not record_value is Dictionary:
			return false
		var record := record_value as Dictionary
		var candidate_id := StringName(String(record.get("candidate_id", "")))
		var status := StringName(String(record.get("status", "")))
		var assignment_id := StringName(String(record.get("assignment_id", "")))
		if (
			candidate_id not in CANDIDATE_ORDER
			or restored.has(candidate_id)
			or status not in [&"candidate", &"active", &"review", &"completed", &"fellow"]
			or not ASSIGNMENTS.has(assignment_id)
		):
			return false
		for key in [
			"start_day", "shifts_completed", "term_shifts", "extensions", "completed_day",
		]:
			if not _is_integral(record.get(key, null)):
				return false
		var start_day := int(record.get("start_day", 0))
		var shifts_completed := int(record.get("shifts_completed", 0))
		var term_shifts := int(record.get("term_shifts", TERM_SHIFTS))
		var extensions := int(record.get("extensions", 0))
		var completed_day := int(record.get("completed_day", 0))
		if (
			start_day < 0 or start_day > saved_day
			or shifts_completed < 0 or shifts_completed > 9999
			or term_shifts < 1 or term_shifts > 9999
			or extensions < 0 or extensions > 9999
			or completed_day < 0 or completed_day > saved_day
		):
			return false
		restored[candidate_id] = {
			"candidate_id": candidate_id,
			"status": status,
			"assignment_id": assignment_id,
			"start_day": start_day,
			"shifts_completed": shifts_completed,
			"term_shifts": term_shifts,
			"extensions": extensions,
			"completed_day": completed_day,
		}
	if restored.size() != CANDIDATE_ORDER.size():
		return false
	var restored_history: Array[Dictionary] = []
	for action_value in history_value as Array:
		if not _valid_saved_action(action_value, saved_day):
			return false
		restored_history.append((action_value as Dictionary).duplicate(true))
	if not (last_action_value as Dictionary).is_empty():
		if not _valid_saved_action(last_action_value, saved_day):
			return false
	_records = restored
	_history = restored_history
	_last_action = (last_action_value as Dictionary).duplicate(true)
	return true


static func neutral_save_data() -> Dictionary:
	var state := InternshipProgramState.new()
	return state.to_save_data()


func _onboard_reason(
	candidate_id: StringName,
	day: int,
	fund_cents: int,
	planning_open: bool,
	seat_limit: int,
) -> String:
	if not _records.has(candidate_id):
		return "That intern is not in the screened cohort."
	if day < UNLOCK_DAY:
		return "The Bright-Eyed Rotation opens on Day %d." % UNLOCK_DAY
	if not planning_open:
		return "Internships can only be filed during planning or review."
	if StringName((_records[candidate_id] as Dictionary).get("status", &"")) != &"candidate":
		return "That candidate already has a filed internship outcome."
	if active_count() >= clampi(seat_limit, BASE_SEAT_LIMIT, MAX_SEAT_LIMIT):
		return "Every supervised intern seat is currently assigned."
	if fund_cents < ONBOARDING_COST_CENTS:
		return "The Feed Fund cannot cover the $3.00 credential-and-meal-card packet."
	return ""


func _candidate_name(candidate_id: StringName) -> String:
	return String((CANDIDATES.get(candidate_id, {}) as Dictionary).get("name", "Office Intern"))


func _rejection(action_id: StringName, candidate_id: StringName, reason: String) -> Dictionary:
	return {
		"accepted": false,
		"action_id": action_id,
		"candidate_id": candidate_id,
		"reason": reason,
	}


func _file_action(action: Dictionary) -> Dictionary:
	_last_action = action.duplicate(true)
	_history.append(_primitive_action(action))
	while _history.size() > 64:
		_history.pop_front()
	return action.duplicate(true)


func _primitive_action(action: Dictionary) -> Dictionary:
	var result := action.duplicate(true)
	for key in ["action_id", "candidate_id", "assignment_id", "resolution_id"]:
		if result.has(key):
			result[key] = String(result[key])
	return result


func _primitive_history() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for action in _history:
		result.append(_primitive_action(action))
	return result


func _valid_saved_action(value: Variant, saved_day: int) -> bool:
	if not value is Dictionary:
		return false
	var action := value as Dictionary
	var candidate_id := StringName(String(action.get("candidate_id", "")))
	if candidate_id not in CANDIDATE_ORDER:
		return false
	if not _is_integral(action.get("day", null)):
		return false
	var action_day := int(action.get("day", 0))
	return action_day >= 1 and action_day <= saved_day


func _is_integral(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and float(value) == floorf(float(value))
