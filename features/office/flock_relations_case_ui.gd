class_name FlockRelationsCaseUI
extends VBoxContainer

## Compact labor-case controls hosted inside the existing Flockwatch ledger.
##
## This view never reconstructs case economics. Every action, price, gate, and
## disabled reason comes from the authoritative simulation snapshot.

signal action_requested(case_id: int, action_id: StringName)

const COLOR_BRASS := Color("e7c56e")
const COLOR_PAPER := Color("ddd2b8")
const COLOR_MUTED := Color("aeb8c4")
const COLOR_MULBERRY := Color("9d7890")
const COLOR_TEAL := Color("73b5a7")
const COLOR_RUST := Color("d68a68")

var _snapshot: Dictionary = {}
var _status_label: Label
var _terms_label: Label
var _case_list: VBoxContainer
var _last_resolution_label: Label


func _ready() -> void:
	name = "FlockRelationsCaseUI"
	add_theme_constant_override("separation", 6)
	_build_interface()
	_refresh()


func apply_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_refresh()


func _build_interface() -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	add_child(header)

	var title := _make_label("FLOCK RELATIONS", 12, COLOR_BRASS)
	title.name = "FlockRelationsTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_status_label = _make_label("CASE INTAKE", 10, COLOR_MULBERRY)
	_status_label.name = "FlockRelationsStatus"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_status_label)

	_terms_label = _make_label("", 10, COLOR_MUTED)
	_terms_label.name = "FlockRelationsTerms"
	_terms_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_terms_label)

	_case_list = VBoxContainer.new()
	_case_list.name = "FlockRelationsCaseList"
	_case_list.add_theme_constant_override("separation", 6)
	_case_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_case_list)

	_last_resolution_label = _make_label("", 10, COLOR_TEAL)
	_last_resolution_label.name = "FlockRelationsLastResolution"
	_last_resolution_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_last_resolution_label.visible = false
	add_child(_last_resolution_label)


func _refresh() -> void:
	if _status_label == null:
		return
	var relations := _relations_snapshot()
	var level := maxi(0, int(relations.get("level", 0)))
	visible = level > 0
	if not visible:
		return

	var capacity := maxi(0, int(relations.get("capacity", level)))
	var open_cases := _case_entries(relations)
	var open_count := maxi(0, int(relations.get("open_case_count", open_cases.size())))
	var resolution_limit := maxi(0, int(relations.get("resolution_limit", level)))
	var used := clampi(int(relations.get("resolutions_used_today", 0)), 0, resolution_limit)
	_status_label.text = "OPEN %d / %d" % [open_count, capacity]
	_status_label.add_theme_color_override(
		"font_color",
		COLOR_RUST if open_count >= capacity and capacity > 0 else COLOR_MULBERRY,
	)
	_terms_label.text = (
		"LEVEL %d | REVIEW AUTHORIZATIONS %d / %d USED\n"
		+ "Unresolved files carry compliance, solidarity, and grievance pressure into the next closing."
	) % [level, used, resolution_limit]

	for child in _case_list.get_children():
		child.queue_free()
	if open_cases.is_empty():
		var clear_label := _make_label(
			"NO OPEN HEN FILES | Intake remains available when documented strain crosses the filing threshold.",
			10,
			COLOR_TEAL,
		)
		clear_label.name = "FlockRelationsNoOpenCases"
		clear_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_case_list.add_child(clear_label)
	else:
		for case_record in open_cases:
			_case_list.add_child(_build_case_card(case_record))

	var last_resolution_value: Variant = relations.get("last_resolution", {})
	var last_resolution := (
		last_resolution_value as Dictionary
		if last_resolution_value is Dictionary else
		{}
	)
	_last_resolution_label.visible = not last_resolution.is_empty()
	if _last_resolution_label.visible:
		_last_resolution_label.text = _resolution_copy(last_resolution)


func _build_case_card(case_record: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.name = "FlockRelationsCase_%s" % _safe_suffix(str(case_record.get("case_id", "unfiled")))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _card_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(column)

	var worker_name := String(case_record.get("worker_name", "UNFILED HEN")).to_upper()
	var title := String(case_record.get("title", "WORKPLACE GRIEVANCE")).to_upper()
	var severity := clampi(int(case_record.get("severity", 1)), 1, 3)
	var filed_day := maxi(0, int(case_record.get("filed_day", 0)))
	var heading := _make_label("%s | %s" % [worker_name, title], 11, COLOR_PAPER)
	heading.name = "CaseHeading"
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(heading)

	var metadata := _make_label(
		"SEVERITY %d | FILED DAY %d | CASE %s" % [
			severity,
			filed_day,
			str(case_record.get("docket_id", case_record.get("case_id", "UNFILED"))),
		],
		9,
		COLOR_RUST if severity >= 3 else COLOR_MUTED,
	)
	metadata.name = "CaseMetadata"
	metadata.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(metadata)

	var evidence := String(case_record.get("evidence_summary", "Documented workplace strain."))
	var evidence_label := _make_label(evidence, 10, COLOR_MUTED)
	evidence_label.name = "CaseEvidence"
	evidence_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(evidence_label)

	var actions := HFlowContainer.new()
	actions.name = "CaseActions"
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_theme_constant_override("v_separation", 6)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(actions)

	var options_value: Variant = case_record.get("action_options", [])
	if options_value is Array:
		for option_value in options_value as Array:
			if option_value is Dictionary:
				actions.add_child(_build_action_button(case_record, option_value as Dictionary))
	if actions.get_child_count() == 0:
		var held := _make_label(
			"CASE ACTIONS HELD | Reopen the review file for authoritative terms.",
			9,
			COLOR_RUST,
		)
		held.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		actions.add_child(held)
	return card


func _build_action_button(case_record: Dictionary, option: Dictionary) -> Button:
	var action_id := StringName(String(option.get("action_id", "")))
	var case_id := int(case_record.get("case_id", 0))
	var label := String(option.get("label", String(action_id))).to_upper()
	var cost_cents := maxi(0, int(option.get("cost_cents", 0)))
	var enabled := bool(option.get("enabled", false)) and action_id != &"" and case_id > 0
	var reason := String(option.get("reason", "This case action is currently held."))
	var preview := String(option.get("effect_preview", "Authoritative effects will be filed in the resolution receipt."))

	var button := Button.new()
	button.name = "FlockRelationsAction_%s" % _safe_suffix(String(action_id))
	button.theme_type_variation = &"PrimaryButton" if action_id != &"file_pip" else &"DangerButton"
	button.custom_minimum_size = Vector2(112.0, 38.0)
	button.text = "%s\n%s" % [label, "NO FUND COST" if cost_cents == 0 else "$%.2f" % (cost_cents / 100.0)]
	button.disabled = not enabled
	button.tooltip_text = (
		"%s\n%s" % [preview, reason]
		if not enabled else
		"%s\nThis authorization will be entered immediately in the permanent case ledger." % preview
	)
	button.set_meta("case_id", case_id)
	button.set_meta("action_id", action_id)
	button.pressed.connect(func() -> void: action_requested.emit(case_id, action_id))
	return button


func _relations_snapshot() -> Dictionary:
	var value: Variant = _snapshot.get("flock_relations", {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _case_entries(relations: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var value: Variant = relations.get("open_cases", [])
	if value is Array:
		for entry in value as Array:
			if entry is Dictionary:
				result.append((entry as Dictionary).duplicate(true))
	return result


func _resolution_copy(resolution: Dictionary) -> String:
	var worker_name := String(resolution.get("worker_name", "A HEN")).to_upper()
	var action_label := String(resolution.get("action_label", resolution.get("action_id", "RESOLVED"))).to_upper()
	var cost_cents := maxi(0, int(resolution.get("cost_cents", 0)))
	var outcome := String(resolution.get("outcome", "The case ledger was updated."))
	return "LAST FILED | %s | %s | %s\n%s" % [
		worker_name,
		action_label,
		"NO FUND COST" if cost_cents == 0 else "$%.2f" % (cost_cents / 100.0),
		outcome,
	]


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1d2028e8")
	style.border_color = Color("55404f")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style


func _make_label(copy: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _safe_suffix(value: String) -> String:
	var result := ""
	for character in value:
		result += character if character.is_valid_identifier() or character.is_valid_int() else "_"
	return result
