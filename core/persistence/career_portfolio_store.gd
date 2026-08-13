class_name CareerPortfolioStore
extends RefCounted

## Small, independent index for the three local career roosts. Campaign payloads
## remain owned by CampaignSaveStore; this file only remembers which verified
## filename is active and the player's cosmetic coop identity for each roost.

const FORMAT := "pecking_order_career_portfolio"
const VERSION := 1
const DEFAULT_FILENAME := "career_portfolio.json"
const SLOT_IDS: Array[StringName] = [&"roost_a", &"roost_b", &"roost_c"]
const SLOT_DEFINITIONS := {
	&"roost_a": {"label": "ROOST A", "filename": "probation_campaign.json"},
	&"roost_b": {"label": "ROOST B", "filename": "probation_campaign_slot_b.json"},
	&"roost_c": {"label": "ROOST C", "filename": "probation_campaign_slot_c.json"},
}
const IDENTITY_IDS: Array[StringName] = [&"open_nest", &"brass_beak", &"field_union"]
const IDENTITY_DEFINITIONS := {
	&"open_nest": {
		"label": "OPEN NEST CO-OP",
		"short": "OPEN NEST",
		"emblem": "OPEN WING",
		"color": "73b5a7",
		"promise": "Care is an operating system, not a poster.",
	},
	&"brass_beak": {
		"label": "BRASS BEAK BUREAU",
		"short": "BRASS BEAK",
		"emblem": "BRASS EGG",
		"color": "d1a650",
		"promise": "Every result earns a visible receipt.",
	},
	&"field_union": {
		"label": "FIELD & FLOCK UNION",
		"short": "FIELD & FLOCK",
		"emblem": "JOINED PERCH",
		"color": "c96f59",
		"promise": "No basket is credited without the flock that filled it.",
	},
}

var last_error := ""
var _path := ""
var _temporary_path := ""
var _data: Dictionary = {}


func _init(filename: String = DEFAULT_FILENAME) -> void:
	if filename.is_empty() or "/" in filename or "\\" in filename or ":" in filename:
		last_error = "Career portfolio filename is invalid."
		return
	_path = "user://%s" % filename
	_temporary_path = "%s.tmp" % _path
	_data = defaults()


static func defaults() -> Dictionary:
	var profiles := {}
	for slot_id in SLOT_IDS:
		profiles[String(slot_id)] = {"identity_id": String(IDENTITY_IDS[0])}
	return {
		"format": FORMAT,
		"version": VERSION,
		"active_slot": String(SLOT_IDS[0]),
		"profiles": profiles,
	}


static func slot_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot_id in SLOT_IDS:
		var definition := (SLOT_DEFINITIONS[slot_id] as Dictionary).duplicate(true)
		definition["id"] = String(slot_id)
		result.append(definition)
	return result


static func identity_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for identity_id in IDENTITY_IDS:
		result.append(identity(identity_id))
	return result


static func identity(identity_id: StringName) -> Dictionary:
	var normalized := StringName(String(identity_id).strip_edges().to_lower())
	if not IDENTITY_DEFINITIONS.has(normalized):
		normalized = IDENTITY_IDS[0]
	var result := (IDENTITY_DEFINITIONS[normalized] as Dictionary).duplicate(true)
	result["id"] = String(normalized)
	return result


static func filename_for_slot(slot_id: StringName) -> String:
	var normalized := normalize_slot_id(slot_id)
	return String((SLOT_DEFINITIONS[normalized] as Dictionary).get("filename", "probation_campaign.json"))


static func normalize_slot_id(slot_id: StringName) -> StringName:
	var normalized := StringName(String(slot_id).strip_edges().to_lower())
	return normalized if normalized in SLOT_IDS else SLOT_IDS[0]


static func normalize_profile(value: Variant) -> Dictionary:
	var source := value as Dictionary if value is Dictionary else {}
	return identity(StringName(String(source.get("identity_id", IDENTITY_IDS[0]))))


func load_portfolio() -> Dictionary:
	last_error = ""
	if _path.is_empty():
		return defaults()
	if not FileAccess.file_exists(_path):
		_data = defaults()
		return _data.duplicate(true)
	var file := FileAccess.open(_path, FileAccess.READ)
	if file == null:
		last_error = "Career portfolio could not be opened."
		_data = defaults()
		return _data.duplicate(true)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		last_error = "Career portfolio was malformed; safe defaults were restored."
		_data = defaults()
		return _data.duplicate(true)
	_data = _sanitize(parsed as Dictionary)
	return _data.duplicate(true)


func snapshot() -> Dictionary:
	if _data.is_empty():
		load_portfolio()
	return _data.duplicate(true)


func active_slot_id() -> StringName:
	if _data.is_empty():
		load_portfolio()
	return normalize_slot_id(StringName(String(_data.get("active_slot", SLOT_IDS[0]))))


func profile_for_slot(slot_id: StringName) -> Dictionary:
	if _data.is_empty():
		load_portfolio()
	var normalized := normalize_slot_id(slot_id)
	var profiles := _data.get("profiles", {}) as Dictionary
	return normalize_profile(profiles.get(String(normalized), {}))


func activate_slot(slot_id: StringName) -> bool:
	if _data.is_empty():
		load_portfolio()
	var normalized := normalize_slot_id(slot_id)
	if normalized != slot_id:
		last_error = "Unknown career roost."
		return false
	_data["active_slot"] = String(normalized)
	return _save()


func set_identity(slot_id: StringName, identity_id: StringName) -> bool:
	if _data.is_empty():
		load_portfolio()
	var normalized_slot := normalize_slot_id(slot_id)
	var normalized_identity := StringName(String(identity_id).strip_edges().to_lower())
	if normalized_slot != slot_id or normalized_identity not in IDENTITY_IDS:
		last_error = "Career identity selection is invalid."
		return false
	var profiles := (_data.get("profiles", {}) as Dictionary).duplicate(true)
	profiles[String(normalized_slot)] = {"identity_id": String(normalized_identity)}
	_data["profiles"] = profiles
	return _save()


func _sanitize(source: Dictionary) -> Dictionary:
	var result := defaults()
	result["active_slot"] = String(normalize_slot_id(StringName(String(source.get("active_slot", "roost_a")))))
	var source_profiles := source.get("profiles", {}) as Dictionary if source.get("profiles", {}) is Dictionary else {}
	var profiles := result.get("profiles", {}) as Dictionary
	for slot_id in SLOT_IDS:
		var profile := normalize_profile(source_profiles.get(String(slot_id), {}))
		profiles[String(slot_id)] = {"identity_id": String(profile.get("id", IDENTITY_IDS[0]))}
	result["profiles"] = profiles
	return result


func _save() -> bool:
	last_error = ""
	if _path.is_empty():
		last_error = "Career portfolio store is not configured."
		return false
	_data = _sanitize(_data)
	var text := JSON.stringify(_data)
	var file := FileAccess.open(_temporary_path, FileAccess.WRITE)
	if file == null:
		last_error = "Career portfolio could not stage its update."
		return false
	file.store_string(text)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		last_error = "Career portfolio update could not be completed."
		return false
	if FileAccess.file_exists(_path):
		var remove_error := DirAccess.remove_absolute(_path)
		if remove_error != OK:
			last_error = "Career portfolio could not replace its prior index."
			return false
	var rename_error := DirAccess.rename_absolute(_temporary_path, _path)
	if rename_error != OK:
		var copy_error := DirAccess.copy_absolute(_temporary_path, _path)
		if copy_error != OK:
			last_error = "Career portfolio could not commit its update."
			return false
		DirAccess.remove_absolute(_temporary_path)
	return true
