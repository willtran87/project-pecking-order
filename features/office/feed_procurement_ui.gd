class_name FeedProcurementUI
extends VBoxContainer

## Compact feed-inventory controls hosted inside the existing Flockwatch ledger.
##
## This component is intent-only. Quotes, quantities, costs, ration effects, and
## disabled reasons are copied from the authoritative feed_procurement snapshot.

signal feed_order_requested(order_id: StringName)

const ManagementTheme := preload("res://features/office/management_ui_theme.gd")
const FlockwatchDisclosureToggleScript := preload("res://features/office/flockwatch_disclosure_toggle.gd")

const OFFER_IDS := [
	&"local_whole_grain",
	&"inspirational_bulk_mash",
	&"fixed_future_reserve",
]
const OFFER_LABELS := {
	&"local_whole_grain": "LOCAL WHOLE GRAIN",
	&"inspirational_bulk_mash": "INSPIRATIONAL BULK MASH",
	&"fixed_future_reserve": "FIXED FUTURE RESERVE",
}

const COLOR_INK := Color("e9edf0")
const COLOR_MUTED := Color("aeb8c4")
const COLOR_BRASS := Color("e7c56e")
const COLOR_TEAL := Color("73b5a7")
const COLOR_RUST := Color("d68a68")
const COLOR_PAPER := Color("ddd2b8")
const COLOR_NAVY := Color("172832")

var _snapshot: Dictionary = {}
var _season_quote_label: Label
var _inventory_label: Label
var _active_ration_label: Label
var _fallback_label: Label
var _last_activity_label: Label
var _offers_toggle
var _offer_controls: Dictionary = {}
var _had_actionable_offer := false


func _ready() -> void:
	name = "FeedProcurementUI"
	theme = ManagementTheme.create_theme()
	mouse_filter = Control.MOUSE_FILTER_PASS
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	_build_interface()
	_refresh()


func apply_snapshot(snapshot: Dictionary) -> void:
	# Office snapshots are large and arrive throughout the live shift. Retain only
	# this component's canonical projection and do no layout work while it is
	# unchanged instead of cloning the campaign, roster, and full facility ledger.
	var procurement := _extract_procurement_snapshot(snapshot)
	if procurement == _snapshot:
		return
	_snapshot = procurement.duplicate(true)
	_refresh()


func _build_interface() -> void:
	var section := PanelContainer.new()
	section.name = "FeedProcurementSection"
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
	column.name = "FeedProcurementColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 5)
	margin.add_child(column)

	var header := HFlowContainer.new()
	header.name = "FeedProcurementHeader"
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("h_separation", 8)
	header.add_theme_constant_override("v_separation", 2)
	column.add_child(header)
	var title := _make_label("FLOCK PROVISIONS", 12, COLOR_BRASS)
	title.name = "FeedProcurementTitle"
	header.add_child(title)
	_season_quote_label = _make_label("SEASONAL SPOT QUOTE PENDING", 10, COLOR_TEAL)
	_season_quote_label.name = "FeedProcurementSeasonQuote"
	_season_quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(_season_quote_label)

	_inventory_label = _make_label("Feed inventory is being counted.", 11, COLOR_INK)
	_inventory_label.name = "FeedProcurementInventory"
	_inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_inventory_label)

	_active_ration_label = _make_label("", 10, COLOR_MUTED)
	_active_ration_label.name = "FeedProcurementActiveRation"
	_active_ration_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_active_ration_label.visible = false
	column.add_child(_active_ration_label)

	_fallback_label = _make_label("", 10, COLOR_TEAL)
	_fallback_label.name = "FeedProcurementSpotFallback"
	_fallback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_fallback_label)

	_offers_toggle = FlockwatchDisclosureToggleScript.new()
	_offers_toggle.name = "FeedProcurementOffersToggle"
	column.add_child(_offers_toggle)

	var divider := HSeparator.new()
	divider.name = "FeedProcurementOffersDivider"
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(divider)

	var offer_heading := _make_label("REVIEW-ONLY FEED ORDERS", 10, COLOR_BRASS)
	offer_heading.name = "FeedProcurementOfferHeading"
	column.add_child(offer_heading)

	var offer_list := VBoxContainer.new()
	offer_list.name = "FeedProcurementOfferList"
	offer_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offer_list.add_theme_constant_override("separation", 6)
	column.add_child(offer_list)
	for offer_id: StringName in OFFER_IDS:
		_build_offer_card(offer_list, offer_id)
	var offer_targets: Array[Control] = [divider, offer_heading, offer_list]
	_offers_toggle.configure("FEED ORDERS", "3 SUPPLIER FILES", offer_targets, false)

	_last_activity_label = _make_label("", 10, COLOR_MUTED)
	_last_activity_label.name = "FeedProcurementLastActivity"
	_last_activity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_last_activity_label)


func _build_offer_card(parent: VBoxContainer, offer_id: StringName) -> void:
	var suffix := String(offer_id)
	var card := PanelContainer.new()
	card.name = "FeedProcurementOffer_%s" % suffix
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _offer_style())
	parent.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 3)
	margin.add_child(column)

	var title := _make_label(String(OFFER_LABELS.get(offer_id, String(offer_id))).to_upper(), 11, COLOR_PAPER)
	title.name = "FeedProcurementOfferTitle_%s" % suffix
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)

	var description := _make_label("Authoritative supplier terms are pending.", 10, COLOR_MUTED)
	description.name = "FeedProcurementOfferDescription_%s" % suffix
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description)

	var terms := _make_label("QUANTITY 0 SCOOPS  /  PREPAID $0.00", 10, COLOR_INK)
	terms.name = "FeedProcurementOfferTerms_%s" % suffix
	terms.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(terms)

	var ration := _make_label("RATION EFFECT  /  BASELINE", 10, COLOR_MUTED)
	ration.name = "FeedProcurementOfferRation_%s" % suffix
	ration.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(ration)

	var reason := _make_label("HELD  /  Supplier terms are unavailable.", 10, COLOR_RUST)
	reason.name = "FeedProcurementOfferReason_%s" % suffix
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(reason)

	var order_button := Button.new()
	order_button.name = "FeedProcurementOrder_%s" % suffix
	order_button.text = "OFFER FILE UNAVAILABLE"
	order_button.theme_type_variation = &"PrimaryButton"
	order_button.focus_mode = Control.FOCUS_ALL
	order_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	order_button.custom_minimum_size = Vector2(0.0, 38.0)
	order_button.disabled = true
	order_button.pressed.connect(_on_order_pressed.bind(offer_id))
	column.add_child(order_button)

	_offer_controls[offer_id] = {
		"title": title,
		"description": description,
		"terms": terms,
		"ration": ration,
		"reason": reason,
		"button": order_button,
	}


func _refresh() -> void:
	if _season_quote_label == null:
		return
	var procurement := _procurement_snapshot()
	visible = not procurement.is_empty()
	if procurement.is_empty():
		return

	_refresh_quote_and_inventory(procurement)
	var offers_by_id := _offers_by_id(procurement)
	for offer_id: StringName in OFFER_IDS:
		_refresh_offer(offer_id, offers_by_id.get(offer_id, {}) as Dictionary, procurement)
	_refresh_offers_disclosure()
	_last_activity_label.text = _last_activity_copy(procurement)


func set_offers_expanded(expanded: bool) -> void:
	if _offers_toggle != null:
		_offers_toggle.set_expanded(expanded)


func offers_expanded() -> bool:
	return _offers_toggle != null and _offers_toggle.is_expanded()


func _refresh_offers_disclosure() -> void:
	if _offers_toggle == null:
		return
	var ready_count := 0
	for controls_value: Variant in _offer_controls.values():
		if not controls_value is Dictionary:
			continue
		var button := (controls_value as Dictionary).get("button") as Button
		if button != null and not button.disabled:
			ready_count += 1
	_offers_toggle.set_summary(
		"%d READY / %d FILES" % [ready_count, OFFER_IDS.size()]
		if ready_count > 0 else
		"%d FILES / REVIEW CLOSED" % OFFER_IDS.size()
	)
	var actionable := ready_count > 0
	if actionable and not _had_actionable_offer:
		_offers_toggle.set_expanded(true, false)
	_had_actionable_offer = actionable


func _refresh_quote_and_inventory(procurement: Dictionary) -> void:
	var season_value: Variant = procurement.get("season", {})
	var season := season_value as Dictionary if season_value is Dictionary else {}
	var season_label := String(season.get("label", season.get("id", "SEASONAL"))).replace("_", " ").to_upper()
	var start_day := maxi(0, int(season.get("start_day", 0)))
	var end_day := maxi(start_day, int(season.get("end_day", start_day)))
	var days_remaining := maxi(0, int(season.get("days_remaining", 0)))
	var spot_unit := maxi(0, int(procurement.get("spot_unit_price_cents", 0)))
	var base_unit := maxi(0, int(procurement.get("base_spot_unit_price_cents", spot_unit)))
	var quote_copy := "%s  /  SPOT $%.2f PER SCOOP" % [season_label, float(spot_unit) / 100.0]
	if start_day > 0 or end_day > 0:
		quote_copy += "  /  DAYS %d-%d" % [start_day, end_day]
	quote_copy += "  /  %d DAY%s LEFT" % [days_remaining, "" if days_remaining == 1 else "S"]
	if base_unit != spot_unit:
		quote_copy += "  /  BASE $%.2f" % (float(base_unit) / 100.0)
	_season_quote_label.text = quote_copy
	_season_quote_label.tooltip_text = quote_copy

	var stock := maxi(0, int(procurement.get("stock_scoops", 0)))
	var capacity := maxi(0, int(procurement.get("capacity_scoops", 0)))
	var demand := maxi(0, int(procurement.get("demand_scoops", 0)))
	var after_demand := maxi(0, int(procurement.get("stock_after_demand_scoops", stock - demand)))
	var shortage := maxi(0, int(procurement.get("spot_shortage_scoops", demand - stock)))
	var coverage := maxf(0.0, float(procurement.get("coverage_shifts", 0.0)))
	_inventory_label.text = (
		"STOCK %d / %d SCOOPS  /  NEXT-SHIFT DEMAND %d\n"
		+ "AFTER RATIONS %d  /  COVERAGE %s SHIFT%s  /  SPOT SHORTAGE %d"
	) % [
		stock,
		capacity,
		demand,
		after_demand,
		_decimal_copy(coverage),
		"" if is_equal_approx(coverage, 1.0) else "S",
		shortage,
	]

	var ration_value: Variant = procurement.get("active_ration", {})
	var active_ration := ration_value as Dictionary if ration_value is Dictionary else {}
	_active_ration_label.visible = not active_ration.is_empty()
	if not active_ration.is_empty():
		_active_ration_label.text = "ACTIVE %s" % _ration_copy(active_ration)

	var spot_obligation := maxi(0, int(procurement.get("spot_obligation_cents", shortage * spot_unit)))
	if shortage > 0:
		_fallback_label.text = (
			"AUTOMATIC SPOT FALLBACK  /  %d uncovered scoop%s will be bought at $%.2f each "
			+ "($%.2f next shift). No order is required to continue."
		) % [
			shortage,
			"" if shortage == 1 else "s",
			float(spot_unit) / 100.0,
			float(spot_obligation) / 100.0,
		]
	else:
		_fallback_label.text = (
			"AUTOMATIC SPOT FALLBACK  /  If stored feed runs short, uncovered scoops are bought "
			+ "at $%.2f each. No order is required to continue."
		) % (float(spot_unit) / 100.0)
	_fallback_label.tooltip_text = _fallback_label.text


func _refresh_offer(offer_id: StringName, offer: Dictionary, procurement: Dictionary) -> void:
	var controls := _offer_controls.get(offer_id, {}) as Dictionary
	if controls.is_empty():
		return
	var title := controls.get("title") as Label
	var description := controls.get("description") as Label
	var terms := controls.get("terms") as Label
	var ration := controls.get("ration") as Label
	var reason_label := controls.get("reason") as Label
	var button := controls.get("button") as Button

	var has_offer := not offer.is_empty()
	var offer_label := String(offer.get("label", OFFER_LABELS.get(offer_id, String(offer_id)))).strip_edges()
	title.text = offer_label.to_upper()
	description.text = String(offer.get("description", "Supplier terms are unavailable for this review.")).strip_edges()

	var quantity := maxi(0, int(offer.get("quantity_scoops", 0)))
	var unit_cost := maxi(0, int(offer.get("unit_price_cents", offer.get("unit_cost_cents", 0))))
	var total_cost := maxi(0, int(offer.get("total_cost_cents", quantity * unit_cost)))
	var shelf_shifts := maxi(0, int(offer.get("shelf_shifts", 0)))
	var expires_day := maxi(0, int(offer.get("expires_day", 0)))
	terms.text = (
		"QUANTITY %d SCOOPS  /  $%.2f EACH  /  PREPAID $%.2f\nSHELF LIFE %d SHIFT%s%s"
	) % [
		quantity,
		float(unit_cost) / 100.0,
		float(total_cost) / 100.0,
		shelf_shifts,
		"" if shelf_shifts == 1 else "S",
		"  /  EXPIRES DAY %d" % expires_day if expires_day > 0 else "",
	]
	ration.text = _ration_copy(offer)

	var held_reason := _authorization_reason(offer_id, offer, procurement)
	var authorized := has_offer and held_reason.is_empty()
	if authorized:
		var used := maxi(0, int(procurement.get("orders_used_today", 0)))
		var limit := maxi(0, int(procurement.get("order_limit", 0)))
		var ready_reason := String(offer.get("reason", "")).strip_edges()
		if ready_reason.is_empty():
			ready_reason = "Farmer Review open; %d of %d daily orders used." % [used, limit]
		reason_label.text = "READY  /  %s" % ready_reason
		reason_label.add_theme_color_override("font_color", COLOR_TEAL)
		button.text = "ORDER %d SCOOPS  /  PREPAY $%.2f" % [quantity, float(total_cost) / 100.0]
	else:
		reason_label.text = "HELD  /  %s" % held_reason
		reason_label.add_theme_color_override("font_color", COLOR_RUST)
		button.text = _held_button_copy(has_offer, total_cost, procurement)
	button.disabled = not authorized
	button.tooltip_text = "%s  /  %d scoops  /  $%.2f prepaid  /  shelf life %d shift%s  /  %s" % [
		offer_label,
		quantity,
		float(total_cost) / 100.0,
		shelf_shifts,
		"" if shelf_shifts == 1 else "s",
		"Ready to order." if authorized else held_reason,
	]


func _authorization_reason(offer_id: StringName, offer: Dictionary, procurement: Dictionary) -> String:
	if offer.is_empty():
		return "%s is missing from the authoritative supplier file." % String(OFFER_LABELS.get(offer_id, offer_id))
	var authoritative_reason := String(offer.get("reason", offer.get("unavailable_reason", ""))).strip_edges()
	if not bool(procurement.get("planning_open", false)):
		return authoritative_reason if not authoritative_reason.is_empty() else "Feed orders open only during Farmer Review."
	var order_limit := maxi(0, int(procurement.get("order_limit", 0)))
	var orders_used := maxi(0, int(procurement.get("orders_used_today", 0)))
	if order_limit <= 0 or orders_used >= order_limit:
		return authoritative_reason if not authoritative_reason.is_empty() else "Today's feed-order authorization has already been used."
	if not bool(offer.get("available", false)):
		return authoritative_reason if not authoritative_reason.is_empty() else "This supplier is not available at the current Flock Provisions level."
	if not bool(offer.get("can_authorize", false)):
		return authoritative_reason if not authoritative_reason.is_empty() else "This prepaid order does not fit the current capacity or Feed Fund reserve."
	return ""


func _held_button_copy(has_offer: bool, total_cost: int, procurement: Dictionary) -> String:
	if not has_offer:
		return "OFFER FILE UNAVAILABLE"
	if not bool(procurement.get("planning_open", false)):
		return "REVIEW TO ORDER  /  $%.2f" % (float(total_cost) / 100.0)
	var limit := maxi(0, int(procurement.get("order_limit", 0)))
	var used := maxi(0, int(procurement.get("orders_used_today", 0)))
	if limit <= 0 or used >= limit:
		return "ORDER LIMIT REACHED"
	return "ORDER HELD  /  $%.2f PREPAID" % (float(total_cost) / 100.0)


func _ration_copy(record: Dictionary) -> String:
	var strain_basis_points := maxi(0, int(record.get("strain_basis_points", 10_000)))
	var morale_delta := int(record.get("morale_delta", 0))
	var grievance_delta := int(record.get("grievance_delta", 0))
	return "RATION EFFECT  /  STRAIN %s  /  MORALE %s  /  GRIEVANCE %s" % [
		_basis_point_delta_copy(strain_basis_points),
		_signed_copy(morale_delta),
		_signed_copy(grievance_delta),
	]


func _last_activity_copy(procurement: Dictionary) -> String:
	var delivery_value: Variant = procurement.get("last_order", {})
	var delivery := delivery_value as Dictionary if delivery_value is Dictionary else {}
	var delivery_copy := "LAST DELIVERY  /  NONE FILED"
	if not delivery.is_empty() and bool(delivery.get("accepted", true)):
		var label := String(delivery.get("offer_label", delivery.get("offer_id", "SUPPLIER"))).replace("_", " ").to_upper()
		delivery_copy = (
			"LAST DELIVERY  /  DAY %d  /  %s  /  %d SCOOPS  /  $%.2f PREPAID  /  STOCK %d -> %d"
		) % [
			maxi(0, int(delivery.get("day", 0))),
			label,
			maxi(0, int(delivery.get("quantity_scoops", 0))),
			float(maxi(0, int(delivery.get("total_cost_cents", 0)))) / 100.0,
			maxi(0, int(delivery.get("stock_before_scoops", 0))),
			maxi(0, int(delivery.get("stock_after_scoops", 0))),
		]

	var consumption_value: Variant = procurement.get("last_consumption", {})
	var consumption := consumption_value as Dictionary if consumption_value is Dictionary else {}
	var consumption_copy := "LAST CONSUMPTION  /  NONE RECORDED"
	if not consumption.is_empty():
		consumption_copy = (
			"LAST CONSUMPTION  /  DAY %d  /  DEMAND %d  /  STORED %d + SPOT %d SCOOPS  /  SPOT $%.2f"
		) % [
			maxi(0, int(consumption.get("day", 0))),
			maxi(0, int(consumption.get("demand_scoops", 0))),
			maxi(0, int(consumption.get("inventory_scoops", 0))),
			maxi(0, int(consumption.get("spot_scoops", 0))),
			float(maxi(0, int(consumption.get("spot_cost_cents", 0)))) / 100.0,
		]

	var spoilage_value: Variant = procurement.get("last_spoilage", {})
	var spoilage := spoilage_value as Dictionary if spoilage_value is Dictionary else {}
	var spoiled_total := maxi(0, int(procurement.get("spoiled_total_scoops", 0)))
	var spoiled_total_value := maxi(0, int(procurement.get("spoiled_total_value_cents", 0)))
	var spoilage_copy := "SPOILAGE  /  NONE RECORDED"
	if not spoilage.is_empty():
		spoilage_copy = (
			"LAST SPOILAGE  /  DAY %d  /  %d SCOOPS  /  $%.2f LOST  /  LIFETIME %d SCOOPS ($%.2f)"
		) % [
			maxi(0, int(spoilage.get("day", 0))),
			maxi(0, int(spoilage.get("scoops", 0))),
			float(maxi(0, int(spoilage.get("value_cents", 0)))) / 100.0,
			spoiled_total,
			float(spoiled_total_value) / 100.0,
		]
	elif spoiled_total > 0:
		spoilage_copy = "SPOILAGE  /  LIFETIME %d SCOOPS  /  $%.2f LOST" % [
			spoiled_total,
			float(spoiled_total_value) / 100.0,
		]
	return "\n".join([delivery_copy, consumption_copy, spoilage_copy])


func _on_order_pressed(offer_id: StringName) -> void:
	var procurement := _procurement_snapshot()
	var offer := (_offers_by_id(procurement)).get(offer_id, {}) as Dictionary
	if _authorization_reason(offer_id, offer, procurement).is_empty():
		feed_order_requested.emit(offer_id)


func _procurement_snapshot() -> Dictionary:
	return _snapshot


func _extract_procurement_snapshot(snapshot: Dictionary) -> Dictionary:
	var nested_value: Variant = snapshot.get("feed_procurement", {})
	if nested_value is Dictionary and not (nested_value as Dictionary).is_empty():
		return nested_value as Dictionary
	if snapshot.has("offers") and snapshot.has("spot_unit_price_cents"):
		return snapshot
	return {}


func _offers_by_id(procurement: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var offers_value: Variant = procurement.get("offers", [])
	if offers_value is Array:
		for offer_value: Variant in offers_value as Array:
			if not offer_value is Dictionary:
				continue
			var offer := (offer_value as Dictionary).duplicate(true)
			var offer_id := StringName(String(offer.get("offer_id", offer.get("id", ""))))
			if offer_id in OFFER_IDS and not result.has(offer_id):
				result[offer_id] = offer
	elif offers_value is Dictionary:
		for offer_id: StringName in OFFER_IDS:
			var offer_value: Variant = (offers_value as Dictionary).get(offer_id, (offers_value as Dictionary).get(String(offer_id), {}))
			if offer_value is Dictionary:
				result[offer_id] = (offer_value as Dictionary).duplicate(true)
	return result


func _basis_point_delta_copy(basis_points: int) -> String:
	var delta := snappedf(float(basis_points - 10_000) / 100.0, 0.1)
	if is_zero_approx(delta):
		return "BASELINE"
	return "%s%s%%" % ["+" if delta > 0.0 else "", _decimal_copy(delta)]


func _signed_copy(value: int) -> String:
	return "+%d" % value if value > 0 else str(value)


func _decimal_copy(value: float) -> String:
	var rounded := snappedf(value, 0.01)
	if is_equal_approx(rounded, float(roundi(rounded))):
		return str(roundi(rounded))
	var copy := "%.2f" % rounded
	while copy.ends_with("0"):
		copy = copy.left(-1)
	return copy


func _make_label(copy: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _section_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("152b2c")
	style.border_color = Color("6ba99a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style


func _offer_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_NAVY
	style.border_color = Color("50616d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	return style
