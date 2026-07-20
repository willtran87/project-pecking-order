class_name CampaignSaveStore
extends RefCounted


## Versioned, JSON-only campaign persistence for desktop and Web exports.
##
## The public contract deliberately contains only Dictionaries and primitive JSON
## values. Callers save a campaign payload plus optional metadata, then receive an
## envelope shaped like:
## {
##     "schema_version": CURRENT_SCHEMA_VERSION,
##     "campaign": Dictionary,
##     "metadata": Dictionary,
##     "recovered_from_backup": bool,
##     "recovery_source": String,
## }
##
## Callers that must perform domain-level validation across the complete campaign
## payload can use load_recovery_candidates(). It returns every envelope-valid
## snapshot in deterministic attempt order without assuming that envelope validity
## also proves the nested campaign, simulation, and career ledgers are coherent.
##
## To add a schema, increment CURRENT_SCHEMA_VERSION and override or extend
## _migrate_one_version(). Each migration must advance exactly one version.

const CURRENT_SCHEMA_VERSION := 2
const SAVE_FORMAT := "pecking_order_campaign"
const DEFAULT_FILENAME := "campaign.json"

const MAX_FILE_BYTES := 8 * 1024 * 1024
const MAX_NESTING_DEPTH := 64
const MAX_VALUE_COUNT := 100_000
const MAX_STRING_LENGTH := 1_000_000

var last_error: String = ""

var _primary_path: String = ""
var _temporary_path: String = ""
var _backup_path: String = ""
var _backup_temporary_path: String = ""
var _configuration_error: String = ""


func _init(filename: String = DEFAULT_FILENAME) -> void:
	_configure(filename)


## Returns true only when at least one valid, loadable snapshot exists.
func has_save() -> bool:
	last_error = ""
	if not _ensure_configured():
		return false
	for path in _all_paths():
		if not FileAccess.file_exists(path):
			continue
		if bool(_read_envelope(path).get("ok", false)):
			return true
	return false


## Saves a plain campaign Dictionary and optional plain metadata Dictionary.
## Returns false without modifying the last valid primary when validation fails.
func save(campaign: Dictionary, metadata: Dictionary = {}) -> bool:
	last_error = ""
	if not _ensure_configured():
		return false

	var campaign_error := _validate_json_root(campaign, "campaign")
	if not campaign_error.is_empty():
		return _fail("Campaign validation failed: %s" % campaign_error)
	var metadata_error := _validate_json_root(metadata, "metadata")
	if not metadata_error.is_empty():
		return _fail("Metadata validation failed: %s" % metadata_error)

	var stored_metadata: Dictionary = metadata.duplicate(true)
	stored_metadata["saved_at_unix"] = int(Time.get_unix_time_from_system())
	stored_metadata["save_revision"] = _highest_known_revision() + 1
	var envelope := {
		"format": SAVE_FORMAT,
		"schema_version": CURRENT_SCHEMA_VERSION,
		"campaign": campaign.duplicate(true),
		"metadata": stored_metadata,
	}
	envelope["integer_paths"] = _collect_integer_paths(envelope)
	# Production checkpoints are machine envelopes, not hand-authored documents.
	# Compact JSON materially reduces serialization, UTF-8 allocation, Web
	# filesystem copy, and verification cost while preserving identical data.
	var json_text := JSON.stringify(envelope)
	if json_text.to_utf8_buffer().size() > MAX_FILE_BYTES:
		return _fail("Save exceeds the %d-byte limit." % MAX_FILE_BYTES)

	if not _write_text(_temporary_path, json_text):
		return false
	var temporary_result := _read_envelope(_temporary_path)
	if not bool(temporary_result.get("ok", false)):
		return _fail("Temporary save verification failed: %s" % String(temporary_result.get("error", "unknown error")))

	# Preserve only a known-good primary. A corrupt primary must never overwrite a
	# usable backup from the previous successful transaction.
	if FileAccess.file_exists(_primary_path):
		var primary_result := _read_envelope(_primary_path)
		if bool(primary_result.get("ok", false)) and not _refresh_backup():
			return false

	if FileAccess.file_exists(_primary_path):
		var remove_error := DirAccess.remove_absolute(_primary_path)
		if remove_error != OK:
			return _fail("Could not replace the existing save: %s" % error_string(remove_error))

	var rename_error := DirAccess.rename_absolute(_temporary_path, _primary_path)
	if rename_error != OK:
		# Some virtual filesystems cannot rename atomically. Copying the already
		# validated temporary file is the safe Web-compatible fallback.
		var copy_error := DirAccess.copy_absolute(_temporary_path, _primary_path)
		if copy_error != OK:
			return _fail("Could not commit the temporary save: %s" % error_string(copy_error))
		_remove_if_present(_temporary_path)

	var committed_result := _read_envelope(_primary_path)
	if not bool(committed_result.get("ok", false)):
		return _fail("Committed save verification failed: %s" % String(committed_result.get("error", "unknown error")))
	_remove_if_present(_backup_temporary_path)
	last_error = ""
	return true


## Loads the current campaign envelope, or an empty Dictionary on failure.
## A corrupt/missing primary falls back to the newest valid recovery snapshot.
func load() -> Dictionary:
	var candidates := load_recovery_candidates()
	if candidates.is_empty():
		return {}
	var selected := candidates[0]
	return _public_envelope(
		selected,
		bool(selected.get("recovered_from_backup", false)),
		String(selected.get("recovery_source", "primary"))
	)


## Returns one self-contained, current-schema JSON envelope suitable for a
## player-controlled backup file. Recovery-only presentation fields are omitted;
## importing the result creates a new verified local revision through save().
func export_portable_backup() -> String:
	last_error = ""
	var envelope: Dictionary = self.load()
	if envelope.is_empty():
		return ""
	var portable := {
		"format": SAVE_FORMAT,
		"schema_version": CURRENT_SCHEMA_VERSION,
		"campaign": (envelope.get("campaign", {}) as Dictionary).duplicate(true),
		"metadata": (envelope.get("metadata", {}) as Dictionary).duplicate(true),
	}
	portable["integer_paths"] = _collect_integer_paths(portable)
	var json_text := JSON.stringify(portable)
	if json_text.to_utf8_buffer().size() > MAX_FILE_BYTES:
		_fail("Portable backup exceeds the %d-byte limit." % MAX_FILE_BYTES)
		return ""
	return json_text


## Parses, migrates, bounds-checks, and envelope-validates a player-supplied
## backup without touching disk or replacing the current campaign. Office uses
## the returned isolated envelope for full domain-level staging before commit.
func inspect_portable_backup(json_text: String) -> Dictionary:
	last_error = ""
	var result := _parse_envelope_text(json_text)
	if not bool(result.get("ok", false)):
		last_error = String(result.get("error", "Portable backup is invalid."))
		return {}
	return _public_envelope(
		result.get("envelope", {}) as Dictionary,
		false,
		"portable"
	)


## Commits an already inspectable portable backup through the ordinary verified
## temporary-write and backup-rotation transaction. Invalid input cannot modify
## the previous primary or recovery copy.
func import_portable_backup(json_text: String) -> bool:
	var envelope := inspect_portable_backup(json_text)
	if envelope.is_empty():
		return false
	return save(
		envelope.get("campaign", {}) as Dictionary,
		envelope.get("metadata", {}) as Dictionary,
	)


## Returns every envelope-valid snapshot for caller-owned semantic validation.
##
## Ordering deliberately preserves load() selection behavior: a valid primary is
## always first, followed by recovery artifacts in descending save revision. Equal
## recovery revisions use the stable source order backup, temporary, then
## backup_temporary. Invalid or unreadable artifacts are excluded.
##
## Each candidate is a deep-isolated public envelope with two additional fields:
##     "save_revision": int  - canonical revision copied from metadata
##     "is_recovery": bool   - false only for the primary artifact
## Existing "recovery_source" and "recovered_from_backup" fields are retained so
## a semantic loader can publish the same recovery disclosure as load().
func load_recovery_candidates() -> Array[Dictionary]:
	last_error = ""
	if not _ensure_configured():
		return []

	var errors: Array[String] = []
	var primary_candidate: Dictionary = {}
	var recovery_candidates: Array[Dictionary] = []
	for path in _all_paths():
		if not FileAccess.file_exists(path):
			continue
		var result := _read_envelope(path)
		var source := _source_name(path)
		if not bool(result.get("ok", false)):
			errors.append("%s: %s" % [source, String(result.get("error", "invalid"))])
			continue
		var candidate := _recovery_candidate(
			result.get("envelope", {}) as Dictionary,
			source,
			int(result.get("revision", 0))
		)
		if source == "primary":
			primary_candidate = candidate
		else:
			recovery_candidates.append(candidate)

	recovery_candidates.sort_custom(_recovery_candidate_precedes)
	var ordered: Array[Dictionary] = []
	if not primary_candidate.is_empty():
		ordered.append(primary_candidate)
	ordered.append_array(recovery_candidates)
	if not ordered.is_empty():
		last_error = ""
		return ordered

	if errors.is_empty():
		last_error = "No campaign save found."
	else:
		last_error = "No valid campaign save found (%s)." % "; ".join(errors)
	return []


## Removes the primary, backup, and any interrupted-write artifacts.
func delete() -> bool:
	last_error = ""
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
		return _fail("Could not delete every campaign save file (%s)." % "; ".join(failures))
	return true


## Migration hook. Extend this match when CURRENT_SCHEMA_VERSION advances.
## The returned Dictionary must carry schema_version == from_version + 1.
func _migrate_one_version(envelope: Dictionary, from_version: int) -> Dictionary:
	match from_version:
		1:
			var migrated: Dictionary = envelope.duplicate(true)
			if not migrated.has("campaign") and typeof(migrated.get("payload")) == TYPE_DICTIONARY:
				migrated["campaign"] = (migrated.get("payload") as Dictionary).duplicate(true)
			var metadata_value: Variant = migrated.get("metadata", migrated.get("meta", {}))
			if typeof(metadata_value) != TYPE_DICTIONARY:
				return {}
			var migrated_metadata: Dictionary = (metadata_value as Dictionary).duplicate(true)
			migrated_metadata["saved_at_unix"] = migrated_metadata.get("saved_at_unix", 0)
			migrated_metadata["save_revision"] = migrated_metadata.get("save_revision", 0)
			migrated_metadata["migrated_from_schema_version"] = 1
			migrated["format"] = SAVE_FORMAT
			migrated["metadata"] = migrated_metadata
			migrated["schema_version"] = 2
			migrated.erase("payload")
			migrated.erase("meta")
			# Schema one did not distinguish JSON integers from floats. Preserve
			# whole-number legacy values as integers before adding the type map.
			_coerce_integral_numbers(migrated.get("campaign"))
			_coerce_integral_numbers(migrated.get("metadata"))
			migrated["integer_paths"] = _collect_integer_paths(migrated)
			return migrated
		_:
			return {}


func _configure(filename: String) -> void:
	if not _is_safe_filename(filename):
		_configuration_error = "Save filename must be a non-empty filename without path separators."
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
	for codepoint_index in filename.length():
		if filename.unicode_at(codepoint_index) < 32:
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


func _write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return _fail("Could not open temporary save for writing: %s" % error_string(FileAccess.get_open_error()))
	file.store_string(text)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return _fail("Could not finish writing temporary save: %s" % error_string(write_error))
	return true


func _refresh_backup() -> bool:
	if not _remove_if_present(_backup_temporary_path):
		return _fail("Could not clear the stale backup transaction file.")
	var copy_error := DirAccess.copy_absolute(_primary_path, _backup_temporary_path)
	if copy_error != OK:
		return _fail("Could not stage the campaign backup: %s" % error_string(copy_error))
	var staged_result := _read_envelope(_backup_temporary_path)
	if not bool(staged_result.get("ok", false)):
		return _fail("Staged backup verification failed: %s" % String(staged_result.get("error", "unknown error")))
	if FileAccess.file_exists(_backup_path):
		var remove_error := DirAccess.remove_absolute(_backup_path)
		if remove_error != OK:
			return _fail("Could not rotate the previous backup: %s" % error_string(remove_error))
	var rename_error := DirAccess.rename_absolute(_backup_temporary_path, _backup_path)
	if rename_error != OK:
		var fallback_copy_error := DirAccess.copy_absolute(_backup_temporary_path, _backup_path)
		if fallback_copy_error != OK:
			return _fail("Could not commit the campaign backup: %s" % error_string(fallback_copy_error))
		var copied_result := _read_envelope(_backup_path)
		if not bool(copied_result.get("ok", false)):
			return _fail("Copied backup verification failed: %s" % String(copied_result.get("error", "unknown error")))
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
	var file_length := file.get_length()
	if file_length <= 0:
		file.close()
		return {"ok": false, "error": "file is empty"}
	if file_length > MAX_FILE_BYTES:
		file.close()
		return {"ok": false, "error": "file exceeds the size limit"}
	var json_text := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK:
		return {"ok": false, "error": "read failed: %s" % error_string(read_error)}
	return _parse_envelope_text(json_text)


func _parse_envelope_text(json_text: String) -> Dictionary:
	var byte_count := json_text.to_utf8_buffer().size()
	if byte_count <= 0:
		return {"ok": false, "error": "file is empty"}
	if byte_count > MAX_FILE_BYTES:
		return {"ok": false, "error": "file exceeds the size limit"}

	var parser := JSON.new()
	var parse_error := parser.parse(json_text)
	if parse_error != OK:
		return {
			"ok": false,
			"error": "JSON parse failed on line %d: %s" % [parser.get_error_line(), parser.get_error_message()],
		}
	if typeof(parser.data) != TYPE_DICTIONARY:
		return {"ok": false, "error": "save root must be a Dictionary"}

	var raw_envelope: Dictionary = parser.data
	var version_result := _read_schema_version(raw_envelope)
	if not bool(version_result.get("ok", false)):
		return version_result
	var version := int(version_result.get("version", -1))
	if version > CURRENT_SCHEMA_VERSION:
		return {
			"ok": false,
			"error": "save schema %d is newer than supported schema %d" % [version, CURRENT_SCHEMA_VERSION],
		}

	var envelope: Dictionary = raw_envelope.duplicate(true)
	while version < CURRENT_SCHEMA_VERSION:
		var migrated: Variant = _migrate_one_version(envelope, version)
		if typeof(migrated) != TYPE_DICTIONARY or (migrated as Dictionary).is_empty():
			return {"ok": false, "error": "no migration available from schema %d" % version}
		var next_version_result := _read_schema_version(migrated as Dictionary)
		if not bool(next_version_result.get("ok", false)):
			return {"ok": false, "error": "migration from schema %d returned an invalid version" % version}
		var next_version := int(next_version_result.get("version", -1))
		if next_version != version + 1:
			return {"ok": false, "error": "migration must advance exactly one schema version"}
		envelope = (migrated as Dictionary).duplicate(true)
		version = next_version

	var integer_restore_error := _restore_integer_paths(envelope)
	if not integer_restore_error.is_empty():
		return {"ok": false, "error": integer_restore_error}
	var envelope_error := _validate_current_envelope(envelope)
	if not envelope_error.is_empty():
		return {"ok": false, "error": envelope_error}
	var metadata := envelope.get("metadata", {}) as Dictionary
	return {
		"ok": true,
		"envelope": envelope,
		"revision": int(metadata.get("save_revision", 0)),
	}


func _read_schema_version(envelope: Dictionary) -> Dictionary:
	if not envelope.has("schema_version"):
		return {"ok": false, "error": "schema_version is missing"}
	var value: Variant = envelope.get("schema_version")
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return {"ok": false, "error": "schema_version must be an integer"}
	var numeric := float(value)
	if is_nan(numeric) or is_inf(numeric) or floor(numeric) != numeric or numeric < 1.0:
		return {"ok": false, "error": "schema_version must be a positive integer"}
	return {"ok": true, "version": int(numeric)}


func _validate_current_envelope(envelope: Dictionary) -> String:
	if String(envelope.get("format", "")) != SAVE_FORMAT:
		return "save format marker is missing or invalid"
	var version_result := _read_schema_version(envelope)
	if not bool(version_result.get("ok", false)) or int(version_result.get("version", -1)) != CURRENT_SCHEMA_VERSION:
		return "save schema does not match the current schema"
	if typeof(envelope.get("campaign")) != TYPE_DICTIONARY:
		return "campaign payload must be a Dictionary"
	if typeof(envelope.get("metadata")) != TYPE_DICTIONARY:
		return "metadata must be a Dictionary"
	if typeof(envelope.get("integer_paths")) != TYPE_ARRAY:
		return "integer_paths must be an Array"
	var campaign_error := _validate_json_root(envelope.get("campaign") as Dictionary, "campaign")
	if not campaign_error.is_empty():
		return campaign_error
	var metadata: Dictionary = envelope.get("metadata") as Dictionary
	var metadata_error := _validate_json_root(metadata, "metadata")
	if not metadata_error.is_empty():
		return metadata_error
	if not _is_nonnegative_integer(metadata.get("saved_at_unix")):
		return "metadata.saved_at_unix must be a non-negative integer"
	if not _is_nonnegative_integer(metadata.get("save_revision")):
		return "metadata.save_revision must be a non-negative integer"
	return ""


func _highest_known_revision() -> int:
	var highest := 0
	for path in _all_paths():
		if not FileAccess.file_exists(path):
			continue
		var result := _read_envelope(path)
		if bool(result.get("ok", false)):
			highest = maxi(highest, int(result.get("revision", 0)))
	return highest


func _public_envelope(envelope: Dictionary, recovered: bool, source: String) -> Dictionary:
	return {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"campaign": (envelope.get("campaign", {}) as Dictionary).duplicate(true),
		"metadata": (envelope.get("metadata", {}) as Dictionary).duplicate(true),
		"recovered_from_backup": recovered,
		"recovery_source": source,
	}


func _recovery_candidate(envelope: Dictionary, source: String, revision: int) -> Dictionary:
	var is_recovery := source != "primary"
	var candidate := _public_envelope(envelope, is_recovery, source)
	candidate["save_revision"] = revision
	candidate["is_recovery"] = is_recovery
	return candidate


func _recovery_candidate_precedes(first: Dictionary, second: Dictionary) -> bool:
	var first_revision := int(first.get("save_revision", 0))
	var second_revision := int(second.get("save_revision", 0))
	if first_revision != second_revision:
		return first_revision > second_revision
	return _recovery_source_priority(String(first.get("recovery_source", "unknown"))) < _recovery_source_priority(
		String(second.get("recovery_source", "unknown"))
	)


func _recovery_source_priority(source: String) -> int:
	match source:
		"backup":
			return 0
		"temporary":
			return 1
		"backup_temporary":
			return 2
		_:
			return 3


func _collect_integer_paths(envelope: Dictionary) -> Array[String]:
	var paths: Array[String] = []
	_collect_integer_paths_from_value(envelope.get("campaign"), "/campaign", paths)
	_collect_integer_paths_from_value(envelope.get("metadata"), "/metadata", paths)
	return paths


func _collect_integer_paths_from_value(value: Variant, path: String, paths: Array[String]) -> void:
	match typeof(value):
		TYPE_INT:
			paths.append(path)
		TYPE_ARRAY:
			var array_value: Array = value
			for index in array_value.size():
				_collect_integer_paths_from_value(array_value[index], "%s/%d" % [path, index], paths)
		TYPE_DICTIONARY:
			var dictionary_value: Dictionary = value
			for key in dictionary_value.keys():
				_collect_integer_paths_from_value(
					dictionary_value[key],
					"%s/%s" % [path, _escape_pointer_segment(String(key))],
					paths
				)


func _restore_integer_paths(envelope: Dictionary) -> String:
	var paths_value: Variant = envelope.get("integer_paths")
	if typeof(paths_value) != TYPE_ARRAY:
		return "integer_paths is missing or invalid"
	var paths: Array = paths_value
	if paths.size() > MAX_VALUE_COUNT:
		return "integer_paths exceeds the maximum value count"
	for path_value in paths:
		if typeof(path_value) != TYPE_STRING:
			return "integer_paths must contain only Strings"
		var path := String(path_value)
		if path.length() > MAX_STRING_LENGTH or not (path.begins_with("/campaign") or path.begins_with("/metadata")):
			return "integer_paths contains an invalid path"
		var segments := path.trim_prefix("/").split("/", false)
		if segments.is_empty():
			return "integer_paths contains an empty path"
		var current: Variant = envelope
		for segment_index in segments.size() - 1:
			var segment := _unescape_pointer_segment(segments[segment_index])
			if typeof(current) == TYPE_DICTIONARY:
				var current_dictionary: Dictionary = current
				if not current_dictionary.has(segment):
					return "integer path does not exist: %s" % path
				current = current_dictionary[segment]
			elif typeof(current) == TYPE_ARRAY:
				if not segment.is_valid_int():
					return "integer path has an invalid Array index: %s" % path
				var current_array: Array = current
				var index := int(segment)
				if index < 0 or index >= current_array.size():
					return "integer path Array index is out of range: %s" % path
				current = current_array[index]
			else:
				return "integer path crosses a primitive value: %s" % path
		var final_segment := _unescape_pointer_segment(segments[-1])
		var number: Variant
		if typeof(current) == TYPE_DICTIONARY:
			var current_dictionary: Dictionary = current
			if not current_dictionary.has(final_segment):
				return "integer path does not exist: %s" % path
			number = current_dictionary[final_segment]
			if not _is_integral_number(number):
				return "integer path does not point to an integer-compatible number: %s" % path
			current_dictionary[final_segment] = int(number)
		elif typeof(current) == TYPE_ARRAY:
			if not final_segment.is_valid_int():
				return "integer path has an invalid Array index: %s" % path
			var current_array: Array = current
			var index := int(final_segment)
			if index < 0 or index >= current_array.size():
				return "integer path Array index is out of range: %s" % path
			number = current_array[index]
			if not _is_integral_number(number):
				return "integer path does not point to an integer-compatible number: %s" % path
			current_array[index] = int(number)
		else:
			return "integer path parent is not a container: %s" % path
	return ""


func _escape_pointer_segment(segment: String) -> String:
	return segment.replace("~", "~0").replace("/", "~1")


func _unescape_pointer_segment(segment: String) -> String:
	return segment.replace("~1", "/").replace("~0", "~")


func _coerce_integral_numbers(value: Variant) -> void:
	if typeof(value) == TYPE_DICTIONARY:
		var dictionary_value: Dictionary = value
		for key in dictionary_value.keys():
			var child: Variant = dictionary_value[key]
			if typeof(child) == TYPE_FLOAT and _is_integral_number(child):
				dictionary_value[key] = int(child)
			else:
				_coerce_integral_numbers(child)
	elif typeof(value) == TYPE_ARRAY:
		var array_value: Array = value
		for index in array_value.size():
			var child: Variant = array_value[index]
			if typeof(child) == TYPE_FLOAT and _is_integral_number(child):
				array_value[index] = int(child)
			else:
				_coerce_integral_numbers(child)


func _is_integral_number(value: Variant) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var numeric := float(value)
	return not is_nan(numeric) and not is_inf(numeric) and floor(numeric) == numeric


func _validate_json_root(value: Dictionary, path: String) -> String:
	var counter := {"count": 0}
	return _validate_json_value(value, path, 0, [], counter)


func _validate_json_value(value: Variant, path: String, depth: int, ancestors: Array, counter: Dictionary) -> String:
	if depth > MAX_NESTING_DEPTH:
		return "%s exceeds the maximum nesting depth" % path
	counter["count"] = int(counter.get("count", 0)) + 1
	if int(counter.get("count", 0)) > MAX_VALUE_COUNT:
		return "%s exceeds the maximum value count" % path

	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT:
			return ""
		TYPE_FLOAT:
			var number := float(value)
			if is_nan(number) or is_inf(number):
				return "%s contains a non-finite number" % path
			return ""
		TYPE_STRING:
			if String(value).length() > MAX_STRING_LENGTH:
				return "%s contains an oversized string" % path
			return ""
		TYPE_ARRAY:
			if _has_same_reference(ancestors, value):
				return "%s contains a cyclic Array" % path
			ancestors.append(value)
			var array_value: Array = value
			for index in array_value.size():
				var child_error := _validate_json_value(array_value[index], "%s[%d]" % [path, index], depth + 1, ancestors, counter)
				if not child_error.is_empty():
					ancestors.pop_back()
					return child_error
			ancestors.pop_back()
			return ""
		TYPE_DICTIONARY:
			if _has_same_reference(ancestors, value):
				return "%s contains a cyclic Dictionary" % path
			ancestors.append(value)
			var dictionary_value: Dictionary = value
			for key in dictionary_value.keys():
				if typeof(key) != TYPE_STRING:
					ancestors.pop_back()
					return "%s contains a non-String key" % path
				if String(key).length() > MAX_STRING_LENGTH:
					ancestors.pop_back()
					return "%s contains an oversized key" % path
				var child_path := "%s.%s" % [path, String(key)]
				var child_error := _validate_json_value(dictionary_value[key], child_path, depth + 1, ancestors, counter)
				if not child_error.is_empty():
					ancestors.pop_back()
					return child_error
			ancestors.pop_back()
			return ""
		_:
			return "%s contains unsupported type %s" % [path, type_string(typeof(value))]


func _has_same_reference(ancestors: Array, value: Variant) -> bool:
	for ancestor in ancestors:
		if is_same(ancestor, value):
			return true
	return false


func _is_nonnegative_integer(value: Variant) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var numeric := float(value)
	return not is_nan(numeric) and not is_inf(numeric) and floor(numeric) == numeric and numeric >= 0.0


func _fail(message: String) -> bool:
	last_error = message
	return false
