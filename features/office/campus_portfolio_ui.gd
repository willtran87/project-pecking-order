class_name CampusPortfolioUI
extends Control

## Responsive, intent-only planner for the multi-parcel campus portfolio.
##
## The control presents authoritative projection data and emits stable intent
## signals. Selection is local presentation state; deeds, projects, staffing,
## construction progress, and balances remain host-owned.

signal deed_requested(parcel_id: StringName)
signal project_requested(module_id: StringName, pad_id: StringName)
signal staff_assignment_requested(module_id: StringName, worker_id)
signal staff_unassignment_requested(module_id: StringName)
signal close_requested
signal north_meadow_details_requested

const PortfolioModelScript := preload("res://features/office/campus_portfolio_model.gd")
const ManagementTheme := preload("res://features/office/management_ui_theme.gd")

const COMPACT_BREAKPOINT := 900.0
const COLOR_INK := Color("eef1df")
const COLOR_MUTED := Color("aeb8c4")
const COLOR_BRASS := Color("e7c56e")
const COLOR_TEAL := Color("73b5a7")
const COLOR_RUST := Color("d68a68")
const COLOR_NAVY := Color("101923")
const COLOR_PANEL := Color("17232d")
const COLOR_MAP := Color("12222a")
const COLOR_ORCHARD := Color("284134")
const COLOR_CREEK := Color("203b46")

var _model := CampusPortfolioModel.new()
var _selected_parcel_id := &""
var _selected_pad_id := &""
var _selected_module_id := &""
var _selected_worker_id: Variant = null
var _layout_mode := &"desktop"
var _applying_layout := false
var _return_focus: WeakRef

var _main_panel: PanelContainer
var _header_status: Label
var _resource_rail: HFlowContainer
var _resource_labels: Dictionary = {}
var _body_scroll: ScrollContainer
var _desktop_body: HBoxContainer
var _compact_body: VBoxContainer
var _active_body: Container
var _map_panel: PanelContainer
var _inspector_panel: PanelContainer
var _desktop_parcel_host: HBoxContainer
var _compact_parcel_host: VBoxContainer
var _active_parcel_host: Container
var _parcel_cards: Dictionary = {}
var _pad_buttons: Dictionary = {}
var _module_buttons: Dictionary = {}
var _project_host: VBoxContainer

var _inspector_title: Label
var _inspector_status: Label
var _inspector_pad: Label
var _inspector_economics: Label
var _inspector_capacity: Label
var _inspector_effect: Label
var _inspector_reason: Label
var _module_host: VBoxContainer
var _worker_selector: OptionButton
var _assign_button: Button
var _unassign_button: Button
var _staff_status: Label
var _north_meadow_details_button: Button
var _return_button: Button
var _action_button: Button
var _action_summary: Label


func _ready() -> void:
	name = "CampusPortfolioUI"
	theme = ManagementTheme.create_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_apply_responsive_layout)
	_build_interface()
	visible = false
	set_process_unhandled_key_input(false)
	_apply_responsive_layout()
	_refresh()


func _exit_tree() -> void:
	for body: Container in [_desktop_body, _compact_body]:
		if body != null and is_instance_valid(body) and body.get_parent() == null:
			body.free()
	for host: Container in [_desktop_parcel_host, _compact_parcel_host]:
		if host != null and is_instance_valid(host) and host.get_parent() == null:
			host.free()


func set_snapshot(snapshot: Dictionary) -> void:
	var previous_parcel := _selected_parcel_id
	var previous_pad := _selected_pad_id
	var previous_module := _selected_module_id
	_model.set_snapshot(snapshot)

	if _model.parcel(previous_parcel).is_empty():
		_selected_parcel_id = _model.default_parcel_id()
	else:
		_selected_parcel_id = previous_parcel
	if _model.pad(previous_pad).is_empty() or StringName(String(_model.pad(previous_pad).get("parcel_id", ""))) != _selected_parcel_id:
		_selected_pad_id = _model.default_pad_id(_selected_parcel_id)
	else:
		_selected_pad_id = previous_pad
	if _model.module(previous_module).is_empty() or previous_module not in _model.module_ids(_selected_parcel_id):
		_selected_module_id = _model.default_module_id(_selected_parcel_id, _selected_pad_id)
	else:
		_selected_module_id = previous_module
	_selected_worker_id = _model.assignment_for(_selected_module_id)
	if is_node_ready():
		_refresh()


func apply_snapshot(snapshot: Dictionary) -> void:
	set_snapshot(snapshot)


func show_portfolio(snapshot: Dictionary = {}) -> void:
	if not snapshot.is_empty():
		set_snapshot(snapshot)
	visible = true
	set_process_unhandled_key_input(true)
	_refresh()
	call_deferred("_focus_selection")


func show_planner(snapshot: Dictionary = {}) -> void:
	show_portfolio(snapshot)


func hide_portfolio(restore_focus: bool = true) -> void:
	visible = false
	set_process_unhandled_key_input(false)
	if restore_focus and _return_focus != null:
		var target: Variant = _return_focus.get_ref()
		if target is Control and is_instance_valid(target) and (target as Control).is_visible_in_tree():
			(target as Control).call_deferred("grab_focus")


func hide_planner(restore_focus: bool = true) -> void:
	hide_portfolio(restore_focus)


func set_restore_focus(control: Control) -> void:
	_return_focus = weakref(control) if control != null else null


func is_open() -> bool:
	return visible


func layout_mode_name() -> StringName:
	return _layout_mode


func selected_parcel_id() -> StringName:
	return _selected_parcel_id


func selected_pad_id() -> StringName:
	return _selected_pad_id


func selected_module_id() -> StringName:
	return _selected_module_id


func select_parcel(parcel_id: StringName) -> bool:
	if _model.parcel(parcel_id).is_empty():
		return false
	_selected_parcel_id = parcel_id
	_selected_pad_id = _model.default_pad_id(parcel_id)
	_selected_module_id = _model.default_module_id(parcel_id, _selected_pad_id)
	_selected_worker_id = _model.assignment_for(_selected_module_id)
	_refresh()
	return true


func select_pad(pad_id: StringName) -> bool:
	var pad := _model.pad(pad_id)
	if pad.is_empty() or StringName(String(pad.get("parcel_id", ""))) != _selected_parcel_id:
		return false
	_selected_pad_id = pad_id
	if _selected_module_id not in _model.module_ids(_selected_parcel_id):
		_selected_module_id = _model.default_module_id(_selected_parcel_id, pad_id)
	_refresh()
	return true


func select_module(module_id: StringName) -> bool:
	if _model.module(module_id).is_empty() or module_id not in _model.module_ids(_selected_parcel_id):
		return false
	_selected_module_id = module_id
	_selected_worker_id = _model.assignment_for(module_id)
	_refresh_module_buttons()
	_refresh_inspector()
	_refresh_staffing()
	_refresh_action()
	return true


func presentation_state() -> Dictionary:
	return {
		"resources": _model.resources(),
		"parcels": _model.parcels(),
		"pads": _model.pads(),
		"modules": _model.modules(),
		"projects": _model.projects(),
		"workers": _model.workers(),
		"assignments": _model.assignments(),
		"selected_parcel_id": _selected_parcel_id,
		"selected_pad_id": _selected_pad_id,
		"selected_module_id": _selected_module_id,
	}


func accessible_text() -> String:
	var pieces: Array[String] = [_model.accessible_summary()]
	for parcel_record: Dictionary in _model.parcels():
		pieces.append("%s, %s." % [String(parcel_record.get("name", "Parcel")), String(parcel_record.get("status_label", "HELD"))])
	for project_record: Dictionary in _model.projects():
		pieces.append("%s, %s, %d shifts remaining." % [
			String(project_record.get("module_name", "Project")),
			String(project_record.get("status_label", "QUEUED")),
			int(project_record.get("remaining_shifts", 0)),
		])
	for label: Label in [_inspector_title, _inspector_status, _inspector_pad, _inspector_economics, _inspector_capacity, _inspector_effect, _inspector_reason, _staff_status, _action_summary]:
		if label != null and not label.text.strip_edges().is_empty():
			pieces.append(label.text.replace("\n", "; "))
	return " ".join(pieces)


func _build_interface() -> void:
	var scrim := ColorRect.new()
	scrim.name = "CampusPortfolioScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.02, 0.035, 0.045, 0.90)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	_main_panel = PanelContainer.new()
	_main_panel.name = "CampusPortfolioPanel"
	_main_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_panel.offset_left = 12.0
	_main_panel.offset_top = 10.0
	_main_panel.offset_right = -12.0
	_main_panel.offset_bottom = -10.0
	_main_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_main_panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL, COLOR_BRASS, 12, 2))
	add_child(_main_panel)

	var outer := _margin(_main_panel, 12)
	var page := VBoxContainer.new()
	page.name = "CampusPortfolioPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 7)
	outer.add_child(page)

	var header := HBoxContainer.new()
	header.name = "CampusPortfolioHeader"
	header.custom_minimum_size.y = 38.0
	header.add_theme_constant_override("separation", 10)
	page.add_child(header)
	var title := _label("CAMPUS PORTFOLIO", 22, COLOR_BRASS)
	title.name = "CampusPortfolioTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_header_status = _wrap_label("NO FILED CAMPUS PLAN", 11, COLOR_TEAL)
	_header_status.name = "CampusPortfolioHeaderStatus"
	_header_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header_status.custom_minimum_size.x = 280.0
	header.add_child(_header_status)

	_build_resource_rail(page)

	_body_scroll = ScrollContainer.new()
	_body_scroll.name = "CampusPortfolioBodyScroll"
	_body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(_body_scroll)

	_desktop_body = HBoxContainer.new()
	_desktop_body.name = "CampusPortfolioDesktopBody"
	_desktop_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_desktop_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desktop_body.add_theme_constant_override("separation", 10)
	_compact_body = VBoxContainer.new()
	_compact_body.name = "CampusPortfolioCompactBody"
	_compact_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compact_body.add_theme_constant_override("separation", 9)

	_build_map_panel()
	_build_inspector_panel()
	_active_body = _desktop_body
	_body_scroll.add_child(_active_body)
	_active_body.add_child(_map_panel)
	_active_body.add_child(_inspector_panel)

	var action_rail := HBoxContainer.new()
	action_rail.name = "CampusPortfolioActionRail"
	action_rail.custom_minimum_size.y = 48.0
	action_rail.add_theme_constant_override("separation", 8)
	page.add_child(action_rail)
	_return_button = Button.new()
	_return_button.name = "CampusPortfolioReturnButton"
	_return_button.text = "RETURN TO BLUEPRINT"
	_return_button.custom_minimum_size = Vector2(164.0, 44.0)
	_return_button.focus_mode = Control.FOCUS_ALL
	_return_button.pressed.connect(func() -> void: close_requested.emit())
	action_rail.add_child(_return_button)
	_action_summary = _wrap_label("SELECT A FILED PARCEL", 11, COLOR_MUTED)
	_action_summary.name = "CampusPortfolioActionSummary"
	_action_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_rail.add_child(_action_summary)
	_action_button = Button.new()
	_action_button.name = "CampusPortfolioActionButton"
	_action_button.text = "SELECT A PROJECT"
	_action_button.clip_text = true
	_action_button.custom_minimum_size = Vector2(270.0, 44.0)
	_action_button.theme_type_variation = &"PrimaryButton"
	_action_button.focus_mode = Control.FOCUS_ALL
	_action_button.pressed.connect(_on_action_pressed)
	action_rail.add_child(_action_button)


func _build_resource_rail(parent: VBoxContainer) -> void:
	_resource_rail = HFlowContainer.new()
	_resource_rail.name = "CampusPortfolioResourceRail"
	_resource_rail.custom_minimum_size.y = 34.0
	_resource_rail.add_theme_constant_override("h_separation", 6)
	_resource_rail.add_theme_constant_override("v_separation", 4)
	parent.add_child(_resource_rail)
	for spec: Dictionary in [
		{"id": &"feed_fund", "title": "FEED FUND"},
		{"id": &"spendable", "title": "SPENDABLE"},
		{"id": &"reserve", "title": "PROTECTED"},
		{"id": &"contractors", "title": "CONTRACTORS"},
		{"id": &"power", "title": "POWER"},
		{"id": &"cold", "title": "COLD"},
	]:
		var panel := PanelContainer.new()
		panel.name = "CampusPortfolioResourceCard_%s" % String(spec["id"])
		panel.custom_minimum_size = Vector2(150.0, 32.0)
		panel.add_theme_stylebox_override("panel", _panel_style(Color("111d26"), Color("3f5662"), 6, 1))
		_resource_rail.add_child(panel)
		var label := _label("%s  -" % String(spec["title"]), 11, COLOR_MUTED)
		label.name = "CampusPortfolioResource_%s" % String(spec["id"])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(label)
		_resource_labels[StringName(spec["id"])] = label


func _build_map_panel() -> void:
	_map_panel = PanelContainer.new()
	_map_panel.name = "CampusPortfolioMapPanel"
	_map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_panel.size_flags_stretch_ratio = 6.5
	_map_panel.custom_minimum_size = Vector2(560.0, 430.0)
	_map_panel.add_theme_stylebox_override("panel", _panel_style(COLOR_MAP, Color("405966"), 9, 1))
	var margin := _margin(_map_panel, 9)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	var heading := _label("SURVEYED CAMPUS / SELECT PARCEL & PAD", 11, COLOR_MUTED)
	heading.name = "CampusPortfolioMapHeading"
	column.add_child(heading)

	_desktop_parcel_host = HBoxContainer.new()
	_desktop_parcel_host.name = "CampusPortfolioDesktopParcels"
	_desktop_parcel_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_desktop_parcel_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desktop_parcel_host.add_theme_constant_override("separation", 7)
	_compact_parcel_host = VBoxContainer.new()
	_compact_parcel_host.name = "CampusPortfolioCompactParcels"
	_compact_parcel_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compact_parcel_host.add_theme_constant_override("separation", 7)
	_active_parcel_host = _desktop_parcel_host
	column.add_child(_active_parcel_host)

	var queue_panel := PanelContainer.new()
	queue_panel.name = "CampusPortfolioProjectQueue"
	queue_panel.custom_minimum_size.y = 118.0
	queue_panel.add_theme_stylebox_override("panel", _panel_style(Color("17242d"), Color("4c606c"), 7, 1))
	column.add_child(queue_panel)
	var queue_margin := _margin(queue_panel, 7)
	var queue_column := VBoxContainer.new()
	queue_column.add_theme_constant_override("separation", 4)
	queue_margin.add_child(queue_column)
	var queue_heading := _label("ACTIVE BUILD QUEUE / SHIFT-BASED", 10, COLOR_BRASS)
	queue_column.add_child(queue_heading)
	_project_host = VBoxContainer.new()
	_project_host.name = "CampusPortfolioProjectHost"
	_project_host.add_theme_constant_override("separation", 3)
	queue_column.add_child(_project_host)


func _build_inspector_panel() -> void:
	_inspector_panel = PanelContainer.new()
	_inspector_panel.name = "CampusPortfolioInspector"
	_inspector_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inspector_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_inspector_panel.size_flags_stretch_ratio = 3.5
	_inspector_panel.custom_minimum_size = Vector2(330.0, 430.0)
	_inspector_panel.add_theme_stylebox_override("panel", _panel_style(Color("1b2933"), Color("596c78"), 9, 1))
	var margin := _margin(_inspector_panel, 11)
	var scroll := ScrollContainer.new()
	scroll.name = "CampusPortfolioInspectorScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.name = "CampusPortfolioInspectorColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 5)
	scroll.add_child(column)

	_inspector_title = _wrap_label("SELECT A CAMPUS PARCEL", 18, COLOR_INK)
	_inspector_title.name = "CampusPortfolioInspectorTitle"
	column.add_child(_inspector_title)
	_inspector_status = _wrap_label("NO AUTHORITATIVE FILE SELECTED", 10, COLOR_MUTED)
	_inspector_status.name = "CampusPortfolioInspectorStatus"
	column.add_child(_inspector_status)
	_north_meadow_details_button = Button.new()
	_north_meadow_details_button.name = "CampusPortfolioNorthMeadowDetailsButton"
	_north_meadow_details_button.text = "OPEN NORTH MEADOW SERVICE FILE"
	_north_meadow_details_button.focus_mode = Control.FOCUS_ALL
	_north_meadow_details_button.pressed.connect(func() -> void: north_meadow_details_requested.emit())
	column.add_child(_north_meadow_details_button)
	column.add_child(HSeparator.new())

	var module_heading := _label("MODULE FILES", 10, COLOR_BRASS)
	column.add_child(module_heading)
	_module_host = VBoxContainer.new()
	_module_host.name = "CampusPortfolioModuleHost"
	_module_host.add_theme_constant_override("separation", 4)
	column.add_child(_module_host)

	_inspector_pad = _inspector_section(column, "SELECTED PAD", "CampusPortfolioInspectorPad")
	_inspector_economics = _inspector_section(column, "CAPITAL & LIABILITY", "CampusPortfolioInspectorEconomics")
	_inspector_capacity = _inspector_section(column, "CAPACITY & STAFFING", "CampusPortfolioInspectorCapacity")
	_inspector_effect = _inspector_section(column, "VISIBLE RESULT", "CampusPortfolioInspectorEffect")
	_inspector_reason = _inspector_section(column, "PROJECT FILE", "CampusPortfolioInspectorReason")

	var staff_heading := _label("NAMED MODULE STAFF", 10, COLOR_BRASS)
	column.add_child(staff_heading)
	_staff_status = _wrap_label("No module selected.", 11, COLOR_MUTED)
	_staff_status.name = "CampusPortfolioStaffStatus"
	column.add_child(_staff_status)
	_worker_selector = OptionButton.new()
	_worker_selector.name = "CampusPortfolioWorkerSelector"
	_worker_selector.focus_mode = Control.FOCUS_ALL
	_worker_selector.item_selected.connect(_on_worker_selected)
	column.add_child(_worker_selector)
	var staff_actions := HBoxContainer.new()
	staff_actions.add_theme_constant_override("separation", 6)
	column.add_child(staff_actions)
	_assign_button = Button.new()
	_assign_button.name = "CampusPortfolioAssignButton"
	_assign_button.text = "ASSIGN HEN"
	_assign_button.focus_mode = Control.FOCUS_ALL
	_assign_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_assign_button.pressed.connect(_on_assign_pressed)
	staff_actions.add_child(_assign_button)
	_unassign_button = Button.new()
	_unassign_button.name = "CampusPortfolioUnassignButton"
	_unassign_button.text = "CLEAR PERCH"
	_unassign_button.focus_mode = Control.FOCUS_ALL
	_unassign_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_unassign_button.pressed.connect(_on_unassign_pressed)
	staff_actions.add_child(_unassign_button)


func _inspector_section(parent: VBoxContainer, heading_text: String, node_name: String) -> Label:
	var heading := _label(heading_text, 10, COLOR_BRASS)
	parent.add_child(heading)
	var body := _wrap_label("-", 11, COLOR_MUTED)
	body.name = node_name
	parent.add_child(body)
	return body


func _refresh() -> void:
	_refresh_header()
	_refresh_resources()
	_rebuild_parcel_cards()
	_rebuild_projects()
	_rebuild_module_buttons()
	_refresh_inspector()
	_refresh_staffing()
	_refresh_action()


func _refresh_header() -> void:
	if _header_status == null:
		return
	var active := _model.projects().size()
	_header_status.text = "%d PARCELS  /  %d ACTIVE PROJECT%s" % [
		_model.parcels().size(),
		active,
		"" if active == 1 else "S",
	]


func _refresh_resources() -> void:
	var resources := _model.resources()
	_set_resource(&"feed_fund", "FEED FUND", _money(int(resources.get("feed_fund_cents", 0))), bool(resources.get("has_feed_fund", false)))
	_set_resource(&"spendable", "SPENDABLE", _money(int(resources.get("spendable_fund_cents", 0))), bool(resources.get("has_spendable", false)))
	_set_resource(&"reserve", "PROTECTED", _money(int(resources.get("protected_reserve_cents", 0))), bool(resources.get("has_reserve", false)))
	_set_resource(&"contractors", "CONTRACTORS", "%d / %d" % [int(resources.get("contractor_used", 0)), int(resources.get("contractor_capacity", 0))], bool(resources.get("has_contractors", false)))
	_set_resource(&"power", "POWER", "%d / %d" % [int(resources.get("power_used", 0)), int(resources.get("power_capacity", 0))], bool(resources.get("has_power", false)))
	_set_resource(&"cold", "COLD", "%d / %d" % [int(resources.get("cold_used", 0)), int(resources.get("cold_capacity", 0))], bool(resources.get("has_cold", false)))


func _set_resource(resource_id: StringName, heading: String, value: String, known: bool) -> void:
	var label := _resource_labels.get(resource_id) as Label
	if label == null:
		return
	label.text = "%s  %s" % [heading, value if known else "-"]
	label.add_theme_color_override("font_color", COLOR_INK if known else COLOR_MUTED)


func _rebuild_parcel_cards() -> void:
	_clear_container(_active_parcel_host)
	_parcel_cards.clear()
	_pad_buttons.clear()
	for parcel_record: Dictionary in _model.parcels():
		var parcel_id := StringName(String(parcel_record.get("id", "")))
		var card := PanelContainer.new()
		card.name = "CampusPortfolioParcelCard_%s" % String(parcel_id)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.size_flags_stretch_ratio = 1.0
		card.custom_minimum_size = Vector2(170.0, 188.0)
		card.add_theme_stylebox_override("panel", _parcel_style(parcel_id, parcel_id == _selected_parcel_id))
		_active_parcel_host.add_child(card)
		_parcel_cards[parcel_id] = card
		var margin := _margin(card, 7)
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 4)
		margin.add_child(column)
		var parcel_button := Button.new()
		parcel_button.name = "CampusPortfolioParcel_%s" % String(parcel_id)
		parcel_button.text = "%s\n%s" % [
			String(parcel_record.get("name", parcel_id)).to_upper(),
			String(parcel_record.get("status_label", "HELD")),
		]
		parcel_button.focus_mode = Control.FOCUS_ALL
		parcel_button.theme_type_variation = &"SelectedChoiceButton" if parcel_id == _selected_parcel_id else &"DecisionChoiceButton"
		parcel_button.set_meta("parcel_id", parcel_id)
		parcel_button.pressed.connect(select_parcel.bind(parcel_id))
		column.add_child(parcel_button)
		var pads_heading := _label("CONSTRUCTION PADS", 9, COLOR_MUTED)
		column.add_child(pads_heading)
		var filed_pads := _model.pads(parcel_id)
		if filed_pads.is_empty():
			column.add_child(_wrap_label(
				"Utility sockets are filed in North Meadow Details."
				if parcel_id == &"north_meadow" else
				"No surveyed pads filed.",
				10,
				COLOR_MUTED if parcel_id == &"north_meadow" else COLOR_RUST,
			))
		for pad_record: Dictionary in filed_pads:
			var pad_id := StringName(String(pad_record.get("id", "")))
			var pad_button := Button.new()
			pad_button.name = "CampusPortfolioPad_%s" % String(pad_id)
			pad_button.text = "%s\n%s" % [
				String(pad_record.get("name", pad_id)).to_upper(),
				String(pad_record.get("status_label", "HELD")),
			]
			pad_button.custom_minimum_size.y = 45.0
			pad_button.clip_text = true
			pad_button.focus_mode = Control.FOCUS_ALL
			pad_button.theme_type_variation = &"SelectedChoiceButton" if pad_id == _selected_pad_id else &"Button"
			pad_button.tooltip_text = String(pad_record.get("reason", ""))
			pad_button.set_meta("pad_id", pad_id)
			pad_button.pressed.connect(_on_pad_pressed.bind(parcel_id, pad_id))
			column.add_child(pad_button)
			_pad_buttons[pad_id] = pad_button
		var active_projects := _model.projects_for_parcel(parcel_id).size()
		var footer := _label("%d ACTIVE BUILD%s" % [active_projects, "" if active_projects == 1 else "S"], 9, COLOR_TEAL if active_projects > 0 else COLOR_MUTED)
		footer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		footer.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		column.add_child(footer)


func _rebuild_projects() -> void:
	_clear_container(_project_host)
	var projects := _model.projects()
	if projects.is_empty():
		var empty := _label("NO ACTIVE WORK / choose one module and one surveyed pad.", 10, COLOR_MUTED)
		empty.name = "CampusPortfolioProjectQueueEmpty"
		_project_host.add_child(empty)
		return
	for project_record: Dictionary in projects:
		var job_id := StringName(String(project_record.get("job_id", "")))
		var row := VBoxContainer.new()
		row.name = "CampusPortfolioProject_%s" % String(job_id)
		row.add_theme_constant_override("separation", 2)
		_project_host.add_child(row)
		var summary := _wrap_label("%s  /  %s  /  %d SHIFT%s LEFT" % [
			String(project_record.get("module_name", project_record.get("module_id", "PROJECT"))).to_upper(),
			String(project_record.get("status_label", "QUEUED")),
			int(project_record.get("remaining_shifts", 0)),
			"" if int(project_record.get("remaining_shifts", 0)) == 1 else "S",
		], 10, COLOR_INK)
		summary.name = "CampusPortfolioProjectSummary_%s" % String(job_id)
		row.add_child(summary)
		var stages := project_record.get("stages", []) as Array
		if stages.is_empty():
			var stage_id := StringName(String(project_record.get("stage_id", "")))
			var duration := int(project_record.get("duration_shifts", 0))
			var progress := int(project_record.get("progress_shifts", maxi(0, duration - int(project_record.get("remaining_shifts", 0)))))
			var stage_copy := (
				"STAGE / %s" % String(project_record.get("stage_label", _title(stage_id))).to_upper()
				if stage_id != &"" else
				"BUILD PROGRESS / %d OF %d SHIFTS / %s" % [progress, duration, String(project_record.get("status_label", "QUEUED"))]
			)
			var stage := _label(stage_copy, 9, COLOR_BRASS)
			stage.name = "CampusPortfolioStage_%s_%s" % [String(job_id), String(stage_id) if stage_id != &"" else "progress"]
			row.add_child(stage)
		else:
			var stage_flow := HFlowContainer.new()
			stage_flow.add_theme_constant_override("h_separation", 5)
			stage_flow.add_theme_constant_override("v_separation", 2)
			row.add_child(stage_flow)
			for stage_record: Dictionary in stages:
				var stage_id := StringName(String(stage_record.get("id", "")))
				var stage := _label("%s / %s" % [String(stage_record.get("label", stage_id)).to_upper(), String(stage_record.get("status", "pending")).to_upper()], 9, COLOR_TEAL if StringName(String(stage_record.get("status", ""))) == &"complete" else COLOR_BRASS)
				stage.name = "CampusPortfolioStage_%s_%s" % [String(job_id), String(stage_id)]
				stage_flow.add_child(stage)


func _rebuild_module_buttons() -> void:
	_clear_container(_module_host)
	_module_buttons.clear()
	var available := _model.modules(_selected_parcel_id)
	if available.is_empty():
		_module_host.add_child(_wrap_label("No module files are assigned to this parcel.", 10, COLOR_RUST))
		return
	for module_record: Dictionary in available:
		var module_id := StringName(String(module_record.get("id", "")))
		var button := Button.new()
		button.name = "CampusPortfolioModule_%s" % String(module_id)
		button.text = _module_button_text(module_record)
		button.clip_text = true
		button.focus_mode = Control.FOCUS_ALL
		button.theme_type_variation = &"SelectedChoiceButton" if module_id == _selected_module_id else &"DecisionChoiceButton"
		button.set_meta("module_id", module_id)
		button.pressed.connect(select_module.bind(module_id))
		_module_host.add_child(button)
		_module_buttons[module_id] = button


func _refresh_module_buttons() -> void:
	for module_id: StringName in _module_buttons:
		var button := _module_buttons[module_id] as Button
		button.theme_type_variation = &"SelectedChoiceButton" if module_id == _selected_module_id else &"DecisionChoiceButton"


func _refresh_inspector() -> void:
	var parcel_record := _model.parcel(_selected_parcel_id)
	var pad_record := _model.pad(_selected_pad_id)
	var module_record := _model.module(_selected_module_id)
	_north_meadow_details_button.visible = _selected_parcel_id == &"north_meadow"
	if parcel_record.is_empty():
		_inspector_title.text = "NO CAMPUS PARCEL FILED"
		_inspector_status.text = "The portfolio projection contains no selectable parcels."
		_set_inspector_empty()
		return
	if module_record.is_empty():
		_inspector_title.text = String(parcel_record.get("name", _selected_parcel_id)).to_upper()
		_inspector_status.text = "%s / SELECT A MODULE FILE" % String(parcel_record.get("status_label", "HELD"))
		_inspector_pad.text = _pad_copy(pad_record)
		var deed := _model.deed_quote(_selected_parcel_id)
		_inspector_economics.text = _quote_cost_copy(deed)
		_inspector_capacity.text = "Parcel deed / no module capacity selected."
		_inspector_effect.text = _bullet_copy(parcel_record.get("benefit_lines", []), "No parcel effect lines filed.")
		_inspector_reason.text = _reason_or(deed, parcel_record, "No authoritative deed reason filed.")
		return

	var quote := _model.project_quote(_selected_module_id, _selected_pad_id)
	_inspector_title.text = String(module_record.get("name", _selected_module_id)).to_upper()
	var active_project := _model.project_for_module(_selected_module_id)
	var project_status := String(active_project.get("status_label", ""))
	_inspector_status.text = "%s / %s%s" % [
		String(parcel_record.get("name", _selected_parcel_id)).to_upper(),
		String(parcel_record.get("status_label", "HELD")),
		" / %s" % project_status if not project_status.is_empty() else "",
	]
	_inspector_pad.text = _pad_copy(pad_record)
	_inspector_economics.text = _quote_cost_copy(quote)
	_inspector_capacity.text = _capacity_copy(module_record)
	_inspector_effect.text = _bullet_copy(module_record.get("effect_lines", []), "No operational effect lines filed.")
	_inspector_reason.text = _reason_or(quote, module_record, "No authoritative project reason filed.")
	_inspector_reason.add_theme_color_override("font_color", COLOR_TEAL if bool(quote.get("can_authorize", false)) else COLOR_RUST)


func _set_inspector_empty() -> void:
	for label: Label in [_inspector_pad, _inspector_economics, _inspector_capacity, _inspector_effect, _inspector_reason]:
		label.text = "-"


func _refresh_staffing() -> void:
	_worker_selector.clear()
	_selected_worker_id = _model.assignment_for(_selected_module_id) if _selected_worker_id == null else _selected_worker_id
	var module_record := _model.module(_selected_module_id)
	var assigned_id: Variant = _model.assignment_for(_selected_module_id)
	var assigned_worker := _model.worker(assigned_id)
	var workers := _model.workers_for_module(_selected_module_id)
	for worker_record: Dictionary in workers:
		var worker_id: Variant = worker_record.get("id", null)
		var label := "%s / %s%s" % [
			String(worker_record.get("name", "Unnamed hen")),
			String(worker_record.get("role", "Flock worker")),
			" / HELD" if not bool(worker_record.get("can_assign_here", false)) else "",
		]
		_worker_selector.add_item(label)
		var index := _worker_selector.item_count - 1
		_worker_selector.set_item_metadata(index, worker_id)
		_worker_selector.set_item_disabled(index, not bool(worker_record.get("can_assign_here", false)) and str(worker_id) != str(assigned_id))
		if _selected_worker_id != null and str(worker_id) == str(_selected_worker_id):
			_worker_selector.select(index)
	if _worker_selector.item_count > 0 and _worker_selector.selected < 0:
		_worker_selector.select(0)
		_selected_worker_id = _worker_selector.get_item_metadata(0)
	elif _worker_selector.item_count > 0 and _selected_worker_id == null:
		for index: int in range(_worker_selector.item_count):
			if not _worker_selector.is_item_disabled(index):
				_worker_selector.select(index)
				_selected_worker_id = _worker_selector.get_item_metadata(index)
				break

	var assigned_name := String(assigned_worker.get("name", module_record.get("worker_name", ""))).strip_edges()
	_staff_status.text = (
		"CURRENT PERCH / %s" % assigned_name
		if assigned_id != null or not assigned_name.is_empty() else
		"UNSTAFFED / select one available named flock worker."
	)
	_worker_selector.disabled = module_record.is_empty() or workers.is_empty()
	var selected_worker: Dictionary = {}
	for worker_record: Dictionary in workers:
		if str(worker_record.get("id", null)) == str(_selected_worker_id):
			selected_worker = worker_record
			break
	var can_assign := not module_record.is_empty() and not selected_worker.is_empty() and bool(selected_worker.get("can_assign_here", false))
	_assign_button.disabled = not can_assign or str(_selected_worker_id) == str(assigned_id)
	_unassign_button.visible = assigned_id != null or not assigned_name.is_empty()
	_unassign_button.disabled = module_record.is_empty() or not _unassign_button.visible


func _refresh_action() -> void:
	var parcel_record := _model.parcel(_selected_parcel_id)
	if parcel_record.is_empty():
		_action_button.text = "NO FILED ACTION"
		_action_button.disabled = true
		_action_summary.text = "No authoritative campus parcel is available."
		return
	if not bool(parcel_record.get("owned", false)):
		var quote := _model.deed_quote(_selected_parcel_id)
		_action_button.text = "BUY %s DEED%s" % [
			String(parcel_record.get("name", _selected_parcel_id)).to_upper(),
			" / %s" % _money(int(quote.get("cost_cents", 0))) if bool(quote.get("has_cost", false)) else "",
		]
		_action_button.disabled = not bool(quote.get("can_authorize", false))
		_action_button.set_meta("action_id", &"deed")
		_action_summary.text = _reason_or(quote, parcel_record, "No authoritative deed reason filed.")
		_action_button.tooltip_text = _action_summary.text
		return

	var module_record := _model.module(_selected_module_id)
	if module_record.is_empty() or _selected_pad_id == &"":
		_action_button.text = "SELECT MODULE & PAD"
		_action_button.disabled = true
		_action_button.set_meta("action_id", &"none")
		_action_summary.text = "Choose one module file and one surveyed construction pad."
		return
	var active_project := _model.project_for_module(_selected_module_id)
	var quote := _model.project_quote(_selected_module_id, _selected_pad_id)
	var held_by_existing := bool(module_record.get("installed", false)) or not active_project.is_empty()
	var duration := int(quote.get("duration_shifts", module_record.get("duration_shifts", 0)))
	_action_button.text = "QUEUE %s%s%s" % [
		String(module_record.get("name", _selected_module_id)).to_upper(),
		" / %s" % _money(int(quote.get("cost_cents", 0))) if bool(quote.get("has_cost", false)) else "",
		" / %d SHIFT%s" % [duration, "" if duration == 1 else "S"] if duration > 0 else "",
	]
	if held_by_existing:
		_action_button.text = "COMMISSIONED" if bool(module_record.get("installed", false)) else "PROJECT ACTIVE"
	_action_button.disabled = held_by_existing or not bool(quote.get("can_authorize", false))
	_action_button.set_meta("action_id", &"project")
	_action_summary.text = (
		String(active_project.get("reason", active_project.get("status_label", "Project already active.")))
		if not active_project.is_empty() else
		_reason_or(quote, module_record, "No authoritative project reason filed.")
	)
	_action_button.tooltip_text = _action_summary.text


func _on_action_pressed() -> void:
	if _action_button.disabled:
		return
	var action_id := StringName(String(_action_button.get_meta("action_id", &"none")))
	if action_id == &"deed":
		var quote := _model.deed_quote(_selected_parcel_id)
		if bool(quote.get("can_authorize", false)):
			deed_requested.emit(_selected_parcel_id)
	elif action_id == &"project":
		var quote := _model.project_quote(_selected_module_id, _selected_pad_id)
		if bool(quote.get("can_authorize", false)):
			project_requested.emit(_selected_module_id, _selected_pad_id)


func _on_pad_pressed(parcel_id: StringName, pad_id: StringName) -> void:
	if parcel_id != _selected_parcel_id:
		_selected_parcel_id = parcel_id
	select_pad(pad_id)


func _on_worker_selected(index: int) -> void:
	if index >= 0 and index < _worker_selector.item_count:
		_selected_worker_id = _worker_selector.get_item_metadata(index)
	_refresh_staffing()


func _on_assign_pressed() -> void:
	if _assign_button.disabled or _selected_module_id == &"" or _selected_worker_id == null:
		return
	staff_assignment_requested.emit(_selected_module_id, _selected_worker_id)


func _on_unassign_pressed() -> void:
	if _unassign_button.disabled or _selected_module_id == &"":
		return
	staff_unassignment_requested.emit(_selected_module_id)


func _apply_responsive_layout() -> void:
	if _body_scroll == null or _applying_layout:
		return
	_applying_layout = true
	var compact := size.x <= COMPACT_BREAKPOINT
	_layout_mode = &"compact" if compact else &"desktop"
	var target_body: Container = _compact_body if compact else _desktop_body
	if _active_body != target_body:
		_reparent_control(_map_panel, target_body)
		_reparent_control(_inspector_panel, target_body)
		if _active_body != null and _active_body.get_parent() == _body_scroll:
			_body_scroll.remove_child(_active_body)
		_active_body = target_body
		_body_scroll.add_child(_active_body)
		if _map_panel.get_parent() != _active_body:
			_active_body.add_child(_map_panel)
		if _inspector_panel.get_parent() != _active_body:
			_active_body.add_child(_inspector_panel)
	var target_parcels: Container = _compact_parcel_host if compact else _desktop_parcel_host
	if _active_parcel_host != target_parcels:
		var map_column := _active_parcel_host.get_parent() as VBoxContainer
		if map_column != null:
			map_column.remove_child(_active_parcel_host)
		_active_parcel_host = target_parcels
		if map_column != null:
			map_column.add_child(_active_parcel_host)
			map_column.move_child(_active_parcel_host, 1)
		_rebuild_parcel_cards()
	_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if compact else ScrollContainer.SCROLL_MODE_DISABLED
	if compact:
		_map_panel.custom_minimum_size = Vector2(0.0, 710.0)
		_inspector_panel.custom_minimum_size = Vector2(0.0, 620.0)
		_header_status.custom_minimum_size.x = 125.0
		_header_status.visible = size.x >= 520.0
		_action_summary.visible = size.x >= 620.0
		_return_button.custom_minimum_size.x = 108.0
		_return_button.text = "RETURN"
		_action_button.custom_minimum_size.x = 200.0
		for card_value: Variant in _resource_labels.values():
			var resource_panel := (card_value as Label).get_parent() as PanelContainer
			resource_panel.custom_minimum_size.x = 106.0
	else:
		_map_panel.custom_minimum_size = Vector2(560.0, 430.0)
		_inspector_panel.custom_minimum_size = Vector2(330.0, 430.0)
		_header_status.custom_minimum_size.x = 280.0
		_header_status.visible = true
		_action_summary.visible = true
		_return_button.custom_minimum_size.x = 164.0
		_return_button.text = "RETURN TO BLUEPRINT"
		_action_button.custom_minimum_size.x = 270.0
		for card_value: Variant in _resource_labels.values():
			var resource_panel := (card_value as Label).get_parent() as PanelContainer
			resource_panel.custom_minimum_size.x = 150.0
	_applying_layout = false


func _reparent_control(control: Control, target: Container) -> void:
	if control == null or control.get_parent() == target:
		return
	if control.get_parent() != null:
		control.get_parent().remove_child(control)
	target.add_child(control)


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or _is_repeated_key_event(event):
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close_requested.emit()


func _focus_selection() -> void:
	var target := _pad_buttons.get(_selected_pad_id) as Button
	if target == null:
		target = _action_button
	if target != null and target.is_visible_in_tree():
		target.grab_focus()


func _module_button_text(module_record: Dictionary) -> String:
	var cost := " / %s" % _money(int(module_record.get("cost_cents", 0))) if bool(module_record.get("has_cost", false)) else ""
	var state := (
		" / ONLINE" if bool(module_record.get("operational", false)) else
		" / BUILT" if bool(module_record.get("installed", false)) else
		""
	)
	return "%s%s%s" % [String(module_record.get("name", "MODULE")).to_upper(), cost, state]


func _pad_copy(pad_record: Dictionary) -> String:
	if pad_record.is_empty():
		return "No surveyed construction pad selected."
	var reason := String(pad_record.get("reason", "")).strip_edges()
	return "%s / %s%s" % [
		String(pad_record.get("name", "PAD")).to_upper(),
		String(pad_record.get("status_label", "HELD")),
		"\n%s" % reason if not reason.is_empty() else "",
	]


func _quote_cost_copy(quote: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("CAPITAL  %s" % _money(int(quote.get("cost_cents", 0))) if bool(quote.get("has_cost", false)) else "CAPITAL  NOT FILED")
	lines.append("DAILY LIABILITY  %s" % _money(int(quote.get("daily_cost_cents", 0))) if bool(quote.get("has_daily_cost", false)) else "DAILY LIABILITY  NOT FILED")
	var duration := int(quote.get("duration_shifts", 0))
	if duration > 0:
		lines.append("BUILD TIME  %d SHIFT%s" % [duration, "" if duration == 1 else "S"])
	if quote.has("projected_spendable_fund_cents"):
		lines.append("AFTER BUILD SPENDABLE  %s" % _money(int(quote.get("projected_spendable_fund_cents", 0))))
	if quote.has("projected_protected_reserve_cents"):
		lines.append("PROTECTED RESERVE  %s" % _money(int(quote.get("projected_protected_reserve_cents", 0))))
	return "\n".join(lines)


func _capacity_copy(module_record: Dictionary) -> String:
	var staff_required := int(module_record.get("staff_required", 0))
	return "CONTRACTORS  %d\nPOWER  %d\nCOLD  %d\nSTAFF  %s" % [
		int(module_record.get("contractor_slots", 0)),
		int(module_record.get("power_required", 0)),
		int(module_record.get("cold_required", 0)),
		str(staff_required) if staff_required > 0 else "NO DEDICATED PERCH",
	]


func _reason_or(quote: Dictionary, fallback: Dictionary, empty_text: String) -> String:
	var reason := String(quote.get("reason", fallback.get("reason", ""))).strip_edges()
	return reason if not reason.is_empty() else empty_text


func _bullet_copy(value: Variant, fallback: String) -> String:
	var lines: Array[String] = []
	if value is Array:
		for item: Variant in value as Array:
			var line := str(item).strip_edges()
			if not line.is_empty():
				lines.append("- %s" % line)
	elif value is String or value is StringName:
		var line := str(value).strip_edges()
		if not line.is_empty():
			lines.append("- %s" % line)
	return "\n".join(lines) if not lines.is_empty() else fallback


func _parcel_style(parcel_id: StringName, selected: bool) -> StyleBoxFlat:
	var fill := Color("213430")
	if parcel_id == &"orchard_row":
		fill = COLOR_ORCHARD
	elif parcel_id == &"creekside_yard":
		fill = COLOR_CREEK
	return _panel_style(fill.lightened(0.035) if selected else fill, COLOR_BRASS if selected else Color("47605b"), 8, 2 if selected else 1)


func _margin(parent: Control, amount: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", amount)
	margin.add_theme_constant_override("margin_right", amount)
	margin.add_theme_constant_override("margin_top", amount)
	margin.add_theme_constant_override("margin_bottom", amount)
	parent.add_child(margin)
	return margin


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	return label


func _wrap_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := _label(text_value, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _panel_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _clear_container(container: Container) -> void:
	if container == null:
		return
	for child: Node in container.get_children():
		container.remove_child(child)
		child.free()


func _money(cents: int) -> String:
	return "$%.2f" % (float(cents) / 100.0)


func _title(value: StringName) -> String:
	return String(value).replace("_", " ").capitalize()


func _is_repeated_key_event(event: InputEvent) -> bool:
	return event is InputEventKey and (event as InputEventKey).echo
