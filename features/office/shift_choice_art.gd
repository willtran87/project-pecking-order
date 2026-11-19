class_name ShiftChoiceArt
extends RefCounted

## Shared illustrated badges; imported fonts/emoji are not needed for tool identity.
const MARKS := {
	"relay_bell": '<path d="M35 79h58M42 77V64a22 22 0 0 1 44 0v13M64 35v7M58 88h12"/><path d="M28 57q-5 10 0 20M100 57q5 10 0 20"/>',
	"shell_guard": '<circle cx="58" cy="56" r="25"/><path d="m77 77 20 20" stroke-width="10"/><path d="M58 40c-15 12-15 30 0 30s15-18 0-30Z" fill="#f7e8b4" stroke-width="2"/>',
	"team_kettle": '<path d="M35 66h48v12q0 15-24 15T35 78ZM83 67q22-6 22 7T84 85M32 59h55M54 51q-9-8 0-16M69 51q-9-8 0-16"/>',
	"fast": '<path d="m69 27-31 43h23l-5 31 35-45H67Z" fill="#e8bc65" stroke-width="3"/>',
	"safe": '<path d="m64 27 29 12v26q0 23-29 37-29-14-29-37V39Z"/><path d="m49 63 10 10 22-24"/>',
	"flock": '<path d="M64 94 35 67C13 40 43 21 64 45c21-24 51-5 29 22Z" fill="#d5a2ba" stroke-width="3"/>',
	"fund": '<ellipse cx="64" cy="47" rx="28" ry="13"/><path d="M36 47v30c0 17 56 17 56 0V47M36 62c0 17 56 17 56 0"/><path d="M60 40h8M64 37v20" stroke-width="3"/>',
	"mastery": '<path d="m47 72-7 29 24-12 24 12-7-29" fill="#ab93c8"/><circle cx="64" cy="53" r="27"/><path d="m64 35 5 12 14 1-11 9 3 14-11-7-11 7 3-14-11-9 14-1Z" fill="#f7e8b4" stroke-width="2"/>',
	"recovery": '<path d="M64 96V59M64 76Q27 79 32 43q34-4 32 33ZM64 63q-2-33 32-32 5 34-32 32Z" fill="#85b8a2" stroke-width="3"/>',
}
static var _cache: Dictionary = {}


static func badge(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id] as Texture2D
	var mark := String(MARKS.get(id, MARKS.safe))
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><defs><linearGradient id="bg" x2="0.8" y2="1"><stop stop-color="#3e5964"/><stop offset="1" stop-color="#192d3b"/></linearGradient></defs><rect x="4" y="7" width="120" height="118" rx="28" fill="#101d28"/><rect x="4" y="3" width="120" height="118" rx="28" fill="url(#bg)" stroke="#71878a" stroke-width="2"/><path d="M25 15h77" stroke="#a7b4a5" stroke-opacity=".35"/><g fill="none" stroke="#f4d58e" stroke-width="5" stroke-linecap="round" stroke-linejoin="round">%s</g></svg>' % mark
	var image := Image.new()
	if image.load_svg_from_string(svg) != OK:
		return null
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_cache[id] = texture
	return texture
