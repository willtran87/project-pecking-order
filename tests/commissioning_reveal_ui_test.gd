extends SceneTree

const CommissioningRevealUIScript := preload("res://features/office/commissioning_reveal_ui.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observed := {
		"continue": 0,
		"return": 0,
	}
	var harness := Control.new()
	harness.name = "CommissioningRevealUITestHarness"
	harness.size = Vector2(1280.0, 720.0)
	root.add_child(harness)
	var ui := CommissioningRevealUIScript.new() as CommissioningRevealUI
	harness.add_child(ui)
	ui.continue_requested.connect(func() -> void: observed["continue"] += 1)
	ui.return_to_blueprint_requested.connect(func() -> void: observed["return"] += 1)
	await process_frame

	var receipt := _receipt()
	ui.show_reveal(receipt, false)
	await process_frame
	await process_frame
	var panel := ui.find_child("CommissioningReceiptPanel", true, false) as PanelContainer
	var scroll := ui.find_child("CommissioningReceiptScroll", true, false) as ScrollContainer
	var action_rail := ui.find_child("CommissioningActionRail", true, false) as HBoxContainer
	var title := ui.find_child("CommissioningRevealTitle", true, false) as Label
	var facility := ui.find_child("CommissioningFacilityName", true, false) as Label
	var level := ui.find_child("CommissioningLevelName", true, false) as Label
	var before_after := ui.find_child("CommissioningBeforeAfter", true, false) as Label
	var obligations := ui.find_child("CommissioningObligations", true, false) as Label
	var effects := ui.find_child("CommissioningEffects", true, false) as Label
	var outcome := ui.find_child("CommissioningOutcome", true, false) as Label
	var return_button := ui.find_child("CommissioningReturnToBlueprint", true, false) as Button
	var continue_button := ui.find_child("CommissioningContinue", true, false) as Button

	_check(ui.is_reveal_visible(), "show_reveal should reveal a held receipt", failures)
	_check(title != null and title.text == "FACILITY COMMISSIONED", "reveal should use one plain commissioning heading", failures)
	_check(facility != null and facility.text == "FARMGATE DISPATCH DEPOT", "receipt should name the exact commissioned facility", failures)
	_check(level != null and level.text == "COUNTY ROUTE DESK", "receipt should retain the authored level name", failures)
	_check(before_after != null and _contains_all(before_after.text, ["$200.00", "$75.00", "$125.00", "->"]), "receipt should show exact spendable before, after, and capital filed", failures)
	_check(obligations != null and _contains_all(obligations.text, ["$32.00/day", "$37.00/day", "$4.00/day", "$9.00/day", "+$5.00/day", "->"]), "receipt should show exact reserve and upkeep obligations before and after", failures)
	_check(effects != null and _contains_all(effects.text, ["farmgate inventory", "county dispatch", "listing paperwork", "12-egg", "6 eggs", "2-shift"]), "receipt should preserve authored operating effects and exact Farmgate capacities", failures)
	_check(outcome != null and _contains_all(outcome.text, ["farmgate depot", "farmer", "showcase"]), "receipt should retain the authoritative commissioning outcome", failures)
	_check(
		_contains_all(ui.accessible_text(), ["facility commissioned", "farmgate dispatch depot", "county route desk", "$125.00", "protected reserve", "operating effect"]),
		"the complete receipt should be available as concise accessible text",
		failures,
	)
	_check(ui.entrance_animated() and not ui.used_reduced_motion(), "ordinary presentation may use the short receipt fade", failures)
	_check(scroll != null and action_rail != null and not scroll.is_ancestor_of(action_rail), "held actions should remain outside the receipt scroll surface", failures)
	_check(return_button != null and continue_button != null and return_button.focus_mode == Control.FOCUS_ALL and continue_button.focus_mode == Control.FOCUS_ALL, "both player-held actions should be keyboard focusable", failures)
	_check(continue_button != null and root.gui_get_focus_owner() == continue_button, "the safe Continue action should receive initial focus", failures)

	var copied := ui.receipt_snapshot()
	copied["cost_cents"] = 1
	_check(int(ui.receipt_snapshot().get("cost_cents", 0)) == 12_500, "public receipt snapshots should be defensive copies", failures)
	receipt["facility_name"] = "MUTATED"
	_check(String(ui.receipt_snapshot().get("facility_name", "")) == "Farmgate Dispatch Depot", "the reveal should not retain caller-owned receipt aliases", failures)

	for _frame: int in 8:
		await process_frame
	_check(ui.is_reveal_visible(), "commissioning reveal should never auto-dismiss", failures)
	if return_button != null:
		return_button.pressed.emit()
	_check(int(observed["return"]) == 1 and ui.is_reveal_visible(), "Return should emit host intent while the reveal remains player-held", failures)
	if continue_button != null:
		continue_button.pressed.emit()
	_check(int(observed["continue"]) == 1 and ui.is_reveal_visible(), "Continue should emit host intent without hiding itself", failures)

	ui.hide_reveal()
	_check(not ui.is_reveal_visible(), "the host should be able to dismiss the acknowledged receipt explicitly", failures)
	ui.show_reveal(_receipt(), true)
	await process_frame
	_check(ui.used_reduced_motion() and not ui.entrance_animated(), "reduced motion should bypass the entrance tween", failures)
	_check(panel != null and is_equal_approx(panel.modulate.a, 1.0), "reduced motion receipt should appear at full opacity immediately", failures)

	harness.size = Vector2(844.0, 390.0)
	await process_frame
	await process_frame
	if panel != null:
		var panel_rect := panel.get_global_rect()
		_check(panel_rect.position.x >= -0.5 and panel_rect.end.x <= harness.size.x + 0.5, "compact reveal should stay within the 844px viewport", failures)
		_check(panel_rect.position.y >= 120.0 and panel_rect.end.y <= harness.size.y + 0.5, "compact receipt should preserve the upper live-camera view and fit vertically", failures)
	_check(scroll != null and scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "long compact effects should remain reachable by scrolling", failures)
	_check(action_rail != null and return_button != null and continue_button != null and not scroll.is_ancestor_of(action_rail), "compact actions should remain fixed outside the scroll surface", failures)
	if return_button != null and continue_button != null:
		_check(return_button.is_visible_in_tree() and continue_button.is_visible_in_tree(), "both compact actions should remain visible at 844x390", failures)
		_check(return_button.get_global_rect().end.y <= harness.size.y + 0.5 and continue_button.get_global_rect().end.y <= harness.size.y + 0.5, "compact actions should remain physically reachable", failures)

	ui.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("COMMISSIONING_REVEAL_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("COMMISSIONING_REVEAL_UI_TEST_PASSED receipt=exact held=player compact=844x390 motion=reduced actions=2")
	quit(0)


func _receipt() -> Dictionary:
	return {
		"accepted": true,
		"action_id": &"purchase_facility",
		"facility_id": &"farmgate_dispatch_depot",
		"facility_name": "Farmgate Dispatch Depot",
		"level_name": "County Route Desk",
		"day": 6,
		"purchased_level": 2,
		"max_level": 3,
		"cost_cents": 12_500,
		"fund_before_cents": 23_200,
		"fund_after_cents": 10_700,
		"spendable_before_cents": 20_000,
		"spendable_after_cents": 7_500,
		"protected_reserve_before_cents": 3_200,
		"protected_reserve_after_cents": 3_700,
		"upkeep_before_cents": 400,
		"upkeep_after_cents": 900,
		"upkeep_delta_cents": 500,
		"effect": {
			"benefits": [
				"Opens a held Farmgate inventory ledger.",
				"Authorizes one county dispatch after review.",
			],
			"tradeoffs": ["Adds daily listing paperwork."],
			"storage_capacity_eggs": 12,
			"dispatch_capacity_eggs": 6,
			"shelf_life_shifts": 2,
		},
		"outcome": "Farmgate Depot commissioned; six premium eggs may now enter the farmer's showcase.",
	}


func _contains_all(text_value: String, needles: Array[String]) -> bool:
	var lowered := text_value.to_lower()
	for needle: String in needles:
		if needle.to_lower() not in lowered:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
