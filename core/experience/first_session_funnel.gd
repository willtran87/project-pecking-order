class_name FirstSessionFunnel
extends RefCounted

## Privacy-local, presentation-only evidence for a fresh player's first file.
## The funnel is never saved into campaign authority and never transmitted. It
## exists so browser diagnostics, moderated sessions, and deterministic audits
## can answer when the first meaningful actions and payoff actually happened.

const VERSION := 4
const MILESTONES: Array[Dictionary] = [
	{"id": &"intake_ready", "label": "INTAKE READY", "target_seconds": 5},
	{"id": &"file_started", "label": "FILE STARTED", "target_seconds": 60},
	{"id": &"hen_inspected", "label": "HEN INSPECTED", "target_seconds": 120},
	{"id": &"route_filed", "label": "ROUTE FILED", "target_seconds": 180},
	{"id": &"checkin_filed", "label": "CHECK-IN FILED", "target_seconds": 300},
	{"id": &"priority_peck", "label": "PRIORITY PECK", "target_seconds": 480},
	{"id": &"first_egg", "label": "FIRST EGG DELIVERED", "target_seconds": 600},
	{"id": &"reinvestment", "label": "FIRST REINVESTMENT", "target_seconds": 720},
	{"id": &"first_review", "label": "FIRST SHIFT REVIEW", "target_seconds": 900},
]
const SIGNAL_IDS: Array[StringName] = [
	&"guidance_used",
	&"ledger_opened",
	&"route_miss",
	&"next_moment_used",
	&"settings_opened",
]

var _started_msec := 0
var _active := false
var _mode: StringName = &"idle"
var _reached_msec: Dictionary[StringName, int] = {}
var _signals: Dictionary[StringName, int] = {}
var _route_first := false
var _first_laid_msec := -1


func begin_intake(now_msec: int = -1) -> void:
	_started_msec = _now(now_msec)
	_active = true
	_mode = &"fresh_intake"
	_reached_msec.clear()
	_signals.clear()
	_route_first = false
	_first_laid_msec = -1
	mark(&"intake_ready", _started_msec)


func begin_new_file(now_msec: int = -1) -> void:
	if not _active or _mode != &"fresh_intake":
		begin_intake(now_msec)
	_mode = &"fresh_file"
	mark(&"file_started", now_msec)


func begin_resume() -> void:
	_active = false
	_mode = &"resumed_file"
	_reached_msec.clear()
	_signals.clear()
	_route_first = false
	_first_laid_msec = -1


func observe_signal(signal_id: StringName) -> bool:
	if not _active or signal_id not in SIGNAL_IDS:
		return false
	_signals[signal_id] = int(_signals.get(signal_id, 0)) + 1
	return true


func mark(milestone_id: StringName, now_msec: int = -1) -> bool:
	if not _active or _reached_msec.has(milestone_id) or _definition(milestone_id).is_empty():
		return false
	_reached_msec[milestone_id] = maxi(_started_msec, _now(now_msec))
	return true


func observe(
	simulation_snapshot: Dictionary,
	first_clutch: Dictionary,
	campaign_stage: StringName,
	now_msec: int = -1,
) -> void:
	if not _active or _mode != &"fresh_file":
		return
	_route_first = _route_first or bool(first_clutch.get("route_first_lesson", false))
	if _first_laid_msec < 0 and bool(first_clutch.get("delivery_laid", false)):
		_first_laid_msec = _now(now_msec)
	if bool(first_clutch.get("inspected", false)):
		mark(&"hen_inspected", now_msec)
	if bool(first_clutch.get("specialty_routed", false)):
		mark(&"route_filed", now_msec)
	if bool(first_clutch.get("checkin_filed", false)):
		mark(&"checkin_filed", now_msec)
	if not _route_first and int(first_clutch.get("assisted_claim_id", -1)) >= 0:
		mark(&"priority_peck", now_msec)
	if bool(first_clutch.get("delivery_seen", false)) or (not _route_first and int(simulation_snapshot.get("eggs_today", 0)) > 0):
		mark(&"first_egg", now_msec)
	var reinvestment := simulation_snapshot.get("first_clutch_reinvestment", {}) as Dictionary
	if StringName(String(reinvestment.get("status", &""))) in [&"purchased", &"banked"]:
		mark(&"reinvestment", now_msec)
	if int(simulation_snapshot.get("shift_phase", 0)) == 3 or campaign_stage in [&"farmer", &"credit", &"probation"]:
		mark(&"first_review", now_msec)


func snapshot(now_msec: int = -1) -> Dictionary:
	var observed_now := _now(now_msec)
	var rows: Array[Dictionary] = []
	var next_id: StringName = &""
	var reached_count := 0
	var required_remaining := 0
	for definition in MILESTONES:
		var milestone_id := StringName(definition["id"])
		var reached := _reached_msec.has(milestone_id)
		var optional := _route_first and milestone_id in [&"checkin_filed", &"priority_peck"]
		var elapsed_seconds := (
			maxi(0, int(_reached_msec[milestone_id]) - _started_msec) / 1_000.0
			if reached else
			-1.0
		)
		if reached:
			reached_count += 1
		elif not optional:
			required_remaining += 1
			if next_id == &"":
				next_id = milestone_id
		rows.append({
			"id": String(milestone_id),
			"label": String(definition["label"]),
			"reached": reached,
			"optional": optional,
			"elapsed_seconds": snappedf(elapsed_seconds, 0.001) if reached else -1.0,
			"target_seconds": int(definition["target_seconds"]),
			"inside_budget": reached and elapsed_seconds <= float(definition["target_seconds"]),
		})
	var signal_snapshot: Dictionary = {}
	for signal_id in SIGNAL_IDS:
		signal_snapshot[String(signal_id)] = int(_signals.get(signal_id, 0))
	var friction_flags: Array[String] = []
	if int(_signals.get(&"route_miss", 0)) >= 2:
		friction_flags.append("repeated_route_miss")
	if int(_signals.get(&"ledger_opened", 0)) >= 3 and reached_count < 6:
		friction_flags.append("frequent_ledger_reference")
	if int(_signals.get(&"guidance_used", 0)) >= 4 and reached_count < 5:
		friction_flags.append("primary_action_reliance")
	var micro_definitions: Array[Dictionary] = [
		{"id": "plan", "label": "PLAN", "icon": "goal", "target_seconds": 5, "complete": bool(_reached_msec.has(&"file_started"))},
		{"id": "route", "label": "ROUTE", "icon": "route", "target_seconds": 12, "complete": bool(_reached_msec.has(&"route_filed"))},
		{"id": "react", "label": "REACT", "icon": "shield", "target_seconds": 22, "complete": bool(_reached_msec.has(&"priority_peck"))},
		{"id": "reward", "label": "REWARD", "icon": "egg", "target_seconds": 30, "complete": bool(_reached_msec.has(&"first_egg"))},
	]
	var micro_completed := 0
	if _route_first:
		micro_definitions[2] = {"id": "work", "label": "AUTO WORK", "icon": "goal", "target_seconds": 35, "complete": _first_laid_msec >= 0}
		micro_definitions[3]["target_seconds"] = 45
	var micro_beats: Array[Dictionary] = []
	for definition in micro_definitions:
		var beat := definition.duplicate(true)
		var beat_complete := bool(beat.get("complete", false))
		if beat_complete:
			micro_completed += 1
		beat["state"] = "complete" if beat_complete else ("current" if micro_completed == micro_beats.size() else "upcoming")
		beat["label_visible"] = not beat_complete
		micro_beats.append(beat)
	return {
		"version": VERSION,
		"privacy": "LOCAL SESSION ONLY / NEVER TRANSMITTED",
		"authoritative": false,
		"active": _active,
		"mode": String(_mode),
		"elapsed_seconds": (
			snappedf(maxi(0, observed_now - _started_msec) / 1_000.0, 0.001)
			if _active else
			0.0
		),
		"reached_count": reached_count,
		"total_count": MILESTONES.size(),
		"complete": required_remaining == 0,
		"next_id": String(next_id),
		"milestones": rows,
		"signals": signal_snapshot,
		"friction_flags": friction_flags,
		"opening_timing": _opening_timing(),
		"micro_shift": {
			"budget_seconds": 45 if _route_first else 30,
			"beat_count": micro_beats.size(),
			"completed_count": micro_completed,
			"complete": micro_completed == micro_beats.size(),
			"beats": micro_beats,
			"retired_label_count": micro_completed,
			"icons_remain_after_labels_retire": true,
		},
	}


func _opening_timing() -> Dictionary:
	var route_msec := int(_reached_msec.get(&"route_filed", -1))
	var delivered_msec := int(_reached_msec.get(&"first_egg", -1))
	return {
		"route_first": _route_first,
		"target_seconds": 45,
		"production_seconds": (_first_laid_msec - route_msec) / 1000.0 if route_msec >= 0 and _first_laid_msec >= route_msec else -1.0,
		"presentation_seconds": (delivered_msec - _first_laid_msec) / 1000.0 if _first_laid_msec >= 0 and delivered_msec >= _first_laid_msec else -1.0,
		"route_to_delivery_seconds": (delivered_msec - route_msec) / 1000.0 if route_msec >= 0 and delivered_msec >= route_msec else -1.0,
		"clock": "LOCAL WALL CLOCK; INCLUDES PLAYER PAUSES AND RENDER DELAYS",
	}


## Explicit, player-triggered handoff for a moderator or issue report. Calling
## this never transmits anything; it only produces a bounded JSON receipt that
## the player may choose to save and share.
func export_receipt(now_msec: int = -1) -> String:
	var payload := snapshot(now_msec)
	payload["export_version"] = 2
	payload["consent"] = "PLAYER REQUESTED LOCAL EXPORT"
	payload["contains_personal_data"] = false
	payload["transmitted"] = false
	payload["instructions"] = "Share this file only if you choose to participate in a playtest or bug report."
	return JSON.stringify(payload, "  ")


func _definition(milestone_id: StringName) -> Dictionary:
	for definition in MILESTONES:
		if StringName(definition["id"]) == milestone_id:
			return definition
	return {}


func _now(injected_msec: int) -> int:
	return injected_msec if injected_msec >= 0 else Time.get_ticks_msec()
