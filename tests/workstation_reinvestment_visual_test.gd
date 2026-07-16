extends SceneTree


const WorkstationScene := preload("res://assets/models/office_workstation.glb")
const WorkstationFeedbackScript := preload("res://features/office/workstation_feedback.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var fixture := Node3D.new()
	fixture.name = "WorkstationReinvestmentFixture"
	root.add_child(fixture)
	var workstations := Node3D.new()
	workstations.name = "Workstations"
	fixture.add_child(workstations)
	var desks: Array[Node3D] = []
	for desk_index in 2:
		var desk := WorkstationScene.instantiate() as Node3D
		desk.name = "Workstation_%02d" % desk_index
		desk.position = Vector3(desk_index * 4.0, 0.0, 0.0)
		workstations.add_child(desk)
		desks.append(desk)

	var feedback := WorkstationFeedbackScript.new() as WorkstationFeedback
	feedback.name = "WorkstationFeedback"
	fixture.add_child(feedback)
	feedback.configure(workstations)
	# Configure twice to protect office rebuilds from duplicating generated props.
	feedback.configure(workstations)

	_check(workstations.find_children("PeckworkKeycapUpgrade", "Node3D", true, false).size() == 2, "configure should create one keycap root per desk", failures)
	_check(workstations.find_children("RequisitionKeycap_*", "MeshInstance3D", true, false).size() == 10, "configure should create exactly five requisition keys per desk", failures)
	_check(workstations.find_children("ShellIntegrityDeskLamp", "Node3D", true, false).size() == 2, "configure should create one wall candler per desk", failures)
	_check(workstations.find_children("ErgonomicNestUpgrade", "Node3D", true, false).size() == 2, "configure should create one connected nest treatment per desk", failures)
	_check(workstations.find_children("IssuedHardwareToken_*", "Node3D", true, false).size() == 6, "configure should create three overview hardware tokens per desk", failures)
	_check(workstations.find_children("LivePeckworkPaper_*", "MeshInstance3D", true, false).size() == 10, "reconfigure should not duplicate activity papers", failures)

	var desk_zero := desks[0]
	var keyboard := desk_zero.find_child("Keyboard", true, false) as Node3D
	var cubicle_back := desk_zero.find_child("CubicleBack", true, false) as Node3D
	var chair := desk_zero.find_child("TaskChair", true, false) as Node3D
	var key_root := feedback.upgrade_prop_root(0, &"peckwork_tools")
	var lamp_root := feedback.upgrade_prop_root(0, &"shell_lamp")
	var nest_root := feedback.upgrade_prop_root(0, &"nest_cushion")
	_check(key_root != null and key_root.get_parent() == keyboard, "requisition keys should be attached to the imported Keyboard", failures)
	_check(lamp_root != null and lamp_root.get_parent() == cubicle_back, "shell candler should be mounted to CubicleBack", failures)
	_check(nest_root != null and nest_root.get_parent() == chair, "nest treatment should inherit TaskChair swivel", failures)
	_check(nest_root != null and nest_root.find_child("ErgonomicNestBackrest", true, false) != null, "nest treatment should include a connected backrest", failures)
	var first_key := desk_zero.find_child("RequisitionKeycap_0", true, false) as MeshInstance3D
	_check(first_key != null and absf(first_key.global_position.y - 0.99) < 0.045, "requisition key should contact the authored keyboard key plane", failures)
	_check(first_key != null and absf(first_key.global_position.z + 0.31) < 0.045, "requisition key should sit over the authored keyboard row", failures)
	_check(not _branch_has_text_or_collision(key_root), "keycap upgrade must remain non-text and collision-free", failures)
	_check(not _branch_has_text_or_collision(lamp_root), "wall candler must remain non-text and collision-free", failures)
	_check(not _branch_has_text_or_collision(nest_root), "nest treatment must remain non-text and collision-free", failures)

	var upgraded_snapshot := {
		"upgrade_levels": {
			&"peckwork_tools": 1,
			&"shell_lamp": 1,
			&"nest_cushion": 1,
		},
		"workers": [
			{"id": 42, "desk_index": 0, "state": 1, "progress": 24.0, "stress": 8.0, "at_workstation": true},
			{"id": 43, "desk_index": 1, "state": 0, "progress": 0.0, "stress": 0.0, "at_workstation": false},
		],
	}
	feedback.apply_snapshot(upgraded_snapshot)
	for upgrade_id in [&"peckwork_tools", &"shell_lamp", &"nest_cushion"]:
		var prop := feedback.upgrade_prop_root(0, upgrade_id)
		_check(prop != null and prop.visible, "%s real prop should follow the authoritative upgrade level" % upgrade_id, failures)
		_check(prop != null and prop.scale.is_equal_approx(Vector3.ONE), "ordinary snapshot restore should leave %s static" % upgrade_id, failures)
		var token := desk_zero.find_child("IssuedHardwareToken_%s" % String(upgrade_id), true, false) as Node3D
		_check(token != null and token.visible, "%s overview token should be visible after purchase" % upgrade_id, failures)
		_check(not _branch_has_text_or_collision(token), "%s overview token must be physical, non-text, and collision-free" % upgrade_id, failures)

	var desk_one_key_root := feedback.upgrade_prop_root(1, &"peckwork_tools")
	_check(feedback.play_reinvestment_install(42, 0, &"peckwork_tools", 1), "targeted install should start for a valid worker desk", failures)
	_check(key_root != null and not key_root.scale.is_equal_approx(Vector3.ONE), "target real prop should begin the install reveal", failures)
	_check(desk_one_key_root != null and desk_one_key_root.scale.is_equal_approx(Vector3.ONE), "global upgrade props should remain static away from the target desk", failures)
	# The authoritative simulation commonly notifies the office in the same frame
	# as purchase. It may update visibility/materials, but must not erase or replay
	# this one targeted reveal.
	feedback.apply_snapshot(upgraded_snapshot)
	_check(key_root != null and not key_root.scale.is_equal_approx(Vector3.ONE), "snapshot application should not erase the active install target", failures)
	await process_frame
	_check(key_root != null and not key_root.scale.is_equal_approx(Vector3.ONE), "install should remain visually distinguishable after the snapshot race", failures)
	await create_timer(0.65).timeout
	_check(key_root != null and key_root.scale.is_equal_approx(Vector3.ONE), "install tween should settle the real prop exactly at rest scale", failures)
	var target_token := desk_zero.find_child("IssuedHardwareToken_peckwork_tools", true, false) as Node3D
	_check(target_token != null and target_token.scale.is_equal_approx(Vector3.ONE), "install tween should settle the overview token exactly at rest scale", failures)

	var focus_point := feedback.install_focus_point_global(0)
	_check(focus_point != Vector3.ZERO and focus_point.y > desk_zero.global_position.y + 1.2, "install focus helper should frame the desk hardware, not the floor", failures)
	_check(feedback.install_focus_point_global(99) == Vector3.ZERO, "invalid desk focus should fail safely", failures)
	_check(feedback.upgrade_prop_root(99, &"shell_lamp") == null, "invalid desk prop lookup should fail safely", failures)
	_check(not feedback.play_reinvestment_install(42, 0, &"unknown_upgrade", 1), "unknown install IDs should be rejected", failures)

	feedback.apply_snapshot({"upgrade_levels": {}, "workers": []})
	_check(not feedback.play_reinvestment_install(42, -1, &"shell_lamp", 1), "cleared snapshots should remove stale worker-to-desk mappings", failures)

	fixture.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("WORKSTATION_REINVESTMENT_VISUAL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("WORKSTATION_REINVESTMENT_VISUAL_TEST_PASSED props=attached tokens=physical install=targeted snapshot_race=safe")
	quit(0)


func _branch_has_text_or_collision(node: Node) -> bool:
	if node == null:
		return false
	if node is Label3D or node is CollisionObject3D or node is CollisionShape3D:
		return true
	for child in node.get_children():
		if _branch_has_text_or_collision(child):
			return true
	return false


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
