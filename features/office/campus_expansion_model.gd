class_name CampusExpansionModel
extends RefCounted

## Read-only presentation model for the North Meadow campus plan.
##
## Expected input is either a full simulation snapshot containing
## `campus_expansion`, or that projection directly:
## {
##   parcel: Dictionary,
##   utilities: Array[Dictionary] | Dictionary,
##   sockets: Array[Dictionary] | Dictionary,
##   routing_pod: Dictionary,
##   construction_stages: Array[Dictionary],
##   operational_benefits: Array[String],
##   summary: String,
## }
##
## Stable identities are presentation constants. Prices, recurring costs,
## dependencies, route gates, readiness, quotes, stages, and benefits are
## copied from the authoritative projection and are never estimated here.

const PARCEL_ID := &"north_meadow"

const SERVICE_CIRCULATION := &"circulation"
const SERVICE_POWER := &"power"
const SERVICE_COLD_CHAIN := &"cold_chain"
const SERVICE_ORDER: Array[StringName] = [
	SERVICE_CIRCULATION,
	SERVICE_POWER,
	SERVICE_COLD_CHAIN,
]

const SOCKET_A := &"meadow_west"
const SOCKET_B := &"meadow_east"
const SOCKET_C := &"service_spine"
const SOCKET_ORDER: Array[StringName] = [
	SOCKET_A,
	SOCKET_B,
	SOCKET_C,
]

const SERVICE_DEFAULT_NAMES := {
	SERVICE_CIRCULATION: "FLOCK CIRCULATION",
	SERVICE_POWER: "COOP POWER",
	SERVICE_COLD_CHAIN: "COLD-CHAIN LOOP",
}

const SOCKET_DEFAULT_LABELS := {
	SOCKET_A: "SOCKET A / MEADOW WEST",
	SOCKET_B: "SOCKET B / MEADOW EAST",
	SOCKET_C: "SOCKET C / SERVICE SPINE",
}

var _projection: Dictionary = {}
var _parcel: Dictionary = {}
var _services_by_id: Dictionary = {}
var _sockets_by_id: Dictionary = {}
var _pod: Dictionary = {}
var _construction_stages: Array[Dictionary] = []
var _operational_benefits: Array[String] = []
var _summary := ""


func set_snapshot(snapshot: Dictionary) -> void:
	var projection_value: Variant = snapshot.get("campus_expansion", snapshot)
	_projection = _dictionary_value(projection_value).duplicate(true)
	_parcel = _normalize_parcel(_parcel_source())
	_pod = _normalize_pod(_pod_source())

	_services_by_id.clear()
	var authored_services := _records_by_id(
		_projection.get("utilities", _projection.get("services", [])),
		SERVICE_ORDER,
	)
	for service_id: StringName in SERVICE_ORDER:
		_services_by_id[service_id] = _normalize_service(
			service_id,
			_dictionary_value(authored_services.get(service_id, {})),
		)

	_sockets_by_id.clear()
	var authored_sockets := _records_by_id(
		_projection.get("sockets", _projection.get("pod_sockets", [])),
		SOCKET_ORDER,
	)
	for socket_id: StringName in SOCKET_ORDER:
		_sockets_by_id[socket_id] = _normalize_socket(
			socket_id,
			_dictionary_value(authored_sockets.get(socket_id, {})),
		)

	_construction_stages = _normalize_stages(_projection.get(
		"construction_stages",
		_pod.get("construction_stages", []),
	))
	if _construction_stages.is_empty() and not _projection.is_empty():
		_construction_stages = _derived_construction_stages()
	_operational_benefits = _copy_lines(_projection.get(
		"operational_benefits",
		_pod.get("operational_benefits", []),
	))
	if _operational_benefits.is_empty() and not _projection.is_empty():
		_operational_benefits = _derived_operational_benefits()
	_summary = String(_projection.get(
		"summary",
		_projection.get("construction_summary", _pod.get("summary", "")),
	)).strip_edges()
	if _summary.is_empty() and not _projection.is_empty():
		_summary = _derived_summary()


func has_projection() -> bool:
	return not _projection.is_empty()


func parcel() -> Dictionary:
	return _parcel.duplicate(true)


func services() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for service_id: StringName in SERVICE_ORDER:
		result.append((_services_by_id[service_id] as Dictionary).duplicate(true))
	return result


func service(service_id: StringName) -> Dictionary:
	if not _services_by_id.has(service_id):
		return {}
	return (_services_by_id[service_id] as Dictionary).duplicate(true)


func sockets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for socket_id: StringName in SOCKET_ORDER:
		result.append((_sockets_by_id[socket_id] as Dictionary).duplicate(true))
	return result


func socket(socket_id: StringName) -> Dictionary:
	if not _sockets_by_id.has(socket_id):
		return {}
	return (_sockets_by_id[socket_id] as Dictionary).duplicate(true)


func routing_pod() -> Dictionary:
	return _pod.duplicate(true)


func construction_stages() -> Array[Dictionary]:
	return _construction_stages.duplicate(true)


func operational_benefits() -> Array[String]:
	return _operational_benefits.duplicate()


func project_summary() -> String:
	return _summary


func default_socket_id() -> StringName:
	var requested := StringName(String(_projection.get(
		"selected_socket_id",
		_projection.get("preview_socket_id", ""),
	)))
	if requested in SOCKET_ORDER:
		return requested
	var current := StringName(String(_pod.get("current_socket_id", "")))
	if current in SOCKET_ORDER:
		return current
	return SOCKET_A


func placement_quote(socket_id: StringName) -> Dictionary:
	var target := socket(socket_id)
	if target.is_empty():
		return _invalid_quote(socket_id, "That North Meadow socket is not on the filed plan.")
	if bool(_pod.get("placed", false)):
		return _invalid_quote(socket_id, "The Egg Routing Pod is already installed; file a relocation quote instead.")
	var has_cost := bool(target.get("has_placement_cost", false)) or bool(
		_pod.get("has_placement_cost", false)
	)
	var cost := (
		int(target.get("placement_cost_cents", 0))
		if bool(target.get("has_placement_cost", false)) else
		int(_pod.get("placement_cost_cents", 0))
	)
	var pod_gate := (
		bool(_pod.get("can_place", false))
		if bool(_pod.get("has_can_place", false)) else
		true
	)
	var allowed := (
		bool(_parcel.get("owned", false))
		and not bool(target.get("route_blocked", false))
		and bool(target.get("can_place", false))
		and pod_gate
		and has_cost
	)
	var reason := ""
	if not bool(_parcel.get("owned", false)):
		reason = "Purchase the North Meadow parcel before placing the Egg Routing Pod."
	elif bool(target.get("route_blocked", false)):
		reason = String(target.get("route_reason", target.get("reason", "This route is blocked.")))
	elif not bool(target.get("can_place", false)):
		reason = String(target.get("placement_reason", target.get("reason", "This socket is not cleared for pod placement.")))
	elif not pod_gate:
		reason = String(_pod.get("placement_reason", "The Egg Routing Pod placement file is held."))
	elif not has_cost:
		reason = "No authoritative placement quote is filed for this socket."
	return {
		"action_id": &"place_pod",
		"socket_id": socket_id,
		"can_authorize": allowed,
		"cost_cents": cost,
		"has_cost": has_cost,
		"recurring_cost_cents": (
			int(target.get("placement_recurring_cost_cents", 0))
			if bool(target.get("has_placement_recurring_cost", false)) else
			int(_pod.get("recurring_cost_cents", 0))
		),
		"has_recurring_cost": bool(target.get("has_placement_recurring_cost", false)) or bool(_pod.get("has_recurring_cost", false)),
		"reason": reason,
	}


func relocation_quote(socket_id: StringName) -> Dictionary:
	var target := socket(socket_id)
	if target.is_empty():
		return _invalid_quote(socket_id, "That North Meadow socket is not on the filed plan.")
	if not bool(_pod.get("placed", false)):
		return _invalid_quote(socket_id, "Place the Egg Routing Pod before filing a relocation.")
	var current_socket_id := StringName(String(_pod.get("current_socket_id", "")))
	if socket_id == current_socket_id:
		return _invalid_quote(socket_id, "The Egg Routing Pod is already installed at this socket.")
	var has_cost := bool(target.get("has_relocation_cost", false)) or bool(
		_pod.get("has_relocation_cost", false)
	)
	var cost := (
		int(target.get("relocation_cost_cents", 0))
		if bool(target.get("has_relocation_cost", false)) else
		int(_pod.get("relocation_cost_cents", 0))
	)
	var pod_gate := (
		bool(_pod.get("can_relocate", false))
		if bool(_pod.get("has_can_relocate", false)) else
		true
	)
	var allowed := (
		not bool(target.get("route_blocked", false))
		and bool(target.get("can_relocate", false))
		and pod_gate
		and has_cost
	)
	var reason := ""
	if bool(target.get("route_blocked", false)):
		reason = String(target.get("route_reason", target.get("reason", "This route is blocked.")))
	elif not bool(target.get("can_relocate", false)):
		reason = String(target.get("relocation_reason", target.get("reason", "This socket is not cleared for relocation.")))
	elif not pod_gate:
		reason = String(_pod.get("relocation_reason", "The Egg Routing Pod relocation file is held."))
	elif not has_cost:
		reason = "No authoritative relocation quote is filed for this socket."
	return {
		"action_id": &"relocate_pod",
		"from_socket_id": current_socket_id,
		"socket_id": socket_id,
		"can_authorize": allowed,
		"cost_cents": cost,
		"has_cost": has_cost,
		"recurring_cost_cents": (
			int(target.get("relocation_recurring_cost_cents", 0))
			if bool(target.get("has_relocation_recurring_cost", false)) else
			int(_pod.get("recurring_cost_cents", 0))
		),
		"has_recurring_cost": bool(target.get("has_relocation_recurring_cost", false)) or bool(_pod.get("has_recurring_cost", false)),
		"reason": reason,
	}


func _parcel_source() -> Dictionary:
	var source := _dictionary_value(
		_projection.get("parcel", _projection.get("north_meadow", {}))
	).duplicate(true)
	var quote := _dictionary_value(_projection.get("parcel_quote", {}))
	if source.is_empty() and quote.is_empty() and not _projection.has("parcel_owned"):
		return source
	if not source.has("id"):
		source["id"] = StringName(String(_projection.get("parcel_id", PARCEL_ID)))
	if not source.has("name"):
		source["name"] = String(quote.get("name", "NORTH MEADOW"))
	if not source.has("owned"):
		source["owned"] = bool(_projection.get("parcel_owned", false))
	if not source.has("can_purchase"):
		source["can_purchase"] = bool(quote.get("can_authorize", false))
	if not source.has("reason"):
		source["reason"] = String(quote.get("reason", _projection.get("access_gate_reason", "")))
	if not source.has("capital_cost_cents") and quote.has("cost_cents"):
		source["capital_cost_cents"] = int(quote.get("cost_cents", 0))
	if not source.has("daily_cost_cents") and quote.has("added_daily_cost_cents"):
		source["daily_cost_cents"] = int(quote.get("added_daily_cost_cents", 0))
	if not source.has("dependency_lines"):
		var access_reason := String(_projection.get("access_gate_reason", "")).strip_edges()
		if not access_reason.is_empty():
			source["dependency_lines"] = [access_reason]
	if not source.has("benefit_lines") and not source.has("benefits"):
		source["benefit_lines"] = _quote_effect_lines(quote)
	if not source.has("status_label"):
		source["status_label"] = (
			"DEED FILED" if bool(source.get("owned", false)) else
			"READY" if bool(source.get("can_purchase", false)) else
			"HELD"
		)
	return source


func _pod_source() -> Dictionary:
	var source := _dictionary_value(
		_projection.get(
			"routing_pod",
			_projection.get("egg_routing_pod", _projection.get("module", {})),
		)
	).duplicate(true)
	if source.is_empty() and not (
		_projection.has("pod_owned")
		or _projection.has("pod_socket_id")
		or _projection.has("module_id")
	):
		return source
	if not source.has("id"):
		source["id"] = StringName(String(_projection.get("module_id", &"egg_routing_pod")))
	if not source.has("name"):
		var filed_name := "EGG ROUTING POD"
		var sockets_value: Variant = _projection.get("sockets", [])
		if sockets_value is Array:
			for socket_value: Variant in sockets_value as Array:
				if not socket_value is Dictionary:
					continue
				var placement := _dictionary_value((socket_value as Dictionary).get("placement_quote", {}))
				if not String(placement.get("name", "")).is_empty():
					filed_name = String(placement.get("name", filed_name))
					break
		source["name"] = filed_name
	if not source.has("owned") and not source.has("placed") and not source.has("installed"):
		source["owned"] = bool(_projection.get("pod_owned", false))
	if not source.has("socket_id") and not source.has("current_socket_id"):
		source["socket_id"] = StringName(String(_projection.get("pod_socket_id", "")))
	if not source.has("operational"):
		source["operational"] = bool(_projection.get("pod_operational", false))
	return source


func _normalize_parcel(source: Dictionary) -> Dictionary:
	var owned := bool(source.get("owned", source.get("purchased", source.get("acquired", false))))
	var can_purchase := bool(source.get("can_purchase", false))
	var known := not source.is_empty()
	var reason := String(source.get("reason", source.get("action_reason", ""))).strip_edges()
	if reason.is_empty() and not known:
		reason = "No authoritative North Meadow parcel file is available."
	var status_id := StringName(String(source.get(
		"status_id",
		&"owned" if owned else &"ready" if can_purchase else &"blocked",
	)))
	var normalized := source.duplicate(true)
	normalized.merge({
		"id": PARCEL_ID,
		"name": String(source.get("name", "NORTH MEADOW")).strip_edges(),
		"known": known,
		"owned": owned,
		"can_purchase": can_purchase,
		"status_id": status_id,
		"status_label": String(source.get("status_label", _status_label(status_id))).to_upper(),
		"reason": reason,
		"purchase_cost_cents": _first_int(source, ["purchase_cost_cents", "capital_cost_cents", "cost_cents"]),
		"has_purchase_cost": _has_any(source, ["purchase_cost_cents", "capital_cost_cents", "cost_cents"]),
		"recurring_cost_cents": _first_int(source, ["recurring_cost_cents", "daily_cost_cents", "daily_maintenance_cents"]),
		"has_recurring_cost": _has_any(source, ["recurring_cost_cents", "daily_cost_cents", "daily_maintenance_cents"]),
		"dependency_lines": _dependency_lines(source),
		"benefit_lines": _copy_lines(source.get("benefit_lines", source.get("benefits", []))),
	}, true)
	return normalized


func _normalize_service(service_id: StringName, source: Dictionary) -> Dictionary:
	var quote := _dictionary_value(source.get("quote", source.get("connection_quote", {})))
	var connected := bool(source.get("connected", source.get("commissioned", source.get("owned", false))))
	var can_connect := bool(source.get("can_connect", source.get("can_purchase", quote.get("can_authorize", false))))
	var known := not source.is_empty()
	var reason := String(source.get("reason", source.get("action_reason", quote.get("reason", "")))).strip_edges()
	if reason.is_empty() and not known:
		reason = "No authoritative service quote is filed."
	var status_id := StringName(String(source.get(
		"status_id",
		&"connected" if connected else &"ready" if can_connect else &"blocked",
	)))
	var normalized := source.duplicate(true)
	normalized.merge({
		"id": service_id,
		"name": String(source.get("name", SERVICE_DEFAULT_NAMES[service_id])).strip_edges(),
		"known": known,
		"connected": connected,
		"can_connect": can_connect,
		"status_id": status_id,
		"status_label": String(source.get("status_label", _status_label(status_id))).to_upper(),
		"reason": reason,
		"purchase_cost_cents": _first_int_pair(source, quote, ["purchase_cost_cents", "capital_cost_cents", "cost_cents"]),
		"has_purchase_cost": _has_any(source, ["purchase_cost_cents", "capital_cost_cents", "cost_cents"]) or _has_any(quote, ["purchase_cost_cents", "capital_cost_cents", "cost_cents"]),
		"recurring_cost_cents": _first_int_pair(source, quote, ["recurring_cost_cents", "daily_cost_cents", "daily_maintenance_cents", "added_daily_cost_cents"]),
		"has_recurring_cost": _has_any(source, ["recurring_cost_cents", "daily_cost_cents", "daily_maintenance_cents"]) or quote.has("added_daily_cost_cents"),
		"dependency_lines": _service_dependency_lines(source, reason),
		"benefit_lines": _benefit_lines_with_quote(source, quote),
	}, true)
	return normalized


func _normalize_pod(source: Dictionary) -> Dictionary:
	var placement_quote := _dictionary_value(source.get("placement_quote", {}))
	var relocation_quote := _dictionary_value(source.get("relocation_quote", {}))
	var normalized := source.duplicate(true)
	normalized.merge({
		"id": &"egg_routing_pod",
		"name": String(source.get("name", "EGG ROUTING POD")).strip_edges(),
		"placed": bool(source.get("placed", source.get("installed", source.get("owned", false)))),
		"current_socket_id": StringName(String(source.get("current_socket_id", source.get("socket_id", "")))),
		"placement_cost_cents": _first_int_pair(source, placement_quote, ["placement_cost_cents", "capital_cost_cents", "cost_cents"]),
		"has_placement_cost": _has_any(source, ["placement_cost_cents", "capital_cost_cents", "cost_cents"]) or _has_any(placement_quote, ["placement_cost_cents", "capital_cost_cents", "cost_cents"]),
		"relocation_cost_cents": _first_int_pair(source, relocation_quote, ["relocation_cost_cents", "cost_cents"]),
		"has_relocation_cost": _has_any(source, ["relocation_cost_cents"]) or _has_any(relocation_quote, ["relocation_cost_cents", "cost_cents"]),
		"recurring_cost_cents": _first_int(source, ["recurring_cost_cents", "daily_cost_cents", "daily_maintenance_cents"]),
		"has_recurring_cost": _has_any(source, ["recurring_cost_cents", "daily_cost_cents", "daily_maintenance_cents"]),
		"can_place": bool(source.get("can_place", source.get("can_place_pod", placement_quote.get("can_authorize", false)))),
		"has_can_place": source.has("can_place") or source.has("can_place_pod") or placement_quote.has("can_authorize"),
		"placement_reason": String(source.get("placement_reason", placement_quote.get("reason", source.get("reason", "")))).strip_edges(),
		"can_relocate": bool(source.get("can_relocate", source.get("can_relocate_pod", relocation_quote.get("can_authorize", false)))),
		"has_can_relocate": source.has("can_relocate") or source.has("can_relocate_pod") or relocation_quote.has("can_authorize"),
		"relocation_reason": String(source.get("relocation_reason", relocation_quote.get("reason", source.get("reason", "")))).strip_edges(),
		"construction_stages": _normalize_stages(source.get("construction_stages", [])),
		"operational_benefits": _copy_lines(source.get("operational_benefits", source.get("benefits", []))),
		"summary": String(source.get("summary", "")).strip_edges(),
	}, true)
	return normalized


func _normalize_socket(socket_id: StringName, source: Dictionary) -> Dictionary:
	var placement_quote := _dictionary_value(source.get("placement_quote", {}))
	var relocation_quote := _dictionary_value(source.get("relocation_quote", {}))
	var known := not source.is_empty()
	var route_blocked := bool(source.get("route_blocked", false))
	var route_reason := String(source.get(
		"route_reason",
		source.get("route_blocked_reason", source.get("blocked_reason", "")),
	)).strip_edges()
	var placement_reason := String(source.get("placement_reason", placement_quote.get("reason", ""))).strip_edges()
	var relocation_reason := String(source.get("relocation_reason", relocation_quote.get("reason", ""))).strip_edges()
	var reason := String(source.get("reason", source.get("action_reason", route_reason if route_blocked else placement_reason))).strip_edges()
	if reason.is_empty() and not known:
		reason = "No authoritative route survey is filed for this socket."
	var current_socket_id := StringName(String(_pod.get("current_socket_id", "")))
	var occupied := bool(source.get("occupied", socket_id == current_socket_id and bool(_pod.get("placed", false))))
	var can_place := bool(source.get("can_place", source.get("can_place_pod", placement_quote.get("can_authorize", false))))
	var can_relocate := bool(source.get("can_relocate", source.get("can_relocate_pod", relocation_quote.get("can_authorize", can_place))))
	var status_label := "HELD"
	if route_blocked:
		status_label = "ROUTE BLOCKED"
	elif occupied:
		status_label = "POD INSTALLED"
	elif can_place or can_relocate:
		status_label = "READY"
	var normalized := source.duplicate(true)
	normalized.merge({
		"id": socket_id,
		"label": String(source.get("label", source.get("name", SOCKET_DEFAULT_LABELS[socket_id]))).strip_edges(),
		"known": known,
		"route_blocked": route_blocked,
		"route_reason": route_reason,
		"reason": reason,
		"placement_reason": placement_reason,
		"relocation_reason": relocation_reason,
		"occupied": occupied,
		"can_place": can_place,
		"can_relocate": can_relocate,
		"status_label": String(source.get("status_label", status_label)).to_upper(),
		"dependency_lines": _dependency_lines(source),
		"placement_cost_cents": _first_int_pair(source, placement_quote, ["placement_cost_cents", "capital_cost_cents", "cost_cents"]),
		"has_placement_cost": _has_any(source, ["placement_cost_cents", "capital_cost_cents", "cost_cents"]) or _has_any(placement_quote, ["placement_cost_cents", "capital_cost_cents", "cost_cents"]),
		"placement_recurring_cost_cents": _first_int_pair(source, placement_quote, ["recurring_cost_cents", "daily_cost_cents", "added_daily_cost_cents"]),
		"has_placement_recurring_cost": _has_any(source, ["recurring_cost_cents", "daily_cost_cents"]) or placement_quote.has("added_daily_cost_cents"),
		"relocation_cost_cents": _first_int_pair(source, relocation_quote, ["relocation_cost_cents", "cost_cents"]),
		"has_relocation_cost": source.has("relocation_cost_cents") or _has_any(relocation_quote, ["relocation_cost_cents", "cost_cents"]),
		"relocation_recurring_cost_cents": _first_int_pair(source, relocation_quote, ["relocation_recurring_cost_cents", "added_daily_cost_cents"]),
		"has_relocation_recurring_cost": source.has("relocation_recurring_cost_cents") or relocation_quote.has("added_daily_cost_cents"),
	}, true)
	return normalized


func _normalize_stages(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not value is Array:
		return result
	for index: int in (value as Array).size():
		var stage_value: Variant = (value as Array)[index]
		if not stage_value is Dictionary:
			continue
		var source := stage_value as Dictionary
		var stage_id := StringName(String(source.get("id", "stage_%d" % (index + 1))))
		var status_id := StringName(String(source.get("status_id", source.get("status", "pending"))))
		var normalized := source.duplicate(true)
		normalized.merge({
			"id": stage_id,
			"label": String(source.get("label", source.get("name", "STAGE %d" % (index + 1)))).strip_edges(),
			"status_id": status_id,
			"status_label": String(source.get("status_label", _status_label(status_id))).to_upper(),
			"detail": String(source.get("detail", source.get("description", ""))).strip_edges(),
			"cost_cents": _first_int(source, ["cost_cents", "capital_cost_cents"]),
			"has_cost": _has_any(source, ["cost_cents", "capital_cost_cents"]),
		}, true)
		result.append(normalized)
	return result


func _derived_construction_stages() -> Array[Dictionary]:
	var parcel_owned := bool(_parcel.get("owned", false))
	var circulation := service(SERVICE_CIRCULATION)
	var power := service(SERVICE_POWER)
	var circulation_ready := bool(circulation.get("connected", false))
	var power_ready := bool(power.get("connected", false))
	var services_ready := circulation_ready and power_ready
	var pod_owned := bool(_pod.get("placed", false))
	var pod_operational := bool(_projection.get("pod_operational", _pod.get("operational", false)))
	var placement_ready := false
	for socket_id: StringName in SOCKET_ORDER:
		var socket_record := socket(socket_id)
		if bool(socket_record.get("can_place", false)) and not bool(socket_record.get("route_blocked", false)):
			placement_ready = true
			break
	var raw: Array[Dictionary] = [
		{
			"id": &"parcel_deed",
			"label": "PARCEL DEED",
			"status": &"complete" if parcel_owned else &"active" if bool(_parcel.get("can_purchase", false)) else &"pending",
			"detail": String(_parcel.get("reason", "")),
		},
		{
			"id": &"utility_trench",
			"label": "UTILITY TRENCH",
			"status": &"complete" if services_ready else &"active" if parcel_owned else &"pending",
			"detail": "CIRCULATION %s / POWER %s" % [
				"CONNECTED" if circulation_ready else "HELD",
				"CONNECTED" if power_ready else "HELD",
			],
		},
		{
			"id": &"pod_pad",
			"label": "POD PLACEMENT",
			"status": &"complete" if pod_owned else &"active" if placement_ready else &"pending",
			"detail": (
				String(_pod.get("current_socket_id", "")).replace("_", " ").to_upper()
				if pod_owned else
				"SELECT A CLEARED SOCKET"
			),
		},
		{
			"id": &"commissioning",
			"label": "COMMISSIONING",
			"status": &"complete" if pod_operational else &"active" if pod_owned else &"pending",
			"detail": "POD OPERATIONAL" if pod_operational else "OPERATING GATES HELD",
		},
	]
	return _normalize_stages(raw)


func _derived_operational_benefits() -> Array[String]:
	var result: Array[String] = []
	if _projection.has("claim_capacity_bonus"):
		result.append("CLAIM CAPACITY BONUS  +%d FILES" % int(_projection.get("claim_capacity_bonus", 0)))
	if _projection.has("farmgate_capacity_bonus_eggs"):
		result.append("FARMGATE CAPACITY BONUS  +%d EGGS" % int(_projection.get("farmgate_capacity_bonus_eggs", 0)))
	if _projection.has("current_daily_cost_cents"):
		result.append("CURRENT CAMPUS OBLIGATION  %s/DAY" % _money(int(_projection.get("current_daily_cost_cents", 0))))
	return result


func _derived_summary() -> String:
	var complete_count := 0
	for stage: Dictionary in _construction_stages:
		if StringName(String(stage.get("status_id", ""))) in [&"complete", &"operational"]:
			complete_count += 1
	return "CONSTRUCTION STAGES  %d / %d COMPLETE / POD %s" % [
		complete_count,
		_construction_stages.size(),
		"OPERATIONAL" if bool(_projection.get("pod_operational", _pod.get("operational", false))) else "HELD",
	]


func _records_by_id(value: Variant, stable_ids: Array[StringName]) -> Dictionary:
	var result: Dictionary = {}
	if value is Array:
		for record_value: Variant in value as Array:
			if not record_value is Dictionary:
				continue
			var record := record_value as Dictionary
			var record_id := StringName(String(record.get("id", record.get("service_id", record.get("socket_id", "")))))
			if record_id in stable_ids and not result.has(record_id):
				result[record_id] = record.duplicate(true)
	elif value is Dictionary:
		for stable_id: StringName in stable_ids:
			var record_value: Variant = (value as Dictionary).get(
				stable_id,
				(value as Dictionary).get(String(stable_id), {}),
			)
			if record_value is Dictionary:
				result[stable_id] = (record_value as Dictionary).duplicate(true)
	return result


func _dependency_lines(source: Dictionary) -> Array[String]:
	var authored_lines := _copy_lines(source.get("dependency_lines", []))
	if not authored_lines.is_empty():
		return authored_lines
	var result: Array[String] = []
	var dependencies: Variant = source.get("dependencies", [])
	if dependencies is Array:
		for dependency_value: Variant in dependencies as Array:
			if dependency_value is Dictionary:
				var dependency := dependency_value as Dictionary
				var label := String(dependency.get("label", dependency.get("name", dependency.get("id", "DEPENDENCY")))).strip_edges()
				var met := bool(dependency.get("met", dependency.get("satisfied", dependency.get("connected", false))))
				result.append("%s / %s" % ["CLEARED" if met else "HELD", label])
			else:
				var line := String(dependency_value).strip_edges()
				if not line.is_empty():
					result.append(line)
	return result


func _service_dependency_lines(source: Dictionary, reason: String) -> Array[String]:
	var result := _dependency_lines(source)
	if result.is_empty() and bool(_parcel.get("known", false)):
		result.append("NORTH MEADOW DEED / %s" % (
			"CLEARED" if bool(_parcel.get("owned", false)) else "HELD"
		))
		if source.has("required_for_pod"):
			result.append("EGG ROUTING POD / %s" % (
				"REQUIRED SERVICE" if bool(source.get("required_for_pod", false)) else "OPTIONAL SERVICE"
			))
	if (
		result.is_empty()
		and not reason.is_empty()
		and not bool(source.get("connected", source.get("commissioned", false)))
	):
		result.append(reason)
	return result


func _benefit_lines_with_quote(source: Dictionary, quote: Dictionary) -> Array[String]:
	var result := _copy_lines(source.get("benefit_lines", source.get("benefits", [])))
	if result.is_empty():
		result = _quote_effect_lines(quote)
	return result


func _quote_effect_lines(quote: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if quote.has("claim_capacity_before") and quote.has("claim_capacity_after"):
		result.append("CLAIM CAPACITY  %d -> %d" % [
			int(quote.get("claim_capacity_before", 0)),
			int(quote.get("claim_capacity_after", 0)),
		])
	if quote.has("farmgate_capacity_before") and quote.has("farmgate_capacity_after"):
		result.append("FARMGATE CAPACITY  %d -> %d EGGS" % [
			int(quote.get("farmgate_capacity_before", 0)),
			int(quote.get("farmgate_capacity_after", 0)),
		])
	if quote.has("projected_spendable_cents"):
		result.append("PROJECTED SPENDABLE  %s" % _money(int(quote.get("projected_spendable_cents", 0))))
	return result


func _invalid_quote(socket_id: StringName, reason: String) -> Dictionary:
	return {
		"socket_id": socket_id,
		"can_authorize": false,
		"cost_cents": 0,
		"has_cost": false,
		"recurring_cost_cents": int(_pod.get("recurring_cost_cents", 0)),
		"has_recurring_cost": bool(_pod.get("has_recurring_cost", false)),
		"reason": reason,
	}


func _status_label(status_id: StringName) -> String:
	match status_id:
		&"owned", &"connected", &"complete", &"operational":
			return "COMPLETE"
		&"ready", &"available":
			return "READY"
		&"active", &"building", &"construction":
			return "IN PROGRESS"
		&"route_blocked":
			return "ROUTE BLOCKED"
		_:
			return "HELD"


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


func _first_int(source: Dictionary, keys: Array[String]) -> int:
	for key: String in keys:
		if source.has(key):
			return int(source.get(key, 0))
	return 0


func _first_int_pair(primary: Dictionary, secondary: Dictionary, keys: Array[String]) -> int:
	if _has_any(primary, keys):
		return _first_int(primary, keys)
	return _first_int(secondary, keys)


func _has_any(source: Dictionary, keys: Array[String]) -> bool:
	for key: String in keys:
		if source.has(key):
			return true
	return false


func _dictionary_value(value: Variant) -> Dictionary:
	return value as Dictionary if value is Dictionary else {}


func _money(cents: int) -> String:
	return "$%.2f" % (float(cents) / 100.0)
