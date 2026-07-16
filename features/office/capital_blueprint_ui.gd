class_name CapitalBlueprintUI
extends Control

## Full-screen, intent-only capital planning surface.
##
## The UI consumes CapitalBlueprintModel projections and emits stable facility
## identities. Office remains responsible for previewing, pinning, purchasing,
## saving, and restoring prior focus.

signal close_requested
signal preview_requested(facility_id: StringName)
signal pin_requested(facility_id: StringName)
signal purchase_requested(facility_id: StringName)
signal campus_expansion_requested

const BlueprintModelScript := preload("res://features/office/capital_blueprint_model.gd")
const ManagementTheme := preload("res://features/office/management_ui_theme.gd")

const COMPACT_BREAKPOINT := 900.0
const COLOR_INK := Color("eef1df")
const COLOR_MUTED := Color("aeb8c4")
const COLOR_BRASS := Color("e7c56e")
const COLOR_TEAL := Color("73b5a7")
const COLOR_RUST := Color("d68a68")
const COLOR_NAVY := Color("101923")
const COLOR_PANEL := Color("17232d")

const FILTER_LABELS := {
	&"all": "ALL PLANS",
	&"ready": "READY",
	&"blocked": "FUTURE",
	&"owned": "OWNED",
}

var _model := CapitalBlueprintModel.new()
var _campus_expansion: Dictionary = {}
var _campus_portfolio: Dictionary = {}
var _active_filter := CapitalBlueprintModel.FILTER_READY
var _selected_facility_id := &""
var _return_focus: WeakRef
var _layout_mode := &"desktop"
var _last_activation_frame_by_id: Dictionary = {}

var _main_panel: PanelContainer
var _plan_summary_label: Label
var _filter_buttons: Dictionary = {}
var _campus_expansion_button: Button
var _body_scroll: ScrollContainer
var _desktop_body: HBoxContainer
var _compact_body: VBoxContainer
var _active_body: Container
var _map_panel: PanelContainer
var _map_canvas: Control
var _zone_panels: Dictionary = {}
var _zone_labels: Dictionary = {}
var _parcel_buttons: Dictionary = {}
var _inspector_panel: PanelContainer
var _inspector_title: Label
var _inspector_status: Label
var _inspector_bodies: Dictionary = {}
var _return_button: Button
var _pin_button: Button
var _purchase_button: Button


func _ready() -> void:
	name = "CapitalBlueprintUI"
	theme = ManagementTheme.create_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_apply_responsive_layout)
	_build_interface()
	visible = false
	set_process_unhandled_key_input(false)
	_apply_responsive_layout()


func _exit_tree() -> void:
	# Responsive reparenting keeps one layout container intentionally detached.
	# Detached CanvasItems are not owned by the scene tree, so release that empty
	# shell explicitly when the standalone surface is destroyed.
	for body: Container in [_desktop_body, _compact_body]:
		if body != null and is_instance_valid(body) and body.get_parent() == null:
			body.free()


func apply_snapshot(snapshot: Dictionary) -> void:
	var prior_selection := _selected_facility_id
	_model.apply_snapshot(snapshot)
	_campus_expansion = (snapshot.get("campus_expansion", {}) as Dictionary).duplicate(true)
	_campus_portfolio = (snapshot.get("campus_portfolio", {}) as Dictionary).duplicate(true)
	_ensure_parcel_buttons()
	_select_relevant_filter_if_empty()
	var visible_facilities := _model.facilities(_active_filter)
	if not prior_selection.is_empty() and _facility_in_entries(prior_selection, visible_facilities):
		_selected_facility_id = prior_selection
	elif _model.pinned_facility_id() != &"" and _facility_in_entries(_model.pinned_facility_id(), visible_facilities):
		_selected_facility_id = _model.pinned_facility_id()
	else:
		_selected_facility_id = _first_facility_id(visible_facilities)
	_refresh()


func _select_relevant_filter_if_empty() -> void:
	# Opening the Blueprint should answer "what can I do now?" before exposing
	# the entire long-range campus catalog. The full catalog remains available
	# through ALL PLANS, while old saves with only commissioned rooms land on the
	# owned file instead of an empty page.
	if not _model.facilities(_active_filter).is_empty():
		return
	if not _model.facilities(CapitalBlueprintModel.FILTER_READY).is_empty():
		_active_filter = CapitalBlueprintModel.FILTER_READY
	elif not _model.facilities(CapitalBlueprintModel.FILTER_OWNED).is_empty():
		_active_filter = CapitalBlueprintModel.FILTER_OWNED
	else:
		_active_filter = CapitalBlueprintModel.FILTER_ALL


func show_blueprint(snapshot: Dictionary = {}) -> void:
	if not snapshot.is_empty():
		apply_snapshot(snapshot)
	visible = true
	set_process_unhandled_key_input(true)
	_refresh()
	call_deferred("_focus_selected_or_return")


func hide_blueprint(restore_focus: bool = true) -> void:
	visible = false
	set_process_unhandled_key_input(false)
	if restore_focus and _return_focus != null:
		var target: Variant = _return_focus.get_ref()
		if target is Control and is_instance_valid(target) and (target as Control).is_visible_in_tree():
			(target as Control).call_deferred("grab_focus")


func set_restore_focus(control: Control) -> void:
	_return_focus = weakref(control) if control != null else null


func is_open() -> bool:
	return visible


func selected_facility_id() -> StringName:
	return _selected_facility_id


func active_filter_id() -> StringName:
	return _active_filter


func layout_mode_name() -> StringName:
	return _layout_mode


func visible_facility_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for facility: Dictionary in _model.facilities(_active_filter):
		result.append(StringName(String(facility.get("id", ""))))
	return result


func inspector_accessible_text() -> String:
	if _selected_facility_id == &"":
		return "No capital parcel is selected."
	var facility := _model.facility(_selected_facility_id)
	if facility.is_empty():
		return "The selected capital parcel is not in the authoritative catalog."
	var sections: Array[String] = [
		String(_inspector_title.text),
		String(_inspector_status.text),
	]
	for section_id: StringName in [&"why_now", &"you_get", &"you_owe", &"after_build", &"gates"]:
		var label := _inspector_bodies.get(section_id) as Label
		if label != null:
			sections.append("%s: %s" % [String(section_id).replace("_", " "), label.text])
	return " ".join(sections).replace("\n", "; ")


func select_facility(facility_id: StringName, emit_preview: bool = true) -> bool:
	if _model.facility(facility_id).is_empty():
		return false
	_selected_facility_id = facility_id
	_refresh_parcel_buttons()
	_refresh_inspector()
	if emit_preview:
		preview_requested.emit(facility_id)
	return true


func set_filter(filter_id: StringName) -> bool:
	if filter_id not in CapitalBlueprintModel.FILTER_ORDER:
		return false
	_active_filter = filter_id
	var visible_facilities := _model.facilities(_active_filter)
	if not _facility_in_entries(_selected_facility_id, visible_facilities):
		_selected_facility_id = _first_facility_id(visible_facilities)
	_refresh()
	return true


func reset_presentation_filter() -> void:
	# Campaign state is authoritative, but the player's catalog filter is local
	# presentation state. A fresh file should always begin with actionable plans;
	# ALL PLANS remains available through the normal public filter API.
	set_filter(CapitalBlueprintModel.FILTER_READY)


func _build_interface() -> void:
	var scrim := ColorRect.new()
	scrim.name = "CapitalBlueprintScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.025, 0.04, 0.055, 0.94)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	_main_panel = PanelContainer.new()
	_main_panel.name = "CapitalBlueprintPanel"
	_main_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_panel.offset_left = 14.0
	_main_panel.offset_top = 12.0
	_main_panel.offset_right = -14.0
	_main_panel.offset_bottom = -12.0
	_main_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_main_panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL, COLOR_BRASS, 12, 2))
	add_child(_main_panel)

	var outer_margin := MarginContainer.new()
	outer_margin.name = "CapitalBlueprintOuterMargin"
	outer_margin.add_theme_constant_override("margin_left", 16)
	outer_margin.add_theme_constant_override("margin_right", 16)
	outer_margin.add_theme_constant_override("margin_top", 12)
	outer_margin.add_theme_constant_override("margin_bottom", 12)
	_main_panel.add_child(outer_margin)

	var page := VBoxContainer.new()
	page.name = "CapitalBlueprintPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 8)
	outer_margin.add_child(page)

	var header := HBoxContainer.new()
	header.name = "CapitalBlueprintHeader"
	header.custom_minimum_size.y = 42.0
	header.add_theme_constant_override("separation", 16)
	page.add_child(header)
	var title := _make_label("CAPITAL BLUEPRINT", 23, COLOR_BRASS)
	title.name = "CapitalBlueprintTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_plan_summary_label = _make_label("NO CAPITAL PLAN PINNED", 12, COLOR_TEAL)
	_plan_summary_label.name = "CapitalBlueprintPlanSummary"
	_plan_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_plan_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_plan_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_plan_summary_label.custom_minimum_size.x = 310.0
	header.add_child(_plan_summary_label)

	var filters := HFlowContainer.new()
	filters.name = "CapitalBlueprintFilters"
	filters.custom_minimum_size.y = 36.0
	filters.add_theme_constant_override("h_separation", 7)
	filters.add_theme_constant_override("v_separation", 4)
	page.add_child(filters)
	for filter_id: StringName in CapitalBlueprintModel.FILTER_ORDER:
		var button := Button.new()
		button.name = "CapitalBlueprintFilter_%s" % String(filter_id)
		button.custom_minimum_size = Vector2(108.0, 32.0)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_filter_pressed.bind(filter_id))
		filters.add_child(button)
		_filter_buttons[filter_id] = button
	_campus_expansion_button = Button.new()
	_campus_expansion_button.name = "CapitalBlueprintCampusExpansionButton"
	_campus_expansion_button.text = "CAMPUS PORTFOLIO  /  LAND & UTILITIES"
	_campus_expansion_button.custom_minimum_size = Vector2(260.0, 32.0)
	_campus_expansion_button.focus_mode = Control.FOCUS_ALL
	_campus_expansion_button.theme_type_variation = &"PrimaryButton"
	_campus_expansion_button.pressed.connect(func() -> void: campus_expansion_requested.emit())
	filters.add_child(_campus_expansion_button)

	_body_scroll = ScrollContainer.new()
	_body_scroll.name = "CapitalBlueprintBodyScroll"
	_body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(_body_scroll)

	_desktop_body = HBoxContainer.new()
	_desktop_body.name = "CapitalBlueprintDesktopBody"
	_desktop_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_desktop_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desktop_body.add_theme_constant_override("separation", 10)

	_compact_body = VBoxContainer.new()
	_compact_body.name = "CapitalBlueprintCompactBody"
	_compact_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compact_body.add_theme_constant_override("separation", 8)

	_build_map_panel()
	_build_inspector_panel()
	_active_body = _desktop_body
	_body_scroll.add_child(_active_body)
	_active_body.add_child(_map_panel)
	_active_body.add_child(_inspector_panel)

	var action_rail := HBoxContainer.new()
	action_rail.name = "CapitalBlueprintActionRail"
	action_rail.custom_minimum_size.y = 46.0
	action_rail.add_theme_constant_override("separation", 9)
	page.add_child(action_rail)
	_return_button = Button.new()
	_return_button.name = "CapitalBlueprintReturnButton"
	_return_button.text = "RETURN TO OFFICE"
	_return_button.custom_minimum_size = Vector2(170.0, 44.0)
	_return_button.focus_mode = Control.FOCUS_ALL
	_return_button.pressed.connect(_request_close)
	action_rail.add_child(_return_button)
	var rail_spacer := Control.new()
	rail_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_rail.add_child(rail_spacer)
	_pin_button = Button.new()
	_pin_button.name = "CapitalBlueprintPinButton"
	_pin_button.text = "PIN AS CAPITAL PLAN"
	_pin_button.custom_minimum_size = Vector2(204.0, 44.0)
	_pin_button.focus_mode = Control.FOCUS_ALL
	_pin_button.pressed.connect(_on_pin_pressed)
	action_rail.add_child(_pin_button)
	_purchase_button = Button.new()
	_purchase_button.name = "CapitalBlueprintPurchaseButton"
	_purchase_button.text = "AUTHORIZE BUILD"
	_purchase_button.theme_type_variation = &"PrimaryButton"
	_purchase_button.custom_minimum_size = Vector2(218.0, 44.0)
	_purchase_button.focus_mode = Control.FOCUS_ALL
	_purchase_button.pressed.connect(_on_purchase_pressed)
	action_rail.add_child(_purchase_button)


func _build_map_panel() -> void:
	_map_panel = PanelContainer.new()
	_map_panel.name = "CapitalBlueprintMapPanel"
	_map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_panel.size_flags_stretch_ratio = 7.0
	_map_panel.custom_minimum_size = Vector2(520.0, 310.0)
	_map_panel.add_theme_stylebox_override("panel", _panel_style(Color("111d26"), Color("435867"), 9, 1))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_map_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 5)
	margin.add_child(column)
	var map_heading := _make_label("SURVEYED CAMPUS PARCELS", 12, COLOR_MUTED)
	map_heading.name = "CapitalBlueprintMapHeading"
	column.add_child(map_heading)
	_map_canvas = Control.new()
	_map_canvas.name = "CapitalBlueprintMapCanvas"
	_map_canvas.clip_contents = true
	_map_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	_map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_canvas.custom_minimum_size.y = 274.0
	_map_canvas.resized.connect(_layout_map_geometry)
	column.add_child(_map_canvas)

	for category: Dictionary in _model.categories():
		var category_id := StringName(String(category.get("id", "")))
		var zone := PanelContainer.new()
		zone.name = "CapitalBlueprintZone_%s" % String(category_id)
		zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zone.add_theme_stylebox_override("panel", _zone_style(category_id))
		_map_canvas.add_child(zone)
		_zone_panels[category_id] = zone
		var label := _make_label(String(category.get("label", "")), 10, COLOR_BRASS)
		label.name = "CapitalBlueprintZoneLabel_%s" % String(category_id)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_map_canvas.add_child(label)
		_zone_labels[category_id] = label


func _build_inspector_panel() -> void:
	_inspector_panel = PanelContainer.new()
	_inspector_panel.name = "CapitalBlueprintInspector"
	_inspector_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inspector_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_inspector_panel.size_flags_stretch_ratio = 3.0
	_inspector_panel.custom_minimum_size = Vector2(300.0, 310.0)
	_inspector_panel.add_theme_stylebox_override("panel", _panel_style(Color("1d2933"), Color("596b77"), 9, 1))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 13)
	margin.add_theme_constant_override("margin_right", 13)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_inspector_panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.name = "CapitalBlueprintInspectorScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.name = "CapitalBlueprintInspectorColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	scroll.add_child(column)
	_inspector_title = _make_label("SELECT A CAPITAL PARCEL", 18, COLOR_INK)
	_inspector_title.name = "CapitalBlueprintFacilityTitle"
	_inspector_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_inspector_title)
	_inspector_status = _make_label("NO AUTHORITATIVE FILE SELECTED", 11, COLOR_MUTED)
	_inspector_status.name = "CapitalBlueprintFacilityStatus"
	_inspector_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_inspector_status)
	column.add_child(HSeparator.new())
	for section: Dictionary in [
		{"id": &"why_now", "label": "WHY NOW"},
		{"id": &"you_get", "label": "YOU GET"},
		{"id": &"you_owe", "label": "YOU OWE"},
		{"id": &"after_build", "label": "AFTER BUILD"},
		{"id": &"gates", "label": "GATES"},
	]:
		var heading := _make_label(String(section["label"]), 10, COLOR_BRASS)
		heading.name = "CapitalBlueprintSection_%s" % String(section["id"])
		column.add_child(heading)
		var body := _make_label("-", 11, COLOR_MUTED)
		body.name = "CapitalBlueprint%s" % _pascal_case(String(section["id"]))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(body)
		_inspector_bodies[StringName(section["id"])] = body


func _ensure_parcel_buttons() -> void:
	if _map_canvas == null:
		return
	for facility: Dictionary in _model.facilities(CapitalBlueprintModel.FILTER_ALL):
		var facility_id := StringName(String(facility.get("id", "")))
		if facility_id == &"" or _parcel_buttons.has(facility_id):
			continue
		var button := Button.new()
		button.name = "CapitalBlueprintParcel_%s" % String(facility_id)
		button.focus_mode = Control.FOCUS_ALL
		button.clip_text = true
		button.custom_minimum_size = Vector2(92.0, 50.0)
		button.pressed.connect(_activate_parcel.bind(facility_id))
		button.gui_input.connect(_on_parcel_gui_input.bind(button, facility_id))
		_map_canvas.add_child(button)
		_parcel_buttons[facility_id] = button
	_layout_map_geometry()


func _refresh() -> void:
	_refresh_filter_buttons()
	_refresh_campus_expansion_button()
	_refresh_plan_summary()
	_refresh_parcel_buttons()
	_refresh_inspector()
	_layout_map_geometry()


func _refresh_filter_buttons() -> void:
	var counts := _model.filter_counts()
	for filter_id: StringName in CapitalBlueprintModel.FILTER_ORDER:
		var button := _filter_buttons.get(filter_id) as Button
		if button == null:
			continue
		button.text = "%s  %d" % [
			String(FILTER_LABELS.get(filter_id, String(filter_id).to_upper())),
			int(counts.get(filter_id, 0)),
		]
		button.theme_type_variation = &"ActiveSpeedButton" if filter_id == _active_filter else &"Button"
		button.set_meta("active", filter_id == _active_filter)


func _refresh_campus_expansion_button() -> void:
	if _campus_expansion_button == null:
		return
	var parcel := _campus_expansion.get("parcel", {}) as Dictionary
	var module := _campus_expansion.get(
		"routing_pod",
		_campus_expansion.get("module", _campus_expansion.get("pod", {})),
	) as Dictionary
	var services_value: Variant = _campus_expansion.get("services", {})
	var parcel_owned := bool(parcel.get("owned", _campus_expansion.get("parcel_owned", false)))
	var module_operational := bool(module.get(
		"operational", _campus_expansion.get("pod_operational", _campus_expansion.get("operational", false))
	))
	var connected_services := 0
	var service_records: Array = (
		services_value.values() if services_value is Dictionary else
		services_value if services_value is Array else
		[]
	)
	for service_value in service_records:
		if service_value is Dictionary and bool((service_value as Dictionary).get(
			"connected", (service_value as Dictionary).get("commissioned", false)
		)):
			connected_services += 1
	var status := (
		"POD ONLINE" if module_operational else
		"SERVICES %d/3" % connected_services if parcel_owned else
		"BUY LAND"
	)
	var deed_count := 1 if parcel_owned else 0
	var active_projects := 0
	var portfolio_parcels_value: Variant = _campus_portfolio.get("parcels", [])
	var portfolio_parcel_records: Array = (
		portfolio_parcels_value.values() if portfolio_parcels_value is Dictionary else
		portfolio_parcels_value if portfolio_parcels_value is Array else
		[]
	)
	for record_value: Variant in portfolio_parcel_records:
		if record_value is Dictionary and bool((record_value as Dictionary).get("owned", false)):
			deed_count += 1
	var projects_value: Variant = _campus_portfolio.get("projects", [])
	var project_records: Array = (
		projects_value.values() if projects_value is Dictionary else
		projects_value if projects_value is Array else
		[]
	)
	for project_value: Variant in project_records:
		if not project_value is Dictionary:
			continue
		var project := project_value as Dictionary
		var project_status := StringName(String(project.get(
			"status",
			project.get("stage", project.get("stage_id", "")),
		)).to_lower())
		if project_status not in [&"complete", &"completed", &"operational", &"commissioned"]:
			active_projects += 1
	var portfolio_status := status
	if not _campus_portfolio.is_empty():
		portfolio_status = (
			"%d BUILD%s ACTIVE" % [active_projects, "" if active_projects == 1 else "S"]
			if active_projects > 0 else
			"%d / 3 DEEDS" % deed_count
		)
	_campus_expansion_button.text = "CAMPUS PORTFOLIO  /  %s" % portfolio_status
	var recurring_cents := maxi(0, int(_campus_expansion.get(
		"current_daily_cost_cents", _campus_expansion.get("daily_recurring_cents", 0)
	)))
	_campus_expansion_button.tooltip_text = (
		"Plan player-owned deeds, circulation, power, cold-chain, and visible construction. "
		+ "North Meadow recurring cost: $%.2f per shift." % (recurring_cents / 100.0)
	)
	if not _campus_portfolio.is_empty():
		_campus_expansion_button.tooltip_text += (
			" %d of 3 deeds filed; %d project%s queued or active."
			% [deed_count, active_projects, "" if active_projects == 1 else "s"]
		)


func _refresh_plan_summary() -> void:
	var pinned_id := _model.pinned_facility_id()
	var pinned := _model.facility(pinned_id)
	if pinned_id == &"" or pinned.is_empty():
		_plan_summary_label.text = "NO CAPITAL PLAN PINNED"
		_plan_summary_label.tooltip_text = "Select any parcel and pin it without spending Feed Fund."
		return
	_plan_summary_label.text = "CAPITAL PLAN / %s / %s" % [
		String(pinned.get("short_name", pinned.get("display_name", pinned_id))).to_upper(),
		String(pinned.get("readiness_label", "BLOCKED")),
	]
	_plan_summary_label.tooltip_text = String(pinned.get("why_now", ""))


func _refresh_parcel_buttons() -> void:
	var visible_ids := visible_facility_ids()
	for facility_id: StringName in _parcel_buttons:
		var button := _parcel_buttons[facility_id] as Button
		var facility := _model.facility(facility_id)
		var shown := facility_id in visible_ids and not facility.is_empty()
		# Stable identities remain queryable for accessibility, automation, and
		# exact feature preservation even while progressive filters hide the card.
		button.set_meta("facility_id", facility_id)
		button.set_meta("readiness_id", facility.get("readiness_id", &"blocked"))
		button.set_meta("pinned", bool(facility.get("pinned", false)))
		button.visible = shown
		if not shown:
			button.set_meta("selected", false)
			continue
		var selected := facility_id == _selected_facility_id
		var pinned := bool(facility.get("pinned", false))
		var level := int(facility.get("level", 0))
		var max_level := int(facility.get("max_level", 1))
		var plan_prefix := "PLAN / " if pinned else ""
		button.text = "%s%s\nL%d/%d / %s" % [
			plan_prefix,
			String(facility.get("short_name", facility.get("display_name", facility_id))).to_upper(),
			level,
			max_level,
			String(facility.get("readiness_label", "BLOCKED")),
		]
		button.tooltip_text = "%s / %s" % [
			String(facility.get("display_name", facility_id)),
			String(facility.get("why_now", "")),
		]
		button.set_meta("selected", selected)
		button.theme_type_variation = (
			&"SelectedChoiceButton" if selected else
			&"ActiveSpeedButton" if pinned else
			&"DecisionChoiceButton"
		)
		_apply_parcel_status_style(button, facility, selected)


func _refresh_inspector() -> void:
	var facility := _model.facility(_selected_facility_id)
	if facility.is_empty():
		_inspector_title.text = "NO PARCEL IN THIS FILTER"
		_inspector_status.text = "Choose another capital filter."
		for body_value: Variant in _inspector_bodies.values():
			(body_value as Label).text = "-"
		_pin_button.disabled = true
		_purchase_button.disabled = true
		_purchase_button.text = "AUTHORIZE BUILD"
		return

	var level := int(facility.get("level", 0))
	var max_level := int(facility.get("max_level", 1))
	_inspector_title.text = String(facility.get("display_name", _selected_facility_id)).to_upper()
	_inspector_status.text = "%s / LEVEL %d OF %d / %s%s" % [
		String(facility.get("category_label", "CAPITAL")),
		level,
		max_level,
		String(facility.get("readiness_label", "BLOCKED")),
		" / CAPITAL PLAN" if bool(facility.get("pinned", false)) else "",
	]
	_set_inspector_body(&"why_now", String(facility.get("why_now", "No capital reason filed.")))
	_set_inspector_body(&"you_get", _bullet_copy(facility.get("benefit_lines", []), "No next-tier effects are filed."))
	_set_inspector_body(&"you_owe", _obligation_copy(facility))
	_set_inspector_body(&"after_build", _projection_copy(facility))
	_set_inspector_body(&"gates", _gate_copy(facility))

	var pinned := bool(facility.get("pinned", false))
	_pin_button.disabled = pinned
	_pin_button.text = "CAPITAL PLAN PINNED" if pinned else "PIN AS CAPITAL PLAN"
	_pin_button.tooltip_text = (
		"This parcel is the authoritative capital plan."
		if pinned else
		"Pin this parcel without spending Feed Fund."
	)
	var can_purchase := bool(facility.get("can_purchase", false))
	_purchase_button.disabled = not can_purchase
	_purchase_button.text = (
		String(facility.get("purchase_label", "AUTHORIZE BUILD")).replace(String.chr(183), "/")
		if can_purchase else
		"FULLY COMMISSIONED" if bool(facility.get("maxed", false)) else
		"BUILD HELD"
	)
	_purchase_button.tooltip_text = (
		"Authorize the exact capital file shown above."
		if can_purchase else
		String(facility.get("why_now", "This parcel is not ready."))
	)


func _set_inspector_body(section_id: StringName, copy: String) -> void:
	var label := _inspector_bodies.get(section_id) as Label
	if label == null:
		return
	label.text = copy
	label.tooltip_text = copy
	label.add_theme_color_override(
		"font_color",
		COLOR_RUST if section_id == &"gates" and not bool(_model.facility(_selected_facility_id).get("can_purchase", false)) else COLOR_MUTED,
	)


func _obligation_copy(facility: Dictionary) -> String:
	if bool(facility.get("maxed", false)):
		return "NO NEW CAPITAL FILE / all commissioned obligations remain protected."
	var lines: Array[String] = [
		"CAPITAL  %s" % _currency(int(facility.get("capital_cost_cents", 0))),
		"MAINTENANCE  %s/DAY" % _signed_currency(int(facility.get("maintenance_delta_cents", 0))),
	]
	var payroll_delta := int(facility.get("supervisor_payroll_delta_cents", 0))
	if payroll_delta != 0:
		lines.append("PAYROLL  %s/DAY" % _signed_currency(payroll_delta))
	for tradeoff: String in _string_lines(facility.get("tradeoff_lines", [])):
		lines.append(tradeoff)
	return "\n".join(lines)


func _projection_copy(facility: Dictionary) -> String:
	var lines: Array[String] = []
	if bool(facility.get("has_projected_spendable", false)):
		lines.append("SPENDABLE FEED FUND  %s" % _currency(int(facility.get("projected_spendable_fund_cents", 0))))
	if bool(facility.get("has_projected_protected_reserve", false)):
		lines.append("PROTECTED RESERVE  %s/DAY" % _currency(int(facility.get("projected_protected_reserve_cents", 0))))
	if lines.is_empty():
		return "No after-build projection is filed in this catalog entry."
	return "\n".join(lines)


func _gate_copy(facility: Dictionary) -> String:
	var gates := _string_lines(facility.get("gate_lines", []))
	if not gates.is_empty():
		return _bullet_copy(gates, "")
	if bool(facility.get("maxed", false)):
		return "ALL TIERS COMMISSIONED."
	if bool(facility.get("can_purchase", false)):
		return "ALL AUTHORITATIVE GATES CLEARED."
	return "No gate reason is filed."


func _bullet_copy(value: Variant, empty_copy: String) -> String:
	var lines := _string_lines(value)
	if lines.is_empty():
		return empty_copy
	var bullets: Array[String] = []
	for line: String in lines:
		bullets.append("- %s" % line)
	return "\n".join(bullets)


func _layout_map_geometry() -> void:
	if _map_canvas == null or _map_canvas.size.x <= 0.0 or _map_canvas.size.y <= 0.0:
		return
	var available := _map_canvas.size
	var outer := 5.0
	var gap := 7.0
	var inner_width := maxf(1.0, available.x - outer * 2.0 - gap * 2.0)
	var production_width := floorf(inner_width * 0.32)
	var flock_width := floorf(inner_width * 0.24)
	var governance_width := inner_width - production_width - flock_width
	var rects := {
		CapitalBlueprintModel.CATEGORY_PRODUCTION: Rect2(outer, outer, production_width, available.y - outer * 2.0),
		CapitalBlueprintModel.CATEGORY_FLOCK: Rect2(outer + production_width + gap, outer, flock_width, available.y - outer * 2.0),
		CapitalBlueprintModel.CATEGORY_GOVERNANCE: Rect2(outer + production_width + flock_width + gap * 2.0, outer, governance_width, available.y - outer * 2.0),
	}
	for category_id: StringName in rects:
		var rect := rects[category_id] as Rect2
		var zone := _zone_panels.get(category_id) as Control
		var label := _zone_labels.get(category_id) as Label
		if zone != null:
			zone.position = rect.position
			zone.size = rect.size
		if label != null:
			label.position = rect.position + Vector2(6.0, 4.0)
			label.size = Vector2(maxf(1.0, rect.size.x - 12.0), 20.0)
		_layout_category_buttons(category_id, rect)


func _layout_category_buttons(category_id: StringName, rect: Rect2) -> void:
	var category_ids: Array[StringName] = []
	for category: Dictionary in _model.categories():
		if StringName(String(category.get("id", ""))) != category_id:
			continue
		for facility_value: Variant in category.get("facility_ids", []):
			var facility_id := StringName(String(facility_value))
			if _parcel_buttons.has(facility_id):
				category_ids.append(facility_id)
		break
	var columns := 1 if category_id == CapitalBlueprintModel.CATEGORY_FLOCK else 2
	var gap := 6.0
	var left := rect.position.x + 8.0
	var top := rect.position.y + 30.0
	var usable_width := maxf(1.0, rect.size.x - 16.0)
	var button_width := maxf(68.0, (usable_width - gap * float(columns - 1)) / float(columns))
	var row_count := maxi(1, ceili(float(category_ids.size()) / float(columns)))
	var usable_height := maxf(1.0, rect.size.y - 39.0)
	var button_height := clampf((usable_height - gap * float(row_count - 1)) / float(row_count), 42.0, 66.0)
	for index: int in category_ids.size():
		var button := _parcel_buttons[category_ids[index]] as Button
		var column := index % columns
		var row := index / columns
		button.position = Vector2(
			left + float(column) * (button_width + gap),
			top + float(row) * (button_height + gap),
		)
		button.size = Vector2(button_width, button_height)


func _apply_responsive_layout() -> void:
	if _body_scroll == null or _map_panel == null or _inspector_panel == null:
		return
	var compact := size.x <= COMPACT_BREAKPOINT
	var target_body: Container = _compact_body if compact else _desktop_body
	_layout_mode = &"compact" if compact else &"desktop"
	if _active_body != target_body:
		if _map_panel.get_parent() != null:
			_map_panel.get_parent().remove_child(_map_panel)
		if _inspector_panel.get_parent() != null:
			_inspector_panel.get_parent().remove_child(_inspector_panel)
		if _active_body != null and _active_body.get_parent() == _body_scroll:
			_body_scroll.remove_child(_active_body)
		_active_body = target_body
		_body_scroll.add_child(_active_body)
		_active_body.add_child(_map_panel)
		_active_body.add_child(_inspector_panel)
	if compact:
		_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_map_panel.custom_minimum_size = Vector2(0.0, 318.0)
		_inspector_panel.custom_minimum_size = Vector2(0.0, 315.0)
		_plan_summary_label.custom_minimum_size.x = 230.0
	else:
		_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_map_panel.custom_minimum_size = Vector2(520.0, 310.0)
		_inspector_panel.custom_minimum_size = Vector2(300.0, 310.0)
		_plan_summary_label.custom_minimum_size.x = 310.0
	call_deferred("_layout_map_geometry")


func _on_filter_pressed(filter_id: StringName) -> void:
	set_filter(filter_id)
	_focus_selected_or_return()


func _activate_parcel(facility_id: StringName) -> void:
	var frame := Engine.get_process_frames()
	if int(_last_activation_frame_by_id.get(facility_id, -1)) == frame:
		return
	_last_activation_frame_by_id[facility_id] = frame
	select_facility(facility_id, true)


func _on_parcel_gui_input(event: InputEvent, button: Button, facility_id: StringName) -> void:
	if not event.is_pressed() or _is_repeated_key_event(event):
		return
	if event.is_action_pressed(&"ui_accept"):
		button.accept_event()
		_activate_parcel(facility_id)
		return
	var direction := Vector2.ZERO
	if event.is_action_pressed(&"ui_left"):
		direction = Vector2.LEFT
	elif event.is_action_pressed(&"ui_right"):
		direction = Vector2.RIGHT
	elif event.is_action_pressed(&"ui_up"):
		direction = Vector2.UP
	elif event.is_action_pressed(&"ui_down"):
		direction = Vector2.DOWN
	if direction != Vector2.ZERO:
		button.accept_event()
		_focus_neighbor(facility_id, direction)


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or _is_repeated_key_event(event):
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_request_close()
		return
	if event.is_action_pressed(&"ui_accept"):
		# Focused Buttons consume ui_accept before it reaches this handler. This
		# fallback keeps the selected parcel operable if a host opens the surface
		# before assigning keyboard focus.
		var focus_owner := get_viewport().gui_get_focus_owner()
		if focus_owner == null or not is_ancestor_of(focus_owner):
			get_viewport().set_input_as_handled()
			_activate_parcel(_selected_facility_id)


func _focus_neighbor(from_id: StringName, direction: Vector2) -> void:
	var current := _parcel_buttons.get(from_id) as Button
	if current == null:
		return
	var current_center := current.get_global_rect().get_center()
	var best_button: Button
	var best_score := INF
	for facility_id: StringName in _parcel_buttons:
		if facility_id == from_id:
			continue
		var candidate := _parcel_buttons[facility_id] as Button
		if candidate == null or not candidate.is_visible_in_tree():
			continue
		var offset := candidate.get_global_rect().get_center() - current_center
		var forward := offset.dot(direction)
		if forward <= 0.5:
			continue
		var lateral := absf(offset.dot(Vector2(-direction.y, direction.x)))
		var score := forward + lateral * 2.25
		if score < best_score:
			best_score = score
			best_button = candidate
	if best_button == null:
		var ids := visible_facility_ids()
		var index := ids.find(from_id)
		if index >= 0 and not ids.is_empty():
			var step := -1 if direction in [Vector2.LEFT, Vector2.UP] else 1
			best_button = _parcel_buttons.get(ids[posmod(index + step, ids.size())]) as Button
	if best_button != null:
		best_button.grab_focus()
		var next_id := StringName(String(best_button.get_meta("facility_id", "")))
		if next_id != &"":
			select_facility(next_id, true)


func _on_pin_pressed() -> void:
	if _selected_facility_id != &"" and not _model.facility(_selected_facility_id).is_empty():
		pin_requested.emit(_selected_facility_id)


func _on_purchase_pressed() -> void:
	var facility := _model.facility(_selected_facility_id)
	if not facility.is_empty() and bool(facility.get("can_purchase", false)):
		purchase_requested.emit(_selected_facility_id)


func _request_close() -> void:
	close_requested.emit()


func _focus_selected_or_return() -> void:
	var button := _parcel_buttons.get(_selected_facility_id) as Button
	if button != null and button.is_visible_in_tree():
		button.grab_focus()
	elif _return_button != null:
		_return_button.grab_focus()


func _apply_parcel_status_style(button: Button, facility: Dictionary, selected: bool) -> void:
	var border := (
		COLOR_BRASS if selected else
		COLOR_TEAL if bool(facility.get("can_purchase", false)) else
		Color("73808a") if bool(facility.get("installed", false)) else
		COLOR_RUST
	)
	var background := (
		Color("344d49") if selected else
		Color("24443e") if bool(facility.get("can_purchase", false)) else
		Color("25333d") if bool(facility.get("installed", false)) else
		Color("30272b")
	)
	button.add_theme_stylebox_override("normal", _panel_style(background, border, 7, 2 if selected else 1))
	button.add_theme_stylebox_override("hover", _panel_style(background.lightened(0.08), COLOR_BRASS, 7, 2))


func _zone_style(category_id: StringName) -> StyleBoxFlat:
	var color := Color("263640")
	match category_id:
		CapitalBlueprintModel.CATEGORY_PRODUCTION:
			color = Color("243944")
		CapitalBlueprintModel.CATEGORY_FLOCK:
			color = Color("273c35")
		CapitalBlueprintModel.CATEGORY_GOVERNANCE:
			color = Color("332f3c")
	return _panel_style(color, color.lightened(0.16), 8, 1)


func _panel_style(color: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _make_label(copy: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _currency(cents: int) -> String:
	return "$%.2f" % (float(cents) / 100.0)


func _signed_currency(cents: int) -> String:
	return "%s$%.2f" % ["+" if cents >= 0 else "-", float(absi(cents)) / 100.0]


func _string_lines(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for line_value: Variant in value as Array:
			var line := String(line_value).strip_edges()
			if not line.is_empty():
				result.append(line)
	elif value is String or value is StringName:
		var line := String(value).strip_edges()
		if not line.is_empty():
			result.append(line)
	return result


func _first_facility_id(entries: Array[Dictionary]) -> StringName:
	if entries.is_empty():
		return &""
	return StringName(String(entries[0].get("id", "")))


func _facility_in_entries(facility_id: StringName, entries: Array[Dictionary]) -> bool:
	for facility: Dictionary in entries:
		if StringName(String(facility.get("id", ""))) == facility_id:
			return true
	return false


func _is_repeated_key_event(event: InputEvent) -> bool:
	return event is InputEventKey and (event as InputEventKey).echo


func _pascal_case(value: String) -> String:
	var result := ""
	for part: String in value.split("_", false):
		result += part.capitalize()
	return result
