extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(260824, 4)
	for worker_id in simulation.workers.size():
		simulation.set_worker_at_workstation(worker_id, true)
	_check(simulation.select_directive(&"shell_assurance"), "fixture should enter a running shift", failures)
	simulation.revenue_cents = 10000

	var opening := simulation.playbook_snapshot(0)
	var opening_spotlight := opening.get("opening_spotlight", {}) as Dictionary
	var study := opening.get("comprehension_study", {}) as Dictionary
	_check(bool(opening_spotlight.get("active", false)) and (opening_spotlight.get("path", []) as Array).size() == 3, "the first shift should spotlight plan, route, and result without a prose tutorial", failures)
	_check(int(study.get("participants_required", 0)) == 5 and String(study.get("status", "")) == "AWAITING REAL PARTICIPANTS", "the build should ship an honest five-person comprehension protocol without fabricated findings", failures)
	_check(DepartmentSimulation.challenge_seed_from_code(simulation.challenge_code()) == 824, "a share code should round-trip its deterministic four-digit seed", failures)
	_check(int(DepartmentSimulation.challenge_state_from_code(simulation.challenge_code()).get("day", 0)) == simulation.day, "a share code should round-trip the exact challenge day", failures)
	_check(DepartmentSimulation.challenge_seed_from_code("NOT-A-CODE") == -1, "invalid share codes should be rejected", failures)

	var plan := simulation.perform_playbook_action(&"preset", &"safe", 0)
	var arc := plan.get("decision_arc", {}) as Dictionary
	_check(bool(plan.get("accepted", false)) and bool(arc.get("reconciled", false)) and not (arc.get("forecast", {}) as Dictionary).is_empty(), "a plan should preserve forecast, action, and reconciled result in one receipt", failures)

	var proposal_id := simulation.call("_playbook_proposal_id", 0) as StringName
	var proposal := simulation.perform_playbook_action(&"proposal", proposal_id, 0)
	_check(bool(proposal.get("accepted", false)) and int(simulation.active_playbook.get("proposal_worker_id", -1)) == 0, "a named hen should make one authoritative optional proposal", failures)
	_check(not bool(simulation.perform_playbook_action(&"proposal", proposal_id, 0).get("accepted", false)), "the same shift must not duplicate hen proposals", failures)

	simulation.eggs_today = 1
	simulation.routing_momentum_chain = 0
	var rescue := simulation.perform_playbook_action(&"rescue", &"show_me", 0)
	_check(bool(rescue.get("accepted", false)) and simulation.routing_momentum_peck_recharge_bank == 1 and bool(simulation.active_playbook.get("rescue_used", false)), "Show Me should restore a specialty route and one visible help charge exactly once", failures)

	var stress_before := simulation.workers[0].stress
	var toy := simulation.perform_playbook_action(&"toy", &"cooler_break", 0)
	_check(bool(toy.get("accepted", false)) and simulation.workers[0].stress <= stress_before and String(simulation.active_playbook.get("toy_id", "")) == "cooler_break", "the break-room toy should produce one organic hen reaction and bounded recovery", failures)

	var display := simulation.perform_playbook_action(&"display", &"shell", 0)
	var sockets := simulation.playbook_snapshot(0).get("display_sockets", []) as Array
	_check(bool(display.get("accepted", false)) and sockets.size() == 3 and String((sockets[0] as Dictionary).get("style_id", "")) == "shell", "customization should restyle exactly three safe earned sockets", failures)

	var challenge := simulation.perform_playbook_action(&"challenge", &"copy_code", 0)
	_check(bool(challenge.get("accepted", false)) and not bool(challenge.get("changes_authority", true)) and String(challenge.get("code", "")).begins_with("PO-"), "sharing a challenge should be deterministic and presentation-only", failures)

	var playbook := simulation.playbook_snapshot(0)
	_check(not (playbook.get("build_identity", {}) as Dictionary).is_empty(), "the current build should have a compact identity summary", failures)
	_check(((playbook.get("mastery_automation", {}) as Dictionary).get("rules", []) as Array).size() == 3, "mastery automation should disclose specialty, deadline, and strain-protection rules", failures)
	_check(not (playbook.get("career_story", {}) as Dictionary).is_empty(), "persistent hen state should project as a multi-shift career story", failures)
	_check((playbook.get("personal_best", {}) as Dictionary).has("routing"), "live progress should compare against a persistent personal best", failures)

	var restored := DepartmentSimulation.new(1, 4)
	_check(restored.restore_save_state(simulation.export_save_state()), "the advancement record should survive a strict save round-trip", failures)
	_check(String(restored.active_playbook.get("proposal_id", "")) == String(proposal_id) and String(restored.active_playbook.get("toy_id", "")) == "cooler_break" and int(restored.active_playbook.get("display_style_index", -1)) == 1, "proposal, toy, rescue, and safe display choices should restore without duplication", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("ENGAGEMENT_ADVANCEMENT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("ENGAGEMENT_ADVANCEMENT_TEST_PASSED loop=forecast-action-result proposal=one rescue=one toys=bounded sockets=3 stories=derived challenge=round-trip study=instrumented")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
