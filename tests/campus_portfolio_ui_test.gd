extends SceneTree

const PortfolioUIScript := preload("res://features/office/campus_portfolio_ui.gd")
const ManagementUIThemeScript := preload("res://features/office/management_ui_theme.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observed := {
		"deeds": [] as Array[StringName],
		"projects": [] as Array[Dictionary],
		"assignments": [] as Array[Dictionary],
		"unassignments": [] as Array[StringName],
		"close": 0,
		"north": 0,
	}
	var harness := Control.new()
	harness.name = "CampusPortfolioUITestHarness"
	harness.size = Vector2(1280.0, 720.0)
	root.add_child(harness)
	var ui := PortfolioUIScript.new() as CampusPortfolioUI
	harness.add_child(ui)
	ui.deed_requested.connect(func(parcel_id: StringName) -> void: (observed["deeds"] as Array).append(parcel_id))
	ui.project_requested.connect(func(module_id: StringName, pad_id: StringName) -> void: (observed["projects"] as Array).append({"module_id": module_id, "pad_id": pad_id}))
	ui.staff_assignment_requested.connect(func(module_id: StringName, worker_id: Variant) -> void: (observed["assignments"] as Array).append({"module_id": module_id, "worker_id": worker_id}))
	ui.staff_unassignment_requested.connect(func(module_id: StringName) -> void: (observed["unassignments"] as Array).append(module_id))
	ui.close_requested.connect(func() -> void: observed["close"] += 1)
	ui.north_meadow_details_requested.connect(func() -> void: observed["north"] += 1)
	await process_frame
	ui.show_portfolio(_snapshot())
	await process_frame
	await process_frame

	var main_panel := ui.find_child("CampusPortfolioPanel", true, false) as PanelContainer
	var desktop_body := ui.find_child("CampusPortfolioDesktopBody", true, false) as HBoxContainer
	var compact_body := ui.find_child("CampusPortfolioCompactBody", true, false) as VBoxContainer
	var map_panel := ui.find_child("CampusPortfolioMapPanel", true, false) as PanelContainer
	var inspector := ui.find_child("CampusPortfolioInspector", true, false) as PanelContainer
	var body_scroll := ui.find_child("CampusPortfolioBodyScroll", true, false) as ScrollContainer
	var action_rail := ui.find_child("CampusPortfolioActionRail", true, false) as HBoxContainer
	var action_button := ui.find_child("CampusPortfolioActionButton", true, false) as Button
	var return_button := ui.find_child("CampusPortfolioReturnButton", true, false) as Button
	var north_button := ui.find_child("CampusPortfolioNorthMeadowDetailsButton", true, false) as Button
	var glance_grid := ui.find_child("CampusPortfolioGlanceGrid", true, false) as GridContainer
	var pad_glance := ui.find_child("CampusPortfolioPadGlance", true, false) as Label
	var cost_glance := ui.find_child("CampusPortfolioCostGlance", true, false) as Label
	var time_glance := ui.find_child("CampusPortfolioTimeGlance", true, false) as Label
	var funds_glance := ui.find_child("CampusPortfolioFundsGlance", true, false) as Label
	var capacity_glance := ui.find_child("CampusPortfolioCapacityGlance", true, false) as Label
	var staff_glance := ui.find_child("CampusPortfolioStaffGlance", true, false) as Label
	var primary_effect_glance := ui.find_child("CampusPortfolioEffectPrimaryGlance", true, false) as Label
	var secondary_effect_glance := ui.find_child("CampusPortfolioEffectSecondaryGlance", true, false) as Label
	var exact_economics := ui.find_child("CampusPortfolioInspectorEconomics", true, false) as Label
	var exact_capacity := ui.find_child("CampusPortfolioInspectorCapacity", true, false) as Label
	var exact_effect := ui.find_child("CampusPortfolioInspectorEffect", true, false) as Label

	_check(ui.is_open(), "show_portfolio should reveal the planner", failures)
	_check(ui.layout_mode_name() == &"desktop", "1280x720 should use the desktop planner", failures)
	_check(main_panel != null and main_panel.get_global_rect().end.x <= harness.size.x + 0.5 and main_panel.get_global_rect().end.y <= harness.size.y + 0.5, "full-screen planner should remain inside the viewport", failures)
	_check(map_panel != null and inspector != null and map_panel.get_parent() == desktop_body and inspector.get_parent() == desktop_body, "desktop should use a spatial map beside one contextual inspector", failures)
	_check(map_panel != null and inspector != null and is_equal_approx(map_panel.size_flags_stretch_ratio, 6.5) and is_equal_approx(inspector.size_flags_stretch_ratio, 3.5), "desktop should retain its 65/35 planning emphasis", failures)
	_check(action_rail != null and body_scroll != null and not body_scroll.is_ancestor_of(action_rail), "the one economic CTA should remain in a fixed action rail", failures)
	_check(ui.find_children("CampusPortfolioParcelCard_*", "PanelContainer", true, false).size() == 3, "all three spatial parcel cards should be visible", failures)
	_check(ui.find_children("CampusPortfolioPad_*", "Button", true, false).size() == 4, "every filed construction pad should remain selectable", failures)
	_check(ui.find_children("CampusPortfolioModule_*", "Button", true, false).size() == 2, "the selected parcel should show only its two relevant module files", failures)
	_check(ui.find_children("CampusPortfolioProject_*", "VBoxContainer", true, false).size() >= 1, "active project queue should expose authored project records", failures)
	_check(ui.find_children("CampusPortfolioStage_job_grain_01_*", "Label", true, false).size() == 3, "every authored construction stage should be visible", failures)
	_check(glance_grid != null and glance_grid.columns == 2 and glance_grid.get_child_count() == 8, "selected-project economics should resolve into eight two-line glance tiles", failures)
	_check(pad_glance != null and _contains_all(pad_glance.text, ["pad", "west apron", "ready"]), "pad glance should lead with the selected location and state", failures)
	_check(cost_glance != null and _contains_all(cost_glance.text, ["cost", "$140", "$6.50/day"]), "cost glance should combine capital and daily liability without redundant prose", failures)
	_check(time_glance != null and _contains_all(time_glance.text, ["time", "2 shifts"]), "time glance should expose construction duration", failures)
	_check(funds_glance != null and _contains_all(funds_glance.text, ["after", "not filed"]), "missing projections should say not filed instead of inventing zero-dollar balances", failures)
	_check(capacity_glance != null and _contains_all(capacity_glance.text, ["build load", "1 crew", "pwr 2", "cold 0"]), "build-load glance should compress the three shared capacities", failures)
	_check(staff_glance != null and _contains_all(staff_glance.text, ["staff", "1 hen"]), "staff glance should expose the dedicated-perch requirement", failures)
	_check(primary_effect_glance != null and secondary_effect_glance != null and _contains_all(primary_effect_glance.tooltip_text, ["adds one collection rail branch", "relieves routing overflow"]), "benefit tiles should retain both exact authored effects on inspection", failures)
	_check(cost_glance != null and _contains_all(String(cost_glance.get_meta("accessible_text", "")), ["capital", "$140.00", "daily liability", "$6.50", "west rail tie-in cleared"]), "cost glance accessibility should retain exact money and filing reason", failures)
	_check(exact_economics != null and exact_capacity != null and exact_effect != null and not exact_economics.visible and not exact_capacity.visible and not exact_effect.visible, "exact semantic ledgers should remain populated but visually collapsed", failures)
	_check(exact_economics != null and _contains_all(exact_economics.text, ["capital", "$140.00", "daily liability", "$6.50", "build time", "2 shifts"]), "collapsed economics should retain every authored term", failures)
	_check(exact_capacity != null and _contains_all(exact_capacity.text, ["contractors", "power", "cold", "staff"]), "collapsed capacity should retain every authored resource term", failures)
	_check(exact_effect != null and _contains_all(exact_effect.text, ["adds one collection rail branch", "relieves routing overflow"]), "collapsed effects should retain the exact authored benefit copy", failures)

	_check(_label_contains(ui, "CampusPortfolioResource_feed_fund", ["feed fund", "$512.50"]), "resource rail should show exact Feed Fund", failures)
	_check(_label_contains(ui, "CampusPortfolioResource_spendable", ["spendable", "$325.00"]), "resource rail should show exact spendable fund", failures)
	_check(_label_contains(ui, "CampusPortfolioResource_reserve", ["protected", "$187.50"]), "resource rail should show exact reserve", failures)
	_check(_label_contains(ui, "CampusPortfolioResource_contractors", ["1 / 2"]), "resource rail should show contractor use and capacity", failures)
	_check(_label_contains(ui, "CampusPortfolioResource_power", ["4 / 8"]), "resource rail should show power use and capacity", failures)
	_check(_label_contains(ui, "CampusPortfolioResource_cold", ["2 / 6"]), "resource rail should show cold use and capacity", failures)

	_check(ui.selected_parcel_id() == &"north_meadow" and ui.selected_pad_id() == &"meadow_west" and ui.selected_module_id() == &"collection_rail_hub", "projection-selected parcel, pad, and module should establish context", failures)
	_check(action_button != null and not action_button.disabled and _contains_all(action_button.text, ["queue", "collection rail hub", "$140.00", "2 shifts"]), "ready module should expose one exact queue CTA", failures)
	var portfolio_primary := ui.primary_action_state()
	ui.focus_primary_action()
	_check(
		String(portfolio_primary.get("copy", "")) == action_button.text
		and String(portfolio_primary.get("action_id", ""))
		== "campus_portfolio_file"
		and action_button.has_focus(),
		"Campus Portfolio should publish and focus its exact enabled filing",
		failures,
	)
	_check(_contains_all(ui.accessible_text(), ["campus portfolio", "3 parcels", "collection rail hub", "$140.00", "contractors", "power", "cold"]), "accessible copy should cover the visible portfolio decision", failures)
	if action_button != null:
		action_button.pressed.emit()
	_check((observed["projects"] as Array) == [{"module_id": &"collection_rail_hub", "pad_id": &"meadow_west"}], "primary CTA should emit exact module and pad intent", failures)
	_check(ui.presentation_state().get("projects", []).size() == 1, "project intent should not optimistically mutate the queue", failures)

	if north_button != null:
		north_button.pressed.emit()
	_check(int(observed["north"]) == 1, "North Meadow detail affordance should emit its host-owned intent", failures)

	# A different parcel changes the same single CTA to its authoritative deed.
	_check(ui.select_parcel(&"orchard_row"), "Orchard Row should be selectable", failures)
	await process_frame
	action_button = ui.find_child("CampusPortfolioActionButton", true, false) as Button
	_check(action_button != null and not action_button.disabled and _contains_all(action_button.text, ["buy", "orchard row", "$95.00"]), "unowned ready parcel should expose its exact deed CTA", failures)
	if action_button != null:
		action_button.pressed.emit()
	_check((observed["deeds"] as Array) == [&"orchard_row"], "deed CTA should emit only the stable parcel identity", failures)
	_check(not bool((ui.presentation_state().get("parcels", []) as Array)[1].get("owned", true)), "deed intent should not optimistically file ownership", failures)

	# Staffing controls emit named-worker intents and retain authoritative state.
	ui.select_parcel(&"north_meadow")
	ui.select_module(&"grain_recovery_mill")
	await process_frame
	var staff_status := ui.find_child("CampusPortfolioStaffStatus", true, false) as Label
	var unassign_button := ui.find_child("CampusPortfolioUnassignButton", true, false) as Button
	_check(staff_status != null and _contains_all(staff_status.text, ["current perch", "mabel"]), "active module assignment should identify its named worker", failures)
	_check(unassign_button != null and unassign_button.visible and not unassign_button.disabled, "assigned module should expose a clear-perch control", failures)
	if unassign_button != null:
		unassign_button.pressed.emit()
	_check((observed["unassignments"] as Array) == [&"grain_recovery_mill"], "clear-perch should emit the stable module only", failures)
	_check((ui.presentation_state().get("assignments", {}) as Dictionary).get(&"grain_recovery_mill", null) == 17, "unassignment intent should not mutate authoritative staffing", failures)

	ui.select_parcel(&"creekside_yard")
	ui.select_module(&"creekside_chilling_exchange")
	await process_frame
	_check(_contains_all(primary_effect_glance.text, ["storage", "+12 eggs"]), "storage effect should resolve into one compact benefit tile", failures)
	_check(_contains_all(secondary_effect_glance.text, ["pickup", "90% to 95% value"]), "pickup effect should use a Web-font-safe direction phrase", failures)
	_check(_contains_all(secondary_effect_glance.tooltip_text, ["raises staffed overflow pickup from 90% to 95% of recorded value"]), "pickup tile should retain the exact authored effect on inspection", failures)
	var selector := ui.find_child("CampusPortfolioWorkerSelector", true, false) as OptionButton
	var assign_button := ui.find_child("CampusPortfolioAssignButton", true, false) as Button
	_check(selector != null and selector.item_count == 2, "staffing selector should retain both named workers and explicit eligibility", failures)
	if selector != null:
		selector.select(1)
		selector.item_selected.emit(1)
	await process_frame
	_check(assign_button != null and not assign_button.disabled, "eligible Juniper selection should enable assignment", failures)
	if assign_button != null:
		assign_button.pressed.emit()
	_check((observed["assignments"] as Array) == [{"module_id": &"creekside_chilling_exchange", "worker_id": 23}], "staff assignment should emit exact module and worker identities", failures)

	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	ui._unhandled_key_input(cancel)
	_check(int(observed["close"]) == 1 and ui.is_open(), "ui_cancel should emit close without hiding host-owned state", failures)
	_check(return_button != null and return_button.focus_mode == Control.FOCUS_ALL and action_button != null and action_button.focus_mode == Control.FOCUS_ALL, "fixed actions should remain keyboard focusable", failures)

	# Compact landscape stacks planning surfaces while the fixed CTA remains reachable.
	harness.size = Vector2(844.0, 390.0)
	await process_frame
	await process_frame
	compact_body = ui.find_child("CampusPortfolioCompactBody", true, false) as VBoxContainer
	_check(ui.layout_mode_name() == &"compact", "844x390 should switch to compact planning", failures)
	_check(compact_body != null and map_panel.get_parent() == compact_body and inspector.get_parent() == compact_body, "compact planner should stack map above inspector", failures)
	_check(body_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "compact body should scroll vertically without horizontal scrolling", failures)
	_check(not body_scroll.is_ancestor_of(action_rail), "compact scrolling should not move the primary CTA", failures)
	_check(main_panel.get_global_rect().end.x <= harness.size.x + 0.5 and main_panel.get_global_rect().end.y <= harness.size.y + 0.5, "compact planner should fit 844x390", failures)
	_check(action_rail.get_global_rect().end.y <= harness.size.y + 0.5, "compact action rail should remain physically reachable", failures)

	# Portrait keeps resource cards and the fixed action inside the viewport.
	harness.size = Vector2(390.0, 844.0)
	await process_frame
	await process_frame
	_check(ui.layout_mode_name() == &"compact", "390x844 should retain compact mode", failures)
	var viewport_bounds := Rect2(Vector2.ZERO, harness.size)
	_check(_visible_children_fit(ui, viewport_bounds), "portrait planner should not require horizontal scrolling (%s)" % _first_horizontal_overflow(ui, viewport_bounds), failures)
	_check(action_button.get_global_rect().end.x <= harness.size.x + 0.5, "portrait contextual CTA should remain inside the viewport (rect=%s)" % action_button.get_global_rect(), failures)

	# Maximum supported interface scale and moderately expanded English copy
	# must preserve the complete planning route, not merely the base typography.
	ui.theme = ManagementUIThemeScript.create_theme(false, 1.5)
	_apply_explicit_font_scale(ui, 1.5)
	_expand_interface_copy(ui)
	await process_frame
	await process_frame
	_check(
		_visible_children_fit(ui, viewport_bounds),
		"150-percent expanded-copy portfolio should remain inside 390x844 (%s; largest=%s)"
		% [
			_first_horizontal_overflow(ui, viewport_bounds),
			_largest_minimum_widths(ui),
		],
		failures,
	)
	_check(
		body_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
		"150-percent portfolio planning should remain vertical-scroll-only",
		failures,
	)
	_check(
		action_rail.get_global_rect().end.y <= harness.size.y + 0.5,
		"150-percent portfolio action rail should remain physically reachable",
		failures,
	)

	ui.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPUS_PORTFOLIO_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_PORTFOLIO_UI_TEST_PASSED layout=65/35+compact parcels=3 resources=6 glance=8x2line+exact-hidden queue=staged staffing=named CTA=deed+project intents=only responsive=1280+844+390 resilience=150-percent+expanded-copy")
	quit(0)


func _snapshot() -> Dictionary:
	return {
		"feed_fund_cents": 51_250,
		"spendable_fund_cents": 32_500,
		"protected_reserve_cents": 18_750,
		"workers": {
			17: {"name": "Mabel", "role": "Routing analyst", "available": true, "eligible_module_ids": [&"grain_recovery_mill", &"collection_rail_hub"]},
			23: {"name": "Juniper", "role": "Cold-chain clerk", "available": true, "eligible_module_ids": [&"creekside_chilling_exchange"]},
		},
		"campus_portfolio": {
			"selected_parcel_id": &"north_meadow",
			"selected_pad_id": &"meadow_west",
			"selected_module_id": &"collection_rail_hub",
			"contractor": {"active_slots": 1, "capacity_slots": 2},
			"network": {"power_reserved_units": 4, "power_capacity_units": 8, "cold_reserved_units": 2, "cold_capacity_units": 6},
			"parcels": [
				{"id": &"north_meadow", "name": "North Meadow", "owned": true, "can_purchase": false, "deed_cost_cents": 8_500, "daily_cost_cents": 300, "reason": "North Meadow deed already filed.", "pads": [
					{"id": &"meadow_west", "name": "West Apron", "blocked": false, "reason": "Rail and circulation routes clear."},
					{"id": &"meadow_east", "name": "East Apron", "blocked": true, "reason": "Protected rail trunk crosses this pad."},
				]},
				{"id": &"orchard_row", "name": "Orchard Row", "owned": false, "can_purchase": true, "deed_cost_cents": 9_500, "daily_cost_cents": 375, "reason": "Boundary survey filed; deed is ready.", "pads": [{"id": &"orchard_loading", "name": "Loading Pad", "blocked": false}]},
				{"id": &"creekside_yard", "name": "Creekside Yard", "owned": true, "can_purchase": false, "reason": "Creekside deed already filed.", "pads": [{"id": &"creek_exchange", "name": "Exchange Pad", "blocked": false}]},
			],
			"modules": [
				{"id": &"collection_rail_hub", "name": "Collection Rail Hub", "parcel_id": &"north_meadow", "allowed_pad_ids": [&"meadow_west", &"meadow_east"], "capital_cost_cents": 14_000, "daily_cost_cents": 650, "duration_shifts": 2, "contractor_slots": 1, "power_units": 2, "cold_units": 0, "staff_required": 1, "benefits": ["Adds one collection rail branch.", "Relieves routing overflow."], "quote": {"can_authorize": true, "reason": "Contractor and power capacity are filed.", "cost_cents": 14_000, "added_daily_cost_cents": 650, "duration_shifts": 2}, "pad_quotes": {"meadow_west": {"can_authorize": true, "reason": "West rail tie-in cleared.", "cost_cents": 14_000, "added_daily_cost_cents": 650, "duration_shifts": 2}}},
				{"id": &"grain_recovery_mill", "name": "Grain Recovery Mill", "parcel_id": &"north_meadow", "allowed_pad_ids": [&"meadow_west"], "capital_cost_cents": 11_500, "daily_cost_cents": 575, "duration_shifts": 2, "power_units": 2, "staff_required": 1, "can_authorize": false, "reason": "A mill project is already active."},
				{"id": &"creekside_chilling_exchange", "name": "Creekside Chilling Exchange", "parcel_id": &"creekside_yard", "allowed_pad_ids": [&"creek_exchange"], "capital_cost_cents": 16_000, "daily_cost_cents": 800, "duration_shifts": 3, "contractor_slots": 1, "power_units": 2, "cold_units": 3, "staff_required": 1, "can_authorize": true, "reason": "Creekside service routes are clear.", "benefits": ["+12 finished-egg storage positions while staffed and powered", "Raises staffed overflow pickup from 90% to 95% of recorded value"]},
				{"id": &"contractor_roost", "name": "Contractor Roost", "parcel_id": &"orchard_row", "allowed_pad_ids": [&"orchard_loading"], "capital_cost_cents": 12_500, "daily_cost_cents": 700, "duration_shifts": 2, "can_authorize": false, "reason": "Purchase Orchard Row first."},
			],
			"projects": [{"project_id": &"job_grain_01", "module_id": &"grain_recovery_mill", "module_name": "Grain Recovery Mill", "parcel_id": &"north_meadow", "pad_id": &"meadow_west", "status": &"building", "status_label": "FRAMING", "stage_id": &"frame", "progress_shifts": 1, "duration_shifts": 2, "remaining_shifts": 1, "stages": [
				{"id": &"stakes", "label": "Survey Stakes", "status": &"complete"},
				{"id": &"frame", "label": "Timber Frame", "status": &"active"},
				{"id": &"commission", "label": "Commission", "status": &"pending"},
			]}],
			"assignments": {"grain_recovery_mill": 17},
		},
	}


func _label_contains(ui: Control, node_name: String, needles: Array[String]) -> bool:
	var label := ui.find_child(node_name, true, false) as Label
	return label != null and _contains_all(label.text, needles)


func _visible_children_fit(root_control: Control, bounds: Rect2) -> bool:
	for node: Node in root_control.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		if rect.position.x < bounds.position.x - 1.0 or rect.end.x > bounds.end.x + 1.0:
			return false
	return true


func _first_horizontal_overflow(root_control: Control, bounds: Rect2) -> String:
	for node: Node in root_control.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		if rect.position.x < bounds.position.x - 1.0 or rect.end.x > bounds.end.x + 1.0:
			return "%s=%s bounds=%s" % [control.name, rect, bounds]
	return "none"


func _largest_minimum_widths(root_control: Control) -> String:
	var rows: Array[Dictionary] = []
	for node: Node in root_control.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		rows.append({
			"name": String(control.name),
			"minimum": control.get_combined_minimum_size().x,
			"width": control.size.x,
		})
	rows.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return float(left.get("minimum", 0.0)) > float(right.get("minimum", 0.0))
	)
	var summaries: Array[String] = []
	for index: int in mini(24, rows.size()):
		var row := rows[index]
		summaries.append("%s:min=%.1f/size=%.1f" % [
			String(row.get("name", "")),
			float(row.get("minimum", 0.0)),
			float(row.get("width", 0.0)),
		])
	return ", ".join(summaries)


func _apply_explicit_font_scale(root_control: Control, scale: float) -> void:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
		if control == null or not control.has_theme_font_size_override("font_size"):
			continue
		var base_size := control.get_theme_font_size("font_size")
		control.add_theme_font_size_override(
			"font_size",
			maxi(10, roundi(float(base_size) * scale)),
		)


func _expand_interface_copy(root_control: Control) -> void:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		if node_value is OptionButton:
			var option := node_value as OptionButton
			for item_index: int in range(option.item_count):
				option.set_item_text(
					item_index,
					_expanded(option.get_item_text(item_index)),
				)
		elif node_value is Button:
			var button := node_value as Button
			button.text = _expanded(button.text)
		elif node_value is Label:
			var label := node_value as Label
			label.text = _expanded(label.text)


func _expanded(source: String) -> String:
	var expanded := source
	for vowel: String in ["a", "e", "i", "o", "u", "A", "E", "I", "O", "U"]:
		expanded = expanded.replace(vowel, vowel + vowel)
	return expanded


func _contains_all(text_value: String, needles: Array[String]) -> bool:
	var lowered := text_value.to_lower()
	for needle: String in needles:
		if needle.to_lower() not in lowered:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
