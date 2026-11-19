class_name CareerWorkshop
extends RefCounted

const TOOLS := {
	"relay_bell": {"label": "ROUTING BELL", "day": 2, "effect": "A recommended route in each lane banks one extra Peck.", "tip": "Visit all 3 trays. One reserve at a time; each lane pays once per shift."},
	"shell_guard": {"label": "CANDLING LENS", "day": 3, "effect": "Your first 2 strong Pecks protect those eggs from cracking.", "tip": "Spend your timing on valuable or fragile files. Two protected eggs per shift."},
	"team_kettle": {"label": "TEAM KETTLE", "day": 4, "effect": "Alternate strong Pecks: both hens recover; the previous hen gets +10 work.", "tip": "Switch hens to relay: -4 stress/fatigue for both. Up to 3 relays per shift."},
}
const ADVANCED := ["route_circuit", "precision_pair", "flock_relay"]
const SPECIALIST := ["mixed_basket", "deadline_rescue", "team_coaching"]
const TUNINGS := {
	"relay_bell": {"id": "sprint", "label": "SPRINT", "day": 3, "effect": "First 3 strong Pecks: +10 work, but +3 stress. Replaces reserve Pecks."},
	"shell_guard": {"id": "precision", "label": "PRECISION", "day": 4, "effect": "Protect 3 eggs, but only PERFECT Pecks qualify. Strong Pecks keep the lens charge."},
	"team_kettle": {"id": "mentor", "label": "MENTOR", "day": 5, "effect": "Alternate strong Pecks: the previous hen earns 6 XP. Replaces recovery/work; 3 relays."},
}
const MASTER_MODES := {
	"relay_bell": {"id": "handoff", "label": "HANDOFF", "day": 4, "effect": "Alternate strong Pecks: pass +18 work to the previous working hen. Replaces reserve Pecks; 3 handoffs.", "requirement": "Claim Route Circuit or Mixed Basket after using the bell.", "contracts": ["route_circuit", "mixed_basket", "relay_finish"]},
	"shell_guard": {"id": "triage", "label": "TRIAGE", "day": 4, "effect": "Strong-Peck a file in its final hour: protect its egg and add +15 work. Two charges; early Pecks keep charges.", "requirement": "Claim Precision Pair or Deadline Rescue after using the lens.", "contracts": ["precision_pair", "deadline_rescue"]},
	"team_kettle": {"id": "encourage", "label": "ENCOURAGE", "day": 5, "effect": "Alternate strong Pecks: both hens lose up to 8 stress and fatigue. Replaces work/XP; 3 relays.", "requirement": "Claim Flock Relay or Team Coaching after using the kettle.", "contracts": ["flock_relay", "team_coaching", "care_circle"]},
}
const CHALLENGES := {
	"relay_finish": {"label": "RELAY FINISH", "short": "HENS", "target": 3, "goal": "Finish a clean Peck-assisted egg with 3 different hens.", "tip": "NEXT: Assist different hens, then finish their eggs. Handoff helps; repeated hens and cracks do not count."},
	"care_circle": {"label": "CARE CIRCLE", "short": "SUPPORTED", "target": 3, "goal": "Include 3 different hens in successful kettle relays.", "tip": "NEXT: Alternate strong Pecks across the flock. A relay needs two different hens; unfinished pairs do not count."},
	"mixed_basket": {"label": "MIXED BASKET", "short": "TRAYS", "target": 3, "goal": "Produce a clean egg from each of the 3 file types.", "tip": "NEXT: Spread assignments across all three trays. Routing alone does not count; finish the eggs."},
	"deadline_rescue": {"label": "DEADLINE RESCUE", "short": "RESCUED", "target": 2, "goal": "Strong-Peck 2 files in their final hour; finish clean and on time.", "tip": "NEXT: Watch due times. Peck with 0–60 game minutes left, then finish before the deadline. Late or cracked eggs do not count."},
	"team_coaching": {"label": "TEAM COACHING", "short": "COACHED", "target": 3, "goal": "Land a strong or perfect Peck for 3 different hens.", "tip": "NEXT: Switch hens after a strong Peck. Repeating the same hen adds no progress."},
	"route_circuit": {"label": "ROUTE CIRCUIT", "short": "TRAYS", "target": 3, "goal": "Make a recommended route in each of the 3 trays.", "tip": "NEXT: Visit Nest Damage, Predator Loss, and Appeals. Repeating a tray adds no progress."},
	"precision_pair": {"label": "PRECISION PAIR", "short": "ASSISTED", "target": 2, "goal": "Finish 2 Peck-assisted eggs without cracks.", "tip": "NEXT: Peck active files, then let those hens finish. Cracked eggs do not count."},
	"flock_relay": {"label": "FLOCK RELAY", "short": "HENS", "target": 3, "goal": "Have 3 different hens each produce a clean egg.", "tip": "NEXT: Spread work across your flock. Repeated eggs from one hen count only once."},
}

var mastered_tools: Array[String] = []
var assisted_workers: Array[int] = []
var relief_workers: Array[int] = []

var stamps := 0
var owned: Array[String] = []
var equipped := ""
var tuning := "standard"
var last_award_day := 0
var daily_day := 0
var route_lanes: Array[String] = []
var clean_workers: Array[int] = []
var assisted_clean := 0
var bell_lanes: Array[String] = []
var protected_claims: Array[int] = []
var uses := 0
var previous_peck_worker := -1
var loadout_locked := false
var clean_lanes: Array[String] = []
var coached_workers: Array[int] = []
var rescue_claims: Array[int] = []
var rescued_clean := 0


func begin_day(day: int) -> void:
	if daily_day == day:
		return
	daily_day = day
	route_lanes.clear()
	clean_workers.clear()
	assisted_clean = 0
	bell_lanes.clear()
	protected_claims.clear()
	uses = 0
	previous_peck_worker = -1
	loadout_locked = false
	clean_lanes.clear()
	coached_workers.clear()
	rescue_claims.clear()
	rescued_clean = 0
	assisted_workers.clear()
	relief_workers.clear()


static func contract_for(day: int, plan: String, tool: String = "", mode: String = "standard") -> String:
	if day >= 4 and tool == "relay_bell" and mode == "handoff" and plan == "fast":
		return "relay_finish" if day % 2 == 0 else "mixed_basket"
	if day >= 4 and tool == "shell_guard" and mode == "triage" and plan == "safe":
		return "deadline_rescue" if day % 2 == 0 else "precision_pair"
	if day >= 5 and tool == "team_kettle" and mode == "encourage" and plan == "flock":
		return "care_circle" if day % 2 == 1 else "flock_relay"
	var slot := ["fast", "safe", "flock"].find(plan)
	if slot < 0:
		return ""
	if day >= 5:
		var rotation := ADVANCED + SPECIALIST
		return rotation[(slot + day - 2) % rotation.size()]
	if day >= slot + 2:
		return ADVANCED[slot]
	return ["fit_three", "clean_pair", "peck_pair"][slot]


static func horizon(day: int) -> String:
	match day:
		1: return "NEXT SHIFT: Route Circuit + Routing Bell unlock. Challenges earn workshop stamps."
		2: return "NEXT SHIFT: Candling Lens unlocks; tune your Routing Bell for Sprint."
		3: return "NEXT SHIFT: Team Kettle unlocks; try the lens's stricter Precision mode."
	return "Shift 5+: mixed baskets, deadline rescues and team coaching join the rotation. Tune tools before work starts."


func progress(contract_id: String, day: int) -> int:
	if day != daily_day:
		return 0
	match contract_id:
		"relay_finish": return assisted_workers.size()
		"care_circle": return relief_workers.size()
		"mixed_basket": return clean_lanes.size()
		"deadline_rescue": return rescued_clean
		"team_coaching": return coached_workers.size()
		"route_circuit": return route_lanes.size()
		"precision_pair": return assisted_clean
		"flock_relay": return clean_workers.size()
	return 0


func record_route(day: int, lane: String, recommended: bool) -> void:
	begin_day(day)
	loadout_locked = true
	if recommended and lane not in route_lanes:
		route_lanes.append(lane)


func record_strong_peck(day: int, worker_id: int, claim_id: int, minutes_left: int) -> void:
	begin_day(day)
	if worker_id not in coached_workers:
		coached_workers.append(worker_id)
	if minutes_left >= 0 and minutes_left <= 60 and claim_id not in rescue_claims:
		rescue_claims.append(claim_id)


func record_egg(day: int, worker_id: int, clean: bool, assisted: bool, lane: String = "", claim_id: int = -1, on_time: bool = false) -> void:
	begin_day(day)
	loadout_locked = true
	if clean:
		if lane in ["nest_damage", "predator_loss", "appeals"] and lane not in clean_lanes:
			clean_lanes.append(lane)
		if claim_id in rescue_claims and on_time:
			rescued_clean += 1
		if worker_id not in clean_workers:
			clean_workers.append(worker_id)
		if assisted:
			assisted_clean += 1
			if worker_id not in assisted_workers:
				assisted_workers.append(worker_id)
	rescue_claims.erase(claim_id)


func mastery_offer(contract_id: String) -> Dictionary:
	if equipped not in MASTER_MODES or equipped in mastered_tools:
		return {}
	var definition: Dictionary = MASTER_MODES[equipped]
	if contract_id not in definition.contracts or (uses == 0 and bell_lanes.is_empty()):
		return {}
	return {"tool": equipped, "id": definition.id, "label": definition.label, "day": definition.day, "effect": definition.effect}


func award(day: int, contract_id: String = "") -> bool:
	if last_award_day >= day:
		return false
	last_award_day = day
	if daily_day == day and not mastery_offer(contract_id).is_empty():
		mastered_tools.append(equipped)
	if stamps + owned.size() >= TOOLS.size():
		return false
	stamps += 1
	return true


func catalog(day: int, running: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var locked := daily_day == day and loadout_locked
	for id: String in TOOLS:
		var definition: Dictionary = TOOLS[id]
		var purchased := id in owned
		var unlocked := day >= int(definition.day)
		var available := running and unlocked and ((purchased and not locked and equipped != id) or (not purchased and stamps > 0))
		var action := "EQUIPPED" if purchased and equipped == id else "EQUIP" if purchased else "UNLOCK · 1 STAMP"
		var reason := ""
		if not unlocked:
			reason = "Unlocks on shift %d." % int(definition.day)
		elif purchased and locked:
			reason = "Your tool locks when work starts. Swap before work next shift."
		elif not purchased and stamps == 0:
			reason = "Complete a shift challenge and claim its reward to earn a stamp."
		elif not purchased and locked:
			reason = "Unlock permanently now; equip before work next shift."
		var alternate: Dictionary = TUNINGS[id].duplicate(true)
		alternate["unlocked"] = day >= int(alternate.day)
		var mastery_definition: Dictionary = MASTER_MODES[id]
		var mastery := {"id": mastery_definition.id, "label": mastery_definition.label, "day": mastery_definition.day, "effect": mastery_definition.effect, "requirement": mastery_definition.requirement}
		mastery["earned"] = id in mastered_tools
		mastery["unlocked"] = bool(mastery.earned) and day >= int(mastery.day)
		result.append({"mastery": mastery, "kind": "workshop", "id": id, "label": definition.label, "gain": definition.effect, "cost": "FREE TO EQUIP" if purchased else "1 WORKSHOP STAMP", "risk": "ONE EQUIPPED TOOL", "tip": definition.tip, "detail": reason, "reason": reason, "available": available, "owned": purchased, "equipped": equipped == id, "unlock_day": definition.day, "action": action, "tuning": tuning if equipped == id else "standard", "alternate": alternate, "can_configure": running and unlocked and not locked and (purchased or stamps > 0)})
	return result


func choose(id: String, day: int, running: bool) -> Dictionary:
	var parts := id.split("/", true)
	if parts.size() > 2:
		return {"accepted": false, "reason": "Unknown tool tuning."}
	id = parts[0]
	var requested := parts[1] if parts.size() == 2 else "standard"
	if not TOOLS.has(id) or not tuning_unlocked(id, requested, day):
		return {"accepted": false, "reason": "That tuning is not unlocked yet."}
	for option in catalog(day, running):
		if option.id != id:
			continue
		var retuning := bool(option.can_configure) and equipped == id and tuning != requested
		if not bool(option.available) and not retuning:
			return {"accepted": false, "reason": option.reason}
		if requested != "standard" and not bool(option.can_configure):
			return {"accepted": false, "reason": "Tune before work starts next shift."}
		begin_day(day)
		var purchased := id in owned
		if not purchased:
			stamps -= 1
			owned.append(id)
		if not loadout_locked:
			equipped = id
			tuning = requested
		var gain := String(option.gain) if requested == "standard" else String((MASTER_MODES[id] if requested == MASTER_MODES[id].id else TUNINGS[id]).effect)
		return {"accepted": true, "playbook_kind": "workshop", "choice_id": id, "label": option.label, "day": day, "effects": {"gain": gain, "cost": "FREE" if purchased else "1 STAMP", "risk": "ONE TOOL AT A TIME"}, "outcome": "%s %s (%s). %s" % [option.label, "equipped" if equipped == id else "unlocked for future shifts", requested.to_upper(), gain]}
	return {"accepted": false, "reason": "Unknown workshop tool."}


func tuning_unlocked(tool: String, mode: String, day: int) -> bool:
	if not TOOLS.has(tool):
		return false
	if mode == "standard":
		return true
	if mode == TUNINGS[tool].id:
		return day >= int(TUNINGS[tool].day)
	return mode == MASTER_MODES[tool].id and tool in mastered_tools and day >= int(MASTER_MODES[tool].day)


func snapshot(day: int, contract_id: String = "") -> Dictionary:
	var mode_label := "" if tuning == "standard" else " · " + tuning.to_upper()
	return {"mastered_tools": mastered_tools.duplicate(), "mastery_offer": mastery_offer(contract_id), "stamps": stamps, "owned": owned.duplicate(), "equipped": equipped, "tuning": tuning, "equipped_label": String((TOOLS.get(equipped, {}) as Dictionary).get("label", "NO TOOL")) + mode_label, "locked": daily_day == day and loadout_locked, "uses": uses if daily_day == day else 0, "protected_count": protected_claims.size() if daily_day == day else 0, "bell_lanes": bell_lanes.duplicate() if daily_day == day else [], "horizon": horizon(day), "day": day, "all_earned": stamps + owned.size() >= TOOLS.size()}


func to_save_data() -> Dictionary:
	return {"mastered_tools": mastered_tools.duplicate(), "assisted_workers": assisted_workers.duplicate(), "relief_workers": relief_workers.duplicate(), "stamps": stamps, "owned": owned.duplicate(), "equipped": equipped, "tuning": tuning, "clean_lanes": clean_lanes.duplicate(), "coached_workers": coached_workers.duplicate(), "rescue_claims": rescue_claims.duplicate(), "rescued_clean": rescued_clean, "last_award_day": last_award_day, "daily_day": daily_day, "route_lanes": route_lanes.duplicate(), "clean_workers": clean_workers.duplicate(), "assisted_clean": assisted_clean, "bell_lanes": bell_lanes.duplicate(), "protected_claims": protected_claims.duplicate(), "uses": uses, "previous_peck_worker": previous_peck_worker, "loadout_locked": loadout_locked}


static func from_save_data(value: Variant, day: int, worker_count: int) -> CareerWorkshop:
	var result := CareerWorkshop.new()
	if value == null:
		return result
	if not value is Dictionary:
		return null
	var data := (value as Dictionary).duplicate(true)
	# Older careers keep their original tool behavior and start new counters empty.
	for field in ["clean_lanes", "coached_workers", "rescue_claims", "mastered_tools", "assisted_workers", "relief_workers"]:
		if not data.has(field): data[field] = []
	if not data.has("rescued_clean"): data["rescued_clean"] = 0
	var saved_tuning: Variant = data.get("tuning", "standard")
	if typeof(saved_tuning) != TYPE_STRING: return null
	result.tuning = saved_tuning
	for field in ["stamps", "last_award_day", "daily_day", "assisted_clean", "uses", "previous_peck_worker", "rescued_clean"]:
		var number: Variant = data.get(field)
		if typeof(number) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(number)) or float(number) != floorf(float(number)):
			return null
		result.set(field, int(number))
	if result.stamps < 0 or result.stamps > 3 or result.last_award_day < 0 or result.last_award_day > day or result.daily_day < 0 or result.daily_day > day or result.assisted_clean < 0 or result.assisted_clean > 99999 or result.uses < 0 or result.uses > 3 or result.previous_peck_worker < -1 or result.previous_peck_worker >= worker_count:
		return null
	if typeof(data.get("equipped")) != TYPE_STRING or typeof(data.get("loadout_locked")) != TYPE_BOOL:
		return null
	result.equipped = data.equipped
	if result.rescued_clean < 0 or result.rescued_clean > 99999:
		return null
	result.loadout_locked = data.loadout_locked
	for field in ["owned", "route_lanes", "bell_lanes", "clean_workers", "protected_claims", "clean_lanes", "coached_workers", "rescue_claims", "mastered_tools", "assisted_workers", "relief_workers"]:
		if not data.get(field) is Array:
			return null
		var seen: Array = []
		for item: Variant in data[field]:
			if item in seen:
				return null
			if field in ["owned", "route_lanes", "bell_lanes", "clean_lanes", "mastered_tools"]:
				if typeof(item) != TYPE_STRING or (not TOOLS.has(item) if field in ["owned", "mastered_tools"] else item not in ["nest_damage", "predator_loss", "appeals"]):
					return null
			else:
				if typeof(item) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(item)) or float(item) != floorf(float(item)) or int(item) < (1 if field in ["protected_claims", "rescue_claims"] else 0) or int(item) >= (2000000000 if field in ["protected_claims", "rescue_claims"] else worker_count):
					return null
			seen.append(item)
		if field in ["owned", "route_lanes", "bell_lanes", "clean_lanes", "mastered_tools"]:
			(result.get(field) as Array[String]).assign(seen)
		else:
			(result.get(field) as Array[int]).assign(seen)
	if result.stamps + result.owned.size() > 3 or result.stamps + result.owned.size() > result.last_award_day or result.protected_claims.size() > (3 if result.tuning == "precision" else 2) or result.rescue_claims.size() > worker_count or (not result.equipped.is_empty() and result.equipped not in result.owned):
		return null
	if result.protected_claims.size() > result.uses or (not result.protected_claims.is_empty() and result.equipped != "shell_guard") or (not result.bell_lanes.is_empty() and (result.equipped != "relay_bell" or result.tuning != "standard")) or (result.uses > 0 and result.equipped not in ["shell_guard", "team_kettle"] and not (result.equipped == "relay_bell" and result.tuning in ["sprint", "handoff"])):
		return null
	if result.tuning != "standard" and (not TOOLS.has(result.equipped) or not result.tuning_unlocked(result.equipped, result.tuning, day)):
		return null
	for id in result.mastered_tools:
		if id not in result.owned or result.last_award_day < int(TOOLS[id].day):
			return null
	for id in result.owned:
		if day < int(TOOLS[id].day):
			return null
	return result
