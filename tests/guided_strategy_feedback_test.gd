extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(260823, 4)
	var worker_snapshot := simulation.snapshot().get("workers", [])[0] as Dictionary
	var view := ChickenView.new()
	view.configure(worker_snapshot)
	root.add_child(view)
	await process_frame

	_check(view.play_signature_feedback(&"share_credit"), "share credit should play a physical signature", failures)
	var share_state := view.signature_feedback_state()
	var marker := view.find_child("SignatureMoveMarker", true, false) as Sprite3D
	var share_texture := marker.texture if marker != null else null
	_check(
		bool(share_state.get("active", false))
		and bool(share_state.get("animated", false))
		and String(share_state.get("action_id", "")) == "share_credit"
		and share_texture != null,
		"the named hen should own one animated, semantic signature marker",
		failures,
	)

	_check(view.play_signature_feedback(&"career_coaching"), "career coaching should play a physical signature", failures)
	var coaching_texture := marker.texture if marker != null else null
	_check(
		coaching_texture != null and coaching_texture != share_texture
		and int(view.signature_feedback_state().get("serial", 0)) == 2,
		"different signature actions should use distinct silhouettes instead of a generic effect",
		failures,
	)

	view.set_reduced_motion(true)
	_check(view.play_signature_feedback(&"quota_pressure"), "pressure should retain a reduced-motion signature", failures)
	_check(
		not bool(view.signature_feedback_state().get("animated", true)),
		"reduced motion should preserve a static semantic signature",
		failures,
	)
	await create_timer(1.20).timeout
	_check(
		not bool(view.signature_feedback_state().get("active", true)),
		"signature feedback should clean itself up after its bounded hold",
		failures,
	)

	view.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("GUIDED_STRATEGY_FEEDBACK_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("GUIDED_STRATEGY_FEEDBACK_TEST_PASSED signatures=3 silhouettes=distinct reduced=static cleanup=bounded")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
