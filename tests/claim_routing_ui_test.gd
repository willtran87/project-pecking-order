extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var routing_ui := office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	var queue_strip := office.find_child("PeckworkQueueStrip", true, false) as PanelContainer
	var dossier := office.find_child("PeckworkAssignmentDossier", true, false) as PanelContainer
	var nest_queue := office.find_child("Queue_nest_damage", true, false) as Label
	var predator_queue := office.find_child("Queue_predator_loss", true, false) as Label
	var appeals_queue := office.find_child("Queue_appeals", true, false) as Label
	var assign_auto := office.find_child("Assign_auto", true, false) as Button
	var assign_predator := office.find_child("Assign_predator_loss", true, false) as Button
	var current_claim := office.find_child("RoutingCurrentClaim", true, false) as Label
	var worker_career := office.find_child("RoutingWorkerCareer", true, false) as Label
	var worker_profile := office.find_child("RoutingWorkerSpecialty", true, false) as Label
	var manager_trust := office.find_child("RoutingManagerTrust", true, false) as Label
	var grievance := office.find_child("RoutingGrievance", true, false) as Label
	var check_in_status := office.find_child("RoutingCheckInStatus", true, false) as Label
	var share_credit := office.find_child("PersonnelAction_share_credit", true, false) as Button
	var career_coaching := office.find_child("PersonnelAction_career_coaching", true, false) as Button
	var quota_pressure := office.find_child("PersonnelAction_quota_pressure", true, false) as Button
	var decision_host := office.find_child("ManagementDecisionHost", true, false) as Control

	_check(routing_ui != null, "Office should install the routing interface", failures)
	_check(queue_strip != null and queue_strip.is_visible_in_tree(), "typed queue strip should remain visible in overview", failures)
	_check(nest_queue != null and "2" in nest_queue.text, "opening strip should show two Nest Damage files", failures)
	_check(predator_queue != null and "2" in predator_queue.text, "opening strip should show two Predator Loss files", failures)
	_check(appeals_queue != null and "2" in appeals_queue.text, "opening strip should show two Appeals files", failures)
	_check(dossier != null and not dossier.is_visible_in_tree(), "worker dossier should stay hidden before a hen is selected", failures)

	if routing_ui != null:
		routing_ui.set_focus(0)
	await process_frame
	_check(dossier != null and dossier.is_visible_in_tree(), "selecting a hen should open her routing dossier", failures)
	_check(assign_auto != null and assign_auto.disabled, "routing must remain locked behind the morning policy", failures)
	var opening_worker := _worker_snapshot(simulation.snapshot(), 0)
	_check(worker_career != null and worker_career.is_visible_in_tree(), "selected-hen dossier should expose career rank and XP", failures)
	_check(worker_career != null and String(opening_worker.get("career_title", "")) in worker_career.text, "career label should mirror the authoritative worker title", failures)
	_check(worker_career != null and "XP" in worker_career.text, "career label should make progression legible", failures)
	_check(worker_profile != null and worker_profile.is_visible_in_tree(), "selected-hen dossier should expose the career profile", failures)
	_check(worker_profile != null and String(opening_worker.get("career_profile_name", "")) in worker_profile.text, "profile label should mirror the authoritative worker profile", failures)
	_check(manager_trust != null and manager_trust.is_visible_in_tree() and "TRUST  %d" % int(roundf(float(opening_worker.get("manager_trust", -1.0)))) in manager_trust.text, "dossier should show authoritative manager trust", failures)
	_check(grievance != null and grievance.is_visible_in_tree() and "GRIEVANCE  %d" % int(roundf(float(opening_worker.get("grievance", -1.0)))) in grievance.text, "dossier should show authoritative grievance", failures)
	_check(check_in_status != null and "LOCKED" in check_in_status.text, "personnel check-in should explain its pre-policy lock", failures)
	_check(share_credit != null and share_credit.disabled, "share-credit action must remain locked behind the morning policy", failures)
	_check(career_coaching != null and career_coaching.disabled, "career-coaching action must remain locked behind the morning policy", failures)
	_check(quota_pressure != null and quota_pressure.disabled, "quota-pressure action must remain locked behind the morning policy", failures)

	var assurance_option := office.find_child("DecisionOption_shell_assurance", true, false) as Button
	var confirm_decision := office.find_child("ConfirmDecisionButton", true, false) as Button
	_check(assurance_option != null and confirm_decision != null, "opening policy controls should exist", failures)
	if assurance_option != null and confirm_decision != null:
		assurance_option.pressed.emit()
		confirm_decision.pressed.emit()
	await process_frame
	_check(decision_host != null and not decision_host.is_visible_in_tree(), "authorization should reveal live routing", failures)
	_check(assign_auto != null and not assign_auto.disabled, "routing should unlock during the running shift", failures)
	_check(check_in_status != null and "READY" in check_in_status.text, "personnel check-in should become ready during the running shift", failures)
	_check(share_credit != null and not share_credit.disabled, "share-credit action should unlock during the running shift", failures)
	_check(career_coaching != null and not career_coaching.disabled, "career-coaching action should unlock during the running shift", failures)
	_check(quota_pressure != null and not quota_pressure.disabled, "quota-pressure action should unlock during the running shift", failures)

	var trust_before := float(opening_worker.get("manager_trust", 0.0))
	var grievance_before := float(opening_worker.get("grievance", 0.0))
	var career_xp_before := int(opening_worker.get("career_xp", 0))
	if share_credit != null:
		share_credit.pressed.emit()
	await process_frame
	var managed_worker := _worker_snapshot(simulation.snapshot(), 0)
	_check(StringName(managed_worker.get("last_personnel_action", &"")) == &"share_credit", "personnel button should file its action on the authoritative worker", failures)
	_check(int(managed_worker.get("last_personnel_action_day", 0)) == int(simulation.snapshot().get("day", -1)), "personnel action should be recorded against the active shift", failures)
	_check(float(managed_worker.get("manager_trust", 0.0)) > trust_before, "sharing credit should increase authoritative manager trust", failures)
	_check(float(managed_worker.get("grievance", 100.0)) < grievance_before, "sharing credit should reduce the authoritative grievance", failures)
	_check(int(managed_worker.get("career_xp", 0)) > career_xp_before, "sharing credit should award persistent career XP", failures)
	_check(bool(simulation.snapshot().get("personnel_action_used", false)), "one filed action should lock personnel management globally for the shift", failures)
	_check(check_in_status != null and "FILED" in check_in_status.text, "dossier should confirm that the shift check-in was filed", failures)
	_check(share_credit != null and share_credit.disabled, "used personnel action should disable share credit", failures)
	_check(career_coaching != null and career_coaching.disabled, "used personnel action should disable career coaching", failures)
	_check(quota_pressure != null and quota_pressure.disabled, "used personnel action should disable quota pressure", failures)

	# The lock is flock-wide, not local to the hen who received the check-in.
	if routing_ui != null:
		routing_ui.set_focus(1)
	await process_frame
	var second_worker_before := _worker_snapshot(simulation.snapshot(), 1)
	_check(share_credit != null and share_credit.disabled, "personnel controls should stay disabled when another hen is selected", failures)
	if quota_pressure != null:
		quota_pressure.pressed.emit()
	await process_frame
	var second_worker_after := _worker_snapshot(simulation.snapshot(), 1)
	_check(StringName(second_worker_after.get("last_personnel_action", &"")) == StringName(second_worker_before.get("last_personnel_action", &"")), "global lock should reject a second hen's personnel action", failures)
	_check(float(second_worker_after.get("manager_trust", 0.0)) == float(second_worker_before.get("manager_trust", 0.0)), "rejected second action should not mutate the other hen", failures)
	if routing_ui != null:
		routing_ui.set_focus(0)
	await process_frame

	if assign_predator != null:
		assign_predator.pressed.emit()
	await process_frame
	var worker_zero := _worker_snapshot(simulation.snapshot(), 0)
	_check(StringName(worker_zero.get("assigned_lane", &"")) == &"predator_loss", "routing button should change authoritative worker assignment", failures)
	_check(assign_predator != null and assign_predator.theme_type_variation == &"SelectedChoiceButton", "selected tray should be visually persistent", failures)

	# Pull one file without bypassing the seated-only production invariant: this
	# test changes authoritative presence but advances only into WORKING, never to
	# an egg completion.
	simulation.set_worker_at_workstation(0, true)
	simulation.advance_tick()
	await process_frame
	worker_zero = _worker_snapshot(simulation.snapshot(), 0)
	var claim := worker_zero.get("current_claim", {}) as Dictionary
	_check(StringName(claim.get("lane", &"")) == &"predator_loss", "assigned hen should pull only from the selected tray", failures)
	_check(current_claim != null and "PREDATOR LOSS" in current_claim.text, "dossier should expose the current file and progress", failures)
	_check(predator_queue != null and "1" in predator_queue.text, "queue strip should react when a file enters peckwork", failures)

	var feedback := office.get("_workstation_feedback") as WorkstationFeedback
	if feedback != null:
		var stations: Dictionary = feedback.get("_stations_by_worker") as Dictionary
		var station = stations.get(0)
		_check(station != null and StringName(station.current_lane) == &"predator_loss", "workstation screen should inherit the active claim lane", failures)
	else:
		failures.append("workstation feedback controller should exist")

	if dossier != null:
		var dossier_rect := dossier.get_global_rect()
		_check(dossier_rect.position.x >= 0.0 and dossier_rect.end.x <= 1280.0, "routing dossier should fit the 1280-wide game stage", failures)
		_check(dossier_rect.position.y >= 0.0 and dossier_rect.end.y <= 666.0, "routing dossier should clear the bottom ticker", failures)

	await create_timer(0.4).timeout
	office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("CLAIM_ROUTING_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CLAIM_ROUTING_UI_TEST_PASSED lanes=3 dossier=career_relationships personnel=authoritative_global_lock screens=lane_colored")
	quit(0)


func _worker_snapshot(snapshot: Dictionary, worker_id: int) -> Dictionary:
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return worker
	return {}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
