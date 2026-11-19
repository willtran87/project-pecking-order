extends SceneTree

const Director := preload("res://core/experience/gameplay_pulse_director.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var director := Director.new()
	var simulation := DepartmentSimulation.new(1701, DepartmentSimulation.MINIMUM_STAFF_COUNT)
	var context := {
		"simulation": simulation.snapshot(),
		"active_playbook": simulation.playbook_snapshot(1),
		"next_action": {"action_id": "route", "visible_label": "ROUTE FILE", "actionable": true},
		"focused_worker_id": 1,
		"action_feedback": {"visible": false},
	}
	var original := context.duplicate(true)
	var public_pulse := director.compose(context)
	var live_pulse := director.compose(context, true)
	_check(public_pulse == live_pulse, "shared catalogs must preserve every projected value", failures)
	_check(context == original, "composition must not mutate gameplay inputs", failures)
	var first_catalogs := _catalogs(live_pulse)
	for catalog in first_catalogs:
		_check(catalog.is_read_only() and not catalog.is_empty(), "shared catalogs must be immutable and populated", failures)
		for row: Dictionary in catalog:
			_check(row.is_read_only(), "nested descriptor rows must also be immutable", failures)
	var public_catalogs := _catalogs(public_pulse)
	for catalog in public_catalogs:
		_check(not catalog.is_read_only() and not (catalog[0] as Dictionary).is_read_only(), "public projections must retain mutable copies", failures)
		catalog[0]["authority"] = "external change"
		catalog.pop_back()
	_check(director.compose(context) == live_pulse, "external edits must not contaminate shared or future projections", failures)
	context["next_action"]["visible_label"] = "RESUME SHIFT"
	context["next_action"]["action_id"] = "resume_shift"
	context["simulation"]["eggs_today"] = 4
	context["active_playbook"]["contract"]["progress"] = 4
	var next := director.compose(context, true)
	_check(next == director.compose(context), "changed gameplay must match the public projection immediately", failures)
	_check(next["focus_mode"]["copy"] == "RESUME SHIFT" and live_pulse["focus_mode"]["copy"] == "ROUTE FILE", "live actions must update without mutating retained projections", failures)
	var next_catalogs := _catalogs(next)
	for index in first_catalogs.size():
		_check(is_same(first_catalogs[index], next_catalogs[index]), "fixed catalogs must reuse their bounded immutable arrays", failures)

	var office := Office.new()
	root.add_child(office)
	for _frame in 24:
		await process_frame
	var clock := office.get("_clock") as SimulationClock
	clock.set_process(false)
	clock.set_speed(0)
	office.set_process(false)
	var campaign := office.get("_campaign_state") as CampaignState
	var full := campaign.snapshot()
	var compact: Dictionary = office.call("_campaign_pulse_projection")
	_check(compact.size() == 3, "the live campaign projection must exclude history and unrelated forecasts", failures)
	for key in compact:
		_check(compact[key] == full[key], "compact campaign %s must equal the full read model" % key, failures)
	var before := campaign.to_dictionary()
	office.call("_refresh_gameplay_pulse", (office.get("_simulation") as DepartmentSimulation).snapshot())
	_check(campaign.to_dictionary() == before, "presentation must not change campaign authority", failures)
	office.free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("PULSE_CATALOG_REUSE_TEST_%s" % ("PASSED" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)


func _catalogs(pulse: Dictionary) -> Array[Array]:
	var completion: Dictionary = pulse["intuitive_rewarding_completion"]
	var polish: Dictionary = completion["professional_polish"]
	var experiential: Dictionary = polish["experiential_polish"]
	var next_level: Dictionary = experiential["next_level_polish"]
	return [
		completion["items"], polish["items"], experiential["items"], next_level["items"],
		next_level["core_loop_mastery_polish"]["items"],
		pulse["professional_gameplay_completion"]["items"],
		pulse["cohesive_game_loop_advancement"]["items"],
	]


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
