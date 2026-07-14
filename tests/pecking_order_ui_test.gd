extends SceneTree

const PeckingOrderUIScript := preload("res://features/office/pecking_order_ui.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observed := {"selected_worker": -1}
	var harness := Control.new()
	harness.name = "PeckingOrderUITestHarness"
	harness.size = Vector2(260.0, 760.0)
	root.add_child(harness)
	var host := MarginContainer.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	harness.add_child(host)
	var ui = PeckingOrderUIScript.new()
	host.add_child(ui)
	ui.worker_selected.connect(func(worker_id: int) -> void: observed["selected_worker"] = worker_id)
	await process_frame

	ui.apply_snapshot({
		"day": 2,
		"pecking_order": [
			_rank_row(3, 2, "Clover", 2, 2, 0, 0, 160, true),
			_rank_row(1, 0, "Mabel", 7, 5, 1, 1, 580, true),
			_rank_row(1, 3, "Agnes", 5, 4, 0, 1, 510, true),
			_rank_row(2, 1, "Penny", 4, 4, 0, 0, 300, true),
			_rank_row(0, 8, "Applicant", 99, 99, 0, 0, 9999, false),
		],
	})
	await process_frame
	await process_frame

	var live_rows := _row_buttons(ui)
	_check(live_rows.size() == 4, "leaderboard should render employed hens only", failures)
	_check(
		_worker_ids(live_rows) == [0, 3, 1, 2],
		"rows should sort by supplied rank and deterministic performance tie-breaks",
		failures,
	)
	var leader := ui.find_child("PeckingOrderRow_0", true, false) as Button
	_check(leader != null and "MABEL" in leader.text and "7 EGGS" in leader.text, "leader row should expose name and output", failures)
	_check(
		leader != null and leader.theme_type_variation == &"SelectedChoiceButton",
		"rank one should receive the polished brass leader treatment",
		failures,
	)
	_check(
		leader != null and "$5.80" in leader.tooltip_text and "Select to inspect" in leader.tooltip_text,
		"row tooltip should preserve exact credit and interaction guidance",
		failures,
	)
	_check(
		ui.leader_summary() == "#1 MABEL // 7 EGGS",
		"public leader summary should be concise enough for Flockwatch chrome",
		failures,
	)
	if leader != null:
		leader.pressed.emit()
	_check(int(observed["selected_worker"]) == 0, "clicking a row should emit its stable worker id", failures)
	_check_rows_fit(live_rows, harness, failures)

	# A new live clutch with no production should retain the completed shift's
	# useful ranking instead of showing four arbitrary zero-score leaders.
	ui.apply_snapshot({
		"day": 3,
		"pecking_order": [
			_rank_row(2, 1, "Penny", 0, 0, 0, 0, 0, true),
			_rank_row(1, 0, "Mabel", 0, 0, 0, 0, 0, true),
		],
		"last_pecking_order_day": 2,
		"last_pecking_order": [
			_rank_row(2, 4, "Juniper", 5, 4, 1, 0, 460, true),
			_rank_row(1, 5, "Biscuit", 8, 7, 0, 1, 720, true),
			_rank_row(3, 9, "Former Applicant", 12, 12, 0, 0, 900, false),
		],
	})
	await process_frame
	await process_frame

	var mode := ui.find_child("PeckingOrderMode", true, false) as Label
	var last_rows := _row_buttons(ui)
	_check(mode != null and mode.text == "LAST SHIFT // DAY 2", "zero-output live shift should clearly label the retained ranking", failures)
	_check(_worker_ids(last_rows) == [5, 4], "last-shift fallback should remain ranked and filter non-employees", failures)
	_check(
		ui.leader_summary() == "LAST SHIFT // #1 BISCUIT // 8 EGGS",
		"leader summary should disclose when it describes the previous shift",
		failures,
	)
	var last_leader := ui.find_child("PeckingOrderRow_5", true, false) as Button
	_check(
		last_leader != null and StringName(last_leader.get_meta("source", &"")) == &"last_shift",
		"fallback rows should expose their source for office integration and diagnostics",
		failures,
	)
	_check_rows_fit(last_rows, harness, failures)

	# Positive current output must immediately replace the retained result.
	ui.apply_snapshot({
		"day": 3,
		"pecking_order": [
			_rank_row(1, 1, "Penny", 1, 1, 0, 0, 70, true),
			_rank_row(2, 0, "Mabel", 0, 0, 0, 0, 0, true),
		],
		"last_pecking_order_day": 2,
		"last_pecking_order": [_rank_row(1, 5, "Biscuit", 8, 7, 0, 1, 720, true)],
	})
	await process_frame
	await process_frame
	_check(mode.text == "LIVE SHIFT", "first live egg should restore live-mode labeling", failures)
	_check(_worker_ids(_row_buttons(ui)) == [1, 0], "positive live rows should supersede last-shift fallback", failures)
	_check(ui.leader_summary() == "#1 PENNY // 1 EGG", "leader summary should use singular egg copy", failures)

	# Invalid or fully filtered data should fail soft with a bounded empty state.
	ui.apply_snapshot({"pecking_order": [{"worker_id": -1}, _rank_row(1, 7, "Applicant", 3, 3, 0, 0, 200, false)]})
	await process_frame
	await process_frame
	var empty := ui.find_child("PeckingOrderEmpty", true, false) as Label
	_check(_row_buttons(ui).is_empty(), "invalid and applicant records should not create buttons", failures)
	_check(empty != null and empty.is_visible_in_tree(), "empty ranking should retain an explanatory state", failures)
	_check(
		ui.leader_summary() == "PECKING ORDER // NO ACTIVE RANKING",
		"empty leaderboard should expose safe summary copy",
		failures,
	)
	_check(ui.get_global_rect().end.x <= harness.get_global_rect().end.x + 0.5, "component should remain within a 260px Flockwatch column", failures)

	ui.free()
	harness.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("PECKING_ORDER_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PECKING_ORDER_UI_TEST_PASSED rows=ranked/filterable/clickable fallback=last-shift bounds=260px")
	quit(0)


func _rank_row(
	rank: int,
	worker_id: int,
	worker_name: String,
	eggs: int,
	sound: int,
	cracked: int,
	golden: int,
	credit_cents: int,
	employed: bool,
) -> Dictionary:
	return {
		"rank": rank,
		"worker_id": worker_id,
		"worker_name": worker_name,
		"eggs": eggs,
		"sound": sound,
		"cracked": cracked,
		"golden": golden,
		"credit_cents": credit_cents,
		"employed": employed,
	}


func _row_buttons(ui: Control) -> Array[Button]:
	var rows: Array[Button] = []
	var host := ui.find_child("PeckingOrderRows", true, false) as VBoxContainer
	if host == null:
		return rows
	for child: Node in host.get_children():
		if child is Button and child.name.begins_with("PeckingOrderRow_"):
			rows.append(child as Button)
	return rows


func _worker_ids(rows: Array[Button]) -> Array[int]:
	var ids: Array[int] = []
	for row in rows:
		ids.append(int(row.get_meta("worker_id", -1)))
	return ids


func _check_rows_fit(rows: Array[Button], harness: Control, failures: Array[String]) -> void:
	var bounds := harness.get_global_rect()
	for row in rows:
		var rect := row.get_global_rect()
		_check(
			rect.position.x >= bounds.position.x - 0.5
			and rect.end.x <= bounds.end.x + 0.5
			and rect.size.x <= 260.5,
			"%s should remain inside the compact Flockwatch column (rect=%s)" % [row.name, rect],
			failures,
		)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
