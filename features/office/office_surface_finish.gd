class_name OfficeSurfaceFinish
extends RefCounted

## Small, shared, mipmapped finishes for the Compatibility renderer. No runtime
## updates, transparent overlays, extra lights, or changes to imported resources.
const TEXTURE_BANK_PATH := "res://assets/materials/office_surface_textures.res"
static var _texture_bank_checked := false
static var _textures: Dictionary = {}
static var _materials: Dictionary = {}


static func material(kind: StringName, tint: Color, scale: float = 1.0) -> StandardMaterial3D:
	# Clothing shares the baked linen bank instead of generating another texture.
	if kind == &"cloth":
		kind = &"linen"
	var key := "%s_%s_%.2f" % [kind, tint.to_html(), scale]
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var result := StandardMaterial3D.new()
	result.albedo_color = tint
	result.albedo_texture = _texture(kind)
	result.roughness = 0.68 if kind == &"wood" else 0.96
	result.metallic = 0.0
	result.uv1_triplanar = true
	result.uv1_triplanar_sharpness = 8.0
	result.uv1_scale = Vector3.ONE * scale
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_materials[key] = result
	return result


static func _texture(kind: StringName) -> Texture2D:
	if not _texture_bank_checked:
		_texture_bank_checked = true
		if ResourceLoader.exists(TEXTURE_BANK_PATH):
			var bank := load(TEXTURE_BANK_PATH) as Resource
			var textures: Dictionary = bank.get_meta("textures", {}) if bank != null else {}
			for key in [&"wood", &"tile", &"linen"]:
				if textures.get(key) is Texture2D:
					_textures[key] = textures[key]
	if not _textures.has(kind):
		_textures[kind] = _generate_texture(kind)
	return _textures[kind] as Texture2D


# Retained for the offline baker and as a safe fallback in source checkouts.
static func _generate_texture(kind: StringName) -> Texture2D:
	const SIZE := 128
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			# Integer hash is repeatable without consuming the simulation's RNG.
			var grain := float((x * 73 + y * 151 + x * y * 17) % 29) / 28.0
			var value := 0.94 + (grain - 0.5) * 0.045
			if kind == &"wood":
				var wave := sin(float(x) * TAU / 128.0) * 1.8
				var rings := sin(float(y) * TAU / 16.0 + wave)
				value = 0.88 + rings * 0.065 + (grain - 0.5) * 0.025
			elif kind == &"tile":
				var tile_x := x / 64
				var tile_y := y / 64
				value = 0.90 + float((tile_x + tile_y) % 2) * 0.07 + (grain - 0.5) * 0.025
				if x % 64 < 1 or y % 64 < 1:
					value *= 0.77
			else:
				# Broad woven ribs survive overview distance; fine threads fade via mipmaps.
				value -= 0.055 if y % 16 < 3 else 0.0
				value += 0.02 if (x + y) % 4 < 2 else -0.02
			image.set_pixel(x, y, Color(value, value, value))
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	return texture
