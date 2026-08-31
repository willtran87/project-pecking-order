class_name SemanticColorPalette
extends RefCounted


## One semantic palette for gameplay-critical routing and egg-quality signals.
##
## The color-blind-safe mode uses high-separation hues derived from the
## Okabe-Ito family and always adds compact text markers. Color is therefore an
## enhancement rather than the only carrier of meaning.

const MODE_STANDARD: StringName = &"standard"
const MODE_COLOR_BLIND_SAFE: StringName = &"color_blind_safe"
const MODES: Array[String] = ["standard", "color_blind_safe"]

const STANDARD_LANE_COLORS := {
	&"auto": Color("72b6aa"),
	&"nest_damage": Color("8fbd8d"),
	&"predator_loss": Color("d68a68"),
	&"appeals": Color("a896ce"),
	&"overdue": Color("e08a72"),
}
const SAFE_LANE_COLORS := {
	&"auto": Color("56b4e9"),
	&"nest_damage": Color("009e73"),
	&"predator_loss": Color("e69f00"),
	&"appeals": Color("cc79a7"),
	&"overdue": Color("d55e00"),
}

const STANDARD_QUALITY_COLORS := {
	&"sound": Color("7eb28f"),
	&"golden": Color("d6a34e"),
	&"cracked": Color("b85c51"),
}
const SAFE_QUALITY_COLORS := {
	&"sound": Color("0072b2"),
	&"golden": Color("f0e442"),
	&"cracked": Color("d55e00"),
}

const STANDARD_EGG_COLORS := {
	&"sound": Color("e8dfc4"),
	&"golden": Color("d9a43e"),
	&"cracked": Color("a87366"),
}
const SAFE_EGG_COLORS := {
	&"sound": Color("56b4e9"),
	&"golden": Color("f0e442"),
	&"cracked": Color("d55e00"),
}

const LANE_MARKERS := {
	&"auto": "[A]",
	&"nest_damage": "[N]",
	&"predator_loss": "[P]",
	&"appeals": "[A]",
	&"overdue": "[!]",
}
const QUALITY_MARKERS := {
	&"sound": "[OK]",
	&"golden": "[*]",
	&"cracked": "[X]",
}


static func normalize_mode(value: Variant) -> StringName:
	var candidate := String(value)
	return StringName(candidate) if candidate in MODES else MODE_STANDARD


static func is_safe_mode(value: Variant) -> bool:
	return normalize_mode(value) == MODE_COLOR_BLIND_SAFE


static func lane_color(lane: StringName, mode: Variant = MODE_STANDARD) -> Color:
	var palette := SAFE_LANE_COLORS if is_safe_mode(mode) else STANDARD_LANE_COLORS
	return palette.get(lane, palette[&"auto"])


static func quality_color(quality: StringName, mode: Variant = MODE_STANDARD) -> Color:
	var normalized := quality if STANDARD_QUALITY_COLORS.has(quality) else &"sound"
	var palette := SAFE_QUALITY_COLORS if is_safe_mode(mode) else STANDARD_QUALITY_COLORS
	return palette[normalized]


static func egg_color(quality: StringName, mode: Variant = MODE_STANDARD) -> Color:
	var normalized := quality if STANDARD_EGG_COLORS.has(quality) else &"sound"
	var palette := SAFE_EGG_COLORS if is_safe_mode(mode) else STANDARD_EGG_COLORS
	return palette[normalized]


static func lane_marker(lane: StringName, mode: Variant = MODE_STANDARD) -> String:
	if not is_safe_mode(mode):
		return ""
	return String(LANE_MARKERS.get(lane, "[?]"))


static func quality_marker(quality: StringName, mode: Variant = MODE_STANDARD) -> String:
	if not is_safe_mode(mode):
		return ""
	return String(QUALITY_MARKERS.get(quality, "[?]"))


static func marked_lane_name(name: String, lane: StringName, mode: Variant = MODE_STANDARD) -> String:
	var marker := lane_marker(lane, mode)
	return "%s %s" % [marker, name] if not marker.is_empty() else name


static func marked_quality_name(name: String, quality: StringName, mode: Variant = MODE_STANDARD) -> String:
	var marker := quality_marker(quality, mode)
	return "%s %s" % [marker, name] if not marker.is_empty() else name
