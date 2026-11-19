class_name HenSocialUI
extends PanelContainer

const Voices := preload("res://features/chickens/hen_personality.gd")
var _heading: Label
var _opening: Label
var _reply: Label
var _copy_key := ""
var _tail := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 6
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.094, 0.173, 0.208, 0.96)
	style.border_color = Color("a5c6b8")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 11
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	_heading = Label.new()
	_heading.add_theme_font_size_override("font_size", 12)
	_heading.add_theme_color_override("font_color", Color("a5c6b8"))
	box.add_child(_heading)
	_opening = Label.new()
	_reply = Label.new()
	for label in [_opening, _reply]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 15)
		box.add_child(label)
	hide()

func present(beat: Dictionary, replying: bool, anchor: Vector2, extent: Vector2, avoid: Rect2 = Rect2()) -> void:
	var key := "%s:%s:%s" % [beat.opening, beat.reply, replying]
	var width := minf(340.0, extent.x * 0.39)
	custom_minimum_size.x = width
	# Wrapped labels update minimum height after container layout. Shrink on the
	# following frame too, rather than retaining the first zero-width tall shape.
	size = Vector2(width, 0.0)
	if key != _copy_key:
		_copy_key = key
		_heading.text = "%s  /  %s" % [String(beat.second_name if replying else beat.first_name).to_upper(), Voices.title(int(beat.second_id if replying else beat.first_id))]
		if not String(beat.get("relationship_label", "")).is_empty():
			_heading.text += "  ·  " + String(beat.relationship_label)
		_opening.text = "%s: %s" % [beat.first_name, beat.opening]
		_reply.text = "%s: %s" % [beat.second_name, beat.reply] if replying else "%s is listening..." % beat.second_name
		_opening.add_theme_color_override("font_color", Voices.COLORS[posmod(int(beat.first_id), 6)])
		_reply.add_theme_color_override("font_color", Voices.COLORS[posmod(int(beat.second_id), 6)] if replying else Color("b1bfc0"))
		reset_size()
	# Keep the balloon out of the top HUD and selected-hen action panel.
	position = Vector2(clampf(anchor.x + 32.0, 18.0, extent.x - width - 18.0), clampf(anchor.y - size.y - 28.0, 142.0, maxf(142.0, extent.y - size.y - 190.0)))
	if avoid.has_area() and Rect2(position, size).intersects(avoid):
		position.y = avoid.end.y + 8.0
	_tail = anchor - position
	queue_redraw()
	# Do not flash the provisional, zero-width wrapped height on its first frame.
	modulate.a = 1.0 if size.y <= 180.0 else 0.0
	show()

func _draw() -> void:
	if _tail == Vector2.ZERO:
		return
	var base := Vector2(clampf(_tail.x, 15.0, size.x - 25.0), size.y - 1.0)
	var tip := Vector2(clampf(_tail.x, -24.0, size.x + 24.0), minf(_tail.y, size.y + 24.0))
	draw_colored_polygon(PackedVector2Array([base, base + Vector2(16.0, 0.0), tip]), Color("182c35"))
	draw_polyline(PackedVector2Array([base, tip, base + Vector2(16.0, 0.0)]), Color("a5c6b8"), 2.0, true)

func diagnostic_state() -> Dictionary:
	return {"visible": visible and modulate.a > 0.0, "heading": _heading.text, "opening": _opening.text, "reply": _reply.text, "rect": {"x": position.x, "y": position.y, "width": size.x, "height": size.y}, "blocks_input": mouse_filter != Control.MOUSE_FILTER_IGNORE}
