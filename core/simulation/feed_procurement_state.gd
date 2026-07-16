class_name FeedProcurementState
extends RefCounted

## Authoritative, deterministic inventory ledger for the Flock Provisions Co-op.
## Money remains integer cents and feed remains integer scoops. DepartmentSimulation
## owns the cash account and season quote; this object owns lots, FIFO use, and waste.

const SAVE_VERSION := 1
const MAX_LEDGER_VALUE := 2_000_000_000
const MAX_LOTS := 64

const OFFER_PROFILES := {
	&"local_whole_grain": {
		"shelf_shifts": 2,
		"strain_basis_points": 9_200,
		"morale_millipoints": 2_000,
		"grievance_millipoints": 0,
	},
	&"inspirational_bulk_mash": {
		"shelf_shifts": 3,
		"strain_basis_points": 10_500,
		"morale_millipoints": 0,
		"grievance_millipoints": 1_000,
	},
	&"fixed_future_reserve": {
		"shelf_shifts": 4,
		"strain_basis_points": 10_000,
		"morale_millipoints": 0,
		"grievance_millipoints": 0,
	},
}

const SAVE_KEYS: Array[String] = [
	"version",
	"current_day",
	"lots",
	"order_used_day",
	"next_lot_id",
	"procurement_spend_today_cents",
	"procurement_spend_total_cents",
	"spot_spend_today_cents",
	"spot_spend_total_cents",
	"spoiled_today_scoops",
	"spoiled_total_scoops",
	"spoiled_today_value_cents",
	"spoiled_total_value_cents",
	"consumed_today_scoops",
	"consumed_inventory_today_scoops",
	"consumed_spot_today_scoops",
	"consumed_value_today_cents",
	"ration_applied_day",
	"active_strain_basis_points",
	"active_morale_millipoints",
	"active_grievance_millipoints",
	"last_order",
	"last_consumption",
	"last_spoilage",
]
const LOT_KEYS: Array[String] = [
	"lot_id",
	"offer_id",
	"ordered_day",
	"expires_day",
	"scoops_initial",
	"scoops_remaining",
	"unit_cost_cents",
	"total_cost_cents",
	"strain_basis_points",
	"morale_millipoints",
	"grievance_millipoints",
]
const ORDER_KEYS: Array[String] = [
	"accepted",
	"action_id",
	"offer_id",
	"offer_label",
	"day",
	"lot_id",
	"quantity_scoops",
	"unit_cost_cents",
	"total_cost_cents",
	"shelf_shifts",
	"expires_day",
	"stock_before_scoops",
	"stock_after_scoops",
	"capacity_scoops",
	"strain_basis_points",
	"morale_delta",
	"grievance_delta",
	"outcome",
]
const CONSUMPTION_KEYS: Array[String] = [
	"day",
	"demand_scoops",
	"inventory_scoops",
	"spot_scoops",
	"spot_unit_price_cents",
	"spot_cost_cents",
	"consumed_value_cents",
	"strain_basis_points",
	"morale_millipoints",
	"grievance_millipoints",
	"allocations",
	"shortage_covered_automatically",
]
const ALLOCATION_KEYS: Array[String] = [
	"lot_id",
	"offer_id",
	"scoops",
	"unit_cost_cents",
	"value_cents",
]
const SPOILAGE_KEYS: Array[String] = [
	"day",
	"scoops",
	"value_cents",
	"lots",
]
const SPOILED_LOT_KEYS: Array[String] = [
	"lot_id",
	"offer_id",
	"scoops",
	"unit_cost_cents",
	"value_cents",
	"expired_day",
]

var current_day: int = 0
var lots: Array[Dictionary] = []
var order_used_day: int = 0
var next_lot_id: int = 1
var procurement_spend_today_cents: int = 0
var procurement_spend_total_cents: int = 0
var spot_spend_today_cents: int = 0
var spot_spend_total_cents: int = 0
var spoiled_today_scoops: int = 0
var spoiled_total_scoops: int = 0
var spoiled_today_value_cents: int = 0
var spoiled_total_value_cents: int = 0
var consumed_today_scoops: int = 0
var consumed_inventory_today_scoops: int = 0
var consumed_spot_today_scoops: int = 0
var consumed_value_today_cents: int = 0
var ration_applied_day: int = 0
var active_strain_basis_points: int = 10_000
var active_morale_millipoints: int = 0
var active_grievance_millipoints: int = 0
var last_order: Dictionary = {}
var last_consumption: Dictionary = {}
var last_spoilage: Dictionary = {}


static func neutral_save_data(saved_day: int) -> Dictionary:
	var state := FeedProcurementState.new()
	state.begin_day(saved_day)
	return state.to_save_data()


func begin_day(target_day: int) -> bool:
	if target_day < 1 or (current_day > 0 and target_day < current_day):
		return false
	if target_day != current_day:
		current_day = target_day
		procurement_spend_today_cents = 0
		spot_spend_today_cents = 0
		spoiled_today_scoops = 0
		spoiled_today_value_cents = 0
		consumed_today_scoops = 0
		consumed_inventory_today_scoops = 0
		consumed_spot_today_scoops = 0
		consumed_value_today_cents = 0
		ration_applied_day = 0
		active_strain_basis_points = 10_000
		active_morale_millipoints = 0
		active_grievance_millipoints = 0
		# Depleted lots are retained only during their consumption day so a later
		# incident can deterministically rebalance that same ration plan.
		var carried: Array[Dictionary] = []
		for lot in lots:
			if int(lot.get("scoops_remaining", 0)) > 0:
				carried.append(lot)
		lots = carried
	_expire_lots(target_day)
	return true


func stock_scoops() -> int:
	var total := 0
	for lot in lots:
		total += maxi(0, int(lot.get("scoops_remaining", 0)))
	return total


func lots_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for lot in lots:
		if int(lot.get("scoops_remaining", 0)) > 0:
			result.append(lot.duplicate(true))
	return result


func authorize_lot(
	offer_id: StringName,
	offer_label: String,
	quantity_scoops: int,
	unit_cost_cents: int,
	capacity_scoops: int,
	target_day: int,
	outcome: String
) -> Dictionary:
	if not OFFER_PROFILES.has(offer_id):
		return {"accepted": false, "offer_id": offer_id, "reason": "Unknown feed offer."}
	if not begin_day(target_day):
		return {"accepted": false, "offer_id": offer_id, "reason": "Feed ledger day is invalid."}
	if order_used_day == target_day:
		return {"accepted": false, "offer_id": offer_id, "reason": "Today's provisions order is already filed."}
	if quantity_scoops <= 0 or unit_cost_cents <= 0:
		return {"accepted": false, "offer_id": offer_id, "reason": "Feed order quantity or quote is invalid."}
	var stock_before := stock_scoops()
	if stock_before + quantity_scoops > maxi(0, capacity_scoops):
		return {"accepted": false, "offer_id": offer_id, "reason": "The provisions bins cannot hold that order."}
	var total_cost_cents := quantity_scoops * unit_cost_cents
	if total_cost_cents <= 0 or total_cost_cents > MAX_LEDGER_VALUE:
		return {"accepted": false, "offer_id": offer_id, "reason": "Feed order total is outside the authorized ledger."}
	var profile := OFFER_PROFILES[offer_id] as Dictionary
	var shelf_shifts := int(profile["shelf_shifts"])
	var lot := {
		"lot_id": next_lot_id,
		"offer_id": String(offer_id),
		"ordered_day": target_day,
		"expires_day": target_day + shelf_shifts - 1,
		"scoops_initial": quantity_scoops,
		"scoops_remaining": quantity_scoops,
		"unit_cost_cents": unit_cost_cents,
		"total_cost_cents": total_cost_cents,
		"strain_basis_points": int(profile["strain_basis_points"]),
		"morale_millipoints": int(profile["morale_millipoints"]),
		"grievance_millipoints": int(profile["grievance_millipoints"]),
	}
	lots.append(lot)
	next_lot_id += 1
	order_used_day = target_day
	procurement_spend_today_cents += total_cost_cents
	procurement_spend_total_cents += total_cost_cents
	last_order = {
		"accepted": true,
		"action_id": String(&"authorize_feed_order"),
		"offer_id": String(offer_id),
		"offer_label": offer_label,
		"day": target_day,
		"lot_id": int(lot["lot_id"]),
		"quantity_scoops": quantity_scoops,
		"unit_cost_cents": unit_cost_cents,
		"total_cost_cents": total_cost_cents,
		"shelf_shifts": shelf_shifts,
		"expires_day": int(lot["expires_day"]),
		"stock_before_scoops": stock_before,
		"stock_after_scoops": stock_scoops(),
		"capacity_scoops": capacity_scoops,
		"strain_basis_points": int(profile["strain_basis_points"]),
		"morale_delta": int(profile["morale_millipoints"]) / 1_000,
		"grievance_delta": int(profile["grievance_millipoints"]) / 1_000,
		"outcome": outcome,
	}
	return last_order.duplicate(true)


func consume(demand_scoops: int, spot_unit_price_cents: int, target_day: int) -> Dictionary:
	if not begin_day(target_day):
		return {}
	demand_scoops = maxi(0, demand_scoops)
	spot_unit_price_cents = maxi(0, spot_unit_price_cents)
	if ration_applied_day == target_day and not _restore_current_consumption():
		return {}
	_sort_lots_fifo()
	var remaining := demand_scoops
	var inventory_scoops := 0
	var inventory_value_cents := 0
	var weighted_strain := 0
	var weighted_morale := 0
	var weighted_grievance := 0
	var allocations: Array[Dictionary] = []
	for lot in lots:
		if remaining <= 0:
			break
		var available := maxi(0, int(lot.get("scoops_remaining", 0)))
		var used := mini(available, remaining)
		if used <= 0:
			continue
		lot["scoops_remaining"] = available - used
		remaining -= used
		inventory_scoops += used
		var unit_cost := int(lot["unit_cost_cents"])
		inventory_value_cents += used * unit_cost
		weighted_strain += used * int(lot["strain_basis_points"])
		weighted_morale += used * int(lot["morale_millipoints"])
		weighted_grievance += used * int(lot["grievance_millipoints"])
		allocations.append({
			"lot_id": int(lot["lot_id"]),
			"offer_id": String(lot["offer_id"]),
			"scoops": used,
			"unit_cost_cents": unit_cost,
			"value_cents": used * unit_cost,
		})
	var spot_scoops := remaining
	var spot_cost_cents := spot_scoops * spot_unit_price_cents
	weighted_strain += spot_scoops * 10_000
	spot_spend_today_cents = spot_cost_cents
	spot_spend_total_cents += spot_cost_cents
	consumed_today_scoops = demand_scoops
	consumed_inventory_today_scoops = inventory_scoops
	consumed_spot_today_scoops = spot_scoops
	consumed_value_today_cents = inventory_value_cents + spot_cost_cents
	ration_applied_day = target_day
	if demand_scoops > 0:
		active_strain_basis_points = _half_up_ratio(weighted_strain, demand_scoops)
		active_morale_millipoints = _half_up_ratio(weighted_morale, demand_scoops)
		active_grievance_millipoints = _half_up_ratio(weighted_grievance, demand_scoops)
	else:
		active_strain_basis_points = 10_000
		active_morale_millipoints = 0
		active_grievance_millipoints = 0
	last_consumption = {
		"day": target_day,
		"demand_scoops": demand_scoops,
		"inventory_scoops": inventory_scoops,
		"spot_scoops": spot_scoops,
		"spot_unit_price_cents": spot_unit_price_cents,
		"spot_cost_cents": spot_cost_cents,
		"consumed_value_cents": consumed_value_today_cents,
		"strain_basis_points": active_strain_basis_points,
		"morale_millipoints": active_morale_millipoints,
		"grievance_millipoints": active_grievance_millipoints,
		"allocations": allocations,
		"shortage_covered_automatically": spot_scoops > 0,
	}
	return last_consumption.duplicate(true)


func active_ration_snapshot() -> Dictionary:
	return {
		"applied": ration_applied_day == current_day,
		"day": ration_applied_day,
		"strain_basis_points": active_strain_basis_points,
		"strain_multiplier": float(active_strain_basis_points) / 10_000.0,
		"morale_millipoints": active_morale_millipoints,
		"morale_delta": float(active_morale_millipoints) / 1_000.0,
		"grievance_millipoints": active_grievance_millipoints,
		"grievance_delta": float(active_grievance_millipoints) / 1_000.0,
	}


func to_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"current_day": current_day,
		"lots": lots.duplicate(true),
		"order_used_day": order_used_day,
		"next_lot_id": next_lot_id,
		"procurement_spend_today_cents": procurement_spend_today_cents,
		"procurement_spend_total_cents": procurement_spend_total_cents,
		"spot_spend_today_cents": spot_spend_today_cents,
		"spot_spend_total_cents": spot_spend_total_cents,
		"spoiled_today_scoops": spoiled_today_scoops,
		"spoiled_total_scoops": spoiled_total_scoops,
		"spoiled_today_value_cents": spoiled_today_value_cents,
		"spoiled_total_value_cents": spoiled_total_value_cents,
		"consumed_today_scoops": consumed_today_scoops,
		"consumed_inventory_today_scoops": consumed_inventory_today_scoops,
		"consumed_spot_today_scoops": consumed_spot_today_scoops,
		"consumed_value_today_cents": consumed_value_today_cents,
		"ration_applied_day": ration_applied_day,
		"active_strain_basis_points": active_strain_basis_points,
		"active_morale_millipoints": active_morale_millipoints,
		"active_grievance_millipoints": active_grievance_millipoints,
		"last_order": last_order.duplicate(true),
		"last_consumption": last_consumption.duplicate(true),
		"last_spoilage": last_spoilage.duplicate(true),
	}


func restore_save_data(source: Variant, saved_day: int, capacity_scoops: int, facility_level: int) -> bool:
	if not source is Dictionary:
		return false
	var data := source as Dictionary
	if not _has_exact_keys(data, SAVE_KEYS):
		return false
	for key in SAVE_KEYS:
		if key in ["lots", "last_order", "last_consumption", "last_spoilage"]:
			continue
		if not _is_integral_number(data.get(key, null)):
			return false
	if int(data["version"]) != SAVE_VERSION or int(data["current_day"]) != saved_day:
		return false
	if saved_day < 1 or capacity_scoops < 0 or facility_level < 0 or facility_level > 3:
		return false
	var lot_values: Variant = data["lots"]
	if not lot_values is Array or (lot_values as Array).size() > MAX_LOTS:
		return false
	var restored_lots: Array[Dictionary] = []
	var seen_lot_ids: Dictionary = {}
	var maximum_lot_id := 0
	var restored_stock := 0
	for lot_value in lot_values as Array:
		if not lot_value is Dictionary:
			return false
		var lot := (lot_value as Dictionary).duplicate(true)
		if not _is_valid_lot(lot, saved_day):
			return false
		var lot_id := int(lot["lot_id"])
		if seen_lot_ids.has(lot_id):
			return false
		seen_lot_ids[lot_id] = true
		maximum_lot_id = maxi(maximum_lot_id, lot_id)
		restored_stock += int(lot["scoops_remaining"])
		restored_lots.append(lot)
	if restored_stock > capacity_scoops:
		return false
	var restored_next_lot_id := int(data["next_lot_id"])
	if restored_next_lot_id < 1 or restored_next_lot_id <= maximum_lot_id:
		return false
	var restored_order_day := int(data["order_used_day"])
	var restored_ration_day := int(data["ration_applied_day"])
	if restored_order_day < 0 or restored_order_day > saved_day:
		return false
	if restored_ration_day not in [0, saved_day]:
		return false
	var bounded_nonnegative_keys: Array[String] = [
		"procurement_spend_today_cents", "procurement_spend_total_cents",
		"spot_spend_today_cents", "spot_spend_total_cents",
		"spoiled_today_scoops", "spoiled_total_scoops",
		"spoiled_today_value_cents", "spoiled_total_value_cents",
		"consumed_today_scoops", "consumed_inventory_today_scoops",
		"consumed_spot_today_scoops", "consumed_value_today_cents",
		"active_morale_millipoints", "active_grievance_millipoints",
	]
	for key in bounded_nonnegative_keys:
		var value := int(data[key])
		if value < 0 or value > MAX_LEDGER_VALUE:
			return false
	var restored_strain := int(data["active_strain_basis_points"])
	if (
		restored_strain < 9_200
		or restored_strain > 10_500
		or int(data["active_morale_millipoints"]) > 2_000
		or int(data["active_grievance_millipoints"]) > 1_000
	):
		return false
	if (
		int(data["procurement_spend_today_cents"]) > int(data["procurement_spend_total_cents"])
		or int(data["spot_spend_today_cents"]) > int(data["spot_spend_total_cents"])
		or int(data["spoiled_today_scoops"]) > int(data["spoiled_total_scoops"])
		or int(data["spoiled_today_value_cents"]) > int(data["spoiled_total_value_cents"])
		or int(data["consumed_inventory_today_scoops"]) + int(data["consumed_spot_today_scoops"])
		!= int(data["consumed_today_scoops"])
	):
		return false
	var restored_last_order: Variant = _validated_last_order(data["last_order"], restored_order_day, saved_day)
	if restored_last_order == null:
		return false
	var restored_last_consumption: Variant = _validated_last_consumption(
		data["last_consumption"], restored_ration_day, saved_day, seen_lot_ids
	)
	if restored_last_consumption == null:
		return false
	var restored_last_spoilage: Variant = _validated_last_spoilage(data["last_spoilage"], saved_day)
	if restored_last_spoilage == null:
		return false
	if restored_order_day != saved_day and int(data["procurement_spend_today_cents"]) != 0:
		return false
	if restored_order_day == 0 and not (restored_last_order as Dictionary).is_empty():
		return false
	if restored_order_day > 0:
		if (restored_last_order as Dictionary).is_empty():
			return false
		if (
			int((restored_last_order as Dictionary)["lot_id"]) >= restored_next_lot_id
			or int((restored_last_order as Dictionary)["total_cost_cents"])
			> int(data["procurement_spend_total_cents"])
		):
			return false
		if restored_order_day == saved_day and int(data["procurement_spend_today_cents"]) != int((restored_last_order as Dictionary)["total_cost_cents"]):
			return false
	if restored_ration_day == 0:
		if (
			int(data["spot_spend_today_cents"]) != 0
			or int(data["consumed_today_scoops"]) != 0
			or restored_strain != 10_000
			or int(data["active_morale_millipoints"]) != 0
			or int(data["active_grievance_millipoints"]) != 0
		):
			return false
		if (
			not (restored_last_consumption as Dictionary).is_empty()
			and int((restored_last_consumption as Dictionary)["day"]) >= saved_day
		):
			return false
	else:
		var consumption := restored_last_consumption as Dictionary
		if (
			consumption.is_empty()
			or int(consumption["demand_scoops"]) != int(data["consumed_today_scoops"])
			or int(consumption["inventory_scoops"]) != int(data["consumed_inventory_today_scoops"])
			or int(consumption["spot_scoops"]) != int(data["consumed_spot_today_scoops"])
			or int(consumption["spot_cost_cents"]) != int(data["spot_spend_today_cents"])
			or int(consumption["consumed_value_cents"]) != int(data["consumed_value_today_cents"])
			or int(consumption["strain_basis_points"]) != restored_strain
			or int(consumption["morale_millipoints"]) != int(data["active_morale_millipoints"])
			or int(consumption["grievance_millipoints"]) != int(data["active_grievance_millipoints"])
		):
			return false
	if not (restored_last_consumption as Dictionary).is_empty() and (
		int((restored_last_consumption as Dictionary)["spot_cost_cents"])
		> int(data["spot_spend_total_cents"])
	):
		return false
	if int(data["spoiled_today_scoops"]) > 0:
		var spoilage := restored_last_spoilage as Dictionary
		if (
			spoilage.is_empty()
			or int(spoilage["day"]) != saved_day
			or int(spoilage["scoops"]) != int(data["spoiled_today_scoops"])
			or int(spoilage["value_cents"]) != int(data["spoiled_today_value_cents"])
		):
			return false
	elif (
		not (restored_last_spoilage as Dictionary).is_empty()
		and int((restored_last_spoilage as Dictionary)["day"]) == saved_day
	):
		return false
	if not (restored_last_spoilage as Dictionary).is_empty() and (
		int((restored_last_spoilage as Dictionary)["scoops"])
		> int(data["spoiled_total_scoops"])
		or int((restored_last_spoilage as Dictionary)["value_cents"])
		> int(data["spoiled_total_value_cents"])
	):
		return false
	if facility_level == 0 and (
		not restored_lots.is_empty()
		or restored_order_day != 0
		or int(data["procurement_spend_total_cents"]) != 0
		or int(data["spoiled_total_scoops"]) != 0
	):
		return false
	current_day = saved_day
	lots = restored_lots
	order_used_day = restored_order_day
	next_lot_id = restored_next_lot_id
	procurement_spend_today_cents = int(data["procurement_spend_today_cents"])
	procurement_spend_total_cents = int(data["procurement_spend_total_cents"])
	spot_spend_today_cents = int(data["spot_spend_today_cents"])
	spot_spend_total_cents = int(data["spot_spend_total_cents"])
	spoiled_today_scoops = int(data["spoiled_today_scoops"])
	spoiled_total_scoops = int(data["spoiled_total_scoops"])
	spoiled_today_value_cents = int(data["spoiled_today_value_cents"])
	spoiled_total_value_cents = int(data["spoiled_total_value_cents"])
	consumed_today_scoops = int(data["consumed_today_scoops"])
	consumed_inventory_today_scoops = int(data["consumed_inventory_today_scoops"])
	consumed_spot_today_scoops = int(data["consumed_spot_today_scoops"])
	consumed_value_today_cents = int(data["consumed_value_today_cents"])
	ration_applied_day = restored_ration_day
	active_strain_basis_points = restored_strain
	active_morale_millipoints = int(data["active_morale_millipoints"])
	active_grievance_millipoints = int(data["active_grievance_millipoints"])
	last_order = (restored_last_order as Dictionary).duplicate(true)
	last_consumption = (restored_last_consumption as Dictionary).duplicate(true)
	last_spoilage = (restored_last_spoilage as Dictionary).duplicate(true)
	_sort_lots_fifo()
	return true


func _expire_lots(target_day: int) -> void:
	var retained: Array[Dictionary] = []
	var spoiled_rows: Array[Dictionary] = []
	var spoiled_scoops := 0
	var spoiled_value := 0
	for lot in lots:
		var remaining := maxi(0, int(lot.get("scoops_remaining", 0)))
		if remaining > 0 and int(lot.get("expires_day", 0)) < target_day:
			var value_cents := remaining * int(lot.get("unit_cost_cents", 0))
			spoiled_scoops += remaining
			spoiled_value += value_cents
			spoiled_rows.append({
				"lot_id": int(lot.get("lot_id", 0)),
				"offer_id": String(lot.get("offer_id", "")),
				"scoops": remaining,
				"unit_cost_cents": int(lot.get("unit_cost_cents", 0)),
				"value_cents": value_cents,
				"expired_day": int(lot.get("expires_day", 0)),
			})
			continue
		retained.append(lot)
	lots = retained
	if spoiled_scoops > 0:
		spoiled_today_scoops += spoiled_scoops
		spoiled_total_scoops += spoiled_scoops
		spoiled_today_value_cents += spoiled_value
		spoiled_total_value_cents += spoiled_value
		last_spoilage = {
			"day": target_day,
			"scoops": spoiled_scoops,
			"value_cents": spoiled_value,
			"lots": spoiled_rows,
		}


func _restore_current_consumption() -> bool:
	var allocation_values: Variant = last_consumption.get("allocations", [])
	if not allocation_values is Array:
		return false
	for allocation_value in allocation_values as Array:
		if not allocation_value is Dictionary:
			return false
		var allocation := allocation_value as Dictionary
		var lot_index := _lot_index(int(allocation.get("lot_id", -1)))
		if lot_index < 0:
			return false
		var lot := lots[lot_index]
		lot["scoops_remaining"] = int(lot.get("scoops_remaining", 0)) + int(allocation.get("scoops", 0))
	spot_spend_total_cents = maxi(0, spot_spend_total_cents - spot_spend_today_cents)
	spot_spend_today_cents = 0
	consumed_today_scoops = 0
	consumed_inventory_today_scoops = 0
	consumed_spot_today_scoops = 0
	consumed_value_today_cents = 0
	active_strain_basis_points = 10_000
	active_morale_millipoints = 0
	active_grievance_millipoints = 0
	return true


func _sort_lots_fifo() -> void:
	lots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ordered_a := int(a.get("ordered_day", 0))
		var ordered_b := int(b.get("ordered_day", 0))
		if ordered_a != ordered_b:
			return ordered_a < ordered_b
		return int(a.get("lot_id", 0)) < int(b.get("lot_id", 0))
	)


func _lot_index(lot_id: int) -> int:
	for index in lots.size():
		if int(lots[index].get("lot_id", -1)) == lot_id:
			return index
	return -1


static func _half_up_ratio(numerator: int, denominator: int) -> int:
	if denominator <= 0:
		return 0
	@warning_ignore("integer_division")
	return (numerator + denominator / 2) / denominator


static func _has_exact_keys(source: Dictionary, expected: Array[String]) -> bool:
	if source.size() != expected.size():
		return false
	for key in expected:
		if not source.has(key):
			return false
	return true


static func _is_integral_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and float(value) == floor(float(value))


static func _is_valid_lot(lot: Dictionary, saved_day: int) -> bool:
	if not _has_exact_keys(lot, LOT_KEYS):
		return false
	for key in LOT_KEYS:
		if key == "offer_id":
			continue
		if not _is_integral_number(lot.get(key, null)):
			return false
	var offer_id := StringName(String(lot["offer_id"]))
	if not OFFER_PROFILES.has(offer_id):
		return false
	var profile := OFFER_PROFILES[offer_id] as Dictionary
	var ordered_day := int(lot["ordered_day"])
	var expires_day := int(lot["expires_day"])
	var initial := int(lot["scoops_initial"])
	var remaining := int(lot["scoops_remaining"])
	var unit_cost := int(lot["unit_cost_cents"])
	if (
		int(lot["lot_id"]) < 1
		or ordered_day < 1 or ordered_day > saved_day
		or expires_day != ordered_day + int(profile["shelf_shifts"]) - 1
		or expires_day < saved_day
		or initial < 1 or initial > MAX_LEDGER_VALUE
		or remaining < 0 or remaining > initial
		or unit_cost < 1 or unit_cost > MAX_LEDGER_VALUE
		or int(lot["total_cost_cents"]) != initial * unit_cost
		or int(lot["total_cost_cents"]) > MAX_LEDGER_VALUE
		or int(lot["strain_basis_points"]) != int(profile["strain_basis_points"])
		or int(lot["morale_millipoints"]) != int(profile["morale_millipoints"])
		or int(lot["grievance_millipoints"]) != int(profile["grievance_millipoints"])
	):
		return false
	for key in LOT_KEYS:
		if key != "offer_id":
			lot[key] = int(lot[key])
	lot["offer_id"] = String(offer_id)
	return true


static func _validated_last_order(value: Variant, order_day: int, saved_day: int) -> Variant:
	if not value is Dictionary:
		return null
	var order := (value as Dictionary).duplicate(true)
	if order.is_empty():
		return order
	if not _has_exact_keys(order, ORDER_KEYS):
		return null
	if typeof(order["accepted"]) != TYPE_BOOL or not bool(order["accepted"]):
		return null
	if StringName(String(order["action_id"])) != &"authorize_feed_order":
		return null
	var offer_id := StringName(String(order["offer_id"]))
	if not OFFER_PROFILES.has(offer_id):
		return null
	for key in ORDER_KEYS:
		if key in ["accepted", "action_id", "offer_id", "offer_label", "outcome"]:
			continue
		if not _is_integral_number(order.get(key, null)):
			return null
	var profile := OFFER_PROFILES[offer_id] as Dictionary
	if (
		int(order["day"]) != order_day or order_day < 1 or order_day > saved_day
		or int(order["lot_id"]) < 1
		or int(order["quantity_scoops"]) < 1
		or int(order["unit_cost_cents"]) < 1
		or int(order["total_cost_cents"]) != int(order["quantity_scoops"]) * int(order["unit_cost_cents"])
		or int(order["shelf_shifts"]) != int(profile["shelf_shifts"])
		or int(order["expires_day"]) != order_day + int(profile["shelf_shifts"]) - 1
		or int(order["stock_before_scoops"]) < 0
		or int(order["stock_after_scoops"]) != int(order["stock_before_scoops"]) + int(order["quantity_scoops"])
		or int(order["stock_after_scoops"]) > int(order["capacity_scoops"])
		or int(order["capacity_scoops"]) not in [18, 36, 54, 72]
		or int(order["total_cost_cents"]) > MAX_LEDGER_VALUE
		or int(order["strain_basis_points"]) != int(profile["strain_basis_points"])
		or int(order["morale_delta"]) != int(profile["morale_millipoints"]) / 1_000
		or int(order["grievance_delta"]) != int(profile["grievance_millipoints"]) / 1_000
	):
		return null
	for key in ORDER_KEYS:
		if key not in ["accepted", "action_id", "offer_id", "offer_label", "outcome"]:
			order[key] = int(order[key])
	order["action_id"] = String(&"authorize_feed_order")
	order["offer_id"] = String(offer_id)
	return order


static func _validated_last_consumption(value: Variant, ration_day: int, saved_day: int, known_lot_ids: Dictionary) -> Variant:
	if not value is Dictionary:
		return null
	var consumption := (value as Dictionary).duplicate(true)
	if consumption.is_empty():
		return consumption
	if not _has_exact_keys(consumption, CONSUMPTION_KEYS):
		return null
	if typeof(consumption["shortage_covered_automatically"]) != TYPE_BOOL:
		return null
	for key in CONSUMPTION_KEYS:
		if key in ["allocations", "shortage_covered_automatically"]:
			continue
		if not _is_integral_number(consumption.get(key, null)):
			return null
	var consumption_day := int(consumption["day"])
	if consumption_day < 1 or consumption_day > saved_day:
		return null
	if ration_day > 0 and consumption_day != ration_day:
		return null
	var allocation_values: Variant = consumption["allocations"]
	if not allocation_values is Array:
		return null
	var allocation_scoops := 0
	var allocation_value := 0
	var weighted_strain := int(consumption["spot_scoops"]) * 10_000
	var weighted_morale := 0
	var weighted_grievance := 0
	for allocation_value_raw in allocation_values as Array:
		if not allocation_value_raw is Dictionary:
			return null
		var allocation := allocation_value_raw as Dictionary
		if not _has_exact_keys(allocation, ALLOCATION_KEYS):
			return null
		for key in ALLOCATION_KEYS:
			if key == "offer_id":
				continue
			if not _is_integral_number(allocation.get(key, null)):
				return null
		var offer_id := StringName(String(allocation["offer_id"]))
		if not OFFER_PROFILES.has(offer_id):
			return null
		var lot_id := int(allocation["lot_id"])
		if consumption_day == saved_day and ration_day == saved_day and not known_lot_ids.has(lot_id):
			return null
		var scoops := int(allocation["scoops"])
		var unit_cost := int(allocation["unit_cost_cents"])
		if lot_id < 1 or scoops < 1 or unit_cost < 1 or int(allocation["value_cents"]) != scoops * unit_cost:
			return null
		allocation["lot_id"] = lot_id
		allocation["offer_id"] = String(offer_id)
		allocation["scoops"] = scoops
		allocation["unit_cost_cents"] = unit_cost
		allocation["value_cents"] = int(allocation["value_cents"])
		allocation_scoops += scoops
		allocation_value += int(allocation["value_cents"])
		var profile := OFFER_PROFILES[offer_id] as Dictionary
		weighted_strain += scoops * int(profile["strain_basis_points"])
		weighted_morale += scoops * int(profile["morale_millipoints"])
		weighted_grievance += scoops * int(profile["grievance_millipoints"])
	var demand := int(consumption["demand_scoops"])
	var spot_scoops := int(consumption["spot_scoops"])
	var spot_unit := int(consumption["spot_unit_price_cents"])
	if (
		demand < 0 or spot_scoops < 0 or spot_unit < 0
		or int(consumption["inventory_scoops"]) != allocation_scoops
		or demand != allocation_scoops + spot_scoops
		or int(consumption["spot_cost_cents"]) != spot_scoops * spot_unit
		or int(consumption["consumed_value_cents"]) != allocation_value + int(consumption["spot_cost_cents"])
		or bool(consumption["shortage_covered_automatically"]) != (spot_scoops > 0)
	):
		return null
	if demand > 0 and (
		int(consumption["strain_basis_points"]) != _half_up_ratio(weighted_strain, demand)
		or int(consumption["morale_millipoints"]) != _half_up_ratio(weighted_morale, demand)
		or int(consumption["grievance_millipoints"]) != _half_up_ratio(weighted_grievance, demand)
	):
		return null
	for key in CONSUMPTION_KEYS:
		if key not in ["allocations", "shortage_covered_automatically"]:
			consumption[key] = int(consumption[key])
	return consumption


static func _validated_last_spoilage(value: Variant, saved_day: int) -> Variant:
	if not value is Dictionary:
		return null
	var spoilage := (value as Dictionary).duplicate(true)
	if spoilage.is_empty():
		return spoilage
	if not _has_exact_keys(spoilage, SPOILAGE_KEYS):
		return null
	for key in ["day", "scoops", "value_cents"]:
		if not _is_integral_number(spoilage.get(key, null)):
			return null
	if int(spoilage["day"]) < 1 or int(spoilage["day"]) > saved_day:
		return null
	var lot_values: Variant = spoilage["lots"]
	if not lot_values is Array:
		return null
	var total_scoops := 0
	var total_value := 0
	for row_value in lot_values as Array:
		if not row_value is Dictionary:
			return null
		var row := row_value as Dictionary
		if not _has_exact_keys(row, SPOILED_LOT_KEYS):
			return null
		for key in SPOILED_LOT_KEYS:
			if key == "offer_id":
				continue
			if not _is_integral_number(row.get(key, null)):
				return null
		if not OFFER_PROFILES.has(StringName(String(row["offer_id"]))):
			return null
		var scoops := int(row["scoops"])
		var unit_cost := int(row["unit_cost_cents"])
		if scoops < 1 or unit_cost < 1 or int(row["value_cents"]) != scoops * unit_cost:
			return null
		row["lot_id"] = int(row["lot_id"])
		row["offer_id"] = String(StringName(String(row["offer_id"])))
		row["scoops"] = scoops
		row["unit_cost_cents"] = unit_cost
		row["value_cents"] = int(row["value_cents"])
		row["expired_day"] = int(row["expired_day"])
		total_scoops += scoops
		total_value += int(row["value_cents"])
	if total_scoops != int(spoilage["scoops"]) or total_value != int(spoilage["value_cents"]):
		return null
	spoilage["day"] = int(spoilage["day"])
	spoilage["scoops"] = int(spoilage["scoops"])
	spoilage["value_cents"] = int(spoilage["value_cents"])
	return spoilage
