class_name EconomicBriefingUI
extends VBoxContainer

## Presentation-only economic decision support for Flockwatch Capital.
##
## All prices, margins, trends, resources, and bottlenecks arrive through the
## simulation's `economic_briefing` projection. This component formats that
## authority and never mutates or independently recalculates the economy.

const FlockwatchDisclosureToggleScript := preload(
	"res://features/office/flockwatch_disclosure_toggle.gd"
)

const COLOR_INK := Color("d8e2e4")
const COLOR_MUTED := Color("9ba9af")
const COLOR_TEAL := Color("83b9ae")
const COLOR_GOLD := Color("e0c078")
const COLOR_WARNING := Color("db9b69")
const COLOR_DANGER := Color("d77b70")

var _built := false
var _briefing: Dictionary = {}
var _headline: Label
var _cash: Label
var _costs: Label
var _market: Label
var _bottleneck: Label
var _trend: Label
var _history: Label
var _resources: Label
var _strategies: Label
var _recovery: Label
var _details_toggle: FlockwatchDisclosureToggle


func _ready() -> void:
	_ensure_interface()


func apply_snapshot(snapshot: Dictionary) -> void:
	_ensure_interface()
	var source_value: Variant = snapshot.get("economic_briefing", {})
	_briefing = (
		(source_value as Dictionary).duplicate(true)
		if source_value is Dictionary else
		{}
	)
	_refresh()


func presentation_snapshot() -> Dictionary:
	return _briefing.duplicate(true)


func accessible_text() -> String:
	if _briefing.is_empty():
		return "Economic briefing unavailable."
	return " ".join([
		_headline.text,
		_cash.text,
		_costs.text,
		_market.text,
		_bottleneck.text,
		_trend.text,
		_history.text,
		_resources.text,
		_strategies.text,
		_recovery.text,
	]).replace("\n", " ")


func _ensure_interface() -> void:
	if _built:
		return
	_built = true
	name = "EconomicBriefingUI"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)

	var heading := _label("ECONOMIC BRIEFING", 17, COLOR_GOLD)
	heading.name = "EconomicBriefingHeading"
	add_child(heading)

	var summary_panel := PanelContainer.new()
	summary_panel.name = "EconomicBriefingSummary"
	summary_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("182630"), Color("4f6870")),
	)
	add_child(summary_panel)
	var summary_margin := MarginContainer.new()
	for side: StringName in [
		&"margin_left", &"margin_right", &"margin_top", &"margin_bottom",
	]:
		summary_margin.add_theme_constant_override(side, 9)
	summary_panel.add_child(summary_margin)
	var summary_rows := VBoxContainer.new()
	summary_rows.add_theme_constant_override("separation", 4)
	summary_margin.add_child(summary_rows)

	_headline = _label("AWAITING AUTHORITATIVE LEDGER", 13, COLOR_GOLD)
	_headline.name = "EconomicBriefingHeadline"
	_cash = _label("CASH / awaiting projection", 12, COLOR_INK)
	_cash.name = "EconomicBriefingCash"
	_costs = _label("COSTS / awaiting projection", 11, COLOR_MUTED)
	_costs.name = "EconomicBriefingCosts"
	_market = _label("MARKET / awaiting calendar", 12, COLOR_TEAL)
	_market.name = "EconomicBriefingMarket"
	_bottleneck = _label("BOTTLENECK / awaiting workflow", 12, COLOR_WARNING)
	_bottleneck.name = "EconomicBriefingBottleneck"
	_trend = _label("TREND / awaiting first close", 11, COLOR_MUTED)
	_trend.name = "EconomicBriefingTrend"
	for label: Label in [_headline, _cash, _costs, _market, _bottleneck, _trend]:
		summary_rows.add_child(label)

	_details_toggle = FlockwatchDisclosureToggleScript.new()
	_details_toggle.name = "EconomicBriefingDetailsToggle"
	add_child(_details_toggle)
	_history = _label("CLOSE HISTORY / no filed shifts", 11, COLOR_MUTED)
	_history.name = "EconomicBriefingHistory"
	_resources = _label("RESOURCE MAP / awaiting projection", 11, COLOR_MUTED)
	_resources.name = "EconomicBriefingResources"
	_strategies = _label("STRATEGY FILE / awaiting projection", 11, COLOR_MUTED)
	_strategies.name = "EconomicBriefingStrategies"
	_recovery = _label("RECOVERY FILE / awaiting projection", 11, COLOR_MUTED)
	_recovery.name = "EconomicBriefingRecovery"
	for label: Label in [_history, _resources, _strategies, _recovery]:
		add_child(label)
	_details_toggle.configure(
		"WHY + RECOVERY",
		"RESOURCES / HISTORY / OPTIONS",
		[_history, _resources, _strategies, _recovery],
		false,
	)


func _refresh() -> void:
	if _briefing.is_empty():
		_headline.text = "AWAITING AUTHORITATIVE LEDGER"
		_cash.text = "CASH / awaiting projection"
		_costs.text = "COSTS / awaiting projection"
		_market.text = "MARKET / awaiting calendar"
		_bottleneck.text = "BOTTLENECK / awaiting workflow"
		_trend.text = "TREND / awaiting first close"
		_history.text = "CLOSE HISTORY / no filed shifts"
		_resources.text = "RESOURCE MAP / awaiting projection"
		_strategies.text = "STRATEGY FILE / awaiting projection"
		_recovery.text = "RECOVERY FILE / awaiting projection"
		return

	var status_id := StringName(String(_briefing.get("status_id", &"stable")))
	_headline.text = "%s / DAY %d / VALUES FILED NOW" % [
		String(_briefing.get("status_label", "OPERATING ROOM")),
		int(_briefing.get("day", 1)),
	]
	_headline.add_theme_color_override(
		"font_color",
		COLOR_DANGER if status_id == &"critical" else (
			COLOR_WARNING if status_id == &"tight" else COLOR_GOLD
		),
	)

	var cash := _briefing.get("cash", {}) as Dictionary
	_cash.text = (
		"CASH / FUND %s / RESERVED %s / FREE %s\n"
		+ "RUN RATE / SECURED %s - FILED COST %s = %s / BREAK-EVEN LEFT %s"
	) % [
		_money(int(cash.get("feed_fund_cents", 0))),
		_money(int(cash.get("protected_reserve_cents", 0))),
		_money(int(cash.get("spendable_fund_cents", 0))),
		_money(int(cash.get("secured_income_today_cents", 0))),
		_money(int(cash.get("daily_operating_cost_cents", 0))),
		_signed_money(int(cash.get("secured_operating_margin_cents", 0))),
		_money(int(cash.get("break_even_remaining_cents", 0))),
	]
	_cash.tooltip_text = (
		"Run rate uses only claim credit already secured today against the full filed "
		+ "operating cost. Unearned binder premiums and future eggs are excluded."
	)

	var costs := _briefing.get("costs", {}) as Dictionary
	_costs.text = (
		"COSTS / FEED %s / HENS %s / ROOSTERS %s / PERCHES %s\n"
		+ "FACILITIES %s / CAMPUS %s / PORTFOLIO %s"
	) % [
		_money(int(costs.get("feed_cents", 0))),
		_money(int(costs.get("hen_payroll_cents", 0))),
		_money(int(costs.get("supervisor_payroll_cents", 0))),
		_money(int(costs.get("expanded_perches_cents", 0))),
		_money(int(costs.get("facility_maintenance_cents", 0))),
		_money(int(costs.get("campus_services_cents", 0))),
		_money(int(costs.get("portfolio_operations_cents", 0))),
	]

	var market := _briefing.get("market", {}) as Dictionary
	var current_market := market.get("current", {}) as Dictionary
	var next_market := market.get("next", {}) as Dictionary
	# Market demand is authored as a signed basis-point modifier to the binder,
	# not as an absolute index. Subtracting 10,000 here previously presented a
	# real +20% Spring opportunity as -80%.
	var demand_delta := int(market.get("opportunity_demand_basis_points", 0))
	var next_demand_delta := int(
		market.get("next_opportunity_demand_basis_points", 0)
	)
	_market.text = (
		"MARKET / %s / %d DAY%s LEFT\n"
		+ "FORECAST / %s\n"
		+ "CAUSE / %s\n"
		+ "NOW / %s %s / FEED %s PER SCOOP\n"
		+ "NEXT DAY %d / %s\n"
		+ "LEAD / %s %s / FEED %s"
	) % [
		String(current_market.get("short_label", "BASELINE BOOK")),
		int(market.get("current_days_remaining", 0)),
		"" if int(market.get("current_days_remaining", 0)) == 1 else "S",
		String(market.get("forecast_certainty", "FILED CALENDAR")),
		String(market.get(
			"current_cause",
			current_market.get("summary", "Farm Mutual's filed calendar sets demand."),
		)),
		String(market.get("opportunity_lane_label", "CLAIMS")).to_upper(),
		_signed_percent(demand_delta),
		_money(int(market.get("feed_spot_unit_price_cents", 0))),
		int(market.get("next_market_day", 1)),
		String(next_market.get("short_label", "BASELINE BOOK")),
		String(market.get("next_opportunity_lane_label", "CLAIMS")).to_upper(),
		_signed_percent(next_demand_delta),
		_money(int(market.get("next_feed_spot_unit_price_cents", 0))),
	]
	_market.tooltip_text = "%s %s" % [
		String(market.get(
			"current_cause",
			"The filed market calendar determines lane demand and feed pressure.",
		)),
		String(market.get(
			"forecast_uncertainty",
			"The calendar is filed; individual claim intake can still vary.",
		)),
	]

	var bottlenecks := _briefing.get("bottlenecks", []) as Array
	var primary := (
		bottlenecks[0] as Dictionary
		if not bottlenecks.is_empty() and bottlenecks[0] is Dictionary else
		{}
	)
	_bottleneck.text = "BOTTLENECK / %s\nWHY / %s\nACT / %s" % [
		String(primary.get("label", "NO CRITICAL BOTTLENECK")),
		String(primary.get("reason", "Current systems remain inside filed limits.")),
		String(primary.get("action", "Compare the next disclosed tradeoff.")),
	]
	_bottleneck.add_theme_color_override(
		"font_color",
		COLOR_DANGER if int(primary.get("severity", 0)) >= 4 else (
			COLOR_WARNING if int(primary.get("severity", 0)) > 0 else COLOR_TEAL
		),
	)

	var trend := _briefing.get("trend", {}) as Dictionary
	_trend.text = "FIVE-CLOSE TREND / %s / AVG %s / LAST CHANGE %s" % [
		String(trend.get("status_label", "AWAITING FIRST CLOSE")),
		_signed_money(int(trend.get("average_margin_cents", 0))),
		_signed_money(int(trend.get("margin_change_cents", 0))),
	]
	_refresh_history()
	_refresh_resources()
	_refresh_strategies()
	_refresh_recovery()
	_details_toggle.set_summary("%d BOTTLENECKS / %d RECOVERY PATHS" % [
		bottlenecks.size(),
		(_briefing.get("recovery_actions", []) as Array).size(),
	])


func _refresh_history() -> void:
	var rows := _briefing.get("history", []) as Array
	if rows.is_empty():
		_history.text = "CLOSE HISTORY / no filed shifts yet"
		return
	var lines: Array[String] = ["CLOSE HISTORY / LAST %d" % rows.size()]
	for row_value: Variant in rows:
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		lines.append("DAY %d / IN %s / MARGIN %s / CASH %s / DEBT %s" % [
			int(row.get("day", 0)),
			_money(int(row.get("inflow_cents", 0))),
			_signed_money(int(row.get("operating_margin_cents", 0))),
			_money(int(row.get("closing_cash_cents", 0))),
			_money(int(row.get("closing_liabilities_cents", 0))),
		])
	_history.text = "\n".join(lines)


func _refresh_resources() -> void:
	var lines: Array[String] = ["RESOURCE MAP / SOURCE -> USE -> LIMIT"]
	for row_value: Variant in _briefing.get("resources", []) as Array:
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		lines.append("%s\n  SOURCE: %s\n  USE: %s\n  LIMIT: %s\n  VALUE: %s" % [
			String(row.get("label", "RESOURCE")),
			String(row.get("source", "")),
			String(row.get("use", "")),
			String(row.get("limit", "")),
			String(row.get("strategic_value", "")),
		])
	_resources.text = "\n".join(lines)


func _refresh_strategies() -> void:
	var lines: Array[String] = ["STRATEGY FILE / EACH ROUTE HAS A COUNTERWEIGHT"]
	for row_value: Variant in _briefing.get("strategies", []) as Array:
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		lines.append("%s\n  LEVER: %s\n  UPSIDE: %s\n  RISK: %s" % [
			String(row.get("label", "STRATEGY")),
			String(row.get("lever", "")),
			String(row.get("upside", "")),
			String(row.get("counterweight", "")),
		])
	_strategies.text = "\n".join(lines)


func _refresh_recovery() -> void:
	var lines: Array[String] = ["RECOVERY FILE / AVAILABLE OPTIONS ARE MARKED READY"]
	for row_value: Variant in _briefing.get("recovery_actions", []) as Array:
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		lines.append("%s / %s\n  %s\n  COST: %s" % [
			"READY" if bool(row.get("available", false)) else "HELD",
			String(row.get("label", "RECOVERY ACTION")),
			String(row.get("effect", "")),
			String(row.get("tradeoff", "")),
		])
	_recovery.text = "\n".join(lines)


func _label(copy: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	return style


func _money(cents: int) -> String:
	return "$%.2f" % (float(maxi(0, cents)) / 100.0)


func _signed_money(cents: int) -> String:
	return "%s$%.2f" % [
		"+" if cents >= 0 else "-",
		absf(float(cents)) / 100.0,
	]


func _signed_percent(basis_point_delta: int) -> String:
	return "%s%d%%" % [
		"+" if basis_point_delta >= 0 else "-",
		roundi(absf(float(basis_point_delta)) / 100.0),
	]
