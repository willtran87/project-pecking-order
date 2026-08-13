class_name OfficeAudioDirector
extends Node

signal mix_target_changed(pressure: float, running: bool, review: bool)

## Fixed-player adaptive score for the open office. Eight deterministic authored
## Ogg stems ship with the game: long office and room-tone beds, pressure,
## momentum, review, and one identity for each replay scenario. Runtime updates
## move numeric mix targets or swap the single scenario player's preloaded
## stream; they never create players, decode generated PCM, timers, or tweens.

const AudioFeedbackScript := preload("res://features/office/office_audio_feedback.gd")
const BASE_TRACK := preload("res://assets/audio/authored_score/office_base.ogg")
const PRESSURE_TRACK := preload("res://assets/audio/authored_score/office_pressure.ogg")
const MOMENTUM_TRACK := preload("res://assets/audio/authored_score/office_momentum.ogg")
const REVIEW_TRACK := preload("res://assets/audio/authored_score/office_review.ogg")
const AMBIENT_TRACK := preload("res://assets/audio/authored_score/office_ambient.ogg")
const SCENARIO_HARVEST_TRACK := preload("res://assets/audio/authored_score/scenario_harvest.ogg")
const SCENARIO_AUDIT_TRACK := preload("res://assets/audio/authored_score/scenario_audit.ogg")
const SCENARIO_WALKOUT_TRACK := preload("res://assets/audio/authored_score/scenario_walkout.ogg")

const PLAYER_COUNT := 6
const ARRANGEMENT_SECONDS := 24.0
const AUTHORED_TRACK_COUNT := 8
const SILENCE_DB := -60.0
const BASE_RUNNING_DB := -9.5
const BASE_IDLE_DB := -15.0
const BASE_REVIEW_DB := -22.0
const PRESSURE_ACTIVE_DB := -11.0
const MOMENTUM_ACTIVE_DB := -13.0
const REVIEW_ACTIVE_DB := -10.5
const SCENARIO_ACTIVE_DB := -16.0
const AMBIENT_BASE_DB := -12.5

var _players: Array[AudioStreamPlayer] = []
var _base_player: AudioStreamPlayer
var _pressure_player: AudioStreamPlayer
var _momentum_player: AudioStreamPlayer
var _review_player: AudioStreamPlayer
var _scenario_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer

var _pressure_target := 0.0
var _pressure_blend := 0.0
var _momentum_target := 0.0
var _momentum_blend := 0.0
var _scenario_target := 0.0
var _scenario_blend := 0.0
var _running_target := false
var _review_target := false
var _overtime_target := false
var _focus_paused := false
var _scenario_id: StringName = &"baseline_book"


func _ready() -> void:
	name = "OfficeAudioDirector"
	AudioFeedbackScript.ensure_audio_buses()
	_base_player = _add_loop_player(
		"DirectorPlayer_MusicBase", OfficeAudioFeedback.BUS_MUSIC,
		_looping_copy(BASE_TRACK), BASE_IDLE_DB,
	)
	_pressure_player = _add_loop_player(
		"DirectorPlayer_MusicPressure", OfficeAudioFeedback.BUS_MUSIC,
		_looping_copy(PRESSURE_TRACK), SILENCE_DB,
	)
	_momentum_player = _add_loop_player(
		"DirectorPlayer_MusicMomentum", OfficeAudioFeedback.BUS_MUSIC,
		_looping_copy(MOMENTUM_TRACK), SILENCE_DB,
	)
	_review_player = _add_loop_player(
		"DirectorPlayer_MusicReview", OfficeAudioFeedback.BUS_MUSIC,
		_looping_copy(REVIEW_TRACK), SILENCE_DB,
	)
	_scenario_player = _add_loop_player(
		"DirectorPlayer_MusicScenario", OfficeAudioFeedback.BUS_MUSIC,
		_looping_copy(SCENARIO_HARVEST_TRACK), SILENCE_DB,
	)
	_ambient_player = _add_loop_player(
		"DirectorPlayer_Ambient", OfficeAudioFeedback.BUS_AMBIENT,
		_looping_copy(AMBIENT_TRACK), AMBIENT_BASE_DB,
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
	_review_player = null
	_scenario_player = null
	_ambient_player = null


func _process(delta: float) -> void:
	if _focus_paused or _players.size() != PLAYER_COUNT:
		return
	var response := 1.0 - exp(-maxf(0.0, delta) * 2.8)
	_pressure_blend = lerpf(_pressure_blend, _pressure_target, response)
	_momentum_blend = lerpf(_momentum_blend, _momentum_target, response)
	_scenario_blend = lerpf(_scenario_blend, _scenario_target, response)

	var base_target := BASE_IDLE_DB
	if _review_target:
		base_target = BASE_REVIEW_DB
	elif _running_target:
		base_target = BASE_RUNNING_DB - _pressure_blend * 2.5
	var pressure_db := _blended_db(_pressure_blend, PRESSURE_ACTIVE_DB, 0.78)
	var momentum_db := _blended_db(_momentum_blend, MOMENTUM_ACTIVE_DB, 0.82)
	var scenario_db := _blended_db(_scenario_blend, SCENARIO_ACTIVE_DB, 0.86)
	var review_db := REVIEW_ACTIVE_DB if _review_target else SILENCE_DB
	if not _running_target or _review_target:
		pressure_db = SILENCE_DB
		momentum_db = SILENCE_DB
		scenario_db = SILENCE_DB
	var ambient_target := AMBIENT_BASE_DB + _pressure_blend * 1.8
	if _review_target:
		ambient_target -= 4.0
	elif _overtime_target:
		ambient_target += 1.2

	_base_player.volume_db = lerpf(_base_player.volume_db, base_target, response)
	_pressure_player.volume_db = lerpf(_pressure_player.volume_db, pressure_db, response)
	_momentum_player.volume_db = lerpf(_momentum_player.volume_db, momentum_db, response)
	_review_player.volume_db = lerpf(_review_player.volume_db, review_db, response)
	_scenario_player.volume_db = lerpf(_scenario_player.volume_db, scenario_db, response)
	_ambient_player.volume_db = lerpf(_ambient_player.volume_db, ambient_target, response)


## Accepts DepartmentSimulation.snapshot() without depending on the simulation
## class. Missing fields resolve to a calm, paused baseline-office preview.
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
	var momentum := smoothstep(0.32, 1.0, quota_progress)
	momentum *= 1.0 - pressure * 0.28
	if quota_progress >= 1.0:
		momentum = 1.0
	if not running:
		pressure = 0.0
		momentum = 0.0
	var docket := snapshot.get("case_docket", {}) as Dictionary
	var scenario := docket.get("scenario", {}) as Dictionary
	var scenario_id := StringName(String(scenario.get("id", &"")))
	set_mix_target(
		pressure,
		running,
		review,
		overtime,
		momentum,
		scenario_id,
	)


## Explicit integration seam for previews, menus, and tests that do not own a
## complete simulation snapshot. An empty scenario ID preserves the active stem.
func set_mix_target(
	pressure: float,
	running: bool,
	review: bool = false,
	overtime: bool = false,
	momentum: float = 0.0,
	scenario_id: StringName = &"",
) -> void:
	_pressure_target = clampf(pressure, 0.0, 1.0)
	_momentum_target = clampf(momentum, 0.0, 1.0)
	_running_target = running
	_review_target = review
	_overtime_target = overtime
	if scenario_id != &"":
		_select_scenario(scenario_id)
	_scenario_target = (
		1.0
		if running and not review and _scenario_id != &"baseline_book" else
		0.0
	)
	mix_target_changed.emit(_pressure_target, _running_target, _review_target)


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
		"source": "authored_ogg",
		"authored_track_count": AUTHORED_TRACK_COUNT,
		"arrangement_seconds": ARRANGEMENT_SECONDS,
		"scenario_id": String(_scenario_id),
		"pressure_target": _pressure_target,
		"pressure_blend": _pressure_blend,
		"momentum_target": _momentum_target,
		"momentum_blend": _momentum_blend,
		"scenario_target": _scenario_target,
		"scenario_blend": _scenario_blend,
		"running": _running_target,
		"review": _review_target,
		"overtime": _overtime_target,
		"focus_paused": _focus_paused,
		"player_count": _players.size(),
		"loop_seconds": ARRANGEMENT_SECONDS,
		"raw_pcm_bytes": 0,
		"base_db": _volume(_base_player),
		"pressure_db": _volume(_pressure_player),
		"momentum_db": _volume(_momentum_player),
		"review_db": _volume(_review_player),
		"scenario_db": _volume(_scenario_player),
		"ambient_db": _volume(_ambient_player),
	}


func _select_scenario(next_id: StringName) -> void:
	var normalized := next_id
	if normalized not in [&"harvest_surge", &"shell_audit", &"flock_walkout"]:
		normalized = &"baseline_book"
	if normalized == _scenario_id:
		return
	_scenario_id = normalized
	if _scenario_player == null:
		return
	var source: AudioStream = SCENARIO_HARVEST_TRACK
	match _scenario_id:
		&"shell_audit":
			source = SCENARIO_AUDIT_TRACK
		&"flock_walkout":
			source = SCENARIO_WALKOUT_TRACK
	_scenario_player.stop()
	_scenario_player.stream = _looping_copy(source)
	_scenario_player.play()


func _looping_copy(source: AudioStream) -> AudioStream:
	var stream := source.duplicate() as AudioStream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
		(stream as AudioStreamOggVorbis).loop_offset = 0.0
	return stream


func _add_loop_player(
	player_name: String,
	bus: StringName,
	stream: AudioStream,
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


func _blended_db(blend: float, active_db: float, exponent: float) -> float:
	if blend <= 0.015:
		return SILENCE_DB
	return linear_to_db(lerpf(0.001, db_to_linear(active_db), pow(blend, exponent)))


func _volume(player: AudioStreamPlayer) -> float:
	return player.volume_db if player != null else SILENCE_DB
