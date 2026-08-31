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
	var clock := office.get("_clock") as SimulationClock
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var routing_ui := office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	var dialogue_ui := office.find_child("CharacterDialogueUI", true, false) as CharacterDialogueUI
	var dossier := office.find_child("PeckworkAssignmentDossier", true, false) as PanelContainer
	var assist_button := office.find_child("PeckAssistButton", true, false) as Button
	var intent_button := office.find_child("HenIntentAction", true, false) as Button
	var claim_label := office.find_child("RoutingCurrentClaim", true, false) as Label
	var claim_phase_icon := office.find_child("RoutingClaimPhaseIcon", true, false) as TextureRect
	var claim_phase_progress := office.find_child("RoutingClaimPhaseProgress", true, false) as Label
	var claim_detail := office.find_child("RoutingClaimDetail", true, false) as Control
	var progress_track := office.find_child("RoutingClaimProgressTrack", true, false) as Control
	var gold_band := office.find_child("PriorityPeckGoldBand", true, false) as ColorRect
	var ideal_marker := office.find_child("PriorityPeckIdealMarker", true, false) as ColorRect
	var timing_label := office.find_child("PriorityPeckTimingLabel", true, false) as Label
	var intent_link := office.find_child("PriorityPeckIntentLink", true, false) as Control
	var assist_receipt := office.find_child("RoutingAutomationHint", true, false) as Label

	# Normalize any resumable developer-local file to the authored title surface so
	# this integration test exercises the same blocking presentation every run.
	if campaign_ui != null:
		campaign_ui.show_title(false)
	await process_frame

	_check(simulation != null, "Office should expose its authoritative simulation", failures)
	_check(clock != null, "Office should expose its simulation clock", failures)
	_check(routing_ui != null, "Office should install the Peckwork routing interface", failures)
	_check(dialogue_ui != null, "Office should install the character dialogue input context", failures)
	_check(dossier != null, "routing interface should build the selected-hen dossier", failures)
	_check(assist_button != null, "selected-hen dossier should contain a Priority Peck button", failures)
	_check(
		progress_track != null and gold_band != null and ideal_marker != null and timing_label != null,
		"selected-hen dossier should build the visible Priority Peck timing guide",
		failures,
	)
	_check(
		intent_link != null,
		"selected-hen dossier should build the icon-to-timing-lane connection cue",
		failures,
	)
	_check(
		campaign_ui != null and campaign_ui.modal_state() == ProbationCampaignUI.VIEW_TITLE,
		"the fixture should begin on the blocking campaign title",
		failures,
	)
	_check(
		routing_ui != null and not routing_ui.is_visible_in_tree(),
		"Peckwork should stay hidden behind the campaign title",
		failures,
	)

	# Even a programmatic focus change cannot leak dossier actions through the
	# title. The controls remain instantiated and authoritatively disabled for the
	# pre-policy state, but the blocking surface owns presentation.
	if routing_ui != null:
		routing_ui.set_focus(0)
	await process_frame
	_check(dossier != null and not dossier.is_visible_in_tree(), "a focused dossier should remain hidden behind the campaign title", failures)
	_check(assist_button != null and not assist_button.is_visible_in_tree(), "Priority Peck should not leak through the campaign title", failures)
	_check(assist_button != null and assist_button.disabled, "the hidden Priority Peck action should remain locked before policy", failures)

	await _start_normal_running_campaign(office, failures)
	if dialogue_ui != null:
		dialogue_ui.clear_session()
	await process_frame
	if routing_ui != null:
		routing_ui.clear_focus()
	await process_frame
	_check(dossier != null and not dossier.is_visible_in_tree(), "dossier should remain hidden before a hen is selected in normal play", failures)
	_check(assist_button != null and not assist_button.is_visible_in_tree(), "Priority Peck should not float outside a closed dossier", failures)

	if routing_ui != null:
		routing_ui.set_focus(0)
	await process_frame
	_check(dossier != null and dossier.is_visible_in_tree(), "selecting a hen should reveal the dossier", failures)
	_check(assist_button != null and assist_button.is_visible_in_tree(), "selecting a hen should reveal Priority Peck inside the dossier", failures)
	_check(assist_button != null and assist_button.disabled, "Priority Peck should remain locked without an active file", failures)
	_check(assist_button != null and "NO ACTIVE FILE" in assist_button.text, "idle hens should explain that no claim can be assisted", failures)
	_check(timing_label != null and not timing_label.is_visible_in_tree(), "idle hens should not show a timing target", failures)
	if dossier != null and assist_button != null:
		var dossier_rect := dossier.get_global_rect().grow(0.5)
		var button_rect := assist_button.get_global_rect()
		_check(
			dossier_rect.has_point(button_rect.position) and dossier_rect.has_point(button_rect.end),
			"Priority Peck should be fully contained by the selected-hen dossier",
			failures,
		)

	_check(
		simulation != null and simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING,
		"the normal campaign fixture should retain the authoritative running shift",
		failures,
	)

	# Build a real claim rhythm using authoritative ticks. Keeping the game clock
	# paused makes this deterministic and proves the inspection-to-action recovery:
	# selection stays safe, then one explicit confirmation resumes and stamps.
	if clock != null:
		clock.set_speed(0)
	office.call("_retire_action_outcome_receipts", &"core_action_hold_test", false)
	var uses_before_invalid_resume := simulation.peck_assists_used_today if simulation != null else -1
	office.call("_on_peck_assist_requested", 0)
	await process_frame
	var held_notifications := office.call("_notification_diagnostic_state") as Dictionary
	var held_announcement := office.call(
		"_web_accessibility_announcement",
		simulation.snapshot(),
		"",
	) as Dictionary
	_check(
		clock != null
		and clock.speed_index == 0
		and simulation != null
		and simulation.peck_assists_used_today == uses_before_invalid_resume
		and bool(held_notifications.get("toast_visible", false))
		and String(held_notifications.get("toast_copy", "")) == "PECK HELD  ·  WAIT FOR WORK"
		and String(held_notifications.get("toast_priority", "")) == "action"
		and "actively pecking a file" in String(held_announcement.get("text", "")),
		"an invalid paused request should preserve time and attention while showing one concise, fully narrated recovery receipt",
		failures,
	)
	office.call("_on_worker_assignment_undo_requested", 0)
	var stale_undo_notifications := office.call("_notification_diagnostic_state") as Dictionary
	_check(
		String(stale_undo_notifications.get("toast_copy", ""))
		== "UNDO HELD  ·  CHOOSE NEW ROUTE"
		and "Choose a new route" in String(
			(office.get("_ticker_label") as Label).get_meta("accessible_text", ""),
		),
		"a stale one-level Undo should replace hidden label text with an actionable priority receipt",
		failures,
	)
	office.call("_on_worker_assignment_requested", -1, &"auto")
	var stale_route_notifications := office.call("_notification_diagnostic_state") as Dictionary
	_check(
		String(stale_route_notifications.get("toast_copy", ""))
		== "ROUTE HELD  ·  PICK ACTIVE HEN"
		and "current employed hen" in String(
			(office.get("_ticker_label") as Label).get_meta("accessible_text", ""),
		),
		"a stale route command should identify the unavailable hen and retain the exact recovery path assistively",
		failures,
	)
	var priority_preferences := (office.get("_player_preferences") as Dictionary).duplicate(true)
	priority_preferences["notice_level"] = "priority"
	office.set("_player_preferences", priority_preferences)
	office.call("_publish_priority_peck_hold", {
		"window_state": &"spent",
		"reason": "A clean assisted delivery restores the next management-attention charge.",
	})
	var spent_notifications := office.call("_notification_diagnostic_state") as Dictionary
	_check(
		bool(spent_notifications.get("toast_visible", false))
		and String(spent_notifications.get("toast_copy", "")) == "PECK HELD  ·  0 CHARGES  >  DELIVER"
		and "clean assisted delivery restores" in String(
			(office.get("_ticker_label") as Label).get_meta("accessible_text", ""),
		),
		"priority-only notices should retain the compact depleted-charge receipt and its exact recovery rule",
		failures,
	)
	priority_preferences["notice_level"] = "all"
	office.set("_player_preferences", priority_preferences)
	if simulation != null:
		simulation.set_worker_at_workstation(0, true)
		# One authoritative tick assigns the first file and exposes the pre-gold
		# timing state without depending on a restored campaign's incidental frame.
		simulation.advance_tick()
	await process_frame
	_check(
		assist_button != null
		and assist_button.disabled
		and assist_button.text.begins_with("PECK")
		and "E / A" in assist_button.text
		and "BUILDING RHYTHM" not in assist_button.text
		and "wait for the file meter" in assist_button.accessibility_name
		and assist_button.accessibility_name == String(assist_button.get_meta("accessible_text", "")),
		"the warming timing window should preserve one recognizable action target while assistive copy explains its lock",
		failures,
	)
	var first_window_open := _advance_until_assist_available(simulation, 0)
	await process_frame
	_check(first_window_open, "a seated working hen should enter the Priority Peck timing window", failures)
	_check(
		simulation != null and bool(simulation.peck_assist_status(0).get("available", false)),
		"authoritative status should report the live timing window",
		failures,
	)
	var open_assist := simulation.peck_assist_status(0) if simulation != null else {}
	_check(
		 timing_label != null
		and timing_label.is_visible_in_tree()
		and timing_label.text.begins_with("PECK NOW")
		and String(open_assist.get("timing_label", "")) in timing_label.text
		and "58-66%" in timing_label.tooltip_text
		and "ideal 62%" in timing_label.tooltip_text
		and "Priority Peck now" in timing_label.accessibility_name
		and timing_label.tooltip_text == timing_label.accessibility_name,
		"an active claim should show the immediate action while retaining exact timing detail on demand",
		failures,
	)
	_check(
		progress_track != null and progress_track.custom_minimum_size.y >= 16.0,
		"the Priority Peck timing lane should be tall enough to read at a glance",
		failures,
	)
	_check(
		gold_band != null
		and ideal_marker != null
		and gold_band.is_visible_in_tree()
		and ideal_marker.is_visible_in_tree()
		and is_equal_approx(gold_band.anchor_left, 0.58)
		and is_equal_approx(gold_band.anchor_right, 0.66)
		and is_equal_approx(ideal_marker.anchor_left, 0.62),
		"the claim meter should position its gold band and ideal marker from authoritative timing values",
		failures,
	)
	if dossier != null and progress_track != null and gold_band != null and ideal_marker != null:
		var track_rect := progress_track.get_global_rect().grow(0.5)
		_check(
			track_rect.has_point(gold_band.get_global_rect().position)
			and track_rect.has_point(gold_band.get_global_rect().end)
			and track_rect.has_point(ideal_marker.get_global_rect().position)
			and track_rect.has_point(ideal_marker.get_global_rect().end),
			"the Priority Peck targets should stay clipped inside the dossier progress track",
			failures,
		)
	_check(
		assist_button != null
		and not assist_button.disabled
		and bool(assist_button.get_meta("resume_required", false))
		and "RESUME + PECK" in assist_button.text,
		"a paused open window should offer one explicit resume-and-peck confirmation",
		failures,
	)
	_check(
		intent_button != null
		and intent_button.icon != null
		and not intent_button.disabled
		and "SYNC PECK" in intent_button.text
		and "Resume" in intent_button.tooltip_text,
		"the icon-led shortcut should remain actionable and disclose its paused-clock consequence",
		failures,
	)
	_check(
		assist_button != null and "Resume" in assist_button.tooltip_text,
		"paused Priority Peck should tell the player how to unlock it",
		failures,
	)
	_check(
		intent_link != null
		and not intent_link.is_visible_in_tree()
		and not bool(intent_link.get_meta("active", false)),
		"paused Priority Peck should suppress the connective pulse instead of implying a live action",
		failures,
	)
	var uses_before_paused_handoff := simulation.peck_assists_used_today if simulation != null else -1
	var paused_target := routing_ui.focus_intent_action(&"peck") if routing_ui != null else null
	await process_frame
	_check(
		paused_target == assist_button
		and root.gui_get_focus_owner() == assist_button
		and simulation != null
		and simulation.peck_assists_used_today == uses_before_paused_handoff
		and clock != null
		and clock.speed_index == 0,
		"rail-style focus handoff should expose recovery without resuming or spending it",
		failures,
	)
	_check(
		intent_link != null
		and not intent_link.is_visible_in_tree()
		and not bool(intent_link.get_meta("active", false)),
		"paused recovery should remain static instead of implying that time is already live",
		failures,
	)
	if routing_ui != null:
		routing_ui.set_reduced_motion(true)
	await process_frame
	_check(
		intent_link != null
		and not intent_link.is_visible_in_tree()
		and bool(intent_link.get_meta("reduced_motion", false))
		and intent_button != null
		and intent_button.modulate.is_equal_approx(Color.WHITE),
		"reduced motion should keep paused recovery quiet and the icon static",
		failures,
	)
	if routing_ui != null:
		routing_ui.set_reduced_motion(false)
	await process_frame
	_check(assist_button != null and "PECK" in assist_button.text, "open timing window should present a concise action label", failures)
	_check(
		assist_button != null
		and "restores one charge" in assist_button.tooltip_text
		and "crack consumes" in assist_button.tooltip_text,
		"Priority Peck should explain its renewable clean-delivery loop before commitment",
		failures,
	)
	var first_progress_before := _worker_progress(simulation, 0)
	var first_claim_id := int(simulation.peck_assist_status(0).get("claim_id", -1)) if simulation != null else -1
	var uses_before_mouse := simulation.peck_assists_used_today if simulation != null else -1
	var claim_paths_filed_during_handoff: Array[StringName] = []
	if routing_ui != null:
		routing_ui.claim_resolution_requested.connect(
			func(_worker_id: int, path_id: StringName) -> void:
				claim_paths_filed_during_handoff.append(path_id)
		)
	if assist_button != null:
		await _mouse_click(assist_button)
	await process_frame
	var first_result := simulation.last_peck_assist if simulation != null else {}
	var focus_handoff := (
		routing_ui.peck_result_focus_handoff_state()
		if routing_ui != null else
		{}
	)
	_check(
		intent_button != null
		and root.gui_get_focus_owner() == intent_button
		and String(intent_button.get_meta("action_id", "")) != "peck"
		and String(focus_handoff.get("status", "")) == "completed"
		and String(focus_handoff.get("target", "")) == "HenIntentAction"
		and claim_paths_filed_during_handoff.is_empty(),
		"a committed peck should repair only its disabled focus into the visible next intent without filing it",
		failures,
	)
	_check(
		clock != null and clock.speed_index == 1,
		"confirming paused Priority Peck should resume through the normal 1x speed route",
		failures,
	)
	# Freeze only the test fixture after proving the real resume. This keeps the
	# following result-presentation assertions deterministic on slower runners.
	if clock != null:
		clock.set_speed(0)
	await process_frame
	_check(
		simulation != null and simulation.peck_assists_used_today == uses_before_mouse + 1,
		"clicking the dossier button should invoke one authoritative Priority Peck",
		failures,
	)
	_check(
		int(first_result.get("worker_id", -1)) == 0 and int(first_result.get("claim_id", -1)) == first_claim_id,
		"mouse invocation should stamp the focused hen's exact active claim",
		failures,
	)
	_check(
		intent_link != null
		and intent_link.is_visible_in_tree()
		and bool(intent_link.get_meta("confirmation", false))
		and StringName(intent_link.get_meta("rating", &"")) == StringName(first_result.get("rating", &"")),
		"a landed Priority Peck should reverse the connector with the authoritative result rating",
		failures,
	)
	if routing_ui != null:
		routing_ui.set_reduced_motion(true)
		routing_ui.play_peck_assist_result(0, StringName(first_result.get("rating", &"")))
	await process_frame
	_check(
		intent_link != null
		and intent_link.is_visible_in_tree()
		and bool(intent_link.get_meta("confirmation", false))
		and bool(intent_link.get_meta("reduced_motion", false)),
		"reduced motion should retain a brief static result connection",
		failures,
	)
	if routing_ui != null:
		routing_ui.set_reduced_motion(false)
		routing_ui.call("_process", PeckworkRoutingUI.PECK_RESULT_LINK_DURATION + 0.1)
	await process_frame
	_check(
		intent_link != null
		and not intent_link.is_visible_in_tree()
		and not bool(intent_link.get_meta("active", false)),
		"the result connector should settle instead of becoming persistent clutter",
		failures,
	)
	_check(_worker_progress(simulation, 0) > first_progress_before, "accepted mouse invocation should advance authoritative claim progress", failures)
	_check(assist_button != null and assist_button.disabled, "a stamped claim should immediately lock against duplicate input", failures)
	_check(
		assist_button != null and _display_rating(first_result) in assist_button.text,
		"button should retain the exact completed timing rating",
		failures,
	)
	_check(
		assist_button != null and "CHAIN x%d" % int(first_result.get("streak", 0)) in assist_button.text,
		"button should retain the completed timing chain",
		failures,
	)
	_check(
		assist_receipt != null
		and "FILE +%d%%" % int(roundf(float(first_result.get("progress_gain", 0.0)))) in assist_receipt.text
		and "RISK" in assist_receipt.text
		and "CLEAN EGG REFUNDS 1" in assist_receipt.text,
		"the completed action should label its immediate file, risk, and renewable-charge payoff",
		failures,
	)
	_check(timing_label != null and not timing_label.is_visible_in_tree(), "a completed assist should retire the live timing guide", failures)
	if simulation != null:
		simulation.workers[0].work_progress = 99.0
		simulation.advance_tick()
	await process_frame
	_check(
		claim_label != null
		and claim_label.text.begins_with("APPEALS #")
		and "LAYING" not in claim_label.text
		and claim_phase_icon != null
		and claim_phase_icon.is_visible_in_tree()
		and claim_phase_icon.texture != null
		and String(claim_phase_icon.get_meta("semantic_shape", "")) == "egg_receipt"
		and claim_phase_progress != null
		and claim_phase_progress.text == "100%"
		and "Step 3, egg laying" in claim_label.accessibility_name,
		"a boosted file reaching 100%% should replace the laying word with the egg receipt (actual: %s)" % (
			claim_label.text if claim_label != null else "<missing>"
		),
		failures,
	)
	var laying_claim_facts := (
		claim_detail.get_meta("facts", []) as Array
		if claim_detail != null else
		[]
	)
	_check(
		claim_detail != null
		and claim_detail.is_visible_in_tree()
		and laying_claim_facts.size() == 3
		and String((laying_claim_facts[0] as Dictionary).get("icon", "")) == "cash"
		and String((laying_claim_facts[0] as Dictionary).get("value", "")).begins_with("$")
		and String((laying_claim_facts[1] as Dictionary).get("icon", "")) == "shell_risk"
		and String((laying_claim_facts[1] as Dictionary).get("value", "")).ends_with("%")
		and String((laying_claim_facts[2] as Dictionary).get("icon", "")) == "grading"
		and String((laying_claim_facts[2] as Dictionary).get("value", "")) == "GRADING"
		and "farmer basket" in claim_detail.accessibility_name
		and claim_detail.tooltip_text == claim_detail.accessibility_name,
		"the non-interactive delivery beat should use payout, cracked-shell, and grading facts without a retired deadline sentence",
		failures,
	)
	_check(
		assist_receipt != null and not assist_receipt.is_visible_in_tree(),
		"the completed Priority Peck receipt should retire its dense laying sentence",
		failures,
	)
	var delivery_lifecycle := routing_ui.routing_lifecycle_state()
	var delivery_lifecycle_stages := delivery_lifecycle.get("stage_states", []) as Array
	_check(
		bool(delivery_lifecycle.get("visible", false))
		and String(delivery_lifecycle.get("active_stage", "")) == "egg"
		and not bool(delivery_lifecycle.get("visible_stage_labels", true))
		and delivery_lifecycle_stages.size() == 3
		and String((delivery_lifecycle_stages[2] as Dictionary).get("semantic_shape", "")) == "egg_receipt"
		and String((delivery_lifecycle_stages[2] as Dictionary).get("state", "")) == "current"
		and bool(delivery_lifecycle.get("clean_delivery_refund", false))
		and String(delivery_lifecycle.get("reward_shape", "")) == "charge_diamond_plus_one"
		and not bool(delivery_lifecycle.get("route_hint_visible", true))
		and "restore one Priority Peck charge" in String(delivery_lifecycle.get("accessible_text", "")),
		"laying should replace prose with the active egg stage and one renewable-charge diamond",
		failures,
	)
	var laying_handoff := (
		routing_ui.peck_result_focus_handoff_state()
		if routing_ui != null else
		{}
	)
	_check(
		intent_button != null
		and "TRACK EGG" in intent_button.text
		and StringName(intent_button.get_meta("action_id", &"")) == &"route"
		and not intent_button.disabled
		and root.gui_get_focus_owner() == intent_button
		and String(laying_handoff.get("action_id", "")) == "route",
		"the same focused next-action prompt should mature into a truthful egg-tracking receipt",
		failures,
	)
	if routing_ui != null:
		routing_ui.call("_on_dossier_tab_pressed", &"claim")
	await process_frame
	if intent_button != null:
		intent_button.pressed.emit()
	await process_frame
	_check(
		routing_ui != null
		and routing_ui.active_dossier_tab() == &"route"
		and claim_paths_filed_during_handoff.is_empty(),
		"TRACK EGG should return to the live receipt without filing an expired claimant choice",
		failures,
	)

	# The semantic action must share the same authoritative route. Prepare a new
	# worker's window, then inject the mapped action rather than calling Office
	# internals; this covers keyboard/gamepad remapping without coupling to KEY_E.
	if clock != null:
		clock.set_speed(0)
	if simulation != null:
		simulation.set_worker_at_workstation(0, false)
		simulation.set_worker_at_workstation(1, true)
	office.call("_on_camera_focus_changed", "PIP", 1)
	var second_window_open := _advance_until_assist_available(simulation, 1)
	await process_frame
	_check(second_window_open, "a second seated hen should receive an independent timing window", failures)
	_check(InputMap.has_action(&"peck_assist"), "Office should register a semantic peck_assist action", failures)
	_check(_action_has_keyboard_or_gamepad_binding(&"peck_assist"), "peck_assist should expose keyboard or gamepad input", failures)
	if clock != null:
		clock.set_speed(3)
	await process_frame
	_check(clock != null and clock.speed_index == 3, "10× should remain the player's requested speed", failures)
	_check(
		clock != null and clock.precision_focus_limiting() and is_equal_approx(clock.effective_multiplier(), 1.0),
		"an inspected open claim should hold 10× at a readable 1× effective pace",
		failures,
	)
	var ultra_button := office.find_child("SpeedButton_3", true, false) as Button
	var guidance := office.get("_guidance_label") as Label
	_check(ultra_button != null and "10×/1×" in ultra_button.text, "speed controls should disclose the temporary precision hold", failures)
	_check(
		guidance != null and "PRIORITY FOCUS 1×" in guidance.text,
		"live guidance should explain the precision window (actual: %s)" % (guidance.text if guidance != null else "<missing>"),
		failures,
	)
	# A visual-novel aside can arrive at the same instant as a timing window. It
	# must freeze the live clock, swallow the semantic action, then restore the
	# exact selected speed so the opportunity remains fair and legible.
	if dialogue_ui != null:
		dialogue_ui.clear_session()
		_check(dialogue_ui.enqueue_dialogue({
			"id": &"priority_peck_input_guard_probe",
			"speaker_id": &"mabel",
			"speaker_name": "Mabel",
			"speaker_role": "Junior Peckwork Clerk",
			"portrait_id": &"mabel",
			"channel": &"PRIVATE ASIDE",
			"text": "One filing at a time, please.",
			"hold_seconds": 15.0,
			"presentation_mode": &"visual_novel",
		}), "visual-novel guard probe should be accepted", failures)
	await process_frame
	_check(
		clock != null and clock.speed_index == 0 and dialogue_ui != null and dialogue_ui.is_blocking(),
		"a visual-novel aside should pause the running floor while it owns attention",
		failures,
	)
	var guarded_uses := simulation.peck_assists_used_today if simulation != null else -1
	var guarded_event := InputEventAction.new()
	guarded_event.action = &"peck_assist"
	guarded_event.pressed = true
	guarded_event.strength = 1.0
	Input.parse_input_event(guarded_event)
	await process_frame
	_check(
		simulation != null and simulation.peck_assists_used_today == guarded_uses,
		"Priority Peck input should never fire behind a visual-novel aside",
		failures,
	)
	if dialogue_ui != null:
		dialogue_ui.dismiss_current()
	await process_frame
	_check(
		clock != null and clock.speed_index == 3,
		"filing the aside should restore the player's exact requested 10× speed",
		failures,
	)
	var second_claim_id := int(simulation.peck_assist_status(1).get("claim_id", -1)) if simulation != null else -1
	var uses_before_semantic := simulation.peck_assists_used_today if simulation != null else -1
	var semantic_event := InputEventAction.new()
	semantic_event.action = &"peck_assist"
	semantic_event.pressed = true
	semantic_event.strength = 1.0
	Input.parse_input_event(semantic_event)
	await process_frame
	var second_result := simulation.last_peck_assist if simulation != null else {}
	_check(
		simulation != null and simulation.peck_assists_used_today == uses_before_semantic + 1,
		"semantic peck_assist input should invoke one authoritative action",
		failures,
	)
	_check(
		int(second_result.get("worker_id", -1)) == 1 and int(second_result.get("claim_id", -1)) == second_claim_id,
		"semantic input should stamp the focused hen's exact active claim",
		failures,
	)
	_check(
		clock != null and clock.precision_focus_limiting() and is_equal_approx(clock.effective_multiplier(), 1.0),
		"filing the exact claim should retain 1× through the short result beat",
		failures,
	)
	_check(
		assist_button != null
		and _display_rating(second_result) in assist_button.text
		and "shell risk" in assist_button.tooltip_text,
		"the dossier should retain rating, gain, and shell-risk outcome clarity",
		failures,
	)
	await create_timer(3.2).timeout
	_check(
		clock != null and not clock.precision_focus_limiting() and is_equal_approx(clock.effective_multiplier(), 10.0),
		"the requested 10× pace should restore automatically after the result beat",
		failures,
	)
	_check(ultra_button != null and ultra_button.text == "10×", "restored speed should retire the precision marker", failures)

	# Let short feedback cues retire before tearing down the whole office; the
	# dummy headless audio driver otherwise reports live playback resources.
	await create_timer(0.4).timeout
	office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("PECK_ASSIST_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PECK_ASSIST_UI_TEST_PASSED dossier=contained mouse=authoritative paused=explicit_resume dialogue_guard=time-safe semantic_input=authoritative precision_focus=1x outcome=retained")
	quit(0)


func _display_rating(receipt: Dictionary) -> String:
	return PeckworkRoutingUI._peck_rating_label(StringName(receipt.get("rating", &"steady")))


func _start_normal_running_campaign(office: Office, failures: Array[String]) -> void:
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var routing_ui := office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	var simulation := office.get("_simulation") as DepartmentSimulation
	if campaign_ui != null:
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
	var assist_button := office.find_child("PeckAssistButton", true, false) as Button
	_check(
		decision_host != null and decision_host.is_visible_in_tree(),
		"opening Mabel's file should reveal the blocking morning directive",
		failures,
	)
	_check(
		routing_ui != null and not routing_ui.is_visible_in_tree(),
		"Peckwork should stay hidden behind the blocking morning directive",
		failures,
	)
	_check(assist_button != null and assist_button.disabled, "the hidden Priority Peck action should stay locked before policy", failures)

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
	_check(routing_ui != null and routing_ui.is_visible_in_tree(), "normal running play should reveal Peckwork", failures)


func _advance_until_assist_available(simulation: DepartmentSimulation, worker_id: int) -> bool:
	if simulation == null:
		return false
	for _step in 32:
		if bool(simulation.peck_assist_status(worker_id).get("available", false)):
			return true
		simulation.advance_tick()
	return bool(simulation.peck_assist_status(worker_id).get("available", false))


func _worker_progress(simulation: DepartmentSimulation, worker_id: int) -> float:
	if simulation == null:
		return -1.0
	for worker_value in simulation.snapshot().get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return float(worker.get("progress", -1.0))
	return -1.0


func _mouse_click(button: Button) -> void:
	var position := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	root.push_input(motion, true)
	await process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	root.push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	root.push_input(release, true)
	await process_frame


func _action_has_keyboard_or_gamepad_binding(action: StringName) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey or event is InputEventJoypadButton:
			return true
	return false


func _press(button: Button) -> bool:
	if button == null or button.disabled:
		return false
	button.pressed.emit()
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
