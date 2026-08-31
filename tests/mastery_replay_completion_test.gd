extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var director := GameplayPulseDirector.new()
	var pulse := director.compose({
		"simulation": {
			"day": 4,
			"shift_phase": 1,
			"minute_of_day": 820,
			"eggs_today": 5,
			"quota_target": 8,
			"claims_processed": 4,
			"quality_streak": 3,
			"workers": [{
				"id": 0,
				"name": "Mabel",
				"employed": true,
				"hen_intent": {"label": "FINISH THE APPEAL", "urgency": 2},
				"personal_mastery": {"completed": 2, "total": 3, "next_label": "LEAD HEN"},
			}],
		},
		"next_action": {
			"action_id": "route",
			"copy": "ROUTE THE APPEAL",
			"visible_label": "ROUTE APPEAL",
			"actionable": true,
		},
		"routing_lifecycle": {},
		"action_feedback": {},
		"momentum_brief": {"status": "steady", "headline": "FLOCK IN FLOW"},
		"rival": {"name": "BARN EAST", "difference": 1, "standing": "ahead"},
		"first_session_funnel": {
			"privacy": "LOCAL SESSION ONLY / NEVER TRANSMITTED",
			"milestones": [],
		},
		"adaptive": {},
		"chapter": {},
		"order_pulse": {"on_track": 2, "total": 3},
		"focused_worker_id": 0,
		"active_playbook": {
			"authoritative": true,
			"day": 4,
			"strategy_preset_id": "safe",
			"strategy_preset": {"label": "SAFE PLAN", "gain": "SHELL RISK -4%", "cost": "PACE -3%", "risk": "SMALLER BUFFER"},
			"dominant_objective": {"single": true, "label": "ROUTE THE APPEAL", "ghost_path": ["FILE", "HEN", "RESULT"]},
			"contract": {"id": "clean_carton", "label": "CLEAN CARTON", "progress": 2, "target": 3, "complete": false},
			"combo": {"active": true, "progress": 2, "target": 3},
			"combo_recipe": {"label": "SHELL SEAL", "completed_steps": 1, "total_steps": 2, "effect": "SHELL RISK -1.5%"},
			"options": [{"kind": "signature", "label": "MABEL / SHARE CREDIT", "available": true, "gain": "TEAM MORALE", "cost": "ONE USE", "risk": "TIMING"}],
			"display_sockets": [{"id": "plan"}, {"id": "contract"}, {"id": "reward"}],
			"strategy_mastery": {"tier": "TAKING SHAPE", "marks": 2},
			"career_story": {"chapter": "THE LATE CARTON"},
			"relationship_echo": {"last_move": "TEAM LIFT"},
			"rare_episode": {"authored": true},
			"personal_best": {"routing": {"best": 5}, "quality": {"best": 4}},
			"challenge": {"code": "PECK-404", "seed": 404, "shareable": true},
			"challenge_modifier": {"optional": true, "skippable": true},
			"boss_file": {"active": false, "label": "FINAL HEARING", "mechanics": ["POLICY", "INCIDENT", "CREDIT"]},
			"next_shift_preview": {"one_more_shift": true, "label": "THE LATE CARTON"},
			"campaign_legacy_evidence": {},
			"shift_journey": [
				{"id": "plan", "label": "PLAN", "state": "complete"},
				{"id": "work", "label": "WORK", "state": "current"},
				{"id": "respond", "label": "RESPOND", "state": "upcoming"},
				{"id": "reward", "label": "REWARD", "state": "upcoming"},
			],
		},
	})
	var layer := pulse.get("mastery_replay", {}) as Dictionary
	var payoff := layer.get("payoff_clock", {}) as Dictionary
	var power := layer.get("manager_power", {}) as Dictionary
	var decision := layer.get("decision_stack", {}) as Dictionary
	var study := layer.get("comprehension_protocol", {}) as Dictionary
	_check(
		int(pulse.get("version", 0)) == 16
		and int(layer.get("item_count", 0)) == 30
		and int(layer.get("resolved_count", 0)) == 30
		and bool(layer.get("all_resolved", false)),
		"the mastery/replay contract should resolve all thirty findings",
		failures,
	)
	_check(
		String(power.get("input", "")) == "Q"
		and bool(power.get("ready", false))
		and bool(power.get("opens_playbook", false))
		and not bool(power.get("files_on_press", true)),
		"Q should expose a ready contextual power without filing a choice",
		failures,
	)
	_check(
		int(payoff.get("actions_remaining", -1)) == 1
		and int(decision.get("maximum_major_choices", 0)) == 1
		and bool(decision.get("unrelated_actions_folded", false))
		and String((layer.get("progressive_reveal", {}) as Dictionary).get("tier", "")) == "MASTERY",
		"the live layer should show one decision, one-step payoff anticipation, and mastered-system reveal",
		failures,
	)
	_check(
		bool(study.get("local_instrumentation", false))
		and bool(study.get("real_participants_required", false))
		and not bool(study.get("fabricated_results", true))
		and int((layer.get("unlock_ladder", {}) as Dictionary).get("step_count", 0)) == 3
		and bool((layer.get("campaign_finale", {}) as Dictionary).get("decisive", false)),
		"usability evidence should stay honest while the unlock ladder and finale remain explicit",
		failures,
	)
	if not failures.is_empty():
		for failure in failures:
			push_error("MASTERY_REPLAY_COMPLETION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MASTERY_REPLAY_COMPLETION_TEST_PASSED items=30 reveal=progressive decision=one payoff=countdown power=Q replay=same-seed finale=decisive")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
