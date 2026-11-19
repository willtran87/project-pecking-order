class_name ShiftChallengeUI
extends Control

const ChoiceArt := preload("res://features/office/shift_choice_art.gd")

signal confirmed(option: Dictionary)
signal canceled
signal more_actions_requested
signal workshop_requested

const GOALS := {
	"clean_pair": "Produce 2 uncracked eggs in a row.",
	"fit_three": "Make 3 recommended routes in a row.",
	"peck_pair": "Land 2 STRONG or PERFECT pecks in a row.",
}
const PLAN_GOALS := {"fast": "fit_three", "safe": "clean_pair", "flock": "peck_pair"}
const PLAN_TITLES := {"fast": "FASTER EGGS", "safe": "SAFER SHELLS", "flock": "HAPPIER HENS"}
const PLAN_TIPS := {
	"fast": "NEXT: Open a tray and choose its recommended hen. Risky routes reset the streak.",
	"safe": "NEXT: Let hens work; help stressed hens protect their eggs. Cracks reset the streak.",
	"flock": "NEXT: Select a working hen. Press E in her gold timing window for a strong peck.",
}

var _options: Array[Dictionary] = []
var _cards: Array[Button] = []
var _selected := -1
var _mode := "preset"
var _title: Label
var _subtitle: Label
var _detail: Label
var _confirm: Button
var _later: Button
var _more: Button
var _progress: ProgressBar
var _workshop_button: Button
var _workshop: Dictionary = {}
var _tune: Button
var _selected_tuning := "standard"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100
	var scrim := ColorRect.new()
	scrim.color = Color(0.035, 0.065, 0.09, 0.92)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1000, 0)
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("152530")
	frame.border_color = Color("9e8657")
	frame.set_border_width_all(1)
	frame.border_width_top = 3
	frame.set_corner_radius_all(14)
	frame.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	frame.shadow_size = 12
	panel.add_theme_stylebox_override("panel", frame)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	_title = _label("", 30)
	var heading := HBoxContainer.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(_title)
	_workshop_button = Button.new()
	_workshop_button.custom_minimum_size = Vector2(220, 48)
	_workshop_button.pressed.connect(func() -> void: workshop_requested.emit())
	heading.add_child(_workshop_button)
	column.add_child(heading)
	_subtitle = _label("", 19)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.custom_minimum_size.x = 952
	column.add_child(_subtitle)
	_progress = ProgressBar.new()
	_progress.custom_minimum_size.y = 12
	_progress.show_percentage = false
	column.add_child(_progress)
	for index in 3:
		var card := Button.new()
		card.custom_minimum_size = Vector2(952, 84)
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.add_theme_font_size_override("font_size", 19)
		card.expand_icon = true
		card.add_theme_constant_override("icon_max_width", 56)
		card.add_theme_constant_override("h_separation", 18)
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var style := StyleBoxFlat.new()
			var selected: bool = state in ["pressed", "hover_pressed"]
			style.bg_color = Color("30494d") if selected else Color("2b3d4c") if state == "hover" else Color("21333f")
			style.border_color = Color("ebc779") if selected else Color("708995") if state == "hover" else Color("415767")
			style.set_border_width_all(2 if selected else 1)
			style.set_corner_radius_all(9)
			style.content_margin_left = 12
			style.content_margin_right = 12
			style.content_margin_top = 8
			style.content_margin_bottom = 8
			card.add_theme_stylebox_override(state, style)
		card.toggle_mode = true
		card.pressed.connect(_select.bind(index))
		column.add_child(card)
		_cards.append(card)
	_detail = _label("", 19)
	_detail.custom_minimum_size = Vector2(952, 90)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_detail)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 16)
	column.add_child(actions)
	_later = Button.new()
	_later.text = "LATER  [ESC]"
	_later.custom_minimum_size = Vector2(180, 64)
	_later.pressed.connect(func() -> void: canceled.emit())
	actions.add_child(_later)
	_tune = Button.new()
	_tune.custom_minimum_size = Vector2(220, 64)
	_tune.pressed.connect(_toggle_tuning)
	actions.add_child(_tune)
	_more = Button.new()
	_more.text = "OTHER ACTIONS"
	_more.custom_minimum_size = Vector2(180, 64)
	_more.pressed.connect(func() -> void: more_actions_requested.emit())
	actions.add_child(_more)
	_confirm = Button.new()
	_confirm.theme_type_variation = &"PrimaryButton"
	_confirm.custom_minimum_size = Vector2(0, 64)
	_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm.add_theme_font_size_override("font_size", 20)
	_confirm.pressed.connect(_commit)
	actions.add_child(_confirm)
	hide()


func _label(copy: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = copy
	label.add_theme_font_size_override("font_size", font_size)
	return label


func show_choices(mode: String, options: Array[Dictionary], worker_name: String, contract: Dictionary, workshop: Dictionary = {}) -> void:
	_mode = mode
	_workshop = workshop.duplicate(true)
	_options = options.duplicate(true)
	_selected = -1
	_selected_tuning = "standard"
	_tune.visible = mode == "workshop"
	_tune.disabled = true
	_tune.text = "SELECT A TOOL"
	_title.text = "CHALLENGE COMPLETE!" if mode == "reward" else "MAKE THIS SHIFT YOURS"
	if mode == "workshop":
		_title.text = "BUILD YOUR PLAYSTYLE"
	_subtitle.text = "Choose your payoff. Your completed challenge stays earned this shift." if mode == "reward" else "One plan for this shift. Choose a strength, accept a tradeoff."
	if mode == "workshop":
		_subtitle.text = "%d STAMPS  ·  %s  ·  One tool equipped per shift." % [int(workshop.get("stamps", 0)), String(workshop.get("equipped_label", "NO TOOL"))]
	_workshop_button.visible = mode != "workshop" and not workshop.is_empty()
	_workshop_button.text = "WORKSHOP · %d STAMPS" % int(workshop.get("stamps", 0))
	_progress.visible = mode == "reward"
	_progress.value = 100
	for index in 3:
		var card := _cards[index]
		card.visible = index < _options.size()
		if not card.visible:
			continue
		var option := _options[index]
		var id := String(option["id"])
		card.icon = ChoiceArt.badge(id)
		card.disabled = mode != "workshop" and not bool(option.get("available", false))
		card.button_pressed = false
		var copy := ""
		if mode == "preset":
			var goal := String(option.get("goal", ""))
			if goal.is_empty():
				goal = GOALS[PLAN_GOALS[id]]
			copy = "%s%s\nGoal: %s" % [PLAN_TITLES[id], "  ·  POLICY FIT" if bool(option.get("recommended", false)) else "", goal]
		elif mode == "workshop":
			copy = _workshop_card_copy(option, String(option.get("tuning", "standard")))
		else:
			match id:
				"fund": copy = "+$3.00 FEED FUND\nSave toward your next office upgrade."
				"mastery": copy = "+6 CAREER XP  ·  %s\nBring this hen closer to her next promotion." % worker_name
				"recovery": copy = "WHOLE FLOCK RECOVERY\nEvery employed hen: -4 stress and -4 fatigue."
		card.text = "  %d   %s" % [index + 1, copy]
		card.tooltip_text = String(option.get("detail", ""))
		card.accessibility_name = card.text + ". " + card.tooltip_text
		if card.disabled:
			card.text += "  ·  NEEDS $2" if mode == "preset" and id == "flock" else "  ·  UNAVAILABLE"
	_detail.text = "Pick a card to compare its benefit and cost. Complete its goal to choose cash, XP, or flock recovery." if mode == "preset" else "You earned one reward. Choose the benefit your office needs most."
	if mode == "preset" and not workshop.is_empty():
		_detail.text = "Complete your goal for a reward + a workshop stamp.\n%s" % String(workshop.get("horizon", ""))
	elif mode == "reward" and not workshop.is_empty():
		_detail.text += "\n" + ("All tools funded: also earn a $1 mastery bonus." if bool(workshop.get("all_earned", false)) else "Every reward also earns 1 stamp toward a permanent workshop tool.")
	elif mode == "workshop":
		_detail.text = "Pick a tool to see how it changes your tactics. Unlocks are permanent.\n%s" % String(workshop.get("horizon", ""))
	if mode == "reward":
		_detail.text += _mastery_reward_copy()
	_confirm.text = "SELECT A PLAN" if mode == "preset" else "SELECT A REWARD"
	if mode == "workshop":
		_confirm.text = "INSPECT A TOOL"
	_confirm.disabled = true
	show()
	_later.grab_focus()
	set_meta("contract", contract.duplicate(true))


func _workshop_card_copy(option: Dictionary, tool_mode: String) -> String:
	var state := "EQUIPPED" if bool(option.get("equipped", false)) and tool_mode == String(option.get("tuning", "standard")) else "OWNED" if bool(option.get("owned", false)) else "SHIFT %d · 1 STAMP" % int(option.get("unlock_day", 2))
	if bool((option.get("mastery", {}) as Dictionary).get("earned", false)):
		state += " · MASTERED"
	var short_gain := {"relay_bell": "Recommended routes in new trays bank an extra Peck.", "shell_guard": "Your first 2 strong Pecks protect those eggs from cracks.", "team_kettle": "Alternate strong Pecks: recover both hens; pass +10 work."}
	var tuned_gain := {"handoff": "Alternate strong Pecks: pass +18 work; no reserve Pecks.", "triage": "Final-hour strong Pecks: protect 2 eggs and add +15 work.", "encourage": "Alternate strong Pecks: -8 stress/fatigue for both; no work or XP.", "sprint": "Strong Pecks: +10 work and +3 stress. Three per shift.", "precision": "Protect 3 eggs with PERFECT Pecks; strong does not protect.", "mentor": "Alternate strong Pecks: train the previous hen, without recovery."}
	return "%s · %s%s\n%s" % [String(option.label), state, " · " + tool_mode.to_upper() if tool_mode != "standard" else "", String(tuned_gain.get(tool_mode, short_gain.get(String(option.id), option.gain)))]


func _select(index: int) -> void:
	if index < 0 or index >= _options.size() or (_mode != "workshop" and not bool(_options[index].get("available", false))):
		return
	if _selected != index:
		_selected_tuning = String(_options[index].get("tuning", "standard"))
	_selected = index
	for card_index in _cards.size():
		_cards[card_index].set_pressed_no_signal(card_index == index)
		if _mode == "workshop" and card_index < _options.size():
			var card_mode := _selected_tuning if card_index == index else String(_options[card_index].get("tuning", "standard"))
			_cards[card_index].text = "  %d   %s" % [card_index + 1, _workshop_card_copy(_options[card_index], card_mode)]
			_cards[card_index].accessibility_name = _cards[card_index].text + ". " + _cards[card_index].tooltip_text
	var option := _options[index]
	if _mode == "preset":
		var tip := String(option.get("tip", ""))
		_detail.text = "BENEFIT: %s\nTRADEOFF: %s · %s\n%s" % [option.get("gain", ""), option.get("cost", ""), option.get("risk", ""), PLAN_TIPS[String(option["id"])] if tip.is_empty() else tip]
	elif _mode == "workshop":
		var alternate := option.get("alternate", {}) as Dictionary
		var unlocked := _available_tunings(option).size() > 1
		_tune.disabled = not unlocked or not bool(option.get("can_configure", false))
		_tune.text = "MODE: %s [T]" % _selected_tuning.to_upper() if unlocked else "TUNING · SHIFT %d" % int(alternate.get("day", 3))
		_tune.tooltip_text = "Cycle available modes before committing. Earn mastery modes by completing a related challenge with this tool. Work locks your choice."
		var mastery := option.get("mastery", {}) as Dictionary
		var selected_mode := mastery if _selected_tuning == String(mastery.get("id", "")) else alternate
		var effect := String(option.tip) if _selected_tuning == "standard" else String(selected_mode.get("effect", ""))
		_detail.text = "%s: %s\n%s · One tool and mode per shift.\n%s" % [_selected_tuning.to_upper(), effect, String(option.cost), String(option.reason)]
		if bool(mastery.get("unlocked", false)):
			_detail.text += "\nEARNED: %s · [T] compares all 3 modes." % String(mastery.label)
		if not mastery.is_empty() and not bool(mastery.get("unlocked", false)):
			_detail.text += "\n%s · SHIFT %d: %s" % [String(mastery.label), int(mastery.day), "Earned! Available from that shift." if bool(mastery.get("earned", false)) else String(mastery.requirement)]
	else:
		_detail.text = "YOURS TO KEEP: %s\nChoose one reward; the other two will be passed up." % String(option.get("label", ""))
		if not _workshop.is_empty():
			_detail.text += "\n" + ("PLUS: $1 workshop mastery bonus." if bool(_workshop.get("all_earned", false)) else "PLUS: 1 workshop stamp toward a permanent tool.")
	if _mode == "reward":
		_detail.text += _mastery_reward_copy()
	_confirm.text = "COMMIT TO %s  [ENTER]" % PLAN_TITLES[String(option["id"])] if _mode == "preset" else "CLAIM REWARD  [ENTER]"
	if _mode == "workshop":
		_confirm.text = "%s  [ENTER]" % String(option.get("action", "UNLOCK"))
	_confirm.disabled = not bool(option.get("available", false))
	if _mode == "workshop" and bool(option.get("can_configure", false)):
		var unchanged := bool(option.get("equipped", false)) and _selected_tuning == String(option.get("tuning", "standard"))
		_confirm.disabled = unchanged
		_confirm.text = "EQUIPPED" if unchanged else "EQUIP %s [ENTER]" % _selected_tuning.to_upper() if bool(option.get("owned", false)) else "UNLOCK + EQUIP [ENTER]"


func _mastery_reward_copy() -> String:
	var offer := _workshop.get("mastery_offer", {}) as Dictionary
	return "" if offer.is_empty() else "\nALSO EARN: %s mode · free to equip from shift %d." % [String(offer.label), int(offer.day)]


func _available_tunings(option: Dictionary) -> Array[String]:
	var modes: Array[String] = ["standard"]
	for field in ["alternate", "mastery"]:
		var mode := option.get(field, {}) as Dictionary
		if bool(mode.get("unlocked", false)):
			modes.append(String(mode.id))
	return modes


func _toggle_tuning() -> void:
	if _selected < 0 or _tune.disabled:
		return
	var modes := _available_tunings(_options[_selected])
	_selected_tuning = modes[(modes.find(_selected_tuning) + 1) % modes.size()]
	_select(_selected)


func _commit() -> void:
	if _selected >= 0 and not _confirm.disabled:
		var option := _options[_selected].duplicate(true)
		if _mode == "workshop" and _selected_tuning != "standard":
			option["id"] = "%s/%s" % [option.id, _selected_tuning]
		confirmed.emit(option)


func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).physical_keycode
	if key == 0:
		key = (event as InputEventKey).keycode
	if key in [KEY_1, KEY_2, KEY_3]:
		_select(key - KEY_1)
	elif key == KEY_ENTER or key == KEY_KP_ENTER:
		_commit()
	elif key == KEY_ESCAPE:
		canceled.emit()
	elif key == KEY_T and _mode == "workshop":
		_toggle_tuning()
	elif key == KEY_TAB:
		var focus_order: Array[Control] = []
		if _workshop_button.visible:
			focus_order.append(_workshop_button)
		for card in _cards:
			if card.visible and not card.disabled:
				focus_order.append(card)
		focus_order.append(_later)
		if _tune.visible and not _tune.disabled:
			focus_order.append(_tune)
		focus_order.append(_more)
		if not _confirm.disabled:
			focus_order.append(_confirm)
		var current := focus_order.find(get_viewport().gui_get_focus_owner())
		focus_order[posmod(current + (-1 if event.shift_pressed else 1), focus_order.size())].grab_focus()
	else:
		return
	get_viewport().set_input_as_handled()


func primary_action_state() -> Dictionary:
	if not visible:
		return {}
	return {"copy": _confirm.text, "action_id": "shift_challenge", "actionable": not _confirm.disabled, "accessible_text": _title.text + ". " + _detail.text}


func focus_primary_action() -> bool:
	if not visible:
		return false
	(_later if _confirm.disabled else _confirm).grab_focus()
	return true


func snapshot() -> Dictionary:
	var card_rects: Array[Dictionary] = []
	for card in _cards:
		card_rects.append(_rect(card))
	return {"visible": visible, "mode": _mode, "selected": _selected, "title": _title.text, "detail": _detail.text, "confirm_enabled": not _confirm.disabled, "options": _options, "contract": get_meta("contract", {}), "workshop": _workshop, "workshop_rect": _rect(_workshop_button), "card_rects": card_rects, "confirm_rect": _rect(_confirm), "later_rect": _rect(_later), "tuning": _selected_tuning, "tuning_enabled": _tune.visible and not _tune.disabled, "tuning_rect": _rect(_tune)}


func _rect(control: Control) -> Dictionary:
	var rect := control.get_global_rect()
	return {"x": rect.position.x, "y": rect.position.y, "width": rect.size.x, "height": rect.size.y}
