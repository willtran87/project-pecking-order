extends SceneTree

const FarmgateDispatchUIScript := preload("res://features/office/farmgate_dispatch_ui.gd")
const ManagementUIThemeScript := preload("res://features/office/management_ui_theme.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := _dispatch_fixture()
	var test_viewport := SubViewport.new()
	test_viewport.name = "FarmgateDispatchTestViewport"
	test_viewport.size = Vector2i(282, 760)
	test_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(test_viewport)
	var harness := Control.new()
	harness.name = "FarmgateDispatchUIContractHarness"
	harness.size = Vector2(282.0, 760.0)
	test_viewport.add_child(harness)

	var ui := FarmgateDispatchUIScript.new() as FarmgateDispatchUI
	ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	harness.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	await process_frame

	var requested: Array[StringName] = []
	ui.mandate_requested.connect(
		func(mandate_id: StringName) -> void: requested.append(mandate_id)
	)
	ui.apply_snapshot(simulation.snapshot())
	await process_frame
	await process_frame

	var season := ui.find_child("FarmgateDispatchSeason", true, false) as Label
	var title := ui.find_child("FarmgateDispatchTitle", true, false) as Label
	var stock := ui.find_child("FarmgateDispatchStock", true, false) as Label
	var stock_glance := ui.find_child("FarmgateDispatchStockGlance", true, false) as Label
	var value_glance := ui.find_child("FarmgateDispatchValueGlance", true, false) as Label
	var oldest_glance := ui.find_child("FarmgateDispatchOldestGlance", true, false) as Label
	var expiring_glance := ui.find_child("FarmgateDispatchExpiringGlance", true, false) as Label
	var selector := ui.find_child("FarmgateDispatchMandateSelector", true, false) as OptionButton
	var terms := ui.find_child("FarmgateDispatchMandateTerms", true, false) as Label
	var capacity_glance := ui.find_child("FarmgateDispatchCapacityGlance", true, false) as Label
	var quote_glance := ui.find_child("FarmgateDispatchQuoteGlance", true, false) as Label
	var fee_glance := ui.find_child("FarmgateDispatchFeeGlance", true, false) as Label
	var cash_glance := ui.find_child("FarmgateDispatchCashGlance", true, false) as Label
	var reason := ui.find_child("FarmgateDispatchMandateReason", true, false) as Label
	var authorize := ui.find_child("FarmgateDispatchAuthorize", true, false) as Button
	_check(ui.visible, "a commissioned authoritative projection should reveal Farmgate Dispatch", failures)
	_check(
		season != null and _contains_all(season.text, ["spring", "auction 105%"])
		and "spring hatch surge" in season.tooltip_text.to_lower(),
		"the compact market header should retain the live full season and quote on demand",
		failures,
	)
	_check(
		stock != null and _contains_all(stock.text, ["reserve 2 / 12 eggs", "$25.00", "default farmer pickup"]),
		"the reserve line should consume exact authoritative stock, capacity, value, and safe default",
		failures,
	)
	_check(
		stock != null and not stock.visible
		and stock_glance != null and _contains_all(stock_glance.text, ["stock", "2 / 12"])
		and value_glance != null and _contains_all(value_glance.text, ["value", "$25"])
		and oldest_glance != null and _contains_all(oldest_glance.text, ["oldest", "0 shifts"])
		and expiring_glance != null and _contains_all(expiring_glance.text, ["due", "0"]),
		"the first-read reserve should use four glance tiles while retaining the exact hidden audit copy",
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
		terms != null and not terms.visible
		and capacity_glance != null and _contains_all(capacity_glance.text, ["cap", "6 eggs"])
		and quote_glance != null and _contains_all(quote_glance.text, ["quote", "162.5%"])
		and fee_glance != null and _contains_all(fee_glance.text, ["fee", "$3"])
		and cash_glance != null and _contains_all(cash_glance.text, ["net", "$37.63"]),
		"the route's first read should be compact tiles backed by the exact hidden terms",
		failures,
	)
	_check(
		reason != null and _contains_all(reason.text, ["held", "need route fleet"])
		and "regional route fleet" in reason.tooltip_text.to_lower(),
		"the compact held state should retain the authoritative tier gate on demand",
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
	_check(
		cash_glance != null and _contains_all(cash_glance.text, ["net", "$24.94"])
		and authorize != null and authorize.text == "AUCTION",
		"the county route should expose net cash and a glance-first action verb",
		failures,
	)
	_check(authorize != null and not authorize.disabled, "the funded review route should be actionable", failures)
	if authorize != null:
		authorize.pressed.emit()
	_check(requested == [&"county_auction"], "the action should emit one stable mandate intent and never mutate locally", failures)
	var authorization := simulation.authorize_farmgate_dispatch(&"county_auction")
	_check(bool(authorization.get("accepted", false)), "the filing receipt fixture should authorize the selected county route", failures)
	ui.apply_snapshot(simulation.snapshot())
	await process_frame
	var filed_receipt := ui.find_child("FarmgateDispatchAuthorizationReceipt", true, false) as Label
	_check(
		filed_receipt != null and filed_receipt.visible
		and _contains_all(filed_receipt.text, ["filed", "auction", "day 6", "105%"])
		and _contains_all(filed_receipt.tooltip_text, ["route filed", "county auction", "listing fee $0"]),
		"an accepted filing should become a compact durable receipt without implying an immediate debit",
		failures,
	)
	_check(
		reason != null and reason.text == "FILED / QUOTE LOCKED"
		and authorize != null and authorize.disabled and authorize.text == "FILED",
		"the selected filed route should read as durable success rather than a held or unavailable error",
		failures,
	)

	# The canonical state receipt uses sold_eggs/expired_eggs and cash_delta_cents.
	# Keep the UI bound to those authoritative names so its audit line cannot drift.
	var settlement_simulation := _dispatch_fixture()
	var settlement := settlement_simulation._farmgate_dispatch.settle(6, 1, 8, 5)
	_check(bool(settlement.get("accepted", false)), "the receipt fixture should settle the two stored lots", failures)
	ui.apply_snapshot(settlement_simulation.snapshot())
	await process_frame
	var receipt := ui.find_child("FarmgateDispatchReceipt", true, false) as Label
	_check(
		receipt != null and receipt.visible and _contains_all(receipt.text, ["last", "pickup", "2 sold", "+$25"])
		and _contains_all(receipt.tooltip_text, ["held 0", "expired 0", "net cash +$25.00"]),
		"the permanent audit line should consume the canonical settlement receipt field names",
		failures,
	)

	var prior_theme := ui.theme
	var control_records := _capture_control_records(ui)
	ui.theme = ManagementUIThemeScript.create_theme(false, 1.5)
	_apply_explicit_font_scale(ui, 1.5)
	await process_frame
	await process_frame
	var route_toggle := ui.find_child("FarmgateDispatchMandateToggle", true, false) as Button
	_check(
		route_toggle != null and route_toggle.text == "HIDE ROUTES  /  3 / 4",
		"the max-scale route disclosure should retain its complete compact count",
		failures,
	)
	if "--capture-max-scale-farmgate" in OS.get_cmdline_user_args():
		var capture_directory := ProjectSettings.globalize_path(
			"res://output/web-game/farmgate-dispatch-scale-v1"
		)
		DirAccess.make_dir_recursive_absolute(capture_directory)
		var capture_image := test_viewport.get_texture().get_image()
		_check(
			capture_image != null,
			"Farmgate scale capture should expose the rendered compact filing",
			failures,
		)
		if capture_image != null:
			_check(
				capture_image.save_png(
					capture_directory.path_join(
						"farmgate-dispatch-282x760-150.png"
					)
				) == OK,
				"Farmgate scale capture should save",
				failures,
			)
	_expand_interface_copy(ui)
	await process_frame
	await process_frame
	var ui_rect := ui.get_global_rect()
	_check(
		ui.get_combined_minimum_size().x <= harness.size.x + 0.5,
		"150-percent expanded Farmgate filing should remain inside 282px (minimum=%s viewport=%s largest=%s)"
		% [
			ui.get_combined_minimum_size(),
			harness.size,
			_largest_minimum_widths(ui),
		],
		failures,
	)
	_check(
		_visible_children_fit_horizontally(ui, ui_rect),
		"every max-scale Farmgate control should remain horizontally contained",
		failures,
	)
	_check(
		title != null and season != null
		and title.get_global_rect().end.y <= season.get_global_rect().position.y + 0.5,
		"the scaled Farmgate title and market line should remain vertically separated",
		failures,
	)
	_check(
		selector != null
		and not selector.fit_to_longest_item
		and authorize != null
		and authorize.clip_text,
		"compact Farmgate actions should shrink independently of expanded option and action copy",
		failures,
	)
	_restore_control_records(control_records)
	ui.theme = prior_theme
	await process_frame
	await process_frame

	ui.apply_snapshot({})
	await process_frame
	_check(not ui.visible, "a snapshot without the authoritative projection should leave no empty dispatch furniture", failures)

	test_viewport.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FARMGATE_DISPATCH_UI_CONTRACT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARMGATE_DISPATCH_UI_CONTRACT_TEST_PASSED projection=authoritative mandates=4 intent=stable filing_receipt=durable settlement_receipt=canonical compact=282px")
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


func _visible_children_fit_horizontally(
	root_control: Control,
	root_rect: Rect2,
) -> bool:
	for node_value: Node in root_control.find_children(
		"*",
		"Control",
		true,
		false,
	):
		var control := node_value as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		if (
			rect.position.x < root_rect.position.x - 0.5
			or rect.end.x > root_rect.end.x + 0.5
		):
			return false
	return true


func _largest_minimum_widths(root_control: Control) -> String:
	var rows: Array[Dictionary] = []
	for node_value: Node in root_control.find_children(
		"*",
		"Control",
		true,
		false,
	):
		var control := node_value as Control
		if control != null and control.is_visible_in_tree():
			rows.append({
				"name": control.name,
				"minimum": control.get_combined_minimum_size().x,
				"width": control.size.x,
			})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("minimum", 0.0)) > float(b.get("minimum", 0.0))
	)
	var summaries: Array[String] = []
	for index: int in mini(12, rows.size()):
		var row := rows[index]
		summaries.append("%s:min=%.1f/size=%.1f" % [
			String(row.get("name", "")),
			float(row.get("minimum", 0.0)),
			float(row.get("width", 0.0)),
		])
	return ", ".join(summaries)


func _capture_control_records(root_node: Node) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for node_value: Node in root_node.find_children(
		"*",
		"Control",
		true,
		false,
	):
		var control := node_value as Control
		var record := {
			"control": control,
			"had_font_override": control.has_theme_font_size_override(
				"font_size"
			),
			"font_size": control.get_theme_font_size("font_size"),
			"kind": &"",
			"text": "",
			"items": [] as Array[String],
		}
		if control is OptionButton:
			var option := control as OptionButton
			var items: Array[String] = []
			for item_index: int in option.item_count:
				items.append(option.get_item_text(item_index))
			record["kind"] = &"option"
			record["items"] = items
		elif control is Button:
			record["kind"] = &"button"
			record["text"] = (control as Button).text
		elif control is Label:
			record["kind"] = &"label"
			record["text"] = (control as Label).text
		records.append(record)
	return records


func _restore_control_records(records: Array[Dictionary]) -> void:
	for record: Dictionary in records:
		var value: Variant = record.get("control")
		if not is_instance_valid(value):
			continue
		var control := value as Control
		if control == null:
			continue
		match StringName(record.get("kind", &"")):
			&"option":
				var option := control as OptionButton
				var items := record.get("items", []) as Array
				for item_index: int in mini(option.item_count, items.size()):
					option.set_item_text(item_index, String(items[item_index]))
			&"button":
				(control as Button).text = String(record.get("text", ""))
			&"label":
				(control as Label).text = String(record.get("text", ""))
		if bool(record.get("had_font_override", false)):
			control.add_theme_font_size_override(
				"font_size",
				int(record.get("font_size", 16)),
			)
		else:
			control.remove_theme_font_size_override("font_size")


func _apply_explicit_font_scale(root_node: Node, scale: float) -> void:
	for node_value: Node in root_node.find_children(
		"*",
		"Control",
		true,
		false,
	):
		var control := node_value as Control
		if (
			control != null
			and control.has_theme_font_size_override("font_size")
		):
			var base_size := control.get_theme_font_size("font_size")
			control.add_theme_font_size_override(
				"font_size",
				maxi(10, roundi(float(base_size) * scale)),
			)


func _expand_interface_copy(root_node: Node) -> void:
	for node_value: Node in root_node.find_children(
		"*",
		"Control",
		true,
		false,
	):
		if node_value is OptionButton:
			var option := node_value as OptionButton
			for item_index: int in option.item_count:
				option.set_item_text(
					item_index,
					_expanded(option.get_item_text(item_index)),
				)
		elif node_value is Button:
			var button := node_value as Button
			button.text = _expanded(button.text)
		elif node_value is Label:
			var label := node_value as Label
			label.text = _expanded(label.text)


func _expanded(source: String) -> String:
	var expanded := source
	for vowel: String in [
		"a",
		"e",
		"i",
		"o",
		"u",
		"A",
		"E",
		"I",
		"O",
		"U",
	]:
		expanded = expanded.replace(vowel, vowel + vowel)
	return expanded


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
