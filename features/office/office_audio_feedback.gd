class_name OfficeAudioFeedback
extends Node

signal cue_played(cue: StringName)

## Small pooled procedural sound palette. The prototype has no external audio
## dependencies, so these short cues are synthesized once and reused by eight
## voices instead of allocating a player for every egg or button press.

const VOICE_COUNT := 8
const SAMPLE_RATE := 22050
const PECK_CONTACT_PITCHES: Array[float] = [0.96, 1.02, 1.08]

var _voices: Array[AudioStreamPlayer] = []
var _voice_cursor := 0
var _last_cue_msec: Dictionary[StringName, int] = {}
var _sound_egg: AudioStreamWAV
var _cracked_egg: AudioStreamWAV
var _golden_egg: AudioStreamWAV
var _upgrade_approved: AudioStreamWAV
var _feed_party: AudioStreamWAV
var _review_stamp: AudioStreamWAV
var _ui_tick: AudioStreamWAV
var _decision_alert: AudioStreamWAV
var _policy_stamp: AudioStreamWAV
var _decision_resolved: AudioStreamWAV
var _peck_assist: AudioStreamWAV
var _peck_assist_perfect: AudioStreamWAV
var _peck_contact: AudioStreamWAV
var _lay_nest_thump: AudioStreamWAV
var _sorter_receipt_clack: AudioStreamWAV
var _basket_thunk: AudioStreamWAV
var _payout_confirmation: AudioStreamWAV


func _ready() -> void:
	name = "OfficeAudioFeedback"
	_ensure_sfx_bus()
	for voice_index in VOICE_COUNT:
		var player := AudioStreamPlayer.new()
		player.name = "SFXVoice_%02d" % voice_index
		player.bus = &"SFX"
		player.volume_db = -9.0
		add_child(player)
		_voices.append(player)
	_sound_egg = _synth_chirp(420.0, 610.0, 0.13, 0.55, 0.0)
	_cracked_egg = _synth_chirp(260.0, 95.0, 0.22, 0.62, 0.24)
	_golden_egg = _synth_sequence(PackedFloat32Array([660.0, 880.0, 1175.0]), 0.085, 0.46)
	_upgrade_approved = _synth_sequence(PackedFloat32Array([392.0, 523.0, 784.0]), 0.075, 0.38)
	_feed_party = _synth_sequence(PackedFloat32Array([330.0, 440.0, 494.0, 660.0]), 0.07, 0.34)
	_review_stamp = _synth_chirp(150.0, 92.0, 0.30, 0.58, 0.06)
	_ui_tick = _synth_chirp(520.0, 565.0, 0.055, 0.24, 0.0)
	_decision_alert = _synth_sequence(PackedFloat32Array([294.0, 294.0, 440.0]), 0.09, 0.42)
	_policy_stamp = _synth_sequence(PackedFloat32Array([349.0, 523.0, 698.0]), 0.085, 0.40)
	_decision_resolved = _synth_chirp(480.0, 720.0, 0.17, 0.38, 0.0)
	_peck_assist = _synth_sequence(PackedFloat32Array([360.0, 470.0, 590.0]), 0.055, 0.34)
	_peck_assist_perfect = _synth_sequence(PackedFloat32Array([520.0, 690.0, 920.0]), 0.055, 0.40)
	# Physical production-line cues use short noise-rich transients rather than
	# melodic UI chirps. All streams are synthesized once and share the same
	# eight fixed playback voices as the existing palette.
	_peck_contact = _synth_impact(1180.0, 640.0, 0.050, 0.46, 0.58, 3101)
	_lay_nest_thump = _synth_impact(175.0, 72.0, 0.160, 0.55, 0.40, 3102)
	_sorter_receipt_clack = _synth_impact(920.0, 390.0, 0.110, 0.43, 0.32, 3103, 0.52)
	_basket_thunk = _synth_impact(128.0, 58.0, 0.185, 0.62, 0.30, 3104)
	_payout_confirmation = _synth_sequence(PackedFloat32Array([620.0, 930.0]), 0.050, 0.34)


func _exit_tree() -> void:
	# Stop the pooled playbacks before their synthesized streams are released.
	# This is especially important for short-lived headless verification scenes.
	for voice in _voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
	_voices.clear()


func play_egg(quality: StringName, streak: int) -> void:
	match quality:
		&"golden":
			_play(&"golden", _golden_egg, 1.0 + minf(0.10, streak * 0.008), -4.0, 40)
		&"cracked":
			_play(&"cracked", _cracked_egg, 0.96, -7.0, 55)
		_:
			_play(&"sound", _sound_egg, 0.96 + minf(0.16, streak * 0.012), -10.0, 45)


func play_upgrade() -> void:
	_play(&"upgrade", _upgrade_approved, 1.0, -5.5, 80)


func play_feed_party() -> void:
	_play(&"feed", _feed_party, 1.0, -7.0, 120)


func play_review() -> void:
	_play(&"review", _review_stamp, 1.0, -6.0, 180)


func play_ui_tick() -> void:
	_play(&"ui", _ui_tick, 1.0, -14.0, 32)


func play_decision_alert() -> void:
	_play(&"decision_alert", _decision_alert, 1.0, -6.5, 180)


func play_policy_stamp() -> void:
	_play(&"policy", _policy_stamp, 1.0, -5.5, 160)


func play_decision_resolved() -> void:
	_play(&"decision_resolved", _decision_resolved, 1.0, -8.0, 100)


func play_peck_assist(rating: StringName, streak: int) -> void:
	var perfect := rating == &"perfect"
	_play(
		&"peck_assist",
		_peck_assist_perfect if perfect else _peck_assist,
		1.0 + minf(0.16, maxi(0, streak) * 0.025),
		-5.0 if perfect else -7.0,
		80,
	)


## Dry beak/key contact, intended to be called from ChickenView's
## priority_peck_contact signal. Contact-index pitch is deterministic so rapid
## three-hit flourishes stay varied without runtime RNG or stream allocation.
func play_peck_contact(contact_index: int, rating: StringName = &"steady") -> bool:
	var pitch_index := posmod(contact_index, PECK_CONTACT_PITCHES.size())
	var pitch: float = PECK_CONTACT_PITCHES[pitch_index]
	if rating == &"perfect":
		pitch *= 1.045
	return _play(
		&"peck_contact",
		_peck_contact,
		pitch,
		-6.5 if rating == &"perfect" else -8.0,
		55,
	)


## Soft release/rustle plus nest contact. Quality shifts pitch subtly while the
## semantic identity remains physical rather than becoming another reward jingle.
func play_lay_release(quality: StringName = &"sound") -> bool:
	return _play(
		&"lay_release",
		_lay_nest_thump,
		_quality_pitch(quality),
		-6.5 if quality == &"golden" else -8.0,
		90,
	)


## Sorter gate and receipt-printer clack, called when grading is authoritative.
func play_sorter_clack(quality: StringName = &"sound") -> bool:
	return _play(
		&"sorter_clack",
		_sorter_receipt_clack,
		_quality_pitch(quality),
		-8.0,
		80,
	)


## Wooden collection impact, called when the retained egg reaches its basket.
func play_basket_thunk(quality: StringName = &"sound") -> bool:
	return _play(
		&"basket_thunk",
		_basket_thunk,
		_quality_pitch(quality) * 0.98,
		-7.5 if quality == &"golden" else -8.5,
		95,
	)


## Feed Fund confirmation, intended for the end of the payout-chip tween rather
## than the earlier lay event. Value only adds a bounded deterministic lift.
func play_payout_confirmation(
	value_cents: int = 0,
	quality: StringName = &"sound"
) -> bool:
	var value_lift := minf(0.10, float(maxi(0, value_cents)) / 12000.0)
	return _play(
		&"payout_confirmation",
		_payout_confirmation,
		_quality_pitch(quality) + value_lift,
		-6.0 if quality == &"golden" else -8.0,
		75,
	)


func _quality_pitch(quality: StringName) -> float:
	match quality:
		&"golden":
			return 1.08
		&"cracked":
			return 0.92
		_:
			return 1.0


func _play(
	cue: StringName,
	stream: AudioStream,
	pitch: float,
	volume_db: float,
	limiter_msec: int
) -> bool:
	if stream == null or _voices.is_empty():
		return false
	var now := Time.get_ticks_msec()
	if now - int(_last_cue_msec.get(cue, -limiter_msec)) < limiter_msec:
		return false
	_last_cue_msec[cue] = now
	var player := _next_voice()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()
	cue_played.emit(cue)
	return true


func _next_voice() -> AudioStreamPlayer:
	for offset in VOICE_COUNT:
		var candidate := _voices[(_voice_cursor + offset) % VOICE_COUNT]
		if not candidate.playing:
			_voice_cursor = (_voice_cursor + offset + 1) % VOICE_COUNT
			return candidate
	var stolen := _voices[_voice_cursor]
	_voice_cursor = (_voice_cursor + 1) % VOICE_COUNT
	stolen.stop()
	return stolen


func _ensure_sfx_bus() -> void:
	if AudioServer.get_bus_index(&"SFX") < 0:
		AudioServer.add_bus()
		var bus_index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, &"SFX")
		AudioServer.set_bus_send(bus_index, &"Master")
		AudioServer.set_bus_volume_db(bus_index, -3.0)


func _synth_chirp(start_hz: float, end_hz: float, duration: float, volume: float, noise_mix: float) -> AudioStreamWAV:
	var frame_count := maxi(1, roundi(SAMPLE_RATE * duration))
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(start_hz * 31.0 + end_hz * 17.0)
	for frame in frame_count:
		var t := float(frame) / float(maxi(1, frame_count - 1))
		var frequency := lerpf(start_hz, end_hz, smoothstep(0.0, 1.0, t))
		phase = fmod(phase + frequency / SAMPLE_RATE, 1.0)
		var attack := smoothstep(0.0, 0.08, t)
		var release := pow(1.0 - t, 1.65)
		var harmonic := sin(phase * TAU) * 0.82 + sin(phase * TAU * 2.0) * 0.18
		var noise := rng.randf_range(-1.0, 1.0)
		var sample := (harmonic * (1.0 - noise_mix) + noise * noise_mix) * attack * release * volume
		data.encode_s16(frame * 2, clampi(roundi(sample * 32767.0), -32768, 32767))
	return _make_wav(data)


func _synth_sequence(frequencies: PackedFloat32Array, note_duration: float, volume: float) -> AudioStreamWAV:
	var frames_per_note := maxi(1, roundi(SAMPLE_RATE * note_duration))
	var frame_count := frames_per_note * frequencies.size()
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var phase := 0.0
	for frame in frame_count:
		var note_index := mini(frequencies.size() - 1, frame / frames_per_note)
		var note_t := float(frame % frames_per_note) / float(frames_per_note)
		phase = fmod(phase + frequencies[note_index] / SAMPLE_RATE, 1.0)
		var envelope := smoothstep(0.0, 0.10, note_t) * pow(1.0 - note_t, 0.72)
		var sample := (sin(phase * TAU) * 0.78 + sin(phase * TAU * 2.0) * 0.22) * envelope * volume
		data.encode_s16(frame * 2, clampi(roundi(sample * 32767.0), -32768, 32767))
	return _make_wav(data)


func _synth_impact(
	start_hz: float,
	end_hz: float,
	duration: float,
	volume: float,
	noise_mix: float,
	seed: int,
	secondary_hit_at: float = -1.0
) -> AudioStreamWAV:
	var frame_count := maxi(1, roundi(SAMPLE_RATE * duration))
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for frame in frame_count:
		var t := float(frame) / float(maxi(1, frame_count - 1))
		var frequency := lerpf(start_hz, end_hz, smoothstep(0.0, 1.0, t))
		phase = fmod(phase + frequency / SAMPLE_RATE, 1.0)
		var primary := smoothstep(0.0, 0.022, t) * pow(1.0 - t, 4.2)
		var secondary := 0.0
		if secondary_hit_at >= 0.0 and t >= secondary_hit_at:
			var secondary_t := (t - secondary_hit_at) / maxf(0.001, 1.0 - secondary_hit_at)
			secondary = (
				smoothstep(0.0, 0.045, secondary_t)
				* pow(1.0 - secondary_t, 5.0)
				* 0.62
			)
		var envelope := maxf(primary, secondary)
		var body := sin(phase * TAU) * 0.76 + sin(phase * TAU * 2.35) * 0.24
		var noise := rng.randf_range(-1.0, 1.0)
		var sample := (
			(body * (1.0 - noise_mix) + noise * noise_mix)
			* envelope
			* volume
		)
		data.encode_s16(
			frame * 2,
			clampi(roundi(clampf(sample, -1.0, 1.0) * 32767.0), -32768, 32767),
		)
	return _make_wav(data)


func _make_wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = data
	return wav
