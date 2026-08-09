class_name InternshipProgramUI
extends VBoxContainer

signal onboard_requested(candidate_id: StringName)
signal assignment_requested(candidate_id: StringName, assignment_id: StringName)
signal review_requested(candidate_id: StringName, resolution_id: StringName)
signal presentation_context_changed

const COLOR_BRASS := Color("e7c56e")
const COLOR_TEAL := Color("73b5a7")
const COLOR_MUTED := Color("aeb8c4")
const COLOR_INK := Color("f2ead4")
const COLOR_PANEL := Color("14212b")
const COLOR_EDGE := Color("56766f")
const ASSIGNMENT_GLANCE_LABELS := {
	&"guided_shadow": "GUIDED  /  +1 FILE  /  SAFE",
	&"stretch_project": "STRETCH  /  +2 FILES  /  +1% RISK",
	&"culture_sprint": "CULTURE  /  -10% MORALE DRAIN",
}
const REVIEW_GLANCE_LABELS := {
	&"growth_extension": "EXTEND\n$1",
	&"recommendation_letter": "LETTER\nFREE",
	&"paid_fellowship": "HIRE\n$8+$2/D",
}
const PORTRAITS := {
	&"intern_lottie": preload("res://assets/npcs/intern-lottie-ledger/portraits/lottie-ledger_portrait_eager.png"),
	&"intern_chip": preload("res://assets/npcs/intern-chip-chirper/portraits/chip-chirper_portrait_optimistic.png"),
	&"intern_marigold": preload("res://assets/npcs/intern-marigold-memo/portraits/marigold-memo_portrait_helpful.png"),
	&"intern_tilly": preload("res://assets/npcs/intern-tilly-tabs/portraits/tilly-tabs_portrait_tech-hopeful.png"),
}

var _snapshot: Dictionary = {}
var _expanded := false
var _summary_label: Label
var _effects_label: Label
var _toggle_button: Button
var _candidate_list: VBoxContainer


func _ready() -> void:
	name = "InternshipProgramUI"
	add_theme_constant_override("separation", 7)
	_build_interface()
	_refresh()


func apply_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	if _summary_label == null:
		_build_interface()
	_refresh()


func set_expanded(expanded: bool) -> void:
	if _expanded == expanded:
		return
	_expanded = expanded
	_refresh()
	presentation_context_changed.emit()


func is_expanded() -> bool:
	return _expanded


func diagnostic_state() -> Dictionary:
	return {
		"visible": is_visible_in_tree(),
		"expanded": _expanded,
		"unlocked": bool(_snapshot.get("unlocked", false)),
		"active_count": int(_snapshot.get("active_count", 0)),
		"seat_limit": int(_snapshot.get("seat_limit", 1)),
		"fellow_count": int(_snapshot.get("fellow_count", 0)),
		"candidate_count": (_snapshot.get("candidates", []) as Array).size(),
		"effects": (_snapshot.get("effects", {}) as Dictionary).duplicate(true),
		"accessible_text": _accessible_text(),
	}


func _build_interface() -> void:
	if _summary_label != null:
		return
	var heading_row := HBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 8)
	add_child(heading_row)
	var heading := _make_label("BRIGHT-EYED ROTATION", 16, COLOR_BRASS)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading)
	var badge := _make_label("INTERNS", 10, COLOR_TEAL)
	heading_row.add_child(badge)

	_summary_label = _make_label("", 12, COLOR_INK)
	_summary_label.name = "InternshipProgramSummary"
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary_label)

	_effects_label = _make_label("", 10, COLOR_MUTED)
	_effects_label.name = "InternshipProgramEffects"
	_effects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_effects_label)

	_toggle_button = Button.new()
	_toggle_button.name = "InternshipProgramToggle"
	_toggle_button.custom_minimum_size.y = 40.0
	_toggle_button.focus_mode = Control.FOCUS_ALL
	_toggle_button.pressed.connect(func() -> void: set_expanded(not _expanded))
	add_child(_toggle_button)

	_candidate_list = VBoxContainer.new()
	_candidate_list.name = "InternshipCandidateList"
	_candidate_list.add_theme_constant_override("separation", 8)
	add_child(_candidate_list)


func _refresh() -> void:
	if _summary_label == null:
		return
	var unlocked := bool(_snapshot.get("unlocked", false))
	if not unlocked:
		var unlock_day := int(_snapshot.get("unlock_day", 2))
		_summary_label.text = "OPENS DAY %d" % unlock_day
		_summary_label.tooltip_text = (
			"The university partnership begins on Day %d. Corporate has already reserved the word opportunity."
			% unlock_day
		)
		_effects_label.text = "FILES +0  /  WORK +0%  /  RISK +0%  /  PAY $0/DAY"
		_effects_label.tooltip_text = (
			"No intern labor, capacity, quality risk, or fellowship cost is active."
		)
		_toggle_button.text = "COHORT OPENS DAY %d" % unlock_day
		_toggle_button.disabled = true
		_candidate_list.visible = false
		return
	var active_count := int(_snapshot.get("active_count", 0))
	var seat_limit := int(_snapshot.get("seat_limit", 1))
	var fellow_count := int(_snapshot.get("fellow_count", 0))
	_summary_label.text = "SEATS %d/%d  /  FELLOWS %d" % [
		active_count,
		seat_limit,
		fellow_count,
	]
	_summary_label.tooltip_text = "%d of %d supervised rotations; %d paid fellow%s." % [
		active_count,
		seat_limit,
		fellow_count,
		"" if fellow_count == 1 else "s",
	]
	var effects := _snapshot.get("effects", {}) as Dictionary
	_effects_label.text = (
		"FILES +%d  /  WORK +%.1f%%  /  RISK +%.1f%%  /  MORALE %d%%  /  PAY $%.2f/DAY"
		% [
			int(effects.get("claim_capacity_bonus", 0)),
			float(effects.get("work_basis_points", 0)) / 100.0,
			float(effects.get("crack_basis_points", 0)) / 100.0,
			roundi(float(effects.get("morale_drain_basis_points", 10_000)) / 100.0),
			float(effects.get("fellow_payroll_cents", 0)) / 100.0,
		]
	)
	_effects_label.tooltip_text = (
		"Filed cohort effect: +%d live-file capacity, +%.1f%% flock work, "
		+ "+%.1f%% shell risk, morale drain at %d%%, and $%.2f/day junior payroll."
	) % [
		int(effects.get("claim_capacity_bonus", 0)),
		float(effects.get("work_basis_points", 0)) / 100.0,
		float(effects.get("crack_basis_points", 0)) / 100.0,
		roundi(float(effects.get("morale_drain_basis_points", 10_000)) / 100.0),
		float(effects.get("fellow_payroll_cents", 0)) / 100.0,
	]
	_toggle_button.disabled = false
	_toggle_button.text = "CLOSE ROSTER" if _expanded else "VIEW ROSTER"
	_candidate_list.visible = _expanded
	if not _expanded:
		return
	for child in _candidate_list.get_children():
		child.queue_free()
	for candidate_value in _snapshot.get("candidates", []):
		if candidate_value is Dictionary:
			_candidate_list.add_child(_candidate_card(candidate_value as Dictionary))


func _candidate_card(candidate: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.name = "InternCard_%s" % String(candidate.get("candidate_id", "intern"))
	card.add_theme_stylebox_override("panel", _panel_style())
	card.tooltip_text = _candidate_profile_tooltip(candidate)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 8)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)

	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 7)
	column.add_child(identity_row)
	var portrait := TextureRect.new()
	portrait.name = "InternPortrait_%s" % String(candidate.get("candidate_id", "intern"))
	portrait.texture = PORTRAITS.get(
		StringName(String(candidate.get("portrait_id", &"intern_lottie")))
	) as Texture2D
	portrait.custom_minimum_size = Vector2(54.0, 64.0)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity_row.add_child(portrait)
	var identity_copy := VBoxContainer.new()
	identity_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_copy.add_theme_constant_override("separation", 2)
	identity_row.add_child(identity_copy)
	var name_label := _make_label(
		String(candidate.get("name", "OFFICE INTERN")).to_upper(),
		14,
		COLOR_INK,
	)
	identity_copy.add_child(name_label)
	var role_label := _make_label(String(candidate.get("role", "BRIGHT-EYED ROTATION")), 10, COLOR_TEAL)
	role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	identity_copy.add_child(role_label)
	var personality := _make_label(
		String(candidate.get("personality_title", "EAGER LEARNER")),
		10,
		COLOR_MUTED,
	)
	personality.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	personality.tooltip_text = _candidate_profile_tooltip(candidate)
	identity_copy.add_child(personality)

	var status := StringName(String(candidate.get("status", &"candidate")))
	var status_label := _make_label(_status_glance_copy(candidate), 11, _status_color(status))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.tooltip_text = _status_copy(candidate)
	column.add_child(status_label)
	match status:
		&"candidate":
			var button := Button.new()
			button.text = "ONBOARD  /  $3"
			button.custom_minimum_size.y = 40.0
			button.disabled = not bool(candidate.get("can_onboard", false))
			button.tooltip_text = _onboard_tooltip(candidate)
			var candidate_id := StringName(String(candidate.get("candidate_id", "")))
			button.name = "InternOnboard_%s" % String(candidate_id)
			button.pressed.connect(func() -> void: onboard_requested.emit(candidate_id))
			column.add_child(button)
		&"active":
			_add_assignment_controls(column, candidate)
		&"review":
			_add_review_controls(column, candidate)
	return card


func _add_assignment_controls(column: VBoxContainer, candidate: Dictionary) -> void:
	var selector := OptionButton.new()
	selector.name = "InternAssignment_%s" % String(candidate.get("candidate_id", "intern"))
	selector.custom_minimum_size.y = 38.0
	var selected_id := StringName(String(candidate.get("assignment_id", &"guided_shadow")))
	var selected_index := 0
	var index := 0
	for assignment_value in _snapshot.get("assignments", []):
		if not assignment_value is Dictionary:
			continue
		var assignment := assignment_value as Dictionary
		var assignment_id := StringName(String(assignment.get("id", "")))
		selector.add_item(_assignment_glance_label(assignment))
		selector.set_item_metadata(index, assignment_id)
		selector.set_item_tooltip(
			index,
			"%s\n%s" % [
				String(assignment.get("promise", "")),
				String(assignment.get("disclosure", "")),
			],
		)
		if assignment_id == selected_id:
			selected_index = index
		index += 1
	selector.select(selected_index)
	selector.disabled = not bool(_snapshot.get("planning_open", false))
	var candidate_id := StringName(String(candidate.get("candidate_id", "")))
	selector.item_selected.connect(
		func(item_index: int) -> void:
			assignment_requested.emit(
				candidate_id,
				StringName(String(selector.get_item_metadata(item_index))),
			)
	)
	column.add_child(selector)


func _add_review_controls(column: VBoxContainer, candidate: Dictionary) -> void:
	var note := _make_label(
		"TERM COMPLETE  /  CHOOSE NEXT STEP",
		10,
		COLOR_BRASS,
	)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(note)
	var candidate_id := StringName(String(candidate.get("candidate_id", "")))
	var choice_grid := GridContainer.new()
	choice_grid.name = "InternReviewChoices_%s" % String(candidate_id)
	choice_grid.columns = 3
	choice_grid.add_theme_constant_override("h_separation", 5)
	column.add_child(choice_grid)
	for review_value in _snapshot.get("reviews", []):
		if not review_value is Dictionary:
			continue
		var review := review_value as Dictionary
		var review_id := StringName(String(review.get("id", "")))
		var button := Button.new()
		button.name = "InternReview_%s_%s" % [
			String(candidate_id),
			String(review_id),
		]
		button.text = _review_glance_label(review)
		button.custom_minimum_size.y = 48.0
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = (
			not bool(_snapshot.get("planning_open", false))
			or not bool(review.get("available", true))
			or not bool(review.get("affordable", true))
		)
		button.tooltip_text = "%s\n%s%s" % [
			String(review.get("promise", "")),
			String(review.get("disclosure", "")),
			_review_held_suffix(review),
		]
		button.pressed.connect(
			func() -> void: review_requested.emit(candidate_id, review_id)
		)
		choice_grid.add_child(button)


func _status_copy(candidate: Dictionary) -> String:
	var status := StringName(String(candidate.get("status", &"candidate")))
	match status:
		&"candidate":
			return "AVAILABLE  /  %s" % String(candidate.get("hope", "Ready to contribute."))
		&"active":
			return "ACTIVE ROTATION  /  %d shift%s remaining  /  %s" % [
				int(candidate.get("term_remaining", 0)),
				"" if int(candidate.get("term_remaining", 0)) == 1 else "s",
				String(candidate.get("hope", "")),
			]
		&"review":
			return "AWAITING FUTURE-OPPORTUNITY REVIEW"
		&"completed":
			return "PROGRAM ALUM  /  Recommendation issued; no perch attached."
		&"fellow":
			return "PAID FELLOW  /  A junior post finally exists in the ledger."
	return "UNFILED"


func _status_glance_copy(candidate: Dictionary) -> String:
	var status := StringName(String(candidate.get("status", &"candidate")))
	match status:
		&"candidate":
			return "AVAILABLE  /  $3  /  3 SHIFTS"
		&"active":
			return "ACTIVE  /  %d SHIFT%s LEFT" % [
				int(candidate.get("term_remaining", 0)),
				"" if int(candidate.get("term_remaining", 0)) == 1 else "S",
			]
		&"review":
			return "REVIEW DUE"
		&"completed":
			return "ALUM  /  RECOMMENDED"
		&"fellow":
			return "PAID FELLOW  /  +1 FILE  /  +1% WORK  /  $2/DAY"
	return "UNFILED"


func _candidate_profile_tooltip(candidate: Dictionary) -> String:
	return "%s. %s %s" % [
		String(candidate.get("personality", "")),
		String(candidate.get("hope", "")),
		String(candidate.get("blind_spot", "")),
	]


func _onboard_tooltip(candidate: Dictionary) -> String:
	var reason := String(candidate.get("onboard_reason", ""))
	var exact := (
		"Start a three-shift supervised rotation for $3.00. The default Guided "
		+ "File Shadow adds +1 live-file capacity and +1% flock work with no "
		+ "shell-risk change."
	)
	return exact if reason.is_empty() else "%s\nHELD: %s" % [exact, reason]


func _assignment_glance_label(assignment: Dictionary) -> String:
	var assignment_id := StringName(String(assignment.get("id", "")))
	return String(ASSIGNMENT_GLANCE_LABELS.get(
		assignment_id,
		String(assignment.get("label", "LEARNING ROTATION")),
	))


func _review_glance_label(review: Dictionary) -> String:
	var review_id := StringName(String(review.get("id", "")))
	return String(REVIEW_GLANCE_LABELS.get(
		review_id,
		String(review.get("label", "FILE TERM REVIEW")),
	))


func _review_held_suffix(review: Dictionary) -> String:
	if not bool(_snapshot.get("planning_open", false)):
		return "\nHELD: Term reviews can only be filed during planning or review."
	if not bool(review.get("available", true)):
		return "\nHELD: The single paid fellowship perch is already occupied."
	if not bool(review.get("affordable", true)):
		return "\nHELD: The free Feed Fund cannot cover this filing and payroll reserve."
	return ""


func _status_color(status: StringName) -> Color:
	return COLOR_TEAL if status in [&"active", &"fellow"] else COLOR_MUTED


func _accessible_text() -> String:
	if _summary_label == null:
		return ""
	var lines := PackedStringArray([
		"BRIGHT-EYED ROTATION",
		_summary_label.tooltip_text if not _summary_label.tooltip_text.is_empty() else _summary_label.text,
		_effects_label.tooltip_text if not _effects_label.tooltip_text.is_empty() else _effects_label.text,
	])
	if _expanded:
		for candidate_value in _snapshot.get("candidates", []):
			if candidate_value is Dictionary:
				var candidate := candidate_value as Dictionary
				var status := StringName(String(candidate.get("status", &"candidate")))
				lines.append("%s. %s. %s. %s" % [
					String(candidate.get("name", "Office Intern")),
					String(candidate.get("role", "Bright-Eyed Rotation")),
					_candidate_profile_tooltip(candidate),
					_status_copy(candidate),
				])
				match status:
					&"candidate":
						lines.append(_onboard_tooltip(candidate))
					&"active":
						for assignment_value in _snapshot.get("assignments", []):
							if assignment_value is Dictionary:
								var assignment := assignment_value as Dictionary
								lines.append("%s%s. %s %s" % [
									String(assignment.get("label", "Learning Rotation")),
									" selected" if StringName(String(assignment.get("id", ""))) == StringName(String(candidate.get("assignment_id", ""))) else "",
									String(assignment.get("promise", "")),
									String(assignment.get("disclosure", "")),
								])
					&"review":
						for review_value in _snapshot.get("reviews", []):
							if review_value is Dictionary:
								var review := review_value as Dictionary
								lines.append("%s. %s %s%s" % [
									String(review.get("label", "Term Review")),
									String(review.get("promise", "")),
									String(review.get("disclosure", "")),
									_review_held_suffix(review),
								])
	return "; ".join(lines)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.border_color = COLOR_EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
