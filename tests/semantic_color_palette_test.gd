extends SceneTree

const Palette := preload("res://core/settings/semantic_color_palette.gd")


func _init() -> void:
	var failures: Array[String] = []
	_check(Palette.normalize_mode("unknown") == &"standard", "unknown modes should fail safely to standard", failures)
	_check(Palette.normalize_mode("color_blind_safe") == &"color_blind_safe", "safe mode should retain its canonical ID", failures)

	var lanes: Array[StringName] = [&"nest_damage", &"predator_loss", &"appeals"]
	var qualities: Array[StringName] = [&"sound", &"golden", &"cracked"]
	_check_pairwise_separation(lanes, true, failures)
	_check_pairwise_separation(qualities, false, failures)

	_check(Palette.lane_marker(&"nest_damage", &"standard").is_empty(), "standard presentation should preserve existing labels", failures)
	_check(Palette.lane_marker(&"nest_damage", &"color_blind_safe") == "[N]", "safe Nest lane should carry a redundant marker", failures)
	_check(Palette.lane_marker(&"predator_loss", &"color_blind_safe") == "[P]", "safe Predator lane should carry a redundant marker", failures)
	_check(Palette.lane_marker(&"appeals", &"color_blind_safe") == "[A]", "safe Appeals lane should carry a redundant marker", failures)
	_check(Palette.quality_marker(&"sound", &"color_blind_safe") == "[OK]", "safe sound eggs should carry a redundant marker", failures)
	_check(Palette.quality_marker(&"golden", &"color_blind_safe") == "[*]", "safe golden eggs should carry a redundant marker", failures)
	_check(Palette.quality_marker(&"cracked", &"color_blind_safe") == "[X]", "safe cracked eggs should carry a redundant marker", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("SEMANTIC_COLOR_PALETTE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SEMANTIC_COLOR_PALETTE_TEST_PASSED modes=2 lanes=3 qualities=3 safe=high-separation+redundant-symbols")
	quit(0)


func _check_pairwise_separation(ids: Array[StringName], lanes: bool, failures: Array[String]) -> void:
	for left_index in ids.size():
		for right_index in range(left_index + 1, ids.size()):
			var left := (
				Palette.lane_color(ids[left_index], &"color_blind_safe")
				if lanes else
				Palette.quality_color(ids[left_index], &"color_blind_safe")
			)
			var right := (
				Palette.lane_color(ids[right_index], &"color_blind_safe")
				if lanes else
				Palette.quality_color(ids[right_index], &"color_blind_safe")
			)
			var distance := Vector3(left.r, left.g, left.b).distance_to(Vector3(right.r, right.g, right.b))
			_check(
				distance >= 0.48,
				"%s and %s should remain strongly separated in the safe palette (%.3f)" % [ids[left_index], ids[right_index], distance],
				failures,
			)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
