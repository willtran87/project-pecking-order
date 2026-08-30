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
			"minute_of_day": 790,
			"eggs_today": 4,
			"quota_target": 7,
			"quality_streak": 2,
			"workers": [
				{"id": 7, "name": "Mabel", "employed": true, "specialty": "appeals", "temperament": "careful", "hen_intent": {"label": "PROTECT THE CLEAN CARTON", "action_label": "ROUTE APPEAL"}, "personal_mastery": {"completed": 2, "total": 3}},
				{"id": 8, "name": "Dot", "employed": true, "specialty": "predator_loss", "temperament": "bold"},
			],
		},
		"next_action": {"action_id": "route", "copy": "ROUTE THE APPEAL", "visible_label": "ROUTE APPEAL", "actionable": true},
		"action_feedback": {"visible": true, "title": "SAFE ROUTE", "entries": [{"copy": "SHELL RISK -4%", "detail": "Specialty fit reduced shell risk."}]},
		"momentum_brief": {"status": "steady", "headline": "FLOCK IN FLOW", "short_label": "BEST FIT"},
		"first_session_funnel": {"milestones": [], "privacy": "LOCAL SESSION ONLY"},
		"focused_worker_id": 7,
		"active_playbook": {
			"authoritative": true,
			"strategy_preset_id": "safe",
			"dominant_objective": {"single": true, "label": "ROUTE THE APPEAL"},
			"prediction_score": {"verdict": "ON PLAN", "predicted": 3, "actual": 2},
			"push_luck": {"id": "double_carton", "open": true},
			"side_goal": {"id": "mabel_clean", "label": "MABEL'S CLEAN FILE", "progress": 1, "target": 2},
			"hen_proposal": {"worker_id": 7, "id": "slow_and_safe", "optional": true},
			"display_sockets": [{"id": "plan"}, {"id": "contract"}, {"id": "reward"}],
			"personal_best": {"routing": {"best": 5}},
			"challenge_modifier": {"optional": true, "detail": "RUSH FILES ARRIVE EARLY"},
			"next_shift_preview": {"one_more_shift": true, "label": "THE LATE CARTON"},
			"combo_recipe": {"label": "SHELL SEAL", "completed_steps": 1, "total_steps": 2},
			"strategy_mastery": {"label": "SAFE HANDS", "completed": 2, "transformative_at": 3},
			"career_story": {"worker_id": 7, "beat": 2, "total_beats": 3},
			"shift_journey": [
				{"id": "plan", "label": "PLAN", "state": "complete"},
				{"id": "work", "label": "WORK", "state": "current"},
				{"id": "respond", "label": "RESPOND", "state": "upcoming"},
				{"id": "reward", "label": "REWARD", "state": "upcoming"},
			],
		},
	})
	var layer := pulse.get("compelling_loop", {}) as Dictionary
	_check(
		int(pulse.get("version", 0)) == 14
		and int(layer.get("item_count", 0)) == 30
		and int(layer.get("resolved_count", 0)) == 30
		and bool(layer.get("all_resolved", false))
		and not bool(layer.get("authoritative", true)),
		"the compelling loop should resolve all thirty findings without owning state",
		failures,
	)
	var first_win := layer.get("first_minute_win", {}) as Dictionary
	var before_after := layer.get("before_after_preview", {}) as Dictionary
	var impact := layer.get("action_impact", {}) as Dictionary
	_check(
		int(first_win.get("budget_seconds", 0)) == 30
		and (first_win.get("sequence", []) as Array).size() == 4
		and before_after.has("before")
		and before_after.has("after")
		and bool(before_after.get("files_nothing", false))
		and int(impact.get("channel_count", 0)) == 3,
		"the opening win, safe preview, and world/character/interface impact should be explicit",
		failures,
	)
	var roster := layer.get("roster_strategy", {}) as Dictionary
	var combo := layer.get("combo_discovery", {}) as Dictionary
	_check(
		int(roster.get("worker_count", 0)) == 2
		and int(roster.get("coverage_count", 0)) == 2
		and int(combo.get("progress", 0)) == 1
		and int(combo.get("target", 0)) == 2
		and String(combo.get("compact", "")) == "COMBO 1/2",
		"roster coverage and the next combo step should be understandable at a glance",
		failures,
	)
	var density := layer.get("information_density", {}) as Dictionary
	var grammar := layer.get("semantic_grammar", {}) as Dictionary
	var audio := layer.get("audio_grammar", {}) as Dictionary
	var comprehension := layer.get("comprehension", {}) as Dictionary
	_check(
		int(density.get("compact_fields", 0)) == 4
		and bool(grammar.get("color_is_never_the_only_signal", false))
		and (audio.get("families", {}) as Dictionary).size() == 5
		and bool(comprehension.get("real_participants_required", false))
		and bool(comprehension.get("results_never_fabricated", false)),
		"professional density, semantic feedback, audio, and honest playtesting contracts should remain complete",
		failures,
	)
	if not failures.is_empty():
		for failure in failures:
			push_error("COMPELLING_GAME_LOOP_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("COMPELLING_GAME_LOOP_TEST_PASSED items=30 first_win=30 impact=3 roster=2 combo=1/2 audio=5")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
