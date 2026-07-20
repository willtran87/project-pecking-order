class_name PlayerPreferencesStore
extends RefCounted


## Versioned, validated player preferences kept independently from career data.
##
## Writes are staged and verified before the last known-good primary is rotated
## to a recovery copy. Loading selects the highest-revision valid recovery file
## if the primary is missing or corrupt. Public preference values remain plain,
## JSON-safe Dictionaries so desktop and Web builds share one contract.

const OfficeActionCatalogScript := preload("res://core/settings/office_action_catalog.gd")
const SemanticColorPaletteScript := preload("res://core/settings/semantic_color_palette.gd")

const CURRENT_SCHEMA_VERSION := 3
const PREFERENCES_FORMAT := "pecking_order_player_preferences"
const DEFAULT_FILENAME := "player_preferences.json"
const MAX_FILE_BYTES := 512 * 1024

const MOTION_MODES: Array[String] = ["system", "reduced", "full"]
const UI_SCALES: Array[float] = [1.0, 1.25, 1.5]
const VISUAL_QUALITIES: Array[String] = ["low", "balanced", "high"]
const TIMING_ASSISTS: Array[String] = ["standard", "lenient", "extended"]
const COLOR_VISION_MODES: Array[String] = ["standard", "color_blind_safe"]
const AUDIO_BUS_IDS: Array[String] = ["master", "sfx", "ui", "music", "ambient"]
const AUDIO_BUS_NAMES := {
	"master": &"Master",
	"sfx": &"SFX",
	"ui": &"UI",
	"music": &"Music",
	"ambient": &"Ambient",
}

var last_error: String = ""
var last_load_recovered := false
var last_recovery_source: String = ""

var _primary_path: String = ""
var _temporary_path: String = ""
var _backup_path: String = ""
var _backup_temporary_path: String = ""
var _configuration_error: String = ""


func _init(filename: String = DEFAULT_FILENAME) -> void:
	_configure(filename)


static func defaults() -> Dictionary:
	return {
		"audio": {
			"master": {"volume": 1.0, "muted": false},
			"sfx": {"volume": 0.82, "muted": false},
			"ui": {"volume": 0.82, "muted": false},
			"music": {"volume": 0.65, "muted": false},
			"ambient": {"volume": 0.65, "muted": false},
		},
		"motion_mode": "system",
		"ui_scale": 1.0,
		"high_contrast": false,
		"color_vision_mode": "standard",
		"visual_quality": "balanced",
		"timing_assist": "standard",
		"pause_when_unfocused": true,
		# Empty means the catalog defaults. Only explicit overrides need to be
		# persisted, which lets later versions add actions without a migration.
		"input_bindings": {},
	}


## Produces a complete safe preference Dictionary from UI drafts or legacy
## callers. Invalid individual fields fall back independently; save_preferences
## remains strict so a corrupt caller cannot silently replace a known-good file.
static func sanitize(source: Dictionary) -> Dictionary:
	var result := defaults()
	var audio_value: Variant = source.get("audio", {})
	if audio_value is Dictionary:
		var source_audio := audio_value as Dictionary
		var result_audio := result.get("audio", {}) as Dictionary
		for bus_id in AUDIO_BUS_IDS:
			var bus_value: Variant = source_audio.get(bus_id, {})
			if not bus_value is Dictionary:
				continue
			var bus_source := bus_value as Dictionary
			var bus_result := result_audio.get(bus_id, {}) as Dictionary
			var volume_value: Variant = bus_source.get("volume", bus_result.get("volume", 1.0))
			if _is_finite_number(volume_value):
				bus_result["volume"] = clampf(float(volume_value), 0.0, 1.0)
			if typeof(bus_source.get("muted", null)) == TYPE_BOOL:
				bus_result["muted"] = bool(bus_source["muted"])
			result_audio[bus_id] = bus_result
		result["audio"] = result_audio

	var motion_mode := String(source.get("motion_mode", ""))
	if motion_mode in MOTION_MODES:
		result["motion_mode"] = motion_mode
	var ui_scale_value: Variant = source.get("ui_scale", null)
	if _is_finite_number(ui_scale_value):
		result["ui_scale"] = _nearest_ui_scale(float(ui_scale_value))
	if typeof(source.get("high_contrast", null)) == TYPE_BOOL:
		result["high_contrast"] = bool(source["high_contrast"])
	var color_vision_mode := String(source.get("color_vision_mode", ""))
	if color_vision_mode in COLOR_VISION_MODES:
		result["color_vision_mode"] = String(SemanticColorPaletteScript.normalize_mode(color_vision_mode))
	var visual_quality := String(source.get("visual_quality", ""))
	if visual_quality in VISUAL_QUALITIES:
		result["visual_quality"] = visual_quality
	var timing_assist := String(source.get("timing_assist", ""))
	if timing_assist in TIMING_ASSISTS:
		result["timing_assist"] = timing_assist
	if typeof(source.get("pause_when_unfocused", null)) == TYPE_BOOL:
		result["pause_when_unfocused"] = bool(source["pause_when_unfocused"])
	var bindings_value: Variant = source.get("input_bindings", {})
	if bindings_value is Dictionary:
		var binding_result: Dictionary = OfficeActionCatalogScript.validate_bindings(bindings_value as Dictionary)
		if bool(binding_result.get("valid", false)):
			result["input_bindings"] = (binding_result.get("bindings", {}) as Dictionary).duplicate(true)
	return result


## Returns an empty String when `preferences` is exactly safe for persistence.
static func validate(preferences: Dictionary) -> String:
	var expected_keys: Array[String] = [
		"audio", "motion_mode", "ui_scale", "high_contrast",
		"color_vision_mode", "visual_quality", "timing_assist",
		"pause_when_unfocused", "input_bindings",
	]
	var key_error := _exact_string_keys_error(preferences, expected_keys, "preferences")
	if not key_error.is_empty():
		return key_error
	if not preferences.get("audio") is Dictionary:
		return "preferences.audio must be a Dictionary"
	var audio := preferences.get("audio") as Dictionary
	key_error = _exact_string_keys_error(audio, AUDIO_BUS_IDS, "preferences.audio")
	if not key_error.is_empty():
		return key_error
	for bus_id in AUDIO_BUS_IDS:
		if not audio.get(bus_id) is Dictionary:
			return "preferences.audio.%s must be a Dictionary" % bus_id
		var bus := audio.get(bus_id) as Dictionary
		key_error = _exact_string_keys_error(bus, ["volume", "muted"], "preferences.audio.%s" % bus_id)
		if not key_error.is_empty():
			return key_error
		var volume_value: Variant = bus.get("volume")
		if not _is_finite_number(volume_value) or float(volume_value) < 0.0 or float(volume_value) > 1.0:
			return "preferences.audio.%s.volume must be between 0 and 1" % bus_id
		if typeof(bus.get("muted")) != TYPE_BOOL:
			return "preferences.audio.%s.muted must be a Boolean" % bus_id
	if typeof(preferences.get("motion_mode")) != TYPE_STRING or String(preferences.get("motion_mode")) not in MOTION_MODES:
		return "preferences.motion_mode is invalid"
	var ui_scale_value: Variant = preferences.get("ui_scale")
	if not _is_finite_number(ui_scale_value) or not _is_allowed_ui_scale(float(ui_scale_value)):
		return "preferences.ui_scale must be 1.0, 1.25, or 1.5"
	if typeof(preferences.get("high_contrast")) != TYPE_BOOL:
		return "preferences.high_contrast must be a Boolean"
	if typeof(preferences.get("color_vision_mode")) != TYPE_STRING or String(preferences.get("color_vision_mode")) not in COLOR_VISION_MODES:
		return "preferences.color_vision_mode is invalid"
	if typeof(preferences.get("visual_quality")) != TYPE_STRING or String(preferences.get("visual_quality")) not in VISUAL_QUALITIES:
		return "preferences.visual_quality is invalid"
	if typeof(preferences.get("timing_assist")) != TYPE_STRING or String(preferences.get("timing_assist")) not in TIMING_ASSISTS:
		return "preferences.timing_assist is invalid"
	if typeof(preferences.get("pause_when_unfocused")) != TYPE_BOOL:
		return "preferences.pause_when_unfocused must be a Boolean"
	if not preferences.get("input_bindings") is Dictionary:
		return "preferences.input_bindings must be a Dictionary"
	var binding_result: Dictionary = OfficeActionCatalogScript.validate_bindings(preferences.get("input_bindings") as Dictionary)
	if not bool(binding_result.get("valid", false)):
		return "preferences.input_bindings: %s" % String(binding_result.get("error", "invalid bindings"))
	return ""


func has_preferences() -> bool:
	last_error = ""
	if not _ensure_configured():
		return false
	for path in _all_paths():
		if FileAccess.file_exists(path) and bool(_read_envelope(path).get("ok", false)):
			return true
	return false


## Strictly saves a complete preferences Dictionary. Call sanitize() explicitly
## for a draft that may contain unchecked UI or imported values.
func save_preferences(preferences: Dictionary) -> bool:
	last_error = ""
	last_load_recovered = false
	last_recovery_source = ""
	if not _ensure_configured():
		return false
	var validation_error := validate(preferences)
	if not validation_error.is_empty():
		return _fail("Preferences validation failed: %s" % validation_error)

	var envelope := {
		"format": PREFERENCES_FORMAT,
		"schema_version": CURRENT_SCHEMA_VERSION,
		"preferences": preferences.duplicate(true),
		"metadata": {
			"saved_at_unix": int(Time.get_unix_time_from_system()),
			"save_revision": _highest_known_revision() + 1,
		},
	}
	var json_text := JSON.stringify(envelope, "\t")
	if json_text.to_utf8_buffer().size() > MAX_FILE_BYTES:
		return _fail("Preferences exceed the %d-byte limit." % MAX_FILE_BYTES)
	if not _write_text(_temporary_path, json_text):
		return false
	var temporary_result := _read_envelope(_temporary_path)
	if not bool(temporary_result.get("ok", false)):
		return _fail("Temporary preferences verification failed: %s" % String(temporary_result.get("error", "unknown error")))

	if FileAccess.file_exists(_primary_path):
		var primary_result := _read_envelope(_primary_path)
		if bool(primary_result.get("ok", false)) and not _refresh_backup():
			return false
	if FileAccess.file_exists(_primary_path):
		var remove_error := DirAccess.remove_absolute(_primary_path)
		if remove_error != OK:
			return _fail("Could not replace existing preferences: %s" % error_string(remove_error))
	var rename_error := DirAccess.rename_absolute(_temporary_path, _primary_path)
	if rename_error != OK:
		# Web virtual filesystems may not support atomic rename. The temporary
		# payload has already been read back and fully validated.
		var copy_error := DirAccess.copy_absolute(_temporary_path, _primary_path)
		if copy_error != OK:
			return _fail("Could not commit preferences: %s" % error_string(copy_error))
		_remove_if_present(_temporary_path)
	var committed_result := _read_envelope(_primary_path)
	if not bool(committed_result.get("ok", false)):
		return _fail("Committed preferences verification failed: %s" % String(committed_result.get("error", "unknown error")))
	_remove_if_present(_backup_temporary_path)
	last_error = ""
	return true


## Always returns a complete validated preference set. Missing or wholly corrupt
## files fall back to defaults while last_error explains the failure. Recovery
## from a valid backup/temp file is disclosed through the public status fields.
func load_preferences() -> Dictionary:
	last_error = ""
	last_load_recovered = false
	last_recovery_source = ""
	if not _ensure_configured():
		return defaults()

	var errors: Array[String] = []
	if FileAccess.file_exists(_primary_path):
		var primary_result := _read_envelope(_primary_path)
		if bool(primary_result.get("ok", false)):
			return (primary_result.get("preferences", defaults()) as Dictionary).duplicate(true)
		errors.append("primary: %s" % String(primary_result.get("error", "invalid")))

	var best_recovery: Dictionary = {}
	for path in [_backup_path, _temporary_path, _backup_temporary_path]:
		if not FileAccess.file_exists(path):
			continue
		var result := _read_envelope(path)
		if not bool(result.get("ok", false)):
			errors.append("%s: %s" % [_source_name(path), String(result.get("error", "invalid"))])
			continue
		if best_recovery.is_empty() or int(result.get("revision", -1)) > int(best_recovery.get("revision", -1)):
			best_recovery = result.duplicate(true)
			best_recovery["source"] = _source_name(path)
	if not best_recovery.is_empty():
		last_load_recovered = true
		last_recovery_source = String(best_recovery.get("source", "recovery"))
		return (best_recovery.get("preferences", defaults()) as Dictionary).duplicate(true)

	if not errors.is_empty():
		last_error = "No valid preferences found (%s). Defaults restored." % "; ".join(errors)
	return defaults()


func delete_preferences() -> bool:
	last_error = ""
	last_load_recovered = false
	last_recovery_source = ""
	if not _ensure_configured():
		return false
	var failures: Array[String] = []
	for path in _all_paths():
		if not FileAccess.file_exists(path):
			continue
		var remove_error := DirAccess.remove_absolute(path)
		if remove_error != OK:
			failures.append("%s: %s" % [_source_name(path), error_string(remove_error)])
	if not failures.is_empty():
		return _fail("Could not delete every preferences file (%s)." % "; ".join(failures))
	return true


## Applies only the audio branch and returns the canonical values actually used.
## Missing SFX/UI/Music/Ambient buses are created once and routed through Master.
static func apply_audio(preferences: Dictionary) -> Dictionary:
	var safe := sanitize(preferences)
	var audio := safe.get("audio", {}) as Dictionary
	var applied: Array[String] = []
	for bus_id in AUDIO_BUS_IDS:
		var bus_name: StringName = AUDIO_BUS_NAMES[bus_id]
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			AudioServer.add_bus()
			bus_index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(bus_index, bus_name)
			if bus_name != &"Master":
				AudioServer.set_bus_send(bus_index, &"Master")
		var bus := audio.get(bus_id, {}) as Dictionary
		var volume := clampf(float(bus.get("volume", 1.0)), 0.0, 1.0)
		# Avoid passing negative infinity to platform audio backends. Muting remains
		# a separate explicit preference even when the slider itself is at zero.
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(volume, 0.0001)))
		AudioServer.set_bus_mute(bus_index, bool(bus.get("muted", false)))
		applied.append(bus_id)
	return {"accepted": true, "applied": applied, "audio": audio.duplicate(true)}


func _configure(filename: String) -> void:
	if not _is_safe_filename(filename):
		_configuration_error = "Preferences filename must be a safe filename without path separators."
		last_error = _configuration_error
		return
	_primary_path = "user://%s" % filename
	_temporary_path = "%s.tmp" % _primary_path
	_backup_path = "%s.bak" % _primary_path
	_backup_temporary_path = "%s.bak.tmp" % _primary_path


func _ensure_configured() -> bool:
	if _configuration_error.is_empty():
		return true
	last_error = _configuration_error
	return false


func _is_safe_filename(filename: String) -> bool:
	if filename.is_empty() or filename.length() > 128:
		return false
	if filename != filename.strip_edges() or filename in [".", ".."]:
		return false
	for index in filename.length():
		if filename.unicode_at(index) < 32:
			return false
	for forbidden in ["/", "\\", ":"]:
		if filename.contains(forbidden):
			return false
	return true


func _all_paths() -> Array[String]:
	return [_primary_path, _backup_path, _temporary_path, _backup_temporary_path]


func _source_name(path: String) -> String:
	if path == _primary_path:
		return "primary"
	if path == _backup_path:
		return "backup"
	if path == _temporary_path:
		return "temporary"
	if path == _backup_temporary_path:
		return "backup_temporary"
	return "unknown"


func _write_text(path: String, contents: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return _fail("Could not open temporary preferences: %s" % error_string(FileAccess.get_open_error()))
	file.store_string(contents)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return _fail("Could not finish writing preferences: %s" % error_string(write_error))
	return true


func _refresh_backup() -> bool:
	if not _remove_if_present(_backup_temporary_path):
		return _fail("Could not clear stale preferences backup transaction.")
	var copy_error := DirAccess.copy_absolute(_primary_path, _backup_temporary_path)
	if copy_error != OK:
		return _fail("Could not stage preferences backup: %s" % error_string(copy_error))
	var staged_result := _read_envelope(_backup_temporary_path)
	if not bool(staged_result.get("ok", false)):
		return _fail("Staged preferences backup failed verification.")
	if FileAccess.file_exists(_backup_path):
		var remove_error := DirAccess.remove_absolute(_backup_path)
		if remove_error != OK:
			return _fail("Could not rotate preferences backup: %s" % error_string(remove_error))
	var rename_error := DirAccess.rename_absolute(_backup_temporary_path, _backup_path)
	if rename_error != OK:
		var fallback_error := DirAccess.copy_absolute(_backup_temporary_path, _backup_path)
		if fallback_error != OK:
			return _fail("Could not commit preferences backup: %s" % error_string(fallback_error))
		if not bool(_read_envelope(_backup_path).get("ok", false)):
			return _fail("Copied preferences backup failed verification.")
		_remove_if_present(_backup_temporary_path)
	return true


func _remove_if_present(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(path) == OK


func _read_envelope(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "file does not exist"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "open failed: %s" % error_string(FileAccess.get_open_error())}
	var length := file.get_length()
	if length <= 0 or length > MAX_FILE_BYTES:
		file.close()
		return {"ok": false, "error": "file size is invalid"}
	var json_text := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK:
		return {"ok": false, "error": "read failed: %s" % error_string(read_error)}
	var parser := JSON.new()
	var parse_error := parser.parse(json_text)
	if parse_error != OK:
		return {"ok": false, "error": "JSON parse failed on line %d: %s" % [parser.get_error_line(), parser.get_error_message()]}
	if not parser.data is Dictionary:
		return {"ok": false, "error": "preferences root must be a Dictionary"}
	var envelope := (parser.data as Dictionary).duplicate(true)
	var schema_result := _schema_version(envelope)
	if not bool(schema_result.get("ok", false)):
		return schema_result
	var version := int(schema_result.get("version", -1))
	if version > CURRENT_SCHEMA_VERSION:
		return {"ok": false, "error": "preferences schema %d is newer than supported schema %d" % [version, CURRENT_SCHEMA_VERSION]}
	while version < CURRENT_SCHEMA_VERSION:
		var migrated := _migrate_one_version(envelope, version)
		if migrated.is_empty():
			return {"ok": false, "error": "no preferences migration available from schema %d" % version}
		envelope = migrated
		version += 1
	var envelope_error := _validate_envelope(envelope)
	if not envelope_error.is_empty():
		return {"ok": false, "error": envelope_error}
	var metadata := envelope.get("metadata", {}) as Dictionary
	return {
		"ok": true,
		"preferences": sanitize(envelope.get("preferences", {}) as Dictionary),
		"revision": int(metadata.get("save_revision", 0)),
	}


func _validate_envelope(envelope: Dictionary) -> String:
	var key_error := _exact_string_keys_error(
		envelope,
		["format", "schema_version", "preferences", "metadata"],
		"preferences envelope",
	)
	if not key_error.is_empty():
		return key_error
	if String(envelope.get("format", "")) != PREFERENCES_FORMAT:
		return "preferences format marker is invalid"
	var version_result := _schema_version(envelope)
	if not bool(version_result.get("ok", false)) or int(version_result.get("version", -1)) != CURRENT_SCHEMA_VERSION:
		return "preferences schema does not match the current schema"
	if not envelope.get("preferences") is Dictionary:
		return "preferences payload must be a Dictionary"
	var preference_error := validate(envelope.get("preferences") as Dictionary)
	if not preference_error.is_empty():
		return preference_error
	if not envelope.get("metadata") is Dictionary:
		return "preferences metadata must be a Dictionary"
	var metadata := envelope.get("metadata") as Dictionary
	key_error = _exact_string_keys_error(metadata, ["saved_at_unix", "save_revision"], "preferences metadata")
	if not key_error.is_empty():
		return key_error
	if not _is_nonnegative_integer(metadata.get("saved_at_unix")):
		return "preferences metadata.saved_at_unix must be a non-negative integer"
	if not _is_nonnegative_integer(metadata.get("save_revision")):
		return "preferences metadata.save_revision must be a non-negative integer"
	return ""


func _schema_version(envelope: Dictionary) -> Dictionary:
	var value: Variant = envelope.get("schema_version", null)
	if not _is_nonnegative_integer(value) or int(value) < 1:
		return {"ok": false, "error": "preferences schema_version must be a positive integer"}
	return {"ok": true, "version": int(value)}


func _migrate_one_version(envelope: Dictionary, from_version: int) -> Dictionary:
	if from_version == 1:
		var migrated := envelope.duplicate(true)
		var preferences_value: Variant = migrated.get("preferences", {})
		if not preferences_value is Dictionary:
			return {}
		var preferences := (preferences_value as Dictionary).duplicate(true)
		preferences["color_vision_mode"] = "standard"
		migrated["preferences"] = preferences
		migrated["schema_version"] = 2
		return migrated
	if from_version == 2:
		var migrated := envelope.duplicate(true)
		var preferences_value: Variant = migrated.get("preferences", {})
		if not preferences_value is Dictionary:
			return {}
		var preferences := (preferences_value as Dictionary).duplicate(true)
		var audio_value: Variant = preferences.get("audio", {})
		if not audio_value is Dictionary:
			return {}
		var audio := (audio_value as Dictionary).duplicate(true)
		var music_value: Variant = audio.get("music", {})
		audio["ambient"] = (
			(music_value as Dictionary).duplicate(true)
			if music_value is Dictionary else
			{"volume": 0.65, "muted": false}
		)
		preferences["audio"] = audio
		preferences["pause_when_unfocused"] = true
		migrated["preferences"] = preferences
		migrated["schema_version"] = 3
		return migrated
	return {}


func _highest_known_revision() -> int:
	var highest := 0
	for path in _all_paths():
		if not FileAccess.file_exists(path):
			continue
		var result := _read_envelope(path)
		if bool(result.get("ok", false)):
			highest = maxi(highest, int(result.get("revision", 0)))
	return highest


func _fail(message: String) -> bool:
	last_error = message
	return false


static func _exact_string_keys_error(value: Dictionary, expected_keys: Array[String], context: String) -> String:
	if value.size() != expected_keys.size():
		return "%s has missing or unsupported fields" % context
	for key_value in value:
		if typeof(key_value) not in [TYPE_STRING, TYPE_STRING_NAME] or String(key_value) not in expected_keys:
			return "%s has an unsupported field" % context
	for expected in expected_keys:
		if not value.has(expected) and not value.has(StringName(expected)):
			return "%s is missing %s" % [context, expected]
	return ""


static func _nearest_ui_scale(value: float) -> float:
	var nearest := UI_SCALES[0]
	var nearest_distance := absf(value - nearest)
	for candidate in UI_SCALES:
		var distance := absf(value - candidate)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest


static func _is_allowed_ui_scale(value: float) -> bool:
	for candidate in UI_SCALES:
		if is_equal_approx(value, candidate):
			return true
	return false


static func _is_finite_number(value: Variant) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var numeric := float(value)
	return not is_nan(numeric) and not is_inf(numeric)


static func _is_nonnegative_integer(value: Variant) -> bool:
	if not _is_finite_number(value):
		return false
	var numeric := float(value)
	return floor(numeric) == numeric and numeric >= 0.0
