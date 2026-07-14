class_name SeniorRoostState
extends RefCounted

## Persistent post-probation career progression. Probation remains an immutable
## five-shift record; this model owns the recurring three-shift quarters that
## follow it and consumes only primitive workday report facts.

const SCHEMA_ID := "pecking_order.senior_roost"
const SCHEMA_VERSION := 2
const LEGACY_SCHEMA_VERSION := 1
const SHIFTS_PER_QUARTER := 3
const QUARTERS_PER_YEAR := 4
const MAX_ANNUAL_HISTORY := 8
const MAX_SPONSORSHIP_HISTORY := 64
const MAX_COUNTER := 2_000_000_000
const MAX_WORKER_NAME_LENGTH := 128

const SPONSORSHIP_RECORD_VERSION := 1
const SPONSORSHIP_MARK_COST := 3
const SPONSORSHIP_ACTION_ID: StringName = &"career_sponsorship"
const SPONSORSHIP_ALREADY_FILED_REASON := "A Career Sponsorship is already filed for this completed-quarter gate."
const SPONSORSHIP_LANES: Array[StringName] = [
	&"nest_damage",
	&"predator_loss",
	&"appeals",
]

const STATUS_INACTIVE: StringName = &"inactive"
const STATUS_QUARTER_CHOICE: StringName = &"quarter_choice"
const STATUS_ACTIVE: StringName = &"active"
const STATUS_ANNUAL_REVIEW: StringName = &"annual_review"
const VALID_STATUSES: Array[StringName] = [
	STATUS_INACTIVE,
	STATUS_QUARTER_CHOICE,
	STATUS_ACTIVE,
	STATUS_ANNUAL_REVIEW,
]
const SPONSORSHIP_STATUSES: Array[StringName] = [
	STATUS_QUARTER_CHOICE,
	STATUS_ANNUAL_REVIEW,
]

const POLICY_MERIT_GRANTS: StringName = &"merit_grants"
const POLICY_FLOCK_DIVIDEND: StringName = &"flock_dividend"
const POLICY_HARVEST_FORECAST: StringName = &"harvest_forecast"
const POLICY_IDS: Array[StringName] = [
	POLICY_MERIT_GRANTS,
	POLICY_FLOCK_DIVIDEND,
	POLICY_HARVEST_FORECAST,
]

var status: StringName = STATUS_INACTIVE
var total_senior_shifts: int = 0
var completed_quarters: int = 0
var completed_years: int = 0
var successful_years: int = 0
var best_annual_score: int = 0
var roost_marks: int = 0
var roost_marks_spent: int = 0
var last_recorded_day: int = 0
var last_rework_total_created: int = 0

var active_policy_id: StringName = &""
var active_policy_receipt: Dictionary = {}
var current_quarter_shifts: Array[Dictionary] = []
var current_year_quarters: Array[Dictionary] = []
var annual_history: Array[Dictionary] = []
var last_quarter_review: Dictionary = {}
var last_annual_review: Dictionary = {}
var last_shift_result: Dictionary = {}
var sponsorship_history: Array[Dictionary] = []
var choice_counts: Dictionary = {
	POLICY_MERIT_GRANTS: 0,
	POLICY_FLOCK_DIVIDEND: 0,
	POLICY_HARVEST_FORECAST: 0,
}


func begin(last_completed_day: int, simulation_snapshot: Dictionary = {}) -> bool:
	if status != STATUS_INACTIVE or last_completed_day < 0:
		return false
	last_recorded_day = last_completed_day
	last_rework_total_created = maxi(
		0,
		int(simulation_snapshot.get("rework_total_created", 0)),
	)
	status = STATUS_QUARTER_CHOICE
	return true


func requires_quarter_policy() -> bool:
	return status == STATUS_QUARTER_CHOICE and active_policy_id == &""


func is_active() -> bool:
	return status != STATUS_INACTIVE


func available_roost_marks() -> int:
	## Lifetime Roost Marks continue to drive promotion_title(). Spending is
	## tracked separately so a sponsorship can never demote the player.
	return maxi(0, roost_marks - roost_marks_spent)


func sponsorship_available_this_gate() -> bool:
	return (
		status in SPONSORSHIP_STATUSES
		and completed_quarters > 0
		and sponsorship_history.size() < MAX_SPONSORSHIP_HISTORY
		and available_roost_marks() >= SPONSORSHIP_MARK_COST
		and _sponsorship_at_gate(completed_quarters).is_empty()
	)


func sponsorship_for_worker(worker_id: int) -> Dictionary:
	for record in sponsorship_history:
		if int(record.get("worker_id", -1)) == worker_id:
			return record.duplicate(true)
	return {}


func preflight_sponsorship(
	worker_id: int,
	primary_lane: StringName,
	secondary_lane: StringName,
) -> Dictionary:
	## Pure Senior-ledger validation. A coordinator can pair this with the
	## simulation's own pure preflight before either ledger is mutated.
	var rejection := _sponsorship_rejection(worker_id, primary_lane, secondary_lane)
	var accepted := rejection.is_empty()
	return {
		"accepted": accepted,
		"action_id": String(SPONSORSHIP_ACTION_ID),
		"reason_id": "" if accepted else String(rejection.get("reason_id", "held")),
		"reason": "" if accepted else String(rejection.get("reason", "Career Sponsorship is unavailable.")),
		"worker_id": worker_id,
		"primary_lane": String(primary_lane),
		"secondary_lane": String(secondary_lane),
		"mark_cost": SPONSORSHIP_MARK_COST,
		"roost_marks_lifetime_before": roost_marks,
		"roost_marks_spent_before": roost_marks_spent,
		"available_roost_marks_before": available_roost_marks(),
		"sponsorship_count_before": sponsorship_history.size(),
		"completed_quarters_before": completed_quarters,
		"status_before": String(status),
	}


func commit_sponsorship(
	preflight: Dictionary,
	authoritative_receipt: Dictionary,
) -> Dictionary:
	## Commits only the Senior side of the cross-ledger transaction. The caller
	## must supply an accepted, matching simulation receipt obtained after both
	## ledgers passed preflight. The embedded before-values reject stale intents.
	if not bool(preflight.get("accepted", false)):
		return _rejected_sponsorship(
			"preflight_rejected",
			String(preflight.get("reason", "Career Sponsorship preflight was not accepted.")),
		)
	if not _is_integer(preflight.get("worker_id")):
		return _rejected_sponsorship("invalid_preflight", "Career Sponsorship preflight has an invalid worker ID.")
	var worker_id := int(preflight.get("worker_id", -1))
	var primary_lane := StringName(String(preflight.get("primary_lane", "")))
	var secondary_lane := StringName(String(preflight.get("secondary_lane", "")))
	var current := preflight_sponsorship(worker_id, primary_lane, secondary_lane)
	if not bool(current.get("accepted", false)):
		return _rejected_sponsorship(
			String(current.get("reason_id", "held")),
			String(current.get("reason", "Career Sponsorship is no longer available.")),
		)
	if not _sponsorship_preflight_matches(preflight, current):
		return _rejected_sponsorship(
			"stale_preflight",
			"Career Sponsorship preflight is stale; refresh both ledgers before committing.",
		)

	var receipt_error := _authoritative_sponsorship_receipt_error(
		authoritative_receipt,
		worker_id,
		primary_lane,
		secondary_lane,
	)
	if not receipt_error.is_empty():
		return _rejected_sponsorship("authoritative_receipt_rejected", receipt_error)

	roost_marks_spent += SPONSORSHIP_MARK_COST
	var record := {
		"version": SPONSORSHIP_RECORD_VERSION,
		"accepted": true,
		"action_id": String(SPONSORSHIP_ACTION_ID),
		"sponsorship_id": sponsorship_history.size() + 1,
		"career_quarter": completed_quarters,
		"status_at_commit": String(status),
		"worker_id": worker_id,
		"worker_name": String(authoritative_receipt.get("worker_name", "")),
		"primary_lane": String(primary_lane),
		"secondary_lane": String(secondary_lane),
		"mark_cost": SPONSORSHIP_MARK_COST,
		"fund_cost_cents": int(authoritative_receipt.get("fund_cost_cents", 0)),
		"roost_marks_lifetime_at_commit": roost_marks,
		"roost_marks_spent_after": roost_marks_spent,
		"available_roost_marks_after": available_roost_marks(),
	}
	sponsorship_history.append(record.duplicate(true))
	return {
		"accepted": true,
		"action_id": String(SPONSORSHIP_ACTION_ID),
		"reason_id": "",
		"reason": "",
		"record": record.duplicate(true),
		"roost_marks": roost_marks,
		"roost_marks_spent": roost_marks_spent,
		"available_roost_marks": available_roost_marks(),
	}


func _sponsorship_rejection(
	worker_id: int,
	primary_lane: StringName,
	secondary_lane: StringName,
) -> Dictionary:
	if status not in SPONSORSHIP_STATUSES:
		return {
			"reason_id": "invalid_status",
			"reason": "Career Sponsorship may only be filed at a completed-quarter or annual-review gate.",
		}
	if completed_quarters <= 0:
		return {
			"reason_id": "quarter_required",
			"reason": "Complete one Senior quarter before filing a Career Sponsorship.",
		}
	if not _sponsorship_at_gate(completed_quarters).is_empty():
		return {
			"reason_id": "already_filed_this_gate",
			"reason": SPONSORSHIP_ALREADY_FILED_REASON,
		}
	if worker_id < 0 or worker_id > MAX_COUNTER:
		return {
			"reason_id": "invalid_worker",
			"reason": "Career Sponsorship requires a valid persistent worker ID.",
		}
	if primary_lane not in SPONSORSHIP_LANES:
		return {
			"reason_id": "invalid_primary_lane",
			"reason": "Career Sponsorship requires a recognized primary claim lane.",
		}
	if secondary_lane not in SPONSORSHIP_LANES:
		return {
			"reason_id": "invalid_secondary_lane",
			"reason": "Career Sponsorship requires a recognized secondary claim lane.",
		}
	if secondary_lane == primary_lane:
		return {
			"reason_id": "same_lane",
			"reason": "Career Sponsorship must add a claim lane beyond the hen's primary specialty.",
		}
	if sponsorship_history.size() >= MAX_SPONSORSHIP_HISTORY:
		return {
			"reason_id": "history_capacity",
			"reason": "The Career Sponsorship ledger has reached its supported capacity.",
		}
	if not sponsorship_for_worker(worker_id).is_empty():
		return {
			"reason_id": "worker_already_sponsored",
			"reason": "This hen already has a permanent secondary-lane sponsorship.",
		}
	if available_roost_marks() < SPONSORSHIP_MARK_COST:
		return {
			"reason_id": "insufficient_roost_marks",
			"reason": "%d more available Roost Mark%s required." % [
				SPONSORSHIP_MARK_COST - available_roost_marks(),
				" is" if SPONSORSHIP_MARK_COST - available_roost_marks() == 1 else "s are",
			],
		}
	return {}


func _sponsorship_at_gate(career_quarter: int) -> Dictionary:
	for record in sponsorship_history:
		if int(record.get("career_quarter", -1)) == career_quarter:
			return record.duplicate(true)
	return {}


func _sponsorship_preflight_matches(candidate: Dictionary, current: Dictionary) -> bool:
	if String(candidate.get("action_id", "")) != String(SPONSORSHIP_ACTION_ID):
		return false
	for key in [
		"worker_id", "mark_cost", "roost_marks_lifetime_before",
		"roost_marks_spent_before", "available_roost_marks_before",
		"sponsorship_count_before", "completed_quarters_before",
	]:
		if not candidate.has(key) or not _is_integer(candidate.get(key)):
			return false
		if int(candidate.get(key)) != int(current.get(key)):
			return false
	for key in ["primary_lane", "secondary_lane", "status_before"]:
		if typeof(candidate.get(key)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return false
		if String(candidate.get(key)) != String(current.get(key)):
			return false
	return true


func _authoritative_sponsorship_receipt_error(
	receipt: Dictionary,
	worker_id: int,
	primary_lane: StringName,
	secondary_lane: StringName,
) -> String:
	if typeof(receipt.get("accepted")) != TYPE_BOOL or not bool(receipt.get("accepted", false)):
		return "Career Sponsorship requires an accepted authoritative simulation receipt."
	if not _is_integer(receipt.get("worker_id")) or int(receipt.get("worker_id", -1)) != worker_id:
		return "The authoritative Career Sponsorship receipt names a different worker."
	if typeof(receipt.get("primary_lane")) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return "The authoritative Career Sponsorship receipt is missing its primary lane."
	if StringName(String(receipt.get("primary_lane", ""))) != primary_lane:
		return "The authoritative Career Sponsorship receipt names a different primary lane."
	if typeof(receipt.get("secondary_lane")) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return "The authoritative Career Sponsorship receipt is missing its secondary lane."
	if StringName(String(receipt.get("secondary_lane", ""))) != secondary_lane:
		return "The authoritative Career Sponsorship receipt names a different secondary lane."
	var worker_name_value: Variant = receipt.get("worker_name", "")
	if typeof(worker_name_value) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return "The authoritative Career Sponsorship receipt has an invalid worker name."
	if String(worker_name_value).length() > MAX_WORKER_NAME_LENGTH:
		return "The authoritative Career Sponsorship receipt worker name is too long."
	var fund_cost_value: Variant = receipt.get("fund_cost_cents", 0)
	if (
		not _is_integer(fund_cost_value)
		or int(fund_cost_value) < 0
		or int(fund_cost_value) > MAX_COUNTER
	):
		return "The authoritative Career Sponsorship receipt has an invalid Feed Fund cost."
	return ""


func _rejected_sponsorship(reason_id: String, reason: String) -> Dictionary:
	return {
		"accepted": false,
		"action_id": String(SPONSORSHIP_ACTION_ID),
		"reason_id": reason_id,
		"reason": reason,
		"roost_marks": roost_marks,
		"roost_marks_spent": roost_marks_spent,
		"available_roost_marks": available_roost_marks(),
		"sponsorship_count": sponsorship_history.size(),
	}


func policy_catalog(spendable_cents: int = MAX_COUNTER) -> Array[Dictionary]:
	var policies: Array[Dictionary] = []
	for definition in _policy_definitions():
		var policy := definition.duplicate(true)
		var cost_cents := int(policy.get("cost_cents", 0))
		var available := cost_cents <= maxi(0, spendable_cents)
		policy["available"] = available
		policy["unavailable_reason"] = (
			"$%.2f more spendable Feed Fund is required." % (
				float(cost_cents - maxi(0, spendable_cents)) / 100.0
			)
			if not available else
			""
		)
		policies.append(policy)
	return policies


func record_quarter_policy(receipt: Dictionary) -> bool:
	if not requires_quarter_policy() or not bool(receipt.get("accepted", false)):
		return false
	var policy_id := StringName(String(receipt.get("policy_id", "")))
	if policy_id not in POLICY_IDS:
		return false
	active_policy_id = policy_id
	active_policy_receipt = _json_safe_variant(receipt) as Dictionary
	choice_counts[policy_id] = int(choice_counts.get(policy_id, 0)) + 1
	status = STATUS_ACTIVE
	return true


func record_shift(report: Dictionary) -> Dictionary:
	var errors := _validate_shift_report(report)
	if status != STATUS_ACTIVE or active_policy_id == &"":
		errors.append("a Senior Roost quarter policy is required")
	if not errors.is_empty():
		return {"accepted": false, "errors": errors}

	var record := _normalize_shift(report)
	current_quarter_shifts.append(record)
	total_senior_shifts += 1
	last_recorded_day = int(record["day"])
	last_rework_total_created += int(record["rework_created"])
	last_shift_result = {
		"accepted": true,
		"day": int(record["day"]),
		"year": current_year_number(),
		"quarter": current_quarter_in_year(),
		"shift_in_quarter": current_quarter_shifts.size(),
		"quarter_complete": false,
		"annual_complete": false,
	}

	var quarter_review: Dictionary = {}
	var annual_review: Dictionary = {}
	if current_quarter_shifts.size() == SHIFTS_PER_QUARTER:
		quarter_review = _close_quarter()
		last_shift_result["quarter_complete"] = true
		last_shift_result["quarter_review"] = quarter_review.duplicate(true)
		if status == STATUS_ANNUAL_REVIEW:
			annual_review = last_annual_review.duplicate(true)
			last_shift_result["annual_complete"] = true
			last_shift_result["annual_review"] = annual_review.duplicate(true)

	return {
		"accepted": true,
		"errors": PackedStringArray(),
		"record": record.duplicate(true),
		"quarter_complete": not quarter_review.is_empty(),
		"annual_complete": not annual_review.is_empty(),
		"quarter_review": quarter_review,
		"annual_review": annual_review,
		"state": snapshot(),
	}


func continue_after_annual() -> bool:
	if status != STATUS_ANNUAL_REVIEW:
		return false
	status = STATUS_QUARTER_CHOICE
	return true


func current_year_number() -> int:
	return completed_years + 1


func current_quarter_in_year() -> int:
	return current_year_quarters.size() + 1


func current_shift_in_quarter() -> int:
	return mini(SHIFTS_PER_QUARTER, current_quarter_shifts.size() + 1)


func promotion_title() -> String:
	if roost_marks >= 50:
		return "EXECUTIVE NEST OFFICER"
	if roost_marks >= 30:
		return "VICE PRESIDENT OF EGGS"
	if roost_marks >= 15:
		return "REGIONAL COOP DIRECTOR"
	if roost_marks >= 6:
		return "DEPARTMENT ROOSTER"
	return "SENIOR CLAIMS ROOSTER"


func active_policy() -> Dictionary:
	for policy in _policy_definitions():
		if StringName(policy.get("id", &"")) == active_policy_id:
			return policy.duplicate(true)
	return {}


func current_objective_progress(live_metrics: Dictionary = {}) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if status != STATUS_ACTIVE or active_policy_id == &"":
		return result
	var records: Array[Dictionary] = []
	for record in current_quarter_shifts:
		records.append(record.duplicate(true))
	if not live_metrics.is_empty() and records.size() < SHIFTS_PER_QUARTER:
		records.append(_projection_record(live_metrics))
	if records.is_empty():
		return result
	var aggregate := _aggregate_records(records)
	var quota_met_shifts := int(aggregate.get("quota_met_shifts", 0))
	var crack_rate := int(aggregate.get("crack_rate_basis_points", 0))
	var projected_score := _score_records(records, true)
	result.append(_objective_row(
		&"quota_shifts", "QUOTA RELIABILITY",
		"Meet the filed clutch target in all three quarter shifts.",
		&"minimum", quota_met_shifts, SHIFTS_PER_QUARTER,
		quota_met_shifts >= records.size(), 30,
	))
	result.append(_objective_row(
		&"crack_rate_basis_points", "SHELL INTEGRITY",
		"Keep the quarter crack rate at or below 15% for full quality credit.",
		&"maximum", crack_rate, 1500, crack_rate <= 1500, 20,
	))
	result.append(_objective_row(
		&"quarter_score", "SENIOR STANDING",
		"Project at least 60 points across output, quality, queues, and safeguards.",
		&"minimum", projected_score, 60, projected_score >= 60, 3,
	))
	return result


func snapshot() -> Dictionary:
	return {
		"status": String(status),
		"total_senior_shifts": total_senior_shifts,
		"completed_quarters": completed_quarters,
		"completed_years": completed_years,
		"successful_years": successful_years,
		"best_annual_score": best_annual_score,
		"roost_marks": roost_marks,
		"roost_marks_spent": roost_marks_spent,
		"available_roost_marks": available_roost_marks(),
		"sponsorship_mark_cost": SPONSORSHIP_MARK_COST,
		"sponsorship_available_this_gate": sponsorship_available_this_gate(),
		"sponsorship_count": sponsorship_history.size(),
		"sponsorship_history": sponsorship_history.duplicate(true),
		"promotion_title": promotion_title(),
		"year": current_year_number(),
		"quarter": current_quarter_in_year(),
		"shift_in_quarter": current_shift_in_quarter(),
		"active_policy_id": String(active_policy_id),
		"active_policy": active_policy(),
		"requires_policy": requires_quarter_policy(),
		"last_shift_result": last_shift_result.duplicate(true),
		"last_quarter_review": last_quarter_review.duplicate(true),
		"last_annual_review": last_annual_review.duplicate(true),
	}


func to_dictionary() -> Dictionary:
	var saved_counts: Dictionary = {}
	for policy_id in POLICY_IDS:
		saved_counts[String(policy_id)] = int(choice_counts.get(policy_id, 0))
	return {
		"schema_id": SCHEMA_ID,
		"schema_version": SCHEMA_VERSION,
		"status": String(status),
		"total_senior_shifts": total_senior_shifts,
		"completed_quarters": completed_quarters,
		"completed_years": completed_years,
		"successful_years": successful_years,
		"best_annual_score": best_annual_score,
		"roost_marks": roost_marks,
		"roost_marks_spent": roost_marks_spent,
		"last_recorded_day": last_recorded_day,
		"last_rework_total_created": last_rework_total_created,
		"active_policy_id": String(active_policy_id),
		"active_policy_receipt": active_policy_receipt.duplicate(true),
		"current_quarter_shifts": current_quarter_shifts.duplicate(true),
		"current_year_quarters": current_year_quarters.duplicate(true),
		"annual_history": annual_history.duplicate(true),
		"last_quarter_review": last_quarter_review.duplicate(true),
		"last_annual_review": last_annual_review.duplicate(true),
		"last_shift_result": last_shift_result.duplicate(true),
		"sponsorship_history": sponsorship_history.duplicate(true),
		"choice_counts": saved_counts,
	}


static func from_dictionary(data: Dictionary) -> SeniorRoostState:
	var migrated := _migrate_to_current_schema(data)
	var errors := validate_dictionary(migrated)
	if not errors.is_empty():
		push_warning("Senior Roost save rejected: %s" % "; ".join(errors))
		return null
	var state := SeniorRoostState.new()
	state._hydrate_unchecked(migrated)
	return state


static func validate_dictionary(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if String(data.get("schema_id", "")) != SCHEMA_ID:
		errors.append("schema_id is not supported")
	if not _is_integer(data.get("schema_version")) or int(data.get("schema_version", -1)) != SCHEMA_VERSION:
		errors.append("schema_version is not supported")
	var status_id := StringName(String(data.get("status", "")))
	if status_id not in VALID_STATUSES:
		errors.append("status is not supported")
	for key in [
		"total_senior_shifts", "completed_quarters", "completed_years",
		"successful_years", "best_annual_score", "roost_marks", "roost_marks_spent",
		"last_recorded_day", "last_rework_total_created",
	]:
		if not _is_integer(data.get(key)) or int(data.get(key, -1)) < 0 or int(data.get(key, 0)) > MAX_COUNTER:
			errors.append("%s must be a nonnegative integer" % key)
	var active_policy := StringName(String(data.get("active_policy_id", "")))
	if active_policy != &"" and active_policy not in POLICY_IDS:
		errors.append("active_policy_id is not supported")
	for key in [
		"active_policy_receipt", "last_quarter_review", "last_annual_review",
		"last_shift_result", "choice_counts",
	]:
		if typeof(data.get(key)) != TYPE_DICTIONARY:
			errors.append("%s must be a Dictionary" % key)
	for key in [
		"current_quarter_shifts", "current_year_quarters", "annual_history",
		"sponsorship_history",
	]:
		if typeof(data.get(key)) != TYPE_ARRAY:
			errors.append("%s must be an Array" % key)
	if not errors.is_empty():
		return errors

	var quarter_shifts := data.get("current_quarter_shifts", []) as Array
	var year_quarters := data.get("current_year_quarters", []) as Array
	var history := data.get("annual_history", []) as Array
	var saved_sponsorships := data.get("sponsorship_history", []) as Array
	if quarter_shifts.size() >= SHIFTS_PER_QUARTER:
		errors.append("current_quarter_shifts must contain at most two records")
	if year_quarters.size() >= QUARTERS_PER_YEAR:
		errors.append("current_year_quarters must contain at most three records")
	if history.size() > MAX_ANNUAL_HISTORY:
		errors.append("annual_history exceeds its retention limit")
	if saved_sponsorships.size() > MAX_SPONSORSHIP_HISTORY:
		errors.append("sponsorship_history exceeds its retention limit")
	for record_value in quarter_shifts:
		if not record_value is Dictionary:
			errors.append("current_quarter_shifts entries must be Dictionaries")
			continue
		_validate_saved_shift(record_value as Dictionary, errors)
	for quarter_value in year_quarters:
		if not quarter_value is Dictionary:
			errors.append("current_year_quarters entries must be Dictionaries")
	for annual_value in history:
		if not annual_value is Dictionary:
			errors.append("annual_history entries must be Dictionaries")

	var total_shifts := int(data.get("total_senior_shifts", 0))
	var completed_quarter_count := int(data.get("completed_quarters", 0))
	var completed_year_count := int(data.get("completed_years", 0))
	var lifetime_marks := int(data.get("roost_marks", 0))
	var spent_marks := int(data.get("roost_marks_spent", 0))
	if total_shifts != completed_quarter_count * SHIFTS_PER_QUARTER + quarter_shifts.size():
		errors.append("total_senior_shifts is inconsistent with quarter records")
	if completed_quarter_count != completed_year_count * QUARTERS_PER_YEAR + year_quarters.size():
		errors.append("completed_quarters is inconsistent with year records")
	if int(data.get("successful_years", 0)) > completed_year_count:
		errors.append("successful_years cannot exceed completed_years")
	if spent_marks > lifetime_marks:
		errors.append("roost_marks_spent cannot exceed lifetime roost_marks")
	_validate_saved_sponsorships(
		saved_sponsorships,
		completed_quarter_count,
		lifetime_marks,
		spent_marks,
		errors,
	)
	var counts := data.get("choice_counts", {}) as Dictionary
	var choice_total := 0
	for policy_id in POLICY_IDS:
		var count_value: Variant = counts.get(String(policy_id))
		if not _is_integer(count_value) or int(count_value) < 0:
			errors.append("choice_counts.%s must be a nonnegative integer" % String(policy_id))
		else:
			choice_total += int(count_value)
	var expected_choices := completed_quarter_count + (1 if active_policy != &"" else 0)
	if choice_total != expected_choices:
		errors.append("choice_counts is inconsistent with filed quarter policies")

	match status_id:
		STATUS_INACTIVE:
			if total_shifts != 0 or completed_quarter_count != 0 or active_policy != &"":
				errors.append("inactive Senior Roost state must be empty")
			if spent_marks != 0 or not saved_sponsorships.is_empty():
				errors.append("inactive Senior Roost state cannot contain sponsorship spending")
		STATUS_QUARTER_CHOICE:
			if active_policy != &"" or not quarter_shifts.is_empty():
				errors.append("quarter_choice requires an empty upcoming quarter")
		STATUS_ACTIVE:
			if active_policy == &"":
				errors.append("active Senior Roost state requires a policy")
		STATUS_ANNUAL_REVIEW:
			if active_policy != &"" or not quarter_shifts.is_empty() or not year_quarters.is_empty():
				errors.append("annual_review requires a closed Senior year")
			if completed_year_count <= 0 or history.is_empty():
				errors.append("annual_review requires a persisted annual record")
	return errors


func _close_quarter() -> Dictionary:
	var quarter_number := completed_quarters + 1
	var year_number := completed_years + 1
	var quarter_in_year := current_year_quarters.size() + 1
	var review := _summarize_quarter(
		current_quarter_shifts,
		active_policy_id,
		active_policy_receipt,
		quarter_number,
		year_number,
		quarter_in_year,
	)
	var score := int(review.get("score", 0))
	var marks_awarded := 3 if score >= 80 else (2 if score >= 60 else (1 if score >= 45 else 0))
	roost_marks += marks_awarded
	review["marks_awarded"] = marks_awarded
	review["roost_marks_after"] = roost_marks
	current_year_quarters.append(review.duplicate(true))
	last_quarter_review = review.duplicate(true)
	completed_quarters += 1
	current_quarter_shifts.clear()
	active_policy_id = &""
	active_policy_receipt.clear()
	status = STATUS_QUARTER_CHOICE

	if current_year_quarters.size() == QUARTERS_PER_YEAR:
		var annual := _summarize_annual(current_year_quarters, completed_years + 1)
		completed_years += 1
		if bool(annual.get("passed", false)):
			successful_years += 1
			roost_marks += 3
		annual["annual_bonus_marks"] = 3 if bool(annual.get("passed", false)) else 0
		annual["roost_marks_after"] = roost_marks
		best_annual_score = maxi(best_annual_score, int(annual.get("score", 0)))
		last_annual_review = annual.duplicate(true)
		annual_history.append(annual.duplicate(true))
		while annual_history.size() > MAX_ANNUAL_HISTORY:
			annual_history.pop_front()
		current_year_quarters.clear()
		status = STATUS_ANNUAL_REVIEW
	return review


func _summarize_quarter(
	records: Array[Dictionary],
	policy_id: StringName,
	policy_receipt: Dictionary,
	quarter_number: int,
	year_number: int,
	quarter_in_year: int,
) -> Dictionary:
	var aggregate := _aggregate_records(records)
	var score := _score_records(records, false)
	return {
		"quarter_number": quarter_number,
		"year": year_number,
		"quarter_in_year": quarter_in_year,
		"shift_count": records.size(),
		"policy_id": String(policy_id),
		"policy_title": String(active_policy().get("title", "SENIOR POLICY")),
		"policy_receipt": policy_receipt.duplicate(true),
		"style_id": String(policy_receipt.get("style_id", "")),
		"score": score,
		"eggs": int(aggregate.get("eggs", 0)),
		"quota": int(aggregate.get("quota", 0)),
		"quota_met_shifts": int(aggregate.get("quota_met_shifts", 0)),
		"cracked": int(aggregate.get("cracked", 0)),
		"crack_rate_basis_points": int(aggregate.get("crack_rate_basis_points", 0)),
		"overdue": int(aggregate.get("overdue", 0)),
		"rework_created": int(aggregate.get("rework_created", 0)),
		"credited_cents": int(aggregate.get("credited_cents", 0)),
		"welfare": int(aggregate.get("welfare", 0)),
		"compliance": int(aggregate.get("compliance", 0)),
		"farmer_favor": int(aggregate.get("farmer_favor", 0)),
		"closing_wage_arrears_cents": int(aggregate.get("closing_wage_arrears_cents", 0)),
		"closing_fund_cents": int(aggregate.get("closing_fund_cents", 0)),
		"records": records.duplicate(true),
	}


func _summarize_annual(quarters: Array[Dictionary], year_number: int) -> Dictionary:
	var score_total := 0
	var eggs := 0
	var quota := 0
	var cracked := 0
	var welfare_total := 0
	var compliance_total := 0
	var favor_total := 0
	var credited_cents := 0
	var closing_arrears := 0
	var policy_styles: Dictionary = {}
	for quarter in quarters:
		score_total += int(quarter.get("score", 0))
		eggs += int(quarter.get("eggs", 0))
		quota += int(quarter.get("quota", 0))
		cracked += int(quarter.get("cracked", 0))
		welfare_total += int(quarter.get("welfare", 0))
		compliance_total += int(quarter.get("compliance", 0))
		favor_total += int(quarter.get("farmer_favor", 0))
		credited_cents += int(quarter.get("credited_cents", 0))
		closing_arrears = int(quarter.get("closing_wage_arrears_cents", 0))
		var style_id := String(quarter.get("style_id", "unfiled"))
		policy_styles[style_id] = int(policy_styles.get(style_id, 0)) + 1
	var score := roundi(float(score_total) / float(maxi(1, quarters.size())))
	var welfare := roundi(float(welfare_total) / float(maxi(1, quarters.size())))
	var compliance := roundi(float(compliance_total) / float(maxi(1, quarters.size())))
	var farmer_favor := roundi(float(favor_total) / float(maxi(1, quarters.size())))
	var crack_rate := _basis_points(cracked, eggs)
	var criteria := {
		"score": score >= 60,
		"welfare": welfare >= 45,
		"compliance": compliance >= 55,
		"farmer_favor": farmer_favor >= 50,
		"shell_quality": crack_rate <= 2500,
		"solvency": closing_arrears == 0,
	}
	var passed := true
	for criterion in criteria.values():
		passed = passed and bool(criterion)
	return {
		"year": year_number,
		"score": score,
		"passed": passed,
		"criteria": criteria,
		"welfare": welfare,
		"compliance": compliance,
		"farmer_favor": farmer_favor,
		"eggs": eggs,
		"quota": quota,
		"cracked": cracked,
		"crack_rate_basis_points": crack_rate,
		"credited_cents": credited_cents,
		"closing_wage_arrears_cents": closing_arrears,
		"dominant_policy_style": _dominant_key(policy_styles),
		"policy_style_counts": policy_styles,
		"quarters": quarters.duplicate(true),
	}


func _score_records(records: Array[Dictionary], normalize_quota: bool) -> int:
	if records.is_empty():
		return 0
	var aggregate := _aggregate_records(records)
	var met_shifts := int(aggregate.get("quota_met_shifts", 0))
	var quota_points := (
		roundi(30.0 * float(met_shifts) / float(records.size()))
		if normalize_quota else
		met_shifts * 10
	)
	var crack_rate := int(aggregate.get("crack_rate_basis_points", 10000))
	var quality_points := 20 if crack_rate <= 1500 else (10 if crack_rate <= 2500 else 0)
	var overdue := int(aggregate.get("overdue", 0))
	var queue_points := 10 if overdue <= 3 else (5 if overdue <= 6 else 0)
	var welfare := int(aggregate.get("welfare", 0))
	var welfare_points := 15 if welfare >= 60 else (8 if welfare >= 45 else 0)
	var compliance := int(aggregate.get("compliance", 0))
	var compliance_points := 10 if compliance >= 70 else (5 if compliance >= 55 else 0)
	var favor := int(aggregate.get("farmer_favor", 0))
	var favor_points := 10 if favor >= 60 else (5 if favor >= 50 else 0)
	var solvency_points := 5 if int(aggregate.get("closing_wage_arrears_cents", 0)) == 0 else 0
	return clampi(
		quota_points + quality_points + queue_points + welfare_points
		+ compliance_points + favor_points + solvency_points,
		0,
		100,
	)


func _aggregate_records(records: Array[Dictionary]) -> Dictionary:
	var eggs := 0
	var quota := 0
	var cracked := 0
	var quota_met_shifts := 0
	var overdue := 0
	var rework_created := 0
	var credited_cents := 0
	var welfare_total := 0
	var compliance_total := 0
	var favor_total := 0
	var closing_arrears := 0
	var closing_fund := 0
	for record in records:
		eggs += maxi(0, int(record.get("eggs", 0)))
		quota += maxi(1, int(record.get("quota", 1)))
		cracked += maxi(0, int(record.get("cracked", 0)))
		quota_met_shifts += 1 if bool(record.get("met_quota", false)) else 0
		overdue += maxi(0, int(record.get("overdue", 0)))
		rework_created += maxi(0, int(record.get("rework_created", 0)))
		credited_cents += maxi(0, int(record.get("credited_cents", 0)))
		welfare_total += clampi(int(record.get("welfare", 0)), 0, 100)
		compliance_total += clampi(int(record.get("compliance", 0)), 0, 100)
		favor_total += clampi(int(record.get("farmer_favor", 0)), 0, 100)
		closing_arrears = maxi(0, int(record.get("wage_arrears_cents", 0)))
		closing_fund = maxi(0, int(record.get("closing_fund_cents", 0)))
	var count := maxi(1, records.size())
	return {
		"eggs": eggs,
		"quota": quota,
		"quota_met_shifts": quota_met_shifts,
		"cracked": cracked,
		"crack_rate_basis_points": _basis_points(cracked, eggs),
		"overdue": overdue,
		"rework_created": rework_created,
		"credited_cents": credited_cents,
		"welfare": roundi(float(welfare_total) / float(count)),
		"compliance": roundi(float(compliance_total) / float(count)),
		"farmer_favor": roundi(float(favor_total) / float(count)),
		"closing_wage_arrears_cents": closing_arrears,
		"closing_fund_cents": closing_fund,
	}


func _validate_shift_report(report: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	for key in [
		"day", "eggs", "quota", "cracked", "overdue_claims",
		"rework_total_created", "credited_cents", "welfare", "compliance",
		"farmer_favor", "wage_arrears_cents", "closing_fund_cents",
	]:
		if not _is_integer(report.get(key)):
			errors.append("report.%s must be an integer" % key)
	if not errors.is_empty():
		return errors
	if int(report["day"]) != last_recorded_day + 1:
		errors.append("report.day must follow the last recorded Senior shift")
	for key in [
		"eggs", "quota", "cracked", "overdue_claims", "rework_total_created",
		"credited_cents", "wage_arrears_cents", "closing_fund_cents",
	]:
		if int(report[key]) < 0:
			errors.append("report.%s cannot be negative" % key)
	for key in ["welfare", "compliance", "farmer_favor"]:
		if int(report[key]) < 0 or int(report[key]) > 100:
			errors.append("report.%s must be between 0 and 100" % key)
	if int(report["quota"]) <= 0:
		errors.append("report.quota must be positive")
	if int(report["cracked"]) > int(report["eggs"]):
		errors.append("report.cracked cannot exceed report.eggs")
	if int(report["rework_total_created"]) < last_rework_total_created:
		errors.append("report.rework_total_created cannot move backward")
	return errors


func _normalize_shift(report: Dictionary) -> Dictionary:
	return {
		"day": int(report["day"]),
		"eggs": int(report["eggs"]),
		"quota": int(report["quota"]),
		"met_quota": int(report["eggs"]) >= int(report["quota"]),
		"cracked": int(report["cracked"]),
		"overdue": int(report["overdue_claims"]),
		"rework_created": int(report["rework_total_created"]) - last_rework_total_created,
		"credited_cents": int(report["credited_cents"]),
		"welfare": int(report["welfare"]),
		"compliance": int(report["compliance"]),
		"farmer_favor": int(report["farmer_favor"]),
		"wage_arrears_cents": int(report["wage_arrears_cents"]),
		"closing_fund_cents": int(report["closing_fund_cents"]),
	}


func _projection_record(live: Dictionary) -> Dictionary:
	var eggs := maxi(0, int(live.get("eggs", 0)))
	var quota := maxi(1, int(live.get("quota", 1)))
	return {
		"day": last_recorded_day + 1,
		"eggs": eggs,
		"quota": quota,
		"met_quota": eggs >= quota,
		"cracked": clampi(int(live.get("cracked", 0)), 0, eggs),
		"overdue": maxi(0, int(live.get("overdue_files", 0))),
		"rework_created": maxi(0, int(live.get("rework", 0))),
		"credited_cents": maxi(0, int(live.get("credited_cents", 0))),
		"welfare": clampi(int(live.get("welfare", 0)), 0, 100),
		"compliance": clampi(int(live.get("compliance", 0)), 0, 100),
		"farmer_favor": clampi(int(live.get("farmer_favor", 0)), 0, 100),
		"wage_arrears_cents": maxi(0, int(live.get("wage_arrears_cents", 0))),
		"closing_fund_cents": maxi(0, int(live.get("closing_fund_cents", 0))),
	}


func _objective_row(
	metric: StringName,
	title: String,
	description: String,
	comparison: StringName,
	actual: int,
	target: int,
	projected_met: bool,
	score_award: int,
) -> Dictionary:
	return {
		"metric": metric,
		"title": title,
		"description": description,
		"comparison": comparison,
		"actual": actual,
		"target": target,
		"projected_met": projected_met,
		"status": "on_track" if projected_met else "needs_action",
		"score_award": score_award,
	}


static func _migrate_to_current_schema(data: Dictionary) -> Dictionary:
	## Nested Senior saves own their schema independently from the outer campaign
	## envelope. Never mutate the caller's Dictionary during migration.
	var migrated := data.duplicate(true)
	if String(migrated.get("schema_id", "")) != SCHEMA_ID:
		return migrated
	if not _is_integer(migrated.get("schema_version")):
		return migrated
	var source_version := int(migrated.get("schema_version", -1))
	if source_version == LEGACY_SCHEMA_VERSION:
		migrated["roost_marks_spent"] = 0
		migrated["sponsorship_history"] = []
		migrated["schema_version"] = 2
	return migrated


func _hydrate_unchecked(data: Dictionary) -> void:
	status = StringName(String(data["status"]))
	total_senior_shifts = int(data["total_senior_shifts"])
	completed_quarters = int(data["completed_quarters"])
	completed_years = int(data["completed_years"])
	successful_years = int(data["successful_years"])
	best_annual_score = int(data["best_annual_score"])
	roost_marks = int(data["roost_marks"])
	roost_marks_spent = int(data["roost_marks_spent"])
	last_recorded_day = int(data["last_recorded_day"])
	last_rework_total_created = int(data["last_rework_total_created"])
	active_policy_id = StringName(String(data["active_policy_id"]))
	active_policy_receipt = _restore_json_numbers(data["active_policy_receipt"]) as Dictionary
	current_quarter_shifts.assign(_restore_json_numbers(data["current_quarter_shifts"]) as Array)
	current_year_quarters.assign(_restore_json_numbers(data["current_year_quarters"]) as Array)
	annual_history.assign(_restore_json_numbers(data["annual_history"]) as Array)
	last_quarter_review = _restore_json_numbers(data["last_quarter_review"]) as Dictionary
	last_annual_review = _restore_json_numbers(data["last_annual_review"]) as Dictionary
	last_shift_result = _restore_json_numbers(data["last_shift_result"]) as Dictionary
	sponsorship_history.assign(_restore_json_numbers(data["sponsorship_history"]) as Array)
	var counts := data["choice_counts"] as Dictionary
	for policy_id in POLICY_IDS:
		choice_counts[policy_id] = int(counts.get(String(policy_id), 0))


static func _validate_saved_sponsorships(
	records: Array,
	completed_quarter_count: int,
	lifetime_marks: int,
	spent_marks: int,
	errors: PackedStringArray,
) -> void:
	if spent_marks != records.size() * SPONSORSHIP_MARK_COST:
		errors.append("roost_marks_spent is inconsistent with sponsorship_history")
	if records.size() > completed_quarter_count:
		errors.append("sponsorship_history cannot exceed completed-quarter gates")

	var seen_workers: Dictionary = {}
	var previous_gate := 0
	var previous_lifetime_marks := 0
	for index in records.size():
		var record_value: Variant = records[index]
		if not record_value is Dictionary:
			errors.append("sponsorship_history entries must be Dictionaries")
			continue
		var record := record_value as Dictionary
		var type_error := false
		for key in [
			"version", "sponsorship_id", "career_quarter", "worker_id",
			"mark_cost", "fund_cost_cents", "roost_marks_lifetime_at_commit",
			"roost_marks_spent_after", "available_roost_marks_after",
		]:
			if not _is_integer(record.get(key)):
				errors.append("sponsorship_history[%d].%s must be an integer" % [index, key])
				type_error = true
		if typeof(record.get("accepted")) != TYPE_BOOL:
			errors.append("sponsorship_history[%d].accepted must be a bool" % index)
			type_error = true
		for key in [
			"action_id", "status_at_commit", "worker_name", "primary_lane",
			"secondary_lane",
		]:
			if typeof(record.get(key)) not in [TYPE_STRING, TYPE_STRING_NAME]:
				errors.append("sponsorship_history[%d].%s must be a String" % [index, key])
				type_error = true
		if type_error:
			continue

		var sponsorship_id := int(record.get("sponsorship_id", 0))
		var career_quarter := int(record.get("career_quarter", 0))
		var worker_id := int(record.get("worker_id", -1))
		var mark_cost := int(record.get("mark_cost", -1))
		var fund_cost := int(record.get("fund_cost_cents", -1))
		var lifetime_at_commit := int(record.get("roost_marks_lifetime_at_commit", -1))
		var spent_after := int(record.get("roost_marks_spent_after", -1))
		var available_after := int(record.get("available_roost_marks_after", -1))
		var primary_lane := StringName(String(record.get("primary_lane", "")))
		var secondary_lane := StringName(String(record.get("secondary_lane", "")))
		var commit_status := StringName(String(record.get("status_at_commit", "")))

		if int(record.get("version", -1)) != SPONSORSHIP_RECORD_VERSION:
			errors.append("sponsorship_history[%d].version is not supported" % index)
		if not bool(record.get("accepted", false)):
			errors.append("sponsorship_history[%d] must be an accepted receipt" % index)
		if StringName(String(record.get("action_id", ""))) != SPONSORSHIP_ACTION_ID:
			errors.append("sponsorship_history[%d].action_id is not supported" % index)
		if sponsorship_id != index + 1:
			errors.append("sponsorship_history[%d].sponsorship_id is inconsistent" % index)
		if career_quarter <= previous_gate or career_quarter > completed_quarter_count:
			errors.append("sponsorship_history[%d].career_quarter must identify a later completed-quarter gate" % index)
		else:
			previous_gate = career_quarter
		if commit_status not in SPONSORSHIP_STATUSES:
			errors.append("sponsorship_history[%d].status_at_commit is not a sponsorship gate" % index)
		if worker_id < 0 or worker_id > MAX_COUNTER:
			errors.append("sponsorship_history[%d].worker_id is invalid" % index)
		elif seen_workers.has(worker_id):
			errors.append("sponsorship_history contains more than one sponsorship for worker %d" % worker_id)
		else:
			seen_workers[worker_id] = true
		if String(record.get("worker_name", "")).length() > MAX_WORKER_NAME_LENGTH:
			errors.append("sponsorship_history[%d].worker_name is too long" % index)
		if primary_lane not in SPONSORSHIP_LANES:
			errors.append("sponsorship_history[%d].primary_lane is not supported" % index)
		if secondary_lane not in SPONSORSHIP_LANES:
			errors.append("sponsorship_history[%d].secondary_lane is not supported" % index)
		if primary_lane == secondary_lane:
			errors.append("sponsorship_history[%d] must add a secondary lane" % index)
		if mark_cost != SPONSORSHIP_MARK_COST:
			errors.append("sponsorship_history[%d].mark_cost is inconsistent" % index)
		if fund_cost < 0 or fund_cost > MAX_COUNTER:
			errors.append("sponsorship_history[%d].fund_cost_cents is invalid" % index)
		var expected_spent_after := (index + 1) * SPONSORSHIP_MARK_COST
		if spent_after != expected_spent_after:
			errors.append("sponsorship_history[%d].roost_marks_spent_after is inconsistent" % index)
		if (
			lifetime_at_commit < spent_after
			or lifetime_at_commit < previous_lifetime_marks
			or lifetime_at_commit > lifetime_marks
		):
			errors.append("sponsorship_history[%d].roost_marks_lifetime_at_commit is inconsistent" % index)
		else:
			previous_lifetime_marks = lifetime_at_commit
		if available_after != lifetime_at_commit - spent_after:
			errors.append("sponsorship_history[%d].available_roost_marks_after is inconsistent" % index)


static func _validate_saved_shift(record: Dictionary, errors: PackedStringArray) -> void:
	for key in [
		"day", "eggs", "quota", "cracked", "overdue", "rework_created",
		"credited_cents", "welfare", "compliance", "farmer_favor",
		"wage_arrears_cents", "closing_fund_cents",
	]:
		if not _is_integer(record.get(key)):
			errors.append("saved Senior shift.%s must be an integer" % key)
	if typeof(record.get("met_quota")) != TYPE_BOOL:
		errors.append("saved Senior shift.met_quota must be a bool")


static func _is_integer(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (
		typeof(value) == TYPE_FLOAT
		and is_finite(float(value))
		and is_equal_approx(float(value), roundf(float(value)))
	)


static func _basis_points(numerator: int, denominator: int) -> int:
	if denominator <= 0:
		return 0
	return roundi(float(maxi(0, numerator)) / float(denominator) * 10000.0)


static func _dominant_key(counts: Dictionary) -> String:
	var best_key := "balanced"
	var best_count := -1
	var tied := false
	for key in counts:
		var count := int(counts[key])
		if count > best_count:
			best_count = count
			best_key = String(key)
			tied = false
		elif count == best_count:
			tied = true
	return "balanced" if tied else best_key


static func _json_safe_variant(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var safe: Dictionary = {}
			for key: Variant in value as Dictionary:
				safe[String(key)] = _json_safe_variant((value as Dictionary)[key])
			return safe
		TYPE_ARRAY:
			var safe_array: Array = []
			for item: Variant in value as Array:
				safe_array.append(_json_safe_variant(item))
			return safe_array
		TYPE_STRING_NAME:
			return String(value)
		_:
			return value


static func _restore_json_numbers(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var restored: Dictionary = {}
			for key: Variant in value as Dictionary:
				restored[String(key)] = _restore_json_numbers((value as Dictionary)[key])
			return restored
		TYPE_ARRAY:
			var restored_array: Array = []
			for item: Variant in value as Array:
				restored_array.append(_restore_json_numbers(item))
			return restored_array
		TYPE_FLOAT:
			var number := float(value)
			return int(number) if is_finite(number) and is_equal_approx(number, roundf(number)) else number
		_:
			return value


static func _policy_definitions() -> Array[Dictionary]:
	return [
		{
			"id": POLICY_MERIT_GRANTS,
			"title": "MERIT GRANTS",
			"description": "Concentrate development money on the quarter's top hen.",
			"effect": "-$12.00  /  top hen +18 XP, morale and trust  /  favor -2",
			"cost_cents": 1200,
			"style_id": &"individual_merit",
		},
		{
			"id": POLICY_FLOCK_DIVIDEND,
			"title": "FLOCK DIVIDEND",
			"description": "Return part of the harvest to every employed hen.",
			"effect": "-$24.00  /  flock strain down  /  solidarity +10  /  quota -1",
			"cost_cents": 2400,
			"style_id": &"shared_scoop",
		},
		{
			"id": POLICY_HARVEST_FORECAST,
			"title": "EXECUTIVE HARVEST FORECAST",
			"description": "Book future confidence as present Feed Fund.",
			"effect": "+$24.00  /  favor +8  /  next quota +3  /  flock trust down",
			"cost_cents": 0,
			"style_id": &"management_innovation",
		},
	]
