class_name PeckworkRoutingUI
extends Control

const SemanticColorPaletteScript := preload("res://core/settings/semantic_color_palette.gd")
const ManagementUIThemeScript := preload("res://features/office/management_ui_theme.gd")
const FlockwatchIconBadgeScript := preload("res://features/office/flockwatch_icon_badge.gd")


class PriorityPeckIntentLink:
	extends Control

	var source_control: Control
	var target_control: Control
	var pulse_phase := 0.0
	var motion_reduced := false


	func configure(source: Control, target: Control) -> void:
		source_control = source
		target_control = target
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = false


	func set_link_state(
		active: bool,
		reduced_motion: bool,
		phase: float,
		confirmation: bool = false,
		rating: StringName = &"",
	) -> void:
		visible = active
		motion_reduced = reduced_motion
		pulse_phase = phase
		set_meta("active", active)
		set_meta("reduced_motion", reduced_motion)
		set_meta("confirmation", confirmation)
		set_meta("rating", rating)
		if active:
			queue_redraw()


	func _draw() -> void:
		if (
			source_control == null
			or target_control == null
			or not is_instance_valid(source_control)
			or not is_instance_valid(target_control)
		):
			return
		var source_rect := source_control.get_global_rect()
		var target_rect := target_control.get_global_rect()
		var inverse := get_global_transform().affine_inverse()
		var start := inverse * Vector2(
			source_rect.end.x + 2.0,
			source_rect.position.y + source_rect.size.y * 0.54,
		)
		var finish := inverse * Vector2(
			target_rect.position.x - 3.0,
			target_rect.position.y + target_rect.size.y * 0.5,
		)
		var bend := Vector2(
			lerpf(start.x, finish.x, 0.48),
			minf(start.y, finish.y) - 5.0,
		)
		var points := PackedVector2Array()
		for index in 11:
			points.append(_quadratic_point(start, bend, finish, float(index) / 10.0))
		var confirmation := bool(get_meta("confirmation", false))
		var rating := StringName(get_meta("rating", &""))
		var missed := confirmation and rating == &"missed"
		var signal_color := _rating_color(rating) if confirmation else Color(0.98, 0.76, 0.24)
		var fade := (
			1.0 - smoothstep(0.72, 1.0, clampf(pulse_phase, 0.0, 1.0))
			if confirmation else 1.0
		)
		if missed:
			var first_half := PackedVector2Array()
			var second_half := PackedVector2Array()
			for index in 5:
				first_half.append(points[index])
			for index in range(6, points.size()):
				second_half.append(points[index])
			draw_polyline(first_half, Color(signal_color, 0.58 * fade), 2.0, true)
			draw_polyline(second_half, Color(signal_color, 0.58 * fade), 2.0, true)
			var cross_size := 3.0
			draw_line(
				finish + Vector2(-cross_size, -cross_size),
				finish + Vector2(cross_size, cross_size),
				Color(signal_color.lightened(0.22), 0.9 * fade),
				2.0,
				true,
			)
			draw_line(
				finish + Vector2(-cross_size, cross_size),
				finish + Vector2(cross_size, -cross_size),
				Color(signal_color.lightened(0.22), 0.9 * fade),
				2.0,
				true,
			)
		else:
			draw_polyline(points, Color(signal_color, 0.54 * fade), 2.0, true)
			draw_circle(finish, 2.0, Color(signal_color.lightened(0.22), 0.88 * fade))
		var travel := (
			0.56
			if motion_reduced else
			1.0 - clampf(pulse_phase, 0.0, 1.0)
			if confirmation else
			fposmod(pulse_phase * 0.72, 1.0)
		)
		var pulse_point := _quadratic_point(start, bend, finish, travel)
		draw_circle(pulse_point, 3.2, Color(signal_color, 0.96 * fade))
		draw_circle(pulse_point, 1.25, Color(signal_color.lightened(0.65), fade))


	func _quadratic_point(start: Vector2, bend: Vector2, finish: Vector2, weight: float) -> Vector2:
		var inverse_weight := 1.0 - weight
		return (
			start * inverse_weight * inverse_weight
			+ bend * 2.0 * inverse_weight * weight
			+ finish * weight * weight
		)


	func _rating_color(rating: StringName) -> Color:
		match rating:
			&"perfect":
				return Color("f4d667")
			&"strong":
				return Color("a8c894")
			&"steady":
				return Color("74d4c2")
			&"missed":
				return Color("d68a68")
			_:
				return Color("d68a68")


class PriorityPeckChargeMeter:
	extends Control

	var charges := 0
	var charge_limit := 3
	var banked := false
	var recharge_active := false
	var recharge_phase := 0.0
	var recharge_before := 0
	var recharge_after := 0
	var recharge_reduced_motion := false


	func set_counts(next_charges: int, next_limit: int, next_banked: bool) -> void:
		charges = maxi(0, next_charges)
		charge_limit = clampi(next_limit, 1, 5)
		banked = next_banked
		var accessible := "%d of %d Priority Peck charges ready" % [charges, charge_limit]
		if banked:
			accessible += "; one routing recharge is banked"
		tooltip_text = accessible + "."
		set_meta("charges", charges)
		set_meta("limit", charge_limit)
		set_meta("banked", banked)
		set_meta("accessible_text", accessible)
		queue_redraw()


	func set_recharge_state(
		active: bool,
		phase: float,
		reduced_motion: bool,
		before: int,
		after: int,
		serial: int,
	) -> void:
		recharge_active = active
		recharge_phase = clampf(phase, 0.0, 1.0)
		recharge_reduced_motion = reduced_motion
		recharge_before = before
		recharge_after = after
		set_meta("recharge_active", active)
		set_meta("recharge_phase", recharge_phase)
		set_meta("recharge_animated", active and not reduced_motion)
		set_meta("recharge_serial", serial)
		queue_redraw()


	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.055, 0.09, 0.11, 0.92), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color("50656d"), false, 1.0)
		var visible_limit := clampi(charge_limit, 1, 5)
		var pip_gap := 5.0
		var pip_size := 10.0
		var total_width := visible_limit * pip_size + (visible_limit - 1) * pip_gap
		var start_x := (size.x - total_width) * 0.5
		var center_y := size.y * 0.5
		for index in visible_limit:
			var center := Vector2(start_x + pip_size * 0.5 + index * (pip_size + pip_gap), center_y)
			var is_ready := index < charges
			var is_new_charge := recharge_active and index == recharge_after - 1
			var pulse_scale := 1.0
			if is_new_charge and not recharge_reduced_motion:
				pulse_scale = 0.72 + ease(minf(1.0, recharge_phase * 2.2), -1.7) * 0.34
			var radius := pip_size * 0.5 * pulse_scale
			var points := PackedVector2Array([
				center + Vector2(0.0, -radius),
				center + Vector2(radius, 0.0),
				center + Vector2(0.0, radius),
				center + Vector2(-radius, 0.0),
			])
			var fill := (
				Color("74d4c2")
				if is_new_charge or (banked and index == charge_limit - 1) else
				Color("e7c56e")
			)
			if is_ready:
				draw_colored_polygon(points, fill)
				draw_circle(center, 1.25, Color("fff9df"))
			var outline := PackedVector2Array(points)
			outline.append(points[0])
			draw_polyline(
				outline,
				Color("d9fff7") if is_new_charge else Color("8ca0a8"),
				1.4 if is_ready else 1.0,
				true,
			)
			if banked and index == charge_limit - 1:
				draw_arc(center, radius + 2.3, 0.0, TAU, 16, Color("74d4c2"), 1.2, true)
			if is_new_charge:
				var ring_alpha := 0.78 if recharge_reduced_motion else 1.0 - smoothstep(0.58, 1.0, recharge_phase)
				draw_arc(
					center,
					radius + 3.0 + recharge_phase * 3.0,
					0.0,
					TAU,
					18,
					Color(Color("d9fff7"), ring_alpha),
					1.5,
					true,
				)


class FirstClutchProgressRail:
	extends Control

	var completed_steps := 0
	var step_total := 5


	func set_progress(next_completed: int, next_total: int) -> void:
		step_total = clampi(next_total, 1, 9)
		completed_steps = clampi(next_completed, 0, step_total)
		custom_minimum_size = Vector2(maxf(78.0, step_total * 15.0), 14.0)
		var active_step := mini(completed_steps + 1, step_total)
		accessibility_name = (
			"First Clutch: all %d steps complete." % step_total
			if completed_steps >= step_total else
			"First Clutch: %d of %d steps complete; step %d active."
			% [completed_steps, step_total, active_step]
		)
		tooltip_text = accessibility_name
		set_meta("completed_steps", completed_steps)
		set_meta("total_steps", step_total)
		set_meta("active_step", 0 if completed_steps >= step_total else active_step)
		set_meta("shape_language", "check=complete; diamond=active; ring=upcoming")
		queue_redraw()


	func presentation_state() -> Dictionary:
		return {
			"visible": visible,
			"completed_steps": completed_steps,
			"total_steps": step_total,
			"active_step": int(get_meta("active_step", 0)),
			"accessible_text": accessibility_name,
			"shape_language": String(get_meta("shape_language", "")),
		}


	func _draw() -> void:
		if step_total <= 0:
			return
		var gap := 15.0
		var rail_width := (step_total - 1) * gap
		var start_x := (size.x - rail_width) * 0.5
		var center_y := size.y * 0.5
		if step_total > 1:
			draw_line(
				Vector2(start_x, center_y),
				Vector2(start_x + rail_width, center_y),
				Color("51636b"),
				1.2,
				true,
			)
		for index in step_total:
			var center := Vector2(start_x + index * gap, center_y)
			if index < completed_steps:
				draw_circle(center, 4.4, Color("73b5a7"))
				draw_line(center + Vector2(-2.1, 0.1), center + Vector2(-0.4, 1.8), Color("effff9"), 1.25, true)
				draw_line(center + Vector2(-0.4, 1.8), center + Vector2(2.5, -2.0), Color("effff9"), 1.25, true)
			elif index == completed_steps:
				var radius := 5.0
				var diamond := PackedVector2Array([
					center + Vector2(0.0, -radius),
					center + Vector2(radius, 0.0),
					center + Vector2(0.0, radius),
					center + Vector2(-radius, 0.0),
					center + Vector2(0.0, -radius),
				])
				draw_colored_polygon(diamond, Color("d8b967"))
				draw_polyline(diamond, Color("fff0ae"), 1.2, true)
				draw_circle(center, 1.25, Color("fff9df"))
			else:
				draw_circle(center, 3.5, Color("172832"))
				draw_arc(center, 3.5, 0.0, TAU, 16, Color("7b8e95"), 1.2, true)


class RoutingLifecycleRail:
	extends Control

	const STAGES: Array[StringName] = [&"route", &"peck", &"egg"]
	const LABELS := ["ROUTE", "PECK", "EGG"]
	const STAGE_SHAPES: Array[StringName] = [&"file_tray", &"work_monitor", &"egg_receipt"]

	var active_stage: StringName = &"route"
	var clean_delivery_refund := false


	func set_stage(stage: StringName, restores_charge_on_clean_delivery := false) -> void:
		active_stage = stage if stage in STAGES else &"route"
		clean_delivery_refund = (
			restores_charge_on_clean_delivery and active_stage == &"egg"
		)
		var stage_index := STAGES.find(active_stage)
		accessibility_name = (
			"Work cycle: route a file, the hen pecks it, then lays the completed egg. "
			+ "Current step: %s."
		) % String(LABELS[stage_index]).to_lower()
		if clean_delivery_refund:
			accessibility_name += (
				" This clean assisted egg will restore one Priority Peck charge "
				+ "when it reaches the farmer."
			)
		tooltip_text = accessibility_name
		set_meta("active_stage", active_stage)
		set_meta("active_index", stage_index)
		set_meta("sequence", ["route", "peck", "egg"])
		set_meta("stage_shapes", ["file_tray", "work_monitor", "egg_receipt"])
		set_meta("visible_stage_labels", false)
		set_meta("clean_delivery_refund", clean_delivery_refund)
		set_meta("reward_shape", &"charge_diamond_plus_one" if clean_delivery_refund else &"")
		set_meta(
			"shape_language",
			(
				"file tray=route; work monitor=peck; egg receipt=egg; "
				+ "check=complete; double frame+pointer=current; outline=upcoming; "
				+ "diamond+1=clean delivery restores peck"
			),
		)
		queue_redraw()


	func presentation_state() -> Dictionary:
		var active_index := STAGES.find(active_stage)
		var stage_states: Array[Dictionary] = []
		for index in STAGES.size():
			stage_states.append({
				"id": String(STAGES[index]),
				"accessible_label": String(LABELS[index]),
				"semantic_shape": String(STAGE_SHAPES[index]),
				"state": (
					"complete" if index < active_index else
					"current" if index == active_index else
					"upcoming"
				),
			})
		return {
			"visible": is_visible_in_tree(),
			"active_stage": String(active_stage),
			"sequence": ["route", "peck", "egg"],
			"stage_states": stage_states,
			"visible_stage_labels": false,
			"accessible_text": accessibility_name,
			"shape_language": String(get_meta("shape_language", "")),
			"clean_delivery_refund": clean_delivery_refund,
			"reward_shape": String(get_meta("reward_shape", &"")),
		}


	func _draw() -> void:
		var font := get_theme_default_font()
		var active_index := STAGES.find(active_stage)
		var station_step := 51.0
		for index in STAGES.size():
			var center := Vector2(14.0 + index * station_step, 11.5)
			var completed := index < active_index
			var active := index == active_index
			var plate := Rect2(center - Vector2(14.0, 10.5), Vector2(28.0, 21.0))
			var color := Color("effff9") if completed else Color("fff0ae") if active else Color("82939a")
			var plate_fill := Color("245449") if completed else Color("453a1f") if active else Color("17252c")
			draw_rect(plate, plate_fill, true)
			draw_rect(plate, Color("73b5a7") if completed else Color("d8b967") if active else Color("52656d"), false, 1.25)
			if active:
				draw_rect(plate.grow(-2.5), Color("e8cb70"), false, 1.0)
				var pointer := PackedVector2Array([
					center + Vector2(-3.0, 10.5),
					center + Vector2(3.0, 10.5),
					center + Vector2(0.0, 13.5),
				])
				draw_colored_polygon(pointer, Color("d8b967"))
			match index:
				0:
					_draw_tray(center, color)
				1:
					_draw_screen(center, color)
				2:
					_draw_egg(center, color)
			if completed:
				var check_center := center + Vector2(10.5, -7.5)
				draw_circle(check_center, 3.6, Color("73b5a7"))
				draw_line(check_center + Vector2(-1.8, 0.0), check_center + Vector2(-0.4, 1.4), Color("effff9"), 1.0, true)
				draw_line(check_center + Vector2(-0.4, 1.4), check_center + Vector2(2.0, -1.5), Color("effff9"), 1.0, true)
			if index < STAGES.size() - 1:
				var arrow_start := center + Vector2(17.0, 0.0)
				var arrow_end := center + Vector2(34.0, 0.0)
				draw_line(arrow_start, arrow_end, Color("52656d"), 1.2, true)
				draw_line(arrow_end, arrow_end + Vector2(-3.0, -2.5), Color("52656d"), 1.2, true)
				draw_line(arrow_end, arrow_end + Vector2(-3.0, 2.5), Color("52656d"), 1.2, true)
		if clean_delivery_refund:
			var reward_center := Vector2(148.0, 11.5)
			var reward_radius := 5.0
			var reward_diamond := PackedVector2Array([
				reward_center + Vector2(0.0, -reward_radius),
				reward_center + Vector2(reward_radius, 0.0),
				reward_center + Vector2(0.0, reward_radius),
				reward_center + Vector2(-reward_radius, 0.0),
			])
			draw_colored_polygon(reward_diamond, Color("73b5a7"))
			draw_line(reward_center + Vector2(-2.1, 0.0), reward_center + Vector2(2.1, 0.0), Color("effff9"), 1.15, true)
			draw_line(reward_center + Vector2(0.0, -2.1), reward_center + Vector2(0.0, 2.1), Color("effff9"), 1.15, true)
			draw_string(font, Vector2(156.0, 15.5), "+1", HORIZONTAL_ALIGNMENT_LEFT, 20.0, 10, Color("9fd4bd"))


	func _draw_tray(center: Vector2, color: Color) -> void:
		draw_rect(Rect2(center + Vector2(-6.0, -3.0), Vector2(12.0, 8.0)), color, false, 1.25)
		draw_line(center + Vector2(-4.0, -5.0), center + Vector2(1.0, -5.0), color, 1.25, true)
		draw_line(center + Vector2(1.0, -5.0), center + Vector2(3.0, -3.0), color, 1.25, true)


	func _draw_screen(center: Vector2, color: Color) -> void:
		draw_rect(Rect2(center + Vector2(-6.0, -5.0), Vector2(12.0, 9.0)), color, false, 1.25)
		draw_line(center + Vector2(0.0, 4.0), center + Vector2(0.0, 6.0), color, 1.25, true)
		draw_line(center + Vector2(-3.0, 6.0), center + Vector2(3.0, 6.0), color, 1.25, true)


	func _draw_egg(center: Vector2, color: Color) -> void:
		var points := PackedVector2Array()
		for point_index in 17:
			var angle := TAU * float(point_index) / 16.0
			var vertical := sin(angle)
			var taper := 1.0 - maxf(0.0, -vertical) * 0.18
			points.append(center + Vector2(cos(angle) * 4.2 * taper, vertical * 6.0))
		draw_polyline(points, color, 1.25, true)


class RoutingMomentumBreakGlyph:
	extends Control

	var retreat_phase := 0.0
	var motion_reduced := false
	var link_mode: StringName = &"break"


	func set_break_state(active: bool, phase: float, reduced_motion: bool) -> void:
		visible = active
		retreat_phase = clampf(phase, 0.0, 1.0)
		motion_reduced = reduced_motion
		link_mode = &"break"
		set_meta("active", active)
		set_meta("phase", retreat_phase)
		set_meta("reduced_motion", reduced_motion)
		set_meta("mode", link_mode if active else &"")
		if active:
			queue_redraw()

	func set_recovery_state(active: bool, phase: float, reduced_motion: bool) -> void:
		visible = active
		retreat_phase = clampf(phase, 0.0, 1.0)
		motion_reduced = reduced_motion
		link_mode = &"recovery"
		set_meta("active", active)
		set_meta("phase", retreat_phase)
		set_meta("reduced_motion", reduced_motion)
		set_meta("mode", link_mode if active else &"")
		if active:
			queue_redraw()


	func _draw() -> void:
		if link_mode == &"recovery":
			_draw_recovery()
			return
		var phase := 0.34 if motion_reduced else retreat_phase
		var retreat := ease(clampf(phase, 0.0, 1.0), 1.8) * 2.5
		var fade := 1.0 - smoothstep(0.76, 1.0, phase)
		if motion_reduced:
			fade = 1.0
		var color := Color(Color("d68a68"), 0.96 * fade)
		var highlight := Color(Color("ffd0ba"), fade)
		# Two outward-facing link halves leave an unmistakable gap. The centered
		# X keeps the loss shape-distinct in every color-vision mode.
		draw_arc(
			Vector2(5.5 - retreat, 9.0), 4.1,
			-PI * 0.66, PI * 0.66, 12, color, 2.0, true,
		)
		draw_arc(
			Vector2(12.5 + retreat, 9.0), 4.1,
			PI * 0.34, PI * 1.66, 12, color, 2.0, true,
		)
		var cross := 2.2
		draw_line(
			Vector2(9.0 - cross, 9.0 - cross),
			Vector2(9.0 + cross, 9.0 + cross),
			highlight, 1.8, true,
		)
		draw_line(
			Vector2(9.0 - cross, 9.0 + cross),
			Vector2(9.0 + cross, 9.0 - cross),
			highlight, 1.8, true,
		)


	func _draw_recovery() -> void:
		var phase := 0.72 if motion_reduced else retreat_phase
		var join_offset := (1.0 - ease(clampf(phase, 0.0, 1.0), 2.2)) * 2.8
		var color := Color("74d4c2")
		var highlight := Color("d9fff7")
		# The same two link halves that retreated on loss now visibly converge.
		# A check-shaped join mark makes the repaired state readable without color.
		draw_arc(
			Vector2(5.5 - join_offset, 9.0), 4.1,
			-PI * 0.66, PI * 0.66, 12, color, 2.0, true,
		)
		draw_arc(
			Vector2(12.5 + join_offset, 9.0), 4.1,
			PI * 0.34, PI * 1.66, 12, color, 2.0, true,
		)
		var mark_alpha := smoothstep(0.42, 0.78, phase)
		var mark_color := Color(highlight, mark_alpha)
		draw_line(Vector2(7.1, 9.2), Vector2(8.6, 10.6), mark_color, 1.8, true)
		draw_line(Vector2(8.6, 10.6), Vector2(11.2, 7.4), mark_color, 1.8, true)

## Compact management surface for typed peckwork queues.
##
## The queue strip stays readable in the office overview. Selecting a hen opens
## the lower routing dossier, turning camera inspection into an authoritative
## staffing action without covering the character or the workstations.

signal assignment_requested(worker_id: int, lane: StringName)
signal assignment_undo_requested(worker_id: int)
signal dispatch_lane_requested(lane: StringName)
signal claim_resolution_requested(worker_id: int, path_id: StringName)
signal personnel_action_requested(worker_id: int, action_id: StringName)
signal peck_assist_requested(worker_id: int)
signal first_clutch_skip_requested
signal first_clutch_focus_requested(worker_id: int)
signal first_clutch_skip_rect_settled(rect: Rect2)
signal interaction_safety_changed

const PECK_RESULT_LINK_DURATION := 0.72
const PECK_MISSED_LINK_DURATION := 0.58
const CLAIM_FILE_ARRIVAL_DURATION := 1.8
const HEN_DOSSIER_ARRIVAL_DURATION := 1.8
const DISPATCH_TRAY_ARRIVAL_DURATION := 1.8
const PECK_RECHARGE_DISPLAY_SECONDS := 1.55
const DISPATCH_BREAK_DISPLAY_SECONDS := 3.8
const DISPATCH_BREAK_GLYPH_SECONDS := 0.92
const DISPATCH_BREAK_RETREAT_SECONDS := 0.68
const DISPATCH_BREAK_RECOVERY_SECONDS := 0.92
const DISPATCH_RECOVERY_DISPLAY_SECONDS := 1.55
const DISPATCH_RECOVERY_JOIN_SECONDS := 0.78
const DISPATCH_RECOVERY_GLYPH_SECONDS := 1.12
const QUEUE_IDLE_RIGHT := 422.0
const QUEUE_MOMENTUM_RIGHT := 561.0

const LANE_ORDER: Array[StringName] = [
	&"nest_damage",
	&"predator_loss",
	&"appeals",
]
const ASSIGNMENT_ORDER: Array[StringName] = [
	&"auto",
	&"nest_damage",
	&"predator_loss",
	&"appeals",
]
const LANE_NAMES := {
	&"auto": "AUTO SORT",
	&"nest_damage": "NEST DAMAGE",
	&"predator_loss": "PREDATOR LOSS",
	&"appeals": "APPEALS",
}
const LANE_ACTION_NAMES := {
	&"auto": "AUTO",
	&"nest_damage": "NEST",
	&"predator_loss": "PREDATOR",
	&"appeals": "APPEALS",
}
const LANE_SHORT_NAMES := {
	&"nest_damage": "NEST",
	&"predator_loss": "PREDATOR",
	&"appeals": "APPEALS",
}
const PERSONNEL_ACTION_ORDER: Array[StringName] = [
	&"share_credit",
	&"career_coaching",
	&"quota_pressure",
]
const PERSONNEL_ACTION_NAMES := {
	&"share_credit": "SHARE CREDIT",
	&"career_coaching": "CAREER COACH",
	&"quota_pressure": "QUOTA PRESSURE",
}
const PERSONNEL_ACTION_TOOLTIPS := {
	&"share_credit": "Publicly recognize this hen's work. Builds trust and eases grievances.",
	&"career_coaching": "Invest in this hen's career development. Builds experience with a modest short-term strain.",
	&"quota_pressure": "Demand more output from this hen at a personal cost.",
}

var _queue_labels: Dictionary[StringName, Label] = {}
var _queue_buttons: Dictionary[StringName, Button] = {}
var _queue_lane_icons: Dictionary[StringName, TextureRect] = {}
var _queue_title_label: Label
var _queue_contract_badge: Label
var _queue_compact_label: Label
var _queue_row: HBoxContainer
var _queue_heading: VBoxContainer
var _queue_overdue_host: HBoxContainer
var _queue_overdue_icon: TextureRect
var _dispatch_momentum_label: Label
var _dispatch_momentum_break_glyph: RoutingMomentumBreakGlyph
var _return_cue_focus_serial := 0
var _last_return_cue_focus: Dictionary = {}
var _assignment_buttons: Dictionary[StringName, Button] = {}
var _personnel_buttons: Dictionary[StringName, Button] = {}
var _queue_panel: PanelContainer
var _first_clutch_panel: PanelContainer
var _first_clutch_progress_label: Label
var _first_clutch_progress_rail: FirstClutchProgressRail
var _first_clutch_title_label: Label
var _first_clutch_body_label: Label
var _first_clutch_return_button: Button
var _first_clutch_skip_button: Button
var _focus_panel: PanelContainer
var _worker_name_label: Label
var _worker_career_label: Label
var _worker_identity_row: HBoxContainer
var _worker_profile_icon: TextureRect
var _worker_specialty_icon: TextureRect
var _worker_trait_label: Label
var _hen_intent_button: Button
var _details_button: Button
var _dossier_tabs: HBoxContainer
var _dossier_tab_buttons: Dictionary[StringName, Button] = {}
var _active_dossier_tab: StringName = &"route"
var _claim_file_arrival_remaining := 0.0
var _claim_file_arrival_claim_id := -1
var _claim_file_arrival_serial := 0
var _hen_dossier_arrival_remaining := 0.0
var _hen_dossier_arrival_worker_id := -1
var _hen_dossier_arrival_serial := 0
var _dispatch_tray_arrival_remaining := 0.0
var _dispatch_tray_arrival_lane: StringName = &""
var _dispatch_tray_arrival_target: Control
var _dispatch_tray_arrival_serial := 0
var _dispatch_tray_arrival_fallback := false
var _dispatch_tray_arrival_queue_title_text := ""
var _current_claim_label: Label
var _claim_phase_icon: TextureRect
var _claim_phase_progress_label: Label
var _golden_file_badge: Label
var _current_contract_badge: Label
var _claim_context_row: HBoxContainer
var _claim_detail_strip: HBoxContainer
var _claim_detail_fact_groups: Array[Control] = []
var _claim_detail_fact_icons: Array[Control] = []
var _claim_detail_fact_values: Array[Label] = []
var _routing_lifecycle_rail: RoutingLifecycleRail
var _claim_progress_track: Control
var _claim_progress_bar: ProgressBar
var _peck_timing_band: ColorRect
var _peck_timing_marker: ColorRect
var _peck_timing_label: Label
var _priority_peck_intent_link: PriorityPeckIntentLink
var _dossier_summary_label: Label
var _routing_hint_label: Label
var _peck_assist_button: Button
var _peck_charge_meter: PriorityPeckChargeMeter
var _trust_label: Label
var _grievance_label: Label
var _check_in_status_label: Label
var _claim_header: HBoxContainer
var _assist_row: HBoxContainer
var _personnel_status: HBoxContainer
var _assignment_section: GridContainer
var _assignment_undo_button: Button
var _claim_resolution_section: VBoxContainer
var _claim_resolution_buttons: Dictionary[StringName, Button] = {}
var _claim_resolution_confirmation: ConfirmationDialog
var _pending_claim_resolution_path: StringName = &""
var _pending_claim_resolution_worker_id := -1
var _pending_claim_resolution_claim_id := -1
var _claim_resolution_origin: Control
var _personnel_actions_section: VBoxContainer
var _focused_worker_id := -1
var _snapshot: Dictionary = {}
var _interaction_enabled := true
var _active_dispatch_lane: StringName = &""
var _dispatch_momentum_chain := 0
var _dispatch_recommended_name := ""
var _dispatch_reward_label := ""
var _routing_best_chain := 0
var _routing_next_milestone := 0
var _routing_next_reward := ""
var _routing_mastery_target_kind: StringName = &""
var _dispatch_reward_tween: Tween
var _dispatch_break_remaining := 0.0
var _dispatch_break_chain := 0
var _dispatch_break_reason := ""
var _dispatch_break_source: StringName = &""
var _dispatch_break_serial := 0
var _dispatch_break_capture_staged := false
var _dispatch_recovery_remaining := 0.0
var _dispatch_recovery_worker_name := ""
var _dispatch_recovery_lane: StringName = &""
var _dispatch_recovery_break_serial := 0
var _dispatch_recovery_serial := 0
var _dispatch_recovery_authority_serial := 0
var _dispatch_recovery_capture_staged := false
var _peck_assist_clock_running := true
var _peck_assist_binding_label := "E / A"
var _reduced_motion := false
var _color_vision_mode: StringName = &"standard"
var _assist_pulse_phase := 0.0
var _peck_result_link_remaining := 0.0
var _peck_result_link_rating: StringName = &""
var _peck_missed_link_serial := 0
var _peck_missed_capture_staged := false
var _peck_recharge_remaining := 0.0
var _peck_recharge_before := 0
var _peck_recharge_after := 0
var _peck_recharge_serial := 0
var _peck_recharge_authority_key := ""
var _peck_recharge_capture_staged := false
var _hen_intent_transition_tween: Tween
var _last_hen_intent_key := ""
var _hen_intent_transition_serial := 0
var _context_action_serial := 0
var _context_action_id: StringName = &""
var _context_action_target_name := ""
var _peck_result_focus_handoff: Dictionary = {
	"status": "idle",
	"worker_id": -1,
	"claim_id": -1,
	"target": "",
	"action_id": "",
	"serial": 0,
	"reason": "",
}
var _first_clutch: Dictionary = {}
var _first_clutch_cued_control: Control
var _first_clutch_layout_width := -1.0
var _first_clutch_compact := false
var _last_first_clutch_skip_rect := Rect2()
var _details_expanded := false
var _top_inset := 120.0
var _interface_scale := 1.0
var _icon_led_queue_marks := true


func _ready() -> void:
	name = "PeckworkRoutingUI"
	# Management pauses the simulation tree while this presentation remains
	# interactive. Keep only this UI process alive so its visual cue and settled
	# accessibility target do not freeze with the authoritative clock.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_queue_strip()
	_build_first_clutch_coach()
	_build_focus_dossier()
	_build_claim_resolution_confirmation()
	resized.connect(_apply_first_clutch_layout)
	_apply_first_clutch_layout()
	_refresh()
	set_process(true)


func _process(delta: float) -> void:
	_process_claim_file_arrival(delta)
	_process_hen_dossier_arrival(delta)
	_process_dispatch_tray_arrival(delta)
	_process_dispatch_break(delta)
	_process_dispatch_recovery(delta)
	_process_priority_peck_recharge(delta)
	var viewport_width := get_viewport_rect().size.x
	if not is_equal_approx(viewport_width, _first_clutch_layout_width):
		_apply_first_clutch_layout()
	var skip_rect := first_clutch_skip_button_rect()
	if not skip_rect.is_equal_approx(_last_first_clutch_skip_rect):
		_last_first_clutch_skip_rect = skip_rect
		if skip_rect.has_area():
			first_clutch_skip_rect_settled.emit(skip_rect)
	var peck_visible := _peck_assist_button != null and _peck_assist_button.visible
	var dispatch_break_active := (
		_dispatch_break_remaining > 0.0 or _dispatch_recovery_remaining > 0.0
	)
	var peck_recharge_active := _peck_recharge_remaining > 0.0
	var peck_link_active := (
		_priority_peck_intent_link != null
		and _hen_intent_button != null
		and _hen_intent_button.is_visible_in_tree()
		and not _hen_intent_button.disabled
		and StringName(_hen_intent_button.get_meta("action_id", &"")) == &"peck"
		and _peck_assist_button != null
		and bool(_peck_assist_button.get_meta("assist_live", false))
		and _claim_progress_track != null
		and _claim_progress_track.is_visible_in_tree()
	)
	if _peck_result_link_remaining > 0.0 and not _peck_missed_capture_staged:
		_peck_result_link_remaining = maxf(0.0, _peck_result_link_remaining - delta)
	var result_link_active := (
		_peck_result_link_remaining > 0.0
		and _hen_intent_button != null
		and _hen_intent_button.is_visible_in_tree()
		and _claim_progress_track != null
		and _claim_progress_track.is_visible_in_tree()
	)
	if result_link_active:
		peck_link_active = false
	var cue_visible := (
		_first_clutch_cued_control != null
		and is_instance_valid(_first_clutch_cued_control)
		and _first_clutch_cued_control.is_visible_in_tree()
	)
	if (
		not peck_visible
		and not cue_visible
		and not peck_link_active
		and not result_link_active
		and not dispatch_break_active
		and not peck_recharge_active
	):
		if _priority_peck_intent_link != null:
			_priority_peck_intent_link.set_link_state(false, _reduced_motion, _assist_pulse_phase)
		return
	if _reduced_motion:
		if peck_visible:
			_peck_assist_button.modulate = Color.WHITE
		if _hen_intent_button != null:
			_hen_intent_button.modulate = Color.WHITE
		if _priority_peck_intent_link != null:
			_priority_peck_intent_link.set_link_state(
				peck_link_active or result_link_active,
				true,
				_result_link_progress() if result_link_active else _assist_pulse_phase,
				result_link_active,
				_peck_result_link_rating,
			)
		if cue_visible:
			_first_clutch_cued_control.self_modulate = Color.WHITE
		return
	_assist_pulse_phase = fmod(_assist_pulse_phase + delta, TAU)
	if peck_visible:
		var assist_open := bool(_peck_assist_button.get_meta("assist_live", false))
		_peck_assist_button.modulate = (
			Color(1.0, 1.0, 1.0, 0.92 + sin(_assist_pulse_phase * 4.2) * 0.08)
			if assist_open else Color.WHITE
		)
	if _hen_intent_button != null:
		_hen_intent_button.modulate = (
			Color(1.0, 1.0, 1.0, 0.94 + sin(_assist_pulse_phase * 4.2) * 0.06)
			if peck_link_active else Color.WHITE
		)
	if _priority_peck_intent_link != null:
		_priority_peck_intent_link.set_link_state(
			peck_link_active or result_link_active,
			false,
			_result_link_progress() if result_link_active else _assist_pulse_phase,
			result_link_active,
			_peck_result_link_rating,
		)
	if cue_visible:
		var cue_lift := 0.94 + (sin(_assist_pulse_phase * 3.6) + 1.0) * 0.03
		_first_clutch_cued_control.self_modulate = Color(cue_lift, cue_lift, cue_lift, 1.0)


func set_focus(worker_id: int) -> void:
	if worker_id != _focused_worker_id:
		_finish_claim_file_arrival()
		_finish_hen_dossier_arrival()
		_cancel_peck_result_focus_handoff("worker_focus_changed")
		_peck_missed_capture_staged = false
		set_meta("peck_missed_capture_staged", false)
		_reset_hen_intent_transition()
		_last_hen_intent_key = ""
		_details_expanded = not bool(_first_clutch.get("visible", false))
		_active_dossier_tab = &"route"
	_focused_worker_id = worker_id
	_refresh()


func clear_focus() -> void:
	_cancel_claim_resolution_confirmation(false)
	set_focus(-1)


func apply_snapshot(snapshot: Dictionary) -> void:
	# Office creates this bounded routing projection solely for this component.
	# The UI never mutates it, so retaining the owned value avoids a third copy of
	# every live claim and worker dossier on each accelerated clock publication.
	_snapshot = snapshot
	if _claim_file_arrival_remaining > 0.0:
		var arrival_worker := _worker_snapshot(_focused_worker_id)
		var arrival_claim := arrival_worker.get("current_claim", {}) as Dictionary
		if int(arrival_claim.get("id", -1)) != _claim_file_arrival_claim_id:
			_finish_claim_file_arrival()
	if _hen_dossier_arrival_remaining > 0.0:
		var dossier_worker := _worker_snapshot(_hen_dossier_arrival_worker_id)
		if dossier_worker.is_empty() or _hen_dossier_arrival_worker_id != _focused_worker_id:
			_finish_hen_dossier_arrival()
	var momentum := snapshot.get("routing_momentum", {}) as Dictionary
	_routing_best_chain = int(momentum.get("best_chain", 0))
	_routing_next_milestone = int(momentum.get("next_milestone", 0))
	_routing_next_reward = String(momentum.get("next_reward", ""))
	_routing_mastery_target_kind = StringName(String(momentum.get("mastery_target_kind", "")))
	if _peck_charge_meter != null:
		_peck_charge_meter.set_counts(
			int(snapshot.get("peck_assists_remaining", 0)),
			int(snapshot.get("peck_assist_limit", 3)),
			int(momentum.get("peck_recharge_bank", 0)) > 0,
		)
	if not _pending_claim_resolution_is_valid():
		_cancel_claim_resolution_confirmation(false)
	_refresh()
	_repair_committed_peck_focus()


func set_egg_journey_receipts(receipts: Array[Dictionary]) -> void:
	_snapshot["egg_journey_receipts"] = receipts
	_refresh()


func egg_journey_receipt_state() -> Dictionary:
	if _routing_hint_label == null:
		return {"visible": false}
	return {
		"visible": bool(_routing_hint_label.get_meta("egg_journey_visible", false)),
		"worker_id": int(_routing_hint_label.get_meta("egg_journey_worker_id", -1)),
		"claim_id": int(_routing_hint_label.get_meta("egg_journey_claim_id", -1)),
		"stage": String(_routing_hint_label.get_meta("egg_journey_stage", &"")),
		"active_count": int(_routing_hint_label.get_meta("egg_journey_active_count", 0)),
		"copy": _routing_hint_label.text,
		"accessible_text": String(_routing_hint_label.get_meta("accessible_text", "")),
	}


func routing_lifecycle_state() -> Dictionary:
	var state := (
		_routing_lifecycle_rail.presentation_state()
		if _routing_lifecycle_rail != null else
		{"visible": false}
	)
	state["header_copy"] = _current_claim_label.text if _current_claim_label != null else ""
	state["header_accessible_text"] = (
		String(_current_claim_label.get_meta("accessible_text", ""))
		if _current_claim_label != null else
		""
	)
	state["header_role"] = (
		String(_current_claim_label.get_meta("presentation_role", &"status"))
		if _current_claim_label != null else
		"status"
	)
	state["header_phase_visible"] = (
		_claim_phase_icon.is_visible_in_tree()
		if _claim_phase_icon != null else
		false
	)
	state["header_phase_shape"] = (
		String(_claim_phase_icon.get_meta("semantic_shape", ""))
		if _claim_phase_icon != null else
		""
	)
	state["header_phase_progress"] = (
		_claim_phase_progress_label.text
		if _claim_phase_progress_label != null and _claim_phase_progress_label.visible else
		""
	)
	state["header_phase_accessible_text"] = (
		_claim_phase_icon.accessibility_name
		if _claim_phase_icon != null else
		""
	)
	state["identity_copy"] = _worker_trait_label.text if _worker_trait_label != null else ""
	state["identity_accessible_text"] = (
		String(_worker_trait_label.get_meta("accessible_text", ""))
		if _worker_trait_label != null else
		""
	)
	state["identity_role"] = (
		String(_worker_trait_label.get_meta("presentation_role", &"worker_identity"))
		if _worker_trait_label != null else
		"worker_identity"
	)
	state["route_hint_copy"] = _routing_hint_label.text if _routing_hint_label != null else ""
	state["route_hint_accessible_text"] = (
		String(_routing_hint_label.get_meta("accessible_text", ""))
		if _routing_hint_label != null else
		""
	)
	state["route_hint_role"] = (
		String(_routing_hint_label.get_meta("presentation_role", &"status"))
		if _routing_hint_label != null else
		"status"
	)
	state["route_hint_visible"] = (
		_routing_hint_label.is_visible_in_tree()
		if _routing_hint_label != null else
		false
	)
	state["claim_facts_visible"] = (
		_claim_detail_strip.is_visible_in_tree()
		if _claim_detail_strip != null else
		false
	)
	state["claim_facts"] = (
		(_claim_detail_strip.get_meta("facts", []) as Array).duplicate(true)
		if _claim_detail_strip != null else
		[]
	)
	state["claim_facts_accessible_text"] = (
		String(_claim_detail_strip.get_meta("accessible_text", ""))
		if _claim_detail_strip != null else
		""
	)
	state["claim_facts_shape_language"] = (
		String(_claim_detail_strip.get_meta("shape_language", ""))
		if _claim_detail_strip != null else
		""
	)
	var component_rect := get_global_rect()
	var dossier_rect := _focus_panel.get_global_rect() if _focus_panel != null else Rect2()
	var viewport_rect := Rect2(Vector2.ZERO, get_viewport_rect().size)
	state["component_rect"] = {
		"x": component_rect.position.x,
		"y": component_rect.position.y,
		"width": component_rect.size.x,
		"height": component_rect.size.y,
	}
	state["dossier_rect"] = {
		"x": dossier_rect.position.x,
		"y": dossier_rect.position.y,
		"width": dossier_rect.size.x,
		"height": dossier_rect.size.y,
	}
	state["dossier_visible"] = _focus_panel != null and _focus_panel.is_visible_in_tree()
	state["dossier_contained"] = (
		dossier_rect.has_area()
		and viewport_rect.encloses(dossier_rect)
	)
	return state


func golden_file_state() -> Dictionary:
	return {
		"visible": _golden_file_badge != null and _golden_file_badge.visible,
		"claim_id": int(_claim_header.get_meta("routing_golden_claim_id", -1)) if _claim_header != null else -1,
		"shape": "star_wordmark",
		"label": _golden_file_badge.text if _golden_file_badge != null else "",
		"accessible_text": _golden_file_badge.tooltip_text if _golden_file_badge != null else "",
		"reduced_motion": _reduced_motion,
	}


## Applies presentation-only state for the optional first-shift coach.
##
## Expected fields are `visible`, `progress`, `total`, `title`, and `body`.
## `cue` may be `route`, `check_in`, or `priority_peck`; route cues read
## `lane`, check-in cues read `action_id`, and `worker_id` optionally limits a
## cue to that hen's open dossier. A bound worker mismatch exposes a recovery
## intent, while `resume_required` suppresses the disabled Priority Peck cue.
## This component never advances coach state or changes camera focus directly.
func apply_first_clutch(coach: Dictionary) -> void:
	var previous_stage := _first_clutch_disclosure_stage()
	var was_active := bool(_first_clutch.get("visible", false))
	_first_clutch = coach.duplicate(true)
	var is_active := bool(_first_clutch.get("visible", false))
	if previous_stage != _first_clutch_disclosure_stage() or was_active != is_active:
		_details_expanded = not is_active
	_refresh_first_clutch()


## Sets the presentation stage without transferring ownership of tutorial state.
##
## Office remains authoritative over progress and completion. This convenience
## API accepts the same payload as `apply_first_clutch`, stamps both compatible
## stage keys, and defaults known induction stages to visible. Passing `normal`,
## `dismissed`, or an empty stage reveals the complete management surface.
func set_first_clutch_stage(stage: StringName, state: Dictionary = {}) -> void:
	var coach := state.duplicate(true)
	coach["stage"] = stage
	coach["step"] = stage
	if stage in [&"", &"normal", &"dismissed", &"off"]:
		coach["visible"] = false
	elif not coach.has("visible"):
		coach["visible"] = true
	apply_first_clutch(coach)


func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled
	if not enabled:
		_cancel_peck_result_focus_handoff("interaction_blocked")
		_cancel_claim_resolution_confirmation(false)
	_refresh()


## Mirrors Office's short-lived tray selection without owning the gameplay state.
func set_dispatch_state(
	lane: StringName,
	momentum_chain: int = 0,
	recommended_name: String = "",
	reward_label: String = "",
) -> void:
	_active_dispatch_lane = lane if lane in LANE_ORDER else &""
	_dispatch_momentum_chain = maxi(0, momentum_chain)
	if _dispatch_momentum_chain > 0 and _dispatch_break_remaining > 0.0:
		_finish_dispatch_break()
	if _dispatch_momentum_chain > 1 and _dispatch_recovery_remaining > 0.0:
		_finish_dispatch_recovery()
	_dispatch_recommended_name = recommended_name
	_dispatch_reward_label = reward_label
	_refresh()


func play_dispatch_reward(
	reward_id: StringName,
	chain: int,
	reward_receipt: Dictionary = {},
) -> void:
	if _dispatch_momentum_label == null or reward_id == &"":
		return
	if _dispatch_reward_tween != null and _dispatch_reward_tween.is_valid():
		_dispatch_reward_tween.kill()
	var reward_color := Color("e7c56e")
	match reward_id:
		&"peck_recharge":
			reward_color = Color("74d4c2")
		&"golden_file":
			reward_color = Color("ffd75e")
		&"team_lift":
			reward_color = Color("ef91a2")
		&"mastery_record":
			reward_color = Color("7dd4c4")
	_dispatch_momentum_label.modulate = reward_color
	var accessible_copy := String(reward_receipt.get("accessible_text", ""))
	if accessible_copy.is_empty():
		accessible_copy = "FIT x%d milestone earned: %s" % [chain, _dispatch_reward_label]
	_dispatch_momentum_label.tooltip_text = accessible_copy
	_dispatch_momentum_label.set_meta("accessible_text", accessible_copy)
	_dispatch_momentum_label.set_meta("reward_id", reward_id)
	_dispatch_momentum_label.set_meta("reward_chain", chain)
	if _reduced_motion:
		return
	_dispatch_reward_tween = create_tween().bind_node(_dispatch_momentum_label)
	_dispatch_reward_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_dispatch_reward_tween.tween_property(
		_dispatch_momentum_label,
		"modulate",
		Color.WHITE,
		0.16,
	)
	_dispatch_reward_tween.tween_property(
		_dispatch_momentum_label,
		"modulate",
		reward_color,
		0.12,
	)
	_dispatch_reward_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_dispatch_reward_tween.tween_property(
		_dispatch_momentum_label,
		"modulate",
		Color.WHITE,
		0.42,
	)


func routing_mastery_state() -> Dictionary:
	var accessible_text := ""
	if _routing_next_milestone > 0 and _dispatch_momentum_chain >= 10:
		accessible_text = (
			"Best-fit record %d. Rebuild the prior best at %d."
			% [_routing_best_chain, _routing_next_milestone]
			if _routing_mastery_target_kind == &"rebuild" else
			"Best-fit record %d. The next mastery record is %d."
			% [_routing_best_chain, _routing_next_milestone]
		)
	return {
		"active": _dispatch_momentum_chain >= 10,
		"chain": _dispatch_momentum_chain,
		"best_chain": _routing_best_chain,
		"next_milestone": _routing_next_milestone,
		"next_reward": _routing_next_reward,
		"target_kind": _routing_mastery_target_kind,
		"accessible_text": accessible_text,
	}


## Joins the authoritative x3 receipt to the existing Priority Peck control.
## The world burst remains the source beat; this meter is the destination, so
## the player sees exactly which reusable management resource was restored.
func play_priority_peck_recharge(reward: Dictionary, chain: int) -> bool:
	if (
		StringName(String(reward.get("id", ""))) != &"peck_recharge"
		or not bool(reward.get("refilled", false))
		or _peck_charge_meter == null
	):
		return false
	var charges_before := int(reward.get("charges_before", -1))
	var charges_after := int(reward.get("charges_after", -1))
	if charges_before < 0 or charges_after <= charges_before:
		return false
	var authority_key := String(reward.get("authority_key", ""))
	if authority_key.is_empty():
		authority_key = "%d:%d:%d" % [chain, charges_before, charges_after]
	if authority_key == _peck_recharge_authority_key:
		return false
	_peck_recharge_authority_key = authority_key
	_peck_recharge_before = charges_before
	_peck_recharge_after = charges_after
	_peck_recharge_serial += 1
	_peck_recharge_remaining = PECK_RECHARGE_DISPLAY_SECONDS
	_peck_recharge_capture_staged = false
	_peck_charge_meter.set_counts(
		charges_after,
		int(reward.get("limit_after", maxi(charges_after, 3))),
		bool(reward.get("banked", false)),
	)
	_peck_charge_meter.set_recharge_state(
		true,
		0.62 if _reduced_motion else 0.0,
		_reduced_motion,
		_peck_recharge_before,
		_peck_recharge_after,
		_peck_recharge_serial,
	)
	set_meta("peck_recharge_active", true)
	set_meta("peck_recharge_serial", _peck_recharge_serial)
	set_meta("peck_recharge_authority_key", _peck_recharge_authority_key)
	set_meta("peck_recharge_animated", not _reduced_motion)
	set_meta("peck_recharge_capture_staged", false)
	return true


func stage_priority_peck_recharge_capture() -> bool:
	if _peck_recharge_remaining <= 0.0 or _peck_charge_meter == null:
		return false
	_peck_recharge_capture_staged = true
	_peck_recharge_remaining = PECK_RECHARGE_DISPLAY_SECONDS * 0.46
	set_meta("peck_recharge_capture_staged", true)
	_peck_charge_meter.set_recharge_state(
		true,
		0.54,
		_reduced_motion,
		_peck_recharge_before,
		_peck_recharge_after,
		_peck_recharge_serial,
	)
	return true


func priority_peck_charge_state() -> Dictionary:
	return {
		"charges": int(_peck_charge_meter.get_meta("charges", 0)) if _peck_charge_meter != null else 0,
		"limit": int(_peck_charge_meter.get_meta("limit", 0)) if _peck_charge_meter != null else 0,
		"banked": bool(_peck_charge_meter.get_meta("banked", false)) if _peck_charge_meter != null else false,
		"recharge_active": _peck_recharge_remaining > 0.0,
		"recharge_before": _peck_recharge_before,
		"recharge_after": _peck_recharge_after,
		"recharge_serial": _peck_recharge_serial,
		"authority_key": _peck_recharge_authority_key,
		"animated": _peck_recharge_remaining > 0.0 and not _reduced_motion,
		"reduced_motion": _reduced_motion,
		"capture_staged": _peck_recharge_capture_staged,
		"shape": "filled_diamond_pips",
	}


func _process_priority_peck_recharge(delta: float) -> void:
	if _peck_recharge_remaining <= 0.0 or _peck_charge_meter == null:
		return
	if not _peck_recharge_capture_staged:
		_peck_recharge_remaining = maxf(0.0, _peck_recharge_remaining - delta)
	if _peck_recharge_remaining <= 0.0:
		_finish_priority_peck_recharge()
		return
	var phase := (
		0.62
		if _reduced_motion else
		1.0 - (_peck_recharge_remaining / PECK_RECHARGE_DISPLAY_SECONDS)
	)
	_peck_charge_meter.set_recharge_state(
		true,
		phase,
		_reduced_motion,
		_peck_recharge_before,
		_peck_recharge_after,
		_peck_recharge_serial,
	)


func _finish_priority_peck_recharge() -> void:
	_peck_recharge_remaining = 0.0
	_peck_recharge_capture_staged = false
	set_meta("peck_recharge_active", false)
	set_meta("peck_recharge_capture_staged", false)
	if _peck_charge_meter != null:
		_peck_charge_meter.set_recharge_state(
			false,
			1.0,
			_reduced_motion,
			_peck_recharge_before,
			_peck_recharge_after,
			_peck_recharge_serial,
		)


## Presents one authoritative skill-chain loss without another prose panel.
## The split-link glyph and xN > 0 receipt show what changed; NEXT FIT x1 and
## the tray pulse point to the exact recovery action. The detailed cause stays
## available through the queue tooltip and accessibility name.
func play_dispatch_break(receipt: Dictionary) -> bool:
	var broken_chain := int(receipt.get("broken_chain", 0))
	if _dispatch_momentum_label == null or broken_chain <= 0:
		return false
	if _dispatch_reward_tween != null and _dispatch_reward_tween.is_valid():
		_dispatch_reward_tween.kill()
	_dispatch_break_serial += 1
	_dispatch_break_chain = broken_chain
	_dispatch_break_reason = String(receipt.get("reason", "Routing flow ended."))
	_dispatch_break_source = StringName(String(receipt.get("source", "unknown")))
	_dispatch_break_remaining = DISPATCH_BREAK_DISPLAY_SECONDS
	_dispatch_break_capture_staged = false
	set_meta("dispatch_break_serial", _dispatch_break_serial)
	set_meta("dispatch_break_chain", _dispatch_break_chain)
	set_meta("dispatch_break_reason", _dispatch_break_reason)
	set_meta("dispatch_break_source", _dispatch_break_source)
	set_meta("dispatch_break_animated", not _reduced_motion)
	set_meta("dispatch_break_active", true)
	set_meta("dispatch_break_capture_staged", false)
	_apply_dispatch_break_presentation()
	return true


## Capture-only hold of the same live presentation. Runtime remains bounded.
func stage_dispatch_break_capture() -> bool:
	if _dispatch_break_remaining <= 0.0 or _dispatch_momentum_label == null:
		return false
	_dispatch_break_remaining = DISPATCH_BREAK_DISPLAY_SECONDS - 0.28
	_dispatch_break_capture_staged = true
	set_meta("dispatch_break_capture_staged", true)
	_apply_dispatch_break_presentation()
	return true


func _process_dispatch_break(delta: float) -> void:
	if _dispatch_break_remaining <= 0.0:
		return
	if not _dispatch_break_capture_staged:
		_dispatch_break_remaining = maxf(0.0, _dispatch_break_remaining - delta)
	if _dispatch_break_remaining <= 0.0:
		_finish_dispatch_break()
		_refresh()
		return
	_apply_dispatch_break_presentation()


func _apply_dispatch_break_presentation() -> void:
	if _dispatch_momentum_label == null or _dispatch_break_remaining <= 0.0:
		return
	var elapsed := DISPATCH_BREAK_DISPLAY_SECONDS - _dispatch_break_remaining
	var glyph_active := elapsed < DISPATCH_BREAK_GLYPH_SECONDS
	if _dispatch_momentum_break_glyph != null:
		_dispatch_momentum_break_glyph.set_break_state(
			glyph_active,
			clampf(elapsed / DISPATCH_BREAK_RETREAT_SECONDS, 0.0, 1.0),
			_reduced_motion,
		)
	_dispatch_momentum_label.text = (
		"x%d  >  0" % _dispatch_break_chain
		if elapsed < DISPATCH_BREAK_RECOVERY_SECONDS else
		"NEXT FIT  x1"
	)
	_dispatch_momentum_label.modulate = (
		Color("f2a07b") if elapsed < DISPATCH_BREAK_RECOVERY_SECONDS else Color("88cdbd")
	)
	var detail := "FIT x%d ended: %s Choose a tray, then the gold-star hen to restart at x1." % [
		_dispatch_break_chain,
		_dispatch_break_reason,
	]
	_dispatch_momentum_label.tooltip_text = detail
	_dispatch_momentum_label.accessibility_name = detail
	_set_dispatch_tray_break_modulate(elapsed)


func _set_dispatch_tray_break_modulate(elapsed: float) -> void:
	for lane: StringName in _queue_buttons:
		var tray := _queue_buttons.get(lane) as Button
		if tray == null or tray.disabled or _reduced_motion:
			if tray != null:
				tray.self_modulate = Color.WHITE
			continue
		if elapsed < 0.55:
			tray.self_modulate = Color(1.0, 0.82, 0.74, 1.0)
		elif elapsed < 1.85:
			var lift := (sin(elapsed * 8.4) + 1.0) * 0.5
			tray.self_modulate = Color(
				lerpf(0.88, 0.98, lift), 1.0, lerpf(0.93, 1.0, lift), 1.0
			)
		else:
			tray.self_modulate = Color.WHITE


func _finish_dispatch_break() -> void:
	_dispatch_break_remaining = 0.0
	_dispatch_break_capture_staged = false
	set_meta("dispatch_break_active", false)
	set_meta("dispatch_break_capture_staged", false)
	if _dispatch_momentum_break_glyph != null:
		_dispatch_momentum_break_glyph.set_break_state(false, 1.0, _reduced_motion)
	if _dispatch_momentum_label != null:
		_dispatch_momentum_label.modulate = Color.WHITE
		_dispatch_momentum_label.accessibility_name = ""
	for tray_value in _queue_buttons.values():
		var tray := tray_value as Button
		if tray != null:
			tray.self_modulate = Color.WHITE


## Closes the correction loop after the first authoritative best-fit dispatch
## following a break. It reuses the queue-strip link rather than adding a toast.
func play_dispatch_recovery(receipt: Dictionary) -> bool:
	var recovered_chain := int(receipt.get("recovered_chain", 0))
	var authority_serial := int(receipt.get("serial", 0))
	if _dispatch_momentum_label == null or recovered_chain != 1:
		return false
	if authority_serial > 0 and authority_serial <= _dispatch_recovery_authority_serial:
		return false
	if _dispatch_reward_tween != null and _dispatch_reward_tween.is_valid():
		_dispatch_reward_tween.kill()
	if _dispatch_break_remaining > 0.0:
		_finish_dispatch_break()
	_dispatch_recovery_serial += 1
	_dispatch_recovery_authority_serial = maxi(
		_dispatch_recovery_authority_serial,
		authority_serial,
	)
	_dispatch_recovery_worker_name = String(receipt.get("worker_name", "BEST-FIT HEN"))
	_dispatch_recovery_lane = StringName(String(receipt.get("lane", "")))
	_dispatch_recovery_break_serial = int(receipt.get("break_serial", 0))
	_dispatch_recovery_remaining = DISPATCH_RECOVERY_DISPLAY_SECONDS
	_dispatch_recovery_capture_staged = false
	set_meta("dispatch_recovery_serial", _dispatch_recovery_serial)
	set_meta("dispatch_recovery_authority_serial", _dispatch_recovery_authority_serial)
	set_meta("dispatch_recovery_break_serial", _dispatch_recovery_break_serial)
	set_meta("dispatch_recovery_worker_name", _dispatch_recovery_worker_name)
	set_meta("dispatch_recovery_lane", _dispatch_recovery_lane)
	set_meta("dispatch_recovery_animated", not _reduced_motion)
	set_meta("dispatch_recovery_active", true)
	set_meta("dispatch_recovery_capture_staged", false)
	_apply_dispatch_recovery_presentation()
	return true


## Capture-only hold of the live recovery join at its most legible phase.
func stage_dispatch_recovery_capture() -> bool:
	if _dispatch_recovery_remaining <= 0.0 or _dispatch_momentum_label == null:
		return false
	_dispatch_recovery_remaining = DISPATCH_RECOVERY_DISPLAY_SECONDS - 0.58
	_dispatch_recovery_capture_staged = true
	set_meta("dispatch_recovery_capture_staged", true)
	_apply_dispatch_recovery_presentation()
	return true


func _process_dispatch_recovery(delta: float) -> void:
	if _dispatch_recovery_remaining <= 0.0:
		return
	if not _dispatch_recovery_capture_staged:
		_dispatch_recovery_remaining = maxf(0.0, _dispatch_recovery_remaining - delta)
	if _dispatch_recovery_remaining <= 0.0:
		_finish_dispatch_recovery()
		_refresh()
		return
	_apply_dispatch_recovery_presentation()


func _apply_dispatch_recovery_presentation() -> void:
	if _dispatch_momentum_label == null or _dispatch_recovery_remaining <= 0.0:
		return
	var elapsed := DISPATCH_RECOVERY_DISPLAY_SECONDS - _dispatch_recovery_remaining
	var glyph_active := elapsed < DISPATCH_RECOVERY_GLYPH_SECONDS
	if _dispatch_momentum_break_glyph != null:
		_dispatch_momentum_break_glyph.set_recovery_state(
			glyph_active,
			clampf(elapsed / DISPATCH_RECOVERY_JOIN_SECONDS, 0.0, 1.0),
			_reduced_motion,
		)
	_dispatch_momentum_label.text = "FIT LINKED  x1"
	_dispatch_momentum_label.modulate = Color("74d4c2")
	var lane_label := String(_dispatch_recovery_lane).replace("_", " ").to_upper()
	var detail := "%s rebuilt routing flow at x1 with the best fit for %s." % [
		_dispatch_recovery_worker_name,
		lane_label if not lane_label.is_empty() else "the selected tray",
	]
	_dispatch_momentum_label.tooltip_text = detail
	_dispatch_momentum_label.accessibility_name = detail


func _finish_dispatch_recovery() -> void:
	_dispatch_recovery_remaining = 0.0
	_dispatch_recovery_capture_staged = false
	set_meta("dispatch_recovery_active", false)
	set_meta("dispatch_recovery_capture_staged", false)
	if _dispatch_momentum_break_glyph != null:
		_dispatch_momentum_break_glyph.set_recovery_state(false, 1.0, _reduced_motion)
	if _dispatch_momentum_label != null:
		_dispatch_momentum_label.modulate = Color.WHITE
		_dispatch_momentum_label.accessibility_name = ""


func set_peck_assist_clock_running(running: bool) -> void:
	_peck_assist_clock_running = running
	_refresh()


func set_peck_assist_binding_label(binding_label: String) -> void:
	_peck_assist_binding_label = binding_label if not binding_label.is_empty() else "E / A"
	_refresh()


func play_peck_assist_result(worker_id: int, rating: StringName) -> void:
	if worker_id != _focused_worker_id or _hen_intent_button == null:
		return
	_peck_result_link_rating = rating
	_peck_result_link_remaining = PECK_RESULT_LINK_DURATION
	_peck_missed_capture_staged = false
	set_meta("peck_missed_capture_staged", false)
	set_meta("peck_result_link_worker_id", worker_id)
	set_meta("peck_result_link_rating", rating)


## Runs the success connector backward as a broken line when the inspected
## window closes. The stable MISSED / NEXT FILE states remain available when
## motion is reduced, so this flourish is supplemental rather than required.
func play_peck_assist_missed(worker_id: int) -> bool:
	if worker_id != _focused_worker_id or _hen_intent_button == null:
		return false
	_peck_missed_link_serial += 1
	set_meta("peck_missed_link_worker_id", worker_id)
	set_meta("peck_missed_link_serial", _peck_missed_link_serial)
	set_meta("peck_missed_link_animated", not _reduced_motion)
	_peck_missed_capture_staged = false
	set_meta("peck_missed_capture_staged", false)
	if _reduced_motion:
		_peck_result_link_remaining = 0.0
		return false
	_peck_result_link_rating = &"missed"
	_peck_result_link_remaining = PECK_MISSED_LINK_DURATION
	return true


## Deterministic browser captures can hold the same authored broken connector at
## its midpoint. No live code path stages this state or changes the bounded beat.
func stage_peck_assist_missed_capture(worker_id: int) -> bool:
	if (
		worker_id != _focused_worker_id
		or _hen_intent_button == null
		or _claim_progress_track == null
	):
		return false
	_peck_result_link_rating = &"missed"
	_peck_result_link_remaining = PECK_MISSED_LINK_DURATION * 0.5
	_peck_missed_capture_staged = true
	set_meta("peck_missed_capture_staged", true)
	return true


func _result_link_progress() -> float:
	return clampf(
		1.0 - (_peck_result_link_remaining / PECK_RESULT_LINK_DURATION),
		0.0,
		1.0,
	)


func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if _claim_file_arrival_remaining > 0.0:
		set_meta("claim_file_arrival_animated", not _reduced_motion)
		_apply_claim_file_arrival_presentation()
	if _hen_dossier_arrival_remaining > 0.0:
		set_meta("hen_dossier_arrival_animated", not _reduced_motion)
		_apply_hen_dossier_arrival_presentation()
	if _dispatch_tray_arrival_remaining > 0.0:
		set_meta("dispatch_tray_arrival_animated", not _reduced_motion)
		_apply_dispatch_tray_arrival_presentation()
	if enabled:
		_peck_missed_capture_staged = false
		set_meta("peck_missed_capture_staged", false)
		_reset_hen_intent_transition()
	if _dispatch_break_remaining > 0.0:
		set_meta("dispatch_break_animated", not _reduced_motion)
		_apply_dispatch_break_presentation()
	if _dispatch_recovery_remaining > 0.0:
		set_meta("dispatch_recovery_animated", not _reduced_motion)
		_apply_dispatch_recovery_presentation()
	if _peck_recharge_remaining > 0.0 and _peck_charge_meter != null:
		set_meta("peck_recharge_animated", not _reduced_motion)
		_peck_charge_meter.set_recharge_state(
			true,
			0.62 if _reduced_motion else 1.0 - (_peck_recharge_remaining / PECK_RECHARGE_DISPLAY_SECONDS),
			_reduced_motion,
			_peck_recharge_before,
			_peck_recharge_after,
			_peck_recharge_serial,
		)


func set_color_vision_mode(mode: StringName) -> void:
	_color_vision_mode = SemanticColorPaletteScript.normalize_mode(mode)
	for lane in _assignment_buttons:
		var button := _assignment_buttons[lane] as Button
		if button != null:
			button.text = _lane_action_name(StringName(lane))
	if _queue_panel != null:
		_refresh()


func color_vision_mode() -> StringName:
	return _color_vision_mode


func focused_worker_id() -> int:
	return _focused_worker_id


## Returns the most urgent usable tray from live intake evidence. Deadline pressure
## leads, then overdue/rush/volume break exact ties; LANE_ORDER keeps the result
## stable when every gameplay signal is equal. This never mutates the snapshot.
func dispatch_priority_state() -> Dictionary:
	var routing: Dictionary = _snapshot.get("routing", {}) as Dictionary
	var queue_counts: Dictionary = routing.get(
		"queue_counts",
		_snapshot.get("claim_queue_counts", {}),
	) as Dictionary
	var overdue_counts: Dictionary = routing.get(
		"overdue_by_lane",
		_snapshot.get("claim_queue_overdue_counts", {}),
	) as Dictionary
	var queue_items: Dictionary = _snapshot.get("claim_queue_items", {}) as Dictionary
	var best: Dictionary = {}
	for lane: StringName in LANE_ORDER:
		var tray := _queue_buttons.get(lane) as Button
		var queue_count := int(queue_counts.get(lane, queue_counts.get(String(lane), 0)))
		if (
			tray == null
			or tray.disabled
			or not tray.is_visible_in_tree()
			or queue_count <= 0
		):
			continue
		var lane_items_value: Variant = queue_items.get(
			lane,
			queue_items.get(String(lane), []),
		)
		var lane_items: Array = lane_items_value as Array if lane_items_value is Array else []
		var earliest_deadline := 2_147_483_647
		var rush_count := 0
		for item_value in lane_items:
			if not item_value is Dictionary:
				continue
			var item := item_value as Dictionary
			earliest_deadline = mini(
				earliest_deadline,
				int(item.get("minutes_until_deadline", 2_147_483_647)),
			)
			if bool(item.get("market_contract_rush", false)):
				rush_count += 1
		var overdue_count := int(overdue_counts.get(
			lane,
			overdue_counts.get(String(lane), 0),
		))
		var candidate := {
			"available": true,
			"lane": String(lane),
			"lane_label": _lane_name(lane),
			"queue_count": queue_count,
			"overdue_count": overdue_count,
			"minutes_until_deadline": earliest_deadline,
			"rush_count": rush_count,
			"reason": (
				"overdue" if overdue_count > 0 or earliest_deadline < 0 else
				"nearest_deadline" if earliest_deadline < 2_147_483_647 else
				"queue_volume"
			),
		}
		if best.is_empty() or _dispatch_priority_precedes(candidate, best):
			best = candidate
	return best


func _dispatch_priority_precedes(candidate: Dictionary, current: Dictionary) -> bool:
	var candidate_deadline := int(candidate.get("minutes_until_deadline", 2_147_483_647))
	var current_deadline := int(current.get("minutes_until_deadline", 2_147_483_647))
	if candidate_deadline != current_deadline:
		return candidate_deadline < current_deadline
	var candidate_overdue := int(candidate.get("overdue_count", 0))
	var current_overdue := int(current.get("overdue_count", 0))
	if candidate_overdue != current_overdue:
		return candidate_overdue > current_overdue
	var candidate_rush := int(candidate.get("rush_count", 0))
	var current_rush := int(current.get("rush_count", 0))
	if candidate_rush != current_rush:
		return candidate_rush > current_rush
	return int(candidate.get("queue_count", 0)) > int(current.get("queue_count", 0))


## Moves keyboard focus to the most urgent usable intake tray without filing a
## route. Office pairs this with one restrained pulse for the one-shot re-entry
## handoff; gameplay authority remains in the normal tray and hen-selection flow.
func focus_priority_dispatch_tray() -> Control:
	_finish_dispatch_tray_arrival()
	_return_cue_focus_serial += 1
	var priority := dispatch_priority_state()
	if not priority.is_empty():
		var lane := StringName(String(priority.get("lane", "")))
		var tray := _queue_buttons.get(lane) as Button
		if tray != null:
			clear_dispatch_tray_focus_fallback()
			tray.grab_focus()
			_begin_dispatch_tray_arrival(lane, tray)
			_last_return_cue_focus = priority.duplicate(true)
			_last_return_cue_focus.merge({
				"serial": _return_cue_focus_serial,
				"fallback": false,
				"target": String(tray.name),
			}, true)
			return tray
	# A freshly restored clock can briefly have no filed intake. Keep the action
	# truthful by focusing the queue strip itself instead of enabling an empty tray.
	if _queue_panel != null and _queue_panel.is_visible_in_tree():
		_queue_panel.focus_mode = Control.FOCUS_ALL
		_queue_panel.accessibility_name = "Peckwork intake trays; no file is ready yet"
		_queue_panel.grab_focus()
		_begin_dispatch_tray_arrival(&"", _queue_panel, true)
		_last_return_cue_focus = {
			"serial": _return_cue_focus_serial,
			"available": false,
			"lane": "",
			"lane_label": "",
			"queue_count": 0,
			"overdue_count": 0,
			"minutes_until_deadline": 2_147_483_647,
			"rush_count": 0,
			"reason": "waiting_for_intake",
			"fallback": true,
			"target": String(_queue_panel.name),
		}
		return _queue_panel
	return null


## Acknowledges the exact urgent intake lane selected by an external handoff.
## The tray remains an ordinary semantic button: no dispatch mode or route is
## armed until the player deliberately activates it.
func _begin_dispatch_tray_arrival(
	lane: StringName,
	target: Control,
	fallback: bool = false,
) -> void:
	_finish_claim_file_arrival()
	_finish_hen_dossier_arrival()
	_dispatch_tray_arrival_lane = lane
	_dispatch_tray_arrival_target = target
	_dispatch_tray_arrival_remaining = DISPATCH_TRAY_ARRIVAL_DURATION
	_dispatch_tray_arrival_serial += 1
	_dispatch_tray_arrival_fallback = fallback
	_dispatch_tray_arrival_queue_title_text = (
		_queue_title_label.text if _queue_title_label != null else ""
	)
	set_meta("dispatch_tray_arrival_active", true)
	set_meta("dispatch_tray_arrival_animated", not _reduced_motion)
	set_meta("dispatch_tray_arrival_lane", String(lane))
	set_meta("dispatch_tray_arrival_fallback", fallback)
	set_meta("dispatch_tray_arrival_serial", _dispatch_tray_arrival_serial)
	_apply_dispatch_tray_arrival_presentation()


func _process_dispatch_tray_arrival(delta: float) -> void:
	if _dispatch_tray_arrival_remaining <= 0.0:
		return
	if (
		_dispatch_tray_arrival_target == null
		or not is_instance_valid(_dispatch_tray_arrival_target)
		or not _dispatch_tray_arrival_target.is_visible_in_tree()
	):
		_finish_dispatch_tray_arrival()
		return
	_dispatch_tray_arrival_remaining = maxf(
		0.0,
		_dispatch_tray_arrival_remaining - delta,
	)
	if _dispatch_tray_arrival_remaining <= 0.0:
		_finish_dispatch_tray_arrival()
		return
	_apply_dispatch_tray_arrival_presentation()


func _apply_dispatch_tray_arrival_presentation() -> void:
	if _dispatch_tray_arrival_target == null:
		return
	var progress := clampf(
		1.0 - (_dispatch_tray_arrival_remaining / DISPATCH_TRAY_ARRIVAL_DURATION),
		0.0,
		1.0,
	)
	var pulse := 0.55 if _reduced_motion else (sin(progress * TAU * 2.0) + 1.0) * 0.5
	var strength := (0.28 + pulse * 0.46) * (1.0 - progress * 0.4)
	var arrival_color := Color("9edfd3") if _dispatch_tray_arrival_fallback else Color("ffd66b")
	_dispatch_tray_arrival_target.modulate = Color.WHITE.lerp(arrival_color, strength)
	_dispatch_tray_arrival_target.pivot_offset = _dispatch_tray_arrival_target.size * 0.5
	_dispatch_tray_arrival_target.scale = (
		Vector2.ONE
		if _reduced_motion or _dispatch_tray_arrival_fallback else
		Vector2.ONE * (1.0 + pulse * 0.035 * (1.0 - progress))
	)
	if _queue_title_label != null:
		if _dispatch_tray_arrival_fallback:
			_queue_title_label.text = "INTAKE CLEAR  ·  WAITING"
		_queue_title_label.self_modulate = Color.WHITE.lerp(
			Color("c7f3ea") if _dispatch_tray_arrival_fallback else Color("fff0b5"),
			strength * 0.68,
		)


func _finish_dispatch_tray_arrival() -> void:
	var had_arrival := (
		_dispatch_tray_arrival_remaining > 0.0
		or _dispatch_tray_arrival_target != null
	)
	if _dispatch_tray_arrival_target != null and is_instance_valid(_dispatch_tray_arrival_target):
		_dispatch_tray_arrival_target.modulate = Color.WHITE
		_dispatch_tray_arrival_target.scale = Vector2.ONE
	_dispatch_tray_arrival_remaining = 0.0
	_dispatch_tray_arrival_lane = &""
	_dispatch_tray_arrival_target = null
	_dispatch_tray_arrival_fallback = false
	set_meta("dispatch_tray_arrival_active", false)
	set_meta("dispatch_tray_arrival_animated", false)
	set_meta("dispatch_tray_arrival_lane", "")
	set_meta("dispatch_tray_arrival_fallback", false)
	if _queue_title_label != null:
		if had_arrival:
			_queue_title_label.text = _dispatch_tray_arrival_queue_title_text
		_queue_title_label.self_modulate = Color.WHITE
	_dispatch_tray_arrival_queue_title_text = ""


func dispatch_tray_arrival_state() -> Dictionary:
	return {
		"active": _dispatch_tray_arrival_remaining > 0.0,
		"animated": _dispatch_tray_arrival_remaining > 0.0 and not _reduced_motion,
		"reduced_motion": _reduced_motion,
		"lane": String(_dispatch_tray_arrival_lane),
		"fallback": _dispatch_tray_arrival_fallback,
		"reason": (
			"waiting_for_intake"
			if _dispatch_tray_arrival_fallback else
			"urgent_file" if _dispatch_tray_arrival_remaining > 0.0 else ""
		),
		"serial": _dispatch_tray_arrival_serial,
		"target": (
			String(_dispatch_tray_arrival_target.name)
			if _dispatch_tray_arrival_target != null else
			""
		),
	}


func clear_dispatch_tray_arrival() -> void:
	_finish_dispatch_tray_arrival()
	clear_dispatch_tray_focus_fallback()


func return_cue_focus_state() -> Dictionary:
	return _last_return_cue_focus.duplicate(true)


func reset_return_cue_focus_state() -> void:
	clear_dispatch_tray_focus_fallback()
	_last_return_cue_focus.clear()


func clear_dispatch_tray_focus_fallback() -> void:
	if _queue_panel == null:
		return
	if _queue_panel.has_focus():
		_queue_panel.release_focus()
	_queue_panel.focus_mode = Control.FOCUS_NONE
	_queue_panel.accessibility_name = ""


func first_clutch_stage() -> StringName:
	return _first_clutch_disclosure_stage()


## Read-only presentation metadata for integration and accessibility tests.
## Section flags describe this component's intended disclosure even when Office
## temporarily hides the whole routing layer behind a blocking surface.
func first_clutch_presentation_state() -> Dictionary:
	var primary_action := ""
	var recommended_route := ""
	var demoted_current_route := ""
	if _first_clutch_cued_control != null and is_instance_valid(_first_clutch_cued_control):
		primary_action = _first_clutch_cued_control.name
	for lane in ASSIGNMENT_ORDER:
		var route_button := _assignment_buttons.get(lane) as Button
		if route_button == null:
			continue
		if bool(route_button.get_meta("first_clutch_recommended_route", false)):
			recommended_route = String(lane)
		if bool(route_button.get_meta("first_clutch_current_route_demoted", false)):
			demoted_current_route = String(lane)
	var dossier_summary_visible := (
		_dossier_summary_label != null and _dossier_summary_label.is_visible_in_tree()
	)
	return {
		"active": bool(_first_clutch.get("visible", false)),
		"stage": String(first_clutch_stage()),
		"target_worker_id": _first_clutch_target_worker_id(),
		"focused_worker_id": _focused_worker_id,
		"target_matches": _first_clutch_has_contextual_dossier(),
		"compact_coach": _first_clutch_compact,
		"details_expanded": _details_expanded,
		"active_dossier_tab": String(_active_dossier_tab),
		"dossier_tabs_visible": _dossier_tabs != null and _dossier_tabs.visible,
		"component_visible_in_tree": is_visible_in_tree(),
		"queue_visible": is_dossier_section_visible(&"queue"),
		"claim_visible": is_dossier_section_visible(&"claim"),
		"routing_visible": is_dossier_section_visible(&"routing"),
		"check_in_visible": is_dossier_section_visible(&"check_in"),
		"priority_peck_visible": is_dossier_section_visible(&"priority_peck"),
		"details_visible": _details_button != null and _details_button.visible,
		"primary_action_node": primary_action,
		"recommended_route": recommended_route,
		"demoted_current_route": demoted_current_route,
		"visual_title": _first_clutch_title_label.text if _first_clutch_title_label != null else "",
		"accessible_title": (
			String(_first_clutch_title_label.get_meta("accessible_text", ""))
			if _first_clutch_title_label != null else
			""
		),
		"visual_body": _first_clutch_body_label.text if _first_clutch_body_label != null else "",
		"accessible_body": (
			String(_first_clutch_body_label.get_meta("accessible_text", ""))
			if _first_clutch_body_label != null else
			""
		),
		"dossier_summary_copy": (
			_dossier_summary_label.text if dossier_summary_visible else ""
		),
		"dossier_summary_accessible_text": (
			String(_dossier_summary_label.get_meta("accessible_text", ""))
			if dossier_summary_visible else
			""
		),
		"dossier_summary_role": (
			String(_dossier_summary_label.get_meta("presentation_role", &"dossier_detail"))
			if dossier_summary_visible else
			"hidden"
		),
		"dossier_summary_visible": dossier_summary_visible,
		"return_action_label": (
			_first_clutch_return_button.text
			if _first_clutch_return_button != null and _first_clutch_return_button.visible else
			""
		),
		"progress_rail": (
			_first_clutch_progress_rail.presentation_state()
			if _first_clutch_progress_rail != null else {}
		),
	}


func routing_choices_accessible_text() -> String:
	if _focused_worker_id < 0 or _assignment_section == null or not _assignment_section.visible:
		return ""
	var choices: Array[String] = []
	var worker := _worker_snapshot(_focused_worker_id)
	var selected_lane := StringName(worker.get(
		"assignment",
		worker.get("assigned_lane", &"auto"),
	))
	for lane in ASSIGNMENT_ORDER:
		var button := _assignment_buttons.get(lane) as Button
		var state := "selected" if lane == selected_lane else (
			"unavailable" if button == null or button.disabled else "available"
		)
		choices.append("%s, %s: %s" % [
			String(LANE_NAMES.get(lane, String(lane).replace("_", " ").to_upper())),
			state,
			_assignment_tooltip(lane),
		])
	return "; ".join(choices)


func routing_choice_state() -> Dictionary:
	var choices: Array[Dictionary] = []
	var worker := _worker_snapshot(_focused_worker_id)
	var selected_lane := StringName(String(worker.get(
		"assignment",
		worker.get("assigned_lane", &"auto"),
	)))
	for lane in ASSIGNMENT_ORDER:
		var button := _assignment_buttons.get(lane) as Button
		if button == null:
			continue
		choices.append({
			"lane": String(lane),
			"label": button.text,
			"semantic_icon": String(button.get_meta("semantic_icon", "")),
			"icon_visible": button.icon != null and button.is_visible_in_tree(),
			"selected": lane == selected_lane,
			"specialty_match": bool(button.get_meta("specialty_match", false)),
			"accessible_text": button.accessibility_name,
		})
	return {
		"visible": _assignment_section != null and _assignment_section.is_visible_in_tree(),
		"selected_lane": String(selected_lane),
		"shape_language": "tray=auto; nest=damage; fox=predator; return-file=appeals",
		"choices": choices,
	}


func dossier_tab_state() -> Dictionary:
	var tabs: Array[Dictionary] = []
	for tab_id: StringName in [&"route", &"claim", &"support", &"profile"]:
		var button := _dossier_tab_buttons.get(tab_id) as Button
		if button == null:
			continue
		tabs.append({
			"id": String(tab_id),
			"label": button.text,
			"semantic_icon": String(button.get_meta("semantic_icon", "")),
			"icon_visible": button.icon != null and button.is_visible_in_tree(),
			"selected": button.button_pressed,
			"accessible_text": button.accessibility_name,
		})
	return {
		"visible": _dossier_tabs != null and _dossier_tabs.is_visible_in_tree(),
		"active_tab": String(_active_dossier_tab),
		"shape_language": "tray=route; document=file; flock-care=support; crest=profile",
		"tabs": tabs,
	}


func selected_hen_identity_state() -> Dictionary:
	return {
		"visible": (
			_worker_identity_row != null
			and _worker_identity_row.is_visible_in_tree()
		),
		"worker_id": _focused_worker_id,
		"visual_copy": _worker_trait_label.text if _worker_trait_label != null else "",
		"accessible_text": (
			_worker_trait_label.accessibility_name
			if _worker_trait_label != null else
			""
		),
		"profile_icon": (
			String(_worker_profile_icon.get_meta("semantic_icon", ""))
			if _worker_profile_icon != null else
			""
		),
		"profile_icon_visible": (
			_worker_profile_icon != null
			and _worker_profile_icon.texture != null
			and _worker_profile_icon.is_visible_in_tree()
		),
		"specialty_lane": (
			String(_worker_specialty_icon.get_meta("specialty_lane", ""))
			if _worker_specialty_icon != null else
			""
		),
		"specialty_icon": (
			String(_worker_specialty_icon.get_meta("semantic_icon", ""))
			if _worker_specialty_icon != null else
			""
		),
		"specialty_icon_visible": (
			_worker_specialty_icon != null
			and _worker_specialty_icon.texture != null
			and _worker_specialty_icon.is_visible_in_tree()
		),
		"shape_language": "crest=work profile; lane mark=primary specialty",
	}


## One compact read model keeps browser narration and regression fixtures aligned
## with the confirmation or reversible routing action currently visible.
func has_held_confirmation() -> bool:
	return (
		_claim_resolution_confirmation != null
		and _claim_resolution_confirmation.visible
	)


func interaction_safety_state() -> Dictionary:
	var assignment_undo := _snapshot.get("assignment_undo", {}) as Dictionary
	var confirmation_focus := (
		"confirm"
		if _claim_resolution_confirmation != null
		and _claim_resolution_confirmation.get_ok_button().has_focus() else
		"safe_return"
		if _claim_resolution_confirmation != null
		and _claim_resolution_confirmation.get_cancel_button().has_focus() else
		""
	)
	return {
		"claim_confirmation_visible": (
			_claim_resolution_confirmation != null
			and _claim_resolution_confirmation.visible
		),
		"claim_confirmation_worker_id": _pending_claim_resolution_worker_id,
		"claim_confirmation_claim_id": _pending_claim_resolution_claim_id,
		"claim_confirmation_path_id": String(_pending_claim_resolution_path),
		"claim_confirmation_title": (
			_claim_resolution_confirmation.title
			if _claim_resolution_confirmation != null else
			""
		),
		"claim_confirmation_confirm_label": (
			_claim_resolution_confirmation.get_ok_button().text
			if _claim_resolution_confirmation != null else
			""
		),
		"claim_confirmation_cancel_label": (
			_claim_resolution_confirmation.get_cancel_button().text
			if _claim_resolution_confirmation != null else
			""
		),
		"claim_confirmation_focus": confirmation_focus,
		"claim_confirmation_accessible_text": (
			String(_claim_resolution_confirmation.get_meta("accessible_text", ""))
			if _claim_resolution_confirmation != null else
			""
		),
		"claim_confirmation_skin": (
			String(_claim_resolution_confirmation.get_meta(
				"held_confirmation_skin",
				"",
			))
			if _claim_resolution_confirmation != null else
			""
		),
		"route_undo_visible": (
			_assignment_undo_button != null
			and _assignment_undo_button.is_visible_in_tree()
		),
		"route_undo_worker_id": int(assignment_undo.get("worker_id", -1)),
		"route_undo_previous_lane": String(assignment_undo.get("previous_lane", &"")),
		"route_undo_current_lane": String(assignment_undo.get("current_lane", &"")),
	}


func is_dossier_section_visible(section: StringName) -> bool:
	match section:
		&"queue":
			return _queue_panel != null and _queue_panel.visible
		&"claim", &"active_claim":
			return _claim_header != null and _claim_header.visible
		&"routing", &"assignments":
			return _assignment_section != null and _assignment_section.visible
		&"resolution", &"claim_resolution":
			return (
				_claim_resolution_section != null
				and _claim_resolution_section.visible
			)
		&"check_in", &"personnel":
			return _personnel_actions_section != null and _personnel_actions_section.visible
		&"priority_peck", &"peck_assist":
			return _peck_assist_button != null and _peck_assist_button.visible
		&"details":
			return _details_button != null and _details_button.visible
	return false


## Lets Office reclaim the duplicated objective row during guided onboarding
## without changing any routing content or action. Normal play restores 120px.
func set_top_inset(inset: float) -> void:
	var sanitized := maxf(0.0, inset)
	if is_equal_approx(_top_inset, sanitized):
		return
	_top_inset = sanitized
	_apply_first_clutch_layout()


## Use the same symbol-plus-count queue language at every interface scale so the
## always-visible strip stays glanceable. Exact lane names remain in each tray's
## tooltip and accessibility label rather than being repeated across the HUD.
func set_interface_scale(scale: float) -> void:
	_interface_scale = clampf(scale, 1.0, 1.5)
	_icon_led_queue_marks = true
	if _queue_title_label != null:
		_queue_title_label.text = "ROUTING"
	if _queue_heading != null:
		_queue_heading.custom_minimum_size.x = 104.0
	if _queue_row != null:
		_queue_row.add_theme_constant_override("separation", 7)
	var mark_size := Vector2.ONE * roundf(12.0 * _interface_scale)
	for lane: StringName in LANE_ORDER:
		var lane_icon := _queue_lane_icons.get(lane) as TextureRect
		if lane_icon != null:
			lane_icon.custom_minimum_size = mark_size
			lane_icon.visible = _icon_led_queue_marks
	if _queue_overdue_icon != null:
		_queue_overdue_icon.custom_minimum_size = mark_size
		_queue_overdue_icon.visible = _icon_led_queue_marks
	if _queue_panel != null:
		_queue_panel.set_meta("interface_scale", _interface_scale)
		_queue_panel.set_meta("compact_lane_marks", _icon_led_queue_marks)
		_refresh()
	_apply_first_clutch_layout()


func queue_strip_state() -> Dictionary:
	var lanes: Array[Dictionary] = []
	for lane: StringName in LANE_ORDER:
		var lane_icon := _queue_lane_icons.get(lane) as TextureRect
		var lane_label := _queue_labels.get(lane) as Label
		lanes.append({
			"lane": String(lane),
			"label": lane_label.text if lane_label != null else "",
			"semantic_icon": String(lane_icon.get_meta("semantic_icon", "")) if lane_icon != null else "",
			"icon_visible": lane_icon != null and lane_icon.is_visible_in_tree(),
			"accessible_text": (
				(_queue_buttons.get(lane) as Button).accessibility_name
				if _queue_buttons.has(lane) else
				""
			),
		})
	var strip_rect := _queue_panel.get_global_rect() if _queue_panel != null else Rect2()
	return {
		"visible": _queue_panel != null and _queue_panel.visible,
		"interface_scale": _interface_scale,
		"compact_lane_marks": _icon_led_queue_marks,
		"heading": _queue_title_label.text if _queue_title_label != null else "",
		"width": strip_rect.size.x,
		"overdue_label": String((_queue_labels.get(&"overdue") as Label).text) if _queue_labels.has(&"overdue") else "",
		"overdue_icon": String(_queue_overdue_icon.get_meta("semantic_icon", "")) if _queue_overdue_icon != null else "",
		"overdue_icon_visible": (
			_queue_overdue_icon != null
			and _queue_overdue_icon.is_visible_in_tree()
		),
		"overdue_state_shape": (
			String(_queue_overdue_icon.get_meta("state_shape", ""))
			if _queue_overdue_icon != null else
			""
		),
		"accessible_text": _queue_panel.tooltip_text if _queue_panel != null else "",
		"shape_language": "nest=repair; fox=predator; return-file=appeals; ring/diamond=overdue state",
		"lanes": lanes,
	}


func top_inset() -> float:
	return _top_inset


## Exposes only the two live routing surfaces transaction feedback must avoid.
## Keeping the geometry query here avoids coupling Office to private panel nodes.
func settlement_feedback_top_rect() -> Rect2:
	if _queue_panel == null or not _queue_panel.visible:
		return Rect2()
	return _queue_panel.get_global_rect()


func settlement_feedback_bottom_rect() -> Rect2:
	if _focus_panel == null or not _focus_panel.visible:
		return Rect2()
	return _focus_panel.get_global_rect()


## Gives transient settlement presentation the exact reusable-resource surface.
## Office may outline this control, but never owns or mutates its charge state.
func settlement_feedback_peck_target() -> Control:
	if _peck_charge_meter == null or not _peck_charge_meter.is_visible_in_tree():
		return null
	return _peck_charge_meter


func _build_queue_strip() -> void:
	_queue_panel = PanelContainer.new()
	_queue_panel.name = "PeckworkQueueStrip"
	_queue_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_queue_panel.offset_left = 18.0
	_queue_panel.offset_top = 120.0
	_queue_panel.offset_right = QUEUE_IDLE_RIGHT
	_queue_panel.offset_bottom = 158.0
	_queue_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_queue_panel.add_theme_stylebox_override("panel", _panel_style(Color("16242d"), 0.96, Color("52646d"), 7, 1))
	add_child(_queue_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	_queue_panel.add_child(margin)
	_queue_row = HBoxContainer.new()
	_queue_row.name = "RoutingQueueRow"
	_queue_row.add_theme_constant_override("separation", 7)
	margin.add_child(_queue_row)
	_queue_heading = VBoxContainer.new()
	_queue_heading.name = "RoutingQueueHeading"
	_queue_heading.custom_minimum_size.x = 104.0
	_queue_heading.add_theme_constant_override("separation", 0)
	_queue_row.add_child(_queue_heading)
	_queue_title_label = _make_label("ROUTING", 12, Color("e7c56e"))
	_queue_title_label.name = "RoutingQueueTitle"
	_queue_heading.add_child(_queue_title_label)
	_queue_contract_badge = _make_contract_badge("RoutingQueueContractBadge", 104.0)
	_queue_heading.add_child(_queue_contract_badge)
	_queue_compact_label = _make_label("FILES  0  /  OVERDUE  0", 12, Color("c7d3d7"))
	_queue_compact_label.name = "RoutingQueueCompactSummary"
	_queue_compact_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_queue_compact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_queue_compact_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_queue_compact_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_queue_compact_label.visible = false
	_queue_row.add_child(_queue_compact_label)
	for lane in LANE_ORDER:
		var tray_button := Button.new()
		tray_button.name = "DispatchTray_%s" % String(lane)
		tray_button.custom_minimum_size.x = 62.0
		tray_button.focus_mode = Control.FOCUS_ALL
		tray_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tray_button.theme_type_variation = &"DecisionChoiceButton"
		tray_button.tooltip_text = "Dispatch the next %s file. Then choose a hen; the gold star marks the best fit." % _lane_name(lane)
		tray_button.pressed.connect(_on_dispatch_tray_pressed.bind(lane))
		_queue_row.add_child(tray_button)
		_queue_buttons[lane] = tray_button
		var tray_line := HBoxContainer.new()
		tray_line.name = "QueueLine_%s" % String(lane)
		tray_line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tray_line.alignment = BoxContainer.ALIGNMENT_CENTER
		tray_line.add_theme_constant_override("separation", 2)
		tray_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tray_button.add_child(tray_line)
		var lane_icon := TextureRect.new()
		lane_icon.name = "QueueIcon_%s" % String(lane)
		lane_icon.custom_minimum_size = Vector2(14.0, 14.0)
		lane_icon.texture = ManagementUIThemeScript.action_icon(_lane_queue_icon(lane))
		lane_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lane_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lane_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lane_icon.visible = true
		lane_icon.set_meta("semantic_icon", String(_lane_queue_icon(lane)))
		tray_line.add_child(lane_icon)
		_queue_lane_icons[lane] = lane_icon
		var label := _make_label("0", 12, _lane_color(lane))
		label.name = "Queue_%s" % String(lane)
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tray_line.add_child(label)
		_queue_labels[lane] = label
	_queue_overdue_host = HBoxContainer.new()
	_queue_overdue_host.name = "QueueOverdueHost"
	_queue_overdue_host.custom_minimum_size.x = 66.0
	_queue_overdue_host.alignment = BoxContainer.ALIGNMENT_CENTER
	_queue_overdue_host.add_theme_constant_override("separation", 2)
	_queue_overdue_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_queue_row.add_child(_queue_overdue_host)
	_queue_overdue_icon = TextureRect.new()
	_queue_overdue_icon.name = "QueueOverdueStateIcon"
	_queue_overdue_icon.custom_minimum_size = Vector2(14.0, 14.0)
	_queue_overdue_icon.texture = ManagementUIThemeScript.action_icon(&"status_pass")
	_queue_overdue_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_queue_overdue_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_queue_overdue_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_queue_overdue_icon.visible = true
	_queue_overdue_icon.set_meta("semantic_icon", "status_pass")
	_queue_overdue_icon.set_meta("state_shape", "ring_check")
	_queue_overdue_host.add_child(_queue_overdue_icon)
	var debt := _make_label("0", 12, _lane_color(&"overdue"))
	debt.name = "QueueOverdue"
	debt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_queue_overdue_host.add_child(debt)
	_queue_labels[&"overdue"] = debt
	_dispatch_momentum_label = _make_label("", 11, Color("e7c56e"))
	_dispatch_momentum_label.name = "DispatchMomentum"
	_dispatch_momentum_label.custom_minimum_size.x = 132.0
	_dispatch_momentum_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dispatch_momentum_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_queue_row.add_child(_dispatch_momentum_label)
	_dispatch_momentum_break_glyph = RoutingMomentumBreakGlyph.new()
	_dispatch_momentum_break_glyph.name = "DispatchMomentumBreakGlyph"
	_dispatch_momentum_break_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dispatch_momentum_break_glyph.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_dispatch_momentum_break_glyph.offset_left = 0.0
	_dispatch_momentum_break_glyph.offset_right = 18.0
	_dispatch_momentum_break_glyph.offset_top = -9.0
	_dispatch_momentum_break_glyph.offset_bottom = 9.0
	_dispatch_momentum_break_glyph.visible = false
	_dispatch_momentum_label.add_child(_dispatch_momentum_break_glyph)


func _build_first_clutch_coach() -> void:
	_first_clutch_panel = PanelContainer.new()
	_first_clutch_panel.name = "FirstClutchCoach"
	_first_clutch_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_first_clutch_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_first_clutch_panel.z_index = 4
	_first_clutch_panel.visible = false
	_first_clutch_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("172832"), 0.985, Color("c7a352"), 8, 1),
	)
	add_child(_first_clutch_panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_first_clutch_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 9)
	margin.add_child(row)

	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	row.add_child(copy)

	var progress_row := HBoxContainer.new()
	progress_row.name = "FirstClutchProgressRow"
	progress_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_row.add_theme_constant_override("separation", 8)
	copy.add_child(progress_row)

	_first_clutch_progress_label = _make_label("FIRST CLUTCH", 10, Color("d8b967"))
	_first_clutch_progress_label.name = "FirstClutchProgress"
	_first_clutch_progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_row.add_child(_first_clutch_progress_label)

	_first_clutch_progress_rail = FirstClutchProgressRail.new()
	_first_clutch_progress_rail.name = "FirstClutchProgressRail"
	_first_clutch_progress_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_first_clutch_progress_rail.focus_mode = Control.FOCUS_NONE
	_first_clutch_progress_rail.set_progress(0, 5)
	progress_row.add_child(_first_clutch_progress_rail)

	_first_clutch_title_label = _make_label("INSPECT A HEN", 14, Color("f6e5b5"))
	_first_clutch_title_label.name = "FirstClutchActionTitle"
	_first_clutch_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_first_clutch_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(_first_clutch_title_label)

	_first_clutch_body_label = _make_label("Click a hen or press Tab to open her work file.", 11, Color("b8c7ce"))
	_first_clutch_body_label.name = "FirstClutchActionBody"
	_first_clutch_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_first_clutch_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_first_clutch_body_label.max_lines_visible = 2
	_first_clutch_body_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(_first_clutch_body_label)

	_first_clutch_return_button = Button.new()
	_first_clutch_return_button.name = "FirstClutchReturnToHen"
	_first_clutch_return_button.text = "RETURN TO HEN"
	_first_clutch_return_button.tooltip_text = "Return to the coached hen's work file."
	_first_clutch_return_button.custom_minimum_size = Vector2(108.0, 30.0)
	_first_clutch_return_button.add_theme_font_size_override("font_size", 10)
	_first_clutch_return_button.clip_text = true
	_first_clutch_return_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_first_clutch_return_button.visible = false
	_first_clutch_return_button.pressed.connect(_on_first_clutch_return_pressed)
	row.add_child(_first_clutch_return_button)

	_first_clutch_skip_button = Button.new()
	_first_clutch_skip_button.name = "FirstClutchSkip"
	_first_clutch_skip_button.text = "HIDE"
	_first_clutch_skip_button.tooltip_text = "Hide the optional coach. Reopen it from Settings without rewinding work."
	_first_clutch_skip_button.custom_minimum_size = Vector2(58.0, 30.0)
	_first_clutch_skip_button.add_theme_font_size_override("font_size", 10)
	_first_clutch_skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_first_clutch_skip_button.pressed.connect(_on_first_clutch_skip_pressed)
	row.add_child(_first_clutch_skip_button)


func _apply_first_clutch_layout() -> void:
	if _first_clutch_panel == null:
		return
	var viewport_width := get_viewport_rect().size.x
	_first_clutch_layout_width = viewport_width
	var available_width := minf(size.x, viewport_width) if size.x > 0.0 else viewport_width
	var narrow := available_width > 0.0 and available_width < 720.0
	if _queue_panel != null:
		_queue_panel.offset_left = 12.0 if narrow else 18.0
		_queue_panel.offset_top = _top_inset
		_queue_panel.offset_right = maxf(12.0, available_width - 12.0) if narrow else QUEUE_IDLE_RIGHT
		_queue_panel.offset_bottom = _top_inset + 38.0
		if _queue_compact_label != null:
			_queue_compact_label.visible = narrow
		for lane in LANE_ORDER:
			var tray_button := _queue_buttons.get(lane) as Button
			if tray_button != null:
				tray_button.visible = not narrow
		var overdue_label := _queue_labels.get(&"overdue") as Label
		if overdue_label != null:
			overdue_label.visible = not narrow
		_refresh_queue_momentum_layout()
	if narrow:
		_first_clutch_panel.set_anchor(SIDE_LEFT, 0.0)
		_first_clutch_panel.set_anchor(SIDE_RIGHT, 0.0)
		_first_clutch_panel.offset_left = 12.0
		_first_clutch_panel.offset_top = _top_inset + 52.0
		_first_clutch_panel.offset_right = maxf(12.0, available_width - 12.0)
		_first_clutch_panel.offset_bottom = (
			_top_inset + (110.0 if _first_clutch_compact else 156.0)
		)
	else:
		_first_clutch_panel.set_anchor(SIDE_LEFT, 0.0)
		_first_clutch_panel.set_anchor(SIDE_RIGHT, 0.0)
		_first_clutch_panel.offset_left = 18.0
		_first_clutch_panel.offset_top = _top_inset + 52.0
		_first_clutch_panel.offset_right = 598.0
		_first_clutch_panel.offset_bottom = (
			_top_inset + (110.0 if _first_clutch_compact else 130.0)
		)


func _refresh_queue_momentum_layout() -> void:
	if _queue_panel == null or _dispatch_momentum_label == null:
		return
	var viewport_width := get_viewport_rect().size.x
	var available_width := minf(size.x, viewport_width) if size.x > 0.0 else viewport_width
	var narrow := available_width > 0.0 and available_width < 720.0
	var momentum_active := not _dispatch_momentum_label.text.is_empty()
	_dispatch_momentum_label.visible = not narrow and momentum_active
	_queue_panel.offset_right = (
		maxf(12.0, available_width - 12.0)
		if narrow else
		QUEUE_MOMENTUM_RIGHT
		if momentum_active else
		QUEUE_IDLE_RIGHT
	)
	_queue_panel.set_meta("momentum_slot_active", momentum_active)
	_queue_panel.set_meta("compact_idle_extent", not narrow and not momentum_active)


func _build_focus_dossier() -> void:
	_focus_panel = PanelContainer.new()
	_focus_panel.name = "PeckworkAssignmentDossier"
	_focus_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_focus_panel.offset_left = 18.0
	_focus_panel.offset_top = -194.0
	_focus_panel.offset_right = -18.0
	_focus_panel.offset_bottom = -62.0
	_focus_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_focus_panel.add_theme_stylebox_override("panel", _panel_style(Color("172832"), 0.985, Color("bf9851"), 9, 2))
	add_child(_focus_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_focus_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)

	var identity := VBoxContainer.new()
	identity.custom_minimum_size.x = 281.0
	identity.add_theme_constant_override("separation", 2)
	row.add_child(identity)
	identity.add_child(_make_label("SELECTED HEN", 11, Color("d8b967")))
	var selected_row := HBoxContainer.new()
	selected_row.name = "SelectedHenActionRow"
	selected_row.add_theme_constant_override("separation", 6)
	identity.add_child(selected_row)
	_worker_name_label = _make_label("MABEL", 21, Color("f6e5b5"))
	_worker_name_label.name = "RoutingWorkerName"
	_worker_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selected_row.add_child(_worker_name_label)
	_hen_intent_button = Button.new()
	_hen_intent_button.name = "HenIntentAction"
	_hen_intent_button.text = "SET ROUTE  ›"
	_hen_intent_button.custom_minimum_size = Vector2(118.0, 25.0)
	_hen_intent_button.add_theme_font_size_override("font_size", 10)
	_hen_intent_button.add_theme_constant_override("icon_separation", 4)
	_hen_intent_button.theme_type_variation = &"DecisionChoiceButton"
	_hen_intent_button.clip_text = true
	_hen_intent_button.expand_icon = true
	_hen_intent_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hen_intent_button.pressed.connect(_on_hen_intent_pressed)
	selected_row.add_child(_hen_intent_button)
	_worker_career_label = _make_label("PECKWORK ASSOCIATE  /  XP 0", 11, Color("d7c17d"))
	_worker_career_label.name = "RoutingWorkerCareer"
	_worker_career_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	identity.add_child(_worker_career_label)
	_worker_identity_row = HBoxContainer.new()
	_worker_identity_row.name = "RoutingWorkerIdentityRow"
	_worker_identity_row.add_theme_constant_override("separation", 4)
	identity.add_child(_worker_identity_row)
	_worker_profile_icon = TextureRect.new()
	_worker_profile_icon.name = "RoutingWorkerProfileIcon"
	_worker_profile_icon.custom_minimum_size = Vector2(16.0, 16.0)
	_worker_profile_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_worker_profile_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_worker_profile_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_worker_profile_icon.texture = ManagementUIThemeScript.action_icon(&"rank_crest")
	_worker_profile_icon.set_meta("semantic_icon", &"rank_crest")
	_worker_identity_row.add_child(_worker_profile_icon)
	_worker_specialty_icon = TextureRect.new()
	_worker_specialty_icon.name = "RoutingWorkerSpecialtyIcon"
	_worker_specialty_icon.custom_minimum_size = Vector2(16.0, 16.0)
	_worker_specialty_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_worker_specialty_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_worker_specialty_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_worker_specialty_icon.texture = ManagementUIThemeScript.action_icon(&"lane_nest")
	_worker_specialty_icon.set_meta("semantic_icon", &"lane_nest")
	_worker_specialty_icon.set_meta("specialty_lane", &"nest_damage")
	_worker_identity_row.add_child(_worker_specialty_icon)
	_worker_trait_label = _make_label("SPECIALTY  /  NEST DAMAGE", 11, Color("aebdc5"))
	_worker_trait_label.name = "RoutingWorkerSpecialty"
	_worker_trait_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_worker_trait_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_worker_identity_row.add_child(_worker_trait_label)
	_dossier_tabs = HBoxContainer.new()
	_dossier_tabs.name = "RoutingDossierTabs"
	_dossier_tabs.add_theme_constant_override("separation", 3)
	identity.add_child(_dossier_tabs)
	var dossier_tab_icons: Dictionary[StringName, StringName] = {
		&"route": &"order_trays",
		&"claim": &"requisitions",
		&"support": &"receipt_flock",
		&"profile": &"rank_crest",
	}
	var dossier_tab_labels: Dictionary[StringName, String] = {
		&"route": "ROUTE",
		&"claim": "FILE",
		&"support": "CARE",
		&"profile": "BIO",
	}
	var dossier_tab_accessible_names: Dictionary[StringName, String] = {
		&"route": "Route tab",
		&"claim": "File tab",
		&"support": "Support and care tab",
		&"profile": "Hen profile tab",
	}
	for tab_id: StringName in [&"route", &"claim", &"support", &"profile"]:
		var tab := Button.new()
		tab.name = "DossierTab_%s" % String(tab_id)
		tab.text = dossier_tab_labels[tab_id]
		var semantic_icon := dossier_tab_icons[tab_id]
		tab.icon = ManagementUIThemeScript.action_icon(semantic_icon)
		tab.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		tab.expand_icon = true
		tab.set_meta("semantic_icon", semantic_icon)
		tab.toggle_mode = true
		tab.custom_minimum_size = Vector2(68.0, 30.0)
		tab.add_theme_font_size_override("font_size", 9)
		tab.add_theme_constant_override("icon_separation", 3)
		tab.tooltip_text = {
			&"route": "Current file, tray routing, and Priority Peck.",
			&"claim": "Claimant context and the exact settlement, denial, or exception tradeoff.",
			&"support": "Recognition, coaching, pressure, and check-in status.",
			&"profile": "Career, specialties, trust, grievance, and care details.",
		}[tab_id]
		tab.accessibility_name = "%s. %s" % [
			dossier_tab_accessible_names[tab_id],
			tab.tooltip_text,
		]
		tab.pressed.connect(_on_dossier_tab_pressed.bind(tab_id))
		_dossier_tabs.add_child(tab)
		_dossier_tab_buttons[tab_id] = tab
	_details_button = Button.new()
	_details_button.name = "RoutingDetailsToggle"
	_details_button.text = "DETAILS"
	_details_button.tooltip_text = "Show career, trust, grievance, and care details for this hen."
	_details_button.custom_minimum_size = Vector2(98.0, 24.0)
	_details_button.add_theme_font_size_override("font_size", 10)
	_details_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_details_button.pressed.connect(_on_details_pressed)
	identity.add_child(_details_button)

	var active_file := VBoxContainer.new()
	active_file.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	active_file.add_theme_constant_override("separation", 3)
	row.add_child(active_file)
	_claim_header = HBoxContainer.new()
	_claim_header.name = "RoutingClaimHeader"
	_claim_header.add_theme_constant_override("separation", 7)
	active_file.add_child(_claim_header)
	_current_claim_label = _make_label("WAITING FOR PECKWORK", 16, Color("eef2e9"))
	_current_claim_label.name = "RoutingCurrentClaim"
	_current_claim_label.custom_minimum_size.x = 210.0
	_current_claim_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_claim_header.add_child(_current_claim_label)
	_claim_phase_icon = TextureRect.new()
	_claim_phase_icon.name = "RoutingClaimPhaseIcon"
	_claim_phase_icon.custom_minimum_size = Vector2(22.0, 22.0)
	_claim_phase_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_claim_phase_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_claim_phase_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	_claim_phase_icon.focus_mode = Control.FOCUS_NONE
	_claim_phase_icon.visible = false
	_claim_header.add_child(_claim_phase_icon)
	_claim_phase_progress_label = _make_label("", 16, Color("e7c56e"))
	_claim_phase_progress_label.name = "RoutingClaimPhaseProgress"
	_claim_phase_progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_claim_phase_progress_label.visible = false
	_claim_header.add_child(_claim_phase_progress_label)
	var claim_header_spacer := Control.new()
	claim_header_spacer.name = "RoutingClaimHeaderSpacer"
	claim_header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	claim_header_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_claim_header.add_child(claim_header_spacer)
	_golden_file_badge = _make_label("* GOLD", 12, Color("ffd75e"))
	_golden_file_badge.name = "RoutingGoldenFileBadge"
	_golden_file_badge.visible = false
	_golden_file_badge.mouse_filter = Control.MOUSE_FILTER_STOP
	_claim_header.add_child(_golden_file_badge)
	_current_contract_badge = _make_contract_badge("RoutingCurrentContractBadge", 154.0)
	_claim_header.add_child(_current_contract_badge)
	_claim_context_row = HBoxContainer.new()
	_claim_context_row.name = "RoutingClaimContextRow"
	_claim_context_row.custom_minimum_size.y = 25.0
	_claim_context_row.add_theme_constant_override("separation", 18)
	_claim_context_row.mouse_filter = Control.MOUSE_FILTER_PASS
	active_file.add_child(_claim_context_row)
	_claim_detail_strip = HBoxContainer.new()
	_claim_detail_strip.name = "RoutingClaimDetail"
	_claim_detail_strip.custom_minimum_size.y = 20.0
	_claim_detail_strip.add_theme_constant_override("separation", 10)
	_claim_detail_strip.mouse_filter = Control.MOUSE_FILTER_STOP
	_claim_detail_strip.focus_mode = Control.FOCUS_NONE
	_claim_detail_strip.set_meta("shape_language", "clock=deadline; cash=payout; cracked egg=shell risk; egg or magnifier=next destination")
	_claim_context_row.add_child(_claim_detail_strip)
	for fact_index in 4:
		var fact := HBoxContainer.new()
		fact.name = "ClaimFact_%d" % fact_index
		fact.add_theme_constant_override("separation", 2)
		fact.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_claim_detail_strip.add_child(fact)
		var icon := FlockwatchIconBadgeScript.new()
		icon.name = "ClaimFactIcon_%d" % fact_index
		icon.set_badge_size(16.0)
		fact.add_child(icon)
		var value := _make_label("", 11, Color("b8c8cc"))
		value.name = "ClaimFactValue_%d" % fact_index
		value.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fact.add_child(value)
		_claim_detail_fact_groups.append(fact)
		_claim_detail_fact_icons.append(icon)
		_claim_detail_fact_values.append(value)
	_routing_lifecycle_rail = RoutingLifecycleRail.new()
	_routing_lifecycle_rail.name = "RoutingLifecycleRail"
	_routing_lifecycle_rail.custom_minimum_size = Vector2(178.0, 25.0)
	_routing_lifecycle_rail.mouse_filter = Control.MOUSE_FILTER_PASS
	_routing_lifecycle_rail.focus_mode = Control.FOCUS_NONE
	_routing_lifecycle_rail.set_stage(&"route")
	_routing_lifecycle_rail.visible = false
	_claim_context_row.add_child(_routing_lifecycle_rail)
	_claim_progress_track = Control.new()
	_claim_progress_track.name = "RoutingClaimProgressTrack"
	_claim_progress_track.custom_minimum_size.y = 16.0
	_claim_progress_track.clip_contents = true
	_claim_progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	active_file.add_child(_claim_progress_track)
	_claim_progress_bar = ProgressBar.new()
	_claim_progress_bar.name = "RoutingClaimProgress"
	_claim_progress_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_claim_progress_bar.min_value = 0.0
	_claim_progress_bar.max_value = 100.0
	_claim_progress_bar.show_percentage = false
	_claim_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_claim_progress_bar.add_theme_stylebox_override("background", _compact_button_style(Color("101a21"), Color("3e5059"), 1))
	_claim_progress_bar.add_theme_stylebox_override("fill", _compact_button_style(Color("5aa897"), Color("8dcfbd"), 0))
	_claim_progress_track.add_child(_claim_progress_bar)
	_peck_timing_band = ColorRect.new()
	_peck_timing_band.name = "PriorityPeckGoldBand"
	_peck_timing_band.color = Color(0.98, 0.76, 0.24, 0.52)
	_peck_timing_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_claim_progress_track.add_child(_peck_timing_band)
	_peck_timing_marker = ColorRect.new()
	_peck_timing_marker.name = "PriorityPeckIdealMarker"
	_peck_timing_marker.color = Color("fff0a6")
	_peck_timing_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_claim_progress_track.add_child(_peck_timing_marker)
	_peck_timing_label = _make_label("", 10, Color("d7c17d"))
	_peck_timing_label.name = "PriorityPeckTimingLabel"
	_peck_timing_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	active_file.add_child(_peck_timing_label)
	_dossier_summary_label = _make_label("", 11, Color("c7d3d7"))
	_dossier_summary_label.name = "RoutingDossierSummary"
	_dossier_summary_label.custom_minimum_size.y = 54.0
	_dossier_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dossier_summary_label.max_lines_visible = 4
	_dossier_summary_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	active_file.add_child(_dossier_summary_label)
	_assist_row = HBoxContainer.new()
	_assist_row.name = "RoutingAssistRow"
	_assist_row.add_theme_constant_override("separation", 9)
	active_file.add_child(_assist_row)
	_routing_hint_label = _make_label("Choose which tray this hen pulls next.", 11, Color("d7c17d"))
	_routing_hint_label.name = "RoutingAutomationHint"
	_routing_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_routing_hint_label.custom_minimum_size.y = 30.0
	_routing_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_routing_hint_label.max_lines_visible = 2
	_routing_hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_assist_row.add_child(_routing_hint_label)
	_assignment_undo_button = Button.new()
	_assignment_undo_button.name = "UndoRoutingAssignment"
	_assignment_undo_button.text = "UNDO ROUTE"
	_assignment_undo_button.custom_minimum_size = Vector2(126.0, 30.0)
	_assignment_undo_button.add_theme_font_size_override("font_size", 10)
	_assignment_undo_button.theme_type_variation = &"SecondaryButton"
	_assignment_undo_button.visible = false
	_assignment_undo_button.pressed.connect(_on_assignment_undo_pressed)
	_assist_row.add_child(_assignment_undo_button)
	_peck_assist_button = Button.new()
	_peck_assist_button.name = "PeckAssistButton"
	_peck_assist_button.text = "NO ACTIVE FILE"
	_peck_assist_button.custom_minimum_size = Vector2(166.0, 30.0)
	_peck_assist_button.add_theme_font_size_override("font_size", 11)
	_apply_peck_assist_style(_peck_assist_button)
	_peck_assist_button.pressed.connect(_on_peck_assist_pressed)
	_assist_row.add_child(_peck_assist_button)
	_peck_charge_meter = PriorityPeckChargeMeter.new()
	_peck_charge_meter.name = "PriorityPeckChargeMeter"
	_peck_charge_meter.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_peck_charge_meter.offset_left = -72.0
	_peck_charge_meter.offset_right = -2.0
	_peck_charge_meter.offset_top = 0.0
	_peck_charge_meter.offset_bottom = 0.0
	_peck_charge_meter.z_index = 5
	_peck_charge_meter.mouse_filter = Control.MOUSE_FILTER_PASS
	_peck_charge_meter.set_counts(3, 3, false)
	_claim_progress_track.add_child(_peck_charge_meter)
	_priority_peck_intent_link = PriorityPeckIntentLink.new()
	_priority_peck_intent_link.name = "PriorityPeckIntentLink"
	_priority_peck_intent_link.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_priority_peck_intent_link.z_index = 4
	_priority_peck_intent_link.configure(_hen_intent_button, _claim_progress_track)
	add_child(_priority_peck_intent_link)
	_personnel_status = HBoxContainer.new()
	_personnel_status.name = "RoutingPersonnelStatus"
	_personnel_status.add_theme_constant_override("separation", 13)
	active_file.add_child(_personnel_status)
	_trust_label = _make_label("TRUST  50", 11, Color("73b5a7"))
	_trust_label.name = "RoutingManagerTrust"
	_personnel_status.add_child(_trust_label)
	_grievance_label = _make_label("GRIEVANCE  0", 11, Color("d68a68"))
	_grievance_label.name = "RoutingGrievance"
	_personnel_status.add_child(_grievance_label)
	_check_in_status_label = _make_label("CHECK-IN READY", 11, Color("e7c56e"))
	_check_in_status_label.name = "RoutingCheckInStatus"
	_check_in_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_check_in_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_check_in_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_personnel_status.add_child(_check_in_status_label)

	_assignment_section = GridContainer.new()
	_assignment_section.name = "RoutingAssignments"
	_assignment_section.columns = 2
	_assignment_section.add_theme_constant_override("h_separation", 7)
	_assignment_section.add_theme_constant_override("v_separation", 7)
	row.add_child(_assignment_section)
	for assignment in ASSIGNMENT_ORDER:
		var button := Button.new()
		button.name = "Assign_%s" % String(assignment)
		button.set_meta("assignment_lane", assignment)
		var semantic_icon := _lane_queue_icon(assignment)
		button.set_meta("semantic_icon", semantic_icon)
		button.text = _lane_action_name(assignment)
		button.icon = ManagementUIThemeScript.action_icon(semantic_icon)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_constant_override("icon_separation", 5)
		button.custom_minimum_size = Vector2(142.0, 34.0)
		button.theme_type_variation = &"DecisionChoiceButton"
		button.tooltip_text = _assignment_tooltip(assignment)
		button.pressed.connect(_on_assignment_pressed.bind(assignment))
		_assignment_section.add_child(button)
		_assignment_buttons[assignment] = button

	_claim_resolution_section = VBoxContainer.new()
	_claim_resolution_section.name = "ClaimResolutionChoices"
	_claim_resolution_section.custom_minimum_size.x = 142.0
	_claim_resolution_section.add_theme_constant_override("separation", 4)
	row.add_child(_claim_resolution_section)
	for path_id: StringName in [&"settle", &"deny", &"exception"]:
		var button := Button.new()
		button.name = "ClaimResolution_%s" % String(path_id)
		button.text = String(path_id).to_upper()
		button.custom_minimum_size = Vector2(142.0, 26.0)
		button.add_theme_font_size_override("font_size", 10)
		button.theme_type_variation = &"DecisionChoiceButton"
		button.pressed.connect(_on_claim_resolution_pressed.bind(path_id))
		_claim_resolution_section.add_child(button)
		_claim_resolution_buttons[path_id] = button

	_personnel_actions_section = VBoxContainer.new()
	_personnel_actions_section.name = "PersonnelActions"
	_personnel_actions_section.custom_minimum_size.x = 142.0
	_personnel_actions_section.add_theme_constant_override("separation", 4)
	row.add_child(_personnel_actions_section)
	for action_id in PERSONNEL_ACTION_ORDER:
		var button := Button.new()
		button.name = "PersonnelAction_%s" % String(action_id)
		button.set_meta("personnel_action_id", action_id)
		button.text = String(PERSONNEL_ACTION_NAMES[action_id])
		button.custom_minimum_size = Vector2(142.0, 26.0)
		button.add_theme_font_size_override("font_size", 11)
		_apply_compact_personnel_style(button, action_id)
		button.tooltip_text = String(PERSONNEL_ACTION_TOOLTIPS[action_id])
		button.pressed.connect(_on_personnel_action_pressed.bind(action_id))
		_personnel_actions_section.add_child(button)
		_personnel_buttons[action_id] = button


func _build_claim_resolution_confirmation() -> void:
	_claim_resolution_confirmation = ConfirmationDialog.new()
	_claim_resolution_confirmation.name = "ClaimResolutionConfirmation"
	_claim_resolution_confirmation.title = "FILE AN IRREVERSIBLE CLAIMANT PATH?"
	_claim_resolution_confirmation.ok_button_text = "FILE PATH"
	_claim_resolution_confirmation.cancel_button_text = "KEEP CURRENT PATH"
	_claim_resolution_confirmation.min_size = Vector2i(340, 270)
	ManagementUIThemeScript.style_held_confirmation(_claim_resolution_confirmation)
	var copy := _claim_resolution_confirmation.get_label()
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	copy.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	copy.custom_minimum_size = Vector2(300.0, 152.0)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_claim_resolution_confirmation.get_ok_button().theme_type_variation = &"DangerButton"
	_claim_resolution_confirmation.get_cancel_button().theme_type_variation = &"PrimaryButton"
	_claim_resolution_confirmation.confirmed.connect(
		_confirm_claim_resolution
	)
	_claim_resolution_confirmation.canceled.connect(
		_cancel_claim_resolution_confirmation
	)
	add_child(_claim_resolution_confirmation)


func _on_dossier_tab_pressed(tab_id: StringName) -> void:
	if tab_id not in [&"route", &"claim", &"support", &"profile"]:
		return
	if tab_id != &"claim":
		_finish_claim_file_arrival()
	if tab_id != &"route":
		_finish_hen_dossier_arrival()
	_active_dossier_tab = tab_id
	_refresh()
	var first_focus: Control
	match tab_id:
		&"route":
			first_focus = _assignment_buttons.get(&"auto") as Control
		&"claim":
			first_focus = _claim_resolution_buttons.get(&"settle") as Control
		&"support":
			first_focus = _personnel_buttons.get(&"share_credit") as Control
		&"profile":
			first_focus = _dossier_tab_buttons.get(&"profile") as Control
	if first_focus != null and first_focus.is_visible_in_tree():
		first_focus.call_deferred("grab_focus")


func active_dossier_tab() -> StringName:
	return _active_dossier_tab


## Opens the File tab only when the requested receipt still names the exact
## claim held by the focused hen. A stale or completed receipt returns null and
## leaves the dossier at hen level; it never substitutes a newer file.
func focus_claim_file(claim_id: int) -> Control:
	if _focused_worker_id < 0 or claim_id < 0:
		_finish_claim_file_arrival()
		return null
	var worker := _worker_snapshot(_focused_worker_id)
	var current_claim := worker.get("current_claim", {}) as Dictionary
	if current_claim.is_empty() or int(current_claim.get("id", -1)) != claim_id:
		_finish_claim_file_arrival()
		return null
	var target := focus_intent_action(&"claim")
	if target == null:
		_finish_claim_file_arrival()
		return null
	_begin_claim_file_arrival(claim_id)
	return target


## Briefly acknowledges that an external receipt landed on this exact live File.
## The effect is presentation-only: it neither presses a claimant-path button nor
## changes the authoritative simulation snapshot.
func _begin_claim_file_arrival(claim_id: int) -> void:
	_finish_dispatch_tray_arrival()
	_finish_hen_dossier_arrival()
	_claim_file_arrival_claim_id = claim_id
	_claim_file_arrival_remaining = CLAIM_FILE_ARRIVAL_DURATION
	_claim_file_arrival_serial += 1
	set_meta("claim_file_arrival_active", true)
	set_meta("claim_file_arrival_animated", not _reduced_motion)
	set_meta("claim_file_arrival_claim_id", claim_id)
	set_meta("claim_file_arrival_serial", _claim_file_arrival_serial)
	_apply_claim_file_arrival_presentation()


func _process_claim_file_arrival(delta: float) -> void:
	if _claim_file_arrival_remaining <= 0.0:
		return
	_claim_file_arrival_remaining = maxf(0.0, _claim_file_arrival_remaining - delta)
	if _claim_file_arrival_remaining <= 0.0:
		_finish_claim_file_arrival()
		return
	_apply_claim_file_arrival_presentation()


func _apply_claim_file_arrival_presentation() -> void:
	var file_tab := _dossier_tab_buttons.get(&"claim") as Button
	if file_tab == null:
		return
	var progress := clampf(
		1.0 - (_claim_file_arrival_remaining / CLAIM_FILE_ARRIVAL_DURATION),
		0.0,
		1.0,
	)
	var pulse := 0.52 if _reduced_motion else (sin(progress * TAU * 2.0) + 1.0) * 0.5
	var strength := (0.26 + pulse * 0.42) * (1.0 - progress * 0.45)
	var file_tint := Color.WHITE.lerp(Color("ffd66b"), strength)
	file_tab.self_modulate = file_tint
	file_tab.pivot_offset = file_tab.size * 0.5
	file_tab.scale = (
		Vector2.ONE
		if _reduced_motion else
		Vector2.ONE * (1.0 + pulse * 0.035 * (1.0 - progress))
	)
	if _claim_header != null:
		_claim_header.self_modulate = Color.WHITE.lerp(Color("fff0b5"), strength * 0.72)


func _finish_claim_file_arrival() -> void:
	_claim_file_arrival_remaining = 0.0
	_claim_file_arrival_claim_id = -1
	set_meta("claim_file_arrival_active", false)
	set_meta("claim_file_arrival_animated", false)
	set_meta("claim_file_arrival_claim_id", -1)
	var file_tab := _dossier_tab_buttons.get(&"claim") as Button
	if file_tab != null:
		file_tab.self_modulate = Color.WHITE
		file_tab.scale = Vector2.ONE
	if _claim_header != null:
		_claim_header.self_modulate = Color.WHITE


func claim_file_arrival_state() -> Dictionary:
	return {
		"active": _claim_file_arrival_remaining > 0.0,
		"animated": _claim_file_arrival_remaining > 0.0 and not _reduced_motion,
		"reduced_motion": _reduced_motion,
		"claim_id": _claim_file_arrival_claim_id,
		"serial": _claim_file_arrival_serial,
		"active_tab": String(_active_dossier_tab),
		"target": "DossierTab_claim",
	}


## Restores a receipt to the focused hen's general dossier rather than leaving a
## previously opened File visible. This is presentation-only and never routes a
## file or presses a management action.
func focus_hen_dossier(worker_id: int) -> Control:
	if worker_id < 0:
		_finish_hen_dossier_arrival()
		return null
	if worker_id != _focused_worker_id:
		set_focus(worker_id)
	if _worker_snapshot(worker_id).is_empty():
		_finish_hen_dossier_arrival()
		return null
	_on_dossier_tab_pressed(&"route")
	_begin_hen_dossier_arrival(worker_id)
	return _dossier_tab_buttons.get(&"route") as Control


func _begin_hen_dossier_arrival(worker_id: int) -> void:
	_finish_dispatch_tray_arrival()
	_finish_claim_file_arrival()
	_hen_dossier_arrival_worker_id = worker_id
	_hen_dossier_arrival_remaining = HEN_DOSSIER_ARRIVAL_DURATION
	_hen_dossier_arrival_serial += 1
	set_meta("hen_dossier_arrival_active", true)
	set_meta("hen_dossier_arrival_animated", not _reduced_motion)
	set_meta("hen_dossier_arrival_worker_id", worker_id)
	set_meta("hen_dossier_arrival_serial", _hen_dossier_arrival_serial)
	_apply_hen_dossier_arrival_presentation()


func _process_hen_dossier_arrival(delta: float) -> void:
	if _hen_dossier_arrival_remaining <= 0.0:
		return
	_hen_dossier_arrival_remaining = maxf(0.0, _hen_dossier_arrival_remaining - delta)
	if _hen_dossier_arrival_remaining <= 0.0:
		_finish_hen_dossier_arrival()
		return
	_apply_hen_dossier_arrival_presentation()


func _apply_hen_dossier_arrival_presentation() -> void:
	if _worker_name_label == null:
		return
	var progress := clampf(
		1.0 - (_hen_dossier_arrival_remaining / HEN_DOSSIER_ARRIVAL_DURATION),
		0.0,
		1.0,
	)
	var pulse := 0.52 if _reduced_motion else (sin(progress * TAU * 2.0) + 1.0) * 0.5
	var strength := (0.24 + pulse * 0.40) * (1.0 - progress * 0.45)
	_worker_name_label.self_modulate = Color.WHITE.lerp(Color("ffd66b"), strength)
	_worker_name_label.pivot_offset = _worker_name_label.size * 0.5
	_worker_name_label.scale = (
		Vector2.ONE
		if _reduced_motion else
		Vector2.ONE * (1.0 + pulse * 0.03 * (1.0 - progress))
	)
	if _worker_trait_label != null:
		_worker_trait_label.self_modulate = Color.WHITE.lerp(
			Color("fff0b5"),
			strength * 0.68,
		)


func _finish_hen_dossier_arrival() -> void:
	_hen_dossier_arrival_remaining = 0.0
	_hen_dossier_arrival_worker_id = -1
	set_meta("hen_dossier_arrival_active", false)
	set_meta("hen_dossier_arrival_animated", false)
	set_meta("hen_dossier_arrival_worker_id", -1)
	if _worker_name_label != null:
		_worker_name_label.self_modulate = Color.WHITE
		_worker_name_label.scale = Vector2.ONE
	if _worker_trait_label != null:
		_worker_trait_label.self_modulate = Color.WHITE


func hen_dossier_arrival_state() -> Dictionary:
	return {
		"active": _hen_dossier_arrival_remaining > 0.0,
		"animated": _hen_dossier_arrival_remaining > 0.0 and not _reduced_motion,
		"reduced_motion": _reduced_motion,
		"worker_id": _hen_dossier_arrival_worker_id,
		"serial": _hen_dossier_arrival_serial,
		"active_tab": String(_active_dossier_tab),
		"target": "RoutingWorkerName",
	}


## Opens the existing management category that fulfills a hen's authoritative
## intent and places keyboard focus on its safest useful control. It never emits
## an economic action: the player still confirms Priority Peck, a claimant path,
## personnel support, or routing after inspecting the opened context.
func focus_intent_action(action_id: StringName) -> Control:
	if _focused_worker_id < 0 or action_id not in [&"peck", &"claim", &"support", &"profile", &"route"]:
		return null
	var tab_id := action_id
	if action_id == &"peck":
		tab_id = &"route"
	_on_dossier_tab_pressed(tab_id)
	var target: Control
	match action_id:
		&"peck":
			if _peck_assist_button != null and not _peck_assist_button.disabled:
				target = _peck_assist_button
		&"claim":
			for path_id: StringName in [&"settle", &"deny", &"exception"]:
				var path_button := _claim_resolution_buttons.get(path_id) as Button
				if path_button != null and path_button.visible and not path_button.disabled:
					target = path_button
					break
		&"support":
			var worker := _worker_snapshot(_focused_worker_id)
			var preferred_action := StringName(worker.get("preferred_personnel_action", &""))
			var preferred_button := _personnel_buttons.get(preferred_action) as Button
			if preferred_button != null and preferred_button.visible and not preferred_button.disabled:
				target = preferred_button
		&"profile":
			target = _dossier_tab_buttons.get(&"profile") as Control
		&"route":
			var route_worker := _worker_snapshot(_focused_worker_id)
			var assigned_lane := StringName(route_worker.get(
				"assigned_lane",
				route_worker.get("assignment", &"auto"),
			))
			target = _assignment_buttons.get(assigned_lane) as Control
	if target == null or not target.is_visible_in_tree() or (
		target is BaseButton and (target as BaseButton).disabled
	):
		target = _dossier_tab_buttons.get(tab_id) as Control
	_context_action_serial += 1
	_context_action_id = action_id
	_context_action_target_name = target.name if target != null else ""
	set_meta("context_action_serial", _context_action_serial)
	set_meta("context_action_id", action_id)
	set_meta("context_action_target", _context_action_target_name)
	if target != null and target.is_visible_in_tree() and target.focus_mode != Control.FOCUS_NONE:
		target.call_deferred("grab_focus")
	return target


func context_action_state() -> Dictionary:
	return {
		"serial": _context_action_serial,
		"action_id": String(_context_action_id),
		"target": _context_action_target_name,
		"active_tab": String(_active_dossier_tab),
		"focused_worker_id": _focused_worker_id,
	}


func _set_claim_detail_facts(facts: Array[Dictionary], accessible_text: String) -> void:
	if _claim_detail_strip == null:
		return
	var presented: Array[Dictionary] = []
	for fact_index in _claim_detail_fact_groups.size():
		var visible := fact_index < facts.size()
		_claim_detail_fact_groups[fact_index].visible = visible
		if not visible:
			continue
		var fact := facts[fact_index]
		var kind := StringName(String(fact.get("icon", "goal")))
		var value := String(fact.get("value", ""))
		var role := StringName(String(fact.get("role", "status")))
		var accent := fact.get("accent", Color("b8c8cc")) as Color
		_claim_detail_fact_icons[fact_index].call("configure", kind, accent)
		_claim_detail_fact_icons[fact_index].set_meta("semantic_icon", kind)
		_claim_detail_fact_values[fact_index].text = value
		_claim_detail_fact_values[fact_index].add_theme_color_override("font_color", accent.lightened(0.12))
		_claim_detail_fact_groups[fact_index].set_meta("presentation_role", role)
		presented.append({
			"role": String(role),
			"icon": String(kind),
			"value": value,
		})
	_claim_detail_strip.tooltip_text = accessible_text
	_claim_detail_strip.accessibility_name = accessible_text
	_claim_detail_strip.set_meta("accessible_text", accessible_text)
	_claim_detail_strip.set_meta("facts", presented)
	_claim_detail_strip.set_meta("fact_count", presented.size())


func _clear_claim_phase_header() -> void:
	_claim_phase_icon.visible = false
	_claim_phase_icon.texture = null
	_claim_phase_icon.tooltip_text = ""
	_claim_phase_icon.accessibility_name = ""
	_claim_phase_icon.set_meta("semantic_shape", &"")
	_claim_phase_icon.set_meta("phase", &"")
	_claim_phase_icon.set_meta("progress_bucket", -1)
	_claim_phase_progress_label.visible = false
	_claim_phase_progress_label.text = ""
	_claim_phase_progress_label.tooltip_text = ""
	_claim_phase_progress_label.accessibility_name = ""


## Reuses the selected hen's world-space work dial and egg receipt in the file
## header. The neighboring percentage carries the exact amount; full phase copy
## remains on the header tooltip and accessibility description.
func _set_claim_phase_header(
	phase: StringName,
	progress: int,
	accessible_text: String,
) -> void:
	var laying := phase == &"egg"
	var semantic_shape: StringName = &"egg_receipt" if laying else &"work_dial"
	var icon_kind: StringName = &"delivery" if laying else &"steady"
	var progress_bucket := (
		-1 if laying else clampi(ceili(float(progress) / 20.0), 0, 5)
	)
	_claim_phase_icon.texture = ChickenView.hen_intent_icon_texture(
		icon_kind,
		progress_bucket,
		2,
		semantic_shape,
	)
	_claim_phase_icon.visible = true
	_claim_phase_icon.tooltip_text = accessible_text
	_claim_phase_icon.accessibility_name = accessible_text
	_claim_phase_icon.set_meta("semantic_shape", semantic_shape)
	_claim_phase_icon.set_meta("phase", phase)
	_claim_phase_icon.set_meta("progress_bucket", progress_bucket)
	_claim_phase_progress_label.text = "%d%%" % clampi(progress, 0, 100)
	_claim_phase_progress_label.visible = true
	_claim_phase_progress_label.tooltip_text = accessible_text
	_claim_phase_progress_label.accessibility_name = accessible_text
	_claim_phase_progress_label.add_theme_color_override(
		"font_color",
		Color("8fc9b8") if laying else Color("e7c56e"),
	)


func _refresh() -> void:
	if _queue_panel == null or _focus_panel == null:
		return
	var routing: Dictionary = _snapshot.get("routing", {}) as Dictionary
	var queue_counts: Dictionary = routing.get("queue_counts", _snapshot.get("claim_queue_counts", {})) as Dictionary
	var overdue_counts: Dictionary = routing.get("overdue_by_lane", _snapshot.get("claim_queue_overdue_counts", {})) as Dictionary
	var queue_total := 0
	for lane in LANE_ORDER:
		var count := int(queue_counts.get(lane, queue_counts.get(String(lane), 0)))
		queue_total += count
		var lane_overdue := int(overdue_counts.get(lane, overdue_counts.get(String(lane), 0)))
		var suffix := "  !%d" % lane_overdue if lane_overdue > 0 else ""
		_queue_labels[lane].text = "%d%s" % [count, suffix]
		_queue_labels[lane].add_theme_color_override("font_color", _lane_color(lane))
		_queue_labels[lane].tooltip_text = "%s  //  %d WAITING  //  %d OVERDUE" % [
			_lane_name(lane), count, lane_overdue,
		]
		var tray_button := _queue_buttons.get(lane) as Button
		if tray_button != null:
			tray_button.disabled = not _interaction_enabled or int(_snapshot.get("shift_phase", 1)) != 1 or count <= 0
			tray_button.theme_type_variation = (
				&"SelectedChoiceButton" if lane == _active_dispatch_lane else &"DecisionChoiceButton"
			)
			tray_button.accessibility_name = "%s tray, %d waiting, %d overdue" % [
				_lane_name(lane), count, lane_overdue,
			]
			tray_button.tooltip_text = (
				"%s TRAY  //  %d WAITING  //  %d OVERDUE\n" % [
					_lane_name(lane), count, lane_overdue,
				]
				+ "Dispatch the next file, then choose a hen; the gold star marks the best fit."
			)
	var overdue := int(routing.get("overdue_total", _snapshot.get("overdue_claims", 0)))
	_queue_labels[&"overdue"].text = str(overdue)
	_queue_labels[&"overdue"].modulate = Color.WHITE if overdue > 0 else Color(1.0, 1.0, 1.0, 0.62)
	if _queue_overdue_host != null:
		_queue_overdue_host.tooltip_text = "%d FILES OVERDUE ACROSS ALL TRAYS" % overdue
		_queue_overdue_host.set_meta("accessible_text", _queue_overdue_host.tooltip_text)
	if _queue_overdue_icon != null:
		var overdue_icon_kind: StringName = &"status_need" if overdue > 0 else &"status_pass"
		_queue_overdue_icon.texture = ManagementUIThemeScript.action_icon(overdue_icon_kind)
		_queue_overdue_icon.set_meta("semantic_icon", String(overdue_icon_kind))
		_queue_overdue_icon.set_meta("state_shape", "diamond_exclamation" if overdue > 0 else "ring_check")
	_queue_compact_label.text = "FILES  %d  /  OVERDUE  %d" % [queue_total, overdue]
	_queue_compact_label.add_theme_color_override(
		"font_color",
		_lane_color(&"overdue") if overdue > 0 else Color("c7d3d7"),
	)
	if _dispatch_momentum_label != null:
		var mastery_state := routing_mastery_state()
		var mastery_active := bool(mastery_state.get("active", false))
		var mastery_target := int(mastery_state.get("next_milestone", 0))
		var mastery_progress := "%d / %d" % [_dispatch_momentum_chain, mastery_target]
		var immediate_mastery_reward := (
			_dispatch_reward_label.begins_with("RECORD")
			or _dispatch_reward_label.begins_with("ALL")
		)
		if _dispatch_recovery_remaining > 0.0:
			_apply_dispatch_recovery_presentation()
		elif _dispatch_break_remaining > 0.0:
			_apply_dispatch_break_presentation()
		elif _active_dispatch_lane != &"":
			_dispatch_momentum_label.text = (
				"PICK FIT %s" % mastery_progress
				if mastery_active and mastery_target > _dispatch_momentum_chain else
				"PICK · ×%d" % _dispatch_momentum_chain
				if _dispatch_momentum_chain >= 2 else
				"PICK"
			)
			var pick_tooltip := (
				"Choose a hen. Best fit: %s.%s" % [
					_dispatch_recommended_name,
					(" %s is ready." % _dispatch_reward_label) if not _dispatch_reward_label.is_empty() else "",
				]
				if not _dispatch_recommended_name.is_empty() else
				"Choose a hen. The gold star marks the best fit."
			)
			if mastery_active and mastery_target > _dispatch_momentum_chain:
				pick_tooltip += " Best-fit mastery: %d of %d. The streak has no timer." % [
					_dispatch_momentum_chain,
					mastery_target,
				]
			_dispatch_momentum_label.tooltip_text = pick_tooltip
			_dispatch_momentum_label.accessibility_name = pick_tooltip
			_dispatch_momentum_label.set_meta("accessible_text", pick_tooltip)
		elif _dispatch_momentum_chain >= 2:
			_dispatch_momentum_label.text = (
				"FIT ×%d  %s" % [_dispatch_momentum_chain, _dispatch_reward_label]
				if immediate_mastery_reward else
				"FIT %s" % mastery_progress
				if mastery_active and mastery_target > _dispatch_momentum_chain else
				"FIT ×%d  %s" % [_dispatch_momentum_chain, _dispatch_reward_label]
				if not _dispatch_reward_label.is_empty() else
				"FIT ×%d" % _dispatch_momentum_chain
			)
			_dispatch_momentum_label.tooltip_text = (
				String(mastery_state.get("accessible_text", ""))
				if mastery_active else
				"Best-fit flow has no timer. Poor routing or missed Peck precision breaks it."
			)
			_dispatch_momentum_label.set_meta(
				"accessible_text",
				_dispatch_momentum_label.tooltip_text,
			)
			_dispatch_momentum_label.accessibility_name = _dispatch_momentum_label.tooltip_text
			_dispatch_momentum_label.set_meta("mastery_target", mastery_target)
			_dispatch_momentum_label.set_meta(
				"mastery_target_kind",
				_routing_mastery_target_kind,
			)
		elif not _dispatch_reward_label.is_empty():
			_dispatch_momentum_label.text = _dispatch_reward_label
			_dispatch_momentum_label.tooltip_text = "Earned routing reward ready."
			_dispatch_momentum_label.accessibility_name = _dispatch_momentum_label.tooltip_text
			_dispatch_momentum_label.set_meta(
				"accessible_text",
				_dispatch_momentum_label.tooltip_text,
			)
		else:
			_dispatch_momentum_label.text = ""
			_dispatch_momentum_label.tooltip_text = ""
			_dispatch_momentum_label.accessibility_name = ""
	_refresh_queue_momentum_layout()
	_queue_panel.tooltip_text = (
		"PECKWORK ROUTING\nNest %d  /  Predator %d  /  Appeals %d  /  Overdue %d"
		% [
			int(queue_counts.get(&"nest_damage", queue_counts.get("nest_damage", 0))),
			int(queue_counts.get(&"predator_loss", queue_counts.get("predator_loss", 0))),
			int(queue_counts.get(&"appeals", queue_counts.get("appeals", 0))),
			overdue,
		]
	)
	if _dispatch_break_remaining > 0.0:
		_queue_panel.tooltip_text += "\nFIT x%d ended: %s\nRecovery: choose a tray, then the gold-star hen." % [
			_dispatch_break_chain,
			_dispatch_break_reason,
		]
	elif _dispatch_recovery_remaining > 0.0:
		_queue_panel.tooltip_text += "\nFIT LINKED x1: %s corrected the route with the best fit for %s." % [
			_dispatch_recovery_worker_name,
			String(_dispatch_recovery_lane).replace("_", " ").to_upper(),
		]
	_refresh_queue_contract_badge(routing)

	var worker := _worker_snapshot(_focused_worker_id)
	_focus_panel.visible = _focused_worker_id >= 0 and not worker.is_empty()
	if not _focus_panel.visible:
		_refresh_first_clutch()
		return

	var worker_name := String(worker.get("name", "HEN %d" % (_focused_worker_id + 1)))
	var specialty := StringName(worker.get("specialty", &"nest_damage"))
	var secondary_specialty := StringName(String(worker.get(
		"secondary_specialty",
		worker.get("secondary_lane", ""),
	)))
	var training_specialty := StringName(String(worker.get(
		"training_specialty",
		worker.get(
			"cross_training_target",
			worker.get("pending_training_lane", worker.get("training_lane", "")),
		),
	)))
	var assignment := StringName(worker.get("assignment", worker.get("assigned_lane", &"auto")))
	_worker_name_label.text = worker_name.to_upper()
	_refresh_worker_identity_marks(specialty)
	var career_title := String(worker.get("career_title", "PECKWORK ASSOCIATE"))
	var career_xp := maxi(0, int(worker.get("career_xp", 0)))
	var next_xp := int(worker.get("career_xp_next", worker.get("career_xp_to_next", 0)))
	var career_profile_name := String(worker.get("career_profile_name", "UNFILED PROFILE"))
	var career_profile_description := String(worker.get("career_profile_description", ""))
	var temperament_label := String(worker.get("temperament_label", "STEADY HEN"))
	var temperament_description := String(worker.get("temperament_description", ""))
	var flock_bond := worker.get("flock_bond", {}) as Dictionary
	var personal_mastery := worker.get("personal_mastery", {}) as Dictionary
	var temperament_effect := worker.get("temperament_effect", {}) as Dictionary
	var preferred_action := StringName(worker.get("preferred_personnel_action", &""))
	_worker_career_label.text = (
		"%s  /  XP %d / %d" % [career_title.to_upper(), career_xp, next_xp]
		if next_xp > career_xp else
		"%s  /  XP %d" % [career_title.to_upper(), career_xp]
	)
	var credential_text := _lane_name(specialty)
	if secondary_specialty != &"":
		credential_text += " + %s" % _lane_name(secondary_specialty)
	_worker_trait_label.text = "%s  /  %s" % [career_profile_name, credential_text]
	_worker_trait_label.tooltip_text = "%s Primary specialty: %s." % [career_profile_description, _lane_name(specialty)]
	_worker_trait_label.tooltip_text += "\nTEMPERAMENT / %s: %s" % [
		temperament_label,
		temperament_description if not temperament_description.is_empty() else "A stable individual work cadence is on file.",
	]
	if not temperament_effect.is_empty():
		_worker_trait_label.tooltip_text += "\nWORK STYLE / %s: %s" % [
			String(temperament_effect.get("label", "STEADY RHYTHM")),
			String(temperament_effect.get("summary", "steady baseline")),
		]
	if not flock_bond.is_empty():
		_worker_trait_label.tooltip_text += "\nFLOCK BOND / %s" % String(flock_bond.get(
			"summary",
			"No active perchmate relationship is filed.",
		))
	if not personal_mastery.is_empty():
		_worker_trait_label.tooltip_text += "\nMASTERY %d/%d / NEXT %s → %s" % [
			int(personal_mastery.get("completed", 0)),
			int(personal_mastery.get("total", 3)),
			String(personal_mastery.get("next_label", "MASTERED")),
			String(personal_mastery.get("next_reward", career_title)).to_upper(),
		]
	if secondary_specialty != &"":
		_worker_trait_label.tooltip_text += "\nSECONDARY ACCREDITATION: %s receives the same specialist speed and shell-risk treatment when routed manually." % _lane_name(secondary_specialty)
	if training_specialty != &"":
		var training_terms := _training_terms_snapshot()
		var work_multiplier := float(worker.get(
			"cross_training_work_multiplier",
			training_terms.get("effective_work_multiplier", training_terms.get("pending_work_multiplier", 0.85)),
		))
		var work_penalty := maxf(0.0, snappedf((1.0 - work_multiplier) * 100.0, 0.1))
		var coaching_xp_bonus := maxi(0, int(training_terms.get("coaching_xp_bonus", 0)))
		var wage_bonus_cents := maxi(0, int(training_terms.get("wage_bonus_cents", 100)))
		_worker_trait_label.text += "  /  TRAINING: %s" % _lane_name(training_specialty)
		_worker_trait_label.tooltip_text += (
			"\nIN TRAINING: this worked shift keeps full throughput. %s accreditation files after close with +$%.2f/day wage."
			if work_penalty <= 0.05 else
			"\nIN TRAINING: this worked shift is %s%% slower. %s accreditation files after close with +$%.2f/day wage."
		) % (
			[
				_lane_name(training_specialty),
				float(wage_bonus_cents) / 100.0,
			]
			if work_penalty <= 0.05 else
			[
				_compact_number(work_penalty),
				_lane_name(training_specialty),
				float(wage_bonus_cents) / 100.0,
			]
		)
		if coaching_xp_bonus > 0:
			_worker_trait_label.tooltip_text += " Training Roost coaching adds +%d career XP per check-in." % coaching_xp_bonus
	var worker_state_label := String(worker.get("state_label", "")).to_upper()
	if worker_state_label == "WELLNESS":
		_worker_trait_label.text += "  /  WELLNESS NEST"
	_worker_trait_label.tooltip_text += "\nFLOCK CARE: morale %d / stress %d / fatigue %d%s." % [
		roundi(float(worker.get("morale", 0.0))),
		roundi(float(worker.get("stress", 0.0))),
		roundi(float(worker.get("fatigue", 0.0))),
		" / resting at a recovery perch" if worker_state_label == "WELLNESS" else "",
	]
	_worker_trait_label.add_theme_color_override("font_color", _lane_color(specialty))
	if training_specialty != &"":
		_worker_trait_label.add_theme_color_override("font_color", Color("efcf83"))
	elif bool(worker.get("is_compact_sponsor", false)):
		_worker_trait_label.text += "  /  COMPACT SPONSOR"
		_worker_trait_label.tooltip_text += "\nBINDING FLOCK COMPACT: %s" % String(worker.get(
			"compact_condition",
			"The closing ledger determines whether management kept its promise.",
		))
		_worker_trait_label.add_theme_color_override("font_color", Color("efcf83"))
	elif bool(worker.get("is_petition_sponsor", false)):
		_worker_trait_label.text += "  /  PETITION SPONSOR"
		_worker_trait_label.tooltip_text += "\nThis hen signed the current flock petition."
		_worker_trait_label.add_theme_color_override("font_color", Color("df9278"))
	_worker_trait_label.accessibility_name = "%s. %s" % [
		_worker_trait_label.text,
		_worker_trait_label.tooltip_text,
	]
	_worker_trait_label.set_meta("accessible_text", _worker_trait_label.accessibility_name)
	_worker_trait_label.set_meta("presentation_role", &"worker_identity")
	var claim: Dictionary = worker.get("current_claim", {}) as Dictionary
	var golden_file_target := bool(claim.get("routing_golden_target", false))
	_golden_file_badge.visible = golden_file_target
	_claim_header.set_meta("routing_golden_target", golden_file_target)
	_claim_header.set_meta(
		"routing_golden_claim_id",
		int(claim.get("id", -1)) if golden_file_target else -1,
	)
	if golden_file_target:
		_golden_file_badge.tooltip_text = (
			"Golden File seal: file #%04d will grade golden if it arrives clean. "
			+ "A crack preserves the reward and moves the seal to the next active file."
		) % int(claim.get("id", 0))
		_golden_file_badge.set_meta("accessibility_label", "Golden File sealed on file %04d" % int(claim.get("id", 0)))
	_refresh_contract_badge(_current_contract_badge, claim)
	if claim.is_empty():
		_clear_claim_phase_header()
		if assignment == &"auto":
			_current_claim_label.text = "1  CHOOSE A ROUTE"
			_current_claim_label.accessibility_name = (
				"Step 1, choose a route for %s. No file is active. "
				+ "Auto sorting remains available and will favor specialty and deadline."
			) % worker_name
			_current_claim_label.set_meta("presentation_role", &"route_action")
		else:
			_current_claim_label.text = "1  %s  ·  WAITING" % _lane_name(assignment)
			_current_claim_label.accessibility_name = (
				"Step 1, route a file. %s is waiting for the next %s file."
				% [worker_name, _lane_name(assignment)]
			)
			_current_claim_label.set_meta("presentation_role", &"route_status")
		_current_claim_label.tooltip_text = _current_claim_label.accessibility_name
		_current_claim_label.set_meta("accessible_text", _current_claim_label.accessibility_name)
		_claim_progress_bar.value = 0.0
		_claim_progress_track.visible = false
		_routing_lifecycle_rail.set_stage(&"route")
	else:
		var lane := StringName(claim.get("lane", &"nest_damage"))
		var claim_id := int(claim.get("id", 0))
		var rework := bool(claim.get("rework", claim.get("is_rework", false)))
		var progress := int(worker.get("progress", 0))
		_claim_progress_track.visible = true
		_claim_progress_bar.value = progress
		var file_step := 2
		var file_state_accessible := "peckwork"
		var file_phase: StringName = &"peck"
		if worker_state_label == "LAYING":
			file_step = 3
			file_state_accessible = "egg laying"
			file_phase = &"egg"
		elif worker_state_label not in ["PECKING", "WORKING"]:
			file_state_accessible = worker_state_label.replace("_", " ").to_lower()
		_current_claim_label.text = "%s #%04d%s" % [
			_lane_name(lane), claim_id, ("  •  REWORK" if rework else ""),
		]
		_current_claim_label.accessibility_name = (
			"Step %d, %s. %s file #%04d is %d percent complete.%s"
			% [
				file_step,
				file_state_accessible,
				_lane_name(lane).to_lower(),
				claim_id,
				progress,
				" This file is rework." if rework else "",
			]
		)
		_current_claim_label.tooltip_text = _current_claim_label.accessibility_name
		_current_claim_label.set_meta("accessible_text", _current_claim_label.accessibility_name)
		_current_claim_label.set_meta("presentation_role", &"file_status")
		_set_claim_phase_header(
			file_phase,
			progress,
			_current_claim_label.accessibility_name,
		)
		var value_cents := int(claim.get("value_cents", 0))
		var remaining_minutes := int(claim.get("minutes_until_deadline", 0))
		var claim_overdue := bool(claim.get("overdue", false))
		var urgency := (
			"%dM OVERDUE" % absi(remaining_minutes)
			if claim_overdue else
			"%dM LEFT" % maxi(0, remaining_minutes)
		)
		var urgency_accessible := (
			"Overdue by %d minutes" % absi(remaining_minutes)
			if claim_overdue else
			"Due in %d minutes" % maxi(0, remaining_minutes)
		)
		var crack_risk := int(float(worker.get("estimated_crack_risk", 0.0)) * 100.0)
		var shell_risk_color := SemanticColorPaletteScript.quality_color(
			&"cracked",
			_color_vision_mode,
		)
		var claim_facts: Array[Dictionary] = []
		if worker_state_label == "LAYING":
			claim_facts = [
				{"role": &"payout", "icon": &"cash", "value": "$%.2f" % (value_cents / 100.0), "accent": Color("73b5a7")},
				{"role": &"shell_risk", "icon": &"shell_risk", "value": "%d%%" % crack_risk, "accent": shell_risk_color},
				{"role": &"next_destination", "icon": &"grading", "value": "GRADING", "accent": Color("8fc9b8")},
			]
			var laying_facts_accessible := (
				"Payout $%.2f. Estimated shell crack risk %d percent. Next, grading, then the farmer basket."
				% [value_cents / 100.0, crack_risk]
			)
			_set_claim_detail_facts(claim_facts, laying_facts_accessible)
		else:
			claim_facts = [
				{
					"role": &"deadline",
					"icon": &"clock",
					"value": "%dM OVER" % absi(remaining_minutes) if claim_overdue else "%dM" % maxi(0, remaining_minutes),
					"accent": Color("df826f") if claim_overdue else Color("d7c17d"),
				},
				{"role": &"payout", "icon": &"cash", "value": "$%.2f" % (value_cents / 100.0), "accent": Color("73b5a7")},
				{"role": &"shell_risk", "icon": &"shell_risk", "value": "%d%%" % crack_risk, "accent": shell_risk_color},
				{"role": &"next_destination", "icon": &"egg", "value": "EGG", "accent": Color("d8b967")},
			]
			var working_facts_accessible := (
				"%s. File value $%.2f. Estimated shell crack risk %d percent. Next, finish the work and lay the egg."
				% [urgency_accessible, value_cents / 100.0, crack_risk]
			)
			_set_claim_detail_facts(claim_facts, working_facts_accessible)
	_refresh_claim_resolution_controls(worker, claim)
	var assist := worker.get("peck_assist", {}) as Dictionary
	var assist_available := bool(assist.get("available", false)) and _interaction_enabled
	var resume_required := assist_available and not _peck_assist_clock_running
	var assist_live := assist_available and _peck_assist_clock_running
	var assist_state := StringName(assist.get("window_state", &"locked"))
	var last_assist := _snapshot.get("last_peck_assist", {}) as Dictionary
	var last_assist_matches_claim := (
		int(last_assist.get("claim_id", -1)) == int(claim.get("id", -2))
	)
	# The same authoritative claim remains in the worker's hands during LAYING,
	# even though peck_assist_status correctly changes to WAITING. Preserve the
	# landed receipt through that visible result beat instead of reverting the
	# dossier to a generic locked label before the flourish can be read.
	if last_assist_matches_claim and assist_state in [&"waiting", &"used"]:
		assist_state = &"used"
	var assist_remaining := maxi(0, int(assist.get("remaining", _snapshot.get("peck_assists_remaining", 0))))
	var assist_pending := maxi(0, int(assist.get(
		"pending_delivery_count",
		_snapshot.get("peck_assist_pending_delivery_count", 0),
	)))
	var assist_receipt_text := ""
	var assist_receipt_tooltip := ""
	var assist_receipt_active := false
	_refresh_peck_timing_presentation(assist, assist_state, claim.is_empty())
	# Pausing is an inspection tool, not a dead end. Keep an authoritative open
	# window actionable and make its one deliberate consequence explicit: the
	# confirmation resumes at 1x and stamps the focused file. Selection/focus still
	# never emits the action by itself.
	_peck_assist_button.set_meta("assist_open", assist_available)
	_peck_assist_button.set_meta("assist_live", assist_live)
	_peck_assist_button.set_meta("resume_required", resume_required)
	_peck_assist_button.disabled = not assist_available
	_peck_assist_button.add_theme_color_override("font_disabled_color", Color("73808a"))
	_peck_assist_button.tooltip_text = "%s\n%s" % [
		(
			"Resume at 1x and stamp this exact file. Nothing happens until you confirm."
			if resume_required else
			String(assist.get("reason", "Select a working hen to synchronize peckwork."))
		),
		"A strong stamp accelerates this file and lowers shell risk; every stamp adds strain. A sound or golden assisted egg restores one charge when the farmer receives it; a crack consumes the charge and breaks the chain. %d/%d attention charges remain." % [
			assist_remaining, int(assist.get("limit", _snapshot.get("peck_assist_limit", 3))),
		],
	]
	# The contextual shortcut must mirror the authoritative Priority Peck lock.
	# Refresh it only after the underlying button has resolved clock/window state.
	_refresh_hen_intent(worker)
	match assist_state:
		&"open":
			var timing_label := String(assist.get("timing_label", "CLEAN RHYTHM"))
			_peck_assist_button.text = "%s  [%s]" % [
				(
					"RESUME + PECK"
					if resume_required else
					("GOLDEN PECK" if "GOLDEN" in timing_label else "PECK NOW")
				),
				_peck_assist_binding_label,
			]
			_claim_progress_bar.add_theme_stylebox_override("fill", _compact_button_style(Color("d5aa4f"), Color("f1d681"), 0))
		&"not_ready":
			# Keep the action target stable while the timing label and meter explain
			# readiness. This lets players learn one button position instead of
			# parsing a second status sentence that later turns into the action.
			_peck_assist_button.text = "PECK  [%s]" % _peck_assist_binding_label
			_claim_progress_bar.add_theme_stylebox_override("fill", _compact_button_style(Color("4d8d83"), Color("75b6a9"), 0))
		&"used":
			if last_assist_matches_claim:
				assist_receipt_active = true
				var rating := String(last_assist.get("rating", "steady")).to_upper()
				var progress_gain := int(roundf(float(last_assist.get("progress_gain", 0.0))))
				var risk_points := float(last_assist.get("quality_modifier", 0.0)) * 100.0
				var risk_text := "%s%.1f%%" % [("+" if risk_points > 0.0 else ""), risk_points]
				_peck_assist_button.text = (
					"%s!  ·  FILE READY" % rating
					if worker_state_label == "LAYING" else
					"%s!  ·  CHAIN x%d" % [rating, int(last_assist.get("streak", 0))]
				)
				_peck_assist_button.add_theme_color_override("font_disabled_color", Color("c9e5b9"))
				assist_receipt_text = (
					"" if worker_state_label == "LAYING" else
					"FILE +%d%%  ·  RISK %s  ·  CLEAN EGG REFUNDS 1" % [progress_gain, risk_text]
				)
				assist_receipt_tooltip = "%s Priority Peck landed on this exact file: +%d%% progress, shell risk %s, chain x%d. A sound or golden delivery restores its attention charge." % [
					rating.capitalize(),
					progress_gain,
					risk_text,
					int(last_assist.get("streak", 0)),
				]
				_peck_assist_button.tooltip_text = assist_receipt_tooltip
			else:
				_peck_assist_button.text = "PRIORITY FILED  ·  x%d" % int(assist.get("streak", 0))
			_claim_progress_bar.add_theme_stylebox_override("fill", _compact_button_style(Color("769e75"), Color("a8c894"), 0))
		&"missed", &"passed":
			_peck_assist_button.text = "MISSED"
			_claim_progress_bar.add_theme_stylebox_override("fill", _compact_button_style(Color("89645c"), Color("b57d6d"), 0))
		&"spent":
			_peck_assist_button.text = (
				"AWAIT CLEAN DELIVERY"
				if assist_pending > 0 else
				"ATTENTION SPENT"
			)
		_:
			_peck_assist_button.text = "NO ACTIVE FILE" if claim.is_empty() else "PECK SUPPORT LOCKED"
	var lifecycle_stage := (
		&"route" if claim.is_empty() else
		&"egg" if worker_state_label == "LAYING" else
		&"peck"
	)
	var lifecycle_replaces_hint := (
		lifecycle_stage == &"egg" and assist_receipt_active
	)
	_routing_lifecycle_rail.set_stage(lifecycle_stage, lifecycle_replaces_hint)
	_routing_hint_label.set_meta("lifecycle_replaces_hint", lifecycle_replaces_hint)
	_peck_assist_button.accessibility_name = (
		"Resume at normal speed and Priority Peck this file"
		if resume_required else
		"Priority Peck unavailable; wait for the file meter to reach the gold band"
		if assist_state == &"not_ready" else
		_peck_assist_button.text
	)
	_peck_assist_button.set_meta("accessible_text", _peck_assist_button.accessibility_name)
	if golden_file_target:
		# The milestone seal owns the file's primary outcome color through LAYING;
		# Priority Peck remains legible through its separate button and timing band.
		_claim_progress_bar.add_theme_stylebox_override("fill", _compact_button_style(Color("c49a32"), Color("ffe08a"), 0))
	var assignment_is_credentialed := (
		assignment == &"auto"
		or assignment == specialty
		or (secondary_specialty != &"" and assignment == secondary_specialty)
	)
	_routing_hint_label.add_theme_color_override("font_color", Color("d7c17d"))
	var employed := bool(worker.get("employed", true))
	var operations := _operations_snapshot()
	var automation := operations.get("automation", {}) as Dictionary
	var it_level := maxi(0, int(operations.get("it_coop_level", 0)))
	var automation_enabled := bool(automation.get("enabled", false)) and it_level > 0
	var auto_work_basis_points := maxi(10_000, int(automation.get("work_basis_points", 10_000)))
	var auto_work_percent := float(auto_work_basis_points - 10_000) / 100.0
	var auto_grace := maxi(0, int(automation.get("specialty_grace_minutes", 180)))
	var auto_secondary := bool(automation.get("recognizes_secondary_specialties", false))
	if not employed:
		_routing_hint_label.text = "APPLICANT FILE / NO LIVE AUTO SUPPORT"
		_routing_hint_label.tooltip_text = "Only employed hens can receive live tray routing or IT Coop AUTO support."
	elif assignment == &"auto":
		_routing_hint_label.text = (
			"IT AUTO L%d / +%s%% PACE / %dM GRACE"
			% [it_level, _compact_number(auto_work_percent), auto_grace]
			if automation_enabled else
			"LOCAL AUTO / BASE PACE / %dM GRACE" % auto_grace
		)
		_routing_hint_label.tooltip_text = (
			"AUTO is opt-in for this employed hen. IT Coop support improves only AUTO-routed work; it never completes a file or lays an egg. "
			+ ("Secondary accreditation is recognized by dispatch." if auto_secondary else "Dispatch recognizes the primary specialty only.")
		)
	else:
		_routing_hint_label.text = (
			"FIT ROUTE  •  NO AUTO BONUS"
			if assignment_is_credentialed else
			"OFF-FIT ROUTE  •  NO AUTO BONUS"
		)
		_routing_hint_label.tooltip_text = (
			"This manual %s tray is an explicit override, so IT Coop AUTO pace and grace do not apply. %s"
			% [
				_lane_name(assignment),
				"The route matches a filed specialty." if assignment_is_credentialed else "The route is out of specialty and raises time and shell risk.",
			]
		)
	if assist_pending > 0:
		_routing_hint_label.text = "%d CLEAN %s EN ROUTE / %s" % [
			assist_pending,
			("EGG" if assist_pending == 1 else "EGGS"),
			_routing_hint_label.text,
		]
	if lifecycle_replaces_hint:
		_routing_hint_label.text = ""
		_routing_hint_label.tooltip_text = assist_receipt_tooltip
		_routing_hint_label.add_theme_color_override("font_color", Color("a8c894"))
	elif not assist_receipt_text.is_empty():
		_routing_hint_label.text = assist_receipt_text
		_routing_hint_label.tooltip_text = assist_receipt_tooltip
		_routing_hint_label.add_theme_color_override("font_color", Color("a8c894"))
	_routing_hint_label.set_meta(
		"presentation_role",
		&"delivery_lifecycle_details" if lifecycle_replaces_hint else &"status",
	)
	_routing_hint_label.accessibility_name = _routing_hint_label.tooltip_text
	_routing_hint_label.set_meta("accessible_text", _routing_hint_label.accessibility_name)
	_refresh_egg_journey_receipt(_focused_worker_id, assist_receipt_active)
	var manager_trust := clampf(float(worker.get("manager_trust", worker.get("trust", 50.0))), 0.0, 100.0)
	var grievance := clampf(float(worker.get("grievance", 0.0)), 0.0, 100.0)
	_trust_label.text = "TRUST  %d" % int(roundf(manager_trust))
	_trust_label.add_theme_color_override(
		"font_color",
		Color("73b5a7") if manager_trust >= 60.0 else (Color("d7c17d") if manager_trust >= 35.0 else Color("df826f")),
	)
	_grievance_label.text = "GRIEVANCE  %d" % int(roundf(grievance))
	_grievance_label.add_theme_color_override(
		"font_color",
		Color("df826f") if grievance >= 60.0 else (Color("d7c17d") if grievance >= 30.0 else Color("aebdc5")),
	)
	var phase := int(_snapshot.get("shift_phase", 1))
	var can_assign := _interaction_enabled and phase == 1 and employed
	for lane in ASSIGNMENT_ORDER:
		var button := _assignment_buttons[lane]
		button.remove_theme_font_size_override("font_size")
		var specialty_match := (
			lane != &"auto"
			and (lane == specialty or (secondary_specialty != &"" and lane == secondary_specialty))
		)
		button.text = "%s  FIT" % _lane_action_name(lane) if specialty_match else _lane_action_name(lane)
		button.disabled = not can_assign
		button.theme_type_variation = &"SelectedChoiceButton" if lane == assignment else &"DecisionChoiceButton"
		button.tooltip_text = _assignment_tooltip(lane)
		button.set_meta("specialty_match", specialty_match)
		button.accessibility_name = (
			"%s route, specialty fit" % _lane_action_name(lane)
			if specialty_match else
			"%s route" % _lane_action_name(lane)
		)
		if specialty_match:
			button.tooltip_text += " SPECIALTY FIT: this credential improves work pace and shell safety."
		if lane == &"auto":
			button.tooltip_text += (
				" IT Coop support will apply to this employed hen."
				if automation_enabled and employed else
				" AUTO remains a local opt-in without IT Coop support."
			)
		else:
			button.tooltip_text += " This is an explicit manual override of IT Coop AUTO support."
	var assignment_undo := _snapshot.get("assignment_undo", {}) as Dictionary
	var undo_previous_lane := StringName(assignment_undo.get("previous_lane", &""))
	var undo_current_lane := StringName(assignment_undo.get("current_lane", &""))
	var undo_matches := (
		int(assignment_undo.get("worker_id", -1)) == _focused_worker_id
		and int(assignment_undo.get("day", -1)) == int(_snapshot.get("day", -2))
		and undo_previous_lane in ASSIGNMENT_ORDER
		and undo_current_lane in ASSIGNMENT_ORDER
		and assignment == undo_current_lane
	)
	_assignment_undo_button.visible = undo_matches
	_assignment_undo_button.disabled = not can_assign
	if undo_matches:
		_assignment_undo_button.text = "UNDO ROUTE  /  %s" % _lane_name(
			undo_previous_lane
		)
		_assignment_undo_button.tooltip_text = (
			"Restore %s's prior %s route. This changes the next tray only; "
			+ "completed file work is never rolled back."
		) % [
			worker_name,
			_lane_name(undo_previous_lane),
		]
	var action_status := _snapshot.get("personnel_action_status", {}) as Dictionary
	var has_allowance_status := action_status.has("limit") or action_status.has("remaining")
	var action_limit := maxi(1, int(action_status.get("limit", 1)))
	var actions_used := clampi(
		int(action_status.get(
			"used",
			1 if bool(_snapshot.get("personnel_action_used", false)) else 0,
		)),
		0,
		action_limit,
	)
	var actions_remaining := clampi(
		int(action_status.get("remaining", action_limit - actions_used)),
		0,
		action_limit,
	)
	if not has_allowance_status and bool(_snapshot.get("personnel_action_used", false)):
		actions_remaining = 0
	var action_available := bool(action_status.get(
		"available",
		_snapshot.get("personnel_action_available", false),
	))
	var last_action := action_status.get("last_action", {}) as Dictionary
	var worker_action := _worker_action_receipt(action_status, worker, _focused_worker_id)
	var worker_action_filed := not worker_action.is_empty()
	var legacy_global_lock := not has_allowance_status and bool(_snapshot.get("personnel_action_used", false))
	var can_manage := (
		can_assign
		and action_available
		and actions_remaining > 0
		and not worker_action_filed
		and not legacy_global_lock
	)
	if worker_action_filed:
		_check_in_status_label.text = "HEN FILED / %d OF %d" % [actions_used, action_limit]
		_check_in_status_label.tooltip_text = String(worker_action.get(
			"outcome",
			"%s already has a filed flock check-in today." % worker_name,
		))
	elif actions_remaining <= 0 or legacy_global_lock:
		_check_in_status_label.text = "CHECK-INS FULL / %d OF %d" % [actions_used, action_limit]
		_check_in_status_label.tooltip_text = String(action_status.get(
			"reason",
			"Today's flock check-in allowance is fully filed.",
		))
	elif can_assign and action_available:
		_check_in_status_label.text = "CHECK-IN READY / %d OF %d / %d LEFT" % [
			actions_used,
			action_limit,
			actions_remaining,
		]
		_check_in_status_label.tooltip_text = "Choose one personnel action for this hen; %d flock check-in%s remain%s." % [
			actions_remaining,
			"" if actions_remaining == 1 else "s",
			"s" if actions_remaining == 1 else "",
		]
	else:
		_check_in_status_label.text = "CHECK-IN LOCKED / %d OF %d" % [actions_used, action_limit]
		_check_in_status_label.tooltip_text = String(action_status.get(
			"reason",
			"Resolve the current management decision first.",
		))
	_check_in_status_label.add_theme_color_override(
		"font_color",
		Color("e7c56e") if can_manage else Color("83939d"),
	)
	for action_id in PERSONNEL_ACTION_ORDER:
		var personnel_button := _personnel_buttons[action_id]
		personnel_button.add_theme_font_size_override("font_size", 11)
		var definition := _personnel_definition(action_id)
		var action_label := String(definition.get(
			"short_name",
			definition.get("button_label", definition.get("display_name", definition.get("name", PERSONNEL_ACTION_NAMES[action_id]))),
		)).to_upper()
		personnel_button.text = "%s%s" % [("SIG / " if preferred_action == action_id else ""), action_label]
		var preview := String(definition.get("preview", definition.get("description", PERSONNEL_ACTION_TOOLTIPS[action_id])))
		var action_cost := int(definition.get("cost_cents", 0))
		var affordable := int(_snapshot.get("spendable_fund_cents", _snapshot.get("revenue_cents", 0))) >= action_cost
		personnel_button.tooltip_text = "%s%s%s" % [
			preview,
			" Signature move for this hen; it still uses one normal flock check-in." if preferred_action == action_id else "",
			(
				" This hen already has a filed check-in today."
				if worker_action_filed else
				" The flock check-in allowance is full."
				if actions_remaining <= 0 or legacy_global_lock else
				(" Feed Fund is short." if not affordable else " Uses one of %d remaining flock check-ins." % actions_remaining)
			),
		]
		personnel_button.disabled = not can_manage or not affordable
	_refresh_dossier_summary(
		worker,
		career_profile_name,
		career_profile_description,
		preferred_action,
		worker_action,
	)
	_dossier_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_dossier_summary_label.accessibility_name = _dossier_summary_label.tooltip_text
	_dossier_summary_label.set_meta("accessible_text", _dossier_summary_label.accessibility_name)
	_dossier_summary_label.set_meta("presentation_role", &"dossier_detail")
	_refresh_first_clutch()


func _refresh_egg_journey_receipt(worker_id: int, current_file_receipt_visible: bool) -> void:
	_routing_hint_label.set_meta("egg_journey_visible", false)
	_routing_hint_label.set_meta("egg_journey_worker_id", -1)
	_routing_hint_label.set_meta("egg_journey_claim_id", -1)
	_routing_hint_label.set_meta("egg_journey_stage", &"")
	_routing_hint_label.set_meta("egg_journey_active_count", 0)
	_routing_hint_label.set_meta("accessible_text", _routing_hint_label.tooltip_text)
	_routing_hint_label.accessibility_name = _routing_hint_label.tooltip_text
	if current_file_receipt_visible:
		return
	var selected: Dictionary = {}
	var oldest_active_serial := 2_147_483_647
	var latest_settled_serial := -1
	var active_count := 0
	for receipt_value in _snapshot.get("egg_journey_receipts", []):
		var receipt := receipt_value as Dictionary
		if int(receipt.get("worker_id", -1)) != worker_id:
			continue
		var stage := StringName(String(receipt.get("stage", "")))
		var serial := int(receipt.get("serial", 0))
		if stage in [&"grading", &"graded"]:
			active_count += 1
			if serial < oldest_active_serial:
				oldest_active_serial = serial
				selected = receipt
		elif active_count == 0 and serial > latest_settled_serial:
			latest_settled_serial = serial
			selected = receipt
	if selected.is_empty():
		return
	var stage := StringName(String(selected.get("stage", "")))
	var claim_id := int(selected.get("claim_id", -1))
	var quality := String(selected.get("quality", "sound")).to_upper()
	var destination := (
		"FARMGATE" if StringName(String(selected.get("destination", "farmer"))) == &"farmgate" else "FARMER"
	)
	var claim_copy := " #%04d" % claim_id if claim_id >= 0 else ""
	var overlap_copy := "  +%d EGG" % (active_count - 1) if active_count > 1 else ""
	match stage:
		&"grading":
			_routing_hint_label.text = "LAST EGG%s  /  GRADING > %s%s" % [
				claim_copy, destination, overlap_copy,
			]
		&"graded":
			_routing_hint_label.text = "LAST EGG%s  /  %s GRADED > %s%s" % [
				claim_copy, quality, destination, overlap_copy,
			]
		&"stocked":
			_routing_hint_label.text = "LAST EGG%s  /  FARMGATE STOCK  $%.2f" % [
				claim_copy, float(selected.get("value_cents", 0)) / 100.0,
			]
		_:
			_routing_hint_label.text = "LAST EGG%s  /  FARMER +$%.2f%s" % [
				claim_copy,
				float(selected.get("cash_cents", 0)) / 100.0,
				"  /  PECK +1" if bool(selected.get("priority_refunded", false)) else "",
			]
	var worker_name := String(selected.get("worker_name", "This hen"))
	var accessible_text := (
		"Previous egg outcome, separate from %s's current controls. " % worker_name
		+ "%s egg%s is %s%s." % [
			quality.capitalize(),
			" from file %04d" % claim_id if claim_id >= 0 else "",
			(
				"moving through grading to %s" % destination.capitalize()
				if stage == &"grading" else
				"graded and moving to %s" % destination.capitalize()
				if stage == &"graded" else
				"stocked at Farmgate for later routing"
				if stage == &"stocked" else
				"delivered to the farmer for $%.2f%s" % [
					float(selected.get("cash_cents", 0)) / 100.0,
					" and restored one Priority Peck charge" if bool(selected.get("priority_refunded", false)) else "",
				]
			),
			" One additional egg is moving." if active_count == 2 else (
				" %d additional eggs are moving." % (active_count - 1) if active_count > 2 else ""
			),
		]
	)
	_routing_hint_label.tooltip_text = accessible_text
	_routing_hint_label.accessibility_name = accessible_text
	_routing_hint_label.add_theme_color_override(
		"font_color",
		Color("a8c894") if stage in [&"delivered", &"stocked"] else Color("efcf83"),
	)
	_routing_hint_label.set_meta("egg_journey_visible", true)
	_routing_hint_label.set_meta("egg_journey_worker_id", worker_id)
	_routing_hint_label.set_meta("egg_journey_claim_id", claim_id)
	_routing_hint_label.set_meta("egg_journey_stage", stage)
	_routing_hint_label.set_meta("egg_journey_active_count", active_count)
	_routing_hint_label.set_meta("accessible_text", accessible_text)


func _refresh_peck_timing_presentation(
	assist: Dictionary,
	assist_state: StringName,
	claim_empty: bool,
) -> void:
	if (
		_peck_timing_band == null
		or _peck_timing_marker == null
		or _peck_timing_label == null
		or _claim_progress_track == null
	):
		return
	var gold_start := clampf(float(assist.get("gold_start", 58.0)), 0.0, 100.0)
	var gold_end := clampf(float(assist.get("gold_end", 66.0)), gold_start, 100.0)
	var ideal_progress := clampf(
		float(assist.get("ideal_progress", 62.0)),
		gold_start,
		gold_end,
	)
	_peck_timing_band.set_anchor(SIDE_LEFT, gold_start / 100.0, false)
	_peck_timing_band.set_anchor(SIDE_RIGHT, gold_end / 100.0, false)
	_peck_timing_band.set_anchor(SIDE_TOP, 0.0, false)
	_peck_timing_band.set_anchor(SIDE_BOTTOM, 1.0, false)
	_peck_timing_band.offset_left = 0.0
	_peck_timing_band.offset_right = 0.0
	_peck_timing_band.offset_top = 0.0
	_peck_timing_band.offset_bottom = 0.0
	_peck_timing_marker.set_anchor(SIDE_LEFT, ideal_progress / 100.0, false)
	_peck_timing_marker.set_anchor(SIDE_RIGHT, ideal_progress / 100.0, false)
	_peck_timing_marker.set_anchor(SIDE_TOP, 0.0, false)
	_peck_timing_marker.set_anchor(SIDE_BOTTOM, 1.0, false)
	_peck_timing_marker.offset_left = -2.0
	_peck_timing_marker.offset_right = 2.0
	_peck_timing_marker.offset_top = 0.0
	_peck_timing_marker.offset_bottom = 0.0
	var timing_tooltip := (
		"Priority Peck opens at %d%%. The gold band runs from %d-%d%%, and the bright line marks the ideal %d%% rhythm. Press the action while the file meter crosses the band."
		% [
			roundi(float(assist.get("window_start", 28.0))),
			roundi(gold_start),
			roundi(gold_end),
			roundi(ideal_progress),
		]
	)
	_claim_progress_track.tooltip_text = timing_tooltip
	var timing_accessible := timing_tooltip
	if claim_empty:
		_peck_timing_label.text = ""
		_peck_timing_label.tooltip_text = ""
		_peck_timing_label.accessibility_name = ""
		_peck_timing_label.set_meta("accessible_text", "")
		return
	match assist_state:
		&"not_ready":
			_peck_timing_label.text = "WAIT FOR GOLD  •  THEN PECK"
			timing_accessible = (
				"Wait for the file meter to reach the gold band, then use Priority Peck. "
				+ timing_tooltip
			)
			_peck_timing_band.color = Color(0.95, 0.72, 0.22, 0.42)
			_peck_timing_label.add_theme_color_override("font_color", Color("77b7aa"))
		&"open":
			var timing_label := String(assist.get("timing_label", "WORKABLE RHYTHM"))
			_peck_timing_label.text = "PECK NOW  •  %s" % timing_label
			timing_accessible = (
				"Priority Peck now. %s. " % timing_label
				+ timing_tooltip
			)
			var timing_color := Color("e7d7a4")
			if "GOLDEN" in timing_label:
				timing_color = Color("f1d681")
				_peck_timing_band.color = Color(1.0, 0.78, 0.18, 0.82)
			elif "CLEAN" in timing_label:
				timing_color = Color("8dcfbd")
				_peck_timing_band.color = Color(0.98, 0.76, 0.24, 0.64)
			elif "RISKY" in timing_label:
				timing_color = Color("d98c75")
				_peck_timing_band.color = Color(0.89, 0.58, 0.28, 0.48)
			_peck_timing_label.add_theme_color_override("font_color", timing_color)
		&"missed", &"passed":
			_peck_timing_label.text = "NEXT FILE  •  TRY AGAIN"
			timing_accessible = (
				"Priority Peck window missed. Try again on the next file. "
				+ timing_tooltip
			)
			_peck_timing_band.color = Color(0.62, 0.38, 0.31, 0.34)
			_peck_timing_label.add_theme_color_override("font_color", Color("c97d6b"))
		_:
			_peck_timing_label.text = ""
			timing_accessible = ""
	_peck_timing_label.tooltip_text = timing_accessible
	_peck_timing_label.accessibility_name = timing_accessible
	_peck_timing_label.set_meta("accessible_text", timing_accessible)


func _refresh_claim_resolution_controls(
	worker: Dictionary,
	claim: Dictionary,
) -> void:
	if _claim_resolution_section == null:
		return
	var status := worker.get("claim_resolution_status", {}) as Dictionary
	var available := bool(status.get("available", false)) and _interaction_enabled
	var reason := String(status.get(
		"reason",
		"Choose a claimant path before the file is 55% complete.",
	))
	var selected_path := StringName(claim.get("resolution_path", &"standard"))
	var locked := bool(claim.get("resolution_locked", false))
	for path_id in _claim_resolution_buttons:
		var button := _claim_resolution_buttons[path_id] as Button
		var definition := _claim_resolution_definition(path_id)
		var cost_cents := int(definition.get("cost_cents", 0))
		button.text = "%s  /  $%.2f" % [
			String(definition.get(
				"short_label",
				String(path_id).to_upper(),
			)),
			float(cost_cents) / 100.0,
		]
		button.disabled = claim.is_empty() or not available
		button.theme_type_variation = (
			&"SelectedChoiceButton"
			if locked and selected_path == path_id else
			&"DecisionChoiceButton"
		)
		button.tooltip_text = "%s RECEIVES THE BENEFIT\n%s\n%s%s" % [
			String(definition.get("beneficiary", "BUREAU")),
			String(definition.get("benefit", "")),
			String(definition.get("burden", "")),
			"\n%s" % reason if not available and not reason.is_empty() else "",
		]


func _refresh_dossier_summary(
	worker: Dictionary,
	career_profile_name: String,
	career_profile_description: String,
	preferred_action: StringName,
	worker_action: Dictionary,
) -> void:
	if _dossier_summary_label == null:
		return
	_dossier_summary_label.remove_theme_stylebox_override("normal")
	match _active_dossier_tab:
		&"claim":
			var claim := worker.get("current_claim", {}) as Dictionary
			if claim.is_empty():
				_dossier_summary_label.text = (
					"NO ACTIVE CLAIMANT FILE\n"
					+ "Route work from the live trays, then return before 55% completion."
				)
				_dossier_summary_label.tooltip_text = _dossier_summary_label.text
				_dossier_summary_label.add_theme_color_override(
					"font_color",
					Color("aebdc5"),
				)
				return
			var selected_path := StringName(claim.get(
				"resolution_path",
				&"standard",
			))
			var definition := _claim_resolution_definition(selected_path)
			var return_label := (
				"RETURNED APPEAL  /  "
				if bool(claim.get("is_claimant_follow_up", false)) else
				"CLAIMANT  /  "
			)
			_dossier_summary_label.text = (
				"%s%s\nLOSS  /  %s\nNEEDS  /  %s\nDELAY COST  /  %s" % [
					return_label,
					String(claim.get("claimant_name", "UNFILED CLAIMANT")),
					String(claim.get("claimant_incident", "No incident context filed.")),
					String(claim.get("claimant_need", "No requested remedy filed.")),
					String(claim.get(
						"claimant_delay_cost",
						"No delay consequence filed.",
					)),
				]
			)
			_dossier_summary_label.tooltip_text = (
				"%s\nCURRENT PATH / %s\n%s\n%s" % [
					_dossier_summary_label.text,
					String(definition.get("label", "STANDARD HANDLING")),
					String(definition.get("benefit", "")),
					String(definition.get("burden", "")),
				]
			)
			_dossier_summary_label.add_theme_color_override(
				"font_color",
				Color("efcf83"),
			)
		&"support":
			var definition := _personnel_definition(preferred_action)
			var action_name := String(definition.get(
				"short_name",
				definition.get("name", PERSONNEL_ACTION_NAMES.get(preferred_action, "CHECK-IN")),
			)).to_upper()
			var preview := String(definition.get(
				"preview",
				definition.get("description", PERSONNEL_ACTION_TOOLTIPS.get(preferred_action, "")),
			)).strip_edges()
			if not worker_action.is_empty():
				var filed_name := String(worker_action.get(
					"action_name",
					worker_action.get("display_name", action_name),
				)).to_upper()
				var outcome := String(worker_action.get(
					"outcome",
					"This hen's check-in is already filed for today.",
				)).strip_edges()
				_dossier_summary_label.text = "CHECK-IN FILED  /  %s\n%s" % [filed_name, outcome]
				_dossier_summary_label.tooltip_text = _dossier_summary_label.text
				_dossier_summary_label.add_theme_color_override("font_color", Color("8fc9b8"))
				return
			_dossier_summary_label.text = "PROFILE FIT  /  %s\n%s\n%s" % [
				action_name,
				career_profile_description if not career_profile_description.is_empty() else "This filing matches the hen's recorded work profile.",
				preview,
			]
			_dossier_summary_label.tooltip_text = "%s\n%s" % [
				String(definition.get("description", "Choose one permanent check-in for this shift.")),
				preview,
			]
			_dossier_summary_label.add_theme_color_override("font_color", Color("e7c56e"))
		&"profile":
			var specialty := StringName(worker.get("specialty", &"nest_damage"))
			var assignment := StringName(worker.get("assignment", worker.get("assigned_lane", &"auto")))
			var morale := roundi(float(worker.get("morale", 0.0)))
			var stress := roundi(float(worker.get("stress", 0.0)))
			var fatigue := roundi(float(worker.get("fatigue", 0.0)))
			var crack_risk := roundi(float(worker.get("estimated_crack_risk", 0.0)) * 100.0)
			var temperament_label := String(worker.get("temperament_label", "STEADY HEN"))
			var temperament_effect := worker.get("temperament_effect", {}) as Dictionary
			var work_style_label := String(temperament_effect.get("label", "STEADY RHYTHM"))
			var work_style_summary := String(temperament_effect.get("summary", "steady baseline"))
			var flock_bond := worker.get("flock_bond", {}) as Dictionary
			var bond_line := String(flock_bond.get("summary", "No active perchmate relationship is filed."))
			var personal_mastery := worker.get("personal_mastery", {}) as Dictionary
			var mastery_line := "MASTERY  %d/%d  /  NEXT %s → %s" % [
				int(personal_mastery.get("completed", 0)),
				int(personal_mastery.get("total", 3)),
				String(personal_mastery.get("next_label", "MASTERED")),
				String(personal_mastery.get(
					"next_reward",
					worker.get("career_title", "MASTER LAYER"),
				)).to_upper(),
			]
			_dossier_summary_label.text = "%s  /  %s SPECIALIST  /  %s\n%s\nTEMPERAMENT  /  %s  /  %s: %s\nFLOCK BOND  /  %s\nCARE  morale %d  /  stress %d  /  fatigue %d  /  shell risk %d%%" % [
				career_profile_name.to_upper(),
				_lane_name(specialty),
				("AUTO SORT" if assignment == &"auto" else "%s TRAY" % _lane_name(assignment)),
				mastery_line,
				temperament_label,
				work_style_label,
				work_style_summary,
				bond_line,
				morale,
				stress,
				fatigue,
				crack_risk,
			]
			_dossier_summary_label.tooltip_text = _dossier_summary_label.text
			_dossier_summary_label.add_theme_color_override("font_color", _lane_color(specialty))
		_:
			_dossier_summary_label.text = ""
			_dossier_summary_label.tooltip_text = ""


func _refresh_first_clutch() -> void:
	if _first_clutch_panel == null:
		return
	var coach_active := bool(_first_clutch.get("visible", false))
	if _hen_intent_button != null:
		var worker := _worker_snapshot(_focused_worker_id)
		_hen_intent_button.visible = (
			not coach_active
			and not (worker.get("hen_intent", {}) as Dictionary).is_empty()
		)
	var compact := coach_active and (
		_first_clutch_has_contextual_dossier()
		or bool(_first_clutch.get("essential_only", false))
	)
	if compact != _first_clutch_compact:
		_first_clutch_compact = compact
		_apply_first_clutch_layout()
	_first_clutch_panel.visible = coach_active
	_first_clutch_body_label.visible = not compact
	_refresh_first_clutch_return_action(coach_active)
	_apply_dossier_disclosure()
	if not coach_active:
		# A mouse-activated Skip can remain the viewport's focus owner after its
		# coach card disappears. Release only focus owned by that hidden card so
		# Home/WASD and other floor controls are not swallowed by an invisible UI.
		var focus_owner := get_viewport().gui_get_focus_owner()
		if focus_owner != null and _first_clutch_panel.is_ancestor_of(focus_owner):
			get_viewport().gui_release_focus()
		_clear_first_clutch_control_cue()
		return
	var total := clampi(int(_first_clutch.get("total", 5)), 1, 99)
	var progress := clampi(int(_first_clutch.get(
		"progress",
		_first_clutch.get("completed_steps", 0),
	)), 0, total)
	var eyebrow := String(_first_clutch.get("eyebrow", "")).strip_edges().to_upper()
	var character_led_orientation := (
		bool(_first_clutch.get("pre_policy", false)) and not eyebrow.is_empty()
	)
	_first_clutch_progress_label.text = eyebrow if character_led_orientation else "FIRST CLUTCH"
	_first_clutch_progress_rail.visible = not character_led_orientation
	_first_clutch_progress_rail.set_progress(progress, total)
	var accessible_title := String(_first_clutch.get(
		"title",
		_first_clutch.get("action_title", "INSPECT A HEN"),
	)).strip_edges().to_upper()
	if accessible_title.is_empty():
		accessible_title = "INSPECT A HEN"
	_first_clutch_title_label.text = String(_first_clutch.get(
		"visual_title",
		accessible_title,
	)).strip_edges().to_upper()
	if _first_clutch_title_label.text.is_empty():
		_first_clutch_title_label.text = accessible_title
	_first_clutch_title_label.accessibility_name = accessible_title
	_first_clutch_title_label.tooltip_text = accessible_title
	_first_clutch_title_label.set_meta("accessible_text", accessible_title)
	var accessible_body := String(_first_clutch.get(
		"body",
		_first_clutch.get("action_body", "Click a hen or press Tab to open her work file."),
	)).strip_edges()
	if accessible_body.is_empty():
		accessible_body = "Complete the highlighted management action."
	_first_clutch_body_label.text = String(_first_clutch.get(
		"visual_body",
		accessible_body,
	)).strip_edges()
	if _first_clutch_body_label.text.is_empty():
		_first_clutch_body_label.text = accessible_body
	_first_clutch_body_label.accessibility_name = accessible_body
	_first_clutch_body_label.tooltip_text = accessible_body
	_first_clutch_body_label.set_meta("accessible_text", accessible_body)
	_first_clutch_panel.tooltip_text = "%s\n%s" % [
		accessible_title,
		accessible_body,
	]
	var can_skip := bool(_first_clutch.get("can_skip", true))
	var skip_had_focus := _first_clutch_skip_button.has_focus()
	_first_clutch_skip_button.visible = can_skip
	_first_clutch_skip_button.mouse_filter = (
		Control.MOUSE_FILTER_STOP if can_skip else Control.MOUSE_FILTER_IGNORE
	)
	if skip_had_focus and not can_skip:
		# Delivery can settle asynchronously while Skip owns keyboard focus. Reuse
		# the staged-disclosure focus handoff after the button is actually hidden
		# so focus never remains trapped on an unavailable tutorial action.
		_ensure_contextual_focus_remains_visible(
			_first_clutch_disclosure_stage(),
			_first_clutch_skip_button,
		)
	var tone := StringName(String(_first_clutch.get("tone", "active")))
	var border := Color("c7a352")
	if tone == &"warning":
		border = Color("c9795d")
	elif tone in [&"ready", &"complete"]:
		border = Color("73b5a7")
	_first_clutch_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("172832"), 0.985, border, 8, 1),
	)
	_apply_first_clutch_control_cue()
	_apply_first_clutch_route_glance()
	_apply_first_clutch_check_in_glance()
	_apply_first_clutch_priority_peck_glance()
	_apply_first_clutch_delivery_glance()


## Turns the first routing lesson into one glanceable match: the hen's filed
## specialty, the suggested tray, and its keyboard action all share one color.
## Exact automation and credential tradeoffs remain available in tooltips and
## the Details disclosure after the player has learned the physical action.
func _apply_first_clutch_route_glance() -> void:
	if (
		_first_clutch_disclosure_stage() != &"specialty_route"
		or not _first_clutch_has_contextual_dossier()
	):
		return
	var lane := _first_clutch_route_lane()
	if lane == &"" or not _assignment_buttons.has(lane):
		return
	var worker := _worker_snapshot(_focused_worker_id)
	var specialty := StringName(String(worker.get("specialty", "")))
	var secondary := StringName(String(worker.get(
		"secondary_specialty",
		worker.get("secondary_lane", ""),
	)))
	var matched := lane == specialty or (secondary != &"" and lane == secondary)
	var lane_name := _lane_name(lane)
	var route_color := _lane_color(lane)
	var target_button := _assignment_buttons[lane] as Button
	_refresh_worker_identity_marks(lane)
	target_button.text = "%s  [ENTER]" % _lane_action_name(lane)
	target_button.add_theme_font_size_override("font_size", 11)
	target_button.set_meta("first_clutch_recommended_route", true)
	target_button.accessibility_name = "Recommended best-fit route: %s. Press Enter." % lane_name
	var current_lane := StringName(String(worker.get(
		"assignment",
		worker.get("assigned_lane", &"auto"),
	)))
	if current_lane != lane and _assignment_buttons.has(current_lane):
		var current_button := _assignment_buttons[current_lane] as Button
		current_button.theme_type_variation = &"DecisionChoiceButton"
		current_button.self_modulate = Color(1.0, 1.0, 1.0, 0.58)
		current_button.set_meta("first_clutch_current_route_demoted", true)
		current_button.accessibility_name = (
			"Current route: %s. Change to recommended %s to continue First Clutch."
			% [_lane_name(current_lane), lane_name]
		)
	_worker_trait_label.text = (
		"%s SPECIALIST" % lane_name
		if matched else
		"TARGET TRAY  /  %s" % lane_name
	)
	_worker_trait_label.accessibility_name = (
		(
			"%s's %s specialty matches the highlighted %s tray. "
			+ "A specialty match improves speed and shell safety."
		) % [String(worker.get("name", "This hen")), lane_name, lane_name]
		if matched else
		"The highlighted target tray is %s; choose it to continue First Clutch." % lane_name
	)
	_worker_trait_label.tooltip_text = _worker_trait_label.accessibility_name
	_worker_trait_label.set_meta("accessible_text", _worker_trait_label.accessibility_name)
	_worker_trait_label.set_meta(
		"presentation_role",
		&"specialist_identity" if matched else &"target_route",
	)
	_worker_trait_label.add_theme_color_override("font_color", route_color.lightened(0.18))
	var route_guidance := String(_first_clutch.get(
		"guidance",
		"Press Enter or choose the highlighted %s tray." % lane_name,
	))
	if matched:
		_routing_hint_label.text = "FIT = FASTER + SAFER"
		_routing_hint_label.accessibility_name = (
			"Specialty match: speed improves and shell crack risk decreases. "
			+ route_guidance
		)
		_routing_hint_label.set_meta("presentation_role", &"match_payoff")
	else:
		_routing_hint_label.text = "ROUTE  >  %s  [ENTER]" % _lane_short_name(lane)
		_routing_hint_label.accessibility_name = route_guidance
		_routing_hint_label.set_meta("presentation_role", &"route_action")
	_routing_hint_label.tooltip_text = _routing_hint_label.accessibility_name
	_routing_hint_label.set_meta("accessible_text", _routing_hint_label.accessibility_name)
	_routing_hint_label.add_theme_color_override("font_color", route_color.lightened(0.22))


func _first_clutch_route_lane() -> StringName:
	var lane_text := String(_first_clutch.get(
		"lane",
		_first_clutch.get(
			"expected_lane",
			_first_clutch.get("specialty", _first_clutch.get("specialty_name", "")),
		),
	)).strip_edges().to_lower().replace(" ", "_")
	var lane := StringName(lane_text)
	return lane if lane in ASSIGNMENT_ORDER else &""


## Uses the otherwise empty center of the coached dossier to name the one
## required tutorial action. The permanent personnel action underneath stays
## explicit in the tooltip and accessibility copy, along with its exact effects.
func _apply_first_clutch_check_in_glance() -> void:
	if (
		_first_clutch_disclosure_stage() != &"check_in"
		or not _first_clutch_has_contextual_dossier()
	):
		return
	var worker := _worker_snapshot(_focused_worker_id)
	var action_id := StringName(String(_first_clutch.get(
		"action_id",
		_first_clutch.get(
			"preferred_action",
			worker.get("preferred_personnel_action", ""),
		),
	)))
	if action_id == &"" or not _personnel_buttons.has(action_id):
		return
	var definition := _personnel_definition(action_id)
	var action_name := String(definition.get(
		"short_name",
		PERSONNEL_ACTION_NAMES.get(action_id, String(action_id).replace("_", " ")),
	)).to_upper()
	var profile_name := String(worker.get("career_profile_name", "PROFILE FIT")).to_upper()
	var worker_name := String(worker.get("name", "This hen"))
	var target_button := _personnel_buttons[action_id] as Button
	var action_description := String(definition.get(
		"description",
		PERSONNEL_ACTION_TOOLTIPS.get(action_id, ""),
	))
	var action_preview := String(definition.get("preview", ""))
	var check_in_detail := (
		"File this profile-fit check-in using %s. %s %s Permanent; uses the one available flock check-in."
		% [action_name, action_description, action_preview]
	).strip_edges()
	target_button.text = "FILE CHECK-IN  [ENTER]"
	target_button.add_theme_font_size_override("font_size", 10)
	target_button.tooltip_text = check_in_detail
	target_button.accessibility_name = check_in_detail
	target_button.set_meta("accessible_text", check_in_detail)
	target_button.set_meta("presentation_role", &"check_in_action")
	_worker_trait_label.text = "PROFILE  /  %s" % profile_name
	_worker_trait_label.accessibility_name = "%s's active work profile is %s." % [worker_name, profile_name]
	_worker_trait_label.tooltip_text = _worker_trait_label.accessibility_name
	_worker_trait_label.set_meta("accessible_text", _worker_trait_label.accessibility_name)
	_worker_trait_label.set_meta("presentation_role", &"profile_identity")
	_worker_trait_label.add_theme_color_override("font_color", Color("8fc9b8"))
	_dossier_summary_label.visible = true
	_dossier_summary_label.text = "RECOMMENDED  >  FILE CHECK-IN"
	_dossier_summary_label.accessibility_name = (
		"Recommended check-in for %s: FILE CHECK-IN uses %s because %s is a profile match. %s %s"
		% [
			worker_name,
			action_name,
			profile_name,
			action_description,
			action_preview,
		]
	).strip_edges()
	_dossier_summary_label.tooltip_text = _dossier_summary_label.accessibility_name
	_dossier_summary_label.set_meta("accessible_text", _dossier_summary_label.accessibility_name)
	_dossier_summary_label.set_meta("presentation_role", &"check_in_recommendation")
	_dossier_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dossier_summary_label.add_theme_color_override("font_color", Color("bce4d8"))
	_dossier_summary_label.add_theme_stylebox_override(
		"normal",
		_compact_button_style(Color("1d3535"), Color("5b9b8d"), 1),
	)
	_check_in_status_label.text = "1 OF 1 LEFT  /  PERMANENT"
	_check_in_status_label.add_theme_color_override("font_color", Color("8fc9b8"))


func _personnel_effect_glance(action_id: StringName) -> String:
	match action_id:
		&"share_credit":
			return "TRUST +  /  GRIEVANCE -"
		&"career_coaching":
			return "CAREER XP +  /  SHELL RISK -"
		&"quota_pressure":
			return "PACE +  /  TRUST -"
	return "PROFILE EFFECT  /  SEE DETAILS"


## Keeps the timing lesson aligned with the action the player is actually
## learning. The specialty route is already complete here, so an empty tray is
## a wait-for-work state—not another route decision—and the automation note is
## less useful than the three-beat rhythm the player should watch.
func _apply_first_clutch_priority_peck_glance() -> void:
	if (
		_first_clutch_disclosure_stage() != &"priority_peck"
		or not _first_clutch_has_contextual_dossier()
	):
		return
	var worker := _worker_snapshot(_focused_worker_id)
	var claim := worker.get("current_claim", {}) as Dictionary
	var assist := worker.get("peck_assist", {}) as Dictionary
	var assist_state := StringName(assist.get("window_state", &"locked"))
	var resume_required := bool(_first_clutch.get("resume_required", false))
	var worker_name := String(worker.get("name", "This hen"))
	_routing_lifecycle_rail.set_stage(&"peck")
	if claim.is_empty():
		_clear_claim_phase_header()
		_current_claim_label.text = "2  WAIT FOR LIVE FILE"
		_current_claim_label.accessibility_name = (
			"Step 2, Priority Peck. %s is correctly routed and waiting for a live file. "
			+ "When work arrives, watch its progress meter for the gold timing window."
		) % worker_name
		_current_claim_label.tooltip_text = _current_claim_label.accessibility_name
		_current_claim_label.set_meta("accessible_text", _current_claim_label.accessibility_name)
		_current_claim_label.set_meta("presentation_role", &"priority_wait")
		_routing_hint_label.text = (
			"RESUME 1x  >  FILE  >  GOLD"
			if resume_required else
			"FILE INCOMING  >  WATCH GOLD"
		)
	else:
		match assist_state:
			&"open":
				_routing_hint_label.text = (
					"RESUME 1x  >  PECK NOW"
					if resume_required else
					"GOLD OPEN  >  PECK NOW  [%s]" % _peck_assist_binding_label
				)
			&"not_ready":
				_routing_hint_label.text = (
					"RESUME 1x  >  WATCH GOLD"
					if resume_required else
					"BUILD RHYTHM  >  WATCH GOLD"
				)
			&"used":
				# Keep the exact landed receipt authored by the normal dossier.
				return
			_:
				_routing_hint_label.text = "WATCH FILE  >  GOLD WINDOW"
	_routing_hint_label.accessibility_name = String(_first_clutch.get(
		"body",
		"Watch the live file meter for the gold Priority Peck window.",
	))
	_routing_hint_label.tooltip_text = _routing_hint_label.accessibility_name
	_routing_hint_label.set_meta("accessible_text", _routing_hint_label.accessibility_name)
	_routing_hint_label.set_meta("presentation_role", &"priority_sequence")
	_routing_hint_label.add_theme_color_override("font_color", Color("e5ca72"))


## Turns the post-peck handoff into the same three-beat visual language as the
## rest of First Clutch. The player tracks one assisted file until it becomes
## an egg, then the active lifecycle shape and copy move to grading together.
func _apply_first_clutch_delivery_glance() -> void:
	if (
		_first_clutch_disclosure_stage() != &"delivery"
		or not _first_clutch_has_contextual_dossier()
	):
		return
	var worker := _worker_snapshot(_focused_worker_id)
	var worker_name := String(worker.get("name", "This hen"))
	var claim_id := int(_first_clutch.get("assisted_claim_id", -1))
	var egg_laid := bool(_first_clutch.get("delivery_laid", false))
	_clear_claim_phase_header()
	if egg_laid:
		_routing_lifecycle_rail.set_stage(&"egg", true)
		_current_claim_label.text = "3  EGG IN GRADING"
		_current_claim_label.accessibility_name = (
			"Step 3, egg delivery. %s finished assisted file #%04d. "
			+ "Its egg is moving through grading toward the farmer basket."
		) % [worker_name, maxi(0, claim_id)]
		_current_claim_label.set_meta("presentation_role", &"delivery_grading")
		_routing_hint_label.text = "GRADING  >  FARMER BASKET  >  FEED FUND"
		_routing_hint_label.set_meta("presentation_role", &"delivery_sequence")
	else:
		_routing_lifecycle_rail.set_stage(&"peck")
		_current_claim_label.text = (
			"2  ASSISTED FILE #%04d  /  FINISHING" % claim_id
			if claim_id >= 0 else
			"2  ASSISTED FILE  /  FINISHING"
		)
		_current_claim_label.accessibility_name = (
			"Step 2, assisted file. Priority Peck landed; watch %s finish file #%04d and lay its egg."
			% [worker_name, maxi(0, claim_id)]
		)
		_current_claim_label.set_meta("presentation_role", &"delivery_file")
		_routing_hint_label.text = "PECK LANDED  >  FINISH FILE  >  LAY EGG"
		_routing_hint_label.set_meta("presentation_role", &"delivery_sequence")
	_current_claim_label.tooltip_text = _current_claim_label.accessibility_name
	_current_claim_label.set_meta("accessible_text", _current_claim_label.accessibility_name)
	_routing_hint_label.accessibility_name = String(_first_clutch.get(
		"body",
		"Follow the assisted file through egg delivery.",
	))
	_routing_hint_label.tooltip_text = _routing_hint_label.accessibility_name
	_routing_hint_label.set_meta("accessible_text", _routing_hint_label.accessibility_name)
	_routing_hint_label.add_theme_color_override(
		"font_color",
		Color("9fd4bd") if egg_laid else Color("e5ca72"),
	)


func _first_clutch_disclosure_stage() -> StringName:
	var stage := StringName(String(_first_clutch.get(
		"stage",
		_first_clutch.get("step", _first_clutch.get("cue", "")),
	)).strip_edges().to_lower())
	match stage:
		&"route", &"routing", &"match_route":
			return &"specialty_route"
		&"checkin", &"personnel", &"personnel_action":
			return &"check_in"
		&"peck", &"peck_assist":
			return &"priority_peck"
		_:
			return stage


func _first_clutch_has_contextual_dossier() -> bool:
	if _focus_panel == null or not _focus_panel.visible or _focused_worker_id < 0:
		return false
	var target_worker_id := _first_clutch_target_worker_id()
	return target_worker_id < 0 or target_worker_id == _focused_worker_id


## Keeps one management category visible at a time while First Clutch is active.
## Nodes are retained (including names, signals, and disabled state); normal or
## dismissed coach state restores every management action immediately.
func _apply_dossier_disclosure() -> void:
	if (
		_queue_panel == null
		or _focus_panel == null
		or _assignment_section == null
		or _claim_resolution_section == null
		or _personnel_actions_section == null
	):
		return
	var previous_focus_owner: Control
	var viewport := get_viewport()
	if viewport != null:
		previous_focus_owner = viewport.gui_get_focus_owner()
	var coach_active := bool(_first_clutch.get("visible", false))
	var normal_play := not coach_active
	var target_matches := _first_clutch_has_contextual_dossier()
	var stage := _first_clutch_disclosure_stage()
	if stage == &"":
		stage = &"inspect"
	var route_tab := normal_play and _active_dossier_tab == &"route"
	var claim_tab := normal_play and _active_dossier_tab == &"claim"
	var support_tab := normal_play and _active_dossier_tab == &"support"
	var profile_tab := normal_play and _active_dossier_tab == &"profile"

	var show_claim := route_tab or claim_tab or (coach_active and stage in [
		&"inspect",
		&"specialty_route",
		&"priority_peck",
		&"delivery",
		&"reinvestment",
		&"complete",
	])
	var show_routing := route_tab or (coach_active and target_matches and stage == &"specialty_route")
	var show_check_in := support_tab or (coach_active and target_matches and stage == &"check_in")
	var show_priority := route_tab or (coach_active and target_matches and stage == &"priority_peck")
	var show_delivery := target_matches and stage == &"delivery"

	# The queue is useful while teaching routes, but it is visual noise during
	# inspection, personnel, timing, and delivery steps.
	_queue_panel.visible = normal_play or (target_matches and stage == &"specialty_route")
	_claim_header.visible = show_claim
	_dossier_summary_label.visible = (
		normal_play
		and _active_dossier_tab in [&"claim", &"support", &"profile"]
	)
	var worker := _worker_snapshot(_focused_worker_id)
	var claim := worker.get("current_claim", {}) as Dictionary
	_claim_context_row.visible = show_claim
	_claim_detail_strip.visible = show_claim and not claim.is_empty()
	_routing_lifecycle_rail.visible = show_claim
	_claim_progress_track.visible = show_claim and not claim.is_empty()
	var show_timing := (
		not claim.is_empty()
		and (route_tab or show_priority)
		and StringName((worker.get("peck_assist", {}) as Dictionary).get(
			"window_state",
			&"locked",
		)) in [&"not_ready", &"open", &"missed", &"passed"]
	)
	_peck_timing_band.visible = show_timing
	_peck_timing_marker.visible = show_timing
	_peck_timing_label.visible = show_timing
	_assignment_section.visible = show_routing
	_claim_resolution_section.visible = claim_tab and not claim.is_empty()
	_personnel_actions_section.visible = show_check_in

	_assist_row.visible = route_tab or show_routing or show_priority or show_delivery
	_routing_hint_label.visible = (
		_assist_row.visible
		and not (
			normal_play
			and bool(_routing_hint_label.get_meta("lifecycle_replaces_hint", false))
		)
	)
	_peck_assist_button.visible = route_tab or show_priority
	_peck_charge_meter.visible = _peck_assist_button.visible and _claim_progress_track.visible

	_worker_career_label.visible = profile_tab or (coach_active and _details_expanded)
	_trust_label.visible = profile_tab or (coach_active and _details_expanded)
	_grievance_label.visible = profile_tab or (coach_active and _details_expanded)
	_check_in_status_label.visible = show_check_in
	_personnel_status.visible = profile_tab or show_check_in or (coach_active and _details_expanded)
	_dossier_tabs.visible = normal_play
	_details_button.visible = coach_active
	for tab_id: StringName in _dossier_tab_buttons:
		var tab_button := _dossier_tab_buttons[tab_id] as Button
		tab_button.set_pressed_no_signal(tab_id == _active_dossier_tab)
	_details_button.text = "HIDE DETAILS" if _details_expanded else "DETAILS"
	_details_button.tooltip_text = (
		"Hide career, trust, grievance, and care details."
		if _details_expanded else
		"Show career, trust, grievance, and care details for this hen."
	)
	if not profile_tab and not _details_expanded and not worker.is_empty():
		var specialty := StringName(worker.get("specialty", &"nest_damage"))
		var secondary := StringName(String(worker.get(
			"secondary_specialty",
			worker.get("secondary_lane", ""),
		)))
		var specialty_copy := _lane_name(specialty)
		if secondary != &"":
			specialty_copy += " + %s" % _lane_name(secondary)
		_worker_trait_label.text = "SPECIALTY  /  %s" % specialty_copy
		_worker_trait_label.tooltip_text = (
			"Primary routing specialty: %s. Open Details for career, care, and accreditation notes."
			% _lane_name(specialty)
		)
	_ensure_contextual_focus_remains_visible(stage, previous_focus_owner)


func _ensure_contextual_focus_remains_visible(
	stage: StringName,
	focus_owner: Control = null,
) -> void:
	if focus_owner == null:
		var viewport := get_viewport()
		if viewport == null:
			return
		focus_owner = viewport.gui_get_focus_owner()
	if (
		focus_owner == null
		or not is_ancestor_of(focus_owner)
		or focus_owner.is_visible_in_tree()
	):
		return
	var target: Button
	match stage:
		&"specialty_route":
			var lane := StringName(String(_first_clutch.get(
				"expected_lane",
				_first_clutch.get("lane", "auto"),
			)))
			target = _assignment_buttons.get(lane) as Button
		&"check_in":
			var action_id := StringName(String(_first_clutch.get(
				"preferred_action",
				_worker_snapshot(_focused_worker_id).get("preferred_personnel_action", ""),
			)))
			target = _personnel_buttons.get(action_id) as Button
		&"priority_peck":
			target = _peck_assist_button
	if target == null or not target.is_visible_in_tree():
		# When the coached hen is no longer focused, the explicit return action is
		# safer than moving focus into an unrelated hen's dossier. A target-matched
		# dossier falls back to Details for delivery/reinvestment/complete stages.
		if (
			_first_clutch_return_button != null
			and _first_clutch_return_button.is_visible_in_tree()
		):
			target = _first_clutch_return_button
		else:
			target = _details_button
	if target != null and target.is_visible_in_tree() and target.focus_mode != Control.FOCUS_NONE:
		target.call_deferred("grab_focus")


func _apply_first_clutch_control_cue() -> void:
	if not bool(_first_clutch.get("visible", false)) or not _focus_panel.visible:
		_clear_first_clutch_control_cue()
		return
	var worker_id := _first_clutch_target_worker_id()
	if worker_id >= 0 and worker_id != _focused_worker_id:
		_clear_first_clutch_control_cue()
		return
	var cue := StringName(String(_first_clutch.get(
		"cue",
		_first_clutch.get("step", _first_clutch.get("stage", "")),
	)).strip_edges().to_lower())
	var target: Button
	match cue:
		&"route", &"routing", &"match_route", &"specialty_route":
			var lane_text := String(_first_clutch.get(
				"lane",
				_first_clutch.get(
					"expected_lane",
					_first_clutch.get("specialty", _first_clutch.get("specialty_name", "")),
				),
			)).strip_edges().to_lower().replace(" ", "_")
			var lane := StringName(lane_text)
			if _assignment_buttons.has(lane):
				target = _assignment_buttons[lane]
		&"check_in", &"checkin", &"personnel", &"personnel_action":
			var focused_worker := _worker_snapshot(_focused_worker_id)
			var action_id := StringName(String(_first_clutch.get(
				"action_id",
				_first_clutch.get(
					"preferred_action",
					focused_worker.get("preferred_personnel_action", ""),
				),
			)))
			if _personnel_buttons.has(action_id):
				target = _personnel_buttons[action_id]
		&"priority_peck", &"peck", &"peck_assist":
			if not bool(_first_clutch.get("resume_required", false)):
				target = _peck_assist_button
	if (
		target != null
		and target == _first_clutch_cued_control
		and is_instance_valid(_first_clutch_cued_control)
	):
		return
	_clear_first_clutch_control_cue()
	if target == null:
		return
	_first_clutch_cued_control = target
	target.set_meta("first_clutch_cue", true)
	target.self_modulate = Color("fff4cf")
	_apply_first_clutch_cue_style(target)


func _clear_first_clutch_control_cue() -> void:
	if _first_clutch_cued_control == null:
		return
	if _first_clutch_cued_control != null and is_instance_valid(_first_clutch_cued_control):
		_first_clutch_cued_control.self_modulate = Color.WHITE
	_first_clutch_cued_control = null
	var focused_worker := _worker_snapshot(_focused_worker_id)
	var current_lane := StringName(String(focused_worker.get(
		"assignment",
		focused_worker.get("assigned_lane", &"auto"),
	)))
	for lane in ASSIGNMENT_ORDER:
		var assignment_button := _assignment_buttons.get(lane) as Button
		if assignment_button == null:
			continue
		assignment_button.set_meta("first_clutch_cue", false)
		assignment_button.set_meta("first_clutch_recommended_route", false)
		assignment_button.set_meta("first_clutch_current_route_demoted", false)
		assignment_button.accessibility_name = ""
		assignment_button.self_modulate = Color.WHITE
		if not focused_worker.is_empty():
			assignment_button.theme_type_variation = (
				&"SelectedChoiceButton" if lane == current_lane else &"DecisionChoiceButton"
			)
		for style_name in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
			assignment_button.remove_theme_stylebox_override(style_name)
	for action_id in PERSONNEL_ACTION_ORDER:
		var personnel_button := _personnel_buttons.get(action_id) as Button
		if personnel_button == null:
			continue
		personnel_button.set_meta("first_clutch_cue", false)
		personnel_button.self_modulate = Color.WHITE
		_apply_compact_personnel_style(personnel_button, action_id)
	if _peck_assist_button != null:
		_peck_assist_button.set_meta("first_clutch_cue", false)
		_peck_assist_button.self_modulate = Color.WHITE
		_apply_peck_assist_style(_peck_assist_button)


func _apply_first_clutch_cue_style(button: Button) -> void:
	var lane := StringName(String(button.get_meta("assignment_lane", "")))
	if lane in LANE_ORDER:
		var lane_color := _lane_color(lane)
		button.add_theme_stylebox_override(
			"normal",
			_compact_button_style(lane_color.darkened(0.58), lane_color.lightened(0.22), 3),
		)
		button.add_theme_stylebox_override(
			"hover",
			_compact_button_style(lane_color.darkened(0.42), lane_color.lightened(0.38), 3),
		)
		button.add_theme_stylebox_override(
			"pressed",
			_compact_button_style(lane_color.darkened(0.68), Color("fff0b8"), 3),
		)
		button.add_theme_stylebox_override(
			"disabled",
			_compact_button_style(lane_color.darkened(0.72), lane_color.darkened(0.24), 2),
		)
		button.add_theme_stylebox_override(
			"focus",
			_compact_button_style(Color(0.0, 0.0, 0.0, 0.0), Color("fff0aa"), 2),
		)
		return
	var personnel_action := StringName(String(button.get_meta("personnel_action_id", "")))
	if personnel_action == &"share_credit":
		button.add_theme_stylebox_override(
			"normal",
			_compact_button_style(Color("294b43"), Color("8fc9b8"), 3),
		)
		button.add_theme_stylebox_override(
			"hover",
			_compact_button_style(Color("356052"), Color("c4eadf"), 3),
		)
		button.add_theme_stylebox_override(
			"pressed",
			_compact_button_style(Color("1d3535"), Color("fff0b8"), 3),
		)
		button.add_theme_stylebox_override(
			"disabled",
			_compact_button_style(Color("1b2928"), Color("456f68"), 2),
		)
		button.add_theme_stylebox_override(
			"focus",
			_compact_button_style(Color(0.0, 0.0, 0.0, 0.0), Color("fff0aa"), 2),
		)
		return
	button.add_theme_stylebox_override(
		"normal",
		_compact_button_style(Color("4d4128"), Color("f0c968"), 2),
	)
	button.add_theme_stylebox_override(
		"hover",
		_compact_button_style(Color("65502b"), Color("ffe49a"), 2),
	)
	button.add_theme_stylebox_override(
		"pressed",
		_compact_button_style(Color("302719"), Color("fff0b8"), 2),
	)
	button.add_theme_stylebox_override(
		"disabled",
		_compact_button_style(Color("27281f"), Color("9f874f"), 2),
	)
	button.add_theme_stylebox_override(
		"focus",
		_compact_button_style(Color(0.0, 0.0, 0.0, 0.0), Color("fff0aa"), 2),
	)


func _refresh_queue_contract_badge(routing: Dictionary) -> void:
	var summary := _market_contract_queue_summary(routing)
	_refresh_contract_badge(_queue_contract_badge, summary)
	_queue_title_label.visible = summary.is_empty()


func _market_contract_queue_summary(routing: Dictionary) -> Dictionary:
	var queue_items_variant: Variant = routing.get(
		"queue_items",
		_snapshot.get("claim_queue_items", {}),
	)
	if not queue_items_variant is Dictionary:
		return {}
	var queue_items := queue_items_variant as Dictionary
	var contract_claims: Array[Dictionary] = []
	var has_rush := false
	for lane in LANE_ORDER:
		var lane_items_variant: Variant = queue_items.get(
			lane,
			queue_items.get(String(lane), []),
		)
		if not lane_items_variant is Array:
			continue
		for claim_value in lane_items_variant as Array:
			if not claim_value is Dictionary:
				continue
			var claim := claim_value as Dictionary
			if not bool(claim.get("market_contract", false)):
				continue
			contract_claims.append(claim)
			has_rush = has_rush or bool(claim.get("market_contract_rush", false))
	if contract_claims.is_empty():
		return {}

	# If any rush folders are waiting, disclose the nearest rush deadline. A
	# normal binder otherwise reports the nearest contracted-folder deadline.
	var deadline_claim: Dictionary = {}
	var nearest_minutes := 2147483647
	for claim in contract_claims:
		if has_rush and not bool(claim.get("market_contract_rush", false)):
			continue
		var minutes_until_deadline := int(claim.get("minutes_until_deadline", 2147483647))
		if deadline_claim.is_empty() or minutes_until_deadline < nearest_minutes:
			deadline_claim = claim
			nearest_minutes = minutes_until_deadline
	return {
		"market_contract": true,
		"market_contract_name": String(deadline_claim.get(
			"market_contract_name",
			"MUTUAL BINDER",
		)),
		"market_contract_rush": has_rush,
		"market_contract_deadline_time": String(deadline_claim.get(
			"market_contract_deadline_time",
			"END OF SHIFT",
		)),
		"market_contract_queue_count": contract_claims.size(),
	}


func _refresh_contract_badge(badge: Label, claim: Dictionary) -> void:
	if badge == null:
		return
	var contracted := bool(claim.get("market_contract", false))
	badge.visible = contracted
	if not contracted:
		badge.text = ""
		badge.tooltip_text = ""
		return
	var rush := bool(claim.get("market_contract_rush", false))
	var badge_title := "CONTRACT RUSH" if rush else "MUTUAL BINDER"
	var deadline := String(claim.get(
		"market_contract_deadline_time",
		"END OF SHIFT",
	)).strip_edges().to_upper()
	if deadline.is_empty():
		deadline = "END OF SHIFT"
	badge.text = "%s  %s" % [badge_title, deadline]
	var binder_name := String(claim.get("market_contract_name", "MUTUAL BINDER")).strip_edges().to_upper()
	var queue_count := maxi(0, int(claim.get("market_contract_queue_count", 0)))
	badge.tooltip_text = "FARM MUTUAL / %s\nDisclosed deadline: %s." % [binder_name, deadline]
	if queue_count > 0:
		badge.tooltip_text += "\n%d contracted %s currently waiting in the routing trays." % [
			queue_count,
			"folder" if queue_count == 1 else "folders",
		]


func _worker_snapshot(worker_id: int) -> Dictionary:
	if worker_id < 0:
		return {}
	for worker_value in _snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return worker
	return {}


func first_clutch_skip_button_rect() -> Rect2:
	## Browser accessibility and production-path audits need the same authored
	## target the player sees. Publishing its settled canvas rectangle avoids
	## brittle guessed coordinates while leaving the button as the sole intent.
	if (
		_first_clutch_skip_button == null
		or not _first_clutch_skip_button.is_visible_in_tree()
	):
		return Rect2()
	return _first_clutch_skip_button.get_global_rect()


func _operations_snapshot() -> Dictionary:
	var operations_value: Variant = _snapshot.get("operations", {})
	if operations_value is Dictionary:
		return (operations_value as Dictionary).duplicate(true)
	return {}


func _worker_action_receipt(
	action_status: Dictionary,
	worker: Dictionary,
	worker_id: int,
) -> Dictionary:
	var active_day := int(action_status.get("day", _snapshot.get("day", 0)))
	var actions_value: Variant = action_status.get("actions", [])
	if actions_value is Array:
		for action_value in (actions_value as Array):
			if not action_value is Dictionary:
				continue
			var action := action_value as Dictionary
			if (
				int(action.get("worker_id", -1)) == worker_id
				and int(action.get("day", active_day)) == active_day
			):
				return action.duplicate(true)
	if (
		int(worker.get("last_personnel_action_day", -1)) == active_day
		and StringName(worker.get("last_personnel_action", &"")) != &""
	):
		var last_action := action_status.get("last_action", {}) as Dictionary
		if int(last_action.get("worker_id", worker_id)) == worker_id:
			return last_action.duplicate(true) if not last_action.is_empty() else {
				"day": active_day,
				"worker_id": worker_id,
				"worker_name": String(worker.get("name", "HEN")),
				"action_id": StringName(worker.get("last_personnel_action", &"")),
			}
	return {}


func _training_terms_snapshot() -> Dictionary:
	var care_value: Variant = _snapshot.get("flock_care", {})
	if care_value is Dictionary:
		var terms_value: Variant = (care_value as Dictionary).get("training_terms", {})
		if terms_value is Dictionary and not (terms_value as Dictionary).is_empty():
			return (terms_value as Dictionary).duplicate(true)
	var direct_value: Variant = _snapshot.get("training_terms", {})
	if direct_value is Dictionary:
		return (direct_value as Dictionary).duplicate(true)
	return {}


func _compact_number(value: float) -> String:
	var rounded := snappedf(value, 0.1)
	return str(roundi(rounded)) if is_equal_approx(rounded, float(roundi(rounded))) else "%.1f" % rounded


func _first_clutch_target_worker_id() -> int:
	return int(_first_clutch.get(
		"worker_id",
		_first_clutch.get("target_worker_id", -1),
	))


func _refresh_first_clutch_return_action(coach_visible: bool) -> void:
	if _first_clutch_return_button == null:
		return
	var target_worker_id := _first_clutch_target_worker_id()
	var pre_policy := bool(_first_clutch.get("pre_policy", false))
	var show_return := (
		coach_visible
		and target_worker_id >= 0
		and (pre_policy or target_worker_id != _focused_worker_id)
	)
	_first_clutch_return_button.visible = show_return
	_first_clutch_return_button.mouse_filter = (
		Control.MOUSE_FILTER_STOP if show_return else Control.MOUSE_FILTER_IGNORE
	)
	if not show_return:
		return
	var worker := _worker_snapshot(target_worker_id)
	var worker_name := String(worker.get("name", "HEN %d" % (target_worker_id + 1))).strip_edges()
	if worker_name.is_empty():
		worker_name = "HEN %d" % (target_worker_id + 1)
	if pre_policy:
		_first_clutch_return_button.custom_minimum_size.x = 166.0
		_first_clutch_return_button.text = "OPEN FIRST FILE  [ENTER]"
		_first_clutch_return_button.tooltip_text = "Open %s's live dossier, then choose the flock policy." % worker_name
		_first_clutch_return_button.accessibility_name = _first_clutch_return_button.tooltip_text
		_first_clutch_return_button.set_meta("first_clutch_action", &"open_target_file")
		return
	_first_clutch_return_button.custom_minimum_size.x = 108.0
	_first_clutch_return_button.text = "FIND %s" % worker_name.to_upper()
	_first_clutch_return_button.tooltip_text = "Find %s and reopen her work file without advancing the coach." % worker_name
	_first_clutch_return_button.accessibility_name = _first_clutch_return_button.tooltip_text
	_first_clutch_return_button.set_meta("first_clutch_action", &"focus_target")


func _on_dispatch_tray_pressed(lane: StringName) -> void:
	if not _interaction_enabled or lane not in LANE_ORDER:
		return
	_finish_dispatch_tray_arrival()
	dispatch_lane_requested.emit(lane)


func _on_assignment_pressed(lane: StringName) -> void:
	if _focused_worker_id < 0 or not _interaction_enabled:
		return
	assignment_requested.emit(_focused_worker_id, lane)


func _on_assignment_undo_pressed() -> void:
	if (
		_focused_worker_id < 0
		or not _interaction_enabled
		or _assignment_undo_button == null
		or _assignment_undo_button.disabled
		or not _assignment_undo_button.visible
	):
		return
	assignment_undo_requested.emit(_focused_worker_id)


func _on_claim_resolution_pressed(path_id: StringName) -> void:
	if (
		_focused_worker_id < 0
		or not _interaction_enabled
		or path_id not in [&"settle", &"deny", &"exception"]
	):
		return
	var worker := _worker_snapshot(_focused_worker_id)
	var claim := worker.get("current_claim", {}) as Dictionary
	var status := worker.get("claim_resolution_status", {}) as Dictionary
	var button := _claim_resolution_buttons.get(path_id) as Button
	if (
		claim.is_empty()
		or bool(claim.get("resolution_locked", false))
		or not bool(status.get("available", false))
		or button == null
		or button.disabled
	):
		return
	var definition := _claim_resolution_definition(path_id)
	if definition.is_empty():
		return
	_pending_claim_resolution_path = path_id
	_pending_claim_resolution_worker_id = _focused_worker_id
	_pending_claim_resolution_claim_id = int(claim.get("id", -1))
	_claim_resolution_origin = button
	var path_label := String(definition.get(
		"label",
		String(path_id).replace("_", " ").to_upper(),
	)).to_upper()
	var filing_label := String({
		&"settle": "SETTLEMENT",
		&"deny": "DENIAL",
		&"exception": "EXCEPTION",
	}.get(path_id, definition.get(
		"short_label",
		String(path_id).replace("_", " ").to_upper(),
	))).to_upper()
	var claimant_name := String(claim.get("claimant_name", "THIS CLAIMANT")).to_upper()
	var cost_cents := int(definition.get("cost_cents", 0))
	var beneficiary := String(definition.get("beneficiary", "DISCLOSED PARTY")).to_upper()
	var current_path := StringName(claim.get("resolution_path", &"standard"))
	var current_definition := _claim_resolution_definition(current_path)
	var current_label := String(current_definition.get(
		"short_label",
		"STANDARD",
	)).to_upper()
	var cost_copy := (
		"$0.00"
		if cost_cents == 0 else
		"-$%.2f" % (float(cost_cents) / 100.0)
	)
	_claim_resolution_confirmation.title = "FILE %s?" % path_label
	_claim_resolution_confirmation.ok_button_text = "FILE %s" % filing_label
	_claim_resolution_confirmation.cancel_button_text = "KEEP %s" % current_label
	_claim_resolution_confirmation.dialog_text = (
		"CLAIMANT  /  %s\n"
		+ "PATH  /  %s  ·  PERMANENT\n\n"
		+ "COST  /  %s FEED FUND\n"
		+ "HELPS  /  %s\n"
		+ "UPSIDE  /  %s\n"
		+ "TRADEOFF  /  %s\n\n"
		+ "NO CHANGE UNTIL YOU FILE."
	) % [
		claimant_name,
		path_label,
		cost_copy,
		beneficiary,
		String(definition.get("benefit", "See the disclosed path terms.")),
		String(definition.get("burden", "See the disclosed path terms.")),
	]
	var confirm_button := _claim_resolution_confirmation.get_ok_button()
	var cancel_button := _claim_resolution_confirmation.get_cancel_button()
	confirm_button.tooltip_text = (
		"Permanently file %s for %s. %s Feed Fund."
		% [path_label, claimant_name, cost_copy]
	)
	cancel_button.tooltip_text = (
		"Return to the claimant file with %s unchanged."
		% String(current_definition.get("label", "STANDARD HANDLING")).to_upper()
	)
	var accessible_copy := "%s %s Confirm: %s. Safe return: %s." % [
		_claim_resolution_confirmation.title,
		_claim_resolution_confirmation.dialog_text.replace("\n", " "),
		confirm_button.text,
		cancel_button.text,
	]
	_claim_resolution_confirmation.set_meta("accessible_text", accessible_copy)
	_claim_resolution_confirmation.get_label().set_meta(
		"accessible_text",
		accessible_copy,
	)
	_claim_resolution_confirmation.popup_centered_clamped(
		Vector2i(370, 330),
		0.92,
	)
	cancel_button.call_deferred("grab_focus")
	interaction_safety_changed.emit()


func _confirm_claim_resolution() -> void:
	if not _pending_claim_resolution_is_valid():
		_cancel_claim_resolution_confirmation(false)
		return
	var worker_id := _pending_claim_resolution_worker_id
	var path_id := _pending_claim_resolution_path
	_clear_pending_claim_resolution()
	if _claim_resolution_confirmation != null:
		_claim_resolution_confirmation.hide()
	claim_resolution_requested.emit(worker_id, path_id)
	interaction_safety_changed.emit()


func _cancel_claim_resolution_confirmation(restore_focus: bool = true) -> void:
	var origin := _claim_resolution_origin
	var had_pending := _pending_claim_resolution_path != &""
	_clear_pending_claim_resolution()
	if _claim_resolution_confirmation != null:
		_claim_resolution_confirmation.hide()
	if (
		restore_focus
		and origin != null
		and is_instance_valid(origin)
		and origin.is_visible_in_tree()
		and not origin.disabled
	):
		origin.call_deferred("grab_focus")
	if had_pending:
		interaction_safety_changed.emit()


func _clear_pending_claim_resolution() -> void:
	_pending_claim_resolution_path = &""
	_pending_claim_resolution_worker_id = -1
	_pending_claim_resolution_claim_id = -1
	_claim_resolution_origin = null


func _pending_claim_resolution_is_valid() -> bool:
	if _pending_claim_resolution_path == &"":
		return false
	if (
		not _interaction_enabled
		or _pending_claim_resolution_worker_id != _focused_worker_id
		or _pending_claim_resolution_path not in [&"settle", &"deny", &"exception"]
	):
		return false
	var worker := _worker_snapshot(_pending_claim_resolution_worker_id)
	var claim := worker.get("current_claim", {}) as Dictionary
	var status := worker.get("claim_resolution_status", {}) as Dictionary
	return (
		not claim.is_empty()
		and int(claim.get("id", -1)) == _pending_claim_resolution_claim_id
		and not bool(claim.get("resolution_locked", false))
		and bool(status.get("available", false))
	)


func _on_personnel_action_pressed(action_id: StringName) -> void:
	if _focused_worker_id < 0 or not _interaction_enabled:
		return
	var phase := int(_snapshot.get("shift_phase", 1))
	var action_status := _snapshot.get("personnel_action_status", {}) as Dictionary
	var has_allowance_status := action_status.has("limit") or action_status.has("remaining")
	var action_limit := maxi(1, int(action_status.get("limit", 1)))
	var actions_used := clampi(
		int(action_status.get(
			"used",
			1 if bool(_snapshot.get("personnel_action_used", false)) else 0,
		)),
		0,
		action_limit,
	)
	var actions_remaining := clampi(
		int(action_status.get("remaining", action_limit - actions_used)),
		0,
		action_limit,
	)
	var action_available := bool(action_status.get(
		"available",
		_snapshot.get("personnel_action_available", false),
	))
	var worker := _worker_snapshot(_focused_worker_id)
	var worker_action_filed := not _worker_action_receipt(
		action_status,
		worker,
		_focused_worker_id,
	).is_empty()
	var legacy_global_lock := not has_allowance_status and bool(_snapshot.get("personnel_action_used", false))
	if (
		phase != 1
		or not bool(worker.get("employed", true))
		or not action_available
		or actions_remaining <= 0
		or worker_action_filed
		or legacy_global_lock
	):
		return
	personnel_action_requested.emit(_focused_worker_id, action_id)


func request_focused_peck_assist() -> bool:
	if _focused_worker_id < 0 or _peck_assist_button == null or _peck_assist_button.disabled:
		return false
	arm_peck_result_focus_handoff(_focused_worker_id)
	peck_assist_requested.emit(_focused_worker_id)
	if String(_peck_result_focus_handoff.get("status", "")) == "armed":
		_cancel_peck_result_focus_handoff("assist_not_committed")
	return true


## Arms a narrowly scoped accessibility repair. It is valid only while the
## player's focus is on the live Priority Peck button; an accepted synchronous
## snapshot may then move that stranded focus to the already-visible next intent.
## It never changes dossier tabs or emits an action.
func arm_peck_result_focus_handoff(worker_id: int) -> bool:
	if (
		worker_id != _focused_worker_id
		or _peck_assist_button == null
		or _peck_assist_button.disabled
		or not _interaction_enabled
	):
		return false
	var viewport := get_viewport()
	if viewport == null or viewport.gui_get_focus_owner() != _peck_assist_button:
		return false
	var worker := _worker_snapshot(worker_id)
	var claim := worker.get("current_claim", {}) as Dictionary
	if claim.is_empty():
		return false
	_peck_result_focus_handoff = {
		"status": "armed",
		"worker_id": worker_id,
		"claim_id": int(claim.get("id", -1)),
		"target": "",
		"action_id": "",
		"serial": int(_peck_result_focus_handoff.get("serial", 0)),
		"reason": "",
	}
	set_meta("peck_result_focus_handoff_status", "armed")
	return true


func cancel_peck_result_focus_handoff(reason: String = "cancelled") -> void:
	_cancel_peck_result_focus_handoff(reason)


func peck_result_focus_handoff_state() -> Dictionary:
	return _peck_result_focus_handoff.duplicate(true)


func _repair_committed_peck_focus() -> void:
	if String(_peck_result_focus_handoff.get("status", "")) != "armed":
		return
	var worker_id := int(_peck_result_focus_handoff.get("worker_id", -1))
	var claim_id := int(_peck_result_focus_handoff.get("claim_id", -1))
	var last_assist := _snapshot.get("last_peck_assist", {}) as Dictionary
	if (
		worker_id != _focused_worker_id
		or int(last_assist.get("worker_id", -1)) != worker_id
		or int(last_assist.get("claim_id", -1)) != claim_id
	):
		return
	var viewport := get_viewport()
	var focus_owner := viewport.gui_get_focus_owner() if viewport != null else null
	# During this synchronous result refresh Godot may retain the disabled button
	# or release it to null. Any different control means the player deliberately
	# chose another context and must never be redirected.
	if focus_owner != null and focus_owner != _peck_assist_button:
		_cancel_peck_result_focus_handoff("focus_changed")
		return
	var action_id := StringName(_hen_intent_button.get_meta("action_id", &"")) if _hen_intent_button != null else &""
	if (
		_hen_intent_button == null
		or not _hen_intent_button.is_visible_in_tree()
		or _hen_intent_button.disabled
		or action_id in [&"", &"peck"]
	):
		_cancel_peck_result_focus_handoff("next_action_unavailable")
		return
	_hen_intent_button.grab_focus()
	var next_serial := int(_peck_result_focus_handoff.get("serial", 0)) + 1
	_peck_result_focus_handoff = {
		"status": "completed",
		"worker_id": worker_id,
		"claim_id": claim_id,
		"target": String(_hen_intent_button.name),
		"action_id": String(action_id),
		"serial": next_serial,
		"reason": "disabled_origin_repaired",
	}
	set_meta("peck_result_focus_handoff_status", "completed")
	set_meta("peck_result_focus_handoff_serial", next_serial)


func _cancel_peck_result_focus_handoff(reason: String) -> void:
	if String(_peck_result_focus_handoff.get("status", "")) != "armed":
		return
	_peck_result_focus_handoff["status"] = "cancelled"
	_peck_result_focus_handoff["reason"] = reason
	set_meta("peck_result_focus_handoff_status", "cancelled")


func _on_peck_assist_pressed() -> void:
	request_focused_peck_assist()


func _refresh_hen_intent(worker: Dictionary) -> void:
	if _hen_intent_button == null:
		return
	var intent := worker.get("hen_intent", {}) as Dictionary
	var coach_active := bool(_first_clutch.get("visible", false))
	_hen_intent_button.visible = not coach_active and not intent.is_empty()
	if intent.is_empty():
		_reset_hen_intent_transition()
		_last_hen_intent_key = ""
		_hen_intent_button.icon = null
		_hen_intent_button.set_meta("action_id", &"")
		_hen_intent_button.set_meta("intent_icon", &"")
		_hen_intent_button.set_meta("accessible_text", "")
		return
	var icon := StringName(String(intent.get("icon", "steady")))
	var urgency := clampi(int(intent.get("urgency", 1)), 1, 3)
	var action_id := StringName(String(intent.get("action_id", "route")))
	var action_label := String(intent.get("action_label", "OPEN")).to_upper()
	var choice_intent := StringName(String(intent.get("id", ""))) == &"choice"
	var outcome_cutoff := clampi(int(intent.get("cutoff_progress", 55)), 1, 99)
	var visual_action_label := (
		"OUTCOME <%d%%" % outcome_cutoff
		if choice_intent else
		action_label
	)
	var intent_key := "%s|%s|%s" % [String(icon), String(action_id), action_label]
	var previous_intent_key := _last_hen_intent_key
	var detail := String(intent.get("detail", "Open this hen's next useful action."))
	var action_available := _interaction_enabled and bool(intent.get("actionable", true))
	if action_id == &"peck":
		var peck_available := _peck_assist_button != null and not _peck_assist_button.disabled
		action_available = action_available and peck_available
		if _peck_assist_button != null and (
			not peck_available or bool(_peck_assist_button.get_meta("resume_required", false))
		):
			detail = "%s\n%s" % [detail, _peck_assist_button.tooltip_text]
	_hen_intent_button.icon = ChickenView.hen_intent_icon_texture(icon, -1, urgency)
	_hen_intent_button.text = (
		visual_action_label
		if choice_intent else
		"%s  ›" % visual_action_label
	)
	_hen_intent_button.add_theme_font_size_override("font_size", 9 if choice_intent else 10)
	_hen_intent_button.tooltip_text = detail
	_hen_intent_button.set_meta("action_id", action_id)
	_hen_intent_button.set_meta("intent_icon", icon)
	_hen_intent_button.set_meta("outcome_cutoff_progress", outcome_cutoff if choice_intent else -1)
	_hen_intent_button.set_meta("accessible_text", "%s. %s" % [action_label, detail])
	_hen_intent_button.disabled = not action_available
	_hen_intent_button.theme_type_variation = (
		&"PrimaryButton" if urgency >= 3 else &"DecisionChoiceButton"
	)
	# A committed Priority Peck can leave keyboard focus on this same compact
	# action while the authoritative file advances from working to laying. Keep
	# the diagnostic handoff receipt aligned with the action now under focus; this
	# updates no tab, focus, or economic state.
	var viewport := get_viewport()
	if (
		String(_peck_result_focus_handoff.get("status", "")) == "completed"
		and String(_peck_result_focus_handoff.get("target", "")) == String(_hen_intent_button.name)
		and viewport != null
		and viewport.gui_get_focus_owner() == _hen_intent_button
	):
		_peck_result_focus_handoff["action_id"] = String(action_id)
	_last_hen_intent_key = intent_key
	if not previous_intent_key.is_empty() and previous_intent_key != intent_key:
		_play_hen_intent_transition(previous_intent_key, intent_key, urgency)


func _play_hen_intent_transition(from_key: String, to_key: String, urgency: int) -> void:
	_reset_hen_intent_transition()
	_hen_intent_transition_serial += 1
	_hen_intent_button.set_meta("intent_transition_serial", _hen_intent_transition_serial)
	_hen_intent_button.set_meta("intent_transition_from", from_key)
	_hen_intent_button.set_meta("intent_transition_to", to_key)
	_hen_intent_button.set_meta("intent_transition_animated", not _reduced_motion)
	if _reduced_motion:
		return
	var transition_color := Color("8dcfbd")
	if urgency >= 3:
		transition_color = Color("f1d681")
	elif urgency == 2:
		transition_color = Color("e6a07e")
	_hen_intent_button.pivot_offset = _hen_intent_button.size * 0.5
	_hen_intent_button.scale = Vector2(0.95, 0.95)
	_hen_intent_button.self_modulate = transition_color.lightened(0.24)
	_hen_intent_transition_tween = create_tween().bind_node(_hen_intent_button).set_parallel(true)
	_hen_intent_transition_tween.tween_property(
		_hen_intent_button,
		"scale",
		Vector2.ONE,
		0.2,
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hen_intent_transition_tween.tween_property(
		_hen_intent_button,
		"self_modulate",
		Color.WHITE,
		0.3,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _reset_hen_intent_transition() -> void:
	if _hen_intent_transition_tween != null and _hen_intent_transition_tween.is_valid():
		_hen_intent_transition_tween.kill()
	_hen_intent_transition_tween = null
	if _hen_intent_button != null:
		_hen_intent_button.scale = Vector2.ONE
		_hen_intent_button.self_modulate = Color.WHITE


func _on_hen_intent_pressed() -> void:
	if _hen_intent_button == null or _hen_intent_button.disabled:
		return
	var action_id := StringName(_hen_intent_button.get_meta("action_id", &"route"))
	match action_id:
		&"peck":
			request_focused_peck_assist()
		&"claim":
			_on_dossier_tab_pressed(&"claim")
		&"support":
			_on_dossier_tab_pressed(&"support")
		&"profile":
			_on_dossier_tab_pressed(&"profile")
		_:
			_on_dossier_tab_pressed(&"route")


func _on_first_clutch_skip_pressed() -> void:
	first_clutch_skip_requested.emit()


func _on_first_clutch_return_pressed() -> void:
	var target_worker_id := _first_clutch_target_worker_id()
	if target_worker_id < 0 or _first_clutch_return_button == null or not _first_clutch_return_button.visible:
		return
	first_clutch_focus_requested.emit(target_worker_id)


func _on_details_pressed() -> void:
	if _focused_worker_id < 0:
		return
	_details_expanded = not _details_expanded
	# Refresh restores the full profile copy before presentation disclosure is
	# re-applied; collapsing then returns to the compact specialty summary.
	_refresh()


func _personnel_definition(action_id: StringName) -> Dictionary:
	var catalog_value: Variant = _snapshot.get("personnel_catalog", [])
	if catalog_value is Dictionary:
		var catalog := catalog_value as Dictionary
		return catalog.get(action_id, catalog.get(String(action_id), {})) as Dictionary
	if catalog_value is Array:
		for entry_value in (catalog_value as Array):
			var entry := entry_value as Dictionary
			if StringName(entry.get("id", &"")) == action_id:
				return entry
	return {}


func _claim_resolution_definition(path_id: StringName) -> Dictionary:
	var catalog_value: Variant = _snapshot.get("claim_resolution_catalog", [])
	if catalog_value is Dictionary:
		var catalog := catalog_value as Dictionary
		return catalog.get(path_id, catalog.get(String(path_id), {})) as Dictionary
	if catalog_value is Array:
		for entry_value in (catalog_value as Array):
			var entry := entry_value as Dictionary
			if StringName(entry.get("id", &"")) == path_id:
				return entry
	return {}


func _lane_name(lane: StringName) -> String:
	var display := String(LANE_NAMES.get(lane, String(lane).replace("_", " ").to_upper()))
	return SemanticColorPaletteScript.marked_lane_name(display, lane, _color_vision_mode)


func _lane_action_name(lane: StringName) -> String:
	var display := String(LANE_ACTION_NAMES.get(
		lane,
		LANE_NAMES.get(lane, String(lane).replace("_", " ").to_upper()),
	))
	return SemanticColorPaletteScript.marked_lane_name(display, lane, _color_vision_mode)


func _lane_short_name(lane: StringName) -> String:
	var display := String(LANE_SHORT_NAMES.get(lane, String(lane).replace("_", " ").to_upper()))
	return SemanticColorPaletteScript.marked_lane_name(display, lane, _color_vision_mode)


func _lane_queue_icon(lane: StringName) -> StringName:
	match lane:
		&"nest_damage": return &"lane_nest"
		&"predator_loss": return &"lane_predator"
		&"appeals": return &"lane_appeals"
	return &"order_trays"


func _refresh_worker_identity_marks(specialty: StringName) -> void:
	if _worker_profile_icon != null:
		_worker_profile_icon.texture = ManagementUIThemeScript.action_icon(&"rank_crest")
		_worker_profile_icon.set_meta("semantic_icon", &"rank_crest")
	if _worker_specialty_icon == null:
		return
	var semantic_icon := _lane_queue_icon(specialty)
	_worker_specialty_icon.texture = ManagementUIThemeScript.action_icon(semantic_icon)
	_worker_specialty_icon.set_meta("semantic_icon", semantic_icon)
	_worker_specialty_icon.set_meta("specialty_lane", specialty)


func _lane_color(lane: StringName) -> Color:
	return SemanticColorPaletteScript.lane_color(lane, _color_vision_mode)


func _assignment_tooltip(lane: StringName) -> String:
	var full_label := String(LANE_NAMES.get(
		lane,
		String(lane).replace("_", " ").to_upper(),
	))
	var base := "%s. Assign this peckwork tray." % full_label
	match lane:
		&"auto":
			return "%s. Pull the most urgent file, favoring this hen's specialty when deadlines allow. AUTO uses standard handling until management files a claimant path." % full_label
		&"nest_damage":
			base = "%s. Pull only routine nest and coop property files." % full_label
		&"predator_loss":
			base = "%s. Pull only time-sensitive predator and loss files." % full_label
		&"appeals":
			base = "%s. Pull only complex appeals and exception files." % full_label
	var catalog := _snapshot.get("routing_catalog", []) as Array
	for entry_value in catalog:
		var entry := entry_value as Dictionary
		if StringName(entry.get("id", &"")) != lane:
			continue
		var tradeoff := String(entry.get("operational_tradeoff", ""))
		return "%s\n%s" % [base, tradeoff] if not tradeoff.is_empty() else base
	return base


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_contract_badge(control_name: String, minimum_width: float) -> Label:
	var badge := _make_label("", 9, Color("f6df9d"))
	badge.name = control_name
	badge.custom_minimum_size = Vector2(minimum_width, 22.0)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override(
		"normal",
		_compact_button_style(Color("4a3523"), Color("d6ab5f"), 1),
	)
	badge.visible = false
	return badge


func _apply_compact_personnel_style(button: Button, action_id: StringName) -> void:
	var normal_color := Color("263842")
	var border_color := Color("647780")
	var hover_color := Color("31504f")
	if action_id == &"share_credit":
		normal_color = Color("29453f")
		border_color = Color("5b9b8d")
		hover_color = Color("356052")
	elif action_id == &"quota_pressure":
		normal_color = Color("4b302f")
		border_color = Color("a95748")
		hover_color = Color("633a35")
	button.add_theme_stylebox_override("normal", _compact_button_style(normal_color, border_color, 1))
	button.add_theme_stylebox_override("hover", _compact_button_style(hover_color, Color("e0bd68"), 2))
	button.add_theme_stylebox_override("pressed", _compact_button_style(Color("172832"), Color("f0cb70"), 2))
	button.add_theme_stylebox_override("disabled", _compact_button_style(Color("151d25"), Color("303b45"), 1))
	button.add_theme_stylebox_override("focus", _compact_button_style(Color(0.0, 0.0, 0.0, 0.0), Color("e0bd68"), 2))


func _apply_peck_assist_style(button: Button) -> void:
	button.add_theme_color_override("font_color", Color("fff1bd"))
	button.add_theme_color_override("font_hover_color", Color("fff8dc"))
	button.add_theme_color_override("font_disabled_color", Color("73808a"))
	button.add_theme_stylebox_override("normal", _compact_button_style(Color("5a4528"), Color("d9ad51"), 2))
	button.add_theme_stylebox_override("hover", _compact_button_style(Color("74572d"), Color("f3d477"), 2))
	button.add_theme_stylebox_override("pressed", _compact_button_style(Color("34291d"), Color("fff0aa"), 2))
	button.add_theme_stylebox_override("disabled", _compact_button_style(Color("182229"), Color("394851"), 1))
	button.add_theme_stylebox_override("focus", _compact_button_style(Color("5a4528"), Color("fff0aa"), 2))


func _compact_button_style(color: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := _panel_style(color, color.a, border, 6, border_width)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	return style


func _panel_style(color: Color, opacity: float, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, opacity)
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
