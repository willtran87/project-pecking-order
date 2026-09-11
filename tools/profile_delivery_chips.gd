extends SceneTree

## Read-only allocation profiler for the per-egg Feed Fund delivery feedback.
## Godot --headless --path . --script tools/profile_delivery_chips.gd

const SAMPLE_COUNT := 40


func _init() -> void:
	_profile.call_deferred()


func _profile() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	for _frame in 4:
		await process_frame
	var ui_root := office.get("_ui_root") as Control
	var objects_before := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var children_before := ui_root.get_child_count()
	var started := Time.get_ticks_usec()
	for sample_index in SAMPLE_COUNT:
		office.call(
			"_spawn_fund_credit_chip",
			100 + sample_index,
			&"golden" if sample_index % 10 == 0 else &"sound",
		)
	var spawn_usec := Time.get_ticks_usec() - started
	var objects_after := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes_after := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var active_after_spawn := _active_count(office)
	var visible_after_spawn := _visible_pool_count(office)
	office.call("_process_fund_credit_chip_pool", 1.0)
	print("DELIVERY_CHIP_PROFILE %s" % JSON.stringify({
		"sample_count": SAMPLE_COUNT,
		"spawn_total_usec": spawn_usec,
		"spawn_average_usec": float(spawn_usec) / float(SAMPLE_COUNT),
		"objects_created": objects_after - objects_before,
		"nodes_created": nodes_after - nodes_before,
		"ui_children_created": ui_root.get_child_count() - children_before,
		"pool_size": (office.get("_fund_credit_chip_pool") as Array).size(),
		"active_after_spawn": active_after_spawn,
		"visible_after_spawn": visible_after_spawn,
		"active_after_settle": _active_count(office),
		"visible_after_settle": _visible_pool_count(office),
	}))
	office.free()
	await process_frame
	quit(0)


func _active_count(office: Node) -> int:
	return (office.get("_active_fund_credit_chips") as Array).size()


func _visible_pool_count(office: Node) -> int:
	var visible := 0
	for visual in office.get("_fund_credit_chip_pool") as Array:
		var panel := visual.get("panel") as PanelContainer
		if panel.visible:
			visible += 1
	return visible
