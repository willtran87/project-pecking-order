class_name EnvironmentalSignage
extends RefCounted

## Builds office copy as authored props instead of camera-facing labels. Each
## mounting family now follows the object that owns it: a cubicle gets a slotted
## paper insert, a shipping crate gets a glued label, equipment gets faded paint,
## and only the bureau itself earns a dimensional identity sign.

static var _material_cache: Dictionary = {}
static var _font_cache: Dictionary = {}
static var _source_font_cache: Dictionary = {}

const BUREAU_REGULAR_PATH := "res://assets/fonts/BarlowCondensed-Regular.fontbytes"
const BUREAU_SEMIBOLD_PATH := "res://assets/fonts/BarlowCondensed-SemiBold.fontbytes"
const LEDGER_REGULAR_PATH := "res://assets/fonts/IBMPlexMono-Regular.fontbytes"
const LEDGER_SEMIBOLD_PATH := "res://assets/fonts/IBMPlexMono-SemiBold.fontbytes"
const PAPER_REGULAR_PATH := "res://assets/fonts/CourierPrime-Regular.fontbytes"
const PAPER_BOLD_PATH := "res://assets/fonts/CourierPrime-Bold.fontbytes"

const WARM_LAMINATE := Color("745238")
const CUBICLE_GREEN := Color("536c64")
const CORPORATE_TEAL := Color("315b60")
const CLAIMS_PAPER := Color("e0d9bd")
const BRASS_INK := Color("d5b866")
const DEEP_TEAL := Color("243f43")
const CREAM_INK := Color("f0e7ce")

# Label3D's font_size controls the raster resolution of the generated glyph
# texture, while pixel_size controls its physical world scale. The authored
# calls predate that distinction and use small UI-like raster sizes, so render
# every sign from a larger glyph atlas and compensate pixel_size below.
const HIGH_RES_FONT_SIZE := 64
const MIN_FITTED_PIXEL_SIZE := 0.00001
const FOCUSED_DETAIL_RADIUS := 2.75
const DETAIL_FADE_IN_SECONDS := 0.16
const DETAIL_FADE_OUT_SECONDS := 0.12


static func add_panel(
	parent: Node3D,
	label_name: String,
	copy: String,
	fixture_position: Vector3,
	panel_size: Vector2,
	panel_color: Color,
	ink_color: Color,
	fixture_rotation_degrees: Vector3 = Vector3.ZERO,
	font_size: int = 18,
	pixel_size: float = 0.0042,
	tier: StringName = &"secondary",
	mount_kind: StringName = &"wall",
	is_screen: bool = false
) -> Label3D:
	var fixture := Node3D.new()
	fixture.name = "%sFixture" % label_name
	fixture.position = fixture_position
	fixture.rotation_degrees = fixture_rotation_degrees
	var style_family := _style_family(tier, mount_kind, is_screen)
	var formal_treatment := mount_kind == &"paper" or tier == &"primary"
	fixture.set_meta(&"sign_tier", tier)
	fixture.set_meta(&"mount_kind", mount_kind)
	fixture.set_meta(&"style_family", style_family)
	fixture.set_meta(&"panel_size", panel_size)
	# When the caller parents a fixture directly to a prop mesh, preserve that
	# relationship explicitly. This is stronger than the old style-derived
	# `physical_host` flag: rotated cartons, machine faces, and wooden slats now
	# carry their own print instead of leaving it behind in world space.
	fixture.set_meta(&"host_surface_name", parent.name if parent is MeshInstance3D else &"")
	fixture.set_meta(&"host_attached", parent is MeshInstance3D)
	fixture.set_meta(
		&"physical_host",
		parent is MeshInstance3D or style_family in [
			&"hosted_header", &"chart_header", &"portrait_masthead",
			&"beam_letters", &"surface_stencil",
		]
	)
	fixture.set_meta(&"formal_treatment", formal_treatment)
	fixture.set_meta(&"surface_integrated", true)
	fixture.set_meta(&"overview_anchor", _is_overview_anchor(style_family, tier))
	fixture.set_meta(
		&"fixture_detail_only",
		style_family in [&"partition_insert", &"adhesive_label", &"room_plaque"]
	)
	if style_family in [&"paper_notice", &"adhesive_label"]:
		# A barely imperfect pinning angle keeps repeated notices from reading as
		# a screen-space card grid. The name hash makes the result deterministic.
		fixture.rotation_degrees.z += _deterministic_signed(label_name, 0) * 0.72
	parent.add_child(fixture)
	fixture.add_to_group(&"environmental_signage")

	_build_mount(
		fixture, panel_size, panel_color, ink_color,
		style_family, formal_treatment
	)

	var split_copy := copy.split("\n", false, 1)
	var use_hierarchy := split_copy.size() > 1 and style_family != &"screen"
	var label: Label3D
	if use_hierarchy:
		var heading := String(split_copy[0])
		var body := String(split_copy[1])
		label = _add_printed_label(
			fixture, label_name, heading,
			Vector3(0.0, panel_size.y * 0.15, _text_depth(style_family)),
			Vector2(panel_size.x, panel_size.y * 0.43),
			font_size, pixel_size, ink_color, panel_color,
			style_family, true, &"heading"
		)
		_add_printed_label(
			fixture, "%sBody" % label_name, body,
			Vector3(0.0, -panel_size.y * 0.18, _text_depth(style_family)),
			Vector2(panel_size.x, panel_size.y * 0.34),
			maxi(9, roundi(font_size * 0.72)), pixel_size * 0.86,
			ink_color.darkened(0.12), panel_color,
			style_family, false, &"body"
		)
	else:
		var single_line_area := Vector2(panel_size.x, panel_size.y * 0.78)
		if style_family == &"screen":
			single_line_area = Vector2(panel_size.x * 0.82, panel_size.y * 0.68)
		var single_emphasized := (
			tier == &"primary"
			or style_family in [&"chart_header", &"portrait_masthead", &"beam_letters"]
			or (tier == &"secondary" and style_family == &"surface_stencil")
		)
		label = _add_printed_label(
			fixture, label_name, copy,
			Vector3(0.0, -0.006, _text_depth(style_family)),
			single_line_area,
			font_size, pixel_size, ink_color, panel_color,
			style_family, single_emphasized,
			&"live" if style_family == &"screen" else &"heading"
		)

	if (
		(tier == &"primary" and style_family == &"bureau_plaque")
		or style_family in [&"room_plaque", &"beam_letters"]
	):
		_add_letterpress_shadow(fixture, label, ink_color)
	return label


static func add_architectural_identity(
	parent: Node3D,
	fixture_name: String,
	title: String,
	subtitle: String,
	fixture_position: Vector3,
	panel_size: Vector2,
	fixture_rotation_degrees: Vector3 = Vector3.ZERO
) -> Node3D:
	## Permanent identity belongs to the architecture: shallow dimensional letters
	## sit on a laminate fascia instead of another framed UI-like card.
	var fixture := Node3D.new()
	fixture.name = "%sFixture" % fixture_name
	fixture.position = fixture_position
	fixture.rotation_degrees = fixture_rotation_degrees
	fixture.set_meta(&"sign_tier", &"primary")
	fixture.set_meta(&"mount_kind", &"architecture")
	fixture.set_meta(&"style_family", &"architectural_letters")
	fixture.set_meta(&"panel_size", panel_size)
	fixture.set_meta(&"physical_host", false)
	fixture.set_meta(&"surface_integrated", true)
	fixture.set_meta(&"overview_anchor", true)
	parent.add_child(fixture)
	fixture.add_to_group(&"environmental_signage")

	_add_box(
		fixture, "IdentityFascia",
		Vector3(panel_size.x, panel_size.y, 0.050), Vector3.ZERO,
		WARM_LAMINATE.darkened(0.10), 0.78
	)
	# The dark inset makes the wordmark read as part of the permanent wall trim,
	# rather than pale copy printed directly over the window valance.
	_add_box(
		fixture, "IdentityInset",
		Vector3(panel_size.x - 0.16, panel_size.y - 0.13, 0.024),
		Vector3(0.0, 0.0, 0.030), DEEP_TEAL, 0.58
	)
	_add_box(
		fixture, "FasciaTopRail",
		Vector3(panel_size.x + 0.10, 0.055, 0.068),
		Vector3(0.0, panel_size.y * 0.5 - 0.028, -0.004),
		BRASS_INK.darkened(0.22), 0.52, 0.30
	)
	_add_box(
		fixture, "FasciaBottomRail",
		Vector3(panel_size.x + 0.10, 0.040, 0.068),
		Vector3(0.0, -panel_size.y * 0.5 + 0.020, -0.004),
		BRASS_INK.darkened(0.28), 0.52, 0.30
	)
	_add_egg_seal(
		fixture,
		Vector3(-panel_size.x * 0.5 + panel_size.y * 0.55, 0.045, 0.045),
		panel_size.y * 0.23,
		BRASS_INK.lightened(0.06)
	)
	for fastener_x in [-1.0, 1.0]:
		_add_fastener(
			fixture,
			Vector3(fastener_x * (panel_size.x * 0.5 - 0.08), 0.0, 0.049),
			Color("b99b5b")
		)
	var identity_label := _add_printed_label(
		fixture,
		fixture_name,
		title,
		Vector3(panel_size.y * 0.20, panel_size.y * 0.075, 0.050),
		Vector2(panel_size.x - panel_size.y * 0.92, panel_size.y * 0.50),
		44,
		0.0170,
		Color("d8bd74"),
		DEEP_TEAL,
		&"architectural_letters",
		true,
		&"heading"
	)
	_add_letterpress_shadow(fixture, identity_label, BRASS_INK)
	var subtitle_label := _add_printed_label(
		fixture,
		"%sSubtitle" % fixture_name,
		subtitle,
		Vector3(panel_size.y * 0.20, -panel_size.y * 0.250, 0.049),
		Vector2(panel_size.x - panel_size.y * 0.92, panel_size.y * 0.18),
		18,
		0.0092,
		CREAM_INK.darkened(0.04),
		DEEP_TEAL,
		&"architectural_letters",
		false,
		&"body"
	)
	subtitle_label.set_meta(&"type_role", &"identity_subtitle")
	return fixture


static func set_camera_detail(
	root: Node,
	focused: bool,
	focus_position: Vector3 = Vector3(INF, INF, INF),
	detail_radius: float = FOCUSED_DETAIL_RADIUS,
	animate: bool = true
) -> void:
	## Orthographic zoom changes projected size without changing camera distance,
	## so GeometryInstance visibility ranges cannot suppress unreadable microcopy.
	## Keep the overview architectural: landmarks, headers, and live equipment only.
	## Focused shots reveal only the copy near the inspected subject. Previously a
	## single selected hen switched on every document in the room, which made the
	## office read like a field of HUD cards instead of a physical workplace.
	if root == null:
		return
	var has_spatial_focus := (
		is_finite(focus_position.x)
		and is_finite(focus_position.y)
		and is_finite(focus_position.z)
	)
	# Tiny removable labels should not leave bright empty rectangles behind when
	# their lettering is too small to read. Reveal the whole prop only when its
	# owning desk or carton is actually being inspected.
	for fixture_candidate in root.find_children("*", "Node3D", true, false):
		var fixture := fixture_candidate as Node3D
		if (
			fixture == null
			or not fixture.is_in_group(&"environmental_signage")
			or not bool(fixture.get_meta(&"fixture_detail_only", false))
		):
			continue
		var fixture_near_focus := focused and (
			not has_spatial_focus
			or fixture.global_position.distance_to(focus_position) <= maxf(0.25, detail_radius)
		)
		fixture.visible = fixture_near_focus
		fixture.set_meta(&"detail_should_show", fixture_near_focus)
	for candidate in root.find_children("*", "Label3D", true, false):
		var label := candidate as Label3D
		if label == null or not bool(label.get_meta(&"environmental_copy", false)):
			continue
		var tier := StringName(label.get_meta(&"sign_tier", &"utility"))
		var detail_role := StringName(label.get_meta(&"detail_role", &"body"))
		var fixture := label.get_parent() as Node3D
		var overview_anchor := (
			fixture != null and bool(fixture.get_meta(&"overview_anchor", false))
		)
		var near_focus := focused and (
			not has_spatial_focus
			or label.global_position.distance_to(focus_position) <= maxf(0.25, detail_radius)
		)
		var should_show := (
			near_focus
			or (tier == &"primary" and detail_role != &"body")
			or (overview_anchor and detail_role in [&"heading", &"live"])
		)
		_set_detail_visibility(label, should_show, animate)


static func _set_detail_visibility(label: Label3D, should_show: bool, animate: bool) -> void:
	label.set_meta(&"detail_should_show", should_show)
	var resting_alpha := (
		float(label.get_meta(&"resting_alpha"))
		if label.has_meta(&"resting_alpha")
		else label.modulate.a
	)
	var active_tween_value: Variant = (
		label.get_meta(&"detail_visibility_tween")
		if label.has_meta(&"detail_visibility_tween")
		else null
	)
	if active_tween_value is Tween:
		(active_tween_value as Tween).kill()
	if label.has_meta(&"detail_visibility_tween"):
		label.remove_meta(&"detail_visibility_tween")

	if not animate or not label.is_inside_tree():
		label.visible = should_show
		label.modulate.a = resting_alpha if should_show else 0.0
		return

	if should_show:
		label.visible = true
		var fade_in := label.create_tween()
		fade_in.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fade_in.tween_property(label, "modulate:a", resting_alpha, DETAIL_FADE_IN_SECONDS)
		label.set_meta(&"detail_visibility_tween", fade_in)
		return

	if not label.visible:
		label.modulate.a = 0.0
		return
	var fade_out := label.create_tween()
	fade_out.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_out.tween_property(label, "modulate:a", 0.0, DETAIL_FADE_OUT_SECONDS)
	fade_out.tween_callback(func() -> void:
		if is_instance_valid(label) and not bool(label.get_meta(&"detail_should_show", true)):
			label.visible = false
	)
	label.set_meta(&"detail_visibility_tween", fade_out)


static func refit_label(label: Label3D) -> void:
	## Dynamic KPI screens change line lengths during play. Refit after each update
	## so the digits remain contained by the physical glass instead of overflowing.
	if label == null or not label.has_meta(&"text_area_size"):
		return
	var area := label.get_meta(&"text_area_size", Vector2.ONE) as Vector2
	var requested := float(label.get_meta(&"requested_pixel_size", label.pixel_size))
	var screen_copy := bool(label.get_meta(&"screen_copy", false))
	label.pixel_size = _fitted_pixel_size(
		label.text, area, label.font, label.font_size, requested, screen_copy
	)
	label.width = maxi(1, floori(area.x * 0.90 / label.pixel_size))
	label.set_meta(&"fitted_pixel_size", label.pixel_size)


static func apply_house_type(
	label: Label3D,
	style_family: StringName = &"enamel_plate",
	emphasized: bool = false
) -> void:
	## Lets transient, already-authored machine readouts use the same typography
	## without wrapping them in a second environmental-sign fixture.
	if label == null:
		return
	if not bool(label.get_meta(&"house_type_high_res", false)):
		var authored_font_size := maxi(1, label.font_size)
		var authored_pixel_size := label.pixel_size
		var physical_width := float(label.width) * authored_pixel_size
		label.font_size = maxi(HIGH_RES_FONT_SIZE, authored_font_size)
		label.pixel_size = (
			authored_pixel_size * float(authored_font_size) / float(label.font_size)
		)
		label.width = maxi(1, roundi(physical_width / label.pixel_size))
		if label.line_spacing != 0:
			label.line_spacing = roundi(
				float(label.line_spacing) * float(label.font_size) / float(authored_font_size)
			)
		label.set_meta(&"authored_font_size", authored_font_size)
		label.set_meta(&"authored_pixel_size", authored_pixel_size)
		label.set_meta(&"house_type_high_res", true)
	label.font = _font_for(style_family, emphasized)
	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT
		if style_family in [&"screen", &"paper_notice", &"hosted_header"]
		else HORIZONTAL_ALIGNMENT_CENTER
	)
	label.outline_size = 0
	label.shaded = style_family != &"screen"
	label.set_meta(&"type_role", _type_role(style_family, emphasized))
	_apply_visibility_range(label, &"utility", style_family)


static func _style_family(tier: StringName, mount_kind: StringName, is_screen: bool) -> StringName:
	if is_screen or mount_kind == &"screen":
		return &"screen"
	if mount_kind == &"room":
		return &"room_plaque"
	if mount_kind == &"machine" or mount_kind == &"shelf":
		return &"enamel_plate"
	if mount_kind == &"desk":
		return &"desk_plaque"
	if mount_kind == &"partition":
		return &"partition_insert"
	if mount_kind == &"shipping":
		return &"adhesive_label"
	if mount_kind == &"stencil":
		return &"surface_stencil"
	if mount_kind == &"chart":
		return &"chart_header"
	if mount_kind == &"portrait":
		return &"portrait_masthead"
	if mount_kind == &"beam":
		return &"beam_letters"
	if mount_kind == &"suspended":
		return &"suspended_notice"
	if mount_kind == &"paper":
		return &"paper_notice"
	if mount_kind == &"memo":
		return &"paper_notice"
	if mount_kind == &"board_header" or mount_kind == &"host":
		return &"hosted_header"
	if tier == &"primary":
		return &"bureau_plaque"
	return &"paper_notice"


static func _is_overview_anchor(style_family: StringName, tier: StringName) -> bool:
	return (
		style_family in [
			&"architectural_letters", &"beam_letters",
		]
		or (style_family == &"screen" and tier == &"secondary")
	)


static func _build_mount(
	fixture: Node3D,
	panel_size: Vector2,
	panel_color: Color,
	ink_color: Color,
	style_family: StringName,
	formal_treatment: bool
) -> void:
	match style_family:
		&"bureau_plaque":
			_build_bureau_plaque(fixture, panel_size, panel_color, ink_color)
		&"room_plaque":
			_build_room_plaque(fixture, panel_size, panel_color, ink_color)
		&"screen":
			_build_screen(fixture, panel_size, panel_color)
		&"enamel_plate":
			_build_enamel_plate(fixture, panel_size, panel_color)
		&"desk_plaque":
			_build_desk_plaque(fixture, panel_size, panel_color)
		&"partition_insert":
			_build_partition_insert(fixture, panel_size, panel_color)
		&"adhesive_label":
			_build_adhesive_label(fixture, panel_size, panel_color, ink_color)
		&"surface_stencil":
			_build_surface_stencil(fixture, panel_size, panel_color, ink_color)
		&"suspended_notice":
			_build_suspended_notice(fixture, panel_size, panel_color, ink_color)
		&"hosted_header":
			_build_hosted_header(fixture, panel_size, ink_color)
		&"chart_header":
			_build_chart_header(fixture, panel_size, panel_color, ink_color)
		&"portrait_masthead":
			_build_portrait_masthead(fixture, panel_size, panel_color, ink_color)
		&"beam_letters":
			_build_beam_letters(fixture, panel_size, panel_color, ink_color)
		_:
			_build_paper_notice(
				fixture, panel_size, panel_color, ink_color, formal_treatment
			)


static func _build_bureau_plaque(fixture: Node3D, size: Vector2, color: Color, ink: Color) -> void:
	_add_box(fixture, "Frame", Vector3(size.x + 0.08, size.y + 0.08, 0.048), Vector3(0.0, 0.0, -0.014), WARM_LAMINATE, 0.76)
	_add_box(fixture, "Backplate", Vector3(size.x, size.y, 0.026), Vector3(0.0, 0.0, 0.010), color.darkened(0.08), 0.58)
	_add_box(fixture, "InsetGoldRail", Vector3(size.x - 0.12, 0.018, 0.012), Vector3(0.0, -size.y * 0.5 + 0.048, 0.028), ink.darkened(0.08), 0.50)
	_add_box(fixture, "IdentityTab", Vector3(0.10, size.y * 0.46, 0.020), Vector3(-size.x * 0.5 + 0.095, 0.0, 0.041), Color("a86148"), 0.72)
	_add_egg_seal(fixture, Vector3(size.x * 0.5 - 0.12, 0.0, 0.031), minf(size.y * 0.28, 0.10), ink)


static func _build_room_plaque(
	fixture: Node3D,
	size: Vector2,
	color: Color,
	ink: Color
) -> void:
	# Compact institutional laminate: it belongs to the wall rather than to a
	# machine, so it has real face fasteners without equipment brackets.
	_add_box(
		fixture, "Backplate", Vector3(size.x, size.y, 0.018),
		Vector3(0.0, 0.0, 0.009), color.darkened(0.025), 0.62
	)
	_add_box(
		fixture, "RoomPlaqueAccent", Vector3(0.055, size.y * 0.68, 0.004),
		Vector3(-size.x * 0.5 + 0.050, 0.0, 0.020),
		Color("d0a54f"), 0.64
	)
	_add_egg_seal(
		fixture,
		Vector3(size.x * 0.5 - 0.070, 0.0, 0.023),
		minf(size.y * 0.15, 0.045),
		ink.lightened(0.16)
	)
	_add_box(
		fixture, "RoomPlaqueRule", Vector3(size.x * 0.74, 0.010, 0.003),
		Vector3(0.0, -size.y * 0.5 + 0.048, 0.0195),
		ink.lightened(0.22), 0.72
	)
	for fastener_x in [-1.0, 1.0]:
		_add_fastener(
			fixture,
			Vector3(fastener_x * (size.x * 0.5 - 0.055), 0.0, 0.022),
			Color("a99467")
		)


static func _build_paper_notice(
	fixture: Node3D,
	size: Vector2,
	color: Color,
	ink: Color,
	formal_treatment: bool
) -> void:
	# Real pinned paper is a few millimetres thick. It casts a physical shadow;
	# it does not carry a baked, offset UI-card shadow behind it.
	var paper_variation := _deterministic_signed(String(fixture.name), 1)
	var paper_color := color.lightened(0.035 + paper_variation * 0.012)
	var contact_shadow := _add_box(
		fixture, "PaperContactShadow",
		Vector3(size.x + 0.010, size.y + 0.010, 0.0006),
		Vector3(0.0025, -0.0030, -0.0005),
		Color("5b5146"), 1.0
	)
	contact_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_box(
		fixture, "Backplate", Vector3(size.x, size.y, 0.0025),
		Vector3(0.0, 0.0, 0.00125), paper_color, 0.97
	)
	var header_rule := _add_box(
		fixture, "PrintedHeaderRule", Vector3(size.x * 0.78, 0.009, 0.0012),
		Vector3(0.0, size.y * 0.5 - 0.052, 0.0031),
		ink.darkened(0.04), 0.94
	)
	header_rule.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if formal_treatment:
		_add_box(
			fixture, "DocumentIndexTab", Vector3(0.085, 0.028, 0.0015),
			Vector3(-size.x * 0.5 + 0.065, size.y * 0.5 - 0.052, 0.0034),
			Color("a95f4c"), 0.88
		)
		_add_box(
			fixture, "DocumentFooterRule", Vector3(size.x * 0.42, 0.006, 0.0010),
			Vector3(-size.x * 0.18, -size.y * 0.5 + 0.047, 0.0030),
			ink.lightened(0.42), 0.96
		)
		_add_egg_seal(
			fixture,
			Vector3(size.x * 0.5 - 0.068, -size.y * 0.5 + 0.062, 0.0040),
			minf(size.y * 0.058, 0.027),
			ink.lightened(0.18)
		)
	# Quiet form rules and a filing code make the sheet read as a used document
	# before any glyph is legible. They deliberately stay close to the paper tone.
	for rule_index in 3:
		var body_rule := _add_box(
			fixture,
			"DocumentBodyRule_%d" % rule_index,
			Vector3(size.x * (0.54 - rule_index * 0.06), 0.004, 0.0008),
			Vector3(
				-size.x * (0.08 + rule_index * 0.015),
				-size.y * (0.12 + rule_index * 0.13),
				0.0030
			),
			ink.lightened(0.56),
			0.98
		)
		body_rule.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var file_mark := _add_box(
		fixture,
		"DocumentFileMark",
		Vector3(size.x * 0.12, size.y * 0.08, 0.0010),
		Vector3(size.x * 0.34, -size.y * 0.36, 0.0033),
		Color("a76654").lerp(paper_color, 0.28),
		0.92
	)
	file_mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for pin_x in [-1.0, 1.0]:
		_add_fastener(
			fixture,
			Vector3(pin_x * (size.x * 0.5 - 0.048), size.y * 0.5 - 0.048, 0.0065),
			Color("b29661")
		)
		_add_box(
			fixture,
			"PaperTapeLeft" if pin_x < 0.0 else "PaperTapeRight",
			Vector3(size.x * 0.14, 0.036, 0.0014),
			Vector3(pin_x * size.x * 0.32, size.y * 0.5 + 0.004, 0.0048),
			Color("c8b77d"),
			0.96
		)


static func _build_enamel_plate(fixture: Node3D, size: Vector2, color: Color) -> void:
	# A small, workmanlike asset plate. The former black frame, gold stripe, and
	# oversized brackets made every caption read like a collectible-card border.
	_add_box(
		fixture, "EquipmentPlateLip",
		Vector3(size.x + 0.028, size.y + 0.028, 0.014),
		Vector3(0.0, 0.0, -0.002), color.darkened(0.16), 0.48, 0.18
	)
	_add_box(
		fixture, "Backplate", Vector3(size.x, size.y, 0.010),
		Vector3(0.0, 0.0, 0.007), color.lerp(Color("b8b7a8"), 0.12), 0.72
	)
	for fastener_x in [-1.0, 1.0]:
		_add_fastener(
			fixture,
			Vector3(fastener_x * (size.x * 0.5 - 0.035), 0.0, 0.016),
			Color("8e927f")
		)


static func _build_desk_plaque(fixture: Node3D, size: Vector2, color: Color) -> void:
	# Warm laminate and a slim brass reveal make the employee identity look like
	# cubicle furniture, not a black HUD pill. The clips remain visibly attached to
	# the partition and the inset is deep enough to catch a small physical shadow.
	_add_box(
		fixture, "Frame", Vector3(size.x + 0.050, size.y + 0.050, 0.034),
		Vector3(0.0, 0.0, -0.010), WARM_LAMINATE.darkened(0.05), 0.72
	)
	_add_box(
		fixture, "DeskPlaqueBrassReveal", Vector3(size.x + 0.018, size.y + 0.018, 0.016),
		Vector3(0.0, 0.0, 0.009), BRASS_INK.darkened(0.20), 0.48, 0.55
	)
	_add_box(
		fixture, "Backplate", Vector3(size.x, size.y, 0.018),
		Vector3(0.0, 0.0, 0.020), color, 0.78
	)
	_add_box(
		fixture, "DeskPlaqueBaseline", Vector3(size.x * 0.66, 0.008, 0.003),
		Vector3(size.x * 0.06, -size.y * 0.5 + 0.042, 0.031),
		DEEP_TEAL.lightened(0.08), 0.76
	)
	_add_box(fixture, "PartitionClipLeft", Vector3(0.035, size.y + 0.10, 0.040), Vector3(-size.x * 0.5 - 0.030, -0.014, -0.013), Color("8b7959"), 0.38, 0.72)
	_add_box(fixture, "PartitionClipRight", Vector3(0.035, size.y + 0.10, 0.040), Vector3(size.x * 0.5 + 0.030, -0.014, -0.013), Color("8b7959"), 0.38, 0.72)
	_add_egg_seal(fixture, Vector3(-size.x * 0.5 + 0.052, 0.0, 0.033), minf(size.y * 0.11, 0.027), Color("b5924f"))


static func _build_partition_insert(fixture: Node3D, size: Vector2, color: Color) -> void:
	# Cheap interchangeable office furniture is the right language for a cubicle.
	# A muted paper slip sits inside two shallow rails; no brass, seal, or frame.
	_add_box(
		fixture, "PartitionInsertShadow",
		Vector3(size.x + 0.028, size.y + 0.030, 0.006),
		Vector3(0.008, -0.008, -0.002), Color("49534f"), 0.94
	)
	_add_box(
		fixture, "Backplate", Vector3(size.x, size.y, 0.004),
		Vector3(0.0, 0.0, 0.008), color.lerp(Color("d8d4c5"), 0.58), 0.94
	)
	var rail_color := CUBICLE_GREEN.darkened(0.06)
	_add_box(
		fixture, "PartitionRailTop", Vector3(size.x + 0.045, 0.027, 0.014),
		Vector3(0.0, size.y * 0.5 + 0.006, 0.006), rail_color, 0.66
	)
	_add_box(
		fixture, "PartitionRailBottom", Vector3(size.x + 0.045, 0.027, 0.014),
		Vector3(0.0, -size.y * 0.5 - 0.006, 0.006), rail_color, 0.66
	)
	_add_box(
		fixture, "PartitionClipLeft", Vector3(0.025, size.y + 0.045, 0.014),
		Vector3(-size.x * 0.5 - 0.010, 0.0, 0.005), rail_color.darkened(0.06), 0.58
	)
	_add_box(
		fixture, "PartitionClipRight", Vector3(0.025, size.y + 0.045, 0.014),
		Vector3(size.x * 0.5 + 0.010, 0.0, 0.005), rail_color.darkened(0.06), 0.58
	)


static func _build_adhesive_label(
	fixture: Node3D,
	size: Vector2,
	color: Color,
	ink: Color
) -> void:
	# Warehouse labels are glued directly to cartons and crates. Their almost-flat
	# contact shadow and faint form rules make the attachment legible up close.
	_add_box(
		fixture, "AdhesiveShadow", Vector3(size.x + 0.018, size.y + 0.018, 0.0010),
		Vector3(0.006, -0.006, -0.0004), Color("574c3f"), 1.0
	)
	_add_box(
		fixture, "Backplate", Vector3(size.x, size.y, 0.0018),
		Vector3.ZERO, color.lightened(0.035), 0.98
	)
	_add_box(
		fixture, "ShippingRule", Vector3(size.x * 0.84, 0.005, 0.0008),
		Vector3(0.0, -size.y * 0.5 + 0.030, 0.0014),
		ink.lerp(color, 0.42), 0.96
	)
	_add_box(
		fixture, "ShippingCodeBlock", Vector3(size.x * 0.10, size.y * 0.20, 0.0008),
		Vector3(size.x * 0.39, size.y * 0.27, 0.0014),
		ink.lerp(color, 0.58), 0.96
	)


static func _build_surface_stencil(
	fixture: Node3D,
	size: Vector2,
	color: Color,
	ink: Color
) -> void:
	# Direct paint belongs to the underlying machine or wooden prop. The bed is
	# deliberately the host color and only millimetres thick, so there is no card
	# silhouette competing with the object itself.
	_add_box(
		fixture, "Backplate", Vector3(size.x, size.y, 0.0018),
		Vector3.ZERO, color, 0.92
	)
	_add_box(
		fixture, "StencilRegistrationTick", Vector3(size.x * 0.11, 0.004, 0.0008),
		Vector3(-size.x * 0.39, -size.y * 0.5 + 0.022, 0.0014),
		ink.lerp(color, 0.52), 0.90
	)


static func _build_screen(fixture: Node3D, size: Vector2, color: Color) -> void:
	_add_box(fixture, "Frame", Vector3(size.x + 0.14, size.y + 0.14, 0.090), Vector3(0.0, 0.0, -0.030), Color("354247"), 0.58)
	_add_box(fixture, "Backplate", Vector3(size.x, size.y, 0.034), Vector3(0.0, 0.0, 0.010), color.darkened(0.18), 0.34, 0.0, true)
	# Glass decoration belongs behind the glyph plane. It previously protruded in
	# front of the Label3D at z=0.029 and sliced through letters under depth test.
	_add_box(fixture, "ScreenHeaderRail", Vector3(size.x * 0.82, 0.020, 0.0010), Vector3(-size.x * 0.02, size.y * 0.5 - 0.060, 0.0272), Color("78aa91"), 0.38, 0.0, true, 0.22)
	for scanline_index in 3:
		var line_y := -size.y * 0.30 + scanline_index * size.y * 0.20
		_add_box(fixture, "ScreenScanline", Vector3(size.x * 0.88, 0.006, 0.0008), Vector3(0.0, line_y, 0.0271), color.lightened(0.05), 0.44, 0.0, true, 0.05)
	_add_fastener(fixture, Vector3(-size.x * 0.5 + 0.052, -size.y * 0.5 + 0.052, 0.045), Color("728084"))
	_add_status_lamp(fixture, Vector3(size.x * 0.5 - 0.062, -size.y * 0.5 + 0.058, 0.047), Color("75b596"))


static func _build_suspended_notice(fixture: Node3D, size: Vector2, color: Color, ink: Color) -> void:
	_add_box(fixture, "Frame", Vector3(size.x + 0.08, size.y + 0.08, 0.052), Vector3(0.0, 0.0, -0.020), Color("66513a"), 0.72)
	_add_box(fixture, "Backplate", Vector3(size.x, size.y, 0.024), Vector3(0.0, 0.0, 0.014), color, 0.90)
	_add_box(fixture, "PrintedHeaderRule", Vector3(size.x * 0.82, 0.020, 0.008), Vector3(0.0, size.y * 0.5 - 0.065, 0.036), ink.darkened(0.08), 0.82)
	for hanger_x in [-1.0, 1.0]:
		var rod_name := "SuspensionRodLeft" if hanger_x < 0.0 else "SuspensionRodRight"
		_add_box(fixture, rod_name, Vector3(0.025, 0.36, 0.025), Vector3(hanger_x * size.x * 0.34, size.y * 0.5 + 0.20, -0.015), Color("67625a"), 0.42, 1.0)
		_add_fastener(fixture, Vector3(hanger_x * size.x * 0.34, size.y * 0.5 - 0.035, 0.040), Color("b79d68"))


static func _build_hosted_header(fixture: Node3D, size: Vector2, ink: Color) -> void:
	# The host object already supplies the panel/frame. Add only a silk-screened
	# equipment band, rule, and registration tab so the lettering belongs to it.
	_add_box(
		fixture, "HostHeaderBand", Vector3(size.x, size.y, 0.006),
		Vector3.ZERO, DEEP_TEAL, 0.68
	)
	_add_box(fixture, "HostHeaderRule", Vector3(size.x * 0.90, 0.012, 0.002), Vector3(0.0, -size.y * 0.5 + 0.030, 0.002), ink.darkened(0.12), 0.76)
	_add_box(fixture, "HostIdentityTab", Vector3(0.065, size.y * 0.30, 0.002), Vector3(-size.x * 0.5 + 0.050, 0.0, 0.002), Color("a9634d"), 0.86)
	_add_box(
		fixture,
		"HostRegistrationTick",
		Vector3(size.x * 0.10, 0.008, 0.002),
		Vector3(size.x * 0.37, size.y * 0.26, 0.002),
		ink.darkened(0.28),
		0.86
	)


static func _build_chart_header(
	fixture: Node3D,
	size: Vector2,
	color: Color,
	ink: Color
) -> void:
	# This field is printed directly into the chart backing. It deliberately lacks
	# the dark rounded-tab silhouette used by live UI and equipment screens.
	_add_box(
		fixture, "HostPrintField", Vector3(size.x, size.y, 0.004),
		Vector3.ZERO, color, 0.94
	)
	_add_box(
		fixture, "ChartHeaderRule", Vector3(size.x * 0.86, 0.012, 0.002),
		Vector3(0.0, -size.y * 0.5 + 0.035, 0.003), ink, 0.90
	)
	_add_box(
		fixture, "ChartIndexBlock", Vector3(0.060, size.y * 0.42, 0.002),
		Vector3(-size.x * 0.5 + 0.055, 0.0, 0.003), Color("c19a4c"), 0.86
	)


static func _build_portrait_masthead(
	fixture: Node3D,
	size: Vector2,
	color: Color,
	ink: Color
) -> void:
	# An award-card masthead belongs to the portrait mat and uses paper, ink, and
	# a small foil rule instead of the management monitor's screen band.
	_add_box(
		fixture, "PortraitTitleMat", Vector3(size.x, size.y, 0.005),
		Vector3.ZERO, color, 0.96
	)
	_add_box(
		fixture, "PortraitFoilRule", Vector3(size.x * 0.74, 0.010, 0.002),
		Vector3(0.0, -size.y * 0.5 + 0.035, 0.004), BRASS_INK, 0.54, 0.42
	)
	for fastener_x in [-1.0, 1.0]:
		_add_fastener(
			fixture,
			Vector3(fastener_x * (size.x * 0.5 - 0.045), 0.0, 0.009),
			ink.lightened(0.28)
		)


static func _build_beam_letters(
	fixture: Node3D,
	size: Vector2,
	color: Color,
	ink: Color
) -> void:
	# A near-invisible letter bed shares the host beam's color; the narrow brass
	# baseline and dimensional shadow make the copy feel fixed to the perch.
	_add_box(
		fixture, "BeamLetterBed", Vector3(size.x, size.y, 0.005),
		Vector3.ZERO, color, 0.78
	)
	_add_box(
		fixture, "BeamLetterRail", Vector3(size.x * 0.84, 0.014, 0.003),
		Vector3(0.0, -size.y * 0.5 + 0.034, 0.004), ink.darkened(0.14), 0.56, 0.34
	)
	_add_egg_seal(
		fixture,
		Vector3(-size.x * 0.5 + 0.070, 0.0, 0.009),
		minf(size.y * 0.13, 0.038),
		ink.darkened(0.06)
	)


static func _add_printed_label(
	fixture: Node3D,
	label_name: String,
	copy: String,
	position: Vector3,
	text_area: Vector2,
	font_size: int,
	requested_pixel_size: float,
	ink_color: Color,
	substrate_color: Color,
	style_family: StringName,
	emphasized: bool,
	detail_role: StringName = &"body"
) -> Label3D:
	var label := Label3D.new()
	label.name = label_name
	label.text = copy
	label.position = position
	label.font = _font_for(style_family, emphasized)
	var authored_font_size := maxi(1, font_size)
	label.font_size = maxi(HIGH_RES_FONT_SIZE, authored_font_size)
	var high_res_requested_pixel_size := (
		requested_pixel_size * float(authored_font_size) / float(label.font_size)
	)
	# Each physical medium has an authored density. Environmental copy may shrink
	# to avoid overflow, but short labels no longer expand to button-like full-face
	# proportions merely because spare panel area exists.
	var measured_atlas_size := label.font.get_multiline_string_size(
		copy,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		label.font_size
	)
	var minimum_height_fill := 0.22
	if style_family == &"screen":
		minimum_height_fill = 0.48
	elif style_family == &"architectural_letters":
		minimum_height_fill = 0.46 if emphasized else 0.24
	elif style_family in [&"paper_notice", &"adhesive_label"]:
		minimum_height_fill = 0.27 if emphasized else 0.17
	elif style_family == &"partition_insert":
		minimum_height_fill = 0.24 if emphasized else 0.13
	elif style_family == &"surface_stencil":
		minimum_height_fill = 0.20 if emphasized else 0.12
	elif style_family == &"enamel_plate":
		minimum_height_fill = 0.22 if emphasized else 0.13
	elif style_family in [&"hosted_header", &"chart_header", &"portrait_masthead", &"beam_letters"]:
		minimum_height_fill = 0.32
	elif style_family == &"desk_plaque":
		minimum_height_fill = 0.34 if emphasized else 0.20
	elif emphasized:
		minimum_height_fill = 0.34
	high_res_requested_pixel_size = maxf(
		high_res_requested_pixel_size,
		text_area.y * minimum_height_fill / maxf(1.0, measured_atlas_size.y)
	)
	label.pixel_size = _fitted_pixel_size(
		copy,
		text_area,
		label.font,
		label.font_size,
		high_res_requested_pixel_size,
		style_family == &"screen"
	)
	label.width = maxi(1, floori(text_area.x * 0.90 / label.pixel_size))
	label.line_spacing = -6 if copy.contains("\n") else 0
	label.outline_size = 0
	label.modulate = _surface_ink(ink_color, substrate_color, style_family, emphasized)
	label.set_meta(&"resting_alpha", label.modulate.a)
	label.outline_modulate = Color(0.02, 0.03, 0.035, 0.72)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.no_depth_test = false
	label.fixed_size = false
	label.shaded = style_family != &"screen"
	label.double_sided = false
	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT
		if style_family in [
			&"screen", &"paper_notice", &"adhesive_label",
			&"partition_insert", &"hosted_header",
		]
		else HORIZONTAL_ALIGNMENT_CENTER
	)
	# Label3D lays a left-aligned line box forward from its local origin. Move the
	# origin to the printable area's left inset so paper and screen copy uses the
	# full face instead of appearing pasted into the right-hand half.
	if label.horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT:
		label.position.x -= text_area.x * 0.45
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	label.set_meta(&"requested_pixel_size", high_res_requested_pixel_size)
	label.set_meta(&"authored_font_size", authored_font_size)
	label.set_meta(&"authored_pixel_size", requested_pixel_size)
	label.set_meta(&"minimum_height_fill", minimum_height_fill)
	label.set_meta(&"fitted_pixel_size", label.pixel_size)
	label.set_meta(&"text_area_size", text_area)
	label.set_meta(&"screen_copy", style_family == &"screen")
	label.set_meta(&"emphasized", emphasized)
	label.set_meta(&"type_role", _type_role(style_family, emphasized))
	label.set_meta(&"environmental_copy", true)
	label.set_meta(&"surface_printed", true)
	label.set_meta(&"substrate_color", substrate_color)
	label.set_meta(&"sign_tier", StringName(fixture.get_meta(&"sign_tier", &"utility")))
	label.set_meta(&"detail_role", detail_role)
	_apply_visibility_range(
		label,
		StringName(fixture.get_meta(&"sign_tier", &"secondary")),
		style_family
	)
	fixture.add_child(label)
	return label


static func _add_letterpress_shadow(fixture: Node3D, source: Label3D, ink_color: Color) -> void:
	var shadow := Label3D.new()
	shadow.name = "%sLetterpressShadow" % source.name
	shadow.text = source.text
	shadow.position = source.position + Vector3(0.0014, -0.0014, -0.0007)
	shadow.font_size = source.font_size
	shadow.font = source.font
	shadow.pixel_size = source.pixel_size
	shadow.width = source.width
	shadow.outline_size = 0
	shadow.modulate = ink_color.darkened(0.72)
	shadow.set_meta(&"resting_alpha", shadow.modulate.a)
	shadow.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	shadow.no_depth_test = false
	shadow.fixed_size = false
	shadow.shaded = true
	shadow.double_sided = false
	shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shadow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shadow.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	shadow.visibility_range_begin = source.visibility_range_begin
	shadow.visibility_range_begin_margin = source.visibility_range_begin_margin
	shadow.visibility_range_end = source.visibility_range_end
	shadow.visibility_range_end_margin = source.visibility_range_end_margin
	shadow.visibility_range_fade_mode = source.visibility_range_fade_mode
	# The impressed under-layer is still part of the printed copy. Give it the same
	# detail metadata so spatial LOD cannot leave ghost lettering on an otherwise
	# blank distant plate.
	shadow.set_meta(&"environmental_copy", true)
	shadow.set_meta(&"surface_printed", true)
	shadow.set_meta(&"sign_tier", source.get_meta(&"sign_tier", &"utility"))
	shadow.set_meta(&"detail_role", source.get_meta(&"detail_role", &"body"))
	shadow.set_meta(&"type_role", &"letterpress_shadow")
	fixture.add_child(shadow)
	fixture.move_child(shadow, source.get_index())


static func _fitted_pixel_size(
	copy: String,
	panel_size: Vector2,
	font: Font,
	font_size: int,
	requested: float,
	is_screen: bool
) -> float:
	var measured := Vector2.ONE
	if font != null:
		measured = font.get_multiline_string_size(
			copy,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			font_size
		)
	measured.x = maxf(1.0, measured.x)
	measured.y = maxf(1.0, measured.y)
	var width_fit := panel_size.x * (0.86 if is_screen else 0.80) / measured.x
	var height_fit := panel_size.y * (0.84 if is_screen else 0.76) / measured.y
	# `requested` is the house type scale, not a hard minimum. Short copy may grow
	# toward the available plate while long copy is allowed to shrink below it.
	var target := requested
	# Never clamp back up to a percentage of the authored size: doing so allowed
	# unusually long dynamic data to spill beyond its physical glass.
	return maxf(MIN_FITTED_PIXEL_SIZE, minf(target, minf(width_fit, height_fit)))


static func _surface_ink(
	ink_color: Color,
	substrate_color: Color,
	style_family: StringName,
	emphasized: bool
) -> Color:
	# Printed copy borrows a little of the material beneath it. This removes the
	# pure, luminous UI contrast while keeping close-up text readable.
	var substrate_blend := 0.12 if emphasized else 0.20
	if style_family == &"screen":
		substrate_blend = 0.15
	elif style_family == &"architectural_letters":
		substrate_blend = 0.10 if emphasized else 0.24
	elif style_family == &"paper_notice":
		substrate_blend = 0.18 if emphasized else 0.30
	elif style_family == &"adhesive_label":
		substrate_blend = 0.28 if emphasized else 0.38
	elif style_family == &"partition_insert":
		substrate_blend = 0.24 if emphasized else 0.36
	elif style_family == &"surface_stencil":
		substrate_blend = 0.32 if emphasized else 0.42
	elif style_family == &"desk_plaque":
		substrate_blend = 0.14
	elif style_family == &"chart_header":
		substrate_blend = 0.22
	elif style_family == &"portrait_masthead":
		substrate_blend = 0.18
	elif style_family == &"beam_letters":
		substrate_blend = 0.08
	var result := ink_color.lerp(substrate_color, substrate_blend)
	# Printed pigment is faded by borrowing the substrate's RGB, not by making
	# the glyph translucent. Semi-transparent shaded text turned into gray noise
	# at oblique management-camera angles and looked composited over the room.
	result.a = 1.0 if emphasized else 0.97
	if style_family == &"screen":
		result.a = 1.0
	return result


static func _text_depth(style_family: StringName) -> float:
	match style_family:
		&"screen":
			return 0.029
		&"paper_notice":
			return 0.0050
		&"adhesive_label":
			return 0.0032
		&"surface_stencil":
			return 0.0030
		&"partition_insert":
			return 0.0135
		&"room_plaque":
			return 0.021
		&"desk_plaque":
			return 0.033
		&"enamel_plate":
			return 0.0145
		&"suspended_notice":
			return 0.028
		&"hosted_header":
			return 0.004
		&"chart_header":
			return 0.007
		&"portrait_masthead":
			return 0.008
		&"beam_letters":
			return 0.008
		&"architectural_letters":
			return 0.027
		_:
			return 0.026


static func _apply_visibility_range(
	label: Label3D,
	tier: StringName,
	style_family: StringName
) -> void:
	# The management camera remains roughly 32 m from its focus even while it
	# pans, so these generous ranges retain every important identifier while
	# allowing tiny utility copy at the far edge of the cutaway to recede first.
	var range_end := 48.0
	var fade_margin := 7.0
	if tier == &"primary":
		range_end = 64.0
		fade_margin = 10.0
	elif style_family == &"screen":
		range_end = 56.0
		fade_margin = 8.0
	elif style_family == &"room_plaque" or tier == &"secondary":
		range_end = 50.0
		fade_margin = 8.0
	elif tier == &"utility":
		range_end = 43.0
		fade_margin = 6.0
	label.visibility_range_begin = 0.0
	label.visibility_range_begin_margin = 0.0
	label.visibility_range_end = range_end
	label.visibility_range_end_margin = fade_margin
	label.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


static func _deterministic_signed(key: String, salt: int) -> float:
	var bucket := posmod(key.hash() + salt * 7919, 2001)
	return float(bucket) / 1000.0 - 1.0


static func _font_for(style_family: StringName, emphasized: bool) -> Font:
	var key := "%s_%s" % [style_family, str(emphasized)]
	if _font_cache.has(key):
		return _font_cache[key] as Font
	var font := FontVariation.new()
	font.base_font = _base_font_for(style_family, emphasized)
	var width_scale := 1.0
	var weight := 0.0
	if style_family == &"screen":
		width_scale = 0.96
	elif style_family == &"architectural_letters" or emphasized:
		weight = 0.12
	elif style_family == &"room_plaque":
		weight = 0.08
	elif style_family == &"paper_notice":
		width_scale = 0.98
	elif style_family in [&"adhesive_label", &"partition_insert"]:
		width_scale = 0.96
	elif style_family == &"surface_stencil":
		width_scale = 0.92
	font.variation_embolden = weight
	font.variation_transform = Transform2D(
		Vector2(width_scale, 0.0),
		Vector2(0.0, 1.0),
		Vector2.ZERO
	)
	_font_cache[key] = font
	return font


static func _base_font_for(style_family: StringName, emphasized: bool) -> Font:
	if style_family == &"screen":
		return _source_font(LEDGER_SEMIBOLD_PATH if emphasized else LEDGER_REGULAR_PATH)
	if style_family in [&"paper_notice", &"adhesive_label", &"portrait_masthead"]:
		return _source_font(PAPER_BOLD_PATH if emphasized else PAPER_REGULAR_PATH)
	return _source_font(BUREAU_SEMIBOLD_PATH if emphasized else BUREAU_REGULAR_PATH)


static func _source_font(path: String) -> Font:
	if _source_font_cache.has(path):
		return _source_font_cache[path] as Font
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		push_warning("Environmental signage could not read authored font: %s" % path)
		return ThemeDB.fallback_font
	var font := FontFile.new()
	font.generate_mipmaps = true
	font.data = bytes
	font.resource_name = path.get_file()
	font.set_meta(&"authored_source_path", path)
	_source_font_cache[path] = font
	return font


static func _type_role(style_family: StringName, emphasized: bool) -> StringName:
	if style_family == &"screen":
		return &"live_data"
	if style_family == &"architectural_letters":
		return &"identity"
	if style_family == &"room_plaque":
		return &"room_identity"
	if style_family == &"chart_header":
		return &"printed_chart_title"
	if style_family == &"portrait_masthead":
		return &"award_masthead"
	if style_family == &"beam_letters":
		return &"raised_beam_identity"
	if style_family == &"paper_notice":
		return &"document_heading" if emphasized else &"document_body"
	if style_family == &"adhesive_label":
		return &"shipping_heading" if emphasized else &"shipping_detail"
	if style_family == &"partition_insert":
		return &"employee_name" if emphasized else &"employee_role"
	if style_family == &"surface_stencil":
		return &"equipment_stencil"
	if style_family == &"hosted_header":
		return &"host_label"
	return &"display" if emphasized else &"utility"


static func _add_box(
	parent: Node3D,
	part_name: String,
	size: Vector3,
	position: Vector3,
	color: Color,
	roughness: float,
	metallic: float = 0.0,
	emissive: bool = false,
	emission_energy: float = 0.28
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _material(color, roughness, metallic, emissive, emission_energy)
	parent.add_child(instance)
	return instance


static func _add_fastener(parent: Node3D, position: Vector3, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.012
	mesh.bottom_radius = 0.014
	mesh.height = 0.010
	mesh.radial_segments = 10
	var fastener := MeshInstance3D.new()
	fastener.name = "MountFastener"
	fastener.mesh = mesh
	fastener.position = position
	fastener.rotation_degrees.x = 90.0
	fastener.material_override = _material(color, 0.30, 1.0)
	parent.add_child(fastener)


static func _add_status_lamp(parent: Node3D, position: Vector3, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.rings = 4
	var lamp := MeshInstance3D.new()
	lamp.name = "ScreenStatusLamp"
	lamp.mesh = mesh
	lamp.position = position
	lamp.scale = Vector3.ONE * 0.024
	lamp.material_override = _material(color, 0.30, 0.0, true, 0.45)
	parent.add_child(lamp)


static func _add_egg_seal(parent: Node3D, position: Vector3, radius: float, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 10
	mesh.rings = 6
	var seal := MeshInstance3D.new()
	seal.name = "BureauEggSeal"
	seal.mesh = mesh
	seal.position = position
	seal.scale = Vector3(radius * 0.74, radius, 0.020)
	seal.material_override = _material(color.lightened(0.08), 0.52)
	parent.add_child(seal)


static func _material(
	color: Color,
	roughness: float,
	metallic: float = 0.0,
	emissive: bool = false,
	emission_energy: float = 0.28
) -> StandardMaterial3D:
	# These props share a deliberately small material vocabulary; this keeps the
	# signage visually coherent and avoids one material resource per fixture.
	var metal_value := clampf(metallic, 0.0, 1.0)
	var key := "%s_%.2f_%.2f_%s_%.2f" % [color.to_html(true), roughness, metal_value, str(emissive), emission_energy]
	if _material_cache.has(key):
		return _material_cache[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.22) if emissive else color
	material.roughness = roughness
	material.metallic = metal_value
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	_material_cache[key] = material
	return material
