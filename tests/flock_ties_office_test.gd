extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, copy: String) -> void:
	if not ok:
		failures.append(copy)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	await process_frame
	var sim := office.get("_simulation") as DepartmentSimulation
	sim.select_directive(&"shell_assurance")
	sim.revenue_cents = 10000
	(office.get("_campaign_ui") as ProbationCampaignUI).hide_modal()
	(office.get("_decision_host") as Control).hide()
	(office.get("_character_dialogue_ui") as CharacterDialogueUI).clear_session()
	var clock := office.get("_clock") as SimulationClock
	clock.set_speed(1)
	office.call("_open_flock_ties")
	var ui := office.get("_flock_ties_ui") as FlockTiesUI
	for unused in 8:
		await process_frame
	_check(ui != null and ui.visible, "live relationship panel opens")
	_check(bool(office.call("_nonconfirmation_management_surface_open")), "relationship reading owns management hold")
	_check(clock.interaction_hold_active() and clock.effective_multiplier() == 0, "live shift pauses while preserving requested speed")
	var snap := ui.snapshot()
	var panel := snap.panel_rect as Dictionary
	var action := snap.break_rect as Dictionary
	_check(float(panel.y) >= 0 and float(panel.y) + float(panel.height) <= 720.1, "panel fits logical viewport")
	_check(float(action.y) + float(action.height) <= float(panel.y) + float(panel.height), "action stays inside panel")
	var before := sim.revenue_cents
	ui.action_requested.emit(0, 1, "shared_break")
	_check(sim.revenue_cents == before - 100 and int(ui.snapshot().pair.affinity) == 8, "public panel signal reaches authority and refreshes story")
	_check(not ui.snapshot().break_available and not ui.snapshot().repair_available, "used opportunity disables both buttons")
	ui.pair_selected.emit(0, 2)
	_check(ui.snapshot().partner_id == 2, "pair selector refreshes independently")
	office.call("_close_flock_ties")
	_check(not ui.visible and not clock.interaction_hold_active() and clock.speed_index == 1, "close restores prior running speed")
	clock.set_speed(0)
	office.call("_open_flock_ties")
	office.call("_close_flock_ties")
	_check(clock.speed_index == 0, "manual pause is preserved")
	office.queue_free()
	await process_frame
	if failures.is_empty():
		print("FLOCK_TIES_OFFICE_TEST_PASSED modal=live clock=preserved action=authoritative geometry=contained")
		quit(0)
	else:
		for failure in failures:
			push_error("FLOCK_TIES_OFFICE_TEST_FAILED: " + failure)
		quit(1)
