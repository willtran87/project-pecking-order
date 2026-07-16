extends SceneTree

const FarmgateDispatchUIScript := preload("res://features/office/farmgate_dispatch_ui.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := _dispatch_fixture()
	var harness := Control.new()
	harness.name = "FarmgateDispatchUIContractHarness"
	harness.size = Vector2(282.0, 760.0)
	root.add_child(harness)

	var ui := FarmgateDispatchUIScript.new() as FarmgateDispatchUI
	ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	harness.add_child(ui)
	await process_frame

	var requested: Array[StringName] = []
	ui.mandate_requested.connect(
		func(mandate_id: StringName) -> void: requested.append(mandate_id)
	)
	ui.apply_snapshot(simulation.snapshot())
	await process_frame
	await process_frame

	var season := ui.find_child("FarmgateDispatchSeason", true, false) as Label
	var stock := ui.find_child("FarmgateDispatchStock", true, false) as Label
	var selector := ui.find_child("FarmgateDispatchMandateSelector", true, false) as OptionButton
	var terms := ui.find_child("FarmgateDispatchMandateTerms", true, false) as Label
	var reason := ui.find_child("FarmgateDispatchMandateReason", true, false) as Label
	var authorize := ui.find_child("FarmgateDispatchAuthorize", true, false) as Button
	_check(ui.visible, "a commissioned authoritative projection should reveal Farmgate Dispatch", failures)
	_check(
		season != null and _contains_all(season.text, ["spring hatch surge", "auction 105%"]),
		"the market header should consume the live season and quote",
		failures,
	)
	_check(
		stock != null and _contains_all(stock.text, ["reserve 2 / 12 eggs", "$25.00", "default farmer pickup"]),
		"the reserve line should consume exact authoritative stock, capacity, value, and safe default",
		failures,
	)
	_check(selector != null and selector.item_count == 4, "the compact selector should expose four canonical mandates", failures)
	_check(authorize != null and authorize.focus_mode == Control.FOCUS_ALL, "the file action should be keyboard focusable", failures)

	_check(ui.select_mandate(&"farmer_pickup"), "the safe default should be selectable by stable id", failures)
	await process_frame
	_check(
		terms != null and "CAPACITY UNLIMITED" in terms.text,
		"Farmer Pickup should render its authored unlimited capacity",
		failures,
	)

	_check(ui.select_mandate(&"regional_showcase"), "the premium route should be selectable by stable id", failures)
	await process_frame
	_check(
		terms != null and _contains_all(terms.text, ["capacity 6 eggs", "quote 162.5%", "fee $3.00"]),
		"the UI should read Regional Showcase's canonical projected_capacity rather than the depot-wide route capacity",
		failures,
	)
	_check(
		reason != null and _contains_all(reason.text, ["held", "regional route fleet"]),
		"the authoritative tier gate should remain visible beside the held route",
		failures,
	)
	_check(authorize != null and authorize.disabled, "a held authoritative route must not emit intent", failures)

	_check(ui.select_mandate(&"county_auction"), "the county route should be selectable by stable id", failures)
	await process_frame
	_check(
		terms != null and _contains_all(terms.text, ["capacity 8 eggs", "quote 105%", "fee $1.31", "projected cash $24.94"]),
		"the county card should display its exact tier-one frozen terms",
		failures,
	)
	_check(authorize != null and not authorize.disabled, "the funded review route should be actionable", failures)
	if authorize != null:
		authorize.pressed.emit()
	_check(requested == [&"county_auction"], "the action should emit one stable mandate intent and never mutate locally", failures)

	# The canonical state receipt uses sold_eggs/expired_eggs and cash_delta_cents.
	# Keep the UI bound to those authoritative names so its audit line cannot drift.
	var settlement := simulation._farmgate_dispatch.settle(6, 1, 8, 5)
	_check(bool(settlement.get("accepted", false)), "the receipt fixture should settle the two stored lots", failures)
	ui.apply_snapshot(simulation.snapshot())
	await process_frame
	var receipt := ui.find_child("FarmgateDispatchReceipt", true, false) as Label
	_check(
		receipt != null and receipt.visible and _contains_all(receipt.text, ["sold 2", "held 0", "expired 0", "net cash +$25.00"]),
		"the permanent audit line should consume the canonical settlement receipt field names",
		failures,
	)

	ui.apply_snapshot({})
	await process_frame
	_check(not ui.visible, "a snapshot without the authoritative projection should leave no empty dispatch furniture", failures)

	harness.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FARMGATE_DISPATCH_UI_CONTRACT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARMGATE_DISPATCH_UI_CONTRACT_TEST_PASSED projection=authoritative mandates=4 intent=stable receipt=canonical compact=282px")
	quit(0)


func _dispatch_fixture() -> DepartmentSimulation:
	var simulation := DepartmentSimulation.new(21_501, 4)
	simulation.day = 6
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 1_000_000
	simulation.owned_facilities[DepartmentSimulation.PACKING_ANNEX_ID] = 1
	simulation.owned_facilities[DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID] = 1
	simulation.owned_facilities[DepartmentSimulation.FARMGATE_DISPATCH_DEPOT_ID] = 1
	simulation._harvest_credit.public_standing = 5
	simulation._farmgate_dispatch.begin_day(6)
	simulation._farmgate_dispatch.store_lot(701, 6, 0, "Mabel", &"sound", 1_000, 1, 2, 12)
	simulation._farmgate_dispatch.store_lot(702, 6, 1, "Pip", &"golden", 1_500, 1, 2, 12)
	return simulation


func _contains_all(copy: String, fragments: Array[String]) -> bool:
	var normalized := copy.to_lower()
	for fragment in fragments:
		if not normalized.contains(fragment.to_lower()):
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
