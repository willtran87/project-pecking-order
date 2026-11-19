class_name OfficeReviewPresenter
extends RefCounted

## Farmer review, senior-quarter and end-of-shift presentation surfaces.
## Holds no state of its own: every read and write goes through the owning
## Office so behaviour is identical to the original in-class methods.

var office: Office


func _init(owner_node: Office) -> void:
	office = owner_node

func _review_bottleneck_readout() -> String:
	return office._web_bridge._review_bottleneck_readout()


func _build_day_review_panel() -> void:
	office._environment_builder._build_day_review_panel()


func _apply_physical_review_layout() -> void:
	if office._day_review_panel == null:
		return
	var compact := office._compact_physical_hud
	office._day_review_panel.offset_left = -500.0 if compact else -370.0
	office._day_review_panel.offset_right = 500.0 if compact else 370.0
	var interface_scale := float(office._player_preferences.get("ui_scale", 1.0))
	for node_value: Node in office._day_review_panel.find_children("*", "Control", true, false):
		var control := node_value as Control
		if control == null:
			continue
		var button := control as Button
		if control.has_theme_font_size_override("font_size") or button != null:
			if not control.has_meta(&"review_had_explicit_font"):
				control.set_meta(&"review_had_explicit_font", control.has_theme_font_size_override("font_size"))
			if not control.has_meta(&"preference_base_font_size"):
				control.set_meta(
					&"preference_base_font_size",
					roundi(control.get_theme_font_size("font_size") / maxf(1.0, interface_scale)),
				)
			var base_font := int(control.get_meta(&"preference_base_font_size", 14))
			if not compact and not bool(control.get_meta(&"review_had_explicit_font")):
				control.remove_theme_font_size_override("font_size")
			else:
				control.add_theme_font_size_override(
					"font_size", roundi(base_font * interface_scale * (1.5 if compact else 1.0)),
				)
			control.update_minimum_size()
		if button != null:
			if not button.has_meta(&"review_base_minimum"):
				button.set_meta(&"review_base_minimum", button.custom_minimum_size)
			var base_minimum: Vector2 = button.get_meta(&"review_base_minimum")
			button.custom_minimum_size = Vector2(
				base_minimum.x, maxf(72.0, base_minimum.y) if compact else base_minimum.y,
			)
	if office._review_details_scroll != null:
		office._review_details_scroll.custom_minimum_size.y = 112.0 if compact else 184.0
	office._set_review_details_expanded(office._review_details_expanded)


func _set_review_details_expanded(expanded: bool) -> void:
	office._review_details_expanded = expanded
	for node_name in ["ReviewRequisitionsButton", "ReviewCapitalBlueprintButton"]:
		var secondary := office.find_child(node_name, true, false) as Button
		if secondary != null:
			secondary.visible = expanded
	if office._review_details_scroll != null:
		office._review_details_scroll.visible = office._review_details_expanded
	if office._review_details_toggle != null:
		office._review_details_toggle.text = (
			"HIDE DETAILS"
			if office._review_details_expanded else
			"DETAILS"
		)
	if office._day_review_panel != null:
		var interface_scale := float(office._player_preferences.get("ui_scale", 1.0))
		var scale_height_allowance := roundi(maxf(0.0, interface_scale - 1.0) * 50.0)
		var half_height := (
			(350 if office._review_details_expanded else 305) + scale_height_allowance
			if office._compact_physical_hud else
			(310 if office._review_details_expanded else 255) + scale_height_allowance
		)
		var bounded_half_height := minf(float(half_height), office.get_viewport().get_visible_rect().size.y * 0.5 - 16.0)
		office._day_review_panel.offset_top = -bounded_half_height
		office._day_review_panel.offset_bottom = bounded_half_height


func _routing_review_receipt(
	report: Dictionary,
	previous_report: Dictionary = {},
) -> Dictionary:
	var filed_value: Variant = report.get("routing_review", {})
	if filed_value is Dictionary and not (filed_value as Dictionary).is_empty():
		return (filed_value as Dictionary).duplicate(true)
	var momentum_value: Variant = report.get("routing_momentum", {})
	if not momentum_value is Dictionary:
		return {}
	var momentum := momentum_value as Dictionary
	var best_chain := maxi(0, int(momentum.get("best_chain", 0)))
	if best_chain <= 0:
		return {}

	var previous_best := 0
	var previous_review_value: Variant = previous_report.get("routing_review", {})
	if previous_review_value is Dictionary and not (previous_review_value as Dictionary).is_empty():
		previous_best = maxi(0, int((previous_review_value as Dictionary).get(
			"best_chain",
			0,
		)))
	else:
		var previous_momentum_value: Variant = previous_report.get("routing_momentum", {})
		if previous_momentum_value is Dictionary and not (
			previous_momentum_value as Dictionary
		).is_empty():
			previous_best = maxi(0, int((previous_momentum_value as Dictionary).get(
				"best_chain",
				0,
			)))
		elif int(report.get("day", 1)) > 1:
			# Legacy reports predate this receipt. Preserve their current record but do
			# not falsely celebrate it as newly earned after an upgrade.
			previous_best = best_chain
	previous_best = mini(previous_best, best_chain)
	var record_set := best_chain > previous_best
	var next_record := (
		DepartmentSimulation.ROUTING_MOMENTUM_CELEBRATION_MILESTONE
		if best_chain < DepartmentSimulation.ROUTING_MOMENTUM_CELEBRATION_MILESTONE else
		maxi(
			15,
			(
				floori(float(best_chain) / DepartmentSimulation.ROUTING_MOMENTUM_MASTERY_INTERVAL)
				+ 1
			) * DepartmentSimulation.ROUTING_MOMENTUM_MASTERY_INTERVAL,
		)
	)
	var target_label := (
		"TEAM LIFT"
		if best_chain < DepartmentSimulation.ROUTING_MOMENTUM_CELEBRATION_MILESTONE else
		"CHASE"
	)
	var short_label := "%sFIT RECORD  x%d   /   %s  x%d" % [
		"NEW " if record_set else "BEST ",
		best_chain,
		target_label,
		next_record,
	]
	var accessible_text := "%s best-fit routing record: %d consecutive recommended tray assignments. %s: %d." % [
		"New" if record_set else "Current",
		best_chain,
		"Next Team Lift" if target_label == "TEAM LIFT" else "Next mastery record",
		next_record,
	]
	return {
		"version": 1,
		"best_chain": best_chain,
		"previous_best_chain": previous_best,
		"record_set": record_set,
		"next_record": next_record,
		"target_kind": "team_lift" if target_label == "TEAM LIFT" else "record",
		"short_label": short_label,
		"accessible_text": accessible_text,
	}


func _show_farmer_review(report: Dictionary, animate: bool = true) -> void:
	if office._audio_feedback != null:
		if animate:
			office._audio_feedback.play_review()
	office._set_flockwatch_open(false)
	var met_quota := bool(report.get("met_quota", false))
	var eggs := int(report.get("eggs", 0))
	var quota := int(report.get("quota", 0))
	var cracked := int(report.get("cracked", 0))
	var golden := int(report.get("golden", 0))
	var quota_bonus := int(report.get("quota_bonus_cents", 0))
	var quality_bonus := int(report.get("quality_bonus_cents", 0))
	var market_contract := report.get("market_contract", {}) as Dictionary
	var market_contract_premium := int(report.get(
		"market_contract_premium_cents",
		market_contract.get("premium_cents", 0),
	))
	var market_contract_service_bonus := int(report.get(
		"market_contract_service_coop_bonus_cents",
		market_contract.get(
			"service_coop_bonus_cents",
			market_contract.get("accreditation_bonus_cents", 0),
		),
	))
	var market_contract_base_premium := int(report.get(
		"market_contract_base_premium_cents",
		market_contract.get(
			"authored_base_premium_cents",
			market_contract.get(
				"base_premium_cents",
				maxi(0, market_contract_premium - market_contract_service_bonus),
			),
		),
	))
	var market_contract_season_premium_delta := int(report.get(
		"market_contract_season_premium_delta_cents",
		market_contract.get("season_premium_delta_cents", 0),
	))
	var market_contract_clause_premium_delta := int(report.get(
		"market_contract_clause_premium_delta_cents",
		market_contract.get("clause_premium_delta_cents", 0),
	))
	# Schema-v14 settlements freeze the signed season and rider adjustments even
	# when either adjustment is zero. Older settlement reports do not carry those
	# fields, so keep their compact Base + Coop receipt instead of inventing terms
	# that were never part of the signed binder.
	var market_contract_has_signed_terms := (
		report.has("market_contract_season_premium_delta_cents")
		or report.has("market_contract_clause_premium_delta_cents")
		or market_contract.has("season_premium_delta_cents")
		or market_contract.has("clause_premium_delta_cents")
		or market_contract.has("season_id")
		or market_contract.has("clause_id")
	)
	var market_contract_breach := int(report.get(
		"market_contract_breach_cents",
		market_contract.get("breach_cents", 0),
	))
	var gross_credit := int(report.get("credited_cents", quota_bonus + quality_bonus))
	# Successful Farm Mutual premiums already enter credited_cents at settlement;
	# remove that closing premium before naming the flock's base production. A
	# breach is not negative production and therefore remains a separate charge.
	var production_credit := maxi(
		0,
		gross_credit - quota_bonus - quality_bonus - market_contract_premium,
	)
	var feed_cost := int(report.get("feed_cost_cents", 0))
	var payroll_cost := int(report.get("payroll_cents", 0))
	var hen_payroll_cost := int(report.get("hen_payroll_cents", payroll_cost))
	var fellow_payroll_cost := int(report.get("fellow_payroll_cents", 0))
	var supervisor_payroll_cost := int(report.get(
		"supervisor_payroll_cents",
		maxi(0, payroll_cost - hen_payroll_cost - fellow_payroll_cost),
	))
	var facility_cost := int(report.get("facility_cost_cents", 0))
	var facility_capacity_cost := int(report.get("facility_expansion_cost_cents", facility_cost))
	var facility_maintenance := int(report.get("facility_maintenance_cents", maxi(0, facility_cost - facility_capacity_cost)))
	var packing_contract := report.get("packing_contract", {}) as Dictionary
	var packing_level := int(packing_contract.get("level", 0))
	var packing_cartons := int(report.get(
		"packing_cartons_today",
		packing_contract.get("cartons_today", 0),
	))
	var packing_value_bonus := int(report.get(
		"packing_value_bonus_cents",
		packing_contract.get("value_bonus_today_cents", 0),
	))
	var packing_carton_bonus := int(report.get(
		"packing_carton_bonus_cents",
		packing_contract.get("carton_bonus_today_cents", 0),
	))
	var operating_cost := int(report.get("operating_cost_cents", feed_cost + payroll_cost + facility_cost))
	# Gross credit already contains a successful premium exactly once. Failed
	# contracts debit Feed Fund outside operating obligations, so include that
	# separate charge once when presenting the shift's reconciled net.
	var operating_net := gross_credit - operating_cost - market_contract_breach
	var closing_fund := int(report.get("closing_fund_cents", office._simulation.revenue_cents))
	var closing_arrears := int(report.get("wage_arrears_cents", 0))
	var treasury_receipt := report.get("farm_treasury_receipt", {}) as Dictionary
	var treasury_snapshot := report.get("farm_treasury", {}) as Dictionary
	var operating_net_text := "%s$%.2f" % [
		("+" if operating_net >= 0 else "-"),
		absf(float(operating_net)) / 100.0,
	]
	var completed_directive := report.get("directive", {}) as Dictionary
	var directive_name := String(completed_directive.get("short_name", "UNFILED"))
	var incident_count := int(report.get("incidents_resolved", 0))
	var incident_summaries: Array[String] = []
	for response_value in report.get("incident_responses", []):
		if not response_value is Dictionary:
			continue
		var response_summary := String((response_value as Dictionary).get("summary", ""))
		if not response_summary.is_empty():
			incident_summaries.append(response_summary)
	var incident_review := (
		"; ".join(incident_summaries)
		if not incident_summaries.is_empty() else
		"%d resolved" % incident_count
	)
	var lane_processed := report.get("lane_processed", {}) as Dictionary
	var overdue_files := int(report.get("overdue_claims", 0))
	var rework_files := int(report.get("rework_waiting", 0)) + int(report.get("rework_due_next_shift", 0))
	var outstanding_files := int(report.get("claims_outstanding", 0))
	var claim_capacity := int(report.get("claim_capacity", 18))
	var intake_rejections := int(report.get("intake_rejections_today", report.get("intake_rejections", 0)))
	var intake_missed_value := int(report.get("intake_missed_value_today_cents", report.get("intake_missed_value_cents", 0)))
	var personnel_action := report.get("personnel_action", {}) as Dictionary
	var personnel_actions := report.get("personnel_actions", []) as Array
	var closing_order := report.get("pecking_order", []) as Array
	var closing_leader: Dictionary = (
		closing_order[0] as Dictionary if not closing_order.is_empty() else {}
	)
	var personnel_line := "NOT FILED"
	if not personnel_actions.is_empty():
		var filed_actions: Array[String] = []
		for action_value in personnel_actions:
			var filed_action := action_value as Dictionary
			filed_actions.append("%s / %s" % [
				String(filed_action.get("worker_name", "HEN")).to_upper(),
				String(filed_action.get("action_name", "CHECK-IN")).to_upper(),
			])
		personnel_line = "; ".join(filed_actions)
	elif not personnel_action.is_empty():
		personnel_line = "%s / %s" % [
			String(personnel_action.get("worker_name", "HEN")).to_upper(),
			String(personnel_action.get("action_name", "CHECK-IN")).to_upper(),
		]
	office._review_title.text = "%s · DAY %d" % ["QUOTA MET" if met_quota else "SHIFT FILED", int(report.get("day", 1))]
	office._set_review_details_expanded(false)
	if office._review_eggs_value != null:
		office._review_eggs_value.text = "%s  %d / %d" % [
			"OK" if met_quota else "!",
			eggs,
			quota,
		]
		office._review_eggs_value.add_theme_color_override(
			"font_color",
			Color("8fd9b7") if met_quota else Color("f3aa80"),
		)
	if office._review_net_value != null:
		office._review_net_value.text = operating_net_text
		office._review_net_value.add_theme_color_override(
			"font_color",
			Color("8fd9b7") if operating_net >= 0 else Color("f3aa80"),
		)
	if office._review_fund_value != null:
		office._review_fund_value.text = "$%.2f" % (float(closing_fund) / 100.0)
	if office._review_next_value != null:
		office._review_next_value.text = "%d EGGS" % int(report.get("next_quota", quota))
	office._apply_three_card_review(report)
	if office._review_summary != null:
		var shell_summary := (
			"OK  CLEAN SHELLS   /   * %d GOLDEN" % golden
			if cracked == 0 else
			"! %d CRACKED   /   * %d GOLDEN" % [cracked, golden]
		)
		var net_equation := "CREDIT $%.2f - COSTS $%.2f" % [
			float(gross_credit) / 100.0,
			float(operating_cost) / 100.0,
		]
		if market_contract_breach > 0:
			net_equation += " - CONTRACT $%.2f" % (float(market_contract_breach) / 100.0)
		net_equation += " = %s NET" % operating_net_text
		var routing_review := report.get("routing_review", {}) as Dictionary
		var routing_short := String(routing_review.get("short_label", "")).strip_edges()
		var loss_cause := ""
		if operating_net < 0:
			var largest_cost := 0
			var largest_name := ""
			var next_action := ""
			for cost_entry in [
				{"present": report.has("feed_cost_cents"), "cents": feed_cost, "name": "FEED", "next": "ROUTE MORE EGGS"},
				{"present": report.has("payroll_cents"), "cents": payroll_cost, "name": "PAYROLL", "next": "USE CURRENT DESKS FULLY"},
				{"present": report.has("facility_cost_cents"), "cents": facility_cost, "name": "FACILITIES", "next": "USE INSTALLED CAPACITY"},
				{"present": market_contract_breach > 0, "cents": market_contract_breach, "name": "CONTRACT PENALTY", "next": "REVIEW CONTRACT TERMS"},
			]:
				if bool(cost_entry["present"]) and int(cost_entry["cents"]) > largest_cost:
					largest_cost = int(cost_entry["cents"])
					largest_name = String(cost_entry["name"])
					next_action = String(cost_entry["next"])
			if largest_cost > 0:
				loss_cause = "BIGGEST COST: %s $%.2f · NEXT: %s" % [
					largest_name, float(largest_cost) / 100.0, next_action,
				]
		office._review_summary.text = (
			"%s\n%s" % [net_equation, loss_cause if not loss_cause.is_empty() else routing_short]
			if not loss_cause.is_empty() or not routing_short.is_empty() else
			net_equation
		)
		var routing_accessible := String(
			routing_review.get("accessible_text", "")
		).strip_edges()
		var summary_accessible := "%s. %s" % [net_equation, shell_summary]
		if not loss_cause.is_empty():
			summary_accessible += ". " + loss_cause
		if not routing_accessible.is_empty():
			summary_accessible += ". " + routing_accessible
		office._review_summary.set_meta("accessible_text", summary_accessible)
		office._review_summary.tooltip_text = summary_accessible
	office._review_results.text = "%s\n%d / %d eggs  ·  %d cracked  ·  %d golden\nPolicy: %s\nIncident files: %s\nCheck-in: %s  ·  avg trust %d  ·  avg grievance %d\nFiles: N%d  ·  P%d  ·  A%d  ·  %d overdue  ·  %d rework\nArchive: %d / %d live  ·  %d turned away  ·  est. $%.2f file value missed\nIncome: Production credit +$%.2f  ·  Quota bonus +$%.2f  ·  Quality bonus +$%.2f\nCosts: Feed -$%.2f  ·  Payroll -$%.2f  ·  Facilities -$%.2f\nNet operating %s  ·  Closing Feed Fund $%.2f  ·  Wage arrears $%.2f" % [
		("TARGET HARVESTED" if met_quota else "TARGET MISSED"),
		eggs, quota, cracked, golden,
		directive_name,
		incident_review,
		personnel_line,
		int(report.get("average_manager_trust", 0)),
		int(report.get("average_grievance", 0)),
		int(lane_processed.get(&"nest_damage", 0)),
		int(lane_processed.get(&"predator_loss", 0)),
		int(lane_processed.get(&"appeals", 0)),
		overdue_files,
		rework_files,
		outstanding_files,
		claim_capacity,
		intake_rejections,
		float(intake_missed_value) / 100.0,
		production_credit / 100.0, quota_bonus / 100.0, quality_bonus / 100.0,
		feed_cost / 100.0, payroll_cost / 100.0, facility_cost / 100.0,
		operating_net_text, closing_fund / 100.0, closing_arrears / 100.0,
	]
	office._review_results.text = office._review_results.text.replace("Check-in:", "Check-ins:")
	office._review_results.text = office._review_results.text.replace(
		"Payroll -$%.2f" % (payroll_cost / 100.0),
		"Payroll -$%.2f (hens $%.2f + roosters $%.2f + fellows $%.2f)" % [
			payroll_cost / 100.0,
			hen_payroll_cost / 100.0,
			supervisor_payroll_cost / 100.0,
			fellow_payroll_cost / 100.0,
		],
	)
	if not treasury_receipt.is_empty():
		var treasury_liabilities := int(treasury_snapshot.get(
			"total_liabilities_cents",
			int(treasury_receipt.get("closing_credit_principal_cents", 0))
			+ int(treasury_receipt.get("closing_vendor_arrears_cents", 0))
			+ int(treasury_receipt.get("closing_interest_arrears_cents", 0)),
		))
		var treasury_line := (
			"\nFarm Treasury: opening $%.2f + inflow $%.2f  ·  vendors due $%.2f / paid $%.2f"
			+ "  ·  interest $%.2f  ·  line draw $%.2f / principal repaid $%.2f"
			+ "  ·  payroll paid $%.2f / promised $%.2f  ·  closing liabilities $%.2f%s"
		) % [
			float(int(treasury_receipt.get("opening_cash_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("inflow_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("total_vendor_due_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("vendor_paid_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("interest_charged_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("credit_draw_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("principal_repaid_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("labor_paid_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("labor_unpaid_cents", 0))) / 100.0,
			float(treasury_liabilities) / 100.0,
			"  ·  CAPITAL FROZEN" if bool(treasury_snapshot.get("capital_frozen", false)) else "",
		]
		office._review_results.text = office._review_results.text.replace("\nCosts:", treasury_line + "\nCosts:")
	var completed_operations := report.get("operations", {}) as Dictionary
	if not completed_operations.is_empty():
		var completed_supervision := completed_operations.get("supervision", {}) as Dictionary
		var completed_automation := completed_operations.get("automation", {}) as Dictionary
		var rooster_level := int(completed_operations.get("rooster_office_level", 0))
		var it_level := int(completed_operations.get("it_coop_level", 0))
		if rooster_level > 0 or it_level > 0:
			var operations_line := (
				"\nOperations: Rooster L%d / %d of %d check-ins filed / surveillance +%.2f stress per hen; "
				+ "IT L%d / AUTO %d%% / compliance exposure -%.2f"
			) % [
				rooster_level,
				int(completed_supervision.get("actions_used", 0)),
				int(completed_supervision.get("action_limit", 1)),
				float(completed_supervision.get("surveillance_stress_millipoints", 0)) / 1000.0,
				it_level,
				roundi(float(completed_automation.get("work_basis_points", 10_000)) / 100.0),
				float(completed_automation.get("compliance_exposure_millipoints", 0)) / 1000.0,
			]
			office._review_results.text = office._review_results.text.replace("\nCosts:", operations_line + "\nCosts:")
	var completed_flock_relations := report.get("flock_relations", {}) as Dictionary
	var flock_relations_filings := report.get("flock_relations_filings", []) as Array
	var flock_relations_carry := report.get("flock_relations_carry_effects", []) as Array
	var flock_relations_level := int(completed_flock_relations.get("level", 0))
	if flock_relations_level > 0:
		var relations_line := (
			"\nFlock Relations L%d: %d / %d open cases  ·  %d / %d review authorizations used"
		) % [
			flock_relations_level,
			int(completed_flock_relations.get("open_case_count", 0)),
			int(completed_flock_relations.get("capacity", flock_relations_level)),
			int(completed_flock_relations.get("resolutions_used_today", 0)),
			int(completed_flock_relations.get("resolution_limit", flock_relations_level)),
		]
		if not flock_relations_filings.is_empty():
			var filed_case := flock_relations_filings[0] as Dictionary
			relations_line += "  ·  NEW %s / %s / severity %d" % [
				String(filed_case.get("docket_id", "CASE FILE")).to_upper(),
				String(filed_case.get("worker_name", "HEN")).to_upper(),
				int(filed_case.get("severity", 1)),
			]
		if not flock_relations_carry.is_empty():
			relations_line += "  ·  %d unresolved %s carried" % [
				flock_relations_carry.size(),
				"case" if flock_relations_carry.size() == 1 else "cases",
			]
		office._review_results.text = office._review_results.text.replace("\nCosts:", relations_line + "\nCosts:")
	var completed_provisions := report.get("feed_procurement", {}) as Dictionary
	var provisions_level := int(completed_provisions.get("level", 0))
	var provisions_prepaid := int(report.get("feed_procurement_spend_cents", 0))
	var provisions_spoiled := int(completed_provisions.get("spoiled_today_scoops", 0))
	if provisions_level > 0 or provisions_prepaid > 0 or provisions_spoiled > 0:
		var provisions_line := (
			"\nFlock Provisions L%d: demand %d scoops  /  stored %d + spot %d  /  closing stock %d / %d  /  prepaid $%.2f  /  spoilage %d"
		) % [
			provisions_level,
			int(completed_provisions.get("consumed_today_scoops", 0)),
			int(completed_provisions.get("consumed_inventory_today_scoops", 0)),
			int(completed_provisions.get("consumed_spot_today_scoops", 0)),
			int(completed_provisions.get("stock_scoops", 0)),
			int(completed_provisions.get("capacity_scoops", 0)),
			float(provisions_prepaid) / 100.0,
			provisions_spoiled,
		]
		office._review_results.text = office._review_results.text.replace(
			"\nCosts:",
			provisions_line + "\nCosts:",
		)
	if packing_level > 0:
		var packing_line := (
			"\nPacking Annex L%d: %d carton%s  ·  value lift +$%.2f  ·  carton contracts +$%.2f (included in production)"
			% [
				packing_level,
				packing_cartons,
				"" if packing_cartons == 1 else "s",
				float(packing_value_bonus) / 100.0,
				float(packing_carton_bonus) / 100.0,
			]
		)
		office._review_results.text = office._review_results.text.replace("\nCosts:", packing_line + "\nCosts:")
	if not market_contract.is_empty() or market_contract_premium > 0 or market_contract_breach > 0:
		var contract_name := String(
			market_contract.get("short_name", market_contract.get("name", "FARM MUTUAL BINDER"))
		).to_upper()
		var contract_status := String(market_contract.get(
			"status",
			"fulfilled" if market_contract_premium > 0 else "breached",
		)).to_upper()
		var timely_completed := int(market_contract.get("timely_sound_completed", 0))
		var required_completed := int(market_contract.get("required_completed", 0))
		var season_delta_label := "%s$%.2f" % [
			"+" if market_contract_season_premium_delta >= 0 else "-",
			absf(float(market_contract_season_premium_delta)) / 100.0,
		]
		var clause_delta_label := "%s$%.2f" % [
			"+" if market_contract_clause_premium_delta >= 0 else "-",
			absf(float(market_contract_clause_premium_delta)) / 100.0,
		]
		var settlement_label := "Breach -$%.2f" % (float(market_contract_breach) / 100.0)
		if market_contract_premium > 0:
			if market_contract_has_signed_terms:
				settlement_label = "Authored +$%.2f  +  Season %s  +  Rider %s  +  Coop L%d +$%.2f  =  +$%.2f" % [
					float(market_contract_base_premium) / 100.0,
					season_delta_label,
					clause_delta_label,
					int(market_contract.get("service_coop_level_at_signing", 0)),
					float(market_contract_service_bonus) / 100.0,
					float(market_contract_premium) / 100.0,
				]
			else:
				settlement_label = "Base +$%.2f  +  Coop L%d +$%.2f  =  +$%.2f" % [
					float(market_contract_base_premium) / 100.0,
					int(market_contract.get("service_coop_level_at_signing", 0)),
					float(market_contract_service_bonus) / 100.0,
					float(market_contract_premium) / 100.0,
				]
		var contract_line := "\nFarm Mutual: %s %s  ·  %s" % [
			contract_name,
			contract_status,
			settlement_label,
		]
		if required_completed > 0:
			contract_line += "  ·  %d/%d clean on time" % [
				timely_completed,
				required_completed,
			]
		var standing_value: Variant = report.get(
			"market_accreditation",
			report.get(
				"farm_mutual_standing",
				report.get("market_contract_standing", {}),
			),
		)
		if standing_value is Dictionary and not (standing_value as Dictionary).is_empty():
			var standing := standing_value as Dictionary
			contract_line += "  ·  %s standing %d" % [
				String(standing.get(
					"rank_label",
					standing.get("rank_name", standing.get("rank", "UNLISTED")),
				)).to_upper(),
				int(standing.get("points", standing.get("score", 0))),
			]
			var clean_streak := int(standing.get("clean_streak", 0))
			if clean_streak > 0:
				contract_line += "  ·  %d clean binder streak" % clean_streak
		office._review_results.text = office._review_results.text.replace(
			"\nCosts:",
			contract_line + "\nCosts:",
		)
	var newly_unlocked_facilities := report.get("new_facility_unlocks", []) as Array
	if not newly_unlocked_facilities.is_empty():
		var unlock_names: Array[String] = []
		for unlock_value in newly_unlocked_facilities:
			var unlock := unlock_value as Dictionary
			unlock_names.append(String(unlock.get("name", "NEW CAPITAL FACILITY")))
		office._review_results.text = office._review_results.text.replace(
			"\nCosts:",
			"\nCAPITAL FILE UNLOCKED: %s  ·  Resolve closing credit, then open Capital Expansions.\nCosts:"
			% ", ".join(unlock_names),
		)
	office._review_results.tooltip_text = (
		"FACILITY COST BREAKDOWN\n"
		+ "Authorized perch overhead  $%.2f\n" % (facility_capacity_cost / 100.0)
		+ "Installed module maintenance  $%.2f\n\n" % (facility_maintenance / 100.0)
		+ "PAYROLL BREAKDOWN\n"
		+ "Hen wages  $%.2f\n" % (hen_payroll_cost / 100.0)
		+ "Rooster supervisor wages  $%.2f\n" % (supervisor_payroll_cost / 100.0)
		+ "Paid fellow wages  $%.2f\n\n" % (fellow_payroll_cost / 100.0)
		+ "Net operating uses accrued feed, payroll, and facility obligations. Unpaid payroll remains visible as arrears."
		+ (
			"\n\nFARM TREASURY\nThe filed receipt conserves opening cash, intrashift inflows, vendor payments, interest, labor payments, debt service, and closing cash exactly. The revolving line may cover vendors and interest, but never wages."
			if not treasury_receipt.is_empty() else
			""
		)
		+ "\n\nINTAKE CAPACITY\nTurned-away file value is an opportunity estimate only. It never enters the Feed Fund. More archive space can retain more work, but it can also increase overdue exposure."
		+ (
			"\n\nPACKING CONTRACT\nThe percentage lift and six-good-egg carton settlement are already included in Production credit."
			if packing_level > 0 else
			""
		)
		+ (
			"\n\nFARM MUTUAL SETTLEMENT\nBase premium and the Service Coop accreditation bonus are itemized above, then enter gross credit exactly once as the displayed total. A breach earns neither and is charged once against the Feed Fund. Closing Feed Fund remains the authoritative settled balance."
			if not market_contract.is_empty() or market_contract_premium > 0 or market_contract_breach > 0 else
			""
		)
		+ (
			"\n\nFLOCK RELATIONS\nOpen Requisitions to inspect each named-hen case. Remedy, mediation, PIP, and arbitration terms come directly from the permanent case ledger. Every case left open carries obedience, unity, and grievance pressure into a later closing."
			if flock_relations_level > 0 else
			""
		)
		+ (
			"\n\nFLOCK PROVISIONS\nPrepaid orders leave the Feed Fund when authorized and enter stored inventory. The closing Feed cost is only today's automatic spot shortage, so prepaid grain is never charged a second time. Consumed inventory value and spoilage remain visible as working-capital receipts."
			if provisions_level > 0 or provisions_prepaid > 0 else
			""
		)
	)
	var flock_ledger_entries: Array[String] = []
	var flock_ledger_details: Array[String] = []
	var compact_receipt := report.get("flock_compact_receipt", {}) as Dictionary
	if not compact_receipt.is_empty():
		flock_ledger_entries.append("%s %s" % [
			String(compact_receipt.get("compact_name", "FLOCK COMPACT")).to_upper(),
			String(compact_receipt.get("status", "FILED")).to_upper(),
		])
		flock_ledger_details.append(String(compact_receipt.get("outcome", "Compact receipt filed.")))
	var completed_work_to_rule := report.get("work_to_rule", {}) as Dictionary
	if bool(completed_work_to_rule.get("completed", false)):
		flock_ledger_entries.append("WORK-TO-RULE COMPLETED")
		flock_ledger_details.append("The flock completed one shift of slower, shell-safe written procedure.")
	var next_compact := report.get("next_flock_compact", {}) as Dictionary
	if not next_compact.is_empty():
		flock_ledger_entries.append("%s BINDS DAY %d" % [
			String(next_compact.get("compact_name", "FLOCK COMPACT")).to_upper(),
			int(next_compact.get("effective_day", int(report.get("day", 1)) + 1)),
		])
		flock_ledger_details.append(String(next_compact.get("condition", "Tomorrow's ledger tests the promise.")))
	var next_work_to_rule := report.get("next_work_to_rule", {}) as Dictionary
	if bool(next_work_to_rule.get("active", false)) or bool(next_work_to_rule.get("scheduled", false)):
		flock_ledger_entries.append("WORK-TO-RULE FILED FOR DAY %d" % int(next_work_to_rule.get("day", 0)))
		flock_ledger_details.append("The flock will follow every written procedure: slower throughput, safer shells.")
	if not flock_ledger_entries.is_empty():
		office._review_results.text += "\nFlock ledger: %s" % "  ·  ".join(flock_ledger_entries)
		office._review_results.tooltip_text += "\n\n" + "\n".join(flock_ledger_details)
	var review_highlight := "OK  SHIFT FILED"
	if not flock_relations_filings.is_empty():
		var story_case := flock_relations_filings[0] as Dictionary
		review_highlight = "! CASE  ·  %s  /  %s" % [
			String(story_case.get("worker_name", "HEN")).to_upper(),
			String(story_case.get("title", "WORKPLACE CASE")).to_upper(),
		]
	elif provisions_spoiled > 0:
		review_highlight = "! %d FEED SCOOP%s EXPIRED" % [
			provisions_spoiled,
			"" if provisions_spoiled == 1 else "S",
		]
	elif not personnel_action.is_empty():
		review_highlight = "+  CHECK-IN  ·  %s" % personnel_line
	elif not closing_leader.is_empty():
		review_highlight = "*  %s LED  ·  %d EGGS  ·  +$%.2f" % [
			String(closing_leader.get("worker_name", "HEN")).to_upper(),
			int(closing_leader.get("eggs", 0)),
			float(int(closing_leader.get("credit_cents", 0))) / 100.0,
		]
	office._review_story.text = review_highlight
	# The accounting above remains available in Details. End on the hen's work.
	var named_contribution := report.get("hen_highlight", {}) as Dictionary
	if not named_contribution.is_empty():
		office._review_story.text = _review_hen_caption(named_contribution)
		office._review_story.tooltip_text = String(named_contribution.get("body", review_highlight))
		office._review_story.accessibility_name = "%s. %s" % [office._review_story.text, office._review_story.tooltip_text]
	office._review_story.set_meta("filed_highlight", review_highlight)
	office._review_remix_index = -1
	if office._review_remix_button != null:
		office._review_remix_button.text = "OTHER GOAL"
	if not personnel_action.is_empty():
		office._review_results.text += "\nPersonnel outcome: %s" % String(
			personnel_action.get("outcome", "Check-in filed.")
		)
	if not flock_relations_filings.is_empty():
		var detailed_case := flock_relations_filings[0] as Dictionary
		office._review_results.text += (
			"\nFlock Relations action: Open Staff / Cases to resolve %s's %s."
			% [
				String(detailed_case.get("worker_name", "hen")),
				String(detailed_case.get("title", "workplace case")).to_lower(),
			]
		)
	if provisions_spoiled > 0:
		office._review_results.text += (
			"\nFlock Provisions outcome: %d scoop%s expired."
			% [provisions_spoiled, "" if provisions_spoiled == 1 else "s"]
		)
	if office._begin_next_shift_button != null:
		var memo_kind := StringName(report.get("credit_memo_kind", &""))
		var memo_id := StringName(report.get("credit_memo_id", &""))
		office._begin_next_shift_button.text = (
			"REVIEW CREDIT  >" if office._review_has_pending_credit() else
			"CAREER REVIEW  >" if office._campaign_senior_roost else
			"FINAL REVIEW  >" if office._campaign_state != null and office._campaign_state.outcome != Office.CampaignStateScript.OUTCOME_IN_PROGRESS else
			"PLAN NEXT SHIFT  >"
		)
		office._begin_next_shift_button.tooltip_text = (
			"Next: restructuring credit file."
			if memo_id == &"flock_restructuring" else
			("Next: golden egg credit dossier."
			if memo_id == &"golden_egg_dossier" else
			("Next: allocate closing credit."
			if office._review_has_pending_credit() else
			"Next: file the shift report and plan the following shift."))
		)
	office._day_review_scrim.visible = true
	office._refresh_floor_input_context()
	office._ticker_label.text = "SHIFT COMPLETE. The farmer has harvested the credit; review the real accounting."
	if animate:
		office._day_review_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
		office._day_review_panel.scale = Vector2(0.94, 0.94)
		office._day_review_panel.pivot_offset = office._day_review_panel.size * 0.5
		var tween := office._presentation_tween().set_parallel(true)
		tween.tween_property(office._day_review_panel, "modulate:a", 1.0, 0.24)
		tween.tween_property(office._day_review_panel, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		office._day_review_panel.modulate = Color.WHITE
		office._day_review_panel.scale = Vector2.ONE


func _review_has_pending_credit() -> bool:
	return StringName(office._simulation.pending_decision.get("kind", &"")) in [&"credit_allocation", &"major_event"]


func _review_handoff_hint(optional_copy: String) -> String:
	var next_step := "Review campaign progress, then plan the next shift."
	if office._review_has_pending_credit():
		next_step = "Resolve closing credit, then review what comes next."
	elif office._campaign_senior_roost:
		next_step = "Review your career before planning the next shift."
	elif office._campaign_state != null and office._campaign_state.outcome != Office.CampaignStateScript.OUTCOME_IN_PROGRESS:
		next_step = "Review your five-shift campaign result."
	return "NEXT: %s\nOPTIONAL GOAL: %s" % [next_step, optional_copy]


func _apply_three_card_review(report: Dictionary) -> void:
	var accepted_next_shift: bool = office._personal_goal.get("status", "") == "active" and int(office._personal_goal.get("day", -1)) == int(report.get("day", -2)) + 1
	office._personal_goal_offer = office._personal_goal.duplicate(true) if accepted_next_shift else Office.PersonalShiftGoal.offer(report)
	office._personal_goal_button.text = "GOAL ACCEPTED · CANCEL" if office._personal_goal == office._personal_goal_offer else "TRY NEXT SHIFT · " + Office.PersonalShiftGoal.label(office._personal_goal_offer)
	office._personal_goal_button.tooltip_text = "Optional personal goal. Tracks real results next shift; no money is spent and no cash reward is promised. Click again to cancel."
	var next_challenge := Office.PersonalShiftGoal.strategy(office._personal_goal_offer)
	office._review_next_hint.text = office._review_handoff_hint(String(report.get("personal_goal_result", next_challenge.get("copy", "NEXT SHIFT"))))
	office._review_next_hint.tooltip_text = "Next names the required review step. The personal goal is optional; nothing is purchased or filed automatically."
	office._review_next_hint.accessibility_name = "%s. %s" % [office._review_next_hint.text, office._review_next_hint.tooltip_text]
	var projection := office._gameplay_pulse_director.compose_report(report)
	var cards := projection.get("cards", []) as Array
	var value_labels: Array[Label] = [
		office._review_eggs_value,
		office._review_net_value,
		office._review_fund_value,
	]
	var captions := ["EGGS / QUOTA", "SHIFT NET", "SHELL QUALITY"]
	var card_indexes := [0, 2, 1]
	for index in value_labels.size():
		var value_label := value_labels[index]
		if value_label == null:
			continue
		var caption := value_label.get_parent().find_child(
			value_label.name.trim_suffix("Value") + "Caption",
			true,
			false,
		) as Label
		if caption != null:
			caption.text = captions[index]
		var card: Dictionary = (
			cards[card_indexes[index]] as Dictionary
			if card_indexes[index] < cards.size() else
			{}
		)
		if caption != null:
			caption.text = String(card.get("label", captions[index]))
		value_label.text = String(card.get("value", value_label.text))
		value_label.tooltip_text = "%s  ·  %s\n%s" % [
			String(card.get("label", captions[index])),
			String(card.get("value", value_label.text)),
			String(card.get("detail", "Filed shift result.")),
		]
		value_label.accessibility_name = value_label.tooltip_text
		value_label.set_meta("report_card", card.duplicate(true))
	if office._review_next_value != null:
		var next_caption := office._review_next_value.get_parent().find_child(
			"FarmerReviewNextCaption",
			true,
			false,
		) as Label
		if next_caption != null:
			next_caption.text = "NEXT QUOTA"
	var hen_highlight := report.get("hen_highlight", {}) as Dictionary
	if office._review_story != null and not hen_highlight.is_empty():
		office._review_story.text = _review_hen_caption(hen_highlight)
		office._review_story.tooltip_text = String(hen_highlight.get("body", ""))
		office._review_story.accessibility_name = "%s. %s" % [office._review_story.text, office._review_story.tooltip_text]
	if office._day_review_panel != null:
		office._day_review_panel.set_meta("three_card_report", projection.duplicate(true))
		office._day_review_panel.set_meta(
			"fast_replay_flow",
			{"actions": ["replay_highlight", "remix_idea", "continue"], "one_click": true},
		)


func _review_hen_caption(highlight: Dictionary) -> String:
	var hen_name := String(highlight.get("worker_name", "THE FLOCK")).to_upper()
	var eggs := int(highlight.get("eggs", 0))
	if String(highlight.get("type", "")) == "strain_notice":
		return "%s · NEEDS SOME CARE" % hen_name
	if eggs <= 0:
		return "%s · SHIFT FILED" % hen_name
	return "%s · %d %s" % [hen_name, eggs, "EGG" if eggs == 1 else "EGGS"]


func _review_progression_action(snapshot: Dictionary = {}) -> Dictionary:
	var source := snapshot if not snapshot.is_empty() else office._simulation.snapshot()
	var pending_memo_id := StringName(source.get("credit_memo_id", &""))
	var gallery := office._farmer_relations_gallery_projection(source)
	var gallery_status := StringName(String(gallery.get(
		"campaign_status",
		gallery.get("status", ""),
	)))
	if office._farmer_relations_gallery_offer_open(source):
		return {
			"button_text": "CONTINUE: SKIP PUBLIC CAMPAIGN",
			"exact_detail": "Skip the optional public campaign and continue to this shift's report.",
			"guidance_copy": "NEXT: REQUISITION OR GALLERY",
			"guidance_detail": "Approve any requisitions, publish one Gallery campaign, or continue to skip it.",
		}
	if office._campaign_review_stage == &"credit" and gallery_status in [&"filed", &"skipped"]:
		return {
			"button_text": "CONTINUE: FILE SHIFT REPORT",
			"exact_detail": "File this shift's report after settling the public-credit record.",
			"guidance_copy": "NEXT: REQUISITION OR SHIFT REPORT",
			"guidance_detail": "Approve any requisitions, then file this shift's settled report.",
		}
	if pending_memo_id == &"flock_restructuring":
		return {
			"button_text": "CONTINUE: OPEN RESTRUCTURING FILE",
			"exact_detail": "Open the required restructuring credit file before this shift's report.",
			"guidance_copy": "NEXT: REQUISITION OR RESTRUCTURING",
			"guidance_detail": "Approve any requisitions, then settle the required restructuring credit file.",
		}
	if pending_memo_id == &"golden_egg_dossier":
		return {
			"button_text": "CONTINUE: OPEN GOLDEN DOSSIER",
			"exact_detail": "Open the required golden egg credit dossier before this shift's report.",
			"guidance_copy": "NEXT: REQUISITION OR GOLDEN DOSSIER",
			"guidance_detail": "Approve any requisitions, then settle the required golden egg dossier.",
		}
	if bool(source.get("credit_memo_pending", false)):
		return {
			"button_text": "CONTINUE: FILE CLOSING CREDIT",
			"exact_detail": "File the required closing credit before this shift's report.",
			"guidance_copy": "NEXT: REQUISITION OR CLOSING CREDIT",
			"guidance_detail": "Approve any requisitions, then attribute the flock's work in the closing credit file.",
		}
	if office._campaign_senior_roost:
		return {
			"button_text": "CONTINUE: OPEN SENIOR REPORT",
			"exact_detail": "Open this quarter's Senior Roost report and review the filed results.",
			"guidance_copy": "NEXT: REQUISITION OR SENIOR REPORT",
			"guidance_detail": "Approve any requisitions, then review this quarter's Senior Roost results.",
		}
	if office._campaign_state.outcome != Office.CampaignStateScript.OUTCOME_IN_PROGRESS:
		return {
			"button_text": "CONTINUE: OPEN FINAL REVIEW",
			"exact_detail": "Open the completed probation file's final review.",
			"guidance_copy": "NEXT: REQUISITION OR FINAL REVIEW",
			"guidance_detail": "Approve any requisitions, then open the completed probation file's final review.",
		}
	return {
		"button_text": "CONTINUE: FILE SHIFT RESULTS",
		"exact_detail": "File this shift's results, then choose the next morning policy.",
		"guidance_copy": "NEXT: REQUISITION OR SHIFT RESULTS",
		"guidance_detail": "Approve any requisitions, then file this shift's results before tomorrow's policy.",
	}


func _apply_review_progression_action(snapshot: Dictionary = {}) -> Dictionary:
	var action := office._review_progression_action(snapshot)
	if office._continue_shift_button != null:
		office._continue_shift_button.text = String(action.get("button_text", "CONTINUE: FILE SHIFT RESULTS"))
		var exact_detail := String(action.get(
			"exact_detail",
			"File this shift's results, then choose the next morning policy.",
		))
		office._continue_shift_button.tooltip_text = exact_detail
		office._continue_shift_button.accessibility_name = exact_detail
		office._continue_shift_button.set_meta("accessible_text", exact_detail)
	return action


func _advance_from_farmer_review() -> void:
	office._flockwatch_restore_farmer_review = false
	office._day_review_scrim.visible = false
	office._set_flockwatch_open(false)
	var pending := office._simulation.pending_decision_snapshot()
	var pending_kind := StringName(pending.get("kind", &""))
	if pending_kind in [&"credit_allocation", &"major_event"]:
		office._campaign_review_stage = &"credit"
		office._campaign_ui.show_active_campaign(office._campaign_presentation_snapshot(&"active"))
		office._set_campaign_modal_open(false)
		office._simulation.announce_pending_decision()
		office._queue_campaign_checkpoint("credit_memo_opened")
		return
	office._advance_after_closing_credit()


func _senior_presentation_snapshot(view: StringName) -> Dictionary:
	var state_snapshot: Dictionary = office._senior_roost_state.snapshot()
	var status_id: StringName = office._senior_roost_state.status
	var annual_review: Dictionary = office._senior_roost_state.last_annual_review
	var quarter_review: Dictionary = office._senior_roost_state.last_quarter_review
	var active_policy := office._senior_roost_state.active_policy()
	var mandate_required := office._senior_roost_state.requires_annual_mandate()
	var active_mandate := office._senior_roost_state.active_annual_mandate()
	var mandate_progress := office._senior_roost_state.current_annual_mandate_progress(
		office._campaign_live_metrics(office._simulation.snapshot()) if view == &"active" else {}
	)
	var career_forecast := office._senior_roost_state.current_career_forecast(
		office._campaign_live_metrics(office._simulation.snapshot()) if view == &"active" else {}
	)
	var mandate_tier := office._senior_roost_state.mandate_tier_eligibility()
	var mandate_mastery := state_snapshot.get("mandate_mastery", {}) as Dictionary
	var year_number := office._senior_roost_state.current_year_number()
	var quarter_number := office._senior_roost_state.current_quarter_in_year()
	var display_shift := office._senior_roost_state.current_shift_in_quarter()
	if status_id == Office.SeniorRoostStateScript.STATUS_ANNUAL_REVIEW:
		year_number = maxi(1, int(annual_review.get("year", office._senior_roost_state.completed_years)))
		quarter_number = Office.SeniorRoostStateScript.QUARTERS_PER_YEAR
		display_shift = Office.SeniorRoostStateScript.SHIFTS_PER_QUARTER
	elif status_id == Office.SeniorRoostStateScript.STATUS_QUARTER_CHOICE:
		display_shift = 1
	elif view == &"between_shift" and not office._senior_roost_state.current_quarter_shifts.is_empty():
		display_shift = clampi(
			int(office._senior_roost_state.last_shift_result.get("shift_in_quarter", 1)),
			1,
			Office.SeniorRoostStateScript.SHIFTS_PER_QUARTER,
		)

	var policy_cards: Array[Dictionary] = []
	if status_id == Office.SeniorRoostStateScript.STATUS_QUARTER_CHOICE:
		policy_cards = (
			_senior_board_mandate_cards()
			if mandate_required else
			office._senior_roost_state.policy_catalog(office._simulation.spendable_fund_cents())
		)

	var report_heading := "SENIOR ROOST QUARTERLY FILING"
	var report_note := "The permanent career ledger remains open."
	var continue_label := "PLAN NEXT SENIOR SHIFT  [C]"
	var continue_tooltip := "Open the next Senior Roost shift briefing."
	var objective := {
		"title": "FILE A CAPITAL POLICY",
		"description": "Choose how the next three shifts trade money, pressure, and flock trust.",
		"reward": "Every completed quarter awards up to 3 permanent Roost Marks.",
	}
	var secondary_display := "%d / %d" % [
		office._senior_roost_state.current_quarter_shifts.size(),
		Office.SeniorRoostStateScript.SHIFTS_PER_QUARTER,
	]
	var secondary_caption := "QUARTER SHIFTS"
	var secondary_tooltip := "Three filed shifts close a Senior Roost quarter."

	if status_id == Office.SeniorRoostStateScript.STATUS_QUARTER_CHOICE:
		if mandate_required:
			report_heading = "YEAR %d · ANNUAL BOARD MANDATE" % year_number
			continue_label = "SELECT A MANDATE BEFORE Q1 POLICY  [C]"
			continue_tooltip = "Choose one frozen twelve-shift Board Mandate; the Standard Board Book never stakes Roost Marks."
			secondary_display = "%d" % int(mandate_tier.get("mandate_seals", 0))
			secondary_caption = "BOARD SEALS"
			secondary_tooltip = _senior_mandate_tier_tooltip(mandate_tier)
			report_note = "Choose the year-long terms before quarterly policy. Harder books stake available Roost Marks; success returns the stake and earns more permanent Board Seals. PORTFOLIO %d / %d MASTERED; first clears advance Coop Commendations." % [
				int(mandate_mastery.get("mastered_count", 0)),
				int(mandate_mastery.get("total_count", Office.SeniorRoostStateScript.MANDATE_IDS.size())),
			]
			if year_number > 1 and not annual_review.is_empty():
				var previous_year_passed := bool(annual_review.get("passed", false))
				var transition_note := (
					"YEAR %d CLEARED  ·  BASELINE +1 FOR THIS YEAR." % (year_number - 1)
					if previous_year_passed else
					"RECOVERY YEAR  ·  BASELINE +2  ·  FARMER FAVOR -5."
				)
				report_note = "%s %s" % [transition_note, report_note]
			objective = {
				"title": "CHOOSE THE YEAR'S TERMS",
				"description": "Compare all three target bundles, reward, failure cost, and stake. The first card is always a valid no-stake fallback.",
				"reward": "%s  /  PORTFOLIO %d / %d" % [
					_senior_mandate_tier_tooltip(mandate_tier),
					int(mandate_mastery.get("mastered_count", 0)),
					int(mandate_mastery.get("total_count", Office.SeniorRoostStateScript.MANDATE_IDS.size())),
				],
			}
		else:
			report_heading = "YEAR %d · QUARTER %d CAPITAL FILING" % [year_number, quarter_number]
			continue_label = "SELECT A POLICY TO OPEN QUARTER  [C]"
			continue_tooltip = "File one available capital policy before the quarter can open."
			secondary_display = (
				"%d / 100" % int(quarter_review.get("score", 0))
				if not quarter_review.is_empty() else
				"OPEN"
			)
			secondary_caption = "LAST QUARTER"
			if quarter_review.is_empty():
				report_note = "Annual terms filed. Choose the irreversible capital policy that governs this three-shift quarter."
			else:
				var available_sponsorship_marks := int(state_snapshot.get(
					"available_roost_marks",
					office._senior_roost_state.roost_marks,
				))
				var sponsorship_mark_cost := int(state_snapshot.get(
					"sponsorship_mark_cost",
					Office.SeniorRoostStateScript.SPONSORSHIP_MARK_COST,
				))
				var sponsorship_note := (
					"Optional Career Sponsorship is available below."
					if available_sponsorship_marks >= sponsorship_mark_cost else
					"Sponsorship unlock: %d banked marks (%d available)." % [
						sponsorship_mark_cost,
						available_sponsorship_marks,
					]
				)
				report_note = "Q%d filed at %d / 100 for +%d Roost Mark%s. File one policy. %s" % [
					int(quarter_review.get("quarter_number", 0)),
					int(quarter_review.get("score", 0)),
					int(quarter_review.get("marks_awarded", 0)),
					"" if int(quarter_review.get("marks_awarded", 0)) == 1 else "s",
					sponsorship_note,
				]
				var quarter_breakdown := state_snapshot.get(
					"last_quarter_score_breakdown",
					{},
				) as Dictionary
				var filed_score := int(quarter_review.get("score", 0))
				var marks_awarded := int(quarter_review.get("marks_awarded", 0))
				var credit_leaders: Array[String] = []
				for component_value in quarter_breakdown.get("components", []):
					var component := component_value as Dictionary
					if int(component.get("score", 0)) <= 0:
						continue
					credit_leaders.append("%s %d/%d" % [
						String(component.get("label", "SENIOR CREDIT")),
						int(component.get("score", 0)),
						int(component.get("max_score", 0)),
					])
					if credit_leaders.size() == 3:
						break
				var result_lines: Array[String] = [
					"FILED SCORE  ·  %d / 100  ·  +%d ROOST MARK%s" % [
						filed_score,
						marks_awarded,
						"" if marks_awarded == 1 else "S",
					],
				]
				if not credit_leaders.is_empty():
					result_lines.append("CREDIT LEADERS  ·  %s" % "  ·  ".join(credit_leaders))
				var recoverable := quarter_breakdown.get(
					"largest_recoverable_component",
					{},
				) as Dictionary
				if recoverable.is_empty():
					result_lines.append("TOP MARK TIER  ·  NO RECOVERABLE SENIOR POINTS")
				else:
					result_lines.append("NEXT EDGE  ·  %s  ·  +%d RECOVERABLE" % [
						String(recoverable.get("label", "SENIOR STANDING")),
						int(recoverable.get("recoverable_points", 0)),
					])
					result_lines.append(String(recoverable.get(
						"cause",
						"The closing ledger identifies the next recoverable edge.",
					)))
				objective = {
					"title": "QUARTER %d FILED  ·  REWARD RECEIPT" % int(
						quarter_review.get("quarter_number", 0)
					),
					"description": "\n".join(result_lines),
					"reward": "%d lifetime Roost Mark%s" % [
						office._senior_roost_state.roost_marks,
						"" if office._senior_roost_state.roost_marks == 1 else "s",
					],
				}
				if not mandate_progress.is_empty():
					var board_status := "BOARD %d / %d TARGETS MET" % [
						int(mandate_progress.get("objectives_met", 0)),
						int(mandate_progress.get("objectives_total", 0)),
					]
					var mandate_blocker := mandate_progress.get(
						"largest_recoverable_blocker",
						{},
					) as Dictionary
					if mandate_blocker.is_empty():
						board_status += "  ·  YEAR BOOK ON TRACK"
					else:
						board_status += "  ·  NEXT %s %d / %d" % [
							String(mandate_blocker.get("label", "ANNUAL TARGET")),
							int(mandate_blocker.get("actual", 0)),
							int(mandate_blocker.get("target", 0)),
						]
					objective["reward"] = "%s  ·  %s" % [
						String(objective.get("reward", "")),
						board_status,
					]
	elif status_id == Office.SeniorRoostStateScript.STATUS_ANNUAL_REVIEW:
		var annual_passed := bool(annual_review.get("passed", false))
		var strategy_recap := Office.SeniorRoostStateScript.annual_strategy_recap(annual_review)
		var mandate_settlement := annual_review.get(
			"mandate_settlement",
			office._senior_roost_state.last_mandate_settlement,
		) as Dictionary
		var mandate_succeeded := bool(mandate_settlement.get("success", false))
		var seals_after := int(mandate_settlement.get(
			"mandate_seals_after",
			office._senior_roost_state.mandate_seals,
		))
		var seals_before := maxi(
			0,
			seals_after - int(mandate_settlement.get("seal_reward", 0)),
		)
		var mandate_tier_before := Office.SeniorRoostStateScript.mandate_tier_for_seals(seals_before)
		var mandate_tier_after := Office.SeniorRoostStateScript.mandate_tier_for_seals(seals_after)
		var mandate_unlock_note := ""
		if mandate_tier_after > mandate_tier_before:
			mandate_unlock_note = " Advanced mandate tier %d unlocked for Year %d." % [
				mandate_tier_after,
				year_number + 1,
			]
		report_heading = "YEAR %d ANNUAL ROOST REVIEW" % year_number
		report_note = "%s  Annual score %d / 100 · welfare %d%% · obedience %d%% · farmer favor %d%% · shell cracks %.1f%%." % [
			"SAFEGUARDS PASSED." if annual_passed else "PERFORMANCE IMPROVEMENT YEAR REQUIRED.",
			int(annual_review.get("score", 0)),
			int(annual_review.get("welfare", 0)),
			int(annual_review.get("compliance", 0)),
			int(annual_review.get("farmer_favor", 0)),
			float(int(annual_review.get("crack_rate_basis_points", 0))) / 100.0,
		]
		var annual_available_marks := int(state_snapshot.get(
			"available_roost_marks",
			office._senior_roost_state.available_roost_marks(),
		))
		var annual_sponsorship_cost := int(state_snapshot.get(
			"sponsorship_mark_cost",
			Office.SeniorRoostStateScript.SPONSORSHIP_MARK_COST,
		))
		report_note += (
			" Career Sponsorship may be filed before Year %d planning." % (year_number + 1)
			if annual_available_marks >= annual_sponsorship_cost else
			" Sponsorship needs %d available marks; %d currently banked." % [
				annual_sponsorship_cost,
				annual_available_marks,
			]
		)
		if not mandate_settlement.is_empty():
			report_note += " %s" % String(mandate_settlement.get(
				"outcome",
				"The annual Board Mandate has been settled.",
			))
			if mandate_succeeded:
				var settled_mandate_id := StringName(String(mandate_settlement.get("mandate_id", "")))
				var mastery_counts := state_snapshot.get("mandate_success_counts", {}) as Dictionary
				var mastery_count := int(mastery_counts.get(settled_mandate_id, 0))
				report_note += " %s / BOARD PORTFOLIO %d / %d." % [
					"NEW BOOK MASTERED" if mastery_count == 1 else "BOOK REFILED x%d" % mastery_count,
					int(mandate_mastery.get("mastered_count", 0)),
					int(mandate_mastery.get("total_count", Office.SeniorRoostStateScript.MANDATE_IDS.size())),
				]
		report_note += mandate_unlock_note
		continue_label = "BEGIN YEAR %d PLANNING  [C]" % (year_number + 1)
		continue_tooltip = (
			"Accept the annual review. Next year's baseline quota rises by one egg."
			if annual_passed else
			"Accept the improvement year. Baseline quota rises by two and farmer favor falls by five."
		)
		objective = {
			"title": "%s · YEAR %d %s" % [
				String(mandate_settlement.get("mandate_name", "BOARD MANDATE")),
				year_number,
				"SEALED" if mandate_succeeded else "HELD",
			],
			"description": (
				"The career continues with a one-egg baseline increase."
				if annual_passed else
				"The career continues under a two-egg quota increase and reduced farmer favor."
			) + (
				" Board Mandate succeeded: +%d permanent seal%s; %d staked mark%s returned."
				% [
					int(mandate_settlement.get("seal_reward", 0)),
					"" if int(mandate_settlement.get("seal_reward", 0)) == 1 else "s",
					int(mandate_settlement.get("stake_returned", 0)),
					"" if int(mandate_settlement.get("stake_returned", 0)) == 1 else "s",
				]
				if mandate_succeeded else
				(" Board Mandate failed: no seal filed; no Roost Marks were at risk."
				if int(mandate_settlement.get("stake_marks", 0)) == 0 else
				" Board Mandate failed: %d staked Roost Mark%s permanently spent."
				% [
					int(mandate_settlement.get("stake_forfeited", 0)),
					"" if int(mandate_settlement.get("stake_forfeited", 0)) == 1 else "s",
				])
			),
			"reward": (
				"+3 annual Roost Marks" if annual_passed else "No annual bonus marks"
			) + " · %d total Board Seals  /  %d / %d BOOKS MASTERED" % [
				seals_after,
				int(mandate_mastery.get("mastered_count", 0)),
				int(mandate_mastery.get("total_count", Office.SeniorRoostStateScript.MANDATE_IDS.size())),
			] + (
				" · MANDATE TIER %d UNLOCKED" % mandate_tier_after
				if mandate_tier_after > mandate_tier_before else
				""
			),
		}
		if not strategy_recap.is_empty():
			var recap_lines := strategy_recap.get("lines", []) as Array
			objective["description"] = "%s\n\nYEAR STRATEGY RECEIPT\n%s" % [
				String(objective.get("description", "")),
				"\n".join(recap_lines),
			]
		secondary_display = "%d / 100" % int(annual_review.get("score", 0))
		secondary_caption = "ANNUAL SCORE"
		secondary_tooltip = "Annual passage requires 60 plus every flock, shell, favor, and solvency safeguard."
	else:
		var shifts_filed: int = office._senior_roost_state.current_quarter_shifts.size()
		var policy_title := String(active_policy.get("title", "SENIOR POLICY"))
		if shifts_filed == 0:
			report_heading = "QUARTER %d POLICY FILED" % quarter_number
			report_note = String(office._senior_roost_state.active_policy_receipt.get(
				"outcome",
				"%s now governs the next three shifts." % policy_title,
			))
			continue_label = "BEGIN QUARTER %d · SHIFT 1  [C]" % quarter_number
		else:
			report_heading = "QUARTER %d · SHIFT %d FILED" % [quarter_number, display_shift]
			# The heading, shift metric, policy receipt, and primary action already
			# carry this state. Leaving the subtitle empty removes a repeated sentence
			# from the scan path without hiding any authoritative information.
			report_note = ""
			continue_label = "PLAN QUARTER %d · SHIFT %d  [C]" % [
				quarter_number,
				office._senior_roost_state.current_shift_in_quarter(),
			]
		var objective_rows: Array[Dictionary] = office._senior_roost_state.current_objective_progress(
			office._campaign_live_metrics(office._simulation.snapshot()) if view == &"active" else {}
		)
		if not objective_rows.is_empty():
			var objective_lines: Array[String] = []
			for row in objective_rows:
				objective_lines.append("%s · %s" % [
					"ON TRACK" if bool(row.get("projected_met", false)) else "NEEDS ACTION",
					String(row.get("description", "Quarter safeguard filed.")),
				])
			objective = {
				"title": "YEAR %d · QUARTER %d · %s" % [year_number, quarter_number, policy_title],
				"description": "\n".join(objective_lines),
				"quarter_drivers": objective_rows,
				"reward": "Score 40+ earns 1 Roost Mark Â· 60+ earns 2 Â· 80+ earns 3.",
			}

	# The annual Board stays visible in every in-year report, but its dense exact
	# ledger is progressive detail. One stable summary and three target tiles own
	# the visible layer whether the player is between shifts or filing a policy.
	if (
		not mandate_progress.is_empty()
		and status_id != Office.SeniorRoostStateScript.STATUS_ANNUAL_REVIEW
	):
		var mandate_lines := office._senior_mandate_progress_lines(mandate_progress)
		objective["board_detail"] = "ANNUAL BOARD  //  %s\n%s" % [
			String(mandate_progress.get("mandate_name", "BOARD MANDATE")),
			"\n".join(mandate_lines),
		]
		var mandate_met := int(mandate_progress.get("objectives_met", 0))
		var mandate_total := int(mandate_progress.get("objectives_total", 0))
		objective["board_summary"] = "BOARD %d / %d MET  //  %d NEED ACTION  //  YEAR %d / %d" % [
			mandate_met,
			mandate_total,
			maxi(0, mandate_total - mandate_met),
			int(mandate_progress.get("shifts_recorded", 0)),
			int(mandate_progress.get("shifts_target", 12)),
		]
		objective["reward"] = objective["board_summary"]

	var policy_receipt: Dictionary = {}
	if status_id == Office.SeniorRoostStateScript.STATUS_ACTIVE and not office._senior_roost_state.active_policy_receipt.is_empty():
		policy_receipt = office._senior_roost_state.active_policy_receipt.duplicate(true)
		policy_receipt["day"] = display_shift
		policy_receipt["decision_id"] = "senior_quarter_policy"
		policy_receipt["option_id"] = String(office._senior_roost_state.active_policy_id)

	var hen_highlight: Dictionary = {}
	# The named-hen story remains on each in-quarter shift receipt. At a quarter
	# or annual boundary the policy/reward filing owns the hierarchy; repeating
	# the previous shift highlight there pushed the actual policy controls below
	# the fold without adding a new decision.
	if (
		office._senior_roost_state.total_senior_shifts > 0
		and status_id == Office.SeniorRoostStateScript.STATUS_ACTIVE
	):
		var highlight_value: Variant = office._last_workday_report.get("hen_highlight", {})
		if highlight_value is Dictionary and not (highlight_value as Dictionary).is_empty():
			hen_highlight = (highlight_value as Dictionary).duplicate(true)
			hen_highlight["day"] = display_shift

	var last_quarter_score := int(quarter_review.get("score", 0))
	var available_roost_marks := int(state_snapshot.get(
		"available_roost_marks",
		office._senior_roost_state.roost_marks,
	))
	var invested_roost_marks := int(state_snapshot.get("roost_marks_spent", 0))
	var staked_roost_marks := int(state_snapshot.get("mandate_stake_reserved", 0))
	var forfeited_roost_marks := int(state_snapshot.get("mandate_marks_forfeited", 0))
	var mandate_seals := int(state_snapshot.get("mandate_seals", 0))
	var ledgers: Array[Dictionary] = [
		{
			"label": "Roost Marks",
			"value": office._senior_roost_state.roost_marks,
			"glance": (
				"+ %d READY TO SPEND" % available_roost_marks
				if available_roost_marks > 0 else
				"- NONE READY TO SPEND"
			),
			"detail": "%d AVAILABLE  ·  %d INVESTED  ·  %d STAKED  ·  %d FORFEITED" % [
				available_roost_marks,
				invested_roost_marks,
				staked_roost_marks,
				forfeited_roost_marks,
			],
		},
		{
			"label": "Board Seals",
			"value": mandate_seals,
			"format": "number",
			"glance": (
				"+ MAX TIER UNLOCKED"
				if int(mandate_tier.get("eligible_tier", 0)) >= int(mandate_tier.get("max_tier", 3)) else
				"> %d SEAL%s TO TIER %d" % [
					int(mandate_tier.get("seals_to_next_tier", 0)),
					"" if int(mandate_tier.get("seals_to_next_tier", 0)) == 1 else "S",
					int(mandate_tier.get("eligible_tier", 0)) + 1,
				]
			),
			"detail": "MANDATE TIER %d  ·  %s" % [
				int(mandate_tier.get("eligible_tier", 0)),
				_senior_mandate_tier_tooltip(mandate_tier).to_upper(),
			],
		},
		{
			"label": "Quarter score",
			"value": last_quarter_score,
			"format": "number",
			"glance": "+ LAST QUARTER FILED" if not quarter_review.is_empty() else "> FIRST QUARTER OPEN",
			"detail": "LAST CLOSED QUARTER" if not quarter_review.is_empty() else "FIRST QUARTER OPEN",
		},
		{
			"label": "Spendable Feed Fund",
			"value": office._simulation.spendable_fund_cents(),
			"format": "currency_cents",
			"detail": "AFTER OPERATING RESERVE",
		},
	]
	if status_id == Office.SeniorRoostStateScript.STATUS_ANNUAL_REVIEW:
		ledgers[2] = {
			"label": "Annual score",
			"value": int(annual_review.get("score", 0)),
			"format": "number",
			"glance": "+ SAFEGUARDS PASSED" if bool(annual_review.get("passed", false)) else "! IMPROVEMENT YEAR",
			"detail": "PASSED" if bool(annual_review.get("passed", false)) else "IMPROVEMENT YEAR",
		}
		ledgers[3] = {
			"label": "Years passed",
			"value": office._senior_roost_state.successful_years,
			"detail": "OF %d REVIEWED" % office._senior_roost_state.completed_years,
		}

	var available_marks := int(state_snapshot.get(
		"available_roost_marks",
		office._senior_roost_state.roost_marks,
	))
	var primary_metric_display := str(available_marks)
	var primary_metric_caption := "AVAILABLE MARKS"
	var primary_metric_tooltip := "%d uncommitted Roost Mark%s remain after stakes and career spending." % [
		available_marks,
		"" if available_marks == 1 else "s",
	]
	if status_id == Office.SeniorRoostStateScript.STATUS_ACTIVE:
		primary_metric_caption = "MARKS FORECAST"
		if career_forecast.is_empty():
			primary_metric_display = "OPEN"
			primary_metric_tooltip = "The quarter reward forecast opens after the first filed Senior shift."
		else:
			var projected_marks := int(career_forecast.get("projected_marks", 0))
			var projected_score := int(career_forecast.get("projected_score", 0))
			primary_metric_display = "+%d" % projected_marks
			primary_metric_tooltip = "If this quarter filed at the current projection: score %d / 100 and +%d Roost Mark%s." % [
				projected_score,
				projected_marks,
				"" if projected_marks == 1 else "s",
			]

	return {
		"view": view,
		"career_mode": "senior_roost",
		"status": "SENIOR ROOST",
		"day": display_shift,
		"total_days": Office.SeniorRoostStateScript.SHIFTS_PER_QUARTER,
		"senior_year": year_number,
		"senior_quarter": quarter_number,
		"day_badge_text": (
			"YEAR %d · ANNUAL REVIEW" % year_number
			if status_id == Office.SeniorRoostStateScript.STATUS_ANNUAL_REVIEW else
			("Y%d · ANNUAL MANDATE" % year_number
			if mandate_required else
			("Y%d · Q%d · POLICY" % [year_number, quarter_number]
			if status_id == Office.SeniorRoostStateScript.STATUS_QUARTER_CHOICE else
			"Y%d · Q%d · SHIFT %d / %d" % [year_number, quarter_number, display_shift, Office.SeniorRoostStateScript.SHIFTS_PER_QUARTER]))
		),
		"score": office._senior_roost_state.roost_marks,
		"primary_metric_display": primary_metric_display,
		"primary_metric_tooltip": primary_metric_tooltip,
		"score_caption": primary_metric_caption,
		"rank": office._senior_roost_state.promotion_title(),
		"rank_caption": "CAREER TITLE",
		"secondary_metric_display": secondary_display,
		"secondary_metric_caption": secondary_caption,
		"secondary_metric_tooltip": secondary_tooltip,
		"ledgers": ledgers,
		"ledger_section_title": "SENIOR CAREER RECORD",
		"report_kicker": "SENIOR ROOST  //  YEAR %d  //  QUARTER %d" % [year_number, quarter_number],
		"report_heading": report_heading,
		"report_note": report_note,
		"objective_section_title": "ANNUAL BOARD MANDATE" if not active_mandate.is_empty() or mandate_required else "SENIOR OBJECTIVE",
		"next_objective": objective,
		"milestone_choices": policy_cards,
		"selected_milestone": (
			String(active_mandate.get("id", ""))
			if mandate_required else
			String(office._senior_roost_state.active_policy_id)
		),
		"choice_required": status_id == Office.SeniorRoostStateScript.STATUS_QUARTER_CHOICE,
		"choice_section_title": (
			"ANNUAL BOARD MANDATE  //  FILE ONE"
			if mandate_required else
			"QUARTERLY CAPITAL POLICY  //  FILE ONE"
		),
		"choice_hint": (
			"One twelve-shift mandate governs the year. Compare targets, seal reward, and any Roost Mark stake."
			if mandate_required else
			(
				"One policy governs three shifts. LAST YEAR shows how each option affects the prior binding safeguard."
				if (
					office._senior_roost_state.completed_years > 0
					and office._senior_roost_state.current_year_quarters.is_empty()
				) else
				"One irreversible policy governs the next three shifts."
			)
		),
		"continue_label": continue_label,
		"continue_tooltip": continue_tooltip,
		"credit_memo": policy_receipt,
		"score_receipt": {},
		"market_forecast": office._campaign_market_forecast(
			view == &"between_shift"
			and status_id != Office.SeniorRoostStateScript.STATUS_ANNUAL_REVIEW
		),
		"hen_highlight": hen_highlight,
		"senior_roost": state_snapshot,
		"annual_mandate": active_mandate,
		"annual_mandate_progress": mandate_progress,
		"annual_mandate_delta": state_snapshot.get("annual_mandate_delta", {}),
		"annual_strategy_recap": (
			Office.SeniorRoostStateScript.annual_strategy_recap(annual_review)
			if status_id == Office.SeniorRoostStateScript.STATUS_ANNUAL_REVIEW else
			{}
		),
		"mandate_tier": mandate_tier,
		"career_sponsorship": office._career_sponsorship_presentation_snapshot(),
		"staffing_planning_open": bool(
			office._simulation.snapshot().get("staffing_planning_open", false)
		),
	}


func _senior_board_mandate_cards() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for offer in office._senior_roost_state.annual_mandate_catalog():
		var targets: Array[String] = []
		for objective_value in offer.get("objectives", []) as Array:
			if not objective_value is Dictionary:
				continue
			var target := objective_value as Dictionary
			targets.append("%s %s" % [
				String(target.get("label", "TARGET")),
				office._senior_mandate_target_text(
					String(target.get("metric", "")),
					String(target.get("comparison", "minimum")),
					int(target.get("target", 0)),
				),
			])
		var stake := int(offer.get("stake_marks", 0))
		var mastery_text := String(offer.get("mastery_text", "NEW PORTFOLIO CLEAR"))
		var available := bool(offer.get("available", true))
		var unavailable_reason := String(offer.get("unavailable_reason", ""))
		var stake_text := "NO MARK STAKE" if stake <= 0 else "%d ROOST MARK%s STAKED" % [
			stake,
			"" if stake == 1 else "S",
		]
		var effect_text := "TIER %d  /  %s  /  %s  /  +%d SEAL%s\nTARGETS  %s" % [
			int(offer.get("tier", 0)),
			mastery_text,
			stake_text,
			int(offer.get("seal_reward", 1)),
			"" if int(offer.get("seal_reward", 1)) == 1 else "S",
			"  ·  ".join(targets),
		]
		if not available and not unavailable_reason.is_empty():
			effect_text += "\nHELD  ·  %s" % unavailable_reason.to_upper()
		var result_tooltip := (
			unavailable_reason
			if not available else
			"SUCCESS: %s\nFAILURE: %s" % [
				String(offer.get("reward", "Earn permanent Board Seals.")),
				String(offer.get("failure", "No seal is awarded.")),
			]
		)
		result_tooltip = "PORTFOLIO: %s\n%s" % [mastery_text, result_tooltip]
		cards.append({
			"id": String(offer.get("id", "")),
			"title": String(offer.get("name", "ANNUAL BOARD MANDATE")),
			"description": String(offer.get("summary", "Twelve-shift annual performance book.")),
			"effect": effect_text,
			"stake_marks": stake,
			"confirmation_required": stake > 0,
			"confirmation_label": "CONFIRM %d-MARK STAKE  [C]" % stake,
			"confirmation_tooltip": (
				"Confirm the %d-mark career stake. The marks remain reserved for this twelve-shift Book; success returns them, while failure permanently spends them."
				% stake
			),
			"available": available,
			"unavailable_reason": unavailable_reason,
			"tooltip": result_tooltip,
		})
	return cards


func _senior_mandate_tier_tooltip(tier: Dictionary) -> String:
	var eligible := int(tier.get("eligible_tier", 0))
	var seals_to_next := int(tier.get("seals_to_next_tier", 0))
	if eligible >= int(tier.get("max_tier", 3)):
		return "Maximum Board Mandate tier unlocked."
	return "%d more Board Seal%s unlock%s mandate tier %d." % [
		seals_to_next,
		"" if seals_to_next == 1 else "s",
		"s" if seals_to_next == 1 else "",
		eligible + 1,
	]


func _career_sponsorship_presentation_snapshot() -> Dictionary:
	if not office._campaign_senior_roost or office._senior_roost_state == null:
		return {"visible": false}
	var status_id: StringName = office._senior_roost_state.status
	var gate_open := status_id in [
		Office.SeniorRoostStateScript.STATUS_QUARTER_CHOICE,
		Office.SeniorRoostStateScript.STATUS_ANNUAL_REVIEW,
	]
	var has_closed_quarter: bool = office._senior_roost_state.completed_quarters > 0
	if (
		not gate_open
		or not has_closed_quarter
		or office._senior_roost_state.requires_annual_mandate()
	):
		return {"visible": false}

	var simulation_snapshot := office._simulation.snapshot()
	var flock_care := simulation_snapshot.get("flock_care", {}) as Dictionary
	var training_terms := flock_care.get("training_terms", {}) as Dictionary
	var senior_snapshot: Dictionary = office._senior_roost_state.snapshot()
	var mark_cost := int(senior_snapshot.get(
		"sponsorship_mark_cost",
		Office.SeniorRoostStateScript.SPONSORSHIP_MARK_COST,
	))
	var available_marks := int(senior_snapshot.get(
		"available_roost_marks",
		office._senior_roost_state.roost_marks,
	))
	var fund_cost := int(training_terms.get(
		"effective_sponsorship_cost_cents",
		training_terms.get(
			"effective_cost_cents",
			simulation_snapshot.get("career_sponsorship_cost_cents", 1200),
		),
	))
	var spendable_fund := int(simulation_snapshot.get(
		"spendable_fund_cents",
		office._simulation.spendable_fund_cents(),
	))
	var planning_open := bool(simulation_snapshot.get(
		"career_sponsorship_planning_open",
		false,
	))
	var sponsorship_filed_this_gate := false
	var sponsorship_history_value: Variant = senior_snapshot.get("sponsorship_history", [])
	if sponsorship_history_value is Array:
		for record_value in sponsorship_history_value as Array:
			if (
				record_value is Dictionary
				and int((record_value as Dictionary).get("career_quarter", -1)) == office._senior_roost_state.completed_quarters
			):
				sponsorship_filed_this_gate = true
				break

	var lanes: Array[Dictionary] = []
	for lane_value in office._simulation.routing_catalog():
		var lane := lane_value as Dictionary
		lanes.append({
			"id": String(lane.get("id", "")),
			"label": String(lane.get("display_name", lane.get("short_name", "FILE TRAY"))),
		})

	var eligible_workers: Array[Dictionary] = []
	for worker_value in simulation_snapshot.get("workers", []):
		if worker_value is not Dictionary:
			continue
		var worker := worker_value as Dictionary
		if not office._is_worker_employed(worker) or int(worker.get("career_level", 0)) < 1:
			continue
		if bool(worker.get("has_secondary_specialty", false)):
			continue
		if bool(worker.get("cross_training_pending", false)):
			continue
		eligible_workers.append({
			"id": int(worker.get("id", -1)),
			"name": String(worker.get("name", "PECKWORK HEN")),
			"career_title": String(worker.get("career_title", "ACCREDITED LAYER")),
			"primary_specialty": String(worker.get("specialty", "")),
			"primary_specialty_name": String(worker.get("specialty_name", "PRIMARY FILE TRAY")),
			"secondary_specialty": String(worker.get("secondary_specialty", "")),
			"wage_cents": int(worker.get("daily_wage_cents", 0)),
			"current_daily_wage_cents": int(worker.get("daily_wage_cents", 0)),
		})

	var unavailable_reason := ""
	if sponsorship_filed_this_gate:
		unavailable_reason = "This quarter's career sponsorship has already been filed. Bank remaining marks for the next quarter."
	elif not planning_open:
		unavailable_reason = "Career sponsorships are authorized only while the office is in a closed-shift planning review."
	elif available_marks < mark_cost:
		unavailable_reason = "%d more Roost Mark%s required. Marks may be banked across quarters." % [
			mark_cost - available_marks,
			"" if mark_cost - available_marks == 1 else "s",
		]
	elif spendable_fund < fund_cost:
		unavailable_reason = "$%.2f more protected Feed Fund is required." % (float(fund_cost - spendable_fund) / 100.0)
	elif eligible_workers.is_empty():
		unavailable_reason = "No employed Accredited Layer is currently eligible for a first secondary routing specialty."

	# A disabled multi-field form competes with the irreversible quarterly policy
	# choice and pushes its filing action below a typical laptop viewport. The
	# quarter heading already publishes the exact three-mark unlock, so keep this
	# optional surface out of the planning hierarchy until it can be used.
	if available_marks < mark_cost and not sponsorship_filed_this_gate:
		return {
			"visible": false,
			"available_marks": available_marks,
			"mark_cost": mark_cost,
			"unavailable_reason": unavailable_reason,
		}

	return {
		"visible": true,
		"available_marks": available_marks,
		"lifetime_marks": office._senior_roost_state.roost_marks,
		"invested_marks": int(senior_snapshot.get("roost_marks_spent", 0)),
		"mark_cost": mark_cost,
		"fund_cost_cents": fund_cost,
		"training_terms": training_terms.duplicate(true),
		"spendable_fund_cents": spendable_fund,
		"eligible_workers": eligible_workers,
		"lanes": lanes,
		"unavailable_reason": unavailable_reason,
	}


func _capture_day_review_preview(expand_details := false, max_interface_scale := false) -> void:
	office._ensure_preview_runner()
	await office._preview_runner.call("_capture_day_review_preview", expand_details, max_interface_scale)


func _capture_review_preview() -> void:
	office._ensure_preview_runner()
	await office._preview_runner.call("_capture_review_preview")


func _capture_routing_review_preview() -> void:
	office._ensure_preview_runner()
	await office._preview_runner.call("_capture_routing_review_preview")


func _capture_internship_review_ui_preview() -> void:
	office._ensure_preview_runner()
	await office._preview_runner.call("_capture_internship_review_ui_preview")
