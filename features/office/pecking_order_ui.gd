class_name PeckingOrderUI
extends VBoxContainer

## Compact, presentation-only flock leaderboard for the Flockwatch ledger.
##
## The authoritative simulation supplies ranked rows through `pecking_order`.
## This component filters out non-employees, preserves the supplied rank order,
## and emits a worker id when management selects a row for inspection.

signal worker_selected(worker_id: int)

const COLOR_BRASS := Color("e7c56e")
const COLOR_TEAL := Color("73b5a7")
const COLOR_INK := Color("eef1df")
const COLOR_MUTED := Color("aeb8c4")
const COLOR_RUST := Color("d68a68")

var _snapshot: Dictionary = {}
var _display_rows: Array[Dictionary] = []
var _showing_last_shift := false

var _mode_label: Label
var _caption_label: Label
var _rows_host: VBoxContainer
var _empty_label: Label
var _leader_label: Label


func _ready() -> void:
	name = "PeckingOrderUI"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	_build_interface()
	_refresh()


func apply_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	if _rows_host != null:
		_refresh()


## Concise copy suitable for the closed Flockwatch button or a tooltip.
func leader_summary() -> String:
	if _display_rows.is_empty():
		return "PECKING ORDER // NO ACTIVE RANKING"
	var leader := _display_rows[0]
	var prefix := "LAST SHIFT // " if _showing_last_shift else ""
	return "%s#%d %s // %s" % [
		prefix,
		int(leader.get("rank", 1)),
		String(leader.get("worker_name", "HEN")).to_upper(),
		_egg_count_copy(int(leader.get("eggs", 0))),
	]


func _build_interface() -> void:
	var heading_row := HBoxContainer.new()
	heading_row.name = "PeckingOrderHeadingRow"
	heading_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_theme_constant_override("separation", 8)
	add_child(heading_row)

	var heading := _make_label("PECKING ORDER", 17, COLOR_BRASS)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.clip_text = true
	heading_row.add_child(heading)

	_mode_label = _make_label("LIVE SHIFT", 10, COLOR_TEAL)
	_mode_label.name = "PeckingOrderMode"
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_mode_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mode_label.clip_text = true
	_mode_label.custom_minimum_size.x = 0.0
	heading_row.add_child(_mode_label)

	_caption_label = _make_label(
		"Ranked by credited basket value; goldens, fewer cracks, then employee number break ties.",
		11,
		COLOR_MUTED,
	)
	_caption_label.name = "PeckingOrderCaption"
	_caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_caption_label)

	_rows_host = VBoxContainer.new()
	_rows_host.name = "PeckingOrderRows"
	_rows_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_host.add_theme_constant_override("separation", 5)
	add_child(_rows_host)

	_empty_label = _make_label(
		"No active hens have entered the credited-output ledger.",
		12,
		COLOR_MUTED,
	)
	_empty_label.name = "PeckingOrderEmpty"
	_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows_host.add_child(_empty_label)

	_leader_label = _make_label("LEADER // AWAITING FIRST EGG", 11, COLOR_BRASS)
	_leader_label.name = "PeckingOrderLeaderSummary"
	_leader_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_leader_label)


func _refresh() -> void:
	var current_rows := _normalized_rows(_snapshot.get("pecking_order", []))
	var last_rows := _normalized_rows(_snapshot.get("last_pecking_order", []))
	_showing_last_shift = (
		_total_eggs(current_rows) <= 0
		and not last_rows.is_empty()
		and _total_eggs(last_rows) > 0
	)
	_display_rows = (last_rows if _showing_last_shift else current_rows).duplicate(true)

	_clear_rows()
	_empty_label = null
	if _display_rows.is_empty():
		_empty_label = _make_label(
			"No active hens have entered the credited-output ledger.",
			12,
			COLOR_MUTED,
		)
		_empty_label.name = "PeckingOrderEmpty"
		_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_rows_host.add_child(_empty_label)
	else:
		for row in _display_rows:
			_rows_host.add_child(_build_worker_row(row))

	if _showing_last_shift:
		var completed_day := int(_snapshot.get("last_pecking_order_day", 0))
		_mode_label.text = (
			"LAST SHIFT // DAY %d" % completed_day
			if completed_day > 0 else
			"LAST SHIFT"
		)
		_mode_label.add_theme_color_override("font_color", COLOR_BRASS)
		_caption_label.text = "Last shift, ranked by credited basket value; goldens and fewer cracks break ties."
	else:
		_mode_label.text = "LIVE SHIFT"
		_mode_label.add_theme_color_override("font_color", COLOR_TEAL)
		_caption_label.text = "Ranked by credited basket value; goldens, fewer cracks, then employee number break ties."

	_leader_label.text = (
		"LEADER // %s" % leader_summary()
		if not _display_rows.is_empty() else
		"LEADER // AWAITING FIRST EGG"
	)
	_leader_label.tooltip_text = _leader_tooltip()


func _build_worker_row(row: Dictionary) -> Button:
	var worker_id := int(row.get("worker_id", -1))
	var rank := int(row.get("rank", 1))
	var worker_name := String(row.get("worker_name", "HEN %d" % (worker_id + 1)))
	var eggs := int(row.get("eggs", 0))
	var sound := int(row.get("sound", 0))
	var cracked := int(row.get("cracked", 0))
	var golden := int(row.get("golden", 0))
	var credit_cents := int(row.get("credit_cents", 0))

	var button := Button.new()
	button.name = "PeckingOrderRow_%d" % worker_id
	button.theme_type_variation = &"SelectedChoiceButton" if rank == 1 else &"DecisionChoiceButton"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = true
	button.custom_minimum_size = Vector2(0.0, 50.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 12)
	button.text = "#%d  ·  %s  ·  $%.2f\n%s  ·  SOUND %d  ·  GOLD %d  ·  CRACK %d" % [
		rank,
		worker_name.to_upper(),
		float(credit_cents) / 100.0,
		_egg_count_copy(eggs),
		sound,
		golden,
		cracked,
	]
	button.tooltip_text = (
		"%s // Rank #%d\n%s: %d sound, %d golden, %d cracked.\n"
		+ "$%.2f credited. Select to inspect this hen."
	) % [
		worker_name,
		rank,
		_egg_count_copy(eggs),
		sound,
		golden,
		cracked,
		credit_cents / 100.0,
	]
	button.set_meta("worker_id", worker_id)
	button.set_meta("rank", rank)
	button.set_meta("source", &"last_shift" if _showing_last_shift else &"live")
	button.pressed.connect(func() -> void: worker_selected.emit(worker_id))
	return button


func _normalized_rows(raw_rows: Variant) -> Array[Dictionary]:
	var source: Variant = raw_rows
	if source is Dictionary:
		source = (source as Dictionary).get("rows", [])
	var normalized: Array[Dictionary] = []
	if not source is Array:
		return normalized
	var fallback_rank := 1
	for row_value: Variant in source as Array:
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		if not bool(row.get("employed", true)):
			continue
		var worker_id := int(row.get("worker_id", -1))
		if worker_id < 0:
			continue
		var rank := int(row.get("rank", fallback_rank))
		normalized.append({
			"rank": maxi(1, rank),
			"worker_id": worker_id,
			"worker_name": String(row.get("worker_name", row.get("name", "HEN %d" % (worker_id + 1)))),
			"eggs": maxi(0, int(row.get("eggs", 0))),
			"sound": maxi(0, int(row.get("sound", 0))),
			"cracked": maxi(0, int(row.get("cracked", 0))),
			"golden": maxi(0, int(row.get("golden", 0))),
			"credit_cents": maxi(0, int(row.get("credit_cents", 0))),
			"employed": true,
		})
		fallback_rank += 1
	normalized.sort_custom(_row_precedes)
	return normalized


func _row_precedes(first: Dictionary, second: Dictionary) -> bool:
	var first_rank := int(first.get("rank", 999))
	var second_rank := int(second.get("rank", 999))
	if first_rank != second_rank:
		return first_rank < second_rank
	var first_eggs := int(first.get("eggs", 0))
	var second_eggs := int(second.get("eggs", 0))
	if first_eggs != second_eggs:
		return first_eggs > second_eggs
	var first_golden := int(first.get("golden", 0))
	var second_golden := int(second.get("golden", 0))
	if first_golden != second_golden:
		return first_golden > second_golden
	var first_cracked := int(first.get("cracked", 0))
	var second_cracked := int(second.get("cracked", 0))
	if first_cracked != second_cracked:
		return first_cracked < second_cracked
	return int(first.get("worker_id", 999)) < int(second.get("worker_id", 999))


func _total_eggs(rows: Array[Dictionary]) -> int:
	var total := 0
	for row in rows:
		total += int(row.get("eggs", 0))
	return total


func _leader_tooltip() -> String:
	if _display_rows.is_empty():
		return "No employed hen currently has a ranked output record."
	var leader := _display_rows[0]
	return "%s\n$%.2f credited%s" % [
		leader_summary(),
		int(leader.get("credit_cents", 0)) / 100.0,
		" in the completed shift." if _showing_last_shift else " during the live shift.",
	]


func _clear_rows() -> void:
	for child: Node in _rows_host.get_children():
		_rows_host.remove_child(child)
		child.queue_free()


func _egg_count_copy(eggs: int) -> String:
	return "%d EGG%s" % [eggs, "" if eggs == 1 else "S"]


func _make_label(copy: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
