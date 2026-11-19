class_name OfficeWebBridge
extends RefCounted

## Browser mirror: serializes diagnostic, accessibility and live-region state for the Web wrapper.
## Holds no state of its own: every read and write goes through the owning
## Office so behaviour is identical to the original in-class methods.

var office: Office


func _init(owner_node: Office) -> void:
	office = owner_node

func boot_timing_snapshot() -> Dictionary:
	var snapshot := office._boot_timing.duplicate(true)
	if office._office_storytelling != null:
		snapshot["optional_visuals"] = office._office_storytelling.optional_visual_build_snapshot()
	return snapshot


func _prewarm_web_management_surfaces() -> void:
	if office._flockwatch_panel == null or office._settings_ui == null:
		return
	# Chromium/Godot otherwise pays the complete Control layout and glyph setup
	# on the player's first toggle or shift close. Warm the already-built
	# management and review surfaces behind the opaque campaign intake before the
	# Web build reports itself interactive.
	var flockwatch_visible := office._flockwatch_panel.visible
	var flockwatch_modulate := office._flockwatch_panel.modulate
	var flockwatch_mouse_filter := office._flockwatch_panel.mouse_filter
	var settings_visible: bool = office._settings_ui.visible
	var settings_modulate: Color = office._settings_ui.modulate
	var settings_mouse_filter: int = office._settings_ui.mouse_filter
	var settings_processes_input: bool = office._settings_ui.is_processing_input()
	var review_visible := office._day_review_scrim.visible if office._day_review_scrim != null else false
	var review_modulate := office._day_review_scrim.modulate if office._day_review_scrim != null else Color.WHITE
	var review_mouse_filter := (
		office._day_review_scrim.mouse_filter
		if office._day_review_scrim != null else
		Control.MOUSE_FILTER_IGNORE
	)
	var review_details_visible := (
		office._review_details_scroll.visible
		if office._review_details_scroll != null else
		false
	)
	office._flockwatch_panel.modulate.a = 0.001
	office._flockwatch_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	office._flockwatch_panel.visible = true
	office._settings_ui.modulate.a = 0.001
	office._settings_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	office._settings_ui.set_process_input(false)
	office._settings_ui.visible = true
	if office._day_review_scrim != null:
		office._day_review_scrim.modulate.a = 0.001
		office._day_review_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		office._day_review_scrim.visible = true
	if office._review_details_scroll != null:
		office._review_details_scroll.visible = true
	if office._campaign_ui != null:
		await office._campaign_ui.prewarm_hidden_surfaces()
	else:
		await office.get_tree().process_frame
		await office.get_tree().process_frame
	office._flockwatch_panel.visible = flockwatch_visible
	office._flockwatch_panel.modulate = flockwatch_modulate
	office._flockwatch_panel.mouse_filter = flockwatch_mouse_filter
	office._settings_ui.visible = settings_visible
	office._settings_ui.modulate = settings_modulate
	office._settings_ui.mouse_filter = settings_mouse_filter
	office._settings_ui.set_process_input(settings_processes_input)
	if office._review_details_scroll != null:
		office._review_details_scroll.visible = review_details_visible
	if office._day_review_scrim != null:
		office._day_review_scrim.visible = review_visible
		office._day_review_scrim.modulate = review_modulate
		office._day_review_scrim.mouse_filter = review_mouse_filter
	office._refresh_floor_input_context()


func _load_web_player_preferences() -> Dictionary:
	if not OS.has_feature("web"):
		office._web_preferences_mirror_status = "not_applicable"
		return {}
	var bridge := JavaScriptBridge.get_interface("__pecking_order_preferences_bridge")
	if bridge == null:
		office._web_preferences_mirror_status = "bridge_unavailable"
		return {}
	var payload_value: Variant = bridge.call("load")
	if typeof(payload_value) != TYPE_STRING:
		office._web_preferences_mirror_status = "bridge_invalid_result"
		return {}
	var payload := String(payload_value)
	if payload.is_empty():
		office._web_preferences_mirror_status = "missing"
		return {}
	var preferences: Dictionary = office._web_preferences_mirror.decode(payload)
	if preferences.is_empty():
		office._web_preferences_mirror_status = "invalid"
		push_warning(office._web_preferences_mirror.last_error)
		return {}
	office._web_preferences_mirror_status = "loaded"
	return preferences


func _save_web_player_preferences() -> bool:
	if not OS.has_feature("web"):
		office._web_preferences_mirror_status = "not_applicable"
		return true
	var payload: String = office._web_preferences_mirror.encode(office._player_preferences)
	if payload.is_empty():
		office._web_preferences_mirror_status = "failed"
		push_warning(office._web_preferences_mirror.last_error)
		return false
	var bridge := JavaScriptBridge.get_interface("__pecking_order_preferences_bridge")
	if bridge == null:
		office._web_preferences_mirror_status = "bridge_unavailable"
		return false
	var saved := bool(bridge.call("save", payload))
	office._web_preferences_mirror_status = "saved" if saved else "failed"
	return saved


func _install_web_checkpoint_bridge() -> void:
	if not OS.has_feature("web"):
		return
	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		return
	office._web_checkpoint_flush_callback = JavaScriptBridge.create_callback(
		_on_web_checkpoint_flush_requested
	)
	window.set("__pecking_order_request_checkpoint", office._web_checkpoint_flush_callback)
	office._web_career_backup_offer_callback = JavaScriptBridge.create_callback(
		_on_web_career_backup_offered
	)
	window.set("__pecking_order_offer_backup", office._web_career_backup_offer_callback)
	office._web_mobile_action_callback = JavaScriptBridge.create_callback(
		_on_web_mobile_action_requested
	)
	window.set("__pecking_order_mobile_action", office._web_mobile_action_callback)
	office._web_focus_pause_callback = JavaScriptBridge.create_callback(
		_on_web_focus_pause_requested
	)
	window.set("__pecking_order_set_focus_paused", office._web_focus_pause_callback)
	office._web_diagnostic_request_callback = JavaScriptBridge.create_callback(
		_on_web_diagnostic_requested
	)
	window.set("__pecking_order_request_diagnostic", office._web_diagnostic_request_callback)
	office._web_accessibility_request_callback = JavaScriptBridge.create_callback(
		_on_web_accessibility_state_requested
	)
	window.set(
		"__pecking_order_request_accessibility_state",
		office._web_accessibility_request_callback,
	)


func _on_web_checkpoint_flush_requested(arguments: Array) -> void:
	var reason := "web_lifecycle"
	if not arguments.is_empty():
		var requested_reason := String(arguments[0]).strip_edges()
		if not requested_reason.is_empty():
			reason = requested_reason
	office._request_lifecycle_checkpoint(reason)


func _on_web_diagnostic_requested(arguments: Array) -> void:
	# The comprehensive design/audit projection is useful to developer tools,
	# but must not travel through every live status poll or assistive update.
	if not arguments.is_empty() and String(arguments[0]) == "full_gameplay_pulse":
		if OS.has_feature("web"):
			var window := JavaScriptBridge.get_interface("window")
			if window != null:
				window.set("__pecking_order_full_gameplay_pulse", JSON.stringify(office._json_safe_variant(office._gameplay_pulse)))
				window.set("__pecking_order_full_first_session_funnel", JSON.stringify(office._first_session_funnel.snapshot()))
		return
	var snapshot := office._pending_web_diagnostic_snapshot
	if snapshot.is_empty() and office._simulation != null:
		snapshot = office._simulation.snapshot(true)
	if not snapshot.is_empty():
		_serialize_web_diagnostic_state(snapshot)


func _on_web_accessibility_state_requested(_arguments: Array) -> void:
	var snapshot := office._pending_web_diagnostic_snapshot
	if snapshot.is_empty() and office._simulation != null:
		snapshot = office._simulation.snapshot(true)
	if not snapshot.is_empty():
		_serialize_web_accessibility_state(snapshot)


func _on_web_career_backup_offered(arguments: Array) -> void:
	if office._settings_ui == null or not office._settings_ui.is_open():
		return
	var json_text := String(arguments[0]) if arguments.size() > 0 else ""
	var source_label := String(arguments[1]) if arguments.size() > 1 else "browser backup"
	var bridge_error := String(arguments[2]).strip_edges() if arguments.size() > 2 else ""
	if not bridge_error.is_empty():
		office._settings_ui.complete_career_backup_import(
			false,
			"Career restore held: %s" % bridge_error.substr(0, Office.CHECKPOINT_ERROR_LIMIT),
		)
		_publish_web_diagnostic_state(office._simulation.snapshot())
		return
	office._settings_ui.stage_career_backup_import(json_text, source_label)
	# The Settings surface has paused the floor, so no simulation tick will
	# refresh the wrapper's live/assistive mirror after the browser file arrives.
	_publish_web_diagnostic_state(office._simulation.snapshot())


func _on_web_mobile_action_requested(arguments: Array) -> void:
	if arguments.is_empty():
		return
	var action := StringName(String(arguments[0]).strip_edges().to_lower())
	# This bridge is deliberately allow-listed. It exposes no arbitrary method,
	# property, file, or expression access to the page.
	match action:
		&"settings":
			office._on_settings_requested()
		&"career_backup":
			_on_career_backup_settings_requested()
		&"overview":
			if office._settings_ui != null and office._settings_ui.is_open():
				office._on_settings_close_requested()
			elif office._flockwatch_open:
				office._set_flockwatch_open(false, true)
			elif office._camera_controller != null and not office._blocking_management_surface_open():
				office._camera_controller.show_overview()
		&"flockwatch":
			if (
				(office._settings_ui == null or not office._settings_ui.is_open())
				and not office._blocking_management_surface_open()
			):
				office._on_flockwatch_pressed()
		&"zoom_in", &"zoom_out":
			if (
				office._camera_controller != null
				and office._camera_controller.is_processing_unhandled_input()
				and not office._blocking_management_surface_open()
			):
				office._camera_controller.request_zoom_step(action == &"zoom_in")
		&"cycle_hen":
			if office._flockwatch_open and office._flockwatch_navigation != null:
				office._flockwatch_navigation.cycle_page(1, true)
			elif (
				office._camera_controller != null
				and office._camera_controller.is_processing_unhandled_input()
				and not office._blocking_management_surface_open()
			):
				office._camera_controller.cycle_worker(1)
		&"pause":
			if not office._blocking_management_surface_open() and not office._flockwatch_open:
				office._on_pause_requested()
		&"next_moment":
			if not office._blocking_management_surface_open() and not office._flockwatch_open:
				office._on_next_moment_pressed()
		&"peck_assist":
			if not office._flockwatch_open and not office._peck_assist_input_blocked():
				office._request_peck_assist_from_input()
		_:
			return
	_publish_web_diagnostic_state(office._simulation.snapshot())


func _on_career_backup_settings_requested() -> void:
	office._build_settings_surface()
	if not office._settings_ui.is_open():
		office._on_settings_requested()
	if office._settings_ui.is_open():
		# This route is a one-time destination, not a preference mutation. Ordinary
		# F10 Settings should still reopen the category the player last filed.
		office._settings_ui.reveal_category(&"career", false, true)


func _on_web_focus_pause_requested(arguments: Array) -> void:
	if arguments.is_empty() or typeof(arguments[0]) != TYPE_BOOL:
		return
	var unfocused := bool(arguments[0])
	office._set_audio_focus_paused(unfocused)
	office._set_application_focus_paused(unfocused)
	if unfocused:
		office._request_lifecycle_checkpoint("web_focus_out")


func office_physical_presentation_snapshot() -> Dictionary:
	return office._office_physical_presentation_state(office._displayed_office_capacity).duplicate(true)


func capacity_commissioning_snapshot() -> Dictionary:
	return office._capacity_commissioning_state.duplicate(true)


func _active_status_accessible_detail() -> String:
	if (
		office._ticker_last_text.is_empty()
		or office._ticker_last_publish_msec < 0
		or Time.get_ticks_msec() - office._ticker_last_publish_msec > office._status_toast_hold_msec()
		or office._status_priority(office._ticker_last_text) != &"action"
		or not office._should_present_status_toast(office._ticker_last_text)
	):
		return ""
	return (
		office._ticker_last_accessible_text
		if not office._ticker_last_accessible_text.is_empty() else
		office._ticker_last_text
	)


func _active_held_confirmation_surface() -> String:
	if office.get_tree() == null:
		return ""
	for node: Node in office.get_tree().get_nodes_in_group(&"held_confirmation_dialogs"):
		var dialog := node as ConfirmationDialog
		if dialog == null or not office.is_ancestor_of(dialog) or not dialog.visible:
			continue
		return _held_confirmation_surface_id(dialog)
	return ""


func _held_confirmation_surface_id(dialog: ConfirmationDialog) -> String:
	match dialog.name:
		&"ClaimResolutionConfirmation":
			return "claimant_path"
		&"StaffReleaseConfirmation":
			return "hen_release"
		&"ManagerRecruitConfirmation":
			return "manager_succession"
		&"CareerSponsorshipConfirmation":
			return "career_sponsorship"
		&"FlockRelationsDispositionConfirmation":
			return "flock_relations_disposition"
		&"FarmerRelationsCampaignConfirmation":
			return "public_campaign"
		&"CareerBackupImportConfirmation":
			return "career_restore"
		_:
			return String(dialog.name).to_snake_case()


## Blocking confirmations outrank their parent management surface in the Web
## live region. Exact authored copy is preferred; the fallback still names both
## the irreversible action and the safe return for every themed confirmation.
func _active_held_confirmation_accessibility_event() -> Dictionary:
	if office.get_tree() == null:
		return {}
	for node: Node in office.get_tree().get_nodes_in_group(&"held_confirmation_dialogs"):
		var dialog := node as ConfirmationDialog
		if dialog == null or not office.is_ancestor_of(dialog) or not dialog.visible:
			continue
		var surface_id := _held_confirmation_surface_id(dialog)
		var accessible_text := String(dialog.get_meta("accessible_text", "")).strip_edges()
		if accessible_text.is_empty():
			accessible_text = "%s. %s Confirm: %s. Safe return: %s. No change until you confirm." % [
				dialog.title,
				dialog.dialog_text.replace("\n", " "),
				dialog.get_ok_button().text,
				dialog.get_cancel_button().text,
			]
		return {
			"kind": "held_confirmation_%s" % surface_id,
			"text": accessible_text,
		}
	return {}


func _probation_orders_accessibility_brief() -> String:
	if office._campaign_state == null:
		return "none filed."
	var lines: Array[String] = []
	for objective in office._campaign_state.current_objectives():
		lines.append("%s, %s, worth %d score" % [
			String(objective.get("title", "Probation order")),
			String(objective.get("description", "filed against the closing ledger.")),
			int(objective.get("score_award", 0)),
		])
	return "; ".join(lines) + "."


func _directive_choices_accessibility_brief() -> String:
	var lines: Array[String] = []
	for option_value in office._active_decision.get("options", []):
		var option := option_value as Dictionary
		var fit := office._directive_order_fit(StringName(option.get("id", &"")))
		lines.append("%s helps %d and risks %d orders" % [
			String(option.get("short_label", option.get("label", "Policy"))),
			int(fit.get("support_count", 0)),
			int(fit.get("risk_count", 0)),
		])
	return "; ".join(lines) + "."


func _decision_choices_accessibility_brief() -> String:
	var lines: Array[String] = []
	for option_value in office._active_decision.get("options", []):
		var option := option_value as Dictionary
		lines.append("%s. %s %s" % [
			String(option.get("label", "Response")),
			String(option.get("tagline", "")),
			String(option.get("preview", "Consequence pending.")),
		])
	return "; ".join(lines)


func _review_bottleneck_readout() -> String:
	if office._review_fund_value == null:
		return "Work quality unavailable"
	var card := office._review_fund_value.get_meta("report_card", {}) as Dictionary
	return "%s: %s" % [String(card.get("label", "Work quality")).capitalize(), office._review_fund_value.text]


func _next_moment_diagnostic_state(snapshot: Dictionary = {}) -> Dictionary:
	var target_state := office._next_moment_target_state(snapshot)
	return {
		"active": office._next_moment_active,
		"target": String(target_state.get("id", "next_management_moment")),
		"target_label": String(target_state.get("label", "DECISION / PECK / REVIEW")),
		"target_worker_id": int(target_state.get("worker_id", -1)),
		"camera_focus_on_stop": true,
		"previous_speed_index": office._next_moment_previous_speed,
		"stop_reason": office._next_moment_stop_reason,
		"binding": office._action_hint(Office.NEXT_MOMENT_ACTION),
		"button_text": office._next_moment_button.text if office._next_moment_button != null else "",
	}


func _checkpoint_diagnostic_state() -> Dictionary:
	var checkpoint: Dictionary = office._checkpoint_coordinator.diagnostic_snapshot()
	checkpoint["has_candidate"] = office._has_campaign_checkpoint_candidate
	checkpoint["has_checkpoint"] = office._has_verified_campaign_checkpoint
	checkpoint["last_error"] = office._checkpoint_last_error
	checkpoint["last_saved_reason"] = office._checkpoint_last_saved_reason
	checkpoint["last_saved_unix_msec"] = office._checkpoint_last_saved_unix_msec
	checkpoint["userfs_persistent_hint"] = (
		OS.is_userfs_persistent() if OS.has_feature("web") else true
	)
	if not office._checkpoint_last_error.is_empty():
		checkpoint["status"] = "error"
	elif bool(checkpoint.get("saving", false)):
		checkpoint["status"] = "saving"
	elif bool(checkpoint.get("dirty", false)):
		# Preserve the coordinator's precise pending/due/retry state.
		pass
	elif office._has_verified_campaign_checkpoint:
		checkpoint["status"] = "saved"
	else:
		checkpoint["status"] = "not_started"
	return checkpoint


func _campaign_order_page_arrival_state() -> Dictionary:
	return {
		"active": office._campaign_order_page_arrival_active,
		"animated": office._campaign_order_page_arrival_animated,
		"pinned": office._campaign_order_page_arrival_pinned,
		"reduced_motion": office._campaign_order_page_arrival_reduced_motion,
		"serial": office._campaign_order_page_arrival_serial,
		"page": String(office._campaign_order_page_arrival_page_id),
		"target": office._campaign_order_page_arrival_target_name,
	}


func _probation_doctrine_snapshot() -> Dictionary:
	if office._campaign_senior_roost or office._campaign_state == null:
		return {}
	return office._campaign_state.active_doctrine()


func _commendations_diagnostic_state() -> Dictionary:
	return Office.CareerCommendationsScript.compact_snapshot(office._commendations_snapshot)


func _routing_return_cue_diagnostic_state() -> Dictionary:
	var focus_state := (
		office._routing_ui.return_cue_focus_state()
		if office._routing_ui != null and office._routing_ui.has_method("return_cue_focus_state") else
		{}
	) as Dictionary
	var result := {
		"active": not office._routing_return_cue.is_empty(),
		"visible": not office._routing_return_cue.is_empty() and office._guidance_action_id == &"routing_chase",
		"dismissal": office._last_routing_return_cue_dismissal.duplicate(true),
		"focus": focus_state.duplicate(true),
	}
	if not office._routing_return_cue.is_empty():
		result.merge(office._routing_return_cue.duplicate(true), true)
	return result


func _pending_decision_diagnostic_state() -> Dictionary:
	if office._decision_host == null or not office._decision_host.visible or office._active_decision.is_empty():
		return {"visible": false}
	var spendable_cents := office._simulation.spendable_fund_cents() if office._simulation != null else 0
	var options: Array[Dictionary] = []
	var option_index := 0
	for option_value: Variant in office._active_decision.get("options", []):
		if option_index >= 3 or not option_value is Dictionary:
			break
		var option := option_value as Dictionary
		var cost_cents := maxi(0, int(option.get("cost_cents", 0)))
		var authored_available := bool(option.get("can_select", true))
		var available := authored_available and cost_cents <= spendable_cents
		var order_fit := (
			office._directive_order_fit(StringName(option.get("id", &"")))
			if StringName(office._active_decision.get("kind", &"")) == &"directive" else
			{}
		)
		options.append({
			"index": option_index + 1,
			"id": String(option.get("id", "")),
			"label": String(option.get("label", "RESPONSE")),
			"short_label": String(option.get("short_label", option.get("label", "RESPONSE"))),
			"glance": String(option.get("glance", "")),
			"tagline": String(option.get("tagline", "")),
			"preview": String(option.get("preview", "Consequence pending.")),
			"effect_chips": office._json_safe_variant(option.get("effect_chips", [])),
			"tone": String(option.get("tone", "")),
			"cost_cents": cost_cents,
			"case_memory_active": bool(option.get("case_memory_active", false)),
			"case_memory_label": String(option.get("case_memory_label", "")),
			"precedent": (option.get("precedent", {}) as Dictionary).duplicate(true),
			"available": available,
			"order_fit": order_fit.duplicate(true),
			"unavailable_reason": (
				"" if available else String(option.get(
					"unavailable_reason",
					"Requires $%.2f Feed Fund; only $%.2f is available." % [
						cost_cents / 100.0,
						spendable_cents / 100.0,
					],
				))
			),
		})
		option_index += 1
	return {
		"visible": true,
		"serial": int(office._active_decision.get("serial", -1)),
		"kind": String(office._active_decision.get("kind", "")),
		"id": String(office._active_decision.get("id", "")),
		"category": String(office._active_decision.get("category", "")),
		"eyebrow": String(office._active_decision.get("eyebrow", "")),
		"title": String(office._active_decision.get("title", "CHOOSE A RESPONSE")),
		"body": String(office._active_decision.get(
			"body",
			"A measurable variance requires management attention.",
		)),
		"case_memory": (office._active_decision.get("case_memory", {}) as Dictionary).duplicate(true),
		"prompt": (
			office._decision_preview.text
			if office._decision_preview != null else
			String(office._active_decision.get(
				"selection_prompt",
				"Choose a response card, then authorize it.",
			))
		),
		"selected_option_id": String(office._selected_decision_option),
		"confirm_enabled": office._decision_confirm_button != null and not office._decision_confirm_button.disabled,
		"confirm_label": (
			office._decision_confirm_button.text
			if office._decision_confirm_button != null else
			String(office._active_decision.get("confirm_label", "AUTHORIZE RESPONSE"))
		),
		"spendable_fund_cents": spendable_cents,
		"options": options,
	}


func _flockwatch_diagnostic_state() -> Dictionary:
	var current_page := ""
	var current_page_title := ""
	var available_pages: Array[String] = []
	var accessible_copy := ""
	var last_feedback := office._ticker_last_text
	if office._flockwatch_navigation != null:
		current_page = String(office._flockwatch_navigation.current_page_id())
		current_page_title = office._flockwatch_navigation.current_page_title()
		for page_id: StringName in office._flockwatch_navigation.available_page_ids():
			available_pages.append(String(page_id))
		accessible_copy = office._flockwatch_navigation.accessible_text()
		last_feedback = office._flockwatch_navigation.last_feedback()
	return {
		"visible": office._flockwatch_open,
		"current_page": current_page,
		"current_page_title": current_page_title,
		"available_pages": available_pages,
		"accessible_text": accessible_copy if office._flockwatch_open else "",
		"last_feedback": last_feedback,
		"focused_campaign_order_id": String(office._focused_campaign_order_id),
		"campaign_order_focus_serial": office._campaign_order_focus_serial,
		"campaign_order_driver": {
			"visible": (
				office._campaign_order_driver_button != null
				and office._campaign_order_driver_button.is_visible_in_tree()
			),
			"objective_id": String(office._campaign_order_driver_action.get("objective_id", "")),
			"metric": String(office._campaign_order_driver_action.get("metric", "")),
			"action_id": String(office._campaign_order_driver_action.get("action_id", "")),
			"label": (
				office._campaign_order_driver_label.text
				if office._campaign_order_driver_label != null else
				""
			),
			"activation_serial": office._campaign_order_driver_activation_serial,
			"last_result": office._last_campaign_order_driver_result.duplicate(true),
			"page_arrival": _campaign_order_page_arrival_state(),
			"dispatch_tray_arrival": (
				office._routing_ui.dispatch_tray_arrival_state()
				if office._routing_ui != null and office._routing_ui.has_method("dispatch_tray_arrival_state") else
				{}
			),
			"hen_dossier_arrival": (
				office._routing_ui.hen_dossier_arrival_state()
				if office._routing_ui != null and office._routing_ui.has_method("hen_dossier_arrival_state") else
				{}
			),
		},
		"campaign_order_return": {
			"visible": not office._campaign_order_return_cue.is_empty(),
			"serial": office._campaign_order_return_serial,
			"objective_id": String(office._campaign_order_return_cue.get("objective_id", "")),
			"order_index": int(office._campaign_order_return_cue.get("order_index", -1)),
			"copy": String(office._campaign_order_return_cue.get("copy", "")),
			"icon_kind": String(office._campaign_order_return_cue.get("icon_kind", "")),
			"driver_action_id": String(office._campaign_order_return_cue.get("driver_action_id", "")),
			"handoff_kind": String(office._campaign_order_return_cue.get("handoff_kind", "")),
			"activation_serial": office._campaign_order_return_activation_serial,
			"last_result": office._last_campaign_order_return_result.duplicate(true),
		},
		"campaign_order_causes": _campaign_order_cause_diagnostic_state(),
	}


func _campaign_order_cause_diagnostic_state() -> Dictionary:
	var receipts: Array[Dictionary] = []
	for glance in office._campaign_order_glances:
		var objective_id := StringName(glance.get_meta("objective_id", &""))
		if objective_id == &"" or not office._campaign_order_cause_receipts.has(objective_id):
			continue
		var receipt := (
			office._campaign_order_cause_receipts[objective_id] as Dictionary
		).duplicate(true)
		receipt["source_available"] = office._campaign_order_cause_source_available(receipt)
		receipts.append(receipt)
	return {
		"serial": office._campaign_order_cause_serial,
		"count": receipts.size(),
		"receipts": receipts,
		"activation_serial": office._campaign_order_cause_activation_serial,
		"last_focus_result": office._last_campaign_order_cause_focus_result.duplicate(true),
		"claim_file_arrival": (
			office._routing_ui.claim_file_arrival_state()
			if office._routing_ui != null and office._routing_ui.has_method("claim_file_arrival_state") else
			{}
		),
		"hen_dossier_arrival": (
			office._routing_ui.hen_dossier_arrival_state()
			if office._routing_ui != null and office._routing_ui.has_method("hen_dossier_arrival_state") else
			{}
		),
	}


func _notification_diagnostic_state() -> Dictionary:
	var recent: Array[Dictionary] = []
	for entry: String in office._status_history.slice(0, mini(5, office._status_history.size())):
		recent.append({
			"priority": String(office._status_priority(entry)),
			"label": office._status_priority_label(entry),
			"copy": entry,
		})
	var toast_copy := ""
	if office._ticker_panel != null and office._ticker_panel.visible:
		toast_copy = office._ticker_visible_copy
	var now_msec := Time.get_ticks_msec()
	return {
		"level": String(office._player_preferences.get("notice_level", "all")),
		"toast_visible": office._ticker_panel != null and office._ticker_panel.visible,
		"toast_copy": toast_copy,
		"toast_priority": (
			String(office._status_priority(toast_copy))
			if not toast_copy.is_empty() else
			""
		),
		"toast_now_msec": now_msec,
		"toast_hide_at_msec": office._ticker_hide_at_msec,
		"toast_hold_remaining_msec": maxi(0, office._ticker_hide_at_msec - now_msec),
		"duration": String(office._player_preferences.get("notice_duration", "standard")),
		"configured_hold_msec": office._status_toast_hold_msec(),
		"ticker_label_copy": office._ticker_label.text if office._ticker_label != null else "",
		"latest_copy": office._ticker_last_text,
		"latest_priority": (
			String(office._status_priority(office._ticker_last_text))
			if not office._ticker_last_text.is_empty() else
			""
		),
		"history_expanded": office._status_history_expanded,
		"recent": recent,
		"handoff": office._latest_notification_handoff.duplicate(true),
	}


func _diagnostic_subset(source: Dictionary, keys: Array) -> Dictionary:
	var result: Dictionary = {}
	for key_value: Variant in keys:
		var key := String(key_value)
		if source.has(key):
			result[key] = source[key]
	return result


func _diagnostic_array_subset(source_value: Variant, keys: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not source_value is Array:
		return result
	for entry_value: Variant in source_value as Array:
		if entry_value is Dictionary:
			result.append(_diagnostic_subset(entry_value as Dictionary, keys))
	return result


func _diagnostic_without(source: Dictionary, omitted_keys: Array) -> Dictionary:
	var result := source.duplicate(true)
	for key_value: Variant in omitted_keys:
		result.erase(String(key_value))
	return result


## Facility authority contains a wide matrix of every current/next effect and
## prerequisite so authored management surfaces can explain a selected parcel.
## The synchronous browser mirror only needs each visible row's identity,
## purchase state, exact price/upkeep, and authored consequence summary.
func _compact_facility_record_diagnostic(source: Dictionary) -> Dictionary:
	var result := _diagnostic_subset(source, [
		"id", "name", "unlocked", "owned", "level", "max_level",
		"can_purchase", "cost_cents", "daily_maintenance_cents", "reason",
	])
	# Consequence summaries become decision-relevant once the facility is
	# available or owned. Locked future rows already expose their exact gate.
	if (
		bool(source.get("unlocked", false))
		or bool(source.get("owned", false))
		or bool(source.get("can_purchase", false))
	):
		result["benefits"] = (source.get("benefits", []) as Array).duplicate(true)
		result["tradeoffs"] = (source.get("tradeoffs", []) as Array).duplicate(true)
	return result


func _compact_facility_catalog_diagnostic(source_value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not source_value is Array:
		return result
	for source_value_entry: Variant in source_value as Array:
		if source_value_entry is Dictionary:
			result.append(_compact_facility_record_diagnostic(source_value_entry as Dictionary))
	return result


func _compact_facility_receipt_diagnostic(source: Dictionary) -> Dictionary:
	return _diagnostic_subset(source, [
		"accepted", "action_id", "day", "facility_id", "facility_name",
		"purchased_level", "level_name", "max_level", "cost_cents",
		"fund_before_cents", "fund_after_cents", "protected_reserve_before_cents",
		"protected_reserve_after_cents", "spendable_before_cents",
		"spendable_after_cents", "upkeep_before_cents", "upkeep_after_cents",
		"upkeep_delta_cents", "effect",
	])


func _compact_capital_plan_diagnostic(source: Dictionary) -> Dictionary:
	var result := _diagnostic_subset(source, [
		"has_pinned_plan", "pinned_capital_plan_id",
	])
	result["facility"] = _compact_facility_record_diagnostic(
		source.get("facility", {}) as Dictionary,
	)
	var last_receipt := _compact_facility_receipt_diagnostic(
		source.get("last_facility_purchase_receipt", {}) as Dictionary,
	)
	result["last_facility_purchase_receipt"] = last_receipt
	var history := source.get("commissioning_history", []) as Array
	result["commissioning_count"] = history.size()
	var latest_receipt := (
		_compact_facility_receipt_diagnostic(history.back() as Dictionary)
		if not history.is_empty() and history.back() is Dictionary else
		{}
	)
	# The authoritative last receipt and the tail of commissioning history are
	# normally identical. Publish the tail only when it represents a distinct
	# event instead of serializing the same receipt twice.
	result["latest_commissioning"] = (
		{}
		if (
			int(latest_receipt.get("day", -1)) == int(last_receipt.get("day", -2))
			and String(latest_receipt.get("facility_id", ""))
				== String(last_receipt.get("facility_id", ""))
			and String(latest_receipt.get("action_id", ""))
				== String(last_receipt.get("action_id", ""))
		) else
		latest_receipt
	)
	return result


func _compact_operations_diagnostic(
		source: Dictionary,
		include_staffing_details: bool = true,
) -> Dictionary:
	var result := _diagnostic_subset(source, [
		"version", "rooster_office_level", "it_coop_level",
		"flock_relations_office_level", "manager_capacity", "daily_costs",
		"supervision", "automation", "management_density", "manager_assignments",
		"manager_postures", "management_reports", "last_manager_action",
		"next_operations_action",
	])
	result["rooster_operations_office"] = _compact_facility_record_diagnostic(
		source.get("rooster_operations_office", {}) as Dictionary,
	)
	result["it_coop"] = _compact_facility_record_diagnostic(
		source.get("it_coop", {}) as Dictionary,
	)
	var compact_roster := _diagnostic_array_subset(
		source.get("manager_roster", []),
		[
			"id", "name", "archetype", "salary_cents",
			"assignment_id", "posture_id",
			"influence", "interventions", "credit_claims",
		],
	)
	var compact_candidates := _diagnostic_array_subset(
		source.get("manager_candidates", []),
		[
			"id", "name", "archetype", "default_posture", "hired",
			"can_recruit", "reason", "signing_cost_cents", "appointment_salary_cents",
			"supervisor_payroll_delta_cents",
		],
	)
	result["manager_roster_count"] = compact_roster.size()
	result["manager_candidate_count"] = compact_candidates.size()
	result["manager_roster"] = compact_roster if include_staffing_details else []
	result["manager_candidates"] = compact_candidates if include_staffing_details else []
	if include_staffing_details and not (source.get("manager_candidates", []) as Array).is_empty():
		var first_candidate := (source.get("manager_candidates", []) as Array)[0] as Dictionary
		result["succession_shared_terms"] = _diagnostic_subset(
			first_candidate,
			[
				"replaces_manager_id", "replaces_name", "replaces_salary_cents",
				"supervisor_payroll_after_cents",
			],
		)
	if not include_staffing_details:
		result.erase("manager_postures")
		result.erase("manager_assignments")
		result.erase("management_reports")
		result.erase("last_manager_action")
	return result


func _operations_staffing_details_visible(
		operations_filing_open: bool,
		held_confirmation_surface: StringName,
) -> bool:
	return operations_filing_open and held_confirmation_surface == &""


func _compact_interaction_safety_diagnostic(source: Dictionary) -> Dictionary:
	var routing := source.get("routing", {}) as Dictionary
	var staffing := source.get("staffing", {}) as Dictionary
	var backdrop := source.get("confirmation_backdrop", {}) as Dictionary
	var live := (
		bool(routing.get("claim_confirmation_visible", false))
		or bool(routing.get("route_undo_visible", false))
		or bool(staffing.get("release_confirmation_visible", false))
		or bool(staffing.get("manager_recruit_confirmation_visible", false))
		or bool(backdrop.get("visible", false))
	)
	if live:
		return source.duplicate(true)
	return {
		"routing": {
			"claim_confirmation_visible": false,
			"route_undo_visible": false,
		},
		"staffing": {
			"release_confirmation_visible": false,
			"manager_recruit_confirmation_visible": false,
		},
		"confirmation_backdrop": {"visible": false},
	}


func _compact_work_progress_diagnostic(source: Dictionary) -> Dictionary:
	if int(source.get("visible_count", 0)) > 0:
		return source.duplicate(true)
	var result := _diagnostic_subset(source, [
		"deadline_risk_count", "hovered_count", "paused_count", "pip_count_per_rail",
		"pooled_affordance_count", "pooled_rail_count", "reduced_motion",
		"selected_count", "visible_count",
	])
	result["desks"] = []
	return result


func _compact_probation_safeguards_diagnostic(source: Dictionary) -> Dictionary:
	var result := _diagnostic_subset(source, [
		"visible", "all_pass", "at_risk_count", "completed_shifts", "criteria_count",
		"is_final", "pass_count", "required_shifts",
	])
	result["criteria"] = _diagnostic_array_subset(
		source.get("criteria", []),
		[
			"id", "label", "metric", "comparison", "target", "unit", "current_value",
			"projected_value", "current_pass", "pass", "status", "distance_to_pass",
			"recoverable", "value_source",
		],
	)
	result["largest_recoverable_blocker"] = _diagnostic_subset(
		source.get("largest_recoverable_blocker", {}) as Dictionary,
		["id", "label", "metric", "target", "unit", "projected_value", "status", "distance_to_pass"],
	)
	var challenge := source.get("challenge_contract", {}) as Dictionary
	result["challenge_contract"] = _diagnostic_subset(
		challenge,
		["id", "label", "short_label", "difficulty", "difficulty_label"],
	)
	return result


func _compact_flock_care_diagnostic(source: Dictionary) -> Dictionary:
	var result := _diagnostic_subset(source, [
		"version", "active_staff_count", "welfare", "welfare_score",
		"rested_flock_gate", "rested_flock_gate_met", "welfare_delta_to_gate",
		"wellness_level", "training_roost_level", "breaks_active",
		"training_active_count", "recovery_perch_count", "rested_flock",
		"training_active", "training_terms", "recovery_effects", "next_care_action",
	])
	result["wellness_nest"] = _compact_facility_record_diagnostic(
		source.get("wellness_nest", {}) as Dictionary,
	)
	result["training_roost"] = _compact_facility_record_diagnostic(
		source.get("training_roost", {}) as Dictionary,
	)
	result["effects"] = _diagnostic_subset(
		source.get("effects", {}) as Dictionary,
		[
			"wellness_break_morale_millipoints", "wellness_break_recovery_basis_points",
			"wellness_break_recovery_multiplier",
			"wellness_overnight_fatigue_recovery_millipoints",
			"wellness_overnight_stress_recovery_millipoints",
			"wellness_strain_gain_basis_points", "wellness_strain_gain_multiplier",
			"training_roost_level", "cross_training_work_basis_points",
			"cross_training_work_multiplier", "career_coaching_xp_bonus",
			"career_sponsorship_cost_cents", "career_sponsorship_discount_cents",
		],
	)
	return result


func _egg_journey_feedback_active(source: Dictionary) -> bool:
	if not (source.get("receipts", []) as Array).is_empty():
		return true
	if bool((source.get("focused_receipt", {}) as Dictionary).get("visible", false)):
		return true
	for branch_name: String in [
		"world_acknowledgments",
		"fund_credit_batches",
		"auxiliary_settlements",
		"settlement_placement",
		"settlement_arbitration",
		"settlement_destinations",
		"fund_debits",
	]:
		var branch := source.get(branch_name, {}) as Dictionary
		for counter_name: String in [
			"active_count", "active_batch_count", "visible_batch_count",
			"visible_card_count", "deferred_batch_count", "deferred_card_count",
		]:
			if int(branch.get(counter_name, 0)) > 0:
				return true
	for pulse_value: Variant in (
		source.get("settlement_destinations", {}) as Dictionary
	).get("pulses", []):
		if pulse_value is Dictionary and bool((pulse_value as Dictionary).get("active", false)):
			return true
	return false


## Inactive journey pools repeat the same arbitration blocker across credits,
## stock, placement, and destination acknowledgements. Preserve complete live
## receipts while reducing dormant pool telemetry to one useful support summary.
func _compact_egg_journey_diagnostic(source: Dictionary) -> Dictionary:
	if _egg_journey_feedback_active(source):
		return source.duplicate(true)
	var arbitration_source := source.get("settlement_arbitration", {}) as Dictionary
	var arbitration := _diagnostic_subset(arbitration_source, [
		"active_batch_count", "deferred_batch_count", "visible_batch_count",
		"released_batch_count", "released_total", "suppressed_total",
		"release_serial", "release_cue_count",
	])
	arbitration["attention"] = _diagnostic_subset(
		arbitration_source.get("attention", {}) as Dictionary,
		["active", "primary_id", "accessible_text"],
	)
	return {
		"receipts": [],
		"focused_receipt": _diagnostic_subset(
			source.get("focused_receipt", {}) as Dictionary,
			["visible", "stage", "copy", "accessible_text", "worker_id", "claim_id"],
		),
		"world_acknowledgments": _diagnostic_subset(
			source.get("world_acknowledgments", {}) as Dictionary,
			["pooled_marker_count", "active_count", "capture_staged_count", "reduced_motion"],
		),
		"fund_credit_batches": _diagnostic_subset(
			source.get("fund_credit_batches", {}) as Dictionary,
			["pooled_chip_count", "active_batch_count", "total_eggs", "total_value_cents", "reduced_motion"],
		),
		"auxiliary_settlements": _diagnostic_subset(
			source.get("auxiliary_settlements", {}) as Dictionary,
			["pooled_chip_count", "active_batch_count", "stock_eggs", "stock_value_cents", "pecks_restored", "reduced_motion"],
		),
		"settlement_placement": _diagnostic_subset(
			source.get("settlement_placement", {}) as Dictionary,
			["card_count", "visible_card_count", "deferred_card_count", "clamped_count", "all_safe"],
		),
		"settlement_arbitration": arbitration,
		"settlement_destinations": _diagnostic_subset(
			source.get("settlement_destinations", {}) as Dictionary,
			["pooled_count", "active_count", "merged_total", "started_total", "reduced_motion"],
		),
		"fund_debits": _diagnostic_subset(
			source.get("fund_debits", {}) as Dictionary,
			["pooled_count", "active_count", "merged_total", "started_total", "recycled_total", "bounded", "reduced_motion"],
		),
	}


## The contract authority intentionally contains every client x pricing x rider
## permutation. The global synchronous browser mirror needs the current filing,
## not that recursively expanded catalog; the complete terms remain in the
## visible Contract Board and its accessibility text.
func _compact_contract_offer_diagnostic(
		source: Dictionary,
		include_schedule_details: bool = true,
) -> Dictionary:
	var result := _diagnostic_subset(source, [
		"id", "offer_id", "name", "short_name", "client", "known", "can_sign",
		"reason", "category", "tone", "tagline", "status", "total_claims",
		"rush_claims", "required_completed", "required_deliveries",
		"required_active_staff", "required_claim_capacity", "staffing_ready",
		"active_staff_count", "available_claim_slots", "lane_mix", "lane_mix_label",
		"rush_lane_mix", "rush_lane_mix_label", "arrival_schedule", "premium_cents",
		"contracted_premium_cents", "market_premium_cents",
		"authored_base_premium_cents", "base_premium_cents",
		"season_premium_delta_cents", "clause_premium_delta_cents",
		"service_coop_bonus_cents", "breach_cents", "breach_reserve_cents",
		"estimated_handling_cost_cents", "estimated_margin_cents",
		"estimated_margin_per_file_cents", "spendable_after_reserve_cents",
		"clause_id", "clause_label", "clause_summary", "clause_category",
		"pricing_profile_id", "pricing_label", "pricing_summary",
		"welfare_gate_required", "welfare_gate_minimum", "target_day", "deadline_day",
		"season_id", "season_label", "success_required", "benefit", "tradeoff",
		"summary", "completed_claim_ids", "timely_sound_completed",
	])
	result["scheduled_claims"] = (
		_diagnostic_array_subset(
			source.get("scheduled_claims", []),
			[
				"claim_id", "lane", "rush", "released", "rejected",
				"arrival_minute_of_day", "arrival_time", "deadline_minute_of_day",
				"deadline_time",
			],
		)
		if include_schedule_details else
		[]
	)
	return result


func _compact_contract_board_diagnostic(
		source: Dictionary,
		include_offer_index: bool,
) -> Dictionary:
	var result := _diagnostic_subset(source, [
		"unlocked", "unlock_day", "unlock_requirement", "planning_open", "target_day",
		"last_result", "decline_receipt", "market_standing", "market_standing_rank",
		"season_id", "season_label", "contracts_signed_total",
		"contracts_succeeded_total", "contracts_breached_total", "premium_today_cents",
		"premium_total_cents", "breach_today_cents", "breach_total_cents",
		"market_clean_contract_streak", "best_market_clean_contract_streak",
		"service_coop_level", "service_coop_premium_bonus_basis_points",
		"negotiation_room_level", "decline_available",
	])
	result["active"] = _compact_contract_offer_diagnostic(
		source.get("active", {}) as Dictionary,
	)
	result["active_contract"] = _compact_contract_offer_diagnostic(
		source.get("active_contract", {}) as Dictionary,
	)
	result["standing"] = (source.get("standing", {}) as Dictionary).duplicate(true)
	result["season"] = (source.get("season", {}) as Dictionary).duplicate(true)
	result["accreditation"] = _diagnostic_subset(
		source.get("accreditation", {}) as Dictionary,
		[
			"facility_id", "level", "max_level", "next_level", "current_maintenance_cents",
			"premium_bonus_basis_points", "premium_bonus_percent",
			"next_required_active_staff", "next_required_claim_capacity",
			"next_required_standing",
		],
	)
	result["negotiation_room"] = _diagnostic_subset(
		source.get("negotiation_room", {}) as Dictionary,
		["facility_id", "owned", "installed", "level", "reason", "current_maintenance_cents"],
	)
	result["pricing"] = _diagnostic_subset(
		source.get("pricing", {}) as Dictionary,
		["claimant_satisfaction", "market_share_basis_points"],
	)
	var compact_offers: Array[Dictionary] = []
	if include_offer_index:
		for offer_value: Variant in source.get("offers", []) as Array:
			if offer_value is Dictionary:
				compact_offers.append(_compact_contract_offer_diagnostic(
					offer_value as Dictionary,
					false,
				))
	result["offers"] = compact_offers
	return result


func _compact_contract_planning_diagnostic(source: Dictionary) -> Dictionary:
	var result := _diagnostic_subset(source, [
		"selected_offer_id", "selected_clause_id", "selected_pricing_profile_id",
		"negotiation_open", "sign_enabled", "signature_pending", "decline_visible",
		"decline_pending", "continue_enabled", "can_sign", "hold_reason",
	])
	result["effective_terms"] = _compact_contract_offer_diagnostic(
		source.get("effective_terms", {}) as Dictionary,
	)
	result["signed_contract"] = _compact_contract_offer_diagnostic(
		source.get("signed_contract", {}) as Dictionary,
	)
	return result


func _compact_campus_portfolio_diagnostic(source: Dictionary) -> Dictionary:
	var result := _diagnostic_subset(source, [
		"version", "summary", "planning_open", "current_day",
		"capital_spend_total_cents", "daily_cost_cents", "last_receipt", "resources",
		"contractor", "network", "bonuses",
	])
	result["parcels"] = _diagnostic_array_subset(
		source.get("parcels", []),
		["id", "name", "owned", "deed_filed", "status_label", "capital_cost_cents", "daily_cost_cents"],
	)
	result["modules"] = _diagnostic_array_subset(
		source.get("modules", source.get("module_catalog", [])),
		[
			"id", "module_id", "name", "installed", "commissioned", "built",
			"operational", "pad_id", "worker_id", "worker_name", "staffed",
			"requires_staff",
		],
	)
	result["projects"] = _diagnostic_array_subset(
		source.get("projects", []),
		[
			"id", "project_id", "module_id", "module_name", "status", "status_label",
			"stage_id", "stage_label", "remaining_shifts", "pad_id", "parcel_id",
		],
	)
	result["workers"] = _diagnostic_array_subset(
		source.get("workers", []),
		["id", "worker_id", "name", "display_name", "worker_name"],
	)
	result["assignments"] = _diagnostic_array_subset(
		source.get("assignments", []),
		["module_id", "facility_id", "worker_id", "worker_name"],
	)
	return result


func _compact_campus_expansion_diagnostic(source: Dictionary) -> Dictionary:
	var result := _diagnostic_subset(source, [
		"id", "visible", "summary", "unlock_day", "access_gate_met",
		"access_gate_reason", "parcel_owned", "pod_owned", "pod_operational",
		"pod_socket_id", "claim_capacity_bonus", "farmgate_capacity_bonus_eggs",
		"current_daily_cost_cents", "construction_stage", "capital_spend_total_cents",
		"last_receipt",
	])
	result["parcel"] = _diagnostic_subset(
		source.get("parcel", {}) as Dictionary,
		["id", "name", "owned", "can_purchase", "reason", "capital_cost_cents", "daily_cost_cents"],
	)
	result["services"] = _diagnostic_array_subset(
		source.get("services", []),
		["id", "name", "connected", "commissioned", "owned", "required_for_pod"],
	)
	result["routing_pod"] = _diagnostic_subset(
		source.get("routing_pod", {}) as Dictionary,
		["id", "name", "owned", "placed", "operational", "current_socket_id", "socket_id"],
	)
	return result


## Compact engine-health counters for release soak tests and support reports.
## These are sampled only when the already-throttled Web diagnostic is rebuilt;
## they do not add a second timer or perform any allocation-heavy enumeration.
func _runtime_performance_diagnostic() -> Dictionary:
	return {
		"fps": int(round(Performance.get_monitor(Performance.TIME_FPS))),
		"process_usec": int(round(
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000000.0
		)),
		"physics_process_usec": int(round(
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000000.0
		)),
		"static_memory_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"static_memory_peak_bytes": int(
			Performance.get_monitor(Performance.MEMORY_STATIC_MAX)
		),
		"object_count": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"orphan_node_count": int(
			Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
		),
		"draw_calls": int(
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		),
		"rendered_objects": int(
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		),
		"rendered_primitives": int(
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		),
	}


func _publish_web_diagnostic_state(snapshot: Dictionary) -> void:
	if not OS.has_feature("web"):
		return
	# Keep only the newest immutable read model. The browser asks for either a
	# compact assistive mirror or the complete audit payload synchronously. This
	# removes the former ~214 KB serialization from ordinary gameplay frames.
	office._pending_web_diagnostic_snapshot = snapshot
	office._web_diagnostic_dirty = true


func _dispatch_diagnostic_state() -> Dictionary:
	var candidate_ids: Array[int] = []
	var candidate_previews: Array[Dictionary] = []
	for candidate in office._dispatch_candidates:
		candidate_ids.append(int(candidate.get("worker_id", -1)))
		candidate_previews.append({
			"worker_id": int(candidate.get("worker_id", -1)),
			"fit_tier": String(candidate.get("fit_tier", "risky")),
			"fit_label": String(candidate.get("fit_label", "RISKY")),
			"fit_shape": String(candidate.get("fit_shape", "triangle")),
			"pace": String(candidate.get("pace_preview", "slow")),
			"shell_risk": String(candidate.get("shell_risk_preview", "high")),
			"reward": String(candidate.get("reward_preview", "recovery")),
			"strategy": String(candidate.get("strategy_label", "GAMBIT")),
			"consequence": String(candidate.get("consequence_preview", "FLOW RESETS")),
		})
	var recommendation_handoff := {}
	var recommended_view := office._worker_views.get(office._dispatch_recommended_worker_id) as ChickenView
	if recommended_view != null:
		recommendation_handoff = recommended_view.dispatch_candidate_snapshot()
	var work_progress_source := (
		office._workstation_feedback.work_progress_snapshot()
		if office._workstation_feedback != null else
		{}
	)
	return {
		"active": office._dispatch_lane != &"",
		"lane": String(office._dispatch_lane),
		"candidate_ids": candidate_ids,
		"candidate_previews": candidate_previews,
		"file_preview": office._dispatch_file_preview.duplicate(true),
		"fit_legend": {
			"best": {"shape": "star", "meaning": "FAST / LOW RISK / MOMENTUM"},
			"safe": {"shape": "check", "meaning": "STEADY / GUARDED / STABLE"},
			"risky": {"shape": "triangle", "meaning": "SLOW / HIGH RISK / RECOVERY"},
			"color_only": false,
		},
		"recommended_worker_id": office._dispatch_recommended_worker_id,
		"recommendation_handoff": recommendation_handoff,
		"drag_feedback": (
			office._routing_ui.dispatch_drag_feedback_state()
			if office._routing_ui != null and office._routing_ui.has_method("dispatch_drag_feedback_state") else
			{}
		),
		"momentum_chain": office._dispatch_momentum_chain,
		"momentum": office._simulation.routing_momentum_snapshot(),
		"reward_label": office._dispatch_reward_label,
		"last_receipt": office._dispatch_last_receipt.duplicate(true),
		"team_lift": office._last_team_lift_presentation.duplicate(true),
		"mastery_record": office._last_routing_mastery_presentation.duplicate(true),
		"mastery_ui": (
			office._routing_ui.routing_mastery_state()
			if office._routing_ui != null and office._routing_ui.has_method("routing_mastery_state") else
			{}
		),
		"break_serial": int(office._routing_ui.get_meta("dispatch_break_serial", 0)) if office._routing_ui != null else 0,
		"break_active": bool(office._routing_ui.get_meta("dispatch_break_active", false)) if office._routing_ui != null else false,
		"break_animated": bool(office._routing_ui.get_meta("dispatch_break_animated", false)) if office._routing_ui != null else false,
		"break_chain": int(office._routing_ui.get_meta("dispatch_break_chain", 0)) if office._routing_ui != null else 0,
		"break_source": String(office._routing_ui.get_meta("dispatch_break_source", &"")) if office._routing_ui != null else "",
		"break_capture_staged": bool(office._routing_ui.get_meta("dispatch_break_capture_staged", false)) if office._routing_ui != null else false,
		"recovery_serial": int(office._routing_ui.get_meta("dispatch_recovery_serial", 0)) if office._routing_ui != null else 0,
		"recovery_authority_serial": int(office._routing_ui.get_meta("dispatch_recovery_authority_serial", 0)) if office._routing_ui != null else 0,
		"recovery_break_serial": int(office._routing_ui.get_meta("dispatch_recovery_break_serial", 0)) if office._routing_ui != null else 0,
		"recovery_active": bool(office._routing_ui.get_meta("dispatch_recovery_active", false)) if office._routing_ui != null else false,
		"recovery_animated": bool(office._routing_ui.get_meta("dispatch_recovery_animated", false)) if office._routing_ui != null else false,
		"recovery_lane": String(office._routing_ui.get_meta("dispatch_recovery_lane", &"")) if office._routing_ui != null else "",
		"recovery_worker_name": String(office._routing_ui.get_meta("dispatch_recovery_worker_name", "")) if office._routing_ui != null else "",
		"recovery_capture_staged": bool(office._routing_ui.get_meta("dispatch_recovery_capture_staged", false)) if office._routing_ui != null else false,
		"active_folder_deliveries": (
			office._workstation_feedback.active_dispatch_delivery_count()
			if office._workstation_feedback != null else
			0
		),
		"active_reward_bursts": (
			office._workstation_feedback.active_routing_reward_burst_count()
			if office._workstation_feedback != null else
			0
		),
		"reward_world": (
			office._workstation_feedback.routing_reward_snapshot()
			if office._workstation_feedback != null else
			{}
		),
		"landing": (
			office._workstation_feedback.dispatch_landing_snapshot()
			if office._workstation_feedback != null else
			{}
		),
		"priority_peck_charge": (
			office._routing_ui.priority_peck_charge_state()
			if office._routing_ui != null else
			{}
		),
		"golden_file_ui": (
			office._routing_ui.golden_file_state()
			if office._routing_ui != null else
			{}
		),
		"workstation_pace": (
			office._workstation_feedback.routing_pace_snapshot()
			if office._workstation_feedback != null else
			{}
		),
		"work_progress": _compact_work_progress_diagnostic(work_progress_source),
		"work_progress_action": office._last_work_progress_action.duplicate(true),
		"work_progress_dossier": (
			office._routing_ui.context_action_state()
			if office._routing_ui != null else
			{}
		),
	}


func _serialize_web_accessibility_state(snapshot: Dictionary) -> void:
	if not OS.has_feature("web"):
		return
	var summary := _web_accessibility_summary(snapshot)
	var announcement := _web_accessibility_announcement(snapshot, summary)
	var title_open := (
		office._campaign_ui != null
		and office._campaign_ui.modal_state() == ProbationCampaignUI.VIEW_TITLE
	)
	var state := {
		"loaded": true,
		"mode": "godot_canvas_accessibility",
		"campaign_stage": "title" if title_open else String(office._campaign_review_stage),
		"campaign_day": int(office._campaign_state.completed_shifts) + 1,
		"shift_phase": int(snapshot.get("shift_phase", -1)),
		"authoritative_tick_revision": int(snapshot.get("authoritative_tick_revision", 0)),
		"accessibility_summary": summary,
		"accessibility_announcement": announcement,
		"checkpoint": _checkpoint_diagnostic_state(),
	}
	var window := JavaScriptBridge.get_interface("window")
	if window != null:
		window.set(
			"__pecking_order_accessibility_state",
			JSON.stringify(office._json_safe_variant(state)),
		)


func _campaign_intake_accessibility_objective() -> String:
	if office._campaign_ui == null:
		return "Choose a difficulty, then start Shift 1."
	var action := office._campaign_ui.title_primary_action_state()
	var objective := String(action.get("accessible_text", "")).strip_edges()
	return (
		objective
		if not objective.is_empty() else
		"Choose a difficulty, then start Shift 1."
	)


func _web_accessibility_summary(snapshot: Dictionary) -> String:
	var held_confirmation := _active_held_confirmation_accessibility_event()
	if not held_confirmation.is_empty():
		var safe_return := office._active_held_confirmation_primary_action_state()
		return _web_accessibility_text(
			"%s Objective: %s" % [
				String(held_confirmation.get("text", "")),
				String(safe_return.get(
					"accessible_text",
					"Review the irreversible filing or choose the safe return; no change occurs until confirmation.",
				)),
			],
			2200,
		)
	if office._settings_ui != null and office._settings_ui.is_open():
		return _web_accessibility_text(
			"%s Objective: adjust a preference or control binding, then choose Return to the Floor."
			% office._settings_ui.accessible_text(),
			2200,
		)
	if (
		office._campus_portfolio_reveal_ui != null
		and bool(office._campus_portfolio_reveal_ui.call("is_reveal_visible"))
	):
		var campus_reveal_action := (
			office._campus_portfolio_reveal_ui.call("primary_action_state") as Dictionary
		)
		return _web_accessibility_text(
			"%s Objective: %s" % [
				String(office._campus_portfolio_reveal_ui.call("accessible_text")),
				String(campus_reveal_action.get(
					"accessible_text",
					"Acknowledge the campus receipt and return to the prior office surface.",
				)),
			],
			2200,
		)
	if office._dispatch_lane != &"":
		var recommended := office._dispatch_candidate_for(office._dispatch_recommended_worker_id)
		return (
			"%s %s file selected. %s Choose a hen in the office. Star: %s, best fit, adds one flow. Check marks are safe alternatives and hold flow; warning triangles are risky alternatives and reset flow. Hover a hen for pace and shell-risk forecast. Other marked hens remain valid choices. Cancel returns the tray."
			% [
				String(office._dispatch_file_preview.get("symbol", "")),
				String(office._dispatch_file_preview.get("label", office._dispatch_lane_label(office._dispatch_lane))),
				String(office._dispatch_file_preview.get("reason", "")),
				String(recommended.get("worker_name", "unknown")),
			]
		)
	if office._workstation_feedback != null:
		var landing := office._workstation_feedback.dispatch_landing_snapshot()
		if bool(landing.get("active", false)):
			if bool(landing.get("work_started", false)):
				var work_copy := (
					"%s began peckwork on the best-fit %s file. Fit chain x%d."
					if bool(landing.get("recommended", false)) else
					"%s began peckwork on the routed %s file. The best-fit chain did not advance."
				)
				return work_copy % [
					String(landing.get("worker_name", "The selected hen")),
					office._dispatch_lane_label(StringName(landing.get("lane", &""))),
					int(landing.get("fit_chain", 0)),
				] if bool(landing.get("recommended", false)) else work_copy % [
					String(landing.get("worker_name", "The selected hen")),
					office._dispatch_lane_label(StringName(landing.get("lane", &""))),
				]
			var landing_copy := (
				"Best-fit %s file landed at %s's desk. Fit chain x%d."
				if bool(landing.get("recommended", false)) else
				"%s file routed to %s's desk. The best-fit chain did not advance."
			)
			return landing_copy % [
				office._dispatch_lane_label(StringName(landing.get("lane", &""))),
				String(landing.get("worker_name", "the selected hen")),
				int(landing.get("fit_chain", 0)),
			] if bool(landing.get("recommended", false)) else landing_copy % [
				office._dispatch_lane_label(StringName(landing.get("lane", &""))),
				String(landing.get("worker_name", "the selected hen")),
			]
	if office._decision_host != null and office._decision_host.visible and not office._active_decision.is_empty():
		var first_egg_choice := (
			StringName(office._active_decision.get("kind", &""))
			== Office.FIRST_CLUTCH_REINVESTMENT_KIND
		)
		var selection := ""
		if not office._selected_decision_option.is_empty():
			selection = " Selected %s: %s." % [
				"option" if first_egg_choice else "response",
				String(office._selected_decision_option).replace("_", " "),
			]
		var opening_policy_context := (
			StringName(office._active_decision.get("kind", &"")) == &"directive"
			and not office._campaign_senior_roost
			and office._campaign_state != null
			and int(office._campaign_state.completed_shifts) == 0
		)
		var choice_context := (
			" Today's orders: %s Choices: %s"
			% [
				_probation_orders_accessibility_brief(),
				_directive_choices_accessibility_brief(),
			]
			if opening_policy_context else
			" Choices: %s." % _decision_choices_accessibility_brief()
		)
		var decision_action := office._decision_primary_action_state()
		var decision_objective := (
			"Objective: %s" % String(decision_action.get("accessible_text", ""))
			if String(decision_action.get("stage", "select")) == "confirm" else
			"Objective: choose where the first egg goes, review the exact cost and desk payoff, then authorize or stay paused."
			if first_egg_choice else
			"Objective: choose a response, review its disclosed consequence, then authorize or stay paused."
		)
		return _web_accessibility_text(
			"%s. %s%s%s %s"
			% [
				office._decision_title.text if office._decision_title != null else String(
					office._active_decision.get("title", "Decision required")
				),
				String(office._decision_body.get_meta("accessible_text", office._decision_body.text))
				if office._decision_body != null else String(office._active_decision.get("body", "")),
				choice_context,
				selection,
				decision_objective,
			],
			1800,
		)
	if office._flockwatch_open and office._flockwatch_navigation != null:
		var required_flockwatch_action := office._flockwatch_navigation.context_action_accessible_text()
		var flockwatch_objective := (
			"Objective: complete the required in-panel action, or review another filing first."
			if not required_flockwatch_action.is_empty() else
			"Objective: review the open filing, then close Flockwatch to return to the floor."
		)
		return _web_accessibility_text(
			"%s %s %s"
			% [
				office._flockwatch_navigation.accessible_text(),
				office._flockwatch_navigation.last_feedback(),
				flockwatch_objective,
			],
			2600,
		)
	if office._capital_blueprint_ui != null and bool(office._capital_blueprint_ui.call("is_open")):
		return _web_accessibility_text(
			"%s Objective: compare the selected facility, file an affordable plan, or return."
			% String(office._capital_blueprint_ui.call("inspector_accessible_text")),
			1800,
		)
	if office._campus_expansion_ui != null and bool(office._campus_expansion_ui.call("is_open")):
		return _web_accessibility_text(
			"%s Objective: review the selected expansion socket, file it, or return."
			% String(office._campus_expansion_ui.call("accessible_text")),
			1800,
		)
	if office._campus_portfolio_ui != null and bool(office._campus_portfolio_ui.call("is_open")):
		return _web_accessibility_text(
			"%s Objective: review the selected parcel and module, file it, or return."
			% String(office._campus_portfolio_ui.call("accessible_text")),
			2200,
		)
	if (
		office._commissioning_reveal_ui != null
		and bool(office._commissioning_reveal_ui.call("is_reveal_visible"))
	):
		return _web_accessibility_text(
			"%s Objective: acknowledge the commissioning receipt."
			% String(office._commissioning_reveal_ui.call("accessible_text")),
			1800,
		)
	if office._day_review_scrim != null and office._day_review_scrim.visible:
		return _web_accessibility_text(
			(
				"%s. Eggs versus target: %s. Net: %s. %s. "
				+ "Next target: %s. %s. %s. Accounting details: %s "
				+ "Objective: review the close-of-shift result, then continue."
			)
			% [
				office._review_title.text if office._review_title != null else "Farmer review",
				office._review_eggs_value.text if office._review_eggs_value != null else "",
				office._review_net_value.text if office._review_net_value != null else "",
				_review_bottleneck_readout(),
				office._review_next_value.text if office._review_next_value != null else "",
				String(office._review_summary.get_meta(
					"accessible_text",
					office._review_summary.text,
				)) if office._review_summary != null else "",
				office._review_story.text if office._review_story != null else "",
				office._review_results.text if office._review_results != null else "",
			],
			2400,
		)
	var title_open := (
		office._campaign_ui != null
		and office._campaign_ui.modal_state() == ProbationCampaignUI.VIEW_TITLE
	)
	if title_open:
		var intake_phase := String(office._campaign_ui.title_intake_phase()).replace("_", " ")
		var title_snapshot := office._campaign_ui.campaign_snapshot()
		var resume_summary := office._resume_dictionary(title_snapshot.get("resume_summary"))
		var return_recap := _web_return_recap_summary(resume_summary)
		var offline_recap := _web_offline_recap_summary(resume_summary)
		var intake_objective := _campaign_intake_accessibility_objective()
		return _web_accessibility_text(
			"Pecking Order career intake is open, %s.%s%s Objective: %s"
			% [
				intake_phase,
				" %s" % return_recap if not return_recap.is_empty() else "",
				" %s" % offline_recap if not offline_recap.is_empty() else "",
				intake_objective,
			],
			1600,
		)
	if office._campaign_ui != null and office._campaign_ui.is_modal_open():
		var campaign_action := office._campaign_modal_primary_action_state()
		var action_objective := String(campaign_action.get("accessible_text", "")).strip_edges()
		return _web_accessibility_text(
			"%s%s" % [
				office._campaign_ui.accessible_text(),
				"\nObjective: %s" % action_objective if not action_objective.is_empty() else "",
			],
			2600,
		)
	if office._character_dialogue_ui != null and office._character_dialogue_ui.is_presenting():
		return _web_accessibility_text(
			"%s Objective: read or file away this character aside; the exact event remains in Flockwatch."
			% office._character_dialogue_ui.accessibility_text(),
			1600,
		)
	var first_clutch := office._first_clutch_coach_snapshot(snapshot)
	if bool(first_clutch.get("visible", false)):
		var route_choices := ""
		if (
			StringName(first_clutch.get("stage", &"")) == &"specialty_route"
			and office._routing_ui != null
			and office._routing_ui.has_method("routing_choices_accessible_text")
		):
			var choices_text := String(office._routing_ui.call(
				"routing_choices_accessible_text",
			))
			if not choices_text.is_empty():
				route_choices = " Route choices: %s." % choices_text
		return _web_accessibility_text(
			"First Clutch, step %d. %s. %s%s Objective: %s"
			% [
				int(first_clutch.get("progress", 0)) + (1 if bool(first_clutch.get("route_first_lesson", false)) else 0),
				String(first_clutch.get("title", "Orientation")),
				String(first_clutch.get("guidance", "")),
				route_choices,
				String(first_clutch.get("title", "complete the highlighted action")).to_lower(),
			],
			1600,
		)
	var objective := (
		office._campaign_objectives_label.text
		if office._campaign_objectives_label != null else
		"Observe the floor and choose the next useful intervention."
	)
	var guidance := (
		String(office._guidance_label.get_meta("accessible_text", office._guidance_label.text))
		if office._guidance_label != null else
		""
	)
	var action_feedback := ""
	if bool(office._latest_action_outcome_receipt.get("visible", false)):
		action_feedback = String(office._latest_action_outcome_receipt.get(
			"accessible_text",
			"Decision consequences filed.",
		))
	var toast := ""
	if office._ticker_panel != null and office._ticker_panel.visible:
		toast = office._ticker_visible_copy
	var speed: int = office._clock.effective_multiplier() if office._clock != null else 0
	return _web_accessibility_text(
		"Day %d, %s, speed %dx. Feed Fund $%.2f; %d of %d eggs; %d files waiting. Orders: %s Guidance: %s %s %s"
		% [
			int(office._campaign_state.completed_shifts) + 1,
			String(snapshot.get("time_label", "shift time unavailable")),
			speed,
			int(snapshot.get("revenue_cents", 0)) / 100.0,
			int(snapshot.get("eggs_today", 0)),
			int(snapshot.get("quota_target", 0)),
			int(snapshot.get("claims_waiting", 0)),
			objective,
			guidance,
			action_feedback,
			toast,
		],
		2200,
	)


## The browser keeps the full summary attached to the canvas for deliberate
## inspection. Only bounded, authored events enter its polite live region; the
## running clock and routine economy counters must never create announcement
## churn merely because the 1.5-second shell poll observed a new tick.
func _web_accessibility_announcement(snapshot: Dictionary, summary := "") -> Dictionary:
	var kind: StringName = &""
	var text := summary if not summary.is_empty() else _web_accessibility_summary(snapshot)
	var action_status_detail := _active_status_accessible_detail()
	var action_status_suffix := (
		" Latest action: %s" % action_status_detail
		if not action_status_detail.is_empty() else
		""
	)
	var held_confirmation := _active_held_confirmation_accessibility_event()
	if not held_confirmation.is_empty():
		kind = StringName(held_confirmation.get("kind", "held_confirmation"))
		text = String(held_confirmation.get("text", ""))
	elif office._settings_ui != null and office._settings_ui.is_open():
		kind = &"settings"
		text = (
			"Coop Settings and Controls opened. Objective: adjust a preference or "
			+ "control binding, then choose Return to the Floor."
		)
	elif (
		office._campus_portfolio_reveal_ui != null
		and bool(office._campus_portfolio_reveal_ui.call("is_reveal_visible"))
	):
		kind = &"campus_portfolio_reveal"
		var campus_reveal_action := (
			office._campus_portfolio_reveal_ui.call("primary_action_state") as Dictionary
		)
		text = "Campus build reveal opened. Objective: %s Receipt: %s" % [
			String(campus_reveal_action.get(
				"accessible_text",
				"Acknowledge the campus receipt and return to the prior office surface.",
			)),
			_web_accessibility_text(
				String(office._campus_portfolio_reveal_ui.call("accessible_text")),
				700,
			),
		]
	elif office._dispatch_lane != &"":
		kind = &"route_selection"
		text = _web_accessibility_text(text, 520)
	elif office._workstation_feedback != null and bool(
		office._workstation_feedback.dispatch_landing_snapshot().get("active", false)
	):
		kind = &"route_receipt"
		text = _web_accessibility_text(text, 520)
	elif office._decision_host != null and office._decision_host.visible and not office._active_decision.is_empty():
		kind = &"management_decision"
		var first_egg_choice := (
			StringName(office._active_decision.get("kind", &""))
			== Office.FIRST_CLUTCH_REINVESTMENT_KIND
		)
		var decision_title := (
			office._decision_title.text
			if office._decision_title != null else
			String(office._active_decision.get("title", "Decision required"))
		)
		var decision_selection := ""
		if not office._selected_decision_option.is_empty():
			decision_selection = " Selected %s: %s." % [
				"option" if first_egg_choice else "response",
				String(office._selected_decision_option).replace("_", " "),
			]
		var decision_preview := (
			_web_accessibility_text(String(office._decision_preview.get_meta(
				"accessible_text",
				office._decision_preview.text,
			)), 420)
			if office._decision_preview != null else
			""
		)
		var decision_action := office._decision_primary_action_state()
		var decision_objective := (
			"Objective: %s" % String(decision_action.get("accessible_text", ""))
			if not office._selected_decision_option.is_empty() else
			"Objective: choose where the first egg goes, then authorize or stay paused."
			if first_egg_choice else
			"Objective: review the response, then authorize or stay paused."
		)
		text = "%s.%s %s %s" % [
			decision_title,
			decision_selection,
			decision_preview,
			decision_objective,
		]
	elif office._flockwatch_open and office._flockwatch_navigation != null:
		kind = &"flockwatch"
		var required_flockwatch_action := office._flockwatch_navigation.context_action_accessible_text()
		var flockwatch_feedback := (
			action_status_detail
			if not action_status_detail.is_empty() else
			office._flockwatch_navigation.last_feedback()
		)
		if required_flockwatch_action.is_empty():
			text = "Flockwatch opened to %s. %s Objective: review the open filing, then close Flockwatch to return to the floor." % [
				office._flockwatch_navigation.current_page_title(),
				_web_accessibility_text(flockwatch_feedback, 360),
			]
		else:
			text = "Flockwatch opened to %s. %s Required action: %s Objective: complete it when ready, or review another filing first." % [
				office._flockwatch_navigation.current_page_title(),
				_web_accessibility_text(flockwatch_feedback, 360),
				_web_accessibility_text(required_flockwatch_action, 360),
			]
	elif office._capital_blueprint_ui != null and bool(office._capital_blueprint_ui.call("is_open")):
		kind = &"capital_plan"
		text = "Capital Blueprint opened. Objective: compare the selected facility, file an affordable plan, or return.%s" % action_status_suffix
	elif office._campus_expansion_ui != null and bool(office._campus_expansion_ui.call("is_open")):
		kind = &"campus_expansion"
		text = "Campus Expansion opened. Objective: review the selected socket, file it, or return.%s" % action_status_suffix
	elif office._campus_portfolio_ui != null and bool(office._campus_portfolio_ui.call("is_open")):
		kind = &"campus_portfolio"
		text = "Campus Portfolio opened. Objective: review the selected parcel and module, file it, or return.%s" % action_status_suffix
	elif (
		office._commissioning_reveal_ui != null
		and bool(office._commissioning_reveal_ui.call("is_reveal_visible"))
	):
		kind = &"commissioning_receipt"
		text = "Facility commissioning receipt opened. Objective: review the filed effects, then acknowledge the receipt."
	elif office._day_review_scrim != null and office._day_review_scrim.visible:
		kind = &"shift_review"
		text = "%s. Eggs versus target: %s. Net: %s. %s. Objective: review the close-of-shift result, then continue." % [
			office._review_title.text if office._review_title != null else "Farmer review",
			office._review_eggs_value.text if office._review_eggs_value != null else "unavailable",
			office._review_net_value.text if office._review_net_value != null else "unavailable",
			_review_bottleneck_readout(),
		]
	elif (
		office._campaign_ui != null
		and office._campaign_ui.modal_state() == ProbationCampaignUI.VIEW_TITLE
	):
		kind = &"career_intake"
		text = "Pecking Order career intake opened. Objective: %s%s" % [
			_campaign_intake_accessibility_objective(),
			action_status_suffix,
		]
	elif office._campaign_ui != null and office._campaign_ui.is_modal_open():
		kind = &"campaign_record"
		var campaign_action := office._campaign_modal_primary_action_state()
		var action_objective := String(campaign_action.get("accessible_text", "")).strip_edges()
		text = (
			"%s opened. Objective: %s%s" % [
				office._campaign_modal_accessibility_name(),
				action_objective,
				action_status_suffix,
			]
			if not action_objective.is_empty() else
			"Campaign record opened. Objective: review the current filing and choose the available continuation.%s" % action_status_suffix
		)
	elif office._character_dialogue_ui != null and office._character_dialogue_ui.is_presenting():
		kind = &"character_dialogue"
		text = _web_accessibility_text(
			"%s Objective: read or file away this character aside."
			% office._character_dialogue_ui.accessibility_text(),
			700,
		)
	elif bool(office._first_clutch_coach_snapshot(snapshot).get("visible", false)):
		kind = &"first_clutch"
		var first_clutch := office._first_clutch_coach_snapshot(snapshot)
		text = "First Clutch, step %d. %s. %s Objective: %s" % [
			int(first_clutch.get("progress", 0)) + (1 if bool(first_clutch.get("route_first_lesson", false)) else 0),
			String(first_clutch.get("title", "Orientation")),
			String(first_clutch.get("guidance", "")),
			String(first_clutch.get("title", "complete the highlighted action")).to_lower(),
		]
	elif bool(office._latest_action_outcome_receipt.get("visible", false)):
		kind = &"action_feedback"
		text = String(office._latest_action_outcome_receipt.get(
			"accessible_text",
			"Decision consequences filed.",
		))
	elif office._ticker_panel != null and office._ticker_panel.visible and not office._ticker_visible_copy.is_empty():
		kind = &"notification"
		text = String(
			office._ticker_label.get_meta("accessible_text", office._ticker_visible_copy)
			if office._ticker_label != null else
			office._ticker_visible_copy
		)
	else:
		return {"kind": "", "key": "", "text": ""}
	text = _web_accessibility_text(text, 1000)
	if text.is_empty():
		return {"kind": "", "key": "", "text": ""}
	return {
		"kind": String(kind),
		"key": "%s:%s" % [String(kind), str(hash(text))],
		"text": text,
	}


func _web_return_recap_summary(resume_summary: Dictionary) -> String:
	var return_recap := office._resume_dictionary(resume_summary.get("return_recap"))
	if return_recap.is_empty():
		return ""
	var last_filed := _web_accessibility_text(
		String(return_recap.get("last_filed_label", "current coop checkpoint")),
		100,
	)
	var status_label := _web_accessibility_text(
		String(return_recap.get("status_label", "current economic review")),
		100,
	)
	var status_reason := _web_accessibility_text(
		String(return_recap.get("status_reason", "")),
		240,
	)
	var next_action := _web_accessibility_text(
		String(return_recap.get("next_action", "")),
		240,
	)
	var status_prefix := (
		"Status"
		if String(return_recap.get("status_id", "")) == "clear" else
		"Unresolved"
	)
	var result := "Last filed: %s. %s: %s" % [
		last_filed,
		status_prefix,
		status_label,
	]
	if not status_reason.is_empty():
		result += ", %s" % status_reason
	if not _web_text_has_terminal_punctuation(result):
		result += "."
	if not next_action.is_empty():
		result += " Next: %s" % next_action
		if not _web_text_has_terminal_punctuation(result):
			result += "."
	var routing_mastery := office._resume_dictionary(return_recap.get("routing_mastery"))
	var routing_accessible := _web_accessibility_text(
		String(routing_mastery.get("accessible_text", "")),
		240,
	)
	if not routing_accessible.is_empty():
		result += " %s" % routing_accessible
	return _web_accessibility_text(result, 760)


func _web_offline_recap_summary(resume_summary: Dictionary) -> String:
	var offline_recap := office._resume_dictionary(resume_summary.get("offline_recap"))
	if offline_recap.is_empty():
		return ""
	var status_label := _web_accessibility_text(
		String(offline_recap.get("status_label", "ECONOMY PAUSED")),
		100,
	)
	var elapsed_label := _web_accessibility_text(
		String(offline_recap.get("elapsed_label", "SAVE TIME NOT FILED")),
		120,
	)
	var detail := _web_accessibility_text(
		String(offline_recap.get("detail", "")),
		260,
	)
	var result := "Offline: %s, %s." % [status_label, elapsed_label]
	if not detail.is_empty():
		result += " %s" % detail
	return _web_accessibility_text(result, 520)


func _web_text_has_terminal_punctuation(value: String) -> bool:
	return value.ends_with(".") or value.ends_with("!") or value.ends_with("?")


func _web_accessibility_text(value: String, limit: int) -> String:
	var compact := value.replace("\n", " ").replace("\t", " ").strip_edges()
	while "  " in compact:
		compact = compact.replace("  ", " ")
	if compact.length() > limit:
		return compact.substr(0, maxi(0, limit - 1)).strip_edges() + "…"
	return compact


func _web_control_rect(control: Control) -> Dictionary:
	if control == null:
		return {}
	var rect := control.get_global_rect()
	return {"x": rect.position.x, "y": rect.position.y, "width": rect.size.x, "height": rect.size.y}


func _compact_gameplay_pulse_diagnostic(source: Dictionary) -> Dictionary:
	# Keep the current playable loop. The omitted nested catalogs describe
	# implementation history and repeat other read models; authority and the
	# presentation tree retain the complete projection unchanged.
	var result := _diagnostic_subset(source, [
		"version", "authoritative", "core_loop", "shift_journey",
		"immediate_outcome", "action_preview", "hen_intention", "combo_readiness",
		"rival_pulse", "fail_forward", "shift_win",
	])
	result["active_playbook"] = _diagnostic_subset(source.get("active_playbook", {}) as Dictionary, [
		"day", "strategy_preset_id", "preparation_id", "recovery_id", "loadout_id",
		"dominant_objective", "shift_plan", "last_receipt", "contract", "workshop",
	])
	result["full_debug_request"] = "__pecking_order_request_diagnostic('full_gameplay_pulse')"
	return result


func _compact_first_session_funnel_diagnostic(source: Dictionary) -> Dictionary:
	# Session milestone history and teaching-script definitions remain in the
	# consent-based export and explicit debug request, not every live status poll.
	return _diagnostic_subset(source, [
		"version", "active", "authoritative", "complete", "mode", "next_id",
		"elapsed_seconds", "reached_count", "total_count", "friction_flags",
		"signals", "privacy", "opening_timing",
	])


func _live_hud_diagnostic_state() -> Dictionary:
	var controls := {}
	for control: Control in [office._day_label, office._time_label, office._revenue_label, office._quota_progress_label, office._active_playbook_button, office._guidance_action_button, office._speed_buttons[0], office._compact_speed_menu, office._next_moment_button, office._settings_button]:
		controls[String(control.name)] = {
			"rect": _web_control_rect(control),
			"visible": control.is_visible_in_tree(),
			"font_size": control.get_theme_font_size("font_size"),
		}
	return {"compact": office._compact_physical_hud, "canvas_ratio": office._hud_canvas_ratio, "rect": _web_control_rect(office._top_hud_panel), "controls": controls}


func _serialize_web_diagnostic_state(snapshot: Dictionary) -> void:
	if not OS.has_feature("web"):
		return
	var first_clutch := office._first_clutch_coach_snapshot(snapshot)
	var first_clutch_presentation := (
		office._routing_ui.first_clutch_presentation_state()
		if office._routing_ui != null and office._routing_ui.has_method("first_clutch_presentation_state") else
		{}
	) as Dictionary
	var reinvestment := office._simulation.first_clutch_reinvestment_status()
	var reinvestment_options: Array[Dictionary] = []
	for option_value in reinvestment.get("offered_options", []):
		var option := option_value as Dictionary
		reinvestment_options.append({
			"id": String(option.get("id", "")),
			"list_cost_cents": int(option.get("list_cost_cents", 0)),
			"procurement_match_cents": int(option.get("procurement_match_cents", 0)),
			"net_cost_cents": int(option.get("net_cost_cents", 0)),
			"projected_spendable_fund_cents": int(option.get("projected_spendable_fund_cents", 0)),
			"can_purchase": bool(option.get("can_purchase", false)),
		})
	var decision_rect := Rect2()
	if office._decision_panel != null:
		decision_rect = office._decision_panel.get_global_rect()
	var first_clutch_skip_rect := Rect2()
	if office._routing_ui != null and office._routing_ui.has_method("first_clutch_skip_button_rect"):
		first_clutch_skip_rect = office._routing_ui.call("first_clutch_skip_button_rect") as Rect2
	var focused_worker_id := -1
	if office._routing_ui != null:
		focused_worker_id = office._routing_ui.focused_worker_id()
	var focused_worker: Dictionary = {}
	var recommended_peck_assist_worker_id := office._simulation.recommended_peck_assist_worker_id()
	var recommended_peck_assist_worker_name := ""
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == focused_worker_id:
			focused_worker = worker
		if int(worker.get("id", -1)) == recommended_peck_assist_worker_id:
			recommended_peck_assist_worker_name = String(worker.get("name", ""))
	var contract_planning: Dictionary = {}
	if office._campaign_ui != null:
		var contract_board_ui := office._campaign_ui.contract_board_ui()
		if contract_board_ui != null and contract_board_ui.has_method("presentation_state"):
			var planning_value: Variant = contract_board_ui.call("presentation_state")
			if planning_value is Dictionary:
				contract_planning = _compact_contract_planning_diagnostic(
					planning_value as Dictionary,
				)
				contract_planning["can_sign"] = bool(contract_planning.get("sign_enabled", false))
				var effective_terms := contract_planning.get("effective_terms", {}) as Dictionary
				contract_planning["hold_reason"] = (
					"" if bool(contract_planning["can_sign"]) else String(effective_terms.get("reason", ""))
				)
	var career_forecast := office._senior_career_forecast(snapshot)
	var capital_blueprint_state := {
		"visible": false,
		"selected_facility_id": "",
		"active_filter_id": "all",
		"layout_mode": "desktop",
		"visible_facility_ids": [],
		"inspector_text": "",
	}
	if office._capital_blueprint_ui != null:
		capital_blueprint_state = {
			"visible": bool(office._capital_blueprint_ui.call("is_open")),
			"selected_facility_id": String(office._capital_blueprint_ui.call("selected_facility_id")),
			"active_filter_id": String(office._capital_blueprint_ui.call("active_filter_id")),
			"layout_mode": String(office._capital_blueprint_ui.call("layout_mode_name")),
			"visible_facility_ids": office._capital_blueprint_ui.call("visible_facility_ids"),
			"inspector_text": String(office._capital_blueprint_ui.call("inspector_accessible_text")),
		}
	var campus_planner_state := {
		"visible": false,
		"layout_mode": "desktop",
		"selected_socket_id": "meadow_west",
		"accessible_text": "",
	}
	if office._campus_expansion_ui != null:
		var campus_planner_visible := bool(office._campus_expansion_ui.call("is_open"))
		campus_planner_state["visible"] = campus_planner_visible
		campus_planner_state["layout_mode"] = String(
			office._campus_expansion_ui.call("layout_mode_name")
		)
		campus_planner_state["selected_socket_id"] = String(
			office._campus_expansion_ui.call("selected_socket_id")
		)
		if campus_planner_visible:
			campus_planner_state["accessible_text"] = String(
				office._campus_expansion_ui.call("accessible_text")
			)
	var campus_portfolio_planner_state := {
		"visible": false,
		"layout_mode": "desktop",
		"selected_parcel_id": "",
		"selected_pad_id": "",
		"selected_module_id": "",
		"accessible_text": "",
	}
	if office._campus_portfolio_ui != null:
		var portfolio_planner_visible := bool(office._campus_portfolio_ui.call("is_open"))
		campus_portfolio_planner_state["visible"] = portfolio_planner_visible
		campus_portfolio_planner_state["layout_mode"] = String(
			office._campus_portfolio_ui.call("layout_mode_name")
		)
		campus_portfolio_planner_state["selected_parcel_id"] = String(
			office._campus_portfolio_ui.call("selected_parcel_id")
		)
		campus_portfolio_planner_state["selected_pad_id"] = String(
			office._campus_portfolio_ui.call("selected_pad_id")
		)
		campus_portfolio_planner_state["selected_module_id"] = String(
			office._campus_portfolio_ui.call("selected_module_id")
		)
		if portfolio_planner_visible:
			campus_portfolio_planner_state["accessible_text"] = String(
				office._campus_portfolio_ui.call("accessible_text")
			)
	var commissioning_state := {"visible": false, "receipt": {}, "accessible_text": ""}
	if office._commissioning_reveal_ui != null:
		commissioning_state = {
			"visible": bool(office._commissioning_reveal_ui.call("is_reveal_visible")),
			"receipt": office._commissioning_reveal_ui.call("receipt_snapshot"),
			"accessible_text": String(office._commissioning_reveal_ui.call("accessible_text")),
		}
	var campus_portfolio_reveal_state := {
		"visible": false,
		"receipt": {},
		"context": {},
		"accessible_text": "",
		"reduced_motion": false,
	}
	if office._campus_portfolio_reveal_ui != null:
		var reveal_state_value: Variant = office._campus_portfolio_reveal_ui.call("presentation_state")
		if reveal_state_value is Dictionary:
			campus_portfolio_reveal_state = (reveal_state_value as Dictionary).duplicate(true)
	var settings_state := {
		"visible": office._settings_ui != null and office._settings_ui.is_open(),
		"active_category": (
			String(office._settings_ui.active_category())
			if office._settings_ui != null else
			String(office._player_preferences.get("settings_category", "comfort"))
		),
		"settings_category": String(
			office._player_preferences.get("settings_category", "comfort")
		),
		"available_categories": ["audio", "comfort", "controls", "career"],
		"accessible_text": (
			office._settings_ui.accessible_text()
			if office._settings_ui != null and office._settings_ui.is_open() else ""
		),
		"motion_mode": String(office._player_preferences.get("motion_mode", "system")),
		"reduced_motion_active": office._prefers_reduced_motion(),
		"ui_scale": float(office._player_preferences.get("ui_scale", 1.0)),
		"high_contrast": bool(office._player_preferences.get("high_contrast", false)),
		"color_vision_mode": String(office._player_preferences.get("color_vision_mode", "standard")),
		"browser_mirror_status": office._web_preferences_mirror_status,
		"visual_quality": String(office._player_preferences.get("visual_quality", "balanced")),
		"timing_assist": String(office._player_preferences.get("timing_assist", "standard")),
		"notice_level": String(office._player_preferences.get("notice_level", "all")),
		"notice_duration": String(office._player_preferences.get("notice_duration", "standard")),
		"effect_level": String(office._player_preferences.get("effect_level", "full")),
		"particle_level": String(office._player_preferences.get("particle_level", "full")),
		"camera_motion": String(office._player_preferences.get("camera_motion", "full")),
		"camera_sensitivity": String(
			office._player_preferences.get("camera_sensitivity", "standard")
		),
		"animation_speed": String(office._player_preferences.get("animation_speed", "standard")),
		"animation_speed_multiplier": office._animation_speed_multiplier,
		"tooltip_delay": String(office._player_preferences.get("tooltip_delay", "standard")),
		"tooltip_delay_seconds": Office.PlayerPreferencesStoreScript.tooltip_delay_seconds(
			String(office._player_preferences.get("tooltip_delay", "standard"))
		),
		"guidance_mode": String(office._player_preferences.get("guidance_mode", "full")),
		"first_clutch_replay_available": office._first_clutch_can_reopen(),
		"first_clutch_reference": (
			office._settings_ui.first_clutch_reference_state()
			if office._settings_ui != null else
			{
				"mode": "review",
				"playbook_visible": false,
				"step_count": 5,
				"mutates_campaign": false,
			}
		),
		"haptics_enabled": bool(office._player_preferences.get("haptics_enabled", true)),
		"pause_when_unfocused": bool(office._player_preferences.get("pause_when_unfocused", true)),
		"focus_pause_active": office._focus_pause_active,
		"focus_pause_restore_speed": office._focus_pause_previous_speed,
		"dialogue_pause_restore_speed": office._character_dialogue_previous_speed,
		"audio": (office._player_preferences.get("audio", {}) as Dictionary).duplicate(true),
		"bindings": office._current_binding_labels(),
	}
	var challenge_contract: Dictionary = office._campaign_state.challenge_contract_snapshot()
	var selected_new_challenge_contract: Dictionary = {}
	var resume_challenge_contract: Dictionary = {}
	var resume_return_recap: Dictionary = {}
	var resume_offline_recap: Dictionary = {}
	var resume_available := false
	var resume_senior_roost := false
	var campaign_intake_phase := ""
	var campaign_strategy_receipt: Dictionary = {}
	var title_open := (
		office._campaign_ui != null
		and office._campaign_ui.modal_state() == ProbationCampaignUI.VIEW_TITLE
		and office._campaign_ui.has_method("selected_challenge_contract_id")
	)
	if title_open:
		campaign_intake_phase = String(office._campaign_ui.title_intake_phase())
		var title_contract := Office.CampaignStateScript.challenge_contract(
			StringName(office._campaign_ui.call("selected_challenge_contract_id"))
		)
		if not title_contract.is_empty():
			challenge_contract = title_contract
			selected_new_challenge_contract = title_contract.duplicate(true)
		var title_snapshot := office._campaign_ui.campaign_snapshot()
		resume_available = office._resume_boolean(
			title_snapshot.get("continue_available", title_snapshot.get("has_continue")),
			false,
		)
		var resume_summary := office._resume_dictionary(title_snapshot.get("resume_summary"))
		resume_return_recap = office._resume_dictionary(resume_summary.get("return_recap"))
		resume_offline_recap = office._resume_dictionary(resume_summary.get("offline_recap"))
		resume_senior_roost = office._resume_boolean(resume_summary.get("senior_roost"), false)
		if resume_available and not resume_senior_roost:
			var resume_contract_value := office._resume_dictionary(
				resume_summary.get("challenge_contract")
			)
			var resume_contract_id_value: Variant = resume_contract_value.get("id")
			if resume_contract_id_value is String or resume_contract_id_value is StringName:
				resume_challenge_contract = Office.CampaignStateScript.challenge_contract(
					StringName(String(resume_contract_id_value))
				)
	if office._campaign_ui != null:
		var strategy_value: Variant = office._campaign_ui.campaign_snapshot().get(
			"strategy_receipt",
			{},
		)
		if strategy_value is Dictionary:
			campaign_strategy_receipt = (strategy_value as Dictionary).duplicate(true)
	var active_filing_id := (
		office._flockwatch_navigation.current_page_id()
		if office._flockwatch_open and office._flockwatch_navigation != null else
		&""
	)
	var capital_filing_open := active_filing_id == FlockwatchNavigation.PAGE_CAPITAL
	var operations_filing_open := active_filing_id == FlockwatchNavigation.PAGE_OPERATIONS

	var capital_source := snapshot.get("capital_plan", {}) as Dictionary
	var compact_capital_plan := _compact_capital_plan_diagnostic(capital_source)
	var capital_diagnostic := {
		"upgrade_levels": snapshot.get("upgrade_levels", {}),
		"owned_facilities": snapshot.get("owned_facilities", {}),
		"facility_effects": snapshot.get("facility_effects", {}),
		"packing_contract": snapshot.get("packing_contract", {}),
		"capital_plan": _diagnostic_subset(
			compact_capital_plan,
			["has_pinned_plan", "pinned_capital_plan_id", "facility"],
		),
		"last_facility_purchase_receipt": _diagnostic_subset(
			_compact_facility_receipt_diagnostic(
				snapshot.get("last_facility_purchase_receipt", {}) as Dictionary,
			),
			[
				"accepted", "action_id", "day", "facility_id", "facility_name",
				"purchased_level", "cost_cents",
			],
		),
		"facility_catalog": (
			_compact_facility_catalog_diagnostic(snapshot.get("facility_catalog", []))
			if capital_filing_open or bool(capital_blueprint_state.get("visible", false)) else
			[]
		),
	}
	var portfolio_source := snapshot.get("campus_portfolio", {}) as Dictionary
	var portfolio_diagnostic := _compact_campus_portfolio_diagnostic(portfolio_source)
	var expansion_source := snapshot.get("campus_expansion", {}) as Dictionary
	var expansion_diagnostic := _compact_campus_expansion_diagnostic(expansion_source)
	var contract_source := snapshot.get("contract_board", {}) as Dictionary
	var contract_diagnostic := _compact_contract_board_diagnostic(
		contract_source,
		office._campaign_review_stage == &"contract_board",
	)
	var care_source := snapshot.get("flock_care", {}) as Dictionary
	var care_diagnostic := _compact_flock_care_diagnostic(care_source)
	var operations_source := snapshot.get("operations", {}) as Dictionary
	var operations_diagnostic := _compact_operations_diagnostic(
		operations_source,
		_operations_staffing_details_visible(
			operations_filing_open,
			_active_held_confirmation_surface(),
		),
	)
	var runtime_performance := _runtime_performance_diagnostic()
	runtime_performance.merge({
		"authoritative_tick_revision": int(snapshot.get("authoritative_tick_revision", 0)),
		"last_presented_tick_revision": office._last_presented_tick_revision,
		"presentation_update_count": office._presentation_update_count,
		"cost_probe": office._simulation.cost_probe.snapshot(),
		"hen_identity_resources": {
			"record_meshes": HenDeskIdentity._records.size(),
			"hardware_meshes": HenDeskIdentity._hardware.size(),
			"finish_materials": ChickenView._identity_materials.size(),
		},
		"snapshot_presentation_usec": office._snapshot_presentation_usec,
		"workstation_surface_writes": office._workstation_feedback.presentation_write_counts() if office._workstation_feedback != null else {},
		"snapshot_presentation_timing": office._snapshot_presentation_timing.duplicate(),
		"gameplay_pulse_timing": office._gameplay_pulse_timing.duplicate(),
		"director_stages": office._gameplay_pulse_director.last_compose_timing.duplicate() if office._gameplay_pulse_director != null else {},
		"playbook_menu_build_count": office._active_playbook_menu_build_count,
		"routing_refresh": office._routing_ui.runtime_refresh_diagnostic() if office._routing_ui != null else {},
		"ticks_advanced_last_frame": office._clock.ticks_advanced_last_frame(),
		"pending_tick_count": office._clock.pending_tick_count(),
		"runtime_projection_cache": (
			office._simulation.runtime_projection_cache_diagnostics()
			if office._simulation != null else
			{}
		),
		"diagnostic_publish_mode": "on_demand",
	}, true)
	var diagnostic_directive := snapshot.get("active_directive", {}) as Dictionary
	var active_policy_order_fit := (
		office._directive_order_fit(StringName(diagnostic_directive.get("id", &"")))
		if not diagnostic_directive.is_empty() and not office._campaign_senior_roost else
		{}
	)
	var senior_diagnostic := {"status": "inactive"}
	if office._senior_roost_state != null and office._senior_roost_state.is_active():
		senior_diagnostic = office._senior_roost_state.snapshot()
		if office._senior_roost_state.requires_quarter_policy():
			senior_diagnostic["quarterly_policy_offers"] = (
				office._senior_roost_state.policy_catalog(office._simulation.spendable_fund_cents())
			)
		if office._campaign_ui != null:
			var campaign_presentation := office._campaign_ui.campaign_snapshot()
			var pending_mandate_confirmation := campaign_presentation.get(
				"pending_milestone_confirmation",
				{},
			) as Dictionary
			if not pending_mandate_confirmation.is_empty():
				senior_diagnostic["pending_mandate_confirmation"] = (
					pending_mandate_confirmation.duplicate(true)
				)
	var routing_interaction_safety: Dictionary = {}
	if office._routing_ui != null and office._routing_ui.has_method("interaction_safety_state"):
		routing_interaction_safety = office._routing_ui.interaction_safety_state()
	var staffing_interaction_safety: Dictionary = {}
	if office._staffing_ui != null and office._staffing_ui.has_method("interaction_safety_state"):
		staffing_interaction_safety = office._staffing_ui.interaction_safety_state()
	var held_confirmation_surface := _active_held_confirmation_surface()
	var interaction_safety_diagnostic := _compact_interaction_safety_diagnostic({
		"routing": routing_interaction_safety,
		"staffing": staffing_interaction_safety,
		"confirmation_backdrop": {
			"visible": (
				office._held_confirmation_scrim != null
				and office._held_confirmation_scrim.visible
			),
			"surface": held_confirmation_surface,
			"alpha": (
				office._held_confirmation_scrim.color.a
				if office._held_confirmation_scrim != null else
				0.0
			),
			"blocks_pointer": (
				office._held_confirmation_scrim != null
				and office._held_confirmation_scrim.mouse_filter == Control.MOUSE_FILTER_STOP
			),
			"flockwatch_page": (
				String(office._flockwatch_navigation.current_page_id())
				if office._flockwatch_navigation != null else
				""
			),
		},
	})
	var egg_journey_source := {
		"receipts": office._egg_journey_receipt_snapshot(),
		"focused_receipt": (
			office._routing_ui.egg_journey_receipt_state()
			if office._routing_ui != null and office._routing_ui.has_method("egg_journey_receipt_state") else
			{"visible": false}
		),
		"world_acknowledgments": (
			office._workstation_feedback.egg_delivery_ack_snapshot()
			if office._workstation_feedback != null and office._workstation_feedback.has_method("egg_delivery_ack_snapshot") else
			{"pooled_marker_count": 0, "active_count": 0, "acknowledgments": []}
		),
		"fund_credit_batches": fund_credit_batch_snapshot(),
		"auxiliary_settlements": auxiliary_settlement_snapshot(),
		"settlement_placement": settlement_feedback_placement_snapshot(),
		"settlement_arbitration": settlement_feedback_arbitration_snapshot(),
		"settlement_destinations": settlement_destination_ack_snapshot(),
		"fund_debits": fund_debit_feedback_snapshot(),
	}
	var egg_journey_diagnostic := _compact_egg_journey_diagnostic(egg_journey_source)
	var hen_intents: Array[Dictionary] = []
	var flock_bonds: Array[Dictionary] = []
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if not bool(worker.get("employed", false)):
			continue
		var worker_id := int(worker.get("id", -1))
		var intent := worker.get("hen_intent", {}) as Dictionary
		var intent_marker: Sprite3D
		var worker_view := office._worker_views.get(worker_id) as ChickenView
		if worker_view != null and is_instance_valid(worker_view):
			intent_marker = worker_view.find_child("HenIntentMarker", true, false) as Sprite3D
		var intent_diagnostic := {
			"worker_id": worker_id,
			"expression": worker_view.expression_snapshot() if worker_view != null else {},
			"worker_name": String(worker.get("name", "")),
			"id": String(intent.get("id", "")),
			"icon": String(intent.get("icon", "")),
			"action_id": String(intent.get("action_id", "")),
			"action_label": String(intent.get("action_label", "")),
			"urgency": int(intent.get("urgency", 0)),
			"world_semantic_shape": String(
				intent_marker.get_meta("semantic_shape", &"status_pin")
				if intent_marker != null else
				&"status_pin"
			),
			"priority_peck_ready_pulse_serial": int(
				intent_marker.get_meta("priority_peck_ready_serial", 0)
				if intent_marker != null else
				0
			),
			"priority_peck_ready_pulse_active": (
				bool(intent_marker.get_meta("priority_peck_ready_active", false))
				if intent_marker != null else
				false
			),
			"priority_peck_missed_pulse_serial": int(
				intent_marker.get_meta("priority_peck_missed_serial", 0)
				if intent_marker != null else
				0
			),
			"priority_peck_missed_pulse_active": (
				bool(intent_marker.get_meta("priority_peck_missed_active", false))
				if intent_marker != null else
				false
			),
		}
		var focus_role := String(
			intent_marker.get_meta("focus_role", &"peer")
			if intent_marker != null else
			&"peer"
		)
		var focus_size := float(
			intent_marker.get_meta("focus_size_scale", 1.0)
			if intent_marker != null else
			1.0
		)
		var focus_lift := float(
			intent_marker.get_meta("focus_height_lift", 0.0)
			if intent_marker != null else
			0.0
		)
		var selection_halo := (
			bool(intent_marker.get_meta("selection_halo_visible", false))
			if intent_marker != null else
			false
		)
		var world_alpha := intent_marker.modulate.a if intent_marker != null else 1.0
		if focus_role != "peer":
			intent_diagnostic["world_focus_role"] = focus_role
		if not is_equal_approx(focus_size, 1.0):
			intent_diagnostic["world_focus_size_scale"] = focus_size
		if not is_zero_approx(focus_lift):
			intent_diagnostic["world_focus_height_lift"] = focus_lift
		if selection_halo:
			intent_diagnostic["world_selection_halo_visible"] = true
		if not is_equal_approx(world_alpha, 1.0):
			intent_diagnostic["world_alpha"] = world_alpha
		var team_lift_state := (
			worker_view.team_lift_feedback_state()
			if worker_view != null and is_instance_valid(worker_view) else
			{}
		)
		intent_diagnostic["team_lift"] = (
			team_lift_state
			if bool(team_lift_state.get("active", false))
				or int(team_lift_state.get("serial", 0)) > 0 else
			{"active": false}
		)
		var signature_state := (
			worker_view.signature_feedback_state()
			if worker_view != null and is_instance_valid(worker_view) else
			{}
		)
		intent_diagnostic["signature_move"] = (
			signature_state
			if bool(signature_state.get("active", false))
				or int(signature_state.get("serial", 0)) > 0 else
			{"active": false}
		)
		hen_intents.append(intent_diagnostic)
		var bond := worker.get("flock_bond", {}) as Dictionary
		var bond_score := int(bond.get("score", 50))
		flock_bonds.append({
			"worker_id": int(worker.get("id", -1)),
			"partner_id": int(bond.get("partner_id", -1)),
			"partner_name": String(bond.get("partner_name", "")),
			"score": bond_score,
			"label": String(bond.get("label", "")),
			"world_signal": (
				"clutchmates" if bond_score >= 75 else
				"good_perch" if bond_score >= 60 else
				"withdrawn" if bond_score < 30 else
				"quiet"
			),
		})
		if hen_intents.size() >= 6:
			break
	var breakroom_interactions: Array[Dictionary] = []
	var sorted_worker_ids := office._worker_views.keys()
	sorted_worker_ids.sort()
	for worker_id_value in sorted_worker_ids:
		var interaction_view := office._worker_views.get(worker_id_value) as ChickenView
		if interaction_view == null or not is_instance_valid(interaction_view):
			continue
		var interaction := interaction_view.break_interaction_state()
		interaction["worker_id"] = int(worker_id_value)
		breakroom_interactions.append(interaction)
	var state := {
		"coordinate_system": "Canvas origin is top-left; +x right, +y down; authored stage 1280x720.",
		"mode": "godot_canvas",
		"controls": [
			"click hen",
			"middle-drag, touch-drag, WASD, arrows, or left stick to pan",
			"wheel, pinch, plus/minus, or right stick to zoom",
			"Home, Escape, or right click for office overview",
			"route file",
			"%s priority peck" % office._action_hint(Office.PECK_ASSIST_ACTION),
			"1-3 binder or speed",
			"N negotiate",
			"R standard terms",
			"Enter authorize",
			"D standard book",
			"C continue",
			"%s select rider or pause" % office._action_hint(&"pause_simulation"),
			"%s advance safely to the next moment" % office._action_hint(Office.NEXT_MOMENT_ACTION),
			"%s Flockwatch" % office._action_hint(&"toggle_flockwatch"),
			"%s Feed Party" % office._action_hint(&"fund_feed_party"),
			"%s after-hours pecking" % office._action_hint(&"toggle_overtime"),
			"%s settings and controls" % office._action_hint(&"open_settings"),
		],
		"loaded": true,
		"accessibility_announcement": _web_accessibility_announcement(snapshot),
		"boot": boot_timing_snapshot(),
		"camera": (
			office._camera_controller.navigation_state()
			if office._camera_controller != null and office._camera_controller.has_method("navigation_state") else
			{}
		),
		"office_presentation": office_physical_presentation_snapshot(),
		"breakroom": {
			"station_count": 6,
			"interactions": breakroom_interactions,
		},
		"manager_command_station": (
			office._management_presence.command_station_snapshot()
			if office._management_presence != null else
			{"physical": false}
		),
		"capacity_commissioning": capacity_commissioning_snapshot(),
		"audio": {
			"director": (
				office._audio_director.call("mix_snapshot")
				if office._audio_director != null and office._audio_director.has_method("mix_snapshot") else
				{}
			),
			"feedback": (
				office._audio_feedback.call("feedback_snapshot")
				if office._audio_feedback != null and office._audio_feedback.has_method("feedback_snapshot") else
				{}
			),
		},
		"settings": settings_state,
		"interaction_safety": interaction_safety_diagnostic,
		"notifications": _notification_diagnostic_state(),
		"routing_return_cue": _routing_return_cue_diagnostic_state(),
		"adaptive_routing_recovery": office._adaptive_route_recovery_diagnostic_state(),
		"routing_lifecycle": (
			office._routing_ui.routing_lifecycle_state()
			if office._routing_ui != null and office._routing_ui.has_method("routing_lifecycle_state") else
			{"visible": false}
		),
		"routing_queue_strip": (
			office._routing_ui.queue_strip_state()
			if office._routing_ui != null and office._routing_ui.has_method("queue_strip_state") else
			{"visible": false}
		),
		"routing_choices": (
			office._routing_ui.routing_choice_state()
			if office._routing_ui != null and office._routing_ui.has_method("routing_choice_state") else
			{"visible": false, "choices": []}
		),
		"dossier_tabs": (
			office._routing_ui.dossier_tab_state()
			if office._routing_ui != null and office._routing_ui.has_method("dossier_tab_state") else
			{"visible": false, "tabs": []}
		),
		"selected_hen_identity": (
			office._routing_ui.selected_hen_identity_state()
			if office._routing_ui != null and office._routing_ui.has_method("selected_hen_identity_state") else
			{"visible": false}
		),
		"next_action": office._next_action_diagnostic_state(),
		"gameplay_pulse": _compact_gameplay_pulse_diagnostic(office._gameplay_pulse),
		"shift_challenge": office._shift_challenge_ui.snapshot() if office._shift_challenge_ui != null else {"visible": false},
		"cause_replay": office._last_cause_replay.duplicate(true),
		"explain_mode": {
			"active": office._explain_mode_active,
			"visible": office._explain_strip != null and office._explain_strip.visible,
			"input": "H",
			"chip_count": office._explain_chip_labels.size(),
			"projection": (
				office._explain_strip.get_meta("projection", {}) as Dictionary
				if office._explain_strip != null else
				{}
			),
		},
		"manager_power": {
			"input": "Q",
			"visible": office._active_playbook_button != null and office._active_playbook_button.visible,
			"ready": bool(((office._gameplay_pulse.get("mastery_replay", {}) as Dictionary).get(
				"manager_power", {},
			) as Dictionary).get("ready", false)),
			"popup_visible": (
				office._active_playbook_button != null
				and office._active_playbook_button.get_popup().visible
			),
			"files_on_press": false,
		},
		"next_moment": _next_moment_diagnostic_state(snapshot),
		"clutch_reward_ladder": office._clutch_reward_ladder_snapshot(
			int(snapshot.get("quality_streak", 0))
		),
		"action_feedback": office._latest_action_outcome_receipt.duplicate(true),
		"egg_journey": egg_journey_diagnostic,
		"character_dialogue": (
			office._character_dialogue_ui.diagnostic_state()
			if office._character_dialogue_ui != null else
			{"visible": false, "queued_count": 0}
		),
		"internship_program": (
			office._staffing_ui.internship_program_diagnostic_state()
			if office._staffing_ui != null else
			{"visible": false, "candidate_count": 0}
		),
		"flockwatch": _flockwatch_diagnostic_state(),
		"commendations": _commendations_diagnostic_state(),
		"checkpoint": _checkpoint_diagnostic_state(),
		"first_session_funnel": _compact_first_session_funnel_diagnostic(office._first_session_funnel.snapshot()),
		"personal_shift_goal": office._personal_goal.duplicate(true),
		"personal_goal_offer": office._personal_goal_offer.duplicate(true),
		"goal_browse_control": {"visible": office._review_remix_button != null and office._review_remix_button.is_visible_in_tree(), "rect": _web_control_rect(office._review_remix_button)},
		"review_contribution": office._review_story.text if office._review_story != null else "",
		"quiet_hud": {"details_visible": office._explain_strip != null and office._explain_strip.visible, "loop_counters_visible": office._core_loop_host != null and office._core_loop_host.is_visible_in_tree(), "reward_counters_visible": office._reward_loop_host != null and office._reward_loop_host.is_visible_in_tree(), "clock": office._time_label.text if office._time_label != null else "", "goal": office._quality_streak_label.text if office._quality_streak_label != null else ""},
		"care_lesson": office._routing_ui.care_lesson_state(),
		"personal_goal_control": {
			"visible": office._personal_goal_button != null and office._personal_goal_button.is_visible_in_tree(),
			"label": office._personal_goal_button.text if office._personal_goal_button != null else "",
			"rect": _web_control_rect(office._personal_goal_button),
		},
		"campaign_stage": "title" if title_open else String(office._campaign_review_stage),
		"campaign_intake_phase": campaign_intake_phase,
		"campaign_day": int(office._campaign_state.completed_shifts) + 1,
		"campaign_score": int(office._campaign_state.probation_score),
		"shift_continuity": office._shift_continuity.duplicate(true),
		"campaign_strategy_receipt": campaign_strategy_receipt,
		"probation_order_tracker": (
			office._campaign_ui.live_order_progress()
			if office._campaign_ui != null else
			{}
		),
		"case_docket": (snapshot.get("case_docket", {}) as Dictionary).duplicate(true),
		"challenge_contract": challenge_contract,
		"selected_new_challenge_contract": selected_new_challenge_contract,
		"resume_challenge_contract": resume_challenge_contract,
		"resume_return_recap": resume_return_recap,
		"resume_offline_recap": resume_offline_recap,
		"routing_review": office._resume_dictionary(office._last_workday_report.get("routing_review")),
		"resume_available": resume_available,
		"resume_senior_roost": resume_senior_roost,
		"probation_safeguards": _compact_probation_safeguards_diagnostic(
			office._campaign_state.probation_safeguard_forecast(),
		),
		"probation_doctrine": _probation_doctrine_snapshot(),
		"senior_roost": senior_diagnostic,
		"career_forecast": career_forecast.duplicate(true),
		"career_sponsorship": (
			office._career_sponsorship_presentation_snapshot()
			if office._campaign_senior_roost else
			{"visible": false}
		),
		"flock_care": care_diagnostic,
		"operations": operations_diagnostic,
		"flock_relations": (snapshot.get("flock_relations", {}) as Dictionary).duplicate(true),
		"feed_procurement": _diagnostic_without(
			snapshot.get("feed_procurement", {}) as Dictionary,
			["offers", "history", "order_history"],
		),
		"farm_treasury": (snapshot.get("farm_treasury", {}) as Dictionary).duplicate(true),
		"farmer_relations_gallery": _diagnostic_without(
			office._farmer_relations_gallery_projection(snapshot),
			["offers", "history"],
		),
		"farmgate_dispatch": _diagnostic_without(
			snapshot.get("farmgate_dispatch", {}) as Dictionary,
			["mandates", "lots", "history"],
		),
		"campus_expansion": expansion_diagnostic,
			"campus_expansion_planner": campus_planner_state,
			"campus_portfolio": portfolio_diagnostic,
			"campus_portfolio_planner": campus_portfolio_planner_state,
		"capital_plan": compact_capital_plan,
		"capital_blueprint": capital_blueprint_state,
		"commissioning_reveal": commissioning_state,
		"campus_portfolio_reveal": campus_portfolio_reveal_state,
		"shift_phase": int(snapshot.get("shift_phase", -1)),
		"clock_speed_index": office._clock.speed_index,
		"clock_multiplier": SimulationClock.SPEED_MULTIPLIERS[office._clock.speed_index],
		"clock_effective_multiplier": office._clock.effective_multiplier(),
		"clock_interaction_hold_active": office._clock.interaction_hold_active(),
		"pause_context": office._pause_context_state(),
		"priority_peck_focus": {
			"active": office._clock.precision_focus_active(),
			"limiting": office._clock.precision_focus_limiting(),
			"worker_id": office._priority_peck_focus_worker_id,
			"requested_multiplier": SimulationClock.SPEED_MULTIPLIERS[office._clock.speed_index],
			"effective_multiplier": office._clock.effective_multiplier(),
			"result_hold_msec_remaining": maxi(0, office._priority_peck_result_hold_until_msec - Time.get_ticks_msec()),
			"result_hold_kind": String(office._priority_peck_result_hold_kind),
			"rearm_required": office._priority_peck_focus_disarmed_worker_id >= 0,
			"next_action_handoff": (
				office._routing_ui.peck_result_focus_handoff_state()
				if office._routing_ui != null else
				{"status": "unavailable"}
			),
			"missed_link_serial": int(
				office._routing_ui.get_meta("peck_missed_link_serial", 0)
				if office._routing_ui != null else
				0
			),
			"missed_link_animated": (
				bool(office._routing_ui.get_meta("peck_missed_link_animated", false))
				if office._routing_ui != null else
				false
			),
		},
		"performance": runtime_performance,
		"pending_decision_kind": String(office._active_decision.get("kind", "")),
		"pending_decision": _pending_decision_diagnostic_state(),
		"contract_board": contract_diagnostic,
		"contract_planning": contract_planning,
		"first_clutch": {
			"route_first_lesson": bool(office._first_clutch.get("route_first_lesson", false)),
			"primary_button": office._routing_ui.first_clutch_action_state() if office._routing_ui != null else {},
			"visible": bool(first_clutch.get("visible", false)),
			"dismissed": bool(office._first_clutch.get("dismissed", true)),
			"can_skip": bool(first_clutch.get("can_skip", false)),
			"stage": String(first_clutch.get("stage", "")),
			"progress": int(first_clutch.get("progress", 0)),
			"title": String(first_clutch.get("title", "")),
			"visual_title": String(first_clutch.get("visual_title", first_clutch.get("title", ""))),
			"guidance": String(first_clutch.get("guidance", "")),
			"dossier_summary_copy": String(first_clutch_presentation.get("dossier_summary_copy", "")),
			"dossier_summary_accessible_text": String(first_clutch_presentation.get("dossier_summary_accessible_text", "")),
			"dossier_summary_role": String(first_clutch_presentation.get("dossier_summary_role", "dossier_detail")),
			"primary_action_shortcut": String(first_clutch.get("primary_action_shortcut", "")),
			"target_worker_id": int(first_clutch.get("target_worker_id", -1)),
			"first_hen_prelude": bool(first_clutch.get("pre_policy", false)),
			"target_name": String(first_clutch.get("target_name", "")),
			"orders_handoff_pending": bool(first_clutch.get("orders_handoff_pending", false)),
			"orders_handoff_acknowledged": bool(office._first_clutch.get("orders_handoff_acknowledged", false)),
			"skip_button_rect": {
				"x": first_clutch_skip_rect.position.x,
				"y": first_clutch_skip_rect.position.y,
				"width": first_clutch_skip_rect.size.x,
				"height": first_clutch_skip_rect.size.y,
			},
			"reinvestment": {
				"status": String(reinvestment.get("status", &"unavailable")),
				"modal_visible": (
					office._decision_host != null
					and office._decision_host.visible
					and StringName(office._active_decision.get("kind", &"")) == Office.FIRST_CLUTCH_REINVESTMENT_KIND
				),
				"selected_choice": String(office._selected_decision_option),
				"confirm_enabled": office._decision_confirm_button != null and not office._decision_confirm_button.disabled,
				"card_rect": {
					"x": decision_rect.position.x,
					"y": decision_rect.position.y,
					"width": decision_rect.size.x,
					"height": decision_rect.size.y,
				},
				"created_value_cents": int(reinvestment.get("created_value_cents", 0)),
				"fund_at_collection_cents": int(reinvestment.get("fund_at_collection_cents", 0)),
				"protected_reserve_cents": int(reinvestment.get("protected_reserve_cents", 0)),
				"spendable_at_collection_cents": int(reinvestment.get("spendable_at_collection_cents", 0)),
				"procurement_match_available_cents": int(reinvestment.get("procurement_match_available_cents", 0)),
				"choice_id": String(reinvestment.get("choice_id", &"")),
				"selected_list_cost_cents": int(reinvestment.get("selected_list_cost_cents", 0)),
				"procurement_match_used_cents": int(reinvestment.get("procurement_match_used_cents", 0)),
				"net_cost_cents": int(reinvestment.get("net_cost_cents", 0)),
				"fund_after_cents": int(reinvestment.get("fund_after_cents", 0)),
				"spendable_after_cents": int(reinvestment.get("spendable_after_cents", 0)),
				"options": reinvestment_options,
			},
		},
		"focused_worker_id": focused_worker_id,
		"hen_intents": hen_intents,
		"hen_social": office._hen_social.snapshot(),
		"flock_ties": office._flock_ties_ui.snapshot() if office._flock_ties_ui != null else {"visible": false},
		"hen_social_ui": office._hen_social_ui.diagnostic_state() if office._hen_social_ui != null else {},
		"flock_bonds": flock_bonds,
		"focused_hen_intent": (
			focused_worker.get("hen_intent", {}) as Dictionary
		).duplicate(true),
		"economy": {
			"feed_fund_cents": int(snapshot.get("revenue_cents", 0)),
			"spendable_fund_cents": int(snapshot.get("spendable_fund_cents", 0)),
			"daily_operating_cost_cents": int(snapshot.get("daily_operating_cost_cents", 0)),
			"daily_feed_cost_cents": int(snapshot.get("daily_feed_cost_cents", 0)),
			"daily_payroll_cents": int(snapshot.get("daily_payroll_cents", 0)),
			"daily_hen_payroll_cents": int(snapshot.get("daily_hen_payroll_cents", 0)),
			"daily_supervisor_payroll_cents": int(
				snapshot.get("daily_supervisor_payroll_cents", 0)
			),
			"daily_fellow_payroll_cents": int(
				snapshot.get("daily_fellow_payroll_cents", 0)
			),
			"daily_facility_cost_cents": int(snapshot.get("daily_facility_cost_cents", 0)),
			"wage_arrears_cents": int(snapshot.get("wage_arrears_cents", 0)),
			# The complete briefing projection is already rendered and narrated by
			# Flockwatch. Mirroring its large strategy/offer ledger here duplicated
			# presentation-only data on every Web diagnostic tick.
		},
		"production": {
			"claims_waiting": int(snapshot.get("claims_waiting", 0)),
			"claims_outstanding": int(snapshot.get("claims_outstanding", 0)),
			"claim_capacity": int(snapshot.get("claim_capacity", 18)),
			"intake_rejections_today": int(snapshot.get("intake_rejections_today", 0)),
			"intake_rejections_total": int(snapshot.get("intake_rejections_total", 0)),
			"intake_missed_value_today_cents": int(snapshot.get("intake_missed_value_today_cents", 0)),
			"intake_missed_value_total_cents": int(snapshot.get("intake_missed_value_total_cents", 0)),
			"focused_claim": (focused_worker.get("current_claim", {}) as Dictionary).duplicate(true),
			"focused_progress": float(focused_worker.get("progress", 0.0)),
			"focused_peck_assist": (focused_worker.get("peck_assist", {}) as Dictionary).duplicate(true),
			"recommended_peck_assist_worker_id": recommended_peck_assist_worker_id,
			"recommended_peck_assist_worker_name": recommended_peck_assist_worker_name,
			"peck_assists_remaining": int(snapshot.get("peck_assists_remaining", 0)),
			"last_peck_assist": (snapshot.get("last_peck_assist", {}) as Dictionary).duplicate(true),
			"feed_party_used_today": bool(snapshot.get("feed_party_used_today", false)),
			"feed_party_active": office._feed_party_active,
			"feed_party_expected_attendees": office._feed_party_expected_attendees.size(),
			"feed_party_arrivals": office._feed_party_arrivals.size(),
			"feed_party_returns": office._feed_party_returns.size(),
		},
		"dispatch": _dispatch_diagnostic_state(),
		"capital": capital_diagnostic,
		"orders": {
			"on_track": int(office._campaign_objectives_label.get_meta("orders_on_track", 0)),
			"total": int(office._campaign_objectives_label.get_meta("orders_total", 0)),
			"active_policy_fit": active_policy_order_fit.duplicate(true),
		},
		"shift_objective": {
			"opening_slots_visible": (office._opening_egg_slots.is_visible_in_tree() or office._opening_header_slots.is_visible_in_tree()) if office._opening_egg_slots != null else false,
			"opening_slots_filled": int(office._opening_egg_slots.get("filled")) if office._opening_egg_slots != null else 0,
			"visible": office._shift_objective_row.is_visible_in_tree() if office._shift_objective_row != null else false,
			"visual_label": office._shift_egg_goal_label.text if office._shift_egg_goal_label != null else "",
			"goal_icon": String(office._shift_goal_status_icon.get_meta("semantic_icon", "egg")) if office._shift_goal_status_icon != null else "egg",
			"goal_icon_visible": office._shift_goal_status_icon.is_visible_in_tree() if office._shift_goal_status_icon != null else false,
			"readout": office._quota_progress_label.text if office._quota_progress_label != null else "",
			"accessible_text": String(office._shift_goal_status_host.get_meta("accessible_text", "")) if office._shift_goal_status_host != null else "",
			"shape_language": String(office._shift_goal_status_host.get_meta("shape_language", "")) if office._shift_goal_status_host != null else "",
		},
		"live_policy_badge": {
			"visible_text": office._directive_badge.text if office._directive_badge != null else "",
			"full_text": String(office._directive_badge.get_meta("full_text", "")) if office._directive_badge != null else "",
			"compact_text": String(office._directive_badge.get_meta("compact_text", "")) if office._directive_badge != null else "",
			"compact": bool(office._directive_badge_host.get_meta("compact_policy_mark", false)) if office._directive_badge_host != null else false,
			"icon_led": bool(office._directive_badge_host.get_meta("icon_led_policy_mark", false)) if office._directive_badge_host != null else false,
			"interface_scale": float(office._directive_badge_host.get_meta("interface_scale", 1.0)) if office._directive_badge_host != null else 1.0,
			"semantic_icon": String(office._directive_badge.get_meta("semantic_icon", "goal")) if office._directive_badge != null else "goal",
			"icon_visible": office._directive_badge_icon.is_visible_in_tree() if office._directive_badge_icon != null else false,
			"accessible_text": String(office._directive_badge.get_meta("accessible_text", "")) if office._directive_badge != null else "",
		},
		"flockwatch_toggle": {
			"visible_text": office._flockwatch_toggle.text if office._flockwatch_toggle != null else "",
			"full_text": String(office._flockwatch_toggle.get_meta("full_text", "")) if office._flockwatch_toggle != null else "",
			"compact_text": String(office._flockwatch_toggle.get_meta("compact_text", "")) if office._flockwatch_toggle != null else "",
			"compact": bool(office._flockwatch_toggle.get_meta("compact_action_mark", false)) if office._flockwatch_toggle != null else false,
			"icon_led": bool(office._flockwatch_toggle.get_meta("icon_led_action_mark", false)) if office._flockwatch_toggle != null else false,
			"semantic_icon": String(office._flockwatch_toggle.get_meta("semantic_icon", "")) if office._flockwatch_toggle != null else "",
			"icon_visible": office._flockwatch_toggle.icon != null and office._flockwatch_toggle.is_visible_in_tree() if office._flockwatch_toggle != null else false,
			"interface_scale": float(office._flockwatch_toggle.get_meta("interface_scale", 1.0)) if office._flockwatch_toggle != null else 1.0,
			"accessible_text": String(office._flockwatch_toggle.get_meta("accessible_text", "")) if office._flockwatch_toggle != null else "",
			"position": {
				"x": office._flockwatch_toggle.position.x if office._flockwatch_toggle != null else 0.0,
				"y": office._flockwatch_toggle.position.y if office._flockwatch_toggle != null else 0.0,
			},
			"size": {
				"x": office._flockwatch_toggle.size.x if office._flockwatch_toggle != null else 0.0,
				"y": office._flockwatch_toggle.size.y if office._flockwatch_toggle != null else 0.0,
			},
		},
		"settings_button": {
			"visible_text": office._settings_button.text if office._settings_button != null else "",
			"full_text": String(office._settings_button.get_meta("full_text", "")) if office._settings_button != null else "",
			"compact_text": String(office._settings_button.get_meta("compact_text", "")) if office._settings_button != null else "",
			"compact": bool(office._settings_button.get_meta("compact_action_mark", false)) if office._settings_button != null else false,
			"icon_led": bool(office._settings_button.get_meta("icon_led_action_mark", false)) if office._settings_button != null else false,
			"semantic_icon": String(office._settings_button.get_meta("semantic_icon", "")) if office._settings_button != null else "",
			"icon_visible": office._settings_button.icon != null and office._settings_button.is_visible_in_tree() if office._settings_button != null else false,
			"interface_scale": float(office._settings_button.get_meta("interface_scale", 1.0)) if office._settings_button != null else 1.0,
			"accessible_text": String(office._settings_button.get_meta("accessible_text", "")) if office._settings_button != null else "",
			"position": {
				"x": office._settings_button.position.x if office._settings_button != null else 0.0,
				"y": office._settings_button.position.y if office._settings_button != null else 0.0,
			},
			"size": {
				"x": office._settings_button.size.x if office._settings_button != null else 0.0,
				"y": office._settings_button.size.y if office._settings_button != null else 0.0,
			},
		},
		"shift_status": {
			"layout": _live_hud_diagnostic_state(),
			"day_text": office._day_label.text if office._day_label != null else "",
			"time_text": office._time_label.text if office._time_label != null else "",
			"fund_text": office._revenue_label.text if office._revenue_label != null else "",
			"fund_full_text": String(office._revenue_label.get_meta("full_text", "")) if office._revenue_label != null else "",
			"compact": bool(office._shift_clock_status_host.get_meta("compact_status_marks", false)) if office._shift_clock_status_host != null else false,
			"icon_led": bool(office._shift_clock_status_host.get_meta("icon_led_status_marks", false)) if office._shift_clock_status_host != null else false,
			"interface_scale": float(office._shift_clock_status_host.get_meta("interface_scale", 1.0)) if office._shift_clock_status_host != null else 1.0,
			"clock_icon": String(office._shift_clock_status_icon.get_meta("semantic_icon", "")) if office._shift_clock_status_icon != null else "",
			"clock_icon_visible": office._shift_clock_status_icon.visible if office._shift_clock_status_icon != null else false,
			"fund_icon": String(office._fund_status_icon.get_meta("semantic_icon", "")) if office._fund_status_icon != null else "",
			"fund_icon_visible": office._fund_status_icon.visible if office._fund_status_icon != null else false,
			"clock_accessible_text": String(office._shift_clock_status_host.get_meta("accessible_text", "")) if office._shift_clock_status_host != null else "",
			"fund_accessible_text": String(office._fund_status_host.get_meta("accessible_text", "")) if office._fund_status_host != null else "",
			"clock_position": {
				"x": office._shift_clock_status_host.position.x if office._shift_clock_status_host != null else 0.0,
				"y": office._shift_clock_status_host.position.y if office._shift_clock_status_host != null else 0.0,
			},
			"clock_size": {
				"x": office._shift_clock_status_host.size.x if office._shift_clock_status_host != null else 0.0,
				"y": office._shift_clock_status_host.size.y if office._shift_clock_status_host != null else 0.0,
			},
			"fund_position": {
				"x": office._fund_status_host.position.x if office._fund_status_host != null else 0.0,
				"y": office._fund_status_host.position.y if office._fund_status_host != null else 0.0,
			},
			"fund_size": {
				"x": office._fund_status_host.size.x if office._fund_status_host != null else 0.0,
				"y": office._fund_status_host.size.y if office._fund_status_host != null else 0.0,
			},
		},
		"flock_labor": {
			"compact": (snapshot.get("flock_compact", {}) as Dictionary).duplicate(true),
			"work_to_rule": (snapshot.get("work_to_rule", {}) as Dictionary).duplicate(true),
		},
		"eggs_today": int(snapshot.get("eggs_today", 0)),
		"quota_target": int(snapshot.get("quota_target", 0)),
		"minute_of_day": int(snapshot.get("minute_of_day", DepartmentSimulation.SHIFT_START_MINUTE)),
		"time_label": String(snapshot.get("time_label", "")),
	}
	var window := JavaScriptBridge.get_interface("window")
	if window != null:
		runtime_performance["diagnostic_payload_limit_bytes"] = (
			Office.WEB_DIAGNOSTIC_PAYLOAD_LIMIT_BYTES
		)
		runtime_performance["diagnostic_payload_bytes"] = 0
		var serialized_state := JSON.stringify(office._json_safe_variant(state))
		runtime_performance["diagnostic_payload_bytes"] = serialized_state.to_utf8_buffer().size()
		serialized_state = JSON.stringify(office._json_safe_variant(state))
		runtime_performance["diagnostic_payload_bytes"] = serialized_state.to_utf8_buffer().size()
		serialized_state = JSON.stringify(office._json_safe_variant(state))
		window.set("__pecking_order_state", serialized_state)
	office._web_diagnostic_dirty = false


func settlement_destination_ack_snapshot() -> Dictionary:
	var pulses: Array[Dictionary] = []
	var active_count := 0
	for visual in office._settlement_destination_ack_pool:
		if visual.active:
			active_count += 1
		pulses.append(office._settlement_destination_ack_receipt(
			visual,
			office._prefers_reduced_motion(),
		))
	return {
		"pooled_count": office._settlement_destination_ack_pool.size(),
		"active_count": active_count,
		"started_total": office._settlement_destination_ack_total,
		"merged_total": office._settlement_destination_ack_merged_total,
		"bounded_by_kind": true,
		"reduced_motion": office._prefers_reduced_motion(),
		"pulses": pulses,
		"last_by_kind": office._settlement_destination_ack_last_by_kind.duplicate(true),
	}


func fund_debit_feedback_snapshot() -> Dictionary:
	var active: Array[Dictionary] = []
	for visual in office._fund_debit_chip_pool:
		if visual.active:
			active.append(office._fund_debit_receipt(visual, office._prefers_reduced_motion()))
	return {
		"pooled_count": office._fund_debit_chip_pool.size(),
		"active_count": active.size(),
		"started_total": office._fund_debit_started_total,
		"merged_total": office._fund_debit_merged_total,
		"recycled_total": office._fund_debit_recycled_total,
		"bounded": true,
		"source_id": "feed_fund_counter",
		"reduced_motion": office._prefers_reduced_motion(),
		"active_debits": active,
		"last_receipt": office._fund_debit_last_receipt.duplicate(true),
	}


func fund_credit_batch_snapshot() -> Dictionary:
	var batches: Array[Dictionary] = []
	var total_eggs := 0
	var total_value_cents := 0
	for visual in office._active_fund_credit_chips:
		if not visual.active:
			continue
		total_eggs += visual.egg_count
		total_value_cents += visual.value_cents
		var panel_rect := visual.panel.get_global_rect()
		panel_rect.position -= office._ui_root.get_global_rect().position
		batches.append({
			"batch_serial": int(visual.panel.get_meta("batch_serial", 0)),
			"egg_count": visual.egg_count,
			"value_cents": visual.value_cents,
			"quality": String(visual.quality),
			"quality_counts": visual.quality_counts.duplicate(true),
			"label": visual.label.text,
			"elapsed": visual.elapsed,
			"animated": not office._prefers_reduced_motion(),
			"capture_staged": visual.capture_staged,
			"visible": visual.panel.visible,
			"deferred": visual.deferred,
			"deferred_elapsed": visual.deferred_elapsed,
			"deferred_reason": String(visual.deferred_reason),
			"released_after_defer": visual.released_after_defer,
			"release_serial": visual.release_serial,
			"desired_source_center": visual.desired_source_center,
			"safe_source_center": visual.safe_source_center,
			"placement_clamped": visual.placement_clamped,
			"panel_rect": panel_rect,
			"accessible_text": String(visual.panel.get_meta("accessible_text", "")),
		})
	return {
		"pooled_chip_count": office._fund_credit_chip_pool.size(),
		"active_batch_count": batches.size(),
		"total_eggs": total_eggs,
		"total_value_cents": total_value_cents,
		"merge_window_seconds": Office.FUND_CREDIT_CHIP_MERGE_SECONDS,
		"reduced_motion": office._prefers_reduced_motion(),
		"placement": office._last_settlement_feedback_placement.duplicate(true),
		"arbitration": settlement_feedback_arbitration_snapshot(),
		"batches": batches,
	}


func auxiliary_settlement_snapshot() -> Dictionary:
	var batches: Array[Dictionary] = []
	var stock_eggs := 0
	var stock_value_cents := 0
	var pecks_restored := 0
	for visual in office._active_auxiliary_settlement_chips:
		if not visual.active:
			continue
		if visual.kind == &"refund":
			pecks_restored += visual.item_count
		else:
			stock_eggs += visual.item_count
			stock_value_cents += visual.value_cents
		var panel_rect := visual.panel.get_global_rect()
		panel_rect.position -= office._ui_root.get_global_rect().position
		batches.append({
			"batch_serial": int(visual.panel.get_meta("batch_serial", 0)),
			"kind": String(visual.kind),
			"item_count": visual.item_count,
			"value_cents": visual.value_cents,
			"charges_after": visual.charges_after,
			"quality": String(visual.quality),
			"quality_counts": visual.quality_counts.duplicate(true),
			"label": visual.label.text,
			"elapsed": visual.elapsed,
			"animated": not office._prefers_reduced_motion(),
			"capture_staged": visual.capture_staged,
			"visible": visual.panel.visible,
			"deferred": visual.deferred,
			"deferred_elapsed": visual.deferred_elapsed,
			"deferred_reason": String(visual.deferred_reason),
			"released_after_defer": visual.released_after_defer,
			"release_serial": visual.release_serial,
			"desired_source_center": visual.desired_source_center,
			"safe_source_center": visual.safe_source_center,
			"placement_clamped": visual.placement_clamped,
			"panel_rect": panel_rect,
			"accessible_text": String(visual.panel.get_meta("accessible_text", "")),
		})
	return {
		"pooled_chip_count": office._auxiliary_settlement_chip_pool.size(),
		"active_batch_count": batches.size(),
		"stock_eggs": stock_eggs,
		"stock_value_cents": stock_value_cents,
		"pecks_restored": pecks_restored,
		"merge_window_seconds": Office.AUXILIARY_SETTLEMENT_CHIP_MERGE_SECONDS,
		"reduced_motion": office._prefers_reduced_motion(),
		"placement": office._last_settlement_feedback_placement.duplicate(true),
		"arbitration": settlement_feedback_arbitration_snapshot(),
		"batches": batches,
	}


func settlement_feedback_arbitration_snapshot() -> Dictionary:
	var deferred_count := 0
	var visible_count := 0
	var released_count := 0
	for visual in office._active_fund_credit_chips:
		if not visual.active:
			continue
		if visual.deferred:
			deferred_count += 1
		if visual.panel != null and visual.panel.visible:
			visible_count += 1
		if visual.released_after_defer:
			released_count += 1
	for visual in office._active_auxiliary_settlement_chips:
		if not visual.active:
			continue
		if visual.deferred:
			deferred_count += 1
		if visual.panel != null and visual.panel.visible:
			visible_count += 1
		if visual.released_after_defer:
			released_count += 1
	return {
		"attention": office._settlement_feedback_attention_state(),
		"active_batch_count": (
			office._active_fund_credit_chips.size()
			+ office._active_auxiliary_settlement_chips.size()
		),
		"visible_batch_count": visible_count,
		"deferred_batch_count": deferred_count,
		"released_batch_count": released_count,
		"deferred_total": office._settlement_feedback_deferred_total,
		"released_total": office._settlement_feedback_released_total,
		"suppressed_total": office._settlement_feedback_suppressed_total,
		"max_defer_seconds": Office.SETTLEMENT_FEEDBACK_MAX_DEFER_SECONDS,
		"last_suppressed": office._settlement_feedback_last_suppressed.duplicate(true),
		"release_serial": office._settlement_feedback_release_serial,
		"release_cue_count": office._settlement_feedback_release_cue_count,
		"last_release": office._settlement_feedback_last_release.duplicate(true),
		"route_handoff": office._settlement_feedback_route_handoff.duplicate(true),
		"last_route_handoff": office._settlement_feedback_last_route_handoff.duplicate(true),
		"route_handoff_timeout_seconds": Office.SETTLEMENT_ROUTE_HANDOFF_TIMEOUT_SECONDS,
		"receipt_surfaces": [
			"feed_fund_counter",
			"flockwatch_inventory_ledger",
			"priority_peck_meter",
			"workstation_acknowledgment",
			"selected_hen_last_egg",
			"shift_record",
		],
	}


func settlement_feedback_placement_snapshot() -> Dictionary:
	var cards: Array[Dictionary] = []
	var root_size := office._ui_root.get_global_rect().size if office._ui_root != null else Vector2.ZERO
	var root_origin := office._ui_root.get_global_rect().position if office._ui_root != null else Vector2.ZERO
	for visual in office._active_fund_credit_chips:
		if not visual.active or visual.panel == null:
			continue
		var panel_rect := visual.panel.get_global_rect()
		panel_rect.position -= root_origin
		cards.append({
			"id": "fund",
			"rect": panel_rect,
			"visible": visual.panel.visible,
			"deferred": visual.deferred,
			"placement_clamped": visual.placement_clamped,
			"desired_source_center": visual.desired_source_center,
			"safe_source_center": visual.safe_source_center,
		})
	for visual in office._active_auxiliary_settlement_chips:
		if not visual.active or visual.panel == null:
			continue
		var panel_rect := visual.panel.get_global_rect()
		panel_rect.position -= root_origin
		cards.append({
			"id": String(visual.kind),
			"rect": panel_rect,
			"visible": visual.panel.visible,
			"deferred": visual.deferred,
			"placement_clamped": visual.placement_clamped,
			"desired_source_center": visual.desired_source_center,
			"safe_source_center": visual.safe_source_center,
		})
	var placement := office._last_settlement_feedback_placement.duplicate(true)
	var top_boundary := float(placement.get("top_boundary", 0.0))
	var bottom_boundary := float(placement.get("bottom_boundary", root_size.y))
	var safe := true
	var reasons: Array[String] = []
	var clamped_count := 0
	var visible_count := 0
	var deferred_count := 0
	for card in cards:
		var card_id := String(card.get("id", "card"))
		var rect := card.get("rect", Rect2()) as Rect2
		if bool(card.get("deferred", false)):
			deferred_count += 1
		if not bool(card.get("visible", false)):
			continue
		visible_count += 1
		if bool(card.get("placement_clamped", false)):
			clamped_count += 1
		if (
			rect.position.x < -0.5
			or rect.end.x > root_size.x + 0.5
			or rect.position.y < -0.5
			or rect.end.y > root_size.y + 0.5
		):
			safe = false
			reasons.append("%s_offscreen" % card_id)
		if rect.position.y < top_boundary + Office.SETTLEMENT_FEEDBACK_SURFACE_GAP - 0.5:
			safe = false
			reasons.append("%s_overlaps_top_surfaces" % card_id)
		if rect.end.y > bottom_boundary - Office.SETTLEMENT_FEEDBACK_SURFACE_GAP + 0.5:
			safe = false
			reasons.append("%s_overlaps_bottom_surface" % card_id)
	for first_index in cards.size():
		if not bool(cards[first_index].get("visible", false)):
			continue
		var first_rect := cards[first_index].get("rect", Rect2()) as Rect2
		for second_index in range(first_index + 1, cards.size()):
			if not bool(cards[second_index].get("visible", false)):
				continue
			var second_rect := cards[second_index].get("rect", Rect2()) as Rect2
			if first_rect.intersects(second_rect):
				safe = false
				reasons.append("%s_overlaps_%s" % [
					String(cards[first_index].get("id", "card")),
					String(cards[second_index].get("id", "card")),
				])
	return {
		"all_safe": safe,
		"reasons": reasons,
		"card_count": cards.size(),
		"visible_card_count": visible_count,
		"deferred_card_count": deferred_count,
		"clamped_count": clamped_count,
		"cards": cards,
		"placement": placement,
		"arbitration": settlement_feedback_arbitration_snapshot(),
	}
