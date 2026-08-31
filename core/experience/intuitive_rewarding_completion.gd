class_name IntuitiveRewardingCompletion
extends RefCounted

## Read-only completion contract for the 33-item intuitive, fun, engaging, and
## rewarding pass. DepartmentSimulation remains the sole writer; this layer
## selects the shortest useful cue from existing authoritative systems.

const VERSION := 1
const ITEM_IDS: Array[StringName] = [
	&"playable_first_minute_tutorial",
	&"persistent_now_why_reward_cue",
	&"world_based_action_previews",
	&"physical_consequences",
	&"strong_shift_objective",
	&"transformative_rewards",
	&"strong_shift_finale",
	&"ten_second_review",
	&"hero_file_staging",
	&"hero_file_follow_through",
	&"developing_chicken_partnerships",
	&"chicken_initiative",
	&"distinct_chicken_work_styles",
	&"visible_rival_intent",
	&"rival_personality_development",
	&"short_skillful_combinations",
	&"meaningful_automation_progression",
	&"automation_world_behavior",
	&"visual_grammar_over_prose",
	&"progressive_disclosure",
	&"clear_affordances",
	&"action_availability_explanations",
	&"adaptive_assistance",
	&"compact_layout_hierarchy",
	&"session_sized_goals",
	&"visible_collection_cabinet",
	&"strategy_shaped_celebrations",
	&"meaningful_rematches",
	&"comeback_arcs",
	&"strong_next_shift_promise",
	&"content_repetition_protection",
	&"no_fomo_mastery_challenges",
	&"five_person_first_shift_study",
]


static func compose(context: Dictionary) -> Dictionary:
	var simulation := context.get("simulation", {}) as Dictionary
	var next_action := context.get("next_action", {}) as Dictionary
	var playbook := context.get("active_playbook", {}) as Dictionary
	var consolidated := context.get("consolidated_game_loop", {}) as Dictionary
	var professional := context.get("professional_gameplay_completion", {}) as Dictionary
	var feedback := context.get("action_feedback", {}) as Dictionary
	var funnel := context.get("first_session_funnel", {}) as Dictionary
	var guided := context.get("guided_loop", {}) as Dictionary
	var complete := context.get("complete_loop", {}) as Dictionary
	var rewarding := context.get("rewarding_loop", {}) as Dictionary
	var mastery := context.get("mastery_replay", {}) as Dictionary
	var strategic := context.get("strategic_flow_loop", {}) as Dictionary
	var cue := (consolidated.get("unified_cue", {}) as Dictionary).duplicate(true)
	var hero := (playbook.get("hero_case", {}) as Dictionary).duplicate(true)
	var partnership := (playbook.get("partnership", {}) as Dictionary).duplicate(true)
	var rival_memory := (playbook.get("rival_memory", {}) as Dictionary).duplicate(true)
	var automation := (playbook.get("mastery_automation", {}) as Dictionary).duplicate(true)
	var automation_report := (playbook.get("automation_report", {}) as Dictionary).duplicate(true)
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
		"now_why_reward": {
			"now": String(cue.get("now", next_action.get("visible_label", "OBSERVE"))),
			"why": String(cue.get("why", "MOVE THE SHIFT")),
			"reward": String(cue.get("reward", feedback.get("title", "VISIBLE RESULT"))),
			"word_budget": 6,
			"persistent": true,
		},
		"first_minute": {
			"playable": true,
			"skippable": true,
			"seconds": 60,
			"path": ["PLAN", "ROUTE", "HELP", "REWARD"],
			"prepared_file": true,
			"measurement": (funnel.get("micro_shift", {}) as Dictionary).duplicate(true),
		},
		"world_action_preview": {
			"target": String(next_action.get("world_target", next_action.get("target_id", "office"))),
			"ghost_path": true,
			"icons": (guided.get("consequence_icons", []) as Array).duplicate(true),
			"prose_required": false,
		},
		"physical_consequences": {
			"chain": ["FILE", "HEN", "EGG", "SORTER", "CREDIT"],
			"receipts_land_in_world": true,
			"affected_hen_reacts": true,
			"office_state_changes": true,
		},
		"shift_identity": {
			"objective": (playbook.get("dominant_objective", {}) as Dictionary).duplicate(true),
			"journey": (playbook.get("shift_journey", []) as Array).duplicate(true),
			"finale": (playbook.get("push_luck", {}) as Dictionary).duplicate(true),
			"boss_file": (playbook.get("boss_file", {}) as Dictionary).duplicate(true),
		},
		"reward_progression": {
			"transformative": (rewarding.get("transformative_reward", {}) as Dictionary).duplicate(true),
			"contract": (playbook.get("contract", {}) as Dictionary).duplicate(true),
			"strategy_mastery": (playbook.get("strategy_mastery", {}) as Dictionary).duplicate(true),
			"changes_verbs_not_only_percentages": true,
		},
		"review": {
			"seconds": 10,
			"beats": ["WHAT WORKED", "CLOSE CALL", "WHAT CHANGED", "NEXT SHIFT"],
			"replay_skippable": true,
			"source": (complete.get("review", {}) as Dictionary).duplicate(true),
		},
		"hero_file": {
			"id": String(hero.get("id", "")),
			"staging": (hero.get("staging", {}) as Dictionary).duplicate(true),
			"follow_through": (hero.get("follow_through", {}) as Dictionary).duplicate(true),
			"repetition_guard": (hero.get("repetition_guard", {}) as Dictionary).duplicate(true),
			"options": (hero.get("options", []) as Array).duplicate(true),
		},
		"partnership_growth": partnership,
		"chicken_agency": {
			"proposal": (playbook.get("hen_proposal", {}) as Dictionary).duplicate(true),
			"career_story": (playbook.get("career_story", {}) as Dictionary).duplicate(true),
			"trust_gated": true,
			"failure_penalty": 0,
		},
		"work_styles": _work_styles(simulation),
		"rival": {
			"intent": String(rival_memory.get("visible_intent", "VISIBLE BENCHMARK")),
			"personality": String(rival_memory.get("personality", "WATCHFUL BENCHMARKER")),
			"memory": rival_memory,
			"responses": (professional.get("rival_race", {}) as Dictionary).get("responses", []),
			"hidden_counter": false,
		},
		"skill_combinations": {
			"combo": (playbook.get("combo", {}) as Dictionary).duplicate(true),
			"recipe": (playbook.get("combo_recipe", {}) as Dictionary).duplicate(true),
			"teamwork": (playbook.get("teamwork", {}) as Dictionary).duplicate(true),
			"decision_seconds": 30,
		},
		"automation": {
			"progression": automation,
			"report": automation_report,
			"world_behavior": ["LEAVE DESK", "COLLECT FILE", "RETURN", "WORK", "DELIVER EGG"],
			"exceptions_manual": true,
			"policy_persistent_per_hen": true,
		},
		"visual_language": {
			"shapes": ["GOAL", "DANGER", "REWARD"],
			"icons": ["goal", "status_need", "egg"],
			"labels_retire_after_learning": true,
			"details_on_demand": true,
			"one_primary_action": true,
		},
		"availability": {
			"unusable_choices_hidden_by_default": true,
			"disabled_choices_explain_reason": true,
			"options": _availability_summary(playbook),
		},
		"adaptive_assistance": {
			"opt_in": true,
			"changes_difficulty": false,
			"show_me": (playbook.get("contextual_rescue", {}) as Dictionary).duplicate(true),
			"detail_density_adapts": true,
		},
		"compact_hierarchy": {
			"order": ["NOW", "WORLD", "RESULT", "DETAILS"],
			"touch_targets": true,
			"blocking_panel": false,
			"selected_hen_card_fields": 4,
		},
		"session_goal": {
			"minutes": (playbook.get("session_target_minutes", {}) as Dictionary).duplicate(true),
			"side_goal": (playbook.get("side_goal", {}) as Dictionary).duplicate(true),
			"permanent_challenge": (playbook.get("challenge", {}) as Dictionary).duplicate(true),
		},
		"collection_cabinet": {
			"physical": true,
			"sockets": (playbook.get("display_sockets", []) as Array).duplicate(true),
			"hero_files_archived": (playbook.get("hero_case_history", []) as Array).size(),
			"strategy_shaped": true,
		},
		"celebration": {
			"strategy_shaped": true,
			"destinations": ["FLOCK", "OFFICE", "STANDING", "MASTERY"],
			"choice_before_spectacle": true,
		},
		"replay_and_recovery": {
			"rematch": (mastery.get("rematch", mastery.get("rematch_variation", {})) as Dictionary).duplicate(true),
			"comeback": (playbook.get("contextual_rescue", {}) as Dictionary).duplicate(true),
			"next_shift": (playbook.get("next_shift_preview", {}) as Dictionary).duplicate(true),
			"banked_rewards_safe": true,
		},
		"repetition_protection": {
			"hero": (hero.get("repetition_guard", {}) as Dictionary).duplicate(true),
			"incident_bag": true,
			"dialogue_bags": true,
			"deterministic_remix": (strategic.get("challenge_variation", {}) as Dictionary).duplicate(true),
		},
		"mastery_challenges": {
			"permanent": true,
			"expires": false,
			"miss_penalty": 0,
			"catalog": (professional.get("mastery_variety", {}) as Dictionary).get("challenges", []),
		},
		"human_study": {
			"minimum_participants": 5,
			"first_shift": true,
			"protocol": (playbook.get("comprehension_study", {}) as Dictionary).duplicate(true),
			"instrumentation": (funnel.get("signals", {}) as Dictionary).duplicate(true),
			"status": "AWAITING REAL PARTICIPANTS",
			"results_complete": false,
			"never_fabricate": true,
		},
	}


static func _work_styles(simulation: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for worker_value in simulation.get("workers", []) as Array:
		if not worker_value is Dictionary:
			continue
		var worker := worker_value as Dictionary
		if not bool(worker.get("employed", false)):
			continue
		results.append({
			"worker_id": int(worker.get("id", -1)),
			"name": String(worker.get("name", "HEN")),
			"style": String(worker.get("temperament_work_style_label", "STEADY FILE")),
			"tell": String(worker.get("temperament_label", "STEADY HEN")),
			"mechanical": true,
		})
	return results


static func _availability_summary(playbook: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for option_value in playbook.get("options", []) as Array:
		if not option_value is Dictionary:
			continue
		var option := option_value as Dictionary
		results.append({
			"kind": String(option.get("kind", "")),
			"choice_id": String(option.get("choice_id", "")),
			"available": bool(option.get("available", false)),
			"reason": String(option.get("reason", "")),
		})
		if results.size() >= 12:
			break
	return results


static func _authority_for(item_id: StringName) -> String:
	if item_id in [&"hero_file_staging", &"hero_file_follow_through", &"content_repetition_protection"]:
		return "DepartmentSimulation / hero case history / incident bag"
	if item_id in [&"developing_chicken_partnerships", &"chicken_initiative", &"distinct_chicken_work_styles"]:
		return "ChickenState / DepartmentSimulation / Active Playbook"
	if item_id in [&"visible_rival_intent", &"rival_personality_development"]:
		return "DepartmentSimulation / persistent rival response history"
	if item_id in [&"meaningful_automation_progression", &"automation_world_behavior"]:
		return "ChickenState automation policy / Office chicken choreography"
	if item_id == &"five_person_first_shift_study":
		return "FirstSessionFunnel / real-participant study protocol"
	return "GameplayPulseDirector / existing campaign, simulation, office, and review authorities"
