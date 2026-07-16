class_name CampusExpansionUI
extends Control

## Responsive, intent-only North Meadow campus planner.
##
## Public integration contract:
## - set_snapshot(snapshot): applies the authoritative `campus_expansion` view.
## - purchase_parcel_requested(parcel_id): asks the host to purchase North Meadow.
## - connect_service_requested(service_id): asks the host to connect one utility.
## - place_pod_requested(socket_id): asks the host to place the Egg Routing Pod.
## - relocate_pod_requested(from_socket_id, to_socket_id): asks the host to move it.
## - close_requested: asks the host to leave the planner.
##
## Selection is presentation-only. This control never spends funds, resolves a
## dependency, changes a route, advances construction, or moves the pod itself.

signal close_requested
signal purchase_parcel_requested(parcel_id: StringName)
signal connect_service_requested(service_id: StringName)
signal place_pod_requested(socket_id: StringName)
signal relocate_pod_requested(from_socket_id: StringName, to_socket_id: StringName)

const CampusModelScript := preload("res://features/office/campus_expansion_model.gd")
const ManagementTheme := preload("res://features/office/management_ui_theme.gd")

const COMPACT_BREAKPOINT := 900.0
const COLOR_INK := Color("eef1df")
const COLOR_MUTED := Color("aeb8c4")
const COLOR_BRASS := Color("e7c56e")
const COLOR_TEAL := Color("73b5a7")
const COLOR_RUST := Color("d68a68")
const COLOR_NAVY := Color("101923")
const COLOR_PANEL := Color("17232d")
const COLOR_SITE := Color("172a2c")

var _model := CampusExpansionModel.new()
var _selected_socket_id := CampusExpansionModel.SOCKET_A
var _layout_mode := &"desktop"
var _return_focus: WeakRef

var _main_panel: PanelContainer
var _header_status: Label
var _body_scroll: ScrollContainer
var _desktop_body: HBoxContainer
var _compact_body: VBoxContainer
var _active_body: Container
var _site_panel: PanelContainer
var _project_panel: PanelContainer

var _parcel_title: Label
var _parcel_status: Label
var _parcel_costs: Label
var _parcel_dependencies: Label
var _parcel_benefits: Label
var _parcel_reason: Label
var _parcel_button: Button

var _socket_buttons: Dictionary = {}
var _socket_detail: Label
var _service_controls: Dictionary = {}
var _stage_host: HFlowContainer
var _benefit_summary: Label

var _selection_summary: Label
var _close_button: Button
var _place_button: Button
var _relocate_button: Button


func _ready() -> void:
	name = "CampusExpansionUI"
	theme = ManagementTheme.create_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_apply_responsive_layout)
	_build_interface()
	_refresh()
	visible = false
	set_process_unhandled_key_input(false)
	_apply_responsive_layout()


func _exit_tree() -> void:
	for body: Container in [_desktop_body, _compact_body]:
		if body != null and is_instance_valid(body) and body.get_parent() == null:
			body.free()


func set_snapshot(snapshot: Dictionary) -> void:
	var previous := _selected_socket_id
	_model.set_snapshot(snapshot)
	if previous in CampusExpansionModel.SOCKET_ORDER:
		_selected_socket_id = previous
	else:
		_selected_socket_id = _model.default_socket_id()
	if is_node_ready():
		_refresh()


func show_planner(snapshot: Dictionary = {}) -> void:
	if not snapshot.is_empty():
		set_snapshot(snapshot)
	visible = true
	set_process_unhandled_key_input(true)
	_refresh()
	call_deferred("_focus_selected_socket")


func hide_planner(restore_focus: bool = true) -> void:
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


func selected_socket_id() -> StringName:
	return _selected_socket_id


func layout_mode_name() -> StringName:
	return _layout_mode


func select_socket(socket_id: StringName) -> bool:
	if socket_id not in CampusExpansionModel.SOCKET_ORDER:
		return false
	_selected_socket_id = socket_id
	if is_node_ready():
		_refresh_sockets()
		_refresh_pod_action()
	return true


func presentation_state() -> Dictionary:
	var pod := _model.routing_pod()
	var quote := (
		_model.relocation_quote(_selected_socket_id)
		if bool(pod.get("placed", false)) else
		_model.placement_quote(_selected_socket_id)
	)
	return {
		"visible": visible,
		"layout_mode": _layout_mode,
		"selected_socket_id": _selected_socket_id,
		"parcel": _model.parcel(),
		"services": _model.services(),
		"sockets": _model.sockets(),
		"routing_pod": pod,
		"selected_quote": quote,
		"construction_stages": _model.construction_stages(),
		"operational_benefits": _model.operational_benefits(),
	}


func accessible_text() -> String:
	var parts: Array[String] = [
		"CAMPUS EXPANSION",
		_header_status.text,
		_parcel_title.text,
		_parcel_status.text,
		_parcel_costs.text,
		_parcel_dependencies.text,
		_parcel_reason.text,
		_socket_detail.text,
	]
	for service_id: StringName in CampusExpansionModel.SERVICE_ORDER:
		var controls := _service_controls.get(service_id, {}) as Dictionary
		for key: String in ["title", "status", "costs", "dependencies", "reason"]:
			var label := controls.get(key) as Label
			if label != null:
				parts.append(label.text)
	for socket_id: StringName in CampusExpansionModel.SOCKET_ORDER:
		var socket := _model.socket(socket_id)
		parts.append("%s / %s / %s" % [
			String(socket.get("label", socket_id)),
			String(socket.get("status_label", "HELD")),
			String(socket.get("route_reason", socket.get("reason", ""))),
		])
	parts.append(_benefit_summary.text)
	parts.append(_selection_summary.text)
	return "; ".join(parts).replace("\n", "; ")


func _build_interface() -> void:
	var scrim := ColorRect.new()
	scrim.name = "CampusExpansionScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.025, 0.04, 0.055, 0.94)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	_main_panel = PanelContainer.new()
	_main_panel.name = "CampusExpansionPanel"
	_main_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_panel.offset_left = 14.0
	_main_panel.offset_top = 12.0
	_main_panel.offset_right = -14.0
	_main_panel.offset_bottom = -12.0
	_main_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_main_panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL, COLOR_BRASS, 12, 2))
	add_child(_main_panel)

	var margin := MarginContainer.new()
	margin.name = "CampusExpansionOuterMargin"
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_main_panel.add_child(margin)

	var page := VBoxContainer.new()
	page.name = "CampusExpansionPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 8)
	margin.add_child(page)

	var header := HBoxContainer.new()
	header.name = "CampusExpansionHeader"
	header.custom_minimum_size.y = 46.0
	header.add_theme_constant_override("separation", 14)
	page.add_child(header)
	var title := _label("CAMPUS EXPANSION", 23, COLOR_BRASS)
	title.name = "CampusExpansionTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_header_status = _label("NORTH MEADOW / PLAN NOT FILED", 12, COLOR_TEAL)
	_header_status.name = "CampusExpansionHeaderStatus"
	_header_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_header_status.custom_minimum_size.x = 340.0
	header.add_child(_header_status)

	_body_scroll = ScrollContainer.new()
	_body_scroll.name = "CampusExpansionBodyScroll"
	_body_scroll.custom_minimum_size.y = 180.0
	_body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	page.add_child(_body_scroll)

	_desktop_body = HBoxContainer.new()
	_desktop_body.name = "CampusExpansionDesktopBody"
	_desktop_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_desktop_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desktop_body.add_theme_constant_override("separation", 10)
	_compact_body = VBoxContainer.new()
	_compact_body.name = "CampusExpansionCompactBody"
	_compact_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compact_body.add_theme_constant_override("separation", 10)

	_build_site_panel()
	_build_project_panel()
	_active_body = _desktop_body
	_body_scroll.add_child(_active_body)
	_active_body.add_child(_site_panel)
	_active_body.add_child(_project_panel)

	var action_rail := HBoxContainer.new()
	action_rail.name = "CampusExpansionActionRail"
	action_rail.custom_minimum_size.y = 48.0
	action_rail.add_theme_constant_override("separation", 10)
	page.add_child(action_rail)
	_close_button = Button.new()
	_close_button.name = "CampusExpansionCloseButton"
	_close_button.text = "RETURN TO OFFICE"
	_close_button.custom_minimum_size = Vector2(170.0, 44.0)
	_close_button.focus_mode = Control.FOCUS_ALL
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	action_rail.add_child(_close_button)
	_selection_summary = _label("SELECT A POD SOCKET", 12, COLOR_MUTED)
	_selection_summary.name = "CampusExpansionSelectionSummary"
	_selection_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selection_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_selection_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_selection_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_rail.add_child(_selection_summary)
	_place_button = Button.new()
	_place_button.name = "CampusExpansionPlacePodButton"
	_place_button.text = "PLACE EGG ROUTING POD"
	_place_button.theme_type_variation = &"PrimaryButton"
	_place_button.custom_minimum_size = Vector2(225.0, 44.0)
	_place_button.focus_mode = Control.FOCUS_ALL
	_place_button.pressed.connect(_on_place_pod_pressed)
	action_rail.add_child(_place_button)
	_relocate_button = Button.new()
	_relocate_button.name = "CampusExpansionRelocatePodButton"
	_relocate_button.text = "RELOCATE EGG ROUTING POD"
	_relocate_button.theme_type_variation = &"PrimaryButton"
	_relocate_button.custom_minimum_size = Vector2(245.0, 44.0)
	_relocate_button.focus_mode = Control.FOCUS_ALL
	_relocate_button.pressed.connect(_on_relocate_pod_pressed)
	action_rail.add_child(_relocate_button)


func _build_site_panel() -> void:
	_site_panel = PanelContainer.new()
	_site_panel.name = "CampusExpansionSitePanel"
	_site_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_site_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_site_panel.size_flags_stretch_ratio = 5.5
	_site_panel.custom_minimum_size = Vector2(440.0, 470.0)
	_site_panel.add_theme_stylebox_override("panel", _panel_style(COLOR_SITE, Color("44645f"), 9, 1))
	var margin := _panel_margin(_site_panel)
	var column := VBoxContainer.new()
	column.name = "CampusExpansionSiteColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var parcel_heading := _label("NORTH MEADOW PARCEL", 13, COLOR_BRASS)
	parcel_heading.name = "CampusExpansionParcelHeading"
	column.add_child(parcel_heading)
	var parcel_card := PanelContainer.new()
	parcel_card.name = "CampusExpansionParcelCard"
	parcel_card.add_theme_stylebox_override("panel", _panel_style(Color("1b3030"), Color("58736d"), 8, 1))
	column.add_child(parcel_card)
	var parcel_margin := _panel_margin(parcel_card, 10)
	var parcel_column := VBoxContainer.new()
	parcel_column.add_theme_constant_override("separation", 4)
	parcel_margin.add_child(parcel_column)
	var parcel_top := HBoxContainer.new()
	parcel_top.add_theme_constant_override("separation", 8)
	parcel_column.add_child(parcel_top)
	_parcel_title = _label("NORTH MEADOW", 18, COLOR_INK)
	_parcel_title.name = "CampusExpansionParcelName"
	_parcel_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parcel_top.add_child(_parcel_title)
	_parcel_status = _label("HELD", 12, COLOR_RUST)
	_parcel_status.name = "CampusExpansionParcelStatus"
	parcel_top.add_child(_parcel_status)
	_parcel_costs = _wrap_label("PURCHASE NOT FILED / RECURRING NOT FILED", 13, COLOR_INK)
	_parcel_costs.name = "CampusExpansionParcelCosts"
	parcel_column.add_child(_parcel_costs)
	_parcel_dependencies = _wrap_label("DEPENDENCIES / NOT FILED", 11, COLOR_MUTED)
	_parcel_dependencies.name = "CampusExpansionParcelDependencies"
	parcel_column.add_child(_parcel_dependencies)
	_parcel_benefits = _wrap_label("SITE EFFECT / NOT FILED", 11, COLOR_MUTED)
	_parcel_benefits.name = "CampusExpansionParcelBenefits"
	parcel_column.add_child(_parcel_benefits)
	_parcel_reason = _wrap_label("No authoritative North Meadow parcel file is available.", 11, COLOR_RUST)
	_parcel_reason.name = "CampusExpansionParcelReason"
	parcel_column.add_child(_parcel_reason)
	_parcel_button = Button.new()
	_parcel_button.name = "CampusExpansionPurchaseParcelButton"
	_parcel_button.text = "PURCHASE NORTH MEADOW"
	_parcel_button.theme_type_variation = &"PrimaryButton"
	_parcel_button.custom_minimum_size.y = 40.0
	_parcel_button.focus_mode = Control.FOCUS_ALL
	_parcel_button.pressed.connect(_on_purchase_parcel_pressed)
	parcel_column.add_child(_parcel_button)

	var map_heading := _label("EAST CAMPUS FOOTPRINT / ABOVE FARMGATE DEPOT", 13, COLOR_BRASS)
	map_heading.name = "CampusExpansionMapHeading"
	column.add_child(map_heading)
	var map_card := PanelContainer.new()
	map_card.name = "CampusExpansionMapCard"
	map_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_card.add_theme_stylebox_override("panel", _panel_style(Color("112226"), Color("3f5a62"), 8, 1))
	column.add_child(map_card)
	var map_margin := _panel_margin(map_card, 10)
	var map_column := VBoxContainer.new()
	map_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_column.add_theme_constant_override("separation", 8)
	map_margin.add_child(map_column)
	var footprint := _wrap_label("NORTH MEADOW SERVICE APRON / SELECT ONE FILED POD SOCKET", 11, COLOR_TEAL)
	footprint.name = "CampusExpansionFootprintLabel"
	footprint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_column.add_child(footprint)
	var sockets := HBoxContainer.new()
	sockets.name = "CampusExpansionSockets"
	sockets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sockets.add_theme_constant_override("separation", 8)
	map_column.add_child(sockets)
	for socket_id: StringName in CampusExpansionModel.SOCKET_ORDER:
		var button := Button.new()
		button.name = "CampusExpansionSocket_%s" % String(socket_id)
		button.text = String(socket_id).replace("_", " ").to_upper()
		button.custom_minimum_size = Vector2(118.0, 76.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_socket_pressed.bind(socket_id))
		button.gui_input.connect(_on_socket_gui_input.bind(socket_id))
		sockets.add_child(button)
		_socket_buttons[socket_id] = button
	_socket_detail = _wrap_label("Select a socket to inspect its route and pod quote.", 12, COLOR_MUTED)
	_socket_detail.name = "CampusExpansionSocketDetail"
	_socket_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_column.add_child(_socket_detail)


func _build_project_panel() -> void:
	_project_panel = PanelContainer.new()
	_project_panel.name = "CampusExpansionProjectPanel"
	_project_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_project_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_project_panel.size_flags_stretch_ratio = 4.5
	_project_panel.custom_minimum_size = Vector2(390.0, 470.0)
	_project_panel.add_theme_stylebox_override("panel", _panel_style(Color("18232d"), Color("485b68"), 9, 1))
	var margin := _panel_margin(_project_panel)
	var column := VBoxContainer.new()
	column.name = "CampusExpansionProjectColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var utility_heading := _label("MEADOW UTILITIES", 13, COLOR_BRASS)
	utility_heading.name = "CampusExpansionUtilitiesHeading"
	column.add_child(utility_heading)
	var utility_flow := HFlowContainer.new()
	utility_flow.name = "CampusExpansionUtilityCards"
	utility_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	utility_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	utility_flow.add_theme_constant_override("h_separation", 7)
	utility_flow.add_theme_constant_override("v_separation", 7)
	column.add_child(utility_flow)
	for service_id: StringName in CampusExpansionModel.SERVICE_ORDER:
		_build_service_card(utility_flow, service_id)

	var stage_heading := _label("STAGED CONSTRUCTION", 13, COLOR_BRASS)
	stage_heading.name = "CampusExpansionStagesHeading"
	column.add_child(stage_heading)
	_stage_host = HFlowContainer.new()
	_stage_host.name = "CampusExpansionStages"
	_stage_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage_host.alignment = FlowContainer.ALIGNMENT_CENTER
	_stage_host.add_theme_constant_override("h_separation", 7)
	_stage_host.add_theme_constant_override("v_separation", 7)
	column.add_child(_stage_host)

	var benefit_heading := _label("OPERATIONAL BENEFIT", 13, COLOR_BRASS)
	benefit_heading.name = "CampusExpansionBenefitsHeading"
	column.add_child(benefit_heading)
	_benefit_summary = _wrap_label("No staged construction or operating effect is filed.", 12, COLOR_MUTED)
	_benefit_summary.name = "CampusExpansionBenefitSummary"
	_benefit_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_benefit_summary)


func _build_service_card(parent: HFlowContainer, service_id: StringName) -> void:
	var card := PanelContainer.new()
	card.name = "CampusExpansionServiceCard_%s" % String(service_id)
	card.custom_minimum_size = Vector2(145.0, 178.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel_style(Color("1a2933"), Color("425b65"), 7, 1))
	parent.add_child(card)
	var margin := _panel_margin(card, 8)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	margin.add_child(column)
	var title := _wrap_label("SERVICE", 12, COLOR_INK)
	title.name = "CampusExpansionServiceTitle_%s" % String(service_id)
	column.add_child(title)
	var status := _label("HELD", 10, COLOR_RUST)
	status.name = "CampusExpansionServiceStatus_%s" % String(service_id)
	column.add_child(status)
	var costs := _wrap_label("PURCHASE / NOT FILED\nRECURRING / NOT FILED", 10, COLOR_MUTED)
	costs.name = "CampusExpansionServiceCosts_%s" % String(service_id)
	column.add_child(costs)
	var dependencies := _wrap_label("DEPENDENCIES / NOT FILED", 9, COLOR_MUTED)
	dependencies.name = "CampusExpansionServiceDependencies_%s" % String(service_id)
	dependencies.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(dependencies)
	var reason := _wrap_label("No authoritative service quote is filed.", 9, COLOR_RUST)
	reason.name = "CampusExpansionServiceReason_%s" % String(service_id)
	column.add_child(reason)
	var button := Button.new()
	button.name = "CampusExpansionConnectService_%s" % String(service_id)
	button.text = "CONNECT"
	button.custom_minimum_size.y = 36.0
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_on_connect_service_pressed.bind(service_id))
	column.add_child(button)
	_service_controls[service_id] = {
		"card": card,
		"title": title,
		"status": status,
		"costs": costs,
		"dependencies": dependencies,
		"reason": reason,
		"button": button,
	}


func _refresh() -> void:
	if _main_panel == null:
		return
	_refresh_header()
	_refresh_parcel()
	_refresh_services()
	_refresh_sockets()
	_refresh_stages_and_benefits()
	_refresh_pod_action()
	_apply_responsive_layout()
	tooltip_text = accessible_text()


func _refresh_header() -> void:
	var parcel := _model.parcel()
	var pod := _model.routing_pod()
	_header_status.text = "NORTH MEADOW / %s / POD %s" % [
		String(parcel.get("status_label", "HELD")),
		"AT %s" % String(pod.get("current_socket_id", "")).replace("_", " ").to_upper()
		if bool(pod.get("placed", false)) else
		"UNPLACED",
	]


func _refresh_parcel() -> void:
	var parcel := _model.parcel()
	_parcel_title.text = String(parcel.get("name", "NORTH MEADOW")).to_upper()
	_parcel_status.text = String(parcel.get("status_label", "HELD"))
	_parcel_status.add_theme_color_override(
		"font_color",
		COLOR_TEAL if bool(parcel.get("owned", false)) or bool(parcel.get("can_purchase", false)) else COLOR_RUST,
	)
	_parcel_costs.text = "PURCHASE  %s   /   RECURRING  %s" % [
		_money(int(parcel.get("purchase_cost_cents", 0))) if bool(parcel.get("has_purchase_cost", false)) else "NOT FILED",
		"%s/DAY" % _money(int(parcel.get("recurring_cost_cents", 0))) if bool(parcel.get("has_recurring_cost", false)) else "NOT FILED",
	]
	_parcel_dependencies.text = "DEPENDENCIES\n%s" % _lines_or(
		parcel.get("dependency_lines", []),
		"NONE FILED",
	)
	_parcel_benefits.text = "SITE EFFECT\n%s" % _lines_or(
		parcel.get("benefit_lines", []),
		"NONE FILED",
	)
	var owned := bool(parcel.get("owned", false))
	var has_cost := bool(parcel.get("has_purchase_cost", false))
	var can_authorize := not owned and bool(parcel.get("can_purchase", false)) and has_cost
	var reason := String(parcel.get("reason", "")).strip_edges()
	if owned:
		reason = "North Meadow is already held in the campus deed."
	elif bool(parcel.get("can_purchase", false)) and not has_cost:
		reason = "No authoritative North Meadow purchase price is filed."
	elif reason.is_empty() and can_authorize:
		reason = "Parcel purchase is ready for explicit authorization."
	elif reason.is_empty():
		reason = "North Meadow purchase is held by the filed dependencies."
	_parcel_reason.text = reason
	_parcel_button.disabled = not can_authorize
	_parcel_button.text = (
		"NORTH MEADOW OWNED" if owned else
		"PURCHASE NORTH MEADOW / %s" % _money(int(parcel.get("purchase_cost_cents", 0))) if has_cost else
		"PURCHASE NORTH MEADOW / QUOTE HELD"
	)
	_parcel_button.tooltip_text = reason


func _refresh_services() -> void:
	for service_id: StringName in CampusExpansionModel.SERVICE_ORDER:
		var service := _model.service(service_id)
		var controls := _service_controls.get(service_id, {}) as Dictionary
		var title := controls.get("title") as Label
		var status := controls.get("status") as Label
		var costs := controls.get("costs") as Label
		var dependencies := controls.get("dependencies") as Label
		var reason_label := controls.get("reason") as Label
		var button := controls.get("button") as Button
		if button == null:
			continue
		title.text = String(service.get("name", service_id)).to_upper()
		status.text = String(service.get("status_label", "HELD"))
		var connected := bool(service.get("connected", false))
		var has_cost := bool(service.get("has_purchase_cost", false))
		var can_authorize := not connected and bool(service.get("can_connect", false)) and has_cost
		status.add_theme_color_override("font_color", COLOR_TEAL if connected or can_authorize else COLOR_RUST)
		costs.text = "PURCHASE  %s\nRECURRING  %s" % [
			_money(int(service.get("purchase_cost_cents", 0))) if has_cost else "NOT FILED",
			"%s/DAY" % _money(int(service.get("recurring_cost_cents", 0))) if bool(service.get("has_recurring_cost", false)) else "NOT FILED",
		]
		dependencies.text = "DEPENDENCIES\n%s" % _lines_or(
			service.get("dependency_lines", []),
			"NONE FILED",
		)
		var reason := String(service.get("reason", "")).strip_edges()
		if connected:
			reason = "This North Meadow service is already connected."
		elif bool(service.get("can_connect", false)) and not has_cost:
			reason = "No authoritative service purchase quote is filed."
		elif reason.is_empty() and can_authorize:
			reason = "Every filed dependency is cleared for connection."
		elif reason.is_empty():
			reason = "This service is held by its filed dependencies."
		reason_label.text = reason
		button.disabled = not can_authorize
		button.text = (
			"CONNECTED" if connected else
			"CONNECT / %s" % _money(int(service.get("purchase_cost_cents", 0))) if has_cost else
			"CONNECT / QUOTE HELD"
		)
		button.tooltip_text = reason


func _refresh_sockets() -> void:
	for socket_id: StringName in CampusExpansionModel.SOCKET_ORDER:
		var socket := _model.socket(socket_id)
		var button := _socket_buttons.get(socket_id) as Button
		if button == null:
			continue
		var selected := socket_id == _selected_socket_id
		button.text = "%s\n%s" % [
			String(socket.get("label", socket_id)).to_upper(),
			String(socket.get("status_label", "HELD")),
		]
		button.set_meta("socket_id", socket_id)
		button.set_meta("selected", selected)
		button.set_meta("route_blocked", bool(socket.get("route_blocked", false)))
		button.theme_type_variation = &"SelectedChoiceButton" if selected else &"DecisionChoiceButton"
		button.tooltip_text = String(socket.get(
			"route_reason",
			socket.get("reason", "No authoritative route survey is filed."),
		))
		button.add_theme_stylebox_override(
			"normal",
			_panel_style(
				Color("3a2829") if bool(socket.get("route_blocked", false)) else Color("344d49") if selected else Color("20313a"),
				COLOR_RUST if bool(socket.get("route_blocked", false)) else COLOR_BRASS if selected else Color("4d626d"),
				7,
				2 if selected else 1,
			),
		)
	var selected_socket := _model.socket(_selected_socket_id)
	var pod := _model.routing_pod()
	var route_copy := String(selected_socket.get("route_reason", "")).strip_edges()
	if route_copy.is_empty():
		route_copy = String(selected_socket.get("reason", "Route survey is ready.")).strip_edges()
	var quote := (
		_model.relocation_quote(_selected_socket_id)
		if bool(pod.get("placed", false)) else
		_model.placement_quote(_selected_socket_id)
	)
	_socket_detail.text = "%s / %s\nROUTE  %s\n%s QUOTE  %s / ADDED RECURRING  %s" % [
		String(selected_socket.get("label", _selected_socket_id)).to_upper(),
		String(selected_socket.get("status_label", "HELD")),
		route_copy,
		"RELOCATION" if bool(pod.get("placed", false)) else "PLACEMENT",
		_money(int(quote.get("cost_cents", 0))) if bool(quote.get("has_cost", false)) else "NOT FILED",
		"%s/DAY" % _money(int(quote.get("recurring_cost_cents", 0))) if bool(quote.get("has_recurring_cost", false)) else "NOT FILED",
	]
	_socket_detail.add_theme_color_override(
		"font_color",
		COLOR_RUST if bool(selected_socket.get("route_blocked", false)) else COLOR_MUTED,
	)


func _refresh_stages_and_benefits() -> void:
	for child: Node in _stage_host.get_children():
		child.free()
	var stages := _model.construction_stages()
	if stages.is_empty():
		var empty := _wrap_label("NO CONSTRUCTION STAGES FILED", 11, COLOR_MUTED)
		empty.name = "CampusExpansionStageEmpty"
		_stage_host.add_child(empty)
	else:
		for stage: Dictionary in stages:
			var card := PanelContainer.new()
			card.name = "CampusExpansionStage_%s" % String(stage.get("id", "stage"))
			card.custom_minimum_size = Vector2(118.0, 78.0)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var status_id := StringName(String(stage.get("status_id", "pending")))
			var active := status_id in [&"active", &"building", &"construction"]
			var complete := status_id in [&"complete", &"operational", &"connected", &"owned"]
			card.add_theme_stylebox_override(
				"panel",
				_panel_style(
					Color("24443e") if complete else Color("443c2b") if active else Color("202b34"),
					COLOR_TEAL if complete else COLOR_BRASS if active else Color("4a5a64"),
					7,
					1,
				),
			)
			_stage_host.add_child(card)
			var margin := _panel_margin(card, 7)
			var text := "%s\n%s" % [
				String(stage.get("label", "STAGE")).to_upper(),
				String(stage.get("status_label", "HELD")),
			]
			var detail := String(stage.get("detail", "")).strip_edges()
			if not detail.is_empty():
				text += "\n%s" % detail
			if bool(stage.get("has_cost", false)):
				text += "\n%s" % _money(int(stage.get("cost_cents", 0)))
			var label := _wrap_label(text, 9, COLOR_INK)
			margin.add_child(label)
	var benefit_lines := _model.operational_benefits()
	var summary := _model.project_summary()
	var copy_parts: Array[String] = []
	if not summary.is_empty():
		copy_parts.append(summary)
	if not benefit_lines.is_empty():
		copy_parts.append(_lines_or(benefit_lines, ""))
	_benefit_summary.text = (
		"\n".join(copy_parts)
		if not copy_parts.is_empty() else
		"No staged construction or operating effect is filed."
	)


func _refresh_pod_action() -> void:
	var pod := _model.routing_pod()
	var placed := bool(pod.get("placed", false))
	_place_button.visible = not placed
	_relocate_button.visible = placed
	var quote := (
		_model.relocation_quote(_selected_socket_id)
		if placed else
		_model.placement_quote(_selected_socket_id)
	)
	var can_authorize := bool(quote.get("can_authorize", false))
	var action_button := _relocate_button if placed else _place_button
	action_button.disabled = not can_authorize
	action_button.text = "%s / %s" % [
		"RELOCATE EGG ROUTING POD" if placed else "PLACE EGG ROUTING POD",
		_money(int(quote.get("cost_cents", 0))) if bool(quote.get("has_cost", false)) else "QUOTE HELD",
	]
	var reason := String(quote.get("reason", "")).strip_edges()
	if reason.is_empty() and can_authorize:
		reason = "Exact pod quote is ready for explicit authorization."
	elif reason.is_empty():
		reason = "This pod file is held by the selected route or dependency."
	action_button.tooltip_text = reason
	var selected_socket := _model.socket(_selected_socket_id)
	_selection_summary.text = "%s / %s\n%s" % [
		String(selected_socket.get("label", _selected_socket_id)).to_upper(),
		String(selected_socket.get("status_label", "HELD")),
		reason,
	]
	_selection_summary.add_theme_color_override("font_color", COLOR_TEAL if can_authorize else COLOR_RUST)


func _apply_responsive_layout() -> void:
	if _body_scroll == null:
		return
	var compact := size.x <= COMPACT_BREAKPOINT
	var target: Container = _compact_body if compact else _desktop_body
	_layout_mode = &"compact" if compact else &"desktop"
	if _active_body != target:
		if _site_panel.get_parent() != null:
			_site_panel.get_parent().remove_child(_site_panel)
		if _project_panel.get_parent() != null:
			_project_panel.get_parent().remove_child(_project_panel)
		if _active_body != null and _active_body.get_parent() == _body_scroll:
			_body_scroll.remove_child(_active_body)
		_active_body = target
		_body_scroll.add_child(_active_body)
		_active_body.add_child(_site_panel)
		_active_body.add_child(_project_panel)
	if compact:
		_site_panel.custom_minimum_size = Vector2(0.0, 470.0)
		_project_panel.custom_minimum_size = Vector2(0.0, 470.0)
		_header_status.custom_minimum_size.x = 230.0
	else:
		_site_panel.custom_minimum_size = Vector2(440.0, 470.0)
		_project_panel.custom_minimum_size = Vector2(390.0, 470.0)
		_header_status.custom_minimum_size.x = 340.0


func _on_purchase_parcel_pressed() -> void:
	var parcel := _model.parcel()
	if not bool(parcel.get("owned", false)) and bool(parcel.get("can_purchase", false)) and bool(parcel.get("has_purchase_cost", false)):
		purchase_parcel_requested.emit(CampusExpansionModel.PARCEL_ID)


func _on_connect_service_pressed(service_id: StringName) -> void:
	var service := _model.service(service_id)
	if not bool(service.get("connected", false)) and bool(service.get("can_connect", false)) and bool(service.get("has_purchase_cost", false)):
		connect_service_requested.emit(service_id)


func _on_place_pod_pressed() -> void:
	var quote := _model.placement_quote(_selected_socket_id)
	if bool(quote.get("can_authorize", false)):
		place_pod_requested.emit(_selected_socket_id)


func _on_relocate_pod_pressed() -> void:
	var quote := _model.relocation_quote(_selected_socket_id)
	if not bool(quote.get("can_authorize", false)):
		return
	var pod := _model.routing_pod()
	relocate_pod_requested.emit(
		StringName(String(pod.get("current_socket_id", ""))),
		_selected_socket_id,
	)


func _on_socket_pressed(socket_id: StringName) -> void:
	select_socket(socket_id)


func _on_socket_gui_input(event: InputEvent, socket_id: StringName) -> void:
	if not event.is_pressed() or _is_repeated_key_event(event):
		return
	var step := 0
	if event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"ui_up"):
		step = -1
	elif event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"ui_down"):
		step = 1
	if step == 0:
		return
	var current_index := CampusExpansionModel.SOCKET_ORDER.find(socket_id)
	if current_index < 0:
		return
	var next_id := CampusExpansionModel.SOCKET_ORDER[posmod(
		current_index + step,
		CampusExpansionModel.SOCKET_ORDER.size(),
	)]
	get_viewport().set_input_as_handled()
	select_socket(next_id)
	var next_button := _socket_buttons.get(next_id) as Button
	if next_button != null:
		next_button.grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or _is_repeated_key_event(event):
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close_requested.emit()


func _focus_selected_socket() -> void:
	var button := _socket_buttons.get(_selected_socket_id) as Button
	if button != null and button.is_visible_in_tree():
		button.grab_focus()


func _panel_margin(parent: Control, amount: int = 9) -> MarginContainer:
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


func _lines_or(value: Variant, fallback: String) -> String:
	var lines: Array[String] = []
	if value is Array:
		for line_value: Variant in value as Array:
			var line := String(line_value).strip_edges()
			if not line.is_empty():
				lines.append("- %s" % line)
	elif value is String or value is StringName:
		var line := String(value).strip_edges()
		if not line.is_empty():
			lines.append("- %s" % line)
	return "\n".join(lines) if not lines.is_empty() else fallback


func _money(cents: int) -> String:
	return "$%.2f" % (float(cents) / 100.0)


func _is_repeated_key_event(event: InputEvent) -> bool:
	return event is InputEventKey and (event as InputEventKey).echo
