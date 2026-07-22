class_name CampaignState
extends RefCounted

## Authoritative five-shift probation campaign state. This model does not own
## scenes or the simulation. Feed it DepartmentSimulation.workday_completed
## reports plus the closing snapshot, then persist to_dictionary() anywhere.

const CAMPAIGN_LENGTH: int = 5
const MILESTONE_AFTER_SHIFT: int = 2
const STARTING_SCORE: int = 50
const MIN_PASS_SCORE: int = 60
const MIN_PASS_WELFARE: int = 45
const MIN_PASS_COMPLIANCE: int = 55
const MIN_PASS_FARMER_FAVOR: int = 50
const MAX_PASS_CRACK_RATE_BASIS_POINTS: int = 2500
const DEFAULT_OPENING_FUND_CENTS: int = 5000
const SCHEMA_ID: String = "pecking_order.probation_campaign"
const SCHEMA_VERSION: int = 2

const CHALLENGE_SUPPORTED_FLOCK: StringName = &"supported_flock"
const CHALLENGE_STANDARD_FILING: StringName = &"standard_filing"
const CHALLENGE_EXECUTIVE_AUDIT: StringName = &"executive_audit"

const CHALLENGE_CONTRACT_IDS: Array[StringName] = [
	CHALLENGE_SUPPORTED_FLOCK,
	CHALLENGE_STANDARD_FILING,
	CHALLENGE_EXECUTIVE_AUDIT,
]
const CHALLENGE_CONTRACTS := {
	CHALLENGE_SUPPORTED_FLOCK: {
		"id": "supported_flock",
		"label": "SUPPORTED FLOCK",
		"short_label": "SUPPORTED",
		"difficulty": "learning",
		"difficulty_label": "LEARNING",
		"difficulty_guidance": "Best for learning the complete management loop with more recovery room.",
		"description": "More room for score, farmer favor, and shell loss while preserving the Standard welfare and compliance floors.",
		"route_brief": "OPEN ROUTES  //  CARE, QUALITY & HARVEST",
		"route_guidance": "Use this contract to learn any doctrine. It forgives score, favor, and shell-loss variance, but welfare and compliance still require active management.",
		"criteria": {
			"minimum_score": 35,
			"minimum_welfare": 45,
			"minimum_compliance": 55,
			"minimum_farmer_favor": 45,
			"maximum_crack_rate_basis_points": 3000,
		},
	},
	CHALLENGE_STANDARD_FILING: {
		"id": "standard_filing",
		"label": "STANDARD FILING",
		"short_label": "STANDARD",
		"difficulty": "standard",
		"difficulty_label": "STANDARD",
		"difficulty_guidance": "The recommended authored balance for a first complete probation file.",
		"description": "The authored probation contract with the shipped balance of flock care, compliance, favor, and shell quality.",
		"route_brief": "BALANCED ROUTES  //  CARE, QUALITY & HARVEST",
		"route_guidance": "Every permanent doctrine has a tested route through these terms. Follow its playbook and cover the safeguard named in its watchout.",
		"criteria": {
			"minimum_score": MIN_PASS_SCORE,
			"minimum_welfare": MIN_PASS_WELFARE,
			"minimum_compliance": MIN_PASS_COMPLIANCE,
			"minimum_farmer_favor": MIN_PASS_FARMER_FAVOR,
			"maximum_crack_rate_basis_points": MAX_PASS_CRACK_RATE_BASIS_POINTS,
		},
	},
	CHALLENGE_EXECUTIVE_AUDIT: {
		"id": "executive_audit",
		"label": "EXECUTIVE AUDIT",
		"short_label": "EXECUTIVE",
		"difficulty": "expert",
		"difficulty_label": "EXPERT",
		"difficulty_guidance": "A demanding replay contract for managers who already understand every safeguard.",
		"description": "A tighter replay contract demanding stronger score, welfare, compliance, favor, and shell-loss results.",
		"route_brief": "EXPERT REPLAY  //  HARVEST ROUTE PROVEN",
		"route_guidance": "Harvest Partnership has a proven specialist route. Care-led files need extra score; quality-led files must deliberately recover welfare and farmer favor.",
		"criteria": {
			"minimum_score": 65,
			"minimum_welfare": 48,
			"minimum_compliance": 65,
			"minimum_farmer_favor": 53,
			"maximum_crack_rate_basis_points": 2300,
		},
	},
}

const OUTCOME_IN_PROGRESS: StringName = &"in_progress"
const OUTCOME_PASSED: StringName = &"passed"
const OUTCOME_FAILED: StringName = &"failed"

const RANK_TERMINATED: StringName = &"terminated"
const RANK_CRITICAL_REVIEW: StringName = &"critical_review"
const RANK_PROBATIONARY: StringName = &"probationary"
const RANK_TRUSTED_LAYER: StringName = &"trusted_layer"
const RANK_GOLDEN_MANAGEMENT: StringName = &"golden_management"

var completed_shifts: int = 0
var probation_score: int = STARTING_SCORE
var probation_rank: StringName = RANK_PROBATIONARY
var outcome: StringName = OUTCOME_IN_PROGRESS
var final_reason: String = "Complete five shifts without sacrificing the flock."

var cumulative_welfare: int = 0
var cumulative_compliance: int = 0
var cumulative_farmer_favor: int = 0
var total_credited_cents: int = 0
var total_eggs: int = 0
var total_cracked_eggs: int = 0
var total_overdue_files: int = 0
var total_rework: int = 0

var _challenge_contract_id: StringName = CHALLENGE_STANDARD_FILING
## Read-only public view of the permanently filed challenge contract. Selection
## and validated hydration write the private authority directly; external
## assignment is intentionally ignored so callers cannot bypass the lifecycle
## lock enforced by select_challenge_contract().
var challenge_contract_id: StringName:
	get:
		return _challenge_contract_id
	set(_value):
		pass
var chosen_milestone_id: StringName = &""
var unlocked_feature_ids: Array[StringName] = []
var shift_records: Array[CampaignShiftRecord] = []

var _last_closing_fund_cents: int = DEFAULT_OPENING_FUND_CENTS
var _last_source_rework_total: int = 0
var _challenge_contract_selected: bool = false


func _init() -> void:
	probation_rank = rank_for_score(probation_score)


## Stable presentation catalog. Returned dictionaries are deep copies so UI
## code cannot mutate the authoritative thresholds shared by every campaign.
static func challenge_contract_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for contract_id in CHALLENGE_CONTRACT_IDS:
		result.append(challenge_contract(contract_id))
	return result


static func challenge_contract(contract_id: StringName) -> Dictionary:
	var normalized := StringName(String(contract_id).to_lower())
	if not CHALLENGE_CONTRACTS.has(normalized):
		return {}
	return (CHALLENGE_CONTRACTS[normalized] as Dictionary).duplicate(true)


## A contract may be selected exactly once on a pristine in-memory campaign.
## Restored files and campaigns with accepted work are already locked. The
## Standard contract remains the safe default when callers make no selection.
func select_challenge_contract(contract_id: StringName) -> bool:
	if (
		_challenge_contract_selected
		or completed_shifts != 0
		or not shift_records.is_empty()
		or chosen_milestone_id != &""
		or outcome != OUTCOME_IN_PROGRESS
	):
		return false
	var contract := challenge_contract(contract_id)
	if contract.is_empty():
		return false
	_challenge_contract_id = StringName(String(contract["id"]))
	_challenge_contract_selected = true
	return true


func challenge_contract_snapshot() -> Dictionary:
	var contract := challenge_contract(challenge_contract_id)
	if contract.is_empty():
		contract = challenge_contract(CHALLENGE_STANDARD_FILING)
	return contract


## Applies exactly one chronological shift. The existing simulation report keys
## are consumed directly: day, eggs, quota, cracked, feed_cost_cents,
## overdue_claims, rework_total_created, and closing_fund_cents. Welfare is
## derived from workers when not explicitly supplied; compliance and farmer
## favor use compliance / executive_confidence from the closing snapshot.
func record_shift(report: Dictionary, closing_snapshot: Dictionary = {}) -> Dictionary:
	var errors := _validate_shift_input(report, closing_snapshot)
	if not errors.is_empty():
		return {"accepted": false, "errors": errors}

	_challenge_contract_selected = true
	var record := _normalize_shift(report, closing_snapshot)
	_evaluate_objectives(record)
	record.score_delta = _score_shift(record)
	probation_score = clampi(probation_score + record.score_delta, 0, 100)
	probation_rank = rank_for_score(probation_score)
	record.score_after = probation_score
	record.rank_after = probation_rank

	shift_records.append(record)
	completed_shifts += 1
	cumulative_welfare += record.welfare
	cumulative_compliance += record.compliance
	cumulative_farmer_favor += record.farmer_favor
	total_credited_cents += record.credited_cents
	total_eggs += record.eggs
	total_cracked_eggs += record.cracked_eggs
	total_overdue_files += record.overdue_files
	total_rework += record.rework
	if report.has("closing_fund_cents"):
		_last_closing_fund_cents = int(report["closing_fund_cents"])
	if report.has("rework_total_created"):
		_last_source_rework_total = int(report["rework_total_created"])
	_refresh_outcome()

	return {
		"accepted": true,
		"errors": PackedStringArray(),
		"record": record.to_dictionary(),
		"campaign": snapshot(),
		"milestone_available": is_milestone_choice_available(),
		"final_evaluation": final_evaluation(),
	}


## The gate opens after shift two and is deliberately mandatory before shift
## three, making the probation specialization a visible strategic commitment.
func choose_milestone(choice_id: StringName) -> bool:
	if not is_milestone_choice_available():
		return false
	var choice := _milestone_by_id(choice_id)
	if choice == null:
		return false
	chosen_milestone_id = choice.id
	unlocked_feature_ids.assign([choice.unlock_id])
	probation_score = clampi(probation_score + choice.score_bonus, 0, 100)
	probation_rank = rank_for_score(probation_score)
	_refresh_outcome()
	return true


func is_milestone_choice_available() -> bool:
	return (
		outcome == OUTCOME_IN_PROGRESS
		and completed_shifts == MILESTONE_AFTER_SHIFT
		and chosen_milestone_id == &""
	)


func milestone_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for choice in _milestone_choices():
		result.append(choice.to_dictionary())
	return result


func available_milestone_choices() -> Array[Dictionary]:
	return milestone_catalog() if is_milestone_choice_available() else []


func has_unlock(unlock_id: StringName) -> bool:
	return unlock_id in unlocked_feature_ids


func active_unlock_effects() -> Dictionary:
	if chosen_milestone_id == &"":
		return {}
	var choice := _milestone_by_id(chosen_milestone_id)
	return choice.effects.duplicate(true) if choice != null else {}


## Presentation guidance for the permanent specialization already represented
## by chosen_milestone_id. This is derived rather than persisted, so old saves
## gain the same doctrine identity without a schema migration or duplicated
## source of truth.
func active_doctrine() -> Dictionary:
	if chosen_milestone_id == &"":
		return {}
	var choice := _milestone_by_id(chosen_milestone_id)
	if choice == null:
		return {}
	var result := choice.doctrine.duplicate(true)
	result["milestone_id"] = String(choice.id)
	result["milestone_title"] = choice.title
	result["unlock_id"] = String(choice.unlock_id)
	result["unlock_label"] = choice.unlock_label
	result["effects"] = choice.effects.duplicate(true)
	return result


func objectives_for_shift(shift_number: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for objective in _objectives_for_shift(shift_number):
		result.append(objective.to_dictionary(false))
	return result


func current_objectives() -> Array[Dictionary]:
	if outcome != OUTCOME_IN_PROGRESS or completed_shifts >= CAMPAIGN_LENGTH:
		return []
	return objectives_for_shift(completed_shifts + 1)


## Projects the current shift against the same immutable objective definitions
## used by record_shift(). The result is presentation-only: it never awards
## score early, and closing metrics may still move before 5:00 PM.
func current_objective_progress(live_metrics: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if outcome != OUTCOME_IN_PROGRESS or completed_shifts >= CAMPAIGN_LENGTH:
		return result
	for objective in _objectives_for_shift(completed_shifts + 1):
		var row := objective.to_dictionary(false)
		var actual := int(live_metrics.get(objective.metric, 0))
		var projected_met := objective.is_completed(live_metrics)
		var progress := 0.0
		match objective.comparison:
			CampaignObjective.COMPARISON_MINIMUM:
				progress = clampf(float(actual) / float(maxi(1, objective.target)), 0.0, 1.0)
			CampaignObjective.COMPARISON_MAXIMUM:
				progress = (
					1.0 if actual <= objective.target else
					clampf(float(maxi(1, objective.target)) / float(maxi(1, actual)), 0.0, 1.0)
				)
			CampaignObjective.COMPARISON_EQUAL:
				progress = 1.0 if projected_met else 0.0
		row["actual"] = actual
		row["projected_met"] = projected_met
		row["progress_ratio"] = progress
		row["status"] = "on_track" if projected_met else "needs_action"
		result.append(row)
	return result


## Cursor used to turn the simulation's lifetime rework counter into the exact
## current-shift value expected by the next probation order.
func last_source_rework_total() -> int:
	return _last_source_rework_total


func latest_score_receipt() -> Dictionary:
	if shift_records.is_empty():
		return {}
	return score_receipt_for_shift(shift_records.size())


func score_receipt_for_shift(shift_number: int) -> Dictionary:
	if shift_number < 1 or shift_number > shift_records.size():
		return {}
	var record := shift_records[shift_number - 1]
	var score_before := _score_before_shift(shift_number)
	var components := _score_components(record)
	var raw_delta := 0
	for component in components:
		raw_delta += int(component.get("delta", 0))
	var applied_delta := record.score_after - score_before
	var cap_adjustment := applied_delta - raw_delta
	if cap_adjustment != 0:
		components.append({
			"id": "score_cap",
			"label": "SCORE CAP",
			"detail": "The probation ledger is bounded between 0 and 100.",
			"delta": cap_adjustment,
			"tone": &"neutral",
		})
	var milestone_bonus := 0
	var milestone_title := ""
	if shift_number == MILESTONE_AFTER_SHIFT and chosen_milestone_id != &"":
		var milestone := _milestone_by_id(chosen_milestone_id)
		if milestone != null:
			milestone_bonus = milestone.score_bonus
			milestone_title = milestone.title
			components.append({
				"id": "milestone_bonus",
				"label": "SPECIALIZATION FILED",
				"detail": milestone.title,
				"delta": milestone_bonus,
				"tone": &"positive" if milestone_bonus > 0 else &"neutral",
			})
	var score_after_report := clampi(record.score_after + milestone_bonus, 0, 100)
	return {
		"shift_number": shift_number,
		"score_before": score_before,
		"raw_shift_delta": raw_delta,
		"score_delta": score_after_report - score_before,
		"applied_shift_delta": applied_delta,
		"cap_adjustment": cap_adjustment,
		"clamped": cap_adjustment != 0,
		"score_after_shift": record.score_after,
		"score_after": score_after_report,
		"rank_after": String(rank_for_score(score_after_report)),
		"milestone_bonus": milestone_bonus,
		"milestone_title": milestone_title,
		"components": components,
	}


func average_welfare() -> int:
	return _rounded_average(cumulative_welfare, completed_shifts)


func average_compliance() -> int:
	return _rounded_average(cumulative_compliance, completed_shifts)


func average_farmer_favor() -> int:
	return _rounded_average(cumulative_farmer_favor, completed_shifts)


func cumulative_crack_rate_basis_points() -> int:
	return _basis_points(total_cracked_eggs, total_eggs)


## Read-only final-safeguard forecast for the probation ledger. Callers may
## supply any subset of the five aggregate metric keys to preview a proposed
## closing state without changing the campaign:
## probation_score, average_welfare, average_compliance,
## average_farmer_favor, and crack_rate_basis_points.
##
## signed_gap is deliberately comparable in meaning across minimum and maximum
## criteria: positive is headroom, zero is the exact pass boundary, and
## negative is a miss. distance_to_pass is the corresponding unsigned deficit.
func probation_safeguard_forecast(projected_metrics: Dictionary = {}) -> Dictionary:
	var current_values := {
		"probation_score": probation_score,
		"average_welfare": average_welfare(),
		"average_compliance": average_compliance(),
		"average_farmer_favor": average_farmer_favor(),
		"crack_rate_basis_points": cumulative_crack_rate_basis_points(),
	}
	var criteria: Array[Dictionary] = []
	var pass_count := 0
	var at_risk_count := 0
	var largest_recoverable_blocker: Dictionary = {}
	var largest_distance_basis_points := -1
	var can_recover := outcome == OUTCOME_IN_PROGRESS and completed_shifts < CAMPAIGN_LENGTH
	for specification in _probation_safeguard_specifications():
		var metric := String(specification["metric"])
		var comparison := String(specification["comparison"])
		var target := int(specification["target"])
		var current_value := int(current_values[metric])
		var has_projection := (
			projected_metrics.has(metric)
			and _is_integer_number(projected_metrics[metric])
		)
		var projected_value := current_value
		if has_projection:
			var maximum := 10_000 if metric == "crack_rate_basis_points" else 100
			projected_value = clampi(int(projected_metrics[metric]), 0, maximum)
		var current_signed_gap := (
			current_value - target
			if comparison == "minimum" else
			target - current_value
		)
		var signed_gap := (
			projected_value - target
			if comparison == "minimum" else
			target - projected_value
		)
		var passed := signed_gap >= 0
		var distance_to_pass := maxi(0, -signed_gap)
		var distance_basis_points := (
			0 if passed else
			clampi(
				roundi(float(distance_to_pass) * 10_000.0 / float(maxi(1, target))),
				0,
				10_000,
			)
		)
		var row := {
			"id": String(specification["id"]),
			"label": String(specification["label"]),
			"metric": metric,
			"comparison": comparison,
			"target": target,
			"unit": String(specification["unit"]),
			"current_value": current_value,
			"projected_value": projected_value,
			"value_source": "projected" if has_projection else "current",
			"current_pass": current_signed_gap >= 0,
			"current_signed_gap": current_signed_gap,
			"pass": passed,
			"at_risk": not passed,
			"status": "pass" if passed else "at_risk",
			"signed_gap": signed_gap,
			"distance_to_pass": distance_to_pass,
			"distance_basis_points": distance_basis_points,
			"recoverable": not passed and can_recover,
		}
		criteria.append(row)
		if passed:
			pass_count += 1
		else:
			at_risk_count += 1
			if can_recover and distance_basis_points > largest_distance_basis_points:
				largest_distance_basis_points = distance_basis_points
				largest_recoverable_blocker = row.duplicate(true)
	return {
		"visible": true,
		"is_final": outcome != OUTCOME_IN_PROGRESS,
		"challenge_contract": challenge_contract_snapshot(),
		"completed_shifts": completed_shifts,
		"required_shifts": CAMPAIGN_LENGTH,
		"criteria": criteria,
		"pass_count": pass_count,
		"at_risk_count": at_risk_count,
		"criteria_count": criteria.size(),
		"all_pass": pass_count == criteria.size(),
		"largest_recoverable_blocker": largest_recoverable_blocker,
	}


func final_evaluation() -> Dictionary:
	var safeguards := probation_safeguard_forecast()
	var safeguard_passes := {}
	for row_value in safeguards.get("criteria", []) as Array:
		if row_value is Dictionary:
			var row := row_value as Dictionary
			safeguard_passes[String(row.get("id", ""))] = bool(row.get("pass", false))
	return {
		"outcome": String(outcome),
		"passed": outcome == OUTCOME_PASSED,
		"is_final": outcome != OUTCOME_IN_PROGRESS,
		"reason": final_reason,
		"challenge_contract": challenge_contract_snapshot(),
		"completed_shifts": completed_shifts,
		"required_shifts": CAMPAIGN_LENGTH,
		"probation_score": probation_score,
		"probation_rank": String(probation_rank),
		"average_welfare": average_welfare(),
		"average_compliance": average_compliance(),
		"average_farmer_favor": average_farmer_favor(),
		"crack_rate_basis_points": cumulative_crack_rate_basis_points(),
		"criteria": {
			"score": bool(safeguard_passes.get("score", false)),
			"welfare": bool(safeguard_passes.get("welfare", false)),
			"compliance": bool(safeguard_passes.get("compliance", false)),
			"farmer_favor": bool(safeguard_passes.get("farmer_favor", false)),
			"shell_quality": bool(safeguard_passes.get("crack_rate", false)),
		},
		"chosen_milestone_id": String(chosen_milestone_id),
		"unlocked_feature_ids": _string_array(unlocked_feature_ids),
	}


func snapshot() -> Dictionary:
	var data := to_dictionary()
	data["current_objectives"] = current_objectives()
	data["milestone_available"] = is_milestone_choice_available()
	data["available_milestones"] = available_milestone_choices()
	data["active_unlock_effects"] = active_unlock_effects()
	data["active_doctrine"] = active_doctrine()
	data["challenge_contract"] = challenge_contract_snapshot()
	data["final_evaluation"] = final_evaluation()
	data["probation_safeguard_forecast"] = probation_safeguard_forecast()
	return data


## Primitive-only, versioned representation safe for JSON.stringify().
func to_dictionary() -> Dictionary:
	var records: Array[Dictionary] = []
	for record in shift_records:
		records.append(record.to_dictionary())
	return {
		"schema_id": SCHEMA_ID,
		"schema_version": SCHEMA_VERSION,
		"challenge_contract_id": String(challenge_contract_id),
		"campaign_length": CAMPAIGN_LENGTH,
		"completed_shifts": completed_shifts,
		"probation_score": probation_score,
		"probation_rank": String(probation_rank),
		"outcome": String(outcome),
		"final_reason": final_reason,
		"totals": {
			"cumulative_welfare": cumulative_welfare,
			"cumulative_compliance": cumulative_compliance,
			"cumulative_farmer_favor": cumulative_farmer_favor,
			"total_credited_cents": total_credited_cents,
			"total_eggs": total_eggs,
			"total_cracked_eggs": total_cracked_eggs,
			"total_overdue_files": total_overdue_files,
			"total_rework": total_rework,
		},
		"milestone": {
			"available": is_milestone_choice_available(),
			"selected_id": String(chosen_milestone_id),
			"unlocked_feature_ids": _string_array(unlocked_feature_ids),
		},
		"source_cursors": {
			"last_closing_fund_cents": _last_closing_fund_cents,
			"last_rework_total_created": _last_source_rework_total,
		},
		"shift_records": records,
	}


static func from_dictionary(data: Dictionary) -> CampaignState:
	var migrated := _migrate_dictionary(data)
	var errors := _validate_current_dictionary(migrated)
	if not errors.is_empty():
		push_warning("Campaign save rejected: %s" % "; ".join(errors))
		return null
	var state := CampaignState.new()
	state._hydrate_unchecked(migrated)
	return state


## Schema v1 predates selectable probation contracts and therefore represents
## the exact shipped Standard Filing thresholds. Migration never trusts a
## challenge-like field smuggled into a legacy payload.
static func _migrate_dictionary(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	if (
		String(migrated.get("schema_id", "")) == SCHEMA_ID
		and _integer_value(migrated.get("schema_version", -1), -1) == 1
	):
		migrated["schema_version"] = SCHEMA_VERSION
		migrated["challenge_contract_id"] = String(CHALLENGE_STANDARD_FILING)
	return migrated


## Returns every discovered error instead of failing at the first malformed
## field, allowing a save manager to show diagnostics or fall back to a backup.
static func validate_dictionary(data: Dictionary) -> PackedStringArray:
	return _validate_current_dictionary(_migrate_dictionary(data))


static func _validate_current_dictionary(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	_require_string(data, "schema_id", errors)
	_require_integer(data, "schema_version", SCHEMA_VERSION, SCHEMA_VERSION, errors)
	_require_string(data, "challenge_contract_id", errors)
	_require_integer(data, "campaign_length", CAMPAIGN_LENGTH, CAMPAIGN_LENGTH, errors)
	_require_integer(data, "completed_shifts", 0, CAMPAIGN_LENGTH, errors)
	_require_integer(data, "probation_score", 0, 100, errors)
	_require_string(data, "probation_rank", errors)
	_require_string(data, "outcome", errors)
	_require_string(data, "final_reason", errors)
	if String(data.get("schema_id", "")) != SCHEMA_ID:
		errors.append("schema_id is not supported")
	if _integer_value(data.get("schema_version", -1), -1) != SCHEMA_VERSION:
		errors.append("schema_version is not supported")
	var persisted_challenge_id := String(data.get("challenge_contract_id", ""))
	var persisted_challenge := challenge_contract(StringName(persisted_challenge_id))
	if persisted_challenge.is_empty():
		errors.append("challenge_contract_id is not supported")
	elif persisted_challenge_id != String(persisted_challenge.get("id", "")):
		errors.append("challenge_contract_id must use its canonical stable ID")

	var totals_value: Variant = data.get("totals")
	if typeof(totals_value) != TYPE_DICTIONARY:
		errors.append("totals must be a Dictionary")
	else:
		var totals := totals_value as Dictionary
		for key in [
			"cumulative_welfare", "cumulative_compliance", "cumulative_farmer_favor",
			"total_credited_cents", "total_eggs", "total_cracked_eggs",
			"total_overdue_files", "total_rework",
		]:
			_require_integer(totals, key, 0, 2_000_000_000, errors, "totals.")

	var milestone_value: Variant = data.get("milestone")
	if typeof(milestone_value) != TYPE_DICTIONARY:
		errors.append("milestone must be a Dictionary")
	else:
		var milestone := milestone_value as Dictionary
		_require_bool(milestone, "available", errors, "milestone.")
		_require_string(milestone, "selected_id", errors, "milestone.")
		_require_string_array(milestone, "unlocked_feature_ids", errors, "milestone.")

	var cursors_value: Variant = data.get("source_cursors")
	if typeof(cursors_value) != TYPE_DICTIONARY:
		errors.append("source_cursors must be a Dictionary")
	else:
		var cursors := cursors_value as Dictionary
		_require_integer(cursors, "last_closing_fund_cents", 0, 2_000_000_000, errors, "source_cursors.")
		_require_integer(cursors, "last_rework_total_created", 0, 2_000_000_000, errors, "source_cursors.")

	var records_value: Variant = data.get("shift_records")
	if typeof(records_value) != TYPE_ARRAY:
		errors.append("shift_records must be an Array")
	elif _is_integer_number(data.get("completed_shifts", -1)):
		var records := records_value as Array
		if records.size() != int(data["completed_shifts"]):
			errors.append("shift_records count must equal completed_shifts")
		var probe := CampaignState.new()
		for index in records.size():
			var record_value: Variant = records[index]
			if typeof(record_value) != TYPE_DICTIONARY:
				errors.append("shift_records[%d] must be a Dictionary" % index)
				continue
			probe._validate_saved_record(record_value as Dictionary, index + 1, errors)

	if not errors.is_empty():
		return errors

	var candidate := CampaignState.new()
	candidate._hydrate_unchecked(data)
	candidate._validate_cross_field_invariants(data, errors)
	return errors


static func rank_for_score(score: int) -> StringName:
	if score < 20:
		return RANK_TERMINATED
	if score < 40:
		return RANK_CRITICAL_REVIEW
	if score < 60:
		return RANK_PROBATIONARY
	if score < 80:
		return RANK_TRUSTED_LAYER
	return RANK_GOLDEN_MANAGEMENT


static func rank_display_name(rank_id: StringName) -> String:
	match rank_id:
		RANK_TERMINATED:
			return "Contract Terminated"
		RANK_CRITICAL_REVIEW:
			return "Critical Review"
		RANK_PROBATIONARY:
			return "Probationary Manager"
		RANK_TRUSTED_LAYER:
			return "Trusted Layer"
		RANK_GOLDEN_MANAGEMENT:
			return "Golden Management Track"
		_:
			return "Unknown Rank"


func _validate_shift_input(report: Dictionary, closing_snapshot: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if outcome != OUTCOME_IN_PROGRESS:
		errors.append("campaign is already final")
	if completed_shifts >= CAMPAIGN_LENGTH:
		errors.append("all five probation shifts are complete")
	if completed_shifts >= MILESTONE_AFTER_SHIFT and chosen_milestone_id == &"":
		errors.append("choose one probation milestone before shift three")

	_require_integer(report, "day", completed_shifts + 1, completed_shifts + 1, errors, "report.")
	_require_integer(report, "eggs", 0, 100_000, errors, "report.")
	_require_integer(report, "quota", 1, 100_000, errors, "report.")
	_require_integer(report, "cracked", 0, 100_000, errors, "report.")
	_require_integer(report, "overdue_claims", 0, 100_000, errors, "report.")
	if _is_integer_number(report.get("eggs")) and _is_integer_number(report.get("cracked")):
		if int(report["cracked"]) > int(report["eggs"]):
			errors.append("report.cracked cannot exceed report.eggs")

	if report.has("credited_cents"):
		_require_integer(report, "credited_cents", 0, 2_000_000_000, errors, "report.")
	elif report.has("shift_credited_cents"):
		_require_integer(report, "shift_credited_cents", 0, 2_000_000_000, errors, "report.")
	else:
		_require_integer(report, "closing_fund_cents", 0, 2_000_000_000, errors, "report.")
		_require_integer(report, "feed_cost_cents", 0, 2_000_000_000, errors, "report.")

	if report.has("rework_total_created"):
		_require_integer(report, "rework_total_created", _last_source_rework_total, 2_000_000_000, errors, "report.")
	elif report.has("rework_created"):
		_require_integer(report, "rework_created", 0, 100_000, errors, "report.")
	else:
		_require_integer(report, "rework_waiting", 0, 100_000, errors, "report.")
		_require_integer(report, "rework_due_next_shift", 0, 100_000, errors, "report.")

	var welfare := _extract_welfare(report, closing_snapshot)
	if welfare < 0:
		errors.append("closing welfare requires report.welfare, snapshot.welfare, or snapshot.workers")
	var compliance := _extract_percentage(report, closing_snapshot, "compliance", "compliance")
	if compliance < 0:
		errors.append("closing compliance is required")
	var favor := _extract_percentage(report, closing_snapshot, "farmer_favor", "executive_confidence")
	if favor < 0:
		errors.append("closing farmer favor / executive_confidence is required")
	return errors


func _normalize_shift(report: Dictionary, closing_snapshot: Dictionary) -> CampaignShiftRecord:
	var record := CampaignShiftRecord.new()
	record.shift_number = completed_shifts + 1
	record.eggs = int(report["eggs"])
	record.quota = int(report["quota"])
	record.met_quota = record.eggs >= record.quota
	record.cracked_eggs = int(report["cracked"])
	record.crack_rate_basis_points = _basis_points(record.cracked_eggs, record.eggs)
	record.overdue_files = int(report["overdue_claims"])
	if report.has("rework_total_created"):
		record.rework = int(report["rework_total_created"]) - _last_source_rework_total
	elif report.has("rework_created"):
		record.rework = int(report["rework_created"])
	else:
		record.rework = int(report["rework_waiting"]) + int(report["rework_due_next_shift"])
	if report.has("credited_cents"):
		record.credited_cents = int(report["credited_cents"])
	elif report.has("shift_credited_cents"):
		record.credited_cents = int(report["shift_credited_cents"])
	else:
		var spending := int(report.get("management_spending_cents", 0))
		record.credited_cents = maxi(
			0,
			int(report["closing_fund_cents"])
			- _last_closing_fund_cents
			+ int(report["feed_cost_cents"])
			+ spending
		)
	record.welfare = _extract_welfare(report, closing_snapshot)
	record.compliance = _extract_percentage(report, closing_snapshot, "compliance", "compliance")
	record.farmer_favor = _extract_percentage(report, closing_snapshot, "farmer_favor", "executive_confidence")
	return record


func _evaluate_objectives(record: CampaignShiftRecord) -> void:
	var metrics := record.metrics_dictionary()
	for objective in _objectives_for_shift(record.shift_number):
		var completed := objective.is_completed(metrics)
		record.objective_results.append({
			"id": String(objective.id),
			"completed": completed,
			"score_awarded": objective.score_award if completed else 0,
		})


func _score_shift(record: CampaignShiftRecord) -> int:
	var delta := 0
	for component in _score_components(record):
		delta += int(component.get("delta", 0))
	return delta


func _score_components(record: CampaignShiftRecord) -> Array[Dictionary]:
	var components: Array[Dictionary] = []
	var objective_award := 0
	var completed_objectives := 0
	for result in record.objective_results:
		objective_award += int(result.get("score_awarded", 0))
		if bool(result.get("completed", false)):
			completed_objectives += 1
	var all_objectives := (
		not record.objective_results.is_empty()
		and completed_objectives == record.objective_results.size()
	)
	var objective_bundle := 3 if all_objectives else 0
	components.append(_score_component(
		&"probation_orders",
		"PROBATION ORDERS",
		"%d / %d filed%s" % [
			completed_objectives,
			record.objective_results.size(),
			" · clean sweep +3" if all_objectives else "",
		],
		objective_award + objective_bundle,
	))

	var quota_delta := 3 if record.met_quota else -5
	components.append(_score_component(
		&"daily_clutch",
		"DAILY CLUTCH",
		"%d / %d eggs" % [record.eggs, record.quota],
		quota_delta,
	))

	var shell_delta := 0
	if record.crack_rate_basis_points <= 1000:
		shell_delta = 2
	elif record.crack_rate_basis_points > 2000:
		shell_delta = -3
	components.append(_score_component(
		&"shell_quality",
		"SHELL QUALITY",
		"%d cracked · %.1f%%" % [
			record.cracked_eggs,
			float(record.crack_rate_basis_points) / 100.0,
		],
		shell_delta,
	))

	var overdue_delta := 2 if record.overdue_files == 0 else -mini(record.overdue_files, 4)
	var rework_delta := 1 if record.rework == 0 else -mini(record.rework, 3)
	components.append(_score_component(
		&"queue_control",
		"QUEUE CONTROL",
		"%d overdue %s · %d rework %s" % [
			record.overdue_files, _signed_score(overdue_delta),
			record.rework, _signed_score(rework_delta),
		],
		overdue_delta + rework_delta,
	))

	var welfare_delta := 1 if record.welfare >= 70 else (-3 if record.welfare < 45 else 0)
	var compliance_delta := 1 if record.compliance >= 80 else (-3 if record.compliance < 55 else 0)
	var favor_delta := 1 if record.farmer_favor >= 70 else (-3 if record.farmer_favor < 45 else 0)
	components.append(_score_component(
		&"flock_safeguards",
		"FLOCK SAFEGUARDS",
		"welfare %d %s · obedience %d %s · favor %d %s" % [
			record.welfare, _signed_score(welfare_delta),
			record.compliance, _signed_score(compliance_delta),
			record.farmer_favor, _signed_score(favor_delta),
		],
		welfare_delta + compliance_delta + favor_delta,
	))
	return components


func _score_component(id: StringName, label: String, detail: String, delta: int) -> Dictionary:
	return {
		"id": String(id),
		"label": label,
		"detail": detail,
		"delta": delta,
		"tone": &"positive" if delta > 0 else (&"negative" if delta < 0 else &"neutral"),
	}


func _score_before_shift(shift_number: int) -> int:
	var score := STARTING_SCORE
	for record in shift_records:
		if record.shift_number >= shift_number:
			break
		score = record.score_after
		if record.shift_number == MILESTONE_AFTER_SHIFT and chosen_milestone_id != &"":
			var milestone := _milestone_by_id(chosen_milestone_id)
			if milestone != null:
				score = clampi(score + milestone.score_bonus, 0, 100)
	return score


func _signed_score(value: int) -> String:
	return "+%d" % value if value > 0 else str(value)


func _refresh_outcome() -> void:
	probation_rank = rank_for_score(probation_score)
	if probation_score < 20:
		outcome = OUTCOME_FAILED
		final_reason = "The farmer terminated probation after confidence collapsed."
		return
	if completed_shifts < CAMPAIGN_LENGTH:
		outcome = OUTCOME_IN_PROGRESS
		final_reason = "Complete five shifts without sacrificing the flock."
		return
	var passed := bool(probation_safeguard_forecast().get("all_pass", false))
	if passed:
		outcome = OUTCOME_PASSED
		final_reason = "Probation passed: the flock endured and the farmer approved the ledger."
	else:
		outcome = OUTCOME_FAILED
		final_reason = "Probation failed: the final ledger missed one or more flock safeguards."


func _objectives_for_shift(shift_number: int) -> Array[CampaignObjective]:
	var objectives: Array[CampaignObjective] = []
	match shift_number:
		1:
			objectives.assign([
				CampaignObjective.new(&"opening_clutch", "Opening clutch", "Gather at least 18 eggs.", &"eggs", CampaignObjective.COMPARISON_MINIMUM, 18, 3),
				CampaignObjective.new(&"sound_start", "Sound start", "Keep cracked eggs at or below 20%.", &"crack_rate_basis_points", CampaignObjective.COMPARISON_MAXIMUM, 2000, 3),
				CampaignObjective.new(&"settled_flock", "Settled flock", "Close with welfare at 48 or better.", &"welfare", CampaignObjective.COMPARISON_MINIMUM, 48, 3),
			])
		2:
			objectives.assign([
				CampaignObjective.new(&"meet_the_clutch", "Meet the clutch", "Meet the farmer's daily quota.", &"quota_met", CampaignObjective.COMPARISON_EQUAL, 1, 3),
				CampaignObjective.new(&"orderly_coop", "Orderly coop", "Close with compliance at 68 or better.", &"compliance", CampaignObjective.COMPARISON_MINIMUM, 68, 3),
				CampaignObjective.new(&"trim_the_trays", "Trim the trays", "Leave no more than three overdue files.", &"overdue_files", CampaignObjective.COMPARISON_MAXIMUM, 3, 3),
			])
		3:
			objectives.assign([
				CampaignObjective.new(&"prove_the_plan", "Prove the plan", "Meet quota after choosing a specialization.", &"quota_met", CampaignObjective.COMPARISON_EQUAL, 1, 3),
				CampaignObjective.new(&"farmer_confidence", "Farmer confidence", "Raise farmer favor to at least 52.", &"farmer_favor", CampaignObjective.COMPARISON_MINIMUM, 52, 3),
				CampaignObjective.new(&"no_rework_spiral", "No rework spiral", "Create no more than three rework files.", &"rework", CampaignObjective.COMPARISON_MAXIMUM, 3, 3),
			])
		4:
			objectives.assign([
				CampaignObjective.new(&"clear_the_nests", "Clear the nests", "Leave no more than one overdue file.", &"overdue_files", CampaignObjective.COMPARISON_MAXIMUM, 1, 3),
				CampaignObjective.new(&"audit_ready", "Audit ready", "Close with compliance at 74 or better.", &"compliance", CampaignObjective.COMPARISON_MINIMUM, 74, 3),
				CampaignObjective.new(&"clean_shells", "Clean shells", "Keep cracks at or below 15%.", &"crack_rate_basis_points", CampaignObjective.COMPARISON_MAXIMUM, 1500, 3),
			])
		5:
			objectives.assign([
				CampaignObjective.new(&"final_clutch", "Final clutch", "Meet the final quota.", &"quota_met", CampaignObjective.COMPARISON_EQUAL, 1, 3),
				CampaignObjective.new(&"farmer_signoff", "Farmer sign-off", "Close with farmer favor at 60 or better.", &"farmer_favor", CampaignObjective.COMPARISON_MINIMUM, 60, 3),
				CampaignObjective.new(&"flock_still_standing", "Flock still standing", "Close with welfare at 55 or better.", &"welfare", CampaignObjective.COMPARISON_MINIMUM, 55, 3),
			])
	return objectives


func _milestone_choices() -> Array[CampaignMilestoneChoice]:
	var choices: Array[CampaignMilestoneChoice] = []
	choices.assign([
		CampaignMilestoneChoice.new(
			&"padded_perches",
			"Padded Perches",
			"Fund humane workstation breaks before productivity hardens into burnout.",
			&"welfare_breaks",
			"Welfare Break Protocol",
			2,
			{"stress_gain_percent": -12, "fatigue_gain_percent": -10},
			{
				"label": "FLOCK STEWARDSHIP",
				"summary": "Build durable output through recovery, shared credit, and a flock that can still work tomorrow.",
				"strengths": ["WELFARE", "COMPLIANCE", "RECOVERY"],
				"watchouts": ["FARMER FAVOR", "SHELL SUPPORT"],
				"playbook": "Favor Sustainable Flock and Share Credit, then rotate in Shell Assurance when the crack ledger tightens.",
			}
		),
		CampaignMilestoneChoice.new(
			&"shell_quality_lab",
			"Shell Quality Lab",
			"Catch brittle paperwork before another cracked egg becomes tomorrow's rework.",
			&"shell_quality_checks",
			"Shell Quality Checks",
			2,
			{"crack_risk_basis_points": -250},
			{
				"label": "SHELL ASSURANCE",
				"summary": "Win through clean output, controlled rework, and precise support at the desks.",
				"strengths": ["SHELL QUALITY", "COMPLIANCE", "REWORK"],
				"watchouts": ["FLOCK WELFARE", "RECOVERY DAYS"],
				"playbook": "Pair Shell Assurance with recovery shifts and complementary nest support instead of stacking quality hardware twice.",
			}
		),
		CampaignMilestoneChoice.new(
			&"farmer_credit_line",
			"Farmer Credit Line",
			"Package the flock's output into a presentation the farmer can monetize.",
			&"farmer_credit_bonus",
			"Farmer Credit Bonus",
			2,
			{"egg_value_bonus_cents": 25},
			{
				"label": "HARVEST PARTNERSHIP",
				"summary": "Turn output and farmer confidence into capital without spending the flock to get there.",
				"strengths": ["FARMER FAVOR", "FEED FUND", "OUTPUT"],
				"watchouts": ["FLOCK WELFARE", "QUOTA PRESSURE"],
				"playbook": "Use Record Harvest selectively, share credit often, and reinvest the first clutch in comfort before applying more pressure.",
			}
		),
	])
	return choices


func _milestone_by_id(choice_id: StringName) -> CampaignMilestoneChoice:
	for choice in _milestone_choices():
		if choice.id == choice_id:
			return choice
	return null


func _extract_welfare(report: Dictionary, closing_snapshot: Dictionary) -> int:
	if _is_percentage(report.get("welfare")):
		return int(round(float(report["welfare"])))
	if _is_percentage(closing_snapshot.get("welfare")):
		return int(round(float(closing_snapshot["welfare"])))
	var workers_value: Variant = closing_snapshot.get("workers")
	if typeof(workers_value) != TYPE_ARRAY or (workers_value as Array).is_empty():
		return -1
	var total := 0
	var count := 0
	for worker_value in workers_value as Array:
		if typeof(worker_value) != TYPE_DICTIONARY:
			return -1
		var worker := worker_value as Dictionary
		if not _is_percentage(worker.get("morale")):
			return -1
		var morale := int(round(float(worker["morale"])))
		var stress := int(round(float(worker.get("stress", 0.0)))) if _is_percentage(worker.get("stress", 0.0)) else 0
		var fatigue := int(round(float(worker.get("fatigue", 0.0)))) if _is_percentage(worker.get("fatigue", 0.0)) else 0
		total += clampi(morale + 20 - _rounded_average(stress, 3) - _rounded_average(fatigue, 5), 0, 100)
		count += 1
	return _rounded_average(total, count)


func _extract_percentage(
	report: Dictionary,
	closing_snapshot: Dictionary,
	report_key: String,
	snapshot_key: String
) -> int:
	if _is_percentage(report.get(report_key)):
		return int(round(float(report[report_key])))
	if _is_percentage(closing_snapshot.get(snapshot_key)):
		return int(round(float(closing_snapshot[snapshot_key])))
	return -1


func _hydrate_unchecked(data: Dictionary) -> void:
	# _validate_current_dictionary() has already required the exact canonical ID.
	# Hydration is the only path besides pristine selection that may write the
	# private authority, and restored files are locked immediately below.
	_challenge_contract_id = StringName(String(data["challenge_contract_id"]))
	_challenge_contract_selected = true
	completed_shifts = int(data["completed_shifts"])
	probation_score = int(data["probation_score"])
	probation_rank = StringName(data["probation_rank"])
	outcome = StringName(data["outcome"])
	final_reason = String(data["final_reason"])
	var totals := data["totals"] as Dictionary
	cumulative_welfare = int(totals["cumulative_welfare"])
	cumulative_compliance = int(totals["cumulative_compliance"])
	cumulative_farmer_favor = int(totals["cumulative_farmer_favor"])
	total_credited_cents = int(totals["total_credited_cents"])
	total_eggs = int(totals["total_eggs"])
	total_cracked_eggs = int(totals["total_cracked_eggs"])
	total_overdue_files = int(totals["total_overdue_files"])
	total_rework = int(totals["total_rework"])
	var milestone := data["milestone"] as Dictionary
	chosen_milestone_id = StringName(milestone["selected_id"])
	unlocked_feature_ids.clear()
	for unlock_value in milestone["unlocked_feature_ids"] as Array:
		unlocked_feature_ids.append(StringName(unlock_value))
	var cursors := data["source_cursors"] as Dictionary
	_last_closing_fund_cents = int(cursors["last_closing_fund_cents"])
	_last_source_rework_total = int(cursors["last_rework_total_created"])
	shift_records.clear()
	for record_value in data["shift_records"] as Array:
		shift_records.append(CampaignShiftRecord.from_dictionary(record_value as Dictionary))


func _validate_saved_record(data: Dictionary, expected_shift: int, errors: PackedStringArray) -> void:
	var prefix := "shift_records[%d]." % (expected_shift - 1)
	_require_integer(data, "shift_number", expected_shift, expected_shift, errors, prefix)
	_require_integer(data, "eggs", 0, 100_000, errors, prefix)
	_require_integer(data, "quota", 1, 100_000, errors, prefix)
	_require_bool(data, "met_quota", errors, prefix)
	_require_integer(data, "cracked_eggs", 0, 100_000, errors, prefix)
	_require_integer(data, "crack_rate_basis_points", 0, 10_000, errors, prefix)
	_require_integer(data, "overdue_files", 0, 100_000, errors, prefix)
	_require_integer(data, "rework", 0, 100_000, errors, prefix)
	_require_integer(data, "credited_cents", 0, 2_000_000_000, errors, prefix)
	_require_integer(data, "welfare", 0, 100, errors, prefix)
	_require_integer(data, "compliance", 0, 100, errors, prefix)
	_require_integer(data, "farmer_favor", 0, 100, errors, prefix)
	_require_integer(data, "score_delta", -100, 100, errors, prefix)
	_require_integer(data, "score_after", 0, 100, errors, prefix)
	_require_string(data, "rank_after", errors, prefix)
	var results_value: Variant = data.get("objective_results")
	if typeof(results_value) != TYPE_ARRAY:
		errors.append(prefix + "objective_results must be an Array")
		return
	var definitions := _objectives_for_shift(expected_shift)
	var results := results_value as Array
	if results.size() != definitions.size():
		errors.append(prefix + "objective_results count does not match the shift catalog")
		return
	for index in results.size():
		var result_value: Variant = results[index]
		if typeof(result_value) != TYPE_DICTIONARY:
			errors.append(prefix + "objective_results[%d] must be a Dictionary" % index)
			continue
		var result := result_value as Dictionary
		_require_string(result, "id", errors, prefix + "objective_results[%d]." % index)
		_require_bool(result, "completed", errors, prefix + "objective_results[%d]." % index)
		_require_integer(result, "score_awarded", 0, 100, errors, prefix + "objective_results[%d]." % index)


func _validate_cross_field_invariants(data: Dictionary, errors: PackedStringArray) -> void:
	if probation_rank != rank_for_score(probation_score):
		errors.append("probation_rank does not match probation_score")
	var expected_score := STARTING_SCORE
	var expected_totals := {
		"cumulative_welfare": 0,
		"cumulative_compliance": 0,
		"cumulative_farmer_favor": 0,
		"total_credited_cents": 0,
		"total_eggs": 0,
		"total_cracked_eggs": 0,
		"total_overdue_files": 0,
		"total_rework": 0,
	}
	for record in shift_records:
		if record.met_quota != (record.eggs >= record.quota):
			errors.append("shift %d met_quota is inconsistent" % record.shift_number)
		if record.cracked_eggs > record.eggs:
			errors.append("shift %d cracked_eggs exceeds eggs" % record.shift_number)
		if record.crack_rate_basis_points != _basis_points(record.cracked_eggs, record.eggs):
			errors.append("shift %d crack rate is inconsistent" % record.shift_number)
		var definitions := _objectives_for_shift(record.shift_number)
		var metrics := record.metrics_dictionary()
		for index in mini(definitions.size(), record.objective_results.size()):
			var objective := definitions[index]
			var result := record.objective_results[index]
			var completed := objective.is_completed(metrics)
			if StringName(result.get("id", "")) != objective.id:
				errors.append("shift %d objective order/id is inconsistent" % record.shift_number)
			if bool(result.get("completed", false)) != completed:
				errors.append("shift %d objective completion is inconsistent" % record.shift_number)
			var expected_award := objective.score_award if completed else 0
			if int(result.get("score_awarded", -1)) != expected_award:
				errors.append("shift %d objective score is inconsistent" % record.shift_number)
		var expected_delta := _score_shift(record)
		if record.score_delta != expected_delta:
			errors.append("shift %d score_delta is inconsistent" % record.shift_number)
		expected_score = clampi(expected_score + expected_delta, 0, 100)
		if record.score_after != expected_score:
			errors.append("shift %d score_after is inconsistent" % record.shift_number)
		if record.rank_after != rank_for_score(record.score_after):
			errors.append("shift %d rank_after is inconsistent" % record.shift_number)
		expected_totals["cumulative_welfare"] += record.welfare
		expected_totals["cumulative_compliance"] += record.compliance
		expected_totals["cumulative_farmer_favor"] += record.farmer_favor
		expected_totals["total_credited_cents"] += record.credited_cents
		expected_totals["total_eggs"] += record.eggs
		expected_totals["total_cracked_eggs"] += record.cracked_eggs
		expected_totals["total_overdue_files"] += record.overdue_files
		expected_totals["total_rework"] += record.rework
		if record.shift_number == MILESTONE_AFTER_SHIFT and chosen_milestone_id != &"":
			var choice := _milestone_by_id(chosen_milestone_id)
			if choice != null:
				expected_score = clampi(expected_score + choice.score_bonus, 0, 100)
	if expected_score != probation_score:
		errors.append("probation_score is inconsistent with shift records and milestone")
	var totals := data["totals"] as Dictionary
	for key in expected_totals:
		if int(totals[key]) != int(expected_totals[key]):
			errors.append("totals.%s is inconsistent with shift records" % key)

	var selected_choice := _milestone_by_id(chosen_milestone_id) if chosen_milestone_id != &"" else null
	if chosen_milestone_id != &"" and selected_choice == null:
		errors.append("milestone.selected_id is unknown")
	if chosen_milestone_id != &"" and completed_shifts < MILESTONE_AFTER_SHIFT:
		errors.append("milestone cannot be selected before shift two")
	if chosen_milestone_id == &"" and completed_shifts > MILESTONE_AFTER_SHIFT:
		errors.append("campaign cannot advance past shift two without a milestone")
	var expected_unlocks: Array[StringName] = []
	if selected_choice != null:
		expected_unlocks.append(selected_choice.unlock_id)
	if unlocked_feature_ids != expected_unlocks:
		errors.append("milestone unlock does not match the selected choice")
	if bool((data["milestone"] as Dictionary)["available"]) != is_milestone_choice_available():
		errors.append("milestone.available is inconsistent")

	var expected_outcome := outcome
	var expected_reason := final_reason
	_refresh_outcome()
	if outcome != expected_outcome:
		errors.append("outcome is inconsistent with campaign performance")
	if final_reason != expected_reason:
		errors.append("final_reason is inconsistent with outcome")

func _probation_safeguard_specifications() -> Array[Dictionary]:
	var contract_criteria := challenge_contract_snapshot().get("criteria", {}) as Dictionary
	return [
		{
			"id": "score",
			"label": "PROBATION SCORE",
			"metric": "probation_score",
			"comparison": "minimum",
			"target": int(contract_criteria.get("minimum_score", MIN_PASS_SCORE)),
			"unit": "points",
		},
		{
			"id": "welfare",
			"label": "FLOCK WELFARE",
			"metric": "average_welfare",
			"comparison": "minimum",
			"target": int(contract_criteria.get("minimum_welfare", MIN_PASS_WELFARE)),
			"unit": "points",
		},
		{
			"id": "compliance",
			"label": "COOP COMPLIANCE",
			"metric": "average_compliance",
			"comparison": "minimum",
			"target": int(contract_criteria.get("minimum_compliance", MIN_PASS_COMPLIANCE)),
			"unit": "points",
		},
		{
			"id": "farmer_favor",
			"label": "FARMER FAVOR",
			"metric": "average_farmer_favor",
			"comparison": "minimum",
			"target": int(contract_criteria.get("minimum_farmer_favor", MIN_PASS_FARMER_FAVOR)),
			"unit": "points",
		},
		{
			"id": "crack_rate",
			"label": "SHELL CRACK RATE",
			"metric": "crack_rate_basis_points",
			"comparison": "maximum",
			"target": int(contract_criteria.get(
				"maximum_crack_rate_basis_points",
				MAX_PASS_CRACK_RATE_BASIS_POINTS,
			)),
			"unit": "basis_points",
		},
	]


static func _basis_points(numerator: int, denominator: int) -> int:
	if denominator <= 0:
		return 0
	return clampi(roundi(float(numerator) * 10_000.0 / float(denominator)), 0, 10_000)


static func _rounded_average(total: int, count: int) -> int:
	if count <= 0:
		return 0
	return roundi(float(total) / float(count))


static func _string_array(values: Array[StringName]) -> Array[String]:
	var strings: Array[String] = []
	for value in values:
		strings.append(String(value))
	return strings


static func _is_percentage(value: Variant) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var numeric := float(value)
	return not is_nan(numeric) and not is_inf(numeric) and numeric >= 0.0 and numeric <= 100.0


static func _is_integer_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) != TYPE_FLOAT:
		return false
	var numeric := float(value)
	return not is_nan(numeric) and not is_inf(numeric) and numeric == floor(numeric)


static func _integer_value(value: Variant, fallback: int) -> int:
	return int(value) if _is_integer_number(value) else fallback


static func _require_integer(
	data: Dictionary,
	key: String,
	minimum: int,
	maximum: int,
	errors: PackedStringArray,
	prefix: String = ""
) -> void:
	if not data.has(key) or not _is_integer_number(data[key]):
		errors.append(prefix + key + " must be an integer")
		return
	var value := int(data[key])
	if value < minimum or value > maximum:
		errors.append(prefix + key + " is outside its valid range")


static func _require_string(data: Dictionary, key: String, errors: PackedStringArray, prefix: String = "") -> void:
	if not data.has(key) or typeof(data[key]) not in [TYPE_STRING, TYPE_STRING_NAME]:
		errors.append(prefix + key + " must be a String")


static func _require_bool(data: Dictionary, key: String, errors: PackedStringArray, prefix: String = "") -> void:
	if not data.has(key) or typeof(data[key]) != TYPE_BOOL:
		errors.append(prefix + key + " must be a bool")


static func _require_string_array(data: Dictionary, key: String, errors: PackedStringArray, prefix: String = "") -> void:
	if not data.has(key) or typeof(data[key]) != TYPE_ARRAY:
		errors.append(prefix + key + " must be an Array")
		return
	for value in data[key] as Array:
		if typeof(value) not in [TYPE_STRING, TYPE_STRING_NAME]:
			errors.append(prefix + key + " must contain only strings")
			return
