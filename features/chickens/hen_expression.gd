class_name HenExpression
extends RefCounted

## Presentation only: samples bounded poses, never production or movement.
const DURATIONS := {&"proud": 2.2, &"golden": 2.8, &"promotion": 3.0, &"relief": 2.4, &"disappointed": 1.9}
var reaction: StringName = &""
var last_reaction: StringName = &""
var elapsed := 0.0
var serial := 0
var _waiting := 0.0
var _recent_events: Array[String] = []
var head := Vector3.ZERO
var body := Vector3.ZERO
var lift := 0.0
var wings := 0.0
var eyes := 1.0
var breath := 1.0
var sparkle := 0.0
var strain := 0.0
var checking := 0.0


func play(kind: StringName, event_key: String = "") -> bool:
	if not DURATIONS.has(kind) or (not event_key.is_empty() and event_key in _recent_events):
		return false
	# Keep a major earned celebration intact when a smaller event arrives.
	if reaction in [&"golden", &"promotion"] and kind in [&"proud", &"relief"]:
		return false
	if not event_key.is_empty():
		_recent_events.append(event_key)
		if _recent_events.size() > 16:
			_recent_events.pop_front()
	# Closely spaced successes share the current flourish instead of snapping
	# the same pose back to its first frame. They still get distinct receipts.
	if reaction == kind and elapsed < float(DURATIONS[kind]) * 0.72:
		serial += 1
		_waiting = 0.0
		return true
	reaction = kind
	last_reaction = kind
	elapsed = 0.0
	_waiting = 0.0
	serial += 1
	return true


func advance(delta: float, available: bool) -> void:
	if reaction.is_empty():
		return
	if not available:
		_waiting += delta
		if _waiting > 5.0:
			reaction = &""
		return
	elapsed += delta
	if elapsed >= float(DURATIONS[reaction]):
		reaction = &""


static func work_check(phase: float, worker: int) -> float:
	var cycle := fposmod(phase + worker * 1.37, 5.4 + (worker % 3) * 0.35)
	return smoothstep(3.7, 4.05, cycle) * (1.0 - smoothstep(4.75, 5.25, cycle))


func sample(phase: float, worker: int, stress: float, fatigue: float, working: bool, reduced: bool) -> void:
	head = Vector3.ZERO
	body = Vector3.ZERO
	lift = 0.0
	wings = 0.0
	eyes = 1.0
	sparkle = 0.0
	strain = smoothstep(48.0, 85.0, stress)
	checking = work_check(phase, worker) if working and not reduced else 0.0
	var tired := smoothstep(45.0, 90.0, fatigue)
	var motion := 0.0 if reduced else 1.0
	var personality_phase := phase + worker * 0.73
	# A quick read/check beat breaks up the mechanical endless peck loop.
	head.y = checking * sin(personality_phase * 1.8) * 0.25
	head.z = checking * (0.09 if worker % 2 == 0 else -0.09)
	head.x = checking * 0.12 - tired * 0.10
	body.z = sin(personality_phase * 1.3) * 0.018 * motion
	# Tension is held in the neck; occasional double-takes remain below panic.
	var fidget := smoothstep(0.60, 0.95, sin(personality_phase * 1.5)) * motion
	head.y += sin(personality_phase * 8.0) * strain * fidget * 0.14
	head.z += strain * 0.10
	body.x -= strain * 0.055
	lift -= tired * 0.045
	eyes = 1.0 - tired * 0.40 - strain * 0.12
	breath = 1.0 + sin(personality_phase * lerpf(2.0, 4.4, strain)) * lerpf(0.008, 0.019, strain) * motion
	# Individual working signatures, distinct even before anyone speaks.
	var signature := checking * motion * (1.0 - strain * 0.65)
	match posmod(worker, 6):
		0: # Mabel: an eager little lift and curious tilt.
			head.z += signature * 0.13
			lift += signature * 0.025
		1: # Pip: still, compact, with a restrained sideways check.
			head *= 0.72
			body.z *= 0.35
		2: # Henrietta: soft settling and a slow contented blink.
			lift -= signature * 0.025
			eyes *= 1.0 - signature * 0.22
		3: # Dot: a much wider look around the neighboring perches.
			head.y += sin(personality_phase * 2.3) * signature * 0.22
		4: # Agnes: two precise read/check nods.
			head.x += sin(personality_phase * 6.0) * signature * 0.09
		5: # Beatrice: the unmistakable skeptical tilt.
			head.z -= signature * 0.18
	if reaction.is_empty():
		return
	var t := clampf(elapsed / float(DURATIONS[reaction]), 0.0, 1.0)
	var envelope := smoothstep(0.0, 0.14, t) * (1.0 - smoothstep(0.72, 1.0, t))
	if reduced:
		envelope = 1.0
	match reaction:
		&"proud", &"golden", &"promotion":
			var big := reaction != &"proud"
			var nod := sin(t * TAU * (3.0 if big else 2.0)) * motion
			head.x += envelope * (0.16 - nod * 0.10)
			head.z += envelope * (0.12 if worker % 2 == 0 else -0.12)
			body.x += envelope * 0.10
			lift += envelope * (0.045 + maxf(0.0, nod) * 0.035) * motion
			wings = envelope * (0.26 if big else 0.16) * (0.75 + nod * 0.25) * motion
			eyes = lerpf(eyes, 0.55, envelope)
			sparkle = envelope
			var flourish := [1.15, 0.65, 0.80, 1.20, 0.72, 0.90][posmod(worker, 6)] as float
			wings *= flourish
		&"relief":
			head.x += envelope * 0.16
			body.x += envelope * 0.07
			breath += sin(t * PI) * 0.035 * motion
			eyes = lerpf(eyes, 0.28, envelope)
		&"disappointed":
			head.y += sin(t * TAU * 2.0) * 0.24 * envelope * motion
			head.x -= envelope * 0.19
			lift -= envelope * 0.035
			eyes = lerpf(eyes, 0.48, envelope)


func snapshot() -> Dictionary:
	return {"reaction": reaction, "last_reaction": last_reaction, "serial": serial, "elapsed": snappedf(elapsed, 0.01), "checking": checking > 0.5, "strain": snappedf(strain, 0.01), "eye_openness": snappedf(eyes, 0.01), "sparkle": sparkle > 0.05}
