class_name OfficeAudioFeedback
extends Node

signal cue_played(cue: StringName)

## Small pooled procedural sound palette. The prototype has no external audio
## dependencies, so these short cues are synthesized once and reused by eight
## voices instead of allocating a player for every egg or button press.

const VOICE_COUNT := 8
const SAMPLE_RATE := 22050
const PECK_CONTACT_PITCHES: Array[float] = [0.96, 1.02, 1.08]
const BUS_SFX: StringName = &"SFX"
const BUS_UI: StringName = &"UI"
const BUS_MUSIC: StringName = &"Music"
const BUS_AMBIENT: StringName = &"Ambient"
const PRIORITY_ROUTINE := 20
const PRIORITY_PHYSICAL := 40
const PRIORITY_CONFIRMATION := 70
const PRIORITY_IMPORTANT := 85
const PRIORITY_RARE := 95
const PRIORITY_ALERT := 100

var _voices: Array[AudioStreamPlayer] = []
var _voice_cursor := 0
var _voice_priorities: Array[int] = []
var _voice_started_msec: Array[int] = []
var _voice_cues: Array[StringName] = []
var _last_cue_msec: Dictionary[StringName, int] = {}
var _focus_paused := false
var _last_played_cue: StringName = &""
var _cue_serial := 0
var _sound_egg: AudioStreamWAV
var _cracked_egg: AudioStreamWAV
var _golden_egg: AudioStreamWAV
var _upgrade_approved: AudioStreamWAV
var _feed_party: AudioStreamWAV
var _feed_nibble: AudioStreamWAV
var _review_stamp: AudioStreamWAV
var _ui_tick: AudioStreamWAV
var _decision_alert: AudioStreamWAV
var _policy_stamp: AudioStreamWAV
var _decision_resolved: AudioStreamWAV
var _precedent_filed: AudioStreamWAV
var _peck_assist: AudioStreamWAV
var _peck_assist_perfect: AudioStreamWAV
var _peck_contact: AudioStreamWAV
var _lay_nest_thump: AudioStreamWAV
var _sorter_receipt_clack: AudioStreamWAV
var _basket_thunk: AudioStreamWAV
var _payout_confirmation: AudioStreamWAV
var _attention_restored: AudioStreamWAV
var _denied: AudioStreamWAV
var _shift_alert: AudioStreamWAV
var _campaign_pass: AudioStreamWAV
var _campaign_fail: AudioStreamWAV
var _commendation_stamp: AudioStreamWAV


func _ready() -> void:
	name = "OfficeAudioFeedback"
	ensure_audio_buses()
	for voice_index in VOICE_COUNT:
		var player := AudioStreamPlayer.new()
		player.name = "SFXVoice_%02d" % voice_index
		player.bus = BUS_SFX
		player.volume_db = -9.0
		add_child(player)
		_voices.append(player)
		_voice_priorities.append(0)
		_voice_started_msec.append(0)
		_voice_cues.append(&"")
		player.finished.connect(_on_voice_finished.bind(voice_index))
	_sound_egg = _synth_chirp(420.0, 610.0, 0.13, 0.55, 0.0)
	_cracked_egg = _synth_chirp(260.0, 95.0, 0.22, 0.62, 0.24)
	_golden_egg = _synth_sequence(PackedFloat32Array([660.0, 880.0, 1175.0]), 0.085, 0.46)
	_upgrade_approved = _synth_sequence(PackedFloat32Array([392.0, 523.0, 784.0]), 0.075, 0.38)
	_feed_party = _synth_sequence(PackedFloat32Array([330.0, 440.0, 494.0, 660.0]), 0.07, 0.34)
	# A short seed-and-beak crunch gives each physical arrival feedback without
	# becoming a second celebratory jingle or allocating a stream at runtime.
	_feed_nibble = _synth_impact(610.0, 155.0, 0.095, 0.24, 0.72, 3201, 0.46)
	_review_stamp = _synth_chirp(150.0, 92.0, 0.30, 0.58, 0.06)
	_ui_tick = _synth_chirp(520.0, 565.0, 0.055, 0.24, 0.0)
	_decision_alert = _synth_sequence(PackedFloat32Array([294.0, 294.0, 440.0]), 0.09, 0.42)
	_policy_stamp = _synth_sequence(PackedFloat32Array([349.0, 523.0, 698.0]), 0.085, 0.40)
	_decision_resolved = _synth_chirp(480.0, 720.0, 0.17, 0.38, 0.0)
	# One restrained stamp-and-rise cadence confirms that a decision changed a
	# future case. It remains a single pooled UI voice rather than layering the
	# ordinary resolution chirp with the policy stamp in the same frame.
	_precedent_filed = _synth_sequence(
		PackedFloat32Array([392.0, 294.0, 523.0, 698.0]),
		0.070,
		0.38,
	)
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
	_attention_restored = _synth_sequence(PackedFloat32Array([520.0, 690.0, 920.0]), 0.050, 0.36)
	_denied = _synth_sequence(PackedFloat32Array([294.0, 247.0]), 0.075, 0.34)
	_shift_alert = _synth_sequence(PackedFloat32Array([330.0, 440.0, 330.0]), 0.070, 0.38)
	_campaign_pass = _synth_sequence(
		PackedFloat32Array([392.0, 523.25, 659.25, 784.0, 1046.5]),
		0.105,
		0.44,
	)
	_campaign_fail = _synth_sequence(
		PackedFloat32Array([349.25, 293.625, 246.875, 196.0]),
		0.135,
		0.40,
	)
	_commendation_stamp = _synth_sequence(
		PackedFloat32Array([523.25, 659.25, 784.0, 1046.5]),
		0.075,
		0.40,
	)


func _exit_tree() -> void:
	# Stop the pooled playbacks before their synthesized streams are released.
	# This is especially important for short-lived headless verification scenes.
	for voice in _voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
	_voices.clear()
	_voice_priorities.clear()
	_voice_started_msec.clear()
	_voice_cues.clear()


func play_egg(quality: StringName, streak: int) -> void:
	match quality:
		&"golden":
			_play(
				&"golden", _golden_egg, 1.0 + minf(0.10, streak * 0.008),
				-4.0, 40, BUS_SFX, PRIORITY_RARE,
			)
		&"cracked":
			_play(&"cracked", _cracked_egg, 0.96, -7.0, 55, BUS_SFX, PRIORITY_RARE)
		_:
			_play(
				&"sound", _sound_egg, 0.96 + minf(0.16, streak * 0.012),
				-10.0, 45, BUS_SFX, PRIORITY_PHYSICAL,
			)


func play_upgrade() -> void:
	_play(&"upgrade", _upgrade_approved, 1.0, -5.5, 80, BUS_UI, PRIORITY_IMPORTANT)


func play_feed_party() -> void:
	_play(&"feed", _feed_party, 1.0, -7.0, 120, BUS_SFX, PRIORITY_CONFIRMATION)


## Restrained feeding contact used once as each attendee reaches the trough.
## Worker-based pitch and limiter keys preserve a natural flock texture while
## still bounding duplicate signals from the same chicken.
func play_feed_nibble(worker_id: int) -> bool:
	var pitch_steps: Array[float] = [0.94, 1.0, 1.07]
	return _play(
		&"feed_nibble",
		_feed_nibble,
		pitch_steps[posmod(worker_id, pitch_steps.size())],
		-12.0,
		140,
		BUS_SFX,
		PRIORITY_PHYSICAL,
		StringName("feed_nibble_%d" % maxi(0, worker_id)),
	)


func play_review() -> void:
	_play(&"review", _review_stamp, 1.0, -6.0, 180, BUS_SFX, PRIORITY_CONFIRMATION)


func play_ui_tick() -> void:
	_play(&"ui", _ui_tick, 1.0, -14.0, 32, BUS_UI, PRIORITY_ROUTINE)


func play_decision_alert() -> void:
	_play(
		&"decision_alert", _decision_alert, 1.0, -6.5, 180,
		BUS_UI, PRIORITY_ALERT,
	)


func play_policy_stamp() -> void:
	_play(&"policy", _policy_stamp, 1.0, -5.5, 160, BUS_UI, PRIORITY_IMPORTANT)


func play_decision_resolved() -> void:
	_play(
		&"decision_resolved", _decision_resolved, 1.0, -8.0, 100,
		BUS_UI, PRIORITY_CONFIRMATION,
	)


func play_precedent_filed() -> void:
	_play(
		&"precedent_filed", _precedent_filed, 1.0, -7.0, 180,
		BUS_UI, PRIORITY_IMPORTANT,
	)


func play_peck_assist(rating: StringName, streak: int) -> void:
	var perfect := rating == &"perfect"
	_play(
		&"peck_assist",
		_peck_assist_perfect if perfect else _peck_assist,
		1.0 + minf(0.16, maxi(0, streak) * 0.025),
		-5.0 if perfect else -7.0,
		80,
		BUS_UI,
		PRIORITY_IMPORTANT if perfect else PRIORITY_CONFIRMATION,
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
		BUS_SFX,
		PRIORITY_PHYSICAL,
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
		BUS_SFX,
		_quality_priority(quality, PRIORITY_PHYSICAL),
		_quality_limiter_key(&"lay_release", quality),
	)


## Sorter gate and receipt-printer clack, called when grading is authoritative.
func play_sorter_clack(quality: StringName = &"sound") -> bool:
	return _play(
		&"sorter_clack",
		_sorter_receipt_clack,
		_quality_pitch(quality),
		-8.0,
		80,
		BUS_SFX,
		_quality_priority(quality, PRIORITY_PHYSICAL),
		_quality_limiter_key(&"sorter_clack", quality),
	)


## Wooden collection impact, called when the retained egg reaches its basket.
func play_basket_thunk(quality: StringName = &"sound") -> bool:
	return _play(
		&"basket_thunk",
		_basket_thunk,
		_quality_pitch(quality) * 0.98,
		-7.5 if quality == &"golden" else -8.5,
		95,
		BUS_SFX,
		_quality_priority(quality, PRIORITY_PHYSICAL),
		_quality_limiter_key(&"basket_thunk", quality),
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
		BUS_UI,
		_quality_priority(quality, PRIORITY_CONFIRMATION),
		_quality_limiter_key(&"payout_confirmation", quality),
	)


## Short renewable-attention confirmation, synchronized with the transient
## +1 Priority Peck chip after a clean assisted egg reaches the farmer.
func play_attention_restored() -> bool:
	return _play(
		&"attention_restored",
		_attention_restored,
		1.0,
		-6.5,
		90,
		BUS_UI,
		PRIORITY_IMPORTANT,
	)


## A restrained descending hold tone for rejected or unavailable actions. The
## optional reason is intentionally not folded into the limiter key: repeated
## invalid input remains calm rather than becoming an alarm loop.
func play_denied(_reason: StringName = &"generic") -> bool:
	return _play(
		&"denied", _denied, 1.0, -8.5, 120,
		BUS_UI, PRIORITY_IMPORTANT,
	)


## A higher-priority shift-state warning. Severity changes intensity without
## creating additional streams or allowing routine navigation to steal it.
func play_shift_alert(severity: float = 1.0) -> bool:
	var normalized := clampf(severity, 0.0, 1.0)
	return _play(
		&"shift_alert",
		_shift_alert,
		0.94 + normalized * 0.12,
		lerpf(-10.5, -5.5, normalized),
		180,
		BUS_UI,
		PRIORITY_ALERT if normalized >= 0.65 else PRIORITY_IMPORTANT,
	)


## A final verdict deserves a semantic cadence rather than another generic
## review stamp. Pass rises into the established warm score; failure descends
## and settles without using a punitive alarm or manipulative celebration.
func play_campaign_outcome(passed: bool) -> bool:
	return _play(
		&"campaign_pass" if passed else &"campaign_fail",
		_campaign_pass if passed else _campaign_fail,
		1.0,
		-4.5 if passed else -6.0,
		750,
		BUS_UI,
		PRIORITY_ALERT,
	)


## Permanent recognition is a short brass-like filing cadence. It is distinct
## from payouts and campaign verdicts, uses the existing fixed voice pool, and
## has a generous limiter so several source facts settling together stay calm.
func play_commendation() -> bool:
	return _play(
		&"commendation",
		_commendation_stamp,
		1.0,
		-5.5,
		650,
		BUS_UI,
		PRIORITY_RARE,
	)


func feedback_snapshot() -> Dictionary:
	var active_voice_count := 0
	for voice in _voices:
		if voice.playing:
			active_voice_count += 1
	return {
		"voice_count": _voices.size(),
		"active_voice_count": active_voice_count,
		"last_cue": String(_last_played_cue),
		"cue_serial": _cue_serial,
		"focus_paused": _focus_paused,
	}


## Transient cues should not resume late after a tab or window regains focus.
## Pausing therefore clears active one-shots while retaining the fixed players
## and synthesized stream bank for immediate reuse.
func set_focus_paused(paused: bool) -> void:
	if _focus_paused == paused:
		return
	_focus_paused = paused
	if not paused:
		return
	for voice_index in _voices.size():
		var voice := _voices[voice_index]
		voice.stop()
		voice.stream = null
		_reset_voice_state(voice_index)


func is_focus_paused() -> bool:
	return _focus_paused


func _quality_pitch(quality: StringName) -> float:
	match quality:
		&"golden":
			return 1.08
		&"cracked":
			return 0.92
		_:
			return 1.0


func _quality_priority(quality: StringName, fallback: int) -> int:
	match quality:
		&"golden", &"cracked":
			return PRIORITY_RARE
		_:
			return fallback


func _quality_limiter_key(cue: StringName, quality: StringName) -> StringName:
	match cue:
		&"lay_release":
			return &"lay_release_golden" if quality == &"golden" else (
				&"lay_release_cracked" if quality == &"cracked" else &"lay_release_sound"
			)
		&"sorter_clack":
			return &"sorter_clack_golden" if quality == &"golden" else (
				&"sorter_clack_cracked" if quality == &"cracked" else &"sorter_clack_sound"
			)
		&"basket_thunk":
			return &"basket_thunk_golden" if quality == &"golden" else (
				&"basket_thunk_cracked" if quality == &"cracked" else &"basket_thunk_sound"
			)
		&"payout_confirmation":
			return &"payout_golden" if quality == &"golden" else (
				&"payout_cracked" if quality == &"cracked" else &"payout_sound"
			)
		_:
			return cue


func _play(
	cue: StringName,
	stream: AudioStream,
	pitch: float,
	volume_db: float,
	limiter_msec: int,
	bus: StringName = BUS_SFX,
	priority: int = PRIORITY_PHYSICAL,
	semantic_key: StringName = &"",
) -> bool:
	if stream == null or _voices.is_empty() or _focus_paused:
		return false
	var now := Time.get_ticks_msec()
	var limiter_key := semantic_key if semantic_key != &"" else cue
	if now - int(_last_cue_msec.get(limiter_key, -limiter_msec)) < limiter_msec:
		return false
	var player := _next_voice(priority)
	if player == null:
		return false
	_last_cue_msec[limiter_key] = now
	var voice_index := _voices.find(player)
	_voice_priorities[voice_index] = priority
	_voice_started_msec[voice_index] = now
	_voice_cues[voice_index] = cue
	player.stream = stream
	player.bus = bus
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()
	_last_played_cue = cue
	_cue_serial += 1
	cue_played.emit(cue)
	return true


func _next_voice(requested_priority: int) -> AudioStreamPlayer:
	for offset in VOICE_COUNT:
		var voice_index := (_voice_cursor + offset) % VOICE_COUNT
		var candidate := _voices[voice_index]
		if not candidate.playing:
			_voice_cursor = (voice_index + 1) % VOICE_COUNT
			return candidate

	# When saturated, steal the oldest voice in the lowest priority tier. A
	# routine request is dropped rather than cutting off an important result.
	var steal_index := -1
	var lowest_priority := PRIORITY_ALERT + 1
	var oldest_started := Time.get_ticks_msec()
	for offset in VOICE_COUNT:
		var voice_index := (_voice_cursor + offset) % VOICE_COUNT
		var voice_priority := _voice_priorities[voice_index]
		var voice_started := _voice_started_msec[voice_index]
		if (
			voice_priority < lowest_priority
			or (voice_priority == lowest_priority and voice_started < oldest_started)
		):
			steal_index = voice_index
			lowest_priority = voice_priority
			oldest_started = voice_started
	if steal_index < 0 or requested_priority < lowest_priority:
		return null
	var stolen := _voices[steal_index]
	_voice_cursor = (steal_index + 1) % VOICE_COUNT
	stolen.stop()
	return stolen


func _on_voice_finished(voice_index: int) -> void:
	if voice_index < 0 or voice_index >= _voices.size():
		return
	_voices[voice_index].stream = null
	_reset_voice_state(voice_index)


func _reset_voice_state(voice_index: int) -> void:
	_voice_priorities[voice_index] = 0
	_voice_started_msec[voice_index] = 0
	_voice_cues[voice_index] = &""


## The conventional res://default_bus_layout.tres installs this graph before
## scenes load. This idempotent fallback keeps isolated test scenes and imported
## embeddings safe without overriding a player's saved volume choices.
static func ensure_audio_buses() -> void:
	_ensure_bus(BUS_SFX, -3.0)
	_ensure_bus(BUS_UI, -4.0)
	_ensure_bus(BUS_MUSIC, -8.0)
	_ensure_bus(BUS_AMBIENT, -7.0)
	var master_index := AudioServer.get_bus_index(&"Master")
	if master_index < 0:
		return
	for effect_index in AudioServer.get_bus_effect_count(master_index):
		if AudioServer.get_bus_effect(master_index, effect_index) is AudioEffectLimiter:
			AudioServer.set_bus_effect_enabled(master_index, effect_index, true)
			return
	var limiter := AudioEffectLimiter.new()
	limiter.resource_name = "Production Ceiling"
	limiter.ceiling_db = -1.0
	limiter.threshold_db = -6.0
	limiter.soft_clip_db = 2.0
	limiter.soft_clip_ratio = 10.0
	AudioServer.add_bus_effect(master_index, limiter)


static func _ensure_bus(bus_name: StringName, default_volume_db: float) -> void:
	if AudioServer.get_bus_index(bus_name) < 0:
		AudioServer.add_bus()
		var bus_index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, &"Master")
		AudioServer.set_bus_volume_db(bus_index, default_volume_db)


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
