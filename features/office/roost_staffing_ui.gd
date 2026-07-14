class_name RoostStaffingUI
extends VBoxContainer

## Compact staffing controls hosted inside the existing Flockwatch ledger.
##
## The surface deliberately reuses the ledger's ScrollContainer instead of
## creating another permanent overlay. Every disabled action retains the
## authoritative simulation reason in its tooltip.

signal capacity_purchase_requested
signal hire_requested(worker_id: int)
signal release_requested(worker_id: int)

const COLOR_BRASS := Color("e7c56e")
const COLOR_TEAL := Color("73b5a7")
const COLOR_MUTED := Color("aeb8c4")
const COLOR_RUST := Color("d68a68")

var _snapshot: Dictionary = {}
var _headcount_label: Label
var _costs_label: Label
var _arrears_label: Label
var _planning_label: Label
var _capacity_button: Button
var _applicant_list: VBoxContainer
var _release_selector: OptionButton
var _release_button: Button
var _last_action_label: Label
var _selected_release_worker_id := -1


func _ready() -> void:
	name = "RoostStaffingUI"
	add_theme_constant_override("separation", 7)
	_build_interface()
	_refresh()


func apply_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_refresh()


func _build_interface() -> void:
	var heading_row := HBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 8)
	add_child(heading_row)
	var heading := _make_label("ROOST STAFFING", 17, COLOR_BRASS)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading)
	_headcount_label = _make_label("4 / 4", 14, COLOR_TEAL)
	_headcount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heading_row.add_child(_headcount_label)

	_costs_label = _make_label("Operating reserve is being calculated.", 12, COLOR_MUTED)
	_costs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_costs_label)
	_arrears_label = _make_label("", 12, COLOR_RUST)
	_arrears_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_arrears_label.visible = false
	add_child(_arrears_label)

	_capacity_button = Button.new()
	_capacity_button.name = "PurchaseStaffCapacity"
	_capacity_button.theme_type_variation = &"PrimaryButton"
	_capacity_button.custom_minimum_size.y = 40.0
	_capacity_button.pressed.connect(func() -> void: capacity_purchase_requested.emit())
	add_child(_capacity_button)

	_planning_label = _make_label("STAFFING FILE", 12, COLOR_BRASS)
	add_child(_planning_label)
	_applicant_list = VBoxContainer.new()
	_applicant_list.name = "StaffingApplicants"
	_applicant_list.add_theme_constant_override("separation", 6)
	add_child(_applicant_list)

	var release_title := _make_label("ACTIVE ROOST", 12, COLOR_BRASS)
	add_child(release_title)
	var release_row := HBoxContainer.new()
	release_row.add_theme_constant_override("separation", 6)
	add_child(release_row)
	_release_selector = OptionButton.new()
	_release_selector.name = "ReleaseWorkerSelector"
	_release_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_release_selector.custom_minimum_size.y = 38.0
	_release_selector.item_selected.connect(_on_release_selection_changed)
	release_row.add_child(_release_selector)
	_release_button = Button.new()
	_release_button.name = "ReleaseWorkerButton"
	_release_button.theme_type_variation = &"DangerButton"
	_release_button.custom_minimum_size = Vector2(92.0, 38.0)
	_release_button.pressed.connect(_on_release_pressed)
	release_row.add_child(_release_button)

	_last_action_label = _make_label("", 12, Color("d7c17d"))
	_last_action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_last_action_label.visible = false
	add_child(_last_action_label)


func _refresh() -> void:
	if _headcount_label == null:
		return
	var active_count := int(_snapshot.get("active_staff_count", _employed_workers().size()))
	var capacity := int(_snapshot.get("office_capacity", maxi(active_count, 4)))
	var maximum := int(_snapshot.get("maximum_staff_capacity", maxi(capacity, 6)))
	var planning_open := bool(_snapshot.get("staffing_planning_open", false))
	var payroll := int(_snapshot.get("daily_payroll_cents", 0))
	var facility := int(_snapshot.get("daily_facility_cost_cents", 0))
	var operating := int(_snapshot.get("daily_operating_cost_cents", payroll + facility))
	var spendable := int(_snapshot.get("spendable_fund_cents", _snapshot.get("revenue_cents", 0)))
	var arrears := int(_snapshot.get("wage_arrears_cents", 0))

	_headcount_label.text = "%d / %d  ·  MAX %d" % [active_count, capacity, maximum]
	_headcount_label.add_theme_color_override("font_color", COLOR_RUST if active_count > capacity else COLOR_TEAL)
	_costs_label.text = "RESERVED  $%.2f/day  ·  payroll $%.2f  ·  facility $%.2f\nSPENDABLE FEED FUND  $%.2f" % [
		operating / 100.0,
		payroll / 100.0,
		facility / 100.0,
		spendable / 100.0,
	]
	_arrears_label.visible = arrears > 0
	_arrears_label.text = "WAGE ARREARS  $%.2f  ·  obligations remain unpaid" % (arrears / 100.0)
	_planning_label.text = "SCREENED APPLICANTS" if planning_open else "SCREENED APPLICANTS  ·  FILE LOCKED"
	_planning_label.tooltip_text = (
		"Staffing changes are available while the planning file is open."
		if planning_open else
		"Pause during an active shift or enter a planning review to change headcount."
	)

	_refresh_capacity_button(capacity, maximum, spendable, planning_open)
	_refresh_applicants(spendable, planning_open)
	_refresh_release_controls(spendable, planning_open)
	_refresh_last_action()


func _refresh_capacity_button(capacity: int, maximum: int, spendable: int, planning_open: bool) -> void:
	var upgrade := _snapshot.get("capacity_upgrade", {}) as Dictionary
	var cost := int(upgrade.get("cost_cents", upgrade.get("cost", 0)))
	var next_capacity := int(upgrade.get("next_capacity", mini(maximum, capacity + 1)))
	var maxed := bool(upgrade.get("maxed", capacity >= maximum)) or capacity >= maximum
	var authoritative_can_purchase := bool(upgrade.get("can_purchase", upgrade.get("available", not maxed)))
	var affordable := spendable >= cost
	var enabled := planning_open and not maxed and authoritative_can_purchase and affordable
	_capacity_button.text = (
		"ROOST CAPACITY FULL  ·  %d PERCHES" % maximum
		if maxed else
		"AUTHORIZE PERCH %d  ·  $%.2f" % [next_capacity, cost / 100.0]
	)
	_capacity_button.disabled = not enabled
	var reason := String(upgrade.get("reason", ""))
	if reason.is_empty() and not planning_open:
		reason = "The staffing file is locked until management pauses for planning."
	elif reason.is_empty() and maxed:
		reason = "Every approved workstation is already authorized."
	elif reason.is_empty() and not affordable:
		reason = "Spendable Feed Fund is short by $%.2f." % ((cost - spendable) / 100.0)
	elif reason.is_empty() and not authoritative_can_purchase:
		reason = "This capacity requisition is not currently authorized."
	_capacity_button.tooltip_text = (
		"Spend $%.2f to reveal one staffed workstation without touching reserved operating costs." % (cost / 100.0)
		if enabled else
		"CAPACITY HELD: %s" % reason
	)


func _refresh_applicants(spendable: int, planning_open: bool) -> void:
	_clear_children(_applicant_list)
	var applicants := _applicant_entries()
	if applicants.is_empty():
		var empty := _make_label("No screened applicants remain in the hiring file.", 12, COLOR_MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_applicant_list.add_child(empty)
		return
	for applicant in applicants:
		_build_applicant_card(applicant, spendable, planning_open)


func _build_applicant_card(applicant: Dictionary, spendable: int, planning_open: bool) -> void:
	var worker_id := _worker_id(applicant)
	var display_name := String(applicant.get("name", applicant.get("display_name", "APPLICANT %d" % worker_id)))
	var specialty := String(applicant.get("specialty_name", applicant.get("specialty", "GENERAL PECKWORK"))).replace("_", " ").to_upper()
	var profile := String(applicant.get("career_profile_name", applicant.get("profile_name", "UNFILED PROFILE"))).to_upper()
	var wage := int(applicant.get("daily_wage_cents", 0))
	var hire_cost := int(applicant.get("hire_cost_cents", applicant.get("cost_cents", 0)))
	var can_hire := bool(applicant.get("can_hire", true))
	var affordable := spendable >= hire_cost
	var enabled := planning_open and can_hire and affordable and worker_id >= 0

	var card := PanelContainer.new()
	card.name = "StaffingApplicant_%d" % worker_id
	card.add_theme_stylebox_override("panel", _card_style())
	_applicant_list.add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	margin.add_child(row)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 1)
	row.add_child(identity)
	var name_label := _make_label(display_name.to_upper(), 14, Color("eef1df"))
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	identity.add_child(name_label)
	var fit_label := _make_label("%s  ·  %s" % [profile, specialty], 10, COLOR_MUTED)
	fit_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	fit_label.tooltip_text = "%s specializes in %s files." % [display_name, specialty]
	identity.add_child(fit_label)
	identity.add_child(_make_label("WAGE $%.2f/day" % (wage / 100.0), 11, Color("d7c17d")))

	var hire_button := Button.new()
	hire_button.name = "HireWorker_%d" % worker_id
	hire_button.theme_type_variation = &"PrimaryButton"
	hire_button.custom_minimum_size = Vector2(94.0, 42.0)
	hire_button.text = "HIRE\n$%.2f" % (hire_cost / 100.0)
	hire_button.disabled = not enabled
	var reason := String(applicant.get("reason", applicant.get("disabled_reason", "")))
	if reason.is_empty() and not planning_open:
		reason = "The staffing file is locked."
	elif reason.is_empty() and not affordable:
		reason = "Spendable Feed Fund is short by $%.2f." % ((hire_cost - spendable) / 100.0)
	elif reason.is_empty() and not can_hire:
		reason = "No authorized perch is available for this applicant."
	hire_button.tooltip_text = (
		"Hire %s for $%.2f; adds $%.2f to daily payroll." % [display_name, hire_cost / 100.0, wage / 100.0]
		if enabled else
		"HIRE HELD: %s" % reason
	)
	hire_button.pressed.connect(func() -> void: hire_requested.emit(worker_id))
	row.add_child(hire_button)


func _refresh_release_controls(spendable: int, planning_open: bool) -> void:
	var employed := _employed_workers()
	var previous_selection := _selected_release_worker_id
	_release_selector.clear()
	for worker in employed:
		var worker_id := _worker_id(worker)
		var display_name := String(worker.get("name", worker.get("display_name", "HEN %d" % (worker_id + 1))))
		var wage := int(worker.get("daily_wage_cents", 0))
		_release_selector.add_item("%s  ·  $%.2f/d" % [display_name.to_upper(), wage / 100.0])
		var item_index := _release_selector.item_count - 1
		_release_selector.set_item_metadata(item_index, worker_id)
		if worker_id == previous_selection:
			_release_selector.select(item_index)
	if _release_selector.item_count == 0:
		_selected_release_worker_id = -1
		_release_selector.add_item("NO ACTIVE HENS")
		_release_selector.disabled = true
		_release_button.text = "RELEASE"
		_release_button.disabled = true
		_release_button.tooltip_text = "No active employment record can be released."
		return
	_release_selector.disabled = not planning_open
	if _release_selector.selected < 0:
		_release_selector.select(0)
	_selected_release_worker_id = int(_release_selector.get_item_metadata(_release_selector.selected))
	var selected := _staffing_record(_selected_release_worker_id)
	var release_cost := int(selected.get("release_cost_cents", 0))
	var can_release := bool(selected.get("can_release", true))
	var affordable := spendable >= release_cost
	var enabled := planning_open and can_release and affordable
	_release_button.text = "RELEASE\n$%.2f" % (release_cost / 100.0)
	_release_button.disabled = not enabled
	var reason := String(selected.get("release_reason", selected.get("disabled_reason", "")))
	if reason.is_empty() and not planning_open:
		reason = "The staffing file is locked."
	elif reason.is_empty() and not affordable:
		reason = "Spendable Feed Fund is short by $%.2f." % ((release_cost - spendable) / 100.0)
	elif reason.is_empty() and not can_release:
		reason = "At least one active hen must remain on the claim floor."
	_release_button.tooltip_text = (
		"Release this hen for an exact separation cost of $%.2f." % (release_cost / 100.0)
		if enabled else
		"RELEASE HELD: %s" % reason
	)


func _refresh_last_action() -> void:
	var last_action := _snapshot.get("last_staffing_action", {}) as Dictionary
	var outcome := String(last_action.get("outcome", last_action.get("reason", "")))
	_last_action_label.visible = not outcome.is_empty()
	_last_action_label.text = "LAST FILE  ·  %s" % outcome if not outcome.is_empty() else ""
	_last_action_label.tooltip_text = outcome


func _on_release_selection_changed(index: int) -> void:
	if index < 0 or index >= _release_selector.item_count:
		return
	var metadata: Variant = _release_selector.get_item_metadata(index)
	if metadata == null:
		return
	_selected_release_worker_id = int(metadata)
	_refresh_release_controls(
		int(_snapshot.get("spendable_fund_cents", _snapshot.get("revenue_cents", 0))),
		bool(_snapshot.get("staffing_planning_open", false)),
	)


func _on_release_pressed() -> void:
	if _selected_release_worker_id >= 0:
		release_requested.emit(_selected_release_worker_id)


func _applicant_entries() -> Array[Dictionary]:
	var workers_by_id: Dictionary[int, Dictionary] = {}
	for worker_value in _snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		workers_by_id[_worker_id(worker)] = worker
	var result: Array[Dictionary] = []
	for entry_value in _snapshot.get("staffing_catalog", []):
		var entry := (entry_value as Dictionary).duplicate(true)
		var worker_id := _worker_id(entry)
		if workers_by_id.has(worker_id):
			entry.merge(workers_by_id[worker_id], true)
		if not _is_employed(entry):
			result.append(entry)
	if result.is_empty():
		for worker in workers_by_id.values():
			if not _is_employed(worker):
				result.append(worker.duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _worker_id(a) < _worker_id(b))
	return result


func _employed_workers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for worker_value in _snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if _is_employed(worker):
			result.append(worker)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("desk_index", 999)) < int(b.get("desk_index", 999))
	)
	return result


func _worker_snapshot(worker_id: int) -> Dictionary:
	for worker_value in _snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if _worker_id(worker) == worker_id:
			return worker
	return {}


func _staffing_record(worker_id: int) -> Dictionary:
	var result := _worker_snapshot(worker_id).duplicate(true)
	for entry_value in _snapshot.get("staffing_catalog", []):
		var entry := entry_value as Dictionary
		if _worker_id(entry) == worker_id:
			result.merge(entry, true)
			break
	return result


func _is_employed(worker: Dictionary) -> bool:
	if worker.has("employed"):
		return bool(worker.get("employed", false))
	var status := StringName(String(worker.get("employment_status", "employed")))
	return int(worker.get("desk_index", -1)) >= 0 and status not in [&"applicant", &"released", &"inactive"]


func _worker_id(worker: Dictionary) -> int:
	return int(worker.get("id", worker.get("worker_id", -1)))


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _make_label(copy: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172832")
	style.border_color = Color("50616d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	return style
