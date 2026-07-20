class_name FlockwatchNavigation
extends VBoxContainer

## Progressive, presentation-only navigation for the Flockwatch ledger.
##
## Office remains authoritative over every registered control and every economy
## action. This component only reparents existing section roots into persistent,
## independently scrolling pages. Reparenting preserves the controls themselves,
## their names, signal connections, metadata, and focus modes.

signal page_changed(page_id: StringName)
signal page_availability_changed(page_id: StringName, available: bool)
signal show_all_filings_changed(enabled: bool)

const PAGE_TODAY: StringName = &"today"
const PAGE_FLOCK: StringName = &"flock"
const PAGE_OPERATIONS: StringName = &"operations"
const PAGE_CAPITAL: StringName = &"capital"
const PAGE_GOVERNANCE_RECORDS: StringName = &"governance_records"

const PAGE_ORDER: Array[StringName] = [
	PAGE_TODAY,
	PAGE_FLOCK,
	PAGE_OPERATIONS,
	PAGE_CAPITAL,
	PAGE_GOVERNANCE_RECORDS,
]
const BASE_PAGES: Array[StringName] = [PAGE_TODAY, PAGE_FLOCK]
const SECONDARY_PAGES: Array[StringName] = [
	PAGE_OPERATIONS,
	PAGE_CAPITAL,
	PAGE_GOVERNANCE_RECORDS,
]
const MORE_FILES_SHOW_ALL_ID := 100

const PAGE_LABELS := {
	PAGE_TODAY: "TODAY",
	PAGE_FLOCK: "FLOCK",
	PAGE_OPERATIONS: "OPS",
	PAGE_CAPITAL: "CAPITAL",
	PAGE_GOVERNANCE_RECORDS: "RECORDS",
}
const PAGE_TITLES := {
	PAGE_TODAY: "Today's orders, compact shift snapshot, exceptions, and optional notice history",
	PAGE_FLOCK: "Pecking Order, roster, applicants, care, training, and careers",
	PAGE_OPERATIONS: "Feed Party, after-hours pecking, Rooster Operations, Procurement, and Farmgate",
	PAGE_CAPITAL: "Treasury, requisitions, capacity, facilities, Blueprint, and Portfolio",
	PAGE_GOVERNANCE_RECORDS: "Flock Relations, Farm Mutual, contracts, Gallery credit, and bureau records",
}

const OPERATIONS_FACILITY_IDS: Array[StringName] = [
	&"rooster_operations_office",
	&"it_coop",
	&"feed_procurement_coop",
	&"farmgate_dispatch_depot",
]
const GOVERNANCE_FACILITY_IDS: Array[StringName] = [
	&"flock_relations_office",
	&"farmer_relations_gallery",
	&"farm_mutual_service_coop",
	&"farm_mutual_negotiation_room",
]

const OPERATIONS_RECEIPT_KEYS: Array[StringName] = [
	&"last_operations_receipt",
	&"last_feed_order_receipt",
	&"last_feed_procurement_receipt",
	&"last_farmgate_dispatch_receipt",
	&"pending_operations_receipts",
]
const CAPITAL_RECEIPT_KEYS: Array[StringName] = [
	&"last_facility_purchase_receipt",
	&"last_capacity_purchase_receipt",
	&"last_campus_expansion_receipt",
	&"last_campus_portfolio_receipt",
	&"pending_capital_receipts",
]
const GOVERNANCE_RECEIPT_KEYS: Array[StringName] = [
	&"last_flock_relations_receipt",
	&"last_contract_receipt",
	&"last_gallery_receipt",
	&"flock_compact_receipt",
	&"pending_governance_receipts",
]

var _snapshot: Dictionary = {}
var _interface_built := false
var _first_clutch_active := false
var _show_all_filings := false
var _current_page_id: StringName = PAGE_TODAY
var _registration_serial := 0

var _page_buttons: Dictionary = {}
var _page_scrolls: Dictionary = {}
var _page_contents: Dictionary = {}
var _page_available: Dictionary = {}
var _discovered_pages: Dictionary = {}
var _sections: Dictionary = {}
var _original_parent_orders: Dictionary = {}

var _page_button_group: ButtonGroup
var _all_filings_toggle: Button
var _more_files_button: MenuButton
var _feedback_panel: PanelContainer
var _feedback_label: Label
var _context_actions: VBoxContainer
var _page_deck: Control
var _last_feedback: String = ""


func _ready() -> void:
	_ensure_interface()
	_recompute_availability()


## Reads immutable presentation evidence from an authoritative snapshot. It does
## not retain a reference to the caller's Dictionary and never calls simulation.
func apply_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	if snapshot.has("first_clutch_active"):
		_first_clutch_active = bool(snapshot.get("first_clutch_active", false))
	elif snapshot.has("first_clutch"):
		var first_clutch_value: Variant = snapshot.get("first_clutch", {})
		if first_clutch_value is Dictionary:
			var first_clutch := first_clutch_value as Dictionary
			var stage := StringName(String(first_clutch.get("stage", &"")))
			_first_clutch_active = bool(first_clutch.get("visible", false)) and stage != &"complete"
	_recompute_availability()


## Hosts can use this when First Clutch presentation state is stored outside the
## simulation snapshot passed to apply_snapshot().
func set_first_clutch_active(active: bool) -> void:
	if _first_clutch_active == active:
		return
	_first_clutch_active = active
	_recompute_availability()


func is_first_clutch_active() -> bool:
	return _first_clutch_active


## Explicit accessibility/reachability escape hatch. Turning this off returns to
## organically discovered pages; it does not forget pages already discovered.
func set_show_all_filings(enabled: bool) -> void:
	_ensure_interface()
	if _show_all_filings == enabled:
		_update_more_files_presentation()
		return
	_show_all_filings = enabled
	_recompute_availability()
	show_all_filings_changed.emit(enabled)


func is_showing_all_filings() -> bool:
	return _show_all_filings


## Clears presentation discovery for a genuinely new campaign. Today and Flock
## remain available, and the current snapshot is evaluated again immediately.
func reset_discovered_pages() -> void:
	_discovered_pages.clear()
	for page_id: StringName in BASE_PAGES:
		_discovered_pages[page_id] = true
	_recompute_availability()


## Registers an existing section root without recreating or copying it. The
## optional order is local to its page; equal orders retain registration order.
func register_section(
	page_id: StringName,
	control: Control,
	section_id: StringName = &"",
	sort_order: int = 0
) -> bool:
	_ensure_interface()
	if page_id not in PAGE_ORDER or control == null or not is_instance_valid(control):
		return false
	if control == self or control.is_ancestor_of(self) or _section_id_for_control(control) != &"":
		return false
	if is_ancestor_of(control) and control.get_parent() not in _page_contents.values():
		return false
	var stable_id := section_id
	if stable_id == &"":
		stable_id = StringName(control.name)
	if stable_id == &"" or _sections.has(stable_id):
		return false

	var original_parent := control.get_parent()
	var original_index := -1
	if original_parent != null:
		var parent_key := original_parent.get_instance_id()
		if not _original_parent_orders.has(parent_key):
			_original_parent_orders[parent_key] = original_parent.get_children()
		var original_order := _original_parent_orders[parent_key] as Array
		original_index = original_order.find(control)
		if original_index < 0:
			original_index = control.get_index()

	_registration_serial += 1
	_sections[stable_id] = {
		"section_id": stable_id,
		"control": control,
		"page_id": page_id,
		"original_parent": original_parent,
		"original_index": original_index,
		"sort_order": sort_order,
		"serial": _registration_serial,
	}
	var content := _page_contents.get(page_id) as VBoxContainer
	if original_parent == null:
		content.add_child(control)
	elif original_parent != content:
		control.reparent(content, false)
	_sort_page_sections(page_id)
	_ensure_focus_not_hidden()
	return true


## Restores one section to the parent and sibling position it had when its first
## sibling was registered. Passing false detaches it instead.
func unregister_section(section_id: StringName, restore_original_parent: bool = true) -> Control:
	if not _sections.has(section_id):
		return null
	var entry := _sections[section_id] as Dictionary
	var control := entry.get("control") as Control
	_sections.erase(section_id)
	if control == null or not is_instance_valid(control):
		return null
	var original_parent := entry.get("original_parent") as Node
	if restore_original_parent and original_parent != null and is_instance_valid(original_parent):
		if control.get_parent() != original_parent:
			control.reparent(original_parent, false)
		var original_index := int(entry.get("original_index", -1))
		if original_index >= 0:
			original_parent.move_child(control, mini(original_index, original_parent.get_child_count() - 1))
	elif control.get_parent() != null:
		control.get_parent().remove_child(control)
	return control


## Restores every section in original sibling order. Useful before replacing or
## freeing a navigator while the host UI remains alive.
func restore_registered_sections() -> void:
	var section_ids: Array[StringName] = []
	var original_parents: Dictionary = {}
	for section_id_value: Variant in _sections.keys():
		section_ids.append(StringName(section_id_value))
		var entry := _sections[section_id_value] as Dictionary
		var original_parent := entry.get("original_parent") as Node
		if original_parent != null and is_instance_valid(original_parent):
			original_parents[original_parent.get_instance_id()] = original_parent
	section_ids.sort_custom(
		func(left_id: StringName, right_id: StringName) -> bool:
			var left := _sections[left_id] as Dictionary
			var right := _sections[right_id] as Dictionary
			var left_parent := left.get("original_parent") as Node
			var right_parent := right.get("original_parent") as Node
			var left_parent_id := left_parent.get_instance_id() if left_parent != null else 0
			var right_parent_id := right_parent.get_instance_id() if right_parent != null else 0
			if left_parent_id != right_parent_id:
				return left_parent_id < right_parent_id
			return int(left.get("original_index", -1)) < int(right.get("original_index", -1))
	)
	for section_id: StringName in section_ids:
		unregister_section(section_id, true)
	# Reapply the captured complete sibling order, including unregistered spacers
	# and headings. This is stronger than restoring section indices one at a time
	# when registration and page-local sorting happened in different orders.
	for parent_id: Variant in original_parents.keys():
		var parent := original_parents[parent_id] as Node
		if parent == null or not is_instance_valid(parent):
			continue
		var original_order := _original_parent_orders.get(parent_id, []) as Array
		var target_index := 0
		for child_value: Variant in original_order:
			var child := child_value as Node
			if child == null or not is_instance_valid(child) or child.get_parent() != parent:
				continue
			parent.move_child(child, target_index)
			target_index += 1


func registered_section_ids(page_id: StringName = &"") -> Array[StringName]:
	var result: Array[StringName] = []
	for candidate_page: StringName in PAGE_ORDER:
		if page_id != &"" and candidate_page != page_id:
			continue
		var entries := _section_entries_for_page(candidate_page)
		for entry: Dictionary in entries:
			result.append(StringName(entry.get("section_id", &"")))
	return result


func page_for_section(section_id: StringName) -> StringName:
	if not _sections.has(section_id):
		return &""
	return StringName((_sections[section_id] as Dictionary).get("page_id", &""))


func open_page(page_id: StringName, grab_tab_focus: bool = false) -> bool:
	_ensure_interface()
	if not is_page_available(page_id):
		return false
	_activate_page(page_id, grab_tab_focus)
	return true


func cycle_page(direction: int, grab_tab_focus: bool = true) -> bool:
	var available := available_page_ids()
	if available.is_empty() or direction == 0:
		return false
	var current_index := available.find(_current_page_id)
	if current_index < 0:
		current_index = 0
	var next_index := posmod(current_index + (1 if direction > 0 else -1), available.size())
	_activate_page(available[next_index], grab_tab_focus)
	return true


func current_page_id() -> StringName:
	return _current_page_id


func is_page_available(page_id: StringName) -> bool:
	return bool(_page_available.get(page_id, false))


func available_page_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for page_id: StringName in PAGE_ORDER:
		if is_page_available(page_id):
			result.append(page_id)
	return result


func page_button(page_id: StringName) -> Button:
	_ensure_interface()
	if page_id in SECONDARY_PAGES:
		return _more_files_button
	return _page_buttons.get(page_id) as Button


func focus_current_tab() -> bool:
	_ensure_interface()
	var target := _focus_control_for_page(_current_page_id)
	if target == null or not target.is_visible_in_tree() or target.focus_mode == Control.FOCUS_NONE:
		return false
	target.grab_focus()
	return true


func current_page_title() -> String:
	return String(PAGE_TITLES.get(_current_page_id, String(_current_page_id)))


func available_page_labels() -> Array[String]:
	var result: Array[String] = []
	for page_id: StringName in available_page_ids():
		result.append(String(PAGE_LABELS.get(page_id, String(page_id))).capitalize())
	return result


func set_last_feedback(copy: String) -> void:
	_ensure_interface()
	_last_feedback = copy.strip_edges()
	if _feedback_panel == null or _feedback_label == null:
		return
	_feedback_panel.visible = not _last_feedback.is_empty()
	_feedback_label.text = (
		"LATEST NOTICE  /  %s" % _display_feedback(_last_feedback)
		if not _last_feedback.is_empty() else ""
	)
	_feedback_label.tooltip_text = _last_feedback


func last_feedback() -> String:
	return _last_feedback


func page_scroll(page_id: StringName) -> ScrollContainer:
	_ensure_interface()
	return _page_scrolls.get(page_id) as ScrollContainer


## Hosts can place one or more progression actions above the page deck so a
## required Continue/Confirm control never disappears merely because the player
## is reading a different filing page. The original Control and its signals are
## preserved exactly.
func adopt_context_action(control: Control) -> bool:
	_ensure_interface()
	if control == null or not is_instance_valid(control):
		return false
	if control == self or control.is_ancestor_of(self):
		return false
	if control.get_parent() == null:
		_context_actions.add_child(control)
	elif control.get_parent() != _context_actions:
		control.reparent(_context_actions, false)
	return true


func context_actions() -> VBoxContainer:
	_ensure_interface()
	return _context_actions


## Reuses an already-built Flockwatch ScrollContainer as one page, preserving
## its object identity, name, connections, current scroll value, and child VBox.
## This lets Office keep the legacy `FlockwatchScroll` node that integrations
## already locate. Call either before or after registering its direct sections.
func adopt_page_scroll(
	page_id: StringName,
	scroll: ScrollContainer,
	content: VBoxContainer = null
) -> bool:
	_ensure_interface()
	if page_id not in PAGE_ORDER or scroll == null or not is_instance_valid(scroll):
		return false
	if scroll == self or scroll.is_ancestor_of(self):
		return false
	var adopted_content := content
	if adopted_content == null:
		for child: Node in scroll.get_children():
			if child is VBoxContainer:
				adopted_content = child as VBoxContainer
				break
	if adopted_content == null or adopted_content.get_parent() != scroll:
		return false
	var adopted_name := scroll.name
	var old_scroll := _page_scrolls.get(page_id) as ScrollContainer
	var old_content := _page_contents.get(page_id) as VBoxContainer
	if old_scroll == scroll and old_content == adopted_content:
		return true
	if is_ancestor_of(scroll) and old_scroll != scroll:
		return false

	if old_content != null and old_content != adopted_content:
		for child: Node in old_content.get_children():
			child.reparent(adopted_content, false)
	if old_scroll != null and old_scroll != scroll and is_instance_valid(old_scroll):
		old_scroll.free()
	if scroll.get_parent() != _page_deck:
		scroll.reparent(_page_deck, false)
	scroll.name = adopted_name
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	scroll.focus_mode = Control.FOCUS_NONE
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	adopted_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_scrolls[page_id] = scroll
	_page_contents[page_id] = adopted_content
	_sort_page_sections(page_id)
	_set_page_presentations()
	_activate_page(_current_page_id, false)
	_ensure_focus_not_hidden()
	return true


func page_content(page_id: StringName) -> VBoxContainer:
	_ensure_interface()
	return _page_contents.get(page_id) as VBoxContainer


func all_filings_button() -> Button:
	_ensure_interface()
	return _all_filings_toggle


## The compact secondary-page switcher. `all_filings_button()` remains as a
## compatibility alias because Office and older integration tests discover that
## control by role rather than by its user-facing copy.
func more_files_button() -> MenuButton:
	_ensure_interface()
	return _more_files_button


func accessible_text() -> String:
	var summary := "Flockwatch filing pages. %s is current. Available: %s. %d sections filed. More files %s. All filings %s." % [
		String(PAGE_LABELS.get(_current_page_id, String(_current_page_id))).capitalize(),
		", ".join(available_page_labels()),
		_sections.size(),
		"shows every page" if _show_all_filings else "is filtered by relevance",
		"shown" if _show_all_filings else "filtered by relevance",
	]
	if not _last_feedback.is_empty():
		summary += " Latest notice: %s" % _last_feedback
	return summary


func _ensure_interface() -> void:
	if _interface_built:
		return
	_interface_built = true
	name = "FlockwatchNavigation"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_constant_override("separation", 7)

	var heading := HBoxContainer.new()
	heading.name = "FlockwatchNavigationHeading"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 8)
	add_child(heading)
	var title := Label.new()
	title.name = "FlockwatchNavigationTitle"
	title.text = "FLOCKWATCH"
	title.custom_minimum_size = Vector2(112.0, 30.0)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	heading.add_child(title)
	_page_button_group = ButtonGroup.new()
	_page_button_group.allow_unpress = false
	var navigation := HBoxContainer.new()
	navigation.name = "FlockwatchPageNavigation"
	navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_theme_constant_override("separation", 4)
	navigation.clip_contents = true
	add_child(navigation)
	for page_id: StringName in BASE_PAGES:
		var button := Button.new()
		button.name = "FlockwatchPage_%s" % _pascal_case(page_id)
		button.text = String(PAGE_LABELS.get(page_id, String(page_id)))
		button.toggle_mode = true
		button.button_group = _page_button_group
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = Vector2(66.0, 34.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = String(PAGE_TITLES.get(page_id, button.text))
		button.pressed.connect(_on_page_pressed.bind(page_id))
		button.gui_input.connect(_on_page_button_gui_input.bind(page_id))
		navigation.add_child(button)
		_page_buttons[page_id] = button

	_more_files_button = MenuButton.new()
	_more_files_button.name = "FlockwatchMoreFiles"
	_more_files_button.text = "MORE FILES"
	_more_files_button.custom_minimum_size = Vector2(94.0, 34.0)
	_more_files_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_more_files_button.focus_mode = Control.FOCUS_ALL
	_more_files_button.clip_text = true
	_more_files_button.toggle_mode = true
	_more_files_button.tooltip_text = "Open Operations, Capital, or Records without widening the filing rail."
	_more_files_button.gui_input.connect(_on_more_files_gui_input)
	navigation.add_child(_more_files_button)
	_all_filings_toggle = _more_files_button
	var more_popup := _more_files_button.get_popup()
	for page_index: int in SECONDARY_PAGES.size():
		var page_id := SECONDARY_PAGES[page_index]
		more_popup.add_item(String(PAGE_LABELS.get(page_id, String(page_id))), page_index)
		more_popup.set_item_metadata(more_popup.item_count - 1, page_id)
	more_popup.add_separator()
	more_popup.add_check_item("SHOW EVERY FILE", MORE_FILES_SHOW_ALL_ID)
	more_popup.id_pressed.connect(_on_more_files_item_pressed)

	_feedback_panel = PanelContainer.new()
	_feedback_panel.name = "FlockwatchLatestFeedback"
	_feedback_panel.visible = false
	_feedback_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var feedback_style := StyleBoxFlat.new()
	feedback_style.bg_color = Color("2b3745")
	feedback_style.border_color = Color("7ba79d")
	feedback_style.set_border_width_all(1)
	feedback_style.set_corner_radius_all(6)
	feedback_style.content_margin_left = 9.0
	feedback_style.content_margin_right = 9.0
	feedback_style.content_margin_top = 7.0
	feedback_style.content_margin_bottom = 7.0
	_feedback_panel.add_theme_stylebox_override("panel", feedback_style)
	add_child(_feedback_panel)
	_feedback_label = Label.new()
	_feedback_label.name = "FlockwatchLatestFeedbackCopy"
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.add_theme_color_override("font_color", Color("d8e8e2"))
	_feedback_label.add_theme_font_size_override("font_size", 12)
	_feedback_panel.add_child(_feedback_label)

	_context_actions = VBoxContainer.new()
	_context_actions.name = "FlockwatchContextActions"
	_context_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_context_actions.add_theme_constant_override("separation", 5)
	add_child(_context_actions)

	_page_deck = Control.new()
	_page_deck.name = "FlockwatchPageDeck"
	_page_deck.custom_minimum_size.y = 150.0
	_page_deck.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_deck.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_deck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page_deck.clip_contents = true
	add_child(_page_deck)
	for page_id: StringName in PAGE_ORDER:
		var scroll := ScrollContainer.new()
		scroll.name = (
			"FlockwatchScroll"
			if page_id == PAGE_TODAY else
			"Flockwatch%sScroll" % _pascal_case(page_id)
		)
		scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.follow_focus = true
		scroll.focus_mode = Control.FOCUS_NONE
		scroll.mouse_filter = Control.MOUSE_FILTER_STOP
		scroll.visible = false
		_page_deck.add_child(scroll)
		var content := VBoxContainer.new()
		content.name = "Flockwatch%sPage" % _pascal_case(page_id)
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_theme_constant_override("separation", 8)
		content.mouse_filter = Control.MOUSE_FILTER_PASS
		scroll.add_child(content)
		_page_scrolls[page_id] = scroll
		_page_contents[page_id] = content

	for page_id: StringName in PAGE_ORDER:
		var base_available := page_id in BASE_PAGES
		_page_available[page_id] = base_available
		_discovered_pages[page_id] = base_available
	_set_page_presentations()
	_activate_page(PAGE_TODAY, false)


func _recompute_availability() -> void:
	_ensure_interface()
	for page_id: StringName in PAGE_ORDER:
		if page_id in BASE_PAGES or _snapshot_relevant_to_page(page_id):
			_discovered_pages[page_id] = true

	var prior_focus := _focus_owner()
	var focus_will_hide := false
	if prior_focus != null:
		var focused_page := _page_for_descendant(prior_focus)
		focus_will_hide = focused_page != &"" and focused_page == _current_page_id

	for page_id: StringName in PAGE_ORDER:
		var available := (
			page_id in BASE_PAGES
			or _show_all_filings
			or (not _first_clutch_active and bool(_discovered_pages.get(page_id, false)))
		)
		var changed := available != bool(_page_available.get(page_id, false))
		_page_available[page_id] = available
		if changed:
			page_availability_changed.emit(page_id, available)
	_set_page_presentations()
	if not is_page_available(_current_page_id):
		_activate_page(PAGE_TODAY, focus_will_hide)
	else:
		_activate_page(_current_page_id, false)
	_ensure_focus_not_hidden()


func _set_page_presentations() -> void:
	for page_id: StringName in PAGE_ORDER:
		var available := is_page_available(page_id)
		var button := _page_buttons.get(page_id) as Button
		var scroll := _page_scrolls.get(page_id) as ScrollContainer
		if button != null:
			if not available and button.has_focus():
				button.release_focus()
			button.visible = available
			button.focus_mode = Control.FOCUS_ALL if available else Control.FOCUS_NONE
		if scroll != null:
			scroll.visible = available and page_id == _current_page_id
	_update_more_files_presentation()


func _activate_page(page_id: StringName, grab_tab_focus: bool) -> void:
	if not is_page_available(page_id):
		return
	var changed := _current_page_id != page_id
	var old_scroll := _page_scrolls.get(_current_page_id) as ScrollContainer
	var focus_owner := _focus_owner()
	var focus_was_in_old_page := old_scroll != null and focus_owner != null and old_scroll.is_ancestor_of(focus_owner)
	if focus_was_in_old_page:
		focus_owner.release_focus()
	_current_page_id = page_id
	for candidate_id: StringName in BASE_PAGES:
		var button := _page_buttons.get(candidate_id) as Button
		if button != null:
			button.set_pressed_no_signal(candidate_id == page_id)
	for candidate_id: StringName in PAGE_ORDER:
		var scroll := _page_scrolls.get(candidate_id) as ScrollContainer
		if scroll != null:
			scroll.visible = is_page_available(candidate_id) and candidate_id == page_id
	_update_more_files_presentation()
	if grab_tab_focus or focus_was_in_old_page:
		var target := _focus_control_for_page(page_id)
		if target != null and target.is_visible_in_tree():
			target.grab_focus()
	if changed:
		page_changed.emit(page_id)


func _on_page_button_gui_input(event: InputEvent, _page_id: StringName) -> void:
	if not event.is_pressed() or (event is InputEventKey and event.echo):
		return
	var direction := 0
	if event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"ui_focus_prev"):
		direction = -1
	elif event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"ui_focus_next"):
		direction = 1
	if direction == 0:
		return
	if cycle_page(direction, true):
		accept_event()


func _on_more_files_gui_input(event: InputEvent) -> void:
	_on_page_button_gui_input(event, _current_page_id)


func _on_more_files_item_pressed(item_id: int) -> void:
	if item_id == MORE_FILES_SHOW_ALL_ID:
		set_show_all_filings(not _show_all_filings)
		_more_files_button.grab_focus()
		return
	var popup := _more_files_button.get_popup()
	var item_index := popup.get_item_index(item_id)
	if item_index < 0:
		return
	var metadata: Variant = popup.get_item_metadata(item_index)
	if metadata == null:
		return
	var page_id := StringName(String(metadata))
	if open_page(page_id, true):
		_more_files_button.grab_focus()


func _update_more_files_presentation() -> void:
	if _more_files_button == null:
		return
	var popup := _more_files_button.get_popup()
	# PopupMenu has no per-item visibility API in the project's Godot runtime.
	# Rebuilding this five-entry presentation-only menu keeps undiscovered files
	# genuinely undisclosed without replacing any page or registered control.
	popup.clear()
	for page_index: int in SECONDARY_PAGES.size():
		var page_id := SECONDARY_PAGES[page_index]
		if not is_page_available(page_id):
			continue
		popup.add_item(String(PAGE_LABELS.get(page_id, String(page_id))), page_index)
		popup.set_item_metadata(popup.item_count - 1, page_id)
	if popup.item_count > 0:
		popup.add_separator()
	popup.add_check_item("SHOW EVERY FILE", MORE_FILES_SHOW_ALL_ID)
	popup.set_item_checked(popup.item_count - 1, _show_all_filings)
	_more_files_button.text = (
		"%s  ▾" % String(PAGE_LABELS.get(_current_page_id, "MORE"))
		if _current_page_id in SECONDARY_PAGES else
		"MORE FILES  ▾"
	)
	_more_files_button.set_pressed_no_signal(_current_page_id in SECONDARY_PAGES)
	_more_files_button.tooltip_text = (
		"Current secondary file: %s. Open the menu to switch filing pages."
		% String(PAGE_TITLES.get(_current_page_id, String(_current_page_id)))
		if _current_page_id in SECONDARY_PAGES else
		"Open Operations, Capital, or Records. Show Every File changes presentation only."
	)


func _focus_control_for_page(page_id: StringName) -> Button:
	if page_id in SECONDARY_PAGES:
		return _more_files_button
	return _page_buttons.get(page_id) as Button


func _display_feedback(copy: String) -> String:
	const MAX_VISIBLE_CHARACTERS := 180
	if copy.length() <= MAX_VISIBLE_CHARACTERS:
		return copy
	return copy.left(MAX_VISIBLE_CHARACTERS - 1).rstrip(" ,.;:") + "…"


func _snapshot_relevant_to_page(page_id: StringName) -> bool:
	if _explicit_page_relevance(page_id) or _has_pending_page_receipt(page_id):
		return true
	match page_id:
		PAGE_OPERATIONS:
			return _operations_relevant()
		PAGE_CAPITAL:
			return _capital_relevant()
		PAGE_GOVERNANCE_RECORDS:
			return _governance_relevant()
	return page_id in BASE_PAGES


func _explicit_page_relevance(page_id: StringName) -> bool:
	var relevant_pages_value: Variant = _snapshot.get("relevant_flockwatch_pages", [])
	if relevant_pages_value is Array:
		for value: Variant in relevant_pages_value as Array:
			if _canonical_page_id(StringName(String(value))) == page_id:
				return true
	var relevance_value: Variant = _snapshot.get("flockwatch_relevance", {})
	if relevance_value is not Dictionary:
		return false
	var relevance := relevance_value as Dictionary
	for alias: StringName in _page_aliases(page_id):
		var value: Variant = relevance.get(alias, relevance.get(String(alias), null))
		if _semantic_flag(value):
			return true
	return false


func _has_pending_page_receipt(page_id: StringName) -> bool:
	for root_key: StringName in [&"flockwatch_pending_receipts", &"pending_receipts"]:
		var pending_value: Variant = _snapshot.get(root_key, _snapshot.get(String(root_key), {}))
		if pending_value is not Dictionary:
			continue
		var pending := pending_value as Dictionary
		for alias: StringName in _page_aliases(page_id):
			if _value_present(pending.get(alias, pending.get(String(alias), null))):
				return true
	var keys: Array[StringName] = []
	match page_id:
		PAGE_OPERATIONS:
			keys = OPERATIONS_RECEIPT_KEYS
		PAGE_CAPITAL:
			keys = CAPITAL_RECEIPT_KEYS
		PAGE_GOVERNANCE_RECORDS:
			keys = GOVERNANCE_RECEIPT_KEYS
	for key: StringName in keys:
		if _value_present(_snapshot.get(key, _snapshot.get(String(key), null))):
			return true
	return false


func _operations_relevant() -> bool:
	var owned := _dictionary(_snapshot.get("owned_facilities", {}))
	if _owns_any(owned, OPERATIONS_FACILITY_IDS):
		return true
	if bool(_snapshot.get("feed_party_available", false)):
		return true
	if bool(_snapshot.get("feed_party_used_today", false)) or bool(_snapshot.get("overtime_enabled", false)):
		return true
	var operations := _dictionary(_snapshot.get("operations", {}))
	if (
		int(operations.get("rooster_office_level", 0)) > 0
		or int(operations.get("it_coop_level", 0)) > 0
	):
		return true
	var procurement := _dictionary(_snapshot.get("feed_procurement", {}))
	if (
		int(procurement.get("level", 0)) > 0
		or _value_present(procurement.get("last_order", null))
		or _value_present(procurement.get("last_consumption", null))
		or _value_present(procurement.get("last_spoilage", null))
	):
		return true
	var dispatch := _dictionary(_snapshot.get("farmgate_dispatch", {}))
	return (
		int(dispatch.get("level", 0)) > 0
		or _value_present(dispatch.get("last_authorization_receipt", null))
		or _value_present(dispatch.get("last_settlement_receipt", null))
	)


func _capital_relevant() -> bool:
	var owned := _dictionary(_snapshot.get("owned_facilities", {}))
	for value: Variant in owned.values():
		if int(value) > 0:
			return true
	var catalog_value: Variant = _snapshot.get("facility_catalog", [])
	if catalog_value is Array:
		for facility_value: Variant in catalog_value as Array:
			if facility_value is not Dictionary:
				continue
			var facility := facility_value as Dictionary
			if (
				bool(facility.get("can_purchase", false))
				or bool(facility.get("ready", false))
				or int(facility.get("owned_level", facility.get("level", 0))) > 0
			):
				return true
	var plan := _dictionary(_snapshot.get("capital_plan", {}))
	if (
		bool(plan.get("has_pinned_plan", false))
		or String(plan.get("pinned_capital_plan_id", plan.get("facility_id", ""))) != ""
	):
		return true
	var capacity := _dictionary(_snapshot.get("capacity_upgrade", {}))
	if bool(capacity.get("can_purchase", false)) or int(capacity.get("current_level", 0)) > 0:
		return true
	var treasury := _dictionary(_snapshot.get("farm_treasury", {}))
	if bool(treasury.get("capital_frozen", false)) or int(treasury.get("total_liabilities_cents", 0)) > 0:
		return true
	var campus := _dictionary(_snapshot.get("campus_expansion", {}))
	if (
		bool(campus.get("deed_owned", false))
		or int(campus.get("service_level", campus.get("utilities_level", 0))) > 0
		or _value_present(campus.get("last_purchase_receipt", null))
	):
		return true
	var portfolio := _dictionary(_snapshot.get("campus_portfolio", {}))
	return (
		int(portfolio.get("owned_parcel_count", 0)) > 0
		or int(portfolio.get("commissioned_module_count", 0)) > 0
		or _value_present(portfolio.get("last_purchase_receipt", null))
	)


func _governance_relevant() -> bool:
	var owned := _dictionary(_snapshot.get("owned_facilities", {}))
	if _owns_any(owned, GOVERNANCE_FACILITY_IDS):
		return true
	var relations := _dictionary(_snapshot.get("flock_relations", {}))
	if (
		int(relations.get("level", 0)) > 0
		or int(relations.get("open_case_count", 0)) > 0
		or int(relations.get("resolved_total", 0)) > 0
		or _value_present(relations.get("last_resolution", null))
	):
		return true
	var contract := _dictionary(_snapshot.get("contract_board", {}))
	if (
		bool(contract.get("planning_open", false))
		or bool(contract.get("has_active_contract", false))
		or _value_present(contract.get("active_contract", null))
		or int(contract.get("contracts_signed_total", 0)) > 0
		or _value_present(contract.get("last_receipt", null))
	):
		return true
	var gallery := _dictionary(_snapshot.get("farmer_relations_gallery", {}))
	if int(gallery.get("level", 0)) > 0 or _value_present(gallery.get("last_receipt", null)):
		return true
	for key: StringName in [&"flock_petition", &"flock_petition_history", &"flock_compact", &"flock_compact_receipt"]:
		if _value_present(_snapshot.get(key, _snapshot.get(String(key), null))):
			return true
	var work_to_rule := _dictionary(_snapshot.get("work_to_rule", {}))
	return (
		bool(work_to_rule.get("active", false))
		or bool(work_to_rule.get("scheduled", false))
		or _value_present(work_to_rule.get("record", null))
		or _value_present(work_to_rule.get("queued_record", null))
	)


func _sort_page_sections(page_id: StringName) -> void:
	var content := _page_contents.get(page_id) as VBoxContainer
	if content == null:
		return
	var entries := _section_entries_for_page(page_id)
	for index: int in entries.size():
		var control := entries[index].get("control") as Control
		if control != null and control.get_parent() == content:
			content.move_child(control, index)


func _section_entries_for_page(page_id: StringName) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for value: Variant in _sections.values():
		var entry := value as Dictionary
		if StringName(entry.get("page_id", &"")) == page_id:
			entries.append(entry)
	entries.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			var left_order := int(left.get("sort_order", 0))
			var right_order := int(right.get("sort_order", 0))
			if left_order != right_order:
				return left_order < right_order
			return int(left.get("serial", 0)) < int(right.get("serial", 0))
	)
	return entries


func _section_id_for_control(control: Control) -> StringName:
	for section_id_value: Variant in _sections.keys():
		var entry := _sections[section_id_value] as Dictionary
		if entry.get("control") == control:
			return StringName(section_id_value)
	return &""


func _ensure_focus_not_hidden() -> void:
	var focus_owner := _focus_owner()
	if focus_owner == null:
		return
	var page_id := _page_for_descendant(focus_owner)
	if page_id == &"":
		return
	if page_id != _current_page_id or not is_page_available(page_id):
		focus_owner.release_focus()
		var fallback := _focus_control_for_page(_current_page_id)
		if fallback != null and fallback.is_visible_in_tree():
			fallback.grab_focus()


func _focus_owner() -> Control:
	if not is_inside_tree() or get_viewport() == null:
		return null
	return get_viewport().gui_get_focus_owner()


func _page_for_descendant(control: Control) -> StringName:
	for page_id: StringName in PAGE_ORDER:
		var scroll := _page_scrolls.get(page_id) as ScrollContainer
		if scroll != null and (scroll == control or scroll.is_ancestor_of(control)):
			return page_id
	return &""


func _on_page_pressed(page_id: StringName) -> void:
	_activate_page(page_id, false)


func _owns_any(owned: Dictionary, facility_ids: Array[StringName]) -> bool:
	for facility_id: StringName in facility_ids:
		if int(owned.get(facility_id, owned.get(String(facility_id), 0))) > 0:
			return true
	return false


func _dictionary(value: Variant) -> Dictionary:
	return value as Dictionary if value is Dictionary else {}


func _semantic_flag(value: Variant) -> bool:
	if value is Dictionary:
		var dictionary := value as Dictionary
		for key: StringName in [&"relevant", &"available", &"visible", &"enabled", &"owned", &"active", &"pending"]:
			if bool(dictionary.get(key, dictionary.get(String(key), false))):
				return true
		for key: StringName in [&"level", &"count", &"pending_receipt_count", &"owned_level"]:
			if int(dictionary.get(key, dictionary.get(String(key), 0))) > 0:
				return true
		return false
	return _value_present(value)


func _value_present(value: Variant) -> bool:
	if value == null:
		return false
	if value is Dictionary:
		return not (value as Dictionary).is_empty()
	if value is Array:
		return not (value as Array).is_empty()
	if value is String or value is StringName:
		return not String(value).strip_edges().is_empty()
	if value is bool:
		return bool(value)
	if value is int or value is float:
		return float(value) > 0.0
	return false


func _page_aliases(page_id: StringName) -> Array[StringName]:
	match page_id:
		PAGE_TODAY:
			return [&"today"]
		PAGE_FLOCK:
			return [&"flock"]
		PAGE_OPERATIONS:
			return [&"operations", &"ops"]
		PAGE_CAPITAL:
			return [&"capital", &"build"]
		PAGE_GOVERNANCE_RECORDS:
			return [&"governance_records", &"governance", &"records"]
	return []


func _canonical_page_id(value: StringName) -> StringName:
	for page_id: StringName in PAGE_ORDER:
		if value in _page_aliases(page_id):
			return page_id
	return &""


func _pascal_case(value: StringName) -> String:
	var pieces := String(value).split("_", false)
	var result := ""
	for piece: String in pieces:
		result += piece.capitalize()
	return result
