class_name CharacterDialogueUI
extends Control

## Character cutout used to turn exact management state into one readable human
## beat. Ambient cards leave the floor live; visual-novel asides deliberately
## hand input and clock ownership to Office until they are filed away.

signal dialogue_presented(entry: Dictionary)
signal dialogue_dismissed(entry_id: StringName)

const ManagementTheme := preload("res://features/office/management_ui_theme.gd")
const PORTRAITS := {
	&"mabel": preload("res://assets/npcs/mabel/portraits/mabel_portrait_anxious.png"),
	&"pip": preload("res://assets/npcs/pip/portraits/pip_portrait_skeptical.png"),
	&"henrietta": preload("res://assets/npcs/henrietta/portraits/henrietta_portrait_anxious.png"),
	&"dot": preload("res://assets/npcs/dot/portraits/dot_portrait_knowing.png"),
	&"agnes": preload("res://assets/npcs/agnes/portraits/agnes_portrait_methodical.png"),
	&"beatrice": preload("res://assets/npcs/beatrice/portraits/beatrice_portrait_gentle-rebel.png"),
	&"cornelius": preload("res://assets/npcs/cornelius-claimwell/portraits/cornelius-claimwell_portrait_weary.png"),
	&"bramwell": preload("res://assets/npcs/bramwell-beakley/portraits/bramwell-beakley_portrait_quota.png"),
	&"prudence": preload("res://assets/npcs/prudence-peckworth/portraits/prudence-peckworth_portrait_compliance.png"),
	&"clover": preload("res://assets/npcs/clover-crowsby/portraits/clover-crowsby_portrait_culture.png"),
	&"pivot": preload("res://assets/npcs/pivot-strutters/portraits/pivot-strutters_portrait_reorg.png"),
	&"byte": preload("res://assets/npcs/byte-bantam/portraits/byte-bantam_portrait_automation.png"),
	&"intern_lottie": preload("res://assets/npcs/intern-lottie-ledger/portraits/lottie-ledger_portrait_eager.png"),
	&"intern_chip": preload("res://assets/npcs/intern-chip-chirper/portraits/chip-chirper_portrait_optimistic.png"),
	&"intern_marigold": preload("res://assets/npcs/intern-marigold-memo/portraits/marigold-memo_portrait_helpful.png"),
	&"intern_tilly": preload("res://assets/npcs/intern-tilly-tabs/portraits/tilly-tabs_portrait_tech-hopeful.png"),
}

const MAX_QUEUE := 6
const DESKTOP_WIDTH := 1160.0
const DESKTOP_HEIGHT := 490.0
const COMPACT_BREAKPOINT := 760.0
const AMBIENT_WIDTH := 450.0
const AMBIENT_HEIGHT := 132.0
const COLOR_PANEL := Color("111b24")
const COLOR_PANEL_EDGE := Color("d2ae61")
const COLOR_INK := Color("f2ead4")
const COLOR_MUTED := Color("aeb8c4")
const COLOR_BRASS := Color("e7c56e")
const COLOR_TEAL := Color("79b9ab")

var _queue: Array[Dictionary] = []
var _seen_ids: Dictionary[StringName, bool] = {}
var _active: Dictionary = {}
var _remaining_seconds := 0.0
var _suspended := false
var _reduced_motion := false
var _layout_refresh_pending := false

var _scrim: ColorRect
var _panel: PanelContainer
var _content_margin: MarginContainer
var _row: GridContainer
var _portrait_frame: PanelContainer
var _portrait: TextureRect
var _copy: VBoxContainer
var _channel_label: Label
var _name_label: Label
var _role_label: Label
var _quote_label: Label
var _action_rail: HFlowContainer
var _exact_note: Label
var _file_button: Button


func _ready() -> void:
	name = "CharacterDialogueUI"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = ManagementTheme.create_theme()
	resized.connect(_apply_responsive_layout)
	_build_interface()
	visible = true
	_scrim.visible = false
	_panel.visible = false
	_apply_responsive_layout()
	set_process(true)


func enqueue_dialogue(entry: Dictionary) -> bool:
	if not _valid_entry(entry):
		return false
	var entry_id := StringName(String(entry.get("id", "")))
	if _seen_ids.has(entry_id):
		return false
	_seen_ids[entry_id] = true
	if _active.is_empty() and not _suspended:
		_present(entry)
		return true
	if _queue.size() >= MAX_QUEUE:
		return false
	_queue.append(entry.duplicate(true))
	return true


func enqueue_many(entries: Array[Dictionary]) -> int:
	var accepted := 0
	for entry in entries:
		if enqueue_dialogue(entry):
			accepted += 1
	return accepted


func dismiss_current() -> void:
	if _active.is_empty():
		return
	var dismissed_id := StringName(String(_active.get("id", "")))
	_active.clear()
	_remaining_seconds = 0.0
	_panel.visible = false
	_scrim.visible = false
	dialogue_dismissed.emit(dismissed_id)
	_present_next_if_available()


func set_suspended(suspended: bool) -> void:
	if _suspended == suspended:
		return
	_suspended = suspended
	if _suspended:
		_panel.visible = false
		_scrim.visible = false
	elif not _active.is_empty():
		_panel.visible = true
		_scrim.visible = not _is_ambient_active()
	else:
		_present_next_if_available()


func set_reduced_motion(reduced_motion: bool) -> void:
	_reduced_motion = reduced_motion


func clear_session() -> void:
	_queue.clear()
	_seen_ids.clear()
	_active.clear()
	_remaining_seconds = 0.0
	if _panel != null:
		_panel.visible = false
	if _scrim != null:
		_scrim.visible = false


func has_seen(entry_id: StringName) -> bool:
	return _seen_ids.has(entry_id)


func active_entry() -> Dictionary:
	return _active.duplicate(true)


func queued_count() -> int:
	return _queue.size()


func is_presenting() -> bool:
	return _panel != null and _panel.visible and not _active.is_empty()


func is_blocking() -> bool:
	return is_presenting() and not _is_ambient_active()


func has_blocking_dialogue() -> bool:
	return not _active.is_empty() and not _is_ambient_active()


func accessibility_text() -> String:
	if _active.is_empty():
		return ""
	return "%s; %s; %s" % [
		String(_active.get("channel", "FLOOR CHAT")),
		String(_active.get("speaker_name", "Office Hen")),
		String(_active.get("text", "")),
	]


func diagnostic_state() -> Dictionary:
	return {
		"visible": _panel != null and _panel.visible,
		"suspended": _suspended,
		"active_id": StringName(String(_active.get("id", ""))),
		"speaker_id": StringName(String(_active.get("speaker_id", ""))),
		"speaker_name": String(_active.get("speaker_name", "")),
		"channel": StringName(String(_active.get("channel", ""))),
		"text": String(_active.get("text", "")),
		"queued_count": _queue.size(),
		"remaining_seconds": maxf(0.0, _remaining_seconds),
		"accessible_text": accessibility_text(),
		"presentation_mode": _presentation_mode(),
		"panel_rect": _panel.get_global_rect() if _panel != null else Rect2(),
	}


func _process(delta: float) -> void:
	if _suspended or _active.is_empty() or _panel == null or not _panel.visible:
		return
	_remaining_seconds -= delta
	if _remaining_seconds <= 0.0:
		dismiss_current()


func _build_interface() -> void:
	_scrim = ColorRect.new()
	_scrim.name = "CharacterDialogueScrim"
	_scrim.color = Color(0.025, 0.045, 0.06, 0.66)
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_scrim)

	_panel = PanelContainer.new()
	_panel.name = "CharacterDialoguePanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(COLOR_PANEL, COLOR_PANEL_EDGE),
	)
	_panel.minimum_size_changed.connect(_queue_responsive_layout)
	add_child(_panel)

	_content_margin = MarginContainer.new()
	_content_margin.name = "CharacterDialogueMargin"
	_content_margin.add_theme_constant_override("margin_left", 22)
	_content_margin.add_theme_constant_override("margin_right", 22)
	_content_margin.add_theme_constant_override("margin_top", 18)
	_content_margin.add_theme_constant_override("margin_bottom", 18)
	_panel.add_child(_content_margin)

	_row = GridContainer.new()
	_row.name = "CharacterDialogueRow"
	_row.columns = 2
	_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_row.add_theme_constant_override("h_separation", 24)
	_row.add_theme_constant_override("v_separation", 12)
	_content_margin.add_child(_row)

	_portrait_frame = PanelContainer.new()
	_portrait_frame.name = "CharacterDialoguePortraitFrame"
	_portrait_frame.custom_minimum_size = Vector2(400.0, 440.0)
	_portrait_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_portrait_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("18252f"), Color("6b847e"), 8, 1),
	)
	_row.add_child(_portrait_frame)

	_portrait = TextureRect.new()
	_portrait.name = "CharacterDialoguePortrait"
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_child(_portrait)

	_copy = VBoxContainer.new()
	_copy.name = "CharacterDialogueCopy"
	_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_copy.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_copy.add_theme_constant_override("separation", 6)
	_row.add_child(_copy)

	_channel_label = _make_label("PRIVATE ASIDE", 12, COLOR_TEAL)
	_channel_label.name = "CharacterDialogueChannel"
	_channel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_copy.add_child(_channel_label)

	_name_label = _make_label("MABEL", 29, COLOR_INK)
	_name_label.name = "CharacterDialogueSpeaker"
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_copy.add_child(_name_label)

	_role_label = _make_label("APPEALS  /  BRIGHT-EYED", 12, COLOR_MUTED)
	_role_label.name = "CharacterDialogueRole"
	_role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_copy.add_child(_role_label)

	_quote_label = _make_label("", 24, COLOR_INK)
	_quote_label.name = "CharacterDialogueQuote"
	_quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quote_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_quote_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_quote_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_copy.add_child(_quote_label)

	_action_rail = HFlowContainer.new()
	_action_rail.name = "CharacterDialogueActionRail"
	_action_rail.alignment = FlowContainer.ALIGNMENT_END
	_action_rail.add_theme_constant_override("h_separation", 6)
	_action_rail.add_theme_constant_override("v_separation", 3)
	_copy.add_child(_action_rail)

	_exact_note = _make_label("Exact filing remains in Flockwatch  •  Enter to continue", 10, COLOR_MUTED)
	_exact_note.name = "CharacterDialogueExactNote"
	_exact_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exact_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_exact_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action_rail.add_child(_exact_note)

	_file_button = Button.new()
	_file_button.name = "CharacterDialogueDismiss"
	_file_button.text = "FILE AWAY"
	_file_button.focus_mode = Control.FOCUS_ALL
	_file_button.custom_minimum_size = Vector2(154.0, 40.0)
	_file_button.autowrap_mode = TextServer.AUTOWRAP_OFF
	_file_button.clip_text = true
	_file_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_file_button.tooltip_text = "Dismiss this character aside. The exact event remains in the Shift Record."
	_file_button.pressed.connect(dismiss_current)
	_action_rail.add_child(_file_button)


func _present(entry: Dictionary) -> void:
	_active = entry.duplicate(true)
	_remaining_seconds = clampf(float(_active.get("hold_seconds", 9.0)), 5.0, 15.0)
	var portrait_id := StringName(String(_active.get("portrait_id", "")))
	_portrait.texture = PORTRAITS.get(portrait_id) as Texture2D
	_channel_label.text = String(_active.get("channel", "FLOOR CHAT")).to_upper()
	_name_label.text = String(_active.get("speaker_name", "Office Hen")).to_upper()
	_role_label.text = String(_active.get("speaker_role", "EGG YIELD BUREAU")).to_upper()
	_quote_label.text = "“%s”" % String(_active.get("text", "")).strip_edges()
	_file_button.text = (
		"CONTINUE  •  %d" % _queue.size()
		if not _queue.is_empty() else
		"FILE AWAY"
	)
	_apply_presentation_mode()
	_apply_responsive_layout()
	if not _suspended:
		_scrim.visible = not _is_ambient_active()
		_panel.visible = true
		if not _reduced_motion:
			_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
			var tween := create_tween()
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(_panel, "modulate:a", 1.0, 0.16)
		else:
			_panel.modulate = Color.WHITE
	dialogue_presented.emit(_active.duplicate(true))


func _present_next_if_available() -> void:
	if _suspended or not _active.is_empty() or _queue.is_empty():
		return
	var next := _queue.pop_front() as Dictionary
	_present(next)


func _apply_responsive_layout() -> void:
	if _panel == null:
		return
	var viewport_size := size
	if _is_ambient_active():
		var ambient_margin := 10.0 if viewport_size.x <= 520.0 else 16.0
		var ambient_width := minf(AMBIENT_WIDTH, viewport_size.x - ambient_margin * 2.0)
		var ambient_height := minf(
			maxf(AMBIENT_HEIGHT, _panel.get_combined_minimum_size().y),
			viewport_size.y - ambient_margin * 2.0,
		)
		_panel.anchor_left = 1.0
		_panel.anchor_top = 1.0
		_panel.anchor_right = 1.0
		_panel.anchor_bottom = 1.0
		_panel.offset_left = -ambient_margin - ambient_width
		_panel.offset_right = -ambient_margin
		_panel.offset_top = -ambient_margin - ambient_height
		_panel.offset_bottom = -ambient_margin
		_row.columns = 1
		_content_margin.add_theme_constant_override("margin_left", 14)
		_content_margin.add_theme_constant_override("margin_right", 14)
		_content_margin.add_theme_constant_override("margin_top", 11)
		_content_margin.add_theme_constant_override("margin_bottom", 11)
		return
	var compact := viewport_size.x < COMPACT_BREAKPOINT
	var narrow := viewport_size.x <= 520.0
	var margin := 10.0 if narrow else (16.0 if compact else 24.0)
	var panel_width := minf(DESKTOP_WIDTH, viewport_size.x - margin * 2.0)
	var base_panel_height := minf(
		viewport_size.y - margin * 2.0,
		clampf(viewport_size.y * (0.94 if narrow else 0.68), 430.0, DESKTOP_HEIGHT),
	)
	var required_panel_height := _panel.get_combined_minimum_size().y
	var panel_height := minf(
		maxf(base_panel_height, required_panel_height),
		viewport_size.y - margin * 2.0,
	)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -panel_width * 0.5
	_panel.offset_right = panel_width * 0.5
	_panel.offset_top = -margin - panel_height
	_panel.offset_bottom = -margin
	if _row != null:
		_row.columns = 1 if narrow else 2
	if _content_margin != null:
		var content_margin := 8 if narrow else 18
		_content_margin.add_theme_constant_override("margin_left", content_margin)
		_content_margin.add_theme_constant_override("margin_right", content_margin)
		_content_margin.add_theme_constant_override("margin_top", content_margin)
		_content_margin.add_theme_constant_override("margin_bottom", content_margin)
	if _portrait_frame != null:
		_portrait_frame.custom_minimum_size = (
			Vector2(0.0, 108.0) if narrow else Vector2(400.0, 440.0)
		)
		_portrait_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _file_button != null:
		_file_button.custom_minimum_size.x = 180.0 if narrow else 154.0
	if _exact_note != null:
		_exact_note.custom_minimum_size.x = 0.0
		_exact_note.visible = not narrow


func _unhandled_key_input(event: InputEvent) -> void:
	if (
		not _suspended
		and is_presenting()
		and not _is_ambient_active()
		and (
			event.is_action_pressed("ui_accept")
			or event.keycode in [KEY_ENTER, KEY_KP_ENTER]
		)
	):
		dismiss_current()
		get_viewport().set_input_as_handled()


func _queue_responsive_layout() -> void:
	if _layout_refresh_pending or not is_inside_tree():
		return
	_layout_refresh_pending = true
	call_deferred("_refresh_responsive_layout")


func _refresh_responsive_layout() -> void:
	_layout_refresh_pending = false
	_apply_responsive_layout()


func _presentation_mode() -> StringName:
	return StringName(String(_active.get("presentation_mode", &"visual_novel")))


func _is_ambient_active() -> bool:
	return not _active.is_empty() and _presentation_mode() == &"ambient"


func _apply_presentation_mode() -> void:
	var ambient := _is_ambient_active()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE if ambient else Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(
			Color("13232a") if ambient else COLOR_PANEL,
			COLOR_TEAL if ambient else COLOR_PANEL_EDGE,
			8 if ambient else 10,
			1 if ambient else 2,
		),
	)
	_portrait_frame.visible = not ambient
	_role_label.visible = not ambient
	_exact_note.visible = not ambient
	_file_button.visible = not ambient
	_channel_label.add_theme_font_size_override("font_size", 10 if ambient else 12)
	_name_label.add_theme_font_size_override("font_size", 18 if ambient else 29)
	_quote_label.add_theme_font_size_override("font_size", 16 if ambient else 24)


func _valid_entry(entry: Dictionary) -> bool:
	if entry.is_empty():
		return false
	var entry_id := StringName(String(entry.get("id", "")))
	var portrait_id := StringName(String(entry.get("portrait_id", "")))
	return (
		not entry_id.is_empty()
		and PORTRAITS.has(portrait_id)
		and not String(entry.get("speaker_name", "")).strip_edges().is_empty()
		and not String(entry.get("text", "")).strip_edges().is_empty()
	)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _panel_style(
	color: Color,
	border_color: Color,
	radius: int = 10,
	border_width: int = 2,
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.36)
	style.shadow_size = 6
	return style
