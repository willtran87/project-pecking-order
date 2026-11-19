class_name HenPersonality
extends RefCounted

## Voices follow the existing six temperaments. No second personality/save economy.
const TITLES := ["EAGER OPTIMIST", "DRY WIT", "COZY CARETAKER", "OFFICE GOSSIP", "PERFECTIONIST", "QUIET REBEL"]
const COLORS := [Color("eac76d"), Color("8ac4dd"), Color("edb69c"), Color("cea9e5"), Color("9fc9b6"), Color("b6cc80")]
const CHAT := [
	["What if we finish early?", "I color-coded my ambitions.", "This could be our best clutch yet!"],
	["The stapler and I have an understanding.", "My inbox has started nesting.", "Another meeting could have been a cluck."],
	["I saved the warm perch for you.", "Anyone need a biscuit after this?", "A tidy nest, a cup of tea. Bliss."],
	["Apparently the copier is getting promoted.", "Guess who called a meeting about meetings?", "I heard the good seed is back."],
	["My checklist has a checklist.", "Those tabs are in alphabetical order.", "I counted twice. Then once for luck."],
	["I filed that memo under 'maybe'.", "We should unionize the staplers.", "Our break is not a rounding error."],
]
const REPLIES := [
	["I knew this team had potential!", "I'm putting that on my goal list."],
	["I'll pretend I didn't enjoy that.", "Noted. In pencil."],
	["I'll put the kettle on.", "There's room on my perch."],
	["Oh, the break room needs to hear this.", "You didn't hear it from me."],
	["I'll need that in triplicate.", "That is technically correct."],
	["Finally, a sensible office policy.", "Solidarity. And snacks."],
]
const PRAISE := ["That was brilliant!", "Clean work. No notes.", "You earned a biscuit for that.", "Everyone, did you see that?", "Flawless. I checked.", "Your work. Your credit."]
const THANKS := ["We make a pretty good flock!", "I may allow myself a small smile.", "Better when we share the good bits.", "Tell the others I was very modest.", "A satisfying result, precisely.", "Couldn't do it without the flock."]
const SUPPORT := ["One file at a time. You've got this.", "Breathe. The paperwork can wait.", "Save a little energy for yourself.", "You can vent to me after this.", "One breath. Then one small step.", "You're a hen, not a quota."]
const ACCEPT := ["Right. Small steps. I can do that.", "Thanks. Quietly appreciated.", "A little kindness goes a long way.", "I needed a friendly cluck.", "Adding 'breathe' to the checklist.", "Thanks for looking out for me."]
const FRIEND_CHAT := ["Remember our first clean shift together?", "I saved you the good pen. Don't tell.", "Same perch for our next tea break?", "You get the gossip before anyone else.", "Your tabs and mine make a perfect system.", "If they rush you, they answer to us both."]
const FRIEND_REPLY := ["Best work friend. Officially!", "I have grown annoyingly fond of you.", "Always room beside me.", "Now that's a story worth sharing.", "A reliable partnership. My favorite kind.", "Whatever the quota says, we're a team."]
const RIVAL_CHAT := ["I wish they'd stop comparing our clutches.", "Apparently we're keeping score now.", "I miss when this perch felt friendly.", "They called us rivals. Did you hear?", "Your total is one ahead. I noticed.", "Their quota shouldn't put us at odds."]
const RIVAL_REPLY := ["I just wanted us both to do well.", "I'd rather share a break than a scoreboard.", "Maybe we should talk over tea.", "Let's give them a better story.", "Fair credit would be a useful start.", "We can choose to stop this contest."]
const MENDING_CHAT := ["Fresh start? I think we can do this.", "I've retired the imaginary scoreboard.", "I'm glad we talked. Tea's on me.", "New office story: we're talking again.", "A fresh page. No old tallies.", "We don't have to be their competition."]
const MENDING_REPLY := ["One shared shift at a time!", "Truce. You may borrow the good pen.", "There's room beside me again.", "That's the version I'll tell everyone.", "Agreed. Let's make the next handoff count.", "Us against the paperwork. Deal."]

static func title(id: int) -> String:
	return TITLES[posmod(id, 6)]

static func exchange(kind: StringName, first: Dictionary, second: Dictionary, variant: int) -> Dictionary:
	var a := posmod(int(first.id), 6)
	var b := posmod(int(second.id), 6)
	var opening := String(CHAT[a][posmod(variant, 3)])
	var reply := String(REPLIES[b][posmod(variant, 2)])
	if kind == &"celebrate":
		opening = PRAISE[a]
		reply = THANKS[b]
	elif kind == &"comfort":
		opening = SUPPORT[a]
		reply = ACCEPT[b]
	var relationship: Dictionary = {}
	for row in first.get("relationships", []):
		if int(row.get("partner_id", -1)) == int(second.id):
			relationship = row
			break
	var tier := String(relationship.get("tier", "familiar"))
	if tier in ["friends", "inseparable"]:
		if kind == &"chat":
			opening = FRIEND_CHAT[a]
		reply = FRIEND_REPLY[b]
	elif tier in ["rivals", "strained"]:
		opening = RIVAL_CHAT[a] if kind == &"chat" else "We're competing, but that was good work." if kind == &"celebrate" else "Even rivals need a breather."
		reply = RIVAL_REPLY[b]
	elif tier == "mending":
		opening = MENDING_CHAT[a]
		reply = MENDING_REPLY[b]
	var reward := relationship.get("reward", {}) as Dictionary
	if kind == &"chat" and bool(reward.get("contest", false)) and not bool(reward.get("earned", false)):
		opening = "One clean egg each. Let's make this a fair contest."
		reply = "Deal. We both win if we finish clean."
	return {"kind": kind, "first_id": int(first.id), "second_id": int(second.id), "first_name": String(first.name), "second_name": String(second.name), "opening": opening, "reply": reply, "relationship_label": String(relationship.get("label", "")) if tier != "familiar" else ""}
