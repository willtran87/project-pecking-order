extends SceneTree

## Read-only allocation profiler for the per-delivery Feed Fund number tween.
## Godot --headless --path . --script tools/profile_fund_counter.gd

const SAMPLE_COUNT := 40


func _init() -> void:
	_profile.call_deferred()


func _profile() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	for _frame in 4:
		await process_frame
	office.set("_displayed_revenue_cents", 1000)
	var objects_before := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var started := Time.get_ticks_usec()
	for sample_index in SAMPLE_COUNT:
		office.call("_tween_fund_to", 1100 + sample_index * 25)
	var total_usec := Time.get_ticks_usec() - started
	var objects_after := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes_after := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	print("FUND_COUNTER_PROFILE %s" % JSON.stringify({
		"sample_count": SAMPLE_COUNT,
		"total_usec": total_usec,
		"average_usec": float(total_usec) / float(SAMPLE_COUNT),
		"objects_created": objects_after - objects_before,
		"nodes_created": nodes_after - nodes_before,
	}))
	office.free()
	await process_frame
	quit(0)
