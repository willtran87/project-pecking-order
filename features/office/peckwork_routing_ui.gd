class_name PeckworkRoutingUI
extends Control

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
const LANE_COLORS := {
	&"auto": Color("72b6aa"),
	&"nest_damage": Color("8fbd8d"),
	&"predator_loss": Color("d68a68"),
	&"appeals": Color("a896ce"),
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
var _current_claim_label: Label
var _claim_detail_label: Label
var _claim_progress_bar: ProgressBar
var _routing_hint_label: Label
var _peck_assist_button: Button
var _trust_label: Label
var _grievance_label: Label
var _check_in_status_label: Label
var _focused_worker_id := -1
var _snapshot: Dictionary = {}
var _interaction_enabled := true
var _peck_assist_clock_running := true
var _assist_pulse_phase := 0.0
var _first_clutch: Dictionary = {}
var _first_clutch_cued_control: Control
var _first_clutch_layout_width := -1.0


func _ready() -> void:
	name = "PeckworkRoutingUI"
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
	var peck_visible := _peck_assist_button != null and _peck_assist_button.visible
	var cue_visible := (
		_first_clutch_cued_control != null
		and is_instance_valid(_first_clutch_cued_control)
		and _first_clutch_cued_control.is_visible_in_tree()
	)
	if not peck_visible and not cue_visible:
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
	_first_clutch = coach.duplicate(true)
	_refresh_first_clutch()


func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled
	_refresh()


func set_peck_assist_clock_running(running: bool) -> void:
	_peck_assist_clock_running = running
	_refresh()


func focused_worker_id() -> int:
	return _focused_worker_id


func _build_queue_strip() -> void:
	_queue_panel = PanelContainer.new()
	_queue_panel.name = "PeckworkQueueStrip"
	_queue_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_queue_panel.offset_left = 18.0
	_queue_panel.offset_top = 120.0
	_queue_panel.offset_right = 720.0
	_queue_panel.offset_bottom = 164.0
	_queue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_queue_panel.add_theme_stylebox_override("panel", _panel_style(Color("16242d"), 0.96, Color("52646d"), 7, 1))
	add_child(_queue_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	_queue_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)
	margin.add_child(row)
	var title := _make_label("PECKWORK ROUTING", 13, Color("e7c56e"))
	title.custom_minimum_size.x = 142.0
	row.add_child(title)
	for lane in LANE_ORDER:
		var label := _make_label("%s  0" % String(LANE_SHORT_NAMES[lane]), 13, LANE_COLORS[lane])
		label.name = "Queue_%s" % String(lane)
		label.custom_minimum_size.x = 116.0
		row.add_child(label)
		_queue_labels[lane] = label
	var debt := _make_label("OVERDUE  0", 13, Color("e08a72"))
	debt.name = "QueueOverdue"
	debt.custom_minimum_size.x = 102.0
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
	if narrow:
		_first_clutch_panel.set_anchor(SIDE_LEFT, 0.0)
		_first_clutch_panel.set_anchor(SIDE_RIGHT, 0.0)
		_first_clutch_panel.offset_left = 12.0
		_first_clutch_panel.offset_top = 172.0
		_first_clutch_panel.offset_right = maxf(12.0, available_width - 12.0)
		_first_clutch_panel.offset_bottom = 276.0
	else:
		_first_clutch_panel.set_anchor(SIDE_LEFT, 0.0)
		_first_clutch_panel.set_anchor(SIDE_RIGHT, 0.0)
		_first_clutch_panel.offset_left = 18.0
		_first_clutch_panel.offset_top = 172.0
		_first_clutch_panel.offset_right = 598.0
		_first_clutch_panel.offset_bottom = 250.0


func _build_focus_dossier() -> void:
	_focus_panel = PanelContainer.new()
	_focus_panel.name = "PeckworkAssignmentDossier"
	_focus_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_focus_panel.offset_left = 18.0
	_focus_panel.offset_top = -206.0
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

	var active_file := VBoxContainer.new()
	active_file.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	active_file.add_theme_constant_override("separation", 3)
	row.add_child(active_file)
	_current_claim_label = _make_label("WAITING FOR PECKWORK", 16, Color("eef2e9"))
	_current_claim_label.name = "RoutingCurrentClaim"
	_current_claim_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	active_file.add_child(_current_claim_label)
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
	var assist_row := HBoxContainer.new()
	assist_row.name = "RoutingAssistRow"
	assist_row.add_theme_constant_override("separation", 9)
	active_file.add_child(assist_row)
	_routing_hint_label = _make_label("Choose which tray this hen pulls next.", 11, Color("d7c17d"))
	_routing_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_routing_hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	assist_row.add_child(_routing_hint_label)
	_peck_assist_button = Button.new()
	_peck_assist_button.name = "PeckAssistButton"
	_peck_assist_button.text = "NO ACTIVE FILE"
	_peck_assist_button.custom_minimum_size = Vector2(166.0, 30.0)
	_peck_assist_button.add_theme_font_size_override("font_size", 11)
	_apply_peck_assist_style(_peck_assist_button)
	_peck_assist_button.pressed.connect(_on_peck_assist_pressed)
	assist_row.add_child(_peck_assist_button)
	var personnel_status := HBoxContainer.new()
	personnel_status.name = "RoutingPersonnelStatus"
	personnel_status.add_theme_constant_override("separation", 13)
	active_file.add_child(personnel_status)
	_trust_label = _make_label("TRUST  50", 11, Color("73b5a7"))
	_trust_label.name = "RoutingManagerTrust"
	personnel_status.add_child(_trust_label)
	_grievance_label = _make_label("GRIEVANCE  0", 11, Color("d68a68"))
	_grievance_label.name = "RoutingGrievance"
	personnel_status.add_child(_grievance_label)
	_check_in_status_label = _make_label("CHECK-IN READY", 11, Color("e7c56e"))
	_check_in_status_label.name = "RoutingCheckInStatus"
	_check_in_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_check_in_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_check_in_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	personnel_status.add_child(_check_in_status_label)

	var actions := GridContainer.new()
	actions.name = "RoutingAssignments"
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 7)
	actions.add_theme_constant_override("v_separation", 7)
	row.add_child(actions)
	for assignment in ASSIGNMENT_ORDER:
		var button := Button.new()
		button.name = "Assign_%s" % String(assignment)
		button.text = String(LANE_NAMES[assignment])
		button.custom_minimum_size = Vector2(142.0, 34.0)
		button.theme_type_variation = &"DecisionChoiceButton"
		button.tooltip_text = _assignment_tooltip(assignment)
		button.pressed.connect(_on_assignment_pressed.bind(assignment))
		actions.add_child(button)
		_assignment_buttons[assignment] = button

	var personnel_actions := VBoxContainer.new()
	personnel_actions.name = "PersonnelActions"
	personnel_actions.custom_minimum_size.x = 142.0
	personnel_actions.add_theme_constant_override("separation", 4)
	row.add_child(personnel_actions)
	for action_id in PERSONNEL_ACTION_ORDER:
		var button := Button.new()
		button.name = "PersonnelAction_%s" % String(action_id)
		button.text = String(PERSONNEL_ACTION_NAMES[action_id])
		button.custom_minimum_size = Vector2(142.0, 26.0)
		button.add_theme_font_size_override("font_size", 11)
		_apply_compact_personnel_style(button, action_id)
		button.tooltip_text = String(PERSONNEL_ACTION_TOOLTIPS[action_id])
		button.pressed.connect(_on_personnel_action_pressed.bind(action_id))
		personnel_actions.add_child(button)
		_personnel_buttons[action_id] = button


func _refresh() -> void:
	if _queue_panel == null or _focus_panel == null:
		return
	var routing: Dictionary = _snapshot.get("routing", {}) as Dictionary
	var queue_counts: Dictionary = routing.get("queue_counts", _snapshot.get("claim_queue_counts", {})) as Dictionary
	var overdue_counts: Dictionary = routing.get("overdue_by_lane", _snapshot.get("claim_queue_overdue_counts", {})) as Dictionary
	for lane in LANE_ORDER:
		var count := int(queue_counts.get(lane, queue_counts.get(String(lane), 0)))
		var lane_overdue := int(overdue_counts.get(lane, overdue_counts.get(String(lane), 0)))
		var suffix := "  !%d" % lane_overdue if lane_overdue > 0 else ""
		_queue_labels[lane].text = "%s  %d%s" % [String(LANE_SHORT_NAMES[lane]), count, suffix]
	var overdue := int(routing.get("overdue_total", _snapshot.get("overdue_claims", 0)))
	_queue_labels[&"overdue"].text = "OVERDUE  %d" % overdue
	_queue_labels[&"overdue"].modulate = Color.WHITE if overdue > 0 else Color(1.0, 1.0, 1.0, 0.62)

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
		_worker_trait_label.text += "  /  TRAINING: %s" % _lane_name(training_specialty)
		_worker_trait_label.tooltip_text += "\nIN TRAINING: this worked shift is 15%% slower. %s accreditation files after close." % _lane_name(training_specialty)
	_worker_trait_label.add_theme_color_override("font_color", LANE_COLORS.get(specialty, Color("aebdc5")))
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
	if claim.is_empty():
		_current_claim_label.text = "WAITING FOR %s PECKWORK" % (_lane_name(assignment) if assignment != &"auto" else "AUTO-SORTED")
		_claim_progress_bar.value = 0.0
		_claim_progress_bar.visible = false
		_claim_detail_label.text = "No active file  ·  next pull follows the selected tray"
	else:
		var lane := StringName(claim.get("lane", &"nest_damage"))
		var claim_id := int(claim.get("id", 0))
		var rework := bool(claim.get("rework", claim.get("is_rework", false)))
		var progress := int(worker.get("progress", 0))
		_claim_progress_bar.visible = true
		_claim_progress_bar.value = progress
		_current_claim_label.text = "%s #%04d%s  ·  %d%%" % [
			_lane_name(lane), claim_id, ("  /  REWORK" if rework else ""), progress,
		]
		var value_cents := int(claim.get("value_cents", 0))
		var remaining_minutes := int(claim.get("minutes_until_deadline", 0))
		var urgency := (
			"OVERDUE BY %dm" % absi(remaining_minutes)
			if bool(claim.get("overdue", false)) else
			"DUE IN %dm" % maxi(0, remaining_minutes)
		)
		_claim_detail_label.text = "%s  ·  VALUE $%.2f  ·  crack risk %d%%" % [
			urgency, value_cents / 100.0, int(float(worker.get("estimated_crack_risk", 0.0)) * 100.0),
		]
	var assist := worker.get("peck_assist", {}) as Dictionary
	var assist_open := bool(assist.get("available", false)) and _interaction_enabled and _peck_assist_clock_running
	var assist_state := StringName(assist.get("window_state", &"locked"))
	var assist_remaining := maxi(0, int(assist.get("remaining", _snapshot.get("peck_assists_remaining", 0))))
	_peck_assist_button.set_meta("assist_open", assist_open)
	_peck_assist_button.disabled = not assist_open
	_peck_assist_button.tooltip_text = "%s\n%s" % [
		(
			"Resume at 1×, 3×, or 10× before stamping the live rhythm."
			if not _peck_assist_clock_running and bool(assist.get("available", false)) else
			String(assist.get("reason", "Select a working hen to synchronize peckwork."))
		),
		"A strong stamp accelerates this file and lowers shell risk; every stamp adds strain. %d/%d attention stamps remain." % [
			assist_remaining, int(assist.get("limit", _snapshot.get("peck_assist_limit", 3))),
		],
	]
	match assist_state:
		&"open":
			var timing_label := String(assist.get("timing_label", "CLEAN RHYTHM"))
			_peck_assist_button.text = "PECK  ·  %s  [E]" % ("GOLDEN" if "GOLDEN" in timing_label else "SYNC")
			_claim_progress_bar.add_theme_stylebox_override("fill", _compact_button_style(Color("d5aa4f"), Color("f1d681"), 0))
		&"not_ready":
			_peck_assist_button.text = "READY AT %d%%" % int(assist.get("window_start", 28.0))
			_claim_progress_bar.add_theme_stylebox_override("fill", _compact_button_style(Color("4d8d83"), Color("75b6a9"), 0))
		&"used":
			_peck_assist_button.text = "PRIORITY FILED  ·  x%d" % int(assist.get("streak", 0))
			_claim_progress_bar.add_theme_stylebox_override("fill", _compact_button_style(Color("769e75"), Color("a8c894"), 0))
		&"missed", &"passed":
			_peck_assist_button.text = "WINDOW MISSED"
			_claim_progress_bar.add_theme_stylebox_override("fill", _compact_button_style(Color("89645c"), Color("b57d6d"), 0))
		&"spent":
			_peck_assist_button.text = "ATTENTION SPENT"
		_:
			_peck_assist_button.text = "NO ACTIVE FILE" if claim.is_empty() else "PECK SUPPORT LOCKED"
	var assignment_is_credentialed := (
		assignment == &"auto"
		or assignment == specialty
		or (secondary_specialty != &"" and assignment == secondary_specialty)
	)
	_routing_hint_label.text = (
		"Matched specialty: faster peckwork and safer shells."
		if assignment_is_credentialed else
		"Out-of-specialty routing raises time and shell risk."
	)
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
	var can_assign := _interaction_enabled and phase == 1
	for lane in ASSIGNMENT_ORDER:
		var button := _assignment_buttons[lane]
		button.disabled = not can_assign
		button.theme_type_variation = &"SelectedChoiceButton" if lane == assignment else &"DecisionChoiceButton"
	var action_used := bool(_snapshot.get("personnel_action_used", false))
	var action_available := bool(_snapshot.get("personnel_action_available", false))
	var action_status := _snapshot.get("personnel_action_status", {}) as Dictionary
	var last_action := action_status.get("last_action", {}) as Dictionary
	var can_manage := can_assign and action_available and not action_used
	_check_in_status_label.text = (
		"FILED / %s" % String(last_action.get("worker_name", "FLOCK")).to_upper()
		if action_used else
		("CHECK-IN READY" if action_available and can_assign else "CHECK-IN LOCKED")
	)
	_check_in_status_label.tooltip_text = (
		String(last_action.get("outcome", "Today's flock check-in is already filed."))
		if action_used else
		String(action_status.get("reason", "Choose one personnel action for one hen this shift."))
	)
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
				" Check-in already filed this shift."
				if action_used else
				(" Feed Fund is short." if not affordable else " Uses the flock's one check-in this shift.")
			),
		]
		personnel_button.disabled = not can_manage or not affordable
	_refresh_first_clutch()


func _refresh_first_clutch() -> void:
	if _first_clutch_panel == null:
		return
	var coach_visible := bool(_first_clutch.get("visible", false))
	_first_clutch_panel.visible = coach_visible
	_refresh_first_clutch_return_action(coach_visible)
	if not coach_visible:
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
	_first_clutch_skip_button.visible = can_skip
	_first_clutch_skip_button.mouse_filter = (
		Control.MOUSE_FILTER_STOP if can_skip else Control.MOUSE_FILTER_IGNORE
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


func _worker_snapshot(worker_id: int) -> Dictionary:
	if worker_id < 0:
		return {}
	for worker_value in _snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return worker
	return {}


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
	var action_used := bool(_snapshot.get("personnel_action_used", false))
	var action_available := bool(_snapshot.get("personnel_action_available", false))
	if phase != 1 or action_used or not action_available:
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
	return String(LANE_NAMES.get(lane, String(lane).replace("_", " ").to_upper()))


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
