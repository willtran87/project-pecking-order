class_name WebPreferencesMirror
extends RefCounted


## Pure codec for the synchronous browser preference mirror.
##
## The JavaScript wrapper owns only a fixed localStorage key and bounded strings.
## Godot remains the authority for the preference schema and rejects malformed or
## unsupported values before they can affect runtime settings.

const PlayerPreferencesStoreScript := preload("res://core/settings/player_preferences_store.gd")

const MAX_PAYLOAD_BYTES := 512 * 1024
const MIRROR_FORMAT := "pecking_order_web_preferences"

var last_error := ""


func encode(preferences: Dictionary) -> String:
	last_error = ""
	var validation_error := PlayerPreferencesStoreScript.validate(preferences)
	if not validation_error.is_empty():
		last_error = "Browser preference mirror validation failed: %s" % validation_error
		return ""
	var payload := JSON.stringify({
		"format": MIRROR_FORMAT,
		"schema_version": PlayerPreferencesStoreScript.CURRENT_SCHEMA_VERSION,
		"preferences": preferences.duplicate(true),
	})
	if payload.to_utf8_buffer().size() > MAX_PAYLOAD_BYTES:
		last_error = "Browser preference mirror exceeds the %d-byte limit." % MAX_PAYLOAD_BYTES
		return ""
	return payload


func decode(payload: String) -> Dictionary:
	last_error = ""
	if payload.is_empty():
		return {}
	if payload.to_utf8_buffer().size() > MAX_PAYLOAD_BYTES:
		last_error = "Browser preference mirror exceeds the %d-byte limit." % MAX_PAYLOAD_BYTES
		return {}
	var parser := JSON.new()
	var parse_error := parser.parse(payload)
	if parse_error != OK:
		last_error = "Browser preference mirror JSON is invalid."
		return {}
	if not parser.data is Dictionary:
		last_error = "Browser preference mirror root must be a Dictionary."
		return {}
	var root := parser.data as Dictionary
	var preferences: Dictionary = {}
	if root.has("format") or root.has("schema_version") or root.has("preferences"):
		if not _has_exact_keys(root, ["format", "schema_version", "preferences"]):
			last_error = "Browser preference mirror envelope has missing or unsupported fields."
			return {}
		if String(root.get("format", "")) != MIRROR_FORMAT:
			last_error = "Browser preference mirror format marker is invalid."
			return {}
		var version_value: Variant = root.get("schema_version", null)
		if not _is_positive_integer(version_value):
			last_error = "Browser preference mirror schema version is invalid."
			return {}
		var version := int(version_value)
		if version > PlayerPreferencesStoreScript.CURRENT_SCHEMA_VERSION:
			last_error = "Browser preference mirror schema is newer than this build."
			return {}
		if not root.get("preferences") is Dictionary:
			last_error = "Browser preference mirror preferences must be a Dictionary."
			return {}
		var source := root.get("preferences") as Dictionary
		preferences = (
			source.duplicate(true)
			if version == PlayerPreferencesStoreScript.CURRENT_SCHEMA_VERSION else
			_migrate_legacy_preferences(source, version)
		)
	else:
		# Releases before the versioned mirror stored the strict preference payload
		# directly. Accept only the two exact historical contracts, migrate them,
		# and reject arbitrary partial dictionaries.
		var current_error := PlayerPreferencesStoreScript.validate(root)
		if current_error.is_empty():
			preferences = root.duplicate(true)
		elif _matches_legacy_schema(root, 2):
			preferences = _migrate_legacy_preferences(root, 2)
		elif _matches_legacy_schema(root, 1):
			preferences = _migrate_legacy_preferences(root, 1)
		else:
			last_error = "Browser preference mirror validation failed: %s" % current_error
			return {}
	if preferences.is_empty():
		last_error = "Browser preference mirror migration failed."
		return {}
	var validation_error := PlayerPreferencesStoreScript.validate(preferences)
	if not validation_error.is_empty():
		last_error = "Browser preference mirror validation failed: %s" % validation_error
		return {}
	return preferences.duplicate(true)


func _migrate_legacy_preferences(source: Dictionary, from_version: int) -> Dictionary:
	if not _matches_legacy_schema(source, from_version):
		return {}
	var migrated := source.duplicate(true)
	var version := from_version
	if version == 1:
		migrated["color_vision_mode"] = "standard"
		version = 2
	if version == 2:
		var audio := (migrated.get("audio", {}) as Dictionary).duplicate(true)
		audio["ambient"] = (audio.get("music", {}) as Dictionary).duplicate(true)
		migrated["audio"] = audio
		migrated["pause_when_unfocused"] = true
		version = 3
	if version != PlayerPreferencesStoreScript.CURRENT_SCHEMA_VERSION:
		return {}
	return migrated if PlayerPreferencesStoreScript.validate(migrated).is_empty() else {}


func _matches_legacy_schema(preferences: Dictionary, version: int) -> bool:
	var expected := [
		"audio", "motion_mode", "ui_scale", "high_contrast",
		"visual_quality", "timing_assist", "input_bindings",
	]
	if version >= 2:
		expected.append("color_vision_mode")
	if not _has_exact_keys(preferences, expected):
		return false
	var audio_value: Variant = preferences.get("audio", null)
	return (
		audio_value is Dictionary
		and _has_exact_keys(audio_value as Dictionary, ["master", "sfx", "ui", "music"])
	)


func _has_exact_keys(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size():
		return false
	for key_value: Variant in value:
		if typeof(key_value) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return false
		if String(key_value) not in expected:
			return false
	for key_value: Variant in expected:
		var key := String(key_value)
		if not value.has(key) and not value.has(StringName(key)):
			return false
	return true


func _is_positive_integer(value: Variant) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var number := float(value)
	return not is_nan(number) and not is_inf(number) and floor(number) == number and number >= 1.0
