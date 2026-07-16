extends SceneTree

const PortfolioModelScript := preload("res://features/office/campus_portfolio_model.gd")
const PortfolioStateScript := preload("res://core/simulation/campus_portfolio_state.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var model := PortfolioModelScript.new() as CampusPortfolioModel
	var snapshot := _snapshot()
	model.set_snapshot(snapshot)

	_check(model.has_projection(), "a full snapshot containing campus_portfolio should be recognized", failures)
	_check(model.parcel_ids() == [&"north_meadow", &"orchard_row", &"creekside_yard"], "the three authored parcels should retain stable spatial order", failures)
	var resources := model.resources()
	_check(int(resources.get("feed_fund_cents", 0)) == 51_250, "Feed Fund should come from the full snapshot without recalculation", failures)
	_check(int(resources.get("spendable_fund_cents", 0)) == 32_500 and int(resources.get("protected_reserve_cents", 0)) == 18_750, "spendable and reserve should remain exact", failures)
	_check(int(resources.get("contractor_used", 0)) == 1 and int(resources.get("contractor_capacity", 0)) == 2, "nested contractor slots should normalize", failures)
	_check(int(resources.get("power_used", 0)) == 4 and int(resources.get("power_capacity", 0)) == 8, "nested power network should normalize", failures)
	_check(int(resources.get("cold_used", 0)) == 2 and int(resources.get("cold_capacity", 0)) == 6, "nested cold network should normalize", failures)

	_check(model.pad_ids(&"north_meadow") == [&"meadow_west", &"meadow_east"], "embedded parcel pad arrays should normalize", failures)
	_check(model.pad_ids(&"orchard_row") == [&"orchard_loading"], "dictionary-backed parcel pad records should retain their key identity", failures)
	_check(model.module_ids().size() == 4, "dictionary-backed module catalog should preserve every authored module", failures)
	var rail := model.module(&"collection_rail_hub")
	_check(int(rail.get("cost_cents", 0)) == 14_000 and int(rail.get("daily_cost_cents", 0)) == 650, "module capital and daily costs should be copied exactly", failures)
	_check(int(rail.get("contractor_slots", 0)) == 1 and int(rail.get("power_required", 0)) == 2, "module capacity draws should normalize canonical unit fields", failures)
	_check((rail.get("effect_lines", []) as Array).size() == 2, "all authored module benefits should survive normalization", failures)

	var meadow_deed := model.deed_quote(&"north_meadow")
	var orchard_deed := model.deed_quote(&"orchard_row")
	_check(not bool(meadow_deed.get("can_authorize", true)), "an owned deed must never emit another purchase", failures)
	_check(bool(orchard_deed.get("can_authorize", false)) and int(orchard_deed.get("cost_cents", 0)) == 9_500, "ready deed price and readiness should remain authoritative", failures)
	_check(_contains_all(String(orchard_deed.get("reason", "")), ["survey", "filed"]), "deed reason should be preserved verbatim", failures)

	var rail_west := model.project_quote(&"collection_rail_hub", &"meadow_west")
	var rail_east := model.project_quote(&"collection_rail_hub", &"meadow_east")
	_check(bool(rail_west.get("can_authorize", false)) and int(rail_west.get("cost_cents", 0)) == 14_000 and int(rail_west.get("duration_shifts", 0)) == 2, "pad-specific project quote should preserve exact authorization, cost, and duration", failures)
	_check(not bool(rail_east.get("can_authorize", true)) and _contains_all(String(rail_east.get("reason", "")), ["rail", "trunk"]), "blocked pad reason should override a general module quote", failures)

	var projects := model.projects()
	_check(projects.size() == 1, "the active project queue should preserve its authored records", failures)
	_check(StringName(String(projects[0].get("job_id", ""))) == &"job_grain_01" and int(projects[0].get("remaining_shifts", 0)) == 1, "project identity and ETA should remain exact", failures)
	_check((projects[0].get("stages", []) as Array).size() == 3, "authored construction stages should remain visible", failures)
	_check(model.assignment_for(&"grain_recovery_mill") == 17, "module-to-worker assignment should retain its worker identity", failures)
	_check(String(model.worker(17).get("name", "")) == "Mabel", "dictionary-backed named workers should normalize", failures)
	_check(not bool(model.workers_for_module(&"grain_recovery_mill")[1].get("can_assign_here", true)), "worker eligibility should remain module-specific", failures)

	# Returned records and the original input cannot mutate presentation authority.
	rail["cost_cents"] = 1
	(snapshot["campus_portfolio"] as Dictionary)["modules"]["collection_rail_hub"]["capital_cost_cents"] = 2
	_check(int(model.module(&"collection_rail_hub").get("cost_cents", 0)) == 14_000, "model getters and input should be defensively copied", failures)

	# The same contract is valid when callers pass the projection directly.
	model.set_snapshot(snapshot["campus_portfolio"] as Dictionary)
	_check(model.parcels().size() == 3 and model.projects().size() == 1, "direct campus_portfolio projection should be accepted", failures)

	# Stay attached to the live construction ledger's canonical snapshot aliases.
	var live_state := PortfolioStateScript.new() as CampusPortfolioState
	model.set_snapshot(live_state.snapshot({
		"day": 9,
		"planning_open": true,
		"power_capacity_units": 10,
		"cold_capacity_units": 10,
		"valid_worker_ids": [17],
		"worker_names": {17: "Mabel"},
	}))
	_check(model.parcel_ids() == [&"orchard_row", &"creekside_yard"], "live ledger parcels should normalize without fabricating legacy North Meadow", failures)
	_check(int(model.resources().get("contractor_capacity", 0)) == 1 and int(model.resources().get("power_capacity", 0)) == 10, "live contractor and network dictionaries should feed the compact resource rail", failures)
	var live_quote := model.project_quote(&"collection_rail_hub", &"orchard_west")
	_check(bool(live_quote.get("known", false)) and int(live_quote.get("cost_cents", 0)) == 14_000, "live placement_quotes array should drive exact module economics", failures)
	_check(not String(live_quote.get("reason", "")).strip_edges().is_empty(), "live held project should retain its authoritative dependency reason", failures)

	model.set_snapshot({})
	_check(not model.has_projection(), "empty input should remain an explicit empty state", failures)
	_check(model.parcels().is_empty() and model.modules().is_empty() and not bool(model.project_quote(&"missing", &"missing").get("can_authorize", true)), "empty state should not invent parcels, modules, quotes, or readiness", failures)

	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPUS_PORTFOLIO_MODEL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_PORTFOLIO_MODEL_TEST_PASSED parcels=3 collections=array+dict resources=exact quotes=deed+project projects=staged staffing=named defensive=true")
	quit(0)


func _snapshot() -> Dictionary:
	return {
		"feed_fund_cents": 51_250,
		"spendable_fund_cents": 32_500,
		"protected_reserve_cents": 18_750,
		"workers": {
			17: {"name": "Mabel", "role": "Routing analyst", "available": true, "eligible_module_ids": [&"grain_recovery_mill", &"collection_rail_hub"]},
			23: {"name": "Juniper", "role": "Cold-chain clerk", "available": true, "eligible_module_ids": [&"creekside_chilling_exchange"]},
		},
		"campus_portfolio": {
			"selected_parcel_id": &"north_meadow",
			"selected_pad_id": &"meadow_west",
			"selected_module_id": &"collection_rail_hub",
			"contractor": {"active_slots": 1, "capacity_slots": 2},
			"network": {
				"power_reserved_units": 4,
				"power_capacity_units": 8,
				"cold_reserved_units": 2,
				"cold_capacity_units": 6,
			},
			"parcels": [
				{
					"id": &"north_meadow",
					"name": "North Meadow",
					"owned": true,
					"deed_cost_cents": 8_500,
					"daily_cost_cents": 300,
					"can_purchase": false,
					"reason": "North Meadow deed already filed.",
					"pads": [
						{"id": &"meadow_west", "name": "West Apron", "parcel_id": &"north_meadow", "occupied": false, "blocked": false, "reason": "Rail and circulation routes clear."},
						{"id": &"meadow_east", "name": "East Apron", "parcel_id": &"north_meadow", "occupied": false, "blocked": true, "reason": "Protected rail trunk crosses this pad."},
					],
				},
				{
					"id": &"orchard_row",
					"name": "Orchard Row",
					"owned": false,
					"deed_cost_cents": 9_500,
					"daily_cost_cents": 375,
					"can_purchase": true,
					"reason": "Boundary survey filed; deed is ready.",
					"pads": {"orchard_loading": {"name": "Loading Pad", "blocked": false}},
				},
				{
					"id": &"creekside_yard",
					"name": "Creekside Yard",
					"owned": true,
					"can_purchase": false,
					"pads": [{"id": &"creek_exchange", "name": "Exchange Pad", "blocked": false}],
				},
			],
			"modules": {
				"collection_rail_hub": {
					"name": "Collection Rail Hub",
					"parcel_id": &"north_meadow",
					"allowed_pad_ids": [&"meadow_west", &"meadow_east"],
					"capital_cost_cents": 14_000,
					"daily_cost_cents": 650,
					"duration_shifts": 2,
					"contractor_slots": 1,
					"power_units": 2,
					"cold_units": 0,
					"staff_required": 1,
					"benefits": ["Adds one collection rail branch.", "Relieves routing overflow."],
					"quote": {"can_authorize": true, "reason": "Contractor and power capacity are filed.", "cost_cents": 14_000, "added_daily_cost_cents": 650, "duration_shifts": 2},
					"pad_quotes": {
						"meadow_west": {"can_authorize": true, "reason": "West rail tie-in cleared.", "cost_cents": 14_000, "added_daily_cost_cents": 650, "duration_shifts": 2},
					},
				},
				"grain_recovery_mill": {"name": "Grain Recovery Mill", "parcel_id": &"north_meadow", "allowed_pad_ids": [&"meadow_west"], "capital_cost_cents": 11_500, "daily_cost_cents": 575, "duration_shifts": 2, "power_units": 2, "staff_required": 1, "can_authorize": false, "reason": "A mill project is already active."},
				"creekside_chilling_exchange": {"name": "Creekside Chilling Exchange", "parcel_id": &"creekside_yard", "allowed_pad_ids": [&"creek_exchange"], "capital_cost_cents": 16_000, "daily_cost_cents": 800, "duration_shifts": 3, "power_units": 2, "cold_units": 3, "staff_required": 1, "can_authorize": true, "reason": "Creekside service routes are clear."},
				"contractor_roost": {"name": "Contractor Roost", "parcel_id": &"orchard_row", "allowed_pad_ids": [&"orchard_loading"], "capital_cost_cents": 12_500, "daily_cost_cents": 700, "duration_shifts": 2, "can_authorize": false, "reason": "Purchase Orchard Row first."},
			},
			"projects": [{
				"project_id": &"job_grain_01",
				"module_id": &"grain_recovery_mill",
				"module_name": "Grain Recovery Mill",
				"parcel_id": &"north_meadow",
				"pad_id": &"meadow_west",
				"status": &"building",
				"stage_id": &"frame",
				"progress_shifts": 1,
				"duration_shifts": 2,
				"remaining_shifts": 1,
				"stages": [
					{"id": &"stakes", "label": "Survey Stakes", "status": &"complete"},
					{"id": &"frame", "label": "Timber Frame", "status": &"active"},
					{"id": &"commission", "label": "Commission", "status": &"pending"},
				],
			}],
			"assignments": {"grain_recovery_mill": 17},
		},
	}


func _contains_all(text_value: String, needles: Array[String]) -> bool:
	var lowered := text_value.to_lower()
	for needle: String in needles:
		if needle.to_lower() not in lowered:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
