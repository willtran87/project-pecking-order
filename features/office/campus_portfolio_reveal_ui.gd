class_name CampusPortfolioRevealUI
extends Control

## Player-held campus deed, construction, and staffing receipt shown over the
## exact live-world result. The control is presentation-only: Office owns the
## authoritative mutation, camera, return path, and simulation pause.

signal continue_requested
signal return_to_portfolio_requested

const ManagementTheme := preload("res://features/office/management_ui_theme.gd")

const COMPACT_BREAKPOINT := 900.0
const COLOR_INK := Color("eef1df")
const COLOR_MUTED := Color("aeb8c4")
const COLOR_BRASS := Color("e7c56e")
const COLOR_TEAL := Color("73b5a7")
const COLOR_RUST := Color("d68a68")
const COLOR_PANEL := Color("17232d")

var _receipt: Dictionary = {}
var _context: Dictionary = {}
var _reduced_motion := false
var _entrance_animated := false
var _entrance_tween: Tween

var _receipt_panel: PanelContainer
var _eyebrow_label: Label
var _asset_label: Label
var _location_label: Label
var _outcome_label: Label
var _economics_label: Label
var _capacity_label: Label
var _effects_label: Label
var _return_button: Button
var _continue_button: Button


func _ready() -> void:
	name = "CampusPortfolioRevealUI"
	theme = ManagementTheme.create_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_apply_responsive_layout)
	_build_interface()
	_refresh_receipt()
	visible = false
	set_process_unhandled_key_input(false)
	_apply_responsive_layout()


func show_reveal(
		receipt: Dictionary,
		context: Dictionary = {},
		reduced_motion: bool = false,
) -> void:
	_receipt = receipt.duplicate(true)
	_context = context.duplicate(true)
	_reduced_motion = reduced_motion
	_entrance_animated = not _reduced_motion
	_refresh_receipt()
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
	visible = true
	set_process_unhandled_key_input(true)
	_receipt_panel.modulate = Color.WHITE
	if _entrance_animated:
		_receipt_panel.modulate.a = 0.0
		_receipt_panel.position.y += 10.0
		_entrance_tween = create_tween()
		_entrance_tween.set_parallel(true)
		_entrance_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_entrance_tween.tween_property(_receipt_panel, "modulate:a", 1.0, 0.22)
		_entrance_tween.tween_property(_receipt_panel, "position:y", _receipt_panel.position.y - 10.0, 0.22)
	call_deferred("_focus_continue")


func hide_reveal() -> void:
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
	visible = false
	set_process_unhandled_key_input(false)


func is_reveal_visible() -> bool:
	return visible


func receipt_snapshot() -> Dictionary:
	return _receipt.duplicate(true)


func presentation_state() -> Dictionary:
	return {
		"visible": visible,
		"receipt": _receipt.duplicate(true),
		"context": _context.duplicate(true),
		"accessible_text": accessible_text(),
		"reduced_motion": _reduced_motion,
	}


func used_reduced_motion() -> bool:
	return _reduced_motion


func entrance_animated() -> bool:
	return _entrance_animated


func accessible_text() -> String:
	if _eyebrow_label == null:
		return "Campus portfolio reveal is not ready."
	return "; ".join([
		_eyebrow_label.text,
		_asset_label.text,
		_location_label.text,
		_outcome_label.text,
		_economics_label.text,
		_capacity_label.text,
		_effects_label.text,
	]).replace("\n", "; ")


func _build_interface() -> void:
	var scrim := ColorRect.new()
	scrim.name = "CampusPortfolioRevealScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.015, 0.025, 0.035, 0.24)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	_receipt_panel = PanelContainer.new()
	_receipt_panel.name = "CampusPortfolioRevealPanel"
	_receipt_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_receipt_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_receipt_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(COLOR_PANEL, COLOR_BRASS, 11, 2),
	)
	add_child(_receipt_panel)

	var margin := MarginContainer.new()
	margin.name = "CampusPortfolioRevealMargin"
	for side: StringName in [&"margin_left", &"margin_right"]:
		margin.add_theme_constant_override(side, 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_receipt_panel.add_child(margin)

	var page := VBoxContainer.new()
	page.name = "CampusPortfolioRevealPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 5)
	margin.add_child(page)

	_eyebrow_label = _make_label("CAMPUS RECORD FILED", 12, COLOR_BRASS)
	_eyebrow_label.name = "CampusPortfolioRevealEyebrow"
	_eyebrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(_eyebrow_label)

	var content_scroll := ScrollContainer.new()
	content_scroll.name = "CampusPortfolioRevealScroll"
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	page.add_child(content_scroll)

	var content := HFlowContainer.new()
	content.name = "CampusPortfolioRevealContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("h_separation", 18)
	content.add_theme_constant_override("v_separation", 7)
	content_scroll.add_child(content)

	var identity := VBoxContainer.new()
	identity.name = "CampusPortfolioRevealIdentity"
	identity.custom_minimum_size.x = 230.0
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 3)
	content.add_child(identity)
	_asset_label = _wrap_label("CAMPUS ASSET", 20, COLOR_INK)
	_asset_label.name = "CampusPortfolioRevealAsset"
	identity.add_child(_asset_label)
	_location_label = _wrap_label("CAMPUS PARCEL", 11, COLOR_TEAL)
	_location_label.name = "CampusPortfolioRevealLocation"
	identity.add_child(_location_label)
	_outcome_label = _wrap_label("Campus receipt filed.", 11, COLOR_MUTED)
	_outcome_label.name = "CampusPortfolioRevealOutcome"
	identity.add_child(_outcome_label)

	var economics := VBoxContainer.new()
	economics.name = "CampusPortfolioRevealEconomicsColumn"
	economics.custom_minimum_size.x = 235.0
	economics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(economics)
	_economics_label = _wrap_label("CAPITAL & LIABILITY\n-", 11, COLOR_INK)
	_economics_label.name = "CampusPortfolioRevealEconomics"
	economics.add_child(_economics_label)

	var capacity := VBoxContainer.new()
	capacity.name = "CampusPortfolioRevealCapacityColumn"
	capacity.custom_minimum_size.x = 220.0
	capacity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(capacity)
	_capacity_label = _wrap_label("BUILD & CAPACITY\n-", 11, COLOR_MUTED)
	_capacity_label.name = "CampusPortfolioRevealCapacity"
	capacity.add_child(_capacity_label)

	var effects := VBoxContainer.new()
	effects.name = "CampusPortfolioRevealEffectsColumn"
	effects.custom_minimum_size.x = 235.0
	effects.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(effects)
	_effects_label = _wrap_label("VISIBLE RESULT\n-", 11, COLOR_INK)
	_effects_label.name = "CampusPortfolioRevealEffects"
	effects.add_child(_effects_label)

	var rail := HFlowContainer.new()
	rail.name = "CampusPortfolioRevealActionRail"
	rail.alignment = FlowContainer.ALIGNMENT_END
	rail.add_theme_constant_override("h_separation", 9)
	rail.add_theme_constant_override("v_separation", 5)
	page.add_child(rail)
	_return_button = Button.new()
	_return_button.name = "CampusPortfolioRevealReturn"
	_return_button.text = "RETURN TO PORTFOLIO"
	_return_button.focus_mode = Control.FOCUS_ALL
	_return_button.custom_minimum_size = Vector2(185.0, 38.0)
	_return_button.tooltip_text = "Return to the Campus Portfolio with this authoritative result preserved."
	_return_button.pressed.connect(func() -> void: return_to_portfolio_requested.emit())
	rail.add_child(_return_button)
	_continue_button = Button.new()
	_continue_button.name = "CampusPortfolioRevealContinue"
	_continue_button.text = "CONTINUE"
	_continue_button.theme_type_variation = &"PrimaryButton"
	_continue_button.focus_mode = Control.FOCUS_ALL
	_continue_button.custom_minimum_size = Vector2(145.0, 38.0)
	_continue_button.tooltip_text = "Acknowledge the campus receipt and return to the prior office surface."
	_continue_button.pressed.connect(func() -> void: continue_requested.emit())
	rail.add_child(_continue_button)


func _refresh_receipt() -> void:
	if _asset_label == null:
		return
	var action_id := StringName(String(_receipt.get("action_id", "")))
	_eyebrow_label.text = _action_heading(action_id)
	var parcel_name := String(_context.get(
		"parcel_name",
		_title(String(_receipt.get("parcel_id", "CAMPUS PARCEL"))),
	))
	var module_name := String(_context.get(
		"module_name",
		_title(String(_receipt.get("module_id", ""))),
	))
	var pad_name := String(_context.get(
		"pad_name",
		_title(String(_receipt.get("pad_id", ""))),
	))
	_asset_label.text = (
		parcel_name.to_upper()
		if action_id == &"purchase_deed" or module_name.is_empty() else
		module_name.to_upper()
	)
	var location_parts: Array[String] = []
	if not parcel_name.is_empty():
		location_parts.append(parcel_name.to_upper())
	if not pad_name.is_empty():
		location_parts.append(pad_name.to_upper())
	var status := String(_receipt.get("status", "filed")).replace("_", " ").to_upper()
	if not status.is_empty():
		location_parts.append(status)
	_location_label.text = " / ".join(location_parts)
	_outcome_label.text = String(_receipt.get(
		"outcome",
		_context.get("outcome", "Campus receipt filed."),
	))

	var cost := int(_receipt.get("cost_cents", 0))
	var daily_delta := int(_receipt.get("added_daily_cost_cents", 0))
	var economics_lines: Array[String] = [
		"CAPITAL & LIABILITY",
		"CAPITAL FILED  %s" % _money(cost),
		"DAILY OBLIGATION  %s/day" % _signed_money(daily_delta),
	]
	if bool(_context.get("has_fund_before", false)):
		economics_lines.append("FEED FUND  %s -> %s" % [
			_money(int(_context.get("fund_before_cents", 0))),
			_money(int(_context.get("fund_after_cents", 0))),
		])
	if bool(_context.get("has_spendable_after", false)):
		economics_lines.append(
			"SPENDABLE AFTER  %s" % _money(int(_context.get("spendable_after_cents", 0)))
		)
	_economics_label.text = "\n".join(economics_lines)

	var duration := int(_receipt.get("duration_shifts", 0))
	var worker_name := String(_context.get("worker_name", "")).strip_edges()
	var capacity_lines: Array[String] = []
	if action_id in [&"assign_worker", &"unassign_worker"]:
		capacity_lines = [
			"CAMPUS DUTY",
			"NO CAPITAL CONSTRUCTION",
			"DESK OUTPUT  %s" % ("RESUMES AFTER RETURN" if action_id == &"unassign_worker" else "PAUSED FOR COMMUTE"),
		]
	elif action_id == &"purchase_deed":
		capacity_lines = [
			"LAND & CAPACITY",
			"NO CONSTRUCTION WINDOW",
			"NO CONTRACTOR SLOT",
			"PARCEL CIRCULATION FILED",
		]
	else:
		capacity_lines = [
			"BUILD & CAPACITY",
			"BUILD TIME  %d %s" % [duration, "SHIFT" if duration == 1 else "SHIFTS"],
			"CONTRACTORS  %d" % int(_receipt.get("contractor_slots", 0)),
			"POWER  %d  /  COLD  %d" % [
				int(_receipt.get("power_units", 0)),
				int(_receipt.get("cold_units", 0)),
			],
		]
	if not worker_name.is_empty():
		capacity_lines.append("NAMED HEN  %s" % worker_name.to_upper())
	_capacity_label.text = "\n".join(capacity_lines)

	var effect_lines: Array[String] = ["VISIBLE RESULT"]
	for effect_value: Variant in _context.get("effect_lines", []) as Array:
		var effect := String(effect_value).strip_edges()
		if not effect.is_empty():
			effect_lines.append(effect if effect.begins_with("+") or effect.begins_with("-") else "+ %s" % effect)
	if effect_lines.size() == 1:
		effect_lines.append(_visible_result_fallback(action_id, status, worker_name))
	_effects_label.text = "\n".join(effect_lines)
	tooltip_text = accessible_text()


func _action_heading(action_id: StringName) -> String:
	match action_id:
		&"purchase_deed":
			return "CAMPUS DEED FILED"
		&"authorize_project":
			return "CAMPUS BUILD AUTHORIZED"
		&"start_project":
			return "CONTRACTOR MOBILIZED"
		&"complete_project":
			return "CAMPUS BUILD COMPLETE"
		&"assign_worker":
			return "NAMED CAMPUS PERCH STAFFED"
		&"unassign_worker":
			return "CAMPUS PERCH CLEARED"
	return "CAMPUS RECORD FILED"


func _visible_result_fallback(action_id: StringName, status: String, worker_name: String) -> String:
	match action_id:
		&"purchase_deed":
			return "Survey stakes yield to the owned parcel and filed circulation ground."
		&"authorize_project":
			return "The selected pad now shows its exact %s construction state." % status
		&"start_project":
			return "The active contractor has moved from the queue onto the physical pad."
		&"complete_project":
			return "The completed building is now permanent; benefits wait for utilities and named staff."
		&"assign_worker":
			return "%s leaves desk production and commutes to this module." % (
				worker_name if not worker_name.is_empty() else "The named hen"
			)
		&"unassign_worker":
			return "%s returns to her office chair before desk production resumes." % (
				worker_name if not worker_name.is_empty() else "The named hen"
			)
	return "The authoritative campus projection now matches this filed record."


func _apply_responsive_layout() -> void:
	if _receipt_panel == null:
		return
	var compact := size.x <= COMPACT_BREAKPOINT or size.y <= 430.0
	var portrait := size.x < size.y and size.x <= 520.0
	_receipt_panel.offset_left = 10.0 if compact else 52.0
	_receipt_panel.offset_right = -10.0 if compact else -52.0
	_receipt_panel.offset_top = -440.0 if portrait else (-220.0 if compact else -246.0)
	_receipt_panel.offset_bottom = -10.0 if compact else -18.0
	if _asset_label != null:
		_asset_label.add_theme_font_size_override("font_size", 16 if compact else 20)
	for column: Control in [
		_asset_label.get_parent() if _asset_label != null else null,
		_economics_label.get_parent() if _economics_label != null else null,
		_capacity_label.get_parent() if _capacity_label != null else null,
		_effects_label.get_parent() if _effects_label != null else null,
	]:
		if column != null:
			column.custom_minimum_size.x = 0.0 if portrait else (200.0 if compact else 220.0)


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE:
		return_to_portfolio_requested.emit()
		get_viewport().set_input_as_handled()


func _focus_continue() -> void:
	if visible and _continue_button != null and _continue_button.is_visible_in_tree():
		_continue_button.grab_focus()


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	return label


func _wrap_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := _make_label(text_value, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _panel_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _money(cents: int) -> String:
	return "$%.2f" % (float(cents) / 100.0)


func _signed_money(cents: int) -> String:
	return "%s%s" % ["+" if cents >= 0 else "-", _money(absi(cents))]


func _title(value: String) -> String:
	return value.replace("_", " ").capitalize()
