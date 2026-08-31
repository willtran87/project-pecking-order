extends SceneTree

const AdvancementScript := preload("res://core/experience/cohesive_game_loop_advancement.gd")


func _init() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(260831, 4)
	for worker_id in simulation.workers.size():
		simulation.set_worker_at_workstation(worker_id, true)
	_check(simulation.select_directive(&"shell_assurance"), "fixture should start a shift", failures)
	var playbook := simulation.playbook_snapshot(0)
	var challenge_catalog := CampaignState.challenge_contract_catalog()
	var scenario_catalog := DepartmentSimulation.replay_scenario_catalog()
	var layer := AdvancementScript.compose({
		"simulation": simulation.snapshot(),
		"active_playbook": playbook,
		"consolidated_game_loop": {
			"cold_open": {"budget_seconds": 30},
			"environment_interactions": {"hotspots": [1, 2, 3, 4, 5, 6]},
			"reward_cadence": {"micro": {}, "shift": {}, "chapter": {}},
		},
		"professional_gameplay_completion": {"hero_case_catalog": [1, 2, 3, 4, 5, 6, 7, 8]},
		"intuitive_rewarding_completion": {
			"compact_hierarchy": {"order": ["NOW", "WORLD", "RESULT", "DETAILS"]},
			"professional_polish": {
				"experiential_polish": {
					"next_level_polish": {
						"core_loop_mastery_polish": {
							"file_personalities": {"types": ["RUSH", "RETURNED", "PRIZE", "FRAGILE", "SENSITIVE", "REPAIR", "STEADY"]},
							"hen_ambitions": {"objectives": [{"worker_id": 0}]},
						},
					},
				},
			},
		},
		"first_session_funnel": {"signals": {"first_route": false}, "micro_shift": {"active": true}},
		"action_feedback": {"visible": true, "title": "CLEAN FILE"},
		"relationship_episode": {"available": true, "score": 28},
		"rival": {"name": "Golden Comb Group", "difference": -2},
		"chapter": {"title": "Final Hearing"},
		"campaign": {
			"available_milestones": [{"id": "padded_perches"}, {"id": "clockwork_roost"}],
			"chosen_milestone_id": "",
			"active_doctrine": {},
			"final_evaluation": {"passed": false},
		},
		"scenario": simulation.scenario_identity_snapshot(),
		"challenge_contract_catalog": challenge_catalog,
		"scenario_catalog": scenario_catalog,
		"cause_replay": {"available": true, "sequence": ["FILE", "HEN", "RESULT"]},
	})
	var item_ids: Array[String] = []
	for item_value in layer.get("items", []) as Array:
		if item_value is Dictionary:
			item_ids.append(String((item_value as Dictionary).get("id", "")))
	_check(
		int(layer.get("version", 0)) == 1
		and bool(layer.get("canonical", false))
		and not bool(layer.get("authoritative", true))
		and not bool(layer.get("adds_default_panel", true))
		and not bool(layer.get("adds_currency", true))
		and int(layer.get("item_count", 0)) == 25
		and int(layer.get("product_complete_count", 0)) == 25
		and bool(layer.get("all_product_work_complete", false))
		and item_ids.size() == 25
		and item_ids.duplicate().all(func(item_id): return item_ids.count(item_id) == 1),
		"the cohesive advancement should resolve the exact twenty-five product items once",
		failures,
	)
	var validation := layer.get("first_player_validation", {}) as Dictionary
	var subtraction := layer.get("subtraction_guard", {}) as Dictionary
	var curriculum := layer.get("icon_curriculum", {}) as Dictionary
	var why := layer.get("why_inspection", {}) as Dictionary
	_check(
		String(validation.get("status", "")) == "AWAITING REAL PARTICIPANTS"
		and not bool(validation.get("results_complete", true))
		and bool(validation.get("never_fabricate", false))
		and not bool(layer.get("human_evidence_complete", true))
		and bool(subtraction.get("one_primary_action", false))
		and int(subtraction.get("supporting_metric_limit", 0)) == 2
		and int(subtraction.get("required_prose_words", -1)) == 0
		and (curriculum.get("order", []) as Array).size() == 3
		and not bool(curriculum.get("color_only", true))
		and (why.get("triggers", []) as Array) == ["HOLD H", "CLICK LATEST CAUSE"],
		"clarity, progressive disclosure, explainability, and human evidence should stay concrete and honest",
		failures,
	)
	var cash_out := layer.get("flow_cash_out", {}) as Dictionary
	var contract_draft := layer.get("contract_draft", {}) as Dictionary
	var resources := layer.get("resource_tradeoffs", {}) as Dictionary
	var allocation := layer.get("end_shift_allocation", {}) as Dictionary
	_check(
		(cash_out.get("choices", []) as Array).size() == 2
		and String(((cash_out.get("choices", []) as Array)[0] as Dictionary).get("id", "")) == "bank_clutch"
		and String(((cash_out.get("choices", []) as Array)[1] as Dictionary).get("id", "")) == "chase_premium"
		and (contract_draft.get("campaign_contracts", []) as Array).size() == 3
		and (resources.get("resources", []) as Array).size() == 5
		and bool(resources.get("gain_cost_risk_disclosed", false))
		and bool(allocation.get("single_choice", false))
		and bool(allocation.get("preview_before_filing", false)),
		"flow, contracts, resources, and reward allocation should expose real choices and tradeoffs",
		failures,
	)
	var content := layer.get("signature_content", {}) as Dictionary
	var scenarios := layer.get("scenario_modes", {}) as Dictionary
	var difficulty := layer.get("difficulty_contracts", {}) as Dictionary
	var music := layer.get("dynamic_music", {}) as Dictionary
	var cadence := layer.get("content_cadence", {}) as Dictionary
	_check(
		int(content.get("hero_case_count", 0)) == 8
		and int(content.get("file_personality_count", 0)) == 7
		and int(content.get("scenario_count", 0)) == scenario_catalog.size()
		and (scenarios.get("catalog", []) as Array).size() == scenario_catalog.size()
		and bool(scenarios.get("distinct_rules_not_only_numbers", false))
		and (difficulty.get("catalog", []) as Array).size() == 3
		and (difficulty.get("expected_labels", []) as Array) == ["LEARNING", "STANDARD", "EXPERT"]
		and (music.get("layers", []) as Array).size() == 5
		and (cadence.get("rhythm", []) as Array) == ["ANTICIPATE", "DECIDE", "ACT", "LAND", "REFLECT"],
		"content, scenarios, difficulty, audio, and reward cadence should be complete and distinct",
		failures,
	)
	if not failures.is_empty():
		for failure in failures:
			push_error("COHESIVE_GAME_LOOP_ADVANCEMENT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("COHESIVE_GAME_LOOP_ADVANCEMENT_TEST_PASSED items=25 panels=0 currency=0 human-study=awaiting scenarios=%d" % scenario_catalog.size())
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
