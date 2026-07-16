extends SceneTree

const CampusExpansionUIScript := preload("res://features/office/campus_expansion_ui.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observed := {
		"close": 0,
		"parcels": [] as Array[StringName],
		"services": [] as Array[StringName],
		"placements": [] as Array[StringName],
		"relocations": [] as Array[Dictionary],
	}
	var harness := Control.new()
	harness.name = "CampusExpansionUITestHarness"
	harness.size = Vector2(1280.0, 720.0)
	root.add_child(harness)
	var ui := CampusExpansionUIScript.new() as CampusExpansionUI
	harness.add_child(ui)
	ui.close_requested.connect(func() -> void: observed["close"] += 1)
	ui.purchase_parcel_requested.connect(func(parcel_id: StringName) -> void: (observed["parcels"] as Array).append(parcel_id))
	ui.connect_service_requested.connect(func(service_id: StringName) -> void: (observed["services"] as Array).append(service_id))
	ui.place_pod_requested.connect(func(socket_id: StringName) -> void: (observed["placements"] as Array).append(socket_id))
	ui.relocate_pod_requested.connect(
		func(from_socket_id: StringName, to_socket_id: StringName) -> void:
			(observed["relocations"] as Array).append({
				"from": from_socket_id,
				"to": to_socket_id,
			})
	)
	await process_frame

	_check(not ui.is_open(), "the Campus Expansion planner should be hidden by default like Capital Blueprint", failures)
	ui.set_snapshot(_snapshot(false, true))
	ui.show_planner()
	await process_frame
	await process_frame

	var main_panel := ui.find_child("CampusExpansionPanel", true, false) as PanelContainer
	var body_scroll := ui.find_child("CampusExpansionBodyScroll", true, false) as ScrollContainer
	var desktop_body := ui.find_child("CampusExpansionDesktopBody", true, false) as HBoxContainer
	var site_panel := ui.find_child("CampusExpansionSitePanel", true, false) as PanelContainer
	var project_panel := ui.find_child("CampusExpansionProjectPanel", true, false) as PanelContainer
	var action_rail := ui.find_child("CampusExpansionActionRail", true, false) as HBoxContainer
	var header := ui.find_child("CampusExpansionHeaderStatus", true, false) as Label
	var parcel_status := ui.find_child("CampusExpansionParcelStatus", true, false) as Label
	var parcel_costs := ui.find_child("CampusExpansionParcelCosts", true, false) as Label
	var parcel_reason := ui.find_child("CampusExpansionParcelReason", true, false) as Label
	var parcel_button := ui.find_child("CampusExpansionPurchaseParcelButton", true, false) as Button
	var place_button := ui.find_child("CampusExpansionPlacePodButton", true, false) as Button
	var relocate_button := ui.find_child("CampusExpansionRelocatePodButton", true, false) as Button
	var close_button := ui.find_child("CampusExpansionCloseButton", true, false) as Button
	var socket_detail := ui.find_child("CampusExpansionSocketDetail", true, false) as Label
	var benefit_summary := ui.find_child("CampusExpansionBenefitSummary", true, false) as Label

	_check(ui.is_open(), "show_planner should reveal the standalone planning surface", failures)
	_check(ui.layout_mode_name() == &"desktop", "1280x720 should use the desktop campus composition", failures)
	_check(main_panel != null and main_panel.get_global_rect().end.x <= harness.size.x + 0.5, "campus panel should fit the desktop viewport", failures)
	_check(site_panel != null and project_panel != null and site_panel.get_parent() == desktop_body and project_panel.get_parent() == desktop_body, "desktop should compose site and project detail side by side", failures)
	_check(site_panel != null and project_panel != null and is_equal_approx(site_panel.size_flags_stretch_ratio, 5.5) and is_equal_approx(project_panel.size_flags_stretch_ratio, 4.5), "desktop should preserve its weighted site/project split", failures)
	_check(action_rail != null and body_scroll != null and not body_scroll.is_ancestor_of(action_rail), "pod confirmation and Return should remain in a fixed rail", failures)
	_check(header != null and _contains_all(header.text, ["north meadow", "deed filed", "pod unplaced"]), "header should summarize parcel and pod status", failures)

	_check(parcel_status != null and parcel_status.text == "DEED FILED", "North Meadow status should be exact and visible", failures)
	_check(parcel_costs != null and _contains_all(parcel_costs.text, ["purchase", "$85.00", "recurring", "$3.00/day"]), "North Meadow should show exact purchase and recurring costs", failures)
	_check(parcel_button != null and parcel_button.disabled and "OWNED" in parcel_button.text, "owned North Meadow should disable duplicate purchase", failures)
	_check(parcel_reason != null and _contains_all(parcel_reason.text, ["already", "campus deed"]), "disabled parcel action should print a plain-language reason", failures)

	_check(ui.find_children("CampusExpansionServiceCard_*", "PanelContainer", true, false).size() == 3, "circulation, power, and cold-chain should render as three stable utility cards", failures)
	var circulation_costs := ui.find_child("CampusExpansionServiceCosts_circulation", true, false) as Label
	var power_costs := ui.find_child("CampusExpansionServiceCosts_power", true, false) as Label
	var cold_costs := ui.find_child("CampusExpansionServiceCosts_cold_chain", true, false) as Label
	var power_dependencies := ui.find_child("CampusExpansionServiceDependencies_power", true, false) as Label
	var cold_reason := ui.find_child("CampusExpansionServiceReason_cold_chain", true, false) as Label
	var circulation_button := ui.find_child("CampusExpansionConnectService_circulation", true, false) as Button
	var power_button := ui.find_child("CampusExpansionConnectService_power", true, false) as Button
	var cold_button := ui.find_child("CampusExpansionConnectService_cold_chain", true, false) as Button
	_check(circulation_costs != null and _contains_all(circulation_costs.text, ["$28.00", "$1.50/day"]), "circulation card should retain exact purchase and recurring costs", failures)
	_check(power_costs != null and _contains_all(power_costs.text, ["$35.00", "$2.25/day"]), "power card should retain exact purchase and recurring costs", failures)
	_check(cold_costs != null and _contains_all(cold_costs.text, ["$60.00", "$4.00/day"]), "cold-chain card should retain exact purchase and recurring costs", failures)
	_check(power_dependencies != null and _contains_all(power_dependencies.text, ["cleared", "north meadow", "held", "circulation trench"]), "power card should retain every explicit dependency", failures)
	_check(circulation_button != null and circulation_button.disabled and "CONNECTED" in circulation_button.text, "connected circulation should disable duplicate service authorization", failures)
	_check(power_button != null and not power_button.disabled and _contains_all(power_button.text, ["connect", "$35.00"]), "ready power quote should be explicitly actionable", failures)
	_check(cold_button != null and cold_button.disabled and cold_reason != null and _contains_all(cold_reason.text, ["connect", "power", "first"]), "blocked cold-chain should display its plain-language dependency reason", failures)
	if cold_button != null:
		cold_button.pressed.emit()
	if power_button != null:
		power_button.pressed.emit()
	_check((observed["services"] as Array) == [&"power"], "only the authoritative ready service should emit a stable connect intent", failures)
	var service_state := ui.presentation_state().get("services", []) as Array
	_check(not bool((service_state[1] as Dictionary).get("connected", true)), "service intent should not optimistically connect power", failures)

	var west_button := ui.find_child("CampusExpansionSocket_meadow_west", true, false) as Button
	var east_button := ui.find_child("CampusExpansionSocket_meadow_east", true, false) as Button
	var spine_button := ui.find_child("CampusExpansionSocket_service_spine", true, false) as Button
	_check(west_button != null and east_button != null and spine_button != null, "Socket A/B/C should retain stable route buttons", failures)
	_check(spine_button != null and _contains_all(spine_button.text, ["service spine", "route blocked"]), "Socket C should advertise its blocked route before selection", failures)
	_check(west_button != null and east_button != null and spine_button != null and west_button.focus_mode == Control.FOCUS_ALL and east_button.focus_mode == Control.FOCUS_ALL and spine_button.focus_mode == Control.FOCUS_ALL, "all sockets should remain selectable and keyboard focusable", failures)
	ui.select_socket(&"service_spine")
	_check(socket_detail != null and _contains_all(socket_detail.text, ["service spine", "circulation route", "placement quote", "$75.00"]), "selected blocked socket should retain route explanation and exact quote", failures)
	_check(place_button != null and place_button.disabled and _contains_all(place_button.tooltip_text, ["service spine", "circulation route"]), "blocked route should disable placement with the same visible reason", failures)
	ui.select_socket(&"meadow_west")
	_check(place_button != null and place_button.visible and not place_button.disabled and _contains_all(place_button.text, ["place egg routing pod", "$75.00"]), "cleared Socket A should expose the exact pod placement quote", failures)
	_check(relocate_button != null and not relocate_button.visible, "unplaced pod should not expose relocation", failures)
	if place_button != null:
		place_button.pressed.emit()
	_check((observed["placements"] as Array) == [&"meadow_west"], "placement confirmation should emit only the selected stable socket ID", failures)
	_check(not bool((ui.presentation_state().get("routing_pod", {}) as Dictionary).get("placed", true)), "placement intent should not optimistically install the pod", failures)

	_check(ui.find_children("CampusExpansionStage_*", "PanelContainer", true, false).size() == 4, "all four authored construction stages should remain visible", failures)
	_check(benefit_summary != null and _contains_all(benefit_summary.text, ["four filed stages", "operational after commissioning", "six claim files", "six farmgate eggs"]), "construction and operational benefit summary should remain authored and complete", failures)
	_check(_contains_all(ui.accessible_text(), ["north meadow", "$85.00", "meadow power drop", "$35.00", "service spine", "circulation route", "four filed stages"]), "all planning decisions should be represented in accessible copy", failures)

	# Semantic arrow navigation changes presentation selection without hardcoded keys.
	var right := InputEventAction.new()
	right.action = &"ui_right"
	right.pressed = true
	if west_button != null:
		west_button.gui_input.emit(right)
	await process_frame
	_check(ui.selected_socket_id() == &"meadow_east", "semantic ui_right should move Socket A selection to Socket B", failures)

	# A purchasable deed emits its exact parcel ID and never changes itself locally.
	ui.set_snapshot(_snapshot(false, false))
	await process_frame
	parcel_button = ui.find_child("CampusExpansionPurchaseParcelButton", true, false) as Button
	_check(parcel_button != null and not parcel_button.disabled and _contains_all(parcel_button.text, ["purchase north meadow", "$85.00"]), "ready North Meadow deed should expose its exact purchase quote", failures)
	if parcel_button != null:
		parcel_button.pressed.emit()
	_check((observed["parcels"] as Array) == [&"north_meadow"], "parcel confirmation should emit only the stable North Meadow intent", failures)
	_check(not bool((ui.presentation_state().get("parcel", {}) as Dictionary).get("owned", true)), "parcel confirmation should not optimistically mutate authoritative state", failures)

	# Installed west pod switches the action rail to an exact west-to-east relocation.
	ui.set_snapshot(_snapshot(true, true))
	ui.select_socket(&"meadow_east")
	await process_frame
	place_button = ui.find_child("CampusExpansionPlacePodButton", true, false) as Button
	relocate_button = ui.find_child("CampusExpansionRelocatePodButton", true, false) as Button
	_check(place_button != null and not place_button.visible and relocate_button != null and relocate_button.visible, "installed pod should switch the fixed action from place to relocate", failures)
	_check(relocate_button != null and not relocate_button.disabled and _contains_all(relocate_button.text, ["relocate egg routing pod", "$18.00"]), "cleared Socket B should expose the exact relocation quote", failures)
	if relocate_button != null:
		relocate_button.pressed.emit()
	_check(
		(observed["relocations"] as Array) == [{"from": &"meadow_west", "to": &"meadow_east"}],
		"relocation confirmation should emit exact from/to stable socket IDs",
		failures,
	)
	_check(StringName(String((ui.presentation_state().get("routing_pod", {}) as Dictionary).get("current_socket_id", ""))) == &"meadow_west", "relocation intent should not optimistically move the pod", failures)

	# The authoritative flat migration/tool projection should drive the identical
	# visible cards and derive its stage/effect summary from exact snapshot fields.
	ui.set_snapshot(_flat_snapshot())
	ui.select_socket(&"meadow_east")
	await process_frame
	parcel_costs = ui.find_child("CampusExpansionParcelCosts", true, false) as Label
	power_costs = ui.find_child("CampusExpansionServiceCosts_power", true, false) as Label
	benefit_summary = ui.find_child("CampusExpansionBenefitSummary", true, false) as Label
	relocate_button = ui.find_child("CampusExpansionRelocatePodButton", true, false) as Button
	_check(parcel_costs != null and _contains_all(parcel_costs.text, ["$85.00", "$3.00/day"]), "flat parcel_quote should drive exact UI terms", failures)
	_check(power_costs != null and _contains_all(power_costs.text, ["$35.00", "$2.25/day"]), "flat service quote should drive exact utility terms", failures)
	_check(benefit_summary != null and _contains_all(benefit_summary.text, ["4 / 4 complete", "+6 files", "+6 eggs", "$15.75/day"]), "flat status and bonus fields should drive staged operational summary", failures)
	_check(relocate_button != null and not relocate_button.disabled and "$18.00" in relocate_button.text, "nested flat relocation quote should drive the fixed action", failures)

	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	ui._unhandled_key_input(cancel)
	_check(int(observed["close"]) == 1 and ui.is_open(), "semantic ui_cancel should emit close intent without hiding host state", failures)
	_check(close_button != null and close_button.focus_mode == Control.FOCUS_ALL, "Return should remain in natural focus order", failures)

	harness.size = Vector2(844.0, 390.0)
	await process_frame
	await process_frame
	var compact_body := ui.find_child("CampusExpansionCompactBody", true, false) as VBoxContainer
	_check(ui.layout_mode_name() == &"compact", "844x390 should switch to compact campus planning", failures)
	_check(site_panel != null and project_panel != null and site_panel.get_parent() == compact_body and project_panel.get_parent() == compact_body, "compact mode should stack site above project detail", failures)
	_check(body_scroll != null and body_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "compact stacked planning should remain scrollable", failures)
	_check(action_rail != null and not body_scroll.is_ancestor_of(action_rail), "compact scrolling should not move the action rail", failures)
	if main_panel != null:
		var rect := main_panel.get_global_rect()
		_check(rect.position.x >= -0.5 and rect.end.x <= harness.size.x + 0.5 and rect.end.y <= harness.size.y + 0.5, "compact planner should fit inside 844x390", failures)
	_check(relocate_button != null and relocate_button.is_visible_in_tree() and relocate_button.get_global_rect().end.y <= harness.size.y + 0.5, "compact relocation confirmation should remain physically reachable", failures)

	ui.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPUS_EXPANSION_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_EXPANSION_UI_TEST_PASSED hidden=default desktop=weighted compact=844x390 utilities=3 sockets=A/B/C intents=parcel+service+place+relocate")
	quit(0)


func _snapshot(pod_placed: bool, parcel_owned: bool) -> Dictionary:
	return {
		"campus_expansion": {
			"selected_socket_id": &"meadow_west",
			"parcel": {
				"id": &"north_meadow",
				"name": "NORTH MEADOW PARCEL",
				"owned": parcel_owned,
				"can_purchase": not parcel_owned,
				"status_label": "DEED FILED" if parcel_owned else "READY",
				"capital_cost_cents": 8_500,
				"daily_cost_cents": 300,
				"dependency_lines": ["Day 6 review open.", "Farmgate Depot level 1 commissioned."],
				"benefits": ["Opens the east-campus construction apron."],
			},
			"utilities": [
				{"id": &"circulation", "name": "MEADOW CIRCULATION LINK", "connected": true, "can_connect": false, "capital_cost_cents": 2_800, "daily_cost_cents": 150, "dependencies": [{"label": "North Meadow deed", "met": true}]},
				{"id": &"power", "name": "MEADOW POWER DROP", "connected": false, "can_connect": true, "capital_cost_cents": 3_500, "daily_cost_cents": 225, "dependencies": [{"label": "North Meadow deed", "met": true}, {"label": "Circulation trench inspection", "met": false}]},
				{"id": &"cold_chain", "name": "MEADOW COLD-CHAIN LOOP", "connected": false, "can_connect": false, "capital_cost_cents": 6_000, "daily_cost_cents": 400, "dependencies": [{"label": "Meadow Power Drop", "met": false}], "reason": "Connect Meadow Power Drop first."},
			],
			"sockets": [
				{"id": &"meadow_west", "name": "SOCKET A / MEADOW WEST", "route_blocked": false, "can_place": not pod_placed, "can_relocate": false, "reason": "Circulation and power routes clear the west apron."},
				{"id": &"meadow_east", "name": "SOCKET B / MEADOW EAST", "route_blocked": false, "can_place": not pod_placed, "can_relocate": pod_placed, "reason": "East apron route is clear."},
				{"id": &"service_spine", "name": "SOCKET C / SERVICE SPINE", "route_blocked": true, "can_place": false, "can_relocate": false, "blocked_reason": "The Service Spine is reserved for the flock circulation route."},
			],
			"module": {
				"id": &"egg_routing_pod",
				"name": "EGG ROUTING POD",
				"owned": pod_placed,
				"socket_id": &"meadow_west" if pod_placed else &"",
				"can_place": not pod_placed,
				"can_relocate": pod_placed,
				"capital_cost_cents": 7_500,
				"relocation_cost_cents": 1_800,
				"daily_cost_cents": 500,
			},
			"construction_stages": [
				{"id": &"deed", "label": "PARCEL DEED", "status": &"complete", "detail": "North Meadow filed."},
				{"id": &"trench", "label": "UTILITY TRENCH", "status": &"active", "detail": "Power review open."},
				{"id": &"pad", "label": "POD PAD", "status": &"pending", "detail": "Socket selection held."},
				{"id": &"commission", "label": "COMMISSION", "status": &"pending", "detail": "Operational handoff."},
			],
			"summary": "Four filed stages; the meadow becomes operational after commissioning.",
			"operational_benefits": ["Adds six claim files of campus capacity.", "Cold-chain service protects six Farmgate eggs."],
		},
	}


func _flat_snapshot() -> Dictionary:
	return {
		"campus_expansion": {
			"parcel_id": &"north_meadow",
			"parcel_owned": true,
			"parcel_quote": _flat_quote(8_500, 300, false, "North Meadow is already owned."),
			"services": [
				{"id": &"circulation", "name": "MEADOW CIRCULATION LINK", "commissioned": true, "capital_cost_cents": 2_800, "daily_cost_cents": 150, "quote": _flat_quote(2_800, 150, false, "Already commissioned.")},
				{"id": &"power", "name": "MEADOW POWER DROP", "commissioned": true, "capital_cost_cents": 3_500, "daily_cost_cents": 225, "quote": _flat_quote(3_500, 225, false, "Already commissioned.")},
				{"id": &"cold_chain", "name": "MEADOW COLD-CHAIN LOOP", "commissioned": true, "capital_cost_cents": 6_000, "daily_cost_cents": 400, "quote": _flat_quote(6_000, 400, false, "Already commissioned.")},
			],
			"sockets": [
				{"id": &"meadow_west", "name": "SOCKET A / MEADOW WEST", "route_blocked": false, "occupied": true, "placement_quote": _flat_quote(7_500, 500, false, "Pod already placed."), "relocation_quote": _flat_quote(1_800, 0, false, "Pod already occupies this socket.")},
				{"id": &"meadow_east", "name": "SOCKET B / MEADOW EAST", "route_blocked": false, "occupied": false, "placement_quote": _flat_quote(7_500, 500, false, "Pod already placed."), "relocation_quote": _flat_quote(1_800, 0, true, "")},
				{"id": &"service_spine", "name": "SOCKET C / SERVICE SPINE", "route_blocked": true, "blocked_reason": "The Service Spine is reserved for the flock circulation route.", "occupied": false, "placement_quote": _flat_quote(7_500, 500, false, "The Service Spine is reserved for the flock circulation route."), "relocation_quote": _flat_quote(1_800, 0, false, "The Service Spine is reserved for the flock circulation route.")},
			],
			"module_id": &"egg_routing_pod",
			"pod_owned": true,
			"pod_socket_id": &"meadow_west",
			"pod_operational": true,
			"claim_capacity_bonus": 6,
			"farmgate_capacity_bonus_eggs": 6,
			"current_daily_cost_cents": 1_575,
		},
	}


func _flat_quote(cost: int, daily: int, can_authorize: bool, reason: String) -> Dictionary:
	return {
		"known": true,
		"name": "FILED CAMPUS ITEM",
		"can_authorize": can_authorize,
		"reason": reason,
		"cost_cents": cost,
		"added_daily_cost_cents": daily,
	}


func _contains_all(text_value: String, needles: Array[String]) -> bool:
	var lowered := text_value.to_lower()
	for needle: String in needles:
		if needle.to_lower() not in lowered:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
