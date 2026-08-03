class_name ManagementUITheme
extends RefCounted

const INK := Color("e9edf0")
const MUTED := Color("9eabb5")
const NAVY := Color("18232e")
const NAVY_RAISED := Color("243341")
const TEAL := Color("4f8b82")
const TEAL_BRIGHT := Color("73b5a7")
const BRASS := Color("c89b4a")
const RUST := Color("a95748")

static var _action_icon_cache: Dictionary[StringName, Texture2D] = {}


static func create_theme(high_contrast: bool = false, font_scale: float = 1.0) -> Theme:
	var scale := clampf(font_scale, 0.9, 1.5)
	var ink := Color.WHITE if high_contrast else INK
	var muted := Color("d4dde3") if high_contrast else MUTED
	var navy := Color("081018") if high_contrast else NAVY
	var navy_raised := Color("111f2b") if high_contrast else NAVY_RAISED
	var teal := Color("3e8f83") if high_contrast else TEAL
	var teal_bright := Color("9bf2df") if high_contrast else TEAL_BRIGHT
	var brass := Color("ffd86b") if high_contrast else BRASS
	var rust := Color("d65e50") if high_contrast else RUST
	var focus_width := 3 if high_contrast else 2
	var theme := Theme.new()
	theme.set_color(&"font_color", &"Label", ink)
	theme.set_color(&"font_shadow_color", &"Label", Color(0.0, 0.0, 0.0, 0.72 if high_contrast else 0.36))
	theme.set_constant(&"shadow_offset_x", &"Label", 1)
	theme.set_constant(&"shadow_offset_y", &"Label", 1)
	theme.set_font_size(&"font_size", &"Label", maxi(12, roundi(14.0 * scale)))

	theme.set_color(&"font_color", &"Button", ink)
	theme.set_color(&"font_hover_color", &"Button", Color.WHITE)
	theme.set_color(&"font_pressed_color", &"Button", Color("fff0c0"))
	theme.set_color(&"font_disabled_color", &"Button", muted.darkened(0.10 if high_contrast else 0.18))
	theme.set_font_size(&"font_size", &"Button", maxi(12, roundi(14.0 * scale)))
	theme.set_stylebox(&"normal", &"Button", _box(navy_raised, Color("738595") if high_contrast else Color("455665"), 6, 1))
	theme.set_stylebox(&"hover", &"Button", _box(Color("304454"), teal_bright, 6, 2))
	theme.set_stylebox(&"pressed", &"Button", _box(Color("172832"), brass, 6, 2))
	theme.set_stylebox(&"disabled", &"Button", _box(Color("151d25"), Color("303b45"), 6, 1))
	theme.set_stylebox(&"focus", &"Button", _outline_box(brass, 6, focus_width))

	theme.set_type_variation(&"SpeedButton", &"Button")
	theme.set_type_variation(&"ActiveSpeedButton", &"Button")
	theme.set_stylebox(&"normal", &"ActiveSpeedButton", _box(Color("31584f"), teal_bright, 6, 2))
	theme.set_stylebox(&"hover", &"ActiveSpeedButton", _box(Color("31584f"), teal_bright, 6, 2))
	theme.set_color(&"font_color", &"ActiveSpeedButton", Color("e7fff4"))

	theme.set_type_variation(&"UpgradeButton", &"Button")
	theme.set_stylebox(&"normal", &"UpgradeButton", _box(Color("22323a"), Color("6c7e80"), 7, 1))
	theme.set_stylebox(&"hover", &"UpgradeButton", _box(Color("2c4948"), brass, 7, 2))
	theme.set_font_size(&"font_size", &"UpgradeButton", maxi(12, roundi(13.0 * scale)))

	theme.set_type_variation(&"PrimaryButton", &"Button")
	theme.set_stylebox(&"normal", &"PrimaryButton", _box(Color("416e62"), teal_bright, 7, 2))
	theme.set_stylebox(&"hover", &"PrimaryButton", _box(Color("4c8172"), Color("a5dfcf"), 7, 2))
	theme.set_color(&"font_color", &"PrimaryButton", Color("f6fff8"))

	theme.set_type_variation(&"DangerButton", &"Button")
	theme.set_stylebox(&"normal", &"DangerButton", _box(Color("55312e"), rust, 7, 1))
	theme.set_stylebox(&"hover", &"DangerButton", _box(Color("6a3934"), Color("d47a66"), 7, 2))

	theme.set_type_variation(&"DecisionChoiceButton", &"Button")
	theme.set_stylebox(&"normal", &"DecisionChoiceButton", _box(Color("1f2d38"), Color("50616d"), 8, 1))
	theme.set_stylebox(&"hover", &"DecisionChoiceButton", _box(Color("29404a"), teal_bright, 8, 2))
	theme.set_font_size(&"font_size", &"DecisionChoiceButton", maxi(12, roundi(14.0 * scale)))

	# Quarterly policy cards separate Treasury movement from the operational
	# result. Shape, sign, and copy all carry meaning so the chips remain useful
	# without color perception.
	theme.set_type_variation(&"PolicyDebitChip", &"PanelContainer")
	theme.set_stylebox(
		&"panel",
		&"PolicyDebitChip",
		_chip_box(rust.darkened(0.62), rust.lightened(0.08)),
	)
	theme.set_type_variation(&"PolicyCreditChip", &"PanelContainer")
	theme.set_stylebox(
		&"panel",
		&"PolicyCreditChip",
		_chip_box(teal.darkened(0.58), teal_bright),
	)
	theme.set_type_variation(&"PolicyOutcomeChip", &"PanelContainer")
	theme.set_stylebox(
		&"panel",
		&"PolicyOutcomeChip",
		_chip_box(brass.darkened(0.68), brass),
	)
	for chip_label_type: StringName in [
		&"PolicyDebitChipLabel",
		&"PolicyCreditChipLabel",
		&"PolicyOutcomeChipLabel",
	]:
		theme.set_type_variation(chip_label_type, &"Label")
		theme.set_font_size(&"font_size", chip_label_type, maxi(10, roundi(11.0 * scale)))
		theme.set_color(&"font_color", chip_label_type, ink)
	theme.set_type_variation(&"PolicyCardTitleLabel", &"Label")
	theme.set_font_size(&"font_size", &"PolicyCardTitleLabel", maxi(11, roundi(12.0 * scale)))
	theme.set_color(&"font_color", &"PolicyCardTitleLabel", ink)
	theme.set_type_variation(&"PolicyCardSignalLabel", &"Label")
	theme.set_font_size(&"font_size", &"PolicyCardSignalLabel", maxi(10, roundi(11.0 * scale)))
	theme.set_color(&"font_color", &"PolicyCardSignalLabel", muted)

	theme.set_type_variation(&"SelectedChoiceButton", &"DecisionChoiceButton")
	theme.set_stylebox(&"normal", &"SelectedChoiceButton", _box(Color("334d49"), brass, 8, 3))
	theme.set_stylebox(&"hover", &"SelectedChoiceButton", _box(Color("3d5b55"), Color("f1c96f"), 8, 3))
	theme.set_color(&"font_color", &"SelectedChoiceButton", Color("fff4ce"))

	theme.set_stylebox(&"background", &"ProgressBar", _box(Color("111a22"), Color("3b4b56"), 5, 1))
	theme.set_stylebox(&"fill", &"ProgressBar", _box(teal, teal_bright, 5, 1))
	theme.set_color(&"font_color", &"ProgressBar", Color("f3f5ed"))
	theme.set_font_size(&"font_size", &"ProgressBar", maxi(12, roundi(13.0 * scale)))

	# Settings controls inherit the same warm institutional material language.
	theme.set_color(&"font_color", &"CheckButton", ink)
	theme.set_font_size(&"font_size", &"CheckButton", maxi(12, roundi(14.0 * scale)))
	theme.set_color(&"font_color", &"OptionButton", ink)
	theme.set_font_size(&"font_size", &"OptionButton", maxi(12, roundi(14.0 * scale)))
	theme.set_stylebox(&"normal", &"LineEdit", _box(navy, Color("5d7180"), 6, 1))
	theme.set_stylebox(&"focus", &"LineEdit", _box(navy, brass, 6, focus_width))
	theme.set_color(&"font_color", &"LineEdit", ink)
	theme.set_font_size(&"font_size", &"LineEdit", maxi(12, roundi(14.0 * scale)))
	return theme


static func style_held_confirmation(dialog: ConfirmationDialog) -> void:
	if dialog == null:
		return
	dialog.theme_type_variation = &"HeldConfirmationDialog"
	dialog.add_theme_stylebox_override("embedded_border", _held_confirmation_frame())
	dialog.add_theme_stylebox_override("panel", _held_confirmation_panel())
	dialog.add_theme_color_override("title_color", Color("f3dfaa"))
	dialog.add_theme_color_override("title_outline_modulate", Color("090f14"))
	dialog.add_theme_font_size_override("title_font_size", 16)
	dialog.add_theme_constant_override("title_height", 38)
	dialog.add_theme_constant_override("title_outline_size", 1)
	var copy := dialog.get_label()
	copy.add_theme_color_override("font_color", INK)
	copy.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.48),
	)
	copy.add_theme_constant_override("line_spacing", 3)
	var confirm_button := dialog.get_ok_button()
	var safe_return_button := dialog.get_cancel_button()
	confirm_button.theme_type_variation = &"DangerButton"
	safe_return_button.theme_type_variation = &"PrimaryButton"
	confirm_button.icon = action_icon(&"irreversible")
	safe_return_button.icon = action_icon(&"safe_return")
	confirm_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	safe_return_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	confirm_button.add_theme_constant_override("icon_separation", 3)
	safe_return_button.add_theme_constant_override("icon_separation", 3)
	confirm_button.set_meta("semantic_icon", "irreversible_warning")
	safe_return_button.set_meta("semantic_icon", "safe_return_arrow")
	safe_return_button.focus_mode = Control.FOCUS_ALL
	confirm_button.custom_minimum_size = Vector2(108.0, 42.0)
	safe_return_button.custom_minimum_size = Vector2(126.0, 42.0)
	dialog.about_to_popup.connect(
		func() -> void: safe_return_button.call_deferred("grab_focus")
	)
	dialog.set_meta("held_confirmation_skin", "flockwatch_compact")
	dialog.set_meta("held_confirmation_accent", "rust_left_brass_title")
	dialog.set_meta("held_confirmation_action_hierarchy", "danger_then_safe_return")
	dialog.set_meta("held_confirmation_icon_language", "warning_then_return")
	dialog.add_to_group(&"held_confirmation_dialogs")


static func action_icon(kind: StringName) -> Texture2D:
	if _action_icon_cache.has(kind):
		return _action_icon_cache[kind]
	var symbol := ""
	if kind == &"irreversible":
		# A warning triangle and heavy exclamation stay distinct from the return
		# arrow in monochrome, high contrast, and color-vision modes.
		symbol = (
			"<path d='M12 2.3 L22 20.8 H2 Z' fill='#f3dfaa' "
			+ "stroke='#101a23' stroke-width='1.5' stroke-linejoin='round'/>"
			+ "<path d='M12 7 V14.2 M12 17.6 V17.8' fill='none' "
			+ "stroke='#55312e' stroke-width='2.5' stroke-linecap='round'/>"
		)
	elif kind == &"safe_return":
		# The broad U-turn reads as leave unchanged without borrowing a confirm
		# checkmark, which could imply that the irreversible action will proceed.
		symbol = (
			"<path d='M9.6 3.2 L2 10.8 L9.6 18.4 V14.1 H14.2 "
			+ "C17.8 14.1 20.4 11.8 21.8 7.1 C19.1 9.4 17 10.1 14.1 10.1 "
			+ "H9.6 Z' fill='#f6fff8' stroke='#101a23' stroke-width='1.4' "
			+ "stroke-linejoin='round'/>"
		)
	elif kind == &"requisitions":
		# A clipped requisition sheet reads as a management list without relying
		# on the word repeated by the surrounding Roost panel.
		symbol = (
			"<rect x='4.3' y='4.8' width='15.4' height='16.2' rx='2' "
			+ "fill='#f3dfaa' stroke='#101a23' stroke-width='1.4'/>"
			+ "<path d='M8 4.8 V2.8 H16 V4.8 M8 9 H16 M8 13 H16 M8 17 H13' "
			+ "fill='none' stroke='#243341' stroke-width='1.8' stroke-linecap='round'/>"
		)
	elif kind == &"shelve":
		# A file descending into a shelf communicates a safe pause rather than a
		# destructive exit, and remains distinct from the confirmation U-turn.
		symbol = (
			"<path d='M3 8 H21 V20 H3 Z' fill='#d9e5e2' stroke='#101a23' "
			+ "stroke-width='1.4' stroke-linejoin='round'/>"
			+ "<path d='M3 8 L5 4 H19 L21 8 M8 12 H16 M12 2 V11 M8.5 7.5 "
			+ "L12 11 L15.5 7.5' fill='none' stroke='#31584f' stroke-width='1.8' "
			+ "stroke-linecap='round' stroke-linejoin='round'/>"
		)
	elif kind == &"advance":
		# A broad forward arrow carries next-shift, next-year, and file-and-plan
		# actions without repeating each destination inside the button.
		symbol = (
			"<path d='M2.5 8.7 H12.5 V3.2 L22 12 L12.5 20.8 V15.3 H2.5 Z' "
			+ "fill='#f6fff8' stroke='#101a23' stroke-width='1.4' "
			+ "stroke-linejoin='round'/>"
		)
	else:
		return null
	var svg := (
		"<svg xmlns='http://www.w3.org/2000/svg' width='18' height='18' viewBox='0 0 24 24'>"
		+ symbol
		+ "</svg>"
	)
	var image := Image.new()
	if image.load_svg_from_string(svg, 1.0) != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_action_icon_cache[kind] = texture
	return texture


static func _held_confirmation_frame() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101a23")
	style.border_color = Color("a85e4c")
	style.border_width_left = 4
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.set_corner_radius_all(9)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 9.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.52)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0.0, 5.0)
	return style


static func _held_confirmation_panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172630")
	style.border_color = Color("a85e4c")
	style.border_width_left = 4
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.set_corner_radius_all(7)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 11.0
	return style


static func _box(color: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style


static func _chip_box(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	return style


static func _outline_box(color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
