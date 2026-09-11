extends SceneTree

## Renderer-independent layout stress for the player-facing Settings surface.
##
## The shipped game is English-only, so this does not claim localization
## support. It exercises the production requirement that authored interfaces
## survive longer labels and maximum text scale without losing controls or
## introducing horizontal scrolling.

const SettingsUIScript := preload("res://features/office/settings_ui.gd")
const PlayerPreferencesStoreScript := preload(
	"res://core/settings/player_preferences_store.gd"
)
const ManagementUIThemeScript := preload(
	"res://features/office/management_ui_theme.gd"
)

const VIEWPORTS: Array[Vector2] = [
	Vector2(1280.0, 720.0),
	Vector2(844.0, 390.0),
	Vector2(390.0, 844.0),
]
const CATEGORY_NAMES: Array[String] = [
	"Audio",
	"Comfort",
	"Controls",
	"Career",
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var harness := Control.new()
	harness.size = VIEWPORTS[0]
	harness.theme = ManagementUIThemeScript.create_theme(false, 1.5)
	root.add_child(harness)

	var settings := SettingsUIScript.new() as PeckingOrderSettingsUI
	harness.add_child(settings)
	await process_frame

	var preferences := PlayerPreferencesStoreScript.defaults()
	preferences["ui_scale"] = 1.5
	settings.show_settings(preferences, {}, true)
	_apply_explicit_scale(settings, 1.5)
	_expand_interface_copy(settings)
	await process_frame
	await process_frame

	var panel := settings.find_child("SettingsPanel", true, false) as PanelContainer
	var scroll := settings.find_child("SettingsScroll", true, false) as ScrollContainer
	var category_nav := settings.find_child(
		"SettingsCategoryNavigation",
		true,
		false,
	) as HFlowContainer
	_check(
		panel != null and scroll != null and category_nav != null,
		"stress fixture should expose its bounded panel, category flow, and scroll region",
		failures,
	)

	for viewport_size: Vector2 in VIEWPORTS:
		harness.size = viewport_size
		await process_frame
		await process_frame
		var panel_rect := panel.get_global_rect()
		_check(
			_rect_within(panel_rect, Rect2(Vector2.ZERO, viewport_size)),
			"150-percent expanded Settings panel should fit %dx%d (got %s; largest minima: %s)"
			% [
				int(viewport_size.x),
				int(viewport_size.y),
				panel_rect,
				_largest_minimum_controls(settings),
			],
			failures,
		)
		_check(
			category_nav.get_combined_minimum_size().x <= panel_rect.size.x + 0.5,
			"expanded category navigation should wrap rather than widen the panel at %dx%d"
			% [int(viewport_size.x), int(viewport_size.y)],
			failures,
		)
		for category_name: String in CATEGORY_NAMES:
			var button := settings.find_child(
				"SettingsCategory_%s" % category_name,
				true,
				false,
			) as Button
			if button == null:
				_check(false, "%s category button should exist" % category_name, failures)
				continue
			button.pressed.emit()
			await process_frame
			await process_frame
			var active_page := settings.find_child(
				"SettingsPage_%s" % category_name,
				true,
				false,
			) as Control
			_check(
				active_page != null and active_page.visible,
				"%s should remain reachable under expanded copy" % category_name,
				failures,
			)
			if active_page == null:
				continue
			_check(
				active_page.get_combined_minimum_size().x <= scroll.size.x + 0.5,
				"%s should not require horizontal scrolling at %dx%d"
				% [category_name, int(viewport_size.x), int(viewport_size.y)],
				failures,
			)
			_check(
				not _has_visible_horizontal_overflow(active_page, scroll.get_global_rect()),
				"%s controls should remain horizontally contained at %dx%d"
				% [category_name, int(viewport_size.x), int(viewport_size.y)],
				failures,
			)

	settings.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("UI_TEXT_EXPANSION_RESILIENCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print(
		"UI_TEXT_EXPANSION_RESILIENCE_TEST_PASSED "
		+ "scale=150-percent copy=vowel-expanded categories=4 "
		+ "viewports=1280x720+844x390+390x844 horizontal-scroll=none"
	)
	quit(0)


func _apply_explicit_scale(root_control: Control, scale: float) -> void:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
		if control == null or not control.has_theme_font_size_override("font_size"):
			continue
		var base_size := control.get_theme_font_size("font_size")
		control.add_theme_font_size_override(
			"font_size",
			maxi(10, roundi(float(base_size) * scale)),
		)


func _expand_interface_copy(root_control: Control) -> void:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		if node_value is Label:
			var label := node_value as Label
			label.text = _expanded(label.text)
		elif node_value is OptionButton:
			var option := node_value as OptionButton
			for item_index: int in option.item_count:
				option.set_item_text(
					item_index,
					_expanded(option.get_item_text(item_index)),
				)
		elif node_value is Button:
			var button := node_value as Button
			button.text = _expanded(button.text)


func _expanded(source: String) -> String:
	var result := ""
	for character: String in source:
		result += character
		if character.to_lower() in ["a", "e", "i", "o", "u"]:
			result += character.to_lower()
	return result


func _has_visible_horizontal_overflow(
	root_control: Control,
	bounds: Rect2,
) -> bool:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
		if (
			control == null
			or not control.is_visible_in_tree()
			or control is VScrollBar
			or control is HScrollBar
		):
			continue
		var rect := control.get_global_rect()
		if rect.size.x <= 0.0:
			continue
		if rect.position.x < bounds.position.x - 1.0:
			return true
		if rect.end.x > bounds.end.x + 1.0:
			return true
	return false


func _rect_within(rect: Rect2, bounds: Rect2) -> bool:
	return (
		rect.position.x >= bounds.position.x - 0.5
		and rect.position.y >= bounds.position.y - 0.5
		and rect.end.x <= bounds.end.x + 0.5
		and rect.end.y <= bounds.end.y + 0.5
	)


func _largest_minimum_controls(root_control: Control) -> String:
	var rows: Array[Dictionary] = []
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
		if control == null:
			continue
		rows.append({
			"name": control.name,
			"minimum": control.get_combined_minimum_size(),
			"visible": control.is_visible_in_tree(),
		})
	rows.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			return (first.get("minimum") as Vector2).y > (
				second.get("minimum") as Vector2
			).y
	)
	var summaries: Array[String] = []
	for index: int in mini(8, rows.size()):
		var row := rows[index]
		summaries.append("%s=%s/%s" % [
			row.get("name"),
			row.get("minimum"),
			"visible" if bool(row.get("visible")) else "hidden",
		])
	return ", ".join(summaries)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
