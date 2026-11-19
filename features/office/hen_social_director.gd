class_name HenSocialDirector
extends RefCounted

const Voices := preload("res://features/chickens/hen_personality.gd")
const LENGTH := 8.0
const REPLY_AT := 3.8
var current: Dictionary = {}
var elapsed := 0.0
var serial := 0
var cooldown := 7.0
var _time := 0.0
var _day := -1
var _cursor := 0
var _previous: Dictionary = {}
var _pending: Array[Dictionary] = []
var _comfort_until: Dictionary = {}
var _reward_keys: Array[String] = []
var _shared_moment: Dictionary = {}

func observe(snapshot: Dictionary) -> void:
	var day := int(snapshot.get("day", 1))
	if day != _day:
		_day = day
		_previous.clear()
		_pending.clear()
		_comfort_until.clear()
		_reward_keys.clear()
		_shared_moment.clear()
		current.clear()
		cooldown = 7.0
	for value in snapshot.get("workers", []):
		var worker := value as Dictionary
		var id := int(worker.id)
		if bool(worker.get("employed", false)) and _previous.has(id):
			var old := _previous[id] as Dictionary
			if int(worker.get("career_level", 0)) > int(old.level):
				celebrate(id, "career:%d:%d" % [id, int(worker.get("career_level", 0))])
		_previous[id] = {"eggs": worker.get("eggs_laid", 0), "level": worker.get("career_level", 0)}

func celebrate(id: int, event_key: String) -> bool:
	if event_key in _reward_keys:
		return false
	_reward_keys.append(event_key)
	if _reward_keys.size() > 32:
		_reward_keys.pop_front()
	# Coalesce successes while a hen is laying/celebrating, without stale applause.
	for event in _pending:
		if int(event.id) == id:
			return false
	_pending.append({"id": id, "expires": _time + 40.0})
	if _pending.size() > 6:
		_pending.pop_front()
	return true

func reflect_pair(a: int, b: int, reward: Dictionary = {}) -> void:
	# Simultaneous pair completions coalesce into one exchange. Keep the
	# player's chosen contest ahead of an incidental friendship reward.
	var pending_reward := _shared_moment.get("reward", {}) as Dictionary
	if reward.is_empty() and not pending_reward.is_empty() and int(_shared_moment.a) in [a, b] and int(_shared_moment.b) in [a, b]:
		return
	if not reward.is_empty() and bool(pending_reward.get("contest", false)) and not bool(reward.get("contest", false)):
		return
	# A real shared moment gets a nearby follow-up after management closes.
	# Discard an old argument between this pair rather than resuming it repaired.
	if not current.is_empty() and int(current.first_id) in [a, b] and int(current.second_id) in [a, b]:
		current.clear()
	_shared_moment = {"a": a, "b": b, "expires": _time + 40.0, "reward": reward.duplicate()}
	cooldown = minf(cooldown, 1.5)

func advance(delta: float, eligible: Array[Dictionary], can_start: bool = true) -> void:
	_time += delta
	if not current.is_empty():
		if _find(eligible, int(current.first_id)).is_empty() or _find(eligible, int(current.second_id)).is_empty():
			current.clear()
			cooldown = 8.0
			return
		elapsed += delta
		if elapsed >= LENGTH:
			current.clear()
			cooldown = 18.0
		return
	if not can_start:
		return
	# An exchange may continue through a routine lay/reward animation, which
	# still owns the hen's body. Start new chat only when both hens are free.
	eligible = eligible.filter(func(worker: Dictionary) -> bool: return bool(worker.get("ready", true)))
	cooldown = maxf(0.0, cooldown - delta)
	if cooldown > 0.0 or eligible.size() < 2:
		return
	if not _shared_moment.is_empty():
		var a := _find(eligible, int(_shared_moment.a))
		var b := _find(eligible, int(_shared_moment.b))
		if float(_shared_moment.expires) < _time:
			_shared_moment.clear()
		elif not a.is_empty() and not b.is_empty() and (a.position as Vector3).distance_to(b.position) <= 6.5:
			current = Voices.exchange(&"chat", a, b, serial / 2)
			var reward := _shared_moment.get("reward", {}) as Dictionary
			if not reward.is_empty():
				current.kind = &"celebrate"
				current.relationship_label = String(reward.label)
				current.opening = "Two clean eggs! We both earned %d XP." % int(reward.xp)
				current.reply = "Good contest. Let's share the credit. +6 warmth!" if bool(reward.contest) else "Better together. And %d less stress each!" % int(reward.relief)
			serial += 1
			elapsed = 0.0
			_shared_moment.clear()
			return
	var subject: Dictionary = {}
	var kind: StringName = &"chat"
	for index in range(_pending.size() - 1, -1, -1):
		var event := _pending[index]
		if float(event.expires) < _time:
			_pending.remove_at(index)
			continue
		subject = _find(eligible, int(event.id))
		if not subject.is_empty():
			_pending.remove_at(index)
			kind = &"celebrate"
			break
	if subject.is_empty():
		for worker in eligible:
			if float(worker.get("stress", 0.0)) >= 65.0 and float(_comfort_until.get(worker.id, 0.0)) <= _time:
				subject = worker
				kind = &"comfort"
				break
	if subject.is_empty():
		subject = eligible[posmod(_cursor, eligible.size())]
		_cursor += 1
	var partner := _partner(eligible, subject)
	if partner.is_empty():
		cooldown = 3.0
		return
	if kind == &"comfort":
		_comfort_until[subject.id] = _time + 90.0
	# Support/praise is directed toward the hen whose real state caused it.
	current = Voices.exchange(kind, subject if kind == &"chat" else partner, partner if kind == &"chat" else subject, serial / 2)
	serial += 1
	elapsed = 0.0

func _find(workers: Array[Dictionary], id: int) -> Dictionary:
	for worker in workers:
		if int(worker.id) == id:
			return worker
	return {}

func _partner(workers: Array[Dictionary], subject: Dictionary) -> Dictionary:
	var nearest: Dictionary = {}
	var best_score := -100.0
	for candidate in workers:
		if int(candidate.id) == int(subject.id):
			continue
		var d: float = (candidate.position as Vector3).distance_to(subject.position)
		if d > 6.5:
			continue
		if int(candidate.id) == int(subject.get("partner_id", -1)):
			return candidate
		var history_score := 0.0
		for relationship in subject.get("relationships", []):
			if int(relationship.get("partner_id", -1)) == int(candidate.id):
				history_score = absf(float(relationship.get("affinity", 0))) * 0.08
		var score := history_score - d
		if score > best_score:
			nearest = candidate
			best_score = score
	return nearest

func snapshot() -> Dictionary:
	return {"current": current.duplicate(), "elapsed": snappedf(elapsed, 0.01), "serial": serial, "replying": elapsed >= REPLY_AT, "pending": _pending.size()}
