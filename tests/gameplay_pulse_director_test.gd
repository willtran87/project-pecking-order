extends SceneTree

const DirectorScript := preload("res://core/experience/gameplay_pulse_director.gd")


func _init() -> void:
	var failures: Array[String] = []
	var director := DirectorScript.new() as GameplayPulseDirector
	var pulse := director.compose({
		"simulation": {
			"day": 2,
			"shift_phase": 1,
			"eggs_today": 4,
			"quality_streak": 3,
			"routing_momentum": {"chain": 2, "next_milestone": 3, "next_reward": "PACE +15%"},
			"active_directive": {"id": "shell_assurance", "short_name": "ASSURANCE", "icon": "shield", "description": "Keep shells clean."},
			"pending_decision": {"options": [{"id": "care"}, {"id": "pace"}]},
			"personnel_action_available": true,
			"personnel_action_status": {"available": true, "remaining": 1},
			"personnel_catalog": [{"id": "share_credit", "short_name": "SHARE CREDIT"}],
			"packing_contract": {"enabled": true, "carton_progress": 3},
			"owned_facilities": {"breakroom": 1},
			"workers": [{
				"id": 7,
				"name": "Mabel",
				"employed": true,
				"preferred_personnel_action": "share_credit",
				"shift_golden": 1,
				"hen_intent": {"id": "peck", "urgency": 4, "detail": "Ready to peck."},
				"flock_bond": {"partner_id": 8, "partner_name": "Dot", "score": 79, "label": "TRUSTED", "summary": "The pair has momentum."},
				"personal_mastery": {"worker_id": 7, "completed": 2, "total": 3, "next_label": "LEAD HEN"},
			}],
		},
		"next_action": {"action_id": "route", "visible_label": "ROUTE FILE", "actionable": true, "activation_behavior": "focus_target", "accessible_text": "Choose one fitted hen."},
		"routing_lifecycle": {"active_stage": "peck"},
		"action_feedback": {"visible": false, "entries": []},
		"momentum_brief": {"status": "comeback", "headline": "COMEBACK FILE", "short_label": "WELFARE NEEDS RECOVERY", "detail": "Recover welfare.", "action_id": "comeback_file", "take_me_there": true, "recovery_stamp": {"label": "LESSON FILED", "earned": true}},
		"rival": {"name": "Golden Comb", "difference": -3, "standing": "behind"},
		"chapter": {"title": "RANKING DAY", "promise": "Protect the flock record."},
		"first_session_funnel": {"privacy": "LOCAL SESSION ONLY / NEVER TRANSMITTED", "next_id": "first_egg", "reached_count": 6, "total_count": 9, "signals": {"route_miss": 2}, "friction_flags": ["repeated_route_miss"]},
		"adaptive": {"active": true, "miss_streak": 2},
		"order_pulse": {"on_track": 2, "total": 3},
		"focused_worker_id": 7,
	})
	var required := [
		"focus_mode", "action_preview", "core_loop", "shift_journey", "guided_loop", "physical_loop", "immediate_outcome", "shift_win",
		"review_highlights", "comeback_guidance", "combo_readiness", "hen_intention",
		"relationship_episode", "tangible_reward_choice", "rival_pulse", "golden_moment",
		"quick_docket", "hen_mastery", "fail_forward", "voluntary_streak",
		"adaptive_assistance", "celebration_hierarchy", "comprehension_tuning",
		"intuitive_rewarding_completion",
	]
	for key in required:
		_check(pulse.has(key), "the clarity coordinator should publish %s" % key, failures)
	var core_loop := pulse.get("core_loop", {}) as Dictionary
	var steps := core_loop.get("steps", []) as Array
	_check(steps.size() == 4 and String(core_loop.get("active_stage", "")) == "hen", "the permanent loop should translate peckwork into the hen stage", failures)
	_check(String((steps[0] as Dictionary).get("state", "")) == "complete" and String((steps[1] as Dictionary).get("state", "")) == "current", "loop progress should mark prior and current stages correctly", failures)
	_check(String((pulse.get("action_preview", {}) as Dictionary).get("compact", "")) == "FILE → HEN", "the current action should retain one icon-first consequence preview", failures)
	var shift_journey := pulse.get("shift_journey", {}) as Dictionary
	_check(
		String(shift_journey.get("compact", "")) == "PLAN → WORK → RESPOND → REWARD"
		and (shift_journey.get("steps", []) as Array).size() == 4
		and String(shift_journey.get("active_stage", "")) == "respond",
		"the visible shift journey should identify the current response stage without replacing the production-chain diagnostic",
		failures,
	)
	var guided_loop := pulse.get("guided_loop", {}) as Dictionary
	_check(
		int(guided_loop.get("item_count", 0)) == 24
		and (guided_loop.get("core_vocabulary", {}) as Dictionary).get("verbs", []) == ["INSPECT", "ROUTE", "HELP", "PECK", "INVEST"]
		and bool((guided_loop.get("one_action_one_target", {}) as Dictionary).get("world_outline", false))
		and int((guided_loop.get("daily_content_budget", {}) as Dictionary).get("major", 0)) == 1,
		"the guided loop should consolidate all twenty-four improvements around five verbs, one world target, and a bounded daily choice budget",
		failures,
	)
	var physical_loop := pulse.get("physical_loop", {}) as Dictionary
	var physical_items := physical_loop.get("items", {}) as Dictionary
	_check(
		int(physical_loop.get("item_count", 0)) == 24
		and int(physical_loop.get("resolved_count", 0)) == 24
		and bool(physical_loop.get("all_resolved", false))
		and physical_items.has("quick_start")
		and physical_items.has("direct_world_routing")
		and physical_items.has("next_shift_preview"),
		"the physical loop contract should resolve all twenty-four audited enhancements to real game surfaces",
		failures,
	)
	_check(
		PeckworkRoutingUI._peck_rating_label(&"steady") == "GOOD"
		and PeckworkRoutingUI._peck_rating_label(&"strong") == "GREAT"
		and PeckworkRoutingUI._peck_rating_label(&"perfect") == "PERFECT"
		and PeckworkRoutingUI._peck_rating_label(&"scramble") == "LATE",
		"Priority Peck should present a readable Good, Great, Perfect skill ladder while preserving stable receipt IDs",
		failures,
	)
	_check(String((pulse.get("combo_readiness", {}) as Dictionary).get("compact", "")) == "2/3 COMBO ARMED", "routing momentum should disclose the next combo threshold", failures)
	_check(bool((pulse.get("relationship_episode", {}) as Dictionary).get("available", false)), "a strong named bond should surface one relationship episode", failures)
	_check(String((pulse.get("rival_pulse", {}) as Dictionary).get("compact", "")) == "RIVAL -3", "the rival pulse should expose the exact disclosed margin", failures)
	_check(int((pulse.get("hen_mastery", {}) as Dictionary).get("completed", 0)) == 2, "the focused hen should carry her personal mastery arc", failures)
	_check(String(((pulse.get("fail_forward", {}) as Dictionary).get("recovery_stamp", {}) as Dictionary).get("label", "")) == "LESSON FILED", "a setback should retain its earned recovery stamp", failures)
	_check(int((pulse.get("voluntary_streak", {}) as Dictionary).get("loss_penalty", -1)) == 0, "voluntary streaks should never remove banked progress", failures)
	_check(not bool((pulse.get("adaptive_assistance", {}) as Dictionary).get("changes_difficulty", true)), "adaptive route help should remain opt-in and difficulty-neutral", failures)
	_check(String((pulse.get("celebration_hierarchy", {}) as Dictionary).get("tier", "")) == "milestone", "a golden delivery should reserve the strongest celebration tier", failures)
	var reward_loop := pulse.get("reward_loop", {}) as Dictionary
	var reward_items := [
		"signature_ability", "combo_recipe", "optional_shift_contract", "clutch_carton",
		"hen_promise", "rival_counterplay", "route_chain_plan", "near_miss_rescue",
		"furnishing_loadout", "future_reward_ghost", "three_beat_finale",
		"strategy_identity", "relationship_teamwork", "surprise_opportunity",
		"office_celebration",
	]
	_check(reward_loop.size() == 16 and not bool(reward_loop.get("authoritative", true)), "the reward loop should publish exactly fifteen presentation-only enhancements", failures)
	for item in reward_items:
		_check(reward_loop.has(item), "the reward loop should publish %s" % item, failures)
	_check(bool((reward_loop.get("signature_ability", {}) as Dictionary).get("ready", false)), "the focused hen's preferred check-in should surface as her ready signature move", failures)
	_check(String((reward_loop.get("combo_recipe", {}) as Dictionary).get("label", "")) == "SHELL LOCK", "Shell Assurance should name its fit-chain recipe", failures)
	_check(int((reward_loop.get("optional_shift_contract", {}) as Dictionary).get("failure_penalty", -1)) == 0, "the shift contract should remain optional and penalty-free", failures)
	_check((reward_loop.get("clutch_carton", {}) as Dictionary).get("thresholds", []) == [2, 4, 8], "the physical clutch track should disclose all three milestones", failures)
	_check(String((reward_loop.get("strategy_identity", {}) as Dictionary).get("label", "")) == "SHELL GUARDIAN", "the active policy should produce one legible strategy identity", failures)
	_check(((reward_loop.get("three_beat_finale", {}) as Dictionary).get("beats", []) as Array).size() == 3, "the shift finale should retain win, lesson, and next beats", failures)
	_check((pulse.get("comprehension_tuning", {}) as Dictionary).get("friction_flags", []) == ["repeated_route_miss"], "local friction signals should reach the diagnostic pulse without authority", failures)
	_check(not bool(pulse.get("authoritative", true)), "the entire pulse must remain presentation-only", failures)
	var completion := pulse.get("intuitive_rewarding_completion", {}) as Dictionary
	_check(
		int(pulse.get("version", 0)) == 20
		and int(completion.get("item_count", 0)) == 33
		and bool(completion.get("all_implemented", false))
		and String((completion.get("human_study", {}) as Dictionary).get("status", "")) == "AWAITING REAL PARTICIPANTS",
		"the director should publish the exact 33-item completion layer while keeping real human evidence pending",
		failures,
	)
	var active_pulse := director.compose({
		"simulation": {
			"day": 2,
			"shift_phase": 1,
			"quality_streak": 2,
			"routing_momentum": {"chain": 3, "next_milestone": 6},
			"active_directive": {"id": "shell_assurance"},
			"workers": [{"id": 0, "name": "Mabel", "employed": true}],
		},
		"focused_worker_id": 0,
		"active_playbook": {
			"authoritative": true,
			"strategy_preset_id": "safe",
			"strategy_preset": {"label": "SAFE PLAN", "gain": "SHELL RISK -4.3%", "cost": "PACE -4.9%", "risk": "LOWER OUTPUT"},
			"recommended_preset_id": "safe",
			"smart_default": {"id": "safe", "label": "SAFE PLAN", "one_click": true},
			"contract": {"id": "clean_pair", "label": "CLEAN PAIR", "progress": 2, "target": 2, "complete": true, "reward_claimed": false},
			"combo": {"id": "shell_lock", "label": "SHELL LOCK", "progress": 3, "target": 3, "active": true, "effect": "SHELL RISK -2%"},
			"loadout_id": "quality_floor",
			"options": [
				{"kind": "signature", "label": "MABEL / SHARE CREDIT", "icon": "flock", "available": true, "detail": "PROFILE-SPECIFIC EFFECT"},
				{"kind": "teamwork", "label": "TEAM LIFT", "icon": "sync", "available": true, "detail": "PAIR MORALE + ATTENTION"},
			],
			"opportunity_shapes": [{"id": "contract", "shape": "stamp", "active": true}],
			"shift_journey": [
				{"id": "plan", "label": "PLAN", "icon": "goal", "state": "complete"},
				{"id": "work", "label": "WORK", "icon": "route", "state": "complete"},
				{"id": "respond", "label": "RESPOND", "icon": "shield", "state": "complete"},
				{"id": "reward", "label": "REWARD", "icon": "egg", "state": "current"},
			],
		},
	})
	var active_reward_loop := active_pulse.get("reward_loop", {}) as Dictionary
	_check(
		bool(active_reward_loop.get("authoritative", false))
		and bool((active_reward_loop.get("future_reward_ghost", {}) as Dictionary).get("claimable", false))
		and bool((active_reward_loop.get("signature_ability", {}) as Dictionary).get("ready", false))
		and String((active_reward_loop.get("furnishing_loadout", {}) as Dictionary).get("label", "")) == "QUALITY FLOOR",
		"an active playbook should replace projections with the exact filed contract, combo, signature, and loadout authority",
		failures,
	)
	var active_guided := active_pulse.get("guided_loop", {}) as Dictionary
	_check(
		String(((active_guided.get("strategy_presets", {}) as Dictionary).get("selected", ""))) == "safe"
		and bool((active_guided.get("immediate_reward_draft", {}) as Dictionary).get("ready", false))
		and String((active_guided.get("compound_success", {}) as Dictionary).get("label", "")) == "2/3 PERFECT PLAY",
		"the active guided loop should project the filed preset, immediate reward draft, and compound-play progress from authority",
		failures,
	)

	if not failures.is_empty():
		for failure in failures:
			push_error("GAMEPLAY_PULSE_DIRECTOR_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("GAMEPLAY_PULSE_DIRECTOR_TEST_PASSED items=20 reward-loop=15 guided-loop=24 physical-loop=24 authority=playbook-aware journey=4-stage rival=disclosed mastery=3-stage recovery=fail-forward")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
