extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var storytelling := office.get("_office_storytelling") as OfficeStorytelling
	var revenue_label := office.get("_revenue_label") as Label
	var worker_views: Dictionary = office.get("_worker_views") as Dictionary
	var worker_view := worker_views.get(0) as ChickenView
	_check(storytelling != null and revenue_label != null and worker_view != null, "office feedback fixtures should exist", failures)

	# Close the opening policy so the capture reflects a live shift, then place the
	# test hen in the same visible seated state required by the production guard.
	var assurance_option := office.find_child("DecisionOption_shell_assurance", true, false) as Button
	var confirm_decision := office.find_child("ConfirmDecisionButton", true, false) as Button
	if assurance_option != null and confirm_decision != null:
		assurance_option.pressed.emit()
		confirm_decision.pressed.emit()
	await process_frame
	worker_view.set("_is_at_workstation", true)
	worker_view.set("_seat_blend", 1.0)
	worker_view.set("_destination_kind", &"home")
	worker_view.set("_is_walking", false)
	worker_view.set("_feed_party_active", false)
	worker_view.set("_feed_party_queued", false)
	worker_view.global_position = worker_view.get("_home_position") as Vector3
	_check(worker_view.is_seated_at_workstation(), "feedback test must honor the visible seating guard", failures)

	var graded := {"seen": false, "value": 0, "quality": &""}
	var collected := {"seen": false, "value": 0}
	storytelling.egg_graded.connect(func(
		_worker_id: int,
		quality: StringName,
		value_cents: int,
		_streak_bonus_cents: int,
		_grading_position: Vector3
	) -> void:
		graded["seen"] = true
		graded["value"] = value_cents
		graded["quality"] = quality
	)
	storytelling.egg_reached_presentation_detailed.connect(func(
		_worker_id: int,
		_quality: StringName,
		value_cents: int,
		_streak_bonus_cents: int
	) -> void:
		collected["seen"] = true
		collected["value"] = value_cents
	)

	var opening_fund := simulation.revenue_cents
	var egg_value := 455
	simulation.revenue_cents += egg_value
	simulation.eggs_today += 1
	office.call("_on_egg_laid", 0, &"sound", egg_value)
	office.call("_on_snapshot_changed", simulation.snapshot())
	_check("$%.2f" % (opening_fund / 100.0) in revenue_label.text, "Feed Fund should wait for physical collection before displaying egg value", failures)
	var quota_progress := office.find_child("ShiftQuotaProgress", true, false) as ProgressBar
	_check(quota_progress != null and int(quota_progress.value) == 1, "quota should react immediately when the hen lays", failures)
	var routed_egg := office.find_child("Egg_sound_*", true, false) as MeshInstance3D
	var routed_mesh := routed_egg.mesh if routed_egg != null else null
	var quality_treatment := routed_egg.find_child("EggQualityTreatment", false, false) as Node3D if routed_egg != null else null
	_check(
		routed_egg != null and routed_mesh is ArrayMesh,
		"a routed deliverable should use the authored tapered egg silhouette instead of a spherical placeholder",
		failures
	)
	_check(
		quality_treatment != null
		and quality_treatment.find_child("EggSorterStampRing", true, false) != null,
		"the exact routed egg should carry its bounded sorter-impact treatment",
		failures
	)
	var handoff_echoes := office.find_children("PooledEggHandoffEcho_*", "MeshInstance3D", true, false)
	_check(
		handoff_echoes.size() == 3 and handoff_echoes.size() <= 18,
		"one routed egg should acquire three echoes from the bounded 18-node handoff pool",
		failures
	)

	await _wait_for_flag(graded, "seen", 240)
	_check(bool(graded["seen"]), "sorter waypoint should emit an explicit grading event", failures)
	_check(int(graded["value"]) == egg_value and StringName(graded["quality"]) == &"sound", "grading receipt should carry exact authoritative quality and value", failures)
	var printer_body := office.find_child("GradingReceiptPrinterBody", true, false) as MeshInstance3D
	var printer_slot := office.find_child("GradingReceiptPrinterSlot", true, false) as MeshInstance3D
	var grading_gate := office.find_child("ShellIntegrityGate", true, false) as MeshInstance3D
	_check(
		printer_body != null
		and printer_slot != null
		and grading_gate != null
		and printer_body.global_position.distance_to(grading_gate.global_position) < 0.8,
		"grading receipt printer should be a fixed part of the sorting gate",
		failures
	)
	var grading_receipts := office.find_children("GradingReceipt_*", "Node3D", true, false)
	_check(not grading_receipts.is_empty(), "sorter should create a physical grading receipt", failures)
	var grading_receipt := grading_receipts[0] as Node3D if not grading_receipts.is_empty() else null
	var receipt_copy := grading_receipt.find_child("ReceiptText", true, false) as Label3D if grading_receipt != null else null
	var receipt_paper := grading_receipt.find_child("ReceiptPaper", true, false) as MeshInstance3D if grading_receipt != null else null
	var receipt_box: BoxMesh = receipt_paper.mesh as BoxMesh if receipt_paper != null else null
	_check(
		grading_receipt != null
		and receipt_paper != null
		and grading_receipt.find_child("ReceiptTearBar", true, false) != null,
		"grading output should read as a paper docket physically fed from the sorter",
		failures
	)
	_check(
		printer_slot != null
		and grading_receipt != null
		and grading_receipt.global_position.distance_to(printer_slot.global_position) < 0.12,
		"grading docket should emerge directly from the fixed printer slot",
		failures
	)
	_check(
		receipt_box != null and receipt_box.size.x <= 0.50 and receipt_box.size.y <= 0.36,
		"grading docket should be compact paper rather than a floating sign card",
		failures
	)
	_check(
		receipt_copy != null
		and receipt_copy.text == "SOUND  $4.55"
		and receipt_copy.shaded
		and receipt_copy.outline_size == 0,
		"grading docket copy should use printed-paper treatment instead of HUD glow",
		failures
	)
	_check("GRADED" in (office.get("_ticker_label") as Label).text, "bottom ticker should explain the grading stage", failures)

	await _wait_for_flag(collected, "seen", 240)
	_check(bool(collected["seen"]) and int(collected["value"]) == egg_value, "presentation arrival should carry the same exact value", failures)
	await create_timer(0.8).timeout
	_check("$%.2f" % ((opening_fund + egg_value) / 100.0) in revenue_label.text, "Feed Fund should count up after the farmer collects the egg", failures)
	_check(int(office.get("_pending_collection_cents")) == 0, "collected egg value should leave no pending visual credit", failures)
	for echo_node in office.find_children("PooledEggHandoffEcho_*", "MeshInstance3D", true, false):
		var echo := echo_node as MeshInstance3D
		_check(
			not echo.visible and not bool(echo.get_meta("handoff_in_use", false)),
			"handoff echoes should return invisibly to the pool after basket arrival",
			failures
		)
	await create_timer(0.8).timeout
	_check(office.find_children("GradingReceipt_*", "Node3D", true, false).is_empty(), "grading receipts should clear after their bounded display", failures)

	# Close the full renewable-action loop through the production Office: exact
	# claim assist -> sound egg -> physical basket callback -> one restored charge.
	worker_view.stage_at_workstation_for_introduction()
	simulation.set_worker_at_workstation(0, true)
	var assisted_worker := simulation.workers[0]
	if assisted_worker.current_claim == null:
		simulation.advance_tick()
	_check(assisted_worker.current_claim != null, "attention-refund fixture should pull a real claim", failures)
	if assisted_worker.current_claim != null:
		assisted_worker.work_state = ChickenState.WorkState.WORKING
		assisted_worker.work_progress = DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS
		var assist := simulation.perform_peck_assist(0)
		var assisted_claim_id := int(assist.get("claim_id", -1))
		_check(bool(assist.get("accepted", false)) and int(assist.get("remaining", -1)) == 2, "a real Priority Peck should consume one attention charge", failures)
		var risk := simulation.estimated_crack_risk(0)
		var golden_chance := clampf(
			0.025 + maxf(0.0, assisted_worker.morale - 70.0) * 0.0005,
			0.025,
			0.08,
		)
		var clean_seed := _seed_for_sound_egg(risk, golden_chance)
		_check(clean_seed > 0, "Office refund fixture should find a deterministic sound egg", failures)
		(simulation.get("_rng") as RandomNumberGenerator).seed = clean_seed
		worker_view.stage_at_workstation_for_introduction()
		simulation.set_worker_at_workstation(0, true)
		assisted_worker.work_state = ChickenState.WorkState.LAYING
		assisted_worker.state_ticks_remaining = 1
		simulation.advance_tick()
		_check(
			int(simulation.peck_assist_delivery_status().get("pending_delivery_count", 0)) == 1,
			"assisted lay should remain pending while its exact physical egg travels",
			failures
		)
		await _wait_for_refund(simulation, 1, 360)
		var delivery := simulation.peck_assist_delivery_status()
		_check(int(delivery.get("charges", -1)) == 3 and int(delivery.get("refunds", -1)) == 1, "farmer arrival should restore exactly one renewable attention charge", failures)
		_check(int(delivery.get("pending_delivery_count", -1)) == 0, "basket settlement should consume the exact pending token", failures)
		_check(int((delivery.get("last_delivery", {}) as Dictionary).get("claim_id", -1)) == assisted_claim_id, "Office should settle the same claim carried by the routed egg", failures)
		var refund_chip := office.find_child("PriorityPeckRefundChip", true, false) as PanelContainer
		var refund_copy := refund_chip.get_child(0) as Label if refund_chip != null and refund_chip.get_child_count() > 0 else null
		_check(refund_chip != null and refund_copy != null and "+1 PRIORITY PECK" in refund_copy.text and "3/3" in refund_copy.text, "physical delivery should launch a concise renewable-attention payoff chip", failures)
		await create_timer(1.8).timeout
		await process_frame
		_check(office.find_children("GradingReceipt_*", "Node3D", true, false).is_empty(), "renewed assisted delivery should retire its bounded grading docket", failures)

	# Exercise the one-slot queue directly so the compact Courier docket keeps the
	# authoritative bonus breakdown and advances to the next grade on schedule.
	storytelling.call("_enqueue_grading_receipt", &"golden", 789, 34)
	storytelling.call("_enqueue_grading_receipt", &"cracked", 120, 0)
	await process_frame
	var queued_receipts := office.find_children("GradingReceipt_*", "Node3D", true, false)
	var queued_copy := (
		queued_receipts[0].find_child("ReceiptText", true, false) as Label3D
		if not queued_receipts.is_empty() else null
	)
	_check(
		queued_copy != null and queued_copy.text == "GOLDEN  $7.55\n+$0.34 clean-clutch",
		"grading docket should preserve exact base value and clean-clutch bonus copy",
		failures
	)
	await create_timer(1.75).timeout
	await process_frame
	queued_receipts = office.find_children("GradingReceipt_*", "Node3D", true, false)
	queued_copy = (
		queued_receipts[0].find_child("ReceiptText", true, false) as Label3D
		if not queued_receipts.is_empty() else null
	)
	_check(
		queued_copy != null and queued_copy.text == "CRACKED  $1.20",
		"grading docket queue should advance into the same fixed printer slot (saw %s)" % (
			queued_copy.text.replace("\n", " / ") if queued_copy != null else "no docket"
		),
		failures
	)
	await create_timer(1.75).timeout
	await process_frame
	_check(
		office.find_children("GradingReceipt_*", "Node3D", true, false).is_empty(),
		"queued grading dockets should retain their bounded display timing",
		failures
	)

	# Quality must remain legible without hue alone. The golden treatment carries
	# a crown/glint silhouette while cracked work carries a raised seam on both
	# faces; both are connected children of the same retained egg node.
	var golden_probe := MeshInstance3D.new()
	golden_probe.name = "GoldenQualityProbe"
	storytelling.egg_collection_root.add_child(golden_probe)
	storytelling.call("_apply_egg_quality_visual", golden_probe, &"golden", false)
	_check(
		golden_probe.find_child("EggGoldenCrownRidge", true, false) != null
		and golden_probe.find_children("EggGoldenGlint_*", "MeshInstance3D", true, false).size() == 2,
		"golden eggs should expose crown and glint geometry rather than relying on color alone",
		failures
	)
	var cracked_probe := MeshInstance3D.new()
	cracked_probe.name = "CrackedQualityProbe"
	storytelling.egg_collection_root.add_child(cracked_probe)
	storytelling.call("_apply_egg_quality_visual", cracked_probe, &"cracked", false)
	_check(
		cracked_probe.find_children("EggCrack_*", "MeshInstance3D", true, false).size() >= 8,
		"cracked eggs should expose a readable connected seam on both faces",
		failures
	)

	await create_timer(0.4).timeout
	office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("EGG_GRADING_FEEDBACK_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("EGG_GRADING_FEEDBACK_TEST_PASSED lay=quota grade=receipt collect=fund")
	quit(0)


func _wait_for_flag(state: Dictionary, key: String, frame_limit: int) -> void:
	for _frame in frame_limit:
		if bool(state.get(key, false)):
			return
		await process_frame


func _wait_for_refund(simulation: DepartmentSimulation, expected: int, frame_limit: int) -> void:
	for _frame in frame_limit:
		if simulation.peck_assist_refunds_today >= expected:
			return
		await process_frame


func _seed_for_sound_egg(crack_risk: float, golden_chance: float) -> int:
	for candidate in range(1, 10_000):
		var probe := RandomNumberGenerator.new()
		probe.seed = candidate
		if probe.randf() >= crack_risk and probe.randf() >= golden_chance:
			return candidate
	return -1


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
