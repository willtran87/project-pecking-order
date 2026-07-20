extends SceneTree


const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const TEST_SAVE_FILENAME := "office_presentation_efficiency_test.json"

var _stage := "boot"


class EfficiencyOffice:
	extends Office

	var diagnostic_publish_count := 0
	var last_diagnostic_snapshot: Dictionary = {}


	func _publish_web_diagnostic_state(snapshot: Dictionary) -> void:
		diagnostic_publish_count += 1
		last_diagnostic_snapshot = snapshot.duplicate(true)


class CountingStaffingUI:
	extends RoostStaffingUI

	var apply_count := 0


	func apply_snapshot(_snapshot: Dictionary) -> void:
		apply_count += 1


class CountingManagementControl:
	extends Control

	var apply_count := 0
	var set_count := 0


	func apply_snapshot(_snapshot: Dictionary) -> void:
		apply_count += 1


	func set_snapshot(_snapshot: Dictionary) -> void:
		set_count += 1


func _init() -> void:
	create_timer(90.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	var store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	store.delete()
	var office := EfficiencyOffice.new()
	office.set("_campaign_store", store)
	root.add_child(office)
	await process_frame
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	_check(simulation != null and clock != null, "Office should compose simulation and clock authority", failures)
	if simulation == null or clock == null:
		await _finish(office, store, [], failures)
		return

	# Keep the fixture deterministic: all cadence below is driven synchronously.
	office.set_process(false)
	clock.set_process(false)
	_stage = "coalescing accelerated presentation"
	_check(
		simulation.select_directive(&"shell_assurance"),
		"the efficiency fixture should begin a real running shift",
		failures,
	)
	clock.set_speed(3)
	var presentation_before := int(office.get("_presentation_update_count"))
	var revision_before := simulation.checkpoint_revision()
	var observed_revisions: Array[int] = []
	simulation.snapshot_changed.connect(func(snapshot: Dictionary) -> void:
		observed_revisions.append(int(snapshot.get("authoritative_tick_revision", -1)))
	)
	clock._process(1.0)
	var expected_revision := revision_before + SimulationClock.MAX_TICKS_PER_FRAME
	_check(
		clock.ticks_advanced_last_frame() == SimulationClock.MAX_TICKS_PER_FRAME
		and simulation.checkpoint_revision() == expected_revision,
		"a long 10x frame should advance the exact bounded authoritative tick count",
		failures,
	)
	_check(
		observed_revisions == [expected_revision],
		"the clock should publish one newest read model for the complete tick batch",
		failures,
	)
	_check(
		int(office.get("_presentation_update_count")) == presentation_before + 1
		and int(office.get("_last_presented_tick_revision")) == expected_revision,
		"Office should apply presentation exactly once at the newest batch revision",
		failures,
	)
	var runtime_performance := office.call("_runtime_performance_diagnostic") as Dictionary
	_check(
		[
			"fps", "process_usec", "physics_process_usec", "static_memory_bytes",
			"static_memory_peak_bytes", "object_count", "node_count",
			"orphan_node_count", "draw_calls", "rendered_objects",
			"rendered_primitives",
		].all(func(key: String) -> bool: return runtime_performance.has(key))
		and int(runtime_performance.get("static_memory_bytes", -1)) >= 0
		and int(runtime_performance.get("static_memory_peak_bytes", -1))
			>= int(runtime_performance.get("static_memory_bytes", 0))
		and int(runtime_performance.get("object_count", 0)) > 0
		and int(runtime_performance.get("node_count", 0)) > 0,
		"the release diagnostic should expose bounded engine memory, object, frame, and render counters",
		failures,
	)

	_stage = "gating hidden management surfaces"
	var staffing := CountingStaffingUI.new()
	var capital := CountingManagementControl.new()
	var expansion := CountingManagementControl.new()
	var portfolio := CountingManagementControl.new()
	var pecking_order := CountingManagementControl.new()
	capital.visible = false
	expansion.visible = false
	portfolio.visible = false
	pecking_order.visible = false
	office.add_child(pecking_order)
	office.set("_staffing_ui", staffing)
	office.set("_capital_blueprint_ui", capital)
	office.set("_campus_expansion_ui", expansion)
	office.set("_campus_portfolio_ui", portfolio)
	office.set("_pecking_order_ui", pecking_order)
	office.set("_flockwatch_open", false)
	var current_snapshot := simulation.snapshot()
	office.call("_refresh_visible_management_surfaces", current_snapshot, false)
	_check(
		staffing.apply_count == 0
		and capital.apply_count == 0
		and expansion.set_count == 0
		and portfolio.apply_count == 0
		and pecking_order.apply_count == 0,
		"hidden management surfaces should allocate no snapshot rebuild work",
		failures,
	)

	office.call("_refresh_visible_management_surfaces", current_snapshot, true)
	_check(
		staffing.apply_count == 1
		and pecking_order.apply_count == 1
		and capital.apply_count == 0
		and expansion.set_count == 0
		and portfolio.apply_count == 0,
		"a forced filing refresh should update lightweight filed views without rebuilding hidden planners",
		failures,
	)

	capital.visible = true
	expansion.visible = true
	portfolio.visible = true
	pecking_order.visible = true
	office.call("_refresh_visible_management_surfaces", current_snapshot, false)
	_check(
		capital.apply_count == 1
		and expansion.set_count == 1
		and portfolio.apply_count == 1
		and pecking_order.apply_count == 2,
		"each visible planner should receive exactly one current snapshot refresh",
		failures,
	)

	var navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	_check(navigation != null, "the efficiency fixture should retain its real filing navigator", failures)
	if navigation != null:
		navigation.set_show_all_filings(true)
		navigation.open_page(FlockwatchNavigation.PAGE_FLOCK)
		office.set("_flockwatch_open", true)
		office.call("_refresh_visible_management_surfaces", current_snapshot, false)
		_check(
			staffing.apply_count == 2,
			"staffing should refresh when its Flockwatch filing becomes visible",
			failures,
		)

	_stage = "publishing paused camera feedback"
	office.diagnostic_publish_count = 0
	office.call("_on_camera_focus_changed", "", -1)
	_check(
		office.diagnostic_publish_count == 1,
		"camera mode changes should republish assistive state without waiting for a simulation tick",
		failures,
	)

	_stage = "throttling pending browser diagnostics"
	office.diagnostic_publish_count = 0
	office.last_diagnostic_snapshot = {}
	office.set("_pending_web_diagnostic_snapshot", {"marker": "newest"})
	office.set("_web_diagnostic_dirty", true)
	office.set("_web_diagnostic_next_allowed_msec", Time.get_ticks_msec() + 60_000)
	office.call("_flush_pending_web_diagnostic")
	_check(
		office.diagnostic_publish_count == 0
		and bool(office.get("_web_diagnostic_dirty"))
		and String((office.get("_pending_web_diagnostic_snapshot") as Dictionary).get("marker", "")) == "newest",
		"a diagnostic inside the throttle window should retain only the newest pending read model",
		failures,
	)
	office.set("_web_diagnostic_next_allowed_msec", 0)
	office.call("_flush_pending_web_diagnostic")
	office.call("_flush_pending_web_diagnostic")
	_check(
		office.diagnostic_publish_count == 1
		and String(office.last_diagnostic_snapshot.get("marker", "")) == "newest"
		and not bool(office.get("_web_diagnostic_dirty"))
		and (office.get("_pending_web_diagnostic_snapshot") as Dictionary).is_empty(),
		"an elapsed diagnostic window should publish the newest state once and clear its queue",
		failures,
	)

	await _finish(office, store, [staffing, capital, expansion, portfolio], failures)


func _finish(
	office: EfficiencyOffice,
	store: Variant,
	unparented_doubles: Array,
	failures: Array[String],
) -> void:
	office.free()
	for double_value: Variant in unparented_doubles:
		var double_node := double_value as Node
		if double_node != null and is_instance_valid(double_node):
			double_node.free()
	await process_frame
	store.delete()
	if not failures.is_empty():
		for failure: String in failures:
			push_error("OFFICE_PRESENTATION_EFFICIENCY_TEST_FAILED: %s [stage=%s]" % [failure, _stage])
		quit(1)
		return
	print("OFFICE_PRESENTATION_EFFICIENCY_TEST_PASSED ticks=coalesced hidden=idle diagnostics=latest-only health=memory+objects+frames+render")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _on_watchdog_timeout() -> void:
	push_error("OFFICE_PRESENTATION_EFFICIENCY_TEST_TIMEOUT stage=%s" % _stage)
	quit(1)
