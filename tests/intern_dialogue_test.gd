extends SceneTree

const Library := preload("res://features/office/character_dialogue_library.gd")
const Catalog := preload("res://features/office/character_dialogue_catalog.gd")

const THEMES: Array[StringName] = [
	&"onboard",
	&"guided_shadow",
	&"stretch_project",
	&"culture_sprint",
	&"term_complete",
	&"growth_extension",
	&"recommendation_letter",
	&"paid_fellowship",
]


func _init() -> void:
	var failures: Array[String] = []
	for candidate_id in InternshipProgramState.CANDIDATE_ORDER:
		var speaker_id := Library.intern_speaker(candidate_id)
		_check(Library.SPEAKERS.has(speaker_id), "%s should map to a cast speaker" % candidate_id, failures)
		for theme_id in THEMES:
			var lines := Library.voice_lines(speaker_id, theme_id)
			_check(
				lines.size() >= 2,
				"%s should have repeat-resistant %s dialogue" % [speaker_id, theme_id],
				failures,
			)
	var sample := Catalog.beat_for_internship_action({
		"accepted": true,
		"action_id": &"intern_assignment",
		"candidate_id": &"lottie_ledger",
		"assignment_id": &"stretch_project",
		"day": 3,
		"cost_cents": 0,
	})
	_check(StringName(sample.get("speaker_id", &"")) == &"intern_lottie", "actions should route to the selected intern", failures)
	_check(
		String(sample.get("text", "")).length() >= 24,
		"intern action should create a substantial portrait dialogue beat",
		failures,
	)
	var transition_beats := Catalog.beats_for_internship_transitions({
		"internship_transitions": [{
			"accepted": true,
			"action_id": &"intern_term_complete",
			"candidate_id": &"tilly_tabs",
			"day": 4,
			"cost_cents": 0,
		}],
	})
	_check(
		transition_beats.size() == 1
		and StringName(transition_beats[0].get("speaker_id", &"")) == &"intern_tilly",
		"term milestones should produce the correct cast dialogue",
		failures,
	)

	if not failures.is_empty():
		for failure in failures:
			push_error("INTERN_DIALOGUE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("INTERN_DIALOGUE_TEST_PASSED cast=4 themes=8 lines>=64 events=state-driven")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
