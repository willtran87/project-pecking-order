class_name HarvestCreditState
extends RefCounted

## Strict, deterministic review ledger for the Harvest Credit Gallery. The
## DepartmentSimulation remains the authority for money and worker effects;
## this value object freezes completed-shift evidence, quotes publicity
## contracts, and owns their standing/attribution history.

const SAVE_VERSION := 1
const MAX_LEDGER_VALUE := 2_000_000_000
const HISTORY_LIMIT := 32

const STATUS_LOCKED: StringName = &"locked"
const STATUS_PRE_CREDIT: StringName = &"pre_credit"
const STATUS_OFFER_OPEN: StringName = &"offer_open"
const STATUS_FILED: StringName = &"filed"
const STATUS_SKIPPED: StringName = &"skipped"

const CAMPAIGN_ORDER: Array[StringName] = [
	&"layer_profile",
	&"clutch_results_board",
	&"farmer_method",
]
const CAMPAIGN_DEFINITIONS := {
	&"layer_profile": {
		"label": "LAYER PROFILE",
		"style_id": &"named_layer",
		"base_reach": 1,
		"per_sound_egg_cents": [20, 25, 30],
		"golden_bonus_cents": [100, 150, 200],
		"attribution_delta": -10,
	},
	&"clutch_results_board": {
		"label": "CLUTCH RESULTS BOARD",
		"style_id": &"shared_clutch",
		"base_reach": 2,
		"per_sound_egg_cents": [15, 20, 25],
		"golden_bonus_cents": [75, 100, 125],
		"attribution_delta": -15,
	},
	&"farmer_method": {
		"label": "FARMER METHOD",
		"style_id": &"farmer_method",
		"base_reach": 3,
		"per_sound_egg_cents": [35, 45, 55],
		"golden_bonus_cents": [200, 300, 400],
		"attribution_delta": 18,
	},
}

const SAVE_KEYS: Array[String] = [
	"version",
	"public_standing",
	"attribution_balance",
	"total_campaigns",
	"payout_total_cents",
	"last_campaign_id",
	"last_skipped_day",
	"last_receipt",
	"history",
	"frozen_evidence",
	"review_level",
	"review_status",
]
const EVIDENCE_KEYS: Array[String] = [
	"day",
	"eggs",
	"quota",
	"sound",
	"cracked",
	"golden",
	"met_quota",
	"top_worker_id",
	"top_worker_name",
	"hen_highlight",
]
const RECEIPT_KEYS: Array[String] = [
	"status",
	"day",
	"facility_level",
	"campaign_id",
	"campaign_label",
	"style_id",
	"top_worker_id",
	"top_worker_name",
	"sound_eggs",
	"golden_eggs",
	"per_sound_egg_cents",
	"golden_bonus_cents",
	"base_payout_cents",
	"standing_bonus_basis_points",
	"payout_cents",
	"public_standing_before",
	"public_standing_delta",
	"public_standing_after",
	"standing_label_before",
	"standing_label_after",
	"attribution_before",
	"attribution_delta",
	"attribution_after",
	"attribution_style",
	"evidence",
	"outcome",
]

var public_standing: int = 0
var attribution_balance: int = 0
var total_campaigns: int = 0
var payout_total_cents: int = 0
var last_campaign_id: StringName = &""
var last_skipped_day: int = 0
var last_receipt: Dictionary = {}
var history: Array[Dictionary] = []
var frozen_evidence: Dictionary = {}
var review_level: int = 0
var review_status: StringName = STATUS_LOCKED


static func neutral_save_data() -> Dictionary:
	return HarvestCreditState.new().to_save_data()


static func standing_label_for(value: int) -> String:
	if value >= 45:
		return "HOUSEHOLD FARM BRAND"
	if value >= 25:
		return "REGIONAL SHOWCASE"
	if value >= 12:
		return "COUNTY FAIR"
	if value >= 5:
		return "ROADSIDE NOTICE"
	return "UNLISTED"


static func attribution_style_for(value: int) -> StringName:
	if value <= -20:
		return &"flock_authored"
	if value >= 20:
		return &"farmer_authored"
	return &"contested_credit"


func stage_review(evidence: Dictionary, facility_level: int, credit_pending: bool) -> bool:
	var validated := _validated_evidence(evidence)
	if validated.is_empty() or facility_level < 0 or facility_level > 3:
		return false
	frozen_evidence = validated
	review_level = facility_level
	if facility_level == 0:
		review_status = STATUS_LOCKED
	else:
		review_status = STATUS_PRE_CREDIT if credit_pending else STATUS_OFFER_OPEN
	return true


func release_credit_gate(completed_day: int) -> bool:
	if (
		review_status != STATUS_PRE_CREDIT
		or int(frozen_evidence.get("day", 0)) != completed_day
		or review_level <= 0
	):
		return false
	review_status = STATUS_OFFER_OPEN
	return true


func review_day() -> int:
	return int(frozen_evidence.get("day", 0))


func campaign_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for campaign_id in CAMPAIGN_ORDER:
		result.append(campaign_quote(campaign_id))
	return result


func campaign_quote(campaign_id: StringName) -> Dictionary:
	if not CAMPAIGN_DEFINITIONS.has(campaign_id):
		return {}
	var definition := CAMPAIGN_DEFINITIONS[campaign_id] as Dictionary
	var enabled := review_level > 0 and not frozen_evidence.is_empty()
	var tier_index := clampi(review_level - 1, 0, 2)
	var sound := maxi(0, int(frozen_evidence.get("sound", 0)))
	var golden := maxi(0, int(frozen_evidence.get("golden", 0)))
	var per_sound := int((definition["per_sound_egg_cents"] as Array)[tier_index]) if enabled else 0
	var golden_bonus := int((definition["golden_bonus_cents"] as Array)[tier_index]) if enabled else 0
	var base_payout := sound * per_sound + golden * golden_bonus
	var standing_bonus_basis_points := mini(2_500, maxi(0, public_standing) * 50)
	var payout := _basis_points_half_up(
		base_payout,
		10_000 + standing_bonus_basis_points,
	)
	var reach_delta := (
		int(definition["base_reach"])
		+ maxi(0, review_level - 1)
		+ (1 if bool(frozen_evidence.get("met_quota", false)) else 0)
		+ mini(2, golden)
	) if enabled else 0
	return {
		"campaign_id": campaign_id,
		"label": String(definition["label"]),
		"style_id": StringName(definition["style_id"]),
		"facility_level": review_level,
		"available": review_status == STATUS_OFFER_OPEN,
		"reason": _campaign_hold_reason(),
		"sound_eggs": sound,
		"golden_eggs": golden,
		"per_sound_egg_cents": per_sound,
		"golden_bonus_cents": golden_bonus,
		"base_payout_cents": base_payout,
		"standing_bonus_basis_points": standing_bonus_basis_points,
		"payout_cents": payout,
		"public_standing_before": public_standing,
		"public_standing_delta": reach_delta,
		"public_standing_after": mini(MAX_LEDGER_VALUE, public_standing + reach_delta),
		"attribution_delta": int(definition["attribution_delta"]),
		"top_worker_id": int(frozen_evidence.get("top_worker_id", -1)),
		"top_worker_name": String(frozen_evidence.get("top_worker_name", "")),
	}


func commit_campaign(campaign_id: StringName, outcome: String = "") -> Dictionary:
	if review_status != STATUS_OFFER_OPEN or not CAMPAIGN_DEFINITIONS.has(campaign_id):
		return {}
	var quote := campaign_quote(campaign_id)
	if quote.is_empty():
		return {}
	var standing_before := public_standing
	var attribution_before := attribution_balance
	public_standing = mini(
		MAX_LEDGER_VALUE,
		public_standing + int(quote["public_standing_delta"]),
	)
	attribution_balance = clampi(
		attribution_balance + int(quote["attribution_delta"]),
		-MAX_LEDGER_VALUE,
		MAX_LEDGER_VALUE,
	)
	var payout := int(quote["payout_cents"])
	total_campaigns = mini(MAX_LEDGER_VALUE, total_campaigns + 1)
	payout_total_cents = mini(MAX_LEDGER_VALUE, payout_total_cents + payout)
	last_campaign_id = campaign_id
	review_status = STATUS_FILED
	var receipt := {
		"status": String(STATUS_FILED),
		"day": review_day(),
		"facility_level": review_level,
		"campaign_id": String(campaign_id),
		"campaign_label": String(quote["label"]),
		"style_id": String(quote["style_id"]),
		"top_worker_id": int(quote["top_worker_id"]),
		"top_worker_name": String(quote["top_worker_name"]),
		"sound_eggs": int(quote["sound_eggs"]),
		"golden_eggs": int(quote["golden_eggs"]),
		"per_sound_egg_cents": int(quote["per_sound_egg_cents"]),
		"golden_bonus_cents": int(quote["golden_bonus_cents"]),
		"base_payout_cents": int(quote["base_payout_cents"]),
		"standing_bonus_basis_points": int(quote["standing_bonus_basis_points"]),
		"payout_cents": payout,
		"public_standing_before": standing_before,
		"public_standing_delta": public_standing - standing_before,
		"public_standing_after": public_standing,
		"standing_label_before": standing_label_for(standing_before),
		"standing_label_after": standing_label_for(public_standing),
		"attribution_before": attribution_before,
		"attribution_delta": attribution_balance - attribution_before,
		"attribution_after": attribution_balance,
		"attribution_style": String(attribution_style_for(attribution_balance)),
		"evidence": frozen_evidence.duplicate(true),
		"outcome": outcome,
	}
	last_receipt = receipt
	_append_history(receipt)
	return receipt.duplicate(true)


func skip_campaign() -> Dictionary:
	if review_status != STATUS_OFFER_OPEN:
		return {}
	review_status = STATUS_SKIPPED
	last_skipped_day = review_day()
	var receipt := {
		"status": String(STATUS_SKIPPED),
		"day": review_day(),
		"facility_level": review_level,
		"campaign_id": "",
		"campaign_label": "NO PUBLIC RELEASE",
		"style_id": "unfiled",
		"top_worker_id": int(frozen_evidence.get("top_worker_id", -1)),
		"top_worker_name": String(frozen_evidence.get("top_worker_name", "")),
		"sound_eggs": int(frozen_evidence.get("sound", 0)),
		"golden_eggs": int(frozen_evidence.get("golden", 0)),
		"per_sound_egg_cents": 0,
		"golden_bonus_cents": 0,
		"base_payout_cents": 0,
		"standing_bonus_basis_points": mini(2_500, public_standing * 50),
		"payout_cents": 0,
		"public_standing_before": public_standing,
		"public_standing_delta": 0,
		"public_standing_after": public_standing,
		"standing_label_before": standing_label_for(public_standing),
		"standing_label_after": standing_label_for(public_standing),
		"attribution_before": attribution_balance,
		"attribution_delta": 0,
		"attribution_after": attribution_balance,
		"attribution_style": String(attribution_style_for(attribution_balance)),
		"evidence": frozen_evidence.duplicate(true),
		"outcome": "No Harvest Credit release was filed. The completed shift remains in the internal ledger.",
	}
	last_receipt = receipt
	_append_history(receipt)
	return receipt.duplicate(true)


func snapshot() -> Dictionary:
	return {
		"status": review_status,
		"review_open": review_status == STATUS_OFFER_OPEN,
		"review_day": review_day(),
		"review_level": review_level,
		"public_standing": public_standing,
		"public_standing_label": standing_label_for(public_standing),
		"attribution_balance": attribution_balance,
		"attribution_style": attribution_style_for(attribution_balance),
		"total_campaigns": total_campaigns,
		"payout_total_cents": payout_total_cents,
		"last_campaign_id": last_campaign_id,
		"last_skipped_day": last_skipped_day,
		"last_receipt": last_receipt.duplicate(true),
		"history": history.duplicate(true),
		"frozen_evidence": frozen_evidence.duplicate(true),
		"offers": campaign_catalog(),
	}


func to_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"public_standing": public_standing,
		"attribution_balance": attribution_balance,
		"total_campaigns": total_campaigns,
		"payout_total_cents": payout_total_cents,
		"last_campaign_id": String(last_campaign_id),
		"last_skipped_day": last_skipped_day,
		"last_receipt": last_receipt.duplicate(true),
		"history": history.duplicate(true),
		"frozen_evidence": frozen_evidence.duplicate(true),
		"review_level": review_level,
		"review_status": String(review_status),
	}


func restore_save_data(source: Variant, saved_day: int, facility_level: int) -> bool:
	if not source is Dictionary or saved_day < 1 or facility_level < 0 or facility_level > 3:
		return false
	var data := source as Dictionary
	if not _has_exact_keys(data, SAVE_KEYS):
		return false
	for field in [
		"version", "public_standing", "attribution_balance", "total_campaigns",
		"payout_total_cents", "last_skipped_day", "review_level",
	]:
		if not _is_integral(data.get(field, null)):
			return false
	if int(data["version"]) != SAVE_VERSION:
		return false
	var restored_standing := int(data["public_standing"])
	var restored_attribution := int(data["attribution_balance"])
	var restored_total := int(data["total_campaigns"])
	var restored_payout := int(data["payout_total_cents"])
	var restored_skip_day := int(data["last_skipped_day"])
	var restored_level := int(data["review_level"])
	var restored_status := StringName(String(data["review_status"]))
	var restored_campaign := StringName(String(data["last_campaign_id"]))
	if (
		restored_standing < 0 or restored_standing > MAX_LEDGER_VALUE
		or absi(restored_attribution) > MAX_LEDGER_VALUE
		or restored_total < 0 or restored_total > MAX_LEDGER_VALUE
		or restored_payout < 0 or restored_payout > MAX_LEDGER_VALUE
		or restored_skip_day < 0 or restored_skip_day > saved_day
		or restored_level < 0 or restored_level > facility_level
		or restored_status not in [
			STATUS_LOCKED, STATUS_PRE_CREDIT, STATUS_OFFER_OPEN, STATUS_FILED, STATUS_SKIPPED,
		]
		or (restored_campaign != &"" and restored_campaign not in CAMPAIGN_ORDER)
		or (restored_total == 0 and restored_campaign != &"")
		or (restored_total > 0 and restored_campaign == &"")
	):
		return false
	if not data["frozen_evidence"] is Dictionary or not data["last_receipt"] is Dictionary:
		return false
	var restored_evidence := _validated_evidence(data["frozen_evidence"], true)
	if not (data["frozen_evidence"] as Dictionary).is_empty() and restored_evidence.is_empty():
		return false
	if not restored_evidence.is_empty() and int(restored_evidence["day"]) > saved_day:
		return false
	if (
		(restored_status == STATUS_LOCKED and restored_level != 0)
		or (restored_status != STATUS_LOCKED and (restored_level <= 0 or restored_evidence.is_empty()))
		or (restored_status in [STATUS_PRE_CREDIT, STATUS_OFFER_OPEN] and int(restored_evidence["day"]) != saved_day - 1)
	):
		return false
	if not data["history"] is Array or (data["history"] as Array).size() > HISTORY_LIMIT:
		return false
	var restored_history: Array[Dictionary] = []
	for raw_receipt in data["history"] as Array:
		var receipt := _validated_receipt(raw_receipt, saved_day)
		if receipt.is_empty():
			return false
		if not restored_history.is_empty() and int(receipt["day"]) < int(restored_history[-1]["day"]):
			return false
		restored_history.append(receipt)
	var restored_last := _validated_receipt(data["last_receipt"], saved_day, true)
	if not (data["last_receipt"] as Dictionary).is_empty() and restored_last.is_empty():
		return false
	if (
		(restored_history.is_empty() and not restored_last.is_empty())
		or (not restored_history.is_empty() and restored_last != restored_history[-1])
	):
		return false
	var recent_campaigns := 0
	var recent_payout := 0
	for receipt in restored_history:
		if StringName(receipt["status"]) == STATUS_FILED:
			recent_campaigns += 1
			recent_payout += int(receipt["payout_cents"])
	if restored_total < recent_campaigns or restored_payout < recent_payout:
		return false
	if restored_skip_day > 0 and (
		restored_last.is_empty()
		or not _history_has_skip_day(restored_history, restored_skip_day)
	):
		# Once history rolls over, an old skip may legitimately no longer be present.
		if restored_history.size() < HISTORY_LIMIT:
			return false
	public_standing = restored_standing
	attribution_balance = restored_attribution
	total_campaigns = restored_total
	payout_total_cents = restored_payout
	last_campaign_id = restored_campaign
	last_skipped_day = restored_skip_day
	last_receipt = restored_last
	history = restored_history
	frozen_evidence = restored_evidence
	review_level = restored_level
	review_status = restored_status
	return true


func _campaign_hold_reason() -> String:
	match review_status:
		STATUS_LOCKED:
			return "The completed shift closed before the Harvest Credit Gallery was commissioned."
		STATUS_PRE_CREDIT:
			return "File the closing credit memo before publishing its public version."
		STATUS_OFFER_OPEN:
			return ""
		STATUS_FILED:
			return "This shift already has a filed Harvest Credit campaign."
		STATUS_SKIPPED:
			return "This shift's public release was explicitly skipped."
	return "The publicity ledger is unavailable."


func _append_history(receipt: Dictionary) -> void:
	history.append(receipt.duplicate(true))
	while history.size() > HISTORY_LIMIT:
		history.pop_front()


static func _validated_evidence(source: Variant, allow_empty: bool = false) -> Dictionary:
	if not source is Dictionary:
		return {}
	var data := source as Dictionary
	if data.is_empty():
		return {} if allow_empty else {}
	if not _has_exact_keys(data, EVIDENCE_KEYS):
		return {}
	for field in ["day", "eggs", "quota", "sound", "cracked", "golden", "top_worker_id"]:
		if not _is_integral(data.get(field, null)):
			return {}
	if typeof(data.get("met_quota", null)) != TYPE_BOOL or typeof(data.get("top_worker_name", null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return {}
	if not data.get("hen_highlight", null) is Dictionary:
		return {}
	var day := int(data["day"])
	var eggs := int(data["eggs"])
	var quota := int(data["quota"])
	var sound := int(data["sound"])
	var cracked := int(data["cracked"])
	var golden := int(data["golden"])
	var worker_id := int(data["top_worker_id"])
	if (
		day < 1 or day > 9999
		or eggs < 0 or eggs > 100_000
		or quota < 1 or quota > 100_000
		or cracked < 0 or cracked > eggs
		or golden < 0 or golden > eggs
		or sound != maxi(0, eggs - cracked)
		or bool(data["met_quota"]) != (eggs >= quota)
		or worker_id < -1 or worker_id > 9999
		or (worker_id >= 0 and String(data["top_worker_name"]).is_empty())
	):
		return {}
	return {
		"day": day,
		"eggs": eggs,
		"quota": quota,
		"sound": sound,
		"cracked": cracked,
		"golden": golden,
		"met_quota": bool(data["met_quota"]),
		"top_worker_id": worker_id,
		"top_worker_name": String(data["top_worker_name"]),
		# Completed-shift highlights come from a broader report surface. Normalize
		# their nested primitives here so a live review and the same review loaded
		# through JSON expose one identical, deterministic projection.
		"hen_highlight": _canonical_json_value(data["hen_highlight"]),
	}


static func _validated_receipt(source: Variant, saved_day: int, allow_empty: bool = false) -> Dictionary:
	if not source is Dictionary:
		return {}
	var data := source as Dictionary
	if data.is_empty():
		return {} if allow_empty else {}
	if not _has_exact_keys(data, RECEIPT_KEYS):
		return {}
	for field in [
		"day", "facility_level", "top_worker_id", "sound_eggs", "golden_eggs",
		"per_sound_egg_cents", "golden_bonus_cents", "base_payout_cents",
		"standing_bonus_basis_points", "payout_cents", "public_standing_before",
		"public_standing_delta", "public_standing_after", "attribution_before",
		"attribution_delta", "attribution_after",
	]:
		if not _is_integral(data.get(field, null)):
			return {}
	for field in [
		"status", "campaign_id", "campaign_label", "style_id", "top_worker_name",
		"standing_label_before", "standing_label_after", "attribution_style", "outcome",
	]:
		if typeof(data.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {}
	var evidence := _validated_evidence(data.get("evidence", null))
	if evidence.is_empty():
		return {}
	var status := StringName(String(data["status"]))
	var campaign_id := StringName(String(data["campaign_id"]))
	var day := int(data["day"])
	var level := int(data["facility_level"])
	if (
		status not in [STATUS_FILED, STATUS_SKIPPED]
		or day < 1 or day > saved_day
		or day != int(evidence["day"])
		or level < 1 or level > 3
		or int(data["top_worker_id"]) != int(evidence["top_worker_id"])
		or String(data["top_worker_name"]) != String(evidence["top_worker_name"])
		or int(data["sound_eggs"]) != int(evidence["sound"])
		or int(data["golden_eggs"]) != int(evidence["golden"])
	):
		return {}
	if status == STATUS_SKIPPED:
		if (
			campaign_id != &""
			or int(data["payout_cents"]) != 0
			or int(data["base_payout_cents"]) != 0
			or int(data["public_standing_delta"]) != 0
			or int(data["attribution_delta"]) != 0
		):
			return {}
	else:
		if campaign_id not in CAMPAIGN_ORDER:
			return {}
		var definition := CAMPAIGN_DEFINITIONS[campaign_id] as Dictionary
		var tier_index := level - 1
		var per_sound := int((definition["per_sound_egg_cents"] as Array)[tier_index])
		var golden_bonus := int((definition["golden_bonus_cents"] as Array)[tier_index])
		var base := int(evidence["sound"]) * per_sound + int(evidence["golden"]) * golden_bonus
		var prior_standing := int(data["public_standing_before"])
		var bonus_bp := mini(2_500, prior_standing * 50)
		var reach := int(definition["base_reach"]) + level - 1 + (1 if bool(evidence["met_quota"]) else 0) + mini(2, int(evidence["golden"]))
		if (
			int(data["per_sound_egg_cents"]) != per_sound
			or int(data["golden_bonus_cents"]) != golden_bonus
			or int(data["base_payout_cents"]) != base
			or int(data["standing_bonus_basis_points"]) != bonus_bp
			or int(data["payout_cents"]) != _basis_points_half_up(base, 10_000 + bonus_bp)
			or int(data["public_standing_delta"]) != reach
			or int(data["public_standing_after"]) != mini(MAX_LEDGER_VALUE, prior_standing + reach)
			or int(data["attribution_delta"]) != int(definition["attribution_delta"])
			or int(data["attribution_after"]) != clampi(int(data["attribution_before"]) + int(definition["attribution_delta"]), -MAX_LEDGER_VALUE, MAX_LEDGER_VALUE)
		):
			return {}
	if (
		String(data["standing_label_before"]) != standing_label_for(int(data["public_standing_before"]))
		or String(data["standing_label_after"]) != standing_label_for(int(data["public_standing_after"]))
		or StringName(String(data["attribution_style"])) != attribution_style_for(int(data["attribution_after"]))
	):
		return {}
	var restored := _canonical_json_value(data) as Dictionary
	restored["evidence"] = evidence
	return restored


static func _history_has_skip_day(receipts: Array[Dictionary], day: int) -> bool:
	for receipt in receipts:
		if StringName(receipt["status"]) == STATUS_SKIPPED and int(receipt["day"]) == day:
			return true
	return false


static func _has_exact_keys(data: Dictionary, keys: Array[String]) -> bool:
	if data.size() != keys.size():
		return false
	for key in keys:
		if not data.has(key):
			return false
	return true


static func _is_integral(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	return typeof(value) == TYPE_FLOAT and is_finite(float(value)) and is_equal_approx(float(value), round(float(value)))


static func _canonical_json_value(value: Variant) -> Variant:
	match typeof(value):
		TYPE_STRING_NAME:
			return String(value)
		TYPE_FLOAT:
			var number := float(value)
			return int(number) if is_finite(number) and is_equal_approx(number, round(number)) else number
		TYPE_ARRAY:
			var normalized_array: Array = []
			for entry in value as Array:
				normalized_array.append(_canonical_json_value(entry))
			return normalized_array
		TYPE_DICTIONARY:
			var normalized_dictionary: Dictionary = {}
			for key in value as Dictionary:
				var normalized_key: Variant = String(key) if typeof(key) == TYPE_STRING_NAME else key
				normalized_dictionary[normalized_key] = _canonical_json_value((value as Dictionary)[key])
			return normalized_dictionary
	return value


static func _basis_points_half_up(value: int, basis_points: int) -> int:
	if value <= 0 or basis_points <= 0:
		return 0
	return mini(MAX_LEDGER_VALUE, (value * basis_points + 5_000) / 10_000)
