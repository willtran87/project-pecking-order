extends SceneTree

const AudioFeedbackScript := preload("res://features/office/office_audio_feedback.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
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
	_check(AudioServer.get_bus_index(&"SFX") >= 0, "gameplay cues should route through the SFX bus", failures)
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
	for required_cue in [
		&"peck_contact", &"lay_release", &"sorter_clack",
		&"basket_thunk", &"payout_confirmation",
	]:
		_check(required_cue in cue_events, "new feedback palette should emit %s" % required_cue, failures)

	await create_timer(0.07).timeout
	var first_contact_played := audio.play_peck_contact(1, &"steady")
	var duplicate_contact_played := audio.play_peck_contact(2, &"steady")
	_check(first_contact_played, "peck limiter should reopen after its short clarity window", failures)
	_check(not duplicate_contact_played, "peck limiter should reject a same-window duplicate", failures)

	# Stress every public production cue. Limiting may suppress redundant playback,
	# but it must never grow or replace the eight preallocated player nodes.
	for event_index in 100:
		audio.play_peck_contact(event_index, &"steady")
		audio.play_lay_release(&"sound")
		audio.play_sorter_clack(&"sound")
		audio.play_basket_thunk(&"sound")
		audio.play_payout_confirmation(300 + event_index, &"sound")
	var stressed_voices := audio.find_children("SFXVoice_*", "AudioStreamPlayer", true, false)
	var stressed_voice_ids: Array[int] = []
	for voice in stressed_voices:
		stressed_voice_ids.append(voice.get_instance_id())
	_check(stressed_voices.size() == 8, "100 production events must not grow the voice pool", failures)
	_check(stressed_voice_ids == original_voice_ids, "production cues should reuse the original playback nodes", failures)

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
	print("AUDIO_FEEDBACK_TEST_PASSED voices=8 cues=procedural limiter=covered growth=none bus=SFX")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
