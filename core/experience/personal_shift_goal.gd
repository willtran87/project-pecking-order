extends RefCounted

## Optional, non-economic ambition. All progress comes from simulation facts.
static func offer(report: Dictionary) -> Dictionary:
	var day := maxi(1, int(report.get("day", 1))) + 1
	var quota := maxi(1, int(report.get("next_quota", report.get("quota", report.get("quota_target", 1)))))
	var cracks := maxi(0, int(report.get("cracked", report.get("cracked_today", 0))))
	var overdue := maxi(0, int(report.get("overdue_claims", 0)))
	if cracks > 0:
		return {"version": 1, "day": day, "kind": "shells", "target": cracks - 1, "quota": quota, "status": "active"}
	if overdue > 0:
		return {"version": 1, "day": day, "kind": "files", "target": 0, "quota": quota, "status": "active"}
	return {"version": 1, "day": day, "kind": "output", "target": maxi(quota, int(report.get("eggs", report.get("eggs_today", 0))) + 1), "quota": quota, "status": "active"}


static func normalize(value: Variant) -> Dictionary:
	if not value is Dictionary or value.is_empty():
		return {}
	for field in ["version", "day", "target", "quota"]:
		var number: Variant = value.get(field)
		if typeof(number) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(number)) or float(number) != floorf(float(number)) or float(number) < 0.0 or float(number) > 1000000.0:
			return {}
	if int(value.version) != 1 or int(value.day) < 1 or int(value.quota) < 1:
		return {}
	if value.get("kind") not in ["shells", "files", "output"] or value.get("status") not in ["active", "complete", "missed"]:
		return {}
	if (value.kind == "output" and int(value.target) < 1) or (value.kind == "files" and int(value.target) != 0):
		return {}
	return {"version": 1, "day": int(value.day), "target": int(value.target), "quota": int(value.quota), "kind": String(value.kind), "status": String(value.status)}


## Repair optional legacy goals against restored authority, without touching the
## career or completed accomplishments. Older releases accidentally saved 1.
static func reconcile(value: Variant, day: int, quota: int, report: Dictionary) -> Dictionary:
	var goal := normalize(value)
	if goal.is_empty() or goal.status != "active":
		return goal
	if int(goal.day) == day:
		goal.quota = maxi(1, quota)
	elif int(goal.day) == int(report.get("day", -2)) + 1:
		goal.quota = maxi(1, int(report.get("next_quota", goal.quota)))
	if goal.kind == "output":
		goal.target = maxi(int(goal.target), int(goal.quota))
	return goal


static func strategy(goal: Dictionary) -> Dictionary:
	match String(goal.get("kind", "")):
		"shells": return {"id": "safe", "label": "SAFE", "copy": "SAFE · gentler work, fewer shell risks. Trade some speed."}
		"files": return {"id": "fast", "label": "FAST", "copy": "FAST · clear files sooner. Watch fatigue and shells."}
	return {"id": "fast", "label": "FAST", "copy": "FAST · build output. Check in before fatigue builds."}


static func label(goal: Dictionary) -> String:
	match String(goal.get("kind", "")):
		"shells": return "MEET QUOTA · AT MOST %d %s" % [int(goal.target), "CRACK" if int(goal.target) == 1 else "CRACKS"]
		"files": return "MEET QUOTA · NO OVERDUE FILES"
		"output": return "FILE %d EGGS" % int(goal.target)
	return ""


static func progress(goal: Dictionary, snapshot: Dictionary) -> String:
	var eggs := int(snapshot.get("eggs_today", snapshot.get("eggs", 0)))
	match String(goal.get("kind", "")):
		"shells": return "GOAL %d/%d · CRACKS %d/%d" % [eggs, int(snapshot.get("quota_target", goal.quota)), int(snapshot.get("cracked_today", snapshot.get("cracked", 0))), int(goal.target)]
		"files": return "GOAL %d/%d · LATE %d" % [eggs, int(snapshot.get("quota_target", goal.quota)), int(snapshot.get("overdue_claims", 0))]
		"output": return "GOAL · %d/%d EGGS" % [eggs, int(goal.target)]
	return ""


static func finish(goal: Dictionary, report: Dictionary) -> Dictionary:
	if goal.is_empty() or goal.status != "active" or int(goal.day) != int(report.get("day", -1)):
		return goal.duplicate(true)
	var result := goal.duplicate(true)
	var eggs := int(report.get("eggs", report.get("eggs_today", 0)))
	var quota := maxi(1, int(report.get("quota", report.get("quota_target", goal.quota))))
	var quota_met := eggs >= quota and bool(report.get("met_quota", true))
	var success := false
	match String(goal.kind):
		"shells": success = quota_met and int(report.get("cracked", report.get("cracked_today", 0))) <= int(goal.target)
		"files": success = quota_met and int(report.get("overdue_claims", 0)) == 0
		"output": success = quota_met and eggs >= int(goal.target)
	result["status"] = "complete" if success else "missed"
	return result
