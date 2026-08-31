extends SceneTree

const DirectorScript := preload("res://core/experience/gameplay_pulse_director.gd")
const CampaignStateScript := preload("res://core/campaign/campaign_state.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var pulse := DirectorScript.new().compose({
		"simulation": {
			"day": 2,
			"shift_phase": 1,
			"workers": [
				{"id": 0, "name": "Mabel", "employed": true, "specialty": "appeals"},
				{"id": 1, "name": "Dot", "employed": true, "specialty": "predator_loss"},
			],
		},
		"next_action": {"action_id": "route", "visible_label": "ROUTE APPEAL", "actionable": true},
		"focused_worker_id": 0,
		"challenge_contract_catalog": CampaignStateScript.challenge_contract_catalog(),
		"tactical_route_plan": {
			"count": 2,
			"capacity": 3,
			"queued": [
				{"worker_id": 0, "worker_name": "Mabel", "lane": "appeals", "order": 1},
				{"worker_id": 1, "worker_name": "Dot", "lane": "predator_loss", "order": 2},
			],
			"files_nothing": true,
		},
		"active_playbook": {
			"authoritative": true,
			"strategy_preset_id": "safe",
			"strategy_preset": {"label": "SAFE PLAN"},
			"prediction_score": {"verdict": "ON PLAN", "progress": 2, "target": 3},
			"push_luck": {"available": true},
			"combo_recipe": {"label": "SHELL SEAL", "completed_steps": 1, "total_steps": 2},
			"side_goal": {"label": "MABEL'S CLEAN FILE", "optional": true},
			"hen_proposal": {"label": "TRY APPEALS", "penalty_free": true},
			"challenge": {"code": "PECK-707", "shareable": true},
			"challenge_modifier": {"label": "EARLY RUSH", "optional": true},
			"display_sockets": [{"id": "plan"}, {"id": "medal"}],
		},
	})
	var layer := pulse.get("tactile_reward_loop", {}) as Dictionary
	_check(
		int(pulse.get("version", 0)) == 21
		and int(layer.get("item_count", 0)) == 20
		and int(layer.get("resolved_count", 0)) == 20
		and bool(layer.get("all_resolved", false))
		and not bool(layer.get("authoritative", true)),
		"the tactile reward layer should resolve all twenty items without owning gameplay state",
		failures,
	)
	var plan := layer.get("tactical_pause_plan", {}) as Dictionary
	var resources := layer.get("resource_identities", {}) as Dictionary
	_check(
		bool(plan.get("active", false))
		and int(plan.get("count", 0)) == 2
		and int(plan.get("capacity", 0)) == 3
		and bool(plan.get("files_nothing", false))
		and String(plan.get("commit_action", "")) == "RESUME"
		and int(resources.get("count", 0)) == 6
		and bool(resources.get("source_and_use_visible", false)),
		"pause planning and six distinct resources should remain glanceable and honest",
		failures,
	)
	var tutorial := layer.get("tutorial_shift", {}) as Dictionary
	var intensity := layer.get("intensity_contracts", {}) as Dictionary
	var scenario := layer.get("scenario_board", {}) as Dictionary
	_check(
		int(tutorial.get("safe_practice_ceiling_seconds", 0)) == 300
		and int(tutorial.get("first_reward_budget_seconds", 0)) == 30
		and int(intensity.get("count", 0)) == 3
		and String(intensity.get("default", "")) == "standard_filing"
		and bool(scenario.get("permanent", false))
		and not bool(scenario.get("fomo", true)),
		"tutorial, intensity contracts, and permanent scenarios should expose the shipped authorities",
		failures,
	)
	var comprehension := layer.get("comprehension", {}) as Dictionary
	var relationship_map := layer.get("relationship_map", {}) as Dictionary
	_check(
		bool(comprehension.get("real_participants_required", false))
		and bool(comprehension.get("results_never_fabricated", false))
		and bool(relationship_map.get("world_first", false))
		and not bool(relationship_map.get("dense_panel_required", true)),
		"comprehension evidence must stay honest and relationships must stay world-first",
		failures,
	)
	if not failures.is_empty():
		for failure in failures:
			push_error("TACTILE_REWARD_LOOP_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("TACTILE_REWARD_LOOP_TEST_PASSED items=20 plan=2/3 resources=6 intensity=3 scenario=permanent comprehension=honest")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
