class_name TacticalRoutePlanner
extends RefCounted

## Ephemeral command buffer for pause-mode routing. It owns intentions only;
## DepartmentSimulation remains the sole authority that can file a route.

const CAPACITY := 3

var _commands: Array[Dictionary] = []


func queue_route(
	worker_id: int,
	worker_name: String,
	lane: StringName,
	current_lane: StringName,
) -> Dictionary:
	if worker_id < 0 or lane == &"":
		return _receipt(false, "INVALID ROUTE", false)
	var existing_index := _index_for_worker(worker_id)
	if lane == current_lane:
		if existing_index >= 0:
			_commands.remove_at(existing_index)
			_normalize_order()
		return _receipt(false, "ALREADY FILED", existing_index >= 0)
	if existing_index < 0 and _commands.size() >= CAPACITY:
		return _receipt(false, "PLAN FULL", false)
	var clean_name := worker_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "HEN %d" % (worker_id + 1)
	var replaced := existing_index >= 0
	var entry := {
		"worker_id": worker_id,
		"worker_name": clean_name,
		"lane": String(lane),
		"previous_lane": String(
			_commands[existing_index].get("previous_lane", current_lane)
			if replaced else current_lane
		),
		"order": existing_index + 1 if replaced else _commands.size() + 1,
	}
	if replaced:
		_commands[existing_index] = entry
	else:
		_commands.append(entry)
	return _receipt(true, "ROUTE REVISED" if replaced else "ROUTE QUEUED", replaced, entry)


func cancel_route(worker_id: int) -> Dictionary:
	var index := _index_for_worker(worker_id)
	if index < 0:
		return _receipt(false, "NOT QUEUED", false)
	var removed := _commands[index].duplicate(true)
	_commands.remove_at(index)
	_normalize_order()
	return _receipt(true, "ROUTE REMOVED", false, removed)


func drain() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for command in _commands:
		result.append(command.duplicate(true))
	_commands.clear()
	return result


func clear() -> void:
	_commands.clear()


func is_empty() -> bool:
	return _commands.is_empty()


func snapshot() -> Dictionary:
	var queued: Array[Dictionary] = []
	for command in _commands:
		queued.append(command.duplicate(true))
	return {
		"count": queued.size(),
		"capacity": CAPACITY,
		"queued": queued,
		"files_nothing": true,
		"commits_on_resume": true,
		"can_replace": true,
		"can_cancel": true,
		"ephemeral": true,
	}


func _index_for_worker(worker_id: int) -> int:
	for index in _commands.size():
		if int(_commands[index].get("worker_id", -1)) == worker_id:
			return index
	return -1


func _normalize_order() -> void:
	for index in _commands.size():
		_commands[index]["order"] = index + 1


func _receipt(
	accepted: bool,
	reason: String,
	replaced: bool,
	entry: Dictionary = {},
) -> Dictionary:
	return {
		"accepted": accepted,
		"reason": reason,
		"replaced": replaced,
		"entry": entry.duplicate(true),
		"plan": snapshot(),
	}
