extends SceneTree

const SurfaceFinish := preload("res://features/office/office_surface_finish.gd")


func _init() -> void:
	assert(ResourceLoader.exists(SurfaceFinish.TEXTURE_BANK_PATH))
	for kind in [&"wood", &"tile", &"linen"]:
		var baked := SurfaceFinish._texture(kind)
		var generated := SurfaceFinish._generate_texture(kind)
		assert(baked.get_image().get_data() == generated.get_image().get_data(), "Baked pixels and mipmaps must be byte-identical")
		assert(baked.get_image().has_mipmaps())
		assert(baked == SurfaceFinish._texture(kind), "Repeated surfaces must share their texture")
	assert(SurfaceFinish.material(&"wood", Color.WHITE) == SurfaceFinish.material(&"wood", Color.WHITE))
	print("OFFICE_SURFACE_BANK_TEST_PASSED pixels=identical mipmaps=identical resources=shared")
	quit()
