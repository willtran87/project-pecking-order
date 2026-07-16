class_name CheckpointCoordinator
extends RefCounted


## Deterministic scheduling state for durable checkpoints.
##
## The coordinator deliberately does not serialize or write data. A host marks
## mutations, polls claim_due_save(), captures its save payload for the returned
## generation, and reports the result through complete_save(). This handshake
## keeps the scheduler independently testable and allows a future Web host to
## perform an asynchronous filesystem sync without permitting overlapping saves.

const DEFAULT_QUIET_INTERVAL_MSEC := 750
const DEFAULT_MAXIMUM_INTERVAL_MSEC := 5000
const DEFAULT_RETRY_INTERVAL_MSEC := 1000
const MAX_DIAGNOSTIC_REASON_LENGTH := 160
const NO_TIMESTAMP := -1

var _quiet_interval_msec: int = DEFAULT_QUIET_INTERVAL_MSEC
var _maximum_interval_msec: int = DEFAULT_MAXIMUM_INTERVAL_MSEC
var _retry_interval_msec: int = DEFAULT_RETRY_INTERVAL_MSEC

var _generation: int = 0
var _persisted_generation: int = 0
var _in_flight_generation: int = 0
var _dirty_since_msec: int = NO_TIMESTAMP
var _dirty_after_in_flight_since_msec: int = NO_TIMESTAMP
var _last_dirty_msec: int = NO_TIMESTAMP
var _next_retry_msec: int = NO_TIMESTAMP
var _in_flight_started_msec: int = NO_TIMESTAMP
var _last_attempt_msec: int = NO_TIMESTAMP
var _last_success_msec: int = NO_TIMESTAMP
var _last_failure_msec: int = NO_TIMESTAMP

var _pending_reason: String = ""
var _in_flight_reason: String = ""
var _force_due: bool = false
var _saving: bool = false

var _write_attempt_count: int = 0
var _write_success_count: int = 0
var _write_failure_count: int = 0


func _init(
	quiet_interval_msec: int = DEFAULT_QUIET_INTERVAL_MSEC,
	maximum_interval_msec: int = DEFAULT_MAXIMUM_INTERVAL_MSEC,
	retry_interval_msec: int = DEFAULT_RETRY_INTERVAL_MSEC,
) -> void:
	configure(quiet_interval_msec, maximum_interval_msec, retry_interval_msec)


## Updates scheduling intervals. Existing dirty work is retained and immediately
## observes the new limits. A zero interval means the corresponding wait is due
## immediately.
func configure(
	quiet_interval_msec: int,
	maximum_interval_msec: int,
	retry_interval_msec: int,
) -> void:
	_quiet_interval_msec = maxi(0, quiet_interval_msec)
	_maximum_interval_msec = maxi(0, maximum_interval_msec)
	_retry_interval_msec = maxi(0, retry_interval_msec)


## Marks routine work. Repeated calls move the quiet deadline while the maximum
## deadline remains anchored to the first unsaved mutation.
func mark_routine(reason: String, now_msec: int = NO_TIMESTAMP) -> int:
	return _mark_dirty(reason, _resolve_now(now_msec), false)


## Marks work that must be claimable without waiting for either coalescing
## interval. If another save is active, the new generation becomes due as soon
## as that save completes.
func mark_immediate(reason: String, now_msec: int = NO_TIMESTAMP) -> int:
	return _mark_dirty(reason, _resolve_now(now_msec), true)


func is_dirty() -> bool:
	return _generation > _persisted_generation


func is_saving() -> bool:
	return _saving


func is_save_due(now_msec: int = NO_TIMESTAMP) -> bool:
	var now := _resolve_now(now_msec)
	if not is_dirty() or _saving:
		return false
	if _force_due:
		return true
	if _next_retry_msec != NO_TIMESTAMP:
		return now >= _next_retry_msec
	var due_at := _routine_due_at_msec()
	return due_at != NO_TIMESTAMP and now >= due_at


## Atomically claims the currently due generation. An empty Dictionary means no
## write should begin. The host must capture exactly this generation's payload
## before yielding and eventually call complete_save().
func claim_due_save(now_msec: int = NO_TIMESTAMP) -> Dictionary:
	var now := _resolve_now(now_msec)
	if not is_save_due(now):
		return {}
	_saving = true
	_in_flight_generation = _generation
	_in_flight_reason = _pending_reason
	_in_flight_started_msec = now
	_dirty_after_in_flight_since_msec = NO_TIMESTAMP
	_force_due = false
	_write_attempt_count += 1
	_last_attempt_msec = now
	return {
		"generation": _in_flight_generation,
		"reason": _in_flight_reason,
		"started_at_msec": _in_flight_started_msec,
	}


## Completes the sole active save. A success advances only to the generation
## returned by claim_due_save(); mutations marked while the write was active stay
## dirty. A failure retains all dirty work and schedules a bounded retry.
func complete_save(success: bool, now_msec: int = NO_TIMESTAMP) -> bool:
	if not _saving:
		return false
	var now := _resolve_now(now_msec)
	var completed_generation := _in_flight_generation
	_saving = false

	if success:
		_write_success_count += 1
		_last_success_msec = now
		_persisted_generation = maxi(_persisted_generation, completed_generation)
		_next_retry_msec = NO_TIMESTAMP
		if not is_dirty():
			_dirty_since_msec = NO_TIMESTAMP
			_last_dirty_msec = NO_TIMESTAMP
			_pending_reason = ""
			_force_due = false
		else:
			# Only mutations created after claim_due_save() remain. Restart their
			# maximum interval at the first such mutation rather than the generation
			# that was just persisted.
			_dirty_since_msec = (
				_dirty_after_in_flight_since_msec
				if _dirty_after_in_flight_since_msec != NO_TIMESTAMP
				else _last_dirty_msec
			)
	else:
		_write_failure_count += 1
		_last_failure_msec = now
		_next_retry_msec = now + _retry_interval_msec

	_in_flight_generation = 0
	_in_flight_reason = ""
	_in_flight_started_msec = NO_TIMESTAMP
	_dirty_after_in_flight_since_msec = NO_TIMESTAMP
	return true


## Abandons unsaved generations after the host has deliberately rolled back to
## a previously verified payload. This is intentionally unavailable during an
## active write: callers must first finish that write so its result cannot be
## confused with the restored state.
func discard_pending() -> bool:
	if _saving:
		return false
	_persisted_generation = _generation
	_dirty_since_msec = NO_TIMESTAMP
	_dirty_after_in_flight_since_msec = NO_TIMESTAMP
	_last_dirty_msec = NO_TIMESTAMP
	_next_retry_msec = NO_TIMESTAMP
	_pending_reason = ""
	_force_due = false
	return true


## Returns scalar-only, fixed-cardinality state suitable for a browser diagnostic
## bridge or compact HUD. It intentionally contains no save payload or reason
## history, and reasons are truncated at ingestion.
func diagnostic_snapshot(now_msec: int = NO_TIMESTAMP) -> Dictionary:
	var now := _resolve_now(now_msec)
	var due_at := _next_due_at_msec(now)
	var status := _status_at(now)
	return {
		"dirty": is_dirty(),
		"saving": _saving,
		"status": status,
		"reason": _in_flight_reason if _saving else _pending_reason,
		"generation": _generation,
		"persisted_generation": _persisted_generation,
		"in_flight_generation": _in_flight_generation,
		"due_at_msec": due_at,
		"due_in_msec": maxi(0, due_at - now) if due_at != NO_TIMESTAMP else NO_TIMESTAMP,
		"dirty_since_msec": _dirty_since_msec,
		"last_dirty_msec": _last_dirty_msec,
		"last_attempt_msec": _last_attempt_msec,
		"last_success_msec": _last_success_msec,
		"last_failure_msec": _last_failure_msec,
		"write_attempt_count": _write_attempt_count,
		"write_success_count": _write_success_count,
		"write_failure_count": _write_failure_count,
		"quiet_interval_msec": _quiet_interval_msec,
		"maximum_interval_msec": _maximum_interval_msec,
		"retry_interval_msec": _retry_interval_msec,
	}


func _mark_dirty(reason: String, now_msec: int, immediate: bool) -> int:
	var was_dirty := is_dirty()
	_generation += 1
	if not was_dirty:
		_dirty_since_msec = now_msec
	elif _saving and _generation > _in_flight_generation:
		if _dirty_after_in_flight_since_msec == NO_TIMESTAMP:
			_dirty_after_in_flight_since_msec = now_msec
	_last_dirty_msec = now_msec
	_pending_reason = _bounded_reason(reason)
	if immediate:
		_force_due = true
	return _generation


func _routine_due_at_msec() -> int:
	if _dirty_since_msec == NO_TIMESTAMP or _last_dirty_msec == NO_TIMESTAMP:
		return NO_TIMESTAMP
	var quiet_due := _last_dirty_msec + _quiet_interval_msec
	var maximum_due := _dirty_since_msec + _maximum_interval_msec
	return mini(quiet_due, maximum_due)


func _next_due_at_msec(now_msec: int) -> int:
	if not is_dirty() or _saving:
		return NO_TIMESTAMP
	if _force_due:
		return now_msec
	if _next_retry_msec != NO_TIMESTAMP:
		return _next_retry_msec
	return _routine_due_at_msec()


func _status_at(now_msec: int) -> String:
	if _saving:
		return "saving"
	if not is_dirty():
		return "clean"
	if is_save_due(now_msec):
		return "due"
	if _next_retry_msec != NO_TIMESTAMP:
		return "retry_wait"
	return "pending"


func _bounded_reason(reason: String) -> String:
	var normalized := reason.strip_edges()
	if normalized.is_empty():
		normalized = "unspecified"
	return normalized.substr(0, MAX_DIAGNOSTIC_REASON_LENGTH)


func _resolve_now(now_msec: int) -> int:
	return Time.get_ticks_msec() if now_msec == NO_TIMESTAMP else maxi(0, now_msec)
