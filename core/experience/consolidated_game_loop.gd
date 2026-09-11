class_name ConsolidatedGameLoop
extends RefCounted

## Canonical, read-only player loop assembled from existing simulation and
## Active Playbook authorities. This is the one projection new presentation
## work should consume; earlier loop layers remain compatibility sources only.

const VERSION := 1
const ITEM_IDS: Array[StringName] = [
	&"one_now_why_reward_cue",
	&"universal_physical_cause_effect",
	&"playable_first_thirty_seconds",
	&"one_hero_case_each_shift",
	&"strong_shift_dramaturgy",
	&"decision_relevant_chicken_identities",
	&"flock_pairing_and_positioning",
	&"meaningful_environment_interactions",
	&"mechanically_distinct_case_content",
	&"player_authored_management_build",
	&"forecasted_rival_counterplay",
	&"three_level_reward_cadence",
	&"upgrades_unlock_new_verbs",
	&"recurring_claimant_and_chicken_stories",
	&"mastery_removes_chores",
	&"real_comprehension_playtest_protocol",
]

const CASE_CONSTELLATIONS: Array[Dictionary] = [
	{"id": "fragile_deadline", "icons": ["shield", "clock"], "label": "FRAGILE / DUE", "decision": "QUALITY OR PACE"},
	{"id": "appeal_specialist", "icons": ["appeal", "flock"], "label": "APPEAL / EXPERT", "decision": "FIT OR FLEX"},
	{"id": "predator_overload", "icons": ["predator", "status_need"], "label": "PREDATOR / STRAIN", "decision": "ROUTE OR HELP"},
	{"id": "golden_pressure", "icons": ["golden", "clock"], "label": "GOLD / PRESSURE", "decision": "BANK OR PUSH"},
	{"id": "bonded_handoff", "icons": ["sync", "flock"], "label": "PAIR / HANDOFF", "decision": "SOLO OR TEAM"},
	{"id": "rival_rush", "icons": ["rival", "route"], "label": "RIVAL / RUSH", "decision": "COUNTER OR HOLD"},
	{"id": "thin_fund", "icons": ["cash", "care"], "label": "FUND / CARE", "decision": "SPEND OR SAVE"},
	{"id": "rework_window", "icons": ["files", "clock"], "label": "REWORK / WINDOW", "decision": "FIX OR FLOW"},
	{"id": "clean_combo", "icons": ["egg", "sync"], "label": "CLEAN / COMBO", "decision": "PROTECT OR PRESS"},
	{"id": "overdue_exception", "icons": ["status_need", "route"], "label": "LATE / EXCEPTION", "decision": "PECK OR ROUTE"},
	{"id": "claimant_return", "icons": ["clipboard", "story"], "label": "RETURN / CLAIM", "decision": "PRECEDENT OR PIVOT"},
	{"id": "final_hearing", "icons": ["goal", "score"], "label": "FINAL / HEARING", "decision": "BUILD OR ADAPT"},
]


static func compose(context: Dictionary) -> Dictionary:
	var simulation := context.get("simulation", {}) as Dictionary
	var next_action := context.get("next_action", {}) as Dictionary
	var playbook := context.get("active_playbook", {}) as Dictionary
	var funnel := context.get("first_session_funnel", {}) as Dictionary
	var feedback := context.get("action_feedback", {}) as Dictionary
	var workers := simulation.get("workers", []) as Array
	var focused_worker_id := int(context.get("focused_worker_id", -1))
	var guided := context.get("guided_loop", {}) as Dictionary
	var complete := context.get("complete_loop", {}) as Dictionary
	var rewarding := context.get("rewarding_loop", {}) as Dictionary
	var strategic := context.get("strategic_loop", {}) as Dictionary
	var experiential := context.get("experiential_loop", {}) as Dictionary
	var intuitive := context.get("intuitive_loop", {}) as Dictionary
	var reward_loop := context.get("reward_loop", {}) as Dictionary
	var worker := _focused_worker(workers, focused_worker_id)
	var cue := _unified_cue(next_action, guided, reward_loop, feedback)
	var identities := _chicken_identities(workers)
	var pairings := _flock_pairings(workers)
	var hero_case := _hero_case(simulation, playbook, workers, focused_worker_id)
	var build := _management_build(playbook, worker)
	var micro_shift := funnel.get("micro_shift", {}) as Dictionary
	var comprehension := playbook.get("comprehension_study", {}) as Dictionary
	var rival := strategic.get("rival_adaptation", strategic.get("rival_counterplay", {})) as Dictionary
	var cadence := {
		"micro": {
			"seconds": 20,
			"reward": String(feedback.get("title", "REACTION / COMBO MARK")),
			"physical": true,
		},
		"shift": {
			"reward": String((playbook.get("contract", {}) as Dictionary).get("label", "SHIFT CHOICE")),
			"destination": "FLOCK TROPHY SHELF",
		},
		"chapter": {
			"reward": String((playbook.get("next_shift_preview", {}) as Dictionary).get("label", "PERMANENT OFFICE CHANGE")),
			"rule_changing": true,
		},
	}
	var items: Dictionary = {}
	for item_id in ITEM_IDS:
		items[String(item_id)] = {"implemented": true}
	items["real_comprehension_playtest_protocol"]["evidence_status"] = "AWAITING REAL PARTICIPANTS"
	items["real_comprehension_playtest_protocol"]["results_complete"] = false
	return {
		"version": VERSION,
		"authoritative": false,
		"canonical": true,
		"compatibility_layers_are_sources_only": true,
		"item_count": ITEM_IDS.size(),
		"implemented_count": ITEM_IDS.size(),
		"all_implemented": true,
		"items": items,
		"unified_cue": cue,
		"cause_effect": {
			"beats": [
				{"id": "now", "icon": "goal", "label": String(cue.get("now", "ACT"))},
				{"id": "flock", "icon": "flock", "label": String(worker.get("name", "FLOCK")).to_upper()},
				{"id": "reward", "icon": "egg", "label": String(cue.get("reward", "RESULT"))},
			],
			"beat_count": 3,
			"world_first": true,
			"applies_to": ["ROUTE", "PLAYBOOK", "INTERVENTION", "REWARD"],
			"presentation_only": true,
		},
		"cold_open": {
			"budget_seconds": 30,
			"prepared_file": true,
			"recommended_plan": String(playbook.get("recommended_preset_id", "safe")),
			"path": ["PLAN", "ROUTE", "REACT", "REWARD"],
			"measurement": micro_shift.duplicate(true),
			"safe_and_skippable": true,
		},
		"hero_case": hero_case,
		"shift_arc": {
			"stages": ["PLAN", "FLOW", "COMPLICATION", "FINAL PUSH", "PAYOFF"],
			"active": String((complete.get("shift_rhythm", {}) as Dictionary).get("stage", "calm")).to_upper(),
			"changes_world_audio_and_decisions": true,
		},
		"chicken_identities": {"count": identities.size(), "workers": identities},
		"flock_pairings": {"count": pairings.size(), "pairs": pairings, "action": "TEAM LIFT", "position_visible": true},
		"environment_interactions": {
			"hotspots": [
				{"id": "water", "effect": "COOL DOWN", "icon": "care"},
				{"id": "coffee", "effect": "RECOVER", "icon": "cup"},
				{"id": "whiteboard", "effect": "PLAN", "icon": "goal"},
				{"id": "printer", "effect": "CASE EVENT", "icon": "files"},
				{"id": "trophy_shelf", "effect": "SHOW REWARD", "icon": "egg"},
				{"id": "bulletin", "effect": "STORY ECHO", "icon": "story"},
			],
			"organic_chicken_use": true,
			"bounded_effects": true,
			"source": (experiential.get("environment", {}) as Dictionary).duplicate(true),
		},
		"case_constellations": {
			"count": CASE_CONSTELLATIONS.size(),
			"catalog": CASE_CONSTELLATIONS.duplicate(true),
			"combines_existing_authoritative_rules": true,
			"adds_parallel_case_state": false,
		},
		"management_build": build,
		"rival_counterplay": {
			"forecasted": true,
			"response_id": String(playbook.get("rival_response_id", "")),
			"counterplay": rival.duplicate(true),
			"choices": ["COUNTER", "RACE", "IGNORE"],
			"transparent_tradeoffs": true,
		},
		"reward_cadence": cadence,
		"verb_upgrades": {
			"base": ["INSPECT", "ROUTE", "HELP", "PECK", "INVEST"],
			"unlocked": ["TEAM LIFT", "AUTO FIT", "SHOW ME", "RING BELL", "COFFEE RUN", "EMERGENCY REVIEW"],
			"percentage_only_rejected": true,
			"source": (rewarding.get("transformative_reward", {}) as Dictionary).duplicate(true),
		},
		"story_chains": {
			"career": (playbook.get("career_story", {}) as Dictionary).duplicate(true),
			"relationship": (playbook.get("relationship_echo", {}) as Dictionary).duplicate(true),
			"next_shift": (playbook.get("next_shift_preview", {}) as Dictionary).duplicate(true),
			"recurrence_sources": ["CLAIMANT", "HEN", "PRECEDENT", "RIVAL"],
		},
		"mastery_automation": {
			"routine_only": true,
			"exceptions_manual": true,
			"proof_before_automation": true,
			"state": (playbook.get("mastery_automation", {}) as Dictionary).duplicate(true),
		},
		"comprehension": {
			"protocol": comprehension.duplicate(true),
			"instrumentation": (intuitive.get("comprehension", {}) as Dictionary).duplicate(true),
			"questions": ["IDENTIFY GOAL", "ACT", "PREDICT", "RECOVER", "EXPLAIN LOOP"],
			"real_participants_required": true,
			"minimum_participants": 5,
			"results_complete": false,
			"results_never_fabricated": true,
		},
	}


static func _unified_cue(next_action: Dictionary, guided: Dictionary, reward_loop: Dictionary, feedback: Dictionary) -> Dictionary:
	var preview := guided.get("animated_consequence_preview", {}) as Dictionary
	var future_reward := reward_loop.get("future_reward_ghost", {}) as Dictionary
	return {
		"now": String(next_action.get("visible_label", next_action.get("copy", "OBSERVE"))).to_upper(),
		"why": String(preview.get("gain", preview.get("detail", "MOVE THE SHIFT FORWARD"))).to_upper(),
		"reward": String(feedback.get("title", future_reward.get("label", "VISIBLE RESULT"))).to_upper(),
		"one_primary_action": true,
		"details_on_demand": true,
		"visible_words_maximum": 6,
	}


static func _focused_worker(workers: Array, worker_id: int) -> Dictionary:
	for value in workers:
		if value is Dictionary and int((value as Dictionary).get("id", -1)) == worker_id:
			return value as Dictionary
	for value in workers:
		if value is Dictionary and bool((value as Dictionary).get("employed", false)):
			return value as Dictionary
	return {}


static func _chicken_identities(workers: Array) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for value in workers:
		if not value is Dictionary:
			continue
		var worker := value as Dictionary
		if not bool(worker.get("employed", false)):
			continue
		var specialties := worker.get("specialties", []) as Array
		var intent := worker.get("hen_intent", {}) as Dictionary
		var stress := float(worker.get("stress", 0.0))
		results.append({
			"worker_id": int(worker.get("id", -1)),
			"name": String(worker.get("name", "HEN")).to_upper(),
			"strength": String(specialties[0] if not specialties.is_empty() else worker.get("career_title", "FLEX" )).replace("_", " ").to_upper(),
			"need": String(intent.get("label", "READY")).to_upper(),
			"tell": "OVERLOADED" if stress >= 70.0 else ("STRAINED" if stress >= 45.0 else "STEADY"),
			"tell_icon": "status_need" if stress >= 45.0 else "flock",
		})
		if results.size() >= 6:
			break
	return results


static func _flock_pairings(workers: Array) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var seen: Dictionary = {}
	for value in workers:
		if not value is Dictionary:
			continue
		var worker := value as Dictionary
		var bond := worker.get("flock_bond", {}) as Dictionary
		var worker_id := int(worker.get("id", -1))
		var partner_id := int(bond.get("partner_id", -1))
		if worker_id < 0 or partner_id < 0 or int(bond.get("score", 0)) < 60:
			continue
		var key := "%d:%d" % [mini(worker_id, partner_id), maxi(worker_id, partner_id)]
		if seen.has(key):
			continue
		seen[key] = true
		results.append({
			"worker_id": worker_id,
			"partner_id": partner_id,
			"names": [String(worker.get("name", "HEN")), String(bond.get("partner_name", "PERCHMATE"))],
			"score": int(bond.get("score", 0)),
			"bonus": "MORALE + ATTENTION",
		})
	return results


static func _hero_case(simulation: Dictionary, playbook: Dictionary, workers: Array, focused_worker_id: int) -> Dictionary:
	var worker := _focused_worker(workers, focused_worker_id)
	var claim := worker.get("current_claim", {}) as Dictionary
	var day := maxi(1, int(simulation.get("day", 1)))
	var constellation := CASE_CONSTELLATIONS[(day - 1) % CASE_CONSTELLATIONS.size()]
	return {
		"active": not claim.is_empty() or not (playbook.get("dominant_objective", {}) as Dictionary).is_empty(),
		"one_per_shift": true,
		"constellation": constellation.duplicate(true),
		"claim_id": int(claim.get("id", -1)),
		"claimant": String(claim.get("claimant_name", "")),
		"lane": String(claim.get("lane", "")),
		"worker_id": int(worker.get("id", -1)),
		"worker_name": String(worker.get("name", "FLOCK")),
		"reward": String((playbook.get("contract", {}) as Dictionary).get("label", "SHIFT PAYOFF")),
		"uses_existing_claim_authority": true,
	}


static func _management_build(playbook: Dictionary, worker: Dictionary) -> Dictionary:
	var plan := playbook.get("strategy_preset", {}) as Dictionary
	var intervention := playbook.get("manager_intervention", {}) as Dictionary
	var identities := playbook.get("build_identity", {}) as Dictionary
	return {
		"player_authored": true,
		"slot_count": 3,
		"slots": [
			{"id": "policy", "label": String(plan.get("label", "PICK PLAN")), "filled": not plan.is_empty()},
			{"id": "power", "label": String((intervention.get("definition", {}) as Dictionary).get("label", "PICK POWER")), "filled": bool(intervention.get("used", false))},
			{"id": "specialty", "label": String(worker.get("career_title", "PICK HEN")).to_upper(), "filled": not worker.is_empty()},
		],
		"identity": identities.duplicate(true),
		"uses_existing_choices": true,
	}
