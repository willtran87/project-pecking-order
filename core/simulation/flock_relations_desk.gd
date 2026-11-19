class_name FlockRelationsDesk
extends RefCounted

## Flock petitions, compacts, relations cases and restructuring resolution.
## Holds no state of its own: every read and write goes through the owning
## DepartmentSimulation so behaviour is identical to the original in-class methods.

## Weak back-reference: the simulation owns this component, so a strong
## reference here would form a RefCounted cycle and leak both objects.
var _sim_ref: WeakRef


func _init(owner_node: DepartmentSimulation) -> void:
	_sim_ref = weakref(owner_node)

func flock_relations_case_capacity() -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return sim._facility_level_schedule_value(
		DepartmentSimulation.FLOCK_RELATIONS_CASE_CAPACITY,
		sim.facility_level(DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID),
		0,
	)


func flock_relations_resolution_limit() -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	return sim._facility_level_schedule_value(
		DepartmentSimulation.FLOCK_RELATIONS_RESOLUTION_LIMITS,
		sim.facility_level(DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID),
		0,
	)


func _resolve_flock_restructuring(option_id: StringName) -> bool:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if (
		sim.shift_phase != DepartmentSimulation.ShiftPhase.REVIEW
		or sim.flock_restructuring_resolved
		or StringName(sim.pending_decision.get("id", &"")) != &"flock_restructuring"
	):
		return false
	var chosen: Dictionary = {}
	for option_value in sim.pending_decision.get("options", []):
		var option := option_value as Dictionary
		if StringName(option.get("id", &"")) == option_id:
			chosen = option
			break
	if chosen.is_empty():
		return false
	var candidate_id := int(sim.pending_decision.get("subject_worker_id", -1))
	if candidate_id < 0 or candidate_id >= sim.workers.size() or not sim.workers[candidate_id].employed:
		sim.announcement_posted.emit("RESTRUCTURING HELD: the named hen is no longer on the active roster.")
		return false
	var cost_cents := int(chosen.get("cost_cents", 0))
	if sim.spendable_fund_cents() < cost_cents:
		sim.announcement_posted.emit(
			"RESTRUCTURING HELD: $%.2f more spendable Feed Fund required." % (
				float(cost_cents - sim.spendable_fund_cents()) / 100.0
			)
		)
		return false

	var candidate := sim.workers[candidate_id]
	var candidate_before := {
		"career_title": candidate.career_title(),
		"career_xp": candidate.career_xp,
		"specialty": String(candidate.specialty),
		"assignment": String(candidate.assigned_lane),
		"manager_trust": candidate.manager_trust,
		"grievance": candidate.grievance,
		"morale": candidate.morale,
		"stress": candidate.stress,
		"fatigue": candidate.fatigue,
	}
	var candidate_row := _ranked_worker_row(
		sim.pending_decision.get("ranking", []) as Array,
		candidate_id,
	)
	sim.revenue_cents -= cost_cents
	var replacement_worker_id := -1
	match option_id:
		&"nominate_variance":
			replacement_worker_id = _release_restructuring_candidate(candidate)
			sim.revenue_cents += 1800
			sim.executive_confidence = minf(100.0, sim.executive_confidence + 8.0)
			sim.quota_target = mini(10_000, sim.quota_target + 2)
		&"fund_redeployment":
			candidate.assigned_lane = candidate.specialty
			candidate.manually_routed = false
			candidate.morale = minf(100.0, candidate.morale + 8.0)
			candidate.manager_trust = minf(100.0, candidate.manager_trust + 14.0)
			candidate.grievance = maxf(0.0, candidate.grievance - 12.0)
			candidate.stress = maxf(0.0, candidate.stress - 10.0)
			candidate.fatigue = maxf(0.0, candidate.fatigue - 10.0)
			candidate.add_career_xp(18)
			sim.executive_confidence = maxf(0.0, sim.executive_confidence - 5.0)
			sim.compliance = minf(100.0, sim.compliance + 4.0)
			sim.quota_target = maxi(1, sim.quota_target - 1)
		&"contest_ranking":
			for worker in sim.workers:
				if not worker.employed:
					continue
				worker.morale = minf(100.0, worker.morale + 4.0)
				worker.manager_trust = minf(100.0, worker.manager_trust + 8.0)
				worker.grievance = maxf(0.0, worker.grievance - 6.0)
			sim.solidarity = minf(100.0, sim.solidarity + 15.0)
			sim.executive_confidence = maxf(0.0, sim.executive_confidence - 10.0)
			sim.compliance = maxf(0.0, sim.compliance - 5.0)
			sim.quota_target = mini(10_000, sim.quota_target + 2)
		_:
			return false

	var style_id := StringName(chosen.get("style_id", &"management_innovation"))
	sim.credit_choice_counts[style_id] = int(sim.credit_choice_counts.get(style_id, 0)) + 1
	var completed_day := int(sim.pending_decision.get("completed_day", DepartmentSimulation.FLOCK_RESTRUCTURING_SHIFT))
	var outcome := String(chosen.get("outcome", "Flock restructuring order filed."))
	var serial := int(sim.pending_decision.get("serial", -1))
	var candidate_name := candidate.display_name
	sim.last_credit_allocation = {
		"day": completed_day,
		"decision_id": "flock_restructuring",
		"option_id": String(option_id),
		"style_id": String(style_id),
		"worker_id": candidate_id,
		"worker_name": candidate_name,
		"cost_cents": cost_cents,
		"outcome": outcome,
		"special_event": true,
		"projected": false,
	}
	sim.flock_restructuring_record = sim.last_credit_allocation.duplicate(true)
	sim.flock_restructuring_record.merge({
		"choice_label": String(chosen.get("label", "RESTRUCTURING FILED")),
		"candidate_rank": int(candidate_row.get("rank", 0)),
		"candidate_eggs": int(candidate_row.get("eggs", 0)),
		"candidate_cracked": int(candidate_row.get("cracked", 0)),
		"candidate_credit_cents": int(candidate_row.get("credit_cents", 0)),
		"candidate_before": candidate_before,
		"candidate_employed_after": candidate.employed,
		"replacement_worker_id": replacement_worker_id,
		"replacement_worker_name": (
			sim.workers[replacement_worker_id].display_name
			if replacement_worker_id >= 0 else ""
		),
	}, true)
	sim.flock_restructuring_resolved = true
	sim.flock_restructuring_day = completed_day
	sim.pending_decision.clear()
	sim._harvest_credit.release_credit_gate(completed_day)
	sim.announcement_posted.emit(outcome)
	sim.decision_resolved.emit({
		"serial": serial,
		"kind": &"major_event",
		"decision_id": &"flock_restructuring",
		"option_id": option_id,
		"style_id": style_id,
		"worker_id": candidate_id,
		"worker_name": candidate_name,
		"outcome": outcome,
		"day": completed_day,
		"resume_policy": &"review",
	})
	sim.snapshot_changed.emit(sim.snapshot())
	return true


func _ranked_worker_row(ranking: Array, worker_id: int) -> Dictionary:
	for row_value in ranking:
		var row := row_value as Dictionary
		if int(row.get("worker_id", -1)) == worker_id:
			return row.duplicate(true)
	return {}


func _release_restructuring_candidate(candidate: ChickenState) -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var released_desk := candidate.desk_index
	candidate.employed = false
	candidate.desk_index = -1
	candidate.available_for_hire_day = mini(10_000, sim.day + 2)
	candidate.employment_start_day = 0
	candidate.assigned_lane = DepartmentSimulation.AUTO_ASSIGNMENT
	candidate.manually_routed = false
	candidate.current_claim = null
	candidate.work_state = ChickenState.WorkState.IDLE
	candidate.work_progress = 0.0
	candidate.state_ticks_remaining = 0
	sim._worker_at_workstation[candidate.id] = false
	for remaining_worker in sim.workers:
		if not remaining_worker.employed:
			continue
		remaining_worker.morale = maxf(0.0, remaining_worker.morale - 7.0)
		remaining_worker.manager_trust = maxf(0.0, remaining_worker.manager_trust - 10.0)
		remaining_worker.grievance = minf(100.0, remaining_worker.grievance + 12.0)
	sim.solidarity = minf(100.0, sim.solidarity + 10.0)
	if sim.active_worker_count() >= DepartmentSimulation.MINIMUM_STAFF_COUNT:
		return -1
	var replacement := _restructuring_replacement_candidate(candidate.id)
	if replacement == null:
		# This cannot occur with the six-hen roster, but fail closed into a retained
		# minimum rather than letting a malformed save strand the office at two.
		candidate.employed = true
		candidate.desk_index = released_desk
		candidate.available_for_hire_day = 0
		candidate.employment_start_day = sim.day
		return -1
	replacement.employed = true
	replacement.desk_index = released_desk
	replacement.available_for_hire_day = 0
	replacement.hire_count += 1
	replacement.employment_start_day = sim.day
	replacement.assigned_lane = DepartmentSimulation.AUTO_ASSIGNMENT
	replacement.manually_routed = false
	replacement.current_claim = null
	replacement.work_state = ChickenState.WorkState.IDLE
	replacement.work_progress = 0.0
	replacement.state_ticks_remaining = 0
	replacement.morale = minf(100.0, replacement.morale + 3.0)
	sim._worker_at_workstation[replacement.id] = false
	return replacement.id


func _restructuring_replacement_candidate(excluded_worker_id: int) -> ChickenState:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var fallback: ChickenState = null
	for worker in sim.workers:
		if worker.employed or worker.id == excluded_worker_id:
			continue
		if fallback == null:
			fallback = worker
		if worker.available_for_hire_day <= sim.day:
			return worker
	return fallback


func _build_flock_petition_decision() -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if not sim.active_flock_compact.is_empty():
		return {}
	var candidates: Array[Dictionary] = []
	for worker in sim.workers:
		if not worker.employed:
			continue
		if worker.assigned_lane != DepartmentSimulation.AUTO_ASSIGNMENT and worker.assigned_lane != worker.specialty:
			candidates.append({
				"petition_type": &"specialty_respect",
				"worker_id": worker.id,
				"score": 600 + roundi(worker.grievance * 4.0 + worker.stress + worker.fatigue),
				"evidence": [
					"Assigned file: %s" % sim._lane_display_name(worker.assigned_lane),
					"Trained file: %s" % sim._lane_display_name(worker.specialty),
					"Grievance ledger: %d" % roundi(worker.grievance),
				],
			})
		var pace_pressure := (
			worker.stress >= 45.0
			or worker.fatigue >= 55.0
			or sim.overtime_enabled
			or (
				worker.last_personnel_action_day == sim.day
				and worker.last_personnel_action == &"quota_pressure"
			)
		)
		if pace_pressure:
			var pace_score := 400 + roundi(worker.stress * 3.0 + worker.fatigue * 2.0)
			if sim.overtime_enabled:
				pace_score += 100
			if worker.last_personnel_action_day == sim.day and worker.last_personnel_action == &"quota_pressure":
				pace_score += 120
			candidates.append({
				"petition_type": &"safe_pace",
				"worker_id": worker.id,
				"score": pace_score,
				"evidence": [
					"Stress reading: %d" % roundi(worker.stress),
					"Fatigue reading: %d" % roundi(worker.fatigue),
					"Overtime order: %s" % ("ACTIVE" if sim.overtime_enabled else "INACTIVE"),
				],
			})
		if (
			worker.career_profile == &"credit_conscious"
			and not sim.last_credit_allocation.is_empty()
			and int(sim.last_credit_allocation.get("day", 0)) >= 1
			and int(sim.last_credit_allocation.get("day", 0)) < sim.day
		):
			var allocation_style := StringName(sim.last_credit_allocation.get("style_id", &""))
			var credit_score := 200 + roundi(worker.grievance * 2.0)
			if allocation_style == &"management_innovation":
				credit_score += 140
			if int(sim.last_credit_allocation.get("worker_id", -1)) == worker.id:
				credit_score += 60
			candidates.append({
				"petition_type": &"credit_in_writing",
				"worker_id": worker.id,
				"score": credit_score,
				"evidence": [
					"Last credit memo: %s" % String(allocation_style).replace("_", " ").to_upper(),
					"Career profile: CREDIT CONSCIOUS",
					"Grievance ledger: %d" % roundi(worker.grievance),
				],
			})
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := int(a.get("score", 0))
		var score_b := int(b.get("score", 0))
		if score_a != score_b:
			return score_a > score_b
		var type_a := StringName(a.get("petition_type", &""))
		var type_b := StringName(b.get("petition_type", &""))
		var priority_a := int((DepartmentSimulation.FLOCK_PETITION_DEFINITIONS.get(type_a, {}) as Dictionary).get("priority", 0))
		var priority_b := int((DepartmentSimulation.FLOCK_PETITION_DEFINITIONS.get(type_b, {}) as Dictionary).get("priority", 0))
		if priority_a != priority_b:
			return priority_a > priority_b
		return int(a.get("worker_id", 9999)) < int(b.get("worker_id", 9999))
	)
	var candidate := candidates[0]
	var petition_type := StringName(candidate.get("petition_type", &""))
	var definition := DepartmentSimulation.FLOCK_PETITION_DEFINITIONS[petition_type] as Dictionary
	var sponsor := sim.workers[int(candidate.get("worker_id", -1))]
	var effective_day := mini(9999, sim.day + 1)
	var evidence := (candidate.get("evidence", []) as Array).duplicate(true)
	var petition := {
		"version": 1,
		"petition_type": petition_type,
		"petition_title": String(definition.get("title", "FLOCK PETITION")),
		"compact_name": String(definition.get("compact_name", "FLOCK COMPACT")),
		"sponsor_worker_id": sponsor.id,
		"sponsor_worker_name": sponsor.display_name,
		"sponsor_profile": String(sponsor.career_profile),
		"evidence": evidence,
		"evidence_summary": String(evidence[0]) if not evidence.is_empty() else "Filed from the active flock ledger.",
		"promise": String(definition.get("promise", "")),
		"condition": String(definition.get("condition", "")),
		"effective_day": effective_day,
		"solidarity": snappedf(sim.solidarity, 0.0001),
		"work_to_rule_threshold": DepartmentSimulation.WORK_TO_RULE_SOLIDARITY_THRESHOLD,
	}
	return {
		"serial": -1,
		"kind": &"incident",
		"category": DepartmentSimulation.FLOCK_PETITION_CATEGORY,
		"id": DepartmentSimulation.FLOCK_PETITION_INCIDENT_ID,
		"day": sim.day,
		"eyebrow": "FLOCK PETITION  ·  AUTO-PAUSED  ·  %s" % sim._format_time(sim.minute_of_day),
		"title": String(definition.get("title", "FLOCK PETITION")),
		"body": "%s has put her name on a collective request. Its evidence comes from the same ledger used for performance reviews." % sponsor.display_name,
		"petition_type": petition_type,
		"sponsor_worker_id": sponsor.id,
		"sponsor_worker_name": sponsor.display_name,
		"evidence": evidence,
		"petition": petition,
		"options": [
			{
				"id": &"sign_compact",
				"response_tier": &"binding",
				"label": "SIGN THE COMPACT",
				"short_label": "SIGN COMPACT",
				"tagline": "Put tomorrow's promise in writing.",
				"glance": "BINDS NEXT SHIFT",
				"preview": "$%.2f  /  binding next shift  /  breach has consequences" % (float(definition.get("sign_cost_cents", 0)) / 100.0),
				"cost_cents": int(definition.get("sign_cost_cents", 0)),
				"tone": &"care",
				"outcome": "%s's compact was signed. Tomorrow's rooster is accountable to the wording." % sponsor.display_name,
			},
			{
				"id": &"offer_concession",
				"response_tier": &"concession",
				"label": "OFFER A SCOOP OF FEED",
				"short_label": "OFFER FEED",
				"tagline": "Address today's strain without signing tomorrow away.",
				"glance": "RELIEF\nNO COMPACT",
				"preview": "$4.00  /  immediate relief  /  no binding compact",
				"cost_cents": 400,
				"tone": &"quality",
				"outcome": "%s accepted a small concession. The petition remains in the filing cabinet, not the contract drawer." % sponsor.display_name,
			},
			{
				"id": &"deny_and_monitor",
				"response_tier": &"denial",
				"label": "DENY AND MONITOR",
				"short_label": "DENY & MONITOR",
				"tagline": "Call the pattern anecdotal and measure the reaction.",
				"glance": "TRUST DOWN\nWORK-RULE RISK",
				"preview": "FREE  /  trust falls  /  solidarity may trigger work-to-rule",
				"cost_cents": 0,
				"tone": &"danger",
				"outcome": "Management denied %s's petition and opened a dashboard to monitor the resulting solidarity." % sponsor.display_name,
			},
		],
	}


func _can_apply_flock_petition_response(option_id: StringName, chosen: Dictionary) -> bool:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if option_id not in DepartmentSimulation.FLOCK_PETITION_RESPONSE_IDS or int(sim.pending_decision.get("day", 0)) != sim.day:
		return false
	var petition_type := StringName(sim.pending_decision.get("petition_type", &""))
	if petition_type not in DepartmentSimulation.FLOCK_PETITION_TYPES:
		return false
	var sponsor_id := int(sim.pending_decision.get("sponsor_worker_id", -1))
	if sponsor_id < 0 or sponsor_id >= sim.workers.size() or not sim.workers[sponsor_id].employed:
		return false
	if String(sim.pending_decision.get("sponsor_worker_name", "")) != sim.workers[sponsor_id].display_name:
		return false
	var expected_cost := 0
	match option_id:
		&"sign_compact":
			if not sim.active_flock_compact.is_empty():
				return false
			expected_cost = int((DepartmentSimulation.FLOCK_PETITION_DEFINITIONS[petition_type] as Dictionary).get("sign_cost_cents", -1))
		&"offer_concession":
			expected_cost = 400
		&"deny_and_monitor":
			expected_cost = 0
	return int(chosen.get("cost_cents", -1)) == expected_cost


func _apply_flock_petition_response(option_id: StringName, chosen: Dictionary) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var petition_type := StringName(sim.pending_decision.get("petition_type", &""))
	var sponsor_id := int(sim.pending_decision.get("sponsor_worker_id", -1))
	var sponsor := sim.workers[sponsor_id]
	var solidarity_before := sim.solidarity
	var compact_scheduled := false
	var work_to_rule_scheduled := false
	match option_id:
		&"sign_compact":
			sponsor.manager_trust = minf(100.0, sponsor.manager_trust + 6.0)
			sponsor.grievance = maxf(0.0, sponsor.grievance - 8.0)
			sponsor.morale = minf(100.0, sponsor.morale + 3.0)
			sim.solidarity = minf(100.0, sim.solidarity + 5.0)
			sim.executive_confidence = maxf(0.0, sim.executive_confidence - 2.0)
			sim.active_flock_compact = _new_flock_compact(petition_type, sponsor)
			compact_scheduled = true
		&"offer_concession":
			sim._adjust_worker_relationships(1.0, -1.0)
			sponsor.manager_trust = minf(100.0, sponsor.manager_trust + 2.0)
			sponsor.grievance = maxf(0.0, sponsor.grievance - 3.0)
			sponsor.morale = minf(100.0, sponsor.morale + 2.0)
			sponsor.stress = maxf(0.0, sponsor.stress - 4.0)
			sponsor.fatigue = maxf(0.0, sponsor.fatigue - 2.0)
			sim.solidarity = minf(100.0, sim.solidarity + 2.0)
			sim.executive_confidence = maxf(0.0, sim.executive_confidence - 1.0)
		&"deny_and_monitor":
			sim._adjust_worker_relationships(-4.0, 8.0)
			sponsor.manager_trust = maxf(0.0, sponsor.manager_trust - 8.0)
			sponsor.grievance = minf(100.0, sponsor.grievance + 8.0)
			sponsor.morale = maxf(0.0, sponsor.morale - 5.0)
			sponsor.stress = minf(100.0, sponsor.stress + 5.0)
			sim.solidarity = minf(100.0, sim.solidarity + 14.0)
			sim.executive_confidence = minf(100.0, sim.executive_confidence + 4.0)
			if sim.solidarity >= DepartmentSimulation.WORK_TO_RULE_SOLIDARITY_THRESHOLD:
				work_to_rule_scheduled = _schedule_work_to_rule(
					&"petition_denied", sponsor.id, sponsor.display_name, sim.day, mini(9999, sim.day + 1)
				)
	var record := {
		"version": 1,
		"day": sim.day,
		"petition_type": String(petition_type),
		"petition_title": String(sim.pending_decision.get("title", "FLOCK PETITION")),
		"sponsor_worker_id": sponsor.id,
		"sponsor_worker_name": sponsor.display_name,
		"evidence": (sim.pending_decision.get("evidence", []) as Array).duplicate(true),
		"response_id": String(option_id),
		"response_tier": String(chosen.get("response_tier", "")),
		"cost_cents": int(chosen.get("cost_cents", 0)),
		"outcome": String(chosen.get("outcome", "Petition response recorded.")),
		"effective_day": mini(9999, sim.day + 1),
		"compact_scheduled": compact_scheduled,
		"work_to_rule_scheduled": work_to_rule_scheduled,
		"solidarity_before": snappedf(solidarity_before, 0.0001),
		"solidarity_after": snappedf(sim.solidarity, 0.0001),
	}
	sim.last_flock_petition = record.duplicate(true)
	sim.flock_petition_history.append(record.duplicate(true))
	while sim.flock_petition_history.size() > DepartmentSimulation.FLOCK_PETITION_HISTORY_LIMIT:
		sim.flock_petition_history.pop_front()
	return record


func _new_flock_compact(petition_type: StringName, sponsor: ChickenState) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var definition := DepartmentSimulation.FLOCK_PETITION_DEFINITIONS[petition_type] as Dictionary
	return {
		"version": 1,
		"compact_id": "D%d-%s-%d" % [sim.day, String(petition_type), sponsor.id],
		"petition_day": sim.day,
		"effective_day": mini(9999, sim.day + 1),
		"status": "scheduled",
		"petition_type": String(petition_type),
		"compact_name": String(definition.get("compact_name", "FLOCK COMPACT")),
		"sponsor_worker_id": sponsor.id,
		"sponsor_worker_name": sponsor.display_name,
		"promise": String(definition.get("promise", "")),
		"condition": String(definition.get("condition", "")),
	}


func _schedule_work_to_rule(
	trigger: StringName,
	sponsor_id: int,
	sponsor_name: String,
	petition_day: int,
	effective_day: int,
) -> bool:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if effective_day < sim.day or effective_day > 9999:
		return false
	var record := {
		"version": 1,
		"trigger": String(trigger),
		"petition_day": petition_day,
		"effective_day": effective_day,
		"status": "active" if effective_day == sim.day else "scheduled",
		"sponsor_worker_id": sponsor_id,
		"sponsor_worker_name": sponsor_name,
		"work_multiplier": DepartmentSimulation.WORK_TO_RULE_WORK_MULTIPLIER,
		"crack_modifier": DepartmentSimulation.WORK_TO_RULE_CRACK_MODIFIER,
		"outcome": "The flock is following every written procedure, including the slow ones.",
	}
	if sim.work_to_rule_day == 0:
		sim.work_to_rule_day = effective_day
		sim.last_work_to_rule_record = record
		return true
	if sim.work_to_rule_day == effective_day:
		return true
	if sim.work_to_rule_day == sim.day and effective_day > sim.day and sim.queued_work_to_rule_day == 0:
		sim.queued_work_to_rule_day = effective_day
		sim.queued_work_to_rule_record = record
		return true
	if sim.queued_work_to_rule_day == effective_day:
		return true
	return false


func _breach_compact_for_sponsor_release(worker_id: int) -> bool:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if sim.active_flock_compact.is_empty():
		return false
	if int(sim.active_flock_compact.get("sponsor_worker_id", -1)) != worker_id:
		return false
	return _breach_flock_compact(&"sponsor_released")


func _breach_specialty_compact_for_assignment(worker: ChickenState) -> bool:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if sim.active_flock_compact.is_empty():
		return false
	if StringName(sim.active_flock_compact.get("status", &"")) != &"active":
		return false
	if StringName(sim.active_flock_compact.get("petition_type", &"")) != &"specialty_respect":
		return false
	if int(sim.active_flock_compact.get("sponsor_worker_id", -1)) != worker.id:
		return false
	if worker.assigned_lane == worker.specialty:
		return false
	return _breach_flock_compact(&"specialty_assignment_changed")


func _breach_safe_pace_compact(reason: StringName) -> bool:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if sim.active_flock_compact.is_empty():
		return false
	if StringName(sim.active_flock_compact.get("status", &"")) != &"active":
		return false
	if StringName(sim.active_flock_compact.get("petition_type", &"")) != &"safe_pace":
		return false
	return _breach_flock_compact(reason)


func _breach_flock_compact(reason: StringName) -> bool:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if sim.active_flock_compact.is_empty():
		return false
	if StringName(sim.active_flock_compact.get("status", &"")) not in [&"scheduled", &"active"]:
		return false
	var compact := sim.active_flock_compact.duplicate(true)
	var sponsor_id := int(compact.get("sponsor_worker_id", -1))
	sim._adjust_worker_relationships(-3.0, 6.0)
	if sponsor_id >= 0 and sponsor_id < sim.workers.size():
		var sponsor := sim.workers[sponsor_id]
		sponsor.manager_trust = maxf(0.0, sponsor.manager_trust - 9.0)
		sponsor.grievance = minf(100.0, sponsor.grievance + 12.0)
		sponsor.morale = maxf(0.0, sponsor.morale - 6.0)
	sim.solidarity = minf(100.0, sim.solidarity + 16.0)
	sim.compliance = maxf(0.0, sim.compliance - 4.0)
	sim.executive_confidence = maxf(0.0, sim.executive_confidence - 3.0)
	var schedule_day := sim.day if sim.shift_phase in [DepartmentSimulation.ShiftPhase.REVIEW, DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE] else mini(9999, sim.day + 1)
	var work_scheduled := false
	if sim.solidarity >= DepartmentSimulation.WORK_TO_RULE_SOLIDARITY_THRESHOLD:
		work_scheduled = _schedule_work_to_rule(
			&"compact_breached",
			sponsor_id,
			String(compact.get("sponsor_worker_name", "")),
			int(compact.get("petition_day", sim.day)),
			schedule_day,
		)
	sim.last_flock_compact_receipt = {
		"version": 1,
		"compact_id": String(compact.get("compact_id", "")),
		"petition_day": int(compact.get("petition_day", 0)),
		"effective_day": int(compact.get("effective_day", 0)),
		"resolved_day": sim.day,
		"status": "breached",
		"petition_type": String(compact.get("petition_type", "")),
		"compact_name": String(compact.get("compact_name", "FLOCK COMPACT")),
		"sponsor_worker_id": sponsor_id,
		"sponsor_worker_name": String(compact.get("sponsor_worker_name", "")),
		"promise": String(compact.get("promise", "")),
		"condition": String(compact.get("condition", "")),
		"reason": String(reason),
		"work_to_rule_scheduled": work_scheduled,
		"outcome": "%s was breached. The flock has entered the consequence in its own ledger." % String(compact.get("compact_name", "Flock compact")),
	}
	sim.active_flock_compact.clear()
	sim.announcement_posted.emit(String(sim.last_flock_compact_receipt.get("outcome", "Compact breached.")))
	return true


func _resolve_due_flock_compact(completed_day: int) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if sim.active_flock_compact.is_empty():
		return {}
	if (
		StringName(sim.active_flock_compact.get("status", &"")) != &"active"
		or int(sim.active_flock_compact.get("effective_day", 0)) != completed_day
	):
		return {}
	var petition_type := StringName(sim.active_flock_compact.get("petition_type", &""))
	var sponsor_id := int(sim.active_flock_compact.get("sponsor_worker_id", -1))
	var fulfilled := sponsor_id >= 0 and sponsor_id < sim.workers.size() and sim.workers[sponsor_id].employed
	var breach_reason: StringName = &"sponsor_unavailable"
	if fulfilled:
		var sponsor := sim.workers[sponsor_id]
		match petition_type:
			&"specialty_respect":
				fulfilled = sponsor.assigned_lane == sponsor.specialty
				breach_reason = &"specialty_assignment_changed"
			&"safe_pace":
				fulfilled = not sim.overtime_enabled
				breach_reason = &"overtime_enabled"
			&"credit_in_writing":
				fulfilled = (
					sponsor.last_personnel_action_day == completed_day
					and sponsor.last_personnel_action == &"share_credit"
				)
				breach_reason = &"credit_not_filed"
	if not fulfilled:
		_breach_flock_compact(breach_reason)
		return sim.last_flock_compact_receipt.duplicate(true)
	var compact := sim.active_flock_compact.duplicate(true)
	var sponsor := sim.workers[sponsor_id]
	sim._adjust_worker_relationships(1.0, -2.0)
	sponsor.manager_trust = minf(100.0, sponsor.manager_trust + 7.0)
	sponsor.grievance = maxf(0.0, sponsor.grievance - 8.0)
	sponsor.morale = minf(100.0, sponsor.morale + 5.0)
	sim.solidarity = minf(100.0, sim.solidarity + 3.0)
	sim.executive_confidence = maxf(0.0, sim.executive_confidence - 2.0)
	sim.last_flock_compact_receipt = {
		"version": 1,
		"compact_id": String(compact.get("compact_id", "")),
		"petition_day": int(compact.get("petition_day", 0)),
		"effective_day": int(compact.get("effective_day", 0)),
		"resolved_day": completed_day,
		"status": "fulfilled",
		"petition_type": String(petition_type),
		"compact_name": String(compact.get("compact_name", "FLOCK COMPACT")),
		"sponsor_worker_id": sponsor_id,
		"sponsor_worker_name": sponsor.display_name,
		"promise": String(compact.get("promise", "")),
		"condition": String(compact.get("condition", "")),
		"reason": "promise_kept",
		"work_to_rule_scheduled": false,
		"outcome": "%s was fulfilled once, on the shift it named." % String(compact.get("compact_name", "Flock compact")),
	}
	sim.active_flock_compact.clear()
	sim.announcement_posted.emit(String(sim.last_flock_compact_receipt.get("outcome", "Compact fulfilled.")))
	return sim.last_flock_compact_receipt.duplicate(true)


func flock_relations_snapshot() -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var published_cases: Array[Dictionary] = []
	for case_record in sim.flock_relations_open_cases:
		published_cases.append(_flock_relations_public_case(case_record))
	return {
		"level": sim.facility_level(DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID),
		"capacity": sim.flock_relations_case_capacity(),
		"resolution_limit": sim.flock_relations_resolution_limit(),
		"resolutions_used_today": sim.flock_relations_resolutions_used_today,
		"open_case_count": sim.flock_relations_open_cases.size(),
		"open_cases": published_cases,
		"resolved_total": sim.flock_relations_resolved_total,
		"denied_total": sim.flock_relations_denied_total,
		"settlement_spend_total_cents": sim.flock_relations_settlement_spend_total_cents,
		"last_resolution": sim.last_flock_relations_resolution.duplicate(true),
	}


func _flock_relations_public_case(case_record: Dictionary) -> Dictionary:
	var case_id := int(case_record.get("case_id", 0))
	var worker_id := int(case_record.get("worker_id", -1))
	var worker_name := String(case_record.get("worker_name", "UNKNOWN HEN"))
	var action_options: Array[Dictionary] = []
	for action_id in DepartmentSimulation.FLOCK_RELATIONS_ACTION_ORDER:
		var preflight := flock_relations_resolution_preflight(case_id, action_id)
		action_options.append({
			"action_id": action_id,
			"label": String(preflight.get("label", "CASE ACTION")),
			"required_level": int(preflight.get("required_level", 0)),
			"cost_cents": int(preflight.get("cost_cents", 0)),
			"enabled": bool(preflight.get("can_resolve", false)),
			"reason": String(preflight.get("reason", "")),
			"effect_preview": String(preflight.get("effect_preview", "")),
		})
	var filed_day := int(case_record.get("filed_day", 0))
	var case_type := StringName(case_record.get("type", &"workplace_grievance"))
	var evidence := (case_record.get("evidence", {}) as Dictionary).duplicate(true)
	return {
		"case_id": case_id,
		"docket_id": "FR-D%d-H%d-%d" % [filed_day, worker_id, case_id],
		"worker": {"id": worker_id, "name": worker_name},
		"worker_id": worker_id,
		"worker_name": worker_name,
		"type": case_type,
		"case_type": case_type,
		"title": String(case_record.get("title", "WORKPLACE GRIEVANCE")),
		"severity": int(case_record.get("severity", 1)),
		"filed": filed_day,
		"filed_day": filed_day,
		"status": StringName(case_record.get("status", &"open")),
		"evidence": evidence,
		"evidence_summary": _flock_relations_evidence_summary(evidence),
		"action_options": action_options,
	}


func _flock_relations_evidence_summary(evidence: Dictionary) -> String:
	var summary := "Risk %d | Grievance %.1f | Stress %.1f | Fatigue %.1f | Trust %.1f" % [
		int(evidence.get("risk_score", 0)),
		float(evidence.get("grievance", 0.0)),
		float(evidence.get("stress", 0.0)),
		float(evidence.get("fatigue", 0.0)),
		float(evidence.get("manager_trust", 0.0)),
	]
	var arrears_cents := int(evidence.get("wage_arrears_cents", 0))
	if arrears_cents > 0:
		summary += " | Arrears $%.2f" % (float(arrears_cents) / 100.0)
	if bool(evidence.get("it_coop_installed", false)):
		summary += " | Compliance %.1f" % float(evidence.get("compliance", 0.0))
	return summary


func _flock_relations_case_index(case_id: int) -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	for index in sim.flock_relations_open_cases.size():
		if int(sim.flock_relations_open_cases[index].get("case_id", -1)) == case_id:
			return index
	return -1


func _flock_relations_action_cost_cents(action_id: StringName, severity: int) -> int:
	var bounded_severity := clampi(severity, 1, 3)
	match action_id:
		&"fund_remedy":
			return 800 + bounded_severity * 400
		&"mediate":
			return 400 + bounded_severity * 200
		&"file_pip":
			return 0
		&"binding_arbitration":
			return 600 + bounded_severity * 300
	return 0


func flock_relations_resolution_preflight(case_id: int, action_id: StringName) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var known_action := DepartmentSimulation.FLOCK_RELATIONS_ACTION_DEFINITIONS.has(action_id)
	var definition := (
		DepartmentSimulation.FLOCK_RELATIONS_ACTION_DEFINITIONS[action_id] as Dictionary
		if known_action else
		{}
	)
	var case_index := _flock_relations_case_index(case_id)
	var case_found := case_index >= 0
	var case_record := (
		sim.flock_relations_open_cases[case_index]
		if case_found else
		{}
	)
	var severity := int(case_record.get("severity", 1))
	var cost_cents := (
		sim._flock_relations_action_cost_cents(action_id, severity)
		if known_action and case_found else
		0
	)
	var required_level := int(definition.get("required_level", 0))
	var level := sim.facility_level(DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID)
	var installed := level > 0
	var review_open := sim.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW
	var within_limit := (
		sim.flock_relations_resolutions_used_today < sim.flock_relations_resolution_limit()
	)
	var tier_available := known_action and installed and level >= required_level
	var affordable := known_action and case_found and sim.spendable_fund_cents() >= cost_cents
	var can_resolve := (
		known_action
		and case_found
		and installed
		and review_open
		and within_limit
		and tier_available
		and affordable
	)
	var reason := ""
	if not known_action:
		reason = "That disposition is not on the Flock Relations action schedule."
	elif not case_found:
		reason = "That workplace case is no longer open."
	elif not installed:
		reason = "Commission Flock Relations before resolving workplace cases."
	elif not review_open:
		reason = "Workplace cases may only be resolved during shift review."
	elif not within_limit:
		reason = "The Flock Relations review limit has been reached for this day."
	elif not tier_available:
		reason = "%s requires Flock Relations level %d; the office is level %d." % [
			String(definition.get("label", "CASE ACTION")),
			required_level,
			level,
		]
	elif not affordable:
		reason = "%s requires $%.2f in spendable Feed Fund." % [
			String(definition.get("label", "CASE ACTION")),
			float(cost_cents) / 100.0,
		]
	return {
		"accepted": can_resolve,
		"can_resolve": can_resolve,
		"case_id": case_id,
		"case_found": case_found,
		"action_id": action_id,
		"known_action": known_action,
		"label": String(definition.get("label", "UNKNOWN DISPOSITION")),
		"required_level": required_level,
		"cost_cents": cost_cents,
		"effect_preview": String(definition.get("effect_preview", "")),
		"level": level,
		"installed": installed,
		"review_open": review_open,
		"resolution_limit": sim.flock_relations_resolution_limit(),
		"resolutions_used_today": sim.flock_relations_resolutions_used_today,
		"within_limit": within_limit,
		"affordable": affordable,
		"spendable_fund_cents": sim.spendable_fund_cents(),
		"reason": reason,
	}


func resolve_flock_relations_case(case_id: int, action_id: StringName) -> Dictionary:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var preflight := flock_relations_resolution_preflight(case_id, action_id)
	if not bool(preflight.get("can_resolve", false)):
		var rejection := preflight.duplicate(true)
		rejection["accepted"] = false
		return rejection
	var case_index := _flock_relations_case_index(case_id)
	if case_index < 0:
		# The public method is synchronous, but retain a closed atomic guard if that
		# ever changes so no fund or relationship mutation can outlive its case.
		var missing := preflight.duplicate(true)
		missing["accepted"] = false
		missing["can_resolve"] = false
		missing["reason"] = "That workplace case is no longer open."
		return missing
	var case_record := sim.flock_relations_open_cases[case_index]
	var worker_id := int(case_record.get("worker_id", -1))
	if worker_id < 0 or worker_id >= sim.workers.size():
		var invalid_subject := preflight.duplicate(true)
		invalid_subject["accepted"] = false
		invalid_subject["can_resolve"] = false
		invalid_subject["reason"] = "The case subject is not in the authoritative flock ledger."
		return invalid_subject
	var worker := sim.workers[worker_id]
	var public_case_before_resolution := _flock_relations_public_case(case_record)
	var fund_before := sim.revenue_cents
	var trust_before := worker.manager_trust
	var grievance_before := worker.grievance
	var stress_before := worker.stress
	var compliance_before := sim.compliance
	var solidarity_before := sim.solidarity
	var favor_before := sim.executive_confidence
	match action_id:
		&"fund_remedy":
			worker.manager_trust = clampf(worker.manager_trust + 12.0, 0.0, 100.0)
			worker.grievance = clampf(worker.grievance - 16.0, 0.0, 100.0)
			worker.stress = clampf(worker.stress - 8.0, 0.0, 100.0)
			sim.compliance = clampf(sim.compliance + 4.0, 0.0, 100.0)
			sim.executive_confidence = clampf(sim.executive_confidence - 2.0, 0.0, 100.0)
		&"mediate":
			worker.manager_trust = clampf(worker.manager_trust + 7.0, 0.0, 100.0)
			worker.grievance = clampf(worker.grievance - 9.0, 0.0, 100.0)
			worker.stress = clampf(worker.stress - 4.0, 0.0, 100.0)
			sim.compliance = clampf(sim.compliance + 2.0, 0.0, 100.0)
			sim.executive_confidence = clampf(sim.executive_confidence - 1.0, 0.0, 100.0)
		&"file_pip":
			worker.manager_trust = clampf(worker.manager_trust - 10.0, 0.0, 100.0)
			worker.grievance = clampf(worker.grievance + 14.0, 0.0, 100.0)
			worker.stress = clampf(worker.stress + 8.0, 0.0, 100.0)
			sim.compliance = clampf(sim.compliance - 3.0, 0.0, 100.0)
			sim.solidarity = clampf(sim.solidarity + 4.0, 0.0, 100.0)
			sim.executive_confidence = clampf(sim.executive_confidence + 3.0, 0.0, 100.0)
			sim.flock_relations_denied_total += 1
		&"binding_arbitration":
			worker.manager_trust = clampf(worker.manager_trust - 3.0, 0.0, 100.0)
			worker.grievance = clampf(worker.grievance - 5.0, 0.0, 100.0)
			worker.stress = clampf(worker.stress - 3.0, 0.0, 100.0)
			sim.compliance = clampf(sim.compliance + 6.0, 0.0, 100.0)
			sim.solidarity = clampf(sim.solidarity + 2.0, 0.0, 100.0)
			sim.executive_confidence = clampf(sim.executive_confidence + 1.0, 0.0, 100.0)
	var cost_cents := int(preflight.get("cost_cents", 0))
	sim.revenue_cents -= cost_cents
	sim.flock_relations_settlement_spend_total_cents += cost_cents
	sim.flock_relations_resolutions_used_today += 1
	sim.flock_relations_resolved_total += 1
	sim.flock_relations_open_cases.remove_at(case_index)
	var action_label := String(preflight.get("label", "CASE DISPOSITION"))
	var outcome := "%s closed %s's %s file for $%.2f." % [
		action_label.capitalize(),
		worker.display_name,
		String(case_record.get("title", "workplace grievance")).to_lower(),
		float(cost_cents) / 100.0,
	]
	var resolution := {
		"case_id": case_id,
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"type": StringName(case_record.get("type", &"workplace_grievance")),
		"title": String(case_record.get("title", "WORKPLACE GRIEVANCE")),
		"severity": int(case_record.get("severity", 1)),
		"filed_day": int(case_record.get("filed_day", 0)),
		"resolved_day": sim.day,
		"action_id": action_id,
		"action_label": action_label,
		"cost_cents": cost_cents,
		"outcome": outcome,
	}
	sim.last_flock_relations_resolution = resolution.duplicate(true)
	sim.flock_relations_resolution_history.append(resolution.duplicate(true))
	while sim.flock_relations_resolution_history.size() > DepartmentSimulation.FLOCK_RELATIONS_HISTORY_LIMIT:
		sim.flock_relations_resolution_history.pop_front()
	var result := preflight.duplicate(true)
	result.merge({
		"accepted": true,
		"case": public_case_before_resolution,
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"severity": int(case_record.get("severity", 1)),
		"fund_before_cents": fund_before,
		"fund_after_cents": sim.revenue_cents,
		"fund_delta_cents": sim.revenue_cents - fund_before,
		"trust_before": trust_before,
		"trust_after": worker.manager_trust,
		"grievance_before": grievance_before,
		"grievance_after": worker.grievance,
		"stress_before": stress_before,
		"stress_after": worker.stress,
		"compliance_before": compliance_before,
		"compliance_after": sim.compliance,
		"solidarity_before": solidarity_before,
		"solidarity_after": sim.solidarity,
		"farmer_favor_before": favor_before,
		"farmer_favor_after": sim.executive_confidence,
		"resolution": resolution.duplicate(true),
		"outcome": outcome,
	}, true)
	sim.announcement_posted.emit(outcome)
	sim.snapshot_changed.emit(sim.snapshot())
	return result


func _flock_relations_case_risk(worker: ChickenState) -> int:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var risk := roundi(
		worker.grievance * 2.0
		+ worker.stress
		+ worker.fatigue
		+ (100.0 - worker.manager_trust)
	)
	if sim.wage_arrears_cents > 0:
		risk += 120
	if sim.facility_level(DepartmentSimulation.IT_COOP_ID) > 0:
		risk += roundi(maxf(0.0, 70.0 - sim.compliance) * 2.0)
	return risk


func _recent_management_innovation_allocation(completed_day: int) -> bool:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if sim.last_credit_allocation.is_empty():
		return false
	var allocation_day := int(sim.last_credit_allocation.get("day", 0))
	return (
		StringName(sim.last_credit_allocation.get("style_id", &"")) == &"management_innovation"
		and allocation_day >= maxi(1, completed_day - 1)
		and allocation_day <= completed_day
	)


func _flock_relations_case_type(worker: ChickenState, completed_day: int) -> StringName:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	if sim.wage_arrears_cents > 0:
		return &"pay_dispute"
	if sim.facility_level(DepartmentSimulation.IT_COOP_ID) > 0 and sim.compliance < 60.0:
		return &"automation_appeal"
	if worker.grievance >= 50.0:
		return &"surveillance_grievance"
	if worker.stress + worker.fatigue >= 120.0:
		return &"burnout_case"
	if _recent_management_innovation_allocation(completed_day):
		return &"credit_claim"
	return &"workplace_grievance"


func _flock_relations_case_title(case_type: StringName) -> String:
	match case_type:
		&"pay_dispute":
			return "DEFERRED FEED PAY DISPUTE"
		&"automation_appeal":
			return "AUTOMATED ASSIGNMENT APPEAL"
		&"surveillance_grievance":
			return "SUPERVISION & SURVEILLANCE GRIEVANCE"
		&"burnout_case":
			return "OCCUPATIONAL NEST STRAIN CASE"
		&"credit_claim":
			return "WORK PRODUCT CREDIT FILE"
	return "WORKPLACE GRIEVANCE"


func _flock_relations_case_severity(risk_score: int) -> int:
	if risk_score >= 280:
		return 3
	if risk_score >= 220:
		return 2
	return 1


func _worker_has_open_flock_relations_case(worker_id: int) -> bool:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	for case_record in sim.flock_relations_open_cases:
		if int(case_record.get("worker_id", -1)) == worker_id:
			return true
	return false


func _file_flock_relations_case_after_shift(completed_day: int) -> Array[Dictionary]:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var filings: Array[Dictionary] = []
	if (
		sim.facility_level(DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID) <= 0
		or sim.flock_relations_open_cases.size() >= sim.flock_relations_case_capacity()
	):
		return filings
	var selected_worker: ChickenState
	var selected_risk := -1
	for worker in sim.workers:
		if not worker.employed or _worker_has_open_flock_relations_case(worker.id):
			continue
		var risk := _flock_relations_case_risk(worker)
		if risk < DepartmentSimulation.FLOCK_RELATIONS_CASE_RISK_THRESHOLD:
			continue
		if selected_worker == null or risk > selected_risk:
			selected_worker = worker
			selected_risk = risk
	if selected_worker == null:
		return filings
	var case_type := _flock_relations_case_type(selected_worker, completed_day)
	var case_record := {
		"case_id": sim.next_flock_relations_case_id,
		"worker_id": selected_worker.id,
		"worker_name": selected_worker.display_name,
		"type": case_type,
		"title": sim._flock_relations_case_title(case_type),
		"severity": sim._flock_relations_case_severity(selected_risk),
		"filed_day": completed_day,
		"status": &"open",
		"evidence": {
			"risk_score": selected_risk,
			"grievance": snappedf(selected_worker.grievance, 0.0001),
			"stress": snappedf(selected_worker.stress, 0.0001),
			"fatigue": snappedf(selected_worker.fatigue, 0.0001),
			"manager_trust": snappedf(selected_worker.manager_trust, 0.0001),
			"wage_arrears_cents": sim.wage_arrears_cents,
			"compliance": snappedf(sim.compliance, 0.0001),
			"it_coop_installed": sim.facility_level(DepartmentSimulation.IT_COOP_ID) > 0,
			"recent_management_innovation": _recent_management_innovation_allocation(completed_day),
		},
		"risk_score": selected_risk,
		"last_carry_day": completed_day,
	}
	sim.next_flock_relations_case_id += 1
	sim.flock_relations_open_cases.append(case_record)
	var published := _flock_relations_public_case(case_record)
	filings.append(published)
	sim.announcement_posted.emit(
		"FLOCK RELATIONS: %s filed %s (severity %d)." % [
			selected_worker.display_name,
			String(case_record["title"]).to_lower(),
			int(case_record["severity"]),
		]
	)
	return filings


func _apply_flock_relations_carry_penalties(completed_day: int) -> Array[Dictionary]:
	var sim: DepartmentSimulation = _sim_ref.get_ref()
	var effects: Array[Dictionary] = []
	for case_record in sim.flock_relations_open_cases:
		if (
			int(case_record.get("filed_day", completed_day)) >= completed_day
			or int(case_record.get("last_carry_day", 0)) >= completed_day
		):
			continue
		var worker_id := int(case_record.get("worker_id", -1))
		if worker_id < 0 or worker_id >= sim.workers.size():
			continue
		var worker := sim.workers[worker_id]
		var compliance_before := sim.compliance
		var solidarity_before := sim.solidarity
		var grievance_before := worker.grievance
		sim.compliance = clampf(sim.compliance - 1.5, 0.0, 100.0)
		sim.solidarity = clampf(sim.solidarity + 1.5, 0.0, 100.0)
		worker.grievance = clampf(worker.grievance + 2.0, 0.0, 100.0)
		case_record["last_carry_day"] = completed_day
		effects.append({
			"case_id": int(case_record.get("case_id", 0)),
			"worker_id": worker.id,
			"worker_name": worker.display_name,
			"day": completed_day,
			"compliance_before": compliance_before,
			"compliance_after": sim.compliance,
			"solidarity_before": solidarity_before,
			"solidarity_after": sim.solidarity,
			"grievance_before": grievance_before,
			"grievance_after": worker.grievance,
		})
	return effects
