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
	var intent_counts := {"close": 0, "reset": 0}
	settings.preferences_changed.connect(
		func(value: Dictionary) -> void: observed_preferences.append(value.duplicate(true))
	)
	settings.binding_capture_requested.connect(
		func(action: StringName, event: InputEvent) -> void:
			observed_bindings.append({"action": action, "event": event})
	)
	settings.close_requested.connect(func() -> void: intent_counts["close"] += 1)
	settings.reset_defaults_requested.connect(func() -> void: intent_counts["reset"] += 1)
	await process_frame

	_check(not settings.is_open(), "settings should not obstruct the office on boot", failures)
	settings.show_settings(_preferences(), _binding_labels())
	await process_frame
	await process_frame
	_check(settings.is_open(), "show_settings should expose the responsive modal", failures)
	var panel := settings.find_child("SettingsPanel", true, false) as PanelContainer
	var scroll := settings.find_child("SettingsScroll", true, false) as ScrollContainer
	var close := settings.find_child("SettingsCloseButton", true, false) as Button
	var reset := settings.find_child("SettingsResetButton", true, false) as Button
	_check(panel != null and scroll != null, "settings should use a bounded panel with vertical scrolling", failures)
	_check(close != null and close.focus_mode == Control.FOCUS_ALL, "the safe return should remain keyboard focusable", failures)
	_check(reset != null and reset.focus_mode == Control.FOCUS_ALL, "default restoration should remain keyboard focusable", failures)
	_check(settings.find_children("Binding_*", "Button", true, false).size() == 9, "all nine player-remappable floor controls should be visible", failures)
	_check(
		_contains_all(settings.accessible_text(), ["master 80 percent", "motion reduced", "125 percent", "high contrast on", "timing lenient", "f10", "escape"]),
		"settings should publish one complete concise accessibility summary",
		failures,
	)

	var sfx_slider := settings.find_child("AudioVolume_sfx", true, false) as HSlider
	var music_mute := settings.find_child("AudioMute_music", true, false) as CheckButton
	_check(sfx_slider != null and music_mute != null, "audio mix should expose independent volume and mute controls", failures)
	if sfx_slider != null:
		sfx_slider.value = 0.42
	if music_mute != null:
		music_mute.button_pressed = true
	await process_frame
	_check(observed_preferences.size() >= 2, "audio adjustments should apply immediately", failures)
	if not observed_preferences.is_empty():
		var audio := observed_preferences.back().get("audio", {}) as Dictionary
		_check(
			is_equal_approx(float((audio.get("sfx", {}) as Dictionary).get("volume", -1.0)), 0.42)
			and bool((audio.get("music", {}) as Dictionary).get("muted", false)),
			"audio updates should preserve all bus state while changing one field",
			failures,
		)

	var motion := settings.find_child("MotionModeSelector", true, false) as OptionButton
	var quality := settings.find_child("VisualQualitySelector", true, false) as OptionButton
	var timing := settings.find_child("TimingAssistSelector", true, false) as OptionButton
	if motion != null:
		motion.select(2)
		motion.item_selected.emit(2)
	if quality != null:
		quality.select(0)
		quality.item_selected.emit(0)
	if timing != null:
		timing.select(2)
		timing.item_selected.emit(2)
	_check(
		not observed_preferences.is_empty()
		and String(observed_preferences.back().get("motion_mode", "")) == "full"
		and String(observed_preferences.back().get("visual_quality", "")) == "low"
		and String(observed_preferences.back().get("timing_assist", "")) == "extended",
		"comfort selectors should emit their exact canonical settings",
		failures,
	)

	var peck_binding := settings.find_child("Binding_peck_assist", true, false) as Button
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

	settings.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("SETTINGS_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SETTINGS_UI_TEST_PASSED audio=4 comfort=motion+contrast+scale+detail+timing controls=9 binding_ack=pending+success+rejection+cancel responsive=844x390+390x844")
	quit(0)


func _preferences() -> Dictionary:
	return {
		"audio": {
			"master": {"volume": 0.8, "muted": false},
			"music": {"volume": 0.6, "muted": false},
			"sfx": {"volume": 0.9, "muted": false},
			"ui": {"volume": 0.7, "muted": false},
		},
		"motion_mode": "reduced",
		"ui_scale": 1.25,
		"high_contrast": true,
		"visual_quality": "balanced",
		"timing_assist": "lenient",
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
