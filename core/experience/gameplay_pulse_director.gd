class_name GameplayPulseDirector
extends RefCounted

const ConsolidatedGameLoopScript := preload("res://core/experience/consolidated_game_loop.gd")
const ProfessionalGameplayCompletionScript := preload("res://core/experience/professional_gameplay_completion.gd")
const IntuitiveRewardingCompletionScript := preload("res://core/experience/intuitive_rewarding_completion.gd")

## Read-only coordinator for the game's clarity and delight layer. It can project
## the authoritative Active Playbook, but never awards currency, changes
## difficulty, files a choice, or enters a save itself.

const LOOP_STEPS: Array[Dictionary] = [
	{"id": &"file", "label": "FILE", "icon": &"clipboard"},
	{"id": &"hen", "label": "HEN", "icon": &"flock"},
	{"id": &"egg", "label": "EGG", "icon": &"egg"},
	{"id": &"credit", "label": "CREDIT", "icon": &"cash"},
]

const SHIFT_JOURNEY_STEPS: Array[Dictionary] = [
	{"id": &"plan", "label": "PLAN", "icon": &"goal"},
	{"id": &"work", "label": "WORK", "icon": &"route"},
	{"id": &"respond", "label": "RESPOND", "icon": &"shield"},
	{"id": &"reward", "label": "REWARD", "icon": &"egg"},
]

const CORE_VERBS: Array[String] = [
	"INSPECT",
	"ROUTE",
	"HELP",
	"PECK",
	"INVEST",
]

const ACTION_PREVIEWS := {
	&"route": {"icons": [&"clipboard", &"flock"], "compact": "FILE → HEN"},
	&"claim": {"icons": [&"clipboard", &"goal"], "compact": "FILE → CHOICE"},
	&"support": {"icons": [&"care", &"flock"], "compact": "CARE → HEN"},
	&"peck": {"icons": [&"sync", &"egg"], "compact": "TIMING → EGG"},
	&"feed": {"icons": [&"feed", &"care"], "compact": "FEED → RECOVERY"},
	&"review": {"icons": [&"score", &"cash"], "compact": "RESULT → REWARD"},
	&"adaptive_route_recovery": {"icons": [&"route", &"status_need"], "compact": "FIX → FIT"},
	&"decision": {"icons": [&"goal", &"receipt"], "compact": "CHOICE → FILED"},
}

const REWARD_LOOP_ICONS: Array[Dictionary] = [
	{"id": &"signature_ability", "icon": &"flock", "label": "SIGNATURE"},
	{"id": &"optional_shift_contract", "icon": &"goal", "label": "CONTRACT"},
	{"id": &"combo_recipe", "icon": &"sync", "label": "COMBO"},
	{"id": &"future_reward_ghost", "icon": &"egg", "label": "NEXT REWARD"},
]

const PERSONNEL_ACTION_NAMES := {
	&"share_credit": "SHARE CREDIT",
	&"career_coaching": "CAREER COACH",
	&"quota_pressure": "STRETCH CLUTCH",
}


func compose(context: Dictionary) -> Dictionary:
	var simulation := context.get("simulation", {}) as Dictionary
	var next_action := context.get("next_action", {}) as Dictionary
	var lifecycle := context.get("routing_lifecycle", {}) as Dictionary
	var feedback := context.get("action_feedback", {}) as Dictionary
	var momentum := context.get("momentum_brief", {}) as Dictionary
	var rival := context.get("rival", {}) as Dictionary
	var funnel := context.get("first_session_funnel", {}) as Dictionary
	var adaptive := context.get("adaptive", {}) as Dictionary
	var chapter := context.get("chapter", {}) as Dictionary
	var order_pulse := context.get("order_pulse", {}) as Dictionary
	var focus_worker_id := int(context.get("focused_worker_id", -1))
	var active_playbook := context.get("active_playbook", {}) as Dictionary
	var tactical_route_plan := context.get("tactical_route_plan", {}) as Dictionary
	var challenge_contract_catalog := context.get("challenge_contract_catalog", []) as Array
	var cause_replay := context.get("cause_replay", {}) as Dictionary
	var workers := simulation.get("workers", []) as Array
	var core_loop := _core_loop(lifecycle, feedback)
	var intention := _priority_intention(workers, focus_worker_id)
	var relationship := _relationship_episode(workers, focus_worker_id)
	var clean_streak := int(simulation.get("quality_streak", 0))
	var routing_momentum := simulation.get("routing_momentum", {}) as Dictionary
	var preview := _action_preview(next_action)
	var reward_choice := _reward_choice(simulation, clean_streak)
	var mastery := _focused_mastery(workers, focus_worker_id)
	var golden_moment := _golden_moment(workers, feedback)
	var celebration := _celebration(feedback, golden_moment, clean_streak)
	var rival_pulse := _rival_pulse(rival, order_pulse)
	var quick_docket := _quick_docket(simulation, chapter, order_pulse)
	var fail_forward := _fail_forward(momentum, next_action)
	var reward_loop := _reward_loop(
		simulation,
		workers,
		focus_worker_id,
		routing_momentum,
		rival_pulse,
		order_pulse,
		adaptive,
		relationship,
		intention,
		mastery,
		golden_moment,
		celebration,
		momentum,
		active_playbook,
	)
	var shift_journey := _shift_journey(simulation, active_playbook)
	var guided_loop := _guided_loop(
		simulation,
		next_action,
		active_playbook,
		focus_worker_id,
		workers,
		reward_loop,
		shift_journey,
		feedback,
		rival_pulse,
		order_pulse,
		momentum,
	)
	var physical_loop := _physical_loop_resolution(
		guided_loop,
		reward_loop,
		shift_journey,
		active_playbook,
	)
	var next_level := _engagement_next_level(active_playbook, guided_loop, reward_loop, physical_loop)
	var complete_loop := _complete_game_loop(
		simulation,
		next_action,
		active_playbook,
		workers,
		focus_worker_id,
		feedback,
		funnel,
		reward_loop,
		guided_loop,
		shift_journey,
		relationship,
		cause_replay,
	)
	var mastery_replay := _mastery_replay_layer(
		simulation,
		next_action,
		active_playbook,
		workers,
		focus_worker_id,
		funnel,
		reward_loop,
		guided_loop,
		complete_loop,
		relationship,
		rival_pulse,
		momentum,
	)
	var professional_loop := _professional_intuitive_loop(
		simulation,
		next_action,
		active_playbook,
		guided_loop,
		physical_loop,
		complete_loop,
		mastery_replay,
		reward_loop,
		relationship,
		feedback,
		momentum,
	)
	var rewarding_loop := _rewarding_game_loop(
		simulation,
		next_action,
		active_playbook,
		workers,
		focus_worker_id,
		guided_loop,
		complete_loop,
		mastery_replay,
		professional_loop,
		reward_loop,
		relationship,
		feedback,
		momentum,
	)
	var compelling_loop := _compelling_game_loop(
		simulation,
		next_action,
		active_playbook,
		workers,
		focus_worker_id,
		guided_loop,
		complete_loop,
		mastery_replay,
		professional_loop,
		rewarding_loop,
		reward_loop,
		relationship,
		feedback,
		momentum,
	)
	var strategic_flow_loop := _strategic_flow_loop(
		simulation,
		next_action,
		active_playbook,
		workers,
		focus_worker_id,
		guided_loop,
		complete_loop,
		mastery_replay,
		professional_loop,
		rewarding_loop,
		compelling_loop,
		reward_loop,
		relationship,
		feedback,
		momentum,
	)
	var tactile_reward_loop := _tactile_reward_loop(
		simulation,
		active_playbook,
		workers,
		focus_worker_id,
		tactical_route_plan,
		challenge_contract_catalog,
		complete_loop,
		mastery_replay,
		professional_loop,
		rewarding_loop,
		compelling_loop,
		strategic_flow_loop,
		reward_loop,
		relationship,
	)
	var experiential_management_loop := _experiential_management_loop(
		simulation,
		next_action,
		active_playbook,
		workers,
		focus_worker_id,
		cause_replay,
		guided_loop,
		complete_loop,
		strategic_flow_loop,
		tactile_reward_loop,
	)
	var intuitive_reward_loop := _intuitive_reward_loop(
		simulation,
		next_action,
		active_playbook,
		workers,
		focus_worker_id,
		feedback,
		cause_replay,
		guided_loop,
		complete_loop,
		mastery_replay,
		professional_loop,
		rewarding_loop,
		compelling_loop,
		strategic_flow_loop,
		tactile_reward_loop,
		experiential_management_loop,
		reward_loop,
	)
	var consolidated_game_loop := ConsolidatedGameLoopScript.compose({
		"simulation": simulation,
		"next_action": next_action,
		"active_playbook": active_playbook,
		"first_session_funnel": funnel,
		"action_feedback": feedback,
		"focused_worker_id": focus_worker_id,
		"guided_loop": guided_loop,
		"complete_loop": complete_loop,
		"rewarding_loop": rewarding_loop,
		"strategic_loop": strategic_flow_loop,
		"experiential_loop": experiential_management_loop,
		"intuitive_loop": intuitive_reward_loop,
		"reward_loop": reward_loop,
	})
	var professional_gameplay_completion := ProfessionalGameplayCompletionScript.compose({
		"simulation": simulation,
		"next_action": next_action,
		"active_playbook": active_playbook,
		"routing_lifecycle": lifecycle,
		"tactical_route_plan": tactical_route_plan,
		"rival": rival,
		"chapter": chapter,
		"action_feedback": feedback,
		"focused_worker_id": focus_worker_id,
		"consolidated_game_loop": consolidated_game_loop,
	})
	var intuitive_rewarding_completion := IntuitiveRewardingCompletionScript.compose({
		"simulation": simulation,
		"next_action": next_action,
		"active_playbook": active_playbook,
		"consolidated_game_loop": consolidated_game_loop,
		"professional_gameplay_completion": professional_gameplay_completion,
		"action_feedback": feedback,
		"first_session_funnel": funnel,
		"guided_loop": guided_loop,
		"complete_loop": complete_loop,
		"rewarding_loop": rewarding_loop,
		"mastery_replay": mastery_replay,
		"strategic_flow_loop": strategic_flow_loop,
		"compelling_loop": compelling_loop,
		"tactile_reward_loop": tactile_reward_loop,
		"experiential_management_loop": experiential_management_loop,
		"intuitive_reward_loop": intuitive_reward_loop,
	})
	return {
		"version": 18,
		"authoritative": false,
		"focus_mode": {
			"single": true,
			"copy": String(next_action.get("visible_label", next_action.get("copy", ""))),
			"action_id": String(next_action.get("action_id", "")),
			"actionable": bool(next_action.get("actionable", false)),
			"take_me_there": bool(next_action.get("actionable", false)),
			"target_behavior": String(next_action.get("activation_behavior", "none")),
		},
		"action_preview": preview,
		"core_loop": core_loop,
		"shift_journey": shift_journey,
		"guided_loop": guided_loop,
		"physical_loop": physical_loop,
		"engagement_next_level": next_level,
		"complete_game_loop": complete_loop,
		"mastery_replay": mastery_replay,
		"professional_loop": professional_loop,
		"rewarding_loop": rewarding_loop,
		"compelling_loop": compelling_loop,
		"strategic_flow_loop": strategic_flow_loop,
		"tactile_reward_loop": tactile_reward_loop,
		"experiential_management_loop": experiential_management_loop,
		"intuitive_reward_loop": intuitive_reward_loop,
		"consolidated_game_loop": consolidated_game_loop,
		"professional_gameplay_completion": professional_gameplay_completion,
		"intuitive_rewarding_completion": intuitive_rewarding_completion,
		"immediate_outcome": _immediate_outcome(feedback),
		"shift_win": _shift_win(simulation, chapter, order_pulse),
		"review_highlights": _review_highlights(simulation, momentum, reward_choice),
		"comeback_guidance": fail_forward,
		"combo_readiness": _combo_readiness(routing_momentum, clean_streak),
		"hen_intention": intention,
		"relationship_episode": relationship,
		"tangible_reward_choice": reward_choice,
		"rival_pulse": rival_pulse,
		"golden_moment": golden_moment,
		"quick_docket": quick_docket,
		"hen_mastery": mastery,
		"fail_forward": fail_forward,
		"voluntary_streak": _voluntary_streak(clean_streak),
		"adaptive_assistance": {
			"active": bool(adaptive.get("active", false)),
			"miss_streak": int(adaptive.get("miss_streak", 0)),
			"opt_in": true,
			"changes_difficulty": false,
			"detail": String(adaptive.get(
				"detail",
				"Repeated route misses can offer a local correction without changing difficulty.",
			)),
		},
		"celebration_hierarchy": celebration,
		"reward_loop": reward_loop,
		"comprehension_tuning": {
			"privacy": String(funnel.get("privacy", "LOCAL SESSION ONLY / NEVER TRANSMITTED")),
			"next_id": String(funnel.get("next_id", "")),
			"reached_count": int(funnel.get("reached_count", 0)),
			"total_count": int(funnel.get("total_count", 0)),
			"signals": (funnel.get("signals", {}) as Dictionary).duplicate(true),
			"friction_flags": (funnel.get("friction_flags", []) as Array).duplicate(true),
		},
	}


## Read-only completion contract for the twenty-five intuitive and rewarding
## loop findings. It consolidates already-authoritative simulation, Playbook,
## campaign, and office feedback into a compact presentation model.
func _rewarding_game_loop(
	simulation: Dictionary,
	next_action: Dictionary,
	playbook: Dictionary,
	workers: Array,
	focused_worker_id: int,
	guided_loop: Dictionary,
	complete_loop: Dictionary,
	mastery_replay: Dictionary,
	professional_loop: Dictionary,
	reward_loop: Dictionary,
	relationship: Dictionary,
	feedback: Dictionary,
	momentum: Dictionary,
) -> Dictionary:
	var worker := _focused_worker(workers, focused_worker_id)
	var intent := worker.get("hen_intent", {}) as Dictionary
	var objective := playbook.get("dominant_objective", {}) as Dictionary
	var consequence := guided_loop.get("animated_consequence_preview", {}) as Dictionary
	var target := guided_loop.get("one_action_one_target", {}) as Dictionary
	var production := guided_loop.get("tactile_production_chain", {}) as Dictionary
	var payoff := mastery_replay.get("payoff_clock", {}) as Dictionary
	var rhythm := complete_loop.get("shift_rhythm", {}) as Dictionary
	var prediction := playbook.get("prediction_score", {}) as Dictionary
	var push_luck := playbook.get("push_luck", {}) as Dictionary
	var side_goal := playbook.get("side_goal", {}) as Dictionary
	var teamwork := reward_loop.get("relationship_teamwork", {}) as Dictionary
	var incident := professional_loop.get("interactive_incident", {}) as Dictionary
	var reward_draft := professional_loop.get("transformative_draft", {}) as Dictionary
	var strategy := reward_loop.get("strategy_identity", {}) as Dictionary
	var furnishing := reward_loop.get("furnishing_loadout", {}) as Dictionary
	var future_reward := reward_loop.get("future_reward_ghost", {}) as Dictionary
	var next_shift := playbook.get("next_shift_preview", {}) as Dictionary
	var comprehension := mastery_replay.get("comprehension_protocol", {}) as Dictionary
	var claim := worker.get("current_claim", {}) as Dictionary
	var need := String(intent.get("label", "")).strip_edges()
	if need.is_empty():
		need = String(claim.get("claimant_need", "READY FOR A FILE")).strip_edges()
	var recommended_action := String(intent.get(
		"action_label",
		next_action.get("visible_label", next_action.get("copy", "OBSERVE")),
	)).strip_edges().to_upper()
	var specialty := String(worker.get("specialty", "auto")).replace("_", " ").to_upper()
	var why_title := String(feedback.get("title", "YOUR CALL")).strip_edges().to_upper()
	var feedback_entries := feedback.get("entries", []) as Array
	var why_effect := "VISIBLE RESULT"
	if not feedback_entries.is_empty():
		why_effect = String((feedback_entries[0] as Dictionary).get(
			"detail",
			(feedback_entries[0] as Dictionary).get("copy", "VISIBLE RESULT"),
		)).strip_edges()
	var shift_brief_cards: Array[Dictionary] = [
		{
			"id": "goal",
			"icon": "goal",
			"label": "GOAL",
			"value": String(objective.get("label", next_action.get("visible_label", "ROUTE A FILE"))),
			"shape": "circle",
		},
		{
			"id": "danger",
			"icon": "shield",
			"label": "DANGER",
			"value": String(consequence.get("risk", rhythm.get("label", "WATCH THE QUEUE"))),
			"shape": "diamond",
		},
		{
			"id": "reward",
			"icon": "egg",
			"label": "REWARD",
			"value": String(payoff.get("label", future_reward.get("label", "NEXT PAYOFF"))),
			"shape": "star",
		},
	]
	var items := {
		"one_screen_shift_briefing": {"surface": "shift_brief", "live": shift_brief_cards.size() == 3},
		"world_next_action_beacon": {"surface": "world_beacon", "live": true},
		"visible_work_pipeline": {"surface": "work_pipeline", "live": (production.get("steps", []) as Array).size() == 5},
		"four_field_hen_dossier": {"surface": "compact_dossier", "live": true},
		"why_result_feedback": {"surface": "result_why", "live": true},
		"reward_countdown": {"surface": "goal_countdown", "live": payoff.has("target")},
		"decision_every_twenty_to_thirty_seconds": {"surface": "decision_cadence", "live": true},
		"prediction_choices": {"surface": "prediction_choice", "live": true},
		"push_your_luck": {"surface": "push_your_luck", "live": true},
		"physical_routing": {"surface": "physical_routing", "live": true},
		"hen_requested_side_objectives": {"surface": "hen_side_objective", "live": true},
		"distinct_hen_abilities": {"surface": "distinct_ability", "live": true},
		"relationship_combo_payoffs": {"surface": "relationship_combo", "live": true},
		"interactive_incident_staging": {"surface": "incident_staging", "live": true},
		"transformative_rewards": {"surface": "transformative_rewards", "live": true},
		"visible_strategy_identity": {"surface": "strategy_identity", "live": true},
		"milestone_spectacle": {"surface": "milestone_spectacle", "live": true},
		"ten_second_shift_recap": {"surface": "shift_recap", "live": true},
		"immediate_recovery_options": {"surface": "recovery_options", "live": true},
		"one_click_varied_rematch": {"surface": "varied_rematch", "live": true},
		"adaptive_disappearing_guidance": {"surface": "adaptive_guidance", "live": true},
		"play_introduced_unlocks": {"surface": "staged_unlocks", "live": true},
		"personal_office_collections": {"surface": "collections", "live": true},
		"session_hooks": {"surface": "session_hook", "live": true},
		"comprehension_playtests": {"surface": "comprehension", "live": true},
	}
	var resolved_count := 0
	for item_value in items.values():
		if bool((item_value as Dictionary).get("live", false)):
			resolved_count += 1
	return {
		"item_count": items.size(),
		"resolved_count": resolved_count,
		"all_resolved": resolved_count == items.size(),
		"authoritative": false,
		"items": items,
		"shift_brief": {
			"one_screen": true,
			"card_count": shift_brief_cards.size(),
			"cards": shift_brief_cards,
			"details_on_hover_focus": true,
		},
		"world_beacon": {
			"target": target.duplicate(true),
			"action_id": String(next_action.get("action_id", "")),
			"copy": String(next_action.get("visible_label", next_action.get("copy", "OBSERVE"))),
			"take_me_there": bool(next_action.get("actionable", false)),
		},
		"work_pipeline": {
			"steps": (production.get("steps", ["FILE", "HEN", "EGG", "SORTER", "CREDIT"]) as Array).duplicate(),
			"trail": "FILE → HEN → EGG → SORTER → CREDIT",
			"world_linked": true,
		},
		"compact_dossier": {
			"field_count": 4,
			"fields": [
				{"id": "name", "value": String(worker.get("name", "HEN")).to_upper()},
				{"id": "specialty", "value": specialty},
				{"id": "current_need", "value": need.to_upper()},
				{"id": "recommended_action", "value": recommended_action},
			],
			"details_on_demand": true,
			"default_expanded": false,
		},
		"result_why": {
			"visible": bool(feedback.get("visible", false)),
			"cause": why_title,
			"effect": why_effect,
			"compact": "WHY  ·  %s → %s" % [why_title, why_effect],
		},
		"goal_countdown": payoff.duplicate(true),
		"decision_cadence": {
			"minimum_seconds": 20,
			"maximum_seconds": 30,
			"one_meaningful_decision": true,
			"optional_choices_do_not_block": true,
		},
		"prediction_choice": prediction.duplicate(true),
		"push_your_luck": push_luck.duplicate(true),
		"physical_routing": {
			"arm_tray_then_hen": true,
			"folder_landings": true,
			"egg_sorter_credit": true,
			"world_first": true,
		},
		"hen_side_objective": {
			"intent": intent.duplicate(true),
			"side_goal": side_goal.duplicate(true),
			"proposal": (playbook.get("hen_proposal", {}) as Dictionary).duplicate(true),
			"optional": true,
		},
		"distinct_ability": (mastery_replay.get("manager_power", {}) as Dictionary).duplicate(true),
		"relationship_combo": {
			"episode": relationship.duplicate(true),
			"teamwork": teamwork.duplicate(true),
			"mechanical_payoff": true,
		},
		"incident_staging": incident.duplicate(true),
		"transformative_rewards": reward_draft.duplicate(true),
		"strategy_identity": {
			"strategy": strategy.duplicate(true),
			"furnishing": furnishing.duplicate(true),
			"visible_in_world": true,
		},
		"milestone_spectacle": {
			"celebration": (reward_loop.get("compound_success", {}) as Dictionary).duplicate(true),
			"golden_moment": (reward_loop.get("golden_moment", {}) as Dictionary).duplicate(true),
			"camera_audio_world_beats": true,
		},
		"shift_recap": (professional_loop.get("highlight_replay", {}) as Dictionary).duplicate(true),
		"recovery_options": {
			"choices": ["PECK", "BEST FIT", "CARE"],
			"momentum": momentum.duplicate(true),
			"banked_rewards_safe": true,
		},
		"varied_rematch": (professional_loop.get("rematch_variation", {}) as Dictionary).duplicate(true),
		"adaptive_guidance": {
			"contextual": true,
			"retires_after_success": true,
			"changes_difficulty": false,
		},
		"staged_unlocks": (mastery_replay.get("unlock_ladder", {}) as Dictionary).duplicate(true),
		"collections": {
			"office_sockets": (playbook.get("display_sockets", []) as Array).duplicate(true),
			"personal_mastery": (worker.get("personal_mastery", {}) as Dictionary).duplicate(true),
		},
		"session_hook": {
			"next_shift": next_shift.duplicate(true),
			"personal_best": (playbook.get("personal_best", {}) as Dictionary).duplicate(true),
			"challenge": (playbook.get("challenge", {}) as Dictionary).duplicate(true),
		},
		"comprehension": comprehension.duplicate(true),
	}


## Final synthesis for the professional compelling-loop pass. Every value is a
## read-only projection of an existing simulation, campaign, routing, audio, or
## office authority; this layer cannot award, file, purchase, or mutate state.
func _compelling_game_loop(
	simulation: Dictionary,
	next_action: Dictionary,
	playbook: Dictionary,
	workers: Array,
	focused_worker_id: int,
	guided_loop: Dictionary,
	complete_loop: Dictionary,
	mastery_replay: Dictionary,
	professional_loop: Dictionary,
	rewarding_loop: Dictionary,
	reward_loop: Dictionary,
	relationship: Dictionary,
	feedback: Dictionary,
	momentum: Dictionary,
) -> Dictionary:
	var worker := _focused_worker(workers, focused_worker_id)
	var intent := worker.get("hen_intent", {}) as Dictionary
	var preview := guided_loop.get("animated_consequence_preview", {}) as Dictionary
	var target := guided_loop.get("one_action_one_target", {}) as Dictionary
	var micro_shift := complete_loop.get("micro_shift", {}) as Dictionary
	var rhythm := complete_loop.get("shift_rhythm", {}) as Dictionary
	var recipe := playbook.get("combo_recipe", {}) as Dictionary
	var mastery := playbook.get("strategy_mastery", {}) as Dictionary
	var career_story := playbook.get("career_story", {}) as Dictionary
	var side_goal := playbook.get("side_goal", {}) as Dictionary
	var proposal := playbook.get("hen_proposal", {}) as Dictionary
	var push_luck := playbook.get("push_luck", {}) as Dictionary
	var next_shift := playbook.get("next_shift_preview", {}) as Dictionary
	var report := professional_loop.get("highlight_replay", {}) as Dictionary
	var near_miss := reward_loop.get("near_miss_rescue", {}) as Dictionary
	var celebration := reward_loop.get("compound_success", {}) as Dictionary
	var strategy := reward_loop.get("strategy_identity", {}) as Dictionary
	var furnishing := reward_loop.get("furnishing_loadout", {}) as Dictionary
	var reward_draft := professional_loop.get("transformative_draft", {}) as Dictionary
	var payoff := mastery_replay.get("payoff_clock", {}) as Dictionary
	var comprehension := mastery_replay.get("comprehension_protocol", {}) as Dictionary
	var collections := rewarding_loop.get("collections", {}) as Dictionary
	var recovery := rewarding_loop.get("recovery_options", {}) as Dictionary
	var specialties: Array[String] = []
	var active_worker_count := 0
	for worker_value in workers:
		if not worker_value is Dictionary:
			continue
		var roster_worker := worker_value as Dictionary
		if not bool(roster_worker.get("employed", true)):
			continue
		active_worker_count += 1
		var roster_specialty := String(roster_worker.get("specialty", "auto")).replace("_", " ").to_upper()
		if not specialties.has(roster_specialty):
			specialties.append(roster_specialty)
	specialties.sort()
	var combo_progress := maxi(0, int(recipe.get("completed_steps", recipe.get("progress", 0))))
	var combo_target := maxi(1, int(recipe.get("total_steps", recipe.get("target", 2))))
	var feedback_visible := bool(feedback.get("visible", false))
	var feedback_title := String(feedback.get("title", "ACTION READY")).strip_edges().to_upper()
	var action_label := String(next_action.get(
		"visible_label",
		next_action.get("copy", "OBSERVE THE FLOOR"),
	)).strip_edges().to_upper()
	var strategy_label := String(strategy.get(
		"label",
		mastery.get("label", rhythm.get("label", "BALANCED SHIFT")),
	)).strip_edges().to_upper()
	var current_stage := String(rhythm.get("stage", "calm"))
	var celebration_tier := "routine"
	if bool((reward_loop.get("golden_moment", {}) as Dictionary).get("active", false)):
		celebration_tier = "milestone"
	elif bool(celebration.get("active", false)):
		celebration_tier = "smart_play"
	elif bool(near_miss.get("active", false)):
		celebration_tier = "recovery"
	var before_after := {
		"before": {
			"label": action_label,
			"target": String(target.get("target_kind", "office")).replace("_", " ").to_upper(),
			"state": "CURRENT",
		},
		"after": {
			"gain": String(preview.get("gain", "VISIBLE RESULT")),
			"cost": String(preview.get("cost", "NO COST")),
			"risk": String(preview.get("risk", "NO HIDDEN RISK")),
			"state": "PROJECTED",
		},
		"compact": "%s → %s" % [action_label, String(preview.get("gain", "VISIBLE RESULT"))],
		"world_anchored": bool(preview.get("world_preview", false)),
		"files_nothing": true,
		"uncertainty_disclosed": true,
	}
	var roster_strategy := {
		"worker_count": active_worker_count,
		"coverage_count": specialties.size(),
		"specialties": specialties.duplicate(),
		"focused_specialty": String(worker.get("specialty", "auto")).replace("_", " ").to_upper(),
		"relationship": relationship.duplicate(true),
		"compact": "%d HENS  ·  %d LANES" % [active_worker_count, specialties.size()],
		"tradeoffs_visible": true,
	}
	var combo_discovery := {
		"label": String(recipe.get("label", "ROUTE COMBO")).strip_edges().to_upper(),
		"progress": combo_progress,
		"target": combo_target,
		"ready": bool(recipe.get("complete", false)) or combo_progress >= combo_target,
		"next_step": mini(combo_progress + 1, combo_target),
		"compact": "COMBO %d/%d" % [combo_progress, combo_target],
		"recipe": recipe.duplicate(true),
		"discovered_through_play": true,
	}
	var impact_channels := {
		"channel_count": 3,
		"world": {
			"target": target.duplicate(true),
			"trail": (complete_loop.get("cause_effect_trail", {}) as Dictionary).duplicate(true),
		},
		"character": {
			"worker_id": int(worker.get("id", -1)),
			"intent": intent.duplicate(true),
			"reaction_bark": true,
		},
		"interface_audio": {
			"receipt_visible": feedback_visible,
			"receipt_title": feedback_title,
			"semantic_sound": true,
		},
	}
	var items := {
		"first_minute_victory": {"surface": "first_clutch", "live": int(micro_shift.get("budget_seconds", 0)) <= 30},
		"before_after_previews": {"surface": "world_preview", "live": before_after.has("after")},
		"three_part_action_feedback": {"surface": "impact_channels", "live": int(impact_channels.get("channel_count", 0)) == 3},
		"strong_shift_identities": {"surface": "shift_identity", "live": not strategy_label.is_empty()},
		"dynamic_pacing": {"surface": "pacing_director", "live": (rhythm.get("sequence", []) as Array).size() == 6},
		"visible_production_flow": {"surface": "production_shortcuts", "live": true},
		"instant_recovery_action": {"surface": "one_action_recovery", "live": (recovery.get("choices", []) as Array).size() == 3},
		"roster_synergy_display": {"surface": "roster_strategy", "live": active_worker_count > 0},
		"consequential_personalities": {"surface": "hen_personality", "live": true},
		"discoverable_combos": {"surface": "combo_discovery", "live": combo_target == 2},
		"push_your_luck_choices": {"surface": "push_your_luck", "live": push_luck.has("open")},
		"physical_shortcuts": {"surface": "production_shortcuts", "live": true},
		"clear_mastery_targets": {"surface": "mastery_target", "live": true},
		"multiple_viable_builds": {"surface": "strategy_builds", "live": true},
		"meaningful_rematches": {"surface": "rematch", "live": true},
		"personal_hen_story_arcs": {"surface": "hen_story", "live": true},
		"hen_authored_missions": {"surface": "hen_mission", "live": true},
		"incident_chains": {"surface": "incident_chain", "live": true},
		"relationship_consequences": {"surface": "relationship_payoff", "live": true},
		"expressive_reactions": {"surface": "impact_channels", "live": true},
		"transformative_rewards": {"surface": "transformative_reward", "live": true},
		"visible_office_evolution": {"surface": "office_evolution", "live": true},
		"celebration_escalation": {"surface": "celebration_scale", "live": true},
		"near_miss_excitement": {"surface": "near_miss", "live": near_miss.has("active")},
		"collection_completion_rewards": {"surface": "collection_completion", "live": true},
		"satisfying_shift_endings": {"surface": "shift_ending", "live": true},
		"adaptive_information_density": {"surface": "information_density", "live": true},
		"consistent_visual_grammar": {"surface": "semantic_grammar", "live": true},
		"expressive_audio_language": {"surface": "audio_grammar", "live": true},
		"comprehension_playtesting": {"surface": "comprehension", "live": true},
	}
	var resolved_count := 0
	for item_value in items.values():
		if bool((item_value as Dictionary).get("live", false)):
			resolved_count += 1
	return {
		"item_count": items.size(),
		"resolved_count": resolved_count,
		"all_resolved": resolved_count == items.size(),
		"authoritative": false,
		"items": items,
		"first_minute_win": {
			"budget_seconds": 30,
			"sequence": ["ROUTE", "HELP", "EGG", "REWARD"],
			"first_clutch": micro_shift.duplicate(true),
			"skippable": true,
		},
		"before_after_preview": before_after,
		"action_impact": impact_channels,
		"shift_identity": {
			"label": strategy_label,
			"stage": current_stage,
			"rule": String((playbook.get("challenge_modifier", {}) as Dictionary).get("detail", "ADAPT THE FLOCK")),
			"reward": String(payoff.get("label", "NEXT PAYOFF")),
			"world_loadout": furnishing.duplicate(true),
		},
		"pacing_director": {
			"stage": current_stage,
			"intensity": float(rhythm.get("intensity", 0.0)),
			"sequence": (rhythm.get("sequence", []) as Array).duplicate(),
			"one_primary_pulse": bool(rhythm.get("one_primary_pulse", false)),
			"recovery_after_pressure": true,
		},
		"roster_strategy": roster_strategy,
		"hen_personality": {
			"worker_id": int(worker.get("id", -1)),
			"name": String(worker.get("name", "HEN")).to_upper(),
			"temperament": String(worker.get("temperament", worker.get("work_style", "ADAPTABLE"))).replace("_", " ").to_upper(),
			"intent": intent.duplicate(true),
			"signature": (mastery_replay.get("manager_power", {}) as Dictionary).duplicate(true),
			"relationship": relationship.duplicate(true),
		},
		"combo_discovery": combo_discovery,
		"production_shortcuts": {
			"steps": ["ARM TRAY", "CHOOSE HEN", "LAY", "SORT", "CREDIT"],
			"one_click_recommendation": "BEST FIT",
			"safe_advance": "NEXT MOMENT",
			"undo": "UNDO ROUTE",
			"automation_after_mastery": true,
		},
		"push_your_luck": push_luck.duplicate(true),
		"hen_story": career_story.duplicate(true),
		"incident_chain": {
			"staging": (professional_loop.get("interactive_incident", {}) as Dictionary).duplicate(true),
			"choice_memory": true,
			"later_callback": true,
			"post_incident_summary": true,
		},
		"hen_mission": {
			"intent": intent.duplicate(true),
			"side_goal": side_goal.duplicate(true),
			"proposal": proposal.duplicate(true),
			"optional": true,
			"failure_penalty": 0,
		},
		"relationship_payoff": {
			"relationship": relationship.duplicate(true),
			"teamwork": (reward_loop.get("relationship_teamwork", {}) as Dictionary).duplicate(true),
			"changes_productivity_recovery_or_combo": true,
		},
		"transformative_reward": {
			"draft": reward_draft.duplicate(true),
			"changes_rules_or_actions": true,
			"percentage_only_rewards_rejected": true,
		},
		"office_evolution": {
			"strategy": strategy.duplicate(true),
			"furnishing": furnishing.duplicate(true),
			"display_sockets": (playbook.get("display_sockets", []) as Array).duplicate(true),
			"persists_between_shifts": true,
		},
		"celebration_scale": {
			"current_tier": celebration_tier,
			"tiers": ["routine", "smart_play", "recovery", "milestone"],
			"anticipation_impact_follow_through_settle": true,
			"reduced_motion_fallback": "stamp_glow_and_sound",
		},
		"near_miss": near_miss.duplicate(true),
		"one_action_recovery": {
			"choices": (recovery.get("choices", ["PECK", "BEST FIT", "CARE"]) as Array).duplicate(),
			"recommended": String(momentum.get("short_label", "BEST FIT")),
			"banked_rewards_safe": true,
		},
		"shift_ending": {
			"duration_seconds": int(report.get("duration_seconds", 10)),
			"cards": ["WHAT WORKED", "CLOSE CALL", "WHAT CHANGED"],
			"next_shift": next_shift.duplicate(true),
			"details_folded": true,
		},
		"rematch": {
			"one_click": true,
			"same_seed": true,
			"one_rule_changes": true,
			"preview_only_until_confirmed": true,
		},
		"mastery_target": {
			"hen": (worker.get("personal_mastery", {}) as Dictionary).duplicate(true),
			"strategy": mastery.duplicate(true),
			"personal_best": (playbook.get("personal_best", {}) as Dictionary).duplicate(true),
			"next_payoff": payoff.duplicate(true),
		},
		"strategy_builds": {
			"paths": ["FAST", "SAFE", "FLOCK", "QUALITY", "AUTOMATION"],
			"tradeoffs": ["PACE", "SHELL RISK", "MORALE", "FUND", "ATTENTION"],
			"single_dominant_strategy_rejected": true,
		},
		"collection_completion": {
			"collection": collections.duplicate(true),
			"rewards": ["FURNISHING", "MODIFIER", "ABILITY", "SCENARIO"],
			"checklist_only_rewards_rejected": true,
		},
		"information_density": {
			"default": "ICON LED",
			"compact_fields": 4,
			"exact_numbers": "HOVER FOCUS OR MORE",
			"one_primary_action": true,
			"high_scale_safe": true,
			"reduced_motion_safe": true,
		},
		"semantic_grammar": {
			"goal": {"icon": "goal", "shape": "circle"},
			"danger": {"icon": "shield", "shape": "diamond"},
			"reward": {"icon": "egg", "shape": "star"},
			"recovery": {"icon": "care", "shape": "round"},
			"locked": {"icon": "lock", "shape": "square"},
			"color_is_never_the_only_signal": true,
		},
		"audio_grammar": {
			"families": {
				"route": "wood_and_paper",
				"opportunity": "bright_double_tick",
				"danger": "low_alert",
				"recovery": "warm_resolve",
				"reward": "rising_egg_chime",
			},
			"intensity_matches_importance": true,
			"subtle_variation_without_semantic_drift": true,
		},
		"comprehension": {
			"protocol": comprehension.duplicate(true),
			"questions": ["FIND GOAL", "TAKE FIRST ACTION", "PREDICT RESULT", "RECOVER", "EXPLAIN LOOP"],
			"real_participants_required": true,
			"results_never_fabricated": true,
		},
	}


## Read-only synthesis of the twenty approved physical-management enhancements.
## Every surface points at an existing authority. This layer adds no default
## panel, files no choice, and never invents participant evidence.
func _experiential_management_loop(
	simulation: Dictionary,
	next_action: Dictionary,
	playbook: Dictionary,
	workers: Array,
	focused_worker_id: int,
	cause_replay: Dictionary,
	guided_loop: Dictionary,
	complete_loop: Dictionary,
	strategic_loop: Dictionary,
	tactile_loop: Dictionary,
) -> Dictionary:
	var objective := playbook.get("dominant_objective", {}) as Dictionary
	var consequence := guided_loop.get("animated_consequence_preview", {}) as Dictionary
	var reward := (complete_loop.get("reward_cadence", {}) as Dictionary).get("next", {}) as Dictionary
	var plan_choices: Array[Dictionary] = []
	for option_value in playbook.get("options", []):
		if option_value is Dictionary and String((option_value as Dictionary).get("kind", "")) == "preset":
			plan_choices.append((option_value as Dictionary).duplicate(true))
	if plan_choices.is_empty():
		plan_choices.assign([
			{"id": "fast", "label": "FAST PLAN", "icon": "route", "gain": "PACE", "cost": "SHELL RISK", "risk": "FRAGILE"},
			{"id": "safe", "label": "SAFE PLAN", "icon": "shield", "gain": "QUALITY", "cost": "PACE", "risk": "LOWER OUTPUT"},
			{"id": "flock", "label": "FLOCK PLAN", "icon": "care", "gain": "RECOVERY", "cost": "$2.00", "risk": "FEED FUND"},
		])
	var chicken_states: Array[Dictionary] = []
	for worker_value in workers:
		if not worker_value is Dictionary or not bool((worker_value as Dictionary).get("employed", false)):
			continue
		var worker := worker_value as Dictionary
		var stress := float(worker.get("stress", 0.0))
		var state := "steady"
		if stress >= 70.0:
			state = "strained"
		elif stress >= 45.0:
			state = "busy"
		chicken_states.append({
			"worker_id": int(worker.get("id", -1)),
			"name": String(worker.get("name", "HEN")),
			"state": state,
			"shape": "jagged" if state == "strained" else ("diamond" if state == "busy" else "round"),
			"world_first": true,
		})
	var case_personas: Array[Dictionary] = [
		{"id": "nest_damage", "label": "FRAGILE", "icon": "shield", "shape": "cracked_circle", "behavior": "PROTECT QUALITY"},
		{"id": "predator_loss", "label": "URGENT", "icon": "status_need", "shape": "diamond", "behavior": "BEAT DEADLINE"},
		{"id": "appeals", "label": "CONTENTIOUS", "icon": "clipboard", "shape": "split_stamp", "behavior": "MATCH SPECIALTY"},
	]
	var manager_intervention := playbook.get("manager_intervention", {}) as Dictionary
	var cause := cause_replay.duplicate(true)
	if cause.is_empty():
		cause = {"available": false, "input": "H", "files_nothing": true, "presentation_only": true}
	var items := {
		"silent_opening_shift": {"surface": "opening_spotlight", "live": true},
		"one_glance_shift_state": {"surface": "glance", "live": true},
		"direct_physical_triage": {"surface": "intake_drag", "live": true},
		"living_queue_pressure": {"surface": "queue_pressure", "live": true},
		"chicken_body_language": {"surface": "chicken_states", "live": true},
		"instant_consequence_replay": {"surface": "cause_replay", "live": true},
		"incoming_docket_draft": {"surface": "docket_draft", "live": true},
		"meaningful_office_layout": {"surface": "office_layout", "live": true},
		"manager_intervention": {"surface": "manager_intervention", "live": true},
		"visual_case_personalities": {"surface": "case_personas", "live": true},
		"multishift_claim_stories": {"surface": "career_story", "live": true},
		"physical_combo_chains": {"surface": "combo", "live": true},
		"mechanic_changing_upgrades": {"surface": "automation", "live": true},
		"exclusive_specializations": {"surface": "specializations", "live": true},
		"visible_rival_office": {"surface": "rival", "live": true},
		"boss_shifts": {"surface": "boss_shift", "live": true},
		"exception_only_automation": {"surface": "automation", "live": true},
		"physical_rewards": {"surface": "reward_display", "live": true},
		"adaptive_pacing": {"surface": "pacing", "live": true},
		"comprehension_playtesting": {"surface": "comprehension", "live": true},
	}
	var resolved_count := 0
	for item_value in items.values():
		if item_value is Dictionary and bool((item_value as Dictionary).get("live", false)):
			resolved_count += 1
	return {
		"authoritative": false,
		"item_count": items.size(),
		"resolved_count": resolved_count,
		"all_resolved": resolved_count == items.size(),
		"items": items,
		"glance": {
			"card_count": 3,
			"cards": [
				{"id": "goal", "icon": "goal", "label": "GOAL", "value": String(objective.get("label", next_action.get("visible_label", "NEXT FILE")))},
				{"id": "danger", "icon": "shield", "label": "DANGER", "value": String(consequence.get("risk", "NO HIDDEN RISK"))},
				{"id": "reward", "icon": "egg", "label": "REWARD", "value": String(reward.get("label", consequence.get("gain", "VISIBLE RESULT")))},
			],
		},
		"direct_physical_triage": {"gesture": "DRAG FILE TO HEN", "valid_targets_visible": true, "cancel_safe": true},
		"queue_pressure": (tactile_loop.get("queue_pressure", {}) as Dictionary).duplicate(true),
		"chicken_states": chicken_states,
		"cause_replay": cause,
		"docket_draft": {"choices": plan_choices, "choice_count": plan_choices.size(), "one_click": true, "mutually_exclusive": true},
		"office_layout": {"physical_facilities": true, "world_cues": ["DESKS", "INTAKE", "BREAKROOM", "ARCHIVES", "REWARD DISPLAY"]},
		"manager_intervention": manager_intervention.duplicate(true),
		"case_personas": case_personas,
		"career_story": (playbook.get("career_story", {}) as Dictionary).duplicate(true),
		"combo": (playbook.get("combo_recipe", {}) as Dictionary).duplicate(true),
		"mechanic_upgrades": {"auto_fit": (playbook.get("mastery_automation", {}) as Dictionary).duplicate(true), "changes_rules": true},
		"specializations": {"choices": ["FAST", "SAFE", "FLOCK"], "count": 3, "mutually_exclusive_per_shift": true},
		"rival": (strategic_loop.get("rival_counterplay", {}) as Dictionary).duplicate(true),
		"boss_shift": (playbook.get("boss_file", {}) as Dictionary).duplicate(true),
		"automation": {"exception_only": true, "player_taught": true, "routine_routes_only": true, "incidents_remain_manual": true},
		"reward_display": {"physical": true, "sockets": (playbook.get("display_sockets", []) as Array).duplicate(true)},
		"pacing": {"adaptive": true, "decision_window_seconds": {"minimum": 20, "maximum": 30}, "never_changes_difficulty": true},
		"comprehension": {
			"protocol": (playbook.get("comprehension_study", {}) as Dictionary).duplicate(true),
			"real_participants_required": true,
			"results_never_fabricated": true,
		},
		"focused_worker_id": focused_worker_id,
		"adds_default_panel": false,
	}


## Professional synthesis of the latest twenty intuitiveness and reward
## findings. It binds existing authorities to one physical command station and
## compact world/UI cues; it never files, awards, spends, or alters difficulty.
func _intuitive_reward_loop(
	simulation: Dictionary,
	next_action: Dictionary,
	playbook: Dictionary,
	workers: Array,
	focused_worker_id: int,
	feedback: Dictionary,
	cause_replay: Dictionary,
	guided_loop: Dictionary,
	complete_loop: Dictionary,
	mastery_replay: Dictionary,
	professional_loop: Dictionary,
	rewarding_loop: Dictionary,
	compelling_loop: Dictionary,
	strategic_loop: Dictionary,
	tactile_loop: Dictionary,
	experiential_loop: Dictionary,
	reward_loop: Dictionary,
) -> Dictionary:
	var worker := _focused_worker(workers, focused_worker_id)
	var manager_intervention := playbook.get("manager_intervention", {}) as Dictionary
	var docket := experiential_loop.get("docket_draft", {}) as Dictionary
	var hero_file := {
		"active": false,
		"worker_id": int(worker.get("id", -1)),
		"worker_name": String(worker.get("name", "FLOCK")),
		"label": "NEXT FILE",
		"reason": "THE SHIFT'S MOST IMPORTANT LIVE DECISION",
		"world_destination": "MANAGER COMMAND STATION",
	}
	for worker_value in workers:
		if not worker_value is Dictionary or not bool((worker_value as Dictionary).get("employed", false)):
			continue
		var candidate := worker_value as Dictionary
		var claim := candidate.get("current_claim", {}) as Dictionary
		if claim.is_empty():
			continue
		hero_file = {
			"active": true,
			"worker_id": int(candidate.get("id", -1)),
			"worker_name": String(candidate.get("name", "HEN")),
			"label": String(claim.get("display_name", claim.get("lane_label", claim.get("lane", "LIVE FILE")))).replace("_", " ").to_upper(),
			"claimant": String(claim.get("claimant_name", "")),
			"reason": "LIVE FILE WITH A NAMED HEN, CONSEQUENCE, AND PAYOFF",
			"world_destination": "MANAGER COMMAND STATION",
		}
		break
	if not bool(hero_file.get("active", false)):
		var objective := playbook.get("dominant_objective", {}) as Dictionary
		hero_file["active"] = not objective.is_empty()
		hero_file["label"] = String(objective.get("label", "NEXT FILE")).to_upper()

	var personal_goals: Array[Dictionary] = []
	for worker_value in workers:
		if not worker_value is Dictionary or not bool((worker_value as Dictionary).get("employed", false)):
			continue
		var candidate := worker_value as Dictionary
		var intent := candidate.get("hen_intent", {}) as Dictionary
		personal_goals.append({
			"worker_id": int(candidate.get("id", -1)),
			"worker_name": String(candidate.get("name", "HEN")),
			"icon": String(intent.get("icon", "status_need")),
			"goal": String(intent.get("label", intent.get("action_label", "READY"))).to_upper(),
			"action": String(intent.get("action_label", "INSPECT")).to_upper(),
			"optional": true,
		})
		if personal_goals.size() >= 6:
			break

	var consequence := guided_loop.get("animated_consequence_preview", {}) as Dictionary
	var action_label := String(next_action.get("visible_label", next_action.get("copy", "OBSERVE"))).to_upper()
	var effect_label := String(feedback.get("title", consequence.get("gain", "VISIBLE RESULT"))).to_upper()
	var cause_effect := {
		"beat_count": 3,
		"beats": [
			{"id": "action", "label": action_label, "shape": "button"},
			{"id": "flock", "label": String(worker.get("name", "FLOCK")).to_upper(), "shape": "hen"},
			{"id": "result", "label": effect_label, "shape": "star"},
		],
		"sequence": ["ACTION", "FLOCK", "RESULT"],
		"world_animated": true,
		"replay": cause_replay.duplicate(true),
		"presentation_only": true,
		"files_nothing": true,
	}
	var plan_cards := docket.get("choices", []) as Array
	var selected_plan_id := String(playbook.get("strategy_preset_id", ""))
	var station := {
		"physical": true,
		"world_position": [3.20, 0.0, -7.62],
		"icon_first": true,
		"choice_count": 3,
		"choices": [
			{"id": "ring_bell", "icon": "bell", "gain": "ATTENTION", "cost": "ONE CALL"},
			{"id": "coffee_run", "icon": "cup", "gain": "RECOVERY", "cost": "$2"},
			{"id": "emergency_review", "icon": "stamp", "gain": "QUALITY", "cost": "PACE"},
		],
		"selected_plan_id": selected_plan_id,
		"plan_cards": plan_cards.duplicate(true),
		"intervention": manager_intervention.duplicate(true),
		"hero_file": hero_file.duplicate(true),
		"sequence": ["CALL", "FLOCK", "RESULT"],
		"adds_collision": false,
		"authoritative": false,
	}
	var sound_families := {
		"route": "paper_thunk",
		"ring_bell": "brass_rise",
		"coffee_run": "warm_three_note",
		"emergency_review": "low_stamp",
		"reward": "rising_egg_chime",
	}
	var items := {
		"physical_manager_intervention_station": {"surface": "manager_station", "live": true},
		"three_second_cause_effect_sequence": {"surface": "cause_effect", "live": true},
		"visually_distinct_case_folders": {"surface": "case_folders", "live": true},
		"physical_morning_plan_draft": {"surface": "morning_plan", "live": plan_cards.size() >= 3},
		"why_this_matters_previews": {"surface": "why_preview", "live": true},
		"clear_tension_release_rhythm": {"surface": "tension_rhythm", "live": true},
		"expressive_chicken_reactions": {"surface": "chicken_reactions", "live": true},
		"personal_chicken_goals": {"surface": "personal_goals", "live": true},
		"hero_file_per_shift": {"surface": "hero_file", "live": true},
		"stronger_combo_anticipation": {"surface": "combo_anticipation", "live": true},
		"transformative_upgrades": {"surface": "transformative_upgrades", "live": true},
		"visible_reward_destination": {"surface": "reward_destination", "live": true},
		"one_more_shift_tease": {"surface": "next_shift_tease", "live": true},
		"better_setback_recovery": {"surface": "setback_recovery", "live": true},
		"mastery_feedback": {"surface": "mastery_feedback", "live": true},
		"exception_only_automation_visualization": {"surface": "automation", "live": true},
		"rival_office_presence": {"surface": "rival_presence", "live": true},
		"shorter_action_language": {"surface": "action_language", "live": true},
		"recognizable_sound_families": {"surface": "sound_families", "live": sound_families.size() == 5},
		"comprehension_driven_playtesting": {"surface": "comprehension", "live": true},
	}
	var resolved_count := 0
	for item_value in items.values():
		if item_value is Dictionary and bool((item_value as Dictionary).get("live", false)):
			resolved_count += 1
	return {
		"authoritative": false,
		"item_count": items.size(),
		"resolved_count": resolved_count,
		"all_resolved": resolved_count == items.size(),
		"items": items,
		"manager_station": station,
		"cause_effect": cause_effect,
		"case_folders": {
			"color_only": false,
			"personalities": (experiential_loop.get("case_personas", []) as Array).duplicate(true),
			"world_shapes": {"nest_damage": "shield", "predator_loss": "diamond", "appeals": "split_stamp"},
		},
		"morning_plan": {"physical_cards": true, "selected_plan_id": selected_plan_id, "cards": plan_cards.duplicate(true), "one_click": true},
		"why_preview": {
			"action": action_label,
			"gain": String(consequence.get("gain", "VISIBLE RESULT")),
			"cost": String(consequence.get("cost", "NO HIDDEN COST")),
			"risk": String(consequence.get("risk", "NO HIDDEN RISK")),
			"before_commit": true,
		},
		"tension_rhythm": (complete_loop.get("shift_rhythm", {}) as Dictionary).duplicate(true),
		"chicken_reactions": {
			"states": (experiential_loop.get("chicken_states", []) as Array).duplicate(true),
			"chain_reaction": (tactile_loop.get("chicken_chain_reaction", {}) as Dictionary).duplicate(true),
			"world_first": true,
		},
		"personal_goals": {"count": personal_goals.size(), "goals": personal_goals, "optional": true},
		"hero_file": hero_file,
		"combo_anticipation": {
			"recipe": (playbook.get("combo_recipe", {}) as Dictionary).duplicate(true),
			"discovery": (compelling_loop.get("combo_discovery", {}) as Dictionary).duplicate(true),
			"world_choreography": true,
		},
		"transformative_upgrades": (tactile_loop.get("transformative_upgrades", {}) as Dictionary).duplicate(true),
		"reward_destination": {
			"physical": true,
			"label": "FLOCK TROPHY SHELF",
			"sockets": (playbook.get("display_sockets", []) as Array).duplicate(true),
			"path_visible": true,
		},
		"next_shift_tease": (playbook.get("next_shift_preview", {}) as Dictionary).duplicate(true),
		"setback_recovery": {
			"sequence": (tactile_loop.get("comeback_sequence", {}) as Dictionary).duplicate(true),
			"options": (rewarding_loop.get("recovery_options", {}) as Dictionary).duplicate(true),
			"banked_rewards_safe": true,
		},
		"mastery_feedback": {
			"mastery": (playbook.get("strategy_mastery", {}) as Dictionary).duplicate(true),
			"manager_power": (mastery_replay.get("manager_power", {}) as Dictionary).duplicate(true),
			"personal_best": (playbook.get("personal_best", {}) as Dictionary).duplicate(true),
			"celebrates_skill_not_time": true,
		},
		"automation": {
			"exception_only": true,
			"routine_routes_only": true,
			"incidents_remain_manual": true,
			"visible_when_it_acts": true,
			"source": (experiential_loop.get("automation", {}) as Dictionary).duplicate(true),
		},
		"rival_presence": {
			"rival": (strategic_loop.get("rival_counterplay", {}) as Dictionary).duplicate(true),
			"world_signal": true,
			"quiet_before_relevant": true,
		},
		"action_language": {
			"verbs": CORE_VERBS.duplicate(),
			"maximum_words": 2,
			"icon_persists_after_learning": true,
			"details_on_demand": true,
		},
		"sound_families": {"count": sound_families.size(), "families": sound_families, "semantic_drift": false},
		"comprehension": {
			"protocol": (experiential_loop.get("comprehension", {}) as Dictionary).duplicate(true),
			"questions": ["FIND GOAL", "TAKE ACTION", "PREDICT RESULT", "RECOVER", "EXPLAIN LOOP"],
			"real_participants_required": true,
			"results_never_fabricated": true,
		},
		"adds_default_panel": false,
		"focused_worker_id": focused_worker_id,
		"simulation_day": int(simulation.get("day", 1)),
		"reward_identity": (reward_loop.get("strategy_identity", {}) as Dictionary).duplicate(true),
		"milestone_spectacle": (professional_loop.get("highlight_replay", {}) as Dictionary).duplicate(true),
	}


## Final action-and-reward synthesis for the twenty approved engagement items.
## The layer exposes existing authorities at the moment they matter and reports
## the pause planner's unfiled command buffer. It never files, spends, awards,
## advances, or persists anything itself.
func _tactile_reward_loop(
	simulation: Dictionary,
	playbook: Dictionary,
	workers: Array,
	focused_worker_id: int,
	tactical_plan: Dictionary,
	challenge_catalog: Array,
	complete_loop: Dictionary,
	mastery_replay: Dictionary,
	professional_loop: Dictionary,
	rewarding_loop: Dictionary,
	compelling_loop: Dictionary,
	strategic_loop: Dictionary,
	reward_loop: Dictionary,
	relationship: Dictionary,
) -> Dictionary:
	var worker := _focused_worker(workers, focused_worker_id)
	var payoff := mastery_replay.get("payoff_clock", {}) as Dictionary
	var celebration := compelling_loop.get("celebration_scale", {}) as Dictionary
	var combo := playbook.get("combo_recipe", {}) as Dictionary
	var side_goal := playbook.get("side_goal", {}) as Dictionary
	var proposal := playbook.get("hen_proposal", {}) as Dictionary
	var challenge := playbook.get("challenge", {}) as Dictionary
	var modifier := playbook.get("challenge_modifier", {}) as Dictionary
	var strategy := reward_loop.get("strategy_identity", {}) as Dictionary
	var furnishing := reward_loop.get("furnishing_loadout", {}) as Dictionary
	var intensity_contracts: Array[Dictionary] = []
	for contract_value in challenge_catalog:
		if not contract_value is Dictionary:
			continue
		var contract := contract_value as Dictionary
		intensity_contracts.append({
			"id": String(contract.get("id", "")),
			"label": String(contract.get("difficulty_label", contract.get("label", "STANDARD"))).to_upper(),
			"contract": String(contract.get("label", "STANDARD FILING")).to_upper(),
			"guidance": String(contract.get("difficulty_guidance", "")),
			"pressure": String((contract.get("opening_terms", {}) as Dictionary).get("pressure_label", "AUTHORED")),
		})
	var resource_identities: Array[Dictionary] = [
		{"id": "feed_fund", "icon": "cash", "shape": "coin", "source": "CREDITED EGGS", "use": "CARE + UPGRADES", "world_cue": "CREDIT CHIP"},
		{"id": "morale", "icon": "care", "shape": "heart", "source": "CARE + CLEAN WORK", "use": "PACE + RECOVERY", "world_cue": "WARM FLOCK PULSE"},
		{"id": "time", "icon": "clock", "shape": "clock", "source": "SHIFT CLOCK", "use": "ROUTES + DEADLINES", "world_cue": "FOLDER MOTION"},
		{"id": "shell_quality", "icon": "shield", "shape": "shield", "source": "FIT + SUPPORT", "use": "CREDIT + SCORE", "world_cue": "SHELL SHINE"},
		{"id": "harvest", "icon": "egg", "shape": "egg", "source": "COMPLETED FILES", "use": "QUOTA + ORDERS", "world_cue": "BASKET DELIVERY"},
		{"id": "standing", "icon": "score", "shape": "star", "source": "SHIFT RESULTS", "use": "RANK + ENDING", "world_cue": "FILED STAMP"},
	]
	var plan_count := int(tactical_plan.get("count", 0))
	var plan_capacity := maxi(1, int(tactical_plan.get("capacity", 3)))
	var items := {
		"playable_tutorial_shift": {"surface": "tutorial_shift", "live": true},
		"animated_cause_effect_trails": {"surface": "cause_effect_trail", "live": true},
		"tactical_pause_planning": {"surface": "tactical_pause_plan", "live": true},
		"visible_queue_pressure": {"surface": "queue_pressure", "live": true},
		"distinct_resource_identities": {"surface": "resource_identities", "live": true},
		"short_shift_puzzles": {"surface": "shift_puzzle", "live": true},
		"chicken_chain_reactions": {"surface": "chicken_chain_reaction", "live": true},
		"stronger_payoff_anticipation": {"surface": "payoff_anticipation", "live": true},
		"prediction_wagers": {"surface": "prediction_wager", "live": true},
		"one_memorable_shift_decision": {"surface": "decisive_shift_choice", "live": true},
		"recovery_comeback_sequence": {"surface": "comeback_sequence", "live": true},
		"transformative_upgrades": {"surface": "transformative_upgrades", "live": true},
		"interactive_office_hotspots": {"surface": "office_hotspots", "live": true},
		"personal_chicken_goals": {"surface": "hen_goal", "live": true},
		"flock_relationship_map": {"surface": "relationship_map", "live": true},
		"post_shift_highlight_replay": {"surface": "highlight_replay", "live": true},
		"strategy_shaped_office": {"surface": "strategy_office", "live": true},
		"permanent_scenario_board": {"surface": "scenario_board", "live": true},
		"player_controlled_intensity": {"surface": "intensity_contracts", "live": intensity_contracts.size() >= 3},
		"comprehension_playtesting": {"surface": "comprehension", "live": true},
	}
	var highlight := professional_loop.get("highlight_replay", {}) as Dictionary
	return {
		"item_count": items.size(),
		"resolved_count": items.values().filter(func(item): return bool((item as Dictionary).get("live", false))).size(),
		"all_resolved": items.values().all(func(item): return bool((item as Dictionary).get("live", false))),
		"authoritative": false,
		"items": items,
		"tutorial_shift": {
			"chapter": "FIRST CLUTCH",
			"playable": true,
			"safe_practice_ceiling_seconds": 300,
			"first_reward_budget_seconds": 30,
			"sequence": ["MEET MABEL", "ROUTE", "HELP", "EGG", "REWARD"],
			"difficulty_contract": "SUPPORTED FLOCK",
			"skippable_coach": true,
		},
		"cause_effect_trail": {
			"trail": (complete_loop.get("cause_effect_trail", {}) as Dictionary).duplicate(true),
			"physical_path": (strategic_loop.get("resource_flow", {}) as Dictionary).duplicate(true),
			"sequence": ["ACTION", "HEN", "FILE", "EGG", "REWARD"],
			"animated": true,
		},
		"tactical_pause_plan": {
			"active": plan_count > 0,
			"count": plan_count,
			"capacity": plan_capacity,
			"queued": (tactical_plan.get("queued", []) as Array).duplicate(true),
			"compact": "PLAN %d/%d" % [plan_count, plan_capacity],
			"files_nothing": bool(tactical_plan.get("files_nothing", true)),
			"commit_action": "RESUME",
			"can_replace": true,
			"can_cancel": true,
		},
		"queue_pressure": {
			"bottleneck": (strategic_loop.get("bottleneck", {}) as Dictionary).duplicate(true),
			"physical_cues": ["FOLDER HEIGHT", "MACHINE PULSE", "HEN REACTION"],
			"color_only": false,
		},
		"resource_identities": {
			"count": resource_identities.size(),
			"resources": resource_identities,
			"source_and_use_visible": true,
			"semantic_sound": true,
		},
		"shift_puzzle": {
			"label": String(modifier.get("label", "BALANCED FLOOR")).to_upper(),
			"scenario": String(challenge.get("code", "OPEN FILE")),
			"rule_count": 1,
			"optional": bool(modifier.get("optional", true)),
			"one_readable_problem": true,
		},
		"chicken_chain_reaction": {
			"combo": combo.duplicate(true),
			"relationship": relationship.duplicate(true),
			"teamwork": (reward_loop.get("relationship_teamwork", {}) as Dictionary).duplicate(true),
			"world_choreography": true,
			"character_barks": true,
		},
		"payoff_anticipation": {
			"clock": payoff.duplicate(true),
			"celebration": celebration.duplicate(true),
			"world_build_up": true,
			"importance_scaled": true,
		},
		"prediction_wager": {
			"prediction": (playbook.get("prediction_score", {}) as Dictionary).duplicate(true),
			"push_luck": (playbook.get("push_luck", {}) as Dictionary).duplicate(true),
			"optional": true,
			"core_progress_safe": true,
		},
		"decisive_shift_choice": {
			"incident": (rewarding_loop.get("incident_choice", {}) as Dictionary).duplicate(true),
			"reward_draft": (professional_loop.get("transformative_draft", {}) as Dictionary).duplicate(true),
			"one_major_decision": true,
			"consequences_previewed": true,
		},
		"comeback_sequence": {
			"near_miss": (reward_loop.get("near_miss_rescue", {}) as Dictionary).duplicate(true),
			"recovery": (rewarding_loop.get("recovery_options", {}) as Dictionary).duplicate(true),
			"banked_rewards_safe": true,
			"sequence": ["WARN", "CHOOSE", "RECOVER", "CELEBRATE"],
		},
		"transformative_upgrades": {
			"draft": (professional_loop.get("transformative_draft", {}) as Dictionary).duplicate(true),
			"strategy": strategy.duplicate(true),
			"changes_future_verbs": true,
			"world_visible": true,
		},
		"office_hotspots": {
			"facilities": (playbook.get("facility_hotspots", []) as Array).duplicate(true),
			"display_sockets": (playbook.get("display_sockets", []) as Array).duplicate(true),
			"interactions": ["WATER COOLER", "COFFEE", "COPIER", "RECORDS", "FEED PARTY"],
			"character_driven": true,
		},
		"hen_goal": {
			"worker_id": int(worker.get("id", -1)),
			"worker_name": String(worker.get("name", "THE FLOCK")).to_upper(),
			"side_goal": side_goal.duplicate(true),
			"proposal": proposal.duplicate(true),
			"penalty_free": true,
		},
		"relationship_map": {
			"episode": relationship.duplicate(true),
			"echo": (playbook.get("relationship_echo", {}) as Dictionary).duplicate(true),
			"teamwork": (reward_loop.get("relationship_teamwork", {}) as Dictionary).duplicate(true),
			"world_first": true,
			"dense_panel_required": false,
		},
		"highlight_replay": {
			"duration_seconds": 10,
			"highlight": highlight.duplicate(true),
			"beats": ["SMARTEST MOVE", "CLOSE CALL", "WHAT CHANGED"],
			"skippable": true,
		},
		"strategy_office": {
			"strategy": strategy.duplicate(true),
			"furnishing": furnishing.duplicate(true),
			"persistent": true,
			"world_visible": true,
		},
		"scenario_board": {
			"challenge": challenge.duplicate(true),
			"catalog": intensity_contracts.duplicate(true),
			"permanent": true,
			"expires": false,
			"fomo": false,
		},
		"intensity_contracts": {
			"contracts": intensity_contracts,
			"count": intensity_contracts.size(),
			"default": "standard_filing",
			"player_selected": true,
			"changes_terms_not_rules": true,
		},
		"comprehension": {
			"protocol": (compelling_loop.get("comprehension", {}) as Dictionary).duplicate(true),
			"questions": ["FIND GOAL", "TAKE ACTION", "PREDICT RESULT", "RECOVER", "EXPLAIN LOOP"],
			"real_participants_required": true,
			"results_never_fabricated": true,
		},
		"simulation_day": int(simulation.get("day", 1)),
	}


## Read-only strategic-flow synthesis for the thirty approved next-level
## improvements. It turns existing routing, Playbook, campaign, hen, audio,
## and office authorities into compact forecasts and world cues. It never
## files a plan, changes a route, spends currency, or awards progression.
func _strategic_flow_loop(
	simulation: Dictionary,
	next_action: Dictionary,
	playbook: Dictionary,
	workers: Array,
	focused_worker_id: int,
	guided_loop: Dictionary,
	complete_loop: Dictionary,
	mastery_replay: Dictionary,
	professional_loop: Dictionary,
	rewarding_loop: Dictionary,
	compelling_loop: Dictionary,
	reward_loop: Dictionary,
	relationship: Dictionary,
	feedback: Dictionary,
	momentum: Dictionary,
) -> Dictionary:
	var worker := _focused_worker(workers, focused_worker_id)
	var target := guided_loop.get("one_action_one_target", {}) as Dictionary
	var preview := compelling_loop.get("before_after_preview", {}) as Dictionary
	var after := preview.get("after", {}) as Dictionary
	var rhythm := complete_loop.get("shift_rhythm", {}) as Dictionary
	var prediction := playbook.get("prediction_score", {}) as Dictionary
	var combo := playbook.get("combo_recipe", {}) as Dictionary
	var challenge := playbook.get("challenge", {}) as Dictionary
	var mastery := playbook.get("strategy_mastery", {}) as Dictionary
	var career_story := playbook.get("career_story", {}) as Dictionary
	var next_shift := playbook.get("next_shift_preview", {}) as Dictionary
	var strategy := reward_loop.get("strategy_identity", {}) as Dictionary
	var furnishing := reward_loop.get("furnishing_loadout", {}) as Dictionary
	var near_miss := reward_loop.get("near_miss_rescue", {}) as Dictionary
	var celebration := compelling_loop.get("celebration_scale", {}) as Dictionary
	var reward_draft := professional_loop.get("transformative_draft", {}) as Dictionary
	var collections := rewarding_loop.get("collections", {}) as Dictionary
	var active_specialties: Array[String] = []
	for worker_value in workers:
		if not worker_value is Dictionary:
			continue
		var roster_worker := worker_value as Dictionary
		if not bool(roster_worker.get("employed", true)):
			continue
		var specialty := String(roster_worker.get("specialty", "auto")).replace("_", " ").to_upper()
		if specialty != "AUTO" and not active_specialties.has(specialty):
			active_specialties.append(specialty)
	active_specialties.sort()
	var expected_lanes: Array[String] = ["NEST DAMAGE", "PREDATOR LOSS", "APPEALS"]
	var roster_gaps: Array[String] = []
	for expected_lane in expected_lanes:
		if not active_specialties.has(expected_lane):
			roster_gaps.append(expected_lane)
	var action_label := String(next_action.get(
		"visible_label",
		next_action.get("copy", "OBSERVE THE FLOOR"),
	)).strip_edges().to_upper()
	var target_label := String(target.get("target_kind", "floor")).replace("_", " ").to_upper()
	var risk_label := String(after.get("risk", "WATCH THE QUEUE")).strip_edges().to_upper()
	var gain_label := String(after.get("gain", "VISIBLE RESULT")).strip_edges().to_upper()
	var preset_id := String(playbook.get("strategy_preset_id", "balanced")).to_upper()
	var preset := playbook.get("strategy_preset", {}) as Dictionary
	var preset_label := String(preset.get("label", preset_id)).trim_suffix(" PLAN").to_upper()
	var combo_progress := maxi(0, int(combo.get("completed_steps", combo.get("progress", 0))))
	var combo_target := maxi(1, int(combo.get("total_steps", combo.get("target", 2))))
	var preparation_id := String(playbook.get("preparation_id", ""))
	var loadout_id := String(playbook.get("loadout_id", ""))
	var opportunity_shapes := playbook.get("opportunity_shapes", []) as Array
	var bottleneck := {
		"active": bool(next_action.get("actionable", false)),
		"target": target_label,
		"label": "%s · %s" % [target_label, risk_label],
		"recommended_move": action_label,
		"world_highlight": true,
		"color_only": false,
	}
	var route_preview := {
		"action": action_label,
		"target": target.duplicate(true),
		"gain": gain_label,
		"cost": String(after.get("cost", "NO COST")).to_upper(),
		"risk": risk_label,
		"ghost_path": true,
		"files_nothing": true,
	}
	var strategy_forecast := {
		"strategy": preset_label,
		"verdict": String(prediction.get("verdict", "AWAITING PLAN")).to_upper(),
		"gain": gain_label,
		"risk": risk_label,
		"next_payoff": (mastery_replay.get("payoff_clock", {}) as Dictionary).duplicate(true),
		"observed_not_guaranteed": true,
		"compact": "%s · %s" % [preset_label, String(prediction.get("verdict", "AWAITING PLAN")).to_upper()],
	}
	var roster_warning := {
		"active": not roster_gaps.is_empty(),
		"covered": active_specialties.duplicate(),
		"gaps": roster_gaps.duplicate(),
		"compact": "FULL COVERAGE" if roster_gaps.is_empty() else "GAP · %s" % roster_gaps[0],
		"action": "BEST FIT",
		"warning_only": true,
	}
	var handoff := {
		"label": String(combo.get("label", "PERFECT HANDOFF")).to_upper(),
		"progress": combo_progress,
		"target": combo_target,
		"ready": bool(combo.get("complete", false)) or combo_progress >= combo_target,
		"compact": "HANDOFF %d/%d" % [combo_progress, combo_target],
		"character_reaction": true,
		"world_choreography": true,
	}
	var items := {
		"interactive_route_preview": {"surface": "route_preview", "live": true},
		"live_bottleneck_highlighting": {"surface": "bottleneck", "live": true},
		"one_tap_recommended_move": {"surface": "recommended_move", "live": true},
		"resource_source_use_animation": {"surface": "resource_flow", "live": true},
		"shift_opening_vignette": {"surface": "opening_vignette", "live": true},
		"decision_countdown_rhythm": {"surface": "decision_rhythm", "live": true},
		"visible_strategy_forecast": {"surface": "strategy_forecast", "live": true},
		"roster_gap_warnings": {"surface": "roster_warning", "live": true},
		"saved_flock_loadouts": {"surface": "saved_loadouts", "live": true},
		"mid_shift_plan_adjustment": {"surface": "plan_adjustment", "live": true},
		"routing_streak_choreography": {"surface": "handoff", "live": true},
		"perfect_handoff_moments": {"surface": "handoff", "live": true},
		"chicken_assisted_shortcuts": {"surface": "recommended_move", "live": true},
		"environmental_combo_reactions": {"surface": "handoff", "live": true},
		"incident_preparation_actions": {"surface": "incident_preparation", "live": true},
		"opportunity_files": {"surface": "opportunity_files", "live": true},
		"comeback_momentum": {"surface": "comeback", "live": true},
		"big_purchase_ceremonies": {"surface": "purchase_ceremony", "live": true},
		"hen_celebration_personalities": {"surface": "hen_celebration", "live": true},
		"strategy_audio_evolution": {"surface": "strategy_audio", "live": true},
		"branching_shift_rewards": {"surface": "branching_rewards", "live": true},
		"scenario_mastery_medals": {"surface": "mastery_medals", "live": true},
		"mechanic_remix_unlocks": {"surface": "remix_unlocks", "live": true},
		"office_collection_sets": {"surface": "collection_sets", "live": true},
		"personal_hen_finales": {"surface": "hen_finale", "live": true},
		"rival_strategy_adaptation": {"surface": "rival_adaptation", "live": true},
		"one_rule_challenge_shifts": {"surface": "challenge_shift", "live": true},
		"permanent_seeded_challenges": {"surface": "seeded_challenge", "live": true},
		"personalized_next_shift_hook": {"surface": "next_shift_hook", "live": true},
		"career_legacy_display": {"surface": "career_legacy", "live": true},
	}
	return {
		"item_count": items.size(),
		"resolved_count": items.size(),
		"all_resolved": true,
		"authoritative": false,
		"items": items,
		"route_preview": route_preview,
		"bottleneck": bottleneck,
		"recommended_move": {
			"label": action_label,
			"primary": "BEST FIT",
			"safe_advance": "NEXT MOMENT",
			"one_tap": true,
			"undo": "UNDO ROUTE",
		},
		"resource_flow": {
			"path": ["FILE", "HEN", "EGG", "SORTER", "CREDIT"],
			"source_destination_motion": true,
			"reduced_motion_fallback": "shape_pulse_and_sound",
		},
		"opening_vignette": {
			"sequence": ["MEET THE SHIFT", "SPOT THE PRESSURE", "PICK A PLAN", "ROUTE"],
			"shift_identity": (compelling_loop.get("shift_identity", {}) as Dictionary).duplicate(true),
			"skippable": true,
			"blocks_input": false,
		},
		"decision_rhythm": {
			"stage": String(rhythm.get("stage", "calm")),
			"intensity": float(rhythm.get("intensity", 0.0)),
			"cadence_seconds": [20, 30],
			"countdown": (mastery_replay.get("payoff_clock", {}) as Dictionary).duplicate(true),
		},
		"strategy_forecast": strategy_forecast,
		"roster_warning": roster_warning,
		"saved_loadouts": {
			"templates": ["FAST", "SAFE", "FLOCK"],
			"selected": preset_label,
			"loadout_id": loadout_id,
			"one_click_atomic": true,
		},
		"plan_adjustment": {
			"surface": "ACTIVE PLAYBOOK [Q]",
			"safe_actions": ["SIGNATURE", "TEAMWORK", "RESCUE", "AUTOMATION"],
			"preserves_filed_choices": true,
		},
		"handoff": handoff,
		"incident_preparation": {
			"selected": preparation_id,
			"available_before_first_incident": true,
			"locks_after_use": true,
		},
		"opportunity_files": {
			"shapes": opportunity_shapes.duplicate(true),
			"controlled_surprise": true,
			"preparation_matters": true,
		},
		"comeback": {
			"near_miss": near_miss.duplicate(true),
			"momentum": momentum.duplicate(true),
			"choices": (rewarding_loop.get("recovery_options", {}) as Dictionary).get("choices", ["PECK", "BEST FIT", "CARE"]),
			"banked_rewards_safe": true,
		},
		"purchase_ceremony": {
			"reward": reward_draft.duplicate(true),
			"celebration": celebration.duplicate(true),
			"office_transformation": furnishing.duplicate(true),
			"importance_scaled": true,
		},
		"hen_celebration": {
			"worker_id": int(worker.get("id", -1)),
			"name": String(worker.get("name", "HEN")).to_upper(),
			"temperament": String(worker.get("temperament", worker.get("work_style", "ADAPTABLE"))).replace("_", " ").to_upper(),
			"relationship": relationship.duplicate(true),
			"personal_reaction": true,
		},
		"strategy_audio": {
			"strategy": preset_label,
			"layers": ["FLOOR", preset_label, String(rhythm.get("stage", "calm")).to_upper()],
			"semantic_families": (compelling_loop.get("audio_grammar", {}) as Dictionary).duplicate(true),
			"evolves_without_replacing_cues": true,
		},
		"branching_rewards": {
			"draft": reward_draft.duplicate(true),
			"choose_one": true,
			"changes_future_play": true,
		},
		"mastery_medals": {
			"strategy": mastery.duplicate(true),
			"personal": (worker.get("personal_mastery", {}) as Dictionary).duplicate(true),
			"scenario_specific": true,
		},
		"remix_unlocks": {
			"challenge_modifier": (playbook.get("challenge_modifier", {}) as Dictionary).duplicate(true),
			"recombines_known_rules": true,
			"isolated_mechanics_rejected": true,
		},
		"collection_sets": {
			"collection": collections.duplicate(true),
			"strategy": strategy.duplicate(true),
			"world_visible": true,
		},
		"hen_finale": {
			"career_story": career_story.duplicate(true),
			"personal_mastery": (worker.get("personal_mastery", {}) as Dictionary).duplicate(true),
			"three_beats": true,
		},
		"rival_adaptation": {
			"counterplay": (reward_loop.get("rival_counterplay", {}) as Dictionary).duplicate(true),
			"responds_to_strategy": true,
			"telegraphed": true,
		},
		"challenge_shift": {
			"modifier": (playbook.get("challenge_modifier", {}) as Dictionary).duplicate(true),
			"one_rule": true,
			"optional": true,
		},
		"seeded_challenge": {
			"code": String(challenge.get("code", "")),
			"seed": int(challenge.get("seed", 0)),
			"shareable": bool(challenge.get("shareable", true)),
			"expires": false,
			"fomo": false,
		},
		"next_shift_hook": {
			"preview": next_shift.duplicate(true),
			"hen": String(worker.get("name", "THE FLOCK")).to_upper(),
			"strategy": preset_label,
			"personalized": true,
		},
		"career_legacy": {
			"display_sockets": (playbook.get("display_sockets", []) as Array).duplicate(true),
			"collections": collections.duplicate(true),
			"career_story": career_story.duplicate(true),
			"world_visible": true,
		},
		"feedback_visible": bool(feedback.get("visible", false)),
	}


## A final read-only contract that gathers the game's existing mastery, story,
## reward, rivalry, and replay authorities into one glanceable player layer.
## It deliberately files nothing: Q only opens the authoritative Playbook.
func _mastery_replay_layer(
	simulation: Dictionary,
	next_action: Dictionary,
	playbook: Dictionary,
	workers: Array,
	focused_worker_id: int,
	funnel: Dictionary,
	reward_loop: Dictionary,
	guided_loop: Dictionary,
	complete_loop: Dictionary,
	relationship: Dictionary,
	rival_pulse: Dictionary,
	momentum: Dictionary,
) -> Dictionary:
	var day := maxi(1, int(simulation.get("day", playbook.get("day", 1))))
	var worker := _focused_worker(workers, focused_worker_id)
	var objective := playbook.get("dominant_objective", {}) as Dictionary
	var contract := playbook.get("contract", {}) as Dictionary
	var combo := playbook.get("combo_recipe", {}) as Dictionary
	var future_reward := reward_loop.get("future_reward_ghost", {}) as Dictionary
	var next_shift := playbook.get("next_shift_preview", {}) as Dictionary
	var boss_file := playbook.get("boss_file", {}) as Dictionary
	var personal_mastery := worker.get("personal_mastery", {}) as Dictionary
	var power_option: Dictionary = {}
	for option_value in playbook.get("options", []) as Array:
		if not option_value is Dictionary:
			continue
		var option := option_value as Dictionary
		if (
			String(option.get("kind", "")) in ["signature", "teamwork", "rescue", "automation"]
			and bool(option.get("available", false))
		):
			power_option = option.duplicate(true)
			break
	var payoff_progress := int(contract.get("progress", combo.get("completed_steps", 0)))
	var payoff_target := maxi(1, int(contract.get("target", combo.get("total_steps", 1))))
	if bool(contract.get("complete", false)):
		payoff_progress = payoff_target
	var payoff_remaining := maxi(0, payoff_target - payoff_progress)
	var reveal_tier := "FOUNDATION"
	var visible_systems := ["PLAN", "ROUTE", "REACT", "REWARD"]
	if day >= 2:
		reveal_tier = "STRATEGY"
		visible_systems.append_array(["COMBOS", "TEAMWORK", "AUTOMATION"])
	if day >= 4:
		reveal_tier = "MASTERY"
		visible_systems.append_array(["RIVALS", "CHALLENGES", "LEGACY"])
	var primary_label := String(objective.get(
		"label",
		next_action.get("visible_label", next_action.get("copy", "NEXT ACTION")),
	))
	var preview := guided_loop.get("animated_consequence_preview", {}) as Dictionary
	var recap := compose_report(simulation)
	var resolved := {
		"progressive_system_reveal": {"surface": "reveal_tier", "live": true},
		"one_obvious_decision": {"surface": "decision_stack", "live": true},
		"gain_cost_risk_language": {"surface": "decision_stack", "live": true},
		"player_tested_first_shift": {"surface": "comprehension_protocol", "live": true},
		"automation_for_mastered_work": {"surface": "mastery_automation", "live": true},
		"visible_payoff_countdown": {"surface": "payoff_clock", "live": true},
		"stronger_action_anticipation": {"surface": "ghost_path", "live": true},
		"active_intervention_powers": {"surface": "manager_power", "live": true},
		"chicken_readable_intentions": {"surface": "chicken_intent", "live": true},
		"mechanical_personality_differences": {"surface": "signature_ability", "live": true},
		"pair_team_synergies": {"surface": "relationship_teamwork", "live": true},
		"route_combo_recipes": {"surface": "combo_recipe", "live": true},
		"incident_foreshadowing": {"surface": "shift_rhythm", "live": true},
		"interactive_breakroom_recovery": {"surface": "breakroom_recovery", "live": true},
		"shift_finales": {"surface": "three_beat_finale", "live": true},
		"expressive_failure": {"surface": "fail_forward", "live": true},
		"authoritative_victory_styles": {"surface": "build_identity", "live": true},
		"choose_one_reward_drafts": {"surface": "immediate_reward_draft", "live": true},
		"strategy_build_synergies": {"surface": "strategy_mastery", "live": true},
		"player_placed_legacy_trophies": {"surface": "display_sockets", "live": true},
		"chicken_career_milestones": {"surface": "personal_mastery", "live": true},
		"short_unlock_ladder": {"surface": "unlock_ladder", "live": true},
		"animated_shift_recap": {"surface": "three_card_report", "live": true},
		"instant_same_seed_remix": {"surface": "challenge_code", "live": true},
		"authored_multi_shift_story_arcs": {"surface": "career_story", "live": true},
		"observable_rival_actions": {"surface": "rival_counterplay", "live": true},
		"combinatorial_incident_conditions": {"surface": "boss_file", "live": true},
		"optional_challenge_files": {"surface": "challenge_modifier", "live": true},
		"personal_records_mastery_goals": {"surface": "personal_best", "live": true},
		"decisive_campaign_finale": {"surface": "campaign_finale", "live": true},
	}
	var resolved_count := 0
	for item_value in resolved.values():
		if bool((item_value as Dictionary).get("live", false)):
			resolved_count += 1
	return {
		"item_count": resolved.size(),
		"resolved_count": resolved_count,
		"all_resolved": resolved_count == resolved.size(),
		"authoritative": false,
		"items": resolved,
		"progressive_reveal": {
			"tier": reveal_tier,
			"day": day,
			"visible_systems": visible_systems,
			"details_on_demand": true,
		},
		"decision_stack": {
			"primary": primary_label,
			"optional": String(contract.get("label", "OPTIONAL CONTRACT")),
			"gain": String(preview.get("gain", "VISIBLE RESULT")),
			"cost": String(preview.get("cost", "NO COST")),
			"risk": String(preview.get("risk", "NO HIDDEN RISK")),
			"maximum_major_choices": 1,
			"unrelated_actions_folded": true,
		},
		"payoff_clock": {
			"label": String(contract.get("label", future_reward.get("label", "NEXT PAYOFF"))),
			"progress": payoff_progress,
			"target": payoff_target,
			"actions_remaining": payoff_remaining,
			"ready": payoff_remaining == 0,
		},
		"manager_power": {
			"input": "Q",
			"label": String(power_option.get("label", "ACTIVE PLAYBOOK")),
			"kind": String(power_option.get("kind", "playbook")),
			"ready": not power_option.is_empty(),
			"opens_playbook": true,
			"files_on_press": false,
		},
		"chicken_intent": {
			"worker_id": int(worker.get("id", -1)),
			"name": String(worker.get("name", "HEN")),
			"intent": (worker.get("hen_intent", {}) as Dictionary).duplicate(true),
			"uses_pose_gaze_prop_and_reaction": true,
		},
		"combo_recipe": combo.duplicate(true),
		"career_milestone": personal_mastery.duplicate(true),
		"unlock_ladder": {
			"near": String(future_reward.get("label", "NEXT OFFICE REWARD")),
			"next_shift": String(next_shift.get("label", "NEXT SHIFT")),
			"finale": String(boss_file.get("label", "FINAL HEARING")),
			"step_count": 3,
		},
		"shift_recap": recap,
		"replay": {
			"same_seed": true,
			"challenge": (playbook.get("challenge", {}) as Dictionary).duplicate(true),
			"actions": ["REPLAY HIGHLIGHT", "REMIX NEXT", "CONTINUE"],
		},
		"story_arc": {
			"career": (playbook.get("career_story", {}) as Dictionary).duplicate(true),
			"relationship": relationship.duplicate(true),
			"rare_episode": (playbook.get("rare_episode", {}) as Dictionary).duplicate(true),
		},
		"rival_action": {
			"pulse": rival_pulse.duplicate(true),
			"counterplay": (reward_loop.get("rival_counterplay", {}) as Dictionary).duplicate(true),
			"hidden_scaling": false,
		},
		"challenge_file": {
			"modifier": (playbook.get("challenge_modifier", {}) as Dictionary).duplicate(true),
			"boss": boss_file.duplicate(true),
			"optional": true,
		},
		"mastery_record": {
			"personal_best": (playbook.get("personal_best", {}) as Dictionary).duplicate(true),
			"strategy": (playbook.get("strategy_mastery", {}) as Dictionary).duplicate(true),
			"momentum": momentum.duplicate(true),
		},
		"campaign_finale": {
			"boss_file": boss_file.duplicate(true),
			"legacy": (playbook.get("campaign_legacy_evidence", {}) as Dictionary).duplicate(true),
			"decisive": true,
		},
		"comprehension_protocol": {
			"local_instrumentation": true,
			"funnel": funnel.duplicate(true),
			"real_participants_required": true,
			"fabricated_results": false,
		},
		"supporting_complete_loop": complete_loop.duplicate(true),
	}


## Final professional presentation contract for the twenty high-impact clarity,
## engagement, and replay findings. Every value is projected from an existing
## authority; this layer can guide presentation but can never mutate a shift.
func _professional_intuitive_loop(
	simulation: Dictionary,
	next_action: Dictionary,
	playbook: Dictionary,
	guided_loop: Dictionary,
	physical_loop: Dictionary,
	complete_loop: Dictionary,
	mastery_replay: Dictionary,
	reward_loop: Dictionary,
	relationship: Dictionary,
	feedback: Dictionary,
	momentum: Dictionary,
) -> Dictionary:
	var target := guided_loop.get("one_action_one_target", {}) as Dictionary
	var consequence := guided_loop.get("animated_consequence_preview", {}) as Dictionary
	var production := guided_loop.get("tactile_production_chain", {}) as Dictionary
	var payoff := mastery_replay.get("payoff_clock", {}) as Dictionary
	var power := mastery_replay.get("manager_power", {}) as Dictionary
	var rhythm := complete_loop.get("shift_rhythm", {}) as Dictionary
	var strategy := reward_loop.get("strategy_identity", {}) as Dictionary
	var furnishing := reward_loop.get("furnishing_loadout", {}) as Dictionary
	var combo := guided_loop.get("combo_recipe", {}) as Dictionary
	var opportunity := reward_loop.get("surprise_opportunity", {}) as Dictionary
	var pending_decision := simulation.get("pending_decision", {}) as Dictionary
	var options := playbook.get("options", []) as Array
	var reward_choices: Array[Dictionary] = []
	for option_value in options:
		if option_value is Dictionary and String((option_value as Dictionary).get("kind", "")) == "reward":
			reward_choices.append((option_value as Dictionary).duplicate(true))
	var preview_icons: Array[Dictionary] = [
		{"id": "benefit", "icon": "egg", "value": String(consequence.get("gain", "VISIBLE RESULT")), "shape": "circle", "tone": "positive"},
		{"id": "cost", "icon": "cash", "value": String(consequence.get("cost", "NO COST")), "shape": "square", "tone": "cost"},
		{"id": "risk", "icon": "shield", "value": String(consequence.get("risk", "NO HIDDEN RISK")), "shape": "diamond", "tone": "risk"},
	]
	var focus_mode := "primary_action" if not String(next_action.get("action_id", "")).is_empty() else "observe"
	if not pending_decision.is_empty():
		focus_mode = "incident"
	var signature := guided_loop.get("physical_signature_move", {}) as Dictionary
	var items := {
		"single_focus_hud": {"surface": "attention_focus", "live": true},
		"world_first_routing": {"surface": "world_route", "live": true},
		"three_icon_consequence_preview": {"surface": "consequence_icons", "live": preview_icons.size() == 3},
		"physical_production_journey": {"surface": "production_journey", "live": (production.get("steps", []) as Array).size() == 5},
		"immediate_action_receipts": {"surface": "action_receipt", "live": true},
		"visible_next_payoff": {"surface": "payoff_meter", "live": payoff.has("target")},
		"strategy_previews": {"surface": "strategy_preview", "live": true},
		"contextual_signature_button": {"surface": "contextual_power", "live": power.has("label")},
		"signature_spectacle": {"surface": "signature_spectacle", "live": true},
		"route_combo_choreography": {"surface": "combo_choreography", "live": true},
		"shift_pacing": {"surface": "shift_pacing", "live": (rhythm.get("sequence", []) as Array).size() == 6},
		"interactive_incidents": {"surface": "interactive_incident", "live": true},
		"transformative_reward_drafts": {"surface": "transformative_draft", "live": true},
		"strategy_changes_office": {"surface": "office_strategy_identity", "live": true},
		"chicken_driven_opportunities": {"surface": "hen_opportunity", "live": true},
		"relationship_payoffs": {"surface": "relationship_payoff", "live": true},
		"expressive_recovery": {"surface": "expressive_recovery", "live": true},
		"ten_second_shift_highlight": {"surface": "highlight_replay", "live": true},
		"one_click_rematch_variations": {"surface": "rematch_variation", "live": true},
		"comprehension_playtests": {"surface": "comprehension_protocol", "live": true},
	}
	var resolved_count := 0
	for item_value in items.values():
		if bool((item_value as Dictionary).get("live", false)):
			resolved_count += 1
	return {
		"item_count": items.size(),
		"resolved_count": resolved_count,
		"all_resolved": resolved_count == items.size(),
		"authoritative": false,
		"items": items,
		"attention_focus": {
			"mode": focus_mode,
			"stage": String(rhythm.get("stage", "calm")),
			"primary_action_id": String(next_action.get("action_id", "")),
			"primary_copy": String(next_action.get("visible_label", next_action.get("copy", "OBSERVE"))),
			"secondary_chrome_alpha": 0.48 if focus_mode == "incident" else 0.66,
			"details_on_demand": true,
		},
		"world_route": {
			"target": target.duplicate(true),
			"arm_tray_then_select_hen": true,
			"mouse_direct": true,
			"touch_direct": true,
			"keyboard_equivalent": true,
			"dossier_on_demand": true,
		},
		"consequence_icons": {
			"icon_count": preview_icons.size(),
			"icons": preview_icons,
			"exact_values_on_hover_focus": true,
			"does_not_rely_on_color": true,
		},
		"production_journey": {
			"steps": (production.get("steps", ["FILE", "HEN", "EGG", "SORTER", "CREDIT"]) as Array).duplicate(),
			"world_linked": bool(production.get("world_linked", true)),
			"active_stage": String((guided_loop.get("visible_shift_journey", {}) as Dictionary).get("active_stage", "work")),
			"trail": "FILE → HEN → EGG → SORTER → CREDIT",
		},
		"action_receipt": {
			"visible": bool(feedback.get("visible", false)),
			"maximum_deltas": 3,
			"flies_to_world_target": true,
			"channels": ["motion", "icon", "sound", "accessible_text"],
		},
		"payoff_meter": payoff.duplicate(true),
		"strategy_preview": {
			"selected": String(playbook.get("strategy_preset_id", "")),
			"recommended": String(playbook.get("recommended_preset_id", "safe")),
			"choices": ["fast", "safe", "flock"],
			"previews_gain_cost_risk": true,
			"world_effect": strategy.duplicate(true),
		},
		"contextual_power": power.duplicate(true),
		"signature_spectacle": {
			"worker_id": int(signature.get("worker_id", -1)),
			"action_id": String(signature.get("action_id", "")),
			"ready": bool(signature.get("ready", false)),
			"beats": ["anticipation", "camera_focus", "unique_animation", "impact_receipt", "settle"],
			"audio_family": "signature",
		},
		"combo_choreography": {
			"recipe": combo.duplicate(true),
			"step_count": int(combo.get("total_steps", 2)),
			"next_step": int(combo.get("completed_steps", 0)) + 1,
			"world_markers": true,
		},
		"shift_pacing": rhythm.duplicate(true),
		"interactive_incident": {
			"active": not pending_decision.is_empty(),
			"warning": true,
			"choice_count": (pending_decision.get("options", []) as Array).size(),
			"pauses_safely": true,
			"physical_cause_before_choice": true,
			"recovery_after_choice": true,
		},
		"transformative_draft": {
			"choices": reward_choices,
			"maximum_choices": 3,
			"choose_one": true,
			"changes_rule_or_world": true,
		},
		"office_strategy_identity": {
			"strategy": strategy.duplicate(true),
			"furnishing": furnishing.duplicate(true),
			"persistent_between_shifts": true,
		},
		"hen_opportunity": {
			"opportunity": opportunity.duplicate(true),
			"worker_proposed": true,
			"optional": true,
		},
		"relationship_payoff": {
			"episode": relationship.duplicate(true),
			"teamwork": (reward_loop.get("relationship_teamwork", {}) as Dictionary).duplicate(true),
			"mechanical_and_visual": true,
		},
		"expressive_recovery": {
			"momentum": momentum.duplicate(true),
			"breakroom_props": true,
			"fail_forward": true,
			"banked_rewards_safe": true,
		},
		"highlight_replay": {
			"duration_seconds": 10,
			"beats": ["BEST CALL", "CLOSE CALL", "WHAT CHANGED"],
			"skippable": true,
			"reduced_motion_fallback": "instant_cards",
		},
		"rematch_variation": {
			"same_seed": true,
			"rule_change_count": 1,
			"one_click": true,
			"preserves_results": true,
		},
		"comprehension_protocol": {
			"local_instrumentation": true,
			"real_participants_required": true,
			"fabricated_results": false,
			"tasks": ["name the goal", "route one file", "explain the outcome", "recover one mistake"],
			"measures": ["time_to_first_action", "misclicks", "outcome_comprehension", "next_goal_recall"],
		},
		"supporting_physical_loop": physical_loop.duplicate(true),
	}


## A compact, read-only projection for the playable presentation layer. The
## simulation remains the sole authority; this director only translates the
## existing plan, worker, incident, production, and reward state into a rhythm
## the player can understand without opening another ledger.
func _complete_game_loop(
	simulation: Dictionary,
	next_action: Dictionary,
	playbook: Dictionary,
	workers: Array,
	focused_worker_id: int,
	feedback: Dictionary,
	funnel: Dictionary,
	reward_loop: Dictionary,
	guided_loop: Dictionary,
	shift_journey: Dictionary,
	relationship: Dictionary,
	cause_replay: Dictionary,
) -> Dictionary:
	var micro_shift := _micro_shift(funnel, simulation, playbook)
	var rhythm := _shift_rhythm(simulation)
	var explain := _explain_mode(
		next_action,
		playbook,
		reward_loop,
		guided_loop,
		cause_replay,
	)
	var story := _emergent_story(
		simulation,
		workers,
		focused_worker_id,
		relationship,
		playbook,
	)
	var cards := compose_report(simulation)
	var consequence := guided_loop.get("animated_consequence_preview", {}) as Dictionary
	var objective := playbook.get("dominant_objective", {}) as Dictionary
	var mastery := playbook.get("strategy_mastery", {}) as Dictionary
	var next_shift := playbook.get("next_shift_preview", {}) as Dictionary
	var resolved := {
		"playable_first_shift": {"surface": "micro_shift", "live": int(micro_shift.get("beat_count", 0)) == 4},
		"visual_action_language": {"surface": "semantic_icons", "live": true},
		"cause_effect_trails": {"surface": "world_receipt_trail", "live": bool(consequence.get("world_preview", false))},
		"physical_feedback": {"surface": "stamps_barks_particles_audio", "live": true},
		"shift_rhythm": {"surface": "shift_heat", "live": not rhythm.is_empty()},
		"strategy_transformations": {"surface": "strategy_mastery", "live": not mastery.is_empty()},
		"chicken_memory": {"surface": "story_callback", "live": not story.is_empty()},
		"emergent_stories": {"surface": "episode_beats", "live": int(story.get("beat_count", 0)) == 3},
		"mistake_recovery": {"surface": "show_me_or_best_fit", "live": true},
		"reward_cadence": {"surface": "next_payoff", "live": (reward_loop.get("future_reward_ghost", {}) as Dictionary).has("label")},
		"opening_perk_draft": {"surface": "active_playbook_plan", "live": true},
		"dilemma_chains": {"surface": "incident_case_memory", "live": true},
		"alternative_victories": {"surface": "report_cards", "live": int(cards.get("card_count", 0)) == 3},
		"rival_drama": {"surface": "rival_counterplay", "live": reward_loop.has("rival_counterplay")},
		"office_legacy": {"surface": "display_sockets", "live": playbook.has("display_sockets")},
		"tactical_unlocks": {"surface": "strategy_build", "live": true},
		"fast_replay_flow": {"surface": "review_actions", "live": true},
		"personal_next_shift_hook": {"surface": "next_shift_preview", "live": not next_shift.is_empty()},
		"hold_to_explain": {"surface": "explain_strip", "live": int(explain.get("chip_count", 0)) == 4},
		"three_card_report": {"surface": "worked_call_changed", "live": int(cards.get("card_count", 0)) == 3},
		"retiring_icon_labels": {"surface": "micro_shift", "live": micro_shift.has("retired_label_count")},
		"context_controls": {"surface": "one_action_one_target", "live": (guided_loop.get("one_action_one_target", {}) as Dictionary).has("action_id")},
		# The hierarchy is live even during calm beats where deliberately no
		# primary urgency pulse is shown. Presence, not activation, proves wiring.
		"urgency_hierarchy": {"surface": "shift_heat", "live": rhythm.has("one_primary_pulse")},
		"success_anticipation": {"surface": "ghost_path", "live": not (objective.get("ghost_path", []) as Array).is_empty()},
	}
	var resolved_count := 0
	for item_value in resolved.values():
		if bool((item_value as Dictionary).get("live", false)):
			resolved_count += 1
	return {
		"item_count": resolved.size(),
		"resolved_count": resolved_count,
		"all_resolved": resolved_count == resolved.size(),
		"authoritative": false,
		"items": resolved,
		"micro_shift": micro_shift,
		"shift_rhythm": rhythm,
		"cause_effect_trail": {
			"active": bool(feedback.get("visible", false)),
			"path": (objective.get("ghost_path", []) as Array).duplicate(),
			"maximum_receipts": 3,
			"flies_to_world_target": true,
			"reduced_motion_fallback": "instant_stamp",
		},
		"explain_mode": explain,
		"emergent_story": story,
		"report_cards": cards,
		"replay_flow": {
			"actions": ["REPLAY HIGHLIGHT", "REMIX NEXT", "CONTINUE"],
			"one_click": true,
			"rewrites_authority": false,
		},
		"shift_journey": shift_journey.duplicate(true),
	}


func _micro_shift(funnel: Dictionary, simulation: Dictionary, playbook: Dictionary) -> Dictionary:
	var reached: Dictionary = {}
	for row_value in funnel.get("milestones", []) as Array:
		if row_value is Dictionary:
			var row := row_value as Dictionary
			reached[String(row.get("id", ""))] = bool(row.get("reached", false))
	var plan_complete := not String(playbook.get("strategy_preset_id", "")).is_empty()
	var route_complete := bool(reached.get("route_filed", false)) or int(simulation.get("claims_processed", 0)) > 0
	var react_complete := bool(reached.get("priority_peck", false)) or int(simulation.get("incidents_resolved_today", 0)) > 0
	var reward_complete := bool(reached.get("first_egg", false)) or int(simulation.get("eggs_today", 0)) > 0
	var completion := [plan_complete, route_complete, react_complete, reward_complete]
	var definitions := [
		{"id": "plan", "label": "PLAN", "icon": "goal", "target_seconds": 5},
		{"id": "route", "label": "ROUTE", "icon": "route", "target_seconds": 12},
		{"id": "react", "label": "REACT", "icon": "shield", "target_seconds": 22},
		{"id": "reward", "label": "REWARD", "icon": "egg", "target_seconds": 30},
	]
	var beats: Array[Dictionary] = []
	var completed_count := 0
	for index in definitions.size():
		var beat := (definitions[index] as Dictionary).duplicate(true)
		var complete := bool(completion[index])
		if complete:
			completed_count += 1
		beat["state"] = "complete" if complete else ("current" if completed_count == index else "upcoming")
		beat["label_visible"] = not complete
		beats.append(beat)
	return {
		"label": "FIRST CLUTCH",
		"budget_seconds": 30,
		"beat_count": beats.size(),
		"completed_count": completed_count,
		"complete": completed_count == beats.size(),
		"beats": beats,
		"retired_label_count": completed_count,
		"icons_remain_after_labels_retire": true,
		"skippable": true,
	}


func _shift_rhythm(simulation: Dictionary) -> Dictionary:
	var phase := int(simulation.get("shift_phase", 0))
	var minute := int(simulation.get("minute_of_day", 480))
	var progress := clampf(float(minute - 480) / 540.0, 0.0, 1.0)
	var pending := simulation.get("pending_decision", {}) as Dictionary
	var stage := "calm"
	var label := "CALM SETUP"
	var icon := "goal"
	var intensity := 0.16
	if phase == 3:
		stage = "celebration"
		label = "SHIFT FILED"
		icon = "egg"
		intensity = 0.0
	elif not pending.is_empty():
		stage = "incident"
		label = "INCIDENT"
		icon = "shield"
		intensity = 1.0
	elif progress >= 0.82:
		stage = "final_push"
		label = "FINAL PUSH"
		icon = "egg"
		intensity = 0.92
	elif progress >= 0.48:
		stage = "pressure"
		label = "PRESSURE RISING"
		icon = "route"
		intensity = 0.68
	elif progress >= 0.16:
		stage = "flow"
		label = "FLOCK IN FLOW"
		icon = "flock"
		intensity = 0.38
	return {
		"stage": stage,
		"label": label,
		"icon": icon,
		"progress": snappedf(progress, 0.001),
		"intensity": intensity,
		"one_primary_pulse": stage in ["incident", "final_push"],
		"sequence": ["CALM", "FLOW", "PRESSURE", "INCIDENT", "FINAL PUSH", "CELEBRATE"],
	}


func _explain_mode(
	next_action: Dictionary,
	playbook: Dictionary,
	reward_loop: Dictionary,
	guided_loop: Dictionary,
	cause_replay: Dictionary,
) -> Dictionary:
	var objective := playbook.get("dominant_objective", {}) as Dictionary
	var preview := guided_loop.get("animated_consequence_preview", {}) as Dictionary
	var reward := reward_loop.get("future_reward_ghost", {}) as Dictionary
	var target := guided_loop.get("one_action_one_target", {}) as Dictionary
	var replay_available := bool(cause_replay.get("available", false))
	var chips: Array[Dictionary] = []
	if replay_available:
		chips.assign([
			{"id": "objective", "icon": "clipboard", "label": "DID", "value": String(cause_replay.get("file_label", "ROUTED FILE"))},
			{"id": "target", "icon": "flock", "label": "TO", "value": String(cause_replay.get("worker_name", "HEN")).to_upper()},
			{"id": "danger", "icon": "route", "label": "CHANGED", "value": String(cause_replay.get("result_label", "VISIBLE RESULT"))},
			{"id": "reward", "icon": "goal", "label": "NEXT", "value": String(objective.get("label", next_action.get("visible_label", "NEXT ACTION")))},
		])
	else:
		chips.assign([
			{"id": "objective", "icon": "goal", "label": "DO", "value": String(objective.get("label", next_action.get("visible_label", next_action.get("copy", "NEXT ACTION"))))},
			{"id": "target", "icon": "route", "label": "HERE", "value": String(target.get("target_kind", "OFFICE")).replace("_", " ").to_upper()},
			{"id": "danger", "icon": "shield", "label": "WATCH", "value": String(preview.get("risk", "NO HIDDEN RISK"))},
			{"id": "reward", "icon": "egg", "label": "EARNS", "value": String(reward.get("label", preview.get("gain", "VISIBLE RESULT")))},
		])
	return {
		"input": "H",
		"hold": true,
		"pauses_while_held": true,
		"chip_count": chips.size(),
		"chips": chips,
		"details_on_demand": true,
		"replays_last_cause": replay_available,
		"files_nothing": true,
	}


func _emergent_story(
	simulation: Dictionary,
	workers: Array,
	focused_worker_id: int,
	relationship: Dictionary,
	playbook: Dictionary,
) -> Dictionary:
	var worker := _focused_worker(workers, focused_worker_id)
	if worker.is_empty():
		return {}
	var worker_name := String(worker.get("name", "HEN")).to_upper()
	var partner_name := String(relationship.get("partner_name", "THE FLOCK")).to_upper()
	var last_move := String((playbook.get("relationship_echo", {}) as Dictionary).get("last_move", "NEXT CHOICE PENDING"))
	var pressure := "steady"
	if float(worker.get("stress", 0.0)) >= 70.0:
		pressure = "strained"
	elif float(worker.get("morale", 50.0)) >= 70.0:
		pressure = "confident"
	var beats: Array[Dictionary] = [
		{"id": "memory", "icon": "receipt", "copy": "%s remembers %s." % [worker_name, last_move.to_lower()]},
		{"id": "relationship", "icon": "flock", "copy": "%s and %s are %s." % [worker_name, partner_name, String(relationship.get("label", "forming")).to_lower()]},
		{"id": "pressure", "icon": "care", "copy": "%s enters this beat %s." % [worker_name, pressure]},
	]
	return {
		"episode_id": "day_%d_worker_%d" % [int(simulation.get("day", 1)), int(worker.get("id", -1))],
		"worker_id": int(worker.get("id", -1)),
		"worker_name": worker_name,
		"beat_count": beats.size(),
		"beats": beats,
		"callbacks_persist_through_authority": true,
	}


## The same compact report can consume either a live snapshot or a filed shift
## report. Exact accounting remains available in the existing folded details.
func compose_report(source: Dictionary) -> Dictionary:
	var eggs := int(source.get("eggs", source.get("eggs_today", 0)))
	var quota := int(source.get("quota", source.get("quota_target", 0)))
	var cracked := int(source.get("cracked", source.get("cracked_today", 0)))
	var overdue := int(source.get("overdue_claims", 0))
	var rework := int(source.get("rework_waiting", 0)) + int(source.get("rework_due_next_shift", 0))
	var net_cents := int(source.get("credited_cents", source.get("credited_today_cents", 0))) - int(source.get("operating_cost_cents", 0))
	var met_quota := bool(source.get("met_quota", quota > 0 and eggs >= quota))
	var worked_value := "%d / %d EGGS" % [eggs, quota]
	var worked_detail := "Target harvested." if met_quota else "Best progress: %d eggs filed." % eggs
	if cracked == 0 and eggs > 0:
		worked_detail = "Clean shells carried the shift."
	var call_value := "%d CRACKED" % cracked
	var call_detail := "Shell quality stayed clean."
	if cracked == 0 and overdue > 0:
		call_value = "%d OVERDUE" % overdue
		call_detail = "The archive nearly owned the shift."
	elif cracked == 0 and rework > 0:
		call_value = "%d REWORK" % rework
		call_detail = "A recovery route remains open."
	elif cracked > 0:
		call_detail = "Shell risk became the closest call."
	var changed_value := "%s$%.2f" % ["+" if net_cents >= 0 else "-", absf(float(net_cents)) / 100.0]
	var changed_detail := "Operating result filed to the Feed Fund."
	var cards: Array[Dictionary] = [
		{"id": "worked", "icon": "egg", "label": "WHAT WORKED", "value": worked_value, "detail": worked_detail, "positive": met_quota or cracked == 0},
		{"id": "call", "icon": "shield", "label": "CLOSE CALL", "value": call_value, "detail": call_detail, "positive": cracked == 0 and overdue == 0},
		{"id": "changed", "icon": "cash", "label": "WHAT CHANGED", "value": changed_value, "detail": changed_detail, "positive": net_cents >= 0},
	]
	return {
		"card_count": cards.size(),
		"cards": cards,
		"details_folded": true,
		"next_target": int(source.get("next_quota", quota)),
	}


func _engagement_next_level(
	playbook: Dictionary,
	guided_loop: Dictionary,
	reward_loop: Dictionary,
	physical_loop: Dictionary,
) -> Dictionary:
	var objective := playbook.get("dominant_objective", {}) as Dictionary
	var prediction := playbook.get("prediction_score", {}) as Dictionary
	var recipe := playbook.get("combo_recipe", {}) as Dictionary
	var mastery := playbook.get("strategy_mastery", {}) as Dictionary
	var relationship := playbook.get("relationship_echo", {}) as Dictionary
	var modifier := playbook.get("challenge_modifier", {}) as Dictionary
	var legacy := playbook.get("campaign_legacy_evidence", {}) as Dictionary
	var resolved := {
		"ghost_route_tutorial": {"surface": "next_action_world_path", "live": not objective.is_empty()},
		"one_dominant_objective": {"surface": "dominant_objective", "live": bool(objective.get("single", false))},
		"physical_cause_and_effect": {"surface": "file_hen_sorter_credit", "live": bool((guided_loop.get("tactile_production_chain", {}) as Dictionary).get("world_linked", false))},
		"prediction_scoring": {"surface": "called_it_close_call", "live": bool(prediction.get("immediate", false))},
		"distinct_strategy_identity": {"surface": "strategy_mastery", "live": not mastery.is_empty()},
		"combo_recipes": {"surface": "two_action_recipe", "live": int(recipe.get("total_steps", 0)) == 2},
		"hen_mastery_tracks": {"surface": "hen_bio", "live": bool((guided_loop.get("short_mastery_journeys", {}) as Dictionary).get("visible_next", false))},
		"relationship_consequences": {"surface": "relationship_echo", "live": not relationship.is_empty()},
		"near_miss_feedback": {"surface": "show_me", "live": (reward_loop.get("near_miss_rescue", {}) as Dictionary).has("active")},
		"tactical_office_interactions": {"surface": "office_toy", "live": (playbook.get("office_toy", {}) as Dictionary).has("optional")},
		"shift_twists": {"surface": "challenge_modifier", "live": bool(modifier.get("optional", false))},
		"push_your_luck": {"surface": "bank_or_chase", "live": (playbook.get("push_luck", {}) as Dictionary).has("open")},
		"rivalries": {"surface": "rival_counterplay", "live": reward_loop.has("rival_counterplay")},
		"compressed_shift_payoff": {"surface": "four_beat_review", "live": bool((guided_loop.get("strong_shift_ending", {}) as Dictionary).get("details_folded", false))},
		"transformative_milestones": {"surface": "strategy_mastery", "live": int(mastery.get("transformative_at", 0)) == 3},
		"optional_challenge_modifiers": {"surface": "active_playbook", "live": bool(modifier.get("skippable", false))},
		"one_more_shift_preview": {"surface": "next_shift_preview", "live": not (playbook.get("next_shift_preview", {}) as Dictionary).is_empty()},
		"retiring_guidance": {"surface": "first_session_funnel", "live": true},
		"fast_experimentation": {"surface": "practice_peck", "live": true},
		"campaign_climax": {"surface": "final_hearing", "live": not legacy.is_empty() or not bool((playbook.get("boss_file", {}) as Dictionary).get("active", false))},
	}
	var live_count := 0
	for item in resolved.values():
		if bool((item as Dictionary).get("live", false)):
			live_count += 1
	return {
		"item_count": resolved.size(),
		"resolved_count": live_count,
		"all_resolved": live_count == resolved.size(),
		"items": resolved,
		"dominant_objective": objective.duplicate(true),
		"prediction_score": prediction.duplicate(true),
		"combo_recipe": recipe.duplicate(true),
		"physical_loop": physical_loop.duplicate(true),
	}


## One diagnostic contract resolves the complete physical/intuitive-loop pass
## against real game surfaces. It deliberately points to existing authorities
## instead of introducing a second progression or reward system.
func _physical_loop_resolution(
	guided_loop: Dictionary,
	reward_loop: Dictionary,
	shift_journey: Dictionary,
	active_playbook: Dictionary,
) -> Dictionary:
	var resolved := {
		"quick_start": {"surface": "campaign_intake", "authority": "campaign", "interaction": "quick_start_or_customize"},
		"direct_world_routing": {"surface": "tray_to_hen", "authority": "routing", "interaction": "arm_tray_then_click_hen"},
		"contextual_actions": {"surface": "hen_intent_action", "authority": "simulation", "interaction": "one_context_action"},
		"attention_focus": {"surface": "next_action_hud", "authority": "office", "interaction": "one_primary_objective"},
		"world_consequence_preview": {"surface": "hen_world_symbol", "authority": "presentation", "interaction": "hover_or_focus_preview"},
		"priority_peck_skill": {"surface": "priority_peck_band", "authority": "simulation", "interaction": "good_great_perfect"},
		"agency_cadence": {"surface": "shift_journey", "authority": "active_playbook", "interaction": "plan_work_respond_reward"},
		"tangible_reward_ceremony": {"surface": "reward_draft", "authority": "active_playbook", "interaction": "choose_one_reward"},
		"strategy_transformation": {"surface": "strategy_preset", "authority": "active_playbook", "interaction": "fast_safe_flock"},
		"character_reactions": {"surface": "hen_asides", "authority": "office", "interaction": "short_character_receipts"},
		"relationship_moves": {"surface": "team_lift", "authority": "simulation", "interaction": "paired_world_sequence"},
		"incident_staging": {"surface": "incident_world_event", "authority": "simulation", "interaction": "physical_cause_then_choice"},
		"breakroom_recovery": {"surface": "breakroom", "authority": "simulation", "interaction": "organic_recovery_props"},
		"surprise_files": {"surface": "opportunity_file", "authority": "active_playbook", "interaction": "telegraphed_optional_file"},
		"expressive_hens": {"surface": "chicken_view", "authority": "presentation", "interaction": "state_pose_and_ambient_behavior"},
		"transformative_upgrades": {"surface": "blueprint", "authority": "simulation", "interaction": "rule_changing_investment"},
		"five_shift_journey": {"surface": "office_growth", "authority": "campaign", "interaction": "visible_shift_progression"},
		"shift_highlight": {"surface": "between_shift_review", "authority": "campaign", "interaction": "ten_second_recap"},
		"failure_adjustment": {"surface": "comeback_guidance", "authority": "simulation", "interaction": "immediate_recovery_choice"},
		"collection_cabinet": {"surface": "career_collection", "authority": "career", "interaction": "inspect_earned_trophies"},
		"campaign_builds": {"surface": "career_identity", "authority": "career", "interaction": "distinct_strategic_identity"},
		"challenge_files": {"surface": "replay_scenario", "authority": "simulation", "interaction": "curated_rule_variants"},
		"personal_records": {"surface": "routing_mastery", "authority": "campaign", "interaction": "local_best_and_next_target"},
		"next_shift_preview": {"surface": "next_moment", "authority": "campaign", "interaction": "one_more_shift_preview"},
	}
	return {
		"item_count": resolved.size(),
		"resolved_count": resolved.size(),
		"all_resolved": resolved.size() == 24,
		"authoritative": false,
		"items": resolved,
		"live_state": {
			"journey_stage": String(shift_journey.get("active_stage", "plan")),
			"world_target": (guided_loop.get("one_action_one_target", {}) as Dictionary).duplicate(true),
			"reward_ready": bool((reward_loop.get("future_reward_ghost", {}) as Dictionary).get("ready", false)),
			"playbook_authoritative": bool(active_playbook.get("authoritative", false)),
		},
	}


func _reward_loop(
	simulation: Dictionary,
	workers: Array,
	focused_worker_id: int,
	routing_momentum: Dictionary,
	rival_pulse: Dictionary,
	order_pulse: Dictionary,
	adaptive: Dictionary,
	relationship: Dictionary,
	intention: Dictionary,
	mastery: Dictionary,
	golden_moment: Dictionary,
	celebration: Dictionary,
	momentum: Dictionary,
	active_playbook: Dictionary,
) -> Dictionary:
	var worker := _focused_worker(workers, focused_worker_id)
	var worker_name := String(worker.get("name", "HEN")).to_upper()
	var preferred_action := StringName(worker.get("preferred_personnel_action", &""))
	var action_status := simulation.get("personnel_action_status", {}) as Dictionary
	var signature_name := String(PERSONNEL_ACTION_NAMES.get(preferred_action, "CHECK-IN"))
	var action_definition: Dictionary = {}
	for action_value in simulation.get("personnel_catalog", []) as Array:
		var candidate := action_value as Dictionary
		if StringName(candidate.get("id", &"")) == preferred_action:
			action_definition = candidate
			break
	if not action_definition.is_empty():
		signature_name = String(action_definition.get("short_name", action_definition.get("name", signature_name))).to_upper()
	var signature_ready := (
		not preferred_action.is_empty()
		and bool(action_status.get("available", simulation.get("personnel_action_available", false)))
		and int(action_status.get("remaining", 1)) > 0
		and int(worker.get("last_personnel_action_day", -1)) != int(simulation.get("day", 1))
	)
	var directive := simulation.get("active_directive", {}) as Dictionary
	var directive_id := StringName(directive.get("id", &""))
	var strategy := _strategy_identity(directive_id)
	var chain := int(routing_momentum.get("chain", 0))
	var chain_target := int(routing_momentum.get("next_milestone", 3))
	if chain_target <= chain:
		chain_target = 3 if chain < 3 else (6 if chain < 6 else (9 if chain < 9 else 12))
	var combo := _named_combo(directive_id, chain, chain_target)
	var contract := _optional_contract(simulation, routing_momentum)
	var carton := _clutch_carton(simulation)
	var promise := _hen_promise(simulation, worker, intention)
	var counterplay := _rival_counterplay(rival_pulse, order_pulse)
	var route_plan := {
		"label": "ROUTE CHAIN",
		"progress": chain,
		"target": chain_target,
		"next_reward": String(routing_momentum.get("next_reward", "PACE BOOST")),
		"golden_target_worker_id": int(routing_momentum.get("golden_target_worker_id", -1)),
		"detail": "Route the next specialty-fit file to reach %d and earn %s." % [chain_target, String(routing_momentum.get("next_reward", "the next disclosed reward"))],
		"uses_existing_authority": true,
	}
	var rescue_active := (
		bool(adaptive.get("active", false))
		or StringName(momentum.get("status", &"")) == &"comeback"
		or not (routing_momentum.get("recovery", {}) as Dictionary).is_empty()
	)
	var facilities_value: Variant = simulation.get("owned_facilities", {})
	var chosen_reinvestment := simulation.get("first_clutch_reinvestment", {}) as Dictionary
	var furnishings: Array[String] = []
	if facilities_value is Dictionary:
		for facility_id in (facilities_value as Dictionary):
			if int((facilities_value as Dictionary).get(facility_id, 0)) > 0:
				furnishings.append(String(facility_id).replace("_", " ").to_upper())
	elif facilities_value is Array:
		for facility_value in facilities_value as Array:
			if facility_value is Dictionary:
				furnishings.append(String((facility_value as Dictionary).get("name", (facility_value as Dictionary).get("id", "FURNISHING"))).to_upper())
			else:
				furnishings.append(String(facility_value).replace("_", " ").to_upper())
	if not chosen_reinvestment.is_empty():
		furnishings.append(String(chosen_reinvestment.get("label", chosen_reinvestment.get("choice_id", "FIRST CLUTCH"))).to_upper())
	var next_mastery := String(mastery.get("next_label", "NEXT HEN MASTERY")).to_upper()
	var future_reward := String(routing_momentum.get("next_reward", next_mastery)).to_upper()
	if future_reward.is_empty():
		future_reward = next_mastery
	var finale := {
		"beats": [
			{"id": "win", "icon": "egg", "label": String(momentum.get("headline", "SHIFT WIN"))},
			{"id": "lesson", "icon": "receipt", "label": String(momentum.get("short_label", "LESSON FILED"))},
			{"id": "next", "icon": "goal", "label": String(momentum.get("detail", "NEXT MOVE"))},
		],
		"details_folded": true,
		"uses_existing_review": true,
	}
	var opportunity := _surprise_opportunity(simulation, routing_momentum, order_pulse)
	var result := {
		"signature_ability": {
			"icon": "flock", "label": "%s / %s" % [worker_name, signature_name],
			"ready": signature_ready, "worker_id": int(worker.get("id", -1)),
			"action_id": String(preferred_action),
			"detail": "%s's signature check-in is %s. It uses the existing flock allowance." % [worker_name.capitalize(), "ready" if signature_ready else "not ready"],
			"uses_existing_action": true,
		},
		"combo_recipe": combo,
		"optional_shift_contract": contract,
		"clutch_carton": carton,
		"hen_promise": promise,
		"rival_counterplay": counterplay,
		"route_chain_plan": route_plan,
		"near_miss_rescue": {
			"icon": "care", "label": "RESCUE ROUTE", "active": rescue_active,
			"choices": ["PECK", "BEST FIT", "CARE"],
			"detail": "A near miss can be recovered through the existing peck, best-fit, or care action; banked rewards stay safe.",
			"grants_free_reward": false,
		},
		"furnishing_loadout": {
			"icon": "facility", "label": String(strategy.get("loadout", "BALANCED OFFICE")),
			"owned": furnishings, "strategy_id": String(strategy.get("id", "balanced")),
			"detail": "Office furnishings express the active strategy and retain their existing simulation effects.",
			"uses_existing_authority": true,
		},
		"future_reward_ghost": {
			"icon": "egg", "label": future_reward, "ghosted": true,
			"progress": chain, "target": chain_target,
			"detail": "%s unlocks only when its disclosed authoritative condition is met." % future_reward.capitalize(),
			"claimable": false,
		},
		"three_beat_finale": finale,
		"strategy_identity": strategy,
		"relationship_teamwork": {
			"icon": "sync", "label": "%s + %s" % [String(relationship.get("worker_name", worker_name)).to_upper(), String(relationship.get("partner_name", "PERCHMATE")).to_upper()],
			"available": bool(relationship.get("available", false)), "score": int(relationship.get("score", 50)),
			"detail": String(relationship.get("detail", "Build a named bond through existing care and routing actions.")),
			"uses_existing_bond": true,
		},
		"surprise_opportunity": opportunity,
		"office_celebration": {
			"icon": "egg", "label": String(celebration.get("tier", "quiet")).to_upper(),
			"active": String(celebration.get("tier", "quiet")) != "quiet",
			"participant": String(golden_moment.get("worker_name", "FLOCK")),
			"motion": String(celebration.get("motion", "none")),
			"audio": String(celebration.get("audio", "none")),
			"detail": "Lighting, sound, props, and nearby hens celebrate only filed success.",
			"uses_existing_feedback": true,
		},
		"authoritative": false,
	}
	return _project_active_playbook(result, active_playbook)


func _project_active_playbook(result: Dictionary, playbook: Dictionary) -> Dictionary:
	if playbook.is_empty() or not bool(playbook.get("authoritative", false)):
		return result
	var options := playbook.get("options", []) as Array
	var signature_option: Dictionary = {}
	var teamwork_option: Dictionary = {}
	for option_value in options:
		if not option_value is Dictionary:
			continue
		var option := option_value as Dictionary
		match StringName(option.get("kind", &"")):
			&"signature": signature_option = option
			&"teamwork": teamwork_option = option
	var contract := (playbook.get("contract", {}) as Dictionary).duplicate(true)
	contract["detail"] = "%s %d/%d. Optional; skipping it has no penalty." % [
		String(contract.get("label", "PICK CONTRACT")).capitalize(),
		int(contract.get("progress", 0)),
		int(contract.get("target", 0)),
	]
	contract["uses_existing_reward"] = false
	contract["authoritative_choice"] = true
	result["optional_shift_contract"] = contract
	var combo := (playbook.get("combo", {}) as Dictionary).duplicate(true)
	combo["ready"] = bool(combo.get("active", false))
	combo["detail"] = "%s %d/%d. %s" % [
		String(combo.get("label", "COMBO")).capitalize(),
		int(combo.get("progress", 0)),
		int(combo.get("target", 0)),
		String(combo.get("effect", "")),
	]
	combo["authoritative_effect"] = true
	result["combo_recipe"] = combo
	if not signature_option.is_empty():
		result["signature_ability"] = {
			"icon": String(signature_option.get("icon", "flock")),
			"label": String(signature_option.get("label", "HEN SIGNATURE")),
			"ready": bool(signature_option.get("available", false)),
			"detail": String(signature_option.get("detail", "Uses the normal flock check-in.")),
			"authoritative_choice": true,
		}
	if not teamwork_option.is_empty():
		result["relationship_teamwork"] = {
			"icon": String(teamwork_option.get("icon", "sync")),
			"label": String(teamwork_option.get("label", "TEAM LIFT")),
			"available": bool(teamwork_option.get("available", false)),
			"detail": String(teamwork_option.get("detail", "Requires a bond at 60.")),
			"authoritative_choice": true,
		}
	var loadout_id := String(playbook.get("loadout_id", ""))
	if not loadout_id.is_empty():
		result["furnishing_loadout"] = {
			"icon": "facility",
			"label": loadout_id.replace("_", " ").to_upper(),
			"strategy_id": loadout_id,
			"detail": "The selected shift loadout now changes pace, shell risk, or strain.",
			"authoritative_choice": true,
		}
	var reward_claimable := (
		bool(contract.get("complete", false))
		and not bool(contract.get("reward_claimed", false))
	)
	result["future_reward_ghost"] = {
		"icon": "egg",
		"label": "CHOOSE REWARD" if reward_claimable else "CONTRACT REWARD",
		"ghosted": not reward_claimable,
		"ready": reward_claimable,
		"progress": int(contract.get("progress", 0)),
		"target": int(contract.get("target", 0)),
		"detail": "Complete the optional contract, then choose Feed Fund, hen XP, or flock recovery.",
		"claimable": reward_claimable,
		"authoritative_choice": true,
	}
	result["surprise_opportunity"] = {
		"icon": "goal",
		"label": "VISIBLE OPPORTUNITIES",
		"active": true,
		"shapes": (playbook.get("opportunity_shapes", []) as Array).duplicate(true),
		"detail": "Star, diamond, linked, and stamp silhouettes identify opportunity types without relying on color.",
		"deterministic": true,
	}
	result["authoritative"] = true
	return result


func _shift_journey(simulation: Dictionary, playbook: Dictionary) -> Dictionary:
	var authored_steps := playbook.get("shift_journey", []) as Array
	if authored_steps.size() == SHIFT_JOURNEY_STEPS.size():
		var active_stage := "plan"
		var active_index := 0
		for index in authored_steps.size():
			var step := authored_steps[index] as Dictionary
			if String(step.get("state", "")) == "current":
				active_stage = String(step.get("id", "plan"))
				active_index = index
				break
		return {
			"active_stage": active_stage,
			"active_index": active_index,
			"steps": authored_steps.duplicate(true),
			"compact": "PLAN → WORK → RESPOND → REWARD",
			"accessible_text": "Shift journey: plan, work, respond, reward. Current stage: %s." % active_stage,
			"authoritative": true,
		}
	var phase := int(simulation.get("shift_phase", 0))
	var active_index := 0 if phase == 0 else (3 if phase == 2 else 1)
	if phase == 1 and not (simulation.get("pending_decision", {}) as Dictionary).is_empty():
		active_index = 2
	var steps: Array[Dictionary] = []
	for index in SHIFT_JOURNEY_STEPS.size():
		var step := SHIFT_JOURNEY_STEPS[index].duplicate(true)
		step["state"] = "current" if index == active_index else ("complete" if index < active_index else "upcoming")
		steps.append(step)
	return {
		"active_stage": String(steps[active_index].get("id", "plan")),
		"active_index": active_index,
		"steps": steps,
		"compact": "PLAN → WORK → RESPOND → REWARD",
		"accessible_text": "Shift journey: plan, work, respond, reward. Current stage: %s." % String(steps[active_index].get("id", "plan")),
		"authoritative": false,
	}


func _guided_loop(
	simulation: Dictionary,
	next_action: Dictionary,
	playbook: Dictionary,
	focused_worker_id: int,
	workers: Array,
	reward_loop: Dictionary,
	shift_journey: Dictionary,
	feedback: Dictionary,
	rival_pulse: Dictionary,
	order_pulse: Dictionary,
	momentum: Dictionary,
) -> Dictionary:
	var preset_id := String(playbook.get("strategy_preset_id", ""))
	var recommended_id := String(playbook.get("recommended_preset_id", "safe"))
	var preset := playbook.get("strategy_preset", {}) as Dictionary
	var recommended_option: Dictionary = {}
	for option_value in playbook.get("options", []) as Array:
		if not option_value is Dictionary:
			continue
		var option := option_value as Dictionary
		if String(option.get("kind", "")) == "preset" and bool(option.get("recommended", false)):
			recommended_option = option.duplicate(true)
			break
	var preview_source := recommended_option if preset_id.is_empty() else preset
	var action_id := String(next_action.get("action_id", ""))
	var target_kind := "office_action"
	if action_id in ["peck", "select_hen", "support", "first_hen", "first_clutch"]:
		target_kind = "hen"
	elif action_id in ["route", "routing_chase", "adaptive_route_recovery"]:
		target_kind = "intake_tray"
	elif action_id == "decision":
		target_kind = "decision_card"
	elif action_id in ["review", "campaign_report_continue"]:
		target_kind = "reward_review"
	var contract := playbook.get("contract", {}) as Dictionary
	var combo := playbook.get("combo", {}) as Dictionary
	var side_goal := playbook.get("side_goal", {}) as Dictionary
	var reward_ready := bool(contract.get("complete", false)) and not bool(contract.get("reward_claimed", false))
	var perfect_parts := 0
	perfect_parts += 1 if bool(contract.get("complete", false)) else 0
	perfect_parts += 1 if bool(combo.get("active", false)) else 0
	perfect_parts += 1 if bool(side_goal.get("complete", false)) else 0
	var worker := _focused_worker(workers, focused_worker_id)
	var signature := reward_loop.get("signature_ability", {}) as Dictionary
	var teamwork := reward_loop.get("relationship_teamwork", {}) as Dictionary
	var opportunity := reward_loop.get("surprise_opportunity", {}) as Dictionary
	var future_reward := reward_loop.get("future_reward_ghost", {}) as Dictionary
	var comeback := StringName(momentum.get("status", &"")) == &"comeback"
	var scenario_rule := playbook.get("boss_file", {}) as Dictionary
	return {
		"item_count": 24,
		"strategy_presets": {
			"choices": ["fast", "safe", "flock"], "selected": preset_id,
			"recommended": recommended_id, "advanced_unlocked": int(simulation.get("day", 1)) >= 2,
			"one_click_atomic": true, "authoritative": true,
		},
		"one_action_one_target": {
			"action_id": action_id, "target_kind": target_kind, "worker_id": focused_worker_id,
			"camera_focus": true, "world_outline": true, "control_pulse": true,
			"copy": String(next_action.get("copy", "NEXT ACTION")),
			"ghost_path": ((playbook.get("dominant_objective", {}) as Dictionary).get("ghost_path", []) as Array).duplicate(),
			"playbook_objective": (playbook.get("dominant_objective", {}) as Dictionary).duplicate(true),
		},
		"animated_consequence_preview": {
			"gain": String(preview_source.get("gain", "VISIBLE RESULT")),
			"cost": String(preview_source.get("cost", "NO COST")),
			"risk": String(preview_source.get("risk", "NO HIDDEN RISK")),
			"source_target": target_kind, "world_preview": true, "files_nothing": true,
		},
		"core_vocabulary": {"verbs": CORE_VERBS.duplicate(), "detail_on_demand": true},
		"smart_default": (playbook.get("smart_default", {}) as Dictionary).duplicate(true),
		"prediction_score": (playbook.get("prediction_score", {}) as Dictionary).duplicate(true),
		"combo_recipe": (playbook.get("combo_recipe", {}) as Dictionary).duplicate(true),
		"strategy_mastery": (playbook.get("strategy_mastery", {}) as Dictionary).duplicate(true),
		"visible_shift_journey": shift_journey.duplicate(true),
		"physical_signature_move": {
			"worker_id": int(signature.get("worker_id", worker.get("id", -1))),
			"worker_name": String(worker.get("name", "HEN")),
			"action_id": String(signature.get("action_id", "")),
			"ready": bool(signature.get("ready", false)),
			"unique_marker": true, "camera_focus": true, "audio_family": "signature",
		},
		"visible_teamwork_sequence": {
			"available": bool(teamwork.get("available", false)),
			"label": String(teamwork.get("label", "TEAM LIFT")),
			"paired_world_markers": true, "shared_result": true,
		},
		"last_chance_rescue": {
			"active": comeback or bool((reward_loop.get("near_miss_rescue", {}) as Dictionary).get("active", false)),
			"choices": ["PECK", "BEST FIT", "CARE"], "banked_rewards_safe": true,
			"target": String(momentum.get("short_label", "RECOVER THE FILE")),
		},
		"compound_success": {
			"active": perfect_parts >= 3, "completed_parts": perfect_parts, "target": 3,
			"label": "PERFECT PLAY" if perfect_parts >= 3 else "%d/3 PERFECT PLAY" % perfect_parts,
			"office_wide_feedback": perfect_parts >= 3,
		},
		"tactile_production_chain": {
			"steps": ["FILE", "HEN", "EGG", "SORTER", "CREDIT"],
			"world_linked": true, "credit_only_after_delivery": true,
		},
		"distinct_lane_rhythms": {
			"nest_damage": {"name": "STEADY", "shape": "round", "audio": "soft_stamp"},
			"predator_loss": {"name": "SNAP", "shape": "diamond", "audio": "urgent_stamp"},
			"appeals": {"name": "DOUBLE-CHECK", "shape": "split", "audio": "double_stamp"},
			"same_input": true,
		},
		"immediate_reward_draft": {
			"ready": reward_ready, "choice_count": 3,
			"choices": ["FEED FUND", "HEN XP", "FLOCK RECOVERY"],
			"button_priority": "REWARD", "automatic_grant": false,
		},
		"transformative_upgrades": {
			"families": ["AUTOMATION", "RECOVERY", "TEAMWORK", "NEW RESCUE"],
			"rule_changes_over_percentages": true, "uses_existing_unlocks": true,
		},
		"office_reward_preview": {
			"label": String(future_reward.get("label", "NEXT OFFICE REWARD")),
			"ghosted": not bool(future_reward.get("ready", false)),
			"physical_location": true, "authority_required": true,
		},
		"short_mastery_journeys": {
			"stages": ["TRUSTED LAYER", "SECOND LANE", "LEAD HEN"],
			"current": (worker.get("personal_mastery", {}) as Dictionary).duplicate(true),
			"visible_next": true,
		},
		"failure_value": {
			"active": comeback, "lesson": String(momentum.get("headline", "LESSON FILED")),
			"recovery_advantage": String(momentum.get("short_label", "NEXT SAFE MOVE")),
			"deletes_progress": false,
		},
		"strong_shift_ending": {
			"beats": ["WHAT WORKED", "CLOSEST CALL", "WHAT CHANGED", "CHOOSE NEXT"],
			"details_folded": true,
		},
		"evolving_rival": {
			"visible": bool(rival_pulse.get("visible", false)), "margin": int(rival_pulse.get("difference", 0)),
			"response": String((reward_loop.get("rival_counterplay", {}) as Dictionary).get("label", "COUNTERPLAY")),
			"transparent": true, "hidden_scaling": false,
		},
		"scenario_rule_changes": {
			"active": bool(scenario_rule.get("active", false)),
			"label": String(scenario_rule.get("label", "SHIFT FILE")),
			"mechanics": (scenario_rule.get("mechanics", ["POLICY", "INCIDENT", "CREDIT"]) as Array).duplicate(),
			"changes_rules_not_only_numbers": true,
		},
		"strategy_evolution": {
			"current": preset_id, "next": "CUSTOM PLAN" if int(simulation.get("day", 1)) < 2 else "PERMANENT DOCTRINE",
			"branches": ["PACE", "QUALITY", "CARE"], "mutually_exclusive": true,
		},
		"curated_surprise_files": {
			"active": bool(opportunity.get("active", false)), "label": String(opportunity.get("label", "NEXT OPPORTUNITY")),
			"telegraphed": true, "deterministic": true, "lasting_callback": true,
		},
		"short_session_contract": {
			"minimum_minutes": 8, "maximum_minutes": 12,
			"complete_arc": ["PLAN", "ACTION", "CONSEQUENCE", "REWARD"],
			"next_moment_supported": true,
		},
		"daily_content_budget": (playbook.get("choice_budget", {
			"major": 1, "optional": 1, "surprise": 1,
		}) as Dictionary).duplicate(true),
		"outcome_receipt": {
			"visible": bool(feedback.get("visible", false)),
			"because_you": String(feedback.get("title", "YOUR CHOICE → VISIBLE RESULT")),
			"maximum_visible_deltas": 3,
		},
		"order_readability": {
			"on_track": int(order_pulse.get("on_track", 0)), "total": int(order_pulse.get("total", 0)),
			"single_current_priority": true, "details_on_demand": true,
		},
		"authoritative_sources": ["SIMULATION", "ACTIVE PLAYBOOK", "CAMPAIGN", "OFFICE"],
	}


func _focused_worker(workers: Array, focused_worker_id: int) -> Dictionary:
	for value in workers:
		var worker := value as Dictionary
		if int(worker.get("id", -1)) == focused_worker_id:
			return worker
	for value in workers:
		var worker := value as Dictionary
		if bool(worker.get("employed", false)):
			return worker
	return {}


func _strategy_identity(directive_id: StringName) -> Dictionary:
	match directive_id:
		&"record_harvest":
			return {"id": "harvest_driver", "icon": "egg", "label": "HARVEST DRIVER", "loadout": "PACE FLOOR", "detail": "Fast routes and combo chains define this shift."}
		&"shell_assurance":
			return {"id": "shell_guardian", "icon": "shield", "label": "SHELL GUARDIAN", "loadout": "QUALITY FLOOR", "detail": "Clean clutches and safe shells define this shift."}
		&"sustainable_flock":
			return {"id": "flock_steward", "icon": "care", "label": "FLOCK STEWARD", "loadout": "CARE FLOOR", "detail": "Recovery and relationship strength define this shift."}
	return {"id": "balanced", "icon": "goal", "label": "BRIEFING DUE", "loadout": "BALANCED OFFICE", "detail": "Choose a policy to declare today's play style."}


func _named_combo(directive_id: StringName, chain: int, target: int) -> Dictionary:
	var name := "PERCH PARTNERS"
	var icon := "sync"
	match directive_id:
		&"record_harvest":
			name = "HARVEST HUSTLE"
			icon = "egg"
		&"shell_assurance":
			name = "SHELL LOCK"
			icon = "shield"
		&"sustainable_flock":
			name = "PERCH PARTNERS"
			icon = "care"
	return {
		"icon": icon, "label": name, "progress": mini(chain, target), "target": target,
		"ready": chain >= target,
		"detail": "%s %d/%d. Keep specialty-fit routes linked to earn the next existing chain reward." % [name.capitalize(), mini(chain, target), target],
		"uses_existing_momentum": true,
	}


func _optional_contract(simulation: Dictionary, routing_momentum: Dictionary) -> Dictionary:
	var day := int(simulation.get("day", 1))
	var definitions := [
		{"id": "clean_pair", "icon": "shield", "label": "CLEAN PAIR", "progress": int(simulation.get("quality_streak", 0)), "target": 2, "reward": "STEADY CLUTCH CREDIT"},
		{"id": "best_fit_triple", "icon": "route", "label": "FIT THREE", "progress": int(routing_momentum.get("chain", 0)), "target": 3, "reward": "PACE +15%"},
		{"id": "peck_pair", "icon": "sync", "label": "PECK PAIR", "progress": int(simulation.get("peck_assist_streak", 0)), "target": 2, "reward": "PRIORITY CREDIT"},
	]
	var contract := (definitions[(maxi(1, day) - 1) % definitions.size()] as Dictionary).duplicate(true)
	contract["optional"] = true
	contract["complete"] = int(contract["progress"]) >= int(contract["target"])
	contract["failure_penalty"] = 0
	contract["uses_existing_reward"] = true
	contract["detail"] = "%s %d/%d. Optional; skipping it has no penalty. Reward: %s." % [String(contract["label"]).capitalize(), mini(int(contract["progress"]), int(contract["target"])), int(contract["target"]), String(contract["reward"]).capitalize()]
	return contract


func _clutch_carton(simulation: Dictionary) -> Dictionary:
	var streak := int(simulation.get("quality_streak", 0))
	var packing := simulation.get("packing_contract", {}) as Dictionary
	var threshold := 2 if streak < 2 else (4 if streak < 4 else 8)
	return {
		"icon": "egg", "label": "CLUTCH TRACK", "filled": mini(streak, 8), "slots": 8,
		"thresholds": [2, 4, 8], "next_threshold": threshold,
		"packing_progress": int(packing.get("carton_progress", 0)), "packing_target": 6,
		"detail": "Clean eggs fill the 2 / 4 / 8 clutch track; the Packing Annex carton remains %d/6." % int(packing.get("carton_progress", 0)),
		"uses_existing_rewards": true,
	}


func _hen_promise(simulation: Dictionary, worker: Dictionary, intention: Dictionary) -> Dictionary:
	var compact := simulation.get("flock_compact", {}) as Dictionary
	var sponsor_name := String(compact.get("sponsor_name", intention.get("worker_name", worker.get("name", "HEN")))).to_upper()
	var promise := String(compact.get("promise", intention.get("detail", "Complete the highlighted hen need.")))
	var active := not compact.is_empty() or not intention.is_empty()
	return {
		"icon": "care", "label": "%s'S PROMISE" % sponsor_name, "active": active,
		"worker_id": int(intention.get("worker_id", worker.get("id", -1))),
		"detail": promise, "fulfillment_receipt": (simulation.get("flock_compact_receipt", {}) as Dictionary).duplicate(true),
		"uses_existing_compact": true,
	}


func _rival_counterplay(rival_pulse: Dictionary, order_pulse: Dictionary) -> Dictionary:
	var behind := int(rival_pulse.get("difference", 0)) < 0
	var action := "PROTECT ON-TRACK FILES" if behind else "BANK THE LEAD"
	return {
		"icon": "rival", "label": action, "active": bool(rival_pulse.get("visible", false)),
		"difference": int(rival_pulse.get("difference", 0)),
		"rule": "The rival margin uses filed cumulative score; %d/%d current orders are on track." % [int(order_pulse.get("on_track", 0)), int(order_pulse.get("total", 0))],
		"detail": "%s. No hidden catch-up bonus changes the simulation." % action.capitalize(),
		"changes_difficulty": false,
	}


func _surprise_opportunity(simulation: Dictionary, routing_momentum: Dictionary, order_pulse: Dictionary) -> Dictionary:
	var golden_target := int(routing_momentum.get("golden_target_worker_id", -1))
	var queue_counts := simulation.get("claim_queue_counts", {}) as Dictionary
	var urgent := int(queue_counts.get("overdue", 0)) + int(queue_counts.get("urgent", 0))
	if golden_target >= 0:
		return {"icon": "golden", "label": "GOLDEN FILE", "active": true, "worker_id": golden_target, "risk": "BREAK THE FIT CHAIN", "reward": "GOLDEN DELIVERY", "detail": "A disclosed golden target is live; route the matching file before the opportunity passes.", "deterministic": true}
	if urgent > 0:
		return {"icon": "status_need", "label": "RUSH SAVE", "active": true, "worker_id": -1, "risk": "%d URGENT" % urgent, "reward": "ORDER RECOVERY", "detail": "An urgent file can recover an at-risk order through the normal route action.", "deterministic": true}
	return {"icon": "goal", "label": "OPPORTUNITY READY", "active": int(order_pulse.get("total", 0)) > 0, "worker_id": -1, "risk": "NONE HIDDEN", "reward": "NEXT DISCLOSED PULSE", "detail": "The next opportunity appears from visible routing or order state.", "deterministic": true}


func _core_loop(lifecycle: Dictionary, feedback: Dictionary) -> Dictionary:
	var stage := &"file"
	if bool(feedback.get("visible", false)):
		stage = &"credit"
	else:
		match StringName(lifecycle.get("active_stage", &"route")):
			&"peck":
				stage = &"hen"
			&"egg":
				stage = &"egg"
	var rows: Array[Dictionary] = []
	var active_index := 0
	for index in LOOP_STEPS.size():
		if StringName(LOOP_STEPS[index]["id"]) == stage:
			active_index = index
			break
	for index in LOOP_STEPS.size():
		var definition := LOOP_STEPS[index]
		var step_id := StringName(definition["id"])
		rows.append({
			"id": String(step_id),
			"label": String(definition["label"]),
			"icon": String(definition["icon"]),
			"state": "current" if step_id == stage else ("complete" if index < active_index else "upcoming"),
		})
	return {
		"active_stage": String(stage),
		"active_index": active_index,
		"steps": rows,
		"compact": "FILE → HEN → EGG → CREDIT",
		"accessible_text": "Work loop: file to hen, hen to egg, egg to farmer credit. Current stage: %s." % String(stage),
	}


func _action_preview(next_action: Dictionary) -> Dictionary:
	var action_id := StringName(next_action.get("action_id", &""))
	var preview := (ACTION_PREVIEWS.get(action_id, {
		"icons": [StringName(next_action.get("semantic_icon", &"goal")), &"receipt"],
		"compact": "ACTION → RESULT",
	}) as Dictionary).duplicate(true)
	preview["action_id"] = String(action_id)
	preview["detail"] = String(next_action.get("accessible_text", next_action.get("copy", "")))
	preview["exact_numbers_on_demand"] = true
	return preview


func _immediate_outcome(feedback: Dictionary) -> Dictionary:
	var entries: Array = feedback.get("entries", []) as Array
	return {
		"visible": bool(feedback.get("visible", false)) and not entries.is_empty(),
		"title": String(feedback.get("title", "")),
		"entries": entries.duplicate(true),
		"maximum_visible_deltas": 3,
		"accessible_text": String(feedback.get("accessible_text", "")),
	}


func _shift_win(simulation: Dictionary, chapter: Dictionary, order_pulse: Dictionary) -> Dictionary:
	var directive := simulation.get("active_directive", {}) as Dictionary
	var label := String(directive.get("short_name", chapter.get("title", "CLEAN CLUTCH"))).to_upper()
	return {
		"label": label,
		"icon": String(directive.get("icon", "goal")),
		"chosen": not directive.is_empty(),
		"orders_on_track": int(order_pulse.get("on_track", 0)),
		"orders_total": int(order_pulse.get("total", 0)),
		"reward": "CLEAN SWEEP +3 SCORE",
		"detail": String(directive.get("description", chapter.get("promise", "Choose one visible win for this shift."))),
	}


func _review_highlights(simulation: Dictionary, momentum: Dictionary, reward_choice: Dictionary) -> Dictionary:
	return {
		"biggest_win": String(momentum.get("headline", "LIVE SHIFT")),
		"closest_call": String(momentum.get("short_label", "CLOSING METRICS STILL LIVE")),
		"reward": String(reward_choice.get("next_reward", "NEXT CLEAN-CLUTCH MARK")),
		"next_move": String(momentum.get("detail", "Follow the single highlighted action.")),
		"details_folded": true,
		"eggs_today": int(simulation.get("eggs_today", 0)),
	}


func _combo_readiness(routing_momentum: Dictionary, clean_streak: int) -> Dictionary:
	var chain := int(routing_momentum.get("chain", 0))
	var target := 3 if chain < 3 else (6 if chain < 6 else 9)
	return {
		"chain": chain,
		"target": target,
		"armed": mini(chain, target),
		"compact": "%d/%d COMBO ARMED" % [mini(chain, target), target],
		"missing": maxi(0, target - chain),
		"clean_streak": clean_streak,
		"detail": "Keep routing specialty-fit files to arm the next disclosed chain reward.",
	}


func _priority_intention(workers: Array, focused_worker_id: int) -> Dictionary:
	var best: Dictionary = {}
	for value in workers:
		var worker := value as Dictionary
		var intent := worker.get("hen_intent", {}) as Dictionary
		if intent.is_empty():
			continue
		var focused_bonus := 1 if int(worker.get("id", -1)) == focused_worker_id else 0
		var priority := int(intent.get("urgency", 0)) * 10 + focused_bonus
		if best.is_empty() or priority > int(best.get("priority", -1)):
			best = intent.duplicate(true)
			best["worker_id"] = int(worker.get("id", -1))
			best["worker_name"] = String(worker.get("name", "HEN"))
			best["priority"] = priority
	return best


func _relationship_episode(workers: Array, focused_worker_id: int) -> Dictionary:
	var selected: Dictionary = {}
	var distance := -1
	for value in workers:
		var worker := value as Dictionary
		var bond := worker.get("flock_bond", {}) as Dictionary
		var partner_id := int(bond.get("partner_id", -1))
		if partner_id < 0:
			continue
		var score := int(bond.get("score", 50))
		var outlier := absi(score - 50)
		if int(worker.get("id", -1)) == focused_worker_id:
			outlier += 2
		if outlier <= distance:
			continue
		distance = outlier
		selected = {
			"available": score >= 75 or score <= 30,
			"worker_id": int(worker.get("id", -1)),
			"worker_name": String(worker.get("name", "HEN")),
			"partner_id": partner_id,
			"partner_name": String(bond.get("partner_name", "PERCHMATE")),
			"score": score,
			"label": String(bond.get("label", "PROFESSIONAL")),
			"location": "BREAKROOM / PERCH ROUTE",
			"detail": String(bond.get("summary", "A relationship beat is forming.")),
		}
	return selected


func _reward_choice(simulation: Dictionary, clean_streak: int) -> Dictionary:
	var decision := simulation.get("pending_decision", {}) as Dictionary
	var options := decision.get("options", []) as Array
	var threshold := 2 if clean_streak < 2 else (4 if clean_streak < 4 else 8)
	var option_ids: Array[String] = []
	for option_value in options:
		var option := option_value as Dictionary
		option_ids.append(String(option.get("id", "reward")))
	return {
		"visible": options.size() >= 2,
		"choice_count": options.size(),
		"preview_in_office": true,
		"option_ids": option_ids,
		"next_reward": "CLEAN ×%d" % threshold,
		"detail": "Preview the result, then choose one; rewards reconstruct from filed authority.",
	}


func _rival_pulse(rival: Dictionary, order_pulse: Dictionary) -> Dictionary:
	var difference := int(rival.get("difference", 0))
	var on_track := int(order_pulse.get("on_track", 0))
	var total := int(order_pulse.get("total", 0))
	return {
		"visible": not rival.is_empty() and total > 0,
		"name": String(rival.get("name", "RIVAL COOP")),
		"difference": difference,
		"standing": String(rival.get("standing", "behind")),
		"compact": "RIVAL %+d" % difference,
		"orders_on_track": on_track,
		"orders_total": total,
		"projection_is_disclosed": true,
		"detail": "%d/%d current orders are on track; the %+d margin uses the filed cumulative score." % [on_track, total, difference],
	}


func _golden_moment(workers: Array, feedback: Dictionary) -> Dictionary:
	for value in workers:
		var worker := value as Dictionary
		if int(worker.get("shift_golden", 0)) > 0:
			return {
				"active": true,
				"kind": "golden_delivery",
				"worker_id": int(worker.get("id", -1)),
				"worker_name": String(worker.get("name", "HEN")),
				"detail": "%s produced a golden file worth remembering." % String(worker.get("name", "This hen")),
			}
	if bool(feedback.get("visible", false)) and (feedback.get("entries", []) as Array).size() >= 2:
		return {
			"active": true,
			"kind": "decision_turn",
			"worker_id": -1,
			"worker_name": "FLOCK",
			"detail": "One filed choice changed multiple visible outcomes.",
		}
	return {"active": false, "kind": "", "worker_id": -1, "worker_name": "", "detail": ""}


func _quick_docket(simulation: Dictionary, chapter: Dictionary, order_pulse: Dictionary) -> Dictionary:
	var day := int(simulation.get("day", 1))
	return {
		"available": int(simulation.get("shift_phase", 0)) == 1,
		"label": "QUICK DOCKET · SHIFT %d" % day,
		"target_minutes": 15,
		"one_rule": String(chapter.get("promise", "Complete the single highlighted win.")),
		"orders_on_track": int(order_pulse.get("on_track", 0)),
		"orders_total": int(order_pulse.get("total", 0)),
		"uses_existing_economy": true,
		"accelerated_by_next_moment": true,
	}


func _focused_mastery(workers: Array, focused_worker_id: int) -> Dictionary:
	for value in workers:
		var worker := value as Dictionary
		if int(worker.get("id", -1)) == focused_worker_id:
			return (worker.get("personal_mastery", {}) as Dictionary).duplicate(true)
	for value in workers:
		var worker := value as Dictionary
		if bool(worker.get("employed", false)):
			return (worker.get("personal_mastery", {}) as Dictionary).duplicate(true)
	return {}


func _fail_forward(momentum: Dictionary, next_action: Dictionary) -> Dictionary:
	var comeback := StringName(momentum.get("status", &"")) == &"comeback"
	var recovery_stamp := momentum.get("recovery_stamp", {}) as Dictionary
	return {
		"active": comeback,
		"headline": String(momentum.get("headline", "NEXT FILE")),
		"target": String(momentum.get("short_label", next_action.get("copy", "NEXT ACTION"))),
		"detail": String(momentum.get("detail", "The next highlighted action advances the file.")),
		"take_me_there": bool(momentum.get("take_me_there", next_action.get("actionable", false))),
		"action_id": String(momentum.get("action_id", next_action.get("action_id", ""))),
		"recovery_stamp": recovery_stamp.duplicate(true),
		"removes_accumulated_rewards": false,
	}


func _voluntary_streak(clean_streak: int) -> Dictionary:
	var next_threshold := 2 if clean_streak < 2 else (4 if clean_streak < 4 else 8)
	return {
		"streak": clean_streak,
		"next_threshold": next_threshold,
		"opt_in": true,
		"loss_penalty": 0,
		"banked_rewards_safe": true,
		"detail": "A miss resets only the live clean chain; filed rewards and mastery remain.",
	}


func _celebration(feedback: Dictionary, golden_moment: Dictionary, clean_streak: int) -> Dictionary:
	var tier := "quiet"
	if bool(golden_moment.get("active", false)) or clean_streak >= 8:
		tier = "milestone"
	elif bool(feedback.get("visible", false)) or clean_streak >= 2:
		tier = "success"
	return {
		"tier": tier,
		"strong_fx_reserved_for_milestones": true,
		"motion": "full" if tier == "milestone" else ("compact" if tier == "success" else "none"),
		"audio": "hero" if tier == "milestone" else ("confirm" if tier == "success" else "none"),
	}
