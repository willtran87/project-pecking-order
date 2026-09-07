extends RefCounted


static func attention(intent: Dictionary) -> Dictionary:
	match String(intent.get("id", "")):
		"care", "deadline":
			return {"label": "! HELP NEEDED", "icon": &"urgent", "color": Color("f2ab87")}
		"sync", "choice":
			return {"label": "★ OPPORTUNITY", "icon": &"choice", "color": Color("f4d27b")}
		_:
			return {"label": "✓ WORKING", "icon": &"steady", "color": Color("9ccfc2")}


static func next_shift(report: Dictionary) -> Dictionary:
	var cracks := int(report.get("cracked", report.get("cracked_today", 0)))
	var overdue := int(report.get("overdue_claims", 0))
	var eggs := int(report.get("eggs", report.get("eggs_today", 0)))
	if cracks > 0:
		return {"strategy": "safe", "copy": "NEXT: FEWER THAN %d CRACKS · TRY SAFE" % cracks}
	if overdue > 0:
		return {"strategy": "fast", "copy": "NEXT: CLEAR FILES BEFORE THEY TURN OVERDUE"}
	if not bool(report.get("met_quota", false)):
		return {"strategy": "fast", "copy": "NEXT: BEAT YOUR %d-EGG SHIFT" % eggs}
	return {"strategy": "flock", "copy": "NEXT: KEEP THE QUOTA · FINISH WITH A RESTED FLOCK"}


static func strategy_copy(id: String) -> String:
	match id:
		"fast": return "FAST · MORE PACE / MORE SHELL RISK"
		"safe": return "SAFE · SHELL SAFETY / LESS PACE"
		"flock": return "FLOCK · LESS STRAIN / $2 FEED FUND"
	return ""
