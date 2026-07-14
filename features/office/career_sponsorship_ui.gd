class_name CareerSponsorshipUI
extends VBoxContainer

## Compact, report-embedded intent surface for Senior Roost career sponsorship.
##
## This component never mutates career or economy state. It defensively filters
## invalid specialty choices, explains why authorization is held, and emits one
## stable worker/lane intent for an authoritative owner to resolve.

signal sponsorship_requested(worker_id: int, lane_id: StringName)

const ManagementTheme := preload("res://features/office/management_ui_theme.gd")
const DEFAULT_MARK_COST := 3
const DEFAULT_FUND_COST_CENTS := 1200
const TRAINING_THROUGHPUT_PERCENT := 15
const DAILY_WAGE_DELTA_CENTS := 100

const COLOR_INK := Color("e9edf0")
const COLOR_MUTED := Color("9eabb5")
const COLOR_BRASS := Color("d1a650")
const COLOR_TEAL := Color("73b5a7")
const COLOR_RUST := Color("c96f59")
const COLOR_NAVY := Color("18232e")
const COLOR_NAVY_RAISED := Color("223541")

var _snapshot: Dictionary = {}
var _workers: Array[Dictionary] = []
var _lanes: Array[Dictionary] = []
var _selected_worker_id := -1
var _selected_lane_id: StringName = &""
var _available_marks := 0
var _mark_cost := DEFAULT_MARK_COST
var _fund_cost_cents := DEFAULT_FUND_COST_CENTS
var _refreshing := false

var _balance_label: Label
var _worker_selector: OptionButton
var _worker_detail_label: Label
var _lane_selector: OptionButton
var _terms_label: Label
var _reason_label: Label
var _authorize_button: Button


func _ready() -> void:
	name = "CareerSponsorshipUI"
	theme = ManagementTheme.create_theme()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 7)
	_build_interface()
	_refresh()


func apply_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_available_marks = maxi(0, int(_snapshot.get("available_marks", 0)))
	_mark_cost = maxi(0, int(_snapshot.get("mark_cost", DEFAULT_MARK_COST)))
	_fund_cost_cents = maxi(0, int(_snapshot.get("fund_cost_cents", DEFAULT_FUND_COST_CENTS)))
	visible = bool(_snapshot.get("visible", false))
	_refresh()


func selected_worker_id() -> int:
	return _selected_worker_id


func selected_lane_id() -> StringName:
	return _selected_lane_id


func authorization_reason() -> String:
	return _authorization_reason()


func _build_interface() -> void:
	var heading := _make_label("CAREER SPONSORSHIP", 17, COLOR_BRASS)
	heading.name = "CareerSponsorshipHeading"
	add_child(heading)

	var optional_note := _make_label(
		"OPTIONAL  //  Bank every Roost Mark for a later quarter, or sponsor one hen now.",
		12,
		COLOR_TEAL,
	)
	optional_note.name = "CareerSponsorshipOptionalNote"
	optional_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(optional_note)

	var panel := PanelContainer.new()
	panel.name = "CareerSponsorshipPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 11)
	margin.add_theme_constant_override("margin_right", 11)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var form := VBoxContainer.new()
	form.name = "CareerSponsorshipForm"
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 6)
	margin.add_child(form)

	_balance_label = _make_label("AVAILABLE  0 ROOST MARKS", 12, COLOR_BRASS)
	_balance_label.name = "CareerSponsorshipBalance"
	_balance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form.add_child(_balance_label)

	var worker_caption := _make_label("HEN CANDIDATE", 11, COLOR_MUTED)
	worker_caption.name = "CareerSponsorshipHenLabel"
	form.add_child(worker_caption)

	_worker_selector = OptionButton.new()
	_worker_selector.name = "CareerSponsorshipHenSelector"
	_configure_selector(_worker_selector)
	_worker_selector.item_selected.connect(_on_worker_selected)
	form.add_child(_worker_selector)

	_worker_detail_label = _make_label("Select a hen to inspect her current career file.", 11, COLOR_MUTED)
	_worker_detail_label.name = "CareerSponsorshipWorkerDetail"
	_worker_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form.add_child(_worker_detail_label)

	var lane_caption := _make_label("ALTERNATE PECKWORK SPECIALTY", 11, COLOR_MUTED)
	lane_caption.name = "CareerSponsorshipLaneLabel"
	form.add_child(lane_caption)

	_lane_selector = OptionButton.new()
	_lane_selector.name = "CareerSponsorshipLaneSelector"
	_configure_selector(_lane_selector)
	_lane_selector.item_selected.connect(_on_lane_selected)
	form.add_child(_lane_selector)

	_terms_label = _make_label("", 11, COLOR_INK)
	_terms_label.name = "CareerSponsorshipTerms"
	_terms_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form.add_child(_terms_label)

	_reason_label = _make_label("", 11, COLOR_RUST)
	_reason_label.name = "CareerSponsorshipUnavailableReason"
	_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason_label.visible = false
	form.add_child(_reason_label)

	_authorize_button = Button.new()
	_authorize_button.name = "CareerSponsorshipAuthorizeButton"
	_authorize_button.text = "AUTHORIZE SPONSORSHIP"
	_authorize_button.theme_type_variation = &"PrimaryButton"
	_authorize_button.focus_mode = Control.FOCUS_ALL
	_authorize_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_authorize_button.custom_minimum_size = Vector2(0.0, 42.0)
	_authorize_button.pressed.connect(_on_authorize_pressed)
	form.add_child(_authorize_button)


func _configure_selector(selector: OptionButton) -> void:
	selector.fit_to_longest_item = false
	selector.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	selector.focus_mode = Control.FOCUS_ALL
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.custom_minimum_size = Vector2(0.0, 38.0)


func _refresh() -> void:
	visible = bool(_snapshot.get("visible", false))
	if _worker_selector == null:
		return
	_refreshing = true
	_workers = _normalized_workers(_snapshot.get("eligible_workers", []))
	_lanes = _normalized_lanes(_snapshot.get("lanes", []))
	_rebuild_worker_selector()
	_rebuild_lane_selector()
	_refreshing = false
	_refresh_copy_and_authorization()


func _rebuild_worker_selector() -> void:
	var previous_worker_id := _selected_worker_id
	_worker_selector.clear()
	_selected_worker_id = -1
	var selected_index := -1
	for worker in _workers:
		var worker_id := int(worker.get("id", -1))
		var display_name := _worker_name(worker)
		var career_title := String(worker.get("career_title", "UNFILED CAREER")).strip_edges()
		var option_text := display_name.to_upper()
		if not career_title.is_empty():
			option_text += "  ·  %s" % career_title.to_upper()
		_worker_selector.add_item(option_text)
		var index := _worker_selector.item_count - 1
		_worker_selector.set_item_metadata(index, worker_id)
		_worker_selector.set_item_tooltip(index, "%s — %s" % [display_name, career_title])
		if worker_id == previous_worker_id:
			selected_index = index
	if _worker_selector.item_count > 0:
		if selected_index < 0:
			selected_index = 0
		_worker_selector.select(selected_index)
		_selected_worker_id = int(_worker_selector.get_item_metadata(selected_index))
	_worker_selector.disabled = _worker_selector.item_count == 0


func _rebuild_lane_selector() -> void:
	var previous_lane_id := _selected_lane_id
	_lane_selector.clear()
	_selected_lane_id = &""
	var worker := _worker_by_id(_selected_worker_id)
	var valid_lanes := _valid_lanes_for_worker(worker)
	var selected_index := -1
	for lane in valid_lanes:
		var lane_id := StringName(String(lane.get("id", "")))
		_lane_selector.add_item(String(lane.get("label", _lane_fallback_label(lane_id))))
		var index := _lane_selector.item_count - 1
		_lane_selector.set_item_metadata(index, lane_id)
		_lane_selector.set_item_tooltip(index, "Train toward specialist affinity in %s." % String(lane.get("label", _lane_fallback_label(lane_id))))
		if lane_id == previous_lane_id:
			selected_index = index
	if _lane_selector.item_count > 0:
		if selected_index < 0:
			selected_index = 0
		_lane_selector.select(selected_index)
		_selected_lane_id = StringName(_lane_selector.get_item_metadata(selected_index))
	_lane_selector.disabled = _lane_selector.item_count == 0


func _refresh_copy_and_authorization() -> void:
	var mark_word := "MARK" if _mark_cost == 1 else "MARKS"
	var available_word := "MARK" if _available_marks == 1 else "MARKS"
	_balance_label.text = (
		"AVAILABLE  %d ROOST %s\nAUTHORIZATION  %d %s + $%.2f FEED FUND"
		% [_available_marks, available_word, _mark_cost, mark_word, float(_fund_cost_cents) / 100.0]
	)

	var worker := _worker_by_id(_selected_worker_id)
	if worker.is_empty():
		_worker_detail_label.text = "No eligible hen is present in this between-quarter file."
	else:
		var primary_id := _primary_lane_id(worker)
		var wage_cents := maxi(0, int(worker.get("wage_cents", worker.get("daily_wage_cents", 0))))
		_worker_detail_label.text = "PRIMARY  %s  ·  CURRENT WAGE  $%.2f/day" % [
			_lane_label(primary_id),
			float(wage_cents) / 100.0,
		]

	var selected_lane_label := (
		_lane_label(_selected_lane_id)
		if _selected_lane_id != &"" else
		"SELECT AN UNTRAINED ALTERNATE LANE"
	)
	_terms_label.text = (
		"IMMEDIATE  %d Roost %s + $%.2f Feed Fund\n"
		+ "NEXT SHIFT  -%d%% training throughput\n"
		+ "PERMANENT  +$%.2f/day wage\n"
		+ "POST-TRAINING  Specialist affinity: %s"
	) % [
		_mark_cost,
		"Mark" if _mark_cost == 1 else "Marks",
		float(_fund_cost_cents) / 100.0,
		TRAINING_THROUGHPUT_PERCENT,
		float(DAILY_WAGE_DELTA_CENTS) / 100.0,
		selected_lane_label,
	]

	var reason := _authorization_reason()
	_reason_label.visible = not reason.is_empty()
	_reason_label.text = reason
	_authorize_button.disabled = not reason.is_empty()
	if reason.is_empty():
		var worker_name := _worker_name(worker)
		_authorize_button.tooltip_text = (
			"Authorize %s for %s: spend %d Roost %s and $%.2f now."
			% [
				worker_name,
				_lane_label(_selected_lane_id),
				_mark_cost,
				"Mark" if _mark_cost == 1 else "Marks",
				float(_fund_cost_cents) / 100.0,
			]
		)
	else:
		_authorize_button.tooltip_text = reason


func _authorization_reason() -> String:
	var authoritative_reason := String(_snapshot.get("unavailable_reason", "")).strip_edges()
	if not authoritative_reason.is_empty():
		return authoritative_reason
	if _available_marks < _mark_cost:
		var shortfall := _mark_cost - _available_marks
		return "%d more Roost %s required. Bank this opportunity for a later quarter." % [
			shortfall,
			"Mark is" if shortfall == 1 else "Marks are",
		]
	if _workers.is_empty() or _selected_worker_id < 0:
		return "No eligible hens are available for career sponsorship."
	var worker := _worker_by_id(_selected_worker_id)
	if worker.is_empty():
		return "The selected hen is no longer eligible for career sponsorship."
	if _lane_selector == null or _lane_selector.item_count == 0:
		return "%s has no untrained alternate specialty available." % _worker_name(worker)
	if _selected_lane_id == &"":
		return "Select an untrained alternate specialty before authorization."
	return ""


func _on_worker_selected(index: int) -> void:
	if _refreshing or index < 0 or index >= _worker_selector.item_count:
		return
	var metadata: Variant = _worker_selector.get_item_metadata(index)
	if metadata == null:
		return
	_selected_worker_id = int(metadata)
	_selected_lane_id = &""
	_refreshing = true
	_rebuild_lane_selector()
	_refreshing = false
	_refresh_copy_and_authorization()


func _on_lane_selected(index: int) -> void:
	if _refreshing or index < 0 or index >= _lane_selector.item_count:
		return
	var metadata: Variant = _lane_selector.get_item_metadata(index)
	if metadata == null:
		return
	_selected_lane_id = StringName(metadata)
	_refresh_copy_and_authorization()


func _on_authorize_pressed() -> void:
	if not _authorization_reason().is_empty():
		return
	sponsorship_requested.emit(_selected_worker_id, _selected_lane_id)


func _normalized_workers(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen_ids: Dictionary = {}
	if not value is Array:
		return result
	for worker_value: Variant in value as Array:
		if not worker_value is Dictionary:
			continue
		var worker := (worker_value as Dictionary).duplicate(true)
		var worker_id := int(worker.get("id", -1))
		if worker_id < 0 or seen_ids.has(worker_id):
			continue
		seen_ids[worker_id] = true
		result.append(worker)
	return result


func _normalized_lanes(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen_ids: Dictionary = {}
	if not value is Array:
		return result
	for lane_value: Variant in value as Array:
		if not lane_value is Dictionary:
			continue
		var lane := (lane_value as Dictionary).duplicate(true)
		var lane_id := StringName(String(lane.get("id", "")))
		if lane_id == &"" or seen_ids.has(lane_id):
			continue
		seen_ids[lane_id] = true
		var label := String(lane.get("label", "")).strip_edges()
		lane["id"] = lane_id
		lane["label"] = label if not label.is_empty() else _lane_fallback_label(lane_id)
		result.append(lane)
	return result


func _valid_lanes_for_worker(worker: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if worker.is_empty():
		return result
	var blocked := _blocked_lane_ids(worker)
	blocked[_primary_lane_id(worker)] = true
	for lane in _lanes:
		var lane_id := StringName(String(lane.get("id", "")))
		if lane_id == &"" or blocked.has(lane_id):
			continue
		result.append(lane.duplicate(true))
	return result


func _blocked_lane_ids(worker: Dictionary) -> Dictionary:
	var blocked: Dictionary = {}
	for key in [
		"secondary_specialty", "secondary_lane", "secondary_lane_id",
		"training_lane_id", "training_lane", "training_specialty", "cross_training_target",
	]:
		_collect_lane_ids(blocked, worker.get(key, null))
	for key in [
		"secondary_specialties", "trained_specialties", "trained_lanes",
		"sponsored_lanes", "specialty_training",
	]:
		_collect_lane_ids(blocked, worker.get(key, []))
	var training: Variant = worker.get("training", null)
	if training is Dictionary:
		var training_data := training as Dictionary
		for key in ["lane_id", "lane", "specialty", "target_lane_id", "target_specialty"]:
			_collect_lane_ids(blocked, training_data.get(key, null))
		for key in ["completed_lane_ids", "trained_lane_ids", "specialties"]:
			_collect_lane_ids(blocked, training_data.get(key, []))
	elif training is Array or training is String or training is StringName:
		_collect_lane_ids(blocked, training)
	blocked.erase(&"")
	return blocked


func _collect_lane_ids(target: Dictionary, value: Variant) -> void:
	if value == null:
		return
	if value is String or value is StringName:
		var lane_id := StringName(String(value))
		if lane_id != &"":
			target[lane_id] = true
		return
	if value is Array:
		for entry: Variant in value as Array:
			_collect_lane_ids(target, entry)
		return
	if value is Dictionary:
		var entry := value as Dictionary
		for key in ["id", "lane_id", "lane", "specialty"]:
			if entry.has(key):
				_collect_lane_ids(target, entry[key])
				return


func _worker_by_id(worker_id: int) -> Dictionary:
	for worker in _workers:
		if int(worker.get("id", -1)) == worker_id:
			return worker
	return {}


func _worker_name(worker: Dictionary) -> String:
	var worker_id := int(worker.get("id", -1))
	return String(worker.get("name", worker.get("display_name", "HEN %d" % (worker_id + 1)))).strip_edges()


func _primary_lane_id(worker: Dictionary) -> StringName:
	return StringName(String(worker.get(
		"primary_specialty",
		worker.get("primary_lane_id", worker.get("specialty", "")),
	)))


func _lane_label(lane_id: StringName) -> String:
	if lane_id == &"":
		return "UNFILED"
	for lane in _lanes:
		if StringName(String(lane.get("id", ""))) == lane_id:
			return String(lane.get("label", _lane_fallback_label(lane_id))).to_upper()
	return _lane_fallback_label(lane_id).to_upper()


func _lane_fallback_label(lane_id: StringName) -> String:
	return String(lane_id).replace("_", " ").capitalize()


func _make_label(copy: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_NAVY_RAISED
	style.border_color = COLOR_NAVY.lightened(0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	return style
