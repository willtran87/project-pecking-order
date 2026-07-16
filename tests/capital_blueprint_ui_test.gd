extends SceneTree

const CapitalBlueprintUIScript := preload("res://features/office/capital_blueprint_ui.gd")
const CapitalBlueprintModelScript := preload("res://features/office/capital_blueprint_model.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observed := {
		"close": 0,
		"previews": [] as Array[StringName],
		"pins": [] as Array[StringName],
		"purchases": [] as Array[StringName],
		"campus": 0,
	}
	var harness := Control.new()
	harness.name = "CapitalBlueprintUITestHarness"
	harness.size = Vector2(1280.0, 720.0)
	root.add_child(harness)
	var office_focus := Button.new()
	office_focus.name = "OfficeFocusTarget"
	office_focus.text = "OPEN BLUEPRINT"
	harness.add_child(office_focus)
	var ui := CapitalBlueprintUIScript.new() as CapitalBlueprintUI
	harness.add_child(ui)
	ui.close_requested.connect(func() -> void: observed["close"] += 1)
	ui.preview_requested.connect(func(facility_id: StringName) -> void: (observed["previews"] as Array).append(facility_id))
	ui.pin_requested.connect(func(facility_id: StringName) -> void: (observed["pins"] as Array).append(facility_id))
	ui.purchase_requested.connect(func(facility_id: StringName) -> void: (observed["purchases"] as Array).append(facility_id))
	ui.campus_expansion_requested.connect(func() -> void: observed["campus"] += 1)
	await process_frame
	ui.show_blueprint(_snapshot())
	await process_frame
	await process_frame

	var main_panel := ui.find_child("CapitalBlueprintPanel", true, false) as PanelContainer
	var body_scroll := ui.find_child("CapitalBlueprintBodyScroll", true, false) as ScrollContainer
	var desktop_body := ui.find_child("CapitalBlueprintDesktopBody", true, false) as HBoxContainer
	var compact_body := ui.find_child("CapitalBlueprintCompactBody", true, false) as VBoxContainer
	var map_panel := ui.find_child("CapitalBlueprintMapPanel", true, false) as PanelContainer
	var inspector := ui.find_child("CapitalBlueprintInspector", true, false) as PanelContainer
	var action_rail := ui.find_child("CapitalBlueprintActionRail", true, false) as HBoxContainer
	var pin_button := ui.find_child("CapitalBlueprintPinButton", true, false) as Button
	var purchase_button := ui.find_child("CapitalBlueprintPurchaseButton", true, false) as Button
	var return_button := ui.find_child("CapitalBlueprintReturnButton", true, false) as Button
	var plan_summary := ui.find_child("CapitalBlueprintPlanSummary", true, false) as Label
	var campus_button := ui.find_child("CapitalBlueprintCampusExpansionButton", true, false) as Button
	var parcel_nodes := ui.find_children("CapitalBlueprintParcel_*", "Button", true, false)

	_check(ui.is_open(), "show_blueprint should reveal the full planning surface", failures)
	_check(ui.active_filter_id() == &"ready", "Blueprint should open on actionable READY plans instead of the full future catalog", failures)
	_check(ui.visible_facility_ids() == [&"candling_rework_bay", &"training_roost"], "the opening view should disclose only authoritative actionable plans", failures)
	_check(ui.layout_mode_name() == &"desktop", "1280x720 should use the desktop 70/30 composition", failures)
	_check(main_panel != null and main_panel.get_global_rect().end.x <= harness.size.x + 0.5, "desktop blueprint should stay inside its viewport", failures)
	_check(map_panel != null and inspector != null and map_panel.get_parent() == desktop_body and inspector.get_parent() == desktop_body, "desktop should place map and inspector side by side", failures)
	_check(map_panel != null and inspector != null and is_equal_approx(map_panel.size_flags_stretch_ratio, 7.0) and is_equal_approx(inspector.size_flags_stretch_ratio, 3.0), "desktop map/detail columns should retain the intended 70/30 weighting", failures)
	_check(action_rail != null and body_scroll != null and not body_scroll.is_ancestor_of(action_rail), "Return, Pin, and Authorize should remain in a fixed bottom rail", failures)
	_check(parcel_nodes.size() == 13, "the office map should create one stable button for every authoritative facility", failures)
	_check(ui.find_children("CapitalBlueprintFilter_*", "Button", true, false).size() == 4, "ALL, READY, BLOCKED, and OWNED should be persistent controls", failures)
	_check(campus_button != null and _contains_all(campus_button.text, ["campus portfolio", "services 1/3"]), "Capital Blueprint should expose the player-owned portfolio while retaining North Meadow's live utility stage", failures)
	_check(plan_summary != null and _contains_all(plan_summary.text, ["parcel 02", "owned", "blocked"]), "the pinned capital plan and readiness should remain visible in the header", failures)
	_check(return_button != null and pin_button != null and purchase_button != null and return_button.focus_mode == Control.FOCUS_ALL and pin_button.focus_mode == Control.FOCUS_ALL and purchase_button.focus_mode == Control.FOCUS_ALL, "fixed-rail actions should participate in natural keyboard focus order", failures)

	for facility_id: StringName in CapitalBlueprintModel.FACILITY_ORDER:
		var parcel := ui.find_child("CapitalBlueprintParcel_%s" % String(facility_id), true, false) as Button
		_check(parcel != null and parcel.focus_mode == Control.FOCUS_ALL, "%s parcel should be keyboard focusable" % String(facility_id), failures)
		_check(parcel != null and StringName(String(parcel.get_meta("facility_id", ""))) == facility_id, "%s parcel should retain its stable identity" % String(facility_id), failures)

	_check(ui.selected_facility_id() == &"candling_rework_bay", "the first actionable parcel should be the initial selection", failures)
	_check(pin_button != null and not pin_button.disabled, "the actionable opening parcel should preserve the optional Pin action", failures)
	_check(purchase_button != null and not purchase_button.disabled, "an authoritative READY upgrade should expose its purchase action", failures)
	_check(
		_contains_all(ui.inspector_accessible_text(), ["why now", "you get", "you owe", "after build", "gates", "$120.00", "+$5.00"]),
		"the inspector should expose only its five plain-language decision sections with exact economics",
		failures,
	)
	for section_id: String in ["WhyNow", "YouGet", "YouOwe", "AfterBuild", "Gates"]:
		_check(ui.find_child("CapitalBlueprint%s" % section_id, true, false) is Label, "%s inspector body should exist" % section_id, failures)

	ui.select_facility(&"candling_rework_bay")
	await process_frame
	_check((observed["previews"] as Array) == [&"candling_rework_bay"], "parcel selection should emit one stable preview intent", failures)
	_check(pin_button != null and not pin_button.disabled, "an unpinned selected parcel should expose Pin", failures)
	_check(purchase_button != null and not purchase_button.disabled and _contains_all(purchase_button.text, ["authorize", "parcel 01"]), "an authoritative READY parcel should expose its exact build action", failures)
	if pin_button != null:
		pin_button.pressed.emit()
	if purchase_button != null:
		purchase_button.pressed.emit()
	_check((observed["pins"] as Array) == [&"candling_rework_bay"], "Pin should emit intent without mutating the model", failures)
	_check((observed["purchases"] as Array) == [&"candling_rework_bay"], "Authorize should emit the stable purchase intent only", failures)
	if campus_button != null:
		campus_button.pressed.emit()
	_check(int(observed["campus"]) == 1, "Campus Portfolio should emit one host-owned planning intent without mutating simulation state", failures)

	_check(ui.set_filter(&"ready"), "READY should be a valid public filter", failures)
	_check(ui.visible_facility_ids() == [&"candling_rework_bay", &"training_roost"], "READY should use authoritative can_purchase state", failures)
	_check(ui.set_filter(&"owned"), "OWNED should be a valid public filter", failures)
	_check(ui.visible_facility_ids() == [&"farmer_brand_packing_annex", &"records_annex"], "OWNED should retain installed upgrade paths and maxed facilities", failures)
	_check(ui.set_filter(&"blocked"), "BLOCKED should be a valid public filter", failures)
	_check(&"farmer_brand_packing_annex" in ui.visible_facility_ids() and &"records_annex" not in ui.visible_facility_ids(), "BLOCKED should include held upgrades but exclude fully commissioned parcels", failures)
	_check(not ui.set_filter(&"invented"), "unknown filters should be rejected without changing presentation state", failures)
	_check(ui.set_filter(&"all") and ui.visible_facility_ids().size() == 13, "ALL PLANS should remain fully reachable before a campaign presentation reset", failures)
	ui.reset_presentation_filter()
	_check(ui.active_filter_id() == &"ready" and ui.visible_facility_ids() == [&"candling_rework_bay", &"training_roost"], "a new-campaign presentation reset should return the Blueprint to actionable READY plans", failures)
	_check(ui.set_filter(&"all") and ui.visible_facility_ids().size() == 13, "ALL PLANS should remain fully reachable after a campaign presentation reset", failures)

	await process_frame
	await process_frame
	var training := ui.find_child("CapitalBlueprintParcel_training_roost", true, false) as Button
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	if training != null:
		training.gui_input.emit(accept)
	await process_frame
	_check(ui.selected_facility_id() == &"training_roost", "semantic ui_accept should activate a focused parcel without a hardcoded key", failures)
	_check((observed["previews"] as Array).count(&"training_roost") == 1, "semantic activation should emit exactly one preview", failures)
	var right := InputEventAction.new()
	right.action = &"ui_right"
	right.pressed = true
	if training != null:
		training.gui_input.emit(right)
	await process_frame
	_check(ui.selected_facility_id() != &"training_roost", "semantic arrow actions should move map selection", failures)

	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	ui._unhandled_key_input(cancel)
	_check(int(observed["close"]) == 1, "semantic ui_cancel should request Return to Office", failures)
	_check(ui.is_open(), "close intent should not let presentation mutate host visibility", failures)

	harness.size = Vector2(844.0, 390.0)
	await process_frame
	await process_frame
	compact_body = ui.find_child("CapitalBlueprintCompactBody", true, false) as VBoxContainer
	_check(ui.layout_mode_name() == &"compact", "844x390 should switch to the stacked compact composition", failures)
	_check(map_panel != null and inspector != null and map_panel.get_parent() == compact_body and inspector.get_parent() == compact_body, "compact mode should stack map above inspector in one scroll surface", failures)
	_check(body_scroll != null and body_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "compact stacked content should remain vertically reachable", failures)
	_check(action_rail != null and not body_scroll.is_ancestor_of(action_rail), "compact scrolling should not move the fixed action rail", failures)
	if main_panel != null:
		var compact_rect := main_panel.get_global_rect()
		_check(compact_rect.position.x >= -0.5 and compact_rect.end.x <= harness.size.x + 0.5 and compact_rect.end.y <= harness.size.y + 0.5, "compact blueprint should fit the 844x390 viewport", failures)

	ui.set_restore_focus(office_focus)
	ui.hide_blueprint()
	await process_frame
	await process_frame
	_check(not ui.is_open() and root.gui_get_focus_owner() == office_focus, "direct Blueprint dismissal should restore keyboard focus to its visible Office origin", failures)

	ui.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAPITAL_BLUEPRINT_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAPITAL_BLUEPRINT_UI_TEST_PASSED parcels=13 inspector=5 desktop=70/30 compact=844x390 controls=semantic intents=only")
	quit(0)


func _snapshot() -> Dictionary:
	var catalog: Array[Dictionary] = []
	for facility_id: StringName in CapitalBlueprintModel.FACILITY_ORDER:
		catalog.append(_facility_record(facility_id, catalog.size()))
	return {
		"facility_catalog": catalog,
		"campus_expansion": {
			"parcel": {"owned": true},
			"services": {
				"circulation": {"connected": true},
				"power": {"connected": false},
				"cold_chain": {"connected": false},
			},
			"module": {"operational": false},
			"daily_recurring_cents": 200,
		},
		"capital_plan": {
			"has_pinned_plan": true,
			"pinned_capital_plan_id": &"farmer_brand_packing_annex",
		},
		"last_facility_purchase_receipt": {},
	}


func _facility_record(facility_id: StringName, index: int) -> Dictionary:
	var level := 0
	var maxed := false
	var can_purchase := facility_id in [&"candling_rework_bay", &"training_roost"]
	if facility_id == &"farmer_brand_packing_annex":
		level = 1
	if facility_id == &"records_annex":
		level = 3
		maxed = true
	return {
		"id": facility_id,
		"name": String(facility_id).replace("_", " ").capitalize(),
		"short_name": "PARCEL %02d" % (index + 1),
		"level": level,
		"next_level": mini(3, level + 1),
		"max_level": 3,
		"owned": level > 0,
		"installed": level > 0,
		"maxed": maxed,
		"can_purchase": can_purchase,
		"purchase_label": "AUTHORIZE PARCEL %02d / $%d.00" % [index + 1, 120 + index],
		"why_now": "The next review can reduce shell loss without hiding its recurring cost.",
		"benefits": ["Reduce cracked-egg leakage.", "Raise sound-claim value."],
		"tradeoffs": ["Adds a sanitation obligation."],
		"gates": ["Farmer review must be open."],
		"cost_cents": 12_000 + index * 100,
		"maintenance_delta_cents": 500,
		"supervisor_payroll_delta_cents": 250,
		"projected_spendable_fund_cents": 8_000,
		"projected_protected_reserve_cents": 3_800,
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
