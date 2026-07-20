class_name PeckworkRoutingUI
extends Control

const SemanticColorPaletteScript := preload("res://core/settings/semantic_color_palette.gd")

## Compact management surface for typed peckwork queues.
##
## The queue strip stays readable in the office overview. Selecting a hen opens
## the lower routing dossier, turning camera inspection into an authoritative
## staffing action without covering the character or the workstations.

signal assignment_requested(worker_id: int, lane: StringName)
signal personnel_action_requested(worker_id: int, action_id: StringName)
signal peck_assist_requested(worker_id: int)
signal first_clutch_skip_requested
signal first_clutch_focus_requested(worker_id: int)
signal first_clutch_skip_rect_settled(rect: Rect2)

const LANE_ORDER: Array[StringName] = [
	&"nest_damage",
	&"predator_loss",
	&"appeals",
]
const ASSIGNMENT_ORDER: Array[StringName] = [
	&"auto",
	&"nest_damage",
	&"predator_loss",
	&"appeals",
]
const LANE_NAMES := {
	&"auto": "AUTO SORT",
	&"nest_damage": "NEST DAMAGE",
	&"predator_loss": "PREDATOR LOSS",
	&"appeals": "APPEALS",
}
const LANE_SHORT_NAMES := {
	&"nest_damage": "NEST",
	&"predator_loss": "PREDATOR",
	&"appeals": "APPEALS",
}
const PERSONNEL_ACTION_ORDER: Array[StringName] = [
	&"share_credit",
	&"career_coaching",
	&"quota_pressure",
]
const PERSONNEL_ACTION_NAMES := {
	&"share_credit": "SHARE CREDIT",
	&"career_coaching": "CAREER COACH",
	&"quota_pressure": "QUOTA PRESSURE",
}
const PERSONNEL_ACTION_TOOLTIPS := {
	&"share_credit": "Publicly recognize this hen's work. Builds trust and eases grievances.",
	&"career_coaching": "Invest in this hen's career development. Builds experience with a modest short-term strain.",
	&"quota_pressure": "Demand more output from this hen at a personal cost.",
}

var _queue_labels: Dictionary[StringName, Label] = {}
var _queue_title_label: Label
var _queue_contract_badge: Label
var _queue_compact_label: Label
var _assignment_buttons: Dictionary[StringName, Button] = {}
var _personnel_buttons: Dictionary[StringName, Button] = {}
var _queue_panel: PanelContainer
var _first_clutch_panel: PanelContainer
var _first_clutch_progress_label: Label
var _first_clutch_title_label: Label
var _first_clutch_body_label: Label
var _first_clutch_return_button: Button
var _first_clutch_skip_button: Button
var _focus_panel: PanelContainer
var _worker_name_label: Label
var _worker_career_label: Label
var _worker_trait_label: Label
var _details_button: Button
var _dossier_tabs: HBoxContainer
var _dossier_tab_buttons: Dictionary[StringName, Button] = {}
var _active_dossier_tab: StringName = &"route"
var _current_claim_label: Label
var _current_contract_badge: Label
var _claim_detail_label: Label
var _claim_progress_bar: ProgressBar
var _dossier_summary_label: Label
var _routing_hint_label: Label
var _peck_assist_button: Button
var _trust_label: Label
var _grievance_label: Label
var _check_in_status_label: Label
var _claim_header: HBoxContainer
var _assist_row: HBoxContainer
var _personnel_status: HBoxContainer
var _assignment_section: GridContainer
var _personnel_actions_section: VBoxContainer
var _focused_worker_id := -1
var _snapshot: Dictionary = {}
var _interaction_enabled := true
var _peck_assist_clock_running := true
var _peck_assist_binding_label := "E / A"
var _reduced_motion := false
var _color_vision_mode: StringName = &"standard"
var _assist_pulse_phase := 0.0
var _first_clutch: Dictionary = {}
var _first_clutch_cued_control: Control
var _first_clutch_layout_width := -1.0
var _first_clutch_compact := false
var _last_first_clutch_skip_rect := Rect2()
var _details_expanded := false
var _top_inset := 120.0


func _ready() -> void:
	name = "PeckworkRoutingUI"
	# Management pauses the simulation tree while this presentation remains
	# interactive. Keep only this UI process alive so its visual cue and settled
	# accessibility target do not freeze with the authoritative clock.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_queue_strip()
	_build_first_clutch_coach()
	_build_focus_dossier()
	resized.connect(_apply_first_clutch_layout)
	_apply_first_clutch_layout()
	_refresh()
	set_process(true)


func _process(delta: float) -> void:
	var viewport_width := get_viewport_rect().size.x
	if not is_equal_approx(viewport_width, _first_clutch_layout_width):
		_apply_first_clutch_layout()
	var skip_rect := first_clutch_skip_button_rect()
	if not skip_rect.is_equal_approx(_last_first_clutch_skip_rect):
		_last_first_clutch_skip_rect = skip_rect
		if skip_rect.has_area():
			first_clutch_skip_rect_settled.emit(skip_rect)
	var peck_visible := _peck_assist_button != null and _peck_assist_button.visible
	var cue_visible := (
		_first_clutch_cued_control != null
		and is_instance_valid(_first_clutch_cued_control)
		and _first_clutch_cued_control.is_visible_in_tree()
	)
	if not peck_visible and not cue_visible:
		return
	if _reduced_motion:
		if peck_visible:
			_peck_assist_button.modulate = Color.WHITE
		if cue_visible:
			_first_clutch_cued_control.self_modulate = Color.WHITE
		return
	_assist_pulse_phase = fmod(_assist_pulse_phase + delta, TAU)
	if peck_visible:
		var assist_open := bool(_peck_assist_button.get_meta("assist_open", false))
		_peck_assist_button.modulate = (
			Color(1.0, 1.0, 1.0, 0.92 + sin(_assist_pulse_phase * 4.2) * 0.08)
			if assist_open else Color.WHITE
		)
	if cue_visible:
		var cue_lift := 0.94 + (sin(_assist_pulse_phase * 3.6) + 1.0) * 0.03
		_first_clutch_cued_control.self_modulate = Color(cue_lift, cue_lift, cue_lift, 1.0)


func set_focus(worker_id: int) -> void:
	if worker_id != _focused_worker_id:
		_details_expanded = not bool(_first_clutch.get("visible", false))
		_active_dossier_tab = &"route"
	_focused_worker_id = worker_id
	_refresh()


func clear_focus() -> void:
	set_focus(-1)


func apply_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_refresh()


## Applies presentation-only state for the optional first-shift coach.
##
## Expected fields are `visible`, `progress`, `total`, `title`, and `body`.
## `cue` may be `route`, `check_in`, or `priority_peck`; route cues read
## `lane`, check-in cues read `action_id`, and `worker_id` optionally limits a
## cue to that hen's open dossier. A bound worker mismatch exposes a recovery
## intent, while `resume_required` suppresses the disabled Priority Peck cue.
## This component never advances coach state or changes camera focus directly.
func apply_first_clutch(coach: Dictionary) -> void:
	var previous_stage := _first_clutch_disclosure_stage()
	var was_active := bool(_first_clutch.get("visible", false))
	_first_clutch = coach.duplicate(true)
	var is_active := bool(_first_clutch.get("visible", false))
	if previous_stage != _first_clutch_disclosure_stage() or was_active != is_active:
		_details_expanded = not is_active
	_refresh_first_clutch()


## Sets the presentation stage without transferring ownership of tutorial state.
##
## Office remains authoritative over progress and completion. This convenience
## API accepts the same payload as `apply_first_clutch`, stamps both compatible
## stage keys, and defaults known induction stages to visible. Passing `normal`,
## `dismissed`, or an empty stage reveals the complete management surface.
func set_first_clutch_stage(stage: StringName, state: Dictionary = {}) -> void:
	var coach := state.duplicate(true)
	coach["stage"] = stage
	coach["step"] = stage
	if stage in [&"", &"normal", &"dismissed", &"off"]:
		coach["visible"] = false
	elif not coach.has("visible"):
		coach["visible"] = true
	apply_first_clutch(coach)


func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled
	_refresh()


func set_peck_assist_clock_running(running: bool) -> void:
	_peck_assist_clock_running = running
	_refresh()


func set_peck_assist_binding_label(binding_label: String) -> void:
	_peck_assist_binding_label = binding_label if not binding_label.is_empty() else "E / A"
	_refresh()


func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled


func set_color_vision_mode(mode: StringName) -> void:
	_color_vision_mode = SemanticColorPaletteScript.normalize_mode(mode)
	for lane in _assignment_buttons:
		var button := _assignment_buttons[lane] as Button
		if button != null:
			button.text = _lane_name(StringName(lane))
	if _queue_panel != null:
		_refresh()


func color_vision_mode() -> StringName:
	return _color_vision_mode


func focused_worker_id() -> int:
	return _focused_worker_id


func first_clutch_stage() -> StringName:
	return _first_clutch_disclosure_stage()


## Read-only presentation metadata for integration and accessibility tests.
## Section flags describe this component's intended disclosure even when Office
## temporarily hides the whole routing layer behind a blocking surface.
func first_clutch_presentation_state() -> Dictionary:
	var primary_action := ""
	if _first_clutch_cued_control != null and is_instance_valid(_first_clutch_cued_control):
		primary_action = _first_clutch_cued_control.name
	return {
		"active": bool(_first_clutch.get("visible", false)),
		"stage": String(first_clutch_stage()),
		"target_worker_id": _first_clutch_target_worker_id(),
		"focused_worker_id": _focused_worker_id,
		"target_matches": _first_clutch_has_contextual_dossier(),
		"compact_coach": _first_clutch_compact,
		"details_expanded": _details_expanded,
		"active_dossier_tab": String(_active_dossier_tab),
		"dossier_tabs_visible": _dossier_tabs != null and _dossier_tabs.visible,
		"component_visible_in_tree": is_visible_in_tree(),
		"queue_visible": is_dossier_section_visible(&"queue"),
		"claim_visible": is_dossier_section_visible(&"claim"),
		"routing_visible": is_dossier_section_visible(&"routing"),
		"check_in_visible": is_dossier_section_visible(&"check_in"),
		"priority_peck_visible": is_dossier_section_visible(&"priority_peck"),
		"details_visible": _details_button != null and _details_button.visible,
		"primary_action_node": primary_action,
	}


func is_dossier_section_visible(section: StringName) -> bool:
	match section:
		&"queue":
			return _queue_panel != null and _queue_panel.visible
		&"claim", &"active_claim":
			return _claim_header != null and _claim_header.visible
		&"routing", &"assignments":
			return _assignment_section != null and _assignment_section.visible
		&"check_in", &"personnel":
			return _personnel_actions_section != null and _personnel_actions_section.visible
		&"priority_peck", &"peck_assist":
			return _peck_assist_button != null and _peck_assist_button.visible
		&"details":
			return _details_button != null and _details_button.visible
	return false


## Lets Office reclaim the duplicated objective row during guided onboarding
## without changing any routing content or action. Normal play restores 120px.
func set_top_inset(inset: float) -> void:
	var sanitized := maxf(0.0, inset)
	if is_equal_approx(_top_inset, sanitized):
		return
	_top_inset = sanitized
	_apply_first_clutch_layout()


func top_inset() -> float:
	return _top_inset


func _build_queue_strip() -> void:
	_queue_panel = PanelContainer.new()
	_queue_panel.name = "PeckworkQueueStrip"
	_queue_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_queue_panel.offset_left = 18.0
	_queue_panel.offset_top = 120.0
	_queue_panel.offset_right = 650.0
	_queue_panel.offset_bottom = 158.0
	_queue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_queue_panel.add_theme_stylebox_override("panel", _panel_style(Color("16242d"), 0.96, Color("52646d"), 7, 1))
	add_child(_queue_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	_queue_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	margin.add_child(row)
	var queue_heading := VBoxContainer.new()
	queue_heading.name = "RoutingQueueHeading"
	queue_heading.custom_minimum_size.x = 124.0
	queue_heading.add_theme_constant_override("separation", 0)
	row.add_child(queue_heading)
	_queue_title_label = _make_label("PECKWORK ROUTING", 12, Color("e7c56e"))
	_queue_title_label.name = "RoutingQueueTitle"
	queue_heading.add_child(_queue_title_label)
	_queue_contract_badge = _make_contract_badge("RoutingQueueContractBadge", 124.0)
	queue_heading.add_child(_queue_contract_badge)
	_queue_compact_label = _make_label("FILES  0  /  OVERDUE  0", 12, Color("c7d3d7"))
	_queue_compact_label.name = "RoutingQueueCompactSummary"
	_queue_compact_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_queue_compact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_queue_compact_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_queue_compact_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_queue_compact_label.visible = false
	row.add_child(_queue_compact_label)
	for lane in LANE_ORDER:
		var label := _make_label("%s  0" % _lane_short_name(lane), 12, _lane_color(lane))
		label.name = "Queue_%s" % String(lane)
		label.custom_minimum_size.x = 96.0 if lane == &"predator_loss" else 86.0
		row.add_child(label)
		_queue_labels[lane] = label
	var debt := _make_label("OVERDUE  0", 12, _lane_color(&"overdue"))
	debt.name = "QueueOverdue"
	debt.custom_minimum_size.x = 86.0
	row.add_child(debt)
	_queue_labels[&"overdue"] = debt


func _build_first_clutch_coach() -> void:
	_first_clutch_panel = PanelContainer.new()
	_first_clutch_panel.name = "FirstClutchCoach"
	_first_clutch_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_first_clutch_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_first_clutch_panel.z_index = 4
	_first_clutch_panel.visible = false
	_first_clutch_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("172832"), 0.985, Color("c7a352"), 8, 1),
	)
	add_child(_first_clutch_panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_first_clutch_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 9)
	margin.add_child(row)

	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	row.add_child(copy)

	_first_clutch_progress_label = _make_label("FIRST CLUTCH  0 / 5", 10, Color("d8b967"))
	_first_clutch_progress_label.name = "FirstClutchProgress"
	_first_clutch_progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_first_clutch_progress_label)

	_first_clutch_title_label = _make_label("INSPECT A HEN", 14, Color("f6e5b5"))
	_first_clutch_title_label.name = "FirstClutchActionTitle"
	_first_clutch_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_first_clutch_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(_first_clutch_title_label)

	_first_clutch_body_label = _make_label("Click a hen or press Tab to open her work file.", 11, Color("b8c7ce"))
	_first_clutch_body_label.name = "FirstClutchActionBody"
	_first_clutch_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_first_clutch_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_first_clutch_body_label.max_lines_visible = 2
	_first_clutch_body_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(_first_clutch_body_label)

	_first_clutch_return_button = Button.new()
	_first_clutch_return_button.name = "FirstClutchReturnToHen"
	_first_clutch_return_button.text = "RETURN TO HEN"
	_first_clutch_return_button.tooltip_text = "Return to the coached hen's work file."
	_first_clutch_return_button.custom_minimum_size = Vector2(108.0, 30.0)
	_first_clutch_return_button.add_theme_font_size_override("font_size", 10)
	_first_clutch_return_button.clip_text = true
	_first_clutch_return_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_first_clutch_return_button.visible = false
	_first_clutch_return_button.pressed.connect(_on_first_clutch_return_pressed)
	row.add_child(_first_clutch_return_button)

	_first_clutch_skip_button = Button.new()
	_first_clutch_skip_button.name = "FirstClutchSkip"
	_first_clutch_skip_button.text = "SKIP"
	_first_clutch_skip_button.tooltip_text = "Retire the optional first-clutch coach."
	_first_clutch_skip_button.custom_minimum_size = Vector2(58.0, 30.0)
	_first_clutch_skip_button.add_theme_font_size_override("font_size", 10)
	_first_clutch_skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_first_clutch_skip_button.pressed.connect(_on_first_clutch_skip_pressed)
	row.add_child(_first_clutch_skip_button)


func _apply_first_clutch_layout() -> void:
	if _first_clutch_panel == null:
		return
	var viewport_width := get_viewport_rect().size.x
	_first_clutch_layout_width = viewport_width
	var available_width := minf(size.x, viewport_width) if size.x > 0.0 else viewport_width
	var narrow := available_width > 0.0 and available_width < 720.0
	if _queue_panel != null:
		_queue_panel.offset_left = 12.0 if narrow else 18.0
		_queue_panel.offset_top = _top_inset
		_queue_panel.offset_right = maxf(12.0, available_width - 12.0) if narrow else 650.0
		_queue_panel.offset_bottom = _top_inset + 38.0
		if _queue_compact_label != null:
			_queue_compact_label.visible = narrow
		for lane in LANE_ORDER:
			var queue_label := _queue_labels.get(lane) as Label
			if queue_label != null:
				queue_label.visible = not narrow
		var overdue_label := _queue_labels.get(&"overdue") as Label
		if overdue_label != null:
			overdue_label.visible = not narrow
	if narrow:
		_first_clutch_panel.set_anchor(SIDE_LEFT, 0.0)
		_first_clutch_panel.set_anchor(SIDE_RIGHT, 0.0)
		_first_clutch_panel.offset_left = 12.0
		_first_clutch_panel.offset_top = _top_inset + 52.0
		_first_clutch_panel.offset_right = maxf(12.0, available_width - 12.0)
		_first_clutch_panel.offset_bottom = (
			_top_inset + (110.0 if _first_clutch_compact else 156.0)
		)
	else:
		_first_clutch_panel.set_anchor(SIDE_LEFT, 0.0)
		_first_clutch_panel.set_anchor(SIDE_RIGHT, 0.0)
		_first_clutch_panel.offset_left = 18.0
		_first_clutch_panel.offset_top = _top_inset + 52.0
		_first_clutch_panel.offset_right = 598.0
		_first_clutch_panel.offset_bottom = (
			_top_inset + (110.0 if _first_clutch_compact else 130.0)
		)


func _build_focus_dossier() -> void:
	_focus_panel = PanelContainer.new()
	_focus_panel.name = "PeckworkAssignmentDossier"
	_focus_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_focus_panel.offset_left = 18.0
	_focus_panel.offset_top = -194.0
	_focus_panel.offset_right = -18.0
	_focus_panel.offset_bottom = -62.0
	_focus_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_focus_panel.add_theme_stylebox_override("panel", _panel_style(Color("172832"), 0.985, Color("bf9851"), 9, 2))
	add_child(_focus_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 11)
	margin.add_theme_constant_override("margin_bottom", 11)
	_focus_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)

	var identity := VBoxContainer.new()
	identity.custom_minimum_size.x = 205.0
	identity.add_theme_constant_override("separation", 2)
	row.add_child(identity)
	identity.add_child(_make_label("SELECTED HEN", 11, Color("d8b967")))
	_worker_name_label = _make_label("MABEL", 21, Color("f6e5b5"))
	_worker_name_label.name = "RoutingWorkerName"
	identity.add_child(_worker_name_label)
	_worker_career_label = _make_label("PECKWORK ASSOCIATE  /  XP 0", 11, Color("d7c17d"))
	_worker_career_label.name = "RoutingWorkerCareer"
	_worker_career_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	identity.add_child(_worker_career_label)
	_worker_trait_label = _make_label("SPECIALTY  /  NEST DAMAGE", 11, Color("aebdc5"))
	_worker_trait_label.name = "RoutingWorkerSpecialty"
	identity.add_child(_worker_trait_label)
	_dossier_tabs = HBoxContainer.new()
	_dossier_tabs.name = "RoutingDossierTabs"
	_dossier_tabs.add_theme_constant_override("separation", 3)
	identity.add_child(_dossier_tabs)
	for tab_id: StringName in [&"route", &"support", &"profile"]:
		var tab := Button.new()
		tab.name = "DossierTab_%s" % String(tab_id)
		tab.text = String(tab_id).to_upper()
		tab.toggle_mode = true
		tab.custom_minimum_size = Vector2(62.0, 24.0)
		tab.add_theme_font_size_override("font_size", 9)
		tab.tooltip_text = {
			&"route": "Current file, tray routing, and Priority Peck.",
			&"support": "Recognition, coaching, pressure, and check-in status.",
			&"profile": "Career, specialties, trust, grievance, and care details.",
		}[tab_id]
		tab.pressed.connect(_on_dossier_tab_pressed.bind(tab_id))
		_dossier_tabs.add_child(tab)
		_dossier_tab_buttons[tab_id] = tab
	_details_button = Button.new()
	_details_button.name = "RoutingDetailsToggle"
	_details_button.text = "DETAILS"
	_details_button.tooltip_text = "Show career, trust, grievance, and care details for this hen."
	_details_button.custom_minimum_size = Vector2(98.0, 24.0)
	_details_button.add_theme_font_size_override("font_size", 10)
	_details_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_details_button.pressed.connect(_on_details_pressed)
	identity.add_child(_details_button)

	var active_file := VBoxContainer.new()
	active_file.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	active_file.add_theme_constant_override("separation", 3)
	row.add_child(active_file)
	_claim_header = HBoxContainer.new()
	_claim_header.name = "RoutingClaimHeader"
	_claim_header.add_theme_constant_override("separation", 8)
	active_file.add_child(_claim_header)
	_current_claim_label = _make_label("WAITING FOR PECKWORK", 16, Color("eef2e9"))
	_current_claim_label.name = "RoutingCurrentClaim"
	_current_claim_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_current_claim_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_claim_header.add_child(_current_claim_label)
	_current_contract_badge = _make_contract_badge("RoutingCurrentContractBadge", 154.0)
	_claim_header.add_child(_current_contract_badge)
	_claim_detail_label = _make_label("Auto-sort will favor specialty and deadline.", 12, Color("aebdc5"))
	_claim_detail_label.name = "RoutingClaimDetail"
	_claim_detail_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	active_file.add_child(_claim_detail_label)
	_claim_progress_bar = ProgressBar.new()
	_claim_progress_bar.name = "RoutingClaimProgress"
	_claim_progress_bar.custom_minimum_size.y = 9.0
	_claim_progress_bar.min_value = 0.0
	_claim_progress_bar.max_value = 100.0
	_claim_progress_bar.show_percentage = false
	_claim_progress_bar.add_theme_stylebox_override("background", _compact_button_style(Color("101a21"), Color("3e5059"), 1))
	_claim_progress_bar.add_theme_stylebox_override("fill", _compact_button_style(Color("5aa897"), Color("8dcfbd"), 0))
	active_file.add_child(_claim_progress_bar)
	_dossier_summary_label = _make_label("", 11, Color("c7d3d7"))
	_dossier_summary_label.name = "RoutingDossierSummary"
	_dossier_summary_label.custom_minimum_size.y = 54.0
	_dossier_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dossier_summary_label.max_lines_visible = 3
	_dossier_summary_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	active_file.add_child(_dossier_summary_label)
	_assist_row = HBoxContainer.new()
	_assist_row.name = "RoutingAssistRow"
	_assist_row.add_theme_constant_override("separation", 9)
	active_file.add_child(_assist_row)
	_routing_hint_label = _make_label("Choose which tray this hen pulls next.", 11, Color("d7c17d"))
	_routing_hint_label.name = "RoutingAutomationHint"
	_routing_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_routing_hint_label.custom_minimum_size.y = 30.0
	_routing_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_routing_hint_label.max_lines_visible = 2
	_routing_hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_assist_row.add_child(_routing_hint_label)
	_peck_assist_button = Button.new()
	_peck_assist_button.name = "PeckAssistButton"
	_peck_assist_button.text = "NO ACTIVE FILE"
	_peck_assist_button.custom_minimum_size = Vector2(166.0, 30.0)
	_peck_assist_button.add_theme_font_size_override("font_size", 11)
	_apply_peck_assist_style(_peck_assist_button)
	_peck_assist_button.pressed.connect(_on_peck_assist_pressed)
	_assist_row.add_child(_peck_assist_button)
	_personnel_status = HBoxContainer.new()
	_personnel_status.name = "RoutingPersonnelStatus"
	_personnel_status.add_theme_constant_override("separation", 13)
	active_file.add_child(_personnel_status)
	_trust_label = _make_label("TRUST  50", 11, Color("73b5a7"))
	_trust_label.name = "RoutingManagerTrust"
	_personnel_status.add_child(_trust_label)
	_grievance_label = _make_label("GRIEVANCE  0", 11, Color("d68a68"))
	_grievance_label.name = "RoutingGrievance"
	_personnel_status.add_child(_grievance_label)
	_check_in_status_label = _make_label("CHECK-IN READY", 11, Color("e7c56e"))
	_check_in_status_label.name = "RoutingCheckInStatus"
	_check_in_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_check_in_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_check_in_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_personnel_status.add_child(_check_in_status_label)

	_assignment_section = GridContainer.new()
	_assignment_section.name = "RoutingAssignments"
	_assignment_section.columns = 2
	_assignment_section.add_theme_constant_override("h_separation", 7)
	_assignment_section.add_theme_constant_override("v_separation", 7)
	row.add_child(_assignment_section)
	for assignment in ASSIGNMENT_ORDER:
		var button := Button.new()
		button.name = "Assign_%s" % String(assignment)
		button.text = _lane_name(assignment)
		button.custom_minimum_size = Vector2(142.0, 34.0)
		button.theme_type_variation = &"DecisionChoiceButton"
		button.tooltip_text = _assignment_tooltip(assignment)
		button.pressed.connect(_on_assignment_pressed.bind(assignment))
		_assignment_section.add_child(button)
		_assignment_buttons[assignment] = button

	_personnel_actions_section = VBoxContainer.new()
	_personnel_actions_section.name = "PersonnelActions"
	_personnel_actions_section.custom_minimum_size.x = 142.0
	_personnel_actions_section.add_theme_constant_override("separation", 4)
	row.add_child(_personnel_actions_section)
	for action_id in PERSONNEL_ACTION_ORDER:
		var button := Button.new()
		button.name = "PersonnelAction_%s" % String(action_id)
		button.text = String(PERSONNEL_ACTION_NAMES[action_id])
		button.custom_minimum_size = Vector2(142.0, 26.0)
		button.add_theme_font_size_override("font_size", 11)
		_apply_compact_personnel_style(button, action_id)
		button.tooltip_text = String(PERSONNEL_ACTION_TOOLTIPS[action_id])
		button.pressed.connect(_on_personnel_action_pressed.bind(action_id))
		_personnel_actions_section.add_child(button)
		_personnel_buttons[action_id] = button


func _on_dossier_tab_pressed(tab_id: StringName) -> void:
	if tab_id not in [&"route", &"support", &"profile"]:
		return
	_active_dossier_tab = tab_id
	_refresh()
	var first_focus: Control
	match tab_id:
		&"route":
			first_focus = _assignment_buttons.get(&"auto") as Control
		&"support":
			first_focus = _personnel_buttons.get(&"share_credit") as Control
		&"profile":
			first_focus = _dossier_tab_buttons.get(&"profile") as Control
	if first_focus != null and first_focus.is_visible_in_tree():
		first_focus.call_deferred("grab_focus")


func active_dossier_tab() -> StringName:
	return _active_dossier_tab


func _refresh() -> void:
	if _queue_panel == null or _focus_panel == null:
		return
	var routing: Dictionary = _snapshot.get("routing", {}) as Dictionary
	var queue_counts: Dictionary = routing.get("queue_counts", _snapshot.get("claim_queue_counts", {})) as Dictionary
	var overdue_counts: Dictionary = routing.get("overdue_by_lane", _snapshot.get("claim_queue_overdue_counts", {})) as Dictionary
	var queue_total := 0
	for lane in LANE_ORDER:
		var count := int(queue_counts.get(lane, queue_counts.get(String(lane), 0)))
		queue_total += count
		var lane_overdue := int(overdue_counts.get(lane, overdue_counts.get(String(lane), 0)))
		var suffix := "  !%d" % lane_overdue if lane_overdue > 0 else ""
		_queue_labels[lane].text = "%s  %d%s" % [_lane_short_name(lane), count, suffix]
		_queue_labels[lane].add_theme_color_override("font_color", _lane_color(lane))
	var overdue := int(routing.get("overdue_total", _snapshot.get("overdue_claims", 0)))
	_queue_labels[&"overdue"].text = "OVERDUE  %d" % overdue
	_queue_labels[&"overdue"].modulate = Color.WHITE if overdue > 0 else Color(1.0, 1.0, 1.0, 0.62)
	_queue_compact_label.text = "FILES  %d  /  OVERDUE  %d" % [queue_total, overdue]
	_queue_compact_label.add_theme_color_override(
		"font_color",
		_lane_color(&"overdue") if overdue > 0 else Color("c7d3d7"),
	)
	_queue_panel.tooltip_text = (
		"PECKWORK ROUTING\nNest %d  /  Predator %d  /  Appeals %d  /  Overdue %d"
		% [
			int(queue_counts.get(&"nest_damage", queue_counts.get("nest_damage", 0))),
			int(queue_counts.get(&"predator_loss", queue_counts.get("predator_loss", 0))),
			int(queue_counts.get(&"appeals", queue_counts.get("appeals", 0))),
			overdue,
		]
	)
	_refresh_queue_contract_badge(routing)

	var worker := _worker_snapshot(_focused_worker_id)
	_focus_panel.visible = _focused_worker_id >= 0 and not worker.is_empty()
	if not _focus_panel.visible:
		_refresh_first_clutch()
		return

	var worker_name := String(worker.get("name", "HEN %d" % (_focused_worker_id + 1)))
	var specialty := StringName(worker.get("specialty", &"nest_damage"))
	var secondary_specialty := StringName(String(worker.get(
		"secondary_specialty",
		worker.get("secondary_lane", ""),
	)))
	var training_specialty := StringName(String(worker.get(
		"training_specialty",
		worker.get(
			"cross_training_target",
			worker.get("pending_training_lane", worker.get("training_lane", "")),
		),
	)))
	var assignment := StringName(worker.get("assignment", worker.get("assigned_lane", &"auto")))
	_worker_name_label.text = worker_name.to_upper()
	var career_title := String(worker.get("career_title", "PECKWORK ASSOCIATE"))
	var career_xp := maxi(0, int(worker.get("career_xp", 0)))
	var next_xp := int(worker.get("career_xp_next", worker.get("career_xp_to_next", 0)))
	var career_profile_name := String(worker.get("career_profile_name", "UNFILED PROFILE"))
	var career_profile_description := String(worker.get("career_profile_description", ""))
	var preferred_action := StringName(worker.get("preferred_personnel_action", &""))
	_worker_career_label.text = (
		"%s  /  XP %d / %d" % [career_title.to_upper(), career_xp, next_xp]
		if next_xp > career_xp else
		"%s  /  XP %d" % [career_title.to_upper(), career_xp]
	)
	var credential_text := _lane_name(specialty)
	if secondary_specialty != &"":
		credential_text += " + %s" % _lane_name(secondary_specialty)
	_worker_trait_label.text = "%s  /  %s" % [career_profile_name, credential_text]
	_worker_trait_label.tooltip_text = "%s Primary specialty: %s." % [career_profile_description, _lane_name(specialty)]
	if secondary_specialty != &"":
		_worker_trait_label.tooltip_text += "\nSECONDARY ACCREDITATION: %s receives the same specialist speed and shell-risk treatment when routed manually." % _lane_name(secondary_specialty)
	if training_specialty != &"":
		var training_terms := _training_terms_snapshot()
		var work_multiplier := float(worker.get(
			"cross_training_work_multiplier",
			training_terms.get("effective_work_multiplier", training_terms.get("pending_work_multiplier", 0.85)),
		))
		var work_penalty := maxf(0.0, snappedf((1.0 - work_multiplier) * 100.0, 0.1))
		var coaching_xp_bonus := maxi(0, int(training_terms.get("coaching_xp_bonus", 0)))
		var wage_bonus_cents := maxi(0, int(training_terms.get("wage_bonus_cents", 100)))
		_worker_trait_label.text += "  /  TRAINING: %s" % _lane_name(training_specialty)
		_worker_trait_label.tooltip_text += (
			"\nIN TRAINING: this worked shift keeps full throughput. %s accreditation files after close with +$%.2f/day wage."
			if work_penalty <= 0.05 else
			"\nIN TRAINING: this worked shift is %s%% slower. %s accreditation files after close with +$%.2f/day wage."
		) % (
			[
				_lane_name(training_specialty),
				float(wage_bonus_cents) / 100.0,
			]
			if work_penalty <= 0.05 else
			[
				_compact_number(work_penalty),
				_lane_name(training_specialty),
				float(wage_bonus_cents) / 100.0,
			]
		)
		if coaching_xp_bonus > 0:
			_worker_trait_label.tooltip_text += " Training Roost coaching adds +%d career XP per check-in." % coaching_xp_bonus
	var worker_state_label := String(worker.get("state_label", "")).to_upper()
	if worker_state_label == "WELLNESS":
		_worker_trait_label.text += "  /  WELLNESS NEST"
	_worker_trait_label.tooltip_text += "\nFLOCK CARE: morale %d / stress %d / fatigue %d%s." % [
		roundi(float(worker.get("morale", 0.0))),
		roundi(float(worker.get("stress", 0.0))),
		roundi(float(worker.get("fatigue", 0.0))),
		" / resting at a recovery perch" if worker_state_label == "WELLNESS" else "",
	]
	_worker_trait_label.add_theme_color_override("font_color", _lane_color(specialty))
	if training_specialty != &"":
		_worker_trait_label.add_theme_color_override("font_color", Color("efcf83"))
	elif bool(worker.get("is_compact_sponsor", false)):
		_worker_trait_label.text += "  /  COMPACT SPONSOR"
		_worker_trait_label.tooltip_text += "\nBINDING FLOCK COMPACT: %s" % String(worker.get(
			"compact_condition",
			"The closing ledger determines whether management kept its promise.",
		))
		_worker_trait_label.add_theme_color_override("font_color", Color("efcf83"))
	elif bool(worker.get("is_petition_sponsor", false)):
		_worker_trait_label.text += "  /  PETITION SPONSOR"
		_worker_trait_label.tooltip_text += "\nThis hen signed the current flock petition."
		_worker_trait_label.add_theme_color_override("font_color", Color("df9278"))

	var claim: Dictionary = worker.get("current_claim", {}) as Dictionary
	_refresh_contract_badge(_current_contract_badge, claim)
	if claim.is_empty():
		_current_claim_label.text = "1  ROUTE  /  WAITING FOR %s FILE" % (_lane_name(assignment) if assignment != &"auto" else "AUTO-SORTED")
		_claim_progress_bar.value = 0.0
		_claim_progress_bar.visible = false
		_claim_detail_label.text = "NEXT  /  hen sits, pecks the screen, then lays the completed egg"
	else:
		var lane := StringName(claim.get("lane", &"nest_damage"))
		var claim_id := int(claim.get("id", 0))
		var rework := bool(claim.get("rework", claim.get("is_rework", false)))
		var progress := int(worker.get("progress", 0))
		_claim_progress_bar.visible = true
		_claim_progress_bar.value = progress
		var loop_verb := "2  PECKING SCREEN"
		if worker_state_label == "LAYING":
			loop_verb = "3  LAYING DELIVERY"
		elif worker_state_label not in ["PECKING", "WORKING"]:
			loop_verb = worker_state_label
		_current_claim_label.text = "%s  /  %s #%04d%s  ·  %d%%" % [
			loop_verb, _lane_name(lane), claim_id, ("  /  REWORK" if rework else ""), progress,
		]
		var value_cents := int(claim.get("value_cents", 0))
		var remaining_minutes := int(claim.get("minutes_until_deadline", 0))
		var urgency := (
			"OVERDUE BY %dm" % absi(remaining_minutes)
			if bool(claim.get("overdue", false)) else
			"DUE IN %dm" % maxi(0, remaining_minutes)
		)
		var next_stage := "NEXT  /  grader stamps egg, farmer takes credit" if worker_state_label == "LAYING" else "NEXT  /  lay completed egg"
		_claim_detail_label.text = "%s  ·  $%.2f  ·  crack %d%%  ·  %s" % [
			urgency, value_cents / 100.0, int(float(worker.get("estimated_crack_risk", 0.0)) * 100.0), next_stage,
		]
	var assist := worker.get("peck_assist", {}) as Dictionary
	var assist_open := bool(assist.get("available", false)) and _interaction_enabled and _peck_assist_clock_running
	var assist_state := StringName(assist.get("window_state", &"locked"))
	var last_assist := _snapshot.get("last_peck_assist", {}) as Dictionary
	var last_assist_matches_claim := (
		int(last_assist.get("claim_id", -1)) == int(claim.get("id", -2))
	)
	# The same authoritative claim remains in the worker's hands during LAYING,
	# even though peck_assist_status correctly changes to WAITING. Preserve the
	# landed receipt through that visible result beat instead of reverting the
	# dossier to a generic locked label before the flourish can be read.
	if last_assist_matches_claim and assist_state in [&"waiting", &"used"]:
		assist_state = &"used"
	var assist_remaining := maxi(0, int(assist.get("remaining", _snapshot.get("peck_assists_remaining", 0))))
	var assist_pending := maxi(0, int(assist.get(
		"pending_delivery_count",
		_snapshot.get("peck_assist_pending_delivery_count", 0),
	)))
	_peck_assist_button.set_meta("assist_open", assist_open)
	_peck_assist_button.disabled = not assist_open
	_peck_assist_button.tooltip_text = "%s\n%s" % [
		(
			"Resume at 1×, 3×, or 10× before stamping the live rhythm."
			if not _peck_assist_clock_running and bool(assist.get("available", false)) else
			String(assist.get("reason", "Select a working hen to synchronize peckwork."))
		),
		"A strong stamp accelerates this file and lowers shell risk; every stamp adds strain. A sound or golden assisted egg restores one charge when the farmer receives it; a crack consumes the charge and breaks the chain. %d/%d attention charges remain." % [
			assist_remaining, int(assist.get("limit", _snapshot.get("peck_assist_limit", 3))),
		],
	]
	match assist_state:
		&"open":
			var timing_label := String(assist.get("timing_label", "CLEAN RHYTHM"))
			_peck_assist_button.text = "PECK  ·  %s  [%s]" % [
				"GOLDEN" if "GOLDEN" in timing_label else "SYNC",
				_peck_assist_binding_label,
			]
			_claim_progress_bar.add_theme_stylebox_override("fill", _compact_button_style(Color("d5aa4f"), Color("f1d681"), 0))
		&"not_ready":
			_peck_assist_button.text = "READY AT %d%%" % int(assist.get("window_start", 28.0))
			_claim_progress_bar.add_theme_stylebox_override("fill", _compact_button_style(Color("4d8d83"), Color("75b6a9"), 0))
		&"used":
			if last_assist_matches_claim:
				var rating := String(last_assist.get("rating", "steady")).to_upper()
				var progress_gain := int(roundf(float(last_assist.get("progress_gain", 0.0))))
				var risk_points := float(last_assist.get("quality_modifier", 0.0)) * 100.0
				var risk_text := "%s%.1f%%" % [("+" if risk_points > 0.0 else ""), risk_points]
				_peck_assist_button.text = "%s  ·  +%d%%  ·  x%d" % [
					rating,
					progress_gain,
					int(last_assist.get("streak", 0)),
				]
				_peck_assist_button.tooltip_text = "%s Priority Peck landed on this exact file: +%d%% progress, shell risk %s, chain x%d. A sound or golden delivery restores its attention charge." % [
					rating.capitalize(),
					progress_gain,
					risk_text,
					int(last_assist.get("streak", 0)),
				]
			else:
				_peck_assist_button.text = "PRIORITY FILED  ·  x%d" % int(assist.get("streak", 0))
			_claim_progress_bar.add_theme_stylebox_override("fill", _compact_button_style(Color("769e75"), Color("a8c894"), 0))
		&"missed", &"passed":
			_peck_assist_button.text = "WINDOW MISSED"
			_claim_progress_bar.add_theme_stylebox_override("fill", _compact_button_style(Color("89645c"), Color("b57d6d"), 0))
		&"spent":
			_peck_assist_button.text = (
				"AWAIT CLEAN DELIVERY"
				if assist_pending > 0 else
				"ATTENTION SPENT"
			)
		_:
			_peck_assist_button.text = "NO ACTIVE FILE" if claim.is_empty() else "PECK SUPPORT LOCKED"
	var assignment_is_credentialed := (
		assignment == &"auto"
		or assignment == specialty
		or (secondary_specialty != &"" and assignment == secondary_specialty)
	)
	var employed := bool(worker.get("employed", true))
	var operations := _operations_snapshot()
	var automation := operations.get("automation", {}) as Dictionary
	var it_level := maxi(0, int(operations.get("it_coop_level", 0)))
	var automation_enabled := bool(automation.get("enabled", false)) and it_level > 0
	var auto_work_basis_points := maxi(10_000, int(automation.get("work_basis_points", 10_000)))
	var auto_work_percent := float(auto_work_basis_points - 10_000) / 100.0
	var auto_grace := maxi(0, int(automation.get("specialty_grace_minutes", 180)))
	var auto_secondary := bool(automation.get("recognizes_secondary_specialties", false))
	if not employed:
		_routing_hint_label.text = "APPLICANT FILE / NO LIVE AUTO SUPPORT"
		_routing_hint_label.tooltip_text = "Only employed hens can receive live tray routing or IT Coop AUTO support."
	elif assignment == &"auto":
		_routing_hint_label.text = (
			"IT AUTO L%d / +%s%% PACE / %dM GRACE"
			% [it_level, _compact_number(auto_work_percent), auto_grace]
			if automation_enabled else
			"LOCAL AUTO / BASE PACE / %dM GRACE" % auto_grace
		)
		_routing_hint_label.tooltip_text = (
			"AUTO is opt-in for this employed hen. IT Coop support improves only AUTO-routed work; it never completes a file or lays an egg. "
			+ ("Secondary accreditation is recognized by dispatch." if auto_secondary else "Dispatch recognizes the primary specialty only.")
		)
	else:
		_routing_hint_label.text = "MANUAL OVERRIDE / IT AUTO SUPPORT OFF"
		_routing_hint_label.tooltip_text = (
			"This manual %s tray is an explicit override, so IT Coop AUTO pace and grace do not apply. %s"
			% [
				_lane_name(assignment),
				"The route matches a filed specialty." if assignment_is_credentialed else "The route is out of specialty and raises time and shell risk.",
			]
		)
	if assist_pending > 0:
		_routing_hint_label.text = "%d CLEAN %s EN ROUTE / %s" % [
			assist_pending,
			("EGG" if assist_pending == 1 else "EGGS"),
			_routing_hint_label.text,
		]
	var manager_trust := clampf(float(worker.get("manager_trust", worker.get("trust", 50.0))), 0.0, 100.0)
	var grievance := clampf(float(worker.get("grievance", 0.0)), 0.0, 100.0)
	_trust_label.text = "TRUST  %d" % int(roundf(manager_trust))
	_trust_label.add_theme_color_override(
		"font_color",
		Color("73b5a7") if manager_trust >= 60.0 else (Color("d7c17d") if manager_trust >= 35.0 else Color("df826f")),
	)
	_grievance_label.text = "GRIEVANCE  %d" % int(roundf(grievance))
	_grievance_label.add_theme_color_override(
		"font_color",
		Color("df826f") if grievance >= 60.0 else (Color("d7c17d") if grievance >= 30.0 else Color("aebdc5")),
	)
	var phase := int(_snapshot.get("shift_phase", 1))
	var can_assign := _interaction_enabled and phase == 1 and employed
	for lane in ASSIGNMENT_ORDER:
		var button := _assignment_buttons[lane]
		button.text = _lane_name(lane)
		button.disabled = not can_assign
		button.theme_type_variation = &"SelectedChoiceButton" if lane == assignment else &"DecisionChoiceButton"
		button.tooltip_text = _assignment_tooltip(lane)
		if lane == &"auto":
			button.tooltip_text += (
				" IT Coop support will apply to this employed hen."
				if automation_enabled and employed else
				" AUTO remains a local opt-in without IT Coop support."
			)
		else:
			button.tooltip_text += " This is an explicit manual override of IT Coop AUTO support."
	var action_status := _snapshot.get("personnel_action_status", {}) as Dictionary
	var has_allowance_status := action_status.has("limit") or action_status.has("remaining")
	var action_limit := maxi(1, int(action_status.get("limit", 1)))
	var actions_used := clampi(
		int(action_status.get(
			"used",
			1 if bool(_snapshot.get("personnel_action_used", false)) else 0,
		)),
		0,
		action_limit,
	)
	var actions_remaining := clampi(
		int(action_status.get("remaining", action_limit - actions_used)),
		0,
		action_limit,
	)
	if not has_allowance_status and bool(_snapshot.get("personnel_action_used", false)):
		actions_remaining = 0
	var action_available := bool(action_status.get(
		"available",
		_snapshot.get("personnel_action_available", false),
	))
	var last_action := action_status.get("last_action", {}) as Dictionary
	var worker_action := _worker_action_receipt(action_status, worker, _focused_worker_id)
	var worker_action_filed := not worker_action.is_empty()
	var legacy_global_lock := not has_allowance_status and bool(_snapshot.get("personnel_action_used", false))
	var can_manage := (
		can_assign
		and action_available
		and actions_remaining > 0
		and not worker_action_filed
		and not legacy_global_lock
	)
	if worker_action_filed:
		_check_in_status_label.text = "HEN FILED / %d OF %d" % [actions_used, action_limit]
		_check_in_status_label.tooltip_text = String(worker_action.get(
			"outcome",
			"%s already has a filed flock check-in today." % worker_name,
		))
	elif actions_remaining <= 0 or legacy_global_lock:
		_check_in_status_label.text = "CHECK-INS FULL / %d OF %d" % [actions_used, action_limit]
		_check_in_status_label.tooltip_text = String(action_status.get(
			"reason",
			"Today's flock check-in allowance is fully filed.",
		))
	elif can_assign and action_available:
		_check_in_status_label.text = "CHECK-IN READY / %d OF %d / %d LEFT" % [
			actions_used,
			action_limit,
			actions_remaining,
		]
		_check_in_status_label.tooltip_text = "Choose one personnel action for this hen; %d flock check-in%s remain%s." % [
			actions_remaining,
			"" if actions_remaining == 1 else "s",
			"s" if actions_remaining == 1 else "",
		]
	else:
		_check_in_status_label.text = "CHECK-IN LOCKED / %d OF %d" % [actions_used, action_limit]
		_check_in_status_label.tooltip_text = String(action_status.get(
			"reason",
			"Resolve the current management decision first.",
		))
	_check_in_status_label.add_theme_color_override(
		"font_color",
		Color("e7c56e") if can_manage else Color("83939d"),
	)
	for action_id in PERSONNEL_ACTION_ORDER:
		var personnel_button := _personnel_buttons[action_id]
		var definition := _personnel_definition(action_id)
		var action_label := String(definition.get(
			"short_name",
			definition.get("button_label", definition.get("display_name", definition.get("name", PERSONNEL_ACTION_NAMES[action_id]))),
		)).to_upper()
		personnel_button.text = "%s%s" % [("FIT / " if preferred_action == action_id else ""), action_label]
		var preview := String(definition.get("preview", definition.get("description", PERSONNEL_ACTION_TOOLTIPS[action_id])))
		var action_cost := int(definition.get("cost_cents", 0))
		var affordable := int(_snapshot.get("spendable_fund_cents", _snapshot.get("revenue_cents", 0))) >= action_cost
		personnel_button.tooltip_text = "%s%s%s" % [
			preview,
			" Profile match for this hen." if preferred_action == action_id else "",
			(
				" This hen already has a filed check-in today."
				if worker_action_filed else
				" The flock check-in allowance is full."
				if actions_remaining <= 0 or legacy_global_lock else
				(" Feed Fund is short." if not affordable else " Uses one of %d remaining flock check-ins." % actions_remaining)
			),
		]
		personnel_button.disabled = not can_manage or not affordable
	_refresh_dossier_summary(
		worker,
		career_profile_name,
		career_profile_description,
		preferred_action,
		worker_action,
	)
	_refresh_first_clutch()


func _refresh_dossier_summary(
	worker: Dictionary,
	career_profile_name: String,
	career_profile_description: String,
	preferred_action: StringName,
	worker_action: Dictionary,
) -> void:
	if _dossier_summary_label == null:
		return
	match _active_dossier_tab:
		&"support":
			var definition := _personnel_definition(preferred_action)
			var action_name := String(definition.get(
				"short_name",
				definition.get("name", PERSONNEL_ACTION_NAMES.get(preferred_action, "CHECK-IN")),
			)).to_upper()
			var preview := String(definition.get(
				"preview",
				definition.get("description", PERSONNEL_ACTION_TOOLTIPS.get(preferred_action, "")),
			)).strip_edges()
			if not worker_action.is_empty():
				var filed_name := String(worker_action.get(
					"action_name",
					worker_action.get("display_name", action_name),
				)).to_upper()
				var outcome := String(worker_action.get(
					"outcome",
					"This hen's check-in is already filed for today.",
				)).strip_edges()
				_dossier_summary_label.text = "CHECK-IN FILED  /  %s\n%s" % [filed_name, outcome]
				_dossier_summary_label.tooltip_text = _dossier_summary_label.text
				_dossier_summary_label.add_theme_color_override("font_color", Color("8fc9b8"))
				return
			_dossier_summary_label.text = "PROFILE FIT  /  %s\n%s\n%s" % [
				action_name,
				career_profile_description if not career_profile_description.is_empty() else "This filing matches the hen's recorded work profile.",
				preview,
			]
			_dossier_summary_label.tooltip_text = "%s\n%s" % [
				String(definition.get("description", "Choose one permanent check-in for this shift.")),
				preview,
			]
			_dossier_summary_label.add_theme_color_override("font_color", Color("e7c56e"))
		&"profile":
			var specialty := StringName(worker.get("specialty", &"nest_damage"))
			var assignment := StringName(worker.get("assignment", worker.get("assigned_lane", &"auto")))
			var morale := roundi(float(worker.get("morale", 0.0)))
			var stress := roundi(float(worker.get("stress", 0.0)))
			var fatigue := roundi(float(worker.get("fatigue", 0.0)))
			var crack_risk := roundi(float(worker.get("estimated_crack_risk", 0.0)) * 100.0)
			_dossier_summary_label.text = "%s  /  %s SPECIALIST  /  %s\n%s\nCARE  morale %d  /  stress %d  /  fatigue %d  /  shell risk %d%%" % [
				career_profile_name.to_upper(),
				_lane_name(specialty),
				("AUTO SORT" if assignment == &"auto" else "%s TRAY" % _lane_name(assignment)),
				career_profile_description if not career_profile_description.is_empty() else "No additional work-profile note is filed.",
				morale,
				stress,
				fatigue,
				crack_risk,
			]
			_dossier_summary_label.tooltip_text = _dossier_summary_label.text
			_dossier_summary_label.add_theme_color_override("font_color", _lane_color(specialty))
		_:
			_dossier_summary_label.text = ""
			_dossier_summary_label.tooltip_text = ""


func _refresh_first_clutch() -> void:
	if _first_clutch_panel == null:
		return
	var coach_active := bool(_first_clutch.get("visible", false))
	var compact := coach_active and _first_clutch_has_contextual_dossier()
	if compact != _first_clutch_compact:
		_first_clutch_compact = compact
		_apply_first_clutch_layout()
	_first_clutch_panel.visible = coach_active
	_first_clutch_body_label.visible = not compact
	_refresh_first_clutch_return_action(coach_active)
	_apply_dossier_disclosure()
	if not coach_active:
		# A mouse-activated Skip can remain the viewport's focus owner after its
		# coach card disappears. Release only focus owned by that hidden card so
		# Home/WASD and other floor controls are not swallowed by an invisible UI.
		var focus_owner := get_viewport().gui_get_focus_owner()
		if focus_owner != null and _first_clutch_panel.is_ancestor_of(focus_owner):
			get_viewport().gui_release_focus()
		_clear_first_clutch_control_cue()
		return
	var total := clampi(int(_first_clutch.get("total", 5)), 1, 99)
	var progress := clampi(int(_first_clutch.get(
		"progress",
		_first_clutch.get("completed_steps", 0),
	)), 0, total)
	var eyebrow := String(_first_clutch.get("eyebrow", "")).strip_edges().to_upper()
	_first_clutch_progress_label.text = (
		eyebrow if not eyebrow.is_empty() else "FIRST CLUTCH  %d / %d" % [progress, total]
	)
	_first_clutch_title_label.text = String(_first_clutch.get(
		"title",
		_first_clutch.get("action_title", "INSPECT A HEN"),
	)).strip_edges().to_upper()
	if _first_clutch_title_label.text.is_empty():
		_first_clutch_title_label.text = "INSPECT A HEN"
	_first_clutch_body_label.text = String(_first_clutch.get(
		"body",
		_first_clutch.get("action_body", "Click a hen or press Tab to open her work file."),
	)).strip_edges()
	if _first_clutch_body_label.text.is_empty():
		_first_clutch_body_label.text = "Complete the highlighted management action."
	_first_clutch_panel.tooltip_text = "%s\n%s" % [
		_first_clutch_title_label.text,
		_first_clutch_body_label.text,
	]
	var can_skip := bool(_first_clutch.get("can_skip", true))
	var skip_had_focus := _first_clutch_skip_button.has_focus()
	_first_clutch_skip_button.visible = can_skip
	_first_clutch_skip_button.mouse_filter = (
		Control.MOUSE_FILTER_STOP if can_skip else Control.MOUSE_FILTER_IGNORE
	)
	if skip_had_focus and not can_skip:
		# Delivery can settle asynchronously while Skip owns keyboard focus. Reuse
		# the staged-disclosure focus handoff after the button is actually hidden
		# so focus never remains trapped on an unavailable tutorial action.
		_ensure_contextual_focus_remains_visible(
			_first_clutch_disclosure_stage(),
			_first_clutch_skip_button,
		)
	var tone := StringName(String(_first_clutch.get("tone", "active")))
	var border := Color("c7a352")
	if tone == &"warning":
		border = Color("c9795d")
	elif tone in [&"ready", &"complete"]:
		border = Color("73b5a7")
	_first_clutch_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("172832"), 0.985, border, 8, 1),
	)
	_apply_first_clutch_control_cue()


func _first_clutch_disclosure_stage() -> StringName:
	var stage := StringName(String(_first_clutch.get(
		"stage",
		_first_clutch.get("step", _first_clutch.get("cue", "")),
	)).strip_edges().to_lower())
	match stage:
		&"route", &"routing", &"match_route":
			return &"specialty_route"
		&"checkin", &"personnel", &"personnel_action":
			return &"check_in"
		&"peck", &"peck_assist":
			return &"priority_peck"
		_:
			return stage


func _first_clutch_has_contextual_dossier() -> bool:
	if _focus_panel == null or not _focus_panel.visible or _focused_worker_id < 0:
		return false
	var target_worker_id := _first_clutch_target_worker_id()
	return target_worker_id < 0 or target_worker_id == _focused_worker_id


## Keeps one management category visible at a time while First Clutch is active.
## Nodes are retained (including names, signals, and disabled state); normal or
## dismissed coach state restores every management action immediately.
func _apply_dossier_disclosure() -> void:
	if (
		_queue_panel == null
		or _focus_panel == null
		or _assignment_section == null
		or _personnel_actions_section == null
	):
		return
	var previous_focus_owner: Control
	var viewport := get_viewport()
	if viewport != null:
		previous_focus_owner = viewport.gui_get_focus_owner()
	var coach_active := bool(_first_clutch.get("visible", false))
	var normal_play := not coach_active
	var target_matches := _first_clutch_has_contextual_dossier()
	var stage := _first_clutch_disclosure_stage()
	if stage == &"":
		stage = &"inspect"
	var route_tab := normal_play and _active_dossier_tab == &"route"
	var support_tab := normal_play and _active_dossier_tab == &"support"
	var profile_tab := normal_play and _active_dossier_tab == &"profile"

	var show_claim := route_tab or (coach_active and stage in [
		&"inspect",
		&"specialty_route",
		&"priority_peck",
		&"delivery",
		&"reinvestment",
		&"complete",
	])
	var show_routing := route_tab or (coach_active and target_matches and stage == &"specialty_route")
	var show_check_in := support_tab or (coach_active and target_matches and stage == &"check_in")
	var show_priority := route_tab or (coach_active and target_matches and stage == &"priority_peck")
	var show_delivery := target_matches and stage == &"delivery"

	# The queue is useful while teaching routes, but it is visual noise during
	# inspection, personnel, timing, and delivery steps.
	_queue_panel.visible = normal_play or (target_matches and stage == &"specialty_route")
	_claim_header.visible = show_claim
	_claim_detail_label.visible = show_claim
	_dossier_summary_label.visible = normal_play and _active_dossier_tab in [&"support", &"profile"]
	var worker := _worker_snapshot(_focused_worker_id)
	var claim := worker.get("current_claim", {}) as Dictionary
	_claim_progress_bar.visible = show_claim and not claim.is_empty()
	_assignment_section.visible = show_routing
	_personnel_actions_section.visible = show_check_in

	_assist_row.visible = route_tab or show_routing or show_priority or show_delivery
	_routing_hint_label.visible = _assist_row.visible
	_peck_assist_button.visible = route_tab or show_priority

	_worker_career_label.visible = profile_tab or (coach_active and _details_expanded)
	_trust_label.visible = profile_tab or (coach_active and _details_expanded)
	_grievance_label.visible = profile_tab or (coach_active and _details_expanded)
	_check_in_status_label.visible = show_check_in
	_personnel_status.visible = profile_tab or show_check_in or (coach_active and _details_expanded)
	_dossier_tabs.visible = normal_play
	_details_button.visible = coach_active
	for tab_id: StringName in _dossier_tab_buttons:
		var tab_button := _dossier_tab_buttons[tab_id] as Button
		tab_button.set_pressed_no_signal(tab_id == _active_dossier_tab)
	_details_button.text = "HIDE DETAILS" if _details_expanded else "DETAILS"
	_details_button.tooltip_text = (
		"Hide career, trust, grievance, and care details."
		if _details_expanded else
		"Show career, trust, grievance, and care details for this hen."
	)
	if not profile_tab and not _details_expanded and not worker.is_empty():
		var specialty := StringName(worker.get("specialty", &"nest_damage"))
		var secondary := StringName(String(worker.get(
			"secondary_specialty",
			worker.get("secondary_lane", ""),
		)))
		var specialty_copy := _lane_name(specialty)
		if secondary != &"":
			specialty_copy += " + %s" % _lane_name(secondary)
		_worker_trait_label.text = "SPECIALTY  /  %s" % specialty_copy
		_worker_trait_label.tooltip_text = (
			"Primary routing specialty: %s. Open Details for career, care, and accreditation notes."
			% _lane_name(specialty)
		)
	_ensure_contextual_focus_remains_visible(stage, previous_focus_owner)


func _ensure_contextual_focus_remains_visible(
	stage: StringName,
	focus_owner: Control = null,
) -> void:
	if focus_owner == null:
		var viewport := get_viewport()
		if viewport == null:
			return
		focus_owner = viewport.gui_get_focus_owner()
	if (
		focus_owner == null
		or not is_ancestor_of(focus_owner)
		or focus_owner.is_visible_in_tree()
	):
		return
	var target: Button
	match stage:
		&"specialty_route":
			var lane := StringName(String(_first_clutch.get(
				"expected_lane",
				_first_clutch.get("lane", "auto"),
			)))
			target = _assignment_buttons.get(lane) as Button
		&"check_in":
			var action_id := StringName(String(_first_clutch.get(
				"preferred_action",
				_worker_snapshot(_focused_worker_id).get("preferred_personnel_action", ""),
			)))
			target = _personnel_buttons.get(action_id) as Button
		&"priority_peck":
			target = _peck_assist_button
	if target == null or not target.is_visible_in_tree():
		# When the coached hen is no longer focused, the explicit return action is
		# safer than moving focus into an unrelated hen's dossier. A target-matched
		# dossier falls back to Details for delivery/reinvestment/complete stages.
		if (
			_first_clutch_return_button != null
			and _first_clutch_return_button.is_visible_in_tree()
		):
			target = _first_clutch_return_button
		else:
			target = _details_button
	if target != null and target.is_visible_in_tree() and target.focus_mode != Control.FOCUS_NONE:
		target.call_deferred("grab_focus")


func _apply_first_clutch_control_cue() -> void:
	if not bool(_first_clutch.get("visible", false)) or not _focus_panel.visible:
		_clear_first_clutch_control_cue()
		return
	var worker_id := _first_clutch_target_worker_id()
	if worker_id >= 0 and worker_id != _focused_worker_id:
		_clear_first_clutch_control_cue()
		return
	var cue := StringName(String(_first_clutch.get(
		"cue",
		_first_clutch.get("step", _first_clutch.get("stage", "")),
	)).strip_edges().to_lower())
	var target: Button
	match cue:
		&"route", &"routing", &"match_route", &"specialty_route":
			var lane_text := String(_first_clutch.get(
				"lane",
				_first_clutch.get(
					"expected_lane",
					_first_clutch.get("specialty", _first_clutch.get("specialty_name", "")),
				),
			)).strip_edges().to_lower().replace(" ", "_")
			var lane := StringName(lane_text)
			if _assignment_buttons.has(lane):
				target = _assignment_buttons[lane]
		&"check_in", &"checkin", &"personnel", &"personnel_action":
			var focused_worker := _worker_snapshot(_focused_worker_id)
			var action_id := StringName(String(_first_clutch.get(
				"action_id",
				_first_clutch.get(
					"preferred_action",
					focused_worker.get("preferred_personnel_action", ""),
				),
			)))
			if _personnel_buttons.has(action_id):
				target = _personnel_buttons[action_id]
		&"priority_peck", &"peck", &"peck_assist":
			if not bool(_first_clutch.get("resume_required", false)):
				target = _peck_assist_button
	if (
		target != null
		and target == _first_clutch_cued_control
		and is_instance_valid(_first_clutch_cued_control)
	):
		return
	_clear_first_clutch_control_cue()
	if target == null:
		return
	_first_clutch_cued_control = target
	target.set_meta("first_clutch_cue", true)
	target.self_modulate = Color("fff4cf")
	_apply_first_clutch_cue_style(target)


func _clear_first_clutch_control_cue() -> void:
	if _first_clutch_cued_control == null:
		return
	if _first_clutch_cued_control != null and is_instance_valid(_first_clutch_cued_control):
		_first_clutch_cued_control.self_modulate = Color.WHITE
	_first_clutch_cued_control = null
	for lane in ASSIGNMENT_ORDER:
		var assignment_button := _assignment_buttons.get(lane) as Button
		if assignment_button == null:
			continue
		assignment_button.set_meta("first_clutch_cue", false)
		for style_name in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
			assignment_button.remove_theme_stylebox_override(style_name)
	for action_id in PERSONNEL_ACTION_ORDER:
		var personnel_button := _personnel_buttons.get(action_id) as Button
		if personnel_button == null:
			continue
		personnel_button.set_meta("first_clutch_cue", false)
		personnel_button.self_modulate = Color.WHITE
		_apply_compact_personnel_style(personnel_button, action_id)
	if _peck_assist_button != null:
		_peck_assist_button.set_meta("first_clutch_cue", false)
		_peck_assist_button.self_modulate = Color.WHITE
		_apply_peck_assist_style(_peck_assist_button)


func _apply_first_clutch_cue_style(button: Button) -> void:
	button.add_theme_stylebox_override(
		"normal",
		_compact_button_style(Color("4d4128"), Color("f0c968"), 2),
	)
	button.add_theme_stylebox_override(
		"hover",
		_compact_button_style(Color("65502b"), Color("ffe49a"), 2),
	)
	button.add_theme_stylebox_override(
		"pressed",
		_compact_button_style(Color("302719"), Color("fff0b8"), 2),
	)
	button.add_theme_stylebox_override(
		"disabled",
		_compact_button_style(Color("27281f"), Color("9f874f"), 2),
	)
	button.add_theme_stylebox_override(
		"focus",
		_compact_button_style(Color(0.0, 0.0, 0.0, 0.0), Color("fff0aa"), 2),
	)


func _refresh_queue_contract_badge(routing: Dictionary) -> void:
	var summary := _market_contract_queue_summary(routing)
	_refresh_contract_badge(_queue_contract_badge, summary)
	_queue_title_label.visible = summary.is_empty()


func _market_contract_queue_summary(routing: Dictionary) -> Dictionary:
	var queue_items_variant: Variant = routing.get(
		"queue_items",
		_snapshot.get("claim_queue_items", {}),
	)
	if not queue_items_variant is Dictionary:
		return {}
	var queue_items := queue_items_variant as Dictionary
	var contract_claims: Array[Dictionary] = []
	var has_rush := false
	for lane in LANE_ORDER:
		var lane_items_variant: Variant = queue_items.get(
			lane,
			queue_items.get(String(lane), []),
		)
		if not lane_items_variant is Array:
			continue
		for claim_value in lane_items_variant as Array:
			if not claim_value is Dictionary:
				continue
			var claim := claim_value as Dictionary
			if not bool(claim.get("market_contract", false)):
				continue
			contract_claims.append(claim)
			has_rush = has_rush or bool(claim.get("market_contract_rush", false))
	if contract_claims.is_empty():
		return {}

	# If any rush folders are waiting, disclose the nearest rush deadline. A
	# normal binder otherwise reports the nearest contracted-folder deadline.
	var deadline_claim: Dictionary = {}
	var nearest_minutes := 2147483647
	for claim in contract_claims:
		if has_rush and not bool(claim.get("market_contract_rush", false)):
			continue
		var minutes_until_deadline := int(claim.get("minutes_until_deadline", 2147483647))
		if deadline_claim.is_empty() or minutes_until_deadline < nearest_minutes:
			deadline_claim = claim
			nearest_minutes = minutes_until_deadline
	return {
		"market_contract": true,
		"market_contract_name": String(deadline_claim.get(
			"market_contract_name",
			"MUTUAL BINDER",
		)),
		"market_contract_rush": has_rush,
		"market_contract_deadline_time": String(deadline_claim.get(
			"market_contract_deadline_time",
			"END OF SHIFT",
		)),
		"market_contract_queue_count": contract_claims.size(),
	}


func _refresh_contract_badge(badge: Label, claim: Dictionary) -> void:
	if badge == null:
		return
	var contracted := bool(claim.get("market_contract", false))
	badge.visible = contracted
	if not contracted:
		badge.text = ""
		badge.tooltip_text = ""
		return
	var rush := bool(claim.get("market_contract_rush", false))
	var badge_title := "CONTRACT RUSH" if rush else "MUTUAL BINDER"
	var deadline := String(claim.get(
		"market_contract_deadline_time",
		"END OF SHIFT",
	)).strip_edges().to_upper()
	if deadline.is_empty():
		deadline = "END OF SHIFT"
	badge.text = "%s  %s" % [badge_title, deadline]
	var binder_name := String(claim.get("market_contract_name", "MUTUAL BINDER")).strip_edges().to_upper()
	var queue_count := maxi(0, int(claim.get("market_contract_queue_count", 0)))
	badge.tooltip_text = "FARM MUTUAL / %s\nDisclosed deadline: %s." % [binder_name, deadline]
	if queue_count > 0:
		badge.tooltip_text += "\n%d contracted %s currently waiting in the routing trays." % [
			queue_count,
			"folder" if queue_count == 1 else "folders",
		]


func _worker_snapshot(worker_id: int) -> Dictionary:
	if worker_id < 0:
		return {}
	for worker_value in _snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return worker
	return {}


func first_clutch_skip_button_rect() -> Rect2:
	## Browser accessibility and production-path audits need the same authored
	## target the player sees. Publishing its settled canvas rectangle avoids
	## brittle guessed coordinates while leaving the button as the sole intent.
	if (
		_first_clutch_skip_button == null
		or not _first_clutch_skip_button.is_visible_in_tree()
	):
		return Rect2()
	return _first_clutch_skip_button.get_global_rect()


func _operations_snapshot() -> Dictionary:
	var operations_value: Variant = _snapshot.get("operations", {})
	if operations_value is Dictionary:
		return (operations_value as Dictionary).duplicate(true)
	return {}


func _worker_action_receipt(
	action_status: Dictionary,
	worker: Dictionary,
	worker_id: int,
) -> Dictionary:
	var active_day := int(action_status.get("day", _snapshot.get("day", 0)))
	var actions_value: Variant = action_status.get("actions", [])
	if actions_value is Array:
		for action_value in (actions_value as Array):
			if not action_value is Dictionary:
				continue
			var action := action_value as Dictionary
			if (
				int(action.get("worker_id", -1)) == worker_id
				and int(action.get("day", active_day)) == active_day
			):
				return action.duplicate(true)
	if (
		int(worker.get("last_personnel_action_day", -1)) == active_day
		and StringName(worker.get("last_personnel_action", &"")) != &""
	):
		var last_action := action_status.get("last_action", {}) as Dictionary
		if int(last_action.get("worker_id", worker_id)) == worker_id:
			return last_action.duplicate(true) if not last_action.is_empty() else {
				"day": active_day,
				"worker_id": worker_id,
				"worker_name": String(worker.get("name", "HEN")),
				"action_id": StringName(worker.get("last_personnel_action", &"")),
			}
	return {}


func _training_terms_snapshot() -> Dictionary:
	var care_value: Variant = _snapshot.get("flock_care", {})
	if care_value is Dictionary:
		var terms_value: Variant = (care_value as Dictionary).get("training_terms", {})
		if terms_value is Dictionary and not (terms_value as Dictionary).is_empty():
			return (terms_value as Dictionary).duplicate(true)
	var direct_value: Variant = _snapshot.get("training_terms", {})
	if direct_value is Dictionary:
		return (direct_value as Dictionary).duplicate(true)
	return {}


func _compact_number(value: float) -> String:
	var rounded := snappedf(value, 0.1)
	return str(roundi(rounded)) if is_equal_approx(rounded, float(roundi(rounded))) else "%.1f" % rounded


func _first_clutch_target_worker_id() -> int:
	return int(_first_clutch.get(
		"worker_id",
		_first_clutch.get("target_worker_id", -1),
	))


func _refresh_first_clutch_return_action(coach_visible: bool) -> void:
	if _first_clutch_return_button == null:
		return
	var target_worker_id := _first_clutch_target_worker_id()
	var pre_policy := bool(_first_clutch.get("pre_policy", false))
	var show_return := (
		coach_visible
		and target_worker_id >= 0
		and (pre_policy or target_worker_id != _focused_worker_id)
	)
	_first_clutch_return_button.visible = show_return
	_first_clutch_return_button.mouse_filter = (
		Control.MOUSE_FILTER_STOP if show_return else Control.MOUSE_FILTER_IGNORE
	)
	if not show_return:
		return
	var worker := _worker_snapshot(target_worker_id)
	var worker_name := String(worker.get("name", "HEN %d" % (target_worker_id + 1))).strip_edges()
	if worker_name.is_empty():
		worker_name = "HEN %d" % (target_worker_id + 1)
	if pre_policy:
		_first_clutch_return_button.custom_minimum_size.x = 166.0
		_first_clutch_return_button.text = "OPEN %s'S FILE  [ENTER]" % worker_name.to_upper()
		_first_clutch_return_button.tooltip_text = "Open %s's live dossier, then choose the flock policy." % worker_name
		return
	_first_clutch_return_button.custom_minimum_size.x = 108.0
	_first_clutch_return_button.text = "RETURN TO %s" % worker_name.to_upper()
	_first_clutch_return_button.tooltip_text = "Return to %s's work file without advancing the coach." % worker_name


func _on_assignment_pressed(lane: StringName) -> void:
	if _focused_worker_id < 0 or not _interaction_enabled:
		return
	assignment_requested.emit(_focused_worker_id, lane)


func _on_personnel_action_pressed(action_id: StringName) -> void:
	if _focused_worker_id < 0 or not _interaction_enabled:
		return
	var phase := int(_snapshot.get("shift_phase", 1))
	var action_status := _snapshot.get("personnel_action_status", {}) as Dictionary
	var has_allowance_status := action_status.has("limit") or action_status.has("remaining")
	var action_limit := maxi(1, int(action_status.get("limit", 1)))
	var actions_used := clampi(
		int(action_status.get(
			"used",
			1 if bool(_snapshot.get("personnel_action_used", false)) else 0,
		)),
		0,
		action_limit,
	)
	var actions_remaining := clampi(
		int(action_status.get("remaining", action_limit - actions_used)),
		0,
		action_limit,
	)
	var action_available := bool(action_status.get(
		"available",
		_snapshot.get("personnel_action_available", false),
	))
	var worker := _worker_snapshot(_focused_worker_id)
	var worker_action_filed := not _worker_action_receipt(
		action_status,
		worker,
		_focused_worker_id,
	).is_empty()
	var legacy_global_lock := not has_allowance_status and bool(_snapshot.get("personnel_action_used", false))
	if (
		phase != 1
		or not bool(worker.get("employed", true))
		or not action_available
		or actions_remaining <= 0
		or worker_action_filed
		or legacy_global_lock
	):
		return
	personnel_action_requested.emit(_focused_worker_id, action_id)


func request_focused_peck_assist() -> bool:
	if _focused_worker_id < 0 or _peck_assist_button == null or _peck_assist_button.disabled:
		return false
	peck_assist_requested.emit(_focused_worker_id)
	return true


func _on_peck_assist_pressed() -> void:
	request_focused_peck_assist()


func _on_first_clutch_skip_pressed() -> void:
	first_clutch_skip_requested.emit()


func _on_first_clutch_return_pressed() -> void:
	var target_worker_id := _first_clutch_target_worker_id()
	if target_worker_id < 0 or _first_clutch_return_button == null or not _first_clutch_return_button.visible:
		return
	first_clutch_focus_requested.emit(target_worker_id)


func _on_details_pressed() -> void:
	if _focused_worker_id < 0:
		return
	_details_expanded = not _details_expanded
	# Refresh restores the full profile copy before presentation disclosure is
	# re-applied; collapsing then returns to the compact specialty summary.
	_refresh()


func _personnel_definition(action_id: StringName) -> Dictionary:
	var catalog_value: Variant = _snapshot.get("personnel_catalog", [])
	if catalog_value is Dictionary:
		var catalog := catalog_value as Dictionary
		return catalog.get(action_id, catalog.get(String(action_id), {})) as Dictionary
	if catalog_value is Array:
		for entry_value in (catalog_value as Array):
			var entry := entry_value as Dictionary
			if StringName(entry.get("id", &"")) == action_id:
				return entry
	return {}


func _lane_name(lane: StringName) -> String:
	var display := String(LANE_NAMES.get(lane, String(lane).replace("_", " ").to_upper()))
	return SemanticColorPaletteScript.marked_lane_name(display, lane, _color_vision_mode)


func _lane_short_name(lane: StringName) -> String:
	var display := String(LANE_SHORT_NAMES.get(lane, String(lane).replace("_", " ").to_upper()))
	return SemanticColorPaletteScript.marked_lane_name(display, lane, _color_vision_mode)


func _lane_color(lane: StringName) -> Color:
	return SemanticColorPaletteScript.lane_color(lane, _color_vision_mode)


func _assignment_tooltip(lane: StringName) -> String:
	match lane:
		&"auto":
			return "Pull the most urgent file, favoring this hen's specialty when deadlines allow."
		&"nest_damage":
			return "Pull only routine nest and coop property files."
		&"predator_loss":
			return "Pull only time-sensitive predator and loss files."
		&"appeals":
			return "Pull only complex appeals and exception files."
	return "Assign this peckwork tray."


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_contract_badge(control_name: String, minimum_width: float) -> Label:
	var badge := _make_label("", 9, Color("f6df9d"))
	badge.name = control_name
	badge.custom_minimum_size = Vector2(minimum_width, 22.0)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override(
		"normal",
		_compact_button_style(Color("4a3523"), Color("d6ab5f"), 1),
	)
	badge.visible = false
	return badge


func _apply_compact_personnel_style(button: Button, action_id: StringName) -> void:
	var normal_color := Color("263842")
	var border_color := Color("647780")
	var hover_color := Color("31504f")
	if action_id == &"share_credit":
		normal_color = Color("29453f")
		border_color = Color("5b9b8d")
		hover_color = Color("356052")
	elif action_id == &"quota_pressure":
		normal_color = Color("4b302f")
		border_color = Color("a95748")
		hover_color = Color("633a35")
	button.add_theme_stylebox_override("normal", _compact_button_style(normal_color, border_color, 1))
	button.add_theme_stylebox_override("hover", _compact_button_style(hover_color, Color("e0bd68"), 2))
	button.add_theme_stylebox_override("pressed", _compact_button_style(Color("172832"), Color("f0cb70"), 2))
	button.add_theme_stylebox_override("disabled", _compact_button_style(Color("151d25"), Color("303b45"), 1))
	button.add_theme_stylebox_override("focus", _compact_button_style(Color(0.0, 0.0, 0.0, 0.0), Color("e0bd68"), 2))


func _apply_peck_assist_style(button: Button) -> void:
	button.add_theme_color_override("font_color", Color("fff1bd"))
	button.add_theme_color_override("font_hover_color", Color("fff8dc"))
	button.add_theme_color_override("font_disabled_color", Color("73808a"))
	button.add_theme_stylebox_override("normal", _compact_button_style(Color("5a4528"), Color("d9ad51"), 2))
	button.add_theme_stylebox_override("hover", _compact_button_style(Color("74572d"), Color("f3d477"), 2))
	button.add_theme_stylebox_override("pressed", _compact_button_style(Color("34291d"), Color("fff0aa"), 2))
	button.add_theme_stylebox_override("disabled", _compact_button_style(Color("182229"), Color("394851"), 1))
	button.add_theme_stylebox_override("focus", _compact_button_style(Color("5a4528"), Color("fff0aa"), 2))


func _compact_button_style(color: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := _panel_style(color, color.a, border, 6, border_width)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	return style


func _panel_style(color: Color, opacity: float, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, opacity)
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
