extends SceneTree

const CompletionScript := preload("res://core/experience/intuitive_rewarding_completion.gd")


func _init() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(260830, 4)
	for worker_id in simulation.workers.size():
		simulation.set_worker_at_workstation(worker_id, true)
	_check(simulation.select_directive(&"shell_assurance"), "fixture should enter a running shift", failures)
	simulation.solidarity = 100.0
	for worker in simulation.workers:
		if worker.employed:
			worker.morale = 100.0
			worker.stress = 0.0
			worker.fatigue = 0.0
	var playbook := simulation.playbook_snapshot(0)
	var layer := CompletionScript.compose({
		"simulation": simulation.snapshot(),
		"next_action": {"visible_label": "ROUTE FILE", "world_target": "intake_tray"},
		"active_playbook": playbook,
		"consolidated_game_loop": {"unified_cue": {"now": "ROUTE", "why": "MATCH SKILL", "reward": "CLEAN EGG"}},
		"professional_gameplay_completion": {
			"rival_race": {"responses": ["DEFEND", "COUNTER", "BACK FLOCK"]},
			"mastery_variety": {"challenges": [1, 2, 3, 4, 5, 6]},
		},
		"first_session_funnel": {"micro_shift": {"active": true}, "signals": {"first_route": false}},
		"guided_loop": {"consequence_icons": ["flock", "egg"]},
		"complete_loop": {"review": {"seconds": 10}},
		"rewarding_loop": {"transformative_reward": {"changes_verb": true}},
		"mastery_replay": {"rematch": {"same_seed": true, "rule_change_count": 1}},
		"strategic_flow_loop": {"challenge_variation": {"permanent": true}},
	})
	var items := layer.get("items", []) as Array
	var ids: Array[String] = []
	for item_value in items:
		if item_value is Dictionary:
			ids.append(String((item_value as Dictionary).get("id", "")))
	_check(
		int(layer.get("version", 0)) == 1
		and bool(layer.get("canonical", false))
		and not bool(layer.get("authoritative", true))
		and int(layer.get("item_count", 0)) == 33
		and int(layer.get("implemented_count", 0)) == 33
		and bool(layer.get("all_implemented", false))
		and ids.size() == 33
		and ids.duplicate().all(func(item_id): return ids.count(item_id) == 1),
		"the completion contract should cover the exact 33-item brief once",
		failures,
	)
	var cue := layer.get("now_why_reward", {}) as Dictionary
	var first_minute := layer.get("first_minute", {}) as Dictionary
	var visual := layer.get("visual_language", {}) as Dictionary
	_check(
		String(cue.get("now", "")) == "ROUTE"
		and int(cue.get("word_budget", 0)) == 6
		and int(first_minute.get("seconds", 0)) == 60
		and (first_minute.get("path", []) as Array) == ["PLAN", "ROUTE", "HELP", "REWARD"]
		and bool(first_minute.get("skippable", false))
		and bool(visual.get("details_on_demand", false))
		and bool(visual.get("one_primary_action", false)),
		"the default loop should remain playable, concise, icon-led, and progressively disclosed",
		failures,
	)
	var partnership := layer.get("partnership_growth", {}) as Dictionary
	var hero := layer.get("hero_file", {}) as Dictionary
	var automation := layer.get("automation", {}) as Dictionary
	_check(
		bool(partnership.get("specialization_unlocked", false))
		and (partnership.get("choices", []) as Array).size() == 2
		and bool((hero.get("staging", {}) as Dictionary).get("prepared_slot", false))
		and not bool((hero.get("repetition_guard", {}) as Dictionary).get("immediate_repeat_allowed", true))
		and bool(automation.get("exceptions_manual", false))
		and (automation.get("world_behavior", []) as Array).size() == 5,
		"relationships, hero staging, repetition protection, and physical automation should be complete",
		failures,
	)
	var mastery := layer.get("mastery_challenges", {}) as Dictionary
	var study := layer.get("human_study", {}) as Dictionary
	_check(
		bool(mastery.get("permanent", false))
		and not bool(mastery.get("expires", true))
		and int(mastery.get("miss_penalty", -1)) == 0
		and int(study.get("minimum_participants", 0)) == 5
		and String(study.get("status", "")) == "AWAITING REAL PARTICIPANTS"
		and not bool(study.get("results_complete", true))
		and bool(study.get("never_fabricate", false)),
		"mastery should avoid FOMO and the human-study boundary must remain honest",
		failures,
	)
	if not failures.is_empty():
		for failure in failures:
			push_error("INTUITIVE_REWARDING_COMPLETION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("INTUITIVE_REWARDING_COMPLETION_TEST_PASSED items=33 cue=6-words tutorial=60s partnership=2-styles automation=physical mastery=no-fomo study=awaiting-humans")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
