extends SceneTree

const DisclosureToggleScript := preload("res://features/office/flockwatch_disclosure_toggle.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(640, 480)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(column)

	var toggle = DisclosureToggleScript.new()
	toggle.name = "DisclosureToggleFixture"
	column.add_child(toggle)
	var target := VBoxContainer.new()
	target.name = "PreservedFilingFixture"
	column.add_child(target)
	var action := Button.new()
	action.name = "PreservedActionFixture"
	action.text = "AUTHORIZE ORIGINAL FILE"
	action.focus_mode = Control.FOCUS_ALL
	target.add_child(action)
	var original_action := action
	var targets: Array[Control] = [target]
	toggle.configure("SUPPLIER FILES", "1 READY / 3 FILES", targets, false)
	await process_frame

	_check(not target.visible, "a quiet filing group should begin collapsed", failures)
	_check(
		toggle.focus_mode == Control.FOCUS_ALL
		and "REVIEW SUPPLIER FILES" in toggle.text
		and "1 READY / 3 FILES" in toggle.text,
		"the summary row should remain keyboard-focusable and state what is inside",
		failures,
	)

	toggle.set_expanded(true)
	await process_frame
	_check(target.visible and "HIDE SUPPLIER FILES" in toggle.text, "expansion should reveal the existing filing group", failures)
	action.grab_focus()
	await process_frame
	_check(root.gui_get_focus_owner() == action, "the original action should accept keyboard focus", failures)
	toggle.set_expanded(false)
	await process_frame
	_check(
		not target.visible and root.gui_get_focus_owner() == toggle,
		"collapsing a focused descendant should return focus to its disclosure row",
		failures,
	)

	toggle.set_summary("2 READY / 3 FILES")
	toggle.set_expanded(true)
	await process_frame
	_check(
		target.find_child("PreservedActionFixture", true, false) == original_action
		and original_action.get_parent() == target,
		"summary and visibility updates must preserve action identity and ancestry",
		failures,
	)

	column.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FLOCKWATCH_DISCLOSURE_TOGGLE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FLOCKWATCH_DISCLOSURE_TOGGLE_TEST_PASSED quiet=collapsed focus=recovered identity=stable")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
