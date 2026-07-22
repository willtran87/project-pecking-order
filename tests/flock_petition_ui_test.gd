extends SceneTree


const PETITION_PROMISE := "Assign the sponsor to her trained claim lane for the entire next shift."
const PETITION_TEST := "Sponsor remains assigned to her specialty lane for the full shift."


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	var decision_host := office.find_child("ManagementDecisionHost", true, false) as Control
	var routing_ui := office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	var labor_label := office.find_child("FlockLaborStatus", true, false) as Label
	var policy_badge := office.get("_directive_badge") as Label
	_check(
		simulation != null
		and clock != null
		and decision_host != null
		and routing_ui != null
		and labor_label != null
		and policy_badge != null,
		"real Office should expose every petition presentation collaborator",
		failures,
	)
	if simulation == null or clock == null or decision_host == null or routing_ui == null:
		await _finish(office, failures)
		return

	var baseline := simulation.snapshot()
	var sponsor := _worker_snapshot(baseline, 0)
	var sponsor_id := int(sponsor.get("id", -1))
	var sponsor_name := String(sponsor.get("name", "Mabel"))
	_check(sponsor_id >= 0 and not sponsor_name.is_empty(), "fixture should use a named employed sponsor", failures)

	clock.set_speed(2)
	office.call("_on_decision_requested", _petition_decision(sponsor_id, sponsor_name))
	await process_frame
	await process_frame
	var decision_title := office.get("_decision_title") as Label
	var decision_body := office.get("_decision_body") as Label
	var decision_preview := office.find_child("DecisionPreview", true, false) as Label
	var sign := office.find_child("DecisionOption_sign_compact", true, false) as Button
	var concede := office.find_child("DecisionOption_offer_concession", true, false) as Button
	var deny := office.find_child("DecisionOption_deny_and_monitor", true, false) as Button
	var option_buttons := office.get("_decision_option_buttons") as Array[Button]
	_check(decision_host.is_visible_in_tree(), "petition should open the real management decision modal", failures)
	_check(clock.speed_index == 0, "petition modal should hold the previously running clock at pause", failures)
	_check(decision_title != null and decision_title.text == "A HEN REQUESTS HER OWN KIND OF PECKWORK", "petition should retain its authored collective title", failures)
	_check(
		decision_body != null
		and sponsor_name in decision_body.text
		and "FILED EVIDENCE" in decision_body.text
		and "Assigned file: APPEALS" in decision_body.text
		and "Trained file: NEST DAMAGE" in decision_body.text,
		"petition body should expose the named sponsor and filed evidence",
		failures,
	)
	_check(
		decision_body != null
		and "PROPOSED COMPACT" in decision_body.text
		and PETITION_PROMISE in decision_body.text
		and "FULFILLMENT TEST" in decision_body.text
		and PETITION_TEST in decision_body.text,
		"petition body should expose the exact promise and measurable fulfillment test",
		failures,
	)
	_check(
		decision_preview != null and "remains safely paused" in decision_preview.text,
		"petition response prompt should explain that review remains paused",
		failures,
	)
	_check(option_buttons.size() == 3, "petition modal should expose exactly three response tiers", failures)
	_check_petition_option(sign, "SIGN THE COMPACT", "$7.00", "binding next shift", 700, failures)
	_check_petition_option(concede, "OFFER A SCOOP OF FEED", "$4.00", "no binding compact", 400, failures)
	_check_petition_option(deny, "DENY AND MONITOR", "FREE", "work-to-rule", 0, failures)

	# The modal is presentation-only in this focused fixture. Reveal Flockwatch and
	# feed the same snapshot shapes that Office receives from the simulation.
	decision_host.visible = false
	routing_ui.set_interaction_enabled(true)
	office.call("_set_flockwatch_open", true)
	await process_frame
	var compact := _compact_snapshot(sponsor_id, sponsor_name, &"scheduled")
	var scheduled_compact_snapshot := baseline.duplicate(true)
	scheduled_compact_snapshot["active_directive"] = {
		"short_name": "ASSURANCE",
		"preview": "Protect shell quality before filing credit.",
	}
	scheduled_compact_snapshot["flock_compact"] = compact
	scheduled_compact_snapshot["work_to_rule"] = _inactive_work_to_rule()
	office.call("_on_snapshot_changed", scheduled_compact_snapshot)
	await process_frame
	_check(labor_label.is_visible_in_tree(), "Flockwatch should expose its compact labor ledger when opened", failures)
	_check(
		"BINDING COMPACT" in labor_label.text
		and "SPECIALTY NEST COMPACT" in labor_label.text
		and sponsor_name.to_upper() in labor_label.text
		and "SCHEDULED FOR DAY 2" in labor_label.text
		and PETITION_TEST in labor_label.text,
		"scheduled compact display should preserve sponsor, effective day, and exact test",
		failures,
	)
	_check(
		"COMPACT" in policy_badge.text and "SPECIALTY NEST COMPACT" in policy_badge.tooltip_text and PETITION_TEST in policy_badge.tooltip_text,
		"top policy badge should signal the filed compact and retain its fulfillment test",
		failures,
	)

	var active_compact := compact.duplicate(true)
	active_compact["status"] = "active"
	var active_compact_snapshot := scheduled_compact_snapshot.duplicate(true)
	active_compact_snapshot["flock_compact"] = active_compact
	office.call("_update_flock_labor_label", active_compact_snapshot)
	_check(
		"ACTIVE FOR DAY 2" in labor_label.text and PETITION_TEST in labor_label.text,
		"active compact display should remain distinct and keep its measurable test",
		failures,
	)

	var scheduled_work_snapshot := baseline.duplicate(true)
	scheduled_work_snapshot["active_directive"] = scheduled_compact_snapshot["active_directive"]
	scheduled_work_snapshot["flock_compact"] = {}
	scheduled_work_snapshot["work_to_rule"] = _work_to_rule_snapshot(false, true)
	office.call("_on_snapshot_changed", scheduled_work_snapshot)
	await process_frame
	_check(
		"WORK-TO-RULE" in labor_label.text
		and "SCHEDULED DAY 3" in labor_label.text
		and "throughput -18%" in labor_label.text
		and "crack risk -6 pts" in labor_label.text,
		"scheduled work-to-rule display should quantify its slower, safer effects",
		failures,
	)
	_check(
		"ACTION FILED" in policy_badge.text and "scheduled for Day 3" in policy_badge.tooltip_text,
		"top policy badge should signal scheduled collective action",
		failures,
	)

	var active_work_snapshot := scheduled_work_snapshot.duplicate(true)
	active_work_snapshot["work_to_rule"] = _work_to_rule_snapshot(true, false)
	office.call("_on_snapshot_changed", active_work_snapshot)
	await process_frame
	_check(
		"ACTIVE DAY 3" in labor_label.text
		and "throughput -18%" in labor_label.text
		and "crack risk -6 pts" in labor_label.text,
		"active work-to-rule display should keep both causal modifiers legible",
		failures,
	)
	_check(
		"WORK-TO-RULE" in policy_badge.text
		and "output is slower" in policy_badge.tooltip_text
		and "shells are safer" in policy_badge.tooltip_text,
		"top policy badge should identify active labor state and summarize its tradeoff",
		failures,
	)

	# Use an authoritative simulation snapshot for the dossier marker. The flags
	# are computed by DepartmentSimulation, not invented inside the routing UI.
	simulation.active_flock_compact = active_compact.duplicate(true)
	var sponsor_snapshot := simulation.snapshot()
	var sponsor_worker := _worker_snapshot(sponsor_snapshot, sponsor_id)
	_check(
		bool(sponsor_worker.get("is_compact_sponsor", false))
		and String(sponsor_worker.get("compact_condition", "")) == PETITION_TEST,
		"simulation worker snapshot should identify the compact sponsor and exact obligation",
		failures,
	)
	office.call("_set_flockwatch_open", false)
	routing_ui.apply_snapshot(sponsor_snapshot)
	routing_ui.set_focus(sponsor_id)
	await process_frame
	await process_frame
	var dossier := office.find_child("PeckworkAssignmentDossier", true, false) as PanelContainer
	var sponsor_marker := office.find_child("RoutingWorkerSpecialty", true, false) as Label
	_check(dossier != null and dossier.is_visible_in_tree(), "compact sponsor should have a visible focused routing dossier", failures)
	_check(
		sponsor_marker != null
		and "COMPACT SPONSOR" in sponsor_marker.text
		and "BINDING FLOCK COMPACT" in sponsor_marker.tooltip_text
		and PETITION_TEST in sponsor_marker.tooltip_text,
		"focused dossier should expose a compact sponsor marker with the binding test",
		failures,
	)

	await _finish(office, failures)


func _petition_decision(sponsor_id: int, sponsor_name: String) -> Dictionary:
	return {
		"serial": 991,
		"kind": &"incident",
		"category": &"flock_petition",
		"id": &"flock_petition",
		"eyebrow": "FLOCK PETITION  ·  AUTO-PAUSED  ·  2:00 PM",
		"title": "A HEN REQUESTS HER OWN KIND OF PECKWORK",
		"body": "%s has put her name on a collective request. Its evidence comes from the performance ledger." % sponsor_name,
		"petition_type": &"specialty_respect",
		"sponsor_worker_id": sponsor_id,
		"sponsor_worker_name": sponsor_name,
		"evidence": [
			"Assigned file: APPEALS",
			"Trained file: NEST DAMAGE",
			"Grievance ledger: 72",
		],
		"petition": {
			"promise": PETITION_PROMISE,
			"condition": PETITION_TEST,
		},
		"options": [
			{
				"id": &"sign_compact",
				"response_tier": &"binding",
				"label": "SIGN THE COMPACT",
				"tagline": "Put tomorrow's promise in writing.",
				"preview": "$7.00  /  binding next shift  /  breach has consequences",
				"cost_cents": 700,
			},
			{
				"id": &"offer_concession",
				"response_tier": &"concession",
				"label": "OFFER A SCOOP OF FEED",
				"tagline": "Address today's strain without signing tomorrow away.",
				"preview": "$4.00  /  immediate relief  /  no binding compact",
				"cost_cents": 400,
			},
			{
				"id": &"deny_and_monitor",
				"response_tier": &"denial",
				"label": "DENY AND MONITOR",
				"tagline": "Call the pattern anecdotal and measure the reaction.",
				"preview": "FREE  /  trust falls  /  solidarity may trigger work-to-rule",
				"cost_cents": 0,
			},
		],
	}


func _compact_snapshot(sponsor_id: int, sponsor_name: String, status: StringName) -> Dictionary:
	return {
		"version": 1,
		"compact_id": "D1-specialty_respect-%d" % sponsor_id,
		"petition_day": 1,
		"effective_day": 2,
		"status": String(status),
		"petition_type": "specialty_respect",
		"compact_name": "SPECIALTY NEST COMPACT",
		"sponsor_worker_id": sponsor_id,
		"sponsor_worker_name": sponsor_name,
		"promise": PETITION_PROMISE,
		"condition": PETITION_TEST,
	}


func _inactive_work_to_rule() -> Dictionary:
	return {
		"active": false,
		"scheduled": false,
		"day": 0,
		"threshold": 45.0,
		"record": {},
	}


func _work_to_rule_snapshot(active: bool, scheduled: bool) -> Dictionary:
	return {
		"active": active,
		"scheduled": scheduled,
		"day": 3,
		"threshold": 45.0,
		"record": {
			"status": "active" if active else "scheduled",
			"effective_day": 3,
			"work_multiplier": 0.82,
			"crack_modifier": -0.06,
			"outcome": "The flock is following every written procedure, including the slow ones.",
		},
	}


func _worker_snapshot(snapshot: Dictionary, worker_id: int) -> Dictionary:
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return worker
	return {}


func _check_petition_option(
	button: Button,
	label: String,
	cost_text: String,
	tier_text: String,
	cost_cents: int,
	failures: Array[String],
) -> void:
	var preview_text := String(button.get_meta("preview", "")) if button != null else ""
	_check(
		button != null
		and label in button.text
		and cost_text in preview_text
		and tier_text in preview_text
		and cost_text in button.tooltip_text
		and tier_text in button.tooltip_text
		and int(button.get_meta("cost_cents", -1)) == cost_cents,
		"%s tier should expose its identity plus exact terms through the shared-preview contract" % label,
		failures,
	)


func _finish(office: Office, failures: Array[String]) -> void:
	var clock: SimulationClock
	if office != null:
		clock = office.get("_clock") as SimulationClock
	if clock != null:
		clock.set_speed(0)
	if office != null:
		office.free()
	await process_frame
	# Let the short decision-alert playback release its AudioServer reference
	# before this standalone SceneTree exits.
	await create_timer(0.5).timeout
	if not failures.is_empty():
		for failure in failures:
			push_error("FLOCK_PETITION_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FLOCK_PETITION_UI_TEST_PASSED modal=sponsor+evidence+promise+test tiers=3+costs pause=held labor=compact-scheduled+active+work-to-rule badge=scheduled+active sponsor=dossier")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
