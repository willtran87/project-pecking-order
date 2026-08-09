extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const TEST_SAVE_FILENAME := "flockwatch_today_density_test.json"


func _init() -> void:
	create_timer(60.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	var store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	store.delete()
	var office := Office.new()
	office.set("_campaign_store", store)
	root.add_child(office)
	await process_frame
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var decision_host := office.get("_decision_host") as Control
	var navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	if decision_host != null:
		decision_host.visible = false
	if simulation != null:
		simulation.pending_decision.clear()
		simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	office.set("_active_decision", {})
	if campaign_ui != null:
		campaign_ui.show_active_campaign()
	office.call("_set_campaign_modal_open", false)
	office.call("_set_flockwatch_open", true)
	await process_frame
	await process_frame

	var snapshot_panel := office.find_child("FlockwatchTodaySnapshot", true, false) as PanelContainer
	var workload := office.find_child("FlockwatchTodayWorkload", true, false) as Label
	var clutch := office.find_child("FlockwatchTodayClutch", true, false) as Label
	var flock := office.find_child("FlockwatchTodayFlock", true, false) as Label
	var ledgers := office.find_child("FlockwatchTodayLedgers", true, false) as Label
	var workload_glance := office.find_child("FlockwatchTodayCasesGlance", true, false) as Label
	var clutch_glance := office.find_child("FlockwatchTodayEggsGlance", true, false) as Label
	var flock_glance := office.find_child("FlockwatchTodayFlockGlance", true, false) as Label
	var cash_glance := office.find_child("FlockwatchTodayCashGlance", true, false) as Label
	var snapshot_heading := office.find_child("FlockwatchTodaySnapshotHeading", true, false) as Label
	var glance_icons: Array[Node] = []
	for icon_name: String in [
		"FlockwatchTodayCasesGlanceIcon",
		"FlockwatchTodayEggsGlanceIcon",
		"FlockwatchTodayFlockGlanceIcon",
		"FlockwatchTodayCashGlanceIcon",
		"CampaignSafeguardGlanceIcon",
		"FlockCompactGlanceIcon",
		"WorkToRuleGlanceIcon",
	]:
		glance_icons.append(office.find_child(icon_name, true, false))
	var orders_heading := office.find_child("CampaignOrdersHeading", true, false) as Label
	var objectives := office.find_child("CampaignObjectivesLabel", true, false) as Label
	var order_glances := office.find_children("CampaignOrderGlance*", "Label", true, false)
	var doctrine := office.find_child("CampaignActiveDoctrine", true, false) as Label
	var safeguards := office.find_child("CampaignSafeguardForecast", true, false) as Label
	var safeguard_glance := office.find_child("CampaignSafeguardGlance", true, false) as Label
	var labor := office.find_child("FlockLaborStatus", true, false) as Label
	var labor_grid := office.find_child("FlockLaborGlanceGrid", true, false) as GridContainer
	var compact_glance := office.find_child("FlockCompactGlance", true, false) as Label
	var work_rule_glance := office.find_child("WorkToRuleGlance", true, false) as Label
	var history := office.find_child("FlockwatchStatusHistory", true, false) as Label
	var history_toggle := office.find_child("FlockwatchStatusHistoryToggle", true, false) as Button
	var continue_button := office.find_child("ContinueDirectiveButton", true, false) as Button
	_check(
		[
			simulation, navigation, snapshot_panel, workload, clutch, flock,
			ledgers, workload_glance, clutch_glance, flock_glance, cash_glance, snapshot_heading,
			orders_heading, objectives, doctrine, safeguards, safeguard_glance,
			labor, labor_grid, compact_glance, work_rule_glance, history,
			history_toggle, continue_button,
		].all(func(value: Variant) -> bool: return value != null),
		"Office should compose the complete compact Today brief",
		failures,
	)
	_check(
		glance_icons.all(func(icon: Node) -> bool: return icon != null and bool(icon.get_meta("decorative", false))),
		"Today should use font-independent visual symbols while exact meanings stay on labels",
		failures,
	)
	if simulation == null or navigation == null:
		await _finish(office, store, failures)
		return
	var today_scroll := navigation.page_scroll(FlockwatchNavigation.PAGE_TODAY)
	for today_control: Control in [
		orders_heading, objectives, doctrine, safeguards, labor,
		safeguard_glance, labor_grid, snapshot_panel, workload, clutch, flock,
		ledgers, workload_glance, clutch_glance, flock_glance, cash_glance,
		history_toggle, history,
	]:
		_check(
			today_control != null and today_scroll.is_ancestor_of(today_control),
			"%s should remain inside Today's persistent scroll" % (
				today_control.name if today_control != null else "missing control"
			),
			failures,
		)
	_check(
		today_scroll.get_v_scroll_bar().max_value <= today_scroll.get_v_scroll_bar().page + 1.0,
		"opening Today should fit at 1280x720 without mandatory vertical scrolling",
		failures,
	)

	var snapshot := simulation.snapshot()
	var economic_briefing := snapshot.get("economic_briefing", {}) as Dictionary
	var economic_cash := economic_briefing.get("cash", {}) as Dictionary
	var spendable_cents := int(economic_cash.get("spendable_fund_cents", 0))
	var secured_margin_cents := int(economic_cash.get("secured_operating_margin_cents", 0))
	var break_even_remaining_cents := int(economic_cash.get("break_even_remaining_cents", 0))
	var morale_total := 0.0
	var workers := snapshot.get("workers", []) as Array
	for worker_value: Variant in workers:
		morale_total += float((worker_value as Dictionary).get("morale", 0.0))
	var expected_morale := int(morale_total / maxf(1.0, float(workers.size())))
	_check(
		workload != null and _contains_all(workload.text, [
			str(int(snapshot.get("claims_outstanding", snapshot.get("claims_waiting", 0)))),
			str(int(snapshot.get("claim_capacity", 18))),
			str(int(snapshot.get("overdue_claims", 0))),
			str(int(snapshot.get("intake_rejections_today", 0))),
			"LIVE", "OVERDUE", "TURNED AWAY",
		]),
		"workload row should preserve live, capacity, overdue, and rejected-claim measures",
		failures,
	)
	_check(
		clutch != null and _contains_all(clutch.text, [
			str(int(snapshot.get("eggs_today", 0))),
			str(int(snapshot.get("quota_target", 0))),
			str(int(snapshot.get("eggs_total", 0))),
			"TODAY", "CAREER EGGS",
		]),
		"clutch row should preserve today's output, target, and career egg total",
		failures,
	)
	_check(
		flock != null and _contains_all(flock.text, [
			"%d%% SPIRITS" % expected_morale,
			"%d%% UNITY RISK" % int(snapshot.get("solidarity", 0)),
		]),
		"flock row should preserve average morale and unity risk",
		failures,
	)
	_check(
		ledgers != null and _contains_all(ledgers.text, [
			"%d%% FARMER FAVOR" % int(snapshot.get("executive_confidence", 0)),
			"%d%% COOP OBEDIENCE" % int(snapshot.get("compliance", 0)),
		]),
		"ledger row should preserve farmer favor and coop obedience",
		failures,
	)
	_check(
		[workload, clutch, flock, ledgers].all(
			func(label: Label) -> bool: return not label.tooltip_text.is_empty()
		),
		"every exact snapshot row should retain explanatory detail",
		failures,
	)
	_check(
		[workload, clutch, flock, ledgers].all(
			func(label: Label) -> bool: return not label.visible
		),
		"the exact ledger rows should remain semantic detail instead of default prose",
		failures,
	)
	_check(
		workload_glance != null
		and _contains_all(workload_glance.text, ["0 LATE"])
		and "CASES" not in workload_glance.text
		and "TURNED AWAY" in String(workload_glance.get_meta("accessible_text", "")),
		"file icon tile should show load and lateness without repeating its noun",
		failures,
	)
	_check(
		clutch_glance != null
		and _contains_all(clutch_glance.text, [str(int(snapshot.get("quota_target", 0))), "TOTAL"])
		and "EGGS" not in clutch_glance.text
		and "CAREER EGGS" in clutch_glance.tooltip_text,
		"egg icon tile should show clutch progress while preserving the exact career total",
		failures,
	)
	_check(
		flock_glance != null
		and _contains_all(flock_glance.text, ["%d%%" % expected_morale, "RISK"])
		and "FLOCK" not in flock_glance.text
		and "UNITY RISK" in flock_glance.tooltip_text,
		"flock icon tile should show spirits and risk with exact meaning on inspection",
		failures,
	)
	_check(
		cash_glance != null
		and _contains_all(cash_glance.text, [
			"FREE $%s" % _compact_currency(spendable_cents),
			"NET %s" % _signed_currency(secured_margin_cents),
		])
		and "CASH" not in cash_glance.text
		and _contains_all(String(cash_glance.get_meta("accessible_text", "")), [
			"FARMER FAVOR", "COOP OBEDIENCE", "RESERVED", "NEED", "Secured net",
		])
		and int(cash_glance.get_meta("spendable_fund_cents", -1)) == spendable_cents
		and int(cash_glance.get_meta("secured_operating_margin_cents", 1)) == secured_margin_cents
		and int(cash_glance.get_meta("break_even_remaining_cents", -1)) == break_even_remaining_cents
		and StringName(cash_glance.get_meta("margin_state", &"")) == (
			&"deficit" if secured_margin_cents < 0 else &"cleared"
		),
		"coin icon tile should pair spendable money with live operating net and retain complete semantics",
		failures,
	)
	_check(
		orders_heading != null
		and orders_heading.text == "3 ACTIVE GOALS  ·  +9 SCORE"
		and _contains_all(String(orders_heading.get_meta("accessible_text", "")), [
			"All 3 goals are active",
			"clean sweep adds +3 more",
			"Select any goal card",
			"top HUD quota is a separate operating target",
		])
		and snapshot_heading != null and snapshot_heading.text == "NOW",
		"Today should identify every goal as active, disclose its score pool, and preserve goal-card navigation semantics",
		failures,
	)
	_check(
		_snapshot_glances_are_compact([
			workload_glance, clutch_glance, flock_glance, cash_glance,
		]),
		"the four always-visible status tiles should stay within an 18-character glance budget",
		failures,
	)

	var operating_cost := simulation.current_daily_operating_cost_cents()
	simulation.credited_today_cents = maxi(0, operating_cost - 100)
	office.call("_apply_snapshot_presentation", simulation.snapshot())
	await process_frame
	var milestones_before := _count_status_prefix(
		office.get("_status_history") as Array,
		"BREAK EVEN CLEARED",
	)
	simulation.credited_today_cents = operating_cost + 500
	office.call("_apply_snapshot_presentation", simulation.snapshot())
	await process_frame
	var milestones_after_crossing := _count_status_prefix(
		office.get("_status_history") as Array,
		"BREAK EVEN CLEARED",
	)
	var ticker := office.get("_ticker_label") as Label
	_check(
		cash_glance != null
		and _contains_all(cash_glance.text, ["NET +$5"])
		and StringName(cash_glance.get_meta("margin_state", &"")) == &"cleared"
		and navigation.last_feedback() == "BREAK EVEN CLEARED · NET +$5"
		and ticker != null
		and _contains_all(String(ticker.get_meta("accessible_text", "")), [
			"Secured income now covers today's complete filed operating cost",
			"can still change the margin",
			"Open Capital for the exact ledger",
		])
		and StringName(office.call("_status_priority", navigation.last_feedback())) == &"milestone"
		and milestones_after_crossing == milestones_before + 1,
		"crossing break-even should create one clear, semantic milestone and update the live margin tile",
		failures,
	)
	office.call("_apply_snapshot_presentation", simulation.snapshot())
	await process_frame
	_check(
		_count_status_prefix(
			office.get("_status_history") as Array,
			"BREAK EVEN CLEARED",
		) == milestones_after_crossing,
		"re-presenting a cleared ledger should not replay the break-even milestone",
		failures,
	)
	_check(
		order_glances.size() == 3
		and _order_glances_are_compact(order_glances),
		"three scored orders should be readable as two-line action and status tiles with exact hover detail",
		failures,
	)
	_check(
		_contains_all((order_glances[0] as Label).text, ["LAY", "EGGS", "LEFT"])
		and _contains_all((order_glances[1] as Label).text, ["CRACKS", "EGG 1", "PENDING"])
		and _contains_all((order_glances[2] as Label).text, ["WELFARE", "NOW", "SAFE"]),
		"goal tiles should state the player action, target, and live status without ledger shorthand",
		failures,
	)
	_check(
		_contains_all(navigation.accessible_text(), [
			"Visible filing", "LAY 18 EGGS", "EGG 1 PENDING", "WELFARE NEEDS 45",
		]),
		"Flockwatch narration should include the same live plan shown on Today's cards: %s" % navigation.accessible_text(),
		failures,
	)
	_check(
		objectives != null and not objectives.visible
		and safeguard_glance != null and safeguard_glance.is_visible_in_tree()
		and "SAFEGUARD" not in safeguard_glance.text
		and "NEEDS" in safeguard_glance.text
		and "-" not in safeguard_glance.text
		and "SAFEGUARD" in String(safeguard_glance.get_meta("accessible_text", ""))
		and safeguards != null and not safeguards.visible
		and "PROBATION FINAL TERMS" in safeguard_glance.tooltip_text,
		"orders and safeguard prose should collapse into glance tiles without losing final terms",
		failures,
	)

	var quiet_snapshot := snapshot.duplicate(true)
	quiet_snapshot["flock_compact"] = {}
	quiet_snapshot["flock_petition"] = {}
	quiet_snapshot["work_to_rule"] = {"active": false, "scheduled": false, "threshold": 45.0}
	office.call("_update_flock_labor_label", quiet_snapshot)
	_check(
		labor != null and not labor.visible and labor_grid != null and not labor_grid.visible,
		"quiet shifts should not reserve space for an empty labor filing",
		failures,
	)
	quiet_snapshot["flock_petition"] = {
		"sponsor_worker_name": "Mabel",
		"outcome": "Management filed a feed concession.",
	}
	office.call("_update_flock_labor_label", quiet_snapshot)
	_check(
		labor != null and not labor.visible
		and labor_grid != null and labor_grid.visible
		and compact_glance != null and compact_glance.is_visible_in_tree()
		and _contains_all(compact_glance.text, ["PETITION", "MABEL", "FILED"])
		and _contains_all(compact_glance.tooltip_text, ["LAST FLOCK PETITION", "MABEL"]),
		"a filed petition should restore a compact tile with its exact record on inspection",
		failures,
	)

	office.call("_record_status_copy", "TEST NOTICE ONE")
	office.call("_record_status_copy", "TEST NOTICE TWO")
	_check(
		history_toggle != null and not history_toggle.disabled
		and "SHOW SHIFT RECORD" in history_toggle.text
		and history != null and not history.visible,
		"recent notices should remain collapsed by default behind an enabled disclosure",
		failures,
	)
	if history_toggle != null:
		history_toggle.button_pressed = true
	await process_frame
	_check(
		history != null and history.visible
		and _contains_all(history.text, ["RECENT SHIFT RECORD", "TEST NOTICE TWO", "TEST NOTICE ONE"])
		and history_toggle != null and "HIDE SHIFT RECORD" in history_toggle.text,
		"expanding the disclosure should reveal the five-entry shift record in newest-first order",
		failures,
	)
	if history_toggle != null:
		history_toggle.button_pressed = false
	await process_frame
	_check(history != null and not history.visible, "collapsing the disclosure should return the brief to compact form", failures)

	_check(
		continue_button != null and continue_button.get_parent() == navigation.context_actions(),
		"required progression must remain in the global context-action host",
		failures,
	)
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	await process_frame
	_check(
		continue_button != null
		and continue_button.visible
		and continue_button.text == "CONTINUE: FILE SHIFT RESULTS",
		"ordinary review progression should name the shift results it actually opens",
		failures,
	)
	_check(
		continue_button != null
		and _contains_all(continue_button.tooltip_text, ["shift's results", "morning policy"])
		and continue_button.accessibility_name == continue_button.tooltip_text
		and String(continue_button.get_meta("accessible_text", "")) == continue_button.tooltip_text,
		"review progression should explain the exact next action through native and mirrored accessibility semantics",
		failures,
	)
	office.call("_on_review_requisitions_pressed")
	await process_frame
	var guidance_label := office.get("_guidance_label") as Label
	var guidance_action := office.find_child("GuidanceActionButton", true, false) as Button
	var review_next_action := office.call("_next_action_diagnostic_state") as Dictionary
	_check(
		guidance_label != null
		and guidance_action != null
		and guidance_label.text == continue_button.text
		and _contains_all(guidance_label.tooltip_text, [
			continue_button.text,
			continue_button.tooltip_text,
		])
		and StringName(guidance_action.get_meta("guidance_action_id", &"")) == &"flockwatch_context_action"
		and String(review_next_action.get("copy", "")) == continue_button.text
		and String(review_next_action.get("action_id", "")) == "flockwatch_context_action"
		and bool(review_next_action.get("actionable", false)),
		"requisition review should promote the exact reachable shift-results filing above the page deck",
		failures,
	)
	office.call("_on_guidance_action_pressed")
	await process_frame
	_check(
		root.gui_get_focus_owner() == continue_button,
		"global review activation should focus the docked Continue action instead of reopening Capital",
		failures,
	)
	var review_accessibility := String(office.call(
		"_web_accessibility_summary",
		simulation.snapshot(),
	))
	var review_announcement := office.call(
		"_web_accessibility_announcement",
		simulation.snapshot(),
		review_accessibility,
	) as Dictionary
	_check(
		_contains_all(review_accessibility, [
			"Required action: CONTINUE: FILE SHIFT RESULTS",
			"complete the required in-panel action",
		])
		and "close Flockwatch to return to the floor" not in review_accessibility,
		"assistive review summary should name the same required in-panel progression as the visible action",
		failures,
	)
	_check(
		String(review_announcement.get("kind", "")) == "flockwatch"
		and _contains_all(String(review_announcement.get("text", "")), [
			"Required action: CONTINUE: FILE SHIFT RESULTS",
			"complete it when ready",
		])
		and "close Flockwatch to return to the floor" not in String(review_announcement.get("text", "")),
		"Flockwatch live announcement should not tell nonvisual players to leave the required action",
		failures,
	)
	var scaled_preferences := (office.get("_player_preferences") as Dictionary).duplicate(true)
	scaled_preferences["ui_scale"] = 1.5
	office.set("_player_preferences", scaled_preferences)
	office.call("_apply_management_ui_preferences")
	await process_frame
	await process_frame
	var flockwatch_panel := office.find_child("FlockwatchLedger", true, false) as PanelContainer
	var continue_font := continue_button.get_theme_font("font") if continue_button != null else null
	var continue_font_size := continue_button.get_theme_font_size("font_size") if continue_button != null else 0
	var continue_copy_width := (
		continue_font.get_string_size(
			continue_button.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			continue_font_size,
		).x
		if continue_font != null and continue_button != null else
		INF
	)
	var continue_style := continue_button.get_theme_stylebox("normal") if continue_button != null else null
	var continue_horizontal_inset := (
		continue_style.get_content_margin(SIDE_LEFT) + continue_style.get_content_margin(SIDE_RIGHT)
		if continue_style != null else
		0.0
	)
	_check(
		continue_button != null
		and continue_button.is_visible_in_tree()
		and continue_copy_width <= continue_button.size.x - continue_horizontal_inset + 0.5,
		"150-percent review action should remain fully readable instead of relying on clipped text",
		failures,
	)
	_check(
		flockwatch_panel != null
		and flockwatch_panel.get_global_rect().encloses(continue_button.get_global_rect()),
		"150-percent review action should remain inside the bounded Flockwatch panel",
		failures,
	)
	scaled_preferences["ui_scale"] = 1.0
	office.set("_player_preferences", scaled_preferences)
	office.call("_apply_management_ui_preferences")
	await process_frame
	await process_frame
	var specialized_snapshot := simulation.snapshot()
	specialized_snapshot["credit_memo_pending"] = true
	specialized_snapshot["credit_memo_id"] = &"flock_restructuring"
	var specialized_action := office.call("_review_progression_action", specialized_snapshot) as Dictionary
	_check(
		String(specialized_action.get("button_text", "")) == "CONTINUE: OPEN RESTRUCTURING FILE"
		and "before this shift's report" in String(specialized_action.get("exact_detail", "")),
		"restructuring review should name its required intermediate file",
		failures,
	)
	specialized_snapshot["credit_memo_id"] = &"golden_egg_dossier"
	specialized_action = office.call("_review_progression_action", specialized_snapshot) as Dictionary
	_check(
		String(specialized_action.get("button_text", "")) == "CONTINUE: OPEN GOLDEN DOSSIER"
		and "before this shift's report" in String(specialized_action.get("exact_detail", "")),
		"golden credit review should name its required intermediate dossier",
		failures,
	)
	specialized_snapshot["credit_memo_id"] = &"ordinary_closing_credit"
	specialized_action = office.call("_review_progression_action", specialized_snapshot) as Dictionary
	_check(
		String(specialized_action.get("button_text", "")) == "CONTINUE: FILE CLOSING CREDIT"
		and "before this shift's report" in String(specialized_action.get("exact_detail", "")),
		"ordinary credit review should name the closing credit filing",
		failures,
	)
	specialized_snapshot["credit_memo_pending"] = false
	specialized_snapshot["credit_memo_id"] = &""
	office.set("_campaign_senior_roost", true)
	specialized_action = office.call("_review_progression_action", specialized_snapshot) as Dictionary
	_check(
		String(specialized_action.get("button_text", "")) == "CONTINUE: OPEN SENIOR REPORT"
		and "Senior Roost report" in String(specialized_action.get("exact_detail", "")),
		"Senior Roost review should name its quarterly report",
		failures,
	)
	office.set("_campaign_senior_roost", false)
	var campaign_state = office.get("_campaign_state")
	var previous_outcome: StringName = campaign_state.outcome
	campaign_state.outcome = CampaignState.OUTCOME_PASSED
	specialized_action = office.call("_review_progression_action", specialized_snapshot) as Dictionary
	_check(
		String(specialized_action.get("button_text", "")) == "CONTINUE: OPEN FINAL REVIEW"
		and "final review" in String(specialized_action.get("exact_detail", "")),
		"completed probation should name its final review",
		failures,
	)
	campaign_state.outcome = previous_outcome
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	navigation.set_show_all_filings(true)
	await process_frame
	_check(
		navigation.available_page_ids() == FlockwatchNavigation.PAGE_ORDER,
		"All Filings should preserve reachability of every management domain",
		failures,
	)
	for page_id: StringName in FlockwatchNavigation.PAGE_ORDER:
		_check(
			navigation.open_page(page_id) and navigation.page_scroll(page_id) != null,
			"%s should remain reachable through its existing page scroll" % String(page_id),
			failures,
		)
	await _finish(office, store, failures)


func _contains_all(text: String, fragments: Array[String]) -> bool:
	for fragment: String in fragments:
		if fragment not in text:
			return false
	return true


func _compact_currency(cents: int) -> String:
	return str(cents / 100) if cents % 100 == 0 else "%.2f" % (float(cents) / 100.0)


func _signed_currency(cents: int) -> String:
	return "%s$%s" % ["+" if cents >= 0 else "-", _compact_currency(absi(cents))]


func _count_status_prefix(entries: Array, prefix: String) -> int:
	var count := 0
	for entry: Variant in entries:
		if String(entry).begins_with(prefix):
			count += 1
	return count


func _order_glances_are_compact(glances: Array[Node]) -> bool:
	for node: Node in glances:
		if not node is Label:
			return false
		var glance := node as Label
		if (
			glance.text.count("\n") != 1
			or not ["DONE", "LEFT", "PENDING", "SAFE", "OVER", "NEED"].any(
				func(status: String) -> bool: return status in glance.text
			)
			or glance.tooltip_text.is_empty()
		):
			return false
	return true


func _snapshot_glances_are_compact(glances: Array) -> bool:
	for label_value: Variant in glances:
		var label := label_value as Label
		if label == null or label.text.count("\n") != 1 or label.text.length() > 18:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _finish(office: Office, store: Variant, failures: Array[String]) -> void:
	office.free()
	await process_frame
	store.delete()
	if not failures.is_empty():
		for failure: String in failures:
			push_error("FLOCKWATCH_TODAY_DENSITY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FLOCKWATCH_TODAY_DENSITY_TEST_PASSED orders=3 safeguards=1 metrics=4 labor=conditional exact=semantic history=collapsed pages=5")
	quit(0)


func _on_watchdog_timeout() -> void:
	push_error("FLOCKWATCH_TODAY_DENSITY_TEST_TIMEOUT")
	quit(1)
