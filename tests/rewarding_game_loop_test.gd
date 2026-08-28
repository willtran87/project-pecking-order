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
			"workers": [{
				"id": 7,
				"name": "Mabel",
				"employed": true,
				"specialty": "appeals",
				"hen_intent": {
					"label": "PROTECT THE CLEAN CARTON",
					"action_label": "ROUTE APPEAL",
				},
				"personal_mastery": {"completed": 2, "total": 3},
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
			"title": "SAFE ROUTE",
			"entries": [{"copy": "SHELL RISK -4%", "detail": "Specialty fit reduced shell risk."}],
		},
		"momentum_brief": {"status": "steady", "headline": "FLOCK IN FLOW"},
		"first_session_funnel": {"milestones": [], "privacy": "LOCAL SESSION ONLY"},
		"focused_worker_id": 7,
		"active_playbook": {
			"authoritative": true,
			"strategy_preset_id": "safe",
			"recommended_preset_id": "safe",
			"dominant_objective": {"single": true, "label": "ROUTE THE APPEAL"},
			"contract": {"id": "clean_carton", "label": "CLEAN CARTON", "progress": 2, "target": 3},
			"prediction_score": {"verdict": "ON PLAN", "predicted": 3, "actual": 2},
			"push_luck": {"id": "double_carton", "open": true},
			"side_goal": {"id": "mabel_clean", "label": "MABEL'S CLEAN FILE", "progress": 1, "target": 2},
			"hen_proposal": {"worker_id": 7, "id": "slow_and_safe", "optional": true},
			"display_sockets": [{"id": "plan"}, {"id": "contract"}, {"id": "reward"}],
			"personal_best": {"routing": {"best": 5}},
			"challenge": {"code": "PECK-707", "shareable": true},
			"next_shift_preview": {"one_more_shift": true, "label": "THE LATE CARTON"},
			"combo_recipe": {"label": "SHELL SEAL", "completed_steps": 1, "total_steps": 2},
			"options": [
				{"kind": "signature", "label": "MABEL / SHARE CREDIT", "available": true},
				{"kind": "reward", "label": "BREAKROOM UPGRADE", "available": true},
			],
			"shift_journey": [
				{"id": "plan", "label": "PLAN", "state": "complete"},
				{"id": "work", "label": "WORK", "state": "current"},
				{"id": "respond", "label": "RESPOND", "state": "upcoming"},
				{"id": "reward", "label": "REWARD", "state": "upcoming"},
			],
		},
	})
	var layer := pulse.get("rewarding_loop", {}) as Dictionary
	var brief := layer.get("shift_brief", {}) as Dictionary
	var dossier := layer.get("compact_dossier", {}) as Dictionary
	var cadence := layer.get("decision_cadence", {}) as Dictionary
	var why := layer.get("result_why", {}) as Dictionary
	_check(
		int(pulse.get("version", 0)) == 10
		and int(layer.get("item_count", 0)) == 25
		and int(layer.get("resolved_count", 0)) == 25
		and bool(layer.get("all_resolved", false)),
		"the rewarding loop should resolve all twenty-five findings",
		failures,
	)
	var cards := brief.get("cards", []) as Array
	_check(
		bool(brief.get("one_screen", false))
		and cards.size() == 3
		and String((cards[0] as Dictionary).get("id", "")) == "goal"
		and String((cards[1] as Dictionary).get("id", "")) == "danger"
		and String((cards[2] as Dictionary).get("id", "")) == "reward",
		"the shift brief should communicate goal, danger, and reward in one glance",
		failures,
	)
	_check(
		int(dossier.get("field_count", 0)) == 4
		and (dossier.get("fields", []) as Array).size() == 4
		and not bool(dossier.get("default_expanded", true))
		and bool(dossier.get("details_on_demand", false)),
		"the selected-hen card should default to four fields with details on demand",
		failures,
	)
	_check(
		int(cadence.get("minimum_seconds", 0)) == 20
		and int(cadence.get("maximum_seconds", 0)) == 30
		and bool(cadence.get("one_meaningful_decision", false))
		and bool(why.get("visible", false))
		and String(why.get("compact", "")).contains("SAFE ROUTE")
		and String(why.get("compact", "")).contains("Specialty fit reduced shell risk."),
		"decisions should land on a readable cadence and explain why their result happened",
		failures,
	)
	_check(
		(layer.get("work_pipeline", {}) as Dictionary).get("steps", []).size() == 5
		and bool((layer.get("physical_routing", {}) as Dictionary).get("world_first", false))
		and int((layer.get("shift_recap", {}) as Dictionary).get("duration_seconds", 0)) == 10
		and bool((layer.get("varied_rematch", {}) as Dictionary).get("one_click", false))
		and bool((layer.get("comprehension", {}) as Dictionary).get("real_participants_required", false)),
		"the physical pipeline, recap, rematch, and honest comprehension protocol should remain complete",
		failures,
	)
	if not failures.is_empty():
		for failure in failures:
			push_error("REWARDING_GAME_LOOP_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("REWARDING_GAME_LOOP_TEST_PASSED items=25 brief=3 dossier=4 cadence=20-30 why=cause-effect")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
