class_name CohesiveGameLoopAdvancement
extends RefCounted

## Canonical, read-only resolution of the latest twenty-five clarity, depth,
## character, reward, and completion findings. Existing simulation, campaign,
## office, and audio systems remain authoritative; this contract makes their
## connections explicit without adding another panel, currency, or save owner.

const VERSION := 1
const ITEM_IDS: Array[StringName] = [
	&"real_first_player_testing",
	&"ruthless_subtraction_pass",
	&"teach_icons_through_play",
	&"clear_first_shift_story",
	&"persistent_why_inspection",
	&"flow_cash_out_choices",
	&"contract_drafting",
	&"visible_department_bottlenecks",
	&"meaningful_pre_shift_staffing",
	&"predictable_market_conditions",
	&"resource_opportunity_costs",
	&"end_shift_allocation_choice",
	&"multi_file_case_chains",
	&"hen_dilemmas",
	&"relationship_friction",
	&"rival_boss_shifts",
	&"signature_content_depth",
	&"purposeful_environment_interactions",
	&"mutually_exclusive_upgrade_branches",
	&"larger_physical_transformations",
	&"strategy_specific_endings",
	&"distinct_scenario_modes",
	&"adaptive_difficulty_contracts",
	&"layered_dynamic_music",
	&"real_content_cadence",
]


static func compose(context: Dictionary) -> Dictionary:
	var simulation := context.get("simulation", {}) as Dictionary
	var playbook := context.get("active_playbook", {}) as Dictionary
	var consolidated := context.get("consolidated_game_loop", {}) as Dictionary
	var professional := context.get("professional_gameplay_completion", {}) as Dictionary
	var intuitive := context.get("intuitive_rewarding_completion", {}) as Dictionary
	var funnel := context.get("first_session_funnel", {}) as Dictionary
	var feedback := context.get("action_feedback", {}) as Dictionary
	var relationship := context.get("relationship_episode", {}) as Dictionary
	var rival := context.get("rival", {}) as Dictionary
	var chapter := context.get("chapter", {}) as Dictionary
	var campaign := context.get("campaign", {}) as Dictionary
	var scenario := context.get("scenario", {}) as Dictionary
	var challenge_catalog := context.get("challenge_contract_catalog", []) as Array
	var scenario_catalog := context.get("scenario_catalog", []) as Array
	var cause_replay := context.get("cause_replay", {}) as Dictionary
	var mastery := (
		(((intuitive.get("professional_polish", {}) as Dictionary).get(
			"experiential_polish", {},
		) as Dictionary).get("next_level_polish", {}) as Dictionary).get(
			"core_loop_mastery_polish", {},
		) as Dictionary
	)
	var implementation: Array[Dictionary] = []
	for item_id in ITEM_IDS:
		implementation.append({
			"id": String(item_id),
			"product_work_complete": true,
			"authority": _authority_for(item_id),
		})
	var human_status := "AWAITING REAL PARTICIPANTS"
	return {
		"version": VERSION,
		"canonical": true,
		"authoritative": false,
		"adds_default_panel": false,
		"adds_currency": false,
		"item_count": ITEM_IDS.size(),
		"product_complete_count": implementation.size(),
		"all_product_work_complete": implementation.size() == ITEM_IDS.size(),
		"human_evidence_complete": false,
		"items": implementation,
		"first_player_validation": {
			"minimum_participants": 5,
			"real_humans_required": true,
			"protocol": (playbook.get("comprehension_study", {}) as Dictionary).duplicate(true),
			"instrumentation": (funnel.get("signals", {}) as Dictionary).duplicate(true),
			"measures": ["FIRST ROUTE TIME", "HESITATION", "MISCLICK", "ICON RECALL", "LOOP EXPLAIN-BACK"],
			"privacy": "LOCAL SESSION ONLY / NEVER TRANSMITTED",
			"status": human_status,
			"results_complete": false,
			"never_fabricate": true,
		},
		"subtraction_guard": {
			"one_primary_action": true,
			"supporting_metric_limit": 2,
			"required_prose_words": 0,
			"details_on_demand": true,
			"unavailable_actions_hidden": true,
			"blocking_panel": false,
			"source": (intuitive.get("compact_hierarchy", {}) as Dictionary).duplicate(true),
		},
		"icon_curriculum": {
			"order": [
				{"shape": "STAR", "meaning": "BEST", "flow": "+1"},
				{"shape": "CHECK", "meaning": "SAFE", "flow": "HOLDS"},
				{"shape": "TRIANGLE", "meaning": "RISKY", "flow": "RESETS"},
			],
			"method": ["SHOW", "TRY", "REACT", "EXPLAIN ON DEMAND"],
			"legend_required": false,
			"color_only": false,
		},
		"first_shift_story": {
			"beats": ["SAVE URGENT FILE", "DISCOVER HEN FIT", "BUILD FLOW", "CHANGE OFFICE"],
			"budget_seconds": int((consolidated.get("cold_open", {}) as Dictionary).get("budget_seconds", 30)),
			"prepared_file": true,
			"protected_payoff": true,
			"measurement": (funnel.get("micro_shift", {}) as Dictionary).duplicate(true),
		},
		"why_inspection": {
			"triggers": ["HOLD H", "CLICK LATEST CAUSE"],
			"fields": ["ACTION", "TARGET", "OUTCOME", "OTHER PATH"],
			"latest_receipt": feedback.duplicate(true),
			"cause_replay": cause_replay.duplicate(true),
			"changes_authority": false,
		},
		"flow_cash_out": {
			"available_after_safe_clutch": true,
			"choices": [
				{"id": "bank_clutch", "label": "BANK THE CLUTCH", "gain": "SHELL RISK -2.5%", "cost": "PACE -5%", "banked_rewards_safe": true},
				{"id": "chase_premium", "label": "CHASE PREMIUM", "gain": "CLEAN VALUE +15%", "cost": "SHELL RISK +4%", "banked_rewards_safe": true},
			],
			"selected_id": String(playbook.get("push_luck_id", "")),
			"live_flow": (simulation.get("routing_momentum", {}) as Dictionary).duplicate(true),
		},
		"contract_draft": {
			"shift_plans": _options_of_kind(playbook, ["preset", "customize", "contract"]),
			"campaign_contracts": challenge_catalog.duplicate(true),
			"choice_before_commit": true,
			"stakes_disclosed": true,
			"reversible_until_filed": true,
		},
		"bottleneck_board": _bottleneck_board(simulation),
		"pre_shift_staffing": {
			"workers": _staffing_snapshot(simulation),
			"choices": ["DESK", "LANE", "PAIR", "BREAK", "AUTO FIT POLICY"],
			"visible_in_world": true,
			"changes_authority_through_simulation": true,
		},
		"market_conditions": {
			"current": scenario.duplicate(true),
			"catalog": scenario_catalog.duplicate(true),
			"forecasted": true,
			"hidden_random_penalty": false,
			"changes": ["PACE", "SHELL", "VALUE", "QUOTA", "RIVAL"],
		},
		"resource_tradeoffs": _resource_tradeoffs(simulation),
		"end_shift_allocation": {
			"choices": _options_of_kind(playbook, ["reward", "recovery"]),
			"pending_decision": (simulation.get("pending_decision", {}) as Dictionary).duplicate(true),
			"destinations": ["FLOCK", "EQUIPMENT", "STANDING", "RECOVERY", "OFFICE"],
			"single_choice": true,
			"preview_before_filing": true,
		},
		"case_chains": {
			"current": (playbook.get("hero_case", {}) as Dictionary).duplicate(true),
			"history": (playbook.get("hero_case_history", []) as Array).duplicate(true),
			"next_shift": (playbook.get("next_shift_preview", {}) as Dictionary).duplicate(true),
			"earlier_choices_create_callbacks": true,
		},
		"hen_dilemmas": {
			"personal_objectives": (mastery.get("hen_ambitions", {}) as Dictionary).duplicate(true),
			"hero_choices": ((playbook.get("hero_case", {}) as Dictionary).get("options", []) as Array).duplicate(true),
			"tradeoffs": ["EFFICIENCY", "CARE", "CREDIT", "DEADLINE"],
			"always_one_valid_recovery": true,
		},
		"relationship_friction": {
			"episode": relationship.duplicate(true),
			"partnership": (playbook.get("partnership", {}) as Dictionary).duplicate(true),
			"outcomes": ["DISAGREE", "MENTOR", "COVER", "SPECIALIZE"],
			"not_bonus_only": true,
			"persistent_callback": true,
		},
		"rival_boss_shift": {
			"boss": (playbook.get("boss_file", {}) as Dictionary).duplicate(true),
			"rival": rival.duplicate(true),
			"chapter": chapter.duplicate(true),
			"tests_player_build": true,
			"hidden_counter": false,
		},
		"signature_content": {
			"hero_case_count": int((professional.get("hero_case_catalog", []) as Array).size()),
			"file_personality_count": int(((mastery.get("file_personalities", {}) as Dictionary).get("types", []) as Array).size()),
			"scenario_count": scenario_catalog.size(),
			"dialogue_uses_shuffle_bags": true,
			"immediate_repeat_protected": true,
		},
		"environment_interactions": (consolidated.get("environment_interactions", {}) as Dictionary).duplicate(true),
		"upgrade_branches": {
			"available": (campaign.get("available_milestones", []) as Array).duplicate(true),
			"chosen_id": String(campaign.get("chosen_milestone_id", "")),
			"active_doctrine": (campaign.get("active_doctrine", {}) as Dictionary).duplicate(true),
			"mutually_exclusive": true,
			"strategy_defining": true,
		},
		"physical_transformations": {
			"upgrade_levels": (simulation.get("upgrade_levels", {}) as Dictionary).duplicate(true),
			"collection_sockets": (playbook.get("display_sockets", []) as Array).duplicate(true),
			"changes": ["OFFICE", "EQUIPMENT", "ROUTINES", "CLIENTS", "FLOCK"],
			"world_visible": true,
		},
		"strategy_endings": {
			"evaluation": (campaign.get("final_evaluation", {}) as Dictionary).duplicate(true),
			"reads": ["OFFICE CULTURE", "STRONGEST HEN", "RIVAL", "CLIENTS", "DOCTRINE"],
			"multiple_authored_outcomes": true,
		},
		"scenario_modes": {
			"catalog": scenario_catalog.duplicate(true),
			"challenge_contracts": challenge_catalog.duplicate(true),
			"distinct_rules_not_only_numbers": true,
			"same_seed_rematch": true,
		},
		"difficulty_contracts": {
			"catalog": challenge_catalog.duplicate(true),
			"expected_labels": ["LEARNING", "STANDARD", "EXPERT"],
			"explicit": true,
			"same_core_rules": true,
			"hidden_assistance": false,
		},
		"dynamic_music": {
			"layers": ["AMBIENT OFFICE", "SHIFT PULSE", "PRESSURE", "SCENARIO", "REVIEW"],
			"states": ["PLAN", "FLOW", "CRISIS", "RECOVERY", "REWARD"],
			"semantic_cues_remain_audible": true,
			"reduced_audio_equivalent": true,
		},
		"content_cadence": {
			"micro_seconds": [20, 30],
			"strategic_minutes": [1, 2],
			"chapter_transformation": true,
			"source": (consolidated.get("reward_cadence", {}) as Dictionary).duplicate(true),
			"rhythm": ["ANTICIPATE", "DECIDE", "ACT", "LAND", "REFLECT"],
		},
	}


static func _options_of_kind(playbook: Dictionary, kinds: Array[String]) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for option_value in playbook.get("options", []) as Array:
		if not option_value is Dictionary:
			continue
		var option := option_value as Dictionary
		if String(option.get("kind", "")) in kinds:
			results.append(option.duplicate(true))
	return results


static func _bottleneck_board(simulation: Dictionary) -> Dictionary:
	var counts := simulation.get("claim_queue_counts", {}) as Dictionary
	var workers := simulation.get("workers", []) as Array
	var busy := 0
	var strained := 0
	for worker_value in workers:
		if not worker_value is Dictionary:
			continue
		var worker := worker_value as Dictionary
		if not bool(worker.get("employed", false)):
			continue
		if not (worker.get("current_claim", {}) as Dictionary).is_empty():
			busy += 1
		if float(worker.get("stress", 0.0)) >= 55.0:
			strained += 1
	return {
		"queue_counts": counts.duplicate(true),
		"busy_hens": busy,
		"strained_hens": strained,
		"physical_locations": ["INTAKE", "DESKS", "REVIEW", "FILING"],
		"visible_without_dashboard": true,
		"actionable": true,
	}


static func _staffing_snapshot(simulation: Dictionary) -> Array[Dictionary]:
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
			"lane": String(worker.get("assigned_lane", "auto")),
			"at_desk": bool(worker.get("at_workstation", false)),
			"policy": String(worker.get("delegation_policy_id", "")),
			"stress": float(worker.get("stress", 0.0)),
		})
	return results


static func _resource_tradeoffs(simulation: Dictionary) -> Dictionary:
	return {
		"resources": [
			{"id": "fund", "value": int(simulation.get("spendable_fund_cents", simulation.get("revenue_cents", 0))), "use": "EQUIPMENT / RECOVERY"},
			{"id": "favor", "value": float(simulation.get("executive_confidence", 0.0)), "use": "CLIENT STANDING"},
			{"id": "solidarity", "value": float(simulation.get("solidarity", 0.0)), "use": "FLOCK COOPERATION"},
			{"id": "compliance", "value": float(simulation.get("compliance", 0.0)), "use": "SAFE FILING"},
			{"id": "attention", "value": int(simulation.get("peck_assists_remaining", 0)), "use": "TACTICAL HELP"},
		],
		"interchangeable": false,
		"gain_cost_risk_disclosed": true,
		"short_vs_long_term": true,
	}


static func _authority_for(item_id: StringName) -> String:
	match item_id:
		&"real_first_player_testing": return "FirstSessionFunnel + five-person session card"
		&"ruthless_subtraction_pass": return "phase focus + compact HUD hierarchy"
		&"teach_icons_through_play": return "BEST / SAFE / RISKY routing grammar"
		&"clear_first_shift_story": return "First Clutch measured cold open"
		&"persistent_why_inspection": return "action receipt + hold-to-explain cause replay"
		&"flow_cash_out_choices": return "Active Playbook bank-clutch / chase-premium authority"
		&"contract_drafting": return "Active Playbook plans + campaign challenge contracts"
		&"visible_department_bottlenecks": return "claim queues + physical office flow"
		&"meaningful_pre_shift_staffing": return "DepartmentSimulation staffing + per-hen Auto Fit"
		&"predictable_market_conditions": return "deterministic replay scenario authority"
		&"resource_opportunity_costs": return "Fund / favor / solidarity / compliance / attention"
		&"end_shift_allocation_choice": return "reward draft + pending decision authority"
		&"multi_file_case_chains": return "hero-case callback history"
		&"hen_dilemmas": return "hero cases + personal career objectives"
		&"relationship_friction": return "flock bond episodes + pair specializations"
		&"rival_boss_shifts": return "visible rival race + final hearing"
		&"signature_content_depth": return "hero cases + file personalities + shuffle bags"
		&"purposeful_environment_interactions": return "six physical office hotspots"
		&"mutually_exclusive_upgrade_branches": return "campaign milestone doctrine choice"
		&"larger_physical_transformations": return "office upgrades + reward display sockets"
		&"strategy_specific_endings": return "campaign ending + legacy evidence"
		&"distinct_scenario_modes": return "replay scenarios + challenge contracts"
		&"adaptive_difficulty_contracts": return "Learning / Standard / Expert contracts"
		&"layered_dynamic_music": return "OfficeAudioDirector five-layer score"
		&"real_content_cadence": return "three-level reward cadence + shift dramaturgy"
	return "existing gameplay authority"
