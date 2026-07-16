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
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var routing_ui := office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	var queue_strip := office.find_child("PeckworkQueueStrip", true, false) as PanelContainer
	var dossier := office.find_child("PeckworkAssignmentDossier", true, false) as PanelContainer
	var nest_queue := office.find_child("Queue_nest_damage", true, false) as Label
	var predator_queue := office.find_child("Queue_predator_loss", true, false) as Label
	var appeals_queue := office.find_child("Queue_appeals", true, false) as Label
	var queue_contract_badge := office.find_child("RoutingQueueContractBadge", true, false) as Label
	var assign_auto := office.find_child("Assign_auto", true, false) as Button
	var assign_predator := office.find_child("Assign_predator_loss", true, false) as Button
	var current_claim := office.find_child("RoutingCurrentClaim", true, false) as Label
	var current_contract_badge := office.find_child("RoutingCurrentContractBadge", true, false) as Label
	var automation_hint := office.find_child("RoutingAutomationHint", true, false) as Label
	var worker_career := office.find_child("RoutingWorkerCareer", true, false) as Label
	var worker_profile := office.find_child("RoutingWorkerSpecialty", true, false) as Label
	var manager_trust := office.find_child("RoutingManagerTrust", true, false) as Label
	var grievance := office.find_child("RoutingGrievance", true, false) as Label
	var check_in_status := office.find_child("RoutingCheckInStatus", true, false) as Label
	var share_credit := office.find_child("PersonnelAction_share_credit", true, false) as Button
	var career_coaching := office.find_child("PersonnelAction_career_coaching", true, false) as Button
	var quota_pressure := office.find_child("PersonnelAction_quota_pressure", true, false) as Button
	var decision_host := office.find_child("ManagementDecisionHost", true, false) as Control

	# Normalize any resumable developer-local file to the authored title surface;
	# the production frame gate reads this presentation state directly.
	if campaign_ui != null:
		campaign_ui.show_title(false)
	await process_frame

	_check(routing_ui != null, "Office should install the routing interface", failures)
	_check(
		campaign_ui != null and campaign_ui.modal_state() == ProbationCampaignUI.VIEW_TITLE,
		"the fixture should begin on the blocking campaign title",
		failures,
	)
	_check(
		routing_ui != null and not routing_ui.is_visible_in_tree(),
		"routing should stay hidden behind the campaign title instead of competing with it",
		failures,
	)
	_check(
		queue_strip != null and not queue_strip.is_visible_in_tree(),
		"the overview queue should stay hidden while the campaign title blocks management",
		failures,
	)
	_check(dossier != null and not dossier.is_visible_in_tree(), "worker dossier should stay hidden behind the campaign title", failures)

	# Enter through the same New Campaign, Mabel prelude, directive, and optional
	# coach-skip flow used by a player. This proves the modal gate without making
	# the rest of this full-surface integration test depend on contextual tutorial
	# disclosure.
	await _start_normal_running_campaign(office, failures)
	if routing_ui != null:
		routing_ui.clear_focus()
	await process_frame

	_check(queue_strip != null and queue_strip.is_visible_in_tree(), "typed queue strip should remain visible in overview", failures)
	_check(nest_queue != null and "2" in nest_queue.text, "opening strip should show two Nest Damage files", failures)
	_check(predator_queue != null and "2" in predator_queue.text, "opening strip should show two Predator Loss files", failures)
	_check(appeals_queue != null and "2" in appeals_queue.text, "opening strip should show two Appeals files", failures)
	_check(queue_contract_badge != null and not queue_contract_badge.visible, "contract badge should stay hidden when routing trays contain only internal files", failures)
	_check(dossier != null and not dossier.is_visible_in_tree(), "worker dossier should stay hidden before a hen is selected", failures)

	if routing_ui != null:
		routing_ui.set_focus(0)
	await process_frame
	_check(dossier != null and dossier.is_visible_in_tree(), "selecting a hen should open her routing dossier", failures)
	_check(assign_auto != null and not assign_auto.disabled, "normal running play should expose live routing", failures)
	var opening_worker := _worker_snapshot(simulation.snapshot(), 0)
	_check(worker_career != null and worker_career.is_visible_in_tree(), "selected-hen dossier should expose career rank and XP", failures)
	_check(worker_career != null and String(opening_worker.get("career_title", "")) in worker_career.text, "career label should mirror the authoritative worker title", failures)
	_check(worker_career != null and "XP" in worker_career.text, "career label should make progression legible", failures)
	_check(worker_profile != null and worker_profile.is_visible_in_tree(), "selected-hen dossier should expose the career profile", failures)
	_check(worker_profile != null and String(opening_worker.get("career_profile_name", "")) in worker_profile.text, "profile label should mirror the authoritative worker profile", failures)
	_check(manager_trust != null and manager_trust.is_visible_in_tree() and "TRUST  %d" % int(roundf(float(opening_worker.get("manager_trust", -1.0)))) in manager_trust.text, "dossier should show authoritative manager trust", failures)
	_check(grievance != null and grievance.is_visible_in_tree() and "GRIEVANCE  %d" % int(roundf(float(opening_worker.get("grievance", -1.0)))) in grievance.text, "dossier should show authoritative grievance", failures)
	_check(check_in_status != null and "READY" in check_in_status.text, "personnel check-in should be ready in normal running play", failures)
	_check(share_credit != null and not share_credit.disabled, "share-credit action should be available in normal running play", failures)
	_check(career_coaching != null and not career_coaching.disabled, "career-coaching action should be available in normal running play", failures)
	_check(quota_pressure != null and not quota_pressure.disabled, "quota-pressure action should be available in normal running play", failures)
	_check(current_contract_badge != null and not current_contract_badge.visible, "current-file contract badge should stay hidden for ordinary peckwork", failures)

	# Worker dossiers consume effective Training Roost terms and expose individual
	# care state without embedding the original fixed 15 percent penalty.
	var training_snapshot := simulation.snapshot().duplicate(true)
	var training_workers := (training_snapshot.get("workers", []) as Array).duplicate(true)
	for worker_index in training_workers.size():
		var worker := (training_workers[worker_index] as Dictionary).duplicate(true)
		if int(worker.get("id", -1)) != 0:
			continue
		worker["cross_training_target"] = "appeals"
		worker["cross_training_work_multiplier"] = 0.95
		worker["state_label"] = "WELLNESS"
		training_workers[worker_index] = worker
		break
	training_snapshot["workers"] = training_workers
	training_snapshot["flock_care"] = {
		"training_terms": {
			"effective_work_multiplier": 0.95,
			"work_penalty_percent": 5,
			"coaching_xp_bonus": 4,
			"wage_bonus_cents": 100,
		},
	}
	if routing_ui != null:
		routing_ui.apply_snapshot(training_snapshot)
	await process_frame
	_check(worker_profile != null and _contains_all(worker_profile.text, ["training: appeals", "wellness nest"]), "the dossier should identify both the active training lane and physical recovery state", failures)
	_check(worker_profile != null and _contains_all(worker_profile.tooltip_text, ["5% slower", "+$1.00/day", "+4 career xp", "flock care", "morale", "stress", "fatigue"]), "the dossier tooltip should disclose authoritative training and individual care terms", failures)
	if routing_ui != null:
		routing_ui.apply_snapshot(simulation.snapshot())
	await process_frame

	# Selected-hen AUTO support is explicit and never inferred for applicants or
	# manual trays. The dossier consumes the frozen operations snapshot directly.
	var auto_snapshot := simulation.snapshot().duplicate(true)
	auto_snapshot["operations"] = _operations_fixture()
	if routing_ui != null:
		routing_ui.apply_snapshot(auto_snapshot)
		routing_ui.set_focus(0)
	await process_frame
	_check(automation_hint != null and _contains_all(automation_hint.text, ["it auto l2", "+6% pace", "120m grace"]), "an employed AUTO hen should show exact IT Coop speed and grace support", failures)
	_check(automation_hint != null and _contains_all(automation_hint.tooltip_text, ["auto is opt-in", "secondary accreditation", "never completes a file", "lays an egg"]), "AUTO support should explain opt-in scope, credential recognition, and the no-production boundary", failures)

	var manual_snapshot := auto_snapshot.duplicate(true)
	_set_worker_fixture(manual_snapshot, 0, {"assigned_lane": &"predator_loss", "assignment": &"predator_loss"})
	if routing_ui != null:
		routing_ui.apply_snapshot(manual_snapshot)
	await process_frame
	_check(automation_hint != null and _contains_all(automation_hint.text, ["manual override", "it auto support off"]), "a manual tray should be visibly identified as an explicit IT AUTO override", failures)
	_check(automation_hint != null and _contains_all(automation_hint.tooltip_text, ["explicit override", "do not apply"]), "manual routing should explain that IT pace and grace are not active", failures)

	var applicant_snapshot := auto_snapshot.duplicate(true)
	_set_worker_fixture(applicant_snapshot, 0, {"employed": false, "assigned_lane": &"auto", "assignment": &"auto"})
	if routing_ui != null:
		routing_ui.apply_snapshot(applicant_snapshot)
	await process_frame
	_check(automation_hint != null and _contains_all(automation_hint.text, ["applicant file", "no live auto support"]), "applicant dossiers must never advertise live IT AUTO support", failures)
	_check(assign_auto != null and assign_auto.disabled, "applicants cannot receive live tray routing", failures)
	if routing_ui != null:
		routing_ui.apply_snapshot(simulation.snapshot())
		routing_ui.set_focus(0)
	await process_frame

	# Canonical Farm Mutual metadata should surface in both routing contexts while
	# preserving the queue strip and dossier footprints.
	var queue_rect_before := queue_strip.get_global_rect() if queue_strip != null else Rect2()
	var dossier_rect_before := dossier.get_global_rect() if dossier != null else Rect2()
	var contract_snapshot := simulation.snapshot().duplicate(true)
	_apply_contract_fixture(contract_snapshot, true, "10:20 AM")
	if routing_ui != null:
		routing_ui.apply_snapshot(contract_snapshot)
	await process_frame
	_check(queue_contract_badge != null and queue_contract_badge.is_visible_in_tree(), "contracted queue items should reveal a compact routing badge", failures)
	_check(queue_contract_badge != null and "CONTRACT RUSH" in queue_contract_badge.text, "rush queue badge should identify CONTRACT RUSH work", failures)
	_check(queue_contract_badge != null and "10:20 AM" in queue_contract_badge.text, "rush queue badge should disclose its authored deadline", failures)
	_check(queue_contract_badge != null and "Disclosed deadline: 10:20 AM" in queue_contract_badge.tooltip_text, "rush queue tooltip should repeat the disclosed deadline", failures)
	_check(current_contract_badge != null and current_contract_badge.is_visible_in_tree(), "contracted current claims should reveal a compact binder badge", failures)
	_check(current_contract_badge != null and "CONTRACT RUSH" in current_contract_badge.text, "active rush claim should identify CONTRACT RUSH work", failures)
	_check(current_contract_badge != null and "10:20 AM" in current_contract_badge.text, "active rush claim should disclose its authored deadline", failures)
	_check(queue_strip != null and queue_strip.get_global_rect().is_equal_approx(queue_rect_before), "contract queue badge should not resize or move the routing strip", failures)
	_check(dossier != null and dossier.get_global_rect().is_equal_approx(dossier_rect_before), "contract current-file badge should not resize or move the dossier", failures)

	var binder_snapshot := simulation.snapshot().duplicate(true)
	_apply_contract_fixture(binder_snapshot, false, "4:15 PM")
	if routing_ui != null:
		routing_ui.apply_snapshot(binder_snapshot)
	await process_frame
	_check(queue_contract_badge != null and "MUTUAL BINDER" in queue_contract_badge.text, "non-rush contract queues should use the mutual-binder badge", failures)
	_check(queue_contract_badge != null and "4:15 PM" in queue_contract_badge.text, "mutual-binder queue badge should disclose its deadline", failures)
	_check(current_contract_badge != null and "MUTUAL BINDER" in current_contract_badge.text, "non-rush current claims should use the mutual-binder badge", failures)
	if routing_ui != null:
		routing_ui.apply_snapshot(simulation.snapshot())
	await process_frame
	_check(queue_contract_badge != null and not queue_contract_badge.visible, "contract queue badge should clear when contracted folders leave the trays", failures)
	_check(current_contract_badge != null and not current_contract_badge.visible, "current-file contract badge should clear with the contracted claim", failures)

	_check(decision_host != null and not decision_host.is_visible_in_tree(), "normal running play should keep the directive surface retired", failures)
	_check(assign_auto != null and not assign_auto.disabled, "routing should unlock during the running shift", failures)
	_check(check_in_status != null and "READY" in check_in_status.text, "personnel check-in should become ready during the running shift", failures)
	_check(share_credit != null and not share_credit.disabled, "share-credit action should unlock during the running shift", failures)
	_check(career_coaching != null and not career_coaching.disabled, "career-coaching action should unlock during the running shift", failures)
	_check(quota_pressure != null and not quota_pressure.disabled, "quota-pressure action should unlock during the running shift", failures)

	# A Rooster Office allowance is flock-wide but not a first-action global lock:
	# the filed hen stays locked while a second employed hen can use the remainder.
	var multi_action_snapshot := simulation.snapshot().duplicate(true)
	var multi_day := int(multi_action_snapshot.get("day", 1))
	multi_action_snapshot["personnel_action_available"] = true
	multi_action_snapshot["personnel_action_used"] = true
	multi_action_snapshot["personnel_action_status"] = {
		"available": true,
		"used_today": true,
		"day": multi_day,
		"reason": "",
		"limit": 2,
		"used": 1,
		"remaining": 1,
		"actions": [{
			"day": multi_day,
			"worker_id": 0,
			"worker_name": "Mabel",
			"action_id": &"share_credit",
			"outcome": "Mabel already received today's check-in.",
		}],
		"last_action": {
			"day": multi_day,
			"worker_id": 0,
			"worker_name": "Mabel",
			"action_id": &"share_credit",
			"outcome": "Mabel already received today's check-in.",
		},
	}
	if routing_ui != null:
		routing_ui.apply_snapshot(multi_action_snapshot)
		routing_ui.set_focus(0)
	await process_frame
	_check(check_in_status != null and _contains_all(check_in_status.text, ["hen filed", "1 of 2"]), "the filed hen should remain individually locked under a larger allowance", failures)
	_check(share_credit != null and share_credit.disabled, "a hen cannot receive a second personnel action in the same shift", failures)
	if routing_ui != null:
		routing_ui.set_focus(1)
	await process_frame
	_check(check_in_status != null and _contains_all(check_in_status.text, ["check-in ready", "1 of 2", "1 left"]), "another hen should see the exact remaining Rooster Office allowance", failures)
	_check(share_credit != null and not share_credit.disabled, "the first filed action must not globally lock a larger Rooster Office allowance", failures)
	if routing_ui != null:
		routing_ui.apply_snapshot(simulation.snapshot())
		routing_ui.set_focus(0)
	await process_frame

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
	print("CLAIM_ROUTING_UI_TEST_PASSED lanes=3 dossier=auto_support personnel=authoritative_allowance screens=lane_colored")
	quit(0)


func _worker_snapshot(snapshot: Dictionary, worker_id: int) -> Dictionary:
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return worker
	return {}


func _start_normal_running_campaign(office: Office, failures: Array[String]) -> void:
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var routing_ui := office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	var simulation := office.get("_simulation") as DepartmentSimulation
	if campaign_ui != null:
		# Isolate the fixture from any resumable local file without bypassing the
		# production New Campaign signal route.
		campaign_ui.show_title(false)
	await process_frame
	_check(
		_press(office.find_child("NewCampaignButton", true, false) as Button),
		"the regression fixture should open a clean campaign through New Campaign",
		failures,
	)
	await process_frame
	await process_frame
	_check(
		campaign_ui != null and not campaign_ui.is_modal_open(),
		"New Campaign should retire the title before the authored first-hen prelude",
		failures,
	)
	_check(
		_press(office.find_child("FirstClutchReturnToHen", true, false) as Button),
		"the regression fixture should open Mabel's pre-policy file",
		failures,
	)
	await process_frame
	await process_frame

	var decision_host := office.find_child("ManagementDecisionHost", true, false) as Control
	var assign_auto := office.find_child("Assign_auto", true, false) as Button
	var share_credit := office.find_child("PersonnelAction_share_credit", true, false) as Button
	_check(
		decision_host != null and decision_host.is_visible_in_tree(),
		"opening Mabel's file should reveal the blocking morning directive",
		failures,
	)
	_check(
		routing_ui != null and not routing_ui.is_visible_in_tree(),
		"routing should also stay hidden behind the blocking morning directive",
		failures,
	)
	_check(assign_auto != null and assign_auto.disabled, "the hidden routing action should remain authoritatively locked before policy", failures)
	_check(share_credit != null and share_credit.disabled, "the hidden personnel action should remain authoritatively locked before policy", failures)

	_check(
		_press(office.find_child("DecisionOption_shell_assurance", true, false) as Button),
		"Shell Assurance should be selectable through the real directive controls",
		failures,
	)
	_check(
		_press(office.find_child("ConfirmDecisionButton", true, false) as Button),
		"the selected opening directive should start the authoritative shift",
		failures,
	)
	await process_frame
	await process_frame
	_check(
		simulation != null and simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING,
		"the campaign fixture should reach a real running shift",
		failures,
	)

	var skip := office.find_child("FirstClutchSkip", true, false) as Button
	_check(skip != null and skip.is_visible_in_tree(), "the optional coach should expose Skip once the policy is filed", failures)
	_check(_press(skip), "the fixture should dismiss contextual disclosure through the coach's real Skip action", failures)
	await process_frame
	await process_frame
	_check(bool(office.first_clutch_snapshot().get("dismissed", false)), "Skip should place the campaign in normal full-surface play", failures)
	_check(routing_ui != null and routing_ui.is_visible_in_tree(), "normal running play should reveal the routing interface", failures)


func _apply_contract_fixture(snapshot: Dictionary, rush: bool, deadline: String) -> void:
	var queue_items := (snapshot.get("claim_queue_items", {}) as Dictionary).duplicate(true)
	var nest_items := (queue_items.get(&"nest_damage", []) as Array).duplicate(true)
	if nest_items.is_empty():
		return
	var contract_claim := (nest_items[0] as Dictionary).duplicate(true)
	contract_claim["market_contract"] = true
	contract_claim["market_contract_id"] = "FM-0001-RUSH_ADJUSTER"
	contract_claim["market_contract_offer_id"] = "rush_adjuster"
	contract_claim["market_contract_name"] = "RUSH ADJUSTER BINDER"
	contract_claim["market_contract_rush"] = rush
	contract_claim["market_contract_deadline_time"] = deadline
	contract_claim["minutes_until_deadline"] = 35
	nest_items[0] = contract_claim
	queue_items[&"nest_damage"] = nest_items
	snapshot["claim_queue_items"] = queue_items

	var workers := (snapshot.get("workers", []) as Array).duplicate(true)
	for worker_index in workers.size():
		var worker := (workers[worker_index] as Dictionary).duplicate(true)
		if int(worker.get("id", -1)) != 0:
			continue
		worker["current_claim"] = contract_claim.duplicate(true)
		worker["progress"] = 37
		workers[worker_index] = worker
		break
	snapshot["workers"] = workers


func _set_worker_fixture(snapshot: Dictionary, worker_id: int, values: Dictionary) -> void:
	var workers := (snapshot.get("workers", []) as Array).duplicate(true)
	for worker_index in workers.size():
		var worker := (workers[worker_index] as Dictionary).duplicate(true)
		if int(worker.get("id", -1)) != worker_id:
			continue
		for key in values:
			worker[key] = values[key]
		workers[worker_index] = worker
		break
	snapshot["workers"] = workers


func _operations_fixture() -> Dictionary:
	return {
		"version": 1,
		"rooster_office_level": 2,
		"it_coop_level": 2,
		"supervision": {
			"action_limit": 3,
			"actions_used": 1,
			"actions_remaining": 2,
			"actions": [],
			"supervisor_payroll_cents": 800,
			"surveillance_grievance_millipoints": 1250,
			"surveillance_stress_millipoints": 1000,
			"surveillance_solidarity_millipoints": 1000,
		},
		"automation": {
			"enabled": true,
			"work_basis_points": 10600,
			"work_multiplier": 1.06,
			"specialty_grace_minutes": 120,
			"recognizes_secondary_specialties": true,
			"compliance_exposure_millipoints": 1800,
			"ledger_patch_cost_cents": 2600,
		},
	}


func _contains_all(copy: String, fragments: Array[String]) -> bool:
	var normalized := copy.to_lower()
	for fragment in fragments:
		if not normalized.contains(fragment.to_lower()):
			return false
	return true


func _press(button: Button) -> bool:
	if button == null or button.disabled:
		return false
	button.pressed.emit()
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
