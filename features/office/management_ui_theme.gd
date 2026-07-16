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


static func _outline_box(color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
