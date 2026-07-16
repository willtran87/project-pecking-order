class_name CapitalBlueprintModel
extends RefCounted

## Read-only presentation model for the capital blueprint.
##
## All prices, obligations, gates, projections, plan state, and receipts are
## copied from the authoritative DepartmentSimulation snapshot. This model
## never estimates affordability and never mutates the economy.

const FILTER_ALL := &"all"
const FILTER_READY := &"ready"
const FILTER_BLOCKED := &"blocked"
const FILTER_OWNED := &"owned"

const CATEGORY_PRODUCTION := &"production"
const CATEGORY_FLOCK := &"flock"
const CATEGORY_GOVERNANCE := &"governance"

const FILTER_ORDER: Array[StringName] = [
	FILTER_ALL,
	FILTER_READY,
	FILTER_BLOCKED,
	FILTER_OWNED,
]

const FACILITY_ORDER: Array[StringName] = [
	&"candling_rework_bay",
	&"farmer_brand_packing_annex",
	&"records_annex",
	&"farmgate_dispatch_depot",
	&"wellness_nest_room",
	&"training_roost",
	&"flock_relations_office",
	&"farm_mutual_service_coop",
	&"farm_mutual_negotiation_room",
	&"rooster_operations_office",
	&"it_coop",
	&"feed_procurement_coop",
	&"farmer_relations_gallery",
]

const CATEGORY_DEFINITIONS: Array[Dictionary] = [
	{
		"id": CATEGORY_PRODUCTION,
		"label": "PRODUCTION",
		"facility_ids": [
			&"candling_rework_bay",
			&"farmer_brand_packing_annex",
			&"records_annex",
			&"farmgate_dispatch_depot",
		],
	},
	{
		"id": CATEGORY_FLOCK,
		"label": "FLOCK",
		"facility_ids": [
			&"wellness_nest_room",
			&"training_roost",
			&"flock_relations_office",
		],
	},
	{
		"id": CATEGORY_GOVERNANCE,
		"label": "GOVERNANCE",
		"facility_ids": [
			&"farm_mutual_service_coop",
			&"farm_mutual_negotiation_room",
			&"rooster_operations_office",
			&"it_coop",
			&"feed_procurement_coop",
			&"farmer_relations_gallery",
		],
	},
]

var _snapshot: Dictionary = {}
var _catalog_by_id: Dictionary = {}
var _capital_plan: Dictionary = {}
var _last_purchase_receipt: Dictionary = {}
var _pinned_facility_id := &""


func apply_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_catalog_by_id.clear()
	_capital_plan = _dictionary_value(snapshot.get("capital_plan", {})).duplicate(true)
	_last_purchase_receipt = _dictionary_value(
		snapshot.get("last_facility_purchase_receipt", {})
	).duplicate(true)
	_pinned_facility_id = _extract_pinned_facility_id(snapshot.get("capital_plan", {}))

	var authored_by_id: Dictionary = {}
	var catalog_value: Variant = snapshot.get("facility_catalog", [])
	if catalog_value is Array:
		for entry_value: Variant in catalog_value as Array:
			if not entry_value is Dictionary:
				continue
			var entry := entry_value as Dictionary
			var facility_id := StringName(String(entry.get("id", entry.get("facility_id", ""))))
			if facility_id != &"" and facility_id in FACILITY_ORDER and not authored_by_id.has(facility_id):
				authored_by_id[facility_id] = entry.duplicate(true)
	elif catalog_value is Dictionary:
		for facility_id: StringName in FACILITY_ORDER:
			var entry_value: Variant = (catalog_value as Dictionary).get(
				facility_id,
				(catalog_value as Dictionary).get(String(facility_id), {}),
			)
			if entry_value is Dictionary:
				authored_by_id[facility_id] = (entry_value as Dictionary).duplicate(true)

	for facility_id: StringName in FACILITY_ORDER:
		if not authored_by_id.has(facility_id):
			continue
		_catalog_by_id[facility_id] = _normalize_facility(
			facility_id,
			authored_by_id[facility_id] as Dictionary,
		)


func facilities(filter_id: StringName = FILTER_ALL) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for facility_id: StringName in FACILITY_ORDER:
		if not _catalog_by_id.has(facility_id):
			continue
		var facility := _catalog_by_id[facility_id] as Dictionary
		if _matches_filter(facility, filter_id):
			result.append(facility.duplicate(true))
	return result


func facility(facility_id: StringName) -> Dictionary:
	if not _catalog_by_id.has(facility_id):
		return {}
	return (_catalog_by_id[facility_id] as Dictionary).duplicate(true)


func categories() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition: Dictionary in CATEGORY_DEFINITIONS:
		result.append(definition.duplicate(true))
	return result


func category_for_facility(facility_id: StringName) -> StringName:
	for definition: Dictionary in CATEGORY_DEFINITIONS:
		for candidate: Variant in definition.get("facility_ids", []):
			if StringName(String(candidate)) == facility_id:
				return StringName(String(definition.get("id", "")))
	return &""


func category_label(category_id: StringName) -> String:
	for definition: Dictionary in CATEGORY_DEFINITIONS:
		if StringName(String(definition.get("id", ""))) == category_id:
			return String(definition.get("label", ""))
	return ""


func filter_counts() -> Dictionary:
	var result := {
		FILTER_ALL: facilities(FILTER_ALL).size(),
		FILTER_READY: facilities(FILTER_READY).size(),
		FILTER_BLOCKED: facilities(FILTER_BLOCKED).size(),
		FILTER_OWNED: facilities(FILTER_OWNED).size(),
	}
	return result


func capital_plan() -> Dictionary:
	return _capital_plan.duplicate(true)


func pinned_facility_id() -> StringName:
	return _pinned_facility_id


func last_purchase_receipt() -> Dictionary:
	return _last_purchase_receipt.duplicate(true)


func stable_facility_ids() -> Array[StringName]:
	return FACILITY_ORDER.duplicate()


func has_complete_catalog() -> bool:
	return _catalog_by_id.size() == FACILITY_ORDER.size()


func _normalize_facility(facility_id: StringName, source: Dictionary) -> Dictionary:
	var level := maxi(0, int(source.get("level", 0)))
	var max_level := maxi(1, int(source.get("max_level", maxi(1, level))))
	var installed := bool(source.get("installed", source.get("owned", level > 0))) or level > 0
	var maxed := bool(source.get("maxed", level >= max_level))
	var can_purchase := bool(source.get("can_purchase", source.get("available", false)))
	var category_id := category_for_facility(facility_id)
	var display_name := String(source.get(
		"name",
		source.get("display_name", String(facility_id).replace("_", " ").capitalize()),
	)).strip_edges()
	var short_name := String(source.get("short_name", display_name)).strip_edges()
	var reason := String(source.get("action_reason", source.get("reason", ""))).strip_edges()
	var next_level := maxi(level, int(source.get("next_level", mini(max_level, level + 1))))

	var gates := _copy_lines(source.get("gates", source.get("gate_lines", [])))
	if gates.is_empty() and not reason.is_empty():
		gates.append(reason)
	var benefits := _copy_lines(source.get(
		"benefit_lines",
		source.get("benefits", source.get("economic_effects", [])),
	))
	var tradeoffs := _copy_lines(source.get("tradeoff_lines", source.get("tradeoffs", [])))

	var why_now := String(source.get("why_now", "")).strip_edges()
	if why_now.is_empty():
		if not reason.is_empty():
			why_now = reason
		elif maxed:
			why_now = "%s is fully commissioned and operating." % short_name
		elif can_purchase:
			why_now = "The authoritative capital file is ready for level %d." % next_level
		else:
			why_now = "The next capital gate has not been filed."

	var normalized := source.duplicate(true)
	normalized.merge({
		"id": facility_id,
		"display_name": display_name,
		"short_name": short_name,
		"category_id": category_id,
		"category_label": category_label(category_id),
		"level": level,
		"next_level": next_level,
		"max_level": max_level,
		"installed": installed,
		"owned": installed,
		"maxed": maxed,
		"can_purchase": can_purchase,
		"pinned": facility_id == _pinned_facility_id,
		"readiness_id": _readiness_id(can_purchase, maxed),
		"readiness_label": _readiness_label(can_purchase, maxed, installed),
		"why_now": why_now,
		"benefit_lines": benefits,
		"tradeoff_lines": tradeoffs,
		"gate_lines": gates,
		"capital_cost_cents": int(source.get(
			"capital_cost_cents",
			source.get("next_level_cost_cents", source.get("cost_cents", 0)),
		)),
		"maintenance_delta_cents": int(source.get("maintenance_delta_cents", 0)),
		"supervisor_payroll_delta_cents": int(source.get("supervisor_payroll_delta_cents", 0)),
		"projected_spendable_fund_cents": int(source.get(
			"projected_spendable_fund_cents",
			source.get("spendable_fund_cents", 0),
		)),
		"has_projected_spendable": (
			source.has("projected_spendable_fund_cents")
			or source.has("spendable_fund_cents")
		),
		"projected_protected_reserve_cents": _projected_reserve_cents(source),
		"has_projected_protected_reserve": _has_projected_reserve(source),
	}, true)
	return normalized


func _matches_filter(facility: Dictionary, filter_id: StringName) -> bool:
	match filter_id:
		FILTER_READY:
			return bool(facility.get("can_purchase", false))
		FILTER_BLOCKED:
			return not bool(facility.get("can_purchase", false)) and not bool(facility.get("maxed", false))
		FILTER_OWNED:
			return bool(facility.get("installed", false))
		_:
			return true


func _extract_pinned_facility_id(plan_value: Variant) -> StringName:
	if plan_value is String or plan_value is StringName:
		return StringName(String(plan_value))
	if not plan_value is Dictionary:
		return &""
	var plan := plan_value as Dictionary
	return StringName(String(plan.get(
		"pinned_capital_plan_id",
		plan.get("facility_id", plan.get("pinned_facility_id", plan.get("id", ""))),
	)))


func _projected_reserve_cents(source: Dictionary) -> int:
	for key: String in [
		"projected_protected_reserve_cents",
		"projected_operating_reserve_cents",
		"projected_daily_operating_cost_cents",
		"protected_reserve_after_cents",
	]:
		if source.has(key):
			return int(source.get(key, 0))
	return 0


func _has_projected_reserve(source: Dictionary) -> bool:
	return (
		source.has("projected_protected_reserve_cents")
		or source.has("projected_operating_reserve_cents")
		or source.has("projected_daily_operating_cost_cents")
		or source.has("protected_reserve_after_cents")
	)


func _readiness_id(can_purchase: bool, maxed: bool) -> StringName:
	if can_purchase:
		return FILTER_READY
	if maxed:
		return FILTER_OWNED
	return FILTER_BLOCKED


func _readiness_label(can_purchase: bool, maxed: bool, installed: bool) -> String:
	if can_purchase:
		return "READY"
	if maxed:
		return "OWNED"
	if installed:
		return "OWNED / BLOCKED"
	return "BLOCKED"


func _copy_lines(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for line_value: Variant in value as Array:
			var line := String(line_value).strip_edges()
			if not line.is_empty():
				result.append(line)
	elif value is String or value is StringName:
		var line := String(value).strip_edges()
		if not line.is_empty():
			result.append(line)
	return result


func _dictionary_value(value: Variant) -> Dictionary:
	return value as Dictionary if value is Dictionary else {}
