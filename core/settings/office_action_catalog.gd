class_name OfficeActionCatalog
extends RefCounted


## Runtime-owned semantic input contract for the management office.
##
## The project currently builds its scene in code, so this catalog can install
## defaults without requiring an editor-authored InputMap. Existing non-empty
## actions are preserved by default; this is particularly important for the
## legacy `peck_assist` action that Office may already have registered.

const PECK_ASSIST: StringName = &"peck_assist"
const MAX_EVENTS_PER_ACTION := 4
const DEFAULT_DEADZONE := 0.5

const ACTION_IDS: Array[StringName] = [
	&"pause_simulation",
	&"speed_normal",
	&"speed_fast",
	&"speed_ultra",
	PECK_ASSIST,
	&"fund_feed_party",
	&"toggle_overtime",
	&"toggle_flockwatch",
	&"cycle_hen",
	&"camera_pan_left",
	&"camera_pan_right",
	&"camera_pan_up",
	&"camera_pan_down",
	&"camera_zoom_in",
	&"camera_zoom_out",
	&"office_overview",
	&"open_settings",
]

# Conflict groups reflect mutually active contexts. Camera and global actions
# may intentionally share a physical input with a floor action in future, while
# two actions available on the live floor should never collide silently.
const DEFINITIONS := {
	&"pause_simulation": {
		"display_name": "Pause / Resume",
		"group": "floor",
		"bindings": [
			{"type": "key", "physical_keycode": KEY_SPACE},
			{"type": "joypad_button", "button_index": JOY_BUTTON_START},
		],
	},
	&"speed_normal": {
		"display_name": "Normal Speed",
		"group": "floor",
		"bindings": [
			{"type": "key", "physical_keycode": KEY_1},
			{"type": "joypad_button", "button_index": JOY_BUTTON_DPAD_LEFT},
		],
	},
	&"speed_fast": {
		"display_name": "Fast Speed",
		"group": "floor",
		"bindings": [
			{"type": "key", "physical_keycode": KEY_2},
			{"type": "joypad_button", "button_index": JOY_BUTTON_DPAD_DOWN},
		],
	},
	&"speed_ultra": {
		"display_name": "Ultra Speed",
		"group": "floor",
		"bindings": [
			{"type": "key", "physical_keycode": KEY_3},
			{"type": "joypad_button", "button_index": JOY_BUTTON_DPAD_RIGHT},
		],
	},
	PECK_ASSIST: {
		"display_name": "Priority Peck",
		"group": "floor",
		"bindings": [
			{"type": "key", "physical_keycode": KEY_E},
			{"type": "joypad_button", "button_index": JOY_BUTTON_A},
		],
	},
	&"fund_feed_party": {
		"display_name": "Fund Feed Party",
		"group": "floor",
		"bindings": [
			{"type": "key", "physical_keycode": KEY_P},
			{"type": "joypad_button", "button_index": JOY_BUTTON_Y},
		],
	},
	&"toggle_overtime": {
		"display_name": "Toggle After-Hours",
		"group": "floor",
		"bindings": [
			{"type": "key", "physical_keycode": KEY_O},
			{"type": "joypad_button", "button_index": JOY_BUTTON_X},
		],
	},
	&"toggle_flockwatch": {
		"display_name": "Open Flockwatch",
		"group": "floor",
		"bindings": [
			{"type": "key", "physical_keycode": KEY_V},
			{"type": "joypad_button", "button_index": JOY_BUTTON_BACK},
		],
	},
	&"cycle_hen": {
		"display_name": "Cycle Hen",
		"group": "camera",
		"bindings": [
			{"type": "key", "keycode": KEY_TAB},
			{"type": "joypad_button", "button_index": JOY_BUTTON_RIGHT_SHOULDER},
		],
	},
	&"camera_pan_left": {
		"display_name": "Pan Camera Left",
		"group": "camera",
		"bindings": [
			{"type": "key", "physical_keycode": KEY_A},
			{"type": "key", "physical_keycode": KEY_LEFT},
		],
	},
	&"camera_pan_right": {
		"display_name": "Pan Camera Right",
		"group": "camera",
		"bindings": [
			{"type": "key", "physical_keycode": KEY_D},
			{"type": "key", "physical_keycode": KEY_RIGHT},
		],
	},
	&"camera_pan_up": {
		"display_name": "Pan Camera Up",
		"group": "camera",
		"bindings": [
			{"type": "key", "physical_keycode": KEY_W},
			{"type": "key", "physical_keycode": KEY_UP},
		],
	},
	&"camera_pan_down": {
		"display_name": "Pan Camera Down",
		"group": "camera",
		"bindings": [
			{"type": "key", "physical_keycode": KEY_S},
			{"type": "key", "physical_keycode": KEY_DOWN},
		],
	},
	&"camera_zoom_in": {
		"display_name": "Zoom Camera In",
		"group": "camera",
		"bindings": [
			{"type": "key", "physical_keycode": KEY_EQUAL},
			{"type": "key", "physical_keycode": KEY_KP_ADD},
		],
	},
	&"camera_zoom_out": {
		"display_name": "Zoom Camera Out",
		"group": "camera",
		"bindings": [
			{"type": "key", "physical_keycode": KEY_MINUS},
			{"type": "key", "physical_keycode": KEY_KP_SUBTRACT},
		],
	},
	&"office_overview": {
		"display_name": "Return to Overview",
		"group": "camera",
		"bindings": [
			{"type": "key", "keycode": KEY_ESCAPE},
			{"type": "joypad_button", "button_index": JOY_BUTTON_B},
		],
	},
	&"open_settings": {
		"display_name": "Open Settings",
		"group": "global",
		"bindings": [
			{"type": "key", "keycode": KEY_F10},
			{"type": "joypad_button", "button_index": JOY_BUTTON_GUIDE},
		],
	},
}


static func managed_actions() -> Array[StringName]:
	return ACTION_IDS.duplicate()


static func is_managed(action: StringName) -> bool:
	return DEFINITIONS.has(action)


static func display_name(action: StringName) -> String:
	var definition := DEFINITIONS.get(action, {}) as Dictionary
	return String(definition.get("display_name", String(action).replace("_", " ").capitalize()))


## Returns a concise, device-readable label for the action's current runtime
## bindings (for example `E / A`, `Tab / RB`, or `1 / D-pad Left`).
static func binding_label(action: StringName) -> String:
	if not is_managed(action):
		return ""
	install_defaults()
	var labels: Array[String] = []
	for event: InputEvent in InputMap.action_get_events(action):
		var label := _event_label(event)
		if not label.is_empty() and label not in labels:
			labels.append(label)
	return "Unbound" if labels.is_empty() else " / ".join(labels)


static func install_defaults(preserve_existing: bool = true) -> Dictionary:
	var installed: Array[String] = []
	var preserved: Array[String] = []
	var reset: Array[String] = []
	var errors: Array[String] = []
	for action in ACTION_IDS:
		var existed := InputMap.has_action(action)
		if not existed:
			InputMap.add_action(action, DEFAULT_DEADZONE)
		var existing_events := InputMap.action_get_events(action)
		if existed and preserve_existing and not existing_events.is_empty():
			preserved.append(String(action))
			continue
		InputMap.action_erase_events(action)
		var descriptors := _default_descriptors(action)
		for descriptor_value in descriptors:
			var event := _event_from_descriptor(descriptor_value as Dictionary)
			if event == null:
				errors.append("Invalid built-in binding for %s." % action)
				continue
			InputMap.action_add_event(action, event)
		if existed:
			reset.append(String(action))
		else:
			installed.append(String(action))
	return {
		"accepted": errors.is_empty(),
		"installed": installed,
		"preserved": preserved,
		"reset": reset,
		"errors": errors,
	}


## Applies a partial JSON-safe binding map transactionally. Missing actions are
## preserved unless `reset_missing` is true. Conflicts are rejected before the
## InputMap is mutated, and every managed action must retain at least one input.
static func apply_bindings(
	bindings: Dictionary,
	reset_missing: bool = false,
	allow_conflicts: bool = false,
) -> Dictionary:
	var validation := validate_bindings(bindings)
	if not bool(validation.get("valid", false)):
		return {
			"accepted": false,
			"reason": String(validation.get("error", "Invalid input bindings.")),
			"conflicts": [],
			"applied": [],
		}
	var normalized := validation.get("bindings", {}) as Dictionary
	install_defaults()

	var candidates: Dictionary = {}
	for action in ACTION_IDS:
		var action_key := String(action)
		if normalized.has(action_key):
			candidates[action_key] = (normalized[action_key] as Array).duplicate(true)
		elif reset_missing:
			candidates[action_key] = _default_descriptors(action)
		else:
			candidates[action_key] = _descriptors_for_events(InputMap.action_get_events(action))

	var conflicts := _binding_conflicts(candidates)
	if not allow_conflicts and not conflicts.is_empty():
		return {
			"accepted": false,
			"reason": "One or more bindings conflict in the same input context.",
			"conflicts": conflicts,
			"applied": [],
		}

	var applied: Array[String] = []
	for action in ACTION_IDS:
		var action_key := String(action)
		if not normalized.has(action_key) and not reset_missing:
			continue
		InputMap.action_erase_events(action)
		for descriptor_value in candidates[action_key] as Array:
			InputMap.action_add_event(action, _event_from_descriptor(descriptor_value as Dictionary))
		applied.append(action_key)
	return {
		"accepted": true,
		"reason": "",
		"conflicts": conflicts,
		"applied": applied,
	}


## Convenience API for a settings UI that has captured live InputEvents.
static func rebind_action(
	action: StringName,
	events: Array,
	allow_conflicts: bool = false,
) -> Dictionary:
	if not is_managed(action):
		return {"accepted": false, "reason": "Unknown Office action: %s" % action, "conflicts": [], "applied": []}
	var descriptors: Array = []
	for event_value in events:
		if not event_value is InputEvent:
			return {"accepted": false, "reason": "Bindings must be InputEvents.", "conflicts": [], "applied": []}
		var descriptor := event_to_dictionary(event_value as InputEvent)
		if descriptor.is_empty():
			return {"accepted": false, "reason": "Unsupported input event type.", "conflicts": [], "applied": []}
		descriptors.append(descriptor)
	return apply_bindings({String(action): descriptors}, false, allow_conflicts)


static func reset_action(action: StringName) -> bool:
	if not is_managed(action):
		return false
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEFAULT_DEADZONE)
	InputMap.action_erase_events(action)
	for descriptor_value in _default_descriptors(action):
		InputMap.action_add_event(action, _event_from_descriptor(descriptor_value as Dictionary))
	return true


static func reset_all() -> Dictionary:
	return apply_bindings(default_bindings(), true, true)


static func default_bindings() -> Dictionary:
	var result: Dictionary = {}
	for action in ACTION_IDS:
		result[String(action)] = _default_descriptors(action)
	return result


static func export_bindings() -> Dictionary:
	install_defaults()
	var result: Dictionary = {}
	for action in ACTION_IDS:
		result[String(action)] = _descriptors_for_events(InputMap.action_get_events(action))
	return result


## Validates and canonicalizes a partial serialized binding map without touching
## InputMap. This is also used by the preferences store for untrusted JSON.
static func validate_bindings(bindings: Dictionary) -> Dictionary:
	if bindings.size() > ACTION_IDS.size():
		return {"valid": false, "error": "Input binding map has too many actions.", "bindings": {}}
	var normalized: Dictionary = {}
	for key_value in bindings:
		if typeof(key_value) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "error": "Input action IDs must be strings.", "bindings": {}}
		var action := StringName(String(key_value))
		var action_key := String(action)
		if not is_managed(action):
			return {"valid": false, "error": "Unknown Office action: %s" % action_key, "bindings": {}}
		if normalized.has(action_key):
			return {"valid": false, "error": "Duplicate Office action: %s" % action_key, "bindings": {}}
		var events_value: Variant = bindings[key_value]
		if not events_value is Array:
			return {"valid": false, "error": "%s bindings must be an Array." % action_key, "bindings": {}}
		var events := events_value as Array
		if events.is_empty() or events.size() > MAX_EVENTS_PER_ACTION:
			return {"valid": false, "error": "%s must have 1-%d bindings." % [action_key, MAX_EVENTS_PER_ACTION], "bindings": {}}
		var normalized_events: Array = []
		var fingerprints: Dictionary[String, bool] = {}
		for descriptor_value in events:
			if not descriptor_value is Dictionary:
				return {"valid": false, "error": "%s contains a non-Dictionary binding." % action_key, "bindings": {}}
			var descriptor_result := _normalize_descriptor(descriptor_value as Dictionary)
			if not bool(descriptor_result.get("valid", false)):
				return {
					"valid": false,
					"error": "%s: %s" % [action_key, String(descriptor_result.get("error", "invalid binding"))],
					"bindings": {},
				}
			var descriptor := descriptor_result.get("descriptor", {}) as Dictionary
			var fingerprint := _descriptor_fingerprint(descriptor)
			if fingerprints.has(fingerprint):
				return {"valid": false, "error": "%s contains a duplicate binding." % action_key, "bindings": {}}
			fingerprints[fingerprint] = true
			normalized_events.append(descriptor)
		normalized[action_key] = normalized_events
	return {"valid": true, "error": "", "bindings": normalized}


static func event_to_dictionary(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.keycode == 0 and key.physical_keycode == 0:
			return {}
		return {
			"type": "key",
			"keycode": int(key.keycode),
			"physical_keycode": int(key.physical_keycode),
			"shift": key.shift_pressed,
			"ctrl": key.ctrl_pressed,
			"alt": key.alt_pressed,
			"meta": key.meta_pressed,
		}
	if event is InputEventJoypadButton:
		var joy := event as InputEventJoypadButton
		return {
			"type": "joypad_button",
			"button_index": int(joy.button_index),
			"device": joy.device,
		}
	return {}


static func _default_descriptors(action: StringName) -> Array:
	var definition := DEFINITIONS.get(action, {}) as Dictionary
	return (definition.get("bindings", []) as Array).duplicate(true)


static func _descriptors_for_events(events: Array[InputEvent]) -> Array:
	var descriptors: Array = []
	for event in events:
		var descriptor := event_to_dictionary(event)
		if not descriptor.is_empty():
			descriptors.append(descriptor)
	return descriptors


static func _event_from_descriptor(descriptor: Dictionary) -> InputEvent:
	match String(descriptor.get("type", "")):
		"key":
			var key := InputEventKey.new()
			key.keycode = int(descriptor.get("keycode", 0)) as Key
			key.physical_keycode = int(descriptor.get("physical_keycode", 0)) as Key
			key.shift_pressed = bool(descriptor.get("shift", false))
			key.ctrl_pressed = bool(descriptor.get("ctrl", false))
			key.alt_pressed = bool(descriptor.get("alt", false))
			key.meta_pressed = bool(descriptor.get("meta", false))
			return key
		"joypad_button":
			var joy := InputEventJoypadButton.new()
			joy.button_index = int(descriptor.get("button_index", -1)) as JoyButton
			joy.device = int(descriptor.get("device", -1))
			return joy
	return null


static func _event_label(event: InputEvent) -> String:
	if event is InputEventKey:
		var key := event as InputEventKey
		var code: Key = key.keycode if key.keycode != 0 else key.physical_keycode
		if code == 0:
			return ""
		var key_label := OS.get_keycode_string(code)
		if key_label.is_empty():
			key_label = "Key %d" % int(code)
		var modifiers: Array[String] = []
		if key.ctrl_pressed:
			modifiers.append("Ctrl")
		if key.alt_pressed:
			modifiers.append("Alt")
		if key.shift_pressed:
			modifiers.append("Shift")
		if key.meta_pressed:
			modifiers.append("Meta")
		modifiers.append(key_label)
		return "+".join(modifiers)
	if event is InputEventJoypadButton:
		var joy := event as InputEventJoypadButton
		var names := {
			JOY_BUTTON_A: "A",
			JOY_BUTTON_B: "B",
			JOY_BUTTON_X: "X",
			JOY_BUTTON_Y: "Y",
			JOY_BUTTON_BACK: "Back",
			JOY_BUTTON_GUIDE: "Guide",
			JOY_BUTTON_START: "Start",
			JOY_BUTTON_LEFT_STICK: "L3",
			JOY_BUTTON_RIGHT_STICK: "R3",
			JOY_BUTTON_LEFT_SHOULDER: "LB",
			JOY_BUTTON_RIGHT_SHOULDER: "RB",
			JOY_BUTTON_DPAD_UP: "D-pad Up",
			JOY_BUTTON_DPAD_DOWN: "D-pad Down",
			JOY_BUTTON_DPAD_LEFT: "D-pad Left",
			JOY_BUTTON_DPAD_RIGHT: "D-pad Right",
		}
		return String(names.get(joy.button_index, "Button %d" % int(joy.button_index)))
	return ""


static func _normalize_descriptor(source: Dictionary) -> Dictionary:
	var allowed_keys: Array[String] = []
	var descriptor: Dictionary = {}
	match String(source.get("type", "")):
		"key":
			allowed_keys = ["type", "keycode", "physical_keycode", "shift", "ctrl", "alt", "meta"]
			var keycode_value: Variant = source.get("keycode", 0)
			var physical_value: Variant = source.get("physical_keycode", 0)
			if not _is_nonnegative_integer(keycode_value) or not _is_nonnegative_integer(physical_value):
				return {"valid": false, "error": "Key codes must be non-negative integers."}
			var keycode := int(keycode_value)
			var physical_keycode := int(physical_value)
			if keycode == 0 and physical_keycode == 0:
				return {"valid": false, "error": "A key binding must specify a logical or physical key."}
			for modifier in ["shift", "ctrl", "alt", "meta"]:
				if source.has(modifier) and typeof(source[modifier]) != TYPE_BOOL:
					return {"valid": false, "error": "%s must be a Boolean." % modifier}
			descriptor = {
				"type": "key",
				"keycode": keycode,
				"physical_keycode": physical_keycode,
				"shift": bool(source.get("shift", false)),
				"ctrl": bool(source.get("ctrl", false)),
				"alt": bool(source.get("alt", false)),
				"meta": bool(source.get("meta", false)),
			}
		"joypad_button":
			allowed_keys = ["type", "button_index", "device"]
			var button_value: Variant = source.get("button_index", -1)
			var device_value: Variant = source.get("device", -1)
			if not _is_nonnegative_integer(button_value):
				return {"valid": false, "error": "Joypad button index must be a non-negative integer."}
			if not _is_integral_number(device_value) or int(device_value) < -1 or int(device_value) > 15:
				return {"valid": false, "error": "Joypad device must be -1 through 15."}
			var button_index := int(button_value)
			if button_index > 127:
				return {"valid": false, "error": "Joypad button index is out of range."}
			descriptor = {
				"type": "joypad_button",
				"button_index": button_index,
				"device": int(device_value),
			}
		_:
			return {"valid": false, "error": "Only keyboard and joypad-button bindings are supported."}
	for key_value in source:
		if typeof(key_value) not in [TYPE_STRING, TYPE_STRING_NAME] or String(key_value) not in allowed_keys:
			return {"valid": false, "error": "Binding contains an unsupported field."}
	return {"valid": true, "error": "", "descriptor": descriptor}


static func _binding_conflicts(candidates: Dictionary) -> Array[Dictionary]:
	var conflicts: Array[Dictionary] = []
	var seen: Dictionary[String, String] = {}
	for action in ACTION_IDS:
		var action_key := String(action)
		var definition := DEFINITIONS[action] as Dictionary
		var group := String(definition.get("group", "global"))
		for descriptor_value in candidates.get(action_key, []) as Array:
			var descriptor := descriptor_value as Dictionary
			var scoped_fingerprint := "%s|%s" % [group, _descriptor_fingerprint(descriptor)]
			if seen.has(scoped_fingerprint):
				conflicts.append({
					"action": action_key,
					"conflicts_with": seen[scoped_fingerprint],
					"binding": descriptor.duplicate(true),
					"group": group,
				})
			else:
				seen[scoped_fingerprint] = action_key
	return conflicts


static func _descriptor_fingerprint(descriptor: Dictionary) -> String:
	if String(descriptor.get("type", "")) == "key":
		return "key:%d:%d:%d:%d:%d:%d" % [
			int(descriptor.get("keycode", 0)),
			int(descriptor.get("physical_keycode", 0)),
			int(bool(descriptor.get("shift", false))),
			int(bool(descriptor.get("ctrl", false))),
			int(bool(descriptor.get("alt", false))),
			int(bool(descriptor.get("meta", false))),
		]
	return "joy:%d:%d" % [
		int(descriptor.get("device", -1)),
		int(descriptor.get("button_index", -1)),
	]


static func _is_integral_number(value: Variant) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var numeric := float(value)
	return not is_nan(numeric) and not is_inf(numeric) and floor(numeric) == numeric


static func _is_nonnegative_integer(value: Variant) -> bool:
	return _is_integral_number(value) and float(value) >= 0.0
