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
	var controller := office.find_child("ManagementCameraController", true, false) as ManagementCameraController
	var atmosphere := office.find_child("OfficeAtmosphere", true, false) as OfficeAtmosphere
	var audio_feedback := office.find_child("OfficeAudioFeedback", true, false) as OfficeAudioFeedback
	var audio_director := office.find_child("OfficeAudioDirector", true, false) as OfficeAudioDirector
	var routing := office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	var workstation_feedback := office.find_child("WorkstationFeedback", true, false) as WorkstationFeedback
	var storytelling := office.find_child("OfficeStorytelling", true, false) as OfficeStorytelling
	var sun := office.find_child("OfficeSun", true, false) as DirectionalLight3D
	var ui_root := office.find_child("ManagementUIRoot", true, false) as Control
	_check(settings != null and not settings.is_open(), "settings should be integrated but hidden on boot", failures)
	_check(open_button != null and open_button.focus_mode == Control.FOCUS_ALL and "F10" in open_button.text, "the persistent HUD should expose a keyboard-focusable settings route", failures)
	_check(controller != null and atmosphere != null and routing != null, "comfort settings should have live camera, atmosphere, and routing targets", failures)
	_check(audio_feedback != null and audio_director != null and audio_director.fixed_player_count() == 4, "the integrated office should own bounded feedback plus pressure-and-momentum adaptive audio", failures)
	for action: StringName in OfficeActionCatalogScript.managed_actions():
		_check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "%s should have a semantic keyboard/gamepad path" % action, failures)
	var settings_shortcut := InputEventKey.new()
	settings_shortcut.keycode = KEY_F10
	settings_shortcut.physical_keycode = KEY_F10
	settings_shortcut.pressed = true
	office._unhandled_input(settings_shortcut)
	await process_frame
	_check(
		settings != null and settings.is_open(),
		"the non-remappable F10 safety route should open Settings above campaign intake",
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
	comfort["ui_scale"] = 1.25
	comfort["high_contrast"] = true
	comfort["color_vision_mode"] = "color_blind_safe"
	comfort["visual_quality"] = "low"
	comfort["timing_assist"] = "extended"
	comfort["pause_when_unfocused"] = true
	(comfort.get("audio", {}) as Dictionary)["ambient"] = {"volume": 0.37, "muted": true}
	office.set("_player_preferences", comfort)
	office.call("_apply_player_preferences")
	await process_frame
	var simulation := office.get("_simulation") as DepartmentSimulation
	_check(bool(controller.get("_reduced_motion")), "reduced motion should reach the actual camera controller", failures)
	_check(bool(controller.get("_high_contrast")), "high contrast should strengthen the world-space focus marker", failures)
	_check(not bool((atmosphere.get("_dust_motes") as GPUParticles3D).emitting), "reduced motion and low detail should stop ambient particles", failures)
	_check(sun != null and not sun.shadow_enabled, "performance detail should disable the expensive office sun shadow", failures)
	_check(is_equal_approx(root.scaling_3d_scale, 0.82), "performance detail should lower only the 3D render scale", failures)
	_check(simulation.peck_assist_timing_profile == &"extended", "motor-timing assistance should reach the authoritative simulation", failures)
	var ambient_bus_index := AudioServer.get_bus_index(&"Ambient")
	_check(
		ambient_bus_index >= 0
		and is_equal_approx(AudioServer.get_bus_volume_db(ambient_bus_index), linear_to_db(0.37))
		and AudioServer.is_bus_mute(ambient_bus_index),
		"office ambience should apply its own volume and mute independently from music",
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
	_check(nest_queue != null and "[N]" in nest_queue.text, "safe palette should add a redundant Nest routing marker", failures)
	_check(
		(settings.accessible_text() if settings != null else "").to_lower().contains("priority peck timing extended"),
		"settings narration should reflect the applied timing assistance",
		failures,
	)

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
	office.free()
	await process_frame
	preferences_store.delete_preferences()
	OfficeActionCatalogScript.reset_all()
	if not failures.is_empty():
		for failure: String in failures:
			push_error("SETTINGS_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SETTINGS_OFFICE_INTEGRATION_TEST_PASSED modal=safe input=17+camera+ack+rollback audio=feedback+adaptive+ambient-independent focus-pause=restore+opt-out motion=scene contrast=theme+ring color-vision=palette+symbols detail=live timing=authoritative")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
