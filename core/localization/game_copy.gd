class_name GameCopy
extends RefCounted

## Stable translation boundary for the primary player journey. English remains
## the authored shipping locale; adding another CSV column can now translate the
## intake, replay setup, final legacy action, and their semantic equivalents.

static func text(key: StringName, fallback: String) -> String:
	var translated := TranslationServer.translate(String(key))
	return fallback if translated.is_empty() or translated == String(key) else translated
