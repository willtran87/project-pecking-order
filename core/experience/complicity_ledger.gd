class_name ComplicityLedger
extends RefCounted

## The campaign's moral ledger: every filed choice where the company's interest
## and the flock's interest pulled apart, sorted into whose side it took.
##
## The ledger is derived, never saved. DepartmentSimulation gathers "acts" from
## records it already persists (incident responses, closing credit memos, flock
## petitions, the restructuring dossier) and this module classifies and totals
## them, so old saves gain a complete ledger with no schema change.

const SIDE_COMPANY := &"company"
const SIDE_FLOCK := &"flock"
const SIDE_NEUTRAL := &"neutral"

## How far one side must lead before the file reads as a settled direction.
const LEAN_MARGIN := 2

const INCIDENT_TONE_SIDES := {
	&"danger": SIDE_COMPANY,
	&"pressure": SIDE_COMPANY,
	&"care": SIDE_FLOCK,
	&"quality": SIDE_NEUTRAL,
}
const CREDIT_STYLE_SIDES := {
	&"management_innovation": SIDE_COMPANY,
	&"shared_scoop": SIDE_FLOCK,
	&"individual_merit": SIDE_NEUTRAL,
}
const PETITION_RESPONSE_SIDES := {
	&"deny_and_monitor": SIDE_COMPANY,
	&"sign_compact": SIDE_FLOCK,
	&"offer_concession": SIDE_NEUTRAL,
}
const RESTRUCTURING_SIDES := {
	&"nominate_variance": SIDE_COMPANY,
	&"contest_ranking": SIDE_FLOCK,
	&"fund_redeployment": SIDE_NEUTRAL,
}
const SIDE_LABELS := {
	SIDE_COMPANY: "FOR THE COMPANY",
	SIDE_FLOCK: "FOR THE FLOCK",
	SIDE_NEUTRAL: "BY THE BOOK",
}

const VERDICTS := {
	&"unfiled": {
		"title": "NO FILE YET",
		"verdict": "Nothing has asked you to choose between the farmer and the flock. Yet.",
	},
	&"company_bird": {
		"title": "COMPANY BIRD",
		"verdict": "Whenever a choice cost something, you made sure it cost a hen. The farmer has noticed. So has the flock.",
	},
	&"flock_first": {
		"title": "FLOCK FIRST",
		"verdict": "You kept spending your own standing to cover the birds beside you. It shows in the ledger, and in the quota you inherited.",
	},
	&"both_ledgers": {
		"title": "BOTH LEDGERS",
		"verdict": "You protected hens when it was cheap and spent them when it was not. Most roosters call this pragmatism.",
	},
}


static func incident_side(tone: StringName) -> StringName:
	return INCIDENT_TONE_SIDES.get(tone, SIDE_NEUTRAL)


static func credit_style_side(style_id: StringName) -> StringName:
	return CREDIT_STYLE_SIDES.get(style_id, SIDE_NEUTRAL)


static func petition_side(response_id: StringName) -> StringName:
	return PETITION_RESPONSE_SIDES.get(response_id, SIDE_NEUTRAL)


static func restructuring_side(option_id: StringName) -> StringName:
	return RESTRUCTURING_SIDES.get(option_id, SIDE_NEUTRAL)


## One short line naming who pays for an incident response, shown on the
## choice card before the player commits. Empty for neutral responses.
static func witness_stake(tone: StringName, worker_name: String) -> String:
	if worker_name.is_empty():
		return ""
	match incident_side(tone):
		SIDE_COMPANY:
			return "%s PAYS FOR THIS" % worker_name.to_upper()
		SIDE_FLOCK:
			return "COVERS FOR %s" % worker_name.to_upper()
	return ""


## acts: [{source, label, side, weight?, day?}] -> totals, verdict and receipts.
static func compose(acts: Array[Dictionary]) -> Dictionary:
	var company := 0
	var flock := 0
	var neutral := 0
	var receipts: Array[Dictionary] = []
	for act in acts:
		var side := StringName(act.get("side", SIDE_NEUTRAL))
		var weight := maxi(1, int(act.get("weight", 1)))
		match side:
			SIDE_COMPANY:
				company += weight
			SIDE_FLOCK:
				flock += weight
			_:
				side = SIDE_NEUTRAL
				neutral += weight
		receipts.append({
			"day": int(act.get("day", 0)),
			"source": String(act.get("source", "")),
			"label": String(act.get("label", "")),
			"side": side,
			"side_label": SIDE_LABELS[side],
			"weight": weight,
		})
	var verdict_id: StringName = &"unfiled"
	if company + flock > 0:
		if company >= flock + LEAN_MARGIN:
			verdict_id = &"company_bird"
		elif flock >= company + LEAN_MARGIN:
			verdict_id = &"flock_first"
		else:
			verdict_id = &"both_ledgers"
	var verdict := VERDICTS[verdict_id] as Dictionary
	return {
		"id": verdict_id,
		"title": String(verdict["title"]),
		"verdict": String(verdict["verdict"]),
		"company": company,
		"flock": flock,
		"neutral": neutral,
		"total": company + flock + neutral,
		"summary": "%d FOR THE COMPANY  ·  %d FOR THE FLOCK" % [company, flock],
		"receipts": receipts,
	}
