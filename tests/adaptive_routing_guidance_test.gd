extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	office.call("_prepare_capture_running")
	var simulation := office.get("_simulation") as DepartmentSimulation
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var routing_ui := office.find_child(
		"PeckworkRoutingUI",
		true,
		false,
	) as PeckworkRoutingUI
	var guidance := office.get("_guidance_label") as Label
	var guidance_button := office.get("_guidance_action_button") as Button
	if campaign_ui != null:
		campaign_ui.show_active_campaign({})
	office.call("_set_campaign_modal_open", false)
	await process_frame
	_check(
		simulation != null and routing_ui != null and guidance != null
		and guidance_button != null,
		"Office should expose adaptive guidance authority and its existing action rail",
		failures,
	)
	if simulation == null or routing_ui == null or guidance == null or guidance_button == null:
		await _finish(office, failures)
		return

	var full_preferences := (office.get("_player_preferences") as Dictionary).duplicate(true)
	full_preferences["guidance_mode"] = "full"
	office.set("_player_preferences", full_preferences)
	office.call("_clear_adaptive_route_recovery")
	var first_worker := _worker_record(simulation, 0)
	var second_worker := _worker_record(simulation, 1)
	var first_wrong := _wrong_lane(first_worker)
	var second_wrong := _wrong_lane(second_worker)
	office.call("_on_worker_assignment_requested", 0, first_wrong)
	var first_state := office.call("_adaptive_route_recovery_diagnostic_state") as Dictionary
	_check(
		not bool(first_state.get("active", true))
		and int(first_state.get("miss_streak", -1)) == 1
		and StringName(office.get("_guidance_action_id")) != &"adaptive_route_recovery",
		"one valid off-specialty choice should remain quiet instead of being treated as a mistake",
		failures,
	)
	office.call("_on_worker_assignment_requested", 1, second_wrong)
	var repeated_state := office.call("_adaptive_route_recovery_diagnostic_state") as Dictionary
	_check(
		bool(repeated_state.get("active", false))
		and int(repeated_state.get("worker_id", -1)) == 1
		and int(repeated_state.get("miss_streak", 0)) == 2
		and StringName(office.get("_guidance_action_id")) == &"adaptive_route_recovery"
		and guidance.text == "OUT-OF-FIT x2  >  REVIEW %s" % String(
			second_worker.get("name", "HEN 2"),
		).to_upper()
		and "deliberate routes remain valid" in guidance.tooltip_text,
		"two consecutive mismatches should produce one respectful, exact, non-modal recovery action",
		failures,
	)
	office.call("_on_guidance_action_pressed")
	await process_frame
	_check(
		routing_ui.focused_worker_id() == 1
		and routing_ui.active_dossier_tab() == &"route"
		and root.gui_get_focus_owner() != null,
		"activating adaptive recovery should open the exact hen's route dossier without filing a choice",
		failures,
	)
	var second_specialty := StringName(String(second_worker.get("specialty", "")))
	office.call("_on_worker_assignment_requested", 1, second_specialty)
	var corrected_state := office.call("_adaptive_route_recovery_diagnostic_state") as Dictionary
	var corrected_notifications := office.call("_notification_diagnostic_state") as Dictionary
	var corrected_audio := (office.get("_audio_feedback") as OfficeAudioFeedback).feedback_snapshot()
	var corrected_announcement := office.call(
		"_web_accessibility_announcement",
		simulation.snapshot(),
		"",
	) as Dictionary
	var corrected_copy := "FIT RESTORED  ·  %s  >  %s" % [
		String(second_worker.get("name", "HEN 2")).to_upper(),
		_lane_label(second_specialty),
	]
	_check(
		not bool(corrected_state.get("active", true))
		and int(corrected_state.get("miss_streak", -1)) == 0
		and StringName(office.get("_guidance_action_id")) != &"adaptive_route_recovery"
		and bool(corrected_notifications.get("toast_visible", false))
		and String(corrected_notifications.get("toast_copy", "")) == corrected_copy
		and String(corrected_notifications.get("toast_priority", "")) == "milestone"
		and not (corrected_notifications.get("recent", []) as Array).is_empty()
		and String(((corrected_notifications.get("recent", []) as Array)[0] as Dictionary).get(
			"copy",
			"",
		)) == corrected_copy
		and "repeated out-of-fit pattern is cleared" in String(
			(office.get("_ticker_label") as Label).get_meta("accessible_text", ""),
		)
		and String(corrected_audio.get("last_cue", "")) == "attention_restored"
		and String(corrected_announcement.get("kind", "")) == "notification"
		and "Routing fit restored" in String(corrected_announcement.get("text", "")),
		"the exact coached hen's credentialed correction should quiet the cue and earn one concise multisensory recovery receipt",
		failures,
	)

	_normalize_then_repeat(office, simulation, 0, 1)
	var history_count_before_other_hen := (office.get("_status_history") as Array).size()
	var haptic_serial_before_other_hen := int(
		(office.get("_audio_feedback") as OfficeAudioFeedback).feedback_snapshot().get(
			"haptic_serial",
			-1,
		)
	)
	first_worker = _worker_record(simulation, 0)
	office.call(
		"_on_worker_assignment_requested",
		0,
		StringName(String(first_worker.get("specialty", ""))),
	)
	var other_hen_audio := (office.get("_audio_feedback") as OfficeAudioFeedback).feedback_snapshot()
	_check(
		not bool((office.call("_adaptive_route_recovery_diagnostic_state") as Dictionary).get(
			"active",
			true,
		))
		and (office.get("_status_history") as Array).size() == history_count_before_other_hen
		and String(other_hen_audio.get("last_cue", "")) != "attention_restored"
		and int(other_hen_audio.get("haptic_serial", -2)) == haptic_serial_before_other_hen,
		"a credentialed route on another hen should break the mistake streak without falsely claiming that the coached hen was corrected",
		failures,
	)

	_normalize_then_repeat(office, simulation, 0, 1)
	second_worker = _worker_record(simulation, 1)
	office.call("_on_worker_assignment_requested", 1, &"auto")
	var auto_notifications := office.call("_notification_diagnostic_state") as Dictionary
	_check(
		String(auto_notifications.get("toast_copy", ""))
		== "FIT RESTORED  ·  %s  >  AUTO" % String(
			second_worker.get("name", "HEN 2"),
		).to_upper()
		and "Auto, which favors filed specialties and urgent deadlines" in String(
			(office.get("_ticker_label") as Label).get_meta("accessible_text", ""),
		),
		"Auto should provide the same truthful recovery payoff while explaining its actual routing behavior",
		failures,
	)

	var essential_preferences := full_preferences.duplicate(true)
	essential_preferences["guidance_mode"] = "essential"
	office.set("_player_preferences", essential_preferences)
	_normalize_then_repeat(office, simulation, 0, 1)
	var essential_state := office.call("_adaptive_route_recovery_diagnostic_state") as Dictionary
	second_worker = _worker_record(simulation, 1)
	_check(
		bool(essential_state.get("active", false))
		and guidance.text == "RESTORE %s'S FIT  >  %s" % [
			String(second_worker.get("name", "HEN 2")).to_upper(),
			_lane_label(StringName(String(second_worker.get("specialty", "")))),
		]
		and "Two consecutive" in String(guidance.get_meta("accessible_text", "")),
		"Essential mode should retain the direct action while collapsing visible explanation",
		failures,
	)

	var off_preferences := full_preferences.duplicate(true)
	off_preferences["guidance_mode"] = "off"
	office.set("_player_preferences", off_preferences)
	office.call("_clear_adaptive_route_recovery")
	_normalize_then_repeat(office, simulation, 2, 3)
	var off_state := office.call("_adaptive_route_recovery_diagnostic_state") as Dictionary
	_check(
		not bool(off_state.get("active", true))
		and int(off_state.get("miss_streak", -1)) == 0
		and StringName(office.get("_guidance_action_id")) != &"adaptive_route_recovery",
		"Off mode should suppress adaptive coaching while leaving authoritative routing valid",
		failures,
	)

	office.set("_player_preferences", full_preferences)
	office.call("_clear_adaptive_route_recovery")
	_normalize_then_repeat(office, simulation, 2, 3)
	var expired := (office.get("_adaptive_route_recovery") as Dictionary).duplicate(true)
	expired["expires_at_msec"] = Time.get_ticks_msec() - 1
	office.set("_adaptive_route_recovery", expired)
	office.call("_update_guidance", simulation.snapshot())
	var expired_state := office.call("_adaptive_route_recovery_diagnostic_state") as Dictionary
	_check(
		not bool(expired_state.get("active", true))
		and StringName(office.get("_guidance_action_id")) != &"adaptive_route_recovery",
		"an ignored cue should expire on its own instead of nagging through successful play",
		failures,
	)
	await _finish(office, failures)


func _normalize_then_repeat(
	office: Office,
	simulation: DepartmentSimulation,
	first_worker_id: int,
	second_worker_id: int,
) -> void:
	var first := _worker_record(simulation, first_worker_id)
	var second := _worker_record(simulation, second_worker_id)
	office.call(
		"_on_worker_assignment_requested",
		first_worker_id,
		StringName(String(first.get("specialty", ""))),
	)
	office.call(
		"_on_worker_assignment_requested",
		second_worker_id,
		StringName(String(second.get("specialty", ""))),
	)
	first = _worker_record(simulation, first_worker_id)
	second = _worker_record(simulation, second_worker_id)
	office.call("_on_worker_assignment_requested", first_worker_id, _wrong_lane(first))
	office.call("_on_worker_assignment_requested", second_worker_id, _wrong_lane(second))


func _worker_record(simulation: DepartmentSimulation, worker_id: int) -> Dictionary:
	for worker_value in simulation.snapshot().get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return worker
	return {}


func _wrong_lane(worker: Dictionary) -> StringName:
	var specialty := StringName(String(worker.get("specialty", "")))
	var secondary := StringName(String(worker.get("secondary_specialty", "")))
	var current := StringName(String(worker.get("assigned_lane", "")))
	for lane: StringName in [&"nest_damage", &"predator_loss", &"appeals"]:
		if lane != specialty and lane != secondary and lane != current:
			return lane
	return &"auto"


func _lane_label(lane: StringName) -> String:
	match lane:
		&"nest_damage":
			return "NEST"
		&"predator_loss":
			return "PREDATOR"
		&"appeals":
			return "APPEALS"
	return String(lane).replace("_", " ").to_upper()


func _finish(office: Office, failures: Array[String]) -> void:
	office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("ADAPTIVE_ROUTING_GUIDANCE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print(
		"ADAPTIVE_ROUTING_GUIDANCE_TEST_PASSED threshold=2 single=quiet full=exact essential=compact off=suppressed correction=receipt+audio+announcement+exact-hen+auto expiry=bounded action=route-dossier"
	)
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
