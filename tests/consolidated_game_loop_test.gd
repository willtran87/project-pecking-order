extends SceneTree

const LoopScript := preload("res://core/experience/consolidated_game_loop.gd")
const FunnelScript := preload("res://core/experience/first_session_funnel.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var funnel := FunnelScript.new()
	funnel.begin_intake(0)
	funnel.begin_new_file(1_000)
	funnel.observe({}, {"inspected": true}, &"active", 5_000)
	funnel.observe({}, {"inspected": true, "specialty_routed": true}, &"active", 10_000)
	funnel.observe({}, {"inspected": true, "specialty_routed": true, "checkin_filed": true}, &"active", 15_000)
	funnel.observe({}, {"inspected": true, "specialty_routed": true, "checkin_filed": true, "assisted_claim_id": 7}, &"active", 20_000)
	funnel.observe({"eggs_today": 1}, {"delivery_seen": true}, &"active", 28_000)
	var funnel_snapshot := funnel.snapshot(28_000)
	var layer := LoopScript.compose({
		"simulation": {
			"day": 2,
			"workers": [
				{"id": 0, "name": "Mabel", "employed": true, "stress": 38.0, "career_title": "Senior Appeals", "specialties": ["appeals"], "hen_intent": {"label": "FINISH APPEAL"}, "flock_bond": {"partner_id": 1, "partner_name": "Pip", "score": 76}, "current_claim": {"id": 11, "lane": "appeals", "claimant_name": "Beatrice"}},
				{"id": 1, "name": "Pip", "employed": true, "stress": 72.0, "career_title": "Nest Lead", "specialties": ["nest_damage"], "hen_intent": {"label": "TAKE A BREAK"}, "flock_bond": {"partner_id": 0, "partner_name": "Mabel", "score": 76}},
			],
		},
		"next_action": {"visible_label": "ROUTE APPEAL"},
		"active_playbook": {
			"recommended_preset_id": "safe",
			"strategy_preset": {"label": "SAFE PLAN"},
			"manager_intervention": {"used": true, "definition": {"label": "RING BELL"}},
			"contract": {"label": "CLEAN CARTON"},
			"dominant_objective": {"label": "ROUTE APPEAL"},
			"mastery_automation": {"ready": true, "used": false},
			"career_story": {"label": "MABEL'S APPEAL"},
			"relationship_echo": {"last_move": "TEAM LIFT"},
			"next_shift_preview": {"label": "LATE CARTON"},
			"comprehension_study": {"status": "AWAITING REAL PARTICIPANTS"},
		},
		"first_session_funnel": funnel_snapshot,
		"action_feedback": {"title": "BEST FIT"},
		"focused_worker_id": 0,
		"guided_loop": {"animated_consequence_preview": {"gain": "QUALITY +"}},
		"complete_loop": {"shift_rhythm": {"stage": "flow"}},
		"strategic_loop": {"rival_adaptation": {"label": "RIVAL RUSH"}},
		"intuitive_loop": {"comprehension": {"results_never_fabricated": true}},
		"reward_loop": {"future_reward_ghost": {"label": "GOLDEN FILE"}},
	})
	var expected := [
		"one_now_why_reward_cue", "universal_physical_cause_effect", "playable_first_thirty_seconds",
		"one_hero_case_each_shift", "strong_shift_dramaturgy", "decision_relevant_chicken_identities",
		"flock_pairing_and_positioning", "meaningful_environment_interactions", "mechanically_distinct_case_content",
		"player_authored_management_build", "forecasted_rival_counterplay", "three_level_reward_cadence",
		"upgrades_unlock_new_verbs", "recurring_claimant_and_chicken_stories", "mastery_removes_chores",
		"real_comprehension_playtest_protocol",
	]
	_check(
		int(layer.get("item_count", 0)) == 16
		and int(layer.get("implemented_count", 0)) == 16
		and bool(layer.get("all_implemented", false))
		and bool(layer.get("canonical", false))
		and (layer.get("items", {}) as Dictionary).keys().all(func(key): return String(key) in expected),
		"the canonical layer should consolidate the exact sixteen approved improvements",
		failures,
	)
	var cold_open := layer.get("cold_open", {}) as Dictionary
	var cause := layer.get("cause_effect", {}) as Dictionary
	_check(
		int(cold_open.get("budget_seconds", 0)) == 30
		and int((cold_open.get("measurement", {}) as Dictionary).get("budget_seconds", 0)) == 30
		and bool((cold_open.get("measurement", {}) as Dictionary).get("complete", false))
		and int(cause.get("beat_count", 0)) == 3
		and (cause.get("applies_to", []) as Array) == ["ROUTE", "PLAYBOOK", "INTERVENTION", "REWARD"],
		"the first payoff and universal causal trail should be bounded and measurable",
		failures,
	)
	_check(
		int((layer.get("chicken_identities", {}) as Dictionary).get("count", 0)) == 2
		and int((layer.get("flock_pairings", {}) as Dictionary).get("count", 0)) == 1
		and int((layer.get("environment_interactions", {}) as Dictionary).get("hotspots", []).size()) == 6
		and int((layer.get("case_constellations", {}) as Dictionary).get("count", 0)) == 12
		and int((layer.get("management_build", {}) as Dictionary).get("slot_count", 0)) == 3,
		"identities, pairings, hotspots, case constellations, and build slots should stay compact and complete",
		failures,
	)
	var comprehension := layer.get("comprehension", {}) as Dictionary
	_check(
		bool(comprehension.get("real_participants_required", false))
		and int(comprehension.get("minimum_participants", 0)) == 5
		and not bool(comprehension.get("results_complete", true))
		and bool(comprehension.get("results_never_fabricated", false)),
		"the implementation must package the study without fabricating participant evidence",
		failures,
	)
	if not failures.is_empty():
		for failure in failures:
			push_error("CONSOLIDATED_GAME_LOOP_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CONSOLIDATED_GAME_LOOP_TEST_PASSED items=16 cold-open=30s cause=3 identities=2 pairs=1 hotspots=6 cases=12 build=3 evidence=awaiting-humans")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
