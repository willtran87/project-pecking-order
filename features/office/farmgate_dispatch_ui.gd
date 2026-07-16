class_name FarmgateDispatchUI
extends VBoxContainer

## Compact, intent-only finished-goods planning surface for Flockwatch.
##
## The authoritative Farmgate projection owns stock, quotes, reserve safety,
## settlement, and receipts. This component only lets management compare one
## mandate at a time and emits its stable ID for simulation validation.

signal mandate_requested(mandate_id: StringName)

const ManagementTheme := preload("res://features/office/management_ui_theme.gd")

const MANDATE_ORDER: Array[StringName] = [
	&"farmer_pickup",
	&"county_auction",
	&"regional_showcase",
	&"hold_basket",
]
const MANDATE_LABELS := {
	&"farmer_pickup": "FARMER PICKUP",
	&"county_auction": "COUNTY AUCTION",
	&"regional_showcase": "REGIONAL SHOWCASE",
	&"hold_basket": "HOLD THE BASKET",
}

const COLOR_INK := Color("e9edf0")
const COLOR_MUTED := Color("aeb8c4")
const COLOR_BRASS := Color("e7c56e")
const COLOR_TEAL := Color("73b5a7")
const COLOR_RUST := Color("d68a68")
const COLOR_NAVY := Color("172832")

var _projection: Dictionary = {}
var _selected_mandate_id: StringName = &"farmer_pickup"
var _season_label: Label
var _stock_label: Label
var _mandate_selector: OptionButton
var _mandate_description: Label
var _mandate_terms: Label
var _mandate_reason: Label
var _authorize_button: Button
var _receipt_label: Label


func _ready() -> void:
	name = "FarmgateDispatchUI"
	theme = ManagementTheme.create_theme()
	mouse_filter = Control.MOUSE_FILTER_PASS
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	_build_interface()
	_refresh()


func apply_snapshot(snapshot: Dictionary) -> void:
	var projection := _extract_projection(snapshot)
	if projection == _projection:
		return
	_projection = projection.duplicate(true)
	_refresh()


func presentation_state() -> Dictionary:
	var mandate := _mandates_by_id().get(_selected_mandate_id, {}) as Dictionary
	return {
		"visible": visible,
		"selected_mandate_id": _selected_mandate_id,
		"authorize_enabled": _authorize_button != null and not _authorize_button.disabled,
		"stock_count": int(_projection.get("stock_count", 0)),
		"storage_capacity_eggs": int(_projection.get("storage_capacity_eggs", 0)),
		"active_mandate_id": StringName(String(_projection.get("active_mandate_id", "farmer_pickup"))),
		"selected_reason": String(mandate.get("reason", "")),
		"receipt": (_projection.get("last_settlement_receipt", {}) as Dictionary).duplicate(true),
	}


func select_mandate(mandate_id: StringName) -> bool:
	if mandate_id not in MANDATE_ORDER:
		return false
	_selected_mandate_id = mandate_id
	if _mandate_selector != null:
		for index in _mandate_selector.item_count:
			if StringName(String(_mandate_selector.get_item_metadata(index))) == mandate_id:
				_mandate_selector.select(index)
				break
	_refresh_selected_mandate()
	return true


func _build_interface() -> void:
	var section := PanelContainer.new()
	section.name = "FarmgateDispatchSection"
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_stylebox_override("panel", _section_style())
	add_child(section)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 9)
	section.add_child(margin)

	var column := VBoxContainer.new()
	column.name = "FarmgateDispatchColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 5)
	margin.add_child(column)

	var header := HFlowContainer.new()
	header.name = "FarmgateDispatchHeader"
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("h_separation", 8)
	header.add_theme_constant_override("v_separation", 2)
	column.add_child(header)

	var title := _make_label("FARMGATE DISPATCH", 12, COLOR_BRASS)
	title.name = "FarmgateDispatchTitle"
	header.add_child(title)
	_season_label = _make_label("MARKET BOOK PENDING", 10, COLOR_TEAL)
	_season_label.name = "FarmgateDispatchSeason"
	_season_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(_season_label)

	_stock_label = _make_label("Finished baskets are being counted.", 11, COLOR_INK)
	_stock_label.name = "FarmgateDispatchStock"
	_stock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_stock_label)

	var divider := HSeparator.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(divider)

	var mandate_heading := _make_label("NEXT CLOSING MANDATE", 10, COLOR_BRASS)
	mandate_heading.name = "FarmgateDispatchMandateHeading"
	column.add_child(mandate_heading)

	_mandate_selector = OptionButton.new()
	_mandate_selector.name = "FarmgateDispatchMandateSelector"
	_mandate_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mandate_selector.custom_minimum_size.y = 38.0
	_mandate_selector.focus_mode = Control.FOCUS_ALL
	for mandate_id in MANDATE_ORDER:
		_mandate_selector.add_item(String(MANDATE_LABELS[mandate_id]))
		_mandate_selector.set_item_metadata(_mandate_selector.item_count - 1, String(mandate_id))
	_mandate_selector.item_selected.connect(_on_mandate_selected)
	column.add_child(_mandate_selector)

	_mandate_description = _make_label("Select a route to inspect its exact settlement terms.", 10, COLOR_MUTED)
	_mandate_description.name = "FarmgateDispatchMandateDescription"
	_mandate_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_mandate_description)

	_mandate_terms = _make_label("CAPACITY AND QUOTE PENDING", 10, COLOR_INK)
	_mandate_terms.name = "FarmgateDispatchMandateTerms"
	_mandate_terms.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_mandate_terms)

	_mandate_reason = _make_label("HELD / Dispatch terms are unavailable.", 10, COLOR_RUST)
	_mandate_reason.name = "FarmgateDispatchMandateReason"
	_mandate_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_mandate_reason)

	_authorize_button = Button.new()
	_authorize_button.name = "FarmgateDispatchAuthorize"
	_authorize_button.text = "MANDATE FILE UNAVAILABLE"
	_authorize_button.theme_type_variation = &"PrimaryButton"
	_authorize_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_authorize_button.custom_minimum_size.y = 42.0
	_authorize_button.focus_mode = Control.FOCUS_ALL
	_authorize_button.disabled = true
	_authorize_button.pressed.connect(_on_authorize_pressed)
	column.add_child(_authorize_button)

	_receipt_label = _make_label("", 10, COLOR_MUTED)
	_receipt_label.name = "FarmgateDispatchReceipt"
	_receipt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_receipt_label.visible = false
	column.add_child(_receipt_label)


func _refresh() -> void:
	if _season_label == null:
		return
	visible = not _projection.is_empty() and bool(_projection.get(
		"enabled", int(_projection.get("level", 0)) > 0
	))
	if not visible:
		return

	var season_value: Variant = _projection.get("season", {})
	var season := season_value as Dictionary if season_value is Dictionary else {}
	var season_name := String(season.get("label", season.get("id", "BASELINE MARKET"))).replace("_", " ").to_upper()
	var auction_basis := int(season.get("auction_basis_points", _projection.get("auction_basis_points", 10_000)))
	_season_label.text = "%s / AUCTION %s" % [season_name, _percent_from_basis_points(auction_basis)]

	var stock := maxi(0, int(_projection.get("stock_count", 0)))
	var capacity := maxi(0, int(_projection.get("storage_capacity_eggs", _projection.get("storage_capacity", 0))))
	var value := maxi(0, int(_projection.get("stock_value_cents", 0)))
	var expiring := maxi(0, int(_projection.get("expiring_count", 0)))
	var age := maxi(0, int(_projection.get("oldest_age_shifts", 0)))
	_stock_label.text = (
		"RESERVE %d / %d EGGS / UNSETTLED VALUE $%.2f\n"
		+ "OLDEST %d SHIFT%s / %d EXPIRING / DEFAULT FARMER PICKUP NEVER BLOCKS CLOSE"
	) % [
		stock,
		capacity,
		float(value) / 100.0,
		age,
		"" if age == 1 else "S",
		expiring,
	]

	var active_id := StringName(String(_projection.get("active_mandate_id", "farmer_pickup")))
	if _selected_mandate_id not in _mandates_by_id():
		_selected_mandate_id = active_id if active_id in MANDATE_ORDER else &"farmer_pickup"
	select_mandate(_selected_mandate_id)
	_refresh_receipt()


func _refresh_selected_mandate() -> void:
	if _authorize_button == null:
		return
	var mandate := _mandates_by_id().get(_selected_mandate_id, {}) as Dictionary
	var label := String(mandate.get("label", MANDATE_LABELS.get(_selected_mandate_id, _selected_mandate_id))).to_upper()
	var description := String(mandate.get("description", "No authored settlement description is available."))
	var dispatch_capacity := maxi(0, int(mandate.get(
		"projected_capacity",
		mandate.get("projected_capacity_eggs", mandate.get(
			"dispatch_capacity_eggs",
			_projection.get("dispatch_capacity_eggs", 0),
		)),
	)))
	var basis_points := int(mandate.get("projected_basis_points", mandate.get("basis_points", 10_000)))
	var fee := maxi(0, int(mandate.get("projected_fee_cents", mandate.get("fee_cents", 0))))
	var payout := maxi(0, int(mandate.get("projected_payout_cents", 0)))
	var reason := String(mandate.get("reason", mandate.get("unavailable_reason", ""))).strip_edges()
	var can_authorize := bool(mandate.get("can_authorize", false))
	if mandate.is_empty():
		reason = "This mandate is missing from the authoritative dispatch file."
		can_authorize = false

	_mandate_description.text = description
	var capacity_copy := "%d EGGS" % dispatch_capacity
	if _selected_mandate_id == &"farmer_pickup":
		capacity_copy = "UNLIMITED"
	elif _selected_mandate_id == &"hold_basket":
		capacity_copy = "0 EGGS"
	_mandate_terms.text = "CAPACITY %s / QUOTE %s / FEE $%.2f%s" % [
		capacity_copy,
		_percent_from_basis_points(basis_points),
		float(fee) / 100.0,
		" / PROJECTED CASH $%.2f" % (float(payout) / 100.0) if payout > 0 else "",
	]
	if can_authorize:
		_mandate_reason.text = "READY / Exact quote freezes when this mandate is filed."
		_mandate_reason.add_theme_color_override("font_color", COLOR_TEAL)
		_authorize_button.text = "FILE %s" % label
	else:
		_mandate_reason.text = "HELD / %s" % (reason if not reason.is_empty() else "This route is not currently authorized.")
		_mandate_reason.add_theme_color_override("font_color", COLOR_RUST)
		_authorize_button.text = "%s ON HOLD" % label
	_authorize_button.disabled = not can_authorize
	_authorize_button.tooltip_text = "%s / %s" % [label, _mandate_reason.text]


func _refresh_receipt() -> void:
	var value: Variant = _projection.get("last_settlement_receipt", {})
	var receipt := value as Dictionary if value is Dictionary else {}
	_receipt_label.visible = not receipt.is_empty()
	if receipt.is_empty():
		_receipt_label.text = ""
		return
	var mandate_label := String(receipt.get("mandate_label", receipt.get("mandate_id", "DISPATCH"))).replace("_", " ").to_upper()
	var sold := maxi(0, int(receipt.get(
		"sold_eggs", receipt.get("sold_count", receipt.get("eggs_sold", 0))
	)))
	var held := maxi(0, int(receipt.get(
		"stock_after", receipt.get("held_count", receipt.get("eggs_held", 0))
	)))
	var overflow := maxi(0, int(receipt.get("overflow_count", receipt.get("overflow_eggs", 0))))
	var expired := maxi(0, int(receipt.get("expired_count", receipt.get("expired_eggs", 0))))
	var payout := int(receipt.get(
		"settlement_cash_delta_cents",
		receipt.get("net_payout_cents", receipt.get("cash_delta_cents", 0)),
	))
	_receipt_label.text = (
		"LAST ROUTE / %s / SOLD %d / HELD %d / OVERFLOW %d / EXPIRED %d\n"
		+ "NET CASH %s$%.2f"
	) % [
		mandate_label,
		sold,
		held,
		overflow,
		expired,
		"+" if payout >= 0 else "-",
		absf(float(payout) / 100.0),
	]
	_receipt_label.tooltip_text = _receipt_label.text


func _on_mandate_selected(index: int) -> void:
	if index < 0 or index >= _mandate_selector.item_count:
		return
	_selected_mandate_id = StringName(String(_mandate_selector.get_item_metadata(index)))
	_refresh_selected_mandate()


func _on_authorize_pressed() -> void:
	if _authorize_button == null or _authorize_button.disabled:
		return
	mandate_requested.emit(_selected_mandate_id)


func _mandates_by_id() -> Dictionary:
	var result: Dictionary = {}
	for mandate_value in _projection.get("mandates", []):
		if mandate_value is not Dictionary:
			continue
		var mandate := mandate_value as Dictionary
		var mandate_id := StringName(String(mandate.get("id", "")))
		if mandate_id in MANDATE_ORDER:
			result[mandate_id] = mandate
	return result


func _extract_projection(snapshot: Dictionary) -> Dictionary:
	var value: Variant = snapshot.get("farmgate_dispatch", {})
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _percent_from_basis_points(value: int) -> String:
	var percent := float(value) / 100.0
	return "%d%%" % roundi(percent) if is_equal_approx(percent, roundf(percent)) else "%.1f%%" % percent


func _make_label(text_value: String, size_value: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color)
	return label


func _section_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(COLOR_NAVY, 0.92)
	style.border_color = Color("8a7047")
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	return style
