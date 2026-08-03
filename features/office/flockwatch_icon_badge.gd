class_name FlockwatchIconBadge
extends Control

## Small font-independent symbols for the high-frequency Flockwatch brief.
## Exact meanings remain on the neighboring label's tooltip/accessibility copy;
## these shapes make the default layer recognizable without another word.

const ICON_SIZE := Vector2(28.0, 28.0)

var _kind: StringName = &"goal"
var _accent := Color("dce7e8")
var _badge_size := ICON_SIZE.x


func _init() -> void:
	custom_minimum_size = ICON_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	set_meta("decorative", true)


func configure(kind: StringName, accent: Color = Color("dce7e8")) -> void:
	_kind = kind
	_accent = accent
	queue_redraw()


func set_badge_size(size: float) -> void:
	_badge_size = maxf(12.0, size)
	custom_minimum_size = Vector2(_badge_size, _badge_size)
	queue_redraw()


func _draw() -> void:
	var draw_scale := _badge_size / ICON_SIZE.x
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(draw_scale, draw_scale))
	draw_circle(Vector2(14.0, 14.0), 13.0, Color(_accent, 0.10))
	match _kind:
		&"files": _draw_files()
		&"egg": _draw_egg()
		&"flock": _draw_flock()
		&"cash": _draw_cash()
		&"shield": _draw_shield()
		&"compact": _draw_compact()
		&"pause": _draw_pause()
		_: _draw_goal()


func _draw_files() -> void:
	var fill := Color(_accent, 0.20)
	var points := PackedVector2Array([
		Vector2(4.0, 9.0), Vector2(11.0, 9.0), Vector2(13.0, 6.5),
		Vector2(24.0, 6.5), Vector2(24.0, 22.0), Vector2(4.0, 22.0),
	])
	draw_colored_polygon(points, fill)
	draw_polyline(_closed(points), _accent, 1.8, true)
	draw_line(Vector2(4.5, 11.5), Vector2(23.5, 11.5), _accent, 1.5, true)


func _draw_egg() -> void:
	var points := _ellipse_points(Vector2(14.0, 14.5), 7.0, 9.5)
	draw_colored_polygon(points, Color(_accent, 0.16))
	draw_polyline(_closed(points), _accent, 2.0, true)


func _draw_flock() -> void:
	# A heart reads as flock well-being at a much smaller size than a literal hen.
	# The exact "morale / unity risk" meaning remains in semantic copy.
	draw_circle(Vector2(9.7, 10.0), 5.0, Color(_accent, 0.22))
	draw_circle(Vector2(18.3, 10.0), 5.0, Color(_accent, 0.22))
	draw_colored_polygon(PackedVector2Array([
		Vector2(5.0, 11.0), Vector2(23.0, 11.0), Vector2(14.0, 24.0),
	]), Color(_accent, 0.22))
	draw_arc(Vector2(9.7, 10.0), 5.0, PI, TAU, 14, _accent, 1.8, true)
	draw_arc(Vector2(18.3, 10.0), 5.0, PI, TAU, 14, _accent, 1.8, true)
	draw_line(Vector2(5.0, 11.0), Vector2(14.0, 24.0), _accent, 1.8, true)
	draw_line(Vector2(14.0, 24.0), Vector2(23.0, 11.0), _accent, 1.8, true)


func _draw_cash() -> void:
	for row in range(3):
		var center := Vector2(14.0, 18.5 - float(row) * 4.5)
		var points := _ellipse_points(center, 8.5, 3.1)
		draw_colored_polygon(points, Color(_accent, 0.14 + float(row) * 0.04))
		draw_polyline(_closed(points), _accent, 1.5, true)


func _draw_goal() -> void:
	for radius in [9.0, 5.5, 2.0]:
		draw_arc(Vector2(14.0, 14.0), radius, 0.0, TAU, 24, _accent, 1.5, true)
	draw_line(Vector2(14.0, 2.5), Vector2(14.0, 7.0), _accent, 1.4, true)
	draw_line(Vector2(14.0, 21.0), Vector2(14.0, 25.5), _accent, 1.4, true)


func _draw_shield() -> void:
	var points := PackedVector2Array([
		Vector2(14.0, 3.5), Vector2(23.0, 7.0), Vector2(21.5, 17.5),
		Vector2(14.0, 24.5), Vector2(6.5, 17.5), Vector2(5.0, 7.0),
	])
	draw_colored_polygon(points, Color(_accent, 0.15))
	draw_polyline(_closed(points), _accent, 1.8, true)
	draw_line(Vector2(9.5, 14.0), Vector2(12.5, 17.0), _accent, 2.0, true)
	draw_line(Vector2(12.5, 17.0), Vector2(18.8, 10.0), _accent, 2.0, true)


func _draw_compact() -> void:
	draw_rect(Rect2(6.0, 4.0, 16.0, 20.0), Color(_accent, 0.14), true)
	draw_rect(Rect2(6.0, 4.0, 16.0, 20.0), _accent, false, 1.7)
	for y in [9.0, 13.0, 17.0]:
		draw_line(Vector2(9.0, y), Vector2(19.0, y), _accent, 1.4, true)
	draw_circle(Vector2(18.5, 20.0), 3.5, _accent)


func _draw_pause() -> void:
	draw_rect(Rect2(7.0, 5.0, 5.0, 18.0), _accent, true)
	draw_rect(Rect2(16.0, 5.0, 5.0, 18.0), _accent, true)


func _ellipse_points(center: Vector2, radius_x: float, radius_y: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	if not points.is_empty():
		closed.append(points[0])
	return closed
