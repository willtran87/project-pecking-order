extends SceneTree

const OfficeActionCatalogScript := preload("res://core/settings/office_action_catalog.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var original_actions := _snapshot_managed_actions()
	_clear_managed_actions()

	# Office historically installed this action itself. A preferences bootstrap
	# must not silently replace a player's or an older build's binding.
	InputMap.add_action(&"peck_assist", 0.37)
	var legacy_peck := InputEventKey.new()
	legacy_peck.physical_keycode = KEY_Q
	InputMap.action_add_event(&"peck_assist", legacy_peck)
	var install_result: Dictionary = OfficeActionCatalogScript.install_defaults()
	_check(bool(install_result.get("accepted", false)), "default installation should succeed", failures)
	_check(
		(install_result.get("preserved", []) as Array).has("peck_assist"),
		"install_defaults should explicitly report the preserved legacy peck action",
		failures,
	)
	_check(
		OfficeActionCatalogScript.managed_actions().size() == 11,
		"the semantic catalog should expose all eleven agreed Office actions",
		failures,
	)
	for action: StringName in OfficeActionCatalogScript.managed_actions():
		_check(InputMap.has_action(action), "%s should be installed" % action, failures)
		_check(not InputMap.action_get_events(action).is_empty(), "%s should remain reachable" % action, failures)
	_check(
		_has_physical_key(&"peck_assist", KEY_Q)
		and not _has_physical_key(&"peck_assist", KEY_E)
		and InputMap.action_get_events(&"peck_assist").size() == 1,
		"legacy peck_assist should be preserved exactly rather than appended to",
		failures,
	)
	_check(
		OfficeActionCatalogScript.display_name(&"pause_simulation") == "Pause / Resume"
		and OfficeActionCatalogScript.display_name(&"not_catalogued") == "Not Catalogued",
		"display_name should provide stable friendly and fallback labels",
		failures,
	)
	_check(
		OfficeActionCatalogScript.binding_label(&"pause_simulation") == "Space / Start"
		and OfficeActionCatalogScript.binding_label(&"cycle_hen") == "Tab / RB"
		and OfficeActionCatalogScript.binding_label(&"peck_assist") == "Q"
		and OfficeActionCatalogScript.binding_label(&"not_catalogued").is_empty(),
		"binding_label should reflect current concise keyboard and gamepad names",
		failures,
	)

	var pause_before_conflict := OfficeActionCatalogScript.export_bindings().get("pause_simulation", []) as Array
	var conflicting_key := InputEventKey.new()
	conflicting_key.physical_keycode = KEY_Q
	var conflict_result: Dictionary = OfficeActionCatalogScript.rebind_action(
		&"pause_simulation",
		[conflicting_key],
	)
	_check(not bool(conflict_result.get("accepted", true)), "same-context duplicate bindings should be rejected", failures)
	_check(
		not (conflict_result.get("conflicts", []) as Array).is_empty(),
		"a rejected rebind should identify its conflict",
		failures,
	)
	_check(
		OfficeActionCatalogScript.export_bindings().get("pause_simulation", []) == pause_before_conflict,
		"a rejected rebind must leave InputMap unchanged",
		failures,
	)

	_check(OfficeActionCatalogScript.reset_action(&"peck_assist"), "peck_assist should support a safe reset", failures)
	_check(
		_has_physical_key(&"peck_assist", KEY_E)
		and _has_joy_button(&"peck_assist", JOY_BUTTON_A)
		and InputMap.action_get_events(&"peck_assist").size() == 2,
		"peck_assist reset should restore physical E and gamepad A",
		failures,
	)
	_check(OfficeActionCatalogScript.binding_label(&"peck_assist") == "E / A", "reset labels should update with InputMap", failures)

	var replacement := InputEventKey.new()
	replacement.physical_keycode = KEY_F6
	var rebind_result: Dictionary = OfficeActionCatalogScript.rebind_action(&"pause_simulation", [replacement])
	_check(bool(rebind_result.get("accepted", false)), "a unique supported binding should apply", failures)
	_check(
		_has_physical_key(&"pause_simulation", KEY_F6)
		and InputMap.action_get_events(&"pause_simulation").size() == 1,
		"successful rebinding should replace only the requested action",
		failures,
	)
	_check(_has_physical_key(&"peck_assist", KEY_E), "partial rebinding should preserve unrelated actions", failures)

	var exported: Dictionary = OfficeActionCatalogScript.export_bindings()
	var json_round_trip: Variant = JSON.parse_string(JSON.stringify(exported))
	_check(json_round_trip is Dictionary, "exported bindings should be JSON-safe", failures)
	var reset_result: Dictionary = OfficeActionCatalogScript.reset_all()
	_check(bool(reset_result.get("accepted", false)), "reset_all should restore a complete valid map", failures)
	_check(
		_has_physical_key(&"pause_simulation", KEY_SPACE)
		and _has_joy_button(&"pause_simulation", JOY_BUTTON_START),
		"pause reset should restore Space and Start",
		failures,
	)
	if json_round_trip is Dictionary:
		var round_trip_result: Dictionary = OfficeActionCatalogScript.apply_bindings(json_round_trip as Dictionary, true)
		_check(bool(round_trip_result.get("accepted", false)), "serialized bindings should apply transactionally", failures)
		_check(_has_physical_key(&"pause_simulation", KEY_F6), "round-tripped input should retain its exact physical key", failures)

	var state_before_invalid := OfficeActionCatalogScript.export_bindings()
	var invalid_results: Array[Dictionary] = [
		OfficeActionCatalogScript.apply_bindings({"unknown_action": [{"type": "key", "keycode": KEY_A}]}),
		OfficeActionCatalogScript.apply_bindings({"peck_assist": []}),
		OfficeActionCatalogScript.apply_bindings({
			"peck_assist": [
				{"type": "key", "physical_keycode": KEY_E},
				{"type": "key", "physical_keycode": KEY_E},
			],
		}),
		OfficeActionCatalogScript.apply_bindings({"peck_assist": [{"type": "mouse_button", "button_index": 1}]}),
	]
	for invalid_result in invalid_results:
		_check(not bool(invalid_result.get("accepted", true)), "malformed or unsafe bindings should be rejected", failures)
	_check(
		OfficeActionCatalogScript.export_bindings() == state_before_invalid,
		"invalid binding transactions must not partially mutate InputMap",
		failures,
	)

	reset_result = OfficeActionCatalogScript.reset_all()
	_check(bool(reset_result.get("accepted", false)), "final default restoration should succeed", failures)
	_check(
		_defaults_match_contract(),
		"catalog defaults should match the agreed keyboard and gamepad Office contract",
		failures,
	)

	_restore_managed_actions(original_actions)
	if not failures.is_empty():
		for failure: String in failures:
			push_error("OFFICE_ACTION_CATALOG_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OFFICE_ACTION_CATALOG_TEST_PASSED actions=11 legacy_peck=preserved transactions=atomic defaults=keyboard+gamepad")
	quit(0)


func _defaults_match_contract() -> bool:
	return (
		_has_physical_key(&"pause_simulation", KEY_SPACE)
		and _has_joy_button(&"pause_simulation", JOY_BUTTON_START)
		and _has_physical_key(&"speed_normal", KEY_1)
		and _has_joy_button(&"speed_normal", JOY_BUTTON_DPAD_LEFT)
		and _has_physical_key(&"speed_fast", KEY_2)
		and _has_joy_button(&"speed_fast", JOY_BUTTON_DPAD_DOWN)
		and _has_physical_key(&"speed_ultra", KEY_3)
		and _has_joy_button(&"speed_ultra", JOY_BUTTON_DPAD_RIGHT)
		and _has_physical_key(&"peck_assist", KEY_E)
		and _has_joy_button(&"peck_assist", JOY_BUTTON_A)
		and _has_physical_key(&"fund_feed_party", KEY_P)
		and _has_joy_button(&"fund_feed_party", JOY_BUTTON_Y)
		and _has_physical_key(&"toggle_overtime", KEY_O)
		and _has_joy_button(&"toggle_overtime", JOY_BUTTON_X)
		and _has_physical_key(&"toggle_flockwatch", KEY_V)
		and _has_joy_button(&"toggle_flockwatch", JOY_BUTTON_BACK)
		and _has_logical_key(&"cycle_hen", KEY_TAB)
		and _has_joy_button(&"cycle_hen", JOY_BUTTON_RIGHT_SHOULDER)
		and _has_logical_key(&"office_overview", KEY_ESCAPE)
		and _has_joy_button(&"office_overview", JOY_BUTTON_B)
		and _has_logical_key(&"open_settings", KEY_F10)
		and _has_joy_button(&"open_settings", JOY_BUTTON_GUIDE)
	)


func _snapshot_managed_actions() -> Dictionary:
	var snapshot: Dictionary = {}
	for action: StringName in OfficeActionCatalogScript.managed_actions():
		if not InputMap.has_action(action):
			snapshot[String(action)] = {"existed": false}
			continue
		var events: Array[InputEvent] = []
		for event: InputEvent in InputMap.action_get_events(action):
			events.append(event.duplicate(true) as InputEvent)
		snapshot[String(action)] = {
			"existed": true,
			"deadzone": InputMap.action_get_deadzone(action),
			"events": events,
		}
	return snapshot


func _clear_managed_actions() -> void:
	for action: StringName in OfficeActionCatalogScript.managed_actions():
		if InputMap.has_action(action):
			InputMap.erase_action(action)


func _restore_managed_actions(snapshot: Dictionary) -> void:
	_clear_managed_actions()
	for action: StringName in OfficeActionCatalogScript.managed_actions():
		var saved := snapshot.get(String(action), {}) as Dictionary
		if not bool(saved.get("existed", false)):
			continue
		InputMap.add_action(action, float(saved.get("deadzone", 0.5)))
		for event: InputEvent in saved.get("events", []) as Array[InputEvent]:
			InputMap.action_add_event(action, event.duplicate(true) as InputEvent)


func _has_physical_key(action: StringName, keycode: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == keycode:
			return true
	return false


func _has_logical_key(action: StringName, keycode: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).keycode == keycode:
			return true
	return false


func _has_joy_button(action: StringName, button: JoyButton) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button:
			return true
	return false


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
