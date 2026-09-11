extends SceneTree

const PORTRAITS := {
	"mabel": "res://assets/npcs/mabel/portraits/mabel_portrait_anxious.png",
	"pip": "res://assets/npcs/pip/portraits/pip_portrait_skeptical.png",
	"henrietta": "res://assets/npcs/henrietta/portraits/henrietta_portrait_anxious.png",
	"dot": "res://assets/npcs/dot/portraits/dot_portrait_knowing.png",
	"agnes": "res://assets/npcs/agnes/portraits/agnes_portrait_methodical.png",
	"beatrice": "res://assets/npcs/beatrice/portraits/beatrice_portrait_gentle-rebel.png",
	"cornelius": "res://assets/npcs/cornelius-claimwell/portraits/cornelius-claimwell_portrait_weary.png",
	"bramwell": "res://assets/npcs/bramwell-beakley/portraits/bramwell-beakley_portrait_quota.png",
	"prudence": "res://assets/npcs/prudence-peckworth/portraits/prudence-peckworth_portrait_compliance.png",
	"clover": "res://assets/npcs/clover-crowsby/portraits/clover-crowsby_portrait_culture.png",
	"pivot": "res://assets/npcs/pivot-strutters/portraits/pivot-strutters_portrait_reorg.png",
	"byte": "res://assets/npcs/byte-bantam/portraits/byte-bantam_portrait_automation.png",
	"intern_lottie": "res://assets/npcs/intern-lottie-ledger/portraits/lottie-ledger_portrait_eager.png",
	"intern_chip": "res://assets/npcs/intern-chip-chirper/portraits/chip-chirper_portrait_optimistic.png",
	"intern_marigold": "res://assets/npcs/intern-marigold-memo/portraits/marigold-memo_portrait_helpful.png",
	"intern_tilly": "res://assets/npcs/intern-tilly-tabs/portraits/tilly-tabs_portrait_tech-hopeful.png",
}


func _init() -> void:
	var failures: Array[String] = []
	for character_id: String in PORTRAITS:
		var path := String(PORTRAITS[character_id])
		var texture := load(path) as Texture2D
		var image := Image.new()
		var source_bytes := FileAccess.get_file_as_bytes(path)
		if not source_bytes.is_empty():
			image.load_png_from_buffer(source_bytes)
		_check(not image.is_empty(), "%s portrait should load" % character_id, failures)
		if image.is_empty():
			continue
		_check(
			image.get_size() == Vector2i(1024, 1024),
			"%s portrait should keep the approved 1024x1024 cutout contract" % character_id,
			failures,
		)
		_check(
			texture != null and texture.get_size().x <= 512.0 and texture.get_size().y <= 512.0,
			"%s runtime import should stay inside the 512px Web texture budget" % character_id,
			failures,
		)
		for corner in [
			Vector2i(0, 0),
			Vector2i(image.get_width() - 1, 0),
			Vector2i(0, image.get_height() - 1),
			Vector2i(image.get_width() - 1, image.get_height() - 1),
		]:
			_check(
				image.get_pixelv(corner).a <= 0.01,
				"%s portrait corners should remain transparent" % character_id,
				failures,
			)
		var visible_samples := 0
		var green_edge_samples := 0
		for y in range(0, image.get_height(), 8):
			for x in range(0, image.get_width(), 8):
				var pixel := image.get_pixel(x, y)
				if pixel.a <= 0.08:
					continue
				visible_samples += 1
				if pixel.g > pixel.r * 1.55 and pixel.g > pixel.b * 1.35 and pixel.g > 0.48:
					green_edge_samples += 1
		_check(
			visible_samples > 2500,
			"%s portrait should contain a substantial connected cutout" % character_id,
			failures,
		)
		_check(
			green_edge_samples == 0,
			"%s portrait should not retain chroma-key contamination" % character_id,
			failures,
		)

	if not failures.is_empty():
		for failure in failures:
			push_error("CHARACTER_DIALOGUE_PORTRAIT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CHARACTER_DIALOGUE_PORTRAIT_TEST_PASSED count=16 source=1024 runtime<=512 alpha=clean chroma=clean status=source-reference-pass")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
