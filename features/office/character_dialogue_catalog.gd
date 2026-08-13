class_name CharacterDialogueCatalog
extends RefCounted

const DialogueLibrary := preload("res://features/office/character_dialogue_library.gd")

## Human-scale satire projected from the authoritative office state.
##
## These lines never mutate the economy and never invent a second welfare
## system. They translate existing decisions, stress, grievance, fatigue, and
## management density into one short character beat while the exact filing
## remains available in Flockwatch.

const SPEAKERS := DialogueLibrary.SPEAKERS
const EGG_CONVERSATION_MILESTONES: Array[int] = [2, 5, 9, 13]
const MAX_SNAPSHOT_BEATS := 2


static func beat_for_internship_action(result: Dictionary) -> Dictionary:
	if not bool(result.get("accepted", false)):
		return {}
	var candidate_id := StringName(String(result.get("candidate_id", "")))
	if candidate_id.is_empty():
		return {}
	var speaker_id := DialogueLibrary.intern_speaker(candidate_id)
	var action_id := StringName(String(result.get("action_id", "")))
	var theme_id := &"onboard"
	match action_id:
		&"intern_assignment":
			theme_id = StringName(String(result.get("assignment_id", "guided_shadow")))
		&"intern_review":
			theme_id = StringName(String(result.get("resolution_id", "growth_extension")))
		&"intern_term_complete":
			theme_id = &"term_complete"
		&"intern_onboard":
			theme_id = &"onboard"
		_:
			return {}
	var day := maxi(1, int(result.get("day", 1)))
	return _voice_entry(
		"internship_%d_%s_%s_%s" % [
			day,
			String(candidate_id),
			String(action_id),
			String(theme_id),
		],
		speaker_id,
		theme_id,
		"%d|%s|%s|%d" % [
			day,
			String(candidate_id),
			String(theme_id),
			int(result.get("cost_cents", 0)),
		],
		13.0,
	)


static func beats_for_internship_transitions(report: Dictionary) -> Array[Dictionary]:
	var beats: Array[Dictionary] = []
	for transition_value in report.get("internship_transitions", []):
		if not transition_value is Dictionary:
			continue
		var beat := beat_for_internship_action(transition_value as Dictionary)
		if not beat.is_empty():
			beats.append(beat)
	return beats


static func opening_beat(day: int = 1) -> Dictionary:
	return _entry(
		"opening_mabel_%d" % day,
		&"mabel",
		"They called this an entry-level perch. The quota arrived with seniority.",
		&"PRIVATE ASIDE",
		10.0,
	)


static func return_beat(
	return_recap: Dictionary,
	offline_recap: Dictionary,
	day: int,
) -> Dictionary:
	## Re-entry should return the player to the flock, not merely to a ledger.
	## The exact condition remains in the saved-file recap and Flockwatch; this
	## beat translates that same authoritative state into one human consequence.
	if return_recap.is_empty() and offline_recap.is_empty():
		return {}
	var status_label := String(
		return_recap.get("status_label", "CURRENT COOP FILE")
	).strip_edges().to_upper()
	var last_filed := String(
		return_recap.get("last_filed_label", "CURRENT CHECKPOINT")
	).strip_edges().to_upper()
	var entry_id := "return_%d_%s_%s" % [
		maxi(1, day),
		last_filed,
		status_label,
	]
	if bool(offline_recap.get("clock_anomaly", false)):
		return _entry(
			entry_id,
			&"cornelius",
			"The wall clock moved backward. Finance found no billable minutes, so the flock is exactly where we left it.",
			&"MANAGEMENT ASIDE",
			10.0,
		)
	match status_label:
		"FEED COVERAGE":
			return _entry(
				entry_id,
				&"henrietta",
				"Nothing moved while we were away. The ration gap waited at its desk and was marked present.",
				&"FLOOR CHAT",
				10.0,
			)
		"LIVE-FILE CAPACITY", "ARCHIVE CAPACITY", "WORKFLOW DEBT":
			return _entry(
				entry_id,
				&"dot",
				"The files waited exactly where we left them. Management has praised the backlog for its retention.",
				&"BREAK-ROOM WHISPER",
				10.0,
			)
		"FLOCK WELFARE":
			return _entry(
				entry_id,
				&"pip",
				"Nobody got more tired while the terminal was closed. Management has filed this as a successful wellness program.",
				&"PRIVATE ASIDE",
				10.0,
			)
		"SECURED MARGIN":
			return _entry(
				entry_id,
				&"cornelius",
				"No costs posted while we were away. Finance has asked whether absence can be scaled.",
				&"MANAGEMENT ASIDE",
				10.0,
			)
		"MUTUAL REACH":
			return _entry(
				entry_id,
				&"mabel",
				"No claimants were served while the office slept. The farmer's slide will call that disciplined demand.",
				&"PRIVATE ASIDE",
				10.0,
			)
	return _entry(
		entry_id,
		&"mabel",
		"The coop stayed paused while we were gone. The quota was kind enough to wait without getting smaller.",
		&"PRIVATE ASIDE",
		10.0,
	)


static func beats_for_snapshot(previous: Dictionary, current: Dictionary) -> Array[Dictionary]:
	var beats: Array[Dictionary] = []
	if previous.is_empty() or current.is_empty():
		return beats
	var day := int(current.get("day", 1))

	var previous_operations := previous.get("operations", {}) as Dictionary
	var current_operations := current.get("operations", {}) as Dictionary
	var previous_manager_roster := previous_operations.get("manager_roster", []) as Array
	var current_manager_roster := current_operations.get("manager_roster", []) as Array
	var previous_manager_ids := _manager_candidate_ids(previous_manager_roster)
	var current_manager_ids := _manager_candidate_ids(current_manager_roster)
	if current_manager_ids != previous_manager_ids:
		var changed_candidate := _changed_manager_candidate(
			previous_manager_ids,
			current_manager_ids,
		)
		if not changed_candidate.is_empty():
			var manager_speaker := DialogueLibrary.manager_speaker(changed_candidate)
			beats.append(_voice_entry(
				"management_roster_%d_%s_%d" % [
					day,
					String(changed_candidate),
					current_manager_ids.size(),
				],
				manager_speaker,
				&"appointment",
				"%d|%s|%s" % [
					day,
					_manager_id_key(previous_manager_ids),
					_manager_id_key(current_manager_ids),
				],
				11.5,
			))

	var previous_workers := _workers_by_id(previous)
	var worker_transition := _first_worker_transition_beat(
		previous_workers,
		current.get("workers", []) as Array,
		day,
	)
	if not worker_transition.is_empty():
		beats.append(worker_transition)

	var promotion_beat := _first_promotion_beat(
		previous_workers,
		current.get("workers", []) as Array,
		day,
	)
	if not promotion_beat.is_empty():
		beats.append(promotion_beat)

	if (
		not bool(previous.get("overtime_enabled", false))
		and bool(current.get("overtime_enabled", false))
	):
		beats.append(_entry(
			"overtime_%d" % day,
			&"henrietta",
			"After-hours pecking is voluntary. So is keeping your name off the attitude report.",
			&"FLOOR CHAT",
			10.0,
		))

	if (
		not bool(previous.get("feed_party_used_today", false))
		and bool(current.get("feed_party_used_today", false))
	):
		beats.append(_entry(
			"feed_party_%d" % day,
			&"dot",
			"The invitation says the feed is gratitude. Payroll says it is not compensation.",
			&"BREAK-ROOM WHISPER",
			9.0,
		))

	var previous_eggs := int(previous.get("eggs_today", 0))
	var current_eggs := int(current.get("eggs_today", 0))
	if (
		previous_eggs == 0
		and current_eggs > 0
		and not bool(current.get("first_clutch_tracking", false))
	):
		var first_egg_beat := _entry(
			"first_egg_%d" % day,
			&"mabel",
			"Clean shell. Farmer credit is on the way.",
			&"FLOOR CHAT",
			6.0,
		)
		first_egg_beat["presentation_mode"] = &"ambient"
		beats.append(first_egg_beat)
	else:
		var production_beat := _production_milestone_beat(
			previous_eggs,
			current_eggs,
			current.get("workers", []) as Array,
			day,
		)
		if not production_beat.is_empty():
			beats.append(production_beat)

	if (
		int(previous.get("cracked_today", 0)) == 0
		and int(current.get("cracked_today", 0)) > 0
	):
		beats.append(_entry(
			"first_crack_%d" % day,
			&"henrietta",
			"The shell cracked after grading. My performance record cracked before it.",
			&"FLOOR CHAT",
			9.0,
		))

	if (
		int(previous.get("wage_arrears_cents", 0)) == 0
		and int(current.get("wage_arrears_cents", 0)) > 0
	):
		beats.append(_entry(
			"wage_arrears_%d" % day,
			&"pip",
			"The ledger calls it deferred compensation. My grocer continues to call it missing.",
			&"PRIVATE ASIDE",
			11.0,
		))

	var strain_beat := _first_strain_threshold_beat(previous, current, day)
	if not strain_beat.is_empty():
		beats.append(strain_beat)
	if beats.size() > MAX_SNAPSHOT_BEATS:
		beats.resize(MAX_SNAPSHOT_BEATS)
	return beats


static func beat_for_decision_result(result: Dictionary, day: int) -> Dictionary:
	if result.is_empty():
		return {}
	var character_arc := result.get("character_arc", {}) as Dictionary
	if not character_arc.is_empty():
		var speaker_id := StringName(character_arc.get("speaker_id", &"mabel"))
		var tone := StringName(character_arc.get("tone", &""))
		var option_label := String(character_arc.get("option_label", "THAT RESPONSE")).to_lower()
		var supportive := tone in [&"care", &"quality"]
		var standing := StringName(character_arc.get("standing_after", character_arc.get("standing", &"forming")))
		var line := "That was my file. You chose %s. I won't forget." % option_label
		if supportive:
			line = "That was my file. You chose %s. You remembered me." % option_label
		elif standing == &"breaking":
			line = "That was my file. You chose %s. I am done calling this temporary." % option_label
		elif standing == &"ally":
			line = "That was my file. You chose %s. I trusted you; now I need a reason to keep doing that." % option_label
		return _entry(
			"incident_witness_%d_%s_%d" % [
				day,
				String(character_arc.get("pair_id", "case")),
				int(character_arc.get("beat", 1)),
			],
			speaker_id,
			line,
			_default_channel(speaker_id),
			10.0,
		)
	var option_id := StringName(String(result.get(
		"option_id",
		result.get("choice_id", result.get("response_id", "")),
	)))
	match option_id:
		&"peckwork_tools":
			return _entry(
				"first_clutch_keycaps_%d" % day,
				&"mabel",
				"They bought my beak nicer keys with the money my beak earned. Procurement has called this a shared win.",
				&"PRIVATE ASIDE",
			)
		&"shell_lamp":
			return _entry(
				"first_clutch_lamp_%d" % day,
				&"mabel",
				"The new lamp checks whether my eggs can survive the pace. The pace did not receive an inspection.",
				&"PRIVATE ASIDE",
			)
		&"nest_cushion":
			return _entry(
				"first_clutch_cushion_%d" % day,
				&"mabel",
				"My egg bought the nest a cushion. The quota remains admirably committed to standing.",
				&"PRIVATE ASIDE",
			)
		&"bank_fund":
			return _entry(
				"first_clutch_banked_%d" % day,
				&"mabel",
				"My first egg went into the Feed Fund. The farmer kept the story; my desk kept the old keys.",
				&"PRIVATE ASIDE",
			)
		&"record_harvest":
			return _entry(
				"directive_harvest_%d" % day,
				&"mabel",
				"The new policy says speed is a value. I was hoping it meant a value to someone.",
				&"PRIVATE ASIDE",
			)
		&"sustainable_flock":
			return _entry(
				"directive_care_%d" % day,
				&"henrietta",
				"Management approved breathing room. Please finish breathing before the next reporting period.",
				&"FLOOR CHAT",
			)
		&"spreadsheet":
			return _entry(
				"shadow_ledger_%d" % day,
				&"pip",
				"The official system is down. Fortunately, the unofficial system has an unofficial backup.",
				&"PRIVATE ASIDE",
			)
		&"deny_breaks":
			return _entry(
				"breaks_denied_%d" % day,
				&"henrietta",
				"My wellness request was approved as an opportunity to demonstrate resilience.",
				&"PRIVATE ASIDE",
				10.0,
			)
		&"credit_roosters", &"claim_management_innovation", &"patent_rooster_method":
			return _entry(
				"management_credit_%d_%s" % [day, String(option_id)],
				&"cornelius",
				"I did not lay the egg. I did attend the meeting where we renamed it an outcome.",
				&"MANAGEMENT ASIDE",
				10.0,
			)
		&"credit_layers", &"reward_top_layer", &"name_the_layer":
			return _entry(
				"layer_credit_%d_%s" % [day, String(option_id)],
				&"dot",
				"They put a hen's name on the slide. Legal is checking whether this creates a precedent.",
				&"BREAK-ROOM WHISPER",
				10.0,
			)
		&"share_feed_credit", &"flock_owned_patent", &"contest_ranking":
			return _entry(
				"shared_credit_%d_%s" % [day, String(option_id)],
				&"mabel",
				"The filing says we did it together. That is unusually close to what happened.",
				&"PRIVATE ASIDE",
				10.0,
			)
		&"attend_status_sync":
			return _entry(
				"status_sync_%d" % day,
				&"dot",
				"The meeting about lost production ran long because production kept interrupting it.",
				&"BREAK-ROOM WHISPER",
			)
		&"cancel_status_sync":
			return _entry(
				"cancel_sync_%d" % day,
				&"cornelius",
				"I canceled a meeting. My report lists this as a completed management deliverable.",
				&"MANAGEMENT ASIDE",
			)
	var kind := StringName(String(result.get("kind", "")))
	if kind == &"incident":
		return _entry(
			"incident_closed_%d" % day,
			&"cornelius",
			"The incident is resolved. The conditions that produced it remain fully operational.",
			&"MANAGEMENT ASIDE",
			9.0,
		)
	return {}


static func shift_review_beat(report: Dictionary) -> Dictionary:
	if report.is_empty():
		return {}
	var day := int(report.get("day", 1))
	var eggs := int(report.get("eggs", report.get("eggs_laid", 0)))
	var cracked := int(report.get("cracked", report.get("cracked_eggs", 0)))
	if cracked > 0:
		return _voice_entry(
			"review_cracks_%d" % day,
			&"cornelius",
			&"review",
			"%d|%d|%d" % [day, eggs, cracked],
			12.0,
		)
	var speaker := DialogueLibrary.worker_speaker(posmod(day + eggs, 6))
	return _voice_entry(
		"review_clean_%d" % day,
		speaker,
		&"review",
		"%d|%d|clean" % [day, eggs],
		12.0,
	)


static func beat_for_market_contract_signed(result: Dictionary, day: int) -> Dictionary:
	if not bool(result.get("accepted", false)):
		return {}
	var pricing_id := StringName(String(result.get(
		"pricing_profile_id",
		&"mutual_rate",
	)))
	var offer_id := StringName(String(result.get("offer_id", &"binder")))
	match pricing_id:
		&"community_access", &"community_access_rate":
			return _entry(
				"binder_signed_%d_%s_%s" % [day, String(offer_id), String(pricing_id)],
				&"dot",
				"We lowered the rate and took more folders. The farmer calls it outreach. The flock calls it more folders.",
				&"BREAK-ROOM WHISPER",
				10.0,
			)
		&"executive_select", &"executive_select_rate":
			return _entry(
				"binder_signed_%d_%s_%s" % [day, String(offer_id), String(pricing_id)],
				&"cornelius",
				"We will serve fewer claimants at a higher rate. The deck calls the missing claimants focus.",
				&"MANAGEMENT ASIDE",
				10.0,
			)
		_:
			return _entry(
				"binder_signed_%d_%s_%s" % [day, String(offer_id), String(pricing_id)],
				&"mabel",
				"Standard rate, standard promise, non-standard number of folders.",
				&"PRIVATE ASIDE",
				9.0,
			)


static func beat_for_market_contract_result(result: Dictionary, day: int) -> Dictionary:
	if result.is_empty():
		return {}
	var status := StringName(String(result.get("status", &"")))
	var offer_id := StringName(String(result.get("offer_id", &"binder")))
	var pricing_id := StringName(String(result.get(
		"pricing_profile_id",
		&"mutual_rate",
	)))
	if status == &"fulfilled" or bool(result.get("success", false)):
		match pricing_id:
			&"community_access", &"community_access_rate":
				return _entry(
					"binder_result_%d_%s_fulfilled_%s" % [
						day,
						String(offer_id),
						String(pricing_id),
					],
					&"dot",
					"The access binder cleared. More claimants got through, and management discovered a metric for kindness.",
					&"BREAK-ROOM WHISPER",
					10.0,
				)
			&"executive_select", &"executive_select_rate":
				return _entry(
					"binder_result_%d_%s_fulfilled_%s" % [
						day,
						String(offer_id),
						String(pricing_id),
					],
					&"cornelius",
					"The select binder cleared. We improved margin by carefully selecting which problems counted.",
					&"MANAGEMENT ASIDE",
					10.0,
				)
			_:
				return _entry(
					"binder_result_%d_%s_fulfilled_%s" % [
						day,
						String(offer_id),
						String(pricing_id),
					],
					&"mabel",
					"The binder cleared. The premium has arrived before the thank-you.",
					&"PRIVATE ASIDE",
					9.0,
				)
	if status == &"breached" or result.has("breach_cents"):
		return _entry(
			"binder_result_%d_%s_breached_%s" % [
				day,
				String(offer_id),
				String(pricing_id),
			],
			&"pip",
			"The binder breached. Finance has converted the missing work into a perfectly complete invoice.",
			&"PRIVATE ASIDE",
			10.0,
		)
	return {}


static func beat_for_feed_order(result: Dictionary, day: int) -> Dictionary:
	if not bool(result.get("accepted", false)):
		return {}
	var offer_id := StringName(String(result.get("offer_id", &"")))
	match offer_id:
		&"local_whole_grain":
			return _entry(
				"feed_order_%d_%s" % [day, String(offer_id)],
				&"henrietta",
				"The grain is real. Finance has asked us not to interpret this as a precedent.",
				&"FLOOR CHAT",
				9.0,
			)
		&"inspirational_bulk_mash":
			return _entry(
				"feed_order_%d_%s" % [day, String(offer_id)],
				&"pip",
				"The mash came with a motivational slogan. The discount came with three shifts of commitment.",
				&"PRIVATE ASIDE",
				10.0,
			)
		&"fixed_future_reserve":
			return _entry(
				"feed_order_%d_%s" % [day, String(offer_id)],
				&"dot",
				"Tomorrow's feed is locked at today's price. Tomorrow's appetite remains market-rate.",
				&"BREAK-ROOM WHISPER",
				9.0,
			)
	return {}


static func beat_for_facility_purchase(result: Dictionary, day: int) -> Dictionary:
	if not bool(result.get("accepted", false)):
		return {}
	var receipt_value: Variant = result.get("commissioning_receipt", result)
	var receipt := (
		receipt_value as Dictionary
		if receipt_value is Dictionary else
		result
	)
	var facility_id := StringName(String(receipt.get(
		"facility_id",
		result.get("facility_id", &""),
	)))
	var level := int(receipt.get(
		"purchased_level",
		result.get("purchased_level", result.get("level", 1)),
	))
	var entry_id := "facility_%d_%s_l%d" % [day, String(facility_id), level]
	if facility_id in [
		&"wellness_nest_room",
		&"training_roost",
		&"flock_relations_office",
	]:
		return _entry(
			entry_id,
			&"henrietta",
			"The care room is open. Appointments remain subject to operational availability.",
			&"FLOOR CHAT",
			10.0,
		)
	if facility_id in [
		&"rooster_operations_office",
		&"it_coop",
		&"farm_mutual_negotiation_room",
	]:
		return _entry(
			entry_id,
			&"cornelius",
			"The new office is warmer on the brochure. In person it appears to be another place to explain the same quota.",
			&"MANAGEMENT ASIDE",
			10.0,
		)
	if facility_id in [
		&"farmer_brand_packing_annex",
		&"farmer_relations_gallery",
		&"records_annex",
	]:
		return _entry(
			entry_id,
			&"mabel",
			"We built a room for the work after the work. It is larger than the room where we do the work.",
			&"PRIVATE ASIDE",
			10.0,
		)
	return _entry(
		entry_id,
		&"pip",
		"The new equipment removes one bottleneck and adds a maintenance schedule. This is called capacity.",
		&"PRIVATE ASIDE",
		10.0,
	)


static func beat_for_farmgate_dispatch(result: Dictionary, day: int) -> Dictionary:
	if not bool(result.get("accepted", false)):
		return {}
	var mandate_id := StringName(String(result.get("mandate_id", &"")))
	match mandate_id:
		&"farmer_pickup":
			return _entry(
				"farmgate_%d_farmer_pickup" % day,
				&"mabel",
				"We loaded the basket. The farmer will collect the eggs, the receipt, and the active-voice version of the story.",
				&"PRIVATE ASIDE",
				11.0,
			)
		&"county_auction":
			return _entry(
				"farmgate_%d_county_auction" % day,
				&"dot",
				"The eggs are going to auction. Management calls this price discovery. The flock has already discovered the fee.",
				&"BREAK-ROOM WHISPER",
				11.0,
			)
		&"regional_showcase":
			return _entry(
				"farmgate_%d_regional_showcase" % day,
				&"cornelius",
				"The clutch is going on display. I have been asked to stand near it without implying I laid it.",
				&"MANAGEMENT ASIDE",
				11.0,
			)
		&"hold_basket":
			return _entry(
				"farmgate_%d_hold_basket" % day,
				&"pip",
				"We are holding inventory for a better price. The eggs have not been briefed on shelf life.",
				&"PRIVATE ASIDE",
				11.0,
			)
	return {}


static func beat_for_farmer_relations_campaign(result: Dictionary, day: int) -> Dictionary:
	if not bool(result.get("accepted", false)):
		return {}
	var campaign_id := StringName(String(result.get("campaign_id", &"")))
	match campaign_id:
		&"layer_profile":
			return _entry(
				"public_credit_%d_layer_profile" % day,
				&"agnes",
				"They printed a hen's name beside verified work. Legal has classified the accuracy as an experimental feature.",
				&"FILE NOTE",
				12.0,
			)
		&"clutch_results_board":
			return _entry(
				"public_credit_%d_clutch_results" % day,
				&"dot",
				"The whole flock got the byline. Management is checking whether together can be converted into a department.",
				&"BREAK-ROOM WHISPER",
				12.0,
			)
		&"farmer_method":
			return _entry(
				"public_credit_%d_farmer_method" % day,
				&"beatrice",
				"The farmer presented our eggs as his method. I suppose we are the part of the method that needs feed.",
				&"QUIET ASIDE",
				12.0,
			)
	return {}


static func beat_for_flock_relations_result(result: Dictionary, day: int) -> Dictionary:
	if not bool(result.get("accepted", false)):
		return {}
	var worker_id := int(result.get("worker_id", -1))
	var speaker := DialogueLibrary.worker_speaker(worker_id)
	var action_id := StringName(String(result.get("action_id", &"")))
	var line := ""
	match action_id:
		&"fund_remedy":
			line = "They funded the remedy. It is strange how quickly a personal concern becomes real when it has a cost center."
		&"mediate":
			line = "We mediated the concern. I was heard, summarized, and returned to the same queue with better vocabulary."
		&"file_pip":
			line = "I filed a concern. Management filed a performance concern about the way I filed it."
		&"binding_arbitration":
			line = "The decision is binding. Relief arrived with a clause asking it not to establish a pattern."
	if line.is_empty():
		return {}
	return _entry(
		"flock_relations_%d_%d_%s" % [day, int(result.get("case_id", 0)), String(action_id)],
		speaker,
		line,
		_default_channel(speaker),
		13.0,
	)


static func beat_for_manager_instruction(result: Dictionary, day: int) -> Dictionary:
	if not bool(result.get("accepted", false)):
		return {}
	var action_id := StringName(String(result.get("action_id", &"")))
	if action_id == &"manager_recruited":
		return {}
	var candidate_id := StringName(String(result.get("manager_id", &"cornelius_credit")))
	var speaker := DialogueLibrary.manager_speaker(candidate_id)
	return _voice_entry(
		"manager_instruction_%d_%s_%s" % [day, String(candidate_id), String(action_id)],
		speaker,
		&"management",
		"%d|%s|%s" % [day, String(action_id), String(result.get("choice_id", ""))],
		12.0,
	)


static func _first_strain_threshold_beat(
	previous: Dictionary,
	current: Dictionary,
	day: int,
) -> Dictionary:
	var previous_workers := _workers_by_id(previous)
	for worker_value in current.get("workers", []):
		if not worker_value is Dictionary:
			continue
		var worker := worker_value as Dictionary
		if not bool(worker.get("employed", true)):
			continue
		var worker_id := int(worker.get("id", -1))
		if worker_id < 0 or worker_id >= DialogueLibrary.WORKER_SPEAKERS.size():
			continue
		var prior := previous_workers.get(worker_id, {}) as Dictionary
		var stress := float(worker.get("stress", 0.0))
		var prior_stress := float(prior.get("stress", 0.0))
		if stress < 62.0 or prior_stress >= 62.0:
			continue
		var speaker := DialogueLibrary.worker_speaker(worker_id)
		return _voice_entry(
			"strain_%s_%d" % [String(speaker), day],
			speaker,
			&"pressure",
			"%d|%d|%d" % [day, worker_id, roundi(stress)],
			12.0,
		)
	return {}


static func _first_worker_transition_beat(
	previous_workers: Dictionary,
	current_workers: Array,
	day: int,
) -> Dictionary:
	for worker_value in current_workers:
		if not worker_value is Dictionary:
			continue
		var worker := worker_value as Dictionary
		var worker_id := int(worker.get("id", -1))
		if worker_id < 0 or worker_id >= DialogueLibrary.WORKER_SPEAKERS.size():
			continue
		var prior := previous_workers.get(worker_id, {}) as Dictionary
		var was_employed := bool(prior.get("employed", false))
		var is_employed := bool(worker.get("employed", false))
		if was_employed == is_employed:
			continue
		var speaker := DialogueLibrary.worker_speaker(worker_id)
		if is_employed:
			var hired := _voice_entry(
				"worker_hired_%d_%s" % [day, String(speaker)],
				speaker,
				&"hire",
				"%d|%d|hire" % [day, worker_id],
				13.0,
			)
			if not hired.is_empty():
				return hired
			return _entry(
				"worker_hired_%d_%s" % [day, String(speaker)],
				speaker,
				"I found the new perch. Payroll found me first.",
				_default_channel(speaker),
				12.0,
			)
		return _entry(
			"worker_released_%d_%s" % [day, String(speaker)],
			speaker,
			"My chair is now an efficiency gain. I remain available in case the gain needs training.",
			_default_channel(speaker),
			13.0,
		)
	return {}


static func _first_promotion_beat(
	previous_workers: Dictionary,
	current_workers: Array,
	day: int,
) -> Dictionary:
	for worker_value in current_workers:
		if not worker_value is Dictionary:
			continue
		var worker := worker_value as Dictionary
		if not bool(worker.get("employed", false)):
			continue
		var worker_id := int(worker.get("id", -1))
		if worker_id < 0 or worker_id >= DialogueLibrary.WORKER_SPEAKERS.size():
			continue
		var prior := previous_workers.get(worker_id, {}) as Dictionary
		var previous_level := int(prior.get("career_level", 0))
		var current_level := int(worker.get("career_level", 0))
		if current_level <= previous_level:
			continue
		var speaker := DialogueLibrary.worker_speaker(worker_id)
		var title := String(worker.get("career_title", "ACCREDITED LAYER")).to_upper()
		return _entry(
			"promotion_%d_%s_l%d" % [day, String(speaker), current_level],
			speaker,
			"They changed my title to %s. The queue recognized me immediately." % title,
			_default_channel(speaker),
			13.0,
		)
	return {}


static func _production_milestone_beat(
	previous_eggs: int,
	current_eggs: int,
	workers: Array,
	day: int,
) -> Dictionary:
	var reached := 0
	for milestone in EGG_CONVERSATION_MILESTONES:
		if previous_eggs < milestone and current_eggs >= milestone:
			reached = milestone
	if reached <= 0:
		return {}
	var employed_ids: Array[int] = []
	for worker_value in workers:
		if not worker_value is Dictionary:
			continue
		var worker := worker_value as Dictionary
		var worker_id := int(worker.get("id", -1))
		if (
			bool(worker.get("employed", false))
			and worker_id >= 0
			and worker_id < DialogueLibrary.WORKER_SPEAKERS.size()
		):
			employed_ids.append(worker_id)
	if employed_ids.is_empty():
		return {}
	var speaker_worker_id := employed_ids[posmod(day + reached, employed_ids.size())]
	var speaker := DialogueLibrary.worker_speaker(speaker_worker_id)
	return _voice_entry(
		"production_%d_%d_%s" % [day, reached, String(speaker)],
		speaker,
		&"production",
		"%d|%d|%d" % [day, reached, current_eggs],
		11.0,
	)


static func _manager_candidate_ids(roster: Array) -> Array[StringName]:
	var ids: Array[StringName] = []
	for manager_value in roster:
		if not manager_value is Dictionary:
			continue
		var manager := manager_value as Dictionary
		var candidate_id := StringName(String(manager.get(
			"candidate_id",
			manager.get("id", ""),
		)))
		if not candidate_id.is_empty():
			ids.append(candidate_id)
	return ids


static func _changed_manager_candidate(
	previous_ids: Array[StringName],
	current_ids: Array[StringName],
) -> StringName:
	for candidate_id in current_ids:
		if candidate_id not in previous_ids:
			return candidate_id
	for index in current_ids.size():
		if index >= previous_ids.size() or current_ids[index] != previous_ids[index]:
			return current_ids[index]
	return &""


static func _manager_id_key(ids: Array[StringName]) -> String:
	var parts := PackedStringArray()
	for candidate_id in ids:
		parts.append(String(candidate_id))
	return "|".join(parts)


static func _workers_by_id(snapshot: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for worker_value in snapshot.get("workers", []):
		if worker_value is Dictionary:
			var worker := worker_value as Dictionary
			result[int(worker.get("id", -1))] = worker
	return result


static func _voice_entry(
	id_prefix: String,
	speaker_id: StringName,
	theme_id: StringName,
	variation_key: String,
	hold_seconds: float = 11.0,
) -> Dictionary:
	var lines := DialogueLibrary.voice_lines(speaker_id, theme_id)
	if lines.is_empty():
		return {}
	var line_index := posmod(
		("%s|%s|%s|%s" % [
			id_prefix,
			String(speaker_id),
			String(theme_id),
			variation_key,
		]).hash(),
		lines.size(),
	)
	var entry := _entry(
		"%s_v%d" % [id_prefix, line_index],
		speaker_id,
		String(lines[line_index]),
		_default_channel(speaker_id),
		hold_seconds,
	)
	# Routine production color belongs beside the live floor, not in a full-screen
	# cutaway that hides the egg route and its economic payoff.
	if theme_id == &"production":
		entry["presentation_mode"] = &"ambient"
		entry["hold_seconds"] = minf(float(entry.get("hold_seconds", 7.0)), 7.0)
	return entry


static func _default_channel(speaker_id: StringName) -> StringName:
	var speaker := SPEAKERS.get(speaker_id, {}) as Dictionary
	return StringName(String(speaker.get("channel", &"PRIVATE ASIDE")))


static func _entry(
	id: String,
	speaker_id: StringName,
	text: String,
	channel: StringName,
	hold_seconds: float = 9.0,
) -> Dictionary:
	var speaker := SPEAKERS.get(speaker_id, {}) as Dictionary
	if speaker.is_empty() or text.strip_edges().is_empty():
		return {}
	return {
		"id": StringName(id),
		"speaker_id": speaker_id,
		"speaker_name": String(speaker.get("name", "Office Hen")),
		"speaker_role": String(speaker.get("role", "EGG YIELD BUREAU")),
		"portrait_id": StringName(speaker.get("portrait", speaker_id)),
		"channel": channel,
		"text": text.strip_edges(),
		"hold_seconds": clampf(hold_seconds, 5.0, 15.0),
	}
