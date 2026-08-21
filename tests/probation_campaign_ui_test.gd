extends SceneTree

const ProbationCampaignUIScript := preload("res://features/office/probation_campaign_ui.gd")
const ManagementUIThemeScript := preload("res://features/office/management_ui_theme.gd")
const CareerPortfolioScript := preload("res://core/persistence/career_portfolio_store.gd")
const SimulationScript := preload("res://core/simulation/department_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observed := {
		"continue": 0,
		"new": 0,
		"abandon": 0,
		"milestone": &"",
		"challenge_contract": &"",
		"career_slot": &"",
		"career_identity": &"",
		"replay_scenario": &"",
		"title_phase": &"",
		"report_filing_settled": 0,
		"live_order_id": &"",
		"live_order_index": -1,
	}
	var harness := Control.new()
	harness.name = "ProbationCampaignUITestHarness"
	harness.size = Vector2(1280.0, 720.0)
	root.add_child(harness)
	var ui = ProbationCampaignUIScript.new()
	harness.add_child(ui)
	ui.continue_campaign.connect(func() -> void: observed["continue"] += 1)
	ui.new_campaign.connect(func() -> void: observed["new"] += 1)
	ui.abandon_campaign.connect(func() -> void: observed["abandon"] += 1)
	ui.milestone_choice.connect(func(choice_id: StringName) -> void: observed["milestone"] = choice_id)
	ui.challenge_contract_changed.connect(
		func(contract_id: StringName) -> void: observed["challenge_contract"] = contract_id
	)
	ui.career_slot_changed.connect(func(value: StringName) -> void: observed["career_slot"] = value)
	ui.career_identity_changed.connect(func(value: StringName) -> void: observed["career_identity"] = value)
	ui.replay_scenario_changed.connect(func(value: StringName) -> void: observed["replay_scenario"] = value)
	ui.title_intake_phase_changed.connect(
		func(phase: StringName) -> void: observed["title_phase"] = phase
	)
	ui.report_filing_settled.connect(
		func(_reveal_key: String, _instant: bool) -> void:
			observed["report_filing_settled"] += 1
	)
	ui.live_order_mark_requested.connect(
		func(objective_id: StringName, order_index: int) -> void:
			observed["live_order_id"] = objective_id
			observed["live_order_index"] = order_index
	)
	await process_frame

	var badge := ui.find_child("ProbationDayBadge", true, false) as PanelContainer
	var status_label := ui.find_child("ProbationStatusLabel", true, false) as Label
	var status_icon := ui.find_child("ProbationScoreIcon", true, false) as FlockwatchIconBadge
	var day_label := ui.find_child("ProbationDayLabel", true, false) as Label
	var day_icon := ui.find_child("ProbationDayIcon", true, false) as FlockwatchIconBadge
	var day_progress_rail := ui.find_child("ProbationDayProgressRail", true, false) as HBoxContainer
	var day_segment_1 := ui.find_child("ProbationDaySegment1", true, false) as PanelContainer
	var day_segment_3 := ui.find_child("ProbationDaySegment3", true, false) as PanelContainer
	var day_segment_5 := ui.find_child("ProbationDaySegment5", true, false) as PanelContainer
	var modal_host := ui.find_child("ProbationModalHost", true, false) as Control
	_check(badge != null and badge.is_visible_in_tree(), "probation badge should always be visible", failures)
	_check(status_label != null and status_label.text == "PROBATION", "badge should default to probation status", failures)
	_check(day_label != null and day_label.text == "1 / 5", "calendar-led badge should open on shift one of five", failures)
	_check(
		day_progress_rail != null and day_progress_rail.is_visible_in_tree()
		and status_icon != null and status_icon.is_visible_in_tree()
		and status_icon.icon_kind() == &"score"
		and String(status_icon.get_meta("state_shape", "")) == "score_rosette"
		and day_icon != null and day_icon.is_visible_in_tree()
		and day_icon.icon_kind() == &"calendar"
		and String(day_icon.get_meta("state_shape", "")) == "calendar_grid"
		and int(day_progress_rail.get_meta("current_day", 0)) == 1
		and day_segment_1 != null and String(day_segment_1.get_meta("state", "")) == "current"
		and day_segment_3 != null and String(day_segment_3.get_meta("state", "")) == "upcoming"
		and day_segment_5 != null and String(day_segment_5.get_meta("state", "")) == "upcoming"
		and day_label.tooltip_text == "DAY 1 / 5"
		and String(day_label.get_meta("accessible_text", "")) == day_label.tooltip_text,
		"probation badge should pair its exact day label with a five-segment visual rail",
		failures,
	)
	_check(modal_host != null and not modal_host.is_visible_in_tree(), "active campaign should leave the office unobstructed", failures)

	ui.show_active_campaign({
		"status": "Probation",
		"score": 50,
		"challenge_contract": _challenge_contract("executive_audit"),
		"next_objective": {
			"promotion_opportunity": {
				"available": true,
				"current_score": 77,
				"reward_score": 3,
				"projected_score": 80,
				"next_threshold": 80,
				"next_rank_label": "Golden Management Track",
			},
		},
	})
	await process_frame
	_check(
		status_label != null and status_label.text == "50 / 100"
		and status_label.tooltip_text.begins_with("SCORE 50 / 100")
		and String(status_label.get_meta("accessible_text", "")) == status_label.tooltip_text,
		"score rosette should carry the category while the value retains its exact scale",
		failures,
	)
	_check(
		status_label != null
		and _contains_all(status_label.tooltip_text, [
			"EXECUTIVE AUDIT", "SCORE >= 65 / 100", "WELFARE >= 48",
			"COMPLIANCE >= 65", "FARMER FAVOR >= 52", "CRACK RATE <= 24.50%",
		]),
		"score badge tooltip should explain the active contract and every exact threshold",
		failures,
	)
	var order_progress_row := ui.find_child("ProbationOrderProgressRow", true, false) as HBoxContainer
	var order_progress_icon := ui.find_child("ProbationOrderProgressIcon", true, false) as FlockwatchIconBadge
	var order_promotion_icon := ui.find_child("ProbationOrderPromotionIcon", true, false) as TextureRect
	var order_progress_label := ui.find_child("ProbationOrderProgressLabel", true, false) as Label
	var first_order_stamp := ui.find_child("ProbationOrderStamp1", true, false) as PanelContainer
	var first_order_stamp_icon := ui.find_child("ProbationOrderStampIcon1", true, false) as FlockwatchIconBadge
	var first_order_state_icon := ui.find_child("ProbationOrderStampStateIcon1", true, false) as TextureRect
	var first_order_action := ui.find_child("ProbationOrderStampAction1", true, false) as Button
	var second_order_stamp := ui.find_child("ProbationOrderStamp2", true, false) as PanelContainer
	var second_order_stamp_icon := ui.find_child("ProbationOrderStampIcon2", true, false) as FlockwatchIconBadge
	var second_order_state_icon := ui.find_child("ProbationOrderStampStateIcon2", true, false) as TextureRect
	var third_order_stamp := ui.find_child("ProbationOrderStamp3", true, false) as PanelContainer
	var third_order_stamp_icon := ui.find_child("ProbationOrderStampIcon3", true, false) as FlockwatchIconBadge
	var third_order_state_icon := ui.find_child("ProbationOrderStampStateIcon3", true, false) as TextureRect
	var day_one_states: Array[Dictionary] = [
		{
			"id": "prove_the_plan", "label": "Prove the plan", "metric": "quota_met",
			"icon": "egg", "on_track": false,
			"detail": "NEEDS ACTION  //  PROVE THE PLAN  //  OPEN",
		},
		{
			"id": "farmer_confidence", "label": "Farmer confidence",
			"metric": "farmer_favor", "icon": "cash", "on_track": true,
			"detail": "ON TRACK  //  FARMER CONFIDENCE  //  76/52% FLOOR",
		},
		{
			"id": "no_rework_spiral", "label": "No rework spiral", "metric": "rework",
			"icon": "files", "on_track": true,
			"detail": "ON TRACK  //  NO REWORK SPIRAL  //  0/0 CAP",
		},
	]
	var seeded_delta := ui.set_live_order_progress(2, 3, &"probation:1", day_one_states)
	await process_frame
	var icon_led_tracker := ui.live_order_progress()
	_check(
		seeded_delta == 0
		and order_progress_row != null
		and order_progress_row.is_visible_in_tree()
		and bool(order_progress_row.get_meta("promotion_opportunity", false))
		and not bool(order_progress_row.get_meta("promotion_ready", true))
		and order_promotion_icon != null and order_promotion_icon.is_visible_in_tree()
		and order_promotion_icon.texture != null
		and String(order_promotion_icon.get_meta("semantic_icon", "")) == "rank_crest"
		and String(order_promotion_icon.get_meta("promotion_state", "")) == "recover"
		and int(order_promotion_icon.get_meta("target_score", 0)) == 80
		and order_progress_label != null
		and order_progress_icon != null and order_progress_icon.is_visible_in_tree()
		and order_progress_icon.icon_kind() == &"order_check"
		and String(order_progress_icon.get_meta("state_shape", "")) == "checked_order_sheet"
		and order_progress_label.text == "2 / 3"
		and order_progress_label.tooltip_text.begins_with("PROMOTION IN REACH  //  2 / 3 ORDERS ON TRACK  //  +3 SCORE  //  77 -> 80  //  GOLDEN MANAGEMENT TRACK"),
		"a promotion opportunity should join the live order count with one recoverable crest",
		failures,
	)
	_check(
		bool(icon_led_tracker.get("headline_icon_led", false))
		and String(icon_led_tracker.get("headline_shape_language", "")) == "score_rosette + calendar_grid + checked_order_sheet"
		and String(icon_led_tracker.get("score_icon", "")) == "score"
		and bool(icon_led_tracker.get("score_icon_visible", false))
		and String(icon_led_tracker.get("score_text", "")) == "50 / 100"
		and String(icon_led_tracker.get("score_accessible_text", "")).begins_with("SCORE 50 / 100")
		and String(icon_led_tracker.get("day_icon", "")) == "calendar"
		and bool(icon_led_tracker.get("day_icon_visible", false))
		and String(icon_led_tracker.get("day_text", "")) == "1 / 5"
		and String(icon_led_tracker.get("day_accessible_text", "")) == "DAY 1 / 5"
		and String(icon_led_tracker.get("order_icon", "")) == "order_check"
		and bool(icon_led_tracker.get("order_icon_visible", false))
		and String(icon_led_tracker.get("order_text", "")) == "2 / 3"
		and String(icon_led_tracker.get("order_accessible_text", "")).begins_with("PROMOTION IN REACH"),
		"browser diagnostics should publish the three stable headline shapes, concise values, and complete semantic copy",
		failures,
	)
	if first_order_action != null:
		first_order_action.grab_focus()
		var accept_press := InputEventAction.new()
		accept_press.action = &"ui_accept"
		accept_press.pressed = true
		Input.parse_input_event(accept_press)
		await process_frame
		var accept_release := InputEventAction.new()
		accept_release.action = &"ui_accept"
		accept_release.pressed = false
		Input.parse_input_event(accept_release)
		await process_frame
	_check(
		first_order_action != null
		and first_order_action.focus_mode == Control.FOCUS_ALL
		and first_order_action.custom_minimum_size == Vector2(32.0, 24.0)
		and String(first_order_action.get_meta("semantic_action", "")) == "open_flockwatch_order"
		and "OPEN THIS GOAL IN FLOCKWATCH" in first_order_action.tooltip_text
		and StringName(observed.get("live_order_id", &"")) == &"prove_the_plan"
		and int(observed.get("live_order_index", -1)) == 0
		and int(ui.live_order_progress().get("mark_request_serial", 0)) == 1
		and String(ui.live_order_progress().get("last_requested_objective_id", "")) == "prove_the_plan",
		"each semantic mark should be a focusable mouse, touch, keyboard, and controller shortcut",
		failures,
	)
	_check(
		first_order_stamp != null
		and second_order_stamp != null
		and third_order_stamp != null
		and first_order_stamp.is_visible_in_tree()
		and third_order_stamp.is_visible_in_tree()
		and String(first_order_stamp.get_meta("objective_id", "")) == "prove_the_plan"
		and String(first_order_stamp.get_meta("metric", "")) == "quota_met"
		and String(first_order_stamp.get_meta("semantic_icon", "")) == "order_clutch"
		and first_order_stamp_icon != null and first_order_stamp_icon.icon_kind() == &"order_clutch"
		and first_order_state_icon != null
		and String(first_order_state_icon.get_meta("semantic_icon", "")) == "status_need"
		and String(first_order_stamp.get_meta("state_shape", "")) == "diamond_exclamation"
		and not bool(first_order_stamp.get_meta("on_track", true))
		and String(second_order_stamp.get_meta("objective_id", "")) == "farmer_confidence"
		and String(second_order_stamp.get_meta("semantic_icon", "")) == "order_favor"
		and second_order_stamp_icon != null and second_order_stamp_icon.icon_kind() == &"order_favor"
		and second_order_state_icon != null
		and String(second_order_state_icon.get_meta("semantic_icon", "")) == "status_pass"
		and String(second_order_stamp.get_meta("state_shape", "")) == "ring_check"
		and bool(second_order_stamp.get_meta("on_track", false))
		and String(third_order_stamp.get_meta("objective_id", "")) == "no_rework_spiral"
		and String(third_order_stamp.get_meta("semantic_icon", "")) == "order_trays"
		and third_order_stamp_icon != null and third_order_stamp_icon.icon_kind() == &"order_trays"
		and third_order_state_icon != null
		and String(third_order_state_icon.get_meta("semantic_icon", "")) == "status_pass"
		and bool(third_order_stamp.get_meta("on_track", false))
		and first_order_stamp.tooltip_text.begins_with("NEEDS ACTION  //  PROVE THE PLAN")
		and not bool(first_order_stamp.get_meta("change_pulse_active", true))
		and not bool(third_order_stamp.get_meta("change_pulse_active", true))
		and String(third_order_stamp.get_meta("change_settled", "")) == "seeded",
		"active badge should expose stable quota, confidence, and rework marks in authored order",
		failures,
	)
	ui.set_interface_scale(1.5)
	await process_frame
	await process_frame
	var scaled_progress := ui.live_order_progress()
	var scaled_stamp_size := scaled_progress.get("stamp_size", {}) as Dictionary
	var scaled_state_icon_size := scaled_progress.get("state_icon_size", {}) as Dictionary
	var scaled_badge_rect := badge.get_global_rect() if badge != null else Rect2()
	_check(
		is_equal_approx(float(scaled_progress.get("interface_scale", 0.0)), 1.5)
		and is_equal_approx(float(scaled_stamp_size.get("width", 0.0)), 48.0)
		and is_equal_approx(float(scaled_stamp_size.get("height", 0.0)), 36.0)
		and is_equal_approx(float(scaled_state_icon_size.get("width", 0.0)), 15.0)
		and status_icon.custom_minimum_size == Vector2(25.5, 25.5)
		and day_icon.custom_minimum_size == Vector2(25.5, 25.5)
		and order_progress_icon.custom_minimum_size == Vector2(25.5, 25.5)
		and first_order_stamp_icon.custom_minimum_size == Vector2(19.5, 19.5)
		and first_order_action.custom_minimum_size == Vector2(48.0, 36.0)
		and scaled_badge_rect.size.x >= 309.5
		and scaled_badge_rect.end.x <= harness.size.x + 0.5,
		"150-percent interface scale should enlarge tracker marks, hit areas, and frame together",
		failures,
	)
	harness.size = Vector2(390.0, 844.0)
	await process_frame
	await process_frame
	var narrow_scaled_badge_rect := badge.get_global_rect() if badge != null else Rect2()
	_check(
		narrow_scaled_badge_rect.position.x >= -0.5
		and narrow_scaled_badge_rect.end.x <= harness.size.x + 0.5
		and narrow_scaled_badge_rect.size.x >= 353.5
		and String(badge.get_meta("layout_mode", "")) == "narrow",
		"the enlarged tracker should stay fully contained in a 390px-wide viewport",
		failures,
	)
	harness.size = Vector2(1280.0, 720.0)
	ui.set_interface_scale(1.0)
	await process_frame
	await process_frame
	var ready_states := day_one_states.duplicate(true)
	ready_states[0]["on_track"] = true
	ready_states[0]["detail"] = "ON TRACK  //  PROVE THE PLAN  //  MET"
	var improved_delta := ui.set_live_order_progress(3, 3, &"probation:1", ready_states)
	_check(
		improved_delta == 1
		and order_progress_label.text == "3 / 3"
		and bool(order_progress_row.get_meta("promotion_ready", false))
		and String(order_promotion_icon.get_meta("promotion_state", "")) == "ready"
		and order_promotion_icon.modulate.is_equal_approx(Color("f4df9d"))
		and int(ui.live_order_progress().get("on_track", 0)) == 3
		and bool(ui.live_order_progress().get("promotion_ready", false))
		and int(order_promotion_icon.get_meta("promotion_ready_pulse_serial", 0)) == 1
		and bool(order_promotion_icon.get_meta("promotion_ready_pulse_active", false))
		and String(order_promotion_icon.get_meta("promotion_ready_pulse_settled", "")) == "animating"
		and badge.modulate.is_equal_approx(Color.WHITE)
		and bool(first_order_stamp.get_meta("change_pulse_active", false))
		and first_order_state_icon != null
		and String(first_order_state_icon.get_meta("semantic_icon", "")) == "status_pass"
		and String(first_order_stamp.get_meta("state_shape", "")) == "ring_check"
		and String(first_order_stamp.get_meta("change_direction", "")) == "fill"
		and int(first_order_stamp.get_meta("change_serial", 0)) == 1
		and String(first_order_stamp.get_meta("change_settled", "")) == "animating"
		and first_order_stamp.scale.is_equal_approx(Vector2(1.10, 1.55))
		and first_order_stamp.modulate.is_equal_approx(Color("d7ffe9"))
		and not bool(third_order_stamp.get_meta("change_pulse_active", true)),
		"the completed quota order should pulse its egg mark rather than an aggregate boundary",
		failures,
	)
	await create_timer(0.45).timeout
	_check(
		not bool(order_promotion_icon.get_meta("promotion_ready_pulse_active", true))
		and String(order_promotion_icon.get_meta("promotion_ready_pulse_settled", "")) == "settled"
		and order_promotion_icon.scale.is_equal_approx(Vector2.ONE)
		and order_promotion_icon.modulate.is_equal_approx(Color("f4df9d"))
		and not bool(first_order_stamp.get_meta("change_pulse_active", true))
		and String(first_order_stamp.get_meta("change_settled", "")) == "settled"
		and first_order_stamp.scale.is_equal_approx(Vector2.ONE)
		and first_order_stamp.modulate.is_equal_approx(Color.WHITE),
		"promotion-ready glow and changed semantic mark should settle to their stable states",
		failures,
	)
	ui.set_reduced_motion(true)
	var risk_delta := ui.set_live_order_progress(2, 3, &"probation:1", day_one_states)
	_check(
		risk_delta == -1
		and badge.modulate.is_equal_approx(Color.WHITE)
		and String(first_order_stamp.get_meta("change_direction", "")) == "empty"
		and int(first_order_stamp.get_meta("change_serial", 0)) == 2
		and not bool(first_order_stamp.get_meta("change_pulse_active", true))
		and String(first_order_stamp.get_meta("change_settled", "")) == "instant"
		and first_order_stamp.scale.is_equal_approx(Vector2.ONE)
		and "Nothing is filed until review" in order_progress_label.tooltip_text
		and "Closing metrics can still move" in order_progress_label.tooltip_text,
		"risk transitions should remain legible without a pulse when reduced motion is active",
		failures,
	)
	var swapped_states := day_one_states.duplicate(true)
	swapped_states[0]["on_track"] = true
	swapped_states[1]["on_track"] = false
	var swap_delta := ui.set_live_order_progress(2, 3, &"probation:1", swapped_states)
	_check(
		swap_delta == 0
		and String(first_order_stamp.get_meta("change_direction", "")) == "fill"
		and String(second_order_stamp.get_meta("change_direction", "")) == "empty"
		and int(first_order_stamp.get_meta("change_serial", 0)) == 3
		and int(second_order_stamp.get_meta("change_serial", 0)) == 3
		and String(first_order_stamp.get_meta("change_settled", "")) == "instant"
		and String(second_order_stamp.get_meta("change_settled", "")) == "instant",
		"equal-count swaps should still identify the exact order gained and order lost",
		failures,
	)
	var swapped_ready_states := swapped_states.duplicate(true)
	swapped_ready_states[1]["on_track"] = true
	var reduced_ready_delta := ui.set_live_order_progress(3, 3, &"probation:1", swapped_ready_states)
	_check(
		reduced_ready_delta == 1
		and int(order_promotion_icon.get_meta("promotion_ready_pulse_serial", 0)) == 2
		and not bool(order_promotion_icon.get_meta("promotion_ready_pulse_active", true))
		and String(order_promotion_icon.get_meta("promotion_ready_pulse_settled", "")) == "instant"
		and order_promotion_icon.scale.is_equal_approx(Vector2.ONE)
		and order_promotion_icon.modulate.is_equal_approx(Color("f4df9d"))
		and String(second_order_stamp.get_meta("change_direction", "")) == "fill"
		and int(second_order_stamp.get_meta("change_serial", 0)) == 4
		and not bool(second_order_stamp.get_meta("change_pulse_active", true))
		and String(second_order_stamp.get_meta("change_settled", "")) == "instant",
		"reduced motion should acknowledge promotion readiness without animating",
		failures,
	)
	var next_day_states := day_one_states.duplicate(true)
	next_day_states[1]["on_track"] = false
	var next_day_delta := ui.set_live_order_progress(1, 3, &"probation:2", next_day_states)
	_check(
		next_day_delta == 0
		and order_progress_label.text == "1 / 3"
		and String(order_promotion_icon.get_meta("promotion_state", "")) == "recover"
		and String(third_order_stamp.get_meta("change_direction", "stale")) == ""
		and String(third_order_stamp.get_meta("change_settled", "")) == "seeded",
		"a new shift should seed quietly instead of replaying a stale reward cue",
		failures,
	)
	ui.show_active_campaign({
		"next_objective": {
			"promotion_opportunity": {"available": false},
		},
	})
	_check(
		not order_promotion_icon.visible
		and not bool(order_progress_row.get_meta("promotion_opportunity", true))
		and not bool(ui.live_order_progress().get("promotion_opportunity", true))
		and not bool(order_promotion_icon.get_meta("promotion_ready_pulse_active", true))
		and String(order_promotion_icon.get_meta("promotion_ready_pulse_settled", "")) == "cleared",
		"routine score bundles should clear the live promotion crest",
		failures,
	)

	ui.apply_snapshot({
		"view": &"title",
		"day": 1,
		"total_days": 5,
		"continue_available": false,
		"challenge_contract_catalog": _challenge_contract_catalog(),
		"selected_new_challenge_contract_id": "standard_filing",
		"active_career_slot": "roost_a",
		"career_profile": CareerPortfolioScript.identity(&"open_nest"),
		"career_slot_catalog": CareerPortfolioScript.slot_catalog(),
		"career_identity_catalog": CareerPortfolioScript.identity_catalog(),
		"replay_scenario_catalog": SimulationScript.replay_scenario_catalog(),
		"selected_replay_scenario_id": "baseline_book",
	})
	await process_frame
	var title_panel := ui.find_child("CampaignTitlePanel", true, false) as PanelContainer
	var title_heading := ui.find_child("CampaignTitle", true, false) as Label
	var title_description := ui.find_child("CampaignTitleDescription", true, false) as Label
	var mabel_card := ui.find_child("MabelProfileCard", true, false) as PanelContainer
	var mabel_identity := ui.find_child("CampaignMabelIdentity", true, false) as Label
	var mabel_traits := ui.find_child("CampaignMabelTraits", true, false) as Label
	var mabel_quote := ui.find_child("CampaignMabelQuote", true, false) as Label
	var mabel_portrait := ui.find_child("CampaignMabelPortrait", true, false) as TextureRect
	var challenge_selector := ui.find_child("ChallengeContractSelector", true, false) as OptionButton
	var career_slot_selector := ui.find_child("CareerSlotSelector", true, false) as OptionButton
	var career_identity_selector := ui.find_child("CareerIdentitySelector", true, false) as OptionButton
	var replay_scenario_selector := ui.find_child("ReplayScenarioSelector", true, false) as OptionButton
	var replay_scenario_rule := ui.find_child("ReplayScenarioRule", true, false) as Label
	var challenge_card := ui.find_child("ChallengeContractCard", true, false) as PanelContainer
	var challenge_summary := ui.find_child("ChallengeContractSummary", true, false) as Label
	var challenge_fund := ui.find_child("ChallengeOpeningFund", true, false) as Label
	var challenge_quota := ui.find_child("ChallengeOpeningQuota", true, false) as Label
	var challenge_files := ui.find_child("ChallengeOpeningFiles", true, false) as Label
	var challenge_terms_toggle := ui.find_child("ChallengeContractTermsToggle", true, false) as Button
	var challenge_detail := ui.find_child("ChallengeContractDetail", true, false) as Label
	var probation_summary := ui.find_child("ProbationFiveShiftSummary", true, false) as PanelContainer
	var probation_summary_detail := ui.find_child("ProbationFiveShiftDetail", true, false) as Label
	var journey_file := ui.find_child("ProbationJourneyFile", true, false) as Label
	var journey_shifts := ui.find_child("ProbationJourneyShifts", true, false) as Label
	var journey_review := ui.find_child("ProbationJourneyReview", true, false) as Label
	var journey_file_caption := ui.find_child("ProbationJourneyFileCaption", true, false) as Label
	var journey_shifts_caption := ui.find_child("ProbationJourneyShiftsCaption", true, false) as Label
	var journey_review_caption := ui.find_child("ProbationJourneyReviewCaption", true, false) as Label
	var new_button := ui.find_child("NewCampaignButton", true, false) as Button
	var continue_button := ui.find_child("ContinueCampaignButton", true, false) as Button
	var back_button := ui.find_child("BackToSavedCampaignButton", true, false) as Button
	_check(title_panel != null and title_panel.is_visible_in_tree(), "first load should show the campaign title panel", failures)
	_check(
		career_slot_selector != null and career_slot_selector.item_count == 3
		and career_identity_selector != null and career_identity_selector.item_count == 3
		and replay_scenario_selector != null and replay_scenario_selector.item_count == 7
		and replay_scenario_rule != null and "PROVEN FIVE-SHIFT" in replay_scenario_rule.text.to_upper(),
		"new-file intake should expose three isolated roosts, three coop identities, and baseline plus six compact replay files (slots=%d identities=%d scenarios=%d rule=%s)" % [
			career_slot_selector.item_count if career_slot_selector != null else -1,
			career_identity_selector.item_count if career_identity_selector != null else -1,
			replay_scenario_selector.item_count if replay_scenario_selector != null else -1,
			replay_scenario_rule.text if replay_scenario_rule != null else "missing",
		],
		failures,
	)
	_check(modal_host.is_visible_in_tree(), "title panel should be an intentional blocking modal", failures)
	_check(
		title_heading != null and title_heading.text == "MEET MABEL",
		"title should foreground one named hen before management abstractions",
		failures,
	)
	_check(
		 title_description != null
		and title_description.text == "Protect the flock. Survive five shifts."
		and "Help Mabel" in title_description.tooltip_text
		and "terms lock when Shift 1 starts" in title_description.tooltip_text
		and title_description.tooltip_text == String(title_description.get_meta("accessible_text", "")),
		"title subtitle should state the setup action once while retaining its locked-terms explanation",
		failures,
	)
	_check(
		mabel_card != null
		and mabel_card.is_visible_in_tree()
		and mabel_portrait != null
		and mabel_portrait.texture != null
		and ui.find_child("ProbationTermsCard", true, false) == null,
		"Mabel's portrait-led profile should replace the abstract probation-rules card",
		failures,
	)
	_check(
		mabel_identity != null and mabel_identity.text == "MABEL  //  JUNIOR PECKWORK HEN",
		"Mabel profile should establish her name and current role",
		failures,
	)
	_check(
		mabel_traits != null
		and mabel_traits.text == "APPEALS SPECIALIST  ·  SAVES FEED",
		"Mabel profile should expose her specialty and motivation",
		failures,
	)
	_check(
		mabel_quote != null
		and mabel_quote.text == "\"The farmer remembers the basket, not the beak that filled it.\"",
		"Mabel profile should give the opening hen a concise first-person perspective",
		failures,
	)
	_check(
		continue_button != null and continue_button.disabled and not continue_button.is_visible_in_tree(),
		"fresh intake should omit an unusable Continue action instead of adding a disabled peer",
		failures,
	)
	_check(
		new_button != null
		and new_button.text == "START SHIFT 1  [N]"
		and new_button.theme_type_variation == &"PrimaryButton"
		and new_button.focus_mode == Control.FOCUS_ALL,
		"fresh intake should expose one primary Mabel action with keyboard focus",
		failures,
	)
	var fresh_primary_action := ui.title_primary_action_state()
	_check(
		String(fresh_primary_action.get("copy", "")) == "NEXT: CHOOSE DIFFICULTY"
		and String(fresh_primary_action.get("action_id", "")) == "campaign_new"
		and bool(fresh_primary_action.get("actionable", false))
		and String(fresh_primary_action.get("visible_label", "")) == new_button.text
		and _contains_all(
			String(fresh_primary_action.get("accessible_text", "")),
			["Choose a difficulty", "three-step run", "START SHIFT 1 [N]"],
		),
		"fresh intake should publish the same visible next action to assistive and diagnostic clients",
		failures,
	)
	_check(
		_count_visible_primary_buttons(title_panel) == 1
		and back_button != null and not back_button.is_visible_in_tree(),
		"fresh intake should have exactly one visually primary CTA and no irrelevant Back action",
		failures,
	)
	_check(
		probation_summary != null and probation_summary.is_visible_in_tree()
		and probation_summary_detail != null
		and probation_summary_detail.text == "QUICK RECAP AFTER EACH SHIFT"
		and journey_file != null and journey_file.text == "1 FILE"
		and journey_shifts != null and journey_shifts.text == "5 QUICK FILES"
		and journey_review != null and journey_review.text == "FINAL REVIEW"
		and journey_file_caption != null and journey_file_caption.text == "1  TEAM UP"
		and journey_shifts_caption != null and journey_shifts_caption.text == "2  WORK"
		and journey_review_caption != null and journey_review_caption.text == "3  PASS"
		and ui.find_child("ProbationDayStamp_1", true, false) == null
		and ui.find_child("ProbationDayStamp_5", true, false) == null,
		"one numbered three-step journey should replace abstract labels and five equal-weight day stamps",
		failures,
	)
	_check(
		challenge_selector != null
		and challenge_selector.item_count == 3
		and challenge_selector.focus_mode == Control.FOCUS_ALL
		and challenge_selector.get_item_text(0) == "LEARNING  ·  SUPPORTED"
		and challenge_selector.get_item_text(1) == "STANDARD  ·  RECOMMENDED"
		and challenge_selector.get_item_text(2) == "EXPERT  ·  EXECUTIVE"
		and challenge_selector.get_item_text(challenge_selector.selected) == "STANDARD  ·  RECOMMENDED"
		and ui.selected_challenge_contract_id() == &"standard_filing",
		"title should default its keyboard/controller selector to a clear recommended Standard filing",
		failures,
	)
	_check(
		challenge_card != null and challenge_card.is_visible_in_tree()
		and challenge_summary != null and challenge_summary.is_visible_in_tree()
		and challenge_fund != null and challenge_fund.text == "$50"
		and challenge_quota != null and challenge_quota.text == "16"
		and challenge_files != null and challenge_files.text == "6"
		and challenge_terms_toggle != null and challenge_terms_toggle.is_visible_in_tree()
		and challenge_terms_toggle.focus_mode == Control.FOCUS_ALL
		and challenge_terms_toggle.shortcut != null
		and challenge_detail != null and not challenge_detail.is_visible_in_tree()
		and challenge_summary.text == "BALANCED  ·  LOCKS ON START"
		and "BALANCED ROUTES" in challenge_summary.tooltip_text
		and challenge_summary.tooltip_text == String(challenge_summary.get_meta("accessible_text", ""))
		and _contains_all(challenge_terms_toggle.tooltip_text, [
			"recommended authored balance",
			"SCORE >= 60 / 100", "WELFARE >= 45", "COMPLIANCE >= 55",
			"FARMER FAVOR >= 50", "CRACK RATE <= 25.00%", "Every permanent doctrine",
		]),
		"Standard should keep every exact threshold keyboard-accessible behind a compact disclosure",
		failures,
	)
	if challenge_terms_toggle != null:
		challenge_terms_toggle.set_pressed_no_signal(true)
		challenge_terms_toggle.pressed.emit()
	_check(
		challenge_detail != null and challenge_detail.is_visible_in_tree()
		and challenge_detail.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
		and _contains_all(challenge_detail.text, [
			"SCORE >= 60 / 100", "WELFARE >= 45", "COMPLIANCE >= 55",
			"FARMER FAVOR >= 50", "CRACK RATE <= 25.00%", "DIFFICULTY NOTE",
		]),
		"View Exact Terms should reveal every Standard filing threshold without changing authority",
		failures,
	)
	if challenge_selector != null:
		challenge_selector.select(0)
		challenge_selector.item_selected.emit(0)
	_check(
		ui.selected_challenge_contract_id() == &"supported_flock"
		and challenge_summary.text == "MORE FORGIVING  ·  LOCKS ON START"
		and challenge_detail != null
		and _contains_all(challenge_detail.text, [
			"FUND $65.00", "QUOTA 14", "LIVE FILES 6", "RECOVERY CUSHION",
			"SCORE >= 45 / 100", "WELFARE >= 45", "COMPLIANCE >= 55",
			"FARMER FAVOR >= 45", "CRACK RATE <= 30.00%", "Best for learning",
		]),
		"Supported Flock should retain its complete immutable threshold disclosure",
		failures,
	)
	if challenge_selector != null:
		challenge_selector.select(2)
		challenge_selector.item_selected.emit(2)
	_check(
		ui.selected_challenge_contract_id() == &"executive_audit"
		and StringName(observed["challenge_contract"]) == &"executive_audit"
		and challenge_summary.text == "HIGH PRESSURE  ·  LOCKS ON START"
		and challenge_detail != null
		and _contains_all(challenge_detail.text, [
			"FUND $48.00", "QUOTA 18", "LIVE FILES 8", "AUDIT SURGE",
			"SCORE >= 65 / 100", "WELFARE >= 48", "COMPLIANCE >= 65",
			"FARMER FAVOR >= 52", "CRACK RATE <= 24.50%",
			"demanding replay contract",
			"Harvest Partnership has a proven specialist route",
		]),
		"changing the selector should retain the exact Executive contract and disclose its specialist route",
		failures,
	)
	if challenge_terms_toggle != null:
		challenge_terms_toggle.set_pressed_no_signal(false)
		challenge_terms_toggle.pressed.emit()
	_check(
		challenge_detail != null and not challenge_detail.is_visible_in_tree(),
		"exact terms should collapse back to the compact new-file summary",
		failures,
	)
	if new_button != null:
		new_button.pressed.emit()
	_check(int(observed["new"]) == 1, "new campaign action should emit its public signal", failures)
	for viewport_size: Vector2 in [
		Vector2(1280.0, 720.0),
		Vector2(2560.0, 1600.0),
		Vector2(1440.0, 1000.0),
		Vector2(390.0, 844.0),
	]:
		await _check_responsive_layout(ui, harness, "CampaignTitlePanel", viewport_size, failures)
		_check_title_character_layout(
			title_panel,
			mabel_card,
			[mabel_identity, mabel_traits, mabel_quote],
			new_button,
			viewport_size,
			failures,
		)
	await _check_max_scale_expanded_copy(
		ui,
		harness,
		"CampaignTitlePanel",
		["NewCampaignButton", "ChallengeContractSelector"],
		failures,
	)

	# An existing file must be legible before it can be replaced, and replacement
	# requires a second, explicit danger action with the safe choice focused first.
	ui.apply_snapshot({
		"view": &"title",
		"day": 1,
		"total_days": 5,
		"continue_available": true,
		"challenge_contract_catalog": _challenge_contract_catalog(),
		"selected_new_challenge_contract_id": "executive_audit",
		"resume_summary": {
			"day": 3,
			"completed_shifts": 2,
			"probation_score": 66,
			"rank_label": "Trusted Layer",
			"stage_label": "Farmer Review",
			"challenge_contract": _challenge_contract("supported_flock"),
			"offline_recap": {
				"status_id": "paused",
				"status_label": "Economy paused",
				"elapsed_label": "2 hours 14 minutes since last file",
				"elapsed_short_label": "2h 14m",
				"detail": "No files advanced while the terminal was closed.",
			},
			"return_recap": {
				"last_filed_label": "Shift 2 closed",
				"routing_mastery": {
					"short_label": "NEW FIT RECORD  x15   /   CHASE  x20",
					"accessible_text": "New best-fit routing record: 15 consecutive recommended tray assignments. Next mastery record: 20.",
				},
				"status_id": "attention",
				"status_label": "Workflow Debt",
				"status_reason": "Two overdue and one rework file are consuming future production.",
				"next_action": "Route matching specialties before adding another binder.",
			},
		},
	})
	await process_frame
	await process_frame
	var resume_card := ui.find_child("CampaignResumeCard", true, false) as PanelContainer
	var resume_details := ui.find_child("CampaignResumeDetails", true, false) as Label
	_check(
		resume_card != null and resume_card.is_visible_in_tree()
		and resume_details != null
		and _contains_all(resume_details.text, [
			"DAY 3 / 5", "2 SHIFTS FILED", "SCORE 66", "TRUSTED LAYER",
			"FARMER REVIEW", "SAVED CHALLENGE CONTRACT  //  SUPPORTED FLOCK",
			"OFFLINE  //  2H 14M  //  ECONOMY PAUSED",
			"LAST FILED  //  SHIFT 2 CLOSED",
			"ROUTING  //  NEW FIT RECORD X15 / CHASE X20",
			"UNRESOLVED  //  WORKFLOW DEBT",
			"Two overdue and one rework file",
			"NEXT  //  Route matching specialties",
		]),
		"title should recap the checkpoint, paused offline economy, unresolved condition, and next action",
		failures,
	)
	await _check_responsive_layout(
		ui,
		harness,
		"CampaignTitlePanel",
		Vector2(390.0, 844.0),
		failures,
	)
	_check(
		continue_button != null and continue_button.is_visible_in_tree()
		and not continue_button.disabled
		and continue_button.text == "CONTINUE SAVED FILE  [C]"
		and continue_button.theme_type_variation == &"PrimaryButton"
		and new_button != null and new_button.is_visible_in_tree()
		and new_button.text == "REVIEW A NEW FILE  [N]"
		and new_button.theme_type_variation == &"DecisionChoiceButton"
		and _count_visible_primary_buttons(title_panel) == 1,
		"a resumable intake should be Continue-first with one primary CTA and a secondary new-file path",
		failures,
	)
	var resume_primary_action := ui.title_primary_action_state()
	_check(
		String(resume_primary_action.get("copy", "")) == "NEXT: CONTINUE SAVED FILE"
		and String(resume_primary_action.get("action_id", "")) == "campaign_continue"
		and bool(resume_primary_action.get("actionable", false))
		and String(resume_primary_action.get("visible_label", "")) == continue_button.text
		and _contains_all(
			String(resume_primary_action.get("accessible_text", "")),
			["CONTINUE SAVED FILE [C]", "verify and resume", "without changing"],
		),
		"resume intake should publish its real primary CTA instead of generic modal guidance",
		failures,
	)
	_check(
		mabel_card != null and not mabel_card.is_visible_in_tree()
		and challenge_card != null and not challenge_card.is_visible_in_tree()
		and probation_summary != null and not probation_summary.is_visible_in_tree()
		and mabel_identity != null and mabel_identity.text == "MABEL  //  JUNIOR PECKWORK HEN",
		"resume landing should suppress setup density while retaining Mabel's authored identity for the new-file stage",
		failures,
	)
	_check(
		ui.get_viewport().gui_get_focus_owner() == continue_button,
		"resume-first intake should default keyboard/gamepad focus to Continue",
		failures,
	)
	new_button.pressed.emit()
	await process_frame
	await process_frame
	var replacement_host := ui.find_child("CampaignReplacementConfirmation", true, false) as Control
	_check(
		int(observed["new"]) == 1
		and replacement_host != null and not replacement_host.is_visible_in_tree()
		and resume_card != null and not resume_card.is_visible_in_tree()
		and continue_button != null and not continue_button.is_visible_in_tree()
		and mabel_card != null and mabel_card.is_visible_in_tree()
		and challenge_card != null and challenge_card.is_visible_in_tree()
		and probation_summary != null and probation_summary.is_visible_in_tree()
		and new_button.text == "START SHIFT 1  [N]"
		and new_button.theme_type_variation == &"PrimaryButton"
		and back_button != null and back_button.is_visible_in_tree()
		and _count_visible_primary_buttons(title_panel) == 1,
		"Review a New File should stage compact setup without emitting or replacing the saved campaign",
		failures,
	)
	_check(
		ui.title_intake_phase() == &"new_file"
		and StringName(observed["title_phase"]) == &"new_file",
		"staging a new file should publish its visible intake phase",
		failures,
	)
	_check(
		String(ui.title_primary_action_state().get("visible_label", ""))
		== "START SHIFT 1  [N]"
		and String(ui.title_primary_action_state().get("action_id", ""))
		== "campaign_new",
		"staged new-file setup should switch the semantic primary action with the visible CTA",
		failures,
	)
	_check(
		challenge_selector != null and ui.get_viewport().gui_get_focus_owner() == challenge_selector,
		"staged new-file setup should put keyboard/gamepad focus on its immutable contract selector",
		failures,
	)
	if back_button != null:
		back_button.pressed.emit()
	await process_frame
	await process_frame
	_check(
		resume_card != null and resume_card.is_visible_in_tree()
		and continue_button != null and continue_button.is_visible_in_tree()
		and challenge_card != null and not challenge_card.is_visible_in_tree()
		and ui.get_viewport().gui_get_focus_owner() == continue_button
		and ui.selected_challenge_contract_id() == &"executive_audit"
		and int(observed["new"]) == 1,
		"Back should restore the saved-file landing without losing selection or emitting a campaign intent",
		failures,
	)
	_check(
		ui.title_intake_phase() == &"resume"
		and StringName(observed["title_phase"]) == &"resume",
		"Back should publish the restored resume-first phase",
		failures,
	)
	new_button.pressed.emit()
	await process_frame
	await process_frame
	new_button.pressed.emit()
	await process_frame
	await process_frame
	var replacement_panel := ui.find_child("CampaignReplacementConfirmationPanel", true, false) as PanelContainer
	var replacement_body := ui.find_child("CampaignReplacementConfirmationBody", true, false) as Label
	var keep_button := ui.find_child("CancelCampaignReplacementButton", true, false) as Button
	var replace_button := ui.find_child("ConfirmCampaignReplacementButton", true, false) as Button
	_check(int(observed["new"]) == 1, "staging and replacement review must not emit a destructive new-campaign intent", failures)
	_check(
		replacement_host != null and replacement_host.is_visible_in_tree()
		and replacement_body != null
		and _contains_all(replacement_body.text, [
			"DAY 3 / 5", "SCORE 66", "SUPPORTED FLOCK",
			"NEW CHALLENGE CONTRACT  //  EXECUTIVE AUDIT", "untouched", "written and verified",
		])
		and ui.selected_challenge_contract_id() == &"executive_audit",
		"replacement confirmation should name the affected file and transactional guarantee",
		failures,
	)
	_check(
		keep_button != null and ui.get_viewport().gui_get_focus_owner() == keep_button,
		"replacement confirmation should default keyboard/gamepad focus to keeping the current file",
		failures,
	)
	if replacement_panel != null:
		var replacement_rect := replacement_panel.get_global_rect()
		_check(
			replacement_rect.position.x >= -0.5
			and replacement_rect.end.x <= harness.size.x + 0.5
			and replacement_rect.position.y >= -0.5
			and replacement_rect.end.y <= harness.size.y + 0.5,
			"replacement confirmation should remain fully contained in the 390x844 portrait viewport",
			failures,
		)
	if keep_button != null:
		keep_button.pressed.emit()
	await process_frame
	_check(
		replacement_host != null and not replacement_host.is_visible_in_tree()
		and ui.get_viewport().gui_get_focus_owner() == new_button
		and int(observed["new"]) == 1
		and ui.selected_challenge_contract_id() == &"executive_audit",
		"cancel should preserve the campaign, challenge selection, and originating focus",
		failures,
	)
	new_button.pressed.emit()
	await process_frame
	if replace_button != null:
		replace_button.pressed.emit()
	_check(
		int(observed["new"]) == 2
		and replacement_host != null and not replacement_host.is_visible_in_tree()
		and ui.selected_challenge_contract_id() == &"executive_audit",
		"only explicit confirmation should emit once while retaining the selected challenge contract",
		failures,
	)
	harness.size = Vector2(1280.0, 720.0)
	await process_frame

	ui.apply_snapshot({
		"view": &"title",
		"continue_available": true,
		"challenge_contract_catalog": _challenge_contract_catalog(),
		"selected_new_challenge_contract_id": "standard_filing",
		"resume_summary": {
			"day": 2,
			"completed_shifts": 1,
			"probation_score": 50,
			"challenge_contract": {},
			"challenge_contract_verified": false,
		},
	})
	await process_frame
	_check(
		resume_details != null
		and "UNVERIFIED SAVED TERMS" in resume_details.text
		and "STANDARD FILING" not in resume_details.text,
		"an unverified current-schema saved contract must never be previewed as Standard",
		failures,
	)

	ui.apply_snapshot({
		"view": &"title",
		"continue_available": true,
		"challenge_contract_catalog": _challenge_contract_catalog(),
		"selected_new_challenge_contract_id": "standard_filing",
		"resume_summary": {
			"senior_roost": true,
			"senior_year": 3,
			"roost_marks": 7,
			"mandate_seals": 2,
			"challenge_contract": _challenge_contract("supported_flock"),
			"challenge_contract_verified": true,
		},
	})
	await process_frame
	_check(
		resume_details != null
		and "SENIOR YEAR 3" in resume_details.text
		and "CHALLENGE CONTRACT" not in resume_details.text
		and "SUPPORTED FLOCK" not in resume_details.text,
		"Senior resume copy should suppress the completed probation contract",
		failures,
	)

	ui.apply_snapshot({
		"view": "title",
		"day": 3,
		"total_days": 5,
		"continue_available": true,
	})
	await process_frame
	_check(
		day_label.text == "3 / 5" and day_label.tooltip_text == "DAY 3 / 5",
		"calendar-led badge should react to plain campaign snapshot data",
		failures,
	)
	_check(
		String(day_segment_1.get_meta("state", "")) == "complete"
		and String(day_segment_3.get_meta("state", "")) == "current"
		and String(day_segment_5.get_meta("state", "")) == "upcoming",
		"day rail should distinguish completed, current, and upcoming probation shifts",
		failures,
	)
	_check(not continue_button.disabled, "continue should enable when a resumable campaign exists", failures)
	continue_button.pressed.emit()
	_check(int(observed["continue"]) == 1, "continue action should emit its public signal", failures)

	ui.show_between_shift_report({
		"day": 2,
		"total_days": 5,
		"score": 1840,
		"rank": "Silver Comb",
		"rank_progress": {
			"current_score": 1840,
			"current_rank": "silver_comb",
			"current_rank_label": "Silver Comb",
			"band_floor": 1500,
			"next_threshold": 2000,
			"next_rank": "golden_comb",
			"next_rank_label": "Golden Comb",
			"points_to_next": 160,
			"progress_basis_points": 6800,
			"complete": false,
		},
		"score_receipt": {
			"shift_number": 2,
			"score_before": 1703,
			"score_after": 1840,
			"score_delta": 137,
			"raw_shift_delta": 137,
			"applied_shift_delta": 137,
			"rank_before": "bronze_comb",
			"rank_before_label": "Bronze Comb",
			"rank_after": "silver_comb",
			"rank_after_label": "Silver Comb",
			"rank_change": "promotion",
			"components": [
				{
					"id": "probation_orders",
					"label": "Probation Orders",
					"delta": 120,
					"detail": "Two orders cleared without an exception.",
				},
				{
					"id": "daily_clutch",
					"label": "Daily Clutch",
					"delta": 47,
					"detail": "Forty-seven eggs entered the campaign ledger.",
				},
				{
					"id": "shell_quality",
					"label": "Shell Quality",
					"delta": -12,
					"detail": "Cracked shells reduced the filing value.",
				},
				{
					"id": "queue_control",
					"label": "Queue Control",
					"delta": -8,
					"detail": "Open claims remained at close.",
				},
				{
					"id": "flock_safeguards",
					"label": "Flock Safeguards",
					"delta": -10,
					"detail": "One welfare warning was filed.",
				},
			],
		},
		"strategy_receipt": {
			"day": 2,
			"directive_id": "shell_assurance",
			"policy_name": "ASSURANCE",
			"semantic_icon": "shield",
			"status": "mixed",
			"tone": "warning",
			"headline": "MIXED RESULT",
			"forecast": "HELPS 2 / RISKS 1",
			"actual": "1/2 HELP / 1/1 RISKS COVERED",
			"support_total": 2,
			"support_met": 1,
			"risk_total": 1,
			"risk_covered": 1,
			"detail": "MORNING PLAN / ASSURANCE\nFORECAST / HELPS 2 / RISKS 1\nCLOSING RESULT / 1/2 HELP / 1/1 RISKS COVERED\nMET / SUPPORT / ORDERLY COOP\nMISSED / SUPPORT / CLEAN FILES\nMET / RISK / MEET THE CLUTCH",
		},
		"market_forecast": {
			"visible": true,
			"day": 3,
			"season_label": "SPRING HATCH SURGE",
			"season_short_label": "SPRING SURGE",
			"days_remaining": 2,
			"cause": "Nest-damage demand rises as fresh hatches strain the routine-loss book.",
			"certainty": "GUARANTEED CALENDAR",
			"uncertainty": "The season and spot quote are filed; seeded file mix can still vary.",
			"opportunity_lane_id": "nest_damage",
			"opportunity_lane_label": "Nest damage",
			"opportunity_demand_basis_points": 2000,
			"feed_spot_unit_price_cents": 240,
			"next_market_day": 5,
			"next_season_short_label": "PREDATOR SEASON",
			"next_opportunity_lane_label": "Predator loss",
			"next_opportunity_demand_basis_points": 2500,
			"next_feed_spot_unit_price_cents": 260,
		},
		"credit_memo": {
			"day": 2,
			"decision_id": "golden_egg_dossier",
			"option_id": "farmer_credit",
			"style_id": "shared_scoop",
			"worker_name": "Mabel",
			"cost_cents": 0,
			"outcome": "The farmer presented Mabel's golden file as a management breakthrough.",
		},
		"hen_highlight": {
			"day": 2,
			"type": "golden_deliverable",
			"worker_name": "Mabel",
			"career_title": "Senior Peckwork Hen",
			"relationship_label": "Warm",
			"headline": "Golden Deliverable",
			"body": "Mabel laid one golden egg. The farmer congratulated management before collecting it.",
			"metric": "5 EGGS  //  4 SOUND  //  1 GOLDEN  //  $14.80 CREDIT",
			"eggs": 5,
			"sound": 4,
			"cracked": 0,
			"golden": 1,
			"credit_cents": 1480,
			"tone": "gold",
		},
		"ledgers": [
			{"label": "Eggs Filed", "value": 47, "detail": "TWO-SHIFT TOTAL"},
			{"label": "Feed Fund", "value": 9235, "format": "currency_cents", "detail": "BANKED"},
			{"label": "Shell Integrity", "value": 91, "format": "percent", "detail": "CAMPAIGN QUALITY"},
		],
		"challenge_contract": _challenge_contract("standard_filing"),
		"probation_safeguard_forecast": _safeguard_forecast(false, false),
		"next_objective": {
			"title": "Day 3 probation orders",
			"description": "- Meet the clutch: Meet the farmer's daily quota.\n- Orderly coop: Close with compliance at 68 or better.\n- Trim the trays: Leave no more than three overdue files.",
			"orders": [
				{"id": "meet_the_clutch", "title": "Meet the clutch", "description": "Meet the farmer's daily quota.", "metric": "quota_met", "comparison": "equal", "target": 1},
				{"id": "orderly_coop", "title": "Orderly coop", "description": "Close with compliance at 68 or better.", "metric": "compliance", "comparison": "minimum", "target": 68},
				{"id": "trim_the_trays", "title": "Trim the trays", "description": "Leave no more than three overdue files.", "metric": "overdue_files", "comparison": "maximum", "target": 3},
			],
			"reward_score": 3,
			"reward": "Complete all three orders for a +3 score bundle.",
			"promotion_opportunity": {
				"available": true,
				"current_score": 1997,
				"reward_score": 3,
				"projected_score": 2000,
				"next_threshold": 2000,
				"next_rank": "golden_comb",
				"next_rank_label": "Golden Comb",
				"points_to_next": 3,
			},
		},
		"milestone_choices": [
			{
				"id": "fast_keys",
				"title": "Brass Keycaps",
				"description": "Peckwork starts faster.",
				"effect": "+10% processing speed",
				"doctrine": {
					"label": "SHELL ASSURANCE",
					"summary": "Control brittle files before they become tomorrow's rework.",
					"strengths": ["SHELL QUALITY", "COMPLIANCE"],
					"watchouts": ["FLOCK WELFARE"],
					"playbook": "Alternate quality pressure with recovery.",
				},
			},
			{
				"id": "soft_nests",
				"title": "Soft Nests",
				"description": "Cushion rushed production.",
				"effect": "-8% crack risk",
			},
		],
	})
	await process_frame
	await process_frame
	var report_panel := ui.find_child("ProbationReportPanel", true, false) as PanelContainer
	var report_day := ui.find_child("ProbationReportDay", true, false) as Label
	var report_heading := ui.find_child("ProbationReportTitle", true, false) as Label
	var score := ui.find_child("ReportScore", true, false) as Label
	var shift_delta := ui.find_child("ReportShiftDelta", true, false) as Label
	var shift_delta_caption := ui.find_child("ReportShiftDeltaCaption", true, false) as Label
	var shift_delta_icon := ui.find_child("ReportShiftDeltaIcon", true, false) as TextureRect
	var shift_delta_panel := (
		shift_delta.get_parent().get_parent().get_parent() as PanelContainer
		if shift_delta != null else
		null
	)
	var score_panel := (
		score.get_parent().get_parent().get_parent() as PanelContainer
		if score != null else
		null
	)
	var score_row := ui.find_child("ProbationReportScoreRow", true, false) as HFlowContainer
	var receipt_summary := ui.find_child("ReportScoreReceiptSummary", true, false) as Label
	var receipt_grid := ui.find_child("ReportScoreReceiptGrid", true, false) as GridContainer
	var strategy_card := ui.find_child("ReportStrategyReceipt", true, false) as PanelContainer
	var strategy_icon := ui.find_child("ReportStrategyPolicyIcon", true, false) as FlockwatchIconBadge
	var strategy_outcome := ui.find_child("ReportStrategyOutcome", true, false) as Label
	var strategy_policy := ui.find_child("ReportStrategyPolicy", true, false) as Label
	var strategy_forecast := ui.find_child("ReportStrategyForecast", true, false) as Label
	var strategy_actual := ui.find_child("ReportStrategyActual", true, false) as Label
	var market_card := ui.find_child("ReportMarketPulse", true, false) as PanelContainer
	var market_icon := ui.find_child("ReportMarketPulseIcon", true, false) as FlockwatchIconBadge
	var market_kicker := ui.find_child("ReportMarketPulseKicker", true, false) as Label
	var market_season := ui.find_child("ReportMarketPulseSeason", true, false) as Label
	var market_signal := ui.find_child("ReportMarketPulseSignal", true, false) as Label
	var rank := ui.find_child("ReportRank", true, false) as Label
	var rank_caption := ui.find_child("ReportRankCaption", true, false) as Label
	var rank_icon := ui.find_child("ReportRankIcon", true, false) as TextureRect
	var rank_value_row := ui.find_child("ReportRankValueRow", true, false) as HBoxContainer
	var rank_progress := ui.find_child("ReportRankProgress", true, false) as ProgressBar
	var story_row := ui.find_child("ReportShiftStories", true, false) as HFlowContainer
	var credit_memo_card := ui.find_child("FiledCreditMemoCard", true, false) as PanelContainer
	var credit_memo_label := ui.find_child("FiledCreditMemoLabel", true, false) as Label
	var credit_glance := ui.find_child("FiledCreditMemoGlanceStrip", true, false) as HFlowContainer
	var highlight_card := ui.find_child("ShiftHenHighlightCard", true, false) as PanelContainer
	var highlight_eyebrow := ui.find_child("ShiftHenHighlightEyebrow", true, false) as Label
	var highlight_headline := ui.find_child("ShiftHenHighlightHeadline", true, false) as Label
	var highlight_body := ui.find_child("ShiftHenHighlightBody", true, false) as Label
	var highlight_metric := ui.find_child("ShiftHenHighlightMetric", true, false) as Label
	var highlight_glance := ui.find_child("ShiftHenHighlightGlanceStrip", true, false) as HFlowContainer
	var first_ledger := ui.find_child("ReportLedgerValue1", true, false) as Label
	var second_ledger := ui.find_child("ReportLedgerValue2", true, false) as Label
	var third_ledger := ui.find_child("ReportLedgerValue3", true, false) as Label
	var ledger_section := ui.find_child("ReportLedgerSectionTitle", true, false) as Label
	var first_ledger_card := ui.find_child("ReportCumulativeLedger1", true, false) as PanelContainer
	var first_ledger_line := ui.find_child("ReportLedgerMetricLine1", true, false) as HBoxContainer
	var first_ledger_detail := ui.find_child("ReportLedgerDetail1", true, false) as Label
	var safeguard_panel := ui.find_child("ReportProbationSafeguardReceipt", true, false) as PanelContainer
	var safeguard_heading := ui.find_child("ReportProbationSafeguardHeading", true, false) as Label
	var safeguard_grid := ui.find_child("ReportProbationSafeguardGrid", true, false) as GridContainer
	var safeguard_summary := ui.find_child("ReportProbationSafeguardSummary", true, false) as Label
	var safeguard_score := ui.find_child("ReportProbationSafeguardRow_1", true, false) as Label
	var safeguard_favor := ui.find_child("ReportProbationSafeguardRow_4", true, false) as Label
	var safeguard_shells := ui.find_child("ReportProbationSafeguardRow_5", true, false) as Label
	var safeguard_pass_grid := ui.find_child("ReportProbationSafeguardPassGrid", true, false) as GridContainer
	var safeguard_pass_score := ui.find_child("ReportProbationSafeguardPassRow_1", true, false) as Label
	var safeguard_pass_favor := ui.find_child("ReportProbationSafeguardPassRow_4", true, false) as Label
	var safeguard_pass_score_icon := ui.find_child("ReportProbationSafeguardPassIcon_1", true, false) as TextureRect
	var safeguard_pass_favor_icon := ui.find_child("ReportProbationSafeguardPassIcon_4", true, false) as TextureRect
	var objective := ui.find_child("NextShiftObjective", true, false) as Label
	var objective_body := ui.find_child("NextShiftObjectiveDescription", true, false) as Label
	var objective_orders := ui.find_child("ProbationOrderStrip", true, false) as HFlowContainer
	var objective_reward_badge := ui.find_child("NextShiftObjectiveRewardBadge", true, false) as PanelContainer
	var objective_promotion_icon := ui.find_child("NextShiftObjectivePromotionIcon", true, false) as TextureRect
	var objective_reward_label := ui.find_child("NextShiftObjectiveRewardLabel", true, false) as Label
	var objective_progress := ui.find_child("NextShiftObjectiveProgress", true, false) as Label
	var objective_card := ui.find_child("NextShiftObjectiveCard", true, false) as PanelContainer
	var milestone_section := ui.find_child("MilestoneChoiceSection", true, false) as VBoxContainer
	var milestone_legend := ui.find_child("MilestoneSymbolLegend", true, false) as HBoxContainer
	var milestone_edge_legend := ui.find_child("MilestoneEdgeLegend", true, false) as Label
	var milestone_watch_legend := ui.find_child("MilestoneWatchLegend", true, false) as Label
	var milestone_board_legend := ui.find_child("MilestoneBoardLegend", true, false) as Label
	var choice := ui.find_child("MilestoneChoice_fast_keys", true, false) as Button
	var milestone_hint := ui.find_child("MilestoneChoiceHint", true, false) as Label
	var requisitions := ui.find_child("ReviewRoostRequisitionsButton", true, false) as Button
	var report_continue := ui.find_child("ContinueProbationButton", true, false) as Button
	var report_details_toggle := ui.find_child("ReportDetailsToggle", true, false) as Button
	var report_details_section := ui.find_child("ReportDetailsSection", true, false) as VBoxContainer
	_check(
		report_details_toggle != null
		and report_details_toggle.text == "SHIFT DETAILS  [D]"
		and report_details_section != null
		and not report_details_section.is_visible_in_tree()
		and objective_card != null and objective_card.is_visible_in_tree()
		and report_continue != null and report_continue.is_visible_in_tree(),
		"between-shift reports should open on score, tomorrow's plan, and actions with accounting folded",
		failures,
	)
	var collapsed_report_accessibility := ui.accessible_text()
	_check(
		_contains_all(
			collapsed_report_accessibility,
			["SHIFT 2 RESULTS", "Score 1,840", "Mabel", "GOLDEN DELIVERABLE", "NEXT SHIFT MARKET", "GUARANTEED CALENDAR", "DAY 3 PROBATION ORDERS"],
		),
		"folded report details should remain fully represented in assistive output (%s)" % collapsed_report_accessibility,
		failures,
	)
	if report_details_toggle != null:
		report_details_toggle.pressed.emit()
	await process_frame
	_check(
		report_details_toggle != null
		and report_details_toggle.text == "HIDE SHIFT DETAILS  [D]"
		and report_details_section != null
		and report_details_section.is_visible_in_tree(),
		"Shift Details should reveal the complete accounting in place without changing report state",
		failures,
	)
	_check(report_panel != null and report_panel.is_visible_in_tree(), "between shifts should show the probation report", failures)
	_check(
		strategy_card != null and strategy_card.is_visible_in_tree()
		and String(strategy_card.get_meta("status", "")) == "mixed"
		and String(strategy_card.get_meta("directive_id", "")) == "shell_assurance"
		and int(strategy_card.get_meta("support_total", 0)) == 2
		and int(strategy_card.get_meta("support_met", 0)) == 1
		and int(strategy_card.get_meta("risk_total", 0)) == 1
		and int(strategy_card.get_meta("risk_covered", 0)) == 1
		and strategy_icon != null and strategy_icon.icon_kind() == &"shield"
		and String(strategy_icon.get_meta("semantic_icon", "")) == "shield"
		and strategy_outcome != null and strategy_outcome.text == "MIXED RESULT"
		and strategy_policy != null and strategy_policy.text == "ASSURANCE"
		and strategy_forecast != null and strategy_forecast.text == "HELPS 2 / RISKS 1"
		and strategy_actual != null
		and strategy_actual.text == "1/2 HELP / 1/1 RISKS COVERED"
		and "MISSED / SUPPORT / CLEAN FILES" in strategy_card.tooltip_text
		and String(strategy_card.get_meta("accessible_text", "")) == strategy_card.tooltip_text,
		"the closing report should reconcile the morning policy forecast with exact order outcomes",
		failures,
	)
	_check(
		market_card != null and market_card.is_visible_in_tree()
		and market_icon != null and market_icon.icon_kind() == &"calendar"
		and String(market_icon.get_meta("semantic_icon", "")) == "calendar"
		and market_kicker != null and market_kicker.text == "NEXT MARKET"
		and market_season != null and market_season.text == "SPRING SURGE  ·  2 DAYS"
		and market_signal != null and market_signal.text == "NEST DAMAGE +20%  ·  FEED $2.40"
		and int(market_card.get_meta("day", 0)) == 3
		and String(market_card.get_meta("opportunity_lane", "")) == "nest_damage"
		and int(market_card.get_meta("demand_basis_points", 0)) == 2000
		and int(market_card.get_meta("feed_spot_unit_price_cents", 0)) == 240
		and "CAUSE  //  Nest-damage demand rises" in market_card.tooltip_text
		and "UNCERTAINTY  //  The season and spot quote are filed" in market_card.tooltip_text
		and "THEN  //  DAY 5  //  PREDATOR SEASON  //  PREDATOR LOSS +25%  //  FEED $2.60" in market_card.tooltip_text
		and String(market_card.get_meta("accessible_text", "")).contains("GUARANTEED CALENDAR"),
		"the next-shift report should expose a compact actionable market pulse while retaining cause, certainty, and the following turn",
		failures,
	)
	_check(
		int(observed["report_filing_settled"]) == 1,
		"reduced-motion reports should settle one semantic filing receipt immediately",
		failures,
	)
	_check(
		shift_delta_panel != null
		and String(shift_delta_panel.get_meta("result_pulse_motion", "")) == "instant"
		and bool(shift_delta_panel.get_meta("result_pulse_receipt", false))
		and is_equal_approx(shift_delta_panel.scale.x, 1.0),
		"reduced-motion reports should settle the shift-total confirmation without animation",
		failures,
	)
	_check(
		rank_icon != null
		and String(rank_icon.get_meta("promotion_stamp_motion", "")) == "instant"
		and bool(rank_icon.get_meta("promotion_stamp", false))
		and is_equal_approx(rank_icon.scale.x, 1.0),
		"reduced-motion promotions should settle one semantic crest stamp instantly",
		failures,
	)
	_check(
		report_day != null
		and report_day.text == "SHIFT 2 RESULTS"
		and not report_day.visible
		and report_day.tooltip_text == "CLOSING FILE 3 / 3 · SHIFT 2 OF 5 · PROBATION REPORT"
		and String(report_day.get_meta("accessible_text", "")) == report_day.tooltip_text
		and bool(report_day.get_meta("merged_into_result_heading", false))
		and report_heading != null and report_heading.text == "SHIFT 2 RESULTS"
		and report_heading.tooltip_text.begins_with("FARMER'S SHIFT ASSESSMENT\nCLOSING FILE 3 / 3")
		and String(report_heading.get_meta("accessible_text", "")) == report_heading.tooltip_text
		and String(report_heading.get_meta("authored_report_heading", "")) == "FARMER'S SHIFT ASSESSMENT"
		and bool(report_heading.get_meta("compact_result_heading", false)),
		"probation reports should merge duplicate result headings while retaining authored filing provenance",
		failures,
	)
	_check(score != null and score.text == "1,840", "report should present a readable cumulative score", failures)
	_check(shift_delta != null and shift_delta.text == "+137", "report should present the exact signed shift score", failures)
	_check(
		shift_delta_caption != null and shift_delta_caption.text == "THIS SHIFT"
		and shift_delta_caption.tooltip_text == "SHIFT SCORE"
		and String(shift_delta_caption.get_meta("accessible_text", "")) == "SHIFT SCORE"
		and shift_delta_icon != null and shift_delta_icon.is_visible_in_tree()
		and shift_delta_icon.texture != null
		and String(shift_delta_icon.get_meta("semantic_icon", "")) == "score_sum"
		and String(shift_delta_icon.get_meta("delta_direction", "")) == "gain"
		and shift_delta_panel != null
		and bool(shift_delta_panel.get_meta("compact_delta_caption", false))
		and String(shift_delta_panel.get_meta("authored_metric_caption", "")) == "SHIFT SCORE"
		and String(shift_delta.get_meta("accessible_text", "")).begins_with("SHIFT SCORE +137"),
		"shift contribution should use a plain caption and receipt-sum badge while retaining authored semantics",
		failures,
	)
	_check(
		shift_delta != null and _colors_close(shift_delta.get_theme_color("font_color"), Color("73b5a7")),
		"a positive shift score should use the report's positive teal",
		failures,
	)
	var receipt_orders := ui.find_child("ReportScoreReceiptChipLabel_1", true, false) as Label
	var receipt_clutch := ui.find_child("ReportScoreReceiptChipLabel_2", true, false) as Label
	var receipt_shells := ui.find_child("ReportScoreReceiptChipLabel_3", true, false) as Label
	var receipt_queues := ui.find_child("ReportScoreReceiptChipLabel_4", true, false) as Label
	var receipt_flock := ui.find_child("ReportScoreReceiptChipLabel_5", true, false) as Label
	var receipt_orders_icon := ui.find_child("ReportScoreReceiptChipIcon_1", true, false) as TextureRect
	var receipt_shells_icon := ui.find_child("ReportScoreReceiptChipIcon_3", true, false) as TextureRect
	var receipt_flock_icon := ui.find_child("ReportScoreReceiptChipIcon_5", true, false) as TextureRect
	var receipt_orders_card := ui.find_child("ReportScoreReceiptChip_1", true, false) as PanelContainer
	_check(
		receipt_grid != null and receipt_grid.is_visible_in_tree()
		and receipt_grid.columns == 5
		and receipt_summary != null and not receipt_summary.is_visible_in_tree()
		and receipt_orders != null and receipt_orders.text == "+120"
		and receipt_clutch != null and receipt_clutch.text == "+47"
		and receipt_shells != null and receipt_shells.text == "-12"
		and receipt_queues != null and receipt_queues.text == "-8"
		and receipt_flock != null and receipt_flock.text == "-10"
		and receipt_orders_icon != null and receipt_orders_icon.texture != null
		and receipt_shells_icon != null and receipt_shells_icon.texture != null
		and receipt_flock_icon != null and receipt_flock_icon.texture != null
		and receipt_orders_card != null and bool(receipt_orders_card.get_meta("icon_first", false))
		and String(receipt_orders_card.get_meta("semantic_icon", "")) == "order_compliance"
		and String(receipt_shells_icon.get_meta("semantic_icon", "")) == "receipt_shell"
		and String(receipt_flock_icon.get_meta("semantic_icon", "")) == "receipt_flock",
		"score receipts should replace accounting captions with five icon-led signed deltas",
		failures,
	)
	_check(
		receipt_grid != null
		and "SHIFT 2 SCORE RECEIPT" in receipt_grid.tooltip_text
		and "Probation Orders  +120" in receipt_grid.tooltip_text
		and "Two orders cleared without an exception." in receipt_grid.tooltip_text
		and String(receipt_grid.get_meta("accessible_text", "")) == receipt_grid.tooltip_text
		and receipt_orders != null
		and receipt_orders.tooltip_text == "Probation Orders  +120  //  Two orders cleared without an exception."
		and shift_delta.tooltip_text == receipt_grid.tooltip_text,
		"receipt chips and score metric should retain the full causal detail for pointer and assistive access",
		failures,
	)
	_check(
		score_row != null and bool(score_row.get_meta("receipt_equation", false))
		and String(score_row.get_meta("visual_flow", "")) == "receipt_components_to_shift_total_to_score"
		and score_row.get_child(1) == shift_delta_panel
		and score_row.get_child(2) == score_panel
		and shift_delta_panel != null
		and bool(shift_delta_panel.get_meta("receives_score_receipts", false))
		and int(shift_delta_panel.get_meta("receipt_component_count", 0)) == 5
		and score_panel != null and bool(score_panel.get_meta("follows_shift_total", false)),
		"filed receipt components should flow directly into this-shift total before the cumulative score",
		failures,
	)
	_check(
		rank != null and rank.text == "SILVER COMB"
		and rank_caption != null and rank_caption.text == "PROMOTED"
		and rank_value_row != null and rank.get_parent() == rank_value_row
		and rank_value_row.get_child(0) == rank_icon
		and rank_icon != null and rank_icon.texture != null
		and String(rank_icon.get_meta("semantic_icon", "")) == "rank_crest"
		and String(rank_icon.get_meta("rank_title", "")) == "SILVER COMB"
		and rank.tooltip_text == "PROMOTED  //  SILVER COMB  //  FROM BRONZE COMB"
		and String(rank.get_meta("accessible_text", "")) == rank.tooltip_text,
		"a real upward rank crossing should become one compact promoted crest stamp",
		failures,
	)
	_check(
		rank_progress != null and rank_progress.is_visible_in_tree()
		and not rank_progress.show_percentage
		and is_equal_approx(rank_progress.value, 6800.0)
		and bool(rank_progress.get_meta("threshold_backed", false))
		and int(rank_progress.get_meta("points_to_next", -1)) == 160
		and String(rank_progress.get_meta("next_rank_label", "")) == "GOLDEN COMB"
		and bool(rank_progress.get_meta("promotion_opportunity", false))
		and int(rank_progress.get_meta("projected_score", -1)) == 2000
		and rank_progress.tooltip_text == "PROMOTED  //  SILVER COMB  //  FROM BRONZE COMB  //  SCORE 1840 / 2000  //  160 TO GOLDEN COMB  //  NEXT ORDER BUNDLE CAN PROMOTE",
		"report rank should show exact threshold-backed momentum without another visible label",
		failures,
	)
	_check(
		rank != null
		and rank.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
		and rank.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING,
		"report rank should wrap instead of rendering a truncated ellipsis",
		failures,
	)
	_check(
		first_ledger != null and first_ledger.text == "47"
		and second_ledger != null and second_ledger.text == "$92.35"
		and third_ledger != null and third_ledger.text == "91%",
		"report should expose exactly three formatted cumulative ledgers",
		failures,
	)
	_check(
		ledger_section != null and ledger_section.text == "5-SHIFT RECORD"
		and ledger_section.tooltip_text == "PROBATION RECORD  //  5-SHIFT VIEW"
		and String(ledger_section.get_meta("accessible_text", "")) == ledger_section.tooltip_text
		and bool(ledger_section.get_meta("compact_record_heading", false))
		and first_ledger_card != null and first_ledger_card.custom_minimum_size.y == 60.0
		and bool(first_ledger_card.get_meta("metric_first", false))
		and first_ledger_line != null and first_ledger_line.get_child(0) == first_ledger
		and first_ledger_detail != null and first_ledger_detail.text == "2-SHIFT TOTAL",
		"probation records should use a compact heading and present each metric first in a compact two-line card",
		failures,
	)
	_check(
		first_ledger_card != null and first_ledger_card.tooltip_text == "TWO-SHIFT TOTAL"
		and String(first_ledger_card.get_meta("accessible_text", "")).contains(
			"EGGS FILED 47. TWO-SHIFT TOTAL"
		),
		"compact record cards should retain the complete authored accounting detail",
		failures,
	)
	_check(
		safeguard_panel != null and safeguard_panel.is_visible_in_tree()
		and safeguard_heading != null and safeguard_heading.text == "PROBATION CHECK"
		and safeguard_heading.tooltip_text == "PASS CHECK  //  5 TARGETS"
		and String(safeguard_heading.get_meta("accessible_text", "")) == safeguard_heading.tooltip_text
		and bool(safeguard_heading.get_meta("compact_pass_heading", false))
		and safeguard_summary != null
		and safeguard_summary.text == "4/5 PASS  //  FIX FAVOR 1"
		and String(safeguard_summary.get_meta("shift_context_source", "")) == "persistent_day_rail"
		and int(safeguard_summary.get_meta("completed_shifts", -1)) == 2
		and int(safeguard_summary.get_meta("required_shifts", -1)) == 5
		and bool(safeguard_summary.get_meta("compact_status_only", false)),
		"between-shift reports should reduce five filed terms to one plain pass check and next fix without repeating the day rail",
		failures,
	)
	_check(
		safeguard_summary != null
		and "2 / 5 SHIFTS FILED" in safeguard_summary.tooltip_text
		and String(safeguard_summary.get_meta("accessible_text", "")) == safeguard_summary.tooltip_text,
		"the compact pass check should retain exact shift progress for pointer and assistive access",
		failures,
	)
	_check(
		safeguard_grid != null and not safeguard_grid.is_visible_in_tree()
		and safeguard_pass_grid != null and safeguard_pass_grid.is_visible_in_tree()
		and safeguard_pass_score != null and safeguard_pass_score.text == "SCORE\n65"
		and String(safeguard_pass_score.get_meta("visual_status_symbol", "")) == "checkmark_badge"
		and safeguard_pass_score_icon != null and safeguard_pass_score_icon.texture != null
		and String(safeguard_pass_score_icon.get_meta("semantic_icon", "")) == "status_pass"
		and safeguard_pass_score.tooltip_text.begins_with("PASS  //  PROBATION SCORE")
		and safeguard_pass_favor != null and safeguard_pass_favor.text == "FAVOR\n49 NEED 1"
		and String(safeguard_pass_favor.get_meta("visual_status_symbol", "")) == "attention_badge"
		and safeguard_pass_favor_icon != null and safeguard_pass_favor_icon.texture != null
		and String(safeguard_pass_favor_icon.get_meta("semantic_icon", "")) == "status_need",
		"at-risk forecasts should use the same five status-first chips as successful reports",
		failures,
	)
	_check(
		safeguard_score != null and not safeguard_score.is_visible_in_tree()
		and safeguard_favor != null and not safeguard_favor.is_visible_in_tree()
		and safeguard_shells != null and not safeguard_shells.is_visible_in_tree()
		and safeguard_pass_favor != null
		and safeguard_pass_favor.tooltip_text == "AT RISK  //  FARMER FAVOR  //  49 >= 50  //  -1 POINT"
		and "STANDARD FILING" in safeguard_panel.tooltip_text
		and "LARGEST RECOVERABLE GAP  //  FARMER FAVOR  //  -1 POINT" in safeguard_panel.tooltip_text,
		"compact pass checks should retain every contract, threshold, comparison, and signed gap as progressive detail",
		failures,
	)
	var all_pass_report := ui.campaign_snapshot().duplicate(true)
	all_pass_report["probation_safeguard_forecast"] = _safeguard_forecast(false, true)
	ui.show_between_shift_report(all_pass_report)
	await process_frame
	await process_frame
	report_details_toggle = ui.find_child("ReportDetailsToggle", true, false) as Button
	if report_details_toggle != null:
		report_details_toggle.pressed.emit()
	await process_frame
	_check(
		safeguard_pass_grid != null and safeguard_pass_grid.is_visible_in_tree()
		and safeguard_summary.text == "5/5 PASS"
		and safeguard_pass_grid.columns == 5,
		"an all-pass forecast should collapse into one status line and five-chip desktop receipt",
		failures,
	)
	_check(
		safeguard_score != null and not safeguard_score.is_visible_in_tree()
		and safeguard_pass_score != null and safeguard_pass_score.text == "SCORE\n65"
		and safeguard_pass_favor != null and safeguard_pass_favor.text == "FAVOR\n52"
		and String(safeguard_pass_favor.get_meta("visual_status_symbol", "")) == "checkmark_badge"
		and String(safeguard_pass_favor_icon.get_meta("semantic_icon", "")) == "status_pass",
		"compact pass chips should communicate status, metric, and current value without repeated accounting sentences",
		failures,
	)
	_check(
		safeguard_pass_favor != null
		and safeguard_pass_favor.tooltip_text == "PASS  //  FARMER FAVOR  //  52 >= 50  //  +2 POINTS"
		and String(safeguard_pass_favor.get_meta("accessible_text", "")) == safeguard_pass_favor.tooltip_text
		and "PASS  //  CRACK RATE  //  25.00% <= 25.00%  //  0.00 PTS" in safeguard_panel.tooltip_text,
		"compact all-pass receipts should retain every exact target and signed delta for pointer and assistive detail",
		failures,
	)
	var clutch_order := ui.find_child("ProbationOrderLabel_1", true, false) as Label
	var compliance_order := ui.find_child("ProbationOrderLabel_2", true, false) as Label
	var tray_order := ui.find_child("ProbationOrderLabel_3", true, false) as Label
	var clutch_order_card := ui.find_child("ProbationOrder_1", true, false) as PanelContainer
	var clutch_order_icon := ui.find_child("ProbationOrderIcon_1", true, false) as TextureRect
	var compliance_order_icon := ui.find_child("ProbationOrderIcon_2", true, false) as TextureRect
	var tray_order_icon := ui.find_child("ProbationOrderIcon_3", true, false) as TextureRect
	_check(
		objective_orders != null and objective_orders.is_visible_in_tree()
		and objective_body != null and not objective_body.is_visible_in_tree()
		and clutch_order != null and clutch_order.text == "MEET THE CLUTCH\nHIT QUOTA"
		and compliance_order != null and compliance_order.text == "ORDERLY COOP\n68+"
		and tray_order != null and tray_order.text == "TRIM THE TRAYS\n<= 3",
		"probation reports should replace three prose bullets with three glance-readable order chips",
		failures,
	)
	_check(
		clutch_order_card != null
		and String(clutch_order_card.get_meta("semantic_icon", "")) == "order_clutch"
		and clutch_order_icon != null
		and String(clutch_order_icon.get_meta("semantic_icon", "")) == "order_clutch"
		and compliance_order_icon != null
		and String(compliance_order_icon.get_meta("semantic_icon", "")) == "order_compliance"
		and tray_order_icon != null
		and String(tray_order_icon.get_meta("semantic_icon", "")) == "order_trays"
		and clutch_order_icon.texture != compliance_order_icon.texture
		and compliance_order_icon.texture != tray_order_icon.texture
		and StringName(ui.call("_probation_order_icon", {
			"id": "farmer_confidence", "metric": "farmer_favor",
		})) == &"order_favor"
		and StringName(ui.call("_probation_order_icon", {
			"id": "no_rework_spiral", "metric": "rework",
		})) == &"order_trays"
		and ManagementUIThemeScript.action_icon(&"order_favor") != null,
		"next-day orders should use distinct metric-backed quota, compliance, farmer-trust, and rework symbols",
		failures,
	)
	_check(
		clutch_order != null
		and clutch_order_card != null
		and clutch_order_card.tooltip_text == "Meet the clutch. Meet the farmer's daily quota. Target HIT QUOTA."
		and String(clutch_order.get_meta("accessible_text", "")) == clutch_order.tooltip_text
		and String(objective_orders.get_meta("accessible_text", "")) == String(
			(all_pass_report["next_objective"] as Dictionary)["description"]
		),
		"compact order chips should retain the complete authored instruction for pointer and assistive detail",
		failures,
	)
	_check(
		objective_reward_badge != null and objective_reward_badge.is_visible_in_tree()
		and objective_reward_label != null and objective_reward_label.text == "+3 SCORE"
		and objective_promotion_icon != null and objective_promotion_icon.is_visible_in_tree()
		and objective_promotion_icon.texture != null
		and String(objective_promotion_icon.get_meta("semantic_icon", "")) == "rank_crest"
		and bool(objective_reward_badge.get_meta("promotion_opportunity", false))
		and int(objective_reward_badge.get_meta("projected_score", -1)) == 2000
		and int(objective_reward_badge.get_meta("target_score", -1)) == 2000
		and objective_progress != null and not objective_progress.is_visible_in_tree(),
		"a threshold-crossing order bundle should share the rank crest and brass emphasis",
		failures,
	)
	_check(
		objective_reward_badge != null
		and objective_reward_badge.tooltip_text == "PROMOTION READY  //  COMPLETE ALL 3 ORDERS  //  +3 SCORE  //  1997 -> 2000  //  GOLDEN COMB"
		and String(objective_reward_badge.get_meta("accessible_text", "")) == objective_reward_badge.tooltip_text
		and objective_card != null
		and objective_card.tooltip_text.contains("Meet the farmer's daily quota")
		and objective_card.tooltip_text.contains("Complete all three orders for a +3 score bundle."),
		"the compact reward badge and objective card should retain the complete authored rules as progressive detail",
		failures,
	)
	# Applying a fresh report snapshot rebuilds authored milestone buttons. Keep
	# subsequent interaction assertions pointed at the live controls.
	choice = ui.find_child("MilestoneChoice_fast_keys", true, false) as Button
	milestone_hint = ui.find_child("MilestoneChoiceHint", true, false) as Label
	report_continue = ui.find_child("ContinueProbationButton", true, false) as Button
	_check(
		objective != null
		and objective.text == "DAY 3 ORDERS"
		and objective.tooltip_text.contains("NEXT SHIFT OBJECTIVE  //  DAY 3 PROBATION ORDERS")
		and objective.tooltip_text.contains("Complete all three orders for a +3 score bundle.")
		and String(objective.get_meta("accessible_text", "")) == objective.tooltip_text
		and bool(objective.get_meta("compact_orders_heading", false)),
		"structured probation orders should use a compact day heading while preserving authored context as progressive detail",
		failures,
	)
	_check(
		story_row != null and story_row.is_visible_in_tree()
		and credit_memo_card != null and credit_memo_card.is_visible_in_tree()
		and highlight_card != null and highlight_card.is_visible_in_tree(),
		"credit attribution and the causal hen file should share the report story row",
		failures,
	)
	var credit_layer := ui.find_child("FiledCreditLayerChipLabel", true, false) as Label
	var credit_byline := ui.find_child("FiledCreditBylineChipLabel", true, false) as Label
	var credit_fund := ui.find_child("FiledCreditFundChipLabel", true, false) as Label
	var credit_layer_icon := ui.find_child("FiledCreditLayerChipIcon", true, false) as TextureRect
	var credit_byline_icon := ui.find_child("FiledCreditBylineChipIcon", true, false) as TextureRect
	var credit_fund_icon := ui.find_child("FiledCreditFundChipIcon", true, false) as TextureRect
	_check(
		credit_memo_label != null and credit_memo_label.text == "CREDIT GOES TO"
		and bool(credit_memo_label.get_meta("outcome_first_credit_heading", false))
		and credit_memo_label.tooltip_text.begins_with("GOLDEN DOSSIER FILED  //  FARMER CREDIT")
		and credit_glance != null and credit_glance.is_visible_in_tree()
		and credit_layer != null and credit_layer.text == "MABEL"
		and credit_byline != null and credit_byline.text == "FLOCK"
		and credit_fund != null and credit_fund.text == "$0"
		and credit_layer_icon != null and credit_layer_icon.texture != null
		and String(credit_layer_icon.get_meta("semantic_icon", "")) == "receipt_hen"
		and credit_byline_icon != null and credit_byline_icon.texture != null
		and String(credit_byline_icon.get_meta("semantic_icon", "")) == "receipt_flock"
		and credit_fund_icon != null and credit_fund_icon.texture != null
		and String(credit_fund_icon.get_meta("semantic_icon", "")) == "receipt_fund"
		and "farmer presented Mabel's golden file" in credit_glance.tooltip_text
		and "MABEL -> FLOCK  //  FUND NO COST" in credit_glance.tooltip_text
		and String(credit_glance.get_meta("accessible_text", "")) == credit_glance.tooltip_text,
		"credit evidence should lead with a plain attribution heading and use icon-led attribution and fund values",
		failures,
	)
	_check(
		highlight_eyebrow != null and highlight_eyebrow.text == "MABEL  //  WARM"
		and highlight_headline != null and highlight_headline.text == "GOLDEN DELIVERABLE"
		and highlight_body != null and not highlight_body.is_visible_in_tree()
		and "farmer congratulated management" in highlight_body.text
		and highlight_metric != null and not highlight_metric.is_visible_in_tree()
		and highlight_metric.text == "5 EGGS  //  4 SOUND  //  1 GOLDEN  //  $14.80 CREDIT"
		and highlight_glance != null and highlight_glance.is_visible_in_tree(),
		"hen highlight should preserve the subject, satirical outcome, and shift evidence",
		failures,
	)
	var evidence_eggs := ui.find_child("ShiftHenEvidenceChip_1Label", true, false) as Label
	var evidence_sound := ui.find_child("ShiftHenEvidenceChip_2Label", true, false) as Label
	var evidence_gold := ui.find_child("ShiftHenEvidenceChip_3Label", true, false) as Label
	var evidence_credit := ui.find_child("ShiftHenEvidenceChip_4Label", true, false) as Label
	var evidence_eggs_icon := ui.find_child("ShiftHenEvidenceChip_1Icon", true, false) as TextureRect
	var evidence_gold_icon := ui.find_child("ShiftHenEvidenceChip_3Icon", true, false) as TextureRect
	var evidence_credit_icon := ui.find_child("ShiftHenEvidenceChip_4Icon", true, false) as TextureRect
	var receipt_first_chip := ui.find_child("ReportScoreReceiptChip_1", true, false) as PanelContainer
	var receipt_last_chip := ui.find_child("ReportScoreReceiptChip_5", true, false) as PanelContainer
	var credit_first_chip := ui.find_child("FiledCreditLayerChip", true, false) as PanelContainer
	var credit_last_chip := ui.find_child("FiledCreditFundChip", true, false) as PanelContainer
	var hen_first_chip := ui.find_child("ShiftHenEvidenceChip_1", true, false) as PanelContainer
	var hen_last_chip := ui.find_child("ShiftHenEvidenceChip_4", true, false) as PanelContainer
	_check(
		evidence_eggs != null and evidence_eggs.text == "5"
		and evidence_sound != null and evidence_sound.text == "4"
		and evidence_gold != null and evidence_gold.text == "1"
		and evidence_credit != null and evidence_credit.text == "$14.80"
		and evidence_eggs_icon != null and evidence_eggs_icon.texture != null
		and String(evidence_eggs_icon.get_meta("semantic_icon", "")) == "order_clutch"
		and evidence_gold_icon != null and evidence_gold_icon.texture != null
		and String(evidence_gold_icon.get_meta("semantic_icon", "")) == "receipt_specialty"
		and evidence_credit_icon != null and evidence_credit_icon.texture != null
		and String(evidence_credit_icon.get_meta("semantic_icon", "")) == "receipt_fund"
		and bool(story_row.get_meta("compact_story_glance", false))
		and credit_memo_card.custom_minimum_size.y == 76.0
		and highlight_card.custom_minimum_size.y == 76.0,
		"paired probation evidence should use one caption-free icon row of exact results",
		failures,
	)
	_check(
		receipt_first_chip != null and int(receipt_first_chip.get_meta("reveal_order", -1)) == 0
		and receipt_last_chip != null and int(receipt_last_chip.get_meta("reveal_order", -1)) == 4
		and credit_first_chip != null and int(credit_first_chip.get_meta("reveal_order", -1)) == 5
		and credit_last_chip != null and int(credit_last_chip.get_meta("reveal_order", -1)) == 7
		and hen_first_chip != null and int(hen_first_chip.get_meta("reveal_order", -1)) == 8
		and hen_last_chip != null and int(hen_last_chip.get_meta("reveal_order", -1)) == 11
		and String(receipt_grid.get_meta("reveal_motion", "")) == "instant"
		and String(credit_glance.get_meta("reveal_motion", "")) == "instant"
		and String(highlight_glance.get_meta("reveal_motion", "")) == "instant"
		and receipt_first_chip.modulate.is_equal_approx(Color.WHITE)
		and hen_last_chip.modulate.is_equal_approx(Color.WHITE),
		"report evidence should retain one score-to-attribution-to-hen filing order and settle instantly under reduced motion",
		failures,
	)
	_check(
		highlight_body != null
		and "SENIOR PECKWORK HEN" in highlight_body.tooltip_text
		and "5 EGGS" in highlight_body.tooltip_text
		and highlight_eyebrow != null
		and _colors_close(highlight_eyebrow.get_theme_color("font_color"), Color("d1a650")),
		"golden hen highlights should expose their full file and use the gold tone",
		failures,
	)
	var highlight_style := highlight_card.get_theme_stylebox("panel") as StyleBoxFlat if highlight_card != null else null
	_check(
		highlight_style != null
		and _colors_close(highlight_style.border_color, Color("d1a650").darkened(0.1)),
		"hen highlight card border should carry the selected highlight tone",
		failures,
	)
	_check(milestone_section != null and milestone_section.is_visible_in_tree(), "offered milestones should appear as choice cards", failures)
	_check(
		milestone_legend != null and milestone_legend.is_visible_in_tree()
		and milestone_edge_legend != null and milestone_edge_legend.text == "+ EDGE"
		and milestone_edge_legend.tooltip_text == "EDGE  //  The doctrine's permanent strength."
		and milestone_watch_legend != null and milestone_watch_legend.text == "! WATCH"
		and milestone_watch_legend.tooltip_text == "WATCH  //  The doctrine's ongoing tradeoff."
		and milestone_board_legend != null and not milestone_board_legend.visible,
		"probation milestones should decode their benefit and tradeoff symbols without adding card prose",
		failures,
	)
	_check(
		choice != null and choice.focus_mode == Control.FOCUS_ALL
		and choice.custom_minimum_size.y >= 88.0
		and choice.text.split("\n", false).size() == 3
		and _contains_all(choice.text, [
			"SHELL ASSURANCE", "BRASS KEYCAPS", "+10% WORK SPEED",
			"+ SHELL QUALITY", "! FLOCK WELFARE",
		])
		and _contains_all(choice.tooltip_text, [
			"Peckwork starts faster.", "+10% processing speed",
			"SHELL QUALITY // COMPLIANCE",
			"Alternate quality pressure with recovery.",
		])
		and _contains_all(String(choice.get_meta("accessible_text", "")), [
			"Option 1", "SHELL ASSURANCE", "+10% processing speed",
			"SHELL QUALITY // COMPLIANCE", "FLOCK WELFARE",
		])
		and String(choice.get_meta("doctrine_id", "")) == "fast_keys",
		"doctrine milestone cards should use a compact three-line glance while preserving exact effect, edge, obligation, and playbook detail",
		failures,
	)
	_check(report_continue != null and report_continue.disabled, "report should wait for a required milestone choice", failures)
	var initial_report_action := ui.report_primary_action_state()
	_check(
		String(initial_report_action.get("copy", "")) == "NEXT: CHOOSE ONE PERMANENT EDGE"
		and String(initial_report_action.get("action_id", "")) == "campaign_milestone"
		and bool(initial_report_action.get("actionable", false))
		and "available permanent milestone cards" in String(initial_report_action.get("accessible_text", "")),
		"report action state should expose the required milestone instead of its disabled continuation",
		failures,
	)
	_check(
		ui.focus_report_primary_action()
		and ui.get_viewport().gui_get_focus_owner() == choice,
		"the required report action should focus the first available milestone card",
		failures,
	)
	_check(
		requisitions != null
		and requisitions.text == "REQUISITIONS  [R]"
		and requisitions.icon != null
		and String(requisitions.get_meta("semantic_icon", "")) == "requisition_sheet"
		and _contains_all(
			String(requisitions.get_meta("accessible_text", "")),
			["Review Roost requisitions", "closing-credit file"],
		)
		and report_continue != null
		and report_continue.text == "NEXT SHIFT  [C]"
		and report_continue.icon != null
		and String(report_continue.get_meta("semantic_icon", "")) == "advance_arrow"
		and String(report_continue.get_meta("outcome_first_action", "")) == "advance"
		and _contains_all(
			String(report_continue.get_meta("accessible_text", "")),
			["FILE REPORT & PLAN NEXT SHIFT", "Choose one milestone card"],
		),
		"report actions should use concise icon-plus-verb labels while retaining exact assistive copy (requisitions=%s; requisitions_accessible=%s; continue=%s; continue_accessible=%s)" % [
			requisitions.text if requisitions != null else "missing",
			String(requisitions.get_meta("accessible_text", "")) if requisitions != null else "missing",
			report_continue.text if report_continue != null else "missing",
			String(report_continue.get_meta("accessible_text", "")) if report_continue != null else "missing",
		],
		failures,
	)
	if choice != null:
		choice.pressed.emit()
	_check(StringName(observed["milestone"]) == &"fast_keys", "milestone action should emit its stable identifier", failures)
	_check(ui.selected_milestone_id() == &"fast_keys", "component should expose its selected milestone", failures)
	_check(choice != null and choice.theme_type_variation == &"SelectedChoiceButton", "selected milestone should remain visually persistent", failures)
	_check(milestone_hint != null and "SHELL ASSURANCE  //  BRASS KEYCAPS" in milestone_hint.text, "selected doctrine identity should remain visible before filing", failures)
	_check(report_continue != null and not report_continue.disabled, "choosing a milestone should unlock continuation", failures)
	var selected_report_action := ui.report_primary_action_state()
	_check(
		String(selected_report_action.get("copy", "")) == "NEXT SHIFT  [C]"
		and String(selected_report_action.get("action_id", "")) == "campaign_report_continue"
		and bool(selected_report_action.get("actionable", false))
		and "FILE REPORT & PLAN NEXT SHIFT" in String(selected_report_action.get("accessible_text", ""))
		and ui.focus_report_primary_action()
		and ui.get_viewport().gui_get_focus_owner() == report_continue,
		"selected milestone should hand the report action to the exact visible next-shift filing",
		failures,
	)
	if report_continue != null:
		report_continue.pressed.emit()
	_check(int(observed["continue"]) == 2, "report continuation should reuse the campaign continuation signal", failures)
	var abandon := ui.find_child("AbandonCampaignButton", true, false) as Button
	_check(
		abandon != null and abandon.text == "SAVE & EXIT  [A]"
		and abandon.theme_type_variation != &"DangerButton"
		and abandon.icon != null
		and String(abandon.get_meta("semantic_icon", "")) == "safe_shelve"
		and String(abandon.get_meta("outcome_first_action", "")) == "save_exit"
		and _contains_all(
			String(abandon.get_meta("accessible_text", "")),
			["Save this checkpoint", "return to intake", "exact checkpoint"],
		),
		"leaving a report should state its safe save-and-exit outcome rather than use a filing metaphor",
		failures,
	)
	if abandon != null:
		abandon.pressed.emit()
	_check(int(observed["abandon"]) == 1, "abandon action should emit its public signal", failures)

	var report_rect := report_panel.get_global_rect()
	_check(
		report_rect.position.x >= 0.0 and report_rect.end.x <= 1280.0
		and report_rect.position.y >= 60.0 and report_rect.size.y <= 900.0,
		"the complete report should remain a bounded scroll document anchored below the badge (rect %s)" % report_rect,
		failures,
	)
	for viewport_size: Vector2 in [
		Vector2(1280.0, 720.0),
		Vector2(2560.0, 1600.0),
		Vector2(1440.0, 1000.0),
		Vector2(390.0, 844.0),
	]:
		await _check_responsive_layout(ui, harness, "ProbationReportPanel", viewport_size, failures)
	await _check_report_story_layout(ui, harness, Vector2(1280.0, 720.0), false, failures)
	await _check_report_story_layout(ui, harness, Vector2(390.0, 844.0), true, failures)
	await _check_max_scale_expanded_copy(
		ui,
		harness,
		"ProbationReportPanel",
		["ContinueProbationButton", "AbandonCampaignButton"],
		failures,
	)
	var modal_scroll := ui.find_child("ProbationModalScroll", true, false) as ScrollContainer
	if modal_scroll != null:
		modal_scroll.scroll_vertical = 100000
	await process_frame
	ui.show_between_shift_report()
	await process_frame
	await process_frame
	_check(modal_scroll != null and modal_scroll.scroll_vertical == 0, "opening a report should reset its scroll to the causal summary", failures)
	_check(
		ui.get_viewport().gui_get_focus_owner() == report_panel,
		"report focus should intentionally begin on the report summary before its actions",
		failures,
	)
	harness.size = Vector2(1280.0, 720.0)
	await process_frame

	ui.show_between_shift_report({
		"day": 1,
		"score": 0,
		"rank": "Unranked",
		"score_receipt": {},
		"credit_memo": {},
		"hen_highlight": {},
		"milestone_choices": [],
	})
	await process_frame
	await process_frame
	_check(
		shift_delta != null and shift_delta.text == "--"
		and shift_delta_caption != null and shift_delta_caption.text == "THIS SHIFT"
		and shift_delta_icon != null and not shift_delta_icon.visible
		and String(shift_delta_icon.get_meta("semantic_icon", "")) == "score_pending",
		"missing receipt data should use an explicit unavailable shift score without implying movement",
		failures,
	)
	_check(
		receipt_summary != null and receipt_summary.is_visible_in_tree()
		and receipt_summary.text == "Cumulative results follow you through all five shifts."
		and receipt_grid != null and not receipt_grid.is_visible_in_tree(),
		"missing receipt data should restore the neutral report explanation",
		failures,
	)
	_check(
		story_row != null and not story_row.is_visible_in_tree()
		and credit_memo_card != null and not credit_memo_card.is_visible_in_tree()
		and credit_glance != null and not credit_glance.visible
		and highlight_card != null and not highlight_card.is_visible_in_tree()
		and highlight_glance != null and not highlight_glance.visible,
		"story row should collapse completely when neither attribution nor hen data exists",
		failures,
	)

	ui.show_final_review({
		"day": 5,
		"score": 5120,
		"rank": "Golden Rooster",
		"passed": true,
		"challenge_contract": _challenge_contract("standard_filing"),
		"probation_safeguard_forecast": _safeguard_forecast(true, true),
		"ledgers": [
			{"label": "Eggs Filed", "value": 133},
			{"label": "Feed Fund", "value": 21480, "format": "currency_cents"},
			{"label": "Shell Integrity", "value": 94, "format": "percent"},
		],
	})
	await process_frame
	var final_panel := ui.find_child("FinalProbationReviewPanel", true, false) as PanelContainer
	var verdict := ui.find_child("FinalProbationVerdict", true, false) as Label
	var final_continue := ui.find_child("FinalContinueCampaignButton", true, false) as Button
	var final_rank := ui.find_child("FinalRank", true, false) as Label
	var final_safeguard_panel := ui.find_child("FinalProbationSafeguardReceipt", true, false) as PanelContainer
	var final_safeguard_summary := ui.find_child("FinalProbationSafeguardSummary", true, false) as Label
	var final_safeguard_favor := ui.find_child("FinalProbationSafeguardRow_4", true, false) as Label
	var final_safeguard_grid := ui.find_child("FinalProbationSafeguardGrid", true, false) as GridContainer
	var final_safeguard_card_1 := ui.find_child("FinalProbationSafeguardCard_1", true, false) as PanelContainer
	var final_message := ui.find_child("FinalProbationMessage", true, false) as Label
	var final_sticky_bar := ui.find_child("FinalStickyActionBar", true, false) as PanelContainer
	var final_sticky_primary := ui.find_child("FinalStickyPrimaryButton", true, false) as Button
	_check(final_panel != null and final_panel.is_visible_in_tree(), "day five should show the final campaign review", failures)
	_check(verdict != null and verdict.text == "PROBATION PASSED", "final review should clearly distinguish a pass", failures)
	_check(
		final_continue != null and not final_continue.is_visible_in_tree()
		and final_sticky_bar != null and final_sticky_bar.is_visible_in_tree(),
		"passing desktop review should expose one sticky senior-roost continuation without a duplicate row",
		failures,
	)
	var passed_final_action := ui.final_primary_action_state()
	_check(
		final_sticky_primary != null
		and String(passed_final_action.get("copy", "")) == final_sticky_primary.text
		and String(passed_final_action.get("action_id", "")) == "campaign_final_continue"
		and bool(passed_final_action.get("actionable", false))
		and "optional Senior Roost" in String(passed_final_action.get("accessible_text", ""))
		and ui.focus_final_primary_action()
		and root.gui_get_focus_owner() == final_sticky_primary,
		"passing final review guidance should name and focus the exact visible Senior Roost action",
		failures,
	)
	_check(
		final_safeguard_panel != null and final_safeguard_panel.is_visible_in_tree()
		and final_safeguard_summary != null
		and final_safeguard_summary.text == "STANDARD FILING  //  5 OF 5 PASS"
		and final_safeguard_favor != null
		and final_safeguard_favor.text == "FAVOR\n52 / PASS"
		and final_safeguard_grid != null and final_safeguard_grid.columns == 5
		and final_safeguard_card_1 != null and final_safeguard_card_1.is_visible_in_tree(),
		"passing final review should show five compact safeguard tiles",
		failures,
	)
	_check(
		final_safeguard_panel != null
		and "FINAL RESULT  //  STANDARD FILING  //  5 / 5 SAFEGUARDS  //  ALL SAFEGUARDS PASS" in final_safeguard_panel.tooltip_text
		and final_safeguard_favor != null
		and final_safeguard_favor.tooltip_text == "PASS  //  FARMER FAVOR  //  52 >= 50  //  +2 POINTS"
		and String(final_safeguard_favor.get_meta("accessible_text", "")) == final_safeguard_favor.tooltip_text,
		"compact final safeguards should preserve every exact filing term for pointer and assistive access",
		failures,
	)
	_check(
		final_message != null and not final_message.visible,
		"final authored prose should remain semantic instead of occupying the glance-first layout",
		failures,
	)
	_check(
		final_rank != null
		and final_rank.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
		and final_rank.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING,
		"final rank should preserve the complete management title",
		failures,
	)
	_check(
		final_panel.size.y < 600.0,
		"final review should fit the 720-stage while retaining all five receipt rows (height %.1f)" % final_panel.size.y,
		failures,
	)

	ui.show_final_review({
		"day": 5,
		"score": 50,
		"rank": "Probationary Manager",
		"passed": true,
		"challenge_contract": _challenge_contract("supported_flock"),
		"probation_safeguard_forecast": {},
	})
	await process_frame
	_check(
		final_rank != null and final_rank.text == "QUALIFIED ROOSTER",
		"a passed Supported Flock file should use an outcome-aware final title",
		failures,
	)

	ui.show_final_review({
		"day": 5,
		"score": 900,
		"rank": "Loose Feather",
		"passed": false,
		"challenge_contract": _challenge_contract("standard_filing"),
		"probation_safeguard_forecast": _safeguard_forecast(true, false),
	})
	await process_frame
	_check(verdict.text == "PROBATION FAILED", "final review should clearly distinguish a failure", failures)
	_check(not final_continue.is_visible_in_tree(), "failure should not offer post-probation continuation", failures)
	_check(
		final_safeguard_summary != null
		and final_safeguard_summary.text == "STANDARD FILING  //  4 OF 5 PASS  //  HELD"
		and final_safeguard_favor != null
		and final_safeguard_favor.text == "FAVOR\n49 / HELD"
		and final_safeguard_favor.tooltip_text == "HELD  //  FARMER FAVOR  //  49 >= 50  //  -1 POINT",
		"failed final review should show the held condition at a glance while retaining its exact comparison",
		failures,
	)
	var retry := ui.find_child("FinalNewCampaignButton", true, false) as Button
	_check(retry != null and "RETRY PROBATION" in retry.text, "failure should offer an immediate retry", failures)
	var failed_final_action := ui.final_primary_action_state()
	_check(
		final_sticky_primary != null
		and String(failed_final_action.get("copy", "")) == final_sticky_primary.text
		and String(failed_final_action.get("action_id", "")) == "campaign_final_retry"
		and bool(failed_final_action.get("actionable", false))
		and "protected replacement confirmation" in String(
			failed_final_action.get("accessible_text", "")
		)
		and ui.focus_final_primary_action()
		and root.gui_get_focus_owner() == final_sticky_primary,
		"failed final review guidance should name and focus the exact protected Retry action",
		failures,
	)
	for viewport_size: Vector2 in [
		Vector2(1280.0, 720.0),
		Vector2(2560.0, 1600.0),
		Vector2(1440.0, 1000.0),
		Vector2(390.0, 844.0),
	]:
		await _check_responsive_layout(ui, harness, "FinalProbationReviewPanel", viewport_size, failures)
	await _check_max_scale_expanded_copy(
		ui,
		harness,
		"FinalProbationReviewPanel",
		["FinalNewCampaignButton", "FinalAbandonCampaignButton"],
		failures,
	)
	harness.size = Vector2(1280.0, 720.0)
	await process_frame

	ui.hide_modal()
	await process_frame
	_check(not ui.is_modal_open() and not modal_host.is_visible_in_tree(), "closing campaign cards should restore the unobstructed office", failures)
	_check(
		badge.is_visible_in_tree()
		and day_label.text == "5 / 5"
		and day_label.tooltip_text == "DAY 5 / 5",
		"calendar-led day badge should persist after closing a modal",
		failures,
	)

	ui.show_active_campaign({"status": "Senior Roost", "score": 73})
	await process_frame
	_check(
		status_label.text == "ROOST  73"
		and status_label.tooltip_text == "SENIOR ROOST  73",
		"active badge should expose a fitted long-term status and preserve its full accessible label",
		failures,
	)
	_check(
		day_progress_rail != null and not day_progress_rail.is_visible_in_tree(),
		"Senior calendar badges should not inherit the five-shift probation rail",
		failures,
	)

	ui.set_reduced_motion(false)
	var motion_report := all_pass_report.duplicate(true)
	# The badge exercise immediately above intentionally merges a Senior status
	# into the component snapshot; restore the authored probation identity for
	# this independent report-motion scenario.
	motion_report["status"] = "Probation"
	motion_report.erase("senior_roost")
	var motion_receipt := motion_report.get("score_receipt", {}) as Dictionary
	motion_receipt["score_after"] = int(motion_receipt.get("score_after", 0)) + 1
	motion_report["score_receipt"] = motion_receipt
	ui.show_between_shift_report(motion_report)
	await process_frame
	await process_frame
	var motion_first := ui.find_child("ReportScoreReceiptChip_1", true, false) as PanelContainer
	var motion_last := ui.find_child("ShiftHenEvidenceChip_4", true, false) as PanelContainer
	var motion_grid := ui.find_child("ReportScoreReceiptGrid", true, false) as GridContainer
	_check(
		motion_first != null and motion_last != null and motion_grid != null
		and String(motion_grid.get_meta("reveal_motion", "")) == "staggered"
		and int(motion_first.get_meta("reveal_order", -1)) == 0
		and int(motion_last.get_meta("reveal_order", -1)) == 11
		and motion_last.modulate.a < 0.1
		and shift_delta_panel != null
		and String(shift_delta_panel.get_meta("result_pulse_motion", "")) == "queued"
		and rank_icon != null
		and String(rank_icon.get_meta("promotion_stamp_motion", "")) == "queued",
		"standard motion should stagger the filing sequence without changing report layout",
		failures,
	)
	await create_timer(0.6).timeout
	_check(
		motion_first != null and is_equal_approx(motion_first.modulate.a, 1.0)
		and motion_last != null and is_equal_approx(motion_last.modulate.a, 1.0)
		and String(motion_grid.get_meta("reveal_motion", "")) == "completed"
		and shift_delta_panel != null
		and String(shift_delta_panel.get_meta("result_pulse_motion", "")) == "pulsing"
		and shift_delta_panel.scale.x > 1.005
		and int(observed["report_filing_settled"]) == 1,
		"the shift total should pulse only after every evidence chip lands (first_alpha=%.3f last_alpha=%.3f mode=%s pulse=%s scale=%.3f receipts=%d)" % [
			motion_first.modulate.a if motion_first != null else -1.0,
			motion_last.modulate.a if motion_last != null else -1.0,
			String(motion_grid.get_meta("reveal_motion", "missing")) if motion_grid != null else "missing",
			String(shift_delta_panel.get_meta("result_pulse_motion", "missing")) if shift_delta_panel != null else "missing",
			shift_delta_panel.scale.x if shift_delta_panel != null else -1.0,
			int(observed["report_filing_settled"]),
		],
		failures,
	)
	await create_timer(0.35).timeout
	_check(
		shift_delta_panel != null
		and is_equal_approx(shift_delta_panel.scale.x, 1.0)
		and String(shift_delta_panel.get_meta("result_pulse_motion", "")) == "completed"
		and rank_icon != null
		and String(rank_icon.get_meta("promotion_stamp_motion", "")) == "completed"
		and is_equal_approx(rank_icon.scale.x, 1.0)
		and int(observed["report_filing_settled"]) == 2,
		"the complete evidence-to-total-to-promotion filing should settle in under one second",
		failures,
	)

	ui.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("PROBATION_CAMPAIGN_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PROBATION_CAMPAIGN_UI_TEST_PASSED badge=day/5+score/100+safeguards title=resume-first+staged-new-file+one-primary+compact-five-shift+contract-disclosure report=closing-file-3/3+receipt+hen-file+ledgers+milestone final=pass/fail responsive=story-wrap+4 resilience=title+report+final@390x844+150-percent+expanded-copy signals=5")
	quit(0)


func _count_visible_primary_buttons(panel: Control) -> int:
	if panel == null:
		return 0
	var count := 0
	for node: Node in panel.find_children("*", "Button", true, false):
		var button := node as Button
		if (
			button != null
			and button.is_visible_in_tree()
			and button.theme_type_variation == &"PrimaryButton"
		):
			count += 1
	return count


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _contains_all(text: String, needles: Array[String]) -> bool:
	for needle: String in needles:
		if needle not in text:
			return false
	return true


func _challenge_contract_catalog() -> Array[Dictionary]:
	return [
		_challenge_contract("supported_flock"),
		_challenge_contract("standard_filing"),
		_challenge_contract("executive_audit"),
	]


func _challenge_contract(contract_id: String) -> Dictionary:
	match contract_id:
		"supported_flock":
			return {
				"id": "supported_flock",
				"label": "SUPPORTED FLOCK",
				"short_label": "SUPPORTED",
				"difficulty": "learning",
				"difficulty_label": "LEARNING",
				"difficulty_guidance": "Best for learning the complete management loop with more recovery room.",
				"description": "More room for score, farmer favor, and shell loss while preserving care floors.",
				"route_brief": "OPEN ROUTES  //  CARE, QUALITY & HARVEST",
				"route_guidance": "Use this contract to learn any doctrine while still managing welfare and compliance.",
				"opening_terms": {
					"feed_fund_cents": 6500,
					"quota_target": 14,
					"additional_claim_lanes": [],
					"pressure_label": "RECOVERY CUSHION",
				},
				"criteria": {
					"minimum_score": 45,
					"minimum_welfare": 45,
					"minimum_compliance": 55,
					"minimum_farmer_favor": 45,
					"maximum_crack_rate_basis_points": 3000,
				},
			}
		"executive_audit":
			return {
				"id": "executive_audit",
				"label": "EXECUTIVE AUDIT",
				"short_label": "EXECUTIVE",
				"difficulty": "expert",
				"difficulty_label": "EXPERT",
				"difficulty_guidance": "A demanding replay contract for managers who already understand every safeguard.",
				"description": "A tighter replay contract demanding stronger results in every filing.",
				"route_brief": "EXPERT REPLAY  //  HARVEST ROUTE PROVEN",
				"route_guidance": "Harvest Partnership has a proven specialist route. Care-led files need extra score; quality-led files must deliberately recover welfare and farmer favor.",
				"opening_terms": {
					"feed_fund_cents": 4800,
					"quota_target": 18,
					"additional_claim_lanes": [&"appeals", &"predator_loss"],
					"pressure_label": "AUDIT SURGE",
				},
				"criteria": {
					"minimum_score": 65,
					"minimum_welfare": 48,
					"minimum_compliance": 65,
					"minimum_farmer_favor": 52,
					"maximum_crack_rate_basis_points": 2450,
				},
			}
	return {
		"id": "standard_filing",
		"label": "STANDARD FILING",
		"short_label": "STANDARD",
		"difficulty": "standard",
		"difficulty_label": "STANDARD",
		"difficulty_guidance": "The recommended authored balance for a first complete probation file.",
		"description": "The authored probation contract with the shipped balance.",
		"route_brief": "BALANCED ROUTES  //  CARE, QUALITY & HARVEST",
		"route_guidance": "Every permanent doctrine has a tested route through these terms.",
		"opening_terms": {
			"feed_fund_cents": 5000,
			"quota_target": 16,
			"additional_claim_lanes": [],
			"pressure_label": "AUTHORED BASELINE",
		},
		"criteria": {
			"minimum_score": 60,
			"minimum_welfare": 45,
			"minimum_compliance": 55,
			"minimum_farmer_favor": 50,
			"maximum_crack_rate_basis_points": 2500,
		},
	}


func _safeguard_forecast(is_final: bool, all_passing: bool) -> Dictionary:
	var completed_shifts := 5 if is_final else 2
	var farmer_favor := 52 if all_passing else 49
	var criteria: Array[Dictionary] = [
		_safeguard_row("score", "Probation Score", "probation_score", "minimum", 65, 60, not is_final),
		_safeguard_row("welfare", "Welfare", "average_welfare", "minimum", 50, 45, not is_final),
		_safeguard_row("compliance", "Compliance", "average_compliance", "minimum", 58, 55, not is_final),
		_safeguard_row("farmer_favor", "Farmer Favor", "average_farmer_favor", "minimum", farmer_favor, 50, not is_final),
		_safeguard_row("crack_rate", "Crack Rate", "crack_rate_basis_points", "maximum", 2500, 2500, not is_final),
	]
	var pass_count := 0
	for criterion: Dictionary in criteria:
		if bool(criterion["pass"]):
			pass_count += 1
	return {
		"visible": true,
		"is_final": is_final,
		"completed_shifts": completed_shifts,
		"required_shifts": 5,
		"criteria": criteria,
		"pass_count": pass_count,
		"at_risk_count": criteria.size() - pass_count,
		"criteria_count": criteria.size(),
		"all_pass": pass_count == criteria.size(),
		"largest_recoverable_blocker": (
			criteria[3].duplicate(true)
			if not is_final and not bool(criteria[3]["pass"]) else
			{}
		),
	}


func _safeguard_row(
	id: String,
	label: String,
	metric: String,
	comparison: String,
	value: int,
	target: int,
	recoverable: bool,
) -> Dictionary:
	var signed_gap := value - target if comparison == "minimum" else target - value
	return {
		"id": id,
		"label": label,
		"metric": metric,
		"comparison": comparison,
		"target": target,
		"current_value": value,
		"projected_value": value,
		"pass": signed_gap >= 0,
		"at_risk": signed_gap < 0,
		"signed_gap": signed_gap,
		"distance_to_pass": maxi(0, -signed_gap),
		"recoverable": signed_gap < 0 and recoverable,
	}


func _colors_close(left: Color, right: Color, tolerance: float = 0.002) -> bool:
	return (
		absf(left.r - right.r) <= tolerance
		and absf(left.g - right.g) <= tolerance
		and absf(left.b - right.b) <= tolerance
		and absf(left.a - right.a) <= tolerance
	)


func _check_report_story_layout(
	ui: Control,
	harness: Control,
	viewport_size: Vector2,
	expect_wrapped: bool,
	failures: Array[String],
) -> void:
	harness.size = viewport_size
	await process_frame
	await process_frame
	var credit_card := ui.find_child("FiledCreditMemoCard", true, false) as PanelContainer
	var highlight_card := ui.find_child("ShiftHenHighlightCard", true, false) as PanelContainer
	var market_card := ui.find_child("ReportMarketPulse", true, false) as PanelContainer
	_check(
		credit_card != null and credit_card.is_visible_in_tree()
		and highlight_card != null and highlight_card.is_visible_in_tree()
		and market_card != null and market_card.is_visible_in_tree(),
		"report stories and the next-market pulse should remain visible at %s" % viewport_size,
		failures,
	)
	if credit_card == null or highlight_card == null or market_card == null:
		return
	var credit_rect := credit_card.get_global_rect()
	var highlight_rect := highlight_card.get_global_rect()
	var market_rect := market_card.get_global_rect()
	_check(
		market_rect.position.x >= -0.5
		and market_rect.end.x <= viewport_size.x + 0.5
		and market_rect.size.y >= 36.0,
		"next-market pulse should stay bounded and legible at %s (rect %s)" % [viewport_size, market_rect],
		failures,
	)
	if expect_wrapped:
		_check(
			is_equal_approx(credit_card.custom_minimum_size.x, 260.0)
			and is_equal_approx(highlight_card.custom_minimum_size.x, 260.0),
			"portrait report story cards should use compact 260px minimum widths",
			failures,
		)
		_check(
			highlight_rect.position.y >= credit_rect.end.y - 0.5,
			"portrait report should stack the hen file below the credit memo without overlap",
			failures,
		)
	else:
		_check(
			absf(credit_rect.position.y - highlight_rect.position.y) <= 1.0,
			"desktop report should keep both story cards on one compact row",
			failures,
		)


func _check_responsive_layout(
	ui: Control,
	harness: Control,
	panel_name: String,
	viewport_size: Vector2,
	failures: Array[String],
) -> void:
	harness.size = viewport_size
	await process_frame
	await process_frame
	var panel := ui.find_child(panel_name, true, false) as PanelContainer
	var modal_scroll := ui.find_child("ProbationModalScroll", true, false) as ScrollContainer
	var badge := ui.find_child("ProbationDayBadge", true, false) as PanelContainer
	_check(panel != null and panel.is_visible_in_tree(), "%s should remain visible at %s" % [panel_name, viewport_size], failures)
	if panel != null:
		var panel_rect := panel.get_global_rect()
		_check(
			panel_rect.position.x >= -0.5 and panel_rect.end.x <= viewport_size.x + 0.5,
			"%s should stay horizontally inside %s (rect=%s)" % [panel_name, viewport_size, panel_rect],
			failures,
		)
	if modal_scroll != null:
		var scroll_rect := modal_scroll.get_global_rect()
		_check(
			scroll_rect.position.x >= -0.5 and scroll_rect.end.x <= viewport_size.x + 0.5
			and scroll_rect.position.y >= -0.5 and scroll_rect.end.y <= viewport_size.y + 0.5,
			"modal scroll viewport should remain bounded at %s" % viewport_size,
			failures,
		)
		_check(
			modal_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
			"campaign cards should never require horizontal scrolling at %s" % viewport_size,
			failures,
		)
	if badge != null:
		var badge_rect := badge.get_global_rect()
		_check(
			badge_rect.position.x >= -0.5 and badge_rect.end.x <= viewport_size.x + 0.5,
			"probation badge should stay horizontally visible at %s" % viewport_size,
			failures,
		)


func _check_max_scale_expanded_copy(
	ui: Control,
	harness: Control,
	panel_name: String,
	action_names: Array[String],
	failures: Array[String],
) -> void:
	var prior_theme := ui.theme
	var records: Array[Dictionary] = []
	var nodes: Array[Node] = [ui]
	nodes.append_array(ui.find_children("*", "Control", true, false))
	for node_value: Node in nodes:
		var control := node_value as Control
		if control == null:
			continue
		var record := {
			"control": control,
			"had_font_override": control.has_theme_font_size_override("font_size"),
			"font_size": control.get_theme_font_size("font_size"),
			"kind": &"",
			"text": "",
			"items": [] as Array[String],
		}
		if control is OptionButton:
			var option := control as OptionButton
			var item_texts: Array[String] = []
			for item_index: int in option.item_count:
				item_texts.append(option.get_item_text(item_index))
			record["kind"] = &"option"
			record["items"] = item_texts
		elif control is Button:
			record["kind"] = &"button"
			record["text"] = (control as Button).text
		elif control is Label:
			record["kind"] = &"label"
			record["text"] = (control as Label).text
		records.append(record)

	ui.theme = ManagementUIThemeScript.create_theme(false, 1.5)
	_apply_explicit_font_scale(ui, 1.5)
	_expand_interface_copy(ui)
	harness.size = Vector2(390.0, 844.0)
	await process_frame
	await process_frame

	var bounds := Rect2(Vector2.ZERO, harness.size)
	var panel := ui.find_child(panel_name, true, false) as PanelContainer
	var modal_scroll := ui.find_child("ProbationModalScroll", true, false) as ScrollContainer
	_check(
		panel != null and panel.is_visible_in_tree()
		and _visible_children_fit(panel, bounds),
		"%s should remain inside 390x844 at 150-percent with expanded copy (%s; largest=%s)"
		% [
			panel_name,
			_first_horizontal_overflow(panel, bounds) if panel != null else "panel missing",
			_largest_minimum_widths(panel) if panel != null else "panel missing",
		],
		failures,
	)
	_check(
		modal_scroll != null
		and modal_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED
		and modal_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO,
		"%s should remain vertical-scroll-only at maximum scale" % panel_name,
		failures,
	)
	for action_name: String in action_names:
		var action := ui.find_child(action_name, true, false) as Control
		_check(
			action != null and action.is_visible_in_tree()
			and modal_scroll != null and modal_scroll.is_ancestor_of(action)
			and action.get_global_rect().position.x >= -0.5
			and action.get_global_rect().end.x <= harness.size.x + 0.5,
			"%s action %s should remain physically reachable at maximum scale"
			% [panel_name, action_name],
			failures,
		)

	for record: Dictionary in records:
		var control := record.get("control") as Control
		if control == null or not is_instance_valid(control):
			continue
		match StringName(record.get("kind", &"")):
			&"option":
				var option := control as OptionButton
				var item_texts := record.get("items", []) as Array
				for item_index: int in mini(option.item_count, item_texts.size()):
					option.set_item_text(item_index, String(item_texts[item_index]))
			&"button":
				(control as Button).text = String(record.get("text", ""))
			&"label":
				(control as Label).text = String(record.get("text", ""))
		if bool(record.get("had_font_override", false)):
			control.add_theme_font_size_override("font_size", int(record.get("font_size", 16)))
		else:
			control.remove_theme_font_size_override("font_size")
	ui.theme = prior_theme
	await process_frame
	await process_frame


func _visible_children_fit(root_control: Control, bounds: Rect2) -> bool:
	return _first_horizontal_overflow(root_control, bounds) == "none"


func _first_horizontal_overflow(root_control: Control, bounds: Rect2) -> String:
	for node: Node in root_control.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		if rect.position.x < bounds.position.x - 1.0 or rect.end.x > bounds.end.x + 1.0:
			return "%s=%s bounds=%s" % [control.name, rect, bounds]
	return "none"


func _largest_minimum_widths(root_control: Control) -> String:
	var rows: Array[Dictionary] = []
	for node: Node in root_control.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		rows.append({
			"name": String(control.name),
			"minimum": control.get_combined_minimum_size().x,
			"width": control.size.x,
		})
	rows.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return float(left.get("minimum", 0.0)) > float(right.get("minimum", 0.0))
	)
	var summaries: Array[String] = []
	for index: int in mini(20, rows.size()):
		var row := rows[index]
		summaries.append("%s:min=%.1f/size=%.1f" % [
			String(row.get("name", "")),
			float(row.get("minimum", 0.0)),
			float(row.get("width", 0.0)),
		])
	return ", ".join(summaries)


func _apply_explicit_font_scale(root_control: Control, scale: float) -> void:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
		if control == null or not control.has_theme_font_size_override("font_size"):
			continue
		var base_size := control.get_theme_font_size("font_size")
		control.add_theme_font_size_override(
			"font_size",
			maxi(10, roundi(float(base_size) * scale)),
		)


func _expand_interface_copy(root_control: Control) -> void:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		if node_value is OptionButton:
			var option := node_value as OptionButton
			for item_index: int in option.item_count:
				option.set_item_text(item_index, _expanded(option.get_item_text(item_index)))
		elif node_value is Button:
			var button := node_value as Button
			button.text = _expanded(button.text)
		elif node_value is Label:
			var label := node_value as Label
			label.text = _expanded(label.text)


func _expanded(source: String) -> String:
	var expanded := source
	for vowel: String in ["a", "e", "i", "o", "u", "A", "E", "I", "O", "U"]:
		expanded = expanded.replace(vowel, vowel + vowel)
	return expanded


func _check_title_character_layout(
	title_panel: PanelContainer,
	profile_card: PanelContainer,
	profile_labels: Array,
	new_button: Button,
	viewport_size: Vector2,
	failures: Array[String],
) -> void:
	if title_panel == null or profile_card == null or new_button == null:
		return
	var panel_rect := title_panel.get_global_rect()
	var profile_rect := profile_card.get_global_rect()
	_check(
		profile_rect.position.x >= panel_rect.position.x - 0.5
		and profile_rect.end.x <= panel_rect.end.x + 0.5,
		"Mabel profile should stay inside the title panel at %s" % viewport_size,
		failures,
	)
	for label_value in profile_labels:
		var label := label_value as Label
		if label == null:
			continue
		var label_rect := label.get_global_rect()
		_check(
			label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
			and label_rect.position.x >= profile_rect.position.x - 0.5
			and label_rect.end.x <= profile_rect.end.x + 0.5,
			"%s should wrap inside Mabel's profile at %s" % [label.name, viewport_size],
			failures,
		)
	var button_rect := new_button.get_global_rect()
	_check(
		button_rect.position.x >= panel_rect.position.x - 0.5
		and button_rect.end.x <= panel_rect.end.x + 0.5,
		"Mabel title action should stay inside the panel at %s" % viewport_size,
		failures,
	)
