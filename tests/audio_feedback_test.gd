extends SceneTree

const AudioFeedbackScript := preload("res://features/office/office_audio_feedback.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	# Godot conventionally installs res://default_bus_layout.tres before the first
	# scene. Verify that path directly before OfficeAudioFeedback's safe fallback.
	for startup_bus_name in [&"Master", &"SFX", &"UI", &"Music", &"Ambient"]:
		_check(
			AudioServer.get_bus_index(startup_bus_name) >= 0,
			"%s bus should auto-load before feedback instantiation" % startup_bus_name,
			failures,
		)
	var audio := AudioFeedbackScript.new()
	root.add_child(audio)
	await process_frame
	var voices := audio.find_children("SFXVoice_*", "AudioStreamPlayer", true, false)
	var original_voice_ids: Array[int] = []
	for voice in voices:
		original_voice_ids.append(voice.get_instance_id())
	var cue_events: Array[StringName] = []
	audio.cue_played.connect(func(cue: StringName) -> void:
		cue_events.append(cue)
	)
	_check(voices.size() == 8, "audio feedback should use a fixed voice pool", failures)
	var bus_layout := load("res://default_bus_layout.tres") as AudioBusLayout
	_check(bus_layout != null, "the conventional production bus layout should load", failures)
	for bus_name in [&"Master", &"SFX", &"UI", &"Music", &"Ambient"]:
		_check(AudioServer.get_bus_index(bus_name) >= 0, "%s audio bus should exist" % bus_name, failures)
	var master_index := AudioServer.get_bus_index(&"Master")
	var limiter_count := 0
	var master_limiter: AudioEffectLimiter
	for effect_index in AudioServer.get_bus_effect_count(master_index):
		var effect := AudioServer.get_bus_effect(master_index, effect_index)
		if effect is AudioEffectLimiter:
			limiter_count += 1
			master_limiter = effect as AudioEffectLimiter
	_check(limiter_count == 1, "Master should have exactly one production limiter", failures)
	_check(
		master_limiter != null and absf(master_limiter.ceiling_db + 1.0) <= 0.01,
		"Master limiter should retain the -1 dB production ceiling",
		failures,
	)
	AudioFeedbackScript.ensure_audio_buses()
	_check(
		AudioServer.get_bus_effect_count(master_index) == 1,
		"idempotent bus setup should not duplicate the Master limiter",
		failures,
	)
	audio.play_egg(&"sound", 1)
	audio.play_egg(&"golden", 4)
	audio.play_upgrade()
	audio.play_feed_party()
	audio.play_review()
	audio.play_decision_alert()
	audio.play_policy_stamp()
	audio.play_decision_resolved()
	var assigned := 0
	for voice in voices:
		if (voice as AudioStreamPlayer).stream != null:
			assigned += 1
	_check(assigned == 8, "core loop and management decisions should fill the reusable procedural voice pool", failures)
	var ui_routed := 0
	var sfx_routed := 0
	for voice in voices:
		var player := voice as AudioStreamPlayer
		ui_routed += 1 if player.bus == &"UI" else 0
		sfx_routed += 1 if player.bus == &"SFX" else 0
	_check(ui_routed == 4 and sfx_routed == 4, "UI and physical cues should route to separate buses", failures)
	for voice in voices:
		(voice as AudioStreamPlayer).stop()
		(voice as AudioStreamPlayer).stream = null

	# The production-line API must remain physical, semantic, and allocation-free.
	# Distinct cue IDs may play together while a rapid duplicate is rejected.
	await create_timer(0.20).timeout
	_check(audio.play_peck_contact(0, &"perfect"), "first dry peck contact should play", failures)
	_check(audio.play_lay_release(&"sound"), "lay release should play a nest thump", failures)
	_check(audio.play_sorter_clack(&"cracked"), "sorter grading should play a receipt clack", failures)
	_check(audio.play_basket_thunk(&"sound"), "collection should play a basket thunk", failures)
	_check(audio.play_payout_confirmation(455, &"golden"), "payout should play a Feed Fund confirmation", failures)
	_check(audio.play_attention_restored(), "clean assisted delivery should play a renewable-attention confirmation", failures)
	_check(audio.play_denied(&"held"), "rejected actions should have a distinct restrained cue", failures)
	_check(audio.play_shift_alert(1.0), "shift danger should have a protected alert cue", failures)
	_check(audio.play_feed_nibble(0), "first Feed Party attendee should have a physical eating cue", failures)
	_check(audio.play_feed_nibble(1), "different attendees should retain restrained pitch variation", failures)
	_check(not audio.play_feed_nibble(0), "duplicate eating contact from one attendee should be limited", failures)
	for required_cue in [
		&"peck_contact", &"lay_release", &"sorter_clack",
		&"basket_thunk", &"payout_confirmation", &"attention_restored",
		&"denied", &"shift_alert", &"feed_nibble",
	]:
		_check(required_cue in cue_events, "new feedback palette should emit %s" % required_cue, failures)

	# Final campaign outcomes use unmistakably different cadences and expose a
	# compact diagnostic receipt without adding playback nodes.
	await create_timer(0.20).timeout
	var serial_before_outcomes := int(audio.feedback_snapshot().get("cue_serial", -1))
	_check(audio.play_campaign_outcome(true), "passed probation should play its rising verdict cadence", failures)
	_check(audio.play_campaign_outcome(false), "failed probation should play its restrained descending verdict cadence", failures)
	_check(audio.play_commendation(), "permanent career recognition should play its brass filing cadence", failures)
	_check(&"campaign_pass" in cue_events and &"campaign_fail" in cue_events and &"commendation" in cue_events, "campaign verdicts and career recognition should emit distinct semantic cue IDs", failures)
	var verdict_snapshot := audio.feedback_snapshot()
	_check(String(verdict_snapshot.get("last_cue", "")) == "commendation", "feedback diagnostics should expose the latest semantic career cue", failures)
	_check(int(verdict_snapshot.get("cue_serial", -1)) == serial_before_outcomes + 3, "feedback diagnostics should advance once per accepted verdict or commendation", failures)
	_check(int(verdict_snapshot.get("voice_count", 0)) == 8, "verdict feedback should retain the fixed eight-voice pool", failures)

	await create_timer(0.07).timeout
	var first_contact_played := audio.play_peck_contact(1, &"steady")
	var duplicate_contact_played := audio.play_peck_contact(2, &"steady")
	_check(first_contact_played, "peck limiter should reopen after its short clarity window", failures)
	_check(not duplicate_contact_played, "peck limiter should reject a same-window duplicate", failures)

	# A routine quality must never consume the limiter window for a rare result.
	await create_timer(0.20).timeout
	for voice in voices:
		(voice as AudioStreamPlayer).stop()
		(voice as AudioStreamPlayer).stream = null
	_check(audio.play_sorter_clack(&"sound"), "routine sorter cue should play", failures)
	_check(audio.play_sorter_clack(&"golden"), "golden sorter cue should bypass the routine semantic window", failures)
	_check(not audio.play_sorter_clack(&"golden"), "duplicate golden sorter cue should still be limited", failures)

	# Fill every voice, then prove that an alert can preempt a lower-priority cue.
	await create_timer(0.20).timeout
	audio.play_egg(&"sound", 2)
	audio.play_egg(&"golden", 3)
	audio.play_upgrade()
	audio.play_feed_party()
	audio.play_review()
	audio.play_decision_alert()
	audio.play_policy_stamp()
	audio.play_decision_resolved()
	_check(audio.play_shift_alert(0.9), "a saturated pool should preserve a high-priority shift alert", failures)

	# Stress every public production cue. Limiting may suppress redundant playback,
	# but it must never grow or replace the eight preallocated player nodes.
	for event_index in 100:
		audio.play_peck_contact(event_index, &"steady")
		audio.play_lay_release(&"sound")
		audio.play_sorter_clack(&"sound")
		audio.play_basket_thunk(&"sound")
		audio.play_payout_confirmation(300 + event_index, &"sound")
		audio.play_attention_restored()
	var stressed_voices := audio.find_children("SFXVoice_*", "AudioStreamPlayer", true, false)
	var stressed_voice_ids: Array[int] = []
	for voice in stressed_voices:
		stressed_voice_ids.append(voice.get_instance_id())
	_check(stressed_voices.size() == 8, "100 production events must not grow the voice pool", failures)
	_check(stressed_voice_ids == original_voice_ids, "production cues should reuse the original playback nodes", failures)

	audio.set_focus_paused(true)
	_check(audio.is_focus_paused(), "feedback pool should expose focus pause state", failures)
	var serial_while_focused := int(audio.feedback_snapshot().get("cue_serial", -1))
	_check(not audio.play_denied(&"background"), "focus pause should discard new one-shots", failures)
	_check(not audio.play_campaign_outcome(true), "focus pause should discard verdict one-shots instead of resuming them late", failures)
	_check(int(audio.feedback_snapshot().get("cue_serial", -1)) == serial_while_focused, "discarded focus-paused cues should not advance diagnostics", failures)
	for voice in stressed_voices:
		_check(not (voice as AudioStreamPlayer).playing, "focus pause should stop active transient voices", failures)
	audio.set_focus_paused(false)
	_check(not audio.is_focus_paused(), "feedback pool should resume accepting focus-safe cues", failures)

	for voice in stressed_voices:
		(voice as AudioStreamPlayer).stop()
		(voice as AudioStreamPlayer).stream = null
	await process_frame
	await create_timer(0.20).timeout
	audio.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("AUDIO_FEEDBACK_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("AUDIO_FEEDBACK_TEST_PASSED voices=8 cues=procedural verdicts=distinct diagnostics=stable limiter=semantic priority=protected growth=none buses=SFX+UI")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
