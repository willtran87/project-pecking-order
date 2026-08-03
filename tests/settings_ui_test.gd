extends SceneTree

const SettingsUIScript := preload("res://features/office/settings_ui.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var harness := Control.new()
	harness.size = Vector2(1280.0, 720.0)
	root.add_child(harness)
	var settings := SettingsUIScript.new() as PeckingOrderSettingsUI
	harness.add_child(settings)
	var observed_preferences: Array[Dictionary] = []
	var observed_bindings: Array[Dictionary] = []
	var observed_backup_imports: Array[String] = []
	var intent_counts := {"close": 0, "reset": 0, "backup_export": 0}
	settings.preferences_changed.connect(
		func(value: Dictionary) -> void: observed_preferences.append(value.duplicate(true))
	)
	settings.binding_capture_requested.connect(
		func(action: StringName, event: InputEvent) -> void:
			observed_bindings.append({"action": action, "event": event})
	)
	settings.close_requested.connect(func() -> void: intent_counts["close"] += 1)
	settings.reset_defaults_requested.connect(func() -> void: intent_counts["reset"] += 1)
	settings.career_backup_export_requested.connect(
		func() -> void: intent_counts["backup_export"] += 1
	)
	settings.career_backup_import_requested.connect(
		func(json_text: String) -> void: observed_backup_imports.append(json_text)
	)
	await process_frame

	_check(not settings.is_open(), "settings should not obstruct the office on boot", failures)
	settings.show_settings(_preferences(), _binding_labels(), true)
	await process_frame
	await process_frame
	_check(settings.is_open(), "show_settings should expose the responsive modal", failures)
	var panel := settings.find_child("SettingsPanel", true, false) as PanelContainer
	var scroll := settings.find_child("SettingsScroll", true, false) as ScrollContainer
	var close := settings.find_child("SettingsCloseButton", true, false) as Button
	var reset := settings.find_child("SettingsResetButton", true, false) as Button
	var audio_category := settings.find_child("SettingsCategory_Audio", true, false) as Button
	var comfort_category := settings.find_child("SettingsCategory_Comfort", true, false) as Button
	var controls_category := settings.find_child("SettingsCategory_Controls", true, false) as Button
	var career_category := settings.find_child("SettingsCategory_Career", true, false) as Button
	_check(panel != null and scroll != null, "settings should use a bounded panel with vertical scrolling", failures)
	_check(close != null and close.focus_mode == Control.FOCUS_ALL, "the safe return should remain keyboard focusable", failures)
	_check(reset != null and reset.focus_mode == Control.FOCUS_ALL, "default restoration should remain keyboard focusable", failures)
	_check(settings.find_children("Binding_*", "Button", true, false).size() == 15, "all fifteen player-remappable floor and camera controls should be visible", failures)
	var pan_left_binding := settings.find_child("Binding_camera_pan_left", true, false) as Button
	var zoom_in_binding := settings.find_child("Binding_camera_zoom_in", true, false) as Button
	_check(
		pan_left_binding != null and "A / Left" in pan_left_binding.text
		and zoom_in_binding != null and "Equal / Kp Add" in zoom_in_binding.text,
		"camera pan and zoom bindings should be visible with both default keyboard paths",
		failures,
	)
	_check(
		audio_category != null and comfort_category != null
		and controls_category != null and career_category != null
		and settings.active_category() == &"comfort"
		and comfort_category.button_pressed
		and settings.find_child("SettingsPage_Comfort", true, false).visible
		and not settings.find_child("SettingsPage_Audio", true, false).visible
		and not settings.find_child("SettingsPage_Controls", true, false).visible
		and not settings.find_child("SettingsPage_Career", true, false).visible,
		"settings should open on one calm category instead of exposing every option at once",
		failures,
	)
	_check(
		_contains_all(settings.accessible_text(), ["comfort & display category, 2 of 4", "motion reduced", "camera motion reduced", "camera input sensitivity low", "125 percent", "high contrast on", "color vision standard", "effect density reduced", "particle density off", "animation speed relaxed", "tooltip delay long", "timing lenient", "transient notices priority for extended duration", "haptics disabled", "pause when unfocused on"])
		and "master 80 percent" not in settings.accessible_text().to_lower(),
		"settings narration should summarize only the active category",
		failures,
	)
	if comfort_category != null:
		comfort_category.grab_focus()
	var next_category := InputEventAction.new()
	next_category.action = &"ui_right"
	next_category.pressed = true
	settings._input(next_category)
	_check(
		settings.active_category() == &"controls"
		and controls_category != null and controls_category.has_focus()
		and not observed_preferences.is_empty()
		and String(observed_preferences.back().get("settings_category", "")) == "controls",
		"Left and Right should change and persist categories while keeping keyboard focus visible",
		failures,
	)

	var backup_export := settings.find_child("CareerBackupExportButton", true, false) as Button
	var backup_import := settings.find_child("CareerBackupImportButton", true, false) as Button
	var backup_confirmation := settings.find_child(
		"CareerBackupImportConfirmation",
		true,
		false,
	) as ConfirmationDialog
	_check(
		backup_export != null and not backup_export.disabled
		and backup_import != null and not backup_import.disabled
		and backup_confirmation != null
		and backup_confirmation.get_label().autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
		and backup_confirmation.get_label().custom_minimum_size.x >= 560.0,
		"career safety should expose focusable export, restore, and confirmation controls",
		failures,
	)
	_check(
		backup_confirmation != null
		and backup_confirmation.theme_type_variation == &"HeldConfirmationDialog"
		and String(backup_confirmation.get_meta("held_confirmation_skin", "")) == "flockwatch_compact"
		and backup_confirmation.has_theme_stylebox_override("embedded_border")
		and backup_confirmation.has_theme_stylebox_override("panel")
		and backup_confirmation.get_ok_button().theme_type_variation == &"DangerButton"
		and backup_confirmation.get_cancel_button().theme_type_variation == &"PrimaryButton"
		and backup_confirmation.get_ok_button().icon != null
		and backup_confirmation.get_cancel_button().icon != null
		and String(backup_confirmation.get_ok_button().get_meta("semantic_icon", ""))
		== "irreversible_warning"
		and String(backup_confirmation.get_cancel_button().get_meta("semantic_icon", ""))
		== "safe_return_arrow",
		"career restore should share the authored compact irreversible-decision skin",
		failures,
	)
	if career_category != null:
		career_category.pressed.emit()
	_check(
		settings.active_category() == &"career"
		and _contains_all(settings.accessible_text(), ["career backup category, 4 of 4", "backup export is available", "explicit replacement confirmation"]),
		"career backup should have its own concise category summary",
		failures,
	)
	if backup_export != null:
		backup_export.pressed.emit()
	_check(
		int(intent_counts["backup_export"]) == 1,
		"backup export should emit one host-owned durability request",
		failures,
	)
	var portable_fixture := "{\"format\":\"pecking_order_campaign\",\"schema_version\":2}"
	_check(
		settings.stage_career_backup_import(portable_fixture, "portable-\ntest.json"),
		"bounded backup text should stage behind confirmation",
		failures,
	)
	await process_frame
	_check(
		backup_confirmation != null and backup_confirmation.visible
		and backup_confirmation.get_cancel_button().has_focus()
		and "portable- test.json" in backup_confirmation.dialog_text
		and "\n" not in backup_confirmation.dialog_text
		and "automatic recovery copy" in backup_confirmation.dialog_text,
		"restore confirmation should name the file, replacement, validation, and rollback",
		failures,
	)
	if backup_confirmation != null:
		backup_confirmation.confirmed.emit()
	_check(
		observed_backup_imports == [portable_fixture],
		"confirmation should emit the exact unmodified backup text once for host validation",
		failures,
	)
	settings.complete_career_backup_import(false, "Career restore held: semantic fixture rejected.")
	_check(
		"semantic fixture rejected" in settings.accessible_text(),
		"host rejection should remain visible and accessible without closing Settings",
		failures,
	)
	settings.stage_career_backup_import(portable_fixture, "cancel-test.json")
	if backup_confirmation != null:
		backup_confirmation.canceled.emit()
	_check(
		observed_backup_imports.size() == 1
		and "current career was not changed" in settings.accessible_text().to_lower(),
		"cancelling restore should clear staged data without emitting another request",
		failures,
	)

	var sfx_slider := settings.find_child("AudioVolume_sfx", true, false) as HSlider
	var music_mute := settings.find_child("AudioMute_music", true, false) as CheckButton
	var ambient_slider := settings.find_child("AudioVolume_ambient", true, false) as HSlider
	var ambient_mute := settings.find_child("AudioMute_ambient", true, false) as CheckButton
	var alerts_slider := settings.find_child("AudioVolume_alerts", true, false) as HSlider
	var voice_mute := settings.find_child("AudioMute_voice", true, false) as CheckButton
	if audio_category != null:
		audio_category.pressed.emit()
	_check(
		settings.active_category() == &"audio"
		and _contains_all(settings.accessible_text(), ["audio mix category, 1 of 4", "master 80 percent", "office hum + flock room tone 55 percent", "warnings + decision bells 65 percent", "character cutout cues 45 percent"])
		and "motion reduced" not in settings.accessible_text().to_lower(),
		"audio mix should have its own concise category summary",
		failures,
	)
	_check(
		sfx_slider != null and music_mute != null
		and ambient_slider != null and ambient_mute != null
		and alerts_slider != null and voice_mute != null,
		"audio mix should independently expose music, ambience, work, UI, warnings, and character cues",
		failures,
	)
	if sfx_slider != null:
		sfx_slider.value = 0.42
	if music_mute != null:
		music_mute.button_pressed = true
	if ambient_slider != null:
		ambient_slider.value = 0.31
	if ambient_mute != null:
		ambient_mute.button_pressed = true
	if alerts_slider != null:
		alerts_slider.value = 0.24
	if voice_mute != null:
		voice_mute.button_pressed = true
	await process_frame
	_check(observed_preferences.size() >= 2, "audio adjustments should apply immediately", failures)
	if not observed_preferences.is_empty():
		var audio := observed_preferences.back().get("audio", {}) as Dictionary
		_check(
			is_equal_approx(float((audio.get("sfx", {}) as Dictionary).get("volume", -1.0)), 0.42)
			and bool((audio.get("music", {}) as Dictionary).get("muted", false)),
			"audio updates should preserve independent feedback and music state",
			failures,
		)
		_check(
			is_equal_approx(float((audio.get("ambient", {}) as Dictionary).get("volume", -1.0)), 0.31)
			and bool((audio.get("ambient", {}) as Dictionary).get("muted", false)),
			"office ambience should change without changing the music channel",
			failures,
		)
		_check(
			is_equal_approx(float((audio.get("alerts", {}) as Dictionary).get("volume", -1.0)), 0.24)
			and bool((audio.get("voice", {}) as Dictionary).get("muted", false)),
			"warnings and character cutout cues should retain independent mix choices",
			failures,
		)

	var motion := settings.find_child("MotionModeSelector", true, false) as OptionButton
	var camera_motion := settings.find_child("CameraMotionSelector", true, false) as OptionButton
	var camera_sensitivity := settings.find_child("CameraSensitivitySelector", true, false) as OptionButton
	var quality := settings.find_child("VisualQualitySelector", true, false) as OptionButton
	var timing := settings.find_child("TimingAssistSelector", true, false) as OptionButton
	var color_vision := settings.find_child("ColorVisionSelector", true, false) as OptionButton
	var notice_level := settings.find_child("NoticeLevelSelector", true, false) as OptionButton
	var notice_duration := settings.find_child("NoticeDurationSelector", true, false) as OptionButton
	var effect_level := settings.find_child("EffectLevelSelector", true, false) as OptionButton
	var particle_level := settings.find_child("ParticleLevelSelector", true, false) as OptionButton
	var animation_speed := settings.find_child("AnimationSpeedSelector", true, false) as OptionButton
	var tooltip_delay := settings.find_child("TooltipDelaySelector", true, false) as OptionButton
	var haptics := settings.find_child("HapticsToggle", true, false) as CheckButton
	var focus_pause := settings.find_child("PauseWhenUnfocusedToggle", true, false) as CheckButton
	if comfort_category != null:
		comfort_category.pressed.emit()
	if motion != null:
		motion.select(2)
		motion.item_selected.emit(2)
	if camera_motion != null:
		camera_motion.select(2)
		camera_motion.item_selected.emit(2)
	if camera_sensitivity != null:
		camera_sensitivity.select(2)
		camera_sensitivity.item_selected.emit(2)
	if quality != null:
		quality.select(0)
		quality.item_selected.emit(0)
	if timing != null:
		timing.select(2)
		timing.item_selected.emit(2)
	if color_vision != null:
		color_vision.select(1)
		color_vision.item_selected.emit(1)
	if notice_level != null:
		notice_level.select(2)
		notice_level.item_selected.emit(2)
	if notice_duration != null:
		notice_duration.select(0)
		notice_duration.item_selected.emit(0)
	if effect_level != null:
		effect_level.select(2)
		effect_level.item_selected.emit(2)
	if particle_level != null:
		particle_level.select(1)
		particle_level.item_selected.emit(1)
	if animation_speed != null:
		animation_speed.select(2)
		animation_speed.item_selected.emit(2)
	if tooltip_delay != null:
		tooltip_delay.select(0)
		tooltip_delay.item_selected.emit(0)
	if haptics != null:
		haptics.button_pressed = true
	if focus_pause != null:
		focus_pause.button_pressed = false
	_check(
		not observed_preferences.is_empty()
		and String(observed_preferences.back().get("motion_mode", "")) == "full"
		and String(observed_preferences.back().get("camera_motion", "")) == "off"
		and String(observed_preferences.back().get("camera_sensitivity", "")) == "high"
		and String(observed_preferences.back().get("visual_quality", "")) == "low"
		and String(observed_preferences.back().get("timing_assist", "")) == "extended"
		and String(observed_preferences.back().get("color_vision_mode", "")) == "color_blind_safe"
		and String(observed_preferences.back().get("notice_level", "")) == "archive_only"
		and String(observed_preferences.back().get("notice_duration", "")) == "brief"
		and String(observed_preferences.back().get("effect_level", "")) == "off"
		and String(observed_preferences.back().get("particle_level", "")) == "reduced"
		and String(observed_preferences.back().get("animation_speed", "")) == "brisk"
		and String(observed_preferences.back().get("tooltip_delay", "")) == "short"
		and bool(observed_preferences.back().get("haptics_enabled", false))
		and not bool(observed_preferences.back().get("pause_when_unfocused", true)),
		"comfort and notice selectors should emit their exact canonical settings",
		failures,
	)

	var peck_binding := settings.find_child("Binding_peck_assist", true, false) as Button
	if controls_category != null:
		controls_category.pressed.emit()
	_check(
		settings.active_category() == &"controls"
		and _contains_all(settings.accessible_text(), ["controls category, 3 of 4", "select a floor or camera control", "f10", "escape"]),
		"control rebinding should have its own concise category summary",
		failures,
	)
	_check(peck_binding != null and "E / A" in peck_binding.text, "binding cards should show the current device-aware label", failures)
	if peck_binding != null:
		peck_binding.pressed.emit()
	var replacement := InputEventKey.new()
	replacement.physical_keycode = KEY_Q
	replacement.pressed = true
	settings._input(replacement)
	_check(
		observed_bindings.size() == 1
		and StringName(observed_bindings[0].get("action", &"")) == &"peck_assist"
		and (observed_bindings[0].get("event") as InputEventKey).physical_keycode == KEY_Q,
		"binding capture should emit the semantic action and exact pressed input",
		failures,
	)
	var status := settings.find_child("SettingsStatus", true, false) as Label
	var capture_banner := settings.find_child("BindingCaptureBanner", true, false) as Label
	_check(
		settings.capture_action() == &"peck_assist"
		and settings.binding_capture_pending()
		and status != null and "checking" in status.text.to_lower()
		and capture_banner != null and capture_banner.visible,
		"an emitted binding should remain visibly pending until Office acknowledges it",
		failures,
	)
	var success_labels := _binding_labels()
	success_labels[&"peck_assist"] = "Q / A"
	_check(
		settings.acknowledge_binding_capture(
			&"peck_assist",
			true,
			"Priority Peck binding filed and saved.",
			success_labels,
		),
		"the matching host acknowledgement should resolve the pending request",
		failures,
	)
	_check(
		settings.capture_action() == &""
		and not settings.binding_capture_pending()
		and "Q / A" in peck_binding.text
		and status.text == "Priority Peck binding filed and saved.",
		"a success acknowledgement should clear capture, refresh labels, and expose saved status",
		failures,
	)

	var pause_binding := settings.find_child("Binding_pause_simulation", true, false) as Button
	if pause_binding != null:
		pause_binding.pressed.emit()
	var rejected_candidate := InputEventKey.new()
	rejected_candidate.physical_keycode = KEY_Q
	rejected_candidate.pressed = true
	settings._input(rejected_candidate)
	_check(
		observed_bindings.size() == 2 and settings.binding_capture_pending(),
		"a second capture should enter the same pending handshake",
		failures,
	)
	var rejection_status := "Q is already filed for Priority Peck. Choose another input."
	_check(
		settings.acknowledge_binding_capture(&"pause_simulation", false, rejection_status),
		"Office should be able to reject a conflicting candidate explicitly",
		failures,
	)
	_check(
		settings.capture_action() == &"pause_simulation"
		and not settings.binding_capture_pending()
		and status.text == rejection_status
		and capture_banner.visible and "NOT FILED" in capture_banner.text
		and rejection_status in settings.tooltip_text,
		"rejection should preserve its reason while leaving the action ready for another attempt",
		failures,
	)
	_check(
		not settings.acknowledge_binding_capture(&"peck_assist", true, "Stale success must not win."),
		"a stale or mismatched acknowledgement should be ignored",
		failures,
	)
	_check(
		settings.capture_action() == &"pause_simulation" and status.text == rejection_status,
		"ignoring a stale acknowledgement should preserve rejection state and status",
		failures,
	)

	var retry_candidate := InputEventKey.new()
	retry_candidate.physical_keycode = KEY_F6
	retry_candidate.pressed = true
	settings._input(retry_candidate)
	_check(
		observed_bindings.size() == 3 and settings.binding_capture_pending(),
		"a rejected capture should accept a new candidate without reopening the card",
		failures,
	)
	var controller_cancel := InputEventJoypadButton.new()
	controller_cancel.button_index = JOY_BUTTON_B
	controller_cancel.pressed = true
	settings._input(controller_cancel)
	_check(
		observed_bindings.size() == 3
		and settings.capture_action() == &""
		and not settings.binding_capture_pending()
		and "cancelled" in status.text.to_lower(),
		"controller B should cancel even a pending capture without becoming a binding",
		failures,
	)

	if peck_binding != null:
		peck_binding.pressed.emit()
	var semantic_cancel := InputEventAction.new()
	semantic_cancel.action = &"ui_cancel"
	semantic_cancel.pressed = true
	settings._input(semantic_cancel)
	_check(
		observed_bindings.size() == 3 and settings.capture_action() == &"",
		"semantic ui_cancel should cancel capture without emitting a candidate",
		failures,
	)

	if peck_binding != null:
		peck_binding.pressed.emit()
	var keyboard_cancel := InputEventKey.new()
	keyboard_cancel.keycode = KEY_ESCAPE
	keyboard_cancel.pressed = true
	settings._input(keyboard_cancel)
	_check(
		observed_bindings.size() == 3 and settings.capture_action() == &"",
		"Escape should remain a reserved safe return and never become a binding",
		failures,
	)

	if peck_binding != null:
		peck_binding.pressed.emit()
	var guide_cancel := InputEventJoypadButton.new()
	guide_cancel.button_index = JOY_BUTTON_GUIDE
	guide_cancel.pressed = true
	settings._input(guide_cancel)
	_check(
		observed_bindings.size() == 3 and settings.capture_action() == &"",
		"the reserved controller Guide button should cancel instead of replacing a floor control",
		failures,
	)

	if reset != null:
		reset.pressed.emit()
	if close != null:
		close.pressed.emit()
	_check(int(intent_counts["reset"]) == 1 and int(intent_counts["close"]) == 1, "reset and safe-return buttons should emit host-owned intents exactly once", failures)

	for viewport_size: Vector2 in [Vector2(844.0, 390.0), Vector2(390.0, 844.0)]:
		harness.size = viewport_size
		await process_frame
		await process_frame
		var rect := panel.get_global_rect()
		_check(
			rect.position.x >= -0.5 and rect.position.y >= -0.5
			and rect.end.x <= viewport_size.x + 0.5 and rect.end.y <= viewport_size.y + 0.5,
			"settings panel should remain inside %dx%d (got %s)" % [int(viewport_size.x), int(viewport_size.y), str(rect)],
			failures,
		)
		_check(scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "compact settings should keep every option reachable by scroll", failures)
		for category_button: Button in [
			audio_category,
			comfort_category,
			controls_category,
			career_category,
		]:
			if category_button != null:
				category_button.pressed.emit()
				await process_frame
				_check(
					scroll.scroll_vertical == 0,
					"category changes should begin at the top at %dx%d" % [
						int(viewport_size.x),
						int(viewport_size.y),
					],
					failures,
				)

	settings.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("SETTINGS_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SETTINGS_UI_TEST_PASSED categories=4+persistent+arrow+contextual-narration audio=7+alerts+cutout-cues comfort=motion+camera-motion+sensitivity+particles+contrast+color-vision+symbols+scale+detail+timing+notice-level+duration+effect-density+animation-speed+tooltip-delay+haptics+focus-pause controls=15+camera backup=export+confirm+cancel binding_ack=pending+success+rejection+cancel responsive=844x390+390x844")
	quit(0)


func _preferences() -> Dictionary:
	return {
		"audio": {
			"master": {"volume": 0.8, "muted": false},
			"music": {"volume": 0.6, "muted": false},
			"ambient": {"volume": 0.55, "muted": false},
			"sfx": {"volume": 0.9, "muted": false},
			"ui": {"volume": 0.7, "muted": false},
			"alerts": {"volume": 0.65, "muted": false},
			"voice": {"volume": 0.45, "muted": false},
		},
		"motion_mode": "reduced",
		"camera_motion": "reduced",
		"camera_sensitivity": "low",
		"ui_scale": 1.25,
		"high_contrast": true,
		"color_vision_mode": "standard",
		"visual_quality": "balanced",
		"timing_assist": "lenient",
		"notice_level": "priority",
		"notice_duration": "extended",
		"effect_level": "reduced",
		"particle_level": "off",
		"animation_speed": "relaxed",
		"tooltip_delay": "long",
		"haptics_enabled": false,
		"pause_when_unfocused": true,
		"settings_category": "comfort",
		"input_bindings": {},
	}


func _binding_labels() -> Dictionary:
	return {
		&"pause_simulation": "Space / Start",
		&"speed_normal": "1 / D-pad Left",
		&"speed_fast": "2 / D-pad Down",
		&"speed_ultra": "3 / D-pad Right",
		&"peck_assist": "E / A",
		&"fund_feed_party": "P / Y",
		&"toggle_overtime": "O / X",
		&"toggle_flockwatch": "V / Back",
		&"cycle_hen": "Tab / RB",
		&"camera_pan_left": "A / Left",
		&"camera_pan_right": "D / Right",
		&"camera_pan_up": "W / Up",
		&"camera_pan_down": "S / Down",
		&"camera_zoom_in": "Equal / Kp Add",
		&"camera_zoom_out": "Minus / Kp Subtract",
	}


func _contains_all(text: String, needles: Array[String]) -> bool:
	var lowered := text.to_lower()
	for needle in needles:
		if needle.to_lower() not in lowered:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
