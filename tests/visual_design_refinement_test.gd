extends SceneTree

const Goal := preload("res://core/experience/personal_shift_goal.gd")
const Pulse := preload("res://core/experience/gameplay_pulse_director.gd")
const Audio := preload("res://features/office/office_audio_feedback.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	var ui := PeckworkRoutingUI.new()
	root.add_child(ui)
	await process_frame
	ui.set_interface_scale(1.5)
	await process_frame
	var care := ui.find_child("PersonnelActions", true, false) as GridContainer
	_check(care != null and care.columns == 2, "care reflows into two columns", failures)
	for child in care.get_children():
		if child is Button:
			_check(child.custom_minimum_size.y >= 66.0, "large-text care targets remain at least 66 design pixels", failures)
			_check(child.get_theme_font_size("font_size") >= 18, "care labels respect enlarged text", failures)
	var panel := ui.find_child("PeckworkAssignmentDossier", true, false) as Control
	_check(panel.get_meta("readable_scale", 0.0) == 1.5, "actual layout applies the readable scale", failures)
	ui.free()
	var hen := ChickenView.new()
	root.add_child(hen)
	hen.set("_break_interaction_face_point", Vector3.FORWARD)
	hen.rotation.y = 0.0
	_check(not bool(hen.call("_is_facing_break_fixture")), "hens must turn before using the break fixture", failures)
	hen.rotation.y = PI
	_check(bool(hen.call("_is_facing_break_fixture")), "facing the fixture releases the interaction", failures)
	hen.free()

	_check(Goal.strategy({"kind": "shells"}).label == "SAFER SHELLS", "review and plan use the same shell-plan name", failures)
	_check(Goal.strategy({"kind": "output"}).label == "FASTER EGGS", "review and plan use the same output-plan name", failures)
	_check(Goal.strategy({"kind": "welfare"}).label == "HAPPIER HENS", "review and plan use the same wellbeing-plan name", failures)
	var pulse := Pulse.new()
	var report := pulse.compose_report({"eggs": 12, "quota": 10, "cracked": 0, "overdue_claims": 2, "credited_cents": 3000, "operating_cost_cents": 1000, "market_contract_breach_cents": 500})
	var cards := report.cards as Array
	_check(cards[1].label == "LATE FILES", "late files must not be labeled shell quality", failures)
	_check(cards[2].value == "+$15.00", "shift net subtracts operating cost and breach exactly once", failures)
	_check("$30.00 credited" in cards[2].detail and "$5.00 contract penalties" in cards[2].detail, "accounting explanation uses actual amounts", failures)

	var audio := Audio.new()
	root.add_child(audio)
	await process_frame
	var voice := audio.get("_sound_egg") as AudioStreamWAV
	_check(audio.call("_play", &"test_work", voice, 1.0, -10.0, 0, &"SFX", Audio.PRIORITY_PHYSICAL), "work cue starts", failures)
	_check(audio.call("_play", &"test_reward", voice, 1.0, -6.0, 0, &"UI", Audio.PRIORITY_CONFIRMATION), "reward cue starts", failures)
	_check(audio.call("_play", &"test_later_work", voice, 1.0, -10.0, 0, &"SFX", Audio.PRIORITY_PHYSICAL), "work remains audible during payoff", failures)
	var voices := audio.find_children("SFXVoice_*", "AudioStreamPlayer", true, false)
	_check(voices[1].volume_db == -6.0, "reward retains its authored loudness", failures)
	_check(voices[2].volume_db == -18.0, "following work yields eight decibels to the payoff", failures)
	_check(voices.size() == 8, "mixing creates no extra players", failures)
	for player: AudioStreamPlayer in voices:
		player.stop()
		player.stream = null
	await create_timer(0.50).timeout
	audio.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("VISUAL_DESIGN_REFINEMENT_TEST_FAILED: " + failure)
		quit(1)
		return
	print("VISUAL_DESIGN_REFINEMENT_TEST_PASSED care=reflow+large-text reports=accounted plans=consistent audio=payoff-space")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
