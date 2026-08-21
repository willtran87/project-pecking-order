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
	var quota_progress := office.find_child("ShiftQuotaProgress", true, false) as ProgressBar
	var review_panel := office.find_child("DayReviewPanel", true, false) as PanelContainer
	var review_glance := office.find_child("FarmerReviewGlanceGrid", true, false) as GridContainer
	var review_summary := office.find_child("FarmerReviewSummary", true, false) as Label
	var review_eggs := office.find_child("FarmerReviewEggsValue", true, false) as Label
	var review_net := office.find_child("FarmerReviewNetValue", true, false) as Label
	var review_fund := office.find_child("FarmerReviewFundValue", true, false) as Label
	var review_next := office.find_child("FarmerReviewNextValue", true, false) as Label
	var review_details_toggle := office.find_child("FarmerReviewDetailsToggle", true, false) as Button
	var review_details_scroll := office.find_child("FarmerReviewAccountingScroll", true, false) as ScrollContainer
	var review_results := office.find_child("FarmerReviewAccountingDetails", true, false) as Label
	var review_continue := office.find_child("BeginNextShiftButton", true, false) as Button
	var decision_host := office.find_child("ManagementDecisionHost", true, false) as Control
	var flockwatch_toggle := office.find_child("FlockwatchToggle", true, false) as Button
	var settings_button := office.find_child("OpenSettingsButton", true, false) as Button
	var day_label := office.get("_day_label") as Label
	var time_label := office.get("_time_label") as Label
	var fund_label := office.get("_revenue_label") as Label
	var clock_status := office.find_child("ShiftClockStatus", true, false) as HBoxContainer
	var clock_status_icon := office.find_child("ShiftClockStatusIcon", true, false) as FlockwatchIconBadge
	var fund_status := office.find_child("FundStatus", true, false) as HBoxContainer
	var fund_status_icon := office.find_child("FundStatusIcon", true, false) as FlockwatchIconBadge
	var shift_goal_status := office.find_child("ShiftEggGoalStatus", true, false) as HBoxContainer
	var shift_goal_icon := office.find_child("ShiftEggGoalIcon", true, false) as FlockwatchIconBadge
	var live_policy_label := office.find_child("LivePolicyLabel", true, false) as Label
	var live_policy_icon := office.find_child("LivePolicyIcon", true, false) as FlockwatchIconBadge
	var guidance := office.get("_guidance_label") as Label
	var guidance_icon := office.find_child("GuidanceIcon", true, false) as FlockwatchIconBadge
	var guidance_action := office.find_child("GuidanceActionButton", true, false) as Button
	var guidance_chevron := office.find_child("GuidanceActionChevron", true, false) as Label
	var core_loop := office.find_child("CoreLoopPulse", true, false) as HBoxContainer
	var reward_loop_host := office.find_child("RewardLoopPulse", true, false) as HBoxContainer
	var active_playbook_button := office.find_child("ActivePlaybookButton", true, false) as MenuButton
	var clutch_carton := office.find_child("ClutchCartonPulse", true, false) as HBoxContainer
	var rival_pulse := office.find_child("RivalPulseLabel", true, false) as Label
	_check(clock != null and clock.speed_index == 0, "first shift should begin paused for its morning directive", failures)
	_check(decision_host != null and decision_host.is_visible_in_tree(), "opening directive should be presented as a blocking decision", failures)
	office.call("_refresh_gameplay_pulse", simulation.snapshot())
	var gameplay_pulse := office.get("_gameplay_pulse") as Dictionary
	_check(
		core_loop != null
		and core_loop.get_child_count() == 4
		and String(core_loop.get_meta("active_stage", "")) == "file"
		and String(core_loop.get_meta("accessible_text", "")).begins_with("Work loop:")
		and rival_pulse != null
		and not rival_pulse.visible
		and gameplay_pulse.has("hen_mastery")
		and gameplay_pulse.has("reward_loop")
		and reward_loop_host != null
		and reward_loop_host.get_child_count() == 4
		and not reward_loop_host.visible
		and active_playbook_button != null
		and not active_playbook_button.visible
		and clutch_carton != null
		and clutch_carton.get_child_count() == 3
		and not clutch_carton.visible
		and not bool(gameplay_pulse.get("authoritative", true)),
		"the objective rail should prepare four reward shapes, a three-egg clutch track, and a hidden progressive playbook before the shift",
		failures,
	)
	var opening_accessibility := String(
		office.call("_web_accessibility_summary", simulation.snapshot())
	)
	var opening_announcement := office.call(
		"_web_accessibility_announcement",
		simulation.snapshot(),
		opening_accessibility,
	) as Dictionary
	_check(
		String(opening_announcement.get("kind", "")) == "management_decision"
		and String(opening_announcement.get("key", "")).begins_with("management_decision:")
		and "PICK TODAY'S FLOCK RULE" in String(opening_announcement.get("text", ""))
		and "Objective: review the response" in String(opening_announcement.get("text", ""))
		and String(opening_announcement.get("text", "")).length() < opening_accessibility.length(),
		"the browser live region should receive the authored morning decision instead of polling noise [summary=%s announcement=%s]" % [opening_accessibility, str(opening_announcement)],
		failures,
	)
	_check(
		shift_goal_status != null
		and String(shift_goal_status.get_meta("semantic_icon", "")) == "egg"
		and shift_goal_icon != null
		and shift_goal_icon.visible
		and shift_goal_icon.icon_kind() == &"egg"
		and live_policy_label != null
		and live_policy_label.text == "BRIEFING"
		and live_policy_icon != null
		and live_policy_icon.visible,
		"the permanent objective rail should begin with stable egg and policy shapes instead of repeated category words [goal=%s goal-visible=%s policy=%s policy-kind=%s policy-visible=%s]" % [
			String(shift_goal_status.get_meta("semantic_icon", "")) if shift_goal_status != null else "missing",
			str(shift_goal_icon.visible) if shift_goal_icon != null else "missing",
			live_policy_label.text if live_policy_label != null else "missing",
			String(live_policy_icon.icon_kind()) if live_policy_icon != null else "missing",
			str(live_policy_icon.visible) if live_policy_icon != null else "missing",
		],
		failures,
	)
	_check(
		guidance != null
		and guidance_icon != null
		and guidance_action != null
		and not guidance_action.disabled
		and StringName(guidance_action.get_meta("guidance_action_id", &"")) == &"decision"
		and guidance.text == "DECIDE: CHOOSE + AUTHORIZE ONE POLICY"
		and guidance.text.length() <= 40
		and "select a policy card" in String(guidance.get_meta("accessible_text", "")).to_lower()
		and guidance.tooltip_text == String(guidance.get_meta("accessible_text", ""))
		and guidance_icon.tooltip_text == guidance.tooltip_text
		and String(guidance_action.get_meta("activation_behavior", "")) == "focus_target"
		and "focus the next safe decision control" in String(
			guidance_action.get_meta("accessible_text", "")
		)
		and "go directly there" not in String(
			guidance_action.get_meta("accessible_text", "")
		).to_lower(),
		"the HUD should expose one compact next action with the exact explanation available semantically",
		failures,
	)
	if guidance_action != null:
		guidance_action.pressed.emit()
	await process_frame
	var guided_focus := root.get_viewport().gui_get_focus_owner()
	_check(
		guided_focus != null and guided_focus.name.begins_with("DecisionOption_"),
		"activating the next-move cue should focus the first safe policy action without authorizing it",
		failures,
	)
	var assurance_option := office.find_child("DecisionOption_shell_assurance", true, false) as Button
	var assurance_chip_row := office.find_child("DecisionEffectChips_shell_assurance", true, false) as HBoxContainer
	var confirm_decision := office.find_child("ConfirmDecisionButton", true, false) as Button
	var decision_body := office.find_child("DecisionBody", true, false) as Label
	var decision_preview := office.find_child("DecisionPreview", true, false) as Label
	var decision_order_glance := office.find_child("DecisionOrderGlance", true, false) as GridContainer
	var opening_order := office.find_child("DecisionOrderValue_0", true, false) as Label
	var quality_order := office.find_child("DecisionOrderValue_1", true, false) as Label
	var welfare_order := office.find_child("DecisionOrderValue_2", true, false) as Label
	_check(assurance_option != null and confirm_decision != null, "directive modal should expose selectable policy cards and authorization", failures)
	_check(
		assurance_chip_row != null
		and assurance_chip_row.get_child_count() == 3
		and office.find_child("DecisionEffectChip_shell_assurance_pace", true, false) != null
		and office.find_child("DecisionEffectChip_shell_assurance_risk", true, false) != null
		and office.find_child("DecisionEffectChip_shell_assurance_compliance", true, false) != null,
		"the Assurance card should preview pace, shell risk, and rules with three icon-led chips",
		failures,
	)
	_check(
		decision_body != null
		and decision_body.text == "Match today's goals, then start the shift."
		and String(decision_body.get_meta("accessible_text", "")).begins_with(
			"Choose one rule for the whole flock."
		)
		and decision_order_glance != null
		and decision_order_glance.is_visible_in_tree()
		and opening_order != null
		and opening_order.text == "18+ EGGS"
		and quality_order != null
		and quality_order.text == "CRACKS <=20%"
		and welfare_order != null
		and welfare_order.text == "WELFARE 48+",
		"morning policy should show three glance-first scored order tiles before authorization",
		failures,
	)
	_check(
		decision_preview != null
		and not decision_preview.is_visible_in_tree()
		and confirm_decision != null
		and confirm_decision.text == "SELECT A RULE ABOVE",
		"morning policy should remove the duplicate lower prompt before selection",
		failures,
	)
	if assurance_option != null and confirm_decision != null:
		assurance_option.pressed.emit()
		_check(not confirm_decision.disabled, "selecting a directive should enable authorization", failures)
		confirm_decision.pressed.emit()
	await process_frame
	_check(not decision_host.is_visible_in_tree(), "authorizing a directive should close the decision modal", failures)
	_check(StringName(simulation.active_directive_snapshot().get("id", &"")) == &"shell_assurance", "authorized directive should become authoritative", failures)
	_check(clock.speed_index == 1, "authorizing the morning directive should start the shift", failures)
	var eggs_before_rival_probe := simulation.eggs_today
	simulation.eggs_today = 1
	office.call("_refresh_gameplay_pulse", simulation.snapshot())
	var live_reward_loop := (office.get("_gameplay_pulse") as Dictionary).get("reward_loop", {}) as Dictionary
	_check(
		rival_pulse.visible
		and rival_pulse.text.begins_with("RIVAL ")
		and "filed cumulative score" in rival_pulse.tooltip_text
		and bool(((office.get("_gameplay_pulse") as Dictionary).get("rival_pulse", {}) as Dictionary).get("hud_visible", false)),
		"the disclosed rival margin should enter the HUD only after the first live delivery",
		failures,
	)
	_check(
		reward_loop_host.visible
		and clutch_carton.visible
		and int(reward_loop_host.get_meta("item_count", 0)) == 15
		and bool(live_reward_loop.get("authoritative", false))
		and active_playbook_button.visible
		and bool(active_playbook_button.get_meta("authoritative", false))
		and active_playbook_button.get_popup().item_count >= 4
		and active_playbook_button.get_popup().item_count <= 7
		and String((live_reward_loop.get("combo_recipe", {}) as Dictionary).get("label", "")) == "SHELL LOCK"
		and String((live_reward_loop.get("strategy_identity", {}) as Dictionary).get("label", "")) == "SHELL GUARDIAN"
		and "SHELL GUARDIAN" in live_policy_label.tooltip_text,
		"a live shift should expose authoritative reward cues through four icons, the clutch track, and one progressive playbook menu",
		failures,
	)
	var playbook_map := office.get("_active_playbook_menu_map") as Dictionary
	var contract_item_id := -1
	for menu_id_value in playbook_map:
		var option := playbook_map[menu_id_value] as Dictionary
		if String(option.get("kind", "")) == "contract" and String(option.get("id", "")) == "clean_pair":
			contract_item_id = int(menu_id_value)
			break
	_check(contract_item_id >= 0, "the playbook menu should retain exact action metadata behind concise labels", failures)
	simulation.eggs_today = eggs_before_rival_probe
	office.call("_refresh_gameplay_pulse", simulation.snapshot())
	var next_moment_button := office.find_child("NextMomentButton", true, false) as Button
	_check(
		next_moment_button != null
		and next_moment_button.text.begins_with("NEXT")
		and "decision" in next_moment_button.tooltip_text.to_lower(),
		"the live clock should offer one concise, explained Next Moment control",
		failures,
	)
	var next_moment_idle := office.call("_next_moment_diagnostic_state") as Dictionary
	_check(
		String(next_moment_idle.get("target_label", "")) == "DECISION / PECK / REVIEW"
		and int(next_moment_idle.get("target_worker_id", -2)) == -1
		and bool(next_moment_idle.get("camera_focus_on_stop", false)),
		"Next Moment should disclose its fallback target and guarantee a camera handoff",
		failures,
	)
	if next_moment_button != null:
		next_moment_button.pressed.emit()
	_check(
		clock.speed_index == 3
		and bool((office.call("_next_moment_diagnostic_state") as Dictionary).get("active", false))
		and next_moment_button.text.begins_with("STOP"),
		"Next Moment should temporarily seek at 10x and expose a reversible stop state",
		failures,
	)
	office.call("_on_speed_button_pressed", 1)
	_check(
		clock.speed_index == 1
		and not bool((office.call("_next_moment_diagnostic_state") as Dictionary).get("active", true)),
		"a direct speed choice should safely reclaim pace ownership from Next Moment",
		failures,
	)
	var reward_ladder := office.call("_clutch_reward_ladder_snapshot", 4) as Dictionary
	_check(
		String(reward_ladder.get("tier_label", "")) == "ROLLING"
		and int(reward_ladder.get("next_threshold", 0)) == 8
		and int(reward_ladder.get("current_bonus_cents", 0)) == 140,
		"the compact clean-clutch ladder should expose exact milestone and reward authority",
		failures,
	)
	_check(
		live_policy_label.text == "ASSURANCE"
		and live_policy_icon.icon_kind() == &"shield"
		and live_policy_icon.is_visible_in_tree()
		and "POLICY" in String(live_policy_label.get_meta("full_text", ""))
		and "SHELL ASSURANCE" in String(live_policy_label.get_meta("accessible_text", "")),
		"the filed policy should read as a shield plus short name while retaining its complete terms",
		failures,
	)
	var pause_toggle := office.find_child("SpeedButton_0", true, false) as Button
	_check(
		pause_toggle != null
		and pause_toggle.text == "PAUSE"
		and StringName(pause_toggle.get_meta("clock_action", &"")) == &"pause"
		and pause_toggle.tooltip_text == "Pause simulation."
		and pause_toggle.accessibility_name == "Pause simulation. Press Space.",
		"the running clock control should communicate the pause action consistently",
		failures,
	)
	var authored_flockwatch_text := flockwatch_toggle.text if flockwatch_toggle != null else ""
	var authored_fund_text := fund_label.text if fund_label != null else ""
	_check(
		clock_status != null
		and bool(clock_status.get_meta("icon_led_status_marks", false))
		and clock_status.get_theme_constant("separation") == 5
		and clock_status_icon != null
		and clock_status_icon.is_visible_in_tree()
		and clock_status_icon.icon_kind() == &"clock"
		and day_label.text == "DAY 1"
		and time_label.text == "8:00 AM"
		and fund_status != null
		and bool(fund_status.get_meta("icon_led_status_marks", false))
		and fund_status_icon != null
		and fund_status_icon.is_visible_in_tree()
		and fund_status_icon.icon_kind() == &"cash"
		and fund_label.text == "$50.00"
		and "FEED FUND" in String(fund_label.get_meta("full_text", ""))
		and "Feed Fund available" in String(fund_status.get_meta("accessible_text", "")),
		"the default HUD should use persistent clock and cash shapes while preserving exact time, fund terminology, and values",
		failures,
	)
	var enlarged_preferences := (office.get("_player_preferences") as Dictionary).duplicate(true)
	enlarged_preferences["ui_scale"] = 1.5
	office.set("_player_preferences", enlarged_preferences)
	office.call("_apply_management_ui_preferences")
	await process_frame
	await process_frame
	_check(
		flockwatch_toggle != null
		and bool(flockwatch_toggle.get_meta("compact_action_mark", false))
		and bool(flockwatch_toggle.get_meta("icon_led_action_mark", false))
		and String(flockwatch_toggle.get_meta("semantic_icon", "")) == "flockwatch_ledger"
		and flockwatch_toggle.icon != null
		and flockwatch_toggle.text == String(flockwatch_toggle.get_meta("compact_text", ""))
		and "FLOCKWATCH" in flockwatch_toggle.text
		and " / " not in flockwatch_toggle.text
		and "Binding:" in flockwatch_toggle.tooltip_text
		and " / " in String(flockwatch_toggle.get_meta("full_text", ""))
		and String(flockwatch_toggle.get_meta("full_text", "")) in String(flockwatch_toggle.get_meta("accessible_text", ""))
		and settings_button != null
		and bool(settings_button.get_meta("icon_led_action_mark", false))
		and String(settings_button.get_meta("semantic_icon", "")) == "settings_cog"
		and settings_button.icon != null
		and settings_button.text == String(settings_button.get_meta("compact_text", ""))
		and flockwatch_toggle.position.x + flockwatch_toggle.size.x <= office.get_viewport().get_visible_rect().size.x - 18.0,
		"150-percent HUD should keep Flockwatch recognizable and actionable without clipping its secondary binding [flock=%s compact=%s icon-led=%s semantic=%s icon=%s full=%s accessible=%s settings=%s settings-icon=%s end=%.1f]" % [
			flockwatch_toggle.text if flockwatch_toggle != null else "missing",
			str(flockwatch_toggle.get_meta("compact_action_mark", false)) if flockwatch_toggle != null else "missing",
			str(flockwatch_toggle.get_meta("icon_led_action_mark", false)) if flockwatch_toggle != null else "missing",
			String(flockwatch_toggle.get_meta("semantic_icon", "")) if flockwatch_toggle != null else "missing",
			str(flockwatch_toggle.icon != null) if flockwatch_toggle != null else "missing",
			String(flockwatch_toggle.get_meta("full_text", "")) if flockwatch_toggle != null else "missing",
			String(flockwatch_toggle.get_meta("accessible_text", "")) if flockwatch_toggle != null else "missing",
			settings_button.text if settings_button != null else "missing",
			str(settings_button.icon != null) if settings_button != null else "missing",
			flockwatch_toggle.position.x + flockwatch_toggle.size.x if flockwatch_toggle != null else -1.0,
		],
		failures,
	)
	_check(
		day_label != null and day_label.text == "DAY 1"
		and time_label != null and time_label.text == "8:00 AM"
		and fund_label != null and fund_label.text == "$50.00"
		and "FEED FUND" in String(fund_label.get_meta("full_text", ""))
		and fund_status != null
		and "Feed Fund available" in String(fund_status.get_meta("accessible_text", ""))
		and clock_status != null and bool(clock_status.get_meta("compact_status_marks", false))
		and clock_status.get_theme_constant("separation") == 5
		and clock_status_icon != null and clock_status_icon.is_visible_in_tree()
		and clock_status_icon.icon_kind() == &"clock"
		and fund_status_icon != null and fund_status_icon.is_visible_in_tree()
		and fund_status_icon.icon_kind() == &"cash"
		and settings_button != null
		and fund_status.get_global_rect().end.x <= settings_button.get_global_rect().position.x - 10.0,
		"150-percent HUD should group exact day, time, and Feed Fund values behind stable clock and cash marks",
		failures,
	)
	enlarged_preferences["ui_scale"] = 1.0
	office.set("_player_preferences", enlarged_preferences)
	office.call("_apply_management_ui_preferences")
	await process_frame
	await process_frame
	_check(
		flockwatch_toggle.text == authored_flockwatch_text
		and bool(flockwatch_toggle.get_meta("compact_action_mark", false))
		and bool(flockwatch_toggle.get_meta("icon_led_action_mark", false))
		and flockwatch_toggle.icon != null
		and settings_button != null
		and settings_button.text == String(settings_button.get_meta("compact_text", ""))
		and bool(settings_button.get_meta("icon_led_action_mark", false))
		and settings_button.icon != null
		and fund_label.text == authored_fund_text
		and bool(clock_status.get_meta("icon_led_status_marks", false))
		and clock_status_icon != null and clock_status_icon.is_visible_in_tree()
		and fund_status_icon != null and fund_status_icon.is_visible_in_tree()
		and shift_goal_icon != null and shift_goal_icon.is_visible_in_tree()
		and live_policy_icon != null and live_policy_icon.is_visible_in_tree()
		and live_policy_label.text == "ASSURANCE",
		"returning to 100 percent should preserve icon-led utility and shift-status semantics",
		failures,
	)
	if pause_toggle != null:
		pause_toggle.pressed.emit()
	await process_frame
	_check(
		clock.speed_index == 0
		and pause_toggle.text == "RESUME"
		and StringName(pause_toggle.get_meta("clock_action", &"")) == &"resume"
		and StringName(pause_toggle.get_meta("pause_owner_id", &"")) == &"player"
		and "Pause owner: Player" in pause_toggle.tooltip_text
		and "Next action: RESUME 1×" in pause_toggle.tooltip_text
		and pause_toggle.accessibility_name == "%s Press Space." % pause_toggle.tooltip_text,
		"a manual pause should expose its owner, safety guarantee, and direct resume action",
		failures,
	)
	var manual_pause_context := office.call("_pause_context_state") as Dictionary
	_check(
		bool(manual_pause_context.get("active", false))
		and String(manual_pause_context.get("owner_id", "")) == "player"
		and String(manual_pause_context.get("next_action", "")) == "RESUME 1×"
		and bool(manual_pause_context.get("speed_button_actionable", false)),
		"manual pause diagnostics should publish the same truthful continuation contract",
		failures,
	)
	if pause_toggle != null:
		pause_toggle.pressed.emit()
	await process_frame
	_check(
		clock.speed_index == 1 and pause_toggle.text == "PAUSE",
		"pressing the paused clock control should resume normal 1× simulation speed",
		failures,
	)
	var outcome_receipt := office.get("_latest_action_outcome_receipt") as Dictionary
	var outcome_ids: Array[StringName] = []
	var outcome_copy: Array[String] = []
	for entry_value in outcome_receipt.get("entries", []):
		outcome_ids.append(StringName((entry_value as Dictionary).get("id", &"")))
		outcome_copy.append(String((entry_value as Dictionary).get("copy", "")))
	_check(
		bool(outcome_receipt.get("visible", false))
		and &"pace" in outcome_ids
		and &"risk" in outcome_ids
		and &"compliance" in outcome_ids
		and outcome_copy == ["PACE -7%", "RISK -5%", "RULES +3"]
		and not office.find_children("ActionOutcomeReceipt_*", "PanelContainer", true, false).is_empty(),
		"authorizing a policy should immediately show authoritative production, shell-risk, and compliance consequence receipts [receipt=%s nodes=%d]" % [
			str(outcome_receipt),
			office.find_children("ActionOutcomeReceipt_*", "PanelContainer", true, false).size(),
		],
		failures,
	)
	var save_before_receipt_handoff := simulation.export_save_state()
	var audio_feedback = office.get("_audio_feedback")
	var audio_serial_before_handoff := int(audio_feedback.feedback_snapshot().get(
		"cue_serial",
		-1,
	))
	office.call("_set_flockwatch_open", true)
	await process_frame
	await process_frame
	var archived_outcome_receipt := office.get("_latest_action_outcome_receipt") as Dictionary
	_check(
		not bool(archived_outcome_receipt.get("visible", true))
		and String(archived_outcome_receipt.get("dismissed_by", "")) == "flockwatch"
		and int(archived_outcome_receipt.get("retired_panel_count", -1)) == 3
		and (archived_outcome_receipt.get("entries", []) as Array).size() == 3
		and office.find_children("ActionOutcomeReceipt_*", "PanelContainer", true, false).is_empty(),
		"opening the ledger should archive the semantic result and retire every overlapping transient card",
		failures,
	)
	_check(
		simulation.export_save_state() == save_before_receipt_handoff
		and int(audio_feedback.feedback_snapshot().get("cue_serial", -2)) == audio_serial_before_handoff,
		"the receipt-to-ledger handoff should remain save-neutral and silent",
		failures,
	)
	office.call("_set_flockwatch_open", false)
	await process_frame
	var money_before := simulation.snapshot()
	var money_after := money_before.duplicate(true)
	money_after["revenue_cents"] = int(money_before.get("revenue_cents", 0)) - 700
	var money_entries := office.call(
		"_decision_consequence_entries",
		money_before,
		money_after,
	) as Array
	_check(
		not money_entries.is_empty()
		and StringName((money_entries[0] as Dictionary).get("id", &"")) == &"fund"
		and String((money_entries[0] as Dictionary).get("copy", "")) == "FUND -$7.00",
		"a funded choice should map its exact Feed Fund delta to the money receipt family",
		failures,
	)
	clock.set_speed(0)
	await process_frame
	var ticker_panel := office.get("_ticker_panel") as PanelContainer
	var status_history := office.get("_status_history") as Array[String]
	_check(
		guidance != null
		and guidance_action != null
		and guidance.text == "GOALS"
		and "NEXT:" not in guidance.text
		and guidance.text.length() <= 40
		and guidance_icon != null
		and guidance_icon.icon_kind() == &"clipboard"
		and String(guidance_icon.get_meta("semantic_icon", "")) == "clipboard"
		and guidance_chevron != null
		and guidance.get_global_rect().size.x >= 40.0
		and guidance_chevron.get_global_rect().position.x - guidance.get_global_rect().end.x <= 12.0
		and StringName(guidance_action.get_meta("guidance_action_id", &"")) == &"today"
		and "open today's goals" in String(guidance.get_meta("accessible_text", "")).to_lower(),
		"pausing should group the icon, destination, and chevron without narrating or visually disconnecting its affordance [copy=%s icon=%s meta=%s]" % [
			guidance.text if guidance != null else "missing",
			String(guidance_icon.icon_kind()) if guidance_icon != null else "missing",
			String(guidance_icon.get_meta("semantic_icon", "")) if guidance_icon != null else "missing",
		],
		failures,
	)
	_check(
		ticker_panel != null
		and not ticker_panel.visible
		and not status_history.is_empty()
		and "SHIFT PAUSED" in status_history[0],
		"the always-visible pause controls should suppress the duplicate floor toast while preserving its Shift Record entry",
		failures,
	)
	var paused_accessibility := String(
		office.call("_web_accessibility_summary", simulation.snapshot())
	)
	_check(
		"While paused, open today's goals to choose the most useful intervention." in paused_accessibility,
		"assistive narration should retain the exact next-move explanation hidden from the compact HUD",
		failures,
	)
	if guidance_action != null:
		guidance_action.pressed.emit()
	await process_frame
	var flockwatch_panel := office.find_child("FlockwatchLedger", true, false) as PanelContainer
	var flockwatch_navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	var latest_feedback := office.find_child("FlockwatchLatestFeedbackCopy", true, false) as Label
	_check(
		flockwatch_panel != null
		and flockwatch_panel.is_visible_in_tree()
		and flockwatch_navigation != null
		and flockwatch_navigation.current_page_id() == FlockwatchNavigation.PAGE_TODAY,
		"activating the paused next-move cue should open Today's Goals directly",
		failures,
	)
	var flockwatch_accessibility := String(
		office.call("_web_accessibility_summary", simulation.snapshot())
	)
	var flockwatch_announcement := office.call(
		"_web_accessibility_announcement",
		simulation.snapshot(),
		flockwatch_accessibility,
	) as Dictionary
	_check(
		String(flockwatch_announcement.get("kind", "")) == "flockwatch"
		and String(flockwatch_announcement.get("key", "")).begins_with("flockwatch:")
		and "Objective: review the open filing" in String(flockwatch_announcement.get("text", "")),
		"opening Flockwatch should create one bounded management-surface announcement",
		failures,
	)
	_check(
		latest_feedback != null
		and latest_feedback.text == "LATEST  ·  PAUSED  ·  PLAYER  ·  RESUME 1×"
		and "Pause owner: Player" in latest_feedback.tooltip_text
		and "Next action: RESUME 1×" in latest_feedback.tooltip_text,
		"Today's archive glance should name the pause owner and exact continuation without repeating dense prose",
		failures,
	)
	office.call("_set_flockwatch_open", false)
	await process_frame
	var campaign_objectives := office.find_child("CampaignObjectivesLabel", true, false) as Label
	var badge_order_progress := office.find_child("ProbationOrderProgressLabel", true, false) as Label
	var badge_promotion_icon := office.find_child("ProbationOrderPromotionIcon", true, false) as TextureRect
	var badge_order_stamps: Array[PanelContainer] = []
	for index in range(3):
		var stamp := office.find_child(
			"ProbationOrderStamp%d" % (index + 1),
			true,
			false,
		) as PanelContainer
		if stamp != null:
			badge_order_stamps.append(stamp)
	_check(
		campaign_objectives != null
		and badge_order_progress != null
		and badge_order_progress.is_visible_in_tree()
		and badge_order_progress.text == "%d / %d" % [
			int(campaign_objectives.get_meta("orders_on_track", -1)),
			int(campaign_objectives.get_meta("orders_total", -1)),
		],
		"the always-visible badge should mirror the same authoritative live orders as Flockwatch",
		failures,
	)
	var semantic_on_track := 0
	var semantic_marks_valid := badge_order_stamps.size() == 3
	for index in range(badge_order_stamps.size()):
		var stamp := badge_order_stamps[index]
		if index >= int(campaign_objectives.get_meta("orders_total", 0)):
			continue
		semantic_marks_valid = (
			semantic_marks_valid
			and not String(stamp.get_meta("objective_id", "")).is_empty()
			and not String(stamp.get_meta("metric", "")).is_empty()
			and String(stamp.get_meta("semantic_icon", "goal")) in [
				"egg", "flock", "cash", "shield", "files",
				"order_clutch", "order_favor", "order_compliance", "order_trays",
			]
			and String(stamp.get_meta("status_icon", "")) in ["status_pass", "status_need"]
			and String(stamp.get_meta("state_shape", "")) in ["ring_check", "diamond_exclamation"]
			and "//" in String(stamp.get_meta("accessible_text", ""))
		)
		if bool(stamp.get_meta("on_track", false)):
			semantic_on_track += 1
	_check(
		semantic_marks_valid
		and semantic_on_track == int(campaign_objectives.get_meta("orders_on_track", -1)),
		"the compact marks should retain each authored objective identity, icon, status, and exact detail",
		failures,
	)
	var first_order_action := office.find_child(
		"ProbationOrderStampAction1",
		true,
		false,
	) as Button
	var first_order_glance := office.find_child(
		"CampaignOrderGlance1",
		true,
		false,
	) as Label
	var second_order_glance := office.find_child(
		"CampaignOrderGlance2",
		true,
		false,
	) as Label
	var cause_save_before := simulation.export_save_state()
	var cause_audio_before := int(audio_feedback.feedback_snapshot().get("cue_serial", -1))
	var cause_before := simulation.snapshot()
	var cause_after := cause_before.duplicate(true)
	cause_after["eggs_today"] = int(cause_before.get("eggs_today", 0)) + 1
	var cause_count := int(office.call(
		"_record_campaign_order_cause_receipts",
		cause_before,
		cause_after,
		"MABEL/NEST",
		&"route_test",
		"SOUND",
		{
			"source_kind": "worker_file",
			"source_label": "MABEL",
			"worker_id": 0,
			"claim_id": 1,
		},
	))
	var cause_state := (
		office.call("_flockwatch_diagnostic_state") as Dictionary
	).get("campaign_order_causes", {}) as Dictionary
	var first_cause := (
		first_order_glance.get_meta("cause_receipt", {}) as Dictionary
		if first_order_glance != null else
		{}
	)
	var second_cause := (
		second_order_glance.get_meta("cause_receipt", {}) as Dictionary
		if second_order_glance != null else
		{}
	)
	_check(
		cause_count == 2
		and int(cause_state.get("serial", 0)) == 2
		and int(cause_state.get("count", 0)) == 2
		and first_order_glance != null
		and first_order_glance.max_lines_visible == 3
		and first_order_glance.custom_minimum_size.y == 52.0
		and "+1 · MABEL" in first_order_glance.text
		and "↗" in first_order_glance.text
		and "LATEST CAUSE" in first_order_glance.tooltip_text
		and "ACTIVATE AGAIN" in first_order_glance.tooltip_text
		and bool(first_order_glance.get_meta("cause_source_available", false))
		and String(first_cause.get("cause_kind", "")) == "route_test"
		and second_order_glance != null
		and "✓ MABEL/NEST" in second_order_glance.text
		and String(second_cause.get("metric", "")) == "crack_rate_basis_points",
		"a real goal delta should stamp only its exact tiles with one compact cause line and full semantic receipt",
		failures,
	)
	_check(
		simulation.export_save_state() == cause_save_before
		and int(audio_feedback.feedback_snapshot().get("cue_serial", -2)) == cause_audio_before,
		"goal cause receipts should remain presentation-only and silent",
		failures,
	)
	var requested_objective_id := StringName(
		first_order_action.get_meta("objective_id", &"") if first_order_action != null else &""
	)
	if first_order_action != null:
		first_order_action.pressed.emit()
	await process_frame
	await process_frame
	# Reproduce the ordinary pointer-focus path after an intentionally stale HUD.
	# A paused shift will not emit another simulation snapshot to repair it.
	office.call("_set_guidance", "STALE GOAL GUIDANCE")
	if first_order_glance != null:
		office.call("_on_campaign_order_glance_focus_changed", first_order_glance, true)
	await process_frame
	var focused_control := office.get_viewport().gui_get_focus_owner()
	var focused_order_state := office.call("_flockwatch_diagnostic_state") as Dictionary
	var order_driver_button := office.find_child(
		"CampaignOrderDriverAction",
		true,
		false,
	) as Button
	var order_driver_state := focused_order_state.get("campaign_order_driver", {}) as Dictionary
	var driver_next_action := office.call("_next_action_diagnostic_state") as Dictionary
	var focused_order_tile := office.call(
		"_flockwatch_glance_tile",
		first_order_glance,
	) as Control
	_check(
		first_order_action != null
		and requested_objective_id != &""
		and bool(office.get("_flockwatch_open"))
		and flockwatch_navigation.current_page_id() == FlockwatchNavigation.PAGE_TODAY
		and first_order_glance != null
		and StringName(first_order_glance.get_meta("objective_id", &"")) == requested_objective_id
		and focused_control == first_order_glance
		and focused_order_tile != null
		and bool(focused_order_tile.get_meta("direct_focus", false))
		and StringName(focused_order_state.get("focused_campaign_order_id", &"")) == requested_objective_id
		and int(focused_order_state.get("campaign_order_focus_serial", 0)) > 0,
		"activating a live mark should open Today and focus its exact Flockwatch goal tile",
		failures,
	)
	_check(
		order_driver_button != null
		and order_driver_button.is_visible_in_tree()
		and order_driver_button.focus_mode == Control.FOCUS_ALL
		and StringName(order_driver_button.get_meta("objective_id", &"")) == requested_objective_id
		and String(order_driver_button.get_meta("driver_action_id", "")) == "hen_routes"
		and String(order_driver_state.get("objective_id", "")) == String(requested_objective_id)
		and String(order_driver_state.get("action_id", "")) == "hen_routes"
		and "SHOW HEN ROUTES" in String(order_driver_state.get("label", ""))
		and "No choice is filed automatically" in order_driver_button.tooltip_text
		and guidance_action != null
		and not guidance_action.disabled
		and StringName(guidance_action.get_meta("guidance_action_id", &"")) == &"campaign_order_driver"
		and String(driver_next_action.get("activation_behavior", "")) == "navigate"
		and "no choice is filed automatically" in String(
			driver_next_action.get("accessible_text", "")
		).to_lower(),
		"the focused goal should disclose one compact, non-authoritative driver handoff",
		failures,
	)
	var routing_ui := office.get("_routing_ui") as PeckworkRoutingUI
	var driver_save_before := simulation.export_save_state()
	if routing_ui != null:
		routing_ui.set_focus(0)
		routing_ui.call("_on_dossier_tab_pressed", &"claim")
	if guidance_action != null:
		guidance_action.pressed.emit()
	await process_frame
	await process_frame
	var traced_order_state := office.call("_flockwatch_diagnostic_state") as Dictionary
	var traced_driver := traced_order_state.get("campaign_order_driver", {}) as Dictionary
	var traced_result := traced_driver.get("last_result", {}) as Dictionary
	var driver_hen_arrival := traced_driver.get("hen_dossier_arrival", {}) as Dictionary
	var return_cue := traced_order_state.get("campaign_order_return", {}) as Dictionary
	var appeals_fit_button := office.find_child("Assign_appeals", true, false) as Button
	var camera_controller := office.get("_camera_controller") as ManagementCameraController
	_check(
		not bool(office.get("_flockwatch_open"))
		and int(traced_driver.get("activation_serial", 0)) == 1
		and String(traced_result.get("objective_id", "")) == String(requested_objective_id)
		and String(traced_result.get("action_id", "")) == "hen_routes"
		and String(traced_result.get("target", "")) == "DossierTab_route"
		and bool(traced_result.get("target_available", false))
		and not bool(traced_result.get("filed_choice", true))
		and routing_ui != null
		and routing_ui.active_dossier_tab() == &"route"
		and bool(driver_hen_arrival.get("active", false))
		and int(driver_hen_arrival.get("worker_id", -1)) == 0
		and int(driver_hen_arrival.get("serial", 0)) == 1
		and camera_controller != null
		and camera_controller.is_focused()
		and simulation.export_save_state() == driver_save_before,
		"tracing a quota driver should reveal the hen's Route dossier without preserving stale sub-context or filing gameplay",
		failures,
	)
	_check(
		appeals_fit_button != null
		and appeals_fit_button.text.contains("APPEALS")
		and appeals_fit_button.text.ends_with("FIT")
		and bool(appeals_fit_button.get_meta("specialty_match", false))
		and "SPECIALTY FIT" in appeals_fit_button.tooltip_text,
		"the revealed route grid should mark Mabel's credentialed Appeals lane at a glance",
		failures,
	)
	_check(
		bool(return_cue.get("visible", false))
		and int(return_cue.get("serial", 0)) == 1
		and String(return_cue.get("objective_id", "")) == String(requested_objective_id)
		and String(return_cue.get("copy", "")).begins_with("RETURN: ")
		and String(return_cue.get("driver_action_id", "")) == "hen_routes"
		and guidance != null
		and guidance.text == "ROUTE MABEL  >  APPEALS FIT / AUTO"
		and guidance_action != null
		and guidance_action.disabled
		and StringName(guidance_action.get_meta("guidance_action_id", &"")) == &""
		and flockwatch_toggle != null
		and flockwatch_toggle.text.begins_with("RETURN")
		and "RETURN TO GOAL" in String(flockwatch_toggle.get_meta("full_text", ""))
		and "no route is filed" in guidance.tooltip_text.to_lower(),
		"a route driver should prioritize the visible route choice and move exact return to Flockwatch",
		failures,
	)
	if appeals_fit_button != null:
		appeals_fit_button.pressed.emit()
	await process_frame
	await process_frame
	var routed_worker := office.call("_worker_record", simulation.snapshot(), 0) as Dictionary
	var routed_lifecycle := routing_ui.routing_lifecycle_state() if routing_ui != null else {}
	var resume_button := office.find_child("SpeedButton_0", true, false) as Button
	_check(
		StringName(routed_worker.get("assigned_lane", &"")) == &"appeals"
		and String(routed_lifecycle.get("header_copy", "")) == "1  APPEALS  ·  WAITING"
		and StringName(routed_lifecycle.get("header_role", &"")) == &"route_status"
		and "waiting for the next APPEALS file" in String(
			routed_lifecycle.get("header_accessible_text", "")
		),
		"filing the Appeals route should replace the clipped waiting header with one complete route status",
		failures,
	)
	_check(
		guidance != null
		and guidance.text == "APPEALS SET  >  RESUME 1×"
		and guidance_action != null
		and not guidance_action.disabled
		and StringName(guidance_action.get_meta("guidance_action_id", &"")) == &"resume_shift"
		and String(guidance_action.get_meta("activation_behavior", "")) == "focus_target"
		and "focus Resume; activate Resume to start 1×" in String(
			guidance_action.get_meta("accessible_text", "")
		)
		and "Current files finish before the new tray applies" in guidance.tooltip_text
		and "Undo restores the prior route" in guidance.tooltip_text,
		"a filed route should acknowledge the completed decision and advance global guidance to Resume",
		failures,
	)
	if guidance_action != null:
		guidance_action.pressed.emit()
	await process_frame
	_check(
		resume_button != null and root.gui_get_focus_owner() == resume_button,
		"activating completed-route guidance should focus the visible Resume control without starting time implicitly",
		failures,
	)
	if flockwatch_toggle != null:
		flockwatch_toggle.pressed.emit()
	await process_frame
	await process_frame
	await process_frame
	var returned_order_state := office.call("_flockwatch_diagnostic_state") as Dictionary
	var returned_cue := returned_order_state.get("campaign_order_return", {}) as Dictionary
	var returned_result := returned_cue.get("last_result", {}) as Dictionary
	_check(
		bool(office.get("_flockwatch_open"))
		and flockwatch_navigation.current_page_id() == FlockwatchNavigation.PAGE_TODAY
		and office.get_viewport().gui_get_focus_owner() == first_order_glance
		and not bool(returned_cue.get("visible", true))
		and int(returned_cue.get("activation_serial", 0)) == 1
		and String(returned_result.get("objective_id", "")) == String(requested_objective_id)
		and bool(returned_result.get("target_available", false))
		and not bool(returned_result.get("filed_choice", true)),
		"activating the return cue should restore the exact goal and consume the cue without filing a choice",
		failures,
	)
	var original_driver_metric := StringName(first_order_glance.get_meta("metric", &""))
	first_order_glance.set_meta("metric", &"average_welfare")
	office.call("_configure_campaign_order_driver_action", first_order_glance)
	flockwatch_navigation.open_page(FlockwatchNavigation.PAGE_FLOCK)
	await process_frame
	var flock_page_scroll := flockwatch_navigation.page_scroll(
		FlockwatchNavigation.PAGE_FLOCK,
	)
	if flock_page_scroll != null:
		flock_page_scroll.scroll_vertical = 100000
	await process_frame
	flockwatch_navigation.open_page(FlockwatchNavigation.PAGE_TODAY)
	var care_driver_save_before := simulation.export_save_state()
	if order_driver_button != null:
		order_driver_button.pressed.emit()
	await process_frame
	await process_frame
	var care_driver_state := office.call("_flockwatch_diagnostic_state") as Dictionary
	var care_driver := care_driver_state.get("campaign_order_driver", {}) as Dictionary
	var care_result := care_driver.get("last_result", {}) as Dictionary
	var care_page_arrival := care_driver.get("page_arrival", {}) as Dictionary
	var care_section := office.find_child("FlockCareSection", true, false) as Control
	var care_target_offset := (
		care_section.global_position.y - flock_page_scroll.global_position.y
		if care_section != null and flock_page_scroll != null else
		9999.0
	)
	_check(
		bool(office.get("_flockwatch_open"))
		and flockwatch_navigation.current_page_id() == FlockwatchNavigation.PAGE_FLOCK
		and String(care_result.get("action_id", "")) == "flock_care"
		and String(care_result.get("target", "")) == "FlockCareSection"
		and bool(care_result.get("target_available", false))
		and care_section != null
		and care_section.is_visible_in_tree()
		and care_target_offset >= 0.0
		and care_target_offset <= 20.0
		and bool(care_page_arrival.get("active", false))
		and bool(care_page_arrival.get("animated", false))
		and not bool(care_page_arrival.get("reduced_motion", true))
		and int(care_page_arrival.get("serial", 0)) == 1
		and String(care_page_arrival.get("page", "")) == "flock"
		and String(care_page_arrival.get("target", "")) == "FlockCareSection"
		and care_section.modulate != Color.WHITE
		and not bool(care_result.get("filed_choice", true))
		and simulation.export_save_state() == care_driver_save_before,
		"a Flock Care goal driver should clear stale page scroll and land at the exact care filing",
		failures,
	)
	office.call("_activate_campaign_order_return_cue")
	await process_frame
	await process_frame
	var cleared_page_arrival := (
		(office.call("_flockwatch_diagnostic_state") as Dictionary).get(
			"campaign_order_driver",
			{},
		) as Dictionary
	).get("page_arrival", {}) as Dictionary
	_check(
		not bool(cleared_page_arrival.get("active", true))
		and care_section.modulate == Color.WHITE,
		"returning from an exact page handoff should clear its transient arrival tint",
		failures,
	)
	var reduced_preferences := (
		office.get("_player_preferences") as Dictionary
	).duplicate(true)
	var original_motion_mode := String(reduced_preferences.get("motion_mode", "system"))
	reduced_preferences["motion_mode"] = "reduced"
	office.set("_player_preferences", reduced_preferences)
	var reduced_arrival_save_before := simulation.export_save_state()
	var reduced_target := office.call(
		"_open_campaign_order_driver_page",
		FlockwatchNavigation.PAGE_FLOCK,
		PackedStringArray(["FlockCareSection"]),
	) as Control
	await process_frame
	var reduced_page_arrival := (
		(office.call("_flockwatch_diagnostic_state") as Dictionary).get(
			"campaign_order_driver",
			{},
		) as Dictionary
	).get("page_arrival", {}) as Dictionary
	_check(
		reduced_target == care_section
		and bool(reduced_page_arrival.get("active", false))
		and not bool(reduced_page_arrival.get("animated", true))
		and bool(reduced_page_arrival.get("reduced_motion", false))
		and int(reduced_page_arrival.get("serial", 0)) == 2
		and care_section.modulate == Color("fff0bd")
		and simulation.export_save_state() == reduced_arrival_save_before,
		"reduced motion should retain a static exact-section acknowledgment without filing gameplay",
		failures,
	)
	await create_timer(0.7).timeout
	var settled_reduced_arrival := (
		(office.call("_flockwatch_diagnostic_state") as Dictionary).get(
			"campaign_order_driver",
			{},
		) as Dictionary
	).get("page_arrival", {}) as Dictionary
	_check(
		not bool(settled_reduced_arrival.get("active", true))
		and care_section.modulate == Color.WHITE,
		"the reduced-motion acknowledgment should settle cleanly without animation",
		failures,
	)
	reduced_preferences["motion_mode"] = original_motion_mode
	office.set("_player_preferences", reduced_preferences)
	flockwatch_navigation.open_page(FlockwatchNavigation.PAGE_TODAY)
	office.call("_reset_first_clutch", false)
	office.call("_refresh_first_clutch_ui", simulation.snapshot())
	await process_frame
	if routing_ui != null and routing_ui.dispatch_priority_state().is_empty():
		var live_files_queue := simulation._claim_queues.get(&"nest_damage", []) as Array
		live_files_queue.append(ClaimState.new(
			99001,
			&"nest_damage",
			"NEST DAMAGE",
			1.15,
			760,
			0.045,
			1080,
			1440,
			360,
		))
		simulation._claim_queues[&"nest_damage"] = live_files_queue
		simulation.call("_sync_claims_waiting")
		office.call("_on_snapshot_changed", simulation.snapshot())
		await process_frame
	first_order_glance.set_meta("metric", &"rework")
	office.call("_configure_campaign_order_driver_action", first_order_glance)
	var live_files_state_before := office.call("_flockwatch_diagnostic_state") as Dictionary
	var live_files_driver_before := (
		live_files_state_before.get("campaign_order_driver", {}) as Dictionary
	)
	var live_files_arrival_before := (
		live_files_driver_before.get("dispatch_tray_arrival", {}) as Dictionary
	)
	var live_files_save_before := simulation.export_save_state()
	if order_driver_button != null:
		order_driver_button.pressed.emit()
	await process_frame
	await process_frame
	var live_files_state := office.call("_flockwatch_diagnostic_state") as Dictionary
	var live_files_driver := live_files_state.get("campaign_order_driver", {}) as Dictionary
	var live_files_result := live_files_driver.get("last_result", {}) as Dictionary
	var live_files_arrival := (
		live_files_driver.get("dispatch_tray_arrival", {}) as Dictionary
	)
	var live_files_target_name := String(live_files_result.get("target", ""))
	var live_files_target := (
		office.find_child(live_files_target_name, true, false) as Control
		if not live_files_target_name.is_empty() else
		null
	)
	_check(
		not bool(office.get("_flockwatch_open"))
		and String(live_files_result.get("action_id", "")) == "file_trays"
		and bool(live_files_result.get("target_available", false))
		and bool(live_files_result.get("live_file_available", false))
		and not bool(live_files_result.get("filed_choice", true))
		and bool(live_files_arrival.get("active", false))
		and bool(live_files_arrival.get("animated", false))
		and not bool(live_files_arrival.get("reduced_motion", true))
		and String(live_files_arrival.get("lane", "")) != ""
		and String(live_files_arrival.get("target", "")) == String(live_files_result.get("target", ""))
		and int(live_files_arrival.get("serial", 0)) == int(live_files_arrival_before.get("serial", 0)) + 1
		and int(live_files_driver.get("activation_serial", 0)) == int(live_files_driver_before.get("activation_serial", 0)) + 1
		and live_files_target != null
		and live_files_target.modulate != Color.WHITE
		and simulation.export_save_state() == live_files_save_before,
		"a Live Files goal driver should acknowledge the exact urgent tray without arming or filing gameplay",
		failures,
	)
	office.call("_activate_campaign_order_return_cue")
	await process_frame
	await process_frame
	var returned_live_files_arrival := (
		(
			office.call("_flockwatch_diagnostic_state") as Dictionary
		).get("campaign_order_driver", {}) as Dictionary
	).get("dispatch_tray_arrival", {}) as Dictionary
	_check(
		bool(office.get("_flockwatch_open"))
		and not bool(returned_live_files_arrival.get("active", true))
		and live_files_target != null
		and live_files_target.modulate == Color.WHITE
		and simulation.export_save_state() == live_files_save_before,
		"returning from Live Files should clear its tray acknowledgment and restore the source goal",
		failures,
	)
	var today_scroll := flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_TODAY)
	if today_scroll != null:
		today_scroll.scroll_vertical = 100000
	await process_frame
	first_order_glance.set_meta("metric", &"average_farmer_favor")
	office.call("_configure_campaign_order_driver_action", first_order_glance)
	var farmer_driver_before := (
		(office.call("_flockwatch_diagnostic_state") as Dictionary).get(
			"campaign_order_driver",
			{},
		) as Dictionary
	)
	var farmer_arrival_before := farmer_driver_before.get("page_arrival", {}) as Dictionary
	var farmer_save_before := simulation.export_save_state()
	var standing_tile := office.find_child(
		"FlockwatchTodayCashGlanceTile",
		true,
		false,
	) as Control
	var standing_style_before := (
		standing_tile.get_theme_stylebox("panel")
		if standing_tile is PanelContainer else
		null
	)
	if order_driver_button != null:
		order_driver_button.pressed.emit()
	await process_frame
	await process_frame
	var farmer_state := office.call("_flockwatch_diagnostic_state") as Dictionary
	var farmer_driver := farmer_state.get("campaign_order_driver", {}) as Dictionary
	var farmer_result := farmer_driver.get("last_result", {}) as Dictionary
	var farmer_arrival := farmer_driver.get("page_arrival", {}) as Dictionary
	var standing_offset := (
		standing_tile.global_position.y - today_scroll.global_position.y
		if standing_tile != null and today_scroll != null else
		9999.0
	)
	_check(
		bool(office.get("_flockwatch_open"))
		and flockwatch_navigation.current_page_id() == FlockwatchNavigation.PAGE_TODAY
		and String(farmer_driver.get("label", "")) == "SHOW FARMER STANDING"
		and String(farmer_result.get("action_id", "")) == "farmer_standing"
		and String(farmer_result.get("target", "")) == "FlockwatchTodayCashGlanceTile"
		and bool(farmer_result.get("target_available", false))
		and not bool(farmer_result.get("filed_choice", true))
		and standing_tile != null
		and today_scroll != null
		and standing_tile.is_visible_in_tree()
		and standing_offset >= 0.0
		and standing_offset + standing_tile.size.y <= today_scroll.size.y
		and bool(farmer_arrival.get("active", false))
		and bool(farmer_arrival.get("animated", false))
		and String(farmer_arrival.get("page", "")) == "today"
		and String(farmer_arrival.get("target", "")) == "FlockwatchTodayCashGlanceTile"
		and int(farmer_arrival.get("serial", 0)) == int(
			farmer_arrival_before.get("serial", 0)
		) + 1
		and standing_tile.modulate != Color.WHITE
		and simulation.export_save_state() == farmer_save_before,
		"a Farmer Favor driver should land on the visible standing tile instead of an unavailable archive action",
		failures,
	)
	await create_timer(0.7).timeout
	var settled_farmer_driver := (
		(office.call("_flockwatch_diagnostic_state") as Dictionary).get(
			"campaign_order_driver",
			{},
		) as Dictionary
	)
	var settled_farmer_arrival := (
		settled_farmer_driver.get("page_arrival", {}) as Dictionary
	)
	var standing_style_pinned := (
		standing_tile.get_theme_stylebox("panel")
		if standing_tile is PanelContainer else
		null
	)
	_check(
		standing_tile is PanelContainer
		and not bool(settled_farmer_arrival.get("active", true))
		and bool(settled_farmer_arrival.get("pinned", false))
		and standing_tile.modulate == Color.WHITE
		and standing_style_pinned != null
		and standing_style_pinned != standing_style_before
		and simulation.export_save_state() == farmer_save_before,
		"a reached panel should retain a quiet destination pin after its arrival flash settles",
		failures,
	)
	office.call("_activate_campaign_order_return_cue")
	await process_frame
	await process_frame
	await process_frame
	var returned_farmer_driver := (
		(office.call("_flockwatch_diagnostic_state") as Dictionary).get(
			"campaign_order_driver",
			{},
		) as Dictionary
	)
	var returned_farmer_arrival := (
		returned_farmer_driver.get("page_arrival", {}) as Dictionary
	)
	_check(
		bool(office.get("_flockwatch_open"))
		and flockwatch_navigation.current_page_id() == FlockwatchNavigation.PAGE_TODAY
		and office.get_viewport().gui_get_focus_owner() == first_order_glance
		and standing_tile != null
		and standing_tile.modulate == Color.WHITE
		and not bool(returned_farmer_arrival.get("pinned", true))
		and standing_tile.get_theme_stylebox("panel") == standing_style_before
		and simulation.export_save_state() == farmer_save_before,
		"returning from Farmer Standing should restore the source goal without residual emphasis",
		failures,
	)
	flockwatch_navigation.open_page(FlockwatchNavigation.PAGE_OPERATIONS)
	await process_frame
	var operations_scroll := flockwatch_navigation.page_scroll(
		FlockwatchNavigation.PAGE_OPERATIONS,
	)
	if operations_scroll != null:
		operations_scroll.scroll_vertical = 100000
	await process_frame
	flockwatch_navigation.open_page(FlockwatchNavigation.PAGE_TODAY)
	first_order_glance.set_meta("metric", &"average_compliance")
	office.call("_configure_campaign_order_driver_action", first_order_glance)
	var coop_driver_before := (
		(office.call("_flockwatch_diagnostic_state") as Dictionary).get(
			"campaign_order_driver",
			{},
		) as Dictionary
	)
	var coop_arrival_before := coop_driver_before.get("page_arrival", {}) as Dictionary
	var coop_save_before := simulation.export_save_state()
	if order_driver_button != null:
		order_driver_button.pressed.emit()
	await process_frame
	await process_frame
	var coop_state := office.call("_flockwatch_diagnostic_state") as Dictionary
	var coop_driver := coop_state.get("campaign_order_driver", {}) as Dictionary
	var coop_result := coop_driver.get("last_result", {}) as Dictionary
	var coop_arrival := coop_driver.get("page_arrival", {}) as Dictionary
	var exposure_panel := office.find_child(
		"RoosterOperationsExposureGlancePanel",
		true,
		false,
	) as Control
	var exposure_offset := (
		exposure_panel.global_position.y - operations_scroll.global_position.y
		if exposure_panel != null and operations_scroll != null else
		9999.0
	)
	_check(
		bool(office.get("_flockwatch_open"))
		and flockwatch_navigation.current_page_id() == FlockwatchNavigation.PAGE_OPERATIONS
		and String(coop_result.get("action_id", "")) == "coop_controls"
		and String(coop_result.get("target", "")) == "RoosterOperationsExposureGlancePanel"
		and bool(coop_result.get("target_available", false))
		and not bool(coop_result.get("filed_choice", true))
		and exposure_panel != null
		and exposure_panel.is_visible_in_tree()
		and exposure_offset >= 0.0
		and exposure_offset <= 20.0
		and bool(coop_arrival.get("active", false))
		and bool(coop_arrival.get("animated", false))
		and String(coop_arrival.get("page", "")) == "operations"
		and String(coop_arrival.get("target", "")) == "RoosterOperationsExposureGlancePanel"
		and int(coop_arrival.get("serial", 0)) == int(coop_arrival_before.get("serial", 0)) + 1
		and exposure_panel.modulate != Color.WHITE
		and simulation.export_save_state() == coop_save_before,
		"a compliance driver should land on the exact exposure control instead of generic shift actions",
		failures,
	)
	office.call("_activate_campaign_order_return_cue")
	await process_frame
	await process_frame
	_check(
		bool(office.get("_flockwatch_open"))
		and flockwatch_navigation.current_page_id() == FlockwatchNavigation.PAGE_TODAY
		and exposure_panel != null
		and exposure_panel.modulate == Color.WHITE
		and simulation.export_save_state() == coop_save_before,
		"returning from Compliance Exposure should restore the source goal without residual emphasis",
		failures,
	)
	first_order_glance.set_meta("metric", original_driver_metric)
	office.call("_configure_campaign_order_driver_action", first_order_glance)
	var cause_focus_save_before := simulation.export_save_state()
	var first_cause_click := InputEventMouseButton.new()
	first_cause_click.button_index = MOUSE_BUTTON_LEFT
	first_cause_click.pressed = true
	office.call(
		"_on_campaign_order_glance_gui_input",
		first_cause_click,
		first_order_glance,
	)
	await process_frame
	var first_cause_click_state := office.call("_flockwatch_diagnostic_state") as Dictionary
	_check(
		bool(office.get("_flockwatch_open"))
		and int(
			(first_cause_click_state.get("campaign_order_causes", {}) as Dictionary).get(
				"activation_serial",
				0,
			)
		) == 0,
		"the first pointer tap on a cause-bearing goal should select it without leaving the ledger",
		failures,
	)
	var second_cause_click := InputEventMouseButton.new()
	second_cause_click.button_index = MOUSE_BUTTON_LEFT
	second_cause_click.pressed = true
	office.call(
		"_on_campaign_order_glance_gui_input",
		second_cause_click,
		first_order_glance,
	)
	await process_frame
	await process_frame
	var cause_focus_state := office.call("_flockwatch_diagnostic_state") as Dictionary
	var cause_focus := cause_focus_state.get("campaign_order_causes", {}) as Dictionary
	var cause_focus_result := cause_focus.get("last_focus_result", {}) as Dictionary
	var exact_file_arrival := cause_focus.get("claim_file_arrival", {}) as Dictionary
	var exact_hen_arrival := cause_focus.get("hen_dossier_arrival", {}) as Dictionary
	var source_return := cause_focus_state.get("campaign_order_return", {}) as Dictionary
	_check(
		not bool(office.get("_flockwatch_open"))
		and routing_ui != null
		and routing_ui.focused_worker_id() == 0
		and camera_controller != null
		and camera_controller.is_focused()
		and int(cause_focus.get("activation_serial", 0)) == 1
		and int(cause_focus_result.get("worker_id", -1)) == 0
		and String(cause_focus_result.get("objective_id", "")) == String(requested_objective_id)
		and int(cause_focus_result.get("claim_id", -1)) == 1
		and String(cause_focus_result.get("target_kind", "")) in ["claim_file", "hen_dossier"]
		and (
			bool(cause_focus_result.get("claim_available", false))
			== (String(cause_focus_result.get("target_kind", "")) == "claim_file")
		)
		and bool(cause_focus_result.get("target_available", false))
		and not bool(cause_focus_result.get("filed_choice", true))
		and (
			(
				bool(exact_file_arrival.get("active", false))
				and int(exact_file_arrival.get("claim_id", -1)) == 1
				and int(exact_file_arrival.get("serial", 0)) == 1
			)
			if bool(cause_focus_result.get("claim_available", false)) else
			not bool(exact_file_arrival.get("active", true))
		)
		and (
			not bool(exact_hen_arrival.get("active", true))
			if bool(cause_focus_result.get("claim_available", false)) else
			(
				bool(exact_hen_arrival.get("active", false))
				and int(exact_hen_arrival.get("worker_id", -1)) == 0
				and int(exact_hen_arrival.get("serial", 0)) == int(
					driver_hen_arrival.get("serial", 0)
				) + 1
				and routing_ui.active_dossier_tab() == &"route"
			)
		)
		and bool(source_return.get("visible", false))
		and String(source_return.get("handoff_kind", "")) == String(
			cause_focus_result.get("target_kind", "")
		)
		and String(source_return.get("icon_kind", "")) == (
			"files" if bool(cause_focus_result.get("claim_available", false)) else "flock"
		)
		and guidance_icon.icon_kind() == StringName(source_return.get("icon_kind", &""))
		and simulation.export_save_state() == cause_focus_save_before,
		"activating a goal cause should locate its live source hen and preserve an exact return without filing gameplay",
		failures,
	)
	if guidance_action != null:
		guidance_action.pressed.emit()
	await process_frame
	await process_frame
	await process_frame
	_check(
		bool(office.get("_flockwatch_open"))
		and office.get_viewport().gui_get_focus_owner() == first_order_glance,
		"the cause locator return should restore the same goal tile",
		failures,
	)
	var stale_receipt := (
		first_order_glance.get_meta("cause_receipt", {}) as Dictionary
	).duplicate(true)
	var stale_source := (stale_receipt.get("source", {}) as Dictionary).duplicate(true)
	stale_source["claim_id"] = 999999
	stale_receipt["source"] = stale_source
	first_order_glance.set_meta("cause_receipt", stale_receipt)
	var stale_locator_save_before := simulation.export_save_state()
	var stale_locator_activated := bool(office.call(
		"_activate_campaign_order_cause_source",
		first_order_glance,
	))
	var stale_locator_state := office.call("_flockwatch_diagnostic_state") as Dictionary
	var stale_locator_focus := (
		stale_locator_state.get("campaign_order_causes", {}) as Dictionary
	).get("last_focus_result", {}) as Dictionary
	var stale_return := stale_locator_state.get("campaign_order_return", {}) as Dictionary
	var stale_arrival := (
		stale_locator_state.get("campaign_order_causes", {}) as Dictionary
	).get("claim_file_arrival", {}) as Dictionary
	var stale_hen_arrival := (
		stale_locator_state.get("campaign_order_causes", {}) as Dictionary
	).get("hen_dossier_arrival", {}) as Dictionary
	_check(
		stale_locator_activated
		and String(stale_locator_focus.get("target_kind", "")) == "hen_dossier"
		and not bool(stale_locator_focus.get("claim_available", true))
		and String(stale_return.get("handoff_kind", "")) == "hen_dossier"
		and String(stale_return.get("icon_kind", "")) == "flock"
		and not bool(stale_arrival.get("active", true))
		and int(stale_arrival.get("serial", 0)) == int(exact_file_arrival.get("serial", 0))
		and routing_ui.active_dossier_tab() == &"route"
		and bool(stale_hen_arrival.get("active", false))
		and int(stale_hen_arrival.get("worker_id", -1)) == 0
		and int(stale_hen_arrival.get("serial", 0)) == int(
			exact_hen_arrival.get("serial", 0)
		) + 1
		and guidance_icon.icon_kind() == &"flock"
		and simulation.export_save_state() == stale_locator_save_before,
		"a stale receipt should use the hen fallback glyph without substituting a newer file",
		failures,
	)
	office.call("_activate_campaign_order_return_cue")
	office.set("_campaign_order_cause_receipts", {})
	office.call("_update_campaign_objectives_label", simulation.snapshot())
	if camera_controller != null:
		camera_controller.show_overview()
	office.call("_set_flockwatch_open", false)
	await process_frame
	_check(
		badge_promotion_icon != null and not badge_promotion_icon.visible,
		"the opening +3 bundle should not imply a promotion before it can reach the next threshold",
		failures,
	)
	_check(quota_progress != null and int(quota_progress.max_value) == 16 and int(quota_progress.value) == 0, "top HUD should scale the opening objective to four active hens", failures)
	_check(office.find_children("Upgrade_*", "Button", true, false).size() == 3, "Flockwatch should expose three upgrade paths", failures)
	var requisitions_toggle := office.find_child("DeskRequisitionsToggle", true, false) as Button
	var shift_help_toggle := office.find_child("OperationsShiftHelpToggle", true, false) as Button
	var shift_help := office.find_child("OperationsShiftHelp", true, false) as Label
	var records_summary := office.find_child("FlockwatchRecordsArchiveSummary", true, false) as Label
	_check(
		requisitions_toggle != null
		and requisitions_toggle.focus_mode == Control.FOCUS_ALL
		and "FILES" in requisitions_toggle.text
		and "DESK REQUISITIONS" not in requisitions_toggle.text
		and "COMPLETE" not in requisitions_toggle.text
		and _contains_all(
			requisitions_toggle.tooltip_text,
			["desk requisitions", "3 total", "ready", "complete"],
		)
		and _contains_all(
			String(requisitions_toggle.get_meta("accessible_text", "")),
			["files", "collapsed", "3 total", "ready", "complete"],
		),
		"Capital should show a concise keyboard-focusable filing action while preserving exact counts in tooltip and accessibility copy",
		failures,
	)
	_check(
		shift_help_toggle != null
		and shift_help_toggle.focus_mode == Control.FOCUS_ALL
		and shift_help != null
		and not shift_help.visible,
		"Operations help should begin as a concise optional row instead of permanent menu copy",
		failures,
	)
	_check(
		records_summary != null
		and "FARM MUTUAL" in records_summary.text
		and "FLOCK LABOR" in records_summary.text
		and "RECEIPTS" in records_summary.text,
		"Records should provide a useful compact archive instead of an empty page",
		failures,
	)
	_check(
		flockwatch_toggle != null
		and "FLOCKWATCH" in flockwatch_toggle.text
		and "4 of 4" in flockwatch_toggle.tooltip_text,
		"collapsed ledger should keep its stable identity and narrate active roost capacity",
		failures,
	)
	_check(review_panel != null and not review_panel.is_visible_in_tree(), "daily review should remain hidden during a shift", failures)

	var protected_fund := simulation.current_daily_operating_cost_cents() + simulation.wage_arrears_cents
	var opening_fund := simulation.revenue_cents
	_check(not simulation.purchase_upgrade(&"peckwork_tools"), "operating reserves should block an underfunded keycap requisition", failures)
	_check(simulation.revenue_cents == opening_fund, "a reserve-protected requisition rejection should be atomic", failures)
	simulation.revenue_cents += 500
	_check(simulation.purchase_upgrade(&"peckwork_tools"), "five additional Feed Fund dollars should make one keycap level affordable", failures)
	_check(simulation.revenue_cents == protected_fund, "the exact-price keycap requisition should retain the full operating reserve", failures)
	await process_frame
	var first_keycaps := office.find_children("RequisitionKeycap_0", "MeshInstance3D", true, false)
	_check(first_keycaps.size() == 6, "each workstation should contain a keycap upgrade indicator", failures)
	for keycap in first_keycaps:
		_check((keycap as MeshInstance3D).visible, "purchased keycap level should be visible at every desk", failures)

	simulation.eggs_today = simulation.quota_target
	simulation.cracked_today = 0
	simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	for _step in 3:
		simulation.advance_tick()
		_resolve_pending_incident(simulation)
		clock.set_speed(0)
	await process_frame
	_check(review_panel.is_visible_in_tree(), "shift completion should open the farmer review", failures)
	_check(clock.speed_index == 0, "farmer review should pause the next shift", failures)
	_check(
		review_summary != null
		and review_summary.is_visible_in_tree()
		and "CLEAN SHELLS" in review_summary.text
		and review_eggs != null
		and "16 / 16" in review_eggs.text
		and review_net != null
		and "$" in review_net.text
		and (
			review_net.text.begins_with("+")
			or review_net.text.begins_with("-")
		)
		and review_fund != null
		and review_fund.text.begins_with("$")
		and review_next != null
		and review_next.text.is_valid_int()
		and int(review_next.text) > 0,
		(
			"Farmer Review should lead with four glance-first result tiles and one quality line "
			+ "[quality=%s eggs=%s net=%s fund=%s next=%s]"
		) % [
			review_summary.text if review_summary != null else "<missing>",
			review_eggs.text if review_eggs != null else "<missing>",
			review_net.text if review_net != null else "<missing>",
			review_fund.text if review_fund != null else "<missing>",
			review_next.text if review_next != null else "<missing>",
		],
		failures,
	)
	_check(
		review_details_toggle != null
		and review_details_toggle.is_visible_in_tree()
		and review_details_toggle.text == "DETAILS"
		and review_details_scroll != null
		and not review_details_scroll.visible,
		"the full accounting ledger should begin behind an explicit disclosure",
		failures,
	)
	var review_accessibility := String(
		office.call("_web_accessibility_summary", simulation.snapshot())
	)
	_check(
		"Eggs versus target:" in review_accessibility
		and "Net:" in review_accessibility
		and "Feed Fund:" in review_accessibility
		and "Next target:" in review_accessibility
		and "Accounting details:" in review_accessibility
		and "Payroll" in review_accessibility
		and "Closing Feed Fund" in review_accessibility,
		"assistive review narration should combine every glance tile with the complete accounting ledger",
		failures,
	)
	if review_panel != null:
		_check(
			review_panel.size.y <= 432.0,
			"the default result card should release the unused accounting-ledger height",
			failures,
		)
	if review_details_toggle != null:
		review_details_toggle.pressed.emit()
	await process_frame
	_check(
		review_details_scroll != null
		and review_details_scroll.is_visible_in_tree()
		and review_details_toggle.text == "HIDE DETAILS",
		"the accounting disclosure should reveal a bounded scrolling detail region",
		failures,
	)
	_check(
		review_results != null
		and review_results.is_visible_in_tree()
		and "TARGET HARVESTED" in review_results.text
		and "Quality bonus" in review_results.text
		and "Payroll" in review_results.text
		and "Facilities" in review_results.text
		and "Net operating" in review_results.text
		and "Closing Feed Fund" in review_results.text,
		"review should reconcile rewards, obligations, net operations, and closing cash",
		failures,
	)
	if review_panel != null:
		var review_rect := review_panel.get_global_rect()
		_check(
			review_rect.position.y >= 0.0 and review_rect.end.y <= 720.0,
			"the expanded Farmer Review should remain inside the authored 720p stage",
			failures,
		)
	if review_details_toggle != null:
		review_details_toggle.pressed.emit()
	var scaled_preferences := (
		office.get("_player_preferences") as Dictionary
	).duplicate(true)
	scaled_preferences["ui_scale"] = 1.5
	office.set("_player_preferences", scaled_preferences)
	office.call("_apply_management_ui_preferences")
	await process_frame
	await process_frame
	if review_panel != null and review_continue != null:
		var scaled_review_rect := review_panel.get_global_rect()
		var continue_rect := review_continue.get_global_rect()
		_check(
			review_panel.size.y <= 482.0
			and scaled_review_rect.position.y >= 0.0
			and scaled_review_rect.end.y <= 720.0
			and continue_rect.position.y >= scaled_review_rect.position.y
			and continue_rect.end.y <= scaled_review_rect.end.y,
			"the compact result card and Continue action should remain contained at 150 percent scale",
			failures,
		)
	_check(
		review_glance != null
		and review_glance.columns == 4
		and review_glance.get_child_count() == 4,
		"the 150 percent result card should preserve its four-tile visual scan",
		failures,
	)
	# Let the short upgrade/review cues naturally retire before tearing down the
	# entire office; the dummy headless audio driver otherwise reports them as
	# live playback resources during process shutdown.
	await create_timer(0.4).timeout
	office.free()
	await process_frame

	if not failures.is_empty():
		for failure in failures:
			push_error("MANAGEMENT_LOOP_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MANAGEMENT_LOOP_UI_TEST_PASSED objective=visible upgrades=physical review=paused")
	quit(0)


func _resolve_pending_incident(simulation: DepartmentSimulation) -> void:
	var pending := simulation.pending_decision_snapshot()
	if StringName(pending.get("kind", &"")) != &"incident":
		return
	var serial := int(pending.get("serial", -1))
	for option_value in pending.get("options", []):
		var option := option_value as Dictionary
		if int(option.get("cost_cents", 0)) == 0:
			simulation.resolve_decision(serial, StringName(option.get("id", &"")))
			return


func _contains_all(copy: String, needles: Array[String]) -> bool:
	var normalized := copy.to_lower()
	for needle: String in needles:
		if needle.to_lower() not in normalized:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
