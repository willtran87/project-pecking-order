extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var explicit_argument := PackedStringArray([Office.PREDATOR_DEBUG_ARGUMENT])
	var no_arguments := PackedStringArray()

	_check(
		not Office.predator_debug_shortcut_enabled_for_environment(
			false,
			explicit_argument,
			no_arguments,
		),
		"release builds must reject the predator flag even when it is supplied",
		failures,
	)
	_check(
		not Office.predator_debug_shortcut_enabled_for_environment(
			true,
			no_arguments,
			no_arguments,
		),
		"debug builds must keep the shortcut disabled without explicit opt-in",
		failures,
	)
	_check(
		Office.predator_debug_shortcut_enabled_for_environment(
			true,
			explicit_argument,
			no_arguments,
		),
		"debug builds should accept the explicit user argument",
		failures,
	)
	_check(
		Office.predator_debug_shortcut_enabled_for_environment(
			true,
			no_arguments,
			explicit_argument,
		),
		"debug builds should accept the explicit engine argument",
		failures,
	)
	_check(
		not Office.predator_debug_shortcut_enabled_for_environment(
			true,
			PackedStringArray(["--enable-predator-debug-preview"]),
			no_arguments,
		),
		"lookalike arguments must not enable the destructive shortcut",
		failures,
	)

	# Keep the actual input binding in the release contract as well as the pure
	# environment predicate. This source-level check avoids constructing the
	# entire Office scene merely to inspect an editor-only shortcut.
	var office_source := FileAccess.get_file_as_string("res://features/office/office.gd")
	var key_guard_index := office_source.find("event.keycode == KEY_F")
	var environment_guard_index := office_source.find(
		"and _predator_debug_shortcut_enabled()",
		key_guard_index,
	)
	var trigger_index := office_source.find(
		"_trigger_predator_debug_encounter()",
		environment_guard_index,
	)
	_check(
		key_guard_index >= 0
		and environment_guard_index > key_guard_index
		and trigger_index > environment_guard_index
		and trigger_index - key_guard_index < 320,
		"the F binding must pass the environment gate immediately before the predator trigger",
		failures,
	)

	if not failures.is_empty():
		for failure in failures:
			push_error("PREDATOR_DEBUG_GATE_TEST_FAILED: %s" % failure)
		quit(1)
		return

	print("PREDATOR_DEBUG_GATE_TEST_PASSED")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
