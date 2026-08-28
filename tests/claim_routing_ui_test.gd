extends SceneTree

const Palette := preload("res://core/settings/semantic_color_palette.gd")


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
	var queue_title := office.find_child("RoutingQueueTitle", true, false) as Label
	var dossier := office.find_child("PeckworkAssignmentDossier", true, false) as PanelContainer
	var nest_queue := office.find_child("Queue_nest_damage", true, false) as Label
	var predator_queue := office.find_child("Queue_predator_loss", true, false) as Label
	var appeals_queue := office.find_child("Queue_appeals", true, false) as Label
	var nest_queue_icon := office.find_child("QueueIcon_nest_damage", true, false) as TextureRect
	var predator_queue_icon := office.find_child("QueueIcon_predator_loss", true, false) as TextureRect
	var appeals_queue_icon := office.find_child("QueueIcon_appeals", true, false) as TextureRect
	var overdue_queue_icon := office.find_child("QueueOverdueStateIcon", true, false) as TextureRect
	var nest_dispatch_tray := office.find_child("DispatchTray_nest_damage", true, false) as Button
	var dispatch_momentum := office.find_child("DispatchMomentum", true, false) as Label
	var dispatch_break_glyph := office.find_child("DispatchMomentumBreakGlyph", true, false) as Control
	var status_toast_label := office.find_child("StatusToastLabel", true, false) as Label
	var queue_contract_badge := office.find_child("RoutingQueueContractBadge", true, false) as Label
	var assign_auto := office.find_child("Assign_auto", true, false) as Button
	var assign_nest := office.find_child("Assign_nest_damage", true, false) as Button
	var assign_predator := office.find_child("Assign_predator_loss", true, false) as Button
	var assign_appeals := office.find_child("Assign_appeals", true, false) as Button
	var current_claim := office.find_child("RoutingCurrentClaim", true, false) as Label
	var claim_phase_icon := office.find_child("RoutingClaimPhaseIcon", true, false) as TextureRect
	var claim_phase_progress := office.find_child("RoutingClaimPhaseProgress", true, false) as Label
	var claim_detail := office.find_child("RoutingClaimDetail", true, false) as Control
	var current_contract_badge := office.find_child("RoutingCurrentContractBadge", true, false) as Label
	var automation_hint := office.find_child("RoutingAutomationHint", true, false) as Label
	var worker_career := office.find_child("RoutingWorkerCareer", true, false) as Label
	var worker_profile := office.find_child("RoutingWorkerSpecialty", true, false) as Label
	var worker_profile_icon := office.find_child("RoutingWorkerProfileIcon", true, false) as TextureRect
	var worker_specialty_icon := office.find_child("RoutingWorkerSpecialtyIcon", true, false) as TextureRect
	var manager_trust := office.find_child("RoutingManagerTrust", true, false) as Label
	var grievance := office.find_child("RoutingGrievance", true, false) as Label
	var check_in_status := office.find_child("RoutingCheckInStatus", true, false) as Label
	var dossier_summary := office.find_child("RoutingDossierSummary", true, false) as Label
	var details_toggle := office.find_child("RoutingDetailsToggle", true, false) as Button
	var route_tab := office.find_child("DossierTab_route", true, false) as Button
	var claim_tab := office.find_child("DossierTab_claim", true, false) as Button
	var support_tab := office.find_child("DossierTab_support", true, false) as Button
	var profile_tab := office.find_child("DossierTab_profile", true, false) as Button
	var settle_claim := office.find_child("ClaimResolution_settle", true, false) as Button
	var deny_claim := office.find_child("ClaimResolution_deny", true, false) as Button
	var except_claim := office.find_child("ClaimResolution_exception", true, false) as Button
	var share_credit := office.find_child("PersonnelAction_share_credit", true, false) as Button
	var career_coaching := office.find_child("PersonnelAction_career_coaching", true, false) as Button
	var quota_pressure := office.find_child("PersonnelAction_quota_pressure", true, false) as Button
	var decision_host := office.find_child("ManagementDecisionHost", true, false) as Control
	var audio_feedback := office.get("_audio_feedback") as OfficeAudioFeedback
	var routing_audio_cues: Array[StringName] = []
	if audio_feedback != null:
		audio_feedback.cue_played.connect(func(cue: StringName) -> void:
			routing_audio_cues.append(cue)
		)

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
	var default_queue_state := routing_ui.queue_strip_state() if routing_ui != null else {}
	var default_queue_lanes := default_queue_state.get("lanes", []) as Array
	var complete_default_queue_marks := 0
	for default_lane: Dictionary in default_queue_lanes:
		if (
			bool(default_lane.get("icon_visible", false))
			and not String(default_lane.get("semantic_icon", "")).is_empty()
			and not String(default_lane.get("accessible_text", "")).is_empty()
		):
			complete_default_queue_marks += 1
	_check(
		queue_title != null and queue_title.text == "ROUTING"
		and nest_queue != null and nest_queue.text == "2"
		and predator_queue != null and predator_queue.text == "2"
		and appeals_queue != null and appeals_queue.text == "2"
		and nest_queue_icon != null and nest_queue_icon.is_visible_in_tree()
		and predator_queue_icon != null and predator_queue_icon.is_visible_in_tree()
		and appeals_queue_icon != null and appeals_queue_icon.is_visible_in_tree()
		and overdue_queue_icon != null and overdue_queue_icon.is_visible_in_tree()
		and default_queue_lanes.size() == 3
		and complete_default_queue_marks == 3
		and bool(default_queue_state.get("compact_lane_marks", false))
		and String(default_queue_state.get("shape_language", "")).contains("fox=predator")
		and String(default_queue_state.get("overdue_state_shape", "")) == "ring_check",
		"default routing should communicate three named trays and overdue state through persistent shapes plus counts",
		failures,
	)
	_check(queue_contract_badge != null and not queue_contract_badge.visible, "contract badge should stay hidden when routing trays contain only internal files", failures)
	_check(dossier != null and not dossier.is_visible_in_tree(), "worker dossier should stay hidden before a hen is selected", failures)
	_check(
		nest_dispatch_tray != null and not nest_dispatch_tray.disabled,
		"a non-empty overview tray should be an enabled semantic dispatch action",
		failures,
	)
	var idle_queue_rect := queue_strip.get_global_rect() if queue_strip != null else Rect2()
	_check(
		dispatch_momentum != null
		and not dispatch_momentum.is_visible_in_tree()
		and queue_strip != null
		and bool(queue_strip.get_meta("compact_idle_extent", false))
		and idle_queue_rect.size.x <= 420.0,
		"idle routing should end after Overdue instead of reserving an empty momentum tail",
		failures,
	)
	var scaled_preferences := (office.get("_player_preferences") as Dictionary).duplicate(true)
	scaled_preferences["ui_scale"] = 1.5
	office.set("_player_preferences", scaled_preferences)
	office.call("_apply_management_ui_preferences")
	await process_frame
	await process_frame
	var scaled_queue_state := routing_ui.queue_strip_state() if routing_ui != null else {}
	var scaled_queue_rect := queue_strip.get_global_rect() if queue_strip != null else Rect2()
	_check(
		is_equal_approx(float(scaled_queue_state.get("interface_scale", 0.0)), 1.5)
		and bool(scaled_queue_state.get("compact_lane_marks", false))
		and String(scaled_queue_state.get("heading", "")) == "ROUTING"
		and scaled_queue_rect.size.x <= 420.0
		and nest_queue_icon != null and nest_queue_icon.is_visible_in_tree()
		and predator_queue_icon != null and predator_queue_icon.is_visible_in_tree()
		and appeals_queue_icon != null and appeals_queue_icon.is_visible_in_tree()
		and overdue_queue_icon != null and overdue_queue_icon.is_visible_in_tree()
		and nest_queue_icon.texture != null
		and predator_queue_icon.texture != null
		and appeals_queue_icon.texture != null
		and String(nest_queue_icon.get_meta("semantic_icon", "")) == "lane_nest"
		and String(predator_queue_icon.get_meta("semantic_icon", "")) == "lane_predator"
		and String(appeals_queue_icon.get_meta("semantic_icon", "")) == "lane_appeals"
		and "NEST" not in nest_queue.text
		and "PREDATOR" not in predator_queue.text
		and "APPEALS" not in appeals_queue.text,
		"150-percent routing should replace crowded lane words with distinct semantic marks and contained counts",
		failures,
	)
	scaled_preferences["ui_scale"] = 1.0
	office.set("_player_preferences", scaled_preferences)
	office.call("_apply_management_ui_preferences")
	await process_frame
	await process_frame
	_check(
		queue_title != null and queue_title.text == "ROUTING"
		and nest_queue_icon != null and nest_queue_icon.is_visible_in_tree()
		and predator_queue_icon != null and predator_queue_icon.is_visible_in_tree()
		and appeals_queue_icon != null and appeals_queue_icon.is_visible_in_tree()
		and "NEST" not in nest_queue.text
		and "PREDATOR" not in predator_queue.text
		and "APPEALS" not in appeals_queue.text,
		"returning to 100 percent should preserve the icon-led routing language",
		failures,
	)
	var dispatch_save_before := simulation.export_save_state()
	var dispatch_arrival_before := routing_ui.dispatch_tray_arrival_state()
	var priority_target := routing_ui.focus_priority_dispatch_tray()
	var priority_arrival := routing_ui.dispatch_tray_arrival_state()
	_check(
		priority_target != null
		and priority_target is Button
		and bool(priority_arrival.get("active", false))
		and bool(priority_arrival.get("animated", false))
		and not bool(priority_arrival.get("reduced_motion", true))
		and String(priority_arrival.get("target", "")) == String(priority_target.name)
		and String(priority_arrival.get("lane", "")) != ""
		and int(priority_arrival.get("serial", 0)) == int(dispatch_arrival_before.get("serial", 0)) + 1
		and simulation.export_save_state() == dispatch_save_before,
		"a live-files handoff should acknowledge the exact urgent tray without arming a route",
		failures,
	)
	routing_ui.set_reduced_motion(true)
	var reduced_priority_target := routing_ui.focus_priority_dispatch_tray()
	var reduced_priority_arrival := routing_ui.dispatch_tray_arrival_state()
	_check(
		reduced_priority_target == priority_target
		and bool(reduced_priority_arrival.get("active", false))
		and not bool(reduced_priority_arrival.get("animated", true))
		and bool(reduced_priority_arrival.get("reduced_motion", false))
		and int(reduced_priority_arrival.get("serial", 0)) == int(priority_arrival.get("serial", 0)) + 1
		and (reduced_priority_target as Control).modulate != Color.WHITE
		and simulation.export_save_state() == dispatch_save_before,
		"reduced motion should retain a static exact-tray acknowledgment without mutating gameplay",
		failures,
	)
	var populated_routing_snapshot := (
		routing_ui.get("_snapshot") as Dictionary
	).duplicate(true)
	var empty_routing_snapshot := populated_routing_snapshot.duplicate(true)
	var empty_routing := (
		empty_routing_snapshot.get("routing", {}) as Dictionary
	).duplicate(true)
	var empty_counts: Dictionary = {}
	var empty_items: Dictionary = {}
	for lane: StringName in [&"nest_damage", &"predator_loss", &"appeals"]:
		empty_counts[lane] = 0
		empty_counts[String(lane)] = 0
		empty_items[lane] = []
		empty_items[String(lane)] = []
	empty_routing["queue_counts"] = empty_counts.duplicate(true)
	empty_routing["overdue_by_lane"] = empty_counts.duplicate(true)
	empty_routing_snapshot["routing"] = empty_routing
	empty_routing_snapshot["claim_queue_counts"] = empty_counts.duplicate(true)
	empty_routing_snapshot["claim_queue_overdue_counts"] = empty_counts.duplicate(true)
	empty_routing_snapshot["claim_queue_items"] = empty_items
	routing_ui.apply_snapshot(empty_routing_snapshot)
	await process_frame
	var fallback_style_before := queue_strip.get_theme_stylebox("panel")
	var fallback_arrival_before := routing_ui.dispatch_tray_arrival_state()
	var fallback_target := routing_ui.focus_priority_dispatch_tray()
	var fallback_arrival := routing_ui.dispatch_tray_arrival_state()
	_check(
		fallback_target == queue_strip
		and bool(fallback_arrival.get("active", false))
		and bool(fallback_arrival.get("fallback", false))
		and String(fallback_arrival.get("reason", "")) == "waiting_for_intake"
		and String(fallback_arrival.get("target", "")) == "PeckworkQueueStrip"
		and String(fallback_arrival.get("lane", "")) == ""
		and not bool(fallback_arrival.get("animated", true))
		and bool(fallback_arrival.get("reduced_motion", false))
		and int(fallback_arrival.get("serial", 0)) == int(fallback_arrival_before.get("serial", 0)) + 1
		and queue_strip.modulate != Color.WHITE
		and queue_title != null
		and queue_title.text == "INTAKE CLEAR  ·  WAITING"
		and "no file is ready" in queue_strip.accessibility_name
		and simulation.export_save_state() == dispatch_save_before,
		"an empty Live Files handoff should acknowledge waiting intake without inventing a file",
		failures,
	)
	routing_ui.clear_dispatch_tray_arrival()
	_check(
		not bool(routing_ui.dispatch_tray_arrival_state().get("active", true))
		and queue_strip.modulate == Color.WHITE
		and queue_strip.get_theme_stylebox("panel") == fallback_style_before
		and queue_title != null
		and queue_title.text == "ROUTING"
		and queue_strip.focus_mode == Control.FOCUS_NONE
		and queue_strip.accessibility_name.is_empty(),
		"clearing a waiting-intake arrival should restore the queue strip exactly",
		failures,
	)
	routing_ui.apply_snapshot(populated_routing_snapshot)
	routing_ui.set_reduced_motion(false)
	var camera_controller := office.get("_camera_controller") as ManagementCameraController
	var camera_before := camera_controller.navigation_state() if camera_controller != null else {}
	if nest_dispatch_tray != null:
		nest_dispatch_tray.pressed.emit()
	var dispatch_save_after := simulation.export_save_state()
	await process_frame
	_check(
		StringName(office.get("_dispatch_lane")) == &"nest_damage",
		"clicking a waiting tray should arm one-hen dispatch mode",
		failures,
	)
	_check(
		not bool(routing_ui.dispatch_tray_arrival_state().get("active", true))
		and priority_target.modulate == Color.WHITE,
		"activating the acknowledged tray should clear its transient arrival state",
		failures,
	)
	_check(
		dispatch_momentum != null and "PICK" in dispatch_momentum.text,
		"armed dispatch should replace prose with a compact pick-star cue",
		failures,
	)
	var active_queue_rect := queue_strip.get_global_rect() if queue_strip != null else Rect2()
	_check(
		dispatch_momentum != null
		and dispatch_momentum.is_visible_in_tree()
		and queue_strip != null
		and bool(queue_strip.get_meta("momentum_slot_active", false))
		and active_queue_rect.size.x >= idle_queue_rect.size.x + 130.0,
		"arming a tray should reveal the momentum cue and restore its dedicated strip space",
		failures,
	)
	var recommended_id := int(office.get("_dispatch_recommended_worker_id"))
	var recommended_view := (office.get("_worker_views") as Dictionary).get(recommended_id) as ChickenView
	var recommendation_handoff := (
		recommended_view.dispatch_candidate_snapshot()
		if recommended_view != null else
		{}
	)
	_check(
		recommended_view != null
		and bool(recommendation_handoff.get("recommended", false)),
		"the ranked best-fit hen should receive the gold dispatch marker",
		failures,
	)
	_check(
		int(recommendation_handoff.get("handoff_serial", 0)) == 1
		and bool(recommendation_handoff.get("handoff_active", false))
		and bool(recommendation_handoff.get("handoff_animated", false))
		and String(recommendation_handoff.get("handoff_lane", "")) == "nest_damage",
		"tray selection should energize the ranked hen's existing gold marker exactly once",
		failures,
	)
	var marked_candidate_count := 0
	for candidate in office.get("_dispatch_candidates") as Array[Dictionary]:
		var candidate_id := int(candidate.get("worker_id", -1))
		var candidate_view := (office.get("_worker_views") as Dictionary).get(candidate_id) as ChickenView
		if (
			candidate_view != null
			and bool(candidate_view.dispatch_candidate_snapshot().get("active", false))
		):
			marked_candidate_count += 1
	_check(
		marked_candidate_count == (office.get("_dispatch_candidates") as Array[Dictionary]).size()
		and marked_candidate_count > 1,
		"the recommendation handoff should leave every eligible alternative marked and valid",
		failures,
	)
	var camera_after := camera_controller.navigation_state() if camera_controller != null else {}
	_check(
		routing_ui != null and routing_ui.focused_worker_id() == -1
		and String(camera_after.get("mode", "")) == String(camera_before.get("mode", ""))
		and int(camera_after.get("focused_worker_id", -2)) == int(camera_before.get("focused_worker_id", -1))
		and camera_after.get("view_target", Vector3.ZERO) == camera_before.get("view_target", Vector3.ZERO),
		"the visual recommendation should not move focus, select a hen, or reframe the camera",
		failures,
	)
	_check(
		dispatch_save_after == dispatch_save_before,
		"selecting a tray and pulsing its recommendation should not mutate the authoritative save",
		failures,
	)
	var dispatch_diagnostic := office.call("_dispatch_diagnostic_state") as Dictionary
	var diagnostic_handoff := dispatch_diagnostic.get("recommendation_handoff", {}) as Dictionary
	_check(
		int(diagnostic_handoff.get("worker_id", -1)) == recommended_id
		and bool(diagnostic_handoff.get("handoff_active", false)),
		"browser diagnostics should expose the exact recommended hen handoff",
		failures,
	)
	var dispatch_accessibility := String(office.call(
		"_web_accessibility_summary",
		simulation.snapshot(),
	))
	_check(
		"Gold star" in dispatch_accessibility
		and "Other marked hens remain valid choices" in dispatch_accessibility,
		"assistive copy should name both the recommendation marker and retained player agency",
		failures,
	)
	if recommended_view != null:
		recommended_view.set_reduced_motion(true)
		recommended_view.play_dispatch_recommendation_handoff(&"nest_damage")
		var reduced_handoff := recommended_view.dispatch_candidate_snapshot()
		_check(
			int(reduced_handoff.get("handoff_serial", 0)) == 2
			and bool(reduced_handoff.get("handoff_active", false))
			and not bool(reduced_handoff.get("handoff_animated", true))
			and bool(reduced_handoff.get("marker_visible", false)),
			"reduced motion should retain one static gold recommendation receipt",
			failures,
		)
		await create_timer(0.38).timeout
		var settled_reduced_handoff := recommended_view.dispatch_candidate_snapshot()
		_check(
			not bool(settled_reduced_handoff.get("handoff_active", true))
			and bool(settled_reduced_handoff.get("marker_visible", false))
			and bool(settled_reduced_handoff.get("recommended", false)),
			"the static receipt should settle back to the persistent gold recommendation",
			failures,
		)
		recommended_view.set_reduced_motion(false)
	var workstation_feedback := office.get("_workstation_feedback") as WorkstationFeedback
	var dispatch_committed := bool(office.call("_commit_dispatch", recommended_id))
	await process_frame
	_check(dispatch_committed, "choosing the highlighted hen should file the authoritative route", failures)
	_check(StringName(office.get("_dispatch_lane")) == &"", "a filed route should leave dispatch mode cleanly", failures)
	var settled_queue_rect := queue_strip.get_global_rect() if queue_strip != null else Rect2()
	_check(
		dispatch_momentum != null
		and not dispatch_momentum.is_visible_in_tree()
		and settled_queue_rect.is_equal_approx(idle_queue_rect),
		"filing the first route should retire the transient cue and restore the clean idle strip",
		failures,
	)
	_check(
		recommended_view != null
		and not bool(recommended_view.dispatch_candidate_snapshot().get("active", true))
		and not bool(recommended_view.dispatch_candidate_snapshot().get("handoff_active", true))
		and not bool(recommended_view.dispatch_candidate_snapshot().get("marker_visible", true)),
		"a committed route should clean up the recommendation handoff and every dispatch marker",
		failures,
	)
	_check(
		workstation_feedback != null and workstation_feedback.active_dispatch_delivery_count() == 1,
		"a filed route should launch one physical folder toward the selected desk",
		failures,
	)
	_check(
		int((office.get("_dispatch_last_receipt") as Dictionary).get("momentum_chain", 0)) == 1,
		"the first best-fit dispatch should begin the visible fit chain",
		failures,
	)
	_check(
		status_toast_label != null
		and " > NEST" in status_toast_label.text
		and "FIT 1" in status_toast_label.text
		and "NEXT FILE READY" in status_toast_label.text
		and "BEST FIT" not in status_toast_label.text
		and "FROM NEST" not in status_toast_label.text
		and "Best-fit route filed:" in status_toast_label.tooltip_text
		and "Best-fit streak 1" in status_toast_label.tooltip_text
		and status_toast_label.accessibility_name == status_toast_label.tooltip_text,
		"the route receipt should use direction and outcome symbols while keeping the complete result accessible [text=%s tooltip=%s accessibility=%s]" % [
			status_toast_label.text if status_toast_label != null else "<missing>",
			status_toast_label.tooltip_text if status_toast_label != null else "<missing>",
			status_toast_label.accessibility_name if status_toast_label != null else "<missing>",
		],
		failures,
	)
	await create_timer(1.15).timeout
	_check(
		workstation_feedback != null and workstation_feedback.active_dispatch_delivery_count() == 0,
		"the delivered folder should clean itself up after reaching the desk",
		failures,
	)
	var first_landing := (
		workstation_feedback.dispatch_landing_snapshot()
		if workstation_feedback != null else
		{}
	)
	_check(
		bool(first_landing.get("active", false))
		and int(first_landing.get("serial", 0)) == 1
		and int(first_landing.get("worker_id", -1)) == recommended_id
		and String(first_landing.get("lane", "")) == "nest_damage"
		and bool(first_landing.get("recommended", false))
		and int(first_landing.get("fit_chain", 0)) == 1
		and String(first_landing.get("shape", "")) == "gold_star_stamp"
		and bool(first_landing.get("animated", false))
		and int(first_landing.get("active_count", 0)) == 1,
		"the physical folder should resolve into one exact gold-star stamp at its destination desk",
		failures,
	)
	_check(
		&"best_fit_filed" in routing_audio_cues,
		"the visible best-fit landing should own one synchronized paper-and-tray impact cue",
		failures,
	)
	var landing_diagnostic := office.call("_dispatch_diagnostic_state") as Dictionary
	_check(
		int((landing_diagnostic.get("landing", {}) as Dictionary).get("serial", 0)) == 1
		and bool((landing_diagnostic.get("landing", {}) as Dictionary).get("active", false)),
		"browser diagnostics should expose the same active desk-local landing receipt",
		failures,
	)
	var landing_accessibility := String(office.call(
		"_web_accessibility_summary",
		simulation.snapshot(),
	))
	_check(
		"Best-fit NEST file landed" in landing_accessibility
		and "Fit chain x1" in landing_accessibility,
		"assistive state should report the same landing, lane, and earned fit chain",
		failures,
	)
	var work_start_state := simulation.export_save_state()
	if recommended_view != null:
		recommended_view.stage_at_workstation_for_introduction()
		simulation.set_worker_at_workstation(recommended_id, true)
		simulation.advance_tick()
		office.call("_on_snapshot_changed", simulation.snapshot())
		await process_frame
	var recommended_work_row := (
		(simulation.snapshot().get("workers", []) as Array)[recommended_id] as Dictionary
	)
	_check(
		not (recommended_work_row.get("current_claim", {}) as Dictionary).is_empty()
		and int(recommended_work_row.get("state", 0)) == ChickenState.WorkState.WORKING,
		"the routed lane should pull a real claimant file before first-work feedback is eligible",
		failures,
	)
	_check(
		bool(office.call("_on_work_peck_contact", recommended_id, 901)),
		"the seated recommended hen should accept the exact first work contact",
		failures,
	)
	await create_timer(0.35).timeout
	var work_started_landing := (
		workstation_feedback.dispatch_landing_snapshot()
		if workstation_feedback != null else
		{}
	)
	_check(
		bool(work_started_landing.get("active", false))
		and bool(work_started_landing.get("work_started", false))
		and bool(work_started_landing.get("work_handoff_active", false))
		and bool(work_started_landing.get("work_handoff_animated", false))
		and String(work_started_landing.get("phase", "")) == "work_started"
		and int(work_started_landing.get("work_contact_serial", 0)) == 901
		and String(work_started_landing.get("work_handoff_shape", "")) == "stamp_to_screen"
		and int(work_started_landing.get("work_handoff_active_count", 0)) == 1,
		"the first real peck should carry the same gold stamp from the claim tray into the monitor contact",
		failures,
	)
	_check(
		&"best_fit_work_started" in routing_audio_cues,
		"the one-time route-to-work transition should own a restrained physical monitor cue",
		failures,
	)
	var work_started_accessibility := String(office.call(
		"_web_accessibility_summary",
		simulation.snapshot(),
	))
	_check(
		"began peckwork on the best-fit NEST file" in work_started_accessibility
		and "Fit chain x1" in work_started_accessibility,
		"assistive state should advance from landed file to the same worker's first peck",
		failures,
	)
	var action_worker := simulation.workers[recommended_id]
	action_worker.work_progress = DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS
	action_worker.current_claim.deadline_operational_minute = (
		simulation._current_operational_minute() + 35
	)
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	if routing_ui != null:
		# This scenario covers a live Priority Peck opportunity. The surrounding
		# integration fixture advances ticks manually and otherwise leaves its
		# presentation clock paused.
		routing_ui.set_peck_assist_clock_running(true)
	var progress_action_save_before := simulation.export_save_state()
	office.call("_on_work_progress_context_selected", recommended_id, &"work_progress")
	await process_frame
	var progress_action := office.get("_last_work_progress_action") as Dictionary
	var progress_dossier := routing_ui.context_action_state() if routing_ui != null else {}
	_check(
		int(progress_action.get("worker_id", -1)) == recommended_id
		and String(progress_action.get("rail_status", "")) == "deadline_risk"
		and String(progress_action.get("intent_id", "")) == "sync"
		and String(progress_action.get("action_id", "")) == "peck"
		and String(progress_action.get("target", "")) == "PeckAssistButton"
		and not bool(progress_action.get("economic_action_committed", true))
		and String(progress_dossier.get("active_tab", "")) == "route"
		and simulation.export_save_state() == progress_action_save_before,
		"selecting the urgent rail should open the exact Priority Peck remedy without auto-spending it [action=%s dossier=%s save_unchanged=%s]" % [
			str(progress_action),
			str(progress_dossier),
			str(simulation.export_save_state() == progress_action_save_before),
		],
		failures,
	)
	if workstation_feedback != null:
		workstation_feedback.set_reduced_motion(true)
		var reduced_landing := workstation_feedback.dispatch_landing_snapshot()
		_check(
			bool(reduced_landing.get("active", false))
			and bool(reduced_landing.get("work_handoff_active", false))
			and not bool(reduced_landing.get("work_handoff_animated", true))
			and int(reduced_landing.get("serial", 0)) == 1,
			"switching to reduced motion should preserve the same first-peck receipt at the monitor",
			failures,
		)
		_check(
			workstation_feedback.stage_dispatch_work_handoff_capture(recommended_id)
			and int(workstation_feedback.dispatch_landing_snapshot().get("capture_staged_count", 0)) == 1,
			"deterministic capture should hold the real static stamp-to-screen receipt without cloning it",
			failures,
		)
		_check(
			workstation_feedback.release_dispatch_work_handoff_capture(recommended_id)
			and workstation_feedback.finish_dispatch_landing(recommended_id)
			and workstation_feedback.active_dispatch_landing_count() == 0,
			"release and cleanup should retire the pooled route-to-work marker exactly once",
			failures,
		)
		workstation_feedback.set_reduced_motion(false)
	_check(
		simulation.restore_save_state(work_start_state),
		"the isolated first-work fixture should restore the exact routed simulation state",
		failures,
	)
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	if recommended_id >= 0:
		simulation.set_worker_assignment(recommended_id, &"auto")
		office.set("_routing_assignment_undo", {})
	await process_frame
	office.call("_on_dispatch_lane_requested", &"nest_damage")
	await process_frame
	var milestone_worker_id := int(office.get("_dispatch_recommended_worker_id"))
	var milestone_committed := bool(office.call("_commit_dispatch", milestone_worker_id))
	await process_frame
	_check(milestone_committed, "a second best-fit dispatch should reach the first skill milestone", failures)
	_check(
		dispatch_momentum != null and "PACE +15%" in dispatch_momentum.text,
		"the x2 milestone should surface its earned effect in the compact routing strip",
		failures,
	)
	var active_pace_snapshot := workstation_feedback.routing_pace_snapshot() if workstation_feedback != null else {}
	_check(
		bool(active_pace_snapshot.get("authoritative_active", false))
		and is_equal_approx(float(active_pace_snapshot.get("pace_multiplier", 0.0)), 1.15)
		and String(active_pace_snapshot.get("shape", "")) == "double_chevron",
		"the real x2 route should activate the desk-level pace feedback authority",
		failures,
	)
	await create_timer(0.86).timeout
	_check(
		workstation_feedback != null and workstation_feedback.active_routing_reward_burst_count() == 1,
		"the x2 folder landing should create one destination-local milestone icon",
		failures,
	)
	await create_timer(1.7).timeout
	_check(
		workstation_feedback != null and workstation_feedback.active_routing_reward_burst_count() == 0,
		"the routing milestone icon should clean itself up after its readable hold",
		failures,
	)
	# Deliberately choose a genuine non-recommended candidate while FIT x2 is
	# active. The authoritative break should explain both the loss and the exact
	# best-fit recovery action without opening another prose surface.
	office.call("_on_dispatch_lane_requested", &"appeals")
	await process_frame
	var poor_worker_id := -1
	var current_recommended_id := int(office.get("_dispatch_recommended_worker_id"))
	for candidate_value in office.get("_dispatch_candidates") as Array[Dictionary]:
		var candidate_id := int(candidate_value.get("worker_id", -1))
		if candidate_id >= 0 and candidate_id != current_recommended_id:
			poor_worker_id = candidate_id
			break
	_check(poor_worker_id >= 0, "the fixture should expose a real poor-fit dispatch choice", failures)
	if poor_worker_id >= 0:
		if simulation.workers[poor_worker_id].assigned_lane == &"appeals":
			simulation.set_worker_assignment(poor_worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
		var poor_committed := bool(office.call("_commit_dispatch", poor_worker_id))
		await process_frame
		_check(poor_committed, "poor fit should remain a valid routing judgment", failures)
		var poor_receipt := office.get("_dispatch_last_receipt") as Dictionary
		var break_receipt := poor_receipt.get("break", {}) as Dictionary
		_check(int(break_receipt.get("broken_chain", 0)) == 2, "UI should receive the exact lost FIT x2 chain", failures)
		var broken_pace_snapshot := workstation_feedback.routing_pace_snapshot() if workstation_feedback != null else {}
		_check(
			not bool(broken_pace_snapshot.get("authoritative_active", true))
			and int(broken_pace_snapshot.get("active_desk_count", -1)) == 0,
			"the same authoritative break should remove every workstation pace accent",
			failures,
		)
		_check(
			int(routing_ui.get_meta("dispatch_break_serial", 0)) == 1
			and bool(routing_ui.get_meta("dispatch_break_active", false)),
			"one authoritative loss should start one compact break presentation",
			failures,
		)
		_check(
			dispatch_break_glyph != null and dispatch_break_glyph.visible
			and "x2" in dispatch_momentum.text and ">  0" in dispatch_momentum.text,
			"the queue strip should show a shape-distinct broken link and x2 > 0 receipt",
			failures,
		)
		_check(
			"gold-star hen" in dispatch_momentum.tooltip_text,
			"progressive disclosure should name the exact recovery gesture",
			failures,
		)
		await create_timer(1.0).timeout
		var poor_landing := (
			workstation_feedback.dispatch_landing_snapshot()
			if workstation_feedback != null else
			{}
		)
		_check(
			bool(poor_landing.get("active", false))
			and not bool(poor_landing.get("recommended", true))
			and String(poor_landing.get("lane", "")) == "appeals"
			and String(poor_landing.get("shape", "")) == "file_check_stamp"
			and int(poor_landing.get("fit_chain", -1)) == 0,
			"a valid poor-fit route should land with a shape-distinct filing check, not a gold star",
			failures,
		)
		_check(
			&"file_routed" in routing_audio_cues,
			"ordinary route contact should remain audibly distinct from a best-fit filing",
			failures,
		)
		var poor_work_start_state := simulation.export_save_state()
		var poor_view := (office.get("_worker_views") as Dictionary).get(
			poor_worker_id,
		) as ChickenView
		if poor_view != null:
			poor_view.stage_at_workstation_for_introduction()
			simulation.set_worker_at_workstation(poor_worker_id, true)
			simulation.advance_tick()
			office.call("_on_snapshot_changed", simulation.snapshot())
			await process_frame
		_check(
			bool(office.call("_on_work_peck_contact", poor_worker_id, 902)),
			"the seated ordinary-route hen should accept the exact first work contact",
			failures,
		)
		await create_timer(0.45).timeout
		var poor_work_started := workstation_feedback.dispatch_landing_snapshot()
		_check(
			bool(poor_work_started.get("work_started", false))
			and bool(poor_work_started.get("work_handoff_active", false))
			and not bool(poor_work_started.get("recommended", true))
			and int(poor_work_started.get("work_contact_serial", 0)) == 902,
			"an ordinary route should use the same first-peck handoff without inventing a fit reward",
			failures,
		)
		_check(
			&"file_work_started" in routing_audio_cues,
			"ordinary first work should keep a distinct low-key physical cue",
			failures,
		)
		if workstation_feedback != null:
			workstation_feedback.finish_dispatch_landing(poor_worker_id)
		_check(
			simulation.restore_save_state(poor_work_start_state),
			"the ordinary first-work fixture should restore the exact broken-chain state",
			failures,
		)
		office.call("_on_snapshot_changed", simulation.snapshot())
		await process_frame
		_check(
			"NEXT FIT" in dispatch_momentum.text
			and dispatch_break_glyph != null and not dispatch_break_glyph.visible,
			"the broken-link impact should settle into one terse next-action cue",
			failures,
		)
		_check(
			routing_ui.stage_dispatch_break_capture()
			and bool(routing_ui.get_meta("dispatch_break_capture_staged", false)),
			"deterministic capture should hold the real break glyph without changing runtime timing",
			failures,
		)
		routing_ui.call("_finish_dispatch_break")
		routing_ui.set_reduced_motion(true)
		routing_ui.play_dispatch_break(break_receipt)
		_check(
			not bool(routing_ui.get_meta("dispatch_break_animated", true))
			and dispatch_break_glyph != null and dispatch_break_glyph.visible,
			"reduced motion should retain the semantic broken-link state without animation",
			failures,
		)
		routing_ui.call("_finish_dispatch_break")
		routing_ui.set_reduced_motion(false)

		# Correct the mistake through the real Office dispatch path. The first
		# best fit after this exact break should rejoin the same link at x1 once.
		office.call("_on_dispatch_lane_requested", &"predator_loss")
		await process_frame
		var recovery_worker_id := int(office.get("_dispatch_recommended_worker_id"))
		if (
			recovery_worker_id >= 0
			and simulation.workers[recovery_worker_id].assigned_lane == &"predator_loss"
		):
			simulation.set_worker_assignment(
				recovery_worker_id,
				DepartmentSimulation.AUTO_ASSIGNMENT,
			)
		var recovery_committed := bool(office.call("_commit_dispatch", recovery_worker_id))
		await process_frame
		var recovered_dispatch := office.get("_dispatch_last_receipt") as Dictionary
		var recovery_receipt := recovered_dispatch.get("recovery", {}) as Dictionary
		_check(recovery_committed, "a highlighted best fit should correct the broken route", failures)
		_check(
			int(recovery_receipt.get("break_serial", 0)) == int(break_receipt.get("serial", -1))
			and int(recovery_receipt.get("recovered_chain", 0)) == 1,
			"the UI path should retain the exact break it repaired and restart at x1",
			failures,
		)
		_check(
			bool(routing_ui.get_meta("dispatch_recovery_active", false))
			and int(routing_ui.get_meta("dispatch_recovery_authority_serial", 0)) == 1,
			"one authoritative correction should start one recovery presentation",
			failures,
		)
		_check(
			dispatch_break_glyph != null and dispatch_break_glyph.visible
			and StringName(dispatch_break_glyph.get_meta("mode", &"")) == &"recovery"
			and "FIT LINKED" in dispatch_momentum.text and "x1" in dispatch_momentum.text,
			"the broken link should visibly rejoin beside one terse x1 receipt",
			failures,
		)
		_check(
			String(recovery_receipt.get("worker_name", "")) in dispatch_momentum.tooltip_text,
			"progressive disclosure should identify the hen who corrected the route",
			failures,
		)
		_check(
			routing_ui.stage_dispatch_recovery_capture()
			and bool(routing_ui.get_meta("dispatch_recovery_capture_staged", false)),
			"deterministic capture should hold the real link-rejoin presentation",
			failures,
		)
		routing_ui.call("_finish_dispatch_recovery")
		routing_ui.set_reduced_motion(true)
		var reduced_recovery := recovery_receipt.duplicate(true)
		reduced_recovery["serial"] = int(recovery_receipt.get("serial", 0)) + 1
		_check(routing_ui.play_dispatch_recovery(reduced_recovery), "reduced-motion recovery fixture should be accepted once", failures)
		_check(
			not bool(routing_ui.get_meta("dispatch_recovery_animated", true))
			and dispatch_break_glyph != null and dispatch_break_glyph.visible
			and StringName(dispatch_break_glyph.get_meta("mode", &"")) == &"recovery",
			"reduced motion should retain the static semantic rejoined-link state",
			failures,
		)
		_check(
			not routing_ui.play_dispatch_recovery(reduced_recovery),
			"the same authoritative recovery receipt must not replay",
			failures,
		)
		routing_ui.set_dispatch_state(&"", 2)
		_check(
			not bool(routing_ui.get_meta("dispatch_recovery_active", true)),
			"the next chain step should immediately retire the recovery closure",
			failures,
		)
		routing_ui.set_dispatch_state(&"", 0)
		routing_ui.set_reduced_motion(false)
	if milestone_worker_id >= 0:
		simulation.set_worker_assignment(milestone_worker_id, &"auto")
		office.set("_routing_assignment_undo", {})
	await process_frame
	if routing_ui != null:
		routing_ui.set_color_vision_mode(&"color_blind_safe")
	await process_frame
	_check(
		nest_queue != null and nest_queue_icon != null and nest_queue_icon.is_visible_in_tree()
		and predator_queue != null and predator_queue_icon != null and predator_queue_icon.is_visible_in_tree()
		and appeals_queue != null and appeals_queue_icon != null and appeals_queue_icon.is_visible_in_tree()
		and String(nest_queue_icon.get_meta("semantic_icon", "")) == "lane_nest"
		and String(predator_queue_icon.get_meta("semantic_icon", "")) == "lane_predator"
		and String(appeals_queue_icon.get_meta("semantic_icon", "")) == "lane_appeals"
		and nest_dispatch_tray != null and "NEST" in nest_dispatch_tray.accessibility_name,
		"safe color-vision mode should preserve shape-distinct lanes and complete accessible names",
		failures,
	)
	_check(
		nest_queue != null and nest_queue.get_theme_color("font_color").is_equal_approx(Palette.lane_color(&"nest_damage", &"color_blind_safe")),
		"safe routing text should use the centralized semantic palette",
		failures,
	)
	var queue_rect := queue_strip.get_global_rect() if queue_strip != null else Rect2()
	for label in [nest_queue, predator_queue, appeals_queue]:
		_check(
			label != null and label.get_global_rect().end.x <= queue_rect.end.x + 0.5,
			"safe routing markers should remain contained by the queue strip",
			failures,
		)
	_check(assign_predator != null and assign_predator.text == "[P] PREDATOR", "safe assignment controls should pair the lane marker with a concise route action", failures)
	if routing_ui != null:
		routing_ui.set_color_vision_mode(&"standard")
	await process_frame
	var specialty_fit_button_count := 0
	for assignment_button: Button in [assign_nest, assign_predator, assign_appeals]:
		if (
			assignment_button != null
			and assignment_button.text.ends_with("  FIT")
			and bool(assignment_button.get_meta("specialty_match", false))
		):
			specialty_fit_button_count += 1
	_check(
		assign_auto != null and assign_auto.text == "AUTO"
		and assign_nest != null and assign_nest.text.begins_with("NEST")
		and assign_predator != null and assign_predator.text.begins_with("PREDATOR")
		and assign_appeals != null and assign_appeals.text.begins_with("APPEALS")
		and specialty_fit_button_count == 1,
		"routing controls should remain concise while marking the selected hen's one credentialed fit",
		failures,
	)
	_check(
		assign_auto != null and assign_auto.icon != null
		and assign_nest != null and assign_nest.icon != null
		and assign_predator != null and assign_predator.icon != null
		and assign_appeals != null and assign_appeals.icon != null
		and String(assign_auto.get_meta("semantic_icon", "")) == "order_trays"
		and String(assign_nest.get_meta("semantic_icon", "")) == "lane_nest"
		and String(assign_predator.get_meta("semantic_icon", "")) == "lane_predator"
		and String(assign_appeals.get_meta("semantic_icon", "")) == "lane_appeals"
		and assign_auto.icon_alignment == HORIZONTAL_ALIGNMENT_LEFT
		and assign_nest.icon_alignment == HORIZONTAL_ALIGNMENT_LEFT
		and assign_predator.icon_alignment == HORIZONTAL_ALIGNMENT_LEFT
		and assign_appeals.icon_alignment == HORIZONTAL_ALIGNMENT_LEFT,
		"route choices should carry four persistent, shape-distinct lane marks",
		failures,
	)
	var route_choice_state := routing_ui.routing_choice_state() if routing_ui != null else {}
	var route_choice_rows := route_choice_state.get("choices", []) as Array
	var complete_marked_route_count := 0
	for route_choice: Dictionary in route_choice_rows:
		if (
			bool(route_choice.get("icon_visible", false))
			and not String(route_choice.get("semantic_icon", "")).is_empty()
			and not String(route_choice.get("accessible_text", "")).is_empty()
		):
			complete_marked_route_count += 1
	_check(
		route_choice_rows.size() == 4
		and bool(route_choice_state.get("visible", false))
		and String(route_choice_state.get("shape_language", "")).contains("fox=predator")
		and complete_marked_route_count == 4,
		"route-choice diagnostics should expose every visible mark and its complete action name",
		failures,
	)
	_check(
		assign_nest != null and "NEST DAMAGE." in assign_nest.tooltip_text and "+0.6 handler morale" in assign_nest.tooltip_text
		and assign_predator != null and "PREDATOR LOSS." in assign_predator.tooltip_text and "stress accumulates 25% faster" in assign_predator.tooltip_text
		and assign_appeals != null and "APPEALS." in assign_appeals.tooltip_text and "+0.7 audit order" in assign_appeals.tooltip_text,
		"concise routing actions should retain each full lane and claimant-path consequence on inspection",
		failures,
	)

	if routing_ui != null:
		routing_ui.set_focus(0)
	await process_frame
	_check(dossier != null and dossier.is_visible_in_tree(), "selecting a hen should open her routing dossier", failures)
	var compact_dossier := routing_ui.compact_dossier_state() if routing_ui != null else {}
	_check(
		bool(compact_dossier.get("visible", false))
		and int(compact_dossier.get("field_count", 0)) == 4
		and bool(compact_dossier.get("details_on_demand", false))
		and dossier_summary != null
		and _contains_all(dossier_summary.text, ["need", "next"])
		and details_toggle != null
		and details_toggle.text == "MORE",
		"a newly selected hen should open as a concise name, specialty, need, and next-action card",
		failures,
	)
	_check(_press(details_toggle), "More should reveal the complete selected-hen dossier", failures)
	await process_frame
	_check(
		routing_ui != null
		and routing_ui.active_dossier_tab() == &"route"
		and route_tab != null
		and route_tab.button_pressed,
		"a newly selected hen should open on the Route dossier tab",
		failures,
	)
	_check(
		route_tab != null and route_tab.icon != null
		and claim_tab != null and claim_tab.icon != null
		and support_tab != null and support_tab.icon != null
		and profile_tab != null and profile_tab.icon != null
		and String(route_tab.get_meta("semantic_icon", "")) == "order_trays"
		and String(claim_tab.get_meta("semantic_icon", "")) == "requisitions"
		and String(support_tab.get_meta("semantic_icon", "")) == "receipt_flock"
		and String(profile_tab.get_meta("semantic_icon", "")) == "rank_crest"
		and route_tab.text == "ROUTE"
		and claim_tab.text == "FILE"
		and support_tab.text == "CARE"
		and profile_tab.text == "BIO"
		and support_tab.accessibility_name.begins_with("Support and care tab.")
		and profile_tab.accessibility_name.begins_with("Hen profile tab.")
		and route_tab.icon_alignment == HORIZONTAL_ALIGNMENT_LEFT
		and claim_tab.icon_alignment == HORIZONTAL_ALIGNMENT_LEFT
		and support_tab.icon_alignment == HORIZONTAL_ALIGNMENT_LEFT
		and profile_tab.icon_alignment == HORIZONTAL_ALIGNMENT_LEFT,
		"dossier destinations should carry four persistent, shape-distinct marks",
		failures,
	)
	var dossier_tab_state := routing_ui.dossier_tab_state() if routing_ui != null else {}
	var dossier_tab_rows := dossier_tab_state.get("tabs", []) as Array
	var complete_dossier_tab_count := 0
	for dossier_tab: Dictionary in dossier_tab_rows:
		if (
			bool(dossier_tab.get("icon_visible", false))
			and not String(dossier_tab.get("semantic_icon", "")).is_empty()
			and not String(dossier_tab.get("accessible_text", "")).is_empty()
		):
			complete_dossier_tab_count += 1
	_check(
		dossier_tab_rows.size() == 4
		and bool(dossier_tab_state.get("visible", false))
		and String(dossier_tab_state.get("active_tab", "")) == "route"
		and String(dossier_tab_state.get("shape_language", "")).contains("crest=profile")
		and complete_dossier_tab_count == 4,
		"dossier-tab diagnostics should expose every visible mark and complete destination name",
		failures,
	)
	_check(assign_auto != null and assign_auto.is_visible_in_tree() and not assign_auto.disabled, "the Route tab should expose live routing", failures)
	_check(
		worker_profile_icon != null and worker_profile_icon.texture != null
		and worker_specialty_icon != null and worker_specialty_icon.texture != null
		and worker_profile_icon.is_visible_in_tree()
		and worker_specialty_icon.is_visible_in_tree()
		and String(worker_profile_icon.get_meta("semantic_icon", "")) == "rank_crest"
		and String(worker_specialty_icon.get_meta("semantic_icon", "")) == "lane_appeals"
		and String(worker_specialty_icon.get_meta("specialty_lane", "")) == "appeals",
		"selected-hen identity should pair a credential crest with Mabel's shape-distinct specialty mark",
		failures,
	)
	var selected_identity_state := (
		routing_ui.selected_hen_identity_state() if routing_ui != null else {}
	)
	_check(
		bool(selected_identity_state.get("visible", false))
		and bool(selected_identity_state.get("profile_icon_visible", false))
		and bool(selected_identity_state.get("specialty_icon_visible", false))
		and String(selected_identity_state.get("profile_icon", "")) == "rank_crest"
		and String(selected_identity_state.get("specialty_icon", "")) == "lane_appeals"
		and String(selected_identity_state.get("specialty_lane", "")) == "appeals"
		and not String(selected_identity_state.get("accessible_text", "")).is_empty()
		and String(selected_identity_state.get("shape_language", "")).contains("crest=work profile"),
		"selected-hen identity diagnostics should expose both visible marks and the complete character description",
		failures,
	)
	var opening_worker := _worker_snapshot(simulation.snapshot(), 0)
	if (opening_worker.get("current_claim", {}) as Dictionary).is_empty():
		var claimant_snapshot := simulation.snapshot().duplicate(true)
		var claimant_workers := (
			claimant_snapshot.get("workers", []) as Array
		).duplicate(true)
		var claimant_worker := (
			claimant_workers[0] as Dictionary
		).duplicate(true)
		var claimant_claim := ClaimState.new(
			9001,
			&"appeals",
			"APPEALS & EXCEPTIONS",
			1.3,
			820,
			0.055,
			0,
			360,
			360,
		)
		claimant_worker["current_claim"] = claimant_claim.snapshot(60)
		claimant_worker["progress"] = 12.0
		claimant_worker["estimated_crack_risk"] = 0.18
		claimant_worker["claim_resolution_status"] = {
			"available": true,
			"reason": "",
			"claim_id": claimant_claim.id,
			"progress": 12.0,
			"cutoff_progress": 55.0,
		}
		claimant_workers[0] = claimant_worker
		claimant_snapshot["workers"] = claimant_workers
		routing_ui.apply_snapshot(claimant_snapshot)
		await process_frame
		opening_worker = _worker_snapshot(claimant_snapshot, 0)
	var opening_claim := opening_worker.get("current_claim", {}) as Dictionary
	_check(
		not opening_claim.is_empty(),
		"the focused hen should hold a real file for claimant-path inspection",
		failures,
	)
	_check(worker_career != null and not worker_career.is_visible_in_tree(), "the Route tab should not repeat Profile career details", failures)
	_check(share_credit != null and not share_credit.is_visible_in_tree(), "the Route tab should not mix in Support actions", failures)
	_check(_press(claim_tab), "the selected-hen dossier should expose its File tab", failures)
	await process_frame
	_check(
		routing_ui != null
		and routing_ui.active_dossier_tab() == &"claim"
		and claim_tab != null
		and claim_tab.button_pressed,
		"File should become the single active dossier tab",
		failures,
	)
	var exact_claim_id := int(opening_claim.get("id", -1))
	var claim_save_before := simulation.export_save_state()
	var arrival_before := routing_ui.claim_file_arrival_state()
	var exact_claim_target := routing_ui.focus_claim_file(exact_claim_id)
	var exact_arrival := routing_ui.claim_file_arrival_state()
	_check(
		exact_claim_target != null
		and routing_ui.active_dossier_tab() == &"claim"
		and bool(exact_arrival.get("active", false))
		and int(exact_arrival.get("claim_id", -1)) == exact_claim_id
		and int(exact_arrival.get("serial", 0)) == int(arrival_before.get("serial", 0)) + 1
		and simulation.export_save_state() == claim_save_before,
		"an exact live claim receipt should acknowledge that File without filing a claimant path",
		failures,
	)
	var stale_claim_target := routing_ui.focus_claim_file(exact_claim_id + 10000)
	var stale_arrival := routing_ui.claim_file_arrival_state()
	_check(
		stale_claim_target == null
		and not bool(stale_arrival.get("active", true))
		and int(stale_arrival.get("serial", 0)) == int(exact_arrival.get("serial", 0))
		and simulation.export_save_state() == claim_save_before,
		"a stale claim receipt should cancel exact-file emphasis without substituting a newer file or mutating gameplay",
		failures,
	)
	var hen_dossier_target := routing_ui.focus_hen_dossier(0)
	var hen_dossier_arrival := routing_ui.hen_dossier_arrival_state()
	_check(
		hen_dossier_target != null
		and routing_ui.active_dossier_tab() == &"route"
		and bool(hen_dossier_arrival.get("active", false))
		and int(hen_dossier_arrival.get("worker_id", -1)) == 0
		and int(hen_dossier_arrival.get("serial", 0)) == 1
		and simulation.export_save_state() == claim_save_before,
		"a hen-level receipt fallback should acknowledge the Route dossier without mutating gameplay",
		failures,
	)
	routing_ui.set_reduced_motion(true)
	var reduced_claim_target := routing_ui.focus_claim_file(exact_claim_id)
	var reduced_arrival := routing_ui.claim_file_arrival_state()
	_check(
		reduced_claim_target != null
		and not bool(routing_ui.hen_dossier_arrival_state().get("active", true))
		and bool(reduced_arrival.get("active", false))
		and not bool(reduced_arrival.get("animated", true))
		and bool(reduced_arrival.get("reduced_motion", false))
		and simulation.export_save_state() == claim_save_before,
		"reduced motion should keep a brief static exact-File acknowledgment without mutating gameplay",
		failures,
	)
	routing_ui.set_reduced_motion(false)
	_check(
		dossier_summary != null
		and dossier_summary.is_visible_in_tree()
		and String(opening_claim.get("claimant_name", "")) in dossier_summary.text
		and String(opening_claim.get("claimant_incident", "")) in dossier_summary.text
		and String(opening_claim.get("claimant_need", "")) in dossier_summary.text
		and String(opening_claim.get("claimant_delay_cost", "")) in dossier_summary.text,
		"File should disclose who claimed, what happened, what they need, and what delay costs",
		failures,
	)
	_check(
		settle_claim != null
		and settle_claim.is_visible_in_tree()
		and "$1.20" in settle_claim.text
		and "CLAIMANT RECEIVES THE BENEFIT" in settle_claim.tooltip_text
		and "-3%" in settle_claim.tooltip_text,
		"Settlement should disclose its exact money, beneficiary, and shell benefit",
		failures,
	)
	_check(
		deny_claim != null
		and deny_claim.is_visible_in_tree()
		and "$0.00" in deny_claim.text
		and "BUREAU RECEIVES THE BENEFIT" in deny_claim.tooltip_text
		and "appeal tomorrow" in deny_claim.tooltip_text,
		"Denial should disclose its tempting pace benefit and delayed claimant burden",
		failures,
	)
	_check(
		except_claim != null
		and except_claim.is_visible_in_tree()
		and "$0.60" in except_claim.text
		and "-6%" in except_claim.tooltip_text,
		"Coverage Exception should disclose its exact cost and slower careful handling",
		failures,
	)
	if routing_ui != null:
		routing_ui.apply_snapshot(simulation.snapshot())
	_check(_press(support_tab), "the selected-hen dossier should expose its Support tab", failures)
	await process_frame
	_check(
		routing_ui != null
		and routing_ui.active_dossier_tab() == &"support"
		and support_tab != null
		and support_tab.button_pressed,
		"Support should become the single active dossier tab",
		failures,
	)
	_check(check_in_status != null and check_in_status.is_visible_in_tree() and "READY" in check_in_status.text, "Support should own the personnel check-in status", failures)
	_check(share_credit != null and share_credit.is_visible_in_tree() and not share_credit.disabled, "Support should own the live share-credit action", failures)
	_check(
		dossier_summary != null
		and dossier_summary.is_visible_in_tree()
		and "PROFILE FIT  /  SHARE CREDIT" in dossier_summary.text
		and "-$7.00" in dossier_summary.text
		and String(opening_worker.get("career_profile_description", "")) in dossier_summary.text,
		"Support should use the open dossier space for the exact profile-fit consequence instead of hiding it in a tooltip",
		failures,
	)
	_check(assign_auto != null and not assign_auto.is_visible_in_tree(), "Support should not mix in Route actions", failures)
	_check(_press(profile_tab), "the selected-hen dossier should expose its Profile tab", failures)
	await process_frame
	_check(
		routing_ui != null
		and routing_ui.active_dossier_tab() == &"profile"
		and profile_tab != null
		and profile_tab.button_pressed,
		"Profile should become the single active dossier tab",
		failures,
	)
	_check(worker_career != null and worker_career.is_visible_in_tree(), "Profile should expose career rank and XP", failures)
	_check(worker_career != null and String(opening_worker.get("career_title", "")) in worker_career.text, "career label should mirror the authoritative worker title", failures)
	_check(worker_career != null and "XP" in worker_career.text, "career label should make progression legible", failures)
	_check(worker_profile != null and worker_profile.is_visible_in_tree(), "Profile should expose the career profile", failures)
	_check(worker_profile != null and String(opening_worker.get("career_profile_name", "")) in worker_profile.text, "profile label should mirror the authoritative worker profile", failures)
	_check(manager_trust != null and manager_trust.is_visible_in_tree() and "TRUST  %d" % int(roundf(float(opening_worker.get("manager_trust", -1.0)))) in manager_trust.text, "Profile should show authoritative manager trust", failures)
	_check(grievance != null and grievance.is_visible_in_tree() and "GRIEVANCE  %d" % int(roundf(float(opening_worker.get("grievance", -1.0)))) in grievance.text, "Profile should show authoritative grievance", failures)
	_check(
		dossier_summary != null
		and dossier_summary.is_visible_in_tree()
		and String(opening_worker.get("career_profile_name", "")).to_upper() in dossier_summary.text
		and String(opening_worker.get("temperament_label", "")) in dossier_summary.text
		and String(((opening_worker.get("temperament_effect", {}) as Dictionary).get("label", ""))) in dossier_summary.text
		and String(((opening_worker.get("temperament_effect", {}) as Dictionary).get("summary", ""))) in dossier_summary.text
		and String(((opening_worker.get("flock_bond", {}) as Dictionary).get("partner_name", ""))) in dossier_summary.text
		and "TEMPERAMENT" in dossier_summary.text
		and "FLOCK BOND" in dossier_summary.text
		and "CARE  morale" in dossier_summary.text
		and "shell risk" in dossier_summary.text,
		"Profile should fill the dossier with exact work-style terms, perchmate bond, and care state",
		failures,
	)
	_check(assign_auto != null and not assign_auto.is_visible_in_tree(), "Profile should not mix in Route actions", failures)
	_check(share_credit != null and not share_credit.is_visible_in_tree(), "Profile should not mix in Support actions", failures)
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
	_check(_press(route_tab), "the dossier should return from Profile to Route", failures)
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
	_set_worker_fixture(manual_snapshot, 0, {
		"assigned_lane": &"predator_loss",
		"assignment": &"predator_loss",
		"specialty": &"appeals",
		"secondary_specialty": &"",
	})
	if routing_ui != null:
		routing_ui.apply_snapshot(manual_snapshot)
	await process_frame
	_check(automation_hint != null and _contains_all(automation_hint.text, ["off-fit route", "no auto bonus"]), "an out-of-specialty manual tray should lead with its fit tradeoff", failures)
	_check(automation_hint != null and _contains_all(automation_hint.tooltip_text, ["explicit override", "do not apply", "raises time and shell risk"]), "off-fit manual routing should retain exact automation and route-risk consequences", failures)

	var manual_fit_snapshot := auto_snapshot.duplicate(true)
	_set_worker_fixture(manual_fit_snapshot, 0, {
		"assigned_lane": &"appeals",
		"assignment": &"appeals",
		"specialty": &"appeals",
		"secondary_specialty": &"",
	})
	if routing_ui != null:
		routing_ui.apply_snapshot(manual_fit_snapshot)
	await process_frame
	_check(automation_hint != null and _contains_all(automation_hint.text, ["fit route", "no auto bonus"]) and not "off-fit" in automation_hint.text.to_lower(), "a specialty-fit manual tray should show both its fit and AUTO tradeoff", failures)
	_check(automation_hint != null and _contains_all(automation_hint.tooltip_text, ["explicit override", "do not apply", "matches a filed specialty"]), "fit manual routing should retain exact automation and specialty consequences", failures)

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
	_check(_press(support_tab), "Support should remain reachable after routing snapshots refresh", failures)
	await process_frame
	_check(check_in_status != null and check_in_status.is_visible_in_tree() and "READY" in check_in_status.text, "personnel check-in should become ready on Support during the running shift", failures)
	_check(share_credit != null and share_credit.is_visible_in_tree() and not share_credit.disabled, "share-credit action should unlock on Support during the running shift", failures)
	_check(career_coaching != null and career_coaching.is_visible_in_tree() and not career_coaching.disabled, "career-coaching action should unlock on Support during the running shift", failures)
	_check(quota_pressure != null and quota_pressure.is_visible_in_tree() and not quota_pressure.disabled, "quota-pressure action should unlock on Support during the running shift", failures)

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
	_check(_press(support_tab), "changing hens should still leave Support one selection away", failures)
	await process_frame
	_check(check_in_status != null and _contains_all(check_in_status.text, ["check-in ready", "1 of 2", "1 left"]), "another hen should see the exact remaining Rooster Office allowance", failures)
	_check(share_credit != null and not share_credit.disabled, "the first filed action must not globally lock a larger Rooster Office allowance", failures)
	if routing_ui != null:
		routing_ui.apply_snapshot(simulation.snapshot())
		routing_ui.set_focus(0)
	_check(_press(support_tab), "returning to Mabel should allow Support to reopen", failures)
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
	_check(_press(support_tab), "the second hen should expose the same Support contract", failures)
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
	_check(_press(details_toggle), "More should restore file progress controls after changing hens", failures)
	await process_frame

	if assign_predator != null:
		assign_predator.pressed.emit()
	await process_frame
	var tactical_plan := office.call("_tactical_route_plan_snapshot") as Dictionary
	_check(
		int(tactical_plan.get("count", 0)) == 1
		and bool(tactical_plan.get("files_nothing", false)),
		"a paused dossier route should remain an unfiled tactical preview until Resume",
		failures,
	)
	if int(tactical_plan.get("count", 0)) > 0:
		office.call("_on_speed_button_pressed", 1)
		var simulation_clock = office.get("_clock")
		if simulation_clock != null:
			simulation_clock.set_speed(0)
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
	_check(
		current_claim != null
		and current_claim.text.begins_with("PREDATOR LOSS #")
		and "PECKING" not in current_claim.text
		and claim_phase_icon != null
		and claim_phase_icon.is_visible_in_tree()
		and claim_phase_icon.texture != null
		and String(claim_phase_icon.get_meta("semantic_shape", "")) == "work_dial"
		and int(claim_phase_icon.get_meta("progress_bucket", -1)) >= 0
		and claim_phase_progress != null
		and claim_phase_progress.is_visible_in_tree()
		and claim_phase_progress.text.ends_with("%")
		and "Step 2, peckwork" in current_claim.accessibility_name
		and "percent complete" in current_claim.accessibility_name
		and claim_phase_icon.accessibility_name == current_claim.accessibility_name
		and current_claim.tooltip_text == current_claim.accessibility_name,
		"the dossier should pair file identity with a progress dial while retaining its exact work phase",
		failures,
	)
	var active_claim_facts := (
		claim_detail.get_meta("facts", []) as Array
		if claim_detail != null else
		[]
	)
	_check(
		claim_detail != null
		and claim_detail.is_visible_in_tree()
		and active_claim_facts.size() == 4
		and String((active_claim_facts[0] as Dictionary).get("role", "")) == "deadline"
		and "M" in String((active_claim_facts[0] as Dictionary).get("value", ""))
		and String((active_claim_facts[1] as Dictionary).get("icon", "")) == "cash"
		and String((active_claim_facts[2] as Dictionary).get("icon", "")) == "shell_risk"
		and String((active_claim_facts[3] as Dictionary).get("value", "")) == "EGG"
		and ("Due in" in claim_detail.accessibility_name or "Overdue by" in claim_detail.accessibility_name)
		and "Estimated shell crack risk" in claim_detail.accessibility_name
		and "lay the egg" in claim_detail.accessibility_name
		and claim_detail.tooltip_text == claim_detail.accessibility_name,
		"active file facts should expose an icon-led deadline-value-risk-outcome strip with complete semantics (facts=%s accessible=%s)" % [
			JSON.stringify(active_claim_facts),
			claim_detail.accessibility_name if claim_detail != null else "<missing>",
		],
		failures,
	)
	var authoritative_predator_count := simulation.claim_queue_count(&"predator_loss")
	_check(
		predator_queue != null
		and predator_queue.text.begins_with(str(authoritative_predator_count))
		and predator_queue_icon != null
		and predator_queue_icon.is_visible_in_tree()
		and String(predator_queue_icon.get_meta("semantic_icon", "")) == "lane_predator",
		"queue strip should react when a file enters peckwork",
		failures,
	)

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
		var lifecycle_state := routing_ui.routing_lifecycle_state() if routing_ui != null else {}
		_check(
			bool(lifecycle_state.get("dossier_visible", false))
			and bool(lifecycle_state.get("dossier_contained", false))
			and float((lifecycle_state.get("dossier_rect", {}) as Dictionary).get("height", 0.0)) > 0.0,
			"routing diagnostics should prove the visible dossier is contained in the game stage",
			failures,
		)

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
	var dialogue_ui = office.get("_character_dialogue_ui")
	if dialogue_ui != null and dialogue_ui.has_blocking_dialogue():
		dialogue_ui.dismiss_current()
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
