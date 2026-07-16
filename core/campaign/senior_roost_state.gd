class_name SeniorRoostState
extends RefCounted

## Persistent post-probation career progression. Probation remains an immutable
## five-shift record; this model owns the recurring three-shift quarters that
## follow it and consumes only primitive workday report facts.

const SCHEMA_ID := "pecking_order.senior_roost"
const SCHEMA_VERSION := 3
const PREVIOUS_SCHEMA_VERSION := 2
const LEGACY_SCHEMA_VERSION := 1
const SHIFTS_PER_QUARTER := 3
const QUARTERS_PER_YEAR := 4
const SCORE_MAX := 100
const ROOST_MARK_THRESHOLDS: Array[int] = [45, 60, 80]
const MAX_ANNUAL_HISTORY := 8
const MAX_SPONSORSHIP_HISTORY := 64
const MAX_MANDATE_HISTORY := 256
const MAX_COUNTER := 2_000_000_000
const MAX_WORKER_NAME_LENGTH := 128

const MANDATE_SHIFTS_PER_YEAR := SHIFTS_PER_QUARTER * QUARTERS_PER_YEAR
const MANDATE_FALLBACK_ID: StringName = &"standard_board_book"
const MANDATE_OFFER_COUNT := 3
const MANDATE_TIER_ONE_SEALS := 1
const MANDATE_TIER_TWO_SEALS := 3
const MANDATE_TIER_THREE_SEALS := 6
const MANDATE_IDS: Array[StringName] = [
	MANDATE_FALLBACK_ID,
	&"shell_stewardship",
	&"flock_continuity",
	&"mutual_assurance",
	&"executive_harvest",
	&"rested_flock_covenant",
	&"gold_standard_book",
]

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
var annual_mandate_offer_context: Dictionary = {}
var annual_mandate_offers: Array[Dictionary] = []
var _active_annual_mandate: Dictionary = {}
var current_mandate_evidence: Array[Dictionary] = []
var mandate_history: Array[Dictionary] = []
var last_mandate_selection: Dictionary = {}
var last_mandate_settlement: Dictionary = {}
var mandate_success_counts: Dictionary = {
	MANDATE_FALLBACK_ID: 0,
	&"shell_stewardship": 0,
	&"flock_continuity": 0,
	&"mutual_assurance": 0,
	&"executive_harvest": 0,
	&"rested_flock_covenant": 0,
	&"gold_standard_book": 0,
}
var mandate_seals: int = 0
var mandate_marks_forfeited: int = 0
var next_mandate_settlement_id: int = 1
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
	_prepare_annual_mandate_offers(simulation_snapshot)
	return true


func requires_quarter_policy() -> bool:
	return (
		status == STATUS_QUARTER_CHOICE
		and active_policy_id == &""
		and not requires_annual_mandate()
	)


func is_active() -> bool:
	return status != STATUS_INACTIVE


func available_roost_marks() -> int:
	## Lifetime Roost Marks continue to drive promotion_title(). Spending is
	## tracked separately so a sponsorship can never demote the player.
	return maxi(
		0,
		roost_marks
		- roost_marks_spent
		- mandate_marks_forfeited
		- mandate_stake_reserved(),
	)


func requires_annual_mandate() -> bool:
	return (
		status == STATUS_QUARTER_CHOICE
		and current_year_quarters.is_empty()
		and current_quarter_shifts.is_empty()
		and active_policy_id == &""
		and _active_annual_mandate.is_empty()
		and annual_mandate_offers.size() == MANDATE_OFFER_COUNT
	)


func mandate_stake_reserved() -> int:
	if _active_annual_mandate.is_empty():
		return 0
	return maxi(0, int(_active_annual_mandate.get("stake_marks", 0)))


func eligible_mandate_tier() -> int:
	if mandate_seals >= MANDATE_TIER_THREE_SEALS:
		return 3
	if mandate_seals >= MANDATE_TIER_TWO_SEALS:
		return 2
	if mandate_seals >= MANDATE_TIER_ONE_SEALS:
		return 1
	return 0


func mandate_tier_eligibility() -> Dictionary:
	var tier := eligible_mandate_tier()
	var next_seals := (
		MANDATE_TIER_ONE_SEALS if tier == 0 else
		(MANDATE_TIER_TWO_SEALS if tier == 1 else
		(MANDATE_TIER_THREE_SEALS if tier == 2 else -1))
	)
	return {
		"eligible_tier": tier,
		"mandate_seals": mandate_seals,
		"next_tier_seals": next_seals,
		"seals_to_next_tier": maxi(0, next_seals - mandate_seals) if next_seals >= 0 else 0,
		"max_tier": 3,
	}


func annual_mandate_catalog() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	var selected_id := StringName(String(_active_annual_mandate.get("id", "")))
	for offer in annual_mandate_offers:
		var row := offer.duplicate(true)
		var stake := maxi(0, int(row.get("stake_marks", 0)))
		row["selected"] = StringName(String(row.get("id", ""))) == selected_id
		row["available"] = (
			row["selected"]
			or (_active_annual_mandate.is_empty() and stake <= available_roost_marks())
		)
		row["unavailable_reason"] = (
			"" if bool(row["available"]) else
			"%d more available Roost Mark%s required." % [
				stake - available_roost_marks(),
				" is" if stake - available_roost_marks() == 1 else "s are",
			]
		)
		catalog.append(row)
	return catalog


func active_annual_mandate() -> Dictionary:
	return _active_annual_mandate.duplicate(true)


func mandate_success_history() -> Array[Dictionary]:
	var successes: Array[Dictionary] = []
	for settlement in mandate_history:
		if bool(settlement.get("success", false)):
			successes.append(settlement.duplicate(true))
	return successes


func select_annual_mandate(
	mandate_id: StringName,
	expected_year: int = -1,
) -> Dictionary:
	var year := current_year_number()
	var reason_id := ""
	var reason := ""
	if not requires_annual_mandate():
		reason_id = "mandate_not_required"
		reason = "An annual Board Mandate is not awaiting selection."
	elif expected_year >= 0 and expected_year != year:
		reason_id = "stale_year"
		reason = "The Board Mandate offer belongs to a different Senior year."
	var offer: Dictionary = {}
	if reason_id.is_empty():
		for candidate in annual_mandate_offers:
			if StringName(String(candidate.get("id", ""))) == mandate_id:
				offer = candidate.duplicate(true)
				break
		if offer.is_empty():
			reason_id = "unsupported_offer"
			reason = "Select one of the three frozen annual Board Mandates."
	var stake := maxi(0, int(offer.get("stake_marks", 0)))
	if reason_id.is_empty() and stake > available_roost_marks():
		reason_id = "insufficient_roost_marks"
		reason = "%d more available Roost Mark%s required for this mandate stake." % [
			stake - available_roost_marks(),
			" is" if stake - available_roost_marks() == 1 else "s are",
		]
	if not reason_id.is_empty():
		return {
			"accepted": false,
			"action_id": "select_annual_board_mandate",
			"reason_id": reason_id,
			"reason": reason,
			"year": year,
			"mandate_id": String(mandate_id),
		}

	_active_annual_mandate = offer.duplicate(true)
	_active_annual_mandate["selected_year"] = year
	_active_annual_mandate["selected_at_completed_quarter"] = completed_quarters
	_active_annual_mandate["selected_at_lifetime_marks"] = roost_marks
	_active_annual_mandate["grandfathered"] = false
	last_mandate_selection = {
		"accepted": true,
		"action_id": "select_annual_board_mandate",
		"year": year,
		"mandate_id": String(mandate_id),
		"mandate_name": String(offer.get("name", "BOARD MANDATE")),
		"tier": int(offer.get("tier", 0)),
		"stake_marks": stake,
		"available_roost_marks_after": available_roost_marks(),
		"outcome": "%s filed for Senior Year %d." % [
			String(offer.get("name", "Board Mandate")),
			year,
		],
	}
	return last_mandate_selection.duplicate(true)


func current_annual_mandate_progress(live_metrics: Dictionary = {}) -> Dictionary:
	if _active_annual_mandate.is_empty():
		return {}
	var evidence: Array[Dictionary] = []
	for row in current_mandate_evidence:
		evidence.append(row.duplicate(true))
	if not live_metrics.is_empty() and evidence.size() < MANDATE_SHIFTS_PER_YEAR:
		evidence.append(_mandate_evidence_from_projection(live_metrics))
	return _mandate_progress(_active_annual_mandate, evidence)


static func marks_for_score(score: int) -> int:
	## One canonical boundary function owns both live reward projection and the
	## exact quarter-close award. Keeping the 45 / 60 / 80 gates here prevents
	## presentation copy from drifting away from the permanent career ledger.
	var bounded_score := clampi(score, 0, SCORE_MAX)
	if bounded_score >= ROOST_MARK_THRESHOLDS[2]:
		return 3
	if bounded_score >= ROOST_MARK_THRESHOLDS[1]:
		return 2
	if bounded_score >= ROOST_MARK_THRESHOLDS[0]:
		return 1
	return 0


static func next_mark_threshold_for_score(score: int) -> int:
	var bounded_score := clampi(score, 0, SCORE_MAX)
	for threshold in ROOST_MARK_THRESHOLDS:
		if bounded_score < threshold:
			return threshold
	return -1


func sponsorship_available_this_gate() -> bool:
	return (
		status in SPONSORSHIP_STATUSES
		and not requires_annual_mandate()
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
		"mandate_marks_forfeited_at_commit": mandate_marks_forfeited,
		"mandate_stake_reserved_at_commit": mandate_stake_reserved(),
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
	if (
		not requires_quarter_policy()
		or _active_annual_mandate.is_empty()
		or not bool(receipt.get("accepted", false))
	):
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
	current_mandate_evidence.append(_mandate_evidence_from_shift(record))
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


func continue_after_annual(simulation_snapshot: Dictionary = {}) -> bool:
	if status != STATUS_ANNUAL_REVIEW:
		return false
	status = STATUS_QUARTER_CHOICE
	_prepare_annual_mandate_offers(simulation_snapshot)
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
	var breakdown := score_breakdown(records, true)
	var aggregate := breakdown.get("aggregate", {}) as Dictionary
	var quota_met_shifts := int(aggregate.get("quota_met_shifts", 0))
	var crack_rate := int(aggregate.get("crack_rate_basis_points", 0))
	var projected_score := int(breakdown.get("score", 0))
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


func current_career_forecast(live_metrics: Dictionary = {}) -> Dictionary:
	## Presentation-only forecast built from the same pure score breakdown used
	## when the quarter closes. It never mutates or files a shift.
	if status != STATUS_ACTIVE or active_policy_id == &"":
		return {}
	var records: Array[Dictionary] = []
	for record in current_quarter_shifts:
		records.append(record.duplicate(true))
	var includes_live_shift := false
	if not live_metrics.is_empty() and records.size() < SHIFTS_PER_QUARTER:
		records.append(_projection_record(live_metrics))
		includes_live_shift = true
	if records.is_empty():
		return {}
	var breakdown := score_breakdown(records, true)
	var projected_score := int(breakdown.get("score", 0))
	var projected_marks := marks_for_score(projected_score)
	var next_threshold := next_mark_threshold_for_score(projected_score)
	return {
		"visible": true,
		"mode": "senior_roost",
		"basis": "if_filed_now",
		"year": current_year_number(),
		"quarter": current_quarter_in_year(),
		"projected_score": projected_score,
		"score_max": SCORE_MAX,
		"projected_marks": projected_marks,
		"next_mark_threshold": next_threshold,
		"points_to_next_mark": maxi(0, next_threshold - projected_score) if next_threshold >= 0 else 0,
		"closed_shifts": current_quarter_shifts.size(),
		"records_count": records.size(),
		"includes_live_shift": includes_live_shift,
		"components": (breakdown.get("components", []) as Array).duplicate(true),
		"largest_recoverable_component": (
			breakdown.get("largest_recoverable_component", {}) as Dictionary
		).duplicate(true),
	}


func snapshot() -> Dictionary:
	var mandate_progress := current_annual_mandate_progress()
	return {
		"status": String(status),
		"total_senior_shifts": total_senior_shifts,
		"completed_quarters": completed_quarters,
		"completed_years": completed_years,
		"successful_years": successful_years,
		"best_annual_score": best_annual_score,
		"roost_marks": roost_marks,
		"roost_marks_spent": roost_marks_spent,
		"mandate_marks_forfeited": mandate_marks_forfeited,
		"mandate_stake_reserved": mandate_stake_reserved(),
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
		"requires_annual_mandate": requires_annual_mandate(),
		"annual_mandate_offers": annual_mandate_catalog(),
		"active_annual_mandate": active_annual_mandate(),
		"annual_mandate_progress": mandate_progress,
		"mandate_seals": mandate_seals,
		"eligible_mandate_tier": eligible_mandate_tier(),
		"mandate_tier_eligibility": mandate_tier_eligibility(),
		"mandate_success_counts": mandate_success_counts.duplicate(true),
		"mandate_history": mandate_history.duplicate(true),
		"last_mandate_selection": last_mandate_selection.duplicate(true),
		"last_mandate_settlement": last_mandate_settlement.duplicate(true),
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
		"mandate_marks_forfeited": mandate_marks_forfeited,
		"mandate_seals": mandate_seals,
		"next_mandate_settlement_id": next_mandate_settlement_id,
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
		"annual_mandate_offer_context": annual_mandate_offer_context.duplicate(true),
		"annual_mandate_offers": annual_mandate_offers.duplicate(true),
		"active_annual_mandate": _active_annual_mandate.duplicate(true),
		"current_mandate_evidence": current_mandate_evidence.duplicate(true),
		"mandate_history": mandate_history.duplicate(true),
		"last_mandate_selection": last_mandate_selection.duplicate(true),
		"last_mandate_settlement": last_mandate_settlement.duplicate(true),
		"mandate_success_counts": _string_keyed_mandate_counts(),
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
		"last_recorded_day", "last_rework_total_created", "mandate_marks_forfeited",
		"mandate_seals", "next_mandate_settlement_id",
	]:
		if not _is_integer(data.get(key)) or int(data.get(key, -1)) < 0 or int(data.get(key, 0)) > MAX_COUNTER:
			errors.append("%s must be a nonnegative integer" % key)
	var active_policy := StringName(String(data.get("active_policy_id", "")))
	if active_policy != &"" and active_policy not in POLICY_IDS:
		errors.append("active_policy_id is not supported")
	for key in [
		"active_policy_receipt", "last_quarter_review", "last_annual_review",
		"last_shift_result", "choice_counts", "annual_mandate_offer_context",
		"active_annual_mandate", "last_mandate_selection",
		"last_mandate_settlement", "mandate_success_counts",
	]:
		if typeof(data.get(key)) != TYPE_DICTIONARY:
			errors.append("%s must be a Dictionary" % key)
	for key in [
		"current_quarter_shifts", "current_year_quarters", "annual_history",
		"sponsorship_history", "annual_mandate_offers",
		"current_mandate_evidence", "mandate_history",
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
	var mandate_forfeited := int(data.get("mandate_marks_forfeited", 0))
	if total_shifts != completed_quarter_count * SHIFTS_PER_QUARTER + quarter_shifts.size():
		errors.append("total_senior_shifts is inconsistent with quarter records")
	if completed_quarter_count != completed_year_count * QUARTERS_PER_YEAR + year_quarters.size():
		errors.append("completed_quarters is inconsistent with year records")
	if int(data.get("successful_years", 0)) > completed_year_count:
		errors.append("successful_years cannot exceed completed_years")
	if int(data.get("next_mandate_settlement_id", 0)) < 1:
		errors.append("next_mandate_settlement_id must be positive")
	if spent_marks + mandate_forfeited > lifetime_marks:
		errors.append("spent and forfeited Roost Marks cannot exceed lifetime roost_marks")
	_validate_saved_sponsorships(
		saved_sponsorships,
		completed_quarter_count,
		lifetime_marks,
		spent_marks,
		errors,
	)
	_validate_saved_mandates(data, status_id, errors)
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
			if (
				mandate_forfeited != 0
				or int(data.get("mandate_seals", 0)) != 0
				or not (data.get("annual_mandate_offers", []) as Array).is_empty()
				or not (data.get("active_annual_mandate", {}) as Dictionary).is_empty()
			):
				errors.append("inactive Senior Roost state cannot contain Board Mandate progress")
		STATUS_QUARTER_CHOICE:
			if active_policy != &"" or not quarter_shifts.is_empty():
				errors.append("quarter_choice requires an empty upcoming quarter")
		STATUS_ACTIVE:
			if active_policy == &"":
				errors.append("active Senior Roost state requires a policy")
			if (data.get("active_annual_mandate", {}) as Dictionary).is_empty():
				errors.append("active Senior Roost state requires an annual Board Mandate")
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
	review["annual_mandate_checkpoint"] = current_annual_mandate_progress()
	var score := int(review.get("score", 0))
	var marks_awarded := marks_for_score(score)
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
		var mandate_settlement := _settle_annual_mandate(completed_years)
		annual["mandate_settlement"] = mandate_settlement.duplicate(true)
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
	return int(score_breakdown(records, normalize_quota).get("score", 0))


func score_breakdown(records: Array[Dictionary], normalize_quota: bool) -> Dictionary:
	## Pure, detailed scoring authority. This method reads no career counters and
	## mutates neither records nor state, so live projection and quarter filing can
	## safely consume the exact same component facts.
	if records.is_empty():
		return {
			"score": 0,
			"score_max": SCORE_MAX,
			"components": [],
			"largest_recoverable_component": {},
			"aggregate": {},
		}
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
	var closing_arrears := int(aggregate.get("closing_wage_arrears_cents", 0))
	var solvency_points := 5 if closing_arrears == 0 else 0

	var components: Array[Dictionary] = [
		_score_component(
			"quota_reliability",
			"QUOTA RELIABILITY",
			quota_points,
			30,
			"%d of %d filed or projected shifts currently meet quota." % [
				met_shifts,
				records.size(),
			],
			met_shifts,
			SHIFTS_PER_QUARTER,
			"minimum",
		),
		_score_component(
			"shell_integrity",
			"SHELL INTEGRITY",
			quality_points,
			20,
			"Quarter crack rate is %.1f%%; 15%% earns full credit and 25%% retains partial credit." % (
				float(crack_rate) / 100.0
			),
			crack_rate,
			1500,
			"maximum",
		),
		_score_component(
			"queue_control",
			"QUEUE CONTROL",
			queue_points,
			10,
			"%d overdue files are recorded; 3 or fewer earns full credit and 6 or fewer retains partial credit." % overdue,
			overdue,
			3,
			"maximum",
		),
		_score_component(
			"flock_welfare",
			"FLOCK WELFARE",
			welfare_points,
			15,
			"Average welfare is %d%%; 60%% earns full credit and 45%% retains partial credit." % welfare,
			welfare,
			60,
			"minimum",
		),
		_score_component(
			"coop_obedience",
			"COOP OBEDIENCE",
			compliance_points,
			10,
			"Average obedience is %d%%; 70%% earns full credit and 55%% retains partial credit." % compliance,
			compliance,
			70,
			"minimum",
		),
		_score_component(
			"farmer_favor",
			"FARMER FAVOR",
			favor_points,
			10,
			"Average farmer favor is %d%%; 60%% earns full credit and 50%% retains partial credit." % favor,
			favor,
			60,
			"minimum",
		),
		_score_component(
			"solvency",
			"SOLVENCY",
			solvency_points,
			5,
			(
				"No wage arrears are recorded."
				if closing_arrears == 0 else
				"$%.2f in wage arrears removes the solvency credit." % (float(closing_arrears) / 100.0)
			),
			closing_arrears,
			0,
			"maximum",
		),
	]
	var total_score := 0
	var largest_recoverable: Dictionary = {}
	var largest_loss := 0
	for component in components:
		total_score += int(component.get("score", 0))
		var recoverable := int(component.get("recoverable_points", 0))
		# Strictly-greater replacement preserves the authored component order for
		# ties, making the recommended bottleneck deterministic.
		if recoverable > largest_loss:
			largest_loss = recoverable
			largest_recoverable = component.duplicate(true)
	return {
		"score": clampi(total_score, 0, SCORE_MAX),
		"score_max": SCORE_MAX,
		"components": components,
		"largest_recoverable_component": largest_recoverable,
		"aggregate": aggregate.duplicate(true),
	}


func _score_component(
	id: String,
	label: String,
	score: int,
	max_score: int,
	cause: String,
	actual: int,
	target: int,
	comparison: String,
) -> Dictionary:
	var bounded_score := clampi(score, 0, max_score)
	var recoverable := maxi(0, max_score - bounded_score)
	return {
		"id": id,
		"label": label,
		"score": bounded_score,
		"max_score": max_score,
		"recoverable_points": recoverable,
		"cause": cause,
		"actual": actual,
		"target": target,
		"comparison": comparison,
		"status": "full" if recoverable == 0 else ("partial" if bounded_score > 0 else "lost"),
	}


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


func _prepare_annual_mandate_offers(simulation_snapshot: Dictionary) -> void:
	var frozen_snapshot := simulation_snapshot.duplicate(true)
	if not frozen_snapshot.has("day"):
		frozen_snapshot["day"] = last_recorded_day + 1
	annual_mandate_offer_context = _mandate_offer_context(
		current_year_number(),
		frozen_snapshot,
		mandate_seals,
		available_roost_marks(),
	)
	annual_mandate_offers.assign(
		_build_mandate_offers(annual_mandate_offer_context)
	)
	_active_annual_mandate.clear()
	current_mandate_evidence.clear()
	last_mandate_selection.clear()


static func _mandate_offer_context(
	year: int,
	simulation_snapshot: Dictionary,
	seal_count: int,
	available_marks: int,
) -> Dictionary:
	return {
		"year": maxi(1, year),
		"opening_day": maxi(1, int(simulation_snapshot.get("day", 1))),
		"opening_fund_cents": maxi(0, int(simulation_snapshot.get(
			"revenue_cents",
			simulation_snapshot.get("closing_fund_cents", 0),
		))),
		"opening_quota": maxi(1, int(simulation_snapshot.get(
			"quota_target",
			simulation_snapshot.get("quota", 1),
		))),
		"seal_count": maxi(0, seal_count),
		"available_marks": maxi(0, available_marks),
		"eligible_tier": _eligible_mandate_tier_for_seals(seal_count),
	}


static func _eligible_mandate_tier_for_seals(seal_count: int) -> int:
	if seal_count >= MANDATE_TIER_THREE_SEALS:
		return 3
	if seal_count >= MANDATE_TIER_TWO_SEALS:
		return 2
	if seal_count >= MANDATE_TIER_ONE_SEALS:
		return 1
	return 0


static func _build_mandate_offers(context: Dictionary) -> Array[Dictionary]:
	var year := maxi(1, int(context.get("year", 1)))
	var eligible_tier := clampi(int(context.get("eligible_tier", 0)), 0, 3)
	var available_marks := maxi(0, int(context.get("available_marks", 0)))
	var definitions := _annual_mandate_definitions(context)
	var fallback: Dictionary = {}
	var eligible: Array[Dictionary] = []
	for definition in definitions:
		var id := StringName(String(definition.get("id", "")))
		if id == MANDATE_FALLBACK_ID:
			fallback = definition.duplicate(true)
			continue
		if (
			int(definition.get("tier", 0)) <= eligible_tier
			and int(definition.get("stake_marks", 0)) <= available_marks
		):
			eligible.append(definition.duplicate(true))
	# The two tier-zero alternatives guarantee a complete catalog even before
	# the player owns a single seal or available Roost Mark.
	if fallback.is_empty() or eligible.size() < MANDATE_OFFER_COUNT - 1:
		return []
	var rotation_seed := (
		year
		+ int(context.get("opening_day", 1))
		+ int(context.get("seal_count", 0))
	)
	var result: Array[Dictionary] = [_freeze_mandate_offer(fallback, context)]
	var selected: Array[Dictionary] = []
	var highest_available_tier := 0
	for candidate in eligible:
		highest_available_tier = maxi(
			highest_available_tier,
			int(candidate.get("tier", 0)),
		)
	if highest_available_tier > 0:
		var hardest: Array[Dictionary] = []
		for candidate in eligible:
			if int(candidate.get("tier", 0)) == highest_available_tier:
				hardest.append(candidate)
		selected.append(hardest[rotation_seed % hardest.size()])
	var remaining: Array[Dictionary] = []
	var selected_id := String(selected[0].get("id", "")) if not selected.is_empty() else ""
	for candidate in eligible:
		if String(candidate.get("id", "")) != selected_id:
			remaining.append(candidate)
	var rotation := rotation_seed % remaining.size()
	for offset in remaining.size():
		if selected.size() >= MANDATE_OFFER_COUNT - 1:
			break
		selected.append(remaining[(rotation + offset) % remaining.size()])
	for candidate in selected:
		result.append(_freeze_mandate_offer(candidate, context))
	return result


static func _freeze_mandate_offer(definition: Dictionary, context: Dictionary) -> Dictionary:
	return {
		"id": String(definition.get("id", "")),
		"name": String(definition.get("name", "ANNUAL BOARD MANDATE")),
		"summary": String(definition.get("summary", "")),
		"tier": int(definition.get("tier", 0)),
		"stake_marks": int(definition.get("stake_marks", 0)),
		"seal_reward": int(definition.get("seal_reward", 1)),
		"offer_year": int(context.get("year", 1)),
		"context_opening_day": int(context.get("opening_day", 1)),
		"objectives": (definition.get("objectives", []) as Array).duplicate(true),
		"reward": String(definition.get("reward", "Successful filing earns one permanent Board Seal.")),
		"failure": String(definition.get("failure", "Failure closes the book without a seal.")),
	}


static func _annual_mandate_definitions(context: Dictionary) -> Array[Dictionary]:
	var opening_quota := maxi(1, int(context.get("opening_quota", 1)))
	var opening_fund := maxi(0, int(context.get("opening_fund_cents", 0)))
	var harvest_target := maxi(60_000, opening_quota * MANDATE_SHIFTS_PER_YEAR * 350)
	return [
		{
			"id": String(MANDATE_FALLBACK_ID),
			"name": "STANDARD BOARD BOOK",
			"summary": "Keep the year solvent and broadly serviceable without staking career marks.",
			"tier": 0,
			"stake_marks": 0,
			"seal_reward": 1,
			"objectives": [
				_mandate_objective("quota_met_shifts", "RELIABLE CLUTCH", "minimum", 6),
				_mandate_objective("welfare_average", "FLOCK CONTINUITY", "minimum", 45),
				_mandate_objective("wage_arrears_shifts", "CURRENT PAYROLL", "maximum", 0),
			],
			"reward": "Earn 1 permanent Board Seal with no Roost Marks at risk.",
			"failure": "No seal is awarded; no Roost Marks are forfeited.",
		},
		{
			"id": "shell_stewardship",
			"name": "SHELL STEWARDSHIP BOOK",
			"summary": "Protect quality while proving that assurance can still meet the farmer's calendar.",
			"tier": 0,
			"stake_marks": 0,
			"seal_reward": 1,
			"objectives": [
				_mandate_objective("crack_rate_basis_points", "SHELL LOSS", "maximum", 2200),
				_mandate_objective("compliance_average", "AUDIT POSTURE", "minimum", 58),
				_mandate_objective("quota_met_shifts", "SERVICE DAYS", "minimum", 7),
			],
			"reward": "Earn 1 permanent Board Seal.",
			"failure": "No seal is awarded.",
		},
		{
			"id": "flock_continuity",
			"name": "FLOCK CONTINUITY ACCORD",
			"summary": "Keep the flock, farmer, and payroll intact for one full Senior year.",
			"tier": 0,
			"stake_marks": 0,
			"seal_reward": 1,
			"objectives": [
				_mandate_objective("welfare_average", "RESTED FLOCK", "minimum", 56),
				_mandate_objective("farmer_favor_average", "FARMER FAVOR", "minimum", 48),
				_mandate_objective("wage_arrears_shifts", "PAID SHIFTS", "maximum", 0),
			],
			"reward": "Earn 1 permanent Board Seal.",
			"failure": "No seal is awarded.",
		},
		{
			"id": "mutual_assurance",
			"name": "MUTUAL ASSURANCE GUARANTEE",
			"summary": "Stake two marks on a tighter quality, quota, and obedience covenant.",
			"tier": 1,
			"stake_marks": 2,
			"seal_reward": 2,
			"objectives": [
				_mandate_objective("quota_met_shifts", "GUARANTEED SERVICE", "minimum", 9),
				_mandate_objective("crack_rate_basis_points", "GUARANTEED SHELLS", "maximum", 1800),
				_mandate_objective("compliance_average", "GUARANTEED ORDER", "minimum", 65),
			],
			"reward": "Return the 2-mark stake and earn 2 permanent Board Seals.",
			"failure": "The 2-mark stake becomes permanently spent.",
		},
		{
			"id": "executive_harvest",
			"name": "EXECUTIVE HARVEST COMMITMENT",
			"summary": "Stake two marks on credited growth without shrinking the opening Feed Fund.",
			"tier": 1,
			"stake_marks": 2,
			"seal_reward": 2,
			"objectives": [
				_mandate_objective("credited_cents", "CREDITED HARVEST", "minimum", harvest_target),
				_mandate_objective("closing_fund_cents", "FEED FUND FLOOR", "minimum", opening_fund),
				_mandate_objective("farmer_favor_average", "EXECUTIVE FAVOR", "minimum", 55),
			],
			"reward": "Return the 2-mark stake and earn 2 permanent Board Seals.",
			"failure": "The 2-mark stake becomes permanently spent.",
		},
		{
			"id": "rested_flock_covenant",
			"name": "RESTED FLOCK COVENANT",
			"summary": "Stake four marks on a high-care year with disciplined shells and payroll.",
			"tier": 2,
			"stake_marks": 4,
			"seal_reward": 3,
			"objectives": [
				_mandate_objective("welfare_average", "RESTED FLOCK", "minimum", 64),
				_mandate_objective("crack_rate_basis_points", "CAREFUL SHELLS", "maximum", 1600),
				_mandate_objective("compliance_average", "FILED CARE", "minimum", 68),
				_mandate_objective("wage_arrears_shifts", "CURRENT PAYROLL", "maximum", 0),
			],
			"reward": "Return the 4-mark stake and earn 3 permanent Board Seals.",
			"failure": "The 4-mark stake becomes permanently spent.",
		},
		{
			"id": "gold_standard_book",
			"name": "GOLD STANDARD BOOK",
			"summary": "Stake six marks on a perfect service year with executive safeguards.",
			"tier": 3,
			"stake_marks": 6,
			"seal_reward": 4,
			"objectives": [
				_mandate_objective("quota_met_shifts", "PERFECT SERVICE", "minimum", 12),
				_mandate_objective("crack_rate_basis_points", "GOLD SHELLS", "maximum", 1200),
				_mandate_objective("welfare_average", "SUSTAINED FLOCK", "minimum", 68),
				_mandate_objective("compliance_average", "GOLD AUDIT", "minimum", 75),
				_mandate_objective("closing_fund_cents", "CAPITAL FLOOR", "minimum", opening_fund),
			],
			"reward": "Return the 6-mark stake and earn 4 permanent Board Seals.",
			"failure": "The 6-mark stake becomes permanently spent.",
		},
	]


static func _mandate_definition_for_id(mandate_id: StringName) -> Dictionary:
	for definition in _annual_mandate_definitions({}):
		if StringName(String(definition.get("id", ""))) == mandate_id:
			return definition
	return {}


static func _mandate_objective(
	metric: String,
	label: String,
	comparison: String,
	target: int,
) -> Dictionary:
	return {
		"metric": metric,
		"label": label,
		"comparison": comparison,
		"target": target,
	}


static func _mandate_evidence_from_shift(record: Dictionary) -> Dictionary:
	return {
		"day": int(record.get("day", 0)),
		"met_quota": bool(record.get("met_quota", false)),
		"eggs": maxi(0, int(record.get("eggs", 0))),
		"cracked": maxi(0, int(record.get("cracked", 0))),
		"credited_cents": maxi(0, int(record.get("credited_cents", 0))),
		"welfare": clampi(int(record.get("welfare", 0)), 0, 100),
		"compliance": clampi(int(record.get("compliance", 0)), 0, 100),
		"farmer_favor": clampi(int(record.get("farmer_favor", 0)), 0, 100),
		"wage_arrears_cents": maxi(0, int(record.get("wage_arrears_cents", 0))),
		"closing_fund_cents": maxi(0, int(record.get("closing_fund_cents", 0))),
	}


func _mandate_evidence_from_projection(live: Dictionary) -> Dictionary:
	return _mandate_evidence_from_shift(_projection_record(live))


static func _mandate_progress(
	mandate: Dictionary,
	evidence: Array[Dictionary],
) -> Dictionary:
	var aggregate := _aggregate_mandate_evidence(evidence)
	var rows: Array[Dictionary] = []
	var all_met := true
	var objectives_met := 0
	var largest_blocker: Dictionary = {}
	var largest_recoverable := -1
	var next_threshold: Dictionary = {}
	for objective_value in mandate.get("objectives", []) as Array:
		if not objective_value is Dictionary:
			continue
		var objective := objective_value as Dictionary
		var metric := String(objective.get("metric", ""))
		var comparison := String(objective.get("comparison", "minimum"))
		var target := int(objective.get("target", 0))
		var actual := int(aggregate.get(metric, 0))
		var met := actual >= target if comparison == "minimum" else actual <= target
		var progress_basis_points := 10_000
		if not met:
			if comparison == "minimum":
				progress_basis_points = clampi(
					roundi(float(actual) / float(maxi(1, target)) * 10_000.0),
					0,
					10_000,
				)
			else:
				progress_basis_points = (
					0 if target <= 0 else
					clampi(roundi(float(target) / float(maxi(1, actual)) * 10_000.0), 0, 10_000)
				)
		var gap := maxi(0, target - actual) if comparison == "minimum" else maxi(0, actual - target)
		var row := {
			"metric": metric,
			"label": String(objective.get("label", metric.to_upper())),
			"comparison": comparison,
			"actual": actual,
			"target": target,
			"gap": gap,
			"met": met,
			"status": "met" if met else "needs_action",
			"progress_basis_points": progress_basis_points,
			"recoverable_basis_points": 10_000 - progress_basis_points,
		}
		rows.append(row)
		if met:
			objectives_met += 1
		if not met:
			all_met = false
			if next_threshold.is_empty():
				next_threshold = row.duplicate(true)
			var recoverable := int(row["recoverable_basis_points"])
			if recoverable > largest_recoverable:
				largest_recoverable = recoverable
				largest_blocker = row.duplicate(true)
	var shifts_recorded := evidence.size()
	return {
		"visible": true,
		"mandate_id": String(mandate.get("id", "")),
		"mandate_name": String(mandate.get("name", "ANNUAL BOARD MANDATE")),
		"year": int(mandate.get("selected_year", mandate.get("offer_year", 1))),
		"tier": int(mandate.get("tier", 0)),
		"stake_marks": int(mandate.get("stake_marks", 0)),
		"shifts_recorded": shifts_recorded,
		"shifts_target": MANDATE_SHIFTS_PER_YEAR,
		"quarter_checkpoints_filed": shifts_recorded / SHIFTS_PER_QUARTER,
		"objectives_met": objectives_met,
		"objectives_total": rows.size(),
		"objectives": rows,
		"aggregate": aggregate,
		"next_threshold": next_threshold,
		"largest_recoverable_blocker": largest_blocker,
		"all_targets_met": all_met,
		"complete": shifts_recorded == MANDATE_SHIFTS_PER_YEAR,
		"success": shifts_recorded == MANDATE_SHIFTS_PER_YEAR and all_met,
		"grandfathered": bool(mandate.get("grandfathered", false)),
	}


static func _aggregate_mandate_evidence(evidence: Array[Dictionary]) -> Dictionary:
	var quota_met := 0
	var eggs := 0
	var cracked := 0
	var credited := 0
	var welfare := 0
	var compliance := 0
	var favor := 0
	var arrears_shifts := 0
	var closing_fund := 0
	for row in evidence:
		quota_met += 1 if bool(row.get("met_quota", false)) else 0
		eggs += maxi(0, int(row.get("eggs", 0)))
		cracked += maxi(0, int(row.get("cracked", 0)))
		credited += maxi(0, int(row.get("credited_cents", 0)))
		welfare += clampi(int(row.get("welfare", 0)), 0, 100)
		compliance += clampi(int(row.get("compliance", 0)), 0, 100)
		favor += clampi(int(row.get("farmer_favor", 0)), 0, 100)
		arrears_shifts += 1 if int(row.get("wage_arrears_cents", 0)) > 0 else 0
		closing_fund = maxi(0, int(row.get("closing_fund_cents", 0)))
	var count := maxi(1, evidence.size())
	return {
		"quota_met_shifts": quota_met,
		"eggs": eggs,
		"cracked": cracked,
		"crack_rate_basis_points": _basis_points(cracked, eggs),
		"credited_cents": credited,
		"welfare_average": roundi(float(welfare) / float(count)),
		"compliance_average": roundi(float(compliance) / float(count)),
		"farmer_favor_average": roundi(float(favor) / float(count)),
		"wage_arrears_shifts": arrears_shifts,
		"closing_fund_cents": closing_fund,
	}


func _settle_annual_mandate(year: int) -> Dictionary:
	if _active_annual_mandate.is_empty():
		return {}
	var mandate := _active_annual_mandate.duplicate(true)
	var progress := _mandate_progress(mandate, current_mandate_evidence)
	var grandfathered := bool(mandate.get("grandfathered", false))
	var success := bool(progress.get("success", false)) and not grandfathered
	var stake := maxi(0, int(mandate.get("stake_marks", 0)))
	var available_before := available_roost_marks()
	var seal_reward := int(mandate.get("seal_reward", 1)) if success else 0
	if success:
		mandate_seals += seal_reward
		var id := StringName(String(mandate.get("id", "")))
		mandate_success_counts[id] = int(mandate_success_counts.get(id, 0)) + 1
	elif not grandfathered:
		mandate_marks_forfeited += stake

	_active_annual_mandate.clear()
	current_mandate_evidence.clear()
	var settlement := {
		"settlement_id": next_mandate_settlement_id,
		"year": year,
		"mandate_id": String(mandate.get("id", "")),
		"mandate_name": String(mandate.get("name", "ANNUAL BOARD MANDATE")),
		"tier": int(mandate.get("tier", 0)),
		"success": success,
		"grandfathered": grandfathered,
		"stake_marks": stake,
		"stake_returned": stake if success else 0,
		"stake_forfeited": stake if not success and not grandfathered else 0,
		"seal_reward": seal_reward,
		"mandate_seals_after": mandate_seals,
		"mandate_marks_forfeited_after": mandate_marks_forfeited,
		"available_roost_marks_before": available_before,
		"available_roost_marks_after": available_roost_marks(),
		"progress": progress,
		"outcome": (
			"Legacy Senior year preserved without a Board Mandate settlement."
			if grandfathered else
			("Annual Board Mandate fulfilled; the stake returned and the seal was filed."
			if success else
			"Annual Board Mandate failed; its staked Roost Marks are permanently spent.")
		),
	}
	next_mandate_settlement_id += 1
	last_mandate_settlement = settlement.duplicate(true)
	mandate_history.append(settlement.duplicate(true))
	if mandate_history.size() > MAX_MANDATE_HISTORY:
		mandate_history.pop_front()
	return settlement


func _string_keyed_mandate_counts() -> Dictionary:
	var result: Dictionary = {}
	for mandate_id in MANDATE_IDS:
		result[String(mandate_id)] = int(mandate_success_counts.get(mandate_id, 0))
	return result


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
		migrated["schema_version"] = PREVIOUS_SCHEMA_VERSION
		source_version = PREVIOUS_SCHEMA_VERSION
	if source_version == PREVIOUS_SCHEMA_VERSION:
		_migrate_v2_board_mandates(migrated)
		migrated["schema_version"] = SCHEMA_VERSION
	return migrated


static func _migrate_v2_board_mandates(migrated: Dictionary) -> void:
	var status_id := StringName(String(migrated.get("status", "")))
	var completed_year_count := maxi(0, int(migrated.get("completed_years", 0)))
	var year := maxi(
		1,
		completed_year_count if status_id == STATUS_ANNUAL_REVIEW else completed_year_count + 1,
	)
	var saved_records := _legacy_current_year_records(migrated)
	var context_snapshot := _legacy_offer_snapshot(migrated, saved_records)
	var lifetime_marks := maxi(0, int(migrated.get("roost_marks", 0)))
	var sponsorship_spent := maxi(0, int(migrated.get("roost_marks_spent", 0)))
	var context := _mandate_offer_context(
		year,
		context_snapshot,
		0,
		maxi(0, lifetime_marks - sponsorship_spent),
	)
	var offers := _build_mandate_offers(context)
	var evidence: Array[Dictionary] = []
	for record in saved_records:
		evidence.append(_mandate_evidence_from_shift(record))
	var active: Dictionary = {}
	var progress_started := (
		status_id in [STATUS_ACTIVE, STATUS_QUARTER_CHOICE]
		and (
			not saved_records.is_empty()
			or not String(migrated.get("active_policy_id", "")).is_empty()
		)
	)
	if progress_started and not offers.is_empty():
		active = offers[0].duplicate(true)
		active["selected_year"] = year
		active["selected_at_completed_quarter"] = int(migrated.get("completed_quarters", 0)) - int((migrated.get("current_year_quarters", []) as Array).size())
		active["selected_at_lifetime_marks"] = lifetime_marks
		active["grandfathered"] = true

	migrated["mandate_marks_forfeited"] = 0
	migrated["mandate_seals"] = 0
	migrated["next_mandate_settlement_id"] = 1
	migrated["annual_mandate_offer_context"] = {} if status_id == STATUS_INACTIVE else context
	migrated["annual_mandate_offers"] = [] if status_id == STATUS_INACTIVE else offers
	migrated["active_annual_mandate"] = active
	migrated["current_mandate_evidence"] = evidence if not active.is_empty() else []
	migrated["mandate_history"] = []
	migrated["last_mandate_selection"] = {}
	migrated["last_mandate_settlement"] = {}
	var counts: Dictionary = {}
	for mandate_id in MANDATE_IDS:
		counts[String(mandate_id)] = 0
	migrated["mandate_success_counts"] = counts


static func _legacy_current_year_records(data: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quarter_value in data.get("current_year_quarters", []) as Array:
		if not quarter_value is Dictionary:
			continue
		for record_value in (quarter_value as Dictionary).get("records", []) as Array:
			if record_value is Dictionary:
				result.append((record_value as Dictionary).duplicate(true))
	for record_value in data.get("current_quarter_shifts", []) as Array:
		if record_value is Dictionary:
			result.append((record_value as Dictionary).duplicate(true))
	return result


static func _legacy_offer_snapshot(data: Dictionary, records: Array[Dictionary]) -> Dictionary:
	var last_day := maxi(0, int(data.get("last_recorded_day", 0)))
	var opening_day := maxi(1, last_day - records.size() + 1)
	var opening_fund := 0
	var opening_quota := 1
	if not records.is_empty():
		opening_fund = maxi(0, int(records[0].get("closing_fund_cents", 0)))
		opening_quota = maxi(1, int(records[0].get("quota", 1)))
	return {
		"day": opening_day,
		"revenue_cents": opening_fund,
		"quota_target": opening_quota,
	}


func _hydrate_unchecked(data: Dictionary) -> void:
	status = StringName(String(data["status"]))
	total_senior_shifts = int(data["total_senior_shifts"])
	completed_quarters = int(data["completed_quarters"])
	completed_years = int(data["completed_years"])
	successful_years = int(data["successful_years"])
	best_annual_score = int(data["best_annual_score"])
	roost_marks = int(data["roost_marks"])
	roost_marks_spent = int(data["roost_marks_spent"])
	mandate_marks_forfeited = int(data["mandate_marks_forfeited"])
	mandate_seals = int(data["mandate_seals"])
	next_mandate_settlement_id = int(data["next_mandate_settlement_id"])
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
	annual_mandate_offer_context = _restore_json_numbers(data["annual_mandate_offer_context"]) as Dictionary
	annual_mandate_offers.assign(_restore_json_numbers(data["annual_mandate_offers"]) as Array)
	_active_annual_mandate = _restore_json_numbers(data["active_annual_mandate"]) as Dictionary
	current_mandate_evidence.assign(_restore_json_numbers(data["current_mandate_evidence"]) as Array)
	mandate_history.assign(_restore_json_numbers(data["mandate_history"]) as Array)
	last_mandate_selection = _restore_json_numbers(data["last_mandate_selection"]) as Dictionary
	last_mandate_settlement = _restore_json_numbers(data["last_mandate_settlement"]) as Dictionary
	var saved_mandate_counts := data["mandate_success_counts"] as Dictionary
	for mandate_id in MANDATE_IDS:
		mandate_success_counts[mandate_id] = int(saved_mandate_counts.get(String(mandate_id), 0))
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
		var forfeited_at_commit := int(record.get("mandate_marks_forfeited_at_commit", 0))
		var stake_at_commit := int(record.get("mandate_stake_reserved_at_commit", 0))
		var expected_available := lifetime_at_commit - spent_after - forfeited_at_commit - stake_at_commit
		if available_after != expected_available:
			errors.append("sponsorship_history[%d].available_roost_marks_after is inconsistent" % index)


static func _validate_saved_mandates(
	data: Dictionary,
	status_id: StringName,
	errors: PackedStringArray,
) -> void:
	var context := data.get("annual_mandate_offer_context", {}) as Dictionary
	var offers := data.get("annual_mandate_offers", []) as Array
	var active := data.get("active_annual_mandate", {}) as Dictionary
	var evidence := data.get("current_mandate_evidence", []) as Array
	var history := data.get("mandate_history", []) as Array
	var counts := data.get("mandate_success_counts", {}) as Dictionary
	var lifetime_marks := int(data.get("roost_marks", 0))
	var sponsorship_spent := int(data.get("roost_marks_spent", 0))
	var forfeited_marks := int(data.get("mandate_marks_forfeited", 0))
	var seals := int(data.get("mandate_seals", 0))

	if counts.size() != MANDATE_IDS.size():
		errors.append("mandate_success_counts must contain every supported mandate exactly once")
	var expected_seals_from_counts := 0
	var total_mandate_successes := 0
	for mandate_id in MANDATE_IDS:
		var value: Variant = counts.get(String(mandate_id))
		if not _is_integer(value) or int(value) < 0:
			errors.append("mandate_success_counts.%s must be a nonnegative integer" % String(mandate_id))
			continue
		var success_count := int(value)
		total_mandate_successes += success_count
		var definition := _mandate_definition_for_id(mandate_id)
		expected_seals_from_counts += success_count * int(definition.get("seal_reward", 0))
	if seals != expected_seals_from_counts:
		errors.append("mandate_seals is inconsistent with mandate_success_counts")
	if total_mandate_successes > int(data.get("completed_years", 0)):
		errors.append("mandate_success_counts cannot exceed completed Senior years")

	if status_id == STATUS_INACTIVE:
		if (
			not context.is_empty()
			or not offers.is_empty()
			or not active.is_empty()
			or not evidence.is_empty()
			or not history.is_empty()
			or not (data.get("last_mandate_selection", {}) as Dictionary).is_empty()
			or not (data.get("last_mandate_settlement", {}) as Dictionary).is_empty()
			or int(data.get("next_mandate_settlement_id", 0)) != 1
		):
			errors.append("inactive Senior Roost state must not contain Board Mandate state")
		return

	var context_keys: Array[String] = [
		"year", "opening_day", "opening_fund_cents", "opening_quota",
		"seal_count", "available_marks", "eligible_tier",
	]
	if not _has_exact_string_keys(context, context_keys):
		errors.append("annual_mandate_offer_context has unsupported or missing fields")
	else:
		for key in context_keys:
			if not _is_integer(context.get(key)) or int(context.get(key, -1)) < 0:
				errors.append("annual_mandate_offer_context.%s must be a nonnegative integer" % key)
		if int(context.get("year", 0)) < 1 or int(context.get("opening_day", 0)) < 1:
			errors.append("annual_mandate_offer_context year and opening_day must be positive")
		if int(context.get("opening_quota", 0)) < 1:
			errors.append("annual_mandate_offer_context.opening_quota must be positive")
		if int(context.get("eligible_tier", -1)) != _eligible_mandate_tier_for_seals(int(context.get("seal_count", 0))):
			errors.append("annual_mandate_offer_context.eligible_tier is inconsistent with its frozen seals")
		var expected_context_year := (
			int(data.get("completed_years", 0))
			if status_id == STATUS_ANNUAL_REVIEW else
			int(data.get("completed_years", 0)) + 1
		)
		if int(context.get("year", 0)) != expected_context_year:
			errors.append("annual_mandate_offer_context.year is stale")
		var expected_frozen_seals := seals
		if status_id == STATUS_ANNUAL_REVIEW and not history.is_empty() and history.back() is Dictionary:
			expected_frozen_seals -= maxi(0, int((history.back() as Dictionary).get("seal_reward", 0)))
		if int(context.get("seal_count", -1)) != maxi(0, expected_frozen_seals):
			errors.append("annual_mandate_offer_context.seal_count is stale")
		if int(context.get("available_marks", 0)) > lifetime_marks:
			errors.append("annual_mandate_offer_context.available_marks cannot exceed lifetime Roost Marks")

	if offers.size() != MANDATE_OFFER_COUNT:
		errors.append("annual_mandate_offers must contain exactly three frozen offers")
	elif not context.is_empty():
		var expected_offers := _build_mandate_offers(context)
		var normalized_offers := _restore_json_numbers(offers) as Array
		if expected_offers.size() != MANDATE_OFFER_COUNT or normalized_offers != expected_offers:
			errors.append("annual_mandate_offers are inconsistent with their frozen context")
		elif StringName(String((offers[0] as Dictionary).get("id", ""))) != MANDATE_FALLBACK_ID:
			errors.append("annual_mandate_offers must begin with the universal Standard Board Book")

	var saved_records := _legacy_current_year_records(data)
	if evidence.size() > MANDATE_SHIFTS_PER_YEAR:
		errors.append("current_mandate_evidence cannot exceed twelve Senior shifts")
	if active.is_empty():
		if not evidence.is_empty():
			errors.append("current_mandate_evidence requires an active annual mandate")
		if (
			status_id in [STATUS_ACTIVE, STATUS_QUARTER_CHOICE]
			and not saved_records.is_empty()
		):
			errors.append("an in-progress Senior year requires an active annual mandate")
	else:
		_validate_active_mandate(active, offers, data, errors)
		if status_id == STATUS_ANNUAL_REVIEW:
			errors.append("annual_review cannot retain an active annual mandate")
		if evidence.size() != saved_records.size():
			errors.append("current_mandate_evidence count is inconsistent with current-year shifts")
		for index in mini(evidence.size(), saved_records.size()):
			var evidence_value: Variant = evidence[index]
			if not evidence_value is Dictionary:
				errors.append("current_mandate_evidence[%d] must be a Dictionary" % index)
				continue
			var row := _restore_json_numbers(evidence_value) as Dictionary
			_validate_mandate_evidence(row, index, errors)
			if row != _mandate_evidence_from_shift(saved_records[index]):
				errors.append("current_mandate_evidence[%d] is inconsistent with its Senior shift" % index)
	_validate_last_mandate_selection(data, active, history, errors)

	var reserved := maxi(0, int(active.get("stake_marks", 0))) if not active.is_empty() else 0
	if sponsorship_spent + forfeited_marks + reserved > lifetime_marks:
		errors.append("active Board Mandate stake exceeds available lifetime Roost Marks")
	if history.size() > MAX_MANDATE_HISTORY:
		errors.append("mandate_history exceeds its retention limit")
	_validate_mandate_history(data, history, counts, errors)


static func _validate_active_mandate(
	active: Dictionary,
	offers: Array,
	data: Dictionary,
	errors: PackedStringArray,
) -> void:
	var active_keys: Array[String] = [
		"id", "name", "summary", "tier", "stake_marks", "seal_reward",
		"offer_year", "context_opening_day", "objectives", "reward", "failure",
		"selected_year", "selected_at_completed_quarter",
		"selected_at_lifetime_marks", "grandfathered",
	]
	if not _has_exact_string_keys(active, active_keys):
		errors.append("active_annual_mandate has unsupported or missing fields")
		return
	for key in [
		"tier", "stake_marks", "seal_reward", "offer_year", "context_opening_day",
		"selected_year", "selected_at_completed_quarter", "selected_at_lifetime_marks",
	]:
		if not _is_integer(active.get(key)) or int(active.get(key, -1)) < 0:
			errors.append("active_annual_mandate.%s must be a nonnegative integer" % key)
	if typeof(active.get("grandfathered")) != TYPE_BOOL:
		errors.append("active_annual_mandate.grandfathered must be a bool")
	var id := StringName(String(active.get("id", "")))
	if id not in MANDATE_IDS:
		errors.append("active_annual_mandate.id is not supported")
	var frozen_offer: Dictionary = {}
	for offer_value in offers:
		if offer_value is Dictionary and StringName(String((offer_value as Dictionary).get("id", ""))) == id:
			frozen_offer = (offer_value as Dictionary).duplicate(true)
			break
	if frozen_offer.is_empty():
		errors.append("active_annual_mandate is not one of the frozen offers")
	else:
		for key in frozen_offer.keys():
			if active.get(key) != frozen_offer.get(key):
				errors.append("active_annual_mandate.%s is inconsistent with its frozen offer" % String(key))
	var expected_year := int((data.get("annual_mandate_offer_context", {}) as Dictionary).get("year", 0))
	if int(active.get("selected_year", 0)) != expected_year:
		errors.append("active_annual_mandate.selected_year is stale")
	if int(active.get("selected_at_completed_quarter", -1)) != int(data.get("completed_years", 0)) * QUARTERS_PER_YEAR:
		errors.append("active_annual_mandate selection gate is inconsistent")
	if int(active.get("selected_at_lifetime_marks", -1)) > int(data.get("roost_marks", 0)):
		errors.append("active_annual_mandate selected lifetime marks exceed the current ledger")
	var context := data.get("annual_mandate_offer_context", {}) as Dictionary
	if int(active.get("selected_at_lifetime_marks", -1)) < int(context.get("available_marks", 0)):
		errors.append("active_annual_mandate selected lifetime marks are inconsistent with its frozen availability")


static func _validate_last_mandate_selection(
	data: Dictionary,
	active: Dictionary,
	history: Array,
	errors: PackedStringArray,
) -> void:
	var saved := _restore_json_numbers(data.get("last_mandate_selection", {})) as Dictionary
	var status_id := StringName(String(data.get("status", "")))
	var target: Dictionary = {}
	var grandfathered := false
	if not active.is_empty():
		target = active
		grandfathered = bool(active.get("grandfathered", false))
	elif status_id == STATUS_ANNUAL_REVIEW and not history.is_empty() and history.back() is Dictionary:
		target = history.back() as Dictionary
		grandfathered = bool(target.get("grandfathered", false))
	if saved.is_empty():
		if not target.is_empty() and not grandfathered:
			errors.append("last_mandate_selection is missing for the current Senior year")
		return
	if target.is_empty() or grandfathered:
		errors.append("last_mandate_selection is stale")
		return
	var keys: Array[String] = [
		"accepted", "action_id", "year", "mandate_id", "mandate_name", "tier",
		"stake_marks", "available_roost_marks_after", "outcome",
	]
	if not _has_exact_string_keys(saved, keys):
		errors.append("last_mandate_selection has unsupported or missing fields")
		return
	if typeof(saved.get("accepted")) != TYPE_BOOL or not bool(saved.get("accepted", false)):
		errors.append("last_mandate_selection must be an accepted receipt")
	if String(saved.get("action_id", "")) != "select_annual_board_mandate":
		errors.append("last_mandate_selection.action_id is not supported")
	for key in ["year", "tier", "stake_marks", "available_roost_marks_after"]:
		if not _is_integer(saved.get(key)) or int(saved.get(key, -1)) < 0:
			errors.append("last_mandate_selection.%s must be a nonnegative integer" % key)
	for key in ["mandate_id", "mandate_name", "outcome"]:
		if typeof(saved.get(key)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			errors.append("last_mandate_selection.%s must be a String" % key)
	for key in ["year", "mandate_id", "mandate_name", "tier", "stake_marks"]:
		var target_key: String = key
		if key == "year" and not target.has(key):
			target_key = "selected_year"
		elif key == "mandate_id" and not target.has(key):
			target_key = "id"
		elif key == "mandate_name" and not target.has(key):
			target_key = "name"
		var matches := (
			int(saved.get(key, -1)) == int(target.get(target_key, -2))
			if key in ["year", "tier", "stake_marks"] else
			str(saved.get(key)) == str(target.get(target_key))
		)
		if not matches:
			errors.append("last_mandate_selection.%s is inconsistent with the annual mandate" % key)
	if int(saved.get("available_roost_marks_after", 0)) > int(data.get("roost_marks", 0)):
		errors.append("last_mandate_selection available marks exceed the lifetime ledger")
	var frozen_available := int((data.get("annual_mandate_offer_context", {}) as Dictionary).get("available_marks", 0))
	if int(saved.get("available_roost_marks_after", 0)) > frozen_available - int(saved.get("stake_marks", 0)):
		errors.append("last_mandate_selection available marks are inconsistent with the frozen stake")


static func _validate_mandate_evidence(
	row: Dictionary,
	index: int,
	errors: PackedStringArray,
) -> void:
	var keys: Array[String] = [
		"day", "met_quota", "eggs", "cracked", "credited_cents", "welfare",
		"compliance", "farmer_favor", "wage_arrears_cents", "closing_fund_cents",
	]
	if not _has_exact_string_keys(row, keys):
		errors.append("current_mandate_evidence[%d] has unsupported or missing fields" % index)
		return
	if typeof(row.get("met_quota")) != TYPE_BOOL:
		errors.append("current_mandate_evidence[%d].met_quota must be a bool" % index)
	for key in keys:
		if key == "met_quota":
			continue
		if not _is_integer(row.get(key)) or int(row.get(key, -1)) < 0:
			errors.append("current_mandate_evidence[%d].%s must be a nonnegative integer" % [index, key])
	for key in ["welfare", "compliance", "farmer_favor"]:
		if int(row.get(key, 0)) > 100:
			errors.append("current_mandate_evidence[%d].%s must not exceed 100" % [index, key])
	if int(row.get("cracked", 0)) > int(row.get("eggs", 0)):
		errors.append("current_mandate_evidence[%d].cracked cannot exceed eggs" % index)


static func _validate_mandate_history(
	data: Dictionary,
	history: Array,
	counts: Dictionary,
	errors: PackedStringArray,
) -> void:
	var next_id := int(data.get("next_mandate_settlement_id", 0))
	var completed_year_count := int(data.get("completed_years", 0))
	var first_expected_id := next_id - history.size()
	var first_expected_year := completed_year_count - history.size() + 1
	var successes_by_id: Dictionary = {}
	var visible_seals := 0
	var visible_forfeited := 0
	var normalized_history: Array[Dictionary] = []
	for mandate_id in MANDATE_IDS:
		successes_by_id[mandate_id] = 0
	if history.size() > completed_year_count:
		errors.append("mandate_history cannot exceed completed Senior years")
	if next_id - 1 > completed_year_count:
		errors.append("mandate settlements cannot exceed completed Senior years")
	for index in history.size():
		var value: Variant = history[index]
		if not value is Dictionary:
			errors.append("mandate_history[%d] must be a Dictionary" % index)
			normalized_history.append({})
			continue
		var receipt := _restore_json_numbers(value) as Dictionary
		normalized_history.append(receipt)
		var receipt_keys: Array[String] = [
			"settlement_id", "year", "mandate_id", "mandate_name", "tier",
			"success", "grandfathered", "stake_marks", "stake_returned",
			"stake_forfeited", "seal_reward", "mandate_seals_after",
			"mandate_marks_forfeited_after", "available_roost_marks_before",
			"available_roost_marks_after", "progress", "outcome",
		]
		if not _has_exact_string_keys(receipt, receipt_keys):
			errors.append("mandate_history[%d] has unsupported or missing fields" % index)
		for key in [
			"settlement_id", "year", "tier", "stake_marks", "stake_returned",
			"stake_forfeited", "seal_reward", "mandate_seals_after",
			"mandate_marks_forfeited_after", "available_roost_marks_before",
			"available_roost_marks_after",
		]:
			if not _is_integer(receipt.get(key)) or int(receipt.get(key, -1)) < 0:
				errors.append("mandate_history[%d].%s must be a nonnegative integer" % [index, key])
		for key in ["success", "grandfathered"]:
			if typeof(receipt.get(key)) != TYPE_BOOL:
				errors.append("mandate_history[%d].%s must be a bool" % [index, key])
		for key in ["mandate_id", "mandate_name", "outcome"]:
			if typeof(receipt.get(key)) not in [TYPE_STRING, TYPE_STRING_NAME]:
				errors.append("mandate_history[%d].%s must be a String" % [index, key])
		if typeof(receipt.get("progress")) != TYPE_DICTIONARY:
			errors.append("mandate_history[%d].progress must be a Dictionary" % index)
		var settlement_id := int(receipt.get("settlement_id", 0))
		if settlement_id != first_expected_id + index:
			errors.append("mandate_history[%d].settlement_id is stale or out of sequence" % index)
		if int(receipt.get("year", 0)) != first_expected_year + index:
			errors.append("mandate_history[%d].year is stale or out of sequence" % index)
		var id := StringName(String(receipt.get("mandate_id", "")))
		if id not in MANDATE_IDS:
			errors.append("mandate_history[%d].mandate_id is not supported" % index)
		var definition := _mandate_definition_for_id(id)
		var success := bool(receipt.get("success", false))
		var grandfathered := bool(receipt.get("grandfathered", false))
		var stake := int(receipt.get("stake_marks", 0))
		if success and grandfathered:
			errors.append("mandate_history[%d] cannot be both successful and grandfathered" % index)
		if grandfathered and (id != MANDATE_FALLBACK_ID or stake != 0):
			errors.append("mandate_history[%d] grandfathered settlement must use the no-stake fallback" % index)
		if not definition.is_empty():
			if int(receipt.get("tier", -1)) != int(definition.get("tier", -2)):
				errors.append("mandate_history[%d].tier is inconsistent with its mandate" % index)
			if stake != int(definition.get("stake_marks", -1)):
				errors.append("mandate_history[%d].stake_marks is inconsistent with its mandate" % index)
		if int(receipt.get("stake_returned", -1)) != (stake if success else 0):
			errors.append("mandate_history[%d].stake_returned is inconsistent" % index)
		var expected_forfeit := stake if not success and not grandfathered else 0
		if int(receipt.get("stake_forfeited", -1)) != expected_forfeit:
			errors.append("mandate_history[%d].stake_forfeited is inconsistent" % index)
		visible_forfeited += expected_forfeit
		var reward := int(receipt.get("seal_reward", 0))
		var expected_reward := int(definition.get("seal_reward", 0)) if success else 0
		if reward != expected_reward:
			errors.append("mandate_history[%d].seal_reward is inconsistent" % index)
		if success:
			visible_seals += reward
			successes_by_id[id] = int(successes_by_id.get(id, 0)) + 1
		var available_before := int(receipt.get("available_roost_marks_before", 0))
		var expected_available_after := available_before + (stake if success else 0)
		if int(receipt.get("available_roost_marks_after", -1)) != expected_available_after:
			errors.append("mandate_history[%d].available_roost_marks_after is inconsistent" % index)
		if receipt.get("progress") is Dictionary:
			_validate_settled_mandate_progress(receipt, index, errors)
	if not history.is_empty():
		var normalized_last := _restore_json_numbers(
			data.get("last_mandate_settlement", {}),
		) as Dictionary
		if normalized_last != normalized_history.back():
			errors.append("last_mandate_settlement must match the newest history receipt")
		var base_seals := int(data.get("mandate_seals", 0)) - visible_seals
		var base_forfeited := int(data.get("mandate_marks_forfeited", 0)) - visible_forfeited
		if base_seals < 0 or base_forfeited < 0:
			errors.append("mandate_history cumulative rewards exceed the authoritative ledger")
		else:
			var running_seals := base_seals
			var running_forfeited := base_forfeited
			for index in normalized_history.size():
				var receipt := normalized_history[index]
				running_seals += int(receipt.get("seal_reward", 0))
				running_forfeited += int(receipt.get("stake_forfeited", 0))
				if int(receipt.get("mandate_seals_after", -1)) != running_seals:
					errors.append("mandate_history[%d].mandate_seals_after is inconsistent" % index)
				if int(receipt.get("mandate_marks_forfeited_after", -1)) != running_forfeited:
					errors.append("mandate_history[%d].mandate_marks_forfeited_after is inconsistent" % index)
		var latest_annual := _restore_json_numbers(data.get("last_annual_review", {})) as Dictionary
		if not latest_annual.has("mandate_settlement") or latest_annual.get("mandate_settlement") != normalized_history.back():
			errors.append("last_annual_review must contain the newest mandate settlement")
		var annual_records := data.get("annual_history", []) as Array
		if annual_records.is_empty() or not annual_records.back() is Dictionary:
			errors.append("mandate_history requires a matching annual_history receipt")
		else:
			var latest_record := _restore_json_numbers(annual_records.back()) as Dictionary
			if latest_record.get("mandate_settlement", {}) != normalized_history.back():
				errors.append("annual_history newest mandate settlement is inconsistent")
	else:
		if next_id != 1:
			errors.append("empty mandate_history requires settlement ID one")
		if not (data.get("last_mandate_settlement", {}) as Dictionary).is_empty():
			errors.append("empty mandate_history requires an empty last_mandate_settlement")
	if first_expected_id < 1:
		errors.append("next_mandate_settlement_id is inconsistent with mandate_history")
	var has_retired_receipts := first_expected_id > 1
	if has_retired_receipts and history.size() != MAX_MANDATE_HISTORY:
		errors.append("mandate_history can retire receipts only at its retention limit")
	for mandate_id in MANDATE_IDS:
		var visible_count := int(successes_by_id.get(mandate_id, 0))
		var authoritative_count := int(counts.get(String(mandate_id), -1))
		if authoritative_count < visible_count or (not has_retired_receipts and authoritative_count != visible_count):
			errors.append("mandate_success_counts.%s is inconsistent with mandate history" % String(mandate_id))


static func _validate_settled_mandate_progress(
	receipt: Dictionary,
	history_index: int,
	errors: PackedStringArray,
) -> void:
	var progress := _restore_json_numbers(receipt.get("progress", {})) as Dictionary
	var keys: Array[String] = [
		"visible", "mandate_id", "mandate_name", "year", "tier", "stake_marks",
		"shifts_recorded", "shifts_target", "quarter_checkpoints_filed",
		"objectives_met", "objectives_total", "objectives", "aggregate",
		"next_threshold", "largest_recoverable_blocker", "all_targets_met",
		"complete", "success", "grandfathered",
	]
	if not _has_exact_string_keys(progress, keys):
		errors.append("mandate_history[%d].progress has unsupported or missing fields" % history_index)
		return
	for key in ["visible", "all_targets_met", "complete", "success", "grandfathered"]:
		if typeof(progress.get(key)) != TYPE_BOOL:
			errors.append("mandate_history[%d].progress.%s must be a bool" % [history_index, key])
	for key in [
		"year", "tier", "stake_marks", "shifts_recorded", "shifts_target",
		"quarter_checkpoints_filed", "objectives_met", "objectives_total",
	]:
		if not _is_integer(progress.get(key)) or int(progress.get(key, -1)) < 0:
			errors.append("mandate_history[%d].progress.%s must be a nonnegative integer" % [history_index, key])
	for key in ["objectives", "aggregate"]:
		var expected_type := TYPE_ARRAY if key == "objectives" else TYPE_DICTIONARY
		if typeof(progress.get(key)) != expected_type:
			errors.append("mandate_history[%d].progress.%s has an invalid type" % [history_index, key])
	for key in ["next_threshold", "largest_recoverable_blocker"]:
		if typeof(progress.get(key)) != TYPE_DICTIONARY:
			errors.append("mandate_history[%d].progress.%s must be a Dictionary" % [history_index, key])
	for key in ["mandate_id", "mandate_name", "year", "tier", "stake_marks", "grandfathered"]:
		if str(progress.get(key)) != str(receipt.get(key)):
			errors.append("mandate_history[%d].progress.%s is inconsistent with its settlement" % [history_index, key])
	if int(progress.get("shifts_recorded", 0)) != MANDATE_SHIFTS_PER_YEAR:
		errors.append("mandate_history[%d].progress must contain exactly twelve shifts" % history_index)
	if int(progress.get("shifts_target", 0)) != MANDATE_SHIFTS_PER_YEAR:
		errors.append("mandate_history[%d].progress.shifts_target is inconsistent" % history_index)
	if int(progress.get("quarter_checkpoints_filed", 0)) != QUARTERS_PER_YEAR:
		errors.append("mandate_history[%d].progress quarter checkpoints are incomplete" % history_index)
	if not bool(progress.get("visible", false)) or not bool(progress.get("complete", false)):
		errors.append("mandate_history[%d].progress must be visible and complete" % history_index)
	var expected_success := bool(progress.get("success", false)) and not bool(receipt.get("grandfathered", false))
	if bool(receipt.get("success", false)) != expected_success:
		errors.append("mandate_history[%d].success is inconsistent with settled progress" % history_index)
	if bool(progress.get("success", false)) != bool(progress.get("all_targets_met", false)):
		errors.append("mandate_history[%d].progress success is inconsistent with its targets" % history_index)
	var objectives: Array = []
	if progress.get("objectives") is Array:
		objectives = progress.get("objectives") as Array
	if int(progress.get("objectives_total", -1)) != objectives.size():
		errors.append("mandate_history[%d].progress.objectives_total is inconsistent" % history_index)
	var met_count := 0
	for objective_value in objectives:
		if objective_value is Dictionary and bool((objective_value as Dictionary).get("met", false)):
			met_count += 1
	if int(progress.get("objectives_met", -1)) != met_count:
		errors.append("mandate_history[%d].progress.objectives_met is inconsistent" % history_index)


static func _has_exact_string_keys(value: Dictionary, expected: Array[String]) -> bool:
	if value.size() != expected.size():
		return false
	for key in expected:
		if not value.has(key):
			return false
	return true


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
