extends SceneTree

const CompletionScript := preload("res://core/experience/professional_gameplay_completion.gd")


func _init() -> void:
	var failures: Array[String] = []
	var layer := CompletionScript.compose({
		"simulation": {
			"day": 3,
			"shift_phase": 1,
			"eggs_today": 2,
			"quota_target": 8,
			"workers": [{
				"id": 0,
				"name": "Mabel",
				"specialty": "appeals",
				"current_claim": {},
			}],
		},
		"next_action": {"actionable": true, "action_id": "route", "visible_label": "ROUTE A FILE", "world_target": "routing_trays"},
		"active_playbook": {
			"teamwork": {
				"available": true,
				"used": false,
				"ability": {"id": "mentor_handoff", "label": "MENTOR HANDOFF"},
			},
			"mastery_automation": {
				"policy_unlocked": true,
				"policy_id": "deadline_first",
				"policy": {"id": "deadline_first", "label": "DEADLINE FIRST"},
				"rules": [
					{"id": "specialty_first"},
					{"id": "deadline_first"},
					{"id": "protect_strain"},
				],
			},
			"strategy_comparison": {
				"reversible_preview": true,
				"changes_authority": false,
				"plans": [
					{"id": "fast", "label": "FAST PLAN"},
					{"id": "safe", "label": "SAFE PLAN"},
					{"id": "flock", "label": "FLOCK PLAN"},
				],
			},
			"hen_proposal": {"available": true, "choice_id": "own_lane"},
			"contextual_rescue": {"available": true, "choice_id": "show_me"},
			"contract": {"complete": true, "progress": 3, "target": 3},
			"next_shift_preview": {"label": "THE GOLDEN RUSH"},
			"comprehension_study": {"instrumented_events": ["plan_selected", "first_route"]},
		},
		"routing_lifecycle": {"active_dispatch_lane": ""},
		"rival": {"name": "Fox & Finch", "intent": "RUSH QUALITY"},
		"chapter": {"id": "scrutiny", "label": "SCRUTINY"},
		"tactical_route_plan": {"capacity": 3, "commit_on_resume": true},
		"consolidated_game_loop": {
			"unified_cue": {"reward": "CREDIT"},
			"reward_cadence": {"shift": {"label": "SHIFT TROPHY"}},
		},
		"action_feedback": {"title": "BEST FIT", "value": "+12"},
		"focused_worker_id": 0,
	})
	var items := layer.get("items", []) as Array
	var ids: Array[String] = []
	for value in items:
		if value is Dictionary:
			ids.append(String((value as Dictionary).get("id", "")))
	_check(
		int(layer.get("version", 0)) == 1
		and bool(layer.get("canonical", false))
		and not bool(layer.get("authoritative", true))
		and int(layer.get("item_count", 0)) == 23
		and int(layer.get("implemented_count", 0)) == 23
		and bool(layer.get("all_implemented", false))
		and ids.size() == 23
		and ids.duplicate().all(func(item_id): return ids.count(item_id) == 1),
		"the professional completion projection should cover the exact twenty-three-item brief once",
		failures,
	)
	var attention := layer.get("attention_choreography", {}) as Dictionary
	var controls := layer.get("controls", {}) as Dictionary
	var interaction := layer.get("interaction_chain", {}) as Dictionary
	_check(
		String(attention.get("focus_id", "")) == "pickup_file"
		and String(attention.get("primary", "")) == "PICK A FILE"
		and not bool(attention.get("route_choices_visible", true))
		and bool(attention.get("invalid_choices_hidden", false))
		and (interaction.get("steps", []) as Array) == ["SELECT", "PREVIEW", "COMMIT", "LAND"]
		and int(controls.get("required_shortcut_count", -1)) == 0,
		"phase focus should expose one physical pointer-first action without unusable choices or required shortcuts",
		failures,
	)
	var delegation := layer.get("delegation", {}) as Dictionary
	var pair := layer.get("pair_ability", {}) as Dictionary
	var planning := layer.get("what_if_planning", {}) as Dictionary
	_check(
		bool(delegation.get("persistent_per_hen", false))
		and String(delegation.get("current_id", "")) == "deadline_first"
		and (delegation.get("policies", []) as Array).size() == 3
		and String((pair.get("ability", {}) as Dictionary).get("id", "")) == "mentor_handoff"
		and (pair.get("distinct_outcomes", []) as Array).size() == 4
		and bool(planning.get("reversible", false))
		and not bool(planning.get("changes_authority", true))
		and (planning.get("comparison", []) as Array).size() == 3,
		"delegation, pair abilities, and what-if planning should expose their complete authored rule sets",
		failures,
	)
	var rival := layer.get("rival_race", {}) as Dictionary
	var mastery := layer.get("mastery_variety", {}) as Dictionary
	var study := layer.get("comprehension_validation", {}) as Dictionary
	var thresholds := study.get("thresholds", {}) as Dictionary
	_check(
		(layer.get("hero_case_catalog", []) as Array).size() == 8
		and bool(rival.get("active", false))
		and (rival.get("responses", []) as Array).size() == 3
		and (mastery.get("challenges", []) as Array).size() == 6
		and bool(mastery.get("no_fomo", false))
		and int(study.get("participants_required", 0)) == 5
		and String(study.get("status", "")) == "AWAITING REAL PARTICIPANTS"
		and not bool(study.get("results_complete", true))
		and bool(study.get("never_fabricate", false))
		and int(thresholds.get("route_within_seconds", 0)) == 30
		and int(thresholds.get("required_shortcut_discovery", -1)) == 0,
		"authored cases, visible counterplay, mastery variety, and honest human-study thresholds should remain exact",
		failures,
	)
	if not failures.is_empty():
		for failure in failures:
			push_error("PROFESSIONAL_GAMEPLAY_COMPLETION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PROFESSIONAL_GAMEPLAY_COMPLETION_TEST_PASSED items=23 focus=phase-gated chain=4 policies=3 pair-outcomes=4 hero-cases=8 rivals=3 mastery=6 evidence=awaiting-humans")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
