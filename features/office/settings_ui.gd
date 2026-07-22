class_name PeckingOrderSettingsUI
extends Control

## Responsive, keyboard-first player preferences surface.
##
## The UI owns no persistence and never mutates the campaign. Office supplies a
## sanitized preference dictionary, applies every emitted change immediately,
## and reports the saved binding labels back to this view.

signal close_requested
signal preferences_changed(preferences: Dictionary)
signal reset_defaults_requested
signal binding_capture_requested(action: StringName, event: InputEvent)
signal career_backup_export_requested
signal career_backup_import_requested(json_text: String)

const AUDIO_BUSES := [&"master", &"music", &"ambient", &"sfx", &"ui"]
const AUDIO_LABELS := {
	&"master": "MASTER",
	&"music": "CORPORATE MUZAK",
	&"ambient": "OFFICE HUM + FLOCK ROOM TONE",
	&"sfx": "FLOCK + WORKSTATIONS",
	&"ui": "BUREAU INTERFACE",
}
const REBINDABLE_ACTIONS := [
	&"pause_simulation",
	&"speed_normal",
	&"speed_fast",
	&"speed_ultra",
	&"peck_assist",
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
]
const ACTION_LABELS := {
	&"pause_simulation": "PAUSE / RESUME",
	&"speed_normal": "NORMAL CLOCK",
	&"speed_fast": "FAST CLOCK",
	&"speed_ultra": "ULTRA CLOCK",
	&"peck_assist": "PRIORITY PECK",
	&"fund_feed_party": "FUND FEED PARTY",
	&"toggle_overtime": "AFTER-HOURS PECKING",
	&"toggle_flockwatch": "FLOCKWATCH LEDGER",
	&"cycle_hen": "CYCLE HEN",
	&"camera_pan_left": "PAN CAMERA LEFT",
	&"camera_pan_right": "PAN CAMERA RIGHT",
	&"camera_pan_up": "PAN CAMERA UP",
	&"camera_pan_down": "PAN CAMERA DOWN",
	&"camera_zoom_in": "ZOOM CAMERA IN",
	&"camera_zoom_out": "ZOOM CAMERA OUT",
}
const MAX_PORTABLE_BACKUP_BYTES := 8 * 1024 * 1024
const PORTABLE_BACKUP_FILENAME := "pecking-order-career-backup.json"

var _preferences: Dictionary = {}
var _suppress_updates: bool = false
var _capture_action: StringName = &""
var _capture_pending: bool = false
var _panel: PanelContainer
var _scroll: ScrollContainer
var _audio_controls: Dictionary = {}
var _motion_selector: OptionButton
var _ui_scale_selector: OptionButton
var _quality_selector: OptionButton
var _timing_selector: OptionButton
var _color_vision_selector: OptionButton
var _contrast_toggle: CheckButton
var _focus_pause_toggle: CheckButton
var _binding_buttons: Dictionary = {}
var _controls_grid: GridContainer
var _comfort_grid: GridContainer
var _capture_banner: Label
var _status_label: Label
var _close_button: Button
var _backup_export_button: Button
var _backup_import_button: Button
var _backup_available: bool = false
var _backup_import_dialog: FileDialog
var _backup_export_dialog: FileDialog
var _backup_import_confirmation: ConfirmationDialog
var _pending_backup_text: String = ""
var _pending_backup_source: String = ""
var _pending_export_text: String = ""


func _ready() -> void:
	name = "PlayerSettings"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 240
	_build_interface()
	visible = false
	_apply_responsive_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_responsive_layout()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _capture_action != &"":
		if _is_binding_capture_cancel_pressed(event):
			_finish_binding_capture("Binding change cancelled.")
			get_viewport().set_input_as_handled()
			return
		if not _is_pressed_binding_event(event):
			return
		# One candidate remains authoritative until Office validates conflicts and
		# persistence, but the player can still cancel the pending request safely.
		if _capture_pending:
			get_viewport().set_input_as_handled()
			return
		_capture_pending = true
		_capture_banner.text = "CHECKING %s  //  waiting for the bureau to file this binding  //  Esc / controller B cancels" % String(ACTION_LABELS[_capture_action])
		set_status("Checking the new binding. No control has changed yet.")
		var captured := event.duplicate(true) as InputEvent
		binding_capture_requested.emit(_capture_action, captured)
		get_viewport().set_input_as_handled()
		return
	if (
		_is_defined_action_pressed(event, &"open_settings")
		or _is_defined_action_pressed(event, &"office_overview")
	):
		close_requested.emit()
		get_viewport().set_input_as_handled()


func show_settings(
	preferences: Dictionary,
	binding_labels: Dictionary = {},
	backup_available: bool = false,
) -> void:
	_preferences = preferences.duplicate(true)
	set_career_backup_available(backup_available)
	_suppress_updates = true
	_sync_controls_from_preferences()
	refresh_binding_labels(binding_labels)
	_suppress_updates = false
	_capture_action = &""
	_capture_pending = false
	_capture_banner.visible = false
	visible = true
	_apply_responsive_layout()
	_close_button.call_deferred("grab_focus")
	set_status("Preferences save separately from your career file.")


func hide_settings() -> void:
	_capture_action = &""
	_capture_pending = false
	_pending_backup_text = ""
	_pending_backup_source = ""
	_pending_export_text = ""
	if _backup_import_confirmation != null:
		_backup_import_confirmation.hide()
	if _backup_import_dialog != null:
		_backup_import_dialog.hide()
	if _backup_export_dialog != null:
		_backup_export_dialog.hide()
	visible = false


func is_open() -> bool:
	return visible


func set_status(message: String) -> void:
	if _status_label != null:
		_status_label.text = message
	tooltip_text = accessible_text()


func set_career_backup_available(available: bool) -> void:
	_backup_available = available
	if _backup_export_button != null:
		_backup_export_button.disabled = not available
		_backup_export_button.tooltip_text = (
			"Download a verified portable copy of the current career."
			if available else
			"Start or continue a campaign before exporting a career backup."
		)


func present_career_backup(json_text: String) -> bool:
	if json_text.is_empty() or json_text.to_utf8_buffer().size() > MAX_PORTABLE_BACKUP_BYTES:
		set_status("Career backup held: the verified export was empty or oversized.")
		return false
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(
			json_text.to_utf8_buffer(),
			PORTABLE_BACKUP_FILENAME,
			"application/json",
		)
		set_status("Portable career backup downloaded. Keep it outside browser storage.")
		return true
	_pending_export_text = json_text
	_backup_export_dialog.current_file = PORTABLE_BACKUP_FILENAME
	_backup_export_dialog.popup_centered_ratio(0.72)
	set_status("Choose where to save the verified portable career backup.")
	return true


## Stages untrusted text behind an explicit replacement confirmation. Office
## still owns envelope and domain validation, so this method cannot mutate a
## career even when called with malformed input.
func stage_career_backup_import(json_text: String, source_label: String = "selected file") -> bool:
	var byte_count := json_text.to_utf8_buffer().size()
	if byte_count <= 0:
		set_status("Career restore held: the selected backup is empty.")
		return false
	if byte_count > MAX_PORTABLE_BACKUP_BYTES:
		set_status("Career restore held: the selected backup exceeds the 8 MiB safety limit.")
		return false
	_pending_backup_text = json_text
	_pending_backup_source = source_label.strip_edges()
	for whitespace in ["\r", "\n", "\t"]:
		_pending_backup_source = _pending_backup_source.replace(whitespace, " ")
	_pending_backup_source = _pending_backup_source.substr(0, 120)
	_backup_import_confirmation.dialog_text = (
		"This will replace the active local career with %s. The current verified "
		+ "career remains as the automatic recovery copy. The imported file must pass "
		+ "envelope, campaign, office, and Senior Roost validation before anything changes."
	) % (_pending_backup_source if not _pending_backup_source.is_empty() else "the selected file")
	_backup_import_confirmation.popup_centered(Vector2i(680, 280))
	set_status("Career backup staged. Confirm replacement or cancel without changing anything.")
	return true


func complete_career_backup_import(accepted: bool, message: String) -> void:
	_pending_backup_text = ""
	_pending_backup_source = ""
	if _backup_import_confirmation != null:
		_backup_import_confirmation.hide()
	set_status(message)
	if not accepted and _backup_import_button != null:
		_backup_import_button.call_deferred("grab_focus")


func refresh_preferences(preferences: Dictionary) -> void:
	_preferences = preferences.duplicate(true)
	_suppress_updates = true
	_sync_controls_from_preferences()
	_suppress_updates = false


func refresh_binding_labels(binding_labels: Dictionary) -> void:
	for action_variant in _binding_buttons:
		var action := StringName(action_variant)
		var button := _binding_buttons[action] as Button
		var display := String(binding_labels.get(action, binding_labels.get(String(action), "UNBOUND")))
		button.text = "%s\n%s" % [String(ACTION_LABELS.get(action, String(action).to_upper())), display]
		button.tooltip_text = "Change %s. Current binding: %s" % [String(ACTION_LABELS.get(action, action)), display]
	tooltip_text = accessible_text()


func accessible_text() -> String:
	if _preferences.is_empty():
		return "Coop Settings and Controls."
	var audio := _preferences.get("audio", {}) as Dictionary
	var audio_parts: Array[String] = []
	for bus: StringName in AUDIO_BUSES:
		var row := audio.get(String(bus), audio.get(bus, {})) as Dictionary
		audio_parts.append(
			"%s %d percent%s" % [
				String(AUDIO_LABELS[bus]).capitalize(),
				roundi(float(row.get("volume", 1.0)) * 100.0),
				", muted" if bool(row.get("muted", false)) else "",
			]
		)
	var summary := (
		"Coop Settings and Controls. Audio: %s. Motion %s. Interface scale %d percent. "
		+ "High contrast %s. Color vision %s. Detail %s. Priority Peck timing %s. Pause when unfocused %s. Select a control to rebind it. F10 always opens settings; Escape always returns."
	) % [
		", ".join(audio_parts),
		String(_preferences.get("motion_mode", "system")),
		roundi(float(_preferences.get("ui_scale", 1.0)) * 100.0),
		"on" if bool(_preferences.get("high_contrast", false)) else "off",
		String(_preferences.get("color_vision_mode", "standard")).replace("_", " "),
		String(_preferences.get("visual_quality", "balanced")),
		String(_preferences.get("timing_assist", "standard")),
		"on" if bool(_preferences.get("pause_when_unfocused", true)) else "off",
	]
	if _capture_action != &"":
		summary += " Binding capture for %s is %s." % [
			String(ACTION_LABELS.get(_capture_action, _capture_action)).capitalize(),
			"awaiting validation" if _capture_pending else "waiting for another input",
		]
	summary += (
		" Career backup export is available; restore requires explicit confirmation."
		if _backup_available else
		" Career backup restore is available; export requires a verified campaign checkpoint."
	)
	if not _pending_backup_text.is_empty():
		summary += " A portable career backup is awaiting replacement confirmation."
	if _status_label != null and not _status_label.text.is_empty():
		summary += " Status: %s" % _status_label.text
	return summary


func capture_action() -> StringName:
	return _capture_action


func binding_capture_pending() -> bool:
	return _capture_pending


## Completes the host-owned validation/persistence handshake for one emitted
## binding candidate. A rejection leaves the same action armed so the player can
## immediately try another input; stale acknowledgements never alter UI state.
func acknowledge_binding_capture(
	action: StringName,
	accepted: bool,
	status_message: String = "",
	binding_labels: Dictionary = {},
) -> bool:
	if action != _capture_action or not _capture_pending:
		return false
	_capture_pending = false
	if accepted:
		if not binding_labels.is_empty():
			refresh_binding_labels(binding_labels)
		_finish_binding_capture(
			status_message if not status_message.is_empty()
			else "Binding filed. Changes save automatically."
		)
		return true
	_capture_banner.text = "BINDING NOT FILED FOR %s  //  press another key or gamepad button  //  Esc / controller B cancels" % String(ACTION_LABELS[action])
	_capture_banner.visible = true
	set_status(
		status_message if not status_message.is_empty()
		else "That binding could not be filed. Choose another input or cancel."
	)
	return true


func _build_interface() -> void:
	var scrim := ColorRect.new()
	scrim.name = "SettingsScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.015, 0.025, 0.035, 0.90)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scrim)

	_panel = PanelContainer.new()
	_panel.name = "SettingsPanel"
	_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.name = "SettingsMargin"
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	_panel.add_child(margin)

	var frame := VBoxContainer.new()
	frame.add_theme_constant_override("separation", 12)
	margin.add_child(frame)

	var header := HFlowContainer.new()
	header.name = "SettingsHeader"
	header.add_theme_constant_override("h_separation", 12)
	header.add_theme_constant_override("v_separation", 8)
	frame.add_child(header)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_stack)
	var eyebrow := _label("PERSONNEL SERVICES  //  PLAYER PREFERENCES", 12, Color("9bd9cc"))
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	eyebrow.custom_minimum_size.x = 220.0
	title_stack.add_child(eyebrow)
	var title := _label("COOP SETTINGS & CONTROLS", 22, Color("f4d27b"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = 220.0
	title_stack.add_child(title)
	_close_button = Button.new()
	_close_button.name = "SettingsCloseButton"
	_close_button.text = "RETURN TO THE FLOOR  [F10 / ESC]"
	_close_button.custom_minimum_size = Vector2(220.0, 42.0)
	_close_button.focus_mode = Control.FOCUS_ALL
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(_close_button)

	_capture_banner = _label("", 14, Color("fff0bd"))
	_capture_banner.name = "BindingCaptureBanner"
	_capture_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_capture_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_capture_banner.add_theme_stylebox_override("normal", _notice_style())
	_capture_banner.custom_minimum_size.y = 44.0
	_capture_banner.visible = false
	frame.add_child(_capture_banner)

	_scroll = ScrollContainer.new()
	_scroll.name = "SettingsScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(_scroll)

	var content := VBoxContainer.new()
	content.name = "SettingsContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	_scroll.add_child(content)
	_build_audio_section(content)
	_build_accessibility_section(content)
	_build_career_backup_section(content)
	_build_controls_section(content)

	var footer := HFlowContainer.new()
	footer.name = "SettingsFooter"
	footer.add_theme_constant_override("h_separation", 12)
	footer.add_theme_constant_override("v_separation", 8)
	frame.add_child(footer)
	_status_label = _label("Preferences save separately from your career file.", 12, Color("b9c8cc"))
	_status_label.name = "SettingsStatus"
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(_status_label)
	var reset := Button.new()
	reset.name = "SettingsResetButton"
	reset.text = "RESTORE SETTINGS DEFAULTS"
	reset.focus_mode = Control.FOCUS_ALL
	reset.pressed.connect(func() -> void: reset_defaults_requested.emit())
	footer.add_child(reset)

	_build_career_backup_dialogs()


func _build_audio_section(parent: VBoxContainer) -> void:
	var section := _section(parent, "AUDIO MIX", "Keep tactile flock feedback while turning down repetitive office layers.")
	for bus: StringName in AUDIO_BUSES:
		var row := VBoxContainer.new()
		row.name = "Audio_%s" % String(bus).capitalize()
		row.add_theme_constant_override("separation", 4)
		section.add_child(row)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 10)
		row.add_child(top)
		var label := _label(String(AUDIO_LABELS[bus]), 13, Color("dce7e5"))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.custom_minimum_size.x = 112.0
		top.add_child(label)
		var value := _label("100%", 13, Color("9bd9cc"))
		value.name = "AudioValue_%s" % String(bus)
		value.custom_minimum_size.x = 48.0
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		top.add_child(value)
		var mute := CheckButton.new()
		mute.name = "AudioMute_%s" % String(bus)
		mute.text = "MUTE"
		mute.focus_mode = Control.FOCUS_ALL
		mute.toggled.connect(_on_audio_mute_toggled.bind(bus))
		top.add_child(mute)
		var slider := HSlider.new()
		slider.name = "AudioVolume_%s" % String(bus)
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = 1.0
		slider.custom_minimum_size.y = 26.0
		slider.focus_mode = Control.FOCUS_ALL
		slider.value_changed.connect(_on_audio_volume_changed.bind(bus))
		row.add_child(slider)
		_audio_controls[bus] = {"slider": slider, "mute": mute, "value": value}


func _build_accessibility_section(parent: VBoxContainer) -> void:
	var section := _section(parent, "DISPLAY & ACCESSIBILITY", "Apply changes immediately; no restart and no career reset required.")
	_comfort_grid = GridContainer.new()
	_comfort_grid.name = "ComfortGrid"
	_comfort_grid.columns = 2
	_comfort_grid.add_theme_constant_override("h_separation", 18)
	_comfort_grid.add_theme_constant_override("v_separation", 10)
	section.add_child(_comfort_grid)

	_motion_selector = _choice_row(_comfort_grid, "MOTION", ["SYSTEM PREFERENCE", "REDUCED", "FULL"])
	_motion_selector.name = "MotionModeSelector"
	_motion_selector.item_selected.connect(_on_motion_selected)
	_ui_scale_selector = _choice_row(_comfort_grid, "INTERFACE SCALE", ["100%", "125%", "150%"])
	_ui_scale_selector.name = "UIScaleSelector"
	_ui_scale_selector.item_selected.connect(_on_ui_scale_selected)
	_quality_selector = _choice_row(_comfort_grid, "OFFICE DETAIL", ["PERFORMANCE", "BALANCED", "HIGH"])
	_quality_selector.name = "VisualQualitySelector"
	_quality_selector.item_selected.connect(_on_quality_selected)
	_timing_selector = _choice_row(_comfort_grid, "PRIORITY PECK WINDOW", ["STANDARD", "LENIENT", "EXTENDED"])
	_timing_selector.name = "TimingAssistSelector"
	_timing_selector.item_selected.connect(_on_timing_selected)
	_color_vision_selector = _choice_row(_comfort_grid, "COLOR VISION", ["STANDARD PALETTE", "COLOR-BLIND SAFE + SYMBOLS"])
	_color_vision_selector.name = "ColorVisionSelector"
	_color_vision_selector.tooltip_text = "Use high-separation colors plus [N], [P], [A], [OK], [*], and [X] gameplay markers."
	_color_vision_selector.item_selected.connect(_on_color_vision_selected)

	_contrast_toggle = CheckButton.new()
	_contrast_toggle.name = "HighContrastToggle"
	_contrast_toggle.text = "HIGH-CONTRAST INTERFACE"
	_contrast_toggle.tooltip_text = "Increase file-card separation and strengthen keyboard focus rings."
	_contrast_toggle.focus_mode = Control.FOCUS_ALL
	_contrast_toggle.toggled.connect(_on_contrast_toggled)
	section.add_child(_contrast_toggle)
	_focus_pause_toggle = CheckButton.new()
	_focus_pause_toggle.name = "PauseWhenUnfocusedToggle"
	_focus_pause_toggle.text = "PAUSE WHEN UNFOCUSED"
	_focus_pause_toggle.tooltip_text = "Prevent deadlines and production from advancing while another window or browser tab has focus; safely resume the exact prior clock speed on return."
	_focus_pause_toggle.focus_mode = Control.FOCUS_ALL
	_focus_pause_toggle.toggled.connect(_on_focus_pause_toggled)
	section.add_child(_focus_pause_toggle)
	var safety := _label("F10 and the controller Guide button always open this panel. Escape and controller B always provide a safe return.", 12, Color("b9c8cc"))
	safety.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section.add_child(safety)


func _build_controls_section(parent: VBoxContainer) -> void:
	var section := _section(parent, "CONTROL BINDINGS", "Select a filing, then press one keyboard or gamepad button. Camera, clock, and floor bindings save independently; pointer and touch gestures remain available.")
	_controls_grid = GridContainer.new()
	_controls_grid.name = "ControlBindingGrid"
	_controls_grid.columns = 2
	_controls_grid.add_theme_constant_override("h_separation", 10)
	_controls_grid.add_theme_constant_override("v_separation", 10)
	section.add_child(_controls_grid)
	for action: StringName in REBINDABLE_ACTIONS:
		var button := Button.new()
		button.name = "Binding_%s" % String(action)
		button.text = "%s\nUNBOUND" % String(ACTION_LABELS[action])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(250.0, 56.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_begin_binding_capture.bind(action))
		_controls_grid.add_child(button)
		_binding_buttons[action] = button


func _build_career_backup_section(parent: VBoxContainer) -> void:
	var section := _section(
		parent,
		"CAREER BACKUP",
		"Browser storage may be cleared. Keep a portable copy outside the browser, or restore one after explicit validation.",
	)
	var actions := HFlowContainer.new()
	actions.name = "CareerBackupActions"
	actions.add_theme_constant_override("h_separation", 10)
	actions.add_theme_constant_override("v_separation", 10)
	section.add_child(actions)
	_backup_export_button = Button.new()
	_backup_export_button.name = "CareerBackupExportButton"
	_backup_export_button.text = "DOWNLOAD CAREER BACKUP"
	_backup_export_button.focus_mode = Control.FOCUS_ALL
	_backup_export_button.custom_minimum_size = Vector2(250.0, 46.0)
	_backup_export_button.pressed.connect(func() -> void: career_backup_export_requested.emit())
	actions.add_child(_backup_export_button)
	_backup_import_button = Button.new()
	_backup_import_button.name = "CareerBackupImportButton"
	_backup_import_button.text = "RESTORE BACKUP FILE..."
	_backup_import_button.focus_mode = Control.FOCUS_ALL
	_backup_import_button.custom_minimum_size = Vector2(250.0, 46.0)
	_backup_import_button.tooltip_text = "Choose a Pecking Order JSON backup. Nothing changes until confirmation and full validation."
	_backup_import_button.pressed.connect(_open_career_backup_import)
	actions.add_child(_backup_import_button)
	var safety := _label(
		"Restore never executes objects or scripts from a file. Invalid, oversized, newer-version, or incomplete ledgers are rejected before the current save changes.",
		12,
		Color("b9c8cc"),
	)
	safety.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section.add_child(safety)
	set_career_backup_available(_backup_available)


func _build_career_backup_dialogs() -> void:
	_backup_import_dialog = FileDialog.new()
	_backup_import_dialog.name = "CareerBackupImportDialog"
	_backup_import_dialog.title = "Restore Pecking Order Career Backup"
	_backup_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_backup_import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_backup_import_dialog.filters = PackedStringArray(["*.json ; Pecking Order career backup"])
	_backup_import_dialog.file_selected.connect(_on_career_backup_file_selected)
	add_child(_backup_import_dialog)

	_backup_export_dialog = FileDialog.new()
	_backup_export_dialog.name = "CareerBackupExportDialog"
	_backup_export_dialog.title = "Save Pecking Order Career Backup"
	_backup_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_backup_export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_backup_export_dialog.filters = PackedStringArray(["*.json ; Pecking Order career backup"])
	_backup_export_dialog.file_selected.connect(_on_career_backup_export_path_selected)
	add_child(_backup_export_dialog)

	_backup_import_confirmation = ConfirmationDialog.new()
	_backup_import_confirmation.name = "CareerBackupImportConfirmation"
	_backup_import_confirmation.title = "REPLACE THE LOCAL CAREER?"
	_backup_import_confirmation.ok_button_text = "VALIDATE & REPLACE"
	_backup_import_confirmation.cancel_button_text = "KEEP CURRENT CAREER"
	_backup_import_confirmation.min_size = Vector2i(680, 280)
	var confirmation_copy := _backup_import_confirmation.get_label()
	confirmation_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirmation_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	confirmation_copy.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	confirmation_copy.custom_minimum_size = Vector2(560.0, 104.0)
	confirmation_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_backup_import_confirmation.confirmed.connect(_confirm_career_backup_import)
	_backup_import_confirmation.canceled.connect(_cancel_career_backup_import)
	add_child(_backup_import_confirmation)


func _open_career_backup_import() -> void:
	if OS.has_feature("web"):
		var window := JavaScriptBridge.get_interface("window")
		if window == null:
			set_status("Career restore held: the browser file bridge is unavailable.")
			return
		var chooser: Variant = window.get("__pecking_order_choose_backup_file")
		if chooser == null:
			set_status("Career restore held: the browser file picker is not ready yet.")
			return
		window.__pecking_order_choose_backup_file()
		set_status("Choose a portable Pecking Order JSON backup from this device.")
		return
	_backup_import_dialog.popup_centered_ratio(0.72)
	set_status("Choose a portable Pecking Order career backup. Selection does not replace the current save.")


func _on_career_backup_file_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		set_status("Career restore held: the selected file could not be opened.")
		return
	var byte_count := file.get_length()
	if byte_count <= 0 or byte_count > MAX_PORTABLE_BACKUP_BYTES:
		file.close()
		set_status(
			"Career restore held: the selected file is empty or exceeds the 8 MiB safety limit."
		)
		return
	var json_text := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK:
		set_status("Career restore held: the selected file could not be read completely.")
		return
	stage_career_backup_import(json_text, path.get_file())


func _confirm_career_backup_import() -> void:
	if _pending_backup_text.is_empty():
		set_status("Career restore held: no backup is staged.")
		return
	career_backup_import_requested.emit(_pending_backup_text)


func _cancel_career_backup_import() -> void:
	_pending_backup_text = ""
	_pending_backup_source = ""
	set_status("Career restore cancelled. The current career was not changed.")
	if _backup_import_button != null:
		_backup_import_button.call_deferred("grab_focus")


func _on_career_backup_export_path_selected(path: String) -> void:
	if _pending_export_text.is_empty():
		set_status("Career backup held: no verified export is ready.")
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		set_status("Career backup held: the selected destination could not be opened.")
		return
	file.store_string(_pending_export_text)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		set_status("Career backup held: the destination did not accept the complete file.")
		return
	_pending_export_text = ""
	set_status("Portable career backup saved. Keep it outside the game data folder.")


func _section(parent: VBoxContainer, title_text: String, subtitle_text: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _section_style())
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 9)
	margin.add_child(stack)
	stack.add_child(_label(title_text, 18, Color("f4d27b")))
	var subtitle := _label(subtitle_text, 12, Color("aebdc5"))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(subtitle)
	stack.add_child(HSeparator.new())
	return stack


func _choice_row(parent: GridContainer, label_text: String, options: Array[String]) -> OptionButton:
	var label := _label(label_text, 13, Color("dce7e5"))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(label)
	var selector := OptionButton.new()
	selector.custom_minimum_size = Vector2(220.0, 42.0)
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.focus_mode = Control.FOCUS_ALL
	for option in options:
		selector.add_item(option)
	parent.add_child(selector)
	return selector


func _sync_controls_from_preferences() -> void:
	var audio := _preferences.get("audio", {}) as Dictionary
	for bus: StringName in AUDIO_BUSES:
		var row := audio.get(String(bus), audio.get(bus, {})) as Dictionary
		var controls := _audio_controls.get(bus, {}) as Dictionary
		var volume := clampf(float(row.get("volume", 1.0)), 0.0, 1.0)
		(controls.get("slider") as HSlider).value = volume
		(controls.get("mute") as CheckButton).button_pressed = bool(row.get("muted", false))
		(controls.get("value") as Label).text = "%d%%" % roundi(volume * 100.0)
	_motion_selector.select(["system", "reduced", "full"].find(String(_preferences.get("motion_mode", "system"))))
	_ui_scale_selector.select([1.0, 1.25, 1.5].find(float(_preferences.get("ui_scale", 1.0))))
	_quality_selector.select(["low", "balanced", "high"].find(String(_preferences.get("visual_quality", "balanced"))))
	_timing_selector.select(["standard", "lenient", "extended"].find(String(_preferences.get("timing_assist", "standard"))))
	_color_vision_selector.select(["standard", "color_blind_safe"].find(String(_preferences.get("color_vision_mode", "standard"))))
	_contrast_toggle.button_pressed = bool(_preferences.get("high_contrast", false))
	_focus_pause_toggle.button_pressed = bool(_preferences.get("pause_when_unfocused", true))


func _on_audio_volume_changed(value: float, bus: StringName) -> void:
	if _suppress_updates:
		return
	var audio := _preferences.get("audio", {}).duplicate(true) as Dictionary
	var row := audio.get(String(bus), {"volume": 1.0, "muted": false}).duplicate(true) as Dictionary
	row["volume"] = clampf(value, 0.0, 1.0)
	audio[String(bus)] = row
	_preferences["audio"] = audio
	var controls := _audio_controls[bus] as Dictionary
	(controls["value"] as Label).text = "%d%%" % roundi(value * 100.0)
	_emit_preferences()


func _on_audio_mute_toggled(enabled: bool, bus: StringName) -> void:
	if _suppress_updates:
		return
	var audio := _preferences.get("audio", {}).duplicate(true) as Dictionary
	var row := audio.get(String(bus), {"volume": 1.0, "muted": false}).duplicate(true) as Dictionary
	row["muted"] = enabled
	audio[String(bus)] = row
	_preferences["audio"] = audio
	_emit_preferences()


func _on_motion_selected(index: int) -> void:
	_set_preference("motion_mode", ["system", "reduced", "full"][clampi(index, 0, 2)])


func _on_ui_scale_selected(index: int) -> void:
	_set_preference("ui_scale", [1.0, 1.25, 1.5][clampi(index, 0, 2)])


func _on_quality_selected(index: int) -> void:
	_set_preference("visual_quality", ["low", "balanced", "high"][clampi(index, 0, 2)])


func _on_timing_selected(index: int) -> void:
	_set_preference("timing_assist", ["standard", "lenient", "extended"][clampi(index, 0, 2)])


func _on_color_vision_selected(index: int) -> void:
	_set_preference("color_vision_mode", ["standard", "color_blind_safe"][clampi(index, 0, 1)])


func _on_contrast_toggled(enabled: bool) -> void:
	_set_preference("high_contrast", enabled)


func _on_focus_pause_toggled(enabled: bool) -> void:
	_set_preference("pause_when_unfocused", enabled)


func _set_preference(key: String, value: Variant) -> void:
	if _suppress_updates:
		return
	_preferences[key] = value
	_emit_preferences()


func _emit_preferences() -> void:
	preferences_changed.emit(_preferences.duplicate(true))
	set_status("Preference filed. Saving outside the career record…")


func _begin_binding_capture(action: StringName) -> void:
	if _capture_pending:
		return
	_capture_action = action
	_capture_pending = false
	_capture_banner.text = "FILE NEW BINDING FOR %s  //  press a key or gamepad button  //  Esc / controller B cancels" % String(ACTION_LABELS[action])
	_capture_banner.visible = true
	set_status("Waiting for a keyboard or gamepad button. Cancel inputs are never rebound.")


func _finish_binding_capture(message: String) -> void:
	var finished_action := _capture_action
	_capture_action = &""
	_capture_pending = false
	_capture_banner.visible = false
	set_status(message)
	var button := _binding_buttons.get(finished_action) as Button
	if button != null:
		button.call_deferred("grab_focus")


func _is_binding_capture_cancel_pressed(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return false
		if key.keycode in [KEY_ESCAPE, KEY_F10] or key.physical_keycode in [KEY_ESCAPE, KEY_F10]:
			return true
	if event is InputEventJoypadButton:
		var joy := event as InputEventJoypadButton
		if joy.pressed and joy.button_index in [JOY_BUTTON_B, JOY_BUTTON_GUIDE]:
			return true
	return (
		_is_defined_action_pressed(event, &"ui_cancel")
		or _is_defined_action_pressed(event, &"office_overview")
		or _is_defined_action_pressed(event, &"open_settings")
	)


func _is_defined_action_pressed(event: InputEvent, action: StringName) -> bool:
	return InputMap.has_action(action) and event.is_action_pressed(action)


func _is_pressed_binding_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return (event as InputEventKey).pressed and not (event as InputEventKey).echo
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	return false


func _apply_responsive_layout() -> void:
	if _panel == null:
		return
	var viewport_size := size if size.x > 0.0 and size.y > 0.0 else get_viewport_rect().size
	var compact := viewport_size.x < 700.0 or viewport_size.y < 560.0
	if compact:
		_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_panel.offset_left = 8.0
		_panel.offset_top = 8.0
		_panel.offset_right = -8.0
		_panel.offset_bottom = -8.0
	else:
		_panel.set_anchors_preset(Control.PRESET_CENTER)
		var half_width := minf(500.0, viewport_size.x * 0.5 - 22.0)
		var half_height := minf(330.0, viewport_size.y * 0.5 - 18.0)
		_panel.offset_left = -half_width
		_panel.offset_top = -half_height
		_panel.offset_right = half_width
		_panel.offset_bottom = half_height
	if _controls_grid != null:
		_controls_grid.columns = 1 if viewport_size.x < 620.0 else 2
	if _comfort_grid != null:
		_comfort_grid.columns = 1 if viewport_size.x < 620.0 else 2


func _label(text_value: String, size_value: int, color_value: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color_value)
	return label


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111c26", 0.995)
	style.border_color = Color("c89b4a")
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 12
	return style


func _section_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1a2833", 0.98)
	style.border_color = Color("405665")
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	return style


func _notice_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("4d3b25", 0.98)
	style.border_color = Color("f0c963")
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
