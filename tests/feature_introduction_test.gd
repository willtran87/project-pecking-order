extends SceneTree

const FeatureIntroductionScript := preload("res://core/experience/feature_introduction.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var optional_layers: Array[StringName] = []
	for feature: StringName in FeatureIntroductionScript.SCHEDULE:
		optional_layers.append(feature)
	for feature in optional_layers:
		_check(
			not FeatureIntroductionScript.introduced(feature, 1),
			"%s must stay hidden on probation shift 1 so the opening is only the core loop" % feature,
			failures,
		)
		_check(
			FeatureIntroductionScript.introduced(feature, 1, false),
			"%s must be visible immediately when the schedule is not gated (Senior Roost / opt-out)" % feature,
			failures,
		)
		_check(
			FeatureIntroductionScript.introduced(feature, 5),
			"%s must be introduced by the final probation shift" % feature,
			failures,
		)
	_check(
		FeatureIntroductionScript.introduced(&"plan_menu", 2)
		and not FeatureIntroductionScript.introduced(&"career_workshop", 2),
		"shift 2 should add PLAN without also adding the Career Workshop",
		failures,
	)
	_check(
		FeatureIntroductionScript.introduced(&"unscheduled_core_loop", 1),
		"anything not on the schedule is core and always visible",
		failures,
	)
	for shift in range(1, 6):
		_check(
			FeatureIntroductionScript.new_on_shift(shift).size() <= 4,
			"shift %d should announce only a small number of new layers" % shift,
			failures,
		)
	_check(
		FeatureIntroductionScript.briefing_line(1).is_empty()
		and FeatureIntroductionScript.briefing_line(2).begins_with("NEW THIS SHIFT: PLAN"),
		"only shifts that add layers should produce a briefing line",
		failures,
	)
	if not failures.is_empty():
		for failure in failures:
			push_error("FEATURE_INTRODUCTION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FEATURE_INTRODUCTION_TEST_PASSED layers=%d" % optional_layers.size())
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
