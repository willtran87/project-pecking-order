extends Control

## Three physical slots cover the quota bar only during the opening harvest.
## Counts come from the simulation; this widget never awards or collects eggs.
var filled := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_count(count: int) -> void:
	filled = clampi(count, 0, 3)
	queue_redraw()


func _draw() -> void:
	draw_style_box(_background(), Rect2(Vector2.ZERO, size))
	for index in 3:
		var center := Vector2(size.x * (float(index) + 0.5) / 3.0, size.y * 0.5)
		var points := PackedVector2Array()
		for step in 33:
			var angle := TAU * float(step) / 32.0
			points.append(center + Vector2(sin(angle) * (6.0 - cos(angle)), cos(angle) * 8.0))
		if index < filled:
			draw_colored_polygon(points, Color("f4cd66"))
			draw_line(center + Vector2(-3, 0), center + Vector2(-1, 3), Color("172832"), 1.5, true)
			draw_line(center + Vector2(-1, 3), center + Vector2(4, -3), Color("172832"), 1.5, true)
		else:
			draw_polyline(points, Color("82999e"), 1.5, true)


func _background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101a21")
	style.set_corner_radius_all(5)
	return style
