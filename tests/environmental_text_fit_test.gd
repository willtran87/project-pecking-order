extends SceneTree

## Focused integration contract for environmental copy. The broader signage test
## verifies authored props and named host relationships; this test deliberately
## walks every printed layer so a secondary line or letterpress shadow cannot
## silently regress into camera-facing, luminous, overflowing UI text.

const WIDTH_BUDGET := 0.87
const HEIGHT_BUDGET := 0.85
const FIT_EPSILON_METERS := 0.002


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var environmental_labels: Array[Label3D] = []
	var fitted_labels := 0
	var letterpress_layers := 0
	for candidate in office.find_children("*", "Label3D", true, false):
		var label := candidate as Label3D
		var fixture := _sign_fixture_ancestor(label, office)
		_check(fixture != null, "%s must belong to a physical signage fixture" % label.name, failures)
		if fixture == null:
			continue
		environmental_labels.append(label)

		# Perspective and occlusion are environmental-fit requirements for every
		# printed layer, not just the first heading discovered on a fixture.
		_check(label.billboard == BaseMaterial3D.BILLBOARD_DISABLED, "%s must inherit its mount's perspective" % label.name, failures)
		_check(not label.no_depth_test, "%s must be occluded by office geometry" % label.name, failures)
		_check(not label.fixed_size, "%s must retain physical world scale" % label.name, failures)
		_check(not label.double_sided, "%s must print on one physical face" % label.name, failures)
		_check(label.rotation.is_equal_approx(Vector3.ZERO), "%s must not counter-rotate away from its mount" % label.name, failures)
		_check(label.font != null, "%s must use an authored font" % label.name, failures)
		_check(label.font_size >= EnvironmentalSignage.HIGH_RES_FONT_SIZE, "%s must use the high-resolution environmental glyph atlas" % label.name, failures)
		_check(label.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC, "%s must use mipmapped anisotropic type filtering" % label.name, failures)
		_check(label.outline_size <= 1, "%s must not regain a HUD-style outline" % label.name, failures)
		if bool(label.get_meta(&"dimensional_proxy", false)):
			_check(not label.visible and is_zero_approx(float(label.get_meta(&"resting_alpha", 1.0))), "%s semantic proxy must stay behind its modeled lettering" % label.name, failures)
			continue

		var type_role := StringName(label.get_meta(&"type_role", &""))
		if type_role == &"letterpress_shadow":
			letterpress_layers += 1
			_check(label.shaded, "%s letterpress depth must respond to room lighting" % label.name, failures)
			continue

		_check(label.has_meta(&"text_area_size"), "%s must publish its printable area" % label.name, failures)
		_check(label.has_meta(&"requested_pixel_size"), "%s must publish its authored type scale" % label.name, failures)
		_check(label.has_meta(&"fitted_pixel_size"), "%s must publish its fitted type scale" % label.name, failures)
		_check(label.has_meta(&"substrate_color"), "%s ink must be blended for a physical substrate" % label.name, failures)
		if not label.has_meta(&"text_area_size") or label.font == null:
			continue
		fitted_labels += 1

		var area := label.get_meta(&"text_area_size", Vector2.ZERO) as Vector2
		var requested := float(label.get_meta(&"requested_pixel_size", 0.0))
		var fitted := float(label.get_meta(&"fitted_pixel_size", -1.0))
		var measured := label.font.get_multiline_string_size(
			label.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			label.font_size
		)
		var physical_text_size := measured * label.pixel_size
		_check(area.x > 0.0 and area.y > 0.0, "%s must have a positive physical print area" % label.name, failures)
		_check(label.pixel_size > 0.0 and label.pixel_size <= requested + 0.000001, "%s may shrink to fit but must not inflate beyond its authored scale" % label.name, failures)
		_check(is_equal_approx(label.pixel_size, fitted), "%s fitted scale metadata must match the rendered scale" % label.name, failures)
		_check(physical_text_size.x <= area.x * WIDTH_BUDGET + FIT_EPSILON_METERS, "%s text width %.3f m must fit its %.3f m print field" % [label.name, physical_text_size.x, area.x], failures)
		_check(physical_text_size.y <= area.y * HEIGHT_BUDGET + FIT_EPSILON_METERS, "%s text height %.3f m must fit its %.3f m print field" % [label.name, physical_text_size.y, area.y], failures)

		var panel_size := fixture.get_meta(&"panel_size", Vector2.ZERO) as Vector2
		_check(panel_size.x > 0.0 and panel_size.y > 0.0, "%s fixture must publish a physical panel footprint" % fixture.name, failures)
		_check(area.x <= panel_size.x + FIT_EPSILON_METERS and area.y <= panel_size.y + FIT_EPSILON_METERS, "%s print field must remain inside %s's panel footprint" % [label.name, fixture.name], failures)

		var style_family := StringName(fixture.get_meta(&"style_family", &""))
		_check(_font_matches_medium(label, style_family), "%s font must match the %s physical medium" % [label.name, style_family], failures)
		_check(label.shaded == (style_family != &"screen"), "%s lighting response must match the %s medium" % [label.name, style_family], failures)
		var resting_alpha := float(label.get_meta(&"resting_alpha", label.modulate.a))
		_check(resting_alpha >= 0.95, "%s must read as opaque pigment or display light, not translucent overlay text" % label.name, failures)

	_check(environmental_labels.size() >= 30, "fixture should exercise the complete office copy set", failures)
	_check(fitted_labels >= 23, "every authored fixture should contribute fitted source copy", failures)
	_check(letterpress_layers >= 1, "small laminate plaques should retain dimensional letterpress depth", failures)

	var dynamic_screen := office.find_child("ManagementYieldBoard", true, false) as Label3D
	_check(dynamic_screen != null, "copy helper coverage requires the mounted yield screen", failures)
	if dynamic_screen != null:
		var original_name := dynamic_screen.name
		var replacement_copy := "YIELD  999 / 999\nN 12   P 34   A 56\n11:59 PM  ·  AUDIT"
		EnvironmentalSignage.set_copy(dynamic_screen, replacement_copy)
		_check(dynamic_screen.name == original_name, "set_copy should preserve the authored node identity", failures)
		_check(dynamic_screen.text == replacement_copy, "set_copy should apply dynamic screen copy verbatim", failures)
		_check(is_equal_approx(dynamic_screen.pixel_size, float(dynamic_screen.get_meta(&"fitted_pixel_size", -1.0))), "set_copy should immediately publish the recalculated fitted scale", failures)
		var dynamic_area := dynamic_screen.get_meta(&"text_area_size", Vector2.ZERO) as Vector2
		var dynamic_size := dynamic_screen.font.get_multiline_string_size(
			dynamic_screen.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			dynamic_screen.font_size,
		) * dynamic_screen.pixel_size
		_check(dynamic_size.x <= dynamic_area.x * WIDTH_BUDGET + FIT_EPSILON_METERS, "set_copy should keep updated screen width inside its physical glass", failures)
		_check(dynamic_size.y <= dynamic_area.y * HEIGHT_BUDGET + FIT_EPSILON_METERS, "set_copy should keep updated screen height inside its physical glass", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("ENVIRONMENTAL_TEXT_FIT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("ENVIRONMENTAL_TEXT_FIT_TEST_PASSED labels=%d fitted=%d letterpress=%d" % [environmental_labels.size(), fitted_labels, letterpress_layers])
	quit(0)


func _sign_fixture_ancestor(label: Label3D, office: Node) -> Node3D:
	var cursor := label.get_parent()
	while cursor != null and cursor != office:
		if cursor is Node3D and cursor.is_in_group(&"environmental_signage"):
			return cursor as Node3D
		cursor = cursor.get_parent()
	return null


func _font_matches_medium(label: Label3D, style_family: StringName) -> bool:
	if not (label.font is FontVariation):
		return false
	var variation := label.font as FontVariation
	if variation.base_font == null:
		return false
	var source := String(variation.base_font.get_meta(&"authored_source_path", ""))
	if style_family == &"screen":
		return "IBMPlexMono-" in source
	if style_family in [&"paper_notice", &"adhesive_label", &"portrait_masthead"]:
		return "CourierPrime-" in source
	return "BarlowCondensed-" in source


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
