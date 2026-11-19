class_name OfficePulsePresenter
extends RefCounted

## Gameplay pulse HUD projection.
## Holds no state of its own: every read and write goes through the owning
## Office so behaviour is identical to the original in-class methods.

var office: Office


func _init(owner_node: Office) -> void:
	office = owner_node

func _compact_gameplay_pulse_diagnostic(source: Dictionary) -> Dictionary:
	return office._web_bridge._compact_gameplay_pulse_diagnostic(source)


func _campaign_pulse_projection() -> Dictionary:
	if office._campaign_state == null:
		return {}
	# CohesiveGameLoopAdvancement reads only these three fields. Avoid
	# serializing every past shift and unrelated campaign forecast each tick.
	return {
		"available_milestones": office._campaign_state.available_milestone_choices(),
		"active_doctrine": office._campaign_state.active_doctrine(),
		"final_evaluation": office._campaign_state.final_evaluation(),
	}


func _playbook_for_presentation(snapshot: Dictionary, focused_worker_id: int) -> Dictionary:
	# This publication already contains the current unfocused playbook. Focused
	# actions still need their hen-specific eligibility and reactions computed.
	if focused_worker_id < 0 and snapshot.get("active_playbook") is Dictionary:
		return snapshot["active_playbook"]
	return office._simulation.playbook_snapshot(focused_worker_id) if office._simulation != null else {}


func _refresh_gameplay_pulse(snapshot: Dictionary) -> void:
	var pulse_started := Time.get_ticks_usec()
	if office._gameplay_pulse_director == null:
		office._gameplay_pulse.clear()
		return
	var routing_lifecycle := (
		office._routing_ui.routing_lifecycle_state()
		if office._routing_ui != null and office._routing_ui.has_method("routing_lifecycle_state") else
		{}
	)
	var on_track := int(
		office._campaign_objectives_label.get_meta("orders_on_track", 0)
		if office._campaign_objectives_label != null else
		0
	)
	var order_total := int(
		office._campaign_objectives_label.get_meta("orders_total", 0)
		if office._campaign_objectives_label != null else
		0
	)
	var completed: int = office._campaign_state.completed_shifts if office._campaign_state != null else 0
	var focused_worker_id := (
		office._routing_ui.focused_worker_id()
		if office._routing_ui != null and office._routing_ui.has_method("focused_worker_id") else
		-1
	)
	var active_playbook := office._playbook_for_presentation(snapshot, focused_worker_id)
	var pulse_context := {
		"simulation": snapshot,
		"next_action": office._next_action_diagnostic_state(),
		"routing_lifecycle": routing_lifecycle,
		"action_feedback": office._latest_action_outcome_receipt,
		"momentum_brief": (
			office._campaign_state.momentum_brief() if office._campaign_state != null else {}
		),
		"rival": (
			office._simulation.rival_coop_snapshot(office._campaign_state.probation_score, completed)
			if office._simulation != null and office._campaign_state != null else
			{}
		),
		"chapter": (
			office._campaign_state.current_chapter() if office._campaign_state != null else {}
		),
		"first_session_funnel": office._first_session_funnel.snapshot(),
		"adaptive": office._adaptive_route_recovery_diagnostic_state(),
		"order_pulse": {"on_track": on_track, "total": order_total},
		"focused_worker_id": focused_worker_id,
		"active_playbook": active_playbook,
		"tactical_route_plan": office._tactical_route_plan_snapshot(),
		"challenge_contract_catalog": Office.CampaignStateScript.challenge_contract_catalog(),
		"scenario_catalog": DepartmentSimulation.replay_scenario_catalog(),
		"campaign": office._campaign_pulse_projection(),
		"scenario": (office._simulation.scenario_identity_snapshot() if office._simulation != null else {}),
		"cause_replay": office._last_cause_replay.duplicate(true),
	}
	var context_ready := Time.get_ticks_usec()
	office._gameplay_pulse = office._gameplay_pulse_director.compose(pulse_context, true, true)
	var pulse_composed := Time.get_ticks_usec()
	office._gameplay_pulse["active_playbook"] = active_playbook.duplicate(true)
	office._refresh_active_playbook_menu(active_playbook, focused_worker_id)
	_apply_complete_game_loop_presentation(
		office._gameplay_pulse.get("complete_game_loop", {}) as Dictionary,
		snapshot,
	)
	_apply_mastery_replay_presentation(
		office._gameplay_pulse.get("mastery_replay", {}) as Dictionary,
	)
	_apply_professional_loop_presentation(
		office._gameplay_pulse.get("professional_loop", {}) as Dictionary,
	)
	_apply_rewarding_loop_presentation(
		office._gameplay_pulse.get("rewarding_loop", {}) as Dictionary,
	)
	_apply_compelling_loop_presentation(
		office._gameplay_pulse.get("compelling_loop", {}) as Dictionary,
	)
	_apply_strategic_flow_presentation(
		office._gameplay_pulse.get("strategic_flow_loop", {}) as Dictionary,
	)
	_apply_tactile_reward_loop_presentation(
		office._gameplay_pulse.get("tactile_reward_loop", {}) as Dictionary,
	)
	_apply_experiential_management_presentation(
		office._gameplay_pulse.get("experiential_management_loop", {}) as Dictionary,
	)
	_apply_intuitive_reward_presentation(
		office._gameplay_pulse.get("intuitive_reward_loop", {}) as Dictionary,
	)
	_apply_consolidated_game_loop_presentation(
		office._gameplay_pulse.get("consolidated_game_loop", {}) as Dictionary,
	)
	_apply_professional_gameplay_completion_presentation(
		office._gameplay_pulse.get("professional_gameplay_completion", {}) as Dictionary,
	)
	_apply_intuitive_rewarding_completion_presentation(
		office._gameplay_pulse.get("intuitive_rewarding_completion", {}) as Dictionary,
	)
	_apply_cohesive_game_loop_advancement_presentation(
		office._gameplay_pulse.get("cohesive_game_loop_advancement", {}) as Dictionary,
	)
	office._apply_professional_polish_presentation(
		((office._gameplay_pulse.get("intuitive_rewarding_completion", {}) as Dictionary).get(
			"professional_polish",
			{},
		) as Dictionary),
	)
	var loop := office._gameplay_pulse.get("shift_journey", {}) as Dictionary
	var loop_steps := loop.get("steps", []) as Array
	for index in office._core_loop_icons.size():
		var loop_icon := office._core_loop_icons[index]
		if loop_icon == null or index >= loop_steps.size():
			continue
		var step := loop_steps[index] as Dictionary
		var state := StringName(step.get("state", &"upcoming"))
		var accent := Color("667780")
		if state == &"current":
			accent = Color("f4cd66")
		elif state == &"complete":
			accent = Color("9ccfc2")
		loop_icon.configure(StringName(step.get("icon", &"goal")), accent)
		loop_icon.tooltip_text = "%s  ·  %s" % [
			String(step.get("label", "STEP")),
			String(state).replace("_", " ").to_upper(),
		]
		loop_icon.set_meta("state", String(state))
	if office._core_loop_host != null:
		office._core_loop_host.tooltip_text = String(loop.get(
			"accessible_text",
			"Work loop: file to hen, hen to egg, egg to farmer credit.",
		))
		office._core_loop_host.set_meta("active_stage", String(loop.get("active_stage", "plan")))
		office._core_loop_host.set_meta("accessible_text", office._core_loop_host.tooltip_text)
	var reward_loop := office._gameplay_pulse.get("reward_loop", {}) as Dictionary
	for definition in Office.GameplayPulseDirectorScript.REWARD_LOOP_ICONS:
		var reward_id := StringName(definition.get("id", &""))
		var reward_icon: FlockwatchIconBadge = office._reward_loop_icons.get(reward_id)
		if reward_icon == null:
			continue
		var reward := reward_loop.get(reward_id, {}) as Dictionary
		var ready := bool(reward.get("ready", reward.get("complete", false)))
		var active := bool(reward.get("active", false))
		if reward_id == &"future_reward_ghost":
			active = not reward.is_empty()
		var accent := Color("53636c")
		if ready:
			accent = Color("f4cd66")
		elif active:
			accent = Color("9ccfc2")
		reward_icon.configure(StringName(reward.get("icon", definition.get("icon", &"goal"))), accent)
		reward_icon.tooltip_text = "%s  ·  %s\n%s" % [
			String(definition.get("label", "REWARD")),
			String(reward.get("label", "LOCKED")),
			String(reward.get("detail", "Progress is disclosed when the shift begins.")),
		]
		reward_icon.accessibility_name = reward_icon.tooltip_text
		reward_icon.set_meta("ready", ready)
		reward_icon.set_meta("active", active)
		reward_icon.set_meta("projection", reward.duplicate(true))
	if office._reward_loop_host != null:
		var reward_ready := false
		for reward_id in office._reward_loop_icons:
			var projection := reward_loop.get(reward_id, {}) as Dictionary
			if bool(projection.get("ready", projection.get("complete", false))):
				reward_ready = true
				break
		office._reward_loop_host.visible = (
			not office._compact_physical_hud
			and
			int(snapshot.get("shift_phase", 0)) == DepartmentSimulation.ShiftPhase.RUNNING
			and not String(active_playbook.get("strategy_preset_id", "")).is_empty()
			and (int(snapshot.get("eggs_today", 0)) > 0 or reward_ready)
		)
		office._reward_loop_host.set_meta("items", reward_loop.duplicate(true))
		office._reward_loop_host.set_meta("item_count", maxi(0, reward_loop.size() - 1))
	var clutch := reward_loop.get("clutch_carton", {}) as Dictionary
	var clutch_thresholds := clutch.get("thresholds", [2, 4, 8]) as Array
	var clutch_filled := int(clutch.get("filled", 0))
	for index in office._clutch_carton_icons.size():
		var clutch_icon := office._clutch_carton_icons[index]
		if clutch_icon == null:
			continue
		var threshold := int(clutch_thresholds[index]) if index < clutch_thresholds.size() else (index + 1) * 2
		var filled := clutch_filled >= threshold
		var next := not filled and threshold == int(clutch.get("next_threshold", 2))
		clutch_icon.configure(&"egg", Color("f4cd66") if filled else (Color("9ccfc2") if next else Color("53636c")))
		clutch_icon.tooltip_text = "CLEAN ×%d  ·  %s\n%s" % [threshold, "FILLED" if filled else ("NEXT" if next else "LOCKED"), String(clutch.get("detail", ""))]
		clutch_icon.accessibility_name = clutch_icon.tooltip_text
		clutch_icon.set_meta("filled", filled)
	if office._clutch_carton_host != null:
		office._clutch_carton_host.visible = clutch_filled > 0 and not office._compact_physical_hud
		office._clutch_carton_host.tooltip_text = String(clutch.get("detail", "Clean-clutch reward track: 2 / 4 / 8."))
		office._clutch_carton_host.set_meta("projection", clutch.duplicate(true))
	if office._quality_streak_label != null:
		office._quality_streak_label.visible = int(snapshot.get("quality_streak", 0)) > 0 and not office._compact_physical_hud
	var rival := office._gameplay_pulse.get("rival_pulse", {}) as Dictionary
	if office._rival_pulse_label != null:
		office._rival_pulse_label.visible = (
			not office._compact_physical_hud
			and
			bool(rival.get("visible", false))
			and int(snapshot.get("eggs_today", 0)) > 0
			and int(snapshot.get("shift_phase", 0)) == DepartmentSimulation.ShiftPhase.RUNNING
		)
		rival["hud_visible"] = office._rival_pulse_label.visible
		office._rival_pulse_label.text = String(rival.get("compact", "RIVAL ±0"))
		var counterplay := reward_loop.get("rival_counterplay", {}) as Dictionary
		office._rival_pulse_label.tooltip_text = "%s\n%s\n%s" % [
			String(rival.get("detail", "")),
			String(counterplay.get("label", "COUNTERPLAY LOCKED")),
			String(counterplay.get("rule", "")),
		]
		office._rival_pulse_label.accessibility_name = "%s. %s" % [
			office._rival_pulse_label.text,
			office._rival_pulse_label.tooltip_text,
		]
		office._set_hud_font_color(
			office._rival_pulse_label,
			Color("9ccfc2") if int(rival.get("difference", 0)) >= 0 else Color("efaa84"),
		)
	var strategy := reward_loop.get("strategy_identity", {}) as Dictionary
	var loadout := reward_loop.get("furnishing_loadout", {}) as Dictionary
	if office._directive_badge != null and not strategy.is_empty():
		office._directive_badge.tooltip_text += "\n\n%s  ·  %s\n%s" % [
			String(strategy.get("label", "SHIFT STRATEGY")),
			String(loadout.get("label", "BALANCED OFFICE")),
			String(strategy.get("detail", "")),
		]
		office._directive_badge.set_meta("strategy_identity", strategy.duplicate(true))
		office._directive_badge.set_meta("furnishing_loadout", loadout.duplicate(true))
	var preview := office._gameplay_pulse.get("action_preview", {}) as Dictionary
	var preview_line := String(preview.get("compact", ""))
	var guided_loop := office._gameplay_pulse.get("guided_loop", {}) as Dictionary
	var glance_line := "\nAT A GLANCE  ·  %s" % preview_line
	if not preview_line.is_empty() and office._guidance_action_button != null:
		office._guidance_action_button.tooltip_text += glance_line
		office._guidance_action_button.set_meta(
			"accessible_text",
			String(office._guidance_action_button.get_meta("accessible_text", "")) + glance_line,
		)
		# The full projection already lives in _gameplay_pulse and its on-demand
		# diagnostic endpoint; the button only needs its local action preview.
		office._guidance_action_button.set_meta(
			"world_target",
			(guided_loop.get("one_action_one_target", {}) as Dictionary).duplicate(true),
		)
		office._guidance_action_button.set_meta(
			"consequence_preview",
			(guided_loop.get("animated_consequence_preview", {}) as Dictionary).duplicate(true),
		)
	if office._core_loop_host != null:
		office._core_loop_host.set_meta("guided_loop", guided_loop.duplicate(true))
		office._core_loop_host.set_meta("physical_loop", (
			office._gameplay_pulse.get("physical_loop", {}) as Dictionary
		).duplicate(true))
	_apply_attention_focus(StringName(String(
		(office._gameplay_pulse.get("focus_mode", {}) as Dictionary).get("action_id", "")
	)))
	if not preview_line.is_empty() and office._guidance_label != null:
		office._guidance_label.tooltip_text += glance_line
		office._guidance_label.set_meta("accessible_text", office._guidance_label.tooltip_text)
		office._guidance_label.accessibility_name = office._guidance_label.tooltip_text
		if office._guidance_icon != null:
			office._guidance_icon.tooltip_text = office._guidance_label.tooltip_text
			office._guidance_icon.accessibility_name = office._guidance_label.tooltip_text
	office._apply_readable_loop_hud(snapshot, active_playbook)
	_refresh_shift_challenge_goal(active_playbook)

	office._gameplay_pulse_timing = {"context_usec": context_ready - pulse_started, "director_usec": pulse_composed - context_ready, "compose_usec": pulse_composed - pulse_started, "apply_usec": Time.get_ticks_usec() - pulse_composed}


func _apply_readable_loop_hud(snapshot: Dictionary, playbook: Dictionary) -> void:
	var eggs := maxi(0, int(snapshot.get("eggs_today", 0)))
	var guidance_enabled := (
		not bool(office._first_clutch.get("dismissed", true))
		and not (
			bool(office._first_clutch.get("route_first_lesson", false))
			and office._first_clutch_reinvestment_resolved()
		)
	)
	if not guidance_enabled:
		office._sync_authoritative_shift_objective_display()
	var opening := guidance_enabled and int(snapshot.get("day", 1)) == 1 and eggs <= 3
	var first_egg := guidance_enabled and bool(office._first_clutch.get("route_first_lesson", false)) and not office._first_clutch_reinvestment_resolved()
	var opening_target := 1 if first_egg else 3
	var opening_count := int(bool(office._first_clutch.get("delivery_laid", false))) if first_egg else mini(eggs, 3)
	opening = opening or first_egg
	var running := int(snapshot.get("shift_phase", 0)) == DepartmentSimulation.ShiftPhase.RUNNING
	office._opening_header_goal.visible = opening and running and not office._shift_objective_row.visible
	office._live_title_label.visible = not office._compact_physical_hud and not office._opening_header_goal.visible
	if office._opening_header_goal.visible:
		office._opening_header_slots.show_goal(opening_count, opening_target)
		office._opening_header_label.text = "FIRST EGG" if first_egg else "FIRST 3 EGGS" if eggs < 3 else "CLUTCH FILED"
		office._opening_header_goal.tooltip_text = "Opening goal: %d of %d eggs. Route, watch work, then collect. More goals appear after this reward." % [opening_count, opening_target]
		office._opening_header_goal.accessibility_name = office._opening_header_goal.tooltip_text
	office._opening_egg_slots.visible = opening and running
	if office._opening_egg_slots.visible:
		office._opening_egg_slots.show_goal(opening_count, opening_target)
		var opening_complete := not first_egg and eggs >= 3
		if first_egg:
			office._quota_progress_label.text = "FIRST EGG · %d/1" % opening_count
		elif opening_complete:
			office._quota_progress_label.text = "QUOTA  ·  %d / %d" % [eggs, maxi(1, int(snapshot.get("quota_target", 1)))]
		else:
			office._quota_progress_label.text = "FILE 3 EGGS · %d/3" % eggs
		var detail := "Opening goal: %d of %d eggs laid. Each egg travels to grading and the basket. More goals appear after this reward." % [opening_count, opening_target]
		if opening_complete:
			var quota := maxi(1, int(snapshot.get("quota_target", 1)))
			detail = "First clutch complete. Shift quota: %d of %d eggs laid; %d remaining before 5:00 PM." % [eggs, quota, maxi(0, quota - eggs)]
			office._quota_progress.max_value = quota
			office._quota_progress.value = mini(eggs, quota)
		office._quota_progress.tooltip_text = detail
		office._quota_progress.accessibility_name = detail
		office._quota_progress_label.tooltip_text = detail
		office._quota_progress_label.accessibility_name = detail
		office._shift_goal_status_host.set_meta("accessible_text", detail)
	# The floor carries the loop; detailed counters are available while inspecting.
	var inspecting := office._explain_strip != null and office._explain_strip.visible
	office._consequence_icon_host.visible = inspecting and not office._compact_physical_hud
	office._rival_pulse_label.visible = inspecting and not office._compact_physical_hud
	office._directive_badge_host.visible = inspecting and not office._compact_physical_hud
	office._core_loop_host.visible = not opening and inspecting and not office._compact_physical_hud
	office._shift_egg_goal_label.visible = not opening and inspecting
	office._reward_loop_host.visible = not opening and inspecting and not office._compact_physical_hud
	if opening:
		office._reward_loop_host.visible = false
		office._clutch_carton_host.visible = false
		office._quality_streak_label.visible = false
	elif running:
		var chain := maxi(0, int(snapshot.get("quality_streak", 0)))
		var ladder := office._clutch_reward_ladder_snapshot(chain)
		office._quality_streak_label.text = "CLEAN %d · +$%.2f" % [chain, float(ladder.get("current_bonus_cents", 0)) / 100.0]
		office._quality_streak_label.visible = inspecting and chain > 0 and not office._compact_physical_hud
		office._clutch_carton_host.visible = false
		if office._personal_goal.get("status", "") == "active" and int(office._personal_goal.get("day", -1)) == int(snapshot.get("day", 0)):
			office._quality_streak_label.tooltip_text = "%s. %s" % [Office.PersonalShiftGoal.label(office._personal_goal), office._quality_streak_label.text]
			office._quality_streak_label.text = Office.PersonalShiftGoal.progress(office._personal_goal, snapshot)
			office._quality_streak_label.visible = not office._compact_physical_hud
	# Optional bank/chase guidance is resolved by _update_guidance, after pause,
	# onboarding and recovery. Presentation must not overwrite that decision.
	if not office._upgrade_demonstration.is_empty() and int(office._upgrade_demonstration.get("day", 0)) < int(snapshot.get("day", 1)) - 1:
		office._upgrade_demonstration.clear()


## HUD metadata borrows the owned pulse graph read-only. Each refresh replaces
## that graph; no consumer edits it. Retaining subtrees avoids repeatedly copying
## the same nested projections for every label, panel and tooltip.
func _apply_complete_game_loop_presentation(loop: Dictionary, snapshot: Dictionary) -> void:
	if loop.is_empty():
		return
	var explain := loop.get("explain_mode", {}) as Dictionary
	var chips := explain.get("chips", []) as Array
	for index in mini(office._explain_chip_labels.size(), chips.size()):
		var chip := chips[index] as Dictionary
		var label := office._explain_chip_labels[index]
		if label == null:
			continue
		var value := String(chip.get("value", "")).strip_edges()
		if value.length() > 18:
			value = value.left(17).trim_suffix(" ") + "…"
		label.text = "%s\n%s" % [String(chip.get("label", "LOOK")), value]
		label.tooltip_text = "%s: %s" % [String(chip.get("label", "LOOK")), String(chip.get("value", ""))]
		label.accessibility_name = label.tooltip_text
	if office._explain_strip != null:
		office._explain_strip.set_meta("projection", explain)
		office._explain_strip.set_meta("chip_count", chips.size())

	var micro_shift := loop.get("micro_shift", {}) as Dictionary
	if office._core_loop_host != null:
		office._core_loop_host.set_meta("micro_shift", micro_shift)
		office._core_loop_host.set_meta("retired_label_count", int(micro_shift.get("retired_label_count", 0)))

	var rhythm := loop.get("shift_rhythm", {}) as Dictionary
	var stage := StringName(String(rhythm.get("stage", "calm")))
	var accent := Color("8faeb4")
	match stage:
		&"flow": accent = Color("8fd1b0")
		&"pressure": accent = Color("e4c36e")
		&"incident": accent = Color("ed927a")
		&"final_push": accent = Color("f4cd66")
		&"celebration": accent = Color("9ccfc2")
	if office._shift_goal_status_icon != null:
		office._shift_goal_status_icon.configure(&"egg", accent)
		office._shift_goal_status_icon.tooltip_text = "%s  ·  %d%% OF SHIFT" % [
			String(rhythm.get("label", "SHIFT RHYTHM")),
			roundi(float(rhythm.get("progress", 0.0)) * 100.0),
		]
		office._shift_goal_status_icon.set_meta("rhythm", rhythm)
	if office._top_hud_panel != null:
		office._top_hud_panel.set_meta("shift_rhythm", rhythm)
		office._top_hud_panel.set_meta("one_primary_pulse", bool(rhythm.get("one_primary_pulse", false)))
	if stage != office._last_shift_rhythm_stage:
		var previous_stage := office._last_shift_rhythm_stage
		office._last_shift_rhythm_stage = stage
		if previous_stage != &"" and int(snapshot.get("shift_phase", 0)) == DepartmentSimulation.ShiftPhase.RUNNING:
			var bark := ""
			if stage == &"flow":
				bark = "IN THE GROOVE!"
			elif stage == &"pressure":
				bark = "QUEUE'S RISING!"
			elif stage == &"final_push":
				bark = "FINAL PUSH!"
			if not bark.is_empty() and not office._blocking_management_surface_open() and not office._first_clutch_tracking_active() and Time.get_ticks_msec() >= office._payoff_quiet_until_msec and Time.get_ticks_msec() - office._last_optional_floor_beat_msec >= 8000:
				office._last_optional_floor_beat_msec = Time.get_ticks_msec()
				office._character_dialogue_ui.hold_ambient(3.0)
				var story := loop.get("emergent_story", {}) as Dictionary
				var worker_id := int(story.get("worker_id", -1))
				var view := office._worker_views.get(worker_id) as ChickenView
				if view != null and is_instance_valid(view):
					view.play_short_bark(bark, &"team")
			if stage == &"final_push" and office._audio_feedback != null:
				office._audio_feedback.play_shift_alert(float(rhythm.get("intensity", 0.9)))
	if office._active_playbook_button != null:
		office._active_playbook_button.set_meta(
			"emergent_story",
			(loop.get("emergent_story", {}) as Dictionary),
		)
		office._active_playbook_button.set_meta(
			"complete_game_loop",
			loop,
		)


func _apply_mastery_replay_presentation(layer: Dictionary) -> void:
	if layer.is_empty():
		return
	var payoff := layer.get("payoff_clock", {}) as Dictionary
	var power := layer.get("manager_power", {}) as Dictionary
	var reveal := layer.get("progressive_reveal", {}) as Dictionary
	var payoff_line := "NEXT PAYOFF  ·  %s" % String(payoff.get("label", "REWARD"))
	var remaining := int(payoff.get("actions_remaining", 0))
	if remaining > 0:
		payoff_line += "  ·  %d LEFT" % remaining
	else:
		payoff_line += "  ·  READY"
	if office._top_hud_panel != null:
		office._top_hud_panel.set_meta("mastery_replay", layer)
		office._top_hud_panel.set_meta("progressive_reveal", reveal)
		office._top_hud_panel.set_meta("payoff_clock", payoff)
	if office._core_loop_host != null:
		office._core_loop_host.set_meta("unlock_ladder", (
			layer.get("unlock_ladder", {}) as Dictionary
		))
	if office._active_playbook_button == null:
		return
	var base_tooltip := String(office._active_playbook_button.get_meta(
		"base_mastery_tooltip",
		office._active_playbook_button.tooltip_text,
	))
	office._active_playbook_button.text = "PLAN  [Q]"
	office._active_playbook_button.tooltip_text = "%s\nQ  ·  OPEN ACTIVE PLAYBOOK\n%s" % [
		payoff_line,
		base_tooltip,
	]
	office._active_playbook_button.accessibility_name = (
		"%s. Press Q to open the Active Playbook; Q never files a choice. %s"
		% [payoff_line, base_tooltip.replace("\n", ". ")]
	)
	if bool(power.get("ready", false)):
		office._active_playbook_button.icon = Office.ManagementUIThemeScript.action_icon(&"rank_crest")
	office._active_playbook_button.set_meta("mastery_replay", layer)
	office._active_playbook_button.set_meta("manager_power", power)
	office._active_playbook_button.set_meta("payoff_clock", payoff)


func _apply_professional_loop_presentation(layer: Dictionary) -> void:
	if layer.is_empty():
		return
	var focus := layer.get("attention_focus", {}) as Dictionary
	var icon_strip := layer.get("consequence_icons", {}) as Dictionary
	var icon_rows := icon_strip.get("icons", []) as Array
	var icon_accents := [Color("9ccfc2"), Color("d9c47d"), Color("efaa84")]
	for index in office._consequence_icons.size():
		var icon := office._consequence_icons[index]
		if icon == null or index >= icon_rows.size():
			continue
		var row := icon_rows[index] as Dictionary
		icon.configure(
			StringName(row.get("icon", &"goal")),
			icon_accents[index] if index < icon_accents.size() else Color("dce7e8"),
		)
		icon.tooltip_text = "%s  ·  %s" % [
			String(row.get("id", "outcome")).replace("_", " ").to_upper(),
			String(row.get("value", "VISIBLE RESULT")),
		]
		icon.accessibility_name = icon.tooltip_text
		icon.set_meta("projection", row)
	if office._consequence_icon_host != null:
		office._consequence_icon_host.visible = icon_rows.size() == 3
		office._consequence_icon_host.set_meta("icon_count", icon_rows.size())
		office._consequence_icon_host.set_meta("projection", icon_strip)
	if office._guidance_action_button != null and icon_rows.size() == 3:
		var compact_lines: Array[String] = []
		for row_value in icon_rows:
			var row := row_value as Dictionary
			compact_lines.append("%s: %s" % [
				String(row.get("id", "outcome")).replace("_", " ").to_upper(),
				String(row.get("value", "VISIBLE RESULT")),
			])
		var consequence_copy := "\n" + "  ·  ".join(compact_lines)
		if not office._guidance_action_button.tooltip_text.contains("BENEFIT:"):
			office._guidance_action_button.tooltip_text += consequence_copy
		office._guidance_action_button.accessibility_name = office._guidance_action_button.tooltip_text
		office._guidance_action_button.set_meta("consequence_icons", icon_strip)
	var secondary_alpha := clampf(float(focus.get("secondary_chrome_alpha", 0.66)), 0.4, 1.0)
	var focus_active := String(focus.get("mode", "observe")) != "observe"
	if office._core_loop_host != null:
		office._core_loop_host.modulate.a = secondary_alpha if focus_active else 1.0
	if office._reward_loop_host != null and String(focus.get("mode", "")) != "reward":
		office._reward_loop_host.modulate.a = secondary_alpha if focus_active else 1.0
	if office._flockwatch_toggle != null:
		office._flockwatch_toggle.modulate.a = secondary_alpha if focus_active else 1.0
	if office._top_hud_panel != null:
		office._top_hud_panel.set_meta("professional_loop", layer)
		office._top_hud_panel.set_meta("attention_focus", focus)
	var power := layer.get("contextual_power", {}) as Dictionary
	if office._active_playbook_button != null and bool(power.get("ready", false)):
		var action_label := String(power.get("label", "ACTIVE PLAYBOOK")).strip_edges().to_upper()
		if action_label.contains("/"):
			action_label = action_label.get_slice("/", 1).strip_edges()
		if action_label.length() > 18:
			action_label = action_label.left(17).trim_suffix(" ") + "…"
		office._active_playbook_button.text = "PLAN  [Q]"
		office._active_playbook_button.set_meta("contextual_power_label", action_label)
		office._active_playbook_button.set_meta("professional_loop", layer)


func _apply_rewarding_loop_presentation(layer: Dictionary) -> void:
	if layer.is_empty():
		return
	var brief := layer.get("shift_brief", {}) as Dictionary
	var cards := brief.get("cards", []) as Array
	var accents := [Color("9ccfc2"), Color("efaa84"), Color("f4cd66")]
	for index in office._consequence_icons.size():
		var icon := office._consequence_icons[index]
		if icon == null or index >= cards.size():
			continue
		var card := cards[index] as Dictionary
		icon.configure(
			StringName(card.get("icon", &"goal")),
			accents[index] if index < accents.size() else Color("dce7e8"),
		)
		icon.tooltip_text = "%s  ·  %s" % [
			String(card.get("label", "BRIEF")),
			String(card.get("value", "REVIEW THE FLOOR")),
		]
		icon.accessibility_name = icon.tooltip_text
		icon.set_meta("rewarding_brief", card)
	if office._consequence_icon_host != null:
		office._consequence_icon_host.visible = cards.size() == 3
		office._consequence_icon_host.tooltip_text = "SHIFT BRIEF  ·  GOAL / DANGER / REWARD"
		office._consequence_icon_host.set_meta("shift_brief", brief)
		office._consequence_icon_host.set_meta("semantic_order", ["goal", "danger", "reward"])
	var countdown := layer.get("goal_countdown", {}) as Dictionary
	var remaining := maxi(0, int(countdown.get("actions_remaining", 0)))
	var reward_label := String(countdown.get("label", "NEXT PAYOFF")).strip_edges().to_upper()
	if office._shift_egg_goal_label != null:
		office._shift_egg_goal_label.visible = true
		office._shift_egg_goal_label.text = "%d LEFT" % remaining if remaining > 0 else "READY"
		office._shift_egg_goal_label.tooltip_text = "NEXT PAYOFF  ·  %s  ·  %s" % [
			reward_label,
			"%d action%s left" % [remaining, "" if remaining == 1 else "s"]
			if remaining > 0 else
			"ready now",
		]
		office._shift_egg_goal_label.accessibility_name = office._shift_egg_goal_label.tooltip_text
		office._shift_egg_goal_label.set_meta("payoff_countdown", countdown)
	var why := layer.get("result_why", {}) as Dictionary
	if bool(why.get("visible", false)) and office._guidance_action_button != null:
		var why_copy := String(why.get("compact", "")).strip_edges()
		if not why_copy.is_empty() and not office._guidance_action_button.tooltip_text.contains("WHY  ·"):
			office._guidance_action_button.tooltip_text += "\n%s" % why_copy
			office._guidance_action_button.accessibility_name = office._guidance_action_button.tooltip_text
		office._guidance_action_button.set_meta("result_why", why)
	if office._routing_ui != null:
		office._routing_ui.set_meta(
			"rewarding_compact_dossier",
			(layer.get("compact_dossier", {}) as Dictionary),
		)
	if office._top_hud_panel != null:
		office._top_hud_panel.set_meta("rewarding_loop", layer)
	if office._active_playbook_button != null:
		office._active_playbook_button.set_meta(
			"decision_cadence",
			(layer.get("decision_cadence", {}) as Dictionary),
		)


func _apply_compelling_loop_presentation(layer: Dictionary) -> void:
	if layer.is_empty():
		return
	var before_after := layer.get("before_after_preview", {}) as Dictionary
	var before := before_after.get("before", {}) as Dictionary
	var after := before_after.get("after", {}) as Dictionary
	for icon in office._consequence_icons:
		if icon == null:
			continue
		icon.set_meta("before_after_preview", before_after)
		if not icon.tooltip_text.contains("\nNOW  ·"):
			icon.tooltip_text += "\nNOW  ·  %s\nAFTER  ·  %s" % [
				String(before.get("label", "OBSERVE")),
				String(after.get("gain", "VISIBLE RESULT")),
			]
		icon.accessibility_name = icon.tooltip_text
	var identity := layer.get("shift_identity", {}) as Dictionary
	var roster := layer.get("roster_strategy", {}) as Dictionary
	if office._directive_badge != null:
		if not office._directive_badge.tooltip_text.contains("\nSHIFT  ·"):
			office._directive_badge.tooltip_text += "\nSHIFT  ·  %s\nROSTER  ·  %s" % [
				String(identity.get("label", "BALANCED SHIFT")),
				String(roster.get("compact", "FLOCK COVERAGE")),
			]
		office._directive_badge.accessibility_name = office._directive_badge.tooltip_text
		office._directive_badge.set_meta("shift_identity", identity)
		office._directive_badge.set_meta("roster_strategy", roster)
	if office._shift_goal_status_icon != null:
		office._shift_goal_status_icon.tooltip_text += "\n%s" % String(identity.get("label", "BALANCED SHIFT"))
		office._shift_goal_status_icon.set_meta("shift_identity", identity)
	var combo := layer.get("combo_discovery", {}) as Dictionary
	var combo_progress := int(combo.get("progress", 0))
	var combo_target := int(combo.get("target", 0))
	var hen_personality := layer.get("hen_personality", {}) as Dictionary
	var power := hen_personality.get("signature", {}) as Dictionary
	if (
		office._active_playbook_button != null
		and combo_progress > 0
		and combo_progress < combo_target
		and not bool(power.get("ready", false))
	):
		office._active_playbook_button.text = "PLAN  [Q]"
		office._active_playbook_button.set_meta("combo_discovery", combo)
		if not office._active_playbook_button.tooltip_text.begins_with("COMBO "):
			office._active_playbook_button.tooltip_text = "%s\n%s" % [
				String(combo.get("compact", "COMBO IN PROGRESS")),
				office._active_playbook_button.tooltip_text,
			]
		office._active_playbook_button.accessibility_name = office._active_playbook_button.tooltip_text
	if office._top_hud_panel != null:
		office._top_hud_panel.set_meta("compelling_loop", layer)
		office._top_hud_panel.set_meta(
			"celebration_scale",
			(layer.get("celebration_scale", {}) as Dictionary),
		)
		office._top_hud_panel.set_meta(
			"audio_grammar",
			(layer.get("audio_grammar", {}) as Dictionary),
		)
	if office._routing_ui != null:
		office._routing_ui.set_meta(
			"adaptive_information_density",
			(layer.get("information_density", {}) as Dictionary),
		)


func _apply_strategic_flow_presentation(layer: Dictionary) -> void:
	if layer.is_empty():
		return
	var bottleneck := layer.get("bottleneck", {}) as Dictionary
	var forecast := layer.get("strategy_forecast", {}) as Dictionary
	var roster := layer.get("roster_warning", {}) as Dictionary
	var handoff := layer.get("handoff", {}) as Dictionary
	var route_preview := layer.get("route_preview", {}) as Dictionary
	if office._shift_goal_status_icon != null:
		office._shift_goal_status_icon.set_meta("live_bottleneck", bottleneck)
		if not office._shift_goal_status_icon.tooltip_text.contains("\nBOTTLENECK  ·"):
			office._shift_goal_status_icon.tooltip_text += "\nBOTTLENECK  ·  %s" % String(
				bottleneck.get("label", "WATCH THE FLOOR"),
			)
		office._shift_goal_status_icon.accessibility_name = office._shift_goal_status_icon.tooltip_text
	if office._directive_badge != null:
		office._directive_badge.set_meta("strategy_forecast", forecast)
		office._directive_badge.set_meta("roster_warning", roster)
		if not office._directive_badge.tooltip_text.contains("\nFORECAST  ·"):
			office._directive_badge.tooltip_text += "\nFORECAST  ·  %s\nROSTER  ·  %s" % [
				String(forecast.get("compact", "BALANCED · AWAITING PLAN")),
				String(roster.get("compact", "FULL COVERAGE")),
			]
		office._directive_badge.accessibility_name = office._directive_badge.tooltip_text
	if office._active_playbook_button != null:
		office._active_playbook_button.set_meta("perfect_handoff", handoff)
		office._active_playbook_button.set_meta(
			"saved_loadouts",
			(layer.get("saved_loadouts", {}) as Dictionary),
		)
		office._active_playbook_button.set_meta(
			"mid_shift_plan_adjustment",
			(layer.get("plan_adjustment", {}) as Dictionary),
		)
		if not office._active_playbook_button.tooltip_text.contains("\nHANDOFF  ·"):
			office._active_playbook_button.tooltip_text += "\nHANDOFF  ·  %s\nADJUST  ·  SIGNATURE / TEAMWORK / RESCUE" % String(
				handoff.get("compact", "HANDOFF 0/2"),
			)
		office._active_playbook_button.accessibility_name = office._active_playbook_button.tooltip_text
	if office._top_hud_panel != null:
		office._top_hud_panel.set_meta("strategic_flow_loop", layer)
		office._top_hud_panel.set_meta(
			"career_legacy",
			(layer.get("career_legacy", {}) as Dictionary),
		)
	if office._routing_ui != null:
		office._routing_ui.set_meta("interactive_route_preview", route_preview)
		office._routing_ui.set_meta("live_bottleneck", bottleneck)
		office._routing_ui.set_meta(
			"resource_source_use_animation",
			(layer.get("resource_flow", {}) as Dictionary),
		)


func _apply_tactile_reward_loop_presentation(layer: Dictionary) -> void:
	if layer.is_empty():
		return
	var tactical_plan := layer.get("tactical_pause_plan", {}) as Dictionary
	var puzzle := layer.get("shift_puzzle", {}) as Dictionary
	var pressure := layer.get("queue_pressure", {}) as Dictionary
	var wager := layer.get("prediction_wager", {}) as Dictionary
	var payoff := layer.get("payoff_anticipation", {}) as Dictionary
	if office._routing_ui != null:
		office._routing_ui.set_meta("tactical_route_plan", tactical_plan)
		office._routing_ui.set_meta("cause_effect_trail", (layer.get("cause_effect_trail", {}) as Dictionary))
		office._routing_ui.set_meta("queue_pressure", pressure)
		office._routing_ui.set_meta("chicken_chain_reaction", (layer.get("chicken_chain_reaction", {}) as Dictionary))
	if office._directive_badge != null:
		office._directive_badge.set_meta("shift_puzzle", puzzle)
		office._directive_badge.set_meta("intensity_contracts", (layer.get("intensity_contracts", {}) as Dictionary))
		if not office._directive_badge.tooltip_text.contains("\nPUZZLE  ·"):
			office._directive_badge.tooltip_text += "\nPUZZLE  ·  %s\nINTENSITY  ·  PLAYER CONTRACT" % String(
				puzzle.get("label", "BALANCED FLOOR"),
			)
		office._directive_badge.accessibility_name = office._directive_badge.tooltip_text
	if office._active_playbook_button != null:
		office._active_playbook_button.set_meta("prediction_wager", wager)
		office._active_playbook_button.set_meta("decisive_shift_choice", (layer.get("decisive_shift_choice", {}) as Dictionary))
		if not office._active_playbook_button.tooltip_text.contains("\nWAGER  ·"):
			office._active_playbook_button.tooltip_text += "\nWAGER  ·  OPTIONAL / PROGRESS SAFE\nCHOICE  ·  ONE MEMORABLE SHIFT BEAT"
		office._active_playbook_button.accessibility_name = office._active_playbook_button.tooltip_text
	if office._shift_egg_goal_label != null:
		office._shift_egg_goal_label.set_meta("payoff_anticipation", payoff)
		if not office._shift_egg_goal_label.tooltip_text.contains("\nPAYOFF  ·"):
			office._shift_egg_goal_label.tooltip_text += "\nPAYOFF  ·  BUILDUP SCALES WITH IMPORTANCE"
		office._shift_egg_goal_label.accessibility_name = office._shift_egg_goal_label.tooltip_text
	if office._top_hud_panel != null:
		office._top_hud_panel.set_meta("tactile_reward_loop", layer)
		office._top_hud_panel.set_meta("resource_identities", (layer.get("resource_identities", {}) as Dictionary))
		office._top_hud_panel.set_meta("office_hotspots", (layer.get("office_hotspots", {}) as Dictionary))


func _apply_experiential_management_presentation(layer: Dictionary) -> void:
	if layer.is_empty():
		return
	if office._routing_ui != null:
		office._routing_ui.set_meta("direct_physical_triage", (layer.get("direct_physical_triage", {}) as Dictionary))
		office._routing_ui.set_meta("living_queue_pressure", (layer.get("queue_pressure", {}) as Dictionary))
		office._routing_ui.set_meta("chicken_body_language", (layer.get("chicken_states", []) as Array))
		office._routing_ui.set_meta("cause_replay", (layer.get("cause_replay", {}) as Dictionary))
		office._routing_ui.set_meta("case_personas", (layer.get("case_personas", []) as Array))
	if office._top_hud_panel != null:
		office._top_hud_panel.set_meta("experiential_management_loop", layer)
		office._top_hud_panel.set_meta("one_glance_shift_state", (layer.get("glance", {}) as Dictionary))
		office._top_hud_panel.set_meta("adaptive_pacing", (layer.get("pacing", {}) as Dictionary))
	if office._active_playbook_button != null:
		office._active_playbook_button.set_meta("incoming_docket_draft", (layer.get("docket_draft", {}) as Dictionary))
		office._active_playbook_button.set_meta("manager_intervention", (layer.get("manager_intervention", {}) as Dictionary))
		office._active_playbook_button.set_meta("mechanic_upgrades", (layer.get("mechanic_upgrades", {}) as Dictionary))
	if office._explain_strip != null:
		office._explain_strip.set_meta("cause_replay", (layer.get("cause_replay", {}) as Dictionary))
	if office._directive_badge != null:
		office._directive_badge.set_meta("meaningful_office_layout", (layer.get("office_layout", {}) as Dictionary))
		office._directive_badge.set_meta("exclusive_specializations", (layer.get("specializations", {}) as Dictionary))
	if office._rival_pulse_label != null:
		office._rival_pulse_label.set_meta("visible_rival_office", (layer.get("rival", {}) as Dictionary))
		office._rival_pulse_label.set_meta("boss_shift", (layer.get("boss_shift", {}) as Dictionary))
	if office._core_loop_host != null:
		office._core_loop_host.set_meta("silent_opening_shift", ((layer.get("items", {}) as Dictionary).get("silent_opening_shift", {}) as Dictionary))
		office._core_loop_host.set_meta("physical_combo_chains", (layer.get("combo", {}) as Dictionary))


func _apply_intuitive_reward_presentation(layer: Dictionary) -> void:
	if layer.is_empty():
		return
	var station := layer.get("manager_station", {}) as Dictionary
	if office._management_presence != null:
		office._management_presence.apply_command_station_state(station)
	if office._top_hud_panel != null:
		office._top_hud_panel.set_meta("intuitive_reward_loop", layer)
		office._top_hud_panel.set_meta("three_beat_cause_effect", (layer.get("cause_effect", {}) as Dictionary))
	if office._routing_ui != null:
		office._routing_ui.set_meta("shape_coded_case_folders", (layer.get("case_folders", {}) as Dictionary))
		office._routing_ui.set_meta("personal_hen_goals", (layer.get("personal_goals", {}) as Dictionary))
		office._routing_ui.set_meta("setback_recovery", (layer.get("setback_recovery", {}) as Dictionary))
	if office._active_playbook_button != null:
		office._active_playbook_button.set_meta("physical_manager_station", station)
		office._active_playbook_button.set_meta("morning_plan_cards", (layer.get("morning_plan", {}) as Dictionary))
		office._active_playbook_button.set_meta("combo_anticipation", (layer.get("combo_anticipation", {}) as Dictionary))
		office._active_playbook_button.set_meta("short_action_language", (layer.get("action_language", {}) as Dictionary))
	if office._directive_badge != null:
		var hero_file := layer.get("hero_file", {}) as Dictionary
		office._directive_badge.set_meta("hero_file", hero_file)
		if bool(hero_file.get("active", false)) and not office._directive_badge.tooltip_text.contains("\nHERO FILE  ·"):
			office._directive_badge.tooltip_text += "\nHERO FILE  ·  %s  →  %s" % [
				String(hero_file.get("label", "NEXT FILE")),
				String(hero_file.get("worker_name", "FLOCK")).to_upper(),
			]
			office._directive_badge.accessibility_name = office._directive_badge.tooltip_text
	if office._shift_egg_goal_label != null:
		office._shift_egg_goal_label.set_meta("visible_reward_destination", (layer.get("reward_destination", {}) as Dictionary))
		office._shift_egg_goal_label.set_meta("next_shift_tease", (layer.get("next_shift_tease", {}) as Dictionary))
	if office._rival_pulse_label != null:
		office._rival_pulse_label.set_meta("rival_office_presence", (layer.get("rival_presence", {}) as Dictionary))
	if office._core_loop_host != null:
		office._core_loop_host.set_meta("recognizable_sound_families", (layer.get("sound_families", {}) as Dictionary))
		office._core_loop_host.set_meta("mastery_feedback", (layer.get("mastery_feedback", {}) as Dictionary))


func _apply_consolidated_game_loop_presentation(layer: Dictionary) -> void:
	if layer.is_empty():
		return
	var cue := layer.get("unified_cue", {}) as Dictionary
	if office._management_presence != null:
		office._management_presence.apply_consolidated_loop_state(layer)
	if office._top_hud_panel != null:
		office._top_hud_panel.set_meta("canonical_game_loop", layer)
	if office._core_loop_host != null:
		office._core_loop_host.tooltip_text = "NOW  %s\nWHY  %s\nREWARD  %s" % [
			String(cue.get("now", "OBSERVE")),
			String(cue.get("why", "MOVE THE SHIFT")),
			String(cue.get("reward", "VISIBLE RESULT")),
		]
		office._core_loop_host.set_meta("canonical", true)
		office._core_loop_host.set_meta("unified_cue", cue)
		office._core_loop_host.set_meta("shift_arc", (layer.get("shift_arc", {}) as Dictionary))
	if office._guidance_action_button != null:
		office._guidance_action_button.set_meta("now_why_reward", cue)
		office._guidance_action_button.set_meta("one_primary_action", true)
	if office._routing_ui != null:
		office._routing_ui.set_meta("chicken_identities", (layer.get("chicken_identities", {}) as Dictionary))
		office._routing_ui.set_meta("flock_pairings", (layer.get("flock_pairings", {}) as Dictionary))
		office._routing_ui.set_meta("hero_case", (layer.get("hero_case", {}) as Dictionary))
	if office._active_playbook_button != null:
		office._active_playbook_button.set_meta("canonical_game_loop", layer)
		office._active_playbook_button.set_meta("management_build", (layer.get("management_build", {}) as Dictionary))
		office._active_playbook_button.set_meta("rival_counterplay", (layer.get("rival_counterplay", {}) as Dictionary))
	if office._reward_loop_host != null:
		office._reward_loop_host.set_meta("three_level_cadence", (layer.get("reward_cadence", {}) as Dictionary))
	if office._directive_badge != null:
		office._directive_badge.set_meta("hero_case", (layer.get("hero_case", {}) as Dictionary))
		office._directive_badge.set_meta("management_build", (layer.get("management_build", {}) as Dictionary))


func _apply_professional_gameplay_completion_presentation(layer: Dictionary) -> void:
	if layer.is_empty():
		return
	var attention := layer.get("attention_choreography", {}) as Dictionary
	if office._top_hud_panel != null:
		office._top_hud_panel.set_meta("professional_gameplay_completion", layer)
		office._top_hud_panel.set_meta("attention_choreography", attention)
	if office._routing_ui != null:
		if office._routing_ui.has_method("apply_professional_completion_state"):
			office._routing_ui.apply_professional_completion_state(layer, true)
		else:
			office._routing_ui.set_meta("professional_gameplay_completion", layer)
	if office._guidance_action_button != null:
		office._guidance_action_button.set_meta("attention_focus_id", String(attention.get("focus_id", "plan")))
		office._guidance_action_button.set_meta("required_shortcut_count", 0)
		office._guidance_action_button.set_meta("interaction_chain", (layer.get("interaction_chain", {}) as Dictionary))
	if office._active_playbook_button != null:
		office._active_playbook_button.set_meta("delegation", (layer.get("delegation", {}) as Dictionary))
		office._active_playbook_button.set_meta("pair_ability", (layer.get("pair_ability", {}) as Dictionary))
		office._active_playbook_button.set_meta("what_if_planning", (layer.get("what_if_planning", {}) as Dictionary))
	if office._rival_pulse_label != null:
		office._rival_pulse_label.set_meta("visible_rival_race", (layer.get("rival_race", {}) as Dictionary))
	if office._reward_loop_host != null:
		office._reward_loop_host.set_meta("reward_readiness", (layer.get("reward_readiness", {}) as Dictionary))
		office._reward_loop_host.set_meta("celebration_choice", (layer.get("celebration_choice", {}) as Dictionary))
	if office._directive_badge != null:
		office._directive_badge.set_meta("authored_hero_case", (layer.get("hero_case", {}) as Dictionary))
		office._directive_badge.set_meta("next_shift_hook", (layer.get("next_shift_hook", {}) as Dictionary))


func _apply_intuitive_rewarding_completion_presentation(layer: Dictionary) -> void:
	if layer.is_empty():
		return
	var cue := layer.get("now_why_reward", {}) as Dictionary
	if office._top_hud_panel != null:
		office._top_hud_panel.set_meta("intuitive_rewarding_completion", layer)
		office._top_hud_panel.set_meta("compact_hierarchy", (layer.get("compact_hierarchy", {}) as Dictionary))
	if office._guidance_action_button != null:
		office._guidance_action_button.set_meta("concise_cue", cue)
		office._guidance_action_button.set_meta("word_budget", int(cue.get("word_budget", 6)))
	if office._active_playbook_button != null:
		office._active_playbook_button.set_meta("partnership_growth", (layer.get("partnership_growth", {}) as Dictionary))
		office._active_playbook_button.set_meta("availability_explanations", (layer.get("availability", {}) as Dictionary))
	if office._rival_pulse_label != null:
		office._rival_pulse_label.set_meta("rival_memory", (layer.get("rival", {}) as Dictionary))
	if office._routing_ui != null:
		office._routing_ui.set_meta("world_action_preview", (layer.get("world_action_preview", {}) as Dictionary))
		office._routing_ui.set_meta("automation_world_behavior", (layer.get("automation", {}) as Dictionary))
	if office._reward_loop_host != null:
		office._reward_loop_host.set_meta("collection_cabinet", (layer.get("collection_cabinet", {}) as Dictionary))
		office._reward_loop_host.set_meta("strategy_celebration", (layer.get("celebration", {}) as Dictionary))


func _apply_cohesive_game_loop_advancement_presentation(layer: Dictionary) -> void:
	## Reuse the existing progressive-disclosure surfaces. This layer is a
	## connective contract, not a new panel or a second way to issue commands.
	if layer.is_empty():
		return
	if office._top_hud_panel != null:
		office._top_hud_panel.set_meta("cohesive_game_loop_advancement", layer)
		office._top_hud_panel.set_meta("subtraction_guard", (layer.get("subtraction_guard", {}) as Dictionary))
		office._top_hud_panel.set_meta("content_cadence", (layer.get("content_cadence", {}) as Dictionary))
	if office._guidance_action_button != null:
		office._guidance_action_button.set_meta("icon_curriculum", (layer.get("icon_curriculum", {}) as Dictionary))
		office._guidance_action_button.set_meta("first_shift_story", (layer.get("first_shift_story", {}) as Dictionary))
	if office._explain_strip != null:
		office._explain_strip.set_meta("persistent_why_inspection", (layer.get("why_inspection", {}) as Dictionary))
	if office._active_playbook_button != null:
		office._active_playbook_button.set_meta("flow_cash_out", (layer.get("flow_cash_out", {}) as Dictionary))
		office._active_playbook_button.set_meta("contract_draft", (layer.get("contract_draft", {}) as Dictionary))
		office._active_playbook_button.set_meta("end_shift_allocation", (layer.get("end_shift_allocation", {}) as Dictionary))
		office._active_playbook_button.set_meta("hen_dilemmas", (layer.get("hen_dilemmas", {}) as Dictionary))
		office._active_playbook_button.set_meta("relationship_friction", (layer.get("relationship_friction", {}) as Dictionary))
	if office._core_loop_host != null:
		office._core_loop_host.set_meta("bottleneck_board", (layer.get("bottleneck_board", {}) as Dictionary))
		office._core_loop_host.set_meta("resource_tradeoffs", (layer.get("resource_tradeoffs", {}) as Dictionary))
	if office._directive_badge != null:
		office._directive_badge.set_meta("market_conditions", (layer.get("market_conditions", {}) as Dictionary))
		office._directive_badge.set_meta("rival_boss_shift", (layer.get("rival_boss_shift", {}) as Dictionary))
	if office._reward_loop_host != null:
		office._reward_loop_host.set_meta("upgrade_branches", (layer.get("upgrade_branches", {}) as Dictionary))
		office._reward_loop_host.set_meta("physical_transformations", (layer.get("physical_transformations", {}) as Dictionary))
		office._reward_loop_host.set_meta("strategy_endings", (layer.get("strategy_endings", {}) as Dictionary))


func _apply_professional_polish_presentation(layer: Dictionary) -> void:
	if layer.is_empty():
		return
	var experiential := layer.get("experiential_polish", {}) as Dictionary
	var next_level := experiential.get("next_level_polish", {}) as Dictionary
	var mastery_polish := next_level.get("core_loop_mastery_polish", {}) as Dictionary
	var spotlight := layer.get("action_spotlight", {}) as Dictionary
	var payoff := layer.get("payoff_countdown", {}) as Dictionary
	if office._top_hud_panel != null:
		office._top_hud_panel.set_meta("professional_polish", layer)
		office._top_hud_panel.set_meta("experiential_polish", experiential)
		office._top_hud_panel.set_meta("core_loop_mastery_polish", mastery_polish)
		office._top_hud_panel.set_meta("reaction_first_feedback", (layer.get("reaction_first_feedback", {}) as Dictionary))
		office._top_hud_panel.set_meta("adaptive_information_density", (layer.get("adaptive_information_density", {}) as Dictionary))
		office._top_hud_panel.set_meta("contextual_hud", (experiential.get("contextual_hud", {}) as Dictionary))
		office._top_hud_panel.set_meta("audiovisual_grammar", (experiential.get("audiovisual_grammar", {}) as Dictionary))
	if office._guidance_action_button != null:
		office._guidance_action_button.set_meta("contextual_action_spotlight", spotlight)
		office._guidance_action_button.set_meta("before_after_preview", (layer.get("before_after_preview", {}) as Dictionary))
		office._guidance_action_button.set_meta("direct_file_manipulation", (layer.get("direct_file_manipulation", {}) as Dictionary))
		office._guidance_action_button.set_meta("animated_consequence_preview", (experiential.get("animated_consequence_preview", {}) as Dictionary))
		office._guidance_action_button.set_meta("visible_reward_runway", (experiential.get("visible_reward_runway", {}) as Dictionary))
	if office._routing_ui != null:
		if office._routing_ui.has_method("apply_professional_polish_state"):
			office._routing_ui.apply_professional_polish_state(layer, true)
		else:
			office._routing_ui.set_meta("professional_polish", layer)
	if office._core_loop_host != null:
		office._core_loop_host.set_meta("progressive_onboarding", (layer.get("progressive_onboarding", {}) as Dictionary))
		office._core_loop_host.set_meta("session_progression", (layer.get("session_progression", {}) as Dictionary))
		office._core_loop_host.set_meta("silent_tutorial_file", (experiential.get("silent_tutorial_file", {}) as Dictionary))
		office._core_loop_host.set_meta("dynamic_pacing_director", (experiential.get("dynamic_pacing", {}) as Dictionary))
	if office._active_playbook_button != null:
		office._active_playbook_button.set_meta("decision_spikes", (mastery_polish.get("decision_spikes", {}) as Dictionary))
		office._active_playbook_button.set_meta("recovery_bargains", (mastery_polish.get("recovery_bargains", {}) as Dictionary))
		office._active_playbook_button.set_meta("personal_chicken_objectives", (layer.get("personal_objectives", {}) as Dictionary))
		office._active_playbook_button.set_meta("partnership_choreography", (layer.get("partnership_choreography", {}) as Dictionary))
		office._active_playbook_button.set_meta("failure_recovery", (layer.get("failure_recovery", {}) as Dictionary))
		office._active_playbook_button.set_meta("tactical_dilemmas", (layer.get("tactical_dilemmas", {}) as Dictionary))
		office._active_playbook_button.set_meta("signature_chicken_abilities", (experiential.get("signature_abilities", {}) as Dictionary))
		office._active_playbook_button.set_meta("personal_hen_stories", (experiential.get("personal_hen_stories", {}) as Dictionary))
		office._active_playbook_button.set_meta("short_challenge_dockets", (experiential.get("challenge_dockets", {}) as Dictionary))
		office._active_playbook_button.set_meta("safe_experimentation", (experiential.get("safe_experimentation", {}) as Dictionary))
	if office._shift_egg_goal_label != null:
		office._shift_egg_goal_label.set_meta("professional_payoff_countdown", payoff)
	if office._directive_badge != null:
		office._directive_badge.set_meta("one_sentence_shift_identity", (layer.get("shift_identity", {}) as Dictionary))
		office._directive_badge.set_meta("next_shift_tease", (layer.get("next_shift_tease", {}) as Dictionary))
		office._directive_badge.set_meta("dramatic_hero_files", (experiential.get("dramatic_hero_files", {}) as Dictionary))
	if office._rival_pulse_label != null:
		office._rival_pulse_label.set_meta("professional_rival_presence", (layer.get("rival_presence", {}) as Dictionary))
		office._rival_pulse_label.set_meta("consequential_rival_memory", (layer.get("rival_memory", {}) as Dictionary))
		office._rival_pulse_label.set_meta("rival_office_visualization", (experiential.get("rival_office", {}) as Dictionary))
	if office._reward_loop_host != null:
		office._reward_loop_host.set_meta("professional_collection_cabinet", (layer.get("collection_cabinet", {}) as Dictionary))
		office._reward_loop_host.set_meta("professional_strategy_celebration", (layer.get("strategy_celebration", {}) as Dictionary))
		office._reward_loop_host.set_meta("strategy_defining_upgrades", (layer.get("strategy_defining_upgrades", {}) as Dictionary))
		office._reward_loop_host.set_meta("transformative_office_upgrades", (experiential.get("transformative_upgrades", {}) as Dictionary))
		office._reward_loop_host.set_meta("tactile_collection_display", (experiential.get("tactile_collection", {}) as Dictionary))
		office._reward_loop_host.set_meta("strategy_shaped_celebrations", (experiential.get("strategy_celebrations", {}) as Dictionary))


func _refresh_active_playbook_menu(playbook: Dictionary, focused_worker_id: int) -> void:
	if office._active_playbook_button == null:
		return
	office._active_playbook_focused_worker_id = focused_worker_id
	var running := (
		office._simulation != null
		and office._simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
	)
	var strategy_preset_id := String(playbook.get("strategy_preset_id", ""))
	var playbook_contract := playbook.get("contract", {}) as Dictionary
	var plan_filed := not strategy_preset_id.is_empty() or not String(playbook_contract.get("id", "")).is_empty()
	var options := playbook.get("options", []) as Array
	var contextual_power_ready := false
	for option_value in options:
		if not option_value is Dictionary:
			continue
		var option := option_value as Dictionary
		if (
			String(option.get("kind", "")) in ["signature", "teamwork", "partnership", "rescue", "automation", "automation_policy", "intervention"]
			and bool(option.get("available", false))
		):
			contextual_power_ready = true
			break
	office._active_playbook_button.visible = running and (plan_filed or contextual_power_ready or office._first_clutch_reinvestment_resolved())
	office._active_playbook_button.disabled = not running
	if not running:
		return
	var primary_kind := ""
	var opening_lessons := office._simulation.day == 1 and office._simulation.eggs_today < 3
	var priorities := ["reward", "rescue", "push_luck", "hero_case", "partnership", "episode", "proposal", "recovery", "preset", "customize", "contract", "loadout", "preparation", "modifier", "rival", "side_goal", "automation", "automation_policy", "toy", "display", "challenge"]
	if opening_lessons:
		priorities = ["reward", "rescue", "preset", "customize", "contract", "loadout", "preparation"]
	for priority_kind in priorities:
		for option_value in options:
			if (
				option_value is Dictionary
				and String((option_value as Dictionary).get("kind", "")) == priority_kind
				and bool((option_value as Dictionary).get("available", false))
			):
				primary_kind = priority_kind
				break
		if not primary_kind.is_empty():
			break
	var display_options: Array[Dictionary] = []
	for option_value in options:
		if not option_value is Dictionary:
			continue
		var option := option_value as Dictionary
		var kind := String(option.get("kind", ""))
		if (
			(kind == primary_kind and bool(option.get("available", false)))
			or (kind == "practice" and bool(option.get("available", false)))
			or (kind in ["signature", "teamwork", "partnership", "intervention"] and bool(option.get("available", false)))
		):
			display_options.append(option)
	# Only menu choices and their labels can require rebuilding popup items.
	# Live progress still updates the PLAN tooltip below on every snapshot.
	var ready_kind := ""
	for option in display_options:
		if bool(option.get("available", false)):
			ready_kind = String(option.get("kind", "play"))
			break
	var menu_state: Array = [
		focused_worker_id, display_options, office._first_clutch_reinvestment_resolved(),
		office._personal_goal, office._simulation.day, office._simulation.cracked_today,
	]
	if menu_state != office._active_playbook_menu_state:
		office._active_playbook_menu_state = menu_state.duplicate(true)
		office._active_playbook_menu_build_count += 1
		office._active_playbook_menu_map.clear()
		var popup := office._active_playbook_button.get_popup()
		popup.clear()
		var item_id := 100
		var previous_kind := ""
		for option in display_options:
			var kind := String(option.get("kind", "play"))
			if not previous_kind.is_empty() and kind != previous_kind:
				popup.add_separator()
			previous_kind = kind
			var available := bool(option.get("available", false))
			var goal_active: bool = office._personal_goal.get("status", "") == "active" and int(office._personal_goal.get("day", -1)) == office._simulation.day
			var recommended_mark := "TRY · " if bool(option.get("recommended", false)) and not goal_active else ""
			var label := "%s%s  ·  %s" % [
				recommended_mark,
				kind.replace("_", " ").to_upper(),
				String(option.get("label", "PLAY")),
			]
			if kind == "preset":
				var preset := DepartmentSimulation.PLAYBOOK_STRATEGY_PRESET_DEFINITIONS.get(StringName(option.get("id", "")), {}) as Dictionary
				var plain_plans := {"fast": "FASTER EGGS · more fragile", "safe": "SAFER SHELLS · slower work", "flock": "HAPPIER HENS · $2, slightly slower"}
				label = recommended_mark + String(plain_plans.get(String(option.get("id", "")), preset.get("label", "PLAN")))
				if goal_active and not Office.PersonalShiftGoal.is_unreachable(office._personal_goal, {"day": office._simulation.day, "cracked_today": office._simulation.cracked_today}) and String(option.get("id", "")) == String(Office.PersonalShiftGoal.strategy(office._personal_goal).get("id", "")):
					label = "YOUR GOAL · " + label
			popup.add_icon_item(
				Office.ManagementUIThemeScript.action_icon(
					_playbook_menu_icon(StringName(option.get("icon", &"goal")))
				),
				label,
				item_id,
			)
			var item_index := popup.get_item_index(item_id)
			popup.set_item_disabled(item_index, not available)
			popup.set_item_tooltip(item_index, String(option.get("detail", option.get("reason", ""))))
			if kind == "preset":
				var exact_plan := DepartmentSimulation.PLAYBOOK_STRATEGY_PRESET_DEFINITIONS.get(StringName(option.get("id", "")), {}) as Dictionary
				popup.set_item_tooltip(item_index, "%s\n%s · %s\n%s" % [String(exact_plan.get("label", "PLAN")), String(exact_plan.get("gain", "")), String(exact_plan.get("cost", "")), String(option.get("detail", option.get("reason", "")))])
			popup.set_item_metadata(item_index, option.duplicate(true))
			office._active_playbook_menu_map[item_id] = option.duplicate(true)
			item_id += 1
		if office._first_clutch_reinvestment_resolved():
			popup.add_separator()
			popup.add_item("LEARN A CHECK-IN · OPTIONAL", item_id)
			popup.set_item_tooltip(popup.item_count - 1, "Compare a hen's care choices and prices. Opening this lesson spends nothing. Replay it anytime here.")
			office._active_playbook_menu_map[item_id] = {"kind": "learn_care", "id": "care"}
	var contract := playbook.get("contract", {}) as Dictionary
	var combo := playbook.get("combo", {}) as Dictionary
	var combo_recipe := playbook.get("combo_recipe", {}) as Dictionary
	var prediction := playbook.get("prediction_score", {}) as Dictionary
	var side_goal := playbook.get("side_goal", {}) as Dictionary
	var hero_case := playbook.get("hero_case", {}) as Dictionary
	var automation_report := playbook.get("automation_report", {}) as Dictionary
	var plan_labels: Array[String] = []
	for step_value in playbook.get("shift_journey", []):
		if step_value is Dictionary:
			plan_labels.append(String((step_value as Dictionary).get("label", "STEP")))
	var detail_lines: Array[String] = []
	if not plan_labels.is_empty():
		detail_lines.append(" → ".join(plan_labels))
	detail_lines.append("%s  %d/%d" % [
		String(contract.get("label", "PICK CONTRACT")),
		int(contract.get("progress", 0)),
		int(contract.get("target", 0)),
	])
	detail_lines.append("%s  %d/%d  ·  %s" % [
		String(combo.get("label", "BUILD COMBO")),
		int(combo.get("progress", 0)),
		int(combo.get("target", 0)),
		String(combo.get("effect", "")),
	])
	if not combo_recipe.is_empty():
		detail_lines.append("%s  %d/%d  ·  %s" % [
			String(combo_recipe.get("label", "COMBO RECIPE")),
			int(combo_recipe.get("completed_steps", 0)),
			int(combo_recipe.get("total_steps", 2)),
			String(combo_recipe.get("effect", "VISIBLE BONUS")),
		])
	if not prediction.is_empty() and int(prediction.get("target", 0)) > 0:
		detail_lines.append("PREDICTION  ·  %s  ·  %d/%d" % [
			String(prediction.get("verdict", "BUILDING")),
			int(prediction.get("progress", 0)),
			int(prediction.get("target", 0)),
		])
	if not String(side_goal.get("id", "")).is_empty():
		detail_lines.append("%s  %d/%d" % [
			String(side_goal.get("label", "SIDE GOAL")),
			int(side_goal.get("progress", 0)),
			int(side_goal.get("target", 0)),
		])
	if bool(hero_case.get("active", false)):
		detail_lines.append("HERO FILE  ·  %s" % String(hero_case.get("label", "READY")))
	if bool(automation_report.get("available", false)):
		detail_lines.append("AUTO  ·  %d HANDLED  ·  %d%% CLEAN" % [
			int(automation_report.get("handled", 0)),
			int(automation_report.get("clean_rate_percent", 0)),
		])
	var manager_intervention := playbook.get("manager_intervention", {}) as Dictionary
	if not bool(manager_intervention.get("used", false)):
		detail_lines.append("INTERVENTION READY  ·  ONE / SHIFT")
	var last_receipt := playbook.get("last_receipt", {}) as Dictionary
	if not last_receipt.is_empty():
		detail_lines.append("LAST  ·  %s" % String(last_receipt.get("outcome", "PLAY FILED")))
	office._active_playbook_button.visible = running and (plan_filed or contextual_power_ready or office._first_clutch_reinvestment_resolved())
	office._active_playbook_button.text = "PLAN  [Q]"
	office._active_playbook_button.set_meta("opportunity", ready_kind)
	office._active_playbook_button.icon = Office.ManagementUIThemeScript.action_icon(
		&"rank_crest" if ready_kind == "reward" else &"ledger"
	)
	office._active_playbook_button.tooltip_text = "\n".join(detail_lines)
	office._active_playbook_button.set_meta("base_mastery_text", office._active_playbook_button.text)
	office._active_playbook_button.set_meta("base_mastery_tooltip", office._active_playbook_button.tooltip_text)
	office._active_playbook_button.accessibility_name = (
		"Active shift playbook. Core actions: Inspect, Route, Help, Peck, Invest. %s. Open to compare gain, cost, and risk."
		% " ".join(detail_lines)
	)
	office._active_playbook_button.set_meta("authoritative", true)
	office._active_playbook_button.set_meta("playbook", playbook.duplicate(true))
	office._active_playbook_button.set_meta("option_count", display_options.size())
	office._active_playbook_button.set_meta("total_option_count", options.size())
	office._active_playbook_button.set_meta("primary_kind", primary_kind)
	office._active_playbook_button.set_meta(
		"dominant_objective",
		(playbook.get("dominant_objective", {}) as Dictionary).duplicate(true),
	)
	office._active_playbook_button.set_meta("prediction_score", prediction.duplicate(true))
	office._active_playbook_button.set_meta("combo_recipe", combo_recipe.duplicate(true))
	office._active_playbook_button.set_meta("hero_case", hero_case.duplicate(true))
	office._active_playbook_button.set_meta("automation_report", automation_report.duplicate(true))
	_refresh_shift_challenge_goal(playbook)


func _playbook_menu_icon(icon_kind: StringName) -> StringName:
	match icon_kind:
		&"shield": return &"receipt_shell"
		&"route": return &"order_trays"
		&"sync", &"flock": return &"receipt_hen"
		&"care": return &"receipt_flock"
		&"cash": return &"receipt_fund"
		&"egg": return &"order_clutch"
		&"golden": return &"score_gain"
		&"rival": return &"order_favor"
		&"facility": return &"requisitions"
	return &"rank_crest"


func _refresh_shift_challenge_goal(playbook: Dictionary) -> void:
	if office._active_playbook_button == null:
		return
	var contract := playbook.get("contract", {}) as Dictionary
	var id := String(contract.get("id", ""))
	if id.is_empty():
		return
	var complete := bool(contract.get("complete", false))
	var claimed := not String(contract.get("reward_id", "")).is_empty()
	var count := mini(int(contract.get("progress", 0)), int(contract.get("target", 0)))
	# Keep this navigation label stable as optional challenge progress changes.
	office._active_playbook_button.text = "PLAN! [Q]" if complete and not claimed else "PLAN [Q]"
	office._active_playbook_button.tooltip_text = "%s\n%d / %d · %s" % [String(contract.get("goal", ShiftChallengeUI.GOALS.get(id, "Shift challenge"))), count, int(contract.get("target", 0)), "Reward claimed. Press Q for your workshop." if claimed else "Goal earned! Press Q to choose your reward." if complete else "Complete for a reward and workshop progress."]
	var workshop := playbook.get("workshop", {}) as Dictionary
	office._active_playbook_button.tooltip_text += "\nTOOL: %s · %d STAMPS\n%s" % [String(workshop.get("equipped_label", "NO TOOL")), int(workshop.get("stamps", 0)), String(workshop.get("horizon", ""))]
	office._active_playbook_button.accessibility_name = office._active_playbook_button.tooltip_text
	var celebration_key := "%d:%s" % [int(playbook.get("day", 0)), id]
	if complete and not claimed and office._celebrated_shift_challenge != celebration_key:
		office._celebrated_shift_challenge = celebration_key
		office._publish_status_copy("CHALLENGE COMPLETE!  Press Q to choose your reward.", true)
		if office._audio_feedback != null:
			office._audio_feedback.play_commendation()
		if office._office_atmosphere != null:
			office._office_atmosphere.pulse_strategy_reward()
		office._queue_campaign_checkpoint("shift_challenge_earned")


func _next_action_diagnostic_state() -> Dictionary:
	var held_confirmation_action := office._active_held_confirmation_primary_action_state()
	if not held_confirmation_action.is_empty():
		return held_confirmation_action
	if office._settings_ui != null:
		var settings_action: Dictionary = office._settings_ui.primary_action_state()
		if not settings_action.is_empty():
			return settings_action
	var management_overlay_action := office._management_overlay_primary_action_state()
	if not management_overlay_action.is_empty():
		return management_overlay_action
	var decision_action := office._decision_primary_action_state()
	if not decision_action.is_empty():
		return decision_action
	var campaign_action := office._campaign_modal_primary_action_state()
	if not campaign_action.is_empty():
		return campaign_action
	var flockwatch_action := office._flockwatch_context_primary_action_state()
	if not flockwatch_action.is_empty():
		return flockwatch_action
	return {
		"copy": office._guidance_label.text if office._guidance_label != null else "",
		"action_id": String(office._guidance_action_id),
		"actionable": office._guidance_action_id != &"",
		"semantic_icon": (
			String(office._guidance_icon.get_meta("semantic_icon", "goal"))
			if office._guidance_icon != null else
			"goal"
		),
		"icon_visible": (
			office._guidance_icon.is_visible_in_tree()
			if office._guidance_icon != null else
			false
		),
		"accessible_text": (
			String(office._guidance_action_button.get_meta("accessible_text", ""))
			if office._guidance_action_button != null else
			""
		),
		"activation_behavior": (
			String(office._guidance_action_button.get_meta("activation_behavior", "none"))
			if office._guidance_action_button != null else
			"none"
		),
	}


func _apply_attention_focus(action_id: StringName) -> void:
	var active := action_id != &""
	if office._guidance_action_button != null:
		office._guidance_action_button.set_meta("attention_mode_active", active)
		office._guidance_action_button.set_meta("primary_action_id", String(action_id))
	if office._core_loop_host != null:
		office._core_loop_host.modulate.a = 0.66 if active else 1.0
	if office._reward_loop_host != null:
		var reward_action := action_id in [&"review", &"campaign_report_continue"]
		office._reward_loop_host.modulate.a = 1.0 if reward_action or not active else 0.54
	if office._flockwatch_toggle != null:
		office._flockwatch_toggle.modulate.a = 0.72 if active else 1.0


func _pulse_action_target(target: Control) -> void:
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		return
	if office._prefers_reduced_motion():
		target.modulate = Color.WHITE
		return
	target.modulate = Color("ffe6a0")
	var tween := office._presentation_tween(target)
	tween.tween_property(target, "modulate", Color.WHITE, 0.34)
