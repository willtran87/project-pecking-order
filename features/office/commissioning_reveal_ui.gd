class_name CommissioningRevealUI
extends Control

## Player-held commissioning receipt shown over the live office camera.
##
## The reveal never dismisses itself and never mutates simulation state. The
## caller decides whether Return reopens Capital Blueprint or Continue restores
## ordinary office control.

signal continue_requested
signal return_to_blueprint_requested

const ManagementTheme := preload("res://features/office/management_ui_theme.gd")

const COMPACT_BREAKPOINT := 900.0
const COLOR_INK := Color("eef1df")
const COLOR_MUTED := Color("aeb8c4")
const COLOR_BRASS := Color("e7c56e")
const COLOR_TEAL := Color("73b5a7")
const COLOR_NAVY := Color("101923")
const COLOR_PANEL := Color("17232d")

var _receipt: Dictionary = {}
var _reduced_motion := false
var _entrance_animated := false
var _entrance_tween: Tween

var _receipt_panel: PanelContainer
var _facility_label: Label
var _level_label: Label
var _before_after_label: Label
var _effects_label: Label
var _obligations_label: Label
var _outcome_label: Label
var _return_button: Button
var _continue_button: Button


func _ready() -> void:
	name = "CommissioningRevealUI"
	theme = ManagementTheme.create_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_apply_responsive_layout)
	_build_interface()
	_refresh_receipt()
	visible = false
	_apply_responsive_layout()


func apply_receipt(receipt: Dictionary) -> void:
	_receipt = receipt.duplicate(true)
	_refresh_receipt()


func show_reveal(receipt: Dictionary = {}, reduced_motion: bool = false) -> void:
	if not receipt.is_empty():
		apply_receipt(receipt)
	_reduced_motion = reduced_motion
	_entrance_animated = not _reduced_motion
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
	visible = true
	_receipt_panel.modulate = Color.WHITE
	if _entrance_animated:
		_receipt_panel.modulate.a = 0.0
		_entrance_tween = create_tween()
		_entrance_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_entrance_tween.tween_property(_receipt_panel, "modulate:a", 1.0, 0.22)
	call_deferred("_focus_continue")


func hide_reveal() -> void:
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
	visible = false


func is_reveal_visible() -> bool:
	return visible


func receipt_snapshot() -> Dictionary:
	return _receipt.duplicate(true)


func used_reduced_motion() -> bool:
	return _reduced_motion


func entrance_animated() -> bool:
	return _entrance_animated


func accessible_text() -> String:
	var parts: Array[String] = [
		"FACILITY COMMISSIONED",
		_facility_label.text,
		_level_label.text,
		_before_after_label.text,
		_effects_label.text,
		_obligations_label.text,
		_outcome_label.text,
	]
	return "; ".join(parts).replace("\n", "; ")


func _build_interface() -> void:
	var scrim := ColorRect.new()
	scrim.name = "CommissioningRevealScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.015, 0.025, 0.035, 0.28)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	_receipt_panel = PanelContainer.new()
	_receipt_panel.name = "CommissioningReceiptPanel"
	_receipt_panel.anchor_left = 0.0
	_receipt_panel.anchor_top = 1.0
	_receipt_panel.anchor_right = 1.0
	_receipt_panel.anchor_bottom = 1.0
	_receipt_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_receipt_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(COLOR_PANEL, COLOR_BRASS, 12, 2)
	)
	add_child(_receipt_panel)

	var margin := MarginContainer.new()
	margin.name = "CommissioningReceiptMargin"
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_receipt_panel.add_child(margin)

	var page := VBoxContainer.new()
	page.name = "CommissioningReceiptPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 6)
	margin.add_child(page)

	var title := _make_label("FACILITY COMMISSIONED", 14, COLOR_BRASS)
	title.name = "CommissioningRevealTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(title)

	var content_scroll := ScrollContainer.new()
	content_scroll.name = "CommissioningReceiptScroll"
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	page.add_child(content_scroll)

	var content := HBoxContainer.new()
	content.name = "CommissioningReceiptContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	content_scroll.add_child(content)

	var identity := VBoxContainer.new()
	identity.name = "CommissioningReceiptIdentity"
	identity.custom_minimum_size.x = 210.0
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 4)
	content.add_child(identity)
	_facility_label = _make_label("CAPITAL FACILITY", 21, COLOR_INK)
	_facility_label.name = "CommissioningFacilityName"
	_facility_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	identity.add_child(_facility_label)
	_level_label = _make_label("LEVEL COMMISSIONED", 12, COLOR_TEAL)
	_level_label.name = "CommissioningLevelName"
	_level_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	identity.add_child(_level_label)
	_outcome_label = _make_label("Commissioning receipt filed.", 12, COLOR_MUTED)
	_outcome_label.name = "CommissioningOutcome"
	_outcome_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_outcome_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	identity.add_child(_outcome_label)

	var economics := VBoxContainer.new()
	economics.name = "CommissioningReceiptEconomics"
	economics.custom_minimum_size.x = 235.0
	economics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	economics.add_theme_constant_override("separation", 5)
	content.add_child(economics)
	_before_after_label = _make_label("FUNDS  -", 13, COLOR_INK)
	_before_after_label.name = "CommissioningBeforeAfter"
	_before_after_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	economics.add_child(_before_after_label)
	_obligations_label = _make_label("OBLIGATIONS  -", 12, COLOR_MUTED)
	_obligations_label.name = "CommissioningObligations"
	_obligations_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	economics.add_child(_obligations_label)

	_effects_label = _make_label("EFFECTS  -", 12, COLOR_INK)
	_effects_label.name = "CommissioningEffects"
	_effects_label.custom_minimum_size.x = 230.0
	_effects_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_effects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_effects_label)

	var rail := HBoxContainer.new()
	rail.name = "CommissioningActionRail"
	rail.alignment = BoxContainer.ALIGNMENT_END
	rail.add_theme_constant_override("separation", 10)
	page.add_child(rail)
	_return_button = Button.new()
	_return_button.name = "CommissioningReturnToBlueprint"
	_return_button.text = "RETURN TO BLUEPRINT"
	_return_button.focus_mode = Control.FOCUS_ALL
	_return_button.custom_minimum_size = Vector2(190.0, 38.0)
	_return_button.tooltip_text = "Return to the Capital Blueprint without dismissing the commissioning result."
	_return_button.pressed.connect(func() -> void: return_to_blueprint_requested.emit())
	rail.add_child(_return_button)
	_continue_button = Button.new()
	_continue_button.name = "CommissioningContinue"
	_continue_button.text = "CONTINUE"
	_continue_button.theme_type_variation = &"PrimaryButton"
	_continue_button.focus_mode = Control.FOCUS_ALL
	_continue_button.custom_minimum_size = Vector2(150.0, 38.0)
	_continue_button.tooltip_text = "Acknowledge this held receipt and continue in the office."
	_continue_button.pressed.connect(func() -> void: continue_requested.emit())
	rail.add_child(_continue_button)


func _refresh_receipt() -> void:
	if _facility_label == null:
		return
	var facility_name := String(_receipt.get("facility_name", "CAPITAL FACILITY"))
	var level_name := String(_receipt.get("level_name", ""))
	var level := int(_receipt.get("purchased_level", _receipt.get("level", 0)))
	var max_level := int(_receipt.get("max_level", 0))
	_facility_label.text = facility_name.to_upper()
	if not level_name.is_empty():
		_level_label.text = level_name.to_upper()
	elif level > 0 and max_level > 0:
		_level_label.text = "LEVEL %d / %d COMMISSIONED" % [level, max_level]
	elif level > 0:
		_level_label.text = "LEVEL %d COMMISSIONED" % level
	else:
		_level_label.text = "COMMISSIONING RECEIPT"

	var spendable_before := int(_receipt.get("spendable_before_cents", _receipt.get("fund_before_cents", 0)))
	var spendable_after := int(_receipt.get("spendable_after_cents", _receipt.get("fund_after_cents", 0)))
	var cost := int(_receipt.get("cost_cents", _receipt.get("capital_cost_cents", 0)))
	_before_after_label.text = (
		"SPENDABLE FUND  %s  ->  %s\nCAPITAL FILED  %s"
		% [_money(spendable_before), _money(spendable_after), _money(cost)]
	)

	var reserve_before := int(_receipt.get("protected_reserve_before_cents", 0))
	var reserve_after := int(_receipt.get("protected_reserve_after_cents", 0))
	var upkeep_before := int(_receipt.get("upkeep_before_cents", 0))
	var upkeep_after := int(_receipt.get("upkeep_after_cents", 0))
	var upkeep_delta := int(_receipt.get("upkeep_delta_cents", upkeep_after - upkeep_before))
	_obligations_label.text = (
		"PROTECTED RESERVE  %s/day  ->  %s/day\n"
		+ "FACILITY UPKEEP  %s/day  ->  %s/day  (%s/day)"
	) % [
		_money(reserve_before),
		_money(reserve_after),
		_money(upkeep_before),
		_money(upkeep_after),
		_signed_money(upkeep_delta),
	]

	var effect := _receipt.get("effect", {}) as Dictionary
	var lines: Array[String] = []
	for benefit: Variant in effect.get("benefits", []):
		lines.append("+ %s" % String(benefit))
	for tradeoff: Variant in effect.get("tradeoffs", []):
		lines.append("- %s" % String(tradeoff))
	if int(effect.get("storage_capacity_eggs", 0)) > 0:
		lines.append("+ %d-egg cold-store capacity" % int(effect["storage_capacity_eggs"]))
	if int(effect.get("dispatch_capacity_eggs", 0)) > 0:
		lines.append("+ %d eggs dispatchable per shift" % int(effect["dispatch_capacity_eggs"]))
	if int(effect.get("shelf_life_shifts", 0)) > 0:
		lines.append("+ %d-shift shelf life" % int(effect["shelf_life_shifts"]))
	if lines.is_empty():
		lines.append("Commissioned effects are now active in the authoritative office ledger.")
	_effects_label.text = "OPERATING EFFECT\n%s" % "\n".join(lines)
	_outcome_label.text = String(_receipt.get("outcome", "Commissioning receipt filed."))
	tooltip_text = accessible_text()


func _apply_responsive_layout() -> void:
	if _receipt_panel == null:
		return
	var compact := size.x <= COMPACT_BREAKPOINT or size.y <= 430.0
	_receipt_panel.offset_left = 14.0 if compact else 70.0
	_receipt_panel.offset_right = -14.0 if compact else -70.0
	_receipt_panel.offset_top = -238.0 if compact else -230.0
	_receipt_panel.offset_bottom = -14.0 if compact else -20.0
	if _facility_label != null:
		_facility_label.add_theme_font_size_override("font_size", 17 if compact else 21)
	if _effects_label != null:
		_effects_label.custom_minimum_size.x = 220.0 if compact else 230.0


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
