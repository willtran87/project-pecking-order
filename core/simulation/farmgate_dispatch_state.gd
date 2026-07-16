class_name FarmgateDispatchState
extends RefCounted

## Deterministic finished-clutch inventory and settlement ledger. Money remains
## owned by DepartmentSimulation; this value object owns immutable egg lots,
## frozen dispatch mandates, exact settlement math, and strict persistence.

const SAVE_VERSION := 1
const MAX_LEDGER_VALUE := 2_000_000_000
const MAX_LOTS := 64
const HISTORY_LIMIT := 32
const CARRY_COST_PER_EGG_CENTS := 20
const DISPOSAL_COST_PER_EGG_CENTS := 25
const OVERFLOW_BASIS_POINTS := 9_000
const COUNTY_COMMISSION_BASIS_POINTS := 500
const SHOWCASE_BASE_BASIS_POINTS := 16_000
const SHOWCASE_LISTING_FEE_CENTS := 300
const SHOWCASE_EGG_LIMIT := 6

const FARMER_PICKUP: StringName = &"farmer_pickup"
const COUNTY_AUCTION: StringName = &"county_auction"
const REGIONAL_SHOWCASE: StringName = &"regional_showcase"
const HOLD_BASKET: StringName = &"hold_basket"
const MANDATE_ORDER: Array[StringName] = [
	FARMER_PICKUP,
	COUNTY_AUCTION,
	REGIONAL_SHOWCASE,
	HOLD_BASKET,
]

const SAVE_KEYS: Array[String] = [
	"version", "current_day", "lots", "next_lot_id", "active_mandate",
	"last_authorization", "last_settlement", "history",
	"gross_today_cents", "gross_total_cents", "fees_today_cents", "fees_total_cents",
	"payout_today_cents", "payout_total_cents",
	"carrying_today_cents", "carrying_total_cents", "disposal_today_cents", "disposal_total_cents",
	"overflow_eggs_today", "overflow_eggs_total", "overflow_gross_today_cents", "overflow_gross_total_cents",
	"dispatched_eggs_today", "dispatched_eggs_total", "spoiled_eggs_today", "spoiled_eggs_total",
	"cash_delta_today_cents", "cash_delta_total_cents",
]
const LOT_KEYS: Array[String] = [
	"lot_id", "claim_id", "laying_day", "worker_id", "worker_name", "quality",
	"value_cents", "facility_level_at_laying", "shelf_shifts", "expires_day",
]
const MANDATE_KEYS: Array[String] = [
	"mandate_id", "target_day", "facility_level", "dispatch_limit", "season_id",
	"price_basis_points", "standing_points", "standing_bonus_basis_points",
	"listing_fee_cents",
]
const AUTHORIZATION_KEYS: Array[String] = [
	"accepted", "action_id", "mandate_id", "target_day", "facility_level",
	"dispatch_limit", "season_id", "price_basis_points", "standing_points",
	"standing_bonus_basis_points", "listing_fee_cents", "reason", "outcome",
]
const SETTLEMENT_KEYS: Array[String] = [
	"accepted", "action_id", "day", "mandate_id", "facility_level", "season_id",
	"price_basis_points", "dispatch_limit", "stock_before", "stock_after",
	"sold_eggs", "sold_lots", "expired_eggs", "expired_lots",
	"base_value_cents", "gross_cents", "commission_cents", "listing_fee_cents",
	"payout_cents",
	"carrying_cost_cents", "disposal_cost_cents", "overflow_eggs",
	"overflow_gross_cents", "settlement_cash_delta_cents", "cash_delta_cents",
	"outcome",
]

var current_day: int = 0
var lots: Array[Dictionary] = []
var next_lot_id: int = 1
var active_mandate: Dictionary = {}
var last_authorization: Dictionary = {}
var last_settlement: Dictionary = {}
var history: Array[Dictionary] = []

var gross_today_cents: int = 0
var gross_total_cents: int = 0
var fees_today_cents: int = 0
var fees_total_cents: int = 0
var payout_today_cents: int = 0
var payout_total_cents: int = 0
var carrying_today_cents: int = 0
var carrying_total_cents: int = 0
var disposal_today_cents: int = 0
var disposal_total_cents: int = 0
var overflow_eggs_today: int = 0
var overflow_eggs_total: int = 0
var overflow_gross_today_cents: int = 0
var overflow_gross_total_cents: int = 0
var dispatched_eggs_today: int = 0
var dispatched_eggs_total: int = 0
var spoiled_eggs_today: int = 0
var spoiled_eggs_total: int = 0
var cash_delta_today_cents: int = 0
var cash_delta_total_cents: int = 0


static func neutral_save_data(saved_day: int) -> Dictionary:
	var state := FarmgateDispatchState.new()
	state.begin_day(saved_day)
	return state.to_save_data()


func begin_day(target_day: int) -> bool:
	if target_day < 1 or target_day > 9_999:
		return false
	if target_day == current_day:
		return true
	if current_day > 0 and target_day < current_day:
		return false
	current_day = target_day
	gross_today_cents = 0
	fees_today_cents = 0
	payout_today_cents = 0
	carrying_today_cents = 0
	disposal_today_cents = 0
	overflow_eggs_today = 0
	overflow_gross_today_cents = 0
	dispatched_eggs_today = 0
	spoiled_eggs_today = 0
	cash_delta_today_cents = 0
	return true


func stock_count() -> int:
	return lots.size()


func stock_value_cents() -> int:
	var value := 0
	for lot in lots:
		value += int(lot.get("value_cents", 0))
	return value


func lots_snapshot() -> Array[Dictionary]:
	return lots.duplicate(true)


func authorize_mandate(
	mandate_id: StringName,
	target_day: int,
	facility_level: int,
	dispatch_limit: int,
	season_id: StringName,
	county_basis_points: int,
	standing_points: int,
	available_fund_cents: int,
	protected_close_obligations_cents: int,
	outcome: String = "",
) -> Dictionary:
	var reason := ""
	if mandate_id not in MANDATE_ORDER:
		reason = "Select a listed Farmgate mandate."
	elif target_day != current_day:
		reason = "Dispatch mandates may only be filed for the current planning day."
	elif facility_level <= 0 or facility_level > 3:
		reason = "Commission the Farmgate Dispatch Depot before filing a mandate."
	elif not active_mandate.is_empty() and int(active_mandate.get("target_day", 0)) == target_day:
		reason = "This shift already has a frozen dispatch mandate."
	elif mandate_id == REGIONAL_SHOWCASE and facility_level < 3:
		reason = "Regional Showcase requires the Regional Route Fleet."
	elif mandate_id == HOLD_BASKET and available_fund_cents < protected_close_obligations_cents:
		reason = "Hold Basket requires the current Feed Fund to cover protected close obligations without a sale."
	elif dispatch_limit != [0, 8, 16, 24][facility_level]:
		reason = "The dispatch capacity does not match the commissioned Farmgate tier."
	elif String(season_id).is_empty():
		reason = "The seasonal dispatch book is missing."
	elif standing_points < 0 or standing_points > MAX_LEDGER_VALUE:
		reason = "Harvest Credit standing is outside the dispatch ledger."
	elif protected_close_obligations_cents < 0 or available_fund_cents < 0:
		reason = "The protected Feed Fund quote is invalid."
	elif county_basis_points not in [9_000, 10_500, 12_000, 13_500]:
		reason = "The county quote is not on the deterministic seasonal book."

	var price_basis_points := 10_000
	var standing_bonus_basis_points := 0
	var listing_fee_cents := 0
	if mandate_id == COUNTY_AUCTION:
		price_basis_points = county_basis_points
	elif mandate_id == REGIONAL_SHOWCASE:
		standing_bonus_basis_points = mini(2_500, maxi(0, standing_points) * 50)
		price_basis_points = SHOWCASE_BASE_BASIS_POINTS + standing_bonus_basis_points
		listing_fee_cents = SHOWCASE_LISTING_FEE_CENTS
	elif mandate_id == HOLD_BASKET:
		price_basis_points = 0

	var receipt := {
		"accepted": reason.is_empty(),
		"action_id": &"authorize_farmgate_dispatch",
		"mandate_id": mandate_id,
		"target_day": target_day,
		"facility_level": facility_level,
		"dispatch_limit": dispatch_limit,
		"season_id": season_id,
		"price_basis_points": price_basis_points,
		"standing_points": maxi(0, standing_points),
		"standing_bonus_basis_points": standing_bonus_basis_points,
		"listing_fee_cents": listing_fee_cents,
		"reason": reason,
		"outcome": outcome if reason.is_empty() else "",
	}
	if not reason.is_empty():
		return receipt
	active_mandate = _mandate_from_authorization(receipt)
	last_authorization = receipt.duplicate(true)
	return receipt


func store_lot(
	claim_id: int,
	laying_day: int,
	worker_id: int,
	worker_name: String,
	quality: StringName,
	value_cents: int,
	facility_level: int,
	shelf_shifts: int,
	capacity_eggs: int,
	overflow_basis_points: int = OVERFLOW_BASIS_POINTS,
) -> Dictionary:
	var base_capacity: int = (
		[0, 12, 24, 42][facility_level] if facility_level in [1, 2, 3] else 0
	)
	var capacity_bonus: int = capacity_eggs - base_capacity
	if (
		laying_day != current_day
		or (claim_id < -1 or claim_id == 0)
		or worker_id < 0
		or worker_name.strip_edges().is_empty()
		or quality not in [&"sound", &"golden"]
		or value_cents <= 0
		or value_cents > MAX_LEDGER_VALUE
		or facility_level < 1 or facility_level > 3
		or shelf_shifts != [0, 2, 3, 4][facility_level]
		or capacity_bonus not in [0, 6, 12, 18]
		or capacity_eggs > MAX_LOTS
		or overflow_basis_points < OVERFLOW_BASIS_POINTS
		or overflow_basis_points > 9_500
	):
		return {"accepted": false, "stored": false, "reason": "The completed egg could not enter the Farmgate ledger."}
	var lot := {
		"lot_id": next_lot_id,
		"claim_id": claim_id,
		"laying_day": laying_day,
		"worker_id": worker_id,
		"worker_name": worker_name,
		"quality": quality,
		"value_cents": value_cents,
		"facility_level_at_laying": facility_level,
		"shelf_shifts": shelf_shifts,
		"expires_day": laying_day + shelf_shifts - 1,
	}
	next_lot_id += 1
	if lots.size() < capacity_eggs:
		lots.append(lot)
		_sort_fifo()
		return {
			"accepted": true,
			"stored": true,
			"overflow": false,
			"lot": lot.duplicate(true),
			"cash_delta_cents": 0,
		}
	var overflow_gross := _basis_points_half_up(value_cents, overflow_basis_points)
	overflow_eggs_today += 1
	overflow_eggs_total += 1
	overflow_gross_today_cents += overflow_gross
	overflow_gross_total_cents += overflow_gross
	gross_today_cents += overflow_gross
	gross_total_cents += overflow_gross
	payout_today_cents += overflow_gross
	payout_total_cents += overflow_gross
	cash_delta_today_cents += overflow_gross
	cash_delta_total_cents += overflow_gross
	return {
		"accepted": true,
		"stored": false,
		"overflow": true,
		"lot": lot.duplicate(true),
		"base_value_cents": value_cents,
		"price_basis_points": overflow_basis_points,
		"gross_cents": overflow_gross,
		"cash_delta_cents": overflow_gross,
	}


func settle(
	target_day: int,
	facility_level: int,
	dispatch_limit: int,
	public_standing: int,
) -> Dictionary:
	if (
		target_day != current_day
		or facility_level < 1 or facility_level > 3
		or dispatch_limit != [0, 8, 16, 24][facility_level]
	):
		return {"accepted": false, "action_id": &"settle_farmgate_dispatch", "reason": "Farmgate settlement terms are invalid."}
	if int(last_settlement.get("day", 0)) == target_day:
		return {"accepted": false, "action_id": &"settle_farmgate_dispatch", "reason": "Farmgate settlement already closed for this day."}

	var mandate := active_mandate.duplicate(true)
	if mandate.is_empty() or int(mandate.get("target_day", 0)) != target_day:
		mandate = _default_farmer_mandate(target_day, facility_level, dispatch_limit, public_standing)
	var mandate_id := StringName(mandate.get("mandate_id", FARMER_PICKUP))
	var effective_facility_level := int(mandate.get("facility_level", facility_level))
	var effective_dispatch_limit := int(mandate.get("dispatch_limit", dispatch_limit))
	var stock_before := lots.size()
	var expired_lots: Array[Dictionary] = []
	var eligible_lots: Array[Dictionary] = []
	for lot in lots:
		if int(lot.get("expires_day", 0)) < target_day:
			expired_lots.append(lot.duplicate(true))
		else:
			eligible_lots.append(lot.duplicate(true))
	lots = eligible_lots

	var selected: Array[Dictionary] = []
	match mandate_id:
		FARMER_PICKUP:
			selected = lots.duplicate(true)
		COUNTY_AUCTION:
			_sort_fifo()
			for index in mini(effective_dispatch_limit, lots.size()):
				selected.append(lots[index].duplicate(true))
		REGIONAL_SHOWCASE:
			var showcase := lots.duplicate(true)
			showcase.sort_custom(_showcase_before)
			for index in mini(SHOWCASE_EGG_LIMIT, showcase.size()):
				selected.append((showcase[index] as Dictionary).duplicate(true))
		HOLD_BASKET:
			pass
		_:
			mandate_id = FARMER_PICKUP
			selected = lots.duplicate(true)

	var selected_ids: Dictionary = {}
	var base_value := 0
	for lot in selected:
		selected_ids[int(lot.get("lot_id", 0))] = true
		base_value += int(lot.get("value_cents", 0))
	var retained: Array[Dictionary] = []
	for lot in lots:
		if not selected_ids.has(int(lot.get("lot_id", 0))):
			retained.append(lot)
	lots = retained

	var price_basis_points := int(mandate.get("price_basis_points", 10_000))
	var gross := _basis_points_half_up(base_value, price_basis_points)
	var commission := _basis_points_half_up(gross, COUNTY_COMMISSION_BASIS_POINTS) if mandate_id == COUNTY_AUCTION else 0
	var listing_fee := (
		int(mandate.get("listing_fee_cents", SHOWCASE_LISTING_FEE_CENTS))
		if mandate_id == REGIONAL_SHOWCASE and not selected.is_empty() else
		0
	)
	var carrying := lots.size() * CARRY_COST_PER_EGG_CENTS
	var disposal := expired_lots.size() * DISPOSAL_COST_PER_EGG_CENTS
	var fees := commission + listing_fee
	var payout := gross - fees
	var settlement_cash_delta := payout - carrying - disposal

	dispatched_eggs_today += selected.size()
	dispatched_eggs_total += selected.size()
	spoiled_eggs_today += expired_lots.size()
	spoiled_eggs_total += expired_lots.size()
	gross_today_cents += gross
	gross_total_cents += gross
	fees_today_cents += fees
	fees_total_cents += fees
	payout_today_cents += payout
	payout_total_cents += payout
	carrying_today_cents += carrying
	carrying_total_cents += carrying
	disposal_today_cents += disposal
	disposal_total_cents += disposal
	cash_delta_today_cents += settlement_cash_delta
	cash_delta_total_cents += settlement_cash_delta

	var receipt := {
		"accepted": true,
		"action_id": &"settle_farmgate_dispatch",
		"day": target_day,
		"mandate_id": mandate_id,
		"facility_level": effective_facility_level,
		"season_id": StringName(mandate.get("season_id", &"baseline_neutral")),
		"price_basis_points": price_basis_points,
		"dispatch_limit": effective_dispatch_limit,
		"stock_before": stock_before,
		"stock_after": lots.size(),
		"sold_eggs": selected.size(),
		"sold_lots": selected.duplicate(true),
		"expired_eggs": expired_lots.size(),
		"expired_lots": expired_lots.duplicate(true),
		"base_value_cents": base_value,
		"gross_cents": gross,
		"commission_cents": commission,
		"listing_fee_cents": listing_fee,
		"payout_cents": payout,
		"carrying_cost_cents": carrying,
		"disposal_cost_cents": disposal,
		"overflow_eggs": overflow_eggs_today,
		"overflow_gross_cents": overflow_gross_today_cents,
		"settlement_cash_delta_cents": settlement_cash_delta,
		"cash_delta_cents": overflow_gross_today_cents + settlement_cash_delta,
		"outcome": _settlement_outcome(mandate_id, selected.size(), gross, lots.size()),
	}
	last_settlement = receipt.duplicate(true)
	history.append(receipt.duplicate(true))
	while history.size() > HISTORY_LIMIT:
		history.pop_front()
	active_mandate.clear()
	return receipt


func snapshot() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"current_day": current_day,
		"stock_eggs": lots.size(),
		"stock_value_cents": stock_value_cents(),
		"lots": lots_snapshot(),
		"active_mandate": active_mandate.duplicate(true),
		"last_authorization": last_authorization.duplicate(true),
		"last_settlement": last_settlement.duplicate(true),
		"gross_today_cents": gross_today_cents,
		"gross_total_cents": gross_total_cents,
		"fees_today_cents": fees_today_cents,
		"fees_total_cents": fees_total_cents,
		"payout_today_cents": payout_today_cents,
		"payout_total_cents": payout_total_cents,
		"carrying_today_cents": carrying_today_cents,
		"carrying_total_cents": carrying_total_cents,
		"disposal_today_cents": disposal_today_cents,
		"disposal_total_cents": disposal_total_cents,
		"overflow_eggs_today": overflow_eggs_today,
		"overflow_eggs_total": overflow_eggs_total,
		"overflow_gross_today_cents": overflow_gross_today_cents,
		"overflow_gross_total_cents": overflow_gross_total_cents,
		"dispatched_eggs_today": dispatched_eggs_today,
		"dispatched_eggs_total": dispatched_eggs_total,
		"spoiled_eggs_today": spoiled_eggs_today,
		"spoiled_eggs_total": spoiled_eggs_total,
		"cash_delta_today_cents": cash_delta_today_cents,
		"cash_delta_total_cents": cash_delta_total_cents,
	}


func to_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"current_day": current_day,
		"lots": lots.duplicate(true),
		"next_lot_id": next_lot_id,
		"active_mandate": active_mandate.duplicate(true),
		"last_authorization": last_authorization.duplicate(true),
		"last_settlement": last_settlement.duplicate(true),
		"history": history.duplicate(true),
		"gross_today_cents": gross_today_cents,
		"gross_total_cents": gross_total_cents,
		"fees_today_cents": fees_today_cents,
		"fees_total_cents": fees_total_cents,
		"payout_today_cents": payout_today_cents,
		"payout_total_cents": payout_total_cents,
		"carrying_today_cents": carrying_today_cents,
		"carrying_total_cents": carrying_total_cents,
		"disposal_today_cents": disposal_today_cents,
		"disposal_total_cents": disposal_total_cents,
		"overflow_eggs_today": overflow_eggs_today,
		"overflow_eggs_total": overflow_eggs_total,
		"overflow_gross_today_cents": overflow_gross_today_cents,
		"overflow_gross_total_cents": overflow_gross_total_cents,
		"dispatched_eggs_today": dispatched_eggs_today,
		"dispatched_eggs_total": dispatched_eggs_total,
		"spoiled_eggs_today": spoiled_eggs_today,
		"spoiled_eggs_total": spoiled_eggs_total,
		"cash_delta_today_cents": cash_delta_today_cents,
		"cash_delta_total_cents": cash_delta_total_cents,
	}


func restore_save_data(source: Variant, saved_day: int, capacity_eggs: int, facility_level: int) -> bool:
	if not source is Dictionary:
		return false
	var data := source as Dictionary
	if not _has_exact_keys(data, SAVE_KEYS):
		return false
	if not _is_integral(data.get("version")) or int(data["version"]) != SAVE_VERSION:
		return false
	if not _is_integral(data.get("current_day")) or int(data["current_day"]) != saved_day:
		return false
	if not data.get("lots") is Array or not data.get("history") is Array:
		return false
	if not data.get("active_mandate") is Dictionary or not data.get("last_authorization") is Dictionary or not data.get("last_settlement") is Dictionary:
		return false
	for key in SAVE_KEYS:
		if key in ["version", "current_day", "lots", "active_mandate", "last_authorization", "last_settlement", "history"]:
			continue
		if not _is_integral(data.get(key)):
			return false
	var restored_next_lot_id := int(data["next_lot_id"])
	if restored_next_lot_id < 1:
		return false
	var restored_lots: Array[Dictionary] = []
	var seen_ids: Dictionary = {}
	var previous_laying_day := 0
	var previous_lot_id := 0
	for value in data["lots"] as Array:
		if not value is Dictionary or not _valid_lot(value as Dictionary, saved_day):
			return false
		var lot := _normalized_lot(value as Dictionary)
		var lot_id := int(lot["lot_id"])
		var lot_level := int(lot["facility_level_at_laying"])
		var laying_day := int(lot["laying_day"])
		if (
			seen_ids.has(lot_id)
			or lot_id >= restored_next_lot_id
			or lot_level > facility_level
			or int(lot["shelf_shifts"]) != [0, 2, 3, 4][lot_level]
			or laying_day < previous_laying_day
			or (laying_day == previous_laying_day and lot_id <= previous_lot_id)
		):
			return false
		seen_ids[lot_id] = true
		previous_laying_day = laying_day
		previous_lot_id = lot_id
		restored_lots.append(lot)
	if restored_lots.size() > capacity_eggs or restored_lots.size() > MAX_LOTS:
		return false

	var restored_active := _normalized_mandate(data["active_mandate"] as Dictionary)
	var restored_authorization := _normalized_authorization(data["last_authorization"] as Dictionary)
	if not restored_active.is_empty() and not _valid_mandate(restored_active, saved_day, facility_level):
		return false
	if not restored_authorization.is_empty() and not _valid_authorization(restored_authorization, saved_day, facility_level):
		return false
	if not restored_active.is_empty() and _mandate_from_authorization(restored_authorization) != restored_active:
		return false

	var restored_history: Array[Dictionary] = []
	var previous_day := 0
	for value in data["history"] as Array:
		if not value is Dictionary or not _valid_settlement(value as Dictionary, saved_day):
			return false
		var receipt := _normalized_settlement(value as Dictionary)
		var receipt_day := int(receipt["day"])
		if receipt_day <= previous_day:
			return false
		previous_day = receipt_day
		restored_history.append(receipt)
	if restored_history.size() > HISTORY_LIMIT:
		return false
	var restored_last := _normalized_settlement(data["last_settlement"] as Dictionary)
	if restored_history.is_empty():
		if not restored_last.is_empty():
			return false
	elif restored_last != restored_history[restored_history.size() - 1]:
		return false

	for pair in [
		["gross_today_cents", "gross_total_cents"], ["fees_today_cents", "fees_total_cents"],
		["payout_today_cents", "payout_total_cents"],
		["carrying_today_cents", "carrying_total_cents"], ["disposal_today_cents", "disposal_total_cents"],
		["overflow_eggs_today", "overflow_eggs_total"], ["overflow_gross_today_cents", "overflow_gross_total_cents"],
		["dispatched_eggs_today", "dispatched_eggs_total"], ["spoiled_eggs_today", "spoiled_eggs_total"],
	]:
		var today := int(data[pair[0]])
		var total := int(data[pair[1]])
		if today < 0 or today > total or total > MAX_LEDGER_VALUE:
			return false
	if abs(int(data["cash_delta_today_cents"])) > MAX_LEDGER_VALUE or abs(int(data["cash_delta_total_cents"])) > MAX_LEDGER_VALUE:
		return false
	if (
		int(data["gross_today_cents"]) != int(data["payout_today_cents"]) + int(data["fees_today_cents"])
		or int(data["gross_total_cents"]) != int(data["payout_total_cents"]) + int(data["fees_total_cents"])
		or int(data["cash_delta_today_cents"]) != int(data["payout_today_cents"]) - int(data["carrying_today_cents"]) - int(data["disposal_today_cents"])
		or int(data["cash_delta_total_cents"]) != int(data["payout_total_cents"]) - int(data["carrying_total_cents"]) - int(data["disposal_total_cents"])
		or int(data["overflow_gross_today_cents"]) > int(data["payout_today_cents"])
		or int(data["overflow_gross_total_cents"]) > int(data["payout_total_cents"])
	):
		return false
	if facility_level <= 0:
		if (
			not restored_lots.is_empty() or not restored_active.is_empty()
			or not restored_authorization.is_empty() or not restored_history.is_empty()
			or restored_next_lot_id != 1
		):
			return false
		for key in SAVE_KEYS:
			if key.ends_with("_cents") or key.begins_with("overflow_eggs") or key.begins_with("dispatched_eggs") or key.begins_with("spoiled_eggs"):
				if int(data.get(key, 0)) != 0:
					return false

	current_day = saved_day
	lots = restored_lots
	next_lot_id = restored_next_lot_id
	active_mandate = restored_active
	last_authorization = restored_authorization
	last_settlement = restored_last
	history = restored_history
	for key in [
		"gross_today_cents", "gross_total_cents", "fees_today_cents", "fees_total_cents",
		"payout_today_cents", "payout_total_cents",
		"carrying_today_cents", "carrying_total_cents", "disposal_today_cents", "disposal_total_cents",
		"overflow_eggs_today", "overflow_eggs_total", "overflow_gross_today_cents", "overflow_gross_total_cents",
		"dispatched_eggs_today", "dispatched_eggs_total", "spoiled_eggs_today", "spoiled_eggs_total",
		"cash_delta_today_cents", "cash_delta_total_cents",
	]:
		set(key, int(data[key]))
	_sort_fifo()
	return true


func _default_farmer_mandate(target_day: int, facility_level: int, dispatch_limit: int, standing_points: int) -> Dictionary:
	return {
		"mandate_id": FARMER_PICKUP,
		"target_day": target_day,
		"facility_level": facility_level,
		"dispatch_limit": dispatch_limit,
		"season_id": &"baseline_neutral",
		"price_basis_points": 10_000,
		"standing_points": maxi(0, standing_points),
		"standing_bonus_basis_points": 0,
		"listing_fee_cents": 0,
	}


static func _mandate_from_authorization(receipt: Dictionary) -> Dictionary:
	if receipt.is_empty() or not bool(receipt.get("accepted", false)):
		return {}
	var mandate: Dictionary = {}
	for key in MANDATE_KEYS:
		mandate[key] = receipt.get(key)
	return mandate


static func _normalized_lot(source: Dictionary) -> Dictionary:
	if source.is_empty():
		return {}
	var lot := source.duplicate(true)
	lot["quality"] = StringName(lot.get("quality", &""))
	for key in ["lot_id", "claim_id", "laying_day", "worker_id", "value_cents", "facility_level_at_laying", "shelf_shifts", "expires_day"]:
		lot[key] = int(lot.get(key, 0))
	return lot


static func _normalized_mandate(source: Dictionary) -> Dictionary:
	if source.is_empty():
		return {}
	var mandate := source.duplicate(true)
	mandate["mandate_id"] = StringName(mandate.get("mandate_id", &""))
	mandate["season_id"] = StringName(mandate.get("season_id", &""))
	for key in ["target_day", "facility_level", "dispatch_limit", "price_basis_points", "standing_points", "standing_bonus_basis_points", "listing_fee_cents"]:
		mandate[key] = int(mandate.get(key, 0))
	return mandate


static func _normalized_authorization(source: Dictionary) -> Dictionary:
	if source.is_empty():
		return {}
	var receipt := source.duplicate(true)
	receipt["action_id"] = StringName(receipt.get("action_id", &""))
	receipt["mandate_id"] = StringName(receipt.get("mandate_id", &""))
	receipt["season_id"] = StringName(receipt.get("season_id", &""))
	for key in ["target_day", "facility_level", "dispatch_limit", "price_basis_points", "standing_points", "standing_bonus_basis_points", "listing_fee_cents"]:
		receipt[key] = int(receipt.get(key, 0))
	return receipt


static func _normalized_settlement(source: Dictionary) -> Dictionary:
	if source.is_empty():
		return {}
	var receipt := source.duplicate(true)
	receipt["action_id"] = StringName(receipt.get("action_id", &""))
	receipt["mandate_id"] = StringName(receipt.get("mandate_id", &""))
	receipt["season_id"] = StringName(receipt.get("season_id", &""))
	for key in [
		"day", "facility_level", "price_basis_points", "dispatch_limit", "stock_before",
		"stock_after", "sold_eggs", "expired_eggs", "base_value_cents", "gross_cents",
		"commission_cents", "listing_fee_cents", "payout_cents", "carrying_cost_cents",
		"disposal_cost_cents", "overflow_eggs", "overflow_gross_cents",
		"settlement_cash_delta_cents", "cash_delta_cents",
	]:
		receipt[key] = int(receipt.get(key, 0))
	var sold: Array[Dictionary] = []
	for lot_value in receipt.get("sold_lots", []) as Array:
		sold.append(_normalized_lot(lot_value as Dictionary))
	var expired: Array[Dictionary] = []
	for lot_value in receipt.get("expired_lots", []) as Array:
		expired.append(_normalized_lot(lot_value as Dictionary))
	receipt["sold_lots"] = sold
	receipt["expired_lots"] = expired
	return receipt


static func _valid_lot(lot: Dictionary, saved_day: int) -> bool:
	if not _has_exact_keys(lot, LOT_KEYS):
		return false
	for key in ["lot_id", "claim_id", "laying_day", "worker_id", "value_cents", "facility_level_at_laying", "shelf_shifts", "expires_day"]:
		if not _is_integral(lot.get(key)):
			return false
	var laying_day := int(lot["laying_day"])
	var shelf := int(lot["shelf_shifts"])
	return (
		int(lot["lot_id"]) > 0
		and (int(lot["claim_id"]) == -1 or int(lot["claim_id"]) > 0)
		and laying_day >= 1 and laying_day <= saved_day
		and int(lot["worker_id"]) >= 0
		and typeof(lot.get("worker_name")) == TYPE_STRING
		and not String(lot["worker_name"]).strip_edges().is_empty()
		and typeof(lot.get("quality")) in [TYPE_STRING, TYPE_STRING_NAME]
		and StringName(lot["quality"]) in [&"sound", &"golden"]
		and int(lot["value_cents"]) > 0 and int(lot["value_cents"]) <= MAX_LEDGER_VALUE
		and int(lot["facility_level_at_laying"]) in [1, 2, 3]
		and shelf in [2, 3, 4]
		and int(lot["expires_day"]) == laying_day + shelf - 1
	)


static func _valid_mandate(
	mandate: Dictionary,
	saved_day: int,
	facility_level: int,
	require_current_day: bool = true,
) -> bool:
	if not _has_exact_keys(mandate, MANDATE_KEYS):
		return false
	for key in ["target_day", "facility_level", "dispatch_limit", "price_basis_points", "standing_points", "standing_bonus_basis_points", "listing_fee_cents"]:
		if not _is_integral(mandate.get(key)):
			return false
	var mandate_id := StringName(mandate.get("mandate_id", &""))
	var mandate_level := int(mandate["facility_level"])
	var standing := int(mandate["standing_points"])
	var expected_bonus := mini(2_500, maxi(0, standing) * 50) if mandate_id == REGIONAL_SHOWCASE else 0
	var expected_price := 10_000
	if mandate_id == COUNTY_AUCTION:
		expected_price = int(mandate["price_basis_points"])
	elif mandate_id == REGIONAL_SHOWCASE:
		expected_price = SHOWCASE_BASE_BASIS_POINTS + expected_bonus
	elif mandate_id == HOLD_BASKET:
		expected_price = 0
	return (
		mandate_id in MANDATE_ORDER
		and not String(mandate.get("season_id", "")).is_empty()
		and (
			int(mandate["target_day"]) == saved_day
			if require_current_day else
			int(mandate["target_day"]) >= 1 and int(mandate["target_day"]) <= saved_day
		)
		and mandate_level > 0 and mandate_level <= facility_level
		and int(mandate["dispatch_limit"]) == [0, 8, 16, 24][mandate_level]
		and standing >= 0 and standing <= MAX_LEDGER_VALUE
		and int(mandate["standing_bonus_basis_points"]) == expected_bonus
		and int(mandate["price_basis_points"]) == expected_price
		and (mandate_id != COUNTY_AUCTION or expected_price in [9_000, 10_500, 12_000, 13_500])
		and (mandate_id != REGIONAL_SHOWCASE or int(mandate["facility_level"]) == 3)
		and int(mandate["listing_fee_cents"]) == (SHOWCASE_LISTING_FEE_CENTS if mandate_id == REGIONAL_SHOWCASE else 0)
	)


static func _valid_authorization(receipt: Dictionary, saved_day: int, facility_level: int) -> bool:
	if not _has_exact_keys(receipt, AUTHORIZATION_KEYS) or typeof(receipt.get("accepted")) != TYPE_BOOL:
		return false
	if not bool(receipt["accepted"]) or not String(receipt.get("reason", "")).is_empty():
		return false
	return _valid_mandate(
		_mandate_from_authorization(receipt),
		saved_day,
		facility_level,
		false,
	)


static func _valid_settlement(receipt: Dictionary, saved_day: int) -> bool:
	if not _has_exact_keys(receipt, SETTLEMENT_KEYS) or typeof(receipt.get("accepted")) != TYPE_BOOL or not bool(receipt["accepted"]):
		return false
	for key in [
		"day", "facility_level", "price_basis_points", "dispatch_limit", "stock_before", "stock_after",
		"sold_eggs", "expired_eggs", "base_value_cents", "gross_cents", "commission_cents",
		"listing_fee_cents", "payout_cents", "carrying_cost_cents", "disposal_cost_cents", "overflow_eggs",
		"overflow_gross_cents", "settlement_cash_delta_cents", "cash_delta_cents",
	]:
		if not _is_integral(receipt.get(key)):
			return false
	if not receipt.get("sold_lots") is Array or not receipt.get("expired_lots") is Array:
		return false
	var receipt_day := int(receipt["day"])
	if receipt_day < 1 or receipt_day > saved_day:
		return false
	var base := 0
	var seen_lot_ids: Dictionary = {}
	for value in receipt["sold_lots"] as Array:
		if not value is Dictionary or not _valid_lot(value as Dictionary, receipt_day):
			return false
		if int((value as Dictionary)["expires_day"]) < receipt_day:
			return false
		var sold_lot_id := int((value as Dictionary)["lot_id"])
		if seen_lot_ids.has(sold_lot_id):
			return false
		seen_lot_ids[sold_lot_id] = true
		base += int((value as Dictionary)["value_cents"])
	for value in receipt["expired_lots"] as Array:
		if not value is Dictionary or not _valid_lot(value as Dictionary, receipt_day):
			return false
		var expired_lot_id := int((value as Dictionary)["lot_id"])
		if seen_lot_ids.has(expired_lot_id):
			return false
		seen_lot_ids[expired_lot_id] = true
		if int((value as Dictionary)["expires_day"]) >= receipt_day:
			return false
	var mandate_id := StringName(receipt.get("mandate_id", &""))
	var receipt_level := int(receipt["facility_level"])
	var receipt_price := int(receipt["price_basis_points"])
	var gross := _basis_points_half_up(base, int(receipt["price_basis_points"]))
	var commission := _basis_points_half_up(gross, COUNTY_COMMISSION_BASIS_POINTS) if mandate_id == COUNTY_AUCTION else 0
	var listing := SHOWCASE_LISTING_FEE_CENTS if mandate_id == REGIONAL_SHOWCASE and int(receipt["sold_eggs"]) > 0 else 0
	var payout := gross - commission - listing
	var settlement_delta := payout - int(receipt["carrying_cost_cents"]) - int(receipt["disposal_cost_cents"])
	var sold_lots := receipt["sold_lots"] as Array
	for index in range(1, sold_lots.size()):
		var previous := sold_lots[index - 1] as Dictionary
		var current := sold_lots[index] as Dictionary
		if mandate_id in [FARMER_PICKUP, COUNTY_AUCTION] and (
			int(current["laying_day"]) < int(previous["laying_day"])
			or (
				int(current["laying_day"]) == int(previous["laying_day"])
				and int(current["lot_id"]) <= int(previous["lot_id"])
			)
		):
			return false
		if mandate_id == REGIONAL_SHOWCASE and _showcase_before(current, previous):
			return false
	return (
		mandate_id in MANDATE_ORDER
		and not String(receipt.get("season_id", "")).is_empty()
		and receipt_level in [1, 2, 3]
		and int(receipt["dispatch_limit"]) == [0, 8, 16, 24][receipt_level]
		and (
			(mandate_id == FARMER_PICKUP and receipt_price == 10_000)
			or (mandate_id == COUNTY_AUCTION and receipt_price in [9_000, 10_500, 12_000, 13_500])
			or (mandate_id == REGIONAL_SHOWCASE and receipt_price >= 16_000 and receipt_price <= 18_500 and (receipt_price - 16_000) % 50 == 0)
			or (mandate_id == HOLD_BASKET and receipt_price == 0)
		)
		and int(receipt["stock_before"]) >= 0 and int(receipt["stock_before"]) <= MAX_LOTS
		and int(receipt["stock_after"]) >= 0 and int(receipt["stock_after"]) <= MAX_LOTS
		and int(receipt["stock_before"]) == int(receipt["stock_after"]) + int(receipt["sold_eggs"]) + int(receipt["expired_eggs"])
		and int(receipt["sold_eggs"]) == (receipt["sold_lots"] as Array).size()
		and (mandate_id != COUNTY_AUCTION or int(receipt["sold_eggs"]) <= int(receipt["dispatch_limit"]))
		and (mandate_id != REGIONAL_SHOWCASE or int(receipt["sold_eggs"]) <= SHOWCASE_EGG_LIMIT)
		and (mandate_id != HOLD_BASKET or int(receipt["sold_eggs"]) == 0)
		and (mandate_id != FARMER_PICKUP or int(receipt["stock_after"]) == 0)
		and (mandate_id != HOLD_BASKET or int(receipt["stock_after"]) == int(receipt["stock_before"]) - int(receipt["expired_eggs"]))
		and int(receipt["expired_eggs"]) == (receipt["expired_lots"] as Array).size()
		and int(receipt["base_value_cents"]) == base
		and int(receipt["gross_cents"]) == gross
		and int(receipt["commission_cents"]) == commission
		and int(receipt["listing_fee_cents"]) == listing
		and int(receipt["payout_cents"]) == payout
		and int(receipt["carrying_cost_cents"]) == int(receipt["stock_after"]) * CARRY_COST_PER_EGG_CENTS
		and int(receipt["disposal_cost_cents"]) == int(receipt["expired_eggs"]) * DISPOSAL_COST_PER_EGG_CENTS
		and int(receipt["overflow_eggs"]) >= 0
		and int(receipt["overflow_gross_cents"]) >= 0
		and int(receipt["settlement_cash_delta_cents"]) == settlement_delta
		and int(receipt["cash_delta_cents"]) == int(receipt["overflow_gross_cents"]) + settlement_delta
		and String(receipt.get("outcome", "")) == _settlement_outcome(
			mandate_id,
			int(receipt["sold_eggs"]),
			gross,
			int(receipt["stock_after"]),
		)
	)


func _sort_fifo() -> void:
	lots.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if int(left.get("laying_day", 0)) != int(right.get("laying_day", 0)):
			return int(left.get("laying_day", 0)) < int(right.get("laying_day", 0))
		return int(left.get("lot_id", 0)) < int(right.get("lot_id", 0))
	)


static func _showcase_before(left: Dictionary, right: Dictionary) -> bool:
	var left_golden := StringName(left.get("quality", &"")) == &"golden"
	var right_golden := StringName(right.get("quality", &"")) == &"golden"
	if left_golden != right_golden:
		return left_golden
	if int(left.get("value_cents", 0)) != int(right.get("value_cents", 0)):
		return int(left.get("value_cents", 0)) > int(right.get("value_cents", 0))
	return int(left.get("lot_id", 0)) < int(right.get("lot_id", 0))


static func _settlement_outcome(mandate_id: StringName, sold: int, gross: int, retained: int) -> String:
	match mandate_id:
		COUNTY_AUCTION:
			return "County Auction dispatched %d eggs for $%.2f gross; %d remain chilled." % [sold, float(gross) / 100.0, retained]
		REGIONAL_SHOWCASE:
			return "Regional Showcase dispatched %d premium eggs for $%.2f gross; the farmer retained the route placard." % [sold, float(gross) / 100.0]
		HOLD_BASKET:
			return "Management held the basket. No egg was sold and cold-chain costs remain real."
	return "Farmer Pickup collected %d eggs for $%.2f; %d remain in reserve." % [sold, float(gross) / 100.0, retained]


static func _has_exact_keys(source: Dictionary, expected: Array[String]) -> bool:
	if source.size() != expected.size():
		return false
	for key in expected:
		if not source.has(key):
			return false
	return true


static func _is_integral(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and is_equal_approx(float(value), round(float(value))))


static func _basis_points_half_up(value: int, basis_points: int) -> int:
	if value <= 0 or basis_points <= 0:
		return 0
	return (value * basis_points + 5_000) / 10_000
