class_name FlockRelationships
extends RefCounted

## Durable pair history. Presentation never awards relationship progress.
const EVENTS := {
	"shared_shift": {"delta": 4, "text": "Both delivered clean eggs"},
	"shared_credit": {"delta": 6, "text": "Shared the credit"},
	"quota_comparison": {"delta": -10, "text": "Quota pressure turned work into a contest"},
	"team_lift": {"delta": 8, "text": "Looked out for each other with Team Lift"},
	"relay_care": {"delta": 5, "text": "Helped each other through a kettle relay"},
	"shared_break": {"delta": 8, "text": "Made time for a shared break"},
	"clear_air": {"delta": 14, "text": "Talked honestly and cleared the air"},
	"friendly_contest": {"delta": 0, "text": "Chose a friendly contest: one clean egg each"},
	"friend_reward": {"delta": 0, "text": "Earned a clean-pair reward together"},
	"inseparable_reward": {"delta": 0, "text": "Earned an inseparable clean-pair reward together"},
	"contest_reward": {"delta": 6, "text": "Both delivered: competition became mutual respect"},
}
var pairs: Dictionary = {}
var daily_day := 0
var daily_counts: Dictionary = {}
var clean_workers: Array[int] = []

static func key(a: int, b: int) -> String:
	return "%d:%d" % [mini(a, b), maxi(a, b)]

func begin_day(day: int) -> void:
	if day != daily_day:
		daily_day = day
		daily_counts.clear()
		clean_workers.clear()

func record(a: int, b: int, kind: String, day: int) -> bool:
	if a < 0 or b < 0 or a == b or not EVENTS.has(kind):
		return false
	begin_day(day)
	var pair_key := key(a, b)
	var event_key := pair_key + ":" + kind
	if daily_counts.has(event_key):
		return false
	daily_counts[event_key] = 1
	var row := pairs.get(pair_key, {"affinity": 0, "was_rivals": false, "friend_day": 0, "memories": []}) as Dictionary
	row.affinity = clampi(int(row.affinity) + int(EVENTS[kind].delta), -50, 50)
	row.was_rivals = bool(row.was_rivals) or int(row.affinity) <= -14
	if int(row.affinity) >= 18 and int(row.friend_day) == 0:
		row.friend_day = day
	(row.memories as Array).append({"kind": kind, "day": day, "actor": a})
	if row.memories.size() > 3:
		(row.memories as Array).pop_front()
	pairs[pair_key] = row
	return true

func record_clean(a: int, b: int, day: int) -> void:
	begin_day(day)
	if a not in clean_workers:
		clean_workers.append(a)
	if b in clean_workers:
		record(a, b, "shared_shift", day)

func affinity(a: int, b: int) -> int:
	return int((pairs.get(key(a, b), {}) as Dictionary).get("affinity", 0))

func happened(a: int, b: int, kind: String) -> bool:
	return daily_counts.has(key(a, b) + ":" + kind)

func pair_reward(a: int, b: int) -> Dictionary:
	var contest := happened(a, b, "friendly_contest")
	var score := affinity(a, b)
	var earned := happened(a, b, "friend_reward") or happened(a, b, "inseparable_reward") or happened(a, b, "contest_reward")
	var progress := int(a in clean_workers) + int(b in clean_workers)
	var xp := 6 if contest else 4 if score >= 36 else 2 if score >= 18 else 0
	var relief := 0 if contest else 5 if score >= 36 else 3 if score >= 18 else 0
	if happened(a, b, "friend_reward"):
		xp = 2
		relief = 3
	elif happened(a, b, "inseparable_reward"):
		xp = 4
		relief = 5
	return {"eligible": xp > 0, "earned": earned, "progress": progress, "xp": xp, "relief": relief, "contest": contest}

func snapshot(a: int, b: int) -> Dictionary:
	var row := pairs.get(key(a, b), {}) as Dictionary
	var score := affinity(a, b)
	var reconciled := bool(row.get("was_rivals", false)) and score >= 0
	var tier := "inseparable" if score >= 36 else "friends" if score >= 18 else "rivals" if score <= -14 else "strained" if score < 0 else "mending" if reconciled else "familiar"
	var memories: Array[Dictionary] = []
	for value in row.get("memories", []):
		var memory := value as Dictionary
		memories.append({"day": memory.day, "text": String(EVENTS[memory.kind].text), "kind": memory.kind, "actor": memory.actor})
	var goal := "%d warmth to friendship. Share clean shifts, credit, or a break." % maxi(0, 18 - score)
	if score >= 36:
		goal = "A lasting bond. Keep sharing successes and protecting each other's breaks."
	elif score >= 18:
		goal = "%d warmth to inseparable: clean-pair rewards grow to +4 XP / -5 stress each." % (36 - score)
	elif score < 0:
		goal = "Clear the air to repair trust; shared credit and teamwork help it last."
	var reward := pair_reward(a, b)
	var benefit := "At 18 warmth: one clean egg each earns +2 XP / -3 stress each, once per pair per shift."
	if score >= 18:
		benefit = "CLEAN PAIR: +%d XP / -%d stress each. One clean egg each, once per shift. Team Lift also adds +2 morale / -2 stress." % [reward.xp, reward.relief]
	elif score < 0:
		benefit = "Repair trust for lasting teamwork, or start a friendly contest: +6 XP each and +6 warmth if both deliver clean eggs. Starting adds +3 stress each."
	if bool(reward.contest):
		benefit = "FRIENDLY CONTEST: one clean egg each this shift earns +6 XP each and +6 warmth. No extra penalty if unfinished."
		goal = "Keep both hens working. Cracked eggs do not count; try another file before 5 PM." if not reward.earned else "Shared success builds respect. Keep sharing clean shifts and credit."
	var status := "PAIR REWARD EARNED · BOTH HENS BENEFIT" if reward.earned else "%d / 2 HENS DELIVERED CLEAN · %s" % [reward.progress, "REWARD AUTOMATIC" if reward.eligible else "BUILD FRIENDSHIP TO UNLOCK"]
	return {"partner_id": b, "affinity": score, "tier": tier, "label": tier.to_upper(), "reconciled": reconciled, "friend_day": int(row.get("friend_day", 0)), "memories": memories, "goal": goal, "benefit": benefit, "reward": reward, "reward_status": status}

func to_save_data() -> Dictionary:
	return {"pairs": pairs.duplicate(true), "daily_day": daily_day, "daily_counts": daily_counts.duplicate(), "clean_workers": clean_workers.duplicate()}

static func _integer(value: Variant, low: int, high: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == floorf(float(value)) and float(value) >= low and float(value) <= high

static func from_save_data(value: Variant, day: int, worker_count: int) -> FlockRelationships:
	var result := FlockRelationships.new()
	if value == null:
		return result
	if not value is Dictionary:
		return null
	if not _integer(value.get("daily_day"), 0, day) or not value.get("pairs") is Dictionary or not value.get("daily_counts") is Dictionary or not value.get("clean_workers") is Array:
		return null
	var valid_keys: Array[String] = []
	for a in worker_count:
		for b in range(a + 1, worker_count):
			valid_keys.append(key(a, b))
	if value.pairs.size() > valid_keys.size() or value.daily_counts.size() > valid_keys.size() * EVENTS.size() or value.clean_workers.size() > worker_count:
		return null
	for pair_key in value.pairs:
		var row: Variant = value.pairs[pair_key]
		if pair_key not in valid_keys or not row is Dictionary:
			return null
		if not _integer(row.get("affinity"), -50, 50) or typeof(row.get("was_rivals")) != TYPE_BOOL or not _integer(row.get("friend_day"), 0, day) or not row.get("memories") is Array or row.memories.size() > 3:
			return null
		var participants := String(pair_key).split(":")
		for memory in row.memories:
			if not memory is Dictionary or not EVENTS.has(memory.get("kind")) or not _integer(memory.get("day"), 1, day) or not _integer(memory.get("actor"), 0, worker_count - 1) or str(int(memory.actor)) not in participants:
				return null
		result.pairs[pair_key] = row.duplicate(true)
	for event_key in value.daily_counts:
		var parts := String(event_key).split(":")
		if parts.size() != 3 or (parts[0] + ":" + parts[1]) not in valid_keys or not EVENTS.has(parts[2]) or not _integer(value.daily_counts[event_key], 1, 1):
			return null
	for id in value.clean_workers:
		if not _integer(id, 0, worker_count - 1) or int(id) in result.clean_workers:
			return null
		result.clean_workers.append(int(id))
	result.daily_day = int(value.daily_day)
	result.daily_counts = value.daily_counts.duplicate()
	result.begin_day(day)
	return result
