class_name OfficeDecisionPresenter
extends RefCounted

## Incident decision dialogs, consequences and follow-through.
## Holds no state of its own: every read and write goes through the owning
## Office so behaviour is identical to the original in-class methods.

var office: Office


func _init(owner_node: Office) -> void:
	office = owner_node

func _pending_decision_diagnostic_state() -> Dictionary:
	return office._web_bridge._pending_decision_diagnostic_state()


func _build_decision_modal() -> void:
	office._environment_builder._build_decision_modal()


func _set_decision_petition_glance_visible(visible: bool) -> void:
	if office._decision_petition_glance != null:
		office._decision_petition_glance.visible = visible


func _decision_petition_glance_column_count(panel_width: float) -> int:
	return 5 if panel_width >= 700.0 else (3 if panel_width >= 500.0 else 2)


func _decision_petition_option_column_count(panel_width: float) -> int:
	return 3 if panel_width >= 700.0 else (2 if panel_width >= 500.0 else 1)


func _decision_option_column_count(
	kind: StringName,
	decision_category: StringName,
	option_count: int,
	panel_width: float,
) -> int:
	# Choice cards carry two lines of glance copy before their exact consequence
	# preview. Stacking them on phone-width cards preserves comfortable touch
	# targets and readable labels instead of squeezing the same information into
	# narrow side-by-side columns.
	if decision_category == &"flock_petition":
		return office._decision_petition_option_column_count(panel_width)
	if panel_width < 500.0:
		return 1
	if kind == Office.FIRST_CLUTCH_REINVESTMENT_KIND:
		return 3 if panel_width >= 700.0 else 2
	if kind == &"directive" and option_count <= 3:
		return 3 if panel_width >= 700.0 else 2
	return 2 if option_count <= 4 else 1


func _configure_decision_petition_glance(decision: Dictionary) -> void:
	if office._decision_petition_glance == null:
		return
	var petition := decision.get("petition", {}) as Dictionary
	var evidence_lines: Array[String] = []
	var entries: Array[Dictionary] = []
	for evidence_value in decision.get("evidence", []):
		var evidence_line := String(evidence_value).strip_edges()
		if evidence_line.is_empty():
			continue
		evidence_lines.append(evidence_line)
		if entries.size() >= 3:
			continue
		var separator_index := evidence_line.find(":")
		var evidence_caption := "EVIDENCE"
		var evidence_glance := evidence_line
		if separator_index >= 0:
			evidence_caption = evidence_line.left(separator_index).strip_edges()
			evidence_glance = evidence_line.substr(separator_index + 1).strip_edges()
		entries.append({
			"caption": _petition_evidence_caption(evidence_caption),
			"value": evidence_glance.to_upper(),
			"detail": "FILED EVIDENCE\n%s" % evidence_line,
		})
	var petition_type := StringName(decision.get(
		"petition_type",
		petition.get("petition_type", &""),
	))
	var contract_glance := _petition_contract_glance(petition_type)
	var promise := String(petition.get("promise", "A next-shift promise will be binding."))
	var condition := String(petition.get("condition", "The closing ledger determines fulfillment."))
	entries.append({
		"caption": "PROMISE",
		"value": String(contract_glance.get("promise", "NEXT SHIFT")),
		"detail": "PROPOSED COMPACT\n%s" % promise,
	})
	entries.append({
		"caption": "TEST",
		"value": String(contract_glance.get("test", "CLOSING LEDGER")),
		"detail": "FULFILLMENT TEST\n%s" % condition,
	})
	for tile_index in office._decision_petition_tiles.size():
		var has_entry := tile_index < entries.size()
		office._decision_petition_tiles[tile_index].visible = has_entry
		if not has_entry:
			continue
		var entry := entries[tile_index]
		var detail := String(entry.get("detail", ""))
		office._decision_petition_values[tile_index].text = String(entry.get("value", "-"))
		office._decision_petition_captions[tile_index].text = String(entry.get("caption", "FILE"))
		office._decision_petition_tiles[tile_index].tooltip_text = detail
		office._decision_petition_tiles[tile_index].set_meta("accessible_text", detail)
	var sponsor_name := String(decision.get("sponsor_worker_name", "THE SPONSOR")).to_upper()
	office._decision_body.text = "%s FILED A COLLECTIVE REQUEST FROM THE PERFORMANCE LEDGER." % sponsor_name
	var evidence_detail := (
		" / ".join(evidence_lines)
		if not evidence_lines.is_empty() else
		"The active flock ledger supports the filing."
	)
	var semantic_detail := "FILED EVIDENCE. %s PROPOSED COMPACT. %s FULFILLMENT TEST. %s" % [
		evidence_detail,
		promise,
		condition,
	]
	office._decision_body.set_meta("accessible_text", "%s %s" % [office._decision_body.text, semantic_detail])
	if office._decision_petition_semantics != null:
		office._decision_petition_semantics.text = semantic_detail
		office._decision_petition_semantics.set_meta("accessible_text", semantic_detail)
	office._set_decision_petition_glance_visible(true)


func _petition_evidence_caption(raw_caption: String) -> String:
	match raw_caption.to_upper():
		"ASSIGNED FILE":
			return "ASSIGNED"
		"TRAINED FILE":
			return "TRAINED"
		"GRIEVANCE LEDGER":
			return "GRIEVANCE"
		"STRESS READING":
			return "STRESS"
		"FATIGUE READING":
			return "FATIGUE"
		"OVERTIME ORDER":
			return "OVERTIME"
		"LAST CREDIT MEMO":
			return "LAST CREDIT"
		"CAREER PROFILE":
			return "PROFILE"
	return raw_caption.to_upper()


func _petition_contract_glance(petition_type: StringName) -> Dictionary:
	match petition_type:
		&"specialty_respect":
			return {"promise": "SPECIALTY ALL SHIFT", "test": "FULL SHIFT"}
		&"safe_pace":
			return {"promise": "NO OT / QUOTA", "test": "NO BREACH"}
		&"credit_in_writing":
			return {"promise": "SHARE CREDIT", "test": "BEFORE CLOSE"}
	return {"promise": "NEXT SHIFT", "test": "CLOSING LEDGER"}


func _set_decision_order_glance_visible(visible: bool) -> void:
	if office._decision_order_heading != null:
		office._decision_order_heading.visible = visible
	if office._decision_order_glance != null:
		office._decision_order_glance.visible = visible


func _configure_decision_order_glance() -> void:
	if office._campaign_state == null or office._decision_order_glance == null:
		return
	var objectives := office._campaign_state.current_objectives()
	for index in office._decision_order_values.size():
		var has_order := index < objectives.size()
		var value := office._decision_order_values[index]
		var caption := office._decision_order_captions[index]
		var tile := value.get_parent().get_parent() as Control
		if tile != null:
			tile.visible = has_order
		if not has_order:
			continue
		var objective := objectives[index] as Dictionary
		var objective_title := String(objective.get("title", "ORDER")).to_upper()
		value.text = _probation_order_glance_value(objective)
		value.set_meta("base_goal_text", value.text)
		caption.text = "+%d SCORE" % int(objective.get("score_award", 0))
		if index < office._decision_order_tiles.size():
			office._decision_order_tiles[index].set_meta("order_title", objective_title)
		value.tooltip_text = String(objective.get(
			"description",
			"Filed against the closing ledger.",
		))
		caption.tooltip_text = value.tooltip_text
	_reset_decision_order_fit_visuals()
	office._set_decision_order_glance_visible(not objectives.is_empty())


func _reset_decision_order_fit_visuals() -> void:
	if office._decision_order_heading != null:
		office._decision_order_heading.text = "TODAY'S GOALS"
	for index in office._decision_order_tiles.size():
		var tile := office._decision_order_tiles[index]
		var style := office._panel_style(Color("20313b"), 0.98, 8, 1)
		tile.add_theme_stylebox_override("panel", style)
		if index < office._decision_order_values.size():
			var value := office._decision_order_values[index]
			value.text = String(value.get_meta("base_goal_text", value.text))
			value.add_theme_color_override("font_color", Color("f1cf79"))


func _apply_decision_order_fit_visuals(order_fit: Dictionary) -> void:
	_reset_decision_order_fit_visuals()
	var supports := order_fit.get("supports", []) as Array
	var risks := order_fit.get("risks", []) as Array
	for index in office._decision_order_tiles.size():
		var tile := office._decision_order_tiles[index]
		var order_title := String(tile.get_meta("order_title", ""))
		var accent := Color("5c6d7f")
		var fill := Color("20313b")
		var fit_marker := ""
		if order_title in supports:
			accent = Color("8ed3b1")
			fill = Color("19342f")
			fit_marker = "+  "
		elif order_title in risks:
			accent = Color("efb37c")
			fill = Color("382923")
			fit_marker = "!  "
		var style := office._panel_style(fill, 0.98, 8, 2 if order_title in supports or order_title in risks else 1)
		style.border_color = accent
		tile.add_theme_stylebox_override("panel", style)
		if index < office._decision_order_values.size():
			var value := office._decision_order_values[index]
			var base_text := String(value.get_meta("base_goal_text", value.text))
			value.text = "%s%s" % [fit_marker, base_text]
			if not fit_marker.is_empty():
				value.add_theme_color_override("font_color", accent)
	if office._decision_order_heading != null:
		office._decision_order_heading.text = "TODAY'S GOALS  ·  + HELPS  ·  ! RISKS"


func _probation_order_glance_value(objective: Dictionary) -> String:
	var metric := StringName(objective.get("metric", &""))
	var comparison := StringName(objective.get("comparison", &"minimum"))
	var target := int(objective.get("target", 0))
	var target_label := (
		"%d+" % target
		if comparison == &"minimum" else
		"<=%d" % target
		if comparison == &"maximum" else
		"=%d" % target
	)
	match metric:
		&"eggs":
			return "%d+ EGGS" % target
		&"crack_rate_basis_points":
			return "CRACKS <=%d%%" % roundi(float(target) / 100.0)
		&"welfare":
			return "WELFARE %s" % target_label
		&"compliance":
			return "COMPLIANCE %s" % target_label
		&"farmer_favor":
			return "FAVOR %s" % target_label
		&"overdue_files":
			return "OVERDUE %s" % target_label
		&"rework":
			return "REWORK %s" % target_label
		&"quota_met":
			return "MEET QUOTA"
		_:
			return String(objective.get("title", "ORDER")).to_upper()


func _mount_decision_effect_chips(
	button: Button,
	option_id: StringName,
	effect_chips: Array,
) -> void:
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 108.0)
	button.clip_contents = true
	var row := HBoxContainer.new()
	row.name = "DecisionEffectChips_%s" % String(option_id)
	row.anchor_left = 0.0
	row.anchor_top = 1.0
	row.anchor_right = 1.0
	row.anchor_bottom = 1.0
	row.offset_left = 8.0
	row.offset_top = -35.0
	row.offset_right = -8.0
	row.offset_bottom = -6.0
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	for chip_value in effect_chips:
		if not chip_value is Dictionary:
			continue
		var chip := chip_value as Dictionary
		var beneficial := bool(chip.get("beneficial", false))
		var accent := Color("8ed3b1") if beneficial else Color("efb37c")
		var panel := PanelContainer.new()
		panel.name = "DecisionEffectChip_%s_%s" % [
			String(option_id),
			String(chip.get("id", "effect")),
		]
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.custom_minimum_size = Vector2(70.0, 28.0)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.tooltip_text = String(chip.get("detail", chip.get("copy", "Decision effect")))
		panel.set_meta("accessible_text", panel.tooltip_text)
		var chip_style := office._panel_style(Color("17252d"), 0.94, 7, 1)
		chip_style.border_color = Color(accent, 0.72)
		panel.add_theme_stylebox_override("panel", chip_style)
		var content := HBoxContainer.new()
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 2)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(content)
		var icon := Office.FlockwatchIconBadgeScript.new()
		icon.set_badge_size(18.0)
		icon.configure(StringName(chip.get("icon", &"goal")), accent)
		content.add_child(icon)
		var label := office._make_label(String(chip.get("copy", "CHANGE")), 10, accent)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(label)
		row.add_child(panel)


func _select_decision_option_by_index(index: int) -> void:
	if index < 0 or index >= office._decision_option_buttons.size():
		return
	var button := office._decision_option_buttons[index]
	if button.disabled:
		office._decision_preview.text = button.tooltip_text
		return
	office._on_decision_option_pressed(StringName(button.get_meta("option_id", &"")))


func _commit_selected_decision() -> void:
	if office._selected_decision_option == &"" or office._active_decision.is_empty():
		office._decision_preview.text = "Select a response card before authorization."
		return
	office._decision_confirm_button.disabled = true
	office._decision_stay_paused_button.disabled = true
	if StringName(office._active_decision.get("kind", &"")) == Office.FIRST_CLUTCH_REINVESTMENT_KIND:
		var result := office._simulation.resolve_first_clutch_reinvestment(office._selected_decision_option)
		if bool(result.get("accepted", false)):
			# The simulation emits first_clutch_reinvestment_resolved synchronously.
			# Keep this fallback for focused harnesses that substitute a signal-free stub.
			if not office._active_decision.is_empty():
				office._on_first_clutch_reinvestment_resolved(result)
			return
		office._decision_confirm_button.disabled = false
		office._decision_stay_paused_button.disabled = false
		office._decision_preview.text = "AUTHORIZATION HELD  //  %s" % String(result.get(
			"reason",
			"The requisition no longer matches the authoritative Feed Fund ledger.",
		))
		office._decision_confirm_button.grab_focus()
		office._publish_web_diagnostic_state(office._simulation.snapshot())
		return
	var resolved := office._simulation.resolve_decision(
		int(office._active_decision.get("serial", -1)),
		office._selected_decision_option
	)
	if resolved:
		return
	office._decision_confirm_button.disabled = false
	office._decision_stay_paused_button.disabled = false
	office._decision_preview.text = "AUTHORIZATION FAILED  //  Review the Feed Fund requirement and choose again."


func _spawn_decision_consequence_receipts(
	before: Dictionary,
	after: Dictionary,
	result: Dictionary,
) -> void:
	office._retire_action_outcome_receipts(&"replaced", false)
	var entries := office._decision_consequence_entries(before, after)
	var visible_entries: Array = entries.slice(0, mini(3, entries.size()))
	var option_label := String(result.get("option_id", "DECISION")).replace("_", " ").to_upper()
	for option_value in office._active_decision.get("options", []):
		var option := option_value as Dictionary
		if StringName(option.get("id", &"")) != StringName(result.get("option_id", &"")):
			continue
		option_label = String(option.get("short_label", option.get("label", option_label))).to_upper()
		break
	var semantic_entries: Array[Dictionary] = []
	var accessible_lines: Array[String] = []
	for entry_value in entries:
		var entry := entry_value as Dictionary
		semantic_entries.append({
			"id": String(entry.get("id", "change")),
			"icon": String(entry.get("icon", "goal")),
			"copy": String(entry.get("copy", "CHANGE FILED")),
			"detail": String(entry.get("detail", "Decision consequence filed.")),
			"world_target_worker_id": int(entry.get("world_target_worker_id", -1)),
		})
		accessible_lines.append(String(entry.get("detail", "Decision consequence filed.")))
	office._latest_action_outcome_receipt = {
		"visible": not entries.is_empty(),
		"title": option_label,
		"entries": semantic_entries,
		"visible_entry_count": visible_entries.size(),
		"accessible_text": "%s. %s" % [option_label, " ".join(accessible_lines)],
	}
	office._record_campaign_order_cause_receipts(
		before,
		after,
		option_label,
		&"decision",
		"",
		{
			"source_kind": "decision_file",
			"source_label": option_label,
			"source_id": String(result.get("option_id", "")),
		},
	)
	if entries.is_empty() or office._ui_root == null:
		return
	var source_center := office.get_viewport().get_visible_rect().size * 0.5
	if office._decision_panel != null and is_instance_valid(office._decision_panel):
		source_center = (
			office._decision_panel.get_global_rect().get_center()
			- office._ui_root.get_global_rect().position
		)
	var receipt_size := Vector2(154.0, 42.0)
	var gap := 8.0
	var row_width := receipt_size.x * visible_entries.size() + gap * maxi(0, visible_entries.size() - 1)
	var row_left := source_center.x - row_width * 0.5
	var reduced_motion := office._prefers_reduced_motion()
	var capture_holds_receipt := (
		"--capture-action-feedback" in OS.get_cmdline_user_args()
		or "--capture-action-feedback" in OS.get_cmdline_args()
	)
	for index in visible_entries.size():
		var entry := visible_entries[index] as Dictionary
		var panel := PanelContainer.new()
		panel.name = "ActionOutcomeReceipt_%d" % index
		panel.custom_minimum_size = receipt_size
		panel.size = receipt_size
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override(
			"panel",
			office._panel_style(Color("17252d"), 0.98, 8, 1),
		)
		panel.set_meta("accessible_text", String(entry.get("detail", "")))
		var content := HBoxContainer.new()
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 6)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(content)
		var accent: Color = entry.get("accent", Color("f1cf79"))
		var icon := Office.FlockwatchIconBadgeScript.new()
		icon.configure(StringName(entry.get("icon", &"goal")), accent)
		content.add_child(icon)
		var label := office._make_label(String(entry.get("copy", "CHANGE FILED")), 13, accent)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(label)
		office._ui_root.add_child(panel)
		office._active_action_outcome_panels.append(panel)
		panel.position = Vector2(
			row_left + index * (receipt_size.x + gap),
			source_center.y - receipt_size.y * 0.5,
		)
		panel.pivot_offset = receipt_size * 0.5
		panel.scale = Vector2(0.78, 0.78)
		panel.modulate.a = 0.0
		var target_control := entry.get("target") as Control
		var target_position := panel.position - Vector2(0.0, 18.0)
		if target_control != null and is_instance_valid(target_control):
			target_position = (
				target_control.get_global_rect().get_center()
				- office._ui_root.get_global_rect().position
				- receipt_size * 0.5
			)
		var world_target_worker_id := int(entry.get("world_target_worker_id", -1))
		var world_target_view := office._worker_views.get(world_target_worker_id) as ChickenView
		if (
			world_target_view != null
			and is_instance_valid(world_target_view)
			and office._management_camera != null
			and not office._management_camera.is_position_behind(
				world_target_view.global_position + Vector3(0.0, 1.45, 0.0)
			)
		):
			target_position = (
				office._management_camera.unproject_position(
					world_target_view.global_position + Vector3(0.0, 1.45, 0.0)
				)
				- office._ui_root.get_global_rect().position
				- receipt_size * 0.5
			)
			panel.set_meta("flies_to_world_target", true)
			panel.set_meta("world_target_worker_id", world_target_worker_id)
			if index == 0:
				world_target_view.play_short_bark("I FELT THAT!", &"team")
		var tween := office._presentation_tween(panel)
		tween.tween_interval(float(index) * 0.07)
		tween.tween_property(panel, "modulate:a", 1.0, 0.12)
		tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_interval(
			6.0 if capture_holds_receipt else (0.62 if not reduced_motion else 0.82)
		)
		if not reduced_motion:
			tween.tween_property(panel, "position", target_position, 0.58).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(panel, "scale", Vector2(0.82, 0.82), 0.58)
		else:
			tween.tween_interval(0.12)
		tween.tween_property(panel, "modulate:a", 0.0, 0.22)
		tween.tween_callback(office._on_action_outcome_receipt_finished.bind(
			panel,
			index == entries.size() - 1,
		))


func _decision_consequence_entries(before: Dictionary, after: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if before.is_empty() or after.is_empty():
		return entries
	var fund_before := int(before.get("revenue_cents", 0))
	var fund_after := int(after.get("revenue_cents", fund_before))
	var fund_delta := fund_after - fund_before
	if fund_delta != 0:
		_append_action_consequence(
			entries,
			&"fund",
			&"cash",
			"FUND %s$%.2f" % ["+" if fund_delta > 0 else "-", absf(float(fund_delta)) / 100.0],
			"Feed Fund changed from $%.2f to $%.2f." % [float(fund_before) / 100.0, float(fund_after) / 100.0],
			office._revenue_label,
			Color("efc36f"),
		)
	var quota_before := int(before.get("quota_target", 0))
	var quota_after := int(after.get("quota_target", quota_before))
	if quota_after != quota_before:
		_append_action_consequence(
			entries, &"quota", &"egg",
			"GOAL %s%d EGG%s" % ["+" if quota_after > quota_before else "", quota_after - quota_before, "" if absi(quota_after - quota_before) == 1 else "S"],
			"Shift clutch target changed from %d to %d eggs." % [quota_before, quota_after],
			office._quota_progress,
			Color("efb37c") if quota_after > quota_before else Color("8ed3b1"),
		)
	var before_modifiers := before.get("decision_modifiers", {}) as Dictionary
	var after_modifiers := after.get("decision_modifiers", {}) as Dictionary
	var pace_before := float(before_modifiers.get("work_multiplier", 1.0))
	var pace_after := float(after_modifiers.get("work_multiplier", pace_before))
	var pace_delta := roundi((pace_after - pace_before) * 100.0)
	if pace_delta != 0:
		_append_action_consequence(
			entries, &"pace", &"egg",
			"PACE %s%d%%" % ["+" if pace_delta > 0 else "", pace_delta],
			"Production pace changed from %d%% to %d%%." % [roundi(pace_before * 100.0), roundi(pace_after * 100.0)],
			office._quota_progress_label,
			Color("8ed3b1") if pace_delta > 0 else Color("efb37c"),
		)
	var strain_rate_before := float(before_modifiers.get("stress_multiplier", 1.0))
	var strain_rate_after := float(after_modifiers.get("stress_multiplier", strain_rate_before))
	var strain_rate_delta := roundi((strain_rate_after - strain_rate_before) * 100.0)
	if strain_rate_delta != 0:
		_append_action_consequence(
			entries, &"strain", &"flock",
			"STRAIN %s%d%%" % ["+" if strain_rate_delta > 0 else "", strain_rate_delta],
			"Flock stress and fatigue growth changed from %d%% to %d%%." % [roundi(strain_rate_before * 100.0), roundi(strain_rate_after * 100.0)],
			office._flockwatch_toggle,
			Color("8ed3b1") if strain_rate_delta < 0 else Color("e99479"),
		)
	var risk_before := float(before_modifiers.get("crack_modifier", 0.0))
	var risk_after := float(after_modifiers.get("crack_modifier", risk_before))
	var risk_delta := roundi((risk_after - risk_before) * 100.0)
	if risk_delta != 0:
		_append_action_consequence(
			entries, &"risk", &"shield",
			"RISK %s%d%%" % ["+" if risk_delta > 0 else "", risk_delta],
			"Filed shell-risk modifier changed from %s%d%% to %s%d%%." % ["+" if risk_before > 0.0 else "", roundi(risk_before * 100.0), "+" if risk_after > 0.0 else "", roundi(risk_after * 100.0)],
			office._quality_streak_label,
			Color("8ed3b1") if risk_delta < 0 else Color("e99479"),
		)
	var morale_before := _snapshot_worker_average(before, &"morale")
	var morale_after := _snapshot_worker_average(after, &"morale")
	var morale_delta := roundi(morale_after - morale_before)
	if morale_delta != 0:
		_append_action_consequence(
			entries, &"welfare", &"flock",
			"WELFARE %s%d" % ["+" if morale_delta > 0 else "", morale_delta],
			"Average flock morale changed from %d to %d." % [roundi(morale_before), roundi(morale_after)],
			office._flockwatch_toggle,
			Color("8ed3b1") if morale_delta > 0 else Color("e99479"),
			_most_changed_worker_id(before, after, &"morale"),
		)
	var stress_before := _snapshot_worker_average(before, &"stress")
	var stress_after := _snapshot_worker_average(after, &"stress")
	var stress_delta := roundi(stress_after - stress_before)
	if stress_delta != 0 and strain_rate_delta == 0:
		_append_action_consequence(
			entries, &"strain", &"flock",
			"STRAIN %s%d" % ["+" if stress_delta > 0 else "", stress_delta],
			"Average flock stress changed from %d to %d." % [roundi(stress_before), roundi(stress_after)],
			office._flockwatch_toggle,
			Color("8ed3b1") if stress_delta < 0 else Color("e99479"),
			_most_changed_worker_id(before, after, &"stress"),
		)
	var compliance_before := roundi(float(before.get("compliance", 0.0)))
	var compliance_after := roundi(float(after.get("compliance", compliance_before)))
	if compliance_after != compliance_before:
		_append_action_consequence(
			entries, &"compliance", &"files",
			"RULES %s%d" % ["+" if compliance_after > compliance_before else "", compliance_after - compliance_before],
			"Coop compliance changed from %d to %d." % [compliance_before, compliance_after],
			office._directive_badge,
			Color("8ed3b1") if compliance_after > compliance_before else Color("e99479"),
		)
	var feed_before := int(before_modifiers.get("daily_feed_adjustment_cents", 0))
	var feed_after := int(after_modifiers.get("daily_feed_adjustment_cents", feed_before))
	var feed_delta := feed_after - feed_before
	if feed_delta != 0:
		_append_action_consequence(
			entries, &"feed", &"cash",
			"FEED %s$%.0f" % ["+" if feed_delta > 0 else "-", absf(float(feed_delta)) / 100.0],
			"Daily feed cost changed from $%.2f to $%.2f for this shift." % [float(feed_before) / 100.0, float(feed_after) / 100.0],
			office._revenue_label,
			Color("8ed3b1") if feed_delta < 0 else Color("efb37c"),
		)
	var favor_before := roundi(float(before.get("executive_confidence", 0.0)))
	var favor_after := roundi(float(after.get("executive_confidence", favor_before)))
	if favor_after != favor_before:
		_append_action_consequence(
			entries, &"favor", &"goal",
			"FAVOR %s%d" % ["+" if favor_after > favor_before else "", favor_after - favor_before],
			"Farmer favor changed from %d to %d." % [favor_before, favor_after],
			office._directive_badge,
			Color("8ed3b1") if favor_after > favor_before else Color("e99479"),
		)
	while entries.size() > 4:
		entries.pop_back()
	return entries


func _append_action_consequence(
	entries: Array[Dictionary],
	id: StringName,
	icon: StringName,
	copy: String,
	detail: String,
	target: Control,
	accent: Color,
	world_target_worker_id: int = -1,
) -> void:
	entries.append({
		"id": id,
		"icon": icon,
		"copy": copy,
		"detail": detail,
		"target": target,
		"accent": accent,
		"world_target_worker_id": world_target_worker_id,
	})


func _most_changed_worker_id(before: Dictionary, after: Dictionary, field: StringName) -> int:
	var before_by_id: Dictionary = {}
	for worker_value in before.get("workers", []) as Array:
		if worker_value is Dictionary:
			var worker := worker_value as Dictionary
			before_by_id[int(worker.get("id", -1))] = worker
	var best_id := -1
	var best_delta := 0.0
	for worker_value in after.get("workers", []) as Array:
		if not worker_value is Dictionary:
			continue
		var worker := worker_value as Dictionary
		var worker_id := int(worker.get("id", -1))
		var prior := before_by_id.get(worker_id, {}) as Dictionary
		if prior.is_empty():
			continue
		var delta := absf(float(worker.get(field, 0.0)) - float(prior.get(field, 0.0)))
		if delta > best_delta:
			best_delta = delta
			best_id = worker_id
	return best_id


func _snapshot_worker_average(snapshot: Dictionary, field: StringName) -> float:
	var total := 0.0
	var count := 0
	for worker_value in snapshot.get("workers", []):
		if not worker_value is Dictionary:
			continue
		var worker := worker_value as Dictionary
		if not bool(worker.get("employed", true)):
			continue
		total += float(worker.get(field, 0.0))
		count += 1
	return total / maxf(1.0, float(count))


## The decision card has two deliberate stages: choose one reversible card,
## then focus the exact filing button. Keeping both stages in one contract
## prevents the HUD and browser from continuing to say "choose" after the
## rendered card has already advanced to authorization.
func _decision_primary_action_state() -> Dictionary:
	if (
		office._decision_host == null
		or not office._decision_host.visible
		or office._active_decision.is_empty()
	):
		return {}
	var pending_kind := StringName(office._active_decision.get("kind", &"incident"))
	var pending_id := StringName(office._active_decision.get("id", &""))
	var selected := not office._selected_decision_option.is_empty()
	var copy := ""
	var detail := ""
	var semantic_icon := &"shield"
	if pending_kind == Office.FIRST_CLUTCH_REINVESTMENT_KIND:
		semantic_icon = &"egg"
	elif pending_kind == &"directive":
		semantic_icon = &"goal"
	elif pending_kind in [&"credit_allocation", &"major_event"]:
		semantic_icon = &"cash"
	elif pending_id == &"flock_restructuring":
		semantic_icon = &"flock"
	var visible_label := ""
	var actionable := false
	var icon_visible := false
	if selected and office._decision_confirm_button != null:
		visible_label = office._decision_confirm_button.text.strip_edges()
		copy = (
			"FIRST EGG: %s" % visible_label
			if pending_kind == Office.FIRST_CLUTCH_REINVESTMENT_KIND else
			visible_label
		)
		detail = (
			"Selected first-egg option. Press Enter to %s, or choose another option; no change occurs until filing."
			% visible_label
			if pending_kind == Office.FIRST_CLUTCH_REINVESTMENT_KIND else
			"Selected response ready. Press Enter to %s, or choose another card; no change occurs until authorization."
			% visible_label
		)
		actionable = not office._decision_confirm_button.disabled
		icon_visible = office._decision_confirm_button.icon != null
	else:
		match pending_kind:
			Office.FIRST_CLUTCH_REINVESTMENT_KIND:
				copy = "FIRST EGG: REWARD MABEL OR BANK"
				detail = "Choose where Mabel's first egg goes: install one desk upgrade or bank the spendable fund. Exact cost and payoff are shown before filing."
				semantic_icon = &"egg"
			&"directive":
				copy = "DECIDE: CHOOSE + AUTHORIZE ONE POLICY"
				detail = "Morning briefing: select a policy card, review its exact cost, then authorize."
				semantic_icon = &"goal"
			&"credit_allocation", &"major_event":
				copy = "CREDIT: ASSIGN THE FLOCK'S WORK"
				detail = "Closing file: attribute the flock's work before next-shift planning can continue."
				semantic_icon = &"cash"
			_:
				if pending_id == &"flock_restructuring":
					copy = "DECIDE: WHO CARRIES THE RANKING COST?"
					detail = "Restructuring file: inspect the omitted context before deciding who pays for the ranking."
					semantic_icon = &"flock"
				else:
					copy = "INCIDENT: CHOOSE A RESPONSE"
					detail = "The shift is safely paused until management records a response."
		for option_button: Button in office._decision_option_buttons:
			if option_button != null and not option_button.disabled:
				actionable = true
				break
	return {
		"copy": copy,
		"visible_label": visible_label if not visible_label.is_empty() else copy,
		"action_id": "decision",
		"actionable": actionable,
		"semantic_icon": String(semantic_icon),
		"icon_visible": icon_visible,
		"accessible_text": detail,
		"stage": "confirm" if selected else "select",
	}


func _focus_decision_primary_action() -> bool:
	var action := office._decision_primary_action_state()
	if action.is_empty() or not bool(action.get("actionable", false)):
		return false
	if String(action.get("stage", "select")) == "confirm":
		office._decision_confirm_button.grab_focus()
		office._pulse_action_target(office._decision_panel)
		return true
	for option_button: Button in office._decision_option_buttons:
		if option_button != null and not option_button.disabled:
			option_button.grab_focus()
			office._pulse_action_target(office._decision_panel)
			return true
	return false


func _capture_decision_preview() -> void:
	office._ensure_preview_runner()
	await office._preview_runner.call("_capture_decision_preview")
