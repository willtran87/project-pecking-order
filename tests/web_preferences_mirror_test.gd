extends SceneTree

const WebPreferencesMirrorScript := preload("res://core/settings/web_preferences_mirror.gd")
const PlayerPreferencesStoreScript := preload("res://core/settings/player_preferences_store.gd")

var _failures := 0


func _init() -> void:
	var mirror = WebPreferencesMirrorScript.new()
	var preferences := PlayerPreferencesStoreScript.defaults()
	preferences["color_vision_mode"] = "color_blind_safe"
	var payload: String = mirror.encode(preferences)
	_expect(not payload.is_empty(), "valid preferences encode")
	var encoded_root := JSON.parse_string(payload) as Dictionary
	_expect(
		String(encoded_root.get("format", "")) == WebPreferencesMirrorScript.MIRROR_FORMAT
		and int(encoded_root.get("schema_version", -1)) == PlayerPreferencesStoreScript.CURRENT_SCHEMA_VERSION,
		"encoded preferences use the current versioned mirror envelope",
	)
	_expect(mirror.decode(payload) == preferences, "valid preferences round-trip exactly")
	var legacy_v2 := preferences.duplicate(true)
	legacy_v2.erase("notice_level")
	legacy_v2.erase("notice_duration")
	legacy_v2.erase("effect_level")
	legacy_v2.erase("haptics_enabled")
	legacy_v2.erase("animation_speed")
	legacy_v2.erase("tooltip_delay")
	legacy_v2.erase("pause_when_unfocused")
	var legacy_audio := legacy_v2.get("audio", {}) as Dictionary
	legacy_audio.erase("ambient")
	legacy_audio["music"] = {"volume": 0.21, "muted": true}
	var migrated_v2 := mirror.decode(JSON.stringify(legacy_v2))
	_expect(
		bool(migrated_v2.get("pause_when_unfocused", false))
		and (migrated_v2.get("audio", {}) as Dictionary).get("ambient", {}) == legacy_audio.get("music", {}),
		"unversioned schema-two mirrors preserve the combined music and ambience setting",
	)
	var legacy_v3 := preferences.duplicate(true)
	legacy_v3.erase("notice_level")
	legacy_v3.erase("notice_duration")
	legacy_v3.erase("effect_level")
	legacy_v3.erase("haptics_enabled")
	legacy_v3.erase("animation_speed")
	legacy_v3.erase("tooltip_delay")
	var legacy_v3_payload := JSON.stringify({
		"format": WebPreferencesMirrorScript.MIRROR_FORMAT,
		"schema_version": 3,
		"preferences": legacy_v3,
	})
	var migrated_v3 := mirror.decode(legacy_v3_payload)
	_expect(
		String(migrated_v3.get("notice_level", "")) == "all",
		"schema-three mirrors should gain the non-interrupting-compatible all-notices default",
	)
	var legacy_v4 := preferences.duplicate(true)
	legacy_v4.erase("notice_duration")
	legacy_v4.erase("effect_level")
	legacy_v4.erase("haptics_enabled")
	legacy_v4.erase("animation_speed")
	legacy_v4.erase("tooltip_delay")
	var legacy_v4_payload := JSON.stringify({
		"format": WebPreferencesMirrorScript.MIRROR_FORMAT,
		"schema_version": 4,
		"preferences": legacy_v4,
	})
	var migrated_v4 := mirror.decode(legacy_v4_payload)
	_expect(
		String(migrated_v4.get("notice_duration", "")) == "standard"
		and String(migrated_v4.get("effect_level", "")) == "full"
		and bool(migrated_v4.get("haptics_enabled", false)),
		"schema-four mirrors should gain safe feedback pacing and supported-device haptics defaults",
	)
	var legacy_v5 := preferences.duplicate(true)
	legacy_v5.erase("animation_speed")
	legacy_v5.erase("tooltip_delay")
	var legacy_v5_payload := JSON.stringify({
		"format": WebPreferencesMirrorScript.MIRROR_FORMAT,
		"schema_version": 5,
		"preferences": legacy_v5,
	})
	var migrated_v5 := mirror.decode(legacy_v5_payload)
	_expect(
		String(migrated_v5.get("animation_speed", "")) == "standard"
		and String(migrated_v5.get("tooltip_delay", "")) == "standard",
		"schema-five mirrors should gain independent standard presentation timing defaults",
	)
	_expect(mirror.decode("[]").is_empty(), "array roots are rejected")
	_expect(not mirror.last_error.is_empty(), "invalid roots disclose an error")
	_expect(mirror.decode("{broken").is_empty(), "malformed JSON is rejected")
	var invalid := preferences.duplicate(true)
	invalid["unsupported"] = true
	_expect(mirror.encode(invalid).is_empty(), "unsupported fields are rejected")
	_expect(
		mirror.decode("\"%s\"" % "x".repeat(WebPreferencesMirrorScript.MAX_PAYLOAD_BYTES)).is_empty(),
		"oversized payloads are rejected",
	)
	var future_payload := JSON.stringify({
		"format": WebPreferencesMirrorScript.MIRROR_FORMAT,
		"schema_version": PlayerPreferencesStoreScript.CURRENT_SCHEMA_VERSION + 1,
		"preferences": preferences,
	})
	_expect(mirror.decode(future_payload).is_empty(), "future mirror schemas are rejected")
	if _failures == 0:
		print("WEB_PREFERENCES_MIRROR_TEST_PASSED assertions=13 envelope=versioned legacy=v2-music-ambience-preserved+v3-notices-defaulted+v4-feedback-defaulted+v5-presentation-timing-defaulted")
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("web_preferences_mirror_test failed: %s" % message)
