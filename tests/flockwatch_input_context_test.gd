extends SceneTree


const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const PlayerPreferencesStoreScript := preload("res://core/settings/player_preferences_store.gd")
const OfficeActionCatalogScript := preload("res://core/settings/office_action_catalog.gd")
const TEST_CAMPAIGN_FILENAME := "flockwatch_input_context_test_campaign.json"
const TEST_PREFERENCES_FILENAME := "flockwatch_input_context_test_preferences.json"

var _stage := "boot"


func _init() -> void:
	create_timer(60.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	var campaign_store = CampaignSaveStoreScript.new(TEST_CAMPAIGN_FILENAME)
	var preferences_store = PlayerPreferencesStoreScript.new(TEST_PREFERENCES_FILENAME)
	campaign_store.delete()
	preferences_store.delete_preferences()
	OfficeActionCatalogScript.reset_all()

	var office := Office.new()
	office.set("_campaign_store", campaign_store)
	office.set("_preferences_store", preferences_store)
	root.add_child(office)
	await process_frame
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var decision_host := office.get("_decision_host") as Control
	var navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	var camera := office.get("_camera_controller") as ManagementCameraController
	var routing := office.get("_routing_ui") as PeckworkRoutingUI
	var toggle := office.get("_flockwatch_toggle") as Button
	var panel := office.get("_flockwatch_panel") as PanelContainer
	_check(
		[simulation, clock, campaign_ui, decision_host, navigation, camera, routing, toggle, panel].all(
			func(value: Variant) -> bool: return value != null
		),
		"Office should compose every Flockwatch input collaborator",
		failures,
	)

	# Headless Office boots directly into the morning directive. Close only that
	# fixture surface so the injected events exercise ordinary live-floor input.
	if decision_host != null:
		decision_host.visible = false
	if simulation != null:
		simulation.pending_decision.clear()
		simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	office.set("_active_decision", {})
	if campaign_ui != null:
		campaign_ui.show_active_campaign()
	office.call("_set_campaign_modal_open", false)
	office.call("_set_flockwatch_open", false)
	if clock != null:
		clock.set_speed(1)
	if camera != null:
		camera.set_process_unhandled_input(true)
		camera.focus_worker(0)
	if toggle != null:
		toggle.grab_focus()
	await process_frame

	_stage = "keyboard open"
	await _send_key(KEY_V)
	_check(bool(office.get("_flockwatch_open")), "The mapped V key should open Flockwatch", failures)
	_check(panel != null and panel.visible, "Opening should expose the ledger panel", failures)
	_check(
		navigation != null
		and root.gui_get_focus_owner() == navigation.page_button(navigation.current_page_id()),
		"Opening from the canvas should move focus to the current filing tab",
		failures,
	)
	_check(
		camera != null and not camera.is_processing_unhandled_input() and not camera.is_focused(),
		"Flockwatch should suspend camera shortcuts and return a focused hen to overview",
		failures,
	)
	_check(
		routing != null and not bool(routing.get("_interaction_enabled")),
		"Hidden routing controls should not remain interactive behind Flockwatch",
		failures,
	)

	_stage = "controller page navigation"
	var speed_before := clock.speed_index if clock != null else -1
	await _send_joy_button(JOY_BUTTON_RIGHT_SHOULDER)
	_check(
		navigation != null
		and navigation.current_page_id() == FlockwatchNavigation.PAGE_FLOCK
		and root.gui_get_focus_owner() == navigation.page_button(FlockwatchNavigation.PAGE_FLOCK),
		"The mapped right shoulder should cycle filing pages instead of hens",
		failures,
	)
	_check(camera != null and not camera.is_focused(), "Page cycling must not select a hen behind the drawer", failures)

	# D-pad Left is also the Normal Speed floor binding. A focused filing tab must
	# consume its ordinary ui_left meaning before that live-floor action can fire.
	await _send_joy_button(JOY_BUTTON_DPAD_LEFT)
	_check(
		navigation != null and navigation.current_page_id() == FlockwatchNavigation.PAGE_TODAY,
		"D-pad Left should select the previous available filing page",
		failures,
	)
	_check(
		clock != null and clock.speed_index == speed_before,
		"Flockwatch navigation must not leak the same input into simulation speed",
		failures,
	)

	_stage = "persistent action feedback"
	var ticker := office.get("_ticker_label") as Label
	if ticker != null:
		ticker.text = "CAPITAL FILE APPROVED. The protected reserve remains intact."
	await process_frame
	if ticker != null:
		ticker.text = "FILING HELD. The recurring feed obligation is not covered."
	await process_frame
	var feedback_panel := office.find_child("FlockwatchLatestFeedback", true, false) as PanelContainer
	var feedback_copy := office.find_child("FlockwatchLatestFeedbackCopy", true, false) as Label
	var diagnostic := office.call("_flockwatch_diagnostic_state") as Dictionary
	_check(
		feedback_panel != null
		and feedback_panel.visible
		and feedback_copy != null
		and "FILING HELD" in feedback_copy.text,
		"The latest accepted or denied action should remain visible on every filing page",
		failures,
	)
	_check(
		bool(diagnostic.get("visible", false))
		and String(diagnostic.get("current_page", "")) == "today"
		and String(diagnostic.get("current_page_title", "")).contains("orders")
		and (diagnostic.get("available_pages", []) as Array).has("today")
		and String(diagnostic.get("accessible_text", "")).contains("FILING HELD")
		and String(diagnostic.get("last_feedback", "")).begins_with("FILING HELD"),
		"The browser diagnostic should expose the visible page and exact latest receipt",
		failures,
	)

	_stage = "controller close and focus restore"
	await _send_joy_button(JOY_BUTTON_BACK)
	await process_frame
	_check(not bool(office.get("_flockwatch_open")), "The mapped controller Back button should close Flockwatch", failures)
	_check(panel != null and not panel.visible, "Closing should hide the ledger panel", failures)
	_check(
		root.gui_get_focus_owner() == toggle,
		"A user close should restore focus to the control that opened Flockwatch",
		failures,
	)
	_check(
		camera != null and camera.is_processing_unhandled_input(),
		"Closing the final management surface should restore camera input",
		failures,
	)
	_check(
		routing != null and bool(routing.get("_interaction_enabled")),
		"Closing should restore live routing interaction",
		failures,
	)
	diagnostic = office.call("_flockwatch_diagnostic_state") as Dictionary
	_check(
		not bool(diagnostic.get("visible", true))
		and String(diagnostic.get("accessible_text", "")).is_empty()
		and String(diagnostic.get("last_feedback", "")).begins_with("FILING HELD"),
		"A closed ledger should leave history intact without claiming to be the active screen-reader surface",
		failures,
	)

	# Once the ledger closes, the same semantic shoulder binding belongs to the
	# camera again and should cycle to a real hen.
	await _send_joy_button(JOY_BUTTON_RIGHT_SHOULDER)
	_check(camera != null and camera.is_focused(), "Camera cycling should resume after Flockwatch closes", failures)

	office.free()
	await process_frame
	campaign_store.delete()
	preferences_store.delete_preferences()
	OfficeActionCatalogScript.reset_all()
	if not failures.is_empty():
		for failure: String in failures:
			push_error("FLOCKWATCH_INPUT_CONTEXT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FLOCKWATCH_INPUT_CONTEXT_TEST_PASSED keyboard=open controller=pages+close focus=owned camera=suspended feedback=visible+announced")
	quit(0)


func _send_key(physical_keycode: Key) -> void:
	var press := InputEventKey.new()
	press.physical_keycode = physical_keycode
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := press.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _send_joy_button(button_index: JoyButton) -> void:
	var press := InputEventJoypadButton.new()
	press.button_index = button_index
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := press.duplicate() as InputEventJoypadButton
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _on_watchdog_timeout() -> void:
	push_error("FLOCKWATCH_INPUT_CONTEXT_TEST_TIMEOUT stage=%s" % _stage)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
