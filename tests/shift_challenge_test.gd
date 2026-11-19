extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var sim := DepartmentSimulation.new(8129, 4)
	sim.select_directive(&"shell_assurance")
	sim.revenue_cents = 10000
	# The opening delivery must not make the new player's first plan inaccessible.
	sim.eggs_today = 1
	sim.eggs_total = 1
	_check(bool(sim.perform_playbook_action(&"preset", &"fast", 0).get("accepted", false)), "plan remains available after the opening egg")
	for lane: StringName in [&"nest_damage", &"predator_loss", &"appeals"]:
		var candidates := sim.dispatch_candidates(lane)
		var worker_id := int(candidates[0].worker_id)
		if sim.workers[worker_id].assigned_lane == lane:
			sim.set_worker_assignment(worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
		_check(bool(sim.dispatch_worker_to_lane(worker_id, lane).get("recommended", false)), "real recommended route advances challenge")
	_check(bool(sim.active_playbook.get("contract_completed", false)), "third route durably earns challenge")
	sim.call("_break_routing_momentum", "Test a later mistake", &"peck_precision", 0, -1)
	_check(sim.routing_momentum_chain == 0 and bool(sim.playbook_snapshot(0).contract.complete), "later mistake cannot remove earned reward")
	var saved := sim.export_save_state()
	var restored := DepartmentSimulation.new(5, 4)
	_check(restored.restore_save_state(saved), "earned challenge restores")
	_check(bool(restored.playbook_snapshot(0).contract.complete), "completion survives reload with broken streak")
	var cash := restored.revenue_cents
	_check(bool(restored.perform_playbook_action(&"reward", &"fund", 0).accepted), "earned reward can be claimed after reload")
	_check(restored.revenue_cents == cash + 300, "cash reward adds exactly three dollars")
	_check(not bool(restored.perform_playbook_action(&"reward", &"fund", 0).accepted), "cannot double claim")
	var invalid := saved.duplicate(true)
	invalid.active_playbook.contract_completed = "yes"
	_check(not DepartmentSimulation.new(5, 4).restore_save_state(invalid), "malformed completion is rejected")
	var legacy := saved.duplicate(true)
	legacy.active_playbook.erase("contract_completed")
	_check(DepartmentSimulation.new(5, 4).restore_save_state(legacy), "older checkpoints remain compatible")
	var boundary := DepartmentSimulation.new(12, 4)
	boundary.select_directive(&"shell_assurance")
	boundary.eggs_today = 4
	_check(not bool(boundary.perform_playbook_action(&"preset", &"safe", 0).accepted), "opening grace ends after three eggs")
	boundary.eggs_today = 1
	boundary.day = 2
	_check(not bool(boundary.perform_playbook_action(&"preset", &"safe", 0).accepted), "later shifts still require a plan before the first egg")
	var claimed_restore := DepartmentSimulation.new(5, 4)
	_check(claimed_restore.restore_save_state(restored.export_save_state()), "claimed reward restores")
	_check(not bool(claimed_restore.perform_playbook_action(&"reward", &"mastery", 0).accepted), "reloading cannot claim a second reward")
	for plan: StringName in [&"safe", &"flock"]:
		var other := DepartmentSimulation.new(8129, 4)
		other.select_directive(&"shell_assurance")
		other.revenue_cents = 10000
		other.perform_playbook_action(&"preset", plan, 0)
		for worker_id in 2:
			other.set_worker_at_workstation(worker_id, true)
		other.advance_tick()
		if plan == &"flock":
			for worker_id in 2:
				other.workers[worker_id].work_progress = 62.0
				_check(bool(other.perform_peck_assist(worker_id).get("accepted", false)), "real peck advances goal")
			other.peck_assist_streak = 0
		else:
			for worker_id in 2:
				# Choose a deterministic clean roll, then exercise normal egg completion.
				var rng := other.get("_rng") as RandomNumberGenerator
				for seed_value in range(1, 1000):
					rng.seed = seed_value
					if rng.randf() > 0.8:
						rng.seed = seed_value
						break
				other.call("_complete_egg", other.workers[worker_id])
			other.quality_streak = 0
		_check(bool(other.playbook_snapshot(0).contract.complete), "%s goal remains earned after streak resets" % plan)
		for worker in other.workers:
			worker.stress = 10.0
			worker.fatigue = 10.0
		var xp := other.workers[0].career_xp
		var choice := &"mastery" if plan == &"safe" else &"recovery"
		_check(bool(other.perform_playbook_action(&"reward", choice, 0).accepted), "alternative reward accepted")
		_check(other.workers[0].career_xp == xp + 6 if plan == &"safe" else is_equal_approx(other.workers[0].stress, 6.0) and is_equal_approx(other.workers[0].fatigue, 6.0), "alternative reward has exact benefit")
	var ui := ShiftChallengeUI.new()
	root.add_child(ui)
	var fixture := DepartmentSimulation.new(10, 4)
	fixture.select_directive(&"shell_assurance")
	fixture.revenue_cents = 10000
	var choices: Array[Dictionary] = []
	for option: Dictionary in fixture.playbook_snapshot(0).options:
		if option.kind == "preset":
			choices.append(option)
	var before := JSON.stringify(fixture.export_save_state())
	ui.show_choices("preset", choices, "Mabel", {})
	ui.call("_select", 1)
	_check(ui.snapshot().confirm_enabled and ui.snapshot().selected == 1, "preview explicitly selects a plan")
	_check(JSON.stringify(fixture.export_save_state()) == before, "preview never mutates gameplay")
	ui.confirmed.connect(func(option: Dictionary): fixture.perform_playbook_action(StringName(option.kind), StringName(option.id), 0))
	ui.call("_commit")
	_check(fixture.active_playbook.strategy_preset_id == "safe", "confirmation commits selected plan")
	ui.queue_free()
	await process_frame
	var office := Office.new()
	root.add_child(office)
	await process_frame
	(office.get("_campaign_ui") as ProbationCampaignUI).hide_modal()
	(office.get("_decision_host") as Control).hide()
	(office.get("_character_dialogue_ui") as CharacterDialogueUI).clear_session()
	var live := office.get("_simulation") as DepartmentSimulation
	live.select_directive(&"shell_assurance")
	(office.get("_decision_host") as Control).hide()
	var clock := office.get("_clock") as SimulationClock
	clock.set_speed(1)
	_check(bool(office.call("_open_shift_challenge_choices")), "live office opens comparison")
	var live_ui := office.get("_shift_challenge_ui") as ShiftChallengeUI
	_check(live_ui != null and clock.interaction_hold_active(), "reading choices pauses production")
	if live_ui != null:
		var cash_before := live.revenue_cents
		live_ui.call("_select", 0)
		live_ui.canceled.emit()
		_check(not clock.interaction_hold_active() and clock.speed_index == 1, "cancel restores the player's pace")
		_check(String(live.active_playbook.strategy_preset_id).is_empty() and live.revenue_cents == cash_before, "cancel does not spend or select a plan")
		office.call("_open_shift_challenge_choices")
		live_ui.more_actions_requested.emit()
		await process_frame
		await process_frame
		_check((office.get("_active_playbook_button") as MenuButton).get_popup().visible and not live_ui.visible, "other manager actions remain reachable before choosing a plan")
		(office.get("_active_playbook_button") as MenuButton).get_popup().hide()
		office.call("_open_shift_challenge_choices")
		live_ui.call("_select", 0)
		live_ui.call("_commit")
		_check(String(live.active_playbook.strategy_preset_id) == "fast" and not live_ui.visible and not clock.interaction_hold_active(), "confirm applies plan and releases pause")
		_check((office.get("_active_playbook_button") as MenuButton).text.begins_with("PLAN") and (office.get("_active_playbook_button") as MenuButton).tooltip_text.contains("0 / 3"), "stable Plan entry exposes actual goal progress")
		clock.set_speed(0)
		for lane: StringName in [&"nest_damage", &"predator_loss", &"appeals"]:
			var candidates := live.dispatch_candidates(lane)
			var worker_id := int(candidates[0].worker_id)
			if live.workers[worker_id].assigned_lane == lane:
				live.set_worker_assignment(worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
			live.dispatch_worker_to_lane(worker_id, lane)
		_check(bool(office.call("_open_shift_challenge_choices")) and live_ui.snapshot().mode == "reward", "earned reward opens dedicated choice screen")
		live_ui.canceled.emit()
		_check(bool(live.playbook_snapshot(0).contract.complete), "dismissing reward keeps it earned")
		office.call("_open_shift_challenge_choices")
		cash_before = live.revenue_cents
		live_ui.call("_select", 0)
		live_ui.call("_commit")
		_check(live.revenue_cents == cash_before + 300 and live.playbook_snapshot(0).contract.reward_claimed, "live reward UI credits the chosen payoff once")
		for reward_view: ChickenView in (office.get("_worker_views") as Dictionary).values():
			_check(reward_view.expression_snapshot().last_reaction == "proud", "a real fund reward gives the employed flock an earned reaction")
		office.call("_refresh_active_playbook_menu", live.playbook_snapshot(0), 0)
		_check((office.get("_active_playbook_button") as MenuButton).text == "PLAN [Q]" and (office.get("_active_playbook_button") as MenuButton).tooltip_text.contains("Reward claimed"), "menu refresh keeps navigation stable and the earned reward in its detail")
	office.queue_free()
	await process_frame
	if failures.is_empty():
		print("SHIFT_CHALLENGE_TEST_PASSED real-routes=3 goals=3 rewards=3 durable=true exact-once=true preview=nonmutating")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)
