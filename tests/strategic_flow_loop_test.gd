extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var pulse := GameplayPulseDirector.new().compose({
		"simulation": {
			"day": 4,
			"shift_phase": 1,
			"minute_of_day": 805,
			"eggs_today": 5,
			"quota_target": 8,
			"quality_streak": 3,
			"workers": [
				{"id": 7, "name": "Mabel", "employed": true, "specialty": "appeals", "temperament": "careful", "personal_mastery": {"completed": 2, "total": 3}},
				{"id": 8, "name": "Dot", "employed": true, "specialty": "predator_loss", "temperament": "bold"},
			],
		},
		"next_action": {"action_id": "route", "visible_label": "ROUTE APPEAL", "actionable": true},
		"action_feedback": {"visible": true, "title": "CLEAN HANDOFF", "entries": [{"detail": "Specialty fit protected the shell."}]},
		"momentum_brief": {"status": "recovering", "headline": "COMEBACK BUILDING", "short_label": "BEST FIT"},
		"first_session_funnel": {"privacy": "LOCAL SESSION ONLY"},
		"focused_worker_id": 7,
		"active_playbook": {
			"authoritative": true,
			"strategy_preset_id": "safe",
			"strategy_preset": {"label": "SAFE PLAN"},
			"loadout_id": "quality_floor",
			"preparation_id": "brace_shells",
			"prediction_score": {"verdict": "ON PLAN", "progress": 2, "target": 3},
			"combo_recipe": {"label": "SHELL SEAL", "completed_steps": 1, "total_steps": 2},
			"strategy_mastery": {"label": "SAFE HANDS", "completed": 2, "transformative_at": 3},
			"career_story": {"worker_id": 7, "beat": 2, "total_beats": 3},
			"challenge": {"code": "PECK-707", "seed": 707, "shareable": true},
			"challenge_modifier": {"label": "EARLY RUSH", "optional": true},
			"next_shift_preview": {"label": "THE LATE CARTON", "one_more_shift": true},
			"display_sockets": [{"id": "plan"}, {"id": "medal"}, {"id": "legacy"}],
			"opportunity_shapes": [{"id": "golden_file"}, {"id": "rival_offer"}],
			"shift_journey": [
				{"id": "plan", "label": "PLAN", "state": "complete"},
				{"id": "work", "label": "WORK", "state": "current"},
				{"id": "respond", "label": "RESPOND", "state": "upcoming"},
				{"id": "reward", "label": "REWARD", "state": "upcoming"},
			],
		},
	})
	var layer := pulse.get("strategic_flow_loop", {}) as Dictionary
	_check(
		int(pulse.get("version", 0)) == 17
		and int(layer.get("item_count", 0)) == 30
		and int(layer.get("resolved_count", 0)) == 30
		and bool(layer.get("all_resolved", false))
		and not bool(layer.get("authoritative", true)),
		"the strategic-flow layer should resolve all thirty items without owning gameplay state",
		failures,
	)
	var preview := layer.get("route_preview", {}) as Dictionary
	var bottleneck := layer.get("bottleneck", {}) as Dictionary
	var recommendation := layer.get("recommended_move", {}) as Dictionary
	_check(
		bool(preview.get("ghost_path", false))
		and bool(preview.get("files_nothing", false))
		and bool(bottleneck.get("world_highlight", false))
		and not bool(bottleneck.get("color_only", true))
		and bool(recommendation.get("one_tap", false))
		and String(recommendation.get("undo", "")) == "UNDO ROUTE",
		"route planning should preview consequences, expose a shaped bottleneck cue, and stay reversible",
		failures,
	)
	var roster := layer.get("roster_warning", {}) as Dictionary
	var loadouts := layer.get("saved_loadouts", {}) as Dictionary
	var handoff := layer.get("handoff", {}) as Dictionary
	_check(
		bool(roster.get("active", false))
		and (roster.get("gaps", []) as Array).has("NEST DAMAGE")
		and (loadouts.get("templates", []) as Array).size() == 3
		and bool(loadouts.get("one_click_atomic", false))
		and int(handoff.get("progress", 0)) == 1
		and int(handoff.get("target", 0)) == 2,
		"roster gaps, atomic flock loadouts, and the two-beat handoff should be glanceable",
		failures,
	)
	var preparation := layer.get("incident_preparation", {}) as Dictionary
	var challenge := layer.get("seeded_challenge", {}) as Dictionary
	var legacy := layer.get("career_legacy", {}) as Dictionary
	_check(
		String(preparation.get("selected", "")) == "brace_shells"
		and String(challenge.get("code", "")) == "PECK-707"
		and not bool(challenge.get("expires", true))
		and not bool(challenge.get("fomo", true))
		and bool(legacy.get("world_visible", false))
		and (legacy.get("display_sockets", []) as Array).size() == 3,
		"preparation, permanent seeded challenges, and career legacy should use their existing authorities",
		failures,
	)
	if not failures.is_empty():
		for failure in failures:
			push_error("STRATEGIC_FLOW_LOOP_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("STRATEGIC_FLOW_LOOP_TEST_PASSED items=30 preview=ghost bottleneck=shape loadouts=3 handoff=1/2 challenge=permanent")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
