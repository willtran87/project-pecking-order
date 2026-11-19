extends RefCounted

## Loaded only for explicit preview/capture requests. Normal careers never
## parse these authored test scenarios during engine initialization.
var office: Office

func _init(target: Office) -> void:
	office = target


func _capture_preview() -> void:
	_prepare_capture_running()
	# Allow the staggered morning walk to resolve so the capture shows seated work animation.
	await office.get_tree().create_timer(5.5).timeout
	_save_preview("vertical_slice.png")


func _capture_decision_preview() -> void:
	# Give the widened three-card briefing two settled frames plus enough time for
	# the Web/native font atlas to finish populating every compact chip label.
	await office.get_tree().process_frame
	await office.get_tree().process_frame
	await office.get_tree().create_timer(1.2).timeout
	_save_preview("morning_directive.png")


func _capture_action_feedback_preview() -> void:
	await office.get_tree().process_frame
	var option := office.find_child("DecisionOption_shell_assurance", true, false) as Button
	var confirm := office.find_child("ConfirmDecisionButton", true, false) as Button
	if option != null and confirm != null:
		option.pressed.emit()
		confirm.pressed.emit()
	await office.get_tree().create_timer(0.34).timeout
	_save_preview("action_feedback.png")


func _capture_incident_preview(selected := false) -> void:
	_prepare_capture_running()
	office._simulation.minute_of_day = DepartmentSimulation.INCIDENT_MINUTES[0] - DepartmentSimulation.MINUTES_PER_TICK
	office._simulation.advance_tick()
	if selected:
		await office.get_tree().process_frame
		var option := office.find_child("DecisionOption_spreadsheet", true, false) as Button
		if option != null:
			option.pressed.emit()
	await office.get_tree().create_timer(0.8).timeout
	_save_preview(
		"incident_decision_selected.png"
		if selected else
		"incident_decision.png"
	)


func _capture_petition_preview() -> void:
	_prepare_capture_running()
	office._simulation.day = 2
	var sponsor_id := 0
	for worker in office._simulation.workers:
		if worker.employed and worker.career_profile == &"credit_conscious":
			sponsor_id = worker.id
			break
	office._simulation.last_credit_allocation = {
		"day": 1,
		"style_id": "management_innovation",
		"worker_id": sponsor_id,
		"worker_name": office._simulation.workers[sponsor_id].display_name,
	}
	office._simulation._incident_slot = 1
	office._simulation.minute_of_day = DepartmentSimulation.INCIDENT_MINUTES[1] - DepartmentSimulation.MINUTES_PER_TICK
	office._simulation.advance_tick()
	await office.get_tree().create_timer(0.8).timeout
	_save_preview("flock_petition.png")


func _capture_flock_labor_preview() -> void:
	_prepare_capture_running()
	var sponsor = office._simulation.workers[0]
	office._simulation.active_flock_compact = {
		"compact_id": "CAPTURE-SAFE-PACE",
		"petition_day": 0,
		"effective_day": office._simulation.day,
		"status": "active",
		"petition_type": "safe_pace",
		"compact_name": "SAFE PECKING COMPACT",
		"sponsor_worker_id": sponsor.id,
		"sponsor_worker_name": sponsor.display_name,
		"promise": "Keep overtime off and file no quota-pressure check-in.",
		"condition": "Close without overtime or quota pressure.",
	}
	office._simulation.solidarity = 58.0
	office._simulation.work_to_rule_day = office._simulation.day
	office._simulation.last_work_to_rule_record = {
		"status": "active",
		"effective_day": office._simulation.day,
		"sponsor_worker_id": sponsor.id,
		"sponsor_worker_name": sponsor.display_name,
		"work_multiplier": 0.82,
		"crack_modifier": -0.06,
	}
	office._on_snapshot_changed(office._simulation.snapshot())
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_TODAY)
	await office.get_tree().create_timer(0.55).timeout
	_save_preview("flockwatch_labor.png")


func _capture_economic_break_even_preview() -> void:
	_prepare_capture_running()
	office._set_flockwatch_open(true)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_TODAY)
	var operating_cost := office._simulation.current_daily_operating_cost_cents()
	office._simulation.credited_today_cents = maxi(0, operating_cost - 100)
	office._apply_snapshot_presentation(office._simulation.snapshot())
	office._simulation.credited_today_cents = operating_cost + 500
	office._apply_snapshot_presentation(office._simulation.snapshot())
	await office.get_tree().create_timer(0.55).timeout
	_save_preview("economic_break_even.png")


func _capture_ledger_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(1.0).timeout
	office._simulation.purchase_upgrade(&"peckwork_tools")
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_CAPITAL)
	await office.get_tree().create_timer(0.45).timeout
	_save_preview("requisitions.png")


func _capture_capacity_commissioning_preview() -> void:
	_prepare_capture_running()
	office._set_flockwatch_open(false)
	await office.get_tree().create_timer(0.55).timeout
	var upgrade := office._simulation.capacity_upgrade_status()
	office._apply_office_capacity_visibility(5, true)
	office._begin_capacity_commissioning_beat({
		"office_capacity": 5,
		"cost_cents": int(upgrade.get("cost_cents", 0)),
		"added_daily_operating_cents": int(upgrade.get("added_daily_operating_cents", 0)),
	})
	if office._camera_controller != null:
		office._camera_controller.focus_point(
			office.desk_position(4) + Vector3.UP * 1.0,
			"PERCH 5 COMMISSIONED",
			0.32,
			8.8,
		)
	await office.get_tree().create_timer(0.42).timeout
	_save_preview("capacity_commissioning.png")


func _capture_day_review_preview(expand_details := false, max_interface_scale := false) -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(0.8).timeout
	office._simulation.perform_personnel_action(0, &"share_credit")
	office._simulation.eggs_today = office._simulation.quota_target + 3
	office._simulation.cracked_today = 2
	office._simulation.golden_today = 1
	office._simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	office._simulation._incident_slot = DepartmentSimulation.INCIDENT_MINUTES.size()
	office._simulation.advance_tick()
	await office.get_tree().create_timer(0.65).timeout
	if expand_details:
		office._set_review_details_expanded(true)
		await office.get_tree().process_frame
	if max_interface_scale:
		office._player_preferences["ui_scale"] = 1.5
		office._apply_management_ui_preferences()
		await office.get_tree().process_frame
		await office.get_tree().process_frame
	_save_preview(
		"day_review_details.png"
		if expand_details else
		("day_review_max_scale.png" if max_interface_scale else "day_review.png")
	)


func _capture_feed_party_preview() -> void:
	_prepare_capture_running()
	office._simulation.fund_feed_party()
	# Immediate funding queues late arrivals safely behind their morning walk. Wait
	# for the authoritative ready callbacks so the image shows every on-site hen feeding.
	var deadline_msec := Time.get_ticks_msec() + 45000
	while office._feed_party_arrivals.size() < office._feed_party_expected_attendees.size() and Time.get_ticks_msec() < deadline_msec:
		await office.get_tree().process_frame
	if office._feed_party_arrivals.size() < office._feed_party_expected_attendees.size():
		push_warning("Feed-party capture timed out with %d/%d attendees." % [office._feed_party_arrivals.size(), office._feed_party_expected_attendees.size()])
	if office._camera_controller != null:
		office._camera_controller.show_event_focus(
			office.FEED_PARTY_STATION_POSITION + Vector3.UP * 0.72,
			"FEED PARTY ART CHECK",
			2.0,
			true,
		)
	await office.get_tree().create_timer(0.8).timeout
	_save_preview("feed_party.png")


func _capture_fund_debit_preview() -> void:
	_prepare_capture_running()
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_CAPITAL)
	if office._upgrade_disclosure_toggle != null:
		office._upgrade_disclosure_toggle.set_expanded(true, false)
	# Preserve the authored protected operating reserve while giving this isolated
	# evidence fixture enough discretionary cash for the real level-one purchase.
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, 10_000)
	office._on_snapshot_changed(office._simulation.snapshot())
	await office.get_tree().process_frame
	var upgrade_id: StringName = &"peckwork_tools"
	var upgrade_button := office._upgrade_buttons.get(upgrade_id) as Button
	var scroll := office._flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_CAPITAL)
	if scroll != null and upgrade_button != null:
		var component_offset := (
			upgrade_button.global_position.y
			- scroll.global_position.y
			+ float(scroll.scroll_vertical)
			- 72.0
		)
		scroll.scroll_vertical = maxi(0, int(component_offset))
	await office.get_tree().process_frame
	var expected_cost := office._simulation.upgrade_cost_cents(upgrade_id)
	var fund_before := office._simulation.revenue_cents
	if not office._simulation.purchase_upgrade(upgrade_id):
		push_error("Fund-debit capture could not complete the authoritative purchase.")
		office.get_tree().quit(1)
		return
	if not office.stage_fund_debit_feedback_capture():
		push_error("Fund-debit capture could not stage the counter-to-purchase docket.")
		office.get_tree().quit(1)
		return
	var debit_state := office.fund_debit_feedback_snapshot()
	var receipt := debit_state.get("last_receipt", {}) as Dictionary
	if (
		fund_before - office._simulation.revenue_cents != expected_cost
		or int(debit_state.get("pooled_count", 0)) != office.FUND_DEBIT_CHIP_POOL_SIZE
		or int(debit_state.get("active_count", 0)) != 1
		or String(receipt.get("source_id", "")) != "feed_fund_counter"
		or String(receipt.get("target_id", "")) != String(upgrade_id)
		or String(receipt.get("motion", "")) != "counter_to_purchase"
	):
		push_error("Fund-debit capture lost its causal transaction contract: %s" % JSON.stringify(debit_state))
		office.get_tree().quit(1)
		return
	office._clock.set_speed(0)
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.12).timeout
	_save_preview("fund_debit.png")


func _capture_procurement_debit_preview() -> void:
	_prepare_capture_running()
	office._simulation.day = 7
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = 100_000
	var facility_receipt := office._simulation.purchase_facility(&"feed_procurement_coop")
	if not bool(facility_receipt.get("accepted", false)):
		push_error("Procurement-debit capture could not commission Flock Provisions.")
		office.get_tree().quit(1)
		return
	office._simulation._feed_procurement.begin_day(office._simulation.day)
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_OPERATIONS)
	await office.get_tree().process_frame
	var procurement_ui := office.find_child("FeedProcurementUI", true, false) as FeedProcurementUI
	if procurement_ui != null:
		procurement_ui.set_offers_expanded(true)
	var order_id: StringName = &"local_whole_grain"
	var order_button := office.find_child(
		"FeedProcurementOrder_%s" % String(order_id),
		true,
		false,
	) as Control
	var scroll := office._flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_OPERATIONS)
	if scroll != null and order_button != null:
		var component_offset := (
			order_button.global_position.y
			- scroll.global_position.y
			+ float(scroll.scroll_vertical)
			- 250.0
		)
		scroll.scroll_vertical = maxi(0, int(component_offset))
	await office.get_tree().process_frame
	var expected_cost := 0
	for offer_value in office._simulation.procurement_offer_catalog():
		var offer := offer_value as Dictionary
		if StringName(String(offer.get("offer_id", ""))) == order_id:
			expected_cost = int(offer.get("total_cost_cents", 0))
			break
	var fund_before := office._simulation.revenue_cents
	office._on_feed_order_requested(order_id)
	if not office.stage_fund_debit_feedback_capture():
		push_error("Procurement-debit capture could not stage the accepted order docket.")
		office.get_tree().quit(1)
		return
	var debit_state := office.fund_debit_feedback_snapshot()
	var receipt := debit_state.get("last_receipt", {}) as Dictionary
	if (
		expected_cost <= 0
		or fund_before - office._simulation.revenue_cents != expected_cost
		or int(debit_state.get("active_count", 0)) != 1
		or String(receipt.get("transaction_kind", "")) != "feed_procurement"
		or String(receipt.get("target_id", "")) != "feed_order_local_whole_grain"
		or String(receipt.get("target_name", "")) != "FeedProcurementOrder_local_whole_grain"
		or not office._fund_debit_control_is_actually_visible(order_button)
	):
		push_error(
			"Procurement-debit capture lost its accepted-order contract: %s"
			% JSON.stringify(debit_state)
		)
		office.get_tree().quit(1)
		return
	office._clock.set_speed(0)
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.12).timeout
	_save_preview("procurement_debit.png")


func _capture_intern_debit_preview() -> void:
	_prepare_capture_running()
	office._simulation.day = 2
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = 50_000
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_FLOCK)
	var internship_ui := office.find_child("InternshipProgramUI", true, false) as InternshipProgramUI
	if internship_ui != null:
		internship_ui.set_expanded(true)
	await office.get_tree().process_frame
	var candidate_id: StringName = &"lottie_ledger"
	var intern_card := office.find_child(
		"InternCard_%s" % String(candidate_id),
		true,
		false,
	) as Control
	var scroll := office._flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_FLOCK)
	if scroll != null and intern_card != null:
		var component_offset := (
			intern_card.global_position.y
			- scroll.global_position.y
			+ float(scroll.scroll_vertical)
			- 170.0
		)
		scroll.scroll_vertical = maxi(0, int(component_offset))
	await office.get_tree().process_frame
	var fund_before := office._simulation.revenue_cents
	office._on_intern_onboard_requested(candidate_id)
	if not office.stage_fund_debit_feedback_capture():
		push_error("Intern-debit capture could not stage the accepted onboarding docket.")
		office.get_tree().quit(1)
		return
	var debit_state := office.fund_debit_feedback_snapshot()
	var receipt := debit_state.get("last_receipt", {}) as Dictionary
	var settled_card := office.find_child(
		"InternCard_%s" % String(candidate_id),
		true,
		false,
	) as Control
	if (
		fund_before - office._simulation.revenue_cents
		!= InternshipProgramState.ONBOARDING_COST_CENTS
		or int(debit_state.get("active_count", 0)) != 1
		or String(receipt.get("transaction_kind", "")) != "internship"
		or String(receipt.get("target_id", "")) != "intern_onboard_lottie_ledger"
		or String(receipt.get("target_name", "")) != "InternCard_lottie_ledger"
		or not office._fund_debit_control_is_actually_visible(settled_card)
	):
		push_error(
			"Intern-debit capture lost its accepted-onboarding contract: %s"
			% JSON.stringify(debit_state)
		)
		office.get_tree().quit(1)
		return
	office._clock.set_speed(0)
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.12).timeout
	_save_preview("intern_debit.png")


func _capture_review_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().process_frame
	if office._office_atmosphere != null:
		office._office_atmosphere.pulse_farmer_review()
	office._management_presence.play_review()
	office._camera_controller.focus_point(office._management_presence.review_focus_point(), "FARMER INSPECTION", 0.7)
	await office.get_tree().create_timer(1.65).timeout
	_save_preview("farmer_review.png")


func _capture_predator_preview() -> void:
	_prepare_capture_running()
	# Let the selected worker complete the morning path before the fox enters.
	await office.get_tree().create_timer(4.5).timeout
	office._trigger_predator_debug_encounter()
	var worker_view := office._worker_views.get(0) as ChickenView
	if worker_view != null and office._camera_controller != null:
		office._camera_controller.focus_point(worker_view.global_position + Vector3(0.0, 1.0, 0.0), "PREDATOR LOSS", 0.45)
	# Capture during the rotation/shake portion rather than the approach.
	await office.get_tree().create_timer(2.55).timeout
	_save_preview("predator_encounter.png")


func _capture_predator_animation() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(4.5).timeout
	office._trigger_predator_debug_encounter()
	# The fox now enters through the full employee lane before the bite.
	await office.get_tree().create_timer(4.4).timeout
	if office._predator_encounter != null and office._camera_controller != null:
		office._camera_controller.focus_point(office._predator_encounter.focus_point(), "PREDATOR LOSS", 0.25)
	var capture_directory := ProjectSettings.globalize_path("res://captures/predator_live_frames")
	DirAccess.make_dir_recursive_absolute(capture_directory)
	for frame_index in 30:
		await office.get_tree().create_timer(0.1).timeout
		var image := office.get_viewport().get_texture().get_image()
		if image != null:
			image.save_png(capture_directory.path_join("predator_%03d.png" % frame_index))
	office.get_tree().quit()


func _capture_routing_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	office._simulation.set_worker_assignment(0, &"appeals")
	office._simulation.set_worker_at_workstation(0, true)
	office._simulation.advance_tick()
	office._camera_controller.focus_worker(0)
	await office.get_tree().create_timer(1.0).timeout
	_save_preview("peckwork_routing.png")


func _capture_adaptive_routing_guidance_preview() -> void:
	_prepare_capture_running()
	office._player_preferences["guidance_mode"] = "full"
	office._clear_adaptive_route_recovery()
	await office.get_tree().create_timer(5.5).timeout
	for worker_id in [0, 1]:
		var worker := office._worker_record(office._simulation.snapshot(), worker_id)
		var specialty := StringName(String(worker.get("specialty", "")))
		var secondary := StringName(String(worker.get("secondary_specialty", "")))
		for lane: StringName in [&"nest_damage", &"predator_loss", &"appeals"]:
			if lane == specialty or lane == secondary:
				continue
			office._on_worker_assignment_requested(worker_id, lane)
			break
	office._update_guidance(office._simulation.snapshot())
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("adaptive_routing_recovery.png")


func _capture_adaptive_routing_success_preview() -> void:
	_prepare_capture_running()
	office._player_preferences["guidance_mode"] = "full"
	office._clear_adaptive_route_recovery()
	await office.get_tree().create_timer(5.5).timeout
	var coached_worker_id := 1
	for worker_id in [0, coached_worker_id]:
		var worker := office._worker_record(office._simulation.snapshot(), worker_id)
		var specialty := StringName(String(worker.get("specialty", "")))
		var secondary := StringName(String(worker.get("secondary_specialty", "")))
		for lane: StringName in [&"nest_damage", &"predator_loss", &"appeals"]:
			if lane == specialty or lane == secondary:
				continue
			office._on_worker_assignment_requested(worker_id, lane)
			break
	var coached_worker := office._worker_record(office._simulation.snapshot(), coached_worker_id)
	office._on_worker_assignment_requested(
		coached_worker_id,
		StringName(String(coached_worker.get("specialty", ""))),
	)
	office._update_guidance(office._simulation.snapshot())
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("adaptive_routing_success.png")


func _capture_core_action_hold_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	office._retire_action_outcome_receipts(&"core_action_hold_preview", false)
	office._publish_priority_peck_hold({
		"window_state": &"spent",
		"reason": "A clean assisted delivery restores the next management-attention charge.",
	})
	if office._audio_feedback != null:
		office._audio_feedback.play_denied(&"peck_rejected")
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("core_action_hold.png")


func _capture_economic_action_hold_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	office._retire_action_outcome_receipts(&"economic_action_hold_preview", false)
	office._publish_economic_action_hold(
		"PROVISIONS",
		"REVIEW LOT",
		"The selected lot no longer fits storage. Compare capacity and choose a smaller available lot.",
		"Provisions order",
	)
	if office._audio_feedback != null:
		office._audio_feedback.play_denied(&"provisions")
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("economic_action_hold.png")


func _capture_strategic_action_hold_preview() -> void:
	_prepare_capture_running()
	office._player_preferences["notice_duration"] = "extended"
	await office.get_tree().create_timer(5.5).timeout
	office._retire_action_outcome_receipts(&"strategic_action_hold_preview", false)
	office._open_capital_blueprint(false, false)
	await office.get_tree().process_frame
	office._publish_economic_action_hold(
		"CAPITAL PLAN",
		"REVIEW FACILITY",
		"The facility price changed before filing. Compare the current cost and protected reserve.",
		"Capital plan",
	)
	if office._audio_feedback != null:
		office._audio_feedback.play_denied(&"capital_plan")
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("strategic_action_hold.png")


func _capture_save_recovery_hold_preview() -> void:
	_prepare_capture_running()
	office._player_preferences["notice_duration"] = "extended"
	await office.get_tree().create_timer(5.5).timeout
	office._retire_action_outcome_receipts(&"save_recovery_hold_preview", false)
	office._show_campaign_title(false)
	office._set_campaign_modal_open(true)
	await office.get_tree().process_frame
	office._publish_economic_action_hold(
		"SAVE",
		"REVIEW RECOVERY",
		"No complete campaign, office, and Senior ledger passed validation. Start a new file or inspect a portable backup before retrying Continue.",
		"Career recovery",
	)
	if office._audio_feedback != null:
		office._audio_feedback.play_denied(&"save_recovery")
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("save_recovery_hold.png")


func _capture_dispatch_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	for worker_index in mini(4, office._simulation.workers.size()):
		office._simulation.set_worker_at_workstation(worker_index, true)
		var preview_view := office._worker_views.get(worker_index) as ChickenView
		if preview_view != null:
			preview_view.stage_at_workstation_for_introduction()
	office._simulation.advance_tick()
	for preview_lane: StringName in [&"nest_damage", &"predator_loss", &"appeals"]:
		var preview_candidates := office._simulation.dispatch_candidates(preview_lane)
		if preview_candidates.is_empty():
			continue
		var preview_worker_id := int(preview_candidates[0].get("worker_id", -1))
		if office._simulation.workers[preview_worker_id].assigned_lane == preview_lane:
			office._simulation.set_worker_assignment(preview_worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
		office._simulation.dispatch_worker_to_lane(preview_worker_id, preview_lane)
	office._on_dispatch_lane_requested(&"predator_loss")
	if office._workstation_feedback != null and office._dispatch_recommended_worker_id >= 0:
		office._workstation_feedback.play_dispatch_delivery(
			office._dispatch_recommended_worker_id,
			&"predator_loss",
			office.to_global(office.DISPATCH_INTAKE_SOURCE),
			true,
			4,
			18.0,
		)
		office._workstation_feedback.play_routing_reward_burst(
			office._dispatch_recommended_worker_id,
			&"peck_recharge",
			3,
			18.0,
		)
		if office._routing_ui != null:
			office._routing_ui.play_dispatch_reward(&"peck_recharge", 3)
	await office.get_tree().create_timer(4.5).timeout
	_save_preview("peckwork_dispatch.png")


func _capture_routing_pace_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	for worker_index in mini(4, office._simulation.workers.size()):
		office._simulation.set_worker_at_workstation(worker_index, true)
		var preview_view := office._worker_views.get(worker_index) as ChickenView
		if preview_view != null:
			preview_view.stage_at_workstation_for_introduction()
	office._simulation.advance_tick()
	# Cross the real x2 authority boundary through two ranked dispatches, then
	# hold several occupied desks in the work state that receives the multiplier.
	for preview_lane: StringName in [&"nest_damage", &"predator_loss"]:
		var preview_candidates := office._simulation.dispatch_candidates(preview_lane)
		if preview_candidates.is_empty():
			continue
		var preview_worker_id := int(preview_candidates[0].get("worker_id", -1))
		if office._simulation.workers[preview_worker_id].assigned_lane == preview_lane:
			office._simulation.set_worker_assignment(
				preview_worker_id,
				DepartmentSimulation.AUTO_ASSIGNMENT,
			)
		office._simulation.dispatch_worker_to_lane(preview_worker_id, preview_lane)
	for worker_index in mini(4, office._simulation.workers.size()):
		var worker := office._simulation.workers[worker_index]
		if worker.current_claim == null:
			continue
		worker.current_claim.resolution_locked = true
		worker.work_state = ChickenState.WorkState.WORKING
		# Stay before the Priority Peck window so its large opportunity pins do
		# not cover the workstation-level pace evidence in this isolated capture.
		worker.work_progress = 15.0 + worker_index * 2.0
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._character_dialogue_ui != null:
		office._character_dialogue_ui.clear_session()
	# Ordinary low-urgency match pins are useful in play but overlap the physical
	# monitors at this camera angle. Hide only those capture-layer markers so the
	# persistent workstation feedback can be inspected in isolation.
	for preview_view_value in office._worker_views.values():
		var staged_view := preview_view_value as ChickenView
		if staged_view == null:
			continue
		var intent_marker := staged_view.find_child("HenIntentMarker", true, false) as Node3D
		if intent_marker != null:
			intent_marker.visible = false
		var opportunity_halo := staged_view.find_child("PriorityPeckReadyHalo", true, false) as Node3D
		if opportunity_halo != null:
			opportunity_halo.visible = false
	if office._routing_ui != null:
		office._routing_ui.clear_focus()
	if office._camera_controller != null and office._workstation_feedback != null:
		office._camera_controller.focus_point(
			office._workstation_feedback.screen_contact_point_global(0),
			"ROUTING PACE",
			0.35,
			8.8,
		)
	await office.get_tree().create_timer(0.55).timeout
	_save_preview("routing_pace_workstations.png")


func _capture_career_workshop_preview(advanced := false) -> void:
	# A staged fourth-shift career for layout/interaction audits. Goal completion
	# and tool effects are exercised separately through authoritative actions.
	_prepare_capture_running()
	office._simulation.day = 5 if advanced else 4
	office._simulation.call("_reset_daily_decision_state")
	office._simulation.call("_prepare_morning_directive")
	office._simulation.select_directive(&"shell_assurance")
	for completed_day in [1, 2, 3]:
		office._simulation.career_workshop.award(completed_day)
	# Explicit authored mastery capture; normal play never enters this runner.
	# Native progression tests earn these unlocks through real tool/challenge use.
	if advanced and OS.has_feature("web") and bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('mastery') === '1'")):
		for tool: String in CareerWorkshop.TOOLS:
			office._simulation.career_workshop.choose(tool, office._simulation.day, true)
			office._simulation.career_workshop.mastered_tools.append(tool)
		office._simulation.career_workshop.last_award_day = 4

	office._decision_host.hide()
	office._character_dialogue_ui.clear_session()
	for worker_id in 3:
		office._simulation.set_worker_at_workstation(worker_id, true)
		(office._worker_views[worker_id] as ChickenView).stage_at_workstation_for_introduction()
	office._simulation.advance_tick()
	for worker in office._simulation.workers:
		if worker.current_claim != null:
			worker.work_progress = 62.0
			worker.current_claim.deadline_operational_minute = office._simulation._current_operational_minute() + (45 if advanced else 180)
	office._clock.set_speed(0)
	office._routing_ui.set_focus(0)
	office._on_snapshot_changed(office._simulation.snapshot())
	office._open_shift_challenge_choices("workshop")
	await office.get_tree().create_timer(0.3).timeout
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	_save_preview("career_workshop.png")


func _capture_flock_ties_preview(rewards: bool = false) -> void:
	await _capture_hen_social_preview()
	# Art fixture: a short, legible shared history. The action under test still
	# crosses the normal authority, daily opportunity, receipt and save boundary.
	office._simulation.flock_relationships = FlockRelationships.new()
	for shift in [1, 2]:
		office._simulation.flock_relationships.record(0, 1, "quota_comparison", shift)
		office._simulation.flock_relationships.record(0, 2, "team_lift", shift)
		office._simulation.flock_relationships.record(0, 2, "shared_shift", shift)
	office._simulation.flock_relationships.record(0, 1, "shared_credit", 2)
	office._simulation.day = 3
	office._simulation.flock_relationships.begin_day(3)
	office._simulation.active_playbook.clear()
	if rewards:
		office._simulation.day = 4
		office._simulation.flock_relationships.begin_day(4)
		var workshop := office._simulation.career_workshop
		workshop.begin_day(4)
		workshop.owned.assign(["shell_guard"])
		workshop.equipped = "shell_guard"
		workshop.tuning = "precision"
		workshop.loadout_locked = true
		for worker in office._simulation.workers:
			worker.stress = 12.0
			worker.fatigue = 8.0
			if worker.current_claim != null:
				worker.work_progress = 92.0
				worker.current_claim.difficulty = 1.0
				worker.current_claim.deadline_operational_minute = office._simulation._current_operational_minute() + 240
				# Keep this authored reward capture deterministic; ordinary quality
				# and rewards still settle through production and completion.
				if workshop.uses < 3:
					workshop.protected_claims.append(worker.current_claim.id)
					workshop.uses += 1
			office._simulation.set_worker_at_workstation(worker.id, true)
	office._on_snapshot_changed(office._simulation.snapshot())
	office._character_dialogue_ui.clear_session()
	office._routing_ui.set_focus(0)
	office._open_flock_ties()
	await office.get_tree().process_frame
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))


func _capture_hen_social_preview() -> void:
	await _capture_work_progress_preview()
	for worker in office._simulation.workers:
		worker.work_progress = 0.0
		# Longer fixture files leave a reading window before the opening egg
		# handoff rearranges the floor. Production still uses its normal clock.
		if worker.current_claim != null:
			worker.current_claim.difficulty = 4.0
			worker.current_claim.deadline_operational_minute = office._simulation._current_operational_minute() + 240
	# Explicit art comparison only; ordinary careers derive these from earned XP
	# and purchases. Both captures share the same scene, camera and worker IDs.
	var identity_stage := ""
	if OS.has_feature("web"):
		identity_stage = str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('identity') || ''"))
	if not identity_stage.is_empty():
		for worker in office._simulation.workers:
			worker.career_xp = ChickenState.CAREER_THRESHOLDS[mini(worker.id + 1, 3)] if identity_stage == "earned" else 0
		for upgrade: StringName in [&"peckwork_tools", &"shell_lamp", &"nest_cushion"]:
			office._simulation.upgrade_levels[upgrade] = 4 if identity_stage == "earned" else 0
	office._simulation.workers[0].stress = 12.0
	office._simulation.workers[1].stress = 72.0
	office._on_snapshot_changed(office._simulation.snapshot())
	office._character_dialogue_ui.clear_session()
	office._camera_controller.show_overview()
	office._hen_social.cooldown = 0.0
	# Arrange a real stressed pair; normal scheduler chooses their exchange.
	await office.get_tree().create_timer(0.8).timeout
	office._process_hen_social(0.0, true)
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))

	if not identity_stage.is_empty():
		office._clock.set_speed(0)
		office._character_dialogue_ui.clear_session()
		office._publish_web_diagnostic_state(office._simulation.snapshot(true))


func _capture_hen_expression_preview() -> void:
	# Art fixture only. Public Peck/reward inputs still cross normal authorities.
	await _capture_work_progress_preview()
	office._simulation.workers[0].stress = 12.0
	office._simulation.workers[0].fatigue = 8.0
	office._simulation.workers[1].stress = 86.0
	office._simulation.workers[1].fatigue = 76.0
	office._simulation.workers[1].work_progress = 62.0
	office._on_snapshot_changed(office._simulation.snapshot())
	office._camera_controller.focus_worker(1)
	await office.get_tree().create_timer(0.6).timeout
	# The staged threshold can queue the ordinary private-aside dialogue. Keep
	# this art fixture on the physical hen; normal play still shows that dialogue.
	office._character_dialogue_ui.clear_session()
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))


func _capture_collection_detail_preview() -> void:
	await _capture_work_progress_preview()
	office._camera_controller.focus_point(Vector3(9.4, 0.85, -6.85), "COLLECTION DETAILS", 0.35, 5.6)
	await office.get_tree().create_timer(0.65).timeout
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))


func _capture_office_props_preview() -> void:
	await _capture_work_progress_preview()
	office._camera_controller.focus_point(Vector3(10.25, 0.85, -2.6), "OFFICE DETAILS", 0.35, 9.0)
	await office.get_tree().create_timer(0.65).timeout
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))


func _capture_work_progress_preview() -> void:
	_prepare_capture_running()
	office._decision_host.visible = false
	await office.get_tree().create_timer(5.5).timeout
	for worker_index in mini(3, office._simulation.workers.size()):
		office._simulation.set_worker_at_workstation(worker_index, true)
		var preview_view := office._worker_views.get(worker_index) as ChickenView
		if preview_view != null:
			preview_view.stage_at_workstation_for_introduction()
	# Cross the normal work boundary so every displayed file and percentage is a
	# real simulation claim. The capture only arranges those authoritative values
	# into a legible advancing / urgent / paused comparison.
	office._simulation.advance_tick()
	var active_worker_ids: Array[int] = []
	for worker in office._simulation.workers:
		if worker.current_claim != null:
			active_worker_ids.append(worker.id)
		if active_worker_ids.size() == 3:
			break
	if active_worker_ids.size() < 3:
		push_error("Work progress capture requires three active simulation files.")
		office.get_tree().quit(1)
		return
	var now := office._simulation._current_operational_minute()
	var capture_progress := [22.0, 58.0, 78.0]
	var capture_deadlines := [180, 35, 120]
	for index in active_worker_ids.size():
		var worker_id := active_worker_ids[index]
		var worker := office._simulation.workers[worker_id]
		worker.work_state = ChickenState.WorkState.WORKING
		worker.work_progress = capture_progress[index]
		worker.current_claim.deadline_operational_minute = now + capture_deadlines[index]
		office._simulation.set_worker_at_workstation(worker_id, index != 2)
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._character_dialogue_ui != null:
		office._character_dialogue_ui.clear_session()
	if office._routing_ui != null:
		office._routing_ui.clear_focus()
	for preview_view_value in office._worker_views.values():
		var staged_view := preview_view_value as ChickenView
		if staged_view == null:
			continue
		var intent_marker := staged_view.find_child("HenIntentMarker", true, false) as Node3D
		if intent_marker != null:
			intent_marker.visible = false
		var opportunity_halo := staged_view.find_child("PriorityPeckReadyHalo", true, false) as Node3D
		if opportunity_halo != null:
			opportunity_halo.visible = false
	if office._camera_controller != null:
		office._camera_controller.focus_point(
			office.desk_position(1) + Vector3(0.0, 1.32, 0.80),
			"LIVE PECKWORK",
			0.35,
			10.4,
		)
	office._clock.set_speed(0)
	await office.get_tree().create_timer(0.65).timeout
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.12).timeout
	_save_preview("work_progress_rails.png")


func _capture_routing_peck_recharge_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	for worker_index in mini(4, office._simulation.workers.size()):
		office._simulation.set_worker_at_workstation(worker_index, true)
		var preview_view := office._worker_views.get(worker_index) as ChickenView
		if preview_view != null:
			preview_view.stage_at_workstation_for_introduction()
	office._simulation.advance_tick()
	# Start one charge down so x3 visibly fills a real empty pip rather than
	# demonstrating the separate over-cap reserve case.
	office._simulation.peck_assists_used_today = 1
	office._simulation.peck_assist_interventions_today = 1
	for preview_lane: StringName in [&"nest_damage", &"predator_loss"]:
		var candidates := office._simulation.dispatch_candidates(preview_lane)
		if candidates.is_empty():
			continue
		var worker_id := int(candidates[0].get("worker_id", -1))
		if office._simulation.workers[worker_id].assigned_lane == preview_lane:
			office._simulation.set_worker_assignment(worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
		office._simulation.dispatch_worker_to_lane(worker_id, preview_lane)
	office._on_dispatch_lane_requested(&"appeals")
	var recharge_worker_id := office._dispatch_recommended_worker_id
	if recharge_worker_id < 0:
		push_error("Routing recharge capture requires a ranked Appeals hen.")
		office.get_tree().quit(1)
		return
	if office._simulation.workers[recharge_worker_id].assigned_lane == &"appeals":
		office._simulation.set_worker_assignment(
			recharge_worker_id,
			DepartmentSimulation.AUTO_ASSIGNMENT,
		)
	office._routing_ui.set_focus(recharge_worker_id)
	if not office._commit_dispatch(recharge_worker_id):
		push_error("Routing recharge capture could not file the real x3 dispatch.")
		office.get_tree().quit(1)
		return
	# Focus only after the explicit commit; focusing while dispatch mode is armed
	# is itself the normal click-to-file gesture and would correctly commit twice.
	office._camera_controller.focus_worker(recharge_worker_id)
	await office.get_tree().create_timer(0.95).timeout
	if (
		not office._workstation_feedback.stage_routing_reward_capture(&"peck_recharge")
		or not office._routing_ui.stage_priority_peck_recharge_capture()
	):
		push_error("Routing recharge capture could not stage the synchronized world and dossier receipt.")
		office.get_tree().quit(1)
		return
	office._clock.set_speed(0)
	if office._character_dialogue_ui != null:
		office._character_dialogue_ui.clear_session()
	# Ordinary intent pins compete with the x3 source-and-destination evidence.
	# Hide only those capture-layer sprites; live play retains every intent cue.
	for preview_view_value in office._worker_views.values():
		var staged_view := preview_view_value as ChickenView
		if staged_view == null:
			continue
		var intent_marker := staged_view.find_child("HenIntentMarker", true, false) as Node3D
		if intent_marker != null:
			intent_marker.visible = false
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.12).timeout
	_save_preview("routing_peck_recharge.png")


func _capture_routing_golden_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	for worker_index in mini(4, office._simulation.workers.size()):
		office._simulation.set_worker_at_workstation(worker_index, true)
		var preview_view := office._worker_views.get(worker_index) as ChickenView
		if preview_view != null:
			preview_view.stage_at_workstation_for_introduction()
	office._simulation.advance_tick()
	# Build x4 through the real ranked authority, then let the ordinary Office
	# commit path deliver x5 so the milestone, seal, sound, and dossier stay synced.
	for preview_lane: StringName in [&"nest_damage", &"predator_loss", &"appeals", &"nest_damage"]:
		var candidates := office._simulation.dispatch_candidates(preview_lane)
		if candidates.is_empty():
			continue
		var worker_id := int(candidates[0].get("worker_id", -1))
		if office._simulation.workers[worker_id].assigned_lane == preview_lane:
			office._simulation.set_worker_assignment(worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
		office._simulation.dispatch_worker_to_lane(worker_id, preview_lane)
	office._on_dispatch_lane_requested(&"predator_loss")
	var milestone_worker_id := office._dispatch_recommended_worker_id
	if milestone_worker_id < 0:
		push_error("Golden File capture requires a ranked Predator Loss hen.")
		office.get_tree().quit(1)
		return
	if office._simulation.workers[milestone_worker_id].assigned_lane == &"predator_loss":
		office._simulation.set_worker_assignment(milestone_worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
	if not office._commit_dispatch(milestone_worker_id):
		push_error("Golden File capture could not file the real x5 dispatch.")
		office.get_tree().quit(1)
		return
	var momentum := office._simulation.routing_momentum_snapshot()
	var target_worker_id := int(momentum.get("golden_target_worker_id", -1))
	if target_worker_id < 0:
		push_error("Golden File capture did not bind an active file.")
		office.get_tree().quit(1)
		return
	office._routing_ui.set_focus(target_worker_id)
	office._camera_controller.focus_worker(target_worker_id)
	office._clock.set_speed(0)
	if office._character_dialogue_ui != null:
		office._character_dialogue_ui.clear_session()
	for preview_view_value in office._worker_views.values():
		var staged_view := preview_view_value as ChickenView
		if staged_view == null:
			continue
		var intent_marker := staged_view.find_child("HenIntentMarker", true, false) as Node3D
		if intent_marker != null:
			intent_marker.visible = false
	office._on_snapshot_changed(office._simulation.snapshot())
	await office.get_tree().create_timer(0.75).timeout
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.12).timeout
	_save_preview("routing_golden_file.png")


func _capture_routing_team_lift_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	for worker_index in mini(4, office._simulation.workers.size()):
		office._simulation.set_worker_at_workstation(worker_index, true)
		var preview_view := office._worker_views.get(worker_index) as ChickenView
		if preview_view != null:
			preview_view.stage_at_workstation_for_introduction()
	office._simulation.advance_tick()
	var lanes: Array[StringName] = [&"nest_damage", &"predator_loss", &"appeals"]
	for dispatch_index in 9:
		var lane := lanes[dispatch_index % lanes.size()]
		var candidates := office._simulation.dispatch_candidates(lane)
		if candidates.is_empty():
			continue
		var worker_id := int(candidates[0].get("worker_id", -1))
		if office._simulation.workers[worker_id].assigned_lane == lane:
			office._simulation.set_worker_assignment(worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
		office._simulation.dispatch_worker_to_lane(worker_id, lane)
	for worker in office._simulation.workers:
		if not worker.employed:
			continue
		worker.morale = 50.0
		worker.stress = 50.0
		worker.fatigue = 50.0
	office._simulation.solidarity = 50.0
	office._on_snapshot_changed(office._simulation.snapshot())
	office._on_dispatch_lane_requested(&"nest_damage")
	var milestone_worker_id := office._dispatch_recommended_worker_id
	if milestone_worker_id < 0:
		push_error("Team Lift capture requires a ranked Nest Damage hen.")
		office.get_tree().quit(1)
		return
	if office._simulation.workers[milestone_worker_id].assigned_lane == &"nest_damage":
		office._simulation.set_worker_assignment(milestone_worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
	if not office._commit_dispatch(milestone_worker_id):
		push_error("Team Lift capture could not file the real x10 dispatch.")
		office.get_tree().quit(1)
		return
	await office.get_tree().create_timer(0.90).timeout
	var staged_count := 0
	for preview_view_value in office._worker_views.values():
		var staged_view := preview_view_value as ChickenView
		if staged_view == null:
			continue
		if staged_view.stage_team_lift_capture():
			staged_count += 1
		var intent_marker := staged_view.find_child("HenIntentMarker", true, false) as Node3D
		if intent_marker != null:
			intent_marker.visible = false
	if staged_count != int((office._dispatch_last_receipt.get("reward", {}) as Dictionary).get("affected_count", 0)):
		push_error("Team Lift capture could not stage every affected hen.")
		office.get_tree().quit(1)
		return
	if office._workstation_feedback != null:
		office._workstation_feedback.stage_routing_reward_capture(&"team_lift")
	if office._character_dialogue_ui != null:
		office._character_dialogue_ui.clear_session()
	office._camera_controller.show_overview()
	office._clock.set_speed(0)
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.12).timeout
	_save_preview("routing_team_lift.png")


func _capture_routing_mastery_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	for worker_index in mini(4, office._simulation.workers.size()):
		office._simulation.set_worker_at_workstation(worker_index, true)
		var preview_view := office._worker_views.get(worker_index) as ChickenView
		if preview_view != null:
			preview_view.stage_at_workstation_for_introduction()
	office._simulation.advance_tick()
	var lanes: Array[StringName] = [&"nest_damage", &"predator_loss", &"appeals"]
	for dispatch_index in 14:
		var lane := lanes[dispatch_index % lanes.size()]
		var candidates := office._simulation.dispatch_candidates(lane)
		if candidates.is_empty():
			continue
		var worker_id := int(candidates[0].get("worker_id", -1))
		if office._simulation.workers[worker_id].assigned_lane == lane:
			office._simulation.set_worker_assignment(worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
		office._simulation.dispatch_worker_to_lane(worker_id, lane)
	office._on_snapshot_changed(office._simulation.snapshot())
	office._on_dispatch_lane_requested(&"appeals")
	var record_worker_id := office._dispatch_recommended_worker_id
	if record_worker_id < 0:
		push_error("Routing mastery capture requires a ranked Appeals hen.")
		office.get_tree().quit(1)
		return
	if office._simulation.workers[record_worker_id].assigned_lane == &"appeals":
		office._simulation.set_worker_assignment(record_worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
	if not office._commit_dispatch(record_worker_id):
		push_error("Routing mastery capture could not file the real x15 dispatch.")
		office.get_tree().quit(1)
		return
	await office.get_tree().create_timer(0.90).timeout
	if (
		office._workstation_feedback == null
		or not office._workstation_feedback.stage_routing_reward_capture(&"mastery_record")
	):
		push_error("Routing mastery capture could not stage its desk medal.")
		office.get_tree().quit(1)
		return
	# Refresh after the medal lands so the compact strip advances from the earned
	# x15 receipt to its durable >20 horizon while the physical proof remains held.
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._character_dialogue_ui != null:
		office._character_dialogue_ui.clear_session()
	for preview_view_value in office._worker_views.values():
		var staged_view := preview_view_value as ChickenView
		if staged_view == null:
			continue
		var intent_marker := staged_view.find_child("HenIntentMarker", true, false) as Node3D
		if intent_marker != null:
			intent_marker.visible = false
	office._camera_controller.show_overview()
	office._clock.set_speed(0)
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.12).timeout
	_save_preview("routing_mastery.png")


func _capture_routing_review_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(0.8).timeout
	# Stage a previously filed x10 result, then close the live shift at x15. The
	# ordinary workday signal builds the review receipt and the ordinary review UI
	# renders it; only the bounded art precondition is synthetic.
	office._last_workday_report = {
		"day": 0,
		"routing_momentum": {"best_chain": 10},
	}
	office._simulation.routing_momentum_chain = 15
	office._simulation.best_routing_momentum_chain = 15
	office._simulation.eggs_today = office._simulation.quota_target + 3
	office._simulation.cracked_today = 0
	office._simulation.golden_today = 1
	office._simulation.minute_of_day = (
		DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	)
	office._simulation._incident_slot = DepartmentSimulation.INCIDENT_MINUTES.size()
	office._simulation.advance_tick()
	await office.get_tree().create_timer(0.65).timeout
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.12).timeout
	_save_preview("routing_shift_review.png")


func _capture_routing_return_preview() -> void:
	_prepare_capture_running()
	office._decision_host.visible = false
	office._simulation.routing_momentum_chain = 15
	office._simulation.best_routing_momentum_chain = 15
	var prior_report := {"day": 1, "routing_momentum": {"best_chain": 10}}
	var last_report := {"day": 2, "routing_momentum": office._simulation.routing_momentum_snapshot()}
	last_report["routing_review"] = office._routing_review_receipt(last_report, prior_report)
	var return_recap := office._campaign_return_recap(
		{"simulation": office._simulation.export_save_state()},
		{"reason": "workday_completed", "completed_shifts": 2},
		{"last_workday_report": last_report},
	)
	if return_recap.is_empty():
		push_error("Routing return capture could not build a verified recap.")
		office.get_tree().quit(1)
		return
	office._campaign_ui.apply_snapshot({
		"view": &"title",
		"day": 3,
		"total_days": office.CampaignStateScript.CAMPAIGN_LENGTH,
		"continue_available": true,
		"resume_summary": {
			"day": 3,
			"completed_shifts": 2,
			"probation_score": 68,
			"rank_label": "Trusted Layer",
			"stage_label": "Farmer Review",
			"challenge_contract": office.CampaignStateScript.challenge_contract(
				office.CampaignStateScript.CHALLENGE_STANDARD_FILING
			),
			"return_recap": return_recap,
			"offline_recap": {
				"status_label": "Economy paused",
				"elapsed_short_label": "12M",
			},
		},
	})
	office._campaign_ui.show_title(true)
	office._set_campaign_modal_open(true)
	await office.get_tree().create_timer(0.55).timeout
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.12).timeout
	_save_preview("routing_return_recap.png")


func _capture_routing_return_cue_preview(
	clear_with_route := false,
	stage_landing := false,
	stage_work_start := false,
) -> void:
	_prepare_capture_running()
	office._decision_host.visible = false
	var appeals_queue := office._simulation._claim_queues.get(&"appeals", []) as Array
	if not appeals_queue.is_empty():
		var urgent_claim := appeals_queue[0] as ClaimState
		urgent_claim.deadline_operational_minute = office._simulation._current_operational_minute() - 15
	office._simulation.routing_momentum_chain = 15
	office._simulation.best_routing_momentum_chain = 15
	var prior_report := {"day": 1, "routing_momentum": {"best_chain": 10}}
	var last_report := {"day": 2, "routing_momentum": office._simulation.routing_momentum_snapshot()}
	last_report["routing_review"] = office._routing_review_receipt(last_report, prior_report)
	var return_recap := office._campaign_return_recap(
		{"simulation": office._simulation.export_save_state()},
		{"reason": "workday_completed", "completed_shifts": 2},
		{"last_workday_report": last_report},
	)
	if not office._arm_routing_return_cue(return_recap):
		push_error("Routing return cue capture could not arm its verified x20 chase.")
		office.get_tree().quit(1)
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	if clear_with_route:
		# The preview enters its running phase programmatically; give the ordinary
		# input-blocking refresh one frame to enable its real trays before activating
		# the same guidance action a returning player would use.
		await office.get_tree().process_frame
		office._on_guidance_action_pressed()
		var priority := office._routing_ui.dispatch_priority_state()
		var priority_lane := StringName(String(priority.get("lane", "")))
		if priority_lane != &"appeals":
			push_error("Routing return cue capture did not rank the overdue Appeals tray first.")
			office.get_tree().quit(1)
			return
		office._on_dispatch_lane_requested(priority_lane)
		var worker_id := office._dispatch_recommended_worker_id
		if worker_id < 0:
			push_error("Routing return cue capture could not rank an Appeals hen.")
			office.get_tree().quit(1)
			return
		if office._simulation.workers[worker_id].assigned_lane == priority_lane:
			office._simulation.set_worker_assignment(worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
		if stage_work_start:
			# Keep the ordinary ambient cycle from racing the deterministic evidence
			# contact. The production signal path below remains exactly the same.
			var worker_view := office._worker_views.get(worker_id) as ChickenView
			if worker_view != null:
				worker_view.set_process(false)
				worker_view.set_physics_process(false)
		if not office._commit_dispatch(worker_id):
			push_error("Routing return cue capture could not file its first route.")
			office.get_tree().quit(1)
			return
		if stage_work_start:
			await office.get_tree().create_timer(0.86).timeout
			var staged_worker_view := office._worker_views.get(worker_id) as ChickenView
			if staged_worker_view != null:
				staged_worker_view.stage_at_workstation_for_introduction()
			office._simulation.set_worker_at_workstation(worker_id, true)
			office._simulation.advance_tick()
			office._on_snapshot_changed(office._simulation.snapshot())
			await office.get_tree().process_frame
			office._on_work_peck_contact(worker_id, 1)
			await office.get_tree().create_timer(0.58).timeout
			if (
				office._workstation_feedback == null
				or not office._workstation_feedback.stage_dispatch_work_handoff_capture(worker_id)
			):
				push_error("Routing work-start capture could not hold its real first peck handoff.")
				office.get_tree().quit(1)
				return
		elif stage_landing:
			await office.get_tree().create_timer(0.86).timeout
			if (
				office._workstation_feedback == null
				or not office._workstation_feedback.stage_dispatch_landing_capture(worker_id)
			):
				push_error("Routing landing capture could not hold its real desk impact.")
				office.get_tree().quit(1)
				return
	await office.get_tree().create_timer(0.55).timeout
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	await office.get_tree().create_timer(0.12).timeout
	_save_preview(
		"routing_work_start.png"
		if stage_work_start else
		("routing_landing.png"
		if stage_landing else
		("routing_return_cue_cleared.png" if clear_with_route else "routing_return_cue.png")
		)
	)


func _capture_dispatch_break_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	for worker_index in mini(4, office._simulation.workers.size()):
		office._simulation.set_worker_at_workstation(worker_index, true)
		var preview_view := office._worker_views.get(worker_index) as ChickenView
		if preview_view != null:
			preview_view.stage_at_workstation_for_introduction()
	office._simulation.advance_tick()
	# Capture fixtures may stage their precondition, but the transition itself
	# still crosses the exact authoritative break boundary used by real routing.
	# The integration test separately proves a genuine poor-fit dispatch reaches
	# this same signal and receipt.
	office._simulation.routing_momentum_chain = 3
	office._simulation.best_routing_momentum_chain = maxi(
		office._simulation.best_routing_momentum_chain,
		3,
	)
	office._simulation._break_routing_momentum(
		"A poor-fit tray ended the live pace bonus.",
		&"poor_fit",
		1,
	)
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._routing_ui != null:
		office._routing_ui.stage_dispatch_break_capture()
	office._camera_controller.show_overview()
	await office.get_tree().create_timer(0.2).timeout
	_save_preview("routing_momentum_break.png")


func _capture_dispatch_recovery_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	for worker_index in mini(4, office._simulation.workers.size()):
		office._simulation.set_worker_at_workstation(worker_index, true)
		var preview_view := office._worker_views.get(worker_index) as ChickenView
		if preview_view != null:
			preview_view.stage_at_workstation_for_introduction()
	office._simulation.advance_tick()
	# Stage only the lost-chain precondition, then cross the real authoritative
	# recovery boundary with an actual ranked best-fit dispatch.
	office._simulation.routing_momentum_chain = 3
	office._simulation.best_routing_momentum_chain = maxi(
		office._simulation.best_routing_momentum_chain,
		3,
	)
	office._simulation._break_routing_momentum(
		"A poor-fit tray ended the live pace bonus.",
		&"poor_fit",
		1,
	)
	var recovery_lane: StringName = &"predator_loss"
	var recovery_candidates := office._simulation.dispatch_candidates(recovery_lane)
	if not recovery_candidates.is_empty():
		var recovery_worker_id := int(recovery_candidates[0].get("worker_id", -1))
		if (
			recovery_worker_id >= 0
			and office._simulation.workers[recovery_worker_id].assigned_lane == recovery_lane
		):
			office._simulation.set_worker_assignment(
				recovery_worker_id,
				DepartmentSimulation.AUTO_ASSIGNMENT,
			)
		var recovery_dispatch := office._simulation.dispatch_worker_to_lane(
			recovery_worker_id,
			recovery_lane,
		)
		office._dispatch_momentum_chain = int(recovery_dispatch.get("momentum_chain", 0))
		office._dispatch_last_receipt = recovery_dispatch.duplicate(true)
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._character_dialogue_ui != null:
		office._character_dialogue_ui.clear_session()
	if office._routing_ui != null:
		office._routing_ui.stage_dispatch_recovery_capture()
	office._camera_controller.show_overview()
	await office.get_tree().create_timer(0.2).timeout
	_save_preview("routing_momentum_recovery.png")


func _capture_hen_intents_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	office._simulation.solidarity = 88.0
	for worker in office._simulation.workers:
		if worker.employed:
			worker.morale = maxf(worker.morale, 88.0)
			worker.stress = minf(worker.stress, 12.0)
			worker.fatigue = minf(worker.fatigue, 12.0)
	for worker_index in mini(4, office._simulation.workers.size()):
		office._simulation.set_worker_at_workstation(worker_index, true)
		var preview_view := office._worker_views.get(worker_index) as ChickenView
		if preview_view != null:
			preview_view.stage_at_workstation_for_introduction()
	office._simulation.advance_tick()
	if office._simulation.workers[0].current_claim != null:
		office._simulation.workers[0].work_progress = DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS
	if office._simulation.workers.size() > 1 and office._simulation.workers[1].current_claim != null:
		office._simulation.workers[1].current_claim.deadline_operational_minute = (
			office._simulation._current_operational_minute() - 12
		)
	if office._simulation.workers.size() > 2 and office._simulation.workers[2].current_claim != null:
		office._simulation.workers[2].specialty = office._simulation.workers[2].current_claim.lane
		office._simulation.workers[2].current_claim.resolution_locked = true
	if office._simulation.workers.size() > 3:
		office._simulation.workers[3].current_claim = null
		office._simulation.workers[3].work_progress = 0.0
		office._simulation.workers[3].work_state = ChickenState.WorkState.IDLE
		office._simulation.workers[3].stress = 74.0
		office._simulation.workers[3].fatigue = 71.0
		office._simulation.workers[3].morale = 34.0
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._character_dialogue_ui != null:
		office._character_dialogue_ui.clear_session()
	office._routing_ui.set_focus(0)
	office._camera_controller.show_overview()
	await office.get_tree().create_timer(0.9).timeout
	_save_preview("hen_intents.png")


func _capture_first_clutch_preview(check_in := false) -> void:
	office._reset_first_clutch(true)
	_prepare_capture_running()
	await office.get_tree().process_frame
	office._camera_controller.focus_worker(0)
	if check_in:
		var specialty := office._simulation.workers[office.FIRST_HEN_WORKER_ID].specialty
		office._on_worker_assignment_requested(office.FIRST_HEN_WORKER_ID, specialty)
		await office.get_tree().process_frame
	var worker_view := office._worker_views.get(0) as ChickenView
	var seat_deadline := Time.get_ticks_msec() + 15000
	while (
		worker_view != null
		and not worker_view.is_seated_at_workstation()
		and Time.get_ticks_msec() < seat_deadline
	):
		await office.get_tree().process_frame
	await office.get_tree().create_timer(0.55).timeout
	_save_preview(
		"first_clutch_checkin.png" if check_in else "first_clutch_induction.png"
	)


func _capture_first_clutch_reinvestment_preview(
	show_orders_handoff := false,
	open_orders_dashboard := false,
) -> void:
	_prepare_capture_running()
	var reserve := office._simulation.current_daily_operating_cost_cents() + office._simulation.wage_arrears_cents
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, reserve + 2000)
	office._simulation.eggs_today = maxi(1, office._simulation.eggs_today)
	office._simulation.eggs_total = maxi(1, office._simulation.eggs_total)
	office._simulation.workers[office.FIRST_HEN_WORKER_ID].eggs_laid = maxi(
		1,
		office._simulation.workers[office.FIRST_HEN_WORKER_ID].eggs_laid,
	)
	office._first_clutch = office._make_first_clutch_state(false)
	office._first_clutch.merge({
		"completed": true,
		"target_worker_id": office.FIRST_HEN_WORKER_ID,
		"inspected": true,
		"specialty_routed": true,
		"checkin_filed": true,
		"checkin_worker_id": office.FIRST_HEN_WORKER_ID,
		"assisted_worker_id": office.FIRST_HEN_WORKER_ID,
		"assisted_claim_id": 9001,
		"delivery_laid": true,
		"delivery_seen": true,
		"delivered_claim_id": 9001,
		"delivered_quality": "sound",
		"delivered_value_cents": 425,
	}, true)
	var offer := office._simulation.begin_first_clutch_reinvestment(
		office.FIRST_HEN_WORKER_ID,
		9001,
		&"sound",
		425,
	)
	if not bool(offer.get("accepted", false)):
		push_error("First Clutch reinvestment capture could not stage its offer: %s" % String(offer.get("reason", "unknown error")))
		office.get_tree().quit(1)
		return
	office._present_first_clutch_reinvestment(offer)
	if show_orders_handoff or open_orders_dashboard:
		await office.get_tree().process_frame
		var bank := office.find_child("DecisionOption_bank_fund", true, false) as Button
		var confirm := office.find_child("ConfirmDecisionButton", true, false) as Button
		if bank == null or confirm == null:
			push_error("First Clutch orders capture requires the real Bank and Confirm controls.")
			office.get_tree().quit(1)
			return
		bank.pressed.emit()
		await office.get_tree().process_frame
		confirm.pressed.emit()
		if open_orders_dashboard:
			await office.get_tree().process_frame
			office._on_flockwatch_pressed()
	await office.get_tree().create_timer(0.85).timeout
	_save_preview(
		"first_clutch_orders_dashboard.png"
		if open_orders_dashboard else
		("first_clutch_orders_handoff.png"
		if show_orders_handoff else
		"first_clutch_reinvestment.png")
	)


func _capture_first_hen_preview() -> void:
	var player_store = office._campaign_store
	office._campaign_store = office.CampaignSaveStoreScript.new("first_hen_capture.json")
	office._on_campaign_new_requested()
	office._campaign_store = player_store
	await office.get_tree().create_timer(1.1).timeout
	_save_preview("first_hen_prelude.png")


func _capture_first_hen_policy_preview(selected := false) -> void:
	var player_store = office._campaign_store
	office._campaign_store = office.CampaignSaveStoreScript.new("first_hen_policy_capture.json")
	office._on_campaign_new_requested()
	office._open_first_hen_file(office.FIRST_HEN_WORKER_ID)
	office._campaign_store = player_store
	if selected:
		await office.get_tree().process_frame
		var option := office.find_child("DecisionOption_record_harvest", true, false) as Button
		if option != null:
			option.pressed.emit()
	await office.get_tree().create_timer(0.85).timeout
	_save_preview(
		"first_hen_policy_selected.png"
		if selected else
		"first_hen_policy.png"
	)


func _capture_peck_assist_preview(
	show_result := false,
	show_delivery := false,
	show_missed := false,
) -> void:
	_prepare_capture_running()
	var worker_view := office._worker_views.get(0) as ChickenView
	if worker_view == null:
		push_error("Priority Peck capture requires Mabel's worker view.")
		office.get_tree().quit(1)
		return
	# This fixture inspects the timing UI, so stage the authored desk pose directly
	# instead of making the result depend on browser startup and pathing speed.
	worker_view.stage_at_workstation_for_introduction()
	office._simulation.set_worker_at_workstation(0, true)
	office._simulation.advance_tick()
	if office._simulation.workers[0].current_claim == null:
		push_error("Priority Peck capture requires an active file.")
		office.get_tree().quit(1)
		return
	# Establish the same inspected not-ready -> open transition used in live play,
	# so the ready preview validates opportunity semantics rather than starting on
	# an already-open focus change.
	office._simulation.workers[0].work_progress = DepartmentSimulation.PECK_ASSIST_WINDOW_START - 1.0
	office._on_snapshot_changed(office._simulation.snapshot())
	office._routing_ui.set_peck_assist_clock_running(true)
	office._camera_controller.focus_worker(0)
	office._simulation.workers[0].work_progress = DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS
	office._on_snapshot_changed(office._simulation.snapshot())
	if show_missed:
		# Cross the same authoritative boundary as live play so Office receives the
		# real single-fire miss event before capture staging freezes its midpoint.
		office._simulation.workers[0].work_progress = DepartmentSimulation.PECK_ASSIST_WINDOW_END
		office._simulation.advance_tick()
	elif show_result:
		# Run the same live-clock preflight as normal keyboard/controller input,
		# then freeze only after the atomic result has been authored.
		office._clock.set_speed(1)
		office._routing_ui.set_peck_assist_clock_running(true)
		office._on_peck_assist_requested(0)
		if show_delivery:
			office._simulation.workers[0].work_progress = 99.0
			office._simulation.advance_tick()
	else:
		office._workstation_feedback.pulse_peck_assist(0, &"perfect")
	# Freeze the authored gold-window/result frame for deterministic browser
	# inspection. The live mechanic still advances normally; only these explicit
	# capture fixtures hold the claim so the web client cannot arrive too late.
	office._clock.set_speed(0)
	office._on_snapshot_changed(office._simulation.snapshot())
	if show_missed:
		worker_view.stage_priority_peck_missed_capture()
		office._routing_ui.stage_peck_assist_missed_capture(0)
	elif not show_result:
		worker_view.stage_priority_peck_ready_capture()
	await office.get_tree().create_timer(0.18).timeout
	_save_preview(
		"peck_delivery.png"
		if show_delivery else
		(
			"peck_assist_missed.png"
			if show_missed else
			("peck_assist_result.png" if show_result else "peck_assist_ready.png")
		)
	)


func _capture_grading_preview() -> void:
	_prepare_capture_running()
	var worker_view: ChickenView = office._worker_views.get(0) as ChickenView
	if worker_view == null:
		push_error("Grading capture requires Mabel's worker view.")
		office.get_tree().quit(1)
		return
	# Browser startup and navigation settling are intentionally nondeterministic.
	# Stage the authored preview directly at the workstation so this fixture tests
	# the grading and payout beat rather than racing Mabel's opening walk cycle.
	worker_view.stage_at_workstation_for_introduction()
	office._simulation.set_worker_at_workstation(0, true)
	office._camera_controller.focus_point(Vector3(10.82, 2.48, -5.05), "SHELL GRADING", 0.35)
	office._simulation.revenue_cents += 455
	office._simulation.eggs_today += 1
	office._on_egg_laid(0, &"sound", 455)
	office._on_snapshot_changed(office._simulation.snapshot())
	office._clock.set_speed(0)
	await office.get_tree().create_timer(1.35).timeout
	_save_preview("egg_grading.png")


func _capture_egg_journey_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	var worker_view: ChickenView = office._worker_views.get(0) as ChickenView
	if worker_view == null:
		push_error("Egg journey capture requires Mabel's worker view.")
		office.get_tree().quit(1)
		return
	worker_view.stage_at_workstation_for_introduction()
	office._simulation.set_worker_at_workstation(0, true)
	office._simulation.advance_tick()
	office._on_snapshot_changed(office._simulation.snapshot())
	# This local-only fixture stages the already-tested presentation receipt
	# directly. Avoid spawning a second physical egg while the browser harness is
	# judging the intended separation between the new file and the prior outcome.
	office._begin_egg_journey_receipt(0, 9001, &"sound", 455, 455, 0)
	office._update_egg_journey_receipt(0, 9001, {
		"stage": &"delivered",
		"cash_cents": 455,
	})
	if office._character_dialogue_ui != null:
		office._character_dialogue_ui.clear_session()
	if office._routing_ui != null:
		office._routing_ui.set_focus(0)
	if office._camera_controller != null:
		office._camera_controller.focus_worker(0)
	office._clock.set_speed(0)
	await office.get_tree().create_timer(0.9).timeout
	var journey_preview := (
		office._routing_ui.egg_journey_receipt_state()
		if office._routing_ui != null and office._routing_ui.has_method("egg_journey_receipt_state") else
		{}
	)
	if (
		not bool(journey_preview.get("visible", false))
		or "LAST EGG #9001" not in String(journey_preview.get("copy", ""))
	):
		push_error(
			"Egg journey capture lost the separate previous-outcome receipt: ui=%s source=%s"
			% [JSON.stringify(journey_preview), JSON.stringify(office._egg_journey_receipt_snapshot())]
		)
		office.get_tree().quit(1)
		return
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	_save_preview("egg_journey.png")


func _capture_egg_delivery_ack_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	for worker_id in mini(3, office._simulation.workers.size()):
		var worker_view := office._worker_views.get(worker_id) as ChickenView
		if worker_view != null:
			worker_view.stage_at_workstation_for_introduction()
		office._simulation.set_worker_at_workstation(worker_id, true)
	office._simulation.advance_tick()
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._character_dialogue_ui != null:
		office._character_dialogue_ui.clear_session()
	if office._routing_ui != null:
		office._routing_ui.clear_focus()
	var presented := (
		office._workstation_feedback != null
		and office._workstation_feedback.play_egg_delivery_ack(
			1, 9002, &"sound", 455, false, true, 4.0,
		)
	)
	if not presented or not office._workstation_feedback.stage_egg_delivery_ack_capture(1):
		push_error("Egg delivery acknowledgment capture could not stage Pip's pooled marker.")
		office.get_tree().quit(1)
		return
	office._ticker_label.text = "PIP  ·  SOUND DELIVERED  ·  +$4.55 FUND  ·  +1 PECK"
	if office._camera_controller != null:
		office._camera_controller.focus_point(
			office._workstation_feedback.egg_delivery_ack_focus_point_global(1),
			"PIP PAYOUT",
			0.35,
			9.8,
		)
	office._clock.set_speed(0)
	await office.get_tree().create_timer(0.9).timeout
	var ack_state := office._workstation_feedback.egg_delivery_ack_snapshot()
	var acknowledgments := ack_state.get("acknowledgments", []) as Array
	var acknowledgment := acknowledgments[0] as Dictionary if acknowledgments.size() == 1 else {}
	if (
		int(ack_state.get("active_count", 0)) != 1
		or int(acknowledgment.get("worker_id", -1)) != 1
		or int(acknowledgment.get("claim_id", -1)) != 9002
		or String(acknowledgment.get("shape", "")) != "coin_up_arrow"
	):
		push_error("Egg delivery acknowledgment capture lost exact pooled state: %s" % JSON.stringify(ack_state))
		office.get_tree().quit(1)
		return
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	_save_preview("egg_delivery_ack.png")


func _capture_payout_burst_preview() -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	office._simulation.office_capacity = 6
	for worker_id in mini(6, office._simulation.workers.size()):
		var worker = office._simulation.workers[worker_id]
		worker.employed = true
		worker.desk_index = worker_id
	office._on_snapshot_changed(office._simulation.snapshot())
	await office.get_tree().process_frame
	for worker_id in mini(6, office._simulation.workers.size()):
		var worker_view := office._worker_views.get(worker_id) as ChickenView
		if worker_view != null:
			worker_view.stage_at_workstation_for_introduction()
		office._simulation.set_worker_at_workstation(worker_id, true)
	office._simulation.advance_tick()
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._character_dialogue_ui != null:
		office._character_dialogue_ui.clear_session()
	if office._routing_ui != null:
		office._routing_ui.clear_focus()
	var expected_total := 0
	for worker_id in mini(6, office._simulation.workers.size()):
		var payout_cents := 420 + worker_id * 35
		expected_total += payout_cents
		if (
			office._workstation_feedback == null
			or not office._workstation_feedback.play_egg_delivery_ack(
				worker_id, 9100 + worker_id, &"sound", payout_cents, false, false, 4.0,
			)
			or not office._workstation_feedback.stage_egg_delivery_ack_capture(worker_id)
		):
			push_error("Payout burst capture could not stage worker %d." % worker_id)
			office.get_tree().quit(1)
			return
		office._spawn_fund_credit_chip(payout_cents, &"sound")
	if not office.stage_fund_credit_batch_capture():
		push_error("Payout burst capture could not stage the consolidated Feed Fund chip.")
		office.get_tree().quit(1)
		return
	office._ticker_label.text = "6 DESKS DELIVERED  |  ONE CLEAR FUND UPDATE"
	if office._camera_controller != null:
		office._camera_controller.show_overview()
	office._clock.set_speed(0)
	await office.get_tree().create_timer(0.9).timeout
	var ack_state := office._workstation_feedback.egg_delivery_ack_snapshot()
	var batch_state := office.fund_credit_batch_snapshot()
	if (
		int(ack_state.get("active_count", 0)) != 6
		or int(batch_state.get("active_batch_count", 0)) != 1
		or int(batch_state.get("total_eggs", 0)) != 6
		or int(batch_state.get("total_value_cents", 0)) != expected_total
	):
		push_error(
			"Payout burst capture lost its 6-source/1-batch contract: ack=%s batch=%s"
			% [JSON.stringify(ack_state), JSON.stringify(batch_state)]
		)
		office.get_tree().quit(1)
		return
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	_save_preview("payout_burst.png")


func _capture_mixed_settlement_preview(
	focused := false,
	priority_contention := false,
	release_after_route := false,
	capture_destination := false,
) -> void:
	_prepare_capture_running()
	await office.get_tree().create_timer(5.5).timeout
	office._simulation.office_capacity = 6
	for worker_id in mini(6, office._simulation.workers.size()):
		var worker = office._simulation.workers[worker_id]
		worker.employed = true
		worker.desk_index = worker_id
	office._on_snapshot_changed(office._simulation.snapshot())
	await office.get_tree().process_frame
	for worker_id in mini(6, office._simulation.workers.size()):
		var worker_view := office._worker_views.get(worker_id) as ChickenView
		if worker_view != null:
			worker_view.stage_at_workstation_for_introduction()
		office._simulation.set_worker_at_workstation(worker_id, true)
	office._simulation.advance_tick()
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._character_dialogue_ui != null:
		office._character_dialogue_ui.clear_session()
	if office._routing_ui != null:
		office._routing_ui.clear_focus()
	if focused and office._camera_controller != null:
		office._camera_controller.focus_worker(0)
		await office.get_tree().create_timer(0.8).timeout
	if priority_contention:
		var operational_minute := office._simulation._current_operational_minute()
		# Make the visual alert an authoritative intake condition. A full six-hen
		# fixture can pull Appeals empty during its setup tick, so replenish one
		# ordinary file when needed and move other queued deadlines out of the way.
		for queue_value in office._simulation._claim_queues.values():
			for claim_value in queue_value as Array:
				var queued_claim := claim_value as ClaimState
				queued_claim.deadline_operational_minute = operational_minute + 120
		var appeals_queue := office._simulation._claim_queues.get(&"appeals", []) as Array
		if appeals_queue.is_empty():
			appeals_queue.append(ClaimState.new(
				99_201,
				&"appeals",
				"OVERDUE APPEAL",
				1.0,
				500,
				0.0,
				operational_minute - 60,
				operational_minute - 15,
				45,
			))
			office._simulation._claim_queues[&"appeals"] = appeals_queue
		var urgent_claim := appeals_queue[0] as ClaimState
		urgent_claim.deadline_operational_minute = operational_minute - 15
		if not office._arm_routing_return_cue({
			"routing_mastery": {
				"best_chain": 15,
				"next_record": 20,
				"target_kind": "record",
			},
		}):
			push_error("Settlement-priority capture could not arm the routing return cue.")
			office.get_tree().quit(1)
			return
		office._on_snapshot_changed(office._simulation.snapshot())
		office._update_guidance(office._simulation.snapshot())
		office._publish_status_copy(
			"OVERDUE APPEALS FILE. Route a best-fit hen before the claimant waits longer."
		)
	office._animation_speed_multiplier = 2.0
	if office._workstation_feedback != null:
		office._workstation_feedback.set_animation_speed_multiplier(2.0)
	var cash_values := [420, 455, 490]
	var stock_values := [560, 595, 630]
	var qualities: Array[StringName] = [&"sound", &"golden", &"sound"]
	var cash_total := 0
	var stock_total := 0
	for worker_id in 3:
		var cash_cents: int = cash_values[worker_id]
		cash_total += cash_cents
		if (
			office._workstation_feedback == null
			or not office._workstation_feedback.play_egg_delivery_ack(
				worker_id,
				9200 + worker_id,
				qualities[worker_id],
				cash_cents,
				false,
				worker_id == 0,
				4.0,
			)
			or not office._workstation_feedback.stage_egg_delivery_ack_capture(worker_id)
		):
			push_error("Mixed settlement capture could not stage cash worker %d." % worker_id)
			office.get_tree().quit(1)
			return
		office._spawn_fund_credit_chip(cash_cents, qualities[worker_id])
	for local_index in 3:
		var worker_id := local_index + 3
		var stock_cents: int = stock_values[local_index]
		stock_total += stock_cents
		if (
			office._workstation_feedback == null
			or not office._workstation_feedback.play_egg_delivery_ack(
				worker_id,
				9200 + worker_id,
				qualities[local_index],
				0,
				true,
				worker_id == 3,
				4.0,
			)
			or not office._workstation_feedback.stage_egg_delivery_ack_capture(worker_id)
		):
			push_error("Mixed settlement capture could not stage stock worker %d." % worker_id)
			office.get_tree().quit(1)
			return
		office._spawn_farmgate_stock_chip(stock_cents, qualities[local_index])
	office._spawn_attention_refund_chip({"charges_after": 2}, &"sound")
	office._spawn_attention_refund_chip({"charges_after": 3}, &"golden")
	if not office.stage_fund_credit_batch_capture() or not office.stage_auxiliary_settlement_capture():
		push_error("Mixed settlement capture could not stage the three transaction lanes.")
		office.get_tree().quit(1)
		return
	office._ticker_label.text = "10x SETTLEMENT  |  3 CASH  |  3 STOCK  |  +2 PECKS"
	if priority_contention:
		# WebGL startup and diagnostic sampling can consume several wall-clock
		# seconds between staging and evidence capture. Keep this local fixture's
		# already-published action toast alive long enough to prove arbitration;
		# production notice duration remains governed by the player's preference.
		office._ticker_hide_at_msec = Time.get_ticks_msec() + 15000
	if office._camera_controller != null and not focused:
		office._camera_controller.show_overview()
	office._clock.set_speed(0)
	await office.get_tree().create_timer(0.9).timeout
	var ack_state := office._workstation_feedback.egg_delivery_ack_snapshot()
	var fund_state := office.fund_credit_batch_snapshot()
	var auxiliary_state := office.auxiliary_settlement_snapshot()
	var placement_state := office.settlement_feedback_placement_snapshot()
	var arbitration_state := office.settlement_feedback_arbitration_snapshot()
	var notification_state := office._notification_diagnostic_state()
	var priority_contract_met := (
		int(placement_state.get("visible_card_count", 0)) == 0
		and int(placement_state.get("deferred_card_count", 0)) == 3
		and int(arbitration_state.get("deferred_batch_count", 0)) == 3
		and bool((arbitration_state.get("attention", {}) as Dictionary).get(
			"active",
			false,
		))
		and bool(notification_state.get("toast_visible", false))
		and String(notification_state.get("toast_priority", "")) == "action"
		and String(notification_state.get("toast_copy", "")).contains("OVERDUE APPEALS")
		and bool(office._routing_return_cue_diagnostic_state().get("visible", false))
	)
	if (
		int(ack_state.get("active_count", 0)) != 6
		or int(fund_state.get("active_batch_count", 0)) != 1
		or int(fund_state.get("total_eggs", 0)) != 3
		or int(fund_state.get("total_value_cents", 0)) != cash_total
		or int(auxiliary_state.get("active_batch_count", 0)) != 2
		or int(auxiliary_state.get("stock_eggs", 0)) != 3
		or int(auxiliary_state.get("stock_value_cents", 0)) != stock_total
		or int(auxiliary_state.get("pecks_restored", 0)) != 2
		or not bool(placement_state.get("all_safe", false))
		or (
			priority_contention
			and not priority_contract_met
		)
		or (
			focused
			and not priority_contention
			and int(placement_state.get("clamped_count", 0)) != 3
		)
	):
		push_error(
			"Mixed settlement capture lost its 6-source/3-lane priority-safe contract: ack=%s fund=%s auxiliary=%s placement=%s arbitration=%s notifications=%s"
			% [
				JSON.stringify(ack_state),
				JSON.stringify(fund_state),
				JSON.stringify(auxiliary_state),
				JSON.stringify(placement_state),
				JSON.stringify(arbitration_state),
				JSON.stringify(notification_state),
			]
		)
		office.get_tree().quit(1)
		return
	if release_after_route:
		# Cross the same tray -> ranked hen -> accepted dispatch authority used in
		# play. The accepted route retires its now-stale alert, but the three routine
		# lanes wait for the physical folder to reach the chosen desk. That landing
		# becomes their shared origin and owns the single audio beat.
		await office.get_tree().process_frame
		office._on_guidance_action_pressed()
		var priority := office._routing_ui.dispatch_priority_state()
		var priority_lane := StringName(String(priority.get("lane", "")))
		if priority_lane != &"appeals":
			push_error("Settlement-release capture did not rank overdue Appeals first.")
			office.get_tree().quit(1)
			return
		office._on_dispatch_lane_requested(priority_lane)
		var worker_id := office._dispatch_recommended_worker_id
		if worker_id < 0:
			push_error("Settlement-release capture could not rank an Appeals hen.")
			office.get_tree().quit(1)
			return
		if office._simulation.workers[worker_id].assigned_lane == priority_lane:
			office._simulation.set_worker_assignment(worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
		var audio_before: Dictionary = (
			office._audio_feedback.feedback_snapshot() if office._audio_feedback != null else {}
		)
		if not office._commit_dispatch(worker_id):
			push_error("Settlement-release capture could not file its accepted route.")
			office.get_tree().quit(1)
			return
		await office.get_tree().process_frame
		var crossing_arbitration := office.settlement_feedback_arbitration_snapshot()
		var crossing_blocked := false
		for blocker_value in (
			(crossing_arbitration.get("attention", {}) as Dictionary).get("blockers", [])
		):
			if String((blocker_value as Dictionary).get("id", "")) == "routing_delivery":
				crossing_blocked = true
				break
		if (
			not crossing_blocked
			or int(crossing_arbitration.get("deferred_batch_count", 0)) != 3
			or int(crossing_arbitration.get("released_batch_count", -1)) != 0
		):
			push_error(
				"Settlement-release capture did not hold its receipt fan behind the crossing folder: %s"
				% JSON.stringify(crossing_arbitration)
			)
			office.get_tree().quit(1)
			return
		# Advance only until the real delivery callback crosses the handoff. This
		# remains frame-bounded under slow WebGL and avoids a guessed capture delay.
		for _frame in 180:
			if int(office.settlement_feedback_arbitration_snapshot().get("release_serial", 0)) >= 1:
				break
			await office.get_tree().process_frame
		var landing_staged := (
			office._workstation_feedback != null
			and office._workstation_feedback.stage_dispatch_landing_capture(worker_id)
		)
		var released_arbitration := office.settlement_feedback_arbitration_snapshot()
		var dismissal := office._routing_return_cue_diagnostic_state().get("dismissal", {}) as Dictionary
		var release_receipt := released_arbitration.get("last_release", {}) as Dictionary
		var route_handoff := released_arbitration.get("last_route_handoff", {}) as Dictionary
		var released_placement := office.settlement_feedback_placement_snapshot()
		var audio_after: Dictionary = (
			office._audio_feedback.feedback_snapshot() if office._audio_feedback != null else {}
		)
		var audio_available := not bool(audio_before.get("focus_paused", false))
		var expected_release_cues := 1 if audio_available else 0
		if (
			bool(office._notification_diagnostic_state().get("toast_visible", true))
			or bool(office._routing_return_cue_diagnostic_state().get("active", true))
			or not bool(dismissal.get("resolved_action_toast_retired", false))
			or not bool(dismissal.get("settlement_handoff_armed", false))
			or not landing_staged
			or int(released_arbitration.get("visible_batch_count", 0)) != 3
			or int(released_arbitration.get("deferred_batch_count", -1)) != 0
			or int(released_arbitration.get("released_batch_count", 0)) != 3
			or int(released_arbitration.get("release_cue_count", 0))
			!= expected_release_cues
			or String(release_receipt.get("source", "")) != "dispatch_landing"
			or String(release_receipt.get("causal_path", ""))
			!= "accepted_route>folder_landing>receipt_fan"
			or not bool(release_receipt.get("physical_landing_cue_suppressed", false))
			or String(route_handoff.get("status", "")) != "receipts_released"
			or not bool(route_handoff.get("physical_landing_cue_suppressed", false))
			or not bool(released_placement.get("all_safe", false))
			or int(released_placement.get("visible_card_count", 0)) != 3
			or bool(release_receipt.get("cue_played", false)) != audio_available
			or (
				audio_available
				and String(audio_after.get("last_cue", "")) != "settlement_release"
			)
			or int(audio_after.get("cue_serial", 0))
			!= int(audio_before.get("cue_serial", 0)) + expected_release_cues
		):
			push_error(
				"Settlement-release capture lost its accepted-route/physical-origin/single-beat contract: dismissal=%s arbitration=%s placement=%s audio_before=%s audio_after=%s"
				% [
					JSON.stringify(dismissal),
					JSON.stringify(released_arbitration),
					JSON.stringify(released_placement),
					JSON.stringify(audio_before),
					JSON.stringify(audio_after),
				]
			)
			office.get_tree().quit(1)
			return
		if capture_destination:
			for visual in office._active_fund_credit_chips:
				visual.capture_staged = false
				visual.panel.set_meta("capture_staged", false)
			for visual in office._active_auxiliary_settlement_chips:
				visual.capture_staged = false
				visual.panel.set_meta("capture_staged", false)
			office._process_fund_credit_chip_pool(1.0)
			office._process_auxiliary_settlement_chip_pool(1.0)
			var destination_state := office.settlement_destination_ack_snapshot()
			var destination_release := (
				office.settlement_feedback_arbitration_snapshot().get(
					"last_release",
					{},
				) as Dictionary
			)
			var destination_receipts := (
				destination_state.get("last_by_kind", {}) as Dictionary
			)
			if (
				int(destination_state.get("pooled_count", 0)) != 3
				or int(destination_state.get("active_count", 0)) != 3
				or int(destination_state.get("started_total", 0)) != 3
				or int(destination_release.get("destination_acknowledgment_count", 0)) != 3
				or String(destination_release.get("completed_causal_path", ""))
				!= "accepted_route>folder_landing>receipt_fan>destination_surfaces"
				or String((destination_receipts.get("fund", {}) as Dictionary).get(
					"target_id", "",
				)) != "feed_fund_counter"
				or String((destination_receipts.get("stock", {}) as Dictionary).get(
					"target_id", "",
				)) != "flockwatch_inventory_ledger"
				or String((destination_receipts.get("refund", {}) as Dictionary).get(
					"target_id", "",
				)) != "priority_peck_meter"
				or int(office._audio_feedback.feedback_snapshot().get("cue_serial", 0))
				!= int(audio_after.get("cue_serial", 0))
				or office.stage_settlement_destination_ack_capture() != 3
			):
				push_error(
					"Settlement destination capture lost its bounded three-surface handoff: destinations=%s release=%s audio=%s"
					% [
						JSON.stringify(destination_state),
						JSON.stringify(destination_release),
						JSON.stringify(office._audio_feedback.feedback_snapshot()),
					]
				)
				office.get_tree().quit(1)
				return
			# The destination shapes must explain the handoff without capture-only prose.
			office._ticker_label.visible = false
			office._publish_web_diagnostic_state(office._simulation.snapshot(true))
			await office.get_tree().process_frame
			_save_preview("settlement_destination.png")
			return
		office._publish_web_diagnostic_state(office._simulation.snapshot(true))
		await office.get_tree().create_timer(0.12).timeout
		_save_preview("settlement_release.png")
		return
	office._publish_web_diagnostic_state(office._simulation.snapshot(true))
	_save_preview(
		"settlement_priority.png"
		if priority_contention else
		("mixed_settlement_focused.png" if focused else "mixed_settlement.png")
	)


func _capture_staffing_preview() -> void:
	_prepare_capture_running()
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, 50000)
	office._simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	office._simulation._incident_slot = DepartmentSimulation.INCIDENT_MINUTES.size()
	office._simulation.advance_tick()
	await office.get_tree().process_frame
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_FLOCK)
	await office.get_tree().create_timer(0.55).timeout
	_save_preview("roost_staffing.png")


func _capture_internship_ui_preview() -> void:
	_prepare_capture_running()
	office._simulation.day = 2
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, 50_000)
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_FLOCK)
	var internship_ui := office.find_child("InternshipProgramUI", true, false) as InternshipProgramUI
	if internship_ui != null:
		internship_ui.set_expanded(true)
	await office.get_tree().process_frame
	var scroll := office._flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_FLOCK)
	if scroll != null and internship_ui != null:
		var component_offset := (
			internship_ui.global_position.y
			- scroll.global_position.y
			+ float(scroll.scroll_vertical)
			- 24.0
		)
		scroll.scroll_vertical = maxi(0, int(component_offset))
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("bright_eyed_rotation.png")


func _capture_internship_review_ui_preview() -> void:
	_prepare_capture_running()
	office._simulation.day = 2
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, 50_000)
	var onboard := office._simulation.onboard_intern(&"lottie_ledger")
	if not bool(onboard.get("accepted", false)):
		push_error(
			"Intern review capture could not onboard Lottie: %s"
			% String(onboard.get("reason", "unknown reason"))
		)
		office.get_tree().quit(1)
		return
	var internship_state := office._simulation.get("_internship_program") as InternshipProgramState
	for completed_day in [2, 3, 4]:
		internship_state.complete_shift(completed_day)
	office._simulation.day = 5
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_FLOCK)
	var internship_ui := office.find_child("InternshipProgramUI", true, false) as InternshipProgramUI
	if internship_ui != null:
		internship_ui.set_expanded(true)
	await office.get_tree().process_frame
	var scroll := office._flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_FLOCK)
	if scroll != null and internship_ui != null:
		var component_offset := (
			internship_ui.global_position.y
			- scroll.global_position.y
			+ float(scroll.scroll_vertical)
			- 24.0
		)
		scroll.scroll_vertical = maxi(0, int(component_offset))
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("bright_eyed_review.png")


func _capture_internship_fellow_ui_preview() -> void:
	_prepare_capture_running()
	office._simulation.day = 2
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, 50_000)
	var onboard := office._simulation.onboard_intern(&"lottie_ledger")
	if not bool(onboard.get("accepted", false)):
		push_error(
			"Intern fellowship capture could not onboard Lottie: %s"
			% String(onboard.get("reason", "unknown reason"))
		)
		office.get_tree().quit(1)
		return
	var internship_state := office._simulation.get("_internship_program") as InternshipProgramState
	for completed_day in [2, 3, 4]:
		internship_state.complete_shift(completed_day)
	office._simulation.day = 5
	var fellowship := office._simulation.resolve_intern_review(
		&"lottie_ledger",
		&"paid_fellowship",
	)
	if not bool(fellowship.get("accepted", false)):
		push_error(
			"Intern fellowship capture could not file Lottie's paid post: %s"
			% String(fellowship.get("reason", "unknown reason"))
		)
		office.get_tree().quit(1)
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_FLOCK)
	var internship_ui := office.find_child("InternshipProgramUI", true, false) as InternshipProgramUI
	if internship_ui != null:
		internship_ui.set_expanded(true)
	await office.get_tree().process_frame
	var scroll := office._flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_FLOCK)
	if scroll != null and internship_ui != null:
		var component_offset := (
			internship_ui.global_position.y
			- scroll.global_position.y
			+ float(scroll.scroll_vertical)
			- 24.0
		)
		scroll.scroll_vertical = maxi(0, int(component_offset))
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("bright_eyed_paid_fellow.png")


func _capture_intern_dialogue_preview() -> void:
	_prepare_capture_running()
	office._simulation.day = 2
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, 50_000)
	if office._character_dialogue_ui != null:
		office._character_dialogue_ui.clear_session()
	var result := office._simulation.onboard_intern(&"lottie_ledger")
	if not bool(result.get("accepted", false)):
		push_error(
			"Intern dialogue capture could not onboard Lottie: %s"
			% String(result.get("reason", "unknown reason"))
		)
		office.get_tree().quit(1)
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._set_flockwatch_open(false)
	office._queue_character_dialogue(
		office.CharacterDialogueCatalogScript.beat_for_internship_action(result)
	)
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("intern_lottie_dialogue.png")


func _capture_facility_preview() -> void:
	_prepare_capture_running()
	office._simulation.apply_campaign_unlock(&"shell_quality_checks")
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.revenue_cents = maxi(
		office._simulation.revenue_cents,
		office._simulation.current_daily_operating_cost_cents() + 4300,
	)
	var receipt := office._simulation.purchase_facility(&"candling_rework_bay")
	if not bool(receipt.get("accepted", false)) and not office._simulation.has_facility(&"candling_rework_bay"):
		push_error("Facility art capture could not commission its QA bay: %s" % String(receipt.get("reason", "unknown reason")))
		office.get_tree().quit(1)
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._ui_root != null:
		office._ui_root.visible = false
	if office._workers_node != null:
		office._workers_node.visible = false
	if office._management_presence != null:
		office._management_presence.visible = false
	office._camera_controller.focus_point(Vector3(10.10, 0.82, 2.30), "FACILITY ART CHECK", 0.35, 3.45)
	await office.get_tree().create_timer(0.9).timeout
	_save_preview("candling_rework_bay.png")


func _capture_facility_ui_preview() -> void:
	_prepare_capture_running()
	office._simulation.apply_campaign_unlock(&"shell_quality_checks")
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.revenue_cents = office._simulation.current_daily_operating_cost_cents() + 10_000
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_CAPITAL)
	await office.get_tree().process_frame
	var scroll := office._flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_CAPITAL)
	var facility_card := office.find_child("FacilityCard_candling_rework_bay", true, false) as Control
	if scroll != null and facility_card != null:
		var component_offset := (
			facility_card.global_position.y
			- scroll.global_position.y
			+ float(scroll.scroll_vertical)
			- 24.0
		)
		scroll.scroll_vertical = maxi(0, int(component_offset))
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("facility_requisition.png")


func _capture_economic_briefing_ui_preview() -> void:
	_prepare_capture_running()
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = maxi(
		office._simulation.revenue_cents,
		office._simulation.current_daily_operating_cost_cents() + 10_000,
	)
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_CAPITAL)
	var scroll := office._flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_CAPITAL)
	if scroll != null:
		scroll.scroll_vertical = 0
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("economic_briefing.png")


func _capture_feed_procurement_ui_preview() -> void:
	_prepare_capture_running()
	office._simulation.day = 7
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = 100_000
	var receipt := office._simulation.purchase_facility(&"feed_procurement_coop")
	if not bool(receipt.get("accepted", false)):
		push_error("Feed-board capture could not commission Flock Provisions: %s" % String(
			receipt.get("reason", "unknown reason")
		))
		office.get_tree().quit(1)
		return
	# Keep one plan clearly actionable, one tier-held, and one fund-held. The
	# screenshot therefore exercises the same comparison states a real first-tier
	# filing produces instead of inventing presentation-only card data.
	office._simulation.revenue_cents = office._simulation.current_daily_operating_cost_cents() + 1800
	office._simulation._feed_procurement.begin_day(office._simulation.day)
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_OPERATIONS)
	await office.get_tree().process_frame
	var procurement_ui := office.find_child("FeedProcurementUI", true, false) as FeedProcurementUI
	if procurement_ui != null:
		procurement_ui.set_offers_expanded(true)
	var scroll := office._flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_OPERATIONS)
	if scroll != null and procurement_ui != null:
		var component_offset := (
			procurement_ui.global_position.y
			- scroll.global_position.y
			+ float(scroll.scroll_vertical)
			- 10.0
		)
		scroll.scroll_vertical = maxi(0, int(component_offset))
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("feed_procurement_ui.png")


func _capture_packing_annex_preview() -> void:
	_prepare_capture_running()
	office._simulation.day = 3
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = 100_000
	for _level in 3:
		var receipt := office._simulation.purchase_facility(&"farmer_brand_packing_annex")
		if not bool(receipt.get("accepted", false)):
			push_error(
				"Packing Annex art capture could not commission a tier: %s" % String(
					receipt.get("reason", "unknown reason")
				)
			)
			office.get_tree().quit(1)
			return
	for _egg in 5:
		office._simulation.call("_apply_packing_contract_value", &"sound", 500)
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._ui_root != null:
		office._ui_root.visible = false
	if office._workers_node != null:
		office._workers_node.visible = false
	if office._management_presence != null:
		office._management_presence.visible = false
	office._camera_controller.focus_point(
		office.PACKING_ANNEX_FOCUS,
		"PACKING ANNEX ART CHECK",
		0.35,
		7.2,
	)
	await office.get_tree().create_timer(0.95).timeout
	_save_preview("packing_annex_level3.png")


func _capture_records_annex_preview() -> void:
	_prepare_capture_running()
	office._simulation.day = 3
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = 100_000
	for _level in 3:
		var receipt := office._simulation.purchase_facility(&"records_annex")
		if not bool(receipt.get("accepted", false)):
			push_error(
				"Records Annex art capture could not commission a tier: %s" % String(
					receipt.get("reason", "unknown reason")
				)
			)
			office.get_tree().quit(1)
			return
	var capture_lanes: Array[StringName] = [
		&"nest_damage",
		&"predator_loss",
		&"appeals",
	]
	var intake_index := 0
	while int(office._simulation.snapshot().get("claims_outstanding", 0)) < office._simulation.current_claim_capacity():
		office._simulation.call("_enqueue_new_claim", capture_lanes[intake_index % capture_lanes.size()])
		intake_index += 1
	office._simulation.call("_offer_new_claim", &"appeals")
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._ui_root != null:
		office._ui_root.visible = false
	if office._workers_node != null:
		office._workers_node.visible = false
	if office._management_presence != null:
		office._management_presence.visible = false
	office._camera_controller.focus_point(
		office.RECORDS_ANNEX_FOCUS,
		"RECORDS ANNEX ART CHECK",
		0.35,
		7.2,
	)
	await office.get_tree().create_timer(0.95).timeout
	_save_preview("records_annex_level3.png")


func _capture_service_coop_preview() -> void:
	_prepare_capture_running()
	_prepare_service_coop_capture_economy()
	for facility_id in [&"records_annex", &"farm_mutual_service_coop"]:
		for _level in 3:
			var receipt := office._simulation.purchase_facility(facility_id)
			if not bool(receipt.get("accepted", false)):
				push_error(
					"Service Coop art capture could not commission %s: %s" % [
						String(facility_id),
						String(receipt.get("reason", "unknown reason")),
					]
				)
				office.get_tree().quit(1)
				return
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._ui_root != null:
		office._ui_root.visible = false
	if office._workers_node != null:
		office._workers_node.visible = false
	if office._management_presence != null:
		office._management_presence.visible = false
	office._camera_controller.focus_point(
		office.FARM_MUTUAL_SERVICE_COOP_FOCUS,
		"SERVICE COOP ART CHECK",
		0.35,
		7.2,
	)
	await office.get_tree().create_timer(0.95).timeout
	_save_preview("farm_mutual_service_coop_level3.png")


func _capture_service_coop_ui_preview() -> void:
	_prepare_capture_running()
	office._simulation.day = 4
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = 100_000
	office._simulation.market_contracts_succeeded_total = 1
	office._simulation.market_contracts_breached_total = 0
	office._simulation.market_clean_contract_streak = 1
	office._simulation.best_market_clean_contract_streak = 1
	office._simulation.owned_facilities[&"records_annex"] = 1
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_CAPITAL)
	await office.get_tree().process_frame
	var scroll := office._flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_CAPITAL)
	var facility_card := office.find_child("FacilityCard_farm_mutual_service_coop", true, false) as Control
	if scroll != null and facility_card != null:
		var component_offset := (
			facility_card.global_position.y
			- scroll.global_position.y
			+ float(scroll.scroll_vertical)
			- 24.0
		)
		scroll.scroll_vertical = maxi(0, int(component_offset))
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("farm_mutual_service_coop_requisition.png")


func _capture_negotiation_room_preview() -> void:
	_prepare_capture_running()
	_prepare_service_coop_capture_economy()
	for facility_id in [&"records_annex", &"farm_mutual_service_coop"]:
		var max_level := int(office._simulation.facility_status(facility_id).get("max_level", 1))
		for _level in max_level:
			var tier_receipt := office._simulation.purchase_facility(facility_id)
			if not bool(tier_receipt.get("accepted", false)):
				push_error("Negotiation Room capture prerequisite held: %s" % String(tier_receipt.get("reason", "unknown reason")))
				office.get_tree().quit(1)
				return
	var room_receipt := office._simulation.purchase_facility(&"farm_mutual_negotiation_room")
	if not bool(room_receipt.get("accepted", false)):
		push_error("Negotiation Room art capture could not commission the room: %s" % String(room_receipt.get("reason", "unknown reason")))
		office.get_tree().quit(1)
		return
	var rider_receipt := office._simulation.sign_market_contract(
		&"predator_watch_pool",
		&"specialist_roost_endorsement",
	)
	if not bool(rider_receipt.get("accepted", false)):
		push_error("Negotiation Room art capture could not bind its rider: %s" % String(rider_receipt.get("reason", "unknown reason")))
		office.get_tree().quit(1)
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._ui_root != null:
		office._ui_root.visible = false
	if office._workers_node != null:
		office._workers_node.visible = false
	if office._management_presence != null:
		office._management_presence.visible = false
	office._camera_controller.focus_point(
		office.FARM_MUTUAL_NEGOTIATION_ROOM_FOCUS,
		"GOLD NEGOTIATION ROOM ART CHECK",
		0.35,
		7.4,
	)
	await office.get_tree().create_timer(0.95).timeout
	_save_preview("farm_mutual_negotiation_room.png")


func _capture_contract_board_world_preview() -> void:
	_prepare_capture_running()
	office._simulation.day = 3
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, 100_000)
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._ui_root != null:
		office._ui_root.visible = false
	if office._workers_node != null:
		office._workers_node.visible = false
	if office._management_presence != null:
		office._management_presence.visible = false
	office._camera_controller.focus_point(
		office.FARM_MUTUAL_BOARD_FOCUS,
		"FARM MUTUAL BOARD ART CHECK",
		0.35,
		4.8,
	)
	await office.get_tree().create_timer(0.95).timeout
	_save_preview("farm_mutual_contract_board_world.png")


func _capture_contract_board_ui_preview() -> void:
	_prepare_capture_running()
	office._simulation.day = 3
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, 100_000)
	office._on_snapshot_changed(office._simulation.snapshot())
	office._campaign_review_stage = &"contract_board"
	office._campaign_ui.show_contract_board(office._simulation.snapshot())
	office._set_campaign_modal_open(true)
	var board_ui := office._campaign_ui.contract_board_ui()
	if board_ui != null:
		board_ui.call("_on_offer_pressed", &"homestead_stability_binder")
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("farm_mutual_contract_board_ui.png")


func _capture_contract_pricing_ui_preview(access_rate := false) -> void:
	_prepare_capture_running()
	office._simulation.day = 3
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, 100_000)
	office._simulation.market_contracts_signed_total = 4
	office._simulation.market_contracts_succeeded_total = 4
	office._simulation.market_pricing_outcomes["community_access_rate_success"] = 1
	office._simulation.market_pricing_outcomes["executive_select_rate_success"] = 3
	office._on_snapshot_changed(office._simulation.snapshot())
	office._campaign_review_stage = &"contract_board"
	office._campaign_ui.show_contract_board(office._simulation.snapshot())
	office._set_campaign_modal_open(true)
	var board_ui := office._campaign_ui.contract_board_ui()
	var scroll: ScrollContainer
	var pricing_heading: Control
	if board_ui != null:
		board_ui.call("_on_offer_pressed", &"homestead_stability_binder")
		if access_rate:
			board_ui.call("_on_pricing_pressed", &"community_access_rate")
	await office.get_tree().process_frame
	if board_ui != null:
		scroll = board_ui.find_child("ContractBoardScroll", true, false) as ScrollContainer
		pricing_heading = board_ui.find_child(
			"ContractPricingHeading",
			true,
			false,
		) as Control
	if scroll != null and pricing_heading != null:
		scroll.ensure_control_visible(pricing_heading)
		scroll.scroll_vertical = mini(
			scroll.scroll_vertical + 300,
			roundi(scroll.get_v_scroll_bar().max_value),
		)
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview(
		"farm_mutual_contract_pricing_access_ui.png"
		if access_rate else
		"farm_mutual_contract_pricing_ui.png"
	)


func _capture_negotiation_board_ui_preview() -> void:
	_prepare_capture_running()
	_prepare_service_coop_capture_economy()
	office._simulation.day = 9
	for facility_id in [&"records_annex", &"farm_mutual_service_coop", &"farm_mutual_negotiation_room"]:
		var max_level := int(office._simulation.facility_status(facility_id).get("max_level", 1))
		for _level in max_level:
			var receipt := office._simulation.purchase_facility(facility_id)
			if not bool(receipt.get("accepted", false)):
				push_error("Negotiated Board capture prerequisite held: %s" % String(receipt.get("reason", "unknown reason")))
				office.get_tree().quit(1)
				return
	office._on_snapshot_changed(office._simulation.snapshot())
	office._campaign_review_stage = &"contract_board"
	office._campaign_ui.show_contract_board(office._simulation.snapshot())
	office._set_campaign_modal_open(true)
	var board_ui := office._campaign_ui.contract_board_ui()
	if board_ui != null:
		board_ui.call("_on_offer_pressed", &"predator_watch_pool")
		board_ui.call("_on_negotiation_toggle_pressed")
		board_ui.call("_on_clause_pressed", &"expedited_hatch_rider")
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("farm_mutual_negotiated_board_ui.png")


func _capture_wellness_nest_preview() -> void:
	_prepare_capture_running()
	_prepare_care_campus_capture_economy()
	for _level in 3:
		var receipt := office._simulation.purchase_facility(&"wellness_nest_room")
		if not bool(receipt.get("accepted", false)):
			push_error("Wellness Nest art capture could not commission a tier: %s" % String(receipt.get("reason", "unknown reason")))
			office.get_tree().quit(1)
			return
	office._on_snapshot_changed(office._simulation.snapshot())
	_hide_world_capture_overlays()
	office._camera_controller.focus_point(
		office.WELLNESS_NEST_FOCUS,
		"WELLNESS NEST ART CHECK",
		0.35,
		7.2,
	)
	await office.get_tree().create_timer(0.95).timeout
	_save_preview("wellness_nest_level3.png")


func _capture_training_roost_preview() -> void:
	_prepare_capture_running()
	_prepare_care_campus_capture_economy()
	for facility_id in [&"wellness_nest_room", &"training_roost"]:
		for _level in 3:
			var receipt := office._simulation.purchase_facility(facility_id)
			if not bool(receipt.get("accepted", false)):
				push_error(
					"Training Roost art capture could not commission %s: %s" % [
						String(facility_id),
						String(receipt.get("reason", "unknown reason")),
					]
				)
				office.get_tree().quit(1)
				return
	office._on_snapshot_changed(office._simulation.snapshot())
	_hide_world_capture_overlays()
	office._camera_controller.focus_point(
		office.TRAINING_ROOST_FOCUS,
		"TRAINING ROOST ART CHECK",
		0.35,
		7.2,
	)
	await office.get_tree().create_timer(0.95).timeout
	_save_preview("training_roost_level3.png")


func _capture_care_campus_preview() -> void:
	_prepare_capture_running()
	_prepare_care_campus_capture_economy()
	for facility_id in [&"wellness_nest_room", &"training_roost"]:
		for _level in 3:
			var receipt := office._simulation.purchase_facility(facility_id)
			if not bool(receipt.get("accepted", false)):
				push_error("Care campus capture could not commission %s: %s" % [String(facility_id), String(receipt.get("reason", "unknown reason"))])
				office.get_tree().quit(1)
				return
	office._on_snapshot_changed(office._simulation.snapshot())
	_hide_world_capture_overlays()
	office._camera_controller.focus_point(
		office.CARE_CAMPUS_FOCUS,
		"FLOCK CARE CAMPUS",
		0.35,
		14.2,
	)
	await office.get_tree().create_timer(0.95).timeout
	_save_preview("care_campus.png")


func _capture_flock_care_ui_preview() -> void:
	_prepare_capture_running()
	_prepare_care_campus_capture_economy()
	for facility_id in [&"wellness_nest_room", &"training_roost"]:
		var receipt := office._simulation.purchase_facility(facility_id)
		if not bool(receipt.get("accepted", false)):
			push_error("Flock Care UI capture could not commission %s: %s" % [
				String(facility_id),
				String(receipt.get("reason", "unknown reason")),
			])
			office.get_tree().quit(1)
			return
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_FLOCK)
	await office.get_tree().process_frame
	var care_section := office.find_child("FlockCareSection", true, false) as Control
	var scroll := office._flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_FLOCK)
	if scroll != null and care_section != null:
		var component_offset := (
			care_section.global_position.y
			- scroll.global_position.y
			+ float(scroll.scroll_vertical)
			- 10.0
		)
		scroll.scroll_vertical = maxi(0, int(component_offset))
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("flock_care_ui.png")


func _capture_farmer_relations_gallery_preview() -> void:
	_prepare_capture_running()
	_prepare_farmer_relations_gallery_capture_economy()
	for facility_id in [&"farmer_brand_packing_annex", &"farmer_relations_gallery"]:
		if not _commission_capture_facility(facility_id):
			return
	if not _prepare_farmer_relations_gallery_capture_record():
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	_hide_world_capture_overlays()
	office._camera_controller.focus_point(
		office.FARMER_RELATIONS_GALLERY_FOCUS,
		"HARVEST CREDIT GALLERY ART CHECK",
		0.35,
		7.2,
	)
	await office.get_tree().create_timer(0.95).timeout
	_save_preview("harvest_credit_gallery_level3.png")


func _capture_farmer_relations_ui_preview() -> void:
	_prepare_capture_running()
	_prepare_farmer_relations_gallery_capture_economy()
	for facility_id in [&"farmer_brand_packing_annex", &"farmer_relations_gallery"]:
		if not _commission_capture_facility(facility_id):
			return
	if not _prepare_farmer_relations_gallery_capture_offer():
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS)
	await office.get_tree().process_frame
	var gallery_ui := office.find_child("FarmerRelationsGalleryUI", true, false) as FarmerRelationsGalleryUI
	if gallery_ui != null:
		gallery_ui.set_campaigns_expanded(true)
	var scroll := office._flockwatch_navigation.page_scroll(
		FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS,
	)
	await office.get_tree().process_frame
	if scroll != null and gallery_ui != null:
		scroll.ensure_control_visible(gallery_ui)
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("farmer_relations_ui.png")


func _capture_rooster_operations_office_preview() -> void:
	_prepare_capture_running()
	_prepare_operations_campus_capture_economy()
	if not _commission_capture_facility(&"rooster_operations_office"):
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	_hide_world_capture_overlays()
	office._camera_controller.focus_point(
		office.ROOSTER_OPERATIONS_OFFICE_FOCUS,
		"ROOSTER OPERATIONS ART CHECK",
		0.35,
		7.2,
	)
	await office.get_tree().create_timer(0.95).timeout
	_save_preview("rooster_operations_office_level3.png")


func _capture_rooster_operations_ui_preview() -> void:
	_prepare_capture_running()
	_prepare_operations_campus_capture_economy()
	if not _commission_capture_facility(&"rooster_operations_office"):
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_OPERATIONS)
	office._staffing_ui.set_managers_expanded(false)
	office._staffing_ui.set_successors_expanded(false)
	await office.get_tree().process_frame
	var operations_section := office.find_child("RoosterOperationsSection", true, false) as Control
	var scroll := office._flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_OPERATIONS)
	if scroll != null and operations_section != null:
		var component_offset := (
			operations_section.global_position.y
			- scroll.global_position.y
			+ float(scroll.scroll_vertical)
			- 10.0
		)
		scroll.scroll_vertical = maxi(0, int(component_offset))
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("rooster_operations_ui.png")


func _capture_it_coop_preview() -> void:
	_prepare_capture_running()
	_prepare_operations_campus_capture_economy()
	for facility_id in [&"records_annex", &"rooster_operations_office", &"it_coop"]:
		if not _commission_capture_facility(facility_id):
			return
	office._on_snapshot_changed(office._simulation.snapshot())
	_hide_world_capture_overlays()
	office._camera_controller.focus_point(
		office.IT_COOP_FOCUS,
		"IT COOP ART CHECK",
		0.35,
		7.2,
	)
	await office.get_tree().create_timer(0.95).timeout
	_save_preview("it_coop_level3.png")


func _capture_operations_campus_preview() -> void:
	_prepare_capture_running()
	_prepare_operations_campus_capture_economy()
	for facility_id in [&"records_annex", &"rooster_operations_office", &"it_coop"]:
		if not _commission_capture_facility(facility_id):
			return
	office._on_snapshot_changed(office._simulation.snapshot())
	_hide_world_capture_overlays()
	office._camera_controller.focus_point(
		office.OPERATIONS_CAMPUS_FOCUS,
		"OPERATIONS CAMPUS",
		0.35,
		11.0,
	)
	await office.get_tree().create_timer(0.95).timeout
	_save_preview("operations_campus.png")


func _capture_flock_relations_preview() -> void:
	_prepare_capture_running()
	_prepare_care_campus_capture_economy()
	_prepare_operations_campus_capture_economy()
	_prepare_flock_relations_capture_economy()
	for facility_id in [&"wellness_nest_room", &"rooster_operations_office", &"flock_relations_office"]:
		if not _commission_capture_facility(facility_id):
			return
	_prepare_flock_relations_capture_cases()
	office._on_snapshot_changed(office._simulation.snapshot())
	_hide_world_capture_overlays()
	office._camera_controller.focus_point(
		office.FLOCK_RELATIONS_OFFICE_FOCUS,
		"FLOCK RELATIONS ART CHECK",
		0.35,
		7.2,
	)
	await office.get_tree().create_timer(0.95).timeout
	_save_preview("flock_relations_office_level3.png")


func _capture_flock_relations_ui_preview() -> void:
	_prepare_capture_running()
	_prepare_care_campus_capture_economy()
	_prepare_operations_campus_capture_economy()
	_prepare_flock_relations_capture_economy()
	for facility_id in [&"wellness_nest_room", &"rooster_operations_office"]:
		if not _commission_capture_facility(facility_id):
			return
	for _level in 2:
		var receipt := office._simulation.purchase_facility(&"flock_relations_office")
		if not bool(receipt.get("accepted", false)):
			push_error("Flock Relations UI capture could not commission tier two: %s" % String(
				receipt.get("reason", "unknown reason"),
			))
			office.get_tree().quit(1)
			return
	_prepare_flock_relations_ui_capture_case()
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS)
	await office.get_tree().process_frame
	var relations_ui := office.find_child("FlockRelationsCaseUI", true, false) as FlockRelationsCaseUI
	if relations_ui != null:
		relations_ui.set_cases_expanded(true)
	var scroll := office._flockwatch_navigation.page_scroll(
		FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS,
	)
	await office.get_tree().process_frame
	if scroll != null and relations_ui != null:
		# The fixed Records heading already identifies this page. Start the Web
		# evidence at the case itself so its complete 2x2 action grid is visible;
		# the separate max-scale component capture proves the glance header above.
		scroll.scroll_vertical = 118
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("flock_relations_ui.png")


func _capture_flock_provisions_preview() -> void:
	_prepare_capture_running()
	_prepare_operations_campus_capture_economy()
	if not _commission_capture_facility(&"feed_procurement_coop"):
		return
	var order := office._simulation.authorize_feed_order(&"fixed_future_reserve")
	if not bool(order.get("accepted", false)):
		push_error("Provisions art capture could not file reserve order: %s" % String(
			order.get("reason", "unknown reason"),
		))
		office.get_tree().quit(1)
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	_hide_world_capture_overlays()
	office._camera_controller.focus_point(
		office.FLOCK_PROVISIONS_COOP_FOCUS,
		"FLOCK PROVISIONS ART CHECK",
		0.35,
		7.2,
	)
	await office.get_tree().create_timer(0.95).timeout
	_save_preview("flock_provisions_coop_level3.png")


func _capture_governance_campus_preview() -> void:
	_prepare_capture_running()
	_prepare_care_campus_capture_economy()
	_prepare_operations_campus_capture_economy()
	_prepare_flock_relations_capture_economy()
	for facility_id in [
		&"wellness_nest_room",
		&"farmer_brand_packing_annex",
		&"farmer_relations_gallery",
		&"records_annex",
		&"rooster_operations_office",
		&"it_coop",
		&"flock_relations_office",
		&"feed_procurement_coop",
	]:
		if not _commission_capture_facility(facility_id):
			return
	if not _prepare_farmer_relations_gallery_capture_record():
		return
	var provisions_order := office._simulation.authorize_feed_order(&"fixed_future_reserve")
	if not bool(provisions_order.get("accepted", false)):
		push_error("Governance capture could not file provisions order: %s" % String(
			provisions_order.get("reason", "unknown reason"),
		))
		office.get_tree().quit(1)
		return
	_prepare_flock_relations_capture_cases()
	office._on_snapshot_changed(office._simulation.snapshot())
	_hide_world_capture_overlays()
	office._camera_controller.focus_point(
		office.GOVERNANCE_CAMPUS_FOCUS,
		"GOVERNANCE CAMPUS",
		0.35,
		18.2,
	)
	await office.get_tree().create_timer(0.95).timeout
	_save_preview("governance_campus.png")


func _capture_farmgate_dispatch_preview(target_level: int) -> void:
	_prepare_capture_running()
	if not _prepare_farmgate_capture_economy(target_level):
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	_hide_world_capture_overlays()
	office._camera_controller.focus_point(
		office.FARMGATE_DISPATCH_DEPOT_FOCUS,
		"FARMGATE DISPATCH ART CHECK",
		0.35,
		13.0,
	)
	await office.get_tree().create_timer(1.0).timeout
	var suffix := "locked" if target_level < 0 else ("survey" if target_level == 0 else "level%d" % target_level)
	_save_preview("farmgate_dispatch_%s.png" % suffix)


func _capture_farmgate_dispatch_ui_preview() -> void:
	_prepare_capture_running()
	if not _prepare_farmgate_capture_economy(1):
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_OPERATIONS)
	await office.get_tree().process_frame
	var dispatch_ui := office.find_child("FarmgateDispatchUI", true, false) as FarmgateDispatchUI
	if dispatch_ui != null:
		dispatch_ui.select_mandate(&"county_auction")
		dispatch_ui.set_mandate_expanded(true)
	var scroll := office._flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_OPERATIONS)
	await office.get_tree().process_frame
	if scroll != null and dispatch_ui != null:
		scroll.ensure_control_visible(dispatch_ui)
		# Keep the route economics and action together in the production evidence;
		# the component capture separately proves the reserve header at 150% scale.
		scroll.scroll_vertical += 88
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("farmgate_dispatch_ui.png")


func _capture_farmgate_filing_preview() -> void:
	_prepare_capture_running()
	if not _prepare_farmgate_capture_economy(1):
		return
	var result := office._simulation.authorize_farmgate_dispatch(&"county_auction")
	if not bool(result.get("accepted", false)):
		push_error("Farmgate filing capture could not authorize route: %s" % String(
			result.get("reason", "unknown reason"),
		))
		office.get_tree().quit(1)
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_OPERATIONS)
	await office.get_tree().process_frame
	var dispatch_ui := office.find_child("FarmgateDispatchUI", true, false) as FarmgateDispatchUI
	if dispatch_ui != null:
		dispatch_ui.select_mandate(&"county_auction")
		dispatch_ui.set_mandate_expanded(true)
	var scroll := office._flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_OPERATIONS)
	await office.get_tree().process_frame
	if scroll != null and dispatch_ui != null:
		scroll.ensure_control_visible(dispatch_ui)
		scroll.scroll_vertical += 88
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("farmgate_filing_receipt.png")


func _capture_settings_handoff_preview() -> void:
	_prepare_capture_running()
	office._on_settings_requested()
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("settings_action_handoff.png")


func _capture_first_clutch_playbook_preview() -> void:
	_prepare_capture_running()
	office._on_settings_requested()
	await office.get_tree().process_frame
	var reference_button := office.find_child("FirstClutchReplayButton", true, false) as Button
	if reference_button == null or reference_button.disabled:
		push_error("First Clutch playbook capture could not reach the Settings reference action.")
		office.get_tree().quit(1)
		return
	if String(office._settings_ui.first_clutch_reference_state().get("mode", "")) != "review":
		office._settings_ui.set_first_clutch_replay_available(false)
	reference_button.pressed.emit()
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("first_clutch_playbook.png")


func _capture_confirmation_handoff_preview() -> void:
	_prepare_capture_running()
	office._simulation.set_worker_at_workstation(0, true)
	for attempt in 3:
		if office._simulation.workers[0].current_claim != null:
			break
		office._simulation.advance_tick()
	await office.get_tree().process_frame
	office._routing_ui.set_focus(0)
	office._routing_ui.call("_on_dossier_tab_pressed", &"claim")
	# Isolate a routine floor notice so the shipped preview proves that the held
	# confirmation archives it instead of merely out-ranking an older milestone.
	if office._ticker_panel != null:
		office._ticker_panel.visible = false
	office._ticker_visible_copy = ""
	office._publish_status_copy(
		"CLAIMANT TERMS READY. Review the permanent path before choosing.",
		false,
	)
	var settle_button := office.find_child("ClaimResolution_settle", true, false) as Button
	if settle_button == null or settle_button.disabled:
		push_error("Confirmation handoff capture could not stage a claimant settlement.")
		office.get_tree().quit(1)
		return
	settle_button.pressed.emit()
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("claim_confirmation_handoff.png")


func _capture_staff_release_confirmation_preview() -> void:
	_prepare_capture_running()
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, 50_000)
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_FLOCK)
	await office.get_tree().process_frame
	var selector := office.find_child("ReleaseWorkerSelector", true, false) as OptionButton
	var release_button := office.find_child("ReleaseWorkerButton", true, false) as Button
	var release_index := -1
	if selector != null:
		for index in selector.item_count:
			if int(selector.get_item_metadata(index)) == 1:
				release_index = index
				break
	if selector == null or release_button == null or release_index < 0:
		push_error("Staff release capture could not find an eligible staged release.")
		office.get_tree().quit(1)
		return
	selector.select(release_index)
	selector.item_selected.emit(release_index)
	await office.get_tree().process_frame
	if release_button.disabled:
		push_error("Staff release capture found a disabled release filing.")
		office.get_tree().quit(1)
		return
	release_button.pressed.emit()
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("staff_release_confirmation.png")


func _capture_manager_succession_confirmation_preview() -> void:
	_prepare_capture_running()
	_prepare_operations_campus_capture_economy()
	if not _commission_capture_facility(&"rooster_operations_office"):
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_OPERATIONS)
	office._staffing_ui.set_managers_expanded(false)
	office._staffing_ui.set_successors_expanded(true)
	await office.get_tree().process_frame
	await office.get_tree().process_frame
	var recruit := office.find_child(
		"RecruitManager_byte_automation",
		true,
		false,
	) as Button
	if recruit == null or recruit.disabled:
		push_error("Manager succession capture could not stage Byte Bantam.")
		office.get_tree().quit(1)
		return
	recruit.pressed.emit()
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("manager_succession_confirmation.png")


func _capture_dispatch_campus_preview() -> void:
	_prepare_capture_running()
	if not _prepare_farmgate_capture_economy(3):
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	_hide_world_capture_overlays()
	office._camera_controller.focus_point(
		Vector3(19.15, 1.05, -2.60),
		"PACKING AND DISPATCH CAMPUS",
		0.35,
		19.0,
	)
	await office.get_tree().create_timer(1.0).timeout
	_save_preview("dispatch_campus.png")


func _capture_capital_blueprint_preview() -> void:
	_prepare_capture_running()
	if not _prepare_farmgate_capture_economy(0):
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	office._open_capital_blueprint(false, false)
	if office._capital_blueprint_ui != null:
		office._capital_blueprint_ui.call("select_facility", &"farmgate_dispatch_depot", false)
	await office.get_tree().create_timer(0.75).timeout
	_save_preview("capital_blueprint.png")


func _capture_commissioning_reveal_preview() -> void:
	_prepare_capture_running()
	if not _prepare_farmgate_capture_economy(0):
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	office._on_facility_purchase_requested(&"farmgate_dispatch_depot")
	await office.get_tree().create_timer(1.0).timeout
	_save_preview("farmgate_commissioning_reveal.png")


func _capture_campus_expansion_preview() -> void:
	_prepare_capture_running()
	if not _prepare_campus_expansion_capture_economy():
		return
	var snapshot := office._simulation.snapshot()
	office._on_snapshot_changed(snapshot)
	_settle_campus_workers_for_capture()
	_hide_world_capture_overlays()
	var art_bounds := office.CampusExpansionVisualScript.camera_bounds(snapshot)
	var art_focus := art_bounds.get_center()
	art_focus.y = office.NORTH_MEADOW_FOCUS.y
	var frame_size := maxf(art_bounds.size.x, art_bounds.size.z) + 1.0
	office._camera_controller.focus_point(
		art_focus,
		"NORTH MEADOW CAMPUS ART CHECK",
		0.35,
		frame_size,
	)
	await office.get_tree().create_timer(1.0).timeout
	_save_preview("campus_expansion_operational.png")


func _capture_campus_portfolio_preview() -> void:
	_prepare_capture_running()
	if not _prepare_campus_portfolio_capture_economy():
		return
	var snapshot := office._simulation.snapshot()
	office._on_snapshot_changed(snapshot)
	_hide_world_capture_overlays()
	var art_bounds := office.CampusPortfolioVisualScript.camera_bounds(snapshot)
	var art_focus := art_bounds.get_center()
	art_focus.y = office.CAMPUS_PORTFOLIO_FOCUS.y
	var frame_size := maxf(art_bounds.size.x, art_bounds.size.z) + 1.5
	office._camera_controller.focus_point(
		art_focus,
		"CAMPUS PORTFOLIO ART CHECK",
		0.35,
		frame_size,
	)
	await office.get_tree().create_timer(1.0).timeout
	_save_preview("campus_portfolio_complete.png")


func _capture_campus_portfolio_reveal_preview() -> void:
	_prepare_capture_running()
	if not _prepare_campus_expansion_capture_economy():
		return
	office._simulation._campus_portfolio.begin_day(
		office._simulation.day,
		office._simulation._campus_portfolio_context(),
	)
	var result := office._simulation.purchase_campus_portfolio_deed(&"orchard_row")
	if not _campus_capture_receipt_accepted(result, "purchase Orchard Row for reveal"):
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = false
	office._set_campaign_modal_open(false)
	office._resolve_campus_portfolio_action(result, "capture_campus_portfolio_reveal", &"orchard_row")
	await office.get_tree().create_timer(0.75).timeout
	_save_preview("campus_portfolio_reveal.png")


func _settle_campus_workers_for_capture() -> void:
	# Portfolio captures should prove the named staffing promise, not photograph
	# four hens halfway through a long first commute. Large deltas are isolated to
	# this deterministic capture path and still consume every authored waypoint.
	for view_value: Variant in office._worker_views.values():
		var view := view_value as ChickenView
		if view == null or not is_instance_valid(view) or not view.has_campus_duty_assignment():
			continue
		for _capture_step in 170:
			if view.is_at_campus_duty_station():
				break
			view.call("_physics_process", 0.75)


func _capture_campus_portfolio_ui_preview() -> void:
	_prepare_capture_running()
	if not _prepare_campus_portfolio_capture_economy():
		return
	office._on_snapshot_changed(office._simulation.snapshot())
	office._on_campus_expansion_requested()
	if office._campus_portfolio_ui != null:
		office._campus_portfolio_ui.call("select_parcel", &"creekside_yard")
		office._campus_portfolio_ui.call("select_pad", &"creekside_east")
		office._campus_portfolio_ui.call("select_module", &"creekside_chilling_exchange")
	await office.get_tree().create_timer(0.75).timeout
	_save_preview("campus_portfolio_ui.png")


func _prepare_campus_portfolio_capture_economy() -> bool:
	if not _prepare_campus_expansion_capture_economy():
		return false
	office._simulation._campus_portfolio.begin_day(
		office._simulation.day,
		office._simulation._campus_portfolio_context(),
	)
	var deed := office._simulation.purchase_campus_portfolio_deed(&"orchard_row")
	if not _campus_capture_receipt_accepted(deed, "purchase Orchard Row"):
		return false
	deed = office._simulation.purchase_campus_portfolio_deed(&"creekside_yard")
	if not _campus_capture_receipt_accepted(deed, "purchase Creekside Yard"):
		return false
	for project_file: Dictionary in [
		{"module": &"collection_rail_hub", "pad": &"orchard_west"},
		{"module": &"grain_recovery_mill", "pad": &"orchard_east"},
		{"module": &"contractor_roost", "pad": &"creekside_west"},
	]:
		var project := office._simulation.authorize_campus_portfolio_project(
			project_file["module"],
			project_file["pad"],
		)
		if not _campus_capture_receipt_accepted(
			project,
			"authorize %s" % String(project_file["module"]).replace("_", " "),
		):
			return false
	for target_day in [16, 19, 21]:
		office._simulation.day = target_day
		office._simulation._campus_portfolio.begin_day(
			target_day,
			office._simulation._campus_portfolio_context(),
		)
	var staffing := office._simulation.assign_campus_portfolio_worker(&"contractor_roost", 3)
	if not _campus_capture_receipt_accepted(staffing, "staff Contractor Roost"):
		return false
	var chilling := office._simulation.authorize_campus_portfolio_project(
		&"creekside_chilling_exchange",
		&"creekside_east",
	)
	if not _campus_capture_receipt_accepted(chilling, "authorize Creekside Chilling Exchange"):
		return false
	office._simulation.day = 24
	office._simulation._campus_portfolio.begin_day(
		24,
		office._simulation._campus_portfolio_context(),
	)
	for assignment: Dictionary in [
		{"module": &"collection_rail_hub", "worker": 0},
		{"module": &"grain_recovery_mill", "worker": 1},
		{"module": &"creekside_chilling_exchange", "worker": 2},
	]:
		staffing = office._simulation.assign_campus_portfolio_worker(
			assignment["module"],
			int(assignment["worker"]),
		)
		if not _campus_capture_receipt_accepted(
			staffing,
			"staff %s" % String(assignment["module"]).replace("_", " "),
		):
			return false
	return true


func _prepare_campus_expansion_capture_economy() -> bool:
	# Establish only the deterministic access and funding fixture directly. Every
	# capital mutation below must pass through the simulation's receipt-producing
	# authorization API so the capture exercises the same rules as live play.
	office._simulation.day = 14
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = 1_000_000
	office._simulation.market_contracts_succeeded_total = 1
	office._simulation.market_contracts_breached_total = 0

	var receipt := office._simulation.purchase_campus_parcel(&"north_meadow")
	if not _campus_capture_receipt_accepted(receipt, "purchase North Meadow"):
		return false
	for service_id: StringName in [&"circulation", &"power", &"cold_chain"]:
		receipt = office._simulation.commission_campus_service(service_id)
		if not _campus_capture_receipt_accepted(
			receipt,
			"commission %s" % String(service_id).replace("_", " "),
		):
			return false
	receipt = office._simulation.place_campus_module(office.CAMPUS_ROUTING_POD_ID, &"meadow_west")
	if not _campus_capture_receipt_accepted(receipt, "place the Egg Routing Pod"):
		return false

	var campus := office._simulation.campus_expansion_snapshot()
	var connected_services: Dictionary[StringName, bool] = {}
	for service_value in campus.get("services", []) as Array:
		if not service_value is Dictionary:
			continue
		var service := service_value as Dictionary
		connected_services[StringName(String(service.get("id", "")))] = bool(
			service.get("connected", false)
		)
	var fixture_is_operational := (
		bool(campus.get("parcel_owned", false))
		and bool(connected_services.get(&"circulation", false))
		and bool(connected_services.get(&"power", false))
		and bool(connected_services.get(&"cold_chain", false))
		and bool(campus.get("pod_operational", false))
		and bool(campus.get("cold_chain_active", false))
		and StringName(String(campus.get("pod_socket_id", ""))) == &"meadow_west"
	)
	if not fixture_is_operational:
		push_error(
			"Campus expansion art capture fixture did not reach its operational state: %s"
			% String(campus.get("summary", "missing campus summary"))
		)
		office.get_tree().quit(1)
		return false
	return true


func _campus_capture_receipt_accepted(receipt: Dictionary, action_label: String) -> bool:
	if bool(receipt.get("accepted", false)):
		return true
	push_error("Campus expansion art capture could not %s: %s" % [
		action_label,
		String(receipt.get("reason", "unknown reason")),
	])
	office.get_tree().quit(1)
	return false


func _prepare_farmgate_capture_economy(target_level: int) -> bool:
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, 1_000_000)
	if target_level < 0:
		office._simulation.day = 1
		office._simulation._farmgate_dispatch.begin_day(1)
		return true
	office._simulation.day = 14
	office._simulation.office_capacity = 6
	for worker_index in mini(6, office._simulation.workers.size()):
		var worker = office._simulation.workers[worker_index]
		worker.employed = true
		worker.desk_index = worker_index
	office._simulation._harvest_credit.public_standing = 25
	office._simulation._farmgate_dispatch.begin_day(14)
	var prerequisite_level := 3 if target_level == 0 else target_level
	for facility_id in [&"farmer_brand_packing_annex", &"farmer_relations_gallery"]:
		while office._simulation.facility_level(facility_id) < prerequisite_level:
			var prerequisite := office._simulation.purchase_facility(facility_id)
			if not bool(prerequisite.get("accepted", false)):
				push_error("Farmgate capture prerequisite held: %s" % String(
					prerequisite.get("reason", "unknown reason"),
				))
				office.get_tree().quit(1)
				return false
	while office._simulation.facility_level(&"farmgate_dispatch_depot") < target_level:
		var receipt := office._simulation.purchase_facility(&"farmgate_dispatch_depot")
		if not bool(receipt.get("accepted", false)):
			push_error("Farmgate capture tier held: %s" % String(
				receipt.get("reason", "unknown reason"),
			))
			office.get_tree().quit(1)
			return false
	if target_level > 0:
		var lot_count: int = int([0, 5, 11, 18][target_level])
		for lot_index in lot_count:
			office._simulation._farmgate_dispatch.store_lot(
				9_000 + lot_index,
				14,
				lot_index % 6,
				"CAPTURE HEN %d" % (lot_index % 6 + 1),
				&"golden" if lot_index % 5 == 0 else &"sound",
				450 + lot_index * 35,
				target_level,
				office._simulation._farmgate_shelf_life_shifts(),
				office._simulation._farmgate_storage_capacity_eggs(),
			)
	return true


func _capture_expansion_overview_preview() -> void:
	_prepare_capture_running()
	_prepare_service_coop_capture_economy()
	_prepare_care_campus_capture_economy()
	_prepare_operations_campus_capture_economy()
	_prepare_flock_relations_capture_economy()
	office._simulation.day = maxi(office._simulation.day, 14)
	office._simulation._harvest_credit.public_standing = maxi(
		office._simulation._harvest_credit.public_standing,
		25,
	)
	office._simulation.apply_campaign_unlock(&"shell_quality_checks")
	for facility_id in [
		&"candling_rework_bay",
		&"farmer_brand_packing_annex",
		&"records_annex",
		&"farm_mutual_service_coop",
		&"farm_mutual_negotiation_room",
		&"wellness_nest_room",
		&"training_roost",
		&"farmer_relations_gallery",
		&"rooster_operations_office",
		&"it_coop",
		&"flock_relations_office",
		&"feed_procurement_coop",
		&"farmgate_dispatch_depot",
	]:
		var max_level := int(office._simulation.facility_status(facility_id).get("max_level", 1))
		for _level in max_level:
			var receipt := office._simulation.purchase_facility(facility_id)
			if not bool(receipt.get("accepted", false)):
				push_error(
					"Expansion overview could not commission %s: %s" % [
						String(facility_id),
						String(receipt.get("reason", "unknown reason")),
					]
				)
				office.get_tree().quit(1)
				return
	office._on_snapshot_changed(office._simulation.snapshot())
	_hide_world_capture_overlays()
	office._camera_controller.show_overview()
	await office.get_tree().create_timer(1.0).timeout
	_save_preview("expansion_overview.png")


func _prepare_service_coop_capture_economy() -> void:
	office._simulation.day = 7
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = 1_000_000
	office._simulation.market_contracts_succeeded_total = 6
	office._simulation.market_contracts_breached_total = 0
	office._simulation.market_clean_contract_streak = 6
	office._simulation.best_market_clean_contract_streak = 6
	office._simulation.office_capacity = 6
	for worker_index in mini(6, office._simulation.workers.size()):
		var worker = office._simulation.workers[worker_index]
		worker.employed = true
		worker.desk_index = worker_index


func _prepare_care_campus_capture_economy() -> void:
	office._simulation.day = maxi(office._simulation.day, 10)
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, 1_000_000)
	office._simulation.office_capacity = 6
	var credential_lanes: Array[StringName] = [&"appeals", &"nest_damage", &"predator_loss"]
	for worker_index in mini(6, office._simulation.workers.size()):
		var worker = office._simulation.workers[worker_index]
		worker.employed = true
		worker.desk_index = worker_index
		worker.career_xp = maxi(worker.career_xp, 80)
		if worker_index < 3:
			var credential_lane := credential_lanes[worker_index]
			if credential_lane == worker.specialty:
				credential_lane = credential_lanes[(worker_index + 1) % credential_lanes.size()]
			worker.secondary_specialty = credential_lane
		elif worker_index == 3:
			var training_lane := &"appeals" if worker.specialty != &"appeals" else &"predator_loss"
			worker.cross_training_target = training_lane


func _prepare_operations_campus_capture_economy() -> void:
	office._simulation.day = maxi(office._simulation.day, 12)
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, 1_000_000)
	office._simulation.office_capacity = 6
	for worker_index in mini(6, office._simulation.workers.size()):
		var worker = office._simulation.workers[worker_index]
		worker.employed = true
		worker.desk_index = worker_index


func _prepare_flock_relations_capture_economy() -> void:
	office._simulation.day = maxi(office._simulation.day, 13)
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, 1_000_000)
	office._simulation.office_capacity = 6
	for worker_index in mini(6, office._simulation.workers.size()):
		var worker = office._simulation.workers[worker_index]
		worker.employed = true
		worker.desk_index = worker_index
		worker.manager_trust = 72.0
		worker.grievance = 10.0
		worker.stress = 22.0
		worker.fatigue = 16.0


func _prepare_farmer_relations_gallery_capture_economy() -> void:
	office._simulation.day = maxi(office._simulation.day, 13)
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = maxi(office._simulation.revenue_cents, 1_000_000)
	office._simulation.office_capacity = 6
	for worker_index in mini(6, office._simulation.workers.size()):
		var worker = office._simulation.workers[worker_index]
		worker.employed = true
		worker.desk_index = worker_index


func _prepare_farmer_relations_gallery_capture_record() -> bool:
	# Close one authored basket through the real simulation, then file the shared
	# results campaign. The capture therefore cannot invent a hen, payout, standing
	# tier, or attribution receipt that gameplay did not produce.
	if not _prepare_farmer_relations_gallery_capture_offer():
		return false
	var campaign := office._simulation.file_farmer_relations_campaign(&"clutch_results_board")
	if not bool(campaign.get("accepted", false)):
		push_error("Gallery art capture could not file its results campaign: %s" % String(
			campaign.get("reason", "unknown reason"),
		))
		office.get_tree().quit(1)
		return false
	return true


func _prepare_farmer_relations_gallery_capture_offer() -> bool:
	# Stage the same real closed shift used by the permanent world-art receipt,
	# but stop at the three-way public-credit choice for UI evidence.
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	office._simulation.pending_decision.clear()
	office._simulation.eggs_today = 29
	office._simulation.cracked_today = 2
	office._simulation.golden_today = 1
	office._simulation.eggs_total = maxi(office._simulation.eggs_total, 29)
	office._simulation.cracked_eggs = maxi(office._simulation.cracked_eggs, 2)
	office._simulation.golden_eggs = maxi(office._simulation.golden_eggs, 1)
	office._simulation.quota_target = 24
	office._simulation.credited_today_cents = 12_400
	if not office._simulation.workers.is_empty():
		var top_row: Dictionary = office._simulation._worker_shift_stats[0]
		top_row.merge({
			"eggs": 9,
			"sound": 8,
			"cracked": 1,
			"golden": 1,
			"credit_cents": 4_200,
		}, true)
		office._simulation._worker_shift_stats[0] = top_row
	office._simulation._complete_workday()
	var gallery := office._simulation.farmer_relations_gallery_snapshot()
	if StringName(String(gallery.get("campaign_status", ""))) != &"offer_open":
		push_error("Gallery UI capture could not stage its public-credit offer: %s" % String(
			gallery.get("campaign_status", "missing status"),
		))
		office.get_tree().quit(1)
		return false
	return true


func _prepare_flock_relations_capture_cases() -> void:
	# Use the real deterministic filing and resolution APIs so the room never
	# depicts a folder, settlement, or outcome lamp that the economy did not own.
	if office._simulation.workers.size() < 3:
		return
	var first_worker = office._simulation.workers[0]
	first_worker.manager_trust = 24.0
	first_worker.grievance = 82.0
	first_worker.stress = 76.0
	first_worker.fatigue = 68.0
	office._simulation.call("_file_flock_relations_case_after_shift", office._simulation.day)
	var first_snapshot := office._simulation.flock_relations_snapshot()
	var first_cases := first_snapshot.get("open_cases", []) as Array
	if not first_cases.is_empty():
		var first_case := first_cases[0] as Dictionary
		office._simulation.resolve_flock_relations_case(
			int(first_case.get("case_id", 0)),
			&"fund_remedy",
		)
	first_worker.manager_trust = 72.0
	first_worker.grievance = 10.0
	first_worker.stress = 22.0
	first_worker.fatigue = 16.0

	var second_worker = office._simulation.workers[1]
	second_worker.manager_trust = 32.0
	second_worker.grievance = 70.0
	second_worker.stress = 68.0
	second_worker.fatigue = 60.0
	office._simulation.call("_file_flock_relations_case_after_shift", office._simulation.day)

	var third_worker = office._simulation.workers[2]
	third_worker.manager_trust = 38.0
	third_worker.grievance = 58.0
	third_worker.stress = 70.0
	third_worker.fatigue = 66.0
	office._simulation.call("_file_flock_relations_case_after_shift", office._simulation.day)


func _prepare_flock_relations_ui_capture_case() -> void:
	# The UI fixture uses one real filed case so all four comparisons fit in the
	# first viewport. No presentation-only case, cost, or availability is invented.
	if office._simulation.workers.is_empty():
		return
	var worker = office._simulation.workers[0]
	worker.manager_trust = 24.0
	worker.grievance = 82.0
	worker.stress = 76.0
	worker.fatigue = 68.0
	office._simulation.call("_file_flock_relations_case_after_shift", office._simulation.day)


func _commission_capture_facility(facility_id: StringName) -> bool:
	var max_level := int(office._simulation.facility_status(facility_id).get("max_level", 1))
	for _level in max_level:
		var receipt := office._simulation.purchase_facility(facility_id)
		if not bool(receipt.get("accepted", false)):
			push_error(
				"Operations art capture could not commission %s: %s" % [
					String(facility_id),
					String(receipt.get("reason", "unknown reason")),
				]
			)
			office.get_tree().quit(1)
			return false
	return true


func _hide_world_capture_overlays() -> void:
	if office._ui_root != null:
		office._ui_root.visible = false
	if office._workers_node != null:
		office._workers_node.visible = false
	if office._management_presence != null:
		office._management_presence.visible = false


func _capture_signage_preview(focus: Vector3, file_name: String) -> void:
	_prepare_capture_running()
	# Art-review captures need to judge the physical prop, not the management HUD.
	# Keep gameplay captures elsewhere; this route deliberately removes screen UI
	# and actors that otherwise cover the shallow wall and desk fixtures.
	if office._ui_root != null:
		office._ui_root.visible = false
	if office._workers_node != null:
		office._workers_node.visible = false
	if office._management_presence != null:
		office._management_presence.visible = false
	var inspection_size := 5.2
	if file_name.contains("desk"):
		inspection_size = 4.0
	elif file_name.contains("intake"):
		inspection_size = 4.4
	elif file_name.contains("breakroom"):
		inspection_size = 5.5
	elif file_name.contains("left"):
		inspection_size = 5.6
	office._camera_controller.focus_point(focus, "SIGNAGE ART CHECK", 0.35, inspection_size)
	await office.get_tree().create_timer(0.9).timeout
	_save_preview(file_name)


func _capture_breakroom_preview() -> void:
	_prepare_capture_running()
	# Keep the hens visible for this art review: the point of the scene is the
	# relationship between the flock and the environment, not isolated props.
	if office._ui_root != null:
		office._ui_root.visible = false
	if office._management_presence != null:
		office._management_presence.visible = false
	if office._workers_node != null:
		office._workers_node.visible = true
	for worker_view_value in office._worker_views.values():
		var staged_view := worker_view_value as ChickenView
		staged_view.stage_at_workstation_for_introduction()
	for worker_index in mini(4, office._simulation.workers.size()):
		var worker := office._simulation.workers[worker_index] as ChickenState
		if not worker.employed:
			continue
		worker.work_state = ChickenState.WorkState.BREAK
		worker.state_ticks_remaining = 120
	office._apply_snapshot_presentation(office._simulation.snapshot())
	for worker_view_value in office._worker_views.values():
		var worker_view := worker_view_value as ChickenView
		var intent_marker := worker_view.find_child("HenIntentMarker", true, false)
		if intent_marker != null:
			intent_marker.visible = false
	office._camera_controller.focus_point(
		Vector3(-10.05, 1.02, -0.35),
		"BREAKROOM ART CHECK",
		0.35,
		6.4,
	)
	await office.get_tree().create_timer(7.2).timeout
	_save_preview("breakroom.png")


func _capture_career_trophies_preview() -> void:
	_prepare_capture_running()
	_hide_world_capture_overlays()
	office._office_storytelling.set_commendations_snapshot({"earned_count": 5, "total_count": 12})
	office._camera_controller.focus_point(
		office.OfficeStorytellingScript.PERCH_CENTER + Vector3(0.0, 2.55, 0.50),
		"CAREER TROPHY ART CHECK",
		0.35,
		4.8,
	)
	await office.get_tree().create_timer(1.0).timeout
	_save_preview("career_trophies.png")


func _capture_campaign_title_preview() -> void:
	office._decision_host.visible = false
	office._campaign_ui.show_title(false)
	office._set_campaign_modal_open(true)
	await office.get_tree().create_timer(0.55).timeout
	_save_preview("probation_title.png")


func _capture_campaign_report_preview(at_risk: bool = false) -> void:
	office._decision_host.visible = false
	office._campaign_state = office.CampaignStateScript.new()
	var report := _campaign_capture_report(1)
	if at_risk:
		# This deterministic fixture exercises the compact needs-action chips using
		# the same authoritative campaign forecast as an ordinary played shift.
		report["farmer_favor"] = 49
	office._last_workday_report = report.duplicate(true)
	office._campaign_state.record_shift(report, {})
	# The played shift advances the simulation before its report opens. Mirror
	# that transition so the capture's "next market" pulse names Shift 2.
	office._simulation.day = 2
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision = {}
	office._simulation.last_credit_allocation = {
		"day": 1,
		"decision_id": "closing_credit_memo",
		"option_id": "share_the_scoop",
		"style_id": "shared_scoop",
		"worker_id": 1,
		"worker_name": "Mabel",
		"cost_cents": 0,
		"outcome": "Mabel's clutch was credited to the flock. The farmer retained management's name on the presentation.",
		"special_event": false,
		"projected": false,
	}
	office._campaign_review_stage = &"probation"
	office._campaign_ui.show_between_shift_report(office._campaign_presentation_snapshot(&"between_shift"))
	office._set_campaign_modal_open(true)
	await office.get_tree().create_timer(0.55).timeout
	_save_preview("probation_report_risk.png" if at_risk else "probation_report.png")


func _capture_campaign_promotion_opportunity_preview() -> void:
	office._decision_host.visible = false
	office._campaign_state = office.CampaignStateScript.new()
	# Shift one lands at 54 through ordinary scoring, then the clean shift-two
	# fixture reaches 77. The disclosed +3 order bundle therefore reaches the
	# real Golden Management threshold exactly, without mutating campaign rules.
	var opening_report := _campaign_capture_report(1)
	opening_report["eggs"] = 18
	opening_report["quota"] = 24
	opening_report["cracked"] = 3
	opening_report["welfare"] = 47
	opening_report["compliance"] = 60
	opening_report["farmer_favor"] = 60
	office._campaign_state.record_shift(opening_report, {})
	var report := _campaign_capture_report(2)
	office._last_workday_report = report.duplicate(true)
	office._campaign_state.record_shift(report, {})
	# The ordinary close advances to Day 3 before this planning report opens.
	office._simulation.day = office._campaign_state.completed_shifts + 1
	office._simulation.last_credit_allocation = {
		"day": 2,
		"decision_id": "closing_credit_memo",
		"option_id": "share_the_scoop",
		"style_id": "shared_scoop",
		"worker_id": 1,
		"worker_name": "Mabel",
		"cost_cents": 0,
		"outcome": "Mabel's clutch was credited to the flock. The farmer retained management's name on the presentation.",
		"special_event": false,
		"projected": false,
	}
	office._campaign_review_stage = &"probation"
	office._campaign_ui.show_between_shift_report(office._campaign_presentation_snapshot(&"between_shift"))
	office._set_campaign_modal_open(true)
	await office.get_tree().create_timer(0.55).timeout
	_save_preview("probation_report.png")


func _capture_campaign_promotion_tracker_preview(
	promotion_ready: bool = false,
	save_capture: bool = true,
	max_interface_scale: bool = false,
) -> void:
	office._decision_host.visible = false
	office._campaign_state = office.CampaignStateScript.new()
	# File two authentic shifts and the required milestone so the live day-three
	# tracker inherits a real 77 -> 80 Golden Management promotion opportunity.
	var opening_report := _campaign_capture_report(1)
	opening_report["eggs"] = 18
	opening_report["quota"] = 24
	opening_report["cracked"] = 3
	opening_report["welfare"] = 47
	opening_report["compliance"] = 80
	opening_report["farmer_favor"] = 60
	opening_report["overdue_claims"] = 1
	var opening_result: Dictionary = office._campaign_state.record_shift(opening_report, {})
	var second_result: Dictionary = office._campaign_state.record_shift(_campaign_capture_report(2), {})
	var milestone_filed: bool = office._campaign_state.choose_milestone(&"padded_perches")
	if (
		not bool(opening_result.get("accepted", false))
		or not bool(second_result.get("accepted", false))
		or not milestone_filed
		or office._campaign_state.probation_score != 77
	):
		push_error("Promotion tracker capture fixture must reach an authentic 77 score.")
		office.get_tree().quit(1)
		return
	office._campaign_review_stage = &"active"
	office._simulation.day = office._campaign_state.completed_shifts + 1
	_prepare_capture_running()
	if max_interface_scale:
		office._player_preferences["ui_scale"] = 1.5
		office._apply_management_ui_preferences()
	office._campaign_ui.show_active_campaign(office._campaign_presentation_snapshot(&"active"))
	office._set_campaign_modal_open(false)
	office._update_campaign_objectives_label(office._simulation.snapshot())
	await office.get_tree().process_frame
	await office.get_tree().process_frame
	# The authoritative forecast above seeds the stable Day 3 objective identities
	# at 2/3, so the ready transition can identify the exact quota mark that moves.
	if promotion_ready:
		# Satisfy the remaining live quota order through the simulation metric so
		# subsequent presentation refreshes preserve the authentic 3/3 state.
		office._simulation.eggs_today = office._simulation.quota_target
		office._simulation.eggs_total = maxi(office._simulation.eggs_total, office._simulation.eggs_today)
		await office.get_tree().process_frame
		office._update_campaign_objectives_label(office._simulation.snapshot())
	await office.get_tree().create_timer(0.65).timeout
	if save_capture:
		_save_preview(
			"promotion_order_ready.png" if promotion_ready else "promotion_order_tracker.png"
		)


func _capture_campaign_goal_cause_locator_preview(stale_receipt: bool = false) -> void:
	await _capture_campaign_promotion_tracker_preview(false, false)
	# Keep one live authoritative file in the fixture so closing Flockwatch restores
	# the same claim the receipt names, exactly as it would during normal play.
	if not office._simulation.workers.is_empty():
		var preview_worker := office._simulation.workers[0] as ChickenState
		if preview_worker.current_claim == null:
			preview_worker.current_claim = ClaimState.new(
				731,
				&"nest_damage",
				"NEST DAMAGE",
				1.15,
				760,
				0.045,
				1080,
				1440,
				360,
			)
			preview_worker.work_state = ChickenState.WorkState.WORKING
			preview_worker.work_progress = 34.0
	var before_snapshot := office._simulation.snapshot()
	var after_snapshot := before_snapshot.duplicate(true)
	after_snapshot["eggs_today"] = int(before_snapshot.get("quota_target", 1))
	var source_worker := office._worker_record(after_snapshot, 0)
	office._record_campaign_order_cause_receipts(
		before_snapshot,
		after_snapshot,
		"MABEL/NEST",
		&"routed_egg",
		"sound",
		{
			"source_kind": "worker_file",
			"source_label": String(source_worker.get("name", "MABEL")),
			"worker_id": 0,
			"claim_id": 999999 if stale_receipt else int(
				(source_worker.get("current_claim", {}) as Dictionary).get("id", -1)
			),
		},
	)
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_TODAY)
	await office.get_tree().process_frame
	await office.get_tree().process_frame
	_save_preview(
		"goal_cause_fallback.png" if stale_receipt else "goal_cause_locator.png"
	)


func _capture_campaign_goal_driver_route_preview(show_handoff: bool = false) -> void:
	await _capture_campaign_promotion_tracker_preview(false, false)
	if office._simulation.workers.is_empty() or office._routing_ui == null:
		push_error("Goal driver Route capture requires one visible hen dossier.")
		office.get_tree().quit(1)
		return
	var preview_worker := office._simulation.workers[0] as ChickenState
	if preview_worker.current_claim == null:
		preview_worker.current_claim = ClaimState.new(
			731,
			&"nest_damage",
			"NEST DAMAGE",
			1.15,
			760,
			0.045,
			1080,
			1440,
			360,
		)
		preview_worker.work_state = ChickenState.WorkState.WORKING
		preview_worker.work_progress = 34.0
	office._on_snapshot_changed(office._simulation.snapshot())
	office._routing_ui.set_focus(0)
	office._routing_ui.call("_on_dossier_tab_pressed", &"claim")
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_TODAY)
	await office.get_tree().process_frame
	if office._campaign_order_glances.is_empty():
		push_error("Goal driver Route capture requires one campaign order tile.")
		office.get_tree().quit(1)
		return
	var glance := office._campaign_order_glances[0] as Label
	office._configure_campaign_order_driver_action(glance)
	glance.grab_focus()
	await office.get_tree().process_frame
	if show_handoff:
		office._on_campaign_order_driver_pressed()
		await office.get_tree().process_frame
	await office.get_tree().process_frame
	_save_preview("goal_driver_route_handoff.png" if show_handoff else "goal_driver_route.png")


func _capture_campaign_goal_driver_flock_care_preview() -> void:
	await _capture_campaign_promotion_tracker_preview(false, false)
	if office._campaign_order_glances.is_empty() or office._flockwatch_navigation == null:
		push_error("Goal driver Flock Care capture requires one campaign order tile.")
		office.get_tree().quit(1)
		return
	# Seed the page with a deliberately stale lower reading position. The real
	# driver must override it and land on the exact care filing.
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_FLOCK)
	await office.get_tree().process_frame
	var flock_scroll := office._flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_FLOCK)
	if flock_scroll != null:
		flock_scroll.scroll_vertical = 100000
	await office.get_tree().process_frame
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_TODAY)
	await office.get_tree().process_frame
	var glance := office._campaign_order_glances[0] as Label
	glance.text = "WELFARE >= 72\n88 NOW  ·  SAFE"
	glance.set_meta("objective_id", &"rested_flock")
	glance.set_meta("objective_title", "RESTED FLOCK")
	glance.set_meta("metric", &"average_welfare")
	glance.set_meta("on_track", true)
	glance.set_meta("focus_accent", Color("73b5a7"))
	office._configure_campaign_order_driver_action(glance)
	glance.grab_focus()
	office._refresh_campaign_order_glance_focus_style(glance)
	await office.get_tree().process_frame
	await office.get_tree().process_frame
	_save_preview("goal_driver_flock_care.png")


func _capture_campaign_goal_driver_farmer_standing_preview() -> void:
	await _capture_campaign_promotion_tracker_preview(false, false)
	if office._campaign_order_glances.is_empty() or office._flockwatch_navigation == null:
		push_error("Goal driver Farmer Standing capture requires one campaign order tile.")
		office.get_tree().quit(1)
		return
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_TODAY)
	await office.get_tree().process_frame
	var glance := office._campaign_order_glances[0] as Label
	glance.text = "FAVOR 52+\n49  ·  NEED 3"
	glance.set_meta("objective_id", &"farmer_confidence")
	glance.set_meta("objective_title", "FARMER CONFIDENCE")
	glance.set_meta("metric", &"average_farmer_favor")
	glance.set_meta("on_track", false)
	glance.set_meta("focus_accent", Color("d68a68"))
	office._configure_campaign_order_driver_action(glance)
	office._campaign_order_driver_button.grab_focus()
	office._refresh_campaign_order_glance_focus_style(glance)
	await office.get_tree().process_frame
	await office.get_tree().process_frame
	_save_preview("goal_driver_farmer_standing.png")


func _capture_campaign_goal_driver_coop_controls_preview() -> void:
	await _capture_campaign_promotion_tracker_preview(false, false)
	if office._campaign_order_glances.is_empty() or office._flockwatch_navigation == null:
		push_error("Goal driver Compliance capture requires one campaign order tile.")
		office.get_tree().quit(1)
		return
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_OPERATIONS)
	await office.get_tree().process_frame
	var operations_scroll := office._flockwatch_navigation.page_scroll(
		FlockwatchNavigation.PAGE_OPERATIONS,
	)
	if operations_scroll != null:
		operations_scroll.scroll_vertical = 100000
	await office.get_tree().process_frame
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_TODAY)
	await office.get_tree().process_frame
	var glance := office._campaign_order_glances[0] as Label
	glance.text = "COMPLIANCE >= 55\n81 NOW  ·  SAFE"
	glance.set_meta("objective_id", &"coop_compliance")
	glance.set_meta("objective_title", "COOP COMPLIANCE")
	glance.set_meta("metric", &"average_compliance")
	glance.set_meta("on_track", true)
	glance.set_meta("focus_accent", Color("73b5a7"))
	office._configure_campaign_order_driver_action(glance)
	office._campaign_order_driver_button.grab_focus()
	office._refresh_campaign_order_glance_focus_style(glance)
	await office.get_tree().process_frame
	await office.get_tree().process_frame
	_save_preview("goal_driver_coop_controls.png")


func _capture_campaign_goal_driver_live_files_preview(empty_intake: bool = false) -> void:
	await _capture_campaign_promotion_tracker_preview(false, false)
	if office._campaign_order_glances.is_empty() or office._routing_ui == null:
		push_error("Goal driver Live Files capture requires the routing surface.")
		office.get_tree().quit(1)
		return
	if empty_intake:
		for lane: StringName in DepartmentSimulation.CLAIM_LANES:
			office._simulation._claim_queues[lane] = []
		office._simulation.call("_sync_claims_waiting")
		office._on_snapshot_changed(office._simulation.snapshot())
		await office.get_tree().process_frame
	elif office._routing_ui.dispatch_priority_state().is_empty():
		push_error("Goal driver Live Files capture requires one urgent intake tray.")
		office.get_tree().quit(1)
		return
	office._open_flockwatch_page(FlockwatchNavigation.PAGE_TODAY)
	await office.get_tree().process_frame
	var glance := office._campaign_order_glances[0] as Label
	glance.text = "REWORK <= 3\n0 NOW  ·  SAFE"
	glance.set_meta("objective_id", &"clean_files")
	glance.set_meta("objective_title", "CLEAN FILES")
	glance.set_meta("metric", &"rework")
	glance.set_meta("on_track", true)
	glance.set_meta("focus_accent", Color("73b5a7"))
	office._configure_campaign_order_driver_action(glance)
	glance.grab_focus()
	office._refresh_campaign_order_glance_focus_style(glance)
	await office.get_tree().process_frame
	await office.get_tree().process_frame
	_save_preview(
		"goal_driver_live_files_empty.png" if empty_intake else "goal_driver_live_files.png"
	)


func _capture_senior_policy_receipt_preview(with_shift_delta: bool = false) -> void:
	office._decision_host.visible = false
	office._campaign_state = office.CampaignStateScript.new()
	office._senior_roost_state = office.SeniorRoostStateScript.new()
	if not office._senior_roost_state.begin(5):
		push_error("Senior policy receipt capture could not open the career ledger.")
		office.get_tree().quit(1)
		return
	var mandate_receipt: Dictionary = office._senior_roost_state.select_annual_mandate(
		office.SeniorRoostStateScript.MANDATE_FALLBACK_ID,
		office._senior_roost_state.current_year_number(),
	)
	if not bool(mandate_receipt.get("accepted", false)):
		push_error("Senior policy receipt capture could not file the annual Board fallback.")
		office.get_tree().quit(1)
		return
	if not office._senior_roost_state.record_quarter_policy({
		"accepted": true,
		"policy_id": &"harvest_forecast",
		"style_id": &"management_innovation",
		"cost_cents": 0,
		"fund_delta_cents": 6000,
		"farmer_favor_delta": 24,
		"quota_delta": 2,
		"compliance_delta": -4,
		"solidarity_delta": 0,
		"outcome": "Management filed next quarter's harvest before the hens produced it.",
	}):
		push_error("Senior policy receipt capture could not file Harvest Forecast.")
		office.get_tree().quit(1)
		return
	if with_shift_delta:
		office._last_workday_report = _career_sponsorship_capture_report(6, 1)
		var shift_receipt: Dictionary = office._senior_roost_state.record_shift(
			office._last_workday_report
		)
		if not bool(shift_receipt.get("accepted", false)):
			push_error("Senior Board delta capture could not file its demonstration shift.")
			office.get_tree().quit(1)
			return
	office._campaign_senior_roost = true
	office._campaign_review_stage = &"senior_quarter"
	office._campaign_ui.show_between_shift_report(office._senior_presentation_snapshot(&"between_shift"))
	office._set_campaign_modal_open(true)
	await office.get_tree().process_frame
	await office.get_tree().process_frame
	_save_preview(
		"senior_board_delta.png" if with_shift_delta else "senior_policy_receipt.png"
	)


func _capture_career_sponsorship_preview() -> void:
	office._decision_host.visible = false
	office._campaign_state = office.CampaignStateScript.new()
	office._senior_roost_state = office.SeniorRoostStateScript.new()
	if not office._senior_roost_state.begin(5):
		push_error("Career Sponsorship capture could not open the Senior Roost ledger.")
		office.get_tree().quit(1)
		return
	var mandate_receipt: Dictionary = office._senior_roost_state.select_annual_mandate(
		office.SeniorRoostStateScript.MANDATE_FALLBACK_ID,
		office._senior_roost_state.current_year_number(),
	)
	if not bool(mandate_receipt.get("accepted", false)):
		push_error("Career Sponsorship capture could not file the annual Board fallback.")
		office.get_tree().quit(1)
		return
	if not office._senior_roost_state.record_quarter_policy({
		"accepted": true,
		"policy_id": &"harvest_forecast",
		"style_id": &"management_innovation",
		"outcome": "Harvest Forecast funded one protected planning quarter.",
	}):
		push_error("Career Sponsorship capture could not file its quarterly policy.")
		office.get_tree().quit(1)
		return
	for day in [6, 7, 8]:
		var shift_result: Dictionary = office._senior_roost_state.record_shift(
			_career_sponsorship_capture_report(day, day - 5)
		)
		if not bool(shift_result.get("accepted", false)):
			push_error("Career Sponsorship capture could not close Senior shift %d." % day)
			office.get_tree().quit(1)
			return

	for worker in office._simulation.workers:
		worker.career_xp = 0
		worker.secondary_specialty = &""
		worker.cross_training_target = &""
		worker.cross_training_worked_this_shift = false
	var capture_worker = office._simulation.workers[0]
	capture_worker.career_xp = 18
	office._simulation.day = 9
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.pending_decision.clear()
	office._simulation.revenue_cents = (
		office._simulation.current_daily_operating_cost_cents()
		+ office._simulation.wage_arrears_cents
		+ 5000
	)
	office._last_workday_report = _career_sponsorship_capture_report(8, 3)
	office._campaign_senior_roost = true
	office._campaign_review_stage = &"senior_quarter"
	office._campaign_ui.show_between_shift_report(office._senior_presentation_snapshot(&"between_shift"))
	office._set_campaign_modal_open(true)
	await office.get_tree().process_frame
	await office.get_tree().process_frame

	var sponsorship := office._campaign_ui.find_child("CareerSponsorshipUI", true, false) as Control
	var scroll := office._campaign_ui.get("_modal_scroll") as ScrollContainer
	if sponsorship == null or scroll == null or not sponsorship.is_visible_in_tree():
		push_error("Career Sponsorship capture requires the authentic visible report component.")
		office.get_tree().quit(1)
		return
	var component_offset := (
		sponsorship.get_global_rect().position.y
		- scroll.get_global_rect().position.y
		+ float(scroll.scroll_vertical)
		- 14.0
	)
	scroll.scroll_vertical = maxi(0, int(component_offset))
	await office.get_tree().process_frame
	await office.get_tree().process_frame
	# Compact policy cards change the report's minimum height after their queued
	# sort. Re-anchor to the authentic component after that layout settles so the
	# capture cannot preserve a stale pre-sort scroll offset and photograph an
	# empty tail of the report.
	scroll.ensure_control_visible(sponsorship)
	await office.get_tree().process_frame
	await office.get_tree().process_frame
	_save_preview("career_sponsorship.png")


func _capture_career_sponsorship_confirmation_preview() -> void:
	await _capture_career_sponsorship_preview()
	var authorize := office.find_child("CareerSponsorshipAuthorizeButton", true, false) as Button
	if authorize == null or authorize.disabled:
		push_error("Career Sponsorship confirmation capture requires an available filing.")
		office.get_tree().quit(1)
		return
	authorize.pressed.emit()
	await office.get_tree().process_frame
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("career_sponsorship_confirmation.png")


func _capture_campaign_final_preview() -> void:
	office._decision_host.visible = false
	office._campaign_state = office.CampaignStateScript.new()
	for shift_number in range(1, office.CampaignStateScript.CAMPAIGN_LENGTH + 1):
		if shift_number == 3:
			office._campaign_state.choose_milestone(&"padded_perches")
		office._campaign_state.record_shift(_campaign_capture_report(shift_number), {})
	office._simulation.flock_restructuring_resolved = true
	office._simulation.flock_restructuring_day = DepartmentSimulation.FLOCK_RESTRUCTURING_SHIFT
	office._simulation.flock_restructuring_record = {
		"worker_name": "Mabel",
		"option_id": "contest_ranking",
	}
	office._campaign_review_stage = &"final"
	office._campaign_ui.show_final_review(office._campaign_presentation_snapshot(&"final"))
	office._set_campaign_modal_open(true)
	await office.get_tree().create_timer(0.55).timeout
	_save_preview("probation_final.png")


func _capture_restructuring_preview() -> void:
	office._clock.set_speed(0)
	office._day_review_scrim.visible = false
	office._set_flockwatch_open(false)
	office._campaign_ui.show_active_campaign(office._campaign_presentation_snapshot(&"active"))
	office._set_campaign_modal_open(false)
	office._simulation.pending_decision.clear()
	office._simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office._simulation.day = DepartmentSimulation.FLOCK_RESTRUCTURING_SHIFT + 1
	var ranking := office._simulation.current_pecking_order()
	office._simulation._prepare_credit_allocation_decision(
		DepartmentSimulation.FLOCK_RESTRUCTURING_SHIFT,
		ranking,
		0,
	)
	office._simulation.announce_pending_decision()
	await office.get_tree().create_timer(0.65).timeout
	_save_preview("flock_restructuring.png")


func _campaign_capture_report(shift_number: int) -> Dictionary:
	return {
		"day": shift_number,
		"eggs": 28,
		"quota": 24 + shift_number,
		"cracked": 1,
		"overdue_claims": 0,
		"rework_created": 0,
		"credited_cents": 6800,
		"welfare": 78,
		"compliance": 84,
		"farmer_favor": 76,
		"directive": {
			"id": "shell_assurance",
			"name": "SHELL ASSURANCE PROTOCOL",
			"short_name": "ASSURANCE",
			"preview": "-7% work speed / -5% crack risk / +3 obedience",
		},
		"hen_highlight": {
			"version": 1,
			"type": "golden_deliverable",
			"day": shift_number,
			"worker_id": 1,
			"worker_name": "Mabel",
			"career_title": "ACCREDITED LAYER",
			"relationship_label": "WARY",
			"rank": 1,
			"eggs": 8,
			"sound": 7,
			"cracked": 0,
			"golden": 1,
			"credit_cents": 2140,
			"headline": "GOLDEN DELIVERABLE",
			"body": "Mabel laid one golden egg. The farmer congratulated management before collecting it.",
			"metric": "8 EGGS  //  7 SOUND  //  1 GOLDEN  //  $21.40 CREDIT",
			"tone": "gold",
		},
	}


func _career_sponsorship_capture_report(day: int, rework_total: int) -> Dictionary:
	return {
		"day": day,
		"eggs": 30,
		"quota": 24,
		"met_quota": true,
		"cracked": 2,
		"golden": 0,
		"quota_bonus_cents": 0,
		"quality_bonus_cents": 0,
		"feed_cost_cents": 1800,
		"credited_cents": 12_000,
		"welfare": 72,
		"compliance": 76,
		"farmer_favor": 66,
		"wage_arrears_cents": 0,
		"overdue_claims": 0,
		"rework_waiting": 0,
		"rework_due_next_shift": 0,
		"rework_total_created": rework_total,
		"closing_fund_cents": 20_000 + day * 100,
		"credit_memo_required": false,
		"pecking_order": [],
		"hen_highlight": {},
	}


func _prepare_capture_running() -> void:
	# Automated preview routes do not begin with a player gesture, so Web browsers
	# correctly reject vibration. Keep captures console-clean without changing the
	# authored default used after real player input.
	if OS.has_feature("web") and office._audio_feedback != null:
		office._audio_feedback.set_haptics_enabled(false)
	if office._simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE:
		office._simulation.select_directive(&"shell_assurance")
	office._clock.set_speed(0)


func _save_preview(file_name: String) -> void:
	# Browser captures are collected by the Playwright harness. Leaving the Web
	# runtime alive avoids tearing down its audio graph while the screenshot and
	# diagnostic state are still being read.
	if OS.has_feature("web"):
		return
	var capture_directory := ProjectSettings.globalize_path("res://captures")
	for argument in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		var argument_text := String(argument)
		if not argument_text.begins_with("--capture-dir="):
			continue
		var requested_directory := argument_text.trim_prefix("--capture-dir=").strip_edges()
		if requested_directory.is_empty():
			continue
		capture_directory = (
			requested_directory
			if requested_directory.is_absolute_path() else
			ProjectSettings.globalize_path(
				"res://%s" % requested_directory.trim_prefix("./")
			)
		)
		break
	DirAccess.make_dir_recursive_absolute(capture_directory)
	var image := office.get_viewport().get_texture().get_image()
	if image == null:
		push_error("Unable to save %s: the active display driver does not provide a render texture." % file_name)
		office.get_tree().quit(1)
		return
	var error := image.save_png(capture_directory.path_join(file_name))
	if error != OK:
		push_error("Unable to save %s: %s" % [file_name, error_string(error)])
	office.get_tree().quit()


