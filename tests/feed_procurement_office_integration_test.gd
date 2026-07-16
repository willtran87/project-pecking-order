extends SceneTree


const PROVISIONS := DepartmentSimulation.FEED_PROCUREMENT_COOP_ID
const LOCAL_ORDER: StringName = &"local_whole_grain"
const EXPECTED_ORDER_SCOOPS := 7
const EXPECTED_ORDER_COST_CENTS := 1750
const EXPECTED_FOCUS := Vector3(7.30, 1.50, 30.00)

var _stage := "boot"


func _init() -> void:
	create_timer(35.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(18_041, 4)
	simulation.day = 4
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.owned_facilities[PROVISIONS] = 1
	simulation.revenue_cents = 1_000_000

	var office := Office.new()
	office.set("_simulation", simulation)
	root.add_child(office)
	await process_frame
	await process_frame
	_stage = "composing production surfaces"

	var staffing := office.find_child("RoostStaffingUI", true, false) as RoostStaffingUI
	var flockwatch := office.find_child("FlockwatchLedger", true, false) as PanelContainer
	var procurement_ui := office.find_child("FeedProcurementUI", true, false) as FeedProcurementUI
	var procurement_visual := office.find_child("FeedProcurementCoopVisual", true, false) as FeedProcurementCoopVisual
	var flockwatch_navigation := office.find_child("FlockwatchNavigation", true, false) as FlockwatchNavigation
	var operations_scroll := (
		flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_OPERATIONS)
		if flockwatch_navigation != null else null
	) as ScrollContainer
	var today_scroll := (
		flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_TODAY)
		if flockwatch_navigation != null else null
	) as ScrollContainer
	var camera := office.get("_camera_controller") as ManagementCameraController
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var decision_host := office.get("_decision_host") as Control
	var review_scrim := office.get("_day_review_scrim") as Control
	_check(
		staffing != null
		and flockwatch != null
		and procurement_ui != null
		and procurement_visual != null
		and flockwatch_navigation != null
		and operations_scroll != null
		and today_scroll != null
		and camera != null,
		"production Office should compose Flockwatch, its procurement controls, the physical provisions room, and the management camera",
		failures,
	)
	if (
		staffing == null
		or flockwatch == null
		or procurement_ui == null
		or procurement_visual == null
		or flockwatch_navigation == null
		or operations_scroll == null
		or today_scroll == null
		or camera == null
	):
		await _finish(office, failures)
		return

	# Use the real review ledger while suppressing unrelated campaign/review scrims.
	office.call("_set_campaign_modal_open", false)
	if review_scrim != null:
		review_scrim.visible = false
	office.call("_on_snapshot_changed", simulation.snapshot())
	office.call("_set_flockwatch_open", true)
	_check(
		flockwatch_navigation.open_page(FlockwatchNavigation.PAGE_OPERATIONS),
		"the commissioned provisions room should make Operations reachable",
		failures,
	)
	await process_frame
	await process_frame

	_check(
		flockwatch.visible
		and flockwatch_navigation.current_page_id() == FlockwatchNavigation.PAGE_OPERATIONS,
		"Flockwatch should expose the real Operations review filing",
		failures,
	)
	_check(
		procurement_ui.visible
		and operations_scroll.is_ancestor_of(procurement_ui)
		and not today_scroll.is_ancestor_of(procurement_ui)
		and procurement_ui.is_visible_in_tree(),
		"Flock Provisions should remain inline on Operations rather than the legacy Today scroll",
		failures,
	)
	_check(office.find_children("FeedProcurementOffer_*", "PanelContainer", true, false).size() == 3, "Flockwatch should build exactly the three authored procurement offer cards", failures)
	_check(procurement_visual.current_level() == 1 and procurement_visual.stock_scoops() == 0, "the commissioned receiving room should begin with the authoritative empty ledger", failures)
	_check(procurement_visual.visible_stock_sack_count() == 0, "an empty authoritative ledger should not invent physical sacks", failures)
	_check(Office.FLOCK_PROVISIONS_COOP_FOCUS.is_equal_approx(EXPECTED_FOCUS), "Office should retain the exact audited provisions focus constant", failures)
	_check(FeedProcurementCoopVisual.facility_focus_point().is_equal_approx(EXPECTED_FOCUS), "the room should publish the same exact focus constant", failures)
	_check(procurement_visual.focus_point_global().is_equal_approx(EXPECTED_FOCUS), "the built room should resolve the exact focus in world space", failures)

	var local_button := office.find_child("FeedProcurementOrder_local_whole_grain", true, false) as Button
	var inventory_label := office.find_child("FeedProcurementInventory", true, false) as Label
	var offer := _offer(simulation.feed_procurement_snapshot(), LOCAL_ORDER)
	_check(local_button != null and not local_button.disabled, "the exact funded review fixture should enable Local Whole Grain", failures)
	_check(int(offer.get("quantity_scoops", -1)) == EXPECTED_ORDER_SCOOPS, "four active hens should author the exact seven-scoop local order", failures)
	_check(int(offer.get("total_cost_cents", -1)) == EXPECTED_ORDER_COST_CENTS, "the neutral charter should author the exact $17.50 local order", failures)
	_check(local_button != null and local_button.shortcut == null, "procurement should add no dedicated button hotkey", failures)
	_check(not _has_procurement_input_action(), "procurement should add no global InputMap action", failures)
	_check(_feed_named_modal_count(office) == 0, "procurement should add no feed-named modal surface", failures)

	var forwarded: Array[StringName] = []
	staffing.feed_order_requested.connect(func(order_id: StringName) -> void: forwarded.append(order_id))
	var simulation_snapshots := [0]
	simulation.snapshot_changed.connect(func(_snapshot: Dictionary) -> void: simulation_snapshots[0] += 1)
	var input_actions_before := InputMap.get_actions().duplicate()
	var modal_node_count_before := _modal_node_count(office)
	var fund_before := simulation.revenue_cents
	_stage = "authorizing inline order"
	if local_button != null:
		local_button.pressed.emit()
	await process_frame
	await process_frame

	var procurement := simulation.feed_procurement_snapshot()
	var last_order := procurement.get("last_order", {}) as Dictionary
	_check(forwarded == [LOCAL_ORDER], "the embedded button should forward the stable offer id through RoostStaffingUI exactly once", failures)
	_check(int(simulation_snapshots[0]) >= 1, "authoritative authorize_feed_order should publish its accepted snapshot", failures)
	_check(bool(last_order.get("accepted", false)) and StringName(last_order.get("action_id", &"")) == &"authorize_feed_order", "forwarded intent should reach the authoritative authorize_feed_order transaction", failures)
	_check(StringName(last_order.get("offer_id", &"")) == LOCAL_ORDER, "the permanent receipt should retain the exact forwarded offer id", failures)
	_check(simulation.revenue_cents == fund_before - EXPECTED_ORDER_COST_CENTS, "the accepted order should debit the exact $17.50 once", failures)
	_check(int(procurement.get("procurement_spend_today_cents", -1)) == EXPECTED_ORDER_COST_CENTS, "the procurement ledger should record the exact debit once", failures)
	_check(int(procurement.get("stock_scoops", -1)) == EXPECTED_ORDER_SCOOPS, "the authoritative snapshot should receive exactly seven scoops", failures)
	_check((procurement.get("lots", []) as Array).size() == 1, "the accepted transaction should create exactly one authoritative lot", failures)

	_check(procurement_visual.stock_scoops() == EXPECTED_ORDER_SCOOPS, "the physical provisions room should refresh to the same seven-scoop stock", failures)
	_check(procurement_visual.visible_stock_sack_count() == 1 and procurement_visual.lot_ids() == [1], "the physical room should materialize exactly the canonical lot", failures)
	_check(is_equal_approx(procurement_visual.stock_fill_ratio(), 7.0 / 18.0), "physical hopper fill should mirror canonical stock and capacity", failures)
	_check(inventory_label != null and "STOCK 7 / 18 SCOOPS" in inventory_label.text, "the inline Flockwatch inventory should refresh with the same stock", failures)
	_check(camera.current_focus_label == "PROVISIONS DELIVERY FILED", "the accepted order should request the authored delivery camera shot", failures)
	_check(camera.focus_world_position().is_equal_approx(EXPECTED_FOCUS), "the delivery camera should target the exact physical room focus", failures)

	# Static event focus intentionally clears the side ledger so the physical room
	# is visible; the same inline surface must remain available without a modal.
	_check(
		not flockwatch.visible and operations_scroll.is_ancestor_of(procurement_ui),
		"delivery focus should only collapse the existing inline Operations ledger",
		failures,
	)
	_check(campaign_ui == null or not campaign_ui.is_modal_open(), "authorization should not open a campaign modal", failures)
	_check(decision_host == null or not decision_host.visible, "authorization should not open the management decision modal", failures)
	_check(review_scrim == null or not review_scrim.visible, "authorization should not create or reopen a review scrim", failures)
	_check(_modal_node_count(office) == modal_node_count_before, "authorization should not add a modal node", failures)
	_check(InputMap.get_actions() == input_actions_before and not _has_procurement_input_action(), "authorization should not register a hotkey", failures)
	office.call("_set_flockwatch_open", true)
	_check(
		flockwatch_navigation.open_page(FlockwatchNavigation.PAGE_OPERATIONS),
		"the same Operations filing should reopen through public navigation",
		failures,
	)
	await process_frame
	_check(flockwatch.visible and procurement_ui.is_visible_in_tree(), "the same Flockwatch procurement surface should reopen without a modal", failures)

	# Even direct emission from the now-disabled button must remain idempotent: the
	# inline component rechecks the canonical order limit before forwarding intent.
	var state_after_order := JSON.stringify(simulation.export_save_state())
	var snapshots_after_order := int(simulation_snapshots[0])
	local_button = office.find_child("FeedProcurementOrder_local_whole_grain", true, false) as Button
	_check(local_button != null and local_button.disabled, "the refreshed offer should visibly retire today's one order", failures)
	if local_button != null:
		local_button.pressed.emit()
	await process_frame
	_check(forwarded == [LOCAL_ORDER] and int(simulation_snapshots[0]) == snapshots_after_order, "repeat UI input should not forward or transact a second time", failures)
	_check(JSON.stringify(simulation.export_save_state()) == state_after_order, "repeat UI input should preserve the complete authoritative checkpoint", failures)

	camera.show_overview()
	await _finish(office, failures)


func _offer(procurement: Dictionary, offer_id: StringName) -> Dictionary:
	for value in procurement.get("offers", []) as Array:
		if value is Dictionary:
			var offer := value as Dictionary
			if StringName(offer.get("offer_id", &"")) == offer_id:
				return offer
	return {}


func _has_procurement_input_action() -> bool:
	for action in InputMap.get_actions():
		var normalized := String(action).to_lower()
		if "procurement" in normalized or "provisions" in normalized:
			return true
	return false


func _feed_named_modal_count(office: Node) -> int:
	var count := 0
	for candidate in office.find_children("*", "", true, false):
		var normalized := String(candidate.name).to_lower()
		if ("feed" in normalized or "provision" in normalized) and ("modal" in normalized or "scrim" in normalized):
			count += 1
	return count


func _modal_node_count(office: Node) -> int:
	var count := 0
	for candidate in office.find_children("*", "", true, false):
		var normalized := String(candidate.name).to_lower()
		if "modal" in normalized or "scrim" in normalized:
			count += 1
	return count


func _finish(office: Node, failures: Array[String]) -> void:
	_stage = "cleanup"
	if office != null and is_instance_valid(office):
		office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FEED_PROCUREMENT_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FEED_PROCUREMENT_OFFICE_INTEGRATION_TEST_PASSED surface=flockwatch intent=authorize_feed_order debit=$17.50-once stock=snapshot+room camera=exact-focus modal=none hotkey=none")
	quit(0)


func _on_watchdog_timeout() -> void:
	push_error("FEED_PROCUREMENT_OFFICE_INTEGRATION_TEST_TIMEOUT: %s" % _stage)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
