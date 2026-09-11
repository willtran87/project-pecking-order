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
	var selection_observed := {"worker_id": -1}
	view.management_selection_requested.connect(
		func(worker_id: int) -> void: selection_observed["worker_id"] = worker_id
	)
	var pick_state := view.management_pick_state()
	_check(
		bool(pick_state.get("built", false))
		and bool(pick_state.get("input_ray_pickable", false))
		and int(pick_state.get("collision_layer", 0)) == 1 << 19
		and String(pick_state.get("semantic_action", "")) == "inspect_or_dispatch",
		"each physical hen should expose one bounded click/tap target for inspection or an armed tray handoff",
		failures,
	)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	view.call(
		"_on_management_pick_input_event",
		null,
		click,
		Vector3.ZERO,
		Vector3.UP,
		0,
	)
	_check(
		int(selection_observed["worker_id"]) == int(worker_snapshot.get("id", -1)),
		"a world click should emit the exact stable worker ID once",
		failures,
	)
	view.set_consequence_preview(true, &"peck")
	var preview_state := view.consequence_preview_state()
	_check(
		bool(preview_state.get("active", false))
		and String(preview_state.get("kind", "")) == "peck"
		and not bool(preview_state.get("authoritative", true)),
		"next-action anticipation should stay a reversible world-space preview",
		failures,
	)
	view.set_consequence_preview(false)
	_check(
		not bool(view.consequence_preview_state().get("active", true)),
		"world-space consequence preview should clear without filing an action",
		failures,
	)

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
	print("GUIDED_STRATEGY_FEEDBACK_TEST_PASSED world-pick=stable preview=reversible signatures=3 silhouettes=distinct reduced=static cleanup=bounded")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
