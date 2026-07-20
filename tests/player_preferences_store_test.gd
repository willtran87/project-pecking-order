extends SceneTree

const PlayerPreferencesStoreScript := preload("res://core/settings/player_preferences_store.gd")
const TEST_FILENAME := "player_preferences_store_test.json"
const TEST_PRIMARY_PATH := "user://%s" % TEST_FILENAME
const TEST_PATHS: Array[String] = [
	TEST_PRIMARY_PATH,
	"%s.bak" % TEST_PRIMARY_PATH,
	"%s.tmp" % TEST_PRIMARY_PATH,
	"%s.bak.tmp" % TEST_PRIMARY_PATH,
]
const TARGET_BUS_NAMES: Array[StringName] = [&"Master", &"SFX", &"UI", &"Music", &"Ambient"]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var store = PlayerPreferencesStoreScript.new(TEST_FILENAME)
	_check(store.delete_preferences(), "test preferences should start clean", failures)

	var default_preferences: Dictionary = PlayerPreferencesStoreScript.defaults()
	_check(PlayerPreferencesStoreScript.validate(default_preferences).is_empty(), "defaults should satisfy the strict persistence schema", failures)
	_check(
		default_preferences.keys().size() == 9
		and (default_preferences.get("audio", {}) as Dictionary).keys().size() == 5
		and bool(default_preferences.get("pause_when_unfocused", false)),
		"preferences should remain a compact campaign-independent contract",
		failures,
	)
	_check(store.load_preferences() == default_preferences, "a first launch should return complete defaults", failures)
	_check(store.last_error.is_empty() and not store.last_load_recovered, "missing preferences should be a normal first-launch state", failures)

	var sanitized: Dictionary = PlayerPreferencesStoreScript.sanitize({
		"audio": {
			"master": {"volume": 4.0, "muted": true},
			"sfx": {"volume": -3.0, "muted": "not a bool"},
			"music": {"volume": "loud", "muted": true},
		},
		"motion_mode": "reduced",
		"ui_scale": 1.4,
		"high_contrast": true,
		"color_vision_mode": "sepia",
		"visual_quality": "cinematic",
		"timing_assist": "extended",
		"pause_when_unfocused": false,
		"input_bindings": {"unknown_action": []},
	})
	var sanitized_audio := sanitized.get("audio", {}) as Dictionary
	_check(
		is_equal_approx(float((sanitized_audio.get("master", {}) as Dictionary).get("volume", -1.0)), 1.0)
		and bool((sanitized_audio.get("master", {}) as Dictionary).get("muted", false)),
		"sanitize should clamp master volume and retain a valid mute",
		failures,
	)
	_check(
		is_equal_approx(float((sanitized_audio.get("sfx", {}) as Dictionary).get("volume", -1.0)), 0.0)
		and not bool((sanitized_audio.get("sfx", {}) as Dictionary).get("muted", true)),
		"sanitize should clamp SFX volume and reject a mistyped mute",
		failures,
	)
	_check(
		is_equal_approx(float((sanitized_audio.get("music", {}) as Dictionary).get("volume", -1.0)), 0.65)
		and bool((sanitized_audio.get("music", {}) as Dictionary).get("muted", false)),
		"invalid fields should fall back independently without discarding valid siblings",
		failures,
	)
	_check(
		String(sanitized.get("motion_mode", "")) == "reduced"
		and is_equal_approx(float(sanitized.get("ui_scale", 0.0)), 1.5)
		and bool(sanitized.get("high_contrast", false))
		and String(sanitized.get("color_vision_mode", "")) == "standard"
		and String(sanitized.get("visual_quality", "")) == "balanced"
		and String(sanitized.get("timing_assist", "")) == "extended"
		and not bool(sanitized.get("pause_when_unfocused", true))
		and (sanitized.get("input_bindings", {}) as Dictionary).is_empty(),
		"sanitize should canonicalize comfort, quality, timing, and binding values",
		failures,
	)

	var malformed := default_preferences.duplicate(true)
	malformed["unexpected"] = true
	_check(not store.save_preferences(malformed), "strict save should reject unsupported fields", failures)
	_check("validation failed" in store.last_error.to_lower(), "strict save should explain validation failure", failures)
	_check(not store.has_preferences(), "a rejected save must not create a partial preference file", failures)

	var first_preferences := default_preferences.duplicate(true)
	first_preferences["motion_mode"] = "reduced"
	first_preferences["ui_scale"] = 1.25
	first_preferences["high_contrast"] = true
	first_preferences["color_vision_mode"] = "color_blind_safe"
	first_preferences["visual_quality"] = "high"
	first_preferences["timing_assist"] = "lenient"
	first_preferences["pause_when_unfocused"] = false
	first_preferences["input_bindings"] = {
		"peck_assist": [{"type": "key", "physical_keycode": KEY_Q}],
	}
	first_preferences = PlayerPreferencesStoreScript.sanitize(first_preferences)
	var first_saved := first_preferences.duplicate(true)
	_check(store.save_preferences(first_preferences), "a valid complete preference set should save", failures)
	_check(store.has_preferences(), "has_preferences should recognize a validated envelope", failures)
	first_preferences["motion_mode"] = "full"
	(first_preferences.get("audio", {}) as Dictionary)["master"] = {"volume": 0.01, "muted": true}
	_check(store.load_preferences() == first_saved, "saved data should not alias the caller's mutable Dictionary", failures)

	var second_preferences := first_saved.duplicate(true)
	second_preferences["motion_mode"] = "full"
	second_preferences["ui_scale"] = 1.5
	second_preferences["visual_quality"] = "low"
	(second_preferences.get("audio", {}) as Dictionary)["music"] = {"volume": 0.2, "muted": true}
	_check(store.save_preferences(second_preferences), "a second valid save should rotate a known-good backup", failures)
	_check(store.load_preferences() == second_preferences, "the newest valid primary should load exactly", failures)
	_check(FileAccess.file_exists("%s.bak" % TEST_PRIMARY_PATH), "a second save should retain a recovery copy", failures)

	_check(_write_raw(TEST_PRIMARY_PATH, "{ definitely not valid json"), "test should be able to simulate a torn primary write", failures)
	var recovered: Dictionary = store.load_preferences()
	_check(recovered == first_saved, "a corrupt primary should recover the last known-good backup", failures)
	_check(
		store.last_load_recovered and store.last_recovery_source == "backup" and store.last_error.is_empty(),
		"backup recovery should be explicit without presenting a valid recovery as an error",
		failures,
	)

	for path: String in TEST_PATHS:
		_check(_write_raw(path, "not json"), "test should be able to corrupt %s" % path, failures)
	var fallback: Dictionary = store.load_preferences()
	_check(fallback == default_preferences, "wholly corrupt preference artifacts should fail closed to defaults", failures)
	_check(
		not store.last_error.is_empty() and not store.last_load_recovered,
		"unrecoverable preference corruption should be observable to the host",
		failures,
	)

	_check(store.delete_preferences(), "preference artifacts should be independently deletable", failures)
	var legacy_preferences := default_preferences.duplicate(true)
	legacy_preferences.erase("color_vision_mode")
	legacy_preferences.erase("pause_when_unfocused")
	(legacy_preferences.get("audio", {}) as Dictionary).erase("ambient")
	var legacy_envelope := {
		"format": PlayerPreferencesStoreScript.PREFERENCES_FORMAT,
		"schema_version": 1,
		"preferences": legacy_preferences,
		"metadata": {"saved_at_unix": 0, "save_revision": 3},
	}
	_check(_write_raw(TEST_PRIMARY_PATH, JSON.stringify(legacy_envelope)), "test should write a schema-one fixture", failures)
	var migrated_preferences := store.load_preferences()
	_check(
		String(migrated_preferences.get("color_vision_mode", "")) == "standard"
		and bool(migrated_preferences.get("pause_when_unfocused", false))
		and (migrated_preferences.get("audio", {}) as Dictionary).has("ambient")
		and PlayerPreferencesStoreScript.validate(migrated_preferences).is_empty(),
		"schema-one preferences should migrate through palette, ambience, and focus safety defaults",
		failures,
	)
	_check(store.delete_preferences(), "migrated preference fixture should be removable", failures)
	var future_envelope := {
		"format": PlayerPreferencesStoreScript.PREFERENCES_FORMAT,
		"schema_version": PlayerPreferencesStoreScript.CURRENT_SCHEMA_VERSION + 1,
		"preferences": default_preferences,
		"metadata": {"saved_at_unix": 0, "save_revision": 1},
	}
	_check(_write_raw(TEST_PRIMARY_PATH, JSON.stringify(future_envelope)), "test should write a future schema fixture", failures)
	_check(store.load_preferences() == default_preferences, "future preference schemas should never be interpreted as current data", failures)
	_check("newer than supported" in store.last_error, "future schema rejection should be diagnosable", failures)

	var unsafe_store = PlayerPreferencesStoreScript.new("../campaign_save.json")
	_check(not unsafe_store.save_preferences(default_preferences), "preference filenames must not escape user storage", failures)
	_check("safe filename" in unsafe_store.last_error, "unsafe filename rejection should explain the boundary", failures)

	_test_audio_application(failures)
	store.delete_preferences()
	if not failures.is_empty():
		for failure: String in failures:
			push_error("PLAYER_PREFERENCES_STORE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PLAYER_PREFERENCES_STORE_TEST_PASSED schema=v3 migration=v1+v2 color-vision=safe+symbols focus-pause=default-on validation=strict atomic=backup-recovery audio=5-bus preferences=campaign-independent")
	quit(0)


func _test_audio_application(failures: Array[String]) -> void:
	var original_buses := _snapshot_target_buses()
	var preferences: Dictionary = PlayerPreferencesStoreScript.defaults()
	preferences["audio"] = {
		"master": {"volume": 0.25, "muted": true},
		"sfx": {"volume": 0.0, "muted": false},
		"ui": {"volume": 0.5, "muted": true},
		"music": {"volume": 0.75, "muted": false},
		"ambient": {"volume": 0.35, "muted": true},
	}
	var apply_result: Dictionary = PlayerPreferencesStoreScript.apply_audio(preferences)
	_check(
		bool(apply_result.get("accepted", false))
		and (apply_result.get("applied", []) as Array).size() == 5,
		"apply_audio should report all five independent mix channels",
		failures,
	)
	var expected_volumes := {&"Master": 0.25, &"SFX": 0.0, &"UI": 0.5, &"Music": 0.75, &"Ambient": 0.35}
	var expected_mutes := {&"Master": true, &"SFX": false, &"UI": true, &"Music": false, &"Ambient": true}
	for bus_name: StringName in TARGET_BUS_NAMES:
		var bus_index := AudioServer.get_bus_index(bus_name)
		_check(bus_index >= 0, "%s audio bus should exist after apply_audio" % bus_name, failures)
		if bus_index < 0:
			continue
		var expected_linear := maxf(float(expected_volumes[bus_name]), 0.0001)
		_check(
			is_equal_approx(AudioServer.get_bus_volume_db(bus_index), linear_to_db(expected_linear)),
			"%s should receive its independent linear volume" % bus_name,
			failures,
		)
		_check(
			AudioServer.is_bus_mute(bus_index) == bool(expected_mutes[bus_name]),
			"%s should receive its independent mute state" % bus_name,
			failures,
		)
	_restore_target_buses(original_buses)


func _snapshot_target_buses() -> Dictionary:
	var snapshot: Dictionary = {}
	for bus_name: StringName in TARGET_BUS_NAMES:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			snapshot[String(bus_name)] = {"existed": false}
			continue
		snapshot[String(bus_name)] = {
			"existed": true,
			"volume_db": AudioServer.get_bus_volume_db(bus_index),
			"muted": AudioServer.is_bus_mute(bus_index),
			"send": AudioServer.get_bus_send(bus_index),
		}
	return snapshot


func _restore_target_buses(snapshot: Dictionary) -> void:
	# Restore retained buses first, then remove only buses introduced by this test.
	for bus_name: StringName in TARGET_BUS_NAMES:
		var saved := snapshot.get(String(bus_name), {}) as Dictionary
		if not bool(saved.get("existed", false)):
			continue
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			continue
		AudioServer.set_bus_volume_db(bus_index, float(saved.get("volume_db", 0.0)))
		AudioServer.set_bus_mute(bus_index, bool(saved.get("muted", false)))
		if bus_name != &"Master":
			AudioServer.set_bus_send(bus_index, StringName(saved.get("send", &"Master")))
	for target_index in range(TARGET_BUS_NAMES.size() - 1, -1, -1):
		var bus_name := TARGET_BUS_NAMES[target_index]
		var saved := snapshot.get(String(bus_name), {}) as Dictionary
		if bool(saved.get("existed", false)):
			continue
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index > 0:
			AudioServer.remove_bus(bus_index)


func _write_raw(path: String, contents: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(contents)
	file.flush()
	var result := file.get_error() == OK
	file.close()
	return result


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
