class_name FarmerRelationsGalleryUI
extends VBoxContainer

## Compact public-credit campaign controls hosted inside Flockwatch.
##
## This surface is intent-only. Attribution, shift evidence, exact economics,
## authorization gates, standing, and receipts come from the authoritative
## farmer_relations_gallery projection.

signal campaign_requested(campaign_id: StringName)
signal presentation_context_changed

const ManagementTheme := preload("res://features/office/management_ui_theme.gd")
const FlockwatchDisclosureToggleScript := preload("res://features/office/flockwatch_disclosure_toggle.gd")

const CAMPAIGN_IDS: Array[StringName] = [
	&"layer_profile",
	&"clutch_results_board",
	&"farmer_method",
]
const CAMPAIGN_LABELS := {
	&"layer_profile": "LAYER PROFILE",
	&"clutch_results_board": "CLUTCH RESULTS BOARD",
	&"farmer_method": "FARMER'S METHOD",
}
const CAMPAIGN_GLANCE_LABELS := {
	&"layer_profile": "LAYER",
	&"clutch_results_board": "RESULTS",
	&"farmer_method": "METHOD",
}
const CAMPAIGN_ACTIONS := {
	&"layer_profile": "CREDIT LAYER",
	&"clutch_results_board": "POST RESULTS",
	&"farmer_method": "FARMER METHOD",
}

const COLOR_INK := Color("e9edf0")
const COLOR_MUTED := Color("aeb8c4")
const COLOR_BRASS := Color("e7c56e")
const COLOR_TEAL := Color("73b5a7")
const COLOR_RUST := Color("d68a68")
const COLOR_PAPER := Color("eee1bf")
const COLOR_GALLERY := Color("2b2327")

var _snapshot: Dictionary = {}
var _standing_label: Label
var _status_label: Label
var _attribution_label: Label
var _evidence_label: Label
var _standing_glance: Label
var _points_glance: Label
var _eggs_glance: Label
var _shell_glance: Label
var _campaign_glance: Label
var _credit_glance: Label
var _receipt_label: Label
var _campaigns_toggle
var _offer_controls: Dictionary = {}
var _had_actionable_campaign := false
var _confirmation: ConfirmationDialog
var _pending_campaign_id: StringName = &""
var _confirmation_origin: Control


func _ready() -> void:
	name = "FarmerRelationsGalleryUI"
	theme = ManagementTheme.create_theme()
	mouse_filter = Control.MOUSE_FILTER_PASS
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	_build_interface()
	_refresh()


func apply_snapshot(snapshot: Dictionary) -> void:
	# Office publishes large live snapshots. Keep only the compact Gallery file
	# and avoid rebuilding controls so scroll position and keyboard focus survive.
	var gallery := _extract_gallery_snapshot(snapshot)
	if gallery == _snapshot:
		return
	_snapshot = gallery.duplicate(true)
	if not _pending_campaign_is_valid():
		_cancel_confirmation(false)
	_refresh()


func _build_interface() -> void:
	var section := PanelContainer.new()
	section.name = "FarmerRelationsGallerySection"
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
	column.name = "FarmerRelationsGalleryColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 5)
	margin.add_child(column)

	var header := VBoxContainer.new()
	header.name = "FarmerRelationsGalleryHeader"
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 2)
	column.add_child(header)
	var title := _make_label("FARMER RELATIONS", 12, COLOR_BRASS)
	title.name = "FarmerRelationsGalleryTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.tooltip_text = "Farmer Relations Gallery / permanent public-credit campaigns."
	title.set_meta("accessible_text", title.tooltip_text)
	header.add_child(title)
	_standing_label = _make_label("PUBLIC STANDING / UNLISTED / 0 PTS", 10, COLOR_TEAL)
	_standing_label.name = "FarmerRelationsGalleryStanding"
	_standing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_standing_label.visible = false
	header.add_child(_standing_label)

	_status_label = _make_label("CAMPAIGN FILE PENDING", 10, COLOR_MUTED)
	_status_label.name = "FarmerRelationsGalleryStatus"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.visible = false
	column.add_child(_status_label)

	_attribution_label = _make_label("CLOSING ATTRIBUTION / AWAITING CREDIT MEMO", 10, COLOR_PAPER)
	_attribution_label.name = "FarmerRelationsGalleryAttribution"
	_attribution_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_attribution_label.visible = false
	column.add_child(_attribution_label)

	_evidence_label = _make_label("CLOSED-SHIFT EVIDENCE PENDING", 10, COLOR_INK)
	_evidence_label.name = "FarmerRelationsGalleryEvidence"
	_evidence_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_evidence_label.visible = false
	column.add_child(_evidence_label)

	var glance_grid := GridContainer.new()
	glance_grid.name = "FarmerRelationsGalleryGlanceGrid"
	glance_grid.columns = 2
	glance_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	glance_grid.add_theme_constant_override("h_separation", 5)
	glance_grid.add_theme_constant_override("v_separation", 5)
	column.add_child(glance_grid)
	_standing_glance = _metric_chip(glance_grid, "STAND\nUNLISTED")
	_standing_glance.name = "FarmerRelationsStandingGlance"
	_points_glance = _metric_chip(glance_grid, "POINTS\n0")
	_points_glance.name = "FarmerRelationsPointsGlance"
	_eggs_glance = _metric_chip(glance_grid, "EGGS\n-- / --")
	_eggs_glance.name = "FarmerRelationsEggsGlance"
	_shell_glance = _metric_chip(glance_grid, "SHELL\n-- / -- / --")
	_shell_glance.name = "FarmerRelationsShellGlance"

	_campaign_glance = _make_label("1 CAMPAIGN LEFT  /  LOCKED", 9, COLOR_MUTED)
	_campaign_glance.name = "FarmerRelationsCampaignGlance"
	_campaign_glance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_campaign_glance)
	_credit_glance = _make_label("CREDIT  /  AWAITING MEMO", 9, COLOR_PAPER)
	_credit_glance.name = "FarmerRelationsCreditGlance"
	_credit_glance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_credit_glance)

	_campaigns_toggle = FlockwatchDisclosureToggleScript.new()
	_campaigns_toggle.name = "FarmerRelationsCampaignsToggle"
	_campaigns_toggle.disclosure_changed.connect(
		func(_expanded: bool) -> void: presentation_context_changed.emit()
	)
	column.add_child(_campaigns_toggle)

	var divider := HSeparator.new()
	divider.name = "FarmerRelationsCampaignsDivider"
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(divider)

	var offer_heading := _make_label("CHOOSE ONE CAMPAIGN", 10, COLOR_BRASS)
	offer_heading.name = "FarmerRelationsGalleryOfferHeading"
	offer_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	offer_heading.tooltip_text = "One permanent public-credit campaign may be filed per closed shift."
	offer_heading.set_meta("accessible_text", offer_heading.tooltip_text)
	column.add_child(offer_heading)

	var offer_list := VBoxContainer.new()
	offer_list.name = "FarmerRelationsGalleryOfferList"
	offer_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offer_list.add_theme_constant_override("separation", 6)
	column.add_child(offer_list)
	for campaign_id: StringName in CAMPAIGN_IDS:
		_build_offer_card(offer_list, campaign_id)
	var campaign_targets: Array[Control] = [divider, offer_heading, offer_list]
	_campaigns_toggle.configure("CREDIT", "3 FILES", campaign_targets, false)

	_receipt_label = _make_label("LAST HUNG / NONE FILED", 10, COLOR_MUTED)
	_receipt_label.name = "FarmerRelationsGalleryLastReceipt"
	_receipt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_receipt_label)
	_build_confirmation()


func _build_confirmation() -> void:
	_confirmation = ConfirmationDialog.new()
	_confirmation.name = "FarmerRelationsCampaignConfirmation"
	_confirmation.title = "HANG A PERMANENT PUBLIC CAMPAIGN?"
	_confirmation.ok_button_text = "YES"
	_confirmation.cancel_button_text = "NO"
	ManagementTheme.style_held_confirmation(_confirmation)
	_confirmation.min_size = Vector2i(340, 350)
	var copy := _confirmation.get_label()
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	copy.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	copy.custom_minimum_size = Vector2(300.0, 210.0)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for action_button: Button in [
		_confirmation.get_ok_button(),
		_confirmation.get_cancel_button(),
	]:
		action_button.custom_minimum_size = Vector2(148.0, 44.0)
		action_button.add_theme_font_size_override("font_size", 12)
		action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_button.clip_text = true
		action_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_confirmation.get_ok_button().tooltip_text = "Hang this permanent public-credit campaign."
	_confirmation.get_ok_button().set_meta(
		"accessible_text",
		_confirmation.get_ok_button().tooltip_text,
	)
	_confirmation.get_cancel_button().tooltip_text = "Keep the public-credit campaign file open."
	_confirmation.get_cancel_button().set_meta(
		"accessible_text",
		_confirmation.get_cancel_button().tooltip_text,
	)
	_confirmation.confirmed.connect(_confirm_campaign)
	_confirmation.canceled.connect(_cancel_confirmation)
	add_child(_confirmation)


func _build_offer_card(parent: VBoxContainer, campaign_id: StringName) -> void:
	var suffix := String(campaign_id)
	var card := PanelContainer.new()
	card.name = "FarmerRelationsCampaign_%s" % suffix
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

	var title := _make_label(String(CAMPAIGN_LABELS[campaign_id]), 11, COLOR_PAPER)
	title.name = "FarmerRelationsCampaignTitle_%s" % suffix
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)

	var tagline := _make_label("Public-credit copy is being prepared.", 10, COLOR_MUTED)
	tagline.name = "FarmerRelationsCampaignTagline_%s" % suffix
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.visible = false
	column.add_child(tagline)

	var evidence := _make_label("EVIDENCE / CLOSED SHIFT REQUIRED", 10, COLOR_INK)
	evidence.name = "FarmerRelationsCampaignEvidence_%s" % suffix
	evidence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	evidence.visible = false
	column.add_child(evidence)

	var terms := _make_label("FUND EFFECT PENDING", 10, COLOR_TEAL)
	terms.name = "FarmerRelationsCampaignTerms_%s" % suffix
	terms.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	terms.visible = false
	column.add_child(terms)

	var metrics := GridContainer.new()
	metrics.name = "FarmerRelationsCampaignMetrics_%s" % suffix
	metrics.columns = 3
	metrics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metrics.add_theme_constant_override("h_separation", 4)
	column.add_child(metrics)
	var cost_glance := _metric_chip(metrics, "COST\n--")
	cost_glance.name = "FarmerRelationsCampaignCost_%s" % suffix
	var net_glance := _metric_chip(metrics, "NET\n--")
	net_glance.name = "FarmerRelationsCampaignNet_%s" % suffix
	var standing_glance := _metric_chip(metrics, "STAND\n--")
	standing_glance.name = "FarmerRelationsCampaignStanding_%s" % suffix

	var preview := _make_label("Consequences are awaiting the permanent campaign file.", 10, COLOR_MUTED)
	preview.name = "FarmerRelationsCampaignPreview_%s" % suffix
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview.visible = false
	column.add_child(preview)

	var reason := _make_label("HELD / Campaign terms are unavailable.", 10, COLOR_RUST)
	reason.name = "FarmerRelationsCampaignReason_%s" % suffix
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reason.visible = false
	column.add_child(reason)

	var button := Button.new()
	button.name = "FarmerRelationsCampaignButton_%s" % suffix
	button.text = String(CAMPAIGN_ACTIONS[campaign_id])
	button.theme_type_variation = &"PrimaryButton"
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0.0, 42.0)
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.disabled = true
	button.pressed.connect(_on_campaign_pressed.bind(campaign_id, button))
	column.add_child(button)

	_offer_controls[campaign_id] = {
		"card": card,
		"title": title,
		"tagline": tagline,
		"evidence": evidence,
		"terms": terms,
		"cost_glance": cost_glance,
		"net_glance": net_glance,
		"standing_glance": standing_glance,
		"preview": preview,
		"reason": reason,
		"button": button,
	}


func _refresh() -> void:
	if _standing_label == null:
		return
	var gallery := _gallery_snapshot()
	var receipt := _dictionary_value(gallery.get("last_receipt", {}))
	var level := maxi(0, int(gallery.get("level", 0)))
	visible = not gallery.is_empty() and (level > 0 or not receipt.is_empty())
	if not visible:
		return

	_refresh_summary(gallery)
	var offers_by_id := _offers_by_id(gallery)
	for campaign_id: StringName in CAMPAIGN_IDS:
		_refresh_offer(campaign_id, offers_by_id.get(campaign_id, {}) as Dictionary, gallery)
	_refresh_campaigns_disclosure()
	_refresh_receipt(receipt)


func set_campaigns_expanded(expanded: bool) -> void:
	if _campaigns_toggle != null:
		_campaigns_toggle.set_expanded(expanded)


func campaigns_expanded() -> bool:
	return _campaigns_toggle != null and _campaigns_toggle.is_expanded()


func _refresh_campaigns_disclosure() -> void:
	if _campaigns_toggle == null:
		return
	var ready_count := 0
	for controls_value: Variant in _offer_controls.values():
		if not controls_value is Dictionary:
			continue
		var button := (controls_value as Dictionary).get("button") as Button
		if button != null and not button.disabled:
			ready_count += 1
	_campaigns_toggle.set_summary(
		str(ready_count)
		if ready_count > 0 else
		"HELD",
		(
			"%d of %d campaign files are ready. Each file retains its full identity, "
			+ "evidence, exact cost, payout, Feed Fund effect, standing effect, "
			+ "authorization reason, and permanent-record consequence."
		) % [ready_count, CAMPAIGN_IDS.size()],
	)
	var actionable := ready_count > 0
	if actionable and not _had_actionable_campaign:
		_campaigns_toggle.set_expanded(true, false)
	_had_actionable_campaign = actionable


func _refresh_summary(gallery: Dictionary) -> void:
	var standing_value := _dictionary_value(gallery.get("standing", {}))
	var points := maxi(0, int(gallery.get(
		"standing_points",
		gallery.get("public_standing", standing_value.get("points", 0)),
	)))
	var standing := String(gallery.get(
		"standing_label",
		gallery.get(
			"public_standing_label",
			standing_value.get("label", standing_value.get("rank_label", "UNLISTED")),
		),
	)).strip_edges().to_upper()
	if standing.is_empty():
		standing = "UNLISTED"
	_standing_label.text = "PUBLIC STANDING / %s / %d PTS" % [standing, points]
	_standing_label.tooltip_text = _standing_label.text
	_standing_label.set_meta("accessible_text", _standing_label.text)

	var status := StringName(String(gallery.get("campaign_status", gallery.get("status", "locked"))))
	var used_fallback := 1 if status in [&"filed", &"skipped"] else 0
	var used := maxi(0, int(gallery.get(
		"campaigns_used",
		gallery.get("campaigns_used_today", used_fallback),
	)))
	var limit := maxi(1, int(gallery.get("campaign_limit", 1)))
	_status_label.text = "CAMPAIGN %d / %d / %s" % [used, limit, _status_copy(status)]
	_status_label.tooltip_text = _status_label.text
	_status_label.set_meta("accessible_text", _status_label.text)
	_status_label.add_theme_color_override(
		"font_color",
		COLOR_TEAL if status in [&"offer_open", &"open", &"ready", &"filed"] else COLOR_MUTED,
	)

	var shift := _dictionary_value(gallery.get(
		"shift_evidence",
		gallery.get("frozen_evidence", {}),
	))
	var attribution := _dictionary_value(gallery.get("attribution", {}))
	var style := String(attribution.get(
		"style_label",
		String(attribution.get(
			"style_id",
			gallery.get("attribution_style", "AWAITING CREDIT MEMO"),
		)).replace("_", " "),
	)).strip_edges().to_upper()
	var attributed_name := String(attribution.get(
		"worker_name",
		shift.get("top_worker_name", ""),
	)).strip_edges().to_upper()
	_attribution_label.text = "CLOSING ATTRIBUTION / %s%s" % [
		style if not style.is_empty() else "AWAITING CREDIT MEMO",
		" / %s" % attributed_name if not attributed_name.is_empty() else "",
	]
	_attribution_label.tooltip_text = _attribution_label.text
	_attribution_label.set_meta("accessible_text", _attribution_label.text)

	var completed_day := maxi(0, int(gallery.get(
		"completed_day",
		gallery.get("review_day", shift.get("day", 0)),
	)))
	var eggs := maxi(0, int(shift.get("eggs", 0)))
	var quota := maxi(0, int(shift.get("quota", 0)))
	var cracked := maxi(0, int(shift.get("cracked", 0)))
	var golden := maxi(0, int(shift.get("golden", 0)))
	_evidence_label.text = "DAY %d / %d / %d EGGS / %d CRACKED / %d GOLDEN" % [
		completed_day, eggs, quota, cracked, golden,
	]
	_evidence_label.tooltip_text = _evidence_label.text
	_evidence_label.set_meta("accessible_text", _evidence_label.text)

	var sound := maxi(0, int(shift.get("sound", maxi(0, eggs - cracked))))
	_standing_glance.text = "STAND\n%s" % standing
	_points_glance.text = "POINTS\n%d" % points
	_eggs_glance.text = "EGGS\n%d / %d" % [eggs, quota]
	_shell_glance.text = "SHELL\n%d / %d / %d" % [sound, cracked, golden]
	_standing_glance.tooltip_text = _standing_label.text
	_points_glance.tooltip_text = _standing_label.text
	_eggs_glance.tooltip_text = _evidence_label.text
	_shell_glance.tooltip_text = (
		"%s. Shell order is sound / cracked / golden."
		% _evidence_label.text
	)
	for glance: Label in [
		_standing_glance,
		_points_glance,
		_eggs_glance,
		_shell_glance,
	]:
		glance.set_meta("accessible_text", glance.tooltip_text)

	var remaining := maxi(0, limit - used)
	_campaign_glance.text = "%d CAMPAIGN%s LEFT  /  %s" % [
		remaining,
		"" if remaining == 1 else "S",
		_status_copy(status),
	]
	_campaign_glance.tooltip_text = _status_label.text
	_campaign_glance.set_meta("accessible_text", _status_label.text)
	_campaign_glance.add_theme_color_override(
		"font_color",
		COLOR_TEAL if status in [&"offer_open", &"open", &"ready", &"filed"] else COLOR_MUTED,
	)
	var credit_style := _glance_words(style, 2)
	_credit_glance.text = "CREDIT  /  %s%s" % [
		attributed_name if not attributed_name.is_empty() else "AWAITING MEMO",
		"  /  %s" % credit_style if not credit_style.is_empty() else "",
	]
	_credit_glance.tooltip_text = _attribution_label.text
	_credit_glance.set_meta("accessible_text", _attribution_label.text)


func _refresh_offer(
	campaign_id: StringName,
	offer: Dictionary,
	gallery: Dictionary,
) -> void:
	var controls := _offer_controls.get(campaign_id, {}) as Dictionary
	if controls.is_empty():
		return
	var title := controls.get("title") as Label
	var tagline := controls.get("tagline") as Label
	var evidence := controls.get("evidence") as Label
	var terms := controls.get("terms") as Label
	var cost_glance := controls.get("cost_glance") as Label
	var net_glance := controls.get("net_glance") as Label
	var standing_glance := controls.get("standing_glance") as Label
	var preview := controls.get("preview") as Label
	var reason_label := controls.get("reason") as Label
	var button := controls.get("button") as Button
	var card := controls.get("card") as PanelContainer

	var has_offer := not offer.is_empty()
	var offer_label := String(offer.get("label", CAMPAIGN_LABELS[campaign_id])).strip_edges()
	if campaign_id == &"farmer_method" and offer_label.to_upper() == "FARMER METHOD":
		offer_label = "FARMER'S METHOD"
	var full_tagline := String(offer.get(
		"tagline",
		offer.get("description", _fallback_tagline(campaign_id, offer, gallery)),
	)).strip_edges()
	var full_evidence := String(offer.get(
		"evidence",
		offer.get("evidence_label", _fallback_offer_evidence(campaign_id, offer, gallery)),
	)).strip_edges()
	title.text = String(CAMPAIGN_GLANCE_LABELS.get(campaign_id, offer_label)).to_upper()
	tagline.text = full_tagline
	evidence.text = "EVIDENCE / %s" % full_evidence

	var cost := maxi(0, int(offer.get("cost_cents", 0)))
	var payout := maxi(0, int(offer.get("payout_cents", 0)))
	var fund_delta := int(offer.get("fund_delta_cents", payout - cost))
	var standing_delta := int(offer.get(
		"standing_delta",
		offer.get("public_standing_delta", offer.get("standing_points_delta", 0)),
	))
	var full_terms := "COST $%.2f / PAYOUT $%.2f / FUND %s / STANDING %s" % [
		float(cost) / 100.0,
		float(payout) / 100.0,
		_signed_currency(fund_delta),
		_signed_integer(standing_delta),
	]
	terms.text = full_terms
	cost_glance.text = "COST\n%s" % _compact_currency(cost)
	net_glance.text = "NET\n%s" % _compact_signed_currency(fund_delta)
	standing_glance.text = "STAND\n%s" % _signed_integer(standing_delta)
	var full_preview := String(offer.get(
		"preview",
		offer.get("effect_preview", _fallback_offer_preview(offer)),
	)).strip_edges()
	preview.text = full_preview

	var held_reason := _authorization_reason(offer, gallery)
	var authorized := has_offer and held_reason.is_empty()
	var state_reason := held_reason
	if authorized:
		state_reason = String(offer.get("reason", "")).strip_edges()
		if state_reason.is_empty():
			state_reason = "Closing credit filed; 0 of 1 campaign used."
		reason_label.text = "READY"
		reason_label.visible = false
		reason_label.add_theme_color_override("font_color", COLOR_TEAL)
	else:
		reason_label.text = "HELD"
		reason_label.visible = true
		reason_label.add_theme_color_override("font_color", COLOR_RUST)
	button.text = String(CAMPAIGN_ACTIONS[campaign_id])
	button.disabled = not authorized
	var exact_copy := (
		"%s. %s Evidence: %s. %s. %s %s"
		% [
			offer_label,
			full_tagline,
			full_evidence,
			full_terms,
			full_preview,
			"Ready to publish: %s" % state_reason if authorized else "Held: %s" % state_reason,
		]
	).strip_edges()
	title.tooltip_text = "%s. %s" % [offer_label, full_tagline]
	evidence.tooltip_text = evidence.text
	terms.tooltip_text = "%s. %s" % [full_terms, full_preview]
	for glance: Label in [cost_glance, net_glance, standing_glance]:
		glance.tooltip_text = terms.tooltip_text
		glance.set_meta("accessible_text", terms.tooltip_text)
	reason_label.tooltip_text = (
		"Ready to publish: %s" % state_reason if authorized else "Held: %s" % state_reason
	)
	button.tooltip_text = exact_copy
	for control: Control in [title, evidence, terms, reason_label, button]:
		control.set_meta("accessible_text", control.tooltip_text)
	button.set_meta("full_action_label", String(CAMPAIGN_LABELS[campaign_id]))
	button.set_meta("exact_cost_cents", cost)
	button.set_meta("exact_payout_cents", payout)
	button.set_meta("exact_fund_delta_cents", fund_delta)
	button.set_meta("exact_standing_delta", standing_delta)
	if card != null:
		card.tooltip_text = exact_copy
		card.set_meta("accessible_text", exact_copy)


func _fallback_tagline(
	campaign_id: StringName,
	offer: Dictionary,
	gallery: Dictionary,
) -> String:
	var shift := _dictionary_value(gallery.get(
		"shift_evidence",
		gallery.get("frozen_evidence", {}),
	))
	var worker_name := String(offer.get(
		"top_worker_name",
		shift.get("top_worker_name", "the top layer"),
	)).strip_edges()
	match campaign_id:
		&"layer_profile":
			return "Put %s and her real closed shift on the wall." % worker_name
		&"clutch_results_board":
			return "Publish the verified clutch without erasing shell quality."
		&"farmer_method":
			return "Turn the same evidence into a farmer-led management case study."
	return "Publish one frozen closed-shift record."


func _fallback_offer_evidence(
	campaign_id: StringName,
	offer: Dictionary,
	gallery: Dictionary,
) -> String:
	var shift := _dictionary_value(gallery.get(
		"shift_evidence",
		gallery.get("frozen_evidence", {}),
	))
	var worker_name := String(offer.get(
		"top_worker_name",
		shift.get("top_worker_name", "TOP LAYER"),
	)).strip_edges().to_upper()
	var eggs := maxi(0, int(shift.get("eggs", 0)))
	var quota := maxi(0, int(shift.get("quota", 0)))
	var sound := maxi(0, int(offer.get("sound_eggs", shift.get("sound", 0))))
	var cracked := maxi(0, int(shift.get("cracked", 0)))
	var golden := maxi(0, int(offer.get("golden_eggs", shift.get("golden", 0))))
	match campaign_id:
		&"layer_profile":
			return "%s / TOP-LAYER BYLINE / %d SOUND / %d GOLDEN" % [
				worker_name, sound, golden,
			]
		&"clutch_results_board":
			return "%d / %d EGGS / %d SOUND / %d CRACKED / %d GOLDEN" % [
				eggs, quota, sound, cracked, golden,
			]
		&"farmer_method":
			return "%d / %d EGGS / ATTRIBUTION %s" % [
				eggs,
				quota,
				String(gallery.get("attribution_style", "FARMER METHOD")).replace("_", " ").to_upper(),
			]
	return "Closed-shift evidence filed."


func _fallback_offer_preview(offer: Dictionary) -> String:
	var sound := maxi(0, int(offer.get("sound_eggs", 0)))
	var golden := maxi(0, int(offer.get("golden_eggs", 0)))
	var per_sound := maxi(0, int(offer.get("per_sound_egg_cents", 0)))
	var golden_bonus := maxi(0, int(offer.get("golden_bonus_cents", 0)))
	var attribution_delta := int(offer.get("attribution_delta", 0))
	return "PAYOUT BASIS / %d sound x $%.2f + %d golden x $%.2f / ATTRIBUTION %s" % [
		sound,
		float(per_sound) / 100.0,
		golden,
		float(golden_bonus) / 100.0,
		_signed_integer(attribution_delta),
	]


func _glance_words(copy: String, limit: int) -> String:
	var words := copy.strip_edges().to_upper().split(" ", false)
	var result: Array[String] = []
	for index in mini(maxi(0, limit), words.size()):
		result.append(words[index])
	return " ".join(result)


func _authorization_reason(offer: Dictionary, gallery: Dictionary) -> String:
	if offer.is_empty():
		return "This campaign is missing from the authoritative Gallery file."
	var authoritative_reason := String(offer.get(
		"reason",
		offer.get("unavailable_reason", ""),
	)).strip_edges()
	var status := StringName(String(gallery.get("campaign_status", gallery.get("status", "locked"))))
	if status not in [&"offer_open", &"open", &"ready"]:
		return authoritative_reason if not authoritative_reason.is_empty() else _status_reason(status)
	if not bool(gallery.get("review_open", true)):
		return authoritative_reason if not authoritative_reason.is_empty() else "Campaigns are filed only during closing review."
	var limit := maxi(1, int(gallery.get("campaign_limit", 1)))
	var used := maxi(0, int(gallery.get("campaigns_used", gallery.get("campaigns_used_today", 0))))
	if used >= limit:
		return authoritative_reason if not authoritative_reason.is_empty() else "One public campaign has already been filed for this shift."
	if not bool(offer.get("can_authorize", offer.get("available", offer.get("enabled", false)))):
		return authoritative_reason if not authoritative_reason.is_empty() else "The current Feed Fund reserve does not authorize this campaign."
	return ""


func _refresh_receipt(receipt: Dictionary) -> void:
	if receipt.is_empty():
		_receipt_label.text = "LAST HUNG / NONE FILED"
		_receipt_label.tooltip_text = "No public-credit campaign has been filed."
		_receipt_label.set_meta("accessible_text", _receipt_label.tooltip_text)
		return
	var label := String(receipt.get(
		"campaign_label",
		String(receipt.get("campaign_id", "CAMPAIGN")).replace("_", " "),
	)).strip_edges().to_upper()
	var day := maxi(0, int(receipt.get("day", 0)))
	var standing_delta := int(receipt.get(
		"standing_delta",
		receipt.get("public_standing_delta", receipt.get("standing_points_delta", 0)),
	))
	var cost := maxi(0, int(receipt.get("cost_cents", 0)))
	var payout := maxi(0, int(receipt.get("payout_cents", 0)))
	var fund_delta := int(receipt.get("fund_delta_cents", payout - cost))
	var outcome := String(receipt.get("outcome", "Campaign receipt filed.")).strip_edges()
	var exact_copy := (
		"LAST HUNG / DAY %d / %s\n%s\nSTANDING %s / COST $%.2f / PAYOUT $%.2f / FUND %s"
	) % [
		day, label, outcome, _signed_integer(standing_delta), float(cost) / 100.0,
		float(payout) / 100.0, _signed_currency(fund_delta),
	]
	var campaign_id := StringName(String(receipt.get("campaign_id", "")))
	var glance_label := String(CAMPAIGN_GLANCE_LABELS.get(campaign_id, label))
	_receipt_label.text = "LAST  /  D%d  /  %s  /  %s  /  STAND %s" % [
		day,
		glance_label,
		_signed_currency(fund_delta),
		_signed_integer(standing_delta),
	]
	_receipt_label.tooltip_text = exact_copy
	_receipt_label.set_meta("accessible_text", exact_copy)


func _on_campaign_pressed(
	campaign_id: StringName,
	origin: Control,
) -> void:
	if origin == null or not is_instance_valid(origin):
		return
	var gallery := _gallery_snapshot()
	var offer := _offers_by_id(gallery).get(campaign_id, {}) as Dictionary
	if (
		offer.is_empty()
		or not _authorization_reason(offer, gallery).is_empty()
		or origin is BaseButton and (origin as BaseButton).disabled
	):
		return
	_pending_campaign_id = campaign_id
	_confirmation_origin = origin
	var campaign_label := String(offer.get(
		"label",
		CAMPAIGN_LABELS.get(campaign_id, campaign_id),
	)).strip_edges()
	if campaign_id == &"farmer_method" and campaign_label.to_upper() == "FARMER METHOD":
		campaign_label = "FARMER'S METHOD"
	var attribution := _dictionary_value(gallery.get("attribution", {}))
	var worker_name := String(attribution.get(
		"worker_name",
		_dictionary_value(gallery.get("shift_evidence", {})).get(
			"top_worker_name",
			"UNNAMED FLOCK",
		),
	)).strip_edges()
	var attribution_style := String(attribution.get(
		"style_label",
		attribution.get("style_id", "UNFILED CREDIT"),
	)).replace("_", " ").strip_edges()
	var cost_cents := maxi(0, int(offer.get("cost_cents", 0)))
	var payout_cents := maxi(0, int(offer.get("payout_cents", 0)))
	var fund_delta_cents := int(offer.get(
		"fund_delta_cents",
		payout_cents - cost_cents,
	))
	var standing_delta := int(offer.get(
		"standing_delta",
		offer.get("public_standing_delta", 0),
	))
	var evidence := String(offer.get(
		"evidence",
		offer.get("evidence_label", _fallback_offer_evidence(
			campaign_id,
			offer,
			gallery,
		)),
	)).strip_edges()
	var completed_day := maxi(0, int(gallery.get(
		"completed_day",
		gallery.get("review_day", 0),
	)))
	var glance_label := String(CAMPAIGN_GLANCE_LABELS.get(campaign_id, campaign_label)).to_upper()
	_confirmation.title = "HANG %s?" % glance_label
	_confirmation.dialog_text = (
		"%s  /  %s / %s\n"
		+ "EVIDENCE  /  %s\n"
		+ "FUND  /  COST $%.2f / PAYOUT $%.2f / NET %s\n"
		+ "STANDING  /  %s\n"
		+ "PERMANENT  /  DAY %d GALLERY FILE\n\n"
		+ "Nothing changes until HANG. "
		+ "This cannot be undone during this review."
	) % [
		campaign_label.to_upper(),
		attribution_style.to_upper(),
		worker_name.to_upper(),
		evidence.to_upper(),
		float(cost_cents) / 100.0,
		float(payout_cents) / 100.0,
		_signed_currency(fund_delta_cents),
		_signed_integer(standing_delta),
		completed_day,
	]
	_confirmation.popup_centered_clamped(Vector2i(380, 450), 0.96)


func _confirm_campaign() -> void:
	if not _pending_campaign_is_valid():
		_cancel_confirmation(false)
		return
	var campaign_id := _pending_campaign_id
	_clear_pending_confirmation()
	if _confirmation != null:
		_confirmation.hide()
	campaign_requested.emit(campaign_id)


func _cancel_confirmation(restore_focus: bool = true) -> void:
	var origin := _confirmation_origin
	_clear_pending_confirmation()
	if _confirmation != null:
		_confirmation.hide()
	if (
		restore_focus
		and origin != null
		and is_instance_valid(origin)
		and origin.is_visible_in_tree()
		and not (origin is BaseButton and (origin as BaseButton).disabled)
	):
		origin.call_deferred("grab_focus")


func _clear_pending_confirmation() -> void:
	_pending_campaign_id = &""
	_confirmation_origin = null


func _pending_campaign_is_valid() -> bool:
	if _pending_campaign_id == &"":
		return false
	var gallery := _gallery_snapshot()
	var offer := _offers_by_id(gallery).get(
		_pending_campaign_id,
		{},
	) as Dictionary
	return (
		not offer.is_empty()
		and _authorization_reason(offer, gallery).is_empty()
	)


func _gallery_snapshot() -> Dictionary:
	return _snapshot


func _extract_gallery_snapshot(snapshot: Dictionary) -> Dictionary:
	var nested_value: Variant = snapshot.get("farmer_relations_gallery", {})
	if nested_value is Dictionary and not (nested_value as Dictionary).is_empty():
		return nested_value as Dictionary
	if snapshot.has("campaign_status") and snapshot.has("offers"):
		return snapshot
	return {}


func _offers_by_id(gallery: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var offers_value: Variant = gallery.get("offers", [])
	if offers_value is Array:
		for offer_value: Variant in offers_value as Array:
			if not offer_value is Dictionary:
				continue
			var offer := (offer_value as Dictionary).duplicate(true)
			var campaign_id := StringName(String(offer.get("id", offer.get("campaign_id", ""))))
			if campaign_id in CAMPAIGN_IDS and not result.has(campaign_id):
				result[campaign_id] = offer
	elif offers_value is Dictionary:
		for campaign_id: StringName in CAMPAIGN_IDS:
			var offer_value: Variant = (offers_value as Dictionary).get(
				campaign_id,
				(offers_value as Dictionary).get(String(campaign_id), {}),
			)
			if offer_value is Dictionary:
				result[campaign_id] = (offer_value as Dictionary).duplicate(true)
	return result


func _dictionary_value(value: Variant) -> Dictionary:
	return value as Dictionary if value is Dictionary else {}


func _status_copy(status: StringName) -> String:
	match status:
		&"offer_open", &"open", &"ready":
			return "OFFER OPEN"
		&"filed":
			return "FILED"
		&"skipped":
			return "SKIPPED"
		&"pre_credit", &"awaiting_credit":
			return "CREDIT MEMO REQUIRED"
		&"locked":
			return "LOCKED"
		_:
			return String(status).replace("_", " ").to_upper()


func _status_reason(status: StringName) -> String:
	match status:
		&"filed":
			return "One public campaign has already been filed for this shift."
		&"skipped":
			return "This shift's public campaign was skipped."
		&"pre_credit", &"awaiting_credit":
			return "File the closing credit memo first."
		&"locked":
			return "Commission the Farmer Relations Gallery before publishing."
		_:
			return "Campaigns are filed only during closing review."


func _signed_integer(value: int) -> String:
	return "+%d" % value if value > 0 else str(value)


func _signed_currency(value: int) -> String:
	return "%s$%.2f" % ["+" if value >= 0 else "-", float(absi(value)) / 100.0]


func _compact_currency(value: int) -> String:
	var cents := maxi(0, value)
	if cents % 100 == 0:
		return "$%d" % (cents / 100)
	return "$%.2f" % (float(cents) / 100.0)


func _compact_signed_currency(value: int) -> String:
	return "%s%s" % ["+" if value >= 0 else "-", _compact_currency(absi(value))]


func _make_label(copy: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _metric_chip(parent: GridContainer, copy: String) -> Label:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _metric_style())
	parent.add_child(panel)
	var label := _make_label(copy, 10, COLOR_PAPER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(0.0, 38.0)
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(label)
	return label


func _section_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_GALLERY
	style.border_color = Color("a77a67")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style


func _offer_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1a2730")
	style.border_color = Color("5a6570")
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	return style


func _metric_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("242833")
	style.border_color = Color("4b5360")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style
