extends SceneTree

const DEPOT: StringName = DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID
const PACKING: StringName = DepartmentSimulation.PACKING_ANNEX_ID
const GALLERY: StringName = DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID
const DEPOT_FOCUS := Vector3(23.05, 1.25, -3.00)

var _stage := "boot"


func _init() -> void:
	create_timer(45.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := _commissioning_fixture()
	var office := Office.new()
	office.set("_simulation", simulation)
	root.add_child(office)
	await process_frame
	await process_frame
	_stage = "checking composed capital surfaces"

	var blueprint := office.get("_capital_blueprint_ui") as CapitalBlueprintUI
	var reveal := office.get("_commissioning_reveal_ui") as CommissioningRevealUI
	var portfolio := office.get("_campus_portfolio_ui") as CampusPortfolioUI
	var expansion := office.get("_campus_expansion_ui") as CampusExpansionUI
	var portfolio_reveal := office.get("_campus_portfolio_reveal_ui") as CampusPortfolioRevealUI
	var staffing := office.find_child("RoostStaffingUI", true, false) as RoostStaffingUI
	var dispatch_ui := office.find_child("FarmgateDispatchUI", true, false) as FarmgateDispatchUI
	var flockwatch_navigation := office.find_child("FlockwatchNavigation", true, false) as FlockwatchNavigation
	var capital_scroll := (
		flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_CAPITAL)
		if flockwatch_navigation != null else null
	) as ScrollContainer
	var operations_scroll := (
		flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_OPERATIONS)
		if flockwatch_navigation != null else null
	) as ScrollContainer
	var camera := office.get("_camera_controller") as ManagementCameraController
	_check(
		blueprint != null
		and reveal != null
		and portfolio != null
		and expansion != null
		and portfolio_reveal != null
		and staffing != null
		and dispatch_ui != null
		and flockwatch_navigation != null
		and capital_scroll != null
		and operations_scroll != null
		and camera != null,
		"Office should compose every capital modal, both reveals, the embedded Farmgate file, and management camera",
		failures,
	)
	if (
		blueprint == null
		or reveal == null
		or portfolio == null
		or expansion == null
		or portfolio_reveal == null
		or staffing == null
		or dispatch_ui == null
		or flockwatch_navigation == null
		or capital_scroll == null
		or operations_scroll == null
		or camera == null
	):
		await _finish(office, failures)
		return

	# Exercise the real Flockwatch-to-Blueprint connection rather than invoking the
	# modal directly. Suppress only unrelated campaign/review overlays.
	office.call("_set_campaign_modal_open", false)
	var review_scrim := office.get("_day_review_scrim") as Control
	if review_scrim != null:
		review_scrim.visible = false
	office.call("_on_snapshot_changed", simulation.snapshot())
	office.call("_set_flockwatch_open", true)
	_check(
		flockwatch_navigation.open_page(FlockwatchNavigation.PAGE_CAPITAL),
		"the relevant Capital filing page should open through Flockwatch navigation",
		failures,
	)
	await process_frame
	await process_frame
	var open_blueprint := office.find_child("OpenCapitalBlueprint", true, false) as Button
	_check(
		open_blueprint != null
		and capital_scroll.is_ancestor_of(open_blueprint)
		and open_blueprint.is_visible_in_tree(),
		"the Capital page should expose one clear Blueprint entry point",
		failures,
	)
	if open_blueprint != null:
		open_blueprint.grab_focus()
		await process_frame
		open_blueprint.pressed.emit()
	await process_frame
	await process_frame

	_check(blueprint.is_open(), "the Flockwatch action should open the player-held Blueprint", failures)

	# A player-held capital surface must consume live-office shortcuts while
	# retaining the non-remappable F10 Settings safety route above it.
	var settings := office.find_child("PlayerSettings", true, false) as PeckingOrderSettingsUI
	var clock := office.get("_clock") as SimulationClock
	var ticker := office.get("_ticker_label") as Label
	var shortcut_fund_before := simulation.revenue_cents
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	simulation.pending_decision.clear()
	if clock != null:
		clock.set_speed(0)
	if ticker != null:
		ticker.text = "BLUEPRINT INPUT SENTINEL"
	for action: StringName in [
		&"fund_feed_party",
		&"toggle_overtime",
		&"toggle_flockwatch",
		&"speed_normal",
		&"peck_assist",
	]:
		await _send_action(action)
	_check(
		simulation.revenue_cents == shortcut_fund_before
		and not simulation.feed_party_used_today
		and not simulation.overtime_enabled
		and not bool(office.get("_flockwatch_open"))
		and (clock == null or clock.speed_index == 0)
		and (ticker == null or ticker.text == "BLUEPRINT INPUT SENTINEL"),
		"Blueprint should block Feed Party, overtime, Flockwatch, clock, and Peck Assist shortcuts from dispatching behind it",
		failures,
	)
	await _send_action(&"open_settings")
	_check(
		settings != null and settings.is_open() and blueprint.is_open(),
		"F10 Settings should open above Blueprint without dismissing the held capital filing",
		failures,
	)
	if settings != null:
		settings.hide_settings()
	await process_frame
	blueprint.hide_blueprint(false)
	for surface: Control in [portfolio, expansion, reveal, portfolio_reveal]:
		if ticker != null:
			ticker.text = "CAPITAL MODAL INPUT SENTINEL"
		surface.visible = true
		await _send_action(&"toggle_overtime")
		_check(
			not simulation.overtime_enabled
			and (ticker == null or ticker.text == "CAPITAL MODAL INPUT SENTINEL"),
			"%s should block live-office shortcuts from dispatching behind it" % surface.name,
			failures,
		)
		surface.visible = false
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office.call("_on_snapshot_changed", simulation.snapshot())
	blueprint.show_blueprint(simulation.snapshot())
	await process_frame

	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	blueprint._unhandled_key_input(cancel)
	await process_frame
	await process_frame
	_check(
		not blueprint.is_open()
		and bool(office.get("_flockwatch_open"))
		and open_blueprint != null
		and root.gui_get_focus_owner() == open_blueprint,
		"Blueprint-owned Escape should close the modal, restore Flockwatch, and return keyboard focus to its invoking action",
		failures,
	)
	if open_blueprint != null:
		open_blueprint.pressed.emit()
	await process_frame
	await process_frame
	_check(blueprint.is_open(), "the restored Flockwatch action should reopen Blueprint after semantic Return", failures)
	_check(
		blueprint.active_filter_id() == &"ready"
		and DEPOT in blueprint.visible_facility_ids(),
		"Blueprint should open on actionable Ready plans and keep the funded Depot visible",
		failures,
	)
	_check(
		office.find_children("CapitalBlueprintParcel_*", "Button", true, false).size() == 13,
		"Office should retain one stable Blueprint control for every authoritative facility",
		failures,
	)
	_check(
		blueprint.set_filter(&"all")
		and blueprint.visible_facility_ids().size() == 13
		and DEPOT in blueprint.visible_facility_ids(),
		"All Plans should expose the complete thirteen-facility catalog on request",
		failures,
	)
	_check(blueprint.select_facility(DEPOT), "Farmgate Depot should be selectable by its stable capital id", failures)
	await process_frame
	var purchase := office.find_child("CapitalBlueprintPurchaseButton", true, false) as Button
	_check(purchase != null and not purchase.disabled, "the exact funded Day 6 fixture should enable the Roadside Loading Shed", failures)
	_check(
		blueprint.inspector_accessible_text().contains("$120.00")
		and blueprint.inspector_accessible_text().contains("12 / 24 / 42")
		and purchase != null and "$120.00" in purchase.text,
		"the selected parcel should disclose the exact tier-one cost and cumulative storage benefit",
		failures,
	)

	var fund_before := simulation.revenue_cents
	_stage = "commissioning Farmgate from Blueprint"
	if purchase != null:
		purchase.pressed.emit()
	await process_frame
	await process_frame

	var receipt := reveal.receipt_snapshot()
	_check(simulation.facility_level(DEPOT) == 1, "Blueprint purchase intent should reach the authoritative facility transaction", failures)
	_check(simulation.revenue_cents == fund_before - 12_000, "commissioning should debit the exact $120 capital once", failures)
	_check(not blueprint.is_open() and reveal.is_reveal_visible(), "an accepted purchase should replace the Blueprint with a player-held commissioning receipt", failures)
	_check(
		StringName(receipt.get("facility_id", &"")) == DEPOT
		and int(receipt.get("purchased_level", 0)) == 1
		and int(receipt.get("cost_cents", 0)) == 12_000
		and String(receipt.get("level_name", "")) == "ROADSIDE LOADING SHED",
		"the reveal should retain the exact authoritative Farmgate receipt",
		failures,
	)
	_check(
		camera.current_focus_label == "FARMGATE DISPATCH DEPOT"
		and camera.focus_world_position().is_equal_approx(DEPOT_FOCUS),
		"commissioning should hold the camera on the physical Depot parcel",
		failures,
	)

	var continue_button := office.find_child("CommissioningContinue", true, false) as Button
	_check(continue_button != null and continue_button.focus_mode == Control.FOCUS_ALL, "the receipt should remain dismissible by keyboard", failures)
	if continue_button != null:
		continue_button.pressed.emit()
	await process_frame
	_check(not reveal.is_reveal_visible(), "Continue should release the commissioning reveal", failures)

	# File a real route through the embedded compact UI. This proves the two signal
	# forwarding hops (Farmgate UI -> Staffing -> Office) reach the simulation once.
	_stage = "filing Farmgate mandate through Flockwatch"
	office.call("_on_snapshot_changed", simulation.snapshot())
	office.call("_set_flockwatch_open", true)
	_check(
		flockwatch_navigation.open_page(FlockwatchNavigation.PAGE_OPERATIONS),
		"the commissioned Depot should keep its Operations filing page reachable",
		failures,
	)
	await process_frame
	await process_frame
	_check(
		dispatch_ui.visible
		and operations_scroll.is_ancestor_of(dispatch_ui)
		and dispatch_ui.is_visible_in_tree(),
		"commissioning should reveal the embedded dispatch file on Operations",
		failures,
	)
	_check(dispatch_ui.select_mandate(&"farmer_pickup"), "the safe default route should be selectable", failures)
	var authorize := office.find_child("FarmgateDispatchAuthorize", true, false) as Button
	_check(authorize != null and not authorize.disabled, "the review-time farmer pickup should be actionable", failures)
	if authorize != null:
		authorize.pressed.emit()
	await process_frame
	await process_frame
	var dispatch := simulation.farmgate_dispatch_snapshot()
	_check(
		StringName(dispatch.get("active_mandate_id", &"")) == &"farmer_pickup"
		and int((dispatch.get("last_authorization_receipt", {}) as Dictionary).get("target_day", 0)) == 6,
		"the embedded action should file one authoritative Day 6 pickup mandate",
		failures,
	)
	_check(
		camera.current_focus_label == "FARMGATE ROUTE FILED"
		and camera.focus_world_position().is_equal_approx(DEPOT_FOCUS),
		"an accepted mandate should focus the exact Depot route desk",
		failures,
	)

	# Seed the same immutable lot the simulation creates before Office receives the
	# egg presentation callback. Good stock must never masquerade as immediate fund
	# cash; cracked work still enters the Feed Fund at its exact earned value.
	_stage = "verifying deferred and immediate presentation semantics"
	var stored := simulation._farmgate_dispatch.store_lot(
		9_101, 6, 0, "Mabel", &"sound", 800, 1, 2, 12
	)
	_check(bool(stored.get("stored", false)), "the good-egg presentation fixture should enter cold storage", failures)
	office.call("_on_snapshot_changed", simulation.snapshot())
	_check(
		int(office.call("_immediate_cash_for_completed_egg", 9_101, &"sound", 800)) == 0,
		"a commissioned stored sound egg should expose zero immediate presentation cash",
		failures,
	)
	_check(
		int(office.call("_immediate_cash_for_completed_egg", 9_102, &"cracked", 800)) == 800,
		"a cracked egg should retain its full immediate Feed Fund value even with the Depot commissioned",
		failures,
	)

	_queue_presentation(office, 0, 9_101, 0, true)
	office.call("_on_egg_reached_presentation", 0, &"sound", 800, 0)
	await process_frame
	var stock_chips := office.find_children("FarmgateStockChip", "PanelContainer", true, false)
	var fund_chips := office.find_children("FundCreditChip", "PanelContainer", true, false)
	_check(stock_chips.size() == 1 and fund_chips.is_empty(), "stored sound work should animate as one cold-store lot and no Feed Fund credit", failures)
	_check(
		String(office.get("_ticker_label").text).contains("SOUND STOCKED"),
		"the visible delivery copy should name stock, not cash",
		failures,
	)
	for chip in stock_chips:
		(chip as Node).free()
	await process_frame

	var base_fund := simulation.revenue_cents
	var cracked_value := 800
	simulation.revenue_cents += cracked_value
	office.set("_pending_collection_cents", cracked_value)
	office.call("_on_snapshot_changed", simulation.snapshot())
	_queue_presentation(office, 0, 9_102, cracked_value, false)
	office.call("_on_egg_reached_presentation", 0, &"cracked", cracked_value, 0)
	await process_frame
	stock_chips = office.find_children("FarmgateStockChip", "PanelContainer", true, false)
	fund_chips = office.find_children("FundCreditChip", "PanelContainer", true, false)
	var fund_copy := ""
	if fund_chips.size() == 1:
		var label := (fund_chips[0] as Node).find_child("*", true, false) as Label
		fund_copy = label.text if label != null else ""
	_check(fund_chips.size() == 1 and stock_chips.is_empty(), "cracked work should animate as one immediate Feed Fund credit and no cold-store lot", failures)
	_check("+$8.00 FEED FUND" in fund_copy, "the cracked credit chip should disclose its exact immediate value", failures)
	_check(
		int(office.get("_pending_collection_cents")) == 0
		and int(office.get("_fund_visual_target_cents")) == base_fund + cracked_value,
		"cracked presentation should release the held cash into the authoritative Feed Fund target",
		failures,
	)

	await _finish(office, failures)


func _commissioning_fixture() -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(21_511, 4)
	simulation.day = 6
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 1_000_000
	simulation.owned_facilities[PACKING] = 1
	simulation.owned_facilities[GALLERY] = 1
	simulation._harvest_credit.public_standing = 5
	simulation._farmgate_dispatch.begin_day(6)
	return simulation


func _queue_presentation(
	office: Office,
	worker_id: int,
	claim_id: int,
	cash_cents: int,
	stocked: bool,
) -> void:
	office.call("_queue_collection_claim", worker_id, claim_id)
	var cash_by_claim := office.get("_collection_cash_by_claim_id") as Dictionary
	var stocked_by_claim := office.get("_collection_stocked_by_claim_id") as Dictionary
	var in_flight := office.get("_eggs_in_flight_by_worker") as Dictionary
	cash_by_claim[claim_id] = cash_cents
	stocked_by_claim[claim_id] = stocked
	in_flight[worker_id] = int(in_flight.get(worker_id, 0)) + 1
	office.set("_collection_cash_by_claim_id", cash_by_claim)
	office.set("_collection_stocked_by_claim_id", stocked_by_claim)
	office.set("_eggs_in_flight_by_worker", in_flight)


func _send_action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _finish(office: Node, failures: Array[String]) -> void:
	_stage = "cleanup"
	if office != null and is_instance_valid(office):
		office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FARMGATE_CAPITAL_OFFICE_FLOW_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARMGATE_CAPITAL_OFFICE_FLOW_TEST_PASSED blueprint=13 commissioning=receipt mandate=forwarded good-egg=stocked cracked=immediate")
	quit(0)


func _on_watchdog_timeout() -> void:
	push_error("FARMGATE_CAPITAL_OFFICE_FLOW_TEST_TIMEOUT: %s" % _stage)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
