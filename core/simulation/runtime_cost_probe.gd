extends RefCounted

## Explicit profiling only. No timers, logs, retained game objects or growing history.
var enabled := false
var _stages: Dictionary = {}
var _spikes: Array[Dictionary] = []


func begin() -> int:
	return Time.get_ticks_usec() if enabled else 0


func finish(stage: StringName, started: int) -> void:
	if started == 0:
		return
	var elapsed := Time.get_ticks_usec() - started
	if not _stages.has(stage):
		if _stages.size() >= 32:
			return
		_stages[stage] = [0, 0, 0, 0]
	var row: Array = _stages[stage]
	row[0] += 1
	row[1] += elapsed
	row[2] = maxi(row[2], elapsed)
	row[3] = elapsed
	if elapsed >= 20000:
		if _spikes.size() == 24:
			_spikes.pop_front()
		_spikes.append({"stage": String(stage), "usec": elapsed, "frame": Engine.get_process_frames()})


func snapshot() -> Dictionary:
	if not enabled:
		return {}
	var stages := {}
	for key in _stages:
		var row: Array = _stages[key]
		stages[key] = {"count": row[0], "total_usec": row[1], "max_usec": row[2], "last_usec": row[3]}
	return {"frame": Engine.get_process_frames(), "stages": stages, "spikes": _spikes.duplicate(true)}
