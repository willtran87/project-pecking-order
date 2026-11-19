class_name PlaybookAuthority
extends RefCounted

## Active Playbook: options, presets, contracts and action resolution.
## Holds no state of its own: every read and write goes through the owning
## DepartmentSimulation so behaviour is identical to the original in-class methods.

## Weak back-reference: the simulation owns this component, so a strong
## reference here would form a RefCounted cycle and leak both objects.
var _sim_ref: WeakRef
var sim: DepartmentSimulation:
	get:
		return _sim_ref.get_ref() as DepartmentSimulation


func _init(owner_node: DepartmentSimulation) -> void:
	_sim_ref = weakref(owner_node)

func set_worker_assignment(worker_id: int, lane: StringName) -> bool:
	if worker_id < 0 or worker_id >= sim.workers.size():
		return false
	if not sim.workers[worker_id].employed:
		return false
	if lane != DepartmentSimulation.AUTO_ASSIGNMENT and not DepartmentSimulation.CLAIM_LANE_DEFINITIONS.has(lane):
		return false
	var worker := sim.workers[worker_id]
	if worker.assigned_lane == lane:
		worker.manually_routed = lane != DepartmentSimulation.AUTO_ASSIGNMENT
		sim.snapshot_changed.emit(sim.snapshot())
		return true
	worker.assigned_lane = lane
	worker.manually_routed = lane != DepartmentSimulation.AUTO_ASSIGNMENT
	sim._breach_specialty_compact_for_assignment(worker)
	sim.snapshot_changed.emit(sim.snapshot())
	return true


func _next_personnel_action_serial() -> int:
	var highest := 0
	for worker in sim.workers:
		highest = maxi(highest, worker.last_personnel_action_serial)
	return mini(2_000_000_000, highest + 1)


func personnel_action_count_today() -> int:
	return sim._personnel_actions_for_day(sim.day).size()


func personnel_action_used_today() -> bool:
	return sim.personnel_action_count_today() >= sim.personnel_action_limit()


func perform_personnel_action(worker_id: int, action_id: StringName) -> Dictionary:
	## One consequential check-in is available across the entire flock each shift.
	## Every guard runs before the first mutation so denied actions are atomic.
	if worker_id < 0 or worker_id >= sim.workers.size():
		return _rejected_personnel_action("Select a valid hen before filing a check-in.")
	if not sim.workers[worker_id].employed:
		return _rejected_personnel_action("Applicants cannot receive active-roster check-ins.")
	if not DepartmentSimulation.PERSONNEL_ACTION_DEFINITIONS.has(action_id):
		return _rejected_personnel_action("That personnel action is not in the approved handbook.")
	var worker := sim.workers[worker_id]
	var definition: Dictionary = DepartmentSimulation.PERSONNEL_ACTION_DEFINITIONS[action_id]
	var preferred := sim._preferred_personnel_action(worker) == action_id
	var career_xp_award := sim._personnel_action_career_xp_award(worker, action_id, preferred)
	var wage_delta_cents := sim._personnel_action_wage_delta_cents(worker, career_xp_award)
	if sim.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING:
		return _rejected_personnel_action("Resolve the current management decision first.")
	if (
		sim.workers[worker_id].last_personnel_action_day == sim.day
		and sim.workers[worker_id].last_personnel_action != &""
	):
		return _rejected_personnel_action(
			"%s already has a filed flock check-in today." % sim.workers[worker_id].display_name
		)
	if sim.personnel_action_used_today():
		return _rejected_personnel_action(
			"Today's %d flock %s already filed." % [
				sim.personnel_action_limit(),
				"check-in is" if sim.personnel_action_limit() == 1 else "check-ins are",
			]
		)
	var cost_cents := int(definition["cost_cents"])
	var required_spendable_cents := cost_cents + wage_delta_cents
	var available_spendable_cents := sim.spendable_fund_cents()
	if available_spendable_cents < required_spendable_cents:
		var shortfall := float(required_spendable_cents - available_spendable_cents) / 100.0
		var reserve_reason := "Check-in denied: $%.2f more spendable Feed Fund required." % shortfall
		if wage_delta_cents > 0:
			reserve_reason = (
				"Check-in denied: $%.2f more spendable Feed Fund required after the $%.2f daily promotion wage."
				% [shortfall, float(wage_delta_cents) / 100.0]
			)
		return _rejected_personnel_action(reserve_reason)

	var before := {
		"trust": worker.manager_trust,
		"grievance": worker.grievance,
		"morale": worker.morale,
		"stress": worker.stress,
		"fatigue": worker.fatigue,
		"career_xp": worker.career_xp,
		"executive_confidence": sim.executive_confidence,
		"compliance": sim.compliance,
		"solidarity": sim.solidarity,
		"career_title": worker.career_title(),
	}
	sim.revenue_cents -= cost_cents
	match action_id:
		&"share_credit":
			worker.manager_trust = clampf(worker.manager_trust + (18.0 if preferred else 14.0), 0.0, 100.0)
			worker.grievance = clampf(worker.grievance - (13.0 if preferred else 10.0), 0.0, 100.0)
			worker.morale = clampf(worker.morale + (10.0 if preferred else 8.0), 0.0, 100.0)
			worker.stress = clampf(worker.stress - 5.0, 0.0, 100.0)
			worker.add_career_xp(career_xp_award)
			sim.executive_confidence = clampf(sim.executive_confidence - 2.0, 0.0, 100.0)
			sim.solidarity = clampf(sim.solidarity + 2.0, 0.0, 100.0)
		&"career_coaching":
			worker.manager_trust = clampf(worker.manager_trust + (9.0 if preferred else 7.0), 0.0, 100.0)
			worker.grievance = clampf(worker.grievance - 3.0, 0.0, 100.0)
			worker.morale = clampf(worker.morale + 3.0, 0.0, 100.0)
			worker.stress = clampf(worker.stress + 3.0, 0.0, 100.0)
			worker.fatigue = clampf(worker.fatigue + 2.0, 0.0, 100.0)
			worker.add_career_xp(career_xp_award)
			sim.compliance = clampf(sim.compliance + 2.0, 0.0, 100.0)
		&"quota_pressure":
			worker.manager_trust = clampf(worker.manager_trust - 12.0, 0.0, 100.0)
			worker.grievance = clampf(worker.grievance + (10.0 if preferred else 14.0), 0.0, 100.0)
			worker.morale = clampf(worker.morale - 7.0, 0.0, 100.0)
			worker.stress = clampf(worker.stress + 8.0, 0.0, 100.0)
			worker.fatigue = clampf(worker.fatigue + 4.0, 0.0, 100.0)
			worker.add_career_xp(career_xp_award)
			sim.executive_confidence = clampf(sim.executive_confidence + 3.0, 0.0, 100.0)
			sim.compliance = clampf(sim.compliance + 2.0, 0.0, 100.0)
			sim.solidarity = clampf(sim.solidarity + 4.0, 0.0, 100.0)
	worker.last_personnel_action = action_id
	worker.last_personnel_action_day = sim.day
	worker.last_personnel_action_serial = _next_personnel_action_serial()
	var social_partner := int(sim._worker_flock_bond_snapshot(worker).get("partner_id", -1))
	if social_partner >= 0 and action_id in [&"share_credit", &"quota_pressure"]:
		sim.flock_relationships.record(worker.id, social_partner, "shared_credit" if action_id == &"share_credit" else "quota_comparison", sim.day)
		sim._award_clean_pair(worker, sim.workers[social_partner])
	if action_id == &"quota_pressure":
		sim._breach_safe_pace_compact(&"quota_pressure")

	var effects := {
		"trust": worker.manager_trust - float(before["trust"]),
		"grievance": worker.grievance - float(before["grievance"]),
		"morale": worker.morale - float(before["morale"]),
		"stress": worker.stress - float(before["stress"]),
		"fatigue": worker.fatigue - float(before["fatigue"]),
		"career_xp": worker.career_xp - int(before["career_xp"]),
		"career_coaching_xp_bonus": sim.career_coaching_xp_bonus() if action_id == &"career_coaching" else 0,
		"farmer_favor": sim.executive_confidence - float(before["executive_confidence"]),
		"compliance": sim.compliance - float(before["compliance"]),
		"solidarity": sim.solidarity - float(before["solidarity"]),
		"shift_work_multiplier": sim._personnel_shift_work_multiplier(worker),
		"shift_crack_modifier": sim._personnel_shift_crack_modifier(worker),
	}
	var outcome := sim._personnel_action_outcome(worker, action_id)
	var result := {
		"accepted": true,
		"day": sim.day,
		"action_serial": worker.last_personnel_action_serial,
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"action_id": action_id,
		"action_name": String(definition["name"]),
		"cost_cents": cost_cents,
		"career_xp_award": career_xp_award,
		"daily_wage_delta_cents": wage_delta_cents,
		"preferred": preferred,
		"effects": effects,
		"promoted": String(before["career_title"]) != worker.career_title(),
		"career_title": worker.career_title(),
		"outcome": outcome,
		"personnel_actions_used": sim.personnel_action_count_today(),
		"personnel_action_limit": sim.personnel_action_limit(),
		"personnel_actions_remaining": clampi(
			sim.personnel_action_limit() - sim.personnel_action_count_today(),
			0,
			sim.personnel_action_limit(),
		),
	}
	sim.announcement_posted.emit(outcome)
	if bool(result["promoted"]):
		sim.announcement_posted.emit("PROMOTION FILED: %s is now %s." % [worker.display_name.to_upper(), worker.career_title()])
	sim.personnel_action_resolved.emit(result.duplicate(true))
	sim.snapshot_changed.emit(sim.snapshot())
	return result


func _rejected_personnel_action(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}


func _reset_active_playbook() -> void:
	sim.career_workshop.begin_day(sim.day)
	sim.active_playbook = {
		"day": sim.day,
		"strategy_preset_id": "",
		"contract_id": "",
		"preparation_id": "",
		"manager_intervention_id": "",
		"rival_response_id": "",
		"loadout_id": "",
		"recovery_id": "",
		"side_goal_id": "",
		"side_goal_fund_baseline_cents": sim.revenue_cents,
		"signature_worker_ids": [],
		"teamwork_used": false,
		"contract_reward_id": "",
		"contract_completed": false,
		"push_luck_id": "",
		"push_luck_start_eggs": 0,
		"challenge_modifier_id": "",
		"mastery_auto_used": false,
		"proposal_worker_id": -1,
		"proposal_id": "",
		"rescue_used": false,
		"toy_id": "",
		"display_style_index": 0,
		"rare_episode_resolved": false,
		"hero_case_id": String(_hero_case_id_for_day(sim.day)),
		"hero_case_choice_id": "",
		"hero_case_callback": {},
		"last_receipt": {},
		"receipt_serial": 0,
	}


func _ensure_active_playbook() -> void:
	if sim.active_playbook.is_empty() or int(sim.active_playbook.get("day", 0)) != sim.day:
		sim._reset_active_playbook()


func _playbook_contract_progress(contract_id: StringName) -> int:
	if contract_id == StringName(sim.active_playbook.get("contract_id", "")) and bool(sim.active_playbook.get("contract_completed", false)):
		return int((DepartmentSimulation.PLAYBOOK_CONTRACT_DEFINITIONS.get(contract_id, {}) as Dictionary).get("target", 0))
	if CareerWorkshop.CHALLENGES.has(String(contract_id)):
		return sim.career_workshop.progress(String(contract_id), sim.day)
	match contract_id:
		&"clean_pair":
			return sim.quality_streak
		&"fit_three":
			return sim.routing_momentum_chain
		&"peck_pair":
			return sim.peck_assist_streak
	return 0


func _record_playbook_contract_completion() -> void:
	sim._ensure_active_playbook()
	var contract_id := StringName(sim.active_playbook.get("contract_id", ""))
	var definition := DepartmentSimulation.PLAYBOOK_CONTRACT_DEFINITIONS.get(contract_id, {}) as Dictionary
	if not definition.is_empty() and _playbook_contract_progress(contract_id) >= int(definition["target"]):
		sim.active_playbook["contract_completed"] = true


func guided_plan_planning_open() -> bool:
	# Let new managers finish the opening lesson before choosing their first plan.
	return sim.incidents_resolved_today == 0 and (sim.eggs_today == 0 or (sim.day == 1 and sim.eggs_today <= 3))


func _playbook_side_goal_progress(goal_id: StringName) -> int:
	match goal_id:
		&"clean_carton":
			return sim.quality_streak
		&"lane_mastery":
			var best := 0
			for lane in DepartmentSimulation.CLAIM_LANES:
				best = maxi(best, int(sim.lane_processed_today.get(lane, 0)))
			return best
		&"gold_file":
			return sim.golden_today
		&"team_lift":
			return 1 if bool(sim.active_playbook.get("teamwork_used", false)) else 0
		&"fund_growth":
			return maxi(0, sim.revenue_cents - int(sim.active_playbook.get("side_goal_fund_baseline_cents", sim.revenue_cents)))
	return 0


func _playbook_option(
	kind: StringName,
	choice_id: StringName,
	definition: Dictionary,
	available: bool = true,
	reason: String = "",
) -> Dictionary:
	var detail := "%s  ·  %s  ·  %s" % [
		String(definition.get("gain", "VISIBLE GAIN")),
		String(definition.get("cost", "NO COST")),
		String(definition.get("risk", "NO HIDDEN RISK")),
	]
	if not reason.is_empty():
		detail += "\n%s" % reason
	return {
		"kind": String(kind),
		"id": String(choice_id),
		"key": "%s:%s" % [String(kind), String(choice_id)],
		"label": String(definition.get("label", choice_id)).to_upper(),
		"icon": String(definition.get("icon", "goal")),
		"gain": String(definition.get("gain", "VISIBLE GAIN")),
		"cost": String(definition.get("cost", "NO COST")),
		"risk": String(definition.get("risk", "NO HIDDEN RISK")),
		"available": available,
		"reason": reason,
		"detail": detail,
		"recommended": bool(definition.get("recommended", false)),
		"promise": String(definition.get("promise", "")),
		"forecast": {
			"gain": String(definition.get("gain", "VISIBLE GAIN")),
			"cost": String(definition.get("cost", "NO COST")),
			"risk": String(definition.get("risk", "NO HIDDEN RISK")),
			"uncertainty": "DISCLOSED",
		},
	}


func _recommended_playbook_strategy_id() -> StringName:
	match sim.active_directive_id:
		&"record_harvest":
			return &"fast"
		&"sustainable_flock":
			return &"flock"
	return &"safe"


func _playbook_shift_journey(contract_complete: bool) -> Array[Dictionary]:
	var preset_id := String(sim.active_playbook.get("strategy_preset_id", ""))
	var stage := &"plan"
	if not preset_id.is_empty():
		stage = &"work"
	if sim.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING and (
		not sim.pending_decision.is_empty() or (
			sim.eggs_today > 0 and String(sim.active_playbook.get("rival_response_id", "")).is_empty()
		)
	):
		stage = &"respond"
	if contract_complete and String(sim.active_playbook.get("contract_reward_id", "")).is_empty():
		stage = &"reward"
	if sim.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW:
		stage = &"reward"
	var definitions: Array[Dictionary] = [
		{"id": &"plan", "label": "PLAN", "icon": "goal"},
		{"id": &"work", "label": "WORK", "icon": "route"},
		{"id": &"respond", "label": "RESPOND", "icon": "shield"},
		{"id": &"reward", "label": "REWARD", "icon": "egg"},
	]
	var active_index := 0
	for index in definitions.size():
		if StringName(definitions[index].get("id", &"")) == stage:
			active_index = index
			break
	var result: Array[Dictionary] = []
	for index in definitions.size():
		var step := definitions[index].duplicate(true)
		step["state"] = "current" if index == active_index else ("complete" if index < active_index else "upcoming")
		result.append(step)
	return result


func _playbook_proposal_id(worker_id: int) -> StringName:
	if worker_id < 0 or worker_id >= sim.workers.size() or not sim.workers[worker_id].employed:
		return &""
	var worker := sim.workers[worker_id]
	var bond := sim._worker_flock_bond_snapshot(worker)
	if int(bond.get("score", 0)) >= 60:
		return &"pair_perch"
	if worker.stress >= 55.0 or worker.fatigue >= 60.0:
		return &"protect_clutch"
	return &"own_lane"


func _rare_office_episode_id() -> StringName:
	var episode_day := 2 + posmod(sim._career_seed, 3)
	if sim.day != episode_day:
		return &""
	var episode_ids: Array[StringName] = [&"printer_revolt", &"coffee_union", &"bell_audit"]
	return episode_ids[posmod(sim._career_seed, episode_ids.size())]


func _playbook_combo_step_progress(step_id: StringName) -> int:
	match step_id:
		&"fit_routes":
			return sim.routing_momentum_chain
		&"priority_peck":
			return sim.peck_assist_streak
		&"clean_eggs":
			return sim.quality_streak
		&"bank_clutch":
			return 1 if StringName(sim.active_playbook.get("push_luck_id", &"")) == &"bank_clutch" else 0
		&"team_lift":
			return 1 if bool(sim.active_playbook.get("teamwork_used", false)) else 0
		&"hen_signature":
			return (sim.active_playbook.get("signature_worker_ids", []) as Array).size()
	return 0


func _playbook_combo_recipe_snapshot() -> Dictionary:
	var preset_id := StringName(sim.active_playbook.get("strategy_preset_id", &""))
	if preset_id == &"custom" or not DepartmentSimulation.PLAYBOOK_COMBO_RECIPE_DEFINITIONS.has(preset_id):
		match sim.active_directive_id:
			&"record_harvest": preset_id = &"fast"
			&"sustainable_flock": preset_id = &"flock"
			_: preset_id = &"safe"
	var definition := DepartmentSimulation.PLAYBOOK_COMBO_RECIPE_DEFINITIONS[preset_id] as Dictionary
	var steps: Array[Dictionary] = []
	var completed := 0
	for step_value in definition.get("steps", []) as Array:
		var step := (step_value as Dictionary).duplicate(true)
		var step_id := StringName(step.get("id", &""))
		var target := maxi(1, int(step.get("target", 1)))
		var progress := _playbook_combo_step_progress(step_id)
		step["progress"] = mini(progress, target)
		step["complete"] = progress >= target
		if bool(step["complete"]):
			completed += 1
		steps.append(step)
	return {
		"id": String(definition.get("id", "combo_recipe")),
		"label": String(definition.get("label", "COMBO RECIPE")),
		"icon": String(definition.get("icon", "sync")),
		"effect": String(definition.get("effect", "VISIBLE BONUS")),
		"steps": steps,
		"completed_steps": completed,
		"total_steps": steps.size(),
		"complete": completed == steps.size() and not steps.is_empty(),
		"ordered": false,
		"rule": "Complete both short actions in any order; progress is never consumed.",
	}


func _playbook_prediction_snapshot(contract: Dictionary) -> Dictionary:
	var preset_id := StringName(sim.active_playbook.get("strategy_preset_id", &""))
	if String(contract.get("id", "")).is_empty():
		return {
			"plan_id": String(preset_id),
			"plan_label": "PREDICTION OPEN",
			"forecast": "CHOOSE A PLAN",
			"progress": 0,
			"target": 0,
			"verdict": "AWAITING PLAN",
			"score": 0,
			"complete": false,
			"closed": false,
			"immediate": true,
			"detail": "Choose Fast, Safe, or Flock to make one visible shift prediction.",
		}
	var target := maxi(1, int(contract.get("target", 1)))
	var progress := maxi(0, int(contract.get("progress", 0)))
	var complete := bool(contract.get("complete", false))
	var closed := sim.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW or sim.minute_of_day >= DepartmentSimulation.SHIFT_END_MINUTE
	var verdict := "BUILDING"
	var score := 0
	if complete:
		verdict = "CALLED IT"
		score = 2
	elif progress >= target - 1:
		verdict = "CLOSE CALL"
		score = 1
	elif closed:
		verdict = "SURPRISE FILED"
	var plan_label := String((DepartmentSimulation.PLAYBOOK_STRATEGY_PRESET_DEFINITIONS.get(preset_id, {}) as Dictionary).get("label", "CUSTOM PLAN"))
	return {
		"plan_id": String(preset_id),
		"plan_label": plan_label,
		"forecast": String(contract.get("label", "PICK A PLAN")),
		"progress": mini(progress, target),
		"target": target,
		"verdict": verdict,
		"score": score,
		"complete": complete,
		"closed": closed,
		"immediate": true,
		"detail": "%s predicted %s · %d/%d · %s" % [plan_label, String(contract.get("label", "shift result")), mini(progress, target), target, verdict],
	}


func _playbook_primary_objective_snapshot(options: Array[Dictionary]) -> Dictionary:
	var priorities := [
		"reward", "rescue", "hero_case", "push_luck", "proposal", "modifier", "rival",
		"signature", "teamwork", "automation", "toy", "practice",
	]
	var selected: Dictionary = {}
	for priority in priorities:
		for option in options:
			if String(option.get("kind", "")) == priority and bool(option.get("available", false)):
				selected = option.duplicate(true)
				break
		if not selected.is_empty():
			break
	if selected.is_empty():
		return {
			"verb": "ROUTE",
			"label": "ROUTE THE NEXT FILE",
			"icon": "route",
			"world_target": "intake_tray",
			"ghost_path": ["INTAKE", "BEST-FIT HEN", "SORTER", "FARMER"],
			"single": true,
		}
	var kind := String(selected.get("kind", "play"))
	var target := "active_playbook"
	if kind in ["signature", "proposal", "rescue", "teamwork", "practice", "automation"]:
		target = "focused_hen"
	elif kind == "hero_case":
		target = "incident_desk"
	elif kind == "toy":
		target = "breakroom"
	elif kind == "reward":
		target = "reward_shelf"
	return {
		"kind": kind,
		"id": String(selected.get("id", "")),
		"verb": "CHOOSE" if kind in ["reward", "hero_case", "push_luck", "modifier", "rival"] else "ACT",
		"label": String(selected.get("label", "NEXT PLAY")),
		"icon": String(selected.get("icon", "goal")),
		"world_target": target,
		"ghost_path": ["CURRENT FILE", target.replace("_", " ").to_upper(), "VISIBLE RESULT"],
		"single": true,
		"gain": String(selected.get("gain", "VISIBLE RESULT")),
		"cost": String(selected.get("cost", "NONE")),
		"risk": String(selected.get("risk", "NONE")),
	}


func _playbook_relationship_echo_snapshot(focused_worker_id: int) -> Dictionary:
	if focused_worker_id < 0 or focused_worker_id >= sim.workers.size() or not sim.workers[focused_worker_id].employed:
		return {}
	var worker := sim.workers[focused_worker_id]
	var bond := sim._worker_flock_bond_snapshot(worker)
	return {
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"partner_id": int(bond.get("partner_id", -1)),
		"partner_name": String(bond.get("partner_name", "PERCHMATE")),
		"score": int(bond.get("score", 0)),
		"standing": String(bond.get("label", bond.get("relationship_label", "FORMING"))),
		"last_move": "TEAM LIFT" if bool(sim.active_playbook.get("teamwork_used", false)) else ("HEN SIGNATURE" if focused_worker_id in (sim.active_playbook.get("signature_worker_ids", []) as Array) else "NEXT CHOICE PENDING"),
		"world_echo": true,
	}


func _playbook_strategy_mastery_snapshot(combo_recipe: Dictionary, contract: Dictionary, side_goal: Dictionary) -> Dictionary:
	var marks := 0
	marks += 1 if bool(contract.get("complete", false)) else 0
	marks += 1 if bool(combo_recipe.get("complete", false)) else 0
	marks += 1 if bool(side_goal.get("complete", false)) else 0
	var tier := "LEARNING"
	if marks >= 3:
		tier = "SIGNATURE BUILD"
	elif marks >= 2:
		tier = "ONLINE"
	elif marks >= 1:
		tier = "TAKING SHAPE"
	return {
		"tier": tier,
		"marks": marks,
		"target": 3,
		"identity": sim._build_identity_snapshot(),
		"strength": String(combo_recipe.get("effect", "BALANCED FLOOR")),
		"weakness": String((DepartmentSimulation.PLAYBOOK_STRATEGY_PRESET_DEFINITIONS.get(StringName(sim.active_playbook.get("strategy_preset_id", &"")), {}) as Dictionary).get("risk", "NO SPECIALIZATION")),
		"transformative_at": 3,
	}


func _hero_case_id_for_day(target_day: int) -> StringName:
	return DepartmentSimulation.PLAYBOOK_HERO_CASE_ORDER[posmod(maxi(1, target_day) - 1, DepartmentSimulation.PLAYBOOK_HERO_CASE_ORDER.size())]


func _hero_case_snapshot(focused_worker_id: int) -> Dictionary:
	sim._ensure_active_playbook()
	var case_id := StringName(sim.active_playbook.get("hero_case_id", _hero_case_id_for_day(sim.day)))
	var definition := (DepartmentSimulation.PLAYBOOK_HERO_CASE_DEFINITIONS.get(case_id, {}) as Dictionary).duplicate(true)
	var choice_id := StringName(sim.active_playbook.get("hero_case_choice_id", &""))
	var worker_id := focused_worker_id
	if worker_id < 0 or worker_id >= sim.workers.size() or not sim.workers[worker_id].employed:
		worker_id = -1
		for worker in sim.workers:
			if worker.employed:
				worker_id = worker.id
				break
	var options: Array[Dictionary] = []
	for option_id: StringName in (definition.get("choices", {}) as Dictionary):
		var option_definition := definition["choices"][option_id] as Dictionary
		options.append(_playbook_option(
			&"hero_case", option_id, option_definition, choice_id == &"",
			"Choose one disclosed answer; its callback is filed in the shift record.",
		))
	var callback := (sim.active_playbook.get("hero_case_callback", {}) as Dictionary).duplicate(true)
	var recent_case_ids: Array[String] = []
	for index in range(maxi(0, sim.hero_case_history.size() - 3), sim.hero_case_history.size()):
		recent_case_ids.append(String(sim.hero_case_history[index].get("case_id", "")))
	return {
		"id": String(case_id),
		"label": String(definition.get("label", "HERO FILE")),
		"icon": String(definition.get("icon", &"files")),
		"complication": String(definition.get("complication", "A consequential file is ready.")),
		"worker_id": worker_id,
		"worker_name": sim.workers[worker_id].display_name if worker_id >= 0 else "THE FLOCK",
		"active": sim.eggs_today > 0 and choice_id == &"",
		"resolved": choice_id != &"",
		"choice_id": String(choice_id),
		"options": options,
		"callback": callback,
		"persistent_history_count": sim.hero_case_history.size(),
		"staging": {
			"prepared_slot": true,
			"warning_visible": sim.eggs_today == 0,
			"arrival_trigger": "FIRST EGG",
			"world_target": "hero_file_slot",
			"audio_cue": "hero_file_arrival",
		},
		"follow_through": {
			"filed": not callback.is_empty(),
			"returns_in_review": not callback.is_empty(),
			"returns_in_future_docket": not callback.is_empty(),
			"worker_echo": String(callback.get("worker_name", "")),
			"choice_echo": String(callback.get("choice_label", "")),
		},
		"repetition_guard": {
			"recent_case_ids": recent_case_ids,
			"catalog_size": DepartmentSimulation.PLAYBOOK_HERO_CASE_ORDER.size(),
			"immediate_repeat_allowed": false,
		},
	}


func _partnership_progression_snapshot(focused_worker_id: int) -> Dictionary:
	if focused_worker_id < 0 or focused_worker_id >= sim.workers.size() or not sim.workers[focused_worker_id].employed:
		return {"available": false, "reason": "SELECT A HEN"}
	var worker := sim.workers[focused_worker_id]
	var bond := sim._worker_flock_bond_snapshot(worker)
	var partner_id := int(bond.get("partner_id", -1))
	if partner_id < 0 or partner_id >= sim.workers.size() or not sim.workers[partner_id].employed:
		return {"available": false, "reason": "NO ACTIVE PERCHMATE"}
	var partner := sim.workers[partner_id]
	var score := int(bond.get("score", 0))
	var style_id := &""
	var specialization_locked := worker.partnership_style_id != &"" or partner.partnership_style_id != &""
	if worker.partnership_partner_id == partner_id and partner.partnership_partner_id == worker.id:
		if worker.partnership_style_id == partner.partnership_style_id:
			style_id = worker.partnership_style_id
	var tier := "FORMING"
	var next_threshold := 60
	if score >= 90:
		tier = "SIGNATURE PAIR"
		next_threshold = 100
	elif score >= 75:
		tier = "CLUTCHMATES"
		next_threshold = 90
	elif score >= 60:
		tier = "GOOD PERCH"
		next_threshold = 75
	var choices: Array[Dictionary] = []
	for choice_id: StringName in DepartmentSimulation.PLAYBOOK_PARTNERSHIP_STYLE_DEFINITIONS:
		choices.append(_playbook_option(
			&"partnership",
			choice_id,
			DepartmentSimulation.PLAYBOOK_PARTNERSHIP_STYLE_DEFINITIONS[choice_id],
			score >= 75 and not specialization_locked,
			"Choose once at Clutchmates 75; both hens permanently learn the pair style.",
		))
	return {
		"available": score >= 60,
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"partner_id": partner.id,
		"partner_name": partner.display_name,
		"score": score,
		"tier": tier,
		"next_threshold": next_threshold,
		"specialization_unlocked": score >= 75,
		"specialization_locked": specialization_locked,
		"specialization_id": String(style_id),
		"specialization": (DepartmentSimulation.PLAYBOOK_PARTNERSHIP_STYLE_DEFINITIONS.get(style_id, {}) as Dictionary).duplicate(true),
		"choices": choices,
		"development_sources": ["TEAM LIFT", "MORALE", "STRAIN", "SOLIDARITY"],
	}


func _rival_memory_snapshot() -> Dictionary:
	var scenario := sim.scenario_identity_snapshot()
	var current_id := StringName(sim.active_playbook.get("rival_response_id", &""))
	var latest: Dictionary = sim.rival_response_history.back().duplicate(true) if not sim.rival_response_history.is_empty() else {}
	var remembered_id := current_id if current_id != &"" else StringName(latest.get("response_id", &""))
	var personality := "WATCHFUL BENCHMARKER"
	var next_intent := "Tests whether your filed plan holds under visible pressure."
	match remembered_id:
		&"defend":
			personality = "PATIENT PRESSURE"
			next_intent = "Will challenge pace because you previously protected quality."
		&"counter":
			personality = "SHELL TESTER"
			next_intent = "Will challenge quality because you previously raced the benchmark."
		&"ignore":
			personality = "FLOCK BAITER"
			next_intent = "Will widen the visible margin because you previously backed the flock."
	return {
		"rival_name": String(scenario.get("rival_name", "Golden Comb Group")),
		"personality": personality,
		"visible_intent": next_intent,
		"current_response_id": String(current_id),
		"remembered_response_id": String(remembered_id),
		"history": sim.rival_response_history.duplicate(true),
		"memory_count": sim.rival_response_history.size(),
		"persistent": true,
		"response_window": "AFTER FIRST EGG",
		"hidden_counter": false,
	}


func _automation_report_card(focused_worker_id: int) -> Dictionary:
	if focused_worker_id < 0 or focused_worker_id >= sim.workers.size() or not sim.workers[focused_worker_id].employed:
		return {"available": false, "worker_id": -1}
	var worker := sim.workers[focused_worker_id]
	var stats := sim._worker_shift_stat(focused_worker_id)
	var eggs := maxi(0, int(stats.get("eggs", 0)))
	var cracked := maxi(0, int(stats.get("cracked", 0)))
	var clean := maxi(0, eggs - cracked)
	var policy_id := worker.automation_policy_id if worker.automation_policy_unlocked else &""
	var recommendation := "KEEP MANUAL"
	if worker.automation_policy_unlocked and worker.assigned_lane == DepartmentSimulation.AUTO_ASSIGNMENT:
		recommendation = "KEEP %s" % String((DepartmentSimulation.PLAYBOOK_DELEGATION_POLICY_DEFINITIONS.get(policy_id, {}) as Dictionary).get("label", "AUTO FIT"))
		if eggs >= 2 and cracked * 3 > eggs:
			recommendation = "REVIEW POLICY"
	return {
		"available": worker.automation_policy_unlocked,
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"assignment": String(worker.assigned_lane),
		"policy_id": String(policy_id),
		"policy": (DepartmentSimulation.PLAYBOOK_DELEGATION_POLICY_DEFINITIONS.get(policy_id, {}) as Dictionary).duplicate(true),
		"handled": eggs,
		"clean": clean,
		"cracked": cracked,
		"golden": maxi(0, int(stats.get("golden", 0))),
		"credit_cents": maxi(0, int(stats.get("credit_cents", 0))),
		"clean_rate_percent": roundi(100.0 * float(clean) / float(maxi(1, eggs))),
		"exceptions_manual": true,
		"recommendation": recommendation,
	}


func _next_shift_tease_snapshot() -> Dictionary:
	var next_day := sim.day + 1
	if sim.day >= DepartmentSimulation.PROBATION_CAMPAIGN_SHIFTS:
		return {
			"day": sim.day,
			"label": "FINAL RECORD",
			"icon": "star",
			"detail": "Your plan, strongest hen, relationships, and final signature decide the permanent coop record.",
			"climax": true,
		}
	var scenario := sim.scenario_identity_snapshot()
	return {
		"day": next_day,
		"label": "DAY %d · %s" % [next_day, String(scenario.get("short", "NEXT FILE"))],
		"icon": String(scenario.get("icon", "files")),
		"detail": "%s One new pressure beat and the next visible office reward arrive after this report." % String(scenario.get("victory_twist", "The probation file keeps evolving.")),
		"one_more_shift": true,
	}


func _career_story_snapshot(focused_worker_id: int) -> Dictionary:
	if focused_worker_id < 0 or focused_worker_id >= sim.workers.size() or not sim.workers[focused_worker_id].employed:
		return {}
	var worker := sim.workers[focused_worker_id]
	var chapter := "NEW PERCH"
	if worker.career_xp >= 40:
		chapter = "FLOCK VETERAN"
	elif worker.manager_trust >= 65.0:
		chapter = "TRUSTED HAND"
	elif worker.grievance >= 45.0:
		chapter = "RELATIONSHIP AT RISK"
	return {
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"chapter": chapter,
		"beat": "Day %d · %s · trust %d" % [sim.day, worker.career_title(), roundi(worker.manager_trust)],
		"persistent_sources": ["career_xp", "manager_trust", "grievance", "flock_bond"],
	}


func _playbook_display_sockets() -> Array[Dictionary]:
	var style_index := int(sim.active_playbook.get("display_style_index", 0))
	var style_id := DepartmentSimulation.PLAYBOOK_DISPLAY_STYLE_ORDER[style_index]
	var style := DepartmentSimulation.PLAYBOOK_DISPLAY_STYLE_DEFINITIONS[style_id] as Dictionary
	return [
		{"id": "plan", "label": "PLAN", "earned": not String(sim.active_playbook.get("strategy_preset_id", "")).is_empty(), "style_id": String(style_id), "style": style.duplicate(true)},
		{"id": "contract", "label": "CONTRACT", "earned": not String(sim.active_playbook.get("contract_id", "")).is_empty(), "style_id": String(style_id), "style": style.duplicate(true)},
		{"id": "reward", "label": "REWARD", "earned": not String(sim.active_playbook.get("contract_reward_id", "")).is_empty(), "style_id": String(style_id), "style": style.duplicate(true)},
	]


func challenge_code() -> String:
	return "PO-%04d-D%d" % [posmod(sim._career_seed, 10_000), clampi(sim.day, 1, 99)]


static func first_session_comprehension_protocol() -> Dictionary:
	return {
		"participants_required": 5,
		"unaided": true,
		"tasks": ["Choose a plan", "Route one file", "Resolve one hero file", "Recover one mistake", "Explain one result"],
		"pass_rule": "At least 4 of 5 participants complete all five tasks without outside instruction.",
		"thresholds": {
			"choose_plan_unaided": "4/5",
			"route_within_seconds": 30,
			"explain_result_correctly": "4/5",
			"required_shortcut_discovery": 0,
		},
		"observations": ["eye_target", "cursor_path", "first_hesitation", "recovery_path"],
		"instrumented_events": [
			"plan_filed",
			"route_completed",
			"hero_case_resolved",
			"rescue_used",
			"result_explained",
			"shortcut_required",
			"attention_target_changed",
		],
		"real_humans_required": true,
		"results_complete": false,
		"never_fabricate": true,
		"status": "AWAITING REAL PARTICIPANTS",
	}


func playbook_snapshot(focused_worker_id: int = -1) -> Dictionary:
	sim._ensure_active_playbook()
	var contract_id := StringName(sim.active_playbook.get("contract_id", &""))
	var contract_definition := DepartmentSimulation.PLAYBOOK_CONTRACT_DEFINITIONS.get(contract_id, {}) as Dictionary
	var contract_progress := _playbook_contract_progress(contract_id)
	var contract_target := int(contract_definition.get("target", 0))
	var contract_complete := not contract_definition.is_empty() and contract_progress >= contract_target
	var side_goal_id := StringName(sim.active_playbook.get("side_goal_id", &""))
	var side_goal_definition := DepartmentSimulation.PLAYBOOK_SIDE_GOAL_DEFINITIONS.get(side_goal_id, {}) as Dictionary
	var side_goal_progress := _playbook_side_goal_progress(side_goal_id)
	var side_goal_target := int(side_goal_definition.get("target", 0))
	var options: Array[Dictionary] = []
	var running := sim.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING and sim.pending_decision.is_empty()
	var strategy_preset_id := StringName(sim.active_playbook.get("strategy_preset_id", &""))
	var recommended_preset_id := _recommended_playbook_strategy_id()
	var bundled_plan_unfiled := (
		contract_id == &""
		and String(sim.active_playbook.get("loadout_id", "")).is_empty()
		and String(sim.active_playbook.get("preparation_id", "")).is_empty()
		and side_goal_id == &""
	)
	if strategy_preset_id == &"" and bundled_plan_unfiled:
		for choice_id in DepartmentSimulation.PLAYBOOK_STRATEGY_PRESET_ORDER:
			var preset_definition := (DepartmentSimulation.PLAYBOOK_STRATEGY_PRESET_DEFINITIONS[choice_id] as Dictionary).duplicate(true)
			preset_definition["recommended"] = choice_id == recommended_preset_id
			var affordable := sim.spendable_fund_cents() >= int(preset_definition.get("cost_cents", 0))
			var planning_open := guided_plan_planning_open()
			var preset_reason := (
				"Recommended for today's policy. Files plan, challenge, preparation, and personal goal in one action."
				if choice_id == recommended_preset_id else
				"Files plan, challenge, preparation, and personal goal in one action."
			)
			if not affordable:
				preset_reason = "Feed Fund needs $2.00 spendable for the flock plan."
			elif not planning_open:
				preset_reason = "Choose before production begins (first shift: through egg three), and before resolving an incident."
			var preset_option := _playbook_option(&"preset", choice_id, preset_definition, running and affordable and planning_open, preset_reason)
			var challenge_id := CareerWorkshop.contract_for(sim.day, String(choice_id), sim.career_workshop.equipped, sim.career_workshop.tuning)
			preset_option["contract_id"] = challenge_id
			preset_option["goal"] = String((CareerWorkshop.CHALLENGES.get(challenge_id, {}) as Dictionary).get("goal", ""))
			preset_option["tip"] = String((CareerWorkshop.CHALLENGES.get(challenge_id, {}) as Dictionary).get("tip", ""))
			options.append(preset_option)
		if sim.day >= 2:
			options.append(_playbook_option(&"customize", &"advanced", {
				"label": "CUSTOM PLAN",
				"icon": &"facility",
				"gain": "CHOOSE EACH PART",
				"cost": "MORE DECISIONS",
				"risk": "ADVANCED",
				"promise": "Open the individual contract, loadout, preparation, and side-goal choices.",
			}, running, "Advanced planning unlocks after the first shift."))
	if strategy_preset_id == &"custom" and contract_id == &"":
		for choice_id: StringName in DepartmentSimulation.PLAYBOOK_CONTRACT_DEFINITIONS:
			var unlocked := sim.day >= int(DepartmentSimulation.PLAYBOOK_CONTRACT_DEFINITIONS[choice_id].get("unlock_day", 1))
			if choice_id == &"care_circle" and sim.career_workshop.equipped != "team_kettle":
				continue
			options.append(_playbook_option(&"contract", choice_id, DepartmentSimulation.PLAYBOOK_CONTRACT_DEFINITIONS[choice_id], running and unlocked, "Accept one optional shift challenge; declining has no penalty." if unlocked else "Unlocks on a later shift."))
	if strategy_preset_id == &"custom" and String(sim.active_playbook.get("loadout_id", "")).is_empty() and sim.eggs_today == 0:
		for choice_id: StringName in DepartmentSimulation.PLAYBOOK_LOADOUT_DEFINITIONS:
			options.append(_playbook_option(&"loadout", choice_id, DepartmentSimulation.PLAYBOOK_LOADOUT_DEFINITIONS[choice_id], running, "Locks when the first egg is delivered."))
	if strategy_preset_id == &"custom" and String(sim.active_playbook.get("preparation_id", "")).is_empty() and sim.incidents_resolved_today == 0:
		for choice_id: StringName in DepartmentSimulation.PLAYBOOK_PREPARATION_DEFINITIONS:
			var affordable := choice_id != &"rest_flock" or sim.spendable_fund_cents() >= 200
			options.append(_playbook_option(&"preparation", choice_id, DepartmentSimulation.PLAYBOOK_PREPARATION_DEFINITIONS[choice_id], running and affordable, "Prepare once before the first incident." if affordable else "Feed Fund needs $2.00 spendable."))
	var intervention_id := StringName(sim.active_playbook.get("manager_intervention_id", &""))
	var intervention_options: Array[Dictionary] = []
	if not strategy_preset_id.is_empty() and intervention_id == &"":
		for choice_id: StringName in DepartmentSimulation.PLAYBOOK_MANAGER_INTERVENTION_DEFINITIONS:
			var affordable := choice_id != &"coffee_run" or sim.spendable_fund_cents() >= 200
			var option := _playbook_option(
				&"intervention",
				choice_id,
				DepartmentSimulation.PLAYBOOK_MANAGER_INTERVENTION_DEFINITIONS[choice_id],
				running and affordable,
				"Spend the one manager intervention for this shift." if affordable else "Feed Fund needs $2.00 spendable.",
			)
			intervention_options.append(option)
			options.append(option)
	if (
		sim.day >= 2
		and not strategy_preset_id.is_empty()
		and String(sim.active_playbook.get("challenge_modifier_id", "")).is_empty()
		and sim.eggs_today == 0
		and sim.incidents_resolved_today == 0
	):
		for choice_id: StringName in DepartmentSimulation.PLAYBOOK_CHALLENGE_MODIFIER_DEFINITIONS:
			options.append(_playbook_option(
				&"modifier",
				choice_id,
				DepartmentSimulation.PLAYBOOK_CHALLENGE_MODIFIER_DEFINITIONS[choice_id],
				running,
				"Optional shift spice. Skip it freely; filing one changes today's rules and locks the other two.",
			))
	if String(sim.active_playbook.get("rival_response_id", "")).is_empty() and sim.eggs_today > 0:
		for choice_id: StringName in DepartmentSimulation.PLAYBOOK_RIVAL_DEFINITIONS:
			options.append(_playbook_option(&"rival", choice_id, DepartmentSimulation.PLAYBOOK_RIVAL_DEFINITIONS[choice_id], running, "One transparent response for this shift."))
	var hero_case := _hero_case_snapshot(focused_worker_id)
	if bool(hero_case.get("active", false)):
		for hero_option_value in hero_case.get("options", []) as Array:
			if hero_option_value is Dictionary:
				var hero_option := (hero_option_value as Dictionary).duplicate(true)
				hero_option["available"] = running
				options.append(hero_option)
	if strategy_preset_id == &"custom" and side_goal_id == &"":
		for choice_id: StringName in DepartmentSimulation.PLAYBOOK_SIDE_GOAL_DEFINITIONS:
			options.append(_playbook_option(&"side_goal", choice_id, DepartmentSimulation.PLAYBOOK_SIDE_GOAL_DEFINITIONS[choice_id], running, "Pin one personal ambition; no failure penalty."))
	var signature_ids := sim.active_playbook.get("signature_worker_ids", []) as Array
	var signature_reason := "Select an active hen."
	var signature_available := false
	var signature_label := "HEN SIGNATURE"
	if focused_worker_id >= 0 and focused_worker_id < sim.workers.size() and sim.workers[focused_worker_id].employed:
		var focused_worker := sim.workers[focused_worker_id]
		var preferred_action := sim._preferred_personnel_action(focused_worker)
		var preferred_definition := DepartmentSimulation.PERSONNEL_ACTION_DEFINITIONS.get(preferred_action, {}) as Dictionary
		signature_label = "%s / %s" % [focused_worker.display_name.to_upper(), String(preferred_definition.get("short_name", "SIGNATURE"))]
		signature_available = running and focused_worker_id not in signature_ids and bool(sim.personnel_action_status().get("available", false))
		signature_reason = "Uses the normal flock check-in allowance." if signature_available else "This hen's signature or today's flock allowance is already used."
	options.append(_playbook_option(&"signature", &"activate", {"label": signature_label, "icon": &"flock", "gain": "PROFILE-SPECIFIC EFFECT", "cost": "NORMAL CHECK-IN", "risk": "ONE PER HEN / SHIFT"}, signature_available, signature_reason))
	var proposal_id := sim._playbook_proposal_id(focused_worker_id)
	var proposal_open := (
		running
		and proposal_id != &""
		and int(sim.active_playbook.get("proposal_worker_id", -1)) < 0
		and not strategy_preset_id.is_empty()
	)
	if proposal_id != &"":
		var proposal_definition := DepartmentSimulation.PLAYBOOK_HEN_PROPOSAL_DEFINITIONS[proposal_id] as Dictionary
		options.append(_playbook_option(
			&"proposal",
			proposal_id,
			proposal_definition,
			proposal_open,
			"%s is proposing this herself; accept or ignore it with no failure penalty." % sim.workers[focused_worker_id].display_name,
		))
	var teamwork_available := false
	var teamwork_reason := "Select a bonded hen with a Good Perch or Clutchmates relationship."
	var teamwork_ability: Dictionary = {}
	var partnership := _partnership_progression_snapshot(focused_worker_id)
	if focused_worker_id >= 0 and focused_worker_id < sim.workers.size() and sim.workers[focused_worker_id].employed:
		var bond := sim._worker_flock_bond_snapshot(sim.workers[focused_worker_id])
		teamwork_available = running and not bool(sim.active_playbook.get("teamwork_used", false)) and int(bond.get("score", 0)) >= 60
		var partner_id := int(bond.get("partner_id", -1))
		if partner_id >= 0 and partner_id < sim.workers.size():
			teamwork_ability = _team_lift_ability(sim.workers[focused_worker_id], sim.workers[partner_id])
		teamwork_reason = "%s + %s at %d/100; %s." % [
			sim.workers[focused_worker_id].display_name,
			String(bond.get("partner_name", "PERCHMATE")),
			int(bond.get("score", 0)),
			String(teamwork_ability.get("summary", "restore morale and one attention charge")),
		]
	options.append(_playbook_option(&"teamwork", &"team_lift", {
		"label": String(teamwork_ability.get("label", "TEAM LIFT")),
		"icon": teamwork_ability.get("icon", &"sync"),
		"gain": String(teamwork_ability.get("gain", "PAIR MORALE + ATTENTION")),
		"cost": "ONCE / SHIFT",
		"risk": "REQUIRES BOND 60",
	}, teamwork_available, teamwork_reason))
	if (
		bool(partnership.get("specialization_unlocked", false))
		and not bool(partnership.get("specialization_locked", false))
	):
		for partnership_choice_value in partnership.get("choices", []) as Array:
			if partnership_choice_value is Dictionary:
				var partnership_choice := (partnership_choice_value as Dictionary).duplicate(true)
				partnership_choice["available"] = running
				options.append(partnership_choice)
	if contract_complete and String(sim.active_playbook.get("contract_reward_id", "")).is_empty():
		for choice_id: StringName in DepartmentSimulation.PLAYBOOK_REWARD_DEFINITIONS:
			options.append(_playbook_option(&"reward", choice_id, DepartmentSimulation.PLAYBOOK_REWARD_DEFINITIONS[choice_id], running, "Claim one reward for the completed optional contract."))
	if sim.eggs_today >= sim.quota_target and String(sim.active_playbook.get("push_luck_id", "")).is_empty():
		for choice_id: StringName in DepartmentSimulation.PLAYBOOK_PUSH_LUCK_DEFINITIONS:
			options.append(_playbook_option(
				&"push_luck",
				choice_id,
				DepartmentSimulation.PLAYBOOK_PUSH_LUCK_DEFINITIONS[choice_id],
				running,
				"Quota is safe. Choose whether the rest of this shift protects the clutch or presses for premium value.",
			))
	var mastery_auto_available := (
		running
		and sim.routing_momentum_chain >= DepartmentSimulation.ROUTING_MOMENTUM_PACE_MILESTONE
		and not bool(sim.active_playbook.get("mastery_auto_used", false))
		and focused_worker_id >= 0
		and focused_worker_id < sim.workers.size()
		and sim.workers[focused_worker_id].employed
	)
	if sim.routing_momentum_chain >= DepartmentSimulation.ROUTING_MOMENTUM_PACE_MILESTONE:
		options.append(_playbook_option(&"automation", &"auto_fit", {
			"label": "TEACH AUTO FIT",
			"icon": &"route",
			"gain": "SELECTED HEN ROUTES BY FIT",
			"cost": "USES MASTERY MARK",
			"risk": "EXCEPTIONS STAY MANUAL",
		}, mastery_auto_available, "Select the hen whose solved route should now run automatically."))
	var delegation_policy_id: StringName = &""
	var delegation_policy_unlocked := false
	if focused_worker_id >= 0 and focused_worker_id < sim.workers.size() and sim.workers[focused_worker_id].employed:
		var focused_automation_worker := sim.workers[focused_worker_id]
		delegation_policy_id = focused_automation_worker.automation_policy_id
		delegation_policy_unlocked = (
			focused_automation_worker.automation_policy_unlocked
			and focused_automation_worker.assigned_lane == DepartmentSimulation.AUTO_ASSIGNMENT
		)
		if delegation_policy_unlocked:
			for policy_id: StringName in DepartmentSimulation.PLAYBOOK_DELEGATION_POLICY_DEFINITIONS:
				if policy_id == delegation_policy_id:
					continue
				options.append(_playbook_option(
					&"automation_policy",
					policy_id,
					DepartmentSimulation.PLAYBOOK_DELEGATION_POLICY_DEFINITIONS[policy_id],
					running,
					"Reversible management rule for this hen's future routine files.",
				))
	var recovery_open := (
		running
		and String(sim.active_playbook.get("recovery_id", "")).is_empty()
		and (sim.revenue_cents < 2500 or sim.executive_confidence < 45.0 or sim._average_worker_stress() >= 55.0)
	)
	if recovery_open:
		for choice_id: StringName in DepartmentSimulation.PLAYBOOK_RECOVERY_DEFINITIONS:
			var affordable := choice_id != &"repair_flock" or sim.spendable_fund_cents() >= 300
			options.append(_playbook_option(&"recovery", choice_id, DepartmentSimulation.PLAYBOOK_RECOVERY_DEFINITIONS[choice_id], affordable, "Choose one comeback plan." if affordable else "Feed Fund needs $3.00 spendable."))
	var rescue_open := (
		running
		and not bool(sim.active_playbook.get("rescue_used", false))
		and StringName(sim.active_playbook.get("challenge_modifier_id", &"")) != &"one_bell"
		and focused_worker_id >= 0
		and (sim.cracked_today > 0 or (sim.eggs_today > 0 and sim.routing_momentum_chain == 0) or sim._overdue_claim_count(false) > 0)
	)
	if rescue_open:
		options.append(_playbook_option(&"rescue", &"show_me", {
			"label": "SHOW ME",
			"icon": &"route",
			"gain": "SPECIALTY ROUTE + ATTENTION",
			"cost": "ONE RESCUE / SHIFT",
			"risk": "NO BONUS REWARD",
		}, true, "A contextual recovery: fit the selected hen to her specialty and restore one help charge."))
	if String(sim.active_playbook.get("toy_id", "")).is_empty() and sim.eggs_today > 0:
		for toy_id: StringName in DepartmentSimulation.PLAYBOOK_OFFICE_TOY_DEFINITIONS:
			options.append(_playbook_option(&"toy", toy_id, DepartmentSimulation.PLAYBOOK_OFFICE_TOY_DEFINITIONS[toy_id], running, "A tiny physical office beat; once per shift and never required."))
	var episode_id := _rare_office_episode_id()
	if episode_id != &"" and not bool(sim.active_playbook.get("rare_episode_resolved", false)):
		var episode_definition := DepartmentSimulation.PLAYBOOK_RARE_EPISODE_DEFINITIONS[episode_id] as Dictionary
		var episode_affordable := episode_id != &"printer_revolt" or sim.spendable_fund_cents() >= 100
		options.append(_playbook_option(&"episode", episode_id, episode_definition, running and episode_affordable, "One authored office episode in this five-shift docket." if episode_affordable else "The printer repair needs $1.00 spendable."))
	if not strategy_preset_id.is_empty():
		var next_style_index := (int(sim.active_playbook.get("display_style_index", 0)) + 1) % DepartmentSimulation.PLAYBOOK_DISPLAY_STYLE_ORDER.size()
		var next_style_id := DepartmentSimulation.PLAYBOOK_DISPLAY_STYLE_ORDER[next_style_index]
		var next_style := DepartmentSimulation.PLAYBOOK_DISPLAY_STYLE_DEFINITIONS[next_style_id] as Dictionary
		options.append(_playbook_option(&"display", next_style_id, {
			"label": "DISPLAY: %s" % String(next_style.get("label", "STYLE")),
			"icon": next_style.get("icon", &"facility"),
			"gain": "RESTYLE 3 FIXED SOCKETS",
			"cost": "NONE",
			"risk": "COSMETIC ONLY",
		}, running, "Cycles the earned plan, contract, and reward display—never free placement."))
	options.append(_playbook_option(&"challenge", &"copy_code", {
		"label": "COPY %s" % sim.challenge_code(),
		"icon": &"files",
		"gain": "SHARE THIS DOCKET",
		"cost": "NONE",
		"risk": "SAME SEED / DAY",
	}, running, "Copy a compact deterministic challenge code."))
	options.append(_playbook_option(&"practice", &"peck", {"label": "PRACTICE PECK", "icon": &"sync", "gain": "TIMING FEEDBACK", "cost": "NONE", "risk": "NO REWARD"}, running and focused_worker_id >= 0, "Reads the current timing cursor without spending attention or changing the file."))
	var directive_combo := {
		&"record_harvest": {"id": "harvest_hustle", "label": "HARVEST HUSTLE", "icon": "egg", "effect": "PACE +5%"},
		&"shell_assurance": {"id": "shell_lock", "label": "SHELL LOCK", "icon": "shield", "effect": "SHELL RISK -2%"},
		&"sustainable_flock": {"id": "perch_partners", "label": "PERCH PARTNERS", "icon": "care", "effect": "STRAIN -10%"},
	}.get(sim.active_directive_id, {"id": "unfiled", "label": "COMBO LOCKED", "icon": "sync", "effect": "FILE A POLICY"}) as Dictionary
	var combo_active := sim.routing_momentum_chain >= DepartmentSimulation.ROUTING_MOMENTUM_PACE_MILESTONE
	var combo_recipe := sim._playbook_combo_recipe_snapshot()
	var contract_snapshot := {"id": String(contract_id), "label": String(contract_definition.get("label", "PICK CONTRACT")), "icon": String(contract_definition.get("icon", "goal")), "progress": contract_progress, "target": contract_target, "complete": contract_complete, "reward_claimed": not String(sim.active_playbook.get("contract_reward_id", "")).is_empty(), "reward_id": String(sim.active_playbook.get("contract_reward_id", "")), "optional": true, "failure_penalty": 0}
	contract_snapshot.merge(CareerWorkshop.CHALLENGES.get(String(contract_id), {}) as Dictionary, true)
	var side_goal_snapshot := {"id": String(side_goal_id), "label": String(side_goal_definition.get("label", "PIN A GOAL")), "icon": String(side_goal_definition.get("icon", "goal")), "progress": side_goal_progress, "target": side_goal_target, "complete": not side_goal_definition.is_empty() and side_goal_progress >= side_goal_target, "failure_penalty": 0}
	var prediction_score := _playbook_prediction_snapshot(contract_snapshot)
	return {
		"day": sim.day,
		"authoritative": true,
		"options": options,
		"strategy_preset_id": String(strategy_preset_id),
		"strategy_preset": (DepartmentSimulation.PLAYBOOK_STRATEGY_PRESET_DEFINITIONS.get(strategy_preset_id, {}) as Dictionary).duplicate(true),
		"recommended_preset_id": String(recommended_preset_id),
		"smart_default": {
			"id": String(recommended_preset_id),
			"label": String((DepartmentSimulation.PLAYBOOK_STRATEGY_PRESET_DEFINITIONS[recommended_preset_id] as Dictionary).get("label", "SAFE PLAN")),
			"automatic": false,
			"one_click": true,
		},
		"strategy_comparison": {
			"current_id": String(strategy_preset_id),
			"recommended_id": String(recommended_preset_id),
			"reversible_preview": true,
			"changes_authority": false,
			"plans": _strategy_comparison_catalog(strategy_preset_id, recommended_preset_id),
		},
		"contract": contract_snapshot,
		"workshop": sim.career_workshop.snapshot(sim.day, String(contract_id)),
		"combo": {"id": String(directive_combo.get("id", "")), "label": String(directive_combo.get("label", "COMBO")), "icon": String(directive_combo.get("icon", "sync")), "active": combo_active, "progress": sim.routing_momentum_chain, "target": DepartmentSimulation.ROUTING_MOMENTUM_PACE_MILESTONE, "effect": String(directive_combo.get("effect", ""))},
		"combo_recipe": combo_recipe,
		"prediction_score": prediction_score,
		"dominant_objective": _playbook_primary_objective_snapshot(options),
		"shift_plan": _playbook_shift_plan(contract_definition, directive_combo),
		"shift_journey": _playbook_shift_journey(contract_complete),
		"opening_spotlight": {
			"active": sim.day == 1 and sim.eggs_today == 0,
			"path": [
				{"icon": "goal", "label": "PICK PLAN", "world_target": "plan_button"},
				{"icon": "route", "label": "ROUTE FILE", "world_target": "intake_tray"},
				{"icon": "egg", "label": "SEE RESULT", "world_target": "farmer_basket"},
			],
			"skippable": true,
		},
		"core_verbs": ["INSPECT", "ROUTE", "HELP", "PECK", "INVEST"],
		"choice_budget": {"major": 1, "optional": 1, "surprise": 1, "detail": "One major plan, one optional goal, and one visible surprise at a time."},
		"session_target_minutes": {"minimum": 8, "maximum": 12},
		"preparation_id": String(sim.active_playbook.get("preparation_id", "")),
		"manager_intervention": {
			"id": String(intervention_id),
			"definition": (DepartmentSimulation.PLAYBOOK_MANAGER_INTERVENTION_DEFINITIONS.get(intervention_id, {}) as Dictionary).duplicate(true),
			"used": intervention_id != &"",
			"one_per_shift": true,
			"options": intervention_options,
		},
		"rival_response_id": String(sim.active_playbook.get("rival_response_id", "")),
		"rival_memory": _rival_memory_snapshot(),
		"loadout_id": String(sim.active_playbook.get("loadout_id", "")),
		"recovery_id": String(sim.active_playbook.get("recovery_id", "")),
		"side_goal": side_goal_snapshot,
		"challenge_modifier": {
			"id": String(sim.active_playbook.get("challenge_modifier_id", "")),
			"definition": (DepartmentSimulation.PLAYBOOK_CHALLENGE_MODIFIER_DEFINITIONS.get(StringName(sim.active_playbook.get("challenge_modifier_id", &"")), {}) as Dictionary).duplicate(true),
			"optional": true,
			"skippable": true,
		},
		"teamwork_used": bool(sim.active_playbook.get("teamwork_used", false)),
		"teamwork": {
			"used": bool(sim.active_playbook.get("teamwork_used", false)),
			"available": teamwork_available,
			"ability": teamwork_ability.duplicate(true),
		},
		"partnership": partnership,
		"hero_case": hero_case,
		"hero_case_history": sim.hero_case_history.duplicate(true),
		"automation_report": _automation_report_card(focused_worker_id),
		"push_luck": {
			"id": String(sim.active_playbook.get("push_luck_id", "")),
			"start_eggs": int(sim.active_playbook.get("push_luck_start_eggs", 0)),
			"open": sim.eggs_today >= sim.quota_target,
		},
		"mastery_automation": {
			"ready": mastery_auto_available,
			"used": bool(sim.active_playbook.get("mastery_auto_used", false)),
			"chain": sim.routing_momentum_chain,
			"target": DepartmentSimulation.ROUTING_MOMENTUM_PACE_MILESTONE,
			"policy_id": String(delegation_policy_id),
			"policy_unlocked": delegation_policy_unlocked,
			"policy": (DepartmentSimulation.PLAYBOOK_DELEGATION_POLICY_DEFINITIONS.get(delegation_policy_id, {}) as Dictionary).duplicate(true),
			"rules": _delegation_policy_catalog(),
		},
		"hen_proposal": {
			"worker_id": int(sim.active_playbook.get("proposal_worker_id", focused_worker_id)),
			"id": String(sim.active_playbook.get("proposal_id", proposal_id)),
			"accepted": int(sim.active_playbook.get("proposal_worker_id", -1)) >= 0,
			"optional": true,
		},
		"contextual_rescue": {"used": bool(sim.active_playbook.get("rescue_used", false)), "available": rescue_open, "label": "SHOW ME"},
		"office_toy": {"id": String(sim.active_playbook.get("toy_id", "")), "used": not String(sim.active_playbook.get("toy_id", "")).is_empty(), "optional": true},
		"rare_episode": {"id": String(episode_id), "active": episode_id != &"", "resolved": bool(sim.active_playbook.get("rare_episode_resolved", false)), "authored": true},
		"display_sockets": _playbook_display_sockets(),
		"build_identity": sim._build_identity_snapshot(),
		"strategy_mastery": _playbook_strategy_mastery_snapshot(combo_recipe, contract_snapshot, side_goal_snapshot),
		"career_story": _career_story_snapshot(focused_worker_id),
		"relationship_echo": _playbook_relationship_echo_snapshot(focused_worker_id),
		"personal_best": {
			"routing": {"current": sim.routing_momentum_chain, "best": sim.best_routing_momentum_chain, "delta": sim.routing_momentum_chain - sim.best_routing_momentum_chain},
			"quality": {"current": sim.quality_streak, "best": sim.best_quality_streak, "delta": sim.quality_streak - sim.best_quality_streak},
		},
		"challenge": {"code": sim.challenge_code(), "seed": sim._career_seed, "day": sim.day, "shareable": true},
		"comprehension_study": first_session_comprehension_protocol(),
		"boss_file": {"active": sim.day == DepartmentSimulation.PROBATION_CAMPAIGN_SHIFTS, "label": String(sim.scenario_identity_snapshot().get("climax_title", "FINAL HEARING")), "mechanics": ["POLICY", "INCIDENT", "CREDIT"]},
		"next_shift_preview": _next_shift_tease_snapshot(),
		"campaign_legacy_evidence": sim._campaign_legacy_evidence_snapshot() if sim.day == DepartmentSimulation.PROBATION_CAMPAIGN_SHIFTS else {},
		"opportunity_shapes": [
			{"id": "golden", "icon": "golden", "shape": "star", "active": sim.routing_momentum_golden_target_worker_id >= 0},
			{"id": "urgent", "icon": "status_need", "shape": "diamond", "active": sim._overdue_claim_count(false) > 0},
			{"id": "teamwork", "icon": "sync", "shape": "linked", "active": teamwork_available},
			{"id": "contract", "icon": "goal", "shape": "stamp", "active": contract_complete},
		],
		"last_receipt": (sim.active_playbook.get("last_receipt", {}) as Dictionary).duplicate(true),
		"receipt_serial": int(sim.active_playbook.get("receipt_serial", 0)),
	}


func _playbook_shift_plan(contract_definition: Dictionary, combo: Dictionary) -> Array[Dictionary]:
	return [
		{"id": "observe", "icon": "goal", "label": String(sim.active_directive_snapshot().get("short_name", "PICK POLICY"))},
		{"id": "act", "icon": String(combo.get("icon", "sync")), "label": String(combo.get("label", "BUILD COMBO"))},
		{"id": "reward", "icon": String(contract_definition.get("icon", "egg")), "label": String(contract_definition.get("label", "PICK CONTRACT"))},
	]


func perform_playbook_action(kind: StringName, choice_id: StringName, worker_id: int = -1) -> Dictionary:
	sim._ensure_active_playbook()
	if sim.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING or not sim.pending_decision.is_empty():
		return {"accepted": false, "reason": "Resolve the current management file first."}
	if kind == &"workshop":
		if String(sim.active_playbook.get("contract_id", "")) == "care_circle" and String(choice_id).get_slice("/", 0) != "team_kettle" and not (sim.career_workshop.daily_day == sim.day and sim.career_workshop.loadout_locked):
			return {"accepted": false, "reason": "Care Circle needs the kettle. Keep it equipped for this challenge."}
		var workshop_result := sim.career_workshop.choose(String(choice_id), sim.day, true)
		return sim._file_playbook_receipt(workshop_result) if bool(workshop_result.get("accepted", false)) else workshop_result
	if kind == &"hero_case":
		return _perform_playbook_hero_case(choice_id, worker_id)
	if kind == &"intervention":
		if not DepartmentSimulation.PLAYBOOK_MANAGER_INTERVENTION_DEFINITIONS.has(choice_id):
			return {"accepted": false, "reason": "That manager intervention is unavailable."}
		if String(sim.active_playbook.get("strategy_preset_id", "")).is_empty():
			return {"accepted": false, "reason": "File a shift plan before intervening."}
		if not String(sim.active_playbook.get("manager_intervention_id", "")).is_empty():
			return {"accepted": false, "reason": "The one manager intervention for this shift is already used."}
		var outcome := ""
		match choice_id:
			&"ring_bell":
				sim.routing_momentum_peck_recharge_bank = maxi(1, sim.routing_momentum_peck_recharge_bank)
				outcome = "The bell restores one attention charge for a visible recovery or precision play."
			&"coffee_run":
				if sim.spendable_fund_cents() < 200:
					return {"accepted": false, "reason": "The coffee run needs $2.00 spendable Feed Fund."}
				sim.revenue_cents -= 200
				sim._adjust_workers(2.0, -4.0, -2.0)
				outcome = "The flock takes a real breather: morale rises while strain and fatigue fall."
			&"emergency_review":
				sim.compliance = minf(100.0, sim.compliance + 3.0)
				outcome = "The emergency review trades 2% pace for 1.5% lower shell risk and 3 compliance."
		sim.active_playbook["manager_intervention_id"] = String(choice_id)
		return sim._file_playbook_receipt(_playbook_choice_result(
			kind,
			choice_id,
			DepartmentSimulation.PLAYBOOK_MANAGER_INTERVENTION_DEFINITIONS[choice_id],
			outcome,
		))
	if kind == &"proposal":
		if not DepartmentSimulation.PLAYBOOK_HEN_PROPOSAL_DEFINITIONS.has(choice_id) or int(sim.active_playbook.get("proposal_worker_id", -1)) >= 0:
			return {"accepted": false, "reason": "This shift's hen proposal is already answered or unavailable."}
		if worker_id < 0 or worker_id >= sim.workers.size() or not sim.workers[worker_id].employed or sim._playbook_proposal_id(worker_id) != choice_id:
			return {"accepted": false, "reason": "Select the hen who made this proposal."}
		var proposal_worker := sim.workers[worker_id]
		match choice_id:
			&"own_lane":
				sim.set_worker_assignment(worker_id, proposal_worker.specialty)
				proposal_worker.manager_trust = minf(100.0, proposal_worker.manager_trust + 3.0)
			&"pair_perch":
				var proposal_bond := sim._worker_flock_bond_snapshot(proposal_worker)
				var proposal_partner_id := int(proposal_bond.get("partner_id", -1))
				if proposal_partner_id < 0 or proposal_partner_id >= sim.workers.size():
					return {"accepted": false, "reason": "That perch bond is no longer available."}
				for teammate_id in [worker_id, proposal_partner_id]:
					sim.workers[teammate_id].morale = minf(100.0, sim.workers[teammate_id].morale + 3.0)
					sim.workers[teammate_id].stress = maxf(0.0, sim.workers[teammate_id].stress - 2.0)
			&"protect_clutch":
				proposal_worker.stress = maxf(0.0, proposal_worker.stress - 4.0)
				proposal_worker.fatigue = maxf(0.0, proposal_worker.fatigue - 3.0)
		sim.active_playbook["proposal_worker_id"] = worker_id
		sim.active_playbook["proposal_id"] = String(choice_id)
		return sim._file_playbook_receipt(_playbook_choice_result(
			kind,
			choice_id,
			DepartmentSimulation.PLAYBOOK_HEN_PROPOSAL_DEFINITIONS[choice_id],
			"%s's %s proposal is now visible in the floor plan." % [proposal_worker.display_name, String(DepartmentSimulation.PLAYBOOK_HEN_PROPOSAL_DEFINITIONS[choice_id].get("label", "hen"))],
		))
	if kind == &"rescue":
		if choice_id != &"show_me" or bool(sim.active_playbook.get("rescue_used", false)):
			return {"accepted": false, "reason": "Show Me is already used or unavailable."}
		if worker_id < 0 or worker_id >= sim.workers.size() or not sim.workers[worker_id].employed:
			return {"accepted": false, "reason": "Select an active hen for the rescue route."}
		sim.set_worker_assignment(worker_id, sim.workers[worker_id].specialty)
		sim.routing_momentum_peck_recharge_bank = maxi(1, sim.routing_momentum_peck_recharge_bank)
		sim.active_playbook["rescue_used"] = true
		return sim._file_playbook_receipt({
			"accepted": true, "playbook_kind": "rescue", "choice_id": "show_me", "worker_id": worker_id,
			"label": "SHOW ME", "effects": {"gain": "SPECIALTY ROUTE + ATTENTION", "cost": "ONE RESCUE / SHIFT", "risk": "NO BONUS REWARD"},
			"outcome": "%s is back on her specialty lane; one help charge is ready. No reward was granted." % sim.workers[worker_id].display_name, "day": sim.day,
		})
	if kind == &"toy":
		if not DepartmentSimulation.PLAYBOOK_OFFICE_TOY_DEFINITIONS.has(choice_id) or not String(sim.active_playbook.get("toy_id", "")).is_empty():
			return {"accepted": false, "reason": "The office already had its playful beat this shift."}
		var toy_worker_id := worker_id
		if toy_worker_id < 0 or toy_worker_id >= sim.workers.size() or not sim.workers[toy_worker_id].employed:
			for candidate in sim.workers:
				if candidate.employed:
					toy_worker_id = candidate.id
					break
		if toy_worker_id >= 0:
			sim.workers[toy_worker_id].morale = minf(100.0, sim.workers[toy_worker_id].morale + 1.0)
			if choice_id == &"cooler_break":
				sim.workers[toy_worker_id].stress = maxf(0.0, sim.workers[toy_worker_id].stress - 2.0)
		sim.active_playbook["toy_id"] = String(choice_id)
		return sim._file_playbook_receipt(_playbook_choice_result(kind, choice_id, DepartmentSimulation.PLAYBOOK_OFFICE_TOY_DEFINITIONS[choice_id], "%s reacted to the %s. Small, optional, and done for this shift." % [sim.workers[toy_worker_id].display_name, String(DepartmentSimulation.PLAYBOOK_OFFICE_TOY_DEFINITIONS[choice_id].get("label", "office toy")).to_lower()]))
	if kind == &"episode":
		if choice_id != _rare_office_episode_id() or bool(sim.active_playbook.get("rare_episode_resolved", false)):
			return {"accepted": false, "reason": "That office episode is not active."}
		match choice_id:
			&"printer_revolt":
				if sim.spendable_fund_cents() < 100:
					return {"accepted": false, "reason": "The printer repair needs $1.00 spendable."}
				sim.revenue_cents -= 100
				sim.routing_momentum_peck_recharge_bank = maxi(1, sim.routing_momentum_peck_recharge_bank)
			&"coffee_union":
				sim._adjust_workers(0.0, -3.0, -2.0)
			&"bell_audit":
				sim.compliance = minf(100.0, sim.compliance + 2.0)
				sim._adjust_workers(-1.0, 0.0, 0.0)
		sim.active_playbook["rare_episode_resolved"] = true
		return sim._file_playbook_receipt(_playbook_choice_result(kind, choice_id, DepartmentSimulation.PLAYBOOK_RARE_EPISODE_DEFINITIONS[choice_id], "%s resolved. Its disclosed trade is now part of this docket's story." % String(DepartmentSimulation.PLAYBOOK_RARE_EPISODE_DEFINITIONS[choice_id].get("label", "Office episode"))))
	if kind == &"display":
		if choice_id not in DepartmentSimulation.PLAYBOOK_DISPLAY_STYLE_ORDER:
			return {"accepted": false, "reason": "That fixed display style is unavailable."}
		sim.active_playbook["display_style_index"] = DepartmentSimulation.PLAYBOOK_DISPLAY_STYLE_ORDER.find(choice_id)
		return sim._file_playbook_receipt({"accepted": true, "playbook_kind": "display", "choice_id": String(choice_id), "label": "DISPLAY RESTYLED", "effects": {"gain": "3 FIXED SOCKETS", "cost": "NONE", "risk": "COSMETIC ONLY"}, "outcome": "The plan, contract, and reward sockets now use %s. Nothing can overlap the office floor." % String(DepartmentSimulation.PLAYBOOK_DISPLAY_STYLE_DEFINITIONS[choice_id].get("label", "this style")), "day": sim.day})
	if kind == &"challenge":
		if choice_id != &"copy_code":
			return {"accepted": false, "reason": "That challenge code action is unavailable."}
		return {"accepted": true, "playbook_kind": "challenge", "choice_id": "copy_code", "label": "CHALLENGE CODE", "code": sim.challenge_code(), "changes_authority": false, "outcome": "%s is ready to share." % sim.challenge_code(), "day": sim.day}
	if kind == &"modifier":
		if sim.day < 2 or not DepartmentSimulation.PLAYBOOK_CHALLENGE_MODIFIER_DEFINITIONS.has(choice_id):
			return {"accepted": false, "reason": "Optional shift modifiers unlock after the first shift."}
		if (
			not String(sim.active_playbook.get("challenge_modifier_id", "")).is_empty()
			or String(sim.active_playbook.get("strategy_preset_id", "")).is_empty()
			or sim.eggs_today > 0
			or sim.incidents_resolved_today > 0
		):
			return {"accepted": false, "reason": "Choose one optional modifier after the plan and before production begins."}
		sim.active_playbook["challenge_modifier_id"] = String(choice_id)
		if choice_id == &"rush_hour":
			sim.quota_target += 2
		var modifier_definition := DepartmentSimulation.PLAYBOOK_CHALLENGE_MODIFIER_DEFINITIONS[choice_id] as Dictionary
		return sim._file_playbook_receipt(_playbook_choice_result(
			kind,
			choice_id,
			modifier_definition,
			"%s filed. %s" % [String(modifier_definition.get("label", "Shift modifier")), String(modifier_definition.get("rule", "Today's rules changed visibly."))],
		))
	if kind == &"preset":
		if not DepartmentSimulation.PLAYBOOK_STRATEGY_PRESET_DEFINITIONS.has(choice_id):
			return {"accepted": false, "reason": "That guided plan is unavailable."}
		if (
			not String(sim.active_playbook.get("strategy_preset_id", "")).is_empty()
			or not String(sim.active_playbook.get("contract_id", "")).is_empty()
			or not String(sim.active_playbook.get("loadout_id", "")).is_empty()
			or not String(sim.active_playbook.get("preparation_id", "")).is_empty()
			or not String(sim.active_playbook.get("side_goal_id", "")).is_empty()
			or not guided_plan_planning_open()
		):
			return {"accepted": false, "reason": "Today's guided plan is already filed or production has begun."}
		var preset := DepartmentSimulation.PLAYBOOK_STRATEGY_PRESET_DEFINITIONS[choice_id] as Dictionary
		var preset_cost := int(preset.get("cost_cents", 0))
		if sim.spendable_fund_cents() < preset_cost:
			return {"accepted": false, "reason": "The %s needs $%.2f spendable Feed Fund." % [String(preset.get("label", "plan")).to_lower(), float(preset_cost) / 100.0]}
		if preset_cost > 0:
			sim.revenue_cents -= preset_cost
		sim.active_playbook["strategy_preset_id"] = String(choice_id)
		sim.active_playbook["contract_id"] = CareerWorkshop.contract_for(sim.day, String(choice_id), sim.career_workshop.equipped, sim.career_workshop.tuning)
		sim.active_playbook["loadout_id"] = String(preset.get("loadout_id", ""))
		sim.active_playbook["preparation_id"] = String(preset.get("preparation_id", ""))
		sim.active_playbook["side_goal_id"] = String(preset.get("side_goal_id", ""))
		sim.active_playbook["side_goal_fund_baseline_cents"] = sim.revenue_cents
		var preset_result := _playbook_choice_result(
			kind,
			choice_id,
			preset,
			"%s filed in one move. Follow the highlighted world target, then draft the completed contract reward." % String(preset.get("label", "Guided plan")),
		)
		preset_result["bundled_choices"] = {
			"contract_id": String(sim.active_playbook["contract_id"]),
			"loadout_id": String(sim.active_playbook["loadout_id"]),
			"preparation_id": String(sim.active_playbook["preparation_id"]),
			"side_goal_id": String(sim.active_playbook["side_goal_id"]),
		}
		preset_result["cost_cents"] = preset_cost
		return sim._file_playbook_receipt(preset_result)
	if kind == &"customize":
		if choice_id != &"advanced" or sim.day < 2:
			return {"accepted": false, "reason": "Advanced planning unlocks after the first shift."}
		if not String(sim.active_playbook.get("strategy_preset_id", "")).is_empty() or sim.eggs_today > 0:
			return {"accepted": false, "reason": "Today's plan is already filed or production has begun."}
		sim.active_playbook["strategy_preset_id"] = "custom"
		return sim._file_playbook_receipt({
			"accepted": true,
			"playbook_kind": "customize",
			"choice_id": "advanced",
			"label": "CUSTOM PLAN",
			"effects": {"gain": "CHOOSE EACH PART", "cost": "MORE DECISIONS", "risk": "ADVANCED"},
			"outcome": "Custom planning opened. Choose one challenge, floor focus, preparation, and personal goal.",
			"day": sim.day,
		})
	if kind == &"signature":
		if worker_id < 0 or worker_id >= sim.workers.size() or not sim.workers[worker_id].employed:
			return {"accepted": false, "reason": "Select an active hen first."}
		var used_ids := sim.active_playbook.get("signature_worker_ids", []) as Array
		if worker_id in used_ids:
			return {"accepted": false, "reason": "%s already used her signature this shift." % sim.workers[worker_id].display_name}
		var action_id := sim._preferred_personnel_action(sim.workers[worker_id])
		var signature_result := sim.perform_personnel_action(worker_id, action_id)
		if not bool(signature_result.get("accepted", false)):
			return signature_result
		used_ids.append(worker_id)
		sim.active_playbook["signature_worker_ids"] = used_ids
		signature_result["playbook_kind"] = "signature"
		signature_result["signature"] = true
		return sim._file_playbook_receipt(signature_result)
	if kind == &"contract":
		if not DepartmentSimulation.PLAYBOOK_CONTRACT_DEFINITIONS.has(choice_id) or not String(sim.active_playbook.get("contract_id", "")).is_empty():
			return {"accepted": false, "reason": "This shift's optional contract is already filed."}
		if sim.day < int(DepartmentSimulation.PLAYBOOK_CONTRACT_DEFINITIONS[choice_id].get("unlock_day", 1)):
			return {"accepted": false, "reason": "That challenge unlocks on a later shift."}
		if choice_id == &"care_circle" and sim.career_workshop.equipped != "team_kettle":
			return {"accepted": false, "reason": "Equip the Team Kettle before choosing Care Circle."}
		sim.active_playbook["contract_id"] = String(choice_id)
		return sim._file_playbook_receipt(_playbook_choice_result(kind, choice_id, DepartmentSimulation.PLAYBOOK_CONTRACT_DEFINITIONS[choice_id], "Optional contract accepted. Missing it carries no penalty."))
	if kind == &"loadout":
		if not DepartmentSimulation.PLAYBOOK_LOADOUT_DEFINITIONS.has(choice_id) or not String(sim.active_playbook.get("loadout_id", "")).is_empty() or sim.eggs_today > 0:
			return {"accepted": false, "reason": "The floor loadout locks after selection or first delivery."}
		sim.active_playbook["loadout_id"] = String(choice_id)
		return sim._file_playbook_receipt(_playbook_choice_result(kind, choice_id, DepartmentSimulation.PLAYBOOK_LOADOUT_DEFINITIONS[choice_id], "Office loadout filed for this shift."))
	if kind == &"preparation":
		if not DepartmentSimulation.PLAYBOOK_PREPARATION_DEFINITIONS.has(choice_id) or not String(sim.active_playbook.get("preparation_id", "")).is_empty() or sim.incidents_resolved_today > 0:
			return {"accepted": false, "reason": "Incident preparation is already locked."}
		if choice_id == &"rest_flock":
			if sim.spendable_fund_cents() < 200:
				return {"accepted": false, "reason": "Rest preparation needs $2.00 spendable Feed Fund."}
			sim.revenue_cents -= 200
		sim.active_playbook["preparation_id"] = String(choice_id)
		return sim._file_playbook_receipt(_playbook_choice_result(kind, choice_id, DepartmentSimulation.PLAYBOOK_PREPARATION_DEFINITIONS[choice_id], "Preparation will alter the first pressure response."))
	if kind == &"rival":
		if not DepartmentSimulation.PLAYBOOK_RIVAL_DEFINITIONS.has(choice_id) or not String(sim.active_playbook.get("rival_response_id", "")).is_empty() or sim.eggs_today <= 0:
			return {"accepted": false, "reason": "The rival response opens after the first delivery and files once."}
		sim.active_playbook["rival_response_id"] = String(choice_id)
		if choice_id == &"ignore":
			sim.solidarity = minf(100.0, sim.solidarity + 2.0)
		var rival_definition := DepartmentSimulation.PLAYBOOK_RIVAL_DEFINITIONS[choice_id] as Dictionary
		var scenario := sim.scenario_identity_snapshot()
		sim.rival_response_history.append({
			"day": sim.day,
			"response_id": String(choice_id),
			"response_label": String(rival_definition.get("label", "RIVAL RESPONSE")),
			"rival_name": String(scenario.get("rival_name", "Golden Comb Group")),
			"eggs_at_choice": sim.eggs_today,
			"margin_at_choice": roundi(sim.executive_confidence - 50.0),
		})
		while sim.rival_response_history.size() > 32:
			sim.rival_response_history.pop_front()
		return sim._file_playbook_receipt(_playbook_choice_result(kind, choice_id, DepartmentSimulation.PLAYBOOK_RIVAL_DEFINITIONS[choice_id], "Rival response filed with no hidden catch-up rule."))
	if kind == &"side_goal":
		if not DepartmentSimulation.PLAYBOOK_SIDE_GOAL_DEFINITIONS.has(choice_id) or not String(sim.active_playbook.get("side_goal_id", "")).is_empty():
			return {"accepted": false, "reason": "One personal ambition is already pinned."}
		sim.active_playbook["side_goal_id"] = String(choice_id)
		sim.active_playbook["side_goal_fund_baseline_cents"] = sim.revenue_cents
		return sim._file_playbook_receipt(_playbook_choice_result(kind, choice_id, DepartmentSimulation.PLAYBOOK_SIDE_GOAL_DEFINITIONS[choice_id], "Personal ambition pinned; missing it has no penalty."))
	if kind == &"reward":
		return _claim_playbook_contract_reward(choice_id, worker_id)
	if kind == &"push_luck":
		if not DepartmentSimulation.PLAYBOOK_PUSH_LUCK_DEFINITIONS.has(choice_id) or not String(sim.active_playbook.get("push_luck_id", "")).is_empty() or sim.eggs_today < sim.quota_target:
			return {"accepted": false, "reason": "Secure today's quota before choosing a clutch finish."}
		sim.active_playbook["push_luck_id"] = String(choice_id)
		sim.active_playbook["push_luck_start_eggs"] = sim.eggs_today
		return sim._file_playbook_receipt(_playbook_choice_result(
			kind,
			choice_id,
			DepartmentSimulation.PLAYBOOK_PUSH_LUCK_DEFINITIONS[choice_id],
			"Quota banked. %s now shapes every remaining file this shift." % String(DepartmentSimulation.PLAYBOOK_PUSH_LUCK_DEFINITIONS[choice_id].get("label", "Clutch finish")),
		))
	if kind == &"automation":
		if choice_id != &"auto_fit" or bool(sim.active_playbook.get("mastery_auto_used", false)):
			return {"accepted": false, "reason": "That mastery automation is already filed."}
		if sim.routing_momentum_chain < DepartmentSimulation.ROUTING_MOMENTUM_PACE_MILESTONE:
			return {"accepted": false, "reason": "Build a fitted routing chain before teaching Auto Fit."}
		if worker_id < 0 or worker_id >= sim.workers.size() or not sim.workers[worker_id].employed:
			return {"accepted": false, "reason": "Select the hen whose routing rule should be automated."}
		if not sim.set_worker_assignment(worker_id, &"auto"):
			return {"accepted": false, "reason": "Auto Fit could not be filed for that hen."}
		sim.workers[worker_id].automation_policy_unlocked = true
		sim.workers[worker_id].automation_policy_id = &"specialty_first"
		sim.active_playbook["mastery_auto_used"] = true
		return sim._file_playbook_receipt({
			"accepted": true,
			"playbook_kind": "automation",
			"choice_id": "auto_fit",
			"worker_id": worker_id,
			"label": "AUTO FIT TAUGHT",
			"effects": {"gain": "ROUTING AUTOMATED", "cost": "MASTERY MARK", "risk": "DEADLINES MAY OVERRIDE FIT"},
			"outcome": "%s learned Auto Fit with Specialty First. Her delegation rule is now persistent and can be revised from the Playbook." % sim.workers[worker_id].display_name,
			"day": sim.day,
		})
	if kind == &"automation_policy":
		if not DepartmentSimulation.PLAYBOOK_DELEGATION_POLICY_DEFINITIONS.has(choice_id):
			return {"accepted": false, "reason": "That delegation policy is not available."}
		if worker_id < 0 or worker_id >= sim.workers.size() or not sim.workers[worker_id].employed:
			return {"accepted": false, "reason": "Select the hen whose delegation rule should change."}
		var automation_worker := sim.workers[worker_id]
		if not automation_worker.automation_policy_unlocked or automation_worker.assigned_lane != DepartmentSimulation.AUTO_ASSIGNMENT:
			return {"accepted": false, "reason": "Teach this hen Auto Fit before revising her delegation rule."}
		if automation_worker.automation_policy_id == choice_id:
			return {"accepted": false, "reason": "That delegation rule is already active."}
		automation_worker.automation_policy_id = choice_id
		var policy_definition := DepartmentSimulation.PLAYBOOK_DELEGATION_POLICY_DEFINITIONS[choice_id] as Dictionary
		return sim._file_playbook_receipt({
			"accepted": true,
			"playbook_kind": "automation_policy",
			"choice_id": String(choice_id),
			"worker_id": worker_id,
			"label": String(policy_definition.get("label", "AUTO POLICY")),
			"effects": {
				"gain": String(policy_definition.get("gain", "ROUTINE DELEGATION")),
				"cost": String(policy_definition.get("cost", "NONE")),
				"risk": String(policy_definition.get("risk", "EXCEPTIONS REMAIN MANUAL")),
			},
			"outcome": "%s now delegates routine files by %s. Exceptions remain visible and manual." % [
				automation_worker.display_name,
				String(policy_definition.get("label", "AUTO POLICY")).capitalize(),
			],
			"day": sim.day,
		})
	if kind == &"teamwork":
		return _perform_playbook_teamwork(worker_id)
	if kind == &"partnership":
		return _perform_partnership_specialization(choice_id, worker_id)
	if kind == &"recovery":
		return _perform_playbook_recovery(choice_id)
	if kind == &"practice":
		return _practice_playbook_peck(worker_id)
	return {"accepted": false, "reason": "That playbook action is not available."}


func _perform_playbook_hero_case(choice_id: StringName, worker_id: int) -> Dictionary:
	var case_id := StringName(sim.active_playbook.get("hero_case_id", _hero_case_id_for_day(sim.day)))
	var definition := DepartmentSimulation.PLAYBOOK_HERO_CASE_DEFINITIONS.get(case_id, {}) as Dictionary
	var choices := definition.get("choices", {}) as Dictionary
	if not String(sim.active_playbook.get("hero_case_choice_id", "")).is_empty():
		return {"accepted": false, "reason": "Today's hero file already has a filed answer."}
	if sim.eggs_today <= 0:
		return {"accepted": false, "reason": "Land the first egg before the hero file opens."}
	if not choices.has(choice_id):
		return {"accepted": false, "reason": "That answer does not belong to today's hero file."}
	var effects := choices[choice_id] as Dictionary
	var fund_delta := int(effects.get("revenue_cents", 0))
	if fund_delta < 0 and sim.spendable_fund_cents() < -fund_delta:
		return {"accepted": false, "reason": "That answer needs $%.2f spendable Feed Fund." % (float(-fund_delta) / 100.0)}
	var target_worker_id := worker_id
	if target_worker_id < 0 or target_worker_id >= sim.workers.size() or not sim.workers[target_worker_id].employed:
		target_worker_id = int(_hero_case_snapshot(-1).get("worker_id", -1))
	var target_worker: ChickenState = sim.workers[target_worker_id] if target_worker_id >= 0 else null
	sim.revenue_cents = maxi(0, sim.revenue_cents + fund_delta)
	sim.executive_confidence = clampf(sim.executive_confidence + float(effects.get("executive_confidence", 0.0)), 0.0, 100.0)
	sim.compliance = clampf(sim.compliance + float(effects.get("compliance", 0.0)), 0.0, 100.0)
	sim.solidarity = clampf(sim.solidarity + float(effects.get("solidarity", 0.0)), 0.0, 100.0)
	if effects.has("all_stress"):
		sim._adjust_workers(0.0, float(effects.get("all_stress", 0.0)), 0.0)
	if target_worker != null:
		target_worker.stress = clampf(target_worker.stress + float(effects.get("stress", 0.0)), 0.0, 100.0)
		target_worker.manager_trust = clampf(target_worker.manager_trust + float(effects.get("trust", 0.0)), 0.0, 100.0)
		var career_xp := int(effects.get("career_xp", 0))
		if career_xp > 0:
			target_worker.add_career_xp(career_xp)
	if int(effects.get("attention", 0)) > 0:
		sim.routing_momentum_peck_recharge_bank = maxi(sim.routing_momentum_peck_recharge_bank, 1)
	var callback := {
		"day": sim.day,
		"case_id": String(case_id),
		"case_label": String(definition.get("label", "HERO FILE")),
		"choice_id": String(choice_id),
		"choice_label": String(effects.get("label", "ANSWER")),
		"worker_id": target_worker_id,
		"worker_name": target_worker.display_name if target_worker != null else "THE FLOCK",
		"echo": "%s will return in the shift review and future docket history." % String(effects.get("label", "This answer")).capitalize(),
	}
	sim.active_playbook["hero_case_choice_id"] = String(choice_id)
	sim.active_playbook["hero_case_callback"] = callback.duplicate(true)
	sim.hero_case_history.append(callback.duplicate(true))
	if sim.hero_case_history.size() > 32:
		sim.hero_case_history.pop_front()
	return sim._file_playbook_receipt({
		"accepted": true,
		"playbook_kind": "hero_case",
		"choice_id": String(choice_id),
		"case_id": String(case_id),
		"worker_id": target_worker_id,
		"label": String(effects.get("label", "HERO FILE")),
		"effects": {
			"gain": String(effects.get("gain", "VISIBLE CHANGE")),
			"cost": String(effects.get("cost", "NONE")),
			"risk": String(effects.get("risk", "NONE")),
		},
		"outcome": "%s filed %s for %s. The callback is now part of this campaign." % [
			String(definition.get("label", "Hero file")).capitalize(),
			String(effects.get("label", "the answer")).capitalize(),
			callback["worker_name"],
		],
		"callback": callback.duplicate(true),
		"day": sim.day,
	})


func _playbook_choice_result(kind: StringName, choice_id: StringName, definition: Dictionary, outcome: String) -> Dictionary:
	return {"accepted": true, "playbook_kind": String(kind), "choice_id": String(choice_id), "label": String(definition.get("label", choice_id)), "effects": {"gain": String(definition.get("gain", "")), "cost": String(definition.get("cost", "")), "risk": String(definition.get("risk", ""))}, "outcome": outcome, "day": sim.day}


func _file_playbook_receipt(result: Dictionary) -> Dictionary:
	sim._record_playbook_contract_completion()
	var effects := result.get("effects", {}) as Dictionary
	result["decision_arc"] = {
		"forecast": {
			"gain": String(effects.get("gain", "SEE OUTCOME")),
			"cost": String(effects.get("cost", "NONE")),
			"risk": String(effects.get("risk", "NONE")),
		},
		"action": String(result.get("label", "PLAY FILED")),
		"result": String(result.get("outcome", "Playbook action filed.")),
		"reconciled": true,
	}
	sim.active_playbook["receipt_serial"] = int(sim.active_playbook.get("receipt_serial", 0)) + 1
	result["receipt_serial"] = int(sim.active_playbook["receipt_serial"])
	sim.active_playbook["last_receipt"] = result.duplicate(true)
	sim.announcement_posted.emit(String(result.get("outcome", "Playbook action filed.")))
	sim.snapshot_changed.emit(sim.snapshot())
	return result


func _claim_playbook_contract_reward(choice_id: StringName, worker_id: int) -> Dictionary:
	var contract_id := StringName(sim.active_playbook.get("contract_id", &""))
	var contract_definition := DepartmentSimulation.PLAYBOOK_CONTRACT_DEFINITIONS.get(contract_id, {}) as Dictionary
	if contract_definition.is_empty() or _playbook_contract_progress(contract_id) < int(contract_definition.get("target", 0)):
		return {"accepted": false, "reason": "Complete the accepted optional contract first."}
	if not String(sim.active_playbook.get("contract_reward_id", "")).is_empty() or not DepartmentSimulation.PLAYBOOK_REWARD_DEFINITIONS.has(choice_id):
		return {"accepted": false, "reason": "This contract reward is already filed or unavailable."}
	var reward_worker: ChickenState
	if worker_id >= 0 and worker_id < sim.workers.size() and sim.workers[worker_id].employed:
		reward_worker = sim.workers[worker_id]
	else:
		for candidate in sim.workers:
			if candidate.employed:
				reward_worker = candidate
				break
	match choice_id:
		&"fund":
			sim.revenue_cents += 300
			sim.credited_today_cents += 300
		&"mastery":
			if reward_worker != null:
				reward_worker.add_career_xp(6)
		&"recovery":
			sim._adjust_workers(0.0, -4.0, -4.0)
	sim.active_playbook["contract_reward_id"] = String(choice_id)
	var reward_outcome := "$3.00 added to your Feed Fund. Put it toward your next upgrade."
	if choice_id == &"mastery" and reward_worker != null:
		reward_outcome = "%s earned 6 career XP toward her next promotion." % reward_worker.display_name
	elif choice_id == &"recovery":
		reward_outcome = "The whole flock recovered: each employed hen lost up to 4 stress and 4 fatigue."
	var mastery_offer := sim.career_workshop.mastery_offer(String(contract_id))
	if sim.career_workshop.award(sim.day, String(contract_id)):
		reward_outcome += " +1 workshop stamp: unlock a permanent tool."
	else:
		sim.revenue_cents += 100
		sim.credited_today_cents += 100
		reward_outcome += " +$1.00 workshop mastery bonus."
	if not mastery_offer.is_empty():
		reward_outcome += " NEW MODE: %s earned. Equip free before work from shift %d." % [String(mastery_offer.label), int(mastery_offer.day)]
	return sim._file_playbook_receipt(_playbook_choice_result(&"reward", choice_id, DepartmentSimulation.PLAYBOOK_REWARD_DEFINITIONS[choice_id], reward_outcome))


func _delegation_policy_catalog() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	for policy_id: StringName in DepartmentSimulation.PLAYBOOK_DELEGATION_POLICY_DEFINITIONS:
		var row := (DepartmentSimulation.PLAYBOOK_DELEGATION_POLICY_DEFINITIONS[policy_id] as Dictionary).duplicate(true)
		row["id"] = String(policy_id)
		row["persistent"] = true
		row["exceptions_manual"] = true
		catalog.append(row)
	return catalog


func _strategy_comparison_catalog(current_id: StringName, recommended_id: StringName) -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	for plan_id in DepartmentSimulation.PLAYBOOK_STRATEGY_PRESET_ORDER:
		var definition := DepartmentSimulation.PLAYBOOK_STRATEGY_PRESET_DEFINITIONS[plan_id] as Dictionary
		catalog.append({
			"id": String(plan_id),
			"label": String(definition.get("label", "PLAN")),
			"icon": String(definition.get("icon", &"goal")),
			"gain": String(definition.get("gain", "")),
			"cost": String(definition.get("cost", "")),
			"risk": String(definition.get("risk", "")),
			"promise": String(definition.get("promise", "")),
			"current": plan_id == current_id,
			"recommended": plan_id == recommended_id,
		})
	return catalog


func _team_lift_ability(worker: ChickenState, partner: ChickenState) -> Dictionary:
	var ability := sim._base_team_lift_ability(worker, partner)
	if not ability.is_empty() and sim.flock_relationships.affinity(worker.id, partner.id) >= 18:
		ability["morale"] = float(ability.get("morale", 0.0)) + 2.0
		ability["stress"] = float(ability.get("stress", 0.0)) - 2.0
		ability["gain"] = String(ability.gain) + " + FRIEND CARE"
		ability["summary"] = String(ability.summary) + "; friendship adds +2 morale / -2 stress for both"
	return ability


func _base_team_lift_ability(worker: ChickenState, partner: ChickenState) -> Dictionary:
	if worker == null or partner == null:
		return {}
	var specialties: Array[StringName] = [worker.specialty, partner.specialty]
	if worker.specialty == partner.specialty:
		return {
			"id": "specialist_duet",
			"label": "SPECIALIST DUET",
			"icon": &"sync",
			"gain": "XP +3 / MORALE +4",
			"summary": "file a shared specialty lesson and restore morale",
			"morale": 4.0,
			"stress": -3.0,
			"trust": 2.0,
			"career_xp": 3,
			"attention_charge": 0,
		}
	if &"appeals" in specialties and &"nest_damage" in specialties:
		return {
			"id": "mentor_handoff",
			"label": "MENTOR HANDOFF",
			"icon": &"flock",
			"gain": "XP +2 / STRESS -5",
			"summary": "turn the handoff into career growth and calmer work",
			"morale": 4.0,
			"stress": -5.0,
			"trust": 3.0,
			"career_xp": 2,
			"attention_charge": 0,
		}
	if &"appeals" in specialties and &"predator_loss" in specialties:
		return {
			"id": "deadline_cover",
			"label": "DEADLINE COVER",
			"icon": &"clock",
			"gain": "ATTENTION +1 / STRESS -4",
			"summary": "cover the deadline and restore one attention charge",
			"morale": 3.0,
			"stress": -4.0,
			"trust": 2.0,
			"career_xp": 0,
			"attention_charge": 1,
		}
	return {
		"id": "shell_guard",
		"label": "SHELL GUARD",
		"icon": &"shield",
		"gain": "TRUST +4 / STRESS -4",
		"summary": "steady the risky file with a trusted shell check",
		"morale": 4.0,
		"stress": -4.0,
		"trust": 4.0,
		"career_xp": 0,
		"attention_charge": 0,
	}


func _perform_playbook_teamwork(worker_id: int) -> Dictionary:
	if bool(sim.active_playbook.get("teamwork_used", false)):
		return {"accepted": false, "reason": "Team Lift is already filed this shift."}
	if worker_id < 0 or worker_id >= sim.workers.size() or not sim.workers[worker_id].employed:
		return {"accepted": false, "reason": "Select a bonded hen first."}
	var worker := sim.workers[worker_id]
	var bond := sim._worker_flock_bond_snapshot(worker)
	var partner_id := int(bond.get("partner_id", -1))
	if int(bond.get("score", 0)) < 60 or partner_id < 0 or partner_id >= sim.workers.size():
		return {"accepted": false, "reason": "Team Lift requires a Good Perch bond at 60 or higher."}
	var partner := sim.workers[partner_id]
	var ability := _team_lift_ability(worker, partner)
	var morale_delta := float(ability.get("morale", 4.0))
	var stress_delta := float(ability.get("stress", -4.0))
	var trust_delta := float(ability.get("trust", 2.0))
	var career_xp_delta := int(ability.get("career_xp", 0))
	var attention_charge := int(ability.get("attention_charge", 0))
	var specialization_id := &""
	if (
		worker.partnership_partner_id == partner_id
		and partner.partnership_partner_id == worker_id
		and worker.partnership_style_id == partner.partnership_style_id
	):
		specialization_id = worker.partnership_style_id
	match specialization_id:
		&"precision_duet":
			career_xp_delta += 2
			attention_charge = maxi(attention_charge, 1)
		&"recovery_pact":
			morale_delta += 2.0
			stress_delta -= 3.0
	for teammate_id in [worker_id, partner_id]:
		sim.workers[teammate_id].morale = clampf(sim.workers[teammate_id].morale + morale_delta, 0.0, 100.0)
		sim.workers[teammate_id].stress = clampf(sim.workers[teammate_id].stress + stress_delta, 0.0, 100.0)
		sim.workers[teammate_id].manager_trust = clampf(sim.workers[teammate_id].manager_trust + trust_delta, 0.0, 100.0)
		if career_xp_delta > 0:
			sim.workers[teammate_id].add_career_xp(career_xp_delta)
	if attention_charge > 0:
		sim.routing_momentum_peck_recharge_bank = 1
	sim.active_playbook["teamwork_used"] = true
	sim.flock_relationships.record(worker_id, partner_id, "team_lift", sim.day)
	sim._award_clean_pair(worker, partner)
	return sim._file_playbook_receipt({
		"accepted": true,
		"playbook_kind": "teamwork",
		"choice_id": "team_lift",
		"ability_id": String(ability.get("id", "team_lift")),
		"specialization_id": String(specialization_id),
		"worker_id": worker_id,
		"partner_id": partner_id,
		"label": String(ability.get("label", "TEAM LIFT")),
		"effects": {
			"morale": morale_delta,
			"stress": stress_delta,
			"trust": trust_delta,
			"career_xp": career_xp_delta,
			"attention_charge": attention_charge,
		},
		"outcome": "%s and %s filed %s." % [
			worker.display_name,
			String(bond.get("partner_name", "her perchmate")),
			String(ability.get("label", "Team Lift")).capitalize(),
		],
		"day": sim.day,
	})


func _perform_partnership_specialization(choice_id: StringName, worker_id: int) -> Dictionary:
	if not DepartmentSimulation.PLAYBOOK_PARTNERSHIP_STYLE_DEFINITIONS.has(choice_id):
		return {"accepted": false, "reason": "That pair style is unavailable."}
	if worker_id < 0 or worker_id >= sim.workers.size() or not sim.workers[worker_id].employed:
		return {"accepted": false, "reason": "Select one hen in the pair first."}
	var worker := sim.workers[worker_id]
	var bond := sim._worker_flock_bond_snapshot(worker)
	var partner_id := int(bond.get("partner_id", -1))
	if int(bond.get("score", 0)) < 75 or partner_id < 0 or partner_id >= sim.workers.size() or not sim.workers[partner_id].employed:
		return {"accepted": false, "reason": "A Clutchmates bond at 75 or higher unlocks pair specialization."}
	var partner := sim.workers[partner_id]
	if worker.partnership_style_id != &"" or partner.partnership_style_id != &"":
		return {"accepted": false, "reason": "This pair already has a permanent specialization."}
	worker.partnership_partner_id = partner_id
	worker.partnership_style_id = choice_id
	partner.partnership_partner_id = worker_id
	partner.partnership_style_id = choice_id
	var definition := DepartmentSimulation.PLAYBOOK_PARTNERSHIP_STYLE_DEFINITIONS[choice_id] as Dictionary
	return sim._file_playbook_receipt({
		"accepted": true,
		"playbook_kind": "partnership",
		"choice_id": String(choice_id),
		"worker_id": worker_id,
		"partner_id": partner_id,
		"label": String(definition.get("label", "PAIR STYLE")),
		"effects": {
			"gain": String(definition.get("gain", "PAIR SPECIALIZATION")),
			"cost": String(definition.get("cost", "NONE")),
			"risk": String(definition.get("risk", "PERMANENT PAIR STYLE")),
		},
		"outcome": "%s and %s permanently learned %s." % [
			worker.display_name,
			partner.display_name,
			String(definition.get("label", "their pair style")).capitalize(),
		],
		"day": sim.day,
	})


func _perform_playbook_recovery(choice_id: StringName) -> Dictionary:
	if not DepartmentSimulation.PLAYBOOK_RECOVERY_DEFINITIONS.has(choice_id) or not String(sim.active_playbook.get("recovery_id", "")).is_empty():
		return {"accepted": false, "reason": "A recovery plan is already filed or unavailable."}
	if sim.revenue_cents >= 2500 and sim.executive_confidence >= 45.0 and sim._average_worker_stress() < 55.0:
		return {"accepted": false, "reason": "Recovery plans open when cash, favor, or flock strain needs repair."}
	match choice_id:
		&"steady_fund":
			sim.quota_target = maxi(1, sim.quota_target - 2)
			sim.executive_confidence = maxf(0.0, sim.executive_confidence - 2.0)
		&"repair_flock":
			if sim.spendable_fund_cents() < 300:
				return {"accepted": false, "reason": "Flock repair needs $3.00 spendable Feed Fund."}
			sim.revenue_cents -= 300
			sim._adjust_workers(3.0, -8.0, -8.0)
		&"salvage_order":
			pass
	sim.active_playbook["recovery_id"] = String(choice_id)
	return sim._file_playbook_receipt(_playbook_choice_result(&"recovery", choice_id, DepartmentSimulation.PLAYBOOK_RECOVERY_DEFINITIONS[choice_id], "Comeback plan filed; banked rewards remain safe."))


func _practice_playbook_peck(worker_id: int) -> Dictionary:
	if worker_id < 0 or worker_id >= sim.workers.size() or not sim.workers[worker_id].employed:
		return {"accepted": false, "reason": "Select an active hen for practice."}
	var worker := sim.workers[worker_id]
	var status := sim.peck_assist_status(worker_id)
	var progress := worker.work_progress
	var ideal := float(status.get("ideal_progress", DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS))
	var delta := absf(progress - ideal)
	return {"accepted": true, "playbook_kind": "practice", "choice_id": "peck", "worker_id": worker_id, "label": "PRACTICE PECK", "effects": {}, "practice": true, "changes_authority": false, "outcome": "Practice: %s is %.0f points from the ideal peck mark. No charge or reward changed." % [worker.display_name, delta], "day": sim.day}


func _average_worker_stress() -> float:
	var total := 0.0
	var count := 0
	for worker in sim.workers:
		if worker.employed:
			total += worker.stress
			count += 1
	return total / maxf(1.0, float(count))


func _playbook_work_multiplier() -> float:
	sim._ensure_active_playbook()
	var multiplier := 1.0
	match StringName(sim.active_playbook.get("loadout_id", &"")):
		&"pace_floor": multiplier *= 1.04
		&"quality_floor": multiplier *= 0.98
		&"care_floor": multiplier *= 0.99
	if sim.incidents_resolved_today == 0:
		match StringName(sim.active_playbook.get("preparation_id", &"")):
			&"brace_shells": multiplier *= 0.97
			&"clear_trays": multiplier *= 1.05
	match StringName(sim.active_playbook.get("rival_response_id", &"")):
		&"defend": multiplier *= 0.98
		&"counter": multiplier *= 1.04
	match StringName(sim.active_playbook.get("recovery_id", &"")):
		&"salvage_order": multiplier *= 1.06
	match StringName(sim.active_playbook.get("push_luck_id", &"")):
		&"bank_clutch": multiplier *= 0.95
		&"chase_premium": multiplier *= 1.10
	match StringName(sim.active_playbook.get("challenge_modifier_id", &"")):
		&"rush_hour": multiplier *= 1.10
		&"one_bell": multiplier *= 1.08
	if StringName(sim.active_playbook.get("manager_intervention_id", &"")) == &"emergency_review":
		multiplier *= 0.98
	if (
		StringName(sim.active_playbook.get("strategy_preset_id", &"")) == &"fast"
		and bool(sim._playbook_combo_recipe_snapshot().get("complete", false))
	):
		multiplier *= 1.03
	if sim.routing_momentum_chain >= DepartmentSimulation.ROUTING_MOMENTUM_PACE_MILESTONE and sim.active_directive_id == &"record_harvest":
		multiplier *= 1.05
	return clampf(multiplier, 0.80, 1.30)


func _playbook_crack_modifier() -> float:
	sim._ensure_active_playbook()
	var modifier := 0.0
	match StringName(sim.active_playbook.get("loadout_id", &"")):
		&"pace_floor": modifier += 0.008
		&"quality_floor": modifier -= 0.018
	if sim.incidents_resolved_today == 0:
		match StringName(sim.active_playbook.get("preparation_id", &"")):
			&"brace_shells": modifier -= 0.025
			&"clear_trays": modifier += 0.012
	match StringName(sim.active_playbook.get("rival_response_id", &"")):
		&"defend": modifier -= 0.015
		&"counter": modifier += 0.012
	if StringName(sim.active_playbook.get("recovery_id", &"")) == &"salvage_order":
		modifier += 0.02
	match StringName(sim.active_playbook.get("push_luck_id", &"")):
		&"bank_clutch": modifier -= 0.025
		&"chase_premium": modifier += 0.04
	match StringName(sim.active_playbook.get("challenge_modifier_id", &"")):
		&"rush_hour": modifier += 0.01
		&"glass_carton": modifier += 0.03
	if StringName(sim.active_playbook.get("manager_intervention_id", &"")) == &"emergency_review":
		modifier -= 0.015
	if (
		StringName(sim.active_playbook.get("strategy_preset_id", &"")) == &"safe"
		and bool(sim._playbook_combo_recipe_snapshot().get("complete", false))
	):
		modifier -= 0.015
	if sim.routing_momentum_chain >= DepartmentSimulation.ROUTING_MOMENTUM_PACE_MILESTONE and sim.active_directive_id == &"shell_assurance":
		modifier -= 0.02
	return clampf(modifier, -0.12, 0.12)


func _playbook_strain_multiplier() -> float:
	sim._ensure_active_playbook()
	var multiplier := 1.0
	if StringName(sim.active_playbook.get("loadout_id", &"")) == &"care_floor":
		multiplier *= 0.90
	if (
		sim.incidents_resolved_today == 0
		and StringName(sim.active_playbook.get("preparation_id", &"")) == &"rest_flock"
	):
		multiplier *= 0.88
	if sim.routing_momentum_chain >= DepartmentSimulation.ROUTING_MOMENTUM_PACE_MILESTONE and sim.active_directive_id == &"sustainable_flock":
		multiplier *= 0.90
	if (
		StringName(sim.active_playbook.get("strategy_preset_id", &"")) == &"flock"
		and bool(sim._playbook_combo_recipe_snapshot().get("complete", false))
	):
		multiplier *= 0.88
	return clampf(multiplier, 0.65, 1.0)
