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
	var sun := office.find_child("OfficeSun", true, false) as DirectionalLight3D
	var ui_root := office.find_child("ManagementUIRoot", true, false) as Control
	_check(settings != null and not settings.is_open(), "settings should be integrated but hidden on boot", failures)
	_check(open_button != null and open_button.focus_mode == Control.FOCUS_ALL and "F10" in open_button.text, "the persistent HUD should expose a keyboard-focusable settings route", failures)
	_check(controller != null and atmosphere != null and routing != null, "comfort settings should have live camera, atmosphere, and routing targets", failures)
	_check(audio_feedback != null and audio_director != null and audio_director.fixed_player_count() == 3, "the integrated office should own bounded feedback plus adaptive audio", failures)
	for action: StringName in OfficeActionCatalogScript.managed_actions():
		_check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "%s should have a semantic keyboard/gamepad path" % action, failures)

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
	comfort["visual_quality"] = "low"
	comfort["timing_assist"] = "extended"
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
	_check(ui_root != null and ui_root.theme != null and ui_root.theme.get_font_size(&"font_size", &"Button") >= 17, "125 percent UI scale should enlarge default button text", failures)
	_check(
		(settings.accessible_text() if settings != null else "").to_lower().contains("priority peck timing extended"),
		"settings narration should reflect the applied timing assistance",
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
	print("SETTINGS_OFFICE_INTEGRATION_TEST_PASSED modal=safe input=11+ack+rollback audio=feedback+adaptive motion=scene contrast=theme+ring detail=live timing=authoritative")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
