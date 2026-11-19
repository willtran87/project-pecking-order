class_name FlockTiesUI
extends Control

signal pair_selected(worker_id: int, partner_id: int)
signal action_requested(worker_id: int, partner_id: int, action: String)
signal closed
const Portraits := preload("res://features/office/character_dialogue_ui.gd")
const SPEAKERS := [&"mabel", &"pip", &"henrietta", &"dot", &"agnes", &"beatrice"]
var _panel: PanelContainer
var _first: OptionButton
var _second: OptionButton
var _portraits: Array[TextureRect] = []
var _title: Label
var _goal: Label
var _memory: Label
var _benefit: Label
var _reason: Label
var _receipt: Label
var _meter: ProgressBar
var _break: Button
var _repair: Button
var _contest: Button
var _state: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.04, 0.06, 0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("182c35")
	style.border_color = Color("b5c9a4")
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, 20.0)
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_panel.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var label := _label("FLOCK TIES", 28)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(label)
	var close := Button.new()
	close.text = "BACK [Esc]"
	close.custom_minimum_size = Vector2(155, 44)
	close.pressed.connect(func() -> void: closed.emit())
	heading.add_child(close)
	var selectors := HBoxContainer.new()
	selectors.add_theme_constant_override("separation", 16)
	column.add_child(selectors)
	for i in 2:
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(72, 72)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		selectors.add_child(portrait)
		_portraits.append(portrait)
		var select := OptionButton.new()
		select.custom_minimum_size.y = 48
		select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select.add_theme_font_size_override("font_size", 21)
		selectors.add_child(select)
		if i == 0:
			_first = select
		else:
			_second = select
		select.item_selected.connect(func(_index: int) -> void: _select_pair())
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 270
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var story := VBoxContainer.new()
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.add_theme_constant_override("separation", 12)
	scroll.add_child(story)
	_title = _label("", 25)
	story.add_child(_title)
	_meter = ProgressBar.new()
	_meter.custom_minimum_size.y = 13
	_meter.show_percentage = false
	story.add_child(_meter)
	_goal = _label("", 18)
	_memory = _label("", 19)
	_benefit = _label("", 18)
	story.add_child(_benefit)
	_receipt = _label("", 18)
	_receipt.add_theme_color_override("font_color", Color("f4d88e"))
	story.add_child(_receipt)
	story.add_child(_goal)
	story.add_child(_label("WHAT THEY REMEMBER", 14))
	story.add_child(_memory)
	_reason = _label("", 17)
	column.add_child(_reason)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	column.add_child(actions)
	_break = Button.new()
	_break.text = "[1] SHARE BREAK · $1 / +8 WARMTH"
	_repair = Button.new()
	_repair.text = "[2] CLEAR THE AIR · FREE / +14 WARMTH"
	for button in [_break, _repair]:
		button.custom_minimum_size.y = 64
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 17)
		actions.add_child(button)
	_break.pressed.connect(func() -> void: _request("shared_break"))
	_repair.pressed.connect(func() -> void: _request("clear_air"))
	_contest = Button.new()
	_contest.text = "[3] FRIENDLY CONTEST · +3 STRESS EACH / EARN 6 XP EACH"
	_contest.custom_minimum_size.y = 64
	_contest.add_theme_font_size_override("font_size", 17)
	column.add_child(_contest)
	_contest.pressed.connect(func() -> void: _request("friendly_contest"))
	resized.connect(_layout)
	_layout()
	hide()

func _label(copy: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = copy
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("e6e6d6"))
	return label

func _layout() -> void:
	if _panel == null:
		return
	_panel.custom_minimum_size = Vector2(minf(920, size.x - 40), minf(610, size.y - 40))
	_panel.size = _panel.custom_minimum_size

func present(state: Dictionary, receipt: String = "") -> void:
	_state = state.duplicate(true)
	_first.clear()
	_second.clear()
	for worker in state.roster:
		for selector in [_first, _second]:
			selector.add_item(String(worker.name) + (" (off floor)" if not worker.employed else ""), int(worker.id))
	_first.select(_first.get_item_index(int(state.worker_id)))
	_second.select(_second.get_item_index(int(state.partner_id)))
	for i in 2:
		var id := int(state.worker_id if i == 0 else state.partner_id)
		_portraits[i].texture = load(Portraits.PORTRAIT_PATHS[SPEAKERS[posmod(id, 6)]]) as Texture2D
	var pair := state.pair as Dictionary
	_title.text = "%s  ·  %+d WARMTH" % [pair.get("label", "CHOOSE TWO HENS"), int(pair.get("affinity", 0))]
	_title.add_theme_color_override("font_color", Color("edb08d") if int(pair.get("affinity", 0)) < 0 else Color("b9ddb3"))
	_meter.value = int(pair.get("affinity", 0)) + 50
	_goal.text = String(pair.get("goal", "Choose different hens to see their shared story."))
	var lines: Array[String] = []
	for memory in pair.get("memories", []):
		lines.append("Day %d · %s" % [int(memory.day), memory.text])
	_memory.text = "\n".join(lines) if not lines.is_empty() else "A new connection. Their first shared shift is still ahead."
	_benefit.text = String(pair.get("reward_status", "")) + "\n" + String(pair.get("benefit", ""))
	if int(pair.get("friend_day", 0)) > 0:
		_benefit.text += "\nFirst became friends on day %d." % int(pair.friend_day)
	_reason.text = String(state.reason)
	_break.disabled = not bool(state.break_available)
	_repair.disabled = not bool(state.repair_available)
	_contest.disabled = not bool(state.get("contest_available", false))
	_contest.tooltip_text = "Strained or rival pairs only, before either delivers clean. Uses today's Team Lift opportunity; +3 stress each now. Both deliver clean this shift: +6 XP each and +6 warmth. No extra failure penalty."
	_break.tooltip_text = "Both hens: -4 stress, +2 morale, +8 lasting warmth. Costs $1 spendable Feed Fund."
	_repair.tooltip_text = "Repair a strained relationship: +14 lasting warmth, -2 stress and +2 morale for both."
	_receipt.text = receipt
	_receipt.visible = not receipt.is_empty()
	show()
	_layout()

func _select_pair() -> void:
	pair_selected.emit(_first.get_selected_id(), _second.get_selected_id())

func _request(action: String) -> void:
	action_requested.emit(_first.get_selected_id(), _second.get_selected_id(), action)

func snapshot() -> Dictionary:
	return {"visible": visible, "worker_id": _state.get("worker_id", -1), "partner_id": _state.get("partner_id", -1), "pair": _state.get("pair", {}), "receipt": _receipt.text, "benefit": _benefit.text, "break_available": not _break.disabled, "repair_available": not _repair.disabled, "contest_available": not _contest.disabled, "contest_rect": _rect(_contest), "panel_rect": _rect(_panel), "break_rect": _rect(_break), "repair_rect": _rect(_repair), "first_selector_rect": _rect(_first), "second_selector_rect": _rect(_second)}

func _rect(control: Control) -> Dictionary:
	var r := control.get_global_rect()
	return {"x": r.position.x, "y": r.position.y, "width": r.size.x, "height": r.size.y}
