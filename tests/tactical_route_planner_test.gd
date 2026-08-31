extends SceneTree

const PlannerScript := preload("res://core/experience/tactical_route_planner.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var planner = PlannerScript.new()
	var first := planner.queue_route(0, "Mabel", &"appeals", &"auto")
	var second := planner.queue_route(1, "Dot", &"predator_loss", &"auto")
	var revised := planner.queue_route(0, "Mabel", &"nest_damage", &"auto")
	var snapshot := planner.snapshot()
	_check(
		bool(first.get("accepted", false))
		and bool(second.get("accepted", false))
		and bool(revised.get("accepted", false))
		and bool(revised.get("replaced", false))
		and int(snapshot.get("count", 0)) == 2
		and String(((snapshot.get("queued", []) as Array)[0] as Dictionary).get("lane", "")) == "nest_damage",
		"replanning one hen should replace her preview without changing batch order",
		failures,
	)
	planner.queue_route(2, "Peep", &"appeals", &"auto")
	var full := planner.queue_route(3, "Babs", &"appeals", &"auto")
	_check(
		not bool(full.get("accepted", true))
		and String(full.get("reason", "")) == "PLAN FULL"
		and int((full.get("plan", {}) as Dictionary).get("count", 0)) == PlannerScript.CAPACITY,
		"the planner should hold exactly three unfiled routes",
		failures,
	)
	var cancelled := planner.cancel_route(1)
	var same_as_filed := planner.queue_route(0, "Mabel", &"auto", &"auto")
	_check(
		bool(cancelled.get("accepted", false))
		and not bool(same_as_filed.get("accepted", true))
		and int(planner.snapshot().get("count", 0)) == 1,
		"cancel and already-filed choices should safely remove previews",
		failures,
	)
	var filed := planner.drain()
	_check(
		filed.size() == 1
		and int((filed[0] as Dictionary).get("worker_id", -1)) == 2
		and planner.is_empty()
		and bool(planner.snapshot().get("files_nothing", false)),
		"drain should return the ordered command batch and reset the ephemeral preview",
		failures,
	)
	if not failures.is_empty():
		for failure in failures:
			push_error("TACTICAL_ROUTE_PLANNER_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("TACTICAL_ROUTE_PLANNER_TEST_PASSED capacity=3 replace=yes cancel=yes drain=ordered authority=simulation")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
