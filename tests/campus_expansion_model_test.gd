extends SceneTree

const CampusExpansionModelScript := preload("res://features/office/campus_expansion_model.gd")
const DepartmentSimulationScript := preload("res://core/simulation/department_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var model := CampusExpansionModelScript.new() as CampusExpansionModel
	var snapshot := _planning_snapshot(false)
	model.set_snapshot(snapshot)

	_check(model.has_projection(), "campus_expansion should be recognized inside the main snapshot", failures)
	_check(CampusExpansionModel.PARCEL_ID == &"north_meadow", "North Meadow should retain its stable parcel ID", failures)
	_check(CampusExpansionModel.SERVICE_ORDER == [&"circulation", &"power", &"cold_chain"], "utility order should match the stable integration contract", failures)
	_check(CampusExpansionModel.SOCKET_ORDER == [&"meadow_west", &"meadow_east", &"service_spine"], "Socket A/B/C should use their stable route IDs", failures)

	var parcel := model.parcel()
	_check(bool(parcel.get("owned", false)), "owned North Meadow state should be copied exactly", failures)
	_check(int(parcel.get("purchase_cost_cents", 0)) == 8_500, "parcel capital price should be copied exactly", failures)
	_check(int(parcel.get("recurring_cost_cents", 0)) == 300, "parcel recurring cost should be copied exactly", failures)
	_check(_contains_all(_line_copy(parcel.get("dependency_lines", [])), ["day 6", "farmgate depot"]), "parcel dependencies should remain explicit", failures)

	var circulation := model.service(&"circulation")
	var power := model.service(&"power")
	var cold_chain := model.service(&"cold_chain")
	_check(bool(circulation.get("connected", false)) and int(circulation.get("purchase_cost_cents", 0)) == 2_800 and int(circulation.get("recurring_cost_cents", 0)) == 150, "circulation should preserve connection and exact costs", failures)
	_check(bool(power.get("can_connect", false)) and int(power.get("purchase_cost_cents", 0)) == 3_500 and int(power.get("recurring_cost_cents", 0)) == 225, "power should preserve its actionable exact quote", failures)
	_check(not bool(cold_chain.get("can_connect", true)) and _contains_all(String(cold_chain.get("reason", "")), ["power", "first"]), "cold-chain should preserve its plain dependency hold", failures)
	_check(_contains_all(_line_copy(power.get("dependency_lines", [])), ["cleared", "north meadow", "held", "circulation trench"]), "structured utility dependencies should expose cleared and held terms exactly", failures)

	var west := model.socket(&"meadow_west")
	var east := model.socket(&"meadow_east")
	var spine := model.socket(&"service_spine")
	_check(String(west.get("label", "")) == "MEADOW WEST SOCKET" and bool(west.get("can_place", false)), "Socket A should retain its filed west route", failures)
	_check(String(east.get("label", "")) == "MEADOW EAST SOCKET" and bool(east.get("can_place", false)), "Socket B should retain its filed east route", failures)
	_check(bool(spine.get("route_blocked", false)) and _contains_all(String(spine.get("route_reason", "")), ["service spine", "circulation route"]), "Socket C should retain its route-blocked explanation", failures)

	var place_west := model.placement_quote(&"meadow_west")
	var place_spine := model.placement_quote(&"service_spine")
	_check(bool(place_west.get("can_authorize", false)), "cleared west socket should expose an actionable placement quote", failures)
	_check(int(place_west.get("cost_cents", 0)) == 7_500 and int(place_west.get("recurring_cost_cents", 0)) == 500, "pod placement should retain exact capital and recurring costs", failures)
	_check(not bool(place_spine.get("can_authorize", true)) and _contains_all(String(place_spine.get("reason", "")), ["service spine", "circulation route"]), "route-blocked socket should never authorize pod placement", failures)

	_check(model.construction_stages().size() == 4, "the staged construction schedule should remain complete", failures)
	_check(_contains_all(model.project_summary(), ["four filed stages", "operational after commissioning"]), "authored construction summary should remain exact", failures)
	_check(_contains_all(_line_copy(model.operational_benefits()), ["six claim files", "six farmgate eggs"]), "operational effects should remain authored snapshot data", failures)
	_check(model.default_socket_id() == &"meadow_west", "authored preview socket should determine initial selection", failures)

	# Defensive copies prevent this presentation layer from mutating authority.
	parcel["purchase_cost_cents"] = 1
	_check(int(model.parcel().get("purchase_cost_cents", 0)) == 8_500, "parcel getter should return a defensive copy", failures)
	(snapshot["campus_expansion"] as Dictionary)["summary"] = "MUTATED"
	_check(_contains_all(model.project_summary(), ["four filed stages"]), "model should not retain caller-owned snapshot aliases", failures)

	# Installed pod switches the same stable socket records to relocation quotes.
	model.set_snapshot(_planning_snapshot(true))
	var relocation_east := model.relocation_quote(&"meadow_east")
	var relocation_current := model.relocation_quote(&"meadow_west")
	_check(bool(relocation_east.get("can_authorize", false)), "installed west pod should be relocatable to cleared east", failures)
	_check(StringName(String(relocation_east.get("from_socket_id", ""))) == &"meadow_west" and int(relocation_east.get("cost_cents", 0)) == 1_800, "relocation quote should retain exact origin and cost", failures)
	_check(not bool(relocation_current.get("can_authorize", true)) and _contains_all(String(relocation_current.get("reason", "")), ["already installed", "socket"]), "current socket should disable no-op relocation with a plain reason", failures)

	# Migration/tool snapshots may use the authoritative flat projection. Nested
	# quotes must normalize to the same cards, sockets, stages, and exact effects.
	model.set_snapshot(_flat_authoritative_snapshot())
	parcel = model.parcel()
	power = model.service(&"power")
	east = model.socket(&"meadow_east")
	_check(bool(parcel.get("owned", false)) and int(parcel.get("purchase_cost_cents", 0)) == 8_500 and int(parcel.get("recurring_cost_cents", 0)) == 300, "flat parcel_owned plus parcel_quote should normalize exact North Meadow terms", failures)
	_check(bool(power.get("connected", false)) and int(power.get("purchase_cost_cents", 0)) == 3_500 and int(power.get("recurring_cost_cents", 0)) == 225, "service commissioned plus nested quote should normalize exact utility terms", failures)
	_check(bool(east.get("can_relocate", false)) and int(east.get("relocation_cost_cents", 0)) == 1_800, "nested socket relocation_quote should normalize readiness and cost", failures)
	_check(bool(model.routing_pod().get("placed", false)) and StringName(String(model.routing_pod().get("current_socket_id", ""))) == &"meadow_west", "flat pod_owned and pod_socket_id should normalize current module placement", failures)
	_check(model.construction_stages().size() == 4 and _contains_all(model.project_summary(), ["4 / 4 complete", "pod operational"]), "flat authoritative state should derive a four-stage status summary", failures)
	_check(_contains_all(_line_copy(model.operational_benefits()), ["+6 files", "+6 eggs", "$15.75/day"]), "flat exact bonuses and current obligation should drive the operational summary", failures)
	_check(bool(model.relocation_quote(&"meadow_east").get("can_authorize", false)), "flat east relocation quote should remain actionable", failures)

	# The live simulation publishes the rich form; keep this focused contract test
	# attached to its exact prices, route explanation, and authored summaries.
	var simulation := DepartmentSimulationScript.new() as DepartmentSimulation
	model.set_snapshot(simulation.snapshot())
	_check(int(model.parcel().get("purchase_cost_cents", 0)) == 8_500 and int(model.parcel().get("recurring_cost_cents", 0)) == 300, "live campus snapshot should expose exact North Meadow terms", failures)
	_check(int(model.service(&"circulation").get("purchase_cost_cents", 0)) == 2_800 and int(model.service(&"power").get("purchase_cost_cents", 0)) == 3_500 and int(model.service(&"cold_chain").get("purchase_cost_cents", 0)) == 6_000, "live campus snapshot should expose all exact utility prices", failures)
	_check(bool(model.socket(&"service_spine").get("route_blocked", false)) and _contains_all(String(model.socket(&"service_spine").get("route_reason", "")), ["service spine", "circulation route"]), "live service-spine socket should retain its protected-route explanation", failures)
	_check(model.construction_stages().size() == 6 and model.operational_benefits().size() == 2, "live rich snapshot should preserve all authored stages and benefit lines", failures)
	_check(int(model.placement_quote(&"meadow_west").get("cost_cents", 0)) == 7_500 and int(model.placement_quote(&"meadow_west").get("recurring_cost_cents", 0)) == 500, "live placement quote should retain exact pod capital and recurring terms even while held", failures)

	# Empty input retains stable UI affordances but never invents prices or readiness.
	model.set_snapshot({})
	_check(not model.has_projection(), "empty input should remain an explicit empty state", failures)
	_check(model.services().size() == 3 and model.sockets().size() == 3, "empty state should preserve the stable three-card and three-socket structure", failures)
	_check(not bool(model.parcel().get("has_purchase_cost", true)), "empty state should not invent a parcel price", failures)
	_check(not bool(model.placement_quote(&"meadow_west").get("can_authorize", true)), "empty state should never authorize a placement", failures)

	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPUS_EXPANSION_MODEL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_EXPANSION_MODEL_TEST_PASSED parcel=north_meadow utilities=3 sockets=A/B/C quotes=place+relocate data=authoritative")
	quit(0)


func _planning_snapshot(pod_placed: bool) -> Dictionary:
	return {
		"day": 6,
		"campus_expansion": {
			"selected_socket_id": &"meadow_west",
			"parcel": {
				"id": &"north_meadow",
				"name": "NORTH MEADOW PARCEL",
				"owned": true,
				"can_purchase": false,
				"status_label": "DEED FILED",
				"capital_cost_cents": 8_500,
				"daily_cost_cents": 300,
				"dependency_lines": ["Day 6 review open.", "Farmgate Depot level 1 commissioned."],
				"benefits": ["Opens the east-campus construction apron."],
			},
			"utilities": [
				{
					"id": &"circulation",
					"name": "MEADOW CIRCULATION LINK",
					"connected": true,
					"can_connect": false,
					"capital_cost_cents": 2_800,
					"daily_cost_cents": 150,
					"dependencies": [{"label": "North Meadow deed", "met": true}],
				},
				{
					"id": &"power",
					"name": "MEADOW POWER DROP",
					"connected": false,
					"can_connect": true,
					"capital_cost_cents": 3_500,
					"daily_cost_cents": 225,
					"dependencies": [
						{"label": "North Meadow deed", "met": true},
						{"label": "Circulation trench inspection", "met": false},
					],
				},
				{
					"id": &"cold_chain",
					"name": "MEADOW COLD-CHAIN LOOP",
					"connected": false,
					"can_connect": false,
					"capital_cost_cents": 6_000,
					"daily_cost_cents": 400,
					"dependencies": [{"label": "Meadow Power Drop", "met": false}],
					"reason": "Connect Meadow Power Drop first.",
				},
			],
			"sockets": [
				{
					"id": &"meadow_west",
					"name": "MEADOW WEST SOCKET",
					"route_blocked": false,
					"can_place": not pod_placed,
					"can_relocate": false,
					"reason": "Circulation and power routes clear the west apron.",
				},
				{
					"id": &"meadow_east",
					"name": "MEADOW EAST SOCKET",
					"route_blocked": false,
					"can_place": not pod_placed,
					"can_relocate": pod_placed,
					"reason": "East apron route is clear.",
				},
				{
					"id": &"service_spine",
					"name": "SERVICE SPINE SOCKET",
					"route_blocked": true,
					"can_place": false,
					"can_relocate": false,
					"blocked_reason": "The Service Spine is reserved for the flock circulation route.",
				},
			],
			"module": {
				"id": &"egg_routing_pod",
				"name": "EGG ROUTING POD",
				"owned": pod_placed,
				"socket_id": &"meadow_west" if pod_placed else &"",
				"can_place": not pod_placed,
				"can_relocate": pod_placed,
				"capital_cost_cents": 7_500,
				"relocation_cost_cents": 1_800,
				"daily_cost_cents": 500,
			},
			"construction_stages": [
				{"id": &"deed", "label": "PARCEL DEED", "status": &"complete", "detail": "North Meadow filed."},
				{"id": &"trench", "label": "UTILITY TRENCH", "status": &"active", "detail": "Power review open."},
				{"id": &"pad", "label": "POD PAD", "status": &"pending", "detail": "Socket selection held."},
				{"id": &"commission", "label": "COMMISSION", "status": &"pending", "detail": "Operational handoff."},
			],
			"summary": "Four filed stages; the meadow becomes operational after commissioning.",
			"operational_benefits": [
				"Adds six claim files of campus capacity.",
				"Cold-chain service protects six Farmgate eggs.",
			],
		},
	}


func _flat_authoritative_snapshot() -> Dictionary:
	return {
		"campus_expansion": {
			"id": &"campus_expansion",
			"visible": true,
			"parcel_id": &"north_meadow",
			"parcel_owned": true,
			"parcel_quote": _quote(&"purchase_parcel", &"north_meadow", 8_500, 300, false, "North Meadow is already owned."),
			"services": [
				{"id": &"circulation", "name": "MEADOW CIRCULATION LINK", "commissioned": true, "capital_cost_cents": 2_800, "daily_cost_cents": 150, "quote": _quote(&"commission_service", &"circulation", 2_800, 150, false, "Meadow Circulation Link is already commissioned.")},
				{"id": &"power", "name": "MEADOW POWER DROP", "commissioned": true, "capital_cost_cents": 3_500, "daily_cost_cents": 225, "quote": _quote(&"commission_service", &"power", 3_500, 225, false, "Meadow Power Drop is already commissioned.")},
				{"id": &"cold_chain", "name": "MEADOW COLD-CHAIN LOOP", "commissioned": true, "capital_cost_cents": 6_000, "daily_cost_cents": 400, "quote": _quote(&"commission_service", &"cold_chain", 6_000, 400, false, "Meadow Cold-Chain Loop is already commissioned.")},
			],
			"sockets": [
				{"id": &"meadow_west", "name": "MEADOW WEST SOCKET", "route_blocked": false, "blocked_reason": "", "occupied": true, "placement_quote": _quote(&"place_module", &"egg_routing_pod", 7_500, 500, false, "The Egg Routing Pod is already placed; file a relocation instead."), "relocation_quote": _quote(&"relocate_module", &"egg_routing_pod", 1_800, 0, false, "The Egg Routing Pod already occupies this socket.")},
				{"id": &"meadow_east", "name": "MEADOW EAST SOCKET", "route_blocked": false, "blocked_reason": "", "occupied": false, "placement_quote": _quote(&"place_module", &"egg_routing_pod", 7_500, 500, false, "The Egg Routing Pod is already placed; file a relocation instead."), "relocation_quote": _quote(&"relocate_module", &"egg_routing_pod", 1_800, 0, true, "")},
				{"id": &"service_spine", "name": "SERVICE SPINE SOCKET", "route_blocked": true, "blocked_reason": "The Service Spine is reserved for the flock circulation route.", "occupied": false, "placement_quote": _quote(&"place_module", &"egg_routing_pod", 7_500, 500, false, "The Service Spine is reserved for the flock circulation route."), "relocation_quote": _quote(&"relocate_module", &"egg_routing_pod", 1_800, 0, false, "The Service Spine is reserved for the flock circulation route.")},
			],
			"module_id": &"egg_routing_pod",
			"pod_owned": true,
			"pod_socket_id": &"meadow_west",
			"pod_operational": true,
			"cold_chain_active": true,
			"claim_capacity_bonus": 6,
			"farmgate_capacity_bonus_eggs": 6,
			"current_daily_cost_cents": 1_575,
		},
	}


func _quote(action_id: StringName, item_id: StringName, cost: int, daily: int, can_authorize: bool, reason: String) -> Dictionary:
	return {
		"known": true,
		"action_id": action_id,
		"item_id": item_id,
		"name": String(item_id).replace("_", " ").to_upper(),
		"can_authorize": can_authorize,
		"reason": reason,
		"cost_cents": cost,
		"added_daily_cost_cents": daily,
		"claim_capacity_before": 24,
		"claim_capacity_after": 30,
		"farmgate_capacity_before": 24,
		"farmgate_capacity_after": 30,
		"projected_spendable_cents": 8_500,
	}


func _line_copy(value: Variant) -> String:
	var lines: Array[String] = []
	if value is Array:
		for line: Variant in value as Array:
			lines.append(String(line))
	return " ".join(lines)


func _contains_all(text_value: String, needles: Array[String]) -> bool:
	var lowered := text_value.to_lower()
	for needle: String in needles:
		if needle.to_lower() not in lowered:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
