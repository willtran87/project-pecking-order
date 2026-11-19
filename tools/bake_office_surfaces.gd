extends SceneTree

const SurfaceFinish := preload("res://features/office/office_surface_finish.gd")


func _init() -> void:
	var textures: Dictionary = {}
	for kind in [&"wood", &"tile", &"linen"]:
		textures[kind] = SurfaceFinish._generate_texture(kind)
	var bank := Resource.new()
	bank.set_meta("textures", textures)
	DirAccess.make_dir_recursive_absolute("res://assets/materials")
	var error := ResourceSaver.save(bank, SurfaceFinish.TEXTURE_BANK_PATH)
	if error != OK:
		push_error("Office surface texture bake failed: %s" % error_string(error))
		quit(1)
		return
	print("OFFICE_SURFACES_BAKED textures=3 size=128 mipmaps=preserved")
	quit()
