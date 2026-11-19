extends RefCounted

## Event-only presentation of existing campaign facts. No rewards, forecasts,
## save fields or gameplay authority are created here.
static func compose(report: Dictionary, day: int, quota: int, chapter: Dictionary, doctrine: Dictionary, personal_goal: Dictionary) -> Dictionary:
	var source_day := int(report.get("day", 0))
	var has_previous := source_day == day - 1 and source_day > 0
	var carry := "Your equipment and flock relationships carry forward."
	var reason := "persistent_office"
	if has_previous:
		var compact := report.get("next_flock_compact", {}) as Dictionary
		var work_rule := report.get("next_work_to_rule", {}) as Dictionary
		var rework := int(report.get("rework_due_next_shift", 0))
		if not compact.is_empty() and int(compact.get("effective_day", -1)) == day:
			carry = "%s takes effect: %s" % [String(compact.get("compact_name", "Your flock promise")), String(compact.get("condition", "Keep the promise you filed."))]
			reason = "flock_promise"
		elif (bool(work_rule.get("active", false)) or bool(work_rule.get("scheduled", false))) and int(work_rule.get("day", -1)) == day:
			carry = "The flock's work-to-rule continues: slower work, safer shells."
			reason = "work_to_rule"
		elif rework > 0:
			carry = "%d rework file%s carry into this shift. Leave a hen room to clear them." % [rework, "" if rework == 1 else "s"]
			reason = "rework"
		elif not doctrine.is_empty():
			carry = "Your %s specialization stays in effect." % String(doctrine.get("name", doctrine.get("label", "chosen")))
			reason = "doctrine"
		elif not bool(report.get("met_quota", int(report.get("eggs", 0)) >= int(report.get("quota", 1)))):
			carry = "The last shift's quota was missed. Keep your upgrades and try a different rule or route."
			reason = "recovery"
	var focus := String(chapter.get("promise", "Choose a flock rule, route by specialty, and support hens who need help."))
	var title := "SHIFT %d · %s" % [day, String(chapter.get("title", "A NEW SHIFT"))]
	var target := "Lay %d eggs by 5 PM." % quota
	var optional := ""
	if String(personal_goal.get("status", "")) == "active" and int(personal_goal.get("day", -1)) == day:
		optional = "Your optional personal goal is still pinned."
	return {
		"day": day, "source_day": source_day if has_previous else 0,
		"title": title, "carry": carry, "reason": reason, "focus": focus,
		"target": target, "optional": optional,
		"summary": "%s\nNEXT SHIFT: %s %s" % [carry, target, focus],
		"briefing": "%s\n%s\nTODAY: %s\nChoose a flock rule below; hens work automatically.%s" % [title, carry, target, "\n" + optional if not optional.is_empty() else ""],
	}
