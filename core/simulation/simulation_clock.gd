class_name SimulationClock
extends Node

signal speed_changed(speed_index: int, multiplier: float)
signal tick_batch_completed(tick_count: int)
signal precision_focus_changed(active: bool, effective_multiplier: float)

const SPEED_MULTIPLIERS: Array[float] = [0.0, 1.0, 3.0, 10.0]
# At 1x a complete 8:00-17:00 shift now lasts 202.5 real seconds. That gives
# active managers enough time to read a dossier and make a decision before the
# 11:00 incident, while 3x and 10x retain the old fast-forward cadence for
# experienced players and automated waiting.
const BASE_TICK_SECONDS := 0.75
## A selected live claim is an intentional management interaction. While its
## Priority Peck timing band is approaching/open, Office may retain the
## player's requested speed while asking the clock for this readable effective
## pace. This is presentation-time dilation only; authoritative ticks, scoring,
## and the saved speed selection remain unchanged.
const PRECISION_FOCUS_MULTIPLIER := 1.0
# A long frame or a background-tab resume can make hundreds of logical ticks
# due at once. Keep that debt in the accumulator, but only service a bounded
# amount of it per rendered frame so simulation presentation work cannot form
# an unbounded main-thread spike. Four ticks still lets 10x catch up at any
# sustained frame rate above roughly 4.5 FPS.
const MAX_TICKS_PER_FRAME := 4

var speed_index: int = 1
var _accumulator: float = 0.0
var _simulation: DepartmentSimulation
var _ticks_advanced_last_frame: int = 0
var _advancing_tick_batch := false
var _precision_focus_active := false


func initialize(simulation: DepartmentSimulation) -> void:
	_simulation = simulation


func _process(delta: float) -> void:
	_ticks_advanced_last_frame = 0
	if _simulation == null or speed_index == 0:
		return

	_accumulator += delta * effective_multiplier()
	_advancing_tick_batch = true
	while (
		speed_index > 0
		and _accumulator >= BASE_TICK_SECONDS
		and _ticks_advanced_last_frame < MAX_TICKS_PER_FRAME
	):
		_accumulator -= BASE_TICK_SECONDS
		_simulation.advance_tick(false)
		_ticks_advanced_last_frame += 1
	if _ticks_advanced_last_frame > 0:
		# One newest read model per rendered frame keeps accelerated authority exact
		# without constructing and fanning out a full snapshot for intermediate ticks.
		_simulation.publish_current_snapshot()
	_advancing_tick_batch = false
	if _ticks_advanced_last_frame > 0:
		tick_batch_completed.emit(_ticks_advanced_last_frame)


## Number of authoritative ticks serviced by the most recent rendered frame.
## This is intentionally read-only instrumentation for profiling and tests.
func ticks_advanced_last_frame() -> int:
	return _ticks_advanced_last_frame


## Whole authoritative ticks retained for later frames. Fractional simulated
## time remains in the accumulator and is not reported until it becomes due.
func pending_tick_count() -> int:
	return maxi(0, floori(_accumulator / BASE_TICK_SECONDS))


func effective_multiplier() -> float:
	var requested := SPEED_MULTIPLIERS[speed_index]
	if _precision_focus_active and requested > PRECISION_FOCUS_MULTIPLIER:
		return PRECISION_FOCUS_MULTIPLIER
	return requested


func precision_focus_active() -> bool:
	return _precision_focus_active


func precision_focus_limiting() -> bool:
	return _precision_focus_active and SPEED_MULTIPLIERS[speed_index] > PRECISION_FOCUS_MULTIPLIER


func set_precision_focus_active(active: bool) -> void:
	if _precision_focus_active == active:
		return
	_precision_focus_active = active
	if active and speed_index > 1:
		# Do not let high-speed debt from the frame that discovered the window
		# burst through the first precision frame. Preserve only fractional time.
		_accumulator = fmod(_accumulator, BASE_TICK_SECONDS)
	precision_focus_changed.emit(active, effective_multiplier())


## True only while authoritative ticks are being serviced for one rendered
## frame. Consumers may retain the newest snapshot and present it after
## tick_batch_completed without coalescing direct management transactions.
func is_advancing_tick_batch() -> bool:
	return _advancing_tick_batch


func set_speed(new_speed_index: int) -> void:
	speed_index = clampi(new_speed_index, 0, SPEED_MULTIPLIERS.size() - 1)
	if speed_index == 0:
		_accumulator = 0.0
		_ticks_advanced_last_frame = 0
	speed_changed.emit(speed_index, SPEED_MULTIPLIERS[speed_index])


func toggle_pause() -> void:
	set_speed(1 if speed_index == 0 else 0)
