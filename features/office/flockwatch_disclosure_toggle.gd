class_name FlockwatchDisclosureToggle
extends Button

## Focus-safe progressive disclosure for dense Flockwatch filing sections.
##
## The toggle controls existing sibling Controls instead of adopting or rebuilding
## them. That preserves every authored action's node identity, signal connection,
## metadata, parent, and order while still allowing a page to open on a concise
## summary. If a focused descendant is about to be hidden, focus returns here.

signal disclosure_changed(expanded: bool)

var _label := "FILE"
var _summary := ""
var _targets: Array[Control] = []
var _expanded := false


func _ready() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size.y = maxf(custom_minimum_size.y, 34.0)
	if not toggled.is_connected(_on_toggled):
		toggled.connect(_on_toggled)
	_apply_state(false)


func configure(
	label: String,
	summary: String,
	targets: Array[Control],
	expanded: bool = false,
) -> void:
	_label = label.strip_edges().to_upper()
	if _label.is_empty():
		_label = "FILE"
	_summary = summary.strip_edges().to_upper()
	_targets = targets.duplicate()
	set_expanded(expanded, false)


func set_summary(summary: String) -> void:
	_summary = summary.strip_edges().to_upper()
	_refresh_copy()


func set_expanded(expanded: bool, recover_focus: bool = true) -> void:
	if recover_focus and not expanded:
		_recover_focus_from_targets()
	_expanded = expanded
	set_pressed_no_signal(expanded)
	_apply_state(false)


func is_expanded() -> bool:
	return _expanded


func controlled_targets() -> Array[Control]:
	return _targets.duplicate()


func _on_toggled(expanded: bool) -> void:
	if not expanded:
		_recover_focus_from_targets()
	_expanded = expanded
	_apply_state(true)


func _apply_state(emit_change: bool) -> void:
	for target: Control in _targets:
		if is_instance_valid(target):
			target.visible = _expanded
	_refresh_copy()
	if emit_change:
		disclosure_changed.emit(_expanded)


func _refresh_copy() -> void:
	var verb := "HIDE" if _expanded else "REVIEW"
	text = "%s %s" % [verb, _label]
	if not _summary.is_empty():
		text += "  /  %s" % _summary
	tooltip_text = (
		"Collapse %s and return focus here." % _label.to_lower()
		if _expanded else
		"Expand %s without leaving this Flockwatch page." % _label.to_lower()
	)


func _recover_focus_from_targets() -> void:
	if not is_inside_tree():
		return
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner == null:
		return
	for target: Control in _targets:
		if not is_instance_valid(target):
			continue
		if focus_owner == target or target.is_ancestor_of(focus_owner):
			grab_focus()
			return
