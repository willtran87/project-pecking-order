class_name OfficeAudioDirector
extends Node

signal mix_target_changed(pressure: float, running: bool, review: bool)

## Fixed-allocation adaptive score for the open office. Four short mono loops
## are synthesized once at startup: warm corporate muzak, a mechanical pressure
## stem, a positive clutch-momentum counterline, and restrained room tone.
## Snapshot updates only move numeric targets;
## _process performs allocation-free smoothing and never creates players,
## streams, timers, or tweens.

const AudioFeedbackScript := preload("res://features/office/office_audio_feedback.gd")
const PLAYER_COUNT := 4
const SAMPLE_RATE := 16000
const LOOP_SECONDS := 8.0
const CHORD_SECONDS := 2.0
const LOOP_FRAME_COUNT := int(SAMPLE_RATE * LOOP_SECONDS)
const SILENCE_DB := -60.0
const BASE_RUNNING_DB := -9.0
const BASE_IDLE_DB := -15.0
const BASE_REVIEW_DB := -18.0
const PRESSURE_ACTIVE_DB := -10.5
const MOMENTUM_ACTIVE_DB := -13.0
const AMBIENT_BASE_DB := -12.0

var _players: Array[AudioStreamPlayer] = []
var _base_player: AudioStreamPlayer
var _pressure_player: AudioStreamPlayer
var _momentum_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _base_stream: AudioStreamWAV
var _pressure_stream: AudioStreamWAV
var _momentum_stream: AudioStreamWAV
var _ambient_stream: AudioStreamWAV

var _pressure_target := 0.0
var _pressure_blend := 0.0
var _momentum_target := 0.0
var _momentum_blend := 0.0
var _running_target := false
var _review_target := false
var _overtime_target := false
var _focus_paused := false


func _ready() -> void:
	name = "OfficeAudioDirector"
	AudioFeedbackScript.ensure_audio_buses()
	_base_stream = _synth_cozy_office_loop()
	_pressure_stream = _synth_mechanical_pressure_loop()
	_momentum_stream = _synth_clutch_momentum_loop()
	_ambient_stream = _synth_open_office_ambience()
	_base_player = _add_loop_player(
		"DirectorPlayer_MusicBase", OfficeAudioFeedback.BUS_MUSIC,
		_base_stream, BASE_IDLE_DB,
	)
	_pressure_player = _add_loop_player(
		"DirectorPlayer_MusicPressure", OfficeAudioFeedback.BUS_MUSIC,
		_pressure_stream, SILENCE_DB,
	)
	_momentum_player = _add_loop_player(
		"DirectorPlayer_MusicMomentum", OfficeAudioFeedback.BUS_MUSIC,
		_momentum_stream, SILENCE_DB,
	)
	_ambient_player = _add_loop_player(
		"DirectorPlayer_Ambient", OfficeAudioFeedback.BUS_AMBIENT,
		_ambient_stream, AMBIENT_BASE_DB,
	)
	for player in _players:
		player.play()


func _exit_tree() -> void:
	for player in _players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_players.clear()
	_base_player = null
	_pressure_player = null
	_momentum_player = null
	_ambient_player = null
	_base_stream = null
	_pressure_stream = null
	_momentum_stream = null
	_ambient_stream = null


func _process(delta: float) -> void:
	if _focus_paused or _players.size() != PLAYER_COUNT:
		return
	var response := 1.0 - exp(-maxf(0.0, delta) * 2.8)
	_pressure_blend = lerpf(_pressure_blend, _pressure_target, response)
	_momentum_blend = lerpf(_momentum_blend, _momentum_target, response)

	var base_target := BASE_IDLE_DB
	if _review_target:
		base_target = BASE_REVIEW_DB
	elif _running_target:
		base_target = BASE_RUNNING_DB - _pressure_blend * 2.5
	var pressure_db := SILENCE_DB
	if _running_target and not _review_target and _pressure_blend > 0.015:
		# Interpolate in linear amplitude so the stem arrives gradually instead of
		# spending most of its range inaudibly below -40 dB.
		pressure_db = linear_to_db(
			lerpf(0.001, db_to_linear(PRESSURE_ACTIVE_DB), pow(_pressure_blend, 0.78))
		)
	var momentum_db := SILENCE_DB
	if _running_target and not _review_target and _momentum_blend > 0.015:
		momentum_db = linear_to_db(
			lerpf(0.001, db_to_linear(MOMENTUM_ACTIVE_DB), pow(_momentum_blend, 0.82))
		)
	var ambient_target := AMBIENT_BASE_DB + _pressure_blend * 1.8
	if _review_target:
		ambient_target -= 3.0
	elif _overtime_target:
		ambient_target += 1.2

	_base_player.volume_db = lerpf(_base_player.volume_db, base_target, response)
	_pressure_player.volume_db = lerpf(_pressure_player.volume_db, pressure_db, response)
	_momentum_player.volume_db = lerpf(_momentum_player.volume_db, momentum_db, response)
	_ambient_player.volume_db = lerpf(_ambient_player.volume_db, ambient_target, response)


## Accepts DepartmentSimulation.snapshot() without depending on the simulation
## class. Missing fields resolve to a calm, paused office preview.
func update_from_snapshot(snapshot: Dictionary) -> void:
	var phase := int(snapshot.get("shift_phase", 0))
	var running := phase == 1
	var review := phase == 3
	var minute := float(snapshot.get("minute_of_day", 480.0))
	var day_progress := clampf(inverse_lerp(480.0, 1020.0, minute), 0.0, 1.0)
	var quota := maxf(1.0, float(snapshot.get("quota_target", 1.0)))
	var quota_progress := clampf(float(snapshot.get("eggs_today", 0.0)) / quota, 0.0, 1.0)
	var quota_pressure := smoothstep(0.34, 1.0, day_progress) * (1.0 - quota_progress)
	var average_stress := _average_worker_stress(snapshot.get("workers", []))
	var overtime := bool(snapshot.get("overtime_enabled", false))
	var pressure := clampf(
		quota_pressure * 0.78 + average_stress * 0.16 + (0.24 if overtime else 0.0),
		0.0,
		1.0,
	)
	# Progress receives its own restrained counterline. Pressure may temper it,
	# but reaching quota remains unmistakably positive even late in the shift.
	var momentum := smoothstep(0.32, 1.0, quota_progress)
	momentum *= 1.0 - pressure * 0.28
	if quota_progress >= 1.0:
		momentum = 1.0
	if not running:
		pressure = 0.0
		momentum = 0.0
	set_mix_target(pressure, running, review, overtime, momentum)


## Explicit integration seam for previews, menus, and tests that do not own a
## complete simulation snapshot.
func set_mix_target(
	pressure: float,
	running: bool,
	review: bool = false,
	overtime: bool = false,
	momentum: float = 0.0,
) -> void:
	_pressure_target = clampf(pressure, 0.0, 1.0)
	_momentum_target = clampf(momentum, 0.0, 1.0)
	_running_target = running
	_review_target = review
	_overtime_target = overtime
	mix_target_changed.emit(_pressure_target, _running_target, _review_target)


## Looping beds may safely resume from their exact position after focus returns;
## unlike transient feedback, no stale one-shot is released late.
func set_focus_paused(paused: bool) -> void:
	if _focus_paused == paused:
		return
	_focus_paused = paused
	for player in _players:
		player.stream_paused = paused


func is_focus_paused() -> bool:
	return _focus_paused


func fixed_player_count() -> int:
	return _players.size()


func mix_snapshot() -> Dictionary:
	return {
		"pressure_target": _pressure_target,
		"pressure_blend": _pressure_blend,
		"momentum_target": _momentum_target,
		"momentum_blend": _momentum_blend,
		"running": _running_target,
		"review": _review_target,
		"overtime": _overtime_target,
		"focus_paused": _focus_paused,
		"player_count": _players.size(),
		"loop_seconds": LOOP_SECONDS,
		"raw_pcm_bytes": _raw_pcm_bytes(),
		"base_db": _base_player.volume_db if _base_player != null else SILENCE_DB,
		"pressure_db": _pressure_player.volume_db if _pressure_player != null else SILENCE_DB,
		"momentum_db": _momentum_player.volume_db if _momentum_player != null else SILENCE_DB,
		"ambient_db": _ambient_player.volume_db if _ambient_player != null else SILENCE_DB,
	}


func _raw_pcm_bytes() -> int:
	var total := 0
	for stream in [_base_stream, _pressure_stream, _momentum_stream, _ambient_stream]:
		if stream != null:
			total += (stream as AudioStreamWAV).data.size()
	return total


func _add_loop_player(
	player_name: String,
	bus: StringName,
	stream: AudioStreamWAV,
	volume_db: float,
) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	_players.append(player)
	return player


func _average_worker_stress(workers_value: Variant) -> float:
	if not workers_value is Array or (workers_value as Array).is_empty():
		return 0.0
	var workers := workers_value as Array
	var stress_total := 0.0
	var worker_count := 0
	for worker_value in workers:
		if worker_value is Dictionary:
			stress_total += clampf(
				float((worker_value as Dictionary).get("stress", 0.0)) / 100.0,
				0.0,
				1.0,
			)
			worker_count += 1
	return stress_total / float(worker_count) if worker_count > 0 else 0.0


func _synth_cozy_office_loop() -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(LOOP_FRAME_COUNT * 2)
	# An eight-second C / Am / F / G filing-floor progression keeps the warm
	# corporate satire but avoids hammering one static chord every four seconds.
	# Every frequency is quantized to an eighth of a hertz, so each oscillator
	# completes an integer number of cycles at the loop boundary.
	var chords: Array[PackedFloat32Array] = [
		PackedFloat32Array([130.75, 164.75, 196.0, 246.875]),
		PackedFloat32Array([110.0, 130.75, 164.75, 196.0]),
		PackedFloat32Array([87.375, 110.0, 130.75, 164.75]),
		PackedFloat32Array([98.0, 130.75, 146.875, 174.625]),
	]
	var melody := PackedFloat32Array([
		523.25, 659.25, 784.0, 659.25,
		440.0, 523.25, 659.25, 523.25,
		349.25, 440.0, 523.25, 659.25,
		392.0, 523.25, 587.375, 698.5,
	])
	for frame in LOOP_FRAME_COUNT:
		var time := float(frame) / float(SAMPLE_RATE)
		var chord_position := time / CHORD_SECONDS
		var chord_index := int(floor(chord_position)) % chords.size()
		var next_chord_index := (chord_index + 1) % chords.size()
		var chord_phase := fmod(time, CHORD_SECONDS) / CHORD_SECONDS
		var chord_blend := smoothstep(0.72, 1.0, chord_phase)
		var chord := lerpf(
			_chord_sample(chords[chord_index], time),
			_chord_sample(chords[next_chord_index], time),
			chord_blend,
		)
		var pulse_phase := fmod(time * 2.0, 1.0)
		var melody_index := int(floor(time * 2.0)) % melody.size()
		var mallet_envelope := pow(maxf(0.0, sin(PI * pulse_phase)), 4.5)
		var mallet := (
			sin(TAU * melody[melody_index] * time) * 0.74
			+ sin(TAU * melody[melody_index] * 2.0 * time) * 0.26
		) * mallet_envelope
		var breathing := 0.80 + sin(TAU * 0.125 * time - PI * 0.5) * 0.10
		var sample := (chord * 0.18 + mallet * 0.068) * breathing
		_encode_sample(data, frame, sample)
	return _make_loop_wav(data)


func _chord_sample(frequencies: PackedFloat32Array, time: float) -> float:
	# The progression always uses four-note voicings. Keep this sample hot path
	# allocation-free: it runs twice per frame while the loop is synthesized.
	return (
		sin(TAU * frequencies[0] * time) * 0.34
		+ sin(TAU * frequencies[1] * time) * 0.27
		+ sin(TAU * frequencies[2] * time) * 0.22
		+ sin(TAU * frequencies[3] * time) * 0.17
	)


func _synth_mechanical_pressure_loop() -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(LOOP_FRAME_COUNT * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41041
	for frame in LOOP_FRAME_COUNT:
		var time := float(frame) / float(SAMPLE_RATE)
		var tick_phase := fmod(time * 4.0, 1.0)
		var tick_envelope := exp(-tick_phase * 24.0)
		var tick_noise := rng.randf_range(-1.0, 1.0) * tick_envelope
		var clock_body := sin(TAU * 980.0 * time) * tick_envelope
		var machine := (
			sin(TAU * 61.25 * time) * 0.58
			+ sin(TAU * 92.0 * time) * 0.27
			+ sin(TAU * 123.0 * time) * 0.15
		)
		var printer_gate := pow(maxf(0.0, sin(TAU * 1.0 * time)), 10.0)
		var printer := rng.randf_range(-1.0, 1.0) * printer_gate
		var sample := machine * 0.13 + clock_body * 0.075 + tick_noise * 0.055 + printer * 0.035
		_encode_sample(data, frame, sample)
	return _make_loop_wav(data)


func _synth_clutch_momentum_loop() -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(LOOP_FRAME_COUNT * 2)
	# A complementary two-beat filing-bell line makes real clutch progress
	# audible without replacing the physical egg/payout cues. Frequencies are
	# eighth-hertz aligned so the eight-second loop remains seam-safe.
	var melody := PackedFloat32Array([
		261.625, 329.625, 392.0, 523.25,
		220.0, 329.625, 392.0, 493.875,
		174.625, 261.625, 349.25, 440.0,
		196.0, 293.625, 392.0, 523.25,
	])
	for frame in LOOP_FRAME_COUNT:
		var time := float(frame) / float(SAMPLE_RATE)
		var pulse_phase := fmod(time * 2.0, 1.0)
		var note_index := int(floor(time * 2.0)) % melody.size()
		var frequency := melody[note_index]
		var envelope := smoothstep(0.0, 0.035, pulse_phase) * exp(-pulse_phase * 5.6)
		var bell := (
			sin(TAU * frequency * time) * 0.70
			+ sin(TAU * frequency * 2.0 * time) * 0.22
			+ sin(TAU * frequency * 3.0 * time) * 0.08
		)
		var sample := bell * envelope * 0.17
		_encode_sample(data, frame, sample)
	return _make_loop_wav(data)


func _synth_open_office_ambience() -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(LOOP_FRAME_COUNT * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41042
	var filtered_noise := 0.0
	for frame in LOOP_FRAME_COUNT:
		var time := float(frame) / float(SAMPLE_RATE)
		filtered_noise = lerpf(filtered_noise, rng.randf_range(-1.0, 1.0), 0.012)
		var loop_phase := time / LOOP_SECONDS
		var noise_seam_window := (
			smoothstep(0.0, 0.06, loop_phase)
			* (1.0 - smoothstep(0.94, 1.0, loop_phase))
		)
		var vent_cycle := 0.72 + sin(TAU * 0.25 * time) * 0.18
		var electrical_hum := sin(TAU * 60.0 * time) * 0.60 + sin(TAU * 120.0 * time) * 0.24
		var distant_peck_gate := pow(maxf(0.0, sin(TAU * 0.5 * time)), 18.0)
		var distant_peck := sin(TAU * 720.0 * time) * distant_peck_gate
		var sample := (
			filtered_noise * noise_seam_window * vent_cycle * 0.16
			+ electrical_hum * 0.035
			+ distant_peck * 0.018
		)
		_encode_sample(data, frame, sample)
	return _make_loop_wav(data)


func _encode_sample(data: PackedByteArray, frame: int, sample: float) -> void:
	data.encode_s16(
		frame * 2,
		clampi(roundi(clampf(sample, -1.0, 1.0) * 32767.0), -32768, 32767),
	)


func _make_loop_wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = LOOP_FRAME_COUNT
	wav.data = data
	return wav
