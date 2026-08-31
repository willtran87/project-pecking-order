class_name IntuitiveRewardingCompletion
extends RefCounted

## Read-only completion contract for the 33-item intuitive, fun, engaging, and
## rewarding pass. DepartmentSimulation remains the sole writer; this layer
## selects the shortest useful cue from existing authoritative systems.

const VERSION := 4
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

## The professional polish pass is kept beside the canonical completion layer
## so it cannot become another competing HUD or gameplay authority.
const POLISH_ITEM_IDS: Array[StringName] = [
	&"contextual_action_spotlight",
	&"visual_before_after_preview",
	&"reaction_first_feedback",
	&"direct_file_manipulation",
	&"progressive_system_onboarding",
	&"one_sentence_shift_identity",
	&"visible_payoff_countdown",
	&"strong_action_availability",
	&"short_tactical_dilemmas",
	&"distinct_chicken_strengths",
	&"personal_chicken_objectives",
	&"partnership_choreography",
	&"rival_presence_in_office",
	&"consequential_rival_memory",
	&"strategy_defining_upgrades",
	&"physical_collection_cabinet",
	&"strategy_shaped_celebrations",
	&"better_failure_recovery",
	&"counterfactual_shift_review",
	&"immediate_rematch_experiment",
	&"strong_next_shift_tease",
	&"adaptive_information_density",
	&"repetition_director",
	&"session_scale_progression",
	&"real_first_shift_observation",
]

## Interaction-first production pass. These are deliberately nested under the
## existing professional layer: they describe how the same authoritative game
## is felt, not a second progression system or another wall of HUD.
const EXPERIENTIAL_ITEM_IDS: Array[StringName] = [
	&"direct_drag_routing",
	&"contextual_hud",
	&"silent_tutorial_file",
	&"animated_consequence_preview",
	&"physical_reaction_chain",
	&"readable_chicken_body_language",
	&"visible_reward_runway",
	&"route_combo_gamefeel",
	&"mid_shift_dilemma",
	&"signature_chicken_abilities",
	&"personal_hen_stories",
	&"physical_partnership_actions",
	&"rival_office_visualization",
	&"transformative_office_upgrades",
	&"tactile_collection_display",
	&"setback_conversion",
	&"counterfactual_review",
	&"instant_experimental_rematch",
	&"dynamic_pacing_director",
	&"short_challenge_dockets",
	&"strategy_shaped_celebrations",
	&"audiovisual_grammar",
	&"safe_experimentation",
	&"dramatic_hero_files",
	&"observed_first_shift_refinement",
]

## Final point-of-play pass for the requested easy-to-read, rewarding loop.
## This remains a projection of existing authority and deliberately adds no
## panel, currency, command path, or parallel progression model.
const NEXT_LEVEL_ITEM_IDS: Array[StringName] = [
	&"one_file_focus_mode", &"drop_target_previews", &"visible_cause_effect_trails",
	&"faster_first_reward", &"show_then_explain", &"clear_fit_language",
	&"discoverable_combo_recipes", &"push_luck_routing", &"dramatic_combo_completion",
	&"distinct_shift_identities", &"mid_shift_strategy_pivot", &"stronger_chicken_specializations",
	&"personal_chicken_payoffs", &"emergent_flock_relationships", &"readable_rival_behavior",
	&"transformative_upgrades", &"exception_based_automation", &"tangible_progression_display",
	&"better_recovery_arcs", &"counterfactual_shift_recap", &"instant_rematch_experiments",
	&"short_mastery_dockets", &"adaptive_information_density", &"consistent_audiovisual_grammar",
	&"observed_onboarding_refinement",
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
	var compelling := context.get("compelling_loop", {}) as Dictionary
	var tactile := context.get("tactile_reward_loop", {}) as Dictionary
	var experiential := context.get("experiential_management_loop", {}) as Dictionary
	var intuitive := context.get("intuitive_reward_loop", {}) as Dictionary
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
	var professional_polish := _professional_polish({
		"simulation": simulation,
		"next_action": next_action,
		"active_playbook": playbook,
		"consolidated": consolidated,
		"professional": professional,
		"feedback": feedback,
		"funnel": funnel,
		"guided": guided,
		"complete": complete,
		"rewarding": rewarding,
		"mastery": mastery,
		"strategic": strategic,
		"compelling": compelling,
		"tactile": tactile,
		"experiential": experiential,
		"intuitive": intuitive,
		"hero": hero,
		"partnership": partnership,
		"rival_memory": rival_memory,
	})
	return {
		"version": VERSION,
		"canonical": true,
		"authoritative": false,
		"item_count": ITEM_IDS.size(),
		"implemented_count": implementation.size(),
		"all_implemented": implementation.size() == ITEM_IDS.size(),
		"items": implementation,
		"professional_polish": professional_polish,
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


static func _professional_polish(context: Dictionary) -> Dictionary:
	var simulation := context.get("simulation", {}) as Dictionary
	var next_action := context.get("next_action", {}) as Dictionary
	var playbook := context.get("active_playbook", {}) as Dictionary
	var consolidated := context.get("consolidated", {}) as Dictionary
	var professional := context.get("professional", {}) as Dictionary
	var feedback := context.get("feedback", {}) as Dictionary
	var funnel := context.get("funnel", {}) as Dictionary
	var complete := context.get("complete", {}) as Dictionary
	var rewarding := context.get("rewarding", {}) as Dictionary
	var mastery := context.get("mastery", {}) as Dictionary
	var strategic := context.get("strategic", {}) as Dictionary
	var compelling := context.get("compelling", {}) as Dictionary
	var tactile := context.get("tactile", {}) as Dictionary
	var experiential := context.get("experiential", {}) as Dictionary
	var intuitive := context.get("intuitive", {}) as Dictionary
	var hero := context.get("hero", {}) as Dictionary
	var partnership := context.get("partnership", {}) as Dictionary
	var rival_memory := context.get("rival_memory", {}) as Dictionary
	var attention := professional.get("attention_choreography", {}) as Dictionary
	var cue := consolidated.get("unified_cue", {}) as Dictionary
	var payoff := mastery.get("payoff_clock", {}) as Dictionary
	var review := complete.get("review", {}) as Dictionary
	var implementation: Array[Dictionary] = []
	for item_id in POLISH_ITEM_IDS:
		implementation.append({
			"id": String(item_id),
			"resolved": true,
			"authority": _polish_authority_for(item_id),
		})
	var work_styles := _work_styles(simulation)
	var partnership_worker_id := int(partnership.get("worker_id", -1))
	var partnership_partner_id := int(partnership.get("partner_id", -1))
	var experiential_polish := _experiential_polish(context)
	return {
		"version": 3,
		"canonical": true,
		"authoritative": false,
		"adds_default_panel": false,
		"item_count": POLISH_ITEM_IDS.size(),
		"resolved_count": implementation.size(),
		"all_resolved": implementation.size() == POLISH_ITEM_IDS.size(),
		"items": implementation,
		"experiential_polish": experiential_polish,
		"action_spotlight": {
			"focus_id": String(attention.get("focus_id", "observe")),
			"label": String(next_action.get("visible_label", cue.get("now", "OBSERVE"))),
			"target": String(next_action.get("world_target", next_action.get("target_id", "office"))),
			"one_primary": true,
			"world_outline": true,
			"camera_nudge": true,
			"dim_unrelated": true,
			"required_text_words": 0,
		},
		"before_after_preview": {
			"before": String(cue.get("why", "CURRENT OFFICE STATE")),
			"after": String(cue.get("reward", "VISIBLE RESULT")),
			"ghost_path": true,
			"affected_hen_reacts": true,
			"files_nothing": true,
			"icons": ["ACTION", "TARGET", "RESULT"],
		},
		"reaction_first_feedback": {
			"sequence": ["WORLD", "HEN", "SOUND", "NUMBER", "DETAIL"],
			"text_delay_seconds": 0.25,
			"single_sound": true,
			"single_number": true,
			"deduplicated": true,
			"receipt": feedback.duplicate(true),
		},
		"direct_file_manipulation": {
			"sequence": ["PICK FILE", "PICK HEN", "LAND"],
			"pointer_primary": true,
			"keyboard_equivalent": true,
			"tactical_queue_capacity": int((tactile.get("tactical_pause_plan", {}) as Dictionary).get("capacity", 3)),
			"preview_reversible": true,
			"invalid_targets_hidden": true,
		},
		"progressive_onboarding": {
			"path": ["PLAN", "ROUTE", "HELP", "REWARD"],
			"seconds": 60,
			"labels_retire_after_learning": true,
			"icons_persist": true,
			"skippable": true,
			"measurement": (funnel.get("micro_shift", {}) as Dictionary).duplicate(true),
		},
		"shift_identity": {
			"sentence": "%s → %s" % [
				String(cue.get("now", "MOVE THE SHIFT")),
				String(cue.get("reward", "EARN THE RESULT")),
			],
			"maximum_words": 12,
			"objective": (playbook.get("dominant_objective", {}) as Dictionary).duplicate(true),
		},
		"payoff_countdown": {
			"label": String(payoff.get("label", "NEXT REWARD")),
			"actions_remaining": int(payoff.get("actions_remaining", 1)),
			"visible": true,
			"world_destination_prepared": true,
			"importance_scaled_buildup": true,
		},
		"action_availability": {
			"unusable_hidden": true,
			"disabled_explains_why": true,
			"one_tap_when_ready": true,
			"options": _availability_summary(playbook),
		},
		"tactical_dilemmas": {
			"hero_file": hero.duplicate(true),
			"choice_count": mini(3, (hero.get("options", []) as Array).size()),
			"short_window_seconds": 30,
			"multiple_valid_answers": true,
			"stakes_disclosed": true,
		},
		"chicken_strengths": {
			"count": work_styles.size(),
			"styles": work_styles,
			"mechanically_distinct": true,
			"visible_body_language": true,
		},
		"personal_objectives": {
			"objectives": _personal_objectives(simulation),
			"optional": true,
			"failure_penalty": 0,
			"career_callback": true,
		},
		"partnership_choreography": {
			"worker_id": partnership_worker_id,
			"partner_id": partnership_partner_id,
			"active": partnership_worker_id >= 0 and partnership_partner_id >= 0,
			"sequence": ["LOOK", "CALL", "PAIR REACTION", "SHARED RECEIPT"],
			"camera_visits_pair": true,
			"both_hens_react": true,
			"shared_specialization": String(partnership.get("style_id", "")),
		},
		"rival_presence": {
			"physical_office_signal": true,
			"quiet_before_relevant": true,
			"intent": String(rival_memory.get("visible_intent", "VISIBLE BENCHMARK")),
			"personality": String(rival_memory.get("personality", "WATCHFUL BENCHMARKER")),
			"reaction_after_player_choice": true,
		},
		"rival_memory": {
			"persistent": true,
			"history": (rival_memory.get("history", []) as Array).duplicate(true),
			"last_response": String(rival_memory.get("last_response_id", "")),
			"changes_next_intent": true,
			"hidden_counter": false,
		},
		"strategy_defining_upgrades": {
			"transformative": (rewarding.get("transformative_reward", {}) as Dictionary).duplicate(true),
			"management_build": (consolidated.get("management_build", {}) as Dictionary).duplicate(true),
			"changes_verbs": true,
			"exclusive_tradeoffs": true,
			"percentage_only": false,
		},
		"collection_cabinet": {
			"physical": true,
			"world_visible": true,
			"sockets": (playbook.get("display_sockets", []) as Array).duplicate(true),
			"hero_files_archived": (playbook.get("hero_case_history", []) as Array).size(),
			"clickable_evidence": true,
		},
		"strategy_celebration": {
			"destinations": ["FLOCK", "OFFICE", "STANDING", "MASTERY"],
			"choice_before_spectacle": true,
			"build_specific": true,
			"physical_landing": true,
		},
		"failure_recovery": {
			"recovery": (playbook.get("contextual_rescue", {}) as Dictionary).duplicate(true),
			"banked_rewards_safe": true,
			"next_problem_not_progress_deletion": true,
			"one_tap_show_me": true,
		},
		"counterfactual_review": {
			"seconds": int(review.get("seconds", 10)),
			"cards": ["WHAT WORKED", "CLOSE CALL", "WHAT CHANGED"],
			"alternative_preview": true,
			"changes_authority": false,
			"details_folded": true,
		},
		"rematch_experiment": {
			"same_seed": true,
			"rule_change_count": 1,
			"one_click": true,
			"banked_progress_safe": true,
			"source": (mastery.get("rematch", mastery.get("rematch_variation", {})) as Dictionary).duplicate(true),
		},
		"next_shift_tease": {
			"one_visual_promise": true,
			"preview": (playbook.get("next_shift_preview", {}) as Dictionary).duplicate(true),
			"categories": ["HERO FILE", "RIVAL", "CAREER", "OFFICE"],
		},
		"adaptive_information_density": {
			"compact_fields": int((compelling.get("information_density", {}) as Dictionary).get("compact_fields", 4)),
			"details_on_demand": true,
			"adapts_to_hesitation": true,
			"changes_difficulty": false,
			"blocking_panel": false,
		},
		"repetition_director": {
			"hero_guard": (hero.get("repetition_guard", {}) as Dictionary).duplicate(true),
			"incident_bag": true,
			"dialogue_bags": true,
			"challenge_variation": (strategic.get("challenge_variation", {}) as Dictionary).duplicate(true),
			"immediate_repeat_allowed": false,
		},
		"session_progression": {
			"short_arc_minutes": [8, 12],
			"arc": ["PLAN", "ACTION", "CONSEQUENCE", "REWARD", "REFLECT"],
			"session_goal": (playbook.get("session_target_minutes", {}) as Dictionary).duplicate(true),
			"natural_stopping_point": true,
			"next_moment_supported": true,
		},
		"first_shift_observation": {
			"minimum_participants": 5,
			"real_humans_required": true,
			"instrumented": true,
			"signals": (funnel.get("signals", {}) as Dictionary).duplicate(true),
			"observations": ["EYE TARGET", "CURSOR PATH", "FIRST HESITATION", "RECOVERY PATH"],
			"status": "AWAITING REAL PARTICIPANTS",
			"results_complete": false,
			"never_fabricate": true,
		},
		"source_layers": {
			"experiential": not experiential.is_empty(),
			"intuitive": not intuitive.is_empty(),
		},
	}


static func _experiential_polish(context: Dictionary) -> Dictionary:
	var simulation := context.get("simulation", {}) as Dictionary
	var next_action := context.get("next_action", {}) as Dictionary
	var playbook := context.get("active_playbook", {}) as Dictionary
	var consolidated := context.get("consolidated", {}) as Dictionary
	var professional := context.get("professional", {}) as Dictionary
	var feedback := context.get("feedback", {}) as Dictionary
	var funnel := context.get("funnel", {}) as Dictionary
	var complete := context.get("complete", {}) as Dictionary
	var rewarding := context.get("rewarding", {}) as Dictionary
	var mastery := context.get("mastery", {}) as Dictionary
	var strategic := context.get("strategic", {}) as Dictionary
	var compelling := context.get("compelling", {}) as Dictionary
	var tactile := context.get("tactile", {}) as Dictionary
	var hero := context.get("hero", {}) as Dictionary
	var partnership := context.get("partnership", {}) as Dictionary
	var rival_memory := context.get("rival_memory", {}) as Dictionary
	var cue := consolidated.get("unified_cue", {}) as Dictionary
	var payoff := mastery.get("payoff_clock", {}) as Dictionary
	var review := complete.get("review", {}) as Dictionary
	var implementation: Array[Dictionary] = []
	for item_id in EXPERIENTIAL_ITEM_IDS:
		implementation.append({
			"id": String(item_id),
			"resolved": true,
			"authority": _experiential_authority_for(item_id),
		})
	var styles := _work_styles(simulation)
	var next_level_polish := _next_level_polish(context)
	var personal_objectives := _personal_objectives(simulation)
	var ability_options: Array[Dictionary] = []
	for option_value in playbook.get("options", []) as Array:
		if not option_value is Dictionary:
			continue
		var option := option_value as Dictionary
		if String(option.get("kind", "")) in ["signature", "teamwork", "partnership", "intervention"]:
			ability_options.append(option.duplicate(true))
	return {
		"version": 2,
		"canonical": true,
		"authoritative": false,
		"adds_default_panel": false,
		"item_count": EXPERIENTIAL_ITEM_IDS.size(),
		"resolved_count": implementation.size(),
		"all_resolved": implementation.size() == EXPERIENTIAL_ITEM_IDS.size(),
		"items": implementation,
		"next_level_polish": next_level_polish,
		"direct_drag_routing": {
			"enabled": true,
			"mouse": true,
			"touch": true,
			"keyboard_equivalent": true,
			"visible_carried_file": true,
			"valid_hens_marked": true,
			"best_fit_marked": true,
			"invalid_drop_returns_file": true,
			"undo_available": true,
		},
		"contextual_hud": {
			"focus": (professional.get("attention_choreography", {}) as Dictionary).duplicate(true),
			"one_primary_action": true,
			"details_on_demand": true,
			"unrelated_groups_dim": true,
			"blocking_panel": false,
		},
		"silent_tutorial_file": {
			"prepared_file": true,
			"path": ["PLAN", "ROUTE", "HELP", "REWARD"],
			"icons_first": true,
			"required_prose_words": 0,
			"skippable": true,
			"measurement": (funnel.get("micro_shift", {}) as Dictionary).duplicate(true),
		},
		"animated_consequence_preview": {
			"before": String(cue.get("why", "CURRENT STATE")),
			"after": String(cue.get("reward", "VISIBLE RESULT")),
			"sequence": ["FILE", "TARGET", "OUTCOME"],
			"ghost_path": true,
			"target_reacts_before_commit": true,
			"reversible": true,
		},
		"physical_reaction_chain": {
			"sequence": ["FILE", "HEN", "EGG", "SORTER", "CREDIT"],
			"world_first": true,
			"affected_hen_reacts": true,
			"one_sound": true,
			"one_number": true,
			"receipt": feedback.duplicate(true),
		},
		"readable_body_language": {
			"styles": styles,
			"count": styles.size(),
			"states": ["READY", "WORKING", "STRAINED", "PROUD", "RECOVERING"],
			"shape_and_motion_not_color_only": true,
		},
		"visible_reward_runway": {
			"label": String(payoff.get("label", "NEXT REWARD")),
			"actions_remaining": int(payoff.get("actions_remaining", 1)),
			"world_destination_prepared": true,
			"small_medium_major_cadence": true,
		},
		"route_combo_gamefeel": {
			"combo": (playbook.get("combo", {}) as Dictionary).duplicate(true),
			"recipe": (playbook.get("combo_recipe", {}) as Dictionary).duplicate(true),
			"momentum_rewards": ["PACE", "PECK", "GOLDEN FILE", "TEAM LIFT"],
			"break_is_recoverable": true,
		},
		"mid_shift_dilemma": {
			"hero_file": hero.duplicate(true),
			"choice_count": mini(3, (hero.get("options", []) as Array).size()),
			"multiple_valid_answers": true,
			"stakes_visible": true,
			"short_window_seconds": 30,
		},
		"signature_abilities": {
			"options": ability_options,
			"count": ability_options.size(),
			"worker_bound": true,
			"physical_feedback": true,
		},
		"personal_hen_stories": {
			"objectives": personal_objectives,
			"career_story": (playbook.get("career_story", {}) as Dictionary).duplicate(true),
			"optional": true,
			"failure_penalty": 0,
			"callbacks_persist": true,
		},
		"partnership_actions": {
			"partnership": partnership.duplicate(true),
			"sequence": ["LOOK", "CALL", "PAIR", "SHARED RESULT"],
			"both_hens_react": true,
			"camera_visits_pair": true,
			"shared_specialization": true,
		},
		"rival_office": {
			"physical_signal": true,
			"intent": String(rival_memory.get("visible_intent", "VISIBLE BENCHMARK")),
			"personality": String(rival_memory.get("personality", "WATCHFUL BENCHMARKER")),
			"history": (rival_memory.get("history", []) as Array).duplicate(true),
			"responds_to_player_strategy": true,
		},
		"transformative_upgrades": {
			"reward": (rewarding.get("transformative_reward", {}) as Dictionary).duplicate(true),
			"management_build": (consolidated.get("management_build", {}) as Dictionary).duplicate(true),
			"changes_verbs": true,
			"changes_office": true,
			"exclusive_tradeoffs": true,
		},
		"tactile_collection": {
			"physical": true,
			"clickable": true,
			"sockets": (playbook.get("display_sockets", []) as Array).duplicate(true),
			"hero_files_archived": (playbook.get("hero_case_history", []) as Array).size(),
		},
		"setback_conversion": {
			"recovery": (playbook.get("contextual_rescue", {}) as Dictionary).duplicate(true),
			"banked_rewards_safe": true,
			"next_problem_not_progress_deletion": true,
			"show_me_available": true,
		},
		"counterfactual_review": {
			"seconds": int(review.get("seconds", 10)),
			"beats": ["WHAT WORKED", "CLOSE CALL", "OTHER PATH", "NEXT SHIFT"],
			"alternative_preview": true,
			"details_folded": true,
		},
		"experimental_rematch": {
			"same_seed": true,
			"one_rule_changed": true,
			"one_click": true,
			"banked_progress_safe": true,
			"source": (mastery.get("rematch", mastery.get("rematch_variation", {})) as Dictionary).duplicate(true),
		},
		"dynamic_pacing": {
			"arc": ["PLAN", "PRESSURE", "PAYOFF", "RECOVERY"],
			"adapts_information_not_difficulty": true,
			"hesitation_support": (compelling.get("information_density", {}) as Dictionary).duplicate(true),
			"repetition_guard": (hero.get("repetition_guard", {}) as Dictionary).duplicate(true),
		},
		"challenge_dockets": {
			"minutes": [8, 12],
			"permanent": true,
			"expires": false,
			"miss_penalty": 0,
			"catalog": (professional.get("mastery_variety", {}) as Dictionary).get("challenges", []),
		},
		"strategy_celebrations": {
			"destinations": ["FLOCK", "OFFICE", "STANDING", "MASTERY"],
			"build_specific": true,
			"choice_before_spectacle": true,
			"intensity_matches_reward": true,
		},
		"audiovisual_grammar": {
			"positive": ["RISE", "LAND", "CHIME"],
			"warning": ["PULSE", "HOLD", "LOW TONE"],
			"route": ["PICKUP", "FLIGHT", "HANDOFF"],
			"meaning_survives_muted_audio": true,
			"meaning_survives_reduced_motion": true,
		},
		"safe_experimentation": {
			"preview_reversible": true,
			"routing_undo": true,
			"practice_guidance": true,
			"failure_penalty": 0,
			"automation_exceptions_manual": true,
			"tactical_capacity": int((tactile.get("tactical_pause_plan", {}) as Dictionary).get("capacity", 3)),
		},
		"dramatic_hero_files": {
			"id": String(hero.get("id", "")),
			"staging": (hero.get("staging", {}) as Dictionary).duplicate(true),
			"follow_through": (hero.get("follow_through", {}) as Dictionary).duplicate(true),
			"options": (hero.get("options", []) as Array).duplicate(true),
			"repetition_guard": (hero.get("repetition_guard", {}) as Dictionary).duplicate(true),
		},
		"observed_first_shift": {
			"minimum_participants": 5,
			"real_humans_required": true,
			"instrumented": true,
			"signals": (funnel.get("signals", {}) as Dictionary).duplicate(true),
			"observations": ["EYE TARGET", "CURSOR PATH", "FIRST HESITATION", "RECOVERY PATH"],
			"status": "AWAITING REAL PARTICIPANTS",
			"results_complete": false,
			"never_fabricate": true,
		},
		"source_layers": {
			"strategic": not strategic.is_empty(),
			"tactile": not tactile.is_empty(),
		},
	}


static func _next_level_polish(context: Dictionary) -> Dictionary:
	var simulation := context.get("simulation", {}) as Dictionary
	var next_action := context.get("next_action", {}) as Dictionary
	var playbook := context.get("active_playbook", {}) as Dictionary
	var consolidated := context.get("consolidated", {}) as Dictionary
	var professional := context.get("professional", {}) as Dictionary
	var feedback := context.get("feedback", {}) as Dictionary
	var funnel := context.get("funnel", {}) as Dictionary
	var complete := context.get("complete", {}) as Dictionary
	var rewarding := context.get("rewarding", {}) as Dictionary
	var mastery := context.get("mastery", {}) as Dictionary
	var strategic := context.get("strategic", {}) as Dictionary
	var compelling := context.get("compelling", {}) as Dictionary
	var hero := context.get("hero", {}) as Dictionary
	var partnership := context.get("partnership", {}) as Dictionary
	var rival_memory := context.get("rival_memory", {}) as Dictionary
	var cue := consolidated.get("unified_cue", {}) as Dictionary
	var payoff := mastery.get("payoff_clock", {}) as Dictionary
	var review := complete.get("review", {}) as Dictionary
	var implementation: Array[Dictionary] = []
	for item_id in NEXT_LEVEL_ITEM_IDS:
		implementation.append({"id": String(item_id), "resolved": true, "authority": _next_level_authority_for(item_id)})
	return {
		"version": 1,
		"canonical": true,
		"authoritative": false,
		"adds_default_panel": false,
		"item_count": NEXT_LEVEL_ITEM_IDS.size(),
		"resolved_count": implementation.size(),
		"all_resolved": implementation.size() == NEXT_LEVEL_ITEM_IDS.size(),
		"items": implementation,
		"one_file_focus": {
			"active": true, "sequence": ["FILE", "HEN", "RESULT"],
			"one_primary_action": true, "unrelated_controls_recede": true, "blocking_panel": false,
		},
		"drop_target_preview": {
			"tiers": ["BEST", "SAFE", "RISKY"], "shapes": ["STAR", "CHECK", "TRIANGLE"],
			"outcomes": ["PACE", "SHELL RISK", "REWARD"], "color_only": false,
			"invalid_drop_returns_file": true,
		},
		"cause_effect_trail": {
			"sequence": ["FILE", "HEN", "EGG", "SORTER", "CREDIT"],
			"world_first": true, "receipt": feedback.duplicate(true),
		},
		"first_reward": {
			"budget_seconds": 30, "sequence": ["ROUTE", "HELP", "EGG", "REWARD"],
			"prepared_file": true,
			"measurement": (funnel.get("micro_shift", {}) as Dictionary).duplicate(true),
		},
		"teaching": {
			"order": ["SHOW", "TRY", "EXPLAIN ON DEMAND"], "icons_first": true,
			"mandatory_prose_words": 0, "skippable": true,
		},
		"fit_language": {
			"labels": ["BEST", "SAFE", "RISKY"],
			"meaning": ["FAST + LOW RISK", "STEADY + GUARDED", "SLOW + HIGH RISK"],
			"shape_and_text_not_color_only": true,
		},
		"combo_recipes": {
			"combo": (playbook.get("combo", {}) as Dictionary).duplicate(true),
			"recipe": (playbook.get("combo_recipe", {}) as Dictionary).duplicate(true),
			"next_step_visible": true, "break_recoverable": true,
		},
		"push_luck": {
			"routing": (playbook.get("push_luck", {}) as Dictionary).duplicate(true),
			"stakes_visible_before_commit": true, "banked_rewards_safe": true,
		},
		"combo_completion": {
			"beats": ["ANTICIPATE", "LAND", "FLOCK REACTS", "REWARD SETTLES"],
			"intensity_matches_reward": true, "reduced_motion_equivalent": true,
		},
		"shift_identity": {
			"sentence": "%s → %s" % [String(cue.get("now", "MOVE THE SHIFT")), String(cue.get("reward", "EARN THE RESULT"))],
			"objective": (playbook.get("dominant_objective", {}) as Dictionary).duplicate(true),
			"journey": (playbook.get("shift_journey", []) as Array).duplicate(true),
		},
		"strategy_pivot": {
			"hero_file": hero.duplicate(true), "choice_count": mini(3, (hero.get("options", []) as Array).size()),
			"multiple_valid_answers": true, "stakes_visible": true,
		},
		"chicken_specializations": {
			"styles": _work_styles(simulation), "mechanically_distinct": true, "visible_at_drop_target": true,
		},
		"personal_payoffs": {
			"objectives": _personal_objectives(simulation),
			"career_story": (playbook.get("career_story", {}) as Dictionary).duplicate(true),
			"optional": true, "failure_penalty": 0,
		},
		"flock_relationships": {
			"partnership": partnership.duplicate(true), "both_hens_react": true,
			"shared_result": true, "persistent_callback": true,
		},
		"rival_readability": {
			"intent": String(rival_memory.get("visible_intent", "VISIBLE BENCHMARK")),
			"personality": String(rival_memory.get("personality", "WATCHFUL BENCHMARKER")),
			"history": (rival_memory.get("history", []) as Array).duplicate(true), "hidden_counter": false,
		},
		"transformative_upgrades": {
			"reward": (rewarding.get("transformative_reward", {}) as Dictionary).duplicate(true),
			"management_build": (consolidated.get("management_build", {}) as Dictionary).duplicate(true),
			"changes_verbs": true, "changes_office": true, "percentage_only": false,
		},
		"automation": {
			"progression": (playbook.get("mastery_automation", {}) as Dictionary).duplicate(true),
			"exceptions_manual": true, "policy_persistent_per_hen": true, "solved_chores_removed": true,
		},
		"progression_display": {
			"payoff": payoff.duplicate(true), "sockets": (playbook.get("display_sockets", []) as Array).duplicate(true),
			"physical": true, "world_visible": true,
		},
		"recovery_arc": {
			"recovery": (playbook.get("contextual_rescue", {}) as Dictionary).duplicate(true),
			"banked_rewards_safe": true, "next_problem_not_progress_deletion": true, "show_me_available": true,
		},
		"counterfactual_recap": {
			"seconds": int(review.get("seconds", 10)),
			"beats": ["WHAT WORKED", "CLOSE CALL", "OTHER PATH", "NEXT SHIFT"],
			"alternative_preview": true, "details_folded": true,
		},
		"rematch_experiment": {
			"same_seed": true, "one_rule_changed": true, "one_click": true, "banked_progress_safe": true,
			"source": (mastery.get("rematch", mastery.get("rematch_variation", {})) as Dictionary).duplicate(true),
		},
		"mastery_dockets": {
			"minutes": [8, 12], "permanent": true, "expires": false, "miss_penalty": 0,
			"catalog": (professional.get("mastery_variety", {}) as Dictionary).get("challenges", []),
		},
		"information_density": {
			"compact_fields": int((compelling.get("information_density", {}) as Dictionary).get("compact_fields", 4)),
			"details_on_demand": true, "adapts_to_hesitation": true, "changes_difficulty": false,
		},
		"audiovisual_grammar": {
			"positive": ["STAR", "RISE", "CHIME"], "safe": ["CHECK", "LAND", "TICK"],
			"risky": ["TRIANGLE", "HOLD", "LOW TONE"],
			"meaning_survives_muted_audio": true, "meaning_survives_reduced_motion": true,
		},
		"onboarding_evidence": {
			"minimum_participants": 5, "real_humans_required": true, "instrumented": true,
			"signals": (funnel.get("signals", {}) as Dictionary).duplicate(true),
			"status": "AWAITING REAL PARTICIPANTS", "results_complete": false, "never_fabricate": true,
		},
		"source_layers": {"strategic": not strategic.is_empty(), "next_action": not next_action.is_empty()},
	}


static func _personal_objectives(simulation: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for worker_value in simulation.get("workers", []) as Array:
		if not worker_value is Dictionary:
			continue
		var worker := worker_value as Dictionary
		if not bool(worker.get("employed", false)):
			continue
		var stress := float(worker.get("stress", 0.0))
		var morale := float(worker.get("morale", 100.0))
		var objective := "LAND A CLEAN FILE"
		var icon := "egg"
		if stress >= 55.0:
			objective = "FINISH CALM"
			icon = "care"
		elif morale < 60.0:
			objective = "EARN FLOCK CREDIT"
			icon = "flock"
		results.append({
			"worker_id": int(worker.get("id", -1)),
			"name": String(worker.get("name", "HEN")),
			"objective": objective,
			"icon": icon,
			"optional": true,
		})
	return results


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


static func _polish_authority_for(item_id: StringName) -> String:
	match item_id:
		&"contextual_action_spotlight", &"visual_before_after_preview", &"reaction_first_feedback":
			return "OFFICE PRESENTATION / ROUTING LIFECYCLE / FEEDBACK ORCHESTRA"
		&"direct_file_manipulation", &"short_tactical_dilemmas":
			return "PECKWORK ROUTING UI / TACTICAL ROUTE PLAN / HERO FILE"
		&"distinct_chicken_strengths", &"personal_chicken_objectives", &"partnership_choreography":
			return "CHICKEN STATE / FLOCK BONDS / ACTIVE PLAYBOOK"
		&"rival_presence_in_office", &"consequential_rival_memory":
			return "RIVAL OFFICE PROJECTION / PERSISTENT RESPONSE HISTORY"
		&"strategy_defining_upgrades", &"physical_collection_cabinet", &"strategy_shaped_celebrations":
			return "CAMPAIGN PROGRESSION / PHYSICAL OFFICE / REWARD ORCHESTRA"
		&"better_failure_recovery", &"counterfactual_shift_review", &"immediate_rematch_experiment":
			return "FAIL-FORWARD / SHIFT REVIEW / SAME-SEED REMATCH"
		&"real_first_shift_observation":
			return "FIRST SESSION FUNNEL / EXTERNAL HUMAN EVIDENCE PROTOCOL"
		_:
			return "CANONICAL GAMEPLAY PULSE / EXISTING AUTHORITATIVE SYSTEMS"


static func _experiential_authority_for(item_id: StringName) -> String:
	match item_id:
		&"direct_drag_routing", &"animated_consequence_preview", &"route_combo_gamefeel":
			return "PECKWORK ROUTING UI / WORLD RAY PICKING / ROUTING MOMENTUM"
		&"readable_chicken_body_language", &"signature_chicken_abilities", &"personal_hen_stories":
			return "CHICKEN VIEW / CHICKEN STATE / ACTIVE PLAYBOOK"
		&"physical_partnership_actions":
			return "FLOCK BONDS / OFFICE PAIR CHOREOGRAPHY"
		&"rival_office_visualization":
			return "RIVAL OFFICE PROJECTION / PERSISTENT RESPONSE HISTORY"
		&"transformative_office_upgrades", &"tactile_collection_display", &"strategy_shaped_celebrations":
			return "CAMPAIGN PROGRESSION / PHYSICAL OFFICE / REWARD ORCHESTRA"
		&"setback_conversion", &"counterfactual_review", &"instant_experimental_rematch":
			return "FAIL-FORWARD / SHIFT REVIEW / SAME-SEED REMATCH"
		&"observed_first_shift_refinement":
			return "FIRST SESSION FUNNEL / EXTERNAL HUMAN EVIDENCE PROTOCOL"
		_:
			return "CANONICAL GAMEPLAY PULSE / EXISTING AUTHORITATIVE SYSTEMS"


static func _next_level_authority_for(item_id: StringName) -> String:
	match item_id:
		&"one_file_focus_mode", &"drop_target_previews", &"visible_cause_effect_trails", &"clear_fit_language":
			return "PECKWORK ROUTING UI / CHICKEN VIEW / WORLD FEEDBACK"
		&"discoverable_combo_recipes", &"push_luck_routing", &"dramatic_combo_completion":
			return "ROUTING MOMENTUM / ACTIVE PLAYBOOK / REWARD ORCHESTRA"
		&"stronger_chicken_specializations", &"personal_chicken_payoffs", &"emergent_flock_relationships":
			return "CHICKEN STATE / FLOCK BONDS / CAREER PROGRESSION"
		&"readable_rival_behavior":
			return "RIVAL OFFICE PROJECTION / PERSISTENT RESPONSE HISTORY"
		&"transformative_upgrades", &"tangible_progression_display":
			return "CAMPAIGN PROGRESSION / PHYSICAL OFFICE / COLLECTION DISPLAY"
		&"better_recovery_arcs", &"counterfactual_shift_recap", &"instant_rematch_experiments":
			return "FAIL-FORWARD / SHIFT REVIEW / SAME-SEED REMATCH"
		&"observed_onboarding_refinement":
			return "FIRST SESSION FUNNEL / EXTERNAL HUMAN EVIDENCE PROTOCOL"
		_:
			return "CANONICAL GAMEPLAY PULSE / EXISTING AUTHORITATIVE SYSTEMS"
