extends SceneTree

const PlayerPreferencesStoreScript := preload("res://core/settings/player_preferences_store.gd")
const OfficeActionCatalogScript := preload("res://core/settings/office_action_catalog.gd")
const TEST_PREFERENCES_FILENAME := "settings_office_integration_test.json"


class FailingPreferenceStore:
	extends RefCounted
	var last_error := "simulated verified-write failure"

	func save_preferences(_preferences: Dictionary) -> bool:
		return false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var preferences_store = PlayerPreferencesStoreScript.new(TEST_PREFERENCES_FILENAME)
	preferences_store.delete_preferences()
	var office := Office.new()
	office.set("_preferences_store", preferences_store)
	root.add_child(office)
	await process_frame
	await process_frame

	var settings := office.find_child("PlayerSettings", true, false) as PeckingOrderSettingsUI
	var open_button := office.find_child("OpenSettingsButton", true, false) as Button
	var speed_control := office.find_child("SimulationSpeedControl", true, false) as HBoxContainer
	var career_category := office.find_child("SettingsCategory_Career", true, false) as Button
	var controls_category := office.find_child("SettingsCategory_Controls", true, false) as Button
	var controller := office.find_child("ManagementCameraController", true, false) as ManagementCameraController
	var atmosphere := office.find_child("OfficeAtmosphere", true, false) as OfficeAtmosphere
	var audio_feedback := office.find_child("OfficeAudioFeedback", true, false) as OfficeAudioFeedback
	var audio_director := office.find_child("OfficeAudioDirector", true, false) as OfficeAudioDirector
	var simulation := office.get("_simulation") as DepartmentSimulation
	var character_dialogue_ui := office.find_child(
		"CharacterDialogueUI",
		true,
		false,
	) as CharacterDialogueUI
	var routing := office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	var workstation_feedback := office.find_child("WorkstationFeedback", true, false) as WorkstationFeedback
	var storytelling := office.find_child("OfficeStorytelling", true, false) as OfficeStorytelling
	var sun := office.find_child("OfficeSun", true, false) as DirectionalLight3D
	var ui_root := office.find_child("ManagementUIRoot", true, false) as Control
	var worker_views := office.get("_worker_views") as Dictionary
	var sampled_worker := (
		worker_views.values()[0] as ChickenView
		if not worker_views.is_empty()
		else null
	)
	_check(settings != null and not settings.is_open(), "settings should be integrated but hidden on boot", failures)
	_check(
		open_button != null
		and open_button.focus_mode == Control.FOCUS_ALL
		and "F10" in open_button.text
		and open_button.text == String(open_button.get_meta("compact_text", ""))
		and bool(open_button.get_meta("icon_led_action_mark", false))
		and String(open_button.get_meta("semantic_icon", "")) == "settings_cog"
		and open_button.icon != null
		and String(open_button.get_meta("full_text", "")) in String(open_button.get_meta("accessible_text", "")),
		"the persistent HUD should expose a cog-led keyboard-focusable settings route with its complete authored binding available semantically",
		failures,
	)
	_check(controller != null and atmosphere != null and routing != null, "comfort settings should have live camera, atmosphere, and routing targets", failures)
	_check(audio_feedback != null and audio_director != null and audio_director.fixed_player_count() == 4, "the integrated office should own bounded feedback plus pressure-and-momentum adaptive audio", failures)
	for action: StringName in OfficeActionCatalogScript.managed_actions():
		_check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "%s should have a semantic keyboard/gamepad path" % action, failures)
	var settings_shortcut := InputEventKey.new()
	settings_shortcut.keycode = KEY_F10
	settings_shortcut.physical_keycode = KEY_F10
	settings_shortcut.pressed = true
	var consequence_before := simulation.snapshot()
	var consequence_after := consequence_before.duplicate(true)
	consequence_after["revenue_cents"] = int(consequence_before.get("revenue_cents", 0)) - 500
	consequence_after["quota_target"] = int(consequence_before.get("quota_target", 0)) + 1
	office.call(
		"_spawn_decision_consequence_receipts",
		consequence_before,
		consequence_after,
		{"option_id": &"settings_handoff"},
	)
	var save_before_settings_handoff := simulation.export_save_state()
	var cue_serial_before_settings_handoff := int(audio_feedback.feedback_snapshot().get(
		"cue_serial",
		-1,
	))
	office._unhandled_input(settings_shortcut)
	await process_frame
	await process_frame
	_check(
		settings != null and settings.is_open(),
		"the non-remappable F10 safety route should open Settings above campaign intake",
		failures,
	)
	var archived_settings_receipt := office.get("_latest_action_outcome_receipt") as Dictionary
	_check(
		not bool(archived_settings_receipt.get("visible", true))
		and String(archived_settings_receipt.get("dismissed_by", "")) == "settings"
		and int(archived_settings_receipt.get("retired_panel_count", -1)) == 2
		and (archived_settings_receipt.get("entries", []) as Array).size() == 2
		and office.find_children("ActionOutcomeReceipt_*", "PanelContainer", true, false).is_empty(),
		"Settings should archive lower-priority action semantics and remove every overlapping card",
		failures,
	)
	var audio_after_settings_handoff := audio_feedback.feedback_snapshot()
	_check(
		simulation.export_save_state() == save_before_settings_handoff
		and int(audio_after_settings_handoff.get("cue_serial", -2)) == cue_serial_before_settings_handoff + 1
		and String(audio_after_settings_handoff.get("last_cue", "")) == "ui",
		"Settings handoff should remain save-neutral and add only the existing sheet-open cue",
		failures,
	)
	if settings != null:
		settings.close_requested.emit()
	await process_frame

	if open_button != null:
		open_button.pressed.emit()
	await process_frame
	_check(settings != null and settings.is_open(), "the HUD settings route should open above the campaign title", failures)
	_check(controller != null and not controller.is_processing_unhandled_input(), "settings should suspend camera shortcuts while open", failures)
	if career_category != null:
		career_category.pressed.emit()
	await process_frame
	_check(
		settings != null and settings.active_category() == &"career"
		and String((office.get("_player_preferences") as Dictionary).get("settings_category", "")) == "career"
		and String(preferences_store.load_preferences().get("settings_category", "")) == "career",
		"category navigation should apply immediately and commit through the independent preference store",
		failures,
	)
	if settings != null:
		settings.close_requested.emit()
	await process_frame
	_check(settings != null and not settings.is_open(), "safe return should close settings without changing campaign state", failures)
	_check(controller != null and not controller.is_processing_unhandled_input(), "closing over another modal should preserve that modal's camera lock", failures)

	# Binding capture is an acknowledgement handshake: the UI may only announce
	# success after Office has accepted conflicts and verified the independent
	# preference transaction.
	if open_button != null:
		open_button.pressed.emit()
	await process_frame
	_check(
		settings != null and settings.active_category() == &"career",
		"reopening Settings should restore the last verified category without exposing every group",
		failures,
	)
	if controls_category != null:
		controls_category.pressed.emit()
	var peck_binding := office.find_child("Binding_peck_assist", true, false) as Button
	var pause_binding := office.find_child("Binding_pause_simulation", true, false) as Button
	var settings_status := office.find_child("SettingsStatus", true, false) as Label
	var q_event := InputEventKey.new()
	q_event.physical_keycode = KEY_Q
	q_event.pressed = true
	if peck_binding != null:
		peck_binding.pressed.emit()
	if settings != null:
		settings._input(q_event)
	_check(
		settings != null and settings.capture_action() == &""
		and settings_status != null and settings_status.text == "Control binding filed and saved."
		and peck_binding != null and "Q" in peck_binding.text
		and preferences_store.has_preferences(),
		"Office should acknowledge a binding only after the verified preference file commits",
		failures,
	)
	if pause_binding != null:
		pause_binding.pressed.emit()
	if settings != null:
		settings._input(q_event)
	_check(
		settings != null and settings.capture_action() == &"pause_simulation"
		and not settings.binding_capture_pending()
		and settings_status != null and "Binding held:" in settings_status.text
		and "different key or button" in settings_status.text,
		"a conflicting Office binding should preserve its rejection and remain armed for retry",
		failures,
	)
	var cancel_event := InputEventAction.new()
	cancel_event.action = &"ui_cancel"
	cancel_event.pressed = true
	if settings != null:
		settings._input(cancel_event)

	# A failed verified write must roll runtime InputMap and preferences back to Q,
	# then explicitly reject the pending UI request instead of reporting success.
	office.set("_preferences_store", FailingPreferenceStore.new())
	var f6_event := InputEventKey.new()
	f6_event.physical_keycode = KEY_F6
	f6_event.pressed = true
	if peck_binding != null:
		peck_binding.pressed.emit()
	if settings != null:
		settings._input(f6_event)
	_check(
		settings != null and settings.capture_action() == &"peck_assist"
		and not settings.binding_capture_pending()
		and settings_status != null and "simulated verified-write failure" in settings_status.text
		and "Q" in OfficeActionCatalogScript.binding_label(&"peck_assist")
		and "F6" not in OfficeActionCatalogScript.binding_label(&"peck_assist"),
		"failed binding persistence should roll back InputMap and leave the same action armed",
		failures,
	)
	if settings != null:
		settings._input(cancel_event)
		settings.close_requested.emit()
	await process_frame

	var original := (office.get("_player_preferences") as Dictionary).duplicate(true)
	var comfort := PlayerPreferencesStoreScript.defaults()
	comfort["motion_mode"] = "reduced"
	comfort["camera_motion"] = "reduced"
	comfort["camera_sensitivity"] = "high"
	comfort["ui_scale"] = 1.5
	comfort["high_contrast"] = true
	comfort["color_vision_mode"] = "color_blind_safe"
	comfort["visual_quality"] = "low"
	comfort["timing_assist"] = "extended"
	comfort["notice_level"] = "priority"
	comfort["notice_duration"] = "extended"
	comfort["effect_level"] = "reduced"
	comfort["particle_level"] = "off"
	comfort["animation_speed"] = "brisk"
	comfort["tooltip_delay"] = "short"
	comfort["haptics_enabled"] = false
	comfort["pause_when_unfocused"] = true
	(comfort.get("audio", {}) as Dictionary)["ambient"] = {"volume": 0.37, "muted": true}
	(comfort.get("audio", {}) as Dictionary)["alerts"] = {"volume": 0.21, "muted": true}
	(comfort.get("audio", {}) as Dictionary)["voice"] = {"volume": 0.46, "muted": false}
	office.set("_player_preferences", comfort)
	office.call("_apply_player_preferences")
	await process_frame
	_check(
		open_button != null
		and speed_control != null
		and bool(open_button.get_meta("compact_action_mark", false))
		and open_button.text == String(open_button.get_meta("compact_text", ""))
		and open_button.text == "SETTINGS  [F10]"
		and " / " not in open_button.text
		and " / " in String(open_button.get_meta("full_text", ""))
		and String(open_button.get_meta("full_text", "")) in String(open_button.get_meta("accessible_text", ""))
		and "Binding:" in open_button.tooltip_text
		and open_button.get_global_rect().end.x <= speed_control.get_global_rect().position.x - 10.0,
		"150-percent HUD should keep Settings and its primary safety key readable without crowding the speed controls",
		failures,
	)
	var flockwatch_navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	if flockwatch_navigation != null:
		office.call("_set_flockwatch_open", true)
		flockwatch_navigation.set_show_all_filings(true)
		flockwatch_navigation.open_page(FlockwatchNavigation.PAGE_CAPITAL)
		await process_frame
		await process_frame
		var capital_scroll := flockwatch_navigation.page_scroll(
			FlockwatchNavigation.PAGE_CAPITAL
		)
		var capital_content := flockwatch_navigation.page_content(
			FlockwatchNavigation.PAGE_CAPITAL
		)
		var capital_reading_bounds := _scroll_reading_bounds(capital_scroll)
		_check(
			capital_scroll != null
			and capital_content != null
			and capital_content.get_global_rect().end.x
			<= capital_reading_bounds.end.x + 0.5,
			(
				"150-percent Capital filings should clear the vertical scrollbar "
				+ "(content=%s reading_bounds=%s largest=%s)"
			) % [
				capital_content.get_global_rect()
				if capital_content != null else Rect2(),
				capital_reading_bounds,
				_largest_minimum_widths(capital_content),
			],
			failures,
		)
		var clipped_briefing_labels: Array[String] = []
		for label_name: String in [
			"EconomicBriefingHeadline",
			"EconomicBriefingCash",
			"EconomicBriefingCosts",
			"EconomicBriefingMarket",
			"EconomicBriefingBottleneck",
			"EconomicBriefingTrend",
			"EconomicBriefingWatch",
		]:
			var briefing_label := office.find_child(
				label_name,
				true,
				false,
			) as Label
			if (
				briefing_label != null
				and briefing_label.get_visible_line_count()
				< briefing_label.get_line_count()
			):
				clipped_briefing_labels.append(
					"%s:%d/%d size=%s min=%s" % [
						label_name,
						briefing_label.get_visible_line_count(),
						briefing_label.get_line_count(),
						briefing_label.size,
						briefing_label.get_combined_minimum_size(),
					]
				)
		var cash_briefing_label := office.find_child(
			"EconomicBriefingCash",
			true,
			false,
		) as Label
		var market_briefing_label := office.find_child(
			"EconomicBriefingMarket",
			true,
			false,
		) as Label
		_check(
			cash_briefing_label != null
			and cash_briefing_label.get_line_count() > 2
			and market_briefing_label != null
			and market_briefing_label.get_line_count() >= 7,
			(
				"150-percent Capital labels should preserve and wrap their "
				+ "multi-line briefing copy (cash=%d market=%d)"
			) % [
				cash_briefing_label.get_line_count()
				if cash_briefing_label != null else -1,
				market_briefing_label.get_line_count()
				if market_briefing_label != null else -1,
			],
			failures,
		)
		_check(
			clipped_briefing_labels.is_empty(),
			"150-percent Capital briefing should allocate every wrapped line (%s)"
			% ", ".join(clipped_briefing_labels),
			failures,
		)
		var overflowing_capital_controls := _horizontal_overflow_controls(
			capital_content,
			capital_reading_bounds,
		)
		_check(
			overflowing_capital_controls.is_empty(),
			"150-percent Capital descendants should remain inside the scroll viewport (%s)"
			% ", ".join(overflowing_capital_controls),
			failures,
		)
		flockwatch_navigation.set_show_all_filings(false)
		office.call("_set_flockwatch_open", false)
	var effect_snapshot := atmosphere.effect_snapshot()
	var camera_navigation := controller.navigation_state()
	_check(
		bool(controller.get("_reduced_motion"))
		and workstation_feedback != null and workstation_feedback.reduced_motion(),
		"reduced motion should reach the actual camera and workstation feedback controllers",
		failures,
	)
	_check(
		String(camera_navigation.get("camera_motion", "")) == "reduced"
		and String(camera_navigation.get("input_sensitivity", "")) == "high"
		and is_equal_approx(float(camera_navigation.get("input_sensitivity_multiplier", 0.0)), 1.35),
		"independent camera motion and sensitivity should reach the live controller",
		failures,
	)
	_check(bool(controller.get("_high_contrast")), "high contrast should strengthen the world-space focus marker", failures)
	_check(not bool((atmosphere.get("_dust_motes") as GPUParticles3D).emitting), "reduced motion and low detail should stop ambient particles", failures)
	_check(
		String(effect_snapshot.get("level", "")) == "reduced"
		and String(effect_snapshot.get("particle_level", "")) == "off"
		and not bool(effect_snapshot.get("ambient_particles", true))
		and not bool(effect_snapshot.get("event_bursts", true))
		and audio_feedback != null and not audio_feedback.haptics_enabled(),
		"effect density and haptics preferences should reach their live feedback systems",
		failures,
	)
	var passive_mode_before := controller.camera_mode()
	comfort["motion_mode"] = "full"
	comfort["camera_motion"] = "off"
	office.set("_player_preferences", comfort)
	office.call("_apply_player_preferences")
	controller.show_event_focus(Vector3(2.0, 1.0, 2.0), "ACCESSIBILITY PROBE", 0.25, true)
	var motion_off_state := controller.navigation_state()
	_check(
		not bool(controller.get("_reduced_motion"))
		and workstation_feedback != null and not workstation_feedback.reduced_motion()
		and String(motion_off_state.get("camera_motion", "")) == "off"
		and bool(motion_off_state.get("camera_motion_instant", false))
		and controller.camera_mode() == passive_mode_before,
		"camera-motion off should suppress passive reframing without depending on global reduced motion",
		failures,
	)
	_check(
		is_equal_approx(float(camera_navigation.get("animation_speed_multiplier", 0.0)), 1.5)
		and is_equal_approx(float(effect_snapshot.get("animation_speed_multiplier", 0.0)), 1.5)
		and workstation_feedback != null
		and is_equal_approx(workstation_feedback.animation_speed_multiplier(), 1.5)
		and office.get("_management_presence") != null
		and is_equal_approx(
			(office.get("_management_presence") as ManagementPresence).animation_speed_multiplier(),
			1.5,
		)
		and is_equal_approx(
			float(ProjectSettings.get_setting("gui/timers/tooltip_delay_sec", -1.0)),
			0.15,
		),
		"presentation timing should reach camera, world feedback, management, and the live tooltip timer without changing the simulation clock",
		failures,
	)
	_check(sun != null and not sun.shadow_enabled, "performance detail should disable the expensive office sun shadow", failures)
	_check(is_equal_approx(root.scaling_3d_scale, 0.82), "performance detail should lower only the 3D render scale", failures)
	_check(
		int(office.get("_directional_shadow_atlas_size")) == 1024,
		"performance detail should reserve only a small dormant directional atlas",
		failures,
	)
	_check(
		sampled_worker != null
		and is_equal_approx(sampled_worker.presentation_update_rate_hz(), 20.0),
		"performance detail should sample worker presentation at 20 Hz without reducing simulation cadence",
		failures,
	)
	office.call("_apply_visual_quality", &"balanced")
	_check(
		sun != null
		and sun.shadow_enabled
		and sun.directional_shadow_mode == DirectionalLight3D.SHADOW_ORTHOGONAL
		and root.msaa_3d == Viewport.MSAA_DISABLED
		and is_equal_approx(root.scaling_3d_scale, 1.0)
		and int(office.get("_directional_shadow_atlas_size")) == 2048,
		"balanced detail should keep native resolution with one 2048 orthographic shadow map and no MSAA",
		failures,
	)
	_check(
		sampled_worker != null
		and is_equal_approx(sampled_worker.presentation_update_rate_hz(), 30.0),
		"balanced detail should sample authored worker presentation at 30 Hz",
		failures,
	)
	office.call("_apply_visual_quality", &"high")
	_check(
		sun != null
		and sun.shadow_enabled
		and sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		and root.msaa_3d == Viewport.MSAA_4X,
		"high detail should retain the four-split showcase shadow treatment and 4x MSAA",
		failures,
	)
	_check(
		int(office.get("_directional_shadow_atlas_size")) == 4096,
		"high detail should retain the full directional shadow atlas",
		failures,
	)
	_check(
		sampled_worker != null
		and is_equal_approx(sampled_worker.presentation_update_rate_hz(), 0.0),
		"high detail should restore per-frame worker presentation sampling",
		failures,
	)
	office.call("_apply_visual_quality", &"low")
	_check(simulation.peck_assist_timing_profile == &"extended", "motor-timing assistance should reach the authoritative simulation", failures)
	var ambient_bus_index := AudioServer.get_bus_index(&"Ambient")
	var alerts_bus_index := AudioServer.get_bus_index(&"Alerts")
	var voice_bus_index := AudioServer.get_bus_index(&"Voice")
	_check(
		ambient_bus_index >= 0
		and is_equal_approx(AudioServer.get_bus_volume_db(ambient_bus_index), linear_to_db(0.37))
		and AudioServer.is_bus_mute(ambient_bus_index),
		"office ambience should apply its own volume and mute independently from music",
		failures,
	)
	_check(
		alerts_bus_index >= 0
		and is_equal_approx(AudioServer.get_bus_volume_db(alerts_bus_index), linear_to_db(0.21))
		and AudioServer.is_bus_mute(alerts_bus_index)
		and voice_bus_index >= 0
		and is_equal_approx(AudioServer.get_bus_volume_db(voice_bus_index), linear_to_db(0.46))
		and not AudioServer.is_bus_mute(voice_bus_index),
		"warnings and character cutout cues should apply independent persisted mix layers",
		failures,
	)
	if audio_feedback != null:
		audio_feedback.set_focus_paused(true)
		audio_feedback.set_focus_paused(false)
	if character_dialogue_ui != null:
		character_dialogue_ui.dialogue_presented.emit({"speaker_id": "dot"})
	var cutout_audio := (
		audio_feedback.feedback_snapshot()
		if audio_feedback != null else
		{}
	)
	_check(
		character_dialogue_ui != null
		and String(cutout_audio.get("last_cue", "")) == "dialogue_cutout"
		and String(cutout_audio.get("last_bus", "")) == "Voice",
		"presenting a chicken cutout should produce one nonverbal cue on the dedicated character layer",
		failures,
	)
	_check(ui_root != null and ui_root.theme != null and ui_root.theme.get_font_size(&"font_size", &"Button") >= 17, "125 percent UI scale should enlarge default button text", failures)
	_check(
		routing != null and routing.color_vision_mode() == &"color_blind_safe"
		and workstation_feedback != null and workstation_feedback.color_vision_mode() == &"color_blind_safe"
		and storytelling != null and storytelling.color_vision_mode() == &"color_blind_safe",
		"color-blind-safe preference should reach routing, workstation, and egg-quality presentation",
		failures,
	)
	var nest_queue := office.find_child("Queue_nest_damage", true, false) as Label
	var nest_queue_icon := office.find_child("QueueIcon_nest_damage", true, false) as TextureRect
	_check(
		nest_queue != null
		and (
			"[N]" in nest_queue.text
			or (
				nest_queue_icon != null
				and nest_queue_icon.visible
				and String(nest_queue_icon.get_meta("semantic_icon", "")) == "lane_nest"
			)
		),
		"safe palette should add a redundant Nest text marker or enlarged-scale semantic lane mark",
		failures,
	)
	_check(
		_contains_all(
			settings.accessible_text() if settings != null else "",
			["priority peck timing extended", "animation speed brisk", "tooltip delay short"],
		),
		"settings narration should reflect timing assistance and independent presentation pacing",
		failures,
	)
	_check(
		StringName(office.call("_status_priority", "CLOCK LOCKED. Review the open decision.")) == &"action"
		and StringName(office.call("_status_priority", "MILESTONE APPROVED: Training Roost.")) == &"milestone"
		and StringName(office.call("_status_priority", "Mabel routed to Appeals.")) == &"routine",
		"notice classification should label actionable risks, milestones, and routine receipts without relying on color",
		failures,
	)
	_check(
		bool(office.call("_should_present_status_toast", "CLOCK LOCKED. Review the open decision."))
		and not bool(office.call("_should_present_status_toast", "Mabel routed to Appeals.")),
		"priority-only notices should interrupt for actionable filings but archive routine receipts",
		failures,
	)
	office.call("_record_status_copy", "Mabel routed to Appeals.")
	office.call("_record_status_copy", "CLOCK LOCKED. Review the open decision.")
	var notification_diagnostic := office.call("_notification_diagnostic_state") as Dictionary
	var recent_notices := notification_diagnostic.get("recent", []) as Array
	_check(
		recent_notices.size() >= 2
		and String((recent_notices[0] as Dictionary).get("label", "")) == "ACTION"
		and String((recent_notices[1] as Dictionary).get("label", "")) == "ROUTINE",
		"the bounded diagnostic record should preserve newest-first copy with redundant semantic priority labels",
		failures,
	)
	_check(
		String(notification_diagnostic.get("duration", "")) == "extended"
		and int(notification_diagnostic.get("configured_hold_msec", 0)) == 9000,
		"extended notice duration should publish the exact bounded toast hold",
		failures,
	)
	var notice_campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	if notice_campaign_ui != null:
		notice_campaign_ui.hide_modal()
	for notice_surface_name: String in [
		"_decision_host", "_day_review_scrim", "_settings_ui",
		"_capital_blueprint_ui", "_campus_portfolio_ui", "_campus_expansion_ui",
		"_commissioning_reveal_ui", "_campus_portfolio_reveal_ui",
	]:
		var notice_surface := office.get(notice_surface_name) as Control
		if notice_surface != null:
			notice_surface.visible = false
	office.call("_publish_status_copy", "CLOCK LOCKED. Feed Party attendance is still in progress.")
	office.call("_publish_status_copy", "FEED PARTY ALREADY IN PROGRESS. No second morale debit was charged.")
	notification_diagnostic = office.call("_notification_diagnostic_state") as Dictionary
	_check(
		bool(notification_diagnostic.get("toast_visible", false))
		and String(notification_diagnostic.get("toast_priority", "")) == "action"
		and String(notification_diagnostic.get("toast_copy", "")).contains("CLOCK LOCKED")
		and String(notification_diagnostic.get("latest_priority", "")) == "routine"
		and String(notification_diagnostic.get("latest_copy", "")).contains("ALREADY IN PROGRESS"),
		"immediate publication should preserve an actionable toast while archiving a later routine receipt",
		failures,
	)
	office.set("_ticker_hide_at_msec", Time.get_ticks_msec() - 1)
	office.call("_process", 0.0)
	notification_diagnostic = office.call("_notification_diagnostic_state") as Dictionary
	_check(
		not bool(notification_diagnostic.get("toast_visible", true))
		and String(notification_diagnostic.get("latest_priority", "")) == "routine",
		"a held actionable toast should expire at its bounded deadline without being renewed by its restored label",
		failures,
	)
	comfort["notice_level"] = "archive_only"
	office.set("_player_preferences", comfort)
	office.call("_apply_player_preferences")
	_check(
		not bool(office.call("_should_present_status_toast", "CLOCK LOCKED. Review the open decision.")),
		"Shift Record Only should mute even important transient toasts without changing their archive path",
		failures,
	)
	comfort["notice_level"] = "priority"
	office.set("_player_preferences", comfort)
	office.call("_apply_player_preferences")

	# Losing application focus during a live shift should pause only when the
	# default-on safety preference is enabled, then restore the exact prior clock
	# speed after focus returns and no management modal owns the pause.
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var clock := office.get("_clock") as SimulationClock
	if campaign_ui != null:
		campaign_ui.hide_modal()
	for field_name: String in [
		"_decision_host", "_day_review_scrim", "_settings_ui",
		"_capital_blueprint_ui", "_campus_portfolio_ui", "_campus_expansion_ui",
		"_commissioning_reveal_ui", "_campus_portfolio_reveal_ui",
	]:
		var surface := office.get(field_name) as CanvasItem
		if surface != null:
			surface.visible = false
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	_check(not bool(office.call("_blocking_management_surface_open")), "focus-pause fixture should expose an unobstructed live floor", failures)
	clock.set_speed(3)
	office.call("_set_application_focus_paused", true)
	_check(
		clock.speed_index == 0
		and bool(office.get("_focus_pause_active"))
		and int(office.get("_focus_pause_previous_speed")) == 3,
		"focus-loss safety should hold a running shift and remember the exact clock speed",
		failures,
	)
	office.call("_set_application_focus_paused", false)
	_check(
		clock.speed_index == 3
		and not bool(office.get("_focus_pause_active"))
		and int(office.get("_focus_pause_previous_speed")) == 0,
		"focus return should restore the prior speed once and clear its transient receipt",
		failures,
	)
	clock.set_speed(3)
	office.call("_set_application_focus_paused", true)
	if settings != null:
		settings.visible = true
	office.call("_set_application_focus_paused", false)
	_check(
		clock.speed_index == 0 and not bool(office.get("_focus_pause_active")),
		"focus return must not resume behind a management surface that owns the pause",
		failures,
	)
	if settings != null:
		settings.visible = false
	comfort["pause_when_unfocused"] = false
	office.set("_player_preferences", comfort)
	office.call("_apply_player_preferences")
	clock.set_speed(2)
	office.call("_set_application_focus_paused", true)
	_check(
		clock.speed_index == 2 and not bool(office.get("_focus_pause_active")),
		"players who disable focus-loss pausing should retain the running clock",
		failures,
	)

	# Restore this process's prior presentation and input state without writing a
	# preference file; persistence itself has a separate crash-recovery test.
	office.set("_player_preferences", original)
	office.call("_apply_player_preferences")
	await process_frame
	_check(
		open_button.text == String(open_button.get_meta("compact_text", ""))
		and bool(open_button.get_meta("compact_action_mark", false))
		and bool(open_button.get_meta("icon_led_action_mark", false))
		and open_button.icon != null
		and " / " in String(open_button.get_meta("full_text", "")),
		"restoring 100 percent should preserve the cog-led Settings action and complete semantic binding",
		failures,
	)
	office.free()
	await process_frame
	preferences_store.delete_preferences()
	OfficeActionCatalogScript.reset_all()
	if not failures.is_empty():
		for failure: String in failures:
			push_error("SETTINGS_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SETTINGS_OFFICE_INTEGRATION_TEST_PASSED modal=safe categories=host-persisted+restored input=17+camera+ack+rollback+sensitivity audio=feedback+adaptive+ambient+alerts+cutout-cues notices=priority+archive-only+semantic-labels+duration effects=density+particles+motion+camera-motion-off presentation=animation-speed+tooltip-delay haptics=optional focus-pause=restore+opt-out contrast=theme+ring color-vision=palette+symbols detail=live timing=authoritative")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _contains_all(text: String, needles: Array[String]) -> bool:
	var lowered := text.to_lower()
	for needle in needles:
		if needle.to_lower() not in lowered:
			return false
	return true


func _largest_minimum_widths(root_control: Control) -> String:
	if root_control == null:
		return "missing"
	var rows: Array[Dictionary] = []
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
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
	for index: int in mini(8, rows.size()):
		var row := rows[index]
		summaries.append("%s:min=%.1f/size=%.1f" % [
			String(row.get("name", "")),
			float(row.get("minimum", 0.0)),
			float(row.get("width", 0.0)),
		])
	return ", ".join(summaries)


func _horizontal_overflow_controls(
	root_control: Control,
	bounds: Rect2,
) -> Array[String]:
	var overflows: Array[String] = []
	if root_control == null:
		return overflows
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		if (
			rect.position.x < bounds.position.x - 0.5
			or rect.end.x > bounds.end.x + 0.5
		):
			overflows.append("%s:%s" % [control.name, rect])
	return overflows


func _scroll_reading_bounds(scroll: ScrollContainer) -> Rect2:
	if scroll == null:
		return Rect2()
	var bounds := scroll.get_global_rect()
	var vertical_bar := scroll.get_v_scroll_bar()
	if vertical_bar != null and vertical_bar.visible:
		bounds.size.x = maxf(0.0, bounds.size.x - vertical_bar.size.x)
	return bounds
