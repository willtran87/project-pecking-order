extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(390, 844)
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	office.call("_prepare_capture_running")
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	var reserve := simulation.current_daily_operating_cost_cents() + simulation.wage_arrears_cents
	simulation.revenue_cents = reserve + 2000
	simulation.eggs_today = 1
	simulation.eggs_total = 1
	simulation.workers[0].eggs_laid = 1
	var first_clutch := office.call("_make_first_clutch_state", false) as Dictionary
	first_clutch.merge({
		"completed": true,
		"target_worker_id": 0,
		"inspected": true,
		"specialty_routed": true,
		"checkin_filed": true,
		"checkin_worker_id": 0,
		"assisted_worker_id": 0,
		"assisted_claim_id": 401,
		"delivery_laid": true,
		"delivery_seen": true,
		"delivered_claim_id": 401,
		"delivered_quality": "sound",
		"delivered_value_cents": 425,
	}, true)
	office.set("_first_clutch", first_clutch)
	clock.set_speed(3)
	var offer := simulation.begin_first_clutch_reinvestment(0, 401, &"sound", 425)
	_check(bool(offer.get("accepted", false)), "authoritative purchase fixture should stage one offer", failures)
	_check(office.call("_present_first_clutch_reinvestment", offer), "Office should present the staged offer", failures)
	await process_frame
	await process_frame

	var decision_host := office.find_child("ManagementDecisionHost", true, false) as Control
	var decision_card := office.find_child("ManagementDecisionCard", true, false) as Control
	var decision_scroll := office.find_child("DecisionScroll", true, false) as ScrollContainer
	var title := office.get("_decision_title") as Label
	var body := office.get("_decision_body") as Label
	var confirm := office.find_child("ConfirmDecisionButton", true, false) as Button
	var option_buttons := office.get("_decision_option_buttons") as Array
	var guidance := office.get("_guidance_label") as Label
	_check(
		decision_host != null
		and decision_host.visible
		and title != null
		and "REWARD MABEL" in title.text
		and "BANK THE FUND" in title.text,
		"reinvestment should reuse the blocking management card with the authored title",
		failures,
	)
	_check(
		body != null
		and "$20.00 SPENDABLE" in body.text
		and "DESK MATCH" in body.text
		and "$%.2f RESERVED" % (float(reserve) / 100.0) in body.text
		and "$4.25" in String(body.get_meta("accessible_text", "")),
		"body should expose created value, protected reserve, and spendable balance exactly",
		failures,
	)
	var initial_next_action := office.call("_next_action_diagnostic_state") as Dictionary
	var initial_summary := String(office.call("_web_accessibility_summary", simulation.snapshot()))
	var initial_announcement := office.call(
		"_web_accessibility_announcement",
		simulation.snapshot(),
		initial_summary,
	) as Dictionary
	var initial_coach := office.call(
		"_first_clutch_coach_snapshot",
		simulation.snapshot(),
	) as Dictionary
	_check(
		guidance != null
		and guidance.text == "FIRST EGG: REWARD MABEL OR BANK"
		and String(initial_next_action.get("copy", "")) == guidance.text
		and String(initial_next_action.get("action_id", "")) == "decision"
		and "Choose where Mabel's first egg goes" in String(initial_next_action.get("accessible_text", ""))
		and "INCIDENT" not in String(initial_next_action.get("copy", "")),
		"the global next action should name the visible first-egg decision instead of misclassifying it as an incident",
		failures,
	)
	_check(
		String(initial_coach.get("guidance", ""))
		== "Choose where Mabel's first egg goes, then authorize; today's three orders will open.",
		"First Clutch guidance should retain the required choose-then-authorize sequence",
		failures,
	)
	_check(
		"Objective: choose where the first egg goes" in initial_summary
		and "choose a response" not in initial_summary
		and String(initial_announcement.get("kind", "")) == "management_decision"
		and "Objective: choose where the first egg goes" in String(initial_announcement.get("text", ""))
		and "review the response" not in String(initial_announcement.get("text", "")),
		"first-egg summary and live narration should use the authored reinvestment objective",
		failures,
	)
	_check(option_buttons.size() == 3, "offer should contain two requisitions plus Bank", failures)
	var initial_diagnostic := office.call("_pending_decision_diagnostic_state") as Dictionary
	_check(
		String(initial_diagnostic.get("prompt", "")) == "CHOOSE WHERE THE FIRST EGG GOES"
		and String(initial_diagnostic.get("confirm_label", "")) == "PICK AN OPTION",
		"diagnostic state should mirror the visible reinvestment prompt and default action",
		failures,
	)
	for button_value in option_buttons:
		var button := button_value as Button
		_check(
			button != null
			and button.custom_minimum_size.y >= 72.0
			and button.size.y >= 72.0,
			"every reinvestment card should retain a rendered 72px target",
			failures,
		)
	_check(confirm != null and is_equal_approx(confirm.custom_minimum_size.y, 66.0), "reinvestment Confirm should use a 66px target", failures)

	var card_rect := decision_card.get_global_rect() if decision_card != null else Rect2()
	var viewport_rect := root.get_visible_rect()
	_check(
		decision_scroll != null
		and decision_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO
		and card_rect.position.x >= -0.5
		and card_rect.end.x <= viewport_rect.end.x + 0.5
		and card_rect.size.x <= viewport_rect.size.x - 36.0 + 0.5,
		"390x844 layout should keep the card horizontally contained inside its scroll host",
		failures,
	)

	var offered_options := offer.get("offered_options", []) as Array
	var first_option := offered_options[0] as Dictionary
	var upgrade_id := StringName(first_option.get("id", &""))
	var level_before := simulation.upgrade_level(upgrade_id)
	var fund_before := simulation.revenue_cents
	var net_cost := int(first_option.get("net_cost_cents", 0))
	var match_cents := int(first_option.get("procurement_match_cents", 0))
	_check(bool(first_option.get("can_purchase", false)), "purchase fixture should make the first visible requisition affordable", failures)

	var key_one := InputEventKey.new()
	key_one.pressed = true
	key_one.keycode = KEY_1
	Input.parse_input_event(key_one)
	await process_frame
	_check(
		StringName(office.get("_selected_decision_option")) == upgrade_id
		and confirm != null
		and not confirm.disabled
		and root.gui_get_focus_owner() == confirm,
		"1 should select the first card and hand Enter focus to Confirm",
		failures,
	)
	var selected_diagnostic := office.call("_pending_decision_diagnostic_state") as Dictionary
	var selected_next_action := office.call("_next_action_diagnostic_state") as Dictionary
	_check(
		String(selected_diagnostic.get("prompt", "")).begins_with("SELECTED")
		and "INSTALL" in String(selected_diagnostic.get("confirm_label", "")),
		"diagnostic state should mirror the selected card preview and exact authorization action",
		failures,
	)
	_check(
		guidance != null
		and guidance.text == "FIRST EGG: %s" % String(selected_diagnostic.get("confirm_label", ""))
		and String(selected_next_action.get("copy", "")) == guidance.text
		and (
			"Press Enter to %s" % String(selected_diagnostic.get("confirm_label", ""))
			in String(selected_next_action.get("accessible_text", ""))
		),
		"selecting a first-egg option should advance the global action to the exact visible authorization",
		failures,
	)
	var enter := InputEventKey.new()
	enter.pressed = true
	enter.keycode = KEY_ENTER
	Input.parse_input_event(enter)
	await process_frame
	await process_frame

	var status := simulation.first_clutch_reinvestment_status()
	_check(
		StringName(status.get("status", &"")) == &"purchased"
		and simulation.upgrade_level(upgrade_id) == level_before + 1
		and simulation.revenue_cents == fund_before - net_cost
		and int(status.get("procurement_match_used_cents", -1)) == match_cents,
		"Enter should buy exactly one level using only the recorded net debit",
		failures,
	)
	_check(
		clock.speed_index == 3
		and not decision_host.visible
		and bool(office.first_clutch_snapshot().get("orders_handoff_pending", false)),
		"purchase should restore prior 3x speed and release the orders handoff",
		failures,
	)
	var flockwatch_toggle := office.find_child("FlockwatchToggle", true, false) as Button
	var flockwatch_hint := OfficeActionCatalog.binding_label(&"toggle_flockwatch")
	_check(
		flockwatch_toggle != null
		and flockwatch_toggle.text == "3 ORDERS  [%s]" % flockwatch_hint.split(" / ", false)[0]
		and String(flockwatch_toggle.get_meta("full_text", "")) == "TODAY'S 3 ORDERS  [%s]" % flockwatch_hint
		and String(flockwatch_toggle.get_meta("accessible_text", "")).contains("TODAY'S 3 ORDERS")
		and guidance != null
		and guidance.text == "ORDERS READY  >  OPEN  [%s]" % flockwatch_hint,
		"closing the reward card should expose a compact orders action with full assistive meaning and matching guidance",
		failures,
	)
	var handoff_coach := office.call("_first_clutch_coach_snapshot", simulation.snapshot()) as Dictionary
	_check(
		String(handoff_coach.get("visual_title", "")) == "OPEN TODAY'S ORDERS  [%s]" % flockwatch_hint
		and String(handoff_coach.get("visual_body", "")) == "FIRST EGG FILED  >  3 LIVE GOALS"
		and String(handoff_coach.get("title", "")).begins_with("FIRST CLUTCH FILED"),
		"orders handoff should pair one concise visual action with the complete filed receipt",
		failures,
	)
	flockwatch_toggle.pressed.emit()
	await process_frame
	await process_frame
	await process_frame
	var order_glances := office.get("_campaign_order_glances") as Array
	var first_order := order_glances[0] as Label if not order_glances.is_empty() else null
	var first_order_tile := office.call("_flockwatch_glance_tile", first_order) as PanelContainer if first_order != null else null
	var focus_owner := root.gui_get_focus_owner()
	var order_driver := office.find_child("CampaignOrderDriverAction", true, false) as Button
	var orders_heading := office.find_child("CampaignOrdersHeading", true, false) as Label
	var order_handoff_diagnostic := {
		"open": bool(office.get("_flockwatch_open")),
		"focus": String(focus_owner.name) if focus_owner != null else "",
		"handoff_source": bool(first_order.get_meta("opened_from_orders_handoff", false)) if first_order != null else false,
		"spotlight": bool(first_order_tile.get_meta("direct_focus", false)) if first_order_tile != null else false,
		"cursor": first_order.mouse_default_cursor_shape if first_order != null else -1,
		"driver_visible": order_driver != null and order_driver.is_visible_in_tree(),
		"driver_action": String(order_driver.get_meta("driver_action_id", "")) if order_driver != null else "",
		"heading": orders_heading.text if orders_heading != null else "",
	}
	_check(
		bool(office.get("_flockwatch_open"))
		and first_order != null
		and order_driver != null
		and bool(first_order.get_meta("opened_from_orders_handoff", false))
		and first_order_tile != null
		and bool(first_order_tile.get_meta("direct_focus", false))
		and first_order.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND
		and order_driver.is_visible_in_tree()
		and String(order_driver.get_meta("driver_action_id", "")) != ""
		and guidance.text == "ORDER PICKED  >  SHOW HEN ROUTES"
		and orders_heading != null
		and orders_heading.text == "3 ACTIVE GOALS  ·  +9 SCORE"
		and "All 3 goals are active" in String(orders_heading.get_meta("accessible_text", "")),
		"opening the released orders should select the first actionable card and expose its live driver: %s" % JSON.stringify(order_handoff_diagnostic),
		failures,
	)
	var feedback := office.get("_workstation_feedback") as WorkstationFeedback
	var worker_snapshot := _worker_snapshot(simulation, 0)
	var desk_index := int(worker_snapshot.get("desk_index", -1))
	var prop_root := feedback.upgrade_prop_root(desk_index, upgrade_id) if feedback != null else null
	var camera := office.get("_camera_controller") as ManagementCameraController
	_check(
		prop_root != null
		and prop_root.visible
		and camera != null
		and camera.current_focus_label == "FIRST CLUTCH REINVESTMENT",
		"purchase should reveal the real workstation prop and directly focus its install",
		failures,
	)
	var replay_fund := simulation.revenue_cents
	var replay_level := simulation.upgrade_level(upgrade_id)
	var replay := simulation.resolve_first_clutch_reinvestment(upgrade_id)
	_check(
		not bool(replay.get("accepted", true))
		and bool(replay.get("idempotent", false))
		and simulation.revenue_cents == replay_fund
		and simulation.upgrade_level(upgrade_id) == replay_level,
		"purchase replay should reject without a second debit or level",
		failures,
	)

	var legacy_completed := first_clutch.duplicate(true)
	legacy_completed["version"] = 1
	legacy_completed.erase("delivered_claim_id")
	legacy_completed.erase("reinvestment_grandfathered")
	var migrated_completed := office.call("_normalize_first_clutch_state", legacy_completed, false) as Dictionary
	var legacy_unfinished := legacy_completed.duplicate(true)
	legacy_unfinished["completed"] = false
	legacy_unfinished["delivery_laid"] = false
	legacy_unfinished["delivery_seen"] = false
	var migrated_unfinished := office.call("_normalize_first_clutch_state", legacy_unfinished, false) as Dictionary
	_check(
		int(migrated_completed.get("version", -1)) == 2
		and bool(migrated_completed.get("reinvestment_grandfathered", false))
		and not bool(migrated_unfinished.get("reinvestment_grandfathered", true)),
		"v1 completed inductions should be grandfathered while unfinished v1 files remain eligible",
		failures,
	)

	clock.set_speed(0)
	office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FIRST_CLUTCH_REINVESTMENT_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FIRST_CLUTCH_REINVESTMENT_UI_TEST_PASSED modal=blocking options=2+bank keyboard=1-enter purchase=exact-once install=focused speed=restored mobile=contained migration=v1-grandfathered")
	quit(0)


func _worker_snapshot(simulation: DepartmentSimulation, worker_id: int) -> Dictionary:
	for worker_value in simulation.snapshot().get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return worker
	return {}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
