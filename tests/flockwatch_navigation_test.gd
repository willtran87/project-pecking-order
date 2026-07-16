extends SceneTree

const FlockwatchNavigationScript := preload("res://features/office/flockwatch_navigation.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	var harness := Control.new()
	harness.name = "FlockwatchNavigationTestHarness"
	harness.size = Vector2(1280.0, 720.0)
	root.add_child(harness)

	var legacy_scroll := ScrollContainer.new()
	legacy_scroll.name = "FlockwatchScroll"
	legacy_scroll.position = Vector2(700.0, 0.0)
	legacy_scroll.size = Vector2(300.0, 700.0)
	legacy_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	legacy_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	harness.add_child(legacy_scroll)
	var staging := VBoxContainer.new()
	staging.name = "OriginalFlockwatchLedger"
	staging.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legacy_scroll.add_child(staging)
	var before := _section("Before", 20.0)
	var today := _section("TodayOrders", 620.0)
	var today_queue := _section("TodayQueue", 90.0)
	var flock := _section("FlockRoster", 560.0)
	var operations := _section("OperationsControls", 240.0)
	var capital := _section("CapitalControls", 260.0)
	var governance := _section("GovernanceRecords", 280.0)
	var after := _section("After", 20.0)
	for section: VBoxContainer in [before, today, today_queue, flock, operations, capital, governance, after]:
		staging.add_child(section)
	var context_action_host := VBoxContainer.new()
	context_action_host.name = "ExistingRequiredActionHost"
	harness.add_child(context_action_host)
	var required_action := Button.new()
	required_action.name = "ContinueRequiredAction"
	required_action.text = "CONTINUE REQUIRED FILING"
	required_action.focus_mode = Control.FOCUS_ALL
	required_action.custom_minimum_size = Vector2(240.0, 38.0)
	context_action_host.add_child(required_action)
	var required_action_id := required_action.get_instance_id()
	var required_action_focus_mode := required_action.focus_mode

	var capital_action := capital.find_child("CapitalControlsAction", true, false) as Button
	var original_focus_mode := capital_action.focus_mode
	var observed_actions := {"capital": 0, "required": 0}
	capital_action.pressed.connect(func() -> void: observed_actions["capital"] += 1)
	required_action.pressed.connect(func() -> void: observed_actions["required"] += 1)

	var navigation := FlockwatchNavigationScript.new() as FlockwatchNavigation
	navigation.position = Vector2(16.0, 16.0)
	navigation.size = Vector2(272.0, 360.0)
	harness.add_child(navigation)
	var page_changes: Array[StringName] = []
	var availability_changes: Array[Dictionary] = []
	var show_all_changes: Array[bool] = []
	navigation.page_changed.connect(func(page_id: StringName) -> void: page_changes.append(page_id))
	navigation.page_availability_changed.connect(
		func(page_id: StringName, available: bool) -> void:
			availability_changes.append({"page_id": page_id, "available": available})
	)
	navigation.show_all_filings_changed.connect(func(enabled: bool) -> void: show_all_changes.append(enabled))
	await process_frame

	# Adopt a required action that already belongs to another surface. The exact
	# control, its signal wiring, and keyboard semantics must survive reparenting,
	# and its stable host must remain above every page-specific scroll surface.
	_check(navigation.adopt_context_action(required_action), "A pre-existing required action should be adoptable", failures)
	await process_frame
	var context_actions := navigation.context_actions()
	var page_deck := navigation.find_child("FlockwatchPageDeck", false, false) as Control
	_check(
		required_action.get_instance_id() == required_action_id
		and required_action.name == "ContinueRequiredAction"
		and required_action.get_parent() == context_actions,
		"Context adoption should preserve the exact required action identity",
		failures,
	)
	_check(
		context_actions != null
		and page_deck != null
		and context_actions.get_parent() == navigation
		and page_deck.get_parent() == navigation
		and context_actions.get_index() < page_deck.get_index(),
		"Required context actions should be hosted above the page deck",
		failures,
	)
	_check(
		required_action.focus_mode == required_action_focus_mode
		and required_action.is_visible_in_tree(),
		"Context adoption should preserve focus semantics and immediate reachability",
		failures,
	)
	required_action.pressed.emit()
	_check(int(observed_actions["required"]) == 1, "A pre-connected required action signal should survive adoption", failures)
	required_action.grab_focus()
	await process_frame
	_check(root.gui_get_focus_owner() == required_action, "The adopted required action should accept keyboard focus", failures)

	# Register out of original order to prove that the controls themselves and
	# their original sibling positions remain intact.
	_check(navigation.register_section(FlockwatchNavigation.PAGE_CAPITAL, capital, &"capital", 20), "Capital should register", failures)
	_check(navigation.register_section(FlockwatchNavigation.PAGE_TODAY, today, &"today_orders", 10), "Today orders should register", failures)
	_check(navigation.register_section(FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS, governance, &"governance", 10), "Governance should register", failures)
	_check(navigation.register_section(FlockwatchNavigation.PAGE_FLOCK, flock, &"flock", 10), "Flock should register", failures)
	_check(navigation.register_section(FlockwatchNavigation.PAGE_OPERATIONS, operations, &"operations", 10), "Operations should register", failures)
	_check(navigation.register_section(FlockwatchNavigation.PAGE_TODAY, today_queue, &"today_queue", 0), "Today queue should register", failures)
	_check(not navigation.register_section(FlockwatchNavigation.PAGE_TODAY, today, &"duplicate", 0), "A control already inside the navigator should not register twice", failures)
	_check(not navigation.register_section(&"invented", before, &"invented", 0), "Unknown pages should be rejected", failures)
	_check(
		navigation.adopt_page_scroll(FlockwatchNavigation.PAGE_TODAY, legacy_scroll, staging),
		"The existing FlockwatchScroll should be reusable as the Today page",
		failures,
	)
	await process_frame
	await process_frame

	_check(navigation.page_scroll(FlockwatchNavigation.PAGE_TODAY) == legacy_scroll, "Adoption should preserve the exact legacy scroll object", failures)
	_check(legacy_scroll.name == "FlockwatchScroll", "Adoption should preserve the legacy FlockwatchScroll name", failures)
	_check(today.name == "TodayOrders" and capital.name == "CapitalControls", "Reparenting should preserve section names", failures)
	_check(capital_action != null and capital_action.name == "CapitalControlsAction", "Reparenting should preserve descendant names", failures)
	_check(capital_action != null and capital_action.focus_mode == original_focus_mode, "Reparenting should preserve descendant focus modes", failures)
	_check(capital.get_parent() == navigation.page_content(FlockwatchNavigation.PAGE_CAPITAL), "Capital should move into its persistent page", failures)
	_check(today.get_parent() == navigation.page_content(FlockwatchNavigation.PAGE_TODAY), "Today should move into its persistent page", failures)
	_check(
		navigation.registered_section_ids(FlockwatchNavigation.PAGE_TODAY) == [&"today_queue", &"today_orders"],
		"Page-local sort order should be stable and queryable",
		failures,
	)
	_check(navigation.page_for_section(&"governance") == FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS, "Section lookup should retain its page identity", failures)
	if capital_action != null:
		capital_action.pressed.emit()
	_check(int(observed_actions["capital"]) == 1, "Existing child signal connections should survive registration", failures)

	# Even strong advanced evidence stays out of the First Clutch default. The
	# evidence is remembered so it can appear after induction without data loss.
	navigation.apply_snapshot({
		"day": 1,
		"first_clutch": {"visible": true, "stage": &"specialty_route"},
		"owned_facilities": {&"it_coop": 1},
		"facility_catalog": [{"facility_id": &"records_annex", "can_purchase": true}],
		"pending_receipts": {"records": {"receipt_id": "FR-1"}},
	})
	await process_frame
	_check(
		navigation.available_page_ids() == [FlockwatchNavigation.PAGE_TODAY, FlockwatchNavigation.PAGE_FLOCK],
		"Fresh First Clutch should expose only Today and Flock",
		failures,
	)
	for hidden_page: StringName in [FlockwatchNavigation.PAGE_OPERATIONS, FlockwatchNavigation.PAGE_CAPITAL, FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS]:
		var hidden_button := navigation.page_button(hidden_page)
		_check(hidden_button != null and not hidden_button.visible and hidden_button.focus_mode == Control.FOCUS_NONE, "%s should be hidden and absent from keyboard focus" % String(hidden_page), failures)
		_check(not navigation.page_scroll(hidden_page).visible, "%s content should be hidden" % String(hidden_page), failures)
	_check(not navigation.open_page(FlockwatchNavigation.PAGE_CAPITAL), "A hidden filing page should not open through the public API", failures)

	# Context actions sit outside every page scroll. Page changes must therefore
	# leave a required focused action visible and reachable instead of burying it
	# with whichever filing was just closed.
	required_action.grab_focus()
	await process_frame
	for available_page: StringName in [FlockwatchNavigation.PAGE_FLOCK, FlockwatchNavigation.PAGE_TODAY]:
		_check(navigation.open_page(available_page), "%s should be available during First Clutch" % String(available_page), failures)
		await process_frame
		_check(
			required_action.is_visible_in_tree()
			and root.gui_get_focus_owner() == required_action,
			"required context action should remain visible and focused while switching to %s" % String(available_page),
			failures,
		)
	required_action.pressed.emit()
	_check(int(observed_actions["required"]) == 2, "Required action should remain connected after page switching", failures)

	# The explicit escape hatch preserves reachability without teaching the
	# presentation layer anything about the economy.
	navigation.set_show_all_filings(true)
	await process_frame
	_check(navigation.available_page_ids() == FlockwatchNavigation.PAGE_ORDER, "Show All Filings should expose all five pages", failures)
	_check(navigation.open_page(FlockwatchNavigation.PAGE_CAPITAL), "Show All should make Capital reachable", failures)
	await process_frame
	if capital_action != null:
		capital_action.grab_focus()
	await process_frame
	_check(root.gui_get_focus_owner() == capital_action, "A registered Capital action should retain normal keyboard focus", failures)
	navigation.set_show_all_filings(false)
	await process_frame
	_check(navigation.current_page_id() == FlockwatchNavigation.PAGE_TODAY, "Hiding the active advanced page should fall back to Today", failures)
	_check(root.gui_get_focus_owner() != capital_action, "A hidden page must never retain keyboard focus", failures)
	_check(root.gui_get_focus_owner() == navigation.page_button(FlockwatchNavigation.PAGE_TODAY), "Focus should move to the safe visible Today tab", failures)
	_check(show_all_changes == [true, false], "The escape hatch should emit presentation intent exactly once per change", failures)

	# Verify each supported semantic discovery source independently.
	navigation.apply_snapshot({"day": 2, "first_clutch_active": false})
	navigation.reset_discovered_pages()
	_check(navigation.available_page_ids() == [FlockwatchNavigation.PAGE_TODAY, FlockwatchNavigation.PAGE_FLOCK], "A quiet post-induction snapshot should remain progressive", failures)
	navigation.apply_snapshot({"day": 2, "feed_party_available": true})
	_check(navigation.is_page_available(FlockwatchNavigation.PAGE_OPERATIONS), "A relevant live operation should discover Operations", failures)
	navigation.apply_snapshot({"day": 2})
	_check(navigation.is_page_available(FlockwatchNavigation.PAGE_OPERATIONS), "A discovered page should remain reachable after a transient flag clears", failures)

	navigation.reset_discovered_pages()
	navigation.apply_snapshot({
		"day": 3,
		"facility_catalog": [{"facility_id": &"records_annex", "can_purchase": true}],
	})
	_check(navigation.is_page_available(FlockwatchNavigation.PAGE_CAPITAL), "A ready authoritative facility should discover Capital", failures)

	navigation.apply_snapshot({"day": 3})
	navigation.reset_discovered_pages()
	navigation.apply_snapshot({
		"day": 3,
		"pending_receipts": {"records": [{"receipt_id": "PETITION-3"}]},
	})
	_check(navigation.is_page_available(FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS), "A pending Records receipt should discover Governance / Records", failures)

	navigation.apply_snapshot({"day": 6})
	navigation.reset_discovered_pages()
	navigation.apply_snapshot({
		"day": 6,
		"owned_facilities": {&"rooster_operations_office": 1},
	})
	_check(navigation.is_page_available(FlockwatchNavigation.PAGE_OPERATIONS), "Old-save ownership should discover Operations immediately", failures)
	_check(navigation.is_page_available(FlockwatchNavigation.PAGE_CAPITAL), "Any commissioned facility should keep its Capital filing reachable", failures)

	# Each page keeps an independent vertical scroll position, and the HFlow tab
	# rail remains contained when all five pages wrap at ledger width.
	navigation.apply_snapshot({"day": 2})
	navigation.reset_discovered_pages()
	navigation.set_show_all_filings(true)
	navigation.open_page(FlockwatchNavigation.PAGE_TODAY)
	await process_frame
	await process_frame
	var today_scroll := navigation.page_scroll(FlockwatchNavigation.PAGE_TODAY)
	var flock_scroll := navigation.page_scroll(FlockwatchNavigation.PAGE_FLOCK)
	_check(today_scroll.follow_focus and today_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "Page scroll should follow keyboard focus and remain automatic", failures)
	_check(today_scroll.get_v_scroll_bar().max_value > today_scroll.get_v_scroll_bar().page, "Tall Today filings should remain vertically scrollable", failures)
	today_scroll.scroll_vertical = 110
	await process_frame
	var today_position := today_scroll.scroll_vertical
	navigation.open_page(FlockwatchNavigation.PAGE_FLOCK)
	await process_frame
	flock_scroll.scroll_vertical = 75
	await process_frame
	var flock_position := flock_scroll.scroll_vertical
	navigation.open_page(FlockwatchNavigation.PAGE_TODAY)
	await process_frame
	_check(today_position > 0 and today_scroll.scroll_vertical == today_position, "Today should retain its independent scroll position", failures)
	navigation.open_page(FlockwatchNavigation.PAGE_FLOCK)
	await process_frame
	_check(flock_position > 0 and flock_scroll.scroll_vertical == flock_position, "Flock should retain its independent scroll position", failures)

	var navigation_rect := navigation.get_global_rect()
	for page_id: StringName in FlockwatchNavigation.PAGE_ORDER:
		var button := navigation.page_button(page_id)
		var rect := button.get_global_rect()
		_check(
			rect.position.x >= navigation_rect.position.x - 0.5 and rect.end.x <= navigation_rect.end.x + 0.5,
			"%s tab should wrap inside a 272 px ledger" % String(page_id),
			failures,
		)
	_check(navigation.page_content(FlockwatchNavigation.PAGE_TODAY).size.x <= navigation.size.x + 0.5, "Compact page content should not require horizontal scrolling", failures)
	_check(navigation.all_filings_button().focus_mode == Control.FOCUS_ALL, "All Filings should remain keyboard reachable", failures)
	_check(_contains_all(navigation.accessible_text(), ["flockwatch", "available", "6 sections", "all filings shown"]), "Navigation should publish a concise accessibility summary", failures)

	# With Show All active, every registered feature root is reachable through at
	# most one page selection and remains the exact same object.
	var page_controls := {
		FlockwatchNavigation.PAGE_TODAY: [today, today_queue],
		FlockwatchNavigation.PAGE_FLOCK: [flock],
		FlockwatchNavigation.PAGE_OPERATIONS: [operations],
		FlockwatchNavigation.PAGE_CAPITAL: [capital],
		FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS: [governance],
	}
	for page_id: StringName in FlockwatchNavigation.PAGE_ORDER:
		_check(navigation.open_page(page_id), "%s should open from its visible tab" % String(page_id), failures)
		await process_frame
		for control: Control in page_controls[page_id]:
			_check(control.is_visible_in_tree(), "%s should expose every registered feature root" % String(page_id), failures)

	# Natural keyboard cycling skips unavailable tabs and focuses the visible tab.
	navigation.set_show_all_filings(false)
	navigation.apply_snapshot({"day": 2})
	navigation.reset_discovered_pages()
	navigation.open_page(FlockwatchNavigation.PAGE_TODAY)
	_check(navigation.cycle_page(1, true), "Keyboard cycling should advance between available pages", failures)
	await process_frame
	_check(navigation.current_page_id() == FlockwatchNavigation.PAGE_FLOCK, "Keyboard cycling should skip hidden advanced pages", failures)
	_check(root.gui_get_focus_owner() == navigation.page_button(FlockwatchNavigation.PAGE_FLOCK), "Keyboard cycling should focus its visible destination", failures)

	# Restoration is lossless even though registration happened out of order.
	navigation.restore_registered_sections()
	await process_frame
	var restored_names: Array[String] = []
	for child: Node in staging.get_children():
		restored_names.append(child.name)
	_check(
		restored_names == ["Before", "TodayOrders", "TodayQueue", "FlockRoster", "OperationsControls", "CapitalControls", "GovernanceRecords", "After"],
		"Restoring should recover the exact original sibling order (got %s)" % str(restored_names),
		failures,
	)
	_check(navigation.registered_section_ids().is_empty(), "Restoring should empty the navigator registry", failures)
	if capital_action != null:
		capital_action.pressed.emit()
	_check(int(observed_actions["capital"]) == 2, "Child signals should remain connected after restoration", failures)

	navigation.free()
	harness.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("FLOCKWATCH_NAVIGATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FLOCKWATCH_NAVIGATION_TEST_PASSED pages=5 first_clutch=2 context=stable relevance=operations+capital+records show_all=reachable focus=safe scroll=independent compact=272px reparent=lossless")
	quit(0)


func _section(section_name: String, minimum_height: float) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.name = section_name
	section.custom_minimum_size = Vector2(0.0, minimum_height)
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var action := Button.new()
	action.name = "%sAction" % section_name
	action.text = "%s ACTION" % section_name.to_snake_case().replace("_", " ").to_upper()
	action.focus_mode = Control.FOCUS_ALL
	action.custom_minimum_size.y = 38.0
	section.add_child(action)
	var copy := Label.new()
	copy.text = "%s filing content remains owned by its original feature." % section_name
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section.add_child(copy)
	return section


func _contains_all(copy: String, fragments: Array[String]) -> bool:
	var normalized := copy.to_lower()
	for fragment: String in fragments:
		if fragment.to_lower() not in normalized:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
