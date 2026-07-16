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

const WARM_LAMINATE := Color("6b5542")
const CUBICLE_GREEN := Color("536c64")
const CORPORATE_TEAL := Color("315b60")
const CLAIMS_PAPER := Color("e0d9bd")
const BRASS_INK := Color("d5b866")
const DEEP_TEAL := Color("243f43")
const CREAM_INK := Color("f0e7ce")
const AGED_ENAMEL := Color("667061")
const BONE_LETTERS := Color("d7d0b7")
const CHARCOAL_INK := Color("39443f")
const BARN_ENAMEL := Color("2d5148")
const AGED_BRASS := Color("c4a45f")
const WARM_FORM_PAPER := Color("ddd5b9")
const CUBICLE_INSERT := Color("c7c9b7")
const MUTED_MACHINE_ENAMEL := Color("697369")

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
	var copy_band := _copy_band(tier, mount_kind, style_family)
	var substrate_color := _physical_substrate(style_family, panel_color)
	var formal_treatment := mount_kind == &"paper" or tier == &"primary"
	fixture.set_meta(&"sign_tier", tier)
	fixture.set_meta(&"mount_kind", mount_kind)
	fixture.set_meta(&"style_family", style_family)
	fixture.set_meta(&"copy_band", copy_band)
	fixture.set_meta(&"panel_size", panel_size)
	fixture.set_meta(&"authored_panel_color", panel_color)
	fixture.set_meta(&"physical_substrate_color", substrate_color)
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
	fixture.set_meta(&"overview_critical_readout", false)
	fixture.set_meta(&"overview_anchor", _is_overview_anchor(style_family, copy_band))
	fixture.set_meta(
		&"fixture_detail_only",
		style_family in [&"partition_insert", &"adhesive_label", &"room_plaque"]
	)
	if style_family in [&"paper_notice", &"adhesive_label"]:
		# A barely imperfect pinning angle keeps repeated notices from reading as
		# a screen-space card grid. The name hash makes the result deterministic.
		fixture.rotation_degrees.z += _deterministic_signed(label_name, 0) * (
			2.2 if style_family == &"paper_notice" else 0.72
		)
	parent.add_child(fixture)
	fixture.add_to_group(&"environmental_signage")

	_build_mount(
		fixture, panel_size, substrate_color, ink_color,
		style_family, formal_treatment
	)

	var split_copy := copy.split("\n", false, 1)
	var use_hierarchy := split_copy.size() > 1 and style_family != &"screen"
	var label: Label3D
	var hierarchy_body_label: Label3D = null
	if use_hierarchy:
		var heading := String(split_copy[0])
		var body := String(split_copy[1])
		# A real sign needs breathing room for its edge hardware and substrate.
		# Keeping type out of the outer eight percent also prevents long copy from
		# visually becoming the border of another screen-space card.
		var hierarchy_width := panel_size.x * 0.84
		var hierarchy_offset_x := 0.0
		if style_family == &"room_plaque":
			# Leave the enamel seal and end cap visible instead of centring a tiny
			# heading in a wide, empty rectangle.
			hierarchy_width = panel_size.x * 0.68
			hierarchy_offset_x = -panel_size.x * 0.055
		label = _add_printed_label(
			fixture, label_name, heading,
			Vector3(hierarchy_offset_x, panel_size.y * 0.15, _text_depth(style_family)),
			Vector2(hierarchy_width, panel_size.y * 0.43),
			font_size, pixel_size, ink_color, substrate_color,
			style_family, true, &"heading"
		)
		hierarchy_body_label = _add_printed_label(
			fixture, "%sBody" % label_name, body,
			Vector3(hierarchy_offset_x, -panel_size.y * 0.18, _text_depth(style_family)),
			Vector2(hierarchy_width, panel_size.y * 0.34),
			maxi(9, roundi(font_size * 0.72)), pixel_size * 0.86,
			ink_color.darkened(0.12), substrate_color,
			style_family, false, &"body"
		)
	else:
		var single_line_area := Vector2(panel_size.x * 0.86, panel_size.y * 0.76)
		if style_family == &"screen":
			single_line_area = Vector2(panel_size.x * 0.78, panel_size.y * 0.66)
		var single_emphasized := (
			tier == &"primary"
			or style_family in [&"chart_header", &"portrait_masthead", &"beam_letters"]
			or style_family == &"partition_insert"
			or (tier == &"secondary" and style_family == &"surface_stencil")
		)
		label = _add_printed_label(
			fixture, label_name, copy,
			Vector3(0.0, -0.006, _text_depth(style_family)),
			single_line_area,
			font_size, pixel_size, ink_color, substrate_color,
			style_family, single_emphasized,
			&"live" if style_family == &"screen" else &"heading"
		)

	if style_family == &"beam_letters":
		# Static department names are real shallow meshes, not camera-composited
		# glyph cards. Keep the fitted Label3D as an invisible semantic proxy so
		# tests and assistive diagnostics retain the authored copy.
		label.set_meta(&"host_embossed_copy", true)
		label.set_meta(&"dimensional_proxy", true)
		label.visible = false
		label.modulate.a = 0.0
		label.set_meta(&"resting_alpha", 0.0)
		fixture.set_meta(&"uses_host_embossed_type", true)
		fixture.set_meta(&"uses_modeled_type", true)
		_add_modeled_wordmark(
			fixture,
			"%sModeledType" % label_name,
			label.text,
			label.position,
			label.get_meta(&"text_area_size", panel_size) as Vector2,
			ink_color,
			substrate_color,
			style_family,
			copy_band,
			StringName(label.get_meta(&"detail_role", &"heading")),
			0.008,
		)
		if hierarchy_body_label != null:
			hierarchy_body_label.set_meta(&"host_embossed_copy", true)
			hierarchy_body_label.set_meta(&"dimensional_proxy", true)
			hierarchy_body_label.visible = false
			hierarchy_body_label.modulate.a = 0.0
			hierarchy_body_label.set_meta(&"resting_alpha", 0.0)
			_add_modeled_wordmark(
				fixture,
				"%sModeledType" % hierarchy_body_label.name,
				hierarchy_body_label.text,
				hierarchy_body_label.position,
				hierarchy_body_label.get_meta(&"text_area_size", panel_size) as Vector2,
				ink_color.darkened(0.12),
				substrate_color,
				style_family,
				copy_band,
				&"body",
				0.006,
				false,
			)
	elif (
		(tier == &"primary" and style_family == &"bureau_plaque")
		or style_family == &"room_plaque"
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
	## Permanent identity belongs to the architecture: a smooth, shallow wordmark
	## is enamelled into a laminate fascia instead of hovering as a UI card.
	var fixture := Node3D.new()
	fixture.name = "%sFixture" % fixture_name
	fixture.position = fixture_position
	fixture.rotation_degrees = fixture_rotation_degrees
	fixture.set_meta(&"sign_tier", &"primary")
	fixture.set_meta(&"mount_kind", &"architecture")
	fixture.set_meta(&"style_family", &"architectural_letters")
	fixture.set_meta(&"copy_band", &"identity")
	fixture.set_meta(&"panel_size", panel_size)
	fixture.set_meta(&"physical_host", false)
	fixture.set_meta(&"surface_integrated", true)
	fixture.set_meta(&"overview_critical_readout", false)
	fixture.set_meta(&"overview_anchor", true)
	parent.add_child(fixture)
	fixture.add_to_group(&"environmental_signage")

	_add_box(
		fixture, "IdentityFascia",
		Vector3(panel_size.x, panel_size.y, 0.050), Vector3.ZERO,
		WARM_LAMINATE, 0.82
	)
	# The dark inset makes the wordmark read as part of the permanent wall trim,
	# rather than pale copy printed directly over the window valance.
	_add_box(
		fixture, "IdentityInset",
		Vector3(panel_size.x - 0.16, panel_size.y - 0.13, 0.024),
		Vector3(0.0, 0.0, 0.030), BARN_ENAMEL, 0.72
	)
	_add_box(
		fixture, "FasciaTopRail",
		Vector3(panel_size.x + 0.10, 0.055, 0.068),
		Vector3(0.0, panel_size.y * 0.5 - 0.028, -0.004),
		AGED_BRASS.darkened(0.18), 0.62, 0.30
	)
	_add_box(
		fixture, "FasciaBottomRail",
		Vector3(panel_size.x + 0.10, 0.040, 0.068),
		Vector3(0.0, -panel_size.y * 0.5 + 0.020, -0.004),
		AGED_BRASS.darkened(0.26), 0.62, 0.30
	)
	_add_egg_seal(
		fixture,
		Vector3(-panel_size.x * 0.5 + panel_size.y * 0.55, 0.045, 0.045),
		panel_size.y * 0.23,
		AGED_BRASS
	)
	var title_label := _add_printed_label(
		fixture,
		fixture_name,
		title,
		Vector3(panel_size.y * 0.20, panel_size.y * 0.105, 0.064),
		Vector2(panel_size.x - panel_size.y * 0.92, panel_size.y * 0.62),
		34,
		0.0090,
		AGED_BRASS.lightened(0.10),
		BARN_ENAMEL,
		&"architectural_letters",
		true,
		&"heading",
	)
	title_label.set_meta(&"smooth_wordmark", true)
	title_label.set_meta(&"embossed_wordmark", true)
	title_label.set_meta(&"dimensional_proxy", true)
	title_label.visible = false
	title_label.modulate.a = 0.0
	title_label.set_meta(&"resting_alpha", 0.0)
	title_label.set_meta(&"maximum_text_size", Vector2(
		panel_size.x - panel_size.y * 0.92,
		panel_size.y * 0.62,
	))
	fixture.set_meta(&"uses_smooth_wordmark", true)
	fixture.set_meta(&"uses_modeled_type", true)
	_add_modeled_wordmark(
		fixture,
		"%sModeledType" % fixture_name,
		title,
		title_label.position,
		title_label.get_meta(&"text_area_size", Vector2(panel_size.x, panel_size.y * 0.62)) as Vector2,
		AGED_BRASS.lightened(0.10),
		BARN_ENAMEL,
		&"architectural_letters",
		&"identity",
		&"heading",
		0.012,
	)
	# The department line is a replaceable riveted strip, not a second line of
	# luminous HUD copy floating on the monumental wordmark.
	_add_box(
		fixture,
		"IdentityDepartmentStrip",
		Vector3(panel_size.x * 0.42, panel_size.y * 0.20, 0.012),
		Vector3(panel_size.y * 0.20, -panel_size.y * 0.255, 0.049),
		BARN_ENAMEL.darkened(0.07),
		0.88,
	)
	var subtitle_label := _add_printed_label(
		fixture,
		"%sSubtitle" % fixture_name,
		subtitle,
		Vector3(panel_size.y * 0.20, -panel_size.y * 0.255, 0.063),
		Vector2(panel_size.x * 0.37, panel_size.y * 0.16),
		20,
		0.0086,
		AGED_BRASS.lightened(0.06),
		BARN_ENAMEL.darkened(0.07),
		&"architectural_letters",
		false,
		&"body"
	)
	subtitle_label.set_meta(&"type_role", &"identity_subtitle")
	subtitle_label.set_meta(&"dimensional_proxy", true)
	subtitle_label.visible = false
	subtitle_label.modulate.a = 0.0
	subtitle_label.set_meta(&"resting_alpha", 0.0)
	fixture.set_meta(&"uses_modeled_subtitle", true)
	_add_modeled_wordmark(
		fixture,
		"%sSubtitleModeledType" % fixture_name,
		subtitle,
		subtitle_label.position,
		subtitle_label.get_meta(
			&"text_area_size", Vector2(panel_size.x * 0.37, panel_size.y * 0.16)
		) as Vector2,
		AGED_BRASS.lightened(0.02),
		BARN_ENAMEL.darkened(0.07),
		&"architectural_letters",
		&"identity",
		&"body",
		0.007,
		false,
	)
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
	## Keep the overview architectural: landmarks, destination headers, and only
	## those rare operational readouts that were explicitly marked as critical.
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
	# Physical mounts remain in the room at every camera distance. Earlier builds
	# made the entire plaque pop in when a hen was selected, which read exactly
	# like world-space UI. Only the printed glyph layers now participate in LOD.
	for fixture_candidate in root.find_children("*", "Node3D", true, false):
		var fixture := fixture_candidate as Node3D
		if (
			fixture == null
			or not fixture.is_in_group(&"environmental_signage")
			or not bool(fixture.get_meta(&"fixture_detail_only", false))
		):
			continue
		fixture.visible = true
		fixture.set_meta(&"detail_should_show", focused)
	for candidate in root.find_children("*", "Label3D", true, false):
		var label := candidate as Label3D
		if label == null or not bool(label.get_meta(&"environmental_copy", false)):
			continue
		if bool(label.get_meta(&"dimensional_proxy", false)):
			label.visible = false
			continue
		var tier := StringName(label.get_meta(&"sign_tier", &"utility"))
		var detail_role := StringName(label.get_meta(&"detail_role", &"body"))
		var fixture := label.get_parent() as Node3D
		var style_family := StringName(
			fixture.get_meta(&"style_family", &"") if fixture != null else &""
		)
		var overview_anchor := fixture != null and (
			bool(fixture.get_meta(&"overview_anchor", false))
			or bool(fixture.get_meta(&"overview_critical_readout", false))
		)
		var near_focus := focused and (
			not has_spatial_focus
			or label.global_position.distance_to(focus_position) <= maxf(0.25, detail_radius)
		)
		var should_show := (
			near_focus
			or (tier == &"primary" and style_family != &"screen" and detail_role != &"body")
			or (overview_anchor and detail_role in [&"heading", &"live"])
		)
		_set_detail_visibility(label, should_show, animate)
	for candidate in root.find_children("*", "MeshInstance3D", true, false):
		var modeled_copy := candidate as MeshInstance3D
		if modeled_copy == null or not bool(modeled_copy.get_meta(&"environmental_dimensional_copy", false)):
			continue
		var fixture := modeled_copy.get_parent() as Node3D
		var detail_role := StringName(modeled_copy.get_meta(&"detail_role", &"heading"))
		var overview_anchor := fixture != null and (
			bool(fixture.get_meta(&"overview_anchor", false))
			or bool(fixture.get_meta(&"overview_critical_readout", false))
		)
		var near_focus := focused and (
			not has_spatial_focus
			or modeled_copy.global_position.distance_to(focus_position) <= maxf(0.25, detail_radius)
		)
		_set_modeled_detail_visibility(
			modeled_copy,
			near_focus or (overview_anchor and detail_role == &"heading"),
			animate,
		)


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
		fade_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade_in.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fade_in.tween_property(label, "modulate:a", resting_alpha, DETAIL_FADE_IN_SECONDS)
		label.set_meta(&"detail_visibility_tween", fade_in)
		return

	if not label.visible:
		label.modulate.a = 0.0
		return
	var fade_out := label.create_tween()
	fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_out.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_out.tween_property(label, "modulate:a", 0.0, DETAIL_FADE_OUT_SECONDS)
	fade_out.tween_callback(func() -> void:
		if is_instance_valid(label) and not bool(label.get_meta(&"detail_should_show", true)):
			label.visible = false
	)
	label.set_meta(&"detail_visibility_tween", fade_out)


static func _set_modeled_detail_visibility(
	modeled_copy: MeshInstance3D,
	should_show: bool,
	animate: bool,
) -> void:
	## Modeled destination letters use GeometryInstance3D transparency so they
	## enter and leave focus with the same restrained dissolve as printed copy.
	## Snapping an entire wordmark on or off made the physical mesh read like UI.
	modeled_copy.set_meta(&"detail_should_show", should_show)
	var active_tween_value: Variant = (
		modeled_copy.get_meta(&"detail_visibility_tween")
		if modeled_copy.has_meta(&"detail_visibility_tween")
		else null
	)
	if active_tween_value is Tween:
		(active_tween_value as Tween).kill()
	if modeled_copy.has_meta(&"detail_visibility_tween"):
		modeled_copy.remove_meta(&"detail_visibility_tween")

	if not animate or not modeled_copy.is_inside_tree():
		modeled_copy.visible = should_show
		modeled_copy.transparency = 0.0 if should_show else 1.0
		return

	if should_show:
		if not modeled_copy.visible:
			modeled_copy.transparency = 1.0
		modeled_copy.visible = true
		var fade_in := modeled_copy.create_tween()
		fade_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade_in.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fade_in.tween_property(
			modeled_copy, "transparency", 0.0, DETAIL_FADE_IN_SECONDS
		)
		modeled_copy.set_meta(&"detail_visibility_tween", fade_in)
		return

	if not modeled_copy.visible:
		modeled_copy.transparency = 1.0
		return
	var fade_out := modeled_copy.create_tween()
	fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_out.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_out.tween_property(
		modeled_copy, "transparency", 1.0, DETAIL_FADE_OUT_SECONDS
	)
	fade_out.tween_callback(func() -> void:
		if (
			is_instance_valid(modeled_copy)
			and not bool(modeled_copy.get_meta(&"detail_should_show", true))
		):
			modeled_copy.visible = false
	)
	modeled_copy.set_meta(&"detail_visibility_tween", fade_out)


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


static func set_copy(label: Label3D, copy: String) -> void:
	## Dynamic readouts should update through one path so their physical fit is
	## recalculated whenever the authored copy changes.
	if label == null or bool(label.get_meta(&"dimensional_proxy", false)):
		return
	label.text = copy
	refit_label(label)


static func set_overview_critical_readout(label: Label3D, enabled: bool = true) -> void:
	## Operational screens recede from the room overview by default. A genuinely
	## critical status display can opt in without changing its node name or copy.
	if label == null:
		return
	var fixture := label.get_parent() as Node3D
	if (
		fixture == null
		or not fixture.is_in_group(&"environmental_signage")
		or StringName(fixture.get_meta(&"style_family", &"")) != &"screen"
	):
		return
	fixture.set_meta(&"overview_critical_readout", enabled)
	fixture.set_meta(
		&"overview_anchor",
		enabled or _is_overview_anchor(
			StringName(fixture.get_meta(&"style_family", &"")),
			StringName(fixture.get_meta(&"copy_band", &"detail")),
		),
	)


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
		if style_family in [
			&"screen", &"paper_notice", &"hosted_header",
			&"room_plaque", &"partition_insert",
		]
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
	if mount_kind in [&"beam", &"destination"]:
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


static func _physical_substrate(style_family: StringName, authored_color: Color) -> Color:
	## Call sites choose a departmental accent; the mounting family chooses the
	## material. Without this normalization every dark accent became the same
	## monitor-like rectangle. Preserve the hue while keeping paper, furniture,
	## enamel, and live glass materially distinct.
	match style_family:
		&"paper_notice":
			return WARM_FORM_PAPER.lerp(authored_color, 0.16)
		&"adhesive_label":
			return WARM_FORM_PAPER.lightened(0.045).lerp(authored_color, 0.12)
		&"partition_insert":
			return CUBICLE_INSERT.lerp(authored_color, 0.18)
		&"desk_plaque":
			return WARM_LAMINATE.lerp(authored_color, 0.24)
		&"enamel_plate":
			return MUTED_MACHINE_ENAMEL.lerp(authored_color, 0.54)
		&"room_plaque":
			return BARN_ENAMEL.lerp(authored_color, 0.48)
		&"chart_header", &"portrait_masthead":
			return WARM_FORM_PAPER.lerp(authored_color, 0.30)
		&"hosted_header":
			return MUTED_MACHINE_ENAMEL.lerp(authored_color, 0.42)
		&"suspended_notice":
			return WARM_FORM_PAPER.darkened(0.035).lerp(authored_color, 0.20)
		_:
			# Screens, painted stencils, and host-attached destination letters
			# must inherit their actual authored surface color exactly.
			return authored_color


static func _copy_band(
	tier: StringName,
	mount_kind: StringName,
	style_family: StringName,
) -> StringName:
	if style_family == &"architectural_letters":
		return &"identity"
	if mount_kind == &"destination":
		return &"destination"
	if tier == &"primary":
		return &"identity"
	if style_family == &"screen":
		return &"live"
	return &"detail"


static func _is_overview_anchor(style_family: StringName, copy_band: StringName) -> bool:
	# The monitor remains a modeled prop at overview, but its operational glyphs
	# are detail. Only identity and destination copy function as room landmarks.
	if style_family == &"screen":
		return false
	return copy_band in [&"identity", &"destination"]


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
			_build_hosted_header(fixture, panel_size, panel_color, ink_color)
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
	# Compact institutional enamel in a shallow walnut carrier. The projecting
	# end caps make the destination sign read as wall hardware, not a wide HUD
	# banner, while the face stays quiet enough for the office palette.
	_add_box(
		fixture, "RoomPlaqueCarrier", Vector3(size.x + 0.10, size.y + 0.06, 0.030),
		Vector3(0.0, 0.0, -0.005), WARM_LAMINATE.darkened(0.08), 0.76
	)
	_add_box(
		fixture, "Backplate", Vector3(size.x, size.y, 0.018),
		Vector3(0.0, 0.0, 0.011), color.darkened(0.055), 0.68
	)
	for cap_x in [-1.0, 1.0]:
		_add_box(
			fixture,
			"RoomPlaqueEndCapLeft" if cap_x < 0.0 else "RoomPlaqueEndCapRight",
			Vector3(0.045, size.y + 0.025, 0.024),
			Vector3(cap_x * (size.x * 0.5 + 0.025), 0.0, 0.012),
			AGED_BRASS.darkened(0.18), 0.50, 0.42
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
	# One tack and one imperfect strip of tape feel handled; four perfectly paired
	# fasteners made every notice look like the same UI-card component.
	var tack_side := -1.0 if _deterministic_signed(String(fixture.name), 4) < 0.0 else 1.0
	_add_fastener(
		fixture,
		Vector3(tack_side * (size.x * 0.5 - 0.048), size.y * 0.5 - 0.048, 0.0065),
		Color("b29661")
	)
	var tape := _add_box(
		fixture,
		"PaperTape",
		Vector3(size.x * 0.18, 0.040, 0.0014),
		Vector3(-tack_side * size.x * 0.26, size.y * 0.5 + 0.004, 0.0048),
		Color("c8b77d"),
		0.96
	)
	tape.rotation_degrees.z = _deterministic_signed(String(fixture.name), 5) * 4.0
	var dog_ear := _add_box(
		fixture,
		"PaperDogEar",
		Vector3(minf(size.x, size.y) * 0.10, minf(size.x, size.y) * 0.10, 0.0012),
		Vector3(size.x * 0.5 - 0.038, -size.y * 0.5 + 0.038, 0.0040),
		paper_color.darkened(0.07),
		0.98
	)
	dog_ear.rotation_degrees.z = 45.0


static func _build_enamel_plate(fixture: Node3D, size: Vector2, color: Color) -> void:
	# A small, workmanlike asset plate. Layered rolled edges catch the office
	# lighting while the desaturated enamel face remains visibly different from
	# both a black live screen and a pale paper form.
	_add_box(
		fixture, "EquipmentPlateLip",
		Vector3(size.x + 0.036, size.y + 0.036, 0.016),
		Vector3(0.0, 0.0, -0.003), color.darkened(0.19), 0.50, 0.24
	)
	_add_box(
		fixture, "Backplate", Vector3(size.x, size.y, 0.010),
		Vector3(0.0, 0.0, 0.007), color, 0.78
	)
	for edge_y in [-1.0, 1.0]:
		_add_box(
			fixture,
			"EquipmentPlateRollTop" if edge_y > 0.0 else "EquipmentPlateRollBottom",
			Vector3(size.x * 0.76, 0.010, 0.005),
			Vector3(0.0, edge_y * (size.y * 0.5 - 0.013), 0.013),
			color.lightened(0.10) if edge_y > 0.0 else color.darkened(0.12),
			0.62,
			0.18,
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
	# Cheap interchangeable office furniture is the right language for a cubicle,
	# but a pale blank slip disappears into the pale partition at overview. Use a
	# small warm paper-laminate insert in dull brass memo channels. The pale face
	# is intentionally unlike the nearby monitor glass; close-focus lettering can
	# still fade independently without leaving an unexplained UI rectangle behind.
	_add_box(
		fixture, "PartitionInsertShadow",
		Vector3(size.x + 0.010, size.y + 0.010, 0.0015),
		Vector3(0.003, -0.003, -0.0008), Color("464943"), 0.98
	)
	_add_box(
		fixture, "Backplate", Vector3(size.x, size.y, 0.004),
		Vector3(0.0, 0.0, 0.004), color, 0.94
	)
	var rail_color := AGED_BRASS.darkened(0.28)
	_add_box(
		fixture, "PartitionRailTop", Vector3(size.x + 0.026, 0.012, 0.010),
		Vector3(0.0, size.y * 0.5 + 0.003, 0.004), rail_color, 0.72
	)
	_add_box(
		fixture, "PartitionRailBottom", Vector3(size.x + 0.026, 0.012, 0.010),
		Vector3(0.0, -size.y * 0.5 - 0.003, 0.004), rail_color, 0.72
	)
	_add_box(
		fixture, "PartitionIdentityTab", Vector3(0.038, size.y * 0.54, 0.004),
		Vector3(-size.x * 0.5 + 0.034, 0.0, 0.008), Color("9a684f"), 0.76, 0.08
	)
	_add_egg_seal(
		fixture,
		Vector3(size.x * 0.5 - 0.040, 0.0, 0.010),
		minf(size.y * 0.105, 0.026),
		AGED_BRASS.darkened(0.04),
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
	_color: Color,
	ink: Color
) -> void:
	# Direct paint belongs to the underlying machine or wooden prop. Do not create
	# a panel-sized bed here: even a color-matched rectangle catches a different
	# highlight and reads as another card at the management-camera angle.
	_add_box(
		fixture, "StencilRegistrationTick", Vector3(size.x * 0.11, 0.004, 0.0008),
		Vector3(-size.x * 0.39, -size.y * 0.5 + 0.022, 0.0010),
		ink.darkened(0.22), 0.92
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


static func _build_hosted_header(
	fixture: Node3D,
	size: Vector2,
	color: Color,
	ink: Color,
) -> void:
	# The host object already supplies the panel/frame. Add only a silk-screened
	# equipment band, rule, and registration tab so the lettering belongs to it.
	_add_box(
		fixture, "HostHeaderBand", Vector3(size.x, size.y, 0.006),
		Vector3.ZERO, color, 0.82
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
	# Host-attached headings use the beam itself as their substrate. A second
	# panel-sized bed catches a separate highlight and reads as a pasted UI card.
	# Only legacy/sibling-authored headings receive a shallow physical carrier.
	if not bool(fixture.get_meta(&"host_attached", false)):
		_add_box(
			fixture, "BeamLetterCarrier", Vector3(size.x + 0.08, size.y + 0.06, 0.026),
			Vector3(0.0, 0.0, -0.006), color.darkened(0.08), 0.82
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


static func _add_modeled_wordmark(
	fixture: Node3D,
	node_name: String,
	copy: String,
	position: Vector3,
	maximum_size: Vector2,
	ink_color: Color,
	substrate_color: Color,
	style_family: StringName,
	copy_band: StringName,
	detail_role: StringName,
	depth: float,
	emphasized: bool = true,
) -> MeshInstance3D:
	## TextMesh produces actual triangulated, shallowly extruded office lettering.
	## It inherits the sign/beam transform, responds to the room lights, receives
	## occlusion, and casts a tiny contact shadow—properties a Label3D quad cannot
	## provide even when it is correctly mounted.
	var font := _font_for(style_family, emphasized)
	var measured := font.get_multiline_string_size(
		copy,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		HIGH_RES_FONT_SIZE,
	)
	measured.x = maxf(1.0, measured.x)
	measured.y = maxf(1.0, measured.y)
	var modeled_pixel_size := minf(
		maximum_size.x * 0.90 / measured.x,
		maximum_size.y * 0.80 / measured.y,
	)

	var text_mesh := TextMesh.new()
	text_mesh.text = copy
	text_mesh.font = font
	text_mesh.font_size = HIGH_RES_FONT_SIZE
	text_mesh.pixel_size = maxf(MIN_FITTED_PIXEL_SIZE, modeled_pixel_size)
	text_mesh.depth = maxf(0.006, depth)
	text_mesh.curve_step = 0.25
	# TextMesh treats an unbounded negative width as a wrapping sentinel and can
	# spend unbounded time shaping long all-caps lines in Web/Compatibility.
	# A measured finite line box keeps generation deterministic.
	text_mesh.width = measured.x + 4.0
	text_mesh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_mesh.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var modeled := MeshInstance3D.new()
	modeled.name = node_name
	modeled.mesh = text_mesh
	modeled.position = position
	# TextMesh and the authored fixture share the same outward-facing local plane.
	# Keep the installed glyph transform neutral: counter-rotating a wordmark shows
	# its back face and mirrors the copy at oblique management-camera angles.
	modeled.rotation = Vector3.ZERO
	var modeled_metallic := 0.10 if copy_band == &"destination" else 0.32
	if not emphasized:
		modeled_metallic *= 0.55
	modeled.material_override = _material(
		_surface_ink(ink_color, substrate_color, style_family, emphasized, copy_band),
		0.74,
		modeled_metallic,
	)
	modeled.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	modeled.set_meta(&"environmental_copy", true)
	modeled.set_meta(&"environmental_dimensional_copy", true)
	modeled.set_meta(&"modeled_text", copy)
	modeled.set_meta(&"copy_band", copy_band)
	modeled.set_meta(&"detail_role", detail_role)
	modeled.set_meta(&"style_family", style_family)
	modeled.set_meta(&"readable_face_outward", true)
	modeled.set_meta(&"installed_lettering", true)
	modeled.set_meta(&"emphasized", emphasized)
	modeled.set_meta(&"maximum_text_size", maximum_size)
	modeled.set_meta(&"modeled_pixel_size", text_mesh.pixel_size)
	fixture.add_child(modeled)
	return modeled


static func _add_raised_block_letters(
	fixture: Node3D,
	node_name: String,
	copy: String,
	position: Vector3,
	maximum_size: Vector2,
	color: Color,
	style_family: StringName,
	depth: float,
) -> Node3D:
	## Major office landmarks are shallow modeled letters. A small 5x7 geometric
	## alphabet is deliberate: it shares the room's chunky low-poly construction,
	## casts real shadows, and avoids platform-specific font triangulation failures.
	var normalized_copy := copy.to_upper()
	var column_count := 0
	for character_index in normalized_copy.length():
		column_count += 3 if normalized_copy[character_index] == " " else 5
		if character_index < normalized_copy.length() - 1:
			column_count += 1
	var cell_size := minf(
		maximum_size.x / maxf(1.0, float(column_count)),
		maximum_size.y / 7.0,
	) * 0.94
	var text_width := float(column_count) * cell_size
	var letters := Node3D.new()
	letters.name = node_name
	letters.position = position
	letters.set_meta(&"environmental_copy", true)
	letters.set_meta(&"dimensional_letters", true)
	letters.set_meta(&"style_family", style_family)
	letters.set_meta(&"maximum_text_size", maximum_size)
	fixture.add_child(letters)

	var cursor_column := 0
	var stroke_index := 0
	for character_index in normalized_copy.length():
		var character := normalized_copy[character_index]
		if character == " ":
			cursor_column += 4
			continue
		var rows := _block_glyph_rows(character)
		for row_index in rows.size():
			var row := rows[row_index]
			var column_index := 0
			while column_index < row.length():
				if row[column_index] != "#":
					column_index += 1
					continue
				var run_start := column_index
				while column_index < row.length() and row[column_index] == "#":
					column_index += 1
				var run_length := column_index - run_start
				var stroke_width := float(run_length) * cell_size * 0.96
				var stroke := _add_box(
					letters,
					"%sStroke_%03d" % [node_name, stroke_index],
					Vector3(stroke_width, cell_size * 0.96, maxf(0.004, depth)),
					Vector3(
						-text_width * 0.5
						+ (float(cursor_column + run_start) + float(run_length) * 0.5) * cell_size,
						maximum_size.y * 0.5 - (float(row_index) + 0.5) * cell_size,
						0.0,
					),
					color,
					0.72,
					0.04,
				)
				stroke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				stroke_index += 1
		cursor_column += 6
	return letters


static func _block_glyph_rows(character: String) -> PackedStringArray:
	match character:
		"A": return PackedStringArray([".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"])
		"B": return PackedStringArray(["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."])
		"C": return PackedStringArray([".####", "#....", "#....", "#....", "#....", "#....", ".####"])
		"D": return PackedStringArray(["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."])
		"E": return PackedStringArray(["#####", "#....", "#....", "####.", "#....", "#....", "#####"])
		"F": return PackedStringArray(["#####", "#....", "#....", "####.", "#....", "#....", "#...."])
		"G": return PackedStringArray([".####", "#....", "#....", "#.###", "#...#", "#...#", ".###."])
		"H": return PackedStringArray(["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"])
		"I": return PackedStringArray(["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"])
		"J": return PackedStringArray(["..###", "...#.", "...#.", "...#.", "...#.", "#..#.", ".##.."])
		"K": return PackedStringArray(["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"])
		"L": return PackedStringArray(["#....", "#....", "#....", "#....", "#....", "#....", "#####"])
		"M": return PackedStringArray(["#...#", "##.##", "#.#.#", "#...#", "#...#", "#...#", "#...#"])
		"N": return PackedStringArray(["#...#", "##..#", "##..#", "#.#.#", "#..##", "#..##", "#...#"])
		"O": return PackedStringArray([".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."])
		"P": return PackedStringArray(["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."])
		"Q": return PackedStringArray([".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"])
		"R": return PackedStringArray(["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"])
		"S": return PackedStringArray([".####", "#....", "#....", ".###.", "....#", "....#", "####."])
		"T": return PackedStringArray(["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."])
		"U": return PackedStringArray(["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."])
		"V": return PackedStringArray(["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."])
		"W": return PackedStringArray(["#...#", "#...#", "#...#", "#...#", "#.#.#", "#.#.#", ".#.#."])
		"X": return PackedStringArray(["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"])
		"Y": return PackedStringArray(["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."])
		"Z": return PackedStringArray(["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"])
		_: return PackedStringArray(["#####", "....#", "...#.", "..#..", ".#...", ".....", ".#..."])


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
	var copy_band := StringName(fixture.get_meta(&"copy_band", &"detail"))
	var minimum_height_fill := 0.24
	if style_family == &"screen":
		minimum_height_fill = 0.52
	elif style_family == &"architectural_letters":
		minimum_height_fill = 0.46 if emphasized else 0.24
	elif style_family in [&"paper_notice", &"adhesive_label"]:
		minimum_height_fill = 0.28 if emphasized else 0.17
	elif style_family == &"partition_insert":
		minimum_height_fill = 0.38 if emphasized else 0.20
	elif style_family == &"surface_stencil":
		minimum_height_fill = 0.31 if emphasized else 0.20
	elif style_family == &"enamel_plate":
		minimum_height_fill = 0.35 if emphasized else 0.24
	elif style_family == &"room_plaque":
		minimum_height_fill = 0.40 if emphasized else 0.23
	elif style_family == &"beam_letters":
		minimum_height_fill = 0.48 if copy_band == &"destination" else 0.36
	elif style_family in [&"hosted_header", &"chart_header", &"portrait_masthead"]:
		minimum_height_fill = 0.34 if emphasized else 0.22
	elif style_family == &"desk_plaque":
		minimum_height_fill = 0.36 if emphasized else 0.21
	elif emphasized:
		minimum_height_fill = 0.32
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
	label.modulate = _surface_ink(
		ink_color, substrate_color, style_family, emphasized, copy_band
	)
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
			&"hosted_header", &"room_plaque", &"partition_insert",
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
	label.set_meta(
		&"substrate_blend",
		_substrate_blend(style_family, emphasized, copy_band),
	)
	label.set_meta(&"fitted_pixel_size", label.pixel_size)
	label.set_meta(&"text_area_size", text_area)
	label.set_meta(&"screen_copy", style_family == &"screen")
	label.set_meta(&"emphasized", emphasized)
	label.set_meta(
		&"type_role",
		&"destination_identity"
		if copy_band == &"destination" and detail_role == &"heading"
		else _type_role(style_family, emphasized),
	)
	label.set_meta(&"copy_band", copy_band)
	label.set_meta(&"environmental_copy", true)
	label.set_meta(&"surface_printed", true)
	label.set_meta(&"substrate_color", substrate_color)
	label.set_meta(
		&"ink_luminance_separation",
		absf(label.modulate.get_luminance() - substrate_color.get_luminance()),
	)
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
	shadow.position = source.position + Vector3(0.0014, -0.0014, -0.0004)
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
	emphasized: bool,
	copy_band: StringName = &"detail",
) -> Color:
	# Printed copy borrows a little of the material beneath it. This removes the
	# pure, luminous UI contrast while keeping close-up text readable.
	var pigment := _medium_pigment(ink_color, substrate_color, style_family)
	var substrate_blend := _substrate_blend(
		style_family, emphasized, copy_band
	)
	var result := pigment.lerp(substrate_color, substrate_blend)
	# Printed pigment is faded by borrowing the substrate's RGB, not by making
	# the glyph translucent. Semi-transparent shaded text turned into gray noise
	# at oblique management-camera angles and looked composited over the room.
	result.a = 1.0 if emphasized else 0.97
	if style_family == &"screen":
		result.a = 1.0
	return result


static func _medium_pigment(
	authored_ink: Color,
	substrate_color: Color,
	style_family: StringName,
) -> Color:
	## Departmental colors tint the ink, but the physical medium controls its
	## value. If a pale call-site ink lands on the new pale cubicle/paper face (or
	## dark ink lands on dark enamel), select the corresponding house pigment.
	## This is an environmental contrast correction, not a luminous HUD outline.
	if style_family == &"screen":
		return authored_ink
	var substrate_luminance := substrate_color.get_luminance()
	var pigment := authored_ink
	if absf(authored_ink.get_luminance() - substrate_luminance) < 0.30:
		pigment = CHARCOAL_INK if substrate_luminance >= 0.48 else BONE_LETTERS
	elif authored_ink.get_luminance() > substrate_luminance:
		pigment = authored_ink.lerp(BONE_LETTERS, 0.18)
	else:
		pigment = authored_ink.lerp(CHARCOAL_INK, 0.12)
	if style_family in [&"paper_notice", &"adhesive_label", &"portrait_masthead"]:
		# Warm carbon/typewriter ribbon, never pure black or sterile white.
		pigment = pigment.lerp(
			CHARCOAL_INK if substrate_luminance >= 0.48 else BONE_LETTERS,
			0.14,
		)
	return pigment


static func _substrate_blend(
	style_family: StringName,
	emphasized: bool,
	copy_band: StringName = &"detail",
) -> float:
	var substrate_blend := 0.22 if emphasized else 0.32
	if style_family == &"screen":
		substrate_blend = 0.18
	elif style_family == &"architectural_letters":
		substrate_blend = 0.10 if emphasized else 0.28
	elif style_family == &"paper_notice":
		substrate_blend = 0.18 if emphasized else 0.30
	elif style_family == &"adhesive_label":
		substrate_blend = 0.24 if emphasized else 0.36
	elif style_family == &"partition_insert":
		substrate_blend = 0.20 if emphasized else 0.34
	elif style_family == &"surface_stencil":
		substrate_blend = 0.34 if emphasized else 0.46
	elif style_family == &"desk_plaque":
		substrate_blend = 0.22 if emphasized else 0.34
	elif style_family == &"chart_header":
		substrate_blend = 0.24
	elif style_family == &"portrait_masthead":
		substrate_blend = 0.22
	elif style_family == &"beam_letters":
		substrate_blend = 0.18 if copy_band == &"destination" else 0.42
	elif style_family == &"enamel_plate":
		substrate_blend = 0.24 if emphasized else 0.38
	elif style_family == &"hosted_header":
		substrate_blend = 0.28
	elif style_family == &"room_plaque":
		substrate_blend = 0.22 if emphasized else 0.36
	if copy_band == &"identity":
		substrate_blend = minf(substrate_blend, 0.12 if emphasized else 0.26)
	elif copy_band == &"destination":
		substrate_blend = minf(substrate_blend, 0.20 if emphasized else 0.34)
	return substrate_blend


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
	# Environmental type is viewed at an oblique orthographic angle. A restrained
	# optical embolden keeps real ink from collapsing into hairlines without using
	# the hard outline/shadow treatment associated with HUD text.
	var weight := 0.028
	if style_family == &"screen":
		width_scale = 0.96
		weight = 0.018
	elif style_family == &"architectural_letters":
		weight = 0.072 if emphasized else 0.046
	elif style_family == &"beam_letters":
		weight = 0.064 if emphasized else 0.040
	elif style_family == &"room_plaque":
		weight = 0.078 if emphasized else 0.046
	elif style_family == &"paper_notice":
		width_scale = 0.98
		weight = 0.076 if emphasized else 0.034
	elif style_family in [&"adhesive_label", &"partition_insert"]:
		width_scale = 0.96
		weight = 0.072 if emphasized else 0.038
	elif style_family == &"surface_stencil":
		width_scale = 0.92
		weight = 0.064 if emphasized else 0.040
	elif style_family in [&"enamel_plate", &"desk_plaque", &"hosted_header"]:
		weight = 0.070 if emphasized else 0.042
	elif emphasized:
		weight = 0.070
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
		return &"silkscreened_beam_identity"
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
