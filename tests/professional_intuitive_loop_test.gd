extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var director := GameplayPulseDirector.new()
	var pulse := director.compose({
		"simulation": {
			"day": 3,
			"shift_phase": 1,
			"minute_of_day": 760,
			"eggs_today": 4,
			"quota_target": 7,
			"quality_streak": 2,
			"active_directive": {"id": "worker_voice", "short_name": "FLOCK PLAN"},
			"workers": [{
				"id": 7,
				"name": "Mabel",
				"employed": true,
				"hen_intent": {"label": "PROTECT THE CLEAN CARTON"},
			}],
		},
		"next_action": {
			"action_id": "route",
			"copy": "ROUTE THE APPEAL",
			"visible_label": "ROUTE APPEAL",
			"actionable": true,
		},
		"action_feedback": {
			"visible": true,
			"entries": [{"copy": "+1 FILE"}],
		},
		"momentum_brief": {"status": "steady", "headline": "FLOCK IN FLOW"},
		"first_session_funnel": {"milestones": [], "privacy": "LOCAL SESSION ONLY"},
		"focused_worker_id": 7,
		"active_playbook": {
			"authoritative": true,
			"strategy_preset_id": "flock",
			"recommended_preset_id": "flock",
			"strategy_preset": {"gain": "MORALE +4", "cost": "PACE -2%", "risk": "TIGHTER MARGIN"},
			"dominant_objective": {"single": true, "label": "ROUTE THE APPEAL", "ghost_path": ["FILE", "HEN", "RESULT"]},
			"contract": {"label": "CLEAN CARTON", "progress": 2, "target": 3},
			"combo_recipe": {"label": "SHELL SEAL", "completed_steps": 1, "total_steps": 2},
			"options": [
				{"kind": "signature", "label": "MABEL / SHARE CREDIT", "available": true},
				{"kind": "reward", "label": "BREAKROOM UPGRADE", "available": true},
				{"kind": "reward", "label": "SORTER RHYTHM", "available": true},
				{"kind": "reward", "label": "FLOCK CREST", "available": true},
			],
			"shift_journey": [
				{"id": "plan", "label": "PLAN", "state": "complete"},
				{"id": "work", "label": "WORK", "state": "current"},
				{"id": "respond", "label": "RESPOND", "state": "upcoming"},
				{"id": "reward", "label": "REWARD", "state": "upcoming"},
			],
		},
	})
	var layer := pulse.get("professional_loop", {}) as Dictionary
	var icon_strip := layer.get("consequence_icons", {}) as Dictionary
	var journey := layer.get("production_journey", {}) as Dictionary
	var focus := layer.get("attention_focus", {}) as Dictionary
	var replay := layer.get("highlight_replay", {}) as Dictionary
	var rematch := layer.get("rematch_variation", {}) as Dictionary
	var study := layer.get("comprehension_protocol", {}) as Dictionary
	_check(
		int(pulse.get("version", 0)) == 7
		and int(layer.get("item_count", 0)) == 20
		and int(layer.get("resolved_count", 0)) == 20
		and bool(layer.get("all_resolved", false)),
		"the professional loop should resolve all twenty presentation findings",
		failures,
	)
	_check(
		int(icon_strip.get("icon_count", 0)) == 3
		and (icon_strip.get("icons", []) as Array).size() == 3
		and bool(icon_strip.get("does_not_rely_on_color", false))
		and (journey.get("steps", []) as Array).size() == 5,
		"benefit, cost, and risk should be three shaped icons beside a five-stage physical journey",
		failures,
	)
	_check(
		String(focus.get("primary_action_id", "")) == "route"
		and bool((layer.get("world_route", {}) as Dictionary).get("dossier_on_demand", false))
		and String((layer.get("contextual_power", {}) as Dictionary).get("label", "")) == "MABEL / SHARE CREDIT",
		"one world-first route and the exact contextual signature should own attention",
		failures,
	)
	_check(
		int(replay.get("duration_seconds", 0)) == 10
		and (replay.get("beats", []) as Array).size() == 3
		and bool(rematch.get("same_seed", false))
		and int(rematch.get("rule_change_count", 0)) == 1
		and bool(rematch.get("one_click", false)),
		"the recap should be ten seconds and the rematch should change exactly one rule",
		failures,
	)
	_check(
		bool(study.get("local_instrumentation", false))
		and bool(study.get("real_participants_required", false))
		and not bool(study.get("fabricated_results", true))
		and (study.get("tasks", []) as Array).size() == 4,
		"the comprehension protocol must require real participants and never fabricate evidence",
		failures,
	)
	if not failures.is_empty():
		for failure in failures:
			push_error("PROFESSIONAL_INTUITIVE_LOOP_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PROFESSIONAL_INTUITIVE_LOOP_TEST_PASSED items=20 icons=3 journey=5 focus=single replay=10s rematch=one-rule study=honest")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
