class_name CareerCommendations
extends RefCounted

## A presentation-safe achievement ledger derived entirely from permanent or
## best-ever facts already owned by CampaignState, SeniorRoostState, and the
## simulation save. No parallel save schema or hidden economy reward is needed:
## once a commendation is filed, its source fact cannot legitimately regress.

const FIRST_EGG: StringName = &"first_egg"
const DOCTRINE_FILED: StringName = &"doctrine_filed"
const CLEAN_DOZEN: StringName = &"clean_dozen"
const MUTUAL_KEEPER: StringName = &"mutual_keeper"
const ADAPTIVE_CASEWORK: StringName = &"adaptive_casework"
const PROBATION_SURVIVOR: StringName = &"probation_survivor"
const BUREAU_BUILDER: StringName = &"bureau_builder"
const FULL_ROOST: StringName = &"full_roost"
const SENIOR_TRANSFER: StringName = &"senior_transfer"
const BOARD_SEAL: StringName = &"board_seal"
const BOARD_PORTFOLIO: StringName = &"board_portfolio"
const COMPLETE_BOARD_LEDGER: StringName = &"complete_board_ledger"
const BOARD_PORTFOLIO_TARGET := 3
const BOARD_BOOK_TOTAL := 7

const IDS: Array[StringName] = [
	FIRST_EGG,
	DOCTRINE_FILED,
	CLEAN_DOZEN,
	MUTUAL_KEEPER,
	ADAPTIVE_CASEWORK,
	PROBATION_SURVIVOR,
	BUREAU_BUILDER,
	FULL_ROOST,
	SENIOR_TRANSFER,
	BOARD_SEAL,
	BOARD_PORTFOLIO,
	COMPLETE_BOARD_LEDGER,
]


static func definitions() -> Array[Dictionary]:
	return [
		_definition(
			FIRST_EGG,
			"FIRST EGG, FULL CREDIT",
			"Deliver the bureau's first credited egg.",
			"Brass intake stamp",
		),
		_definition(
			DOCTRINE_FILED,
			"DOCTRINE STAMPED",
			"Choose one permanent probation specialty after Shift 2.",
			"Specialist file ribbon",
		),
		_definition(
			CLEAN_DOZEN,
			"A CLEAN DOZEN",
			"Build a best-ever chain of twelve sound or golden eggs.",
			"Candling-room seal",
		),
		_definition(
			MUTUAL_KEEPER,
			"MUTUAL ASSURANCE",
			"Fulfill three Farm Mutual binders without rewriting their terms.",
			"Three-kernel contract stamp",
		),
		_definition(
			ADAPTIVE_CASEWORK,
			"WINGS BOTH WAYS",
			"Use an active counterweight pivot in all three recurring case pairs.",
			"Three-hinge adaptability stamp",
		),
		_definition(
			PROBATION_SURVIVOR,
			"PROBATION SURVIVOR",
			"Pass all five probation shifts and every required safeguard.",
			"Permanent career-file stripe",
		),
		_definition(
			BUREAU_BUILDER,
			"BUREAU BUILDER",
			"Commission three permanent facility tiers.",
			"Capital-plan embossing",
		),
		_definition(
			FULL_ROOST,
			"FULL ROOST",
			"Authorize all six connected office perches.",
			"West-wing occupancy stamp",
		),
		_definition(
			SENIOR_TRANSFER,
			"UPSTAIRS TRANSFER",
			"Enter the recurring Senior Roost career ledger.",
			"Senior filing tab",
		),
		_definition(
			BOARD_SEAL,
			"BOARD-APPROVED BIRD",
			"Earn one permanent Board Mandate seal.",
			"Board seal in the Coop archive",
		),
		_definition(
			BOARD_PORTFOLIO,
			"THREE BOOKS, ONE ROOST",
			"Fulfill three different annual Board Books, not merely the same safe filing three times.",
			"Three-tab strategy portfolio",
		),
		_definition(
			COMPLETE_BOARD_LEDGER,
			"THE WHOLE BOARD BOOK",
			"Fulfill all seven distinct annual Board Books across every mandate tier.",
			"Seven-tab brass master index",
		),
	]


static func evaluate(
	simulation: Dictionary,
	campaign: Dictionary,
	senior: Dictionary = {},
) -> Dictionary:
	var eggs_total := maxi(0, int(simulation.get("eggs_total", 0)))
	var best_quality_streak := maxi(0, int(simulation.get("best_quality_streak", 0)))
	var fulfilled_contracts := maxi(0, int(simulation.get("market_contracts_succeeded_total", 0)))
	var office_capacity := clampi(int(simulation.get("office_capacity", 4)), 0, 6)
	var facility_tiers := _facility_tier_total(simulation.get("owned_facilities", {}))
	var pivot_mastery_value: Variant = simulation.get("incident_pivot_mastery", {})
	if not pivot_mastery_value is Dictionary:
		var case_docket_value: Variant = simulation.get("case_docket", {})
		if case_docket_value is Dictionary:
			pivot_mastery_value = (case_docket_value as Dictionary).get("pivot_mastery", {})
	var pivot_mastery := (
		pivot_mastery_value as Dictionary
		if pivot_mastery_value is Dictionary else
		{}
	)
	var mastered_pivot_pairs := clampi(int(pivot_mastery.get("mastered_count", 0)), 0, 3)

	var milestone_value: Variant = campaign.get("milestone", {})
	var milestone := milestone_value as Dictionary if milestone_value is Dictionary else {}
	var milestone_id := _safe_string(milestone.get(
		"selected_id",
		campaign.get("chosen_milestone_id", ""),
	)).strip_edges()
	var completed_shifts := clampi(int(campaign.get("completed_shifts", 0)), 0, 5)
	var outcome_text := _safe_string(campaign.get("outcome", "in_progress"))
	var outcome := StringName(outcome_text if not outcome_text.is_empty() else "in_progress")

	var senior_status_text := _safe_string(senior.get("status", "inactive"))
	var senior_status := StringName(senior_status_text if not senior_status_text.is_empty() else "inactive")
	var senior_shifts := maxi(0, int(senior.get("total_senior_shifts", 0)))
	var mandate_seals := maxi(0, int(senior.get("mandate_seals", 0)))
	var mastered_books := _mastered_board_books(senior)

	var sources := {
		FIRST_EGG: _source(mini(eggs_total, 1), 1, eggs_total >= 1, "%d / 1 EGG" % mini(eggs_total, 1)),
		DOCTRINE_FILED: _source(1 if not milestone_id.is_empty() else 0, 1, not milestone_id.is_empty(), "FILED" if not milestone_id.is_empty() else "0 / 1 SPECIALTY"),
		CLEAN_DOZEN: _source(mini(best_quality_streak, 12), 12, best_quality_streak >= 12, "%d / 12 CLEAN CHAIN" % mini(best_quality_streak, 12)),
		MUTUAL_KEEPER: _source(mini(fulfilled_contracts, 3), 3, fulfilled_contracts >= 3, "%d / 3 BINDERS" % mini(fulfilled_contracts, 3)),
		ADAPTIVE_CASEWORK: _source(
			mastered_pivot_pairs,
			3,
			mastered_pivot_pairs >= 3,
			"%d / 3 CASE PAIRS" % mastered_pivot_pairs,
		),
		PROBATION_SURVIVOR: _source(
			completed_shifts,
			5,
			outcome == &"passed",
			_probation_progress_label(completed_shifts, outcome),
		),
		BUREAU_BUILDER: _source(mini(facility_tiers, 3), 3, facility_tiers >= 3, "%d / 3 FACILITY TIERS" % mini(facility_tiers, 3)),
		FULL_ROOST: _source(office_capacity, 6, office_capacity >= 6, "%d / 6 PERCHES" % office_capacity),
		SENIOR_TRANSFER: _source(1 if senior_status != &"inactive" or senior_shifts > 0 else 0, 1, senior_status != &"inactive" or senior_shifts > 0, "SENIOR FILE OPEN" if senior_status != &"inactive" or senior_shifts > 0 else "PROBATION FILE"),
		BOARD_SEAL: _source(mini(mandate_seals, 1), 1, mandate_seals >= 1, "%d / 1 BOARD SEAL" % mini(mandate_seals, 1)),
		BOARD_PORTFOLIO: _source(
			mini(mastered_books, BOARD_PORTFOLIO_TARGET),
			BOARD_PORTFOLIO_TARGET,
			mastered_books >= BOARD_PORTFOLIO_TARGET,
			"%d / %d DISTINCT BOOKS" % [mini(mastered_books, BOARD_PORTFOLIO_TARGET), BOARD_PORTFOLIO_TARGET],
		),
		COMPLETE_BOARD_LEDGER: _source(
			mastered_books,
			BOARD_BOOK_TOTAL,
			mastered_books >= BOARD_BOOK_TOTAL,
			"%d / %d DISTINCT BOOKS" % [mastered_books, BOARD_BOOK_TOTAL],
		),
	}

	var rows: Array[Dictionary] = []
	var earned_ids: Array[String] = []
	var earned_count := 0
	var next_row: Dictionary = {}
	for definition: Dictionary in definitions():
		var id := StringName(definition.get("id", &""))
		var source := sources.get(id, _source(0, 1, false, "0 / 1")) as Dictionary
		var row := definition.duplicate(true)
		row.merge(source, true)
		rows.append(row)
		if bool(row.get("earned", false)):
			earned_count += 1
			earned_ids.append(String(id))
		elif next_row.is_empty():
			next_row = row.duplicate(true)

	return {
		"earned_count": earned_count,
		"total_count": IDS.size(),
		"earned_ids": earned_ids,
		"rows": rows,
		"next": next_row,
		"complete": earned_count == IDS.size(),
	}


static func compact_snapshot(evaluated: Dictionary) -> Dictionary:
	var next_value: Variant = evaluated.get("next", {})
	var next := next_value as Dictionary if next_value is Dictionary else {}
	return {
		"earned_count": maxi(0, int(evaluated.get("earned_count", 0))),
		"total_count": maxi(0, int(evaluated.get("total_count", IDS.size()))),
		"earned_ids": (evaluated.get("earned_ids", []) as Array).duplicate(),
		"complete": bool(evaluated.get("complete", false)),
		"next": {
			"id": String(next.get("id", "")),
			"title": String(next.get("title", "")),
			"progress_label": String(next.get("progress_label", "")),
		} if not next.is_empty() else {},
	}


static func _definition(
	id: StringName,
	title: String,
	description: String,
	recognition: String,
) -> Dictionary:
	return {
		"id": id,
		"title": title,
		"description": description,
		"recognition": recognition,
	}


static func _source(progress: int, target: int, earned: bool, progress_label: String) -> Dictionary:
	return {
		"progress": maxi(0, progress),
		"target": maxi(1, target),
		"earned": earned,
		"progress_label": progress_label,
	}


static func _facility_tier_total(value: Variant) -> int:
	if not value is Dictionary:
		return 0
	var total := 0
	for level_value: Variant in (value as Dictionary).values():
		total += maxi(0, int(level_value))
	return total


static func _mastered_board_books(senior: Dictionary) -> int:
	var mastery_value: Variant = senior.get("mandate_mastery", {})
	if mastery_value is Dictionary:
		var mastery := mastery_value as Dictionary
		if mastery.has("mastered_count"):
			return clampi(int(mastery.get("mastered_count", 0)), 0, BOARD_BOOK_TOTAL)
	var counts_value: Variant = senior.get("mandate_success_counts", {})
	if not counts_value is Dictionary:
		return 0
	var mastered := 0
	for count_value: Variant in (counts_value as Dictionary).values():
		if int(count_value) > 0:
			mastered += 1
	return clampi(mastered, 0, BOARD_BOOK_TOTAL)


static func _probation_progress_label(completed_shifts: int, outcome: StringName) -> String:
	if outcome == &"passed":
		return "PASSED / ALL SAFEGUARDS"
	if completed_shifts >= 5:
		return "5 / 5 SHIFTS / SAFEGUARDS MISSED"
	return "%d / 5 SHIFTS" % completed_shifts


static func _safe_string(value: Variant) -> String:
	if typeof(value) in [TYPE_STRING, TYPE_STRING_NAME]:
		return String(value)
	return ""
