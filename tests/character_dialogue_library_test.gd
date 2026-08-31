extends SceneTree

const Library := preload("res://features/office/character_dialogue_library.gd")

const EXPECTED_SPEAKERS := 16
const EXPECTED_THEME_BUCKETS := 70
const EXPECTED_UNIQUE_LINES := 293
const MINIMUM_LINES_PER_BUCKET := 3


func _init() -> void:
	var failures: Array[String] = []
	var seen_lines := {}
	var theme_bucket_count := 0
	var authored_line_count := 0

	_check(
		Library.VOICE_POOLS.size() == EXPECTED_SPEAKERS,
		"voice library should cover all %d chickens" % EXPECTED_SPEAKERS,
		failures,
	)
	for speaker_value: Variant in Library.SPEAKERS:
		var speaker_id := StringName(String(speaker_value))
		_check(
			Library.VOICE_POOLS.has(speaker_id),
			"%s should have an authored voice pool" % String(speaker_id),
			failures,
		)

	for speaker_value: Variant in Library.VOICE_POOLS:
		var speaker_id := StringName(String(speaker_value))
		var voice := Library.VOICE_POOLS.get(speaker_id, {}) as Dictionary
		for theme_value: Variant in voice:
			var theme_id := StringName(String(theme_value))
			var lines := voice.get(theme_id, []) as Array
			theme_bucket_count += 1
			_check(
				lines.size() >= MINIMUM_LINES_PER_BUCKET,
				"%s/%s should have at least %d lines" % [
					String(speaker_id),
					String(theme_id),
					MINIMUM_LINES_PER_BUCKET,
				],
				failures,
			)
			for line_value: Variant in lines:
				var line := String(line_value).strip_edges()
				authored_line_count += 1
				_check(
					line.length() >= 24,
					"%s/%s contains an empty or under-authored line" % [
						String(speaker_id),
						String(theme_id),
					],
					failures,
				)
				_check(
					not seen_lines.has(line),
					"duplicate dialogue line in %s/%s: %s" % [
						String(speaker_id),
						String(theme_id),
						line,
					],
					failures,
				)
				seen_lines[line] = "%s/%s" % [String(speaker_id), String(theme_id)]

	_check(
		theme_bucket_count == EXPECTED_THEME_BUCKETS,
		"voice library should keep %d speaker/theme buckets" % EXPECTED_THEME_BUCKETS,
		failures,
	)
	_check(
		authored_line_count == EXPECTED_UNIQUE_LINES,
		"voice library should contain exactly %d authored lines" % EXPECTED_UNIQUE_LINES,
		failures,
	)
	_check(
		seen_lines.size() == EXPECTED_UNIQUE_LINES,
		"all %d authored lines should be globally unique" % EXPECTED_UNIQUE_LINES,
		failures,
	)

	if not failures.is_empty():
		for failure in failures:
			push_error("CHARACTER_DIALOGUE_LIBRARY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print(
		"CHARACTER_DIALOGUE_LIBRARY_TEST_PASSED speakers=%d themes=%d unique_lines=%d min_bucket=%d"
		% [
			EXPECTED_SPEAKERS,
			EXPECTED_THEME_BUCKETS,
			EXPECTED_UNIQUE_LINES,
			MINIMUM_LINES_PER_BUCKET,
		]
	)
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
