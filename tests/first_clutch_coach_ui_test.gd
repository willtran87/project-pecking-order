extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	var routing_ui := PeckworkRoutingUI.new()
	root.add_child(routing_ui)
	await process_frame
	await process_frame

	var coach := routing_ui.find_child("FirstClutchCoach", true, false) as PanelContainer
	var progress := routing_ui.find_child("FirstClutchProgress", true, false) as Label
	var title := routing_ui.find_child("FirstClutchActionTitle", true, false) as Label
	var body := routing_ui.find_child("FirstClutchActionBody", true, false) as Label
	var return_to_hen := routing_ui.find_child("FirstClutchReturnToHen", true, false) as Button
	var skip := routing_ui.find_child("FirstClutchSkip", true, false) as Button
	var queue := routing_ui.find_child("PeckworkQueueStrip", true, false) as PanelContainer
	var compact_queue := routing_ui.find_child("RoutingQueueCompactSummary", true, false) as Label
	var assign_auto := routing_ui.find_child("Assign_auto", true, false) as Button
	var assign_appeals := routing_ui.find_child("Assign_appeals", true, false) as Button
	var assignments := routing_ui.find_child("RoutingAssignments", true, false) as GridContainer
	var personnel_actions := routing_ui.find_child("PersonnelActions", true, false) as VBoxContainer
	var personnel_status := routing_ui.find_child("RoutingPersonnelStatus", true, false) as HBoxContainer
	var assist_row := routing_ui.find_child("RoutingAssistRow", true, false) as HBoxContainer
	var details := routing_ui.find_child("RoutingDetailsToggle", true, false) as Button
	var worker_career := routing_ui.find_child("RoutingWorkerCareer", true, false) as Label
	var manager_trust := routing_ui.find_child("RoutingManagerTrust", true, false) as Label
	var grievance := routing_ui.find_child("RoutingGrievance", true, false) as Label
	var share_credit := routing_ui.find_child("PersonnelAction_share_credit", true, false) as Button
	var career_coach := routing_ui.find_child("PersonnelAction_career_coaching", true, false) as Button
	var priority_peck := routing_ui.find_child("PeckAssistButton", true, false) as Button

	_check(coach != null and not coach.visible, "first-clutch coach should default hidden", failures)
	_check(progress != null and title != null and body != null, "coach should expose compact progress and current-action copy", failures)
	_check(return_to_hen != null and skip != null, "coach should expose its conditional recovery action and Skip", failures)
	_check(return_to_hen != null and not return_to_hen.visible, "return action should default hidden without a bound target mismatch", failures)
	if coach != null and skip != null:
		var interactive := _interactive_descendants(coach)
		_check(interactive.size() == 1 and interactive[0] == skip, "only Skip should intercept input inside the coach card", failures)

	routing_ui.apply_snapshot(_fixture_snapshot())
	var prelude_observed := {"focus_worker": -1}
	routing_ui.first_clutch_focus_requested.connect(
		func(worker_id: int) -> void: prelude_observed["focus_worker"] = worker_id
	)
	routing_ui.apply_first_clutch({
		"visible": true,
		"progress": 0,
		"total": 5,
		"eyebrow": "FIRST CLUTCH  //  ORIENTATION",
		"title": "Open Mabel's first file",
		"body": "Appeals are mine. The farmer usually remembers the basket, not the beak.",
		"stage": &"inspect",
		"target_worker_id": 0,
		"pre_policy": true,
		"can_skip": false,
	})
	await process_frame
	_check(coach != null and coach.is_visible_in_tree(), "pre-policy Mabel orientation should reveal the existing coach card", failures)
	_check(progress != null and progress.text == "FIRST CLUTCH  //  ORIENTATION", "pre-policy card should use a character-led orientation eyebrow", failures)
	_check(title != null and title.text == "OPEN MABEL'S FIRST FILE", "pre-policy card should name the authored first hen", failures)
	_check(body != null and "remembers the basket" in body.text, "pre-policy card should retain Mabel's first-person point of view", failures)
	_check(return_to_hen != null and return_to_hen.visible and "OPEN MABEL'S FILE" in return_to_hen.text, "pre-policy card should expose one explicit file-opening action", failures)
	_check(skip != null and not skip.visible, "pre-policy beat should not expose the later coach Skip action", failures)
	if coach != null and return_to_hen != null:
		var prelude_actions := _interactive_descendants(coach)
		_check(prelude_actions.size() == 1 and prelude_actions[0] == return_to_hen, "only Open Mabel's File should intercept the pre-policy card", failures)
	if return_to_hen != null:
		return_to_hen.pressed.emit()
	await process_frame
	_check(int(prelude_observed["focus_worker"]) == 0, "pre-policy action should emit Mabel's exact stable worker ID", failures)

	routing_ui.set_focus(0)
	await process_frame
	if assign_auto != null:
		assign_auto.grab_focus()
	await process_frame
	var focus_before := root.gui_get_focus_owner()
	routing_ui.apply_first_clutch({
		"visible": true,
		"progress": 0,
		"total": 5,
		"title": "Match Mabel's tray",
		"body": "Choose Appeals, the specialty printed in her dossier.",
		"stage": &"specialty_route",
		"target_worker_id": 0,
		"specialty_name": "APPEALS",
	})
	await process_frame
	_check(coach != null and coach.is_visible_in_tree(), "visible coach data should reveal the card", failures)
	_check(progress != null and progress.text == "FIRST CLUTCH  0 / 5", "coach should show exact zero-of-five progress", failures)
	_check(title != null and title.text == "MATCH MABEL'S TRAY", "coach should show the current action title", failures)
	_check(body != null and "Choose Appeals" in body.text, "coach should show the current action body", failures)
	_check(body != null and not body.visible, "an open coached dossier should collapse duplicate coach body copy", failures)
	_check(assignments != null and assignments.is_visible_in_tree(), "route stage should expose routing controls", failures)
	_check(queue != null and queue.is_visible_in_tree(), "route stage should expose its supporting queue counts", failures)
	_check(personnel_actions != null and not personnel_actions.visible, "route stage should hide untaught personnel actions", failures)
	_check(priority_peck != null and not priority_peck.visible, "route stage should hide the later Priority Peck action", failures)
	_check(details != null and details.is_visible_in_tree(), "the compact dossier should retain an accessible Details disclosure", failures)
	_check(worker_career != null and not worker_career.visible, "advanced career copy should default collapsed", failures)
	_check(assign_appeals != null and bool(assign_appeals.get_meta("first_clutch_cue", false)), "route stage should cue the exact requested lane", failures)
	_check(assign_auto != null and not bool(assign_auto.get_meta("first_clutch_cue", false)), "route stage should not cue an unrelated lane", failures)
	_check(root.gui_get_focus_owner() == focus_before, "applying a dossier cue must not steal keyboard focus", failures)
	var route_presentation := routing_ui.first_clutch_presentation_state()
	_check(StringName(route_presentation.get("stage", &"")) == &"specialty_route", "presentation metadata should expose the normalized route stage", failures)
	_check(bool(route_presentation.get("routing_visible", false)) and not bool(route_presentation.get("check_in_visible", true)), "presentation metadata should mirror exact route disclosure", failures)
	_check(String(route_presentation.get("primary_action_node", "")) == "Assign_appeals", "metadata should identify the one visually prominent coached action", failures)

	var observed := {"skip": 0, "focus_worker": -1}
	routing_ui.first_clutch_focus_requested.connect(
		func(worker_id: int) -> void: observed["focus_worker"] = worker_id
	)
	routing_ui.set_focus(1)
	await process_frame
	_check(return_to_hen != null and return_to_hen.visible, "moving away from a bound tutorial hen should reveal recovery", failures)
	_check(return_to_hen != null and return_to_hen.text == "RETURN TO MABEL", "recovery should name the bound tutorial hen", failures)
	_check(assign_appeals != null and not bool(assign_appeals.get_meta("first_clutch_cue", false)), "moving away should clear dossier-local cues", failures)
	if coach != null and return_to_hen != null and skip != null:
		var recovery_actions := _interactive_descendants(coach)
		_check(recovery_actions.size() == 2 and return_to_hen in recovery_actions and skip in recovery_actions, "only visible recovery and Skip actions should intercept coach input", failures)
	if return_to_hen != null:
		return_to_hen.pressed.emit()
	await process_frame
	_check(int(observed["focus_worker"]) == 0, "recovery should request the exact bound worker", failures)
	_check(routing_ui.focused_worker_id() == 1, "recovery should emit intent without mutating camera focus", failures)
	routing_ui.set_focus(0)
	await process_frame
	_check(return_to_hen != null and not return_to_hen.visible, "recovery should retire once the bound hen is focused", failures)
	_check(assign_appeals != null and bool(assign_appeals.get_meta("first_clutch_cue", false)), "returning to the bound hen should restore the exact dossier cue", failures)
	if details != null:
		details.pressed.emit()
	await process_frame
	_check(worker_career != null and worker_career.is_visible_in_tree(), "Details should reveal career progression without changing tutorial stage", failures)
	_check(manager_trust != null and manager_trust.is_visible_in_tree(), "Details should reveal manager trust", failures)
	_check(grievance != null and grievance.is_visible_in_tree(), "Details should reveal grievance state", failures)
	if details != null:
		details.pressed.emit()
	await process_frame
	if assign_auto != null:
		assign_auto.grab_focus()
	await process_frame
	_check(root.gui_get_focus_owner() == assign_auto, "keyboard focus fixture should begin on a visible route action", failures)

	routing_ui.apply_first_clutch({
		"visible": true,
		"progress": 2,
		"total": 5,
		"title": "File one check-in",
		"body": "The profile-fit action is highlighted; every filing is permanent.",
		"stage": &"check_in",
		"target_worker_id": 0,
		"preferred_action": &"share_credit",
	})
	await process_frame
	await process_frame
	_check(assignments != null and not assignments.visible, "check-in stage should retire routing controls", failures)
	_check(personnel_actions != null and personnel_actions.is_visible_in_tree(), "check-in stage should expose personnel actions", failures)
	_check(personnel_status != null and personnel_status.is_visible_in_tree(), "check-in stage should expose the filing status", failures)
	_check(assist_row != null and not assist_row.visible, "check-in stage should hide claim-timing controls", failures)
	_check(queue != null and not queue.visible, "check-in stage should hide unrelated queue chrome", failures)
	_check(root.gui_get_focus_owner() == share_credit, "stage disclosure should move focus from a hidden route action to the coached check-in", failures)
	_check(share_credit != null and bool(share_credit.get_meta("first_clutch_cue", false)), "check-in stage should cue the exact profile-fit action", failures)
	_check(career_coach != null and not bool(career_coach.get_meta("first_clutch_cue", false)), "check-in stage should clear unrelated personnel cues", failures)
	_check(assign_appeals != null and not bool(assign_appeals.get_meta("first_clutch_cue", false)), "changing stages should restore the previous route control", failures)

	routing_ui.apply_first_clutch({
		"visible": true,
		"progress": 3,
		"total": 5,
		"title": "Stamp the gold window",
		"body": "Run the clock until this claim enters the gold band, then press E.",
		"stage": &"priority_peck",
		"target_worker_id": 0,
	})
	await process_frame
	_check(assignments != null and not assignments.visible, "Priority Peck stage should keep routing controls retired", failures)
	_check(personnel_actions != null and not personnel_actions.visible, "Priority Peck stage should retire personnel actions", failures)
	_check(priority_peck != null and priority_peck.is_visible_in_tree(), "Priority Peck stage should expose the timing action", failures)
	_check(queue != null and not queue.visible, "Priority Peck stage should keep the queue strip out of the timing task", failures)
	_check(priority_peck != null and bool(priority_peck.get_meta("first_clutch_cue", false)), "Priority Peck stage should cue the exact stamp even while it is locked", failures)
	_check(share_credit != null and not bool(share_credit.get_meta("first_clutch_cue", false)), "Priority Peck stage should restore personnel styling", failures)

	routing_ui.apply_first_clutch({
		"visible": true,
		"progress": 3,
		"total": 5,
		"title": "Resume the clock",
		"body": "Run at 1x until the claim enters the gold band.",
		"stage": &"priority_peck",
		"target_worker_id": 0,
		"resume_required": true,
	})
	await process_frame
	_check(priority_peck != null and priority_peck.disabled, "fixture should keep Priority Peck unavailable while the clock step is pending", failures)
	_check(priority_peck != null and not bool(priority_peck.get_meta("first_clutch_cue", false)), "paused Priority step should not highlight the disabled Peck action", failures)

	routing_ui.apply_first_clutch({
		"visible": true,
		"progress": 3,
		"total": 5,
		"title": "Stamp the gold window",
		"body": "Press E when this claim enters the gold band.",
		"stage": &"priority_peck",
		"target_worker_id": 0,
		"resume_required": false,
	})
	await process_frame
	_check(priority_peck != null and bool(priority_peck.get_meta("first_clutch_cue", false)), "explicitly resumed Priority step should restore the Peck cue", failures)

	routing_ui.first_clutch_skip_requested.connect(func() -> void: observed["skip"] = int(observed["skip"]) + 1)
	if skip != null:
		skip.pressed.emit()
	await process_frame
	_check(int(observed["skip"]) == 1, "Skip should emit one presentation intent without mutating coach state", failures)
	_check(coach != null and coach.visible, "the caller should remain authoritative over coach visibility after Skip", failures)

	routing_ui.set_focus(1)
	await process_frame
	_check(return_to_hen != null and return_to_hen.visible, "recovery should remain available before narrow-layout verification", failures)
	routing_ui.set_anchors_preset(Control.PRESET_TOP_LEFT)
	routing_ui.size = Vector2(390.0, 844.0)
	routing_ui.call("_apply_first_clutch_layout")
	await process_frame
	await process_frame
	if coach != null and queue != null:
		var coach_rect := coach.get_global_rect()
		var queue_rect := queue.get_global_rect()
		_check(coach_rect.position.x >= 0.0 and coach_rect.end.x <= 390.0, "narrow coach should remain horizontally contained", failures)
		_check(coach_rect.position.y >= queue_rect.end.y, "coach should remain below the queue strip at narrow widths", failures)
		if return_to_hen != null:
			var return_rect := return_to_hen.get_global_rect()
			_check(
				return_rect.position.x >= coach_rect.position.x
				and return_rect.end.x <= coach_rect.end.x
				and return_rect.position.y >= coach_rect.position.y
				and return_rect.end.y <= coach_rect.end.y,
				"visible recovery action should stay inside the narrow coach card",
				failures,
			)

	if skip != null:
		skip.grab_focus()
	await process_frame
	_check(root.gui_get_focus_owner() == skip, "completion focus fixture should begin on visible Skip", failures)
	routing_ui.apply_first_clutch({
		"visible": true,
		"progress": 5,
		"total": 5,
		"stage": &"complete",
		"title": "First clutch filed",
		"body": "Every control stays live.",
		"target_worker_id": 0,
		"can_skip": false,
	})
	await process_frame
	await process_frame
	_check(skip != null and not skip.visible, "completed coach payload should retire the optional Skip control", failures)
	_check(
		return_to_hen != null
		and return_to_hen.is_visible_in_tree()
		and root.gui_get_focus_owner() == return_to_hen,
		"hiding focused Skip away from the coached hen should move focus to the visible recovery action",
		failures,
	)

	routing_ui.set_first_clutch_stage(&"delivery", {
		"progress": 4,
		"total": 5,
		"title": "Follow the assisted file",
		"body": "Watch the same claim reach the farmer basket.",
		"target_worker_id": 0,
	})
	routing_ui.set_focus(0)
	await process_frame
	_check(assignments != null and not assignments.visible, "delivery stage should not reintroduce routing actions", failures)
	_check(personnel_actions != null and not personnel_actions.visible, "delivery stage should not reintroduce personnel actions", failures)
	_check(priority_peck != null and not priority_peck.visible, "delivery stage should retire the completed Priority Peck action", failures)
	_check(assist_row != null and assist_row.is_visible_in_tree(), "delivery stage should retain compact claim-following context", failures)
	_check(skip != null and skip.is_visible_in_tree(), "delivery should preserve Skip until the authoritative payload retires it", failures)
	if skip != null:
		skip.grab_focus()
	await process_frame
	_check(root.gui_get_focus_owner() == skip, "reinvestment focus fixture should begin on visible Skip", failures)
	routing_ui.apply_first_clutch({
		"visible": true,
		"progress": 5,
		"total": 5,
		"stage": &"reinvestment",
		"title": "Reinvest the first egg",
		"body": "Choose one desk requisition or bank the Feed Fund.",
		"target_worker_id": 0,
		"can_skip": false,
	})
	await process_frame
	await process_frame
	_check(skip != null and not skip.visible, "reinvestment should retire Skip", failures)
	_check(
		details != null
		and details.is_visible_in_tree()
		and root.gui_get_focus_owner() == details,
		"hiding focused Skip on the coached hen should move focus to visible dossier Details",
		failures,
	)

	routing_ui.set_first_clutch_stage(&"normal")
	await process_frame
	_check(coach != null and not coach.visible, "caller-visible false should hide the coach cleanly for modal states", failures)
	_check(priority_peck != null and not bool(priority_peck.get_meta("first_clutch_cue", false)), "hiding the coach should clear its final dossier cue", failures)
	_check(queue != null and queue.is_visible_in_tree(), "normal play should restore the queue strip", failures)
	_check(assignments != null and assignments.is_visible_in_tree(), "normal play should restore every routing action", failures)
	_check(personnel_actions != null and personnel_actions.is_visible_in_tree(), "normal play should restore every personnel action", failures)
	_check(priority_peck != null and priority_peck.is_visible_in_tree(), "normal play should restore Priority Peck", failures)
	_check(compact_queue != null and compact_queue.is_visible_in_tree(), "narrow normal play should collapse queue detail into one summary chip", failures)
	if queue != null:
		var normal_queue_rect := queue.get_global_rect()
		_check(normal_queue_rect.position.x >= 0.0 and normal_queue_rect.end.x <= 390.0, "compact queue chip should remain inside a narrow viewport", failures)
	var normal_presentation := routing_ui.first_clutch_presentation_state()
	_check(not bool(normal_presentation.get("active", true)), "normal API state should retire progressive disclosure", failures)
	_check(bool(normal_presentation.get("routing_visible", false)) and bool(normal_presentation.get("check_in_visible", false)), "normal metadata should prove all management categories are restored", failures)

	routing_ui.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FIRST_CLUTCH_COACH_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FIRST_CLUTCH_COACH_UI_TEST_PASSED card=compact disclosure=stage_exact details=accessible normal=restored cues=exact recovery=intent focus=preserved")
	quit(0)


func _fixture_snapshot() -> Dictionary:
	return {
		"shift_phase": DepartmentSimulation.ShiftPhase.RUNNING,
		"claim_queue_counts": {
			&"nest_damage": 2,
			&"predator_loss": 2,
			&"appeals": 2,
		},
		"claim_queue_overdue_counts": {},
		"overdue_claims": 0,
		"personnel_action_available": true,
		"personnel_action_used": false,
		"personnel_action_status": {"reason": "Choose one check-in."},
		"spendable_fund_cents": 5000,
		"personnel_catalog": [
			{"id": &"share_credit", "short_name": "SHARE CREDIT", "cost_cents": 700},
			{"id": &"career_coaching", "short_name": "CAREER COACH", "cost_cents": 400},
			{"id": &"quota_pressure", "short_name": "APPLY PRESSURE", "cost_cents": 0},
		],
		"workers": [{
			"id": 0,
			"name": "Mabel",
			"specialty": &"appeals",
			"assignment": &"auto",
			"career_title": "Junior Claims Hen",
			"career_xp": 0,
			"career_xp_next": 18,
			"career_profile_name": "Credit Conscious",
			"career_profile_description": "Recognition matters.",
			"preferred_personnel_action": &"share_credit",
			"manager_trust": 50.0,
			"grievance": 5.0,
			"estimated_crack_risk": 0.17,
			"current_claim": {},
			"peck_assist": {
				"available": false,
				"window_state": &"not_ready",
				"remaining": 3,
				"limit": 3,
				"window_start": 28.0,
				"reason": "Build the claim rhythm to 28% before stamping.",
			},
		}, {
			"id": 1,
			"name": "Penny",
			"specialty": &"nest_damage",
			"assignment": &"auto",
			"career_title": "Junior Claims Hen",
			"career_xp": 0,
			"career_xp_next": 18,
			"career_profile_name": "Steady Scratcher",
			"career_profile_description": "Routine work builds confidence.",
			"preferred_personnel_action": &"career_coaching",
			"manager_trust": 50.0,
			"grievance": 5.0,
			"estimated_crack_risk": 0.12,
			"current_claim": {},
			"peck_assist": {
				"available": false,
				"window_state": &"not_ready",
				"remaining": 3,
				"limit": 3,
				"window_start": 28.0,
				"reason": "Build the claim rhythm to 28% before stamping.",
			},
		}],
	}


func _interactive_descendants(parent: Control) -> Array[Control]:
	var result: Array[Control] = []
	for child in parent.find_children("*", "Control", true, false):
		var control := child as Control
		if control != null and control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			result.append(control)
	return result


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
