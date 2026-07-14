class_name CampaignObjective
extends RefCounted

## Immutable, data-driven probation objective. Runtime shift metrics use integer
## values only, including booleans (0/1) and rates expressed in basis points.

const COMPARISON_MINIMUM: StringName = &"minimum"
const COMPARISON_MAXIMUM: StringName = &"maximum"
const COMPARISON_EQUAL: StringName = &"equal"

var id: StringName
var title: String
var description: String
var metric: StringName
var comparison: StringName
var target: int
var score_award: int


func _init(
	objective_id: StringName = &"",
	objective_title: String = "",
	objective_description: String = "",
	metric_id: StringName = &"",
	comparison_id: StringName = COMPARISON_MINIMUM,
	target_value: int = 0,
	award: int = 0
) -> void:
	id = objective_id
	title = objective_title
	description = objective_description
	metric = metric_id
	comparison = comparison_id
	target = target_value
	score_award = award


func is_completed(metrics: Dictionary) -> bool:
	var actual := int(metrics.get(metric, 0))
	match comparison:
		COMPARISON_MINIMUM:
			return actual >= target
		COMPARISON_MAXIMUM:
			return actual <= target
		COMPARISON_EQUAL:
			return actual == target
		_:
			return false


func to_dictionary(completed: bool = false) -> Dictionary:
	return {
		"id": String(id),
		"title": title,
		"description": description,
		"metric": String(metric),
		"comparison": String(comparison),
		"target": target,
		"score_award": score_award,
		"completed": completed,
	}
