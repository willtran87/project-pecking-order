class_name FarmerRelationsGalleryUI
extends VBoxContainer

## Compact public-credit campaign controls hosted inside Flockwatch.
##
## This surface is intent-only. Attribution, shift evidence, exact economics,
## authorization gates, standing, and receipts come from the authoritative
## farmer_relations_gallery projection.

signal campaign_requested(campaign_id: StringName)

const ManagementTheme := preload("res://features/office/management_ui_theme.gd")

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
const CAMPAIGN_ACTIONS := {
	&"layer_profile": "PUBLISH LAYER PROFILE",
	&"clutch_results_board": "POST CLUTCH RESULTS",
	&"farmer_method": "FRAME FARMER'S METHOD",
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
var _receipt_label: Label
var _offer_controls: Dictionary = {}


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

	var header := HFlowContainer.new()
	header.name = "FarmerRelationsGalleryHeader"
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("h_separation", 8)
	header.add_theme_constant_override("v_separation", 2)
	column.add_child(header)
	var title := _make_label("FARMER RELATIONS GALLERY", 12, COLOR_BRASS)
	title.name = "FarmerRelationsGalleryTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(title)
	_standing_label = _make_label("PUBLIC STANDING / UNLISTED / 0 PTS", 10, COLOR_TEAL)
	_standing_label.name = "FarmerRelationsGalleryStanding"
	_standing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(_standing_label)

	_status_label = _make_label("CAMPAIGN FILE PENDING", 10, COLOR_MUTED)
	_status_label.name = "FarmerRelationsGalleryStatus"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status_label)

	_attribution_label = _make_label("CLOSING ATTRIBUTION / AWAITING CREDIT MEMO", 10, COLOR_PAPER)
	_attribution_label.name = "FarmerRelationsGalleryAttribution"
	_attribution_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_attribution_label)

	_evidence_label = _make_label("CLOSED-SHIFT EVIDENCE PENDING", 10, COLOR_INK)
	_evidence_label.name = "FarmerRelationsGalleryEvidence"
	_evidence_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_evidence_label)

	var divider := HSeparator.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(divider)

	var offer_heading := _make_label("ONE PUBLIC CAMPAIGN PER CLOSED SHIFT", 10, COLOR_BRASS)
	offer_heading.name = "FarmerRelationsGalleryOfferHeading"
	offer_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(offer_heading)

	var offer_list := VBoxContainer.new()
	offer_list.name = "FarmerRelationsGalleryOfferList"
	offer_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offer_list.add_theme_constant_override("separation", 6)
	column.add_child(offer_list)
	for campaign_id: StringName in CAMPAIGN_IDS:
		_build_offer_card(offer_list, campaign_id)

	_receipt_label = _make_label("LAST HUNG / NONE FILED", 10, COLOR_MUTED)
	_receipt_label.name = "FarmerRelationsGalleryLastReceipt"
	_receipt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_receipt_label)


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
	column.add_child(tagline)

	var evidence := _make_label("EVIDENCE / CLOSED SHIFT REQUIRED", 10, COLOR_INK)
	evidence.name = "FarmerRelationsCampaignEvidence_%s" % suffix
	evidence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(evidence)

	var terms := _make_label("FUND EFFECT PENDING", 10, COLOR_TEAL)
	terms.name = "FarmerRelationsCampaignTerms_%s" % suffix
	terms.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(terms)

	var preview := _make_label("Consequences are awaiting the permanent campaign file.", 10, COLOR_MUTED)
	preview.name = "FarmerRelationsCampaignPreview_%s" % suffix
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(preview)

	var reason := _make_label("HELD / Campaign terms are unavailable.", 10, COLOR_RUST)
	reason.name = "FarmerRelationsCampaignReason_%s" % suffix
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(reason)

	var button := Button.new()
	button.name = "FarmerRelationsCampaignButton_%s" % suffix
	button.text = String(CAMPAIGN_ACTIONS[campaign_id])
	button.theme_type_variation = &"PrimaryButton"
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0.0, 38.0)
	button.disabled = true
	button.pressed.connect(_on_campaign_pressed.bind(campaign_id))
	column.add_child(button)

	_offer_controls[campaign_id] = {
		"title": title,
		"tagline": tagline,
		"evidence": evidence,
		"terms": terms,
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
	_refresh_receipt(receipt)


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

	var status := StringName(String(gallery.get("campaign_status", gallery.get("status", "locked"))))
	var used_fallback := 1 if status in [&"filed", &"skipped"] else 0
	var used := maxi(0, int(gallery.get(
		"campaigns_used",
		gallery.get("campaigns_used_today", used_fallback),
	)))
	var limit := maxi(1, int(gallery.get("campaign_limit", 1)))
	_status_label.text = "CAMPAIGN %d / %d / %s" % [used, limit, _status_copy(status)]
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
	var preview := controls.get("preview") as Label
	var reason_label := controls.get("reason") as Label
	var button := controls.get("button") as Button

	var has_offer := not offer.is_empty()
	var offer_label := String(offer.get("label", CAMPAIGN_LABELS[campaign_id])).strip_edges()
	if campaign_id == &"farmer_method" and offer_label.to_upper() == "FARMER METHOD":
		offer_label = "FARMER'S METHOD"
	title.text = offer_label.to_upper()
	tagline.text = String(offer.get(
		"tagline",
		offer.get("description", _fallback_tagline(campaign_id, offer, gallery)),
	)).strip_edges()
	evidence.text = "EVIDENCE / %s" % String(offer.get(
		"evidence",
		offer.get("evidence_label", _fallback_offer_evidence(campaign_id, offer, gallery)),
	)).strip_edges()

	var cost := maxi(0, int(offer.get("cost_cents", 0)))
	var payout := maxi(0, int(offer.get("payout_cents", 0)))
	var fund_delta := int(offer.get("fund_delta_cents", payout - cost))
	var standing_delta := int(offer.get(
		"standing_delta",
		offer.get("public_standing_delta", offer.get("standing_points_delta", 0)),
	))
	terms.text = "COST $%.2f / PAYOUT $%.2f / FUND %s / STANDING %s" % [
		float(cost) / 100.0,
		float(payout) / 100.0,
		_signed_currency(fund_delta),
		_signed_integer(standing_delta),
	]
	preview.text = String(offer.get(
		"preview",
		offer.get("effect_preview", _fallback_offer_preview(offer)),
	)).strip_edges()

	var held_reason := _authorization_reason(offer, gallery)
	var authorized := has_offer and held_reason.is_empty()
	if authorized:
		var ready_reason := String(offer.get("reason", "")).strip_edges()
		if ready_reason.is_empty():
			ready_reason = "Closing credit filed; 0 of 1 campaign used."
		reason_label.text = "READY / %s" % ready_reason
		reason_label.add_theme_color_override("font_color", COLOR_TEAL)
	else:
		reason_label.text = "HELD / %s" % held_reason
		reason_label.add_theme_color_override("font_color", COLOR_RUST)
	button.text = String(CAMPAIGN_ACTIONS[campaign_id])
	button.disabled = not authorized
	button.tooltip_text = "%s / %s / %s" % [
		offer_label,
		terms.text,
		"Ready to publish." if authorized else held_reason,
	]


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
	_receipt_label.text = (
		"LAST HUNG / DAY %d / %s\n%s\nSTANDING %s / COST $%.2f / PAYOUT $%.2f / FUND %s"
	) % [
		day, label, outcome, _signed_integer(standing_delta), float(cost) / 100.0,
		float(payout) / 100.0, _signed_currency(fund_delta),
	]
	_receipt_label.tooltip_text = _receipt_label.text


func _on_campaign_pressed(campaign_id: StringName) -> void:
	var gallery := _gallery_snapshot()
	var offer := _offers_by_id(gallery).get(campaign_id, {}) as Dictionary
	if _authorization_reason(offer, gallery).is_empty():
		campaign_requested.emit(campaign_id)


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


func _make_label(copy: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
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
