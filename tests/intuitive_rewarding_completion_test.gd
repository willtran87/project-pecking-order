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
		int(layer.get("version", 0)) == 3
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
	var polish := layer.get("professional_polish", {}) as Dictionary
	var polish_items := polish.get("items", []) as Array
	var polish_ids: Array[String] = []
	for item_value in polish_items:
		if item_value is Dictionary:
			polish_ids.append(String((item_value as Dictionary).get("id", "")))
	var spotlight := polish.get("action_spotlight", {}) as Dictionary
	var direct := polish.get("direct_file_manipulation", {}) as Dictionary
	var reactions := polish.get("reaction_first_feedback", {}) as Dictionary
	var rematch := polish.get("rematch_experiment", {}) as Dictionary
	var observation := polish.get("first_shift_observation", {}) as Dictionary
	_check(
		int(polish.get("version", 0)) == 2
		and bool(polish.get("canonical", false))
		and not bool(polish.get("authoritative", true))
		and not bool(polish.get("adds_default_panel", true))
		and int(polish.get("item_count", 0)) == 25
		and int(polish.get("resolved_count", 0)) == 25
		and bool(polish.get("all_resolved", false))
		and polish_ids.size() == 25
		and polish_ids.duplicate().all(func(item_id): return polish_ids.count(item_id) == 1),
		"the professional polish layer should resolve the exact 25-item brief once without another panel",
		failures,
	)
	_check(
		bool(spotlight.get("one_primary", false))
		and int(spotlight.get("required_text_words", -1)) == 0
		and (direct.get("sequence", []) as Array) == ["PICK FILE", "PICK HEN", "LAND"]
		and bool(direct.get("preview_reversible", false))
		and (reactions.get("sequence", []) as Array) == ["WORLD", "HEN", "SOUND", "NUMBER", "DETAIL"]
		and is_equal_approx(float(reactions.get("text_delay_seconds", 0.0)), 0.25),
		"play should lead with one physical spotlight, direct routing, and reaction-first feedback",
		failures,
	)
	_check(
		bool((polish.get("partnership_choreography", {}) as Dictionary).get("both_hens_react", false))
		and bool((polish.get("rival_memory", {}) as Dictionary).get("persistent", false))
		and bool((polish.get("strategy_defining_upgrades", {}) as Dictionary).get("changes_verbs", false))
		and bool((polish.get("collection_cabinet", {}) as Dictionary).get("physical", false))
		and bool(rematch.get("same_seed", false))
		and int(rematch.get("rule_change_count", 0)) == 1
		and String(observation.get("status", "")) == "AWAITING REAL PARTICIPANTS"
		and not bool(observation.get("results_complete", true))
		and bool(observation.get("never_fabricate", false)),
		"relationships, rivalry, progression, rematch, and real-human evidence should stay concrete and honest",
		failures,
	)
	var experiential := polish.get("experiential_polish", {}) as Dictionary
	var experiential_items := experiential.get("items", []) as Array
	var experiential_ids: Array[String] = []
	for item_value in experiential_items:
		if item_value is Dictionary:
			experiential_ids.append(String((item_value as Dictionary).get("id", "")))
	var drag := experiential.get("direct_drag_routing", {}) as Dictionary
	var tutorial := experiential.get("silent_tutorial_file", {}) as Dictionary
	var body_language := experiential.get("readable_body_language", {}) as Dictionary
	var experimental_rematch := experiential.get("experimental_rematch", {}) as Dictionary
	var observed := experiential.get("observed_first_shift", {}) as Dictionary
	_check(
		int(experiential.get("version", 0)) == 1
		and bool(experiential.get("canonical", false))
		and not bool(experiential.get("authoritative", true))
		and not bool(experiential.get("adds_default_panel", true))
		and int(experiential.get("item_count", 0)) == 25
		and int(experiential.get("resolved_count", 0)) == 25
		and bool(experiential.get("all_resolved", false))
		and experiential_ids.size() == 25
		and experiential_ids.duplicate().all(func(item_id): return experiential_ids.count(item_id) == 1),
		"the interaction-first production layer should resolve the exact 25-item brief once",
		failures,
	)
	_check(
		bool(drag.get("enabled", false))
		and bool(drag.get("mouse", false))
		and bool(drag.get("touch", false))
		and bool(drag.get("visible_carried_file", false))
		and bool(drag.get("invalid_drop_returns_file", false))
		and int(tutorial.get("required_prose_words", -1)) == 0
		and bool(tutorial.get("icons_first", false))
		and bool(body_language.get("shape_and_motion_not_color_only", false))
		and (body_language.get("states", []) as Array).size() == 5,
		"routing, onboarding, and chicken state should be physical, icon-led, and readable",
		failures,
	)
	_check(
		bool((experiential.get("partnership_actions", {}) as Dictionary).get("both_hens_react", false))
		and bool((experiential.get("rival_office", {}) as Dictionary).get("responds_to_player_strategy", false))
		and bool((experiential.get("transformative_upgrades", {}) as Dictionary).get("changes_office", false))
		and bool((experiential.get("setback_conversion", {}) as Dictionary).get("banked_rewards_safe", false))
		and bool(experimental_rematch.get("same_seed", false))
		and bool(experimental_rematch.get("one_rule_changed", false))
		and String(observed.get("status", "")) == "AWAITING REAL PARTICIPANTS"
		and not bool(observed.get("results_complete", true))
		and bool(observed.get("never_fabricate", false)),
		"relationships, rivalry, upgrades, recovery, rematch, and human evidence should remain concrete",
		failures,
	)
	if not failures.is_empty():
		for failure in failures:
			push_error("INTUITIVE_REWARDING_COMPLETION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("INTUITIVE_REWARDING_COMPLETION_TEST_PASSED items=33 polish=25 experiential=25 drag=mouse+touch ghost=visible tutorial=silent body-language=5-state partnership=physical rematch=safe study=awaiting-humans")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
