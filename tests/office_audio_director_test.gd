extends SceneTree

const DirectorScript := preload("res://features/office/office_audio_director.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var director := DirectorScript.new() as OfficeAudioDirector
	root.add_child(director)
	await process_frame

	var players := director.find_children("DirectorPlayer_*", "AudioStreamPlayer", true, false)
	_check(players.size() == 4, "director should own exactly four fixed loop players", failures)
	_check(director.fixed_player_count() == 4, "director should report its fixed player count", failures)
	var original_player_ids: Array[int] = []
	var original_stream_ids: Array[int] = []
	var music_players := 0
	var ambient_players := 0
	var raw_pcm_bytes := 0
	for player_value in players:
		var player := player_value as AudioStreamPlayer
		original_player_ids.append(player.get_instance_id())
		_check(player.stream is AudioStreamWAV, "%s should use one synthesized WAV loop" % player.name, failures)
		if player.stream is AudioStreamWAV:
			var wav := player.stream as AudioStreamWAV
			original_stream_ids.append(wav.get_instance_id())
			raw_pcm_bytes += wav.data.size()
			_check(wav.loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s should loop without runtime reconstruction" % player.name, failures)
			_check(wav.mix_rate == 16000 and not wav.stereo, "%s should use the bounded mono production format" % player.name, failures)
			_check(wav.loop_begin == 0 and wav.loop_end == 128_000, "%s should expose one exact eight-second loop region" % player.name, failures)
			_check(wav.data.size() == 256_000, "%s should retain one bounded eight-second mono buffer" % player.name, failures)
		music_players += 1 if player.bus == &"Music" else 0
		ambient_players += 1 if player.bus == &"Ambient" else 0
	_check(music_players == 3 and ambient_players == 1, "score stems and room tone should use separate buses", failures)
	_check(raw_pcm_bytes == 1_024_000, "four eight-second procedural loops should use exactly 1,024 KB of raw PCM", failures)
	var initial_mix := director.mix_snapshot()
	_check(float(initial_mix.get("loop_seconds", 0.0)) == 8.0, "diagnostics should disclose the full four-chord loop duration", failures)
	_check(int(initial_mix.get("raw_pcm_bytes", 0)) == raw_pcm_bytes, "diagnostics should disclose the exact fixed PCM footprint", failures)

	director.update_from_snapshot({
		"shift_phase": 1,
		"minute_of_day": 480,
		"quota_target": 12,
		"eggs_today": 0,
		"overtime_enabled": false,
		"workers": [{"stress": 0}],
	})
	var calm := director.mix_snapshot()
	_check(bool(calm["running"]), "running snapshot should activate the score", failures)
	_check(float(calm["pressure_target"]) <= 0.01, "morning office should begin calm", failures)
	_check(float(calm["momentum_target"]) <= 0.01, "an empty clutch should begin without a progress counterline", failures)
	director.call("_process", 1.0)

	director.update_from_snapshot({
		"shift_phase": 1,
		"minute_of_day": 720,
		"quota_target": 12,
		"eggs_today": 10,
		"overtime_enabled": false,
		"workers": [{"stress": 18}, {"stress": 24}],
	})
	var productive_target := director.mix_snapshot()
	_check(float(productive_target["momentum_target"]) >= 0.70, "a nearly complete clutch should expose strong positive momentum", failures)
	director.call("_process", 2.0)
	var productive_mix := director.mix_snapshot()
	_check(float(productive_mix["momentum_blend"]) >= 0.65, "the clutch counterline should approach its target smoothly", failures)
	_check(float(productive_mix["momentum_db"]) > -22.0, "the clutch counterline should become audible near quota", failures)

	director.update_from_snapshot({
		"shift_phase": 1,
		"minute_of_day": 1005,
		"quota_target": 12,
		"eggs_today": 1,
		"overtime_enabled": true,
		"workers": [{"stress": 92}, {"stress": 86}],
	})
	var pressured_target := director.mix_snapshot()
	_check(float(pressured_target["pressure_target"]) >= 0.90, "late missed quota and overtime should expose strong mechanical pressure", failures)
	director.call("_process", 2.0)
	var pressured_mix := director.mix_snapshot()
	_check(float(pressured_mix["pressure_blend"]) >= 0.85, "pressure stem should approach its target smoothly", failures)
	_check(float(pressured_mix["pressure_db"]) > -20.0, "mechanical stem should become audible under strong pressure", failures)

	director.update_from_snapshot({
		"shift_phase": 3,
		"minute_of_day": 1020,
		"quota_target": 12,
		"eggs_today": 1,
		"overtime_enabled": true,
		"workers": [{"stress": 100}],
	})
	var review := director.mix_snapshot()
	_check(bool(review["review"]) and not bool(review["running"]), "review should replace the live shift mix", failures)
	_check(float(review["pressure_target"]) == 0.0, "review should release quota-pressure targeting", failures)
	_check(float(review["momentum_target"]) == 0.0, "review should release live clutch momentum targeting", failures)
	director.call("_process", 2.0)
	_check(float(director.mix_snapshot()["pressure_db"]) <= -50.0, "review should smoothly silence the mechanical stem", failures)
	_check(float(director.mix_snapshot()["momentum_db"]) <= -50.0, "review should smoothly silence the clutch counterline", failures)

	director.set_focus_paused(true)
	_check(director.is_focus_paused(), "director should expose focus pause state", failures)
	for player_value in players:
		_check((player_value as AudioStreamPlayer).stream_paused, "focus pause should suspend every looping bed", failures)
	var paused_mix := director.mix_snapshot()
	director.call("_process", 5.0)
	_check(
		float(director.mix_snapshot()["pressure_blend"]) == float(paused_mix["pressure_blend"]),
		"focus pause should freeze mix smoothing",
		failures,
	)
	director.set_focus_paused(false)
	_check(not director.is_focus_paused(), "focus restore should resume the loop beds", failures)
	for player_value in players:
		_check(not (player_value as AudioStreamPlayer).stream_paused, "focus restore should unpause every loop player", failures)

	# Stress state updates without allowing the director to allocate any additional
	# nodes or regenerate its procedural content.
	for update_index in 500:
		director.set_mix_target(
			float(update_index % 101) / 100.0,
			update_index % 5 != 0,
			update_index % 17 == 0,
			update_index % 7 == 0,
			float((update_index * 7) % 101) / 100.0,
		)
		director.call("_process", 1.0 / 60.0)
	var stressed_players := director.find_children("DirectorPlayer_*", "AudioStreamPlayer", true, false)
	var stressed_player_ids: Array[int] = []
	var stressed_stream_ids: Array[int] = []
	for player_value in stressed_players:
		var player := player_value as AudioStreamPlayer
		stressed_player_ids.append(player.get_instance_id())
		stressed_stream_ids.append(player.stream.get_instance_id())
	_check(stressed_player_ids == original_player_ids, "500 mix updates should retain the original players", failures)
	_check(stressed_stream_ids == original_stream_ids, "500 mix updates should retain the original synthesized loops", failures)

	# Release mixer playback references before freeing the short-lived headless
	# fixture; the production node performs the same stop/null work in _exit_tree.
	for player_value in stressed_players:
		var player := player_value as AudioStreamPlayer
		player.stop()
		player.stream = null
	players.clear()
	stressed_players.clear()
	await process_frame
	await create_timer(0.20).timeout
	director.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("OFFICE_AUDIO_DIRECTOR_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OFFICE_AUDIO_DIRECTOR_TEST_PASSED players=4 loop=8s-progression pcm=1024000 buses=Music+Ambient pressure+momentum=adaptive focus=pause growth=none")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
