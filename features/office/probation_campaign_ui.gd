class_name ProbationCampaignUI
extends Control

## Standalone presentation layer for the five-shift management probation.
##
## The component owns no campaign rules or persistence. Call [apply_snapshot]
## with a plain Dictionary and connect the intent signals below. Supported views
## are `title`, `active`, `between_shift`, `contract_board`, and `final`.

signal continue_campaign
signal new_campaign
signal abandon_campaign
signal review_requisitions
signal challenge_contract_changed(contract_id: StringName)
signal title_intake_phase_changed(phase: StringName)
signal milestone_choice(choice_id: StringName)
signal presentation_state_changed
signal report_filing_settled(reveal_key: String, instant: bool)
signal career_sponsorship_requested(worker_id: int, lane_id: StringName)
signal market_contract_sign_requested(
	offer_id: StringName,
	clause_id: StringName,
	pricing_profile_id: StringName,
)
signal market_contract_decline_requested

const ManagementTheme := preload("res://features/office/management_ui_theme.gd")
const CareerSponsorshipUIScript := preload("res://features/office/career_sponsorship_ui.gd")
const FarmMutualContractBoardUIScript := preload("res://features/office/farm_mutual_contract_board_ui.gd")
const MabelPortrait: Texture2D = preload("res://assets/npcs/mabel/portraits/mabel_portrait_anxious.png")

const VIEW_TITLE := &"title"
const VIEW_ACTIVE := &"active"
const VIEW_REPORT := &"between_shift"
const VIEW_CONTRACT_BOARD := &"contract_board"
const VIEW_FINAL := &"final"
const TITLE_PHASE_RESUME := &"resume"
const TITLE_PHASE_NEW_FILE := &"new_file"
const DEFAULT_TOTAL_DAYS := 5
const PROBATION_SCORE_LIMIT := 100
const PROBATION_PASS_THRESHOLD := 60
const MAX_BADGE_ORDER_SEGMENTS := 3
const MAX_BADGE_DAY_SEGMENTS := DEFAULT_TOTAL_DAYS
const REPORT_DESKTOP_WIDTH := 960.0
const REPORT_HEADING_DESKTOP_WIDTH := 340.0
const REPORT_CREDIT_DESKTOP_WIDTH := 560.0
const REPORT_HIGHLIGHT_DESKTOP_WIDTH := 300.0
const REPORT_STORY_FULL_HEIGHT := 96.0
const REPORT_STORY_COMPACT_HEIGHT := 76.0
const REPORT_REVEAL_DURATION := 0.13
const REPORT_REVEAL_STAGGER := 0.035
const REPORT_TOTAL_PULSE_SCALE := 1.035
const REPORT_TOTAL_PULSE_IN_DURATION := 0.08
const REPORT_TOTAL_PULSE_OUT_DURATION := 0.14
const REPORT_PROMOTION_STAMP_SCALE := 1.22
const REPORT_PROMOTION_STAMP_IN_DURATION := 0.06
const REPORT_PROMOTION_STAMP_OUT_DURATION := 0.10
const DEFAULT_CHALLENGE_CONTRACT_ID: StringName = &"standard_filing"
const DEFAULT_CHALLENGE_CONTRACT := {
	"id": "standard_filing",
	"label": "STANDARD FILING",
	"short_label": "STANDARD",
	"difficulty": "standard",
	"difficulty_label": "STANDARD",
	"difficulty_guidance": "The recommended authored balance for a first complete probation file.",
	"description": "The authored probation contract with the shipped balance of flock care, compliance, favor, and shell quality.",
	"opening_terms": {
		"feed_fund_cents": 5000,
		"quota_target": 16,
		"additional_claim_lanes": [],
		"pressure_label": "AUTHORED BASELINE",
	},
	"criteria": {
		"minimum_score": PROBATION_PASS_THRESHOLD,
		"minimum_welfare": 45,
		"minimum_compliance": 55,
		"minimum_farmer_favor": 50,
		"maximum_crack_rate_basis_points": 2500,
	},
}

const INK := Color("e9edf0")
const MUTED := Color("9eabb5")
const NAVY := Color("172630")
const NAVY_RAISED := Color("223541")
const BRASS := Color("d1a650")
const CREAM := Color("f4df9d")
const TEAL := Color("73b5a7")
const RUST := Color("c96f59")

var _snapshot: Dictionary = {
	"view": VIEW_ACTIVE,
	"day": 1,
	"total_days": DEFAULT_TOTAL_DAYS,
}
var _view: StringName = VIEW_ACTIVE
var _selected_milestone := &""
var _pending_milestone_confirmation := &""
var _selected_challenge_contract_id: StringName = DEFAULT_CHALLENGE_CONTRACT_ID
var _challenge_selector_syncing := false
var _title_new_file_setup := false
var _title_contract_terms_expanded := false
var _last_board_pulse_key := ""

var _day_badge: PanelContainer
var _active_badge_top := 120.0
var _badge_suppressed := false
var _status_label: Label
var _day_label: Label
var _day_progress_row: HBoxContainer
var _day_progress_segments: Array[PanelContainer] = []
var _order_progress_row: HBoxContainer
var _order_progress_label: Label
var _order_progress_segments: Array[PanelContainer] = []
var _live_orders_on_track := -1
var _live_orders_total := 0
var _live_order_context: StringName = &""
var _order_progress_seeded := false
var _order_progress_tween: Tween
var _report_reveal_tween: Tween
var _last_report_reveal_key := ""
var _reduced_motion := false
var _modal_host: Control
var _modal_scroll: ScrollContainer
var _modal_center: CenterContainer
var _title_panel: PanelContainer
var _report_panel: PanelContainer
var _final_panel: PanelContainer
var _title_heading: Label
var _title_description: Label
var _title_profile_card: PanelContainer
var _title_probation_summary: PanelContainer
var _title_actions: HFlowContainer
var _title_resume_card: PanelContainer
var _title_resume_heading: Label
var _title_resume_details: Label
var _title_challenge_card: PanelContainer
var _title_challenge_selector: OptionButton
var _title_challenge_summary: Label
var _title_opening_fund: Label
var _title_opening_quota: Label
var _title_opening_files: Label
var _title_challenge_terms_toggle: Button
var _title_challenge_detail: Label
var _title_new_button: Button
var _title_back_button: Button
var _report_score_row: HFlowContainer
var _report_heading_stack: VBoxContainer
var _report_story_row: HFlowContainer
var _report_ledger_row: HFlowContainer
var _report_actions: HFlowContainer
var _final_metrics: HFlowContainer
var _final_ledger_row: HFlowContainer
var _final_actions: HFlowContainer
var _final_sticky_action_bar: PanelContainer
var _final_sticky_primary_button: Button
var _final_sticky_leave_button: Button

var _continue_title_button: Button
var _report_requisitions_button: Button
var _report_shelve_button: Button
var _report_continue_button: Button
var _report_day_label: Label
var _report_heading_label: Label
var _report_heading_note: Label
var _report_score_receipt_grid: GridContainer
var _report_ledger_section_label: Label
var _report_score_label: Label
var _report_shift_delta_label: Label
var _report_shift_delta_icon: TextureRect
var _report_rank_label: Label
var _report_rank_icon: TextureRect
var _report_rank_progress: ProgressBar
var _report_ledger_labels: Array[Dictionary] = []
var _report_safeguard_panel: PanelContainer
var _report_safeguard_summary: Label
var _report_safeguard_grid: GridContainer
var _report_safeguard_rows: Array[Label] = []
var _report_safeguard_pass_grid: GridContainer
var _report_safeguard_pass_rows: Array[Label] = []
var _credit_memo_card: PanelContainer
var _credit_memo_label: Label
var _credit_memo_glance_strip: HFlowContainer
var _hen_highlight_card: PanelContainer
var _hen_highlight_eyebrow: Label
var _hen_highlight_headline: Label
var _hen_highlight_body: Label
var _hen_highlight_metric: Label
var _hen_highlight_glance_strip: HFlowContainer
var _objective_card: PanelContainer
var _objective_title_label: Label
var _objective_reward_badge: PanelContainer
var _objective_promotion_icon: TextureRect
var _objective_reward_label: Label
var _objective_body_label: Label
var _objective_order_strip: HFlowContainer
var _objective_driver_strip: HFlowContainer
var _objective_board_strip: HFlowContainer
var _objective_progress_label: Label
var _milestone_section: VBoxContainer
var _milestone_section_label: Label
var _milestone_buttons_host: HFlowContainer
var _milestone_hint_label: Label
var _milestone_buttons: Dictionary[StringName, Button] = {}
var _career_sponsorship_ui: CareerSponsorshipUI
var _contract_board_ui: FarmMutualContractBoardUI

var _final_verdict_label: Label
var _final_score_label: Label
var _final_rank_label: Label
var _final_message_label: Label
var _final_ending_glance_grid: GridContainer
var _final_ending_glance_tiles: Array[Dictionary] = []
var _final_ledger_labels: Array[Dictionary] = []
var _final_safeguard_panel: PanelContainer
var _final_safeguard_summary: Label
var _final_safeguard_grid: GridContainer
var _final_safeguard_rows: Array[Label] = []
var _final_continue_button: Button
var _final_new_button: Button

var _replacement_confirmation_host: Control
var _replacement_confirmation_panel: PanelContainer
var _replacement_confirmation_title: Label
var _replacement_confirmation_body: Label
var _replacement_confirmation_confirm: Button
var _replacement_confirmation_cancel: Button
var _replacement_confirmation_origin: Control


func _ready() -> void:
	name = "ProbationCampaignUI"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = ManagementTheme.create_theme()
	_build_day_badge()
	_build_modal_host()
	resized.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	_refresh()


## Replaces all presentation data. This method never mutates the caller's data.
func apply_snapshot(snapshot: Dictionary) -> void:
	_hide_campaign_replacement(false)
	_pending_milestone_confirmation = &""
	_snapshot = snapshot.duplicate(true)
	_view = _read_view(_snapshot)
	if _view == VIEW_TITLE:
		_title_new_file_setup = not _snapshot_continue_available()
		_title_contract_terms_expanded = false
	if _snapshot.has("selected_new_challenge_contract_id"):
		_selected_challenge_contract_id = StringName(String(
			_snapshot.get("selected_new_challenge_contract_id", DEFAULT_CHALLENGE_CONTRACT_ID)
		))
	elif _view != VIEW_TITLE:
		var active_contract := _challenge_contract_from_value(_snapshot.get("challenge_contract", {}))
		if not active_contract.is_empty():
			_selected_challenge_contract_id = StringName(String(active_contract.get(
				"id",
				DEFAULT_CHALLENGE_CONTRACT_ID,
			)))
	_selected_milestone = StringName(_snapshot.get(
		"selected_milestone",
		_snapshot.get("milestone_selected", &""),
	))
	_refresh()


## Shows the first-load campaign card. Continue remains visibly disabled when
## no resumable campaign exists.
func show_title(continue_available: bool = false) -> void:
	_hide_campaign_replacement(false)
	_pending_milestone_confirmation = &""
	_snapshot["view"] = VIEW_TITLE
	_snapshot["continue_available"] = continue_available
	_view = VIEW_TITLE
	_selected_milestone = &""
	_title_new_file_setup = not continue_available
	_title_contract_terms_expanded = false
	_refresh()


## Returns to the office while retaining the compact probation badge.
func show_active_campaign(snapshot: Dictionary = {}) -> void:
	_hide_campaign_replacement(false)
	_pending_milestone_confirmation = &""
	_merge_snapshot(snapshot)
	_snapshot["view"] = VIEW_ACTIVE
	_view = VIEW_ACTIVE
	_refresh()


func prewarm_hidden_surfaces() -> void:
	# These panels are built at startup but normally do not enter Chromium's
	# render/layout path until the first shift closes. Present them almost
	# transparently behind the opaque intake for two frames so that first use
	# does not combine Control layout, glyph setup, and a campaign transaction in
	# one visible frame.
	var controls: Array[Control] = []
	for candidate: Control in [
		_report_panel,
		_final_panel,
		_final_sticky_action_bar,
		_contract_board_ui,
	]:
		if candidate != null:
			controls.append(candidate)
	var states: Array[Dictionary] = []
	for control: Control in controls:
		states.append({
			"visible": control.visible,
			"modulate": control.modulate,
			"mouse_filter": control.mouse_filter,
		})
		control.modulate.a = 0.001
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		control.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	for index: int in controls.size():
		var control := controls[index]
		var state := states[index]
		control.visible = bool(state["visible"])
		control.modulate = state["modulate"] as Color
		control.mouse_filter = int(state["mouse_filter"])


## Opens the intentional between-shift report modal.
func show_between_shift_report(snapshot: Dictionary = {}) -> void:
	_hide_campaign_replacement(false)
	_pending_milestone_confirmation = &""
	_merge_snapshot(snapshot)
	_snapshot["view"] = VIEW_REPORT
	_view = VIEW_REPORT
	_selected_milestone = StringName(_snapshot.get(
		"selected_milestone",
		_snapshot.get("milestone_selected", &""),
	))
	_refresh()


## Opens the sequential Farm Mutual planning file after the closing report and
## before the morning directive. The child consumes the canonical board snapshot.
func show_contract_board(snapshot: Dictionary = {}) -> void:
	_hide_campaign_replacement(false)
	_pending_milestone_confirmation = &""
	_merge_snapshot(snapshot)
	_snapshot["view"] = VIEW_CONTRACT_BOARD
	_view = VIEW_CONTRACT_BOARD
	if _contract_board_ui != null:
		_contract_board_ui.apply_snapshot(_snapshot)
	_refresh()


## Opens the final pass/fail campaign review.
func show_final_review(snapshot: Dictionary = {}) -> void:
	_hide_campaign_replacement(false)
	_pending_milestone_confirmation = &""
	_merge_snapshot(snapshot)
	_snapshot["view"] = VIEW_FINAL
	_view = VIEW_FINAL
	_refresh()


func hide_modal() -> void:
	show_active_campaign()


func is_modal_open() -> bool:
	return _view != VIEW_ACTIVE


func modal_state() -> StringName:
	return _view


func selected_milestone_id() -> StringName:
	return _selected_milestone


## Presentation-only new-file choice. The authoritative campaign owner reads
## this stable ID when the unchanged zero-argument new_campaign signal fires.
func selected_challenge_contract_id() -> StringName:
	return _selected_challenge_contract_id


func title_intake_phase() -> StringName:
	if _view != VIEW_TITLE:
		return &""
	return TITLE_PHASE_NEW_FILE if _title_new_file_setup else TITLE_PHASE_RESUME


func campaign_snapshot() -> Dictionary:
	var result := _snapshot.duplicate(true)
	var confirmation := _pending_milestone_confirmation_snapshot()
	if not confirmation.is_empty():
		result["pending_milestone_confirmation"] = confirmation
	return result


## A concise semantic mirror for the canvas-only campaign surfaces. Visible
## final cards stay glance-first while this string retains the authored coda
## and every exact filing comparison for assistive browser clients.
func accessible_text() -> String:
	if _view == VIEW_FINAL:
		var parts: Array[String] = []
		if _final_verdict_label != null:
			parts.append(_final_verdict_label.text)
		for tile: Dictionary in _final_ending_glance_tiles:
			var caption := tile.get("caption") as Label
			var value := tile.get("value") as Label
			if caption != null and value != null:
				parts.append("%s: %s" % [caption.text, value.text])
		if _final_message_label != null and not _final_message_label.text.is_empty():
			parts.append(_final_message_label.text)
		if _final_score_label != null and _final_rank_label != null:
			parts.append("Final score %s. Final rank %s." % [
				_final_score_label.text,
				_final_rank_label.text,
			])
		if _final_safeguard_panel != null and not _final_safeguard_panel.tooltip_text.is_empty():
			parts.append(_final_safeguard_panel.tooltip_text)
		parts.append(
			"Objective: enter the Senior Roost if approved, retry probation if held, or shelve the file."
		)
		return "\n".join(parts)
	return "Probation management file, %s." % String(_view).replace("_", " ")


## Updates only the presentation badge from an authoritative live projection.
## A new day/quarter seeds quietly; later aggregate changes return their signed
## delta so Office can play one semantic cue without duplicating campaign rules.
func set_live_order_progress(on_track: int, total: int, context: StringName) -> int:
	var sanitized_total := clampi(total, 0, MAX_BADGE_ORDER_SEGMENTS)
	var sanitized_on_track := clampi(on_track, 0, sanitized_total)
	if sanitized_total <= 0:
		_live_orders_on_track = -1
		_live_orders_total = 0
		_live_order_context = context
		_order_progress_seeded = false
		_snapshot["live_orders_on_track"] = 0
		_snapshot["live_orders_total"] = 0
		_snapshot["live_order_context"] = String(context)
		_refresh_live_order_badge()
		return 0
	var same_context := _order_progress_seeded and context == _live_order_context
	var delta := sanitized_on_track - _live_orders_on_track if same_context else 0
	var changed := (
		not same_context
		or sanitized_on_track != _live_orders_on_track
		or sanitized_total != _live_orders_total
	)
	_live_orders_on_track = sanitized_on_track
	_live_orders_total = sanitized_total
	_live_order_context = context
	_order_progress_seeded = true
	_snapshot["live_orders_on_track"] = sanitized_on_track
	_snapshot["live_orders_total"] = sanitized_total
	_snapshot["live_order_context"] = String(context)
	if changed:
		_refresh_live_order_badge()
		if delta != 0 and _view == VIEW_ACTIVE:
			_pulse_live_order_badge(delta > 0)
	return delta


func live_order_progress() -> Dictionary:
	return {
		"on_track": maxi(0, _live_orders_on_track),
		"total": _live_orders_total,
		"context": String(_live_order_context),
		"visible": _order_progress_row != null and _order_progress_row.visible,
	}


func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if _reduced_motion and _order_progress_tween != null and _order_progress_tween.is_valid():
		_order_progress_tween.kill()
	if _reduced_motion and _report_reveal_tween != null and _report_reveal_tween.is_valid():
		_report_reveal_tween.kill()
		_set_report_reveal_controls_settled("instant")
		_set_report_total_pulse_settled("instant")
		_set_report_promotion_stamp_settled("instant")
		if _view == VIEW_REPORT and not _last_report_reveal_key.is_empty():
			report_filing_settled.emit(_last_report_reveal_key, true)
	if _day_badge != null:
		_day_badge.modulate = Color.WHITE


func contract_board_ui() -> FarmMutualContractBoardUI:
	return _contract_board_ui


## Keeps the compact active-file badge aligned with Office's adaptive HUD and
## lets focused drawers/modals suppress it without changing campaign state.
func set_badge_presentation(active_top: float, suppressed: bool) -> void:
	var sanitized_top := maxf(0.0, active_top)
	if is_equal_approx(_active_badge_top, sanitized_top) and _badge_suppressed == suppressed:
		return
	_active_badge_top = sanitized_top
	_badge_suppressed = suppressed
	if _day_badge != null:
		_refresh_day_badge_visibility()
		_position_badge(_view != VIEW_ACTIVE)


func active_badge_top() -> float:
	return _active_badge_top


func is_badge_suppressed() -> bool:
	return _badge_suppressed


func _refresh_day_badge_visibility() -> void:
	if _day_badge == null:
		return
	var report_owns_context := _view == VIEW_REPORT and _is_senior_snapshot()
	_day_badge.visible = not _badge_suppressed and not report_owns_context
	_day_badge.set_meta("suppressed_by_report", report_owns_context)


func _merge_snapshot(snapshot: Dictionary) -> void:
	for key: Variant in snapshot:
		_snapshot[key] = snapshot[key]


func _build_day_badge() -> void:
	_day_badge = PanelContainer.new()
	_day_badge.name = "ProbationDayBadge"
	_day_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_day_badge.offset_left = -490.0
	_day_badge.offset_top = 120.0
	_day_badge.offset_right = -268.0
	_day_badge.offset_bottom = 164.0
	_day_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_day_badge.z_index = 20
	_day_badge.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("16242d"), Color("9e824d"), 8, 1),
	)
	add_child(_day_badge)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_day_badge.add_child(margin)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 1)
	margin.add_child(stack)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	stack.add_child(row)
	_status_label = _make_label("PROBATION", 11, BRASS)
	_status_label.name = "ProbationStatusLabel"
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(_status_label)
	_day_label = _make_label("DAY 1 / 5", 15, CREAM)
	_day_label.name = "ProbationDayLabel"
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_day_label)
	_day_progress_row = HBoxContainer.new()
	_day_progress_row.name = "ProbationDayProgressRail"
	_day_progress_row.mouse_filter = Control.MOUSE_FILTER_STOP
	_day_progress_row.add_theme_constant_override("separation", 4)
	stack.add_child(_day_progress_row)
	for index in range(MAX_BADGE_DAY_SEGMENTS):
		var segment := PanelContainer.new()
		segment.name = "ProbationDaySegment%d" % (index + 1)
		segment.custom_minimum_size = Vector2(24.0, 5.0)
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.mouse_filter = Control.MOUSE_FILTER_STOP
		_day_progress_row.add_child(segment)
		_day_progress_segments.append(segment)
	_order_progress_row = HBoxContainer.new()
	_order_progress_row.name = "ProbationOrderProgressRow"
	_order_progress_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_order_progress_row.add_theme_constant_override("separation", 4)
	stack.add_child(_order_progress_row)
	_order_progress_label = _make_label("ON TRACK 0 / 3", 9, MUTED)
	_order_progress_label.name = "ProbationOrderProgressLabel"
	_order_progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_order_progress_row.add_child(_order_progress_label)
	for index in range(MAX_BADGE_ORDER_SEGMENTS):
		var segment := PanelContainer.new()
		segment.name = "ProbationOrderStamp%d" % (index + 1)
		segment.custom_minimum_size = Vector2(24.0, 5.0)
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_order_progress_row.add_child(segment)
		_order_progress_segments.append(segment)
	_refresh_live_order_badge()
	_refresh_day_progress_rail(1, DEFAULT_TOTAL_DAYS, "DAY 1 / 5")


func _refresh_day_progress_rail(day: int, total_days: int, exact_day_text: String) -> void:
	if _day_progress_row == null:
		return
	var show_rail := not _is_senior_snapshot() and total_days == DEFAULT_TOTAL_DAYS
	_day_progress_row.visible = show_rail
	_day_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_day_label.tooltip_text = exact_day_text
	_day_label.set_meta("accessible_text", exact_day_text)
	_day_label.set_meta("segment_progress", show_rail)
	_day_progress_row.tooltip_text = exact_day_text
	_day_progress_row.set_meta("accessible_text", exact_day_text)
	_day_progress_row.set_meta("current_day", day)
	_day_progress_row.set_meta("total_days", total_days)
	for index in range(_day_progress_segments.size()):
		var segment := _day_progress_segments[index]
		var segment_day := index + 1
		segment.visible = show_rail and segment_day <= total_days
		if not segment.visible:
			continue
		var state := "current" if segment_day == day else (
			"complete" if segment_day < day else "upcoming"
		)
		segment.tooltip_text = "%s  //  SHIFT %d %s" % [
			exact_day_text,
			segment_day,
			state.to_upper(),
		]
		segment.set_meta("day", segment_day)
		segment.set_meta("state", state)
		segment.set_meta("accessible_text", segment.tooltip_text)
		segment.add_theme_stylebox_override(
			"panel",
			_panel_style(
				Color("54451f") if state == "current" else (
					Color("315f58") if state == "complete" else Color("263640")
				),
				BRASS if state == "current" else (
					Color("91c8bb") if state == "complete" else Color("50666c")
				),
				2,
				1,
			),
		)


func _refresh_live_order_badge() -> void:
	if _order_progress_row == null or _order_progress_label == null:
		return
	var visible_progress := _view == VIEW_ACTIVE and _live_orders_total > 0
	_order_progress_row.visible = visible_progress
	if not visible_progress:
		return
	var on_track := clampi(_live_orders_on_track, 0, _live_orders_total)
	# These are live projections, not completed orders. Calling them "ORDERS"
	# beside filled segments made safe opening metrics look pre-awarded. Keep the
	# closing report as the only place that presents an order as filed.
	_order_progress_label.text = "ON TRACK  %d / %d" % [on_track, _live_orders_total]
	_order_progress_label.add_theme_color_override(
		"font_color",
		TEAL if on_track == _live_orders_total else (RUST if on_track == 0 else CREAM),
	)
	_order_progress_label.tooltip_text = (
		"LIVE ESTIMATE  //  %d of %d orders are currently on track. Nothing is filed until review. Closing metrics can still move; open Flockwatch for exact targets and rewards."
		% [on_track, _live_orders_total]
	)
	for index in range(_order_progress_segments.size()):
		var segment := _order_progress_segments[index]
		var active := index < on_track
		var relevant := index < _live_orders_total
		segment.visible = relevant
		if not relevant:
			continue
		segment.add_theme_stylebox_override(
			"panel",
			_panel_style(
				Color("315f58") if active else Color("263640"),
				Color("91c8bb") if active else Color("8a5f59"),
				2,
				1,
			),
		)


func _pulse_live_order_badge(improved: bool) -> void:
	if _day_badge == null:
		return
	if _order_progress_tween != null and _order_progress_tween.is_valid():
		_order_progress_tween.kill()
	_day_badge.modulate = Color.WHITE
	if _reduced_motion:
		return
	_day_badge.modulate = Color("c8f0df") if improved else Color("f5c2b5")
	_order_progress_tween = create_tween()
	_order_progress_tween.set_trans(Tween.TRANS_QUAD)
	_order_progress_tween.set_ease(Tween.EASE_OUT)
	_order_progress_tween.tween_property(_day_badge, "modulate", Color.WHITE, 0.48)


func _build_modal_host() -> void:
	_modal_host = Control.new()
	_modal_host.name = "ProbationModalHost"
	_modal_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_host.z_index = 10
	add_child(_modal_host)

	var scrim := ColorRect.new()
	scrim.name = "ProbationModalScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.012, 0.024, 0.033, 0.88)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_host.add_child(scrim)

	_modal_scroll = ScrollContainer.new()
	_modal_scroll.name = "ProbationModalScroll"
	_modal_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_scroll.offset_left = 18.0
	_modal_scroll.offset_top = 66.0
	_modal_scroll.offset_right = -18.0
	_modal_scroll.offset_bottom = -18.0
	_modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_modal_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_modal_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_modal_host.add_child(_modal_scroll)

	_modal_center = CenterContainer.new()
	_modal_center.name = "ProbationModalCenter"
	_modal_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_modal_center.mouse_filter = Control.MOUSE_FILTER_PASS
	_modal_scroll.add_child(_modal_center)

	_build_title_panel(_modal_center)
	_build_report_panel(_modal_center)
	_build_final_panel(_modal_center)
	_build_final_sticky_action_bar()
	_contract_board_ui = FarmMutualContractBoardUIScript.new() as FarmMutualContractBoardUI
	_contract_board_ui.name = "FarmMutualContractBoardUI"
	_contract_board_ui.visible = false
	_contract_board_ui.contract_sign_requested.connect(_on_market_contract_sign_requested)
	_contract_board_ui.decline_requested.connect(_on_market_contract_decline_requested)
	_contract_board_ui.continue_requested.connect(_on_continue_campaign_pressed)
	_modal_host.add_child(_contract_board_ui)
	_build_replacement_confirmation()


func _build_title_panel(parent: Control) -> void:
	_title_panel = PanelContainer.new()
	_title_panel.name = "CampaignTitlePanel"
	_title_panel.custom_minimum_size = Vector2(760.0, 0.0)
	_title_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(NAVY, Color("ad8a4a"), 15, 2),
	)
	parent.add_child(_title_panel)

	var content := _panel_content(_title_panel, 28, 14, 8)
	var eyebrow := _make_label("YOUR FIRST COOP FILE", 12, BRASS)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(eyebrow)
	_title_heading = _make_label("MEET MABEL", 30, CREAM)
	_title_heading.name = "CampaignTitle"
	_title_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_title_heading)
	_title_description = _make_label(
		"Pick a difficulty. Start shift one.",
		15,
		Color("c4d0d4"),
	)
	_title_description.name = "CampaignTitleDescription"
	_title_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_title_description)

	_title_profile_card = PanelContainer.new()
	_title_profile_card.name = "MabelProfileCard"
	_title_profile_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1d3039"), Color("48616a"), 9, 1),
	)
	content.add_child(_title_profile_card)
	var profile := HBoxContainer.new()
	profile.add_theme_constant_override("separation", 16)
	profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var profile_margin := MarginContainer.new()
	profile_margin.add_theme_constant_override("margin_left", 14)
	profile_margin.add_theme_constant_override("margin_right", 18)
	profile_margin.add_theme_constant_override("margin_top", 6)
	profile_margin.add_theme_constant_override("margin_bottom", 6)
	profile_margin.add_child(profile)
	_title_profile_card.add_child(profile_margin)
	var portrait_frame := PanelContainer.new()
	portrait_frame.name = "CampaignMabelPortraitFrame"
	portrait_frame.custom_minimum_size = Vector2(82.0, 82.0)
	portrait_frame.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("15262f"), BRASS, 46, 2),
	)
	profile.add_child(portrait_frame)
	var portrait_margin := MarginContainer.new()
	portrait_margin.add_theme_constant_override("margin_left", 5)
	portrait_margin.add_theme_constant_override("margin_right", 5)
	portrait_margin.add_theme_constant_override("margin_top", 5)
	portrait_margin.add_theme_constant_override("margin_bottom", 5)
	portrait_frame.add_child(portrait_margin)
	var portrait := TextureRect.new()
	portrait.name = "CampaignMabelPortrait"
	portrait.texture = MabelPortrait
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_margin.add_child(portrait)
	var profile_copy := VBoxContainer.new()
	profile_copy.add_theme_constant_override("separation", 3)
	profile_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	profile.add_child(profile_copy)
	var identity := _make_label("MABEL  //  JUNIOR CLAIMS HEN", 15, CREAM)
	identity.name = "CampaignMabelIdentity"
	identity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile_copy.add_child(identity)
	var traits := _make_label("APPEALS SPECIALIST  ·  SAVES FEED", 12, TEAL)
	traits.name = "CampaignMabelTraits"
	traits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile_copy.add_child(traits)
	var quote := _make_label("\"The farmer remembers the basket, not the beak that filled it.\"", 14, INK)
	quote.name = "CampaignMabelQuote"
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile_copy.add_child(quote)

	_title_challenge_card = PanelContainer.new()
	_title_challenge_card.name = "ChallengeContractCard"
	_title_challenge_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1b2d36"), Color("6d8e86"), 9, 1),
	)
	content.add_child(_title_challenge_card)
	var challenge_content := _panel_content(_title_challenge_card, 16, 8, 4)
	var challenge_header := HFlowContainer.new()
	challenge_header.name = "ChallengeContractHeader"
	challenge_header.add_theme_constant_override("h_separation", 12)
	challenge_header.add_theme_constant_override("v_separation", 6)
	challenge_content.add_child(challenge_header)
	var challenge_label := _make_label("DIFFICULTY", 11, TEAL)
	challenge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	challenge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	challenge_label.custom_minimum_size.x = 210.0
	challenge_header.add_child(challenge_label)
	_title_challenge_selector = OptionButton.new()
	_title_challenge_selector.name = "ChallengeContractSelector"
	_title_challenge_selector.fit_to_longest_item = false
	_title_challenge_selector.clip_text = true
	_title_challenge_selector.custom_minimum_size = Vector2(250.0, 40.0)
	_title_challenge_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_challenge_selector.focus_mode = Control.FOCUS_ALL
	_title_challenge_selector.theme_type_variation = &"DecisionChoiceButton"
	_title_challenge_selector.item_selected.connect(_on_challenge_contract_selected)
	challenge_header.add_child(_title_challenge_selector)
	_title_challenge_summary = _make_label("", 11, MUTED)
	_title_challenge_summary.name = "ChallengeContractSummary"
	_title_challenge_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_challenge_summary.max_lines_visible = 3
	_title_challenge_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title_challenge_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_challenge_summary.mouse_filter = Control.MOUSE_FILTER_STOP
	challenge_content.add_child(_title_challenge_summary)
	var opening_glance := HFlowContainer.new()
	opening_glance.name = "ChallengeOpeningGlance"
	opening_glance.alignment = FlowContainer.ALIGNMENT_CENTER
	opening_glance.add_theme_constant_override("h_separation", 8)
	opening_glance.add_theme_constant_override("v_separation", 8)
	challenge_content.add_child(opening_glance)
	_title_opening_fund = _make_metric("ChallengeOpeningFund", "$50", "FEED FUND", 150.0, 19)
	_title_opening_quota = _make_metric("ChallengeOpeningQuota", "16", "EGG QUOTA", 150.0, 19)
	_title_opening_files = _make_metric("ChallengeOpeningFiles", "6", "OPEN FILES", 150.0, 19)
	for metric in [_title_opening_fund, _title_opening_quota, _title_opening_files]:
		_metric_panel(metric).custom_minimum_size.y = 52.0
		opening_glance.add_child(_metric_panel(metric))
	_title_challenge_terms_toggle = _make_button(
		"ChallengeContractTermsToggle",
		"RULES  [T]",
		&"DecisionChoiceButton",
	)
	_title_challenge_terms_toggle.custom_minimum_size = Vector2(220.0, 34.0)
	_title_challenge_terms_toggle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_title_challenge_terms_toggle.toggle_mode = true
	_title_challenge_terms_toggle.shortcut = _shortcut(KEY_T)
	_title_challenge_terms_toggle.pressed.connect(_on_challenge_contract_terms_toggled)
	challenge_content.add_child(_title_challenge_terms_toggle)
	_title_challenge_detail = _make_label("", 11, INK)
	_title_challenge_detail.name = "ChallengeContractDetail"
	_title_challenge_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_challenge_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_challenge_detail.mouse_filter = Control.MOUSE_FILTER_STOP
	_title_challenge_detail.visible = false
	challenge_content.add_child(_title_challenge_detail)

	_title_probation_summary = PanelContainer.new()
	_title_probation_summary.name = "ProbationFiveShiftSummary"
	_title_probation_summary.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1a2932"), Color("665b42"), 7, 1),
	)
	content.add_child(_title_probation_summary)
	var probation_content := _panel_content(_title_probation_summary, 15, 6, 3)
	var probation_heading := _make_label("YOUR RUN", 11, BRASS)
	probation_heading.name = "ProbationFiveShiftHeading"
	probation_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	probation_content.add_child(probation_heading)
	var journey := HFlowContainer.new()
	journey.name = "ProbationJourney"
	journey.alignment = FlowContainer.ALIGNMENT_CENTER
	journey.add_theme_constant_override("h_separation", 8)
	journey.add_theme_constant_override("v_separation", 8)
	probation_content.add_child(journey)
	for metric in [
		_make_metric("ProbationJourneyFile", "1 FILE", "PAIR UP", 175.0, 18),
		_make_metric("ProbationJourneyShifts", "5 SHIFTS", "PROVE IT", 175.0, 18),
		_make_metric("ProbationJourneyReview", "REVIEW", "FINISH", 175.0, 18),
	]:
		_metric_panel(metric).custom_minimum_size.y = 52.0
		journey.add_child(_metric_panel(metric))
	var probation_detail := _make_label("REPORT AFTER EACH SHIFT", 10, Color("d4c38f"))
	probation_detail.name = "ProbationFiveShiftDetail"
	probation_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	probation_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	probation_content.add_child(probation_detail)

	_title_resume_card = PanelContainer.new()
	_title_resume_card.name = "CampaignResumeCard"
	_title_resume_card.visible = false
	_title_resume_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("20343d"), Color("6d8e86"), 8, 1),
	)
	content.add_child(_title_resume_card)
	var resume_content := _panel_content(_title_resume_card, 16, 9, 3)
	_title_resume_heading = _make_label("SAVED COOP FILE CANDIDATE", 12, TEAL)
	_title_resume_heading.name = "CampaignResumeHeading"
	_title_resume_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_resume_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resume_content.add_child(_title_resume_heading)
	_title_resume_details = _make_label("", 11, INK)
	_title_resume_details.name = "CampaignResumeDetails"
	_title_resume_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_resume_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resume_content.add_child(_title_resume_details)

	_title_actions = HFlowContainer.new()
	_title_actions.name = "CampaignTitleActions"
	_title_actions.alignment = FlowContainer.ALIGNMENT_CENTER
	_title_actions.add_theme_constant_override("h_separation", 12)
	_title_actions.add_theme_constant_override("v_separation", 10)
	content.add_child(_title_actions)
	_continue_title_button = _make_button("ContinueCampaignButton", "CONTINUE SAVED FILE  [C]", &"PrimaryButton")
	_continue_title_button.custom_minimum_size = Vector2(260.0, 48.0)
	_continue_title_button.shortcut = _shortcut(KEY_C)
	_continue_title_button.pressed.connect(_on_continue_campaign_pressed)
	_title_actions.add_child(_continue_title_button)
	_title_new_button = _make_button("NewCampaignButton", "START SHIFT 1  [N]", &"PrimaryButton")
	_title_new_button.custom_minimum_size = Vector2(270.0, 44.0)
	_title_new_button.shortcut = _shortcut(KEY_N)
	_title_new_button.pressed.connect(_on_new_campaign_pressed)
	_title_actions.add_child(_title_new_button)
	_title_back_button = _make_button(
		"BackToSavedCampaignButton",
		"BACK TO SAVED FILE  [B]",
		&"DecisionChoiceButton",
	)
	_title_back_button.custom_minimum_size = Vector2(230.0, 48.0)
	_title_back_button.shortcut = _shortcut(KEY_B)
	_title_back_button.pressed.connect(_on_title_back_pressed)
	_title_actions.add_child(_title_back_button)


func _build_report_panel(parent: Control) -> void:
	_report_panel = PanelContainer.new()
	_report_panel.name = "ProbationReportPanel"
	_report_panel.custom_minimum_size = Vector2(REPORT_DESKTOP_WIDTH, 0.0)
	_report_panel.focus_mode = Control.FOCUS_ALL
	_report_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(NAVY, Color("ad8a4a"), 15, 2),
	)
	parent.add_child(_report_panel)

	# Reports routinely combine receipts, policy cards, and action controls. A
	# restrained vertical rhythm keeps the complete decision gate visible at the
	# reference 1440x900 Web viewport without removing any authored detail.
	var content := _panel_content(_report_panel, 26, 14, 6)
	_report_day_label = _make_label("SHIFT 1 RESULTS", 12, BRASS)
	_report_day_label.name = "ProbationReportDay"
	_report_day_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_report_day_label)

	_report_score_row = HFlowContainer.new()
	_report_score_row.name = "ProbationReportScoreRow"
	_report_score_row.add_theme_constant_override("h_separation", 18)
	_report_score_row.add_theme_constant_override("v_separation", 8)
	content.add_child(_report_score_row)
	_report_heading_stack = VBoxContainer.new()
	_report_heading_stack.custom_minimum_size.x = REPORT_HEADING_DESKTOP_WIDTH
	_report_heading_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_report_heading_stack.add_theme_constant_override("separation", 2)
	_report_score_row.add_child(_report_heading_stack)
	_report_heading_label = _make_label("FARMER'S SHIFT ASSESSMENT", 23, CREAM)
	_report_heading_label.name = "ProbationReportTitle"
	_report_heading_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_report_heading_stack.add_child(_report_heading_label)
	_report_heading_note = _make_label(
		"Cumulative results follow you through all five shifts.",
		13,
		MUTED,
	)
	_report_heading_note.name = "ReportScoreReceiptSummary"
	_report_heading_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_report_heading_note.mouse_filter = Control.MOUSE_FILTER_STOP
	_report_heading_stack.add_child(_report_heading_note)
	_report_score_receipt_grid = GridContainer.new()
	_report_score_receipt_grid.name = "ReportScoreReceiptGrid"
	_report_score_receipt_grid.columns = 5
	_report_score_receipt_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_report_score_receipt_grid.add_theme_constant_override("h_separation", 4)
	_report_score_receipt_grid.add_theme_constant_override("v_separation", 4)
	_report_score_receipt_grid.visible = false
	_report_heading_stack.add_child(_report_score_receipt_grid)
	_report_score_label = _make_metric("ReportScore", "0", "SCORE", 132.0)
	_report_score_row.add_child(_metric_panel(_report_score_label))
	_report_shift_delta_label = _make_metric("ReportShiftDelta", "+0", "THIS SHIFT", 126.0)
	_decorate_shift_delta_metric()
	_report_score_row.add_child(_metric_panel(_report_shift_delta_label))
	_report_rank_label = _make_metric("ReportRank", "UNRANKED", "RANK", 236.0, 14, true)
	_decorate_report_rank_metric()
	_report_score_row.add_child(_metric_panel(_report_rank_label))

	content.add_child(HSeparator.new())
	_report_story_row = HFlowContainer.new()
	_report_story_row.name = "ReportShiftStories"
	_report_story_row.add_theme_constant_override("h_separation", 10)
	_report_story_row.add_theme_constant_override("v_separation", 8)
	content.add_child(_report_story_row)
	_credit_memo_card = PanelContainer.new()
	_credit_memo_card.name = "FiledCreditMemoCard"
	_credit_memo_card.custom_minimum_size = Vector2(
		REPORT_CREDIT_DESKTOP_WIDTH,
		REPORT_STORY_FULL_HEIGHT,
	)
	_credit_memo_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_credit_memo_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("20333a"), Color("8b7444"), 8, 1),
	)
	_report_story_row.add_child(_credit_memo_card)
	var credit_margin := MarginContainer.new()
	credit_margin.add_theme_constant_override("margin_left", 14)
	credit_margin.add_theme_constant_override("margin_right", 14)
	credit_margin.add_theme_constant_override("margin_top", 8)
	credit_margin.add_theme_constant_override("margin_bottom", 8)
	_credit_memo_card.add_child(credit_margin)
	_credit_memo_label = _make_label("CREDIT MEMO AWAITING FILE", 12, CREAM)
	_credit_memo_label.name = "FiledCreditMemoLabel"
	_credit_memo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_credit_memo_label.max_lines_visible = 4
	_credit_memo_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_credit_memo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_credit_memo_label.mouse_filter = Control.MOUSE_FILTER_STOP
	var credit_stack := VBoxContainer.new()
	credit_stack.add_theme_constant_override("separation", 4)
	credit_margin.add_child(credit_stack)
	credit_stack.add_child(_credit_memo_label)
	_credit_memo_glance_strip = HFlowContainer.new()
	_credit_memo_glance_strip.name = "FiledCreditMemoGlanceStrip"
	_credit_memo_glance_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_credit_memo_glance_strip.add_theme_constant_override("h_separation", 5)
	_credit_memo_glance_strip.add_theme_constant_override("v_separation", 4)
	_credit_memo_glance_strip.visible = false
	credit_stack.add_child(_credit_memo_glance_strip)

	_hen_highlight_card = PanelContainer.new()
	_hen_highlight_card.name = "ShiftHenHighlightCard"
	_hen_highlight_card.custom_minimum_size = Vector2(
		REPORT_HIGHLIGHT_DESKTOP_WIDTH,
		REPORT_STORY_FULL_HEIGHT,
	)
	_hen_highlight_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_report_story_row.add_child(_hen_highlight_card)
	var highlight_stack := _panel_content(_hen_highlight_card, 14, 8, 1)
	_hen_highlight_eyebrow = _make_label("HEN FILE  //  AWAITING SUBJECT", 9, TEAL)
	_hen_highlight_eyebrow.name = "ShiftHenHighlightEyebrow"
	_hen_highlight_eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	highlight_stack.add_child(_hen_highlight_eyebrow)
	_hen_highlight_headline = _make_label("SHIFT HIGHLIGHT", 14, CREAM)
	_hen_highlight_headline.name = "ShiftHenHighlightHeadline"
	_hen_highlight_headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	highlight_stack.add_child(_hen_highlight_headline)
	_hen_highlight_glance_strip = HFlowContainer.new()
	_hen_highlight_glance_strip.name = "ShiftHenHighlightGlanceStrip"
	_hen_highlight_glance_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hen_highlight_glance_strip.add_theme_constant_override("h_separation", 4)
	_hen_highlight_glance_strip.add_theme_constant_override("v_separation", 4)
	_hen_highlight_glance_strip.visible = false
	highlight_stack.add_child(_hen_highlight_glance_strip)
	_hen_highlight_body = _make_label("Awaiting a closing hen file.", 11, INK)
	_hen_highlight_body.name = "ShiftHenHighlightBody"
	_hen_highlight_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hen_highlight_body.max_lines_visible = 3
	_hen_highlight_body.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_hen_highlight_body.mouse_filter = Control.MOUSE_FILTER_STOP
	highlight_stack.add_child(_hen_highlight_body)
	_hen_highlight_metric = _make_label("0 EGGS", 9, MUTED)
	_hen_highlight_metric.name = "ShiftHenHighlightMetric"
	_hen_highlight_metric.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	highlight_stack.add_child(_hen_highlight_metric)
	_report_ledger_section_label = _section_label("5-SHIFT RECORD")
	_report_ledger_section_label.name = "ReportLedgerSectionTitle"
	content.add_child(_report_ledger_section_label)
	_build_ledger_row(content, "Report", _report_ledger_labels)
	var report_safeguards := _build_safeguard_receipt(
		content,
		"Report",
		_report_safeguard_rows,
		_report_safeguard_pass_rows,
	)
	_report_safeguard_panel = report_safeguards["panel"] as PanelContainer
	_report_safeguard_summary = report_safeguards["summary"] as Label
	_report_safeguard_grid = report_safeguards["grid"] as GridContainer
	_report_safeguard_pass_grid = report_safeguards["pass_grid"] as GridContainer

	_objective_card = PanelContainer.new()
	_objective_card.name = "NextShiftObjectiveCard"
	_objective_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("20333a"), Color("4c786f"), 8, 1),
	)
	content.add_child(_objective_card)
	var objective_content := _panel_content(_objective_card, 16, 10, 3)
	var objective_header := HBoxContainer.new()
	objective_header.name = "NextShiftObjectiveHeader"
	objective_header.add_theme_constant_override("separation", 10)
	objective_content.add_child(objective_header)
	_objective_title_label = _make_label("NEXT SHIFT OBJECTIVE", 14, TEAL)
	_objective_title_label.name = "NextShiftObjective"
	_objective_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_objective_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_header.add_child(_objective_title_label)
	_objective_reward_badge = PanelContainer.new()
	_objective_reward_badge.name = "NextShiftObjectiveRewardBadge"
	_objective_reward_badge.custom_minimum_size = Vector2(104.0, 28.0)
	_objective_reward_badge.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1b3738"), BRASS, 7, 1),
	)
	_objective_reward_badge.visible = false
	objective_header.add_child(_objective_reward_badge)
	var reward_content := _panel_content(_objective_reward_badge, 9, 4, 0)
	var reward_line := HBoxContainer.new()
	reward_line.name = "NextShiftObjectiveRewardLine"
	reward_line.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_line.add_theme_constant_override("separation", 5)
	reward_content.add_child(reward_line)
	_objective_promotion_icon = TextureRect.new()
	_objective_promotion_icon.name = "NextShiftObjectivePromotionIcon"
	_objective_promotion_icon.custom_minimum_size = Vector2(16.0, 16.0)
	_objective_promotion_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_objective_promotion_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_objective_promotion_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_promotion_icon.texture = ManagementTheme.action_icon(&"rank_crest")
	_objective_promotion_icon.set_meta("semantic_icon", "rank_crest")
	_objective_promotion_icon.visible = false
	reward_line.add_child(_objective_promotion_icon)
	_objective_reward_label = _make_label("+3 SCORE", 10, CREAM)
	_objective_reward_label.name = "NextShiftObjectiveRewardLabel"
	_objective_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_reward_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_line.add_child(_objective_reward_label)
	_objective_body_label = _make_label("Awaiting the next quota notice.", 13, INK)
	_objective_body_label.name = "NextShiftObjectiveDescription"
	_objective_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_content.add_child(_objective_body_label)
	_objective_order_strip = HFlowContainer.new()
	_objective_order_strip.name = "ProbationOrderStrip"
	_objective_order_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_objective_order_strip.add_theme_constant_override("h_separation", 8)
	_objective_order_strip.add_theme_constant_override("v_separation", 7)
	_objective_order_strip.visible = false
	objective_content.add_child(_objective_order_strip)
	_objective_driver_strip = HFlowContainer.new()
	_objective_driver_strip.name = "QuarterDriverStrip"
	_objective_driver_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_objective_driver_strip.add_theme_constant_override("h_separation", 8)
	_objective_driver_strip.add_theme_constant_override("v_separation", 6)
	_objective_driver_strip.visible = false
	objective_content.add_child(_objective_driver_strip)
	_objective_board_strip = HFlowContainer.new()
	_objective_board_strip.name = "BoardTargetStrip"
	_objective_board_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_objective_board_strip.add_theme_constant_override("h_separation", 8)
	_objective_board_strip.add_theme_constant_override("v_separation", 7)
	_objective_board_strip.visible = false
	objective_content.add_child(_objective_board_strip)
	_objective_progress_label = _make_label("", 11, Color("a9c8c0"))
	_objective_progress_label.name = "NextShiftObjectiveProgress"
	_objective_progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_content.add_child(_objective_progress_label)

	_milestone_section = VBoxContainer.new()
	_milestone_section.name = "MilestoneChoiceSection"
	_milestone_section.add_theme_constant_override("separation", 5)
	content.add_child(_milestone_section)
	_milestone_section_label = _section_label("MILESTONE REQUISITION  //  CHOOSE ONE PERMANENT EDGE")
	_milestone_section_label.name = "MilestoneChoiceSectionTitle"
	_milestone_section.add_child(_milestone_section_label)
	_milestone_buttons_host = HFlowContainer.new()
	_milestone_buttons_host.name = "MilestoneChoiceCards"
	_milestone_buttons_host.alignment = FlowContainer.ALIGNMENT_CENTER
	_milestone_buttons_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_milestone_buttons_host.add_theme_constant_override("h_separation", 10)
	_milestone_buttons_host.add_theme_constant_override("v_separation", 8)
	_milestone_section.add_child(_milestone_buttons_host)
	_milestone_hint_label = _make_label("Select one card before filing the next-shift plan.", 11, BRASS)
	_milestone_hint_label.name = "MilestoneChoiceHint"
	_milestone_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_milestone_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_milestone_section.add_child(_milestone_hint_label)

	_career_sponsorship_ui = CareerSponsorshipUIScript.new() as CareerSponsorshipUI
	_career_sponsorship_ui.name = "CareerSponsorshipUI"
	_career_sponsorship_ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_career_sponsorship_ui.sponsorship_requested.connect(
		func(worker_id: int, lane_id: StringName) -> void:
			career_sponsorship_requested.emit(worker_id, lane_id)
	)
	content.add_child(_career_sponsorship_ui)

	_report_actions = HFlowContainer.new()
	_report_actions.name = "ProbationReportActions"
	_report_actions.alignment = FlowContainer.ALIGNMENT_END
	_report_actions.add_theme_constant_override("h_separation", 12)
	_report_actions.add_theme_constant_override("v_separation", 8)
	content.add_child(_report_actions)
	_report_requisitions_button = _make_button(
		"ReviewRoostRequisitionsButton",
		"REQUISITIONS  [R]",
		&"DecisionChoiceButton",
	)
	_report_requisitions_button.custom_minimum_size = Vector2(180.0, 44.0)
	_style_report_action(_report_requisitions_button, &"requisitions")
	_report_requisitions_button.set_meta(
		"exact_action_label",
		"Review Roost requisitions [R].",
	)
	_report_requisitions_button.shortcut = _shortcut(KEY_R)
	_report_requisitions_button.pressed.connect(
		func() -> void: review_requisitions.emit()
	)
	_report_actions.add_child(_report_requisitions_button)
	_report_shelve_button = _make_button(
		"AbandonCampaignButton",
		"SAVE & EXIT  [A]",
		&"DecisionChoiceButton",
	)
	_report_shelve_button.custom_minimum_size = Vector2(160.0, 44.0)
	_style_report_action(_report_shelve_button, &"shelve")
	_report_shelve_button.set_meta(
		"exact_action_label",
		"Save this checkpoint and return to intake [A].",
	)
	_report_shelve_button.set_meta("outcome_first_action", "save_exit")
	_report_shelve_button.tooltip_text = (
		"Save this career checkpoint and return to intake. Continue resumes the exact checkpoint."
	)
	_report_shelve_button.shortcut = _shortcut(KEY_A)
	_report_shelve_button.pressed.connect(_on_abandon_campaign_pressed)
	_report_actions.add_child(_report_shelve_button)
	_report_continue_button = _make_button(
		"ContinueProbationButton",
		"NEXT SHIFT  [C]",
		&"PrimaryButton",
	)
	_report_continue_button.custom_minimum_size = Vector2(220.0, 44.0)
	_style_report_action(_report_continue_button, &"advance")
	_report_continue_button.set_meta(
		"exact_action_label",
		"File report and plan next shift [C].",
	)
	_report_continue_button.shortcut = _shortcut(KEY_C)
	_report_continue_button.pressed.connect(_on_continue_campaign_pressed)
	_report_actions.add_child(_report_continue_button)


func _build_final_panel(parent: Control) -> void:
	_final_panel = PanelContainer.new()
	_final_panel.name = "FinalProbationReviewPanel"
	_final_panel.custom_minimum_size = Vector2(860.0, 0.0)
	parent.add_child(_final_panel)

	var content := _panel_content(_final_panel, 32, 24, 11)
	var eyebrow := _make_label("CORNFIELDS MUTUAL  //  FINAL MANAGEMENT REVIEW", 12, BRASS)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(eyebrow)
	_final_verdict_label = _make_label("PROBATION REVIEW", 31, CREAM)
	_final_verdict_label.name = "FinalProbationVerdict"
	_final_verdict_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_final_verdict_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_final_verdict_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_final_verdict_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_final_verdict_label)
	_final_message_label = _make_label("Five shifts have been entered into the permanent coop record.", 15, INK)
	_final_message_label.name = "FinalProbationMessage"
	_final_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_final_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_final_message_label.visible = false
	content.add_child(_final_message_label)

	_final_ending_glance_grid = GridContainer.new()
	_final_ending_glance_grid.name = "FinalEndingGlance"
	_final_ending_glance_grid.columns = 3
	_final_ending_glance_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_final_ending_glance_grid.add_theme_constant_override("h_separation", 10)
	_final_ending_glance_grid.add_theme_constant_override("v_separation", 8)
	content.add_child(_final_ending_glance_grid)
	for index: int in range(3):
		var card := PanelContainer.new()
		card.name = "FinalEndingBeat%d" % (index + 1)
		card.custom_minimum_size = Vector2(190.0, 58.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		card.add_theme_stylebox_override(
			"panel",
			_panel_style(Color("20343e"), Color("536b72"), 8, 1),
		)
		_final_ending_glance_grid.add_child(card)
		var stack := _panel_content(card, 12, 7, 0)
		var caption := _make_label("OUTCOME", 9, MUTED)
		caption.name = "FinalEndingBeatCaption%d" % (index + 1)
		stack.add_child(caption)
		var value := _make_label("FILED", 17, CREAM)
		value.name = "FinalEndingBeatValue%d" % (index + 1)
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		value.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		stack.add_child(value)
		_final_ending_glance_tiles.append({
			"card": card,
			"caption": caption,
			"value": value,
		})

	_final_metrics = HFlowContainer.new()
	_final_metrics.name = "FinalProbationMetrics"
	_final_metrics.alignment = FlowContainer.ALIGNMENT_CENTER
	_final_metrics.add_theme_constant_override("h_separation", 16)
	_final_metrics.add_theme_constant_override("v_separation", 8)
	content.add_child(_final_metrics)
	_final_score_label = _make_metric("FinalScore", "0", "FINAL SCORE", 190.0)
	_final_metrics.add_child(_metric_panel(_final_score_label))
	_final_rank_label = _make_metric("FinalRank", "UNRANKED", "FINAL RANK", 276.0, 16, true)
	_final_metrics.add_child(_metric_panel(_final_rank_label))

	content.add_child(_section_label("FIVE-SHIFT CLOSING LEDGERS"))
	_build_ledger_row(content, "Final", _final_ledger_labels)
	var final_safeguards := _build_safeguard_receipt(content, "Final", _final_safeguard_rows)
	_final_safeguard_panel = final_safeguards["panel"] as PanelContainer
	_final_safeguard_summary = final_safeguards["summary"] as Label
	_final_safeguard_grid = final_safeguards["grid"] as GridContainer

	_final_actions = HFlowContainer.new()
	_final_actions.name = "FinalProbationActions"
	_final_actions.alignment = FlowContainer.ALIGNMENT_CENTER
	_final_actions.add_theme_constant_override("h_separation", 11)
	_final_actions.add_theme_constant_override("v_separation", 8)
	content.add_child(_final_actions)
	var leave := _make_button("FinalAbandonCampaignButton", "SHELVE & RETURN TO INTAKE  [A]", &"DecisionChoiceButton")
	leave.custom_minimum_size = Vector2(190.0, 46.0)
	leave.shortcut = _shortcut(KEY_A)
	leave.pressed.connect(_on_abandon_campaign_pressed)
	_final_actions.add_child(leave)
	_final_new_button = _make_button("FinalNewCampaignButton", "NEW CAMPAIGN  [N]", &"DecisionChoiceButton")
	_final_new_button.custom_minimum_size = Vector2(210.0, 46.0)
	_final_new_button.shortcut = _shortcut(KEY_N)
	_final_new_button.pressed.connect(_on_new_campaign_pressed)
	_final_actions.add_child(_final_new_button)
	_final_continue_button = _make_button("FinalContinueCampaignButton", "ENTER THE SENIOR ROOST  [C]", &"PrimaryButton")
	_final_continue_button.custom_minimum_size = Vector2(260.0, 46.0)
	_final_continue_button.shortcut = _shortcut(KEY_C)
	_final_continue_button.pressed.connect(_on_continue_campaign_pressed)
	_final_actions.add_child(_final_continue_button)


func _build_final_sticky_action_bar() -> void:
	_final_sticky_action_bar = PanelContainer.new()
	_final_sticky_action_bar.name = "FinalStickyActionBar"
	_final_sticky_action_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_final_sticky_action_bar.offset_left = 18.0
	_final_sticky_action_bar.offset_top = -78.0
	_final_sticky_action_bar.offset_right = -18.0
	_final_sticky_action_bar.offset_bottom = -14.0
	_final_sticky_action_bar.z_index = 14
	_final_sticky_action_bar.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1d3039"), Color("8b7444"), 10, 2),
	)
	_modal_host.add_child(_final_sticky_action_bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	_final_sticky_action_bar.add_child(margin)
	var actions := HFlowContainer.new()
	actions.name = "FinalStickyActions"
	actions.alignment = FlowContainer.ALIGNMENT_END
	actions.add_theme_constant_override("h_separation", 10)
	actions.add_theme_constant_override("v_separation", 6)
	margin.add_child(actions)
	var next_step := _make_label("NEXT STEP  //  THE FILE IS CLOSED", 11, BRASS)
	next_step.name = "FinalStickyActionLabel"
	next_step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_step.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	next_step.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions.add_child(next_step)
	_final_sticky_leave_button = _make_button(
		"FinalStickyLeaveButton",
		"SHELVE FILE  [A]",
		&"DecisionChoiceButton",
	)
	_final_sticky_leave_button.custom_minimum_size = Vector2(170.0, 46.0)
	_final_sticky_leave_button.shortcut = _shortcut(KEY_A)
	_final_sticky_leave_button.pressed.connect(_on_abandon_campaign_pressed)
	actions.add_child(_final_sticky_leave_button)
	_final_sticky_primary_button = _make_button(
		"FinalStickyPrimaryButton",
		"RETRY PROBATION  [N]",
		&"PrimaryButton",
	)
	_final_sticky_primary_button.custom_minimum_size = Vector2(250.0, 46.0)
	_final_sticky_primary_button.pressed.connect(_on_final_sticky_primary_pressed)
	actions.add_child(_final_sticky_primary_button)


func _build_safeguard_receipt(
	parent: VBoxContainer,
	prefix: String,
	rows: Array[Label],
	pass_rows: Array[Label] = [],
) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = "%sProbationSafeguardReceipt" % prefix
	panel.visible = false
	panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1c3038"), Color("6f8e87"), 8, 1),
	)
	parent.add_child(panel)
	var content := _panel_content(panel, 16, 10, 4)
	var final_receipt := prefix == "Final"
	var authored_heading := (
		"FINAL PASS CHECK  //  5 TARGETS" if final_receipt else "PASS CHECK  //  5 TARGETS"
	)
	var heading := _make_label(
		authored_heading if final_receipt else "PROBATION CHECK",
		11,
		TEAL,
	)
	heading.name = "%sProbationSafeguardHeading" % prefix
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.mouse_filter = Control.MOUSE_FILTER_STOP
	heading.tooltip_text = authored_heading
	heading.set_meta("accessible_text", authored_heading)
	heading.set_meta("compact_pass_heading", not final_receipt)
	content.add_child(heading)
	var summary := _make_label("IF FILED NOW  //  0 / 5 SAFEGUARDS", 14, CREAM)
	summary.name = "%sProbationSafeguardSummary" % prefix
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(summary)
	var grid := GridContainer.new()
	grid.name = "%sProbationSafeguardGrid" % prefix
	grid.columns = 5 if final_receipt else 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 3)
	content.add_child(grid)
	for index: int in range(5):
		var row := _make_label("AWAITING FILE", 11, MUTED)
		row.name = "%sProbationSafeguardRow_%d" % [prefix, index + 1]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if final_receipt:
			var card := PanelContainer.new()
			card.name = "%sProbationSafeguardCard_%d" % [prefix, index + 1]
			card.custom_minimum_size = Vector2(120.0, 58.0)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.mouse_filter = Control.MOUSE_FILTER_PASS
			card.add_theme_stylebox_override(
				"panel",
				_panel_style(Color("21353e"), Color("50666c"), 7, 1),
			)
			grid.add_child(card)
			var stack := _panel_content(card, 8, 6, 0)
			row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stack.add_child(row)
		else:
			grid.add_child(row)
		rows.append(row)
	var pass_grid: GridContainer = null
	if not final_receipt:
		pass_grid = GridContainer.new()
		pass_grid.name = "%sProbationSafeguardPassGrid" % prefix
		pass_grid.columns = 5
		pass_grid.visible = false
		pass_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pass_grid.add_theme_constant_override("h_separation", 8)
		pass_grid.add_theme_constant_override("v_separation", 6)
		content.add_child(pass_grid)
		for index: int in range(5):
			var card := PanelContainer.new()
			card.name = "%sProbationSafeguardPassCard_%d" % [prefix, index + 1]
			card.custom_minimum_size = Vector2(120.0, 50.0)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.mouse_filter = Control.MOUSE_FILTER_PASS
			card.add_theme_stylebox_override(
				"panel",
				_panel_style(Color("213b3b"), Color("6f9d8f"), 7, 1),
			)
			pass_grid.add_child(card)
			var stack := _panel_content(card, 8, 6, 0)
			var line := HBoxContainer.new()
			line.alignment = BoxContainer.ALIGNMENT_CENTER
			line.add_theme_constant_override("separation", 4)
			stack.add_child(line)
			var status_icon := TextureRect.new()
			status_icon.name = "%sProbationSafeguardPassIcon_%d" % [prefix, index + 1]
			status_icon.custom_minimum_size = Vector2(16.0, 16.0)
			status_icon.texture = ManagementTheme.action_icon(&"status_pass")
			status_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			status_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			status_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			status_icon.set_meta("semantic_icon", "status_pass")
			line.add_child(status_icon)
			var pass_row := _make_label("TARGET\n0", 9, Color("a7dbc9"))
			pass_row.name = "%sProbationSafeguardPassRow_%d" % [prefix, index + 1]
			pass_row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pass_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			line.add_child(pass_row)
			pass_rows.append(pass_row)
	return {"panel": panel, "summary": summary, "grid": grid, "pass_grid": pass_grid}


func _build_replacement_confirmation() -> void:
	_replacement_confirmation_host = Control.new()
	_replacement_confirmation_host.name = "CampaignReplacementConfirmation"
	_replacement_confirmation_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_replacement_confirmation_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_replacement_confirmation_host.z_index = 100
	_replacement_confirmation_host.visible = false
	_modal_host.add_child(_replacement_confirmation_host)

	var scrim := ColorRect.new()
	scrim.name = "CampaignReplacementConfirmationScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.006, 0.012, 0.018, 0.92)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_replacement_confirmation_host.add_child(scrim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 18.0
	center.offset_top = 18.0
	center.offset_right = -18.0
	center.offset_bottom = -18.0
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	_replacement_confirmation_host.add_child(center)

	_replacement_confirmation_panel = PanelContainer.new()
	_replacement_confirmation_panel.name = "CampaignReplacementConfirmationPanel"
	_replacement_confirmation_panel.custom_minimum_size = Vector2(560.0, 0.0)
	_replacement_confirmation_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1a2730"), RUST, 12, 2),
	)
	center.add_child(_replacement_confirmation_panel)
	var content := _panel_content(_replacement_confirmation_panel, 26, 22, 12)
	var eyebrow := _make_label("RECORDS CONTROL  //  DESTRUCTIVE FILING", 11, RUST)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(eyebrow)
	_replacement_confirmation_title = _make_label("REPLACE THE SAVED COOP FILE?", 24, CREAM)
	_replacement_confirmation_title.name = "CampaignReplacementConfirmationTitle"
	_replacement_confirmation_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_replacement_confirmation_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_replacement_confirmation_title)
	_replacement_confirmation_body = _make_label("", 13, INK)
	_replacement_confirmation_body.name = "CampaignReplacementConfirmationBody"
	_replacement_confirmation_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_replacement_confirmation_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_replacement_confirmation_body)
	var actions := HFlowContainer.new()
	actions.name = "CampaignReplacementConfirmationActions"
	actions.alignment = FlowContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("h_separation", 12)
	actions.add_theme_constant_override("v_separation", 8)
	content.add_child(actions)
	_replacement_confirmation_cancel = _make_button(
		"CancelCampaignReplacementButton",
		"KEEP CURRENT FILE  [ESC]",
		&"PrimaryButton",
	)
	_replacement_confirmation_cancel.custom_minimum_size = Vector2(220.0, 48.0)
	_replacement_confirmation_cancel.shortcut = _shortcut(KEY_ESCAPE)
	_replacement_confirmation_cancel.pressed.connect(_cancel_campaign_replacement)
	actions.add_child(_replacement_confirmation_cancel)
	_replacement_confirmation_confirm = _make_button(
		"ConfirmCampaignReplacementButton",
		"REPLACE & START FRESH  [Y]",
		&"DangerButton",
	)
	_replacement_confirmation_confirm.custom_minimum_size = Vector2(240.0, 48.0)
	_replacement_confirmation_confirm.shortcut = _shortcut(KEY_Y)
	_replacement_confirmation_confirm.pressed.connect(_confirm_campaign_replacement)
	actions.add_child(_replacement_confirmation_confirm)


func _refresh() -> void:
	if _day_badge == null:
		return
	var total_days := maxi(1, int(_snapshot.get("total_days", DEFAULT_TOTAL_DAYS)))
	var day := clampi(int(_snapshot.get("day", 1)), 1, total_days)
	var status_text := String(_snapshot.get("status", "PROBATION")).strip_edges().to_upper()
	if status_text.is_empty():
		status_text = "PROBATION"
	var status_tooltip := status_text
	if _view == VIEW_ACTIVE and _snapshot.has("score"):
		var score_text := _format_integer(int(_snapshot.get("score", 0)))
		if status_text == "SENIOR ROOST":
			status_tooltip = "SENIOR ROOST  %s" % score_text
			status_text = "ROOST  %s" % score_text
		else:
			status_text = "SCORE %s / %d" % [score_text, PROBATION_SCORE_LIMIT]
			status_tooltip = _challenge_contract_terms_text(_active_challenge_contract(), true)
	_status_label.text = status_text
	_status_label.tooltip_text = status_tooltip
	var exact_day_text := String(_snapshot.get(
		"day_badge_text",
		"DAY %d / %d" % [day, total_days],
	))
	_day_label.text = exact_day_text
	_refresh_day_progress_rail(day, total_days, exact_day_text)
	_refresh_day_badge_visibility()
	_refresh_live_order_badge()

	var modal_open := _view != VIEW_ACTIVE
	_modal_host.visible = modal_open
	_modal_scroll.visible = _view != VIEW_CONTRACT_BOARD
	_title_panel.visible = _view == VIEW_TITLE
	_report_panel.visible = _view == VIEW_REPORT
	_final_panel.visible = _view == VIEW_FINAL
	_final_sticky_action_bar.visible = _view == VIEW_FINAL and size.x >= 720.0
	_contract_board_ui.visible = _view == VIEW_CONTRACT_BOARD
	_apply_responsive_layout()
	if not modal_open:
		return

	match _view:
		VIEW_TITLE:
			_refresh_title()
		VIEW_REPORT:
			_refresh_report(day, total_days)
		VIEW_CONTRACT_BOARD:
			_contract_board_ui.apply_snapshot(_snapshot)
		VIEW_FINAL:
			_refresh_final()


func _refresh_title() -> void:
	_rebuild_challenge_contract_selector()
	var can_continue := _snapshot_continue_available()
	var resume_value: Variant = _snapshot.get("resume_summary", {})
	var resume_summary := resume_value as Dictionary if resume_value is Dictionary else {}
	var resume_details := _format_resume_summary(resume_summary)
	if _title_resume_heading != null:
		_title_resume_heading.text = (
			"RECOVERY COPY FOUND  //  SAVED COOP FILE CANDIDATE"
			if bool(resume_summary.get("recovered_from_backup", false)) else
			"SAVED COOP FILE CANDIDATE"
		)
	if _title_resume_details != null:
		_title_resume_details.text = resume_details
	_continue_title_button.disabled = not can_continue
	_continue_title_button.tooltip_text = (
		"Verify and resume the saved coop file candidate.\n%s" % resume_details
		if can_continue else
		"No saved probation file is available yet."
	)
	_apply_title_hierarchy(can_continue)


func _snapshot_continue_available() -> bool:
	return bool(_snapshot.get(
		"continue_available",
		_snapshot.get("has_continue", false),
	))


func _apply_title_hierarchy(can_continue: bool) -> void:
	# A fresh intake has no landing decision to make, so it opens directly on the
	# compact new-file terms. A valid checkpoint instead receives a resume-first
	# landing with one primary action and an explicit secondary path to setup.
	_title_new_file_setup = _title_new_file_setup or not can_continue
	var setup_visible := _title_new_file_setup
	if _title_heading != null:
		_title_heading.text = (
			"MEET MABEL"
			if setup_visible else
			"YOUR COOP FILE IS READY."
		)
	if _title_description != null:
		_title_description.text = (
			"Pick a difficulty. Start shift one."
			if setup_visible else
			"Continue the saved filing candidate; it will be verified before the coop opens, or deliberately review a new file."
		)
	if _title_profile_card != null:
		_title_profile_card.visible = setup_visible
	if _title_challenge_card != null:
		_title_challenge_card.visible = setup_visible
	if _title_probation_summary != null:
		_title_probation_summary.visible = setup_visible
	if _title_resume_card != null:
		_title_resume_card.visible = can_continue and not setup_visible

	_continue_title_button.visible = can_continue and not setup_visible
	_continue_title_button.theme_type_variation = &"PrimaryButton"
	_title_new_button.visible = true
	_title_new_button.theme_type_variation = (
		&"PrimaryButton" if setup_visible else &"DecisionChoiceButton"
	)
	_title_new_button.text = (
		"START SHIFT 1  [N]"
		if setup_visible else
		"REVIEW A NEW FILE  [N]"
	)
	_title_new_button.tooltip_text = (
		"Open a five-shift probation file under %s.%s" % [
			_challenge_contract_label(_selected_challenge_contract(), false),
			" The saved file will remain untouched until replacement is confirmed and verified."
			if can_continue else "",
		]
		if setup_visible else
		"Review Mabel's new-file introduction and immutable challenge terms. The saved file is not changed."
	)
	_title_back_button.visible = can_continue and setup_visible
	_apply_title_contract_disclosure()

	if can_continue and not setup_visible:
		_queue_focus(_continue_title_button)
	elif _title_challenge_selector != null and _title_challenge_selector.visible:
		_queue_focus(_title_challenge_selector)
	else:
		_queue_focus(_title_new_button)


func _format_resume_summary(summary: Dictionary) -> String:
	if summary.is_empty():
		return "A resumable checkpoint candidate is available. Continue verifies its complete filed state before opening."
	var lines: Array[String] = []
	var senior_resume := bool(summary.get("senior_roost", false))
	if senior_resume:
		lines.append("SENIOR YEAR %d  //  %d ROOST MARK%s  //  %d BOARD SEAL%s" % [
			maxi(1, int(summary.get("senior_year", 1))),
			maxi(0, int(summary.get("roost_marks", 0))),
			"" if int(summary.get("roost_marks", 0)) == 1 else "S",
			maxi(0, int(summary.get("mandate_seals", 0))),
			"" if int(summary.get("mandate_seals", 0)) == 1 else "S",
		])
	else:
		lines.append("DAY %d / %d  //  %d SHIFT%s FILED  //  SCORE %d" % [
			clampi(int(summary.get("day", 1)), 1, DEFAULT_TOTAL_DAYS),
			DEFAULT_TOTAL_DAYS,
			maxi(0, int(summary.get("completed_shifts", 0))),
			"" if int(summary.get("completed_shifts", 0)) == 1 else "S",
			clampi(int(summary.get("probation_score", 50)), 0, PROBATION_SCORE_LIMIT),
		])
	if not senior_resume:
		var saved_contract := _challenge_contract_from_value(summary.get("challenge_contract", {}))
		if not saved_contract.is_empty():
			lines.append("SAVED CHALLENGE CONTRACT  //  %s" % _challenge_contract_label(saved_contract, false))
		elif summary.has("challenge_contract_verified") and not bool(summary.get(
			"challenge_contract_verified",
			false,
		)):
			lines.append("SAVED CHALLENGE CONTRACT  //  UNVERIFIED SAVED TERMS")
	var rank_label := String(summary.get("rank_label", "")).strip_edges().to_upper()
	var stage_label := String(summary.get("stage_label", "")).strip_edges().to_upper()
	var context: Array[String] = []
	if not rank_label.is_empty():
		context.append(rank_label)
	if not stage_label.is_empty():
		context.append(stage_label)
	if not context.is_empty():
		lines.append("  //  ".join(context))
	var offline_value: Variant = summary.get("offline_recap", {})
	var offline_recap := offline_value as Dictionary if offline_value is Dictionary else {}
	if not offline_recap.is_empty():
		var offline_status := _bounded_resume_text(
			offline_recap.get("status_label", "Economy paused"),
			60,
		).to_upper()
		var elapsed_label := _bounded_resume_text(
			offline_recap.get(
				"elapsed_short_label",
				offline_recap.get("elapsed_label", "Save time not filed"),
			),
			40,
		).to_upper()
		lines.append("OFFLINE  //  %s  //  %s" % [elapsed_label, offline_status])
	var recap_value: Variant = summary.get("return_recap", {})
	var recap := recap_value as Dictionary if recap_value is Dictionary else {}
	if not recap.is_empty():
		var last_filed := _bounded_resume_text(
			recap.get("last_filed_label", ""),
			80,
		).to_upper()
		if not last_filed.is_empty():
			lines.append("LAST FILED  //  %s" % last_filed)
		var routing_value: Variant = recap.get("routing_mastery", {})
		var routing_mastery := (
			routing_value as Dictionary if routing_value is Dictionary else {}
		)
		var routing_short := _bounded_resume_text(
			routing_mastery.get("short_label", ""),
			100,
		).to_upper()
		if not routing_short.is_empty():
			lines.append("ROUTING  //  %s" % routing_short)
		var status_label := _bounded_resume_text(
			recap.get("status_label", ""),
			80,
		).to_upper()
		var status_reason := _bounded_resume_text(
			recap.get("status_reason", ""),
			180,
		)
		if not status_label.is_empty():
			lines.append("%s  //  %s%s" % [
				"STATUS" if String(recap.get("status_id", "")) == "clear" else "UNRESOLVED",
				status_label,
				"  //  %s" % status_reason if not status_reason.is_empty() else "",
			])
		var next_action := _bounded_resume_text(
			recap.get("next_action", ""),
			180,
		)
		if not next_action.is_empty():
			lines.append("NEXT  //  %s" % next_action)
	return "\n".join(lines)


func _bounded_resume_text(value: Variant, limit: int) -> String:
	var normalized := String(value).replace("\n", " ").replace("\r", " ")
	while "  " in normalized:
		normalized = normalized.replace("  ", " ")
	normalized = normalized.strip_edges()
	if normalized.length() <= limit:
		return normalized
	var boundary := normalized.rfind(" ", limit - 1)
	if boundary < maxi(1, limit / 2):
		boundary = limit
	return normalized.substr(0, boundary).strip_edges() + "…"


func _rebuild_challenge_contract_selector() -> void:
	if _title_challenge_selector == null:
		return
	var catalog := _challenge_contract_catalog()
	var desired_id := _selected_challenge_contract_id
	if _challenge_contract_by_id(desired_id, catalog).is_empty():
		desired_id = _default_challenge_contract_id(catalog)
	_challenge_selector_syncing = true
	_title_challenge_selector.clear()
	var selected_index := 0
	for index: int in range(catalog.size()):
		var contract := catalog[index]
		var contract_id := StringName(String(contract.get("id", "")))
		_title_challenge_selector.add_item(_challenge_contract_selector_label(contract))
		_title_challenge_selector.set_item_metadata(index, String(contract_id))
		if contract_id == desired_id:
			selected_index = index
	_title_challenge_selector.select(selected_index)
	_challenge_selector_syncing = false
	if not catalog.is_empty():
		var selected_contract := catalog[selected_index]
		_selected_challenge_contract_id = StringName(String(selected_contract.get(
			"id",
			DEFAULT_CHALLENGE_CONTRACT_ID,
		)))
		_snapshot["selected_new_challenge_contract_id"] = String(_selected_challenge_contract_id)
		_update_challenge_contract_detail(selected_contract)


func _on_challenge_contract_selected(index: int) -> void:
	if _challenge_selector_syncing or _title_challenge_selector == null:
		return
	if index < 0 or index >= _title_challenge_selector.item_count:
		return
	var contract_id := StringName(String(_title_challenge_selector.get_item_metadata(index)))
	var contract := _challenge_contract_by_id(contract_id, _challenge_contract_catalog())
	if contract.is_empty():
		return
	_selected_challenge_contract_id = contract_id
	_snapshot["selected_new_challenge_contract_id"] = String(contract_id)
	_update_challenge_contract_detail(contract)
	challenge_contract_changed.emit(contract_id)


func _update_challenge_contract_detail(contract: Dictionary) -> void:
	var description := String(contract.get(
		"description",
		"The selected probation filing terms remain fixed for this career.",
	)).strip_edges()
	var opening_terms := _challenge_contract_opening_text(contract)
	var terms := _challenge_contract_terms_text(contract, false)
	var route_brief := String(contract.get("route_brief", "")).strip_edges().to_upper()
	var route_guidance := String(contract.get("route_guidance", "")).strip_edges()
	var difficulty_label := _challenge_contract_difficulty_label(contract)
	var difficulty_guidance := String(contract.get("difficulty_guidance", "")).strip_edges()
	if _title_challenge_summary != null:
		_title_challenge_summary.text = "%s%s" % [
			route_brief if not route_brief.is_empty() else "%s RUN" % difficulty_label,
			"  ·  LOCKS ON START",
		]
		_title_challenge_summary.tooltip_text = "\n".join([
			"%s DIFFICULTY" % difficulty_label,
			difficulty_guidance,
			description,
			route_guidance,
			opening_terms,
			terms,
		].filter(func(line: String) -> bool: return not line.is_empty()))
	var defaults := DEFAULT_CHALLENGE_CONTRACT.get("opening_terms", {}) as Dictionary
	var opening_value: Variant = contract.get("opening_terms", defaults)
	var opening := opening_value as Dictionary if opening_value is Dictionary else defaults
	var lanes_value: Variant = opening.get(
		"additional_claim_lanes",
		defaults.get("additional_claim_lanes", []),
	)
	var extra_files := (lanes_value as Array).size() if lanes_value is Array else 0
	if _title_opening_fund != null:
		_title_opening_fund.text = "$%.0f" % (float(maxi(0, int(opening.get(
			"feed_fund_cents",
			defaults.get("feed_fund_cents", 5000),
		)))) / 100.0)
	if _title_opening_quota != null:
		_title_opening_quota.text = str(maxi(1, int(opening.get(
			"quota_target",
			defaults.get("quota_target", 16),
		))))
	if _title_opening_files != null:
		_title_opening_files.text = str(6 + clampi(extra_files, 0, 4))
	if _title_challenge_detail != null:
		_title_challenge_detail.text = "%s\n%s%s" % [
			opening_terms,
			terms,
			"\nDIFFICULTY NOTE  //  %s" % difficulty_guidance if not difficulty_guidance.is_empty() else "",
		]
		if not route_guidance.is_empty():
			_title_challenge_detail.text += "\nROUTE NOTE  //  %s" % route_guidance
		_title_challenge_detail.tooltip_text = "%s\n%s\n%s\n%s%s" % [
			_challenge_contract_label(contract, false),
			description,
			opening_terms,
			terms,
			"\n%s" % route_guidance if not route_guidance.is_empty() else "",
		]
	if _title_challenge_terms_toggle != null:
		_title_challenge_terms_toggle.tooltip_text = (
			"Show or hide the exact immutable approval thresholds.\n%s\n%s"
			% [description, _title_challenge_detail.text if _title_challenge_detail != null else terms]
		)
	if _title_challenge_selector != null:
		_title_challenge_selector.tooltip_text = (
			"Choose Learning, Standard, or Expert difficulty for the new coop file. The terms lock when the file opens.\n%s"
			% (_title_challenge_detail.tooltip_text if _title_challenge_detail != null else terms)
		)
	_apply_title_contract_disclosure()


func _challenge_contract_opening_text(contract: Dictionary) -> String:
	var defaults := DEFAULT_CHALLENGE_CONTRACT.get("opening_terms", {}) as Dictionary
	var opening_value: Variant = contract.get("opening_terms", defaults)
	var opening := opening_value as Dictionary if opening_value is Dictionary else defaults
	var lanes_value: Variant = opening.get(
		"additional_claim_lanes",
		defaults.get("additional_claim_lanes", []),
	)
	var extra_files := (lanes_value as Array).size() if lanes_value is Array else 0
	var fund_cents := maxi(0, int(opening.get(
		"feed_fund_cents",
		defaults.get("feed_fund_cents", 5000),
	)))
	var quota := maxi(1, int(opening.get(
		"quota_target",
		defaults.get("quota_target", 16),
	)))
	var pressure_label := String(opening.get(
		"pressure_label",
		defaults.get("pressure_label", "AUTHORED BASELINE"),
	)).strip_edges().to_upper()
	return "OPENING ECONOMY  //  FUND $%.2f  //  QUOTA %d  //  LIVE FILES %d  //  %s" % [
		fund_cents / 100.0,
		quota,
		6 + clampi(extra_files, 0, 4),
		pressure_label,
	]


func _challenge_contract_opening_glance(contract: Dictionary) -> String:
	var defaults := DEFAULT_CHALLENGE_CONTRACT.get("opening_terms", {}) as Dictionary
	var opening_value: Variant = contract.get("opening_terms", defaults)
	var opening := opening_value as Dictionary if opening_value is Dictionary else defaults
	var lanes_value: Variant = opening.get(
		"additional_claim_lanes",
		defaults.get("additional_claim_lanes", []),
	)
	var extra_files := (lanes_value as Array).size() if lanes_value is Array else 0
	return "FUND $%.2f  /  QUOTA %d  /  %d FILES" % [
		float(maxi(0, int(opening.get(
			"feed_fund_cents",
			defaults.get("feed_fund_cents", 5000),
		)))) / 100.0,
		maxi(1, int(opening.get(
			"quota_target",
			defaults.get("quota_target", 16),
		))),
		6 + clampi(extra_files, 0, 4),
	]


func _apply_title_contract_disclosure() -> void:
	if _title_challenge_detail != null:
		_title_challenge_detail.visible = (
			_title_new_file_setup and _title_contract_terms_expanded
		)
	if _title_challenge_terms_toggle != null:
		_title_challenge_terms_toggle.button_pressed = _title_contract_terms_expanded
		_title_challenge_terms_toggle.text = (
			"HIDE RULES  [T]"
			if _title_contract_terms_expanded else
			"RULES  [T]"
		)


func _on_challenge_contract_terms_toggled() -> void:
	if _title_challenge_terms_toggle == null or not _title_new_file_setup:
		return
	_title_contract_terms_expanded = _title_challenge_terms_toggle.button_pressed
	_apply_title_contract_disclosure()


func _on_title_back_pressed() -> void:
	if not _snapshot_continue_available() or not _title_new_file_setup:
		return
	_title_new_file_setup = false
	_title_contract_terms_expanded = false
	_refresh_title()
	title_intake_phase_changed.emit(title_intake_phase())


func _challenge_contract_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var catalog_value: Variant = _snapshot.get("challenge_contract_catalog", [])
	if catalog_value is Array:
		for contract_value: Variant in catalog_value as Array:
			if not contract_value is Dictionary:
				continue
			var contract := _normalized_challenge_contract(contract_value as Dictionary)
			if contract.is_empty() or not _challenge_contract_by_id(
				StringName(String(contract.get("id", ""))),
				result,
			).is_empty():
				continue
			result.append(contract)
	if result.is_empty():
		result.append(_normalized_challenge_contract(DEFAULT_CHALLENGE_CONTRACT))
	return result


func _challenge_contract_from_value(value: Variant) -> Dictionary:
	if value is Dictionary:
		return _normalized_challenge_contract(value as Dictionary)
	if value is String or value is StringName:
		return _challenge_contract_by_id(StringName(String(value)), _challenge_contract_catalog())
	return {}


func _normalized_challenge_contract(source: Dictionary) -> Dictionary:
	var contract_id := String(source.get("id", "")).strip_edges().to_lower()
	if contract_id.is_empty():
		return {}
	var result := source.duplicate(true)
	result["id"] = contract_id
	var fallback_label := contract_id.replace("_", " ").to_upper()
	var label := String(result.get("label", fallback_label)).strip_edges().to_upper()
	if label.is_empty():
		label = fallback_label
	result["label"] = label
	var short_label := String(result.get("short_label", label)).strip_edges().to_upper()
	result["short_label"] = label if short_label.is_empty() else short_label
	result["description"] = String(result.get(
		"description",
		"The selected probation filing terms remain fixed for this career.",
	)).strip_edges()
	var difficulty := String(result.get("difficulty", "")).strip_edges().to_lower()
	if difficulty not in ["learning", "standard", "expert"]:
		difficulty = _challenge_contract_fallback_difficulty(contract_id)
	result["difficulty"] = difficulty
	result["difficulty_label"] = String(result.get(
		"difficulty_label",
		difficulty.to_upper(),
	)).strip_edges().to_upper()
	result["difficulty_guidance"] = String(result.get(
		"difficulty_guidance",
		"These terms remain fixed for the five-shift probation file.",
	)).strip_edges()
	result["criteria"] = _challenge_contract_criteria(result)
	return result


func _challenge_contract_fallback_difficulty(contract_id: String) -> String:
	match contract_id:
		"supported_flock":
			return "learning"
		"executive_audit":
			return "expert"
		_:
			return "standard"


func _challenge_contract_by_id(
	contract_id: StringName,
	catalog: Array[Dictionary],
) -> Dictionary:
	var normalized_id := StringName(String(contract_id).strip_edges().to_lower())
	for contract: Dictionary in catalog:
		if StringName(String(contract.get("id", ""))) == normalized_id:
			return contract.duplicate(true)
	return {}


func _default_challenge_contract_id(catalog: Array[Dictionary]) -> StringName:
	if not _challenge_contract_by_id(DEFAULT_CHALLENGE_CONTRACT_ID, catalog).is_empty():
		return DEFAULT_CHALLENGE_CONTRACT_ID
	for contract: Dictionary in catalog:
		if "STANDARD" in _challenge_contract_label(contract, false):
			return StringName(String(contract.get("id", DEFAULT_CHALLENGE_CONTRACT_ID)))
	return (
		StringName(String(catalog[0].get("id", DEFAULT_CHALLENGE_CONTRACT_ID)))
		if not catalog.is_empty() else
		DEFAULT_CHALLENGE_CONTRACT_ID
	)


func _selected_challenge_contract() -> Dictionary:
	var catalog := _challenge_contract_catalog()
	var contract := _challenge_contract_by_id(_selected_challenge_contract_id, catalog)
	if contract.is_empty():
		contract = _challenge_contract_by_id(_default_challenge_contract_id(catalog), catalog)
	return contract if not contract.is_empty() else _normalized_challenge_contract(DEFAULT_CHALLENGE_CONTRACT)


func _active_challenge_contract() -> Dictionary:
	var contract := _challenge_contract_from_value(_snapshot.get("challenge_contract", {}))
	if contract.is_empty():
		var forecast_value: Variant = _snapshot.get("probation_safeguard_forecast", {})
		if forecast_value is Dictionary:
			contract = _challenge_contract_from_value(
				(forecast_value as Dictionary).get("challenge_contract", {})
			)
	if contract.is_empty():
		contract = _normalized_challenge_contract(DEFAULT_CHALLENGE_CONTRACT)
	return contract


func _challenge_contract_criteria(contract: Dictionary) -> Dictionary:
	var defaults := (DEFAULT_CHALLENGE_CONTRACT.get("criteria", {}) as Dictionary).duplicate(true)
	var criteria_value: Variant = contract.get("criteria", {})
	if not criteria_value is Dictionary:
		return defaults
	var criteria := criteria_value as Dictionary
	defaults["minimum_score"] = clampi(_criterion_integer(
		criteria,
		["minimum_score", "score", "min_score", "probation_score"],
		int(defaults["minimum_score"]),
	), 0, PROBATION_SCORE_LIMIT)
	defaults["minimum_welfare"] = clampi(_criterion_integer(
		criteria,
		["minimum_welfare", "welfare", "min_welfare"],
		int(defaults["minimum_welfare"]),
	), 0, 100)
	defaults["minimum_compliance"] = clampi(_criterion_integer(
		criteria,
		["minimum_compliance", "compliance", "min_compliance"],
		int(defaults["minimum_compliance"]),
	), 0, 100)
	defaults["minimum_farmer_favor"] = clampi(_criterion_integer(
		criteria,
		["minimum_farmer_favor", "farmer_favor", "min_farmer_favor"],
		int(defaults["minimum_farmer_favor"]),
	), 0, 100)
	defaults["maximum_crack_rate_basis_points"] = clampi(_criterion_integer(
		criteria,
		[
			"maximum_crack_rate_basis_points", "max_crack_rate_basis_points",
			"crack_rate_basis_points", "maximum_crack_rate", "max_crack_rate",
		],
		int(defaults["maximum_crack_rate_basis_points"]),
	), 0, 10000)
	return defaults


func _criterion_integer(source: Dictionary, keys: Array[String], fallback: int) -> int:
	for key: String in keys:
		if not source.has(key):
			continue
		var value: Variant = source[key]
		if value is Dictionary:
			value = (value as Dictionary).get("target", fallback)
		if value is int or value is float:
			return int(value)
	return fallback


func _challenge_contract_label(contract: Dictionary, compact: bool) -> String:
	var label_key := "short_label" if compact else "label"
	var label := String(contract.get(label_key, contract.get("label", "STANDARD FILING")))
	return label.strip_edges().to_upper() if not label.strip_edges().is_empty() else "STANDARD FILING"


func _challenge_contract_difficulty_label(contract: Dictionary) -> String:
	var normalized := _normalized_challenge_contract(contract)
	var label := String(normalized.get("difficulty_label", "STANDARD")).strip_edges().to_upper()
	return label if not label.is_empty() else "STANDARD"


func _challenge_contract_selector_label(contract: Dictionary) -> String:
	return "[%s] %s" % [
		_challenge_contract_difficulty_label(contract),
		_challenge_contract_label(contract, false),
	]


func _challenge_contract_terms_text(contract: Dictionary, include_heading: bool) -> String:
	var criteria := _challenge_contract_criteria(contract)
	var terms := (
		"PASS FILE  //  SCORE >= %d / %d  //  WELFARE >= %d  //  COMPLIANCE >= %d"
		+ "  //  FARMER FAVOR >= %d  //  CRACK RATE <= %.2f%%"
	) % [
		int(criteria["minimum_score"]),
		PROBATION_SCORE_LIMIT,
		int(criteria["minimum_welfare"]),
		int(criteria["minimum_compliance"]),
		int(criteria["minimum_farmer_favor"]),
		float(criteria["maximum_crack_rate_basis_points"]) / 100.0,
	]
	if include_heading:
		return "CHALLENGE CONTRACT  //  %s DIFFICULTY  //  %s\n%s" % [
			_challenge_contract_difficulty_label(contract),
			_challenge_contract_label(contract, false),
			terms,
		]
	return terms


func _refresh_report(day: int, total_days: int) -> void:
	var senior := _is_senior_snapshot()
	var full_report_kicker := String(_snapshot.get(
		"report_kicker",
		(
			"SENIOR ROOST  //  YEAR %d  //  QUARTER %d  //  SHIFT %d OF %d" % [
				maxi(1, int(_snapshot.get("senior_year", 1))),
				maxi(1, int(_snapshot.get("senior_quarter", 1))),
				day,
				total_days,
			]
			if senior else
			"CLOSING FILE 3 / 3 · SHIFT %d OF %d · PROBATION REPORT" % [day, total_days]
		),
	))
	var authored_report_heading := String(_snapshot.get(
		"report_heading",
		"SENIOR ROOST QUARTERLY FILING" if senior else "FARMER'S SHIFT ASSESSMENT",
	)).to_upper()
	var compact_result_heading := "SHIFT %d RESULTS" % day
	_report_day_label.text = full_report_kicker if senior else compact_result_heading
	_report_day_label.visible = senior
	_report_day_label.tooltip_text = full_report_kicker
	_report_day_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_report_day_label.set_meta("accessible_text", full_report_kicker)
	_report_day_label.set_meta("glance_kicker", false)
	_report_day_label.set_meta("merged_into_result_heading", not senior)
	_report_heading_label.text = authored_report_heading if senior else compact_result_heading
	_report_heading_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_report_heading_label.tooltip_text = (
		authored_report_heading
		if senior else
		"%s\n%s" % [authored_report_heading, full_report_kicker]
	)
	_report_heading_label.set_meta("accessible_text", _report_heading_label.tooltip_text)
	_report_heading_label.set_meta("authored_report_heading", authored_report_heading)
	_report_heading_label.set_meta("compact_result_heading", not senior)
	var authored_ledger_section_title := String(_snapshot.get(
		"ledger_section_title",
		"SENIOR CAREER RECORD" if senior else "PROBATION RECORD  //  5-SHIFT VIEW",
	)).to_upper()
	var show_compact_ledger_heading := (
		not senior
		and authored_ledger_section_title == "PROBATION RECORD  //  5-SHIFT VIEW"
	)
	_report_ledger_section_label.text = (
		"5-SHIFT RECORD" if show_compact_ledger_heading else authored_ledger_section_title
	)
	_report_ledger_section_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_report_ledger_section_label.tooltip_text = authored_ledger_section_title
	_report_ledger_section_label.set_meta("accessible_text", authored_ledger_section_title)
	_report_ledger_section_label.set_meta(
		"compact_record_heading",
		show_compact_ledger_heading,
	)
	_milestone_section_label.text = String(_snapshot.get(
		"choice_section_title",
		"QUARTERLY CAPITAL POLICY  //  FILE ONE" if senior else "MILESTONE REQUISITION  //  CHOOSE ONE PERMANENT EDGE",
	)).to_upper()
	_set_report_continue_presentation(String(_snapshot.get(
		"continue_label",
		"FILE POLICY & OPEN QUARTER  [C]" if senior else "FILE REPORT & PLAN NEXT SHIFT  [C]",
	)))
	if _report_requisitions_button != null:
		var staffing_open := bool(_snapshot.get("staffing_planning_open", false))
		_report_requisitions_button.visible = staffing_open
		_report_requisitions_button.disabled = not staffing_open
		_report_requisitions_button.tooltip_text = (
			"Open Flockwatch to commission perches, compare applicants, or release a worker before filing the next shift."
			if staffing_open else
			"Roost requisitions open after every required closing-credit file has been resolved."
		)
	_report_score_label.text = String(_snapshot.get(
		"primary_metric_display",
		_format_integer(int(_snapshot.get("score", 0))),
	))
	_report_rank_label.text = String(_snapshot.get("rank", "UNRANKED")).to_upper()
	var authored_secondary_caption := String(_snapshot.get(
		"secondary_metric_caption",
		"SHIFT SCORE",
	)).to_upper()
	var visible_secondary_caption := (
		authored_secondary_caption if senior else "THIS SHIFT"
	)
	_set_metric_caption(_report_shift_delta_label, visible_secondary_caption)
	_update_score_receipt(day)
	var primary_metric_caption := String(_snapshot.get("score_caption", "SCORE"))
	var primary_metric_tooltip := String(_snapshot.get("primary_metric_tooltip", ""))
	_set_metric_caption(_report_score_label, primary_metric_caption)
	_report_score_label.tooltip_text = primary_metric_tooltip
	_report_score_label.set_meta("accessible_text", "%s %s. %s" % [
		primary_metric_caption,
		_report_score_label.text,
		primary_metric_tooltip,
	])
	_metric_panel(_report_score_label).tooltip_text = primary_metric_tooltip
	var rank_caption := String(_snapshot.get("rank_caption", "RANK")).to_upper()
	_set_metric_caption(_report_rank_label, rank_caption)
	_refresh_report_rank_presentation(rank_caption)
	if _snapshot.has("secondary_metric_display"):
		_report_shift_delta_label.text = String(_snapshot["secondary_metric_display"])
		_report_shift_delta_label.add_theme_color_override("font_color", CREAM)
		_report_shift_delta_label.tooltip_text = String(_snapshot.get("secondary_metric_tooltip", ""))
	_refresh_shift_delta_semantics(
		authored_secondary_caption,
		visible_secondary_caption,
		senior,
	)
	_update_credit_memo(day)
	_update_hen_highlight(day)
	_queue_report_evidence_reveal(day)
	_update_ledger_labels(_report_ledger_labels)
	_refresh_probation_safeguard_receipt(
		_report_safeguard_panel,
		_report_safeguard_summary,
		_report_safeguard_rows,
		false,
		_report_safeguard_pass_rows,
	)
	_update_objective()
	_rebuild_milestone_choices()
	_sync_report_action_accessibility()
	if _career_sponsorship_ui != null:
		var sponsorship_value: Variant = _snapshot.get("career_sponsorship", {})
		_career_sponsorship_ui.apply_snapshot(
			sponsorship_value as Dictionary if sponsorship_value is Dictionary else {}
		)
	# Open every report at its causal summary. Keyboard users can then tab into
	# the milestone/action controls without the ScrollContainer hiding the score.
	_queue_focus(_report_panel)
	call_deferred("_reset_report_scroll")


func _queue_report_evidence_reveal(report_day: int) -> void:
	# Dynamic report chips are rebuilt for each filing. Defer one frame so their
	# container layout is settled, then reveal the causal receipt from score to
	# attribution to hen evidence without moving any layout geometry.
	var reveal_key := str(hash([
		report_day,
		_snapshot.get("score_receipt", {}),
		_snapshot.get("credit_memo", {}),
		_snapshot.get("hen_highlight", {}),
	]))
	call_deferred("_play_report_evidence_reveal", reveal_key)


func _report_reveal_controls() -> Array[Control]:
	var controls: Array[Control] = []
	for group_value: Variant in [
		{"strip": _report_score_receipt_grid, "id": "score"},
		{"strip": _credit_memo_glance_strip, "id": "credit"},
		{"strip": _hen_highlight_glance_strip, "id": "hen"},
	]:
		var group := group_value as Dictionary
		var strip := group.get("strip") as Control
		if strip == null or not strip.visible:
			continue
		for child: Node in strip.get_children():
			if child is Control:
				var control := child as Control
				control.set_meta("reveal_group", String(group["id"]))
				control.set_meta("reveal_order", controls.size())
				controls.append(control)
	return controls


func _set_report_reveal_controls_settled(mode: String) -> void:
	for control: Control in _report_reveal_controls():
		control.modulate = Color.WHITE
		control.set_meta("reveal_motion", mode)
	for strip: Control in [
		_report_score_receipt_grid,
		_credit_memo_glance_strip,
		_hen_highlight_glance_strip,
	]:
		if strip != null:
			strip.set_meta("reveal_motion", mode)


func _report_shift_total_panel() -> PanelContainer:
	return _metric_panel(_report_shift_delta_label) if _report_shift_delta_label != null else null


func _set_report_total_pulse_settled(mode: String) -> void:
	var panel := _report_shift_total_panel()
	if panel == null:
		return
	panel.scale = Vector2.ONE
	panel.pivot_offset = panel.size * 0.5
	panel.set_meta("result_pulse_motion", mode)
	panel.set_meta("result_pulse_scale", REPORT_TOTAL_PULSE_SCALE)
	panel.set_meta("result_pulse_receipt", bool(_report_score_row.get_meta(
		"receipt_equation",
		false,
	)) if _report_score_row != null else false)


func _report_score_receipt() -> Dictionary:
	var raw_receipt: Variant = _snapshot.get("score_receipt", {})
	return raw_receipt as Dictionary if raw_receipt is Dictionary else {}


func _report_is_promotion() -> bool:
	return (
		not _is_senior_snapshot()
		and String(_report_score_receipt().get("rank_change", "steady")) == "promotion"
	)


func _set_report_promotion_stamp_settled(mode: String) -> void:
	if _report_rank_icon == null:
		return
	_report_rank_icon.scale = Vector2.ONE
	_report_rank_icon.pivot_offset = _report_rank_icon.size * 0.5
	_report_rank_icon.set_meta(
		"promotion_stamp_motion",
		mode if _report_is_promotion() else "skipped",
	)
	_report_rank_icon.set_meta("promotion_stamp_scale", REPORT_PROMOTION_STAMP_SCALE)


func _play_report_evidence_reveal(reveal_key: String) -> void:
	if _view != VIEW_REPORT:
		return
	if _report_reveal_tween != null and _report_reveal_tween.is_valid():
		_report_reveal_tween.kill()
	var controls := _report_reveal_controls()
	if controls.is_empty():
		_set_report_total_pulse_settled("skipped")
		_set_report_promotion_stamp_settled("skipped")
		return
	if reveal_key == _last_report_reveal_key:
		_set_report_reveal_controls_settled("instant" if _reduced_motion else "settled")
		_set_report_total_pulse_settled("instant" if _reduced_motion else "settled")
		_set_report_promotion_stamp_settled("instant" if _reduced_motion else "settled")
		return
	if _reduced_motion:
		_set_report_reveal_controls_settled("instant")
		_set_report_total_pulse_settled("instant")
		_set_report_promotion_stamp_settled("instant")
		_last_report_reveal_key = reveal_key
		report_filing_settled.emit(reveal_key, true)
		return
	_last_report_reveal_key = reveal_key
	for strip: Control in [
		_report_score_receipt_grid,
		_credit_memo_glance_strip,
		_hen_highlight_glance_strip,
	]:
		if strip != null:
			strip.set_meta("reveal_motion", "staggered")
	_set_report_total_pulse_settled("queued")
	_set_report_promotion_stamp_settled("queued")
	_report_reveal_tween = create_tween().set_parallel(true)
	for index: int in controls.size():
		var control := controls[index]
		control.modulate = Color(1.0, 1.0, 1.0, 0.0)
		control.set_meta("reveal_motion", "staggered")
		var reveal := _report_reveal_tween.tween_property(
			control,
			"modulate:a",
			1.0,
			REPORT_REVEAL_DURATION,
		)
		reveal.set_delay(float(index) * REPORT_REVEAL_STAGGER)
		reveal.set_trans(Tween.TRANS_QUAD)
		reveal.set_ease(Tween.EASE_OUT)
	_report_reveal_tween.finished.connect(
		_on_report_evidence_reveal_finished.bind(reveal_key),
		CONNECT_ONE_SHOT,
	)


func _on_report_evidence_reveal_finished(reveal_key: String) -> void:
	if _view != VIEW_REPORT or reveal_key != _last_report_reveal_key:
		return
	_set_report_reveal_controls_settled("completed")
	_play_report_total_pulse(reveal_key)


func _play_report_total_pulse(reveal_key: String) -> void:
	var panel := _report_shift_total_panel()
	var has_receipt_equation := (
		_report_score_row != null
		and bool(_report_score_row.get_meta("receipt_equation", false))
	)
	if panel == null or not has_receipt_equation:
		_set_report_total_pulse_settled("skipped")
		report_filing_settled.emit(reveal_key, false)
		return
	panel.pivot_offset = panel.size * 0.5
	panel.set_meta("result_pulse_motion", "pulsing")
	_report_reveal_tween = create_tween()
	var pulse_in := _report_reveal_tween.tween_property(
		panel,
		"scale",
		Vector2.ONE * REPORT_TOTAL_PULSE_SCALE,
		REPORT_TOTAL_PULSE_IN_DURATION,
	)
	pulse_in.set_trans(Tween.TRANS_QUAD)
	pulse_in.set_ease(Tween.EASE_OUT)
	var pulse_out := _report_reveal_tween.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		REPORT_TOTAL_PULSE_OUT_DURATION,
	)
	pulse_out.set_trans(Tween.TRANS_BACK)
	pulse_out.set_ease(Tween.EASE_OUT)
	_report_reveal_tween.finished.connect(
		_on_report_total_pulse_finished.bind(reveal_key),
		CONNECT_ONE_SHOT,
	)


func _on_report_total_pulse_finished(reveal_key: String) -> void:
	if _view != VIEW_REPORT or reveal_key != _last_report_reveal_key:
		return
	_set_report_total_pulse_settled("completed")
	if _report_is_promotion():
		_play_report_promotion_stamp(reveal_key)
		return
	report_filing_settled.emit(reveal_key, false)


func _play_report_promotion_stamp(reveal_key: String) -> void:
	if _report_rank_icon == null or not _report_is_promotion():
		_set_report_promotion_stamp_settled("skipped")
		report_filing_settled.emit(reveal_key, false)
		return
	_report_rank_icon.pivot_offset = _report_rank_icon.size * 0.5
	_report_rank_icon.set_meta("promotion_stamp_motion", "stamping")
	_report_reveal_tween = create_tween()
	var stamp_in := _report_reveal_tween.tween_property(
		_report_rank_icon,
		"scale",
		Vector2.ONE * REPORT_PROMOTION_STAMP_SCALE,
		REPORT_PROMOTION_STAMP_IN_DURATION,
	)
	stamp_in.set_trans(Tween.TRANS_QUAD)
	stamp_in.set_ease(Tween.EASE_OUT)
	var stamp_out := _report_reveal_tween.tween_property(
		_report_rank_icon,
		"scale",
		Vector2.ONE,
		REPORT_PROMOTION_STAMP_OUT_DURATION,
	)
	stamp_out.set_trans(Tween.TRANS_BACK)
	stamp_out.set_ease(Tween.EASE_OUT)
	_report_reveal_tween.finished.connect(
		_on_report_promotion_stamp_finished.bind(reveal_key),
		CONNECT_ONE_SHOT,
	)


func _on_report_promotion_stamp_finished(reveal_key: String) -> void:
	if _view != VIEW_REPORT or reveal_key != _last_report_reveal_key:
		return
	_set_report_promotion_stamp_settled("completed")
	report_filing_settled.emit(reveal_key, false)


func _update_score_receipt(report_day: int) -> void:
	for child: Node in _report_score_receipt_grid.get_children():
		_report_score_receipt_grid.remove_child(child)
		child.queue_free()
	_report_score_receipt_grid.visible = false
	var receipt_value: Variant = _snapshot.get("score_receipt", {})
	var receipt := receipt_value as Dictionary if receipt_value is Dictionary else {}
	var valid := not receipt.is_empty() and int(receipt.get("shift_number", 0)) == report_day
	if not valid:
		_refresh_report_score_hierarchy(false, 0)
		_report_heading_note.visible = true
		_report_shift_delta_label.text = "--"
		_report_shift_delta_label.add_theme_color_override("font_color", MUTED)
		_report_shift_delta_label.tooltip_text = "No shift score receipt is available."
		_refresh_shift_delta_icon(0, false)
		_report_heading_note.text = String(_snapshot.get(
			"report_note",
			"Career results and quarterly safeguards remain on the permanent coop record."
			if _is_senior_snapshot() else
			"Cumulative results follow you through all five shifts.",
		))
		_report_heading_note.add_theme_font_size_override("font_size", 13)
		_report_heading_note.tooltip_text = _report_heading_note.text
		_metric_panel(_report_shift_delta_label).add_theme_stylebox_override(
			"panel",
			_panel_style(Color("1d3039"), Color("53656d"), 8, 1),
		)
		return
	var score_before := int(receipt.get("score_before", 0))
	var score_after := int(receipt.get("score_after", score_before))
	var score_delta := int(receipt.get("score_delta", score_after - score_before))
	_report_shift_delta_label.text = _format_signed_delta(score_delta)
	var delta_color := TEAL if score_delta > 0 else (RUST if score_delta < 0 else MUTED)
	_report_shift_delta_label.add_theme_color_override("font_color", delta_color)
	_refresh_shift_delta_icon(score_delta, true)
	var raw_components: Variant = receipt.get("components", [])
	var components: Array = raw_components as Array if raw_components is Array else []
	var detail_lines: Array[String] = [
		"SHIFT %d SCORE RECEIPT" % report_day,
		"Score %d to %d (%s)" % [score_before, score_after, _format_signed_delta(score_delta)],
	]
	for component_value: Variant in components:
		if not component_value is Dictionary:
			continue
		var component := component_value as Dictionary
		var component_delta := int(component.get("delta", 0))
		var short_label := _receipt_component_short_label(StringName(component.get("id", &"")))
		detail_lines.append("%s  %s  //  %s" % [
			String(component.get("label", short_label)),
			_format_signed_delta(component_delta),
			String(component.get("detail", "Filed in the permanent career ledger.")),
		])
	var receipt_detail := "\n".join(detail_lines)
	_rebuild_score_receipt_grid(components, receipt_detail)
	_refresh_report_score_hierarchy(
		_report_score_receipt_grid.visible,
		_report_score_receipt_grid.get_child_count(),
	)
	_report_heading_note.visible = not _report_score_receipt_grid.visible
	_report_heading_note.text = "RECEIPT  %d -> %d" % [score_before, score_after]
	_report_heading_note.tooltip_text = receipt_detail
	_report_shift_delta_label.tooltip_text = _report_heading_note.tooltip_text
	_report_shift_delta_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_metric_panel(_report_shift_delta_label).add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1d3039"), delta_color.darkened(0.12), 8, 1),
	)


func _rebuild_score_receipt_grid(components: Array, receipt_detail: String) -> void:
	var index := 0
	for component_value: Variant in components:
		if not component_value is Dictionary:
			continue
		var component := component_value as Dictionary
		var component_delta := int(component.get("delta", 0))
		var short_label := _receipt_component_short_label(
			StringName(component.get("id", &"")),
		)
		var exact_detail := "%s  %s  //  %s" % [
			String(component.get("label", short_label)),
			_format_signed_delta(component_delta),
			String(component.get("detail", "Filed in the permanent career ledger.")),
		]
		var tone := TEAL if component_delta > 0 else (RUST if component_delta < 0 else MUTED)
		var panel := PanelContainer.new()
		panel.name = "ReportScoreReceiptChip_%d" % (index + 1)
		panel.custom_minimum_size = Vector2(52.0, 34.0)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override(
			"panel",
			_panel_style(tone.darkened(0.67), tone.darkened(0.08), 6, 1),
		)
		panel.tooltip_text = exact_detail
		var component_id := StringName(component.get("id", &""))
		var icon_kind := _receipt_component_icon(component_id)
		panel.set_meta("component_id", String(component_id))
		panel.set_meta("semantic_icon", String(icon_kind))
		panel.set_meta("icon_first", true)
		panel.set_meta("accessible_text", exact_detail)
		var content := _panel_content(panel, 5, 4, 0)
		var line := HBoxContainer.new()
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_theme_constant_override("separation", 4)
		content.add_child(line)
		var icon := TextureRect.new()
		icon.name = "ReportScoreReceiptChipIcon_%d" % (index + 1)
		icon.custom_minimum_size = Vector2(18.0, 18.0)
		icon.texture = ManagementTheme.action_icon(icon_kind)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.tooltip_text = exact_detail
		icon.set_meta("semantic_icon", String(icon_kind))
		line.add_child(icon)
		var label := _make_label(_format_signed_delta(component_delta), 10, INK)
		label.name = "ReportScoreReceiptChipLabel_%d" % (index + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.tooltip_text = exact_detail
		label.set_meta("accessible_text", exact_detail)
		line.add_child(label)
		_report_score_receipt_grid.add_child(panel)
		index += 1
	_report_score_receipt_grid.visible = index > 0
	_report_score_receipt_grid.tooltip_text = receipt_detail
	_report_score_receipt_grid.set_meta("accessible_text", receipt_detail)


func _refresh_report_score_hierarchy(receipt_available: bool, component_count: int) -> void:
	if _report_score_row == null:
		return
	var score_panel := _metric_panel(_report_score_label)
	var shift_panel := _metric_panel(_report_shift_delta_label)
	if score_panel == null or shift_panel == null:
		return
	var direct_receipt_flow := receipt_available and not _is_senior_snapshot()
	# A filed probation receipt should read left-to-right as components, shift
	# total, then cumulative career score. Senior calendar metrics retain their
	# authored primary-before-secondary hierarchy.
	if direct_receipt_flow:
		_report_score_row.move_child(shift_panel, 1)
		_report_score_row.move_child(score_panel, 2)
	else:
		_report_score_row.move_child(score_panel, 1)
		_report_score_row.move_child(shift_panel, 2)
	_report_score_row.set_meta("receipt_equation", direct_receipt_flow)
	_report_score_row.set_meta("visual_flow", (
		"receipt_components_to_shift_total_to_score"
		if direct_receipt_flow else
		"primary_to_secondary"
	))
	shift_panel.set_meta("receives_score_receipts", direct_receipt_flow)
	shift_panel.set_meta("receipt_component_count", component_count if direct_receipt_flow else 0)
	score_panel.set_meta("follows_shift_total", direct_receipt_flow)


func _signed_receipt_delta(value: float) -> String:
	var rounded := roundi(value)
	return "%s%d" % ["+" if rounded > 0 else "", rounded]


func _signed_receipt_currency(cents: int) -> String:
	var sign := "+" if cents > 0 else ("-" if cents < 0 else "")
	var absolute_cents := absi(cents)
	var amount := (
		str(absolute_cents / 100)
		if absolute_cents % 100 == 0 else
		"%.2f" % (float(absolute_cents) / 100.0)
	)
	return "$ %s%s" % [sign, amount]


func _senior_policy_receipt_metrics(memo: Dictionary) -> Array[String]:
	var metrics: Array[String] = [
		"FUND %s" % _signed_receipt_currency(int(memo.get("fund_delta_cents", 0))),
	]
	for metric in [
		{"key": "farmer_favor_delta", "label": "FAVOR"},
		{"key": "quota_delta", "label": "QUOTA"},
		{"key": "compliance_delta", "label": "COMPLIANCE"},
		{"key": "solidarity_delta", "label": "SOLIDARITY"},
	]:
		var value := float(memo.get(String(metric["key"]), 0.0))
		if is_zero_approx(value):
			continue
		metrics.append("%s %s" % [
			String(metric["label"]),
			_signed_receipt_delta(value),
		])
	return metrics


func _clear_story_glance_strip(strip: HFlowContainer) -> void:
	for child: Node in strip.get_children():
		strip.remove_child(child)
		child.queue_free()
	strip.visible = false


func _add_story_glance_chip(
	strip: HFlowContainer,
	node_name: String,
	caption: String,
	value: String,
	detail: String,
	tone: Color,
	minimum_width: float,
	icon_kind: StringName = &"",
) -> void:
	var panel := PanelContainer.new()
	panel.name = node_name
	var icon_value_width := 28.0 + float(value.length()) * 7.0
	panel.custom_minimum_size = Vector2(
		maxf(minimum_width, icon_value_width) if icon_kind != &"" else minimum_width,
		28.0,
	)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel",
		_panel_style(tone.darkened(0.70), tone.darkened(0.12), 5, 1),
	)
	panel.tooltip_text = detail
	panel.set_meta("accessible_text", detail)
	panel.set_meta("caption", caption)
	panel.set_meta("icon_first", icon_kind != &"")
	panel.set_meta("semantic_icon", String(icon_kind))
	var content := _panel_content(panel, 5, 3, 0)
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 4)
	content.add_child(line)
	if icon_kind != &"":
		var icon := TextureRect.new()
		icon.name = "%sIcon" % node_name
		icon.custom_minimum_size = Vector2(16.0, 16.0)
		icon.texture = ManagementTheme.action_icon(icon_kind)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.tooltip_text = detail
		icon.set_meta("semantic_icon", String(icon_kind))
		line.add_child(icon)
	var label := _make_label(value if icon_kind != &"" else "%s\n%s" % [caption, value], 9, INK)
	label.name = "%sLabel" % node_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = (
		TextServer.AUTOWRAP_OFF if icon_kind != &"" else TextServer.AUTOWRAP_WORD_SMART
	)
	if icon_kind != &"":
		label.custom_minimum_size.x = maxf(18.0, float(value.length()) * 7.0)
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	label.tooltip_text = detail
	label.set_meta("accessible_text", detail)
	line.add_child(label)
	strip.add_child(panel)


func _credit_byline(style_id: StringName, subject_name: String) -> String:
	match style_id:
		&"individual_merit":
			return subject_name if not subject_name.is_empty() else "LAYER"
		&"shared_scoop":
			return "FLOCK"
		&"management_innovation":
			return "MGMT"
	return "FILED"


func _rebuild_credit_glance_strip(memo: Dictionary, full_detail: String) -> void:
	_clear_story_glance_strip(_credit_memo_glance_strip)
	var subject_name := String(memo.get("worker_name", "LAYER")).strip_edges().to_upper()
	var style_id := StringName(memo.get("style_id", &""))
	var cost_cents := maxi(0, int(memo.get("cost_cents", 0)))
	_add_story_glance_chip(
		_credit_memo_glance_strip,
		"FiledCreditLayerChip",
		"LAYER",
		subject_name if not subject_name.is_empty() else "UNFILED",
		full_detail,
		BRASS,
		104.0,
		&"receipt_hen",
	)
	_add_story_glance_chip(
		_credit_memo_glance_strip,
		"FiledCreditBylineChip",
		"BYLINE",
		_credit_byline(style_id, subject_name),
		full_detail,
		TEAL if style_id != &"management_innovation" else RUST,
		104.0,
		&"receipt_flock",
	)
	_add_story_glance_chip(
		_credit_memo_glance_strip,
		"FiledCreditFundChip",
		"FUND",
		"$0" if cost_cents == 0 else "-$%.2f" % (float(cost_cents) / 100.0),
		full_detail,
		TEAL if cost_cents == 0 else RUST,
		104.0,
		&"receipt_fund",
	)
	_credit_memo_glance_strip.visible = true
	_credit_memo_glance_strip.tooltip_text = full_detail
	_credit_memo_glance_strip.set_meta("accessible_text", full_detail)


func _update_credit_memo(report_day: int) -> void:
	var memo_value: Variant = _snapshot.get("credit_memo", {})
	var memo := memo_value as Dictionary if memo_value is Dictionary else {}
	var visible := not memo.is_empty() and int(memo.get("day", 0)) == report_day
	_credit_memo_card.visible = visible
	if not visible:
		_clear_story_glance_strip(_credit_memo_glance_strip)
		_credit_memo_card.set_meta("compact_policy_receipt", false)
		_credit_memo_card.set_meta("compact_story_glance", false)
		_credit_memo_label.set_meta("outcome_first_credit_heading", false)
		_sync_report_story_visibility()
		return
	var option_name := String(memo.get("option_id", "credit_filed")).replace("_", " ").to_upper()
	var subject_name := String(memo.get("worker_name", "")).to_upper()
	var decision_id := StringName(String(memo.get("decision_id", "")))
	_credit_memo_card.set_meta("compact_policy_receipt", decision_id == &"senior_quarter_policy")
	_credit_memo_card.set_meta("compact_story_glance", false)
	_credit_memo_label.set_meta("outcome_first_credit_heading", false)
	var prefix := "CREDIT FILED"
	if decision_id == &"flock_restructuring":
		prefix = "FLOCK RESTRUCTURING FILED"
	elif decision_id == &"golden_egg_dossier":
		prefix = "GOLDEN DOSSIER FILED"
	elif decision_id == &"senior_quarter_policy":
		prefix = "POLICY LEDGER"
	var outcome := String(memo.get(
		"outcome",
		"The closing attribution is now part of the permanent coop record.",
	))
	if decision_id == &"senior_quarter_policy":
		_clear_story_glance_strip(_credit_memo_glance_strip)
		_credit_memo_label.add_theme_font_size_override("font_size", 12)
		var receipt_metrics := _senior_policy_receipt_metrics(memo)
		_credit_memo_label.text = "%s  //  %s\n%s" % [
			prefix,
			option_name,
			"  /  ".join(receipt_metrics),
		]
		_credit_memo_label.tooltip_text = "%s\n\nOUTCOME  //  %s" % [
			_credit_memo_label.text,
			outcome,
		]
		_credit_memo_label.set_meta(
			"accessible_text",
			_credit_memo_label.tooltip_text.replace("\n", " "),
		)
		_credit_memo_label.set_meta("receipt_metrics", receipt_metrics)
		_credit_memo_card.add_theme_stylebox_override(
			"panel",
			_panel_style(Color("1c3839"), BRASS, 8, 2),
		)
		_sync_report_story_visibility()
		return
	var byline := _credit_byline(StringName(memo.get("style_id", &"")), subject_name)
	var fund_detail := "NO COST" if int(memo.get("cost_cents", 0)) <= 0 else "-$%.2f" % (
		float(int(memo.get("cost_cents", 0))) / 100.0
	)
	var full_detail := "%s  //  %s%s\nATTRIBUTION  //  %s -> %s  //  FUND %s\n%s" % [
		prefix,
		option_name,
		("  //  %s" % subject_name if not subject_name.is_empty() else ""),
		subject_name if not subject_name.is_empty() else "UNFILED",
		byline,
		fund_detail,
		outcome,
	]
	_credit_memo_label.text = "CREDIT GOES TO"
	_credit_memo_label.add_theme_font_size_override("font_size", 14)
	_credit_memo_label.tooltip_text = full_detail
	_credit_memo_label.set_meta("accessible_text", full_detail.replace("\n", " "))
	_credit_memo_label.set_meta("receipt_metrics", [])
	_credit_memo_label.set_meta("outcome_first_credit_heading", true)
	_credit_memo_card.tooltip_text = full_detail
	_credit_memo_card.set_meta("accessible_text", full_detail.replace("\n", " "))
	_credit_memo_card.set_meta("compact_story_glance", true)
	_rebuild_credit_glance_strip(memo, full_detail)
	_credit_memo_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("20333a"), Color("8b7444"), 8, 1),
	)
	_sync_report_story_visibility()


func _update_hen_highlight(report_day: int) -> void:
	var highlight_value: Variant = _snapshot.get("hen_highlight", {})
	var highlight := highlight_value as Dictionary if highlight_value is Dictionary else {}
	var visible := not highlight.is_empty() and int(highlight.get("day", 0)) == report_day
	_hen_highlight_card.visible = visible
	if not visible:
		_clear_story_glance_strip(_hen_highlight_glance_strip)
		_hen_highlight_card.set_meta("compact_story_glance", false)
		_sync_report_story_visibility()
		return
	var worker_name := String(highlight.get("worker_name", "CLAIMS HEN")).to_upper()
	var career_title := String(highlight.get("career_title", "CLAIMS HEN")).to_upper()
	var relationship := String(highlight.get("relationship_label", "UNFILED")).to_upper()
	var body := String(highlight.get("body", "The flock closed another shift."))
	var metric := String(highlight.get("metric", "%d EGGS" % int(highlight.get("eggs", 0))))
	_hen_highlight_eyebrow.text = "%s  //  %s" % [worker_name, relationship]
	_hen_highlight_headline.text = String(highlight.get("headline", "SHIFT HIGHLIGHT")).to_upper()
	_hen_highlight_body.text = body
	_hen_highlight_metric.text = metric
	var tooltip := "%s  //  %s  //  %s\n%s\n%s" % [
		worker_name,
		career_title,
		relationship,
		body,
		metric,
	]
	_hen_highlight_body.tooltip_text = tooltip
	_hen_highlight_card.tooltip_text = tooltip
	_hen_highlight_card.set_meta("accessible_text", tooltip.replace("\n", " "))
	var has_glance_data := (
		highlight.has("eggs")
		and highlight.has("sound")
		and highlight.has("credit_cents")
	)
	_rebuild_hen_highlight_glance_strip(highlight, tooltip, has_glance_data)
	_hen_highlight_body.visible = not has_glance_data
	_hen_highlight_metric.visible = not has_glance_data
	_hen_highlight_card.set_meta("compact_story_glance", has_glance_data)
	var accent := _highlight_tone_color(StringName(highlight.get("tone", &"quality")))
	_hen_highlight_eyebrow.add_theme_color_override("font_color", accent)
	_hen_highlight_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("20333a"), accent.darkened(0.1), 8, 1),
	)
	_sync_report_story_visibility()


func _rebuild_hen_highlight_glance_strip(
	highlight: Dictionary,
	full_detail: String,
	visible: bool,
) -> void:
	_clear_story_glance_strip(_hen_highlight_glance_strip)
	if not visible:
		return
	var accent := _highlight_tone_color(StringName(highlight.get("tone", &"quality")))
	var golden := maxi(0, int(highlight.get("golden", 0)))
	var exception_label := "GOLD" if golden > 0 else "CRACKED"
	var exception_value := golden if golden > 0 else maxi(0, int(highlight.get("cracked", 0)))
	var values := [
		{
			"caption": "EGGS",
			"value": str(maxi(0, int(highlight.get("eggs", 0)))),
			"icon": &"order_clutch",
		},
		{
			"caption": "SOUND",
			"value": str(maxi(0, int(highlight.get("sound", 0)))),
			"icon": &"order_compliance",
		},
		{
			"caption": exception_label,
			"value": str(exception_value),
			"icon": &"receipt_specialty" if golden > 0 else &"receipt_shell",
		},
		{
			"caption": "CREDIT",
			"value": "$%.2f" % (float(maxi(0, int(highlight.get("credit_cents", 0)))) / 100.0),
			"icon": &"receipt_fund",
		},
	]
	for index in values.size():
		var item := values[index] as Dictionary
		_add_story_glance_chip(
			_hen_highlight_glance_strip,
			"ShiftHenEvidenceChip_%d" % (index + 1),
			String(item["caption"]),
			String(item["value"]),
			full_detail,
			accent,
			48.0,
			StringName(item["icon"]),
		)
	_hen_highlight_glance_strip.visible = true
	_hen_highlight_glance_strip.tooltip_text = full_detail
	_hen_highlight_glance_strip.set_meta("accessible_text", full_detail)


func _sync_report_story_visibility() -> void:
	if _report_story_row == null or _credit_memo_card == null or _hen_highlight_card == null:
		return
	_report_story_row.visible = _credit_memo_card.visible or _hen_highlight_card.visible
	var compact_policy_only := (
		_credit_memo_card.visible
		and not _hen_highlight_card.visible
		and bool(_credit_memo_card.get_meta("compact_policy_receipt", false))
	)
	var compact_story_glance := (
		_credit_memo_card.visible
		and _hen_highlight_card.visible
		and bool(_credit_memo_card.get_meta("compact_story_glance", false))
		and bool(_hen_highlight_card.get_meta("compact_story_glance", false))
	)
	_credit_memo_card.custom_minimum_size.y = (
		REPORT_STORY_COMPACT_HEIGHT
		if compact_policy_only or compact_story_glance else
		REPORT_STORY_FULL_HEIGHT
	)
	_hen_highlight_card.custom_minimum_size.y = (
		REPORT_STORY_COMPACT_HEIGHT if compact_story_glance else REPORT_STORY_FULL_HEIGHT
	)
	_report_story_row.set_meta("compact_policy_only", compact_policy_only)
	_report_story_row.set_meta("compact_story_glance", compact_story_glance)


func _receipt_component_short_label(component_id: StringName) -> String:
	match component_id:
		&"probation_orders":
			return "ORDERS"
		&"daily_clutch":
			return "CLUTCH"
		&"shell_quality":
			return "SHELLS"
		&"queue_control":
			return "QUEUES"
		&"flock_safeguards":
			return "FLOCK"
		&"score_cap":
			return "CAP"
		&"milestone_bonus":
			return "SPECIALTY"
	return String(component_id).replace("_", " ").to_upper()


func _receipt_component_icon(component_id: StringName) -> StringName:
	match component_id:
		&"probation_orders":
			return &"order_compliance"
		&"daily_clutch":
			return &"order_clutch"
		&"shell_quality":
			return &"receipt_shell"
		&"queue_control":
			return &"order_trays"
		&"flock_safeguards":
			return &"receipt_flock"
		&"score_cap":
			return &"receipt_cap"
		&"milestone_bonus":
			return &"receipt_specialty"
	return &"order_compliance"


func _format_signed_delta(value: int) -> String:
	return "+%d" % value if value > 0 else str(value)


func _refresh_probation_safeguard_receipt(
	panel: PanelContainer,
	summary: Label,
	rows: Array[Label],
	final_receipt: bool,
	pass_rows: Array[Label] = [],
) -> void:
	if panel == null or summary == null:
		return
	# Presentation snapshots intentionally merge across sequential career views.
	# A Senior filing must never inherit the completed probation receipt left in
	# that shared UI state, even if an older caller omitted the key entirely.
	if _is_senior_snapshot():
		panel.visible = false
		return
	var forecast_value: Variant = _snapshot.get("probation_safeguard_forecast", {})
	var forecast := forecast_value as Dictionary if forecast_value is Dictionary else {}
	var criteria_value: Variant = forecast.get("criteria", [])
	var criteria := criteria_value as Array if criteria_value is Array else []
	panel.visible = not criteria.is_empty()
	if criteria.is_empty():
		return
	var pass_count := clampi(int(forecast.get("pass_count", 0)), 0, criteria.size())
	var all_pass := bool(forecast.get("all_pass", false))
	if not final_receipt and _report_safeguard_grid != null:
		_report_safeguard_grid.visible = false
	if not final_receipt and _report_safeguard_pass_grid != null:
		_report_safeguard_pass_grid.visible = true
	var summary_prefix := "FINAL RESULT" if final_receipt else "CURRENT FORECAST"
	var active_contract := _active_challenge_contract()
	var contract_label := _challenge_contract_label(active_contract, false)
	var summary_status := (
		"ALL SAFEGUARDS PASS"
		if all_pass else
		("FILE HELD" if final_receipt else "ACTION REQUIRED")
	)
	var shift_progress := "" if final_receipt else "  //  %d / %d SHIFTS FILED" % [
		maxi(0, int(forecast.get("completed_shifts", 0))),
		maxi(1, int(forecast.get("required_shifts", DEFAULT_TOTAL_DAYS))),
	]
	var exact_summary := "%s  //  %s  //  %d / %d SAFEGUARDS%s  //  %s" % [
		summary_prefix,
		contract_label,
		pass_count,
		criteria.size(),
		shift_progress,
		summary_status,
	]
	summary.text = (
		"%s  //  %d OF %d PASS%s" % [
			contract_label,
			pass_count,
			criteria.size(),
			"" if all_pass else "  //  HELD",
		]
		if final_receipt else exact_summary
	)
	if not final_receipt:
		var completed_shifts := maxi(0, int(forecast.get("completed_shifts", 0)))
		var required_shifts := maxi(1, int(forecast.get("required_shifts", DEFAULT_TOTAL_DAYS)))
		# The persistent campaign badge already carries the five-shift timeline.
		# Keep this line focused on the decision: how many safeguards pass and,
		# when needed, which single gap the player should fix next.
		summary.text = "%d/%d PASS" % [
			pass_count,
			criteria.size(),
		]
		summary.set_meta("shift_context_source", "persistent_day_rail")
		summary.set_meta("completed_shifts", completed_shifts)
		summary.set_meta("required_shifts", required_shifts)
		summary.set_meta("compact_status_only", true)
	summary.add_theme_color_override("font_color", TEAL if all_pass else RUST)
	var tooltip_lines: Array[String] = [
		exact_summary,
		_challenge_contract_terms_text(active_contract, false),
	]
	for index: int in range(rows.size()):
		var label := rows[index]
		if label == null:
			continue
		label.visible = index < criteria.size()
		if not label.visible:
			continue
		var criterion_value: Variant = criteria[index]
		if not criterion_value is Dictionary:
			label.text = "HELD  //  INVALID SAFEGUARD ROW"
			label.add_theme_color_override("font_color", RUST)
			continue
		var criterion := criterion_value as Dictionary
		var exact_row := _probation_safeguard_row_text(criterion, final_receipt)
		label.text = (
			_probation_safeguard_glance_text(criterion)
			if final_receipt else exact_row
		)
		label.visible = final_receipt
		label.add_theme_color_override(
			"font_color",
			Color("a7dbc9") if bool(criterion.get("pass", false)) else Color("f0aa95"),
		)
		label.tooltip_text = exact_row
		label.set_meta("accessible_text", exact_row)
		if not final_receipt and index < pass_rows.size():
			var pass_label := pass_rows[index]
			var passed := bool(criterion.get("pass", false))
			pass_label.visible = true
			pass_label.text = _probation_safeguard_report_chip_text(criterion)
			pass_label.add_theme_color_override(
				"font_color",
				Color("a7dbc9") if passed else Color("f0aa95"),
			)
			pass_label.tooltip_text = exact_row
			pass_label.set_meta("accessible_text", exact_row)
			pass_label.set_meta("visual_status_symbol", "checkmark_badge" if passed else "attention_badge")
			var pass_card: PanelContainer = null
			var pass_ancestor := pass_label.get_parent()
			while pass_ancestor != null:
				if pass_ancestor is PanelContainer:
					pass_card = pass_ancestor as PanelContainer
					break
				pass_ancestor = pass_ancestor.get_parent()
			if pass_card != null:
				var status_icon := pass_card.find_child(
					"ReportProbationSafeguardPassIcon_%d" % (index + 1),
					true,
					false,
				) as TextureRect
				if status_icon != null:
					var icon_kind := &"status_pass" if passed else &"status_need"
					status_icon.texture = ManagementTheme.action_icon(icon_kind)
					status_icon.tooltip_text = exact_row
					status_icon.set_meta("semantic_icon", String(icon_kind))
				pass_card.tooltip_text = exact_row
				pass_card.set_meta("accessible_text", exact_row)
				pass_card.set_meta("status", "pass" if passed else "needs_action")
				pass_card.set_meta("visual_status_symbol", "checkmark_badge" if passed else "attention_badge")
				pass_card.add_theme_stylebox_override(
					"panel",
					_panel_style(
						Color("213b3b") if passed else Color("3d2c2b"),
						Color("6f9d8f") if passed else Color("b66d5c"),
						7,
						1,
					),
				)
		var row_card := label.get_parent().get_parent().get_parent() as PanelContainer
		if final_receipt and row_card != null:
			row_card.tooltip_text = exact_row
			row_card.set_meta("accessible_text", exact_row)
			row_card.add_theme_stylebox_override(
				"panel",
				_panel_style(
					Color("213b3b") if bool(criterion.get("pass", false)) else Color("3d2c2b"),
					Color("6f9d8f") if bool(criterion.get("pass", false)) else Color("b66d5c"),
					7,
					1,
				),
			)
		tooltip_lines.append(exact_row)
	var blocker := forecast.get("largest_recoverable_blocker", {}) as Dictionary
	if not blocker.is_empty() and not final_receipt:
		var blocker_line := "LARGEST RECOVERABLE GAP  //  %s  //  %s" % [
			String(blocker.get("label", "SAFEGUARD")).to_upper(),
			_probation_safeguard_gap_text(blocker),
		]
		summary.text += "  //  FIX %s %s" % [
			_probation_safeguard_short_label(blocker),
			_probation_safeguard_need_text(blocker),
		]
		tooltip_lines.append(blocker_line)
	panel.tooltip_text = "\n".join(tooltip_lines)
	panel.set_meta("accessible_text", panel.tooltip_text)
	summary.tooltip_text = panel.tooltip_text
	summary.set_meta("accessible_text", panel.tooltip_text)


func _probation_safeguard_glance_text(criterion: Dictionary) -> String:
	var short_label := _probation_safeguard_short_label(criterion)
	var metric := String(criterion.get("metric", ""))
	var value := _probation_safeguard_value_text(metric, int(criterion.get("projected_value", 0)))
	return "%s\n%s / %s" % [
		short_label,
		value,
		"PASS" if bool(criterion.get("pass", false)) else "HELD",
	]


func _probation_safeguard_short_label(criterion: Dictionary) -> String:
	var id := StringName(String(criterion.get("id", "")))
	match id:
		&"score":
			return "SCORE"
		&"welfare":
			return "FLOCK"
		&"compliance":
			return "OBEDIENCE"
		&"farmer_favor":
			return "FAVOR"
		&"crack_rate":
			return "SHELL"
	return "TARGET"


func _probation_safeguard_report_chip_text(criterion: Dictionary) -> String:
	var metric := String(criterion.get("metric", ""))
	var value := _probation_safeguard_value_text(metric, int(criterion.get("projected_value", 0)))
	if bool(criterion.get("pass", false)):
		return "%s\n%s" % [
			_probation_safeguard_short_label(criterion),
			value,
		]
	return "%s\n%s NEED %s" % [
		_probation_safeguard_short_label(criterion),
		value,
		_probation_safeguard_need_text(criterion),
	]


func _probation_safeguard_need_text(criterion: Dictionary) -> String:
	var gap := absi(int(criterion.get("signed_gap", 0)))
	if String(criterion.get("metric", "")) == "crack_rate_basis_points":
		return "%.2f" % (float(gap) / 100.0)
	return str(gap)


func _probation_safeguard_row_text(criterion: Dictionary, final_receipt: bool) -> String:
	var passed := bool(criterion.get("pass", false))
	var status := "PASS" if passed else ("HELD" if final_receipt else "AT RISK")
	var comparison := String(criterion.get("comparison", "minimum"))
	var metric := String(criterion.get("metric", ""))
	return "%s  //  %s  //  %s %s %s  //  %s" % [
		status,
		String(criterion.get("label", "SAFEGUARD")).to_upper(),
		_probation_safeguard_value_text(metric, int(criterion.get("projected_value", 0))),
		">=" if comparison == "minimum" else "<=",
		_probation_safeguard_value_text(metric, int(criterion.get("target", 0))),
		_probation_safeguard_gap_text(criterion),
	]


func _probation_safeguard_value_text(metric: String, value: int) -> String:
	if metric == "crack_rate_basis_points":
		return "%.2f%%" % (float(value) / 100.0)
	return str(value)


func _probation_safeguard_gap_text(criterion: Dictionary) -> String:
	var metric := String(criterion.get("metric", ""))
	var gap := int(criterion.get("signed_gap", 0))
	if metric == "crack_rate_basis_points":
		return "%s%.2f PTS" % ["+" if gap > 0 else "", float(gap) / 100.0]
	return "%s%d POINT%s" % [
		"+" if gap > 0 else "",
		gap,
		"" if absi(gap) == 1 else "S",
	]


func _highlight_tone_color(tone: StringName) -> Color:
	match tone:
		&"danger":
			return RUST
		&"gold":
			return BRASS
		&"care":
			return Color("d99472")
		&"neutral":
			return Color("8e9aa2")
	return TEAL


func _reset_report_scroll() -> void:
	if _modal_scroll != null and _view == VIEW_REPORT:
		_modal_scroll.scroll_vertical = 0


func _refresh_final() -> void:
	var passed := _campaign_passed()
	var ending_value: Variant = _snapshot.get("ending", {})
	var ending := ending_value as Dictionary if ending_value is Dictionary else {}
	var accent := TEAL if passed else RUST
	_final_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(NAVY, accent, 15, 3),
	)
	_final_verdict_label.text = String(ending.get(
		"title",
		"PROBATION PASSED" if passed else "PROBATION FAILED",
	)).to_upper()
	_final_verdict_label.add_theme_color_override("font_color", Color("b9e6d7") if passed else Color("f0aa95"))
	_final_message_label.text = String(_snapshot.get(
		"final_message",
		(
			"Your rooster badge has been approved. The senior roost expects even larger clutches."
			if passed else
			"The farmer has reclaimed the badge. Your file may be reopened for another five-shift probation."
		),
	))
	_final_message_label.set_meta("accessible_text", _final_message_label.text)
	_refresh_final_ending_glance(ending, passed, _final_message_label.text)
	_final_score_label.text = _format_integer(int(_snapshot.get("score", 0)))
	var final_rank := String(_snapshot.get("rank", "UNRANKED")).strip_edges().to_upper()
	if passed and final_rank == "PROBATIONARY MANAGER":
		# Supported Flock can legitimately pass below the score-only Trusted Layer
		# band. The closing receipt must describe that successful outcome instead of
		# contradicting the approved rooster badge with a probationary title.
		final_rank = "QUALIFIED ROOSTER"
	_final_rank_label.text = final_rank
	_update_ledger_labels(_final_ledger_labels)
	_refresh_probation_safeguard_receipt(
		_final_safeguard_panel,
		_final_safeguard_summary,
		_final_safeguard_rows,
		true,
	)
	_final_continue_button.visible = passed
	_final_new_button.text = "NEW CAMPAIGN  [N]" if passed else "RETRY PROBATION  [N]"
	_final_sticky_primary_button.text = (
		"ENTER THE SENIOR ROOST  [C]" if passed else "RETRY PROBATION  [N]"
	)
	_final_sticky_primary_button.shortcut = _shortcut(KEY_C if passed else KEY_N)
	_final_sticky_primary_button.tooltip_text = (
		"Continue this approved file into the optional post-campaign Senior Roost."
		if passed else
		"Open a replacement confirmation before starting a fresh five-shift probation file."
	)
	_queue_focus(
		_final_sticky_primary_button
		if _final_sticky_action_bar.is_visible_in_tree() else
		(_final_continue_button if passed else _final_new_button)
	)


func _refresh_final_ending_glance(
	ending: Dictionary,
	passed: bool,
	exact_message: String,
) -> void:
	var ending_id := StringName(String(ending.get("id", "")))
	var beats: Array[Dictionary]
	match ending_id:
		&"farmer_favorite":
			beats = _ending_beats("FAVOR", "WON", "CAPACITY", "RELEASED", "QUOTA", "RAISED")
		&"benevolent_rooster":
			beats = _ending_beats("FLOCK", "SUPPORTED", "CARE", "FILED", "COST", "NOTED")
		&"collective_bargaining":
			beats = _ending_beats("FLOCK", "UNITED", "VOICE", "FILED", "RANK", "CONTESTED")
		&"probation_terminated":
			beats = _ending_beats("FILE", "CLOSED", "FLOCK", "RECORDED", "BADGE", "RECLAIMED")
		&"probationary_rooster":
			beats = _ending_beats("STATUS", "EXTENDED", "FILING", "INCOMPLETE", "NEXT", "RETRY")
		_:
			beats = (
				_ending_beats("FILE", "APPROVED", "BADGE", "EARNED", "NEXT", "SENIOR ROOST")
				if passed else
				_ending_beats("FILE", "HELD", "BADGE", "RECLAIMED", "NEXT", "RETRY")
			)
	for index: int in range(mini(_final_ending_glance_tiles.size(), beats.size())):
		var tile := _final_ending_glance_tiles[index]
		var beat := beats[index]
		var card := tile.get("card") as PanelContainer
		var caption := tile.get("caption") as Label
		var value := tile.get("value") as Label
		caption.text = String(beat.get("caption", "OUTCOME"))
		value.text = String(beat.get("value", "FILED"))
		card.tooltip_text = exact_message
		card.set_meta("accessible_text", "%s: %s. %s" % [caption.text, value.text, exact_message])


func _ending_beats(
	caption_1: String,
	value_1: String,
	caption_2: String,
	value_2: String,
	caption_3: String,
	value_3: String,
) -> Array[Dictionary]:
	return [
		{"caption": caption_1, "value": value_1},
		{"caption": caption_2, "value": value_2},
		{"caption": caption_3, "value": value_3},
	]


func _update_objective() -> void:
	var objective_value: Variant = _snapshot.get(
		"next_objective",
		_snapshot.get("objective", {}),
	)
	var objective := objective_value as Dictionary if objective_value is Dictionary else {}
	var title := String(objective.get("title", objective.get("label", "AWAITING QUOTA NOTICE")))
	var description := String(objective.get(
		"description",
		objective.get("detail", "The farmer has not filed the next clutch target."),
	))
	_objective_body_label.text = description
	var orders_value: Variant = objective.get("orders", [])
	var probation_orders := (
		orders_value as Array
		if orders_value is Array and not _is_senior_snapshot() else
		[]
	)
	var reward_detail := String(objective.get("reward", "")).strip_edges()
	var reward_score := int(objective.get("reward_score", 0))
	var opportunity_value: Variant = objective.get("promotion_opportunity", {})
	var opportunity := (
		opportunity_value as Dictionary
		if opportunity_value is Dictionary and not _is_senior_snapshot() else
		{}
	)
	var promotion_available := bool(opportunity.get("available", false))
	var promotion_detail := ""
	if promotion_available:
		promotion_detail = "PROMOTION READY  //  COMPLETE ALL 3 ORDERS  //  %s%d SCORE  //  %d -> %d  //  %s" % [
			"+" if reward_score > 0 else "",
			reward_score,
			int(opportunity.get("current_score", 0)),
			int(opportunity.get("next_threshold", 0)),
			String(opportunity.get("next_rank_label", "NEXT RANK")).to_upper(),
		]
	var section_title := String(_snapshot.get(
		"objective_section_title",
		"QUARTER OBJECTIVE" if _is_senior_snapshot() else "NEXT SHIFT OBJECTIVE",
	)).to_upper()
	var authored_title := title.to_upper()
	var full_objective_title := "%s  //  %s" % [section_title, authored_title]
	var show_compact_orders_heading := probation_orders.size() >= 2
	_objective_title_label.text = (
		authored_title.replace("PROBATION ORDERS", "ORDERS")
		if show_compact_orders_heading else
		full_objective_title
	)
	var objective_title_detail := full_objective_title
	if not reward_detail.is_empty():
		objective_title_detail += "\nREWARD  //  %s" % reward_detail
	_objective_title_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_objective_title_label.tooltip_text = objective_title_detail
	_objective_title_label.set_meta("accessible_text", objective_title_detail)
	_objective_title_label.set_meta("compact_orders_heading", show_compact_orders_heading)
	_rebuild_probation_order_strip(probation_orders, description)
	var show_reward_badge := (
		_objective_order_strip.visible
		and reward_score != 0
		and not reward_detail.is_empty()
	)
	_objective_reward_badge.visible = show_reward_badge
	if show_reward_badge:
		_objective_reward_label.text = "%s%d SCORE" % [
			"+" if reward_score > 0 else "",
			reward_score,
		]
		var exact_reward_detail := promotion_detail if promotion_available else reward_detail
		_objective_reward_badge.add_theme_stylebox_override(
			"panel",
			_panel_style(
				Color("25352f") if promotion_available else Color("1b3738"),
				Color("f4df9d") if promotion_available else BRASS,
				7,
				2 if promotion_available else 1,
			),
		)
		_objective_promotion_icon.visible = promotion_available
		_objective_reward_badge.tooltip_text = exact_reward_detail
		_objective_reward_badge.set_meta("accessible_text", exact_reward_detail)
		_objective_reward_badge.set_meta("promotion_opportunity", promotion_available)
		_objective_reward_badge.set_meta("projected_score", int(opportunity.get("projected_score", 0)))
		_objective_reward_badge.set_meta("target_score", int(opportunity.get("next_threshold", 0)))
		_objective_reward_badge.set_meta("next_rank_label", String(opportunity.get("next_rank_label", "")))
		_objective_reward_label.tooltip_text = exact_reward_detail
		_objective_reward_label.set_meta("accessible_text", exact_reward_detail)
	else:
		_objective_promotion_icon.visible = false
		_objective_reward_badge.tooltip_text = ""
		_objective_reward_badge.set_meta("accessible_text", "")
		_objective_reward_badge.set_meta("promotion_opportunity", false)
		_objective_reward_badge.set_meta("projected_score", 0)
		_objective_reward_badge.set_meta("target_score", 0)
		_objective_reward_badge.set_meta("next_rank_label", "")
		_objective_reward_label.tooltip_text = ""
		_objective_reward_label.set_meta("accessible_text", "")
	var driver_value: Variant = objective.get("quarter_drivers", [])
	var quarter_drivers := driver_value as Array if driver_value is Array else []
	var driver_detail := _quarter_driver_detail(quarter_drivers)
	_objective_body_label.visible = (
		quarter_drivers.is_empty() and not _objective_order_strip.visible
	)
	_rebuild_objective_driver_strip(quarter_drivers, driver_detail)
	var mandate_value: Variant = _snapshot.get("annual_mandate_progress", {})
	var mandate_progress := (
		mandate_value as Dictionary if mandate_value is Dictionary else {}
	)
	if not mandate_progress.is_empty():
		_objective_reward_badge.visible = false
		_objective_progress_label.visible = true
		var board_detail := String(objective.get("board_detail", "")).strip_edges()
		var mandate_delta_value: Variant = _snapshot.get("annual_mandate_delta", {})
		var mandate_delta := (
			mandate_delta_value as Dictionary
			if mandate_delta_value is Dictionary else
			{}
		)
		var delta_detail := _board_delta_detail(mandate_delta)
		var detail_sections: Array[String] = []
		if not driver_detail.is_empty():
			detail_sections.append("QUARTER DRIVERS\n%s" % driver_detail)
		if not board_detail.is_empty():
			detail_sections.append(board_detail)
		var full_board_detail := "\n\n".join(detail_sections)
		if not delta_detail.is_empty():
			full_board_detail += "\n\nTHIS SHIFT  //  %s" % delta_detail
		_rebuild_objective_board_strip(
			mandate_progress,
			full_board_detail,
			mandate_delta,
		)
		_objective_progress_label.text = String(objective.get(
			"board_summary",
			_board_progress_summary(mandate_progress),
		))
		_objective_card.tooltip_text = full_board_detail
		_objective_card.set_meta("accessible_text", full_board_detail)
	elif objective.has("progress") or objective.has("target"):
		_objective_reward_badge.visible = false
		_objective_progress_label.visible = true
		_rebuild_objective_board_strip({}, "", {})
		_objective_progress_label.text = "PROGRESS CARRIED FORWARD  %s / %s" % [
			str(objective.get("progress", 0)),
			str(objective.get("target", "—")),
		]
		_objective_card.tooltip_text = driver_detail
		_objective_card.set_meta("accessible_text", driver_detail)
	else:
		_rebuild_objective_board_strip({}, "", {})
		_objective_progress_label.text = reward_detail
		_objective_progress_label.visible = not show_reward_badge
		var objective_detail := driver_detail if not driver_detail.is_empty() else description
		if not reward_detail.is_empty():
			objective_detail = "%s\n\nREWARD  //  %s" % [objective_detail, reward_detail]
		_objective_card.tooltip_text = objective_detail
		_objective_card.set_meta("accessible_text", objective_detail)


func _board_progress_summary(progress: Dictionary) -> String:
	var met := maxi(0, int(progress.get("objectives_met", 0)))
	var total := maxi(met, int(progress.get("objectives_total", 0)))
	var needs_action := maxi(0, total - met)
	return "BOARD %d / %d MET  //  %d NEED ACTION  //  YEAR %d / %d" % [
		met,
		total,
		needs_action,
		maxi(0, int(progress.get("shifts_recorded", 0))),
		maxi(0, int(progress.get("shifts_target", 12))),
	]


func _probation_order_value(row: Dictionary) -> String:
	var metric := String(row.get("metric", ""))
	var comparison := String(row.get("comparison", "minimum"))
	var target := int(row.get("target", 0))
	if metric == "quota_met":
		return "HIT QUOTA"
	if metric == "compliance":
		return "%d+" % target
	if metric == "overdue_files":
		return "<= %d" % target
	match comparison:
		"maximum":
			return "<= %d" % target
		"equal":
			return "= %d" % target
	return "%d+" % target


func _probation_order_icon(row: Dictionary) -> StringName:
	match StringName(row.get("id", "")):
		&"meet_the_clutch":
			return &"order_clutch"
		&"orderly_coop":
			return &"order_compliance"
		&"trim_the_trays":
			return &"order_trays"
	return &"order_clutch"


func _rebuild_probation_order_strip(orders: Array, detail: String) -> void:
	for child: Node in _objective_order_strip.get_children():
		_objective_order_strip.remove_child(child)
		child.queue_free()
	# A lone or malformed order is clearer as its authored sentence. The shipped
	# probation cadence always provides three structured orders for this strip.
	var valid_orders: Array[Dictionary] = []
	for order_value: Variant in orders:
		if order_value is Dictionary:
			valid_orders.append(order_value as Dictionary)
	if valid_orders.size() < 2:
		_objective_order_strip.visible = false
		return
	_objective_order_strip.visible = true
	_objective_order_strip.tooltip_text = detail
	_objective_order_strip.set_meta("accessible_text", detail)
	for index in valid_orders.size():
		var row := valid_orders[index]
		var title := String(row.get("title", "Probation order"))
		var description := String(row.get("description", "Meet the filed target."))
		var value := _probation_order_value(row)
		var exact_detail := "%s. %s Target %s." % [title, description, value]
		var panel := PanelContainer.new()
		panel.name = "ProbationOrder_%d" % (index + 1)
		panel.custom_minimum_size = Vector2(270.0, 42.0)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override(
			"panel",
			_panel_style(Color("1b3738"), Color("4c786f"), 7, 1),
		)
		panel.tooltip_text = exact_detail
		panel.set_meta("order_id", String(row.get("id", "")))
		panel.set_meta("accessible_text", exact_detail)
		var content := _panel_content(panel, 9, 6, 0)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 7)
		content.add_child(line)
		var icon := TextureRect.new()
		icon.name = "ProbationOrderIcon_%d" % (index + 1)
		icon.custom_minimum_size = Vector2(22.0, 22.0)
		icon.texture = ManagementTheme.action_icon(_probation_order_icon(row))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(icon)
		var label := _make_label("%s\n%s" % [title.to_upper(), value], 10, INK)
		label.name = "ProbationOrderLabel_%d" % (index + 1)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.tooltip_text = exact_detail
		label.set_meta("accessible_text", exact_detail)
		line.add_child(label)
		_objective_order_strip.add_child(panel)


func _quarter_driver_value(row: Dictionary) -> String:
	var metric := String(row.get("metric", ""))
	var actual := int(row.get("actual", 0))
	var target := int(row.get("target", 0))
	if metric.ends_with("basis_points"):
		return "%.1f%% / %.1f%%" % [float(actual) / 100.0, float(target) / 100.0]
	return "%d / %d" % [actual, target]


func _quarter_driver_detail(drivers: Array) -> String:
	var lines: Array[String] = []
	for row_value: Variant in drivers:
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		lines.append("%s  //  %s  //  %s  //  %s" % [
			"ON TRACK" if bool(row.get("projected_met", false)) else "NEEDS ACTION",
			String(row.get("title", "QUARTER DRIVER")),
			_quarter_driver_value(row),
			String(row.get("description", "Quarter safeguard filed.")),
		])
	return "\n".join(lines)


func _rebuild_objective_driver_strip(drivers: Array, detail: String) -> void:
	for child: Node in _objective_driver_strip.get_children():
		_objective_driver_strip.remove_child(child)
		child.queue_free()
	_objective_driver_strip.visible = not drivers.is_empty()
	_objective_driver_strip.tooltip_text = detail
	_objective_driver_strip.set_meta("accessible_text", detail)
	for row_value: Variant in drivers:
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		var on_track := bool(row.get("projected_met", false))
		var metric := String(row.get("metric", "quarter_driver"))
		var panel := PanelContainer.new()
		panel.name = "QuarterDriver_%s" % metric
		panel.custom_minimum_size = Vector2(220.0, 30.0)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override(
			"panel",
			_panel_style(
				Color("203a3b") if on_track else Color("3b302d"),
				Color("4c786f") if on_track else Color("8e5145"),
				6,
				1,
			),
		)
		panel.tooltip_text = "%s  //  %s" % [
			String(row.get("description", "Quarter safeguard filed.")),
			_quarter_driver_value(row),
		]
		panel.set_meta("status", "on_track" if on_track else "needs_action")
		panel.set_meta("metric", metric)
		panel.set_meta("actual", int(row.get("actual", 0)))
		panel.set_meta("target", int(row.get("target", 0)))
		panel.set_meta("comparison", String(row.get("comparison", "minimum")))
		panel.set_meta("accessible_text", "%s. %s. %s. %s" % [
			"On track" if on_track else "Needs action",
			String(row.get("title", "Quarter driver")),
			_quarter_driver_value(row),
			String(row.get("description", "Quarter safeguard filed.")),
		])
		var content := _panel_content(panel, 9, 6, 0)
		var label := _make_label("%s %s  %s" % [
			"+" if on_track else "!",
			String(row.get("title", "QUARTER DRIVER")).to_upper(),
			_quarter_driver_value(row),
		], 10, TEAL if on_track else RUST)
		label.name = "QuarterDriverLabel"
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		content.add_child(label)
		_objective_driver_strip.add_child(panel)


func _board_target_value(row: Dictionary) -> String:
	var metric := String(row.get("metric", ""))
	var actual := int(row.get("actual", 0))
	var target := int(row.get("target", 0))
	if metric.ends_with("basis_points"):
		return "%.1f%% / %.1f%%" % [float(actual) / 100.0, float(target) / 100.0]
	if metric.ends_with("_cents") or metric == "credited_cents":
		return "$%.2f / $%.2f" % [float(actual) / 100.0, float(target) / 100.0]
	return "%d / %d" % [actual, target]


func _signed_board_delta(metric: String, delta: int) -> String:
	var sign := "+" if delta > 0 else ("-" if delta < 0 else "")
	var magnitude := absi(delta)
	if metric.ends_with("basis_points"):
		return "%s%.1f%%" % [sign, float(magnitude) / 100.0]
	if metric.ends_with("_cents") or metric == "credited_cents":
		return "$ %s%.2f" % [sign, float(magnitude) / 100.0]
	return "%s%d" % [sign, magnitude]


func _board_delta_detail(delta_receipt: Dictionary) -> String:
	var lines: Array[String] = []
	for change_value: Variant in delta_receipt.get("changes", []) as Array:
		if not change_value is Dictionary:
			continue
		var change := change_value as Dictionary
		lines.append("%s %s (%s)" % [
			String(change.get("label", "BOARD TARGET")),
			_signed_board_delta(
				String(change.get("metric", "")),
				int(change.get("delta", 0)),
			),
			String(change.get("impact", "steady")).to_upper(),
		])
	return "  //  ".join(lines)


func _board_target_progress_rail(row: Dictionary) -> ProgressBar:
	var met := bool(row.get("met", false))
	var progress_basis_points := 10_000 if met else 0
	if row.has("progress_basis_points"):
		progress_basis_points = clampi(int(row["progress_basis_points"]), 0, 10_000)
	elif not met:
		var actual := int(row.get("actual", 0))
		var target := int(row.get("target", 0))
		if String(row.get("comparison", "minimum")) == "minimum":
			progress_basis_points = clampi(
				roundi(float(actual) / float(maxi(1, target)) * 10_000.0),
				0,
				10_000,
			)
		elif target > 0:
			progress_basis_points = clampi(
				roundi(float(target) / float(maxi(1, actual)) * 10_000.0),
				0,
				10_000,
			)
	var rail := ProgressBar.new()
	rail.name = "BoardTargetProgress"
	rail.custom_minimum_size = Vector2(0.0, 4.0)
	rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.min_value = 0.0
	rail.max_value = 10_000.0
	rail.value = float(progress_basis_points)
	rail.show_percentage = false
	rail.add_theme_stylebox_override(
		"background",
		_panel_style(Color("132126"), Color("30484a"), 2, 0),
	)
	var fill_color := Color("73b5a7") if met else Color("c96f59")
	rail.add_theme_stylebox_override(
		"fill",
		_panel_style(fill_color, fill_color, 2, 0),
	)
	rail.set_meta("progress_basis_points", progress_basis_points)
	rail.set_meta("comparison", String(row.get("comparison", "minimum")))
	rail.set_meta(
		"accessible_text",
		"Board progress %d percent toward target." % roundi(
			float(progress_basis_points) / 100.0,
		),
	)
	return rail


func _rebuild_objective_board_strip(
	progress: Dictionary,
	detail: String,
	delta_receipt: Dictionary,
) -> void:
	for child: Node in _objective_board_strip.get_children():
		_objective_board_strip.remove_child(child)
		child.queue_free()
	var objectives_value: Variant = progress.get("objectives", [])
	var objectives := objectives_value as Array if objectives_value is Array else []
	var changes_by_metric: Dictionary = {}
	for change_value: Variant in delta_receipt.get("changes", []) as Array:
		if change_value is Dictionary:
			var change := change_value as Dictionary
			changes_by_metric[String(change.get("metric", ""))] = change
	var pulse_key := "%s:%d:%d:%d" % [
		String(progress.get("mandate_id", "")),
		int(progress.get("year", 0)),
		int(delta_receipt.get("shift_index", 0)),
		int(delta_receipt.get("day", 0)),
	]
	var pulse_recent_changes := (
		bool(delta_receipt.get("visible", false))
		and pulse_key != _last_board_pulse_key
	)
	_objective_board_strip.visible = not objectives.is_empty()
	_objective_board_strip.tooltip_text = detail
	_objective_board_strip.set_meta("accessible_text", detail)
	for row_value: Variant in objectives:
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		var met := bool(row.get("met", false))
		var metric := String(row.get("metric", "board_target"))
		var recent_change := changes_by_metric.get(metric, {}) as Dictionary
		var panel := PanelContainer.new()
		panel.name = "BoardTarget_%s" % metric
		panel.custom_minimum_size = Vector2(220.0, 50.0)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override(
			"panel",
			_panel_style(
				Color("203a3b") if met else Color("3b302d"),
				Color("73b5a7") if met else Color("c96f59"),
				7,
				2 if not recent_change.is_empty() else 1,
			),
		)
		panel.tooltip_text = detail
		panel.set_meta("status", "met" if met else "needs_action")
		panel.set_meta("metric", metric)
		panel.set_meta("recent_change", not recent_change.is_empty())
		panel.set_meta("last_shift_delta", int(recent_change.get("delta", 0)))
		var accessible_text := "%s. %s. Actual %s." % [
			"Met" if met else "Needs action",
			String(row.get("label", "BOARD TARGET")),
			_board_target_value(row),
		]
		if not recent_change.is_empty():
			accessible_text += " This shift %s, %s." % [
				_signed_board_delta(metric, int(recent_change.get("delta", 0))),
				String(recent_change.get("impact", "steady")),
			]
		panel.set_meta("accessible_text", accessible_text)
		var content := _panel_content(panel, 10, 7, 1)
		var status := _make_label(
			"%s  //  %s" % [
				"+ MET" if met else "! NEEDS",
				String(row.get("label", "BOARD TARGET")).to_upper(),
			],
			9,
			TEAL if met else RUST,
		)
		status.name = "BoardTargetState"
		status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		content.add_child(status)
		var value_row := HBoxContainer.new()
		value_row.name = "BoardTargetValueRow"
		value_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		value_row.add_theme_constant_override("separation", 8)
		content.add_child(value_row)
		var value := _make_label(_board_target_value(row), 13, CREAM)
		value.name = "BoardTargetValue"
		value_row.add_child(value)
		if not recent_change.is_empty():
			var impact := String(recent_change.get("impact", "steady"))
			var delta := _make_label(
				"THIS SHIFT %s" % _signed_board_delta(
					metric,
					int(recent_change.get("delta", 0)),
				),
				9,
				TEAL if impact == "improved" else (RUST if impact == "setback" else MUTED),
			)
			delta.name = "BoardTargetDelta"
			delta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			delta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			value_row.add_child(delta)
		content.add_child(_board_target_progress_rail(row))
		_objective_board_strip.add_child(panel)
		if pulse_recent_changes and not recent_change.is_empty() and not _reduced_motion:
			panel.self_modulate = Color(1.0, 0.78, 0.58, 1.0)
			create_tween().tween_property(
				panel,
				"self_modulate",
				Color.WHITE,
				0.7,
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if pulse_recent_changes:
		_last_board_pulse_key = pulse_key


func _senior_policy_effect_glance(effect: String) -> String:
	var normalized := effect.replace(".00", "").strip_edges().to_upper()
	var parts := normalized.split("/", false)
	if parts.size() >= 2:
		normalized = "%s / %s" % [
			String(parts[0]).strip_edges(),
			String(parts[1]).strip_edges(),
		]
	return _bounded_resume_text(normalized, 34).to_upper()


func _senior_policy_metric_glance(choice: Dictionary, effect: String) -> Dictionary:
	var combined := String(choice.get(
		"glance_effect",
		_senior_policy_effect_glance(effect),
	)).strip_edges().to_upper()
	var parts := combined.split("/", false, 1)
	var fund := String(choice.get(
		"glance_fund",
		String(parts[0]).strip_edges() if not parts.is_empty() else "$ --",
	)).strip_edges().to_upper()
	if fund.begins_with("-$"):
		fund = "$ -%s" % fund.trim_prefix("-$").strip_edges()
	elif fund.begins_with("+$"):
		fund = "$ +%s" % fund.trim_prefix("+$").strip_edges()
	var outcome := String(choice.get(
		"glance_outcome",
		String(parts[1]).strip_edges() if parts.size() > 1 else "QUARTER EFFECT",
	)).strip_edges().to_upper()
	return {
		"fund": _bounded_resume_text(fund, 12).to_upper(),
		"outcome": _bounded_resume_text(outcome, 20).to_upper(),
	}


func _add_senior_policy_metric_chips(
	button: Button,
	title_copy: String,
	fund_copy: String,
	outcome_copy: String,
	signal_copy: String,
) -> void:
	button.text = ""
	var title_label := Label.new()
	title_label.name = "PolicyCardTitleLabel"
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.theme_type_variation = &"PolicyCardTitleLabel"
	title_label.text = title_copy
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_left = 12.0
	title_label.offset_top = 9.0
	title_label.offset_right = -12.0
	title_label.offset_bottom = 30.0
	button.add_child(title_label)
	var row := HBoxContainer.new()
	row.name = "PolicyMetricChips"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 12.0
	row.offset_top = 35.0
	row.offset_right = -12.0
	row.offset_bottom = 58.0
	row.add_theme_constant_override("separation", 6)
	button.add_child(row)
	var fund_positive := fund_copy.contains("+") and not fund_copy.contains("-")
	_add_senior_policy_metric_chip(
		row,
		"PolicyFundChip",
		fund_copy,
		&"PolicyCreditChip" if fund_positive else &"PolicyDebitChip",
		&"PolicyCreditChipLabel" if fund_positive else &"PolicyDebitChipLabel",
		0.8,
	)
	_add_senior_policy_metric_chip(
		row,
		"PolicyOutcomeChip",
		outcome_copy,
		&"PolicyOutcomeChip",
		&"PolicyOutcomeChipLabel",
		1.2,
	)
	var signal_label := Label.new()
	signal_label.name = "PolicyCardSignalLabel"
	signal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	signal_label.theme_type_variation = &"PolicyCardSignalLabel"
	signal_label.text = signal_copy
	signal_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	signal_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	signal_label.offset_left = 12.0
	signal_label.offset_top = 66.0
	signal_label.offset_right = -12.0
	signal_label.offset_bottom = 87.0
	button.add_child(signal_label)
	row.modulate.a = 0.58 if button.disabled else 1.0
	title_label.modulate.a = 0.58 if button.disabled else 1.0
	signal_label.modulate.a = 0.58 if button.disabled else 1.0


func _add_senior_policy_metric_chip(
	host: HBoxContainer,
	node_name: String,
	copy: String,
	panel_variation: StringName,
	label_variation: StringName,
	stretch_ratio: float,
) -> void:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.theme_type_variation = panel_variation
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = stretch_ratio
	host.add_child(panel)
	var label := Label.new()
	label.name = "%sLabel" % node_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.theme_type_variation = label_variation
	label.text = copy
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	panel.add_child(label)


func _senior_policy_focus_glance(detail: String) -> String:
	var normalized := detail.to_upper()
	if "FLOCK WELFARE" in normalized or "FLOCK" in normalized:
		return "FLOCK"
	if "TOP-HEN" in normalized or "CAREER" in normalized or "OBEDIENCE" in normalized:
		return "HEN"
	if "FARMER FAVOR" in normalized or "FUND BUFFER" in normalized or "FUND" in normalized:
		return "FUND"
	if "QUOTA" in normalized:
		return "QUOTA"
	return "SCORE"


func _senior_policy_board_glance(strategy: Dictionary) -> String:
	if strategy.has("supported_targets"):
		var targets_value: Variant = strategy.get("supported_targets", [])
		if targets_value is Array:
			var target_count := (targets_value as Array).size()
			return "+%d" % target_count if target_count > 0 else "--"
	var board_fit := String(strategy.get("board_fit", "")).to_upper()
	if board_fit.is_empty() or "FILE THE ANNUAL BOARD MANDATE FIRST" in board_fit:
		return "?"
	if "NO DIRECT TARGET EDGE" in board_fit:
		return "--"
	var edge_clause := board_fit.split("//", false)[0].strip_edges()
	if edge_clause.begins_with("EDGE "):
		var target_copy := edge_clause.trim_prefix("EDGE ").strip_edges()
		var target_count := target_copy.split(" + ", false).size()
		return "+%d" % target_count if target_count > 0 else "--"
	return "--"


func _rebuild_milestone_choices() -> void:
	for child: Node in _milestone_buttons_host.get_children():
		_milestone_buttons_host.remove_child(child)
		child.queue_free()
	_milestone_buttons.clear()
	var raw_choices: Variant = _snapshot.get(
		"milestone_choices",
		_snapshot.get("milestones", []),
	)
	var choices: Array = raw_choices as Array if raw_choices is Array else []
	_milestone_hint_label.text = String(_snapshot.get(
		"choice_hint",
		"Select one capital policy before opening the quarter."
		if _is_senior_snapshot() else
		"Select one card before filing the next-shift plan.",
	))
	_milestone_section.visible = not choices.is_empty()
	if choices.is_empty():
		_pending_milestone_confirmation = &""
		_report_continue_button.disabled = false
		_report_continue_button.tooltip_text = String(_snapshot.get(
			"continue_tooltip",
			"Acknowledge this career review and continue."
			if _is_senior_snapshot() else
			"File this report and begin next-shift planning.",
		))
		_queue_focus(_report_continue_button)
		return

	var index := 0
	for choice_value: Variant in choices:
		if index >= 3 or not choice_value is Dictionary:
			break
		var choice := choice_value as Dictionary
		var choice_id := StringName(choice.get("id", "milestone_%d" % index))
		var title := String(choice.get("title", choice.get("label", "MILESTONE")))
		var description := String(choice.get("description", choice.get("detail", "Permanent campaign benefit.")))
		var effect := String(choice.get("effect", choice.get("preview", "")))
		var doctrine := choice.get("doctrine", {}) as Dictionary
		var doctrine_label := String(doctrine.get("label", "")).strip_edges().to_upper()
		var strengths := _doctrine_terms(doctrine.get("strengths", []))
		var watchouts := _doctrine_terms(doctrine.get("watchouts", []))
		var primary_strength := _doctrine_primary_term(doctrine.get("strengths", []))
		var primary_watchout := _doctrine_primary_term(doctrine.get("watchouts", []))
		var strategy := choice.get("strategy", {}) as Dictionary
		var available := bool(choice.get("available", true))
		var locked_by_filed_choice := (
			_selected_milestone != &""
			and choice_id != _selected_milestone
		)
		var policy_glance_help := ""
		var policy_glance_risk := ""
		var policy_glance_board := ""
		var policy_glance_fund := ""
		var policy_glance_outcome := ""
		var button_copy := "%d  //  %s\n%s%s" % [
			index + 1,
			title.to_upper(),
			description,
			("\n%s" % effect if not effect.is_empty() else ""),
		]
		if not doctrine.is_empty():
			button_copy = "%d  //  %s\n%s%s\nEDGE %s  //  WATCH %s" % [
				index + 1,
				doctrine_label,
				title.to_upper(),
				("  //  %s" % effect if not effect.is_empty() else ""),
				primary_strength,
				primary_watchout,
			]
		elif not strategy.is_empty():
			var policy_metrics := _senior_policy_metric_glance(choice, effect)
			policy_glance_fund = String(policy_metrics.get("fund", "$ --"))
			policy_glance_outcome = String(policy_metrics.get("outcome", "QUARTER EFFECT"))
			policy_glance_help = String(choice.get("glance_help", _senior_policy_focus_glance(
				String(strategy.get("score_edge", "QUARTER TRADEOFF")),
			)))
			policy_glance_risk = String(choice.get("glance_risk", _senior_policy_focus_glance(
				String(strategy.get("score_watch", "CLOSING LEDGER")),
			)))
			policy_glance_board = _senior_policy_board_glance(strategy)
			# Preserve two intentional visual rows for the child metric chips.
			# TextServer collapses truly empty lines inside Button copy, while a
			# single space retains the line height without adding visible prose.
			button_copy = "%d  //  %s\n \n \n+ %s  /  ! %s  /  B %s" % [
				index + 1,
				title.to_upper(),
				policy_glance_help,
				policy_glance_risk,
				policy_glance_board,
			]
		var button := _make_button(
			"MilestoneChoice_%s" % _safe_node_suffix(String(choice_id)),
			button_copy,
			&"DecisionChoiceButton",
		)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(
			0.0,
			96.0 if not strategy.is_empty() else (108.0 if not doctrine.is_empty() else 88.0),
		)
		if not strategy.is_empty():
			button.add_theme_font_size_override("font_size", 12)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.shortcut = _shortcut([KEY_1, KEY_2, KEY_3][index])
		# A selected milestone in the incoming snapshot is authoritative. Keep
		# its card readable, but lock every alternative so a later click cannot
		# visually replace the permanent filing while the domain rejects it.
		button.disabled = not available or locked_by_filed_choice
		if not strategy.is_empty():
			var policy_signal_copy := "+ %s  /  ! %s  /  B %s" % [
				policy_glance_help,
				policy_glance_risk,
				policy_glance_board,
			]
			button.set_meta(
				"visible_card_text",
				"%d  //  %s\n%s  //  %s\n%s" % [
					index + 1,
					title.to_upper(),
					policy_glance_fund,
					policy_glance_outcome,
					policy_signal_copy,
				],
			)
			_add_senior_policy_metric_chips(
				button,
				"%d  //  %s" % [index + 1, title.to_upper()],
				policy_glance_fund,
				policy_glance_outcome,
				policy_signal_copy,
			)
		var default_tooltip := String(choice.get(
			"tooltip",
			choice.get(
				"unavailable_reason",
				"File %s as this quarter's capital policy." % title
				if _is_senior_snapshot() else
				"Choose %s as the permanent probation milestone." % title,
			),
		))
		if not doctrine.is_empty():
			default_tooltip = "%s\n\n%s\n%s\n\nFULL EDGE  //  %s\nWATCH  //  %s\n\nPLAYBOOK  //  %s" % [
				default_tooltip,
				description,
				String(doctrine.get("summary", "This doctrine remains permanent for probation.")),
				strengths,
				watchouts,
				String(doctrine.get("playbook", "Use the safeguard forecast to cover its obligations.")),
			]
		elif not strategy.is_empty():
			default_tooltip = "QUARTER EFFECT  //  FUND %s  //  RESULT %s\nAT A GLANCE  //  + HELPS %s  //  ! RISKS %s  //  B BOARD %s\n\n%s\n\n%s\n%s\n\nSCORE EDGE  //  %s\nSCORE WATCH  //  %s\n%s  //  %s" % [
				policy_glance_fund,
				policy_glance_outcome,
				policy_glance_help,
				policy_glance_risk,
				policy_glance_board,
				default_tooltip,
				description,
				effect,
				String(strategy.get("score_edge", "QUARTER TRADEOFF")),
				String(strategy.get("score_watch", "CLOSING LEDGER")),
				String(strategy.get("board_name", "ANNUAL BOARD MANDATE")).to_upper(),
				String(strategy.get("board_fit", "FILE THE ANNUAL BOARD MANDATE FIRST")),
			]
			var prior_year_fit := strategy.get("prior_year_fit", {}) as Dictionary
			if bool(prior_year_fit.get("visible", false)):
				default_tooltip += "\n\nLAST YEAR  //  %s  //  %s\n%s" % [
					String(prior_year_fit.get("fit_label", "NO DIRECT EDGE")),
					String(prior_year_fit.get("focus_detail", "ANNUAL SAFEGUARD")),
					String(prior_year_fit.get("fit_detail", "Use the annual receipt to cover this safeguard.")),
				]
		if locked_by_filed_choice:
			default_tooltip = "LOCKED  //  %s is already the permanent filing for this review." % (
				String(_selected_milestone).replace("_", " ").to_upper()
			)
		button.tooltip_text = default_tooltip
		if not strategy.is_empty():
			button.set_meta(
				"glance_symbol_language",
				"plus_benefit_bang_tradeoff_b_board",
			)
			button.set_meta("glance_help", policy_glance_help)
			button.set_meta("glance_risk", policy_glance_risk)
			button.set_meta("glance_board", policy_glance_board)
			button.set_meta("glance_fund", policy_glance_fund)
			button.set_meta("glance_outcome", policy_glance_outcome)
			button.set_meta(
				"accessible_text",
				"%s. Fund impact %s. Primary result %s. Helps %s. Risks %s. Board fit %s. %s" % [
					title,
					policy_glance_fund,
					policy_glance_outcome,
					policy_glance_help,
					policy_glance_risk,
					policy_glance_board,
					default_tooltip.replace("\n", " "),
				],
			)
		button.set_meta("choice_id", choice_id)
		button.set_meta(
			"choice_title",
			"%s  //  %s" % [doctrine_label, title.to_upper()]
			if not doctrine_label.is_empty() else
			title.to_upper(),
		)
		button.set_meta("doctrine_id", String(choice_id) if not doctrine.is_empty() else "")
		button.set_meta("confirmation_required", bool(choice.get("confirmation_required", false)))
		button.set_meta("confirmation_label", String(choice.get(
			"confirmation_label",
			"CONFIRM PERMANENT FILING  [C]",
		)))
		button.set_meta("confirmation_tooltip", String(choice.get(
			"confirmation_tooltip",
			"Confirm this irreversible filing.",
		)))
		button.set_meta("confirmation_stake_marks", maxi(0, int(choice.get("stake_marks", 0))))
		button.pressed.connect(_on_milestone_pressed.bind(choice_id))
		_milestone_buttons_host.add_child(button)
		_milestone_buttons[choice_id] = button
		index += 1
	if (
		_selected_milestone != &""
		and (
			not _milestone_buttons.has(_selected_milestone)
			or (_milestone_buttons[_selected_milestone] as Button).disabled
		)
	):
		_selected_milestone = &""
		_snapshot.erase("selected_milestone")
	if (
		_pending_milestone_confirmation != &""
		and not _milestone_buttons.has(_pending_milestone_confirmation)
	):
		_pending_milestone_confirmation = &""
	_update_milestone_selection()
	var needs_choice := (
		bool(_snapshot.get("choice_required", true))
		and (
			_selected_milestone == &""
			or not _milestone_buttons.has(_selected_milestone)
			or (_milestone_buttons[_selected_milestone] as Button).disabled
		)
	)
	_report_continue_button.disabled = needs_choice
	_report_continue_button.tooltip_text = (
		String(_snapshot.get(
			"choice_required_tooltip",
			"Choose one available capital policy before continuing."
			if _is_senior_snapshot() else
			"Choose one milestone card before continuing.",
		))
		if needs_choice else
		String(_snapshot.get("continue_tooltip", "File this report with the selected choice."))
	)
	_apply_pending_milestone_confirmation()
	_apply_responsive_layout()
	if needs_choice:
		var first_available: Button = null
		for button_value: Variant in _milestone_buttons.values():
			var candidate := button_value as Button
			if candidate != null and not candidate.disabled:
				first_available = candidate
				break
		_queue_focus(first_available if first_available != null else _report_panel)
	else:
		_queue_focus(_report_continue_button)


func _doctrine_terms(value: Variant) -> String:
	if not value is Array:
		return ""
	var terms: Array[String] = []
	for item: Variant in value as Array:
		var term := String(item).strip_edges().to_upper()
		if not term.is_empty():
			terms.append(term)
	return " // ".join(terms)


func _doctrine_primary_term(value: Variant) -> String:
	if not value is Array or (value as Array).is_empty():
		return "UNLISTED"
	return String((value as Array)[0]).strip_edges().to_upper()


func _update_milestone_selection() -> void:
	for choice_id: StringName in _milestone_buttons:
		var button := _milestone_buttons[choice_id]
		button.theme_type_variation = (
			&"SelectedChoiceButton"
			if choice_id == _selected_milestone else
			&"DecisionChoiceButton"
		)
	_milestone_hint_label.text = (
		_pending_milestone_confirmation_hint()
		if _pending_milestone_confirmation != &"" else
		"SELECTED  //  %s" % String(
			(_milestone_buttons[_selected_milestone] as Button).get_meta(
				"choice_title",
				String(_selected_milestone).replace("_", " ").to_upper(),
			)
		)
		if _selected_milestone != &"" else
		String(_snapshot.get(
			"choice_hint",
			"Select one capital policy before opening the quarter."
			if _is_senior_snapshot() else
			"Select one card before filing the next-shift plan.",
		))
	)


func _apply_pending_milestone_confirmation() -> void:
	if (
		_pending_milestone_confirmation == &""
		or not _milestone_buttons.has(_pending_milestone_confirmation)
	):
		return
	var button := _milestone_buttons[_pending_milestone_confirmation] as Button
	if button == null or button.disabled:
		return
	_report_continue_button.text = String(button.get_meta(
		"confirmation_label",
		"CONFIRM PERMANENT FILING  [C]",
	))
	_report_continue_button.set_meta(
		"exact_action_label",
		_report_continue_button.text,
	)
	_style_report_action(_report_continue_button, &"irreversible")
	_report_continue_button.tooltip_text = String(button.get_meta(
		"confirmation_tooltip",
		"Confirm this irreversible filing.",
	))
	_report_continue_button.disabled = false
	_sync_report_action_accessibility()
	_queue_focus(_report_continue_button)


func _pending_milestone_confirmation_hint() -> String:
	if not _milestone_buttons.has(_pending_milestone_confirmation):
		return ""
	var button := _milestone_buttons[_pending_milestone_confirmation] as Button
	if button == null:
		return ""
	var title := String(button.get_meta(
		"choice_title",
		String(_pending_milestone_confirmation).replace("_", " ").to_upper(),
	))
	var stake := maxi(0, int(button.get_meta("confirmation_stake_marks", 0)))
	return "REVIEWED  //  %s  //  PRESS C TO CONFIRM %d-MARK STAKE" % [title, stake]


func _pending_milestone_confirmation_snapshot() -> Dictionary:
	if not _milestone_buttons.has(_pending_milestone_confirmation):
		return {}
	var button := _milestone_buttons[_pending_milestone_confirmation] as Button
	if button == null or button.disabled:
		return {}
	return {
		"id": String(_pending_milestone_confirmation),
		"title": String(button.get_meta(
			"choice_title",
			String(_pending_milestone_confirmation).replace("_", " ").to_upper(),
		)),
		"stake_marks": maxi(0, int(button.get_meta("confirmation_stake_marks", 0))),
		"confirmation_label": String(button.get_meta("confirmation_label", "")),
		"confirmation_tooltip": String(button.get_meta("confirmation_tooltip", "")),
	}


func _update_ledger_labels(targets: Array[Dictionary]) -> void:
	var ledgers := _normalized_ledgers()
	for index: int in range(3):
		var target: Dictionary = targets[index]
		var ledger: Dictionary = ledgers[index]
		var title_label := target["title"] as Label
		var value_label := target["value"] as Label
		var detail_label := target["detail"] as Label
		var card := target.get("card") as PanelContainer
		title_label.text = String(ledger.get("label", "LEDGER %d" % (index + 1))).to_upper()
		value_label.text = _ledger_display_value(ledger)
		var exact_detail := String(ledger.get("detail", "CUMULATIVE")).strip_edges().to_upper()
		var glance_text := String(
			ledger.get("glance", _compact_ledger_glance(exact_detail))
		).strip_edges().to_upper()
		detail_label.text = glance_text
		detail_label.tooltip_text = exact_detail
		detail_label.set_meta("accessible_text", exact_detail)
		var accessible_text := "%s %s. %s" % [
			title_label.text,
			value_label.text,
			exact_detail,
		]
		if card != null:
			card.tooltip_text = exact_detail
			card.set_meta("accessible_text", accessible_text)
			card.set_meta("glance_text", glance_text)
			card.set_meta("exact_detail", exact_detail)
			card.set_meta("metric_first", true)


func _compact_ledger_glance(exact_detail: String) -> String:
	# The card keeps the exact authored accounting in progressive detail. Only
	# the visible scan line contracts predictable bookkeeping phrases.
	return exact_detail.replace("FIVE-SHIFT", "5-SHIFT").replace(
		"TWO-SHIFT", "2-SHIFT"
	).replace("AVERAGE", "AVG").replace("CREDIT HARVESTED", "CREDIT")


func _normalized_ledgers() -> Array[Dictionary]:
	var defaults: Array[Dictionary] = [
		{"label": "EGGS FILED", "value": 0, "detail": "CUMULATIVE"},
		{"label": "FEED FUND", "value": 0, "format": "currency_cents", "detail": "BANKED"},
		{"label": "SHELL INTEGRITY", "value": 100, "format": "percent", "detail": "CAMPAIGN QUALITY"},
	]
	var source: Variant = _snapshot.get(
		"ledgers",
		_snapshot.get("cumulative_ledgers", []),
	)
	if source is Array:
		var source_array := source as Array
		for index: int in range(mini(3, source_array.size())):
			if source_array[index] is Dictionary:
				for key: Variant in source_array[index]:
					defaults[index][key] = source_array[index][key]
			else:
				defaults[index]["value"] = source_array[index]
	elif source is Dictionary:
		var source_dict := source as Dictionary
		var known: Array[Dictionary] = [
			{"keys": ["eggs_total", "eggs", "eggs_filed"], "label": "EGGS FILED"},
			{"keys": ["feed_fund_cents", "fund_cents", "revenue_cents"], "label": "FEED FUND", "format": "currency_cents"},
			{"keys": ["shell_integrity", "quality_percent", "quality"], "label": "SHELL INTEGRITY", "format": "percent"},
		]
		for index: int in range(3):
			var descriptor: Dictionary = known[index]
			for key: String in descriptor["keys"]:
				if source_dict.has(key):
					defaults[index]["value"] = source_dict[key]
					defaults[index]["label"] = descriptor["label"]
					if descriptor.has("format"):
						defaults[index]["format"] = descriptor["format"]
					break
	return defaults


func _ledger_display_value(ledger: Dictionary) -> String:
	if ledger.has("display"):
		return String(ledger["display"])
	var value: Variant = ledger.get("value", ledger.get("value_cents", 0))
	match String(ledger.get("format", "number")):
		"currency", "currency_cents":
			return "$%.2f" % (float(value) / 100.0)
		"percent":
			return "%d%%" % int(value)
	return _format_integer(int(value)) if value is int or value is float else String(value)


func _campaign_passed() -> bool:
	if _snapshot.has("passed"):
		return bool(_snapshot["passed"])
	return String(_snapshot.get("result", "fail")).to_lower() in ["pass", "passed", "success"]


func _read_view(snapshot: Dictionary) -> StringName:
	if bool(snapshot.get("first_load", false)):
		return VIEW_TITLE
	if bool(snapshot.get("final", false)):
		return VIEW_FINAL
	if bool(snapshot.get("between_shifts", false)):
		return VIEW_REPORT
	var raw := String(snapshot.get(
		"view",
		snapshot.get("campaign_view", snapshot.get("screen", VIEW_ACTIVE)),
	)).to_lower()
	match raw:
		"title", "first_load", "new_game":
			return VIEW_TITLE
		"between_shift", "between_shifts", "report", "shift_report":
			return VIEW_REPORT
		"contract_board", "farm_mutual", "market_contract":
			return VIEW_CONTRACT_BOARD
		"final", "complete", "campaign_review":
			return VIEW_FINAL
	return VIEW_ACTIVE


func _apply_responsive_layout() -> void:
	if _modal_scroll == null or _modal_center == null:
		return
	var viewport_size := size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = get_viewport_rect().size
	# Leave a narrow gutter for the vertical scrollbar when portrait content
	# wraps into several rows; otherwise a full-width panel loses its right edge.
	var panel_width := maxf(286.0, viewport_size.x - 52.0)
	var modal_height := maxf(240.0, viewport_size.y - 84.0)
	var narrow := viewport_size.x < 720.0
	var compact := viewport_size.x < 1100.0
	var sticky_final_actions := _view == VIEW_FINAL and not narrow
	if _final_sticky_action_bar != null:
		_final_sticky_action_bar.visible = sticky_final_actions
	if _final_actions != null:
		_final_actions.visible = not sticky_final_actions
	_modal_scroll.offset_bottom = -92.0 if sticky_final_actions else -18.0
	if _report_safeguard_grid != null:
		_report_safeguard_grid.columns = 1 if narrow else 2
	if _report_score_receipt_grid != null:
		_report_score_receipt_grid.columns = 2 if narrow else 5
	if _report_safeguard_pass_grid != null:
		_report_safeguard_pass_grid.columns = 2 if narrow else 5
	if _final_safeguard_grid != null:
		_final_safeguard_grid.columns = 2 if narrow else 5
	if _final_ending_glance_grid != null:
		_final_ending_glance_grid.columns = 1 if narrow else 3

	_modal_center.custom_minimum_size = Vector2(panel_width, modal_height)
	_title_panel.custom_minimum_size = Vector2(minf(760.0, panel_width), 0.0)
	_report_panel.custom_minimum_size = Vector2(minf(REPORT_DESKTOP_WIDTH, panel_width), 0.0)
	_final_panel.custom_minimum_size = Vector2(minf(860.0, panel_width), 0.0)
	if _replacement_confirmation_panel != null:
		_replacement_confirmation_panel.custom_minimum_size = Vector2(minf(560.0, panel_width), 0.0)
	if _title_challenge_selector != null:
		_title_challenge_selector.custom_minimum_size.x = 220.0 if narrow else 250.0
	_report_heading_stack.custom_minimum_size.x = (
		0.0 if compact else REPORT_HEADING_DESKTOP_WIDTH
	)

	var report_score_panel := _metric_panel(_report_score_label)
	var report_shift_panel := _metric_panel(_report_shift_delta_label)
	var report_rank_panel := _metric_panel(_report_rank_label)
	var final_score_panel := _metric_panel(_final_score_label)
	var final_rank_panel := _metric_panel(_final_rank_label)
	report_score_panel.custom_minimum_size.x = 132.0
	report_shift_panel.custom_minimum_size.x = 126.0
	report_rank_panel.custom_minimum_size.x = 260.0 if narrow else 236.0
	final_score_panel.custom_minimum_size.x = 190.0
	final_rank_panel.custom_minimum_size.x = 260.0 if narrow else 276.0

	var ledger_width := 260.0 if narrow else 220.0
	for row in [_report_ledger_row, _final_ledger_row]:
		if row == null:
			continue
		for child in row.get_children():
			if child is PanelContainer:
				(child as PanelContainer).custom_minimum_size.x = ledger_width

	if _credit_memo_card != null:
		_credit_memo_card.custom_minimum_size.x = (
			260.0 if narrow else REPORT_CREDIT_DESKTOP_WIDTH
		)
	if _hen_highlight_card != null:
		_hen_highlight_card.custom_minimum_size.x = (
			260.0 if narrow else REPORT_HIGHLIGHT_DESKTOP_WIDTH
		)

	# Preserve three equal comparison columns on small laptops, then switch to
	# deliberate full-width cards before their contents become cramped. HFlow's
	# generic last-line alignment leaves a lone third card visually stranded.
	var report_content_width := maxf(
		1.0,
		minf(REPORT_DESKTOP_WIDTH, panel_width) - 52.0,
	)
	if _objective_order_strip != null:
		# The strip sits inside the objective card's own 16px side padding, so its
		# stacked width must leave room for that nested inset on narrow screens.
		var order_width := maxf(210.0, report_content_width - 36.0)
		if viewport_size.x >= 800.0:
			order_width = clampf((report_content_width - 16.0) / 3.0, 210.0, 290.0)
		for child in _objective_order_strip.get_children():
			if child is PanelContainer:
				(child as PanelContainer).custom_minimum_size.x = order_width
	var milestone_width := report_content_width
	if viewport_size.x >= 800.0:
		milestone_width = clampf(
			# Two 10px gaps plus a small allowance for panel borders and integer
			# rounding keep the final column from wrapping at exactly 800px.
			(report_content_width - 28.0) / 3.0,
			220.0,
			285.0,
		)
	for button_value in _milestone_buttons.values():
		var milestone_button := button_value as Button
		if milestone_button != null:
			milestone_button.custom_minimum_size.x = milestone_width

	if _report_continue_button != null:
		_report_continue_button.custom_minimum_size.x = (
			270.0 if _pending_milestone_confirmation != &"" else 220.0
		)
	if _final_continue_button != null:
		_final_continue_button.custom_minimum_size.x = 260.0

	_position_badge(_view != VIEW_ACTIVE)


func _position_badge(modal_open: bool) -> void:
	var available_width := size.x if size.x > 1.0 else get_viewport_rect().size.x
	if modal_open or available_width < 720.0:
		# Senior reports pair a full career-mode label with year/quarter context.
		# Give both labels enough room instead of ellipsizing the mode at 1280x720.
		_day_badge.offset_left = -318.0
		_day_badge.offset_top = 14.0
		_day_badge.offset_right = -18.0
		_day_badge.offset_bottom = 82.0
	else:
		# This slot sits between the routing strip and Flockwatch button in the
		# 1280x720 office HUD, so the badge never covers hens or workstations.
		_day_badge.offset_left = -490.0
		_day_badge.offset_top = _active_badge_top
		_day_badge.offset_right = -268.0
		_day_badge.offset_bottom = _active_badge_top + 68.0


func _on_final_sticky_primary_pressed() -> void:
	if _campaign_passed():
		_on_continue_campaign_pressed()
	else:
		_on_new_campaign_pressed()


func _on_milestone_pressed(choice_id: StringName) -> void:
	if not _milestone_buttons.has(choice_id):
		return
	var pressed_button := _milestone_buttons[choice_id] as Button
	if pressed_button == null or pressed_button.disabled:
		return
	_selected_milestone = choice_id
	_snapshot["selected_milestone"] = choice_id
	if bool(pressed_button.get_meta("confirmation_required", false)):
		# Permanent-risk Board Books are inspected first and filed only through
		# the existing report action. A stray click or number-key press can never
		# reserve career marks by itself.
		_pending_milestone_confirmation = choice_id
		_update_milestone_selection()
		_apply_pending_milestone_confirmation()
		# This review state exists only in the presentation layer while the
		# simulation is paused. Let Office refresh its Web/accessibility mirror so
		# automation and assistive surfaces see the same uncommitted stake as the
		# player without mutating the authoritative Senior ledger.
		presentation_state_changed.emit()
		return
	_pending_milestone_confirmation = &""
	_update_milestone_selection()
	_report_continue_button.disabled = false
	_report_continue_button.tooltip_text = String(_snapshot.get(
		"continue_tooltip",
		"File this report with the selected choice.",
	))
	milestone_choice.emit(choice_id)


func _is_senior_snapshot() -> bool:
	return (
		String(_snapshot.get("status", "")).strip_edges().to_upper() == "SENIOR ROOST"
		or String(_snapshot.get("career_mode", "")).to_lower() == "senior_roost"
	)


func _on_continue_campaign_pressed() -> void:
	if (
		_pending_milestone_confirmation != &""
		and _milestone_buttons.has(_pending_milestone_confirmation)
	):
		var choice_id := _pending_milestone_confirmation
		var button := _milestone_buttons[choice_id] as Button
		if button != null and not button.disabled:
			_pending_milestone_confirmation = &""
			milestone_choice.emit(choice_id)
			return
	continue_campaign.emit()


func _on_market_contract_sign_requested(
	offer_id: StringName,
	clause_id: StringName,
	pricing_id: StringName,
) -> void:
	market_contract_sign_requested.emit(offer_id, clause_id, pricing_id)


func _on_market_contract_decline_requested() -> void:
	market_contract_decline_requested.emit()


func _on_new_campaign_pressed() -> void:
	if _view == VIEW_TITLE and _snapshot_continue_available() and not _title_new_file_setup:
		_title_new_file_setup = true
		_title_contract_terms_expanded = false
		_refresh_title()
		title_intake_phase_changed.emit(title_intake_phase())
		return
	if _campaign_replacement_requires_confirmation():
		_show_campaign_replacement_confirmation()
		return
	new_campaign.emit()


func _on_abandon_campaign_pressed() -> void:
	abandon_campaign.emit()


func _campaign_replacement_requires_confirmation() -> bool:
	if _view == VIEW_FINAL:
		return true
	return (
		_view == VIEW_TITLE
		and bool(_snapshot.get("continue_available", _snapshot.get("has_continue", false)))
	)


func _show_campaign_replacement_confirmation() -> void:
	if _replacement_confirmation_host == null:
		return
	_replacement_confirmation_origin = (
		_final_new_button
		if _view == VIEW_FINAL else
		find_child("NewCampaignButton", true, false) as Control
	)
	var resume_value: Variant = _snapshot.get("resume_summary", {})
	var resume_summary := resume_value as Dictionary if resume_value is Dictionary else {}
	var current_file := _format_resume_summary(resume_summary)
	if _view == VIEW_FINAL and resume_summary.is_empty():
		current_file = "DAY 5 / 5  //  SCORE %d  //  %s" % [
			clampi(int(_snapshot.get("score", 0)), 0, PROBATION_SCORE_LIMIT),
			String(_snapshot.get("rank", "FILE CLOSED")).to_upper(),
		]
	var selected_contract := _selected_challenge_contract()
	var selected_contract_line := "NEW CHALLENGE CONTRACT  //  %s" % _challenge_contract_label(
		selected_contract,
		false,
	)
	_replacement_confirmation_body.text = (
		"Starting fresh replaces the resumable coop file shown below.\n\n%s\n\n%s\n\n"
		+ "The current file remains untouched until the new checkpoint has been written and verified. "
		+ "Choose Keep Current File to return without changing anything."
	) % [current_file, selected_contract_line]
	_replacement_confirmation_host.visible = true
	_queue_focus(_replacement_confirmation_cancel)


func _cancel_campaign_replacement() -> void:
	_hide_campaign_replacement(true)


func _confirm_campaign_replacement() -> void:
	_hide_campaign_replacement(false)
	new_campaign.emit()


func _hide_campaign_replacement(restore_focus: bool) -> void:
	if _replacement_confirmation_host == null or not _replacement_confirmation_host.visible:
		return
	_replacement_confirmation_host.visible = false
	if restore_focus and _replacement_confirmation_origin != null and is_instance_valid(_replacement_confirmation_origin):
		_queue_focus(_replacement_confirmation_origin)
	_replacement_confirmation_origin = null


func _queue_focus(control: Control) -> void:
	if control == null:
		return
	if control is BaseButton and (control as BaseButton).disabled:
		return
	control.call_deferred("grab_focus")


func _panel_content(
	panel: PanelContainer,
	horizontal_margin: int,
	vertical_margin: int,
	separation: int,
) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", horizontal_margin)
	margin.add_theme_constant_override("margin_right", horizontal_margin)
	margin.add_theme_constant_override("margin_top", vertical_margin)
	margin.add_theme_constant_override("margin_bottom", vertical_margin)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", separation)
	margin.add_child(content)
	return content


func _build_ledger_row(parent: VBoxContainer, prefix: String, targets: Array[Dictionary]) -> void:
	var row := HFlowContainer.new()
	row.name = "%sCumulativeLedgers" % prefix
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 8)
	parent.add_child(row)
	if prefix == "Report":
		_report_ledger_row = row
	else:
		_final_ledger_row = row
	for index: int in range(3):
		var card := PanelContainer.new()
		card.name = "%sCumulativeLedger%d" % [prefix, index + 1]
		card.custom_minimum_size = Vector2(220.0, 60.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override(
			"panel",
			_panel_style(NAVY_RAISED, Color("4a5d66"), 8, 1),
		)
		row.add_child(card)
		var stack := _panel_content(card, 13, 7, 1)
		var metric_line := HBoxContainer.new()
		metric_line.name = "%sLedgerMetricLine%d" % [prefix, index + 1]
		metric_line.add_theme_constant_override("separation", 9)
		stack.add_child(metric_line)
		var value_label := _make_label("0", 19, CREAM)
		value_label.name = "%sLedgerValue%d" % [prefix, index + 1]
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		metric_line.add_child(value_label)
		var title_label := _make_label("LEDGER", 10, MUTED)
		title_label.name = "%sLedgerTitle%d" % [prefix, index + 1]
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		metric_line.add_child(title_label)
		var detail_label := _make_label("CUMULATIVE", 10, TEAL)
		detail_label.name = "%sLedgerDetail%d" % [prefix, index + 1]
		detail_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		detail_label.max_lines_visible = 1
		detail_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		stack.add_child(detail_label)
		targets.append({
			"card": card,
			"title": title_label,
			"value": value_label,
			"detail": detail_label,
		})


func _make_metric(
	label_name: String,
	value: String,
	caption: String,
	width: float = 150.0,
	value_font_size: int = 20,
	wrap_value: bool = false,
) -> Label:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 68.0 if wrap_value else 60.0)
	panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1d3039"), Color("53656d"), 8, 1),
	)
	var stack := _panel_content(panel, 13, 7, 0)
	var caption_label := _make_label(caption, 9, MUTED)
	caption_label.name = "%sCaption" % label_name
	stack.add_child(caption_label)
	var value_label := _make_label(value, value_font_size, CREAM)
	value_label.name = label_name
	if wrap_value:
		value_label.custom_minimum_size.y = 34.0
		value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		value_label.max_lines_visible = 2
		value_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	else:
		value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stack.add_child(value_label)
	return value_label


func _decorate_report_rank_metric() -> void:
	if _report_rank_label == null:
		return
	var stack := _report_rank_label.get_parent() as VBoxContainer
	var panel := _metric_panel(_report_rank_label)
	if stack == null or panel == null:
		return
	stack.remove_child(_report_rank_label)
	var value_row := HBoxContainer.new()
	value_row.name = "ReportRankValueRow"
	value_row.add_theme_constant_override("separation", 5)
	value_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	stack.add_child(value_row)
	_report_rank_icon = TextureRect.new()
	_report_rank_icon.name = "ReportRankIcon"
	_report_rank_icon.custom_minimum_size = Vector2(20.0, 20.0)
	_report_rank_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_report_rank_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_report_rank_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	_report_rank_icon.texture = ManagementTheme.action_icon(&"rank_crest")
	_report_rank_icon.set_meta("semantic_icon", "rank_crest")
	value_row.add_child(_report_rank_icon)
	_report_rank_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_row.add_child(_report_rank_label)
	_report_rank_progress = ProgressBar.new()
	_report_rank_progress.name = "ReportRankProgress"
	_report_rank_progress.custom_minimum_size = Vector2(0.0, 4.0)
	_report_rank_progress.min_value = 0.0
	_report_rank_progress.max_value = 10_000.0
	_report_rank_progress.show_percentage = false
	_report_rank_progress.mouse_filter = Control.MOUSE_FILTER_STOP
	_report_rank_progress.visible = false
	_report_rank_progress.add_theme_stylebox_override(
		"background",
		_panel_style(Color("263b43"), Color("263b43"), 2, 0),
	)
	_report_rank_progress.add_theme_stylebox_override(
		"fill",
		_panel_style(Color("c9a54b"), Color("c9a54b"), 2, 0),
	)
	stack.add_child(_report_rank_progress)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_meta("visual_reward", "rank_crest")


func _refresh_report_rank_presentation(rank_caption: String) -> void:
	if _report_rank_label == null:
		return
	var receipt := _report_score_receipt()
	var promoted := _report_is_promotion()
	var promotion_from := String(receipt.get("rank_before_label", "")).to_upper()
	var visible_caption := "PROMOTED" if promoted else rank_caption
	_set_metric_caption(_report_rank_label, visible_caption)
	var caption := _metric_panel(_report_rank_label).find_child(
		"ReportRankCaption",
		true,
		false,
	) as Label
	if caption != null:
		caption.add_theme_color_override("font_color", BRASS if promoted else MUTED)
	var exact_rank := (
		"PROMOTED  //  %s  //  FROM %s" % [_report_rank_label.text, promotion_from]
		if promoted else
		"%s  //  %s" % [rank_caption, _report_rank_label.text]
	)
	_report_rank_label.tooltip_text = exact_rank
	_report_rank_label.set_meta("accessible_text", exact_rank)
	_report_rank_label.set_meta("visual_reward", "rank_crest")
	var panel := _metric_panel(_report_rank_label)
	if panel != null:
		panel.add_theme_stylebox_override(
			"panel",
			_panel_style(
				Color("25352f") if promoted else Color("1d3039"),
				Color("c9a54b") if promoted else Color("53656d"),
				8,
				1,
			),
		)
		panel.tooltip_text = exact_rank
		panel.set_meta("accessible_text", exact_rank)
		panel.set_meta("visual_reward", "rank_crest")
		panel.set_meta("rank_change", "promotion" if promoted else String(receipt.get("rank_change", "steady")))
		panel.set_meta("promotion_from", promotion_from if promoted else "")
		panel.set_meta("promotion_to", _report_rank_label.text if promoted else "")
	if _report_rank_icon != null:
		_report_rank_icon.tooltip_text = exact_rank
		_report_rank_icon.set_meta("accessible_text", exact_rank)
		_report_rank_icon.set_meta("rank_title", _report_rank_label.text)
		_report_rank_icon.set_meta("promotion_stamp", promoted)
	_refresh_report_rank_progress(exact_rank)


func _refresh_report_rank_progress(exact_rank: String) -> void:
	if _report_rank_progress == null:
		return
	var raw_progress: Variant = _snapshot.get("rank_progress", {})
	var progress := raw_progress as Dictionary if raw_progress is Dictionary else {}
	var available := not _is_senior_snapshot() and not progress.is_empty()
	_report_rank_progress.visible = available
	var panel := _metric_panel(_report_rank_label)
	if not available:
		_report_rank_progress.value = 0.0
		_report_rank_progress.tooltip_text = ""
		_report_rank_progress.set_meta("threshold_backed", false)
		_report_rank_progress.set_meta("promotion_opportunity", false)
		_report_rank_progress.set_meta("projected_score", 0)
		if panel != null:
			panel.set_meta("rank_progress_visible", false)
			panel.set_meta("promotion_opportunity", false)
		return
	var progress_basis_points := clampi(
		int(progress.get("progress_basis_points", 0)),
		0,
		10_000,
	)
	var current_score := int(progress.get("current_score", 0))
	var next_threshold := int(progress.get("next_threshold", 100))
	var points_to_next := maxi(0, int(progress.get("points_to_next", 0)))
	var next_rank_label := String(progress.get("next_rank_label", "TOP RANK")).to_upper()
	var complete := bool(progress.get("complete", false))
	var objective_value: Variant = _snapshot.get("next_objective", {})
	var objective := objective_value as Dictionary if objective_value is Dictionary else {}
	var opportunity_value: Variant = objective.get("promotion_opportunity", {})
	var opportunity := opportunity_value as Dictionary if opportunity_value is Dictionary else {}
	var promotion_available := (
		not _is_senior_snapshot()
		and bool(opportunity.get("available", false))
		and int(opportunity.get("next_threshold", -1)) == next_threshold
	)
	var detail := (
		"%s  //  SCORE %d  //  TOP RANK" % [exact_rank, current_score]
		if complete else
		"%s  //  SCORE %d / %d  //  %d TO %s" % [
			exact_rank,
			current_score,
			next_threshold,
			points_to_next,
			next_rank_label,
		]
	)
	if promotion_available:
		detail += "  //  NEXT ORDER BUNDLE CAN PROMOTE"
	_report_rank_progress.value = progress_basis_points
	_report_rank_progress.add_theme_stylebox_override(
		"fill",
		_panel_style(
			Color("f4df9d") if promotion_available else Color("c9a54b"),
			Color("f4df9d") if promotion_available else Color("c9a54b"),
			2,
			0,
		),
	)
	_report_rank_progress.tooltip_text = detail
	_report_rank_progress.set_meta("accessible_text", detail)
	_report_rank_progress.set_meta("threshold_backed", true)
	_report_rank_progress.set_meta("progress_basis_points", progress_basis_points)
	_report_rank_progress.set_meta("current_score", current_score)
	_report_rank_progress.set_meta("next_threshold", next_threshold)
	_report_rank_progress.set_meta("points_to_next", points_to_next)
	_report_rank_progress.set_meta("next_rank_label", next_rank_label)
	_report_rank_progress.set_meta("complete", complete)
	_report_rank_progress.set_meta("promotion_opportunity", promotion_available)
	_report_rank_progress.set_meta("projected_score", int(opportunity.get("projected_score", 0)))
	if panel != null:
		panel.tooltip_text = detail
		panel.set_meta("accessible_text", detail)
		panel.set_meta("rank_progress_visible", true)
		panel.set_meta("promotion_opportunity", promotion_available)


func _decorate_shift_delta_metric() -> void:
	if _report_shift_delta_label == null:
		return
	var stack := _report_shift_delta_label.get_parent() as VBoxContainer
	if stack == null:
		return
	var caption := stack.get_node_or_null("ReportShiftDeltaCaption") as Label
	if caption == null:
		return
	stack.remove_child(caption)
	var caption_row := HBoxContainer.new()
	caption_row.name = "ReportShiftDeltaCaptionRow"
	caption_row.add_theme_constant_override("separation", 4)
	caption_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(caption_row)
	stack.move_child(caption_row, 0)
	_report_shift_delta_icon = TextureRect.new()
	_report_shift_delta_icon.name = "ReportShiftDeltaIcon"
	_report_shift_delta_icon.custom_minimum_size = Vector2(16.0, 16.0)
	_report_shift_delta_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_report_shift_delta_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_report_shift_delta_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	_report_shift_delta_icon.visible = false
	caption_row.add_child(_report_shift_delta_icon)
	caption.mouse_filter = Control.MOUSE_FILTER_STOP
	caption_row.add_child(caption)
	var panel := _metric_panel(_report_shift_delta_label)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_meta("delta_metric", true)


func _refresh_shift_delta_icon(score_delta: int, available: bool) -> void:
	if _report_shift_delta_icon == null:
		return
	_report_shift_delta_icon.visible = available and not _is_senior_snapshot()
	if not available:
		_report_shift_delta_icon.texture = null
		_report_shift_delta_icon.set_meta("semantic_icon", "score_pending")
		_report_shift_delta_icon.set_meta("delta_direction", "pending")
		return
	var icon_kind: StringName = &"score_sum"
	_report_shift_delta_icon.texture = ManagementTheme.action_icon(icon_kind)
	_report_shift_delta_icon.set_meta("semantic_icon", String(icon_kind))
	_report_shift_delta_icon.set_meta("delta_direction", (
		"gain" if score_delta > 0 else ("loss" if score_delta < 0 else "even")
	))


func _refresh_shift_delta_semantics(
	authored_caption: String,
	visible_caption: String,
	senior: bool,
) -> void:
	if _report_shift_delta_label == null:
		return
	var detail := _report_shift_delta_label.tooltip_text
	var accessible_text := "%s %s" % [
		authored_caption,
		_report_shift_delta_label.text,
	]
	if not detail.is_empty():
		accessible_text += ". %s" % detail
	_report_shift_delta_label.set_meta("accessible_text", accessible_text)
	var panel := _metric_panel(_report_shift_delta_label)
	panel.tooltip_text = detail
	panel.set_meta("authored_metric_caption", authored_caption)
	panel.set_meta("visible_metric_caption", visible_caption)
	panel.set_meta("compact_delta_caption", not senior)
	var caption := _report_shift_delta_label.get_parent().find_child(
		"ReportShiftDeltaCaption",
		true,
		false,
	) as Label
	if caption != null:
		caption.tooltip_text = authored_caption
		caption.set_meta("accessible_text", authored_caption)
	if _report_shift_delta_icon != null:
		_report_shift_delta_icon.visible = _report_shift_delta_icon.visible and not senior
		_report_shift_delta_icon.tooltip_text = accessible_text
		_report_shift_delta_icon.set_meta("accessible_text", accessible_text)


func _metric_panel(value_label: Label) -> PanelContainer:
	var ancestor: Node = value_label
	while ancestor != null:
		if ancestor is PanelContainer:
			return ancestor as PanelContainer
		ancestor = ancestor.get_parent()
	return null


func _set_metric_caption(value_label: Label, caption: String) -> void:
	if value_label == null:
		return
	var panel := _metric_panel(value_label)
	if panel == null:
		return
	var caption_label := panel.find_child(
		"%sCaption" % value_label.name,
		true,
		false,
	) as Label
	if caption_label != null:
		caption_label.text = caption.to_upper()


func _section_label(text: String) -> Label:
	var label := _make_label(text, 11, Color("d0b269"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _set_report_continue_presentation(exact_label: String) -> void:
	if _report_continue_button == null:
		return
	_report_continue_button.text = _compact_report_continue_label(exact_label)
	_report_continue_button.set_meta("exact_action_label", exact_label)
	_report_continue_button.set_meta("outcome_first_action", "advance")
	_style_report_action(_report_continue_button, &"advance")


func _compact_report_continue_label(exact_label: String) -> String:
	var label := exact_label.strip_edges()
	if label.begins_with("SELECT A POLICY") or label.begins_with("FILE POLICY"):
		return "FILE POLICY  [C]"
	if label.begins_with("SELECT A MANDATE"):
		return "FILE MANDATE  [C]"
	if label.begins_with("FILE REPORT & PLAN NEXT SHIFT"):
		return "NEXT SHIFT  [C]"
	if label.begins_with("PLAN NEXT SENIOR SHIFT"):
		return "NEXT SHIFT  [C]"
	if label.begins_with("BEGIN YEAR") and " PLANNING" in label:
		return label.replace("BEGIN YEAR", "YEAR").replace(" PLANNING", "")
	if label.begins_with("BEGIN QUARTER"):
		return label.replace("BEGIN QUARTER", "BEGIN Q")
	if label.begins_with("PLAN QUARTER"):
		return label.replace("PLAN QUARTER", "PLAN Q")
	return label


func _style_report_action(button: Button, icon_kind: StringName) -> void:
	if button == null:
		return
	button.icon = ManagementTheme.action_icon(icon_kind)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_constant_override("icon_separation", 5)
	button.autowrap_mode = TextServer.AUTOWRAP_OFF
	button.clip_text = false
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	var semantic_icon: String = String({
		&"requisitions": "requisition_sheet",
		&"shelve": "safe_shelve",
		&"advance": "advance_arrow",
		&"irreversible": "irreversible_warning",
	}.get(icon_kind, String(icon_kind)))
	button.set_meta("semantic_icon", semantic_icon)


func _sync_report_action_accessibility() -> void:
	for button: Button in [
		_report_requisitions_button,
		_report_shelve_button,
		_report_continue_button,
	]:
		if button == null:
			continue
		var exact_label := String(button.get_meta(
			"exact_action_label",
			button.text,
		)).strip_edges()
		var exact_help := button.tooltip_text.strip_edges()
		button.set_meta(
			"accessible_text",
			"%s %s" % [exact_label, exact_help]
			if not exact_help.is_empty() else exact_label,
		)


func _make_button(node_name: String, text: String, variation: StringName) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.clip_text = true
	button.theme_type_variation = variation
	button.focus_mode = Control.FOCUS_ALL
	return button


func _shortcut(keycode: Key) -> Shortcut:
	var shortcut := Shortcut.new()
	var event := InputEventKey.new()
	event.keycode = keycode
	shortcut.events = [event]
	return shortcut


func _panel_style(color: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _format_integer(value: int) -> String:
	var digits := str(absi(value))
	var formatted := ""
	for index: int in range(digits.length()):
		if index > 0 and (digits.length() - index) % 3 == 0:
			formatted += ","
		formatted += digits[index]
	return ("-" if value < 0 else "") + formatted


func _safe_node_suffix(value: String) -> String:
	return value.strip_edges().replace(" ", "_").replace("-", "_").replace("/", "_")
