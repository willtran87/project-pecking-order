class_name FarmTreasuryState
extends RefCounted


## Authoritative, money-conserving operating treasury for the farm office.
##
## DepartmentSimulation integration is deliberately narrow:
##
## 1. Construct from the live Feed Fund and the last already-closed day with
##    `FarmTreasuryState.new(current_cash_cents, last_closed_day)`. This is also
##    the neutral migration path: it invents no debt, rating, or history.
## 2. During a shift close, call `quote_close(...)` for a pure preview and then
##    `close_shift(...)` with the same categorized inflows, vendor costs, and
##    external labor due (current payroll plus any carried wage arrears).
## 3. Adopt `closing_cash_cents` as the simulation's Feed Fund and
##    `labor_unpaid_cents` as its next wage-arrears balance. Labor is paid only
##    from cash, never credit, and is not carried inside this state.
## 4. Persist `to_save_data()` alongside the simulation. `restore_save_data()`
##    validates every retained receipt by deterministic replay before mutation.
##
## Cash and automatic credit share the first four settlement priorities:
## carried interest -> carried vendor arrears -> current interest -> current
## vendor costs. Residual cash then pays external labor due before repaying
## principal. Interest is charged only on principal present at opening; a
## same-close draw begins accruing on the following shift.

const SAVE_VERSION := 1
const HISTORY_LIMIT := 32
const MAX_LEDGER_CENTS := 2_000_000_000
const MAX_DAY := 9_999
const MAX_BREAKDOWN_ROWS := 32
const MAX_BREAKDOWN_KEY_LENGTH := 64

const BASE_CREDIT_LIMIT_CENTS := 5_000
const STANDING_CREDIT_CENTS_PER_POINT := 500
const STANDING_CREDIT_LIMIT_CAP_CENTS := 15_000
const RATING_CREDIT_BONUS_CENTS := 2_500
const MAX_CREDIT_RATING := 2
const ABSOLUTE_CREDIT_LIMIT_CENTS := (
	STANDING_CREDIT_LIMIT_CAP_CENTS + MAX_CREDIT_RATING * RATING_CREDIT_BONUS_CENTS
)

const BASE_INTEREST_BASIS_POINTS := 500
const RATING_INTEREST_REDUCTION_BASIS_POINTS := 100
const MINIMUM_INTEREST_CENTS := 100
const PROFITABLE_CLOSES_PER_RATING := 3

const SAVE_KEYS: Array[String] = [
	"version",
	"last_closed_day",
	"cash_cents",
	"credit_principal_cents",
	"vendor_arrears_cents",
	"interest_arrears_cents",
	"solvency_streak",
	"credit_rating",
	"next_receipt_id",
	"last_receipt",
	"history",
]

const RECEIPT_KEYS: Array[String] = [
	"accepted",
	"receipt_id",
	"action_id",
	"day",
	"standing_points",
	"income_breakdown",
	"inflow_cents",
	"vendor_breakdown",
	"current_vendor_due_cents",
	"labor_due_cents",
	"opening_cash_cents",
	"opening_credit_principal_cents",
	"opening_vendor_arrears_cents",
	"opening_interest_arrears_cents",
	"credit_rating_before",
	"solvency_streak_before",
	"credit_limit_cents",
	"interest_basis_points",
	"interest_charged_cents",
	"total_interest_due_cents",
	"total_vendor_due_cents",
	"cash_paid_interest_arrears_cents",
	"cash_paid_vendor_arrears_cents",
	"cash_paid_current_interest_cents",
	"cash_paid_current_vendor_cents",
	"credit_paid_interest_arrears_cents",
	"credit_paid_vendor_arrears_cents",
	"credit_paid_current_interest_cents",
	"credit_paid_current_vendor_cents",
	"interest_paid_cents",
	"vendor_paid_cents",
	"credit_draw_cents",
	"labor_paid_cents",
	"labor_unpaid_cents",
	"principal_repaid_cents",
	"closing_cash_cents",
	"closing_credit_principal_cents",
	"closing_vendor_arrears_cents",
	"closing_interest_arrears_cents",
	"operating_margin_cents",
	"profitable",
	"debt_free",
	"solvency_streak_after",
	"credit_rating_after",
	"rating_advanced",
	"closing_credit_limit_cents",
	"conservation_left_cents",
	"conservation_right_cents",
	"outcome",
]

const RECEIPT_INTEGER_KEYS: Array[String] = [
	"receipt_id",
	"day",
	"standing_points",
	"inflow_cents",
	"current_vendor_due_cents",
	"labor_due_cents",
	"opening_cash_cents",
	"opening_credit_principal_cents",
	"opening_vendor_arrears_cents",
	"opening_interest_arrears_cents",
	"credit_rating_before",
	"solvency_streak_before",
	"credit_limit_cents",
	"interest_basis_points",
	"interest_charged_cents",
	"total_interest_due_cents",
	"total_vendor_due_cents",
	"cash_paid_interest_arrears_cents",
	"cash_paid_vendor_arrears_cents",
	"cash_paid_current_interest_cents",
	"cash_paid_current_vendor_cents",
	"credit_paid_interest_arrears_cents",
	"credit_paid_vendor_arrears_cents",
	"credit_paid_current_interest_cents",
	"credit_paid_current_vendor_cents",
	"interest_paid_cents",
	"vendor_paid_cents",
	"credit_draw_cents",
	"labor_paid_cents",
	"labor_unpaid_cents",
	"principal_repaid_cents",
	"closing_cash_cents",
	"closing_credit_principal_cents",
	"closing_vendor_arrears_cents",
	"closing_interest_arrears_cents",
	"operating_margin_cents",
	"solvency_streak_after",
	"credit_rating_after",
	"closing_credit_limit_cents",
	"conservation_left_cents",
	"conservation_right_cents",
]

const RECEIPT_BOOL_KEYS: Array[String] = [
	"accepted", "profitable", "debt_free", "rating_advanced",
]

var last_closed_day: int = 0
var cash_cents: int = 0
var credit_principal_cents: int = 0
var vendor_arrears_cents: int = 0
var interest_arrears_cents: int = 0
var solvency_streak: int = 0
var credit_rating: int = 0
var next_receipt_id: int = 1
var _last_receipt: Dictionary = {}
var _history: Array[Dictionary] = []

## Archive views are defensive copies. A caller may freely annotate a returned
## receipt without altering the authoritative receipt chain used for save replay.
var last_receipt: Dictionary:
	get:
		return _last_receipt.duplicate(true)
	set(_value):
		push_error("FarmTreasuryState.last_receipt is read-only.")

var history: Array[Dictionary]:
	get:
		return _history.duplicate(true)
	set(_value):
		push_error("FarmTreasuryState.history is read-only.")


func _init(initial_cash_cents: int = 0, initial_last_closed_day: int = 0) -> void:
	if not initialize_from_cash(initial_cash_cents, initial_last_closed_day):
		initialize_from_cash(0, 0)


## Neutral initialization for a legacy checkpoint. It preserves only facts the
## old save actually knew: current cash and the last completed shift number.
func initialize_from_cash(current_cash_cents: int, completed_day: int = 0) -> bool:
	if (
		current_cash_cents < 0
		or current_cash_cents > MAX_LEDGER_CENTS
		or completed_day < 0
		or completed_day > MAX_DAY
	):
		return false
	last_closed_day = completed_day
	cash_cents = current_cash_cents
	credit_principal_cents = 0
	vendor_arrears_cents = 0
	interest_arrears_cents = 0
	solvency_streak = 0
	credit_rating = 0
	next_receipt_id = 1
	_last_receipt.clear()
	_history.clear()
	return true


static func neutral_save_data(current_cash_cents: int, completed_day: int = 0) -> Dictionary:
	if (
		current_cash_cents < 0
		or current_cash_cents > MAX_LEDGER_CENTS
		or completed_day < 0
		or completed_day > MAX_DAY
	):
		return {}
	return {
		"version": SAVE_VERSION,
		"last_closed_day": completed_day,
		"cash_cents": current_cash_cents,
		"credit_principal_cents": 0,
		"vendor_arrears_cents": 0,
		"interest_arrears_cents": 0,
		"solvency_streak": 0,
		"credit_rating": 0,
		"next_receipt_id": 1,
		"last_receipt": {},
		"history": [],
	}


## The standing-derived line is capped at $150 before rating bonuses. Each of
## the two earned rating tiers then adds another $25, for an absolute $200 max.
func credit_limit_cents(standing_points: int, rating_override: int = -1) -> int:
	var rating := credit_rating if rating_override < 0 else rating_override
	rating = clampi(rating, 0, MAX_CREDIT_RATING)
	var standing_limit := mini(
		STANDING_CREDIT_LIMIT_CAP_CENTS,
		BASE_CREDIT_LIMIT_CENTS + maxi(0, standing_points) * STANDING_CREDIT_CENTS_PER_POINT,
	)
	return standing_limit + rating * RATING_CREDIT_BONUS_CENTS


func interest_basis_points(rating_override: int = -1) -> int:
	var rating := credit_rating if rating_override < 0 else rating_override
	return maxi(
		0,
		BASE_INTEREST_BASIS_POINTS
		- clampi(rating, 0, MAX_CREDIT_RATING) * RATING_INTEREST_REDUCTION_BASIS_POINTS,
	)


func quote_close(
	target_day: int,
	standing_points: int,
	income_breakdown: Dictionary,
	vendor_breakdown: Dictionary,
	labor_due_cents: int = 0,
) -> Dictionary:
	var reason := _close_reason(
		target_day,
		standing_points,
		income_breakdown,
		vendor_breakdown,
		labor_due_cents,
	)
	if not reason.is_empty():
		return _rejection(target_day, reason)
	var normalized_income := _normalize_breakdown(income_breakdown)
	var normalized_vendor := _normalize_breakdown(vendor_breakdown)
	return _calculate_receipt(
		target_day,
		standing_points,
		normalized_income,
		normalized_vendor,
		labor_due_cents,
		_before_state(),
		next_receipt_id,
	)


## Commits exactly one chronological shift close. Returned receipts are deep
## copies, so callers cannot mutate the authoritative archive after filing.
func close_shift(
	target_day: int,
	standing_points: int,
	income_breakdown: Dictionary,
	vendor_breakdown: Dictionary,
	labor_due_cents: int = 0,
) -> Dictionary:
	var receipt := quote_close(
		target_day,
		standing_points,
		income_breakdown,
		vendor_breakdown,
		labor_due_cents,
	)
	if not bool(receipt.get("accepted", false)):
		return receipt
	_apply_receipt(receipt)
	_last_receipt = receipt.duplicate(true)
	_history.append(receipt.duplicate(true))
	while _history.size() > HISTORY_LIMIT:
		_history.pop_front()
	next_receipt_id += 1
	return receipt.duplicate(true)


func snapshot(standing_points: int = 0) -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"last_closed_day": last_closed_day,
		"cash_cents": cash_cents,
		"credit_principal_cents": credit_principal_cents,
		"vendor_arrears_cents": vendor_arrears_cents,
		"interest_arrears_cents": interest_arrears_cents,
		"total_liabilities_cents": (
			credit_principal_cents + vendor_arrears_cents + interest_arrears_cents
		),
		"solvency_streak": solvency_streak,
		"credit_rating": credit_rating,
		"credit_limit_cents": credit_limit_cents(standing_points),
		"credit_headroom_cents": maxi(
			0,
			credit_limit_cents(standing_points) - credit_principal_cents,
		),
		"interest_basis_points": interest_basis_points(),
		"next_receipt_id": next_receipt_id,
		"last_receipt": _last_receipt.duplicate(true),
		"history": _history.duplicate(true),
	}


func to_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"last_closed_day": last_closed_day,
		"cash_cents": cash_cents,
		"credit_principal_cents": credit_principal_cents,
		"vendor_arrears_cents": vendor_arrears_cents,
		"interest_arrears_cents": interest_arrears_cents,
		"solvency_streak": solvency_streak,
		"credit_rating": credit_rating,
		"next_receipt_id": next_receipt_id,
		"last_receipt": _last_receipt.duplicate(true),
		"history": _history.duplicate(true),
	}


## Strict and atomic: unknown fields, non-integral money, broken receipt chains,
## or any receipt that cannot be reproduced from its signed inputs reject the
## entire checkpoint without mutating the current treasury.
func restore_save_data(source: Variant) -> bool:
	if not source is Dictionary:
		return false
	var data := source as Dictionary
	if not _has_exact_keys(data, SAVE_KEYS):
		return false
	for key in [
		"version", "last_closed_day", "cash_cents", "credit_principal_cents",
		"vendor_arrears_cents", "interest_arrears_cents", "solvency_streak",
		"credit_rating", "next_receipt_id",
	]:
		if not _is_integral(data.get(key)):
			return false
	if int(data["version"]) != SAVE_VERSION:
		return false
	var restored_day := int(data["last_closed_day"])
	var restored_cash := int(data["cash_cents"])
	var restored_principal := int(data["credit_principal_cents"])
	var restored_vendor := int(data["vendor_arrears_cents"])
	var restored_interest := int(data["interest_arrears_cents"])
	var restored_streak := int(data["solvency_streak"])
	var restored_rating := int(data["credit_rating"])
	var restored_next_id := int(data["next_receipt_id"])
	if (
		restored_day < 0 or restored_day > MAX_DAY
		or not _money_in_range(restored_cash)
		or restored_principal < 0 or restored_principal > ABSOLUTE_CREDIT_LIMIT_CENTS
		or not _money_in_range(restored_vendor)
		or not _money_in_range(restored_interest)
		or restored_streak < 0 or restored_streak > PROFITABLE_CLOSES_PER_RATING
		or restored_rating < 0 or restored_rating > MAX_CREDIT_RATING
		or restored_next_id < 1 or restored_next_id > MAX_LEDGER_CENTS
	):
		return false
	if not data.get("last_receipt") is Dictionary or not data.get("history") is Array:
		return false
	var raw_history := data["history"] as Array
	if raw_history.size() > HISTORY_LIMIT:
		return false
	var restored_history: Array[Dictionary] = []
	for raw_receipt in raw_history:
		var normalized := _validated_receipt(raw_receipt)
		if normalized.is_empty():
			return false
		restored_history.append(normalized)

	var normalized_last := _validated_receipt(data["last_receipt"])
	if restored_history.is_empty():
		if not (data["last_receipt"] as Dictionary).is_empty() or not normalized_last.is_empty():
			return false
		if (
			restored_next_id != 1
			or restored_principal != 0
			or restored_vendor != 0
			or restored_interest != 0
			or restored_streak != 0
			or restored_rating != 0
		):
			return false
	else:
		if normalized_last.is_empty() or normalized_last != restored_history[-1]:
			return false
		for index in restored_history.size():
			var receipt := restored_history[index]
			if index > 0 and not _receipts_chain(restored_history[index - 1], receipt):
				return false
		var final_receipt := restored_history[-1]
		if (
			restored_next_id != int(final_receipt["receipt_id"]) + 1
			or restored_day != int(final_receipt["day"])
			or restored_cash != int(final_receipt["closing_cash_cents"])
			or restored_principal != int(final_receipt["closing_credit_principal_cents"])
			or restored_vendor != int(final_receipt["closing_vendor_arrears_cents"])
			or restored_interest != int(final_receipt["closing_interest_arrears_cents"])
			or restored_streak != int(final_receipt["solvency_streak_after"])
			or restored_rating != int(final_receipt["credit_rating_after"])
		):
			return false

	last_closed_day = restored_day
	cash_cents = restored_cash
	credit_principal_cents = restored_principal
	vendor_arrears_cents = restored_vendor
	interest_arrears_cents = restored_interest
	solvency_streak = restored_streak
	credit_rating = restored_rating
	next_receipt_id = restored_next_id
	_last_receipt = normalized_last.duplicate(true)
	_history = restored_history.duplicate(true)
	return true


func _close_reason(
	target_day: int,
	standing_points: int,
	income_breakdown: Dictionary,
	vendor_breakdown: Dictionary,
	labor_due_cents: int,
) -> String:
	if target_day != last_closed_day + 1 or target_day < 1 or target_day > MAX_DAY:
		return "Treasury closes must follow the last filed shift exactly once."
	if standing_points < 0 or standing_points > MAX_LEDGER_CENTS:
		return "Farm Mutual standing is outside the treasury ledger."
	if labor_due_cents < 0 or labor_due_cents > MAX_LEDGER_CENTS:
		return "Labor due must be a non-negative integer-cent obligation."
	var income_validation := _validate_breakdown(income_breakdown)
	if not bool(income_validation.get("valid", false)):
		return "Treasury inflow categories must contain only safe names and non-negative integer cents."
	var vendor_validation := _validate_breakdown(vendor_breakdown)
	if not bool(vendor_validation.get("valid", false)):
		return "Treasury vendor categories must contain only safe names and non-negative integer cents."
	var inflow := int(income_validation.get("total_cents", 0))
	if cash_cents > MAX_LEDGER_CENTS - inflow:
		return "Treasury cash would exceed the supported ledger."
	return ""


func _calculate_receipt(
	target_day: int,
	standing_points: int,
	income: Dictionary,
	vendor: Dictionary,
	labor_due: int,
	before: Dictionary,
	receipt_id: int,
) -> Dictionary:
	var opening_cash := int(before["cash_cents"])
	var opening_principal := int(before["credit_principal_cents"])
	var opening_vendor := int(before["vendor_arrears_cents"])
	var opening_interest := int(before["interest_arrears_cents"])
	var rating_before := int(before["credit_rating"])
	var streak_before := int(before["solvency_streak"])
	var inflow := _breakdown_total(income)
	var current_vendor := _breakdown_total(vendor)
	var rate := interest_basis_points(rating_before)
	var interest_charged := _interest_charge(opening_principal, rate)
	var line_limit := credit_limit_cents(standing_points, rating_before)
	var cash_pool := opening_cash + inflow

	# Cash follows the documented seniority order.
	var cash_paid_interest_arrears := mini(cash_pool, opening_interest)
	cash_pool -= cash_paid_interest_arrears
	var interest_arrears_left := opening_interest - cash_paid_interest_arrears
	var cash_paid_vendor_arrears := mini(cash_pool, opening_vendor)
	cash_pool -= cash_paid_vendor_arrears
	var vendor_arrears_left := opening_vendor - cash_paid_vendor_arrears
	var cash_paid_current_interest := mini(cash_pool, interest_charged)
	cash_pool -= cash_paid_current_interest
	var current_interest_left := interest_charged - cash_paid_current_interest
	var cash_paid_current_vendor := mini(cash_pool, current_vendor)
	cash_pool -= cash_paid_current_vendor
	var current_vendor_left := current_vendor - cash_paid_current_vendor

	# Automatic credit covers the same obligations in the same order, but never
	# exceeds the standing/rating line. A standing decline cannot erase principal;
	# it simply leaves no new headroom until the balance falls below the line.
	var headroom := maxi(0, line_limit - opening_principal)
	var credit_paid_interest_arrears := mini(headroom, interest_arrears_left)
	headroom -= credit_paid_interest_arrears
	interest_arrears_left -= credit_paid_interest_arrears
	var credit_paid_vendor_arrears := mini(headroom, vendor_arrears_left)
	headroom -= credit_paid_vendor_arrears
	vendor_arrears_left -= credit_paid_vendor_arrears
	var credit_paid_current_interest := mini(headroom, current_interest_left)
	headroom -= credit_paid_current_interest
	current_interest_left -= credit_paid_current_interest
	var credit_paid_current_vendor := mini(headroom, current_vendor_left)
	headroom -= credit_paid_current_vendor
	current_vendor_left -= credit_paid_current_vendor
	var credit_draw := (
		credit_paid_interest_arrears
		+ credit_paid_vendor_arrears
		+ credit_paid_current_interest
		+ credit_paid_current_vendor
	)

	# Labor remains an external liability: pay it from residual cash after lender
	# and vendor obligations, never from automatic credit, and report the unpaid
	# remainder for DepartmentSimulation's existing wage-arrears ledger.
	var labor_paid := mini(cash_pool, labor_due)
	cash_pool -= labor_paid
	var labor_unpaid := labor_due - labor_paid
	var principal_before_repayment := opening_principal + credit_draw
	var principal_repaid := mini(cash_pool, principal_before_repayment)
	cash_pool -= principal_repaid
	var closing_principal := principal_before_repayment - principal_repaid
	var closing_vendor := vendor_arrears_left + current_vendor_left
	var closing_interest := interest_arrears_left + current_interest_left
	var operating_margin := inflow - current_vendor - interest_charged - labor_due
	var profitable := operating_margin > 0
	var debt_free := (
		closing_principal == 0
		and closing_vendor == 0
		and closing_interest == 0
		and labor_unpaid == 0
	)
	var streak_after := streak_before + 1 if profitable and debt_free else 0
	var rating_after := rating_before
	var rating_advanced := false
	if streak_after >= PROFITABLE_CLOSES_PER_RATING:
		if rating_after < MAX_CREDIT_RATING:
			rating_after += 1
			streak_after = 0
			rating_advanced = true
		else:
			streak_after = PROFITABLE_CLOSES_PER_RATING

	var interest_paid := (
		cash_paid_interest_arrears
		+ cash_paid_current_interest
		+ credit_paid_interest_arrears
		+ credit_paid_current_interest
	)
	var vendor_paid := (
		cash_paid_vendor_arrears
		+ cash_paid_current_vendor
		+ credit_paid_vendor_arrears
		+ credit_paid_current_vendor
	)
	var conservation_left := opening_cash + inflow + credit_draw
	var conservation_right := (
		interest_paid + vendor_paid + labor_paid + principal_repaid + cash_pool
	)

	return {
		"accepted": true,
		"receipt_id": receipt_id,
		"action_id": "close_treasury_shift",
		"day": target_day,
		"standing_points": standing_points,
		"income_breakdown": income.duplicate(true),
		"inflow_cents": inflow,
		"vendor_breakdown": vendor.duplicate(true),
		"current_vendor_due_cents": current_vendor,
		"labor_due_cents": labor_due,
		"opening_cash_cents": opening_cash,
		"opening_credit_principal_cents": opening_principal,
		"opening_vendor_arrears_cents": opening_vendor,
		"opening_interest_arrears_cents": opening_interest,
		"credit_rating_before": rating_before,
		"solvency_streak_before": streak_before,
		"credit_limit_cents": line_limit,
		"interest_basis_points": rate,
		"interest_charged_cents": interest_charged,
		"total_interest_due_cents": opening_interest + interest_charged,
		"total_vendor_due_cents": opening_vendor + current_vendor,
		"cash_paid_interest_arrears_cents": cash_paid_interest_arrears,
		"cash_paid_vendor_arrears_cents": cash_paid_vendor_arrears,
		"cash_paid_current_interest_cents": cash_paid_current_interest,
		"cash_paid_current_vendor_cents": cash_paid_current_vendor,
		"credit_paid_interest_arrears_cents": credit_paid_interest_arrears,
		"credit_paid_vendor_arrears_cents": credit_paid_vendor_arrears,
		"credit_paid_current_interest_cents": credit_paid_current_interest,
		"credit_paid_current_vendor_cents": credit_paid_current_vendor,
		"interest_paid_cents": interest_paid,
		"vendor_paid_cents": vendor_paid,
		"credit_draw_cents": credit_draw,
		"labor_paid_cents": labor_paid,
		"labor_unpaid_cents": labor_unpaid,
		"principal_repaid_cents": principal_repaid,
		"closing_cash_cents": cash_pool,
		"closing_credit_principal_cents": closing_principal,
		"closing_vendor_arrears_cents": closing_vendor,
		"closing_interest_arrears_cents": closing_interest,
		"operating_margin_cents": operating_margin,
		"profitable": profitable,
		"debt_free": debt_free,
		"solvency_streak_after": streak_after,
		"credit_rating_after": rating_after,
		"rating_advanced": rating_advanced,
		"closing_credit_limit_cents": credit_limit_cents(standing_points, rating_after),
		"conservation_left_cents": conservation_left,
		"conservation_right_cents": conservation_right,
		"outcome": (
			"Day %d treasury filed: cash %d cents; credit %d cents; vendor arrears %d cents; interest arrears %d cents; unpaid labor %d cents."
			% [target_day, cash_pool, closing_principal, closing_vendor, closing_interest, labor_unpaid]
		),
	}


func _apply_receipt(receipt: Dictionary) -> void:
	last_closed_day = int(receipt["day"])
	cash_cents = int(receipt["closing_cash_cents"])
	credit_principal_cents = int(receipt["closing_credit_principal_cents"])
	vendor_arrears_cents = int(receipt["closing_vendor_arrears_cents"])
	interest_arrears_cents = int(receipt["closing_interest_arrears_cents"])
	solvency_streak = int(receipt["solvency_streak_after"])
	credit_rating = int(receipt["credit_rating_after"])


func _before_state() -> Dictionary:
	return {
		"cash_cents": cash_cents,
		"credit_principal_cents": credit_principal_cents,
		"vendor_arrears_cents": vendor_arrears_cents,
		"interest_arrears_cents": interest_arrears_cents,
		"solvency_streak": solvency_streak,
		"credit_rating": credit_rating,
	}


func _validated_receipt(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var source := value as Dictionary
	if source.is_empty() or not _has_exact_keys(source, RECEIPT_KEYS):
		return {}
	for key in RECEIPT_INTEGER_KEYS:
		if not _is_integral(source.get(key)):
			return {}
	for key in RECEIPT_BOOL_KEYS:
		if typeof(source.get(key)) != TYPE_BOOL:
			return {}
	if not bool(source["accepted"]):
		return {}
	if typeof(source.get("action_id")) != TYPE_STRING or String(source["action_id"]) != "close_treasury_shift":
		return {}
	if typeof(source.get("outcome")) != TYPE_STRING:
		return {}
	var income_validation := _validate_breakdown(source.get("income_breakdown"))
	var vendor_validation := _validate_breakdown(source.get("vendor_breakdown"))
	if (
		not bool(income_validation.get("valid", false))
		or not bool(vendor_validation.get("valid", false))
	):
		return {}
	var normalized := source.duplicate(true)
	for key in RECEIPT_INTEGER_KEYS:
		normalized[key] = int(normalized[key])
	normalized["income_breakdown"] = _normalize_breakdown(normalized["income_breakdown"] as Dictionary)
	normalized["vendor_breakdown"] = _normalize_breakdown(normalized["vendor_breakdown"] as Dictionary)
	var before := {
		"cash_cents": int(normalized["opening_cash_cents"]),
		"credit_principal_cents": int(normalized["opening_credit_principal_cents"]),
		"vendor_arrears_cents": int(normalized["opening_vendor_arrears_cents"]),
		"interest_arrears_cents": int(normalized["opening_interest_arrears_cents"]),
		"credit_rating": int(normalized["credit_rating_before"]),
		"solvency_streak": int(normalized["solvency_streak_before"]),
	}
	if not _valid_before_state(before):
		return {}
	var receipt_id := int(normalized["receipt_id"])
	var target_day := int(normalized["day"])
	var standing := int(normalized["standing_points"])
	var labor_due := int(normalized["labor_due_cents"])
	if (
		receipt_id < 1 or receipt_id > MAX_LEDGER_CENTS
		or target_day < 1 or target_day > MAX_DAY
		or standing < 0 or standing > MAX_LEDGER_CENTS
		or labor_due < 0 or labor_due > MAX_LEDGER_CENTS
	):
		return {}
	var expected := _calculate_receipt(
		target_day,
		standing,
		normalized["income_breakdown"] as Dictionary,
		normalized["vendor_breakdown"] as Dictionary,
		labor_due,
		before,
		receipt_id,
	)
	return normalized if normalized == expected else {}


func _receipts_chain(previous: Dictionary, current: Dictionary) -> bool:
	return (
		int(current["receipt_id"]) == int(previous["receipt_id"]) + 1
		and int(current["day"]) == int(previous["day"]) + 1
		and int(current["opening_cash_cents"]) == int(previous["closing_cash_cents"])
		and int(current["opening_credit_principal_cents"]) == int(previous["closing_credit_principal_cents"])
		and int(current["opening_vendor_arrears_cents"]) == int(previous["closing_vendor_arrears_cents"])
		and int(current["opening_interest_arrears_cents"]) == int(previous["closing_interest_arrears_cents"])
		and int(current["credit_rating_before"]) == int(previous["credit_rating_after"])
		and int(current["solvency_streak_before"]) == int(previous["solvency_streak_after"])
	)


func _valid_before_state(before: Dictionary) -> bool:
	return (
		_money_in_range(int(before.get("cash_cents", -1)))
		and int(before.get("credit_principal_cents", -1)) >= 0
		and int(before.get("credit_principal_cents", -1)) <= ABSOLUTE_CREDIT_LIMIT_CENTS
		and _money_in_range(int(before.get("vendor_arrears_cents", -1)))
		and _money_in_range(int(before.get("interest_arrears_cents", -1)))
		and int(before.get("credit_rating", -1)) >= 0
		and int(before.get("credit_rating", -1)) <= MAX_CREDIT_RATING
		and int(before.get("solvency_streak", -1)) >= 0
		and int(before.get("solvency_streak", -1)) <= PROFITABLE_CLOSES_PER_RATING
	)


func _validate_breakdown(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "total_cents": 0}
	var source := value as Dictionary
	if source.size() > MAX_BREAKDOWN_ROWS:
		return {"valid": false, "total_cents": 0}
	var total := 0
	for raw_key in source:
		if typeof(raw_key) != TYPE_STRING:
			return {"valid": false, "total_cents": 0}
		var key := String(raw_key)
		if not _safe_breakdown_key(key) or not _is_integral(source[raw_key]):
			return {"valid": false, "total_cents": 0}
		var amount := int(source[raw_key])
		if amount < 0 or amount > MAX_LEDGER_CENTS or total > MAX_LEDGER_CENTS - amount:
			return {"valid": false, "total_cents": 0}
		total += amount
	return {"valid": true, "total_cents": total}


func _normalize_breakdown(source: Dictionary) -> Dictionary:
	var keys: Array[String] = []
	for raw_key in source:
		keys.append(String(raw_key))
	keys.sort()
	var normalized: Dictionary = {}
	for key in keys:
		normalized[key] = int(source[key])
	return normalized


func _breakdown_total(source: Dictionary) -> int:
	var total := 0
	for value in source.values():
		total += int(value)
	return total


func _safe_breakdown_key(value: String) -> bool:
	if value.is_empty() or value.length() > MAX_BREAKDOWN_KEY_LENGTH:
		return false
	for index in value.length():
		var code := value.unicode_at(index)
		var safe := (
			(code >= 97 and code <= 122)
			or (code >= 48 and code <= 57)
			or code == 95
		)
		if not safe:
			return false
	return true


func _interest_charge(principal_cents: int, basis_points: int) -> int:
	if principal_cents <= 0:
		return 0
	@warning_ignore("integer_division")
	return maxi(
		MINIMUM_INTEREST_CENTS,
		(principal_cents * basis_points + 5_000) / 10_000,
	)


func _rejection(target_day: int, reason: String) -> Dictionary:
	return {
		"accepted": false,
		"action_id": "close_treasury_shift",
		"day": target_day,
		"reason": reason,
	}


func _has_exact_keys(source: Dictionary, expected: Array[String]) -> bool:
	if source.size() != expected.size():
		return false
	for key in expected:
		if not source.has(key):
			return false
	return true


func _money_in_range(value: int) -> bool:
	return value >= 0 and value <= MAX_LEDGER_CENTS


func _is_integral(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) == TYPE_FLOAT:
		var number := float(value)
		return is_finite(number) and number == round(number)
	return false
