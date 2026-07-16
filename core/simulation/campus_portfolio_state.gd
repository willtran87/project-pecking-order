class_name CampusPortfolioState
extends RefCounted


## Strict, money-agnostic construction ledger for the two portfolio parcels.
##
## DepartmentSimulation remains the transaction owner. It asks this object for a
## structural quote, performs its reserve-safe Feed Fund preflight, then calls an
## authorize method and applies the returned negative `fund_delta_cents` in the
## same synchronous transaction. Shared utility capacity and the current worker
## directory are supplied as primitive context, so this state never reaches into
## the simulation or SceneTree.

const SAVE_VERSION := 1
const HISTORY_LIMIT := 512
const PROJECT_LIMIT := 8
const BASE_CONTRACTOR_CAPACITY := 1
const CONTRACTOR_ROOST_CAPACITY_BONUS := 1
const CAMPUS_DUTY_PREMIUM_CENTS := 100
const DEFAULT_FARMGATE_OVERFLOW_BASIS_POINTS := 9_000
const CHILLING_EXCHANGE_OVERFLOW_BASIS_POINTS := 9_500

const ORCHARD_ROW: StringName = &"orchard_row"
const CREEKSIDE_YARD: StringName = &"creekside_yard"
const PARCEL_ORDER: Array[StringName] = [ORCHARD_ROW, CREEKSIDE_YARD]

const ORCHARD_WEST: StringName = &"orchard_west"
const ORCHARD_EAST: StringName = &"orchard_east"
const CREEKSIDE_WEST: StringName = &"creekside_west"
const CREEKSIDE_EAST: StringName = &"creekside_east"
const PAD_ORDER: Array[StringName] = [
	ORCHARD_WEST,
	ORCHARD_EAST,
	CREEKSIDE_WEST,
	CREEKSIDE_EAST,
]

const COLLECTION_RAIL_HUB: StringName = &"collection_rail_hub"
const GRAIN_RECOVERY_MILL: StringName = &"grain_recovery_mill"
const CREEKSIDE_CHILLING_EXCHANGE: StringName = &"creekside_chilling_exchange"
const CONTRACTOR_ROOST: StringName = &"contractor_roost"
const MODULE_ORDER: Array[StringName] = [
	COLLECTION_RAIL_HUB,
	GRAIN_RECOVERY_MILL,
	CREEKSIDE_CHILLING_EXCHANGE,
	CONTRACTOR_ROOST,
]

const PARCEL_DEFINITIONS := {
	ORCHARD_ROW: {
		"name": "ORCHARD ROW",
		"deed_cost_cents": 12_500,
		"daily_cost_cents": 450,
		"unlock_day": 6,
		"required_parcel_id": &"",
		"pads": [ORCHARD_WEST, ORCHARD_EAST],
	},
	CREEKSIDE_YARD: {
		"name": "CREEKSIDE YARD",
		"deed_cost_cents": 16_500,
		"daily_cost_cents": 550,
		"unlock_day": 9,
		"required_parcel_id": ORCHARD_ROW,
		"pads": [CREEKSIDE_WEST, CREEKSIDE_EAST],
	},
}

const PAD_DEFINITIONS := {
	ORCHARD_WEST: {"name": "ORCHARD WEST PAD", "parcel_id": ORCHARD_ROW},
	ORCHARD_EAST: {"name": "ORCHARD EAST PAD", "parcel_id": ORCHARD_ROW},
	CREEKSIDE_WEST: {"name": "CREEKSIDE WEST PAD", "parcel_id": CREEKSIDE_YARD},
	CREEKSIDE_EAST: {"name": "CREEKSIDE EAST PAD", "parcel_id": CREEKSIDE_YARD},
}

const MODULE_DEFINITIONS := {
	COLLECTION_RAIL_HUB: {
		"name": "COLLECTION RAIL HUB",
		"parcel_id": ORCHARD_ROW,
		"capital_cost_cents": 14_000,
		"daily_cost_cents": 600,
		"duration_shifts": 2,
		"contractor_slots": 1,
		"power_units": 1,
		"cold_units": 0,
		"claim_capacity_bonus": 4,
		"good_egg_bonus_cents": 25,
		"benefits": [
			"+4 live claim slots while staffed and powered",
			"+$0.25 to every sound or golden egg while staffed and powered",
		],
		"tradeoffs": [
			"Adds $6.00 daily upkeep after construction",
			"Reserves 1 shared power unit and one named hen for campus duty",
		],
	},
	GRAIN_RECOVERY_MILL: {
		"name": "GRAIN RECOVERY MILL",
		"parcel_id": ORCHARD_ROW,
		"capital_cost_cents": 16_000,
		"daily_cost_cents": 700,
		"duration_shifts": 3,
		"contractor_slots": 1,
		"power_units": 2,
		"cold_units": 0,
		"feed_capacity_bonus_scoops": 18,
		"feed_demand_reduction_scoops": 1,
		"benefits": [
			"+18 scoops of prepaid grain storage while staffed and powered",
			"Reduces staffed daily feed demand by exactly 1 scoop",
		],
		"tradeoffs": [
			"Adds $7.00 daily upkeep after construction",
			"Reserves 2 shared power units and one named hen for campus duty",
		],
	},
	CREEKSIDE_CHILLING_EXCHANGE: {
		"name": "CREEKSIDE CHILLING EXCHANGE",
		"parcel_id": CREEKSIDE_YARD,
		"capital_cost_cents": 20_000,
		"daily_cost_cents": 900,
		"duration_shifts": 3,
		"contractor_slots": 2,
		"power_units": 1,
		"cold_units": 2,
		"farmgate_capacity_bonus_eggs": 12,
		"overflow_basis_points": CHILLING_EXCHANGE_OVERFLOW_BASIS_POINTS,
		"benefits": [
			"+12 finished-egg storage positions while staffed and powered",
			"Raises staffed overflow pickup from 90% to 95% of recorded value",
		],
		"tradeoffs": [
			"Adds $9.00 daily upkeep after construction",
			"Reserves 1 power unit, 2 cold-chain units, 2 contractor slots, and one named hen",
		],
	},
	CONTRACTOR_ROOST: {
		"name": "CONTRACTOR ROOST",
		"parcel_id": CREEKSIDE_YARD,
		"capital_cost_cents": 13_000,
		"daily_cost_cents": 500,
		"duration_shifts": 2,
		"contractor_slots": 1,
		"power_units": 1,
		"cold_units": 0,
		"contractor_capacity_bonus": CONTRACTOR_ROOST_CAPACITY_BONUS,
		"benefits": [
			"Adds 1 contractor slot while staffed and powered",
			"Allows the two-slot Chilling Exchange project to be authorized",
		],
		"tradeoffs": [
			"Adds $5.00 daily upkeep after construction",
			"Reserves 1 shared power unit and one named hen for contractor coordination",
		],
	},
}

const SAVE_KEYS: Array[String] = [
	"version",
	"current_day",
	"parcels",
	"modules",
	"projects",
	"next_project_id",
	"next_receipt_id",
	"capital_spend_total_cents",
	"last_receipt",
	"history",
]
const MODULE_STATE_KEYS: Array[String] = ["installed", "pad_id", "worker_id"]
const PROJECT_KEYS: Array[String] = [
	"project_id",
	"module_id",
	"parcel_id",
	"pad_id",
	"status",
	"authorized_day",
	"started_day",
	"duration_shifts",
	"remaining_shifts",
	"contractor_slots",
	"power_units",
	"cold_units",
	"capital_cost_cents",
	"daily_cost_cents",
]
const RECEIPT_KEYS: Array[String] = [
	"receipt_id",
	"day",
	"action_id",
	"parcel_id",
	"module_id",
	"pad_id",
	"project_id",
	"worker_id",
	"cost_cents",
	"added_daily_cost_cents",
	"duration_shifts",
	"contractor_slots",
	"power_units",
	"cold_units",
	"status",
	"fund_delta_cents",
	"outcome",
]

var current_day: int = 1
var parcels: Dictionary = {}
var modules: Dictionary = {}
var projects: Array[Dictionary] = []
var next_project_id: int = 1
var next_receipt_id: int = 1
var capital_spend_total_cents: int = 0
var last_receipt: Dictionary = {}
var history: Array[Dictionary] = []

var _last_context: Dictionary = {}


func _init(day: int = 1) -> void:
	_apply_neutral(day)


static func neutral_save_data(day: int = 1) -> Dictionary:
	var neutral_parcels: Dictionary = {}
	for parcel_id: StringName in PARCEL_ORDER:
		neutral_parcels[String(parcel_id)] = false
	var neutral_modules: Dictionary = {}
	for module_id: StringName in MODULE_ORDER:
		neutral_modules[String(module_id)] = {
			"installed": false,
			"pad_id": "",
			"worker_id": -1,
		}
	return {
		"version": SAVE_VERSION,
		"current_day": clampi(day, 1, 9999),
		"parcels": neutral_parcels,
		"modules": neutral_modules,
		"projects": [],
		"next_project_id": 1,
		"next_receipt_id": 1,
		"capital_spend_total_cents": 0,
		"last_receipt": {},
		"history": [],
	}


func _apply_neutral(day: int) -> void:
	_apply_save_data_unchecked(neutral_save_data(day))


func quote_deed(parcel_id: StringName, context: Dictionary = {}) -> Dictionary:
	_remember_context(context)
	var definition: Dictionary = PARCEL_DEFINITIONS.get(parcel_id, {}) as Dictionary
	var day := int(context.get("day", current_day))
	var known := not definition.is_empty()
	var reason := ""
	if not known:
		reason = "That parcel is not on the authorized campus portfolio."
	elif day != current_day:
		reason = "The parcel quote is stale; refresh the current review day."
	elif not bool(context.get("planning_open", true)):
		reason = "Campus deeds may only be filed during clear review planning."
	elif bool(parcels.get(String(parcel_id), false)):
		reason = "%s is already held by the bureau." % String(definition["name"])
	elif not _receipt_capacity_available(1):
		reason = "The campus receipt archive must clear before another deed can be filed."
	elif day < int(definition["unlock_day"]):
		reason = "%s becomes available on Day %d." % [definition["name"], definition["unlock_day"]]
	else:
		var required_parcel := StringName(definition.get("required_parcel_id", &""))
		if required_parcel != &"" and not bool(parcels.get(String(required_parcel), false)):
			reason = "File the %s deed before opening %s." % [
				String((PARCEL_DEFINITIONS[required_parcel] as Dictionary)["name"]),
				String(definition["name"]),
			]
	if reason.is_empty() and not bool(context.get("can_fund", true)):
		reason = String(context.get(
			"fund_reason",
			"The Feed Fund cannot cover this deed and its recurring land obligation.",
		))
	var cost := int(definition.get("deed_cost_cents", 0))
	var daily := int(definition.get("daily_cost_cents", 0))
	return {
		"accepted": false,
		"known": known,
		"action_id": &"purchase_deed",
		"parcel_id": parcel_id,
		"module_id": &"",
		"pad_id": &"",
		"can_authorize": reason.is_empty(),
		"ready": reason.is_empty(),
		"reason": reason,
		"name": String(definition.get("name", "UNKNOWN PARCEL")),
		"cost_cents": cost,
		"added_daily_cost_cents": daily,
		"duration_shifts": 0,
		"contractor_slots": 0,
		"power_units": 0,
		"cold_units": 0,
		"project_status": &"complete",
		"fund_delta_cents": -cost,
		"current_daily_cost_cents": daily_cost_cents(),
		"projected_daily_cost_cents": daily_cost_cents() + daily,
	}


func authorize_deed(
	parcel_id: StringName,
	day: int,
	context: Dictionary = {},
) -> Dictionary:
	var effective_context := context.duplicate(true)
	effective_context["day"] = day
	var quote := quote_deed(parcel_id, effective_context)
	if not bool(quote.get("can_authorize", false)):
		return quote
	parcels[String(parcel_id)] = true
	capital_spend_total_cents += int(quote["cost_cents"])
	var receipt := _make_receipt({
		"day": day,
		"action_id": &"purchase_deed",
		"parcel_id": parcel_id,
		"cost_cents": int(quote["cost_cents"]),
		"added_daily_cost_cents": int(quote["added_daily_cost_cents"]),
		"status": &"complete",
	})
	_append_receipt(receipt)
	return _accepted_result(quote, receipt)


func quote_project(
	module_id: StringName,
	pad_id: StringName,
	context: Dictionary = {},
) -> Dictionary:
	_remember_context(context)
	var definition: Dictionary = MODULE_DEFINITIONS.get(module_id, {}) as Dictionary
	var pad_definition: Dictionary = PAD_DEFINITIONS.get(pad_id, {}) as Dictionary
	var day := int(context.get("day", current_day))
	var known := not definition.is_empty()
	var parcel_id := StringName(definition.get("parcel_id", &""))
	var required_slots := int(definition.get("contractor_slots", 0))
	var power_units := int(definition.get("power_units", 0))
	var cold_units := int(definition.get("cold_units", 0))
	var contractor_capacity := contractor_capacity_slots(context)
	var active_slots := _active_contractor_slots()
	var queue_exists := _has_queued_projects()
	var projected_status: StringName = (
		&"active"
		if not queue_exists and active_slots + required_slots <= contractor_capacity else
		&"queued"
	)
	var power_before := _reserved_power_units()
	var cold_before := _reserved_cold_units()
	var power_capacity := _power_capacity(context)
	var cold_capacity := _cold_capacity(context)
	var reason := ""
	if not known:
		reason = "That module is not on the authorized campus portfolio."
	elif day != current_day:
		reason = "The construction quote is stale; refresh the current review day."
	elif not bool(context.get("planning_open", true)):
		reason = "Construction may only be authorized during clear review planning."
	elif not bool(parcels.get(String(parcel_id), false)):
		reason = "Purchase the %s deed before authorizing this module." % String(
			(PARCEL_DEFINITIONS[parcel_id] as Dictionary)["name"]
		)
	elif pad_definition.is_empty():
		reason = "Select a listed portfolio construction pad."
	elif StringName(pad_definition.get("parcel_id", &"")) != parcel_id:
		reason = "%s may only be built on a %s pad." % [
			String(definition["name"]),
			String((PARCEL_DEFINITIONS[parcel_id] as Dictionary)["name"]),
		]
	elif _module_is_installed_or_reserved(module_id):
		reason = "%s is already installed or under contract." % String(definition["name"])
	elif _pad_is_occupied_or_reserved(pad_id):
		reason = "%s is already occupied or reserved by another project." % String(
			pad_definition["name"]
		)
	elif projects.size() >= PROJECT_LIMIT:
		reason = "The contractor queue is full."
	elif (
		history.size()
		+ _future_project_receipt_count()
		+ (2 if projected_status == &"active" else 3)
		> HISTORY_LIMIT
	):
		reason = "The campus construction receipt archive is full."
	elif required_slots > contractor_capacity:
		reason = "%s requires %d contractor slots; staff and power the Contractor Roost first." % [
			String(definition["name"]), required_slots,
		]
	elif power_before + power_units > power_capacity:
		reason = "%s needs %d shared power unit%s; only %d remain unreserved." % [
			String(definition["name"]),
			power_units,
			"s" if power_units != 1 else "",
			maxi(0, power_capacity - power_before),
		]
	elif cold_before + cold_units > cold_capacity:
		reason = "%s needs %d cold-chain unit%s; only %d remain unreserved." % [
			String(definition["name"]),
			cold_units,
			"s" if cold_units != 1 else "",
			maxi(0, cold_capacity - cold_before),
		]
	if reason.is_empty() and not bool(context.get("can_fund", true)):
		reason = String(context.get(
			"fund_reason",
			"The Feed Fund cannot cover this project and its completed daily obligation.",
		))
	var cost := int(definition.get("capital_cost_cents", 0))
	var daily := int(definition.get("daily_cost_cents", 0))
	return {
		"accepted": false,
		"known": known,
		"action_id": &"authorize_project",
		"parcel_id": parcel_id,
		"module_id": module_id,
		"pad_id": pad_id,
		"can_authorize": reason.is_empty(),
		"ready": reason.is_empty(),
		"reason": reason,
		"name": String(definition.get("name", "UNKNOWN MODULE")),
		"cost_cents": cost,
		"added_daily_cost_cents": daily,
		"duration_shifts": int(definition.get("duration_shifts", 0)),
		"contractor_slots": required_slots,
		"power_units": power_units,
		"cold_units": cold_units,
		"project_status": projected_status,
		"fund_delta_cents": -cost,
		"current_daily_cost_cents": daily_cost_cents(),
		"projected_daily_cost_cents": daily_cost_cents() + daily,
		"contractor_capacity_slots": contractor_capacity,
		"active_contractor_slots": active_slots,
		"power_capacity_units": power_capacity,
		"power_reserved_before_units": power_before,
		"power_reserved_after_units": power_before + power_units,
		"cold_capacity_units": cold_capacity,
		"cold_reserved_before_units": cold_before,
		"cold_reserved_after_units": cold_before + cold_units,
		"benefits": (definition.get("benefits", []) as Array).duplicate(true),
		"tradeoffs": (definition.get("tradeoffs", []) as Array).duplicate(true),
	}


func authorize_project(
	module_id: StringName,
	pad_id: StringName,
	day: int,
	context: Dictionary = {},
) -> Dictionary:
	var effective_context := context.duplicate(true)
	effective_context["day"] = day
	var quote := quote_project(module_id, pad_id, effective_context)
	if not bool(quote.get("can_authorize", false)):
		return quote
	var definition := MODULE_DEFINITIONS[module_id] as Dictionary
	var project_id := next_project_id
	next_project_id += 1
	var status := StringName(quote["project_status"])
	var project := {
		"project_id": project_id,
		"module_id": String(module_id),
		"parcel_id": String(quote["parcel_id"]),
		"pad_id": String(pad_id),
		"status": String(status),
		"authorized_day": day,
		"started_day": day if status == &"active" else 0,
		"duration_shifts": int(definition["duration_shifts"]),
		"remaining_shifts": int(definition["duration_shifts"]),
		"contractor_slots": int(definition["contractor_slots"]),
		"power_units": int(definition["power_units"]),
		"cold_units": int(definition["cold_units"]),
		"capital_cost_cents": int(definition["capital_cost_cents"]),
		"daily_cost_cents": int(definition["daily_cost_cents"]),
	}
	projects.append(project)
	capital_spend_total_cents += int(definition["capital_cost_cents"])
	var receipt := _make_receipt({
		"day": day,
		"action_id": &"authorize_project",
		"parcel_id": quote["parcel_id"],
		"module_id": module_id,
		"pad_id": pad_id,
		"project_id": project_id,
		"cost_cents": int(definition["capital_cost_cents"]),
		"added_daily_cost_cents": int(definition["daily_cost_cents"]),
		"duration_shifts": int(definition["duration_shifts"]),
		"contractor_slots": int(definition["contractor_slots"]),
		"power_units": int(definition["power_units"]),
		"cold_units": int(definition["cold_units"]),
		"status": status,
	})
	_append_receipt(receipt)
	return _accepted_result(quote, receipt, project)


func begin_day(day: int, network_context: Dictionary = {}) -> Dictionary:
	_remember_context(network_context)
	if day < current_day or day > 9999:
		return {
			"accepted": false,
			"reason": "Construction day cannot move backward or beyond the campaign limit.",
		}
	if day == current_day:
		return {
			"accepted": true,
			"days_advanced": 0,
			"completed": [],
			"started": [],
		}
	var completed: Array[Dictionary] = []
	var started: Array[Dictionary] = []
	var start_day := current_day
	for next_day in range(current_day + 1, day + 1):
		var day_result := _progress_one_day(next_day, network_context)
		completed.append_array(day_result.get("completed", []) as Array)
		started.append_array(day_result.get("started", []) as Array)
		current_day = next_day
	return {
		"accepted": true,
		"days_advanced": day - start_day,
		"completed": completed,
		"started": started,
	}


func assign_worker(
	module_id: StringName,
	worker_id: int,
	valid_worker_ids: Array,
	network_context: Dictionary = {},
) -> Dictionary:
	_remember_context(network_context)
	if not MODULE_DEFINITIONS.has(module_id):
		return _rejection(&"assign_worker", "That module is not on the campus portfolio.")
	var module_state := _module_state(module_id)
	if not bool(module_state.get("installed", false)):
		return _rejection(&"assign_worker", "Complete the module before assigning campus duty.")
	if worker_id not in _normalized_worker_ids(valid_worker_ids):
		return _rejection(&"assign_worker", "Select a currently employed hen for campus duty.")
	for other_id: StringName in MODULE_ORDER:
		if other_id != module_id and int(_module_state(other_id).get("worker_id", -1)) == worker_id:
			return _rejection(&"assign_worker", "That hen is already assigned to another campus module.")
	var previous_worker := int(module_state.get("worker_id", -1))
	if previous_worker == worker_id:
		return {
			"accepted": true,
			"changed": false,
			"action_id": &"assign_worker",
			"module_id": module_id,
			"worker_id": worker_id,
			"reason": "",
		}
	if not _receipt_capacity_available(1):
		return _rejection(&"assign_worker", "The campus receipt archive must clear before duty changes.")
	module_state["worker_id"] = worker_id
	modules[String(module_id)] = module_state
	_last_context["valid_worker_ids"] = _normalized_worker_ids(valid_worker_ids)
	var receipt := _make_receipt({
		"day": current_day,
		"action_id": &"assign_worker",
		"parcel_id": (MODULE_DEFINITIONS[module_id] as Dictionary)["parcel_id"],
		"module_id": module_id,
		"pad_id": module_state["pad_id"],
		"worker_id": worker_id,
		"added_daily_cost_cents": CAMPUS_DUTY_PREMIUM_CENTS if previous_worker < 0 else 0,
		"status": &"staffed",
	})
	_append_receipt(receipt)
	var started := _promote_queue(_context_with_workers(network_context, valid_worker_ids), current_day)
	return {
		"accepted": true,
		"changed": true,
		"action_id": &"assign_worker",
		"module_id": module_id,
		"worker_id": worker_id,
		"previous_worker_id": previous_worker,
		"reason": "",
		"receipt": receipt.duplicate(true),
		"started": started,
	}


func unassign_worker(
	module_id: StringName,
	valid_worker_ids: Array = [],
	network_context: Dictionary = {},
) -> Dictionary:
	_remember_context(network_context)
	if not MODULE_DEFINITIONS.has(module_id):
		return _rejection(&"unassign_worker", "That module is not on the campus portfolio.")
	var module_state := _module_state(module_id)
	var worker_id := int(module_state.get("worker_id", -1))
	if worker_id < 0:
		return {
			"accepted": true,
			"changed": false,
			"action_id": &"unassign_worker",
			"module_id": module_id,
			"worker_id": -1,
			"reason": "",
		}
	if module_id == CONTRACTOR_ROOST:
		for project in projects:
			if int(project.get("contractor_slots", 0)) > BASE_CONTRACTOR_CAPACITY:
				return _rejection(
					&"unassign_worker",
					"The Contractor Roost must stay staffed while a two-slot project is active or queued.",
				)
	if not _receipt_capacity_available(1):
		return _rejection(&"unassign_worker", "The campus receipt archive must clear before duty changes.")
	module_state["worker_id"] = -1
	modules[String(module_id)] = module_state
	if not valid_worker_ids.is_empty():
		_last_context["valid_worker_ids"] = _normalized_worker_ids(valid_worker_ids)
	var receipt := _make_receipt({
		"day": current_day,
		"action_id": &"unassign_worker",
		"parcel_id": (MODULE_DEFINITIONS[module_id] as Dictionary)["parcel_id"],
		"module_id": module_id,
		"pad_id": module_state["pad_id"],
		"worker_id": worker_id,
		"added_daily_cost_cents": -CAMPUS_DUTY_PREMIUM_CENTS,
		"status": &"unstaffed",
	})
	_append_receipt(receipt)
	return {
		"accepted": true,
		"changed": true,
		"action_id": &"unassign_worker",
		"module_id": module_id,
		"worker_id": worker_id,
		"reason": "",
		"receipt": receipt.duplicate(true),
	}


func daily_cost_cents() -> int:
	var total := 0
	for parcel_id: StringName in PARCEL_ORDER:
		if bool(parcels.get(String(parcel_id), false)):
			total += int((PARCEL_DEFINITIONS[parcel_id] as Dictionary)["daily_cost_cents"])
	for module_id: StringName in MODULE_ORDER:
		var state := _module_state(module_id)
		if bool(state.get("installed", false)):
			total += int((MODULE_DEFINITIONS[module_id] as Dictionary)["daily_cost_cents"])
			if int(state.get("worker_id", -1)) >= 0:
				total += CAMPUS_DUTY_PREMIUM_CENTS
	return total


func claim_capacity_bonus(context: Dictionary = {}) -> int:
	return 4 if _module_operational(COLLECTION_RAIL_HUB, context) else 0


func good_egg_bonus_cents(context: Dictionary = {}) -> int:
	return 25 if _module_operational(COLLECTION_RAIL_HUB, context) else 0


func claim_value_bonus_cents(context: Dictionary = {}) -> int:
	return good_egg_bonus_cents(context)


func feed_capacity_bonus_scoops(context: Dictionary = {}) -> int:
	return 18 if _module_operational(GRAIN_RECOVERY_MILL, context) else 0


func feed_demand_reduction_scoops(context: Dictionary = {}) -> int:
	return 1 if _module_operational(GRAIN_RECOVERY_MILL, context) else 0


func farmgate_capacity_bonus_eggs(context: Dictionary = {}) -> int:
	return 12 if _module_operational(CREEKSIDE_CHILLING_EXCHANGE, context) else 0


func farmgate_storage_bonus_eggs(context: Dictionary = {}) -> int:
	return farmgate_capacity_bonus_eggs(context)


func farmgate_overflow_basis_points(context: Dictionary = {}) -> int:
	return (
		CHILLING_EXCHANGE_OVERFLOW_BASIS_POINTS
		if _module_operational(CREEKSIDE_CHILLING_EXCHANGE, context) else
		DEFAULT_FARMGATE_OVERFLOW_BASIS_POINTS
	)


func farmgate_overflow_value_basis_points(context: Dictionary = {}) -> int:
	return farmgate_overflow_basis_points(context)


func contractor_capacity_slots(context: Dictionary = {}) -> int:
	return (
		BASE_CONTRACTOR_CAPACITY
		+ (CONTRACTOR_ROOST_CAPACITY_BONUS if _module_operational(CONTRACTOR_ROOST, context) else 0)
	)


func snapshot(context: Dictionary = {}) -> Dictionary:
	_remember_context(context)
	var effective_context := _merged_context(context)
	var parcel_rows: Array[Dictionary] = []
	for parcel_id: StringName in PARCEL_ORDER:
		var definition := PARCEL_DEFINITIONS[parcel_id] as Dictionary
		var quote := quote_deed(parcel_id, effective_context)
		var pad_rows: Array[Dictionary] = []
		for pad_id: StringName in definition["pads"]:
			pad_rows.append({
				"id": pad_id,
				"name": String((PAD_DEFINITIONS[pad_id] as Dictionary)["name"]),
				"occupied": _pad_has_installed_module(pad_id),
				"reserved": _pad_has_project(pad_id),
				"module_id": _module_at_pad(pad_id),
			})
		parcel_rows.append({
			"id": parcel_id,
			"name": String(definition["name"]),
			"owned": bool(parcels.get(String(parcel_id), false)),
			"deed_cost_cents": int(definition["deed_cost_cents"]),
			"daily_cost_cents": int(definition["daily_cost_cents"]),
			"unlock_day": int(definition["unlock_day"]),
			"can_purchase": bool(quote.get("can_authorize", false)),
			"reason": String(quote.get("reason", "")),
			"quote": quote.duplicate(true),
			"pads": pad_rows,
		})
	var module_rows: Array[Dictionary] = []
	var worker_names := _worker_names(effective_context)
	for module_id: StringName in MODULE_ORDER:
		var definition := MODULE_DEFINITIONS[module_id] as Dictionary
		var state := _module_state(module_id)
		var worker_id := int(state.get("worker_id", -1))
		var placement_quotes: Array[Dictionary] = []
		for pad_id: StringName in (PARCEL_DEFINITIONS[definition["parcel_id"]] as Dictionary)["pads"]:
			placement_quotes.append(quote_project(module_id, pad_id, effective_context))
		module_rows.append({
			"id": module_id,
			"name": String(definition["name"]),
			"parcel_id": definition["parcel_id"],
			"installed": bool(state.get("installed", false)),
			"reserved": _module_has_project(module_id),
			"pad_id": StringName(String(state.get("pad_id", ""))),
			"worker_id": worker_id,
			"worker_name": String(worker_names.get(worker_id, worker_names.get(str(worker_id), ""))),
			"staffed": _module_staffed(module_id, effective_context),
			"powered": _network_is_sufficient(effective_context),
			"operational": _module_operational(module_id, effective_context),
			"capital_cost_cents": int(definition["capital_cost_cents"]),
			"daily_cost_cents": int(definition["daily_cost_cents"]),
			"duty_premium_cents": CAMPUS_DUTY_PREMIUM_CENTS,
			"duration_shifts": int(definition["duration_shifts"]),
			"contractor_slots": int(definition["contractor_slots"]),
			"power_units": int(definition["power_units"]),
			"cold_units": int(definition["cold_units"]),
			"benefits": (definition["benefits"] as Array).duplicate(true),
			"tradeoffs": (definition["tradeoffs"] as Array).duplicate(true),
			"placement_quotes": placement_quotes,
		})
	var power_capacity := _power_capacity(effective_context)
	var cold_capacity := _cold_capacity(effective_context)
	var power_reserved := _reserved_power_units()
	var cold_reserved := _reserved_cold_units()
	var capacity := contractor_capacity_slots(effective_context)
	var active_slots := _active_contractor_slots()
	return {
		"version": SAVE_VERSION,
		"current_day": current_day,
		"planning_open": bool(effective_context.get("planning_open", true)),
		"daily_cost_cents": daily_cost_cents(),
		"capital_spend_total_cents": capital_spend_total_cents,
		"contractor": {
			"capacity_slots": capacity,
			"active_slots": active_slots,
			"available_slots": maxi(0, capacity - active_slots),
			"queue_count": _queued_project_count(),
		},
		"network": {
			"power_capacity_units": power_capacity,
			"power_reserved_units": power_reserved,
			"power_available_units": maxi(0, power_capacity - power_reserved),
			"cold_capacity_units": cold_capacity,
			"cold_reserved_units": cold_reserved,
			"cold_available_units": maxi(0, cold_capacity - cold_reserved),
			"sufficient": _network_is_sufficient(effective_context),
		},
		"parcels": parcel_rows,
		"modules": module_rows,
		"projects": projects.duplicate(true),
		"workers": _assignment_rows(worker_names),
		"bonuses": {
			"claim_capacity": claim_capacity_bonus(effective_context),
			"good_egg_cents": good_egg_bonus_cents(effective_context),
			"feed_capacity_scoops": feed_capacity_bonus_scoops(effective_context),
			"feed_demand_reduction_scoops": feed_demand_reduction_scoops(effective_context),
			"farmgate_capacity_eggs": farmgate_capacity_bonus_eggs(effective_context),
			"farmgate_overflow_basis_points": farmgate_overflow_basis_points(effective_context),
		},
		"last_receipt": last_receipt.duplicate(true),
		"history": history.duplicate(true),
	}


func to_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"current_day": current_day,
		"parcels": parcels.duplicate(true),
		"modules": modules.duplicate(true),
		"projects": projects.duplicate(true),
		"next_project_id": next_project_id,
		"next_receipt_id": next_receipt_id,
		"capital_spend_total_cents": capital_spend_total_cents,
		"last_receipt": last_receipt.duplicate(true),
		"history": history.duplicate(true),
	}


func restore_save_data(
	source: Variant,
	saved_day: int,
	valid_worker_ids: Array,
	network_context: Dictionary = {},
) -> bool:
	if not source is Dictionary or saved_day < 1 or saved_day > 9999:
		return false
	var data := source as Dictionary
	if not _has_exact_keys(data, SAVE_KEYS):
		return false
	if (
		not _is_integral(data.get("version"))
		or int(data["version"]) != SAVE_VERSION
		or not _is_integral(data.get("current_day"))
		or int(data["current_day"]) != saved_day
		or not data.get("parcels") is Dictionary
		or not data.get("modules") is Dictionary
		or not data.get("projects") is Array
		or not _is_integral(data.get("next_project_id"))
		or not _is_integral(data.get("next_receipt_id"))
		or not _is_integral(data.get("capital_spend_total_cents"))
		or not data.get("last_receipt") is Dictionary
		or not data.get("history") is Array
	):
		return false
	var normalized_parcels := _validated_parcels(data["parcels"])
	if normalized_parcels.is_empty():
		return false
	var worker_ids := _normalized_worker_ids(valid_worker_ids)
	var normalized_modules := _validated_modules(data["modules"], normalized_parcels, worker_ids)
	if normalized_modules.is_empty():
		return false
	var normalized_projects: Variant = _validated_projects(
		data["projects"],
		saved_day,
		normalized_parcels,
		normalized_modules,
	)
	if normalized_projects == null:
		return false
	var project_rows: Array[Dictionary] = []
	project_rows.assign(normalized_projects as Array)
	var normalized_history: Variant = _validated_history(
		data["history"],
		saved_day,
		normalized_parcels,
		normalized_modules,
		project_rows,
	)
	if normalized_history == null:
		return false
	var history_rows: Array[Dictionary] = []
	history_rows.assign(normalized_history as Array)
	var max_project_id := 0
	var expected_spend := 0
	for receipt in history_rows:
		max_project_id = maxi(max_project_id, int(receipt["project_id"]))
		if StringName(receipt["action_id"]) in [&"purchase_deed", &"authorize_project"]:
			expected_spend += int(receipt["cost_cents"])
	if (
		int(data["next_project_id"]) != max_project_id + 1
		or int(data["next_receipt_id"]) != history_rows.size() + 1
		or int(data["capital_spend_total_cents"]) != expected_spend
		or expected_spend < 0 or expected_spend > 2_000_000_000
	):
		return false
	var normalized_last: Dictionary = {}
	if history_rows.is_empty():
		if not (data["last_receipt"] as Dictionary).is_empty():
			return false
	else:
		normalized_last = history_rows[-1].duplicate(true)
		# Compare the raw checkpoint copies before numeric normalization so a
		# canonical JSON round trip (which decodes integers as exact floats) is
		# accepted without weakening the immutable-last-receipt invariant.
		if data["last_receipt"] != (data["history"] as Array)[-1]:
			return false
	var validation_context := network_context.duplicate(true)
	validation_context["valid_worker_ids"] = worker_ids
	validation_context["day"] = saved_day
	# Instantiate through this script resource so direct headless-script tests do
	# not depend on the editor's global class-name cache being regenerated first.
	var probe: Variant = get_script().new(saved_day)
	probe.parcels = normalized_parcels.duplicate(true)
	probe.modules = normalized_modules.duplicate(true)
	probe.projects = project_rows.duplicate(true)
	# Utility capacity is live simulation context, not duplicated portfolio save
	# state. When a caller omits it, validate against the checkpoint's exact
	# reservations; supplied capacities remain strict and may reject the restore.
	if not network_context.has("power_capacity_units"):
		validation_context["power_capacity_units"] = probe._reserved_power_units()
	if not network_context.has("cold_capacity_units"):
		validation_context["cold_capacity_units"] = probe._reserved_cold_units()
	if probe._active_contractor_slots() > probe.contractor_capacity_slots(validation_context):
		return false
	if history_rows.size() + probe._future_project_receipt_count() > HISTORY_LIMIT:
		return false
	for project in probe.projects:
		if int(project["contractor_slots"]) > probe.contractor_capacity_slots(validation_context):
			return false
	if (
		network_context.has("power_capacity_units")
		and probe._reserved_power_units() > probe._power_capacity(validation_context)
	):
		return false
	if (
		network_context.has("cold_capacity_units")
		and probe._reserved_cold_units() > probe._cold_capacity(validation_context)
	):
		return false
	# Commit only after every structural, receipt, worker, and optional network
	# invariant succeeds. A rejected checkpoint leaves this object unchanged.
	current_day = saved_day
	parcels = normalized_parcels.duplicate(true)
	modules = normalized_modules.duplicate(true)
	projects = project_rows.duplicate(true)
	next_project_id = int(data["next_project_id"])
	next_receipt_id = int(data["next_receipt_id"])
	capital_spend_total_cents = expected_spend
	last_receipt = normalized_last
	history = history_rows.duplicate(true)
	# Keep only the caller's live network facts. Synthetic capacities above are
	# validation scaffolding and must never make an unpowered module operational.
	_last_context = network_context.duplicate(true)
	_last_context["valid_worker_ids"] = worker_ids
	_last_context["day"] = saved_day
	return true


func _progress_one_day(day: int, context: Dictionary) -> Dictionary:
	var completed: Array[Dictionary] = []
	var completed_indices: Array[int] = []
	# Only projects active at the opening of this boundary receive work. Projects
	# promoted after a completion start on this day and first progress tomorrow.
	for index in projects.size():
		var project := projects[index] as Dictionary
		if StringName(project["status"]) != &"active":
			continue
		project["remaining_shifts"] = int(project["remaining_shifts"]) - 1
		projects[index] = project
		if int(project["remaining_shifts"]) <= 0:
			completed_indices.append(index)
	for reverse_index in range(completed_indices.size() - 1, -1, -1):
		var project_index := completed_indices[reverse_index]
		var project := projects[project_index] as Dictionary
		var module_id := StringName(project["module_id"])
		var module_state := _module_state(module_id)
		module_state["installed"] = true
		module_state["pad_id"] = String(project["pad_id"])
		module_state["worker_id"] = -1
		modules[String(module_id)] = module_state
		projects.remove_at(project_index)
		var receipt := _make_receipt({
			"day": day,
			"action_id": &"complete_project",
			"parcel_id": project["parcel_id"],
			"module_id": module_id,
			"pad_id": project["pad_id"],
			"project_id": int(project["project_id"]),
			"duration_shifts": int(project["duration_shifts"]),
			"contractor_slots": int(project["contractor_slots"]),
			"power_units": int(project["power_units"]),
			"cold_units": int(project["cold_units"]),
			"status": &"complete",
		})
		_append_receipt(receipt)
		completed.push_front({
			"project_id": int(project["project_id"]),
			"module_id": module_id,
			"pad_id": StringName(project["pad_id"]),
			"receipt": receipt.duplicate(true),
		})
	var started := _promote_queue(context, day)
	return {"completed": completed, "started": started}


func _promote_queue(context: Dictionary, day: int) -> Array[Dictionary]:
	var started: Array[Dictionary] = []
	var capacity := contractor_capacity_slots(context)
	var active_slots := _active_contractor_slots()
	for index in projects.size():
		var project := projects[index] as Dictionary
		if StringName(project["status"]) != &"queued":
			continue
		var slots := int(project["contractor_slots"])
		if active_slots + slots > capacity:
			# Strict FIFO: a large head project blocks younger small jobs.
			break
		project["status"] = "active"
		project["started_day"] = day
		projects[index] = project
		active_slots += slots
		var receipt := _make_receipt({
			"day": day,
			"action_id": &"start_project",
			"parcel_id": project["parcel_id"],
			"module_id": project["module_id"],
			"pad_id": project["pad_id"],
			"project_id": int(project["project_id"]),
			"duration_shifts": int(project["duration_shifts"]),
			"contractor_slots": slots,
			"power_units": int(project["power_units"]),
			"cold_units": int(project["cold_units"]),
			"status": &"active",
		})
		_append_receipt(receipt)
		started.append({
			"project_id": int(project["project_id"]),
			"module_id": StringName(project["module_id"]),
			"pad_id": StringName(project["pad_id"]),
			"receipt": receipt.duplicate(true),
		})
	return started


func _module_operational(module_id: StringName, context: Dictionary) -> bool:
	var effective := _merged_context(context)
	return (
		bool(_module_state(module_id).get("installed", false))
		and _module_staffed(module_id, effective)
		and _network_is_sufficient(effective)
	)


func _module_staffed(module_id: StringName, context: Dictionary) -> bool:
	var worker_id := int(_module_state(module_id).get("worker_id", -1))
	if worker_id < 0:
		return false
	var effective := _merged_context(context)
	if not effective.has("valid_worker_ids"):
		return true
	return worker_id in _context_worker_ids(effective)


func _network_is_sufficient(context: Dictionary) -> bool:
	return (
		_reserved_power_units() <= _power_capacity(context)
		and _reserved_cold_units() <= _cold_capacity(context)
	)


func _reserved_power_units() -> int:
	var total := 0
	for module_id: StringName in MODULE_ORDER:
		if bool(_module_state(module_id).get("installed", false)):
			total += int((MODULE_DEFINITIONS[module_id] as Dictionary)["power_units"])
	for project in projects:
		total += int(project.get("power_units", 0))
	return total


func _reserved_cold_units() -> int:
	var total := 0
	for module_id: StringName in MODULE_ORDER:
		if bool(_module_state(module_id).get("installed", false)):
			total += int((MODULE_DEFINITIONS[module_id] as Dictionary)["cold_units"])
	for project in projects:
		total += int(project.get("cold_units", 0))
	return total


func _active_contractor_slots() -> int:
	var total := 0
	for project in projects:
		if StringName(project.get("status", &"")) == &"active":
			total += int(project.get("contractor_slots", 0))
	return total


func _has_queued_projects() -> bool:
	return _queued_project_count() > 0


func _queued_project_count() -> int:
	var count := 0
	for project in projects:
		if StringName(project.get("status", &"")) == &"queued":
			count += 1
	return count


func _future_project_receipt_count() -> int:
	var count := 0
	for project in projects:
		count += 1 if StringName(project.get("status", &"")) == &"active" else 2
	return count


func _receipt_capacity_available(additional_receipts: int) -> bool:
	return (
		history.size()
		+ _future_project_receipt_count()
		+ maxi(0, additional_receipts)
		<= HISTORY_LIMIT
	)


func _module_is_installed_or_reserved(module_id: StringName) -> bool:
	return bool(_module_state(module_id).get("installed", false)) or _module_has_project(module_id)


func _module_has_project(module_id: StringName) -> bool:
	for project in projects:
		if StringName(project.get("module_id", &"")) == module_id:
			return true
	return false


func _pad_is_occupied_or_reserved(pad_id: StringName) -> bool:
	return _pad_has_installed_module(pad_id) or _pad_has_project(pad_id)


func _pad_has_installed_module(pad_id: StringName) -> bool:
	for module_id: StringName in MODULE_ORDER:
		var state := _module_state(module_id)
		if bool(state.get("installed", false)) and StringName(state.get("pad_id", &"")) == pad_id:
			return true
	return false


func _pad_has_project(pad_id: StringName) -> bool:
	for project in projects:
		if StringName(project.get("pad_id", &"")) == pad_id:
			return true
	return false


func _module_at_pad(pad_id: StringName) -> StringName:
	for module_id: StringName in MODULE_ORDER:
		var state := _module_state(module_id)
		if bool(state.get("installed", false)) and StringName(state.get("pad_id", &"")) == pad_id:
			return module_id
	for project in projects:
		if StringName(project.get("pad_id", &"")) == pad_id:
			return StringName(project.get("module_id", &""))
	return &""


func _module_state(module_id: StringName) -> Dictionary:
	var value: Variant = modules.get(String(module_id), {})
	return value as Dictionary if value is Dictionary else {}


func _make_receipt(fields: Dictionary) -> Dictionary:
	var action_id := StringName(fields.get("action_id", &""))
	var parcel_id := StringName(fields.get("parcel_id", &""))
	var module_id := StringName(fields.get("module_id", &""))
	var pad_id := StringName(fields.get("pad_id", &""))
	var status := StringName(fields.get("status", &"complete"))
	var receipt := {
		"receipt_id": next_receipt_id,
		"day": int(fields.get("day", current_day)),
		"action_id": String(action_id),
		"parcel_id": String(parcel_id),
		"module_id": String(module_id),
		"pad_id": String(pad_id),
		"project_id": int(fields.get("project_id", 0)),
		"worker_id": int(fields.get("worker_id", -1)),
		"cost_cents": int(fields.get("cost_cents", 0)),
		"added_daily_cost_cents": int(fields.get("added_daily_cost_cents", 0)),
		"duration_shifts": int(fields.get("duration_shifts", 0)),
		"contractor_slots": int(fields.get("contractor_slots", 0)),
		"power_units": int(fields.get("power_units", 0)),
		"cold_units": int(fields.get("cold_units", 0)),
		"status": String(status),
		"fund_delta_cents": -int(fields.get("cost_cents", 0)),
		"outcome": _receipt_outcome(action_id, parcel_id, module_id, pad_id, status, int(fields.get("worker_id", -1))),
	}
	return receipt


func _append_receipt(receipt: Dictionary) -> void:
	if history.size() >= HISTORY_LIMIT:
		push_error("Campus portfolio receipt archive overflow; authorization should have been blocked.")
		return
	history.append(receipt.duplicate(true))
	last_receipt = receipt.duplicate(true)
	next_receipt_id += 1


func _receipt_outcome(
	action_id: StringName,
	parcel_id: StringName,
	module_id: StringName,
	pad_id: StringName,
	status: StringName,
	worker_id: int,
) -> String:
	match action_id:
		&"purchase_deed":
			return "%s deed filed with its recurring land obligation." % String((PARCEL_DEFINITIONS[parcel_id] as Dictionary)["name"])
		&"authorize_project":
			return "%s authorized at %s; contractor status is %s." % [
				String((MODULE_DEFINITIONS[module_id] as Dictionary)["name"]),
				String((PAD_DEFINITIONS[pad_id] as Dictionary)["name"]),
				String(status).to_upper(),
			]
		&"start_project":
			return "%s moved from the FIFO queue onto the active contractor board." % String((MODULE_DEFINITIONS[module_id] as Dictionary)["name"])
		&"complete_project":
			return "%s construction completed; benefits wait for named staff and live utilities." % String((MODULE_DEFINITIONS[module_id] as Dictionary)["name"])
		&"assign_worker":
			return "Worker #%d assigned to %s campus duty." % [worker_id, String((MODULE_DEFINITIONS[module_id] as Dictionary)["name"])]
		&"unassign_worker":
			return "Worker #%d released from %s campus duty." % [worker_id, String((MODULE_DEFINITIONS[module_id] as Dictionary)["name"])]
	return "Campus portfolio record filed."


func _accepted_result(quote: Dictionary, receipt: Dictionary, project: Dictionary = {}) -> Dictionary:
	var result := quote.duplicate(true)
	result["accepted"] = true
	result["can_authorize"] = false
	result["ready"] = false
	result["reason"] = ""
	result["receipt"] = receipt.duplicate(true)
	result["outcome"] = receipt["outcome"]
	if not project.is_empty():
		result["project"] = project.duplicate(true)
	return result


func _rejection(action_id: StringName, reason: String) -> Dictionary:
	return {
		"accepted": false,
		"action_id": action_id,
		"reason": reason,
	}


func _assignment_rows(worker_names: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for module_id: StringName in MODULE_ORDER:
		var worker_id := int(_module_state(module_id).get("worker_id", -1))
		if worker_id < 0:
			continue
		rows.append({
			"module_id": module_id,
			"worker_id": worker_id,
			"worker_name": String(worker_names.get(worker_id, worker_names.get(str(worker_id), ""))),
			"daily_premium_cents": CAMPUS_DUTY_PREMIUM_CENTS,
		})
	return rows


func _validated_parcels(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var source := value as Dictionary
	if source.size() != PARCEL_ORDER.size():
		return {}
	var normalized: Dictionary = {}
	for parcel_id: StringName in PARCEL_ORDER:
		var key := String(parcel_id)
		if not source.has(key) or typeof(source[key]) != TYPE_BOOL:
			return {}
		normalized[key] = bool(source[key])
	if bool(normalized[String(CREEKSIDE_YARD)]) and not bool(normalized[String(ORCHARD_ROW)]):
		return {}
	return normalized


func _validated_modules(value: Variant, restored_parcels: Dictionary, valid_worker_ids: Array[int]) -> Dictionary:
	if not value is Dictionary:
		return {}
	var source := value as Dictionary
	if source.size() != MODULE_ORDER.size():
		return {}
	var normalized: Dictionary = {}
	var occupied_pads: Dictionary = {}
	var assigned_workers: Dictionary = {}
	for module_id: StringName in MODULE_ORDER:
		var key := String(module_id)
		if not source.has(key) or not source[key] is Dictionary:
			return {}
		var state := source[key] as Dictionary
		if not _has_exact_keys(state, MODULE_STATE_KEYS):
			return {}
		if typeof(state.get("installed")) != TYPE_BOOL or not _is_integral(state.get("worker_id")):
			return {}
		if typeof(state.get("pad_id")) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {}
		var installed := bool(state["installed"])
		var pad_id := StringName(String(state["pad_id"]))
		var worker_id := int(state["worker_id"])
		var definition := MODULE_DEFINITIONS[module_id] as Dictionary
		var parcel_id := StringName(definition["parcel_id"])
		if not installed:
			if pad_id != &"" or worker_id != -1:
				return {}
		else:
			if (
				not bool(restored_parcels.get(String(parcel_id), false))
				or not PAD_DEFINITIONS.has(pad_id)
				or StringName((PAD_DEFINITIONS[pad_id] as Dictionary)["parcel_id"]) != parcel_id
				or occupied_pads.has(pad_id)
			):
				return {}
			occupied_pads[pad_id] = true
			if worker_id >= 0:
				if worker_id not in valid_worker_ids or assigned_workers.has(worker_id):
					return {}
				assigned_workers[worker_id] = true
			elif worker_id != -1:
				return {}
		normalized[key] = {
			"installed": installed,
			"pad_id": String(pad_id),
			"worker_id": worker_id,
		}
	return normalized


func _validated_projects(
	value: Variant,
	saved_day: int,
	restored_parcels: Dictionary,
	restored_modules: Dictionary,
) -> Variant:
	if not value is Array or (value as Array).size() > PROJECT_LIMIT:
		return null
	var normalized: Array[Dictionary] = []
	var seen_ids: Dictionary = {}
	var seen_modules: Dictionary = {}
	var reserved_pads: Dictionary = {}
	var encountered_queue := false
	var previous_project_id := 0
	for module_id: StringName in MODULE_ORDER:
		var state := restored_modules[String(module_id)] as Dictionary
		if bool(state["installed"]):
			reserved_pads[StringName(state["pad_id"])] = true
	for row_value in value as Array:
		if not row_value is Dictionary:
			return null
		var row := row_value as Dictionary
		if not _has_exact_keys(row, PROJECT_KEYS):
			return null
		for field in [
			"project_id", "authorized_day", "started_day", "duration_shifts",
			"remaining_shifts", "contractor_slots", "power_units", "cold_units",
			"capital_cost_cents", "daily_cost_cents",
		]:
			if not _is_integral(row.get(field)):
				return null
		for field in ["module_id", "parcel_id", "pad_id", "status"]:
			if typeof(row.get(field)) not in [TYPE_STRING, TYPE_STRING_NAME]:
				return null
		var project_id := int(row["project_id"])
		var module_id := StringName(String(row["module_id"]))
		var parcel_id := StringName(String(row["parcel_id"]))
		var pad_id := StringName(String(row["pad_id"]))
		var status := StringName(String(row["status"]))
		if (
			project_id < 1 or project_id <= previous_project_id or seen_ids.has(project_id)
			or not MODULE_DEFINITIONS.has(module_id)
			or seen_modules.has(module_id)
			or bool((restored_modules[String(module_id)] as Dictionary)["installed"])
			or not PAD_DEFINITIONS.has(pad_id) or reserved_pads.has(pad_id)
			or status not in [&"active", &"queued"]
		):
			return null
		var definition := MODULE_DEFINITIONS[module_id] as Dictionary
		if (
			parcel_id != StringName(definition["parcel_id"])
			or StringName((PAD_DEFINITIONS[pad_id] as Dictionary)["parcel_id"]) != parcel_id
			or not bool(restored_parcels.get(String(parcel_id), false))
			or int(row["authorized_day"]) < 1 or int(row["authorized_day"]) > saved_day
			or int(row["duration_shifts"]) != int(definition["duration_shifts"])
			or int(row["contractor_slots"]) != int(definition["contractor_slots"])
			or int(row["power_units"]) != int(definition["power_units"])
			or int(row["cold_units"]) != int(definition["cold_units"])
			or int(row["capital_cost_cents"]) != int(definition["capital_cost_cents"])
			or int(row["daily_cost_cents"]) != int(definition["daily_cost_cents"])
		):
			return null
		var duration := int(row["duration_shifts"])
		var remaining := int(row["remaining_shifts"])
		var started_day := int(row["started_day"])
		if status == &"queued":
			encountered_queue = true
			if started_day != 0 or remaining != duration:
				return null
		else:
			if encountered_queue or started_day < int(row["authorized_day"]) or started_day > saved_day:
				return null
			var expected_remaining := duration - (saved_day - started_day)
			if expected_remaining <= 0 or remaining != expected_remaining:
				return null
		seen_ids[project_id] = true
		previous_project_id = project_id
		seen_modules[module_id] = true
		reserved_pads[pad_id] = true
		var copy := row.duplicate(true)
		for field in [
			"project_id", "authorized_day", "started_day", "duration_shifts",
			"remaining_shifts", "contractor_slots", "power_units", "cold_units",
			"capital_cost_cents", "daily_cost_cents",
		]:
			copy[field] = int(copy[field])
		for field in ["module_id", "parcel_id", "pad_id", "status"]:
			copy[field] = String(copy[field])
		normalized.append(copy)
	return normalized


func _validated_history(
	value: Variant,
	saved_day: int,
	restored_parcels: Dictionary,
	restored_modules: Dictionary,
	restored_projects: Array[Dictionary],
) -> Variant:
	if not value is Array or (value as Array).size() > HISTORY_LIMIT:
		return null
	var normalized: Array[Dictionary] = []
	var replay_parcels: Dictionary = {}
	for parcel_id: StringName in PARCEL_ORDER:
		replay_parcels[String(parcel_id)] = false
	var project_lifecycle: Dictionary = {}
	var completed_modules: Dictionary = {}
	var assignments: Dictionary = {}
	var assigned_workers: Dictionary = {}
	var previous_day := 0
	for index in (value as Array).size():
		var row_value: Variant = (value as Array)[index]
		if not row_value is Dictionary:
			return null
		var receipt := row_value as Dictionary
		if not _has_exact_keys(receipt, RECEIPT_KEYS):
			return null
		for field in [
			"receipt_id", "day", "project_id", "worker_id", "cost_cents",
			"added_daily_cost_cents", "duration_shifts", "contractor_slots",
			"power_units", "cold_units", "fund_delta_cents",
		]:
			if not _is_integral(receipt.get(field)):
				return null
		for field in ["action_id", "parcel_id", "module_id", "pad_id", "status", "outcome"]:
			if typeof(receipt.get(field)) not in [TYPE_STRING, TYPE_STRING_NAME]:
				return null
		var receipt_day := int(receipt["day"])
		var action_id := StringName(String(receipt["action_id"]))
		var parcel_id := StringName(String(receipt["parcel_id"]))
		var module_id := StringName(String(receipt["module_id"]))
		var pad_id := StringName(String(receipt["pad_id"]))
		var status := StringName(String(receipt["status"]))
		var project_id := int(receipt["project_id"])
		var worker_id := int(receipt["worker_id"])
		if (
			int(receipt["receipt_id"]) != index + 1
			or receipt_day < previous_day or receipt_day < 1 or receipt_day > saved_day
			or int(receipt["fund_delta_cents"]) != -int(receipt["cost_cents"])
		):
			return null
		previous_day = receipt_day
		match action_id:
			&"purchase_deed":
				if (
					not PARCEL_DEFINITIONS.has(parcel_id)
					or bool(replay_parcels[String(parcel_id)])
					or module_id != &"" or pad_id != &"" or project_id != 0 or worker_id != -1
					or int(receipt["duration_shifts"]) != 0
					or int(receipt["contractor_slots"]) != 0
					or int(receipt["power_units"]) != 0
					or int(receipt["cold_units"]) != 0
				):
					return null
				var parcel_definition := PARCEL_DEFINITIONS[parcel_id] as Dictionary
				var required_parcel := StringName(parcel_definition["required_parcel_id"])
				if required_parcel != &"" and not bool(replay_parcels[String(required_parcel)]):
					return null
				if (
					int(receipt["cost_cents"]) != int(parcel_definition["deed_cost_cents"])
					or int(receipt["added_daily_cost_cents"]) != int(parcel_definition["daily_cost_cents"])
					or receipt_day < int(parcel_definition["unlock_day"])
					or status != &"complete"
				):
					return null
				replay_parcels[String(parcel_id)] = true
			&"authorize_project":
				if not _receipt_matches_module(receipt, true) or project_lifecycle.has(project_id):
					return null
				if not bool(replay_parcels.get(String(parcel_id), false)):
					return null
				project_lifecycle[project_id] = {
					"module_id": module_id,
					"pad_id": pad_id,
					"status": status,
					"started_day": receipt_day if status == &"active" else 0,
				}
			&"start_project":
				if not _receipt_matches_module(receipt, false) or not project_lifecycle.has(project_id):
					return null
				var lifecycle := project_lifecycle[project_id] as Dictionary
				if (
					StringName(lifecycle["status"]) != &"queued"
					or StringName(lifecycle["module_id"]) != module_id
					or StringName(lifecycle["pad_id"]) != pad_id
					or status != &"active"
				):
					return null
				lifecycle["status"] = "active"
				lifecycle["started_day"] = receipt_day
				project_lifecycle[project_id] = lifecycle
			&"complete_project":
				if not _receipt_matches_module(receipt, false) or not project_lifecycle.has(project_id):
					return null
				var lifecycle := project_lifecycle[project_id] as Dictionary
				if (
					StringName(lifecycle["status"]) != &"active"
					or StringName(lifecycle["module_id"]) != module_id
					or StringName(lifecycle["pad_id"]) != pad_id
					or status != &"complete"
					or receipt_day != int(lifecycle["started_day"]) + int(receipt["duration_shifts"])
				):
					return null
				completed_modules[module_id] = pad_id
				project_lifecycle.erase(project_id)
			&"assign_worker":
				var assignment_definition: Dictionary = MODULE_DEFINITIONS.get(module_id, {}) as Dictionary
				var old_worker := int(assignments.get(module_id, -1))
				if (
					assignment_definition.is_empty()
					or not completed_modules.has(module_id)
					or parcel_id != StringName(assignment_definition["parcel_id"])
					or pad_id != StringName(completed_modules[module_id])
					or worker_id < 0 or assigned_workers.has(worker_id)
					or project_id != 0
					or status != &"staffed"
					or int(receipt["cost_cents"]) != 0
					or int(receipt["added_daily_cost_cents"]) != (CAMPUS_DUTY_PREMIUM_CENTS if old_worker < 0 else 0)
					or int(receipt["duration_shifts"]) != 0
					or int(receipt["contractor_slots"]) != 0
					or int(receipt["power_units"]) != 0
					or int(receipt["cold_units"]) != 0
				):
					return null
				if old_worker >= 0:
					assigned_workers.erase(old_worker)
				assignments[module_id] = worker_id
				assigned_workers[worker_id] = module_id
			&"unassign_worker":
				var assignment_definition: Dictionary = MODULE_DEFINITIONS.get(module_id, {}) as Dictionary
				if (
					assignment_definition.is_empty()
					or not completed_modules.has(module_id)
					or parcel_id != StringName(assignment_definition["parcel_id"])
					or pad_id != StringName(completed_modules[module_id])
					or int(assignments.get(module_id, -1)) != worker_id
					or project_id != 0
					or status != &"unstaffed"
					or int(receipt["cost_cents"]) != 0
					or int(receipt["added_daily_cost_cents"]) != -CAMPUS_DUTY_PREMIUM_CENTS
					or int(receipt["duration_shifts"]) != 0
					or int(receipt["contractor_slots"]) != 0
					or int(receipt["power_units"]) != 0
					or int(receipt["cold_units"]) != 0
				):
					return null
				assignments.erase(module_id)
				assigned_workers.erase(worker_id)
			_:
				return null
		if String(receipt["outcome"]) != _receipt_outcome(
			action_id, parcel_id, module_id, pad_id, status, worker_id
		):
			return null
		var copy := receipt.duplicate(true)
		for field in [
			"receipt_id", "day", "project_id", "worker_id", "cost_cents",
			"added_daily_cost_cents", "duration_shifts", "contractor_slots",
			"power_units", "cold_units", "fund_delta_cents",
		]:
			copy[field] = int(copy[field])
		for field in ["action_id", "parcel_id", "module_id", "pad_id", "status", "outcome"]:
			copy[field] = String(copy[field])
		normalized.append(copy)
	if replay_parcels != restored_parcels:
		return null
	for module_id: StringName in MODULE_ORDER:
		var state := restored_modules[String(module_id)] as Dictionary
		if bool(state["installed"]) != completed_modules.has(module_id):
			return null
		if bool(state["installed"]) and StringName(state["pad_id"]) != StringName(completed_modules[module_id]):
			return null
		if int(state["worker_id"]) != int(assignments.get(module_id, -1)):
			return null
	var restored_by_id: Dictionary = {}
	for project in restored_projects:
		restored_by_id[int(project["project_id"])] = project
	if restored_by_id.size() != project_lifecycle.size():
		return null
	for project_id in project_lifecycle:
		if not restored_by_id.has(project_id):
			return null
		var lifecycle := project_lifecycle[project_id] as Dictionary
		var project := restored_by_id[project_id] as Dictionary
		if (
			StringName(lifecycle["module_id"]) != StringName(project["module_id"])
			or StringName(lifecycle["pad_id"]) != StringName(project["pad_id"])
			or StringName(lifecycle["status"]) != StringName(project["status"])
			or int(lifecycle["started_day"]) != int(project["started_day"])
		):
			return null
	return normalized


func _receipt_matches_module(receipt: Dictionary, authorization: bool) -> bool:
	var module_id := StringName(String(receipt["module_id"]))
	var parcel_id := StringName(String(receipt["parcel_id"]))
	var pad_id := StringName(String(receipt["pad_id"]))
	if not MODULE_DEFINITIONS.has(module_id) or not PAD_DEFINITIONS.has(pad_id):
		return false
	var definition := MODULE_DEFINITIONS[module_id] as Dictionary
	if (
		parcel_id != StringName(definition["parcel_id"])
		or StringName((PAD_DEFINITIONS[pad_id] as Dictionary)["parcel_id"]) != parcel_id
		or int(receipt["duration_shifts"]) != int(definition["duration_shifts"])
		or int(receipt["contractor_slots"]) != int(definition["contractor_slots"])
		or int(receipt["power_units"]) != int(definition["power_units"])
		or int(receipt["cold_units"]) != int(definition["cold_units"])
	):
		return false
	if authorization:
		return (
			int(receipt["project_id"]) > 0
			and int(receipt["worker_id"]) == -1
			and int(receipt["cost_cents"]) == int(definition["capital_cost_cents"])
			and int(receipt["added_daily_cost_cents"]) == int(definition["daily_cost_cents"])
			and StringName(String(receipt["status"])) in [&"active", &"queued"]
		)
	return (
		int(receipt["project_id"]) > 0
		and int(receipt["worker_id"]) == -1
		and int(receipt["cost_cents"]) == 0
		and int(receipt["added_daily_cost_cents"]) == 0
	)


func _apply_save_data_unchecked(data: Dictionary) -> void:
	current_day = int(data["current_day"])
	parcels = (data["parcels"] as Dictionary).duplicate(true)
	modules = (data["modules"] as Dictionary).duplicate(true)
	projects.clear()
	projects.assign((data["projects"] as Array).duplicate(true))
	next_project_id = int(data["next_project_id"])
	next_receipt_id = int(data["next_receipt_id"])
	capital_spend_total_cents = int(data["capital_spend_total_cents"])
	last_receipt = (data["last_receipt"] as Dictionary).duplicate(true)
	history.clear()
	history.assign((data["history"] as Array).duplicate(true))


func _has_exact_keys(value: Dictionary, expected: Array[String]) -> bool:
	if value.size() != expected.size():
		return false
	for key in expected:
		if not value.has(key):
			return false
	return true


func _is_integral(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) != TYPE_FLOAT:
		return false
	var number := float(value)
	return is_finite(number) and number == floor(number)


func _remember_context(context: Dictionary) -> void:
	if context.is_empty():
		return
	for key in ["power_capacity_units", "cold_capacity_units", "valid_worker_ids", "worker_names"]:
		if context.has(key):
			_last_context[key] = context[key]


func _merged_context(context: Dictionary) -> Dictionary:
	var merged := _last_context.duplicate(true)
	merged.merge(context, true)
	if not merged.has("day"):
		merged["day"] = current_day
	return merged


func _context_with_workers(context: Dictionary, worker_ids: Array) -> Dictionary:
	var result := _merged_context(context)
	result["valid_worker_ids"] = worker_ids.duplicate()
	return result


func _power_capacity(context: Dictionary) -> int:
	return maxi(0, int(_merged_context(context).get("power_capacity_units", 0)))


func _cold_capacity(context: Dictionary) -> int:
	return maxi(0, int(_merged_context(context).get("cold_capacity_units", 0)))


func _context_worker_ids(context: Dictionary) -> Array[int]:
	var merged := _merged_context(context)
	var value: Variant = merged.get("valid_worker_ids", [])
	return _normalized_worker_ids(value as Array if value is Array else [])


func _normalized_worker_ids(values: Array) -> Array[int]:
	var result: Array[int] = []
	for value in values:
		if not _is_integral(value):
			continue
		var worker_id := int(value)
		if worker_id >= 0 and worker_id not in result:
			result.append(worker_id)
	result.sort()
	return result


func _worker_names(context: Dictionary) -> Dictionary:
	var merged := _merged_context(context)
	var value: Variant = merged.get("worker_names", {})
	return value as Dictionary if value is Dictionary else {}
