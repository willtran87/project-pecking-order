extends SceneTree

const AGENT_RADIUS := 0.30
const DESK_HALF_WIDTH := 1.35
const DESK_HALF_DEPTH := 0.68


func _init() -> void:
	var failures: Array[String] = []
	var starts: Array[Vector3] = []
	for worker_index in 6:
		var start := Office.entry_position(worker_index)
		starts.append(start)
		var route: Array[Vector3] = [start]
		route.append_array(Office.arrival_route(worker_index))
		_check_route_clear(route, worker_index, failures)
		var wellness: Array[Vector3] = [Office.chair_position(worker_index)]
		wellness.append_array(Office.wellness_route(worker_index))
		_check_route_clear(wellness, worker_index, failures)
		var feed_party: Array[Vector3] = [Office.chair_position(worker_index)]
		feed_party.append_array(Office.feed_party_route(worker_index))
		_check_route_clear(feed_party, worker_index, failures)

	for first in starts.size():
		for second in range(first + 1, starts.size()):
			_check(starts[first].distance_to(starts[second]) >= 0.90, "entry queue should keep chickens separated", failures)

	for first in 6:
		for second in range(first + 1, 6):
			var delta := Office.desk_position(first) - Office.desk_position(second)
			if first % 3 == second % 3:
				_check(absf(delta.z) >= 5.5, "desk rows need a full circulation gap", failures)
			elif int(first / 3) == int(second / 3):
				_check(absf(delta.x) >= 5.8, "desk columns need a full circulation gap", failures)

	for first in 6:
		var first_socket := Office.feed_party_attendance_position(first)
		_check(first_socket.distance_to(Vector3(-10.15, 0.0, 0.0)) >= 0.74, "feed socket %d should keep the chicken body outside the trough" % first, failures)
		for second in range(first + 1, 6):
			var second_socket := Office.feed_party_attendance_position(second)
			_check(first_socket.distance_to(second_socket) >= 0.82, "feed-party attendance sockets must not overlap", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("OFFICE_LAYOUT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OFFICE_LAYOUT_TEST_PASSED routes=18 floor=24x18 feed_sockets=6")
	quit(0)


func _check_route_clear(route: Array[Vector3], worker_index: int, failures: Array[String]) -> void:
	for point in route:
		_check(absf(point.x) <= 11.5 and absf(point.z) <= 8.5, "worker %d route must stay inside office margins" % worker_index, failures)
	for segment_index in route.size() - 1:
		var start := route[segment_index]
		var finish := route[segment_index + 1]
		var distance := start.distance_to(finish)
		var samples := maxi(1, int(ceil(distance / 0.08)))
		for sample in samples + 1:
			var point := start.lerp(finish, float(sample) / samples)
			for desk_index in 6:
				var desk := Office.desk_position(desk_index)
				var inside_x := absf(point.x - desk.x) < DESK_HALF_WIDTH + AGENT_RADIUS
				var inside_z := absf(point.z - desk.z) < DESK_HALF_DEPTH + AGENT_RADIUS
				_check(not (inside_x and inside_z), "worker %d route intersects desk %d" % [worker_index, desk_index], failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
