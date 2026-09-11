class_name CampaignMilestoneChoice
extends RefCounted

## One mutually exclusive probation milestone choice and the gameplay unlock it
## grants. Effects remain primitive integer values so simulation and UI layers
## can consume them without depending on campaign implementation details.

var id: StringName
var title: String
var description: String
var unlock_id: StringName
var unlock_label: String
var score_bonus: int
var effects: Dictionary
var doctrine: Dictionary


func _init(
	choice_id: StringName = &"",
	choice_title: String = "",
	choice_description: String = "",
	granted_unlock_id: StringName = &"",
	granted_unlock_label: String = "",
	choice_score_bonus: int = 0,
	choice_effects: Dictionary = {},
	choice_doctrine: Dictionary = {}
) -> void:
	id = choice_id
	title = choice_title
	description = choice_description
	unlock_id = granted_unlock_id
	unlock_label = granted_unlock_label
	score_bonus = choice_score_bonus
	effects = choice_effects.duplicate(true)
	doctrine = choice_doctrine.duplicate(true)


func to_dictionary() -> Dictionary:
	return {
		"id": String(id),
		"title": title,
		"description": description,
		"unlock_id": String(unlock_id),
		"unlock_label": unlock_label,
		"score_bonus": score_bonus,
		"effects": effects.duplicate(true),
		"doctrine": doctrine.duplicate(true),
	}
