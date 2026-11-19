class_name FeatureIntroduction
extends RefCounted

## Progressive disclosure for the five-shift probation file.
##
## Shift 1 is only the core loop: route claim files, Priority Peck, deliver
## eggs, answer incidents and file the closing credit memo. Each later shift
## introduces at most a couple of optional management layers. This is purely a
## presentation schedule: simulation rules are unchanged, nothing is saved, and
## Senior Roost files (or a schedule switched off) see every system at once.

## feature id -> first probation shift on which the player sees it.
const SCHEDULE := {
	&"plan_menu": 2,
	&"guided_strategies": 2,
	&"manager_intervention": 2,
	&"playbook_extras": 3,
	&"career_workshop": 3,
	&"flock_ties": 3,
	&"feed_party": 3,
	&"overtime": 3,
	&"flockwatch_operations": 3,
	&"flockwatch_capital": 3,
	&"flockwatch_records": 3,
}

## Short, player-facing names for the "NEW THIS SHIFT" briefing line.
const LABELS := {
	&"plan_menu": "PLAN [Q]",
	&"guided_strategies": "FAST / SAFE / FLOCK PLANS",
	&"manager_intervention": "MANAGER INTERVENTION",
	&"playbook_extras": "PLAYBOOK EXTRAS",
	&"career_workshop": "CAREER WORKSHOP",
	&"flock_ties": "FLOCK TIES [B]",
	&"feed_party": "FEED PARTY",
	&"overtime": "OVERTIME",
	&"flockwatch_operations": "FLOCKWATCH OPS",
	&"flockwatch_capital": "FLOCKWATCH CAPITAL",
	&"flockwatch_records": "FLOCKWATCH RECORDS",
}

## Features the briefing line names (sub-features are folded into a parent).
const ANNOUNCED := [
	&"plan_menu",
	&"manager_intervention",
	&"career_workshop",
	&"flock_ties",
	&"feed_party",
	&"flockwatch_capital",
]


static func first_shift(feature: StringName) -> int:
	return int(SCHEDULE.get(feature, 1))


## shift: current probation shift (1-based). gated: false for Senior Roost
## files, completed careers, or when the player has opted out.
static func introduced(feature: StringName, shift: int, gated: bool = true) -> bool:
	if not gated:
		return true
	return maxi(1, shift) >= first_shift(feature)


## Player-facing names of features that first appear on exactly this shift.
static func new_on_shift(shift: int) -> PackedStringArray:
	var names := PackedStringArray()
	for feature: StringName in ANNOUNCED:
		if first_shift(feature) == shift:
			names.append(String(LABELS.get(feature, String(feature).to_upper())))
	return names


static func briefing_line(shift: int) -> String:
	var names := new_on_shift(shift)
	if names.is_empty():
		return ""
	return "NEW THIS SHIFT: %s" % " · ".join(names)
