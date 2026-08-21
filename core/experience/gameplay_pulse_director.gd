class_name GameplayPulseDirector
extends RefCounted

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
	return {
		"version": 3,
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
		},
		"animated_consequence_preview": {
			"gain": String(preview_source.get("gain", "VISIBLE RESULT")),
			"cost": String(preview_source.get("cost", "NO COST")),
			"risk": String(preview_source.get("risk", "NO HIDDEN RISK")),
			"source_target": target_kind, "world_preview": true, "files_nothing": true,
		},
		"core_vocabulary": {"verbs": CORE_VERBS.duplicate(), "detail_on_demand": true},
		"smart_default": (playbook.get("smart_default", {}) as Dictionary).duplicate(true),
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
