extends SceneTree

const RevealUIScript := preload("res://features/office/campus_portfolio_reveal_ui.gd")


func _init() -> void:
	create_timer(25.0).timeout.connect(func() -> void:
		push_error("CAMPUS_PORTFOLIO_REVEAL_UI_TEST_TIMEOUT")
		quit(1)
	)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observed := {"continue": 0, "return": 0}
	var harness := Control.new()
	harness.name = "CampusPortfolioRevealUITestHarness"
	harness.size = Vector2(1280.0, 720.0)
	root.add_child(harness)
	var ui := RevealUIScript.new() as CampusPortfolioRevealUI
	harness.add_child(ui)
	ui.continue_requested.connect(func() -> void: observed["continue"] += 1)
	ui.return_to_portfolio_requested.connect(func() -> void: observed["return"] += 1)
	await process_frame

	var receipt := _receipt()
	ui.show_reveal(receipt, _context(), false)
	await process_frame
	await process_frame
	var panel := ui.find_child("CampusPortfolioRevealPanel", true, false) as PanelContainer
	var scroll := ui.find_child("CampusPortfolioRevealScroll", true, false) as ScrollContainer
	var rail := ui.find_child("CampusPortfolioRevealActionRail", true, false) as HFlowContainer
	var heading := ui.find_child("CampusPortfolioRevealEyebrow", true, false) as Label
	var return_button := ui.find_child("CampusPortfolioRevealReturn", true, false) as Button
	var continue_button := ui.find_child("CampusPortfolioRevealContinue", true, false) as Button

	_check(ui.is_reveal_visible(), "show_reveal should hold the receipt over the world", failures)
	_check(heading != null and heading.text == "CAMPUS BUILD AUTHORIZED", "project authorization should use the exact campus heading", failures)
	_check(
		_contains_all(ui.accessible_text(), [
			"collection rail hub", "orchard row", "orchard west", "active",
			"$140.00", "+$6.50/day", "$900.00", "$760.00", "$645.00",
			"2 shifts", "contractors  1", "power  2", "named hen  mabel",
			"collection rail branch", "foundation crew entered",
		]),
		"accessible narration should preserve identity, location, economics, capacity, named hen, effects, and outcome",
		failures,
	)
	_check(ui.receipt_snapshot() == receipt, "the reveal should retain the exact raw authoritative receipt", failures)
	var copied := ui.receipt_snapshot()
	copied["cost_cents"] = 1
	_check(int(ui.receipt_snapshot().get("cost_cents", 0)) == 14_000, "receipt_snapshot should be a defensive copy", failures)
	receipt["outcome"] = "MUTATED"
	_check("foundation crew entered" in String(ui.receipt_snapshot().get("outcome", "")).to_lower(), "caller mutations must not alias the held receipt", failures)
	_check(ui.entrance_animated() and not ui.used_reduced_motion(), "ordinary reveal may use the short entrance", failures)
	_check(scroll != null and rail != null and not scroll.is_ancestor_of(rail), "held actions should stay outside the scrolling receipt", failures)
	_check(return_button != null and continue_button != null and return_button.focus_mode == Control.FOCUS_ALL and continue_button.focus_mode == Control.FOCUS_ALL, "both reveal choices should support keyboard focus", failures)
	_check(continue_button != null and root.gui_get_focus_owner() == continue_button, "Continue should receive safe initial focus", failures)

	for _frame: int in 6:
		await process_frame
	_check(ui.is_reveal_visible(), "the receipt should never auto-dismiss", failures)
	if return_button != null:
		return_button.pressed.emit()
	_check(int(observed["return"]) == 1 and ui.is_reveal_visible(), "Return should emit host intent without optimistic hiding", failures)
	if continue_button != null:
		continue_button.pressed.emit()
	_check(int(observed["continue"]) == 1 and ui.is_reveal_visible(), "Continue should emit host intent without optimistic hiding", failures)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	ui._unhandled_key_input(escape)
	_check(int(observed["return"]) == 2, "Escape should offer the same safe return-to-portfolio path", failures)

	ui.hide_reveal()
	ui.show_reveal(_receipt(), _context(), true)
	await process_frame
	_check(ui.used_reduced_motion() and not ui.entrance_animated(), "reduced motion should bypass the entrance tween", failures)
	_check(panel != null and is_equal_approx(panel.modulate.a, 1.0), "reduced-motion receipt should appear at full opacity", failures)

	await _assert_layout(harness, ui, panel, rail, return_button, continue_button, Vector2(844.0, 390.0), true, failures)
	await _assert_layout(harness, ui, panel, rail, return_button, continue_button, Vector2(390.0, 844.0), false, failures)

	ui.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPUS_PORTFOLIO_REVEAL_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_PORTFOLIO_REVEAL_UI_TEST_PASSED receipt=exact live-world=visible responsive=844x390+390x844 keyboard=return+continue motion=reduced")
	quit(0)


func _assert_layout(
		harness: Control,
		ui: CampusPortfolioRevealUI,
		panel: PanelContainer,
		rail: HFlowContainer,
		return_button: Button,
		continue_button: Button,
		target_size: Vector2,
		preserve_upper_world: bool,
		failures: Array[String],
) -> void:
	harness.size = target_size
	await process_frame
	await process_frame
	var viewport_bounds := Rect2(Vector2.ZERO, target_size)
	if panel != null:
		var panel_rect := panel.get_global_rect()
		_check(viewport_bounds.encloses(panel_rect), "%s receipt panel should remain inside the viewport (rect=%s)" % [target_size, panel_rect], failures)
		if preserve_upper_world:
			_check(panel_rect.position.y >= 150.0, "844x390 should leave the upper live-world result visible", failures)
	if rail != null and return_button != null and continue_button != null:
		_check(not (ui.find_child("CampusPortfolioRevealScroll", true, false) as ScrollContainer).is_ancestor_of(rail), "%s fixed actions should stay outside scrolling content" % target_size, failures)
		_check(return_button.is_visible_in_tree() and continue_button.is_visible_in_tree(), "%s should keep both player-held actions visible" % target_size, failures)
		_check(viewport_bounds.encloses(return_button.get_global_rect()) and viewport_bounds.encloses(continue_button.get_global_rect()), "%s should keep both actions physically reachable" % target_size, failures)


func _receipt() -> Dictionary:
	return {
		"receipt_id": 17,
		"day": 14,
		"action_id": "authorize_project",
		"parcel_id": "orchard_row",
		"module_id": "collection_rail_hub",
		"pad_id": "orchard_west",
		"project_id": 5,
		"worker_id": 0,
		"cost_cents": 14_000,
		"added_daily_cost_cents": 650,
		"duration_shifts": 2,
		"contractor_slots": 1,
		"power_units": 2,
		"cold_units": 0,
		"status": "active",
		"fund_delta_cents": -14_000,
		"outcome": "Collection Rail Hub authorized at Orchard West; the foundation crew entered the live pad.",
	}


func _context() -> Dictionary:
	return {
		"parcel_name": "Orchard Row",
		"module_name": "Collection Rail Hub",
		"pad_name": "Orchard West",
		"worker_name": "Mabel",
		"effect_lines": ["Adds one collection rail branch.", "Relieves routing overflow."],
		"has_fund_before": true,
		"fund_before_cents": 90_000,
		"fund_after_cents": 76_000,
		"has_spendable_after": true,
		"spendable_after_cents": 64_500,
	}


func _contains_all(text_value: String, needles: Array[String]) -> bool:
	var lowered := text_value.to_lower()
	for needle: String in needles:
		if needle.to_lower() not in lowered:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
