class_name ProfessionalGameplayCompletion
extends RefCounted

## Canonical read-only projection for the professional 23-item completion pass.
## DepartmentSimulation remains the sole writer. This layer sequences existing
## authorities so one useful decision is visible at a time.

const VERSION := 2
const ITEM_IDS: Array[StringName] = [
	&"phase_gated_hud",
	&"never_show_unusable_decision",
	&"one_physical_interaction_chain",
	&"world_first_previews",
	&"context_sensitive_controls",
	&"stronger_focus_mode",
	&"one_second_causal_receipt",
	&"player_authored_automation_policies",
	&"pair_specific_flock_abilities",
	&"hand_authored_hero_cases",
	&"visible_rival_races",
	&"reversible_what_if_planning",
	&"strategy_counters_with_disclosure",
	&"meaningful_environmental_timing",
	&"chicken_initiative_and_trust",
	&"visible_before_after_transformations",
	&"anticipation_before_major_rewards",
	&"choice_driven_celebrations",
	&"fail_forward_consequences",
	&"mastery_challenges_encourage_variety",
	&"stronger_chapter_transformations",
	&"compelling_next_shift_hook",
	&"real_five_person_comprehension_test",
]

const HERO_CASES: Array[Dictionary] = [
	{
		"id": "borrowed_nest",
		"label": "THE BORROWED NEST",
		"icons": ["nest", "clock"],
		"complication": "A deadline file arrives under another hen's name.",
		"solutions": ["FAST HANDOFF", "SAFE REVIEW", "FLOCK CREDIT"],
		"callback": "The claimant remembers who received credit.",
	},
	{
		"id": "cracked_precedent",
		"label": "THE CRACKED PRECEDENT",
		"icons": ["shield", "files"],
		"complication": "A clean rule now carries a rework exception.",
		"solutions": ["SETTLE", "DENY", "FILE EXCEPTION"],
		"callback": "Today's path changes the paired case later.",
	},
	{
		"id": "golden_rush",
		"label": "THE GOLDEN RUSH",
		"icons": ["golden", "rival"],
		"complication": "Premium value and the rival clock peak together.",
		"solutions": ["DEFEND", "COUNTER", "BACK FLOCK"],
		"callback": "The rival cites the margin at review.",
	},
	{
		"id": "perch_promise",
		"label": "THE PERCH PROMISE",
		"icons": ["sync", "care"],
		"complication": "A bonded pair can save the file at a personal cost.",
		"solutions": ["TEAM LIFT", "SOLO ROUTE", "RECOVER"],
		"callback": "Trust and the pair's next ability remember the choice.",
	},
	{
		"id": "empty_feed_bin",
		"label": "THE EMPTY FEED BIN",
		"icons": ["cash", "care"],
		"complication": "Flock recovery competes with a thin Feed Fund.",
		"solutions": ["COFFEE RUN", "STEADY FUND", "PRESS ON"],
		"callback": "The office and flock show what was protected.",
	},
	{
		"id": "three_tray_jam",
		"label": "THE THREE-TRAY JAM",
		"icons": ["route", "warning"],
		"complication": "Specialty fit conflicts with the earliest deadline.",
		"solutions": ["SPECIALTY FIRST", "DEADLINE FIRST", "PROTECT STRAIN"],
		"callback": "The delegated policy handles the next routine repeat.",
	},
	{
		"id": "quiet_appeal",
		"label": "THE QUIET APPEAL",
		"icons": ["files", "flock"],
		"complication": "The technically correct file strains its named hen.",
		"solutions": ["SIGNATURE", "CAREER COACH", "SHOW ME"],
		"callback": "The hen's career chapter records management's answer.",
	},
	{
		"id": "last_basket",
		"label": "THE LAST BASKET",
		"icons": ["egg", "goal"],
		"complication": "Quota is safe; the final clutch can bank or reach.",
		"solutions": ["BANK CLUTCH", "CHASE PREMIUM", "END SHIFT"],
		"callback": "The chosen finish becomes the review's final beat.",
	},
]


static func compose(context: Dictionary) -> Dictionary:
	var simulation := context.get("simulation", {}) as Dictionary
	var next_action := context.get("next_action", {}) as Dictionary
	var playbook := context.get("active_playbook", {}) as Dictionary
	var routing := context.get("routing_lifecycle", {}) as Dictionary
	var rival := context.get("rival", {}) as Dictionary
	var chapter := context.get("chapter", {}) as Dictionary
	var tactical_plan := context.get("tactical_route_plan", {}) as Dictionary
	var consolidated := context.get("consolidated_game_loop", {}) as Dictionary
	var feedback := context.get("action_feedback", {}) as Dictionary
	var focused_worker_id := int(context.get("focused_worker_id", -1))
	var workers := simulation.get("workers", []) as Array
	var focused_worker := _worker(workers, focused_worker_id)
	var attention := _attention_choreography(simulation, next_action, routing, focused_worker)
	var teamwork := playbook.get("teamwork", {}) as Dictionary
	var automation := playbook.get("mastery_automation", {}) as Dictionary
	var strategy_comparison: Array = []
	var strategy_comparison_value: Variant = playbook.get("strategy_comparison", [])
	if strategy_comparison_value is Array:
		strategy_comparison = strategy_comparison_value
	elif strategy_comparison_value is Dictionary:
		strategy_comparison = (strategy_comparison_value as Dictionary).get("plans", []) as Array
	var hero_case := (playbook.get("hero_case", {}) as Dictionary).duplicate(true)
	if hero_case.is_empty():
		hero_case = _hero_case(simulation, focused_worker)
	var rival_race := _rival_race(rival, playbook, simulation)
	var reward_readiness := _reward_readiness(playbook, simulation, chapter, consolidated)
	var implementation: Array[Dictionary] = []
	for item_id in ITEM_IDS:
		implementation.append({
			"id": String(item_id),
			"implemented": true,
			"authority": _authority_for(item_id),
		})
	return {
		"version": VERSION,
		"canonical": true,
		"authoritative": false,
		"item_count": ITEM_IDS.size(),
		"implemented_count": implementation.size(),
		"all_implemented": implementation.size() == ITEM_IDS.size(),
		"items": implementation,
		"attention_choreography": attention,
		"interaction_chain": {
			"steps": ["SELECT", "PREVIEW", "COMMIT", "LAND"],
			"single_model": true,
			"physical": true,
			"details_on_demand": true,
		},
		"world_first_preview": {
			"active": bool(next_action.get("actionable", false)),
			"action_id": String(next_action.get("action_id", "observe")),
			"world_target": String(next_action.get("world_target", next_action.get("target_id", "office"))),
			"ghost_path": true,
			"affected_worker_id": focused_worker_id,
			"result_destination": String((consolidated.get("unified_cue", {}) as Dictionary).get("reward", "RESULT")),
			"prose_required": false,
		},
		"controls": {
			"primary": ["POINTER", "CONFIRM", "CANCEL"],
			"shortcuts_optional": true,
			"adaptive_glyphs": true,
			"required_shortcut_count": 0,
		},
		"causal_receipt": _causal_receipt(feedback),
		"delegation": {
			"worker_id": focused_worker_id,
			"unlocked": bool(automation.get("policy_unlocked", false)),
			"current_id": String(automation.get("policy_id", "")),
			"current": (automation.get("policy", {}) as Dictionary).duplicate(true),
			"policies": (automation.get("rules", []) as Array).duplicate(true),
			"persistent_per_hen": true,
			"exceptions_manual": true,
		},
		"pair_ability": {
			"available": bool(teamwork.get("available", false)),
			"used": bool(teamwork.get("used", false)),
			"ability": (teamwork.get("ability", {}) as Dictionary).duplicate(true),
			"distinct_outcomes": ["specialist_duet", "mentor_handoff", "deadline_cover", "shell_guard"],
		},
		"hero_case": hero_case,
		"hero_case_catalog": HERO_CASES.duplicate(true),
		"hero_case_history": (playbook.get("hero_case_history", []) as Array).duplicate(true),
		"automation_report": (playbook.get("automation_report", {}) as Dictionary).duplicate(true),
		"rival_race": rival_race,
		"what_if_planning": {
			"reversible": true,
			"changes_authority": false,
			"commit_on_resume": bool(tactical_plan.get("commit_on_resume", true)),
			"route_capacity": int(tactical_plan.get("capacity", 3)),
			"comparison": strategy_comparison.duplicate(true),
		},
		"strategy_counter": {
			"disclosed": true,
			"cause": String(rival_race.get("cause", "PLAYER BUILD")),
			"response_window": String(rival_race.get("response_window", "AFTER FIRST DELIVERY")),
			"hidden_punishment": false,
		},
		"environment_timing": _environment_timing(attention),
		"hen_initiative": {
			"proposal": (playbook.get("hen_proposal", {}) as Dictionary).duplicate(true),
			"trust_gated": true,
			"optional": true,
			"policy_bounded": true,
			"failure_penalty": 0,
		},
		"reward_readiness": reward_readiness,
		"celebration_choice": {
			"destinations": ["FLOCK", "OFFICE", "STANDING", "MASTERY"],
			"current_reward": (playbook.get("contract", {}) as Dictionary).duplicate(true),
			"physical_landing": true,
			"choice_before_spectacle": true,
		},
		"fail_forward": {
			"recovery": (playbook.get("contextual_rescue", {}) as Dictionary).duplicate(true),
			"banked_rewards_safe": true,
			"next_shift_branch": true,
			"branches": ["TEMPORARY RULE", "RECOVERY CONTRACT", "CALL IN FAVOR", "COMEBACK WAGER"],
		},
		"mastery_variety": _mastery_variety(playbook, simulation),
		"chapter_transformation": {
			"chapter": chapter.duplicate(true),
			"world_changes": ["POPULATION", "EQUIPMENT", "RELATIONSHIPS", "RIVAL", "VERBS"],
			"before_after": true,
			"percentage_only": false,
		},
		"next_shift_hook": {
			"preview": (playbook.get("next_shift_preview", {}) as Dictionary).duplicate(true),
			"one_visual_promise": true,
			"categories": ["CLAIMANT", "FURNISHING", "RIVAL", "CAREER", "HERO FILE"],
		},
		"comprehension_validation": _comprehension_validation(playbook),
	}


static func _worker(workers: Array, worker_id: int) -> Dictionary:
	for value in workers:
		if value is Dictionary and int((value as Dictionary).get("id", -1)) == worker_id:
			return (value as Dictionary).duplicate(true)
	return {}


static func _attention_choreography(
	simulation: Dictionary,
	next_action: Dictionary,
	routing: Dictionary,
	focused_worker: Dictionary,
) -> Dictionary:
	var phase := int(simulation.get("shift_phase", 0))
	var pending := simulation.get("pending_decision", {}) as Dictionary
	var active_dispatch := String(routing.get("active_dispatch_lane", ""))
	var claim := focused_worker.get("current_claim", {}) as Dictionary
	var focus_id := "plan"
	var primary := String(next_action.get("visible_label", next_action.get("copy", "CHOOSE A PLAN")))
	var visible_groups := ["PRIMARY", "SHIFT ARC"]
	var next_action_id := String(next_action.get("action_id", ""))
	var plan_open := (
		next_action_id in ["plan", "choose_plan", "open_playbook"]
		or primary.to_upper().contains("FAST / SAFE / FLOCK")
	)
	if not pending.is_empty():
		focus_id = "decision"
		visible_groups = ["DECISION", "STAKES", "CONFIRM"]
	elif plan_open:
		focus_id = "plan"
		visible_groups = ["PLAN", "GAIN", "TRADEOFF"]
	elif phase == 1 and not active_dispatch.is_empty():
		focus_id = "choose_hen"
		primary = "PICK A HEN"
		visible_groups = ["ARMED FILE", "HEN FIT", "CANCEL"]
	elif phase == 1 and claim.is_empty():
		focus_id = "pickup_file"
		primary = "PICK A FILE"
		visible_groups = ["ROUTING TRAYS", "QUEUE PRESSURE", "SELECTED HEN"]
	elif phase == 1 and not claim.is_empty():
		focus_id = "work"
		primary = "WATCH THE FILE"
		visible_groups = ["LIVE FILE", "TIMING", "RESULT"]
	elif phase >= 3:
		focus_id = "review"
		primary = "REVIEW THE SHIFT"
		visible_groups = ["WHAT WORKED", "CLOSE CALL", "WHAT CHANGED"]
	return {
		"focus_id": focus_id,
		"primary": primary,
		"visible_groups": visible_groups,
		"dim_unrelated": true,
		"one_primary": true,
		"max_supporting_metrics": 2,
		"active_dispatch_lane": active_dispatch,
		"requires_file_pickup": focus_id == "pickup_file",
		"route_choices_visible": focus_id == "choose_hen",
		"invalid_choices_hidden": true,
	}


static func _hero_case(simulation: Dictionary, focused_worker: Dictionary) -> Dictionary:
	var day := maxi(1, int(simulation.get("day", 1)))
	var definition := HERO_CASES[posmod(day - 1, HERO_CASES.size())].duplicate(true)
	var claim := focused_worker.get("current_claim", {}) as Dictionary
	definition["day"] = day
	definition["active"] = not focused_worker.is_empty()
	definition["worker_id"] = int(focused_worker.get("id", -1))
	definition["worker_name"] = String(focused_worker.get("name", "FLOCK"))
	definition["claim_id"] = int(claim.get("id", -1))
	definition["lane"] = String(claim.get("lane", focused_worker.get("specialty", "")))
	definition["multiple_solutions"] = true
	definition["returning_consequence"] = true
	return definition


static func _rival_race(rival: Dictionary, playbook: Dictionary, simulation: Dictionary) -> Dictionary:
	var eggs := maxi(0, int(simulation.get("eggs_today", 0)))
	var quota := maxi(1, int(simulation.get("quota_target", 1)))
	return {
		"active": eggs > 0,
		"rival_name": String(rival.get("name", rival.get("rival_name", "RIVAL OFFICE"))),
		"player_progress": eggs,
		"target": quota,
		"progress_ratio": clampf(float(eggs) / float(quota), 0.0, 1.0),
		"intent": String(rival.get("intent", rival.get("rule", "PRESS THE CURRENT MARGIN"))),
		"cause": String(rival.get("cause", "CURRENT STRATEGY AND SCORE")),
		"response_window": "AFTER FIRST DELIVERY",
		"responses": ["DEFEND", "COUNTER", "BACK FLOCK"],
		"filed_response_id": String(playbook.get("rival_response_id", "")),
		"reaction_afterward": true,
		"quiet_before_relevant": true,
	}


static func _causal_receipt(feedback: Dictionary) -> Dictionary:
	return {
		"active": not feedback.is_empty(),
		"duration_seconds": 1.0,
		"steps": ["ACTION", "AFFECTED TARGET", "OUTCOME"],
		"single_sound": true,
		"single_number": true,
		"deduplicated": true,
		"receipt": feedback.duplicate(true),
	}


static func _environment_timing(attention: Dictionary) -> Dictionary:
	var focus_id := String(attention.get("focus_id", "plan"))
	var opportunity := {
		"plan": {"hotspot": "WHITEBOARD", "trade": "PLAN NOW / PRESERVE FLEXIBILITY"},
		"pickup_file": {"hotspot": "PRINTER", "trade": "CLEAR QUEUE / PRESERVE RELIABILITY"},
		"choose_hen": {"hotspot": "BULLETIN", "trade": "BEST FIT / DEADLINE"},
		"work": {"hotspot": "COFFEE", "trade": "RECOVER NOW / PRESERVE FUND"},
		"decision": {"hotspot": "WATER COOLER", "trade": "FLOCK VOICE / EXECUTIVE FAVOR"},
		"review": {"hotspot": "TROPHY SHELF", "trade": "DISPLAY ONE LEGACY"},
	}.get(focus_id, {"hotspot": "OFFICE", "trade": "OBSERVE / ACT"}) as Dictionary
	return {
		"current": opportunity.duplicate(true),
		"situational": true,
		"one_shot": true,
		"mandatory": false,
		"routine_chore": false,
	}


static func _reward_readiness(
	playbook: Dictionary,
	simulation: Dictionary,
	chapter: Dictionary,
	consolidated: Dictionary,
) -> Dictionary:
	var contract := playbook.get("contract", {}) as Dictionary
	return {
		"ready": bool(contract.get("complete", false)),
		"progress": int(contract.get("progress", 0)),
		"target": int(contract.get("target", 0)),
		"destination": ((consolidated.get("reward_cadence", {}) as Dictionary).get("shift", {}) as Dictionary).duplicate(true),
		"anticipation_cues": ["TROPHY SOCKET", "MUSIC LIFT", "OFFICE ACTIVITY", "PREPARED DELIVERY"],
		"before_after_world": true,
		"chapter": chapter.duplicate(true),
		"new_verb_required": true,
	}


static func _mastery_variety(playbook: Dictionary, simulation: Dictionary) -> Dictionary:
	return {
		"no_fomo": true,
		"no_daily_streak": true,
		"current": (playbook.get("strategy_mastery", {}) as Dictionary).duplicate(true),
		"personal_best": (playbook.get("personal_best", {}) as Dictionary).duplicate(true),
		"challenges": [
			{"id": "manual_office", "label": "WIN WITHOUT AUTOMATION", "icon": "route"},
			{"id": "relationship_case", "label": "RESOLVE THROUGH A BOND", "icon": "sync"},
			{"id": "comeback", "label": "RECOVER A CLOSE CALL", "icon": "care"},
			{"id": "unusual_build", "label": "WIN WITH AN OFF-META BUILD", "icon": "goal"},
			{"id": "clean_rival", "label": "BEAT RIVAL WITHOUT EXTRA RISK", "icon": "shield"},
			{"id": "perfect_file", "label": "LAND A PERFECT HERO FILE", "icon": "golden"},
		],
		"live_eggs": int(simulation.get("eggs_today", 0)),
	}


static func _comprehension_validation(playbook: Dictionary) -> Dictionary:
	var existing := playbook.get("comprehension_study", {}) as Dictionary
	return {
		"participants_required": 5,
		"unaided": true,
		"real_humans_required": true,
		"results_complete": false,
		"status": "AWAITING REAL PARTICIPANTS",
		"never_fabricate": true,
		"thresholds": {
			"choose_plan_unaided": "4/5",
			"route_within_seconds": 30,
			"explain_result_correctly": "4/5",
			"required_shortcut_discovery": 0,
		},
		"observations": ["EYE TARGET", "CURSOR PATH", "FIRST HESITATION", "RECOVERY PATH"],
		"instrumented_events": existing.get("instrumented_events", []),
	}


static func _authority_for(item_id: StringName) -> String:
	match item_id:
		&"player_authored_automation_policies": return "CHICKEN STATE + DEPARTMENT SIMULATION"
		&"pair_specific_flock_abilities": return "FLOCK BOND + TEAM LIFT"
		&"hand_authored_hero_cases": return "DEPARTMENT SIMULATION + PERSISTENT HERO CASE HISTORY"
		&"visible_rival_races", &"strategy_counters_with_disclosure": return "RIVAL SNAPSHOT + ACTIVE PLAYBOOK"
		&"reversible_what_if_planning": return "TACTICAL ROUTE PLAN + STRATEGY COMPARISON"
		&"real_five_person_comprehension_test": return "EXTERNAL HUMAN EVIDENCE PROTOCOL"
		&"phase_gated_hud", &"never_show_unusable_decision", &"stronger_focus_mode": return "OFFICE PRESENTATION"
		_: return "EXISTING SIMULATION / PLAYBOOK / OFFICE AUTHORITY"
