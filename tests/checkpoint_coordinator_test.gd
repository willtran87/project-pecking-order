extends SceneTree

const CheckpointCoordinatorScript := preload("res://core/persistence/checkpoint_coordinator.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_test_quiet_interval_coalescing(failures)
	_test_maximum_interval_caps_continuous_activity(failures)
	_test_immediate_claim_and_failed_retry(failures)
	_test_success_clears_only_the_captured_generation(failures)
	_test_deliberate_rollback_discards_failed_generation(failures)
	_test_diagnostic_snapshot_is_bounded(failures)
	if not failures.is_empty():
		for failure: String in failures:
			push_error("CHECKPOINT_COORDINATOR_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CHECKPOINT_COORDINATOR_TEST_PASSED coalescing=quiet+maximum immediate=due retry=durable generation=in-flight-safe diagnostics=bounded")
	quit(0)


func _test_quiet_interval_coalescing(failures: Array[String]) -> void:
	var coordinator = CheckpointCoordinatorScript.new(100, 500, 50)
	_check(coordinator.mark_routine("first egg", 0) == 1, "first routine mark should open generation one", failures)
	_check(not coordinator.is_save_due(99), "routine work should wait for its quiet interval", failures)
	_check(coordinator.mark_routine("second egg", 80) == 2, "a coalesced mutation should advance the generation", failures)
	_check(not coordinator.is_save_due(179), "a later routine mark should move the quiet deadline", failures)
	var pending: Dictionary = coordinator.diagnostic_snapshot(179)
	_check(
		String(pending.get("status", "")) == "pending"
		and int(pending.get("due_at_msec", -1)) == 180
		and String(pending.get("reason", "")) == "second egg",
		"pending diagnostics should expose the coalesced deadline and latest bounded reason",
		failures,
	)
	_check(coordinator.is_save_due(180), "routine work should become due at the settled quiet deadline", failures)
	var request: Dictionary = coordinator.claim_due_save(180)
	_check(
		int(request.get("generation", 0)) == 2
		and String(request.get("reason", "")) == "second egg",
		"claim should capture the latest coalesced generation",
		failures,
	)
	_check(coordinator.claim_due_save(180).is_empty(), "a second save must not start while one is in flight", failures)
	_check(coordinator.complete_save(true, 181), "the active coalesced save should accept completion", failures)
	_check(not coordinator.is_dirty() and not coordinator.is_saving(), "a successful latest-generation save should become clean", failures)


func _test_maximum_interval_caps_continuous_activity(failures: Array[String]) -> void:
	var coordinator = CheckpointCoordinatorScript.new(100, 250, 50)
	coordinator.mark_routine("generation 1", 0)
	coordinator.mark_routine("generation 2", 80)
	coordinator.mark_routine("generation 3", 160)
	coordinator.mark_routine("generation 4", 240)
	_check(not coordinator.is_save_due(249), "continuous activity should remain pending before the maximum interval", failures)
	_check(coordinator.is_save_due(250), "the first dirty mark should cap coalescing at the maximum interval", failures)
	var request: Dictionary = coordinator.claim_due_save(250)
	_check(int(request.get("generation", 0)) == 4, "the maximum deadline should capture every coalesced generation", failures)
	coordinator.complete_save(true, 251)


func _test_immediate_claim_and_failed_retry(failures: Array[String]) -> void:
	var coordinator = CheckpointCoordinatorScript.new(100, 500, 50)
	coordinator.mark_immediate("shift decision", 10)
	_check(coordinator.is_save_due(10), "an immediate mark should be due in the same timestamp", failures)
	var first_request: Dictionary = coordinator.claim_due_save(10)
	_check(int(first_request.get("generation", 0)) == 1, "the immediate claim should capture its generation", failures)
	_check(coordinator.complete_save(false, 20), "a failed active save should accept completion", failures)
	var failed: Dictionary = coordinator.diagnostic_snapshot(20)
	_check(
		bool(failed.get("dirty", false))
		and String(failed.get("status", "")) == "retry_wait"
		and int(failed.get("due_at_msec", -1)) == 70
		and int(failed.get("write_failure_count", 0)) == 1,
		"a failed save should remain dirty and publish its retry deadline",
		failures,
	)
	_check(not coordinator.is_save_due(69), "a failed save should not spin before its retry interval", failures)
	_check(coordinator.is_save_due(70), "a failed save should become claimable at its retry deadline", failures)
	var retry_request: Dictionary = coordinator.claim_due_save(70)
	_check(int(retry_request.get("generation", 0)) == 1, "retry should preserve the failed generation", failures)
	coordinator.complete_save(true, 71)
	var recovered: Dictionary = coordinator.diagnostic_snapshot(71)
	_check(
		not bool(recovered.get("dirty", true))
		and String(recovered.get("status", "")) == "clean"
		and int(recovered.get("write_attempt_count", 0)) == 2
		and int(recovered.get("write_success_count", 0)) == 1,
		"a successful retry should clear the generation and retain bounded counters",
		failures,
	)


func _test_success_clears_only_the_captured_generation(failures: Array[String]) -> void:
	var coordinator = CheckpointCoordinatorScript.new(100, 500, 50)
	coordinator.mark_immediate("opening decision", 0)
	var first_request: Dictionary = coordinator.claim_due_save(0)
	_check(int(first_request.get("generation", 0)) == 1, "fixture should begin generation one", failures)
	coordinator.mark_routine("egg arrived during save", 5)
	coordinator.complete_save(true, 10)
	var pending: Dictionary = coordinator.diagnostic_snapshot(10)
	_check(
		bool(pending.get("dirty", false))
		and int(pending.get("generation", 0)) == 2
		and int(pending.get("persisted_generation", 0)) == 1
		and int(pending.get("dirty_since_msec", -1)) == 5
		and int(pending.get("due_at_msec", -1)) == 105,
		"success must retain a generation marked during the in-flight write with a fresh deadline",
		failures,
	)
	_check(coordinator.claim_due_save(104).is_empty(), "the retained routine generation should still coalesce", failures)
	var second_request: Dictionary = coordinator.claim_due_save(105)
	_check(int(second_request.get("generation", 0)) == 2, "the retained generation should become the next claim", failures)
	coordinator.complete_save(true, 106)

	coordinator.mark_immediate("capital authorization", 200)
	coordinator.claim_due_save(200)
	coordinator.mark_immediate("roster authorization during save", 201)
	coordinator.complete_save(true, 202)
	_check(
		coordinator.is_dirty() and coordinator.is_save_due(202),
		"an immediate generation arriving during a save should remain due after that save succeeds",
		failures,
	)
	var immediate_followup: Dictionary = coordinator.claim_due_save(202)
	_check(int(immediate_followup.get("generation", 0)) == 4, "the immediate follow-up should capture only the preserved generation", failures)
	coordinator.complete_save(true, 203)
	_check(not coordinator.is_dirty(), "all generations should be clean after the final successful completion", failures)


func _test_deliberate_rollback_discards_failed_generation(failures: Array[String]) -> void:
	var coordinator = CheckpointCoordinatorScript.new(100, 500, 50)
	coordinator.mark_immediate("replacement campaign", 0)
	coordinator.claim_due_save(0)
	_check(not coordinator.discard_pending(), "an active write must not be discardable", failures)
	coordinator.complete_save(false, 1)
	_check(coordinator.is_dirty(), "a failed replacement should remain retryable before rollback", failures)
	_check(coordinator.discard_pending(), "a verified host rollback should discard the failed replacement generation", failures)
	var restored: Dictionary = coordinator.diagnostic_snapshot(1)
	_check(
		not bool(restored.get("dirty", true))
		and String(restored.get("status", "")) == "clean"
		and int(restored.get("write_failure_count", 0)) == 1,
		"rollback should cancel retry state without erasing bounded failure evidence",
		failures,
	)


func _test_diagnostic_snapshot_is_bounded(failures: Array[String]) -> void:
	var coordinator = CheckpointCoordinatorScript.new(100, 500, 50)
	var oversized_reason := "R".repeat(CheckpointCoordinatorScript.MAX_DIAGNOSTIC_REASON_LENGTH * 3)
	for generation in 100:
		coordinator.mark_routine("%s-%d" % [oversized_reason, generation], generation)
	var snapshot: Dictionary = coordinator.diagnostic_snapshot(100)
	_check(
		String(snapshot.get("reason", "")).length() == CheckpointCoordinatorScript.MAX_DIAGNOSTIC_REASON_LENGTH,
		"diagnostics should truncate unbounded caller reasons",
		failures,
	)
	_check(
		snapshot.size() == 20
		and int(snapshot.get("generation", 0)) == 100
		and not snapshot.has("history")
		and not snapshot.has("payload"),
		"diagnostics should remain fixed-cardinality scalar state regardless of mark count",
		failures,
	)
	_check(not coordinator.complete_save(true, 100), "completion without an active claim should fail closed", failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
