class_name GameplayPulseDirector
extends RefCounted

## Presentation-only coordinator for the game's clarity and delight layer.
## Every row derives from existing simulation/campaign authority; this director
## never awards currency, changes difficulty, files a choice, or enters a save.

const LOOP_STEPS: Array[Dictionary] = [
	{"id": &"file", "label": "FILE", "icon": &"clipboard"},
	{"id": &"hen", "label": "HEN", "icon": &"flock"},
	{"id": &"egg", "label": "EGG", "icon": &"egg"},
	{"id": &"credit", "label": "CREDIT", "icon": &"cash"},
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
	return {
		"version": 1,
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
		"comprehension_tuning": {
			"privacy": String(funnel.get("privacy", "LOCAL SESSION ONLY / NEVER TRANSMITTED")),
			"next_id": String(funnel.get("next_id", "")),
			"reached_count": int(funnel.get("reached_count", 0)),
			"total_count": int(funnel.get("total_count", 0)),
			"signals": (funnel.get("signals", {}) as Dictionary).duplicate(true),
			"friction_flags": (funnel.get("friction_flags", []) as Array).duplicate(true),
		},
	}


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
