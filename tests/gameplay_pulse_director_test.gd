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
			"routing_momentum": {"chain": 2},
			"active_directive": {"short_name": "ASSURANCE", "icon": "shield", "description": "Keep shells clean."},
			"pending_decision": {"options": [{"id": "care"}, {"id": "pace"}]},
			"workers": [{
				"id": 7,
				"name": "Mabel",
				"employed": true,
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
		"focus_mode", "action_preview", "core_loop", "immediate_outcome", "shift_win",
		"review_highlights", "comeback_guidance", "combo_readiness", "hen_intention",
		"relationship_episode", "tangible_reward_choice", "rival_pulse", "golden_moment",
		"quick_docket", "hen_mastery", "fail_forward", "voluntary_streak",
		"adaptive_assistance", "celebration_hierarchy", "comprehension_tuning",
	]
	for key in required:
		_check(pulse.has(key), "the clarity coordinator should publish %s" % key, failures)
	var core_loop := pulse.get("core_loop", {}) as Dictionary
	var steps := core_loop.get("steps", []) as Array
	_check(steps.size() == 4 and String(core_loop.get("active_stage", "")) == "hen", "the permanent loop should translate peckwork into the hen stage", failures)
	_check(String((steps[0] as Dictionary).get("state", "")) == "complete" and String((steps[1] as Dictionary).get("state", "")) == "current", "loop progress should mark prior and current stages correctly", failures)
	_check(String((pulse.get("action_preview", {}) as Dictionary).get("compact", "")) == "FILE → HEN", "the current action should retain one icon-first consequence preview", failures)
	_check(String((pulse.get("combo_readiness", {}) as Dictionary).get("compact", "")) == "2/3 COMBO ARMED", "routing momentum should disclose the next combo threshold", failures)
	_check(bool((pulse.get("relationship_episode", {}) as Dictionary).get("available", false)), "a strong named bond should surface one relationship episode", failures)
	_check(String((pulse.get("rival_pulse", {}) as Dictionary).get("compact", "")) == "RIVAL -3", "the rival pulse should expose the exact disclosed margin", failures)
	_check(int((pulse.get("hen_mastery", {}) as Dictionary).get("completed", 0)) == 2, "the focused hen should carry her personal mastery arc", failures)
	_check(String(((pulse.get("fail_forward", {}) as Dictionary).get("recovery_stamp", {}) as Dictionary).get("label", "")) == "LESSON FILED", "a setback should retain its earned recovery stamp", failures)
	_check(int((pulse.get("voluntary_streak", {}) as Dictionary).get("loss_penalty", -1)) == 0, "voluntary streaks should never remove banked progress", failures)
	_check(not bool((pulse.get("adaptive_assistance", {}) as Dictionary).get("changes_difficulty", true)), "adaptive route help should remain opt-in and difficulty-neutral", failures)
	_check(String((pulse.get("celebration_hierarchy", {}) as Dictionary).get("tier", "")) == "milestone", "a golden delivery should reserve the strongest celebration tier", failures)
	_check((pulse.get("comprehension_tuning", {}) as Dictionary).get("friction_flags", []) == ["repeated_route_miss"], "local friction signals should reach the diagnostic pulse without authority", failures)
	_check(not bool(pulse.get("authoritative", true)), "the entire pulse must remain presentation-only", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("GAMEPLAY_PULSE_DIRECTOR_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("GAMEPLAY_PULSE_DIRECTOR_TEST_PASSED items=20 authority=presentation-only loop=4-stage rival=disclosed mastery=3-stage recovery=fail-forward")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
