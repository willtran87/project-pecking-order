class_name CampusPortfolioModel
extends RefCounted

## Read-only adapter for the multi-parcel campus portfolio projection.
##
## The model accepts either a complete simulation snapshot containing
## `campus_portfolio` or the portfolio projection itself. Collection fields may
## be arrays or dictionaries keyed by stable identity. Nothing in this class
## spends Feed Fund, advances construction, assigns a worker, or invents an
## authorization quote.

const CANONICAL_PARCEL_ORDER: Array[StringName] = [
	&"north_meadow",
	&"orchard_row",
	&"creekside_yard",
]

var _projection: Dictionary = {}
var _snapshot_context: Dictionary = {}
var _resources: Dictionary = {}
var _parcels: Array[Dictionary] = []
var _pads: Array[Dictionary] = []
var _modules: Array[Dictionary] = []
var _projects: Array[Dictionary] = []
var _workers: Array[Dictionary] = []
var _assignments: Dictionary = {}

var _parcels_by_id: Dictionary = {}
var _pads_by_id: Dictionary = {}
var _modules_by_id: Dictionary = {}
var _projects_by_id: Dictionary = {}
var _workers_by_key: Dictionary = {}


func set_snapshot(snapshot: Dictionary) -> void:
	_snapshot_context = snapshot.duplicate(true)
	var source_value: Variant = snapshot.get("campus_portfolio", snapshot)
	_projection = _dictionary(source_value).duplicate(true)
	var resource_source := _snapshot_context.duplicate(true)
	resource_source.merge(_projection, true)
	resource_source.merge(_dictionary(_snapshot_context.get("resources", {})), true)
	resource_source.merge(_dictionary(_projection.get("resources", {})), true)
	_resources = _normalize_resources(resource_source)
	_rebuild_parcels()
	_rebuild_pads()
	_rebuild_modules()
	_rebuild_projects()
	_rebuild_workers()
	_assignments = _normalize_assignments(_projection.get(
		"assignments",
		_projection.get("staff_assignments", _snapshot_context.get("assignments", {})),
	))
	if _assignments.is_empty():
		for module_record: Dictionary in _modules:
			var worker_id: Variant = module_record.get("worker_id", null)
			if worker_id != null and (not worker_id is int or int(worker_id) >= 0) and not str(worker_id).is_empty():
				_assignments[StringName(String(module_record.get("id", "")))] = worker_id


func apply_snapshot(snapshot: Dictionary) -> void:
	set_snapshot(snapshot)


func has_projection() -> bool:
	if _projection.is_empty():
		return false
	for key: String in ["resources", "parcels", "pads", "module_catalog", "modules", "projects", "active_projects", "workers", "assignments"]:
		if _projection.has(key):
			return true
	return false


func projection() -> Dictionary:
	return _projection.duplicate(true)


func resources() -> Dictionary:
	return _resources.duplicate(true)


func parcels() -> Array[Dictionary]:
	return _parcels.duplicate(true)


func parcel(parcel_id: StringName) -> Dictionary:
	return _copy_record(_parcels_by_id, parcel_id)


func parcel_ids() -> Array[StringName]:
	return _record_ids(_parcels)


func pads(parcel_id: StringName = &"") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record: Dictionary in _pads:
		if parcel_id == &"" or StringName(String(record.get("parcel_id", ""))) == parcel_id:
			result.append(record.duplicate(true))
	return result


func pad(pad_id: StringName) -> Dictionary:
	return _copy_record(_pads_by_id, pad_id)


func pad_ids(parcel_id: StringName = &"") -> Array[StringName]:
	return _record_ids(pads(parcel_id))


func modules(parcel_id: StringName = &"") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record: Dictionary in _modules:
		var filed_parcel := StringName(String(record.get("parcel_id", "")))
		if parcel_id == &"" or filed_parcel == &"" or filed_parcel == parcel_id:
			result.append(record.duplicate(true))
	return result


func module(module_id: StringName) -> Dictionary:
	return _copy_record(_modules_by_id, module_id)


func module_ids(parcel_id: StringName = &"") -> Array[StringName]:
	return _record_ids(modules(parcel_id))


func projects() -> Array[Dictionary]:
	return _projects.duplicate(true)


func project(job_id: StringName) -> Dictionary:
	return _copy_record(_projects_by_id, job_id)


func projects_for_parcel(parcel_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record: Dictionary in _projects:
		var project_parcel := StringName(String(record.get("parcel_id", "")))
		if project_parcel == parcel_id:
			result.append(record.duplicate(true))
	return result


func project_for_module(module_id: StringName) -> Dictionary:
	for record: Dictionary in _projects:
		if StringName(String(record.get("module_id", ""))) == module_id:
			return record.duplicate(true)
	return {}


func workers() -> Array[Dictionary]:
	return _workers.duplicate(true)


func worker(worker_id: Variant) -> Dictionary:
	return _copy_record(_workers_by_key, _variant_key(worker_id))


func assignments() -> Dictionary:
	return _assignments.duplicate(true)


func has_assignment(module_id: StringName) -> bool:
	return _assignments.has(module_id) or _assignments.has(String(module_id))


func assignment_for(module_id: StringName) -> Variant:
	if _assignments.has(module_id):
		return _assignments[module_id]
	if _assignments.has(String(module_id)):
		return _assignments[String(module_id)]
	return null


func default_parcel_id() -> StringName:
	var requested := _first_id(_projection, ["selected_parcel_id", "focused_parcel_id", "parcel_id"])
	if _parcels_by_id.has(requested):
		return requested
	for project_record: Dictionary in _projects:
		var active_parcel := StringName(String(project_record.get("parcel_id", "")))
		if _parcels_by_id.has(active_parcel):
			return active_parcel
	return StringName(String(_parcels[0].get("id", ""))) if not _parcels.is_empty() else &""


func default_pad_id(parcel_id: StringName) -> StringName:
	var requested := _first_id(_projection, ["selected_pad_id", "focused_pad_id", "pad_id"])
	var requested_pad := pad(requested)
	if not requested_pad.is_empty() and StringName(String(requested_pad.get("parcel_id", ""))) == parcel_id:
		return requested
	for project_record: Dictionary in projects_for_parcel(parcel_id):
		var active_pad := StringName(String(project_record.get("pad_id", "")))
		if _pads_by_id.has(active_pad):
			return active_pad
	var available := pads(parcel_id)
	return StringName(String(available[0].get("id", ""))) if not available.is_empty() else &""


func default_module_id(parcel_id: StringName, pad_id: StringName = &"") -> StringName:
	var requested := _first_id(_projection, ["selected_module_id", "focused_module_id", "module_id"])
	if _module_is_visible_at(requested, parcel_id, pad_id):
		return requested
	for project_record: Dictionary in projects_for_parcel(parcel_id):
		var active_module := StringName(String(project_record.get("module_id", "")))
		if _module_is_visible_at(active_module, parcel_id, pad_id):
			return active_module
	for record: Dictionary in modules(parcel_id):
		var module_id := StringName(String(record.get("id", "")))
		if _module_is_visible_at(module_id, parcel_id, pad_id):
			return module_id
	return &""


func deed_quote(parcel_id: StringName) -> Dictionary:
	var record := parcel(parcel_id)
	if record.is_empty():
		return _invalid_quote(&"purchase_deed", "No authoritative parcel file is available.")
	var quote := _dictionary(record.get("quote", {})).duplicate(true)
	quote["parcel_id"] = parcel_id
	quote["action_id"] = StringName(String(quote.get("action_id", &"purchase_deed")))
	if bool(record.get("owned", false)):
		quote["can_authorize"] = false
		if String(quote.get("reason", "")).strip_edges().is_empty():
			quote["reason"] = String(record.get("reason", ""))
	return quote


func project_quote(module_id: StringName, pad_id: StringName) -> Dictionary:
	var module_record := module(module_id)
	var pad_record := pad(pad_id)
	if module_record.is_empty():
		return _invalid_quote(&"queue_project", "No authoritative module file is available.")
	if pad_record.is_empty():
		return _invalid_quote(&"queue_project", "Select a filed construction pad.")

	var quote_source := _project_quote_source(module_record, pad_record, module_id, pad_id)
	var quote := _normalize_quote(quote_source, module_record, &"queue_project")
	quote["module_id"] = module_id
	quote["pad_id"] = pad_id

	var pad_reason := String(pad_record.get("reason", "")).strip_edges()
	if bool(pad_record.get("blocked", false)) or bool(pad_record.get("occupied", false)):
		quote["can_authorize"] = false
		if not pad_reason.is_empty():
			quote["reason"] = pad_reason
	var allowed_pad_ids := _id_array(module_record.get("allowed_pad_ids", []))
	if not allowed_pad_ids.is_empty() and pad_id not in allowed_pad_ids:
		quote["can_authorize"] = false
		if String(quote.get("reason", "")).strip_edges().is_empty():
			quote["reason"] = String(module_record.get("reason", ""))
	return quote


func workers_for_module(module_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for worker_record: Dictionary in _workers:
		var copy := worker_record.duplicate(true)
		var eligible_modules := _id_array(copy.get("eligible_module_ids", []))
		var barred_modules := _id_array(copy.get("blocked_module_ids", []))
		var can_assign := bool(copy.get("can_assign", copy.get("available", true)))
		if not eligible_modules.is_empty() and module_id not in eligible_modules:
			can_assign = false
		if module_id in barred_modules:
			can_assign = false
		copy["can_assign_here"] = can_assign
		result.append(copy)
	return result


func accessible_summary() -> String:
	var lines: Array[String] = []
	lines.append("Campus portfolio with %d parcels, %d modules, and %d active projects." % [
		_parcels.size(),
		_modules.size(),
		_projects.size(),
	])
	lines.append("Feed Fund %s; spendable %s; protected reserve %s." % [
		_money(int(_resources.get("feed_fund_cents", 0))),
		_money(int(_resources.get("spendable_fund_cents", 0))),
		_money(int(_resources.get("protected_reserve_cents", 0))),
	])
	lines.append("Contractors %d of %d; power %d of %d; cold %d of %d." % [
		int(_resources.get("contractor_used", 0)),
		int(_resources.get("contractor_capacity", 0)),
		int(_resources.get("power_used", 0)),
		int(_resources.get("power_capacity", 0)),
		int(_resources.get("cold_used", 0)),
		int(_resources.get("cold_capacity", 0)),
	])
	return " ".join(lines)


func _rebuild_parcels() -> void:
	_parcels.clear()
	_parcels_by_id.clear()
	var raw_records := _records(_projection.get("parcels", _projection.get("parcel_catalog", [])))
	for raw: Dictionary in raw_records:
		var fallback_id := StringName(String(raw.get("_record_key", "")))
		var normalized := _normalize_parcel(raw, fallback_id)
		var parcel_id := StringName(String(normalized.get("id", "")))
		if parcel_id == &"" or _parcels_by_id.has(parcel_id):
			continue
		_parcels.append(normalized)
		_parcels_by_id[parcel_id] = normalized
	_sort_parcels()


func _rebuild_pads() -> void:
	_pads.clear()
	_pads_by_id.clear()
	var raw_records: Array[Dictionary] = []
	_append_pad_records(raw_records, _projection.get("pads", _projection.get("construction_pads", [])), &"")
	for parcel_record: Dictionary in _parcels:
		var parcel_id := StringName(String(parcel_record.get("id", "")))
		_append_pad_records(raw_records, parcel_record.get("pads", parcel_record.get("construction_pads", [])), parcel_id)
	for raw: Dictionary in raw_records:
		var fallback_id := StringName(String(raw.get("_record_key", "")))
		var normalized := _normalize_pad(raw, fallback_id)
		var pad_id := StringName(String(normalized.get("id", "")))
		if pad_id == &"" or _pads_by_id.has(pad_id):
			continue
		_pads.append(normalized)
		_pads_by_id[pad_id] = normalized


func _rebuild_modules() -> void:
	_modules.clear()
	_modules_by_id.clear()
	var source: Variant = _projection.get("module_catalog", _projection.get("modules", []))
	for raw: Dictionary in _records(source):
		var fallback_id := StringName(String(raw.get("_record_key", "")))
		var normalized := _normalize_module(raw, fallback_id)
		var module_id := StringName(String(normalized.get("id", "")))
		if module_id == &"" or _modules_by_id.has(module_id):
			continue
		_modules.append(normalized)
		_modules_by_id[module_id] = normalized


func _rebuild_projects() -> void:
	_projects.clear()
	_projects_by_id.clear()
	var source: Variant = _projection.get(
		"projects",
		_projection.get("active_projects", _projection.get("project_queue", [])),
	)
	for raw: Dictionary in _records(source):
		var fallback_id := StringName(String(raw.get("_record_key", "")))
		var normalized := _normalize_project(raw, fallback_id)
		var job_id := StringName(String(normalized.get("job_id", "")))
		if job_id == &"" or _projects_by_id.has(job_id):
			continue
		_projects.append(normalized)
		_projects_by_id[job_id] = normalized


func _rebuild_workers() -> void:
	_workers.clear()
	_workers_by_key.clear()
	var sources: Array[Variant] = [
		_snapshot_context.get("workers", _snapshot_context.get("staff", [])),
		_projection.get("workers", _projection.get("staff", [])),
	]
	for source: Variant in sources:
		for raw: Dictionary in _records(source):
			var fallback: Variant = raw.get("_record_key", "")
			var normalized := _normalize_worker(raw, fallback)
			var worker_id: Variant = normalized.get("id", null)
			var key := _variant_key(worker_id)
			if key == &"":
				continue
			if _workers_by_key.has(key):
				var existing := (_workers_by_key[key] as Dictionary).duplicate(true)
				if StringName(String(normalized.get("assigned_module_id", ""))) != &"":
					existing["assigned_module_id"] = normalized.get("assigned_module_id")
				if String(normalized.get("name", "")).strip_edges() != "Worker %s" % str(worker_id):
					existing["name"] = normalized.get("name")
				_workers_by_key[key] = existing
				for index: int in range(_workers.size()):
					if _variant_key(_workers[index].get("id", null)) == key:
						_workers[index] = existing
						break
				continue
			_workers.append(normalized)
			_workers_by_key[key] = normalized


func _normalize_resources(source: Dictionary) -> Dictionary:
	var contractor := _dictionary(source.get("contractor", source.get("contractors", {})))
	var network := _dictionary(source.get("network", source.get("utilities", {})))
	return {
		"feed_fund_cents": _first_int(source, ["feed_fund_cents", "fund_cents", "revenue_cents"]),
		"spendable_fund_cents": _first_int(source, ["spendable_fund_cents", "spendable_cents", "available_cents"]),
		"protected_reserve_cents": _first_int(source, ["protected_reserve_cents", "reserve_cents"]),
		"contractor_used": _first_int_pair(source, contractor, ["contractor_used", "contractors_used", "contractor_slots_used", "active_contractor_slots", "active_slots"]),
		"contractor_capacity": _first_int_pair(source, contractor, ["contractor_capacity", "contractors_capacity", "contractor_slots", "contractor_capacity_slots", "capacity_slots"]),
		"power_used": _first_int_pair(source, network, ["power_used", "power_draw", "power_load", "power_reserved_units"]),
		"power_capacity": _first_int_pair(source, network, ["power_capacity", "power_cap", "power_capacity_units"]),
		"cold_used": _first_int_pair(source, network, ["cold_used", "cold_draw", "cold_load", "cold_reserved_units"]),
		"cold_capacity": _first_int_pair(source, network, ["cold_capacity", "cold_cap", "cold_capacity_units"]),
		"has_feed_fund": _has_any(source, ["feed_fund_cents", "fund_cents", "revenue_cents"]),
		"has_spendable": _has_any(source, ["spendable_fund_cents", "spendable_cents", "available_cents"]),
		"has_reserve": _has_any(source, ["protected_reserve_cents", "reserve_cents"]),
		"has_contractors": _has_any(source, ["contractor_used", "contractors_used", "contractor_slots_used", "active_contractor_slots", "contractor_capacity", "contractors_capacity", "contractor_slots", "contractor_capacity_slots"]) or not contractor.is_empty(),
		"has_power": _has_any(source, ["power_used", "power_draw", "power_load", "power_capacity", "power_cap"]) or _has_any(network, ["power_reserved_units", "power_capacity_units"]),
		"has_cold": _has_any(source, ["cold_used", "cold_draw", "cold_load", "cold_capacity", "cold_cap"]) or _has_any(network, ["cold_reserved_units", "cold_capacity_units"]),
	}


func _normalize_parcel(source: Dictionary, fallback_id: StringName) -> Dictionary:
	var parcel_id := _first_id(source, ["id", "parcel_id"])
	if parcel_id == &"":
		parcel_id = fallback_id
	var owned := bool(source.get("owned", source.get("purchased", source.get("deed_filed", false))))
	var quote_source := _dictionary(source.get("quote", source.get("deed_quote", source.get("purchase_quote", {}))))
	var quote := _normalize_quote(quote_source, source, &"purchase_deed")
	if owned:
		quote["can_authorize"] = false
	return {
		"id": parcel_id,
		"name": String(source.get("name", source.get("display_name", _title(parcel_id)))).strip_edges(),
		"short_name": String(source.get("short_name", source.get("map_label", ""))).strip_edges(),
		"owned": owned,
		"status_id": StringName(String(source.get("status_id", &"owned" if owned else &"ready" if bool(quote.get("can_authorize", false)) else &"blocked"))),
		"status_label": String(source.get("status_label", "DEED FILED" if owned else "READY" if bool(quote.get("can_authorize", false)) else "HELD")).to_upper(),
		"reason": String(source.get("reason", quote.get("reason", ""))).strip_edges(),
		"quote": quote,
		"benefit_lines": _lines(source.get("benefit_lines", source.get("benefits", source.get("effect", [])))),
		"pad_ids": _id_array(source.get("pad_ids", source.get("construction_pad_ids", []))),
		"pads": source.get("pads", source.get("construction_pads", [])),
		"map_position": source.get("map_position", source.get("position", Vector2.ZERO)),
		"order": int(source.get("order", source.get("map_order", 0))),
	}


func _normalize_pad(source: Dictionary, fallback_id: StringName) -> Dictionary:
	var pad_id := _first_id(source, ["id", "pad_id", "socket_id"])
	if pad_id == &"":
		pad_id = fallback_id
	var parcel_id := _first_id(source, ["parcel_id", "site_id"])
	var occupied := bool(source.get("occupied", source.get("in_use", false)))
	var reserved := bool(source.get("reserved", source.get("project_reserved", false)))
	var blocked := bool(source.get("blocked", source.get("route_blocked", false)))
	return {
		"id": pad_id,
		"parcel_id": parcel_id,
		"name": String(source.get("name", source.get("label", _title(pad_id)))).strip_edges(),
		"status_id": StringName(String(source.get("status_id", &"occupied" if occupied else &"reserved" if reserved else &"blocked" if blocked else &"ready"))),
		"status_label": String(source.get("status_label", "OCCUPIED" if occupied else "PROJECT RESERVED" if reserved else "ROUTE HELD" if blocked else "READY")).to_upper(),
		"occupied": occupied,
		"reserved": reserved,
		"blocked": blocked,
		"reason": String(source.get("reason", source.get("blocked_reason", source.get("route_reason", "")))).strip_edges(),
		"allowed_module_ids": _id_array(source.get("allowed_module_ids", source.get("module_ids", []))),
		"project_quotes": source.get("project_quotes", source.get("module_quotes", source.get("quotes", {}))),
		"order": int(source.get("order", source.get("pad_order", 0))),
	}


func _normalize_module(source: Dictionary, fallback_id: StringName) -> Dictionary:
	var module_id := _first_id(source, ["id", "module_id"])
	if module_id == &"":
		module_id = fallback_id
	var quote_source := _dictionary(source.get("quote", source.get("project_quote", source.get("build_quote", {}))))
	var quote := _normalize_quote(quote_source, source, &"queue_project")
	var effects_value: Variant = source.get("effect_lines", source.get("effects", source.get("effect", source.get("benefits", []))))
	return {
		"id": module_id,
		"name": String(source.get("name", source.get("display_name", _title(module_id)))).strip_edges(),
		"short_name": String(source.get("short_name", "")).strip_edges(),
		"parcel_id": _first_id(source, ["parcel_id", "site_id"]),
		"allowed_pad_ids": _id_array(source.get("allowed_pad_ids", source.get("pad_ids", []))),
		"quote": quote,
		"pad_quotes": source.get("pad_quotes", source.get("quotes_by_pad", source.get("project_quotes", source.get("placement_quotes", {})))),
		"cost_cents": int(quote.get("cost_cents", 0)),
		"has_cost": bool(quote.get("has_cost", false)),
		"daily_cost_cents": int(quote.get("daily_cost_cents", 0)),
		"has_daily_cost": bool(quote.get("has_daily_cost", false)),
		"duration_shifts": _first_int_pair(source, quote, ["duration_shifts", "build_duration_shifts", "construction_shifts"]),
		"contractor_slots": _first_int(source, ["contractor_slots", "contractor_required"]),
		"power_required": _first_int(source, ["power_required", "power_draw", "power_cost", "power_units"]),
		"cold_required": _first_int(source, ["cold_required", "cold_draw", "cold_cost", "cold_units"]),
		"staff_required": _first_int(source, ["staff_required", "required_staff", "staff_slots"]),
		"requires_staff": bool(source.get("requires_staff", _first_int(source, ["staff_required", "required_staff", "staff_slots"]) > 0)),
		"effect_lines": _effect_lines(effects_value),
		"tradeoff_lines": _lines(source.get("tradeoff_lines", source.get("tradeoffs", source.get("obligations", [])))),
		"reason": String(source.get("reason", quote.get("reason", ""))).strip_edges(),
		"operational": bool(source.get("operational", source.get("commissioned", false))),
		"installed": bool(source.get("installed", source.get("built", source.get("owned", false)))),
		"worker_id": source.get("worker_id", null),
		"worker_name": String(source.get("worker_name", "")).strip_edges(),
		"staffed": bool(source.get("staffed", source.get("worker_id", null) != null)),
	}


func _normalize_project(source: Dictionary, fallback_id: StringName) -> Dictionary:
	var job_id := _first_id(source, ["job_id", "id", "project_id"])
	if job_id == &"":
		job_id = fallback_id
	var module_id := _first_id(source, ["module_id", "facility_id"])
	var pad_id := _first_id(source, ["pad_id", "socket_id"])
	var parcel_id := _first_id(source, ["parcel_id", "site_id"])
	if parcel_id == &"" and _pads_by_id.has(pad_id):
		parcel_id = StringName(String((_pads_by_id[pad_id] as Dictionary).get("parcel_id", "")))
	var duration := _first_int(source, ["duration_shifts", "total_shifts", "build_duration_shifts"])
	var progress := _first_int(source, ["progress_shifts", "completed_shifts", "elapsed_shifts"])
	var remaining := _first_int(source, ["remaining_shifts", "shifts_remaining"])
	if not _has_any(source, ["remaining_shifts", "shifts_remaining"]) and duration > 0:
		remaining = maxi(0, duration - progress)
	return {
		"job_id": job_id,
		"id": job_id,
		"module_id": module_id,
		"module_name": String(source.get("module_name", _title(module_id))).strip_edges(),
		"pad_id": pad_id,
		"parcel_id": parcel_id,
		"status": StringName(String(source.get("status", source.get("status_id", &"queued")))),
		"status_label": String(source.get("status_label", String(source.get("status", "queued")).replace("_", " ").to_upper())),
		"stage_id": _first_id(source, ["stage_id", "current_stage_id"]),
		"stage_label": String(source.get("stage_label", source.get("current_stage_label", ""))).strip_edges(),
		"progress_shifts": progress,
		"duration_shifts": duration,
		"remaining_shifts": remaining,
		"stages": _normalize_stages(source.get("stages", source.get("construction_stages", []))),
		"reason": String(source.get("reason", source.get("status_reason", ""))).strip_edges(),
	}


func _normalize_worker(source: Dictionary, fallback_id: Variant) -> Dictionary:
	var worker_id: Variant = source.get("id", source.get("worker_id", fallback_id))
	var assigned_module_id := _first_id(source, ["assigned_module_id", "module_id", "assignment_id"])
	return {
		"id": worker_id,
		"name": String(source.get("name", source.get("display_name", source.get("worker_name", "Worker %s" % str(worker_id))))).strip_edges(),
		"role": String(source.get("role", source.get("title", "Flock worker"))).strip_edges(),
		"available": bool(source.get("available", source.get("can_assign", assigned_module_id == &""))),
		"can_assign": bool(source.get("can_assign", source.get("available", assigned_module_id == &""))),
		"reason": String(source.get("reason", source.get("assignment_reason", ""))).strip_edges(),
		"assigned_module_id": assigned_module_id,
		"eligible_module_ids": _id_array(source.get("eligible_module_ids", source.get("module_ids", []))),
		"blocked_module_ids": _id_array(source.get("blocked_module_ids", [])),
	}


func _normalize_quote(source: Dictionary, fallback: Dictionary, default_action: StringName) -> Dictionary:
	var known := not source.is_empty() or _has_any(fallback, [
		"can_authorize", "can_purchase", "can_build", "cost_cents", "capital_cost_cents", "daily_cost_cents", "duration_shifts",
	])
	var can_authorize := false
	if source.has("can_authorize"):
		can_authorize = bool(source.get("can_authorize", false))
	elif source.has("can_purchase"):
		can_authorize = bool(source.get("can_purchase", false))
	elif source.has("can_build"):
		can_authorize = bool(source.get("can_build", false))
	elif fallback.has("can_authorize"):
		can_authorize = bool(fallback.get("can_authorize", false))
	elif fallback.has("can_purchase"):
		can_authorize = bool(fallback.get("can_purchase", false))
	elif fallback.has("can_build"):
		can_authorize = bool(fallback.get("can_build", false))
	var cost_keys: Array[String] = ["cost_cents", "capital_cost_cents", "purchase_cost_cents", "project_cost_cents", "deed_cost_cents"]
	var daily_keys: Array[String] = ["daily_cost_cents", "recurring_cost_cents", "daily_maintenance_cents", "added_daily_cost_cents"]
	return {
		"known": known,
		"action_id": StringName(String(source.get("action_id", fallback.get("action_id", default_action)))),
		"can_authorize": can_authorize,
		"reason": String(source.get("reason", source.get("blocked_reason", fallback.get("reason", fallback.get("blocked_reason", ""))))).strip_edges(),
		"cost_cents": _first_int_pair(source, fallback, cost_keys),
		"has_cost": _has_any(source, cost_keys) or _has_any(fallback, cost_keys),
		"daily_cost_cents": _first_int_pair(source, fallback, daily_keys),
		"has_daily_cost": _has_any(source, daily_keys) or _has_any(fallback, daily_keys),
		"duration_shifts": _first_int_pair(source, fallback, ["duration_shifts", "build_duration_shifts", "construction_shifts"]),
		"projected_spendable_fund_cents": _first_int_pair(source, fallback, ["projected_spendable_fund_cents", "projected_spendable_cents"]),
		"projected_protected_reserve_cents": _first_int_pair(source, fallback, ["projected_protected_reserve_cents", "projected_reserve_cents"]),
		"effect_lines": _effect_lines(source.get("effect_lines", source.get("effects", fallback.get("effect_lines", fallback.get("effect", []))))),
	}


func _project_quote_source(module_record: Dictionary, pad_record: Dictionary, module_id: StringName, pad_id: StringName) -> Dictionary:
	var candidate := _record_from_collection(module_record.get("pad_quotes", {}), pad_id)
	if not candidate.is_empty():
		return candidate
	candidate = _record_from_collection(pad_record.get("project_quotes", {}), module_id)
	if not candidate.is_empty():
		return candidate
	var root_quotes: Variant = _projection.get("project_quotes", _projection.get("build_quotes", {}))
	candidate = _record_from_collection(root_quotes, StringName("%s:%s" % [module_id, pad_id]))
	if not candidate.is_empty():
		return candidate
	candidate = _record_from_collection(root_quotes, module_id)
	if not candidate.is_empty():
		var nested := _record_from_collection(candidate, pad_id)
		return nested if not nested.is_empty() else candidate
	return _dictionary(module_record.get("quote", {}))


func _append_pad_records(target: Array[Dictionary], value: Variant, parcel_hint: StringName) -> void:
	if value is Dictionary and not (value as Dictionary).has("id") and not (value as Dictionary).has("pad_id"):
		for key: Variant in (value as Dictionary).keys():
			var nested: Variant = (value as Dictionary)[key]
			if nested is Array:
				_append_pad_records(target, nested, StringName(String(key)) if parcel_hint == &"" else parcel_hint)
				continue
			if nested is Dictionary:
				var record := (nested as Dictionary).duplicate(true)
				if not record.has("id"):
					record["id"] = StringName(String(key))
				if parcel_hint != &"" and not record.has("parcel_id"):
					record["parcel_id"] = parcel_hint
				target.append(record)
		return
	for raw: Dictionary in _records(value):
		var copy := raw.duplicate(true)
		if parcel_hint != &"" and not copy.has("parcel_id"):
			copy["parcel_id"] = parcel_hint
		target.append(copy)


func _normalize_assignments(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if value is Dictionary:
		for raw_key: Variant in (value as Dictionary).keys():
			var module_id := StringName(str(raw_key))
			var assignment_value: Variant = (value as Dictionary)[raw_key]
			if assignment_value is Dictionary:
				assignment_value = (assignment_value as Dictionary).get("worker_id", (assignment_value as Dictionary).get("id", null))
			if assignment_value != null:
				result[module_id] = assignment_value
	elif value is Array:
		for raw: Variant in value as Array:
			if not raw is Dictionary:
				continue
			var record := raw as Dictionary
			var module_id := _first_id(record, ["module_id", "facility_id"])
			if module_id != &"" and record.has("worker_id"):
				result[module_id] = record["worker_id"]
	return result


func _normalize_stages(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw: Dictionary in _records(value):
		var stage_id := _first_id(raw, ["id", "stage_id"])
		if stage_id == &"":
			stage_id = StringName(String(raw.get("_record_key", "")))
		result.append({
			"id": stage_id,
			"label": String(raw.get("label", raw.get("name", _title(stage_id)))).strip_edges(),
			"status": StringName(String(raw.get("status", raw.get("status_id", &"pending")))),
			"detail": String(raw.get("detail", raw.get("reason", ""))).strip_edges(),
		})
	return result


func _effect_lines(value: Variant) -> Array[String]:
	if value is Dictionary:
		var result: Array[String] = []
		for key: Variant in (value as Dictionary).keys():
			var effect_value: Variant = (value as Dictionary)[key]
			if effect_value is String or effect_value is StringName:
				result.append(str(effect_value))
			elif effect_value is int or effect_value is float:
				result.append("%s: %s" % [_title(StringName(str(key))), str(effect_value)])
		return result
	return _lines(value)


func _records(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item: Variant in value as Array:
			if item is Dictionary:
				result.append((item as Dictionary).duplicate(true))
	elif value is Dictionary:
		var dictionary := value as Dictionary
		if dictionary.has("id") or dictionary.has("job_id") or dictionary.has("module_id") and dictionary.has("name"):
			result.append(dictionary.duplicate(true))
		else:
			for key: Variant in dictionary.keys():
				var item: Variant = dictionary[key]
				if not item is Dictionary:
					continue
				var record := (item as Dictionary).duplicate(true)
				record["_record_key"] = key
				if not record.has("id"):
					record["id"] = key
				result.append(record)
	return result


func _record_from_collection(value: Variant, record_id: StringName) -> Dictionary:
	if value is Dictionary:
		var dictionary := value as Dictionary
		if dictionary.has(record_id):
			return _dictionary(dictionary[record_id]).duplicate(true)
		if dictionary.has(str(record_id)):
			return _dictionary(dictionary[str(record_id)]).duplicate(true)
	for record: Dictionary in _records(value):
		var candidate := _first_id(record, ["id", "pad_id", "module_id"])
		if candidate == record_id:
			return record.duplicate(true)
	return {}


func _sort_parcels() -> void:
	_parcels.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_id := StringName(String(a.get("id", "")))
		var b_id := StringName(String(b.get("id", "")))
		var a_rank := CANONICAL_PARCEL_ORDER.find(a_id)
		var b_rank := CANONICAL_PARCEL_ORDER.find(b_id)
		if a_rank < 0:
			a_rank = 1000 + int(a.get("order", 0))
		if b_rank < 0:
			b_rank = 1000 + int(b.get("order", 0))
		return a_rank < b_rank
	)
	_parcels_by_id.clear()
	for record: Dictionary in _parcels:
		_parcels_by_id[StringName(String(record.get("id", "")))] = record


func _module_is_visible_at(module_id: StringName, parcel_id: StringName, pad_id: StringName) -> bool:
	if not _modules_by_id.has(module_id):
		return false
	var record := _modules_by_id[module_id] as Dictionary
	var filed_parcel := StringName(String(record.get("parcel_id", "")))
	if filed_parcel != &"" and filed_parcel != parcel_id:
		return false
	var allowed := _id_array(record.get("allowed_pad_ids", []))
	return pad_id == &"" or allowed.is_empty() or pad_id in allowed


func _invalid_quote(action_id: StringName, reason: String) -> Dictionary:
	return {
		"known": false,
		"action_id": action_id,
		"can_authorize": false,
		"reason": reason,
		"cost_cents": 0,
		"has_cost": false,
		"daily_cost_cents": 0,
		"has_daily_cost": false,
		"duration_shifts": 0,
	}


func _copy_record(source: Dictionary, record_id: Variant) -> Dictionary:
	if not source.has(record_id):
		return {}
	var value: Variant = source[record_id]
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _record_ids(records: Array[Dictionary]) -> Array[StringName]:
	var result: Array[StringName] = []
	for record: Dictionary in records:
		var record_id := StringName(String(record.get("id", record.get("job_id", ""))))
		if record_id != &"":
			result.append(record_id)
	return result


func _dictionary(value: Variant) -> Dictionary:
	return value as Dictionary if value is Dictionary else {}


func _first_id(source: Dictionary, keys: Array[String]) -> StringName:
	for key: String in keys:
		if source.has(key) and not str(source[key]).is_empty():
			return StringName(str(source[key]))
	return &""


func _first_int(source: Dictionary, keys: Array[String]) -> int:
	for key: String in keys:
		if source.has(key):
			return int(source[key])
	return 0


func _first_int_pair(primary: Dictionary, fallback: Dictionary, keys: Array[String]) -> int:
	for key: String in keys:
		if primary.has(key):
			return int(primary[key])
	for key: String in keys:
		if fallback.has(key):
			return int(fallback[key])
	return 0


func _has_any(source: Dictionary, keys: Array[String]) -> bool:
	for key: String in keys:
		if source.has(key):
			return true
	return false


func _id_array(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if value is Array:
		for item: Variant in value as Array:
			var item_id := StringName(str((item as Dictionary).get("id", ""))) if item is Dictionary else StringName(str(item))
			if item_id != &"" and item_id not in result:
				result.append(item_id)
	elif value is Dictionary:
		for key: Variant in (value as Dictionary).keys():
			if bool((value as Dictionary)[key]):
				result.append(StringName(String(key)))
	elif value is String or value is StringName:
		var item_id := StringName(str(value))
		if item_id != &"":
			result.append(item_id)
	return result


func _lines(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item: Variant in value as Array:
			if item is Dictionary:
				var line := String((item as Dictionary).get("label", (item as Dictionary).get("text", (item as Dictionary).get("name", "")))).strip_edges()
				if not line.is_empty():
					result.append(line)
			else:
				var line := str(item).strip_edges()
				if not line.is_empty():
					result.append(line)
	elif value is String or value is StringName:
		var line := str(value).strip_edges()
		if not line.is_empty():
			result.append(line)
	return result


func _variant_key(value: Variant) -> StringName:
	return StringName(str(value)) if value != null else &""


func _title(value: StringName) -> String:
	return String(value).replace("_", " ").capitalize()


func _money(cents: int) -> String:
	return "$%.2f" % (float(cents) / 100.0)
