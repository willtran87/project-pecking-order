class_name EconomicBriefingUI
extends VBoxContainer

## Presentation-only economic decision support for Flockwatch Capital.
##
## All prices, margins, trends, resources, and bottlenecks arrive through the
## simulation's `economic_briefing` projection. This component formats that
## authority and never mutates or independently recalculates the economy.

signal economic_watch_requested(watch_id: StringName)
signal economic_watch_open_requested(page_id: StringName)
signal presentation_context_changed

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
var _free_cash_glance: Label
var _margin_glance: Label
var _break_even_glance: Label
var _watch_glance: Label
var _cash: Label
var _costs: Label
var _market: Label
var _bottleneck: Label
var _trend: Label
var _watch: Label
var _watch_selector: OptionButton
var _watch_open_button: Button
var _selected_watch: Dictionary = {}
var _history: Label
var _resources: Label
var _strategies: Label
var _recovery: Label
var _ledger_toggle: FlockwatchDisclosureToggle
var _ledger_details: VBoxContainer
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


func set_details_expanded(expanded: bool) -> void:
	_ensure_interface()
	_details_toggle.set_expanded(expanded)


func details_expanded() -> bool:
	_ensure_interface()
	return _details_toggle.is_expanded()


func set_ledger_expanded(expanded: bool) -> void:
	_ensure_interface()
	_ledger_toggle.set_expanded(expanded)


func ledger_expanded() -> bool:
	_ensure_interface()
	return _ledger_toggle.is_expanded()


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
		_watch.text,
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
	summary_rows.add_child(_headline)

	var glance_grid := GridContainer.new()
	glance_grid.name = "EconomicBriefingGlanceGrid"
	glance_grid.columns = 3
	glance_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	glance_grid.add_theme_constant_override("h_separation", 5)
	summary_rows.add_child(glance_grid)
	_free_cash_glance = _metric_chip(
		glance_grid,
		"EconomicBriefingFreeCashGlance",
		"FREE\n--",
		COLOR_TEAL,
	)
	_margin_glance = _metric_chip(
		glance_grid,
		"EconomicBriefingMarginGlance",
		"MARGIN\n--",
		COLOR_GOLD,
	)
	_break_even_glance = _metric_chip(
		glance_grid,
		"EconomicBriefingBreakEvenGlance",
		"TO GO\n--",
		COLOR_INK,
	)
	_watch_glance = _label("! AWAITING PRIORITY", 12, COLOR_WARNING)
	_watch_glance.name = "EconomicBriefingWatchGlance"
	_watch_glance.tooltip_text = (
		"The watched condition and its filed target. Use the button below to act on it."
	)
	summary_rows.add_child(_watch_glance)

	var watch_actions := VBoxContainer.new()
	watch_actions.name = "EconomicBriefingWatchActions"
	watch_actions.add_theme_constant_override("separation", 7)
	summary_rows.add_child(watch_actions)
	_watch_selector = OptionButton.new()
	_watch_selector.name = "EconomicBriefingWatchSelector"
	_watch_selector.custom_minimum_size = Vector2(178.0, 42.0)
	_watch_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_watch_selector.focus_mode = Control.FOCUS_ALL
	_watch_selector.fit_to_longest_item = false
	_watch_selector.tooltip_text = (
		"Pin one management concern here. Its current value, target, cause, and "
		+ "next action will remain in the compact Capital summary."
	)
	_watch_selector.item_selected.connect(_on_watch_selected)
	watch_actions.add_child(_watch_selector)
	_watch_open_button = Button.new()
	_watch_open_button.name = "EconomicBriefingWatchOpenButton"
	_watch_open_button.text = "OPEN FILE"
	_watch_open_button.custom_minimum_size = Vector2(100.0, 42.0)
	_watch_open_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_watch_open_button.focus_mode = Control.FOCUS_ALL
	_watch_open_button.tooltip_text = "Open the Flockwatch page that can change this watched condition."
	_watch_open_button.pressed.connect(_on_watch_open_pressed)
	watch_actions.add_child(_watch_open_button)

	_ledger_toggle = FlockwatchDisclosureToggleScript.new()
	_ledger_toggle.name = "EconomicBriefingLedgerToggle"
	_ledger_toggle.disclosure_changed.connect(
		func(_expanded: bool) -> void: presentation_context_changed.emit()
	)
	summary_rows.add_child(_ledger_toggle)
	_ledger_details = VBoxContainer.new()
	_ledger_details.name = "EconomicBriefingLedgerDetails"
	_ledger_details.add_theme_constant_override("separation", 4)
	summary_rows.add_child(_ledger_details)

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
		if label != _headline:
			_ledger_details.add_child(label)
	_watch = _label("MANAGEMENT WATCH / awaiting filed priority", 12, COLOR_TEAL)
	_watch.name = "EconomicBriefingWatch"
	_ledger_details.add_child(_watch)
	_ledger_toggle.configure(
		"NUMBERS",
		"",
		[_ledger_details],
		false,
	)

	_details_toggle = FlockwatchDisclosureToggleScript.new()
	_details_toggle.name = "EconomicBriefingDetailsToggle"
	_details_toggle.disclosure_changed.connect(
		func(_expanded: bool) -> void: presentation_context_changed.emit()
	)
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
		"PLAN",
		"",
		[_history, _resources, _strategies, _recovery],
		false,
	)


func _refresh() -> void:
	if _briefing.is_empty():
		_headline.text = "AWAITING AUTHORITATIVE LEDGER"
		_free_cash_glance.text = "FREE\n--"
		_margin_glance.text = "MARGIN\n--"
		_break_even_glance.text = "TO GO\n--"
		_watch_glance.text = "! AWAITING PRIORITY"
		_cash.text = "CASH / awaiting projection"
		_costs.text = "COSTS / awaiting projection"
		_market.text = "MARKET / awaiting calendar"
		_bottleneck.text = "BOTTLENECK / awaiting workflow"
		_trend.text = "TREND / awaiting first close"
		_watch.text = "MANAGEMENT WATCH / awaiting filed priority"
		_watch_selector.clear()
		_watch_selector.disabled = true
		_watch_open_button.disabled = true
		_selected_watch.clear()
		_history.text = "CLOSE HISTORY / no filed shifts"
		_resources.text = "RESOURCE MAP / awaiting projection"
		_strategies.text = "STRATEGY FILE / awaiting projection"
		_recovery.text = "RECOVERY FILE / awaiting projection"
		return

	var status_id := StringName(String(_briefing.get("status_id", &"stable")))
	_headline.text = "%s  /  DAY %d" % [
		String(_briefing.get("status_label", "OPERATING ROOM")),
		int(_briefing.get("day", 1)),
	]
	_headline.tooltip_text = "Status and values are filed from the current authoritative ledger."
	_headline.add_theme_color_override(
		"font_color",
		COLOR_DANGER if status_id == &"critical" else (
			COLOR_WARNING if status_id == &"tight" else COLOR_GOLD
		),
	)

	var cash := _briefing.get("cash", {}) as Dictionary
	var spendable_fund_cents := int(cash.get("spendable_fund_cents", 0))
	var secured_margin_cents := int(cash.get("secured_operating_margin_cents", 0))
	var break_even_remaining_cents := int(cash.get("break_even_remaining_cents", 0))
	_free_cash_glance.text = "FREE\n%s" % _money(spendable_fund_cents)
	_margin_glance.text = "MARGIN\n%s" % _signed_money(secured_margin_cents)
	_break_even_glance.text = "TO GO\n%s" % _money(break_even_remaining_cents)
	_free_cash_glance.tooltip_text = (
		"Spendable fund after protected reserves: %s." % _money(spendable_fund_cents)
	)
	_margin_glance.tooltip_text = (
		"Secured income minus today's full filed operating cost: %s."
		% _signed_money(secured_margin_cents)
	)
	_break_even_glance.tooltip_text = (
		"Additional secured income needed to cover today's filed cost: %s."
		% _money(break_even_remaining_cents)
	)
	_margin_glance.add_theme_color_override(
		"font_color",
		COLOR_DANGER if secured_margin_cents < 0 else COLOR_TEAL,
	)
	_cash.text = (
		"CASH / FUND %s / RESERVED %s\n"
		+ "FREE / %s\n"
		+ "RUN RATE / SECURED %s\n"
		+ "FILED COST / %s\n"
		+ "MARGIN / %s\n"
		+ "BREAK-EVEN LEFT / %s"
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
		"COSTS / FEED %s / HENS %s\n"
		+ "PAYROLL / ROOSTERS %s / FELLOWS %s\n"
		+ "OVERHEAD / PERCHES %s / FACILITIES %s\n"
		+ "CAMPUS / %s / PORTFOLIO %s"
	) % [
		_money(int(costs.get("feed_cents", 0))),
		_money(int(costs.get("hen_payroll_cents", 0))),
		_money(int(costs.get("supervisor_payroll_cents", 0))),
		_money(int(costs.get("fellow_payroll_cents", 0))),
		_money(int(costs.get("expanded_perches_cents", 0))),
		_money(int(costs.get("facility_maintenance_cents", 0))),
		_money(int(costs.get("campus_services_cents", 0))),
		_money(int(costs.get("portfolio_operations_cents", 0))),
	]

	var market := _briefing.get("market", {}) as Dictionary
	var current_market := market.get("current", {}) as Dictionary
	var next_market := market.get("next", {}) as Dictionary
	var market_cause := _wrap_ledger_value(
		String(market.get(
			"current_cause",
			current_market.get("summary", "Farm Mutual's filed calendar sets demand."),
		)),
		30,
	)
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
		+ "NOW / %s %s\n"
		+ "FEED / %s PER SCOOP\n"
		+ "NEXT DAY %d / %s\n"
		+ "LEAD / %s %s\n"
		+ "FEED / %s"
	) % [
		String(current_market.get("short_label", "BASELINE BOOK")),
		int(market.get("current_days_remaining", 0)),
		"" if int(market.get("current_days_remaining", 0)) == 1 else "S",
		String(market.get("forecast_certainty", "FILED CALENDAR")),
		market_cause,
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
	_refresh_management_watch()
	_refresh_history()
	_refresh_resources()
	_refresh_strategies()
	_refresh_recovery()
	var recovery_count := (_briefing.get("recovery_actions", []) as Array).size()
	_details_toggle.set_summary(
		"%d ISSUE%s" % [
			bottlenecks.size(),
			"" if bottlenecks.size() == 1 else "S",
		],
		"Economic plan includes %d bottleneck%s and %d recovery path%s. " % [
			bottlenecks.size(),
			"" if bottlenecks.size() == 1 else "s",
			recovery_count,
			"" if recovery_count == 1 else "s",
		]
		+ "Expand for close history, resource limits, strategies, and recovery actions.",
	)
	_ledger_toggle.set_summary(
		"",
		"Ledger includes exact cash, costs, market terms, primary bottleneck, "
		+ "five-close trend, and management watch.",
	)


func _refresh_management_watch() -> void:
	var watch_projection := _briefing.get("management_watch", {}) as Dictionary
	var catalog := watch_projection.get("catalog", []) as Array
	var selected_id := StringName(watch_projection.get("selected_id", &"auto"))
	var selected_value: Variant = watch_projection.get("selected", {})
	_selected_watch = (
		(selected_value as Dictionary).duplicate(true)
		if selected_value is Dictionary else
		{}
	)
	_watch_selector.clear()
	var selected_index := 0
	for row_value: Variant in catalog:
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		var watch_id := StringName(row.get("id", &""))
		_watch_selector.add_item(
			"AUTO: TOP PRIORITY"
			if watch_id == &"auto" else
			String(row.get("label", watch_id)).to_upper()
		)
		var item_index := _watch_selector.item_count - 1
		_watch_selector.set_item_metadata(item_index, String(watch_id))
		if watch_id == selected_id:
			selected_index = item_index
	if _selected_watch.is_empty() and not catalog.is_empty() and catalog[0] is Dictionary:
		_selected_watch = (catalog[0] as Dictionary).duplicate(true)
	_watch_selector.disabled = _watch_selector.item_count <= 0
	if not _watch_selector.disabled:
		_watch_selector.select(selected_index)
	var status_id := StringName(_selected_watch.get("status_id", &"clear"))
	var selected_watch_id := StringName(_selected_watch.get("id", &""))
	_watch_glance.text = (
		"! %s" % String(_selected_watch.get(
			"status_label",
			"CURRENT PRIORITY",
		)).to_upper()
		if selected_watch_id == &"auto" else
		"! %s\n%s  ->  %s" % [
			String(_selected_watch.get("label", "PRIMARY CONSTRAINT")).to_upper(),
			String(_selected_watch.get("current_label", "AWAITING VALUE")).to_upper(),
			String(_selected_watch.get("target_label", "AWAITING TARGET")).to_upper(),
		]
	)
	_watch_glance.add_theme_color_override(
		"font_color",
		COLOR_WARNING if status_id in [&"attention", &"building"] else COLOR_TEAL,
	)
	_watch_glance.tooltip_text = "%s\nNEXT: %s" % [
		String(_selected_watch.get("why", "No causal filing is available.")),
		String(_selected_watch.get("action", "Review the current operating file.")),
	]
	_watch.text = (
		"MANAGEMENT WATCH / %s / %s\n"
		+ "NOW %s / TARGET %s\n"
		+ "WHY / %s\n"
		+ "ACT / %s"
	) % [
		String(_selected_watch.get("label", "PRIMARY CONSTRAINT")).to_upper(),
		String(_selected_watch.get("status_label", "FILED")).to_upper(),
		String(_selected_watch.get("current_label", "AWAITING VALUE")),
		String(_selected_watch.get("target_label", "AWAITING TARGET")),
		String(_selected_watch.get("why", "No causal filing is available.")),
		String(_selected_watch.get("action", "Review the current operating file.")),
	]
	_watch.add_theme_color_override(
		"font_color",
		COLOR_WARNING if status_id in [&"attention", &"building"] else COLOR_TEAL,
	)
	var destination := StringName(_selected_watch.get("page_id", &""))
	_watch_open_button.disabled = destination == &""
	_watch_open_button.text = (
		"OPEN %s" % _page_short_label(destination)
		if destination != &"" else
		"NO FILE"
	)
	_watch_open_button.set_meta(&"page_id", destination)


func _on_watch_selected(index: int) -> void:
	if index < 0 or index >= _watch_selector.item_count:
		return
	var watch_id := StringName(String(_watch_selector.get_item_metadata(index)))
	if watch_id == &"":
		return
	economic_watch_requested.emit(watch_id)


func _on_watch_open_pressed() -> void:
	var page_id := StringName(_watch_open_button.get_meta(&"page_id", &""))
	if page_id != &"":
		economic_watch_open_requested.emit(page_id)


func _page_short_label(page_id: StringName) -> String:
	match page_id:
		&"operations":
			return "OPS"
		&"governance_records":
			return "RECORDS"
		&"capital":
			return "CAPITAL"
		&"flock":
			return "FLOCK"
		_:
			return "TODAY"


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


func _metric_chip(
	parent: GridContainer,
	node_name: String,
	copy: String,
	color: Color,
) -> Label:
	var panel := PanelContainer.new()
	panel.name = "%sPanel" % node_name
	panel.custom_minimum_size.y = 48.0
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("13222a"), Color("3c555d")),
	)
	parent.add_child(panel)
	var label := _label(copy, 11, color)
	label.name = node_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(label)
	return label


func _wrap_ledger_value(copy: String, maximum_characters: int) -> String:
	var words := copy.strip_edges().split(" ", false)
	var lines: Array[String] = []
	var current := ""
	for word_value: String in words:
		var candidate := word_value if current.is_empty() else "%s %s" % [current, word_value]
		if current.is_empty() or candidate.length() <= maximum_characters:
			current = candidate
			continue
		lines.append(current)
		current = word_value
	if not current.is_empty():
		lines.append(current)
	return "\n        ".join(lines)


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
