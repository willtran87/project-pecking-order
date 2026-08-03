extends SceneTree

const DialogueCatalog := preload("res://features/office/character_dialogue_catalog.gd")
const DialogueLibrary := preload("res://features/office/character_dialogue_library.gd")
const DialogueUI := preload("res://features/office/character_dialogue_ui.gd")
const ManagementUIThemeScript := preload("res://features/office/management_ui_theme.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var viewport_host := Control.new()
	viewport_host.custom_minimum_size = Vector2(1280.0, 720.0)
	viewport_host.size = Vector2(1280.0, 720.0)
	root.add_child(viewport_host)
	var ui := DialogueUI.new()
	viewport_host.add_child(ui)
	await process_frame

	var opening := DialogueCatalog.opening_beat(1)
	_check(ui.enqueue_dialogue(opening), "opening Mabel beat should be accepted", failures)
	await process_frame
	var panel := ui.find_child("CharacterDialoguePanel", true, false) as PanelContainer
	var portrait := ui.find_child("CharacterDialoguePortrait", true, false) as TextureRect
	var speaker := ui.find_child("CharacterDialogueSpeaker", true, false) as Label
	var quote := ui.find_child("CharacterDialogueQuote", true, false) as Label
	var dismiss := ui.find_child("CharacterDialogueDismiss", true, false) as Button
	var scrim := ui.find_child("CharacterDialogueScrim", true, false) as ColorRect
	_check(panel != null and panel.visible, "accepted dialogue should reveal one visual-novel dialogue panel", failures)
	_check(scrim != null and scrim.visible, "visual-novel dialogue should dim the office behind the cast", failures)
	_check(
		ui.is_blocking() and ui.has_blocking_dialogue(),
		"a visible visual-novel aside should truthfully report that it owns floor input",
		failures,
	)
	_check(portrait != null and portrait.texture != null, "dialogue should resolve the approved transparent portrait", failures)
	_check(speaker != null and speaker.text == "MABEL", "opening beat should name its established speaker", failures)
	_check(
		quote != null and "entry-level perch" in quote.text and quote.text.count("\n") <= 2,
		"opening satire should remain a short human-scale line",
		failures,
	)
	_check(
		panel != null
		and panel.get_global_rect().end.x <= viewport_host.get_global_rect().end.x + 0.5
		and panel.get_global_rect().end.y <= viewport_host.get_global_rect().end.y + 0.5,
		"dialogue panel should remain inside the authored desktop viewport",
		failures,
	)
	_check(
		panel != null
		and panel.size.x >= viewport_host.size.x * 0.75
		and panel.size.y >= viewport_host.size.y * 0.58,
		"dialogue should command visual-novel scale instead of returning to a small notification card",
		failures,
	)
	_check(
		ui.accessibility_text().contains("Mabel")
		and ui.accessibility_text().contains("entry-level perch"),
		"visible character copy should have a matching concise accessibility projection",
		failures,
	)

	_check(
		not ui.enqueue_dialogue(opening),
		"the same authored beat should not spam twice in one session",
		failures,
	)
	var overtime_snapshot := {
		"day": 1,
		"overtime_enabled": true,
		"workers": [],
		"operations": {"manager_roster": []},
	}
	var before_overtime := overtime_snapshot.duplicate(true)
	before_overtime["overtime_enabled"] = false
	var overtime_beats := DialogueCatalog.beats_for_snapshot(before_overtime, overtime_snapshot)
	_check(
		overtime_beats.size() == 1
		and StringName((overtime_beats[0] as Dictionary).get("speaker_id", &"")) == &"henrietta",
		"real overtime state should translate into Henrietta's authored concern",
		failures,
	)
	var first_clutch_before := {
		"day": 1,
		"eggs_today": 0,
		"first_clutch_tracking": true,
		"workers": [],
		"operations": {"manager_roster": []},
	}
	var first_clutch_after := first_clutch_before.duplicate(true)
	first_clutch_after["eggs_today"] = 1
	_check(
		DialogueCatalog.beats_for_snapshot(first_clutch_before, first_clutch_after).is_empty(),
		"First Clutch should wait for the reinvestment consequence instead of queuing a generic first-egg line",
		failures,
	)
	var normal_first_egg_before := first_clutch_before.duplicate(true)
	normal_first_egg_before["first_clutch_tracking"] = false
	var normal_first_egg_after := normal_first_egg_before.duplicate(true)
	normal_first_egg_after["eggs_today"] = 1
	var normal_first_egg_beats := DialogueCatalog.beats_for_snapshot(
		normal_first_egg_before,
		normal_first_egg_after,
	)
	_check(
		normal_first_egg_beats.size() == 1
		and StringName((normal_first_egg_beats[0] as Dictionary).get(
			"presentation_mode", &"",
		)) == &"ambient",
		"routine first-egg color should use the non-modal ambient presentation",
		failures,
	)
	var ambient_ui := DialogueUI.new()
	viewport_host.add_child(ambient_ui)
	await process_frame
	_check(
		ambient_ui.enqueue_many(normal_first_egg_beats) == 1,
		"ambient first-egg color should enter the character queue",
		failures,
	)
	await process_frame
	var ambient_panel := ambient_ui.find_child(
		"CharacterDialoguePanel", true, false,
	) as PanelContainer
	var ambient_scrim := ambient_ui.find_child(
		"CharacterDialogueScrim", true, false,
	) as ColorRect
	var ambient_portrait := ambient_ui.find_child(
		"CharacterDialoguePortraitFrame", true, false,
	) as PanelContainer
	_check(
		ambient_panel != null
		and ambient_panel.visible
		and ambient_panel.size.x <= 460.0
		and ambient_panel.size.y <= 150.0
		and ambient_scrim != null
		and not ambient_scrim.visible
		and ambient_portrait != null
		and not ambient_portrait.visible,
		"ambient production color should stay compact, portrait-free, and leave the live floor undimmed",
		failures,
	)
	_check(
		not ambient_ui.is_blocking() and not ambient_ui.has_blocking_dialogue(),
		"ambient production color should remain explicitly non-blocking",
		failures,
	)
	ambient_ui.queue_free()
	var keycap_aftermath := DialogueCatalog.beat_for_decision_result({
		"accepted": true,
		"option_id": &"peckwork_tools",
	}, 1)
	var bank_aftermath := DialogueCatalog.beat_for_decision_result({
		"accepted": true,
		"option_id": &"bank_fund",
	}, 1)
	_check(
		StringName(keycap_aftermath.get("speaker_id", &"")) == &"mabel"
		and "nicer keys" in String(keycap_aftermath.get("text", ""))
		and StringName(bank_aftermath.get("speaker_id", &"")) == &"mabel"
		and "desk kept the old keys" in String(bank_aftermath.get("text", "")),
		"both first-egg beneficiaries should produce a specific Mabel aftermath beat",
		failures,
	)
	_check(ui.enqueue_many(overtime_beats) == 1 and ui.queued_count() == 1, "a live beat should queue behind the visible line", failures)
	ui.set_suspended(true)
	_check(not panel.visible and not ui.active_entry().is_empty(), "management modals should hide without discarding active dialogue", failures)
	ui.set_suspended(false)
	_check(panel.visible, "dialogue should return after the blocking surface closes", failures)
	var enter_event := InputEventKey.new()
	enter_event.pressed = true
	enter_event.keycode = KEY_ENTER
	ui.call("_unhandled_key_input", enter_event)
	await process_frame
	_check(
		StringName(ui.active_entry().get("speaker_id", &"")) == &"henrietta"
		and speaker != null and speaker.text == "HENRIETTA",
		"filing one line away should advance to the next queued speaker",
		failures,
	)

	var previous_manager_snapshot := {
		"day": 5,
		"workers": [],
		"operations": {"manager_roster": [{"id": "cornelius_credit"}]},
	}
	var current_manager_snapshot := previous_manager_snapshot.duplicate(true)
	current_manager_snapshot["operations"] = {
		"manager_roster": [
			{"id": "cornelius_credit"},
			{"id": "bramwell_quota"},
		],
	}
	var manager_beats := DialogueCatalog.beats_for_snapshot(
		previous_manager_snapshot,
		current_manager_snapshot,
	)
	_check(
		manager_beats.size() == 1
		and String((manager_beats[0] as Dictionary).get("speaker_name", "")) == "Bramwell Beakley"
		and StringName((manager_beats[0] as Dictionary).get("portrait_id", &"")) == &"bramwell",
		"each newly appointed manager should speak in their own established voice and portrait",
		failures,
	)

	var cast_probe_ui := DialogueUI.new()
	viewport_host.add_child(cast_probe_ui)
	await process_frame
	for speaker_value in DialogueLibrary.SPEAKERS:
		var speaker_id := StringName(String(speaker_value))
		var profile := DialogueLibrary.speaker(speaker_id)
		var portrait_id := StringName(String(profile.get("portrait", &"")))
		_check(
			cast_probe_ui.enqueue_dialogue({
				"id": StringName("cast_probe_%s" % String(speaker_id)),
				"speaker_id": speaker_id,
				"speaker_name": String(profile.get("name", "")),
				"speaker_role": String(profile.get("role", "")),
				"portrait_id": portrait_id,
				"channel": profile.get("channel", &"PRIVATE ASIDE"),
				"text": "Portrait and voice filing.",
				"hold_seconds": 15.0,
			}),
			"%s should have a runtime dialogue cutout" % String(speaker_id),
			failures,
		)
		await process_frame
		var cast_texture := cast_probe_ui.find_child(
			"CharacterDialoguePortrait",
			true,
			false,
		) as TextureRect
		_check(
			cast_texture != null and cast_texture.texture != null,
			"%s cutout should resolve its imported portrait" % String(speaker_id),
			failures,
		)
		cast_probe_ui.dismiss_current()
		await process_frame
	cast_probe_ui.queue_free()

	var route_beat := DialogueCatalog.beat_for_farmgate_dispatch({
		"accepted": true,
		"mandate_id": &"county_auction",
	}, 8)
	var credit_beat := DialogueCatalog.beat_for_farmer_relations_campaign({
		"accepted": true,
		"campaign_id": &"farmer_method",
	}, 8)
	var labor_beat := DialogueCatalog.beat_for_flock_relations_result({
		"accepted": true,
		"case_id": 41,
		"worker_id": 5,
		"action_id": &"file_pip",
	}, 8)
	var instruction_beat := DialogueCatalog.beat_for_manager_instruction({
		"accepted": true,
		"action_id": &"manager_posture",
		"manager_id": &"byte_automation",
		"choice_id": &"surveillance",
	}, 8)
	_check(
		StringName(route_beat.get("speaker_id", &"")) == &"dot"
		and StringName(credit_beat.get("speaker_id", &"")) == &"beatrice"
		and StringName(labor_beat.get("speaker_id", &"")) == &"beatrice"
		and StringName(instruction_beat.get("speaker_id", &"")) == &"byte",
		"late-game routes, public credit, labor cases, and manager instructions should all project through cast dialogue",
		failures,
	)

	var archive_return := DialogueCatalog.return_beat({
		"last_filed_label": "Shift 2 results filed",
		"status_label": "Archive Capacity",
	}, {
		"status_label": "Economy paused",
		"clock_anomaly": false,
	}, 3)
	var welfare_return := DialogueCatalog.return_beat({
		"last_filed_label": "Facility commissioned",
		"status_label": "Flock Welfare",
	}, {
		"status_label": "Economy paused",
		"clock_anomaly": false,
	}, 4)
	var clock_return := DialogueCatalog.return_beat({
		"last_filed_label": "Current checkpoint",
		"status_label": "Feed Coverage",
	}, {
		"status_label": "Economy paused",
		"clock_anomaly": true,
	}, 2)
	_check(
		StringName(archive_return.get("speaker_id", &"")) == &"dot"
		and "backlog" in String(archive_return.get("text", ""))
		and StringName(welfare_return.get("speaker_id", &"")) == &"pip"
		and "wellness program" in String(welfare_return.get("text", ""))
		and StringName(clock_return.get("speaker_id", &"")) == &"cornelius"
		and "no billable minutes" in String(clock_return.get("text", "")),
		"return beats should translate the saved bottleneck or clock anomaly through the matching cast voice",
		failures,
	)
	var return_ui := DialogueUI.new()
	viewport_host.add_child(return_ui)
	await process_frame
	_check(
		return_ui.enqueue_dialogue(archive_return)
		and not return_ui.enqueue_dialogue(archive_return),
		"the same saved-file return beat should present at most once per session",
		failures,
	)
	return_ui.queue_free()

	var community_signed := DialogueCatalog.beat_for_market_contract_signed({
		"accepted": true,
		"offer_id": &"community_access",
		"pricing_profile_id": &"community_access_rate",
	}, 3)
	var executive_signed := DialogueCatalog.beat_for_market_contract_signed({
		"accepted": true,
		"offer_id": &"executive_select",
		"pricing_profile_id": &"executive_select_rate",
	}, 4)
	_check(
		StringName(community_signed.get("speaker_id", &"")) == &"dot"
		and "more folders" in String(community_signed.get("text", "")),
		"Community Access pricing should translate volume and access into Dot's reaction",
		failures,
	)
	_check(
		StringName(executive_signed.get("speaker_id", &"")) == &"cornelius"
		and "fewer claimants" in String(executive_signed.get("text", "")),
		"Executive Select pricing should expose Cornelius's margin rationalization",
		failures,
	)
	_check(
		DialogueCatalog.beat_for_market_contract_signed({
		"accepted": false,
			"pricing_profile_id": &"executive_select_rate",
		}, 4).is_empty(),
		"rejected binder filings should not invent a consequence beat",
		failures,
	)

	var breached := DialogueCatalog.beat_for_market_contract_result({
		"status": &"breached",
		"offer_id": &"community_access",
		"pricing_profile_id": &"community_access_rate",
		"breach_cents": 1400,
	}, 5)
	var fulfilled := DialogueCatalog.beat_for_market_contract_result({
		"status": &"fulfilled",
		"success": true,
		"offer_id": &"community_access",
		"pricing_profile_id": &"community_access_rate",
	}, 5)
	_check(
		StringName(breached.get("speaker_id", &"")) == &"pip"
		and "invoice" in String(breached.get("text", "")),
		"a breached binder should become a concise causal consequence, not another metric",
		failures,
	)
	_check(
		StringName(fulfilled.get("speaker_id", &"")) == &"dot"
		and "claimants" in String(fulfilled.get("text", "")),
		"a fulfilled access binder should let the cast acknowledge its claimant effect",
		failures,
	)

	var feed_order := DialogueCatalog.beat_for_feed_order({
		"accepted": true,
		"offer_id": &"fixed_future_reserve",
	}, 4)
	var care_room := DialogueCatalog.beat_for_facility_purchase({
		"accepted": true,
		"facility_id": &"wellness_nest_room",
		"purchased_level": 1,
	}, 4)
	var manager_room := DialogueCatalog.beat_for_facility_purchase({
		"accepted": true,
		"commissioning_receipt": {
			"facility_id": &"rooster_operations_office",
			"purchased_level": 1,
		},
	}, 5)
	_check(
		StringName(feed_order.get("speaker_id", &"")) == &"dot"
		and "today's price" in String(feed_order.get("text", "")),
		"feed hedging should become a cast-observed short-versus-long tradeoff",
		failures,
	)
	_check(
		StringName(care_room.get("speaker_id", &"")) == &"henrietta"
		and "operational availability" in String(care_room.get("text", "")),
		"care construction should preserve the gap between corporate promise and access",
		failures,
	)
	_check(
		StringName(manager_room.get("speaker_id", &"")) == &"cornelius"
		and "same quota" in String(manager_room.get("text", "")),
		"management construction should keep Cornelius cold and pressured rather than villainous",
		failures,
	)

	viewport_host.custom_minimum_size = Vector2.ZERO
	viewport_host.size = Vector2(390.0, 720.0)
	ui.size = viewport_host.size
	await process_frame
	_check(
		panel.get_global_rect().position.x >= viewport_host.get_global_rect().position.x - 0.5
		and panel.get_global_rect().end.x <= viewport_host.get_global_rect().end.x + 0.5,
		"compact dialogue should stay inside a narrow viewport",
		failures,
	)

	ui.theme = ManagementUIThemeScript.create_theme(false, 1.5)
	_apply_explicit_font_scale(ui, 1.5)
	_expand_interface_copy(ui)
	viewport_host.size = Vector2(390.0, 844.0)
	ui.size = viewport_host.size
	await process_frame
	await process_frame
	var portrait_bounds := Rect2(viewport_host.global_position, viewport_host.size)
	_check(
		_visible_children_fit(panel, portrait_bounds),
		"390x844 at 150%% with expanded copy should contain the complete cutout (first=%s)"
		% _first_horizontal_overflow(panel, portrait_bounds),
		failures,
	)
	_check(
		portrait != null
		and portrait.is_visible_in_tree()
		and portrait.texture != null
		and portrait_bounds.encloses(portrait.get_global_rect()),
		"max-scale cutout should keep the approved portrait visible and physically attached to the aside (rect=%s panel=%s)"
		% [portrait.get_global_rect(), panel.get_global_rect()],
		failures,
	)
	_check(
		quote != null
		and quote.is_visible_in_tree()
		and portrait_bounds.encloses(quote.get_global_rect())
		and quote.get_global_rect().size.y >= quote.get_combined_minimum_size().y - 0.5,
		"max-scale cutout should allocate the expanded thought without clipping its required lines (rect=%s min=%s)"
		% [quote.get_global_rect(), quote.get_combined_minimum_size()],
		failures,
	)
	_check(
		dismiss != null
		and dismiss.is_visible_in_tree()
		and portrait_bounds.encloses(dismiss.get_global_rect()),
		"max-scale cutout should keep File Away physically reachable (rect=%s)"
		% dismiss.get_global_rect(),
		failures,
	)

	if "--capture-scale-dialogue" in OS.get_cmdline_user_args():
		var capture_viewport := SubViewport.new()
		capture_viewport.size = Vector2i(390, 844)
		capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(capture_viewport)
		var capture_host := Control.new()
		capture_host.custom_minimum_size = Vector2(390.0, 844.0)
		capture_host.size = Vector2(390.0, 844.0)
		capture_viewport.add_child(capture_host)
		var background := ColorRect.new()
		background.color = Color("0b141b")
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		capture_host.add_child(background)
		var capture_ui := DialogueUI.new()
		capture_host.add_child(capture_ui)
		await process_frame
		capture_ui.theme = ManagementUIThemeScript.create_theme(false, 1.5)
		_apply_explicit_font_scale(capture_ui, 1.5)
		capture_ui.set_reduced_motion(true)
		capture_ui.enqueue_dialogue({
			"id": &"max_scale_capture",
			"portrait_id": &"mabel",
			"speaker_name": "Mabel",
			"speaker_role": "Junior Claims Hen / Appeals",
			"channel": &"private_aside",
			"text": "I found the exclusion. I also found the farmer's name. Those are apparently different performance categories.",
			"hold_seconds": 15.0,
		})
		await process_frame
		await process_frame
		var capture_directory := ProjectSettings.globalize_path(
			"res://output/web-game/character-dialogue-scale-v1"
		)
		DirAccess.make_dir_recursive_absolute(capture_directory)
		var image := capture_viewport.get_texture().get_image()
		_check(image != null, "max-scale dialogue capture should expose a rendered viewport", failures)
		if image != null:
			_check(
				image.save_png(capture_directory.path_join("cutout-390x844.png")) == OK,
				"max-scale dialogue capture should save successfully",
				failures,
			)
		capture_viewport.queue_free()

	viewport_host.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("CHARACTER_DIALOGUE_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CHARACTER_DIALOGUE_UI_TEST_PASSED portraits=approved queue=bounded modal=safe satire=state_driven responsive=contained resilience=390x844+150-percent+expanded-copy")
	quit(0)


func _visible_children_fit(root_control: Control, viewport_bounds: Rect2) -> bool:
	return _first_horizontal_overflow(root_control, viewport_bounds) == "none"


func _first_horizontal_overflow(root_control: Control, viewport_bounds: Rect2) -> String:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
		if control != null and control.is_visible_in_tree():
			var rect := control.get_global_rect()
			if rect.position.x < viewport_bounds.position.x - 0.5 or rect.end.x > viewport_bounds.end.x + 0.5:
				return "%s rect=%s min=%s" % [control.name, rect, control.get_combined_minimum_size()]
	return "none"


func _apply_explicit_font_scale(root_control: Control, multiplier: float) -> void:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
		if control == null or not control.has_theme_font_size_override("font_size"):
			continue
		var base_size := control.get_theme_font_size("font_size")
		control.add_theme_font_size_override("font_size", maxi(10, roundi(float(base_size) * multiplier)))


func _expand_interface_copy(root_control: Control) -> void:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		if node_value is Button:
			var button := node_value as Button
			button.text = _expanded(button.text)
		elif node_value is Label:
			var label := node_value as Label
			label.text = _expanded(label.text)


func _expanded(source: String) -> String:
	var expanded := source
	for vowel: String in ["a", "e", "i", "o", "u", "A", "E", "I", "O", "U"]:
		expanded = expanded.replace(vowel, vowel + vowel)
	return expanded


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
