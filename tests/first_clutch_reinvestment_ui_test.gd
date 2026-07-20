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
	_check(
		decision_host != null
		and decision_host.visible
		and title != null
		and "WHAT SHOULD MABEL" in title.text
		and "FIRST EGG BUILD" in title.text,
		"reinvestment should reuse the blocking management card with the authored title",
		failures,
	)
	_check(
		body != null
		and "$4.25" in body.text
		and "$%.2f" % (float(reserve) / 100.0) in body.text
		and "$20.00" in body.text,
		"body should expose created value, protected reserve, and spendable balance exactly",
		failures,
	)
	_check(option_buttons.size() == 3, "offer should contain two requisitions plus Bank", failures)
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
