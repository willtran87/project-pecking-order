class_name SimulationClock
extends Node

signal speed_changed(speed_index: int, multiplier: float)

const SPEED_MULTIPLIERS: Array[float] = [0.0, 1.0, 3.0, 10.0]
# At 1x a complete 8:00-17:00 shift now lasts 202.5 real seconds. That gives
# active managers enough time to read a dossier and make a decision before the
# 11:00 incident, while 3x and 10x retain the old fast-forward cadence for
# experienced players and automated waiting.
const BASE_TICK_SECONDS := 0.75

var speed_index: int = 1
var _accumulator: float = 0.0
var _simulation: DepartmentSimulation


func initialize(simulation: DepartmentSimulation) -> void:
	_simulation = simulation


func _process(delta: float) -> void:
	if _simulation == null or speed_index == 0:
		return

	_accumulator += delta * SPEED_MULTIPLIERS[speed_index]
	while speed_index > 0 and _accumulator >= BASE_TICK_SECONDS:
		_accumulator -= BASE_TICK_SECONDS
		_simulation.advance_tick()


func set_speed(new_speed_index: int) -> void:
	speed_index = clampi(new_speed_index, 0, SPEED_MULTIPLIERS.size() - 1)
	if speed_index == 0:
		_accumulator = 0.0
	speed_changed.emit(speed_index, SPEED_MULTIPLIERS[speed_index])


func toggle_pause() -> void:
	set_speed(1 if speed_index == 0 else 0)
